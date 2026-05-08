CREATE OR REPLACE FUNCTION FNC_INT_C5_CBENEF(pUF         CHAR,
                                             pCFOP       NUMBER,
                                             pSittribut  VARCHAR2,
                                             pCodSt      VARCHAR2)
  RETURN VARCHAR2
  IS
    vCBenef  VARCHAR2(10);
BEGIN
  SELECT v.codigobeneficio
    INTO vCBenef
    FROM pccodigobeneficiofiscalvinculo v
    JOIN pccodigobeneficiofiscal c ON v.codigobeneficio = c.codigobeneficio
    WHERE v.ufdestino = pUF
      AND v.sittribut = pSittribut
      AND v.codfiscal = pCFOP
      AND v.figuratributaria = pCodSt
      AND ROWNUM = 1;
      
  RETURN vCBenef;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN NULL;
END FNC_INT_C5_CBENEF;