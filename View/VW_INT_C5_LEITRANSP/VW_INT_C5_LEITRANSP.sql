CREATE OR REPLACE VIEW VW_INT_C5_LEITRANSP AS
SELECT 
  CARGATRIB.*
FROM
  (SELECT DISTINCT
       NCMFILIAL.CODNCM codncmsh,
       NVL(NCMFILIAL.CODEX, 0) ex,
       NCMFILIAL.UF ufdestino,

       NVL((SELECT PERCTRIBUTOS
        FROM PCTRIBUT
        WHERE CODST = (select distinct t.codst
                       from pctabpr t, pcprodut p, pcregiao r
                       where t.codprod = p.codprod
                       and   t.numregiao = r.numregiao
                       and   r.uf = NCMFILIAL.UF
                       and   p.codncmex = NCMFILIAL.CODNCM||'.'||NCMFILIAL.CODEX AND ROWNUM = 1)), 0) perctributos,
       
       GREATEST(
                (SELECT DTALTERC5
                 FROM PCTRIBUT
                 WHERE CODST = (select distinct t.codst
                                from pctabpr t, pcprodut p, pcregiao r
                                where t.codprod = p.codprod
                                and   t.numregiao = r.numregiao
                                and   r.uf = NCMFILIAL.UF
                                and   p.codncmex = NCMFILIAL.CODNCM||'.'||NCMFILIAL.CODEX AND ROWNUM = 1)),
                                
                  NCMFILIAL.dtalterc5,
                  TRIBNCMFILIAL.dtalterc5
                )dtalterc5,  

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
    (SELECT
       NCM.*,
       (SELECT CODIGO FROM PCFILIAL WHERE UF = NCM.UF AND REGEXP_LIKE(CODIGO, '^[[:digit:]]+$') AND CODIGO <> '99' AND ROWNUM = 1) CODFILIAL
     FROM
         (SELECT DISTINCT
             PCNCM.CODNCM,/*CODNCM É CADASTRADO SEM O "." */
             PCNCM.CODNCMEX,/*CODNCM DA PCNCM É CADASTRADO COM "." E JÁ POSSUI A EXCEÇÃO CASO EXISTA*/
             PCNCM.CODEX,
             PCNCM.DTEXCLUSAO,
             PCNCM.DTALTERC5,
             PCFILIAL.UF
           FROM PCNCM,
                PCFILIAL
           WHERE PCFILIAL.CODIGO <> '99'
           AND   REGEXP_LIKE(PCFILIAL.CODIGO, '^[[:digit:]]+$')
           AND   PCFILIAL.UF IS NOT NULL
           AND   PCNCM.CODNCMEX IS NOT NULL
           )NCM
     )NCMFILIAL,

    (SELECT
       PCTRIBNCMFILIAL.codncm||PCTRIBNCMFILIAL.codfilial ID,
       PCTRIBNCMFILIAL.DTALTERC5,
       PCTRIBNCMFILIAL.percentfisica,
       PCTRIBNCMFILIAL.percfisicaestimp,
       PCTRIBNCMFILIAL.percentfisicaimportado,
       PCTRIBNCMFILIAL.percfisicaestnac,
       PCTRIBNCMFILIAL.percfisicamunicnac
     FROM PCTRIBNCMFILIAL
     WHERE PCTRIBNCMFILIAL.CODFILIAL <> '99'
     AND   REGEXP_LIKE(PCTRIBNCMFILIAL.CODFILIAL, '^[[:digit:]]+$')
     )TRIBNCMFILIAL

   WHERE NCMFILIAL.CODNCMEX||NCMFILIAL.CODFILIAL = TRIBNCMFILIAL.ID(+)
   )CARGATRIB,
     
   (select min(s.ultimaexecucao) ultimaexecucao
    from pccontroleconsinco s
    where (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CARGATRIBUTARIA')
   )DTPADRAO

WHERE NVL(CARGATRIB.DTALTERC5, DTPADRAO.ULTIMAEXECUCAO) >= DTPADRAO.ULTIMAEXECUCAO