CREATE OR REPLACE TRIGGER TRG_PCEMAILDFE_ENVIADO
 BEFORE DELETE ON PCEMAILDFE
 REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
DECLARE
BEGIN
  IF :OLD.PROCESSADO <> 'E' THEN
    INSERT INTO PCEMAILDFEENVIADO
                (NUMTRANSACAO
               , TIPOMOV
               , CODFILIAL
               , TIPODOC
               , TIPOENVIO
               , EMAIL
               , NUMNOTA
               , CHAVEDFE
               , DESTINATARIO
               , ORIGEM
               , PROCESSADO
               , MENSAGEM
               , DTINCLUSAO)
         VALUES (:OLD.NUMTRANSACAO
               , :OLD.TIPOMOV
               , :OLD.CODFILIAL
               , :OLD.TIPODOC
               , :OLD.TIPOENVIO
               , :OLD.EMAIL
               , :OLD.NUMNOTA
               , :OLD.CHAVEDFE
               , :OLD.DESTINATARIO
               , :OLD.ORIGEM
               , :OLD.PROCESSADO
               , :OLD.MENSAGEM
               , SYSDATE);
  END IF;
END;
