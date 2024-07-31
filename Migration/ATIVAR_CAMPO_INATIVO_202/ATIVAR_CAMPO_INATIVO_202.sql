DECLARE
  VSSCRIPT          VARCHAR2(2000);
  VNEXISTEREGISTROS NUMBER;
  VSNOMECAMPO       VARCHAR2(2000);
BEGIN

  FOR DADOS IN (SELECT PCDICIONARIOITEMROT.NOMEOBJETO,
                       PCDICIONARIOITEMROT.NOMECAMPO,
                       PCDICIONARIOITEMROT.CODROTINA,
                       PCDICIONARIOITEMROT.EDITAVEL,
                       PCDICIONARIOITEMROT.OBRIGATORIO,
                       (SELECT PCDICIONARIOITEM.MASCARA
                          FROM PCDICIONARIOITEM
                         WHERE PCDICIONARIOITEMROT.NOMECAMPO =
                               PCDICIONARIOITEM.NOMECAMPO
                           AND PCDICIONARIOITEM.NOMEOBJETO =
                               PCDICIONARIOITEMROT.NOMEOBJETO) MASCARA,
                       ORDEMCAD,
                       ORDEMPSQ,
                       USARNAPESQUISA,
                       EXIBIRRESPESQ,
                       PSQAUXILIAR,
                       PSQCAMPO,
                       PSQFILTRO,
                       PSQFILTRO131,
                       PSQRETORNODESCRICAO,
                       PSQOBJETO,
                       SECAO,
                       VALORDEFAULT,
                       VISIVEL,
                       CODROTINACAD,
                       GERALOG,
                       EXECUTAACAO,
                       CODCONTROLE_EDITAVEL,
                       (SELECT PCDICIONARIOITEM.CHARCASE
                          FROM PCDICIONARIOITEM
                         WHERE PCDICIONARIOITEMROT.NOMECAMPO =
                               PCDICIONARIOITEM.NOMECAMPO
                           AND PCDICIONARIOITEM.NOMEOBJETO =
                               PCDICIONARIOITEMROT.NOMEOBJETO
                               ) CHARCASE,
                       PSQRETORNOCODIGO,
                       (SELECT PCDICIONARIOITEM.AJUDA
                          FROM PCDICIONARIOITEM
                         WHERE PCDICIONARIOITEMROT.NOMECAMPO =
                               PCDICIONARIOITEM.NOMECAMPO
                           AND PCDICIONARIOITEM.NOMEOBJETO =
                               PCDICIONARIOITEMROT.NOMEOBJETO) AJUDA
                  FROM PCDICIONARIOITEMROT
                 WHERE PCDICIONARIOITEMROT.CODROTINA = 202
                   AND PCDICIONARIOITEMROT.VISIVEL = 'N'
                   AND PCDICIONARIOITEMROT.EDITAVEL = 'S') LOOP
  
    VSSCRIPT := 'SELECT COUNT(1) FROM ' || DADOS.NOMEOBJETO || ' WHERE ' ||
                DADOS.NOMECAMPO || ' IS NOT NULL AND TO_CHAR(NVL(' ||
                DADOS.NOMECAMPO || ',''N'')) <> ''N'' ';
  
    BEGIN
    
      EXECUTE IMMEDIATE VSSCRIPT
        INTO VNEXISTEREGISTROS;
    EXCEPTION
      WHEN OTHERS THEN
        VNEXISTEREGISTROS := 0;
    END;
  
    IF (VNEXISTEREGISTROS > 0) THEN
      BEGIN
        SELECT PCDICIONARIOITEMROTCUST.NOMECAMPO
          INTO VSNOMECAMPO
          FROM PCDICIONARIOITEMROTCUST
         WHERE PCDICIONARIOITEMROTCUST.CODROTINA = DADOS.CODROTINA
           AND PCDICIONARIOITEMROTCUST.NOMECAMPO = DADOS.NOMECAMPO
           AND PCDICIONARIOITEMROTCUST.NOMEOBJETO = DADOS.NOMEOBJETO;
      
        UPDATE PCDICIONARIOITEMROTCUST
           SET VISIVEL = 'S'
         WHERE PCDICIONARIOITEMROTCUST.NOMECAMPO = DADOS.NOMECAMPO
           AND PCDICIONARIOITEMROTCUST.NOMEOBJETO = DADOS.NOMEOBJETO
           AND PCDICIONARIOITEMROTCUST.CODROTINA = DADOS.CODROTINA;
      
        COMMIT;
      
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          VSNOMECAMPO := 0;
        
          INSERT INTO PCDICIONARIOITEMROTCUST
            (CODROTINA,
             NOMECAMPO,
             NOMEOBJETO,
             EDITAVEL,
             OBRIGATORIO,
             MASCARA,
             ORDEMCAD,
             ORDEMPSQ,
             USARNAPESQUISA,
             EXIBIRRESPESQ,
             PSQAUXILIAR,
             PSQCAMPO,
             PSQFILTRO,
             PSQFILTRO131,
             PSQRETORNODESCRICAO,
             PSQOBJETO,
             SECAO,
             VALORDEFAULT,
             VISIVEL,
             CODROTINACAD,
             GERALOG,
             EXECUTAACAO,
             CODCONTROLE_EDITAVEL,
             CHARCASE,
             PSQRETORNOCODIGO,
             AJUDA)
          VALUES
            (DADOS.CODROTINA,
             DADOS.NOMECAMPO,
             DADOS.NOMEOBJETO,
             DADOS.EDITAVEL,
             DADOS.OBRIGATORIO,
             DADOS.MASCARA,
             DADOS.ORDEMCAD,
             DADOS.ORDEMPSQ,
             DADOS.USARNAPESQUISA,
             DADOS.EXIBIRRESPESQ,
             DADOS.PSQAUXILIAR,
             DADOS.PSQCAMPO,
             DADOS.PSQFILTRO,
             DADOS.PSQFILTRO131,
             DADOS.PSQRETORNODESCRICAO,
             DADOS.PSQOBJETO,
             DADOS.SECAO,
             DADOS.VALORDEFAULT,
             'S',
             DADOS.CODROTINACAD,
             DADOS.GERALOG,
             DADOS.EXECUTAACAO,
             DADOS.CODCONTROLE_EDITAVEL,
             DADOS.CHARCASE,
             DADOS.PSQRETORNOCODIGO,
             DADOS.AJUDA);
        
          COMMIT;
        
      END;
    
    END IF;
  END LOOP;

END;