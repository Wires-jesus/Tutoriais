CREATE OR REPLACE TRIGGER TRG_INTEGRA_MYFROTA_PCPRODUT
  AFTER UPDATE OR INSERT ON pcprodut
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW
DECLARE
  xmlvalor       clob;
  operacao       varchar2(50);
  CHAVETRANSACAO raw(16);
BEGIN
  SELECT SYS_GUID INTO CHAVETRANSACAO FROM DUAL;

  IF (:NEW.REVENDA = 'N') THEN
  
    IF (UPDATING) THEN
      IF (:NEW.dtexclusao is not null and :OLD.dtexclusao is null) THEN
        SELECT xmltype.getclobval(XMLELEMENT("item",
                                             XMLATTRIBUTES(:NEW.IDINTEGRACAOMYFROTA AS
                                                           "SFT_External_Id"),
                                             XMLELEMENT("transp__SFT_Active__c",
                                                        '0')))
          INTO xmlvalor
          FROM dual;
        SELECT 'ExcluirProdutoMyFrota' into OPERACAO from dual;
      END IF;
      IF NOT (NVL(:NEW.DESCRICAO, 0) = NVL(:OLD.DESCRICAO, 0) AND
          NVL(:NEW.CODPROD, 0) = NVL(:OLD.CODPROD, 0) AND
          NVL(:NEW.UNIDADE, 0) = NVL(:OLD.UNIDADE, 0)
          
          ) THEN
        SELECT xmltype.getclobval(XMLELEMENT("item",
                                             XMLATTRIBUTES(:NEW.IDINTEGRACAOMYFROTA AS
                                                           "SFT_External_Id"),
                                             XMLELEMENT("Name",
                                                        :NEW.DESCRICAO),
                                             XMLELEMENT("transp__SFT_Transaction_Number__c",
                                                        CHAVETRANSACAO),
                                             XMLELEMENT("transp__SFT_NickName__c",
                                                        :NEW.DESCRICAO),
                                             XMLELEMENT("transp__SFT_Reference__c",
                                                        :NEW.CODPROD),
                                             XMLELEMENT("transp__SFT_Type__c",
                                                        'A Definir'),
                                             XMLELEMENT("transp__SFT_Unit_of_Measure__c",
                                                        'A Definir'),
                                             XMLELEMENT("transp__SFT_Sub_System__c",
                                                        'A Definir'),
                                             XMLELEMENT("transp__SFT_Active__c",
                                                        CAST(NVL(NVL(CAST(:NEW.DTEXCLUSAO AS
                                                                          VARCHAR2(10)),
                                                                     '1'),
                                                                 '0') AS
                                                             VARCHAR(1)))
                                             
                                             ))
          INTO xmlvalor
          FROM dual;
      
        SELECT 'AlterarProdutoMyFrota' INTO operacao FROM dual;
      END IF;
    END IF;
    
    IF (INSERTING) THEN
      SELECT xmltype.getclobval(XMLELEMENT("items",
                                           XMLELEMENT("item",
                                                      XMLATTRIBUTES(:NEW.IDINTEGRACAOMYFROTA AS
                                                                    "SFT_External_Id"),
                                                      XMLELEMENT("Name",
                                                                 NVL(:NEW.DESCRICAO,
                                                                     ' ')),
                                                      XMLELEMENT("transp__SFT_Transaction_Number__c",
                                                                 CHAVETRANSACAO),
                                                      XMLELEMENT("transp__SFT_NickName__c",
                                                                 NVL(:NEW.DESCRICAO,
                                                                     ' ')),
                                                      XMLELEMENT("transp__SFT_Reference__c",
                                                                 NVL(CAST(:NEW.CODPROD AS
                                                                          VARCHAR2(50)),
                                                                     ' ')),
                                                      XMLELEMENT("transp__SFT_Type__c",
                                                                 'A Definir'),
                                                      XMLELEMENT("transp__SFT_Unit_of_Measure__c",
                                                                 'A Definir'),
                                                      XMLELEMENT("transp__SFT_Sub_System__c",
                                                                 'A Definir'),
                                                      XMLELEMENT("transp__SFT_Active__c",
                                                                 CAST(NVL(NVL(CAST(:NEW.DTEXCLUSAO AS
                                                                                   VARCHAR2(10)),
                                                                              '1'),
                                                                          '0') AS
                                                                      VARCHAR(1)))
                                                      
                                                      )))
        INTO xmlvalor
        FROM dual;
    
      SELECT 'IncluirProdutoMyFrota' INTO operacao FROM dual;
    
    END IF;
    IF (OPERACAO IN ('IncluirProdutoMyFrota', 'AlterarProdutoMyFrota',
        'ExcluirProdutoMyFrota')) THEN
      INSERT INTO PCMYFROTA_FILA
        (CHAVE, OPERACAO, DADOS)
      VALUES
        (CHAVETRANSACAO, operacao, xmlvalor);
    END IF;
  END IF;
END;