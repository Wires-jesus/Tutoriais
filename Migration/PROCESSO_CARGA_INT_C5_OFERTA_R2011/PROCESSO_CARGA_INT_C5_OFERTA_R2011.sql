CREATE OR REPLACE VIEW VW_INT_C5_OFERTA_R2011 AS
(
select codfilial||2011||codoferta as SEQREGRA,
       descoferta                  as regra,
       3                           as SEQTIPOCREDITO,
       (CASE
          WHEN (DTCANCEL IS NOT NULL) OR (DTFINAL < TRUNC(SYSDATE))  THEN 'N'
          ELSE 'S'
          END)                     as ativo,
       'G'                         as tiporegra,
       'S'                         as cumulativo,
       DTINICIAL                   as dtahorinicio,
       DTFINAL                     as dtahorfim,
       '2011'                      as IDREF
  from PCOFERTAPROGRAMADAC A,
  (select min(s.ultimaexecucao) ultimaexecucao
        from pccontroleconsinco s
        where (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_REGRAINCENTIVO')
           or (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_REGRAINCENTPERIODO')
 ) DATAPADRAO
  WHERE NVL(A.DTALTERC5, DATAPADRAO.ULTIMAEXECUCAO) >= DATAPADRAO.ULTIMAEXECUCAO
       AND DTFINAL >= TRUNC(SYSDATE)
       AND a.dtinicial IS NOT NULL
       AND a.dtfinal IS NOT NULL
)

\

CREATE OR REPLACE VIEW VW_INT_C5_PRODUTO_R2011 AS
(
SELECT DISTINCT a.codauxiliar              as SEQPRODUTO,
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
  AND NVL(A.DTALTERC5, DTPADRAO.ULTIMAEXECUCAO) >= DTPADRAO.ULTIMAEXECUCAO
  AND C.SEQPRODUTO = A.CODAUXILIAR
  AND C.SEQPRODUTO = E.CODAUXILIAR
  AND D.SEQREGRA = A.CODFILIAL||2011||A.CODOFERTA
  AND B.dtinicial IS NOT NULL
  AND B.dtfinal IS NOT NULL
  AND TRUNC(SYSDATE) BETWEEN B.DTINICIAL AND B.DTFINAL
UNION
SELECT DISTINCT
       OFERTA_HIST.CODAUXILIAR      as SEQPRODUTO,
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
        monitorpdvmiddle.tb_produto C,
        monitorpdvmiddle.tb_regraincentivo D,

        (select min(s.ultimaexecucao) ultimaexecucao
         from pccontroleconsinco s
         where (upper(s.objetoreferencia) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_REGRAPRODUTO')
        )DTPADRAO
  WHERE  E.CODFILIAL = OFERTA_HIST.CODFILIAL
  AND    E.CODAUXILIAR = OFERTA_HIST.CODAUXILIAR
  AND    E.CODPROD =  OFERTA_HIST.CODPROD
  AND    C.SEQPRODUTO = OFERTA_HIST.CODAUXILIAR
  AND    C.SEQPRODUTO = E.CODAUXILIAR
  AND    D.SEQREGRA = OFERTA_HIST.CODFILIAL||2011||OFERTA_HIST.CODOFERTA
  AND    OFERTA_HIST.DATAEXCLUSAO IS NOT NULL
  AND    NOT EXISTS(SELECT O.CODOFERTA, O.CODAUXILIAR
                    FROM PCOFERTAPROGRAMADAI O
                    WHERE O.CODOFERTA = OFERTA_HIST.CODOFERTA
                    AND   O.CODAUXILIAR = OFERTA_HIST.CODAUXILIAR
                    AND   O.CODFILIAL = OFERTA_HIST.CODFILIAL)
  AND    NVL(OFERTA_HIST.DTALTERC5, DTPADRAO.ULTIMAEXECUCAO) >= DTPADRAO.ULTIMAEXECUCAO
  GROUP BY OFERTA_HIST.CODAUXILIAR,
           OFERTA_HIST.CODFILIAL||2011||OFERTA_HIST.CODOFERTA,
           E.QTUNIT
)
