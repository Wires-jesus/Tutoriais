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
  (SELECT S.ULTIMAEXECUCAO
          FROM PCCONTROLECONSINCO S
    WHERE UPPER(S.OBJETOREFERENCIA) = 'PKG_SINC_PDV_CONSINCO.CARREGA_TB_REGRAINCENTIVO') DATAPADRAO
  WHERE NVL(A.DTALTERC5, DATAPADRAO.ULTIMAEXECUCAO) >= DATAPADRAO.ULTIMAEXECUCAO
);
