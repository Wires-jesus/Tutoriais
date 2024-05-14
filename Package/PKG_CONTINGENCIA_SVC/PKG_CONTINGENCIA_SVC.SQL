CREATE OR REPLACE PACKAGE PKG_CONTINGENCIA_SVC IS
       
    CAB_SAIDA  PCNFSAID%ROWTYPE;
    CAB_ENT    PCNFENT%ROWTYPE;
    ITEM       PCMOV%ROWTYPE;
    ITEMCOMPLE PCMOVCOMPLE%ROWTYPE;
  
    FUNCTION DUPLICARNFE(P_CODFILIAL    IN VARCHAR2,
                         P_NUMNOTA      IN NUMBER,
                         P_SERIE        IN VARCHAR2,
                         P_CHAVENFE     IN VARCHAR2,
                         P_PROTOCOLONFE IN VARCHAR2,
                         P_SITUACAONFE  IN NUMBER,
                         P_TIPOMOV      IN VARCHAR2,
                         P_MENSAGEM     OUT VARCHAR2)
      RETURN BOOLEAN;
      
    FUNCTION CANCELAR_NUMERACAONFE(P_CODFILIAL             IN VARCHAR2,
                                   P_DTEMISSAO             IN DATE,
                                   P_NUMNOTA               IN NUMBER,
                                   P_CODCLIFORNEC          IN NUMBER,
                                   P_CHAVENFE              IN VARCHAR2,
                                   P_PROTOCOLOCANCELAMENTO IN VARCHAR2,
                                   P_DTCANCEL              IN DATE,
                                   P_TIPOMOV               IN VARCHAR2,
                                   P_MENSAGEM              OUT VARCHAR2)
      RETURN BOOLEAN;
      
    FUNCTION GERARCONTRAPARTIDA(P_NUMTRANSACAO IN NUMBER,
                                P_TIPOMOV      IN VARCHAR2,
                                P_MENSAGEM     OUT VARCHAR2)
      RETURN BOOLEAN;
      
    FUNCTION GETCOLUNAS(P_TABELAA IN VARCHAR2,
                        P_TABELAB IN VARCHAR2) 
      RETURN VARCHAR2;
      
    FUNCTION OBTER_CFOPINVERSO(P_CODFISCAL IN NUMBER) 
      RETURN NUMBER;
    
    PROCEDURE GERAR_LOG(P_MOVIMENTO IN VARCHAR2,
                        P_MENSAGEM  IN VARCHAR2);
END;
