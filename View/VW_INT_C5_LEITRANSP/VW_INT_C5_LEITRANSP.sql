CREATE OR REPLACE VIEW VW_INT_C5_LEITRANSP AS
SELECT * FROM(
   SELECT DISTINCT NVL(tribncmfilial.codncm, produt.codncmex)   as codnbmsh,
           NVL(tribncmfilial.codfilial, prodfilial.codfilial)   as codfilial,
           filial.uf                                            as ufdestino,
           tribncmfilial.percfisicaestimp                       as perctributoimportado,
           tribncmfilial.percentfisica                          as perctributonacfederal,
           tribncmfilial.percentfisicaimportado                 as perctributoimpfederal,
           tribncmfilial.percfisicaestnac                       as perctributoestadual,
           tribncmfilial.percfisicamunicnac                     as perctributomunicipal,
            (
                select distinct perctributos 
                From pctribut s1, 
                     pcprodfilial s2, 
                     pctabpr s3
                where s2.codprod = s3.codprod
                 and s1.codst = s3.codst
                 and produt.codprod = s3.codprod
            
            )                                                   as perctributos,  
           tribncmfilial.codex                                  as ex,
           'S'                                                  as ativo
      FROM pctribncmfilial tribncmfilial,
           pcfilial filial,
           pcprodut produt,
           pcprodfilial prodfilial
    WHERE  produt.codncmex       = tribncmfilial.codncm(+)
          AND produt.codfilial   = filial.codigo(+)
          AND produt.codprod     = prodfilial.codprod(+)
          AND produt.codfilial   = prodfilial.codfilial(+)
)
WHERE codnbmsh IS NOT NULL
      AND ufdestino IS NOT NULL
