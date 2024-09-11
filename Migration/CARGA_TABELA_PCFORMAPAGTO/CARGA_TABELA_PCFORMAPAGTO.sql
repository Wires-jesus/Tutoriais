DECLARE
    iCOUNT Integer;
BEGIN    
------------------------------------------------------Carga de Forma de Pagamento------------------------------------------------------------
    FOR DADOS IN (
        SELECT 45 AS CODIGO, 'Pix Transferência' AS DESCRICAO, 'SIST' AS ORIGEM FROM DUAL UNION
        SELECT 47 AS CODIGO, 'QR-CODE PIX' AS DESCRICAO, 'SIST' AS ORIGEM FROM DUAL
    ) LOOP

        SELECT COUNT(*) INTO iCOUNT FROM PCFORMAPAGTO WHERE CODIGO = DADOS.CODIGO;

        IF iCOUNT = 0 THEN
            INSERT INTO PCFORMAPAGTO (CODIGO, DESCRICAO, ORIGEM) VALUES (DADOS.CODIGO, DADOS.DESCRICAO, DADOS.ORIGEM);
        ELSE
            UPDATE PCFORMAPAGTO SET
                DESCRICAO = DADOS.DESCRICAO,
                ORIGEM = DADOS.ORIGEM
            WHERE CODIGO = DADOS.CODIGO;
        END IF;
    END LOOP;
	
    dbms_output.put_line('Atualizou tabela de CNAEs');
    COMMIT;
------------------------------------------------------------Fim------------------------------------------------------------------
END;