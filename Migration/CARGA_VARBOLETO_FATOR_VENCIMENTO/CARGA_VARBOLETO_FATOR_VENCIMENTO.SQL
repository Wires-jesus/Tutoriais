DECLARE
  CONTADOR INT;
BEGIN
  SELECT COUNT(*)
  INTO CONTADOR
  FROM PCVARIAVELBOLETO
  WHERE NOME = 'FATOR_VENCIMENTO';
  
  IF CONTADOR = 0 THEN
  BEGIN
    INSERT INTO PCVARIAVELBOLETO (
           CODIGO,
           NOME,
           DESCRICAO,
           TIPOVARIAVEL,
           TIPODADOS,
           TIPOCONTEUDO,
           VARIAVELNOSSONUMERO,
           CONTEUDO,
           STATUS
    ) VALUES (
           (SELECT MAX(CODIGO) + 1 FROM PCVARIAVELBANCARIA),
           'FATOR_VENCIMENTO',
           'Fator de Vencimento',
           'PADRAO',
           'NUMERICO',
           'SQL',
           'NAO_SE_APLICA',
           'SELECT ' ||
           '   CASE WHEN DTVENC < TO_DATE(''22022025'', ''DDMMYYYY'') THEN ' ||
           '      DTVENC - TO_DATE(''07-10-1997'', ''DD-MM-YYYY'') ' ||
           '   ELSE ' ||
           '      DTVENC - TO_DATE(''29-05-2022'', ''DD-MM-YYYY'') ' ||
           '   END AS FATORVENCIMENTO ' ||
           'FROM PCPREST ' ||
           'WHERE NUMTRANSVENDA = [NUMTRANSVENDA] ' ||
           'AND PREST = [PREST]',
           'VALIDO'
    );
  END;
  ELSE  
     UPDATE PCVARIAVELBOLETO SET CONTEUDO =
        'SELECT ' ||
        '   CASE WHEN DTVENC < TO_DATE(''22022025'', ''DDMMYYYY'') THEN ' ||
        '      DTVENC - TO_DATE(''07-10-1997'', ''DD-MM-YYYY'') ' ||
        '   ELSE ' ||
        '      DTVENC - TO_DATE(''29-05-2022'', ''DD-MM-YYYY'') ' ||
        '   END AS FATORVENCIMENTO ' ||
        'FROM PCPREST ' ||
        'WHERE NUMTRANSVENDA = [NUMTRANSVENDA] ' ||
        'AND PREST = [PREST]'
     WHERE NOME = 'FATOR_VENCIMENTO';
  END IF;
END;