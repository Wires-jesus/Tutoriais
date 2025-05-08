CREATE OR REPLACE PROCEDURE PRC_BAIXA_CREDITOS_EXPIRADOS_C5 AS
    v_data_atual DATE := TRUNC(SYSDATE);
BEGIN

    UPDATE PCCRECLI
    SET DTDESCONTO = v_data_atual,
        DTCANCEL = v_data_atual,
        HISTORICO = 'Cancelamento realizado de forma automática em decorrência da expiração do cashback'
    WHERE DTVALIDADECASHBACK < v_data_atual
    AND CASHBACK = 'S'
    AND (DTDESCONTO IS NULL OR DTCANCEL IS NULL);
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END PRC_BAIXA_CREDITOS_EXPIRADOS;
/