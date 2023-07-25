SELECT *FROM (
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
          PCCONSOLIDATRIBUTACAO.UFORIGEM  AS UFORIGEM,
          PCCONSOLIDATRIBUTACAO.DTALTERC5 AS DTALTERC5,
          (SELECT MIN(S.ULTIMAEXECUCAO) FROM PCCONTROLECONSINCO S WHERE UPPER(S.OBJETOREFERENCIA) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CODGERALOPER') AS ULTIMAEXECAUCAO
     FROM PCCONSOLIDATRIBUTACAO PCCONSOLIDATRIBUTACAO, PCCFO PCCFO, PCTRIBUT PCTRIBUT
   WHERE PCCONSOLIDATRIBUTACAO.CODFISCAL = PCCFO.CODFISCAL
   AND PCCONSOLIDATRIBUTACAO.CODST = PCTRIBUT.CODST)
WHERE NVL(DTALTERC5, ULTIMAEXECAUCAO) >= ULTIMAEXECAUCAO