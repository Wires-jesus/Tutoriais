CREATE OR REPLACE PACKAGE PKG_CAMPANHACOMBO IS

  /*--------------------------------------------------------------------------------------------------------------------
  Autor                Solicitação        Data         Descrição
  Iran Junor           HIS.03255.2016   19/12/2016    Package para controle de campanhas de desconto por combo
  Guilherme Freitas    0.000295.2017    02/01/2017    Ajustados processos dentro da package.
  --------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE InserirComboCli(pCODFILIAL     IN VARCHAR2,
                            pNUMPED        IN VARCHAR2,
                            pCODPROD       IN NUMBER,
                            pCODCLI        IN NUMBER,
                            pPERDESC       IN NUMBER,
                            pCODCOMBO      IN NUMBER,
                            pCODGRUPOCOMBO IN NUMBER,
                            pNUMSEQ        IN NUMBER,
                            pQT            IN NUMBER,
                            pCODAUXILIAR   IN NUMBER);

  FUNCTION BuscaDesconto(pCODFILIAL     IN VARCHAR2,
                         pCODPROD       IN NUMBER,
                         pCODCLI        IN NUMBER,
                         pNUMPED        IN NUMBER,
                         pCODAUXILIAR   IN NUMBER DEFAULT 0,
                         pInclusaoCombo IN VARCHAR2 DEFAULT 'N',
                         pCODCOMBO      IN NUMBER DEFAULT 0) RETURN NUMBER;
						 
  FUNCTION BuscaCampanhaDesconto(pCODFILIAL     IN VARCHAR2,
                                 pCODPROD       IN NUMBER,
                                 pCODCLI        IN NUMBER,
                                 pNUMPED        IN NUMBER,
                                 pCODAUXILIAR   IN NUMBER,
                                 pInclusaoCombo IN VARCHAR2,
                                 pCODCOMBO      IN OUT NUMBER,
                                 pCODCAMPANHA   IN OUT NUMBER) RETURN NUMBER;

  FUNCTION VerificaCampanhasDesconto(p_numped        in pcpedc.numped%type,
                                     p_codfilial     in pcpedc.codfilial%type,
                                     p_numregiao     in pcpedc.numregiao%type,
                                     p_codcli        in pcpedc.codcli%type,
                                     p_codativ       in pcclient.codatv1%type,
                                     p_codusur       in pcpedc.codusur%type,
                                     p_codsupervisor in pcpedc.codsupervisor%type,
                                     p_coddistrib    in pcpedc.coddistrib%type,
                                     p_codcombo      in pcdescontoc.codigo%type,
                                     p_mensagem      out varchar2,
                                     p_codplpag      in pcpedc.codplpag%type default 0) RETURN BOOLEAN;

  FUNCTION BuscaItensFaixaSQP(pNUMPED       IN NUMBER,
                              pCODCOMBO     IN NUMBER,
                              pCODFILIAL    IN VARCHAR2 DEFAULT NULL,
                              pCODFAIXA     IN NUMBER DEFAULT NULL,
                              pTIPOCAMPANHA IN VARCHAR2 DEFAULT NULL,
                              pMSG          OUT VARCHAR2) RETURN VARCHAR2;

  TYPE TR_DADOS_ITENSPEDIDO IS RECORD (
    PTABELA            PCPEDI.PTABELA%TYPE
   ,PVENDA             PCPEDI.PVENDA%TYPE
   ,CODPROD            PCPEDI.CODPROD%TYPE
   ,PERDESC            PCPEDI.PERDESC%TYPE);

END PKG_CAMPANHACOMBO;
