CREATE OR REPLACE FUNCTION FNC_INT_C5_NUMPEDECF(pSEQDOCTO NUMBER,
                                                pNroCheckout NUMBER,
                                                pCodFilial VARCHAR2) 
  RETURN NUMBER
IS
    vNumpedecf NUMBER;
    vClob CLOB;
    vXMLDoc XMLTYPE;
BEGIN
  vNumpedecf := -1;
  BEGIN
   SELECT A.MENSAGEM
   INTO vClob
   FROM
   (SELECT M.MENSAGEM as MENSAGEM
     FROM PCFILAMENSAGEM M
    WHERE M.SEQDOCTO = pSEQDOCTO
      AND M.NUMCAIXA = pNroCheckout
      AND M.CODFILIAL = pCodFilial
      AND M.TIPOOPERACAO = 'VEND'
    UNION ALL
     SELECT MH.MENSAGEM as MENSAGEM
     FROM PCFILAMENSAGEMHISTORICO MH
    WHERE MH.SEQDOCTO = pSEQDOCTO
      AND MH.NUMCAIXA = TO_CHAR(pNroCheckout)
      AND MH.CODFILIAL = pCodFilial
      AND MH.TIPOOPERACAO = 'VEND'
    UNION ALL
     SELECT ME.MENSAGEM as MENSAGEM
     FROM PCFILAMENSAGEMERRO ME
    WHERE ME.SEQDOCTO = pSEQDOCTO
      AND ME.NUMCAIXA = pNroCheckout
      AND ME.CODFILIAL = pCodFilial
      AND ME.TIPOOPERACAO = 'VEND') A;
  EXCEPTION
    WHEN OTHERS THEN
    vNumpedecf := 0;   
  END; 
   
  IF (vNumpedecf < 0) THEN
    vXMLDoc := XMLType.createXML(vClob);
    vNumpedecf := TO_NUMBER(vXMLDoc.extract('/EsquemaExportacao/Pedido/Pedido/Numpedecf/text()').getStringVal());
  END IF; 

 RETURN(vNumpedecf);
END;