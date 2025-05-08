CREATE OR REPLACE PROCEDURE PRC_INT_C5_BAIXACREDEXP AS
    v_data_atual DATE := TRUNC(SYSDATE);
BEGIN

    UPDATE PCCRECLI
    SET DTDESCONTO = v_data_atual,
        DTCANCEL = v_data_atual,
        HISTORICO = 'Cancelamento realizado de forma automática em decorrência da expiração do cashback'
    WHERE DTVALIDADECASHBACK < v_data_atual
    AND CASHBACK = 'S'
    AND DTDESCONTO IS NULL
  AND DTCANCEL IS NULL;
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END PRC_INT_C5_BAIXACREDEXP;
/