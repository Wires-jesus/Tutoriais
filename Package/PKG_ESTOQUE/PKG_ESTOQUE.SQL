CREATE OR REPLACE PACKAGE PKG_ESTOQUE IS
  ---------------------------------------------------------------------------------------------------------
  -- Autor      : Ilquias.Medeiros / Silvomar
  -- Criado em  : 20/04/2015

  /************************************************************************************************************************
                                       Documento de orientação de uso da PKG_ESTOQUE
  ************************************************************************************************************************
  -------------------------------------------------------------------------------------------------------------------------
  Como é definido o nome das funções/procedures:

      O nome das funções deve conter sempre o contexto para qual a mesma será usada. Caso a mesma seja utilizada internamente deve
  sempre ser criada iniciando com as lentras "PRIV_" para demostrar que esta função/precedure é orquestrada pela função "ADMINISTRAR_ESTOQUE".
  Após estas lentras deve ser inserida uma palavra que represente o processo que a função/precedure fará. Exemplo: Se for reservar o estoque,
  então deve ser usada a palavra "RESERVA". Caso a intenção seja bloqueiar o estoque, então a palavra será "BLOQUEIO", etc.
  A ultima parte do nome da função/precedure deve conter sempre a ação que será executada dentro do processo. Exemplo: Se for incluir
  uma reserva de um estoque a palavra deve ser "INCLUIR". Caso seja uma baixa do estoque reservado, então a palavra deve ser "BAIXAR", etc.

  Veja definições:
  PRIV : E a obreviação de PRIVATE que significa que a função/procedure só "PODE SER EXECUTADA" por uma função
         que exista dentro da PKG_ESTOQUE, nunca de forma externa.

  -------------------------------------------------------------------------------------------------------------------------
  Quando e como usar a função "ADMINISTRAR_ESTOQUE":
      A função "ADMINISTRAR_ESTOQUE" tem como objetivo ser a única função externa da PKG_ESTOQUE para manipulação do estoque.
  Desta forma o desenvolvedor não terá dúvidas de qual função chamar para baixar, reservar, bloquear, etc. Sempre será usada a
  função "ADMINISTRAR_ESTOQUE".

  IMPORTANTE: Toda e qualquer nova necessidade de usar a PKG_ESTOQUE deve ser atribuida a função "ADMINISTRAR_ESTOQUE".
  Não se deve alterar rotinas para chamar função/precedure da PKG_ESTOQUE diferente "ADMINISTRAR_ESTOQUE".
  Para que seja possível usar esta função com o minímo de dúvida na utilização, esta função tem um TYPE de entrada que deve
  ter o minimo de parâmetros possível para diminuir a complexidade do código. Pensando nisso definimos alguns estes parâmetros, veja:

  Retorno da função:
                : O retorno da função é "S" para quando a administração do estoque foi executada corretamente e "N" para quando ocorreu
                  um erro e o processo deverá ser abortado pela aplicação.

  Veja parâmetros de entrada:
  ROTINA        : Este parâmetro é usado para identificar a rotina e consequentemente o processo macro do WinThor. Exemplo: Comprando,
                  vendendo ou gerenciando o estoque.
                * Este parâmetro é "OBRIGATÓRIO"!

  PROCESSO      : Este parâmetro é usado para identificar o processo que a rotina esta tentando executar. Este parâmetro é necessário quando
                  existe mais de um processo que pode ser executado. Exemplo: Se a rotina for 4116/316, ela pode chamar a PKG_ESTOQUE para criar
                  dados nas tabelas PCEST e PCESTOQUEDEPOSITOPROD, para baixar o estoque dos produtos definidos como máteria prima de um KIT,
                  fazer a reserva/pendente do estoque, etc. veja valores existes:
                  BLOQUEAR, RESERVAR, POPULAR, COMPRAR, VENDER, PRODUZIR.
                 * Este parâmetro "É OBRIGATÓRIO"!

  OPERACAO      : Este parâmetro é usado para direcionar como será executada a administração do estoque.
                  É informando "T" (Todos os produtos) quando o usuário informa apenas o identificador e o código da rotina para que seja
                  executada a administração de todos os itens e "P" (Produto) quando o usuário informa o produto e a sequencia do mesmo.
                * Este parâmetro é "OBRIGATÓRIO"!

  IDENTIFICADOR : Este parâmetro é usado para identificar o pedido, nota fiscal, ordem de produção, etc, que será necessário
                  administrar. Com esta informação é possível localizar os itens que serão administrados.
                * Este parâmetro é "OBRIGATÓRIO" quando a operação for igual a "T" e "DESNECESSÁRIO" quando for igual a "P".

  CODFILIAL     : Este parâmetro é usado para identificar a filial.
                * Este parâmetro é "OBRIGATÓRIO" quando o identificador "NÃO" for informado e "DESNECESSÁRIO" quando for informado o identificador.

  CODPROD       : Este parâmetro é usado para identificar o produto.
                * Este parâmetro é "OBRIGATÓRIO" quando o identificador "NÃO" for informado ou quando a operação é igual a "P". É "DESNECESSÁRIO"
                  quando for informado o identificador e a operação é igual a "T".

  NUMERICO_1    : Este parâmetro pode ser usado para identificar a quantidade, o código de um depósito, ou qualquer valor númerico necessário para
                  administrar o estoque. Exemplo:
                  "Quero bloquear 10 unidades manualmente do produto X". Neste exemplo usaremos este campo para informar a quantidade.
                * Este parâmetro pode ser "OBRIGATÓRIO" para algumas rotinas.

  NUMERICO_2, NUMERICO_3 e NUMERICO_4:
                : Estes parâmetros seguem a mesma linha do parâmetro NUMERICO_1.

  CARACTER_1    : Este parâmetro pode ser usado para identificar um valor de decisão (Sim e Não) ou seja, valores literais.
                * Este parâmetro pode ser "OBRIGATÓRIO" para algumas rotinas.

  CARACTER_2, CARACTER_3 e CARACTER_4:
                : Estes parâmetros seguem a mesma linha do parâmetro CARACTER_1.

  MSG_RETORNO   : Este parâmetro deve ser sempre vinculado ao retorno da função. É usado para retornar informações obtidas durante a
                  administração do estoque. O padrão inicial deste retorno é sempre a palavra "OK", o que significa que tudo foi executado
                  de forma correta sem apresentar nenhum erro. Logo o retorno deve ser igual a "S". Caso o valor deste campo seja diferente
                  de "OK" então é porque existe algo de errado na administração do estoque o retorno da função deve ser igual a "N" e a
                  aplicação deve abortar o processo e avisar ao usuário o que aconteceu. Lembrando que todos as mensagens contidas neste
                  parâmetro devem ser explicativas e conter informações que o usuário pode conferir manualmente o motivo do problema e se
                  possível resolve-ló sem a necessidade de acionar o suporte.
                * Este parâmetro é "OBRIGATÓRIO".


###########################################################################################################################
***************************************************************************************************************************
                             Regra para o parâmetro "Operação" (Quando não se usa ADMINISTRAR_ESTOQUE)
***************************************************************************************************************************
###########################################################################################################################
  Regra para o primeiro caracter:
  - Sempre informar a letra "A" quando for uma opção de ALTERAÇÃO.
  - Sempre informar a letra "B" quando for uma opção de BAIXA.
  - Sempre informar a letra "C" quando for uma opção de CANCELAMENTO.
  - Sempre informar a letra "F" quando for uma opção de CORTE.
  - Sempre informar a letra "I" quando for uma opção de INCLUSAO.
  *****************************************************************************
  Regras para o segundo caracter: (São reservadas para uma regra de negocio especifica)

  Caracter útilizadas atualmente:
  A - Ordem de produção Avulsa
  B - Gestão de bloqueado/Avaria via bonus (1106)
  C - Cancelar Conferência de um pedido de venda
  E - Entrada de mercadoria
  F - Estoque frente de loja (Autosseviço)
  G - Gestão de avaria (1181)
  I - Ordem de produção normal da indústria
  M - Requisição de materia prima
  N - Gestão de pedido de venda item a item (Reservar/Pendente)
  O - Ordem de serviço (modulo 35)
  P - Gestão de pedido de venda (Reservar/Pendente)
  Q - Gestão de pedido de venda item a item (Reservar/Pendente)
  R - Gestão de requisições entre depósitos/embalagens/lotes
  U - Alteração manualmente feita pelo usuário
  V - Gestão de cupom/pedido feitos em um PDV/ECF

  ----------------- Regra detalhada considerando os dois caracteres ------------------------
  Nivel de Itens (Quando a chamada for feita item a item):

  AD - Usado para alterar um item de um inventário                            Modulo: Adm. Estoque - 11;
  ------------------------------------------------------------------------------------------------------
  AA - Usado para alterar um item de uma ordem de produção Avulsa             Modulo: Industria - 16;
  BA - Usado para baixar um item de uma ordem de produção Avulsa              Modulo: Industria - 16;
  CA - Usado para cancelar um item de uma ordem de produção Avulsa            Modulo: Industria - 16;
  IA - Usado para incluir um item de uma ordem de produção Avulsa             Modulo: Industria - 16;
  ------------------------------------------------------------------------------------------------------
  AB - Usado para alterar um item de um entrada/bonus                         Modulo: Expedição - 9;
  BB - Usado para baixar um item de um entrada/bonus                          Modulo: Expedição - 9;
  CB - Usado para cancelar um item de um entrada/bonus                        Modulo: Expedição - 9;
  IB - Usado para incluir um item de um entrada/bonus                         Modulo: Expedição - 9;
  ------------------------------------------------------------------------------------------------------
  AE - Usado para alterar um item de uma compra/entrada                       Modulo: Entrada - 13;
  BE - Usado para baixar um item de uma compra/entrada                        Modulo: Entrada - 13;
  CE - Usado para cancelar um item de uma compra/entrada                      Modulo: Entrada - 13;
  IE - Usado para incluir um item de uma compra/entrada                       Modulo: Entrada - 13;
  ------------------------------------------------------------------------------------------------------
  AG - Usado para alterar um item de uma gestão de avaria (1181)              Modulo: Adm. Estoque - 11;
  BG - Usado para baixar um item de uma gestão de avaria (1181)               Modulo: Adm. Estoque - 11;
  CG - Usado para cancelar um item de uma gestão de avaria (1181)             Modulo: Adm. Estoque - 11;
  IG - Usado para incluir um item de uma gestão de avaria (1181)              Modulo: Adm. Estoque - 11;
  ------------------------------------------------------------------------------------------------------
  AI - Usado para alterar um item de uma ordem de produção                    Modulo: Industria - 16;
  BI - Usado para baixar um item de uma ordem de produção                     Modulo: Industria - 16;
  CI - Usado para cancelar um item de uma ordem de produção                   Modulo: Industria - 16;
  II - Usado para incluir um item de uma ordem de produção                    Modulo: Industria - 16;
  ------------------------------------------------------------------------------------------------------
  AM - Usado para alterar um item de uma requisição de materia prima          Modulo: Adm. Estoque - 11;
  BM - Usado para baixar um item de uma requisição de materia prima           Modulo: Adm. Estoque - 11;
  CM - Usado para cancelar um item de uma requisção de materia prima          Modulo: Adm. Estoque - 11;
  IM - Usado para incluir um item de uma requisição de materia prima          Modulo: Adm. Estoque - 11;
  ------------------------------------------------------------------------------------------------------
  IO - Usado para incluir um item de uma ordem de serviço                     Modulo: Serviço - 35;
  BO - Usado para baixar um item de uma ordem de serviço                      Modulo: Serviço - 35;
  AO - Usado para alterar um item de uma ordem de serviço                     Modulo: Serviço - 35;
  CO - Usado para cancelar um item de uma ordem de serviço                    Modulo: Serviço - 35;
  ------------------------------------------------------------------------------------------------------
  IN - Usado para incluir um item de um pedido de venda                       Modulo: Vendas - 3;
  BQ - Usado para baixar um item de um pedido de venda                        Modulo: Vendas - 3;
  AQ - Usado para alterar um item de um pedido de venda                       Modulo: Vendas - 3;
  CQ - Usado para cancelar um item do pedido de venda                         Modulo: Vendas - 3;
  FQ - Usado para alterar um item de um pedido de venda que teve corte        Modulo: Expedição - 9;
  ------------------------------------------------------------------------------------------------------
  IR - Usado para incluir um item de uma requisição de estoque (Depósito/Embalagem/Lote);
  BR - Usado para baixar um item de uma requisição de estoque (Depósito/Embalagem/Lote);
  AR - Usado para alterar um item de uma requisição de estoque (Depósito/Embalagem/Lote);
  CR - Usado para cancelar um um item de uma requisição de estoque (Depósito/Embalagem/Lote);
  ------------------------------------------------------------------------------------------------------
  IU - Usado para incluir um item manualmente pelo usuário                 Modulo: TODOS;
  BU - Usado para baixar um item manualmente pelo usuário                  Modulo: TODOS;
  AU - Usado para alterar um item manualmente pelo usuário                 Modulo: TODOS;
  CU - Usado para cancelar um item manualmente pelo usuário                Modulo: TODOS;
  ------------------------------------------------------------------------------------------------------
  IV - Usado para incluir um item de cupom/pedido ECF                         Modulo: Autosserviço - 20;
  BV - Usado para baixar um item de cupom/pedido ECF                          Modulo: Autosserviço - 20;
  AV - Usado para alterar um item de cupom/pedido ECF                         Modulo: Autosserviço - 20;
  CV - Usado para cancelar um item de cupom/pedido ECF                        Modulo: Autosserviço - 20;
  IF - Usado para incluir quantidade frente de loja                           Modulo: Autosserviço - 20;
  BF - Usado para baixar quantidade frente de loja                            Modulo: Autosserviço - 20;

  ######################################################################################################

  Nivel de Pedido (Quando a chamada for feita pelo pedido):
  IP - Usado para incluir todos os itens de um pedido de venda                Modulo: Vendas - 3;
  BP - Usado para baixar todos os itens de um pedido de venda                 Modulo: Vendas - 3;
  AP - Usado para alterar todos os itens de um pedido de venda                Modulo: Vendas - 3;
  CP - Usado para cancelar todos os itens de um pedido de venda               Modulo: Vendas - 3;
  CC - Usado para cancelar a conferência de um pedido de venda                Modulo: Expedição - 9;

  /**********************************************************************************************
                                             TYPE
  ----------------------------------------------------------------------------------------------*/
  /* Type padrão para administrar o estoque (processo de refatoração da PKG_ESTOQUE)*/
  /**********************************************************************************************/
  TYPE T_ENTRADA IS RECORD
     (ROTINA                      NUMBER
     ,OPERACAO                    VARCHAR2(1)
     ,PROCESSO                    VARCHAR2(30)
     ,IDENTIFICADOR               NUMBER
     ,CODFILIAL                   VARCHAR2(2)
     ,CODPROD                     NUMBER
     ,NUMERICO_1                  NUMBER
     ,NUMERICO_2                  NUMBER
     ,NUMERICO_3                  NUMBER
     ,NUMERICO_4                  NUMBER
     ,NUMERICO_5                  NUMBER
     ,NUMERICO_6                  NUMBER
     ,NUMERICO_7                  NUMBER
     ,CARACTER_1                  VARCHAR2(30)
     ,CARACTER_2                  VARCHAR2(30)
     ,CARACTER_3                  VARCHAR2(30)
     ,CARACTER_4                  VARCHAR2(30)
     ,CARACTER_5                  VARCHAR2(1)
     ,MSG_RETORNO                 VARCHAR2(2000));

  /**********************************************************************************************/
  /* Type para consulta do disponível da Cesta Básica - CB */
  /**********************************************************************************************/
  TYPE T_ESTOQUE IS RECORD
    (CODFILIAL             PCEST.CODFILIAL%TYPE
    ,CODPROD               PCEST.CODPROD%TYPE
    ,PRIORIDADE            PCFILIALRETIRA.PRIORIDADEFILIAL%TYPE
    ,QTEST                 PCEST.QTEST%TYPE
    ,QTESTGER              PCEST.QTESTGER%TYPE
    ,QTDISP                PCEST.QTESTGER%TYPE
    ,QTDISP_CONT           PCEST.QTESTGER%TYPE
    ,QTDISPPECA            PCEST.QTESTGER%TYPE
    ,QTDISP_CONTPECA       PCEST.QTESTGER%TYPE
    ,QTDISPPESOBRUTO       PCEST.QTESTGER%TYPE
    ,QTDISP_CONTPESOBRUTO  PCEST.QTESTGER%TYPE
    ,PESOBRUTOMASTER       PCPRODUT.PESOBRUTOMASTER%TYPE
    ,PESOPECA              PCPRODUT.PESOPECA%TYPE
    ,MSG_RETORNO           VARCHAR2(2000));

  /**********************************************************************************************/
  /* Type para consulta dados anteriores do pedido
  /**********************************************************************************************/
  TYPE TYPE_DADOS_MOV IS RECORD
   (NEW_NUMTRANSVENDA        PCMOV.NUMTRANSVENDA%TYPE
   ,NEW_NUMTRANSENT          PCMOV.NUMTRANSENT%TYPE
   ,NEW_NUMPED               PCMOV.NUMPED%TYPE
   ,NEW_CODFILIAL            PCMOV.CODFILIAL%TYPE
   ,NEW_CONDVENDA            PCNFSAID.CONDVENDA%TYPE
   ,NEW_CODPROD              PCPEDI.CODPROD%TYPE
   ,NEW_NUMLOTE              PCLOTE.NUMLOTE%TYPE
   ,NEW_CODDEPOSITO          PCPEDI.CODDEPOSITO%TYPE
   ,NEW_NUMSEQ               PCPEDI.NUMSEQ%TYPE
   ,NEW_QT                   PCMOV.QT%TYPE
   ,NEW_QTCONT               PCMOV.QTCONT%TYPE
   ,NEW_DTCANCEL             PCMOV.DTCANCEL%TYPE
   ,NEW_CODOPER              PCMOV.CODOPER%TYPE
   -- Valores Anteriores
   ,OLD_NUMTRANSVENDA        PCMOV.NUMTRANSVENDA%TYPE
   ,OLD_NUMTRANSENT          PCMOV.NUMTRANSENT%TYPE
   ,OLD_NUMPED               PCMOV.NUMPED%TYPE
   ,OLD_CODFILIAL            PCMOV.CODFILIAL%TYPE
   ,OLD_CONDVENDA            PCNFSAID.CONDVENDA%TYPE
   ,OLD_CODPROD              PCMOV.CODPROD%TYPE
   ,OLD_NUMLOTE              PCMOV.NUMLOTE%TYPE
   ,OLD_CODDEPOSITO          PCMOV.CODDEPOSITO%TYPE
   ,OLD_NUMSEQ               PCMOV.NUMSEQ%TYPE
   ,OLD_QT                   PCMOV.QT%TYPE
   ,OLD_QTCONT               PCMOV.QTCONT%TYPE
   ,OLD_DTCANCEL             PCMOV.DTCANCEL%TYPE
   ,OLD_CODOPER              PCMOV.CODOPER%TYPE);

  /**********************************************************************************************/
  /* Type para consulta dados anteriores do pedido
  /**********************************************************************************************/
  TYPE TYPE_DADOS_PEDIDO IS RECORD
   (TIPO_OPERACAO            PCLOGPKG_ESTOQUE.TIPO_OPERACAO%TYPE
   ,NEW_IDENTIFICADOR        PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
   ,NEW_CODFILIAL            PCPEDC.CODFILIAL%TYPE
   ,NEW_CODPROD              PCPEDI.CODPROD%TYPE
   ,NEW_NUMLOTE              PCLOTE.NUMLOTE%TYPE
   ,NEW_CODDEPOSITO          PCPEDI.CODDEPOSITO%TYPE
   ,NEW_NUMSEQ               PCPEDI.NUMSEQ%TYPE
   ,NEW_QTDE                 PCPEDI.QT%TYPE
   ,NEW_POSICAO              PCPEDC.POSICAO%TYPE
   ,NEW_CONDVENDA            PCPEDC.CONDVENDA%TYPE
   -- Valores Anteriores
   ,OLD_IDENTIFICADOR        PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
   ,OLD_CODFILIAL            PCPEDC.CODFILIAL%TYPE
   ,OLD_CODPROD              PCPEDI.CODPROD%TYPE
   ,OLD_NUMLOTE              PCLOTE.NUMLOTE%TYPE
   ,OLD_CODDEPOSITO          PCPEDI.CODDEPOSITO%TYPE
   ,OLD_NUMSEQ               PCPEDI.NUMSEQ%TYPE
   ,OLD_QTDE                 PCPEDI.QT%TYPE
   ,OLD_POSICAO              PCPEDC.POSICAO%TYPE
   ,OLD_CONDVENDA            PCPEDC.CONDVENDA%TYPE);

  /**********************************************************************************************/
  /* Type para consulta de lote*/
  /**********************************************************************************************/
  TYPE TB_DADOS_OP     IS TABLE OF TYPE_DADOS_PEDIDO;
  TYPE TB_DADOS_PEDIDO IS TABLE OF TYPE_DADOS_PEDIDO;
  TYPE TB_DADOS_MOV    IS TABLE OF TYPE_DADOS_MOV;
  TYPE TB_ESTOQUE      IS TABLE OF T_ESTOQUE;
  TYPE T_NUMBONUS      IS TABLE OF PCBONUSI.NUMBONUS%TYPE INDEX BY PLS_INTEGER;

  /**********************************************************************************************
                                       FUNÇÕES/PROCEDURES
  ----------------------------------------------------------------------------------------------*/
  /**********************************************************************************************/
  /* Função padrão para administrar o estoque (processo de refatoração da PKG_ESTOQUE)*/
  /**********************************************************************************************/
  FUNCTION ADMINISTRAR_ESTOQUE (p_ENTRADA IN OUT T_ENTRADA)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Função padrão para consultar dados anteriores (processo de refatoração da PKG_ESTOQUE)*/
  /**********************************************************************************************/
  FUNCTION PRIV_CONS_OP_ANTERIORES (pnIDENTIFICADOR   IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
                                   ,pnCODPROD         IN PCPRODUT.CODPROD%TYPE)
  RETURN TB_DADOS_PEDIDO PIPELINED;

  /**********************************************************************************************/
  /* Função padrão para consultar dados anteriores (processo de refatoração da PKG_ESTOQUE)*/
  /**********************************************************************************************/
  FUNCTION PRIV_CONS_MOV_ANTERIORES (pnIDENTIFICADOR   IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
                                    ,pnNUMTRANSVENDA   IN PCMOV.NUMTRANSVENDA%TYPE
                                    ,pnNUMTRANSENT     IN PCMOV.NUMTRANSENT%TYPE
                                    ,pnCODPROD         IN PCMOV.CODPROD%TYPE
                                    ,pnNUMSEQ          IN PCMOV.NUMSEQ%TYPE
                                    ,psPROCESSO        IN VARCHAR2)
  RETURN TB_DADOS_MOV PIPELINED;

  /**********************************************************************************************/
  /* Função padrão para consultar dados anteriores (processo de refatoração da PKG_ESTOQUE)*/
  /**********************************************************************************************/
  FUNCTION PRIV_CONS_PEDIDOS_ANTERIORES (pnIDENTIFICADOR   IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
                                        ,pnCODPROD         IN PCPEDI.CODPROD%TYPE
                                        ,pnNUMSEQ          IN PCPEDI.NUMSEQ%TYPE)
  RETURN TB_DADOS_PEDIDO PIPELINED;

  FUNCTION PRIV_COMPRAS_TERCEIRO (pnCODPROD       IN PCPRODUT.CODPROD%TYPE
                                  ,psECANCELAMENTO IN PCLOGPKG_ESTOQUE.CANCELAMENTO%TYPE
                                  ,pnNUMTRANSACAO  IN PCNFENT.NUMTRANSENT%TYPE
                                  ,pnCODFORNEC     IN PCFORNEC.CODFORNEC%TYPE
                                  ,psCNPJ          IN PCFILIAL.CGC%TYPE
                                  ,psCODFISCAL     IN PCMOV.CODFISCAL%TYPE
                                  ,pnQTDE          IN PCEST.QTEST%TYPE
                                  ,psCODFILIAL     IN PCFILIAL.CODIGO%TYPE
                                  ,psMSG_RETORNO   OUT VARCHAR2)
  RETURN NUMBER;

  /**********************************************************************************************/
  /* alterar estoque bloqueado por produto */
  /**********************************************************************************************/
  FUNCTION BLOQUEIO_ALTERAR (pnIDENTIFICADOR IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
                            ,pnCODPROD       IN PCMOV.CODPROD%TYPE
                            ,pnNUMSEQ        IN PCMOV.NUMSEQ%TYPE
                            ,psOPERACAO      IN PCLOGPKG_ESTOQUE.TIPO_OPERACAO%TYPE
                            ,pnTIPO_CONTAGEM IN NUMBER DEFAULT NULL
                            ,psMSG_RETORNO   OUT VARCHAR2
                            ,psCODFILIAL     IN PCMOV.CODFILIAL%TYPE DEFAULT NULL)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* alterar estoque bloquedo */
  /**********************************************************************************************/
  FUNCTION BLOQUEIO_ALTERAR_PEDIDO (pnIDENTIFICADOR IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
                                   ,psOPERACAO      IN PCLOGPKG_ESTOQUE.TIPO_OPERACAO%TYPE
                                   ,psMSG_RETORNO   OUT VARCHAR2)
  RETURN VARCHAR2;
  /**********************************************************************************************/
  /* Baixar estoque bloqueado por produto */
  /**********************************************************************************************/
  FUNCTION BLOQUEIO_BAIXAR (pnIDENTIFICADOR        IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
                           ,psCODFILIAL            IN PCMOV.CODFILIAL%TYPE
                           ,pnCODPROD              IN PCMOV.CODPROD%TYPE
                           ,pnNUMSEQ               IN PCMOV.NUMSEQ%TYPE
                           ,pnQTDE                 IN PCMOV.QT%TYPE
                           ,pnQTAVARIA             IN PCMOV.QTAVARIA%TYPE
                           ,psOPERACAO             IN PCLOGPKG_ESTOQUE.TIPO_OPERACAO%TYPE
                           ,psCODOPER              IN PCMOV.CODOPER%TYPE DEFAULT NULL
                           ,pnCODDEVOL             IN PCMOV.CODDEVOL%TYPE DEFAULT 0
                           ,psOBSERVACAO           IN VARCHAR2 DEFAULT NULL
                           ,psNUMLOTE              IN PCMOV.NUMLOTE%TYPE DEFAULT NULL
                           ,psMSG_RETORNO          OUT VARCHAR2
                           ,pnCODPRODPRINC         IN PCEST.CODPROD%TYPE DEFAULT NULL
                           ,psDESBLOQPRODFAMILIA   IN VARCHAR2 DEFAULT 'N'
                           ,pnNUMBONUS             IN T_NUMBONUS DEFAULT CAST(NULL AS T_NUMBONUS)
                           ,pnQTENTRADABONUS       IN PCBONUSI.QTENTRADA%TYPE DEFAULT 0
                           ,pnCODDEPOSITO          IN PCPEDI.CODDEPOSITO%TYPE DEFAULT NULL)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Baixar estoque bloqueado */
  /**********************************************************************************************/
  FUNCTION BLOQUEIO_BAIXAR_PEDIDO (pnIDENTIFICADOR IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
                                  ,psOPERACAO      IN PCLOGPKG_ESTOQUE.TIPO_OPERACAO%TYPE
                                  ,psCODOPER       IN PCMOV.CODOPER%TYPE DEFAULT NULL
                                  ,psMSG_RETORNO   OUT VARCHAR2)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Incluir quantidade bloqueada por produto */
  /**********************************************************************************************/
  FUNCTION BLOQUEIO_INCLUIR (pnIDENTIFICADOR IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
                            ,psCODFILIAL     IN PCMOV.CODFILIAL%TYPE
                            ,pnCODPROD       IN PCMOV.CODPROD%TYPE
                            ,pnNUMSEQ        IN PCMOV.NUMSEQ%TYPE
                            ,pnQTDE          IN PCMOV.QT%TYPE
                            ,pnQTAVARIA      IN PCMOV.QTAVARIA%TYPE
                            ,psOPERACAO      IN PCLOGPKG_ESTOQUE.TIPO_OPERACAO%TYPE
                            ,psCODOPER       IN PCMOV.CODOPER%TYPE DEFAULT NULL
                            ,pnCODDEVOL      IN PCMOV.CODDEVOL%TYPE DEFAULT 0
                            ,psOBSERVACAO    IN VARCHAR2 DEFAULT NULL
                            ,psNUMLOTE       IN PCMOV.NUMLOTE%TYPE DEFAULT NULL
                            ,psMSG_RETORNO   OUT VARCHAR2
                            ,pnCODDEPOSITO   IN PCMOV.CODDEPOSITO%TYPE DEFAULT NULL)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Bloqueio Estoque Lote */
  /**********************************************************************************************/
  FUNCTION BLOQUEIO_INCLUIR_LOTE (pnIDENTIFICADOR IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
                                 ,psCODFILIAL     IN PCMOV.CODFILIAL%TYPE
                                 ,pnCODPROD       IN PCMOV.CODPROD%TYPE
                                 ,psNUMLOTE       IN PCMOV.NUMLOTE%TYPE
                                 ,pnNUMSEQ        IN PCMOV.NUMSEQ%TYPE
                                 ,pnNUMDIAS       IN NUMBER
                                 ,pnQTDE          IN PCMOV.QT%TYPE
                                 ,pnQTAVARIA      IN PCMOV.QTAVARIA%TYPE
                                 ,psOPERACAO      IN PCLOGPKG_ESTOQUE.TIPO_OPERACAO%TYPE
                                 ,psCODOPER       IN PCMOV.CODOPER%TYPE DEFAULT NULL
                                 ,psMSG_RETORNO   OUT VARCHAR2)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Incluir quantidade bloqueada */
  /**********************************************************************************************/
  FUNCTION BLOQUEIO_INCLUIR_PEDIDO (pnIDENTIFICADOR IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
                                   ,psOPERACAO      IN PCLOGPKG_ESTOQUE.TIPO_OPERACAO%TYPE
                                   ,psCODOPER       IN PCMOV.CODOPER%TYPE DEFAULT NULL
                                   ,psMSG_RETORNO   OUT VARCHAR2)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Entrada de estoque */
  /**********************************************************************************************/
  FUNCTION COMPRAS_ENTRADA (pnNUMTRANSACAO  IN PCMOV.NUMTRANSENT%TYPE
                           ,psECANCELAMENTO IN PCLOGPKG_ESTOQUE.CANCELAMENTO%TYPE
                           ,psMSG_RETORNO   OUT VARCHAR2)
  RETURN NUMBER;

  /**********************************************************************************************/
  /* Compras entrada beneficiamento */
  /**********************************************************************************************/
  FUNCTION COMPRAS_ENTRADA_BENEFIC (pnNUMTRANSACAO    IN  PCMOV.NUMTRANSENT%TYPE
                                   ,psECANCELAMENTO   IN  PCLOGPKG_ESTOQUE.CANCELAMENTO%TYPE
                                   ,psMSG_RETORNO     OUT VARCHAR2)
  RETURN NUMBER;
  /**********************************************************************************************/
  /* Movimentacao de estoque (compras)*/
  /**********************************************************************************************/
  FUNCTION COMPRAS_MOVIMENTACAO (pnNUMTRANSENT     IN PCMOV.NUMTRANSENT%TYPE
                                ,pnNUMTRANSVENDA   IN PCMOV.NUMTRANSVENDA%TYPE
                                ,psECANCELAMENTO   IN PCLOGPKG_ESTOQUE.CANCELAMENTO%TYPE
                                ,psMSG_RETORNO     OUT VARCHAR2)
  RETURN NUMBER;

  /**********************************************************************************************/
  /* Movimentacao de estoque (compras)*/
  /**********************************************************************************************/
  FUNCTION COMPRAS_MOVIMENTACAO_PROD (pnNUMTRANSENT             IN PCMOV.NUMTRANSENT%TYPE
                                     ,pnNUMTRANSVENDA           IN PCMOV.NUMTRANSVENDA%TYPE
                                     ,pnCODPROD                 IN PCMOV.CODPROD%TYPE
                                     ,psAPENAS_QTEST_QTESTGER   IN VARCHAR2
                                     ,psECANCELAMENTO           IN PCLOGPKG_ESTOQUE.CANCELAMENTO%TYPE
                                     ,psMSG_RETORNO             OUT VARCHAR2)
  RETURN NUMBER;
  /**********************************************************************************************/
  /* Saída de estoque */
  /**********************************************************************************************/
  FUNCTION COMPRAS_SAIDA (pnNUMTRANSACAO  IN PCMOV.NUMTRANSVENDA%TYPE
                         ,psECANCELAMENTO IN PCLOGPKG_ESTOQUE.CANCELAMENTO%TYPE
                         ,psMSG_RETORNO   OUT VARCHAR2)
  RETURN NUMBER;
  /**********************************************************************************************/
  /* Compras saida beneficiamento */
  /**********************************************************************************************/
  FUNCTION COMPRAS_SAIDA_BENEFIC (pnNUMTRANSACAO    IN  PCMOV.NUMTRANSVENDA%TYPE
                                 ,psECANCELAMENTO   IN  PCLOGPKG_ESTOQUE.CANCELAMENTO%TYPE
                                 ,psMSG_RETORNO     OUT VARCHAR2)
  RETURN NUMBER;

  /**********************************************************************************************/
  /* Popular Tabela de Estoque de Produto por Depósito
  /**********************************************************************************************/
  PROCEDURE DEPOSITO_POPULAR_ESTOQUE (psCODFILIAL     IN PCESTOQUEDEPOSITOPROD.CODFILIAL%TYPE
                                     ,pnCODFUNCLANC   IN PCESTOQUEDEPOSITOPROD.CODFUNCLANC%TYPE
                                     ,pbCOMMIT        IN BOOLEAN
                                     ,psMSG_RETORNO   OUT VARCHAR2
                                     ,pnCODPROD       IN NUMBER DEFAULT 0);

  /**********************************************************************************************
  /* Transferir o estoque de um depósito para outro
  /**********************************************************************************************/
  PROCEDURE DEPOSITO_TRANSFERENCIA (pnCODREQUISICAO     IN NUMBER
                                   ,psMSG_RETORNO       OUT VARCHAR2);

  /**********************************************************************************************/
  /* Validar estoque disponível para o produto */
  /**********************************************************************************************/
  FUNCTION ESTOQUE_DISPONIVEL (pnCODPROD      IN PCPEDI.CODPROD%TYPE
                              ,psCODFILIAL    IN PCPEDC.CODFILIAL%TYPE
                              ,psPROCESSO     IN VARCHAR2
                              ,pdDATA         IN PCHISTEST.DATA%TYPE DEFAULT NULL
                              ,pCOMGREATEST   IN VARCHAR2 DEFAULT 'S'
                              ,pnQTDE_REDUZIR IN PCPEDI.QT%TYPE DEFAULT 0)
  RETURN NUMBER;

  /**********************************************************************************************/
  /* Validar estoque disponível bloqueado para o produto */
  /**********************************************************************************************/
  FUNCTION ESTOQUE_DISPONIVEL_BLOQUEADO (pnCODPROD    IN PCPEDI.CODPROD%TYPE
                                        ,psCODFILIAL  IN PCPEDC.CODFILIAL%TYPE)
  RETURN NUMBER;

  /**********************************************************************************************/
  /* Validar estoque disponível bloqueado no deposito para o produto */
  /**********************************************************************************************/
  FUNCTION ESTOQUE_DISPONIVEL_DEP_BLOQ (pnCODPROD     IN PCPEDI.CODPROD%TYPE
                                            ,psCODFILIAL   IN PCPEDC.CODFILIAL%TYPE
                                            ,psCODDEPOSITO IN PCESTOQUEDEPOSITO.CODDEPOSITO%TYPE)
  RETURN NUMBER;

  /**********************************************************************************************/
  /* Validar estoque disponível bloqueado no lote para o produto */
  /**********************************************************************************************/
  FUNCTION ESTOQUE_DISPONIVEL_LOTE_BLOQ (pnCODPROD     IN PCPEDI.CODPROD%TYPE
                                         ,psCODFILIAL   IN PCPEDC.CODFILIAL%TYPE
                                         ,psNUMLOTE     IN PCLOTE.NUMLOTE%TYPE)
  RETURN NUMBER;

  /**********************************************************************************************/
  /* Validar estoque disponível da cesta básica */
  /**********************************************************************************************/
  FUNCTION ESTOQUE_DISPONIVEL_CB (pnCODPROD   IN NUMBER DEFAULT 0
                                 ,psCODFILIAL IN VARCHAR2 DEFAULT '99')
  RETURN TB_ESTOQUE
  PIPELINED;

  /**********************************************************************************************/
  /* Validar estoque disponível por filial retira */
  /**********************************************************************************************/
  FUNCTION ESTOQUE_DISPONIVEL_RETIRA (pnCODPROD     IN PCPEDI.CODPROD%TYPE     DEFAULT 0
                                     ,psCODAUXILIAR IN PCPEDI.CODAUXILIAR%TYPE DEFAULT 0
                                     ,psCODFILIAL   IN PCPEDC.CODFILIAL%TYPE   DEFAULT '99')
  RETURN TB_ESTOQUE
  PARALLEL_ENABLE
  PIPELINED;

  /**********************************************************************************************
  /* Verifica estoque disponivel do depoisto
  /**********************************************************************************************/
  FUNCTION ESTOQUE_DISPONIVEL_DEPOSITO (pnCODPROD     IN PCESTOQUEDEPOSITOPROD.CODPROD%TYPE
                                       ,psCODFILIAL   IN PCESTOQUEDEPOSITOPROD.CODFILIAL%TYPE
                                       ,pnCODDEPOSITO IN PCESTOQUEDEPOSITOPROD.CODDEPOSITO%TYPE
                                       ,psPROCESSO    IN VARCHAR2 DEFAULT NULL)
  RETURN NUMBER;

  /**********************************************************************************************/
  /* Validar estoque disponível para o LOTE */
  /**********************************************************************************************/
  FUNCTION ESTOQUE_DISPONIVEL_LOTE (psCODFILIAL   IN PCPEDC.CODFILIAL%TYPE
                                   ,pnCODPROD     IN PCPEDI.CODPROD%TYPE
                                   ,psNUMLOTE     IN PCMOV.NUMLOTE%TYPE
                                   ,psPROCESSO    IN VARCHAR2 DEFAULT 'I'
                                   ,pdDATA        IN PCHISTESTLOTE.DATA%TYPE DEFAULT NULL)
  RETURN NUMBER;

  /**********************************************************************************************/
  /* Incluir quantidade frente de loja */
  /**********************************************************************************************/
  FUNCTION FRENTELOJA_ATUALIZAR_PCEST (psCODFILIAL     IN PCPEDC.CODFILIAL%TYPE
                                      ,pnCODPROD       IN PCPEDI.CODPROD%TYPE
                                      ,pnQTDE          IN PCPEDI.QT%TYPE
                                      ,psOPERACAO      IN PCLOGPKG_ESTOQUE.TIPO_OPERACAO%TYPE
                                      ,psMSG_RETORNO   OUT VARCHAR2
                                      ,pnIDENTIFICADOR IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE DEFAULT NULL)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Incluir quantidade frente de loja */
  /**********************************************************************************************/
  FUNCTION INDUSTRIA_DEVOLUCAO_AVULSA (pnNUMTRANSAVULSA IN PCOPC.NUMOP%TYPE
                                      ,pnNUMOP          IN PCOPC.NUMOP%TYPE
                                      ,psCODFILIAL      IN PCFILIAL.CODIGO%TYPE
                                      ,psOPERACAO       IN PCLOGPKG_ESTOQUE.TIPO_OPERACAO%TYPE
                                      ,PSCANCELAMENTO   IN PCLOGPKG_ESTOQUE.CANCELAMENTO%TYPE
                                      ,psMSG_RETORNO  OUT VARCHAR2)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Incluir Quantidade Industria (QTINDUSTRIA)*/
  /**********************************************************************************************/
  FUNCTION INDUSTRIA_DESBLOQUEAR (pnNUMREMESSA     IN PCREMESSAPRODUCAO.NUMREMESSA%TYPE
                                 ,PSCANCELAMENTO   IN PCLOGPKG_ESTOQUE.CANCELAMENTO%TYPE
                                 ,psMSG_RETORNO  OUT VARCHAR2)

  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Movimentacao de estoque de entrada (Logistica)*/
  /**********************************************************************************************/
  FUNCTION LOGISTICA_ENTRADA (pnNUMTRANSACAO  IN PCMOV.NUMTRANSVENDA%TYPE
                             ,psECANCELAMENTO IN PCLOGPKG_ESTOQUE.CANCELAMENTO%TYPE
                             ,psMSG_RETORNO   OUT VARCHAR2)
  RETURN NUMBER;

  /**********************************************************************************************/
  /* Movimentacao de estoque de entrada (Logistica)*/
  /**********************************************************************************************/
  FUNCTION LOGISTICA_ENTRADA_PROD (pnNUMTRANSACAO  IN PCMOV.NUMTRANSVENDA%TYPE
                                  ,pnCODPROD       IN PCMOV.CODPROD%TYPE
                                  ,psECANCELAMENTO IN PCLOGPKG_ESTOQUE.CANCELAMENTO%TYPE
                                  ,psMSG_RETORNO   OUT VARCHAR2)
  RETURN NUMBER;

  /**********************************************************************************************/
  /* Movimentacao de estoque de saída (Logistica)*/
  /**********************************************************************************************/
  FUNCTION LOGISTICA_SAIDA (pnNUMTRANSACAO  IN PCMOV.NUMTRANSVENDA%TYPE
                           ,psECANCELAMENTO IN PCLOGPKG_ESTOQUE.CANCELAMENTO%TYPE
                           ,psMSG_RETORNO   OUT VARCHAR2)
  RETURN NUMBER;

  /**********************************************************************************************/
  /* Movimentacao de estoque de saída (Logistica)*/
  /**********************************************************************************************/
  FUNCTION LOGISTICA_SAIDA_PROD (pnNUMTRANSACAO  IN PCMOV.NUMTRANSVENDA%TYPE
                                ,pnCODPROD       IN PCMOV.CODPROD%TYPE
                                ,psECANCELAMENTO IN PCLOGPKG_ESTOQUE.CANCELAMENTO%TYPE
                                ,psMSG_RETORNO   OUT VARCHAR2)
  RETURN NUMBER;

  /**********************************************************************************************/
  /* Movimentacao de estoque (Beneficiamento Entrada) */
  /**********************************************************************************************/
  FUNCTION MOVIMENTACAO_BENEFIC_ENTRADA (pnNUMTRANSENT    IN PCMOV.NUMTRANSENT%TYPE
                                        ,psECANCELAMENTO  IN PCLOGPKG_ESTOQUE.CANCELAMENTO%TYPE)
  RETURN NUMBER;

  /**********************************************************************************************/
  /* Movimentacao de estoque (beneficiamento saida) */
  /**********************************************************************************************/
  FUNCTION MOVIMENTACAO_BENEFIC_SAIDA (pnNUMTRANSVENDA  IN PCMOV.NUMTRANSVENDA%TYPE
                                      ,psECANCELAMENTO  IN PCLOGPKG_ESTOQUE.CANCELAMENTO%TYPE)
  RETURN NUMBER;

  /**********************************************************************************************/
  /* Movimentacao de estoque (beneficiamento) */
  /**********************************************************************************************/
  FUNCTION MOVIMENTACAO_BENEFICIAMENTO (pnNUMTRANSENT    IN PCMOV.NUMTRANSENT%TYPE
                                       ,pnNUMTRANSVENDA  IN PCMOV.NUMTRANSVENDA%TYPE
                                       ,psECANCELAMENTO  IN PCLOGPKG_ESTOQUE.CANCELAMENTO%TYPE)
  RETURN NUMBER;

  /**********************************************************************************************/
  /* Verificar a origem da transferencia
  /**********************************************************************************************/
  FUNCTION ORIGEM_TRANSFERENCIA (pnNUMTRANSTRANSF IN PCMOV.NUMTRANSVENDA%TYPE)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Incluir o estoque pedente  */
  /**********************************************************************************************/
  FUNCTION PENDENTE_INCLUIR (pnIDENTIFICADOR   IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
                            ,pnCODPROD         IN PCPEDI.CODPROD%TYPE
                            ,pnNUMSEQ          IN PCPEDI.NUMSEQ%TYPE
                            ,pbPEDIDO          IN BOOLEAN
                            ,psOPERACAO        IN PCLOGPKG_ESTOQUE.TIPO_OPERACAO%TYPE
                            ,psMSG_RETORNO   OUT VARCHAR2)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Baixar o estoque pendente */
  /**********************************************************************************************/
  FUNCTION PENDENTE_BAIXAR (pnIDENTIFICADOR   IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
                           ,pnCODPROD         IN PCPEDI.CODPROD%TYPE
                           ,pnNUMSEQ          IN PCPEDI.NUMSEQ%TYPE
                           ,psOPERACAO        IN PCLOGPKG_ESTOQUE.TIPO_OPERACAO%TYPE
                           ,psMSG_RETORNO     OUT VARCHAR2)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Alterar o estoque pendente */
  /**********************************************************************************************/
  FUNCTION PENDENTE_ALTERAR (pnIDENTIFICADOR    IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
                            ,pnCODPROD          IN PCPEDI.CODPROD%TYPE
                            ,pnNUMSEQ           IN PCPEDI.NUMSEQ%TYPE
                            ,psOPERACAO         IN PCLOGPKG_ESTOQUE.TIPO_OPERACAO%TYPE
                            ,psMSG_RETORNO      OUT VARCHAR2)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Incluir o estoque do pedido como pendente */
  /**********************************************************************************************/
  FUNCTION PENDENTE_INCLUIR_PEDIDO (pnIDENTIFICADOR     IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
                                   ,psOPERACAO          IN PCLOGPKG_ESTOQUE.TIPO_OPERACAO%TYPE
                                   ,psMSG_RETORNO       OUT VARCHAR2)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Baixar o estoque do pedido como pendente */
  /**********************************************************************************************/
  FUNCTION PENDENTE_BAIXAR_PEDIDO (pnIDENTIFICADOR   IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
                                  ,psOPERACAO        IN PCLOGPKG_ESTOQUE.TIPO_OPERACAO%TYPE
                                  ,psMSG_RETORNO     OUT VARCHAR2)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Alterar o estoque do pedido que esta pendente */
  /**********************************************************************************************/
  FUNCTION PENDENTE_ALTERAR_PEDIDO (pnIDENTIFICADOR     IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
                                   ,psOPERACAO          IN PCLOGPKG_ESTOQUE.TIPO_OPERACAO%TYPE
                                   ,psMSG_RETORNO       OUT VARCHAR2)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Saber se pode faturar a venda gerada com retirada de depósito */
  /**********************************************************************************************/
  FUNCTION PODE_FATURAR (pnIDENTIFICADOR  IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Incluir reserva de estoque */
  /**********************************************************************************************/
  FUNCTION RESERVA_INCLUIR (pnIDENTIFICADOR  IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
                           ,pnCODPROD        IN PCPEDI.CODPROD%TYPE
                           ,pnNUMSEQ         IN PCPEDI.NUMSEQ%TYPE
                           ,pbPEDIDO         IN BOOLEAN
                           ,psOPERACAO       IN PCLOGPKG_ESTOQUE.TIPO_OPERACAO%TYPE
                           ,psMSG_RETORNO    OUT VARCHAR2
                           ,pnCODFUNC        IN PCEMPR.MATRICULA%TYPE DEFAULT 0)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Baixar reserva de estoque */
  /**********************************************************************************************/
  FUNCTION RESERVA_BAIXAR (pnIDENTIFICADOR  IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
                          ,pnCODPROD        IN PCPEDI.CODPROD%TYPE
                          ,pnNUMSEQ         IN PCPEDI.NUMSEQ%TYPE
                          ,psOPERACAO       IN PCLOGPKG_ESTOQUE.TIPO_OPERACAO%TYPE
                          ,psMSG_RETORNO    OUT VARCHAR2)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Alterar reservar de estoque da transação */
  /**********************************************************************************************/
  FUNCTION RESERVA_ALTERAR (pnIDENTIFICADOR  IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
                           ,pnCODPROD        IN PCPEDI.CODPROD%TYPE
                           ,pnNUMSEQ         IN PCPEDI.NUMSEQ%TYPE
                           ,psOPERACAO       IN PCLOGPKG_ESTOQUE.TIPO_OPERACAO%TYPE
                           ,psMSG_RETORNO    OUT VARCHAR2
                           ,pnCODFUNC        IN PCEMPR.MATRICULA%TYPE DEFAULT 0)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Incluir reservar de estoque do pedido */
  /**********************************************************************************************/
  FUNCTION RESERVA_INCLUIR_PEDIDO (pnIDENTIFICADOR  IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
                                  ,psOPERACAO       IN PCLOGPKG_ESTOQUE.TIPO_OPERACAO%TYPE
                                  ,psMSG_RETORNO    OUT VARCHAR2)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Baixar reservar de estoque do pedido */
  /**********************************************************************************************/
  FUNCTION RESERVA_BAIXAR_PEDIDO (pnIDENTIFICADOR  IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
                                 ,psOPERACAO       IN PCLOGPKG_ESTOQUE.TIPO_OPERACAO%TYPE
                                 ,psMSG_RETORNO    OUT VARCHAR2)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Alterar reservar de estoque do pedido */
  /**********************************************************************************************/
  FUNCTION RESERVA_ALTERAR_PEDIDO (pnIDENTIFICADOR  IN PCLOGPKG_ESTOQUE.IDENTIFICADOR%TYPE
                                  ,psOPERACAO       IN PCLOGPKG_ESTOQUE.TIPO_OPERACAO%TYPE
                                  ,psMSG_RETORNO    OUT VARCHAR2)
  RETURN VARCHAR2;

  /************************************************************************************************************************
  /* Valida filial que utiliza cfat*/
  /***********************************************************************************************************************/
  FUNCTION VALIDA_CODFILIAL_CEFAT( PNIDENTIFICADOR   IN PCPEDC.NUMPED%TYPE
                                  ,PNCODPROD         IN PCPEDI.CODPROD%TYPE
                                  ,PNNUMSEQ          IN PCPEDI.NUMSEQ%TYPE)
  RETURN VARCHAR2;

  /**********************************************************************************************/
  /* Saída de estoque */
  /**********************************************************************************************/
  FUNCTION VENDAS_SAIDA (pnNUMTRANSACAO  IN PCMOV.NUMTRANSVENDA%TYPE
                        ,psECANCELAMENTO IN PCLOGPKG_ESTOQUE.CANCELAMENTO%TYPE
                        ,psMSG_RETORNO   OUT VARCHAR2)
  RETURN NUMBER;

  /**********************************************************************************************/
  /* Entrada de estoque */
  /**********************************************************************************************/
  FUNCTION VENDAS_ENTRADA (pnNUMTRANSACAO  IN PCMOV.NUMTRANSENT%TYPE
                          ,psECANCELAMENTO IN PCLOGPKG_ESTOQUE.CANCELAMENTO%TYPE
                          ,psMSG_RETORNO   OUT VARCHAR2)
  RETURN NUMBER;

  /**********************************************************************************************/
  /* Saída de estoque */
  /**********************************************************************************************/
  FUNCTION VENDAS_SAIDA_PROD (pnNUMTRANSACAO     IN PCMOV.NUMTRANSVENDA%TYPE
                             ,pnCODPROD          IN PCMOV.CODPROD%TYPE
                             ,psECANCELAMENTO    IN PCLOGPKG_ESTOQUE.CANCELAMENTO%TYPE
                             ,psMSG_RETORNO      OUT VARCHAR2)
  RETURN NUMBER;

  /**********************************************************************************************/
  /* Entrada de estoque */
  /**********************************************************************************************/
  FUNCTION VENDAS_ENTRADA_PROD (pnNUMTRANSACAO            IN PCMOV.NUMTRANSENT%TYPE
                               ,pnCODPROD                 IN PCMOV.CODPROD%TYPE
                               ,psAPENAS_QTEST_QTESTGER   IN VARCHAR2
                               ,psECANCELAMENTO           IN PCLOGPKG_ESTOQUE.CANCELAMENTO%TYPE
                               ,psMSG_RETORNO             OUT VARCHAR2)
  RETURN NUMBER;

  /**********************************************************************************************/
  /* Movimentacao de estoque (Vendas)*/
  /**********************************************************************************************/
  FUNCTION VENDAS_MOVIMENTACAO (pnNUMTRANSENT   IN PCMOV.NUMTRANSENT%TYPE
                               ,pnNUMTRANSVENDA IN PCMOV.NUMTRANSVENDA%TYPE
                               ,psECANCELAMENTO IN PCLOGPKG_ESTOQUE.CANCELAMENTO%TYPE
                               ,psMSG_RETORNO   OUT VARCHAR2)
  RETURN NUMBER;
  /**********************************************************************************************/
  /* Versão atual da package */
  /**********************************************************************************************/
  FUNCTION VERSAO RETURN VARCHAR2;

END PKG_ESTOQUE;