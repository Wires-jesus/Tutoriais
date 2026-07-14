CREATE OR REPLACE TRIGGER TRG_PCPAGAMENTOJUROSDESCONTO
AFTER INSERT OR UPDATE ON PCLANC
FOR EACH ROW
BEGIN

    PKG_FINANCEIRO.PROCESSA_PAGAMENTO_JD(:NEW.RECNUM,
                                         :NEW.NUMNOTA,
                                         :NEW.CODFILIAL,
                                         :NEW.DUPLIC,
                                         :NEW.PREST,
                                         :NEW.CODFORNEC,
                                         :NEW.VPAGOBORDERO,
                                         :NEW.TXPERM,
                                         :NEW.DESCONTOFIN,
                                         :NEW.DTPAGTO,
                                         :NEW.RECNUMPRINC,
                                         :NEW.DTESTORNOBAIXA,
                                         :NEW.DTCANCEL,
                                         :NEW.DTDESD);

END;