-- 08_PKG_SL_BACKGROUND_PROCESS.sql
-- Descrição: Processa solicitações de rotação de log de forma assíncrona.

CREATE OR REPLACE PACKAGE BODY PKG_SL_BACKGROUND_PROCESS AS
    PROCEDURE PROCESS_ROTATION_REQUESTS IS
        TYPE t_entity_list IS TABLE OF TBL_SL_ROTATION_REQUESTS.ENTITY_NAME%TYPE;
        v_entities_to_process t_entity_list;
    BEGIN
        -- Coleta todas as entidades pendentes para uma coleção em memória para evitar "fetch across commit".
        SELECT ENTITY_NAME
        BULK COLLECT INTO v_entities_to_process
        FROM TBL_SL_ROTATION_REQUESTS;

        IF v_entities_to_process IS NULL OR v_entities_to_process.COUNT = 0 THEN
            RETURN;
        END IF;

        -- Itera sobre a coleção em memória.
        FOR i IN 1 .. v_entities_to_process.COUNT LOOP
            DECLARE
                v_current_entity VARCHAR2(30) := v_entities_to_process(i);
            BEGIN
                PKG_SL_LOGGING.WRITE_LOG('INFO', 'PKG_SL_BACKGROUND_PROCESS', 'PROCESS_ROTATION', 'Processando rotação para: ' || v_current_entity);

                -- Chama a procedure de rotação
                PKG_SL_CDC_MANAGER.ROTATE_LOG_TABLE(v_current_entity);

                -- Remove a solicitação da fila, pois foi atendida.
                DELETE FROM TBL_SL_ROTATION_REQUESTS WHERE ENTITY_NAME = v_current_entity;

                -- Comita a transação para esta entidade.
                COMMIT;
                PKG_SL_LOGGING.WRITE_LOG('INFO', 'PKG_SL_BACKGROUND_PROCESS', 'PROCESS_ROTATION', 'Rotação para ' || v_current_entity || ' concluída.');

            EXCEPTION
                WHEN OTHERS THEN
                    ROLLBACK;
                    PKG_SL_LOGGING.WRITE_LOG('ERROR', 'PKG_SL_BACKGROUND_PROCESS', 'PROCESS_ROTATION', 'Falha ao processar rotação para ' || v_current_entity || ': ' || SQLERRM);
            END;
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            PKG_SL_LOGGING.WRITE_LOG('FATAL', 'PKG_SL_BACKGROUND_PROCESS', 'PROCESS_ROTATION', 'Erro inesperado no job de rotação: ' || SQLERRM);
    END PROCESS_ROTATION_REQUESTS;
END PKG_SL_BACKGROUND_PROCESS;
