DECLARE 
  vTemRotinaTabela integer := 0;
BEGIN
   SELECT COUNT(1)
     INTO vTemRotinaTabela
     FROM PCROTINATABELA
    WHERE NOMEOBJETO = 'PCNATUREZAOPERACAO';

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
   
   UPDATE PCDICIONARIO SET DESCRICAO = 'Natureza de Operação' WHERE NOMEOBJETO = 'PCNATUREZAOPERACAO';
   DELETE FROM PCROTINAI I WHERE I.CODROTINA = 4014 AND I.CODCONTROLE BETWEEN 0 AND 6; 
   
   COMMIT;
   
END;