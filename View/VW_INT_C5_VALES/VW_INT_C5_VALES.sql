CREATE OR REPLACE VIEW VW_INT_C5_VALES AS
(
SELECT  ferramentas.f_buscarparametro_num('CODBANCOINTEGRACAOPDV',a.nroempresa,0) codbanco,
        TO_CHAR(a.dtahoremissao,'YYYY-MM-DD') dtlanc,
        a.nrocheckout numcaixa,
        TO_CHAR(a.dtahoremissao,'YYYY-MM-DD') dtmovimentocx,
        a.seqturno numfechamentomovcx,
        a.especie,
        'NOTAFISCAL' numserieequip,
        (CASE
            WHEN b.valor < 0
                THEN b.valor * -1
            ELSE
                b.valor
          END) valor,
        NVL((CASE
                 WHEN b.moeda = 'DINHEIRO'
                      THEN 'D'
                 ELSE
                     b.moeda
              END),'D') codcob,
        a.seqdocto,
        a.seqdocto || '-' || a.nrocheckout || '-' || a.especie idexterno,
        0 numvale,
        (CASE
             WHEN a.especie = 'SG'
               THEN       'SANGRIA ROTINA: CONSINCO - NUMCAIXA: '
                          || a.nrocheckout
                          || ' - NUMSERIEEQUIP: NotaFiscal - CODOPERADORCX: '
                          || a.sequsuario
                          || ' - CODFISCALCX: '
                          || a.sequsuario
             WHEN a.especie = 'SP'
               THEN
                          'SUPRIMENTO ROTINA: CONSINCO - NUMCAIXA: '
                          || a.nrocheckout
                          || ' - NUMSERIEEQUIP: NotaFiscal - CODOPERADORCX: '
                          || a.sequsuario
                          || ' - CODFISCALCX: '
                          || a.sequsuario
          END) historico,
        a.sequsuario codfunc,
        (CASE
            WHEN a.especie = 'SG'
                THEN 'A'
            WHEN a.especie = 'SP'
                THEN 'U'
            ELSE
              NULL
          END) tipo,
        c5.codfilial codfilial,
        a.ROWID rowid_tb_docto
  FROM  monitorpdvmiddle.tb_docto a,
        monitorpdvmiddle.tb_doctopagto b,
		VW_INT_C5_OBTER_FILIAIS_C5 C5
 WHERE  a.nroempresa = b.nroempresa
   AND  a.seqdocto = b.seqdocto
   AND  a.nrocheckout = b.nrocheckout
   AND  a.seqdocto = b.seqdocto
   AND  a.especie IN ('SG','SP')
   AND  a.replicacao = 'P'
   AND  C5.CODFILIALINTEGRACAO = a.nroempresa
   AND  C5.CODFILIALINTEGRACAO = b.nroempresa
)
