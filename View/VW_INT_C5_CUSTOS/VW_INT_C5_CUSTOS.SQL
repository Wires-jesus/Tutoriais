CREATE OR REPLACE VIEW VW_INT_C5_CUSTOS AS
(
SELECT  e.codfilial,
        e.codprod,
        e.codauxiliar,
        NVL(s.custoultent,0) vlcustoultent,
        NVL(s.custocont,0) vlcustocont,
        NVL(s.custoreal,0) vlcustoreal,
        NVL(s.custofin,0) vlcustofin,
        NVL(s.qtultent,0) qtultent,
        NVL(s.custorep,0) vlcustorep,
        NVL(s.valorultent,0) valorultent,
        NVL(s.vlbaseefet,0) vlbaseefet,
        NVL(s.vlicmsbcr,0) vlicmsbcr,
        NVL(s.vlicmsefet,0) vlicmsefet
  FROM  pcest    s,
        pcprodut p,
        pcembalagem e
 WHERE  e.codprod = p.codprod
   AND  e.codprod = s.codprod
   AND  e.codfilial = s.codfilial
)