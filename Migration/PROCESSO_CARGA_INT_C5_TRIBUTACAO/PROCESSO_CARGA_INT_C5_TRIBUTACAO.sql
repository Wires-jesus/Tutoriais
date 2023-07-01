CREATE OR REPLACE VIEW VW_INT_C5_TRIB_UF AS
(SELECT     t.codst nrotributacao,
            c.UFORIGEM uforigem,
            c.UFDESTINO ufdestino,
            'SN' tipotributacao,
            C.NUMREGIAO nroregtributacao,
            c.percaliquota,
            '0' || NVL (t.sittributpf, t.sittributecf) situacaotributacao,
            c.percisento,
            c.perctributado,
            0 percacrescst,
            NVL(t.aliqstsaida,0) percisentost,
            'B' tipocalcfcp,
            0 percbasefcpicms,
            NVL(t.peracrescimofuncep,0) percaliqfcpicms,
            c.reducaobasest,
            'T' tiporeducaoicmscalcst,
            0 perctributst,
            'S' ativo,
            0 situacaopis,
            0 situacaocofins,
            0 percpis,
            0 perccofins,
            0 percbasefcpst,
            0 percaliqfcpst,
            c.calcicmsdeson,
            c.percdesoneracao percaliqicmsdeson,
            c.codmotivodesoneracao motivodesonicms,
            c.codbeneficiofiscal codbeneficiodesonicms,
            t.codst,
            t.mensagem || ' - TRIBUTACAO' tributacao,
            t.mensagem || ' - TRIBUTACAO' descaplicacao,
            COALESCE(t.codecf, '0000') codecf,
            GREATEST(
                     NVL(t.DTALTERC5, d.datapadrao),
                     NVL(c.DTALTERC5, d.datapadrao)) data,

            COALESCE(t.aliqicms1,0) aliqicms1,
            COALESCE(t.aliqicms2,0) aliqicms2
FROM pctribut t,
     PCCONSOLIDATRIBUTACAO c,
     (SELECT MIN(s.ultimaexecucao) datapadrao FROM pccontroleconsinco s) d

WHERE t.codst = c.codst
      AND NVL(t.sittributecf, t.sittribut) IN ('00', '20', '40', '41', '60', '90')
      AND t.codecf IS NOT NULL
      AND t.codst is not null)

\

CREATE OR REPLACE VIEW VW_INT_C5_TRIB_UF_CONSOLIDADA AS
(
SELECT  NROTRIBUTACAO,
        UFORIGEM,
        UFDESTINO,
        'SN' TIPOTRIBUTACAO,
        NROREGTRIBUTACAO,
        PERCALIQUOTA,
        SITUACAOTRIBUTACAO,
        PERCISENTO,
        PERCTRIBUTADO,
        PERCACRESCST,
        PERCISENTOST,
        TIPOCALCFCP,
        PERCBASEFCPICMS,
        PERCALIQFCPICMS,
        REDUCAOBASEST,
        TIPOREDUCAOICMSCALCST,
        PERCTRIBUTST,
        ATIVO,
        SITUACAOPIS,
        SITUACAOCOFINS,
        PERCPIS,
        PERCCOFINS,
        PERCBASEFCPST,
        PERCALIQFCPST,
        CALCICMSDESON,
        PERCALIQICMSDESON,
        MOTIVODESONICMS,
        CODBENEFICIODESONICMS,
        CODST
  FROM VW_INT_C5_TRIB_UF
 WHERE DATA >= (SELECT S.ULTIMAEXECUCAO  FROM PCCONTROLECONSINCO S WHERE UPPER(S.OBJETOREFERENCIA) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_TRIBUTACAOUF'))

\

CREATE OR REPLACE VIEW VW_TB_TRIBUTACAO_CONSOLIDADA AS
(
SELECT NROTRIBUTACAO,
       CODST,
       TRIBUTACAO,
       DESCAPLICACAO,
       CODECF,
       ATIVO,
       DATA,
       ALIQICMS1,
       ALIQICMS2
  FROM VW_INT_C5_TRIB_UF 
 WHERE DATA >= (SELECT MIN(S.ULTIMAEXECUCAO) FROM PCCONTROLECONSINCO S WHERE UPPER(S.OBJETOREFERENCIA) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_TRIBUTACAO'))
