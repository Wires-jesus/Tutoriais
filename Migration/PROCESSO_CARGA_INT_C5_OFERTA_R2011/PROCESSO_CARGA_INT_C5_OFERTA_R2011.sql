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
       AND a.dtinicial IS NOT NULL
       AND a.dtfinal IS NOT NULL
)

\

CREATE OR REPLACE VIEW VW_INT_C5_PRODUTO_R2011 AS
(

 SELECT  a.codauxiliar||a.codfilial as SEQPRODUTO,
         descoferta                   as regra,
         a.qtmaxvenda                 as QTDEMBALAGEM,
         a.codfilial||2011||a.codoferta  SEQREGRA,
         0 PERCDESCONTO,
         vloferta PRECO,
         (CASE
          WHEN (b.DTCANCEL IS NOT NULL) OR (b.DTFINAL < TRUNC(SYSDATE))  THEN 'N'
          ELSE 'S'
          END)                         as  ATIVO,
        'G'                            as tiporegra,
        'S'                            as cumulativo,
         3                             as SEQTIPOCREDITO
  FROM PCOFERTAPROGRAMADAI a, PCOFERTAPROGRAMADAC b, monitorpdvmiddle.tb_produto c, monitorpdvmiddle.tb_regraincentivo d,
  (SELECT S.ULTIMAEXECUCAO
        FROM PCCONTROLECONSINCO S
  WHERE UPPER(S.OBJETOREFERENCIA) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_REGRAPRODUTO') DATAPADRAO
  WHERE NVL(A.DTALTERC5, DATAPADRAO.ULTIMAEXECUCAO) >= DATAPADRAO.ULTIMAEXECUCAO
        AND a.codfilial = b.codfilial
        AND a.codoferta = b.codoferta
        AND c.seqproduto = a.codauxiliar||a.codfilial
        AND d.seqregra = a.codfilial||2011||a.codoferta
        AND b.dtinicial IS NOT NULL
        AND b.dtfinal IS NOT NULL
)
