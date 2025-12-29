CREATE OR REPLACE PACKAGE BODY PKG_SL_CDC_MANAGER AS

    -- Função auxiliar privada para gerar nomes seguros (Max 30 chars)
    FUNCTION GET_SAFE_OBJ_NAME(p_prefix IN VARCHAR2, p_entity_name IN VARCHAR2) RETURN VARCHAR2 IS
        v_max_len CONSTANT NUMBER := 30;
        v_avail   NUMBER;
    BEGIN
        v_avail := v_max_len - LENGTH(p_prefix);
        IF LENGTH(p_entity_name) > v_avail THEN
            -- Trunca o nome da entidade para caber
            RETURN p_prefix || SUBSTR(p_entity_name, 1, v_avail);
        ELSE
            RETURN p_prefix || p_entity_name;
        END IF;
    END;

    PROCEDURE MANAGE_SYNONYMS(p_entity_name IN VARCHAR2, p_table_name IN VARCHAR2, p_seq_name IN VARCHAR2) IS
        v_syn_table VARCHAR2(30);
        v_syn_seq   VARCHAR2(30);
    BEGIN
        -- Gera nomes seguros para os sinônimos (SYN_SL_LOG_... e SYN_SL_SEQ_...)
        v_syn_table := GET_SAFE_OBJ_NAME('SYN_SL_LOG_', p_entity_name);
        v_syn_seq   := GET_SAFE_OBJ_NAME('SYN_SL_SEQ_', p_entity_name);

        EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM ' || v_syn_table || ' FOR ' || p_table_name;
        EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM ' || v_syn_seq || ' FOR ' || p_seq_name;
    END;

    PROCEDURE REQUEST_ROTATION(p_entity_name IN VARCHAR2) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        MERGE INTO TBL_SL_ROTATION_REQUESTS r
        USING (SELECT p_entity_name AS entity_name FROM dual) s
        ON (r.ENTITY_NAME = s.entity_name)
        WHEN MATCHED THEN UPDATE SET REQUEST_TIME = SYSTIMESTAMP
        WHEN NOT MATCHED THEN INSERT (ENTITY_NAME, REQUEST_TIME) VALUES (s.entity_name, SYSTIMESTAMP);
        COMMIT;
    EXCEPTION WHEN OTHERS THEN ROLLBACK; END;

    PROCEDURE CREATE_FIRST_LOG_TABLE(p_entity_name IN VARCHAR2) AS
        v_queue_id NUMBER;
        v_table    VARCHAR2(30);
        v_seq      VARCHAR2(30);
    BEGIN
        SELECT SEQ_SL_CDC_LOG_QUEUE_ID.NEXTVAL INTO v_queue_id FROM DUAL;
        
        v_table := 'TBL_SL_LOG_' || v_queue_id;
        v_seq   := 'SEQ_SL_LOG_' || v_queue_id;

        EXECUTE IMMEDIATE 'CREATE TABLE ' || v_table || ' (
            LOG_ID NUMBER NOT NULL, CHANGE_TYPE CHAR(1) NOT NULL, ROW_PK VARCHAR2(4000) NOT NULL, 
            CREATED_AT TIMESTAMP DEFAULT SYSTIMESTAMP, 
            CONSTRAINT PK_' || v_table || ' PRIMARY KEY (LOG_ID))';
        
        EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || v_seq || ' START WITH 1 INCREMENT BY 1 NOCACHE';

        MANAGE_SYNONYMS(p_entity_name, v_table, v_seq);

        INSERT INTO TBL_SL_CDC_LOG_QUEUE (QUEUE_ID, ENTITY_NAME, LOG_TABLE_NAME, STATUS)
        VALUES (v_queue_id, p_entity_name, v_table, 'ACTIVE');
        
        COMMIT;
    END;

    PROCEDURE ROTATE_LOG_TABLE(p_entity_name IN VARCHAR2) AS
        v_old_q NUMBER;
        v_new_queue_id NUMBER;
        v_new_table VARCHAR2(30);
        v_new_seq VARCHAR2(30);
    BEGIN
        BEGIN
            SELECT QUEUE_ID INTO v_old_q FROM TBL_SL_CDC_LOG_QUEUE 
            WHERE ENTITY_NAME = p_entity_name AND STATUS = 'ACTIVE';

            SELECT SEQ_SL_CDC_LOG_QUEUE_ID.NEXTVAL INTO v_new_queue_id FROM DUAL;
            v_new_table := 'TBL_SL_LOG_' || v_new_queue_id;
            v_new_seq   := 'SEQ_SL_LOG_' || v_new_queue_id;

            EXECUTE IMMEDIATE 'CREATE TABLE ' || v_new_table || ' (
                LOG_ID NUMBER NOT NULL, CHANGE_TYPE CHAR(1) NOT NULL, ROW_PK VARCHAR2(4000) NOT NULL, 
                CREATED_AT TIMESTAMP DEFAULT SYSTIMESTAMP, 
                CONSTRAINT PK_' || v_new_table || ' PRIMARY KEY (LOG_ID))';
            
            EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || v_new_seq || ' START WITH 1 INCREMENT BY 1 NOCACHE';

            MANAGE_SYNONYMS(p_entity_name, v_new_table, v_new_seq);

            INSERT INTO TBL_SL_CDC_LOG_QUEUE (QUEUE_ID, ENTITY_NAME, LOG_TABLE_NAME, STATUS, UPDATED_AT)
            VALUES (v_new_queue_id, p_entity_name, v_new_table, 'ACTIVE', SYSTIMESTAMP);

            UPDATE TBL_SL_CDC_LOG_QUEUE SET STATUS = 'PENDING', UPDATED_AT = SYSTIMESTAMP WHERE QUEUE_ID = v_old_q;
            
            COMMIT;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            CREATE_FIRST_LOG_TABLE(p_entity_name);
        END;
    END;

    PROCEDURE WRITE_TO_LOG(p_entity_name IN VARCHAR2, p_change_type IN CHAR, p_row_pk IN VARCHAR2) AS
        v_log_id NUMBER;
        v_max_rows NUMBER := 20000; 
        v_syn_table VARCHAR2(30);
        v_syn_seq   VARCHAR2(30);
    BEGIN
        -- Recalcula os nomes seguros para encontrar os sinônimos corretos
        v_syn_table := GET_SAFE_OBJ_NAME('SYN_SL_LOG_', p_entity_name);
        v_syn_seq   := GET_SAFE_OBJ_NAME('SYN_SL_SEQ_', p_entity_name);

        EXECUTE IMMEDIATE 'SELECT ' || v_syn_seq || '.NEXTVAL FROM DUAL' INTO v_log_id;
        
        EXECUTE IMMEDIATE 'INSERT INTO ' || v_syn_table || ' (LOG_ID, CHANGE_TYPE, ROW_PK) VALUES (:1, :2, :3)'
        USING v_log_id, p_change_type, p_row_pk;

        IF v_log_id >= v_max_rows THEN REQUEST_ROTATION(p_entity_name); END IF;
    EXCEPTION WHEN OTHERS THEN RAISE; END;

    PROCEDURE DROP_ALL_LOG_OBJECTS(p_entity_name IN VARCHAR2) AS
        v_syn_table VARCHAR2(30);
        v_syn_seq   VARCHAR2(30);
        v_trg_name  VARCHAR2(30);
    BEGIN
        -- Nomes seguros para drop
        v_syn_table := GET_SAFE_OBJ_NAME('SYN_SL_LOG_', p_entity_name);
        v_syn_seq   := GET_SAFE_OBJ_NAME('SYN_SL_SEQ_', p_entity_name);
        v_trg_name  := GET_SAFE_OBJ_NAME('TRG_CDC_', p_entity_name);

        BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER ' || v_trg_name; EXCEPTION WHEN OTHERS THEN NULL; END;
        BEGIN EXECUTE IMMEDIATE 'DROP SYNONYM ' || v_syn_table; EXCEPTION WHEN OTHERS THEN NULL; END;
        BEGIN EXECUTE IMMEDIATE 'DROP SYNONYM ' || v_syn_seq; EXCEPTION WHEN OTHERS THEN NULL; END;
        
        FOR r IN (SELECT LOG_TABLE_NAME, QUEUE_ID FROM TBL_SL_CDC_LOG_QUEUE WHERE ENTITY_NAME = p_entity_name) LOOP
            BEGIN EXECUTE IMMEDIATE 'DROP TABLE ' || r.LOG_TABLE_NAME || ' PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
            BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_SL_LOG_' || r.QUEUE_ID; EXCEPTION WHEN OTHERS THEN NULL; END;
        END LOOP;
        
        DELETE FROM TBL_SL_CDC_LOG_QUEUE WHERE ENTITY_NAME = p_entity_name;
        COMMIT;
    END;

END PKG_SL_CDC_MANAGER;