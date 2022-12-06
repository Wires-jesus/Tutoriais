CREATE OR REPLACE PACKAGE PKG_BRINDEEX IS
/******************************************
     Versão 29 Pacote
******************************************/

  G_NUMPED               PCPEDC.NUMPED%TYPE;
  G_NUMPED_GZERO         PCPEDC.NUMPED%TYPE;
  G_CODCLI               PCCLIENT.CODCLI%TYPE;
  G_HORAULTPEDACUMU      PCPEDC.HORA%TYPE;
  G_MINULTPEDACUMU       PCPEDC.MINUTO%TYPE;
  G_DTBASEACUMUL         DATE;
  VB_GRPZERO_CONTEMPLADO BOOLEAN := FALSE;
  
  TYPE TRecCriticasRestr IS RECORD (
       vnCodCampanha     NUMBER,
       vnCodGrupo        NUMBER,
       vvCritica         VARCHAR2(2000));
  TYPE TTvCriticasRestr  IS TABLE OF TRecCriticasRestr INDEX BY BINARY_INTEGER;

  PROCEDURE P_VALIDARPEDIDO(pn_codcli IN NUMBER,
                            ps_origemped IN VARCHAR2,
                            ps_codfilial IN VARCHAR2,
                            pn_codemitente IN NUMBER,
                            pn_codusur IN NUMBER,
                            pn_codplpag IN NUMBER,
                            pd_data IN DATE,
                            pn_numregiao IN NUMBER,
                            pn_codprod IN NUMBER,
                            pn_numped IN NUMBER DEFAULT 0,
                            pn_numpedtv5 IN NUMBER DEFAULT 0,
                            apuracao  OUT T_ApuraGrupoRegras,
                            msg       OUT VARCHAR2,
                            criticas  OUT TTvCriticasRestr);

  FUNCTION REL_BRINDES(pn_codcli IN NUMBER,
                       ps_origemped IN VARCHAR2,
                       ps_codfilial IN VARCHAR2,
                       pn_codemitente IN NUMBER,
                       pn_codusur IN NUMBER,
                       pn_codplpag IN NUMBER,
                       pd_data IN DATE,
                       pn_numregiao IN NUMBER,
                       pn_codprod IN NUMBER,
                       pn_numped IN NUMBER DEFAULT 0,
                       pn_numpedtv5 IN NUMBER DEFAULT 0) RETURN T_RELBRINDES_DT
    PARALLEL_ENABLE PIPELINED
    ;

  FUNCTION REL_BRINDES(pn_numped NUMBER, pn_numpedtv5 NUMBER DEFAULT 0) RETURN T_RELBRINDES_DT
    PARALLEL_ENABLE PIPELINED
    ;
    
  FUNCTION RESTRICOES_BRINDES(pn_numped NUMBER, pn_numpedtv5 NUMBER DEFAULT 0) RETURN T_RELBRINDES_DT
    PARALLEL_ENABLE PIPELINED
    ;
    
  PROCEDURE P_GERARPREMIO(PDADOS         IN T_ApuraGrupoRegras,
                          PFILIALESTOQUE IN VARCHAR2,
                          PN_NUMPEDTV5   IN NUMBER,
                          PRESULT        OUT T_RELBRINDES_DT);

  PROCEDURE P_ATUALIZARQTBRINDE(PCODCAMP   IN NUMBER,
                                PGRPREGRA  IN NUMBER,
                                PCODBRINDE IN NUMBER,
                                PQTDE      IN NUMBER,
                                PRESULT    OUT VARCHAR2);

  FUNCTION VALIDARTV5(PN_NUMPED IN PCPEDC.NUMPED%TYPE, PN_NUMPEDTV5 IN PCPEDC.NUMPED%TYPE, PCODBREX IN NUMBER DEFAULT 0)
    RETURN VARCHAR2;

  FUNCTION CODPRODPREMIO(P_CODBREX IN NUMBER, P_GR IN NUMBER, PN_NUMPEDTV5 IN PCPEDC.NUMPED%TYPE)
    RETURN TABELA_INTEIRO;

  PROCEDURE REL_BRINDES_DEBUG(pn_numped NUMBER, pn_numpedtv5 NUMBER DEFAULT 0);
  
END;
