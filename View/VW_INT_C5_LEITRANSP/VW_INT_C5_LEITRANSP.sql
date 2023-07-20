CREATE OR REPLACE VIEW VW_INT_C5_LEITRANSP AS
SELECT SUBSTR(CODNBMSH,0,INSTR(CODNBMSH,'.')) AS codnbmsh,
       "UFDESTINO",
       "PERCTRIBUTOIMPORTADO",
       "PERCTRIBUTONACFEDERAL",
       "PERCTRIBUTOIMPFEDERAL",
       "PERCTRIBUTOESTADUAL",
       "PERCTRIBUTOMUNICIPAL",
       "PERCTRIBUTOS",
       NVL(SUBSTR(CODNBMSH, INSTR(CODNBMSH,'.')+1),0) AS ex,
       "ATIVO"
   FROM(
     
      SELECT DISTINCT NVL(tribncmfilial.codncm, produt.codncmex)                                                          as codnbmsh,
                (SELECT percfisicaestimp FROM pctribncmfilial WHERE codncm = tribncmfilial.codncm AND ROWNUM = 1)         as perctributoimportado,
                (SELECT percentfisica    FROM pctribncmfilial WHERE codncm = tribncmfilial.codncm AND ROWNUM = 1)         as perctributonacfederal,
                (SELECT percentfisicaimportado  FROM pctribncmfilial WHERE codncm = tribncmfilial.codncm AND ROWNUM = 1)  as perctributoimpfederal,
                (SELECT percfisicaestnac   FROM pctribncmfilial WHERE codncm = tribncmfilial.codncm AND ROWNUM = 1)       as perctributoestadual,
                (SELECT percfisicamunicnac FROM pctribncmfilial WHERE codncm = tribncmfilial.codncm AND ROWNUM = 1)       as perctributomunicipal,
                filial.uf                                                                                                 as ufdestino,
                 0                                                                                                        as perctributos,
                tribncmfilial.codex                                                                                       as ex,
                'S'                                                                                                       as ativo          
      FROM pctribncmfilial tribncmfilial,
           pcfilial filial,
           pcprodut produt,
           pcprodfilial prodfilial
    WHERE  produt.codncmex     = tribncmfilial.codncm
      AND prodfilial.codfilial = filial.codigo
      AND prodfilial.codprod   = produt.codprod
      AND filial.codigo        = tribncmfilial.codfilial
)
WHERE codnbmsh IS NOT NULL
      AND ufdestino IS NOT NULL