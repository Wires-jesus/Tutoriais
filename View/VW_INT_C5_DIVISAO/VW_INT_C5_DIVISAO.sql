CREATE OR REPLACE VIEW VW_INT_C5_FAMDIVISAO AS
(SELECT
    PRODTRIB."SEQFAMILIA",PRODTRIB."NROTRIBUTACAO",PRODTRIB."NRODIVISAO",PRODTRIB."ATIVO",
    (select nvl(origmerctrib,0) origmerctrib from pcprodfilial where codprod = PRODTRIB.seqfamilia and rownum = 1 )codorigemtrib
 FROM
     (SELECT DISTINCT
        R.CODPROD seqfamilia,
        R.CODST nrotributacao,
        R.numregiao nrodivisao,
        'S' ativo
      FROM VW_INT_C5_FAMILIA T,
          PCTABPR R
      WHERE T.SEQFAMILIA = R.CODPROD
      AND R.CODST IS NOT NULL
      AND R.NUMREGIAO IN (SELECT VALOR
                          FROM PCPARAMFILIAL
                          WHERE NOME = 'NUMREGIAOPADRAOVAREJO'
                          AND VALOR <> '99'
                          AND REGEXP_LIKE(CODFILIAL, '^[[:digit:]]+$')
                          AND VALOR IS NOT NULL)
      )PRODTRIB
 )