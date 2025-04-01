CREATE OR REPLACE VIEW V_CALCULO_PEPS AS
SELECT NVL(E.CODFILIALNF, E.CODFILIAL) CODFILIAL,
       NVL(ME.NBM, PE.NBM) NCM,
       ME.CODPROD,
       NVL(ME.DESCRICAO, PE.DESCRICAO) DSCPRODUTO,
       NVL(PE.CESTABASICALEGIS, 'N') CESTABASICALEGIS,
       PE.CODLINHAPROD,
       PE.UNIDADE UNIDADECAD,
       --------------------------------------------------------------------------- 
       -- Informações de Entradas 
       --------------------------------------------------------------------------- 
       E.NUMTRANSENT,
       E.NUMNOTA NUMNOTAENT,
       NVL(E.CODFORNECNF, E.CODFORNEC) CODFORNECENT,
       E.FORNECEDOR FORNECEDORENT,
       E.CGC CNPJENT,
       E.IE IEENT,
       E.CONSUMIDORFINAL CONSUMIDORFINALENT,
       E.CHAVENFE CHAVENFEENT,
       E.MODELO MODELOENT,
       E.UF UFENT,
       E.UFFILIAL UFFILIALENT,
       E.DTENT DATAENT,
       E.DTEMISSAO DATAEMIENT,
       E.ESPECIE ESPECIEENT,
       E.SERIE SERIEENT,
       E.TIPODESCARGA TIPOCOMPRAENT,
       NVL(E.CONTRIBUINTE, 'N') CONTRIBUINTEENT,
       E.VLTOTAL VLTOTALENT,
       ME.SITTRIBUT SITTRIBUTENT,
       MCE.ORIGMERCTRIB ORIGMERCTRIBENT,
       -- NumSeqEnt 
       NVL(MCE.NITEMXML, MCE.NUMSEQENT) NUMSEQENT,
       ME.IMPORTADO IMPORTADOENT,
       ME.CODFISCAL CODFISCALENT,
       ME.CODOPER CODOPERENT,
       ME.QTCONT QTCONTENT,
       ME.PUNITCONT PUNITCONTENT,
       ROUND(ME.QTCONT * NVL(ME.BASEBCR, 0), 2) VLBASEBCRENT,
       NVL(ME.BASEBCR, 0) VLBASEBCRENT_UNIT,
       ROUND(ME.QTCONT * NVL(ME.VLDESCONTO, 0), 2) VLDESCONTOENT,
       NVL(ME.VLDESCONTO, 0) VLDESCONTOENT_UNIT,
       --------------------------- 
       CASE
         WHEN E.TIPODESCARGA IN ('6', '8', 'C', 'T') THEN
          ROUND(ME.QTCONT * (NVL(ME.BASEICMS, 0) + NVL(MCE.VLBASEFRETE, 0) +
                NVL(MCE.VLBASEOUTROS, 0)),
                2)
         ELSE
          ROUND(ME.QTCONT * NVL(ME.BASEICMS, 0), 2)
       END VLBASECALCICMSENT,
       --------------------------- 
       CASE
         WHEN E.TIPODESCARGA IN ('6', '8', 'C', 'T') THEN
          ROUND((NVL(ME.BASEICMS, 0) + NVL(MCE.VLBASEFRETE, 0) +
                NVL(MCE.VLBASEOUTROS, 0)),
                2)
         ELSE
          ROUND(NVL(ME.BASEICMS, 0), 2)
       END VLBASECALCICMSENT_UNIT,
       --------------------------- 
       ME.PERCICM ALIQICMSENT,
       --------------------------- 
       CASE
         WHEN E.TIPODESCARGA IN ('6', '8', 'C', 'T') THEN
          ROUND(ME.QTCONT * (NVL(ME.BASEICMS, 0) + NVL(MCE.VLBASEFRETE, 0) +
                NVL(MCE.VLBASEOUTROS, 0)) * NVL(ME.PERCICM, 0) / 100,
                2)
         ELSE
         CASE                                                       
           WHEN (SELECT NVL(MAX(COUNT(1)), 0)                   
                     FROM PCMOV M                                 
                        , PCMOVCOMPLE MC                          
                    WHERE M.NUMTRANSITEM = MC.NUMTRANSITEM        
                      AND M.NUMTRANSENT  = ME.NUMTRANSENT          
                      AND M.CODPROD      = ME.CODPROD              
                      AND NVL(M.CODFILIALNF,M.CODFILIAL) = NVL(ME.CODFILIALNF,ME.CODFILIAL)
                      AND M.DTMOV        = ME.DTMOV
                 GROUP BY M.CODPROD                               
                   HAVING COUNT(1) > 1) > 0                       
              THEN NVL((SELECT MAX(NVL(MVE.QTCONT, 0))            
                          FROM PCMOVENT MVE                       
                         WHERE MVE.CODPROD     = ME.CODPROD        
                           AND MVE.CODFILIAL   = NVL(ME.CODFILIALNF,ME.CODFILIAL)       
                           AND MVE.NUMTRANSENT = ME.NUMTRANSENT), ME.QTCONT) 
           ELSE
            ME.QTCONT END 
              * (NVL(ME.BASEICMS, 0) * NVL(ME.PERCICM, 0) / 100)
       END VLICMSENT,
       --------------------------- 
       CASE
         WHEN E.TIPODESCARGA IN ('6', '8', 'C', 'T') THEN
          ROUND((NVL(ME.BASEICMS, 0) + NVL(MCE.VLBASEFRETE, 0) +
                NVL(MCE.VLBASEOUTROS, 0)) * NVL(ME.PERCICM, 0) / 100,
                2)
         ELSE
          (NVL(ME.BASEICMS, 0) * NVL(ME.PERCICM, 0) / 100)
       END VLICMSENT_UNIT,
       --------------------------- 
       NVL(ME.ALIQICMS1, 0) ALIQICMSINTENT,
       NVL(ME.ALIQICMS2, 0) ALIQICMSEXTENT,
       NVL(ME.PERCALIQEXTGUIA, 0) PERCALIQEXTGUIAENT,
       NVL(ME.PERCIVA, 0) PERCMVAAJUSTADOENT,
       ME.QTCONT * NVL(ME.BASEICST, 0) VLBASEICMSSTENT,
       NVL(ME.BASEICST, 0) VLBASEICMSSTENT_UNIT,
       --- Calculando valor do St da entrada 
       CASE                                                       
           WHEN (SELECT NVL(MAX(COUNT(1)), 0)                   
                     FROM PCMOV M                                 
                        , PCMOVCOMPLE MC                          
                    WHERE M.NUMTRANSITEM = MC.NUMTRANSITEM        
                      AND M.NUMTRANSENT  = ME.NUMTRANSENT          
                      AND M.CODPROD      = ME.CODPROD              
                      AND NVL(M.CODFILIALNF,M.CODFILIAL) = NVL(ME.CODFILIALNF,ME.CODFILIAL)
                      AND M.DTMOV        = ME.DTMOV
                 GROUP BY M.CODPROD                               
                   HAVING COUNT(1) > 1) > 0                       
              THEN NVL((SELECT MAX(NVL(MVE.QTCONT, 0))            
                          FROM PCMOVENT MVE                       
                         WHERE MVE.CODPROD     = ME.CODPROD        
                           AND MVE.CODFILIAL   = NVL(ME.CODFILIALNF,ME.CODFILIAL)       
                           AND MVE.NUMTRANSENT = ME.NUMTRANSENT), ME.QTCONT) 
       ELSE
          ME.QTCONT END * NVL(ME.ST, 0) VLSTENT,
       -------------------------------     
       NVL(ME.ST, 0) VLSTENT_UNIT,
       ME.QTCONT * NVL(ME.VLBASESTFORANF, 0) VLBASEICMSSTENTGUIA,
       NVL(ME.VLBASESTFORANF, 0) VLBASEICMSSTENTGUIA_UNIT,
       ME.QTCONT * NVL(ME.VLDESPADICIONAL, 0) VLSTGUIAENT,
       ME.QTCONT * NVL(ME.STBCR, 0) VLSTBCRENT,
       NVL(ME.STBCR, 0) VLSTBCRENT_UNIT,
       NVL(ME.VLDESPADICIONAL, 0) VLSTGUIAENT_UNIT,
       ROUND(ME.QTCONT * NVL(ME.VLBASEIPI, 0), 2) VLBASEIPIENT,
       NVL(ME.PERCIPI, 0) PERCIPIENT,
       ROUND(ME.QTCONT * NVL(ME.VLIPI, 0), 2) VLIPIENT,
       NVL(ME.VLIPI, 0) VLIPIENT_UNIT,
       (ME.QTCONT * (NVL(ME.VLFRETE, 0) + NVL(ME.VLOUTRASDESP, 0))) VLENCARGOSENT, --Frete, Seguro, Impostos e outros encargos transf. ou cobr. do destin. 
       NVL(MCE.PERCMVAORIG, 0) VLAGREGADOMVA_ENT, --Margem de Valor Agregado - MVA 
       --------------------------- 
       CASE
         WHEN (E.TIPODESCARGA IN ('6', '8', 'C', 'T')) THEN
          ROUND(ME.QTCONT *
                (ME.PUNITCONT + NVL(ME.VLFRETE, 0) + NVL(ME.VLOUTROS, 0)),
                2)
         WHEN E.TIPODESCARGA IN ('N', 'F', 'I') THEN
          (ME.QTCONT * ME.PUNITCONT)
         ELSE
          ME.QTCONT * (ME.PUNITCONT + NVL(ME.VLIPI, 0) + NVL(ME.ST, 0) +
          NVL(ME.VLFRETE, 0) + NVL(ME.VLOUTRASDESP, 0) -
          NVL(ME.VLDESCONTO, 0) - NVL(ME.VLSUFRAMA, 0))
       END VLCONTABILENT,
       --------------------------- 
       CASE
         WHEN (E.TIPODESCARGA IN ('6', '8', 'C', 'T')) THEN
          (ME.PUNITCONT + NVL(ME.VLFRETE, 0) + NVL(ME.VLOUTROS, 0))
         WHEN E.TIPODESCARGA IN ('N', 'F', 'I') THEN
          ME.PUNITCONT
         ELSE
          (ME.PUNITCONT + NVL(ME.VLIPI, 0) + NVL(ME.ST, 0) +
          NVL(ME.VLFRETE, 0) + NVL(ME.VLOUTRASDESP, 0) -
          NVL(ME.VLDESCONTO, 0) - NVL(ME.VLSUFRAMA, 0))
       END VLCONTABILENT_UNIT,
       --------------------------- 
       ROUND(ME.QTCONT * NVL(ME.VLFRETE, 0), 2) VLFRETEENT,
       NVL(ME.VLFRETE, 0) VLFRETEENT_UNIT,
       ROUND(ME.QTCONT * NVL(ME.VLOUTRASDESP, 0), 2) VLOUTRASDESPENT,
       NVL(ME.VLOUTRASDESP, 0) VLOUTRASDESPENT_UNIT,
       ROUND(ME.QTCONT * NVL(MCE.VLREDPVENDASIMPLESNA, 0), 2) VLREDPVENDASIMPLESNAENT,
       E.NUMTRANSORIGEM NUMTRANSORIGEMENT,
       ME.UNIDADE UNIDADEMOVENT,
       NVL(MCE.REGIMEESPECIAL, 'N') REGIMEESPECIALENT,
       --------------------------------------------------------------------------- 
       -- Informações de Saídas 
       --------------------------------------------------------------------------- 
       SAI.CODFILIALSAI,
       SAI.NUMTRANSVENDA,
       SAI.NUMNOTASAI,
       SAI.CODCLISAI,
       SAI.CLIENTESAI,
       SAI.CNPJSAI,
       SAI.IESAI,
       SAI.CONSUMIDORFINALSAI,
       SAI.CHAVENFESAI,
       SAI.MODELOSAI,
       SAI.SIMPLESNACIONALSAI,
       SAI.UFSAI,
       SAI.UFFILIALSAI,
       SAI.DATASAI,
       SAI.DATAEMISAI,
       SAI.ESPECIESAI,
       SAI.SERIESAI,
       SAI.TIPOVENDASAI,
       SAI.VLTOTALSAI,
       SAI.SITTRIBUTSAI,
       SAI.ORIGMERCTRIBSAI,
       SAI.NUMSEQSAI,
       SAI.IMPORTADOSAI,
       SAI.CONTRIBUINTESAI,
       SAI.ORGAOPUBSAI,
       SAI.ORGAOPUBFEDERALSAI,
       SAI.ORGAOPUBMUNICIPALSAI,
       SAI.CODFISCALSAI,
       SAI.CODOPERSAI,
       SAI.QTCONTMOVSAI AS QTCONTSAI,
       SAI.QTCONTMOVSAI,
       SAI.VLBASEBCRSAI,
       SAI.VLBASEBCRSAI_UNIT,
       SAI.VLSTBCRSAI,
       SAI.VLSTBCRSAI_UNIT,
       SAI.VLDESCONTOSAI,
       SAI.VLDESCONTOSAI_UNIT,
       SAI.PUNITCONTSAI,
       SAI.VLBASECALCICMSSAI,
       SAI.VLBASECALCICMSSAI_UNIT,
       SAI.ALIQICMSSAI,
       SAI.VLICMSSAI,
       SAI.VLICMSSAI_UNIT,
       SAI.VLBASEICMSSTSAI,
       SAI.VLBASEICMSSTSAI_UNIT,
       SAI.ALIQICMSINTSAI,
       SAI.ALIQICMSEXTSAI,
       SAI.VLSTSAI,
       SAI.VLSTSAI_UNIT,
       SAI.VLSTGUIASAI,
       SAI.VLSTGUIASAI_UNIT,
       SAI.CODIPISAI,
       SAI.VLBASEIPISAI,
       SAI.PERCIPISAI,
       SAI.VLIPISAI,
       SAI.VLIPISAI_UNIT,
       SAI.VLENCARGOSSAI,
       SAI.VLCONTABILSAI,
       SAI.VLFRETESAI,
       SAI.VLFRETESAI_UNIT,
       SAI.VLOUTRASDESPSAI,
       SAI.VLOUTRASDESPSAI_UNIT,
       SAI.VLCONTABILSAI_UNIT,
       SAI.VLREDPVENDASIMPLESNASAI,
       SAI.NUMTRANSENTORIGEMSAI,
       SAI.UNIDADEMOVSAI,
       SAI.REGIMEESPECIALSAI
  FROM PCNFENT E,
       PCMOV ME,
       PCMOVCOMPLE MCE,
       PCPRODUT PE,
       (SELECT TABS.NUMTRANSVENDA,
               TABS.CODFILIALSAI,
               TABS.NUMNOTASAI,
               TABS.NUMTRANSENTSAI,
               TABS.QTCONTMOVSAI,
               TABS.NUMSEQENT,
               TABS.CODCLISAI,
               TABS.CLIENTESAI,
               TABS.CNPJSAI,
               TABS.IESAI,
               TABS.CONSUMIDORFINALSAI,
               TABS.CHAVENFESAI,
               TABS.MODELOSAI,
               TABS.SIMPLESNACIONALSAI,
               TABS.UFSAI,
               TABS.UFFILIALSAI,
               TABS.DATASAI,
               TABS.DATAEMISAI,
               TABS.ESPECIESAI,
               TABS.SERIESAI,
               TABS.TIPOVENDASAI,
               TABS.VLTOTALSAI,
               TABS.SITTRIBUTSAI,
               TABS.ORIGMERCTRIBSAI,
               TABS.NUMSEQSAI,
               TABS.IMPORTADOSAI,
               TABS.CONTRIBUINTESAI,
               TABS.ORGAOPUBSAI,
               TABS.ORGAOPUBFEDERALSAI,
               TABS.ORGAOPUBMUNICIPALSAI,
               TABS.CODFISCALSAI,
               TABS.CODPRODSAI,
               TABS.CODOPERSAI,
               TABS.PUNITCONTSAI,
               SUM(ROUND(TABS.QTCONTMOVSAI * TABS.VLBASEBCRSAI_UNIT, 2)) VLBASEBCRSAI,
               TABS.VLBASEBCRSAI_UNIT,
               SUM(ROUND(TABS.QTCONTMOVSAI * TABS.VLDESCONTOSAI_UNIT, 2)) VLDESCONTOSAI,
               TABS.VLDESCONTOSAI_UNIT,
               SUM(ROUND(TABS.QTCONTMOVSAI *
                         NVL(TABS.VLBASECALCICMSSAI_UNIT, 0),
                         2)) VLBASECALCICMSSAI,
               TABS.VLBASECALCICMSSAI_UNIT,
               TABS.ALIQICMSSAI,
               TABS.PERCICM,
               SUM(ROUND(TABS.QTCONTMOVSAI *
                         NVL(TABS.VLBASECALCICMSSAI_UNIT, 0) *
                         NVL(TABS.PERCICM, 0) / 100,
                         2)) VLICMSSAI,
               TABS.VLICMSSAI_UNIT,
               SUM(ROUND(TABS.QTCONTMOVSAI * TABS.VLBASEICMSSTSAI_UNIT, 2)) VLBASEICMSSTSAI,
               TABS.VLBASEICMSSTSAI_UNIT,
               TABS.ALIQICMSINTSAI,
               TABS.ALIQICMSEXTSAI,
               SUM(ROUND(TABS.QTCONTMOVSAI * TABS.VLSTSAI_UNIT, 2)) VLSTSAI,
               TABS.VLSTSAI_UNIT,
               SUM(ROUND(TABS.QTCONTMOVSAI * TABS.VLSTGUIASAI_UNIT, 2)) VLSTGUIASAI,
               TABS.VLSTGUIASAI_UNIT,
               SUM(ROUND(TABS.QTCONTMOVSAI * TABS.VLSTBCRSAI_UNIT, 2)) VLSTBCRSAI,
               TABS.VLSTBCRSAI_UNIT,
               TABS.CODIPISAI,
               SUM(ROUND(TABS.QTCONTMOVSAI * TABS.VLBASEIPISAI_UNIT, 2)) VLBASEIPISAI,
               TABS.VLBASEIPISAI_UNIT,
               TABS.PERCIPISAI,
               SUM(ROUND(TABS.QTCONTMOVSAI * TABS.VLIPISAI_UNIT, 2)) VLIPISAI,
               TABS.VLIPISAI_UNIT,
               SUM((TABS.QTCONTMOVSAI *
                   (TABS.VLFRETESAI_UNIT + TABS.VLOUTRASDESPSAI_UNIT))) VLENCARGOSSAI,
               TABS.VLAGREGADOMVASAI,
               SUM(ROUND(TABS.QTCONTMOVSAI * TABS.VLFRETESAI_UNIT, 2)) VLFRETESAI,
               TABS.VLFRETESAI_UNIT,
               SUM(ROUND(TABS.QTCONTMOVSAI * TABS.VLOUTRASDESPSAI_UNIT, 2)) VLOUTRASDESPSAI,
               TABS.VLOUTRASDESPSAI_UNIT,
               TABS.VLOUTROSSAI_UNIT,
               TABS.CODOPER_SAI,
               SUM(CASE
                     WHEN (NVL(TABS.CODOPER_SAI, 'X') <> 'SD') THEN
                      ROUND(TABS.QTCONTMOVSAI *
                            (TABS.PUNITCONTSAI + TABS.VLFRETESAI_UNIT +
                            TABS.VLOUTROSSAI_UNIT),
                            2)
                     ELSE
                      ROUND(TABS.QTCONTMOVSAI *
                            (TABS.PUNITCONTSAI + TABS.VLOUTRASDESPSAI_UNIT),
                            2)
                   END) VLCONTABILSAI,
               TABS.VLCONTABILSAI_UNIT,
               SUM(ROUND(TABS.QTCONTMOVSAI * TABS.VLREDPVENDASIMPLESNA, 2)) VLREDPVENDASIMPLESNASAI,
               TABS.NUMTRANSENTORIGEMSAI,
               TABS.VLREDPVENDASIMPLESNA,
               TABS.UNIDADEMOVSAI,
               TABS.REGIMEESPECIALSAI
          FROM (SELECT S.NUMTRANSVENDA,
                       NVL(S.CODFILIALNF, S.CODFILIAL) CODFILIALSAI,
                       S.NUMNOTA NUMNOTASAI,
                       MVS.NUMTRANSENT NUMTRANSENTSAI,
                       -- QTCONTMOVSAI --
                       (SELECT SUM(MMS.QTCONT)
                          FROM PCMOVSAID MMS
                         WHERE MMS.CODPROD = MS.CODPROD
                           AND MMS.NUMTRANSVENDA = MS.NUMTRANSVENDA
                           AND MMS.NUMSEQENT = MVS.NUMSEQENT
                           AND MMS.NUMTRANSENT = MVS.NUMTRANSENT) QTCONTMOVSAI,
                       ------------------
                       MVS.NUMSEQENT,
                       NVL(S.CODCLINF, S.CODCLI) CODCLISAI,
                       S.CLIENTE CLIENTESAI,
                       S.CGC CNPJSAI,
                       S.IE IESAI,
                       S.CONSUMIDORFINAL CONSUMIDORFINALSAI,
                       S.CHAVENFE CHAVENFESAI,
                       DECODE(S.CHAVENFE,
                              NULL,
                              NULL,
                              SUBSTR(S.CHAVENFE, 21, 2)) MODELOSAI,
                       NVL(S.SIMPLESNACIONAL, 'N') SIMPLESNACIONALSAI,
                       S.UF UFSAI,
                       S.UFFILIAL UFFILIALSAI,
                       S.DTSAIDA DATASAI,
                       S.DTENTREGA DATAEMISAI,
                       S.ESPECIE ESPECIESAI,
                       S.SERIE SERIESAI,
                       S.TIPOVENDA TIPOVENDASAI,
                       S.VLTOTAL VLTOTALSAI,
                       MS.SITTRIBUT SITTRIBUTSAI,
                       MCS.ORIGMERCTRIB ORIGMERCTRIBSAI,
                       -- NUMSEQSAI 
                       MAX(MCS.NITEMXML) NUMSEQSAI,
                       MS.IMPORTADO IMPORTADOSAI,
                       NVL(S.CONTRIBUINTE, 'N') CONTRIBUINTESAI,
                       NVL(S.ORGAOPUB, 'N') ORGAOPUBSAI,
                       NVL(S.ORGAOPUBFEDERAL, 'N') ORGAOPUBFEDERALSAI,
                       NVL(S.ORGAOPUBMUNICIPAL, 'N') ORGAOPUBMUNICIPALSAI,
                       MS.CODFISCAL CODFISCALSAI,
                       MS.CODPROD CODPRODSAI,
                       MS.CODOPER CODOPERSAI,
                       MAX(MS.PUNITCONT) PUNITCONTSAI,
                       MAX(NVL(MS.BASEBCR, 0)) VLBASEBCRSAI_UNIT, -------------------------------- 
                       MAX(NVL(MS.VLDESCONTO, 0)) VLDESCONTOSAI_UNIT, ----------------------------- 
                       MAX(MS.BASEICMS) VLBASECALCICMSSAI_UNIT,
                       MAX(NVL(MS.PERCICM, 0)) ALIQICMSSAI,
                       MAX(NVL(MS.PERCICM, 0)) PERCICM,
                       MAX(NVL(MS.BASEICMS, 0) * NVL(MS.PERCICM, 0) / 100) VLICMSSAI_UNIT,
                       MAX(NVL(MS.BASEICST, 0)) VLBASEICMSSTSAI_UNIT,
                       MAX(NVL(MS.ALIQICMS1, 0)) ALIQICMSINTSAI, ----------------------------- 
                       MAX(NVL(MS.ALIQICMS2, 0)) ALIQICMSEXTSAI, ----------------------------- 
                       MAX(NVL(MS.ST, 0)) VLSTSAI_UNIT,
                       MAX(NVL(MS.VLDESPADICIONAL, 0)) VLSTGUIASAI_UNIT,
                       NVL(MS.STBCR, 0) VLSTBCRSAI_UNIT,
                       MCS.CODSITTRIBIPI CODIPISAI,
                       MAX(NVL(MS.VLBASEIPI, 0)) VLBASEIPISAI_UNIT,
                       NVL(MS.PERCIPI, 0) PERCIPISAI,
                       MAX(NVL(MS.VLIPI, 0)) VLIPISAI_UNIT,
                       MAX(NVL(MCS.PERCMVAORIG, 0)) VLAGREGADOMVASAI, --Margem de Valor Agregado - MVA 
                       MAX(NVL(MS.VLFRETE, 0)) VLFRETESAI_UNIT,
                       MAX(NVL(MS.VLOUTRASDESP, 0)) VLOUTRASDESPSAI_UNIT,
                       MAX(NVL(MS.VLOUTROS, 0)) VLOUTROSSAI_UNIT,
                       MAX(MS.CODOPER) CODOPER_SAI,
                       MAX(CASE
                             WHEN (NVL(MS.CODOPER, 'X') <> 'SD') THEN
                              (MS.PUNITCONT + NVL(MS.VLFRETE, 0) +
                              NVL(MS.VLOUTROS, 0))
                             ELSE
                              (MS.PUNITCONT + NVL(MS.VLOUTRASDESP, 0))
                           END) VLCONTABILSAI_UNIT,
                       S.NUMTRANSENTORIGEM NUMTRANSENTORIGEMSAI,
                       MAX(NVL(MCS.VLREDPVENDASIMPLESNA, 0)) AS VLREDPVENDASIMPLESNA,
                       MS.UNIDADE UNIDADEMOVSAI,
                       MAX(NVL(MCS.REGIMEESPECIAL, 'N')) REGIMEESPECIALSAI
                  FROM PCNFSAID S, PCMOV MS, PCMOVCOMPLE MCS, PCMOVSAID MVS
                 WHERE S.NUMTRANSVENDA = MS.NUMTRANSVENDA
                   AND S.NUMNOTA = MS.NUMNOTA
                   AND MS.NUMTRANSITEM = MCS.NUMTRANSITEM
                   AND MS.CODPROD = MVS.CODPROD
                   AND S.NUMTRANSVENDA = MVS.NUMTRANSVENDA
                   AND S.CODFILIAL = S.CODFILIAL
                      -- Filtros Pelo objeto Fiscal 
                   AND S.DTSAIDA BETWEEN PKG_PARAMETRO_FISCAL.GET_DATA1 AND
                       PKG_PARAMETRO_FISCAL.GET_DATA2
                      -- Filtrando Filiais ----------------------------------------------------- 
                   AND ((NVL(S.CODFILIALNF, S.CODFILIAL) =
                       PKG_PARAMETRO_FISCAL.GET_CODFILIAL) OR
                       (PKG_PARAMETRO_FISCAL.GET_CODFILIAL IS NULL))
                      -------------------------------------------------------------------------- 
                   AND S.ESPECIE IN ('NF', 'CP')
                   AND MS.STATUS IN ('A', 'AB')
                   AND MS.DTCANCEL IS NULL
                 GROUP BY S.NUMTRANSVENDA,
                          NVL(S.CODFILIALNF, S.CODFILIAL),
                          S.NUMNOTA,
                          NVL(S.CODCLINF, S.CODCLI),
                          S.CLIENTE,
                          S.CGC,
                          S.IE,
                          S.CONSUMIDORFINAL,
                          S.CHAVENFE,
                          DECODE(S.CHAVENFE,
                                 NULL,
                                 NULL,
                                 SUBSTR(S.CHAVENFE, 21, 2)),
                          NVL(S.SIMPLESNACIONAL, 'N'),
                          S.UF,
                          S.UFFILIAL,
                          S.DTSAIDA,
                          S.DTENTREGA,
                          S.ESPECIE,
                          S.SERIE,
                          S.TIPOVENDA,
                          S.VLTOTAL,
                          MS.SITTRIBUT,
                          MCS.ORIGMERCTRIB,
                          MS.IMPORTADO,
                          NVL(S.CONTRIBUINTE, 'N'),
                          NVL(S.ORGAOPUB, 'N'),
                          NVL(S.ORGAOPUBFEDERAL, 'N'),
                          NVL(S.ORGAOPUBMUNICIPAL, 'N'),
                          MS.CODFISCAL,
                          MS.CODPROD,
                          MS.CODOPER,
                          NVL(MS.STBCR, 0),
                          MCS.CODSITTRIBIPI,
                          NVL(MS.PERCIPI, 0),
                          S.NUMTRANSENTORIGEM,
                          MS.UNIDADE,
                          MS.NUMTRANSVENDA,
                          MVS.NUMSEQENT,
                          MVS.NUMTRANSENT) TABS
         GROUP BY TABS.NUMTRANSVENDA,
                  TABS.CODFILIALSAI,
                  TABS.NUMNOTASAI,
                  TABS.NUMTRANSENTSAI,
                  TABS.QTCONTMOVSAI,
                  TABS.NUMSEQENT,
                  TABS.CODCLISAI,
                  TABS.CLIENTESAI,
                  TABS.CNPJSAI,
                  TABS.IESAI,
                  TABS.CONSUMIDORFINALSAI,
                  TABS.CHAVENFESAI,
                  TABS.MODELOSAI,
                  TABS.SIMPLESNACIONALSAI,
                  TABS.UFSAI,
                  TABS.UFFILIALSAI,
                  TABS.DATASAI,
                  TABS.DATAEMISAI,
                  TABS.ESPECIESAI,
                  TABS.SERIESAI,
                  TABS.TIPOVENDASAI,
                  TABS.VLTOTALSAI,
                  TABS.SITTRIBUTSAI,
                  TABS.ORIGMERCTRIBSAI,
                  TABS.NUMSEQSAI,
                  TABS.IMPORTADOSAI,
                  TABS.CONTRIBUINTESAI,
                  TABS.ORGAOPUBSAI,
                  TABS.ORGAOPUBFEDERALSAI,
                  TABS.ORGAOPUBMUNICIPALSAI,
                  TABS.CODFISCALSAI,
                  TABS.CODPRODSAI,
                  TABS.CODOPERSAI,
                  TABS.PUNITCONTSAI,
                  TABS.VLBASEBCRSAI_UNIT,
                  TABS.VLDESCONTOSAI_UNIT,
                  TABS.VLBASECALCICMSSAI_UNIT,
                  TABS.ALIQICMSSAI,
                  TABS.PERCICM,
                  TABS.VLICMSSAI_UNIT,
                  TABS.VLBASEICMSSTSAI_UNIT,
                  TABS.ALIQICMSINTSAI,
                  TABS.ALIQICMSEXTSAI,
                  TABS.VLSTSAI_UNIT,
                  TABS.VLSTGUIASAI_UNIT,
                  TABS.VLSTBCRSAI_UNIT,
                  TABS.CODIPISAI,
                  TABS.VLBASEIPISAI_UNIT,
                  TABS.PERCIPISAI,
                  TABS.VLIPISAI_UNIT,
                  TABS.VLAGREGADOMVASAI,
                  TABS.VLFRETESAI_UNIT,
                  TABS.VLOUTRASDESPSAI_UNIT,
                  TABS.VLOUTROSSAI_UNIT,
                  TABS.CODOPER_SAI,
                  TABS.VLCONTABILSAI_UNIT,
                  TABS.NUMTRANSENTORIGEMSAI,
                  TABS.VLREDPVENDASIMPLESNA,
                  TABS.UNIDADEMOVSAI,
                  TABS.REGIMEESPECIALSAI) SAI
 WHERE E.NUMTRANSENT = ME.NUMTRANSENT
   AND E.NUMNOTA = ME.NUMNOTA
      -- Filtrando filial de processamento ----------------------------------------- 
   AND ((NVL(E.CODFILIALNF, E.CODFILIAL) = PKG_PARAMETRO_FISCAL.GET_CODFILIAL) OR
        (PKG_PARAMETRO_FISCAL.GET_CODFILIAL IS NULL))
      ------------------------------------------------------------------------------ 
   AND ME.NUMTRANSITEM = MCE.NUMTRANSITEM(+)
   AND DECODE(NVL(SAI.NUMSEQENT, -1), -1, -1, SAI.NUMSEQENT) =
       DECODE(NVL(SAI.NUMSEQENT, -1), -1, -1, NVL(MCE.NUMSEQENT, ME.NUMSEQ))
   AND ME.CODPROD = PE.CODPROD
   AND ME.CODPROD(+) = SAI.CODPRODSAI
   AND ME.NUMTRANSENT(+) = SAI.NUMTRANSENTSAI
   AND E.ESPECIE = 'NF'
   AND ME.DTCANCEL IS NULL
   AND ME.STATUS IN ('A', 'AB')
-- V 003 