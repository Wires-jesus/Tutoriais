CREATE OR REPLACE PACKAGE PKG_CREDITOCLIENTE IS

  VSVERSAOPACKAGE VARCHAR(100) := '31.1.10.1';

  /*
  1. "FNC_BAIXARCREDITOCLIENTE"
  FUNÇÃO CRIADA PARA ATENDER A PACKAGE DE FATURAMENTO DA EQUIPE DE VENDAS.
  ONDE É PASSADO A NOTA, VALOR E CLIENTE. AUTOMATICAMENTE É FEITO AS BAIXAS DOS CREDITOS EM ABERTO.
  */
  FUNCTION FNC_BAIXARCREDITOCLIENTE(psFILIAL           IN VARCHAR2,
                                    pfCODCLI           IN NUMBER,
                                    pfNUMNOTA          IN NUMBER,
                                    pfNUMTRANSVENDA    IN NUMBER,
                                    pfNUMPED           IN NUMBER,
                                    pfVALORNOTA        IN NUMBER,
                                    pfCODIGOROTINA     IN NUMBER,
                                    pfMATRICULAUSUARIO IN NUMBER
                                   )
  RETURN NUMBER;
  ----------------------------------------------------------------------------------------
  /*
  2. "FNC_ESTORNARCREDITOBAIXADO"
  FUNÇÃO CRIADA PARA ATENDER A FUNCAO DE CANCELAMENTO DE NOTA DA EQUIPE DE VENDAS.
  ONDE É PASSADO O NUMTRANSVENDA E AUTOMATICA SERA LOCALIZADO OS CREDITOS BAIXADOS E FEITO O ESTORNO TORNANDO EM ABERTO NOVAMENTE.
  O VALOR RETORNADO É O TOTAL DE CREDITO QUE CONSEGUIU SER ESTORNADO.
  PARA ATENDER A ROTINA 1209:
  **SE TIVER DE ESTORNAR O CREDITO DE UM TITULO ESPECIFICO SERÁ NECESSARIO INFORMAR "pfPRESTACAO" QUE EQUIVALE A BUSCAR PELO TITULO.
  **PARA ESTORNAR AUTOMATICAMENTE A PCPREST BASTA MARCAR O PARAMETRO "pbGERARPCPRESTAUTOMATICAMENTE", LEMBRANDO QUE PRECISA TAMBÉM DO "pfPRESTACAO.
  */
  FUNCTION FNC_ESTORNARCREDITOBAIXADO(pfNUMTRANSVENDA               IN NUMBER,
                                      pfCODIGOROTINA                IN NUMBER,
                                      pfMATRICULAUSUARIO            IN NUMBER,
                                      pfPRESTACAO                   IN VARCHAR2 DEFAULT '0',
                                      pbGERARPCPRESTAUTOMATICAMENTE IN BOOLEAN DEFAULT FALSE
                                     )
  RETURN NUMBER;
  ----------------------------------------------------------------------------------------
  /*
  3. "FNC_TOTALCREDITODISPONIVEL"
  FUNÇÃO RETORNA O TOTAL DE CREDITO DISPONIVEL PARA BAIXA. QUANDO O NUMPED=0 CONSULTA DOS OS CREDITOS, SENÃO APENAS PARA O NUMERO DE PEDIDO INFORMADO.
  */
  FUNCTION FNC_TOTALCREDITODISPONIVEL(psFILIAL           IN VARCHAR2,
                                      pfCODCLI           IN NUMBER,
                                      pfNUMPED           IN NUMBER DEFAULT 0
                                     )
  RETURN NUMBER;
  ----------------------------------------------------------------------------------------
  /*
  4. "FNC_BAIXAR1CREDITONTITULOS"
  PERMITE BAIXA UM CREDITO COM VÁRIOS TITULOS. PARA CADA TITULO PODE SER FEITO BAIXA PARCIAL.
  */
  FUNCTION FNC_BAIXAR1CREDITONTITULOS(pfCODIGOCREDITO           IN NUMBER,
                                      poLISTA_PC_CONTASRECEBER  IN LISTA_PC_CONTASRECEBER,
                                      pfCODIGOROTINA            IN NUMBER,
                                      pfMATRICULAUSUARIO        IN NUMBER
                                     )
  RETURN BOOLEAN;
  ----------------------------------------------------------------------------------------
  /*
  5. "FNC_BAIXAR1TITULONCREDITOS"
  PERMITE BAIXA UM TITULO COM VÁRIOS CREDITOS.
  */
  FUNCTION FNC_BAIXAR1TITULONCREDITOS(poCONTARECEBER            IN OUT T_PC_CONTASRECEBER,
                                      poLISTA_PC_CREDITOCLIENTE IN LISTA_PC_CREDITOCLIENTE,
                                      pfCODIGOROTINA            IN NUMBER,
                                      pfMATRICULAUSUARIO        IN NUMBER
                                     )
  RETURN BOOLEAN;
  ----------------------------------------------------------------------------------------
  /*
  6. "FNC_BAIXADECREDITOVAREJO"
  FUNÇÃO CRIADA PARA SER UTILIZADA PELA EQUIPE DO VAREJO QUE POSSUI SUAS PARTICULARIDADES.
  */
  FUNCTION FNC_BAIXADECREDITOVAREJO(pfCODIGOCREDITO           IN NUMBER,
                                    pfVALORBAIXAR             IN NUMBER,
                                    pfNUMPEDECF               IN NUMBER,
                                    psNUMSERIEEQUIP           IN VARCHAR2,
                                    pfNUMCAIXA                IN NUMBER,
                                    pfNUMCUPOM                IN NUMBER,
                                    psHISTORICO               IN VARCHAR2,
                                    pfCODIGOROTINA            IN NUMBER,
                                    pfMATRICULAUSUARIO        IN NUMBER,
                                    psCODIGOFILIALDESCONTO    IN VARCHAR2,
                                    psCODIGOSCREDITOGERADO    IN OUT VARCHAR2
                                    )
  RETURN LISTA_PC_CREDITOCLIENTE;
  ----------------------------------------------------------------------------------------
  /*
  7. "FNC_ATUALIZABAIXACREDITOVAREJO"
  FUNÇÃO CRIADA PARA SER UTILIZADA PELA EQUIPE DO VAREJO QUE POSSUI SUAS PARTICULARIDADES.
  NESSE MOMENTO IRA ATUALIZAR DADOS DO CREDITO REFERENTE A BAIXA FEITA NA FUNÇÃO "FNC_BAIXADECREDITOVAREJO"
  */
  FUNCTION FNC_ATUALIZABAIXACREDITOVAREJO(pfCODIGOCREDITO           IN NUMBER,
                                          pfCODIGOROTINA            IN NUMBER,
                                          pfMATRICULAUSUARIO        IN NUMBER
                                    )
  RETURN BOOLEAN;
  ----------------------------------------------------------------------------------------
  /*
  8. "FNC_ESTORNARBAIXACREDITOVAREJO"
  FUNÇÃO CRIADA PARA SER UTILIZADA PELA EQUIPE DO VAREJO QUE POSSUI SUAS PARTICULARIDADES.
  FARA O ESTORNO DO CREDITO BAIXADO PELO VAREJO FAZENDO CONFORME CRITERIOS PASSADOS PELO VAREJO
  */
  FUNCTION FNC_ESTORNARBAIXACREDITOVAREJO(pfNUMPEDECF               IN NUMBER,
                                          psNUMSERIEEQUIP           IN VARCHAR2,
                                          pfNUMCAIXA                IN NUMBER,
                                          pfNUMCUPOM                IN NUMBER,
                                          psHISTORICO               IN VARCHAR2,
                                          pfCODIGOROTINA            IN NUMBER,
                                          pfMATRICULAUSUARIO        IN NUMBER ,
                                          psCODIGOSCREDITOGERADO    IN OUT VARCHAR2,
                                          psCAIXAVENDAABERTA        IN VARCHAR2 DEFAULT 'N'
  )
  RETURN VARCHAR2;

  FUNCTION FC_RETORNA_VERSAO return varchar2;

  PROCEDURE INSERELOG(PMETODO VARCHAR2,
                      PCODFILIAL VARCHAR2,
                      PNUMTRANSENT NUMBER,
                      PNUMTRANSVENDA NUMBER,
                      PNUMTRANSVENDADESC NUMBER,
                      PVALORNOTA NUMBER,
                      PVALORCRED NUMBER,
                      PVALORBAIXA NUMBER,
                      POBSERVACAO VARCHAR2,
                      PNUMCRED NUMBER,
                      PNUMPED NUMBER,
                      PCODROTINA NUMBER);
  ----------------------------------------------------------------------------------------
  /*
  9. FNC_CANCELARESTORCREDITOVAREJO
  FUNCAO CRIADA PARA FAZER O CANCELAMENTO DO ESTORNO REALIZADO POR BAIXA PARCIAL NO VAREJO.
  EX: CASO TENHA UM CREDITO DE 100,00 E FACA A BAIXA DE 80,00 FICARA 20,00 EM ABERTO.
  SE O CODIGO INFORMADO FOR DO CREDITO DE 100,00 QUE JA ENCONTRA-SE ESTORNADO, O SISTEMA IRA
  APAGAR OS CREDITOS DE 80,00 E 20,00 VOLTANDO 100,00 EM ABERTO.
  */
  FUNCTION FNC_CANCELARESTORCREDITOVAREJO(pfCODIGOCREDITO IN NUMBER, pUltimoCredito IN VARCHAR2,
           pNUMCUPOM IN NUMBER, pfCODIGOROTINA IN NUMBER, pfMATRICULAUSUARIO IN NUMBER, pCODIGODEST IN NUMBER,
           pNUMPEDECF IN NUMBER, pNUMSERIEEQUIP IN VARCHAR2, pNUMCAIXA IN NUMBER)
  RETURN BOOLEAN;
  ----------------------------------------------------------------------------------------
  /*
  10. FNC_CHECKOUT_BAIXA_CREDITO
  FUNCAO DESENVOLVIDA PELA EQUIPE DO VAREJO E PEDIDA PARA INCLUIR NA PACKAGE DE CREDITO DE CLIENTE
  */
  FUNCTION FNC_CHECKOUT_BAIXA_CREDITO(codigo             IN NUMBER,
                                      valorBaixar        IN NUMBER,
                                      numPedEcf          IN NUMBER,
                                      numSerieEquip      IN VARCHAR2,
                                      numCaixa           IN NUMBER,
                                      numCupom           IN NUMBER,
                                      matriculaOperador  IN NUMBER,
                                      filial             IN VARCHAR2,
                                      psHISTORICO        IN VARCHAR2)
  RETURN VARCHAR2;
  ----------------------------------------------------------------------------------------
  /*
  11. FNC_CANCELARCREDITOCLIENTE
  */
  FUNCTION FNC_CANCELARCREDITOCLIENTE(psFILIAL IN VARCHAR2, 
                                      pfNUMTRANSVENDA IN NUMBER, 
                                      pfVALOR IN NUMBER, 
                                      pfCODIGOROTINA IN NUMBER, 
                                      pfMATRICULAUSUARIO IN NUMBER, 
                                      pfNUMTRANSENT IN NUMBER DEFAULT 0)
  RETURN NUMBER;
  ----------------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------------
  /*
  12. INSERIRREGISTROSVAREJO
  */
  PROCEDURE INSERIRREGISTROSVAREJO(pCODIGO IN NUMBER, pfCODIGOROTINA IN NUMBER, pfMATRICULAUSUARIO IN NUMBER);
  ----------------------------------------------------------------------------------------
   /*
  13. "FNC_BUSCACREDITO_CODIGO"
  */
  FUNCTION FNC_BUSCACREDITO_CODIGO( pfCODIGOCREDITO    IN NUMBER,
                                    psFILIAL           IN VARCHAR2
                                    )
  RETURN NUMBER;
  ----------------------------------------------------------------------------------------
END PKG_CREDITOCLIENTE;