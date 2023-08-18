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
  FROM PCOFERTAPROGRAMADAI a, PCOFERTAPROGRAMADAC b, monitorpdvmiddle.tb_produto c,
  (SELECT S.ULTIMAEXECUCAO
        FROM PCCONTROLECONSINCO S
  WHERE UPPER(S.OBJETOREFERENCIA) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_REGRAPRODUTO') DATAPADRAO
  WHERE NVL(A.DTALTERC5, DATAPADRAO.ULTIMAEXECUCAO) >= DATAPADRAO.ULTIMAEXECUCAO
        AND a.codfilial = b.codfilial
        AND a.codoferta = b.codoferta
        AND c.seqproduto = a.codauxiliar||a.codfilial
)