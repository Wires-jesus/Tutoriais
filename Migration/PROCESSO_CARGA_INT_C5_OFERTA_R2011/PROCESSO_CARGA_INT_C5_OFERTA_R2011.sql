CREATE OR REPLACE VIEW VW_INT_C5_OFERTA_R2011 AS
(
SELECT
      CODFILIAL||2011||CODOFERTA  AS SEQREGRA,
      CODFILIAL                   AS NROEMPRESA,
      DESCOFERTA                  AS REGRA,
      3                           AS SEQTIPOCREDITO,
      (CASE
         WHEN (DTCANCEL IS NOT NULL) OR (DTFINAL < TRUNC(SYSDATE))  THEN 'N'
         ELSE 'S'
         END)                     AS ATIVO,
      'G'                         AS TIPOREGRA,
      'S'                         AS CUMULATIVO,
      (CASE
         WHEN HORAINICIAL IS NOT NULL THEN
            HORAINICIAL
         ELSE
            DTINICIAL
      END)                        AS DTAHORINICIO,
      (CASE 
         WHEN HORAFINAL IS NOT NULL THEN
            HORAFINAL
          ELSE
            DTFINAL
      END)                         AS DTAHORFIM,
       '2011'                      AS IDREF
  FROM PCOFERTAPROGRAMADAC A,
  (SELECT MIN(S.ULTIMAEXECUCAO) ULTIMAEXECUCAO
        FROM PCCONTROLECONSINCO S
        WHERE (UPPER(S.OBJETOREFERENCIA) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_REGRAINCENTIVO')
           OR (UPPER(S.OBJETOREFERENCIA) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_REGRAEMPRESA') 
           OR (UPPER(S.OBJETOREFERENCIA) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_REGRASEGMENTO') 
           OR (UPPER(S.OBJETOREFERENCIA) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_REGRAINCENTPERIODO')
 ) DATAPADRAO
  WHERE NVL(A.DTALTERC5, DATAPADRAO.ULTIMAEXECUCAO) >= DATAPADRAO.ULTIMAEXECUCAO
       AND DTFINAL >= TRUNC(SYSDATE)
       AND A.DTINICIAL IS NOT NULL
       AND A.DTFINAL IS NOT NULL
)

\

CREATE OR REPLACE VIEW VW_INT_C5_PRODUTO_R2011 AS
(
SELECT DISTINCT 
         --ora_hash(a.codauxiliar, 2147483647) seqproduto,
         a.codauxiliar,
         P.SEQPRODUTO SEQPRODUTO,
         descoferta                        as regra,
         e.qtunit                          as QTDEMBALAGEM,
         a.codfilial||2011||a.codoferta    as SEQREGRA,
         0 PERCDESCONTO,
         a.vloferta                        as PRECO,
         (CASE
          WHEN (b.DTCANCEL IS NOT NULL) OR (b.DTFINAL < TRUNC(SYSDATE))  THEN 'N'
          ELSE 'S'
          END)                          as  ATIVO,
         'G'                            as tiporegra,
         'S'                            as cumulativo,
          3                             as SEQTIPOCREDITO,
          '2011'                        as IDREF
  FROM PCOFERTAPROGRAMADAI A,
       PCOFERTAPROGRAMADAC B,
       PCEMBALAGEM E,
       PCDEPARAEMBALAGENSC5 P,
       monitorpdvmiddle.tb_produto C,
       monitorpdvmiddle.tb_regraincentivo D,

  (select min(s.ultimaexecucao) ultimaexecucao
          from pccontroleconsinco s
    where (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_REGRAPRODUTO')
  )DTPADRAO
  WHERE A.CODOFERTA = B.CODOFERTA
  AND A.CODFILIAL = B.CODFILIAL
  AND A.CODFILIAL = E.CODFILIAL
  AND A.CODAUXILIAR = E.CODAUXILIAR
  --AND C.SEQPRODUTO = A.CODAUXILIAR
  --AND C.SEQPRODUTO = E.CODAUXILIAR
  --AND C.SEQPRODUTO = ora_hash(a.codauxiliar, 2147483647)
  AND A.CODAUXILIAR = P.CODAUXILIAR
  AND E.CODAUXILIAR = P.CODAUXILIAR
  AND C.SEQPRODUTO  = P.SEQPRODUTO 
  AND D.SEQREGRA = A.CODFILIAL||2011||A.CODOFERTA
  AND B.dtinicial IS NOT NULL
  AND B.dtfinal IS NOT NULL
  AND TRUNC(SYSDATE) BETWEEN B.DTINICIAL AND B.DTFINAL
  AND NVL(A.DTALTERC5, DTPADRAO.ULTIMAEXECUCAO) >= DTPADRAO.ULTIMAEXECUCAO
UNION
SELECT DISTINCT
       --ora_hash(OFERTA_HIST.codauxiliar, 2147483647) seqproduto,
       OFERTA_HIST.codauxiliar,
       P.SEQPRODUTO SEQPRODUTO,
       'ITEM EXCLUIDO DA OFERTA'    as regra,
       E.QTUNIT                     as QTDEMBALAGEM,
       OFERTA_HIST.CODFILIAL||2011||OFERTA_HIST.CODOFERTA  SEQREGRA,
       0 PERCDESCONTO,
       MAX(OFERTA_HIST.VLOFERTA)     as PRECO,
       'N'                           as  ATIVO,
       'G'                           as tiporegra,
       'S'                           as cumulativo,
        3                            as SEQTIPOCREDITO,
        '2011'                       as IDREF
  FROM  PCEMBALAGEM E,
        PCOFERTAPROGRAMADAI_HIST OFERTA_HIST,
        PCDEPARAEMBALAGENSC5 P,
        monitorpdvmiddle.tb_produto C,
        monitorpdvmiddle.tb_regraincentivo D,

        (select min(s.ultimaexecucao) ultimaexecucao
         from pccontroleconsinco s
         where (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_REGRAPRODUTO')
        )DTPADRAO
  WHERE  E.CODFILIAL = OFERTA_HIST.CODFILIAL
  AND    E.CODAUXILIAR = OFERTA_HIST.CODAUXILIAR
  AND    E.CODPROD =  OFERTA_HIST.CODPROD
  --AND    C.SEQPRODUTO = OFERTA_HIST.CODAUXILIAR
  --AND    C.SEQPRODUTO = E.CODAUXILIAR
  --AND    C.SEQPRODUTO = ora_hash(OFERTA_HIST.codauxiliar, 2147483647) 
  AND    E.CODAUXILIAR = P.CODAUXILIAR
  AND    OFERTA_HIST.CODAUXILIAR = P.CODAUXILIAR
  AND    C.SEQPRODUTO = P.SEQPRODUTO
  AND    D.SEQREGRA = OFERTA_HIST.CODFILIAL||2011||OFERTA_HIST.CODOFERTA
  AND    OFERTA_HIST.DATAEXCLUSAO IS NOT NULL
  AND    NOT EXISTS(SELECT O.CODOFERTA, O.CODAUXILIAR
                    FROM PCOFERTAPROGRAMADAI O
                    WHERE O.CODOFERTA = OFERTA_HIST.CODOFERTA
                    AND   O.CODAUXILIAR = OFERTA_HIST.CODAUXILIAR
                    AND   O.CODFILIAL = OFERTA_HIST.CODFILIAL)
  AND    NVL(OFERTA_HIST.DTALTERC5, DTPADRAO.ULTIMAEXECUCAO) >= DTPADRAO.ULTIMAEXECUCAO
  GROUP BY OFERTA_HIST.CODAUXILIAR,
           P.SEQPRODUTO,
           OFERTA_HIST.CODFILIAL||2011||OFERTA_HIST.CODOFERTA,
           E.QTUNIT
)
