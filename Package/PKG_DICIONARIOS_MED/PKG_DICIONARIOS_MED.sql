CREATE OR REPLACE PACKAGE PKG_DICIONARIOS_MED
/***********************************************************************************************
  #VERSAO#20200602A #VERSAO#20210302A
  ----------------------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------------------
  #VERSAO20210316A
  #VERSAO20210415A
  ----------------------------------------------------------------------------------------------
  Package de Processos Específicos de Geração de Dados do Módulo de Medicamentos
  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  18/03/2020  Anderson Silva     (DDMEDICA-5511 - Restrição da Condição; DDMEDICA-5540 - Campo ENVIARDICIONARIODADOSMED do Produto por Filial)
  18/03/2020 Anderson Silva      DDMEDICA-5980   Promoção por Markup no Servcon
  18/03/2020 Anderson Silva      DDMEDICA-6008   Utilizar todos os descontos na Integração por Promoção no Servcon
  ----------------     Historico     -----------------------------------------------------------
  Data        Responsável        Tarefa          Comentario
  01/02/2020  Anderson Silva     DDMEDICA-2032   Primeira Versao
  02/06/2020  Anderson Silva     DDMEDICA-3046   Parâmetro para aplicar preço da promoção nas 
                                                 Tabelas de Preço dos OLs
  15/12/2020  Anderson Silva     DDMEDICA-5069   Grupo Faturamento SERVCON                                                 
  02/03/2020  Anderson Silva     DDMEDICA-5782   Filial Retira ; Merge PMPF Servcon Padrão                                               

  15/04/2021  Anderson Silva     DDMEDICA-6349   Condição de Preço zerado em Promoções de Markup evitar divisão por zero
  02/07/2021  Anderson Silva     DDMEDICA-6952   Promoção de Preço Fixo - SERVCON
  04/11/2021  Anderson Silva     DDVENDAS-31504  Filtro de Origem da Validação que Pode Comprar Promoção
  26/11/2021  Anderson Silva     DDVENDAS-32108  Permitir no Arquivo de Preços com Layout Customizado 
                                                 gerar arquivos para mais de uma Filial com a mesma Região
  27/12/2021  Anderson Silva     DDVENDAS-32698  Integração por Promoção por SERVCON adicionada a Faixa de Quantidade no critério de prioridade
  22/02/2022  Anderson Silva     DDVENDAS-33943  Exportação Dicionários Hypera  
  28/03/2022  CASSIO PARDIM      DDVENDAS-34489  Adicionado decode ao buscar dados vinculados aos Clientes da PCCLIENT
  25/04/2022  Anderson Silva     DDVENDAS-35125  Melhoria Referências Externas
  17/05/2022  Anderson Silva     DDVENDAS-35547  Condicionar Tipo Política M ao Tipo Desconto na Integração SERVCON
  06/06/2022  Anderson Silva     DDVENDAS-35883  Ajuste Layout Hypera Tipo de Arquivo
  07/06/2022  Anderson Silva     DDVENDAS-35908  Grupos de Plano de Pagamento
  13/07/2022  Anderson Silva     DDVENDAS-36642  Otimização Consulta Hypera
  15/07/2022  Anderson Silva     DDVENDAS-36710  Cancelamento Hypera
  05/08/2022  Anderson Silva     DDVENDAS-37086  Promoções de Valor Mínimo na Hypera
  12/09/2022  Anderson Silva     DDVENDAS-37737  Envio obrigatório do registro de CDs e Prazos Hypera
  03/10/2022  Anderson Silva     DDVENDAS-38129  Não utilizar regra progressiva Hypera
  17/10/2022  Anderson Silva     DDVENDAS-38410  Enviar como I - Inclusão nos registros de CDs e Prazos
  19/10/2022  Anderson Silva     DDVENDAS-38410  Enviar faixas começando com zero
  22/11/2022  Anderson Silva     DDVENDAS-39005  Enviar Promoções Futuras como Ativas Hypera
  12/12/2022  Anderson Silva     DDVENDAS-39326  Gravação obrigatória do campo CODST na 2313 porque passou a ser usado no customizadd
 ************************************************************************************************/
IS PRAGMA SERIALLY_REUSABLE;
         
  FUNCTION F_OBTER_VERSIONAMENTO RETURN VARCHAR2;
           
  -----------------------------------------------------------------------------
  -- Procedimento para Inserir os Grupos de Plano de Pagamento - DDVENDAS-35908
  ----------------------------------------------------------------------------
  PROCEDURE P_INSERE_GRUPO_PLANO(pi_vCodSistema IN VARCHAR2);
                                          
 /*******************************************************************************
  Nome         : P_CONDCOMERC_SISTOPERLOG
  Descrição    : Procedimento para Gerar dados dos Sistemas de Pedido Eletrônico
  ********************************************************************************/
  PROCEDURE P_CONDCOMERC_SISTOPERLOG(pi_vCodSistema  IN VARCHAR2,
                                     pi_vEstoque     IN VARCHAR2 DEFAULT NULL);                                          

 /*******************************************************************************
  Nome         : P_CONDCOMERC_SISTOPERLOG_SERV
  Descrição    : Procedimento específico da PRC_MED_CONDCOMERC_SISTOPERLOG para
                 atender o SERVCON - DDMEDICA-2032
  ********************************************************************************/
  PROCEDURE P_CONDCOMERC_SISTOPERLOG_SERV(pi_vCodSistema  IN VARCHAR2,
                                          pi_vEstoque     IN VARCHAR2 DEFAULT NULL);

 /*******************************************************************************
  Nome         : P_CONDCOMERC_SISTOPERLOG_HYPER
  Descrição    : Procedimento específico da PRC_MED_CONDCOMERC_SISTOPERLOG para
                 atender o Hypera - DDVENDAS-33943
  ********************************************************************************/
  PROCEDURE P_CONDCOMERC_SISTOPERLOG_HYPER(pi_vCodSistema IN VARCHAR2,
                                           pi_vCodFilial  IN VARCHAR2);
               
END PKG_DICIONARIOS_MED;