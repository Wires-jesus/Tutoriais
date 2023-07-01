CREATE OR REPLACE VIEW VW_INT_C5_FINALIZADORA AS
(
SELECT  f.CODFINALIZADORA nroformapagto,
    (CASE
            WHEN f.especie = 'D'
                THEN 'D'
            WHEN f.especie = 'BK'
                THEN 'B'
            WHEN f.especie IN ('CHP','CHV')
                THEN 'C'
            WHEN f.especie = 'CTD'
                THEN 'E'
            WHEN f.especie IN ('CTC','DIG')
                THEN 'R'
            WHEN f.especie LIKE ('POS%')
                THEN 'S'
            WHEN f.especie = 'CNV'
                THEN 'V'
            WHEN f.especie IN ('CRED','CRED')
                THEN 'I'
            WHEN f.especie = 'PIX'
                THEN 'G'
            ELSE
                'D'
         END) ESPECIE ,
        f.DESCRICAO formapagto,
        (CASE
            WHEN f.dtinativacao IS NULL
                THEN 'S'
            ELSE
                'N'
         END) ativo,
        f.codcob,
        COALESCE(c.boleto,'N') boleto,
        GREATEST(NVL(f.dtultalter, d.datapadrao),
                NVL(f.dtcadastro, d.datapadrao),
                NVL(c.dtultalter, d.datapadrao),
                NVL(c.dtcadastro, d.datapadrao)) data
  FROM  VW_INT_C5_ESPECIE_FORMAPGTO vef,
        pcfinalizadora f,
        pccob c,
        (SELECT MIN(s.ultimaexecucao) datapadrao
          FROM pccontroleconsinco S
         where s.id >= 0) D
 WHERE  f.especie = vef.WINTHOR(+)
   AND  f.CODCOB = c.CODCOB(+)
   and  f.codfinalizadora >= 0
   and  f.codfilial >= '0'   )



