CREATE OR REPLACE TRIGGER TRG_INTEGRA_MYFROTA_PCEMPR
  AFTER UPDATE OR INSERT ON pcempr
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW
DECLARE
  xmlvalor       clob;
  operacao       varchar2(50);
  CHAVETRANSACAO raw(16);
BEGIN
  SELECT SYS_GUID INTO CHAVETRANSACAO FROM DUAL;
  IF (UPDATING) THEN
    IF (:NEW.dt_exclusao is not null and :OLD.dt_exclusao is null) THEN
      SELECT xmltype.getclobval(XMLELEMENT("employee",
                                           XMLATTRIBUTES(:NEW.IDINTEGRACAOMYFROTA AS
                                                         "SFT_External_Id"),
                                           XMLELEMENT("transp__SFT_Active__c",
                                                      0)))
        INTO xmlvalor
        FROM dual;
      SELECT 'ExcluirFuncionarioMyFrota' into OPERACAO from dual;
    END IF;
  
    IF NOT (NVL(:NEW.MATRICULA, 0) = NVL(:OLD.MATRICULA, 0) AND
        NVL(:NEW.CODFILIAL, 0) = NVL(:OLD.CODFILIAL, 0) AND
        NVL(:NEW.NOME, 0) = NVL(:OLD.NOME, 0) AND
        NVL(:NEW.CNH, 0) = NVL(:OLD.CNH, 0) AND
        NVL(:NEW.DTVALIDADECNH, '') = NVL(:OLD.DTVALIDADECNH, '') AND
        NVL(:NEW.CATEGORIACNH, 0) = NVL(:OLD.CATEGORIACNH, 0) AND
        NVL(:NEW.DT_EXCLUSAO, '') = NVL(:OLD.DT_EXCLUSAO, '')) THEN
      SELECT xmltype.getclobval(XMLELEMENT("employee",
                                           XMLATTRIBUTES(:NEW.IDINTEGRACAOMYFROTA AS
                                                         "SFT_External_Id"),
                                           XMLELEMENT("transp__SFT_Transaction_Number__c",
                                                      CHAVETRANSACAO),
                                           XMLELEMENT("transp__SFT_Registration__c",
                                                      :NEW.MATRICULA),
                                           XMLELEMENT("transp__SFT_Company_Code__c",
                                                      :NEW.CODFILIAL),
                                           XMLELEMENT("name", :NEW.NOME),
                                           XMLELEMENT("transp__SFT_Employee_Function__c",
                                                      'A Definir'),
                                           XMLELEMENT("transp__SFT_HabilitationCode__c",
                                                      :NEW.CNH),
                                           XMLELEMENT("transp__SFT_HabilitationDueDate__c",
                                                      :NEW.DTVALIDADECNH),
                                           XMLELEMENT("transp__SFT_Category__c",
                                                      :NEW.CATEGORIACNH),
                                           XMLELEMENT("transp__SFT_IssuingEntity__c",
                                                      ' '),
                                           XMLELEMENT("transp__SFT_Active__c",
                                                      CAST(NVL(NVL(CAST(:NEW.DT_EXCLUSAO AS
                                                                        VARCHAR2(10)),
                                                                   '1'),
                                                               '0') AS
                                                           VARCHAR(1)))))
        INTO xmlvalor
        FROM dual;
      SELECT 'AlterarFuncionarioMyFrota' INTO operacao FROM dual;
    END IF;
  END IF;
  IF (INSERTING) THEN
    SELECT xmltype.getclobval(XMLELEMENT("employee",
                                         XMLATTRIBUTES(:NEW.IDINTEGRACAOMYFROTA AS
                                                       "SFT_External_Id"),
                                         XMLELEMENT("transp__SFT_Transaction_Number__c",
                                                    CHAVETRANSACAO),
                                         XMLELEMENT("transp__SFT_Registration__c",
                                                    NVL(CAST(:NEW.MATRICULA AS
                                                             VARCHAR2(50)),
                                                        ' ')),
                                         XMLELEMENT("transp__SFT_Company_Code__c",
                                                    NVL(CAST(:NEW.CODFILIAL AS
                                                             VARCHAR2(50)),
                                                        ' ')),
                                         XMLELEMENT("name",
                                                    NVL(:NEW.NOME, ' ')),
                                         XMLELEMENT("transp__SFT_Employee_Function__c",
                                                    'A Definir'),
                                         XMLELEMENT("transp__SFT_HabilitationCode__c",
                                                    NVL(CAST(:NEW.CNH AS
                                                             VARCHAR2(50)),
                                                        ' ')),
                                         XMLELEMENT("transp__SFT_HabilitationDueDate__c",
                                                    NVL(CAST(:NEW.DTVALIDADECNH AS
                                                             VARCHAR2(10)),
                                                        ' ')),
                                         XMLELEMENT("transp__SFT_Category__c",
                                                    NVL(:NEW.CATEGORIACNH,
                                                        ' ')),
                                         XMLELEMENT("transp__SFT_IssuingEntity__c",
                                                    ' '),
                                         XMLELEMENT("transp__SFT_Active__c",
                                                    CAST(NVL(NVL(CAST(:NEW.DT_EXCLUSAO AS
                                                                      VARCHAR2(10)),
                                                                 '1'),
                                                             '0') AS
                                                         VARCHAR(1)))))
      INTO xmlvalor
      FROM dual;
    SELECT 'IncluirFuncionarioMyFrota' INTO operacao FROM dual;
  END IF;
  IF (OPERACAO IN ('IncluirFuncionarioMyFrota', 'AlterarFuncionarioMyFrota',
      'ExcluirFuncionarioMyFrota')) THEN
    INSERT INTO PCMYFROTA_FILA
      (CHAVE, OPERACAO, DADOS)
    VALUES
      (CHAVETRANSACAO, operacao, xmlvalor);
  END IF;
END;
