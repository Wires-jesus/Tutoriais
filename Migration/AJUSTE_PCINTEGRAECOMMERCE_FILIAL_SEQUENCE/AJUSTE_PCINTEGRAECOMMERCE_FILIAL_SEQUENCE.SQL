DECLARE                                                                                   
    V_COUNT NUMBER; 
BEGIN  
    ---------------------------------------- // -------------------------------
    -- Verificar e criar a sequência                                                      
    SELECT COUNT(*) INTO V_COUNT                                                          
    FROM ALL_SEQUENCES                                                                    
    WHERE SEQUENCE_NAME = 'DFSEQ_PCINTEGRAECOMMERCE_FILIA';                             
                                                                                          
    IF V_COUNT = 0 THEN                                                                   
        EXECUTE IMMEDIATE 'CREATE SEQUENCE DFSEQ_PCINTEGRAECOMMERCE_FILIA                
                           MINVALUE 1 MAXVALUE 999999999999999999999999999                
                           START WITH 1 INCREMENT BY 1 NOCACHE';                         
    END IF;  
    ---------------------------------------- // -------------------------------    
    -- Verificando e dropando a chave primária da PCPCINTEGRAECOMMERCE_FILIAL
    V_COUNT := 0; 
    SELECT COUNT(*) INTO V_COUNT 
      FROM USER_CONSTRAINTS C
     WHERE C.table_name = 'PCINTEGRAECOMMERCE_FILIAL'
       AND C.constraint_name = 'PCINTEGRAECOMMERCE_FILIA_PK';
       
    IF V_COUNT > 0 THEN                                                                   
       EXECUTE IMMEDIATE 
         'ALTER TABLE PCINTEGRAECOMMERCE_FILIAL DROP CONSTRAINT PCINTEGRAECOMMERCE_FILIA_PK';                         
         COMMIT; 
    END IF;
    
    ------------------------------------------------------------------------------
    -- Verificar e dropar a FK
    V_COUNT := 0;
    SELECT COUNT(*) INTO V_COUNT
      FROM USER_CONSTRAINTS C
     WHERE C.table_name = 'PCINTEGRAECOMMERCE_FILIAL'
       AND C.constraint_name = 'PCINTEGRAECOMMERCE_FILIA_FK1'
       AND C.constraint_type = 'R';  -- 'R' = Foreign Key

    IF V_COUNT > 0 THEN
       EXECUTE IMMEDIATE 
         'ALTER TABLE PCINTEGRAECOMMERCE_FILIAL DROP CONSTRAINT PCINTEGRAECOMMERCE_FILIA_FK1';
    END IF;
           
EXCEPTION
    WHEN OTHERS THEN           
     ROLLBACK;                                                                          
END;