CREATE OR REPLACE VIEW VW_INT_C5_FAT_INUT AS(
SELECT a.nroempresa codfilial,
       b.dtamovimento datatransacao,
       b.nrocheckout
 FROM monitorpdvmiddle.tb_doctoinutnfe a,
      monitorpdvmiddle.tb_docto b
 WHERE  a.nroempresa = b.nroempresa
   AND  a.nrocheckout = b.nrocheckout
   AND  a.seqdocto = b.seqdocto
   AND  b.replicacao = 'F')

\

CREATE OR REPLACE VIEW VW_INT_C5_FAT_VALES AS
(
SELECT a.nroempresa codfilial,
       a.dtamovimento datatransacao,
       a.ESPECIE status,
       a.NROCHECKOUT,
       a.seqdocto,
       'INTERMEDIARIO' usuario,
       'INTERMEDIARIO' senha,
       ferramentas.F_BUSCARPARAMETRO_ALFA('IPFTPFATURAMENTO', a.nroempresa, 1) endereco
  FROM  monitorpdvmiddle.tb_docto a,
        monitorpdvmiddle.tb_doctopagto b
 WHERE  a.nroempresa = b.nroempresa
   AND  a.nrocheckout = b.nrocheckout
   AND  a.seqdocto = b.seqdocto
   AND  a.especie IN ('SG','SP')
   AND  a.replicacao = 'F')


\

create or replace view VW_INT_C5_FAT_VENDAS as
(select  c.nroempresa codfilial, m.dtahoremissao datatransacao, c.status, m.NROCHECKOUT , c.seqdocto,
        'INTERMEDIARIO' usuario,'INTERMEDIARIO' senha, ferramentas.F_BUSCARPARAMETRO_ALFA('IPFTPFATURAMENTO',m.nroempresa,1) endereco
  from monitorpdvmiddle.tb_docto      m,
       monitorpdvmiddle.tb_doctocupom c
 where m.seqdocto = c.seqdocto
   and m.nroempresa =  c.nroempresa
   and m.NROCHECKOUT = c.NROCHECKOUT
   and m.replicacao = 'F')
