CREATE OR REPLACE VIEW VW_INT_C5_CFOP AS
SELECT *FROM
  (SELECT DISTINCT
          a.cfop                          AS codgeraloper,
          SUBSTR(UPPER(o.desccfo),1,40)   AS descricao,
          SUBSTR(UPPER(o.desccfo),1,80)   AS aplicacao,
          a.codst                         AS nrotributacao,
          a.cfop                          AS cfopestado,
          a.cfopexterno                   AS cfopforaestado,
          a.uforigem                      AS uforigem,
          a.ufdestino                     AS ufdestino,
          'N'                             AS contribicms,
           0                              AS nroregtributacao,
          'S'                             AS ativo,
          a.dtalterc5                     AS dtalterc5,
          'N'                             AS calculaicmsst,
          'N'                             AS gerareducaobasest,
          'N'                             AS calculaipi,
          'N'                             AS tipocalculoipi,
          'N'                             AS calculafecp,
          'T'                             AS tipofaturamento,
          'N'                             AS consumidorfinal,
          'N'                             AS vendapresencial,
          'P'                             AS tipotributacao
    FROM  pcconsolidatributacao a,
          pccfo o
   WHERE  o.codfiscal = a.cfop)
   WHERE UFDESTINO IS NOT NULL
         AND UFORIGEM IS NOT NULL