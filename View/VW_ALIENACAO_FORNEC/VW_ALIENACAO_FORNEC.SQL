CREATE OR REPLACE VIEW VW_ALIENACAO_FORNEC AS
SELECT pcprodut.codprod,
       pcprodut.codprodprinc,
       pcprodut.codfornec,
       pcprodut.codepto,
       pcprodut.codsec,
       pcprodut.pesoliq,
       nvl(TRUNC(TO_NUMBER(REPLACE(alienafornec.alienacao,',','.')),6),1) fator
FROM (SELECT refwinthor, alienacao FROM pcalienafornec WHERE categoria = 14) alienafornec, pcprodut
WHERE alienafornec.refwinthor(+) = pcprodut.codprod
