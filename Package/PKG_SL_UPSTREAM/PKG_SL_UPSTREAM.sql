-- 10_PKG_SL_UPSTREAM.sql
-- Correção V6.1: Expansão completa do bloco de bind combinado (Start + End PKs) para até 10 colunas.
 
CREATE OR REPLACE PACKAGE PKG_SL_UPSTREAM AS

    PROCEDURE PROCESS_INITIAL_LOAD(
        p_entity_name   IN VARCHAR2,
        p_batch_size    IN NUMBER DEFAULT 1000,
        p_cursor        OUT SYS_REFCURSOR,
        p_rows_returned OUT NUMBER
    );

    PROCEDURE PROCESS_DIFFERENTIAL_LOAD(
        p_entity_name          IN VARCHAR2,
        p_batch_size           IN NUMBER,
        p_data_cursor          OUT SYS_REFCURSOR,
        p_queue_id             OUT NUMBER,
        p_last_log_id_in_batch OUT NUMBER,
        p_records_in_batch     OUT NUMBER
    );

    PROCEDURE CONFIRM_DIFFERENTIAL_BATCH(
        p_queue_id    IN NUMBER,
        p_last_log_id IN NUMBER
    );

    FUNCTION IS_TABLE_LOCKED_BY_TRANSACTION(p_table_name IN VARCHAR2) RETURN BOOLEAN;
    
    PROCEDURE CLEANUP_PROCESSED_LOGS(p_entity_name IN VARCHAR2);

END PKG_SL_UPSTREAM;
