CREATE OR REPLACE VIEW VW_INT_C5_ESPECIE_FORMAPGTO AS
select especie,
       descricao,
       winthor
from    (SELECT 'D' especie, 'DINHEIRO' descricao, 'D' winthor FROM DUAL
     UNION
     SELECT 'B' especie, 'BOLETO' descricao, 'BK' winthor FROM DUAL
     UNION
     SELECT 'C' especie, 'CHEQUE' descricao, 'CHP' winthor FROM DUAL
     UNION
     SELECT 'C' especie, 'CHEQUE' descricao, 'CHV' winthor FROM DUAL
     UNION
     SELECT 'E' especie, 'CARTAO DE DEBITO' descricao, 'CTD' winthor
       FROM DUAL
     UNION
     SELECT 'N' especie, 'NOTA PROMISSORIA' descricao, 'NP' winthor
       FROM dual
     UNION
     SELECT 'R' especie, 'CARTAO DE CREDITO' descricao, 'CTC' winthor
       FROM DUAL
     UNION
     SELECT 'S' especie, 'POS' descricao, 'POS' winthor FROM DUAL
     UNION
     SELECT 'T' especie, 'TICKET PAPEL' descricao, 'TKT' winthor FROM DUAL
     UNION
     SELECT 'U' especie, 'VALE CREDITO' descricao, 'U' winthor FROM DUAL
     UNION
     SELECT 'V' especie, 'CONVENIO' descricao, 'CONV' winthor FROM DUAL
     UNION
     SELECT 'X' especie, 'VALE CREDITO' descricao, 'X' winthor FROM DUAL
     UNION
     SELECT 'I' especie, 'CREDITO FINANCEIRO' descricao, 'CRED' winthor
       FROM DUAL
     UNION
     SELECT 'G' especie, 'CARTEIRA DIGITAL' descricao, 'PIX' winthor FROM DUAL)

\

CREATE OR REPLACE VIEW VW_INT_C5_FORMAPAGTOEMPRESA AS
(
  SELECT 
    f.codfilial nroempresa,
    1 nrosegmento,
    f.codfinalizadora nroformapagto,
    0 percjuromensal,
    NVL(f.pertxfin, 0) perctaxaadm,
    LEAST(p.numdias, 999) nrodiasvencto,
    'N' solicitavencto,
    COALESCE(f.permitetroco, 'N') permitetroco,
    LEAST(NVL(f.vlminimo, 0), 999999) vlrminimo,
    LEAST(NVL(f.vlmaximo, 0), 999999) vlrmaximo,
    (CASE
      WHEN f.especie IN ('D', 'BK', 'CHV', 'CHP', 'CTD', 'CTC', 'CRE') THEN
      'S'
      WHEN f.especie LIKE 'POS%' THEN
      'S'
      ELSE
      'N'
    END) gerasangria,
    LEAST(o.prazomaximovenda, 999) prazomaximo,
    (CASE
      WHEN COALESCE(o.cartao, 'N') = 'S' THEN
      'S'
      ELSE
      'N'
    END) usatef,
    'S' TIPOCALCULOJUROS,
    NVL(o.permitecontravale, 'N') emitevaletroco,
    NVL(f.imprimevinculado, 'N') emitecomprovante,
    'S' abregaveta,
    'N' alternativa,
    'T' faturamento,
    NVL(f.codcobintegracao,f.codcob) codCob,
    (CASE
      WHEN f.dtinativacao IS NULL THEN
      'S'
      ELSE
      'N'
    END) ativo
  FROM VW_INT_C5_ESPECIE_FORMAPGTO vef,
      pcfilial e,
      pcfinalizadora   f,
      pccob            o,
      pcplpag          p,
      (
        SELECT s.ultimaexecucao
        FROM pccontroleconsinco s
        WHERE upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_FORMAPAGTOEMPRESA'
      ) D
    WHERE f.especie = vef.winthor(+)
    AND   F.CODFILIAL = E.codigo
    AND   f.codcob = o.codcob(+)
    AND   f.codplpag = p.codplpag(+)
    AND   f.codfilial IS NOT NULL
    and   f.codfinalizadora is not null
    AND   E.codigo >= '0'
    AND   E.codigo < '99'
    AND   LENGTH(TRIM(TRANSLATE(e.codigo, '0123456789',' '))) IS null
    AND  (NVL(f.dtalterc5, D.ultimaexecucao) >= D.ultimaexecucao OR
          NVL(o.dtalterc5, D.ultimaexecucao) >= D.ultimaexecucao or
          NVL(e.dtalterc5, D.ultimaexecucao) >= D.ultimaexecucao or
          NVL(p.dtalterc5, D.ultimaexecucao) >= D.ultimaexecucao)
) 