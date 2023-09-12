CREATE OR REPLACE FUNCTION FNC_INT_C5_VLTOTAL (pSeqDocto number,
                                                   pNumeroCaixa NUMBER,
                                                   pCodigoFilial VARCHAR2)
    RETURN NUMBER
IS
    vTotal NUMBER;

BEGIN
    SELECT  SUM(p.valor)
      INTO  vTotal
      FROM  monitorpdvmiddle.tb_doctopagto p
     WHERE  p.seqdocto = pSeqDocto
       AND  p.nroempresa = pCodigoFilial
       AND  p.nrocheckout = pNumeroCaixa;
    RETURN(vTotal);
END;
