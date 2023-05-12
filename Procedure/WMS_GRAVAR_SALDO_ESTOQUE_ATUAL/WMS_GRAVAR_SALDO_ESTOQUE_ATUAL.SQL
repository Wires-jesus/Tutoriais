CREATE OR REPLACE PROCEDURE WMS_GRAVAR_SALDO_ESTOQUE_ATUAL IS                    
BEGIN                                                                            
  FOR DADOS IN (SELECT CODFILIAL,                                                
                       TRUNC(SYSDATE) DATA,                                      
                       TO_CHAR(SYSDATE, 'HH24') AS HORA,                       
                       TO_CHAR(SYSDATE, 'MI') AS MINUTO,                       
                       PCESTENDERECO.CODENDERECO,                                
                       PCESTENDERECO.CODPROD,                                    
                       NVL(PCESTENDERECO.QT, 0) AS QT,                           
                       NVL(PCESTENDERECO.QT - PCESTENDERECO.QTPENDSAIDA +        
                       PCESTENDERECO.QTPENDENTRADA, 0) AS QTSALDOATUAL,          
                       PCESTENDERECOI.NUMLOTE AS NUMLOTE,                        
                       PCENDERECO.STATUS                                         
                  FROM PCESTENDERECO, PCESTENDERECOI, PCENDERECO                 
                 WHERE PCESTENDERECO.CODENDERECO = PCENDERECO.CODENDERECO        
                   AND PCESTENDERECO.CODENDERECO = PCESTENDERECOI.CODENDERECO(+) 
                   AND PCESTENDERECO.CODPROD = PCESTENDERECOI.CODPROD(+)         
                 ORDER BY PCESTENDERECO.CODENDERECO, PCESTENDERECO.CODPROD) LOOP 
    INSERT INTO PCMOVEND                                                         
      (CODFILIAL,                                                                
       DATA,                                                                     
       HORA,                                                                     
       MINUTO,                                                                   
       CODPROD,                                                                  
       QT,                                                                       
       QTSALDOATUAL,                                                             
       CODROTINA,                                                                
       CODOPER,                                                                  
       NUMLOTE,                                                                  
       CODENDERECO,                                                              
       NUMTRANSWMS)                                                              
    VALUES                                                                       
      (DADOS.CODFILIAL,                                                          
       DADOS.DATA,                                                               
       DADOS.HORA,                                                               
       DADOS.MINUTO,                                                             
       DADOS.CODPROD,                                                            
       DADOS.QT,                                                                 
       DADOS.QTSALDOATUAL,                                                       
       '1700',                                                                 
       'T',                                                                    
       DADOS.NUMLOTE,                                                            
       DADOS.CODENDERECO,                                                        
       0);                                                                       
    COMMIT;                                                                      
  END LOOP;                                                                      
END;                                                                             
