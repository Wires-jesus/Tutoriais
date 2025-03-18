DECLARE                                                                                   
    V_COUNT NUMBER; 
    V_ID_SEQ NUMBER;    
    
   -- Cursor dinâmico
    TYPE T_CURSOR IS REF CURSOR;
    C_REGISTROS T_CURSOR;

    -- Variáveis para armazenar os dados do cursor
    V_CODBENEFICIOFISCAL PCBENEFICFISCALCREDPRES.CODBENEFICIOFISCAL%TYPE;
    V_CODST PCBENEFICFISCALCREDPRES.CODST%TYPE;
    V_DTCADASTRO PCBENEFICFISCALCREDPRES.DTCADASTRO%TYPE;
    V_IDROWID ROWID;                                                              
BEGIN  
   -- Verificar e adicionar coluna IDPRES                                                
    SELECT COUNT(*) INTO V_COUNT                                                          
    FROM ALL_TAB_COLUMNS                                                                  
    WHERE TABLE_NAME = 'PCBENEFICFISCALCREDPRESI' AND COLUMN_NAME = 'IDPRES';         
                                                                                          
    IF V_COUNT = 0 THEN                                                                   
        EXECUTE IMMEDIATE 'ALTER TABLE PCBENEFICFISCALCREDPRESI ADD IDPRES NUMBER(10)'; 
    END IF;                                                                               
                                                                                          
    -- Verificar e adicionar coluna IDPRES                                                
    SELECT COUNT(*) INTO V_COUNT                                                          
    FROM ALL_TAB_COLUMNS                                                                  
    WHERE TABLE_NAME = 'PCBENEFICFISCALCREDPRES' AND COLUMN_NAME = 'IDPRES';          
                                                                                          
    IF V_COUNT = 0 THEN                                                                   
        EXECUTE IMMEDIATE 'ALTER TABLE PCBENEFICFISCALCREDPRES ADD IDPRES NUMBER(10)';  
    END IF;                                                                               
                                                                                          
    -- Verificar e adicionar coluna DESCRICAO                                             
    SELECT COUNT(*) INTO V_COUNT                                                          
    FROM ALL_TAB_COLUMNS                                                                  
    WHERE TABLE_NAME = 'PCBENEFICFISCALCREDPRES' AND COLUMN_NAME = 'DESCRICAO';       
                                                                                          
    IF V_COUNT = 0 THEN                                                                   
        EXECUTE IMMEDIATE 'ALTER TABLE PCBENEFICFISCALCREDPRES ADD DESCRICAO VARCHAR2(100)';  
    END IF;                                                                               
                                                                                          
    -- Verificar e criar a sequência                                                      
    SELECT COUNT(*) INTO V_COUNT                                                          
    FROM ALL_SEQUENCES                                                                    
    WHERE SEQUENCE_NAME = 'DEFSEQ_PCBENEFICFISCALCREDPRES';                             
                                                                                          
    IF V_COUNT = 0 THEN                                                                   
        EXECUTE IMMEDIATE 'CREATE SEQUENCE DEFSEQ_PCBENEFICFISCALCREDPRES                
                           MINVALUE 1 MAXVALUE 999999999999999999999999999                
                           START WITH 1 INCREMENT BY 1 NOCACHE';                         
    END IF;    
    
    -- Atualizar os IDs com com sequência nova Chave   
    
    OPEN C_REGISTROS FOR 
        'SELECT CODBENEFICIOFISCAL, CODST, DTCADASTRO, ROWID 
         FROM PCBENEFICFISCALCREDPRES 
         WHERE NVL(IDPRES, 0) = 0 
         ORDER BY DTCADASTRO';

    LOOP
        -- Busca os dados do cursor
        FETCH C_REGISTROS INTO V_CODBENEFICIOFISCAL, V_CODST, V_DTCADASTRO, V_IDROWID;

        -- Sai do loop se não houver mais registros
        EXIT WHEN C_REGISTROS%NOTFOUND;

        -- Gera o próximo valor da sequência
        EXECUTE IMMEDIATE 'BEGIN SELECT DEFSEQ_PCBENEFICFISCALCREDPRES.NEXTVAL INTO :1 FROM dual; END;'
        USING OUT V_ID_SEQ;

        -- Atualiza PCBENEFICFISCALCREDPRES usando EXECUTE IMMEDIATE
        EXECUTE IMMEDIATE 'UPDATE PCBENEFICFISCALCREDPRES 
                           SET IDPRES = :1 
                           WHERE ROWID = :2'
        USING V_ID_SEQ, V_IDROWID;

        -- Atualiza PCBENEFICFISCALCREDPRESI usando EXECUTE IMMEDIATE
        EXECUTE IMMEDIATE 'UPDATE PCBENEFICFISCALCREDPRESI 
                           SET IDPRES = :1 
                           WHERE CODBENEFICIOFISCAL = :2 
                             AND CODST = :3'
        USING V_ID_SEQ, V_CODBENEFICIOFISCAL, V_CODST;
        COMMIT;
    END LOOP;
    
    -- Fecha o cursor
    CLOSE C_REGISTROS;
    
    -- Dropar e recriar as constraints
    DECLARE
        CURSOR C_CONSTRAINTS IS
        SELECT CONSTRAINT_NAME, TABLE_NAME
        FROM USER_CONSTRAINTS
        WHERE CONSTRAINT_NAME IN (  'PCBENEFICFISCALCREDPRESI_FK1',
                                    'PCBENEFICFISCALCREDPRESI_PK',
                                    'PCBENEFICFISCALCREDPRES_PK' );
    BEGIN
        FOR C IN C_CONSTRAINTS LOOP
            EXECUTE IMMEDIATE 'ALTER TABLE ' || C.TABLE_NAME || ' DROP CONSTRAINT ' || C.CONSTRAINT_NAME;
            DBMS_OUTPUT.PUT_LINE('CONSTRAINT ' || C.CONSTRAINT_NAME || ' REMOVIDA.');
        END LOOP;
    END;   
    
   
   -- Criar novas PKs   
   SELECT COUNT(*) INTO V_COUNT                                                                                                               
   FROM USER_CONSTRAINTS                                                                                                                      
   WHERE CONSTRAINT_NAME = 'PCBENEFICFISCALCREDPRES1_PK';                                                                                   
                                                                                                                                                  
   IF V_COUNT = 0 THEN                                                                                                                        
       EXECUTE IMMEDIATE 'ALTER TABLE PCBENEFICFISCALCREDPRES ADD CONSTRAINT PCBENEFICFISCALCREDPRES1_PK PRIMARY KEY (IDPRES)';           
   END IF;                                                                                                                                    
                                                                                                                                                  
   SELECT COUNT(*) INTO V_COUNT                                                                                                               
   FROM USER_CONSTRAINTS                                                                                                                      
   WHERE CONSTRAINT_NAME = 'PCBENEFICFISCALCREDPRESI1_PK';                                                                                  
                                                                                                                                                  
   IF V_COUNT = 0 THEN                                                                                                                        
       EXECUTE IMMEDIATE 'ALTER TABLE PCBENEFICFISCALCREDPRESI ADD CONSTRAINT PCBENEFICFISCALCREDPRESI1_PK PRIMARY KEY (IDPRES, ALIQICMSNF)';                                                              
   END IF;  
   
EXCEPTION
    WHEN OTHERS THEN           
     ROLLBACK;                                                                          
END;                                                                                                         