CREATE OR REPLACE TRIGGER TRG_LOG_PCPREST                                                                                                                     
  BEFORE INSERT OR UPDATE ON PCPREST
  REFERENCING OLD AS OLD NEW AS NEW                                                                                                                           
  FOR EACH ROW                                                                                                                                                
DECLARE                                                                                                                                                       
  /*******************************************************************************                                                                             
                           Historico de Alteracoes                                                                                                            
  --------------------------------------------------------------------------------                                                                            
    Data        Responsavel    Tarefa    Alteracao                                                                                                            
   -----------  -------------  --------  -----------------------------------------                                                                            
    22/08/2011  Marcos Garcia        140041     Gravação do campo rotinalanc                                                                                  
    21/10/2015  PAULO GONÇALVES           0     GRAVANDO PROGRAMA QUE DESDOBROU, PAGOU E FECHOU                                                               
    30/08/2016  FABRÍCIO LIMA    HIS.02223.2016  Gravação dos campos nosso número 1 e 2                                                                       
    11/05/2017  RONDINELLI     1964.049793.2017 Gravação de histórico de Inclusão e Exclusão do Serasa                                                        
    03/03/2018  FRANK          FIN-2449         Gravar alteração no Motorista                                                                                 
    19/04/2018  RONDINELLI     FIN-2460         Gravação log dos campos CODBANCO e CODBANCOCM                                                                 
                                                                                                                                                              
  *******************************************************************************/                                                                            
                                                                                                                                                              
  VSEQUIPAMENTO VARCHAR2(64);                                                                                                                                 
  VSUSUARIO     VARCHAR2(30);                                                                                                                                 
  VSPROGRAMA    VARCHAR2(48);                                                                                                                                 
  VSTIPO        VARCHAR2(20);                                                                                                                                 
  VVUSURWIN     VARCHAR2(20);
  CLIENTEid     VARCHAR2(64);
                                                                                                                                                              
  PROCEDURE GERARLOG(pNOMECOLUNA VARCHAR2, pOLDValue VARCHAR2, pNEWValue VARCHAR2) IS                                                                         
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
      )                                                                                                                                                       
      VALUES(                                                                                                                                                 
        SYSDATE,                                                                                                                                              
        'PCPREST',                                                                                                                                          
        pNOMECOLUNA,                                                                                                                                          
        'NUMTRANSVENDA-PREST: ' || :NEW.NUMTRANSVENDA || '-' || :NEW.PREST,                                                                               
        VSPROGRAMA,                                                                                                                                           
        VSEQUIPAMENTO,                                                                                                                                        
        VSUSUARIO,                                                                                                                                            
        pOLDValue,                                                                                                                                            
        pNEWValue                                                                                                                                             
      );                                                                                                                                                      
                                                                                                                                                              
    END IF;                                                                                                                                                   
  END;                                                                                                                                                        
BEGIN                                                                                                                                                         
                                                                                                                                                              
  VSEQUIPAMENTO := SUBSTR(SYS_CONTEXT('USERENV', 'TERMINAL'), 1, 64);                                                                                     
  VSUSUARIO     := SUBSTR(SYS_CONTEXT('USERENV', 'OS_USER'), 1, 30);                                                                                      
  VSPROGRAMA    := SUBSTR(SYS_CONTEXT('USERENV', 'MODULE'), 1, 48);                                                                                       
                                                                                                                                                              
  :NEW.ROTINALANCULTALT := VSPROGRAMA;                                                                                                                        
  :NEW.DTULTALTER       := TRUNC(SYSDATE);                                                                                                                    
                                                                                                                                                              
  IF (:NEW.CODFUNCULTALTER IS NULL) OR (:OLD.CODFUNCULTALTER = :NEW.CODFUNCULTALTER) THEN                                                                     
    BEGIN                                                                                                                                                     
      CLIENTEid := SYS_CONTEXT('USERENV','CLIENT_INFO');
      SELECT NVL((SUBSTR(CLIENTEid
         , NVL(INSTR(CLIENTEid, ':'),0) + 1
         , LENGTH(CLIENTEid))),'')
      into vVUSURWIN FROM dual;

    EXCEPTION
      WHEN OTHERS THEN                                                                                                                                        
        VVUSURWIN := '0';                                                                                                                                   
    END;                                                                                                                                                      
                                                                                                                                                              
    IF VVUSURWIN = 'INTEGRADORA' THEN                                                                                                                       
      :NEW.CODFUNCULTALTER := 8888;                                                                                                                           
    ELSE                                                                                                                                                      
      BEGIN                                                                                                                                                   
        :NEW.CODFUNCULTALTER := NVL(VVUSURWIN,'0');                                                                                                         
      EXCEPTION                                                                                                                                               
        WHEN OTHERS THEN                                                                                                                                      
          :NEW.CODFUNCULTALTER := 0;                                                                                                                          
      END;                                                                                                                                                    
    END IF;                                                                                                                                                   
  END IF;                                                                                                                                                     
                                                                                                                                                              
  IF UPDATING THEN                                                                                                                                            
    IF ((:OLD.DTPAG IS NULL) AND (:NEW.DTPAG IS NOT NULL) AND (:OLD.ROTINAPAG IS NULL)) THEN                                                                  
      :NEW.ROTINAPAG := VSPROGRAMA;                                                                                                                           
    END IF;                                                                                                                                                   
                                                                                                                                                              
    IF ((:OLD.DTFECHA IS NULL) AND (:NEW.DTFECHA IS NOT NULL) AND (:OLD.ROTINAFECHA IS NULL)) THEN                                                            
      :NEW.ROTINAFECHA := VSPROGRAMA;                                                                                                                         
    END IF;                                                                                                                                                   
                                                                                                                                                              
    IF ((:NEW.CODCOB = 'DESD') AND (:OLD.ROTINADESD IS NULL)) THEN                                                                                          
      :NEW.ROTINADESD := VSPROGRAMA;                                                                                                                          
    END IF;                                                                                                                                                   
                                                                                                                                                              
    -------HIS.02223.2016 Início-------------                                                                                                                 
    IF (NVL(:NEW.NOSSONUMBCO, '0') <> NVL(:OLD.NOSSONUMBCO, '0')) OR (NVL(:NEW.NOSSONUMBCO2, '0') <> NVL(:OLD.NOSSONUMBCO2, '0')) THEN                
      VSTIPO := 'ATUALIZACAO';                                                                                                                              
      IF (:OLD.NOSSONUMBCO IS NULL) OR (:OLD.NOSSONUMBCO2 IS NULL) THEN                                                                                       
        IF (:NEW.NOSSONUMBCO IS NOT NULL) OR (:NEW.NOSSONUMBCO2 IS NOT NULL) THEN                                                                             
          VSTIPO := 'GERACAO';                                                                                                                              
        END IF ;                                                                                                                                              
      END IF;                                                                                                                                                 
                                                                                                                                                              
      INSERT INTO PCHISTNOSSONUMEROBCO(                                                                                                                       
         DATA                                                                                                                                                 
        ,USUARIO                                                                                                                                              
        ,MAQUINA                                                                                                                                              
        ,ROTINA                                                                                                                                               
        ,NUMTRANSVENDA                                                                                                                                        
        ,PREST                                                                                                                                                
        ,CODCLI                                                                                                                                               
        ,TIPO                                                                                                                                                 
        ,NOSSONUMEROANTIGO                                                                                                                                    
        ,NOSSONUMERONOVO                                                                                                                                      
        ,NOSSONUMERO2ANTIGO                                                                                                                                   
        ,NOSSONUMERO2NOVO                                                                                                                                     
      ) VALUES(                                                                                                                                               
         SYSDATE                                                                                                                                              
        ,VSUSUARIO                                                                                                                                            
        ,VSEQUIPAMENTO                                                                                                                                        
        ,VSPROGRAMA                                                                                                                                           
        ,:NEW.NUMTRANSVENDA                                                                                                                                   
        ,:NEW.PREST                                                                                                                                           
        ,:NEW.CODCLI                                                                                                                                          
        ,VSTIPO                                                                                                                                               
        ,:OLD.NOSSONUMBCO                                                                                                                                     
        ,:NEW.NOSSONUMBCO                                                                                                                                     
        ,:OLD.NOSSONUMBCO2                                                                                                                                    
        ,:NEW.NOSSONUMBCO2                                                                                                                                    
      );                                                                                                                                                      
    END IF;                                                                                                                                                   
    -------HIS.02223.2016 Fim-------------                                                                                                                    
                                                                                                                                                              
    -------1964.049793.2017 Início-------------                                                                                                                
    IF (:OLD.DTENVIOSERASA is not null) or (:NEW.DTENVIOSERASA is not null) or (:OLD.DTRETIRADASERASA is not null) or (:NEW.DTRETIRADASERASA is not null) THEN 
                                                                                                                                                              
      VSTIPO := 'ATUALIZACAO';                                                                                                                               
      IF (:OLD.DTENVIOSERASA IS NULL) AND (:NEW.DTENVIOSERASA is not null) THEN                                                                                
        VSTIPO := 'INCLUSAO';                                                                                                                                
      ELSIF (:OLD.DTENVIOSERASA IS NOT NULL) AND (:NEW.DTENVIOSERASA is null) THEN                                                                             
        VSTIPO := 'CANC-INCLUSAO';                                                                                                                           
      ELSIF (:OLD.DTRETIRADASERASA IS NULL) AND (:NEW.DTRETIRADASERASA is not null) THEN                                                                       
        VSTIPO := 'EXCLUSAO';                                                                                                                                
      ELSIF (:OLD.DTRETIRADASERASA IS NOT NULL) AND (:NEW.DTRETIRADASERASA is null) THEN                                                                       
        VSTIPO := 'CANC-EXCLUSAO';                                                                                                                           
      END IF;                                                                                                                                                  
                                                                                                                                                              
      INSERT INTO PCHISTSERASA(                                                                                                                                
        DATA                                                                                                                                                   
        ,USUARIO                                                                                                                                               
        ,MAQUINA                                                                                                                                               
        ,ROTINA                                                                                                                                                
        ,NUMTRANSVENDA                                                                                                                                         
        ,PREST                                                                                                                                                 
        ,CODCLI                                                                                                                                                
        ,TIPO                                                                                                                                                  
        ,DTENVIOSERASAANT                                                                                                                                      
        ,DTENVIOSERASA                                                                                                                                         
        ,DTRETIRADASERASAANT                                                                                                                                   
        ,DTRETIRADASERASA                                                                                                                                      
      ) VALUES(                                                                                                                                                
        SYSDATE                                                                                                                                                
        ,VSUSUARIO                                                                                                                                             
        ,VSEQUIPAMENTO                                                                                                                                         
        ,VSPROGRAMA                                                                                                                                            
        ,:NEW.NUMTRANSVENDA                                                                                                                                    
        ,:NEW.PREST                                                                                                                                            
        ,:NEW.CODCLI                                                                                                                                           
        ,VSTIPO                                                                                                                                                
        ,:OLD.DTENVIOSERASA                                                                                                                                    
        ,:NEW.DTENVIOSERASA                                                                                                                                    
        ,:OLD.DTRETIRADASERASA                                                                                                                                 
        ,:NEW.DTRETIRADASERASA                                                                                                                                 
      );                                                                                                                                                       
                                                                                                                                                              
    END IF;                                                                                                                                                    
    -------1964.049793.2017 Fim-------------                                                                                                                   
  END IF; -- IF UPDATING THEN                                                                                                                                 
                                                                                                                                                              
  IF INSERTING THEN                                                                                                                                           
	IF 	(:NEW.DTPAG IS NOT NULL) 	AND 	(:NEW.ROTINAPAG IS NULL) 	THEN                                                                                                                          		
			:NEW.ROTINAPAG := VSPROGRAMA;                                                                                                                           		
	END IF;  

    :NEW.DATAINSERT := TRUNC(SYSDATE);	
                                                                                                                                                              
    IF (:NEW.DTFECHA IS NOT NULL) THEN                                                                                                                        
      :NEW.ROTINAFECHA := VSPROGRAMA;                                                                                                                         
    END IF;                                                                                                                                                   
                                                                                                                                                              
    IF (:NEW.CODCOB = 'DESD') THEN                                                                                                                          
      :NEW.ROTINADESD := VSPROGRAMA;                                                                                                                          
    END IF;                                                                                                                                                   
                                                                                                                                                              
    :NEW.ROTINAINSERT := VSPROGRAMA;                                                                                                                          
  --  :NEW.ROTINALANC := TO_NUMBER(NVL(regexp_replace(SUBSTR(VSPROGRAMA, 1, 12), '[^[: digit: ]] ', ''), ' 0 '));                                       
    :NEW.EQUIPLANC        := VSEQUIPAMENTO;                                                                                                                   
    :NEW.FUNCLANC         := VSUSUARIO;                                                                                                                       
  END IF;                                                                                                                                                     
  IF UPDATING THEN
  GERARLOG('DTPAG', TO_CHAR(:OLD.DTPAG, 'DD-MM-YYYY'), TO_CHAR(:NEW.DTPAG, 'DD-MM-YYYY'));                                                              
  GERARLOG('DTPAGCOMISSAO', TO_CHAR(:OLD.DTPAGCOMISSAO, 'DD-MM-YYYY'), TO_CHAR(:NEW.DTPAGCOMISSAO, 'DD-MM-YYYY'));                                      
  GERARLOG('DTFECHA', TO_CHAR(:OLD.DTFECHA, 'DD-MM-YYYY'), TO_CHAR(:NEW.DTFECHA, 'DD-MM-YYYY'));                                                        
  GERARLOG('DTBAIXA', TO_CHAR(:OLD.DTBAIXA, 'DD-MM-YYYY'), TO_CHAR(:NEW.DTBAIXA, 'DD-MM-YYYY'));                                                        
  GERARLOG('DTVENC', TO_CHAR(:OLD.DTVENC, 'DD-MM-YYYY'), TO_CHAR(:NEW.DTVENC, 'DD-MM-YYYY'));                                                           
                                                                                                                                                              
  GERARLOG('CODFUNCCHECKOUT', TO_CHAR(:OLD.CODFUNCCHECKOUT), TO_CHAR(:NEW.CODFUNCCHECKOUT));                                                                
  GERARLOG('DUPLIC', TO_CHAR(:OLD.DUPLIC), TO_CHAR(:NEW.DUPLIC));                                                                                           
  GERARLOG('CODMOTORISTA', TO_CHAR(:OLD.CODMOTORISTA), TO_CHAR(:NEW.CODMOTORISTA));                                                                         
  GERARLOG('CODBANCO', TO_CHAR(:OLD.CODBANCO), TO_CHAR(:NEW.CODBANCO));                                                                                     
  GERARLOG('CODBANCOCM', TO_CHAR(:OLD.CODBANCOCM), TO_CHAR(:NEW.CODBANCOCM));                                                                               
  GERARLOG('VALOR', TO_CHAR(:OLD.VALOR), TO_CHAR(:NEW.VALOR));                                                                                              
  GERARLOG('VPAGO', TO_CHAR(:OLD.VPAGO), TO_CHAR(:NEW.VPAGO));                                                                                              
  GERARLOG('CODCOB', TO_CHAR(:OLD.CODCOB), TO_CHAR(:NEW.CODCOB));                                                                                           
  GERARLOG('NUMCAR', TO_CHAR(:OLD.NUMCAR), TO_CHAR(:NEW.NUMCAR));                                                                                           
  GERARLOG('NUMTRANS', TO_CHAR(:OLD.NUMTRANS), TO_CHAR(:NEW.NUMTRANS));                                                                                     
  GERARLOG('NUMTRANSVENDOR', TO_CHAR(:OLD.NUMTRANSVENDOR), TO_CHAR(:NEW.NUMTRANSVENDOR));                                                                   
  GERARLOG('VLTXBOLETO', TO_CHAR(:OLD.VLTXBOLETO), TO_CHAR(:NEW.VLTXBOLETO));                                                                               
  GERARLOG('DTCUSTODIA', TO_CHAR(:OLD.DTCUSTODIA), TO_CHAR(:NEW.DTCUSTODIA));                                                                               
  GERARLOG('NUMCUSTODIA', TO_CHAR(:OLD.NUMCUSTODIA), TO_CHAR(:NEW.NUMCUSTODIA));                                                                            
  GERARLOG('CODFILIALNF', TO_CHAR(:OLD.CODFILIALNF), TO_CHAR(:NEW.CODFILIALNF));                                                                            
  GERARLOG('VALORDESC', TO_CHAR(:OLD.VALORDESC), TO_CHAR(:NEW.VALORDESC));
  -- Cartao de credito
  GERARLOG('NSUTEF'       , TO_CHAR(:OLD.NSUTEF)        , TO_CHAR(:NEW.NSUTEF));
  GERARLOG('NSUHOST'      , TO_CHAR(:OLD.NSUHOST)       , TO_CHAR(:NEW.NSUHOST));
  GERARLOG('PRESTTEF'     , TO_CHAR(:OLD.PRESTTEF)      , TO_CHAR(:NEW.PRESTTEF));
  GERARLOG('QTPARCELASPOS', TO_CHAR(:OLD.QTPARCELASPOS) , TO_CHAR(:NEW.QTPARCELASPOS));
  -- Boletos gerados
  GERARLOG('NUMREMESSA', TO_CHAR(:OLD.NUMREMESSA) , TO_CHAR(:NEW.NUMREMESSA));
  GERARLOG('NOMEARQUIVO', TO_CHAR(:OLD.NOMEARQUIVO) , TO_CHAR(:NEW.NOMEARQUIVO));
  END IF;
END;