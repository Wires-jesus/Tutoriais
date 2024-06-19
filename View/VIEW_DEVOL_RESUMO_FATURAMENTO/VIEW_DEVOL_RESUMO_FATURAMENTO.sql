CREATE OR REPLACE VIEW VIEW_DEVOL_RESUMO_FATURAMENTO AS
SELECT PCFORNEC.CODFORNEC,
       PCMOV.CODFORNEC CODFORNECMOV,
       SUBSTR(PCFORNEC.FORNECEDOR, 1, 40) FORNECEDOR,
       PCNFENT.CODFORNEC CODCLI,
       PCCLIENT.CODATV1 CODATIV,
       PCNFSAID.CODATV1 CODATIVMOV,
       NVL(PCATIVI.CODATIVPRINC, PCATIVI.CODATIV) CODATIVPRINC,
       NVL(ATIVI_MOV.CODATIVPRINC, ATIVI_MOV.CODATIV) CODATIVPRINCMOV,
       DECODE(NVL(PCNFSAID.CAIXA, 0), 0, 0, NVL(PCNFSAID.CAIXA, 0)) CAIXA,
       PCNFENT.NUMNOTA,
       PCNFENT.CODDEVOL, /*NVL(PCNFENT.VLOUTRAS, 0) VLOUTRAS,
        NVL(PCNFENT.VLFRETE, 0) VLFRETE,*/
       ROUND(NVL(PCMOV.VLOUTROS, 0) * NVL(PCMOV.QT, 0), 2) VLOUTRAS,
       ROUND(NVL(PCMOV.VLFRETE, 0) * NVL(PCMOV.QT, 0), 2) VLFRETE,
       PCNFENT.CODFILIAL,
       PCNFENT.CODMOTORISTADEVOL,
       (SELECT DISTINCT PCEMPR.NOME
          FROM PCEMPR
         WHERE PCEMPR.MATRICULA = PCNFENT.CODMOTORISTADEVOL) NOMEMOTORISTA,
       PCNFENT.DTENT,
       PCNFENT.NUMTRANSENT,
       PCESTCOM.NUMTRANSVENDA,
       PCEMPR.NOME NOMEFUNC,
       PCTABDEV.MOTIVO,
       PCNFSAID.VENDAASSISTIDA,
       SUBSTR(PCCLIENT.CLIENTE, 1, 40) CLIENTE,
       PCMOV.CODDEVOL DEVOLITEM,
       PCTABDEV2.MOTIVO MOTIVO2,
       PCCLIENT.ESTENT,
       PCNFSAID.UF UFMOV,
       PCCLIENT.VIP,
       PCNFENT.OBS,
       SUBSTR(PCPRODUT.DESCRICAO, 1, 40) DESCRICAO,
       PCPRODUT.CODAUXILIAR,
       PCPRODUT.EMBALAGEM,
       PCPRODUT.UNIDADE,
       PCMOV.CODPROD,
       PCMOV.DTCANCEL,
       PCPRODUT.CODMARCA,
       PCPRODUT.CODLINHAPROD,
       PCPRODUT.CODEPTO,
       PCMOV.CODEPTO CODEPTOMOV,
       PCPRODUT.CODSEC,
       PCPRODUT.CODCATEGORIA,
       PCPRODUT.CODSUBCATEGORIA,
       PCMOV.CODSEC CODSECMOV,
       PCPRODUT.CODFAB,
       SUBSTR(PCDEPTO.DESCRICAO, 1, 40) DEPARTAMENTO,
       SUBSTR(PCSECAO.DESCRICAO, 1, 40) SECAO,
       PCUSUARI.CODSUPERVISOR,
       COALESCE(PCMOVCOMPLE.CODSUPERVISOR,
                (SELECT CODSUPERVISOR
                   FROM PCUSUARI
                  WHERE CODUSUR = PCMOV.CODUSUR
                    AND ROWNUM = 1),
                PCNFSAID.CODSUPERVISOR) CODSUPERVMOV, -- SUPERVISOR MOVIMENTAÇÃO
       (SELECT S.CODCOORDENADOR
          FROM PCSUPERV S
         WHERE S.CODSUPERVISOR =
               COALESCE(PCMOVCOMPLE.CODSUPERVISOR,
                        (SELECT CODSUPERVISOR
                           FROM PCUSUARI
                          WHERE CODUSUR = PCMOV.CODUSUR
                            AND ROWNUM = 1),
                        PCNFSAID.CODSUPERVISOR)) CODCOORDENADOR, -- COORDENADOR DO SUPERVISOR DA MOVIMENTAÇÃO
       (SELECT DECODE(S.CODCOORDENADOR,
                      NULL,
                      S.CODGERENTE,
                      (SELECT C.CODGERENTE
                         FROM PCCOORDENADORVENDA C
                        WHERE C.CODIGO = S.CODCOORDENADOR))
          FROM PCSUPERV S
         WHERE S.CODSUPERVISOR =
               COALESCE(PCMOVCOMPLE.CODSUPERVISOR,
                        (SELECT CODSUPERVISOR
                           FROM PCUSUARI
                          WHERE CODUSUR = PCMOV.CODUSUR
                            AND ROWNUM = 1),
                        PCNFSAID.CODSUPERVISOR)) CODGERENTELOCAL, -- GERENTE LOCAL DO COORDENADOR OU DO SUPERVISOR DA MOVIMENTAÇÃO
       (SELECT GR.CODGERENTE
          FROM PCSUPERV S, PCGERENTE GL, PCGERENTE GR
         WHERE COALESCE(PCMOVCOMPLE.CODSUPERVISOR,
                        (SELECT CODSUPERVISOR
                           FROM PCUSUARI
                          WHERE CODUSUR = PCMOV.CODUSUR
                            AND ROWNUM = 1),
                        PCNFSAID.CODSUPERVISOR) = S.CODSUPERVISOR
           AND DECODE(S.CODCOORDENADOR,
                      NULL,
                      S.CODGERENTE,
                      (SELECT C.CODGERENTE
                         FROM PCCOORDENADORVENDA C
                        WHERE C.CODIGO = S.CODCOORDENADOR)) = GL.CODGERENTE
           AND GL.CODGERENTESUPERIOR = GR.CODGERENTE(+)) CODGERENTEREGIONAL, -- GERENTE REGIONAL DO GERENTE LOCAL DO COORDENADOR OU DO SUPERVISOR DA MOVIMENTAÇÃO
       (SELECT GR.CODGERENTESUPERIOR
          FROM PCSUPERV S, PCGERENTE GL, PCGERENTE GR
         WHERE COALESCE(PCMOVCOMPLE.CODSUPERVISOR,
                        (SELECT CODSUPERVISOR
                           FROM PCUSUARI
                          WHERE CODUSUR = PCMOV.CODUSUR
                            AND ROWNUM = 1),
                        PCNFSAID.CODSUPERVISOR) = S.CODSUPERVISOR
           AND DECODE(S.CODCOORDENADOR,
                      NULL,
                      S.CODGERENTE,
                      (SELECT C.CODGERENTE
                         FROM PCCOORDENADORVENDA C
                        WHERE C.CODIGO = S.CODCOORDENADOR)) = GL.CODGERENTE
           AND GL.CODGERENTESUPERIOR = GR.CODGERENTE(+)) CODGERENTENACIONAL, -- GERENTE NACIONAL DO GERENTE REGIONAL DO GERENTE LOCAL DO COORDENADOR OU DO SUPERVISOR DA MOVIMENTAÇÃO
       (SELECT GN.CODGERENTESUPERIOR
          FROM PCSUPERV S, PCGERENTE GL, PCGERENTE GR, PCGERENTE GN
         WHERE COALESCE(PCMOVCOMPLE.CODSUPERVISOR,
                        (SELECT CODSUPERVISOR
                           FROM PCUSUARI
                          WHERE CODUSUR = PCMOV.CODUSUR
                            AND ROWNUM = 1),
                        PCNFSAID.CODSUPERVISOR) = S.CODSUPERVISOR
           AND DECODE(S.CODCOORDENADOR,
                      NULL,
                      S.CODGERENTE,
                      (SELECT C.CODGERENTE
                         FROM PCCOORDENADORVENDA C
                        WHERE C.CODIGO = S.CODCOORDENADOR)) = GL.CODGERENTE
           AND GL.CODGERENTESUPERIOR = GR.CODGERENTE(+)
           AND GR.CODGERENTESUPERIOR = GN.CODGERENTE(+)) CODDIRETOR,
       PCPRACA.CODPRACA,
       PCNFSAID.CODPRACA CODPRACAMOV,
       PCPRACA.NUMREGIAO,
       PCNFSAID.NUMREGIAO NUMREGIAOMOV,
       PCPRACA.ROTA,
       PCPRACA.PRACA,
       0 QTMETA,
       0 QTPESOMETA,
       0 MIXPREV,
       0 CLIPOSPREV,
       PCNFSAID.CODPLPAG,
       PCNFSAID.NUMPED,
       CASE
         WHEN PCPEDC.CONDVENDA = 7 THEN
          (SELECT P1.NUMPED
             FROM PCPEDC P1, PCESTCOM E1
            WHERE E1.NUMTRANSENT = PCESTCOM.NUMTRANSENT
              AND P1.NUMTRANSVENDA = E1.NUMTRANSVENDA
              AND P1.NUMPEDENTFUT = PCPEDC.NUMPED
              AND P1.CONDVENDA = 8)
         WHEN PCPEDC.CONDVENDA = 8 THEN
          (SELECT P2.NUMPED
             FROM PCPEDC P2, PCESTCOM E2
            WHERE E2.NUMTRANSENT = PCESTCOM.NUMTRANSENT
              AND P2.NUMTRANSVENDA = E2.NUMTRANSVENDA
              AND P2.NUMPED = PCPEDC.NUMPEDENTFUT
              AND P2.CONDVENDA = 7)
       END TEMVENDATV8,
       PCNFSAID.CODCOB,
       NVL(PCNFSAID.CONDVENDA, 0) CONDVENDA,
       PCNFSAID.PRAZOMEDIO,
       PCNFSAID.PRAZOADICIONAL,
       PCNFSAID.CODEMITENTE,
       SUBSTR(PCPLPAG.DESCRICAO, 1, 20) DESCRICAOPCPLPAG,
       NVL(PCPLPAG.NUMDIAS, 0) NUMDIAS,
       SUBSTR(PCUSUARI.NOME, 1, 40) AS NOME,
       PCFORNEC.CODCOMPRADOR,
       SUBSTR(PCSUPERV.NOME, 1, 40) AS SUPERV,
       0 VLVENDA,
       (NVL(PCMOV.QT, 0) *
       DECODE(PCNFSAID.CONDVENDA, 5, 1, 6, 1, 11, 1, 12, 1, 0)) QTBONIFIC,
       0 VLBONIFIC,
       NVL((DECODE(PCMOV.CODOPER,
                   'S',
                   (NVL(DECODE(PCNFSAID.CONDVENDA,
                               7,
                               DECODE(NVL(PCMOV.TIPOITEM, 'C'),
                                      'C',
                                      PCMOV.QT,
                                      PCMOV.QTCONT),
                               PCMOV.QT),
                        0)),
                   'SM',
                   (NVL(DECODE(PCNFSAID.CONDVENDA,
                               7,
                               DECODE(NVL(PCMOV.TIPOITEM, 'C'),
                                      'C',
                                      PCMOV.QT,
                                      PCMOV.QTCONT),
                               PCMOV.QT),
                        0)),
                   'ST',
                   (NVL(DECODE(PCNFSAID.CONDVENDA,
                               7,
                               DECODE(NVL(PCMOV.TIPOITEM, 'C'),
                                      'C',
                                      PCMOV.QT,
                                      PCMOV.QTCONT),
                               PCMOV.QT),
                        0)),
                   PCMOV.QT)),
           0) QT,
       NVL(PCMOV.QTCONT, 0) QTCONT,
       PCPRODUT.QTUNITCX,
       (CASE WHEN NVL(PCMOV.QT, 0) = 0 AND (PCMOV.TIPOMERC = 'L') THEN
           NVL(PCMOV.QTCONT, 0)
        ELSE
           NVL(PCMOV.QT, 0)
        END *
       (DECODE(PCNFSAID.CONDVENDA,
                5,
                0,
                6,
                0,
                11,
                0,
                1,
                (CASE
                  WHEN NVL(PCMOVCOMPLE.BONIFIC, 'N') = 'N' THEN
                   (DECODE(PCMOV.PUNIT,
                           0,
                           PCMOV.PUNITCONT,
                           NULL,
                           PCMOV.PUNITCONT,
                           PCMOV.PUNIT) + NVL(PCMOV.VLFRETE, 0) +
                   NVL(PCMOV.VLOUTRASDESP, 0) + NVL(PCMOV.VLFRETE_RATEIO, 0) +
                   NVL(PCMOV.VLOUTROS, 0))
                  ELSE
                   0
                END),
                (DECODE(PCMOV.PUNIT,
                        0,
                        PCMOV.PUNITCONT,
                        NULL,
                        PCMOV.PUNITCONT,
                        PCMOV.PUNIT) + NVL(PCMOV.VLFRETE, 0) +
                NVL(PCMOV.VLOUTRASDESP, 0) + NVL(PCMOV.VLFRETE_RATEIO, 0) +
                NVL(PCMOV.VLOUTROS, 0))) -
       DECODE(PCNFSAID.CONDVENDA,
                5,
                0,
                6,
                0,
                11,
                0,
                NVL(PCMOV.VLREPASSE, 0)) -
       DECODE(PCNFSAID.CONDVENDA,
                5,
                0,
                6,
                0,
                11,
                0,
                (NVL(PCMOV.ST, 0) + NVL(PCMOVCOMPLE.VLSTTRANSFCD, 0))) -
       DECODE(PCNFSAID.CONDVENDA,
                5,
                0,
                6,
                0,
                11,
                0,
                (NVL(PCMOVCOMPLE.VLFECP, 0) + NVL(PCMOVCOMPLE.VLFECPTRANSFCD, 0))))) +
       ROUND((NVL(PCMOV.QT, 0) *
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
                            (NVL(PCMOV.ST, 0) +
                            NVL(PCMOVCOMPLE.VLSTTRANSFCD, 0))) +
                     DECODE(PCMOV.CODOPER,
                            'SB',
                            0,
                            (NVL(PCMOVCOMPLE.VLFECP, 0) + NVL(PCMOVCOMPLE.VLFECPTRANSFCD, 0))))),
             2) VLDEVOLUCAO,
       (NVL(PCMOV.QT, 0) * DECODE(PCNFSAID.CONDVENDA,
                                  5,
                                  PCMOV.PUNITCONT + NVL(PCMOV.VLDESCONTO, 0) +
                                  NVL(PCMOV.VLOUTROS, 0),
                                  6,
                                  PCMOV.PUNITCONT + NVL(PCMOV.VLDESCONTO, 0) +
                                  NVL(PCMOV.VLOUTROS, 0),
                                  11,
                                  PCMOV.PUNITCONT + NVL(PCMOV.VLDESCONTO, 0) +
                                  NVL(PCMOV.VLOUTROS, 0),
                                  1,
                                  (CASE
                                    WHEN NVL(PCMOVCOMPLE.BONIFIC, 'N') <> 'N' THEN
                                     (DECODE(PCMOV.PUNIT,
                                             0,
                                             PCMOV.PUNITCONT,
                                             NULL,
                                             PCMOV.PUNITCONT,
                                             PCMOV.PUNIT) + NVL(PCMOV.VLFRETE, 0) +
                                     NVL(PCMOV.VLOUTRASDESP, 0) + NVL(PCMOV.VLFRETE_RATEIO, 0) +
                                     NVL(PCMOV.VLOUTROS, 0))
                                    ELSE
                                     0
                                  END),
                                  0)) VLDEVOLBONIFIC,
       (NVL(PCMOV.QT, 0) * DECODE(PCNFSAID.CONDVENDA,
                                  5,
                                  PCMOV.PUNITCONT + NVL(PCMOV.VLOUTROS, 0),
                                  6,
                                  PCMOV.PUNITCONT + NVL(PCMOV.VLOUTROS, 0),
                                  11,
                                  PCMOV.PUNITCONT + NVL(PCMOV.VLOUTROS, 0),
                                  1,
                                  (CASE
                                    WHEN NVL(PCMOVCOMPLE.BONIFIC, 'N') <> 'N' THEN
                                     (DECODE(PCMOV.PUNIT,
                                             0,
                                             PCMOV.PUNITCONT,
                                             NULL,
                                             PCMOV.PUNITCONT,
                                             PCMOV.PUNIT) + NVL(PCMOV.VLFRETE, 0) +
                                     NVL(PCMOV.VLOUTRASDESP, 0) + NVL(PCMOV.VLFRETE_RATEIO, 0) +
                                     NVL(PCMOV.VLOUTROS, 0))
                                    ELSE
                                     0
                                  END),
                                  0)) VLDEVOLBONIFIC2

      ,
       (NVL(PCMOV.QT, 0) * DECODE(PCNFSAID.CONDVENDA,
                                  5,
                                  PCMOV.PUNITCONT + NVL(PCMOV.VLOUTROS, 0),
                                  6,
                                  PCMOV.PUNITCONT + NVL(PCMOV.VLOUTROS, 0),
                                  11,
                                  PCMOV.PUNITCONT + NVL(PCMOV.VLOUTROS, 0),
                                  0)) VLDEVOLBONIFIC151,
       (NVL(PCMOV.QT, 0) *
       DECODE(PCNFSAID.CONDVENDA,
               1,
               (DECODE(NVL(PCMOVCOMPLE.BONIFIC, 'N'),
                       'F',
                       0,
                       NVL(PCMOV.CUSTOFIN, 0))),
               5,
               0,
               6,
               0,
               11,
               0,
               NVL(PCMOV.CUSTOFIN, 0))) VLCMVDEVOL,
       (NVL(PCMOV.QT, 0) * DECODE(PCNFSAID.CONDVENDA,
                                  1,
                                  (DECODE(NVL(PCMOVCOMPLE.BONIFIC, 'N'),
                                          'F',
                                          NVL(PCMOV.CUSTOFIN, 0),
                                          0)),
                                  5,
                                  NVL(PCMOV.CUSTOFIN, 0),
                                  6,
                                  NVL(PCMOV.CUSTOFIN, 0),
                                  11,
                                  NVL(PCMOV.CUSTOFIN, 0),
                                  0)) VLCMVDEVOLBONIF,
       (NVL(PCMOV.QT, 0) * NVL(PCMOV.CUSTOFIN, 0)) VLCUSTOFIN,
       (NVL(PCPRODUT.VOLUME, 0) * NVL(PCMOV.QT, 0)) LITRAGEM,
       (DECODE(PCMOV.PBASERCA,
               NULL,
               NVL(PCMOV.PBASERCA, NVL(PCMOV.PTABELA, 0)),
               NVL(PCMOV.PTABELA, 0)) * NVL(PCMOV.QT, 0)) DEVOLTAB,
       (NVL(PCPRODUT.PESOBRUTO, 0) * NVL(PCMOV.QT, 0)) AS TOTPESO,
       (NVL(PCMOV.PESOBRUTO, 0) * NVL(PCMOV.QT, 0)) AS TOTPESOMOV,
       NVL(PCCLIENT.CODCLIPRINC, PCCLIENT.CODCLI) CODCLIPRINC,
       PCNFENT.CODUSURDEVOL,
       PCNFENT.CODUSURDEVOL CODUSUR,
       PCMOV.CODUSUR CODUSURMOV,
       PCPEDC.ORIGEMPED, -- DECODE(NVL(PCNFSAID.CONDVENDA,0),5,0,6,0,11,0, (PCMOV.ST * PCMOV.QT)) VLST,
       ROUND((NVL(PCMOV.QT, 0) *
             DECODE(PCNFSAID.CONDVENDA,
                     5,
                     0,
                     6,
                     0,
                     11,
                     0,
                     12,
                     0,
                     DECODE(NVL(PCMOVCOMPLE.BONIFIC, 'N'),
                            'N',
                            DECODE(PCMOV.CODOPER,
                                   'SB',
                                   0,
                                   (NVL(PCMOV.ST, 0) +
                                   NVL(PCMOVCOMPLE.VLSTTRANSFCD, 0))),
                            0))),
             2) VLST,
       DECODE(NVL(PCNFSAID.CONDVENDA, 0),
              5,
              0,
              6,
              0,
              11,
              0,
              (NVL(PCMOV.VLIPI, 0) * NVL(PCMOV.QT, 0))) VLIPI,
       CASE
         WHEN NVL(PCNFSAID.CONDVENDA, 0) IN (5, 6, 11) THEN
          ((NVL(PCMOV.ST, 0) + NVL(PCMOVCOMPLE.VLSTTRANSFCD, 0)) * PCMOV.QT)
         ELSE
          0
       END ICMSRETIDO_BONIF,
       CASE
         WHEN NVL(PCNFSAID.CONDVENDA, 0) IN (5, 6, 11) THEN
          (NVL(PCMOV.VLIPI, 0) * NVL(PCMOV.QT, 0))
         ELSE
          0
       END VLIPI_BONIF,
       ROUND((NVL(PCMOV.QT, 0) *
             DECODE(PCNFSAID.CONDVENDA,
                     5,
                     0,
                     6,
                     0,
                     11,
                     0,
                     12,
                     0,
                     DECODE(NVL(PCMOVCOMPLE.BONIFIC, 'N'),
                            'N',
                            DECODE(PCMOV.CODOPER,
                                   'SB',
                                   0,
                                   (NVL(PCMOVCOMPLE.VLFECP, 0) +
                                   NVL(PCMOVCOMPLE.VLFECPTRANSFCD, 0))),
                            0))),
             2) VLFECP,
       CASE
         WHEN NVL(PCNFSAID.CONDVENDA, 0) IN (5, 6, 11) THEN
          ((NVL(PCMOVCOMPLE.VLFECP, 0) + NVL(PCMOVCOMPLE.VLFECPTRANSFCD, 0)) *
          PCMOV.QT)
         ELSE
          0
       END VLFECPBONIFIC,
       PCMOV.NUMLOTE,
       PCNFENT.SERIE,
       PCFORNEC.CODFORNECPRINC,
       SUBSTR(FORNECPRINC.FORNECEDOR, 1, 40) FORNECPRINC,
       PCNFENT.ESPECIE,
       CASE
         WHEN NVL(PCNFENT.GERANFDEVCLI, 'N') = 'N' THEN
          100
         ELSE
          PCNFENT.SITUACAONFE
       END as SITUACAONFE,
       DECODE(NVL(PCNFSAID.CONDVENDA, 0),
              5,
              0,
              6,
              0,
              11,
              0,
              NVL(ROUND(PCMOV.QT * PCMOV.VLREPASSE, 2), 0)) VLREPASSE,
       PCPRODUT.NUMORIGINAL,
       PCPRODUT.PESOLIQ,
       PCCLIENT.CGCENT,
       PCCLIENT.IEENT,
       PCCLIENT.MUNICENT,
       PCCLIENT.TIPOFJ,
       PCCLIENT.CONSUMIDORFINAL,
       CASE
         WHEN NVL(PCMOV.PBONIFIC, 0) > 0 THEN
          'S'
         ELSE
          'N'
       END AS BONIFICADO,
       (NVL(PCMOV.VLVERBACMV, 0) * PCMOV.QT) AS VLVERBACMV,
       (NVL(PCMOV.VLVERBACMVCLI, 0) * PCMOV.QT) AS VLVERBACMVCLI,
       PCMOV.NUMSEQ
  FROM PCNFENT,
       PCESTCOM,
       PCEMPR,
       PCNFSAID,
       PCMOV,
       PCPRODUT,
       PCCLIENT,
       PCATIVI,
       PCATIVI ATIVI_MOV,
       PCFORNEC,
       PCPRACA,
       PCTABDEV,
       PCTABDEV PCTABDEV2,
       PCDEPTO,
       PCSECAO,
       PCUSUARI,
       PCPLPAG,
       PCSUPERV,
       PCPEDC,
       PCFORNEC FORNECPRINC,
       PCMOVCOMPLE,
       PCCATEGORIA,
       PCSUBCATEGORIA
 WHERE PCNFENT.NUMTRANSENT = PCESTCOM.NUMTRANSENT
   AND PCCLIENT.CODPRACA = PCPRACA.CODPRACA(+)
   AND PCESTCOM.NUMTRANSENT = PCMOV.NUMTRANSENT
   AND PCPRODUT.CODFORNEC = PCFORNEC.CODFORNEC(+)
   AND PCNFSAID.NUMPED = PCPEDC.NUMPED(+)
   AND PCFORNEC.CODFORNECPRINC = FORNECPRINC.CODFORNEC(+)
   AND PCNFENT.CODDEVOL = PCTABDEV.CODDEVOL(+)
   AND PCMOV.CODDEVOL = PCTABDEV2.CODDEVOL(+)
   AND PCPRODUT.CODEPTO = PCDEPTO.CODEPTO(+)
   AND PCNFENT.CODUSURDEVOL = PCUSUARI.CODUSUR(+)
   AND PCNFSAID.CODSUPERVISOR = PCSUPERV.CODSUPERVISOR(+)
   AND PCPRODUT.CODSEC = PCSECAO.CODSEC(+)
   AND PCPRODUT.CODSEC = PCCATEGORIA.CODSEC(+)
   AND PCPRODUT.CODCATEGORIA = PCCATEGORIA.CODCATEGORIA(+)
   AND PCPRODUT.CODSEC = PCSUBCATEGORIA.CODSEC(+)
   AND PCPRODUT.CODCATEGORIA = PCSUBCATEGORIA.CODCATEGORIA(+)
   AND PCPRODUT.CODSUBCATEGORIA = PCSUBCATEGORIA.CODSUBCATEGORIA(+)
   AND PCNFENT.CODFUNCLANC = PCEMPR.MATRICULA(+)
   AND PCESTCOM.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA(+)
   AND NVL(PCNFSAID.CODPLPAG, PCCLIENT.CODPLPAG) = PCPLPAG.CODPLPAG
   AND PCMOV.CODPROD = PCPRODUT.CODPROD
   AND PCNFENT.CODFORNEC = PCCLIENT.CODCLI
   AND PCCLIENT.CODATV1 = PCATIVI.CODATIV(+)
   AND PCNFSAID.CODATV1 = ATIVI_MOV.CODATIV(+)
   AND NVL(PCESTCOM.NUMTRANSVENDA, 0) <> 0
   AND PCNFENT.TIPODESCARGA IN ('6', '7', 'T')
   AND NVL(PCNFENT.CODFISCAL, 0) IN (131, 132, 231, 232, 199, 299)
   AND PCMOV.DTCANCEL IS NULL
   AND PCMOV.CODOPER = 'ED'
      -- AND NVL(PCNFENT.ESPECIE,'X') <> 'OE'
      --Alterado conforme solicitado na tarefa 7398.135067.2017 / FIN-1293
      --Caso cause impacto em outros clientes, deve ser removida a alteração e feita uma melhoria para atender os dois cenários.
   AND (NVL(PCNFENT.ESPECIE, 'X') <> 'OE' OR
       (NVL(PCNFENT.ESPECIE, 'X') = 'OE' AND
       NVL(PCNFSAID.VENDAASSISTIDA, 'N') = 'S' AND PCNFSAID.CONDVENDA = 7))
   AND NVL(PCNFENT.OBS, 'X') <> 'NF CANCELADA'
   AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
   AND NVL(PCNFENT.TIPOMOVGARANTIA, -1) = -1
   AND NOT (PCNFENT.ROTINACAD like '%1303%' and PCNFSAID.CONDVENDA = 8)
   AND NOT (PCNFSAID.CONDVENDA = 8 AND PCMOV.CUSTOFIN = 0)
   AND PCMOV.STATUS IN ('A', 'AB')
    -- Filtros Pelo objeto Fiscal
   AND PCNFENT.DTENT BETWEEN PKG_PARAMETRO_CONTABIL.GET_DATA1
                    AND PKG_PARAMETRO_CONTABIL.GET_DATA2
   -- Filtrando Filiais -----------------------------------------------------
   AND ((PCNFENT.CODFILIAL = PKG_PARAMETRO_CONTABIL.GET_CODFILIAL) or
            (PKG_PARAMETRO_CONTABIL.GET_CODFILIAL is null))
        --------------------------------------------------------------------------