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
									
  PROCEDURE FINALIZARSEPARACAOITEMFILA(pCODFILIAL           IN VARCHAR2,
                                    pNUMDOCWMSSAAS          IN NUMBER,
                                    pCODPROD                IN NUMBER,
                                    pNUMSEQ                 IN NUMBER,
                                    pQTSEPARADA             IN NUMBER,
                                    pNUMLOTE                IN VARCHAR2);									

END PKG_INTEGRACAOWMSSAAS;