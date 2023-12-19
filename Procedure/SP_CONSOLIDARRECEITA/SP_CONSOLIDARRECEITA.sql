CREATE OR REPLACE PROCEDURE SP_CONSOLIDARRECEITA(psCodfilial in Varchar2, pdDataInicial in DATE, pdDataFinal in DATE)
IS
  vsCLASSIFICACAOCENTRORECEITA PCPARAMFILIAL.VALOR%TYPE;
BEGIN
  --Listar par?metrosa
  vsCLASSIFICACAOCENTRORECEITA := PARAMFILIAL.ObterComoVarchar2('CLASSIFICACAOCENTRORECEITA');
  if TRIM(vsCLASSIFICACAOCENTRORECEITA) is NULL then
     vsCLASSIFICACAOCENTRORECEITA := 'R';
  end if;

  --Apaga o per?odo consolidado para gerar novamente
  DELETE FROM PCCONSOLIDARECEITA
   WHERE PCCONSOLIDARECEITA.DTMOV BETWEEN pdDataInicial AND pdDataFinal
     AND PCCONSOLIDARECEITA.CODFILIAL = DECODE(NVL(psCodFilial,'99'), '99', PCCONSOLIDARECEITA.CODFILIAL, psCodFilial);

  --Insert vendas
  INSERT INTO PCCONSOLIDARECEITA
            ( NUMREGISTRO
            , CLASSIFICACAOCENTRORECEITA
            , CODIGO
            , NUMTRANSVENDA
            , NUMTRANSENT
            , NUMNOTA
            , CODFILIAL
            , CODFISCAL
            , SITTRIBUT
            , PERCICM
            , PERCFUNCEP
            , DTMOV
            , QUANTIDADE
            , VLUNITARIO
            , VLTOTALNOTA
            , VLICMS
            , VLPIS
            , VLCOFINS
            , VLISENTAS
            , VLOUTRAS
            , VLFRETE
            , VLST
            , VLIPI
            , VLIMPOSTOESTADUAL
            , VLREPASSE
            , VLSUBSTRETENCAO
            , VLCREDPRESUMIDO
            , VLISENTASDAPI
            , VLNAOTRIBUTADODAPI
            , VLBASERETENCAODAPI
            , VLSUSPENSASDAPI
            , VLSTDAPI
            , VLOUTRASDAPI
            , VLISENTASIPI
            , VLOUTRASIPI
            , VLFUNCEP
            , VLICMSDIFERENCIALALIQ
            , VLICMSUFDESTINO
            , VLICMSUFREMETENTE
            , VLOUTRASDESPESAS
            , VLSTBCR
            , VLSTFORANF
            , VLFECP
            , VLACRESCIMOFUNCEP
            , DTCRIACAO
            )

  SELECT DFSEQ_PCCONSOLIDARECEITA.NEXTVAL
       , vsCLASSIFICACAOCENTRORECEITA CLASSIFICACAOCENTRORECEITA
       , VENDAS.CODIGO
       , VENDAS.NUMTRANSVENDA
       , VENDAS.NUMTRANSENT
       , VENDAS.NUMNOTA
       , VENDAS.CODFILIAL
       , VENDAS.CODFISCAL
       , VENDAS.SITTRIBUT
       , VENDAS.PERCICM
       , VENDAS.ALIQFCPPART
       , VENDAS.DTMOV
       , VENDAS.QUANTIDADE
       , VENDAS.VLUNITARIO
       , VENDAS.VLVENDA VLTOTALNOTA
       , VENDAS.VLICMS
       , VENDAS.VLPIS
       , VENDAS.VLCOFINS
       , VENDAS.VLISENTAS
       , ROUND((VENDAS.VLOUTRASDESP * VENDAS.PROPORCAO),2) VLOUTRAS
       , ROUND((VENDAS.VLFRETE * VENDAS.PROPORCAO),2) VLFRETE
       , VENDAS.VLST
       , VENDAS.VLIPI
       , VENDAS.VLIMPOSTOESTADUAL
       , VENDAS.VLREPASSE
       , VENDAS.VLSUBSTRETENCAO
       , VENDAS.VLCREDPRESUMIDO
       , VENDAS.VLISENTASDAPI
       , VENDAS.VLNAOTRIBUTADODAPI
       , VENDAS.VLBASERETENCAODAPI
       , VENDAS.VLSUSPENSASDAPI
       , VENDAS.VLSTDAPI
       , VENDAS.VLOUTRASDAPI
       , VENDAS.VLISENTASIPI
       , VENDAS.VLOUTRASIPI
       , VENDAS.VLFUNCEP
       , VENDAS.VLICMSDIFERENCIALALIQ
       , VENDAS.VLICMSUFDESTINO
       , VENDAS.VLICMSUFREMETENTE
       , VENDAS.VLOUTRASDESPESAS
       , VENDAS.VLSTBCR
       , VENDAS.VLSTFORANF
       , VENDAS.VLFECP
       , VENDAS.VLACRESCIMOFUNCEP
       , SYSDATE
    FROM (SELECT A.*
               , (A.VLUNITARIO
               + A.VLIPI
               + A.VLST
               + A.VLFECP) * A.QUANTIDADE VLPRODUTO
               , CASE WHEN A.TOTALNOTAGERAL <> 0
                      THEN (((A.VLUNITARIO
                           + A.VLIPI
                           + A.VLST
                           + A.VLFECP)* A.QUANTIDADE) / A.TOTALNOTAGERAL * 100)
                      ELSE 0
                 END PROPORCAO
            FROM (SELECT CASE WHEN vsCLASSIFICACAOCENTRORECEITA = 'F'
                              THEN PCPRODUT.CODFORNEC
                              WHEN vsCLASSIFICACAOCENTRORECEITA = 'D'
                              THEN PCPRODUT.CODEPTO
                              WHEN vsCLASSIFICACAOCENTRORECEITA = 'S'
                              THEN PCPRODUT.CODSEC
                              WHEN vsCLASSIFICACAOCENTRORECEITA = 'U'
                              THEN NVL(PCMOVCOMPLE.CODSUPERVISOR, PCNFSAID.CODSUPERVISOR)
                              WHEN vsCLASSIFICACAOCENTRORECEITA = 'R'
                              THEN PCMOV.CODUSUR
                              ELSE PCMOV.CODUSUR
                         END CODIGO
                       , SUM(ROUND(NVL(NVL((CASE
                                   WHEN ROUND(PCMOVCOMPLE.VLSUBTOTITEM, 2) IS NOT NULL THEN
                                    ROUND(PCMOVCOMPLE.VLSUBTOTITEM, 2)
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
                                                'SB',
                                                NVL(DECODE(PCNFSAID.CONDVENDA,
                                                           5,
                                                           DECODE(PCMOV.TIPOITEM,
                                                                  'N',
                                                                  PCMOV.QTCONT,
                                                                  PCMOV.QT),
                                                           11,
                                                           DECODE(PCMOV.TIPOITEM,
                                                                  'N',
                                                                  PCMOV.QTCONT,
                                                                  PCMOV.QT),
                                                           0), 0),
                                                0)) *
                                        (((NVL(DECODE(PCNFSAID.CONDVENDA,
                                                      7,
                                                      DECODE(PCMOV.TIPOITEM,
                                                             'N',
                                                             NVL(DECODE(NVL(PCNFSAID.SOMAREPASSEOUTRASDESPNF,
                                                                            'N'),
                                                                        'S',
                                                                        PCMOV.PUNIT,
                                                                        PCMOV.PUNITCONT),
                                                                 0),
                                                             PCMOV.PUNIT) +
                                                      NVL(PCMOV.VLFRETE, 0) +
                                                      NVL(PCMOV.VLOUTRASDESP,
                                                          0) + NVL(PCMOV.VLFRETE_RATEIO,
                                                                   0) +
                                                      NVL(PCMOV.VLOUTROS, 0) -
                                                      DECODE(NVL(PCNFSAID.SOMAREPASSEOUTRASDESPNF,
                                                                 'N'),
                                                             'S',
                                                             NVL(PCMOV.VLREPASSE,
                                                                 0),
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
                                                          0) +
                                                      NVL(PCMOV.VLFRETE, 0) +
                                                      NVL(PCMOV.VLOUTRASDESP,
                                                          0) + NVL(PCMOV.VLFRETE_RATEIO,
                                                                   0) +
                                                      NVL(PCMOV.VLOUTROS, 0) -
                                                      DECODE(NVL(PCNFSAID.SOMAREPASSEOUTRASDESPNF,
                                                                 'N'),
                                                             'S',
                                                             NVL(PCMOV.VLREPASSE,
                                                                 0),
                                                             0)),
                                               0))) - NVL(PCMOV.VLIPI, 0) -
                                        NVL(PCMOV.ST, 0)),
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
                                                            'SB',
                                                             NVL(DECODE(PCNFSAID.CONDVENDA,
                                                                        5,
                                                                        DECODE(PCMOV.TIPOITEM,
                                                                               'N',
                                                                               PCMOV.QTCONT,
                                                                               PCMOV.QT),
                                                                        11,
                                                                        DECODE(PCMOV.TIPOITEM,
                                                                               'N',
                                                                               PCMOV.QTCONT,
                                                                               PCMOV.QT),
                                                                  0), 0),
                                                            0)),
                                                    2) +
                                 ROUND(NVL(PCMOV.ST, 0) *
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
                                               'SB',
                                                NVL(DECODE(PCNFSAID.CONDVENDA,
                                                           5,
                                                           DECODE(PCMOV.TIPOITEM,
                                                                  'N',
                                                                  PCMOV.QTCONT,
                                                                  PCMOV.QT),
                                                           11,
                                                           DECODE(PCMOV.TIPOITEM,
                                                                  'N',
                                                                  PCMOV.QTCONT,
                                                                  PCMOV.QT),
                                                           0), 0),
                                               0)),
                                       2)),
                             0),
                         2)) VLVENDA
                       , PCMOV.NUMTRANSVENDA
                       , NULL NUMTRANSENT
                       , PCMOV.NUMNOTA
                       , NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) CODFILIAL
                       , PCMOV.CODFISCAL
                       , CASE WHEN LENGTH(PCMOV.SITTRIBUT) = 3
                              THEN PCMOV.SITTRIBUT
                              ELSE NVL(PCMOVCOMPLE.ORIGMERCTRIB,'0') || PCMOV.SITTRIBUT
                         END SITTRIBUT
                       , NVL(PCMOV.PERCICM,0) PERCICM
                       , NVL(PCMOVCOMPLE.ALIQFCPPART,0) ALIQFCPPART
                       , TRUNC(PCNFSAID.DTSAIDA) DTMOV
                       , SUM(DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) QUANTIDADE
                       , SUM(DECODE(NVL(PCMOV.PUNITCONT,0), 0, NVL(PCMOV.PUNIT,0), PCMOV.PUNITCONT)
                                  - NVL(PCMOV.VLIPI, 0)
                                  - NVL(PCMOV.ST, 0)
                                  - DECODE(NVL(PCMOVCOMPLE.UTILIZOUMOTORCALCULO, 'N'), 'S', NVL(PCMOVCOMPLE.VLFECP, 0), 0)) VLUNITARIO
--                       , SUM(DECODE(NVL(PCMOV.PUNITCONT,0), 0, NVL(PCMOV.PUNIT,0), PCMOV.PUNITCONT) * DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) VLTOTALNOTA
                       ,SUM(CASE WHEN (PCMOV.CODOPER ='SD' AND PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIASIMPNACDEVFORNECNFE', PCFILIAL.CODIGO) = 'N') AND
                                PARAMFILIAL.OBTERCOMOVARCHAR2('FIL_OPTANTESIMPLESNAC', PCFILIAL.CODIGO) IN  ('E', 'S') THEN
                              0
                         ELSE
                              (ROUND(ROUND((DECODE((CASE WHEN NVL(PCCLIENT.TIPOCLIMED, 'X') IN ('D', 'E', 'M')
                AND (NVL(PCPEDC.ROTINA, 'X') = 'PCMED316') THEN
            'S'
           ELSE
            'N'
         END), 'S', NVL(PCMOV.VLDESCRODAPE, 0), 0) +
                                        NVL(PCMOV.BASEICMS, 0) + NVL(PCMOVCOMPLE.VLBASEFRETE, 0) + NVL(PCMOVCOMPLE.VLBASEOUTROS, 0))
                                        * PCMOV.QTCONT , 2) * (NVL(NVL(PCMOV.PERCICMCP, PCMOV.PERCICM), 0) / 100), 2))
                               -
                              (ROUND(ROUND(ROUND((DECODE((CASE
           WHEN NVL(PCCLIENT.TIPOCLIMED,
                    'X') IN ('D',
                             'E',
                             'M')
                AND (NVL(PCPEDC.ROTINA,
                         'X') = 'PCMED316') THEN
            'S'
           ELSE
            'N'
         END), 'S', NVL(PCMOV.VLDESCRODAPE, 0), 0) +
                                        NVL(PCMOV.BASEICMS, 0) + NVL(PCMOVCOMPLE.VLBASEFRETE, 0) + NVL(PCMOVCOMPLE.VLBASEOUTROS, 0))
                                        * PCMOV.QTCONT, 2) * (NVL(NVL(PCMOV.PERCICMCP, PCMOV.PERCICM), 0) / 100), 2) *
                                      (NVL(PCMOVCOMPLE.PERDIFEREIMENTOICMS,NVL(PCMOV.PERCDESCICMSDIF,0))/100), 2))

                          END ) AS VLICMS


                       , SUM(NVL(PCMOV.VLPIS,0) * DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) VLPIS
                       , SUM(NVL(PCMOV.VLCOFINS,0) * DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) VLCOFINS
                       , SUM(0) VLISENTAS
                       , SUM(NVL(PCMOV.VLOUTROS,0) * DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) VLOUTRAS
                       --, SUM(NVL(PCMOV.VLFRETE,0) * DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) VLFRETE
                       , SUM( ROUND( NVL(PCMOV.ST,0) * DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT), 2 ) ) VLST
                       , SUM(NVL(PCMOV.VLIPI,0) * DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT) ) VLIPI
                       , SUM(0) VLIMPOSTOESTADUAL
                       , SUM(NVL(PCMOV.VLREPASSE,0) * DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) VLREPASSE
                       , SUM(0) VLSUBSTRETENCAO
                       , SUM(NVL(PCMOV.VLCREDPRESUMIDO,0) * DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) VLCREDPRESUMIDO
                       , SUM(0) VLISENTASDAPI
                       , SUM(0) VLNAOTRIBUTADODAPI
                       , SUM(0) VLBASERETENCAODAPI
                       , SUM(0) VLSUSPENSASDAPI
                       , SUM(0) VLSTDAPI
                       , SUM(0) VLOUTRASDAPI
                       , SUM(0) VLISENTASIPI
                       , SUM(NVL(PCMOVCOMPLE.VLIPIOUTRAS,0)* DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) VLOUTRASIPI
                       , SUM(PCMOVCOMPLE.VLACRESCIMOFUNCEP) VLFUNCEP
                       , SUM(PCMOVCOMPLE.VLICMSPART) VLICMSDIFERENCIALALIQ
                       , SUM(PCMOVCOMPLE.VLICMSPARTDEST) VLICMSUFDESTINO
                       , SUM(PCMOVCOMPLE.VLICMSPARTREM) VLICMSUFREMETENTE
                       , SUM(0) VLOUTRASDESPESAS
                       , SUM(NVL(PCMOV.STBCR,0)) VLSTBCR
                       , SUM(NVL(PCMOV.VLDESPADICIONAL,0)) VLSTFORANF
                       , SUM(DECODE(NVL(PCMOVCOMPLE.UTILIZOUMOTORCALCULO, 'N'), 'S', NVL(PCMOVCOMPLE.VLFECP, 0),0) * DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) VLFECP
                       , SUM(NVL(PCMOVCOMPLE.VLACRESCIMOFUNCEP,0)* DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) VLACRESCIMOFUNCEP
                       , TRUNC(PCNFSAID.DTSAIDA) DTCRIACAO
                       , MAX(NVL(PCNFSAID.VLTOTGER, PCNFSAID.VLTOTAL) - NVL(PCNFSAID.VLFRETE,0) - NVL(PCNFSAID.VLOUTRASDESP,0)) TOTALNOTAGERAL
                       , MAX(NVL(PCNFSAID.VLFRETE,0)) VLFRETE
                       , MAX(NVL(PCNFSAID.VLOUTRASDESP,0)) VLOUTRASDESP
                    FROM PCNFSAID
                       , PCMOV
                       , PCMOVCOMPLE
                       , PCPRODUT
                       , PCFILIAL
                       , PCCLIENT
                       , PCPEDC
                   WHERE PCMOV.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA
                     AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM
                     AND PCMOV.CODPROD = PCPRODUT.CODPROD
                     AND PCPEDC.NUMPED = PCNFSAID.NUMPED
                     AND PCMOV.DTCANCEL IS NULL
                     AND PCCLIENT.CODCLI = PCNFSAID.CODCLI
                     AND PCMOV.CODOPER IN ('S','SB')
                     AND PCNFSAID.DTSAIDA BETWEEN pdDataInicial AND pdDataFinal
                     AND NVL(PCMOV.CODFILIALRETIRA, NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL)) = PCFILIAL.CODIGO
                     AND PCFILIAL.DTEXCLUSAO IS NULL
                     AND PCFILIAL.CODIGO NOT IN ('99')
           AND NVL(PCMOV.TIPOITEM, 'N') IN ('I', 'N')
                     AND DECODE(NVL(psCodFilial,'99'), '99', PCFILIAL.CODIGO, psCodFilial) = PCFILIAL.CODIGO
                   GROUP
                      BY TRUNC(PCNFSAID.DTSAIDA)
                       , NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL)
                       , CASE WHEN vsCLASSIFICACAOCENTRORECEITA = 'F'
                              THEN PCPRODUT.CODFORNEC
                              WHEN vsCLASSIFICACAOCENTRORECEITA = 'D'
                              THEN PCPRODUT.CODEPTO
                              WHEN vsCLASSIFICACAOCENTRORECEITA = 'S'
                              THEN PCPRODUT.CODSEC
                              WHEN vsCLASSIFICACAOCENTRORECEITA = 'U'
                              THEN NVL(PCMOVCOMPLE.CODSUPERVISOR, PCNFSAID.CODSUPERVISOR)
                                      WHEN vsCLASSIFICACAOCENTRORECEITA = 'R'
                              THEN PCMOV.CODUSUR
                              ELSE PCMOV.CODUSUR
                         END
                       , PCMOV.NUMTRANSVENDA
                       , PCMOV.NUMTRANSENT
                       , PCMOV.NUMNOTA
                       , PCMOV.CODFISCAL
                       , CASE WHEN LENGTH(PCMOV.SITTRIBUT) = 3
                              THEN PCMOV.SITTRIBUT
                              ELSE NVL(PCMOVCOMPLE.ORIGMERCTRIB,'0') || PCMOV.SITTRIBUT
                         END
                       , NVL(PCMOV.PERCICM,0)
                       , NVL(PCMOVCOMPLE.ALIQFCPPART,0)
                 ) a
       )VENDAS;

  --Insert vendas
  INSERT INTO PCCONSOLIDARECEITA
            ( NUMREGISTRO
            , CLASSIFICACAOCENTRORECEITA
            , CODIGO
            , NUMTRANSVENDA
            , NUMTRANSENT
            , NUMNOTA
            , CODFILIAL
            , CODFISCAL
            , SITTRIBUT
            , PERCICM
            , PERCFUNCEP
            , DTMOV
            , QUANTIDADE
            , VLUNITARIO
            , VLTOTALNOTA
            , VLICMS
            , VLPIS
            , VLCOFINS
            , VLISENTAS
            , VLOUTRAS
            , VLFRETE
            , VLST
            , VLIPI
            , VLIMPOSTOESTADUAL
            , VLREPASSE
            , VLSUBSTRETENCAO
            , VLCREDPRESUMIDO
            , VLISENTASDAPI
            , VLNAOTRIBUTADODAPI
            , VLBASERETENCAODAPI
            , VLSUSPENSASDAPI
            , VLSTDAPI
            , VLOUTRASDAPI
            , VLISENTASIPI
            , VLOUTRASIPI
            , VLFUNCEP
            , VLICMSDIFERENCIALALIQ
            , VLICMSUFDESTINO
            , VLICMSUFREMETENTE
            , VLOUTRASDESPESAS
            , VLSTBCR
            , VLSTFORANF
            , VLFECP
            , VLACRESCIMOFUNCEP
            , DTCRIACAO
            )

  SELECT DFSEQ_PCCONSOLIDARECEITA.NEXTVAL
       , vsCLASSIFICACAOCENTRORECEITA CLASSIFICACAOCENTRORECEITA
       , DEVOLUCOES.CODIGO
       , DEVOLUCOES.NUMTRANSVENDA
       , DEVOLUCOES.NUMTRANSENT
       , DEVOLUCOES.NUMNOTA
       , DEVOLUCOES.CODFILIAL
       , DEVOLUCOES.CODFISCAL
       , DEVOLUCOES.SITTRIBUT
       , DEVOLUCOES.PERCICM
       , DEVOLUCOES.ALIQFCPPART
       , DEVOLUCOES.DTMOV
       , DEVOLUCOES.QUANTIDADE
       , DEVOLUCOES.VLUNITARIO
       , DEVOLUCOES.VLTOTALNOTA
       , DEVOLUCOES.VLICMS
       , DEVOLUCOES.VLPIS
       , DEVOLUCOES.VLCOFINS
       , DEVOLUCOES.VLISENTAS
       , DEVOLUCOES.VLOUTRAS
       , DEVOLUCOES.VLFRETE
       , DEVOLUCOES.VLST
       , DEVOLUCOES.VLIPI
       , DEVOLUCOES.VLIMPOSTOESTADUAL
       , DEVOLUCOES.VLREPASSE
       , DEVOLUCOES.VLSUBSTRETENCAO
       , DEVOLUCOES.VLCREDPRESUMIDO
       , DEVOLUCOES.VLISENTASDAPI
       , DEVOLUCOES.VLNAOTRIBUTADODAPI
       , DEVOLUCOES.VLBASERETENCAODAPI
       , DEVOLUCOES.VLSUSPENSASDAPI
       , DEVOLUCOES.VLSTDAPI
       , DEVOLUCOES.VLOUTRASDAPI
       , DEVOLUCOES.VLISENTASIPI
       , DEVOLUCOES.VLOUTRASIPI
       , DEVOLUCOES.VLFUNCEP
       , DEVOLUCOES.VLICMSDIFERENCIALALIQ
       , DEVOLUCOES.VLICMSUFDESTINO
       , DEVOLUCOES.VLICMSUFREMETENTE
       , DEVOLUCOES.VLOUTRASDESPESAS
       , DEVOLUCOES.VLSTBCR
       , DEVOLUCOES.VLSTFORANF
       , DEVOLUCOES.VLFECP
       , DEVOLUCOES.VLACRESCIMOFUNCEP
       , SYSDATE
    FROM (SELECT CASE WHEN vsCLASSIFICACAOCENTRORECEITA = 'F'
                      THEN PCPRODUT.CODFORNEC
                      WHEN vsCLASSIFICACAOCENTRORECEITA = 'D'
                      THEN PCPRODUT.CODEPTO
                      WHEN vsCLASSIFICACAOCENTRORECEITA = 'S'
                      THEN PCPRODUT.CODSEC
                      WHEN vsCLASSIFICACAOCENTRORECEITA = 'U'
                      THEN NVL(PCMOVCOMPLE.CODSUPERVISOR, PCNFSAID.CODSUPERVISOR)
                      WHEN vsCLASSIFICACAOCENTRORECEITA = 'R'
                      THEN NVL(PCESTCOM.CODUSUR, PCMOV.CODUSUR)
                      ELSE NVL(PCESTCOM.CODUSUR, PCMOV.CODUSUR)
                 END CODIGO
               , PCMOV.NUMTRANSVENDA
               , PCMOV.NUMTRANSENT
               , PCMOV.NUMNOTA
               , NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) CODFILIAL
               , PCMOV.CODFISCAL
               , CASE WHEN LENGTH(PCMOV.SITTRIBUT) = 3
                      THEN PCMOV.SITTRIBUT
                      ELSE NVL(PCMOVCOMPLE.ORIGMERCTRIB,'0') || PCMOV.SITTRIBUT
                 END  SITTRIBUT
               , NVL(PCMOV.PERCICM,0) PERCICM
               , NVL(PCMOVCOMPLE.ALIQFCPPART,0) ALIQFCPPART
               , TRUNC(PCNFENT.DTENT) DTMOV
               , SUM(DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) QUANTIDADE
               , SUM(DECODE(NVL(PCMOV.PUNITCONT,0), 0, NVL(PCMOV.PUNIT,0), PCMOV.PUNITCONT)) VLUNITARIO
               -- PROCESSO DA GERALIVRO_ENTRADA, CURSOR DE DEVOLUCOES
               ,SUM(CASE WHEN PCNFENT.ROTINACAD NOT LIKE '%1423%' then
                        ROUND(PCMOV.QTCONT * (PCMOV.PUNITCONT -
                                                NVL(PCMOV.ST,0)),2) +
                            ROUND(PCMOV.QTCONT * NVL(PCMOV.ST,0),2)+
                        CASE WHEN PCNFENT.TIPODESCARGA IN ('6', '8', 'T') THEN
                            0
                        ELSE
                            ROUND(NVL(PCMOV.VLOUTROS,0) * PCMOV.QTCONT,2) END
                    ELSE
                        ROUND(ROUND(PCMOV.QTCONT * (NVL(PCMOV.PUNITCONT,0) -
                                                    NVL(PCMOV.ST,0) -
                                                    NVL(PCMOV.VLIPI,0) -
                                                    NVL(PCMOV.VLFRETE, 0) -
                                                    NVL(PCMOVCOMPLE.VLFECP,0)),2) +
                            ROUND((NVL(PCMOV.QTCONT,0) * NVL(PCMOV.ST,0)),2) +
                            ROUND((NVL(PCMOV.QTCONT,0) * NVL(PCMOV.VLIPI,0)),2) +
                            ROUND((NVL(PCMOV.QTCONT,0) * NVL(PCMOV.VLOUTROS,0)),2) +
                            ROUND((NVL(PCMOV.QTCONT,0) * NVL(PCMOVCOMPLE.VLFECP,0) ),2),2)
                    END) VLTOTALNOTA
               , SUM(DECODE(NVL(PCMOV.GERAICMSLIVROFISCAL, 'S'), 'N', 0, NVL(PCMOVCOMPLE.VLICMS,0)) * DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) VLICMS
               , SUM(NVL(PCMOV.VLPIS,0) * DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) VLPIS
               , SUM(NVL(PCMOV.VLCOFINS,0) * DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) VLCOFINS
               , SUM(0) VLISENTAS
               , SUM(NVL(PCMOV.VLOUTROS,0) * DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) VLOUTRAS
               , SUM(NVL(PCMOV.VLFRETE,0) * DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) VLFRETE
               , SUM(NVL(PCMOV.ST,0) * DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) VLST
               , SUM(NVL(PCMOV.VLIPI,0) * DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) VLIPI
               , SUM(0) VLIMPOSTOESTADUAL
               , SUM(NVL(PCMOV.VLREPASSE,0) * DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) VLREPASSE
               , SUM(0) VLSUBSTRETENCAO
               , SUM(NVL(PCMOV.VLCREDPRESUMIDO,0) * DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) VLCREDPRESUMIDO
               , SUM(0) VLISENTASDAPI
               , SUM(0) VLNAOTRIBUTADODAPI
               , SUM(0) VLBASERETENCAODAPI
               , SUM(0) VLSUSPENSASDAPI
               , SUM(0) VLSTDAPI
               , SUM(0) VLOUTRASDAPI
               , SUM(0) VLISENTASIPI
               , SUM(NVL(PCMOVCOMPLE.VLIPIOUTRAS,0)* DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) VLOUTRASIPI
               , SUM(PCMOVCOMPLE.VLACRESCIMOFUNCEP) VLFUNCEP
               , SUM(PCMOVCOMPLE.VLICMSPART) VLICMSDIFERENCIALALIQ
               , SUM(PCMOVCOMPLE.VLICMSPARTDEST) VLICMSUFDESTINO
               , SUM(PCMOVCOMPLE.VLICMSPARTREM) VLICMSUFREMETENTE
               , SUM(0) VLOUTRASDESPESAS
               , SUM(NVL(PCMOV.STBCR,0)) VLSTBCR
               , SUM(NVL(PCMOV.VLDESPADICIONAL,0)) VLSTFORANF
               , SUM(NVL(PCMOVCOMPLE.VLFECP,0)* DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) VLFECP
               , SUM(NVL(PCMOVCOMPLE.VLACRESCIMOFUNCEP,0)* DECODE(NVL(PCMOV.QTCONT,0),0, NVL(PCMOV.QT,0), PCMOV.QTCONT)) VLACRESCIMOFUNCEP
               , TRUNC(PCNFENT.DTENT) DTCRIACAO
            FROM PCNFENT
               , PCMOV
               , PCMOVCOMPLE
               , PCPRODUT
               , PCFILIAL
               , PCCONSUM
               , PCESTCOM
               , PCNFSAID
           WHERE PCMOV.NUMTRANSENT = PCNFENT.NUMTRANSENT
             AND PCNFENT.NUMTRANSENT = PCESTCOM.NUMTRANSENT(+)
             AND PCESTCOM.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA(+)
             AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM
             AND PCMOV.CODPROD = PCPRODUT.CODPROD
             AND PCMOV.DTCANCEL IS NULL
             AND PCMOV.CODOPER IN ('ED')
             AND PCNFENT.DTENT BETWEEN pdDataInicial AND pdDataFinal
             AND NVL(PCMOV.CODFILIALRETIRA, NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL)) = PCFILIAL.CODIGO
             AND PCFILIAL.DTEXCLUSAO IS NULL
             AND PCFILIAL.CODIGO NOT IN ('99')
             AND DECODE(NVL(psCodFilial,'99'), '99', PCFILIAL.CODIGO, psCodFilial) = PCFILIAL.CODIGO
           GROUP
              BY TRUNC(PCNFENT.DTENT)
               , NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL)
               , CASE WHEN vsCLASSIFICACAOCENTRORECEITA = 'F'
                      THEN PCPRODUT.CODFORNEC
                      WHEN vsCLASSIFICACAOCENTRORECEITA = 'D'
                      THEN PCPRODUT.CODEPTO
                      WHEN vsCLASSIFICACAOCENTRORECEITA = 'S'
                      THEN PCPRODUT.CODSEC
                      WHEN vsCLASSIFICACAOCENTRORECEITA = 'U'
                      THEN NVL(PCMOVCOMPLE.CODSUPERVISOR, PCNFSAID.CODSUPERVISOR)
                      WHEN vsCLASSIFICACAOCENTRORECEITA = 'R'
                      THEN NVL(PCESTCOM.CODUSUR, PCMOV.CODUSUR)
                      ELSE NVL(PCESTCOM.CODUSUR, PCMOV.CODUSUR)
                 END
               , PCMOV.NUMTRANSVENDA
               , PCMOV.NUMTRANSENT
               , PCMOV.NUMNOTA
               , PCMOV.CODFISCAL
               , CASE WHEN LENGTH(PCMOV.SITTRIBUT) = 3
                      THEN PCMOV.SITTRIBUT
                      ELSE NVL(PCMOVCOMPLE.ORIGMERCTRIB,'0') || PCMOV.SITTRIBUT
                 END
               , NVL(PCMOV.PERCICM,0)
               , NVL(PCMOVCOMPLE.ALIQFCPPART,0)
         ) DEVOLUCOES;

END;
