-- 07_PKG_SL_CONFIGURATOR_V2.sql
-- Correção: Implementação da geração real do Schema JSON e ajuste de mapeamento.

CREATE OR REPLACE PACKAGE BODY PKG_SL_CONFIGURATOR AS

    -- Gera o JSON template para o SELECT (Data Extraction)
    FUNCTION GENERATE_SELECT_JSON_TEMPLATE(p_entity_name IN VARCHAR2) RETURN CLOB IS
        v_json_template CLOB;
        v_is_first      BOOLEAN := TRUE;
    BEGIN
        DBMS_LOB.CREATETEMPORARY(v_json_template, TRUE);
        DBMS_LOB.APPEND(v_json_template, 'TO_CLOB(''{'')');

        FOR r IN (SELECT COLUMN_NAME, DATA_TYPE FROM TBL_SL_ENTITY_COLUMNS WHERE ENTITY_NAME = p_entity_name ORDER BY COLUMN_NAME) LOOP
            IF NOT v_is_first THEN 
                DBMS_LOB.APPEND(v_json_template, ' || TO_CLOB('','')'); 
            END IF;
            
            DBMS_LOB.APPEND(v_json_template, ' || TO_CLOB(''"' || r.COLUMN_NAME || '":"'')');
            DBMS_LOB.APPEND(v_json_template, ' || TO_CLOB(PKG_SL_CDC_MANAGER.ESCAPE_JSON(');
            
            IF r.DATA_TYPE LIKE '%DATE%' OR r.DATA_TYPE LIKE '%TIMESTAMP%' THEN
                DBMS_LOB.APPEND(v_json_template, 'TO_CLOB(TO_CHAR(s.' || r.COLUMN_NAME || ', ''YYYY-MM-DD HH24:MI:SS''))');
            ELSE
                DBMS_LOB.APPEND(v_json_template, 'TO_CLOB(s.' || r.COLUMN_NAME || ')');
            END IF;
            
            DBMS_LOB.APPEND(v_json_template, ')) || TO_CLOB(''"'')');
            v_is_first := FALSE;
        END LOOP;

        DBMS_LOB.APPEND(v_json_template, ' || TO_CLOB(''}'')');
        RETURN v_json_template;
    END GENERATE_SELECT_JSON_TEMPLATE;

    -- NOVA FUNÇÃO: Gera o Schema JSON (Metadata Definition)
    FUNCTION GENERATE_JSON_SCHEMA(p_entity_name IN VARCHAR2) RETURN CLOB IS
        v_schema CLOB;
        v_first  BOOLEAN := TRUE;
        v_json_type VARCHAR2(20);
    BEGIN
        DBMS_LOB.CREATETEMPORARY(v_schema, TRUE);
        -- Início do Schema
        DBMS_LOB.APPEND(v_schema, '{"type":"object","properties":{');

        FOR r IN (SELECT COLUMN_NAME, DATA_TYPE FROM TBL_SL_ENTITY_COLUMNS WHERE ENTITY_NAME = p_entity_name ORDER BY COLUMN_NAME) LOOP
            IF NOT v_first THEN 
                DBMS_LOB.APPEND(v_schema, ','); 
            END IF;
            v_first := FALSE;

            -- Mapeamento simples de Tipos Oracle -> JSON Schema
            IF r.DATA_TYPE IN ('NUMBER', 'FLOAT', 'INTEGER', 'BINARY_FLOAT', 'BINARY_DOUBLE') THEN
                v_json_type := '"number"';
            ELSE
                -- Date, Varchar, Char, Timestamp viram String no JSON
                v_json_type := '"string"';
            END IF;

            DBMS_LOB.APPEND(v_schema, '"' || r.COLUMN_NAME || '":{"type":' || v_json_type || '}');
        END LOOP;

        -- Fim do Schema
        DBMS_LOB.APPEND(v_schema, '}}');
        RETURN v_schema;
    END GENERATE_JSON_SCHEMA;

    PROCEDURE GENERATE_DYNAMIC_ARTIFACTS(p_entity_name IN VARCHAR2) IS
        v_pk_cols_list      VARCHAR2(4000);
        v_where_pagination  CLOB;
        v_json_select       CLOB;
        v_schema_json       CLOB;
        v_pk_join_clause    CLOB;
        
        TYPE pk_cols_t IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;
        v_pk_cols           pk_cols_t;
    BEGIN
        PKG_SL_LOGGING.WRITE_LOG('DEBUG', 'PKG_SL_CONFIGURATOR', 'GENERATE_DYNAMIC_ARTIFACTS', 'Gerando artefatos para ' || p_entity_name);
        
        DBMS_LOB.CREATETEMPORARY(v_schema_json, TRUE);
        DBMS_LOB.CREATETEMPORARY(v_where_pagination, TRUE);
        DBMS_LOB.CREATETEMPORARY(v_pk_join_clause, TRUE);

        -- 1. Montar lista de colunas PK e Cláusula de JOIN
        v_pk_cols_list := '';
        FOR r IN (SELECT COLUMN_NAME, PK_ORDER FROM TBL_SL_ENTITY_COLUMNS WHERE ENTITY_NAME = p_entity_name AND (IS_PK = 1 OR IS_UK = 1) ORDER BY PK_ORDER) LOOP
            v_pk_cols_list := v_pk_cols_list || r.COLUMN_NAME || ',';
            v_pk_cols(r.PK_ORDER) := r.COLUMN_NAME;
        END LOOP;
        v_pk_cols_list := RTRIM(v_pk_cols_list, ',');

        -- JOIN: Usar alias 'b' (batch)
        IF v_pk_cols.COUNT = 1 THEN
            v_pk_join_clause := 'TO_CHAR(s.' || v_pk_cols(1) || ') = b.ROW_PK';
        ELSIF v_pk_cols.COUNT > 1 THEN
            FOR i IN 1..v_pk_cols.COUNT LOOP
                IF i > 1 THEN DBMS_LOB.APPEND(v_pk_join_clause, ' || ''|#|'' || '); END IF;
                DBMS_LOB.APPEND(v_pk_join_clause, 'TO_CHAR(s.' || v_pk_cols(i) || ')');
            END LOOP;
            DBMS_LOB.APPEND(v_pk_join_clause, ' = b.ROW_PK');
        ELSE
             -- Fallback se não tiver PK (não deveria acontecer em prod, mas evita erro)
             v_pk_join_clause := '1=1'; 
        END IF;

        -- 2. Montar cláusula WHERE de paginação
        IF v_pk_cols.COUNT > 0 THEN
            IF v_pk_cols.COUNT = 1 THEN
                v_where_pagination := 'WHERE ' || v_pk_cols(1) || ' > :1';
            ELSE
                v_where_pagination := 'WHERE (';
                FOR i IN 1..v_pk_cols.COUNT LOOP
                    IF i > 1 THEN v_where_pagination := v_where_pagination || ' OR ('; END IF;
                    FOR j IN 1..i-1 LOOP
                        v_where_pagination := v_where_pagination || v_pk_cols(j) || ' = :' || j || ' AND ';
                    END LOOP;
                    v_where_pagination := v_where_pagination || v_pk_cols(i) || ' > :' || i;
                    IF i > 1 THEN v_where_pagination := v_where_pagination || ')'; END IF;
                END LOOP;
                v_where_pagination := v_where_pagination || ')';
            END IF;
        END IF;

        -- 3. Gerar Template JSON para SELECT
        v_json_select := GENERATE_SELECT_JSON_TEMPLATE(p_entity_name);
        
        -- 4. Gerar Schema JSON (CORREÇÃO APLICADA AQUI)
        v_schema_json := GENERATE_JSON_SCHEMA(p_entity_name);

        UPDATE TBL_SL_ENTITIES
        SET PK_COLUMNS_LIST = v_pk_cols_list,
            PK_WHERE_CLAUSE_PAGINATION = v_where_pagination,
            JSON_SELECT_TEMPLATE = v_json_select, 
            PK_JOIN_CLAUSE = v_pk_join_clause,
            SCHEMA_JSON = v_schema_json,
            CONFIG_VERSION = CONFIG_VERSION + 1
        WHERE ENTITY_NAME = p_entity_name;

        DBMS_LOB.FREETEMPORARY(v_json_select);
        DBMS_LOB.FREETEMPORARY(v_pk_join_clause);
        DBMS_LOB.FREETEMPORARY(v_schema_json);
        DBMS_LOB.FREETEMPORARY(v_where_pagination);
    END GENERATE_DYNAMIC_ARTIFACTS;

    PROCEDURE CONFIGURE_ENTITY(
        p_owner             IN VARCHAR2,
        p_source_table_name IN VARCHAR2,
        p_entity_type       IN VARCHAR2,
        p_custom_filter     IN CLOB DEFAULT NULL,
        p_force_reconfig    IN NUMBER DEFAULT 0 -- Alterado de BOOLEAN para NUMBER
    ) IS
        v_entity_name  VARCHAR2(30) := UPPER(p_source_table_name);
        v_exists       NUMBER;
        v_key_type     VARCHAR2(10) := 'NONE';
        v_pk_found     BOOLEAN := FALSE;
    BEGIN
        SELECT COUNT(*) INTO v_exists FROM TBL_SL_ENTITIES WHERE ENTITY_NAME = v_entity_name;

        -- Lógica de Controle: Se existe e NÃO é para forçar, sai.
        IF v_exists > 0 THEN
            IF p_force_reconfig = 0 THEN
                -- Opcional: Atualiza apenas o filtro se ele mudou, sem reconfigurar tudo
                UPDATE TBL_SL_ENTITIES 
                SET CUSTOM_FILTER_CLAUSE = p_custom_filter 
                WHERE ENTITY_NAME = v_entity_name;
                
                COMMIT;
                RETURN; -- PONTO CRÍTICO: Sai da procedure aqui.
            END IF;
            -- Se p_force_reconfig = 1, o código continua abaixo e refaz tudo.
        ELSE
            -- Se não existe, insere o registro inicial
            INSERT INTO TBL_SL_ENTITIES (ENTITY_NAME, OWNER, SOURCE_TABLE_NAME, ENTITY_TYPE, CUSTOM_FILTER_CLAUSE)
            VALUES (v_entity_name, p_owner, p_source_table_name, p_entity_type, p_custom_filter);
        END IF;

        -- Atualiza colunas
        DELETE FROM TBL_SL_ENTITY_COLUMNS WHERE ENTITY_NAME = v_entity_name;
        
        INSERT INTO TBL_SL_ENTITY_COLUMNS (ENTITY_NAME, COLUMN_NAME, DATA_TYPE, IS_PK, PK_ORDER, IS_UK)
        SELECT v_entity_name, column_name, data_type, 0, NULL, 0
        FROM all_tab_columns
        WHERE owner = p_owner AND table_name = p_source_table_name
          AND data_type NOT IN (SELECT DATA_TYPE FROM TBL_SL_IGNORED_DATA_TYPES);

        -- Tenta PK primeiro
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

        -- Se não achou PK, tenta UK
        IF NOT v_pk_found THEN
            FOR r IN (
                SELECT cols.column_name, cols.position
                FROM all_constraints cons
                JOIN all_cons_columns cols ON cons.constraint_name = cols.constraint_name AND cons.owner = cols.owner
                WHERE cons.constraint_type = 'U' AND cons.owner = p_owner AND cons.table_name = p_source_table_name
            ) LOOP
                UPDATE TBL_SL_ENTITY_COLUMNS 
                SET IS_UK = 1, PK_ORDER = r.position 
                WHERE ENTITY_NAME = v_entity_name AND COLUMN_NAME = r.column_name AND IS_UK = 0;
                v_key_type := 'UK';
            END LOOP;
        END IF;

        UPDATE TBL_SL_ENTITIES SET KEY_TYPE = v_key_type WHERE ENTITY_NAME = v_entity_name;

        -- Sempre regenera os artefatos
        GENERATE_DYNAMIC_ARTIFACTS(v_entity_name);
        
        COMMIT;
    END CONFIGURE_ENTITY;

    PROCEDURE RESET_ENTITY_FOR_RELOAD(p_entity_name IN VARCHAR2) IS
    BEGIN
        PKG_SL_CDC_MANAGER.DROP_ALL_LOG_OBJECTS(p_entity_name);
        DELETE FROM TBL_SL_INITIAL_LOAD_CONTROL WHERE ENTITY_NAME = p_entity_name;
        UPDATE TBL_SL_ENTITIES SET INITIAL_LOAD_STATUS = 'PENDING', CDC_ENABLED = 0 WHERE ENTITY_NAME = p_entity_name;
        COMMIT;
    END RESET_ENTITY_FOR_RELOAD;

    FUNCTION GET_ENTITY_SCHEMA(p_entity_name IN VARCHAR2) RETURN CLOB IS
        v_schema CLOB;
    BEGIN
        SELECT SCHEMA_JSON INTO v_schema FROM TBL_SL_ENTITIES WHERE ENTITY_NAME = p_entity_name;
        RETURN v_schema;
    END;

    FUNCTION GET_PK_JOIN_CLAUSE(p_entity_name IN VARCHAR2) RETURN VARCHAR2 IS
        v_join CLOB;
    BEGIN
        SELECT PK_JOIN_CLAUSE INTO v_join FROM TBL_SL_ENTITIES WHERE ENTITY_NAME = p_entity_name;
        RETURN DBMS_LOB.SUBSTR(v_join, 4000, 1);
    END;

END PKG_SL_CONFIGURATOR;
