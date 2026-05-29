-- 09_PKG_SL_ORCHESTRATOR.sql
-- Descrição: Orquestra os processos de carga. 
-- Alteração: Ativação do CDC movida para o início da Carga Inicial para garantir captura durante o processo.

CREATE OR REPLACE PACKAGE PKG_SL_ORCHESTRATOR AS

    -- Inicia o processo de carga inicial e ativa o CDC imediatamente.
    PROCEDURE START_INITIAL_LOAD_PROCESS;

    -- Rotina de verificação/reparo para garantir que CDC está ativo após carga.
    PROCEDURE ACTIVATE_CDC_PROCESS;

    -- Força a rotação do log ativo.
    PROCEDURE FORCE_LOG_ROTATION(p_entity_name IN VARCHAR2 DEFAULT NULL);

    -- Reseta uma entidade para nova carga.
    PROCEDURE RESET_ENTITY(p_entity_name IN VARCHAR2);

    -- Confirma lote diferencial.
    PROCEDURE CONFIRM_DIFFERENTIAL_BATCH(
        p_queue_id    IN NUMBER,
        p_last_log_id IN NUMBER
    );

END PKG_SL_ORCHESTRATOR;

