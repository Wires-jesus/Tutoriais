CREATE OR REPLACE PACKAGE PKG_FUNCOESVENDAS_MED
/************************************************************************************************
  #VERSAO20191107A #VERSAO20191110A #VERSAO20191204A #VERSAO20210308A
  -----------------------------------------------------------------------------------------------
  Package de Processos Específicos de Promoção Módulo de Medicamentos
  ----------------     Historico     ------------------------------------------------------------
  Data        Responsável        Tarefa          Comentario
  06/11/2019  Anderson Silva     DDMEDICA-1147   Primeira Versão
  04/12/2019  Anderson Silva     DDMEDICA-1495   Promoção por Lote
  10/01/2019  Anderson Silva     DDMEDICA-1769   Faltas e Avarias Integração WMS - Crossdocking
  22/01/2020  Anderson Silva     DDMEDICA-1888   Importação TV10
  24/01/2020  Anderson Silva     DDMEDICA-1953   Crossdocking
  24/01/2020  Anderson Silva     DDMEDICA-1969   Troca de Nota
  21/09/2020  Anderson Silva     DDMEDICA-4084   Tratamento para não ler Entradas OE
  02/10/2020  Anderson Silva     DDMEDICA-4244   Opção para somar ST do FECP na função para Obter ST Fonte 
  14/10/2020  Anderson Silva     DDMEDICA-4381   Correção Condição ST Avaria/Perda
  07/12/2020  Anderson Silva     DDMEDICA-4993   Merge ST PMPF
  08/03/2021  Anderson Silva     DDMEDICA-5841   Filtrar os Lotes pela Filial do Pedido em Pedido de Avaria
  30/09/2021  Anderson Silva     DDMEDICA-7697   ST Recolhido anteriormente
  15/02/2022  Anderson Silva     DDVENDAS-33636  Depósito por Filial
  25/04/2022  Anderson Silva     DDVENDAS-35125  Melhoria Referências Externas
  04/05/2022  Anderson Silva     DDVENDAS-35253  Limitar ST FECP a Clientes com ST Fonte
  23/05/2022  Anderson Silva     DDVENDAS-35576 - Flexibilização da Regra de Alterar Preço/Desconto 
  26/05/2022  Anderson Silva     DDVENDAS-35697 - Exceções da ABCFARMA/CMED
  31/05/2022  Anderson Silva     DDVENDAS-35778 - Parâmetro para Restrição de Venda conforme Regra de Alterar Preço/Desconto 
  28/09/2022  Anderson Silva     DDVENDAS-38075 - PMC não entra nas Exceções CMED
  06/10/2022  Anderson Silva     DDVENDAS-38166 - Validação de Cotas da Promoção
  30/01/2023  Anderson Silva     DDVENDAS-40111 - Consolidação do uso das cotas da promoção  
  28/02/2023  Anderson Silva     DDVENDAS-40446 - Performance cálculo Função PIS_COFINS_ICMS
 ************************************************************************************************/
IS

  FUNCTION F_OBTER_VERSIONAMENTO RETURN VARCHAR2;
   
 /*******************************************************************************
  Nome         : F_FORMATAR_NUMERO_PARA_TEXTO
  Descricão    : Função para Formatar um Número para Texto
  ********************************************************************************/   
  FUNCTION F_FORMATAR_NUMERO_PARA_TEXTO(pi_nNumero            IN NUMBER,
                                        pi_iQtdeCasasDecimais IN INTEGER) RETURN VARCHAR2;
                                        
 /*******************************************************************************
  Nome         : F_OBTER_LOTES_PEDIDO
  Descricão    : Função para retornar Tabela com os Lotes para Seleção no Pedido
  ********************************************************************************/                                       
  FUNCTION F_OBTER_LOTES_PEDIDO(pi_vTipoPedido     IN VARCHAR2,
                                pi_nOrigemChamada  IN NUMBER,
                                pi_nNumTransEnt    IN NUMBER,
                                pi_nNumPed         IN NUMBER   DEFAULT NULL,
                                pi_nCodProd        IN NUMBER   DEFAULT NULL,
                                pi_nNumSeq         IN NUMBER   DEFAULT NULL,
                                pi_vNumLote        IN VARCHAR2 DEFAULT NULL,
                                pi_vCodFilial      IN VARCHAR2 DEFAULT NULL,
                                pi_nCodPromocaoMed IN NUMBER   DEFAULT NULL)
  RETURN TABELA_MED_OBTER_LOTES_PEDIDO PARALLEL_ENABLE PIPELINED;

  /*******************************************************************************
   Nome         : F_TIPOCOMISSGARANTIDA
   Descricão    : Função para retornar o Tipo de Comissão Garantida
  ********************************************************************************/
  FUNCTION F_TIPOCOMISSGARANTIDA(pi_vTipoComissGarantida      IN VARCHAR2,
                                 pi_vEmpUtilizaComGarantida   IN VARCHAR2,
                                 pi_vPromoUtilizaComGarantida IN VARCHAR2,
                                 pi_vIgnoraRegraMovimentacao  IN VARCHAR2,
                                 pi_vIgnoraRegraPromocao      IN VARCHAR2,
                                 pi_nCodProd                  IN NUMBER,
                                 pi_nCodCli                   IN NUMBER,
                                 pi_nCodUsur                  IN NUMBER,
                                 pi_nPercBonificVenda         IN NUMBER,
                                 pi_nPercDesc                 IN NUMBER,
                                 pi_vTipoRetorno              IN VARCHAR2)
  RETURN VARCHAR2;

 /*******************************************************************************
  Nome         : P_PROMOCAO_VALIDAR_COTA
  Descricão    : Procedimento para Validar as Cotas da Promoção - DDVENDAS-38166
  ********************************************************************************/                                       
  PROCEDURE P_VALIDAR_COTAS_PROMOCAO(pi_nNumPed                IN NUMBER,
                                     pi_nCodProd               IN NUMBER,
                                     pi_nNumSeq                IN NUMBER,
                                     pi_nCodPromocaoMed        IN NUMBER,
                                     pi_nCodCli                IN NUMBER,
                                     pi_nPTabela               IN NUMBER,
                                     pi_nPVenda                IN NUMBER,
                                     pi_nQt                    IN NUMBER,
                                     po_vRejeitarVenda        OUT VARCHAR2,
                                     po_vMsgVendaRejeitada    OUT VARCHAR2,
                                     po_nCotaUtilizadaGeral   OUT NUMBER,
                                     po_nCotaUtilizadaCliente OUT NUMBER);
 
 /*******************************************************************************
  Nome         : F_CONSOLIDA_COTAS_PROMOCAO
  Descricão    : Função para Consolidação das Cotas da Promoção
  ********************************************************************************/                                        
  FUNCTION F_CONSOLIDA_COTAS_PROMOCAO(pi_nOpcaoVigencia    IN NUMBER DEFAULT 0, 
                                      pi_nOpcaoAgrupamento IN NUMBER DEFAULT 0,
                                      pi_vListaPromocoes   IN VARCHAR2 DEFAULT NULL) 
  RETURN TD_CONSOLIDA_COTA_PROMOCAO PARALLEL_ENABLE PIPELINED;        									 

 /*******************************************************************************
  Nome         : P_VALIDAR_OBTER_LOTES_PEDIDO
  Descricão    : Procedimento para Validar Lote do Produto para Seleção no Pedido
  ********************************************************************************/                                       
  PROCEDURE P_VALIDAR_OBTER_LOTES_PRODUTO(pi_vTipoPedido       IN VARCHAR2,
                                          pi_nOrigemChamada    IN NUMBER,
                                          pi_nNumTransEnt      IN NUMBER,
                                          pi_nNumPed           IN NUMBER,
                                          pi_nCodProd          IN NUMBER,
                                          pi_nNumSeq           IN NUMBER,
                                          pi_vNumLote          IN VARCHAR2,
                                          pi_vCodFilial        IN VARCHAR2,
                                          pi_nCodPromocaoMed   IN NUMBER,
                                          po_nSaldoDisponivel OUT NUMBER);
                            
 /*******************************************************************************
  Nome         : P_VALIDACAO_FINAL_PROD
  Descricão    : Procedimento para Validação na Inclusão do Produto
  ********************************************************************************/                                       
  PROCEDURE P_VALIDACAO_FINAL_PROD(pi_vOrigemChamada        IN  VARCHAR2,
                                   pi_vTipoChamada          IN  VARCHAR2,
                                   pi_vGravarTabTemp        IN  VARCHAR2,
                                   pi_vOrigemPed            IN  VARCHAR2,
                                   pi_vTipoFv               IN  VARCHAR2,
                                   pi_nIntegradora          IN  NUMBER,
                                   pi_vCodFilial            IN  VARCHAR2,
                                   pi_vCodFilialNf          IN  VARCHAR2,
                                   pi_vCodFilialRetira      IN  VARCHAR2,
                                   pi_nCodCli               IN  NUMBER,
                                   pi_nNumRegiao            IN  NUMBER,
                                   pi_nCodUsur              IN  NUMBER,
                                   pi_nCodPlPag             IN  NUMBER,
                                   pi_nCodPromocaoMed       IN  NUMBER,
                                   pi_nCodProd              IN  NUMBER,
                                   pi_nQtdeVenda            IN  NUMBER,   
                                   pi_nPercDesc             IN  NUMBER,
                                   pi_nPUnitario            IN  NUMBER,
                                   pi_nNumPed               IN  NUMBER,                                     
                                   pi_nNumSeq               IN  NUMBER,
                                   pi_nPrecoMaxConsum       IN  NUMBER,
                                   po_vTipoRejeicaoProduto  OUT VARCHAR2,
                                   po_vMotivoNaoPodeComprar OUT VARCHAR2,
                                   po_nQtdeLimite           OUT VARCHAR,
                                   pi_nCodDesconto          IN  NUMBER DEFAULT NULL,
                                   pi_vNumLote              IN  VARCHAR DEFAULT NULL,
                                   pi_vNumLotePromocaoMed   IN  VARCHAR DEFAULT NULL);

 /*******************************************************************************
   Nome         : F_OBTER_DEPOSITO_WMS_DEVCLI
   Descricão    : Obter Depósito Padrão do Motivo de Devolução do Cliente
  *******************************************************************************/
  FUNCTION F_OBTER_DEPOSITO_WMS_DEVCLI(pi_nCodFilialPedido IN VARCHAR2,
                                       pi_nCodDevol        IN NUMBER) RETURN NUMBER;

 /*******************************************************************************
   Nome         : P_OBTER_DEPOSITO_WMS - DDVENDAS-33636
   Descricão    : Obter Depósito Padrão conforme tipo passado por parâmetro
  *******************************************************************************/
  PROCEDURE P_OBTER_DEPOSITO_WMS(pi_nCodFilialPedido       IN VARCHAR2,
                                 pi_vCampo                 IN VARCHAR2,
                                 po_nCodigoDepositoWms    OUT NUMBER,
                                 po_vDescricaoDepositoWms OUT VARCHAR2);
     
 /*******************************************************************************
   Nome         : P_OBTER_DADOS_DEPOSITO_WMS - DDVENDAS-33636
   Descricão    : Obter Dados Depósito WMS conforme código passado por parâmetro
  *******************************************************************************/
  PROCEDURE P_OBTER_DADOS_DEPOSITO_WMS(pi_nCodFilialPedido        IN VARCHAR2,
                                       pi_nCodDepositoWms         IN NUMBER,
                                       pio_nCodigoDepositoWms    OUT NUMBER,
                                       pio_vDescricaoDepositoWms OUT VARCHAR2);

  /*******************************************************************************
   Nome         : FCT_MED_OBTER_ESTOQUE_DISP
   Descricão    : Função para obter o Saldo de Estoque Disponivel
  ********************************************************************************/
  FUNCTION F_OBTER_ESTOQUE_DISP(pi_vCodProd                 IN NUMBER,
                                pi_vCodFilial               IN VARCHAR2,
                                pi_nOpcaoLimitarVendaEstMin IN NUMBER DEFAULT 0) RETURN NUMBER;

  /*******************************************************************************
   Nome         : FCT_MED_OBTER_ESTOQUE_DISPPEND
  ********************************************************************************/
  FUNCTION F_OBTER_ESTOQUE_DISPPEND(pi_vCodProd                 IN NUMBER,
                                    pi_vCodFilial               IN VARCHAR2,
                                    pi_nOpcaoLimitarVendaEstMin IN NUMBER DEFAULT 0) RETURN NUMBER;

  /*******************************************************************************
   Nome         : F_OBTER_ESTOQUE_AVARIA
   Descricão    : Função para obter o Saldo de Avaria Disponível
  ********************************************************************************/
  FUNCTION F_OBTER_ESTOQUE_AVARIA(pi_vCodProd   IN NUMBER,
                                  pi_vCodFilial IN VARCHAR2) RETURN NUMBER;

  /*******************************************************************************
   Nome         : F_OBTER_ESTOQUE_BLOQ
   Descricão    : Função para obter o Saldo de Estoque Bloqueado
  ********************************************************************************/
  FUNCTION F_OBTER_ESTOQUE_BLOQ(pi_vCodProd   IN NUMBER,
                                pi_vCodFilial IN VARCHAR2) RETURN NUMBER;

  /*******************************************************************************
   Nome         : F_OBTER_ESTOQUE_DISP_BLOQ
   Descricão    : Função para obter o Saldo de Estoque Disponivel Bloqueado
  ********************************************************************************/
  FUNCTION F_OBTER_ESTOQUE_DISP_BLOQ(pi_vCodProd   IN NUMBER,
                                     pi_vCodFilial IN VARCHAR2,
                                     pi_vNumLote   IN VARCHAR2 DEFAULT NULL) RETURN NUMBER;

  /*******************************************************************************
   Nome         : F_OBTER_EST_CONTAB_DISP
   Descricão    : Função para obter o Saldo de Estoque Contábil Disponivel
  ********************************************************************************/
  FUNCTION F_OBTER_EST_CONTAB_DISP(pi_nCodProd          IN NUMBER,
                                   pi_vCodFilial        IN VARCHAR2,
                                   pi_IgnorarQtPendente IN VARCHAR2 DEFAULT 'N') RETURN NUMBER;

  /*******************************************************************************
   Nome         : F_PODECOMPRARPROMOCAO
   Descricão    : Função para retornar se pode Comprar da Promoção
  ********************************************************************************/
  FUNCTION F_PODECOMPRARPROMOCAO(pi_nCodPromocaoMed   IN NUMBER,
                                 pi_vCodFilial        IN VARCHAR2,
                                 pi_nCodCli           IN NUMBER,
                                 pi_nNumRegiao        IN NUMBER,
                                 pi_nCodUsur          IN NUMBER,
                                 pi_nCodPlPag         IN NUMBER,
                                 pi_nCodCondicaoVenda IN NUMBER,
                                 pi_vOrigemPed        IN VARCHAR2,
                                 pi_vTipoFv           IN VARCHAR2,
                                 pi_dDataPedido       IN DATE DEFAULT SYSDATE) RETURN VARCHAR2;

 /*******************************************************************************
  Nome         : F_MED_PODEGERARPROMOCAO
  Descricão    : Função para retornar se pode Gerar Carga da Promoção
 ********************************************************************************/
  FUNCTION F_MED_PODEGERARPROMOCAO(pi_nCodPromocaoMed   IN NUMBER,
                                   pi_vCodFilial        IN VARCHAR2,
                                   pi_nNumRegiao        IN NUMBER,                                                     
                                   pi_vOrigemPed        IN VARCHAR2,
                                   pi_nCodCondicaoVenda IN NUMBER,
                                   pi_nCodCli           IN NUMBER) RETURN VARCHAR2;

  /*******************************************************************************
   Nome         : F_PROMOCAORESULTADOCAB
   Descricão    : Função para retornar o Resultado da Promoção - Cabeçalho
  ********************************************************************************/
  FUNCTION F_PROMOCAORESULTADOCAB(pi_nSaldoAtualContaCorrente IN NUMBER DEFAULT NULL) RETURN TABELA_MED_PROMOCAORESULTCAB
  PARALLEL_ENABLE PIPELINED;

 /*******************************************************************************
  Nome         : F_OBTEM_PRECO_ABCFARMA - DDVENDAS-35697
  Descricão    : Procedimento Obter o Preço ABCFARMA/CMED - Preço Fábrica ou PMC ou Licitação
  ********************************************************************************/                                       
  FUNCTION F_OBTEM_PRECO_ABCFARMA(pi_vTipoPreco       IN VARCHAR2,
                                  pi_nCodProd         IN NUMBER,
                                  pi_vUf              IN VARCHAR2,
                                  pi_vCodFilial       IN VARCHAR2,
                                  pi_vCodFilialNf     IN VARCHAR2,
                                  pi_nNumRegiao       IN NUMBER,
                                  pi_vTipoCliMed      IN VARCHAR2,
                                  pi_vConvenioIsencao IN VARCHAR2) RETURN NUMBER;
            
  /*******************************************************************************
   Nome         : PRC_MED_VALIDACAO_FINAL_PROD_01 - DDVENDAS-35576
   Descricão    : Procedimento para Validação Final do Produto
  ********************************************************************************/                                       
  PROCEDURE P_VALIDACAO_FINAL_PROD_01(pi_vOrigemChamada        IN  VARCHAR2,
                                      pi_vTipoChamada          IN  VARCHAR2,
                                      pi_vGravarTabTemp        IN  VARCHAR2,
                                      pi_vOrigemPed            IN  VARCHAR2,
                                      pi_vTipoFv               IN  VARCHAR2,
                                      pi_nIntegradora          IN  NUMBER,
                                      pi_vCodFilial            IN  VARCHAR2,
                                      pi_vCodFilialNf          IN  VARCHAR2,
                                      pi_vCodFilialRetira      IN  VARCHAR2,
                                      pi_nCodCli               IN  NUMBER,
                                      pi_nNumRegiao            IN  NUMBER,
                                      pi_nCodUsur              IN  NUMBER,
                                      pi_nCodPlPag             IN  NUMBER,
                                      pi_nCodPromocaoMed       IN  NUMBER,
                                      pi_nCodProd              IN  NUMBER,
                                      pi_nQtdeVenda            IN  NUMBER,   
                                      pi_nPercDesc             IN  NUMBER,
                                      pi_nPUnitario            IN  NUMBER,
                                      pi_nNumPed               IN  NUMBER,                                     
                                      pi_nNumSeq               IN  NUMBER,
                                      pi_nPrecoMaxConsum       IN  NUMBER,
                                      po_vTipoRejeicaoProduto  OUT VARCHAR2,
                                      po_vMotivoNaoPodeComprar OUT VARCHAR2,
                                      po_nQtdeLimite           OUT VARCHAR,
                                      pi_nCodDesconto          IN  NUMBER,
                                      pi_vNumLote              IN  VARCHAR,
                                      pi_vNumLotePromocaoMed   IN  VARCHAR,
                                      pi_nPTabela              IN  NUMBER,
                                      pi_nPTabelaMarkup        IN  NUMBER,
                                      pi_nCustoFin             IN  NUMBER);
                                                                            
 /*******************************************************************************
  Nome         : F_OBTER_ST_FONTE
  Descricão    : Função para retornar o ST Fonte de um Produto
  ********************************************************************************/                                       
  FUNCTION F_OBTER_ST_FONTE(pi_vCodFilial IN VARCHAR2,
                            pi_nCodProd   IN NUMBER,
                            pi_nPTabela   IN NUMBER,
                            pi_nPVenda    IN NUMBER,
                            pi_nCodCli    IN NUMBER DEFAULT NULL,
                            pi_nCondVenda IN NUMBER DEFAULT 1,
                            pi_vTipoVenda IN VARCHAR2 DEFAULT NULL,
                            pi_vSomarFecp IN VARCHAR2 DEFAULT NULL)
  RETURN NUMBER;

END PKG_FUNCOESVENDAS_MED;