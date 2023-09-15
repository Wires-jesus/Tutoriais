CREATE OR REPLACE VIEW VW_INT_C5_ABERTURACX AS
(
SELECT a.nrocheckout numcaixa,
        a.sequsuario codfunccxatual,
        TO_CHAR(a.dtamovimento, 'YYYY-MM-DD') dtabertura,
        a.seqturno,
        a.nroempresa,
        a.seqdocto,
        a.especie,
        0 numnota,
        0 valor,
        1 codcli,
        a.ROWID rowid_tb_docto
  FROM  monitorpdvmiddle.tb_docto a
 WHERE  a.replicacao = 'P'
   AND  a.especie IN ('AC','CX','FC','FM')
)
