CREATE OR REPLACE PACKAGE PKG_GRAVACAO_PEDIDO_MED
/************************************************************************************************
  #VERSAO20191216A #VERSAO20191223A #VERSAO20191230A #VERSAO20200103A #VERSAO20200423A #VERSAO20200601A
  #VERSAO20200818A #VERSAO20200903A #VERSAO20200910A #VERSAO20201111A #VERSAO20201113A #VERSAO20201123A
  #VERSAO20201130A #VERSAO20201207A #VERSAO20210128A #VERSAO20210202A #VERSAO20210222A #VERSAO20210223A
  #VERSAO20210319A #VERSAO20210401A #VERSAO20210419A #VERSAO20210503A
  -----------------------------------------------------------------------------------------------
  Package de Processos de Gravação do Pedido do Módulo de Medicamentos
  ----------------     Historico     ------------------------------------------------------------
  Data        Responsável        Tarefa          Comentario
  14/12/2019  Anderson Silva     DDMEDICA-1586   Primeira Versão
  23/12/2019  Anderson Silva     DDMEDICA-1658   Procedimento para retornar a transportadora da frequência de entrega
  29/12/209   Anderson Silva     DDMEDICA-1589   Troca Cliente Pedido - Validação Produtos
  03/01/2019  Anderson Silva     DDMEDICA-1592   Troca Cliente Pedido - Comissão
  15/04/2020  Anderson Silva     DDMEDICA-1706   Motivos de Bloqueio
  30/04/2019  Anderson Silva     DDMEDICA-2798   Se o Rateio de C/C é no Saldo do Pedido, não pode ratear nos Itens
  28/05/2020  Anderson Silva     DDMEDICA-3017   Parâmetro para não validar prazo médio do pedido no OL e PE
  09/06/2020  Anderson Silva     DDMEDICA-3103 - Validar o CODBNF da Promoção do Item ao criticar Saldo C/C do Pedido
  29/07/2020  Anderson Silva     DDMEDICA-3464 - Restrição por Valor Mínimo 391
  30/07/2020  Anderson Silva     DDMEDICA-3502 - Validação parâmetro 1456 não ser aplicado em Balcão/Balcão Reserva
  18/08/2020  Anderson Silva     DDMEDICA-3658 - Edição do Pedido na 2336 considerar todos os itens na mudança da posição #VERSAO20200818A
  18/08/2020  Anderson Silva     DDMEDICA-3662 - Correção Validação Margem
  19/08/2020  Anderson Silva     DDMEDICA-3689 - Correção Valor Minimo BK com Grupo de Faturamento
  21/08/2020  Anderson Silva     DDMEDICA-3712 - Margem Mínima da 132 com Grupo de Faturamento
  21/08/2020  Anderson Silva     DDMEDICA-3717 - Código Emitente no Pedido de Itens Faltantes
  25/08/2020  Anderson Silva     DDMEDICA-3743 - Utilização do Parâmetro 1304
  03/09/2020  Anderson Silva     DDMEDICA-3918 - Bloqueios Comerciais
  10/09/2020  Anderson Silva     DDMEDICA-3949 - Revalidação da Promoção
  16/10/2020  Anderson Silva     DDMEDICA-4032 - Se Cortar todos os produtos do Plano de Pagamento, não entra na Crítica de Valor Mínimo do Plano de Pagamento
  18/09/2020  Anderson Silva     DDMEDICA-4072 - Utilização do Parâmetro VALIDARMARGEMMINIMA no OL e PE
  28/10/2020  Anderson Silva     DDMEDICA-4566 - Correção Mudança de Posição ao Cancelar um Item na 2336
  11/11/2020  Anderson Silva     DDMEDICA-4732 - Limite Crédito Cliente Principal
  13/11/2020  Anderson Silva     DDMEDICA-4772 - Correcao Validaçao Margem Minima Balcão/Balcão Reserva / Correção Liberação Pedido com Prazo Médio Superior nos OLs                                          
  23/11/2020  Anderson Silva     DDMEDICA-4851 - Substituir opção Abortar nos Bloqueios ao chamar da 2336 se usar acesso da 2345, para que os comerciais possam ser liberados
  30/11/2020  Anderson Silva     DDMEDICA-4900 - Limitar Mensagem do Limite de Crédito
  07/12/2020  Anderson Silva     DDMEDICA-5000 - Atualizar VLTOTAL ao Editar Pedido na 2336
  10/02/2020  Anderson Silva     DDMEDICA-5031 - Não Validar Bloqueio Margem Minima em TV10
  10/12/2020  Anderson Silva     DDMEDICA-5009 - Validar Cota Verba Promoção
  22/12/2020  Anderson Silva     DDMEDICA-5105 - Alteração da Mensagem de Validação de Verba utilizada no Pedido
  24/12/2020  Anderson Silva     DDMEDICA-5131 - Estorno da Devolução de Clientes na Cota de Verba da Promoção
  27/01/2020  Anderson Silva     DDMEDICA-5401 - Validar a Data de Apuração da Verba
  02/02/2020  Anderson Silva     DDMEDICA-5501 - Incorporar o Limite Autorizado de Crédito no Pedido
  22/02/2020  Anderson Silva     DDMEDICA-5675 - Correção Validação Prazo Médio com Prazo Variável no Cliente
  23/02/2020  Anderson Silva     DDMEDICA-5689 - Permissão 73 para Liberar Pedidos abaixo do valor mínimo do RCA 
  02/03/2020  Anderson Silva     DDMEDICA-5782 - Merge Validação Prazo Médio Servcon
  19/03/2021  Anderson Silva     DDMEDICA-6036 - Limite Sazonal da Rotina 3321 e garantir Código da Distribuição do Pedido conforme Produto
  01/04/2021  Anderson Silva     DDMEDICA-6213 - Alvará do SUS e CRF não pode ser impeditivo de iniciar o pedido
  19/04/2021  Anderson Silva     DDMEDICA-6363 - Parâmetro para rejeitar o Pedido caso o RCA não tenha saldo de conta corrente
  03/05/2021  Anderson Silva     DDMEDICA-6491 - Parâmetro para não validar Alvará do SUS

  06/04/2021  Anderson Silva     DDMEDICA-6545 - Parâmetro para não validar Alvará do CRF
  06/04/2021  Anderson Silva     DDMEDICA-6545 - Parâmetro para permitir receber pedido com Alvará vencido na Integradora

  06/05/2021  Anderson Silva     DDMEDICA-6533 - Faturamento Integral no Layout Customizado
  10/05/2021  Anderson Silva     DDMEDICA-6573 - Não validar parâmetro de valor minimo de venda da 132 em transferencias
  12/05/2021  Anderson Silva     DDMEDICA-6582 - Adequação nova validação da posição do pedido na package estoque
  13/05/2021  Anderson Silva     DDMEDICA-6578 - Atualização do DTWMS
  18/05/2021  Anderson Silva     DDMEDICA-6631 - Correção da Autorização de Crédito - PCAUTORC.VLLIBERADO
  08/06/2021  Anderson Silva     DDMEDICA-6772 - Correção Liberação de Pedido com Bloqueios Excluídos
  25/06/2021  Anderson Silva     DDMEDICA-6874 - Troca de cliente no pedido de venda de pessoa jurídica para física
  02/08/2021  Anderson Silva     DDMEDICA-7182 - Permitir realizar a Quebra por Plano de Pagamento também quando chamado da Rotina 2336
  22/08/2021  Anderson Silva     DDMEDICA-7391 - Limitar Venda do Estoque Mínimo
  22/08/2021  Anderson Silva     DDMEDICA-7251 - Pedido Canal Autorizador CA PBM
  14/09/2021  Anderson Silva     DDMEDICA-7580 - Correção passagem parâmetro da função que valida a restrição de venda por filial
  30/09/2021  Anderson Silva     DDMEDICA-7697   ST Recolhido Anteriormente
  06/10/2021  Anderson Silva     DDMEDICA-7731 - Limitar gravação do campo LOG da PCPEDC
  26/10/2021  Anderson Silva     DDVENDAS-31376 - Validação para não movimentar estoque se integrado com WMS
  12/11/2021  Anderson Silva     DDVENDAS-31792 - Adequação Multi-Seleção da 307
  21/03/2022  Anderson Silva     DDVENDAS-34441 - Exceção na Venda do Estoque Mínimo para a Integradora
  24/04/2022  Anderson Silva     DDVENDAS-35125   Melhoria Referências Externas
  09/06/2022  Anderson Silva     DDVENDAS-35974 - Ajuste Motivos por Item na Liberação do Pedido com Balcão Reserva
  10/10/2022  Anderson Silva     DDVENDAS-38264 - Novas restrições por valor 
  01/11/2022  Anderson Silva     DDVENDAS-38483 - Quebra de Pedidos do Força de Vendas
  08/11/2022  Anderson Silva     DDVENDAS-38786 - Alteração da forma de incluir um novo pedido por quebra
  14/12/2022  Anderson Silva     DDVENDAS-39352 - Ajuste descrição produto críticas promoções
 ************************************************************************************************/
IS PRAGMA SERIALLY_REUSABLE;

 /*******************************************************************************
  Nome         : F_FORMATAR_NUMERO_PARA_TEXTO
  Descricão    : Função para Formatar um Número para Texto
  ********************************************************************************/   
  FUNCTION F_FORMATAR_NUMERO_PARA_TEXTO(pi_nNumero            IN NUMBER,
                                        pi_iQtdeCasasDecimais IN INTEGER) RETURN VARCHAR2;

 /***********************************************************************************************
  PROCEDIMENTO: P_OBTER_REGIAO_CLIENTE
  DESCRIÇÃO   : Obter a Região do Cliente
  ***********************************************************************************************/
  PROCEDURE P_OBTER_REGIAO_CLIENTE(pi_nCodCli     IN NUMBER,
                                   pi_vCodFilial  IN VARCHAR2,
                                   po_nNumRegiao OUT NUMBER);
         
 /*******************************************************************************
  Nome         : P_VALIDAR_TROCA_CLIPROD
  Descricão    : Procedimento para Validar Troca do Cliente, referente aos produtos
  ********************************************************************************/   
  PROCEDURE P_VALIDAR_TROCA_CLIPROD(pi_vOrigemChamada        IN VARCHAR2,
                                    pi_nMatricula            IN NUMBER,
                                    pi_nNumPed               IN NUMBER,
                                    pi_nCodCli               IN NUMBER,
                                    pi_nCodPlPag             IN NUMBER,
                                    pi_nCodPlPagEtico        IN NUMBER,
                                    pi_nCodPlPagGenerico     IN NUMBER,
                                    pi_vCodCob               IN VARCHAR2,
                                    pi_nCodPromocaoMed       IN NUMBER,
                                    pi_nNumRegiao            IN NUMBER,
                                    pi_vCodFilial            IN VARCHAR2,
                                    pi_vCodFilialNf          IN VARCHAR2,
                                    po_vOcorreramAlertas    OUT VARCHAR2,
                                    po_vOcorreramRejeicoes  OUT VARCHAR2,
                                    po_vPodeGravarPedido    OUT VARCHAR2,
                                    po_vMotivoNaoPodeGravar OUT VARCHAR2,
                                    po_vProblemasTriPrecif  OUT VARCHAR2);
                                                                           
 /*******************************************************************************
  Nome         : P_VALIDAR_TROCA_CLIENTE
  Descricão    : Procedimento para Validar Troca do Cliente
  ********************************************************************************/   
  PROCEDURE P_VALIDAR_TROCA_CLIENTE(pi_vOrigemChamada       IN VARCHAR2,
                                    pi_nMatricula           IN NUMBER,
                                    pi_nNumPed              IN NUMBER,
                                    pi_nCodCli              IN NUMBER,
                                    pi_nCodPlPag            IN NUMBER,
                                    pi_nCodPlPagEtico       IN NUMBER,
                                    pi_nCodPlPagGenerico    IN NUMBER,
                                    pi_vCodCob              IN VARCHAR2,
                                    pi_nCodPromocaoMed      IN NUMBER,
                                    pi_nNumRegiao           IN NUMBER,
                                    pi_vCodFilial           IN VARCHAR2,
                                    pi_vCodFilialNf         IN VARCHAR2,
                                    po_vOcorreramAlertas   OUT VARCHAR2,
                                    po_vOcorreramRejeicoes OUT VARCHAR2);
                                            
/*******************************************************************************
  Nome         : P_TROCAR_CLIENTE
  Descricão    : Procedimento para Trocar o Cliente do Pedido
  ********************************************************************************/   
  PROCEDURE P_TROCAR_CLIENTE(pi_nMatricula        IN NUMBER,
                             pi_nNumPed           IN NUMBER,
                             pi_nCodCli           IN NUMBER,
                             pi_nCodPlPag         IN NUMBER,
                             pi_nCodPlPagEtico    IN NUMBER,
                             pi_nCodPlPagGenerico IN NUMBER,
                             pi_vCodCob           IN VARCHAR2,
                             pi_nCodPraca         IN NUMBER,
                             pi_nNumRegiao        IN NUMBER,
                             pi_nCodPromocaoMed   IN NUMBER,
                             po_vTrocouCliente   OUT VARCHAR2,
                             po_vMotivoNaoTrocou OUT VARCHAR2);
                             
 /***********************************************************************************************
  PROCEDURE: P_OBTER_TRANSPORTADORA_FREQENT
  DESCRIÇÃO: DDMEDICA-1658 - Obter Transportadora da Frequência de Entrega
  ***********************************************************************************************/   
  PROCEDURE P_OBTER_TRANSPORTADORA_FREQENT(pi_nCodPraca           IN  NUMBER,
                                           pi_vCodFilial          IN VARCHAR2,
                                           po_nCodTransportadora OUT NUMBER,
                                           po_nCodFreqEntrega    OUT NUMBER);                             
                                  
 /***********************************************************************************************
  PROCEDURE: P_VALIDA_CONTROLE_VENDA
  DESCRIÇÃO: : Procedimento para validar o Controle de Venda do Produto para os Clientes
  ***********************************************************************************************/   
  PROCEDURE P_VALIDA_CONTROLE_VENDA(pi_vTipoChamada          IN  VARCHAR2,
                                    pi_nCodCli               IN  NUMBER,
                                    pi_vTipoFJ               IN  VARCHAR2,
                                    pi_nCodProd              IN  NUMBER,
                                    pi_nQtdeVenda            IN  NUMBER,   
                                    pi_nNumPed               IN  NUMBER,                                     
                                    pi_nNumSeq               IN  NUMBER,
                                    po_vPodeComprarProduto   OUT VARCHAR2,
                                    po_vMotivoNaoPodeComprar OUT VARCHAR2,
                                    po_nQtdeLimite           OUT VARCHAR,
                                    pi_nCodRotina            IN  NUMBER DEFAULT NULL);
                        
 /***********************************************************************************************
  PROCEDIMENTO: P_INSERIR_MOTIVO_BLOQ
  DESCRIÇÃO   : Inserir o Motivo de Bloqueio
  ***********************************************************************************************/
  PROCEDURE P_INSERIR_MOTIVO_BLOQ(pi_nNumPed             IN NUMBER,
                                  pi_nCodMotivo          IN NUMBER,
                                  pi_vMotivo             VARCHAR2,
                                  pi_nCodMotBloqueio     IN NUMBER,
                                  pi_nCodPlPag           IN NUMBER,
                                  pi_nCodRejeicao        IN NUMBER,
                                  pi_vDescricaoRejeicao  IN VARCHAR2,
                                  pi_vObservacaoRejeicao IN VARCHAR2);
                
 /*********************************************************************
  PROCEDIMENTO: P_OPCAO_LIMITAR_VENDA_EST_MIN
  DESCRIÇÃO   : Retornar se Limita a Venda do Estoque Mínimo - DDMEDICA-7391
  *********************************************************************/
  PROCEDURE P_OPCAO_LIMITAR_VENDA_EST_MIN(pi_nCodCli                  IN NUMBER,
                                          pi_nCondVenda               IN NUMBER,
                                          po_nOpcaoLimitarVendaEstMin OUT NUMBER,
                                          po_vObservacao              OUT VARCHAR2,
                                          pi_nIntegradora             IN NUMBER DEFAULT NULL);
                
 /*******************************************************************************
  Nome         : P_ESTOQUE_RESERV_ITEM_01
  Descricão    : Atualização do Estoque Reservado
  *******************************************************************************/
  PROCEDURE P_ESTOQUE_RESERV_ITEM_01(pi_nOrigemChamada  IN  NUMBER,
                                     pi_vOperacao       IN  VARCHAR2,
                                     pi_vCodFilial      IN  VARCHAR2,
                                     pi_nNumPed         IN  NUMBER,
                                     pi_nCodProd        IN  NUMBER,
                                     pi_nNumSeq         IN  NUMBER,
                                     pi_nQtde           IN  NUMBER,
                                     pi_vPedidoExiste   IN  VARCHAR2,
                                     po_vOcorreramErros OUT VARCHAR2,
                                     po_vMsgErros       OUT VARCHAR2);
                                                                                                                                                                                                                       
 /*******************************************************************************
  Nome         : P_GRAVACAO_PEDIDO_01
  Descricão    : Procedimento de Gravação do Pedido, que realiza a Reserva do
                 Estoque, Atualização da Posição e Atualização do Conta-Corrente do RCA
  *******************************************************************************/
  PROCEDURE P_GRAVACAO_PEDIDO_01(pi_nCodRotina              IN  NUMBER,
                                 pi_nNumPed                 IN  NUMBER,
                                 pi_nCodUsurContaCorrente   IN  NUMBER,
                                 pi_nMatricula              IN  NUMBER,
                                 pi_vGuardaFalta            IN  VARCHAR2,
                                 pi_vGravarPedidoItensFalta IN  VARCHAR2,
                                 pi_nNumPedidoItensFalta    IN  NUMBER,
                                 pi_vMovimentarSaldoRca     IN  VARCHAR2,
                                 pi_vChamadaProcesso        IN  VARCHAR2,
                                 pi_vNovaPosicaoPedido      IN  VARCHAR2,
                                 pi_vBrindes                IN  VARCHAR2,
                                 pi_nCodProdEdicao          IN  NUMBER,
                                 po_vRetorno                OUT VARCHAR2,
                                 po_vMsgErros               OUT VARCHAR2,
                                 po_vPosicaoFinalPedido     OUT VARCHAR2,
                                 po_nCodMotivo              OUT NUMBER,
                                 po_vMotivoPosicao          OUT VARCHAR2,
                                 po_vObservacaoMotivo       OUT VARCHAR2,
                                 po_vExistemFaltas          OUT VARCHAR2,
                                 pi_vCodFilial              IN  VARCHAR2 DEFAULT NULL,
                                 pi_nCodCli                 IN  NUMBER   DEFAULT NULL,
                                 pi_nCondVenda              IN  NUMBER   DEFAULT NULL,
                                 pi_nCodPlPag               IN  NUMBER   DEFAULT NULL,
                                 pi_nCodPlPagEtico          IN  NUMBER   DEFAULT NULL,
                                 pi_nCodPlPagGenerico       IN  NUMBER   DEFAULT NULL,
                                 pi_vCodCob                 IN  VARCHAR2 DEFAULT NULL,
                                 pi_dDtEntrega              IN  DATE     DEFAULT NULL,
                                 pi_vOrigemPed              IN  VARCHAR2 DEFAULT NULL,
                                 pi_vTipoFv                 IN  VARCHAR2 DEFAULT NULL,
                                 pi_nIntegradora            IN  NUMBER   DEFAULT NULL,
                                 pi_nCodCondicaoVenda       IN  NUMBER   DEFAULT NULL,
                                 pi_nCodUsur                IN  NUMBER   DEFAULT NULL,
                                 pi_vVendaAssistida         IN  VARCHAR2 DEFAULT NULL,
                                 pi_nVlDescNeg              IN  NUMBER   DEFAULT NULL,
                                 pi_vPedidoAvaria           IN  VARCHAR2 DEFAULT NULL,
                                 pi_nNumTransEntCrossDock   IN  NUMBER   DEFAULT NULL,
                                 pi_vGeraCP                   IN VARCHAR2 DEFAULT NULL,
                                 pi_nNumTransEntOrigConsig    IN NUMBER   DEFAULT NULL,
                                 pi_nNumTransEntOrigTrocaNota IN NUMBER  DEFAULT NULL,
                                 pi_nCodMotivo                IN NUMBER   DEFAULT NULL,
                                 pi_nCodMotivoBloqueio        IN NUMBER   DEFAULT NULL,
                                 pi_vMotivoPosicao            IN VARCHAR2 DEFAULT NULL,
                                 pi_nIntegrada                IN NUMBER   DEFAULT NULL,
                                 pi_nCodPromocaoMedPedido     IN NUMBER   DEFAULT NULL,
                                 pi_vFaturamentoIntegral      IN VARCHAR2 DEFAULT NULL,
                                 pi_nQtdeFaturamentoIntegral  IN NUMBER   DEFAULT NULL,
                                 pi_nNumRegiao                IN NUMBER   DEFAULT NULL);

 /*******************************************************************************
  Nome         : P_FINALIZACAO_PEDIDO_01
  Descricão    : Processo de Finalização do Pedido
  *******************************************************************************/
  PROCEDURE P_FINALIZACAO_PEDIDO_01(pi_nCodRotina      IN  NUMBER,
                                    pi_nNumPed         IN  NUMBER,
                                    pi_nMatricula      IN  NUMBER,
                                    pi_vPosicaoPedido  IN  VARCHAR2,
                                    pi_nProxNumCar     IN  NUMBER,
                                    po_vOcorreramErros OUT VARCHAR2,
                                    po_vMsgErros       OUT VARCHAR2);

 /***********************************************************************************************
  PROCEDIMENTO: P_INSERIR_MOTIVO_BLOQ_MANUAL
  DESCRIÇÃO   : Inserir o Motivo de Bloqueio Manual na 2336 - DDMEDICA-3918
  ***********************************************************************************************/
  PROCEDURE P_INSERIR_MOTIVO_BLOQ_MANUAL(pi_nNumPed    IN NUMBER,
                                         pi_nCodMotivo IN NUMBER,
                                         pi_nMatricula IN NUMBER);

 /*********************************************************************
  FUNÇÃO   : F_MED_MIX_PROMOCAO
  DESCRIÇÃO: Retorna se o Produto faz parte do Mix da Promoção
  *********************************************************************/
  FUNCTION F_MED_MIX_PROMOCAO(pi_nCodPromocaoMed IN NUMBER,
                              pi_nCodProd        IN NUMBER,
                              pi_nCodCli         IN NUMBER,
                              pi_nCodUsur        IN NUMBER)
  RETURN VARCHAR2;

 /*******************************************************************************
  Nome         : P_REVALIDA_PROMOCAO
  Descricão    : Procedimento para Revalidar a Promoção ao gravar o Pedido  
  ********************************************************************************/   
  PROCEDURE P_REVALIDA_PROMOCAO(pi_vOrigemChamada       IN VARCHAR2,
                                pi_nMatricula           IN NUMBER,
                                pi_nNumPed              IN NUMBER,
                                pi_nCodCli              IN NUMBER,
                                pi_nCodUsur             IN NUMBER,
                                pi_nCodPlPag            IN NUMBER,
                                pi_nCodPlPagEtico       IN NUMBER,
                                pi_nCodPlPagGenerico    IN NUMBER,
                                pi_vCodCob              IN VARCHAR2,
                                pi_nCodPromocaoMed      IN NUMBER,
                                pi_nNumRegiao           IN NUMBER,
                                pi_vCodFilial           IN VARCHAR2,
                                pi_vCodFilialNf         IN VARCHAR2,
                                pi_vOrigemPed           IN VARCHAR2,
                                pi_vTipoFv              IN VARCHAR2,
                                pi_nCodCondicaoVenda    IN NUMBER,
                                po_vOcorreramAlertas    OUT VARCHAR2,
                                po_vOcorreramRejeicoes  OUT VARCHAR2);

 /***********************************************************************************************
  PROCEDURE: F_EXISTE_INTEGRADORA_CA_PBM
  DESCRIÇÃO: CA PBM - Verifica se existe alguma Integradora com Canal Autorizador PBM
  ***********************************************************************************************/   
  FUNCTION F_EXISTE_INTEGRADORA_CA_PBM RETURN VARCHAR2;

 /***********************************************************************************************
  PROCEDURE: F_PRODUTO_INTEGRADORA_CA_PBM
  DESCRIÇÃO: CA PBM - Verifica se o Produto Participa do Canal Autorizador PBM, retornando a Integradora
  ***********************************************************************************************/   
  FUNCTION F_INTEGRADORA_PRODUTO_CA_PBM(pi_nCodProd IN NUMBER) RETURN NUMBER;

 /***********************************************************************************************
  PROCEDURE: F_OBTER_ACAO_SITUACAO_CA_PBM
  DESCRIÇÃO: CA PBM - Obter Acão a ser executada na Liberação do Pedido conforme Situação da
             Aprovação dos Descontos da Indústria na Indústria no Canal Autorizador
  ***********************************************************************************************/   
  FUNCTION F_OBTER_ACAO_SITUACAO_CA_PBM(pi_nNumPed IN NUMBER) RETURN VARCHAR2;

 /*********************************************************************
  FUNÇÃO    : F_CRITICA_PEDIDO_CA_PBM
  DESCRIÇÃO : Função para verificar críticas de Pedido que será enviado
              para o Canal Autorizador CA PBM
  *********************************************************************/
  FUNCTION F_CRITICA_PEDIDO_CA_PBM(pi_nNumPed IN NUMBER) RETURN VARCHAR2;
  
 /***********************************************************************************************
  FUNÇÃO...: F_VALIDARESTRICAOVENDAFIL
  DESCRIÇÃO: Validar Cadastro de Restrições de Venda por Filial - DDMEDICA-3464
  ***********************************************************************************************/
  FUNCTION F_VALIDARESTRICAOVENDAFIL(pi_vCodFilial        IN VARCHAR2,
                                     pi_vOrigemPed        IN VARCHAR2,
                                     pi_vTipoFv           IN VARCHAR2,
                                     pi_nVlAtend          IN NUMBER,
                                     pi_nCodCondicaoVenda IN NUMBER,
                                     pi_nCondVenda        IN NUMBER,
                                     po_vMotivoRejeitado  OUT VARCHAR2,
                                     pi_nCodCli           IN NUMBER,
                                     pi_nCodUsur          IN NUMBER, 
                                     pi_nCodPlPag         IN NUMBER,
                                     pi_vCodCob           IN VARCHAR2,
                                     pi_nCodSupervisor    IN NUMBER,
                                     pi_nCodAtv1          IN NUMBER,
                                     pi_vTipoFj           IN VARCHAR2,
                                     pi_nCodPraca         IN NUMBER,
                                     pi_nNumRegiao        IN NUMBER) RETURN BOOLEAN;
                                                                                                                                                                                          
END PKG_GRAVACAO_PEDIDO_MED;
