CREATE OR REPLACE PACKAGE PKG_REPOSICAOLOJAS
/*******************************************************************************
  #VERSAO20201106A #VERSAO20201218A #VERSAO20210201A #VERSAO20210527A #VERSAO20220804A
  #VERSAO20220908A
  ------------------------------------------------------------------------------
  Nome         : PKG_REPOSICAOLOJAS
  Descricão    : Package de Procedimentos da Reposição de Lojas
  Alteração    : Anderson Silva - 25/04/2019
  Alteração    : Anderson Silva - 26/04/2019 - Impostos Módulo Farma Hospitalar
  Alteração    : Anderson Silva - 16/08/2019 - Utilizar Alíquotas ST da Aba Transferência - DDMEDICA-579
  Alteração    : Anderson Silva - 11/09/2019 - Agregar ICMS no Preço
  Alteração    : Anderson Silva - 19/03/2020 - Agregar ICMS no Preço sobre o Preço sem Imposto - DDMEDICA-2444
  Alteracao    : Marcos Levi    - 02/07/2020 - Rejeição de Item sem quantidade sugerida  - DDMEDICA-3215
  Alteração    : Anderson Silva - 07/08/2020 - Correção Validação sem quantidade sugerida - DDMEDICA-3571
  Alteração    : Anderson Silva - 27/10/2020 - Origem da Embalagem Master do Produto - DDMEDICA-4553
  Alteração    : Anderson Silva - 04/11/2020 - Parâmetro da Reposição de Lojas para respeitar estoque mínimo da origem - DDMEDICA-4666
  Alteração    : Anderson Silva - 23/11/2020 - Ignorar Comissão - DDMEDICA-4845
  Alteração    : Anderson Silva - 04/12/2020 - % Impostos CMV da Transferência - DDMEDICA-4968
  Alteração    : Anderson Silva - 07/12/2020 - Considerar parâmetro "FIL_UTILIZAVENDAPOREMBALAGEM" da 132 na validação do parâmetro de reposição "USAQTUNITPCEMBREPLOJA"
  Alteração    : Anderson Silva - 16/12/2020 - DDMEDICA-5077 - Pedido Avaria
  Alteração    : Anderson Silva - 13/01/2021 - Opção Gerar Despesas a partir dos Radicais do CNPJ - DDMEDICA-5286
  Alteração    : Anderson Silva - 18/01/2020 - Correção estouro mensagem - DDMEDICA-5328
  Alteração    : Anderson Silva - 01/02/2021 - Importar a Quantidade até 3 casas decimais - DDMEDICA-5477
  Alteração    : Anderson Silva - 27/05/2021 - Não transferir Produtos Cesta Básica - DDMEDICA-6697
  Alteração    : Anderson Silva - 11/06/2021 - Parâmetro de Arredondamento da Sugestão Fracionada - DDMEDICA-6815
  Alteração    : Anderson Silva - 01/07/2021 - Aplicar redução de icms sobre a alíquota que altera o preço da transferência
  Alteração    : Anderson Silva - 03/08/2022 - Aplicar PCEMBALAGEM no Calculo da Tributação - DDVENDAS-37042
  Alteração    : Anderson Silva - 08/09/2022 - Ajuste RETIRAIMPOSTO201 - DDVENDAS-37706
  Alteração    : Anderson Silva - 13/10/2022 - Tratamento para EAN inexistente com PCEMBALAGEM - DDVENDAS-38358
  Alteração    : Anderson Silva - 19/10/2022 - Tratamento para Estoque Negativo - DDVENDAS-38416
********************************************************************************/
IS PRAGMA SERIALLY_REUSABLE;

  /*****************************************************************************
   Nome         : PRC_PCMED_SUG_TRANSF_ATAC_VAR
   Descricão    : Gerar a Tabela Temporária com a Sugestão de Reposição
  ******************************************************************************/
  PROCEDURE PRC_PCMED_SUG_TRANSF_ATAC_VAR(P_CODFILIAL_ORIGEM      VARCHAR2,
                                          P_CODFILIAL_DESTINO     VARCHAR2,
                                          P_CODGRUPOLOJA          VARCHAR2,
                                          P_PRODUTO               VARCHAR2,
                                          P_DEPARTAMENTO          VARCHAR2,
                                          P_SECAO                 VARCHAR2,
                                          P_CATEGORIA             VARCHAR2,
                                          P_SUBCATEGORIA          VARCHAR2,
                                          P_MARCA                 VARCHAR2,
                                          P_FORNECEDOR            VARCHAR2,
                                          P_LINHAPRODUTO          VARCHAR2,
                                          P_CLASSE                VARCHAR2,
                                          P_DT_INICIAL_VENDA      VARCHAR2,
                                          P_DT_FINAL_VENDA        VARCHAR2,
                                          P_UNIDADE               VARCHAR2,
                                          P_PSICOTROPICO          VARCHAR2,
                                          P_TIPO_QUEBRA           NUMBER,
                                          P_UTILIZA_AGENDA        VARCHAR2,
                                          P_TIPO_SUGESTAO         VARCHAR2,
                                          P_TEMPO_REPOSICAO       NUMBER,
                                          P_CONSID_PRAZO_ENTREGA  VARCHAR2,
                                          P_APENAS_ITENS_COM_SUG  VARCHAR2,
                                          P_FORALINHA             VARCHAR2,
                                          P_AUTOMATICO_MANUAL     VARCHAR2,
                                          P_APENAS_ABAIXO_MINIMO  VARCHAR2,
                                          P_COMPRADOR_MARCA       VARCHAR2,
                                          P_TEMPO_REPOS_PRODUTO   VARCHAR2,
                                          P_IMPORTA_QTDE_TRANSF   VARCHAR2,
                                          P_SUGESTAO_EMB_MASTER   VARCHAR2,
                                          P_TIPOTRIBUTMEDIC       VARCHAR2,
                                          P_APENAS_EST_MAIOR_ZERO VARCHAR2,
                                          P_RUA                   VARCHAR2,
                                          P_TIPOCLASSE            NUMBER,
                                          P_CODFILIALRETIRA       VARCHAR2 DEFAULT NULL,
                                          P_PEDIDOAVARIA          VARCHAR2 DEFAULT NULL);

 /*******************************************************************************
  Nome         : PRC_PCMED_PED_TRANSF_ATAC_VAR
  Descricão    : Procedimento para Gerar os Pedidos de Transferências a partir da
                 Tabela Temporária com os Valores da Transferência
  *******************************************************************************/
  PROCEDURE PRC_PCMED_PED_TRANSF_ATAC_VAR(pi_nOrigemChamada      IN  NUMBER,
                                          pi_nCodMatricula       IN  NUMBER,
                                          pi_vGeraPedSemEstoque  IN  VARCHAR2,
                                          pi_vAutomaticoManual   IN  VARCHAR2,
                                          pi_vLiberaPedido       IN  VARCHAR2,
                                          pi_vGuardaFalta        IN  VARCHAR2,
                                          pi_vTipoSugestao       IN  VARCHAR2,
                                          po_nQtdePedidosGerados OUT NUMBER,
                                          po_vOcorreramErros     OUT VARCHAR2,
                                          po_vMsgErros           OUT VARCHAR2,
                                          pi_vPedidoAvaria       IN  VARCHAR2 DEFAULT NULL);

  /*******************************************************************************
   Nome         : PRC_PCMED_FTA_TRANSF_ATAC_VAR
   Descricão    : Procedimento para Gerar os Pedidos de Faltas da Reposição
  ********************************************************************************/
  PROCEDURE PRC_PCMED_FTA_TRANSF_ATAC_VAR(pi_nOrigemChamada      IN  NUMBER,
                                          pi_nCodMatricula       IN  NUMBER,
                                          pi_vGeraPedSemEstoque  IN  VARCHAR2,
                                          pi_vAutomaticoManual   IN  VARCHAR2,
                                          pi_vLiberaPedido       IN  VARCHAR2,
                                          pi_vGuardaFalta        IN  VARCHAR2,
                                          pi_vTipoSugestao       IN  VARCHAR2,
                                          po_vGerouFaltas        OUT VARCHAR2,
                                          po_nQtdePedidosGerados OUT NUMBER,
                                          po_vOcorreramErros     OUT VARCHAR2,
                                          po_vMsgErros           OUT VARCHAR2);

END PKG_REPOSICAOLOJAS;
