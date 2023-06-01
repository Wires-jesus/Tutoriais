CREATE OR REPLACE TRIGGER TRG_INTEGRA_MYFROTA_PCFORNEC
  AFTER UPDATE OR INSERT ON pcfornec
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW
DECLARE
  xmlvalor       clob;
  operacao       varchar2(50);
  pais_new       varchar2(50);
  CHAVETRANSACAO raw(16);
  qpais          int;
BEGIN

  SELECT SYS_GUID INTO CHAVETRANSACAO FROM DUAL;

  SELECT COUNT(*) INTO qpais FROM PCPAIS WHERE CODPAIS = :NEW.CODPAIS;

  IF (qpais > 0) THEN
    SELECT DESCRICAO
      INTO pais_new
      FROM PCPAIS
     WHERE CODPAIS = :NEW.CODPAIS;
  END IF;

  IF (UPDATING) THEN
    IF (:NEW.dtexclusao is not null and :OLD.dtexclusao is null) THEN
      SELECT xmltype.getclobval(XMLELEMENT("issuer",
                                           XMLATTRIBUTES(:NEW.IDINTEGRACAOMYFROTA AS
                                                         "SFT_External_Id"),
                                           XMLELEMENT("transp__SFT_Active__c",
                                                      '0')))
        INTO xmlvalor
        FROM dual;
      SELECT 'ExcluirFornecedorMyFrota' into OPERACAO from dual;
    END IF;
    IF NOT (
        
         NVL(:NEW.FORNECEDOR, 0) = NVL(:OLD.FORNECEDOR, 0) AND
         NVL(:NEW.FANTASIA, 0) = NVL(:OLD.FANTASIA, 0) AND
         NVL(:NEW.CGC, 0) = NVL(:OLD.CGC, 0) AND
         NVL(:NEW.ENDER, 0) = NVL(:OLD.ENDER, 0) AND
         NVL(:NEW.CIDADE, 0) = NVL(:OLD.CIDADE, 0) AND
         NVL(:NEW.ESTADO, 0) = NVL(:OLD.ESTADO, 0) AND
         NVL(:NEW.CEP, 0) = NVL(:OLD.CEP, 0) AND
         NVL(:NEW.BLOQUEIO, 0) = NVL(:OLD.BLOQUEIO, 0) AND
         NVL(:NEW.CODPAIS, 0) = NVL(:OLD.CODPAIS, 0) AND
         NVL(:NEW.DTEXCLUSAO, trunc(sysdate)) =
         NVL(:OLD.DTEXCLUSAO, trunc(sysdate))
        
        ) THEN
      SELECT xmltype.getclobval(XMLELEMENT("issuer",
                                           XMLATTRIBUTES(:NEW.IDINTEGRACAOMYFROTA AS
                                                         "SFT_External_Id"),
                                           XMLELEMENT("name",
                                                      :NEW.FORNECEDOR),
                                           XMLELEMENT("transp__SFT_Transaction_Number__c",
                                                      CHAVETRANSACAO),
                                           XMLELEMENT("transp__SFT_NickName__c",
                                                      :NEW.FANTASIA),
                                           XMLELEMENT("transp__SFT_Supplier_Type__c",
                                                      'Outros'),
                                           XMLELEMENT("transP__SFT_CNPJ__c",
                                                      :NEW.CGC),
                                           XMLELEMENT("transp__SFT_Address__c",
                                                      :NEW.ENDER),
                                           XMLELEMENT("transp__SFT_City__c",
                                                      :NEW.CIDADE),
                                           XMLELEMENT("transp__SFT_State__c",
                                                      :NEW.ESTADO),
                                           XMLELEMENT("transp__SFT_Zip_Code__c",
                                                      :NEW.CEP),
                                           XMLELEMENT("transp__SFT_Issuer_Type__c",
                                                      'Fornecedor'),
                                           XMLELEMENT("transp__SFT_Active__c",
                                                      CAST(NVL(NVL(CAST(:NEW.DTEXCLUSAO AS
                                                                        VARCHAR2(10)),
                                                                   '1'),
                                                               '0') AS
                                                           VARCHAR(1))),
                                           XMLELEMENT("transp__SFT_Country__c",
                                                      pais_new)
                                           
                                           ))
        INTO xmlvalor
        FROM dual;
    
      SELECT 'AlterarFornecedorMyFrota' INTO operacao FROM dual;
    END IF;
  END IF;
  IF (INSERTING) THEN
    SELECT xmltype.getclobval(XMLELEMENT("issuer",
                                         XMLATTRIBUTES(:NEW.IDINTEGRACAOMYFROTA AS
                                                       "SFT_External_Id"),
                                         XMLELEMENT("name",
                                                    NVL(:NEW.FORNECEDOR, ' ')),
                                         XMLELEMENT("transp__SFT_Transaction_Number__c",
                                                    CHAVETRANSACAO),
                                         XMLELEMENT("transp__SFT_NickName__c",
                                                    NVL(:NEW.FANTASIA, ' ')),
                                         XMLELEMENT("transp__SFT_Supplier_Type__c",
                                                    'Outros'),
                                         XMLELEMENT("transP__SFT_CNPJ__c",
                                                    NVL(:NEW.CGC, ' ')),
                                         XMLELEMENT("transp__SFT_Address__c",
                                                    NVL(:NEW.ENDER, ' ')),
                                         XMLELEMENT("transp__SFT_City__c",
                                                    NVL(:NEW.CIDADE, ' ')),
                                         XMLELEMENT("transp__SFT_State__c",
                                                    NVL(:NEW.ESTADO, ' ')),
                                         XMLELEMENT("transp__SFT_Zip_Code__c",
                                                    NVL(:NEW.CEP, ' ')),
                                         XMLELEMENT("transp__SFT_Issuer_Type__c",
                                                    'Fornecedor'),
                                         XMLELEMENT("transp__SFT_Active__c",
                                                    CAST(NVL(NVL(CAST(:NEW.DTEXCLUSAO AS
                                                                      VARCHAR2(10)),
                                                                 '1'),
                                                             '0') AS
                                                         VARCHAR(1))),
                                         XMLELEMENT("transp__SFT_Country__c",
                                                    NVL(pais_new, ' '))
                                         
                                         ))
      INTO xmlvalor
      FROM dual;
    SELECT 'IncluirFornecedorMyFrota' INTO operacao FROM dual;
  
  END IF;
  IF (OPERACAO IN ('IncluirFornecedorMyFrota', 'AlterarFornecedorMyFrota',
      'ExcluirFornecedorMyFrota')) THEN
    INSERT INTO PCMYFROTA_FILA
      (CHAVE, OPERACAO, DADOS)
    VALUES
      (CHAVETRANSACAO, operacao, xmlvalor);
  END IF;
END;
