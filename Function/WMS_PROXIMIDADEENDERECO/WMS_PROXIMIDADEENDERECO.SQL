CREATE OR REPLACE FUNCTION WMS_PROXIMIDADEENDERECO(CODENDERECOREFERENCIA NUMBER,               
                                                   CODENDERECOATUAL      NUMBER)               
  RETURN NUMBER IS                                                                             
  PROXIMIDADE NUMBER;                                                                          
                                                                                               
  ENDERECOREFERENCIA NUMBER;                                                                   
  ENDERECOATUAL      NUMBER;                                                                   
BEGIN                                                                                          
  SELECT TO_NUMBER(TO_CHAR(PCENDERECO.DEPOSITO, 'FM00000') ||                                
                   TO_CHAR(PCENDERECO.RUA, 'FM00000') ||                                     
                   TO_CHAR(PCENDERECO.PREDIO, 'FM00000') ||                                  
                   TO_CHAR(PCENDERECO.NIVEL, 'FM00000') ||                                   
                   TO_CHAR(PCENDERECO.APTO, 'FM00000') ||                      
                   TO_CHAR(NVL(PCTIPOPAL.SEQUENCIA, 0), 'FM00000'))                          
    INTO ENDERECOREFERENCIA                                                                    
    FROM PCENDERECO                                                                            
       , PCTIPOPAL                                                                             
   WHERE PCENDERECO.TIPOPAL = PCTIPOPAL.CODIGO                                                 
     AND PCENDERECO.CODENDERECO = CODENDERECOREFERENCIA;                                       
                                                                                               
  SELECT TO_NUMBER(TO_CHAR(PCENDERECO.DEPOSITO, 'FM00000') ||                                
                   TO_CHAR(PCENDERECO.RUA, 'FM00000') ||                                     
                   TO_CHAR(PCENDERECO.PREDIO, 'FM00000') ||                                  
                   TO_CHAR(PCENDERECO.NIVEL, 'FM00000') ||                                   
                   TO_CHAR(PCENDERECO.APTO, 'FM00000') ||                      
                   TO_CHAR(NVL(PCTIPOPAL.SEQUENCIA, 0), 'FM00000'))                          
    INTO ENDERECOATUAL                                                                         
    FROM PCENDERECO                                                                            
       , PCTIPOPAL                                                                             
   WHERE PCENDERECO.TIPOPAL = PCTIPOPAL.CODIGO                                                 
     AND PCENDERECO.CODENDERECO = CODENDERECOATUAL;                                            
                                                                                               
  PROXIMIDADE := ABS(ENDERECOATUAL - ENDERECOREFERENCIA);                                      
  RETURN(PROXIMIDADE);                                                                         
END WMS_PROXIMIDADEENDERECO;
