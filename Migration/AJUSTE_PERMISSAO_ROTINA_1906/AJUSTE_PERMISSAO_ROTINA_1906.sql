BEGIN
  UPDATE PCCONTROI SET
       CODCONTROLE = 33
  WHERE CODROTINA = 1906 
    AND CODCONTROLE = 29 
    AND ACESSO = 'S' 
    AND NOT EXISTS (SELECT CODROTINA
                      FROM PCCONTROI 
                     WHERE CODROTINA = 1906 
                       AND CODCONTROLE = 33 
                       AND ACESSO = 'S');
  COMMIT;
END;