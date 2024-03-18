DECLARE
  VCOUNT INTEGER;
BEGIN
  SELECT COUNT(COLUMN_NAME)
    INTO VCOUNT
    FROM ALL_TAB_COLUMNS
   WHERE OWNER = SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')
     AND TABLE_NAME = 'PCDICIONARIOITEMROT'
     AND COLUMN_NAME = 'UTILIZACADASTRODINAMICO';

  IF VCOUNT > 0 THEN
    UPDATE PCDICIONARIOITEMROT
       SET UTILIZACADASTRODINAMICO = 'S'
     WHERE NOMEOBJETO = 'PCPRODUT'
       AND CODROTINA = 203
       AND NOMECAMPO IN ('CODEPTO',
                         'CODSEC',
                         'CODMARCA',
                         'CODCATEGORIA',
                         'CODLINHAPROD',
                         'UNIDADE',
                         'UNIDADEMASTER',
                         'UNIDADEPADRAO',
                         'UNIDADETRIB',
                         'UNIDADETRIBEX',
                         'CODNCMEX');
    COMMIT;
  END IF;
END;