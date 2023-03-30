CREATE OR REPLACE TRIGGER TRG_INTEGRA_MYFROTA_PCPREREQMC
  AFTER UPDATE ON PCPREREQMATCONSUMOC
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW
DECLARE
  xmlvalor       clob;
  CHAVETRANSACAO raw(16);
BEGIN
  SELECT SYS_GUID INTO CHAVETRANSACAO FROM DUAL;
  IF (:OLD.PRERECORIGEM = 'myfrota') THEN
    IF (NVL(:OLD.SITUACAO, '') <> NVL(:NEW.SITUACAO, '') AND
       NVL(:NEW.SITUACAO, '') = 'C') THEN
      SELECT xmltype.getclobval(XMLELEMENT("requisitions",
                                           XMLELEMENT("requisition",
                                                      XMLATTRIBUTES(:NEW.IDINTEGRACAOMYFROTA AS
                                                                    "SFT_External_Id"),
                                                      XMLELEMENT("transp__SFT_Transaction_Number__c",
                                                                 CHAVETRANSACAO),
                                                      XMLELEMENT("transp__SFT_Status__c",
                                                                 'Cancelado'))))
        INTO xmlvalor
        FROM dual;
      INSERT INTO PCMYFROTA_FILA
        (CHAVE, OPERACAO, DADOS)
      VALUES
        (CHAVETRANSACAO, 'CancelarRequisicaoMyFrota', xmlvalor);
    END IF;
  END IF;
END;
