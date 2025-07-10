CREATE OR REPLACE VIEW VW_INT_C5_GIFTCARD AS
(
SELECT  A.SEQDOCTO,
        A.NROEMPRESA,
        A.NROCHECKOUT,
        A.NROCHECKOUT NUMCAIXA,
        C.NROCARTAO NUMGIFTCARD,
        'NOTAFISCAL' NUMSERIEEQUIP,
        TO_CHAR(A.DTAMOVIMENTO, 'YYYY-MM-DD') DATA,
        TO_CHAR(A.DTAMOVIMENTO, 'YYYY-MM-DD') DTABERTURA,
        TO_CHAR(A.DTAMOVIMENTO, 'YYYY-MM-DD') DTMOVIMENTOCX,
        A.SEQUSUARIO CODFUNCCX,
        NVL(C.SEQPESSOA, 1) CODCLI,
        C.VLRCREDITO VALOR,
        A.COO NUMCOO,
        FNC_INT_C5_CODUSUR(A.SEQUSUARIO) CODUSUR,
		0 NUMFECHAMENTOMOVCX 
  FROM  MONITORPDVMIDDLE.TB_DOCTO A, ( SELECT P.SEQDOCTO,
                                              P.NROCHECKOUT,
                                              P.NROEMPRESA,
                                              P.NROCARTAO,
                                              P.NROCREDITOCUPOM,
                                              COUNT(1) NUMPRESTS
                                         FROM MONITORPDVMIDDLE.TB_DOCTOPAGTO P,
                                              MONITORPDVMIDDLE.TB_DOCTO D
                                         WHERE P.SEQDOCTO = D.SEQDOCTO
                                         AND P.NROEMPRESA = D.NROEMPRESA
                                         AND P.NROCHECKOUT = D.NROCHECKOUT
                                         AND D.ESPECIE = 'VC'
                                         AND D.REPLICACAO = 'P'
                                         AND P.NROCREDITOCUPOM IS NOT NULL
                                         GROUP BY P.SEQDOCTO,
                                              P.NROCHECKOUT,
                                              P.NROEMPRESA,
                                              P.NROCARTAO,
                                              P.NROCREDITOCUPOM) B, MONITORPDVMIDDLE.TB_DOCTOCREDITOCUPOM C 
 WHERE  1 = 1
   AND  A.REPLICACAO = 'P'
   AND  A.SEQDOCTO = B.SEQDOCTO
   AND  A.NROEMPRESA = B.NROEMPRESA
   AND  A.NROCHECKOUT = B.NROCHECKOUT
   AND  B.NROCREDITOCUPOM = C.NROCREDITOCUPOM
   AND  A.ESPECIE IN ('VC')
)