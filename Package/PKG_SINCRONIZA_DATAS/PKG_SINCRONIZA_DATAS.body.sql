CREATE OR REPLACE PACKAGE BODY PKG_SINCRONIZA_DATAS AS
    
    FUNCTION contar_discrepancias(p_data_inicio IN DATE) RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM pcnfsaid nf
        WHERE EXISTS (
            SELECT 1
            FROM pcmov mv
            WHERE mv.numtransvenda = nf.numtransvenda
            AND nf.dtsaida >= p_data_inicio
            AND mv.dtmov <> nf.dtsaida
            AND nf.dtcancel IS NULL
            AND nf.docemissao = 'CE'
        );
        
        RETURN v_count;
    EXCEPTION
        WHEN OTHERS THEN
            --DBMS_OUTPUT.PUT_LINE('Erro ao contar discrepâncias: ' || SQLERRM);
            RETURN -1;
    END contar_discrepancias;

    PROCEDURE sincronizar_datas_saida(p_data_inicio IN DATE) IS
        v_count_before NUMBER;
        v_count_after NUMBER;
        v_updated_rows NUMBER := 0;
        v_error_count NUMBER := 0;
        v_start_time TIMESTAMP := SYSTIMESTAMP;
    BEGIN
       -- DBMS_OUTPUT.PUT_LINE('Iniciando sincronização de datas a partir de ' || TO_CHAR(p_data_inicio, 'DD-MON-YYYY'));
        
        v_count_before := contar_discrepancias(p_data_inicio);
       -- DBMS_OUTPUT.PUT_LINE('Registros com discrepância encontrados: ' || v_count_before);
        
        FOR r IN (
            SELECT nf.numtransvenda
            FROM pcnfsaid nf
            WHERE EXISTS (
                SELECT 1
                FROM pcmov mv
                WHERE mv.numtransvenda = nf.numtransvenda
                AND nf.dtsaida >= p_data_inicio
                AND mv.dtmov <> nf.dtsaida
                AND nf.dtcancel IS NULL
                AND nf.docemissao = 'CE'
            )
            ORDER BY nf.numtransvenda
        ) LOOP
            BEGIN
                UPDATE pcnfsaid nf
                SET nf.dtsaida = (
                    SELECT MAX(mv.dtmov)
                    FROM pcmov mv
                    WHERE mv.numtransvenda = nf.numtransvenda
                )
                WHERE nf.numtransvenda = r.numtransvenda;
                
                v_updated_rows := v_updated_rows + 1;
                
                IF MOD(v_updated_rows, 100) = 0 THEN
                    COMMIT;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    v_error_count := v_error_count + 1;
                    --DBMS_OUTPUT.PUT_LINE('Erro ao atualizar numtransvenda ' || r.numtransvenda || ': ' || SQLERRM);
            END;
        END LOOP;
        
        COMMIT;
        v_count_after := contar_discrepancias(p_data_inicio);
        
        --DBMS_OUTPUT.PUT_LINE('Processo concluído. Registros atualizados: ' || v_updated_rows);
        --DBMS_OUTPUT.PUT_LINE('Erros encontrados: ' || v_error_count);
        --DBMS_OUTPUT.PUT_LINE('Tempo total: ' || EXTRACT(SECOND FROM (SYSTIMESTAMP - v_start_time)) || ' segundos');
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
           -- DBMS_OUTPUT.PUT_LINE('ERRO GRAVE: ' || SQLERRM);
            RAISE;
    END sincronizar_datas_saida;
END PKG_SINCRONIZA_DATAS;
