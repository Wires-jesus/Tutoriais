DECLARE 
  vTemRotinaTabela integer := 0;
BEGIN
   SELECT COUNT(1)
    INTO vTemRotinaTabela
    FROM PCROTINATABELA
   WHERE NOMEOBJETO = 'PCNATUREZAOPERACAO'
     AND CODROTINA = 4014; 

   IF vTemRotinaTabela = 0 THEN
     INSERT INTO PCROTINATABELA (CODROTINA, NOMEOBJETO, USARCADGENERICO, WHEREADICIONALPESQ, PERMITEINCLUIR, PERMITEALTERAR, PERMITEEXCLUIR, TITULOROTINA, ATUALIZARPERMISSAO)
                         VALUES (4014, 
                                 'PCNATUREZAOPERACAO', 
                                 'N', 
                                 '...',                   
                                 'S',              
                                 'S',             
                                 'S',      
                                 'Cadastro Natureza de operação', 
                                 'S');
   END IF;

   COMMIT;
END;