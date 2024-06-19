CREATE OR REPLACE VIEW VIEW_VENDAS_RESUMO_FATURAMENTO AS
SELECT PCNFSAID.CODUSUR,
       PCMOV.CODUSUR CODUSURMOV,
       (SELECT CODSUPERVISOR FROM PCUSUARI WHERE CODUSUR = PCNFSAID.CODUSUR) AS CODSUPERVISOR,
       CASE
         WHEN PCNFSAID.CODUSUR = PCMOV.CODUSUR THEN
          PCNFSAID.CODSUPERVISOR
         ELSE
          NVL(PCMOVCOMPLE.CODSUPERVISOR,
              (SELECT CODSUPERVISOR
                 FROM PCUSUARI
                WHERE CODUSUR = PCMOV.CODUSUR))
       END AS CODSUPERVMOV,
       (SELECT S.CODCOORDENADOR
          FROM PCSUPERV S
         WHERE S.CODSUPERVISOR = (CASE
                 WHEN PCNFSAID.CODUSUR = PCMOV.CODUSUR THEN
                  PCNFSAID.CODSUPERVISOR
                 ELSE
                  NVL(PCMOVCOMPLE.CODSUPERVISOR,
                      (SELECT CODSUPERVISOR
                         FROM PCUSUARI
                        WHERE CODUSUR = PCMOV.CODUSUR))
               END)) CODCOORDENADOR,
       (SELECT DECODE(S.CODCOORDENADOR,
                      NULL,
                      S.CODGERENTE,
                      (SELECT C.CODGERENTE
                         FROM PCCOORDENADORVENDA C
                        WHERE C.CODIGO = S.CODCOORDENADOR))
          FROM PCSUPERV S
         WHERE S.CODSUPERVISOR = (CASE
                 WHEN PCNFSAID.CODUSUR = PCMOV.CODUSUR THEN
                  PCNFSAID.CODSUPERVISOR
                 ELSE
                  NVL(PCMOVCOMPLE.CODSUPERVISOR,
                      (SELECT CODSUPERVISOR
                         FROM PCUSUARI
                        WHERE CODUSUR = PCMOV.CODUSUR))
               END)) CODGERENTELOCAL,
       (SELECT GR.CODGERENTE
          FROM PCSUPERV S, PCGERENTE GL, PCGERENTE GR
         WHERE (CASE
                 WHEN PCNFSAID.CODUSUR = PCMOV.CODUSUR THEN
                  PCNFSAID.CODSUPERVISOR
                 ELSE
                  NVL(PCMOVCOMPLE.CODSUPERVISOR,
                      (SELECT CODSUPERVISOR
                         FROM PCUSUARI
                        WHERE CODUSUR = PCMOV.CODUSUR))
               END) = S.CODSUPERVISOR
           AND DECODE(S.CODCOORDENADOR,
                      NULL,
                      S.CODGERENTE,
                      (SELECT C.CODGERENTE
                         FROM PCCOORDENADORVENDA C
                        WHERE C.CODIGO = S.CODCOORDENADOR)) = GL.CODGERENTE
           AND GL.CODGERENTESUPERIOR = GR.CODGERENTE(+)) CODGERENTEREGIONAL,
       (SELECT GR.CODGERENTESUPERIOR
          FROM PCSUPERV S, PCGERENTE GL, PCGERENTE GR
         WHERE (CASE
                 WHEN PCNFSAID.CODUSUR = PCMOV.CODUSUR THEN
                  PCNFSAID.CODSUPERVISOR
                 ELSE
                  NVL(PCMOVCOMPLE.CODSUPERVISOR,
                      (SELECT CODSUPERVISOR
                         FROM PCUSUARI
                        WHERE CODUSUR = PCMOV.CODUSUR))
               END) = S.CODSUPERVISOR
           AND DECODE(S.CODCOORDENADOR,
                      NULL,
                      S.CODGERENTE,
                      (SELECT C.CODGERENTE
                         FROM PCCOORDENADORVENDA C
                        WHERE C.CODIGO = S.CODCOORDENADOR)) = GL.CODGERENTE
           AND GL.CODGERENTESUPERIOR = GR.CODGERENTE(+)) CODGERENTENACIONAL,
       (SELECT GN.CODGERENTESUPERIOR
          FROM PCSUPERV S, PCGERENTE GL, PCGERENTE GR, PCGERENTE GN
         WHERE (CASE
                 WHEN PCNFSAID.CODUSUR = PCMOV.CODUSUR THEN
                  PCNFSAID.CODSUPERVISOR
                 ELSE
                  NVL(PCMOVCOMPLE.CODSUPERVISOR,
                      (SELECT CODSUPERVISOR
                         FROM PCUSUARI
                        WHERE CODUSUR = PCMOV.CODUSUR))
               END) = S.CODSUPERVISOR
           AND DECODE(S.CODCOORDENADOR,
                      NULL,
                      S.CODGERENTE,
                      (SELECT C.CODGERENTE
                         FROM PCCOORDENADORVENDA C
                        WHERE C.CODIGO = S.CODCOORDENADOR)) = GL.CODGERENTE
           AND GL.CODGERENTESUPERIOR = GR.CODGERENTE(+)
           AND GR.CODGERENTESUPERIOR = GN.CODGERENTE(+)) CODDIRETOR,
       NVL(PCNFSAID.CODPLPAG, 0) CODPLPAG,
       PCNFSAID.CODPLPAG CODPLPAGMOV,
       PCNFSAID.DTSAIDA,
       PCCLIENT.ESTENT UF,
       PCNFSAID.UF UFMOV,
       PCPRACA.NUMREGIAO,
       PCNFSAID.NUMREGIAO NUMREGIAOMOV,
       PCPRACA.ROTA,
       PCPRACA.CODPRACA,
       PCNFSAID.CODPRACA CODPRACAMOV,
       PCCLIENT.VIP,
       NVL(PCNFSAID.CONDVENDA, 0) CONDVENDA,
       PCNFSAID.CODEMITENTE,
       DECODE(NVL(PCNFSAID.CAIXA, 0), 0, 0, NVL(PCNFSAID.CAIXA, 0)) CAIXA,
       PCPRODUT.CODFORNEC,
       PCMOV.CODFORNEC CODFORNECMOV,
       PCPRODUT.CODPROD,
       PCMOV.CODPROD CODPRODMOV,
       PCPRODUT.CODEPTO,
       PCMOV.CODEPTO CODEPTOMOV,
       PCNFSAID.PRAZOMEDIO,
       PCNFSAID.NUMTRANSVENDA,
       PCNFSAID.CODFILIAL,
       PCNFSAID.CODFILIALNF,
       PCNFSAID.VENDAASSISTIDA,
       PCNFSAID.CODCLI,
       PCNFSAID.SITUACAONFE,
       PCMOV.NUMLOTE,
       PCCLIENT.CODATV1 CODATIV,
       PCNFSAID.CODATV1 CODATIVMOV,
       PCNFSAID.DTCANCEL,
       NVL(ATIVI_PRINCIPAL.CODATIVPRINC, ATIVI_PRINCIPAL.CODATIV) CODATIVPRINC,
       NVL(ATIVIMOV_PRINCIPAL.CODATIVPRINC, ATIVIMOV_PRINCIPAL.CODATIV) CODATIVPRINCMOV,
       (SELECT ORIGEMPED FROM PCPEDC WHERE NUMPED = PCNFSAID.NUMPED) ORIGEMPED,
       PCNFSAID.CODFISCAL,
       PCNFSAID.SERIE,
       PCNFSAID.CODCOB,
       PCNFSAID.ESPECIE,
       PCNFSAID.PRAZOADICIONAL,
       PCNFSAID.NUMITENS,
       (DECODE(NVL(PCMOV.TRUNCARITEM, 'N'),
               'N',
               (ROUND(NVL(PCMOV.QTCONT, 0) *
                      (NVL(PCMOV.PUNITCONT, 0) - NVL(PCMOV.ST, 0) -
                       NVL(PCMOV.VLIPI, 0) - (NVL(PCMOVCOMPLE.VLFECP, 0) + NVL(PCMOVCOMPLE.VLFECPTRANSFCD, 0))),
                      2) + ROUND(PCMOV.QTCONT * (NVL(PCMOV.ST, 0)), 2) +
               ROUND(NVL(PCMOV.QTCONT, 0) * (NVL(PCMOV.VLIPI, 0)), 2)) +
               ROUND(NVL(PCMOV.QTCONT, 0) * (NVL(PCMOVCOMPLE.VLFECP, 0) + NVL(PCMOVCOMPLE.VLFECPTRANSFCD, 0)), 2),
               TRUNC(NVL(PCMOV.QTCONT, 0) * NVL(PCMOV.PUNITCONT, 0), 2))) VLATEND,
       PCMOV.VLDESCONTO,
       PCMOVCOMPLE.VLSUBTOTITEM,
       PCMOV.PUNITCONT,
       PCMOV.VLFRETE,
       PCMOV.VLOUTROS,
       PCMOV.VLFRETE_RATEIO,
       PCMOV.QT,
       PCMOV.QTCONT,
       PCNFSAID.COMISSAO,
       (SELECT CODCOMPRADOR
          FROM PCFORNEC
         WHERE CODFORNEC = PCPRODUT.CODFORNEC) AS CODCOMPRADOR,
       (SELECT CODFORNECPRINC
          FROM PCFORNEC
         WHERE CODFORNEC = PCPRODUT.CODFORNEC) AS CODFORNECPRINC,
       (SELECT SUBSTR(FP.FORNECEDOR, 1, 40)
          FROM PCFORNEC F, PCFORNEC FP
         WHERE F.CODFORNEC = PCPRODUT.CODFORNEC
           AND FP.CODFORNEC = F.CODFORNECPRINC) AS FORNECPRINC,
       NVL(ROUND(case
                   when PCMOV.CODOPER in ('S', 'ST', 'SM', 'SB') then
                    (NVL(DECODE(PCNFSAID.CONDVENDA,
                                7,
                                DECODE(PCMOV.TIPOITEM, 'N', PCMOV.QTCONT, PCMOV.QT),
                                PCMOV.QT),
                         0))
                   else
                    0
                 end * (NVL(PCMOV.VLOUTROS, 0) -
                 DECODE(NVL(PCNFSAID.SOMAREPASSEOUTRASDESPNF, 'N'),
                               'S',
                               NVL(PCMOV.VLREPASSE, 0),
                               0)),
                 2),
           0) VLOUTRASDESP,
       PCPRODUT.CODSEC,
       PCPRODUT.CODCATEGORIA,
       PCPRODUT.CODSUBCATEGORIA,
       PCNFSAID.CODCLI QTCLIENTE,
       NVL(DECODE(PCNFSAID.CONDVENDA,
                  7,
                  DECODE(PCMOV.TIPOITEM,
                         'N',
                         NVL(DECODE(NVL(PCNFSAID.SOMAREPASSEOUTRASDESPNF, 'N'),
                                    'S',
                                    PCMOV.PUNIT,
                                    PCMOV.PUNITCONT),
                             0),
                         PCMOV.PUNIT),
                  DECODE(PCMOV.TIPOITEM,
                         'N',
                         NVL(DECODE(NVL(PCNFSAID.SOMAREPASSEOUTRASDESPNF, 'N'),
                                    'S',
                                    PCMOV.PUNIT,
                                    PCMOV.PUNITCONT),
                             0),
                         PCMOV.PUNIT)),
           0) PUNIT,
       PCMOV.CODOPER,
       PCNFSAID.NUMNOTA,
       (SELECT NVL((PCEST.QTESTGER - PCEST.QTBLOQUEADA - PCEST.QTPENDENTE -
                   PCEST.QTRESERV),
                   0)
          FROM PCEST
         WHERE CODFILIAL = PCMOV.CODFILIAL
           AND CODPROD = PCMOV.CODPROD) AS VLESTDISP,
       (SELECT PCEST.CUSTOFIN
          FROM PCEST
         WHERE CODFILIAL = PCMOV.CODFILIAL
           AND CODPROD = PCMOV.CODPROD) AS CUSTOFIN,
       (SELECT PCEST.CUSTOREAL
          FROM PCEST
         WHERE CODFILIAL = PCMOV.CODFILIAL
           AND CODPROD = PCMOV.CODPROD) AS CUSTOREAL,
       NVL(ROUND(NVL(PCPRODUT.PESOBRUTO, 0) * NVL(PCMOV.QT, 0), 2), 0) AS PESOBRUTO,
       NVL(ROUND(NVL(PCMOV.PESOBRUTO, 0) * NVL(PCMOV.QT, 0), 2), 0) AS PESOBRUTOMOV,
       ROUND(NVL((NVL(PCMOV.QT, 0) *
                 DECODE(PCNFSAID.CONDVENDA,
                         5,
                         0,
                         6,
                         0,
                         NVL(PCMOV.PTABELA, 0) + NVL(PCMOV.VLFRETE, 0) +
                         NVL(PCMOV.VLOUTRASDESP, 0) +
                         NVL(PCMOV.VLFRETE_RATEIO, 0) +
                         NVL(PCMOV.VLOUTROS, 0) -
                         DECODE(NVL(PCNFSAID.SOMAREPASSEOUTRASDESPNF, 'N'),
                                'S',
                                NVL(PCMOV.VLREPASSE, 0),
                                0) - DECODE(NVL(PCMOVCOMPLE.BONIFIC, 'N'),
                                            'F',
                                            NVL(PCMOV.PBONIFIC, 0),
                                            0) - NVL(PCMOV.VLREPASSE, 0))),
                 0),
             2) VLTABELA,
       NVL(ROUND(case
                   when PCMOV.CODOPER in ('S', 'ST', 'SB', 'SM') then
                    (NVL(DECODE(PCNFSAID.CONDVENDA,
                                7,
                                DECODE(PCMOV.TIPOITEM, 'N', PCMOV.QTCONT, PCMOV.QT),
                                PCMOV.QT),
                         0))
                   else
                    0
                 end * (NVL(PCMOV.CUSTOFINEST, 0)),
                 2),
           0) CUSTOFINEST,
       NVL((DECODE(PCMOV.CODOPER,
                   'S',
                   (NVL(DECODE(PCNFSAID.CONDVENDA,
                               7,
                               DECODE(PCMOV.TIPOITEM,
                                      'N',
                                      PCMOV.QTCONT,
                                      PCMOV.QT),
                               PCMOV.QT),
                        0)),
                   'SM',
                   (NVL(DECODE(PCNFSAID.CONDVENDA,
                               7,
                               DECODE(PCMOV.TIPOITEM,
                                      'N',
                                      PCMOV.QTCONT,
                                      PCMOV.QT),
                               PCMOV.QT),
                        0)),
                   'ST',
                   (NVL(DECODE(PCNFSAID.CONDVENDA,
                               7,
                               DECODE(PCMOV.TIPOITEM,
                                      'N',
                                      PCMOV.QTCONT,
                                      PCMOV.QT),
                               PCMOV.QT),
                        0)),
                   0)),
           0) QTVENDA,
       NVL(ROUND((DECODE(PCMOV.CODOPER,
                         'S',
                         (NVL(DECODE(PCNFSAID.CONDVENDA,
                                     7,
                                     DECODE(PCMOV.TIPOITEM,
                                            'N',
                                            PCMOV.QTCONT,
                                            PCMOV.QT),
                                     PCMOV.QT),
                              0)),
                         'ST',
                         (NVL(DECODE(PCNFSAID.CONDVENDA,
                                     7,
                                     DECODE(PCMOV.TIPOITEM,
                                            'N',
                                            PCMOV.QTCONT,
                                            PCMOV.QT),
                                     PCMOV.QT),
                              0)),
                         'SM',
                         (NVL(DECODE(PCNFSAID.CONDVENDA,
                                     7,
                                     DECODE(PCMOV.TIPOITEM,
                                            'N',
                                            PCMOV.QTCONT,
                                            PCMOV.QT),
                                     PCMOV.QT),
                              0)),
                         0)) * (NVL(PCMOV.CUSTOFIN, 0)),
                 2),
           0) VLCUSTOFIN,
       NVL(ROUND((DECODE(PCMOV.CODOPER,
                         'S',
                         (NVL(DECODE(PCNFSAID.CONDVENDA,
                                     7,
                                     DECODE(PCMOV.TIPOITEM,
                                            'N',
                                            PCMOV.QTCONT,
                                            PCMOV.QT),
                                     PCMOV.QT),
                              0)),
                         'ST',
                         (NVL(DECODE(PCNFSAID.CONDVENDA,
                                     7,
                                     DECODE(PCMOV.TIPOITEM,
                                            'N',
                                            PCMOV.QTCONT,
                                            PCMOV.QT),
                                     PCMOV.QT),
                              0)),
                         'SM',
                         (NVL(DECODE(PCNFSAID.CONDVENDA,
                                     7,
                                     DECODE(PCMOV.TIPOITEM,
                                            'N',
                                            PCMOV.QTCONT,
                                            PCMOV.QT),
                                     PCMOV.QT),
                              0)),
                         0)) * (NVL(PCMOV.CUSTOREP, 0)),
                 2),
           0) VLCUSTOREP,
       NVL(ROUND((DECODE(PCMOV.CODOPER,
                         'S',
                         (NVL(DECODE(PCNFSAID.CONDVENDA,
                                     7,
                                     DECODE(PCMOV.TIPOITEM,
                                            'N',
                                            PCMOV.QTCONT,
                                            PCMOV.QT),
                                     PCMOV.QT),
                              0)),
                         'ST',
                         (NVL(DECODE(PCNFSAID.CONDVENDA,
                                     7,
                                     DECODE(PCMOV.TIPOITEM,
                                            'N',
                                            PCMOV.QTCONT,
                                            PCMOV.QT),
                                     PCMOV.QT),
                              0)),
                         'SM',
                         (NVL(DECODE(PCNFSAID.CONDVENDA,
                                     7,
                                     DECODE(PCMOV.TIPOITEM,
                                            'N',
                                            PCMOV.QTCONT,
                                            PCMOV.QT),
                                     PCMOV.QT),
                              0)),
                         0)) * (NVL(PCMOV.CUSTOCONT, 0)),
                 2),
           0) VLCUSTOCONT,
       NVL(ROUND((DECODE(PCMOV.CODOPER,
                         'S',
                         (NVL(DECODE(PCNFSAID.CONDVENDA,
                                     7,
                                     DECODE(PCMOV.TIPOITEM,
                                            'N',
                                            PCMOV.QTCONT,
                                            PCMOV.QT),
                                     PCMOV.QT),
                              0)),
                         'ST',
                         (NVL(DECODE(PCNFSAID.CONDVENDA,
                                     7,
                                     DECODE(PCMOV.TIPOITEM,
                                            'N',
                                            PCMOV.QTCONT,
                                            PCMOV.QT),
                                     PCMOV.QT),
                              0)),
                         'SM',
                         (NVL(DECODE(PCNFSAID.CONDVENDA,
                                     7,
                                     DECODE(PCMOV.TIPOITEM,
                                            'N',
                                            PCMOV.QTCONT,
                                            PCMOV.QT),
                                     PCMOV.QT),
                              0)),
                         'SB',
                         (NVL(DECODE(PCNFSAID.CONDVENDA,
                                     1,
                                     CASE
                                       WHEN NVL(PCMOVCOMPLE.BONIFIC, 'N') = 'F' THEN
                                        PCMOV.QT
                                       ELSE
                                        0
                                     END,
                                     7,
                                     DECODE(PCMOV.TIPOITEM,
                                            'N',
                                            PCMOV.QTCONT,
                                            PCMOV.QT),
                                     PCMOV.QT),
                              0)),
                         0)) * (NVL(PCMOV.CUSTOFIN, 0)),
                 2),
           0) VLCUSTOFINB,
       NVL(ROUND((DECODE(PCMOV.CODOPER,
                         'SB',
                         (NVL(DECODE(PCNFSAID.CONDVENDA,
                                     1,
                                     CASE
                                       WHEN NVL(PCMOVCOMPLE.BONIFIC, 'N') = 'F' THEN
                                        PCMOV.QT
                                       ELSE
                                        0
                                     END,
                                     7,
                                     DECODE(PCMOV.TIPOITEM,
                                            'N',
                                            PCMOV.QTCONT,
                                            PCMOV.QT),
                                     PCMOV.QT),
                              0)),
                         0)) * (NVL(PCMOV.CUSTOFIN, 0)),
                 2),
           0) VLCUSTOFINBONIF,
       PCMOVCOMPLE.BONIFIC,
       NVL(ROUND((DECODE(PCMOV.CODOPER,
                         'S',
                         (NVL(DECODE(PCNFSAID.CONDVENDA,
                                     7,
                                     DECODE(PCMOV.TIPOITEM,
                                            'N',
                                            PCMOV.QTCONT,
                                            PCMOV.QT),
                                     PCMOV.QT),
                              0)),
                         'ST',
                         (NVL(DECODE(PCNFSAID.CONDVENDA,
                                     7,
                                     DECODE(PCMOV.TIPOITEM,
                                            'N',
                                            PCMOV.QTCONT,
                                            PCMOV.QT),
                                     PCMOV.QT),
                              0)),
                         'SM',
                         (NVL(DECODE(PCNFSAID.CONDVENDA,
                                     7,
                                     DECODE(PCMOV.TIPOITEM,
                                            'N',
                                            PCMOV.QTCONT,
                                            PCMOV.QT),
                                     PCMOV.QT),
                              0)),
                         0)) * (NVL(PCMOV.CUSTOREAL, 0)),
                 2),
           0) VLCUSTOREAL,
       ROUND(NVL(NVL((CASE
                       WHEN ROUND(PCMOVCOMPLE.VLSUBTOTITEM, 2) IS NOT NULL THEN
                        (CASE
                          WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) = 'DEDUZIRFRETE' THEN
                           (DECODE(PCMOV.CODOPER,
                                   'S',
                                   (NVL(DECODE(PCNFSAID.CONDVENDA,
                                               5,
                                               0,
                                               6,
                                               0,
                                               11,
                                               0,
                                               12,
                                               0,
                                               DECODE(PCMOV.CODOPER,
                                                      'SB',
                                                      0,
                                                      ROUND(PCMOVCOMPLE.VLSUBTOTITEM, 2))),
                                        0)),
                                   'ST',
                                   (NVL(DECODE(PCNFSAID.CONDVENDA,
                                               5,
                                               0,
                                               6,
                                               0,
                                               11,
                                               0,
                                               12,
                                               0,
                                               DECODE(PCMOV.CODOPER,
                                                      'SB',
                                                      0,
                                                      ROUND(PCMOVCOMPLE.VLSUBTOTITEM, 2))),
                                        0)),
                                   'SM',
                                   (NVL(DECODE(PCNFSAID.CONDVENDA,
                                               5,
                                               0,
                                               6,
                                               0,
                                               11,
                                               0,
                                               12,
                                               0,
                                               DECODE(PCMOV.CODOPER,
                                                      'SB',
                                                      0,
                                                      ROUND(PCMOVCOMPLE.VLSUBTOTITEM, 2))),
                                        0)),
                                   0) - (ROUND(NVL(PCMOV.VLFRETE, 0), 2) * PCMOV.QT))
                          WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) =
                               'DEDUZIROUTRASDESP' THEN
                           (DECODE(PCMOV.CODOPER,
                                   'S',
                                   (NVL(DECODE(PCNFSAID.CONDVENDA,
                                               5,
                                               0,
                                               6,
                                               0,
                                               11,
                                               0,
                                               12,
                                               0,
                                               DECODE(PCMOV.CODOPER,
                                                      'SB',
                                                      0,
                                                      ROUND(PCMOVCOMPLE.VLSUBTOTITEM, 2))),
                                        0)),
                                   'ST',
                                   (NVL(DECODE(PCNFSAID.CONDVENDA,
                                               5,
                                               0,
                                               6,
                                               0,
                                               11,
                                               0,
                                               12,
                                               0,
                                               DECODE(PCMOV.CODOPER,
                                                      'SB',
                                                      0,
                                                      ROUND(PCMOVCOMPLE.VLSUBTOTITEM, 2))),
                                        0)),
                                   'SM',
                                   (NVL(DECODE(PCNFSAID.CONDVENDA,
                                               5,
                                               0,
                                               6,
                                               0,
                                               11,
                                               0,
                                               12,
                                               0,
                                               DECODE(PCMOV.CODOPER,
                                                      'SB',
                                                      0,
                                                      ROUND(PCMOVCOMPLE.VLSUBTOTITEM, 2))),
                                        0)),
                                   0) - (ROUND(NVL(PCMOV.vLOUTROS, 0), 2) * PCMOV.QT))
                          WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) = 'DEDUZIRAMBOS' THEN
                           (DECODE(PCMOV.CODOPER,
                                   'S',
                                   (NVL(DECODE(PCNFSAID.CONDVENDA,
                                               5,
                                               0,
                                               6,
                                               0,
                                               11,
                                               0,
                                               12,
                                               0,
                                               DECODE(PCMOV.CODOPER,
                                                      'SB',
                                                      0,
                                                      ROUND(PCMOVCOMPLE.VLSUBTOTITEM, 2))),
                                        0)),
                                   'ST',
                                   (NVL(DECODE(PCNFSAID.CONDVENDA,
                                               5,
                                               0,
                                               6,
                                               0,
                                               11,
                                               0,
                                               12,
                                               0,
                                               DECODE(PCMOV.CODOPER,
                                                      'SB',
                                                      0,
                                                      ROUND(PCMOVCOMPLE.VLSUBTOTITEM, 2))),
                                        0)),
                                   'SM',
                                   (NVL(DECODE(PCNFSAID.CONDVENDA,
                                               5,
                                               0,
                                               6,
                                               0,
                                               11,
                                               0,
                                               12,
                                               0,
                                               DECODE(PCMOV.CODOPER,
                                                      'SB',
                                                      0,
                                                      ROUND(PCMOVCOMPLE.VLSUBTOTITEM, 2))),
                                        0)),
                                   0) - (ROUND(NVL(PCMOV.VLFRETE, 0), 2) * PCMOV.QT) -
                           (ROUND(NVL(PCMOV.VLOUTROS, 0), 2) * PCMOV.QT))
                          ELSE
                           ROUND(PCMOVCOMPLE.VLSUBTOTITEM, 2)
                        END)
                       ELSE
                        NULL
                     END),
                     (ROUND((DECODE(PCMOV.CODOPER,
                                    'S',
                                    (NVL(DECODE(PCNFSAID.CONDVENDA,
                                                5,
                                                0,
                                                6,
                                                0,
                                                11,
                                                0,
                                                12,
                                                0,
                                                DECODE(PCMOV.CODOPER,
                                                       'SB',
                                                       0,
                                                       DECODE(PCMOV.TIPOITEM,
                                                              'N',
                                                              PCMOV.QTCONT,
                                                              PCMOV.QT))),
                                         0)),
                                    'ST',
                                    (NVL(DECODE(PCNFSAID.CONDVENDA,
                                                5,
                                                0,
                                                6,
                                                0,
                                                11,
                                                0,
                                                12,
                                                0,
                                                DECODE(PCMOV.CODOPER,
                                                       'SB',
                                                       0,
                                                       DECODE(PCMOV.TIPOITEM,
                                                              'N',
                                                              PCMOV.QTCONT,
                                                              PCMOV.QT))),
                                         0)),
                                    'SM',
                                    (NVL(DECODE(PCNFSAID.CONDVENDA,
                                                5,
                                                0,
                                                6,
                                                0,
                                                11,
                                                0,
                                                12,
                                                0,
                                                DECODE(PCMOV.CODOPER,
                                                       'SB',
                                                       0,
                                                       DECODE(PCMOV.TIPOITEM,
                                                              'N',
                                                              PCMOV.QTCONT,
                                                              PCMOV.QT))),
                                         0)),
                                    0)) *
                            ((CASE
                              WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) = 'DEDUZIRFRETE' THEN
                               (NVL(DECODE(PCNFSAID.CONDVENDA,
                                           7,
                                           DECODE(PCMOV.TIPOITEM,
                                                  'N',
                                                  NVL(DECODE(NVL(PCNFSAID.SOMAREPASSEOUTRASDESPNF,
                                                                 'N'),
                                                             'S',
                                                             PCMOV.PUNIT,
                                                             PCMOV.PUNITCONT),
                                                      0),
                                                  PCMOV.PUNIT) + NVL(PCMOV.VLOUTRASDESP, 0) +
                                           NVL(PCMOV.VLFRETE_RATEIO, 0) + NVL(PCMOV.VLOUTROS, 0) -
                                           DECODE(NVL(PCNFSAID.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                  'S',
                                                  NVL(PCMOV.VLREPASSE, 0),
                                                  0),
                                           NVL(DECODE(PCMOV.TIPOITEM,
                                                      'N',
                                                      NVL(DECODE(NVL(PCNFSAID.SOMAREPASSEOUTRASDESPNF,
                                                                     'N'),
                                                                 'S',
                                                                 PCMOV.PUNIT,
                                                                 PCMOV.PUNITCONT),
                                                          0),
                                                      PCMOV.PUNIT),
                                               0) + NVL(PCMOV.VLOUTRASDESP, 0) +
                                           NVL(PCMOV.VLFRETE_RATEIO, 0) + NVL(PCMOV.VLOUTROS, 0) -
                                           DECODE(NVL(PCNFSAID.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                  'S',
                                                  NVL(PCMOV.VLREPASSE, 0),
                                                  0)),
                                    0))
                              WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) =
                                   'DEDUZIROUTRASDESP' THEN
                               (NVL(DECODE(PCNFSAID.CONDVENDA,
                                           7,
                                           DECODE(PCMOV.TIPOITEM,
                                                  'N',
                                                  NVL(DECODE(NVL(PCNFSAID.SOMAREPASSEOUTRASDESPNF,
                                                                 'N'),
                                                             'S',
                                                             PCMOV.PUNIT,
                                                             PCMOV.PUNITCONT),
                                                      0),
                                                  PCMOV.PUNIT) + NVL(PCMOV.VLFRETE, 0) +
                                           NVL(PCMOV.VLFRETE_RATEIO, 0) +
                                           NVL(PCMOV.VLOUTRASDESP, 0),
                                           NVL(DECODE(PCMOV.TIPOITEM,
                                                      'N',
                                                      NVL(DECODE(NVL(PCNFSAID.SOMAREPASSEOUTRASDESPNF,
                                                                     'N'),
                                                                 'S',
                                                                 PCMOV.PUNIT,
                                                                 PCMOV.PUNITCONT),
                                                          0),
                                                      PCMOV.PUNIT),
                                               0) + NVL(PCMOV.VLFRETE, 0) +
                                           NVL(PCMOV.VLFRETE_RATEIO, 0) +
                                           NVL(PCMOV.VLOUTRASDESP, 0)),
                                    0))
                              WHEN (SELECT TIPOVLVENDA FROM PCPARAMPLANOVOO) = 'DEDUZIRAMBOS' THEN
                               (NVL(DECODE(PCNFSAID.CONDVENDA,
                                           7,
                                           DECODE(PCMOV.TIPOITEM,
                                                  'N',
                                                  NVL(DECODE(NVL(PCNFSAID.SOMAREPASSEOUTRASDESPNF,
                                                                 'N'),
                                                             'S',
                                                             PCMOV.PUNIT,
                                                             PCMOV.PUNITCONT),
                                                      0),
                                                  PCMOV.PUNIT) + NVL(PCMOV.VLFRETE_RATEIO, 0) +
                                           NVL(PCMOV.VLOUTRASDESP, 0),
                                           NVL(DECODE(PCMOV.TIPOITEM,
                                                      'N',
                                                      NVL(DECODE(NVL(PCNFSAID.SOMAREPASSEOUTRASDESPNF,
                                                                     'N'),
                                                                 'S',
                                                                 PCMOV.PUNIT,
                                                                 PCMOV.PUNITCONT),
                                                          0),
                                                      PCMOV.PUNIT),
                                               0) + NVL(PCMOV.VLFRETE_RATEIO, 0) +
                                           NVL(PCMOV.VLOUTRASDESP, 0)),
                                    0))
                              ELSE
                               (NVL(DECODE(PCNFSAID.CONDVENDA,
                                           7,
                                           DECODE(PCMOV.TIPOITEM,
                                                  'N',
                                                  NVL(DECODE(NVL(PCNFSAID.SOMAREPASSEOUTRASDESPNF,
                                                                 'N'),
                                                             'S',
                                                             PCMOV.PUNIT,
                                                             PCMOV.PUNITCONT),
                                                      0),
                                                  PCMOV.PUNIT) + NVL(PCMOV.VLFRETE, 0) +
                                           NVL(PCMOV.VLOUTRASDESP, 0) +
                                           NVL(PCMOV.VLFRETE_RATEIO, 0) + NVL(PCMOV.VLOUTROS, 0) -
                                           DECODE(NVL(PCNFSAID.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                  'S',
                                                  NVL(PCMOV.VLREPASSE, 0),
                                                  0),
                                           NVL(DECODE(PCMOV.TIPOITEM,
                                                      'N',
                                                      NVL(DECODE(NVL(PCNFSAID.SOMAREPASSEOUTRASDESPNF,
                                                                     'N'),
                                                                 'S',
                                                                 PCMOV.PUNIT,
                                                                 PCMOV.PUNITCONT),
                                                          0),
                                                      PCMOV.PUNIT),
                                               0) + NVL(PCMOV.VLFRETE, 0) +
                                           NVL(PCMOV.VLOUTRASDESP, 0) +
                                           NVL(PCMOV.VLFRETE_RATEIO, 0) + NVL(PCMOV.VLOUTROS, 0) -
                                           DECODE(NVL(PCNFSAID.SOMAREPASSEOUTRASDESPNF, 'N'),
                                                  'S',
                                                  NVL(PCMOV.VLREPASSE, 0),
                                                  0)),
                                    0))
                            END) - NVL(PCMOV.VLIPI, 0) - NVL(PCMOV.ST, 0) - (NVL(PCMOVCOMPLE.VLFECP, 0) + NVL(PCMOVCOMPLE.VLFECPTRANSFCD, 0))),
                            2)) + ROUND(NVL(PCMOV.VLIPI, 0) *
                                        (DECODE(PCMOV.CODOPER,
                                                'S',
                                                (NVL(DECODE(PCNFSAID.CONDVENDA,
                                                            5,
                                                            0,
                                                            6,
                                                            0,
                                                            11,
                                                            0,
                                                            12,
                                                            0,
                                                            DECODE(PCMOV.CODOPER,
                                                                   'SB',
                                                                   0,
                                                                   DECODE(PCMOV.TIPOITEM,
                                                                          'N',
                                                                          PCMOV.QTCONT,
                                                                          PCMOV.QT))),
                                                     0)),
                                                'ST',
                                                (NVL(DECODE(PCNFSAID.CONDVENDA,
                                                            5,
                                                            0,
                                                            6,
                                                            0,
                                                            11,
                                                            0,
                                                            12,
                                                            0,
                                                            DECODE(PCMOV.CODOPER,
                                                                   'SB',
                                                                   0,
                                                                   DECODE(PCMOV.TIPOITEM,
                                                                          'N',
                                                                          PCMOV.QTCONT,
                                                                          PCMOV.QT))),
                                                     0)),
                                                'SM',
                                                (NVL(DECODE(PCNFSAID.CONDVENDA,
                                                            5,
                                                            0,
                                                            6,
                                                            0,
                                                            11,
                                                            0,
                                                            12,
                                                            0,
                                                            DECODE(PCMOV.CODOPER,
                                                                   'SB',
                                                                   0,
                                                                   DECODE(PCMOV.TIPOITEM,
                                                                          'N',
                                                                          PCMOV.QTCONT,
                                                                          PCMOV.QT))),
                                                     0)),
                                                0)),
                                        2) +
                     ROUND(NVL(PCMOV.ST, 0) * (DECODE(PCMOV.CODOPER,
                                                      'S',
                                                      (NVL(DECODE(PCNFSAID.CONDVENDA,
                                                                  5,
                                                                  0,
                                                                  6,
                                                                  0,
                                                                  11,
                                                                  0,
                                                                  12,
                                                                  0,
                                                                  DECODE(PCMOV.CODOPER,
                                                                         'SB',
                                                                         0,
                                                                         DECODE(PCMOV.TIPOITEM,
                                                                                'N',
                                                                                PCMOV.QTCONT,
                                                                                PCMOV.QT))),
                                                           0)),
                                                      'ST',
                                                      (NVL(DECODE(PCNFSAID.CONDVENDA,
                                                                  5,
                                                                  0,
                                                                  6,
                                                                  0,
                                                                  11,
                                                                  0,
                                                                  12,
                                                                  0,
                                                                  DECODE(PCMOV.CODOPER,
                                                                         'SB',
                                                                         0,
                                                                         DECODE(PCMOV.TIPOITEM,
                                                                                'N',
                                                                                PCMOV.QTCONT,
                                                                                PCMOV.QT))),
                                                           0)),
                                                      'SM',
                                                      (NVL(DECODE(PCNFSAID.CONDVENDA,
                                                                  5,
                                                                  0,
                                                                  6,
                                                                  0,
                                                                  11,
                                                                  0,
                                                                  12,
                                                                  0,
                                                                  DECODE(PCMOV.CODOPER,
                                                                         'SB',
                                                                         0,
                                                                         DECODE(PCMOV.TIPOITEM,
                                                                                'N',
                                                                                PCMOV.QTCONT,
                                                                                PCMOV.QT))),
                                                           0)),
                                                      0)),
                           2) +
                     ROUND((NVL(PCMOVCOMPLE.VLFECP, 0) + NVL(PCMOVCOMPLE.VLFECPTRANSFCD, 0)) * 
                           (DECODE(PCMOV.CODOPER,
                                   'S',
                                   (NVL(DECODE(PCNFSAID.CONDVENDA,
                                               5,
                                               0,
                                               6,
                                               0,
                                               11,
                                               0,
                                               12,
                                               0,
                                               DECODE(PCMOV.CODOPER,
                                                      'SB',
                                                      0,
                                                      DECODE(PCMOV.TIPOITEM,
                                                             'N',
                                                             PCMOV.QTCONT,
                                                             PCMOV.QT))),
                                        0)),
                                   'ST',
                                   (NVL(DECODE(PCNFSAID.CONDVENDA,
                                               5,
                                               0,
                                               6,
                                               0,
                                               11,
                                               0,
                                               12,
                                               0,
                                               DECODE(PCMOV.CODOPER,
                                                      'SB',
                                                      0,
                                                      DECODE(PCMOV.TIPOITEM,
                                                             'N',
                                                             PCMOV.QTCONT,
                                                             PCMOV.QT))),
                                        0)),
                                   'SM',
                                   (NVL(DECODE(PCNFSAID.CONDVENDA,
                                               5,
                                               0,
                                               6,
                                               0,
                                               11,
                                               0,
                                               12,
                                               0,
                                               DECODE(PCMOV.CODOPER,
                                                      'SB',
                                                      0,
                                                      DECODE(PCMOV.TIPOITEM,
                                                             'N',
                                                             PCMOV.QTCONT,
                                                             PCMOV.QT))),
                                        0)),
                                   0)),
                           2)),
                 0),
             2) VLVENDA,
       NVL(NVL(PCMOV.QTCONT, 0) *
           DECODE(PCNFSAID.CONDVENDA,
                  5,
                  DECODE(NVL(PCMOV.PBONIFIC, 0),
                         0,
                         PCMOV.PTABELA + NVL(PCMOV.VLDESCONTO, 0),
                         PCMOV.PBONIFIC + NVL(PCMOV.VLDESCONTO, 0)),
                  6,
                  DECODE(NVL(PCMOV.PBONIFIC, 0),
                         0,
                         PCMOV.PTABELA + NVL(PCMOV.VLDESCONTO, 0),
                         PCMOV.PBONIFIC + NVL(PCMOV.VLDESCONTO, 0)),
                  11,
                  DECODE(NVL(PCMOV.PBONIFIC, 0),
                         0,
                         PCMOV.PTABELA + NVL(PCMOV.VLDESCONTO, 0),
                         PCMOV.PBONIFIC + NVL(PCMOV.VLDESCONTO, 0)),
                  12,
                  DECODE(NVL(PCMOV.PBONIFIC, 0),
                         0,
                         PCMOV.PTABELA + NVL(PCMOV.VLDESCONTO, 0),
                         PCMOV.PBONIFIC + NVL(PCMOV.VLDESCONTO, 0)),
                  1,
                  CASE
                    WHEN PCMOV.CODOPER = 'SB' THEN
                     NVL(PCMOV.PBONIFIC, 0)
                    ELSE
                     0
                  END,
                  14,
                  CASE
                    WHEN PCMOV.CODOPER = 'SB' THEN
                     NVL(PCMOV.PBONIFIC, 0)
                    ELSE
                     0
                  END,
                  0),
           0) VLBONIFIC,
       NVL(NVL(PCMOV.QTCONT, 0) * DECODE(PCNFSAID.CONDVENDA,
                                         5,
                                         PCMOV.PBONIFIC,
                                         6,
                                         PCMOV.PBONIFIC,
                                         11,
                                         PCMOV.PBONIFIC,
                                         12,
                                         PCMOV.PBONIFIC,
                                         1,
                                         CASE
                                           WHEN PCMOV.CODOPER = 'SB' THEN
                                            NVL(PCMOV.PBONIFIC, 0)
                                           ELSE
                                            0
                                         END,
                                         14,
                                         CASE
                                           WHEN PCMOV.CODOPER = 'SB' THEN
                                            NVL(PCMOV.PBONIFIC, 0)
                                           ELSE
                                            0
                                         END,
                                         0),
           0) VLBONIFIC2,
       NVL((NVL(PCMOV.QT, 0) * DECODE(PCNFSAID.CONDVENDA,
                                      5,
                                      1,
                                      6,
                                      1,
                                      11,
                                      1,
                                      12,
                                      1,
                                      1,
                                      CASE
                                        WHEN PCMOV.CODOPER = 'SB' THEN
                                         1
                                        ELSE
                                         0
                                      END)),
           0) QTBONIFIC,
       (CASE
         WHEN ((PCMOV.CODOPER = 'SB')) THEN
          0
         ELSE
          (NVL(PCMOV.VLIPI, 0) * NVL(PCMOV.QT, 0))
       END) VLIPI,
       (CASE
         WHEN ((PCMOV.CODOPER = 'SB')) THEN
          (NVL(PCMOV.VLIPI, 0) * NVL(PCMOV.QT, 0))
         ELSE
          0
       END) VLIPIBONIFIC,
       (CASE
         WHEN ((PCMOV.CODOPER = 'SB')) THEN
          0
         ELSE
          (NVL(ROUND(DECODE(PCNFSAID.CONDVENDA,
                            7,
                            DECODE(NVL(PCMOV.TIPOITEM, 'C'),
                                   'C',
                                   PCMOV.QT,
                                   PCMOV.QTCONT) *
                            (NVL(PCMOV.ST, 0) +
                             NVL(PCMOVCOMPLE.VLSTTRANSFCD, 0)),
                            PCMOV.QT * (NVL(PCMOV.ST, 0) +
                            NVL(PCMOVCOMPLE.VLSTTRANSFCD, 0))),
                     2),
               0))
       END) ICMSRETIDO,
       (CASE
         WHEN ((PCMOV.CODOPER = 'SB')) THEN
          (NVL(ROUND(DECODE(PCNFSAID.CONDVENDA,
                            7,
                            DECODE(NVL(PCMOV.TIPOITEM, 'C'),
                                   'C',
                                   PCMOV.QT,
                                   PCMOV.QTCONT) *
                            (NVL(PCMOV.ST, 0) +
                             NVL(PCMOVCOMPLE.VLSTTRANSFCD, 0)),
                            PCMOV.QT * (NVL(PCMOV.ST, 0) +
                            NVL(PCMOVCOMPLE.VLSTTRANSFCD, 0))),
                     2),
               0))
         ELSE
          0
       END) ICMSRETIDOBONIFIC, /*Campos acrescentados para atender a consolidação de dados na 504 e 507*/
       (CASE
         WHEN ((PCMOV.CODOPER = 'SB')) THEN
          0
         ELSE
          (NVL(ROUND(DECODE(PCNFSAID.CONDVENDA,
                            7,
                            DECODE(NVL(PCMOV.TIPOITEM, 'C'),
                                   'C',
                                   PCMOV.QT,
                                   PCMOV.QTCONT) *
                            (NVL(PCMOVCOMPLE.VLFECP, 0) +
                             NVL(PCMOVCOMPLE.VLFECPTRANSFCD, 0)),
                            PCMOV.QT * (NVL(PCMOVCOMPLE.VLFECP, 0) +
                            NVL(PCMOVCOMPLE.VLFECPTRANSFCD, 0))),
                     2),
               0))
       END) VLFECP,
       (CASE
         WHEN ((PCMOV.CODOPER = 'SB')) THEN
          (NVL(ROUND(DECODE(PCNFSAID.CONDVENDA,
                            7,
                            DECODE(NVL(PCMOV.TIPOITEM, 'C'),
                                   'C',
                                   PCMOV.QT,
                                   PCMOV.QTCONT) *
                            (NVL(PCMOVCOMPLE.VLFECP, 0) +
                             NVL(PCMOVCOMPLE.VLFECPTRANSFCD, 0)),
                            PCMOV.QT * (NVL(PCMOVCOMPLE.VLFECP, 0) +
                            NVL(PCMOVCOMPLE.VLFECPTRANSFCD, 0))),
                     2),
               0))
       
         ELSE
          0
       END) VLFECPBONIFIC,
       TRUNC((DECODE(PCMOV.CODOPER,
                     'E',
                     (NVL(PCMOV.QT, 0)),
                     'EB',
                     (NVL(PCMOV.QT, 0)),
                     0)) * (NVL(PCMOV.PUNIT, 0)),
             6) VLENT,
       TRUNC((DECODE(PCMOV.CODOPER,
                     'E',
                     (NVL(PCMOV.QT, 0)),
                     'EB',
                     (NVL(PCMOV.QT, 0)),
                     0)),
             2) QTENT,
       TRUNC((DECODE(PCMOV.CODOPER, 'ED', (NVL(PCMOV.QT, 0)), 0)) *
             (NVL(PCMOV.PUNIT, 0)),
             6) VLDEVOLCLI,
       TRUNC((DECODE(PCMOV.CODOPER, 'ED', (NVL(PCMOV.QT, 0)), 0)), 6) QTDEVOLCLI,
       NVL(PCNFSAID.CONSUMIDORFINAL, 'N') CONSUMIDORFINAL,
       NVL(PCNFSAID.TIPOFJ, PCCLIENT.TIPOFJ) TIPOFJ,
       NVL(PCNFSAID.IEENT, 'ISENTO') IEENT,
       NVL(ROUND((NVL(PCMOV.VLREPASSE, 0) *
                 DECODE(PCNFSAID.CONDVENDA,
                         5,
                         0,
                         6,
                         0,
                         11,
                         0,
                         12,
                         0,
                         DECODE(PCMOV.CODOPER,
                                'SB',
                                0,
                                DECODE(NVL(PCMOV.TIPOITEM, 'C'),
                                       'C',
                                       PCMOV.QT,
                                       PCMOV.QTCONT)))),
                 2),
           0) VLREPASSE,
       PCPRODUT.DESCRICAO,
       PCPRODUT.EMBALAGEM,
       PCPRODUT.NUMORIGINAL,
       PCPRODUT.CODAUXILIAR,
       PCPRODUT.PESOLIQ,
       PCCLIENT.ESTENT,
       PCCLIENT.CLIENTE,
       PCCLIENT.CGCENT,
       PCCLIENT.MUNICENT,
       PCPRODUT.CODMARCA,
       PCPRODUT.CODLINHAPROD,
       PCPRODUT.CLASSE,
       PCPRODUT.CLASSEVENDA,
       PCMOV.NUMPED,
       PCMOV.NUMSEQ,
       (NVL(PCMOV.VLVERBACMV, 0) * PCMOV.QT) AS VLVERBACMV,
       (NVL(PCMOV.VLVERBACMVCLI, 0) * PCMOV.QT) AS VLVERBACMVCLI,
       PCMOV.PERCDESCFIN
  FROM PCNFSAID,
       PCCLIENT,
       PCPRACA,
       PCMOV,
       PCPRODUT,
       PCMOVCOMPLE,
       PCATIVI     ATIVI_PRINCIPAL,
       PCATIVI     ATIVIMOV_PRINCIPAL
 WHERE PCNFSAID.NUMTRANSVENDA = PCMOV.NUMTRANSVENDA
   AND PCNFSAID.NUMNOTA = PCMOV.NUMNOTA
   AND PCMOV.CODPROD = PCPRODUT.CODPROD
   AND PCCLIENT.CODPRACA = PCPRACA.CODPRACA
   AND PCNFSAID.CODCLI = PCCLIENT.CODCLI
   AND PCCLIENT.CODATV1 = ATIVI_PRINCIPAL.CODATIV(+)
   AND PCNFSAID.CODATV1 = ATIVIMOV_PRINCIPAL.CODATIV(+)
   AND NVL(PCNFSAID.TIPOVENDA, 'X') NOT IN ('SR', 'DF')
   -- Filtros Pelo objeto Contábil
   AND PCNFSAID.DTSAIDA BETWEEN PKG_PARAMETRO_CONTABIL.GET_DATA1
                    AND PKG_PARAMETRO_CONTABIL.GET_DATA2
   -- Filtrando Filiais -----------------------------------------------------
   AND ((PCNFSAID.CODFILIAL = PKG_PARAMETRO_CONTABIL.GET_CODFILIAL) or
            (PKG_PARAMETRO_CONTABIL.GET_CODFILIAL is null))
        --------------------------------------------------------------------------
   AND PCNFSAID.DTCANCEL IS NULL
   AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
   AND NVL(PCMOV.TIPOITEM, 'C') IN ('C', 'N')
   AND PCNFSAID.CODFISCAL <> 0
   AND NOT EXISTS
 (SELECT 1
          FROM PCNFENT N
         WHERE N.NUMTRANSENT = PCNFSAID.NUMTRANSENTNFESTORNADA
           AND NVL(N.TIPOMOVGARANTIA, -1) = -1)
