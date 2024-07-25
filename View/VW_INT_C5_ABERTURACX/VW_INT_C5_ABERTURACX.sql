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
		(CASE WHEN a.Especie IN ('FC','FM') THEN
            (SELECT to_char(b.dtahorinclusao,'hh24') HORAABERTURA 
              FROM monitorpdvmiddle.tb_docto b
             where b.nroempresa = a.nroempresa
               and b.nrocheckout = a.nrocheckout
               and b.dtamovimento = a.dtamovimento
               and b.seqturno = a.seqturno
			   and b.sequsuario = a.sequsuario
               and b.especie = 'AC'
			   and rownum = 1)
          ELSE
             NULL
          END) HORAABERTURA,
        (CASE WHEN a.Especie IN ('FC','FM') THEN
            (SELECT to_char(b.dtahorinclusao,'mi') MINUTOABERTURA 
              FROM monitorpdvmiddle.tb_docto b
             where b.nroempresa = a.nroempresa
               and b.nrocheckout = a.nrocheckout
               and b.dtamovimento = a.dtamovimento
               and b.seqturno = a.seqturno
			   and b.sequsuario = a.sequsuario
               and b.especie = 'AC'
			   and rownum = 1)
          ELSE
             NULL
          END) MINUTOABERTURA,
        (CASE WHEN a.Especie IN ('FC','FM') THEN
             trunc(a.dtahorinclusao)
          ELSE
             NULL
          END) DTFECHAMENTO,
        (CASE WHEN a.Especie IN ('FC','FM') THEN
            to_char(a.dtahorinclusao,'hh24') 
          ELSE
             NULL
          END) HORAFECHAMENTO,
        (CASE WHEN a.Especie IN ('FC','FM') THEN
             to_char(a.dtahorinclusao,'mi')
          ELSE
             NULL
          END) MINUTOFECHAMENTO,
        a.ROWID rowid_tb_docto,
		a.nrocheckout
  FROM  monitorpdvmiddle.tb_docto a
 WHERE  a.replicacao = 'P'
   AND  a.especie IN ('AC','CX','FC','FM')
)
