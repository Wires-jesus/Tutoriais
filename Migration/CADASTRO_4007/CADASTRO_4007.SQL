DECLARE                                                                                   
    V_COUNT NUMBER; 
BEGIN  
    ---------------------------------------- // -------------------------------
    -- Verificar e criar a sequência                                                      
    SELECT COUNT(*) INTO V_COUNT                                                          
    FROM ALL_SEQUENCES                                                                    
    WHERE SEQUENCE_NAME = 'DFSEQ_PCSYSTAXCONTROLE';                             
                                                                                          
    IF V_COUNT = 0 THEN                                                                   
        EXECUTE IMMEDIATE 'CREATE SEQUENCE DFSEQ_PCSYSTAXCONTROLE                
                           MINVALUE 1 MAXVALUE 999999999999999999999999999                
                           START WITH 1 INCREMENT BY 1 NOCACHE';                         
    END IF;  
    ---------------------------------------- // -------------------------------    
    -- Verificando e dropando a chave primária da PCSYSTAXCENARIOTRIB
    V_COUNT := 0; 
    SELECT COUNT(*) INTO V_COUNT 
      FROM USER_CONSTRAINTS C
     WHERE C.table_name = 'PCSYSTAXCENARIOTRIB'
       AND C.constraint_name = 'PCSYSTAXCENARIOTRIB_PK';
       
    IF V_COUNT = 0 THEN                                                                   
       EXECUTE IMMEDIATE 
         'ALTER TABLE PCSYSTAXCENARIOTRIB DROP CONSTRAINT PCSYSTAXCENARIOTRIB_PK';                         
         COMMIT; 
    END IF;       

EXCEPTION
    WHEN OTHERS THEN           
     ROLLBACK;                                                                          
END;
