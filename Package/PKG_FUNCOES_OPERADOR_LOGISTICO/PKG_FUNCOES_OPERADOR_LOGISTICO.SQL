CREATE OR REPLACE PACKAGE PKG_FUNCOES_OPERADOR_LOGISTICO
/***********************************************************************************************
  Package de Funcões para utilização na API de Operador Logístico
  ------------------------------------     Historico     ---------------------------------------
  Data        Responsável        Tarefa          Comentario
  10/01/2023  Anderson Silva     DDVENDAS-38983  Criação da Package
 ************************************************************************************************/
IS

 /***********************************************************************************************
  FUNÇÃO...: F_VALIDACONDICAOVENDA
  DESCRIÇÃO: Função para retornar a Condição de Venda válida para o Cliente
  ***********************************************************************************************/
  FUNCTION F_VALIDACONDICAOVENDA (P_CODCLI                 IN PCCLIENT.CODCLI%TYPE,
                                  P_INTEGRADORA            IN PCINTEGRADORA.INTEGRADORA%TYPE,
                                  P_TIPOSELECAOCONDICAO    IN PCINTEGRADORA.TIPOSELECAOCONDICAO%TYPE,
                                  P_TIPOPRAZO              IN PCPEDRETORNO.TIPOPRAZO%TYPE,
                                  P_CODFILIAL              IN PCFILIAL.CODIGO%TYPE,
                                  P_PRAZO                  IN PCPEDRETORNO.PRAZO%TYPE,
                                  P_CODPRAZO               IN PCPEDRETORNO.CODPRAZO%TYPE,
                                  P_CODIGOPROJETO          IN PCPEDRETORNO.codigoprojeto%TYPE,
                                  P_CODCONDICAOVENDA       IN PCPEDRETORNO.CODCONDICAOVENDA%TYPE) RETURN NUMBER;

 /***********************************************************************************************
  FUNÇÃO   : F_OBTEM_CREDITODISPONIVEL
  DESCRIÇÃO: Validar Limite de Crédito do Cliente
  ***********************************************************************************************/
  FUNCTION F_OBTEM_LIMITECREDITO(pi_nCodCliPrinc   IN NUMBER,
                                 pi_nLimiteCredito IN NUMBER)
  RETURN NUMBER;

 /***********************************************************************************************
  FUNÇÃO   : F_OBTEM_CREDITODISPONIVEL
  DESCRIÇÃO: Validar Limite de Crédito do Cliente
  ***********************************************************************************************/
  FUNCTION F_OBTEM_CREDITODISPONIVEL(pi_nCodCli        IN NUMBER,
                                     pi_nCodCliPrinc   IN NUMBER,
                                     pi_nCodUsur       IN NUMBER,
                                     pi_nLimiteCredito IN NUMBER) RETURN NUMBER;
                                     
 /***********************************************************************************************
  FUNÇÃO...: F_OBTER_PEDIDOS_HUB_INTEGRACAO
  DESCRIÇÃO: Função para retornar os pedidos recebidos no HUB de Integração
  ***********************************************************************************************/
  FUNCTION F_OBTER_PEDIDOS_HUB_INTEGRACAO(pi_vDataInicial IN VARCHAR2 DEFAULT NULL,
                                          pi_vDataFinal   IN VARCHAR2 DEFAULT NULL)
  RETURN TABELA_MED_PEDIDOS_HUB_INTEGRA PARALLEL_ENABLE PIPELINED;                                                                     
                     
END PKG_FUNCOES_OPERADOR_LOGISTICO;