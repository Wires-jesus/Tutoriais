CREATE OR REPLACE VIEW vw_int_c5_finalizadora
AS
(
    SELECT  
        f.codfilial,
        f.codfinalizadora nroformapagto,
        substr(f.descricao,1,40) formapagto,
        (CASE
            WHEN f.especie = 'BK'
            THEN 'B'
            WHEN f.especie IN ('CHP','CHV')
            THEN 'C'
            WHEN f.especie IN ('CTC','DIG')
            THEN 'R'
            WHEN f.especie = 'CTD'
            THEN 'E'
            WHEN f.especie IN ('CNV','CONV')
            THEN 'V'
            WHEN f.especie = 'CRED'
            THEN 'I'
            WHEN f.especie = 'D'
            THEN 'D'
            WHEN f.especie = 'PIX'
            THEN 'G'
            WHEN f.especie LIKE 'POS%'
            THEN 'S'
            ELSE 'S'
        END) especie,
        NVL(c.boleto,'N') boleto,
        (CASE
            WHEN f.dtinativacao IS NULL 
            THEN 'S'
            ELSE 'N'
        END) ativo,
        NVL(f.codcobintegracao,f.codcob) codcob,
        NVL(f.codplpagintegracao,f.codplpag)codplpag,
        GREATEST(NVL(f.dtalterc5,d.datapadrao),
        NVL(c.dtalterc5,d.datapadrao)) data
    FROM  vw_int_c5_especie_formapgto vef,
        pcfinalizadora f,
        pccob c,
        (SELECT MIN(s.ultimaexecucao) datapadrao FROM pccontroleconsinco s WHERE s.id >= 0) d
    WHERE  f.especie = vef.winthor(+)
        AND  NVL(f.codcobintegracao,f.codcob) = c.codcob(+)
        AND  f.codfinalizadora >= 0
)