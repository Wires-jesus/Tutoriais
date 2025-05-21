CREATE OR REPLACE VIEW VIEW_GERA_CIAP AS 
SELECT '01 - Credito lançado pela 3402' AS ID,
       NVL(N.CODFILIALNF, N.CODFILIAL) CODFILIAL,
       N.NUMTRANSENT TRANSACAO,
       'ME' TIPOTRANSACAO,
       M.QTCONT,
       NVL(M.QTMESESCREDCIAP, NVL(PARAMFILIAL.OBTERCOMONUMBER('CON_QTMESESCREDCIAP'), 48)) QTMESESCREDCIAP,
       M.CODPROD,
       N.DTENT DATA,
       N.NUMNOTA,
       P.DESCRICAO,
       ROUND(DECODE(NVL(M.GRAVADOUNITARIO,'S'), 'S', M.QTCONT, 1) * M.VLCREDITO, 2) VLCREDITO,
       ROUND(DECODE(NVL(M.GRAVADOUNITARIO,'S'), 'S', M.QTCONT,1) * M.VLDIFALIQUOTA, 2) VLDIFALIQUOTA,
       0 VLBAIXACRED,
       0 VLBAIXADIFALIQUOTA,
       DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP', NVL(N.CODFILIALNF,N.CODFILIAL)), 'M'), 'E', N.DTENT + 1, N.DTENT) DATAINICIOCIAP,
       DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP', NVL(N.CODFILIALNF,N.CODFILIAL)), 'M'), 'E', NVL(M.DTTERMINOCIAP, N.DTTERMINOCIAP) + 1, NVL(M.DTTERMINOCIAP, N.DTTERMINOCIAP)) DATAFINALCIAP,
       NULL DATABAIXA,
       NVL(N.VINCULARDOCUMENTOCT,'N') VINCULARDOCUMENTOCT,
       -------------- CALCULANDO VLCREDFRETE ------------------
       (CASE WHEN (NVL(N.VINCULARDOCUMENTOCT,'N') = 'S') AND
                  (NVL(N.NUMTRANSORIGEMCT,0) > 0) THEN
           GREATEST((SELECT SUM(ROUND(MF.QTCONT * NVL(MF.VLCREDITO,0),2)) VLCREDITO
                     FROM PCMOVCIAP MF
                     WHERE MF.NUMTRANSENT = N.NUMTRANSORIGEMCT
                       AND MF.VLCREDITO > 0), 0)
        ELSE
           0
        END) / CASE WHEN (NVL(N.VINCULARDOCUMENTOCT,'N') = 'S') AND
                         (NVL(N.NUMTRANSORIGEMCT,0) > 0) AND
                       (SELECT COUNT(1) CONTADOR
                           FROM PCMOVCIAP MF
                          WHERE MF.NUMTRANSENT = N.NUMTRANSENT
                            AND MF.VLCREDITO > 0) > 0
                   THEN
                        (SELECT COUNT(1) CONTADOR
                           FROM PCMOVCIAP MF
                          WHERE MF.NUMTRANSENT = N.NUMTRANSENT
                            AND MF.VLCREDITO > 0)
                   ELSE
                      1 END VLCREDFRETE,
       ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
       0 VLBAIXACREDFRETE,
       (CASE WHEN (NVL(N.VINCULARDOCUMENTOCT,'N') = 'S') AND
                  (NVL(N.NUMTRANSORIGEMCT,0) > 0) THEN
           GREATEST( NVL((SELECT SUM(ROUND(MF.QTCONT * (NVL(MF.VLDIFALIQUOTA,0)),2))
                        FROM PCMOVCIAP MF,
                             PCPRODCIAP PF
                        WHERE MF.NUMTRANSENT = N.NUMTRANSORIGEMCT
                          AND PF.CODPROD = MF.CODPROD
                          --AND MF.VLCREDITO > 0
                          AND MF.VLDIFALIQUOTA > 0),0),0)

        ELSE
           0
        END) / CASE WHEN (NVL(N.VINCULARDOCUMENTOCT,'N') = 'S') AND
                         (NVL(N.NUMTRANSORIGEMCT,0) > 0) AND
                        (SELECT COUNT(1) CONTADOR
                           FROM PCMOVCIAP MF
                          WHERE MF.NUMTRANSENT = N.NUMTRANSENT
                            --AND MF.VLDIFALIQUOTA > 0
                            ) > 0
                   THEN
                        (SELECT COUNT(1) CONTADOR
                           FROM PCMOVCIAP MF
                          WHERE MF.NUMTRANSENT = N.NUMTRANSENT
                            --AND MF.VLDIFALIQUOTA > 0
                            )
                   ELSE
                      1 END VLDIFALIQUOTAFRETE,
       0 VLBAIXADIFALIQUOTAFRETE
       ,M.CODPRODSEQ
       ,M.ITEMDUPLICADO
       -------------------------------------------------------------------------------------------------------------------------
  FROM PCMOVCIAP  M,
       PCNFENT    N,
       PCPRODCIAP P
 WHERE M.NUMTRANSENT = N.NUMTRANSENT
   AND N.ESPECIE = 'NF'
   AND P.CODPROD = M.CODPROD
   AND NVL(M.TIPOMERC, NVL(P.TIPOMERC, 'IM')) = 'IM'
   AND N.VLTOTAL > 0
   AND ( (M.VLCREDITO > 0) OR (M.VLDIFALIQUOTA > 0))
   AND NVL(M.LEASING, 'N') = 'N'
---------------------------------------------------
UNION ALL
---------------------------------------------------
-- CREDITO DE BENS LANÇADOS PELA ROTINA 3405
SELECT '02 - Crédito lançado pela 3405' AS ID,
       N.CODFILIAL,
       N.CODSALDO TRANSACAO,
       'SI' TIPOTRANSACAO,
       1 QTCONT,
       NVL(PARAMFILIAL.OBTERCOMONUMBER('CON_QTMESESCREDCIAP'), 48) QTMESESCREDCIAP,
       N.CODPROD,
       N.DATA,
       N.NUMNOTA,
       P.DESCRICAO,
       N.VLCREDITO,
       N.VLDIFALIQUOTA,
       0 VLBAIXACRED,
       0 VLBAIXADIFALIQUOTA,
       DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP', N.CODFILIAL), 'M'), 'E', N.DATA + 1, N.DATA) DATAINICIOCIAP,
       DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP', N.CODFILIAL), 'M'), 'E', N.DTTERMINOCIAP + 1, N.DTTERMINOCIAP) DATAFINALCIAP,
       NULL DATABAIXA,
       'N' VINCULARDOCUMENTOCT,
       0 VLCREDFRETE,
       0 VLBAIXACREDFRETE,
       0 VLDIFALIQUOTAFRETE,
       0 VLBAIXADIFALIQUOTAFRETE,
       '' CODPRODSEQ
       ,'N' ITEMDUPLICADO
  FROM PCCIAPSALDOINICIAL N,
       PCPRODCIAP         P
 WHERE P.CODPROD = N.CODPROD
   AND N.VLCREDITO > 0
---------------------------------------------------
UNION ALL
---------------------------------------------------
--BAIXA DE BENS BAIXADOS ANTECIPADAMENTE (LANÇADOS PELA ROTINA 3402)
SELECT '03 - Bens lançados pela 3402 baixados Antec' AS ID,
       TAB.CODFILIAL,
       TAB.TRANSACAO,
       TAB.TIPOTRANSACAO,
       TAB.QTCONT,
       TAB.QTMESESCREDCIAP,
       TAB.CODPROD,
       TAB.DATA,
       TAB.NUMNOTA,
       TAB.DESCRICAO,
       SUM(NVL(TAB.VLCREDITO,0)) VLCREDITO,
       SUM(NVL(TAB.VLDIFALIQUOTA,0)) VLDIFALIQUOTA,
       ROUND(SUM(NVL(TAB.VLBAIXACRED,0)),2) VLBAIXACRED,
       ROUND(SUM(NVL(TAB.VLBAIXADIFALIQUOTA,0)),2) VLBAIXADIFALIQUOTA,
       TAB.DATAINICIOCIAP,
       TAB.DATAFINALCIAP,
       TAB.DATABAIXA,
       TAB.VINCULARDOCUMENTOCT,
       TAB.VLCREDFRETE,
       SUM(NVL(TAB.VLBAIXACREDFRETE,0))  VLBAIXACREDFRETE,
       TAB.VLDIFALIQUOTAFRETE,
       SUM(NVL(TAB.VLBAIXADIFALIQUOTAFRETE,0)) VLBAIXADIFALIQUOTAFRETE,
       TAB.CODPRODSEQ,
       TAB.ITEMDUPLICADO
FROM (
SELECT NVL(N.CODFILIALNF, N.CODFILIAL) CODFILIAL,
       N.NUMTRANSENT TRANSACAO,
       'ME' TIPOTRANSACAO,
       DECODE(NVL(M.GRAVADOUNITARIO,'S'), 'S',1, M.QTCONT) QTCONT,
       NVL(M.QTMESESCREDCIAP, NVL(PARAMFILIAL.OBTERCOMONUMBER('CON_QTMESESCREDCIAP'), 48)) QTMESESCREDCIAP,
       M.CODPROD,
       B.DATABAIXA DATA,
       N.NUMNOTA,
       P.DESCRICAO,
       0 VLCREDITO,
       0 VLDIFALIQUOTA,
--------------------------------------------------------------------------------------------------------------------------
       M.VLCREDITO / DECODE(NVL(M.GRAVADOUNITARIO,'S'), 'S',1,M.QTCONT) VLBAIXACRED,
--------------------------------------------------------------------------------------------------------------------------
       NVL(M.VLDIFALIQUOTA, 0) / DECODE(NVL(M.GRAVADOUNITARIO,'S'), 'S', 1, M.QTCONT) VLBAIXADIFALIQUOTA,
--------------------------------------------------------------------------------------------------------------------------
       DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP', NVL(N.CODFILIALNF,N.CODFILIAL)), 'M'), 'E', N.DTENT + 1, N.DTENT) DATAINICIOCIAP,
       DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP', NVL(N.CODFILIALNF,N.CODFILIAL)), 'M'), 'E', NVL(M.DTTERMINOCIAP, N.DTTERMINOCIAP) + 1, NVL(M.DTTERMINOCIAP, N.DTTERMINOCIAP)) DATAFINALCIAP,
       DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP', NVL(N.CODFILIALNF,N.CODFILIAL)), 'M'), 'E', B.DATABAIXA + 1, B.DATABAIXA) DATABAIXA,
       N.VINCULARDOCUMENTOCT,
       0 VLCREDFRETE,
--------------------------------------------------------------------------------------------------------------------------
       DECODE(B.SEQUENCIA,
              (SELECT MAX(SEQUENCIA)
                 FROM PCBENSPATRIMONIAIS
                WHERE NUMTRANSACAO = N.NUMTRANSENT
                  AND CODPROD = M.CODPROD
                  AND TIPOTRANSACAO = 'ME'),
               (CASE WHEN (NVL(VINCULARDOCUMENTOCT,'N') = 'S') AND
                          (NVL(NUMTRANSORIGEMCT,0) > 0) THEN
                   GREATEST(ROUND((SELECT SUM(NVL(MF.VLCREDITO,0)) VLCREDITO
                                   FROM PCMOVCIAP MF
                                   WHERE MF.NUMTRANSENT = N.NUMTRANSORIGEMCT
                                    AND MF.VLCREDITO > 0) /
                                  (SELECT SUM(MC.QTCONT)
                                   FROM PCMOVCIAP MC
                                   WHERE MC.NUMTRANSENT = N.NUMTRANSENT), 2), 0)
                ELSE
                  0
                END), 0) VLBAIXACREDFRETE,
--------------------------------------------------------------------------------------------------------------------------
      0 VLDIFALIQUOTAFRETE,
--------------------------------------------------------------------------------------------------------------------------
       DECODE(B.SEQUENCIA,
              (SELECT MAX(SEQUENCIA)
                 FROM PCBENSPATRIMONIAIS
                WHERE NUMTRANSACAO = N.NUMTRANSENT
                  AND CODPROD = M.CODPROD
                  AND TIPOTRANSACAO = 'ME'),
               (CASE WHEN (NVL(VINCULARDOCUMENTOCT,'N') = 'S') AND
                          (NVL(NUMTRANSORIGEMCT,0) > 0) THEN
                   GREATEST(ROUND((SELECT DECODE(NVL(MF.GERACREDITOCIAP, NVL(PF.GERACREDITOCIAP, 'N')),
                                                 'N',
                                                 0,
                                              SUM(ROUND(MF.QTCONT * (NVL(MF.VLDIFALIQUOTA,0)),2))) VLBAIXADIFALIQUOTAFRETE
                                           FROM PCMOVCIAP MF,
                                              PCPRODCIAP PF
                                           WHERE MF.NUMTRANSENT = N.NUMTRANSORIGEMCT
                                             AND PF.CODPROD = MF.CODPROD
                                             AND MF.VLDIFALIQUOTA > 0
                                           GROUP BY MF.GERACREDITOCIAP, PF.GERACREDITOCIAP) /
                                  CASE
            WHEN (NVL(N.VINCULARDOCUMENTOCT, 'N') = 'S') AND(NVL(N.NUMTRANSORIGEMCT, 0) > 0) AND (SELECT COUNT(1) CONTADOR
                                                                                                    FROM PCMOVCIAP MF
                                                                                                   WHERE MF.NUMTRANSENT = N.NUMTRANSENT AND MF.VLDIFALIQUOTA > 0) > 0
               THEN (SELECT COUNT(1) CONTADOR
                       FROM PCMOVCIAP MF
                      WHERE MF.NUMTRANSENT = N.NUMTRANSENT AND MF.VLDIFALIQUOTA > 0)
            ELSE 1
         END, 2), 0)
                ELSE
                  0
                END), 0) VLBAIXADIFALIQUOTAFRETE
       ,M.CODPRODSEQ
       ,M.ITEMDUPLICADO
       -------------------------------------------------------------------------------------------------------------------------
  FROM PCBENSPATRIMONIAIS B,
       PCNFENT N,
       PCPRODCIAP P,
       PCMOVCIAP M
 WHERE N.ESPECIE = 'NF'
   AND B.NUMTRANSACAO = N.NUMTRANSENT
   --AND B.NUMNOTA(+) = N.NUMNOTA
   AND (CASE WHEN B.TIPOBAIXA <> 'TR' THEN B.NUMNOTA ELSE N.NUMNOTA END) = N.NUMNOTA
   AND B.TIPOTRANSACAO = 'ME'
   AND B.CODPROD = M.CODPROD
   AND NVL(B.CODPRODSEQ,'0') = NVL(M.CODPRODSEQ,'0')
   AND B.NUMTRANSACAO = M.NUMTRANSENT
   AND B.CODFILIAL = NVL(N.CODFILIALNF, N.CODFILIAL)
   AND P.CODPROD = M.CODPROD
   AND NVL(M.TIPOMERC, NVL(P.TIPOMERC, 'IM')) = 'IM'
   AND NVL(M.LEASING, 'N') = 'N'
   AND N.VLTOTAL > 0
   AND ( (M.VLCREDITO > 0) OR (M.VLDIFALIQUOTA > 0))
   -- ESSA CONDIÇÃO EVITA QUE UM BEM BAIXADO NO BENS PATRIMONIAIS COM DATA SUPERIOR A DATA DO TERMINO SEJA EXIBIDO
   AND ( (B.DATABAIXA IS NOT NULL) AND (B.DATABAIXA BETWEEN N.DTENT AND N.DTTERMINOCIAP)  )
) TAB
GROUP BY  TAB.CODFILIAL,
         TAB.TRANSACAO,
         TAB.TIPOTRANSACAO,
         TAB.QTCONT,
         TAB.QTMESESCREDCIAP,
         TAB.CODPROD,
         TAB.DATA,
         TAB.NUMNOTA,
         TAB.DESCRICAO,
         TAB.DATAINICIOCIAP,
         TAB.DATAFINALCIAP,
         TAB.DATABAIXA,
         TAB.VINCULARDOCUMENTOCT,
         TAB.VLCREDFRETE,
         TAB.VLDIFALIQUOTAFRETE,
         TAB.CODPRODSEQ,
         TAB.ITEMDUPLICADO
---------------------------------------------------
UNION ALL
---------------------------------------------------
-- BAIXA PARCIAL DE BENS EM TRANSFERENCIA - TR
SELECT '03.1 - Bens lançados pela 3418 com baixa Antec.pela 3410. Item tipotransacao TR' AS ID,
       NVL(N.CODFILIALNF, N.CODFILIAL) CODFILIAL,
       N.NUMTRANSENT TRANSACAO,
       'ME' TIPOTRANSACAO,
       1 QTCONT,
       NVL(M.QTMESESCREDCIAP, NVL(PARAMFILIAL.OBTERCOMONUMBER('CON_QTMESESCREDCIAP'), 48)) QTMESESCREDCIAP,
       M.CODPROD,
       B.DATABAIXA DATA,
       N.NUMNOTA,
       P.DESCRICAO,
       M.VLCREDITO,
       M.VLDIFALIQUOTA,
--------------------------------------------------------------------------------------------------------------------------
       ROUND(M.VLCREDITO / DECODE(NVL(M.GRAVADOUNITARIO,'S'), 'S',1, M.QTCONT), 2) +
       DECODE(B.SEQUENCIA,
              (SELECT max(SEQUENCIA)
                 FROM PCBENSPATRIMONIAIS
                WHERE NUMTRANSACAO = N.NUMTRANSENT
                  AND CODPROD = M.CODPROD
                  --AND DTTERMINOCIAP IS NULL
                  AND TIPOTRANSACAO = 'ME'),
              ROUND((M.VLCREDITO - ROUND(M.VLCREDITO / DECODE(NVL(M.GRAVADOUNITARIO,'S'), 'S', 1, M.QTCONT), 2) *  DECODE(NVL(M.GRAVADOUNITARIO,'S'), 'S', 1, M.QTCONT)),2),
              0) VLBAIXACRED,

--------------------------------------------------------------------------------------------------------------------------
       ROUND(NVL(M.VLDIFALIQUOTA, 0) / DECODE(NVL(M.GRAVADOUNITARIO,'S'), 'S',1, M.QTCONT), 2) +
       DECODE(B.SEQUENCIA,
              (SELECT max(SEQUENCIA)
                 FROM PCBENSPATRIMONIAIS
                WHERE NUMTRANSACAO = N.NUMTRANSENT
                  AND CODPROD = M.CODPROD
                  AND TIPOTRANSACAO = 'ME'),
              (M.VLDIFALIQUOTA - ROUND(M.VLDIFALIQUOTA / DECODE(NVL(M.GRAVADOUNITARIO,'S'), 'S', 1,M.QTCONT), 2) * M.QTCONT),
              0) VLBAIXADIFALIQUOTA,
--------------------------------------------------------------------------------------------------------------------------
       DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP', NVL(N.CODFILIALNF,N.CODFILIAL)), 'M'), 'E', N.DTENT + 1, N.DTENT) DATAINICIOCIAP,
       DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP', NVL(N.CODFILIALNF,N.CODFILIAL)), 'M'), 'E', N.DTTERMINOCIAP + 1, N.DTTERMINOCIAP) DATAFINALCIAP,
       DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP', NVL(N.CODFILIALNF,N.CODFILIAL)), 'M'), 'E', B.DATABAIXA + 1, B.DATABAIXA) DATABAIXA,
       'N' VINCULARDOCUMENTOCT,
       0 VLCREDFRETE,
--------------------------------------------------------------------------------------------------------------------------
       DECODE(B.SEQUENCIA,
              (SELECT MAX(SEQUENCIA)
                 FROM PCBENSPATRIMONIAIS
                WHERE NUMTRANSACAO = N.NUMTRANSENT
                  AND CODPROD = M.CODPROD
                  AND TIPOTRANSACAO = 'ME'),
               (CASE WHEN (NVL(VINCULARDOCUMENTOCT,'N') = 'S') AND
                          (NVL(NUMTRANSORIGEMCT,0) > 0) THEN
                   GREATEST(ROUND((SELECT SUM(NVL(MF.VLCREDITO,0)) VLCREDITO
                                   FROM PCMOVCIAP MF
                                   WHERE MF.NUMTRANSENT = N.NUMTRANSORIGEMCT
                                    AND MF.VLCREDITO > 0) /
                                  (SELECT SUM(MC.QTCONT)
                                   FROM PCMOVCIAP MC
                                   WHERE MC.NUMTRANSENT = N.NUMTRANSENT), 2), 0)
                ELSE
                  0
                END), 0) VLBAIXACREDFRETE,
--------------------------------------------------------------------------------------------------------------------------
       0 VLDIFALIQUOTAFRETE,
--------------------------------------------------------------------------------------------------------------------------
       DECODE(B.SEQUENCIA,
              (SELECT MAX(SEQUENCIA)
                 FROM PCBENSPATRIMONIAIS
                WHERE NUMTRANSACAO = N.NUMTRANSENT
                  AND CODPROD = M.CODPROD
                  AND TIPOTRANSACAO = 'ME'),
               (CASE WHEN (NVL(VINCULARDOCUMENTOCT,'N') = 'S') AND
                          (NVL(NUMTRANSORIGEMCT,0) > 0) THEN
                   GREATEST(ROUND((SELECT DECODE(NVL(MF.GERACREDITOCIAP, NVL(PF.GERACREDITOCIAP, 'N')),
                                                 'N',
                                                 0,
                                              SUM(ROUND(MF.QTCONT * (NVL(MF.VLDIFALIQUOTA,0)),2))) VLBAIXADIFALIQUOTAFRETE
                                           FROM PCMOVCIAP MF,
                                              PCPRODCIAP PF
                                           WHERE MF.NUMTRANSENT = N.NUMTRANSORIGEMCT
                                             AND PF.CODPROD = MF.CODPROD
                                             AND MF.VLDIFALIQUOTA > 0
                                           GROUP BY MF.GERACREDITOCIAP, PF.GERACREDITOCIAP) /
                                  (SELECT SUM(MC.QTCONT)
                                   FROM PCMOVCIAP MC
                                   WHERE MC.NUMTRANSENT = N.NUMTRANSENT), 2), 0)
                ELSE
                  0
                END), 0) VLBAIXADIFALIQUOTAFRETE,
        '' CODPRODSEQ
        ,M.ITEMDUPLICADO
  FROM PCMOVCIAP          M,
       PCNFENT            N,
       PCPRODCIAP         P,
       (SELECT MAX(SEQUENCIA) SEQUENCIA,
               NUMTRANSACAO,
               DATABAIXA,
               CODFILIAL,
               CODPROD,
               TIPOTRANSACAO
         FROM PCBENSPATRIMONIAIS BM
        GROUP BY NUMTRANSACAO, DATABAIXA, CODFILIAL, CODPROD, TIPOTRANSACAO ) B --estava gerando duplicidade quando existe mais de um registro para a mesma transação e produto
 WHERE M.NUMTRANSENT = N.NUMTRANSENT
   AND N.ESPECIE = 'NF'
   AND B.NUMTRANSACAO = N.NUMTRANSENT
   AND B.TIPOTRANSACAO = 'TR'
   AND B.CODPROD = M.CODPROD
   AND B.CODFILIAL = NVL(N.CODFILIALNF, N.CODFILIAL)
   AND P.CODPROD = M.CODPROD
   AND NVL(M.TIPOMERC, NVL(P.TIPOMERC, 'IM')) = 'IM'
   AND CASE WHEN M.SEQUENCIA IS NULL THEN B.SEQUENCIA ELSE M.SEQUENCIA END = B.SEQUENCIA
   AND NVL(M.LEASING, 'N') = 'N'
   AND N.VLTOTAL > 0
   AND M.VLCREDITO > 0
   AND ( (M.VLCREDITO > 0) OR (M.VLDIFALIQUOTA > 0))
   AND B.DATABAIXA IS NOT NULL
---------------------------------------------------
UNION ALL
---------------------------------------------------
--BAIXA DE BENS BAIXADOS ANTECIPADAMENTE (LANÇADOS PELA ROTINA 3405)
SELECT '04 - Bens lançados pela 3405 baixados Antec' AS ID,
       N.CODFILIAL,
       N.CODSALDO NUMTRANSENT,
       'SI' TIPOTRANSACAO,
       1 QTCONT,
       NVL(PARAMFILIAL.OBTERCOMONUMBER('CON_QTMESESCREDCIAP'), 48) QTMESESCREDCIAP,
       N.CODPROD,
       B.DATABAIXA DATA,
       N.NUMNOTA,
       P.DESCRICAO,
       0 VLCREDITO,
       0 VLDIFALIQUOTA,
       ROUND(N.VLCREDITO / (SELECT COUNT(1)
                              FROM PCBENSPATRIMONIAIS
                             WHERE NUMTRANSACAO = N.CODSALDO
                               AND CODPROD = N.CODPROD
                               AND TIPOTRANSACAO = 'SI'),
             2) +
       DECODE(B.SEQUENCIA,
              (SELECT max(SEQUENCIA)
                 FROM PCBENSPATRIMONIAIS
                WHERE NUMTRANSACAO = N.CODSALDO
                  AND CODPROD = N.CODPROD
                  AND TIPOTRANSACAO = 'SI'),
              (N.VLCREDITO -
              ROUND(N.VLCREDITO / (SELECT COUNT(1)
                                      FROM PCBENSPATRIMONIAIS
                                     WHERE NUMTRANSACAO = N.CODSALDO
                                       AND CODPROD = N.CODPROD
                                       AND TIPOTRANSACAO = 'SI'), 2) *
                    (SELECT COUNT(1)
                     FROM PCBENSPATRIMONIAIS
                     WHERE NUMTRANSACAO = N.CODSALDO
                       AND CODPROD = N.CODPROD
                       AND TIPOTRANSACAO = 'SI')),
              0) VLBAIXACRED,
       N.VLDIFALIQUOTA VLBAIXADIFALIQUOTA,
       DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP', N.CODFILIAL), 'M'), 'E', N.DATA + 1, N.DATA) DATAINICIOCIAP,
       DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP', N.CODFILIAL), 'M'), 'E', N.DTTERMINOCIAP + 1, N.DTTERMINOCIAP) DATAFINALCIAP,
       DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP', N.CODFILIAL), 'M'), 'E', B.DATABAIXA + 1, B.DATABAIXA) DATABAIXA,
       'N' VINCULARDOCUMENTOCT,
       0 VLCREDFRETE,
       0 VLBAIXACREDFRETE,
       0 VLDIFALIQUOTAFRETE,
       0 VLBAIXADIFALIQUOTAFRETE,
       '' CODPRODSEQ
      ,'N' ITEMDUPLICADO
  FROM PCCIAPSALDOINICIAL N,
       PCPRODCIAP         P,
       PCBENSPATRIMONIAIS B
 WHERE P.CODPROD = N.CODPROD
   AND N.VLCREDITO > 0
   AND B.NUMTRANSACAO = N.CODSALDO
   AND B.TIPOTRANSACAO = 'SI'
   AND B.CODPROD = N.CODPROD
   AND ((B.DATABAIXA IS NOT NULL) AND (B.DATABAIXA <= N.DTTERMINOCIAP))
---------------------------------------------------
UNION ALL
---------------------------------------------------
--BAIXA DE BENS COM TERMINO CIAP (LANÇADOS PELA ROTINA 3402) SEM BAIXA PARCIAL
 select '05 - Bens lançados pela 3402 com termino ciap sem baixa parcial' AS ID,
        NVL(N.CODFILIALNF, N.CODFILIAL) CODFILIAL,
       N.NUMTRANSENT TRANSACAO,
       'ME' TIPOTRANSACAO,
       M.QTCONT,
       NVL(M.QTMESESCREDCIAP,
           NVL(PARAMFILIAL.OBTERCOMONUMBER('CON_QTMESESCREDCIAP'), 48)) QTMESESCREDCIAP,
       M.CODPROD,
       ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
          CASE WHEN NVL(M.QTMESESCREDCIAP,0) = 0 THEN
               DECODE( NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP', NVL(N.CODFILIALNF,N.CODFILIAL)), 'M'),
                       'E', (ADD_MONTHS(N.DTTERMINOCIAP,0) ), ( ADD_MONTHS(N.DTTERMINOCIAP,0) ))
               WHEN NVL(M.QTMESESCREDCIAP,0) > 0 THEN
               DECODE( NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP', NVL(N.CODFILIALNF,N.CODFILIAL)), 'M'),
                       'E', (ADD_MONTHS(N.DTTERMINOCIAP,1)), ( ADD_MONTHS(N.DTTERMINOCIAP,1)))
               ELSE
               ADD_MONTHS(N.DTTERMINOCIAP,1) END DATA,
       ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
       N.NUMNOTA,
       P.DESCRICAO,
       0 VLCREDITO,
       0 VLDIFALIQUOTA,
       ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
       ROUND(M.VLCREDITO * DECODE(NVL(M.GRAVADOUNITARIO,'S'), 'S',M.QTCONT,1),2) AS VLBAIXACRED,
       ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
       ROUND(M.VLDIFALIQUOTA * DECODE(NVL(M.GRAVADOUNITARIO,'S'), 'S',M.QTCONT,1),2) AS VLBAIXADIFALIQUOTA,
       ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
       DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP', NVL(N.CODFILIALNF,N.CODFILIAL)), 'M'), 'E', N.DTENT + 1, N.DTENT) DATAINICIOCIAP,
       DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP', NVL(N.CODFILIALNF,N.CODFILIAL)), 'M'), 'E', NVL(M.DTTERMINOCIAP, N.DTTERMINOCIAP) + 1, NVL(M.DTTERMINOCIAP, N.DTTERMINOCIAP)) DATAFINALCIAP,
       null DATABAIXA,
       NVL(N.VINCULARDOCUMENTOCT,'N') VINCULARDOCUMENTOCT,
       0 VLCREDFRETE,
       ----------- CALCULANDO VLBAIXACREDFRETE ---------------------------------------
       (CASE WHEN (NVL(N.VINCULARDOCUMENTOCT,'N') = 'S') AND
                  (NVL(N.NUMTRANSORIGEMCT,0) > 0) THEN
           GREATEST((SELECT SUM(ROUND(MF.QTCONT * NVL(MF.VLCREDITO,0),2)) VLCREDITO
                     FROM PCMOVCIAP MF
                     WHERE MF.NUMTRANSENT = N.NUMTRANSORIGEMCT
                       AND MF.VLCREDITO > 0), 0)
        ELSE
           0
        END) / CASE WHEN (NVL(N.VINCULARDOCUMENTOCT,'N') = 'S') AND
                         (NVL(N.NUMTRANSORIGEMCT,0) > 0) AND
                         (SELECT COUNT(1) CONTADOR
                            FROM PCMOVCIAP MF
                           WHERE MF.NUMTRANSENT = N.NUMTRANSENT
                             AND MF.VLCREDITO > 0) > 0
                    THEN
                         (SELECT COUNT(1) CONTADOR
                            FROM PCMOVCIAP MF
                           WHERE MF.NUMTRANSENT = N.NUMTRANSENT
                             AND MF.VLCREDITO > 0)
                    ELSE
                       1 END VLBAIXACREDFRETE,
       ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
       0 VLDIFALIQUOTAFRETE,
       -- CALCULANDO VLBAIXADIFALIQUOTAFRETE --------------------------------------------------------------------------------------------------------------------------------------------------------------
       (CASE WHEN (NVL(N.VINCULARDOCUMENTOCT,'N') = 'S') AND
                  (NVL(N.NUMTRANSORIGEMCT,0) > 0) THEN
           GREATEST(NVL(( SELECT SUM(ROUND(MF.QTCONT * (NVL(MF.VLDIFALIQUOTA,0)),2))
                     FROM PCMOVCIAP MF,
                          PCPRODCIAP PF
                     WHERE MF.NUMTRANSENT = N.NUMTRANSORIGEMCT
                       AND PF.CODPROD = MF.CODPROD
                       --AND MF.VLCREDITO > 0
                       AND MF.VLDIFALIQUOTA > 0
                       ),0),0)
        ELSE
           0
        END) / CASE WHEN (NVL(N.VINCULARDOCUMENTOCT,'N') = 'S') AND
                         (NVL(N.NUMTRANSORIGEMCT,0) > 0) AND
                        (SELECT COUNT(1) CONTADOR
                           FROM PCMOVCIAP MF
                          WHERE MF.NUMTRANSENT = N.NUMTRANSENT
                            --AND MF.VLCREDITO > 0
                            ) > 0
                   THEN
                        (SELECT COUNT(1) CONTADOR
                           FROM PCMOVCIAP MF
                          WHERE MF.NUMTRANSENT = N.NUMTRANSENT
                            --AND MF.VLCREDITO > 0
                            )
                   ELSE
                      1 END VLBAIXADIFALIQUOTAFRETE
       ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
       ,M.CODPRODSEQ
       ,M.ITEMDUPLICADO
       -------------------------------------------------------------------------------------------------------------------------
 from PCMOVCIAP  M,
      PCNFENT    N,
      PCPRODCIAP P
 where M.NUMTRANSENT = N.NUMTRANSENT
   and P.CODPROD = M.CODPROD
   and N.VLTOTAL > 0
   AND ( (M.VLCREDITO > 0) OR (M.VLDIFALIQUOTA > 0))
   and N.ESPECIE = 'NF'
   and NVL(M.TIPOMERC, NVL(P.TIPOMERC, 'IM')) = 'IM'
   and NVL(M.LEASING, 'N') = 'N'
   -- VERIFICANDO BAIXA PARCIAL NA BENS PATRIMONIAIS
   AND NOT EXISTS (select 1
                      from PCBENSPATRIMONIAIS B
                     where B.NUMTRANSACAO = N.NUMTRANSENT
                       and B.CODPROD = M.CODPROD
                       and B.TIPOTRANSACAO = 'ME'
--                       Alterado para considerar a data final + 1.
--                       and ( (B.DATABAIXA is not null) and (B.DATABAIXA BETWEEN N.DTENT AND N.DTTERMINOCIAP)))
                       and ( (B.DATABAIXA is not null) and (B.DATABAIXA BETWEEN N.DTENT AND ADD_MONTHS(N.DTTERMINOCIAP,1))))
   -- VERIFICANDO BAIXA PARCIAL NA SAIDA PELA 3421
   AND NOT EXISTS (select 1
                      from PCNFSAID S,
                           PCMOVCIAP M2
                     where S.NUMTRANSVENDA = M2.NUMTRANSVENDA
                       AND S.NUMTRANSENTORIGEM = N.NUMTRANSENT
                       AND M2.CODPROD = P.CODPROD
                       AND NVL(S.CODFILIALNF, S.CODFILIAL) = M2.CODFILIAL -- Ligando filial interna desse sub sql.
                       AND NVL(S.CODFILIALNF, S.CODFILIAL) = M.CODFILIAL -- Ligando com a filial externa a este sql.
                       AND ( (S.DTSAIDA is not null) and
                             (S.DTSAIDA BETWEEN N.DTENT and ADD_MONTHS(N.DTTERMINOCIAP,1))))
---------------------------------------------------
UNION ALL
---------------------------------------------------
--BAIXA DE BENS COM TERMINO CIAP (LANÇADOS PELA ROTINA 3402) E QUE TIVERAM BAIXA PARCIAL
 select ID,
       CODFILIAL,
       TRANSACAO,
       TIPOTRANSACAO,
       QTCONT,
       QTMESESCREDCIAP,
       CODPROD,
       DATA, --N.DTTERMINOCIAP
       NUMNOTA,
       DESCRICAO,
       VLCREDITO, -- ZERO
       VLDIFALIQUOTA, --ZERO
       --------------------------------------
       VLBAIXACRED,
       --------------------------------------
       VLBAIXADIFALIQUOTA,
       ---------------------------------------
       DATAINICIOCIAP, -- N.DTENT
       DATAFINALCIAP, -- N.DTTERMINOCIAP
       DATABAIXA, -- null
       VINCULARDOCUMENTOCT, --'N'
       VLCREDFRETE, -- ZERO FIXO
       VLBAIXACREDFRETE,-- ZERO FIXO
       VLDIFALIQUOTAFRETE,-- ZERO FIXO
       VLBAIXADIFALIQUOTAFRETE,-- ZERO FIXO
       CODPRODSEQ,
       ITEMDUPLICADO
 FROM (
 select '05.1 - Bens lançados pela 3402 com termino ciap e que tiveram baixa parcial' AS ID,
        NVL(N.CODFILIALNF, N.CODFILIAL) CODFILIAL,
       N.NUMTRANSENT TRANSACAO,
       'ME' TIPOTRANSACAO,
       M.QTCONT,
       NVL(M.QTMESESCREDCIAP,
           NVL(PARAMFILIAL.OBTERCOMONUMBER('CON_QTMESESCREDCIAP'), 48)) QTMESESCREDCIAP,
       M.CODPROD,
       --ADD_MONTHS(N.DTTERMINOCIAP, 1) DATA,
       N.DTTERMINOCIAP DATA,
       N.NUMNOTA,
       P.DESCRICAO,
       0 VLCREDITO,
       0 VLDIFALIQUOTA,
       --------------------------------------
--       NVL(M.VLCREDITO, 0) -
       ROUND(NVL(M.VLCREDITO, 0) * DECODE(NVL(M.GRAVADOUNITARIO,'S'), 'S', M.QTCONT, 1),2) -
       ROUND((M.VLCREDITO / DECODE(NVL(M.GRAVADOUNITARIO,'S'), 'S',1,M.QTCONT) *
       ((select count(1)
          from PCBENSPATRIMONIAIS
         where NUMTRANSACAO = N.NUMTRANSENT
           and CODPROD = M.CODPROD
           and TIPOTRANSACAO = 'ME'
           and ( (DATABAIXA is not null and databaixa between N.DTENT AND N.DTTERMINOCIAP ))
        ))),2) VLBAIXACRED,
       --------------------------------------
--       NVL(M.VLDIFALIQUOTA, 0) -
       ROUND(NVL(M.VLDIFALIQUOTA, 0) * DECODE(NVL(M.GRAVADOUNITARIO,'S'), 'S',M.QTCONT,1),2) -
       ROUND((M.VLDIFALIQUOTA / DECODE(NVL(M.GRAVADOUNITARIO,'S'), 'S', 1,M.QTCONT) *
       (select count(1)
          from PCBENSPATRIMONIAIS
         where NUMTRANSACAO = N.NUMTRANSENT
           and CODPROD = M.CODPROD
           and TIPOTRANSACAO = 'ME'
           --and DATABAIXA is not null
           --and DATABAIXA < N.DTTERMINOCIAP
           and ( (DATABAIXA is not null and databaixa between N.DTENT AND N.DTTERMINOCIAP ))
           )),2) VLBAIXADIFALIQUOTA,
       ---------------------------------------
       DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP', NVL(N.CODFILIALNF,N.CODFILIAL)), 'M'), 'E', N.DTENT + 1, N.DTENT) DATAINICIOCIAP,
       DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP', NVL(N.CODFILIALNF,N.CODFILIAL)), 'M'), 'E', NVL(M.DTTERMINOCIAP, N.DTTERMINOCIAP) + 1, NVL(M.DTTERMINOCIAP, N.DTTERMINOCIAP)) DATAFINALCIAP,
       null DATABAIXA,
       'N' VINCULARDOCUMENTOCT,
       0 VLCREDFRETE,
       0 VLBAIXACREDFRETE,
       0 VLDIFALIQUOTAFRETE,
       0 VLBAIXADIFALIQUOTAFRETE
       ,M.CODPRODSEQ
       ,M.ITEMDUPLICADO
       -------------------------------------------------------------------------------------------------------------------------
 from PCMOVCIAP  M,
      PCNFENT    N,
      PCPRODCIAP P
 where M.NUMTRANSENT = N.NUMTRANSENT
   and P.CODPROD = M.CODPROD
   and N.VLTOTAL > 0
--   and M.VLCREDITO > 0
   AND ( (M.VLCREDITO > 0) OR (M.VLDIFALIQUOTA > 0))
   and N.ESPECIE = 'NF'
   and NVL(M.TIPOMERC, NVL(P.TIPOMERC, 'IM')) = 'IM'
   and NVL(M.LEASING, 'N') = 'N'

   AND ( (select COUNT(1)
          from PCBENSPATRIMONIAIS B
         where B.NUMTRANSACAO = N.NUMTRANSENT
           and B.CODPROD = M.CODPROD
           and B.TIPOTRANSACAO = 'ME'
           -- Se data da baixa for realizada após a data do terminio porem dentro do mesmo mes deve-se considerar e zerar o crédito do mês.
           and ((B.DATABAIXA is not null) and ((b.databaixa between N.DTENT AND N.DTTERMINOCIAP) OR
                                               (TO_CHAR(b.databaixa,'MMYYYY') = TO_CHAR(N.DTTERMINOCIAP,'MMYYYY') ))
                )) > 0
         AND
         (select COUNT(1)
           from PCBENSPATRIMONIAIS B
          where B.NUMTRANSACAO = N.NUMTRANSENT
            and B.CODPROD = M.CODPROD
            and B.TIPOTRANSACAO = 'ME'
            -- lanc. com baixa superior ao termino deve entrar também como se fosse dtbaixa is null
            and B.DATABAIXA is null OR B.DATABAIXA NOT BETWEEN N.DTENT AND N.DTTERMINOCIAP ) > 0)
            )
        where (nvl(VLBAIXACRED,0) <> 0 or  nvl(VLBAIXADIFALIQUOTA,0) <> 0)
---------------------------------------------------
UNION ALL
---------------------------------------------------
--BAIXA DE BENS COM TERMINO CIAP (LANÇADOS PELA ROTINA 3405)
SELECT '06 - Bens lançados pela 3405 com termino ciap' AS ID,
       N.CODFILIAL,
       N.CODSALDO TRANSACAO,
       'SI' TIPOTRANSACAO,
       1 QTCONT,
       NVL(PARAMFILIAL.OBTERCOMONUMBER('CON_QTMESESCREDCIAP'), 48) QTMESESCREDCIAP,
       N.CODPROD,
       CASE WHEN TO_CHAR(N.DTTERMINOCIAP,'YYYYMM') <= TO_CHAR(ADD_MONTHS(DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP', N.CODFILIAL), 'M'), 'E', N.DATA + 1, N.DATA),NVL(PARAMFILIAL.OBTERCOMONUMBER('CON_QTMESESCREDCIAP'), 48)-1),'YYYYMM') THEN
         ADD_MONTHS(N.DTTERMINOCIAP,1)
       ELSE
         N.DTTERMINOCIAP
       END DATA,
--       ADD_MONTHS(N.DTTERMINOCIAP, 1) DATA,
       N.NUMNOTA,
       P.DESCRICAO,
       0 VLCREDITO,
       0 VLDIFALIQUOTA,
       CASE WHEN (SELECT COUNT(1)
                  FROM PCBENSPATRIMONIAIS
                  WHERE NUMTRANSACAO = N.CODSALDO
                    AND CODPROD = N.CODPROD
                    AND TIPOTRANSACAO = 'SI'
                    AND DATABAIXA IS NOT NULL
                    AND DATABAIXA < N.DTTERMINOCIAP) > 0 THEN
          N.VLCREDITO -
          ROUND(N.VLCREDITO / (SELECT COUNT(1)
                               FROM PCBENSPATRIMONIAIS
                               WHERE NUMTRANSACAO = N.CODSALDO
                                 AND TIPOTRANSACAO = 'SI'
                                 AND CODPROD = N.CODPROD), 2) *
                (SELECT COUNT(1)
                 FROM PCBENSPATRIMONIAIS
                 WHERE NUMTRANSACAO = N.CODSALDO
                   AND CODPROD = N.CODPROD
                   AND TIPOTRANSACAO = 'SI'
                   AND DATABAIXA IS NOT NULL
                   AND DATABAIXA < N.DTTERMINOCIAP)
       ELSE
          N.VLCREDITO
       END VLBAIXACRED,
       N.VLDIFALIQUOTA VLBAIXADIFALIQUOTA,
       DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP', N.CODFILIAL), 'M'), 'E', N.DATA + 1, N.DATA) DATAINICIOCIAP,
       DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('TIPOCALCCIAP', N.CODFILIAL), 'M'), 'E', N.DTTERMINOCIAP + 1, N.DTTERMINOCIAP) DATAFINALCIAP,
       NULL DATABAIXA,
       'N' VINCULARDOCUMENTOCT,
       0 VLCREDFRETE,
       0 VLBAIXACREDFRETE,
       0 VLDIFALIQUOTAFRETE,
       0 VLBAIXADIFALIQUOTAFRETE,
       '' CODPRODSEQ
      ,'N' ITEMDUPLICADO
  FROM PCCIAPSALDOINICIAL N,
       PCPRODCIAP         P
 WHERE P.CODPROD = N.CODPROD
   AND N.VLCREDITO > 0
   AND NOT EXISTS (SELECT 1
                     FROM PCBENSPATRIMONIAIS
                     WHERE NUMTRANSACAO = N.CODSALDO
                       AND CODPROD = N.CODPROD
                       AND TIPOTRANSACAO = 'SI'
                       AND ( (DATABAIXA IS NOT NULL) AND (DATABAIXA BETWEEN N.DATA AND N.DTTERMINOCIAP))
                       )
----------------------------------------------------------------------
-- 001 - 13/12/2021 - Inclusão Novo processo (inclusão de vários produtos com o mesmo codprod - Gleibe
-- 002 - 17/08/2022 - implementado alteração no sql 01 e 05 para as colunas VLDIFALIQUOTAFRETE e VLBAIXADIFALIQUOTAFRETE
-- 003 - 24/08/2022 - Implementado alteração na condição do campo LEASING que passa a ser considerado N quando Nullo.
-- 004 - 05/09/2022 - Alteração no campo Data nos sqls de baixa parcial e baixa por termino ciap
-- 005 - 13/09/2022 - Implementado alteração para considerar o valor VLDIFALIQUOTA para lançamentos da 3405. (Entrada e Baixa)
-- 006 - 01/11/2022 - Implementado alteração no sql '05 - Bens lançados pela 3402 com termino ciap sem baixa parcial' no campo dtterminociap.
-- 007 - 22/12/2023 - Implementado alteração no sql 03.1 para incluir valor de crédito e dif de aliquota para que a baixa não fiq negativa.
-- v001 - 20/05/2025