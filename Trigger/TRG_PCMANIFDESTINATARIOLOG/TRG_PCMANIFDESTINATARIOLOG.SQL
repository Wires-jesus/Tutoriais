CREATE OR REPLACE TRIGGER TRG_PCMANIFDESTINATARIOLOG
 BEFORE INSERT OR DELETE OR UPDATE
 ON PCMANIFDESTINATARIO
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
  BEGIN
    IF UPDATING THEN
      INSERT INTO PCMANIFDESTINATARIOLOG
                  (CODIGO
                 , DATA
                 , CODFILIAL
                 , SITCONFIRMACAODEST
                 , TIPOEVENTO
                 , PROTOCOLOEVENTO
                 , DESCRICAOEVENTO
                 , MAQUINA
                 , USUARIOSO
                 , PROGRAMA
                 , CODFUNCLANC)
           VALUES (:OLD.CODIGO
                 , SYSDATE
                 , :OLD.CODFILIAL
                 , :OLD.SITCONFIRMACAODEST
                 , :OLD.TIPOEVENTO
                 , :OLD.PROTOCOLOEVENTO
                 , :OLD.DESCRICAOEVENTO
                 , SYS_CONTEXT('USERENV', 'HOST')
                 , SYS_CONTEXT('USERENV', 'OS_USER')
                 , SYS_CONTEXT('USERENV', 'MODULE')
                 , 1);  
    ELSIF INSERTING THEN
      INSERT INTO PCMANIFDESTINATARIOLOG
                  (CODIGO
                 , DATA
                 , CODFILIAL
                 , SITCONFIRMACAODEST
                 , TIPOEVENTO
                 , PROTOCOLOEVENTO
                 , DESCRICAOEVENTO
                 , MAQUINA
                 , USUARIOSO
                 , PROGRAMA
                 , CODFUNCLANC)
           VALUES (:NEW.CODIGO
                 , SYSDATE
                 , :NEW.CODFILIAL
                 , :NEW.SITCONFIRMACAODEST
                 , :NEW.TIPOEVENTO
                 , :NEW.PROTOCOLOEVENTO
                 , :NEW.DESCRICAOEVENTO
                 , SYS_CONTEXT('USERENV', 'HOST')
                 , SYS_CONTEXT('USERENV', 'OS_USER')
                 , SYS_CONTEXT('USERENV', 'MODULE')
                 , 1);       
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
       NULL;
  END;
END TRG_PCMANIFDESTINATARIOLOG;
