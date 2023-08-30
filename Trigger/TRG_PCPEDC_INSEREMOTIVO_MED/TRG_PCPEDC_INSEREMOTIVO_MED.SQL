CREATE OR REPLACE TRIGGER TRG_PCPEDC_INSEREMOTIVO_MED
 BEFORE
  INSERT OR UPDATE
 ON PCPEDC
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
DECLARE
/*****************************************************************************
                           Historico de Alteracoes
------------------------------------------------------------------------------
 Data        Responsavel           Tarefa          Alteracao
 ----------  --------------------  -----------    --------------------------------
 20/09/2017  Jorge Humberto        HIS.03501.2017  Criacao do Programa
*****************************************************************************/
   VICONTADOR         INTEGER;
   VNCODIGO           INTEGER;
   rPCBLOQUEIOSPEDIDO PCBLOQUEIOSPEDIDO%rowtype;
BEGIN
  IF (NVL(:NEW.CODMOTIVO, 0) > 0) THEN
    SELECT COUNT(1)
      INTO VICONTADOR
      FROM PCBLOQUEIOSPEDIDO
     WHERE NUMPED = :NEW.NUMPED
       AND CODMOTIVO = :NEW.CODMOTIVO;

    IF VICONTADOR = 0 THEN
      SELECT dfseq_pcbloqueiospedido.NEXTVAL INTO VNCODIGO FROM DUAL;

      BEGIN
        SELECT DESCRICAO
          INTO rPCBLOQUEIOSPEDIDO.MOTIVO
          FROM PCMOTBLOQUEIO
         WHERE CODMOTIVO = :NEW.CODMOTIVO;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          rPCBLOQUEIOSPEDIDO.MOTIVO := substr(:NEW.MOTIVOPOSICAO, 1, 60);
      END;

      rPCBLOQUEIOSPEDIDO.CODIGO         := VNCODIGO;
      rPCBLOQUEIOSPEDIDO.NUMPED         := :NEW.NUMPED;
      rPCBLOQUEIOSPEDIDO.CODMOTIVO      := :NEW.CODMOTIVO;
      rPCBLOQUEIOSPEDIDO.CODMOTBLOQUEIO := :NEW.CODMOTBLOQUEIO;
      --rPCBLOQUEIOSPEDIDO.MOTIVO         := substr(:New.MOTIVOPOSICAO, 1, 60);
      rPCBLOQUEIOSPEDIDO.STATUS         := 'B';
      rPCBLOQUEIOSPEDIDO.TIPO           := 'C';

      INSERT INTO PCBLOQUEIOSPEDIDO VALUES RPCBLOQUEIOSPEDIDO;
    END IF;
  END IF;
END;
