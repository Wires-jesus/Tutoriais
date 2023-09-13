CREATE OR REPLACE FUNCTION FNC_INT_C5_TIPO_CANCEL_ITEM (pSeqDocto IN NUMBER,   pNumeroCaixa IN NUMBER,  pCodigoFilial IN VARCHAR2,   pSeqItem IN NUMBER)
 RETURN VARCHAR2 IS    
vTipoCancel VARCHAR2(1);
BEGIN    
  SELECT  CASE                
  WHEN i.status = 'C'                     
    AND                     
    c.status = 'V'                   
     THEN 'P'                
       ELSE  'T'             
         END      INTO  vTipoCancel      
   FROM  monitorpdvmiddle.tb_doctoitem i, monitorpdvmiddle.tb_doctocupom c,  monitorpdvmiddle.tb_docto a     
   WHERE  i.nrocheckout = a.nrocheckout      
    AND  i.nroempresa = a.nroempresa     
     AND  i.seqdocto = a.seqdocto      
      AND  a.nrocheckout = c.nrocheckout     
        AND  a.nroempresa = c.nroempresa       
        AND  a.seqdocto = c.seqdocto      
         AND  i.seqdocto = pSeqDocto      
         AND  i.seqitem = pSeqItem       
         AND  i.nroempresa = pCodigoFilial      
          AND  i.nrocheckout = pNumeroCaixa;       --AND  i.status = 'C';
RETURN(vTipoCancel);END;
