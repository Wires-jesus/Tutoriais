CREATE OR REPLACE TRIGGER TRG_INTEGRA_MYFROTA_PCCLIENT
  AFTER UPDATE OR INSERT ON pcclient
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW
DECLARE
  xmlvalor       clob;
  operacao       varchar2(50);
  CHAVETRANSACAO raw(16);

BEGIN
  SELECT SYS_GUID INTO CHAVETRANSACAO FROM DUAL;

  IF (UPDATING) THEN
    IF (:NEW.dtexclusao is not null and :OLD.dtexclusao is null) THEN
      SELECT xmltype.getclobval(XMLELEMENT("issuer",
                                           XMLATTRIBUTES(:NEW.IDINTEGRACAOMYFROTA AS
                                                         "SFT_External_Id"),
                                           XMLELEMENT("transp__SFT_Active__c",
                                                      0)))
        INTO xmlvalor
        FROM dual;
      SELECT 'ExcluirClienteMyFrota' into OPERACAO from dual;
    END IF;
    IF NOT (NVL(:NEW.CLIENTE, 0) = NVL(:OLD.CLIENTE, 0) AND
        NVL(:NEW.FANTASIA, 0) = NVL(:OLD.FANTASIA, 0) AND
        NVL(:NEW.CGCENT, 0) = NVL(:OLD.CGCENT, 0) AND
        NVL(:NEW.ENDERCOB, 0) = NVL(:OLD.ENDERCOB, 0) AND
        NVL(:NEW.MUNICCOB, 0) = NVL(:OLD.MUNICCOB, 0) AND
        NVL(:NEW.ESTCOB, 0) = NVL(:OLD.ESTCOB, 0) AND
        NVL(:NEW.CEPCOB, 0) = NVL(:OLD.CEPCOB, 0) AND
        NVL(:NEW.DTEXCLUSAO, '') = NVL(:OLD.DTEXCLUSAO, '')) THEN
      SELECT xmltype.getclobval(XMLELEMENT("issuer",
                                           XMLATTRIBUTES(:NEW.IDINTEGRACAOMYFROTA AS
                                                         "SFT_External_Id"),
                                           XMLELEMENT("name", :NEW.CLIENTE),
                                           XMLELEMENT("transp__SFT_Transaction_Number__c",
                                                      CHAVETRANSACAO),
                                           XMLELEMENT("transp__SFT_NickName__c",
                                                      :NEW.FANTASIA),
                                           XMLELEMENT("transP__SFT_CNPJ__c",
                                                      :NEW.CGCENT),
                                           XMLELEMENT("transp__SFT_Address__c",
                                                      :NEW.ENDERCOB),
                                           XMLELEMENT("transp__SFT_City__c",
                                                      :NEW.MUNICCOB),
                                           XMLELEMENT("transp__SFT_State__c",
                                                      :NEW.ESTCOB),
                                           XMLELEMENT("transp__SFT_Country__c",
                                                      ' '),
                                           XMLELEMENT("transp__SFT_Zip_Code__c",
                                                      :NEW.CEPCOB),
                                           XMLELEMENT("transp__SFT_Issuer_Type__c",
                                                      'Cliente'),
                                           XMLELEMENT("transp__SFT_Active__c",
                                                      CAST(NVL(NVL(CAST(:NEW.DTEXCLUSAO AS
                                                                        VARCHAR2(10)),
                                                                   '1'),
                                                               '0') AS
                                                           VARCHAR(1)))))
        INTO xmlvalor
        FROM dual;
    
      SELECT 'AlterarClienteMyFrota' INTO operacao FROM dual;
    END IF;
  END IF;
  IF (INSERTING) THEN
    SELECT xmltype.getclobval(XMLELEMENT("issuer",
                                         XMLATTRIBUTES(:NEW.IDINTEGRACAOMYFROTA AS
                                                       "SFT_External_Id"),
                                         XMLELEMENT("name",
                                                    NVL(:NEW.CLIENTE, ' ')),
                                         XMLELEMENT("transp__SFT_Transaction_Number__c",
                                                    CHAVETRANSACAO),
                                         XMLELEMENT("transp__SFT_NickName__c",
                                                    NVL(:NEW.FANTASIA, ' ')),
                                         XMLELEMENT("transP__SFT_CNPJ__c",
                                                    NVL(:NEW.CGCENT, ' ')),
                                         XMLELEMENT("transp__SFT_Address__c",
                                                    NVL(:NEW.ENDERCOB, ' ')),
                                         XMLELEMENT("transp__SFT_City__c",
                                                    NVL(:NEW.MUNICCOB, ' ')),
                                         XMLELEMENT("transp__SFT_State__c",
                                                    NVL(:NEW.ESTCOB, ' ')),
                                         XMLELEMENT("transp__SFT_Country__c",
                                                    ' '),
                                         XMLELEMENT("transp__SFT_Zip_Code__c",
                                                    NVL(:NEW.CEPCOB, ' ')),
                                         XMLELEMENT("transp__SFT_Issuer_Type__c",
                                                    'Cliente'),
                                         XMLELEMENT("transp__SFT_Active__c",
                                                    CAST(NVL(NVL(CAST(:NEW.DTEXCLUSAO AS
                                                                      VARCHAR2(10)),
                                                                 '1'),
                                                             '0') AS
                                                         VARCHAR(1)))))
      INTO xmlvalor
      FROM dual;
    SELECT 'IncluirClienteMyFrota' INTO operacao FROM dual;
  
  END IF;
  IF (OPERACAO IN ('IncluirClienteMyFrota', 'AlterarClienteMyFrota',
      'ExcluirClienteMyFrota')) THEN
    INSERT INTO PCMYFROTA_FILA
      (CHAVE, OPERACAO, DADOS)
    VALUES
      (CHAVETRANSACAO, operacao, xmlvalor);
  END IF;
END;
