CREATE OR REPLACE TRIGGER "T_MONITOR_DFES_PRESOS_PREFAT"
  BEFORE UPDATE ON PCNFSAIDPREFAT
  REFERENCING OLD AS OLD NEW AS NEW
  FOR EACH ROW
DECLARE
 VQTDREG NUMBER(10);
 VTIPODOC VARCHAR2(2);
 VSITUACAO NUMBER(5);
 CTIPOMOV VARCHAR2(2) := 'SP';

 procedure GERAR_LOG(VNUMTRANSACAO IN NUMBER,
                     VTIPOMOV IN VARCHAR2,
                     VTIPODOC IN VARCHAR2,
                     VLOG IN VARCHAR2) is
   begin
      insert into PCMONITORDFESPRESOSLOG(NUMTRANSACAO,
                                        TIPOMOV,
                                        TIPODOC,
                                        DATA,
                                        LOG,
                                        TERMINAL,
                                        MAQUINA,
                                        PROGRAMA,
                                        OSUSER)
                               values(VNUMTRANSACAO,
                                      VTIPOMOV,
                                      VTIPODOC,
                                      SYSDATE,
                                      VLOG,
                                      SYS_CONTEXT('USERENV', 'TERMINAL'),
                                      SYS_CONTEXT('USERENV', 'HOST'),
                                      SYS_CONTEXT('USERENV', 'MODULE'),
                                      SYS_CONTEXT('USERENV', 'OS_USER'));
   end;

BEGIN
  IF (NVL(:NEW.ESPECIE, :OLD.ESPECIE) IN ('NE', 'NF')) THEN
    VTIPODOC := 'NF';
    VSITUACAO := :NEW.SITUACAONFE;
  ELSIF (NVL(:NEW.ESPECIE, :OLD.ESPECIE) IN ('CE', 'CO')) THEN
    VTIPODOC := 'CT';
    VSITUACAO := :NEW.SITUACAOCTE;
  END IF;

  IF (VTIPODOC IS NOT NULL AND VSITUACAO IN (1001, 103, 100)) THEN
    IF (VSITUACAO = 100) THEN
       GERAR_LOG(:OLD.NUMTRANSVENDA, CTIPOMOV, VTIPODOC, VTIPODOC || ' APROVADA!');
    ELSE   
       GERAR_LOG(:OLD.NUMTRANSVENDA, 'S', VTIPODOC, VTIPODOC || ' EM PROCESSAMENTO, SITUAÇÃO ' || VSITUACAO);
    END IF;   

     SELECT COUNT(*)
       INTO VQTDREG
       FROM PCMONITORDFESPRESOS
      WHERE NUMTRANSACAO = :OLD.NUMTRANSVENDA;

     IF (VQTDREG = 0) THEN
       INSERT INTO PCMONITORDFESPRESOS (NUMTRANSACAO, TIPOMOV, TIPODOC, DATAULTIMAALTERACAO, ULTIMA_SITUACAO)
       VALUES (:OLD.NUMTRANSVENDA, CTIPOMOV, VTIPODOC, SYSDATE, VSITUACAO);
     ELSE
       UPDATE PCMONITORDFESPRESOS
          SET DATAULTIMAALTERACAO = SYSDATE,
              ULTIMA_SITUACAO = VSITUACAO
        WHERE NUMTRANSACAO = :OLD.NUMTRANSVENDA
          AND TIPODOC = VTIPODOC
          AND TIPOMOV = CTIPOMOV;
     END IF;
  END IF;
END;
