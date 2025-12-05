CREATE OR REPLACE PROCEDURE WMS_GRAVAR_SALDO_ESTOQUE_ATUAL IS                    
  VEXISTE   number;
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
				 
	SELECT COUNT(*) INTO VEXISTE
      FROM PCMOVEND
     WHERE CODFILIAL = DADOS.CODFILIAL
       AND TRUNC(DATA) = DADOS.DATA
       AND CODPROD = DADOS.CODPROD
       AND CODROTINA = '1700'
       and NVL(numlote, '1') = NVL(DADOS.NUMLOTE,'1')
       AND CODENDERECO = DADOS.CODENDERECO
       AND CODOPER = 'T';

  IF VEXISTE = 0 THEN
	
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
	END IF;
  END LOOP;                                                                      
END;                                                                             
