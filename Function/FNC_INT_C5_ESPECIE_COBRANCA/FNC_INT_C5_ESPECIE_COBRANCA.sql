CREATE OR REPLACE FUNCTION FNC_INT_C5_ESPECIE_COBRANCA (pSeqDocto    IN NUMBER,
                                      pNumeroCaixa IN NUMBER,
                                      pCodigoFilial IN NUMBER)
    RETURN VARCHAR2
IS
    vEspecie VARCHAR2(4);


BEGIN
    SELECT  a.CODCOB
      INTO  vEspecie
      FROM  monitorpdvmiddle.tb_doctopagto p,
            monitorpdvmiddle.tb_formapagto f,
            vw_int_c5_finalizadora a
     WHERE  p.nroformapagto = f.nroformapagto
       AND  f.nroformapagto = a.NROFORMAPAGTO
       AND  p.seqitem = 1
       AND  p.seqdocto = pSeqDocto
       AND  p.nroempresa = pCodigoFilial
       AND  p.nrocheckout = pNumeroCaixa;
  /*EXCEPTION
    WHEN OTHERS THEN
      RETURN 'D';*/

    RETURN(vEspecie);
END;
