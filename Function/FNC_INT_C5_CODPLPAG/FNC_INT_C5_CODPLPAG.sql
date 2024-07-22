CREATE OR REPLACE FUNCTION FNC_INT_C5_CODPLPAG(pNroFormaPagto NUMBER,
                             pCodFilial     VARCHAR2)
    RETURN NUMBER
IS
    vCodPlPag NUMBER;
BEGIN
    SELECT  a.codplpag
      INTO  vCodPlPag
      FROM  VW_INT_C5_FINALIZADORA a,
            monitorpdvmiddle.tb_doctopagto p,
			VW_INT_C5_OBTER_FILIAIS_C5 C5
     WHERE  p.nroformapagto = a.nroformapagto
       AND  p.nroempresa = C5.CODFILIALINTEGRACAO
	   AND  a.CODFILIAL = C5.CODFILIAL
       AND  a.nroformapagto = pNroFormaPagto
       AND  a.codfilial = pCodFilial
       AND  ROWNUM = 1;
    RETURN(vCodPlPag);
END;
