CREATE OR REPLACE PACKAGE PKG_PROMOCAO_MED
/************************************************************************************************
  #VERSAO20191107A #VERSAO20191204A #VERSAO20201116A #VERSAO20201209A #VERSAO20201223B
  #VERSAO20210226A
  -----------------------------------------------------------------------------------------------
  Package de Processos Específicos de Promoção Módulo de Medicamentos
  ----------------     Historico     ------------------------------------------------------------
  Data        Responsável        Tarefa          Comentario
  11/09/2019  Anderson Silva     DDMEDICA-755    Primeira Versao
  04/11/2019  Anderson Silva     DDMEDICA-1241   Tributação Pedido Avaria
  04/11/2019  Anderson Silva     DDMEDICA-1147   Código Integração WMS
  04/12/2019  Anderson Silva     DDMEDICA-1495   Promoção por Lote
  25/12/2019  Anderson Silva     DDMEDICA-1682   Desconto CMV na Promoção
  14/01/2019  Jorge Humberto     DDMEDICA-1733 Nas promoções que tiverem utilizando o campo UTILIZADESCREDE = 'S' , considerar também a promoção para o cliente principal do cliente,
  que tiver selecionado
  24/01/2019  Anderson Silva     DDMEDICA-1953   Enviar a Promoção para a seleção de itens de crossdocking
  24/01/2019  Anderson Silva     DDMEDICA-1969   Pedido de Avaria - Troca de Nota
  31/01/2020  Anderson Silva     DDMEDICA-1969   RCA Padrão - Troca de Nota
  06/03/2020  Anderson Silva     DDMEDICA-2314   Arredondamento SUFRAMA
  04/05/2020  Anderson Silva     DDMEDICA-2609   Grupo Comercial
  03/05/2020  Anderson Silva     DDMEDICA-2810   Promoção em Edição por Fornecedor/Marca/Linha
  06/03/2020  Anderson Silva     DDMEDICA-2961   Arredondamento DESONERAÇÃO
  05/06/2020  Anderson Silva     DDMEDICA-3065   Opção para Desconsiderar Repasse na Base do Desconto Isenção ICMS
  07/10/2020  Anderson Silva     DDMEDICA-4289 - Isenção ST não participa da Regra de Arredondamento do ICMS Isenção
  16/11/2020  Anderson Silva     DDMEDICA-4799 - Log de Alteração da Promoção do Item
  03/12/2020  Anderson Silva     DDMEDICA-4915 - Cadastrar Verba na Promoção
  08/12/2020  Anderson Silva     DDMEDICA-5009 - Ler Verba Rebaixa CMV da Promoção
  22/12/2020  Anderson Silva     DDMEDICA-5105 - Inclusão do campo de Valor Unit. de Verba ao verificar se alterou o produto na promoção
  23/12/2020  Anderson Silva     DDMEDICA-5126 - Correção Validação Filial Retira ao Recuperar Orçamento
  23/12/2020  Anderson Silva     DDMEDICA-5105 - Inclusão do campo de Valor Unit. de Verba no grupo de produtos
  26/02/2020  Anderson Silva     DDMEDICA-5751 - Validação Mínimo para quem não usa Normalização
  10/06/2021  Anderson Silva     DDMEDICA-6772   Movida para a Package Medicamentos o procedimento para definir o Código Fiscal
  11/06/2021  Lucas Rangel       DDMEDICA-6796   percmarkupmed valida atraves do  vvTipoPromocao = 'R' ao inves do vvTipoPolitica = 'M' que foi descontinuado
  15/06/2021  Anderson Silva     DDMEDICA-6841 - Gravação Promoção Markup por Faixa de Quantidade
  15/06/2021  Anderson Silva     DDMEDICA-6841 - Cálculo Promoção Markup por Faixa de Quantidade e Preço Fixo no Televendas
  24/06/2021  Anderson Silva     DDMEDICA-6874 - Recálculo Campos Desoneração
  30/06/2021  Anderson Silva     DDMEDICA-6900   Movida para dentro da package a procedure que carrega a lista de promoções principais do pedido na 2316 - P_OBTEM_CUSTO_PROMO_MARKUP
  12/08/2021  Anderson Silva     DDMEDICA-7318 - Ler EAN do Item do Orçamento / Filial Retira nos Brindes
  24/08/2021  Jorge Humberto     DDMEDICA-7403 - Ajuste na PKG_PROMOCAO_MED, na consulta de filial retira
  17/09/2021  Anderson Silva     DDMEDICA-7609 - Correção da Soma de ST do PBASERCA
  15/09/2021  Anderson Silva     DDMEDICA-7594   Customização da Base ST com SUFRAMA/Redução PISCOFINS e DESONERACAO
  30/09/2021  Anderson Silva     DDMEDICA-7697   ST Recolhido Anteriormente
  21/10/2021  Anderson Silva     DDVENDAS-31316  ST Antecipado não somar ao CMV
  13/12/2021  Anderson Silva     DDVENDAS-32472  PTabela de Orçamento com Contrato
  07/01/2022  Anderson Silva     DDVENDAS-32865  Edição de Promoção
  26/01/2021  Anderson Silva     DDVENDAS-33184  Ajustes na Edição da Promoção com Qt.Obrigatório
  08/02/2022  Anderson Silva     DDVENDAS-33442  Conversão Quantidade Empenho
  28/02/2022  Anderson Silva     DDVENDAS-33950  Não permitir ST Nulo
  25/02/2022  Anderson Silva     DDVENDAS-33920  Tributação por Endereço de Entrega
  19/04/2022  Anderson Silva     DDVENDAS-35050 - Ajuste para melhorar as dependências da 2300 centralização alguns procedimentos na PKG_MEDICAMENTOS
  24/04/2022  Anderson Silva     DDVENDAS-35125  Melhoria Referências Externas
  25/05/2022  Anderson Silva     DDVENDAS-35662  Não referenciar campo especifico do módulo 42
  23/05/2022  Anderson Silva     DDVENDAS-35576 - Flexibilização da Regra de Alterar Preço/Desconto 
  07/06/2022  Anderson Silva     DDVENDAS-35939 - Grupo de Comissão no Combo
  22/07/2022  Anderson Silva     DDVENDAS-36806 - Conta Corrente RCA com Promoção de Markup ao recuperar Orçamento
  04/10/2022  Anderson Silva     DDVENDAS-38140 - Cadastro da Cota na Promoção
  06/10/2022  Anderson Silva     DDVENDAS-38166 - Validação de Cotas da Promoção
  26/10/2022  Anderson Silva     DDVENDAS-38534 - Ajuste gravação restrições clientes sem normalização da promoção
  16/11/2022  Anderson Silva     DDVENDAS-38892 - Melhoria de performance na gravação da promoção
 ************************************************************************************************/
IS PRAGMA SERIALLY_REUSABLE;

  FUNCTION F_OBTER_VERSIONAMENTO RETURN VARCHAR2;

 /************************************************************
  Procedimento para Obter o Verba da Promoção - DDMEDICA-5009
  ***********************************************************/
  PROCEDURE P_OBTER_VERBA_PROMOCAO(pi_nCodPromocaoMed        IN NUMBER,
                                   pi_nCodFornec             IN NUMBER,
                                   pio_nVlDescCmvPromocaoMed IN OUT NUMBER,
                                   po_nNumVerba              OUT NUMBER,
                                   po_nValorCotaNumVerba     OUT NUMBER,
                                   po_vSemVerbaVlDescCmv     OUT VARCHAR2);

 /*******************************************************************************
  Nome         : P_VALIDA_PROMOCAO
  Descricão    : Procedimento para validar a Promoção
  ********************************************************************************/
  PROCEDURE P_VALIDA_PROMOCAO(pi_nTipoChamada          IN  NUMBER,
                              pi_nNumPed               IN  NUMBER,
                              pi_nCodCli               IN  NUMBER,
                              pi_nCodUsur              IN  NUMBER,
                              pi_vCodFilial            IN  VARCHAR2,
                              pi_nNumRegiao            IN  NUMBER,
                              pi_nCondVenda            IN  NUMBER,
                              pi_nCodPlPag             IN  NUMBER,
                              pi_nCodPromocaoMedPedido IN  NUMBER,
                              pi_vPosicao              IN  VARCHAR2,
                              pi_nOpcaoTipoEntrega     IN  NUMBER,
                              pi_nRotinaLanc           IN  NUMBER,
                              pi_nQtCombos             IN  NUMBER,
                              po_vPodeGravarPedido     OUT VARCHAR2,
                              po_vMotivoNaoPodeGravar  OUT VARCHAR2,
                              pi_vCodFilialNF          IN VARCHAR2 DEFAULT NULL,
                              pi_vCodCob               IN VARCHAR2 DEFAULT NULL,
                              pi_nCodEdital            IN NUMBER   DEFAULT NULL,
                              pi_vNumEmpenho           IN VARCHAR2 DEFAULT NULL,
                              pi_nCodMatricula         IN NUMBER   DEFAULT NULL,
                              pi_vVisualizarPromoBloq  IN VARCHAR2 DEFAULT NULL,
                              pi_nCodProd              IN NUMBER   DEFAULT NULL,
                              pi_nCodPlPagEtico        IN NUMBER   DEFAULT NULL,
                              pi_nCodPlPagGenerico     IN NUMBER   DEFAULT NULL,
                              pi_nNumOrcamento         IN NUMBER   DEFAULT NULL,
                              pi_nCodLinhaPrazo        IN NUMBER   DEFAULT NULL,
                              pi_nCodCondicaoVenda     IN NUMBER   DEFAULT NULL,
                              pi_vOrigemPed            IN VARCHAR2 DEFAULT NULL,
                              pi_vTipoFv               IN VARCHAR2 DEFAULT NULL,
                              pi_nCodUsurContaCorrente IN NUMBER   DEFAULT NULL,
                              pi_vCodFilialRetira      IN VARCHAR2 DEFAULT NULL,
                              pi_nNumTransEntCrossDock IN NUMBER   DEFAULT NULL,
                              pi_vInProdutosCrossDock  IN VARCHAR2 DEFAULT NULL,
                              pi_nCodEndEntCli         IN NUMBER   DEFAULT NULL -- DDVENDAS-33920
                              );

 /*******************************************************************************
  Nome         : P_ATUALIZAR_PROMOCAO
  Descricão    : Procedimento para atualizar a Promoção
  ********************************************************************************/
  PROCEDURE P_ATUALIZAR_PROMOCAO(pi_vTipoChamada          IN  VARCHAR2,
                                 pi_nCodPromocao          IN  NUMBER,
                                 pi_nCodFunc              IN  NUMBER,
                                 pi_vListaPromocoes       IN  VARCHAR2,
                                 po_nCodPromocaoGerado    OUT NUMBER,
                                 po_vOcorreramErros       OUT VARCHAR2,
                                 po_vMsgErros             OUT VARCHAR2);

 /*******************************************************************************
  Nome         : P_OBTEM_DESC_TELEVENDAS
  Descricão    : Procedimento para obter o Desconto do Televendas (Rotina 2316)
  ********************************************************************************/
  PROCEDURE P_OBTEM_DESC_TELEVENDAS(pi_nTipoChamada         IN  NUMBER,
                                    pi_nCodPromocaoMed      IN  NUMBER,
                                    pi_nCodProd             IN  NUMBER,
                                    pi_nCodCondicaoVenda    IN  NUMBER,
                                    pi_nCodCli              IN  NUMBER,
                                    pi_nQtde                IN  NUMBER,
                                    pi_dData                IN  DATE,
                                    pi_vCodFilial           IN  VARCHAR2,
                                    pi_nCodPraca            IN  NUMBER,
                                    pi_nNumRegiao           IN  NUMBER,
                                    pi_nCodUsur             IN  NUMBER,
                                    pi_vOrigemPed           IN  VARCHAR2,
                                    pi_vTipoFv              IN  VARCHAR2,
                                    pi_nCodPlPag            IN  NUMBER,
                                    pi_vClasseVenda         IN  VARCHAR2,
                                    pi_vUsaPrioritaria      IN  VARCHAR2,
                                    pi_nCodPromocaoItem     IN  NUMBER,
                                    pi_vVisualizarPromoBloq IN  VARCHAR2,
                                    pi_vVisualizarPromoEsp  IN  VARCHAR2,
                                    pi_npTabela             IN  NUMBER,
                                    pi_nCustoFin            IN  NUMBER,
                                    po_nPerDesc             OUT NUMBER,
                                    po_nPerBonific          OUT NUMBER,
                                    po_nPerComerc           OUT NUMBER,
                                    po_nPerBoleto           OUT NUMBER,
                                    po_nPercDescFin         OUT NUMBER,
                                    po_nCodLinhaPrazo       OUT NUMBER,
                                    po_vOcorreramErros      OUT VARCHAR2,
                                    po_vMsgErros            OUT VARCHAR2);

 /*******************************************************************************
  Nome         : P_OBTEM_DESC_TELEVENDAS_01
  Descricão    : Procedimento para obter o Desconto do Televendas (Rotina 2316)
                 a partir da Verba para Rebaixa de CMV da Promoção - DDMEDICA-5009
  ********************************************************************************/
  PROCEDURE P_OBTEM_DESC_TELEVENDAS_01(pi_nTipoChamada         IN  NUMBER,
                                       pi_nCodPromocaoMed      IN  NUMBER,
                                       pi_nCodProd             IN  NUMBER,
                                       pi_nCodCondicaoVenda    IN  NUMBER,
                                       pi_nCodCli              IN  NUMBER,
                                       pi_nQtde                IN  NUMBER,
                                       pi_dData                IN  DATE,
                                       pi_vCodFilial           IN  VARCHAR2,
                                       pi_nCodPraca            IN  NUMBER,
                                       pi_nNumRegiao           IN  NUMBER,
                                       pi_nCodUsur             IN  NUMBER,
                                       pi_vOrigemPed           IN  VARCHAR2,
                                       pi_vTipoFv              IN  VARCHAR2,
                                       pi_nCodPlPag            IN  NUMBER,
                                       pi_vClasseVenda         IN  VARCHAR2,
                                       pi_vUsaPrioritaria      IN  VARCHAR2,
                                       pi_nCodPromocaoItem     IN  NUMBER,
                                       pi_vVisualizarPromoBloq IN  VARCHAR2,
                                       pi_vVisualizarPromoEsp  IN  VARCHAR2,
                                       pi_npTabela             IN  NUMBER,
                                       pi_nCustoFin            IN  NUMBER,
                                       po_nPerDesc             OUT NUMBER,
                                       po_nPerBonific          OUT NUMBER,
                                       po_nPerComerc           OUT NUMBER,
                                       po_nPerBoleto           OUT NUMBER,
                                       po_nPercDescFin         OUT NUMBER,
                                       po_nCodLinhaPrazo       OUT NUMBER,
                                       po_vOcorreramErros      OUT VARCHAR2,
                                       po_vMsgErros            OUT VARCHAR2,
                                       pi_nCodEndEntCli        IN  NUMBER   DEFAULT NULL, -- DDVENDAS-33920
                                       pi_nEstEnt              IN  VARCHAR2 DEFAULT NULL, -- DDVENDAS-33920 
                                       pi_nPrecoFabrica        IN  NUMBER   DEFAULT NULL  -- DDVENDAS-33920 
                                       );

 /*******************************************************************************
  Nome         : P_APLIC_REGRA_ALTDSCPRC_PROMO
  Descricão    : Procedimento para aplicar nos itens da promoção a regra
                 para obedecer a opção de alteração de desconto e preço da promoção
  *******************************************************************************/
  PROCEDURE P_APLIC_REGRA_ALTDSCPRC_PROMO;
                                       
END PKG_PROMOCAO_MED;