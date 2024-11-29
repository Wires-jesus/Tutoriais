CREATE OR REPLACE PACKAGE PKG_MEDICAMENTOS
/***********************************************************************************************
  #VERSAO20191227A
  ----------------------------------------------------------------------------------------------
  Package de Processos Específicos do Módulo de Medicamentos
  ----------------     Historico     -----------------------------------------------------------
  Data        Responsável        Tarefa          Comentario
  27/02/2018  Anderson Silva     DDMEDICA-570    Primeira Versao
  04/11/2019  Anderson Silva     DDMEDICA-1241   RCA por Linha e Tributação de Pedido Avaria
  20/11/2019  Anderson Silva     DDMEDICA-1388   Opção para usar aba perda da tributação no pedido de avaria
  28/12/2019  Anderson Silva     DDMEDICA-1691   PMPF na Base do ST
  24/01/2019  Anderson Silva     DDMEDICA-1953   ST exclusivo para Avaria de Perda vinculado ao GERACP
  05/06/2020  Anderson Silva     DDMEDICA-3065   Desoneração do Recálculo do ST
  05/08/2020  Anderson Silva     DDMEDICA-3545   Não processar Comissão RCA Nula
  17/08/2020  Anderson Silva     DDMEDICA-3639   Simples Nacional ST Fonte na Integradora 
  22/12/2020  Anderson Silva     DDMEDICA-5115 - Transferência de Avaria não gravar como Simples Remessa
  25/05/2020  Anderson Silva     DDMEDICA-6666   Recalculo ST Itens Bonificados inseridos pelo Brinde Express na INTEGRADORA_MED
  10/06/2021  Anderson Silva     DDMEDICA-6772   Movida para esta Package o Procedimento para Definir o Código Fiscal
  29/06/2021  Anderson Silva     DDMEDICA-6900   Procedimento para obter o Custo da Promoção de Markup
  15/09/2021  Anderson Silva     DDMEDICA-7594   Customização da Base ST com SUFRAMA/Redução PISCOFINS e DESONERACAO
  30/09/2021  Anderson Silva     DDMEDICA-7697   ST Recolhido anteriormente
  21/10/2021  Anderson Silva     DDVENDAS-31316  ST Antecipado não somar ao CMV
  27/10/2021  Anderson Silva     DDVENDAS-31441  Preencher campos de BCR com o ST Antecipado
  24/11/2021  Anderson Silva     DDVENDAS-32054  VLICMSSUBSTITUTOANTERIOR - aplicar a Aliq 2 do ST
  21/02/2022  Anderson Silva     DDVENDAS-33718  Utilizar Endereço Entrega
  22/03/2022  Anderson Silva     DDVENDAS-34479  PMPF podendo ser recebido por embalagem
  19/04/2022  Anderson Silva     DDVENDAS-35050  Ajuste para melhorar as dependências centralizando alguns procedimentos nesta Package
  24/04/2022  Anderson Silva     DDVENDAS-35125  Melhoria Referências Externas
  04/05/2022  Anderson Silva     DDVENDAS-35253  Limitar ST FECP a Clientes com ST Fonte
  02/06/2022  Anderson Silva     DDVENDAS-35830  Exceções ABCFARMA/CMED
  15/08/2022  Anderson Silva     DDVENDAS-37241  Cálculo da Desoneração somente no Faturamento
  28/09/2022  Anderson Silva     DDVENDAS-38075 - PMC não entra nas Exceções CMED
  30/12/2022  Anderson Silva     DDVENDAS-39621 - Ajuste chamada ST 4.0
  28/02/2023  Anderson Silva     DDVENDAS-40446 - Performance cálculo Função PIS_COFINS_ICMS
  27/04/2023  Anderson Silva     DDVENDAS-41753 - Inclusão de prioriadade de exceção do Convênio Isenção ICMS
  14/02/2024  Anderson Silva     DDVENDAS-46088 - Filial Retira por Cliente Filial e UF Cliente
 ************************************************************************************************/
IS PRAGMA SERIALLY_REUSABLE;

  -- DDVENDAS-33718
  FUNCTION F_OBTER_VERSIONAMENTO RETURN VARCHAR2;

  /*******************************************************************************
   Nome         : P_DEFINIR_CODFISCAL
   Descricão    : Procedimento para definir o Código Fiscal
  ********************************************************************************/
  PROCEDURE P_DEFINIR_CODFISCAL(pi_vCodFilial             IN  VARCHAR2,
                                pi_nCodCli                IN  NUMBER,
                                pi_nCodProd               IN  NUMBER,
                                pi_nCodSt                 IN  VARCHAR2,
                                pi_nCondVenda             IN  NUMBER,
                                pi_nNumNotaConsign        IN  NUMBER,
                                pi_vTipoCfopTv4           IN  VARCHAR2,
                                pi_vCodCob                IN  VARCHAR2,
                                pi_vProntaEntrega         IN  VARCHAR2,
                                pi_vUsaCfopVendaNaTv10    IN  VARCHAR2,
                                pi_vVendaTriangular       IN  VARCHAR2,
                                pi_vContaOrdem            IN  VARCHAR2,
                                pi_nCodBnf                IN  NUMBER,
                                pi_vFornecEntrega         IN  VARCHAR2,
                                pi_nNumTransEntOrigConsig IN  NUMBER,     
                                pi_nCfopNfDegusta         IN  NUMBER,
                                pi_nVlDescSuframa         IN  NUMBER,     
                                pi_nPVenda                IN  NUMBER,
                                pi_vBonific               IN  VARCHAR2,  
                                pi_vRegimeEspIsenStFonte  IN  VARCHAR2,
                                po_nCodFiscal             OUT NUMBER,                                   
                                po_vSitTrib               OUT VARCHAR2,
                                po_vTipoCodFiscal         OUT VARCHAR2,
                                po_vTipoSitTrib           OUT VARCHAR2,
                                pi_vEstEnt                IN  VARCHAR2 DEFAULT NULL); -- DDVENDAS-33718

  /*******************************************************************************
   Nome         : PRC_MED_OBTER_COMISSAO
   Descricão    : Procedimento para Obter a Comissão para os critérios estabelecidos
                  nos Parãmetros
  ********************************************************************************/
  PROCEDURE P_OBTER_COMISSAO(pi_nTipoChamada         IN  NUMBER,
                             pi_nTipoDefinicaoComiss IN  NUMBER,
                             pi_nCodPromocaoMed      IN  NUMBER,
                             pi_nCodProd             IN  NUMBER,
                             pi_nCodCli              IN  NUMBER,
                             pi_dData                IN  DATE,
                             pi_vCodFilial           IN  VARCHAR2,
                             pi_nNumRegiao           IN  NUMBER,
                             pi_nCodUsur             IN  NUMBER,
                             pi_nMatricula           IN  NUMBER,
                             pi_vOrigemPed           IN  VARCHAR2,
                             pi_vTipoFv              IN  VARCHAR2,
                             pi_nCodPlPag            IN  NUMBER,
                             pi_nQtde                IN  NUMBER,
                             pi_nPerDesc             IN  NUMBER,
                             pi_nCodDesconto         IN  NUMBER,
                             pi_vTipoComissao        IN  VARCHAR2, 
                             po_nPerCom              OUT NUMBER,                                       
                             po_vOcorreramErros      OUT VARCHAR2,
                             po_vMsgErros            OUT VARCHAR2,
                             pi_nCodEdital           IN  NUMBER DEFAULT 0);

 /**********************************************************************************************
  OBJETO...: P_OBTER_DIAS_PRAZO_PEDIDO
  DESCRIÇÃO: Procedure para retornar os dias de Prazo de 1 a 12 do Plano de Pagamento
             DDMEDICA-570
  **********************************************************************************************/  
  PROCEDURE P_OBTER_DIAS_PRAZO_PEDIDO(pi_vCarregarTabTemp   IN VARCHAR2,
                                      pi_nCodPlPag          IN NUMBER,
                                      pi_nCodPlPagEtico     IN NUMBER,
                                      pi_nCodPlPagGenerico  IN NUMBER,
                                      pi_dDtEntrega         IN DATE,
                                      pi_nNumPed            IN NUMBER,
                                      pi_nCondVenda         IN NUMBER,
                                      pi_vOrigemPed         IN VARCHAR2,
                                      pi_vTipoFv            IN VARCHAR2,
                                      pi_vTipoPrazoMedicam  IN VARCHAR2,
                                      pi_nValorEticos       IN NUMBER,
                                      pi_nValorGenericos    IN NUMBER,
                                      pi_dDtVencCustomizado IN DATE,
                                      po_vCalculouPrazos   OUT VARCHAR2,
                                      po_nQtdePrazosCalc   OUT NUMBER,
                                      po_nPrazo1           OUT NUMBER,
                                      po_nPrazo2           OUT NUMBER,
                                      po_nPrazo3           OUT NUMBER,
                                      po_nPrazo4           OUT NUMBER,
                                      po_nPrazo5           OUT NUMBER,
                                      po_nPrazo6           OUT NUMBER,
                                      po_nPrazo7           OUT NUMBER,
                                      po_nPrazo8           OUT NUMBER,
                                      po_nPrazo9           OUT NUMBER,
                                      po_nPrazo10          OUT NUMBER,
                                      po_nPrazo11          OUT NUMBER,
                                      po_nPrazo12          OUT NUMBER,
                                      po_nPrazoMedio       OUT NUMBER,
                                      pi_vUsarPrazoCustom   IN VARCHAR2 DEFAULT 'N',
                                      pi_nPrazoCustom1      IN NUMBER DEFAULT NULL,
                                      pi_nPrazoCustom2      IN NUMBER DEFAULT NULL,
                                      pi_nPrazoCustom3      IN NUMBER DEFAULT NULL,
                                      pi_nPrazoCustom4      IN NUMBER DEFAULT NULL,
                                      pi_nPrazoCustom5      IN NUMBER DEFAULT NULL,
                                      pi_nPrazoCustom6      IN NUMBER DEFAULT NULL,
                                      pi_nPrazoCustom7      IN NUMBER DEFAULT NULL,
                                      pi_nPrazoCustom8      IN NUMBER DEFAULT NULL,
                                      pi_nPrazoCustom9      IN NUMBER DEFAULT NULL,
                                      pi_nPrazoCustom10     IN NUMBER DEFAULT NULL,
                                      pi_nPrazoCustom11     IN NUMBER DEFAULT NULL,
                                      pi_nPrazoCustom12     IN NUMBER DEFAULT NULL);                                     

  /*******************************************************************************
   Nome         : P_OBTEM_PMPF
   Descricão    : Procedimento Obter o PMPF dos Medicamentos
  **********************************************************************************/                                       
  PROCEDURE P_OBTEM_PMPF(pi_nCodSt   IN  VARCHAR2,
                         pi_nCodProd IN  NUMBER,
                         pi_nCodCli  IN  VARCHAR2,                               
                         po_nPmPf    OUT NUMBER,
                         pi_vEstEnt  IN  VARCHAR2 DEFAULT NULL); -- DDVENDAS-33718
            
  /*******************************************************************************
   Nome         : F_GET_SOMADESCUNITBENEFFISCAIS - DDMEDICA-7584
   Descricão    : Função para retornar o somatório dos valores unitários dos descontos de benefícios fiscais
   Parâmetros   : ENTRADA:
                  pi_nVLDESCICMISENCAO
                  pi_nVLDESCSUFRAMA
                  pi_nVLDESCPISSUFRAMA
                  pi_nVLDESCREDUCAOPIS
                  pi_nVLDESCREDUCAOCOFINS
  **********************************************************************************/                                       
  FUNCTION F_GET_SOMADESCUNITBENEFFISCAIS(pi_nVLDESCICMISENCAO    IN NUMBER,
                                          pi_nVLDESCSUFRAMA       IN NUMBER,
                                          pi_nVLDESCPISSUFRAMA    IN NUMBER,
                                          pi_nVLDESCREDUCAOPIS    IN NUMBER,
                                          pi_nVLDESCREDUCAOCOFINS IN NUMBER) 
  RETURN NUMBER;
                                  
  /*******************************************************************************
   Nome         : P_TAXACORDOPARCERIA
   Descrição    : Função para retornar a Taxa de Desconto a Aplicar sobre o Preço Tabela
  ********************************************************************************/
  PROCEDURE P_TAXACORDOPARCERIA(pi_vCodFilial       IN  VARCHAR2,
                                pi_vCodFilialNf     IN  VARCHAR2,
                                pi_nCodProd         IN  NUMBER,
                                pi_nCodCli          IN  NUMBER,
                                pi_nNumRegiao       IN  NUMBER,
                                pi_nCondVenda       IN  NUMBER,
                                pi_vOrigemPed       IN  VARCHAR2,
                                pi_vTipoFv          IN  VARCHAR2,
                                pi_nIntegradora     IN  NUMBER,
                                pi_nCodPlPag        IN  NUMBER,
                                pi_dDtBase          IN  DATE,
                                po_vAchouTaxa       OUT VARCHAR2,
                                po_nCodAcordo       OUT NUMBER,
                                po_nPercTaxa        OUT NUMBER,
                                po_nPerCom          OUT NUMBER,
                                po_vCampo           OUT VARCHAR2,
                                pi_vTipoChamada     IN  VARCHAR2 DEFAULT 'T');
                           
  /***************************************************************************************************
   Nome         : P_OBTEM_VLREPASSE
   Descricão    : Procedimento Obter o Valor do Repasse
  ***************************************************************************************************/                                       
  PROCEDURE P_OBTEM_VLREPASSE(pi_vCodFilial              IN  VARCHAR2,
                              pi_nCodCli                 IN  NUMBER,
                              pi_nNumRegiao              IN  NUMBER,
                              pi_nCondVenda              IN  NUMBER,
                              pi_nCodProd                IN  NUMBER,
                              pi_nCodSt                  IN  NUMBER,
                              pi_nPrecoFabrica           IN  NUMBER,
                              pi_nPrecoLiquido           IN  NUMBER,
                              pi_vTipoAplicRepasseFilial IN  VARCHAR2,
                              pi_vCriticaObrigatorio     IN  VARCHAR2,
                              pi_nIntegradora            IN  NUMBER,
                              pi_vOrigemPed              IN  VARCHAR2,
                              pi_vTipoFV                 IN  VARCHAR2,
                              po_vMensagem               OUT VARCHAR2,
                              po_vTipoRepasse            OUT VARCHAR2,
                              po_nVlRepasse              OUT NUMBER );
                           
 /**********************************************************************************************
  OBJETO...: P_OBTEM_STFONTE_40
  DESCRIÇÃO: Procedimento Obter a Base e Valor do ST Fonte por Preço de Tabela ou Preço de Venda
  **********************************************************************************************/  
  PROCEDURE P_OBTEM_STFONTE_40(pi_vCodFilial             IN VARCHAR2,
                               pi_nCodProd               IN NUMBER,
                               pi_nCodCli                IN NUMBER,
                               pi_nNumRegiao             IN NUMBER,
                               pi_nCondVenda             IN NUMBER,
                               pi_nPercVenda             IN NUMBER,
                               pio_nCodSt                IN OUT NUMBER,
                               pi_vPVenda                IN NUMBER,
                               pi_nValorIpi              IN NUMBER,                                
                               pi_nPrecoMaxConsum        IN NUMBER,
                               pi_nValorUltEnt           IN NUMBER,
                               pi_nCustoNfSemSt          IN NUMBER,
                               pi_nPTabela               IN NUMBER,
                               pi_vSomenteIVATribut      IN VARCHAR2,
                               pi_vPesquisarCustos       IN VARCHAR2,
                               pi_vItemBonific           IN VARCHAR2,
                               pi_nVlFreteOutrasDesp     IN NUMBER,
                               po_nBaseStFonte          OUT NUMBER,
                               po_nValorStFonte         OUT NUMBER,
                               po_vMensagem             OUT VARCHAR2,
                               po_vRegimeEspIsenStFonte OUT VARCHAR2,
                               po_nAliqIcms1            OUT NUMBER,
                               po_nAliqIcms2            OUT NUMBER,
                               po_nIva                  OUT NUMBER,
                               po_nPercBaseRedStFonte   OUT NUMBER,
                               pi_vTipoChamada           IN VARCHAR2 DEFAULT 'O',
                               pi_nQT                    IN NUMBER DEFAULT 0,
                               pi_nNumPedido             IN NUMBER DEFAULT NULL,
                               pi_nCodFilialNf           IN VARCHAR2,
                               po_nPautaFonte           OUT NUMBER,
                               po_vObservacaoStFonte    OUT VARCHAR2,
                               po_vIndEscalaRelevante   OUT VARCHAR2,
                               po_vCnpjFabricante       OUT VARCHAR2,
                               po_vFabricante           OUT VARCHAR2,
                               po_nVLBASEFCPICMS        OUT NUMBER, -- HIS.04200.2017
                               po_nVLBASEFCPST          OUT NUMBER, -- HIS.04200.2017
                               po_nVLBCFCPSTRET         OUT NUMBER, -- HIS.04200.2017
                               po_nPERFCPSTRET          OUT NUMBER, -- HIS.04200.2017
                               po_nVLFCPSTRET           OUT NUMBER, -- HIS.04200.2017
                               po_nPERFCPSN             OUT NUMBER, -- HIS.04200.2017
                               po_nVLFECP               OUT NUMBER, -- HIS.04200.2017
                               po_nVLACRESCIMOFUNCEP    OUT NUMBER, -- HIS.04200.2017
                               po_nPERACRESCIMOFUNCEP   OUT NUMBER, -- HIS.04200.2017
                               po_nALIQICMSFECP         OUT NUMBER, -- HIS.04200.2017
                               po_nVLCREDFCPICMSSN      OUT NUMBER, -- HIS.04200.2017
                               po_nCODCONFIGFUNCEPMED   OUT NUMBER,
                               pi_vOrdemCalculo          IN VARCHAR2 DEFAULT 'F',
                               pi_vMemoriaCalculo        IN VARCHAR2 DEFAULT 'N',
                               pi_nValorNotaFiscal       IN NUMBER   DEFAULT 0,
                               pi_vPedidoAvaria          IN VARCHAR  DEFAULT 'N'
                               );

 /**********************************************************************************************
  OBJETO...: P_OBTEM_STFONTE_42
  DESCRIÇÃO: Procedimento Obter a Base e Valor do ST Fonte por Preço de Tabela ou Preço de Venda
             com a Regra do ST Recolhido Anteriormente
  **********************************************************************************************/  
  PROCEDURE P_OBTEM_STFONTE_42(pi_vCodFilial                IN VARCHAR2,
                               pi_nCodProd                  IN NUMBER,
                               pi_nCodCli                   IN NUMBER,
                               pi_nNumRegiao                IN NUMBER,
                               pi_nCondVenda                IN NUMBER,
                               pi_nPercVenda                IN NUMBER,
                               pio_nCodSt                   IN OUT NUMBER,
                               pi_vPVenda                   IN NUMBER,
                               pi_nValorIpi                 IN NUMBER,                                
                               pi_nPrecoMaxConsum           IN NUMBER,
                               pi_nValorUltEnt              IN NUMBER,
                               pi_nCustoNfSemSt             IN NUMBER,
                               pi_nPTabela                  IN NUMBER,
                               pi_vSomenteIVATribut         IN VARCHAR2,
                               pi_vPesquisarCustos          IN VARCHAR2,
                               pi_vItemBonific              IN VARCHAR2,
                               pi_nVlFreteOutrasDesp        IN NUMBER,
                               po_nBaseStFonte             OUT NUMBER,
                               po_nValorStFonte            OUT NUMBER,
                               po_vMensagem                OUT VARCHAR2,
                               po_vRegimeEspIsenStFonte    OUT VARCHAR2,
                               po_nAliqIcms1               OUT NUMBER,
                               po_nAliqIcms2               OUT NUMBER,
                               po_nIva                     OUT NUMBER,
                               po_nPercBaseRedStFonte      OUT NUMBER,
                               pi_vTipoChamada              IN VARCHAR2 DEFAULT 'O',
                               pi_nQT                       IN NUMBER DEFAULT 0,
                               pi_nNumPedido                IN NUMBER DEFAULT NULL,
                               pi_nCodFilialNf              IN VARCHAR2,
                               po_nPautaFonte              OUT NUMBER,
                               po_vObservacaoStFonte       OUT VARCHAR2,
                               po_vIndEscalaRelevante      OUT VARCHAR2,
                               po_vCnpjFabricante          OUT VARCHAR2,
                               po_vFabricante              OUT VARCHAR2,
                               po_nVLBASEFCPICMS           OUT NUMBER,
                               po_nVLBASEFCPST             OUT NUMBER,
                               po_nVLBCFCPSTRET            OUT NUMBER,
                               po_nPERFCPSTRET             OUT NUMBER,
                               po_nVLFCPSTRET              OUT NUMBER,
                               po_nPERFCPSN                OUT NUMBER,
                               po_nVLFECP                  OUT NUMBER,
                               po_nVLACRESCIMOFUNCEP       OUT NUMBER,
                               po_nPERACRESCIMOFUNCEP      OUT NUMBER,
                               po_nALIQICMSFECP            OUT NUMBER,
                               po_nVLCREDFCPICMSSN         OUT NUMBER,
                               po_nCODCONFIGFUNCEPMED      OUT NUMBER,
                               pi_vOrdemCalculo             IN VARCHAR2 DEFAULT 'F',
                               pi_vMemoriaCalculo           IN VARCHAR2 DEFAULT 'N',
                               pi_nValorNotaFiscal          IN NUMBER   DEFAULT 0,
                               pi_vPedidoAvaria             IN VARCHAR  DEFAULT 'N',
                               po_nBCSTRETANTERIOR          OUT NUMBER,
                               po_nVLICMSSUBSTITUTOANTERIOR OUT NUMBER,                               
                               po_nVLICMSSTRETANTERIOR      OUT NUMBER,
                               po_nSTCLIENTEGNRE            OUT NUMBER,
                               po_nPMPF                     OUT NUMBER,
                               po_vClienteFonteSt           OUT VARCHAR2,
                               pi_vEstEnt                   IN VARCHAR2 DEFAULT NULL, -- DDVENDAS-33718
                               pi_nQtUnitEmb                IN NUMBER DEFAULT NULL);  -- DDVENDAS-34479
       
 /*******************************************************************************
  Nome         : P_OBTER_VALORES_BENEF_FISCAIS
  Descricão    : Procedimento Obter os valores dos Descontos dos Benefícios 
                 Fiscais: 
                 - SUFRAMA
                 - DESONERAÇÃO ICMS
                 - Redução PIS e COFINS
  Solicitação  : DDMEDICA-7594                
  *******************************************************************************/
  PROCEDURE P_OBTER_VALORES_BENEF_FISCAIS(pi_vCodFilial               IN VARCHAR2,
                                          pi_vCodFilialNf             IN VARCHAR2,
                                          pi_nCodCli                  IN NUMBER,
                                          pi_nCodProd                 IN NUMBER,
                                          pi_nCodSt                   IN NUMBER,
                                          pi_nNumCasasDecVenda        IN NUMBER,
                                          pi_vTipoCalcSuframa         IN VARCHAR2,
                                          pi_nPerDescIsencaoIcmsTrib  IN NUMBER,
                                          pi_vAplicaDescIsencaoMed    IN VARCHAR2,
                                          pi_nPVendaSemImposto        IN NUMBER,
                                          pi_nPTabelaSemImposto       IN NUMBER,
                                          pi_nPBaseRcaSemImposto      IN NUMBER,
                                          pi_nQt                      IN NUMBER,                                          
                                          po_nVlDescReducaoPis       OUT NUMBER,
                                          po_nPercDescReducaoPis     OUT NUMBER,
                                          po_nVlDescReducaoCofins    OUT NUMBER,
                                          po_nPercDescReducaoCofins  OUT NUMBER,
                                          po_nVlDescIcmIsencao       OUT NUMBER,
                                          po_nPercDescIcmIsencao     OUT NUMBER,
                                          po_nVlDescSuframa          OUT NUMBER,
                                          po_nPercDescSuframa        OUT NUMBER,
                                          po_nNovoPVenda             OUT NUMBER,
                                          po_nNovoPTabela            OUT NUMBER,
                                          po_nNovoPBaseRca           OUT NUMBER,
                                          po_vErros                  OUT VARCHAR2,
                                          po_vMsgErros               OUT VARCHAR2,
                                          pi_vCalcSomenteDesoneracao  IN VARCHAR2 DEFAULT 'N');
       
 /**********************************************************************************************
  OBJETO...: P_RECALCULAR_STFONTE
  DESCRIÇÃO:  Procedimento para Recalcular o ST Fonte de um Pedido
  **********************************************************************************************/  
  PROCEDURE P_RECALCULAR_STFONTE(pi_nNumPed                  IN  NUMBER,
                                 po_vOcorreramErros          OUT VARCHAR2,
                                 pi_vvMsgErros               OUT VARCHAR2,
                                 pi_vTipoChamada             IN  VARCHAR2 DEFAULT 'O',
                                 pi_vCalculaDesoneracaoLicit IN  VARCHAR2 DEFAULT 'N',
                                 pi_vAplicFatConvPedidoVenda IN  VARCHAR2 DEFAULT NULL);

 /*******************************************************************************
  Nome         : P_CALC_RED_SIMPLES_NAC
  Descrição    : Procedimento para calcular a Recução do Simples Nacional 
                 *** Somente para Clientes Fonte ***
  ********************************************************************************/                                       
  PROCEDURE P_CALC_RED_SIMPLES_NAC(psCodFilial                    IN  VARCHAR2,
                                   pCodCli                        IN  NUMBER,
                                   pCodProd                       IN  NUMBER,
                                   pCondVenda                     IN  NUMBER,
                                   pPreco                         IN  NUMBER,
                                   pPrecoTabela                   IN  NUMBER,
                                   pValorIpi                      IN  NUMBER,
                                   pPrecoMaxConsum                IN  NUMBER,
                                   pTipoMerc                      IN  VARCHAR2,
                                   pi_vCodFilialNf                IN  VARCHAR2,
                                   po_vTipoRedSimplesNac          OUT VARCHAR2,
                                   po_nPercRedSimplesNac          OUT NUMBER,
                                   po_nValorRedSimplesNac         OUT NUMBER,
                                   po_ValorRedSimplesNacNoPreco   OUT NUMBER,
                                   po_ValorRedSimplesNacNoStFonte OUT NUMBER,
                                   po_vOcorreramErros             OUT VARCHAR2,
                                   po_vMsgErros                   OUT VARCHAR2,
                                   pi_nNumRegiaoEnt               IN  NUMBER DEFAULT NULL,    -- DDVENDAS-33718
                                   pi_vEstEnt                     IN  VARCHAR2 DEFAULT NULL); -- DDVENDAS-33718

  /*******************************************************************************
   Nome         : P_OBTEM_CUSTO_PROMO_MARKUP
   Descricão    : Procedimento Obter o Custo da Promoção Markup - DDMEDICA-6900
  **********************************************************************************/                                       
  PROCEDURE P_OBTEM_CUSTO_PROMO_MARKUP(pi_vCodFilial               IN  VARCHAR2,
                                       pi_vCodFilialRetira         IN  VARCHAR2,
                                       pi_nCodProd                 IN  NUMBER,
                                       pi_vOrigemCustoFilialRetira IN  VARCHAR2,
                                       pi_vCustoPromMarkupSt       IN  VARCHAR2,
                                       pi_nNumTransEntCrossDock    IN  NUMBER,
                                       pi_nCustoFinanceiro         IN  NUMBER,
                                       po_vAchouCusto              OUT VARCHAR2,
                                       po_nValorCusto              OUT NUMBER);

 /*******************************************************************************
  Nome     : F_DEFINIRNUMREGIAOPEDIDO - DDVENDAS-33718
  Descricão: Função para definir a Região do Pedido baseado no Endereço de Entrega do Cliente
  ********************************************************************************/                                         
  FUNCTION F_DEFINIRNUMREGIAOPEDIDO(pCodCli            IN NUMBER,
                                    pNumRegiao         IN NUMBER,
                                    pUtilizaTribEndEnt IN VARCHAR2,
                                    pCodEndEnt         IN NUMBER,
                                    pEstEnt            IN VARCHAR2) RETURN NUMBER;

 /*******************************************************************************
  Nome     : F_DEFINIRNUMREGIAOPEDIDO - DDVENDAS-33718
  Descricão: Função para definir a UF de Destino do Pedido baseado no Endereço de Entrega do Cliente
  ********************************************************************************/                                         
  FUNCTION F_DEFINIRUFDESTINOPEDIDO(pCodCli            IN NUMBER,
                                    pUtilizaTribEndEnt IN VARCHAR2,
                                    pCodEndEnt         IN NUMBER,
                                    pEstEnt            IN VARCHAR2) RETURN VARCHAR2;
                     
  /*******************************************************************************
   Nome         : PRC_MED_OBTEM_PMC_PRODUTO
   Descricão    : Procedimento Obter o PMC do Produto
  ********************************************************************************/                                       
  PROCEDURE P_OBTEM_PMC_PRODUTO(pi_vCodFilial    IN  VARCHAR2,
                                pi_nCodProd      IN  NUMBER,
                                pi_vUfCliente    IN  VARCHAR2,
                                pi_nRegiao       IN  NUMBER,
                                po_nPmc          OUT NUMBER,
                                po_nPrecoFabrica OUT NUMBER,
                                po_vMensagem     OUT VARCHAR2,
                                pi_nCodCli       IN  NUMBER DEFAULT NULL);

  /*******************************************************************************
   Nome         : P_CALC_DESONERACAO_FATURAMENTO
   Descricão    : Procedimento para Calcular a Desoneração no Faturamento - DDVENDAS-37241
  **********************************************************************************/                                       
  PROCEDURE P_CALC_DESONERACAO_FATURAMENTO(pi_nNumPed        IN NUMBER,
                                           po_vOcorreuErro  OUT VARCHAR2,
                                           po_vMensagemErro OUT VARCHAR);

  /*******************************************************************************
   Nome         : P_OBTER_FILIAL_RETIRA_CLIENTE
   Descricão    : Procedimento para Obter a Filial Retira do Cliente
  **********************************************************************************/                                       
  PROCEDURE P_OBTER_FILIAL_RETIRA_CLIENTE(pi_nCodCli            IN  NUMBER,
                                          pi_vCodFilial         IN  VARCHAR2,
                                          pi_nCodFornec         IN  NUMBER,
                                          pi_vUfCliente         IN  VARCHAR2,
                                          po_vAchouFilialRetira OUT VARCHAR2,
                                          po_vCodFilialRetira   OUT VARCHAR);

  /*******************************************************************************
   Nome         : P_OBTER_FILIAL_RETIRA_CLICOMBO
   Descricão    : Procedimento para Obter a Filial Retira do Cliente num COMBO
  **********************************************************************************/                                       
  PROCEDURE P_OBTER_FILIAL_RETIRA_CLICOMBO(pi_nCodPromocaoMed    IN  NUMBER,
                                           pi_nCodCli            IN  NUMBER,
                                           pi_vCodFilial         IN  VARCHAR2,
                                           pi_vUfCliente         IN  VARCHAR2,
                                           po_vAchouFilialRetira OUT VARCHAR2,
                                           po_vCodFilialRetira   OUT VARCHAR);

END PKG_MEDICAMENTOS;