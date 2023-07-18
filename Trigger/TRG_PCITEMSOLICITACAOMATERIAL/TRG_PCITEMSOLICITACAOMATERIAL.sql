CREATE OR REPLACE TRIGGER TRG_PCITEMSOLICITACAOMATERIAL

  BEFORE INSERT OR UPDATE ON PCITEMSOLICITACAOMATERIAL
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW

DECLARE                 

  VSEQUIPAMENTO    VARCHAR2(64);                                                                                                     
  VSPROGRAMAVERSAO VARCHAR2(100);                                                                                                                                                                                                            
  VSUSUARIO        VARCHAR2(30);                                                                                                     

  PROCEDURE GERARLOG(
    pNOMECOLUNA VARCHAR2,
    pOLDValue   VARCHAR2,
    pNEWValue   VARCHAR2
  ) IS                                                                                        
  BEGIN

    IF NVL(pOLDValue, 'X') <> NVL(pNEWValue, 'X') THEN

      INSERT INTO PCLOGALTERACAODADOS(
        DATA,
        TABELA,
        COLUNA,
        OBSERVACOES,
        PROGRAMA,
        TERMINAL,
        OSUSER,
        VALORALFAANT,
        VALORALFA
      ) VALUES (
        SYSDATE,
        'PCITEMSOLICITACAOMATERIAL',
        pNOMECOLUNA,
        'NUMEROSOLICITACAO=' || :NEW.NUMEROSOLICITACAO || ' CODPRODUTO=' || :NEW.CODPRODUTO,
        VSPROGRAMAVERSAO,
        VSEQUIPAMENTO,
        VSUSUARIO,
        pOLDValue,
        pNEWValue
      );

    END IF;

  END;

BEGIN                                                                                                                                                                                                      
                                                               
  VSPROGRAMAVERSAO := SUBSTR(SYS_CONTEXT('USERENV', 'MODULE'), 1, 40);
  VSEQUIPAMENTO    := SUBSTR(SYS_CONTEXT('USERENV', 'TERMINAL'), 1, 64);
  VSUSUARIO        := SUBSTR(SYS_CONTEXT('USERENV', 'OS_USER'), 1, 30);

  GERARLOG('QUANTIDADE', TO_CHAR(:OLD.QUANTIDADE), TO_CHAR(:NEW.QUANTIDADE));
  GERARLOG('QTDEATENDIDA', TO_CHAR(:OLD.QTDEATENDIDA), TO_CHAR(:NEW.QTDEATENDIDA));
  GERARLOG('QTDEREJEITADA', TO_CHAR(:OLD.QTDEREJEITADA), TO_CHAR(:NEW.QTDEREJEITADA));
  GERARLOG('QTDECOTACAO', TO_CHAR(:OLD.QTDECOTACAO), TO_CHAR(:NEW.QTDECOTACAO));                                                                                                                                                                                                                                                                            
  GERARLOG('DATAACEITE', TO_CHAR(:OLD.DATAACEITE, 'DD-MM-YYYY'), TO_CHAR(:NEW.DATAACEITE, 'DD-MM-YYYY'));
  GERARLOG('DATAATENDIMENTOITEM', TO_CHAR(:OLD.DATAATENDIMENTOITEM, 'DD-MM-YYYY'), TO_CHAR(:NEW.DATAATENDIMENTOITEM, 'DD-MM-YYYY'));
  GERARLOG('STATUSITEM', :OLD.STATUSITEM, :NEW.STATUSITEM);

END;
