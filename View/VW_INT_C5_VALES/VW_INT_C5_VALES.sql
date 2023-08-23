CREATE OR REPLACE VIEW VW_INT_C5_VALES AS
(
SELECT  FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CODBANCOINTEGRACAOPDV',A.NROEMPRESA,0) CODBANCO,
        TO_CHAR(A.DTAHORINCLUSAO,'YYYY-MM-DD') DTLANC,
        A.NROCHECKOUT NUMCAIXA,
        TO_CHAR(A.DTAHORINCLUSAO,'YYYY-MM-DD') DTMOVIMENTOCX,
        A.SEQTURNO NUMFECHAMENTOMOVCX,
        A.ESPECIE,
        (CASE
            WHEN B.VALOR < 0
                THEN B.VALOR * -1
            ELSE
                B.VALOR
          END) VALOR,
        NVL((CASE
                 WHEN B.MOEDA = 'DINHEIRO'
                      THEN 'D'
                 ELSE
                     B.MOEDA
              END),'D') CODCOB,
        A.SEQDOCTO,
        A.SEQDOCTO || '-' || A.NROCHECKOUT || '-' || A.ESPECIE IDEXTERNO,
        0 NUMVALE,
        (CASE
             WHEN A.ESPECIE = 'SG'
               THEN       'SANGRIA ROTINA: CONSINCO - NUMCAIXA: '
                          || A.NROCHECKOUT
                          || ' - NUMSERIEEQUIP: NOTAFISCAL - CODOPERADORCX: '
                          || A.SEQUSUARIO
                          || ' - CODFISCALCX: '
                          || A.SEQUSUARIO
             WHEN A.ESPECIE = 'SP'
               THEN
                          'SUPRIMENTO ROTINA: CONSINCO - NUMCAIXA: '
                          || A.NROCHECKOUT
                          || ' - NUMSERIEEQUIP: NOTAFISCAL - CODOPERADORCX: '
                          || A.SEQUSUARIO
                          || ' - CODFISCALCX: '
                          || A.SEQUSUARIO
          END) HISTORICO,
        A.SEQUSUARIO CODFUNC,
        (CASE
            WHEN A.ESPECIE = 'SG'
                THEN 'A'
            WHEN A.ESPECIE = 'SP'
                THEN 'U'
            ELSE
              NULL
          END) TIPO,
        A.NROEMPRESA CODFILIAL,
        A.ROWID ROWID_TB_DOCTO
  FROM  MONITORPDVMIDDLE.TB_DOCTO A,
        MONITORPDVMIDDLE.TB_DOCTOPAGTO B
 WHERE  A.NROEMPRESA = B.NROEMPRESA
   AND  A.SEQDOCTO = B.SEQDOCTO
   AND  A.NROCHECKOUT = B.NROCHECKOUT
   AND  A.SEQDOCTO = B.SEQDOCTO
   AND  A.ESPECIE IN ('SG','SP')
   AND  A.REPLICACAO = 'P'
)
