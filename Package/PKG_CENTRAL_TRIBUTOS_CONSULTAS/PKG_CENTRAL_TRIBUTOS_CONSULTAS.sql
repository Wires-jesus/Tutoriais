CREATE OR REPLACE PACKAGE PKG_CENTRAL_TRIBUTOS_CONSULTAS AS


  CURSOR C_DADOS_NF_SAIDA_NORMAL(P_CODFILIAL IN VARCHAR2,
                                 P_NUMEROTRANSACAO IN NUMBER,
                                 P_NUMERONOTA IN NUMBER) IS
    (SELECT NVL(N.CODFILIALNF,N.CODFILIAL) CODFILIAL,
            N.NUMNOTA,
            N.NUMTRANSVENDA NUMTRANSACAO,
            N.NUMPED,
            N.CODCLI,
            NULL CODFORNEC,
            M.CODPROD,
            M.NUMTRANSITEM,
            M.NUMSEQ,
            M.PERCICM,
            M.SITTRIBUT,
            M.CODFISCAL,
            M.NBM NCM,
            M.PUNITCONT,
            M.VLIPI,
            M.VLFRETE,
            M.ST VLST,
            MC.VLFECP,
            M.VLOUTROS,
            M.BASEICMS,
            M.PERCBASERED, 
            M.VLSEGURO,
            M.VLDESCONTO, 
            0 VLVII, 
            M.VLPIS, 
            M.VLCOFINS
            -- VLICMS             
            ,CASE WHEN MC.SOMARVALORDIFBCICMS = 'S' THEN 0 
                  ELSE CASE WHEN (M.CODOPER = 'SD' AND PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIASIMPNACDEVFORNECNFE', NVL(N.CODFILIALNF, N.CODFILIAL)) = 'N') 
                                  AND PARAMFILIAL.OBTERCOMOVARCHAR2('FIL_OPTANTESIMPLESNAC', NVL(N.CODFILIALNF, N.CODFILIAL)) IN  ('E', 'S') 
                  THEN 0
             ELSE
                  (ROUND(ROUND( (DECODE((CASE WHEN NVL(C.TIPOCLIMED,'X') IN ('D','E','M')
                                          AND (NVL(PD.ROTINA,'X') = 'PCMED316') THEN 'S'
                                          ELSE 'N' END), 'S', NVL(M.VLDESCRODAPE, 0), 0) +
                            NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0)),2) * (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100), 2)) 
                  -
                  (ROUND(ROUND(ROUND((DECODE((CASE WHEN NVL(C.TIPOCLIMED,'X') IN ('D','E','M')
                                               AND (NVL(PD.ROTINA,'X')='PCMED316') THEN 'S'
                                              ELSE 'N' END), 'S', NVL(M.VLDESCRODAPE, 0), 0) +
                            NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0)),2) * (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100), 2) *
                          (NVL(MC.PERDIFEREIMENTOICMS,NVL(M.PERCDESCICMSDIF,0))/100), 2))
                END
            END AS VLICMS,            
            NVL(MC.VLICMSPARTDEST,0) AS VLICMSUFDEST,
            (NVL(MC.VLFCPPART,0) + NVL(MC.VLACRESCIMOFUNCEP,0))  AS VLFCP
       from PCNFSAID       N,
            PCMOV          M,
            PCMOVCOMPLE    MC,
            PCPEDC         PD, 
            PCCLIENT       C 
      where NVL(N.CODFILIALNF,N.CODFILIAL) = P_CODFILIAL
        and N.NUMTRANSVENDA = P_NUMEROTRANSACAO
        and N.NUMNOTA       = P_NUMERONOTA
        and NVL(N.CODFILIALNF, N.CODFILIAL) = NVL(M.CODFILIALNF,M.CODFILIAL)
        and N.NUMTRANSVENDA = M.NUMTRANSVENDA
        and N.NUMNOTA       = M.NUMNOTA
        and M.NUMTRANSITEM  = MC.NUMTRANSITEM
        and PD.NUMTRANSVENDA(+) = N.NUMTRANSVENDA
        AND C.CODCLI = NVL(N.CODCLINF, N.CODCLI)
        and M.CODOPER <> 'SD'
        and NVL(N.FINALIDADENFE, 'X') <> 'C'
        and M.DTCANCEL is null
        and M.QTCONT > 0
    );


  CURSOR C_DADOS_NF_SAIDA_PREFAT(P_CODFILIAL IN VARCHAR2,
                                          P_NUMEROTRANSACAO IN NUMBER,
                                          P_NUMERONOTA IN NUMBER) IS
    (SELECT NVL(N.CODFILIALNF,N.CODFILIAL) CODFILIAL,
            N.NUMNOTA,
            N.NUMTRANSVENDA NUMTRANSACAO,
            N.NUMPED,
            N.CODCLI,
            NULL CODFORNEC,
            M.CODPROD,
            M.NUMTRANSITEM,
            M.NUMSEQ,
            M.PERCICM,
            M.SITTRIBUT,
            M.CODFISCAL,
            M.NBM NCM,
            M.PUNITCONT,
            M.VLIPI,
            M.VLFRETE,
            M.ST VLST,
            MC.VLFECP,
            M.VLOUTROS,
            M.BASEICMS,
            M.PERCBASERED, 
            M.VLSEGURO,
            M.VLDESCONTO, 
            0 VLVII, 
            M.VLPIS, 
            M.VLCOFINS,
            -- VLICMS             
            CASE WHEN MC.SOMARVALORDIFBCICMS = 'S' THEN 0 
                 ELSE CASE WHEN (M.CODOPER = 'SD' AND PARAMFILIAL.OBTERCOMOVARCHAR2('ENVIASIMPNACDEVFORNECNFE', NVL(N.CODFILIALNF, N.CODFILIAL)) = 'N') 
                                 AND PARAMFILIAL.OBTERCOMOVARCHAR2('FIL_OPTANTESIMPLESNAC', NVL(N.CODFILIALNF, N.CODFILIAL)) IN  ('E', 'S') 
                 THEN 0
            ELSE
                 (ROUND(ROUND( (DECODE((CASE WHEN NVL(CLIENTE.TIPOCLIMED,'X') IN ('D','E','M')
                                         AND (NVL(PD.ROTINA,'X') = 'PCMED316') THEN 'S'
                                         ELSE 'N' END), 'S', NVL(M.VLDESCRODAPE, 0), 0) +
                           NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0)),2) * (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100), 2)) 
                 -
                 (ROUND(ROUND(ROUND((DECODE((CASE WHEN NVL(CLIENTE.TIPOCLIMED,'X') IN ('D','E','M')
                                              AND (NVL(PD.ROTINA,'X')='PCMED316') THEN 'S'
                                             ELSE 'N' END), 'S', NVL(M.VLDESCRODAPE, 0), 0) +
                           NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0)),2) * (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100), 2) *
                         (NVL(MC.PERDIFEREIMENTOICMS,NVL(M.PERCDESCICMSDIF,0))/100), 2))
               END
            END AS VLICMS,   
            NVL(MC.VLICMSPARTDEST,0) AS VLICMSUFDEST,
      (NVL(MC.VLFCPPART,0) + NVL(MC.VLACRESCIMOFUNCEP,0))  AS VLFCP
      from PCNFSAIDPREFAT       N,
           PCMOVPREFAT          M,
           PCMOVCOMPLEPREFAT    MC,
           PCPRODUT       P,
           PCCLIENTENDENT ENT,
           PCCIDADE       CIDADE_ENT,
           PCPEDC         PD,
           PCCLIENT       CLIENTE,
           PCFILIAL       FI
     where NVL(N.CODFILIALNF,N.CODFILIAL) = P_CODFILIAL
       and N.NUMTRANSVENDA = P_NUMEROTRANSACAO
       and N.NUMNOTA       = P_NUMERONOTA
       and N.NUMTRANSVENDA = M.NUMTRANSVENDA
       and PD.NUMTRANSVENDA(+) = N.NUMTRANSVENDA
       and ENT.CODENDENTCLI(+) = NVL(PD.CODENDENTCLI, PD.CODENDENT)
       and ENT.CODCLI(+) = PD.CODCLI
       and P.CODPROD = M.CODPROD
       and N.NUMNOTA = M.NUMNOTA
       and M.CODOPER <> 'SD'
       and NVL(N.FINALIDADENFE, 'X') <> 'C'
       and MC.NUMTRANSITEM(+) = M.NUMTRANSITEM
       and CIDADE_ENT.CODCIDADE(+) = CLIENTE.CODCIDADECOM
       and CLIENTE.CODCLI(+) = NVL(N.CODCLINF, N.CODCLI)
       and FI.CODIGO(+) = NVL(N.CODFILIALNF, N.CODFILIAL)
       and M.DTCANCEL is null
       and M.QTCONT > 0
   );

  CURSOR C_DADOS_CTE_SAIDA(P_CODFILIAL IN VARCHAR2,
                           P_NUMEROTRANSACAO IN NUMBER,
                           P_NUMERONOTA IN NUMBER) IS
    (SELECT NVL(N.CODFILIALNF,N.CODFILIAL) CODFILIAL,
            N.NUMNOTA,
            N.NUMTRANSVENDA NUMTRANSACAO,
            N.NUMPED,
            N.CODCLI,
            NULL CODFORNEC,
            0 CODPROD,
            0 NUMTRANSITEM,
            0 NUMSEQ,
            0 PERCICM,
            0 SITTRIBUT,
            B.CODFISCAL,
            0  NCM,
            N.VLTOTAL,
            0 VLIPI,
            0 VLFRETE,
            0 VLST,
            0 VLFECP,
            0 VLOUTROS,
            0 BASEICMS,
            0 PERCBASERED, 
            0 VLSEGURO,
            0 VLDESCONTO, 
            0 VLVII, 
            0 VLPIS, 
            0 VLCOFINS,
            0 VLICMS,
            0 VLICMSUFDEST,
            0 VLFCP            
       from PCNFSAID N, PCNFBASE B  
      where NVL(N.CODFILIALNF,N.CODFILIAL) = P_CODFILIAL
        and N.ESPECIE IN ('CT', 'CO', 'CE')
        AND N.NUMTRANSVENDA = B.NUMTRANSVENDA 
        AND N.CODCONT       = B.CODCONT
        and N.NUMTRANSVENDA = P_NUMEROTRANSACAO
        and N.NUMNOTA       = P_NUMERONOTA
    );

  CURSOR C_DADOS_NF_ENTRADA_DEVOLUCAO(P_CODFILIAL IN VARCHAR2,
                                      P_NUMEROTRANSACAO IN NUMBER,
                                      P_NUMERONOTA IN NUMBER) IS
    (SELECT NVL(N.CODFILIALNF,N.CODFILIAL) CODFILIAL,
            N.NUMNOTA,
            N.NUMTRANSENT NUMTRANSACAO,
            NULL NUMPED,
            NULL CODCLI,
            N.CODFORNEC,
            M.CODPROD,
            M.NUMTRANSITEM,
            M.NUMSEQ,
            M.PERCICM,
            M.SITTRIBUT,
            M.CODFISCAL,
            M.NBM NCM,
            M.PUNITCONT,
            M.VLIPI,
            M.VLFRETE,
            M.ST VLST,
            MC.VLFECP,
            M.VLOUTROS,
            M.BASEICMS,
            M.PERCBASERED, 
            M.VLSEGURO,
            M.VLDESCONTO, 
            0 VLVII, 
            M.VLPIS, 
            M.VLCOFINS,
            -- VLICMS --
            CASE WHEN ( NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', NVL(N.CODFILIALNF,N.CODFILIAL)),'N') = 'S') 
                       AND (N.TIPODESCARGA = 'F') 
                 THEN CASE WHEN NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_ICMS', NVL(N.CODFILIALNF,N.CODFILIAL)),'N') = 'N' 
                           THEN ROUND(ROUND((NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)), 2) *
                               (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100), 2) -
                               ROUND(ROUND(ROUND((NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)), 2) *
                                    (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100), 2) *
                                    (NVL(M.PERCDESCICMSDIF, NVL(MC.PERDIFEREIMENTOICMS,0)) / 100), 2)
                      ELSE 0 END
            ELSE ROUND(ROUND((NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)), 2) *
                      (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100), 2) - 
                 ROUND(ROUND(ROUND((NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)), 2) *
                           (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100), 2) *
                           (NVL(M.PERCDESCICMSDIF, NVL(MC.PERDIFEREIMENTOICMS,0)) / 100), 2)
            END AS VALOR_ICMS,
            NVL(MC.VLICMSPARTDEST,0) AS VLICMSUFDEST,
      (NVL(MC.VLFCPPART,0) + NVL(MC.VLACRESCIMOFUNCEP,0))  AS VLFCP
      from PCNFENT N, 
           PCMOV M, 
           PCMOVCOMPLE MC, 
           PCPRODUT P
     where NVL(N.CODFILIALNF,N.CODFILIAL) = P_CODFILIAL
       and N.NUMTRANSENT   = P_NUMEROTRANSACAO
       and N.NUMNOTA       = P_NUMERONOTA
       and N.NUMTRANSENT   = M.NUMTRANSENT
       and N.NUMNOTA = M.NUMNOTA
       AND P.CODPROD = M.CODPROD
       and N.NUMNOTA = M.NUMNOTA
       and MC.NUMTRANSITEM(+) = M.NUMTRANSITEM
       and N.TIPODESCARGA in ('6', '8', 'T')
       and M.DTCANCEL is null
       and M.QTCONT > 0
   );

  CURSOR C_DADOS_NF_ENTRADA(P_CODFILIAL IN VARCHAR2,
                                   P_NUMEROTRANSACAO IN NUMBER,
                                   P_NUMERONOTA IN NUMBER) IS
    (SELECT NVL(N.CODFILIALNF,N.CODFILIAL) CODFILIAL,
            N.NUMNOTA,
            N.NUMTRANSENT NUMTRANSACAO,
            NULL NUMPED,
            NULL CODCLI,
            N.CODFORNEC,
            M.CODPROD,
            M.NUMTRANSITEM,
            M.NUMSEQ,
            M.PERCICM,
            M.SITTRIBUT,
            M.CODFISCAL,
            M.NBM NCM,
            M.PUNITCONT,
            M.VLIPI,
            M.VLFRETE,
            M.ST VLST,
            MC.VLFECP,
            M.VLOUTROS,
            M.BASEICMS,
            M.PERCBASERED,
            M.VLSEGURO,
            M.VLDESCONTO, 
            0 VLVII, 
            M.VLPIS, 
            M.VLCOFINS,
            -- VLICMS --
            CASE WHEN ( NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZAPRECOPERSNFIMP', NVL(N.CODFILIALNF,N.CODFILIAL)),'N') = 'S') 
                       AND (N.TIPODESCARGA = 'F') 
                 THEN CASE WHEN NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('PRECOPERSNFIMP_ICMS', NVL(N.CODFILIALNF,N.CODFILIAL)),'N') = 'N' 
                           THEN ROUND(ROUND((NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)), 2) *
                               (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100), 2) -
                               ROUND(ROUND(ROUND((NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)), 2) *
                                    (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100), 2) *
                                    (NVL(M.PERCDESCICMSDIF, NVL(MC.PERDIFEREIMENTOICMS,0)) / 100), 2)
                      ELSE 0 END
            ELSE ROUND(ROUND((NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)), 2) *
                      (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100), 2) - 
                 ROUND(ROUND(ROUND((NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE,0) + NVL(MC.VLBASEOUTROS,0)), 2) *
                           (NVL(NVL(M.PERCICMCP, M.PERCICM), 0) / 100), 2) *
                           (NVL(M.PERCDESCICMSDIF, NVL(MC.PERDIFEREIMENTOICMS,0)) / 100), 2)
            END AS VALOR_ICMS,
            NVL(MC.VLICMSPARTDEST,0) AS VLICMSUFDEST,
      (NVL(MC.VLFCPPART,0) + NVL(MC.VLACRESCIMOFUNCEP,0))  AS VLFCP      
      from PCNFENT N, 
           PCMOV M, 
           PCMOVCOMPLE MC, 
           PCPRODUT P
     where NVL(N.CODFILIALNF,N.CODFILIAL) = P_CODFILIAL
       and NVL(M.CODFILIALNF,M.CODFILIAL) = P_CODFILIAL    
       and N.NUMTRANSENT   = P_NUMEROTRANSACAO
       and N.NUMNOTA       = P_NUMERONOTA
       and N.NUMTRANSENT   = M.NUMTRANSENT
       and N.NUMNOTA = M.NUMNOTA
       AND P.CODPROD = M.CODPROD
       and N.NUMNOTA = M.NUMNOTA
       and MC.NUMTRANSITEM(+) = M.NUMTRANSITEM
       and N.TIPODESCARGA not in ('6', '8', 'T')
       and M.DTCANCEL is null
       and M.QTCONT > 0
   );

  CURSOR C_DADOS_PEDIDO(P_CODFILIAL IN VARCHAR2,
                        P_NUMPED IN NUMBER) IS
    (SELECT C.CODFILIAL,
            C.NUMNOTA,
            C.NUMTRANSVENDA NUMTRANSACAO,
            C.NUMPED,
            C.CODCLI,
            NULL CODFORNEC,
            PI.CODPROD,
            NULL NUMTRANSITEM,
            PI.NUMSEQ,
            0 PERCICM,
            NULL SITTRIBUT,
            NULL CODFISCAL,
            NULL NCM,
            PI.PVENDA PUNITCONT,
            PI.VLIPI,
            PI.VLFRETE,
            PI.ST VLST,
            PI.VLFECP,
            PI.VLOUTROS,
            NULL BASEICMS,
            PI.PERCBASERED, 
            0 VLSEGURO,
            0 VLDESCONTO, 
            0 VLVII, 
            0 VLPIS, 
            0 VLCOFINS,
            0 VLICMS,
            NVL(PI.VLICMSPARTDEST,0) AS VLICMSUFDEST,
      (NVL(PI.VLFCPPART,0) + NVL(PI.VLACRESCIMOFUNCEP,0))  AS VLFCP
      from PCPEDC C,
           PCPEDI PI
     where C.CODFILIAL = P_CODFILIAL
       and C.NUMPED    = P_NUMPED
       and C.NUMPED    = PI.NUMPED
       AND C.CODFILIAL = C.CODFILIAL
   );
   
   CURSOR C_DADOS_NF_SAIDA_CIAP(P_CODFILIAL IN VARCHAR2,
                             P_NUMEROTRANSACAO IN NUMBER,
                             P_NUMERONOTA IN NUMBER) IS
    (SELECT NVL(N.CODFILIALNF, N.CODFILIAL) CODFILIAL
      ,N.NUMNOTA
      ,N.NUMTRANSVENDA NUMTRANSACAO
      ,N.NUMPED
      ,N.CODCLI
      ,NULL CODFORNEC
      ,M.CODPROD
      ,0 NUMTRANSITEM
      ,M.NUMSEQ
      ,M.PERCICM
      ,M.SITTRIBUT
      ,M.CODFISCAL
      ,P.CODNCM NCM
      ,M.PUNITCONT
      ,M.VLIPI
      ,M.VLFRETE
      ,M.ST VLST
      ,M.VLFECP
      ,0 VLOUTROS
      ,M.BASEICMS
      ,M.PERCBASERED
      ,M.VLSEGURO
      ,M.VLDESCONTO
      ,0 VLVII
      ,M.VLPIS
      ,M.VLCOFINS
      ,NVL(M.VLICMS, 0) VLICMS
      ,NVL(M.VLICMSPARTDEST,0) AS VLICMSUFDEST
      ,(NVL(M.VLFCPPART,0) + NVL(M.VLACRESCIMOFUNCEP,0))  AS VLFCP    
  FROM PCNFSAID   N
      ,PCMOVCIAP  M
      ,PCPRODCIAP P
      ,PCCLIENT   C
 WHERE NVL(N.CODFILIALNF, N.CODFILIAL) = P_CODFILIAL
   AND N.NUMTRANSVENDA = P_NUMEROTRANSACAO
   AND N.NUMNOTA = P_NUMERONOTA
   AND N.NUMTRANSVENDA = M.NUMTRANSVENDA
   AND N.NUMNOTA = M.NUMNOTA
   AND M.CODPROD = P.CODPROD
   AND C.CODCLI = NVL(N.CODCLINF, N.CODCLI)
   AND NVL(N.FINALIDADENFE, 'X') <> 'C'
   AND M.DTCANCEL IS NULL
   AND M.QTCONT > 0
   AND NVL(N.SERIE, 'X') NOT IN ('CF', 'CP')
   AND NOT EXISTS (SELECT PCMOV.CODPROD
                         FROM PCMOV
                        WHERE PCMOV.NUMTRANSVENDA = N.NUMTRANSVENDA 
                          AND PCMOV.NUMNOTA = N.NUMNOTA
                          AND PCMOV.DTMOV = N.DTSAIDA 
                          AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = P_CODFILIAL)
   );   
   
   CURSOR C_DADOS_NF_ENTRADA_CIAP(P_CODFILIAL IN VARCHAR2,
                                  P_NUMEROTRANSACAO IN NUMBER,
                                  P_NUMERONOTA IN NUMBER) IS
    (SELECT NVL(N.CODFILIALNF, N.CODFILIAL) CODFILIAL
      ,N.NUMNOTA
      ,N.NUMTRANSENT NUMTRANSACAO
      ,NULL NUMPED
      ,NULL CODCLI
      ,N.CODFORNEC
      ,M.CODPROD
      ,0 NUMTRANSITEM
      ,M.NUMSEQ
      ,M.PERCICM
      ,M.SITTRIBUT
      ,M.CODFISCAL
      ,P.CODNCM NCM
      ,M.PUNITCONT
      ,M.VLIPI
      ,M.VLFRETE
      ,M.ST VLST
      ,M.VLFECP
      ,0 VLOUTROS
      ,M.BASEICMS
      ,M.PERCBASERED
      ,M.VLSEGURO
      ,M.VLDESCONTO
      ,0 VLVII
      ,M.VLPIS
      ,M.VLCOFINS
      ,NVL(M.VLICMS, 0) VLICMS
      ,NVL(M.VLICMSPARTDEST,0) AS VLICMSUFDEST
      ,(NVL(M.VLFCPPART,0) + NVL(M.VLACRESCIMOFUNCEP,0))  AS VLFCP    
  FROM PCNFENT    N
      ,PCMOVCIAP  M
      ,PCPRODCIAP P
 WHERE NVL(N.CODFILIALNF, N.CODFILIAL) = P_CODFILIAL
   AND N.NUMTRANSENT = P_NUMEROTRANSACAO
   AND N.NUMNOTA = P_NUMERONOTA
   AND N.NUMTRANSENT = M.NUMTRANSENT
   AND N.NUMNOTA = M.NUMNOTA
   AND M.CODPROD = P.CODPROD
   AND M.DTCANCEL IS NULL
   AND M.QTCONT > 0
   AND N.TIPODESCARGA NOT IN ('6', '8', 'T')
   AND NOT EXISTS (SELECT PCMOV.CODPROD
                         FROM PCMOV
                        WHERE PCMOV.NUMTRANSENT = N.NUMTRANSENT 
                          AND PCMOV.NUMNOTA = N.NUMNOTA
                          AND PCMOV.DTMOV = N.DTSAIDA 
                          AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = P_CODFILIAL)
   );    
   
   

END PKG_CENTRAL_TRIBUTOS_CONSULTAS;
