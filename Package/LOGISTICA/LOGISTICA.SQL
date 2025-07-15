CREATE OR REPLACE PACKAGE LOGISTICA IS

  /*--------------------------------------------------------------------------------------------------------------------
  Autor                SolicitaÃ§Ã£o        Data         DescriÃ§Ã£o
  Rodrigo Santos       2419.031297.2016   13/04/2016   CriaÃ§Ã£o da nova package para operaÃ§Ãµes logÃ­sticas(MÃ³d-011).
  
  --------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE GERAR_NF_INVENTARIO(PNUMINVENT           IN NUMBER,
                                PCODFILIAL           IN VARCHAR2,
                                PCFOP_ENTR           IN NUMBER,
                                PCFOP_SAID           IN NUMBER,
                                PORLOTE              IN VARCHAR2 DEFAULT 'N',
                                PMATRICULA           IN NUMBER,
                                PRETORNO             OUT VARCHAR2,
                                PNUMTRANSVENDA       OUT NUMBER,
                                PNUMTRANSVENDA_LISTA OUT VARCHAR2,
                                PNUMTRANSENT         OUT NUMBER,
                                PNUMTRANSENT_LISTA   OUT VARCHAR2);

  FUNCTION GERAR_CUSTOS_PCMOV(PROWID_PCMOV     VARCHAR2,
                              PATUALIZAR_PCEST VARCHAR2 DEFAULT 'S')
    RETURN VARCHAR2;

  PROCEDURE INSERIR_COMPLEMENTODESCPROD(pnROTINA       IN PCPEDI.ROTINALANC%TYPE,
                                        pnNUMPED       IN PCPEDI.NUMPED%TYPE,
                                        pnCODPROD      IN PCPEDI.CODPROD%TYPE,
                                        pnNUMSEQANTIGO IN PCPEDI.NUMSEQ%TYPE,
                                        pnNUMSEQNOVO   IN PCPEDI.NUMSEQ%TYPE);

  PROCEDURE DELETAR_COMPLEMENTODESCPROD(pnROTINA       IN PCPEDI.ROTINALANC%TYPE,
                                        pnNUMPED       IN PCPEDI.NUMPED%TYPE,
                                        pnCODPROD      IN PCPEDI.CODPROD%TYPE,
                                        pnNUMSEQANTIGO IN PCPEDI.NUMSEQ%TYPE);

END LOGISTICA;
