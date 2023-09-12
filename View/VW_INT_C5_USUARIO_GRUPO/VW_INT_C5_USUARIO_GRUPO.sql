CREATE OR REPLACE VIEW VW_INT_C5_USUARIO_GRUPO AS
(
SELECT DISTINCT (CASE
                    WHEN TBOPER.OPER IS NOT NULL THEN 'OPERADOR DE CAIXA'
                    WHEN TBFISCAL.FISCAL IS NOT NULL THEN 'FISCAL DE CAIXA'
                    ELSE 'GRUPO SEM NOME'
                END) NOMEGRUPO,
               (CASE
                    WHEN TBOPER.OPER IS NOT NULL THEN TBOPER.OPER
                    WHEN TBFISCAL.FISCAL IS NOT NULL THEN TBFISCAL.FISCAL
                    ELSE '0'
                END) CODGRUPO,
               TBPERDESC.PERDESC PERCDESCMAX,
               'S' ATIVO
FROM pcempr r,
    (SELECT valor OPER
     FROM pcparamfilial
     WHERE nome = 'CON_CODSETOROPERCX'
       AND codfilial = '99') TBOPER,

    (SELECT valor FISCAL
     FROM pcparamfilial
     WHERE nome = 'CON_CODSETORFISCALCX'
       AND codfilial = '99') TBFISCAL,

    (SELECT NVL(TO_NUMBER(valor), 0) PERDESC
     FROM pcparamfilial
     WHERE nome = 'CON_PERMAXDESCITEMCF'
       AND codfilial = '99') TBPERDESC,


     (SELECT s.ultimaexecucao
      FROM pccontroleconsinco s
      WHERE upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_USUARIO') DTPADRAO

   WHERE r.codsetor IN (TBFISCAL.fiscal, TBOPER.oper)
     AND NVL(r.Dtalterc5, DTPADRAO.ULTIMAEXECUCAO) >= DTPADRAO.ULTIMAEXECUCAO
)
