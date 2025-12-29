CREATE OR REPLACE PACKAGE BODY PKG_SL_TRIGGER_GENERATOR AS

    -- Função auxiliar local (replicada para evitar dependência cruzada complexa)
    FUNCTION GET_SAFE_TRG_NAME(p_entity_name IN VARCHAR2) RETURN VARCHAR2 IS
        v_prefix CONSTANT VARCHAR2(10) := 'TRG_CDC_';
        v_max_len CONSTANT NUMBER := 30;
        v_avail   NUMBER;
    BEGIN
        v_avail := v_max_len - LENGTH(v_prefix);
        IF LENGTH(p_entity_name) > v_avail THEN
            RETURN v_prefix || SUBSTR(p_entity_name, 1, v_avail);
        ELSE
            RETURN v_prefix || p_entity_name;
        END IF;
    END;

    PROCEDURE GENERATE_FOR_ENTITY(p_entity_name IN VARCHAR2) AS
        v_trigger_body      CLOB;
        v_source_table      VARCHAR2(30);
        v_pk_concat_new     VARCHAR2(4000) := '';
        v_pk_concat_old     VARCHAR2(4000) := '';
        v_first             BOOLEAN := TRUE;
        v_trg_name          VARCHAR2(30);
    BEGIN
        PKG_SL_LOGGING.WRITE_LOG('INFO', 'PKG_SL_TRIGGER_GENERATOR', 'GENERATE_FOR_ENTITY', 'Gerando trigger para: ' || p_entity_name);

        SELECT SOURCE_TABLE_NAME INTO v_source_table FROM TBL_SL_ENTITIES WHERE ENTITY_NAME = p_entity_name;

        -- Gera nome seguro para a trigger
        v_trg_name := GET_SAFE_TRG_NAME(p_entity_name);

        FOR r IN (SELECT COLUMN_NAME FROM TBL_SL_ENTITY_COLUMNS 
                  WHERE ENTITY_NAME = p_entity_name AND (IS_PK = 1 OR IS_UK = 1) 
                  ORDER BY PK_ORDER) LOOP
            
            IF NOT v_first THEN
                v_pk_concat_new := v_pk_concat_new || ' || ''|#|'' || ';
                v_pk_concat_old := v_pk_concat_old || ' || ''|#|'' || ';
            END IF;

            v_pk_concat_new := v_pk_concat_new || 'TO_CHAR(:NEW.' || r.COLUMN_NAME || ')';
            v_pk_concat_old := v_pk_concat_old || 'TO_CHAR(:OLD.' || r.COLUMN_NAME || ')';
            
            v_first := FALSE;
        END LOOP;

        IF v_pk_concat_new IS NULL THEN
            v_pk_concat_new := '''NO_PK''';
            v_pk_concat_old := '''NO_PK''';
        END IF;

        v_trigger_body :=
            'CREATE OR REPLACE TRIGGER ' || v_trg_name || '
            AFTER INSERT OR UPDATE OR DELETE ON ' || v_source_table || '
            FOR EACH ROW
            DECLARE
                v_change_type CHAR(1);
                v_row_pk      VARCHAR2(4000);
            BEGIN
                IF INSERTING THEN v_change_type := ''I'';
                ELSIF UPDATING THEN v_change_type := ''U'';
                ELSE v_change_type := ''D''; END IF;

                IF v_change_type IN (''I'', ''U'') THEN
                    v_row_pk := ' || v_pk_concat_new || ';
                ELSE
                    v_row_pk := ' || v_pk_concat_old || ';
                END IF;

                PKG_SL_CDC_MANAGER.WRITE_TO_LOG(
                    p_entity_name => ''' || p_entity_name || ''',
                    p_change_type => v_change_type,
                    p_row_pk      => v_row_pk
                );
            EXCEPTION
                WHEN OTHERS THEN
                    PKG_SL_LOGGING.WRITE_LOG(''ERROR'', ''' || v_trg_name || ''', ''TRIGGER_EXEC'', ''Falha: '' || SQLERRM);
            END;';

        EXECUTE IMMEDIATE v_trigger_body;
        PKG_SL_LOGGING.WRITE_LOG('INFO', 'PKG_SL_TRIGGER_GENERATOR', 'GENERATE_FOR_ENTITY', 'Trigger ' || v_trg_name || ' criada com sucesso.');
    EXCEPTION
        WHEN OTHERS THEN
            PKG_SL_LOGGING.WRITE_LOG('ERROR', 'PKG_SL_TRIGGER_GENERATOR', 'GENERATE_FOR_ENTITY', 'Erro ao criar trigger para ' || p_entity_name || ': ' || SQLERRM);
            RAISE;
    END;

    PROCEDURE DROP_FOR_ENTITY(p_entity_name IN VARCHAR2) AS
        v_trg_name VARCHAR2(30);
    BEGIN
        v_trg_name := GET_SAFE_TRG_NAME(p_entity_name);
        EXECUTE IMMEDIATE 'DROP TRIGGER ' || v_trg_name;
    EXCEPTION WHEN OTHERS THEN NULL; END;

END PKG_SL_TRIGGER_GENERATOR;