DECLARE
  vnCont NUMBER;
BEGIN
  BEGIN
    SELECT COUNT(*) CONTADOR 
       INTO vnCont
    FROM pcparametros2651 where nome = 'DTFIMCARGA';
  END; 
 
  IF vnCont = 0 THEN
     insert into pcparametros2651 (NOME, VALOR, DESCRICAO, CODFILIAL)
     values ('DTFIMCARGA', 'N', 'Data utilizada na clausula between para comparar DTALTERC5', '99');
  END IF;   

END;