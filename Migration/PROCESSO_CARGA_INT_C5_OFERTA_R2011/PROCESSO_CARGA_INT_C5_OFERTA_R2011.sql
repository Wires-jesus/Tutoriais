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
       DTFINAL                     as dtahorfim
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

  SELECT DISTINCT a.codauxiliar||a.codfilial   as SEQPRODUTO,
         descoferta                   as regra,
         e.qtunit                     as QTDEMBALAGEM,
         a.codfilial||2011||a.codoferta  SEQREGRA,
         0 PERCDESCONTO,
         a.vloferta PRECO,
         (CASE
          WHEN (b.DTCANCEL IS NOT NULL) OR (b.DTFINAL < TRUNC(SYSDATE))  THEN 'N'
          ELSE 'S'
          END)                         as  ATIVO,
         'G'                            as tiporegra,
         'S'                            as cumulativo,
          3                             as SEQTIPOCREDITO
  FROM PCOFERTAPROGRAMADAI a, PCOFERTAPROGRAMADAC b, monitorpdvmiddle.tb_produto c, monitorpdvmiddle.tb_regraincentivo d,
  pcembalagem e, pcofertaprogramadai_hist oferta_hist
  WHERE a.codfilial = b.codfilial
        AND a.codoferta = b.codoferta
        AND c.seqproduto = a.codauxiliar||a.codfilial
        AND d.seqregra = a.codfilial||2011||a.codoferta
        AND b.dtinicial IS NOT NULL
        AND b.dtfinal IS NOT NULL
        AND e.codprod = NVL(a.codprod, oferta_hist.codprod)
        AND oferta_hist.codfilial = a.codfilial
UNION 
SELECT DISTINCT oferta_hist.codauxiliar||oferta_hist.codfilial as SEQPRODUTO,
         descoferta                   as regra,
         e.qtunit                     as QTDEMBALAGEM,
         oferta_hist.codfilial||2011||oferta_hist.codoferta  SEQREGRA,
         0 PERCDESCONTO,
         oferta_hist.vloferta PRECO,
         'N'                           as  ATIVO,
        'G'                            as tiporegra,
        'S'                            as cumulativo,
         3                             as SEQTIPOCREDITO
  FROM  PCOFERTAPROGRAMADAC b, monitorpdvmiddle.tb_produto c, monitorpdvmiddle.tb_regraincentivo d,
  pcembalagem e, pcofertaprogramadai_hist oferta_hist
  WHERE  oferta_hist.codfilial = b.codfilial 
        AND oferta_hist.Codoferta = b.codoferta
        AND c.seqproduto = oferta_hist.codauxiliar||oferta_hist.codfilial
        AND d.seqregra = oferta_hist.codfilial||2011||oferta_hist.codoferta
        AND b.dtinicial IS NOT NULL
        AND b.dtfinal IS NOT NULL
        AND e.codprod =  oferta_hist.codprod
        AND e.codfilial = oferta_hist.codfilial
        AND oferta_hist.codprod IN ( 
        select codprod from pcofertaprogramadai_hist
        where codoferta||codprod not in (select codoferta||codprod from PCOFERTAPROGRAMADAI)) 
)
