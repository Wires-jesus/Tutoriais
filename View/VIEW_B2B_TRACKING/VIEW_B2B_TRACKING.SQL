CREATE OR REPLACE VIEW VIEW_B2B_TRACKING (ORDERID, OCCURRENCEDT, CONTROLPOINTID, CONTROLPOINTNM, ISSUERDOCUMENTNR, INVOICENUMBER,
   INVOICESERIALNUMBER, INVOICEEMISSIONDATE, INVOICEELETRONICKEY, SKUID, UNITPRICE, PREPAREDQT, FILAID, TIPOINTEGRACAO)
AS
SELECT DISTINCT "ORDERID","OCCURRENCEDT","CONTROLPOINTID","CONTROLPOINTNM","ISSUERDOCUMENTNR","INVOICENUMBER","INVOICESERIALNUMBER","INVOICEEMISSIONDATE","INVOICEELETRONICKEY","SKUID","UNITPRICE","PREPAREDQT","FILAID","TIPOINTEGRACAO" 
FROM (SELECT C.NUMPEDWEB ORDERID,
             SYSDATE OCCURRENCEDT,
             F.OBSERVACAO CONTROLPOINTID,
             -----------------------------------------------------------
             DECODE(F.OBSERVACAO, 'MAP', 'Análise aprovada',
                                  'MNA', 'Análise reprovada',
                                  'CAN', 'Entrega cancelada',
                                  'ENT', 'Entrega concluída',
                                  'ETR', 'Entrega em andamento',
                                  'FAT', 'Pedido faturado',
                                  'WMS', 'Separação e embalagem',
                                  'NFS', 'Nota Fiscal emitida', '') CONTROLPOINTNM,
             -----------------------------------------------------------
             DECODE(F.OBSERVACAO, 'NFS', L.CGC, '') ISSUERDOCUMENTNR,
             DECODE(F.OBSERVACAO, 'NFS', TO_CHAR(N.NUMNOTA), '') INVOICENUMBER,
             DECODE(F.OBSERVACAO, 'NFS', TO_CHAR(N.SERIE), '') INVOICESERIALNUMBER,
             DECODE(F.OBSERVACAO, 'NFS', TO_CHAR(N.DTSAIDA, 'dd/mm/yyyy hh24:mi:ss'), '') INVOICEEMISSIONDATE ,
             DECODE(F.OBSERVACAO, 'NFS', TO_CHAR(N.CHAVENFE), '') INVOICEELETRONICKEY,
             DECODE(F.OBSERVACAO, 'NFS', TO_CHAR(I.CODAUXILIAR), '') SKUID,
             REPLACE(DECODE(C.POSICAO, 'F', DECODE(INSTR(I.CODAUXILIAR,'C'), 0, TO_CHAR(M.PUNIT), TO_CHAR(M.PUNIT * TO_NUMBER(SUBSTR(I.CODAUXILIAR,INSTR(I.CODAUXILIAR,'C') + 1,LENGTH(I.CODAUXILIAR))))), ''),' ','') UNITPRICE,			 
             REPLACE(DECODE(C.POSICAO, 'F', DECODE(INSTR(I.CODAUXILIAR,'C'), 0, TO_CHAR(M.QT), TO_CHAR(M.QT / TO_NUMBER(SUBSTR(I.CODAUXILIAR,INSTR(I.CODAUXILIAR,'C') + 1,LENGTH(I.CODAUXILIAR))))), ''),' ','') PREPAREDQT,
             F.ROWID FILAID,
             F.TIPOINTEGRACAO
      FROM PCPEDC C, 
           PCECOMMERCEB2BFILA F, 
           PCFILIAL L, 
           PCNFSAID N, 
           PCMOV M, 
           PCPEDCTEMP T,
		     PCPRODUT P,
           PCECOMMERCEB2BPCPEDI I
      WHERE T.ROWID = F.ID
        AND L.CODIGO = C.CODFILIAL
        AND N.NUMTRANSVENDA(+) = C.NUMTRANSVENDA
        AND M.NUMTRANSVENDA(+) = N.NUMTRANSVENDA
        AND C.NUMPED = T.NUMPED
        AND F.TABELA = 'PEDIDO'
        AND I.NUMPEDWEB = C.NUMPEDWEB
        AND M.CODPROD = P.CODPROD
        AND P.CODAUXILIAR = DECODE(INSTR(I.CODAUXILIAR,'C'), 0, I.CODAUXILIAR, SUBSTR(I.CODAUXILIAR, 1, INSTR(I.CODAUXILIAR,'C')-1))		
        AND F.OBSERVACAO IS NOT NULL
      ----------------------------------------------------------------------
      UNION ALL
      ----------------------------------------------------------------------
      SELECT C.NUMPEDWEB ORDERID,
             SYSDATE OCCURRENCEDT,
             -----------------------------------------------------------
             DECODE (C.POSICAO, 'M', 'WMS', 
                                'L', 'MAP', 
                                'B', 'MAP', 
                                'P', 'MAP',
                                'F', DECODE(NVL(N.NUMNOTA,0), 0, 'WMS', 'NFS'), 
                                'C', 'CAN', '') CONTROLPOINTID,
             -----------------------------------------------------------
             DECODE(C.POSICAO, 'M', 'Separação e embalagem',
                               'L', 'Análise aprovada',
                               'B', 'Análise aprovada',
                               'P', 'Análise aprovada',
                               'F', DECODE(NVL(N.NUMNOTA,0), 0, 'Separação e embalagem', 'Nota Fiscal emitida'), 
                               'C', 'Entrega Cancelada', '') CONTROLPOINTNM,      
             -----------------------------------------------------------
             DECODE(C.POSICAO, 'F', L.CGC, '') ISSUERDOCUMENTNR,
             DECODE(C.POSICAO, 'F', TO_CHAR(N.NUMNOTA), '') INVOICENUMBER,
             DECODE(C.POSICAO, 'F', TO_CHAR(N.SERIE), '') INVOICESERIALNUMBER,
             DECODE(C.POSICAO, 'F', TO_CHAR(N.DTSAIDA, 'dd/mm/yyyy hh24:mi:ss'), '') INVOICEEMISSIONDATE ,
             DECODE(C.POSICAO, 'F', TO_CHAR(N.CHAVENFE), '') INVOICEELETRONICKEY,
             DECODE(C.POSICAO, 'F', TO_CHAR(I.CODAUXILIAR), '') SKUID,
             REPLACE(DECODE(C.POSICAO, 'F', DECODE(INSTR(I.CODAUXILIAR,'C'), 0, TO_CHAR(M.PUNIT), TO_CHAR(M.PUNIT * TO_NUMBER(SUBSTR(I.CODAUXILIAR,INSTR(I.CODAUXILIAR,'C') + 1,LENGTH(I.CODAUXILIAR))))), ''),' ','') UNITPRICE,			 
             REPLACE(DECODE(C.POSICAO, 'F', DECODE(INSTR(I.CODAUXILIAR,'C'), 0, TO_CHAR(M.QT), TO_CHAR(M.QT / TO_NUMBER(SUBSTR(I.CODAUXILIAR,INSTR(I.CODAUXILIAR,'C') + 1,LENGTH(I.CODAUXILIAR))))), ''),' ','') PREPAREDQT,
             F.ROWID FILAID,
             F.TIPOINTEGRACAO   
      FROM PCPEDC C, 
           PCECOMMERCEB2BFILA F, 
           PCFILIAL L, 
           PCPEDCTEMP T, 
           PCNFSAID N, 
           PCMOV M, 
           PCPRODUT P,
           PCECOMMERCEB2BPCPEDI I
      WHERE T.ROWID = F.ID
        AND L.CODIGO = C.CODFILIAL
        AND C.NUMPED = T.NUMPED     
        AND N.NUMTRANSVENDA(+) = C.NUMTRANSVENDA
        AND M.NUMTRANSVENDA(+) = N.NUMTRANSVENDA
        AND F.TABELA = 'PEDIDO'
        AND I.NUMPEDWEB = C.NUMPEDWEB
        AND M.CODPROD = P.CODPROD
        AND P.CODAUXILIAR = DECODE(INSTR(I.CODAUXILIAR,'C'), 0, I.CODAUXILIAR, SUBSTR(I.CODAUXILIAR, 1, INSTR(I.CODAUXILIAR,'C')-1))
        AND F.OBSERVACAO IS NULL
        AND C.POSICAO = 'F'
      ----------------------------------------------------------------------
      UNION ALL
      ----------------------------------------------------------------------
      SELECT C.NUMPEDWEB ORDERID,
             SYSDATE OCCURRENCEDT,
             -----------------------------------------------------------
             DECODE (C.POSICAO, 'M', 'WMS', 
                                'L', 'MAP', 
                                'B', 'MAP', 
                                'P', 'MAP', 
                                'C', 'CAN', '') CONTROLPOINTID,
             -----------------------------------------------------------
             DECODE(C.POSICAO, 'M', 'Separação e embalagem',
                               'L', 'Análise aprovada',
                               'B', 'Análise aprovada',
                               'P', 'Análise aprovada', 
                               'C', 'Entrega Cancelada', '') CONTROLPOINTNM,      
             -----------------------------------------------------------
             '' ISSUERDOCUMENTNR,
             '' INVOICENUMBER,
             '' INVOICESERIALNUMBER,
             '' INVOICEEMISSIONDATE ,
             '' INVOICEELETRONICKEY,
             '' SKUID,
             '' UNITPRICE,			 
             '' PREPAREDQT,
             F.ROWID FILAID,
             F.TIPOINTEGRACAO   
      FROM PCPEDC C, 
           PCECOMMERCEB2BFILA F, 
           PCFILIAL L, 
           PCPEDCTEMP T
      WHERE T.ROWID = F.ID
        AND L.CODIGO = C.CODFILIAL
        AND C.NUMPED = T.NUMPED     
        AND F.TABELA = 'PEDIDO'
        AND F.OBSERVACAO IS NULL
        AND C.POSICAO IN ('M','L','B','P','C')       
      ----------------------------------------------------------------------
      UNION ALL
      ----------------------------------------------------------------------
      SELECT T.NUMPEDWEB ORDERID,
             SYSDATE OCCURRENCEDT,
             -----------------------------------------------------------
             (CASE WHEN MOTIVO LIKE 'Cliente sem limite de crédito' THEN
                 'MNA'
              ELSE 
                 'CAN'
              END) CONTROLPOINTID,
             -----------------------------------------------------------
             (CASE WHEN MOTIVO LIKE 'Cliente sem limite de crédito' THEN
                 'Análise reprovada'
              ELSE
                 'Entrega Cancelada' 
              END) CONTROLPOINTNM,
             -----------------------------------------------------------
             '' ISSUERDOCUMENTNR,
             '' INVOICENUMBER,
             '' INVOICESERIALNUMBER,
             '' INVOICEEMISSIONDATE ,
             '' INVOICEELETRONICKEY,
             '' SKUID,
             '' UNITPRICE,
             '' PREPAREDQT,
             F.ROWID FILAID,
             F.TIPOINTEGRACAO     
      FROM PCNFCAN C, 
           PCECOMMERCEB2BFILA F, 
           PCFILIAL L, 
           PCPEDCTEMP T, 
           PCECOMMERCEB2BPCPEDC P
      WHERE T.ROWID = F.ID
        AND L.CODIGO = C.CODFILIAL
        AND C.NUMPED = T.NUMPED
        AND F.TABELA = 'PEDIDO'     
        AND P.NUMPEDWEB = T.NUMPEDWEB
        AND P.TIPOPAGAMENTO IN ('CRL-7', 'CRL-14', 'CRL-21', 'CRL-28')
        AND (F.OBSERVACAO IS NULL OR F.OBSERVACAO IN ('MNA', 'CAN'))
      ----------------------------------------------------------------------
      UNION ALL
      ----------------------------------------------------------------------
      SELECT T.NUMPEDWEB ORDERID,
             SYSDATE OCCURRENCEDT,
             'CAN' CONTROLPOINTID,
             'Entrega Cancelada' CONTROLPOINTNM,
             '' ISSUERDOCUMENTNR,
             '' INVOICENUMBER,
             '' INVOICESERIALNUMBER,
             '' INVOICEEMISSIONDATE ,
             '' INVOICEELETRONICKEY,
             '' SKUID,
             '' UNITPRICE,
             '' PREPAREDQT,
             F.ROWID FILAID,
             F.TIPOINTEGRACAO     
      FROM PCNFCAN C, 
           PCECOMMERCEB2BFILA F, 
           PCFILIAL L, 
           PCPEDCTEMP T, 
           PCECOMMERCEB2BPCPEDC P
      WHERE T.ROWID = F.ID
        AND L.CODIGO = C.CODFILIAL
        AND C.NUMPED = T.NUMPED
        AND F.TABELA = 'PEDIDO'     
        AND P.NUMPEDWEB = T.NUMPEDWEB
        AND P.TIPOPAGAMENTO NOT IN ('CRL-7', 'CRL-14', 'CRL-21', 'CRL-28')
        AND (F.OBSERVACAO IS NULL OR F.OBSERVACAO IN ('MNA', 'CAN')))
      ----------------------------------------------------------------------
      UNION ALL
      --DEVOLUÇÃO TOTAL COMO CANCELAMENTO
      ----------------------------------------------------------------------

      SELECT C.NUMPEDWEB ORDERID,
             SYSDATE OCCURRENCEDT,
             'CAN' CONTROLPOINTID,
             'Entrega Cancelada' CONTROLPOINTNM,
             '' ISSUERDOCUMENTNR,
             '' INVOICENUMBER,
             '' INVOICESERIALNUMBER,
             '' INVOICEEMISSIONDATE,
             '' INVOICEELETRONICKEY,
             '' SKUID,
             '' UNITPRICE,
             '' PREPAREDQT,
             T.ROWID FILAID,
             NVL (T.INTEGRADORA,29 ) AS TIPOINTEGRACAO
      FROM PCPEDC C,
           PCESTCOM CC,
           PCFILIAL L,
           PCPEDCTEMP T,
           PCECOMMERCEB2BPCPEDC P,
           PCPREST PR
      WHERE  L.CODIGO = C.CODFILIAL
		AND C.NUMTRANSVENDA = CC.NUMTRANSVENDA
		AND C.NUMTRANSVENDA = PR.NUMTRANSVENDA
		AND P.NUMPEDWEB =  C.NUMPEDWEB
		AND P.NUMPEDWEB = T.NUMPEDWEB
		AND T.NUMPED =  C.NUMPED
		AND PR.VALOR < 0 
		AND PR.CODCOB = 'DEVT'
