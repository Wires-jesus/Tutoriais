-- 06_PKG_SL_CDC_MANAGER.sql

CREATE OR REPLACE PACKAGE BODY PKG_SL_CDC_MANAGER AS

    FUNCTION ESCAPE_JSON(p_text IN CLOB) RETURN CLOB DETERMINISTIC IS
	    v_result CLOB;
    BEGIN
        IF p_text IS NULL THEN RETURN NULL; END IF;
		v_result := REPLACE(REPLACE(REPLACE(p_text, '\', '\\'), '"', '\"'), CHR(10), '\n');
		RETURN v_result;
    END ESCAPE_JSON;

    -- Gerencia os Sinônimos
    PROCEDURE MANAGE_SYNONYMS(p_entity_name IN VARCHAR2, p_table_name IN VARCHAR2, p_seq_name IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM SYN_SL_LOG_' || p_entity_name || ' FOR ' || p_table_name;
        EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM SYN_SL_SEQ_' || p_entity_name || ' FOR ' || p_seq_name;
    END MANAGE_SYNONYMS;

    PROCEDURE CREATE_LOG_AND_QUEUE_ENTRY(p_entity_name IN VARCHAR2, p_status IN VARCHAR2) AS
        v_queue_id NUMBER;
        v_log_table_name VARCHAR2(30);
        v_seq_name VARCHAR2(30);
    BEGIN
        SELECT SEQ_SL_CDC_LOG_QUEUE_ID.NEXTVAL INTO v_queue_id FROM DUAL;
        v_log_table_name := 'TBL_SL_LOG_' || v_queue_id;
        v_seq_name       := 'SEQ_SL_LOG_' || v_queue_id;

        -- REMOVIDO O CAMPO PAYLOAD DAQUI
        EXECUTE IMMEDIATE 'CREATE TABLE ' || v_log_table_name || ' (
            LOG_ID NUMBER NOT NULL, 
            CHANGE_TYPE CHAR(1) NOT NULL, 
            ROW_PK VARCHAR2(4000) NOT NULL, 
            CREATED_AT TIMESTAMP DEFAULT SYSTIMESTAMP, 
            CONSTRAINT PK_' || v_log_table_name || ' PRIMARY KEY (LOG_ID))';
        
        EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || v_seq_name || ' START WITH 1 INCREMENT BY 1 NOCACHE';

        INSERT INTO TBL_SL_CDC_LOG_QUEUE (QUEUE_ID, ENTITY_NAME, LOG_TABLE_NAME, STATUS, UPDATED_AT)
        VALUES (v_queue_id, p_entity_name, v_log_table_name, p_status, SYSTIMESTAMP);

        IF p_status = 'ACTIVE' THEN
            MANAGE_SYNONYMS(p_entity_name, v_log_table_name, v_seq_name);
        END IF;
    END CREATE_LOG_AND_QUEUE_ENTRY;

    FUNCTION GET_ACTIVE_LOG_TABLE(p_entity_name IN VARCHAR2) RETURN VARCHAR2 AS
        v_log_table_name VARCHAR2(30);
    BEGIN
        SELECT LOG_TABLE_NAME INTO v_log_table_name FROM TBL_SL_CDC_LOG_QUEUE 
        WHERE ENTITY_NAME = p_entity_name AND STATUS = 'ACTIVE' AND ROWNUM = 1;
        RETURN v_log_table_name;
    EXCEPTION WHEN OTHERS THEN RETURN NULL; END;

    PROCEDURE CREATE_FIRST_LOG_TABLE(p_entity_name IN VARCHAR2) AS
        v_c NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_c FROM TBL_SL_CDC_LOG_QUEUE WHERE ENTITY_NAME = p_entity_name AND STATUS = 'ACTIVE';
        IF v_c = 0 THEN CREATE_LOG_AND_QUEUE_ENTRY(p_entity_name, 'ACTIVE'); COMMIT; END IF;
    END;

    PROCEDURE REQUEST_ROTATION(p_entity_name IN VARCHAR2) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        MERGE INTO TBL_SL_ROTATION_REQUESTS r USING (SELECT p_entity_name e FROM dual) s ON (r.ENTITY_NAME = s.e)
        WHEN NOT MATCHED THEN INSERT (ENTITY_NAME) VALUES (s.e);
        COMMIT;
    END;

    PROCEDURE ROTATE_LOG_TABLE(p_entity_name IN VARCHAR2) AS
        v_old_q NUMBER;
        v_new_queue_id NUMBER;
        v_new_table VARCHAR2(30);
        v_new_seq VARCHAR2(30);
    BEGIN
        BEGIN
            SELECT QUEUE_ID INTO v_old_q FROM TBL_SL_CDC_LOG_QUEUE WHERE ENTITY_NAME = p_entity_name AND STATUS = 'ACTIVE' AND ROWNUM = 1;
            
            SELECT SEQ_SL_CDC_LOG_QUEUE_ID.NEXTVAL INTO v_new_queue_id FROM DUAL;
            v_new_table := 'TBL_SL_LOG_' || v_new_queue_id;
            v_new_seq   := 'SEQ_SL_LOG_' || v_new_queue_id;

            -- REMOVIDO O CAMPO PAYLOAD DAQUI TAMBÉM
            EXECUTE IMMEDIATE 'CREATE TABLE ' || v_new_table || ' (
                LOG_ID NUMBER NOT NULL, CHANGE_TYPE CHAR(1) NOT NULL, ROW_PK VARCHAR2(4000) NOT NULL, 
                CREATED_AT TIMESTAMP DEFAULT SYSTIMESTAMP, 
                CONSTRAINT PK_' || v_new_table || ' PRIMARY KEY (LOG_ID))';
            
            EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || v_new_seq || ' START WITH 1 INCREMENT BY 1 NOCACHE';

            -- Atualiza Sinônimos
            MANAGE_SYNONYMS(p_entity_name, v_new_table, v_new_seq);

            INSERT INTO TBL_SL_CDC_LOG_QUEUE (QUEUE_ID, ENTITY_NAME, LOG_TABLE_NAME, STATUS, UPDATED_AT)
            VALUES (v_new_queue_id, p_entity_name, v_new_table, 'ACTIVE', SYSTIMESTAMP);

            -- Marca a antiga como PENDING e atualiza o timestamp (importante para a trava de segurança)
            UPDATE TBL_SL_CDC_LOG_QUEUE SET STATUS = 'PENDING', UPDATED_AT = SYSTIMESTAMP WHERE QUEUE_ID = v_old_q;
            
            COMMIT;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            CREATE_FIRST_LOG_TABLE(p_entity_name);
        END;
    END;

    PROCEDURE WRITE_TO_LOG(p_entity_name IN VARCHAR2, p_change_type IN CHAR, p_row_pk IN VARCHAR2) AS
        -- SEM PRAGMA AUTONOMOUS_TRANSACTION
        v_log_id NUMBER;
        v_max_rows NUMBER := 20000; 
    BEGIN
        -- Usa Sinônimo da Sequence
        EXECUTE IMMEDIATE 'SELECT SYN_SL_SEQ_' || p_entity_name || '.NEXTVAL FROM DUAL' INTO v_log_id;
        
        -- Usa Sinônimo da Tabela e SEM PAYLOAD
        EXECUTE IMMEDIATE 'INSERT INTO SYN_SL_LOG_' || p_entity_name || ' (LOG_ID, CHANGE_TYPE, ROW_PK) VALUES (:1, :2, :3)'
        USING v_log_id, p_change_type, p_row_pk;

        IF v_log_id >= v_max_rows THEN REQUEST_ROTATION(p_entity_name); END IF;
        -- SEM COMMIT (Segue a transação do Winthor)
    EXCEPTION WHEN OTHERS THEN RAISE; END;

    PROCEDURE DROP_ALL_LOG_OBJECTS(p_entity_name IN VARCHAR2) AS
    BEGIN
        BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER TRG_CDC_' || p_entity_name; EXCEPTION WHEN OTHERS THEN NULL; END;
        BEGIN EXECUTE IMMEDIATE 'DROP SYNONYM SYN_SL_LOG_' || p_entity_name; EXCEPTION WHEN OTHERS THEN NULL; END;
        BEGIN EXECUTE IMMEDIATE 'DROP SYNONYM SYN_SL_SEQ_' || p_entity_name; EXCEPTION WHEN OTHERS THEN NULL; END;
        FOR r IN (SELECT LOG_TABLE_NAME, QUEUE_ID FROM TBL_SL_CDC_LOG_QUEUE WHERE ENTITY_NAME = p_entity_name) LOOP
            BEGIN EXECUTE IMMEDIATE 'DROP TABLE ' || r.LOG_TABLE_NAME || ' PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
            BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_SL_LOG_' || r.QUEUE_ID; EXCEPTION WHEN OTHERS THEN NULL; END;
        END LOOP;
        DELETE FROM TBL_SL_CDC_LOG_QUEUE WHERE ENTITY_NAME = p_entity_name;
        COMMIT;
    END;

END PKG_SL_CDC_MANAGER;
