CREATE OR REPLACE PACKAGE BODY PKG_SL_UPSTREAM AS

    FUNCTION IS_TABLE_LOCKED_BY_TRANSACTION(p_table_name IN VARCHAR2) RETURN BOOLEAN IS
        v_lock_count NUMBER;
    BEGIN
        BEGIN
            SELECT COUNT(*) INTO v_lock_count
            FROM v$locked_object l
            JOIN dba_objects o ON l.object_id = o.object_id
            WHERE o.object_name = UPPER(p_table_name);
            
            IF v_lock_count > 0 THEN RETURN TRUE; ELSE RETURN FALSE; END IF;
        EXCEPTION
            WHEN OTHERS THEN
                PKG_SL_LOGGING.WRITE_LOG('ERROR', 'PKG_SL_UPSTREAM', 'LOCK_CHECK', 'Erro ao verificar lock na tabela ' || p_table_name || ': ' || SQLERRM);
                RETURN TRUE; 
        END;
    END IS_TABLE_LOCKED_BY_TRANSACTION;

    FUNCTION STRIP_WHERE(p_clause IN CLOB) RETURN VARCHAR2 IS
    BEGIN
        IF p_clause IS NULL THEN RETURN NULL; END IF;
        IF UPPER(SUBSTR(p_clause, 1, 6)) = 'WHERE ' THEN
            RETURN SUBSTR(p_clause, 7);
        END IF;
        RETURN p_clause;
    END;

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
        
        -- Variáveis expandidas para até 10 colunas
        v_start_pk_1 VARCHAR2(4000); v_start_pk_2 VARCHAR2(4000); v_start_pk_3 VARCHAR2(4000); v_start_pk_4 VARCHAR2(4000); v_start_pk_5 VARCHAR2(4000);
        v_start_pk_6 VARCHAR2(4000); v_start_pk_7 VARCHAR2(4000); v_start_pk_8 VARCHAR2(4000); v_start_pk_9 VARCHAR2(4000); v_start_pk_10 VARCHAR2(4000);
        
        v_end_pk_1 VARCHAR2(4000); v_end_pk_2 VARCHAR2(4000); v_end_pk_3 VARCHAR2(4000); v_end_pk_4 VARCHAR2(4000); v_end_pk_5 VARCHAR2(4000);
        v_end_pk_6 VARCHAR2(4000); v_end_pk_7 VARCHAR2(4000); v_end_pk_8 VARCHAR2(4000); v_end_pk_9 VARCHAR2(4000); v_end_pk_10 VARCHAR2(4000);
        
        v_last_pk_read      VARCHAR2(4000);
        v_pk_cols_count     NUMBER;
        v_entity            TBL_SL_ENTITIES%ROWTYPE;
        
        TYPE T_Cursor IS REF CURSOR;
        v_pk_cursor         T_Cursor;
        
        v_where_accum       CLOB;
        v_pk_upper_clause   CLOB; 
        v_not_null_clause   VARCHAR2(4000);
        v_sep               CONSTANT VARCHAR2(3) := '|#|';
        
        v_pos NUMBER; v_prev_pos NUMBER;
        v_col_name VARCHAR2(30);
        v_bind_counter NUMBER;
    BEGIN
        -- 1. Recupera Metadados
        SELECT * INTO v_entity FROM TBL_SL_ENTITIES WHERE ENTITY_NAME = p_entity_name;
        SELECT LAST_PROCESSED_PK_CONCAT INTO v_last_pk_concat FROM TBL_SL_INITIAL_LOAD_CONTROL WHERE ENTITY_NAME = p_entity_name;
        SELECT COUNT(*) INTO v_pk_cols_count FROM TBL_SL_ENTITY_COLUMNS WHERE ENTITY_NAME = p_entity_name AND (IS_PK = 1 OR IS_UK = 1);
        
        IF v_pk_cols_count = 0 OR v_entity.PK_COLUMNS_LIST IS NULL THEN
            RAISE_APPLICATION_ERROR(-20002, 'Entidade ' || p_entity_name || ' não possui PK definida.');
        END IF;

        -- Geração dinâmica do NOT NULL clause
        v_not_null_clause := '';
        FOR i IN 1..v_pk_cols_count LOOP
            IF i > 1 THEN v_not_null_clause := v_not_null_clause || ' AND '; END IF;
            v_not_null_clause := v_not_null_clause || REGEXP_SUBSTR(v_entity.PK_COLUMNS_LIST, '[^,]+', 1, i) || ' IS NOT NULL';
        END LOOP;

        -- 2. Fase 1: Determinar o Range do Lote
        v_sql_pk := 'SELECT /*+ FIRST_ROWS(' || p_batch_size || ') */ ' || v_entity.PK_COLUMNS_LIST || ' FROM ' || v_entity.OWNER || '.' || v_entity.SOURCE_TABLE_NAME || ' s ';
        v_where_accum := NULL;

        IF v_entity.CUSTOM_FILTER_CLAUSE IS NOT NULL THEN
            v_where_accum := '(' || v_entity.CUSTOM_FILTER_CLAUSE || ')';
        END IF;

        IF v_last_pk_concat IS NOT NULL THEN
            IF v_where_accum IS NOT NULL THEN v_where_accum := v_where_accum || ' AND '; END IF;
            v_where_accum := v_where_accum || '(' || STRIP_WHERE(v_entity.PK_WHERE_CLAUSE_PAGINATION) || ')';
        END IF;

        IF v_where_accum IS NOT NULL THEN v_where_accum := v_where_accum || ' AND '; END IF;
        v_where_accum := v_where_accum || '(' || v_not_null_clause || ')';

        v_sql_pk := v_sql_pk || ' WHERE ' || v_where_accum || ' ORDER BY ' || v_entity.PK_COLUMNS_LIST;

        -- Parser Dinâmico para o Start PK (Suporta até 10 colunas)
        IF v_last_pk_concat IS NOT NULL THEN
            v_prev_pos := 1;
            FOR i IN 1..v_pk_cols_count LOOP
                v_pos := INSTR(v_last_pk_concat, v_sep, 1, i);
                IF v_pos = 0 THEN v_pos := LENGTH(v_last_pk_concat) + 1; END IF;
                
                CASE i
                    WHEN 1 THEN v_start_pk_1 := SUBSTR(v_last_pk_concat, v_prev_pos, v_pos - v_prev_pos);
                    WHEN 2 THEN v_start_pk_2 := SUBSTR(v_last_pk_concat, v_prev_pos, v_pos - v_prev_pos);
                    WHEN 3 THEN v_start_pk_3 := SUBSTR(v_last_pk_concat, v_prev_pos, v_pos - v_prev_pos);
                    WHEN 4 THEN v_start_pk_4 := SUBSTR(v_last_pk_concat, v_prev_pos, v_pos - v_prev_pos);
                    WHEN 5 THEN v_start_pk_5 := SUBSTR(v_last_pk_concat, v_prev_pos, v_pos - v_prev_pos);
                    WHEN 6 THEN v_start_pk_6 := SUBSTR(v_last_pk_concat, v_prev_pos, v_pos - v_prev_pos);
                    WHEN 7 THEN v_start_pk_7 := SUBSTR(v_last_pk_concat, v_prev_pos, v_pos - v_prev_pos);
                    WHEN 8 THEN v_start_pk_8 := SUBSTR(v_last_pk_concat, v_prev_pos, v_pos - v_prev_pos);
                    WHEN 9 THEN v_start_pk_9 := SUBSTR(v_last_pk_concat, v_prev_pos, v_pos - v_prev_pos);
                    WHEN 10 THEN v_start_pk_10 := SUBSTR(v_last_pk_concat, v_prev_pos, v_pos - v_prev_pos);
                END CASE;
                v_prev_pos := v_pos + 3;
            END LOOP;
        END IF;

        -- Abertura do Cursor de PK (Fase 1)
        IF v_last_pk_concat IS NULL THEN
            OPEN v_pk_cursor FOR v_sql_pk;
        ELSE
            IF v_pk_cols_count = 1 THEN OPEN v_pk_cursor FOR v_sql_pk USING v_start_pk_1;
            ELSIF v_pk_cols_count = 2 THEN OPEN v_pk_cursor FOR v_sql_pk USING v_start_pk_1, v_start_pk_1, v_start_pk_2;
            ELSIF v_pk_cols_count = 3 THEN OPEN v_pk_cursor FOR v_sql_pk USING v_start_pk_1, v_start_pk_1, v_start_pk_2, v_start_pk_1, v_start_pk_2, v_start_pk_3;
            ELSIF v_pk_cols_count = 4 THEN OPEN v_pk_cursor FOR v_sql_pk USING v_start_pk_1, v_start_pk_1, v_start_pk_2, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4;
            ELSIF v_pk_cols_count = 5 THEN OPEN v_pk_cursor FOR v_sql_pk USING v_start_pk_1, v_start_pk_1, v_start_pk_2, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5;
            ELSIF v_pk_cols_count = 6 THEN OPEN v_pk_cursor FOR v_sql_pk USING v_start_pk_1, v_start_pk_1, v_start_pk_2, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6;
            ELSIF v_pk_cols_count = 7 THEN OPEN v_pk_cursor FOR v_sql_pk USING v_start_pk_1, v_start_pk_1, v_start_pk_2, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_7;
            ELSIF v_pk_cols_count = 8 THEN OPEN v_pk_cursor FOR v_sql_pk USING v_start_pk_1, v_start_pk_1, v_start_pk_2, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_7, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_7, v_start_pk_8;
            ELSIF v_pk_cols_count = 9 THEN OPEN v_pk_cursor FOR v_sql_pk USING v_start_pk_1, v_start_pk_1, v_start_pk_2, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_7, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_7, v_start_pk_8, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_7, v_start_pk_8, v_start_pk_9;
            ELSIF v_pk_cols_count = 10 THEN OPEN v_pk_cursor FOR v_sql_pk USING v_start_pk_1, v_start_pk_1, v_start_pk_2, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_7, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_7, v_start_pk_8, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_7, v_start_pk_8, v_start_pk_9, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_7, v_start_pk_8, v_start_pk_9, v_start_pk_10;
            END IF;
        END IF;

        LOOP
            IF v_pk_cols_count = 1 THEN FETCH v_pk_cursor INTO v_end_pk_1; EXIT WHEN v_pk_cursor%NOTFOUND; v_last_pk_read := v_end_pk_1;
            ELSIF v_pk_cols_count = 2 THEN FETCH v_pk_cursor INTO v_end_pk_1, v_end_pk_2; EXIT WHEN v_pk_cursor%NOTFOUND; v_last_pk_read := v_end_pk_1 || v_sep || v_end_pk_2;
            ELSIF v_pk_cols_count = 3 THEN FETCH v_pk_cursor INTO v_end_pk_1, v_end_pk_2, v_end_pk_3; EXIT WHEN v_pk_cursor%NOTFOUND; v_last_pk_read := v_end_pk_1 || v_sep || v_end_pk_2 || v_sep || v_end_pk_3;
            ELSIF v_pk_cols_count = 4 THEN FETCH v_pk_cursor INTO v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4; EXIT WHEN v_pk_cursor%NOTFOUND; v_last_pk_read := v_end_pk_1 || v_sep || v_end_pk_2 || v_sep || v_end_pk_3 || v_sep || v_end_pk_4;
            ELSIF v_pk_cols_count = 5 THEN FETCH v_pk_cursor INTO v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5; EXIT WHEN v_pk_cursor%NOTFOUND; v_last_pk_read := v_end_pk_1 || v_sep || v_end_pk_2 || v_sep || v_end_pk_3 || v_sep || v_end_pk_4 || v_sep || v_end_pk_5;
            ELSIF v_pk_cols_count = 6 THEN FETCH v_pk_cursor INTO v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6; EXIT WHEN v_pk_cursor%NOTFOUND; v_last_pk_read := v_end_pk_1 || v_sep || v_end_pk_2 || v_sep || v_end_pk_3 || v_sep || v_end_pk_4 || v_sep || v_end_pk_5 || v_sep || v_end_pk_6;
            ELSIF v_pk_cols_count = 7 THEN FETCH v_pk_cursor INTO v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7; EXIT WHEN v_pk_cursor%NOTFOUND; v_last_pk_read := v_end_pk_1 || v_sep || v_end_pk_2 || v_sep || v_end_pk_3 || v_sep || v_end_pk_4 || v_sep || v_end_pk_5 || v_sep || v_end_pk_6 || v_sep || v_end_pk_7;
            ELSIF v_pk_cols_count = 8 THEN FETCH v_pk_cursor INTO v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7, v_end_pk_8; EXIT WHEN v_pk_cursor%NOTFOUND; v_last_pk_read := v_end_pk_1 || v_sep || v_end_pk_2 || v_sep || v_end_pk_3 || v_sep || v_end_pk_4 || v_sep || v_end_pk_5 || v_sep || v_end_pk_6 || v_sep || v_end_pk_7 || v_sep || v_end_pk_8;
            ELSIF v_pk_cols_count = 9 THEN FETCH v_pk_cursor INTO v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7, v_end_pk_8, v_end_pk_9; EXIT WHEN v_pk_cursor%NOTFOUND; v_last_pk_read := v_end_pk_1 || v_sep || v_end_pk_2 || v_sep || v_end_pk_3 || v_sep || v_end_pk_4 || v_sep || v_end_pk_5 || v_sep || v_end_pk_6 || v_sep || v_end_pk_7 || v_sep || v_end_pk_8 || v_sep || v_end_pk_9;
            ELSIF v_pk_cols_count = 10 THEN FETCH v_pk_cursor INTO v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7, v_end_pk_8, v_end_pk_9, v_end_pk_10; EXIT WHEN v_pk_cursor%NOTFOUND; v_last_pk_read := v_end_pk_1 || v_sep || v_end_pk_2 || v_sep || v_end_pk_3 || v_sep || v_end_pk_4 || v_sep || v_end_pk_5 || v_sep || v_end_pk_6 || v_sep || v_end_pk_7 || v_sep || v_end_pk_8 || v_sep || v_end_pk_9 || v_sep || v_end_pk_10;
            ELSE FETCH v_pk_cursor INTO v_end_pk_1; EXIT WHEN v_pk_cursor%NOTFOUND; v_last_pk_read := v_end_pk_1; 
            END IF;
            
            v_rows_processed := v_rows_processed + 1;
            IF v_rows_processed >= p_batch_size THEN EXIT; END IF;
        END LOOP;
        CLOSE v_pk_cursor;

        p_rows_returned := v_rows_processed;

        IF v_rows_processed > 0 THEN
            UPDATE TBL_SL_INITIAL_LOAD_CONTROL SET LAST_PROCESSED_PK_CONCAT = v_last_pk_read, RECORDS_PROCESSED = RECORDS_PROCESSED + v_rows_processed WHERE ENTITY_NAME = p_entity_name;
        END IF;

        IF v_rows_processed < p_batch_size THEN
            UPDATE TBL_SL_ENTITIES SET INITIAL_LOAD_STATUS = 'COMPLETED' WHERE ENTITY_NAME = p_entity_name;
            UPDATE TBL_SL_INITIAL_LOAD_CONTROL SET END_TIME = SYSTIMESTAMP WHERE ENTITY_NAME = p_entity_name;
        END IF;
        
        COMMIT;

        -- 4. Fase 2: Retornar os Dados
        IF v_rows_processed = 0 THEN
            OPEN p_cursor FOR 'SELECT NULL FROM DUAL WHERE 1=0';
            RETURN;
        END IF;

        -- Parser Dinâmico para o End PK (Suporta até 10 colunas)
        IF v_last_pk_read IS NOT NULL THEN
             v_prev_pos := 1;
            FOR i IN 1..v_pk_cols_count LOOP
                v_pos := INSTR(v_last_pk_read, v_sep, 1, i);
                IF v_pos = 0 THEN v_pos := LENGTH(v_last_pk_read) + 1; END IF;
                CASE i
                    WHEN 1 THEN v_end_pk_1 := SUBSTR(v_last_pk_read, v_prev_pos, v_pos - v_prev_pos);
                    WHEN 2 THEN v_end_pk_2 := SUBSTR(v_last_pk_read, v_prev_pos, v_pos - v_prev_pos);
                    WHEN 3 THEN v_end_pk_3 := SUBSTR(v_last_pk_read, v_prev_pos, v_pos - v_prev_pos);
                    WHEN 4 THEN v_end_pk_4 := SUBSTR(v_last_pk_read, v_prev_pos, v_pos - v_prev_pos);
                    WHEN 5 THEN v_end_pk_5 := SUBSTR(v_last_pk_read, v_prev_pos, v_pos - v_prev_pos);
                    WHEN 6 THEN v_end_pk_6 := SUBSTR(v_last_pk_read, v_prev_pos, v_pos - v_prev_pos);
                    WHEN 7 THEN v_end_pk_7 := SUBSTR(v_last_pk_read, v_prev_pos, v_pos - v_prev_pos);
                    WHEN 8 THEN v_end_pk_8 := SUBSTR(v_last_pk_read, v_prev_pos, v_pos - v_prev_pos);
                    WHEN 9 THEN v_end_pk_9 := SUBSTR(v_last_pk_read, v_prev_pos, v_pos - v_prev_pos);
                    WHEN 10 THEN v_end_pk_10 := SUBSTR(v_last_pk_read, v_prev_pos, v_pos - v_prev_pos);
                END CASE;
                v_prev_pos := v_pos + 3;
            END LOOP;
        END IF;

        -- Geração Dinâmica da Cláusula Superior (<=)
        DBMS_LOB.CREATETEMPORARY(v_pk_upper_clause, TRUE);
        v_bind_counter := 1;
        FOR i IN 1 .. v_pk_cols_count LOOP
            IF i > 1 THEN DBMS_LOB.APPEND(v_pk_upper_clause, ' OR '); END IF;
            DBMS_LOB.APPEND(v_pk_upper_clause, '(');
            FOR j IN 1 .. i LOOP
                v_col_name := REGEXP_SUBSTR(v_entity.PK_COLUMNS_LIST, '[^,]+', 1, j);
                IF j > 1 THEN DBMS_LOB.APPEND(v_pk_upper_clause, ' AND '); END IF;
                IF j = i THEN
                    DBMS_LOB.APPEND(v_pk_upper_clause, 's.' || v_col_name || ' <= :' || v_bind_counter);
                ELSE
                    DBMS_LOB.APPEND(v_pk_upper_clause, 's.' || v_col_name || ' = :' || v_bind_counter);
                END IF;
                v_bind_counter := v_bind_counter + 1;
            END LOOP;
            DBMS_LOB.APPEND(v_pk_upper_clause, ')');
        END LOOP;

        v_sql_data := 'SELECT /*+ FIRST_ROWS(' || p_batch_size || ') */ ' || v_entity.DATA_SELECT_TEMPLATE || ' FROM ' || v_entity.OWNER || '.' || v_entity.SOURCE_TABLE_NAME || ' s ';
        v_where_accum := NULL;
        IF v_entity.CUSTOM_FILTER_CLAUSE IS NOT NULL THEN
            v_where_accum := '(' || v_entity.CUSTOM_FILTER_CLAUSE || ')';
        END IF;

        IF v_last_pk_concat IS NOT NULL THEN
            IF v_where_accum IS NOT NULL THEN v_where_accum := v_where_accum || ' AND '; END IF;
            v_where_accum := v_where_accum || '(' || STRIP_WHERE(v_entity.PK_WHERE_CLAUSE_PAGINATION) || ')';
        END IF;

        IF v_where_accum IS NOT NULL THEN v_where_accum := v_where_accum || ' AND '; END IF;
        v_where_accum := v_where_accum || '(' || v_pk_upper_clause || ')';

        v_sql_data := v_sql_data || ' WHERE ' || v_where_accum || ' ORDER BY ' || v_entity.PK_COLUMNS_LIST;
        
        DBMS_LOB.FREETEMPORARY(v_pk_upper_clause);

        -- Abertura do Cursor de Dados (Fase 2) - Binds Massivos
        IF v_last_pk_concat IS NULL THEN
             IF v_pk_cols_count = 1 THEN OPEN p_cursor FOR v_sql_data USING v_end_pk_1;
             ELSIF v_pk_cols_count = 2 THEN OPEN p_cursor FOR v_sql_data USING v_end_pk_1, v_end_pk_1, v_end_pk_2;
             ELSIF v_pk_cols_count = 3 THEN OPEN p_cursor FOR v_sql_data USING v_end_pk_1, v_end_pk_1, v_end_pk_2, v_end_pk_1, v_end_pk_2, v_end_pk_3;
             ELSIF v_pk_cols_count = 4 THEN OPEN p_cursor FOR v_sql_data USING v_end_pk_1, v_end_pk_1, v_end_pk_2, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4;
             ELSIF v_pk_cols_count = 5 THEN OPEN p_cursor FOR v_sql_data USING v_end_pk_1, v_end_pk_1, v_end_pk_2, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5;
             ELSIF v_pk_cols_count = 6 THEN OPEN p_cursor FOR v_sql_data USING v_end_pk_1, v_end_pk_1, v_end_pk_2, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6;
             ELSIF v_pk_cols_count = 7 THEN OPEN p_cursor FOR v_sql_data USING v_end_pk_1, v_end_pk_1, v_end_pk_2, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7;
             ELSIF v_pk_cols_count = 8 THEN OPEN p_cursor FOR v_sql_data USING v_end_pk_1, v_end_pk_1, v_end_pk_2, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7, v_end_pk_8;
             ELSIF v_pk_cols_count = 9 THEN OPEN p_cursor FOR v_sql_data USING v_end_pk_1, v_end_pk_1, v_end_pk_2, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7, v_end_pk_8, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7, v_end_pk_8, v_end_pk_9;
             ELSIF v_pk_cols_count = 10 THEN OPEN p_cursor FOR v_sql_data USING v_end_pk_1, v_end_pk_1, v_end_pk_2, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7, v_end_pk_8, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7, v_end_pk_8, v_end_pk_9, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7, v_end_pk_8, v_end_pk_9, v_end_pk_10;
             END IF;
        ELSE
             IF v_pk_cols_count = 1 THEN OPEN p_cursor FOR v_sql_data USING v_start_pk_1, v_end_pk_1;
             ELSIF v_pk_cols_count = 2 THEN OPEN p_cursor FOR v_sql_data USING v_start_pk_1, v_start_pk_1, v_start_pk_2, v_end_pk_1, v_end_pk_1, v_end_pk_2;
             ELSIF v_pk_cols_count = 3 THEN OPEN p_cursor FOR v_sql_data USING v_start_pk_1, v_start_pk_1, v_start_pk_2, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_end_pk_1, v_end_pk_1, v_end_pk_2, v_end_pk_1, v_end_pk_2, v_end_pk_3;
             ELSIF v_pk_cols_count = 4 THEN OPEN p_cursor FOR v_sql_data USING v_start_pk_1, v_start_pk_1, v_start_pk_2, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_end_pk_1, v_end_pk_1, v_end_pk_2, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4;
             ELSIF v_pk_cols_count = 5 THEN OPEN p_cursor FOR v_sql_data USING v_start_pk_1, v_start_pk_1, v_start_pk_2, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_end_pk_1, v_end_pk_1, v_end_pk_2, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5;
             ELSIF v_pk_cols_count = 6 THEN OPEN p_cursor FOR v_sql_data USING v_start_pk_1, v_start_pk_1, v_start_pk_2, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_end_pk_1, v_end_pk_1, v_end_pk_2, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6;
             ELSIF v_pk_cols_count = 7 THEN OPEN p_cursor FOR v_sql_data USING v_start_pk_1, v_start_pk_1, v_start_pk_2, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_7, v_end_pk_1, v_end_pk_1, v_end_pk_2, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7;
             ELSIF v_pk_cols_count = 8 THEN OPEN p_cursor FOR v_sql_data USING v_start_pk_1, v_start_pk_1, v_start_pk_2, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_7, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_7, v_start_pk_8, v_end_pk_1, v_end_pk_1, v_end_pk_2, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7, v_end_pk_8;
             ELSIF v_pk_cols_count = 9 THEN OPEN p_cursor FOR v_sql_data USING v_start_pk_1, v_start_pk_1, v_start_pk_2, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_7, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_7, v_start_pk_8, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_7, v_start_pk_8, v_start_pk_9, v_end_pk_1, v_end_pk_1, v_end_pk_2, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7, v_end_pk_8, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7, v_end_pk_8, v_end_pk_9;
             ELSIF v_pk_cols_count = 10 THEN OPEN p_cursor FOR v_sql_data USING v_start_pk_1, v_start_pk_1, v_start_pk_2, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_7, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_7, v_start_pk_8, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_7, v_start_pk_8, v_start_pk_9, v_start_pk_1, v_start_pk_2, v_start_pk_3, v_start_pk_4, v_start_pk_5, v_start_pk_6, v_start_pk_7, v_start_pk_8, v_start_pk_9, v_start_pk_10, v_end_pk_1, v_end_pk_1, v_end_pk_2, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7, v_end_pk_8, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7, v_end_pk_8, v_end_pk_9, v_end_pk_1, v_end_pk_2, v_end_pk_3, v_end_pk_4, v_end_pk_5, v_end_pk_6, v_end_pk_7, v_end_pk_8, v_end_pk_9, v_end_pk_10;
             END IF;
        END IF;

    EXCEPTION WHEN OTHERS THEN
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
        v_data_template  CLOB;
        v_select_cols    CLOB;
        v_join_clause    VARCHAR2(4000);
        v_sql            CLOB;
        v_max_id_fetched NUMBER;
        v_status         VARCHAR2(20);
        v_load_status    VARCHAR2(20);
    BEGIN
        p_queue_id := NULL;
        p_records_in_batch := 0;

        SELECT INITIAL_LOAD_STATUS INTO v_load_status 
        FROM TBL_SL_ENTITIES WHERE ENTITY_NAME = p_entity_name;

        IF v_load_status <> 'COMPLETED' THEN RETURN; END IF;

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
        EXCEPTION WHEN NO_DATA_FOUND THEN RETURN; END;

        IF IS_TABLE_LOCKED_BY_TRANSACTION(v_log_table) THEN
            PKG_SL_LOGGING.WRITE_LOG('WARN', 'PKG_SL_UPSTREAM', 'PROCESS_DIFF', 'LOCK DETECTADO: Tabela ' || v_log_table || ' possui transações ativas. Ignorando lote.');
            p_queue_id := NULL;
            RETURN;
        END IF;
            
        IF v_status = 'PENDING' THEN
            UPDATE TBL_SL_CDC_LOG_QUEUE SET STATUS = 'PROCESSING' WHERE QUEUE_ID = p_queue_id;
            COMMIT;
        END IF;

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

        SELECT SOURCE_TABLE_NAME, DATA_SELECT_TEMPLATE
        INTO v_source_table, v_data_template
        FROM TBL_SL_ENTITIES WHERE ENTITY_NAME = p_entity_name;

        v_select_cols := 's.' || REPLACE(v_data_template, ', ', ', s.');
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
            ' || v_select_cols || '
        FROM batch b
        LEFT JOIN ' || v_source_table || ' s ON ' || v_join_clause || '
        ORDER BY b.MAX_LOG_ID';

        OPEN p_data_cursor FOR v_sql;
        p_records_in_batch := p_batch_size; 

    EXCEPTION WHEN OTHERS THEN
        PKG_SL_LOGGING.WRITE_LOG('ERROR', 'PKG_SL_UPSTREAM', 'PROCESS_DIFFERENTIAL_LOAD', 'Erro: ' || SQLERRM);
        RAISE;
    END PROCESS_DIFFERENTIAL_LOAD;

    PROCEDURE CONFIRM_DIFFERENTIAL_BATCH(
        p_queue_id    IN NUMBER,
        p_last_log_id IN NUMBER
    ) IS
        v_entity_name VARCHAR2(30);
    BEGIN
        UPDATE TBL_SL_CDC_LOG_QUEUE 
        SET LAST_PROCESSED_LOG_ID = p_last_log_id,
            UPDATED_AT = SYSTIMESTAMP
        WHERE QUEUE_ID = p_queue_id
        RETURNING ENTITY_NAME INTO v_entity_name;

        IF SQL%ROWCOUNT = 0 THEN RETURN; END IF;

        COMMIT;
    END CONFIRM_DIFFERENTIAL_BATCH;

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
        PKG_SL_LOGGING.WRITE_LOG('ERROR', 'PKG_SL_UPSTREAM', 'CLEANUP', 'Erro: ' || SQLERRM);
    END CLEANUP_PROCESSED_LOGS;

END PKG_SL_UPSTREAM;