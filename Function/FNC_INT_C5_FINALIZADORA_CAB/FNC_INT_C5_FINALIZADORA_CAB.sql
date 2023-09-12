CREATE OR REPLACE FUNCTION FNC_INT_C5_FINALIZADORA_CAB (pSeqDocto NUMBER,
                                      pNumeroCaixa NUMBER,
                                      pCodigoFilial VARCHAR2)
    RETURN VARCHAR2
IS
    vFinalizadora VARCHAR2(4);

BEGIN
SELECT  CASE
            WHEN p.nroformapagto in (SELECT DISTINCT
                                           f.nroformapagto
                                      FROM monitorpdvmiddle.tb_formapagto f)
                THEN p.nroformapagto
            ELSE
                0
         END
  INTO  vFinalizadora
  FROM  monitorpdvmiddle.tb_doctopagto p,
        monitorpdvmiddle.tb_docto a
 WHERE  p.seqdocto = a.seqdocto
   AND  a.seqdocto = pSeqDocto
   AND  a.nroempresa = pCodigoFilial
   AND  a.nrocheckout = pNumeroCaixa
   AND  ROWNUM = 1;
 RETURN(vFinalizadora);
END;
