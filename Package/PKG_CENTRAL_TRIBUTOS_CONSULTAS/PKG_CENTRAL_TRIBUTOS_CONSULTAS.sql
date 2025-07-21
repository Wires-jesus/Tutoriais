CREATE OR REPLACE PACKAGE PKG_CENTRAL_TRIBUTOS_CONSULTAS AS


  CURSOR C_DADOS_NF_SAIDA_NORMAL(P_CODFILIAL IN VARCHAR2,
                                 P_NUMEROTRANSACAO IN NUMBER,
                                 P_NUMERONOTA IN NUMBER) IS
    (SELECT NVL(N.CODFILIALNF,N.CODFILIAL) CODFILIAL,
            N.NUMNOTA,
            N.NUMTRANSVENDA,
            N.CODCLI,
            NULL NUMTRANSENT,
            NULL CODFORNEC,
            M.CODPROD,
            M.NUMTRANSITEM,
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
            M.PERCBASERED
       from PCNFSAID       N,
            PCMOV          M,
            PCMOVCOMPLE    MC
      where NVL(N.CODFILIALNF,N.CODFILIAL) = P_CODFILIAL
        and N.NUMTRANSVENDA = P_NUMEROTRANSACAO
        and N.NUMNOTA       = P_NUMERONOTA
        and N.CODFILIAL     = M.CODFILIAL
        and N.NUMTRANSVENDA = M.NUMTRANSVENDA
        and N.NUMNOTA       = M.NUMNOTA
        and M.NUMTRANSITEM  = MC.NUMTRANSITEM
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
            N.NUMTRANSVENDA,
            N.CODCLI,
            NULL NUMTRANSENT,
            NULL CODFORNEC,
            M.CODPROD,
            M.NUMTRANSITEM,
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
            M.PERCBASERED
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
            N.NUMTRANSVENDA,
            N.CODCLI,
            NULL NUMTRANSENT,
            NULL CODFORNEC,
            0 CODPROD,
            0 NUMTRANSITEM,
            0 PERCICM,
            0 SITTRIBUT,
            0 CODFISCAL,
            0  NCM,
            N.VLTOTAL,
            0 VLIPI,
            0 VLFRETE,
            0 VLST,
            0 VLFECP,
            0 VLOUTROS,
            0 BASEICMS,
            0 PERCBASERED
       from PCNFSAID       N
      where NVL(N.CODFILIALNF,N.CODFILIAL) = P_CODFILIAL
        and N.ESPECIE IN ('CT', 'CO')
        and N.NUMTRANSVENDA = P_NUMEROTRANSACAO
        and N.NUMNOTA       = P_NUMERONOTA
    );   
    
  CURSOR C_DADOS_NF_ENTRADA_DEVOLUCAO(P_CODFILIAL IN VARCHAR2,
                                     P_NUMEROTRANSACAO IN NUMBER,
                                     P_NUMERONOTA IN NUMBER) IS
    (SELECT NVL(N.CODFILIALNF,N.CODFILIAL) CODFILIAL,
            N.NUMNOTA,
            NULL NUMTRANSVENDA,
            NULL CODCLI,
            N.NUMTRANSENT,
            N.CODFORNEC,
            M.CODPROD,
            M.NUMTRANSITEM,
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
            M.PERCBASERED
      from PCNFENT N, PCMOV M, PCMOVCOMPLE MC, PCPRODUT P
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
   
   
   
  CURSOR C_DADOS_NF_ENTRADA_NORMAL(P_CODFILIAL IN VARCHAR2,
                                   P_NUMEROTRANSACAO IN NUMBER,
                                   P_NUMERONOTA IN NUMBER) IS
    (SELECT NVL(N.CODFILIALNF,N.CODFILIAL) CODFILIAL,
            N.NUMNOTA,
            NULL NUMTRANSVENDA,
            NULL CODCLI,
            N.NUMTRANSENT,
            N.CODFORNEC,
            M.CODPROD,
            M.NUMTRANSITEM,
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
            M.PERCBASERED
      from PCNFENT N, PCMOV M, PCMOVCOMPLE MC, PCPRODUT P
     where NVL(N.CODFILIALNF,N.CODFILIAL) = P_CODFILIAL
       and N.NUMTRANSENT   = P_NUMEROTRANSACAO
       and N.NUMNOTA       = P_NUMERONOTA
       and N.NUMTRANSENT   = M.NUMTRANSENT
       and N.NUMNOTA = M.NUMNOTA
       AND P.CODPROD = M.CODPROD
       and N.NUMNOTA = M.NUMNOTA
       and MC.NUMTRANSITEM(+) = M.NUMTRANSITEM
       and N.TIPODESCARGA not in ('6', '8', 'F', 'N','P', 'C', 'T')
       and M.DTCANCEL is null
       and M.QTCONT > 0
   );       
   

END PKG_CENTRAL_TRIBUTOS_CONSULTAS;
