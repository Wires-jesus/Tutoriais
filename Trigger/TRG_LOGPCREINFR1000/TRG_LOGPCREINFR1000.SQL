CREATE OR REPLACE TRIGGER TRG_LOGPCREINFR1000
  BEFORE INSERT OR UPDATE OR DELETE ON PCREINFR1000
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW
DECLARE
  CHAVE VARCHAR2(2000);
  ACAO  VARCHAR2(10);
BEGIN
  IF INSERTING THEN
    CHAVE := 'GRUPOID: ' || NVL(:NEW.GRUPOID,'') || ' |INIVALID: ' || NVL(:NEW.INIVALID,'') || '|';
    ACAO  := 'INSERT';
  ELSIF UPDATING THEN
    CHAVE := 'GRUPOID: ' || NVL(:NEW.GRUPOID,'') || ' |INIVALID: ' || NVL(:NEW.INIVALID,'') || '|'; 
    ACAO  := 'UPDATE';
  ELSIF DELETING THEN
    CHAVE := 'GRUPOID: ' || NVL(:OLD.GRUPOID,'') || ' |INIVALID: ' || NVL(:OLD.INIVALID,'') || '|';
    ACAO  := 'DELETE';
  END IF;
  
  INSERT INTO PCLOGALTERACAODADOS(DATA,
                                  TABELA,
                                  PROGRAMA,
                                  TERMINAL,
                                  OSUSER,
                                  OBSERVACOES,
                                  OBSERVACOES2) VALUES 
                                 (SYSDATE,
                                  'PCREINFR1000',
                                  SYS_CONTEXT('USERENV', 'MODULE'),
                                  SYS_CONTEXT('USERENV', 'TERMINAL'),
                                  SYS_CONTEXT('USERENV', 'OS_USER'),
                                  ACAO,
                                  CHAVE);  
END;