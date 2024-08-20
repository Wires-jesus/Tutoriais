CREATE OR REPLACE TRIGGER T_MONITOR_DFES_PRESOS_PCNFSAID
  BEFORE INSERT OR UPDATE OF ESPECIE, SITUACAONFE ON PCNFSAID
  REFERENCING OLD AS OLD NEW AS NEW
  FOR EACH ROW
DECLARE
 VQTDREG NUMBER(10);
 VTIPODOC VARCHAR2(2);
 VSITUACAO NUMBER(5);
 CTIPOMOV VARCHAR2(1) := 'S';

 procedure GERAR_LOG(VNUMTRANSACAO IN NUMBER,
                     VTIPOMOV IN VARCHAR2,
                     VTIPODOC IN VARCHAR2,
                     VLOG IN VARCHAR2) is
   begin
    insert into PCMONITORDFESPRESOSLOG
      (NUMTRANSACAO,
                                        TIPOMOV,
                                        TIPODOC,
                                        DATA,
                                        LOG,
                                        TERMINAL,
                                        MAQUINA,
                                        PROGRAMA,
                                        OSUSER)
    values
      (VNUMTRANSACAO,
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
  IF UPDATING THEN    
    VSITUACAO := :NEW.SITUACAONFE;
      
  IF (NVL(:NEW.ESPECIE, :OLD.ESPECIE) IN ('NE', 'NF')) THEN
    VTIPODOC := 'NF';
  ELSIF (NVL(:NEW.ESPECIE, :OLD.ESPECIE) IN ('CE', 'CO')) THEN
    VTIPODOC := 'CT';
  END IF;

  IF (VTIPODOC IS NOT NULL AND VSITUACAO IN (1001, 103)) THEN
      GERAR_LOG(:OLD.NUMTRANSVENDA,
                CTIPOMOV,
                VTIPODOC,
                VTIPODOC || ' EM PROCESSAMENTO, SITUAÇÃO ' || VSITUACAO);

     SELECT COUNT(*)
       INTO VQTDREG
       FROM PCMONITORDFESPRESOS
      WHERE NUMTRANSACAO = :OLD.NUMTRANSVENDA;

     IF (VQTDREG = 0) THEN
        INSERT INTO PCMONITORDFESPRESOS
          (NUMTRANSACAO,
           TIPOMOV,
           TIPODOC,
           DATAULTIMAALTERACAO,
           ULTIMA_SITUACAO)
        VALUES
          (:OLD.NUMTRANSVENDA, CTIPOMOV, VTIPODOC, SYSDATE, VSITUACAO);
     ELSE
       UPDATE PCMONITORDFESPRESOS
           SET DATAULTIMAALTERACAO = SYSDATE, ULTIMA_SITUACAO = VSITUACAO
        WHERE NUMTRANSACAO = :OLD.NUMTRANSVENDA
          AND TIPODOC = VTIPODOC
          AND TIPOMOV = CTIPOMOV;
     END IF;
  ELSIF (VSITUACAO = 100) THEN
      GERAR_LOG(:OLD.NUMTRANSVENDA,
                CTIPOMOV,
                VTIPODOC,
                VTIPODOC || ' APROVADA!');

           DELETE FROM PCMONITORDFESPRESOS
            WHERE NUMTRANSACAO = :OLD.NUMTRANSVENDA
              AND TIPODOC = VTIPODOC;
  END IF;
  ELSIF INSERTING THEN
    IF (:NEW.SITUACAONFE = 100) THEN
      GERAR_LOG(:NEW.NUMTRANSVENDA,
                CTIPOMOV,
                'NF',
                'NF' || ' APROVADA!');
    
      DELETE FROM PCMONITORDFESPRESOS
       WHERE NUMTRANSACAO = :NEW.NUMTRANSVENDA
         AND TIPODOC = 'S';
    END IF;
  END IF;
END;
/
