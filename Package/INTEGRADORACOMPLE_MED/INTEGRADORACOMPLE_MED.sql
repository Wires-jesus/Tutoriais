CREATE OR REPLACE PACKAGE INTEGRADORACOMPLE_MED
/***********************************************************************************************
  Complemento da Package de Integracao do Winthor com Sistemas de Forca de Vendas - MEDICAMENTOS
+++++++++++++++++++++++++++++++++++++++++++++++++++++
  04/02/2021  Anderson Silva DDMEDICA-5511 - Restrição da Condição
  16/03/2020  Anderson Silva DDMEDICA-5980 - Promoção de Makup na Integração SERVCON
  ----------------     Historico     ----------------
  Data        Responsável    Tarefa     Comentario
  27/02/2018  Anderson Silva MED-869    Primeira Versao - (alteracoes iniciais)
  28/08/2018  Anderson Silva MED-1554   Faixa de Quantidade na 561
  05/09/2018  Anderson Silva MED-1645   Desconto Financeiro da 561
  02/09/2018  Anderson Silva            Taxa Frete
  14/09/2018  Anderson Silva            Tratamento Lock Estoque
  13/11/2018  Anderson Silva  MED-1499  Melhora Mensagens
  21/11/2018  Anderson Silva            Merge - Rejeitar Itens Fora de Linha sem Estoque Gerencial
  05/01/2019  Anderson Silva MED-2079   Validação Margem Mínima
  24/01/2019  Anderson Silva MED-2161   Alteração forma gravar os motivos
  22/03/2019  Anderson Silva MED-2270   Cálculo Custo pela própria integradora
  14/05/2019  Anderson Silva MED-2574   Ignorar Parâmetro Desconto Máximo da 132
  19/05/2019  Anderson Silva 4493.055952.2019 - Promoção de Markup
  29/08/2019  Anderson Silva DDMEDICA-675 Função para validação restrição de filial no plano
  12/09/20019 Anderson Silva DDMEDICA-706 Otimização Obter Desconto Integradora
  16/09/2019  Anderson Silva DDMEDICA-800 Validação Desc. Médio Pedido
  05/11/2019  Jorge Humberto DDMEDICA-1245 Incluído a validação da data de vencimento do limite de crédito do cliente
  23/12/2019  Anderson Silva DDMEDICA-1654 Procedimento para retornar a transportadora da frequência de entrega
  14/01/2019  Jorge Humberto DDMEDICA-1733 Nas promoções que tiverem utilizando o campo UTILIZADESCREDE = 'S' , considerar também a promoção para o cliente principal do cliente,
  que tiver selecionado
  20/01/2019  Anderson Silva DDMEDICA-1835 Grupo de Comissão na Integradora
  20/02/2020  Anderson Silva DDMEDICA-2225 Chamar a Integradora
  02/03/2020  Anderson Silva DDMEDICA-2296 Balcão Reserva pelo Força de Vendas
  11/05/2020  Anderson Silva DDMEDICA-2858 - Ajuste pesquisa promoção com cliente principal
  15/05/2020  Anderson Silva DDMEDICA-2832 - Regra Específica para Cálculo ST Pacote
  28/05/2020  Anderson Silva DDMEDICA-3017 - Parâmetro para não validar prazo médio do pedido no OL e PE
  05/06/2020  Anderson Silva DDMEDICA-3001 - Opção para Desconsiderar Repasse na Base do Desconto Isenção ICMS
  29/07/2020  Anderson Silva DDMEDICA-3464 - Restrição por Valor Mínimo 391
  05/08/2020  Anderson Silva DDMEDICA-3551 - Log do Limite de Crédito
  15/09/2020  Anderson Silva DDMEDICA-4013 - Filtro de Tipo de Venda e Multi-seleção na Rebaixa de CMV
  08/12/2020  Anderson Silva DDMEDICA-5009 - Ler Verba Rebaixa CMV da Promoção
  19/03/2021  Anderson Silva DDMEDICA-6036 - Limite Sazonal da Rotina 3321 e garantir Código da Distribuição do Pedido conforme Produto - 30.1.10

  06/04/2021  Anderson Silva DDMEDICA-6249 - Plano de Pagamento do Item na Validação da Promoção com Grupo Faturamento
  15/06/2021  Anderson Silva DDMEDICA-6841 - Cálculo Promoção Markup por Faixa de Quantidade e Preço Fixo no Força de Vendas
  21/06/2021  Anderson Silva DDMEDICA-6837 - Promoção de Markup por Faixa de Quantidade e Preço Fixo no OL e PE
  21/06/2021  Anderson Silva DDMEDICA-6837 - Descontinuar a FCT_MED_OBTEM_DESC_OLPE usando a P_REL_OBTEM_DESC_OLPE
  01/07/2021  Lucas Rangel DDMEDICA-6883 - Alterado regra de semaforo para importação de pedidos na integradora (FUNCTION PERMITE_IMPORTAR_PEDIDO_FV)
  01/09/2021  Anderson Silva - DDMEDICA-7478 - Filtro pelo coddesconto selecionado do FV
  09/09/2021  Anderson Silva DDMEDICA-7545 - Trava de Importação Duplicada de Pedidos de OL e PE
  29/10/2021  Anderson Silva DDVENDAS-31504 - Parametrizações do SERVCON
  14/12/2021  Anderson Silva DDVENDAS-32516 - Autorização Crédito com Cliente Principal
  09/02/2022  Anderson Silva DDVENDAS-33476 - Pesquisa da 561 por Grupo de Produto
  25/04/2022  Anderson Silva DDVENDAS-35125  Melhoria Referências Externas
  05/05/2022  Anderson Silva DDVENDAS-35272 - Priorização da Promoção da Oferta
  02/06/2022  Cassio Pardim  DDVENDAS-35581 - Utilização do campo PERDESCBOLETO sem a necessidade de gerar um CODPROMOCAOMED para o item do pedido
  20/06/2022  Cassio Pardim  DDVENDAS-36173 - Ajuste para validar o campo PERDESCBOLETO
  30/09/2022  Cleber Vicente DDVENDAS-37499 - Bloquear Pedidos Duplicados durante um determinado tempo(dia/hora/mint) 
  03/11/2022  Anderson Silva DDVENDAS-38538 - Serviço de Limite de Crédito
  01/12/2022  Anderson Silva DDVENDAS-38983 - Inclusão de CallCenter na pesquisa de promoção
  04/01/2023  Anderson Silva DDVENDAS-39681 - Ajuste na pesquisa de políticas por grupo de produtos da 561 no OL
 ************************************************************************************************/
IS PRAGMA SERIALLY_REUSABLE;

  FUNCTION F_OBTER_VERSIONAMENTO RETURN VARCHAR2;

 /***********************************************************************************************
  PROCEDURE: proc_recompilar
  DESCRIÇÃO: Garantir a Recompilação
  ***********************************************************************************************/
  PROCEDURE proc_recompilar;

 /***********************************************************************************************
  FUNÇÃO...: FFORMATAR_NUMERO_PARA_TEXTO
  DESCRIÇÃO: Função para Formatar um Número para Texto
  ***********************************************************************************************/
  FUNCTION FFORMATAR_NUMERO_PARA_TEXTO(pi_nNumero            IN NUMBER,
                                       pi_iQtdeCasasDecimais IN INTEGER) RETURN VARCHAR2;

 /***********************************************************************************************
  PROCEDURE: func_gerarlogjson
  DESCRIÇÃO: Gerar Log no Formato JSON MED-1499
  ***********************************************************************************************/
  FUNCTION func_gerarlogjson(pi_vDescricaoRejeicao IN VARCHAR2,
                             pi_vObservacao        IN VARCHAR2,
                             pi_vCodRotina         IN VARCHAR2,
                             pi_nNumeroParametro   IN VARCHAR2,
                             pi_vPermissao         IN VARCHAR2,
                             pi_vSolucao           IN VARCHAR2) RETURN VARCHAR2;

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- PROCEDURE: proc_validarestricao_servcon
  -- DESCRIÇÃO: DDMEDICA-5511 - Validar a Restrição do SERVCON
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  PROCEDURE proc_validarestricao_servcon(pi_nCodCondicaoVenda  IN NUMBER,
                                         pi_nCodProd           IN NUMBER,
                                         pi_nQt                IN NUMBER,
                                         po_vRejeitado        OUT VARCHAR2,
                                         po_vMotivoRejeitado  OUT VARCHAR2,
                                         po_vObservacao       OUT VARCHAR2,
                                         po_vJsonRejeitado    OUT VARCHAR2);

 /******************************************************************
  PROCEDIMENTO PARA CONSULTAR O ACORDO DE PREÇO DO PEDIDO ELETRÔNICO
  ******************************************************************/
  PROCEDURE OBTER_ACORDO_SISTOPERLOG(pi_nIntegradora       IN NUMBER,
                                     pi_vCodFilial         IN VARCHAR2,
                                     pi_nNumRegiao         IN NUMBER,
                                     pi_nCodProd           IN NUMBER,
                                     po_vAchouAcordo       OUT VARCHAR2,
                                     po_nCodAcordo         OUT NUMBER,
                                     po_nCodPromocaoMed    OUT NUMBER,
                                     po_vTipoPromocao      OUT VARCHAR2,
                                     po_nPreco             OUT NUMBER,
                                     po_nPercDesc          OUT NUMBER,
                                     po_nVlDescCmv         OUT NUMBER,   -- DDMEDICA-5009
                                     po_nPerDescCmv        OUT NUMBER,   -- DDMEDICA-5009
                                     po_nNumVerba          OUT NUMBER,   -- DDMEDICA-5009
                                     po_nValorCotaNumVerba OUT NUMBER,   -- DDMEDICA-5009
                                     po_vSemVerbaVlDescCmv OUT VARCHAR2, -- DDMEDICA-5009
                                     po_vOcorreramErros    OUT VARCHAR2,
                                     po_vMsgErros          OUT VARCHAR2);

 /***********************************************************************************************
  PROCEDURE: proc_validaminplanosmed
  DESCRIÇÃO: Validar Valor Mínimo do Plano Ético e Genérico do Cliente - MED-869
  ***********************************************************************************************/
  PROCEDURE proc_validaminplanosmed (pi_nCodPlPagEtico     IN  NUMBER,
                                     pi_nCodPlPagGenerico  IN  NUMBER,
                                     pi_nNumPed            IN  NUMBER,
                                     po_vValido            OUT VARCHAR2,
                                     po_nCodMotivoNaoAtend OUT NUMBER,
                                     po_vMensagem          OUT VARCHAR2,
                                     po_vMsgErros          OUT VARCHAR2);

 /************************************************************************
  FUNÇÕES DE OBTER POLÍTICAS DE DESCONTO MED (retiradas das FUNCOESVENDAS)
  * Contemplando a faixa de quantidade da 561 - MED-1554
  * Filtro pelo coddesconto selecionado do FV - DDMEDICA-7478
  ************************************************************************/
  FUNCTION validarpoliticasdesconto_med -- 28 parametros
    (p_codprod                  IN NUMBER,
     p_data                     IN DATE,
     p_codfilial                IN VARCHAR2,
     p_numregiao                IN NUMBER,
     p_codcli                   IN NUMBER,
     p_codusur                  IN NUMBER,
     p_origempedido             IN VARCHAR2,
     p_codprodprinc             IN NUMBER,
     p_numcasasdecvenda         IN NUMBER,
     p_codplpag                 IN NUMBER,
     p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
     p_classevenda              IN pcclient.classevenda%TYPE,
     p_aplicadesconto           IN NUMBER,
     p_param                    IN NUMBER,
     p_dtfim                    OUT DATE,
     p_mensagem                 IN OUT VARCHAR2,
     p_perdesc                  OUT NUMBER,
     p_perdescfin               OUT NUMBER,
     p_basecreddebrca           OUT VARCHAR2,
     p_creditasobrepolitica     OUT VARCHAR2,
     p_perdescrestricao         OUT NUMBER,
     p_alteraptabela            OUT VARCHAR2,
     p_pbaserca                 OUT NUMBER,
     p_prioritaria              out varchar2,
     p_questionausoprioritaria  out varchar2,
     p_naousarautdebcredpoldesc IN varchar2 default 'N',
     p_usadescfinseparadodesccom IN varchar2,
     p_param2                    IN number,
     p_qt                        IN NUMBER,
     p_coddescontofv             IN NUMBER) RETURN BOOLEAN;

  FUNCTION validarpoliticasdesconto_med -- 29 parametros
    (p_codprod                  IN NUMBER,
     p_data                     IN DATE,
     p_codfilial                IN VARCHAR2,
     p_numregiao                IN NUMBER,
     p_codcli                   IN NUMBER,
     p_codusur                  IN NUMBER,
     p_origempedido             IN VARCHAR2,
     p_codprodprinc             IN NUMBER,
     p_numcasasdecvenda         IN NUMBER,
     p_codplpag                 IN NUMBER,
     p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
     p_classevenda              IN pcclient.classevenda%TYPE,
     p_aplicadesconto           IN NUMBER,
     p_numdias                  IN NUMBER,
     p_dtfim                    OUT DATE,
     p_mensagem                 IN OUT VARCHAR2,
     p_perdesc                  OUT NUMBER,
     p_perdescfin               OUT NUMBER,
     p_basecreddebrca           OUT VARCHAR2,
     p_creditasobrepolitica     OUT VARCHAR2,
     p_perdescrestricao         OUT NUMBER,
     p_alteraptabela            OUT VARCHAR2,
     p_pbaserca                 OUT NUMBER,
     p_prioritaria              out varchar2,
     p_questionausoprioritaria  out varchar2,
     p_naousarautdebcredpoldesc IN varchar2 default 'N',
     p_usadescfinseparadodesccom IN varchar2,
     p_param2                   IN number,
     p_codpolbaserca            out number,
     p_qt                        IN NUMBER,
     p_coddescontofv             IN NUMBER) RETURN BOOLEAN;


 /************************************************************************
  FUNÇÃO DE SEMAFORO DE IMPORTAÇÃO DE PEDIDOS DO FORÇA DE VENDAS - MED-1600
  ************************************************************************/
  FUNCTION PERMITE_IMPORTAR_PEDIDO_FV(pi_nNumPedRca         IN NUMBER,
                                      pi_nCodUsur           IN NUMBER,
                                      pi_vCgcCli            IN VARCHAR2,
                                      pi_dDtAberturaPedPalm IN DATE) RETURN VARCHAR2;

 /************************************************************************
  PROCEDIMENTO PARA RETORNAR A TAXA DE FRETE
  ************************************************************************/
  PROCEDURE OBTER_TAXA_FRETE(pi_vCodFilial   IN  VARCHAR2,
                             pi_vOrigemPed   IN  VARCHAR2,
                             pi_vTipoFv      IN  VARCHAR2,
                             po_vAchouTaxa   OUT VARCHAR2,
                             po_nValorTaxa   OUT NUMBER,
                             po_nValorMinimo OUT NUMBER);

/**************************************************************************
  PROCEDIMENTO DE SEMAFORO DE IMPORTAÇÃO DE PEDIDOS DE OPERADOR LOGISTICO
  **************************************************************************/
  PROCEDURE PERMITE_IMPORTAR_PED_OPERLOG(pi_vArquivoPed   IN VARCHAR2,
                                         pi_vNumPedVan    IN VARCHAR2,
                                         pi_vNumPedCli    IN VARCHAR2,
                                         pi_vToken        IN VARCHAR2,
                                         pi_nIntegradora  IN NUMBER,
                                         pi_nNumQuebra    IN NUMBER,
                                         pi_vReproc       IN VARCHAR2,
                                         pi_dDtImportacao IN DATE,
                                         po_vResultado    OUT VARCHAR2,
                                         po_vMsgResultado OUT VARCHAR2);

  ------------------------------------------------------------------------------
  -- Função para Verificar se Usa Regra Específica de Medicamentos --
  -- 4348.097738.2015
  -------------------------------------------------------------------
  FUNCTION FPEDIDO_EXISTE_PCPEDC(pi_vCgcCli            IN VARCHAR2,
                                 pi_nNumPedRca         IN NUMBER,
                                 pi_dDtAberturaPedPalm IN DATE,
                                 pi_nCodUsur           IN NUMBER) RETURN VARCHAR2;

 /***********************************************************************************************
  PROCEDURE: proc_validacadastrolinhaprazo
  DESCRIÇÃO: Validar Cadastro de Linha de Prazo - MED-1499
  ***********************************************************************************************/
  PROCEDURE proc_validacadastrolinhaprazo (pi_nIntegradora      IN NUMBER,
                                           pi_vTipoFv           IN VARCHAR2,
                                           pi_nCodLinhaPrazo    IN NUMBER,
                                           pi_nCodCondicaoVenda IN NUMBER,
                                           pi_nPrazo            IN NUMBER,
                                           pi_vTipoPrazo        IN VARCHAR2,
                                           pi_vCodigoPrazo      IN VARCHAR2,
                                           po_vRejeitado        OUT VARCHAR2,
                                           po_vMotivoRejeitado  OUT VARCHAR2,
                                           po_vObservacao       OUT VARCHAR2,
                                           po_vJsonRejeitado    OUT VARCHAR2);

 /***********************************************************************************************
  PROCEDURE: proc_validadescmediopedido
  DESCRIÇÃO: Validar Desconto Médio do Pedido - MED-1499
  ***********************************************************************************************/
  PROCEDURE proc_validadescmediopedido (pi_vCodFilial             IN VARCHAR2,
                                        pi_nCondVenda             IN NUMBER,
                                        pi_nPerMaxDescVendaFilial IN NUMBER,
                                        pi_nPerMaxDescVendaGeral  IN NUMBER,
                                        pi_nValorTabela           IN NUMBER,
                                        pi_nValorVenda            IN NUMBER,
                                        pi_nNumCasasDecVenda      IN NUMBER,
                                        pi_vIgnorarPerMaxDescVenda IN VARCHAR2,
                                        po_vRejeitado             OUT VARCHAR2,
                                        po_vMotivoRejeitado       OUT VARCHAR2,
                                        po_vObservacao            OUT VARCHAR2,
                                        po_vJsonRejeitado         OUT VARCHAR2);

 /***********************************************************************************************
  PROCEDURE: proc_validaprazomediopedido
  DESCRIÇÃO: Validar Prazo Médio do Pedido - MED-1499
  ***********************************************************************************************/
  PROCEDURE proc_validaprazomediopedido(pi_nCodPlPagPedido      IN NUMBER,
                                        pi_nCodPlPagCliente     IN NUMBER,
                                        pi_bExistePlPagCli      IN BOOLEAN,
                                        pi_vBloqPrazomdvenda    IN VARCHAR2,
                                        pi_vAceitaVendaBloq     IN VARCHAR2,
                                        pi_nCodPromocaoMed      IN NUMBER,
                                        pi_vOrigemPed                IN VARCHAR2,
                                        pi_vTipoFv                   IN VARCHAR2,
                                        pi_vIgnorarPrazoMedioCliente IN VARCHAR2,
                                        pi_nIntegradora              IN NUMBER,
                                        po_vRejeitado           OUT VARCHAR2,
                                        po_vMotivoRejeitado     OUT VARCHAR2,
                                        po_vObservacao          OUT VARCHAR2,
                                        po_vJsonRejeitado       OUT VARCHAR2,
                                        po_vGravarComoBloqueado OUT VARCHAR2);

 /***********************************************************************************************
  PROCEDURE: proc_validaprazomaxcobranca
  DESCRIÇÃO: Validar Prazo Máximo da Cobrança - MED-1499
  ***********************************************************************************************/
  PROCEDURE proc_validaprazomaxcobranca(pi_vCodCobPedido        IN VARCHAR2,
                                        pi_nCodPlPagPedido      IN NUMBER,
                                        pi_bValidaNivelCob      IN BOOLEAN,
                                        po_vRejeitado           OUT VARCHAR2,
                                        po_vMotivoRejeitado     OUT VARCHAR2,
                                        po_vObservacao          OUT VARCHAR2,
                                        po_vJsonRejeitado       OUT VARCHAR2);

 /***********************************************************************************************
  PROCEDURE: proc_validanivelcobranca
  DESCRIÇÃO: Validar Nivel da Cobrança - MED-1499
  ***********************************************************************************************/
  PROCEDURE proc_validanivelcobranca(pi_vCodCobCliente       IN VARCHAR2,
                                     pi_vCodCobPedido        IN VARCHAR2,
                                     pi_bValidaNivelCob      IN BOOLEAN,
                                     po_vRejeitado           OUT VARCHAR2,
                                     po_vMotivoRejeitado     OUT VARCHAR2,
                                     po_vObservacao          OUT VARCHAR2,
                                     po_vJsonRejeitado       OUT VARCHAR2);

 /***********************************************************************************************
  PROCEDURE: proc_validavalorcgccli
  DESCRIÇÃO: Validar valor gravado no CGC do Cliente - MED-1499
  ***********************************************************************************************/
  PROCEDURE proc_validavalorcgccli(pi_vCgcCli          IN  VARCHAR2,
                                   pi_nCodCli          IN  NUMBER,
                                   pi_nIntegradora     IN  NUMBER,
                                   po_vRejeitado       OUT VARCHAR2,
                                   po_vMotivoRejeitado OUT VARCHAR2,
                                   po_vObservacao      OUT VARCHAR2,
                                   po_vJsonRejeitado   OUT VARCHAR2);

 /***********************************************************************************************
  PROCEDURE: proc_validacreditocliente
  DESCRIÇÃO: Validar Limite de Crédito do Cliente - MED-1499
  ***********************************************************************************************/
  PROCEDURE proc_validacreditocliente(pi_nNumPed                  IN  NUMBER,
                                      pi_nCodCli                  IN  NUMBER,
                                      pi_nCodCliPrincipal         IN  NUMBER,
                                      pi_nCodUsur                 IN  NUMBER,
                                      pi_nLimiteCredito           IN  NUMBER,
                                      pi_nVlTotPed                IN  NUMBER,
                                      pi_vSomaCreditoCliPrincipal IN  VARCHAR2,
                                      pi_vUsaBnfLimiteCredito     IN  VARCHAR2,
                                      pi_nPerExcedeLimCred        IN  NUMBER,
                                      pi_nNumCasasDecVenda        IN  NUMBER,
                                      pi_vAtualizarAutorizacao    IN  VARCHAR2,
                                      pi_vBloqPedLimCred          IN  VARCHAR2,
                                      po_vRejeitado               OUT VARCHAR2,
                                      po_vMotivoRejeitado         OUT VARCHAR2,
                                      po_vObservacao              OUT VARCHAR2,
                                      po_vJsonRejeitado           OUT VARCHAR2,
                                      po_vGravarComoBloqueado     OUT VARCHAR2,
                                      po_nValorRetorno            OUT VARCHAR2,
                                      po_vLogDetalheLimiteRetorno OUT VARCHAR2);

 /***********************************************************************************************
  PROCEDURE: proc_validarestricaovenda
  DESCRIÇÃO: Validar Cadastro de Restrições de Venda - MED-1499
  ***********************************************************************************************/
  PROCEDURE proc_validarestricaovenda(pi_vTipoCriticaRestricaoVenda IN VARCHAR2,
                                      pi_nRotinaParamTipoCriticaRes IN NUMBER,
                                      pi_vTipoFv                    IN VARCHAR2,
                                      pi_nCodProd                   IN NUMBER,
                                      pi_nNumRegiao                 IN NUMBER,
                                      pi_nCodCli                    IN NUMBER,
                                      pi_nCodUsur                   IN NUMBER,
                                      pi_nCodFornec                 IN NUMBER,
                                      pi_nCodPraca                  IN NUMBER,
                                      pi_vClasseProduto             IN VARCHAR2,
                                      pi_nCodAtiv                   IN NUMBER,
                                      pi_nCodSupervisor             IN NUMBER,
                                      pi_vCodFilial                 IN VARCHAR2,
                                      pi_nCondVenda                 IN NUMBER,
                                      pi_vFreteDespacho             IN VARCHAR2,
                                      pi_vOrigemPed                 IN VARCHAR2,
                                      pi_nCodAuxiliar               IN NUMBER,
                                      pi_nCodPlPag                  IN NUMBER,
                                      pi_vCodCob                    IN VARCHAR2,
                                      pi_nCodMarca                  IN NUMBER,
                                      pi_nVlAtend                   IN NUMBER,
                                      po_vRejeitado                 OUT VARCHAR2,
                                      po_vMotivoRejeitado           OUT VARCHAR2,
                                      po_vObservacao                OUT VARCHAR2,
                                      po_vJsonRejeitado             OUT VARCHAR2);

 /***********************************************************************************************
  PROCEDURE: proc_validarestricaovendafil
  DESCRIÇÃO: Validar Cadastro de Restrições de Venda por Filial - DDMEDICA-3464
  ***********************************************************************************************/
  PROCEDURE proc_validarestricaovendafil(pi_vCodFilial        IN VARCHAR2,
                                         pi_vOrigemPed        IN VARCHAR2,
                                         pi_vTipoFv           IN VARCHAR2,
                                         pi_nCodCondicaoVenda IN NUMBER,
                                         po_vRejeitado        OUT VARCHAR2,
                                         po_vMotivoRejeitado  OUT VARCHAR2,
                                         po_vObservacao       OUT VARCHAR2,
                                         po_vJsonRejeitado    OUT VARCHAR2);

 /***********************************************************************************************
  PROCEDURE: proc_CARREGARDADOSVALIDACAO
  DESCRIÇÃO: Carregar Tabela Temporária com os Dados de Validação - MED-1499
  ***********************************************************************************************/
  PROCEDURE proc_CARREGARDADOSVALIDACAO(pi_nOrigem            IN NUMBER,
                                        pi_nNumPedRca         IN NUMBER,
                                        pi_nCodUsur           IN NUMBER,
                                        pi_vCgcCli            IN VARCHAR2,
                                        pi_dDtAberturaPedPalm IN DATE,
                                        pi_nCodProd           IN NUMBER,
                                        pi_nNumSeq            IN NUMBER,
                                        pi_vTipo              IN VARCHAR2);

 /***********************************************************************************************
  FUNCTION : func_foralinhasemest
  DESCRIÇÃO: Validar Fora de Linha sem Estoque
  ***********************************************************************************************/
  FUNCTION func_foralinhasemest(pREJEITARITENSFORALINHASEMEST IN VARCHAR2,
                                pCodFilial                    IN VARCHAR2,
                                pCodFilialRetira              IN VARCHAR2,
                                pCodProd                      IN NUMBER) RETURN VARCHAR2;

 /***********************************************************************************************
  PROCEDURE: proc_validamargemminima
  DESCRIÇÃO: Validar Margem Minima - MED-2079
  ***********************************************************************************************/
  PROCEDURE proc_validamargemminima(pi_vOrigemPed                  IN VARCHAR2,
                                    pi_vTipoFv                     IN VARCHAR2,
                                    pi_vCodFilial                  IN VARCHAR2,
                                    pi_vValidarMargemMinOlPe       IN VARCHAR2,
                                    pi_vPercMargemMinVendaMed      IN VARCHAR2,
                                    pi_vTipoValidMargemMinVendaMed IN VARCHAR2,
                                    pi_nCodPlPag                   IN NUMBER,
                                    pi_nMargemMinPlPag             IN NUMBER,
                                    pi_nPercMargemPedido           IN NUMBER,
                                    pi_vBloqPedAbaixoMargemFv      IN VARCHAR2,
                                    po_vRejeitado                  OUT VARCHAR2,
                                    po_vMotivoRejeitado            OUT VARCHAR2,
                                    po_vObservacao                 OUT VARCHAR2,
                                    po_vJsonRejeitado              OUT VARCHAR2,
                                    po_vGravarComoBloqueado        OUT VARCHAR2,
                                    po_nMargemMinimaAplicada       OUT NUMBER);

 /***********************************************************************************************
  PROCEDURE: proc_insere_bloqueiospedido
  DESCRIÇÃO: Inserir na Tabela de Bloqueios do Pedido - MED-2161
  ***********************************************************************************************/
  PROCEDURE proc_insere_bloqueiospedido(pi_vAtualizarPCPEDC IN VARCHAR2,
                                        pi_nNumPed          IN NUMBER,
                                        pi_nCodMotivo       IN NUMBER,
                                        pi_nCodMotBloqueio  IN NUMBER,
                                        pi_vMotivoPosicao   IN VARCHAR2);

 /**********************************************************************************************
  PROCEDIMENTO PARA RETORNAR VALORES DO PEPS - ICMS - HIS.03510.2016 - Origem Nacional/Importado - MED-2270
  **********************************************************************************************/
  PROCEDURE OBTER_DADOS_PEPS_ICMS(pi_nCodProd           IN  NUMBER,
                                  pi_vCodFilial         IN  VARCHAR2,
                                  pi_nQtde              IN  NUMBER,
                                  pi_dData              IN  DATE,
                                  po_vProdImportadoPeds OUT VARCHAR2,
                                  po_nNumTransEntPeps   OUT NUMBER,
                                  po_vMsgErros          OUT VARCHAR2);

 /**********************************************************************************************
  PROCEDIMENTO PARA RETORNAR O DESCONTO DA PROMOÇÃO - 4493.055952.2019
  **********************************************************************************************/
  PROCEDURE P_OBTEM_DESC_PROMOCAO(pi_nTipoChamada      IN  NUMBER,
                                  pi_vGravaTabTemp        IN  VARCHAR2,
                                  pi_vExecutaCommit       IN  VARCHAR2,
                                  pi_dData                IN  DATE,
                                  pi_vCodFilial           IN  VARCHAR2,
                                  pi_vTipoPrazoMedicam    IN  VARCHAR2,
                                  pi_nNumRegiao           IN  NUMBER,
                                  pi_nCodUsur             IN  NUMBER,
                                  pi_vOrigemPed           IN  VARCHAR2,
                                  pi_vTipoFv              IN  VARCHAR2,
                                  pi_nCodPlPag            IN  NUMBER,
                                  pi_nCodCondicaoVenda    IN  NUMBER,
                                  pi_nCodPromocaoMed      IN  NUMBER,
                                  pi_nCodCli              IN  NUMBER,
                                  pi_nCodProd             IN  NUMBER,
                                  pi_nQtde                IN  NUMBER,
                                  po_vTipoPromoPrecoDesc  OUT VARCHAR2,
                                  po_nCodDesconto         OUT NUMBER,
                                  po_nCodPromocaoMed      OUT NUMBER,
                                  po_nPrecoFixo           OUT NUMBER,
                                  po_nPercDesc            OUT NUMBER,
                                  po_nPercDescFin         OUT NUMBER,
                                  po_nInicioIntervaloQt   OUT NUMBER,
                                  po_nVlDescCmv           OUT NUMBER,   -- DDMEDICA-5009
                                  po_nPerDescCmv          OUT NUMBER,   -- DDMEDICA-5009
                                  po_nNumVerba            OUT NUMBER,   -- DDMEDICA-5009
                                  po_nValorCotaNumVerba   OUT NUMBER,   -- DDMEDICA-5009
                                  po_vSemVerbaVlDescCmv   OUT VARCHAR2, -- DDMEDICA-5009
                                  po_vOcorreramErros      OUT VARCHAR2,
                                  po_vMsgErros            OUT VARCHAR2,
                                  pi_nNumPedRca            IN NUMBER,
                                  pi_vRestringirPromocaoFv IN VARCHAR2,
                                  pi_TipoPromocaoPrecoDesc IN VARCHAR2,
                                  pi_nPTabela              IN NUMBER,
                                  pi_nCustoFin             IN NUMBER,
                                  po_nPercMarkupMed       OUT NUMBER,
                                  pi_nIntegradora          IN NUMBER DEFAULT NULL,
                                  pi_vConcedenteOferta     IN VARCHAR2 DEFAULT NULL);

 /*********************************************************
  Função para Retornar o Percentual de Comissão da Promoção
  *********************************************************/
  FUNCTION F_OBTER_COMISSAO_PROMOCAO(pi_nCodDesconto    IN NUMBER,
                                     pi_nCodPromocaoMed IN NUMBER,
                                     pi_vTipoVend       IN VARCHAR2,
                                     pi_nCodProd        IN NUMBER) RETURN NUMBER;

 /************************************************************
  Função para Retornar o Percentual de Comissão da Integradora
  ***********************************************************/
  FUNCTION F_OBTER_COMISSAO_INTEGRADORA(pi_nCodDesconto          IN NUMBER,
                                        pi_nCodPromocaoMed       IN NUMBER,
                                        pi_vTipoVend             IN VARCHAR2,
                                        pi_nCodProd              IN NUMBER,
                                        pi_nIntegradora          IN NUMBER DEFAULT NULL,
                                        po_nComissaoIntegradora OUT NUMBER) RETURN VARCHAR2;

 /************************************************************
  Função para Retornar se Bloqueia a Comissão do RCA
  ***********************************************************/
  FUNCTION F_BLOQUEIA_COMISSAO(pi_nCodUsur IN NUMBER) RETURN VARCHAR2;                                        
                                        
 /***********************************************************************************************
  PROCEDURE: proc_validamarfilialplano
  DESCRIÇÃO: Validar Filial do Plano de Pagamento - DDMEDICA-675
  ***********************************************************************************************/
  PROCEDURE proc_validamarfilialplano(pi_vOrigemPed                  IN VARCHAR2,
                                      pi_vTipoFv                     IN VARCHAR2,
                                      pi_vCodFilial                  IN VARCHAR2,
                                      pi_nCodPlPag                   IN NUMBER,
                                      pi_vTipoEticoGenerico          IN VARCHAR2,
                                      pi_vTipoImportacaoVenda        IN VARCHAR2,
                                      po_vRejeitado                  OUT VARCHAR2,
                                      po_vMotivoRejeitado            OUT VARCHAR2,
                                      po_vObservacao                 OUT VARCHAR2,
                                      po_vJsonRejeitado              OUT VARCHAR2,
                                      po_vGravarComoBloqueado        OUT VARCHAR2,
                                      po_nCodMotivoNaoAtend          OUT NUMBER);

 /***********************************************************************************************
  PROCEDURE: P_OBTEM_DESC_INTEGRADORA
  DESCRIÇÃO: DDMEDICA-706 - Otimização Consulta por Condição de Venda
  ***********************************************************************************************/
  PROCEDURE P_OBTEM_DESC_INTEGRADORA(pi_nCodProd                  IN  pcprodut.codprod%type,
                                     pi_nqtde                     IN  pcpedi.qt%type,
                                     pi_nCodCondicaoVenda         IN  pccondicaovenda.codcondicaovenda%type,
                                     pi_nCodCli                   IN  pcclient.codcli%type,
                                     pi_dData                     IN  DATE,
                                     pi_sCodFilial                IN  pcfilial.codigo%type,
                                     pi_nNumregiao                IN  pcregiao.numregiao%type,
                                     pi_nCodusur                  IN  pcusuari.codusur%type,
                                     pi_sOrigempedido             IN  pcpedc.origemped%type,
                                     pi_nCodProdPrinc             IN  pcprodut.codprodprinc%type,
                                     pi_nNumcasasdecvenda         IN  pcconsum.numcasasdecvenda%type,
                                     pi_nCodPlPag                 IN  pcplpag.codplpag%type,
                                     pi_nnumdias                  IN  pcplpag.numdias%type,
                                     pi_sclassevenda              IN  pcclient.classevenda%type,
                                     pi_ncodpraca                 IN  pcclient.codpraca%type,
                                     pi_snaousarautdebcredpoldesc IN varchar2,
                                     pi_sUsaprioritaria           IN varchar2,
                                     pi_sTipofv                   IN pcpedretorno.tipofv%type,
                                     po_sBasecreddebrca           OUT pcdesconto.basecreddebrca%type,
                                     po_sCreditasobrepolitica     OUT pcdesconto.creditasobrepolitica%type,
                                     po_sAlteraptabela            OUT pcdesconto.alteraptabela%type,
                                     po_nDescpbaserca             OUT pcdesconto.percdesc%type,
                                     po_creditasobreptabela_quant  OUT pcdescquant.creditasobreptabela%type,
                                     po_basedebcredrca_quant      OUT pcdescquant.basecreddebrca%type,
                                     po_percbaserca_quant         OUT pcdescquant.percdesc%type,
                                     po_nPerDesc                  OUT NUMBER,
                                     po_nPerBonific               OUT NUMBER,
                                     po_nPerComerc                OUT NUMBER,
                                     po_nPerBoleto                OUT NUMBER,
                                     po_nPercDescFin              OUT NUMBER,
                                     po_vOcorreramErros           OUT VARCHAR2,
                                     po_vMsgErros                 OUT VARCHAR2,
                                     pio_CodLinhaPrazo            IN  OUT VARCHAR2, -- 155824)
                                     pi_stratarrestricaoacrescimo IN  VARCHAR2, --4663.087543.2014
                                     pi_saplicaracrescimopolitica IN  VARCHAR2,
                                     po_nCodDescontoPolitica      OUT NUMBER,    -- HIS.03080.2016
                                     po_nCodPromocaoMedPolitica   OUT NUMBER,    -- HIS.03080.2016
                                     po_nPrecoFixoPolitica        OUT NUMBER,    -- HIS.03080.2016
                                     po_vTipoPrecoDescPolitica    OUT VARCHAR2,  -- HIS.03080.2016
                                     po_nVlDescCmv                OUT NUMBER,    -- DDMEDICA-5009
                                     po_nPerDescCmv               OUT NUMBER,    -- DDMEDICA-5009
                                     po_nNumVerba                 OUT NUMBER,    -- DDMEDICA-5009
                                     po_nValorCotaNumVerba        OUT NUMBER,    -- DDMEDICA-5009
                                     po_vSemVerbaVlDescCmv        OUT VARCHAR2,  -- DDMEDICA-5009
                                     po_vMsgProc                  OUT VARCHAR2,  -- HIS.03080.2016
                                     pi_vGravaTabTemp             IN  VARCHAR2,
                                     pi_vExecutaCommit            IN  VARCHAR2,
                                     pi_nIntegradora              IN  NUMBER,
                                     pi_nPTabela                  IN  NUMBER,
                                     pi_nCustoFin                 IN  NUMBER,
                                     po_nInicioIntervaloQt        OUT NUMBER,
                                     po_nPercMarkupMed            OUT NUMBER);

 /***********************************************************************************************
  PROCEDURE: P_VALIDAR_DESC_INTEGRADORA
  DESCRIÇÃO: DDMEDICA-706 - Otimização Consulta por Condição de Venda
  ***********************************************************************************************/
  PROCEDURE P_VALIDAR_DESC_INTEGRADORA(pi_nNumPedRca  IN  NUMBER,
                                       pi_nCodUsur    IN  NUMBER,
                                       pi_nCodProd    IN  NUMBER,
                                       po_vMensagem   OUT VARCHAR2);

 /***********************************************************************************************
  PROCEDURE: P_OBTER_TRANSPORTADORA_FREQENT
  DESCRIÇÃO: DDMEDICA-1654 - Obter Transportadora da Frequência de Entrega
  ***********************************************************************************************/
  PROCEDURE P_OBTER_TRANSPORTADORA_FREQENT(pi_nCodPraca           IN  NUMBER,
                                           pi_vCodFilial          IN VARCHAR2,
                                           po_nCodTransportadora OUT NUMBER,
                                           po_nCodFreqEntrega    OUT NUMBER);

 /***********************************************************************************************
  PROCEDURE: P_OBTER_DESC_SPREAD_OL
  DESCRIÇÃO: DDMEDICA-1835 - Validação de Pré-Cadastro de Descontos da Indústria
  ***********************************************************************************************/
  PROCEDURE P_OBTER_DESC_SPREAD_OL(pi_vOpcao               IN  VARCHAR2,
                                   pi_vCodFilial           IN  NUMBER,
                                   pi_nCodProd             IN  NUMBER,
                                   pi_nCodCli              IN  NUMBER,
                                   pi_nIntegradora         IN  NUMBER,
                                   pi_nCodCondicaoVenda    IN  NUMBER,
                                   po_nPrioridade          OUT NUMBER,
                                   po_vTipo                OUT VARCHAR2,
                                   po_nPercentual          OUT NUMBER,
                                   po_nPercRefDebCred      OUT NUMBER,
                                   po_nPercAcrescimo       OUT NUMBER,
                                   po_nPrioridadeAcrescimo OUT NUMBER);

 /***********************************************************************************************
  PROCEDURE: F_OBTER_RCA_LINHAPROD
  DESCRIÇÃO: DDMEDICA-1835 - Obter o RCA da Linha de Produto
  ***********************************************************************************************/
  FUNCTION F_OBTER_RCA_LINHAPROD(pi_nCodCli                    IN NUMBER,
                                 pi_nCodProd                   IN NUMBER,
                                 pi_vCodFilial                 IN VARCHAR2 DEFAULT NULL,
                                 pi_vUsarClienteLinhaFilialMed IN VARCHAR2 DEFAULT 'N') RETURN NUMBER;

 /***********************************************************************************************
  PROCEDURE: F_RCA_PREPOSTO
  DESCRIÇÃO: DDMEDICA-1835 - Verifica se o RCA é Proposto (Vem no arquivo de pedido)
  ***********************************************************************************************/
  FUNCTION F_RCA_PREPOSTO(pi_nCodUsur       IN NUMBER,
                          pi_vCodVendedorOL IN VARCHAR2) RETURN VARCHAR2;

  ------------------------------------------------------------------------------
  -- Função para Calcular o ST conforme Regra do Pacote - DDMEDICA-2832
  ------------------------------------------------------------------------------
  FUNCTION FCALCULAR_ST(pi_nNUMCASASDECVENDA       IN NUMBER,
                        pi_vCODFILIAL              IN VARCHAR2,
                        pi_vCODFILIANF             IN VARCHAR2,
                        pi_vCODFILIALRETIRA        IN VARCHAR2,
                        pi_nCODCLI                 IN NUMBER,
                        pi_nCODPLPAG               IN NUMBER,
                        pi_nCODPROD                IN NUMBER,
                        pi_nCODAUXILIAR            IN NUMBER,
                        pi_nCONDVENDA              IN NUMBER,
                        pi_nNUMREGIAO              IN NUMBER,
                        pi_nPRECO                  IN NUMBER,
                        pi_vITEMBNF                IN VARCHAR2,
                        pi_nVALORDESCPIS_COFINS    IN NUMBER,
                        pi_nVALORDESCICMS          IN NUMBER,
                        pi_nVALORSUFRAMA           IN NUMBER,
                        pio_vMensagem              IN OUT VARCHAR2,
                        pio_nST                    IN OUT NUMBER,
                        pio_nBASEST                IN OUT NUMBER,
                        pio_nVALORIPI              IN OUT NUMBER,
                        pio_nBASEFECP              IN OUT NUMBER,
                        pio_nALIQFECP              IN OUT NUMBER,
                        pio_nVLFECP                IN OUT NUMBER,
                        po_nPrecoSemImposto        OUT NUMBER) RETURN BOOLEAN;


 /**********************************************
  Procedimento para Rebaixar CMV - DDMEDICA-4013
  **********************************************/
  procedure proc_RebaixarCMV(p_numped in number, 
                             p_data in date,
                             p_codfilial in varchar2, 
                             p_codcontarebaixacmvaapurar in number, 
                             p_codcontarebaixacmv in number, 
                             p_condvenda in number,
                             p_codcli in number);
                             
 /*************************************************************************
  Nome        : P_ATU_DISTRIB_PEDIDO_INICIAL
  Objetivo    : Garantir no Pedido Inicial a Distribuição dos Produtos 
                que ficaram nele - DDMEDICA-6036
  Parametros  : pi_nNumPed : Filtro Número do Pedido Inicial
                pi_vMEDPERMITEDISTRIBDIFRCA : Parâmetro que permite Múltiplas Distribuições no Pedido
  ************************************************************************/
  PROCEDURE P_ATU_DISTRIB_PEDIDO_INICIAL(pi_nNumPedInicial           IN NUMBER,
                                         pi_vMEDPERMITEDISTRIBDIFRCA IN VARCHAR2);

 /*****************'****************************************************
  FUNÇÃO   : F_RETORNAR_PLPAG_ITEM
  DESCRIÇÃO: Retorna o Plano de Pagamento do Item
  *********************************************************************/
  FUNCTION F_RETORNAR_PLPAG_ITEM(pi_vTipoPrazoMedicamen IN VARCHAR2,
                                 pi_nCodProd            IN NUMBER,
                                 pi_nCodPlPag_PCPEDI    IN NUMBER,
                                 pi_nCodPlPag_PCPEDC    IN NUMBER,
                                 pi_nCodPlPag_ETICO     IN NUMBER,
                                 pi_nCodPlPag_GENERICO  IN NUMBER,
                                 pi_vGrupoFaturamento   IN VARCHAR2) RETURN NUMBER;

  /*******************************************************************************
   Nome         : P_REL_OBTEM_DESC_OLPE
   Descricão    : Procedimento para Retornar o Desconto do OL e PE
   Alteração    : Anderson Silva - 22/06/2021 - Criação do Procedimento
  ********************************************************************************/
  PROCEDURE P_REL_OBTEM_DESC_OLPE(pi_nIntegradora      IN NUMBER,
                                  pi_vCodFilial        IN VARCHAR2,
                                  pi_nCodCli           IN NUMBER,
                                  pi_nCodCondicaoVenda IN NUMBER,
                                  pi_nCodProdAdicional IN NUMBER,
                                  pi_nQtde             IN NUMBER);
								  
/***********************************************************************************************
  FUNÇÃO...: F_POSSUIVENDADUPLIC
  DESCRIÇÃO: Função para verificar se possui venda duplicada durante um determinado tempo(dia/hora/mint) 
  ***********************************************************************************************/
  FUNCTION F_POSSUIVENDADUPLIC(pi_vCgcCli            IN VARCHAR2,
                               pi_nIntegradora       IN NUMBER,
                               pi_dDtaberturapedpalm IN DATE,
                               pi_nCodUsur           IN NUMBER,
                               pi_nNumpedRca         IN NUMBER) RETURN boolean; 								  

END INTEGRADORACOMPLE_MED;