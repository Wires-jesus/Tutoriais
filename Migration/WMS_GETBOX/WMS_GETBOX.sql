CREATE OR REPLACE                                                       
FUNCTION WMS_GETBOX(PNUMOS NUMBER,PTIPORET VARCHAR2) RETURN VARCHAR2 IS 
  VCODBOX    PCBOXWMS.CODBOX%TYPE;                                      
  VDESCRICAO PCBOXWMS.DESCRICAO%TYPE;                                   
BEGIN                                                                   
                                                                        
  VCODBOX    := '';                                                   
  VDESCRICAO := '';                                                   
                                                                        
  SELECT TO_CHAR(NVL(B.CODBOX, M.NUMBOX))                               
       , B.DESCRICAO                                                    
    INTO VCODBOX                                                        
       , VDESCRICAO                                                     
    FROM PCMOVENDPEND M                                                 
         ,PCBOXWMS B                                                    
   WHERE M.NUMOS = PNUMOS                                               
     AND M.NUMOS > 0                                                    
     AND ROWNUM = 1                                                     
     AND NVL(M.CODBOX,M.NUMBOX) = B.CODBOX(+)                           
     AND M.CODFILIAL = B.CODFILIAL(+)                                   
GROUP BY TO_CHAR(NVL(B.CODBOX, M.NUMBOX))                               
       , B.DESCRICAO;                                                   
                                                                        
   IF PTIPORET = 'D' THEN                                             
    RETURN VDESCRICAO;                                                  
   ELSE                                                                 
    RETURN VCODBOX;                                                     
   END IF;                                                              
END;                                                                    