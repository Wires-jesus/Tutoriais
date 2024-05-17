CREATE OR REPLACE TRIGGER "T_MONITOR_DFES_PRESOS_PCNFENT"
  BEFORE UPDATE ON PCNFENT
  REFERENCING OLD AS OLD NEW AS NEW
  FOR EACH ROW
DECLARE
 VQTDREG NUMBER(10);
 VTIPODOC VARCHAR2(2);
 VSITUACAO NUMBER(5);
 CTIPOMOV VARCHAR2(1) := 'E';

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
  ELSE
    VTIPODOC := 'CT';
    VSITUACAO := :NEW.SITUACAOCTE;
  END IF;

  IF (VSITUACAO IN (1001, 103)) THEN
     GERAR_LOG(:OLD.NUMTRANSENT, 'S', VTIPODOC, VTIPODOC || ' EM PROCESSAMENTO, SITUAÇÃO ' || VSITUACAO);

     SELECT COUNT(*)
       INTO VQTDREG
       FROM PCMONITORDFESPRESOS
      WHERE NUMTRANSACAO = :OLD.NUMTRANSENT;

     IF (VQTDREG = 0) THEN
       INSERT INTO PCMONITORDFESPRESOS (NUMTRANSACAO, TIPOMOV, TIPODOC, DATAULTIMAALTERACAO, ULTIMA_SITUACAO)
       VALUES (:OLD.NUMTRANSENT, CTIPOMOV, VTIPODOC, SYSDATE, VSITUACAO);
     ELSE
       UPDATE PCMONITORDFESPRESOS
          SET DATAULTIMAALTERACAO = SYSDATE,
              ULTIMA_SITUACAO = VSITUACAO
        WHERE NUMTRANSACAO = :OLD.NUMTRANSENT
          AND TIPODOC = VTIPODOC
          AND TIPOMOV = CTIPOMOV;
     END IF;
  ELSIF (VSITUACAO = 100) THEN
       GERAR_LOG(:OLD.NUMTRANSENT, CTIPOMOV, VTIPODOC, VTIPODOC || ' APROVADA!');

           DELETE FROM PCMONITORDFESPRESOS
            WHERE NUMTRANSACAO = :OLD.NUMTRANSENT
              AND TIPODOC = VTIPODOC
              AND TIPOMOV = CTIPOMOV;
  END IF;
END;
