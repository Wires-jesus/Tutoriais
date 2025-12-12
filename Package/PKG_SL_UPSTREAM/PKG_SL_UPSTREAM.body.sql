-- 10_PKG_SL_UPSTREAM.sql
-- Descrição: Gerencia a extração de dados (Upstream).
-- Alteração: Adicionada trava em PROCESS_DIFFERENTIAL_LOAD para aguardar o fim da Carga Inicial.

CREATE OR REPLACE PACKAGE BODY PKG_SL_UPSTREAM AS

    FUNCTION IS_TABLE_LOCKED_BY_TRANSACTION(p_table_name IN VARCHAR2) RETURN BOOLEAN IS
        resource_busy EXCEPTION;
        PRAGMA EXCEPTION_INIT(resource_busy, -54);
    BEGIN
        SAVEPOINT sp_check_lock;
        BEGIN
            EXECUTE IMMEDIATE 'LOCK TABLE ' || p_table_name || ' IN EXCLUSIVE MODE NOWAIT';
            ROLLBACK TO sp_check_lock;
            RETURN FALSE; 
        EXCEPTION
            WHEN resource_busy THEN
                ROLLBACK TO sp_check_lock; 
                RETURN TRUE; 
            WHEN OTHERS THEN
                ROLLBACK TO sp_check_lock;
                PKG_SL_LOGGING.WRITE_LOG('ERROR', 'PKG_SL_UPSTREAM', 'LOCK_CHECK', 'Erro ao verificar lock na tabela ' || p_table_name || ': ' || SQLERRM);
                RETURN TRUE;
        END;
    END IS_TABLE_LOCKED_BY_TRANSACTION;

    PROCEDURE PROCESS_INITIAL_LOAD(
        p_entity_name   IN VARCHAR2,
        p_batch_size    IN NUMBER DEFAULT 1000,
        p_cursor        OUT SYS_REFCURSOR,
        p_rows_returned OUT NUMBER
    ) IS
        v_sql_pk            CLOB;
        v_sql_data          CLOB;
        v_last_pk_concat    VARCHAR2(4000);
        v_rows_processed    NUMBER := 0;
        
        -- Variáveis para Binds
        v_pk_val_1          VARCHAR2(4000); v_pk_val_2 VARCHAR2(4000); v_pk_val_3 VARCHAR2(4000);
        v_pk_val_4          VARCHAR2(4000); v_pk_val_5 VARCHAR2(4000);
        
        v_last_pk_read      VARCHAR2(4000);
        v_pk_cols_count     NUMBER;
        v_entity            TBL_SL_ENTITIES%ROWTYPE;
        
        TYPE T_Cursor IS REF CURSOR;
        v_pk_cursor         T_Cursor;
    BEGIN
        -- 1. Recupera Metadados
        SELECT * INTO v_entity FROM TBL_SL_ENTITIES WHERE ENTITY_NAME = p_entity_name;
        SELECT LAST_PROCESSED_PK_CONCAT INTO v_last_pk_concat FROM TBL_SL_INITIAL_LOAD_CONTROL WHERE ENTITY_NAME = p_entity_name;
        SELECT COUNT(*) INTO v_pk_cols_count FROM TBL_SL_ENTITY_COLUMNS WHERE ENTITY_NAME = p_entity_name AND (IS_PK = 1 OR IS_UK = 1);

        -- 2. Fase 1: Determinar o Range do Lote (Ler apenas PKs)
        -- Query leve, apenas índices
        v_sql_pk := 'SELECT ' || v_entity.PK_COLUMNS_LIST || ' FROM ' || v_entity.OWNER || '.' || v_entity.SOURCE_TABLE_NAME || ' s ';

        IF v_last_pk_concat IS NULL THEN
            v_sql_pk := v_sql_pk || ' ORDER BY ' || v_entity.PK_COLUMNS_LIST;
            OPEN v_pk_cursor FOR v_sql_pk;
        ELSE
            v_sql_pk := v_sql_pk || ' ' || v_entity.PK_WHERE_CLAUSE_PAGINATION || ' ORDER BY ' || v_entity.PK_COLUMNS_LIST;
            
            v_pk_val_1 := REGEXP_SUBSTR(v_last_pk_concat, '[^|#]+', 1, 1);
            v_pk_val_2 := REGEXP_SUBSTR(v_last_pk_concat, '[^|#]+', 1, 2);
            v_pk_val_3 := REGEXP_SUBSTR(v_last_pk_concat, '[^|#]+', 1, 3);
            v_pk_val_4 := REGEXP_SUBSTR(v_last_pk_concat, '[^|#]+', 1, 4);
            v_pk_val_5 := REGEXP_SUBSTR(v_last_pk_concat, '[^|#]+', 1, 5);

            IF v_pk_cols_count = 1 THEN OPEN v_pk_cursor FOR v_sql_pk USING v_pk_val_1;
            ELSIF v_pk_cols_count = 2 THEN OPEN v_pk_cursor FOR v_sql_pk USING v_pk_val_1, v_pk_val_1, v_pk_val_2;
            ELSIF v_pk_cols_count = 3 THEN OPEN v_pk_cursor FOR v_sql_pk USING v_pk_val_1, v_pk_val_1, v_pk_val_2, v_pk_val_1, v_pk_val_2, v_pk_val_3;
            END IF;
        END IF;

        LOOP
            IF v_pk_cols_count = 1 THEN FETCH v_pk_cursor INTO v_pk_val_1; EXIT WHEN v_pk_cursor%NOTFOUND; v_last_pk_read := v_pk_val_1;
            ELSIF v_pk_cols_count = 2 THEN FETCH v_pk_cursor INTO v_pk_val_1, v_pk_val_2; EXIT WHEN v_pk_cursor%NOTFOUND; v_last_pk_read := v_pk_val_1 || '|#|' || v_pk_val_2;
            ELSIF v_pk_cols_count = 3 THEN FETCH v_pk_cursor INTO v_pk_val_1, v_pk_val_2, v_pk_val_3; EXIT WHEN v_pk_cursor%NOTFOUND; v_last_pk_read := v_pk_val_1 || '|#|' || v_pk_val_2 || '|#|' || v_pk_val_3;
            ELSE FETCH v_pk_cursor INTO v_pk_val_1; EXIT WHEN v_pk_cursor%NOTFOUND; v_last_pk_read := v_pk_val_1; 
            END IF;
            
            v_rows_processed := v_rows_processed + 1;
            IF v_rows_processed >= p_batch_size THEN EXIT; END IF;
        END LOOP;
        CLOSE v_pk_cursor;

        p_rows_returned := v_rows_processed;

        -- 3. Atualiza Controle
        IF v_rows_processed > 0 THEN
            UPDATE TBL_SL_INITIAL_LOAD_CONTROL 
            SET LAST_PROCESSED_PK_CONCAT = v_last_pk_read, 
                RECORDS_PROCESSED = RECORDS_PROCESSED + v_rows_processed 
            WHERE ENTITY_NAME = p_entity_name;
        END IF;

        IF v_rows_processed < p_batch_size THEN
            UPDATE TBL_SL_ENTITIES SET INITIAL_LOAD_STATUS = 'COMPLETED' WHERE ENTITY_NAME = p_entity_name;
            UPDATE TBL_SL_INITIAL_LOAD_CONTROL SET END_TIME = SYSTIMESTAMP WHERE ENTITY_NAME = p_entity_name;
        END IF;
        
        COMMIT;

        -- 4. Fase 2: Retornar os Dados (JSON)
        v_sql_data := 'SELECT ' || v_entity.JSON_SELECT_TEMPLATE || 
                      ' FROM ' || v_entity.OWNER || '.' || v_entity.SOURCE_TABLE_NAME || ' s ' ||
                      ' WHERE s.ROWID IN (SELECT rid FROM (SELECT ROWID rid FROM ' || v_entity.OWNER || '.' || v_entity.SOURCE_TABLE_NAME;

        IF v_last_pk_concat IS NULL THEN
            -- Primeira página
            v_sql_data := v_sql_data || ' ORDER BY ' || v_entity.PK_COLUMNS_LIST;
            v_sql_data := v_sql_data || ') WHERE ROWNUM <= :batch_size) ORDER BY ' || v_entity.PK_COLUMNS_LIST;
            
            OPEN p_cursor FOR v_sql_data USING p_batch_size;
        ELSE
            -- Páginas subsequentes
            v_sql_data := v_sql_data || ' ' || v_entity.PK_WHERE_CLAUSE_PAGINATION || ' ORDER BY ' || v_entity.PK_COLUMNS_LIST;
            v_sql_data := v_sql_data || ') WHERE ROWNUM <= :batch_size) ORDER BY ' || v_entity.PK_COLUMNS_LIST;

            -- Re-bind das variáveis para a query de dados
            v_pk_val_1 := REGEXP_SUBSTR(v_last_pk_concat, '[^|#]+', 1, 1);
            v_pk_val_2 := REGEXP_SUBSTR(v_last_pk_concat, '[^|#]+', 1, 2);
            v_pk_val_3 := REGEXP_SUBSTR(v_last_pk_concat, '[^|#]+', 1, 3);

            IF v_pk_cols_count = 1 THEN 
                OPEN p_cursor FOR v_sql_data USING v_pk_val_1, p_batch_size;
            ELSIF v_pk_cols_count = 2 THEN 
                OPEN p_cursor FOR v_sql_data USING v_pk_val_1, v_pk_val_1, v_pk_val_2, p_batch_size;
            ELSIF v_pk_cols_count = 3 THEN 
                OPEN p_cursor FOR v_sql_data USING v_pk_val_1, v_pk_val_1, v_pk_val_2, v_pk_val_1, v_pk_val_2, v_pk_val_3, p_batch_size;
            END IF;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN 
            IF v_pk_cursor%ISOPEN THEN CLOSE v_pk_cursor; END IF; 
            ROLLBACK;
            PKG_SL_LOGGING.WRITE_LOG('ERROR', 'PKG_SL_UPSTREAM', 'PROCESS_INITIAL_LOAD', 'Erro fatal: ' || SQLERRM);
            UPDATE TBL_SL_ENTITIES SET INITIAL_LOAD_STATUS = 'ERROR' WHERE ENTITY_NAME = p_entity_name; 
            COMMIT; 
            RAISE;
    END PROCESS_INITIAL_LOAD;

    PROCEDURE PROCESS_DIFFERENTIAL_LOAD(
        p_entity_name          IN VARCHAR2,
        p_batch_size           IN NUMBER,
        p_data_cursor          OUT SYS_REFCURSOR,
        p_queue_id             OUT NUMBER,
        p_last_log_id_in_batch OUT NUMBER,
        p_records_in_batch     OUT NUMBER
    ) IS
        v_log_table      VARCHAR2(30);
        v_last_processed NUMBER;
        v_source_table   VARCHAR2(30);
        v_json_template  CLOB;
        v_join_clause    VARCHAR2(4000);
        v_sql            CLOB;
        v_max_id_fetched NUMBER;
        v_status         VARCHAR2(20);
        v_load_status    VARCHAR2(20); -- Nova variável
    BEGIN
        -- Inicializa retornos
        p_queue_id := NULL;
        p_records_in_batch := 0;

        -- 0. TRAVA DE SEGURANÇA (Alteração Solicitada)
        -- Se a carga inicial ainda não terminou, não processa o CDC.
        SELECT INITIAL_LOAD_STATUS INTO v_load_status 
        FROM TBL_SL_ENTITIES WHERE ENTITY_NAME = p_entity_name;

        IF v_load_status <> 'COMPLETED' THEN
            -- Opcional: Logar em nível DEBUG para saber que está aguardando
            -- PKG_SL_LOGGING.WRITE_LOG('DEBUG', 'PKG_SL_UPSTREAM', 'PROCESS_DIFF', 'Aguardando Carga Inicial para: ' || p_entity_name);
            RETURN; -- Retorna p_records_in_batch = 0
        END IF;

        -- 1. Busca a próxima tabela na fila (FIFO estrito)
        BEGIN
            SELECT QUEUE_ID, LOG_TABLE_NAME, LAST_PROCESSED_LOG_ID, STATUS
            INTO p_queue_id, v_log_table, v_last_processed, v_status
            FROM (
                SELECT QUEUE_ID, LOG_TABLE_NAME, LAST_PROCESSED_LOG_ID, STATUS
                FROM TBL_SL_CDC_LOG_QUEUE
                WHERE ENTITY_NAME = p_entity_name 
                  AND STATUS IN ('PENDING', 'PROCESSING')
                ORDER BY QUEUE_ID ASC
            ) WHERE ROWNUM = 1;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            RETURN; 
        END;

        -- 2. VALIDAÇÃO DE INTEGRIDADE (LOCK CHECK)
        IF IS_TABLE_LOCKED_BY_TRANSACTION(v_log_table) THEN
            PKG_SL_LOGGING.WRITE_LOG('WARN', 'PKG_SL_UPSTREAM', 'PROCESS_DIFF', 
                'LOCK DETECTADO: Tabela ' || v_log_table || ' possui transações ativas. Ignorando lote.');
            p_queue_id := NULL;
            RETURN;
        END IF;
            
        IF v_status = 'PENDING' THEN
            UPDATE TBL_SL_CDC_LOG_QUEUE SET STATUS = 'PROCESSING' WHERE QUEUE_ID = p_queue_id;
            COMMIT;
        END IF;

        -- 3. Determina o range de IDs
        EXECUTE IMMEDIATE 'SELECT MAX(LOG_ID) FROM (SELECT LOG_ID FROM ' || v_log_table || 
                          ' WHERE LOG_ID > :1 ORDER BY LOG_ID) WHERE ROWNUM <= :2'
        INTO v_max_id_fetched
        USING v_last_processed, p_batch_size;

        IF v_max_id_fetched IS NULL THEN
            UPDATE TBL_SL_CDC_LOG_QUEUE SET STATUS = 'PROCESSED' WHERE QUEUE_ID = p_queue_id;
            COMMIT;
            p_records_in_batch := 0;
            RETURN;
        END IF;

        p_last_log_id_in_batch := v_max_id_fetched;

        -- 4. Monta a Query
        SELECT SOURCE_TABLE_NAME, JSON_SELECT_TEMPLATE
        INTO v_source_table, v_json_template
        FROM TBL_SL_ENTITIES WHERE ENTITY_NAME = p_entity_name;

        v_join_clause := PKG_SL_CONFIGURATOR.GET_PK_JOIN_CLAUSE(p_entity_name);

        v_sql := '
        WITH batch AS (
            SELECT ROW_PK, 
                   MAX(CHANGE_TYPE) KEEP (DENSE_RANK LAST ORDER BY LOG_ID) as FINAL_TYPE,
                   MAX(LOG_ID) as MAX_LOG_ID
            FROM ' || v_log_table || '
            WHERE LOG_ID > ' || v_last_processed || ' AND LOG_ID <= ' || v_max_id_fetched || '
            GROUP BY ROW_PK
        )
        SELECT 
            b.MAX_LOG_ID,
            b.FINAL_TYPE,
            b.ROW_PK,
            CASE 
                WHEN b.FINAL_TYPE = ''D'' THEN NULL 
                ELSE ' || v_json_template || '
            END as JSON_PAYLOAD
        FROM batch b
        LEFT JOIN ' || v_source_table || ' s ON ' || v_join_clause || '
        ORDER BY b.MAX_LOG_ID';

        OPEN p_data_cursor FOR v_sql;
        p_records_in_batch := p_batch_size; 

    EXCEPTION WHEN OTHERS THEN
        PKG_SL_LOGGING.WRITE_LOG('ERROR', 'PKG_SL_UPSTREAM', 'PROCESS_DIFFERENTIAL_LOAD', 'Erro: ' || SQLERRM);
        RAISE;
    END PROCESS_DIFFERENTIAL_LOAD;

    PROCEDURE CLEANUP_PROCESSED_LOGS(p_entity_name IN VARCHAR2) IS
    BEGIN
        FOR r IN (SELECT LOG_TABLE_NAME, QUEUE_ID FROM TBL_SL_CDC_LOG_QUEUE 
                  WHERE ENTITY_NAME = p_entity_name AND STATUS = 'PROCESSED') LOOP
            
            EXECUTE IMMEDIATE 'DROP TABLE ' || r.LOG_TABLE_NAME || ' PURGE';
            EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_SL_LOG_' || r.QUEUE_ID;
            
            DELETE FROM TBL_SL_CDC_LOG_QUEUE WHERE QUEUE_ID = r.QUEUE_ID;
        END LOOP;
        COMMIT;
    EXCEPTION WHEN OTHERS THEN
        PKG_SL_LOGGING.WRITE_LOG('ERROR', 'PKG_SL_UPSTREAM', 'CLEANUP', 'Erro ao limpar logs: ' || SQLERRM);
    END CLEANUP_PROCESSED_LOGS;

END PKG_SL_UPSTREAM;
