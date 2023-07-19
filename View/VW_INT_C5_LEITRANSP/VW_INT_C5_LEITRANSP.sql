CREATE OR REPLACE VIEW VW_INT_C5_LEITRANSP AS
SELECT SUBSTR(CODNBMSH,0,INSTR(CODNBMSH,'.')) AS codnbmsh,
       "CODFILIAL",
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
    SELECT DISTINCT NVL(tribncmfilial.codncm, produt.codncmex)  as codnbmsh,
           NVL(tribncmfilial.codfilial, prodfilial.codfilial)   as codfilial,
           filial.uf                                            as ufdestino,
           tribncmfilial.percfisicaestimp                       as perctributoimportado,
           tribncmfilial.percentfisica                          as perctributonacfederal,
           tribncmfilial.percentfisicaimportado                 as perctributoimpfederal,
           tribncmfilial.percfisicaestnac                       as perctributoestadual,
           tribncmfilial.percfisicamunicnac                     as perctributomunicipal,
           0                                                    as perctributos,
           tribncmfilial.codex                                  as ex,
           'S'                                                  as ativo
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