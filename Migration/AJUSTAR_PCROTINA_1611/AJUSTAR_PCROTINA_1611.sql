DECLARE
  vTemRotina INTEGER := 0;
BEGIN
  SELECT COUNT(1)
    INTO vTemRotina
    FROM PCROTINA
   WHERE CODIGO = 1611;

  IF vTemRotina = 0 THEN
    INSERT INTO PCROTINA
      (CODIGO,
       NOMEROTINA,
       CODMODULO,
       CODSUBMODULO,
       NUMSEQ,
       EXIBIRMENU,
       QTUTILIZACAO,
       CODFUNCULTUTIL,
       VERSAOCOMPLETA,
       UTILIZACONTROLEBIOMETRICO,
       ROTINAWEB,
       ROTINA)
    VALUES
      (1611,
       'Cadastros Operacionais da Produção',
       16,
       1,
       0,
       'S',
       32,
       1,
       '38.2601.08.04',
       'N',
       'N',
       'PCSIS1611');
  ELSE
    UPDATE PCROTINA
       SET NOMEROTINA  = 'Cadastros Operacionais da Produção',
           CODMODULO  = 16,
           CODSUBMODULO = 1,
           ROTINA      = 'PCSIS1611'
     WHERE CODIGO = 1611;
  END IF;

  COMMIT;
END;
/
