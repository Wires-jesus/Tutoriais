-- 04_PKG_SL_LOGGING.sql
-- Descrição: Pacote para gravação de logs de execução em TBL_SL_LOGGING.
-- Utiliza transação autônoma para garantir o log mesmo em caso de rollback.

CREATE OR REPLACE PACKAGE PKG_SL_LOGGING AS

    PROCEDURE WRITE_LOG(
        p_log_level       IN VARCHAR2,
        p_package_name    IN VARCHAR2,
        p_procedure_name  IN VARCHAR2,
        p_message         IN CLOB
    );

END PKG_SL_LOGGING;
