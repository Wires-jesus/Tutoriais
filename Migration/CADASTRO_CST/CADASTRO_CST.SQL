DECLARE                                                                                                                                                          
  VCSTEXISTENTE VARCHAR2(3);                                                                                                                                     
                                                                                                                                                                 
  VCST00  VARCHAR2(3);                                                                                                                                           
  VCST10  VARCHAR2(3);                                                                                                                                           
  VCST20  VARCHAR2(3);                                                                                                                                           
  VCST30  VARCHAR2(3);                                                                                                                                           
  VCST40  VARCHAR2(3);                                                                                                                                           
  VCST41  VARCHAR2(3);                                                                                                                                           
  VCST50  VARCHAR2(3);                                                                                                                                           
  VCST51  VARCHAR2(3);                                                                                                                                           
  VCST60  VARCHAR2(3); 
  VCST61  VARCHAR2(3);   
  VCST70  VARCHAR2(3);                                                                                                                                           
  VCST90  VARCHAR2(3);                                                                                                                                           
                                                                                                                                                                 
  VCST101 VARCHAR2(3);                                                                                                                                           
  VCST102 VARCHAR2(3);                                                                                                                                           
  VCST103 VARCHAR2(3);                                                                                                                                           
  VCST201 VARCHAR2(3);                                                                                                                                           
  VCST202 VARCHAR2(3);                                                                                                                                           
  VCST203 VARCHAR2(3);                                                                                                                                           
  VCST300 VARCHAR2(3);                                                                                                                                           
  VCST400 VARCHAR2(3);                                                                                                                                           
  VCST500 VARCHAR2(3);                                                                                                                                           
  VCST900 VARCHAR2(3);                                                                                                                                           
                                                                                                                                                                 
  FUNCTION EXISTECST(PCST IN VARCHAR2) RETURN VARCHAR2 IS                                                                                                        
                                                                                                                                                                 
    VQTD NUMBER;                                                                                                                                                 
  BEGIN                                                                                                                                                          
    VQTD := 0;                                                                                                                                                   
    SELECT COUNT(*)                                                                                                                                              
                                                                                                                                                                 
      INTO VQTD                                                                                                                                                  
      FROM PCCST                                                                                                                                                 
     WHERE CST = PCST                                                                                                                                            
       AND ROWNUM = 1;                                                                                                                                           
                                                                                                                                                                 
    IF VQTD > 0 THEN                                                                                                                                             
                                                                                                                                                                 
      RETURN 'S';                                                                                                                                              
                                                                                                                                                                 
    ELSE                                                                                                                                                         
      RETURN 'N';                                                                                                                                              
    END IF;                                                                                                                                                      
                                                                                                                                                                 
  END;                                                                                                                                                           
                                                                                                                                                                 
BEGIN                                                                                                                                                            
                                                                                                                                                                 
  VCST00  := '00';                                                                                                                                             
  VCST10  := '10';                                                                                                                                             
  VCST20  := '20';                                                                                                                                             
  VCST30  := '30';                                                                                                                                             
  VCST40  := '40';                                                                                                                                             
  VCST41  := '41';                                                                                                                                             
  VCST50  := '50';                                                                                                                                             
  VCST51  := '51';                                                                                                                                             
  VCST60  := '60'; 
  VCST61  := '61';  
  VCST70  := '70';                                                                                                                                             
  VCST90  := '90';                                                                                                                                             
                                                                                                                                                                 
  VCST101 := '101';                                                                                                                                            
  VCST102 := '102';                                                                                                                                            
  VCST103 := '103';                                                                                                                                            
  VCST201 := '201';                                                                                                                                            
  VCST202 := '202';                                                                                                                                            
  VCST203 := '203';                                                                                                                                            
  VCST300 := '300';                                                                                                                                            
  VCST400 := '400';                                                                                                                                            
  VCST500 := '500';                                                                                                                                            
  VCST900 := '900';                                                                                                                                            
                                                                                                                                                                 
  IF EXISTECST(VCST00) = 'N' THEN                                                                                                                              
    INSERT INTO PCCST                                                                                                                                            
      (CST, DESCRICAO)                                                                                                                                           
    VALUES                                                                                                                                                       
      ('00', 'TRIBUTADA INTEGRALMENTE');                                                                                                                     
  END IF;                                                                                                                                                        
                                                                                                                                                                 
  IF EXISTECST(VCST10) = 'N' THEN                                                                                                                              
    INSERT INTO PCCST                                                                                                                                            
      (CST, DESCRICAO)                                                                                                                                           
    VALUES                                                                                                                                                       
      ('10',                                                                                                                                                   
       'TRIBUTADA E COM COBRANÇA DO ICMS POR SUBSTITUIÇÃO TRIBUTÁRIA');                                                                                        
  END IF;                                                                                                                                                        
                                                                                                                                                                 
  IF EXISTECST(VCST20) = 'N' THEN                                                                                                                              
    INSERT INTO PCCST                                                                                                                                            
      (CST, DESCRICAO)                                                                                                                                           
    VALUES                                                                                                                                                       
      ('20', 'COM REDUÇÃO DE BASE DE CÁLCULO');                                                                                                              
  END IF;                                                                                                                                                        
                                                                                                                                                                 
  IF EXISTECST(VCST30) = 'N' THEN                                                                                                                              
    INSERT INTO PCCST                                                                                                                                            
      (CST, DESCRICAO)                                                                                                                                           
    VALUES                                                                                                                                                       
      ('30',                                                                                                                                                   
       'ISENTA OU NÃO TRIBUTADA E COM COBRANÇA DO ICMS POR SUBSTITUIÇÃO TRIBUTÁRIA');                                                                          
  END IF;                                                                                                                                                        
                                                                                                                                                                 
  IF EXISTECST(VCST40) = 'N' THEN                                                                                                                              
    INSERT INTO PCCST (CST, DESCRICAO) VALUES ('40', 'ISENTA');                                                                                              
  END IF;                                                                                                                                                        
                                                                                                                                                                 
  IF EXISTECST(VCST41) = 'N' THEN                                                                                                                              
    INSERT INTO PCCST (CST, DESCRICAO) VALUES ('41', 'Não Tributada');                                                                                       
  END IF;                                                                                                                                                        
                                                                                                                                                                 
  IF EXISTECST(VCST50) = 'N' THEN                                                                                                                              
    INSERT INTO PCCST (CST, DESCRICAO) VALUES ('50', 'SUSPENSÃO');                                                                                           
  END IF;                                                                                                                                                        
                                                                                                                                                                 
  IF EXISTECST(VCST51) = 'N' THEN                                                                                                                              
    INSERT INTO PCCST (CST, DESCRICAO) VALUES ('51', 'DIFERIMENTO');                                                                                         
  END IF;                                                                                                                                                        
                                                                                                                                                                 
  IF EXISTECST(VCST60) = 'N' THEN                                                                                                                              
    INSERT INTO PCCST                                                                                                                                            
      (CST, DESCRICAO)                                                                                                                                           
    VALUES                                                                                                                                                       
      ('60', 'ICMS COBRADO ANTERIORMENTE POR SUBSTITUIÇÃO TRIBUTÁRIA');                                                                                      
  END IF; 

  IF EXISTECST(VCST61) = 'N' THEN                                                                                                                              
    INSERT INTO PCCST                                                                                                                                            
      (CST, DESCRICAO)                                                                                                                                           
    VALUES                                                                                                                                                       
      ('61', 'TRIBUTAÇÃO MONOFÁSICA SOBRE COMBUSTÍVEIS COBRADA ANTERIORMENTE');                                                                                      
  END IF;    
                                                                                                                                                                 
  IF EXISTECST(VCST70) = 'N' THEN                                                                                                                              
    INSERT INTO PCCST                                                                                                                                            
      (CST, DESCRICAO)                                                                                                                                           
    VALUES                                                                                                                                                       
      ('70', 'COM REDUÇÃO DE BASE SUBSTITUIÇÃO TRIBUTÁRIA');                                                                                                 
  END IF;                                                                                                                                                        
                                                                                                                                                                 
  IF EXISTECST(VCST90) = 'N' THEN                                                                                                                              
    INSERT INTO PCCST (CST, DESCRICAO) VALUES ('90', 'OUTRAS');                                                                                              
  END IF;                                                                                                                                                        
                                                                                                                                                                 
                                                                                                                                                                 
  IF EXISTECST(VCST101) = 'N' THEN                                                                                                                             
    INSERT INTO PCCST (CST, DESCRICAO) VALUES ('101', 'TRIBUTADA PELO SIMPLES NACIONAL COM PERMISSÃO DE CRÉDITO');                                           
  END IF;                                                                                                                                                        
                                                                                                                                                                 
  IF EXISTECST(VCST102) = 'N' THEN                                                                                                                             
    INSERT INTO PCCST (CST, DESCRICAO) VALUES ('102', 'TRIBUTADA PELO SIMPLES NACIONAL SEM PERMISSÃO DE CRÉDITO');                                           
  END IF;                                                                                                                                                        
                                                                                                                                                                 
  IF EXISTECST(VCST103) = 'N' THEN                                                                                                                             
    INSERT INTO PCCST (CST, DESCRICAO) VALUES ('103', 'ISENTO');                                                                                             
  END IF;                                                                                                                                                        
                                                                                                                                                                 
  IF EXISTECST(VCST201) = 'N' THEN                                                                                                                             
    INSERT INTO PCCST (CST, DESCRICAO) VALUES ('201', 'TRIBUTADA PELO SIMPLES NACIONAL COM PERMISSÃO DE CRÉDITO E COM COBRANÇA DO ICMS POR SUB. TRIBUT.');   
  END IF;                                                                                                                                                        
                                                                                                                                                                 
  IF EXISTECST(VCST202) = 'N' THEN                                                                                                                             
    INSERT INTO PCCST (CST, DESCRICAO) VALUES ('202', 'TRIBUTADA PELO SIMPLES NACIONAL SEM PERMISSÃO DE CRÉDITO E COM COBRANÇA DO ICMS POR SUB. TRIBUT.');   
  END IF;                                                                                                                                                        
                                                                                                                                                                 
  IF EXISTECST(VCST203) = 'N' THEN                                                                                                                             
    INSERT INTO PCCST (CST, DESCRICAO) VALUES ('203', 'ISENÇÃO DO ICMS NO SIMPLES NACIONAL PARA FAIXA DE RECEITA BRUTA E COM COB DO ICMS POR SUB. TRIBUT.'); 
  END IF;                                                                                                                                                        
                                                                                                                                                                 
  IF EXISTECST(VCST300) = 'N' THEN                                                                                                                             
    INSERT INTO PCCST (CST, DESCRICAO) VALUES ('300', 'IMUNES OU ISENTOS');                                                                                  
  END IF;                                                                                                                                                        
                                                                                                                                                                 
  IF EXISTECST(VCST400) = 'N' THEN                                                                                                                             
    INSERT INTO PCCST(CST, DESCRICAO)VALUES ('400', 'NÃO TRIBUTADO PELO SIMPLES NACIONAL');                                                                  
  END IF;                                                                                                                                                        
                                                                                                                                                                 
  IF EXISTECST(VCST500) = 'N' THEN                                                                                                                             
    INSERT INTO PCCST(CST, DESCRICAO)VALUES ('500', 'ICMS COBRADO ANTERIORMENTE POR SUBSTITUIÇÃO TRIBUTÁRIA (SUBSTITUÍDO) OU POR ANTECIPAÇÃO');              
  END IF;                                                                                                                                                        
                                                                                                                                                                 
  IF EXISTECST(VCST900) = 'N' THEN                                                                                                                             
    INSERT INTO PCCST(CST, DESCRICAO)VALUES ('900', 'OUTROS');                                                                                               
  END IF;                                                                                                                                                        

COMMIT;                                                                                                                                                                 
END; 