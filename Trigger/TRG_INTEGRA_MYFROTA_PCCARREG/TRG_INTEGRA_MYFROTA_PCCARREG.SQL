CREATE OR REPLACE TRIGGER TRG_INTEGRA_MYFROTA_PCCARREG AFTER UPDATE ON PCCARREG REFERENCING NEW AS NEW OLD AS OLD FOR EACH ROW
DECLARE
  XML clob;
  OPERACAO varchar2(50);
  CHAVE_TRANSACAO raw(16);
  idintegracaomyfrota_viagem raw(16);
BEGIN
  SELECT SYS_GUID INTO CHAVE_TRANSACAO FROM DUAL;
  SELECT SYS_GUID INTO idintegracaomyfrota_viagem FROM DUAL;

  /* Esta regra é referente aos registros da 1441.
  Quando o registro da pccarreg tiver o campo conhecgerado alterado para 'S',
  irá gerar uma viagem no my frota.*/

  IF (NVL(:NEW.CONHECGERADO, 'N') = 'S') AND (NVL(:OLD.CONHECGERADO, 'N') = 'N') THEN

    INSERT INTO pcmyfrota_viagem
      (idintegracaomyfrota)
    values
      (idintegracaomyfrota_viagem);

    SELECT (xmltype.getclobval(XMLELEMENT("dados",
      XMLELEMENT("chaveregistro", :NEW.NUMCAR),
      XMLELEMENT("chaveTransacao", CHAVE_TRANSACAO),
      XMLELEMENT("novaviagem", idintegracaomyfrota_viagem),
      XMLELEMENT("gerarviagem", 'N')))
    )
    INTO XML
    from dual;

    SELECT 'IncluirViagemMyFrota' INTO OPERACAO FROM dual;
  
    INSERT INTO PCMYFROTA_FILA
      (CHAVE, OPERACAO, DADOS)
    VALUES
      (CHAVE_TRANSACAO, OPERACAO, XML);
  END IF;
END;
