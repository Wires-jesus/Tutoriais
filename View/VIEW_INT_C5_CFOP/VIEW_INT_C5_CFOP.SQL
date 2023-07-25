CREATE OR REPLACE VIEW VW_INT_C5_CFOP AS
SELECT  ROWNUM                          AS CODGERALOPER,
        PCCFO.DESCCFO                   AS DESCRICAO,
        PCCFO.CODFISCAL                 AS CFOP,
        'N'                             AS CALCULAICMSST,
        'N'                             AS GERAREDUCAOBASEST,
        'N'                             AS CALCULAIPI,
        'N'                             AS TIPOCALCULOIPI,
        'N'                             AS CALCULAFECP,
        'T'                             AS TIPOFATURAMENTO,
        'S'                             AS ATIVO,
        'N'                             AS CONSUMIDORFINAL,
        'N'                             AS VENDAPRESENCIAL,
        'P'                             AS TIPOTRIBUTACAO,
        'N'                             AS CONTRIBICMS,
        PCTRIBUT.CODST                  AS NROTRIBUTACAO,
        PCCONSOLIDATRIBUTACAO.UFDESTINO AS UFDESTINO,
        PCCFO.DESCCFO                   AS APLICACAO,
        PCCONSOLIDATRIBUTACAO.UFORIGEM  AS UFORIGEM
   FROM PCCONSOLIDATRIBUTACAO PCCONSOLIDATRIBUTACAO, PCCFO PCCFO, PCTRIBUT PCTRIBUT
 WHERE PCCONSOLIDATRIBUTACAO.CODFISCAL = PCCFO.CODFISCAL
 AND PCCONSOLIDATRIBUTACAO.CODST = PCTRIBUT.CODST
