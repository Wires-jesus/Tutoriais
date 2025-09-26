DECLARE                                                                                   
    V_COUNT NUMBER; 
BEGIN  
    ---------------------------------------- // -------------------------------
    -- Verificar e criar a sequência                                                      
    SELECT COUNT(*) INTO V_COUNT                                                          
    FROM ALL_SEQUENCES                                                                    
    WHERE SEQUENCE_NAME = 'DFSEQ_PCINTEGRAECOMMERCE_PARAM';                             
                                                                                          
    IF V_COUNT = 0 THEN                                                                   
        EXECUTE IMMEDIATE 'CREATE SEQUENCE DFSEQ_PCINTEGRAECOMMERCE_PARAM                
                           MINVALUE 1 MAXVALUE 999999999999999999999999999                
                           START WITH 1 INCREMENT BY 1 NOCACHE';                         
    END IF;           
EXCEPTION
    WHEN OTHERS THEN           
     ROLLBACK;                                                                          
END;