CREATE OR REPLACE PACKAGE BODY PKG_SL_CONFIGURATOR AS

    FUNCTION GENERATE_SELECT_LIST(p_entity_name IN VARCHAR2) RETURN CLOB IS
        v_select_list  CLOB;
        v_buffer       VARCHAR2(32000);
        v_is_first_col BOOLEAN := TRUE;
        v_bucket_count NUMBER := 0;
        v_bucket_limit CONSTANT NUMBER := 50;
    BEGIN
        DBMS_LOB.CREATETEMPORARY(v_select_list, TRUE);
        v_buffer := '';
        
        FOR r IN (SELECT COLUMN_NAME FROM TBL_SL_ENTITY_COLUMNS WHERE ENTITY_NAME = p_entity_name ORDER BY COLUMN_NAME) LOOP
            IF v_buffer IS NULL OR LENGTH(v_buffer) = 0 THEN
                IF NOT v_is_first_col THEN v_buffer := ', '; END IF;
            ELSE
                v_buffer := v_buffer || ', ';
            END IF;
            v_buffer := v_buffer || r.COLUMN_NAME;
            v_is_first_col := FALSE;
            v_bucket_count := v_bucket_count + 1;

            IF v_bucket_count >= v_bucket_limit THEN
                DBMS_LOB.APPEND(v_select_list, v_buffer);
                v_buffer := '';
                v_bucket_count := 0;
            END IF;
        END LOOP;

        IF LENGTH(v_buffer) > 0 THEN DBMS_LOB.APPEND(v_select_list, v_buffer); END IF;
        IF DBMS_LOB.GETLENGTH(v_select_list) = 0 THEN DBMS_LOB.APPEND(v_select_list, '*'); END IF;

        RETURN v_select_list;
    END GENERATE_SELECT_LIST;

    FUNCTION GENERATE_JSON_SCHEMA(p_entity_name IN VARCHAR2) RETURN CLOB IS
        v_schema CLOB;
        v_first  BOOLEAN := TRUE;
        v_json_type VARCHAR2(20);
    BEGIN
        DBMS_LOB.CREATETEMPORARY(v_schema, TRUE);
        DBMS_LOB.APPEND(v_schema, '{"type":"object","properties":{');

        FOR r IN (SELECT COLUMN_NAME, DATA_TYPE FROM TBL_SL_ENTITY_COLUMNS WHERE ENTITY_NAME = p_entity_name ORDER BY COLUMN_NAME) LOOP
            IF NOT v_first THEN DBMS_LOB.APPEND(v_schema, ','); END IF;
            v_first := FALSE;

            IF r.DATA_TYPE IN ('NUMBER', 'FLOAT', 'INTEGER', 'BINARY_FLOAT', 'BINARY_DOUBLE') THEN
                v_json_type := '"number"';
            ELSIF r.DATA_TYPE IN ('DATE', 'TIMESTAMP', 'TIMESTAMP(6)') THEN
                v_json_type := '"date"';
            ELSE
                v_json_type := '"string"';
            END IF;
            DBMS_LOB.APPEND(v_schema, '"' || r.COLUMN_NAME || '":{"type":' || v_json_type || '}');
        END LOOP;

        DBMS_LOB.APPEND(v_schema, '}}');
        RETURN v_schema;
    END GENERATE_JSON_SCHEMA;

    PROCEDURE GENERATE_DYNAMIC_ARTIFACTS(p_entity_name IN VARCHAR2) IS
        v_pk_cols_list      VARCHAR2(4000);
        v_where_pagination  CLOB;
        v_select_list       CLOB;
        v_schema_json       CLOB;
        v_pk_join_clause    CLOB;
        v_bind_counter      NUMBER := 1;
        
        TYPE pk_info_rec IS RECORD (col_name VARCHAR2(30), data_type VARCHAR2(128));
        TYPE pk_cols_t IS TABLE OF pk_info_rec INDEX BY BINARY_INTEGER;
        v_pk_cols           pk_cols_t;
    BEGIN
        PKG_SL_LOGGING.WRITE_LOG('DEBUG', 'PKG_SL_CONFIGURATOR', 'GENERATE_DYNAMIC_ARTIFACTS', 'Gerando artefatos V6.0 (Multi-PK) para ' || p_entity_name);
        
        DBMS_LOB.CREATETEMPORARY(v_schema_json, TRUE);
        DBMS_LOB.CREATETEMPORARY(v_where_pagination, TRUE);
        DBMS_LOB.CREATETEMPORARY(v_pk_join_clause, TRUE);

        -- 1. Lista de PKs e Tipos
        v_pk_cols_list := '';
        FOR r IN (SELECT COLUMN_NAME, PK_ORDER, DATA_TYPE FROM TBL_SL_ENTITY_COLUMNS WHERE ENTITY_NAME = p_entity_name AND IS_PK = 1 ORDER BY PK_ORDER) LOOP
            v_pk_cols_list := v_pk_cols_list || r.COLUMN_NAME || ',';
            v_pk_cols(r.PK_ORDER).col_name := r.COLUMN_NAME;
            v_pk_cols(r.PK_ORDER).data_type := r.DATA_TYPE;
        END LOOP;
        v_pk_cols_list := RTRIM(v_pk_cols_list, ',');

        -- 2. Join Clause (CDC) - Mantém lógica existente que já suporta N colunas via concatenação
        IF v_pk_cols.COUNT = 1 THEN
            IF v_pk_cols(1).data_type IN ('NUMBER', 'INTEGER', 'FLOAT', 'BINARY_FLOAT', 'BINARY_DOUBLE') THEN
                v_pk_join_clause := 's.' || v_pk_cols(1).col_name || ' = TO_NUMBER(b.ROW_PK)';
            ELSE
                v_pk_join_clause := 's.' || v_pk_cols(1).col_name || ' = b.ROW_PK';
            END IF;
        ELSIF v_pk_cols.COUNT > 1 THEN
            FOR i IN 1..v_pk_cols.COUNT LOOP
                IF i > 1 THEN DBMS_LOB.APPEND(v_pk_join_clause, ' || ''|#|'' || '); END IF;
                DBMS_LOB.APPEND(v_pk_join_clause, 'TO_CHAR(s.' || v_pk_cols(i).col_name || ')');
            END LOOP;
            DBMS_LOB.APPEND(v_pk_join_clause, ' = b.ROW_PK');
        ELSE
             v_pk_join_clause := '1=0'; 
        END IF;

        -- 3. Where Pagination (Carga Inicial) - Lógica Dinâmica para N Colunas
        -- Gera: (A > :1) OR (A = :2 AND B > :3) OR (A = :4 AND B = :5 AND C > :6) ...
        -- Nota: Os binds são sequenciais (:1, :2, :3...) para casar com a ordem de envio no Upstream.
        IF v_pk_cols.COUNT > 0 THEN
            v_bind_counter := 1;
            FOR i IN 1 .. v_pk_cols.COUNT LOOP
                IF i > 1 THEN 
                    DBMS_LOB.APPEND(v_where_pagination, ' OR '); 
                END IF;
                
                DBMS_LOB.APPEND(v_where_pagination, '(');
                
                FOR j IN 1 .. i LOOP
                    IF j > 1 THEN 
                        DBMS_LOB.APPEND(v_where_pagination, ' AND '); 
                    END IF;
                    
                    IF j = i THEN
                        -- Última coluna do grupo usa MAIOR QUE (>)
                        DBMS_LOB.APPEND(v_where_pagination, 's.' || v_pk_cols(j).col_name || ' > :' || v_bind_counter);
                    ELSE
                        -- Colunas anteriores usam IGUAL (=)
                        DBMS_LOB.APPEND(v_where_pagination, 's.' || v_pk_cols(j).col_name || ' = :' || v_bind_counter);
                    END IF;
                    v_bind_counter := v_bind_counter + 1;
                END LOOP;
                
                DBMS_LOB.APPEND(v_where_pagination, ')');
            END LOOP;
        END IF;

        -- 4. Gera Templates
        v_select_list := GENERATE_SELECT_LIST(p_entity_name);
        v_schema_json := GENERATE_JSON_SCHEMA(p_entity_name);

        -- 5. Atualiza Entidade
        UPDATE TBL_SL_ENTITIES 
        SET PK_COLUMNS_LIST = v_pk_cols_list,
            PK_WHERE_CLAUSE_PAGINATION = v_where_pagination,
            DATA_SELECT_TEMPLATE = v_select_list,
            SCHEMA_JSON = v_schema_json,
            PK_JOIN_CLAUSE = v_pk_join_clause
        WHERE ENTITY_NAME = p_entity_name;

        DBMS_LOB.FREETEMPORARY(v_schema_json);
        DBMS_LOB.FREETEMPORARY(v_select_list);
        DBMS_LOB.FREETEMPORARY(v_pk_join_clause);
        DBMS_LOB.FREETEMPORARY(v_where_pagination);
    END GENERATE_DYNAMIC_ARTIFACTS;

    PROCEDURE CONFIGURE_ENTITY(
        p_owner             IN VARCHAR2,
        p_source_table_name IN VARCHAR2,
        p_entity_type       IN VARCHAR2,
        p_custom_filter     IN CLOB DEFAULT NULL,
        p_force_reconfig    IN NUMBER DEFAULT 0 
    ) IS
        v_entity_name  VARCHAR2(30) := UPPER(p_source_table_name);
        v_exists       NUMBER;
        v_key_type     VARCHAR2(10) := 'NONE';
        v_pk_found     BOOLEAN := FALSE;
    BEGIN
        SELECT COUNT(*) INTO v_exists FROM TBL_SL_ENTITIES WHERE ENTITY_NAME = v_entity_name;

        IF v_exists > 0 THEN
            IF p_force_reconfig = 0 THEN
                UPDATE TBL_SL_ENTITIES 
                SET CUSTOM_FILTER_CLAUSE = p_custom_filter 
                WHERE ENTITY_NAME = v_entity_name;
                COMMIT;
                RETURN; 
            END IF;
            RESET_ENTITY_FOR_RELOAD(v_entity_name);
            UPDATE TBL_SL_ENTITIES 
            SET CUSTOM_FILTER_CLAUSE = p_custom_filter,
                CONFIG_VERSION = CONFIG_VERSION + 1
            WHERE ENTITY_NAME = v_entity_name;
        ELSE
            INSERT INTO TBL_SL_ENTITIES (ENTITY_NAME, OWNER, SOURCE_TABLE_NAME, ENTITY_TYPE, CUSTOM_FILTER_CLAUSE)
            VALUES (v_entity_name, p_owner, p_source_table_name, p_entity_type, p_custom_filter);
        END IF;

        DELETE FROM TBL_SL_ENTITY_COLUMNS WHERE ENTITY_NAME = v_entity_name;
        
        INSERT INTO TBL_SL_ENTITY_COLUMNS (ENTITY_NAME, COLUMN_NAME, DATA_TYPE, IS_PK, PK_ORDER, IS_UK)
        SELECT v_entity_name, column_name, data_type, 0, NULL, 0
        FROM all_tab_columns
        WHERE owner = p_owner AND table_name = p_source_table_name
          AND data_type NOT IN (SELECT DATA_TYPE FROM TBL_SL_IGNORED_DATA_TYPES);

        FOR r IN (
            SELECT cols.column_name, cols.position
            FROM all_constraints cons
            JOIN all_cons_columns cols ON cons.constraint_name = cols.constraint_name AND cons.owner = cols.owner
            WHERE cons.constraint_type = 'P' AND cons.owner = p_owner AND cons.table_name = p_source_table_name
        ) LOOP
            UPDATE TBL_SL_ENTITY_COLUMNS 
            SET IS_PK = 1, PK_ORDER = r.position 
            WHERE ENTITY_NAME = v_entity_name AND COLUMN_NAME = r.column_name;
            v_pk_found := TRUE;
            v_key_type := 'PK';
        END LOOP;

        IF NOT v_pk_found THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20003, 'Erro Fatal: A tabela ' || p_source_table_name || ' não possui Chave Primária (PK) definida.');
        END IF;

        UPDATE TBL_SL_ENTITIES SET KEY_TYPE = v_key_type WHERE ENTITY_NAME = v_entity_name;

        GENERATE_DYNAMIC_ARTIFACTS(v_entity_name);
        COMMIT;
    END CONFIGURE_ENTITY;

    PROCEDURE RESET_ENTITY_FOR_RELOAD(p_entity_name IN VARCHAR2) IS
    BEGIN
        PKG_SL_CDC_MANAGER.DROP_ALL_LOG_OBJECTS(p_entity_name);
        UPDATE TBL_SL_ENTITIES 
        SET INITIAL_LOAD_STATUS = 'PENDING', 
            CDC_ENABLED = 0 
        WHERE ENTITY_NAME = p_entity_name;
        
        DELETE FROM TBL_SL_INITIAL_LOAD_CONTROL WHERE ENTITY_NAME = p_entity_name;
        INSERT INTO TBL_SL_INITIAL_LOAD_CONTROL (ENTITY_NAME) VALUES (p_entity_name);
        COMMIT;
    END RESET_ENTITY_FOR_RELOAD;
    
    FUNCTION GET_PK_JOIN_CLAUSE(p_entity_name IN VARCHAR2) RETURN CLOB IS
        v_clause CLOB;
    BEGIN
        SELECT PK_JOIN_CLAUSE INTO v_clause FROM TBL_SL_ENTITIES WHERE ENTITY_NAME = p_entity_name;
        RETURN v_clause;
    EXCEPTION WHEN NO_DATA_FOUND THEN RETURN NULL; END;
    
    PROCEDURE PURGE_ALL_CONFIG IS
    BEGIN
        PKG_SL_LOGGING.WRITE_LOG('WARN', 'PURGE_ALL_CONFIG', 'START', 'Iniciando limpeza profunda.');
        FOR r IN (SELECT object_name FROM user_objects WHERE object_type = 'TRIGGER' AND object_name LIKE 'TRG_CDC_%') LOOP
            BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER ' || r.object_name; EXCEPTION WHEN OTHERS THEN NULL; END;
        END LOOP;
        FOR r IN (SELECT object_name FROM user_objects WHERE object_type = 'TABLE' AND object_name LIKE 'TBL_SL_LOG\_%' ESCAPE '\') LOOP
            BEGIN EXECUTE IMMEDIATE 'DROP TABLE ' || r.object_name || ' PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
        END LOOP;
        FOR r IN (SELECT object_name FROM user_objects WHERE object_type = 'SEQUENCE' AND object_name LIKE 'SEQ_SL_LOG\_%' ESCAPE '\') LOOP
            BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE ' || r.object_name; EXCEPTION WHEN OTHERS THEN NULL; END;
        END LOOP;
        DELETE FROM TBL_SL_INITIAL_LOAD_CONTROL;
        DELETE FROM TBL_SL_CDC_LOG_QUEUE;
        DELETE FROM TBL_SL_ENTITY_COLUMNS;
        DELETE FROM TBL_SL_ENTITIES;
        COMMIT;
        PKG_SL_LOGGING.WRITE_LOG('WARN', 'PURGE_ALL_CONFIG', 'END', 'Limpeza profunda finalizada.');
    EXCEPTION WHEN OTHERS THEN
        PKG_SL_LOGGING.WRITE_LOG('ERROR', 'PURGE_ALL_CONFIG', 'FAIL', SQLERRM);
    END PURGE_ALL_CONFIG;

END PKG_SL_CONFIGURATOR;