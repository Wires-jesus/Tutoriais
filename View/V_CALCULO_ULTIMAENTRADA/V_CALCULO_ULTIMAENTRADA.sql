CREATE OR REPLACE VIEW V_CALCULO_ULTIMAENTRADA AS 
      SELECT SAI.CODFILIALSAI CODFILIAL, 
             SAI.NCMSAI NCM, 
             SAI.CODPROD, 
             NVL(SAI.DESCRICAO,P.DESCRICAO) DESCRICAO, 
             (SAI.CODPROD || ' - ' || NVL(SAI.DESCRICAO,P.DESCRICAO)) PRODUTO, 
             NVL(P.CESTABASICALEGIS,'N') CESTABASICALEGIS,              
             SAI.NUMTRANSVENDA, 
             SAI.NUMNOTASAI, 
             SAI.DATASAI, 
             SAI.DATAEMISAI, 
             SAI.DTCANCELSAI, 
             SAI.CODCLISAI, 
             SAI.CLIENTESAI, 
             SAI.CNPJSAI, 
             SAI.IESAI, 
             SAI.CHAVENFESAI, 
             SAI.MODELOSAI, 
             SAI.SIMPLESNACIONALSAI, 
             SAI.CONSUMIDORFINALSAI, 
             SAI.UFSAI, 
             SAI.UFFILIALSAI, 
             SAI.TIPOVENDASAI, 
             SAI.ORIGMERCTRIBSAI, 
             SAI.IMPORTADOSAI, 
             SAI.CONTRIBUINTESAI, 
             SAI.ORGAOPUBSAI, 
             SAI.ORGAOPUBFEDERALSAI, 
             SAI.ORGAOPUBMUNICIPALSAI, 
             SAI.ESPECIESAI, 
             SAI.SERIESAI, 
             SAI.QTCONTSAI, 
             SAI.CODFISCALSAI, 
             SAI.SITTRIBUTSAI, 
             SAI.CODOPERSAI, 
             SAI.GERAICMSLIVROFISCALSAI, 
             SAI.VLTOTALSAI, 
             SAI.PUNITCONTUNITSAI, 
             SAI.PUNITCONTSAI, 
             SAI.VLBASEICMSSTUNITSAI, 
             SAI.VLBASEICMSSTSAI, 
             SAI.ALIQUOTAINTERNASAI, 
             SAI.ALIQUOTAEXTERNASAI, 
             SAI.ALIQICMSSAI, 
             SAI.VLBASEICMSUNITSAI, 
             SAI.VLBASESTNOTAUNITSAI, 
             SAI.VLBASESTGUIAUNITSAI, 
             SAI.VLICMSUNITSAI, 
             SAI.VLBASEICMSSAI, 
             SAI.VLICMSSAI, 
             SAI.VLBASESTNOTASAI, 
             SAI.VLBASESTGUIASAI, 
             SAI.NUMTRANSENTULTENT, 
             SAI.CODIPISAI, 
             SAI.VLBASEIPISAI, 
             SAI.PERCIPISAI, 
             SAI.VLIPISAI, 
             SAI.VLIPIUNITSAI, 
             SAI.VLENCARGOSSAI, 
             SAI.VLAGREGADOMVASAI, 
             SAI.VLFRETESAI, 
             SAI.VLFRETEUNITSAI, 
             SAI.VLOUTRASDESPSAI, 
             SAI.VLOUTRASDESPUNITSAI, 
             SAI.VLCONTABILSAI, 
             SAI.VLCONTABILUNITSAI, 
             SAI.VLREDPVENDASIMPLESNASAI, 
             ENT.NUMNOTAENT, 
             ENT.NUMTRANSENT, 
             ENT.DATAENT, 
             ENT.DATAEMIENT, 
             ENT.DTCANCELENT, 
             ENT.CODFORNECENT, 
             ENT.FORNECEDORENT, 
             ENT.CNPJENT, 
             ENT.IEENT, 
             ENT.CHAVENFEENT, 
             ENT.TIPODESCARGA, 
             ENT.CONSUMIDORFINALENT, 
             ENT.UFENT, 
             ENT.UFFILIALENT, 
             ENT.ESPECIEENT, 
             ENT.SERIEENT, 
             ENT.MODELOENT, 
             ENT.CODFISCALENT, 
             ENT.QTCONTENT, 
             ENT.SITTRIBUTENT, 
             ENT.CODOPERENT, 
             ENT.GERAICMSLIVROFISCALENT, 
             ENT.VLTOTALENT, 
             ENT.PUNITCONTUNITENT, 
             ENT.PUNITCONTENT, 
             ENT.VLBASEICMSSTUNITENT, 
             ENT.VLBASEICMSSTENT, 
             ENT.ALIQUOTAINTERNAENT, 
             ENT.ALIQUOTAEXTERNAENT, 
             ENT.ALIQICMSENT, 
             ENT.VLBASEICMSUNITENT, 
             ENT.VLBASESTNOTAUNITENT, 
             ENT.VLBASESTGUIAUNITENT, 
             ENT.VLICMSUNITENT, 
             ENT.VLBASEICMSENT, 
             ENT.VLICMSENT, 
             ENT.VLBASESTNOTAENT, 
             ENT.VLBASESTGUIAENT, 
             ENT.VLCONTABILENT, 
             ENT.VLCONTABILUNITENT 
      FROM (SELECT S.NUMTRANSVENDA, 
                   S.NUMNOTA NUMNOTASAI, 
                   NVL(S.CODFILIALNF,S.CODFILIAL) CODFILIALSAI, 
                   S.DTSAIDA DATASAI, 
                   S.DTENTREGA DATAEMISAI, 
                   S.DTCANCEL DTCANCELSAI, 
                   NVL(S.CODCLINF, S.CODCLI) CODCLISAI, 
                   S.CLIENTE CLIENTESAI, 
                   S.CGC CNPJSAI, 
                   S.IE IESAI, 
                   S.CHAVENFE CHAVENFESAI, 
                   DECODE(S.CHAVENFE, NULL, NULL, SUBSTR(S.CHAVENFE, 21, 2)) MODELOSAI, 
                   NVL(S.SIMPLESNACIONAL,'N') SIMPLESNACIONALSAI, 
                   NVL(S.CONSUMIDORFINAL,'N') CONSUMIDORFINALSAI, 
                   S.UF UFSAI, 
                   S.UFFILIAL UFFILIALSAI, 
                   S.TIPOVENDA TIPOVENDASAI, 
                   MCS.ORIGMERCTRIB ORIGMERCTRIBSAI, 
                   MS.IMPORTADO IMPORTADOSAI, 
                   NVL(S.CONTRIBUINTE,'N') CONTRIBUINTESAI, 
                   NVL(S.ORGAOPUB,'N') ORGAOPUBSAI, 
                   NVL(S.ORGAOPUBFEDERAL,'N') ORGAOPUBFEDERALSAI, 
                   NVL(S.ORGAOPUBMUNICIPAL,'N') ORGAOPUBMUNICIPALSAI, 
                   S.ESPECIE ESPECIESAI, 
                   S.SERIE SERIESAI, 
                   S.VLTOTAL VLTOTALSAI, 
                   MS.NBM NCMSAI, 
                   MS.CODPROD, 
                   MS.QTCONT QTCONTSAI, 
                   MS.CODFISCAL CODFISCALSAI, 
                   MS.SITTRIBUT SITTRIBUTSAI, 
                   MS.CODOPER CODOPERSAI, 
                   MS.DESCRICAO, 
                   MS.GERAICMSLIVROFISCAL GERAICMSLIVROFISCALSAI, 
                   MS.PUNITCONT PUNITCONTUNITSAI, 
                   ROUND(MS.QTCONT * MS.PUNITCONT, 2) PUNITCONTSAI, 
                   NVL(MS.BASEICST,0) VLBASEICMSSTUNITSAI, 
                   ROUND(MS.QTCONT * NVL(MS.BASEICST,0), 2) VLBASEICMSSTSAI, 
                   NVL(MS.ALIQICMS1,0) ALIQUOTAINTERNASAI, 
                   NVL(MS.ALIQICMS2,0) ALIQUOTAEXTERNASAI, 
                   NVL(MS.PERCICM,0) ALIQICMSSAI, 
                   NVL(MS.BASEICMS, 0) VLBASEICMSUNITSAI, 
                   NVL(MS.ST,0) VLBASESTNOTAUNITSAI, 
                   NVL(MS.VLDESPADICIONAL,0) VLBASESTGUIAUNITSAI, 
                   ROUND(MS.BASEICMS * MS.PERCICM / 100, 2) VLICMSUNITSAI, 
                   ROUND(MS.QTCONT * NVL(MS.BASEICMS, 0),2) VLBASEICMSSAI, 
                   ROUND(MS.QTCONT * (MS.BASEICMS * MS.PERCICM / 100), 2) VLICMSSAI, 
                   ROUND(MS.QTCONT * NVL(MS.ST,0), 2) VLBASESTNOTASAI, 
                   ROUND(MS.QTCONT * NVL(MS.VLDESPADICIONAL,0), 2) VLBASESTGUIASAI, 
                   --------------------------- 
                   (SELECT MAX(E1.NUMTRANSENT) 
                    FROM PCNFENT E1, 
                         PCMOV M1 
                    WHERE E1.NUMTRANSENT = M1.NUMTRANSENT 
                      AND E1.NUMNOTA = M1.NUMNOTA 
                      AND M1.CODPROD = MS.CODPROD 
                      AND E1.DTENT < S.DTSAIDA 
                      AND M1.STATUS IN ('A','AB')) NUMTRANSENTULTENT, 
                   --------------------------- 
                   MCS.CODSITTRIBIPI CODIPISAI, 
                   ROUND(MS.QTCONT * NVL(MS.VLBASEIPI, 0), 2) VLBASEIPISAI, 
                   NVL(MS.PERCIPI, 0) PERCIPISAI, 
                   ROUND(MS.QTCONT * NVL(MS.VLIPI, 0), 2) VLIPISAI, 
                   NVL(MS.VLIPI, 0) VLIPIUNITSAI, 
                   (MS.QTCONT * (NVL(MS.VLFRETE, 0) + NVL(MS.VLOUTRASDESP, 0))) VLENCARGOSSAI, 
                   NVL(MCS.PERCMVAORIG, 0) VLAGREGADOMVASAI, 
                   ROUND(MS.QTCONT * NVL(MS.VLFRETE, 0), 2) VLFRETESAI, 
                   NVL(MS.VLFRETE, 0) VLFRETEUNITSAI, 
                   ROUND(MS.QTCONT * NVL(MS.VLOUTRASDESP, 0), 2) VLOUTRASDESPSAI, 
                   NVL(MS.VLOUTRASDESP, 0)  VLOUTRASDESPUNITSAI, 
                   --------------------------- 
                   (CASE WHEN (NVL(MS.CODOPER,'X') <> 'SD') THEN 
                       ROUND(MS.QTCONT * (MS.PUNITCONT + NVL(MS.VLFRETE,0) + NVL(MS.VLOUTROS,0)), 2) 
                    ELSE 
                       ROUND(MS.QTCONT * (MS.PUNITCONT + NVL(MS.VLOUTRASDESP,0)), 2) 
                    END) VLCONTABILSAI, 
                   --------------------------- 
                   (CASE WHEN (NVL(MS.CODOPER,'X') <> 'SD') THEN 
                       (MS.PUNITCONT + NVL(MS.VLFRETE,0) + NVL(MS.VLOUTROS,0)) 
                    ELSE 
                       (MS.PUNITCONT + NVL(MS.VLOUTRASDESP,0)) 
                    END) VLCONTABILUNITSAI, 
                   --------------------------- 
                   ROUND(MS.QTCONT * NVL(MCS.VLREDPVENDASIMPLESNA, 0),2) VLREDPVENDASIMPLESNASAI 
            FROM PCNFSAID S, 
                 PCMOV MS, 
                 PCMOVCOMPLE MCS 
            WHERE S.NUMTRANSVENDA = MS.NUMTRANSVENDA 
              AND S.NUMNOTA = MS.NUMNOTA 
              AND MS.NUMTRANSITEM = MCS.NUMTRANSITEM(+) 
              AND MS.STATUS IN ('A','AB')) SAI, 
           ------------------------------------------------------- 
           (SELECT E.NUMNOTA NUMNOTAENT, 
                   NVL(E.CODFILIALNF,E.CODFILIAL) CODFILIALENT, 
                   E.NUMTRANSENT, 
                   E.DTENT DATAENT, 
                   E.DTEMISSAO DATAEMIENT, 
                   ME.DTCANCEL DTCANCELENT, 
                   NVL(E.CODFORNECNF, E.CODFORNEC) CODFORNECENT, 
                   E.FORNECEDOR FORNECEDORENT, 
                   E.TIPODESCARGA, 
                   E.CGC CNPJENT, 
                   E.IE IEENT, 
                   E.CHAVENFE CHAVENFEENT, 
                   NVL(E.CONSUMIDORFINAL,'N') CONSUMIDORFINALENT, 
                   E.UF UFENT, 
                   E.UFFILIAL UFFILIALENT, 
                   E.ESPECIE ESPECIEENT, 
                   E.SERIE SERIEENT, 
                   E.MODELO MODELOENT, 
                   E.VLTOTAL VLTOTALENT, 
                   ME.CODPROD, 
                   ME.CODFISCAL CODFISCALENT, 
                   ME.SITTRIBUT SITTRIBUTENT, 
                   ME.CODOPER CODOPERENT, 
                   ME.QTCONT QTCONTENT, 
                   ME.GERAICMSLIVROFISCAL GERAICMSLIVROFISCALENT, 
                   NVL(ME.ALIQICMS1,0) ALIQUOTAINTERNAENT, 
                   NVL(ME.ALIQICMS2,0) ALIQUOTAEXTERNAENT, 
                   NVL(ME.BASEICST,0) VLBASEICMSSTUNITENT, 
                   ROUND(ME.QTCONT * NVL(ME.BASEICST,0), 2) VLBASEICMSSTENT, 
                   ME.PUNITCONT PUNITCONTUNITENT, 
                   ROUND(ME.QTCONT * ME.PUNITCONT, 2) PUNITCONTENT, 
                   NVL(ME.PERCICM,0) ALIQICMSENT, 
                   NVL(ME.ST,0) VLBASESTNOTAUNITENT, 
                   NVL(ME.VLDESPADICIONAL,0) VLBASESTGUIAUNITENT, 
                   ROUND(ME.QTCONT * NVL(ME.ST,0), 2) VLBASESTNOTAENT, 
                   ROUND(ME.QTCONT * NVL(ME.VLDESPADICIONAL,0), 2) VLBASESTGUIAENT, 
                   --------------------------- 
                   CASE WHEN E.TIPODESCARGA IN ('6','8','C','T') THEN 
                           ROUND(ME.QTCONT * (NVL(ME.BASEICMS,0) + NVL(MCE.VLBASEFRETE,0) + NVL(MCE.VLBASEOUTROS,0)), 2) 
                        ELSE 
                           ROUND(ME.QTCONT * NVL(ME.BASEICMS, 0),2) 
                   END VLBASEICMSENT, 
                   --------------------------- 
                   CASE WHEN E.TIPODESCARGA IN ('6','8','C','T') THEN 
                           ROUND((NVL(ME.BASEICMS,0) + NVL(MCE.VLBASEFRETE,0) + NVL(MCE.VLBASEOUTROS,0)), 2) 
                        ELSE 
                           ROUND(NVL(ME.BASEICMS, 0),2) 
                   END VLBASEICMSUNITENT, 
                   --------------------------- 
                   CASE WHEN E.TIPODESCARGA IN ('6','8','C','T') THEN 
                           ROUND(ME.QTCONT * (NVL(ME.BASEICMS,0) + NVL(MCE.VLBASEFRETE,0) + NVL(MCE.VLBASEOUTROS,0)) * NVL(ME.PERCICM, 0) / 100, 2) 
                        ELSE 
                           ME.QTCONT * NVL(MCE.VLICMS, (NVL(ME.BASEICMS, 0) * NVL(ME.PERCICM, 0) / 100)) 
                   END VLICMSENT, 
                   --------------------------- 
                   CASE WHEN E.TIPODESCARGA IN ('6','8','C','T') THEN 
                           ROUND((NVL(ME.BASEICMS,0) + NVL(MCE.VLBASEFRETE,0) + NVL(MCE.VLBASEOUTROS,0)) * NVL(ME.PERCICM, 0) / 100, 2) 
                        ELSE 
                           DECODE(NVL(MCE.VLICMS, 0), 0, (NVL(ME.BASEICMS, 0) * NVL(ME.PERCICM, 0) / 100), MCE.VLICMS) 
                   END VLICMSUNITENT, 
                   --------------------------- 
                   CASE WHEN (E.TIPODESCARGA IN ('6','8','C','T')) THEN 
                           ROUND(ME.QTCONT * (ME.PUNITCONT + NVL(ME.VLFRETE,0) + NVL(ME.VLOUTROS,0)), 2) 
                        WHEN E.TIPODESCARGA IN ('N','F','I') THEN 
                           (ME.QTCONT * ME.PUNITCONT) 
                        ELSE 
                           ME.QTCONT * (ME.PUNITCONT + NVL(ME.VLIPI,0) + NVL(ME.ST,0) + NVL(ME.VLFRETE,0) + NVL(ME.VLOUTRASDESP,0) - NVL(ME.VLDESCONTO,0) - NVL(ME.VLSUFRAMA,0)) 
                   END VLCONTABILENT, 
                   --------------------------- 
                   CASE WHEN (E.TIPODESCARGA IN ('6','8','C','T')) THEN 
                           (ME.PUNITCONT + NVL(ME.VLFRETE,0) + NVL(ME.VLOUTROS,0)) 
                        WHEN E.TIPODESCARGA IN ('N','F','I') THEN 
                           ME.PUNITCONT 
                        ELSE 
                           (ME.PUNITCONT + NVL(ME.VLIPI,0) + NVL(ME.ST,0) + NVL(ME.VLFRETE,0) + NVL(ME.VLOUTRASDESP,0) - NVL(ME.VLDESCONTO,0) - NVL(ME.VLSUFRAMA,0)) 
                   END VLCONTABILUNITENT 
                   --------------------------- 
            FROM PCNFENT E, 
                 PCMOV ME, 
                 PCMOVCOMPLE MCE 
            WHERE E.NUMTRANSENT = ME.NUMTRANSENT 
              AND E.NUMNOTA = ME.NUMNOTA 
              AND ME.NUMTRANSITEM = MCE.NUMTRANSITEM(+) 
              AND ME.STATUS IN ('A','AB')) ENT, 
           ------------------------------------------------------------------------------ 
           PCPRODUT P 
      WHERE ENT.CODFILIALENT = SAI.CODFILIALSAI 
        AND ENT.NUMTRANSENT = SAI.NUMTRANSENTULTENT 
        AND P.CODPROD = SAI.CODPROD 
        AND P.CODPROD = ENT.CODPROD 