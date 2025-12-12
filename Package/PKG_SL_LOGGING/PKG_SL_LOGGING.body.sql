-- 04_PKG_SL_LOGGING.sql
-- Descrição: Pacote para gravação de logs de execução em TBL_SL_LOGGING.
-- Utiliza transação autônoma para garantir o log mesmo em caso de rollback.

CREATE OR REPLACE PACKAGE BODY PKG_SL_LOGGING AS

    PROCEDURE WRITE_LOG(
        p_log_level       IN VARCHAR2,
        p_package_name    IN VARCHAR2,
        p_procedure_name  IN VARCHAR2,
        p_message         IN CLOB
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO TBL_SL_LOGGING (
            LOG_ID,
            LOG_LEVEL,
            PACKAGE_NAME,
            PROCEDURE_NAME,
            MESSAGE
        ) VALUES (
            SEQ_SL_LOGGING_ID.NEXTVAL,
            p_log_level,
            p_package_name,
            p_procedure_name,
            p_message
        );
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            -- Em caso de falha no log, não podemos fazer nada para não entrar em loop.
            -- Apenas fazemos o rollback da transação autônoma.
            ROLLBACK;
    END WRITE_LOG;

END PKG_SL_LOGGING;
