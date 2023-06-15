CREATE OR REPLACE TRIGGER TRG_PCSOLICITACAOMATERIAL                                                                                                 

  BEFORE INSERT OR UPDATE ON PCSOLICITACAOMATERIAL
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
        'PCSOLICITACAOMATERIAL',                                                                                                                 
        pNOMECOLUNA,                                                                                                                
        'NUMEROSOLICITACAO=' || :NEW.NUMEROSOLICITACAO,                                                                                                 
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
                                                                                                                                                                                                                                                                       
  GERARLOG('DATAREJEICAO', TO_CHAR(:OLD.DATAREJEICAO, 'DD-MM-YYYY'), TO_CHAR(:NEW.DATAREJEICAO, 'DD-MM-YYYY'));
  GERARLOG('DATAAPROVACAO', TO_CHAR(:OLD.DATAAPROVACAO, 'DD-MM-YYYY'), TO_CHAR(:NEW.DATAAPROVACAO, 'DD-MM-YYYY'));
  GERARLOG('STATUS', :OLD.STATUS, :NEW.STATUS);

END;
