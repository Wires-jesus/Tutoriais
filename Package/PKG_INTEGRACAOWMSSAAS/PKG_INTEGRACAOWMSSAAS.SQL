CREATE OR REPLACE PACKAGE PKG_INTEGRACAOWMSSAAS IS

  PROCEDURE INTEGRARDOCUMENTONOWMSSAAS(pCODFILIAL      IN VARCHAR2,
                                       pNUMDOCWINTHOR  IN NUMBER,
                                       pTIPOINTEGRACAO IN VARCHAR2,
                                       pTIPODOCWINTHOR IN VARCHAR2);

  PROCEDURE ENVIARDOCFILAINTEGRACAO(pCODFILIAL              IN VARCHAR2,
                                    pNUMDOCWINTHOR          IN NUMBER,
                                    pNUMDOCSAAS             IN NUMBER,
                                    pTIPOINTEGRACAO         IN VARCHAR2,
                                    pTIPODOCWINTHOR         IN VARCHAR2,
                                    pTIPOGERACAODOC         IN VARCHAR2,
                                    pLIBERADOPARAINTEGRACAO IN VARCHAR2);

  PROCEDURE FINALIZARSEPARACAOITEMFILA(pCODFILIAL     IN VARCHAR2,
                                       pNUMDOCWMSSAAS IN NUMBER,
                                       pCODPROD       IN NUMBER,
                                       pNUMSEQ        IN NUMBER,
                                       pQTSEPARADA    IN NUMBER,
                                       pNUMLOTE       IN VARCHAR2);

  PROCEDURE EFETUAR_AJUSTE_ESTOQUE(pCODFILIAL  IN VARCHAR2,
                                     pCODPROD    IN NUMBER,
                                     pQUANTIDADE IN NUMBER,
                                     pTIPO       IN VARCHAR2,
                                     pVALIDADE   IN VARCHAR2,
                                     pNUMLOTE    IN VARCHAR2);

    PROCEDURE EFETUAR_TROCA_ESTOQUE_AVARIA(pCODFILIAL  IN VARCHAR2,
                                           pCODPROD    IN NUMBER,
                                           pQUANTIDADE IN NUMBER,
                                           pTIPO       IN VARCHAR2,
                                           pNUMLOTE    IN VARCHAR2);

    PROCEDURE GERAR_PENDENCIA_MOV_ESTOQUE(pCODFILIAL  IN VARCHAR2,
                                          pCODPROD    IN NUMBER,
                                          pCODOPER    IN VARCHAR2,
                                          pQUANTIDADE IN NUMBER,
                                          pORIGEM     IN VARCHAR2,
                                          pNUMLOTE    IN VARCHAR2,
                                          pVALIDADE   IN VARCHAR2);

  FUNCTION GET_VALIDADE_MINIMA_PRODUTO(PNUMPED  IN NUMBER,
                                       PCODPROD IN NUMBER) RETURN VARCHAR2;

  PROCEDURE GRAVAR_LOG(pPATCH IN VARCHAR2,
                       pTIPO  IN VARCHAR2,
                       pBODY  IN VARCHAR2);

  PROCEDURE ENVIARDOCFILAINTEGRACAOITEM(pNUMDOCWMSSAAS IN NUMBER,
                                        pCODPROD       IN NUMBER,
                                        pQTORIG        IN NUMBER,
                                        pQT            IN NUMBER,
                                        pNUMSEQ        IN NUMBER);

END PKG_INTEGRACAOWMSSAAS;