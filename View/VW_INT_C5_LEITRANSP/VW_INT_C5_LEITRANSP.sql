CREATE OR REPLACE VIEW VW_INT_C5_LEITRANSP AS
(
SELECT
  CARGATRIB."CODNCMSH",
  CARGATRIB."EX",
  CARGATRIB."UFDESTINO",
  MAX(CARGATRIB."PERCTRIBUTOS") PERCTRIBUTOS,
  MAX(CARGATRIB."PERCTRIBUTONACFEDERAL") PERCTRIBUTONACFEDERAL,
  MAX(CARGATRIB."PERCTRIBUTOIMPORTADO") PERCTRIBUTOIMPORTADO,
  MAX(CARGATRIB."PERCTRIBUTOIMPFEDERAL") PERCTRIBUTOIMPFEDERAL,
  MAX(CARGATRIB."PERCTRIBUTOESTADUAL") PERCTRIBUTOESTADUAL,
  MAX(CARGATRIB."PERCTRIBUTOMUNICIPAL")PERCTRIBUTOMUNICIPAL ,
  MAX(CARGATRIB."ATIVO") ATIVO
FROM
  (SELECT DISTINCT
       NCMFILIAL.CODNCM codncmsh,
       NVL(NCMFILIAL.CODEX, 0) ex,
       NCMFILIAL.UF ufdestino,
       NVL(PRODTRIB.PERCTRIBUTOS, 0) PERCTRIBUTOS,
       NVL(TRIBNCMFILIAL.percentfisica, 0) perctributonacfederal,
       NVL(TRIBNCMFILIAL.percfisicaestimp, 0) perctributoimportado,
       NVL(TRIBNCMFILIAL.percentfisicaimportado, 0) perctributoimpfederal,
       NVL(TRIBNCMFILIAL.percfisicaestnac, 0) perctributoestadual,
       NVL(TRIBNCMFILIAL.percfisicamunicnac, 0) perctributomunicipal,

       (CASE
           WHEN NCMFILIAL.DTEXCLUSAO IS NULL THEN
                'S'
           ELSE
                'N'
       END) ativo
   FROM
     (SELECT DISTINCT
             PCNCM.CODNCM, /*CODNCM É CADASTRADO SEM O "." */
             PCNCM.CODNCMEX, /*CODNCM DA PCNCM É CADASTRADO COM "." E JÁ POSSUI A EXCEÇÃO CASO EXISTA*/
             PCNCM.CODEX,
             PCNCM.DTEXCLUSAO,
             PCREGIAO.UF,
             PCREGIAO.CODFILIAL
           FROM PCNCM,
                PCREGIAO,
                (select min(s.ultimaexecucao) ultimaexecucao
                 from pccontroleconsinco s
                 where (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CARGATRIBUTARIA')
                )DTPADRAO
           WHERE PCNCM.CODNCMEX IS NOT NULL
           AND   LENGTH(CODEX) <= 2
           AND   PCREGIAO.NUMREGIAO IN (SELECT DISTINCT(VALOR)
                                        FROM PCPARAMFILIAL
                                        WHERE NOME = 'NUMREGIAOPADRAOVAREJO'
                                        AND VALOR <> '99'
                                        AND REGEXP_LIKE(CODFILIAL, '^[[:digit:]]+$')
                                        AND VALOR IS NOT NULL)
           AND   NVL(PCNCM.DTALTERC5, DTPADRAO.ULTIMAEXECUCAO) >= DTPADRAO.ULTIMAEXECUCAO
     )NCMFILIAL,

    (SELECT
       PCTRIBNCMFILIAL.CODNCM||PCTRIBNCMFILIAL.CODFILIAL ID,
       PCTRIBNCMFILIAL.percentfisica,
       PCTRIBNCMFILIAL.percfisicaestimp,
       PCTRIBNCMFILIAL.percentfisicaimportado,
       PCTRIBNCMFILIAL.percfisicaestnac,
       PCTRIBNCMFILIAL.percfisicamunicnac
     FROM PCTRIBNCMFILIAL, PCFILIAL,
          (select min(s.ultimaexecucao) ultimaexecucao
           from pccontroleconsinco s
           where (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CARGATRIBUTARIA')
           )DTPADRAO
     WHERE PCTRIBNCMFILIAL.CODFILIAL = PCFILIAL.CODIGO
     AND   PCTRIBNCMFILIAL.CODFILIAL <> '99'
     AND   REGEXP_LIKE(PCTRIBNCMFILIAL.CODFILIAL, '^[[:digit:]]+$')
     AND   NVL(PCTRIBNCMFILIAL.DTALTERC5, DTPADRAO.ULTIMAEXECUCAO) >= DTPADRAO.ULTIMAEXECUCAO
     )TRIBNCMFILIAL,

     (SELECT DISTINCT
         P.codncmex,
         G.UF,
         MAX(T.PERCTRIBUTOS) PERCTRIBUTOS
      FROM PCTRIBUT T,
           PCTABPR R,
           PCNCM N,
           PCPRODUT P,
           PCREGIAO G,
          (select min(s.ultimaexecucao) ultimaexecucao
           from pccontroleconsinco s
           where (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CARGATRIBUTARIA')
          )DTPADRAO
      WHERE R.CODST = T.CODST
      AND   P.CODPROD = R.CODPROD
      AND   G.NUMREGIAO = R.NUMREGIAO
      AND   G.NUMREGIAO IN (SELECT DISTINCT(VALOR)
                            FROM PCPARAMFILIAL
                            WHERE NOME = 'NUMREGIAOPADRAOVAREJO'
                            AND VALOR <> '99'
                            AND REGEXP_LIKE(CODFILIAL, '^[[:digit:]]+$')
                            AND VALOR IS NOT NULL)

      AND   N.CODNCMEX IS NOT NULL
      AND   P.CODNCMEX IS NOT NULL
      AND   LENGTH(CODEX) <= 2
      AND   T.CODST IS NOT NULL
      AND   P.codncmex = N.CODNCM||'.'||N.CODEX
      AND   NVL(T.DTALTERC5, DTPADRAO.ULTIMAEXECUCAO) >= DTPADRAO.ULTIMAEXECUCAO
      GROUP BY P.codncmex, G.UF
     ) PRODTRIB

   WHERE NCMFILIAL.CODNCMEX||NCMFILIAL.CODFILIAL = TRIBNCMFILIAL.ID(+)
   AND   PRODTRIB.codncmex = NCMFILIAL.CODNCM||'.'||NCMFILIAL.CODEX
   AND   PRODTRIB.UF = NCMFILIAL.UF
  )CARGATRIB
GROUP BY CARGATRIB.CODNCMSH,
         CARGATRIB.EX,
         CARGATRIB.UFDESTINO
)