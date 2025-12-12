-- 02_CREATE_INFRASTRUCTURE.sql
-- Descrição: Procedure para criar a infraestrutura (Idempotente / Compatível 10g-19c)

CREATE OR REPLACE PROCEDURE PRC_SL_SETUP_INFRASTRUCTURE (
    p_force_recreate IN NUMBER DEFAULT 0 -- 0 = Preserva se existir; 1 = Dropa e recria tudo
) IS
    v_action_log VARCHAR2(4000);

    -- Sub-procedure para executar DDL de criação com tratamento de erro -955 (Objeto já existe)
    PROCEDURE execute_create_ddl(p_ddl IN VARCHAR2, p_message IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_ddl;
        DBMS_OUTPUT.PUT_LINE(p_message);
    EXCEPTION
        WHEN OTHERS THEN
            -- ORA-00955: name is already used by an existing object
            IF SQLCODE = -955 THEN 
                DBMS_OUTPUT.PUT_LINE('- Objeto ja existe (Ignorado): ' || REGEXP_SUBSTR(p_message, '\+ (Tabela|Sequence) \w+') );
            ELSE
                DBMS_OUTPUT.PUT_LINE('ERRO FATAL ao criar: ' || p_message);
                DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE || ' - ' || SQLERRM);
                RAISE;
            END IF;
    END;

    -- Sub-procedure para dropar objetos (apenas se force_recreate = 1)
    PROCEDURE execute_drop_ddl(p_type IN VARCHAR2, p_name IN VARCHAR2) IS
    BEGIN
        IF p_force_recreate = 1 THEN
            BEGIN
                IF p_type = 'TABLE' THEN
                    EXECUTE IMMEDIATE 'DROP TABLE ' || p_name || ' CASCADE CONSTRAINTS';
                ELSIF p_type = 'SEQUENCE' THEN
                    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || p_name;
                END IF;
                DBMS_OUTPUT.PUT_LINE('! Objeto dropado (Force Mode): ' || p_name);
            EXCEPTION
                WHEN OTHERS THEN
                    -- ORA-00942: table or view does not exist
                    -- ORA-02289: sequence does not exist
                    IF SQLCODE IN (-942, -2289) THEN
                        NULL; -- Ignora se não existe
                    ELSE
                        DBMS_OUTPUT.PUT_LINE('Aviso ao dropar ' || p_name || ': ' || SQLERRM);
                    END IF;
            END;
        END IF;
    END;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Iniciando Setup Infraestrutura v4.1 (Cross-Version)');
    IF p_force_recreate = 1 THEN
        DBMS_OUTPUT.PUT_LINE('*** MODO FORCE RECREATE ATIVADO: DADOS SERAO PERDIDOS ***');
    END IF;

    ----------------------------------------------------------------------------
    -- 1. FASE DE LIMPEZA (Apenas se p_force_recreate = 1)
    -- Ordem inversa das dependências (Filhos -> Pais)
    ----------------------------------------------------------------------------
    execute_drop_ddl('TABLE', 'TBL_SL_ROTATION_REQUESTS');
    execute_drop_ddl('SEQUENCE', 'SEQ_SL_CDC_LOG_QUEUE_ID');
    execute_drop_ddl('TABLE', 'TBL_SL_CDC_LOG_QUEUE');
    execute_drop_ddl('TABLE', 'TBL_SL_INITIAL_LOAD_CONTROL');
    execute_drop_ddl('TABLE', 'TBL_SL_ENTITY_COLUMNS');
    execute_drop_ddl('TABLE', 'TBL_SL_ENTITIES');
    execute_drop_ddl('TABLE', 'TBL_SL_IGNORED_DATA_TYPES');
    execute_drop_ddl('SEQUENCE', 'SEQ_SL_LOGGING_ID');
    execute_drop_ddl('TABLE', 'TBL_SL_LOGGING');

    ----------------------------------------------------------------------------
    -- 2. FASE DE CRIAÇÃO
    -- Ordem direta das dependências (Pais -> Filhos)
    ----------------------------------------------------------------------------

    -- 2.1 Logging
    execute_create_ddl(
        'CREATE TABLE TBL_SL_LOGGING (LOG_ID NUMBER, LOG_TIME TIMESTAMP DEFAULT SYSTIMESTAMP, LOG_LEVEL VARCHAR2(10), PACKAGE_NAME VARCHAR2(30), PROCEDURE_NAME VARCHAR2(30), MESSAGE CLOB, CONSTRAINT PK_SL_LOGGING PRIMARY KEY (LOG_ID))', 
        '+ Tabela TBL_SL_LOGGING criada.'
    );
    
    execute_create_ddl(
        'CREATE SEQUENCE SEQ_SL_LOGGING_ID START WITH 1 INCREMENT BY 1 NOCACHE', 
        '+ Sequence SEQ_SL_LOGGING_ID criada.'
    );

    -- 2.2 Configurações Globais
    execute_create_ddl(
        'CREATE TABLE TBL_SL_IGNORED_DATA_TYPES (DATA_TYPE VARCHAR2(30) NOT NULL, CONSTRAINT PK_SL_IGNORED_DATA_TYPES PRIMARY KEY (DATA_TYPE))', 
        '+ Tabela TBL_SL_IGNORED_DATA_TYPES criada.'
    );

    -- 2.3 Entidades (Mestre)
    execute_create_ddl('
    CREATE TABLE TBL_SL_ENTITIES (
        ENTITY_NAME                 VARCHAR2(30) NOT NULL,
        OWNER                       VARCHAR2(30) NOT NULL,
        SOURCE_TABLE_NAME           VARCHAR2(30) NOT NULL,
        ENTITY_TYPE                 VARCHAR2(20) DEFAULT ''MASTER'' NOT NULL,
        INITIAL_LOAD_STATUS         VARCHAR2(20) DEFAULT ''PENDING'' NOT NULL,
        CDC_ENABLED                 NUMBER(1,0) DEFAULT 0 NOT NULL,
        MAX_LOG_ROWS                NUMBER DEFAULT 20000 NOT NULL,
        CONFIG_VERSION              NUMBER DEFAULT 1 NOT NULL,
        KEY_TYPE                    VARCHAR2(10) DEFAULT ''NONE'' NOT NULL,
        CUSTOM_FILTER_CLAUSE        CLOB,
        PK_COLUMNS_LIST             VARCHAR2(4000),
        PK_WHERE_CLAUSE_PAGINATION  CLOB,
        JSON_SELECT_TEMPLATE        CLOB, 
        PK_JOIN_CLAUSE              CLOB, 
        SCHEMA_JSON                 CLOB,
        CONSTRAINT PK_SL_ENTITIES PRIMARY KEY (ENTITY_NAME),
        CONSTRAINT CHK_SL_ENTITIES_STATUS CHECK (INITIAL_LOAD_STATUS IN (''PENDING'', ''RUNNING'', ''COMPLETED'', ''ERROR'', ''RESETTING''))
    )', '+ Tabela TBL_SL_ENTITIES criada.');

    -- 2.4 Colunas das Entidades (Filha de Entities)
    execute_create_ddl('
    CREATE TABLE TBL_SL_ENTITY_COLUMNS (
        ENTITY_NAME     VARCHAR2(30) NOT NULL,
        COLUMN_NAME     VARCHAR2(30) NOT NULL,
        DATA_TYPE       VARCHAR2(128) NOT NULL, 
        IS_PK           NUMBER(1,0) DEFAULT 0 NOT NULL,
        IS_UK           NUMBER(1,0) DEFAULT 0 NOT NULL,
        PK_ORDER        NUMBER,
        CONSTRAINT PK_SL_ENTITY_COLUMNS PRIMARY KEY (ENTITY_NAME, COLUMN_NAME),
        CONSTRAINT FK_SL_ENTITY_COLUMNS_ENTITY FOREIGN KEY (ENTITY_NAME) REFERENCES TBL_SL_ENTITIES(ENTITY_NAME) ON DELETE CASCADE
    )', '+ Tabela TBL_SL_ENTITY_COLUMNS criada.');

    -- 2.5 Controle de Carga Inicial (Filha de Entities)
    execute_create_ddl(
        'CREATE TABLE TBL_SL_INITIAL_LOAD_CONTROL (ENTITY_NAME VARCHAR2(30) NOT NULL, START_TIME TIMESTAMP, END_TIME TIMESTAMP, RECORDS_PROCESSED NUMBER DEFAULT 0, LAST_PROCESSED_PK_CONCAT VARCHAR2(4000), CONSTRAINT PK_SL_INITIAL_LOAD_CONTROL PRIMARY KEY (ENTITY_NAME), CONSTRAINT FK_SL_INIT_LOAD_CTRL_ENT FOREIGN KEY (ENTITY_NAME) REFERENCES TBL_SL_ENTITIES(ENTITY_NAME) ON DELETE CASCADE)', 
        '+ Tabela TBL_SL_INITIAL_LOAD_CONTROL criada.'
    );

    -- 2.6 Fila de Logs CDC (Filha de Entities)
    execute_create_ddl('
    CREATE TABLE TBL_SL_CDC_LOG_QUEUE (
        QUEUE_ID                NUMBER NOT NULL,
        ENTITY_NAME             VARCHAR2(30) NOT NULL,
        LOG_TABLE_NAME          VARCHAR2(30) NOT NULL,
        STATUS                  VARCHAR2(20) DEFAULT ''ACTIVE'' NOT NULL,
        LAST_PROCESSED_LOG_ID   NUMBER DEFAULT 0 NOT NULL,
        CREATED_AT              TIMESTAMP DEFAULT SYSTIMESTAMP,
        UPDATED_AT              TIMESTAMP,
        CONSTRAINT PK_SL_CDC_LOG_QUEUE PRIMARY KEY (QUEUE_ID),
        CONSTRAINT UQ_SL_CDC_LOG_QUEUE_TABLE UNIQUE (LOG_TABLE_NAME),
        CONSTRAINT FK_SL_CDC_LOG_QUEUE_ENTITY FOREIGN KEY (ENTITY_NAME) REFERENCES TBL_SL_ENTITIES(ENTITY_NAME) ON DELETE CASCADE
    )', '+ Tabela TBL_SL_CDC_LOG_QUEUE criada.');

    execute_create_ddl(
        'CREATE SEQUENCE SEQ_SL_CDC_LOG_QUEUE_ID START WITH 1 INCREMENT BY 1 NOCACHE', 
        '+ Sequence SEQ_SL_CDC_LOG_QUEUE_ID criada.'
    );

    -- 2.7 Requisições de Rotação
    execute_create_ddl(
        'CREATE TABLE TBL_SL_ROTATION_REQUESTS (ENTITY_NAME VARCHAR2(30) NOT NULL, REQUEST_TIME TIMESTAMP DEFAULT SYSTIMESTAMP, CONSTRAINT PK_SL_ROTATION_REQUESTS PRIMARY KEY (ENTITY_NAME))', 
        '+ Tabela TBL_SL_ROTATION_REQUESTS criada.'
    );

    DBMS_OUTPUT.PUT_LINE('Infraestrutura verificada/criada com sucesso.');
END;
