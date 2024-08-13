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

\

CREATE OR REPLACE VIEW VW_INT_C5_FAT_RECARGACEL AS
(
SELECT  
        D.SEQDOCTO,
        D.NROEMPRESA,
        D.NROCHECKOUT,
        
        CASE
          WHEN D.ESPECIE = 'RP' THEN
               'R' 
          ELSE 'V' 
        END TIPOOPERACAO,

        CASE
          WHEN D.ESPECIE = 'RP' THEN
               'Recarga Celular '|| P.OPERADORA 
          ELSE 'Vale Gas '|| P.OPERADORA 
        END INFPRODUTO,

        CASE
          WHEN D.ESPECIE = 'RP' THEN
               NULL
          ELSE 137
        END CodOperRecargaCel,
        
        PG.NSUTEF,
        P.VALOR,
        TO_CHAR(P.DTAHOREMISSAO, 'YYYY-MM-DD') DTAHOREMISSAO,
        P.CODIGO,
        D.SEQUSUARIO,
        D.COO,
        P.OPERADORA
  FROM  MONITORPDVMIDDLE.TB_DOCTO D,
        MONITORPDVMIDDLE.TB_DOCTOPREPAGO P,
        MONITORPDVMIDDLE.TB_DOCTOPAGTO PG
 WHERE  D.SEQDOCTO = P.SEQDOCTO
 AND    D.NROEMPRESA = P.NROEMPRESA
 AND    D.NROCHECKOUT = P.NROCHECKOUT
 AND    D.SEQDOCTO = PG.SEQDOCTO
 AND    D.NROEMPRESA = PG.NROEMPRESA
 AND    D.NROCHECKOUT = PG.NROCHECKOUT
 AND    PG.SEQDOCTO = P.SEQDOCTO
 AND    PG.NROEMPRESA = P.NROEMPRESA
 AND    PG.NROCHECKOUT = P.NROCHECKOUT
  AND    D.ESPECIE IN ('RP', 'VG')
)

\

CREATE OR REPLACE VIEW VW_INT_C5_FAT_RECFATURA AS
(
SELECT  
        D.SEQDOCTO,
        D.NROEMPRESA,
        D.NROCHECKOUT,
        MAX(PG.NSUTEF) NSUTEF,
        SUM(PG.VLRTOTAL) VLRTOTAL,
        TO_CHAR(D.DTAHOREMISSAO, 'YYYY-MM-DD') DTAHOREMISSAO,
        D.SEQUSUARIO,
        D.COO,
        'C' ORIGEMFATURA,
        'E' STATUS,
        52 CODOPERRECARGACEL,
        'T'TIPOFATURA
 FROM  MONITORPDVMIDDLE.TB_DOCTO D,
       MONITORPDVMIDDLE.TB_DOCTOPAGTO PG
 WHERE  D.SEQDOCTO = PG.SEQDOCTO
 AND    D.NROEMPRESA = PG.NROEMPRESA
 AND    D.NROCHECKOUT = PG.NROCHECKOUT
 AND    D.ESPECIE IN ('PL')
 GROUP BY 
        D.SEQDOCTO,
        D.NROEMPRESA,
        D.NROCHECKOUT,
        D.SEQUSUARIO,
        D.DTAHOREMISSAO,
        D.COO
)