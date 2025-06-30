CREATE OR REPLACE PACKAGE PKG_CENTRAL_TRIBUTOS_CONSULTAS AS


  CURSOR C_DADOS_NF_SAIDA_NORMAL(P_CODFILIAL IN VARCHAR2,
                                 P_NUMEROTRANSACAO IN NUMBER,
                                 P_NUMERONOTA IN NUMBER) IS
    (SELECT N.NUMTRANSVENDA,
            N.CODCLI,
            M.CODPROD,
            M.NUMTRANSITEM,
            M.PERCICM, -- Alíquota ICMS NF
            M.SITTRIBUT, -- Situação tributária (Opcional)
            M.CODFISCAL, -- Código fiscal(CFOP) (Opcional)
            M.NBM NCM, -- NCM da mercadoria (Opcional)
            M.PUNITCONT, -- Preço unitário
            M.VLIPI, -- Valor do IPI
            M.VLFRETE, -- Valor do frete
            M.ST VLST, -- Valor do ST
            MC.VLFECP,
            M.VLOUTROS, -- Valor de outros
            M.BASEICMS, -- Base ICMS
            M.PERCBASERED -- Redução Base ICMS
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



END PKG_CENTRAL_TRIBUTOS_CONSULTAS;