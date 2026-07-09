CREATE OR REPLACE TRIGGER TRG_PCRECEBIMENTOJUROSDESCONTO
AFTER UPDATE ON PCPREST
FOR EACH ROW
BEGIN

    PKG_FINANCEIRO.PROCESSA_RECEBIMENTO_JD(:OLD.DTPAG,
                                           :NEW.DTPAG,
                                           :NEW.CODCOB,
                                           :NEW.DTESTORNO,
                                           :NEW.NUMTRANSVENDA,
                                           :NEW.PREST,
                                           :NEW.CODCLI,
                                           :NEW.CODFILIAL,
                                           :NEW.VPAGO,
                                           :NEW.VALORMULTA,
                                           :NEW.TXPERM,
                                           :NEW.VALORDESC,
                                           :NEW.DTPAG,
                                           :NEW.NUMTRANSVENDAORIG,
                                           :NEW.PRESTORIG);

END;