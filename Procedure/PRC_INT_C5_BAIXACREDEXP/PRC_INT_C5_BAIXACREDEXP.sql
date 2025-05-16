CREATE OR REPLACE PROCEDURE PRC_INT_C5_BAIXACREDEXP(
                                                      PS_CODROTINA         IN VARCHAR2,
                                                      PN_MATRICULA         IN NUMBER) AS
  V_DATA_ATUAL DATE := TRUNC(SYSDATE);
BEGIN
  FOR REG IN (SELECT CODFILIAL, CODCLI, VALOR, CODIGO, 'E' AS TIPO
              FROM PCCRECLI
             WHERE DTVALIDADECASHBACK < TRUNC(SYSDATE)
               AND CASHBACK = 'S'
               AND DTDESCONTO IS NULL
               AND DTCANCEL IS NULL)
  LOOP
    BEGIN 
      UPDATE PCCRECLI
         SET DTDESCONTO = V_DATA_ATUAL,
             DTCANCEL   = V_DATA_ATUAL,
             HISTORICO  = 'Cancelamento realizado de forma automática em decorrência da expiração do cashback'
       WHERE CODIGO = REG.CODIGO
         AND CODFILIAL = REG.CODFILIAL
         AND CODCLI = REG.CODCLI
         AND VALOR = REG.VALOR
         AND DTVALIDADECASHBACK < V_DATA_ATUAL
         AND CASHBACK = 'S'
         AND DTDESCONTO IS NULL
         AND DTCANCEL IS NULL;
     
      PKG_GERAPCLANCCREDITO.P_GERARLANCAMENTO(REG.CODFILIAL,
                                              REG.CODCLI,
                                              REG.VALOR,
                                              PS_CODROTINA,
                                              PN_MATRICULA,
                                              REG.CODIGO,
                                              'E');
    EXCEPTION
      WHEN OTHERS THEN
        NULL; 
    END;
  END LOOP;
  
  COMMIT;
END PRC_INT_C5_BAIXACREDEXP;