CREATE OR REPLACE FUNCTION FNC_INT_C5_CBENEF(pUF         CHAR,
                                             pCFOP       NUMBER,
                                             pSittribut  VARCHAR2)
  RETURN VARCHAR2
  IS
    vCBenef  VARCHAR2(10);
  BEGIN

    SELECT  v.codigobeneficio
      INTO  vCBenef
      FROM  pccodigobeneficiofiscalvinculo v,
            pccodigobeneficiofiscal        c
     WHERE  v.codigobeneficio = c.codigobeneficio
       AND  v.ufdestino = pUF
       AND  v.sittribut = pSittribut
       AND  v.codfiscal = pCFOP
       AND  ROWNUM = 1;
    
    RETURN(vCBenef);
END;