BEGIN 
  UPDATE PCDICIONARIO SET DESCRICAO = 'Sazonalidade de Limite Crédito Cliente' WHERE NOMEOBJETO = 'PCLIMCRED';
  COMMIT; 

  UPDATE PCDICIONARIO D SET D.DESCRICAO = 'Sazonalidade de Limite Crédito Cliente' 
   WHERE D.NOMEOBJETO = 'PCLIMCRED' 
     AND D.DESCRICAO = 'Sazionalidade de Limite Crédito Cliente';
  COMMIT; 
  
  UPDATE PCDICIONARIOITEMROT SET SECAO = '01-Geral', 
                                 EXIBIRRESPESQ = 'S' 
   WHERE CODROTINA = '3321' 
     AND NOMEOBJETO = 'PCLIMCRED' 
     AND NOMECAMPO IN ('CODDCLI','CODIGO','CODUSUR','DESCRICAO','DTFIM','DTINICIO','PERCAUMENTO','VALOR');   
  COMMIT; 

 
UPDATE PCDICIONARIOITEM DIC 
   SET DIC.AJUDA = 'Código Cliente',  
       DIC.TITULO = 'Código Cliente'
 WHERE DIC.NOMEOBJETO = 'PCCONTATO'
   AND DIC.AJUDA = 'Código CLiente'; 
COMMIT;
   
UPDATE PCDICIONARIOITEM DIC 
   SET DIC.AJUDA = 'Nome Cônjuge', 
       DIC.TITULO = 'Nome Cônjuge'
 WHERE DIC.NOMEOBJETO = 'PCCONTATO'
   AND DIC.AJUDA = 'Nome Conjuje'; 
COMMIT;

UPDATE PCDICIONARIOITEM DIC 
   SET DIC.AJUDA = 'Data Nasc. Cônjuge', 
       DIC.TITULO = 'Data Nasc. Cônjuge'
 WHERE DIC.NOMEOBJETO = 'PCCONTATO'
   AND DIC.AJUDA = 'Data Nasc Conjuje'; 
COMMIT;

UPDATE PCDICIONARIOITEM DI SET DI.AJUDA = 'Descrição da Sazonalidade' 
 WHERE DI.NOMEOBJETO = 'PCLIMCRED' 
   AND DI.AJUDA = 'Descrição da Sazionalidade';
COMMIT;

UPDATE PCDICIONARIOITEM DI SET DI.TITULO = 'Descrição da Sazonalidade' 
 WHERE DI.NOMEOBJETO = 'PCLIMCRED' 
   AND DI.TITULO = 'Descrição da Sazionalidade';   

COMMIT;
END;