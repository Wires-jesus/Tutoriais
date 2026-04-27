DECLARE
    v_batch_size  NUMBER := 5000;
    v_total       NUMBER := 0;
    v_rows        NUMBER := 1;
BEGIN
    WHILE v_rows > 0 LOOP
        UPDATE PCCORTEI
        SET    QTORIG = 0            
        WHERE  QTORIG IS NULL
        AND    ROWNUM <= v_batch_size;

        v_rows  := SQL%ROWCOUNT;         -- Quantas linhas foram atualizadas neste lote
        
        -- Log de acompanhamento
        -- v_total := v_total + v_rows;

        COMMIT;

        -- Log de acompanhamento
        -- DBMS_OUTPUT.PUT_LINE('Lote processado: ' || v_rows || ' linhas | Total acumulado: ' || v_total);
    END LOOP;
    
    -- Log de acompanhamento
    -- DBMS_OUTPUT.PUT_LINE('*** Atualização concluída. Total de linhas atualizadas: ' || v_total || ' ***');
	
    EXECUTE IMMEDIATE 'ALTER TABLE PCCORTEI DROP CONSTRAINT PCCORTEI_PK';

    EXECUTE IMMEDIATE '
        ALTER TABLE PCCORTEI 
        ADD CONSTRAINT PCCORTEI_PK 
        PRIMARY KEY (CODPROD, NUMCAR, NUMPED, NUMSEQ, QTORIG)
    ';
END;