CREATE OR REPLACE VIEW VW_INT_C5_FAT_INUT AS
(
SELECT a.nroempresa codfilial,
       b.dtamovimento datatransacao,
       b.nrocheckout
 FROM monitorpdvmiddle.tb_doctoinutnfe a,
      monitorpdvmiddle.tb_docto b
 WHERE  a.nroempresa = b.nroempresa
   AND  a.nrocheckout = b.nrocheckout
   AND  a.seqdocto = b.seqdocto
   )

\

CREATE OR REPLACE VIEW VW_INT_C5_FAT_VALES AS
(
SELECT a.nroempresa codfilial,
       a.dtamovimento datatransacao,
       a.ESPECIE status,
       a.NROCHECKOUT,
       a.seqdocto
  FROM  monitorpdvmiddle.tb_docto a,
        monitorpdvmiddle.tb_doctopagto b
 WHERE  a.nroempresa = b.nroempresa
   AND  a.nrocheckout = b.nrocheckout
   AND  a.seqdocto = b.seqdocto
   AND  a.especie IN ('SG','SP')
  -- AND  a.replicacao = 'F'
)

\

create or replace view vw_int_c5_fat_vendas as
(
select  c.nroempresa codfilial,
		 m.dtahoremissao datatransacao,
		 c.status,
		 m.NROCHECKOUT,
		 c.seqdocto
  from monitorpdvmiddle.tb_docto      m,
       monitorpdvmiddle.tb_doctocupom c, 
       monitorpdvmiddle.tb_doctonfe    e
 where m.seqdocto = c.seqdocto
   and m.nroempresa =  c.nroempresa
   and m.NROCHECKOUT = c.NROCHECKOUT
   AND e.nroempresa = c.nroempresa
   and e.nrocheckout = c.nrocheckout
   and e.seqdocto = c.seqdocto
   and e.protocoloenvio is not null
   AND not exists (select 1
                     from monitorpdvmiddle.tb_doctoinutnfe i
					where i.seqdocto = m.seqdocto
                      and i.nrocheckout = m.nrocheckout
                      and i.nroempresa = m.nroempresa
                      and i.nronotafiscal = c.nronotafiscal)
   AND M.ESPECIE IN ('NF', 'CF')
)
 
 \
 
CREATE OR REPLACE VIEW VW_PDV_MONITOR AS
(
SELECT P.NUMCAIXA,
     P.DTINICIO,
     P.CODFILIAL,
     DESCRICAO,
     TIPOIMPRESSORA,
     NUMSERIEEQUIP,
     NUMREGIAO,
     NUMCAIXAFISCAL
  FROM PCCAIXA P, VW_INT_C5_OBTER_FILIAIS_C5 C5
  WHERE 0 = 0
    AND UPPER(P.NOMEPDV) = 'PDV SUPER'
  AND P.CODFILIAL = C5.CODFILIAL
  AND P.DTFIM IS NULL
)

\

CREATE OR REPLACE VIEW VW_INT_C5_FAT_CANCELAMENTO AS
(
select  c.nroempresa codfilial,
		 m.dtahoremissao datatransacao,
		 c.status,
		 m.NROCHECKOUT,
		 c.seqdocto
  from monitorpdvmiddle.tb_docto      m,
       monitorpdvmiddle.tb_doctocupom c, 
       monitorpdvmiddle.tb_doctonfe    e
 where m.seqdocto = c.seqdocto
   and m.nroempresa =  c.nroempresa
   and m.NROCHECKOUT = c.NROCHECKOUT
   AND e.nroempresa = c.nroempresa
   and e.nrocheckout = c.nrocheckout
   and e.seqdocto = c.seqdocto
   and e.protocoloenvio is not null
   and e.protocolocancelamento is not null
   AND M.ESPECIE IN ('NF', 'CF')
)