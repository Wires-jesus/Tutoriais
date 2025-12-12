-- 09_PKG_SL_ORCHESTRATOR.sql
-- Descrição: Orquestra os processos de carga. 
-- Alteração: Ativação do CDC movida para o início da Carga Inicial para garantir captura durante o processo.

CREATE OR REPLACE PACKAGE BODY PKG_SL_ORCHESTRATOR AS

    PROCEDURE START_INITIAL_LOAD_PROCESS IS
    BEGIN
        PKG_SL_LOGGING.WRITE_LOG('INFO', 'PKG_SL_ORCHESTRATOR', 'START_INITIAL_LOAD', 'Iniciando Carga Inicial com Ativação Imediata de CDC...');
        
        FOR r_entity IN (SELECT ENTITY_NAME FROM TBL_SL_ENTITIES WHERE INITIAL_LOAD_STATUS = 'PENDING') LOOP
            BEGIN
                -- 1. Garante controle de carga
                MERGE INTO TBL_SL_INITIAL_LOAD_CONTROL c
                USING (SELECT r_entity.ENTITY_NAME AS entity_name FROM dual) s
                ON (c.ENTITY_NAME = s.entity_name)
                WHEN NOT MATCHED THEN
                    INSERT (ENTITY_NAME, START_TIME) VALUES (s.entity_name, SYSTIMESTAMP);

                -- 2. ATIVAÇÃO ANTECIPADA DO CDC (Alteração solicitada)
                -- Cria tabelas de log e triggers ANTES de começar a ler os dados.
                -- Isso garante que alterações durante a carga inicial sejam capturadas.
                PKG_SL_LOGGING.WRITE_LOG('INFO', 'PKG_SL_ORCHESTRATOR', 'START_INITIAL_LOAD', 'Ativando CDC preventivamente para: ' || r_entity.ENTITY_NAME);
                
                PKG_SL_CDC_MANAGER.CREATE_FIRST_LOG_TABLE(r_entity.ENTITY_NAME);
                PKG_SL_TRIGGER_GENERATOR.GENERATE_FOR_ENTITY(r_entity.ENTITY_NAME);

                -- 3. Atualiza status para RUNNING e marca CDC como habilitado
                UPDATE TBL_SL_ENTITIES 
                SET INITIAL_LOAD_STATUS = 'RUNNING',
                    CDC_ENABLED = 1 
                WHERE ENTITY_NAME = r_entity.ENTITY_NAME;

                COMMIT;
                PKG_SL_LOGGING.WRITE_LOG('INFO', 'PKG_SL_ORCHESTRATOR', 'START_INITIAL_LOAD', 'Carga inicial iniciada e CDC ativo para: ' || r_entity.ENTITY_NAME);
            EXCEPTION
                WHEN OTHERS THEN
                    ROLLBACK;
                    PKG_SL_LOGGING.WRITE_LOG('ERROR', 'PKG_SL_ORCHESTRATOR', 'START_INITIAL_LOAD', 'Falha ao iniciar carga/CDC para ' || r_entity.ENTITY_NAME || ': ' || SQLERRM);
            END;
        END LOOP;
        PKG_SL_LOGGING.WRITE_LOG('INFO', 'PKG_SL_ORCHESTRATOR', 'START_INITIAL_LOAD', 'Processo de início finalizado.');
    END START_INITIAL_LOAD_PROCESS;

    PROCEDURE ACTIVATE_CDC_PROCESS IS
    BEGIN
        -- Esta rotina agora serve como "Fallback" ou "Repair".
        -- No fluxo normal, o CDC já estará ativo (CDC_ENABLED=1) quando o status for COMPLETED.
        PKG_SL_LOGGING.WRITE_LOG('INFO', 'PKG_SL_ORCHESTRATOR', 'ACTIVATE_CDC', 'Verificando pendências de ativação de CDC...');
        
        FOR r_entity IN (SELECT e.ENTITY_NAME FROM TBL_SL_ENTITIES e WHERE e.INITIAL_LOAD_STATUS = 'COMPLETED' AND e.CDC_ENABLED = 0) LOOP
            BEGIN
                PKG_SL_LOGGING.WRITE_LOG('WARN', 'PKG_SL_ORCHESTRATOR', 'ACTIVATE_CDC', 'Ativação tardia de CDC para: ' || r_entity.ENTITY_NAME);
                PKG_SL_CDC_MANAGER.CREATE_FIRST_LOG_TABLE(r_entity.ENTITY_NAME);
                PKG_SL_TRIGGER_GENERATOR.GENERATE_FOR_ENTITY(r_entity.ENTITY_NAME);
                
                UPDATE TBL_SL_ENTITIES SET CDC_ENABLED = 1 WHERE ENTITY_NAME = r_entity.ENTITY_NAME;
                COMMIT;
            EXCEPTION
                WHEN OTHERS THEN
                    ROLLBACK;
                    PKG_SL_LOGGING.WRITE_LOG('ERROR', 'PKG_SL_ORCHESTRATOR', 'ACTIVATE_CDC', 'Falha na ativação tardia para ' || r_entity.ENTITY_NAME || ': ' || SQLERRM);
            END;
        END LOOP;
    END ACTIVATE_CDC_PROCESS;

    PROCEDURE FORCE_LOG_ROTATION(p_entity_name IN VARCHAR2 DEFAULT NULL) IS
    BEGIN
        PKG_SL_LOGGING.WRITE_LOG('INFO', 'PKG_SL_ORCHESTRATOR', 'FORCE_LOG_ROTATION', 'Iniciando rotação forçada para: ' || NVL(p_entity_name, 'TODAS'));
        FOR r_entity IN (SELECT ENTITY_NAME FROM TBL_SL_ENTITIES WHERE CDC_ENABLED = 1 AND (ENTITY_NAME = p_entity_name OR p_entity_name IS NULL)) LOOP
            BEGIN
                PKG_SL_CDC_MANAGER.ROTATE_LOG_TABLE(r_entity.ENTITY_NAME);
            EXCEPTION
                WHEN OTHERS THEN
                    PKG_SL_LOGGING.WRITE_LOG('ERROR', 'PKG_SL_ORCHESTRATOR', 'FORCE_LOG_ROTATION', 'Falha ao forçar rotação para ' || r_entity.ENTITY_NAME || ': ' || SQLERRM);
            END;
        END LOOP;
        PKG_SL_LOGGING.WRITE_LOG('INFO', 'PKG_SL_ORCHESTRATOR', 'FORCE_LOG_ROTATION', 'Processo de rotação forçada finalizado.');
    END FORCE_LOG_ROTATION;

    PROCEDURE RESET_ENTITY(p_entity_name IN VARCHAR2) IS
    BEGIN
        PKG_SL_LOGGING.WRITE_LOG('WARN', 'PKG_SL_ORCHESTRATOR', 'RESET_ENTITY', 'Solicitação de reset para: ' || p_entity_name);
        PKG_SL_CONFIGURATOR.RESET_ENTITY_FOR_RELOAD(p_entity_name);
        PKG_SL_LOGGING.WRITE_LOG('WARN', 'PKG_SL_ORCHESTRATOR', 'RESET_ENTITY', 'Entidade ' || p_entity_name || ' resetada.');
    EXCEPTION
        WHEN OTHERS THEN
            PKG_SL_LOGGING.WRITE_LOG('FATAL', 'PKG_SL_ORCHESTRATOR', 'RESET_ENTITY', 'Falha ao resetar ' || p_entity_name || ': ' || SQLERRM);
            RAISE;
    END RESET_ENTITY;

    PROCEDURE CONFIRM_DIFFERENTIAL_BATCH(
        p_queue_id    IN NUMBER,
        p_last_log_id IN NUMBER
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        UPDATE TBL_SL_CDC_LOG_QUEUE
        SET LAST_PROCESSED_LOG_ID = p_last_log_id,
            UPDATED_AT = SYSTIMESTAMP
        WHERE QUEUE_ID = p_queue_id;

        COMMIT;
        PKG_SL_LOGGING.WRITE_LOG('DEBUG', 'PKG_SL_ORCHESTRATOR', 'CONFIRM_DIFFERENTIAL_BATCH', 'Lote confirmado queue_id ' || p_queue_id || ' log_id ' || p_last_log_id);
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            PKG_SL_LOGGING.WRITE_LOG('ERROR', 'PKG_SL_ORCHESTRATOR', 'CONFIRM_BATCH', 'Erro: ' || SQLERRM);
            RAISE;
    END CONFIRM_DIFFERENTIAL_BATCH;

END PKG_SL_ORCHESTRATOR;
