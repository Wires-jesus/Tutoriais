CREATE OR REPLACE TRIGGER TRG_PCEMPR_DTULTALTER
   BEFORE INSERT OR UPDATE ON PCEMPR  REFERENCING OLD AS OLD NEW AS NEW FOR EACH ROW
DECLARE                                                                                                                                                              
   VSEQUIPAMENTO VARCHAR2(64);                                                                                                                                 
   VSUSUARIO     VARCHAR2(30);                                                                                                                                 
   VSPROGRAMA    VARCHAR2(48);                                                                                                                                 
   VSTIPO        VARCHAR2(20);                                                                                                                                 
   VVUSURWIN     VARCHAR2(20);
   CLIENTEid     VARCHAR2(64);
   VSCODROTINA   NUMBER(6);
                                                                                                                                                              
PROCEDURE GERARLOG(pNOMECOLUNA VARCHAR2, pOLDValue VARCHAR2, pNEWValue VARCHAR2, VVUSURWIN VARCHAR2) 
IS

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
        VALORALFA, 
        CODFUNC,
        MAQUINA,
        CODIGO,
        CODROTINA                                                                                                                                            
      )                                                                                                                                                       
      VALUES(                                                                                                                                                 
        SYSDATE,                                                                                                                                              
        'PCEMPR',                                                                                                                                          
        pNOMECOLUNA,                                                                                                                                          
        'Antigo: ' || :OLD.CODFILIAL || ',' || 'Novo: ' || :NEW.CODFILIAL,                                                                               
        VSPROGRAMA,                                                                                                                                           
        VSEQUIPAMENTO,                                                                                                                                        
        VSUSUARIO,                                                                                                                                            
        pOLDValue,                                                                                                                                            
        pNEWValue,
        VVUSURWIN,
        VSEQUIPAMENTO,
        :NEW.MATRICULA,
        VSCODROTINA                                                                                                                                            
      );                                                                                                                                                      
   END IF;
END; 

BEGIN
   IF NVL(:OLD.DTULTALTERSOFITVIEW,TO_DATE('01/01/1900','DD/MM/YYYY HH24:MI:SS')) = NVL(:NEW.DTULTALTERSOFITVIEW,TO_DATE('01/01/1900','DD/MM/YYYY HH24:MI:SS')) AND 
      NVL(:OLD.DTEXCLUSAOSOFITVIEW,TO_DATE('01/01/1900','DD/MM/YYYY HH24:MI:SS')) = NVL(:NEW.DTEXCLUSAOSOFITVIEW,TO_DATE('01/01/1900','DD/MM/YYYY HH24:MI:SS')) AND
      NVL(:OLD.IDSOFITVIEW,0) = NVL(:NEW.IDSOFITVIEW,0) THEN
      :NEW.DTULTALTER := SYSDATE;
   END IF;

   IF (INSERTING OR UPDATING) AND (NVL(:OLD.CODFILIAL,0) <> NVL(:NEW.CODFILIAL,0)) THEN
      BEGIN
         VSEQUIPAMENTO := SUBSTR(SYS_CONTEXT('USERENV', 'TERMINAL'), 1, 64);
         VSUSUARIO     := SUBSTR(SYS_CONTEXT('USERENV', 'OS_USER'), 1, 30);
         VSPROGRAMA    := SUBSTR(SYS_CONTEXT('USERENV', 'MODULE'), 1, 48);
         CLIENTEID     := SYS_CONTEXT('USERENV','CLIENT_INFO');

         SELECT NVL((SUBSTR(CLIENTEID
              , NVL(INSTR(CLIENTEID, ':'),0) + 1
              , LENGTH(CLIENTEid))),'')
         INTO vVUSURWIN
         FROM DUAL;
      EXCEPTION WHEN OTHERS THEN
         VVUSURWIN := '0';
      END;

      BEGIN
         VSCODROTINA := NVL(TO_NUMBER(TRIM(SUBSTR(VSPROGRAMA, (INSTR(VSPROGRAMA, 'PCSIS', 1)) + 5,4))),0);
      EXCEPTION WHEN OTHERS THEN
         VSCODROTINA := 0;
      END;
   END IF;
END;
