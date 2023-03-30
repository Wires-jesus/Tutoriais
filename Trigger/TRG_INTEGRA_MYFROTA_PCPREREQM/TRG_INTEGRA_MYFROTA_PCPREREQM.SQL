CREATE OR REPLACE TRIGGER TRG_INTEGRA_MYFROTA_PCPREREQM
  AFTER UPDATE ON PCPREREQMATCONSUMOI
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW
DECLARE
  xmlvalor        clob;
  origem          varchar2(10);
  QUANTIDADEBAIXA NUMBER(20, 6);
  SITUACAO        varchar2(30);
  CODPROD         NUMBER(6);
  IDMYFROTA       RAW(16);
  CHAVETRANSACAO  raw(16);
BEGIN
  SELECT SYS_GUID INTO CHAVETRANSACAO FROM DUAL;
  Select R.PRERECORIGEM
    INTO origem
    From PCPREREQMATCONSUMOC R
   WHERE R.Numprerequisicao = :NEW.Numprerequisicao;
  IF (origem = 'myfrota') THEN
    IF (:OLD.NUMTRANSVENDA is null and :NEW.NUMTRANSVENDA is not null) THEN
      Select V.QT
        INTO QUANTIDADEBAIXA
        FROM PCMOV V
       WHERE V.CODPROD = :NEW.CODPROD
         AND V.NUMTRANSVENDA = :NEW.NUMTRANSVENDA;
      Select CASE C.SITUACAO
               WHEN 'C' THEN
                'Cancelado'
               WHEN 'A' THEN
                'Atendido total'
               WHEN 'P' THEN
                'Atendido parcial'
               WHEN 'L' THEN
                'Pendente'
             END
        INTO SITUACAO
        FROM PCPREREQMATCONSUMOC C
       WHERE C.NUMPREREQUISICAO = :NEW.NUMPREREQUISICAO;
      Select C.IDINTEGRACAOMYFROTA
        INTO IDMYFROTA
        FROM PCPREREQMATCONSUMOC C
       WHERE C.NUMPREREQUISICAO = :NEW.NUMPREREQUISICAO;
      SELECT xmltype.getclobval(XMLELEMENT("requisitions",
                                           XMLELEMENT("requisition",
                                                      XMLATTRIBUTES(IDMYFROTA AS
                                                                    "SFT_External_Id"),
                                                      XMLELEMENT("transp__SFT_Transaction_Number__c",
                                                                 CHAVETRANSACAO),
                                                      XMLELEMENT("transp__SFT_Attend_Quantity__c",
                                                                 QUANTIDADEBAIXA),
                                                      XMLELEMENT("transp__SFT_Status__c",
                                                                 SITUACAO),
                                                      XMLELEMENT("transp__SFT_Item__c",
                                                                 :NEW.CODPROD))))
        INTO xmlvalor
        FROM DUAL;
    END IF;
    IF (xmlvalor is not null) THEN
      INSERT INTO PCMYFROTA_FILA
        (CHAVE, operacao, DADOS)
      VALUES
        (CHAVETRANSACAO, 'BaixaRequisicaoMyFrota', xmlvalor);
    END IF;
  END IF;
END;
