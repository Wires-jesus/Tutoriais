CREATE OR REPLACE VIEW VW_INT_C5_USUARIO_GRUPO AS
(
SELECT DISTINCT
      GRUPO.valor CODGRUPO,
      GRUPO.NOMEGRUPO NOMEGRUPO,
      TBPERDESC.PERDESC PERCDESCMAX,
      'S' ATIVO
FROM
PCEMPR R,
    (SELECT valor, 'OPERADOR DE CAIXA' NOMEGRUPO
      FROM pcparamfilial
      WHERE nome = 'CON_CODSETOROPERCX'
      AND codfilial = '99'
      UNION ALL
      SELECT valor, 'FISCAL DE CAIXA' NOMEGRUPO
      FROM pcparamfilial
      WHERE nome = 'CON_CODSETORFISCALCX'
      AND codfilial = '99'
    ) GRUPO,

    (SELECT NVL(TO_NUMBER(valor), 0) PERDESC
      FROM pcparamfilial
      WHERE nome = 'CON_PERMAXDESCITEMCF'
      AND codfilial = '99'
    ) TBPERDESC

WHERE r.codsetor = (GRUPO.valor)
)
