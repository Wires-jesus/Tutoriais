CREATE OR REPLACE VIEW VW_INT_C5_LEITRANSP AS
SELECT DISTINCT
       NCMFILIAL.CODNCM codncmsh,
       NCMFILIAL.CODEX ex,
       NCMFILIAL.UF ufdestino,
       (SELECT PERCTRIBUTOS
        FROM PCTRIBUT 
        WHERE CODST = (select distinct t.codst 
                       from pctabpr t, pcprodut p, pcregiao r 
                       where t.codprod = p.codprod
                       and   t.numregiao = r.numregiao
                       and   r.uf = NCMFILIAL.UF
                       and   p.codncmex = NCMFILIAL.CODNCM||'.'||NCMFILIAL.CODEX AND ROWNUM = 1)) perctributos,
       pctribncmfilial.percentfisica perctributonacfederal,
       pctribncmfilial.percfisicaestimp perctributoimportado,
       pctribncmfilial.percentfisicaimportado perctributoimpfederal,
       pctribncmfilial.percfisicaestnac perctributoestadual,
       pctribncmfilial.percfisicamunicnac perctributomunicipal,
       
       (CASE
           WHEN NCMFILIAL.DTEXCLUSAO IS NULL THEN
                'S' 
           ELSE
                'N'
       END) ativo
FROM (SELECT DISTINCT 
        PCNCM.CODNCM,/*CODNCM É CADASTRADO SEM O "." */
        PCNCM.CODNCMEX,/*CODNCM DA PCNCM É CADASTRADO COM "." E JÁ POSSUI A EXCEÇÃO CASO EXISTA*/
        PCNCM.CODEX,
        PCNCM.DTEXCLUSAO,
        PCNCM.DTALTERC5,
        PCFILIAL.UF
     FROM PCNCM,
          PCFILIAL 
     WHERE PCFILIAL.CODIGO <> '99'
     AND   PCFILIAL.UF IS NOT NULL
     AND   PCNCM.CODNCMEX > 0
     )NCMFILIAL,
     
     (select min(s.ultimaexecucao) ultimaexecucao
      from pccontroleconsinco s
      where (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_CARGATRIBUTARIA')
     ) DTPADRAO,
             
     pctribncmfilial
          
WHERE NCMFILIAL.CODNCMEX =  PCTRIBNCMFILIAL.CODNCM(+) /*CODNCM DA PCTRIBNCMFILIAL É ALIMENTADO COM O CAMPO PCNCM.CODNCMEX*/
AND  NCMFILIAL.UF = (SELECT UF FROM PCFILIAL WHERE CODIGO = pctribncmfilial.codfilial)
AND  NVL(NCMFILIAL.DTALTERC5, DTPADRAO.ULTIMAEXECUCAO) >= DTPADRAO.ULTIMAEXECUCAO







