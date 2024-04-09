CREATE OR REPLACE PACKAGE BODY PKG_REPOSICAOLOJAS
/*******************************************************************************
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
  Nome         : F_OBTER_PARAM_REPOSICAO_LOJAS
  Descricão    : Obter parâmetro de Reposição de Lojas
  ******************************************************************************/
  FUNCTION F_OBTER_PARAM_REPOSICAO_LOJAS(pi_vCodFilial    IN VARCHAR2,
                                         pi_vNome         IN VARCHAR2,
                                         pi_vValorDefault IN VARCHAR2)
  RETURN VARCHAR2 IS
    vvRetValorParam PCPARAMREPOSICAOLOJAS.VALOR%TYPE;
  BEGIN
    BEGIN
      SELECT NVL(VALOR,pi_vValorDefault)
        INTO vvRetValorParam
        FROM PCPARAMREPOSICAOLOJAS
       WHERE (NOME      = pi_vNome)
         AND (CODFILIAL = pi_vCodFilial);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvRetValorParam := pi_vValorDefault;
    END;
    RETURN vvRetValorParam;
  END F_OBTER_PARAM_REPOSICAO_LOJAS;

  ------------------------------------------------------------------------------
  -- Procedimento para Obter o Parâmetro da Filial STRING
  ------------------------------------------------------------------------------
  PROCEDURE POBTEM_PARAMFILIAL_STRING(pi_vCodFilial IN  VARCHAR2,
                                      pi_vNomeCampo IN  VARCHAR2,
                                      po_vValor     OUT VARCHAR2,
                                      po_vErro      OUT VARCHAR2,
                                      po_vMsgErro   OUT VARCHAR2) IS
  BEGIN
    -- Inicializa Retornos
    po_vValor   := NULL;
    po_vErro    := 'N';
    po_vMsgErro := NULL;

    -- Pesquisa Parametro
    BEGIN
      SELECT PCPARAMFILIAL.VALOR
        INTO po_vValor
        FROM PCPARAMFILIAL
       WHERE (PCPARAMFILIAL.CODFILIAL = pi_vCodFilial)
         AND (PCPARAMFILIAL.NOME      = pi_vNomeCampo);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        po_vErro    := 'S';
        po_vMsgErro := 'Não foi encontrado o parâmetro "' || pi_vNomeCampo || '" na filial ' || pi_vCodFilial;
        po_vValor   := NULL;
    END;

  END POBTEM_PARAMFILIAL_STRING;

  ------------------------------------------------------------------------------
  -- Função para obter o Fator de Conversão da Embalagem - DDVENDAS-37042
  ------------------------------------------------------------------------------
  FUNCTION F_OBTEM_QTUNIT_EMBALAGEM(pi_nCodAuxiliar           IN PCEMBALAGEM.CODAUXILIAR%TYPE,
                                    pi_vCodFilial             IN PCEMBALAGEM.CODFILIAL%TYPE,
                                    pi_vUSAQTUNITPCEMBREPLOJA IN VARCHAR2)
  RETURN NUMBER IS
    vnRetQtUnit PCEMBALAGEM.QTUNIT%TYPE;
  BEGIN

    vnRetQtUnit := 1;

    IF (pi_vUSAQTUNITPCEMBREPLOJA = 'S') THEN

      BEGIN
        SELECT QTUNIT
          INTO vnRetQtUnit
          FROM PCEMBALAGEM
         WHERE (CODAUXILIAR = pi_nCodAuxiliar)
           AND (CODFILIAL   = pi_vCodFilial);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnRetQtUnit := 1;
      END;

      IF (NVL(vnRetQtUnit,0) = 0) THEN
        vnRetQtUnit := 1;
      END IF;

    END IF;

    RETURN vnRetQtUnit;

  END F_OBTEM_QTUNIT_EMBALAGEM;

 /*****************************************************************************
  *****************************************************************************
  *****************************************************************************
  Nome         : PRC_PCMED_SUG_TRANSF_ATAC_VAR
  Descricão    : Gerar a Tabela Temporária com a Sugestão de Reposição
  #PROC1
  *****************************************************************************
  *****************************************************************************
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
                                          P_PEDIDOAVARIA          VARCHAR2)
  IS

    -- Declaração de Variáveis
    vSqlEstDestino      VARCHAR2(32000);
    vSqlEstTransito     VARCHAR2(32000);
    vSqlEstOperLog      VARCHAR2(32000);
    vSqlEstSugestao     VARCHAR2(32000);
    vSqlHistorico       VARCHAR2(32000);
    vdDataInicialVenda  DATE;
    vdDataFinalVenda    DATE;
  VSQL                varchar2(2000);
    -- REGRA ESPECÍFICA - Ignorar Produto Master (HIS.00011.2018)
    vIGNORARPRODMASTER2312 PCREGRASEXCECAOMED.VALOR%TYPE;
    -- REGRA ESPECÍFICA - Ignorar Qtde. Pedida (HIS.00005.2018)
    vIGNORARQTPEDIDA2312   PCREGRASEXCECAOMED.VALOR%TYPE;
    -- REGRA ESPECÍFICA - Quantidade de dias para analisar o estoque em trânsito
    nQTDEDIASESTOQUETRANSITO NUMBER;

    vUFDestino pcfilial.uf%type;
    vUFOrigem  pcfilial.uf%type;
    -- Tratamento de Erros - 4056.125049.2015
    vvMsgErroTratado    VARCHAR2(200);
    e_Tratado           EXCEPTION;
    vDESCSTFORAUFTRANSF               PCPARAMFILIAL.VALOR%TYPE;
          vvErroPesqParam1         VARCHAR2(1);
      vvMsgErroPesqParam1     VARCHAR2(2000);
    vVALIDARMULTIPLOVENDA PCCLIENT.VALIDARMULTIPLOVENDA%TYPE; 
    vMULTIPLOPRODUTO      PCPRODUT.MULTIPLO%TYPE;
   /******************************************************************************
    PROCEDIMENTO: PFORMULA_QT_SUGERIDA
    DESCRICAO...: Concatenar Formula de Cálculo da Quantidade Sugerida
    ******************************************************************************/
    PROCEDURE PFORMULA_QT_SUGERIDA(pio_vFormula IN OUT VARCHAR2,
                                   pi_vMensagem IN VARCHAR2)
    IS
    BEGIN
      IF (pio_vFormula IS NOT NULL) THEN
        pio_vFormula := pio_vFormula || CHR(13);
      END IF;
      pio_vFormula := pio_vFormula || pi_vMensagem;
    END;

   /******************************************************************************
    PROCEDIMENTO: F_OBTER_TIPO_ARREDONDAMENTO
    DESCRICAO...: Obter o Tipo de Arredondamento
    ******************************************************************************/
    FUNCTION FFORMULA_QT_SUGERIDA(pi_vUNIDADEMASTER_O           IN VARCHAR2,
                                  pi_vEMB_POR_FORNECEDOR_O      IN VARCHAR2,
                                  pi_vTIPO_SUGESTAO             IN VARCHAR2,
                                  pi_vORIGEMEMBALAGEMMASTERFORN IN VARCHAR2)
    RETURN VARCHAR2 IS
      vvRetorno VARCHAR2(255);
    BEGIN
      IF (NVL(pi_vTIPO_SUGESTAO,' ') = 'L') AND
         (NVL(pi_vUNIDADEMASTER_O,' ') = 'FA') AND
         (NVL(pi_vEMB_POR_FORNECEDOR_O,'N') <> 'S') THEN
        vvRetorno := 'CONVERSAO PARA FARDO';
      ELSE
        IF (NVL(pi_vTIPO_SUGESTAO,'L') = 'L') THEN
          IF (NVL(pi_vORIGEMEMBALAGEMMASTERFORN,'N') = '2') THEN
            vvRetorno := 'EMBALAGEM MASTER DO PRODUTO (COMPRA) - ROTINA 203';
          ELSE
            vvRetorno := 'EMBALAGEM MASTER DO PRODUTO NO FORNECEDOR - ROTINA 3602';
          END IF;
        ELSE
          vvRetorno := 'EMBALAGEM MASTER DO PRODUTO (COMPRA) - ROTINA 203';
        END IF;
      END IF;
      -- Retorno
      RETURN vvRetorno;
    END FFORMULA_QT_SUGERIDA;

   /******************************************************************************
    PROCEDIMENTO: PCALCULA_SUGESTAO
    DESCRICAO...: Calcula os valores da Sugestão a partir dos Produtos carregados
                  na Tabela Temporária
    ******************************************************************************/
    PROCEDURE PCALCULA_SUGESTAO(po_vMsgErroTratado OUT VARCHAR2) IS

      CURSOR CR_PRODUTOS IS
          SELECT NVL((SELECT PRIORIDADE
                        FROM PCFILIALPRIORIDADE
                       WHERE CODFILIAL = FO.CODIGO
                         AND CODFILIALDESTINO = ED.CODFILIAL_D),999) PRIORIDADE_D
               , FO.CODIGO CODFILIAL_O
               , PO.CODPROD CODPROD_O
               , PO.CODMARCA CODMARCA_O
               , MO.MARCA MARCA_O
               , PO.CODSUBCATEGORIA CODSUBCATEGORIA_O
               , PO.CODCATEGORIA CODCATEGORIA_O
               , PO.CODSEC CODSEC_O
               , PO.CODEPTO CODEPTO_O
               , PO.CODFORNEC CODFORNEC_O
               , PO.DESCRICAO DESCRICAO_O
               , PO.EMBALAGEM EMBALAGEM_O
               , PO.UNIDADE UNIDADE_O
               , PO.QTUNITCX QTUNITCX_O
               , NVL(TR.QTTRANSITO_O,0) QTTRANSITO_O
               , PO.MODULO MODULO_O
               , PO.RUA RUA_O
               , PO.NUMERO NUMERO_O
               , PO.APTO APTO_O
               , ED.CODFILIAL_D
               , ED.CODPROD_D
               , ED.CODMARCA_D
               , ED.MARCA_D
               , ED.CODCATEGORIA_D
               , ED.CODSEC_D
               , ED.CODEPTO_D
               , ED.CODFORNEC_D
               , ED.DESCRICAO_D
               , ED.EMBALAGEM_D
               , ED.UNIDADE_D
               , ED.QTUNITCX_D
               , ED.QTESTGER_D
               , ED.QTRESERV_D
               , ED.QTBLOQUEADA_D
               , ED.QTINDENIZ_D
               , ED.ESTOQUEMIN_D
               , ED.ESTOQUEMAX_D
               , ED.QTPEDIDA_D
               , ED.PERCARREDONDA_D
               , ED.CLASSE_D
               , ED.TIPOSUGESTAO_D
               , (CASE WHEN ED.TIPOSUGESTAO_D = 'F' THEN 'F - Faceamento' ELSE 'E - Estoque Mín/Máx' END) DESCTIPOSUGESTAO_D
               , ED.CUSTOULTENT_D
               , ED.PMC_D
               , ED.PVENDA_D
               , ED.QTVENDMES_D
               , ED.QTVENDMES1_D
               , ED.QTVENDMES2_D
               , ED.QTVENDMES3_D
               , ED.CODCLI_D
               , PO.CODFAB CODFAB_O
               , ED.CODFAB_D
               , PO.CODAUXILIAR CODAUXILIAR_O
               , ED.CODAUXILIAR_D
               , ED.QTGIRODIA_D
               , ED.QTPENDENTE_D
               , ED.ESTMIN_D
               , NVL(PO.PSICOTROPICO,'N') PSICOTROPICO
               , ED.ESTOQUEIDEAL_D
               , PO.UNIDADEMASTER UNIDADEMASTER_O
               , SG.QTSUGCOMPRA_D
               , PO.TIPOCUSTOTRANSF TIPOCUSTOTRANSF_O
               , OL.QTOPERLOG_O
               , ED.CODFILIALRETIRA_O
               , PO.ESTOQUEPORLOTE
            FROM PCMED_TEMP_ESTDESTINO ED
               , PCPRODUT PO
               , PCFILIAL FO
               , PCMARCA MO
               , PCMED_TEMP_ESTTRANSITO TR
               , PCMED_TEMP_ESTSUGESTAO SG
               , PCMED_TEMP_ESTOPERLOG OL
           WHERE PO.CODPROD     = ED.CODPROD_O
             AND FO.CODIGO      = ED.CODFILIAL_O
             AND PO.CODMARCA    = MO.CODMARCA(+)
             AND ED.CODPROD_O   = TR.CODPROD_O(+)
             AND ED.CODFILIAL_O = TR.CODFILIAL_O(+)
             AND ED.CODFILIAL_D = TR.CODFILIAL_D(+)
             AND ED.CODPROD_D   = SG.CODPROD_D(+)
             AND ED.CODFILIAL_D = SG.CODFILIAL_D(+)
             AND ED.CODFILIAL_O = OL.CODFILIAL_O(+)
             AND ED.CODPROD_O   = OL.CODPROD_O(+)
             AND ED.CODFILIAL_D = OL.CODFILIAL_D(+)
             AND PO.TIPOMERC   <> 'CB' -- DDMEDICA-6697
           ORDER BY 1; -->> CLASSIFICADO PELA PRIORIDADE

    -- CURSOR DE FORNECEDORES DA PRIORIDADE
    CURSOR c_FornecPrioridade(pi_vCodFilial IN VARCHAR2,
                              pi_nCodProd   IN NUMBER) IS
      SELECT PCPRODFORNREPOSICAO.CODFORNEC
           , PCPRODFORNREPOSICAO.INTEGRADORA
           , PCPRODFORNREPOSICAO.INTEGRADORAESPELHONF
        FROM PCPRODFORNREPOSICAO
       WHERE PCPRODFORNREPOSICAO.CODFILIAL = pi_vCodFilial
         AND PCPRODFORNREPOSICAO.CODPROD   = pi_nCodProd
       ORDER BY PCPRODFORNREPOSICAO.PRIORIDADE;

      -- FORNECEDOR DA PRIORIDADE E TIPO SUGESTAO COMPRA/TRANSFERENCIA
      N_CODFORNECPRIORIDADE         PCPRODFORNREPOSICAO.CODFORNEC%TYPE;
      V_DESC_FORNECPRIORIDADE       PCMED_TEMP_TRANSF_ATAC_VAR.DESC_FORNECPRIORIDADE%TYPE;
      V_CODDESC_FORNECPRIORIDADE    PCMED_TEMP_TRANSF_ATAC_VAR.CODDESC_FORNECPRIORIDADE%TYPE;
      V_TIPO_SUG_COMPRA_TRANSF      PCMED_TEMP_TRANSF_ATAC_VAR.TIPO_SUG_COMPRA_TRANSF%TYPE;
      V_DESC_TIPO_SUG_COMPRA_TRANSF PCMED_TEMP_TRANSF_ATAC_VAR.DESC_TIPO_SUG_COMPRA_TRANSF%TYPE;
      N_INTEGRADORA                 PCMED_TEMP_TRANSF_ATAC_VAR.INTEGRADORA%TYPE;
      V_NOMEINTEGRADORA             PCMED_TEMP_TRANSF_ATAC_VAR.NOMEINTEGRADORA%TYPE;
      N_INTEGRADORAESPELHONF        PCMED_TEMP_TRANSF_ATAC_VAR.INTEGRADORAESPELHONF%TYPE;
      V_NOMEINTEGRADORAESPELHONF    PCMED_TEMP_TRANSF_ATAC_VAR.NOMEINTEGRADORAESPELHONF%TYPE;
      -- CLIENTE
      V_CODCLI_D              PCCLIENT.CODCLI%TYPE;
      V_ESTENT_D              PCCLIENT.ESTENT%TYPE;
      N_CODPRACA_D            PCCLIENT.CODPRACA%TYPE;
      N_NUMREGIAO_D           PCPRACA.NUMREGIAO%TYPE;
      V_TIPOCUSTOTRANSF_D     PCCLIENT.TIPOCUSTOTRANSF%TYPE;
      N_NUMPR                 PCPLPAG.NUMPR%TYPE;
      N_NUMREGIAO             PCREGIAO.NUMREGIAO%TYPE;
      -- EQUIPE
      V_CODEQUIPE             PCESTEND.CODEQUIPE%TYPE;
      -- TRIBUTACAO
      V_TRIBUTACAO            VARCHAR2(1);
      V_CODST                 PCTABPR.CODST%TYPE;
      -- PCCONSUM
      V_UTILIZAENDPORFILIAL         VARCHAR2(2);
      V_USATRIBUTACAOPORUF          VARCHAR2(2);
      N_CON_NUMCASASDECCUSTO        NUMBER;
      -- ESPECIFICO DA 3602
      V_APLICARREDEMBFORNECREPLOJAS VARCHAR2(2);
      V_ORIGEMEMBALAGEMMASTERFORNEC VARCHAR2(2);
      V_RESPEITARESTOQUEMINORIGEM   VARCHAR2(2);
      -- 132
      V_BLOQUEIAVENDAESTPENDENTE    PCPARAMFILIAL.VALOR%TYPE;
      -- IDENTIFICAÇÃO DE ERROS AO PESQUISAR PARÂMETROS
      vvErroPesqParam         VARCHAR2(1);
      vvMsgErroPesqParam      VARCHAR2(2000);
      -- ESTOQUE DESTINO
      V_ESTQDISP              PCEST.QTESTGER%TYPE;
      V_ESTQDISPVALIDAMIN     PCEST.QTESTGER%TYPE;
      N_SUG_FRACIONADA_D      PCEST.QTESTGER%TYPE;
      N_QTD_SUGERIDA_D        PCMED_TEMP_TRANSF_ATAC_VAR.QTD_SUGERIDA_D%TYPE;
      V_QTD_EST_ORIG          PCEST.QTESTGER%TYPE;
      V_QTD_EST_DEST          PCEST.QTESTGER%TYPE;
      -- ESTOQUE BLOQUEADO DEDUZIDO DAS AVARIAS NA FILIAL DE DESTINO [Tarefa: 176264]
      v_QTBLOQSEMAVARIA_D     PCEST.QTBLOQUEADA%TYPE;
      -- DADOS DA FILIAL DE ORIGEM
      N_PRAZOENTREGA_O        PCFORNEC.PRAZOENTREGA%TYPE;
      -- FORMULA DA SUGESTAO UNITARIA
      V_FORMULA_QT_SUGERIDA_D VARCHAR2(4000);
      V_FORMULA               VARCHAR2(1);
      -- DADOS DA PCEST
      TYPE TT_INDICE_PROD     IS TABLE OF INTEGER INDEX BY BINARY_INTEGER;
      TYPE TT_CODPROD         IS TABLE OF PCEST.CODPROD%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_QTESTGER        IS TABLE OF PCEST.QTESTGER%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_QTRESERV        IS TABLE OF PCEST.QTRESERV%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_QTBLOQUEADA     IS TABLE OF PCEST.QTBLOQUEADA%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_QTINDENIZ       IS TABLE OF PCEST.QTINDENIZ%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_MODULO          IS TABLE OF PCEST.MODULO%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_RUA             IS TABLE OF PCEST.RUA%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_NUMERO          IS TABLE OF PCEST.NUMERO%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_APTO            IS TABLE OF PCEST.APTO%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_CUSTOREP        IS TABLE OF PCEST.CUSTOREP%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_CUSTOREAL       IS TABLE OF PCEST.CUSTOREAL%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_CUSTOCONT       IS TABLE OF PCEST.CUSTOCONT%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_CUSTOFIN        IS TABLE OF PCEST.CUSTOFIN%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_CUSTOULTENT     IS TABLE OF PCEST.CUSTOULTENT%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_VALORULTENT     IS TABLE OF PCEST.VALORULTENT%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_CUSTOREALSEMST    IS TABLE OF PCEST.CUSTOREALSEMST%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_VLULTENTCONTSEMST IS TABLE OF PCEST.VLULTENTCONTSEMST%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_CUSTOFORNEC       IS TABLE OF PCEST.CUSTOFORNEC%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_ESTMIN            IS TABLE OF PCEST.ESTMIN%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_QTPENDENTE        IS TABLE OF PCEST.QTPENDENTE%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_QTESTDISP         IS TABLE OF PCEST.QTESTGER%TYPE INDEX BY BINARY_INTEGER;
      Type TT_CUSTOFINSEMST     IS TABLE OF PCEST.CUSTOFINSEMST%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_VLICMSBCR         IS TABLE OF PCEST.VLICMSBCR%TYPE INDEX BY BINARY_INTEGER;
      --
      vtINDICE_PROD_O         TT_INDICE_PROD;
      vtCODPROD_O             TT_CODPROD;
      vtQTESTGER_O            TT_QTESTGER;
      vtQTRESERV_O            TT_QTRESERV;
      vtQTBLOQUEADA_O         TT_QTBLOQUEADA;
      vtQTINDENIZ_O           TT_QTINDENIZ;
      vtMODULO_O              TT_MODULO;
      vtRUA_O                 TT_RUA;
      vtNUMERO_O              TT_NUMERO;
      vtAPTO_O                TT_APTO;
      vtCUSTOREP_O            TT_CUSTOREP;
      vtCUSTOREAL_O           TT_CUSTOREAL;
      vtCUSTOCONT_O           TT_CUSTOCONT;
      vtCUSTOFIN_O            TT_CUSTOFIN;
      vtCUSTOFINSEMST_O       TT_CUSTOFINSEMST;
      vtCUSTOULTENT_O         TT_CUSTOULTENT;
      vtVALORULTENT_O         TT_VALORULTENT;
      vtCUSTOREALSEMST_O      TT_CUSTOREALSEMST;
      vtVLULTENTCONTSEMST_O   TT_VLULTENTCONTSEMST;
      vtCUSTOFORNEC_O         TT_CUSTOFORNEC;
      vtESTMIN_O              TT_ESTMIN;
      vtQTPENDENTE_O          TT_QTPENDENTE;
      vtQTESTDISP_O           TT_QTESTDISP;
      vtVLICMSBCR_O           TT_VLICMSBCR;
      --
      N_CODPROD_O             PCEST.CODPROD%TYPE;
      N_QTESTGER_O            PCEST.QTESTGER%TYPE;
      N_QTRESERV_O            PCEST.QTRESERV%TYPE;
      N_QTBLOQUEADA_O         PCEST.QTBLOQUEADA%TYPE;
      N_QTINDENIZ_O           PCEST.QTINDENIZ%TYPE;
      N_MODULO_O              PCEST.MODULO%TYPE;
      N_RUA_O                 PCEST.RUA%TYPE;
      N_NUMERO_O              PCEST.NUMERO%TYPE;
      N_APTO_O                PCEST.APTO%TYPE;
      N_CUSTOREP_O            PCEST.CUSTOREP%TYPE;
      N_CUSTOREAL_O           PCEST.CUSTOREAL%TYPE;
      N_CUSTOCONT_O           PCEST.CUSTOCONT%TYPE;
      N_CUSTOFIN_O            PCEST.CUSTOFIN%TYPE;
      N_CUSTOFINSEMST_O       PCEST.CUSTOFINSEMST%TYPE;
      N_CUSTOULTENT_O         PCEST.CUSTOULTENT%TYPE;
      N_VALORULTENT_O         PCEST.VALORULTENT%TYPE;
      N_CUSTOREALSEMST_O      PCEST.CUSTOREALSEMST%TYPE;
      N_VLULTENTCONTSEMST_O   PCEST.VLULTENTCONTSEMST%TYPE;
      N_CUSTOFORNEC_O         PCEST.CUSTOFORNEC%TYPE;
      N_ESTMIN_O              PCEST.ESTMIN%TYPE;
      N_QTPENDENTE_O          PCEST.QTPENDENTE%TYPE;
      N_QTESTDISP_O           PCEST.QTESTGER%TYPE;
      N_VLICMSBCR_O           PCEST.VLICMSBCR%TYPE;
      -- DADOS DA PCPRODFILIAL
      TYPE TT_INDICE_PROD_F   IS TABLE OF INTEGER INDEX BY BINARY_INTEGER;
      TYPE TT_CODPROD_F       IS TABLE OF PCPRODFILIAL.CODPROD%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_PERCARREDONDA_F IS TABLE OF PCPRODFILIAL.PERCARREDONDA%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_ESTOQUEMIN_F    IS TABLE OF PCPRODFILIAL.ESTOQUEMIN%TYPE INDEX BY BINARY_INTEGER;
      --
      vtINDICE_PROD_F_O        TT_INDICE_PROD_F;
      vtCODPROD_F_O            TT_CODPROD_F;
      vtPERCARREDONDA_F_O      TT_PERCARREDONDA_F;
      vtESTOQUEMIN_F_O         TT_ESTOQUEMIN_F;
      --
      N_PERCARREDONDA_F_O      PCPRODFILIAL.PERCARREDONDA%TYPE;
      N_ESTOQUEMIN_F_O         PCPRODFILIAL.ESTOQUEMIN%TYPE;
      --
      TYPE TRecAgenda          IS RECORD(
           V_EXISTE_AGENDA     VARCHAR2(1),
           V_SEGUNDA           PCAGENDAREPOSICAO.SEGUNDA%TYPE,
           V_TERCA             PCAGENDAREPOSICAO.TERCA%TYPE,
           V_QUARTA            PCAGENDAREPOSICAO.QUARTA%TYPE,
           V_QUINTA            PCAGENDAREPOSICAO.QUINTA%TYPE,
           V_SEXTA             PCAGENDAREPOSICAO.SEXTA%TYPE,
           V_SABADO            PCAGENDAREPOSICAO.SABADO%TYPE,
           V_DOMINGO           PCAGENDAREPOSICAO.DOMINGO%TYPE);
      vrAGENDA                 TRecAgenda;
      B_AGENDA_VALIDA          BOOLEAN;
      --  ARRAY DE DADOS DO CLIENTE
      TYPE TRecCliente         IS RECORD(
           N_CODCLI_D          PCCLIENT.CODCLI%TYPE,
           N_CODPRACA_D        PCCLIENT.CODPRACA%TYPE,
           N_NUMREGIAO_D       PCPRACA.NUMREGIAO%TYPE,
           V_ESTENT_D          PCCLIENT.ESTENT%TYPE,
           V_TIPOCUSTOTRANSF_D PCCLIENT.TIPOCUSTOTRANSF%TYPE,
           N_NUMPR             PCPLPAG.NUMPR%TYPE,
           N_NUMREGIAO         PCREGIAO.NUMREGIAO%TYPE);
      TYPE TTvCliente         IS TABLE OF TRecCliente INDEX BY BINARY_INTEGER;
      vtCLIENTE_D             TTvCliente;
      -- QUEBRA
      V_QUEBRA1               PCMED_TEMP_TRANSF_ATAC_VAR.QUEBRA1%TYPE;
      V_QUEBRA2               PCMED_TEMP_TRANSF_ATAC_VAR.QUEBRA2%TYPE;
      V_QUEBRA3               PCMED_TEMP_TRANSF_ATAC_VAR.QUEBRA3%TYPE;
      V_QUEBRA4               PCMED_TEMP_TRANSF_ATAC_VAR.QUEBRA4%TYPE;
      V_QUEBRA_AGENDA_AUTOM   PCMED_TEMP_TRANSF_ATAC_VAR.QUEBRA3%TYPE;
      -- INFO DAS QUEBRAS
      V_INFOQUEBRAS           PCMED_TEMP_TRANSF_ATAC_VAR.INFOQUEBRAS%TYPE;
      -- OUTRAS VARIAVEIS
      I_CONTA_COMMIT          INTEGER;
      I_INDICE_PROD           INTEGER;
      I_INDICE_PROD_F         INTEGER;

      -- ARRAY DE DADOS POR FILIAL
      -- 4056.074463.2015 - Não pode usar Array, Filiais com Letra no código.
      --TYPE TRecDadosFilial             IS RECORD(
      --     V_CONSIDERAESTPENDSUGCOMPRA PCFILIAL.CONSIDERAESTPENDSUGCOMPRA%TYPE);
      --TYPE TTvDadosFilial              IS TABLE OF TRecDadosFilial INDEX BY BINARY_INTEGER;
      --vtDADOS_FILIAL_D                 TTvDadosFilial;
      --

      -- DADOS POR FILIAL
      V_CONSIDERAESTPENDSUG_D          PCFILIAL.CONSIDERAESTPENDSUGCOMPRA%TYPE;
      V_DESCCONSIDERAESTPENDSUG_D      PCMED_TEMP_TRANSF_ATAC_VAR.DESCCONSIDERAESTPENDSUG_D%TYPE;

      -- PRECO DA NOTA FISCAL DE TRANSFERENCIA
      N_PRECO_TRANSF_O                 PCMED_TEMP_TRANSF_ATAC_VAR.CUSTOULTENT_D%TYPE;
      N_PRECO_TRANSF_D                 PCMED_TEMP_TRANSF_ATAC_VAR.CUSTOULTENT_D%TYPE;

      -- OUTROS VALORES DE CALCULO DA SUGESTAO
      N_QTD_TRANSITO_D                 PCMED_TEMP_TRANSF_ATAC_VAR.QTD_TRANSITO_D%TYPE;
      N_PERCARREDONDA_D                PCMED_TEMP_TRANSF_ATAC_VAR.PERCARREDONDA_D%TYPE;
      N_QTUNITCX_D                     PCMED_TEMP_TRANSF_ATAC_VAR.QTUNITCX_D%TYPE;
      N_QTUNITCX_O                     PCMED_TEMP_TRANSF_ATAC_VAR.QTUNITCX_O%TYPE;
      N_QTD_TRANSFERIR_O               PCMED_TEMP_TRANSF_ATAC_VAR.QTD_TRANSFERIR_O%TYPE;
      N_PERCARREDONDA_O                PCMED_TEMP_TRANSF_ATAC_VAR.PERCARREDONDA_O%TYPE;
      N_CXFORNEC_TRANSFERIR_O          PCMED_TEMP_TRANSF_ATAC_VAR.CXFORNEC_TRANSFERIR_O%TYPE;
      N_QTDIASREP_D                    PCMED_TEMP_TRANSF_ATAC_VAR.QTDIASREP_D%TYPE;
      V_EMB_POR_FORNECEDOR_O           PCMED_TEMP_TRANSF_ATAC_VAR.EMB_POR_FORNECEDOR_O%TYPE;
      N_QTUNITCX_TRANSITO_D            PCMED_TEMP_TRANSF_ATAC_VAR.QTUNITCX_D%TYPE;
      V_CONTROLE_QUEBRA_EMB            VARCHAR2(1);
      N_QTUNITCX_OPERLOG_D             PCMED_TEMP_TRANSF_ATAC_VAR.QTUNITCX_D%TYPE;
      N_QTOPERLOG_D                    PCMED_TEMP_TRANSF_ATAC_VAR.QTOPERLOG_D%TYPE;
      N_CODAUXILIAR_PCEMB_O            PCMED_TEMP_TRANSF_ATAC_VAR.CODAUXILIAR_O%TYPE; -- EAN para Conversão PCEMBALAGEM
      N_EMB_UTILIZADA_CONVERSAO_FRN    NUMBER;

      -- QUANTIDADE CAIXAS INDUSTRIA
      N_QTD_CAIXAS_INDUSTRIA           PCPRODUT.QTUNITCX%TYPE;

      -- QUANTIDADE IMPORTADA
      N_QTIMPORT_D                     PCMED_TEMP_TRANSF_ATAC_VAR.QTIMPORT_D%TYPE;

      -- PRECO DE VENDA
      N_PVENDA_D                       PCMED_TEMP_TRANSF_ATAC_VAR.PVENDA_D%TYPE;

      -- Dados do Produto da Tabela de Preços
      TYPE TRecTabPreco                IS RECORD(
           N_PVENDA1                    PCTABPR.PVENDA1%TYPE,
           N_PVENDA2                    PCTABPR.PVENDA2%TYPE,
           N_PVENDA3                    PCTABPR.PVENDA3%TYPE,
           N_PVENDA4                    PCTABPR.PVENDA4%TYPE,
           N_PVENDA5                    PCTABPR.PVENDA5%TYPE,
           N_PVENDA6                    PCTABPR.PVENDA6%TYPE,
           N_PVENDA7                    PCTABPR.PVENDA7%TYPE,
           N_CODST                      PCTABPR.CODST%TYPE);
      vrTabPreco                        TRecTabPreco;

      -- DADOS PRODUTO ORIGEM E DESTINO
      V_DESCRICAO_O                     PCPRODUT.DESCRICAO%TYPE;
      V_CODFAB_O                        PCPRODUT.CODFAB%TYPE;
      N_CODPROD_D                       PCPRODUT.CODPROD%TYPE;
      V_DESCRICAO_D                     PCPRODUT.DESCRICAO%TYPE;
      V_CODFAB_D                        PCPRODUT.CODFAB%TYPE;

      -- DATA GERAÇÃO
      D_DTGERACAO                       DATE;

      -- TIPO DE CUSTO TRANSF A APLICAR
      V_TIPOCUSTOTRANSF_APLICAR         PCCLIENT.TIPOCUSTOTRANSF%TYPE;

      -- REGRA ESPECÍFICA - Utilizar Conversão PCEMBALAGEM
      vUSAQTUNITPCEMBREPLOJA            PCPARAMREPOSICAOLOJAS.VALOR%TYPE;

      -- DDMEDICA-4666 - Parâmetro da Reposição de Lojas para respeitar estoque mínimo da origem
      N_ESTOQUEMIN_O                    NUMBER;
      N_ESTOQUEMINSUG_O                 NUMBER;
      N_QTCANCESTOQUEMINSUG_O           NUMBER;

      -- Tratamento de Erros - 4056.125049.2015
      e_TratadoLocal                    EXCEPTION;

      -- Restrições
      V_RESTRICOES                      VARCHAR2(1);
      V_DESCONSIDPRODSEMCUSTOFIN        PCPARAMREPOSICAOLOJAS.VALOR%TYPE;
      V_DESCONSIDPRODSEMCUSTOREAL       PCPARAMREPOSICAOLOJAS.VALOR%TYPE;
      V_DESCONSIDPRODSEMTRIBUT          PCPARAMREPOSICAOLOJAS.VALOR%TYPE;

      -- Parâmetro se a Filial de Origem Utiliza Venda por Embalagem - DDMEDICA-5012
      vUTILIZAVENDAPOREMBALAGEM         PCPARAMFILIAL.VALOR%TYPE;

      -- Lote Fabricação - DDMEDICA-5077
      V_NUMLOTE                         PCLOTE.NUMLOTE%TYPE;

      -- Parâmetro de Arredondamento da Sugestão Fracionada - DDMEDICA-6815
      vARREDONDARSUGESTAOFRACIONADA     PCPARAMREPOSICAOLOJAS.VALOR%TYPE;

      -- Parâmetro para validação do multiplo da filial de destino - DDVENDAS-45056
      vAPLICARVALIDACAOMULTIPLO     PCPARAMREPOSICAOLOJAS.VALOR%TYPE;

      -- Array de Lotes - DDMEDICA-5077
      TYPE TRecLotes                    IS RECORD(
           vvSugestaoLote               VARCHAR2(1),
           vvNumLote                    PCLOTE.NUMLOTE%TYPE,
           vnQtIndeniz                  PCLOTE.QTINDENIZ%TYPE);
      TYPE TTvLotes                     IS TABLE OF TRecLotes INDEX BY BINARY_INTEGER;
      vtLotes                           TTvLotes;
      viIdxLote                         INTEGER;

      -- Qtde Avaria em Prefat - DDMEDICA-5077
      vnTotalAvariaPrefat               NUMBER;
    --  vDESCSTFORAUFTRANSF               PCPARAMFILIAL.VALOR%TYPE;

      ----------------------------------------------------------------------------]
      -- PROCEDIMENTO PARA OBTER OS DADOS DA AGENDA
      ---------------------------------------------
      PROCEDURE POBTER_DADOS_AGENDA(pi_vCODFILIAL_O    IN VARCHAR2,
                                    pi_vCODFILIAL_D    IN VARCHAR2,
                                    pi_vTIPOEVENTO     IN VARCHAR2,
                                    pi_vCODEVENTO      IN VARCHAR2,
                                    pio_vEXISTE_AGENDA IN OUT VARCHAR2,
                                    pio_vSEGUNDA       IN OUT VARCHAR2,
                                    pio_vTERCA         IN OUT VARCHAR2,
                                    pio_vQUARTA        IN OUT VARCHAR2,
                                    pio_vQUINTA        IN OUT VARCHAR2,
                                    pio_vSEXTA         IN OUT VARCHAR2,
                                    pio_vSABADO        IN OUT VARCHAR2,
                                    pio_vDOMINGO       IN OUT VARCHAR2) IS
      BEGIN
        -- Pesquisa Agenda
        BEGIN
          SELECT 'S'
               , SEGUNDA
               , TERCA
               , QUARTA
               , QUINTA
               , SEXTA
               , SABADO
               , DOMINGO
           INTO  pio_vEXISTE_AGENDA
               , pio_vSEGUNDA
               , pio_vTERCA
               , pio_vQUARTA
               , pio_vQUINTA
               , pio_vSEXTA
               , pio_vSABADO
               , pio_vDOMINGO
           FROM PCAGENDAREPOSICAO
          WHERE (CODCD      = pi_vCODFILIAL_O)
            AND (CODLOJA    = pi_vCODFILIAL_D)
            AND (TIPOEVENTO = pi_vTIPOEVENTO)
            AND (CODEVENTO  = pi_vCODEVENTO)
            AND (ROWNUM     = 1);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            pio_vEXISTE_AGENDA := 'N';
            pio_vSEGUNDA       := NULL;
            pio_vTERCA         := NULL;
            pio_vQUARTA        := NULL;
            pio_vQUINTA        := NULL;
            pio_vSEXTA         := NULL;
            pio_vSABADO        := NULL;
            pio_vDOMINGO       := NULL;
        END;
      END POBTER_DADOS_AGENDA;

      ------------------------------------------------------------------------------
      -- Procedimento para Obter o Parâmetro da Filial NUMBER
      ------------------------------------------------------------------------------
      PROCEDURE POBTEM_PARAMFILIAL_NUMBER(pi_vCodFilial IN  VARCHAR2,
                                          pi_vNomeCampo IN  VARCHAR2,
                                          po_nValor     OUT NUMBER,
                                          po_vErro      OUT VARCHAR2,
                                          po_vMsgErro   OUT VARCHAR2) IS

        vvValorString PCPARAMFILIAL.VALOR%TYPE;

      BEGIN
        -- Inicializa Retornos
        po_nValor   := 0;
        po_vErro    := 'N';
        po_vMsgErro := NULL;

        -- Pesquisa Parametro
        BEGIN
          SELECT PCPARAMFILIAL.VALOR
            INTO vvValorString
            FROM PCPARAMFILIAL
           WHERE (PCPARAMFILIAL.CODFILIAL = pi_vCodFilial)
             AND (PCPARAMFILIAL.NOME      = pi_vNomeCampo);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            po_vErro      := 'S';
            po_vMsgErro   := 'Não foi encontrado o parâmetro "' || pi_vNomeCampo || '" na filial ' || pi_vCodFilial;
            vvValorString := NULL;
        END;

        -- Se não ocorreu erro ao pesquisar o parâmetro
        IF (po_vErro = 'N') THEN

          -- Tira Espaços em Branco do Valor
          vvValorString := TRIM(vvValorString);
          IF (vvValorString IS NULL) THEN
            vvValorString := '0';
          END IF;

          -- Converte String para Number
          BEGIN
            po_nValor := TO_NUMBER(vvValorString);
          EXCEPTION
            WHEN OTHERS THEN
              po_vErro      := 'S';
              po_vMsgErro   := 'Erro ao converter em numérico o texto "' || vvValorString || '" do parâmetro "' || pi_vNomeCampo || '" na filial ' || pi_vCodFilial;
              po_nValor     := 0;
          END;

        END IF; -- Fim Condição Se não ocorreu erro ao pesquisar o parâmetro

      END POBTEM_PARAMFILIAL_NUMBER;

      -------------------------------------------------------------------------------
      -- Função para Retornar a Quantidade de Caixas conforme Regra de Arredondamento
      -------------------------------------------------------------------------------
      FUNCTION FOBTEM_QTDE_CAIXAS(pi_nSugestaoUnitaria          IN NUMBER,
                                  pi_nQtUnitCx                  IN NUMBER,
                                  pi_nPercArredonda             IN NUMBER,
                                  pi_vTipo                      IN VARCHAR2,
                                  pi_vARREDONDARSUGESTAOFRACION IN VARCHAR2) -- DDMEDICA-6815
      RETURN NUMBER IS

        vnRetQtCaixas PCEST.QTESTGER%TYPE;
        vnQtdeSobra   PCEST.QTESTGER%TYPE;

      BEGIN

        -- Se tem Quantidade de Unidades da Caixa
        IF (NVL(pi_nQtUnitCx,0) > 1) THEN

          PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'$ARREDONDAMENTO PELA EMBALAGEM MASTER - ' || pi_vTipo);
          PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. UNITARIA = ' || NVL(pi_nSugestaoUnitaria,0));
          PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. EMBALAGEM = ' || NVL(pi_nQtUnitCx,0));
          PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'% ARREDONDAMENTO EMB. = ' || NVL(pi_nPercArredonda,0));

          -- CALCULO DA QUANTIDADE DE VOLUMES PARA A SUGESTAO UNITARIA
          vnRetQtCaixas := TRUNC(NVL(pi_nSugestaoUnitaria,0) / NVL(pi_nQtUnitCx,0));
          PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. CAIXAS = ' || NVL(vnRetQtCaixas,0));
          vnQtdeSobra   := NVL(pi_nSugestaoUnitaria,0) - (NVL(vnRetQtCaixas,0) * NVL(pi_nQtUnitCx,0));
          PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. SOBRA UNITARIA = ' || NVL(vnQtdeSobra,0));
          -- SE REALIZA ARREDONDAMENTO PARA EMBALAGEM MASTER E SOBRA IGUAL OU SUPERIOR AO VALOR BASE DE ARREDONDAMENTO
          IF (NVL(pi_nPercArredonda,0) > 0) AND
             (NVL(vnQtdeSobra,0) >= (NVL(pi_nQtUnitCx,0) * (NVL(pi_nPercArredonda,0)/100))) THEN
            vnRetQtCaixas := vnRetQtCaixas + 1;
            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'ADICIONADA UMA CAIXA REF. SOBRA UNITARIA');
          ELSE
            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'SOBRA UNITARIA IGNORADA POR NAO ATINGIR O % ARREDONDAMENTO EMB.');
          END IF;
          -- NAO PERMITE SUGESTAO NEGATIVA
          IF (NVL(vnRetQtCaixas,0) < 0) THEN
            vnRetQtCaixas := 0;
          END IF;

        -- Se FRACIONADO - DDMEDICA-5477
        ELSIF (NVL(pi_nQtUnitCx,0) > 0)  AND
              (NVL(pi_nQtUnitCx,0) <= 1) THEN

          vnRetQtCaixas := pi_nSugestaoUnitaria;

        -- Se não tem Quantidade de Unidades da Caixa
        ELSE

          vnRetQtCaixas := 0;

        END IF;

        -- DDMEDICA-6815
        IF (pi_vARREDONDARSUGESTAOFRACION = 'S') THEN

          -- Se vai ter arredondamento
          IF (vnRetQtCaixas <> ROUND(vnRetQtCaixas,0)) THEN
            vnRetQtCaixas := ROUND(vnRetQtCaixas,0);

            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'$ARREDONDAMENTO CONF. PARAM. REPOSICAO "ARREDONDARSUGESTAOFRACIONADA"');
            IF (NVL(pi_nQtUnitCx,0) > 1) THEN
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. CAIXAS = ' || NVL(vnRetQtCaixas,0));
            ELSE
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. UNITARIA = ' || NVL(vnRetQtCaixas,0));
            END IF;
          END IF; -- Fim Condição: Se vai ter arredondamento

        END IF;

        -- Retorno da Função
        RETURN vnRetQtCaixas;

      END FOBTEM_QTDE_CAIXAS;

      ----------------------------------------------------------------------------
      -- Função para Retornar o Preço da Entrada
      ----------------------------------------------------------------------------
      FUNCTION FOBTEM_PRECO_ENTRADA(pi_vCodFilial    IN VARCHAR2,
                                    pi_nCodProd      IN NUMBER,
                                    pi_nValorDefault IN NUMBER)
      RETURN NUMBER IS
        vnRetPrecoEntrada NUMBER;
      BEGIN

        SELECT MAX(DECODE(PUNIT, 0, PUNITCONT, PUNIT)) AS PUNIT
          INTO vnRetPrecoEntrada
          FROM PCMOV
         WHERE (PCMOV.DTCANCEL IS NULL)
           AND (PCMOV.CODOPER LIKE 'E%')
           AND (NUMTRANSVENDA IS NULL)
           AND (PCMOV.CODPROD = pi_nCodProd)
           AND (PCMOV.CODFILIAL = pi_vCodFilial);

        IF ((NVL(vnRetPrecoEntrada,0) <= 0) AND
            (NVL(pi_nValorDefault,0)   > 0)) THEN
          vnRetPrecoEntrada := NVL(pi_nValorDefault,0);
        END IF;

        RETURN NVL(vnRetPrecoEntrada,0);

      END FOBTEM_PRECO_ENTRADA;

      ----------------------------------------------------------------------------
      -- Função para obter a Quebra Agrupada
      ----------------------------------------------------------------------------
      FUNCTION FOBTEM_QUEBRA_AGRUPADA(pi_vTipoEvento       IN VARCHAR2,
                                      pi_vDepto            IN VARCHAR2,
                                      pi_vSecao            IN VARCHAR2,
                                      pi_vCategoria        IN VARCHAR2,
                                      pi_vSubCategoria     IN VARCHAR2,
                                      pi_vTipoSugestao     IN VARCHAR2,
                                      pi_vAutomaticoManual IN VARCHAR2)
      RETURN VARCHAR2 IS
        vvRetQuebra              VARCHAR2(200);
        vvValorAgrup             VARCHAR2(200);
        vnIdSeq                  PCAGRUPAREPOSICAOLOJASCAB.IDSEQ%TYPE;
        TYPE TTListaAgrup        IS TABLE OF VARCHAR2(200) INDEX BY BINARY_INTEGER;
        vtListaAgrupTipoEvento   TTListaAgrup;
        vtListaAgrupCodigoEvento TTListaAgrup;
      BEGIN

        --
        -- Mecânica: Se quebra por departamento, verifica se existem agrupamentos por departamento, seção, categoria e subcategoria
        --           Se quebra por seção, verifica se existem agrupamentos por seção, categoria, subcategoria
        --           Se quebra por categoria, verifica se existem agrupamentos por categoria e subcategoria
        vtListaAgrupTipoEvento.DELETE;
        vtListaAgrupCodigoEvento.DELETE;
        IF     (pi_vTipoEvento = 'DE') THEN
          vtListaAgrupTipoEvento(1)   := 'SB';
          vtListaAgrupCodigoEvento(1) := pi_vSubCategoria;
          vtListaAgrupTipoEvento(2)   := 'CA';
          vtListaAgrupCodigoEvento(2) := pi_vCategoria;
          vtListaAgrupTipoEvento(3)   := 'SE';
          vtListaAgrupCodigoEvento(3) := pi_vSecao;
          vtListaAgrupTipoEvento(4)   := 'DE';
          vtListaAgrupCodigoEvento(4) := pi_vDepto;
        ELSIF  (pi_vTipoEvento = 'SE') THEN
          vtListaAgrupTipoEvento(1)   := 'SB';
          vtListaAgrupCodigoEvento(1) := pi_vSubCategoria;
          vtListaAgrupTipoEvento(2)   := 'CA';
          vtListaAgrupCodigoEvento(2) := pi_vCategoria;
          vtListaAgrupTipoEvento(3)   := 'SE';
          vtListaAgrupCodigoEvento(3) := pi_vSecao;
        ELSIF  (pi_vTipoEvento = 'CA') THEN
          vtListaAgrupTipoEvento(1)   := 'SB';
          vtListaAgrupCodigoEvento(1) := pi_vSubCategoria;
          vtListaAgrupTipoEvento(2)   := 'CA';
          vtListaAgrupCodigoEvento(2) := pi_vCategoria;
        END IF;

        -- Inicio Controle
        vvValorAgrup := NULL;

        -- Pesquisa o Código do Agrupamento para o Tipo Evento do menor nivel (SubCategoria) até o maior (Depto) conforme a quantidade de niveis inseridos no Array
        IF (vtListaAgrupTipoEvento.COUNT > 0) THEN
          FOR viIdxAgrup IN vtListaAgrupTipoEvento.FIRST..vtListaAgrupTipoEvento.LAST LOOP
            IF (vvValorAgrup IS NULL) THEN -- Enquanto não achou o Agrupamento

              BEGIN
                SELECT PCAGRUPAREPOSICAOLOJASCAB.IDSEQ
                   INTO vnIdSeq
                   FROM PCAGRUPAREPOSICAOLOJASCAB
                      , PCAGRUPAREPOSICAOLOJASDET
                  WHERE (PCAGRUPAREPOSICAOLOJASCAB.IDSEQ           = PCAGRUPAREPOSICAOLOJASDET.IDSEQ)
                    AND ((PCAGRUPAREPOSICAOLOJASCAB.TIPOFILIAL     = 'T') OR (PCAGRUPAREPOSICAOLOJASCAB.TIPOFILIAL = pi_vTipoSugestao))        -- Todos ou Loja/CD
                    AND ((PCAGRUPAREPOSICAOLOJASCAB.TIPOREPOSICAO  = 'T') OR (PCAGRUPAREPOSICAOLOJASCAB.TIPOREPOSICAO = pi_vAutomaticoManual)) -- Todos ou Automatico/Manual
                    AND (PCAGRUPAREPOSICAOLOJASCAB.TIPOEVENTO      = vtListaAgrupTipoEvento(viIdxAgrup))
                    AND (TRIM(PCAGRUPAREPOSICAOLOJASDET.CODEVENTO) = TRIM(vtListaAgrupCodigoEvento(viIdxAgrup)))
                    AND (ROWNUM = 1);
                -- Achou Agrupamento -> Atualiza Agrupamento = Tipo Evento + Código do Agrupamento encontrado
                vvValorAgrup := vtListaAgrupTipoEvento(viIdxAgrup) || '-' || NVL(vnIdSeq,0);
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  vnIdSeq := NULL;
              END;

            END IF; -- Fim Condição ainda não achou Agrupamento
          END LOOP;
        END IF;

        -- Se Achou Agrupamento
        IF (vvValorAgrup IS NOT NULL) THEN
          -- Agrupará pelo ID de Agrupamento
          vvRetQuebra := vvValorAgrup;
        -- Se não achou Agrupamento
        ELSE
          -- Agrupará pelo Código do Evento passado no Parâmetro (Depto ou Seção ou Categoria)
          IF     (pi_vTipoEvento = 'DE') THEN
            vvRetQuebra := pi_vDepto;
          ELSIF  (pi_vTipoEvento = 'SE') THEN
            vvRetQuebra := pi_vSecao;
          ELSIF  (pi_vTipoEvento = 'CA') THEN
            vvRetQuebra := pi_vCategoria;
          END IF;
        END IF;

        -- Retorno
        RETURN NVL(vvRetQuebra,'0');

      END FOBTEM_QUEBRA_AGRUPADA;

    ----------------
    --** INICIO **--
    ----------------
    BEGIN

      -- INICIALIZA MSG DE ERRO TRATADO
      po_vMsgErroTratado := NULL;

      -- DATA GERACAO
      D_DTGERACAO := SYSDATE;

      -- LIMPA TABELA TEMPORARIA
      EXECUTE IMMEDIATE 'TRUNCATE TABLE PCMED_TEMP_TRANSF_ATAC_VAR';

      I_CONTA_COMMIT := 0;

      /* SELECIONANDO OS PARÂMETROS DA PCCONSUM*/
      SELECT NVL(UTILIZAENDPORFILIAL,'N')
           , NVL(USATRIBUTACAOPORUF,'N')
        INTO V_UTILIZAENDPORFILIAL
           , V_USATRIBUTACAOPORUF
        FROM PCCONSUM;

      ----------------------------------------------------
      -- Parâmetro da Reposição de Lojas - MED-1896
      ----------------------------------------------------
      BEGIN
        SELECT VALOR
          INTO vUSAQTUNITPCEMBREPLOJA
          FROM PCPARAMREPOSICAOLOJAS
         WHERE (NOME      = 'USAQTUNITPCEMBREPLOJA')
           AND (CODFILIAL = '99');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vUSAQTUNITPCEMBREPLOJA := NULL;
      END;
      -- Parâmetro se a Filial de Origem Utiliza Venda por Embalagem - DDMEDICA-5012
      IF (vUSAQTUNITPCEMBREPLOJA = 'S') THEN
        POBTEM_PARAMFILIAL_STRING(P_CODFILIAL_ORIGEM,
                                  'FIL_UTILIZAVENDAPOREMBALAGEM',
                                  vUTILIZAVENDAPOREMBALAGEM,
                                  vvErroPesqParam,
                                  vvMsgErroPesqParam);
        IF (vUTILIZAVENDAPOREMBALAGEM IS NULL) THEN
          POBTEM_PARAMFILIAL_STRING('99',
                                    'CON_UTILIZAVENDAPOREMBALAGEM',
                                    vUTILIZAVENDAPOREMBALAGEM,
                                    vvErroPesqParam,
                                    vvMsgErroPesqParam);
        END IF;
        IF (NVL(vUTILIZAVENDAPOREMBALAGEM,'N') <> 'S') THEN
          vUSAQTUNITPCEMBREPLOJA := 'N';
        END IF;
      END IF;

      V_DESCONSIDPRODSEMCUSTOFIN  := F_OBTER_PARAM_REPOSICAO_LOJAS('99',
                                                                   'DESCONSIDPRODSEMCUSTOFIN',
                                                                   'N');
      V_DESCONSIDPRODSEMCUSTOREAL := F_OBTER_PARAM_REPOSICAO_LOJAS('99',
                                                                   'DESCONSIDPRODSEMCUSTOREAL',
                                                                   'N');
      V_DESCONSIDPRODSEMTRIBUT    := F_OBTER_PARAM_REPOSICAO_LOJAS('99',
                                                                   'DESCONSIDPRODSEMTRIBUT',
                                                                   'N');
      -- Desconsiderar ST do preço para transferências fora do estado
      POBTEM_PARAMFILIAL_STRING(P_CODFILIAL_ORIGEM,'DESCSTFORAUFTRANSF',
                                vDESCSTFORAUFTRANSF,vvErroPesqParam,
                                vvMsgErroPesqParam);

      -- PESQUISA DADOS DA FILIAL DE ORIGEM
      BEGIN
        SELECT PCFORNEC.PRAZOENTREGA
          INTO N_PRAZOENTREGA_O
          FROM PCFILIAL
             , PCFORNEC
         WHERE (PCFILIAL.CODFORNEC = PCFORNEC.CODFORNEC)
           AND (PCFILIAL.CODIGO    = P_CODFILIAL_ORIGEM);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          N_PRAZOENTREGA_O := 0;
      END;

    IF (P_CODFILIAL_DESTINO IS NOT NULL) THEN
      BEGIN
      vSQL := 'SELECT UF
         FROM PCFILIAL
         WHERE (PCFILIAL.CODIGO in ('||P_CODFILIAL_DESTINO||'))
         AND ROWNUM = 1';
      EXECUTE IMMEDIATE vSQL INTO vUFDestino;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vUFDestino := NULL;

      END;
      ELSE
    vUFDestino := NULL;
    END IF;

       BEGIN
       SELECT UF
       INTO  vUFORIGEM
       FROM PCFILIAL
       WHERE (PCFILIAL.CODIGO = P_CODFILIAL_ORIGEM);
       EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vUFORIGEM := NULL;
     END;

      -- Parâmetro de Número de Casas Decimais do Custo
      POBTEM_PARAMFILIAL_NUMBER('99',
                                'CON_NUMCASASDECCUSTO',
                                N_CON_NUMCASASDECCUSTO, --> Valor do Parâmetro
                                vvErroPesqParam,
                                vvMsgErroPesqParam);

      -- Parâmetro de Utilizar Arredondamento da Embalagem Master dos Produtos por Fornecedor
      BEGIN
        SELECT VALOR
          INTO V_APLICARREDEMBFORNECREPLOJAS
          FROM PCPARAMREPOSICAOLOJAS
         WHERE (NOME      = 'APLICARREDEMBFORNECREPLOJAS')
           AND (CODFILIAL = '99');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_APLICARREDEMBFORNECREPLOJAS := NULL;
      END;
      -- Parâmetro da Origem da Embalagem Master do Produto
      BEGIN
        SELECT VALOR
          INTO V_ORIGEMEMBALAGEMMASTERFORNEC
          FROM PCPARAMREPOSICAOLOJAS
         WHERE (NOME      = 'ORIGEMEMBALAGEMMASTERFORNEC')
           AND (CODFILIAL = '99');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_ORIGEMEMBALAGEMMASTERFORNEC := NULL;
      END;
      -- Parâmetro para respeitar o estoque na filial de origem - DDMEDICA-4666
      BEGIN
        SELECT VALOR
          INTO V_RESPEITARESTOQUEMINORIGEM
          FROM PCPARAMREPOSICAOLOJAS
         WHERE (NOME      = 'RESPEITARESTOQUEMINORIGEM')
           AND (CODFILIAL = '99');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_RESPEITARESTOQUEMINORIGEM := NULL;
      END;

      -- Bloqueio de Estoque Pendente
      POBTEM_PARAMFILIAL_STRING(NVL(P_CODFILIALRETIRA,P_CODFILIAL_ORIGEM),
                                'BLOQUEIAVENDAESTPENDENTE',
                                V_BLOQUEIAVENDAESTPENDENTE, --> Valor do Parâmetro
                                vvErroPesqParam,
                                vvMsgErroPesqParam);
      IF (V_BLOQUEIAVENDAESTPENDENTE IS NULL) THEN
        POBTEM_PARAMFILIAL_STRING('',
                                  'CON_BLOQUEIAVENDAESTPENDENTE',
                                  V_BLOQUEIAVENDAESTPENDENTE, --> Valor do Parâmetro
                                  vvErroPesqParam,
                                  vvMsgErroPesqParam);
      END IF;

      -- Parâmetro de Arredondamento da Sugestão Fracionada - DDMEDICA-6815
      vARREDONDARSUGESTAOFRACIONADA := F_OBTER_PARAM_REPOSICAO_LOJAS('99',
                                                                     'ARREDONDARSUGESTAOFRACIONADA',
                                                                     'N');

      -- Parâmetro de Arredondamento da Sugestão Fracionada - DDMEDICA-6815
      vAPLICARVALIDACAOMULTIPLO := F_OBTER_PARAM_REPOSICAO_LOJAS('99',
                                                                     'APLICARVALIDACAOMULTIPLO',
                                                                     'N');

      -- CARREGA DADOS DA PCEST NO ARRAY PARA OS PRODUTOS DE ORIGEM
      SELECT CODPROD
           , GREATEST(NVL(QTESTGER,0),0) QTESTGER
           , GREATEST(NVL(QTRESERV,0),0) QTRESERV
           , GREATEST(NVL(QTBLOQUEADA,0),0) QTBLOQUEADA
           , GREATEST(NVL(QTINDENIZ,0),0) QTINDENIZ
           , MODULO
           , RUA
           , NUMERO
           , APTO
           , NVL(CUSTOREP,0)
           , NVL(CUSTOREAL,0)
           , NVL(CUSTOCONT,0)
           , NVL(CUSTOFIN,0)
           , NVL(CUSTOFINSEMST,0)
           , NVL(CUSTOULTENT,0)
           , NVL(VALORULTENT,0)
           , NVL(CUSTOREALSEMST,0)
           , NVL(VLULTENTCONTSEMST,0)
           , NVL(CUSTOFORNEC,0)
           , NVL(ESTMIN,0)
           , NVL(QTPENDENTE,0)
           , CASE WHEN (NVL(V_BLOQUEIAVENDAESTPENDENTE,'N') = 'S') THEN
               GREATEST(GREATEST(NVL(QTESTGER,0),0) - GREATEST(NVL(QTRESERV,0),0) - GREATEST(NVL(QTBLOQUEADA,0),0) - GREATEST(NVL(QTPENDENTE,0),0),0)
             ELSE
               GREATEST(GREATEST(NVL(QTESTGER,0),0) - GREATEST(NVL(QTRESERV,0),0) - GREATEST(NVL(QTBLOQUEADA,0),0),0)
             END
            ,NVL(VLICMSBCR,0)
      BULK COLLECT INTO vtCODPROD_O
                      , vtQTESTGER_O
                      , vtQTRESERV_O
                      , vtQTBLOQUEADA_O
                      , vtQTINDENIZ_O
                      , vtMODULO_O
                      , vtRUA_O
                      , vtNUMERO_O
                      , vtAPTO_O
                      , vtCUSTOREP_O
                      , vtCUSTOREAL_O
                      , vtCUSTOCONT_O
                      , vtCUSTOFIN_O
                      , vtCUSTOFINSEMST_O
                      , vtCUSTOULTENT_O
                      , vtVALORULTENT_O
                      , vtCUSTOREALSEMST_O
                      , vtVLULTENTCONTSEMST_O
                      , vtCUSTOFORNEC_O
                      , vtESTMIN_O
                      , vtQTPENDENTE_O
                      , vtQTESTDISP_O
                      , vtVLICMSBCR_O
       FROM PCEST
      WHERE (CODFILIAL = NVL(P_CODFILIALRETIRA,P_CODFILIAL_ORIGEM)) -->> Priorizar Filial Retira
        AND (CODPROD   IN (SELECT CODPROD_O
                             FROM PCMED_TEMP_ESTDESTINO));
      -- CARREGA INDICES DOS ARRAYS
      -- E ARRAYS DE CONTROLE DE PREVISAO DE ESTOQUE DA ORIGEM
      IF (vtCODPROD_O.COUNT > 0) THEN
        FOR I_LACO IN vtCODPROD_O.FIRST..vtCODPROD_O.LAST LOOP
          -- INDICE
          vtINDICE_PROD_O(vtCODPROD_O(I_LACO)) := I_LACO;
        END LOOP;
      END IF;

      -- CARREGA DADOS DA PCPRODFILIAL NO ARRAY PARA OS PRODUTOS DE ORIGEM - DDMEDICA-4666
      SELECT CODPROD
           , NVL(PERCARREDONDA,0)
           , NVL(ESTOQUEMIN,0)
      BULK COLLECT INTO vtCODPROD_F_O
                      , vtPERCARREDONDA_F_O
                      , vtESTOQUEMIN_F_O
       FROM PCPRODFILIAL
      WHERE (CODFILIAL = NVL(P_CODFILIALRETIRA,P_CODFILIAL_ORIGEM)) -->> Priorizar Filial Retira
        AND (CODPROD   IN (SELECT CODPROD_O
                             FROM PCMED_TEMP_ESTDESTINO));
      -- CARREGA INDICES DOS ARRAYS
      -- E ARRAYS DE CONTROLE DE PRODUTO FILIAL DA ORIGEM
      IF (vtCODPROD_F_O.COUNT > 0) THEN
        FOR I_LACO IN vtCODPROD_F_O.FIRST..vtCODPROD_F_O.LAST LOOP
          -- INDICE
          vtINDICE_PROD_F_O(vtCODPROD_F_O(I_LACO)) := I_LACO;
        END LOOP;
      END IF;

     /**************************
      PROCESSAMENTO DOS PRODUTOS
      **************************/
      FOR PRODUTO IN CR_PRODUTOS
      LOOP
        -- DADOS PRODUTO ORIGEM E DESTINO
        -- ATENÇÃO: O PRODUTO ORIGEM PODERÁ SER IGUALADO AO PRODUTO DESTINO SE MODALIDADE DE COMPRA
        N_CODPROD_O            := PRODUTO.CODPROD_O;
        V_DESCRICAO_O          := PRODUTO.DESCRICAO_O;
        V_CODFAB_O             := PRODUTO.CODFAB_O;
        N_CODPROD_D            := PRODUTO.CODPROD_D;
        V_DESCRICAO_D          := PRODUTO.DESCRICAO_D;
        V_CODFAB_D             := PRODUTO.CODFAB_D;

        -- PEGA O PRECO DE VENDA DO PRODUTO DESTINO
        N_PVENDA_D             := PRODUTO.PVENDA_D;

        -- INICIALIZA A QUEBRA DA AGENDA AUTOMATICA (SEM QUEBRA)
        V_QUEBRA_AGENDA_AUTOM  := '0';
        -- INICIALIZA CONTROLE DE EMBALAGEM DIFERENCIADA POR FORNECEDOR E PRODUTO
        V_EMB_POR_FORNECEDOR_O := 'N';
        -- INICIALIZA CONTROLE DE QUEBRA DE PEDIDOS POR FRACIONADO E CAIXA FECHADA
        V_CONTROLE_QUEBRA_EMB  := 'C';

        -- CÓDIGO AUXILIAR para Conversão PCEMBALAGEM
        N_CODAUXILIAR_PCEMB_O  := NULL;

        -- INICIALIZA TEXTO DA FÓRMULA
        V_FORMULA_QT_SUGERIDA_D       := NULL;
        V_FORMULA                     := NULL;
        -- INICIALIZA A EMBALAGEM DO FORNECEDOR UTILIZADA NA CONVERSÃO
        N_EMB_UTILIZADA_CONVERSAO_FRN := 0;

        /*SELECIONANDO DADOS DA PCPRODFILIAL COM RELAÇÃO A ORIGEM - DDMEDICA-4666*/
        IF (vtINDICE_PROD_F_O.EXISTS(N_CODPROD_O)) THEN
          I_INDICE_PROD_F       := vtINDICE_PROD_F_O(N_CODPROD_O);
          N_PERCARREDONDA_F_O   := vtPERCARREDONDA_F_O(I_INDICE_PROD_F);
          N_ESTOQUEMIN_F_O      := vtESTOQUEMIN_F_O(I_INDICE_PROD_F);
        ELSE
          N_PERCARREDONDA_F_O   := 0;
          N_ESTOQUEMIN_F_O      := 0;
        END IF;

        -----------------------------------------------------------------------------
        -- DEFINE A MODALIDADE (TRANSFERENCIA OU COMPRA) E O FORNECEDOR DA PRIORIDADE
        -----------------------------------------------------------------------------
        -- SE FOR REPOSIÇÃO DE LOJAS
        IF (P_TIPO_SUGESTAO = 'L') THEN

          -- Pesquisa o Fornecedor da Prioridade para o Código de Produto de Origem
          N_CODFORNECPRIORIDADE      := 0;
          N_INTEGRADORA              := NULL; -->> Inicializa sem Operador Logístico
          V_NOMEINTEGRADORA          := NULL;
          N_INTEGRADORAESPELHONF     := NULL; -->> Inicializa sem Operador Logístico
          V_NOMEINTEGRADORAESPELHONF := NULL;
          FOR vc_FornecPrioridade IN c_FornecPrioridade(PRODUTO.CODFILIAL_D,    -->> Código da Filial de Destino (Varejo)
                                                        N_CODPROD_D) LOOP       -->> Código do Produto de Destino (Varejo)
            -- Fornecedor da Prioridade
            N_CODFORNECPRIORIDADE := NVL(vc_FornecPrioridade.CODFORNEC,0);
            -- Verifica se o Fornecedor está cadastrado como FILIAL
            BEGIN
              SELECT 'T'
                INTO V_TIPO_SUG_COMPRA_TRANSF
                FROM PCFILIAL
               WHERE (PCFILIAL.CODFORNEC = N_CODFORNECPRIORIDADE)
                 AND (ROWNUM             = 1);
              -->> Se encontrar o Fornecedor como Filial, HABILITA o Operador Logístico
              N_INTEGRADORA := NVL(vc_FornecPrioridade.INTEGRADORA,0);
              IF (N_INTEGRADORA > 0) THEN
                -- Sugestão de Pedido de Operador Logístico
                V_TIPO_SUG_COMPRA_TRANSF := 'L';
                -- Pesquisa Descrição da Integradora
                BEGIN
                  SELECT DESCRICAO
                    INTO V_NOMEINTEGRADORA
                    FROM PCINTEGRADORA
                   WHERE (INTEGRADORA = N_INTEGRADORA);
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    V_NOMEINTEGRADORA := NULL;
                END;
              END IF;
              -->> Integradora Espelho NF OL
              N_INTEGRADORAESPELHONF := NVL(vc_FornecPrioridade.INTEGRADORAESPELHONF,0);
              IF (N_INTEGRADORAESPELHONF > 0) THEN
                -- Pesquisa Descrição da Integradora
                BEGIN
                  SELECT DESCRICAO
                    INTO V_NOMEINTEGRADORAESPELHONF
                    FROM PCINTEGRADORA
                   WHERE (INTEGRADORA = N_INTEGRADORAESPELHONF);
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    V_NOMEINTEGRADORAESPELHONF := NULL;
                END;
              END IF;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- Se o Fornecedor não estiver cadastrado como Filial, será uma Compra
                V_TIPO_SUG_COMPRA_TRANSF := 'C';
            END;
            -- Sai após achar o primeiro fornecedor
            EXIT;
          END LOOP;
          -- Se não achou Fornecedor da Prioridade mantém como Transferência
          IF (NVL(N_CODFORNECPRIORIDADE,0) = 0) THEN
            -- Pega se o Código de Fornecedor para a Filial de Origem
            BEGIN
              SELECT CODFORNEC
                INTO N_CODFORNECPRIORIDADE
                FROM PCFILIAL
               WHERE (PCFILIAL.CODIGO = PRODUTO.CODFILIAL_O);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                NULL;
            END;
            V_TIPO_SUG_COMPRA_TRANSF := 'T';
          END IF;

          ----------------------------------------------------------
          -- IGUALA O PRODUTO ORIGEM COM O PRODUTO DESTINO SE COMPRA
          --      (NÃO TERÁ PRODUTO PAI NESTE TIPO DE OPERAÇÃO)
          ----------------------------------------------------------
          IF (V_TIPO_SUG_COMPRA_TRANSF = 'C') THEN
            N_CODPROD_O   := N_CODPROD_D;
            V_DESCRICAO_O := V_DESCRICAO_D;
            V_CODFAB_O    := V_CODFAB_D;
          END IF;

        -- SE FOR REPOSIÇÃO DE CD SEMPRE SERÁ TRANSFERÊNCIA
        ELSIF (P_TIPO_SUGESTAO = 'C') THEN

          -- Não tem Fornecedor da Prioridade
          N_CODFORNECPRIORIDADE      := 0;
          N_INTEGRADORA              := NULL; -->> Sem Operador Logístico
          V_NOMEINTEGRADORA          := NULL;
          N_INTEGRADORAESPELHONF     := NULL; -->> Sem Espelho NF Transferência OL
          V_NOMEINTEGRADORAESPELHONF := NULL;
          -- Mantém como Transferência
          V_TIPO_SUG_COMPRA_TRANSF := 'T';

        END IF; -- FIM CONDIÇÃO REPOSIÇÃO DE LOJAS OU CD

        --------------------------------------------------------------------------
        -- REDEFINIÇÃO DO PREÇO DE VENDA PELO PREÇO POR EMBALAGEM SE VAREJO
        --------------------------------------------------------------------------
        IF (P_TIPO_SUGESTAO = 'L') THEN

          /*SELECIONANDO DADOS DA PCEMBALAGEM COM RELAÇÃO AO DESTINO*/
          IF (NVL(vUSAQTUNITPCEMBREPLOJA,'N') <> 'S') THEN -->> SOMENTE se não Utilizar Conversão PCEMBALAGEM (Se Usa Conversão PCEMBALAGEM deve sempre apresentar o Preço da PCTABPR)
            BEGIN
              SELECT NVL(PVENDA,0)
                INTO N_PVENDA_D
                FROM PCEMBALAGEM
               WHERE (CODFILIAL = PRODUTO.CODFILIAL_D)
                 AND (CODPROD   = N_CODPROD_D)
                 AND (ROWNUM    = 1);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- Se não encontrar Preço na PCEMBALAGEM, ignora, mantendo o Preço de Venda por Região
                NULL;
            END;
          END IF;

        END IF; -- Fim Condição Redefinição Preço Venda pela PCEMBALAGEM

        --------------------------------------------------------------------------
        -- ARREDONDAMENTO NA REPOSIÇÃO DE LOJAS ----------------------------------
        --------------------------------------------------------------------------
        IF    (P_TIPO_SUGESTAO = 'L') THEN

          -- Quantidade de Unidade de Caixa do Produto Origem
          N_QTUNITCX_O      := NVL(PRODUTO.QTUNITCX_O,0);
          -- Reposição de Lojas não tem Arredondamento no Produto Origem
          -- (OBRIGATORIO DEIXAR NULO)
          N_PERCARREDONDA_O := NULL;

          -- Código Produto Origem = Código do Produto Destino
          IF (NVL(N_CODPROD_O,0) = NVL(N_CODPROD_D,0)) THEN
            -- Na Transferência de Produtos iguais, NÃO tem Conversão para Produto de Destino
            N_QTUNITCX_D := 1;
          -- Código Produto Origem <> Código do Produto Destino
          ELSE
            -- Na Transferência de Produtos Diferentes, tem Conversão para Produto de Destino
            N_QTUNITCX_D := NVL(PRODUTO.QTUNITCX_D,0);
          END IF;

          -- Para Cálculo do Fracionado do Transito em Caixa Fechada,
          -- é necessário utilizar os Códigos de Produtos Originais,
          -- sem a igualação dos Códigos quando da Modalidade de Compra
          IF (NVL(PRODUTO.CODPROD_O,0) = NVL(PRODUTO.CODPROD_D,0)) THEN
            -- Na Transferência de Produtos iguais, NÃO tem Conversão do Trânsito para Produto de Destino
            N_QTUNITCX_TRANSITO_D := 1;
            N_QTUNITCX_OPERLOG_D  := 1;
          -- Código Produto Origem <> Código do Produto Destino
          ELSE
            -- Na Transferência de Produtos Diferentes, tem Conversão do Trânsito para Produto de Destino
            N_QTUNITCX_TRANSITO_D := NVL(PRODUTO.QTUNITCX_D,0);
            N_QTUNITCX_OPERLOG_D  := NVL(PRODUTO.QTUNITCX_D,0);
          END IF;

          -- Percentual de Arredondamento do Produto Destino
          N_PERCARREDONDA_D := NVL(PRODUTO.PERCARREDONDA_D,0);

          -- REGRA ESPECÍFICA - Utilizar Conversão PCEMBALAGEM
          IF (NVL(vUSAQTUNITPCEMBREPLOJA,'N') = 'S') THEN
            -- Procura a menor Embalagem cadastrada para o PRODUTO ORIGEM na FILIAL ORIGEM
            -- SOMENTE Nas Embalagens que podem ser Usadas no Televendas (PERMITEVENDAATACADO = 'S' conforme orientação)
            SELECT NVL(MIN(PCEMBALAGEM.QTUNIT),0)
              INTO N_QTUNITCX_D
              FROM PCEMBALAGEM
             WHERE (PCEMBALAGEM.CODPROD   = PRODUTO.CODPROD_O)
               AND (PCEMBALAGEM.CODFILIAL = NVL(P_CODFILIALRETIRA,P_CODFILIAL_ORIGEM)) -->> Priorizar Filial Retira
               AND (NVL(PCEMBALAGEM.PERMITEVENDAATACADO,'S') = 'S');
            -- Se não achou por PERMITEVENDAATACADO, pesquisa pelo EAN da PCPRODUT - DDVENDAS-38358
            IF (NVL(N_QTUNITCX_D,0) = 0) THEN
              SELECT NVL(MIN(PCEMBALAGEM.QTUNIT),0)
                INTO N_QTUNITCX_D
                FROM PCEMBALAGEM
               WHERE (PCEMBALAGEM.CODPROD     = PRODUTO.CODPROD_O)
                 AND (PCEMBALAGEM.CODFILIAL   = NVL(P_CODFILIALRETIRA,P_CODFILIAL_ORIGEM)) -->> Priorizar Filial Retira
                 AND (PCEMBALAGEM.CODAUXILIAR = PRODUTO.CODAUXILIAR_O);
            END IF;
            -- Se não achou pelo EAN da PCPRODUT, procura em qualquer embalagem - DDVENDAS-38358
            IF (NVL(N_QTUNITCX_D,0) = 0) THEN
              SELECT NVL(MIN(PCEMBALAGEM.QTUNIT),0)
                INTO N_QTUNITCX_D
                FROM PCEMBALAGEM
               WHERE (PCEMBALAGEM.CODPROD     = PRODUTO.CODPROD_O)
                 AND (PCEMBALAGEM.CODFILIAL   = NVL(P_CODFILIALRETIRA,P_CODFILIAL_ORIGEM)); -->> Priorizar Filial Retira
            END IF;
            IF (NVL(N_QTUNITCX_D,0) > 0) THEN
              SELECT PCEMBALAGEM.CODAUXILIAR
                INTO N_CODAUXILIAR_PCEMB_O
                FROM PCEMBALAGEM
               WHERE (PCEMBALAGEM.CODPROD   = PRODUTO.CODPROD_O)
                 AND (PCEMBALAGEM.CODFILIAL = NVL(P_CODFILIALRETIRA,P_CODFILIAL_ORIGEM)) -->> Priorizar Filial Retira
                 AND (PCEMBALAGEM.QTUNIT    = N_QTUNITCX_D)
                 AND (ROWNUM                = 1);
            END IF;
            -- Usando PCEMBALAGEM, NÃO tem Conversão do Trânsito para Produto de Destino
            N_QTUNITCX_TRANSITO_D := 1;
            N_QTUNITCX_OPERLOG_D  := 1;
            -- Usando PCEMBALAGEM, SEMPRE Arredonda para cima
            N_PERCARREDONDA_D     := 0.01;
          END IF;

        --------------------------------------------------------------------------
        -- ARREDONDAMENTO DE REPOSIÇÃO DE CD -------------------------------------
        --------------------------------------------------------------------------
        ELSIF (P_TIPO_SUGESTAO = 'C') THEN

          -- Quantidade de Unidade de Caixa do Produto Origem
          N_QTUNITCX_O := NVL(PRODUTO.QTUNITCX_O,0);

          -- Pega Percentual de Arredondamento do Produto Origem
          N_PERCARREDONDA_O := NVL(N_PERCARREDONDA_F_O,0);

          -- Reposição de CD's não tem Arredondamento no Produto Destino
          -- (OBRIGATORIO DEIXAR NULO)
          N_QTUNITCX_D          := NULL;
          N_PERCARREDONDA_D     := NULL;
          N_QTUNITCX_TRANSITO_D := NULL;
          N_QTUNITCX_OPERLOG_D  := NULL;

          -- DDMEDICA-5012 - Se o CD utilizar PCEMBALAGEM também precisa validar PCEMBALAGEM
          -- REGRA ESPECÍFICA - Utilizar Conversão PCEMBALAGEM
          IF (NVL(vUSAQTUNITPCEMBREPLOJA,'N') = 'S') THEN
            -- Procura a menor Embalagem cadastrada para o PRODUTO ORIGEM na FILIAL ORIGEM
            -- SOMENTE Nas Embalagens que podem ser Usadas no Televendas (PERMITEVENDAATACADO = 'S' conforme orientação)
            SELECT NVL(MIN(PCEMBALAGEM.QTUNIT),0)
              INTO N_QTUNITCX_D
              FROM PCEMBALAGEM
             WHERE (PCEMBALAGEM.CODPROD   = PRODUTO.CODPROD_O)
               AND (PCEMBALAGEM.CODFILIAL = NVL(P_CODFILIALRETIRA,P_CODFILIAL_ORIGEM)) -->> Priorizar Filial Retira
               AND (NVL(PCEMBALAGEM.PERMITEVENDAATACADO,'S') = 'S');
            -- Se não achou por PERMITEVENDAATACADO, pesquisa pelo EAN da PCPRODUT - DDVENDAS-38358
            IF (NVL(N_QTUNITCX_D,0) = 0) THEN
              SELECT NVL(MIN(PCEMBALAGEM.QTUNIT),0)
                INTO N_QTUNITCX_D
                FROM PCEMBALAGEM
               WHERE (PCEMBALAGEM.CODPROD     = PRODUTO.CODPROD_O)
                 AND (PCEMBALAGEM.CODFILIAL   = NVL(P_CODFILIALRETIRA,P_CODFILIAL_ORIGEM)) -->> Priorizar Filial Retira
                 AND (PCEMBALAGEM.CODAUXILIAR = PRODUTO.CODAUXILIAR_O);
            END IF;
            -- Se não achou pelo EAN da PCPRODUT, procura em qualquer embalagem - DDVENDAS-38358
            IF (NVL(N_QTUNITCX_D,0) = 0) THEN
              SELECT NVL(MIN(PCEMBALAGEM.QTUNIT),0)
                INTO N_QTUNITCX_D
                FROM PCEMBALAGEM
               WHERE (PCEMBALAGEM.CODPROD     = PRODUTO.CODPROD_O)
                 AND (PCEMBALAGEM.CODFILIAL   = NVL(P_CODFILIALRETIRA,P_CODFILIAL_ORIGEM)); -->> Priorizar Filial Retira
            END IF;
            IF (NVL(N_QTUNITCX_D,0) > 0) THEN
              SELECT PCEMBALAGEM.CODAUXILIAR
                INTO N_CODAUXILIAR_PCEMB_O
                FROM PCEMBALAGEM
               WHERE (PCEMBALAGEM.CODPROD   = PRODUTO.CODPROD_O)
                 AND (PCEMBALAGEM.CODFILIAL = NVL(P_CODFILIALRETIRA,P_CODFILIAL_ORIGEM)) -->> Priorizar Filial Retira
                 AND (PCEMBALAGEM.QTUNIT    = N_QTUNITCX_D)
                 AND (ROWNUM                = 1);
              -- Usando PCEMBALAGEM, SEMPRE Arredonda para cima
              N_PERCARREDONDA_D := 0.01;
            END IF;
          END IF;

        END IF; -- Fim Condição Tipo Sugestão para definir Arredondamento

        -- Se Utiliza Agenda
        IF (NVL(P_UTILIZA_AGENDA,'N') = 'S') THEN

          -- Pesquisa Agenda por SubCategoria
          POBTER_DADOS_AGENDA(PRODUTO.CODFILIAL_O,
                              PRODUTO.CODFILIAL_D,
                              'SB',
                              PRODUTO.CODSUBCATEGORIA_O,
                              vrAGENDA.V_EXISTE_AGENDA,
                              vrAGENDA.V_SEGUNDA,
                              vrAGENDA.V_TERCA,
                              vrAGENDA.V_QUARTA,
                              vrAGENDA.V_QUINTA,
                              vrAGENDA.V_SEXTA,
                              vrAGENDA.V_SABADO,
                              vrAGENDA.V_DOMINGO);
          -- Se não encontrou Agenda por SubCategoria
          IF (vrAGENDA.V_EXISTE_AGENDA = 'N') THEN
            -- Pesquisa Agenda por Categoria
            POBTER_DADOS_AGENDA(PRODUTO.CODFILIAL_O,
                                PRODUTO.CODFILIAL_D,
                                'CA',
                                PRODUTO.CODCATEGORIA_O,
                                vrAGENDA.V_EXISTE_AGENDA,
                                vrAGENDA.V_SEGUNDA,
                                vrAGENDA.V_TERCA,
                                vrAGENDA.V_QUARTA,
                                vrAGENDA.V_QUINTA,
                                vrAGENDA.V_SEXTA,
                                vrAGENDA.V_SABADO,
                                vrAGENDA.V_DOMINGO);
            -- Se não encontrou Agenda por Categoria
            IF (vrAGENDA.V_EXISTE_AGENDA = 'N') THEN
              -- Pesquisa Agenda por Seção
              POBTER_DADOS_AGENDA(PRODUTO.CODFILIAL_O,
                                  PRODUTO.CODFILIAL_D,
                                  'SE',
                                  PRODUTO.CODSEC_O,
                                  vrAGENDA.V_EXISTE_AGENDA,
                                  vrAGENDA.V_SEGUNDA,
                                  vrAGENDA.V_TERCA,
                                  vrAGENDA.V_QUARTA,
                                  vrAGENDA.V_QUINTA,
                                  vrAGENDA.V_SEXTA,
                                  vrAGENDA.V_SABADO,
                                  vrAGENDA.V_DOMINGO);
              -- Se não encontrou Agenda por Seção
              IF (vrAGENDA.V_EXISTE_AGENDA = 'N') THEN
                -- Pesquisa Agenda por Seção
                POBTER_DADOS_AGENDA(PRODUTO.CODFILIAL_O,
                                    PRODUTO.CODFILIAL_D,
                                    'DE',
                                    PRODUTO.CODEPTO_O,
                                    vrAGENDA.V_EXISTE_AGENDA,
                                    vrAGENDA.V_SEGUNDA,
                                    vrAGENDA.V_TERCA,
                                    vrAGENDA.V_QUARTA,
                                    vrAGENDA.V_QUINTA,
                                    vrAGENDA.V_SEXTA,
                                    vrAGENDA.V_SABADO,
                                    vrAGENDA.V_DOMINGO);
              END IF; -- Fim Condição Se não encontrou Agenda por Seção
            -- Se Achou Agenda por Categoria
            ELSE
              -- Quebra de Pedido da Agenda Automatica por Sub-Categoria
              V_QUEBRA_AGENDA_AUTOM := TO_CHAR(NVL(PRODUTO.CODCATEGORIA_O,0));
            END IF; -- Fim Condição Se não encontrou Agenda por Categoria
          END IF; -- Fim Condição Se não encontrou Agenda por SubCategoria

          -- Se encontrou Agenda
          IF (vrAGENDA.V_EXISTE_AGENDA = 'S') THEN

            -- Verifica se Existe Agenda para o Dia da Semana
            IF ( ((TO_CHAR(SYSDATE,'D') = '1') AND (NVL(vrAGENDA.V_DOMINGO,'N') = 'S')) OR
                 ((TO_CHAR(SYSDATE,'D') = '2') AND (NVL(vrAGENDA.V_SEGUNDA,'N') = 'S')) OR
                 ((TO_CHAR(SYSDATE,'D') = '3') AND (NVL(vrAGENDA.V_TERCA,'N')   = 'S')) OR
                 ((TO_CHAR(SYSDATE,'D') = '4') AND (NVL(vrAGENDA.V_QUARTA,'N')  = 'S')) OR
                 ((TO_CHAR(SYSDATE,'D') = '5') AND (NVL(vrAGENDA.V_QUINTA,'N')  = 'S')) OR
                 ((TO_CHAR(SYSDATE,'D') = '6') AND (NVL(vrAGENDA.V_SEXTA,'N')   = 'S')) OR
                 ((TO_CHAR(SYSDATE,'D') = '7') AND (NVL(vrAGENDA.V_SABADO,'N')  = 'S')) ) THEN

              -- Agenda Válida
              B_AGENDA_VALIDA := TRUE;

            ELSE

              -- Agenda Inválida
              B_AGENDA_VALIDA := FALSE;

            END IF;

          -- Se não encontrou Agenda
          ELSE

            -- Agenda Inválida
            B_AGENDA_VALIDA := FALSE;

          END IF;

        -- Se não Utiliza Agenda
        ELSE

          -- Se não utiliza Agenda, a Agenda é Válida SEMPRE
          B_AGENDA_VALIDA := TRUE;

        END IF; -- Fim Condição Se Utiliza Agenda

       /****************
        SE AGENDA VÁLIDA
        ****************/

        IF (B_AGENDA_VALIDA) THEN

          /*PESQUISA DADOS DA FILIAL DE DESTINO*/
          -- 4056.074463.2015 - Não pode usar Array, Filiais com Letra no código.
          --IF (NOT vtDADOS_FILIAL_D.EXISTS(PRODUTO.CODFILIAL_D)) THEN
          BEGIN
            SELECT PCFILIAL.CONSIDERAESTPENDSUGCOMPRA
              INTO V_CONSIDERAESTPENDSUG_D
              FROM PCFILIAL
             WHERE (PCFILIAL.CODIGO = PRODUTO.CODFILIAL_D);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              V_CONSIDERAESTPENDSUG_D := 'N';
          END;
          --vtDADOS_FILIAL_D(PRODUTO.CODFILIAL_D).V_CONSIDERAESTPENDSUGCOMPRA := V_CONSIDERAESTPENDSUG_D;
          --ELSE
          --  V_CONSIDERAESTPENDSUG_D := vtDADOS_FILIAL_D(PRODUTO.CODFILIAL_D).V_CONSIDERAESTPENDSUGCOMPRA;
          --END IF;
          IF (V_CONSIDERAESTPENDSUG_D = 'S') THEN
            V_DESCCONSIDERAESTPENDSUG_D := 'Sim';
          ELSE
            V_DESCCONSIDERAESTPENDSUG_D := 'Não';
          END IF;

          /*SELECIONANDO O CLIENTE DE DESTINO*/
          V_CODCLI_D := PRODUTO.CODCLI_D;
          IF (NOT vtCLIENTE_D.EXISTS(V_CODCLI_D)) THEN
            BEGIN
              SELECT PCCLIENT.CODPRACA
                   , PCPRACA.NUMREGIAO
                   , PCCLIENT.ESTENT
                   , PCCLIENT.TIPOCUSTOTRANSF
                   , PCPLPAG.NUMPR
                   , PCPRACA.NUMREGIAO
                INTO N_CODPRACA_D
                   , N_NUMREGIAO_D
                   , V_ESTENT_D
                   , V_TIPOCUSTOTRANSF_D
                   , N_NUMPR
                   , N_NUMREGIAO
                FROM PCCLIENT
                   , PCPRACA
                   , PCPLPAG
               WHERE (PCPRACA.CODPRACA  = PCCLIENT.CODPRACA)
                 AND (PCCLIENT.CODCLI   = V_CODCLI_D)
                 AND (PCCLIENT.CODPLPAG = PCPLPAG.CODPLPAG(+));
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                N_CODPRACA_D        := NULL;
                N_NUMREGIAO_D       := NULL;
                V_ESTENT_D          := NULL;
                V_TIPOCUSTOTRANSF_D := NULL;
                N_NUMPR             := 0;
                N_NUMREGIAO         := NULL;
            END;
            -- Pesquisa Regiao do Cliente por Filial
            BEGIN
              SELECT NUMREGIAO
                INTO N_NUMREGIAO
                FROM PCTABPRCLI
               WHERE (CODCLI      = V_CODCLI_D)
                 AND (CODFILIALNF = PRODUTO.CODFILIAL_O);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- Se não encontrar Regiao do Cliente por Filial ignora,
                -- será mantida a da Praça
                NULL;
            END;
            vtCLIENTE_D(V_CODCLI_D).N_CODPRACA_D        := N_CODPRACA_D;
            vtCLIENTE_D(V_CODCLI_D).N_NUMREGIAO_D       := N_NUMREGIAO_D;
            vtCLIENTE_D(V_CODCLI_D).V_ESTENT_D          := V_ESTENT_D;
            vtCLIENTE_D(V_CODCLI_D).V_TIPOCUSTOTRANSF_D := V_TIPOCUSTOTRANSF_D;
            vtCLIENTE_D(V_CODCLI_D).N_NUMPR             := N_NUMPR;
            vtCLIENTE_D(V_CODCLI_D).N_NUMREGIAO         := N_NUMREGIAO;
          ELSE
            N_CODPRACA_D        := vtCLIENTE_D(V_CODCLI_D).N_CODPRACA_D;
            N_NUMREGIAO_D       := vtCLIENTE_D(V_CODCLI_D).N_NUMREGIAO_D;
            V_ESTENT_D          := vtCLIENTE_D(V_CODCLI_D).V_ESTENT_D;
            V_TIPOCUSTOTRANSF_D := vtCLIENTE_D(V_CODCLI_D).V_TIPOCUSTOTRANSF_D;
            N_NUMPR             := vtCLIENTE_D(V_CODCLI_D).N_NUMPR;
            N_NUMREGIAO         := vtCLIENTE_D(V_CODCLI_D).N_NUMREGIAO;
          END IF;

          /*SELECIONANDO DADOS DA PCEST COM RELAÇÃO A ORIGEM*/
          IF (vtINDICE_PROD_O.EXISTS(N_CODPROD_O)) THEN
            I_INDICE_PROD         := vtINDICE_PROD_O(N_CODPROD_O);
            N_QTESTGER_O          := vtQTESTGER_O(I_INDICE_PROD);
            N_QTRESERV_O          := vtQTRESERV_O(I_INDICE_PROD);
            N_QTBLOQUEADA_O       := vtQTBLOQUEADA_O(I_INDICE_PROD);
            N_QTINDENIZ_O         := vtQTINDENIZ_O(I_INDICE_PROD);
            N_MODULO_O            := vtMODULO_O(I_INDICE_PROD);
            N_RUA_O               := vtRUA_O(I_INDICE_PROD);
            N_NUMERO_O            := vtNUMERO_O(I_INDICE_PROD);
            N_APTO_O              := vtAPTO_O(I_INDICE_PROD);
            N_CUSTOREP_O          := vtCUSTOREP_O(I_INDICE_PROD);
            N_CUSTOREAL_O         := vtCUSTOREAL_O(I_INDICE_PROD);
            N_CUSTOCONT_O         := vtCUSTOCONT_O(I_INDICE_PROD);
            N_CUSTOFIN_O          := vtCUSTOFIN_O(I_INDICE_PROD);
            N_CUSTOFINSEMST_O     := vtCUSTOFINSEMST_O(I_INDICE_PROD);
            N_CUSTOULTENT_O       := vtCUSTOULTENT_O(I_INDICE_PROD);
            N_VALORULTENT_O       := vtVALORULTENT_O(I_INDICE_PROD);
            N_CUSTOREALSEMST_O    := vtCUSTOREALSEMST_O(I_INDICE_PROD);
            N_VLULTENTCONTSEMST_O := vtVLULTENTCONTSEMST_O(I_INDICE_PROD);
            N_CUSTOFORNEC_O       := vtCUSTOFORNEC_O(I_INDICE_PROD);
            N_ESTMIN_O            := vtESTMIN_O(I_INDICE_PROD);
            N_QTPENDENTE_O        := vtQTPENDENTE_O(I_INDICE_PROD);
            N_VLICMSBCR_O         := vtVLICMSBCR_O(I_INDICE_PROD);
            -->> Este QTESTDISP estará baixando à medida que vai inserindo na Tabela Temporária a Sugestão de outras Lojas
            -->> Garantindo que se a primeira Loja consumir o Estoque, não terá estoque para a segunda Loja, quando Respeitar o Estoque Minimo da Filial de Origem
            N_QTESTDISP_O         := vtQTESTDISP_O(I_INDICE_PROD);
          ELSE
            N_QTESTGER_O          := 0;
            N_QTRESERV_O          := 0;
            N_QTBLOQUEADA_O       := 0;
            N_QTINDENIZ_O         := 0;
            N_MODULO_O            := NULL;
            N_RUA_O               := NULL;
            N_NUMERO_O            := NULL;
            N_APTO_O              := NULL;
            N_CUSTOREP_O          := 0;
            N_CUSTOREAL_O         := 0;
            N_CUSTOCONT_O         := 0;
            N_CUSTOFIN_O          := 0;
            N_CUSTOULTENT_O       := 0;
            N_VALORULTENT_O       := 0;
            N_CUSTOREALSEMST_O    := 0;
            N_VLULTENTCONTSEMST_O := 0;
            N_CUSTOFORNEC_O       := 0;
            N_ESTMIN_O            := 0;
            N_QTPENDENTE_O        := 0;
            N_QTESTDISP_O         := 0;
            N_CUSTOFINSEMST_O     := 0;
            N_VLICMSBCR_O         := 0;
          END IF;

          --------------------------------------------------------------------------
          -- IGUALA INFORMAÇÕES DO PRODUTO ORIGEM COM O DO PRODUTO DESTINO SE COMPRA
          --           (NÃO TERÁ PRODUTO PAI NESTE TIPO DE OPERAÇÃO)
          --------------------------------------------------------------------------
          IF (V_TIPO_SUG_COMPRA_TRANSF = 'C') THEN
            N_QTESTGER_O    := NVL(PRODUTO.QTESTGER_D,0);
            N_QTRESERV_O    := NVL(PRODUTO.QTRESERV_D,0);
            N_QTBLOQUEADA_O := NVL(PRODUTO.QTBLOQUEADA_D,0);
          END IF;

          /*ALTERANDO ENDERECO CONFORME PARAMETRO*/
          IF (NVL(V_UTILIZAENDPORFILIAL,' ') <> 'S') THEN
            N_MODULO_O := PRODUTO.MODULO_O;
            N_RUA_O    := PRODUTO.RUA_O;
            N_NUMERO_O := PRODUTO.NUMERO_O;
            N_APTO_O   := PRODUTO.APTO_O;
          END IF;

          /*CALCULANDO O PRECO DA NOTA FISCAL DE TRANSFERENCIA OU PEDIDO DE OPERADOR LOGISTICO*/
          IF    (V_TIPO_SUG_COMPRA_TRANSF IN ('T','L')) THEN

            -- INICIALIZA O TIPO DE CUSTO DE TRANSFERENCIA QUE SERA APLICADO COM VALOR INFORMADO NO CLIENTE
            V_TIPOCUSTOTRANSF_APLICAR := V_TIPOCUSTOTRANSF_D;
            -- SE TIVER TRATAMENTO DIFERENCIADO DE CUSTO DE TRANSFERENCIA ENTRE CD'S POR PRODUTO
            IF ((P_TIPO_SUGESTAO = 'C') AND
                (NVL(PRODUTO.TIPOCUSTOTRANSF_O,' ') IN ('E','R','C','F','U','V','S','T','O','A'))) THEN
              -- SERA APLICADO O VALOR INFORMADO NO PRODUTO
              V_TIPOCUSTOTRANSF_APLICAR := PRODUTO.TIPOCUSTOTRANSF_O;
            END IF;

            N_PRECO_TRANSF_O := 0;
            -- Define o Preço da Transferência conforme o Tipo de Custo da Transferência
            IF    (V_TIPOCUSTOTRANSF_APLICAR = 'E') THEN
              N_PRECO_TRANSF_O := NVL(N_CUSTOREP_O,0);
            ELSIF (V_TIPOCUSTOTRANSF_APLICAR = 'R') THEN
                  IF (vDESCSTFORAUFTRANSF = 'S') AND (vUfOrigem  <>  vUfDestino) THEN
                   N_PRECO_TRANSF_O := NVL(N_CUSTOREALSEMST_O,0) ;
                    ELSE
                   N_PRECO_TRANSF_O := NVL(N_CUSTOREAL_O,0);
                  END IF;
            ELSIF (V_TIPOCUSTOTRANSF_APLICAR = 'C') THEN
              N_PRECO_TRANSF_O := NVL(N_CUSTOCONT_O,0);
            ELSIF (V_TIPOCUSTOTRANSF_APLICAR = 'F') THEN
                IF (vDESCSTFORAUFTRANSF = 'S') AND (vUfOrigem  <> vUfDestino) THEN
                   N_PRECO_TRANSF_O := NVL(N_CUSTOFINSEMST_O,0);
                ELSE
                   N_PRECO_TRANSF_O := NVL(N_CUSTOFIN_O,0);
                END IF;
            ELSIF (V_TIPOCUSTOTRANSF_APLICAR = 'U') THEN
              N_PRECO_TRANSF_O := NVL(N_CUSTOULTENT_O,0);
            ELSIF (V_TIPOCUSTOTRANSF_APLICAR = 'V') THEN
              N_PRECO_TRANSF_O := NVL(N_VALORULTENT_O,0);
            ELSIF (V_TIPOCUSTOTRANSF_APLICAR = 'S') THEN
              N_PRECO_TRANSF_O := NVL(N_CUSTOREALSEMST_O,0);
            ELSIF (V_TIPOCUSTOTRANSF_APLICAR = 'T') THEN
              N_PRECO_TRANSF_O := NVL(N_VLULTENTCONTSEMST_O,0);
            ELSIF (V_TIPOCUSTOTRANSF_APLICAR = 'O') THEN
              N_PRECO_TRANSF_O := NVL(N_CUSTOFORNEC_O,0);
            ELSIF (V_TIPOCUSTOTRANSF_APLICAR = 'A') THEN
              N_PRECO_TRANSF_O := FOBTEM_PRECO_ENTRADA(PRODUTO.CODFILIAL_O,
                                                       N_CODPROD_O,
                                                       N_CUSTOULTENT_O);
            END IF;



            -- Se não conseguiu formar o Preço da Transferência a partir da PCEST
            IF (NVL(N_PRECO_TRANSF_O,0) <= 0) THEN
              -- Pesquisa Dados da Tabela de Preços do Produto
              BEGIN
                SELECT PCTABPR.PVENDA1
                     , PCTABPR.PVENDA2
                     , PCTABPR.PVENDA3
                     , PCTABPR.PVENDA4
                     , PCTABPR.PVENDA5
                     , PCTABPR.PVENDA6
                     , PCTABPR.PVENDA7
                     , PCTABPR.CODST
                  INTO vrTabPreco.N_PVENDA1
                     , vrTabPreco.N_PVENDA2
                     , vrTabPreco.N_PVENDA3
                     , vrTabPreco.N_PVENDA4
                     , vrTabPreco.N_PVENDA5
                     , vrTabPreco.N_PVENDA6
                     , vrTabPreco.N_PVENDA7
                     , vrTabPreco.N_CODST
                  FROM PCTABPR
                 WHERE (PCTABPR.CODPROD   = N_CODPROD_O)
                   AND (PCTABPR.NUMREGIAO = N_NUMREGIAO);
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  vrTabPreco.N_PVENDA1 := 0;
                  vrTabPreco.N_PVENDA2 := 0;
                  vrTabPreco.N_PVENDA3 := 0;
                  vrTabPreco.N_PVENDA4 := 0;
                  vrTabPreco.N_PVENDA5 := 0;
                  vrTabPreco.N_PVENDA6 := 0;
                  vrTabPreco.N_PVENDA7 := 0;
              END;
               -- Define o Preço da Transferência conforme a Tabela de Preços e o Número do Prazo do Plano de Pagamento
              IF    (N_NUMPR = 1) THEN
                N_PRECO_TRANSF_O := NVL(vrTabPreco.N_PVENDA1,0);
              ELSIF (N_NUMPR = 2) THEN
                N_PRECO_TRANSF_O := NVL(vrTabPreco.N_PVENDA2,0);
              ELSIF (N_NUMPR = 3) THEN
                N_PRECO_TRANSF_O := NVL(vrTabPreco.N_PVENDA3,0);
              ELSIF (N_NUMPR = 4) THEN
                N_PRECO_TRANSF_O := NVL(vrTabPreco.N_PVENDA4,0);
              ELSIF (N_NUMPR = 5) THEN
                N_PRECO_TRANSF_O := NVL(vrTabPreco.N_PVENDA5,0);
              ELSIF (N_NUMPR = 6) THEN
                N_PRECO_TRANSF_O := NVL(vrTabPreco.N_PVENDA6,0);
              ELSIF (N_NUMPR = 7) THEN
                N_PRECO_TRANSF_O := NVL(vrTabPreco.N_PVENDA7,0);
              END IF;
            END IF; -- Fim Condição Se não conseguiu formar o Preço da Transferência a partir da PCEST

            -- REGRA ESPECÍFICA - Usa Conversão da PCEMBALAGEM
            IF (NVL(vUSAQTUNITPCEMBREPLOJA,'N') = 'S') THEN
              -- Se usar Conversão da PCEMBALAGEM, não pode aplicar conversão do Display->Blister
              N_PRECO_TRANSF_D := NVL(N_PRECO_TRANSF_O,0);
            ELSE
              -- Preço da Transferência na Filial de Destino (Aplica Conversão para Produto de Destino se houver)
              IF (NVL(N_QTUNITCX_D,0) > 0) THEN
                N_PRECO_TRANSF_D := (NVL(N_PRECO_TRANSF_O,0) / NVL(N_QTUNITCX_D,0));
              ELSE
                N_PRECO_TRANSF_D := NVL(N_PRECO_TRANSF_O,0);
              END IF;
            END IF;

          /*CALCULANDO O PRECO DO PEDIDO DE COMPRA*/
          ELSIF (V_TIPO_SUG_COMPRA_TRANSF = 'C') THEN

            -- PESQUISA PREÇO DA COMPRA DO PRODUTO DESTINO NO FORNECEDOR DA PRIORIDADE PARA A FILIAL DE DESTINO
            BEGIN
              SELECT ((((((((((
                         (PCNEGFORNEC.CUSTOREP * (1 - (NVL(PCNEGFORNEC.PERCDESC,0)/100)))
                       * (1 - (NVL(PCNEGFORNEC.PERCDESC1,0)/100)))
                       * (1 - (NVL(PCNEGFORNEC.PERCDESC2,0)/100)))
                       * (1 - (NVL(PCNEGFORNEC.PERCDESC3,0)/100)))
                       * (1 - (NVL(PCNEGFORNEC.PERCDESC4,0)/100)))
                       * (1 - (NVL(PCNEGFORNEC.PERCDESC5,0)/100)))
                       * (1 - (NVL(PCNEGFORNEC.PERCDESC6,0)/100)))
                       * (1 - (NVL(PCNEGFORNEC.PERCDESC7,0)/100)))
                       * (1 - (NVL(PCNEGFORNEC.PERCDESC8,0)/100)))
                       * (1 - (NVL(PCNEGFORNEC.PERCDESC9,0)/100)))
                       * (1 - (NVL(PCNEGFORNEC.PERCDESC10,0)/100))) AS PLIQ
                INTO N_PRECO_TRANSF_D
                FROM PCNEGFORNEC
               WHERE (PCNEGFORNEC.CODPROD   = N_CODPROD_D)
                 AND (PCNEGFORNEC.CODFORNEC = N_CODFORNECPRIORIDADE)
                 AND (PCNEGFORNEC.CODFILIAL = PRODUTO.CODFILIAL_D);
               -- Iguala o Preço Origem com o Preço Destino (Por ser Modalidade Compra, não tem Produto Pai e Filho)
               N_PRECO_TRANSF_O := NVL(N_PRECO_TRANSF_D,0);
               -- Arredonda com base no número de casas decimais do Parâmetro de Custo
               N_PRECO_TRANSF_O := ROUND(N_PRECO_TRANSF_O, N_CON_NUMCASASDECCUSTO);
               N_PRECO_TRANSF_D := ROUND(N_PRECO_TRANSF_D, N_CON_NUMCASASDECCUSTO);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- Se não achou, zera o Preços, porque não tem Preço de Compra
                N_PRECO_TRANSF_D := 0;
                N_PRECO_TRANSF_O := 0;
            END;

          END IF; -- FIM CONDICAO CALCULO PRECO COMPRA OU TRANSFERENCIA

          /*SELECIONANDO CÓDIGO DE EQUIPE DO PRODUTO ORIGEM*/
          BEGIN
              SELECT NVL(PCESTEND.CODEQUIPE, 'XX')
                INTO V_CODEQUIPE
                FROM PCESTEND
               WHERE PCESTEND.MODULO = N_MODULO_O
                 AND PCESTEND.RUA = N_RUA_O
                 AND PCESTEND.NUMERO = N_NUMERO_O
                 AND PCESTEND.APTO = N_APTO_O
                 AND PCESTEND.CODPROD = N_CODPROD_O;
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
                  V_CODEQUIPE := 'XX';
          END;

          /* BUSCANDO INFORMAÇÕES DE TRIBUTAÇÃO SE TRANSFERENCIA OU PEDIDO DE OPERADOR LOGISTICO*/
          IF (V_TIPO_SUG_COMPRA_TRANSF IN ('T','L')) THEN
            BEGIN
                IF V_USATRIBUTACAOPORUF = 'S' THEN
                    SELECT PCTABTRIB.CODST
                      INTO V_CODST
                      FROM PCTABTRIB
                     WHERE PCTABTRIB.CODPROD = N_CODPROD_O
                       AND PCTABTRIB.CODFILIALNF = PRODUTO.CODFILIAL_O
                       AND PCTABTRIB.UFDESTINO = V_ESTENT_D;
                ELSE
                    SELECT PCTABPR.CODST
                      INTO V_CODST
                      FROM PCTABPR
                     WHERE PCTABPR.CODPROD = N_CODPROD_O
                       AND PCTABPR.NUMREGIAO = N_NUMREGIAO_D;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    V_CODST := 0;
            END;
            V_TRIBUTACAO := CASE WHEN V_CODST > 0 THEN 'S' ELSE 'N' END;
          /* SE COMPRA, NÃO PRECISA DE INFORMAÇÕES DE TRIBUTAÇÃO*/
          ELSIF (V_TIPO_SUG_COMPRA_TRANSF = 'C') THEN
            V_TRIBUTACAO := 'S';
          END IF;

          ---------------------------------------------------------------------------------
          ---------------------------------------------------------------------------------
          PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'$COMPOSICAO DO ESTOQUE DISPONIVEL');
          ---------------------------------------------------------------------------------
          ---------------------------------------------------------------------------------

          -- PEDIDO AVARIA ----------------------------------------------------------------
          IF (NVL(P_PEDIDOAVARIA,'N') = 'S') THEN

            -- CALCULANDO ESTOQUE AVARIADO NA FILIAL DE ORIGEM
            V_QTD_EST_ORIG := NVL(N_QTINDENIZ_O,0);

            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. AVARIA = ' || NVL(N_QTINDENIZ_O,0));

            -- SOMA O QUE ESTIVER EM PREFAT
            IF (NVL(V_QTD_EST_ORIG,0) > 0) THEN

              SELECT SUM(QT)
                INTO vnTotalAvariaPrefat
                FROM PCMOVPREFAT
                   , PCPEDC
               WHERE (PCMOVPREFAT.CODFILIAL = PRODUTO.CODFILIAL_O)
                 AND (PCMOVPREFAT.CODPROD   = N_CODPROD_O)
                 AND (PCMOVPREFAT.NUMPED    = PCPEDC.NUMPED)
                 AND (PCPEDC.PEDIDOAVARIA   = 'S');

              IF (vnTotalAvariaPrefat > 0) THEN

                PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. AVARIA PREFAT = ' || NVL(vnTotalAvariaPrefat,0));

                V_QTD_EST_ORIG := NVL(V_QTD_EST_ORIG,0) - NVL(vnTotalAvariaPrefat,0);
                IF (V_QTD_EST_ORIG < 0) THEN
                  V_QTD_EST_ORIG := 0;
                END IF;

                PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. AVARIA = ' || NVL(N_QTINDENIZ_O,0));

              END IF;

            END IF; -- FIM CONDIÇÃO: SOMA O QUE ESTIVER EM PREFAT

            -- CAMPOS QUE NÃO SERÃO UTILIZADOS NO PEDIDO AVARIA
            V_QTD_EST_DEST      := NULL;
            v_QTBLOQSEMAVARIA_D := NULL;
            N_QTD_TRANSITO_D    := NULL;
            N_QTOPERLOG_D       := NULL;
            V_ESTQDISP          := NULL;
            V_ESTQDISPVALIDAMIN := NULL;


          -- REPOSIÇÃO NORMAL -------------------------------------------------------------
          ELSE

            -- CALCULANDO ESTOQUE DE RETORNO PARA ORIGEM (EMBALAGEM DE DISTRIBUICAO - NAO DIVIDE PELA EMBALAGEM DA INDUSTRIA)
            V_QTD_EST_ORIG  := NVL(N_QTESTGER_O,0) -
                               NVL(N_QTRESERV_O,0) -
                               NVL(N_QTBLOQUEADA_O,0);

            -- CALCULANDO ESTOQUE DE RETORNO PARA DESTINO (NA PROPRIA EMBALAGEM DO VAREJO)
            V_QTD_EST_DEST  := NVL(PRODUTO.QTESTGER_D,0) -
                               NVL(PRODUTO.QTRESERV_D,0) -
                               NVL(PRODUTO.QTBLOQUEADA_D,0);
            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'EST. GERENCIAL = ' || NVL(PRODUTO.QTESTGER_D,0));
            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'EST. RESERVADO = ' || NVL(PRODUTO.QTRESERV_D,0));
            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'EST. BLOQUEADO = ' || NVL(PRODUTO.QTBLOQUEADA_D,0));

            -- CALCULAR O ESTOQUE BLOQUEADO DEDUZIDO DAS AVARIAS NA FILIAL DE DESTINO [Tarefa: 176264]
            v_QTBLOQSEMAVARIA_D := NVL(PRODUTO.QTBLOQUEADA_D,0) -
                                   NVL(PRODUTO.QTINDENIZ_D,0);

            -- CALCULA O ESTOQUE EM TRANSITO PARA A FILIAL DE DESTINO - REPOSIÇÃO DE LOJAS
            IF    (P_TIPO_SUGESTAO = 'L') THEN
              -- Aplica Conversão para Produto de Destino na Reposição de Lojas
              N_QTD_TRANSITO_D := (NVL(PRODUTO.QTTRANSITO_O,0) * NVL(N_QTUNITCX_TRANSITO_D,0));
              -- Aplica Conversão para Produto de Destino na Reposição de Lojas
              N_QTOPERLOG_D    := (NVL(PRODUTO.QTOPERLOG_O,0) * NVL(N_QTUNITCX_OPERLOG_D,0));
            -- CALCULA O ESTOQUE EM TRANSITO PARA A FILIAL DE DESTINO - REPOSIÇÃO DE CD
            ELSIF (P_TIPO_SUGESTAO = 'C') THEN
              -- Na Reposição de CD não tem conversão de Embalagem
              N_QTD_TRANSITO_D := NVL(PRODUTO.QTTRANSITO_O,0);
              -- Na Reposição de CD não tem PBM
              N_QTOPERLOG_D    := 0;
            END IF;

            -- CALCULANDO ESTOQUE DISP. DO PRODUTO DESTINO PARA USO NOS CÁLCULOS
            -- Inicia com o Estoque Atual no Destino
            V_ESTQDISP := ROUND((NVL(PRODUTO.QTESTGER_D,0) -
                                 NVL(PRODUTO.QTRESERV_D,0) -
                                 NVL(PRODUTO.QTBLOQUEADA_D,0))
                                ,0);
            /*IF (NVL(V_ESTQDISP,0) < 0) THEN
              -- Não deixa Ficar o Estoque Negativo [Tarefa: 187283]
              V_ESTQDISP := 0;
            END IF;*/

            -- Estoque Disponivel para Validar o Estoque Minimo
            V_ESTQDISPVALIDAMIN := NVL(V_ESTQDISP,0);
            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'EST. DISP. = (<EST. GERENCIAL> - <EST. RESERVADO> - <EST. BLOQUEADO>)');
            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'EST. DISP. = ' || NVL(V_ESTQDISP,0));
            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'EST. DISP. PARA VALIDAR EST. MINIMO = <EST. DISP.>');
            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'EST. DISP. PARA VALIDAR EST. MINIMO = ' || NVL(V_ESTQDISPVALIDAMIN,0));

            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'$COMPOSICAO DO ESTOQUE TOTAL DISPONIVEL');

            -- Incrementa outras mercadorias em Trânsito para o Destino
            IF    (P_TIPO_SUGESTAO = 'L') THEN
              V_ESTQDISP := NVL(V_ESTQDISP,0) +
                            ROUND((NVL(N_QTD_TRANSITO_D,0))      +
                                  (NVL(PRODUTO.QTPEDIDA_D,0))    + -- [Tarefa: 173465] - Considerar a Qtde. de Pedidos de Compra no Cálculo. Não precisa converter Embalagem
                                  (NVL(v_QTBLOQSEMAVARIA_D,0))   + -- [Tarefa: 176264] - Considerar a Qtde. Bloqueada - Avarias no Cálculo. Não precisa converter Embalagem
                                  (NVL(PRODUTO.QTSUGCOMPRA_D,0)) +
                                  (NVL(N_QTOPERLOG_D,0))
                                  ,0);
            ELSIF (P_TIPO_SUGESTAO = 'C') THEN
              V_ESTQDISP := NVL(V_ESTQDISP,0) +
                            ROUND((NVL(N_QTD_TRANSITO_D,0))      +
                                  (NVL(PRODUTO.QTPEDIDA_D,0))    + -- [Tarefa: 173465] - Considerar a Qtde. de Pedidos de Compra no Cálculo. Não precisa converter Embalagem
                                  (NVL(v_QTBLOQSEMAVARIA_D,0))     -- [Tarefa: 176264] - Considerar a Qtde. Bloqueada - Avarias no Cálculo. Não precisa converter Embalagem
                                  ,0);
            END IF;

            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'EST. AVARIADO = ' || NVL(PRODUTO.QTINDENIZ_D,0));
            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'EST. BLOQ. SEM AVARIA = ' || NVL(v_QTBLOQSEMAVARIA_D,0));
            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'EST. TRANSITO = ' || NVL(N_QTD_TRANSITO_D,0));
            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. PEDIDOS COMPRA = ' || NVL(PRODUTO.QTPEDIDA_D,0));
            IF    (P_TIPO_SUGESTAO = 'L') THEN
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. OPER. LOGISTICO = ' || NVL(N_QTOPERLOG_D,0));
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. SUGESTAO COMPRA = ' || NVL(PRODUTO.QTSUGCOMPRA_D,0));
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'EST. TOT. DISP. = <EST. DISP.> + (<EST. BLOQ. SEM AVARIA> + <EST. TRANSITO> + <QT. PEDIDOS COMPRA> + <QT. OPER. LOGISTICO> + <QT. SUGESTAO COMPRA>)');
            ELSIF (P_TIPO_SUGESTAO = 'C') THEN
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'EST. TOT. DISP. = <EST. DISP.> + (<EST. BLOQ. SEM AVARIA> + <EST. TRANSITO> + <QT. PEDIDOS COMPRA>)');
            END IF;
            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'EST. TOT. DISP. = ' || NVL(V_ESTQDISP,0));

          END IF; -- FIM CONDIÇÃO: PEDIDO AVARIA OU REPOSIÇÃO NORMAL

          -- ZERANDO VARIÁVEL DE QTDE SUGERIDA FRACIONADA DO PRODUTO DESTINO
          N_SUG_FRACIONADA_D      := 0;
          -- ZERANDO VARIÁVEL DE QTDE SUGERIDA DO PRODUTO DESTINO
          N_QTD_SUGERIDA_D        := 0;
          -- ZERANDO VARIÁVEL DE QTDE TRANSFERIR ORIGEM
          N_QTD_TRANSFERIR_O      := 0;
          -- ZERANDO VARIÁVEL DE QTDE CAIXAS PADRAO DO FORNECEDOR A TRANSFERIR ORIGEM
          N_CXFORNEC_TRANSFERIR_O := NULL; -- (Inicializa como Nulo para não apresentar valor se reposição de Loja)

          ------------------------------------------------------------------------
          -- CÁLCULO DA TRANSFERÊNCIA DE AVARIA ----------------------------------
          ------------------------------------------------------------------------
          IF    (NVL(P_PEDIDOAVARIA,'N') = 'S') THEN

            N_QTD_TRANSFERIR_O := N_QTINDENIZ_O;

            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. TRANSFERIR = <QT. AVARIA>');
            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. TRANSFERIR = ' || NVL(N_QTD_TRANSFERIR_O,0));

          ------------------------------------------------------------------------
          -- CÁLCULO DA SUGESTÃO DE REPOSIÇÃO DE LOJAS ---------------------------
          ------------------------------------------------------------------------
          ELSIF (P_TIPO_SUGESTAO = 'L') THEN

            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'$FORMULA DE CALCULO DE REPOSICAO DE LOJAS');

            -- Verifica Regra de Estoque Minimo e Maximo e Faceamento
            IF (PRODUTO.TIPOSUGESTAO_D = 'E' AND  NVL(V_ESTQDISPVALIDAMIN,0) <= NVL(PRODUTO.ESTOQUEMIN_D,0)) OR
               (PRODUTO.TIPOSUGESTAO_D = 'F') THEN

              IF (PRODUTO.TIPOSUGESTAO_D = 'E') THEN
                PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'SUGESTAO DE REPOSICAO POR ESTOQUE MINIMO E MAXIMO');
              ELSE
                PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'SUGESTAO DE REPOSICAO POR FACEAMENTO');
              END IF;

              N_SUG_FRACIONADA_D := (NVL(PRODUTO.ESTOQUEMAX_D,0) - NVL(V_ESTQDISP,0));
              IF (NVL(N_SUG_FRACIONADA_D,0) < 0) THEN
                N_SUG_FRACIONADA_D := 0;
              END IF;
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'EST. MAXIMO = ' || NVL(PRODUTO.ESTOQUEMAX_D,0));
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'EST. TOT. DISP. = ' || NVL(V_ESTQDISP,0));
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'SUG. FRACIONADA = (<EST. MAXIMO> - <EST. TOT. DISP.>)');
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'SUG. FRACIONADA = ' || NVL(N_SUG_FRACIONADA_D,0));

            ELSIF (PRODUTO.TIPOSUGESTAO_D = 'E') THEN

              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'SEM SUGESTAO DE REPOSICAO POR NAO ATINGIR O ESTOQUE MINIMO');

            END IF;
            -- SE IMPORTOU A QUANTIDADE ------------------------------------------
            IF (NVL(P_IMPORTA_QTDE_TRANSF,'N') = 'S') THEN

              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'SUGESTAO POR IMPORTACAO DE ARQUIVO');

              -- PESQUISA QUANTIDADE IMPORTADA
              BEGIN
                SELECT QTD_TRANSFERIR_D
                  INTO N_QTIMPORT_D
                  FROM PCMED_TEMP_IMPORT_ATAC_VAR
                 WHERE (CODPROD_D   = N_CODPROD_D)
                   AND (CODFILIAL_D = PRODUTO.CODFILIAL_D)
                   AND (ROWNUM      = 1);
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  N_QTIMPORT_D := 0;
              END;

              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. IMPORTADA = ' || NVL(N_QTIMPORT_D,0));

              -- ARREDONDAMENTO DA SUGESTAO UNITARIA DO PRODUTO DESTINO COM BASE NA EMBALAGEM MASTER
              -- (PARA NAO FRACIONAR O PRODUTO MASTER)
              BEGIN
                N_QTD_TRANSFERIR_O := FOBTEM_QTDE_CAIXAS(NVL(N_QTIMPORT_D,0), -->> BASE = QUANTIDADE IMPORTADA
                                                         NVL(N_QTUNITCX_D,0),
                                                         NVL(N_PERCARREDONDA_D,0),
                                                         'DISPLAY DO PRODUTO NA FILIAL DE DESTINO',
                                                         vARREDONDARSUGESTAOFRACIONADA); -- DDMEDICA-6815
              EXCEPTION
                WHEN OTHERS THEN
                  po_vMsgErroTratado := 'Problemas ao arredondar para caixa.' || CHR(13) || 'Produto ' || N_CODPROD_D || CHR(13) || 'Sugestão: ' || NVL(N_QTIMPORT_D,0) || CHR(13) || 'QTUNITCX: '|| NVL(N_QTUNITCX_D,0) || ' : ' || SQLERRM;
                  RAISE e_TratadoLocal;
              END;

              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. TRANSFERIR = ' || NVL(N_QTD_TRANSFERIR_O,0));

            -- SE NAO IMPORTOU A QUANTIDADE --------------------------------------
            ELSE

              -- NÃO TEM QUANTIDADE A IMPORTAR
              N_QTIMPORT_D := 0;

              -- ARREDONDAMENTO DA SUGESTAO UNITARIA DO PRODUTO DESTINO COM BASE NA EMBALAGEM MASTER
              -- (PARA NAO FRACIONAR O PRODUTO MASTER)
              BEGIN
                N_QTD_TRANSFERIR_O := FOBTEM_QTDE_CAIXAS(NVL(N_SUG_FRACIONADA_D,0), -->> BASE = SUGESTÃO FRACIONADA
                                                         NVL(N_QTUNITCX_D,0),
                                                         NVL(N_PERCARREDONDA_D,0),
                                                         'DISPLAY DO PRODUTO NA FILIAL DE DESTINO',
                                                         vARREDONDARSUGESTAOFRACIONADA); -- DDMEDICA-6815
              EXCEPTION
                WHEN OTHERS THEN
                  po_vMsgErroTratado := 'Problemas ao arredondar para caixa.' || CHR(13) || 'Produto ' || N_CODPROD_D || CHR(13) || 'Sugestão: ' || NVL(N_SUG_FRACIONADA_D,0) || CHR(13) || 'QTUNITCX: '|| NVL(N_QTUNITCX_D,0) || ' : ' || SQLERRM;
                  RAISE e_TratadoLocal;
              END;

              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. TRANSFERIR = ' || NVL(N_QTD_TRANSFERIR_O,0));

            END IF;

            -- RECALCULA A QUANTIDADE SUGERIDA NO DESTINO COM BASE NO ARREDONDAMENTO DA ORIGEM
            N_QTD_SUGERIDA_D := NVL(N_QTD_TRANSFERIR_O,0) * NVL(N_QTUNITCX_D,0);
            IF (NVL(NVL(N_QTUNITCX_D,0),0) > 1) THEN
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'SUG. FRACIONADA APOS ARRED. EMBALAGEM DISPLAY = ' || NVL(N_SUG_FRACIONADA_D,0));
            END IF;

           /****************************************************
            REGRA ESPECÍFICA - Utilizar Conversão da PCEMBALAGEM
            ****************************************************/
            IF (NVL(vUSAQTUNITPCEMBREPLOJA,'N') = 'S') THEN
              -- Quanto utiliza PCEMBALAGEM, não pode transferir em Caixas (Display), transfere a quantidade do fracionado (A regra da PCEMBALAGEM que será usada para apresentar as Caixas)
              N_QTD_TRANSFERIR_O := N_QTD_SUGERIDA_D;
              IF (NVL(NVL(N_QTUNITCX_D,0),0) > 0) THEN
                PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'APLICAR MENOR EMBALAGEM CADASTRADA PARA O PRODUTO NA REPOSICAO DE LOJAS');
                PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. TRANSFERIR SEM ARRED. EMBALAGEM = ' || NVL(N_QTD_TRANSFERIR_O,0));
              END IF;
            END IF;

            -- OBTEM A QTDE. EMBALAGEM DO FORNECEDOR DA COMPRA E % ARREDONDAMENTO
            -- SE NAO ENCONTRAR MANTEM A DO CADASTRO DO PRODUTO
            IF ((NVL(V_TIPO_SUG_COMPRA_TRANSF,'T') = 'C') OR
                (NVL(V_APLICARREDEMBFORNECREPLOJAS,'N') = 'S')) THEN
              -- DDMEDICA-4553
              IF (NVL(V_ORIGEMEMBALAGEMMASTERFORNEC,'1') = '2') THEN
                -- Manterá o N_QTUNITCX_O que será do Cadastro do Produto
                IF (NVL(N_QTUNITCX_O,0) > 1) THEN
                  -- Pega Percentual de Arredondamento do Produto Origem
                  N_PERCARREDONDA_O      := NVL(N_PERCARREDONDA_F_O,0);
                  V_EMB_POR_FORNECEDOR_O := 'S';
                END IF;
              ELSE
                BEGIN
                  SELECT QTUNITCX
                       , PERCARREDONDA
                       , 'S'
                    INTO N_QTUNITCX_O
                       , N_PERCARREDONDA_O
                       , V_EMB_POR_FORNECEDOR_O
                    FROM PCEMBPRODFORNREPOSICAO
                   WHERE (PCEMBPRODFORNREPOSICAO.CODFILIAL = PRODUTO.CODFILIAL_D)   -->> A EMB. MASTER POR FORNECEDOR SERÁ ESPECIFICA PARA CADA LOJA DE DESTINO
                     AND (PCEMBPRODFORNREPOSICAO.CODPROD   = N_CODPROD_O)           -->> A EMB. MASTER POR FORNECEDOR SERÁ CADASTRADA NO PRODUTO DE ORIGEM (ARREDONDA A ORIGEM)
                     AND (PCEMBPRODFORNREPOSICAO.CODFORNEC = N_CODFORNECPRIORIDADE);
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    V_EMB_POR_FORNECEDOR_O := 'N';
                END;
              END IF;
            END IF;

            -- ARREDONDAMENTO DOS FARDOS A SEREM TRANSFERIDOS COM BASE NA EMBALAGEM DA INDUSTRIA
            -- OU SE TIVER EMBALAGEM DIFERENCIADA POR FORNECEDOR
            IF ( (NVL(PRODUTO.UNIDADEMASTER_O,' ') = 'FA') OR
                 (NVL(V_EMB_POR_FORNECEDOR_O ,'N') =  'S') ) THEN

              -- Pesquisa o Percentual de Arredondamento do Produto e Filial de Origem
              -- Se não achou Embalagem por Fornecedor (FARDOS)
              IF ( (NVL(PRODUTO.UNIDADEMASTER_O,' ')  = 'FA') AND
                   (NVL(V_EMB_POR_FORNECEDOR_O ,'N') <>  'S') ) THEN
                -- Pega Percentual de Arredondamento do Produto Origem
                N_PERCARREDONDA_O := NVL(N_PERCARREDONDA_F_O,0);
              END IF;

              -- Arredonda a Quantidade a Transferir para a Embalagem Master da Industria
              BEGIN
                N_QTD_CAIXAS_INDUSTRIA := FOBTEM_QTDE_CAIXAS(NVL(N_QTD_TRANSFERIR_O,0), -- Quantidade a Transferir
                                                             NVL(N_QTUNITCX_O,0),       -- Embalagem Master do Produto de Origem
                                                             NVL(N_PERCARREDONDA_O,0),  -- % Arredondamento da Embalagem da Indústria
                                                             FFORMULA_QT_SUGERIDA(PRODUTO.UNIDADEMASTER_O,
                                                                                  V_EMB_POR_FORNECEDOR_O,
                                                                                  P_TIPO_SUGESTAO,
                                                                                  V_ORIGEMEMBALAGEMMASTERFORNEC),
                                                             'N');                      -- Aqui não é arredondamento da Sugestão Fracionada - DDMEDICA-6815
                -- Guarda a Embalagem utilizada na Conversão por causa da Regra de Respeitar o Estoque Mínimo
                N_EMB_UTILIZADA_CONVERSAO_FRN := NVL(N_QTUNITCX_O,0);
              EXCEPTION
                WHEN OTHERS THEN
                  po_vMsgErroTratado := 'Problemas ao arredondar para caixa.' || CHR(13) || 'Produto ' || N_CODPROD_O || CHR(13) || 'Sugestão: ' || NVL(N_QTD_TRANSFERIR_O,0) || CHR(13) || 'QTUNITCX: '|| NVL(N_QTUNITCX_O,0) || ' : ' || SQLERRM;
                  RAISE e_TratadoLocal;
              END;

              -- Recalcula a Quantidade a Transferir e a Sugestão do Produto de Destino
              N_QTD_TRANSFERIR_O := NVL(N_QTD_CAIXAS_INDUSTRIA,0) * NVL(N_QTUNITCX_O,0);
              N_QTD_SUGERIDA_D   := NVL(N_QTD_TRANSFERIR_O,0) * NVL(N_QTUNITCX_D,0);

              IF (NVL(N_QTUNITCX_O,0) > 1) THEN
                PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. TRANSFERIR APOS ARRED. EMBALAGEM NA ORIGEM = ' || NVL(N_QTD_TRANSFERIR_O,0));
                PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'SUG. FRACIONADA APOS ARRED. EMBALAGEM NA ORIGEM = ' || NVL(N_QTD_TRANSFERIR_O,0));
              END IF;

            END IF; -- FIM CONDIÇÃO ARREDONDAMENTO NA ORIGEM

            -- SE SUGESTAO DE COMPRA, AGRUPARA PEDIDOS POR SER COMPRA FRACIONADA OU COMPRA DE CAIXA FECHADA
            IF (V_TIPO_SUG_COMPRA_TRANSF = 'C') THEN
              -- SE EMBALAGEM FRACIONADA NA ORIGEM
              IF (NVL(N_QTUNITCX_O,0) = 1) THEN
                V_CONTROLE_QUEBRA_EMB := 'F';
              -- SE CAIXA FECHADA NA ORIGEM
              ELSE
                V_CONTROLE_QUEBRA_EMB := 'C';
              END IF;
            END IF;

          ------------------------------------------------------------------------
          -- CÁLCULO DA SUGESTÃO DE REPOSIÇÃO DE CD ------------------------------
          ------------------------------------------------------------------------
          ELSIF (P_TIPO_SUGESTAO = 'C') THEN

            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'$FORMULA DE CALCULO DE REPOSICAO DE CENTROS DE DISTRIBUICAO');

            -- DEFINE OS DIAS DE REPOSICAO
            IF ( (NVL(P_TEMPO_REPOS_PRODUTO,'N') = 'S') AND
                 (NVL(PRODUTO.ESTOQUEIDEAL_D,0)  >  0 ) )  THEN
              -- SE PRIORIZA O TEMPO DE REPOSIÇÃO INFORMADO NO PRODUTO/FILIAL
              N_QTDIASREP_D := NVL(PRODUTO.ESTOQUEIDEAL_D,0);
            ELSE
              --
              N_QTDIASREP_D := NVL(P_TEMPO_REPOSICAO,0);
            END IF;

            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. DIAS COBERTURA = ' || NVL(N_QTDIASREP_D,0));
            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. GIRO DIA = ' || NVL(PRODUTO.QTGIRODIA_D,0));

            -- CACULA SUGESTAO OBSERVANDO OU NAO O PRAZO DE ENTREGA DO FORNECEDOR
            IF (NVL(P_CONSID_PRAZO_ENTREGA,'N') = 'S') THEN
              N_SUG_FRACIONADA_D := (NVL(PRODUTO.QTGIRODIA_D,0) * (NVL(N_PRAZOENTREGA_O,0) + NVL(N_QTDIASREP_D,0)));
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. PRAZO ENTREGA = ' || NVL(N_PRAZOENTREGA_O,0));
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'SUG. FRACIONADA = (<QT. GIRO DIA> x (<QT. DIAS COBERTURA> + <QT. PRAZO ENTREGA>))');
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'SUG. FRACIONADA = ' || NVL(N_SUG_FRACIONADA_D,0));
            ELSE
              N_SUG_FRACIONADA_D := (NVL(PRODUTO.QTGIRODIA_D,0) * NVL(N_QTDIASREP_D,0));
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'SUG. FRACIONADA = (<QT. GIRO DIA> x <QT. DIAS COBERTURA>)');
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'SUG. FRACIONADA = ' || NVL(N_SUG_FRACIONADA_D,0));
            END IF;

            -- SE CONSIDERA QTDE. PENDENTE NA SUGESTAO
            IF (V_CONSIDERAESTPENDSUG_D = 'S') THEN
              N_SUG_FRACIONADA_D := (NVL(N_SUG_FRACIONADA_D,0) + NVL(PRODUTO.QTPENDENTE_D,0));
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. PENDENTE = ' || NVL(PRODUTO.QTPENDENTE_D,0));
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'SUG. FRACIONADA = <SUG. FRACIONADA> + <QT. PENDENTE>');
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'SUG. FRACIONADA = ' || NVL(N_SUG_FRACIONADA_D,0));
            END IF;

            -- ABATE A QUANTIDADE DISPONIVEL
            N_SUG_FRACIONADA_D := (NVL(N_SUG_FRACIONADA_D,0) - NVL(V_ESTQDISP,0));
            IF (NVL(N_SUG_FRACIONADA_D,0) < 0) THEN
              N_SUG_FRACIONADA_D := 0;
            END IF;
            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'EST. TOT. DISP. = ' || NVL(V_ESTQDISP,0));
            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'SUG. FRACIONADA = <SUG. FRACIONADA> - <EST. TOT. DISP.>');
            PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'SUG. FRACIONADA = ' || NVL(N_SUG_FRACIONADA_D,0));

            -- ARREDONDAMENTO PARA A CAIXA DO FORNECEDOR DO PRODUTO DE ORIGEM
            -- (PARA NAO FRACIONAR A CAIXA PADRAO DO FORNECEDOR)
            IF    (NVL(P_SUGESTAO_EMB_MASTER,'S') = 'S') THEN
              BEGIN
                N_CXFORNEC_TRANSFERIR_O := FOBTEM_QTDE_CAIXAS(NVL(N_SUG_FRACIONADA_D,0),
                                                              NVL(N_QTUNITCX_O,0),
                                                              NVL(N_PERCARREDONDA_O,0),
                                                              FFORMULA_QT_SUGERIDA(PRODUTO.UNIDADEMASTER_O,
                                                                                   V_EMB_POR_FORNECEDOR_O,
                                                                                   P_TIPO_SUGESTAO,
                                                                                   V_ORIGEMEMBALAGEMMASTERFORNEC),
                                                              vARREDONDARSUGESTAOFRACIONADA); -- DDMEDICA-6815
                -- Guarda a Embalagem utilizada na Conversão por causa da Regra de Respeitar o Estoque Mínimo
                N_EMB_UTILIZADA_CONVERSAO_FRN := NVL(N_QTUNITCX_O,0);
              EXCEPTION
                WHEN OTHERS THEN
                  po_vMsgErroTratado := 'Problemas ao arredondar para caixa.' || CHR(13) || 'Produto ' || N_CODPROD_O || CHR(13) || 'Sugestão: ' || NVL(N_SUG_FRACIONADA_D,0) || CHR(13) || 'QTUNITCX: '|| NVL(N_QTUNITCX_O,0) || ' : ' || SQLERRM;
                  RAISE e_TratadoLocal;
              END;

              -- CALCULO DA QUANTIDADE DE SUGESTAO UNITARIA DO PRODUTO ORIGEM COM BASE NA QUANTIDADE DA CAIXAS PADRAO DO FORNECEDOR CALCULADAS
              N_QTD_TRANSFERIR_O := NVL(N_CXFORNEC_TRANSFERIR_O,0) * NVL(N_QTUNITCX_O,0);
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. TRANSFERIR APOS ARRED. EMBALAGEM NA ORIGEM = ' || NVL(N_QTD_TRANSFERIR_O,0));

              -- COMO NAO TEM CONVERSAO DE EMBALAGEM DA TRANSFERENCIA DE CD'S, A QUANTIDADE DESTINO RECEBE A QUANTIDADE ORIGEM
              N_QTD_SUGERIDA_D   := NVL(N_QTD_TRANSFERIR_O,0);
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'SUG. FRACIONADA APOS ARRED. EMBALAGEM NA ORIGEM = ' || NVL(N_QTD_TRANSFERIR_O,0));

            -- SEM ARREDONDAMENTO PARA A CAIXA DO FORNECEDOR DO PRODUTO DE ORIGEM (REPOSICAO FRACIONADA)
            ELSE
              -- CALCULO DA QUANTIDADE DE SUGESTAO UNITARIA DO PRODUTO ORIGEM SEM CONSIDERAR A QUANTIDADE DA CAIXA PADRAO DO FORNECEDOR
              N_QTD_TRANSFERIR_O        := ROUND(NVL(N_SUG_FRACIONADA_D,0)); -- Não deixa a Quantidade com Decimais
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. TRANSFERIR = <SUG. FRACIONADA>');
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. TRANSFERIR = ' || NVL(N_QTD_TRANSFERIR_O,0));

              -- COMO NAO TEM CONVERSAO DE EMBALAGEM DA TRANSFERENCIA DE CD'S, A QUANTIDADE DESTINO RECEBE A QUANTIDADE ORIGEM
              N_QTD_SUGERIDA_D   := NVL(N_QTD_TRANSFERIR_O,0);

              -- CALCULA QUANTAS CAIXAS DO FORNECEDOR SERIAM A TRANSFERÊNCIA
              IF (NVL(N_QTUNITCX_O,0) > 0) THEN
                N_CXFORNEC_TRANSFERIR_O := (NVL(N_QTD_TRANSFERIR_O,0) / NVL(N_QTUNITCX_O,0));
              ELSE
                N_CXFORNEC_TRANSFERIR_O := 0;
              END IF;
            END IF;

          END IF; -- Fim Condição Tipo de Cálculo da Sugestão

          /*********************************************************************************/
          /*DEFINE DESCRIÇÕES CONFORME COMPRA OU TRANSFERENCIA OU PEDIDO OPERADOR LOGISTICO*/
          /*********************************************************************************/
          IF    (V_TIPO_SUG_COMPRA_TRANSF = 'C') THEN
            V_DESC_TIPO_SUG_COMPRA_TRANSF := 'Compra';
            -- Pesquisa o Nome do Fornecedor da Compra
            BEGIN
              SELECT SUBSTR(PCFORNEC.FORNECEDOR,1,30)
                   , PCFORNEC.CODFORNEC || ' - ' || SUBSTR(PCFORNEC.FORNECEDOR,1,30)
                INTO V_DESC_FORNECPRIORIDADE
                   , V_CODDESC_FORNECPRIORIDADE
                FROM PCFORNEC
               WHERE (PCFORNEC.CODFORNEC = N_CODFORNECPRIORIDADE);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                V_DESC_FORNECPRIORIDADE    := NULL;
                V_CODDESC_FORNECPRIORIDADE := NULL;
            END;
          ELSIF (V_TIPO_SUG_COMPRA_TRANSF IN ('T','L')) THEN
            -- Transferência
            IF    (V_TIPO_SUG_COMPRA_TRANSF = 'T') THEN
              V_DESC_TIPO_SUG_COMPRA_TRANSF := 'Transferência';
            -- Transferência Pedido de Operador Logístico
            ELSIF (V_TIPO_SUG_COMPRA_TRANSF = 'L') THEN
              V_DESC_TIPO_SUG_COMPRA_TRANSF := 'Transf. OL';
            END IF;
            -- Pesquisa o Nome da Filial de Origem da Transferencia
            BEGIN
              SELECT PCFILIAL.FANTASIA
                   , PCFILIAL.FANTASIA -- Transferência não precisa colocar o Código
                INTO V_DESC_FORNECPRIORIDADE
                   , V_CODDESC_FORNECPRIORIDADE
                FROM PCFILIAL
               WHERE (PCFILIAL.CODIGO = PRODUTO.CODFILIAL_O);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                V_DESC_FORNECPRIORIDADE    := NULL;
                V_CODDESC_FORNECPRIORIDADE := NULL;
            END;
          END IF;

          /*DEFINE A QUEBRA*/
          IF    (P_TIPO_QUEBRA = 0) THEN
            -- Sem Quebra
            V_QUEBRA1 := '0';
            V_QUEBRA2 := NVL(PRODUTO.PSICOTROPICO,'N');
            V_QUEBRA3 := NVL(V_QUEBRA_AGENDA_AUTOM,'0');
            V_QUEBRA4 := NVL(V_CONTROLE_QUEBRA_EMB,'C');
          ELSIF (P_TIPO_QUEBRA = 1) THEN
            -- Quebra por Equipe
            V_QUEBRA1 := NVL(V_CODEQUIPE,'XXXX');
            V_QUEBRA2 := NVL(PRODUTO.PSICOTROPICO,'N');
            V_QUEBRA3 := NVL(V_QUEBRA_AGENDA_AUTOM,'0');
            V_QUEBRA4 := NVL(V_CONTROLE_QUEBRA_EMB,'C');
          ELSIF (P_TIPO_QUEBRA = 2) THEN
            -- Quebra por Fornecedor
            V_QUEBRA1 := TO_CHAR(NVL(PRODUTO.CODFORNEC_O,0));
            V_QUEBRA2 := NVL(PRODUTO.PSICOTROPICO,'N');
            V_QUEBRA3 := NVL(V_QUEBRA_AGENDA_AUTOM,'0');
            V_QUEBRA4 := NVL(V_CONTROLE_QUEBRA_EMB,'C');
          ELSIF (P_TIPO_QUEBRA = 3) THEN
            -- Quebra por Departamento
            V_QUEBRA1 := FOBTEM_QUEBRA_AGRUPADA('DE',
                                                TO_CHAR(NVL(PRODUTO.CODEPTO_O,0)),
                                                TO_CHAR(NVL(PRODUTO.CODSEC_O,0)),
                                                TO_CHAR(NVL(PRODUTO.CODCATEGORIA_O,0)),
                                                TO_CHAR(NVL(PRODUTO.CODSUBCATEGORIA_O,0)),
                                                P_TIPO_SUGESTAO,
                                                P_AUTOMATICO_MANUAL);
            V_QUEBRA2 := NVL(PRODUTO.PSICOTROPICO,'N');
            V_QUEBRA3 := NVL(V_QUEBRA_AGENDA_AUTOM,'0');
            V_QUEBRA4 := NVL(V_CONTROLE_QUEBRA_EMB,'C');
          ELSIF (P_TIPO_QUEBRA = 4) THEN
            -- Quebra por Seção
            V_QUEBRA1 := FOBTEM_QUEBRA_AGRUPADA('SE',
                                                TO_CHAR(NVL(PRODUTO.CODEPTO_O,0)),
                                                TO_CHAR(NVL(PRODUTO.CODSEC_O,0)),
                                                TO_CHAR(NVL(PRODUTO.CODCATEGORIA_O,0)),
                                                TO_CHAR(NVL(PRODUTO.CODSUBCATEGORIA_O,0)),
                                                P_TIPO_SUGESTAO,
                                                P_AUTOMATICO_MANUAL);
            V_QUEBRA2 := NVL(PRODUTO.PSICOTROPICO,'N');
            V_QUEBRA3 := NVL(V_QUEBRA_AGENDA_AUTOM,'0');
            V_QUEBRA4 := NVL(V_CONTROLE_QUEBRA_EMB,'C');
          ELSIF (P_TIPO_QUEBRA = 5) THEN
            -- Quebra por Categoria
            V_QUEBRA1 := FOBTEM_QUEBRA_AGRUPADA('CA',
                                                TO_CHAR(NVL(PRODUTO.CODEPTO_O,0)),
                                                TO_CHAR(NVL(PRODUTO.CODSEC_O,0)),
                                                TO_CHAR(NVL(PRODUTO.CODCATEGORIA_O,0)),
                                                TO_CHAR(NVL(PRODUTO.CODSUBCATEGORIA_O,0)),
                                                P_TIPO_SUGESTAO,
                                                P_AUTOMATICO_MANUAL);
            V_QUEBRA2 := NVL(PRODUTO.PSICOTROPICO,'N');
            V_QUEBRA3 := NVL(V_QUEBRA_AGENDA_AUTOM,'0');
            V_QUEBRA4 := NVL(V_CONTROLE_QUEBRA_EMB,'C');
          ELSIF (P_TIPO_QUEBRA = 6) THEN
            -- Quebra por Marca
            V_QUEBRA1 := TO_CHAR(NVL(PRODUTO.CODMARCA_O,0));
            V_QUEBRA2 := NVL(PRODUTO.PSICOTROPICO,'N');
            V_QUEBRA3 := NVL(V_QUEBRA_AGENDA_AUTOM,'0');
            V_QUEBRA4 := NVL(V_CONTROLE_QUEBRA_EMB,'C');
          ELSIF (P_TIPO_QUEBRA = 7) THEN
            -- Quebra por Rua
            V_QUEBRA1 := TO_CHAR(NVL(N_RUA_O,0));
            V_QUEBRA2 := NVL(PRODUTO.PSICOTROPICO,'N');
            V_QUEBRA3 := NVL(V_QUEBRA_AGENDA_AUTOM,'0');
            V_QUEBRA4 := NVL(V_CONTROLE_QUEBRA_EMB,'C');
          END IF;

          -- RESTRIÇÕES
          V_RESTRICOES := 'N';
          IF (V_DESCONSIDPRODSEMCUSTOFIN  = 'S') AND (NVL(N_CUSTOFIN_O,0) = 0)  THEN
            V_RESTRICOES := 'S';
          END IF;
          IF (V_DESCONSIDPRODSEMCUSTOREAL = 'S') AND (NVL(N_CUSTOREAL_O,0) = 0) THEN
            V_RESTRICOES := 'S';
          END IF;
          IF (V_DESCONSIDPRODSEMTRIBUT    = 'S') AND (NVL(V_CODST,0) = 0)       THEN
            V_RESTRICOES := 'S';
          END IF;
          IF (NVL(P_PEDIDOAVARIA,'N') = 'S') AND (NVL(N_QTINDENIZ_O,0) = 0) THEN
            V_RESTRICOES := 'S';
          END IF;

          -- ARRAY DE LOTES - DDMEDICA-5077
          vtLotes.DELETE;
          IF (NVL(P_PEDIDOAVARIA,'N') = 'S') THEN
            IF (NVL(PRODUTO.ESTOQUEPORLOTE,'N') = 'S') THEN
              FOR vc_Lotes IN (SELECT NUMLOTE
                                    , QTINDENIZ
                                 FROM PCLOTE
                                WHERE (CODFILIAL = PRODUTO.CODFILIAL_O)
                                  AND (CODPROD   = PRODUTO.CODPROD_O)
                                  AND (QTINDENIZ > 0)) LOOP

                viIdxLote := NVL(vtLotes.COUNT,0) + 1;
                vtLotes(viIdxLote).vvSugestaoLote := 'S';
                vtLotes(viIdxLote).vvNumLote      := vc_Lotes.NUMLOTE;
                vtLotes(viIdxLote).vnQtIndeniz    := vc_Lotes.QTINDENIZ;

                -- SOMA O QUE ESTIVER EM PREFAT PARA O LOTE
                SELECT SUM(QT)
                  INTO vnTotalAvariaPrefat
                  FROM PCMOVPREFAT
                     , PCPEDC
                 WHERE (PCMOVPREFAT.CODFILIAL = PRODUTO.CODFILIAL_O)
                   AND (PCMOVPREFAT.CODPROD   = N_CODPROD_O)
                   AND (PCMOVPREFAT.NUMLOTE   = vc_Lotes.NUMLOTE)
                   AND (PCMOVPREFAT.NUMPED    = PCPEDC.NUMPED)
                   AND (PCPEDC.PEDIDOAVARIA   = 'S');
                IF (vnTotalAvariaPrefat > 0) THEN
                  vtLotes(viIdxLote).vnQtIndeniz := vtLotes(viIdxLote).vnQtIndeniz - NVL(vnTotalAvariaPrefat,0);
                  IF (vtLotes(viIdxLote).vnQtIndeniz < 0) THEN
                    vtLotes(viIdxLote).vnQtIndeniz := 0;
                  END IF;
                END IF;

              END LOOP;
              IF (NVL(vtLotes.COUNT,0) = 0) THEN
                V_RESTRICOES := 'S';
              END IF;
            ELSE
              vtLotes(1).vvSugestaoLote := 'N';
              vtLotes(1).vvNumLote      := 'X';
            END IF;
          ELSE
            vtLotes(1).vvSugestaoLote := 'N';
            vtLotes(1).vvNumLote      := 'X';
          END IF;

          -- ALTERAÇÃO DE VALORES SE PEDIDO AVARIA - DDMEDICA-5077
          IF (P_PEDIDOAVARIA = 'S') THEN
            V_EMB_POR_FORNECEDOR_O := 'N';
            N_PERCARREDONDA_O      := NULL;
            N_QTUNITCX_D           := 1;
          END IF;

          -----------------------------------------------------------------------
          -- INICIO: DDMEDICA-4666 - Respeitar estoque minimo na Filial de Origem
          -----------------------------------------------------------------------
          IF (NVL(P_PEDIDOAVARIA,'N') <> 'S') THEN
            IF (NVL(V_RESPEITARESTOQUEMINORIGEM,'N') = 'S') THEN
              -- Pega Estoque Mínimo da Rotina 238
              N_ESTOQUEMIN_O := NVL(N_ESTOQUEMIN_F_O,0);
              --
              IF (NVL(V_BLOQUEIAVENDAESTPENDENTE,'N') = 'S') THEN
                PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'$LIMITAR A REPOSICAO AO ESTOQUE DISPONIVEL E ESTOQUE MINIMO NA FILIAL DE ORIGEM BLOQUEANDO VENDA DE ESTOQUE PENDENTE');
              ELSE
                PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'$LIMITAR A REPOSICAO AO ESTOQUE DISPONIVEL E ESTOQUE MINIMO NA FILIAL DE ORIGEM SEM BLOQUEAR VENDA DE ESTOQUE PENDENTE');
              END IF;
              -- Estoque Disponível
              IF (vtINDICE_PROD_O.EXISTS(N_CODPROD_O)) THEN
                I_INDICE_PROD := vtINDICE_PROD_O(N_CODPROD_O);
                N_QTESTDISP_O := vtQTESTDISP_O(I_INDICE_PROD);
              ELSE
                N_QTESTDISP_O := 0;
              END IF;
              -- Sobrepõe o Estoque Disponível na Origem do Grid, para abater o que foi utilizado na primeira Loja
              V_QTD_EST_ORIG := N_QTESTDISP_O;
              --
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'EST. DISP. FILIAL ORIGEM = ' || NVL(N_QTESTDISP_O,0));
              -- Define qual Estoque mínimo a usar
              IF    (P_TIPO_SUGESTAO = 'L') THEN
                N_ESTOQUEMINSUG_O := NVL(N_ESTOQUEMIN_O,0);
                PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'EST. MIN. DA ROTINA 238 = ' || NVL(N_ESTOQUEMINSUG_O,0));
              ELSIF (P_TIPO_SUGESTAO = 'C') THEN
                N_ESTOQUEMINSUG_O := NVL(N_ESTMIN_O,0);
                PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'EST. MIN. DA ROTINA 205 = ' || NVL(N_ESTOQUEMINSUG_O,0));
              END IF;
              -- Abate o Estoque Mínimo do Estoque Disponível
              N_QTESTDISP_O := NVL(N_QTESTDISP_O,0) - NVL(N_ESTOQUEMINSUG_O,0);
              IF (NVL(N_QTESTDISP_O,0) < 0) THEN
                N_QTESTDISP_O := 0;
              END IF;
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'EST. DISP. PARA TRANSFERIR = <EST. DISP. FILIAL ORIGEM> - <EST. MIN.>');
              PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'EST. DISP. PARA TRANSFERIR = ' || NVL(N_QTESTDISP_O,0));
              -- Limita a Quantidade a Transferir ao Disponível
              IF (NVL(N_QTD_TRANSFERIR_O,0) > NVL(N_QTESTDISP_O,0)) THEN
                -- Primeiro registra a quantidade cancelada
                N_QTCANCESTOQUEMINSUG_O := (NVL(N_QTD_TRANSFERIR_O,0) - NVL(N_QTESTDISP_O,0));
                -- Depois que limita à quantidade disponível
                N_QTD_TRANSFERIR_O      := NVL(N_QTESTDISP_O,0);
                PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. CANCELADA POR ESTOQUE INSUFICIENTE = ' || NVL(N_QTCANCESTOQUEMINSUG_O,0));
                PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. TRANSFERIR RESTANTE POR ESTOQUE INSUFICIENTE = ' || NVL(N_QTD_TRANSFERIR_O,0));
                -- Se Houve Conversão para Múltiplo da Embalagem do Fornecedor
                IF (NVL(N_EMB_UTILIZADA_CONVERSAO_FRN,0) > 1) THEN
                  N_QTD_CAIXAS_INDUSTRIA := FOBTEM_QTDE_CAIXAS(NVL(N_QTD_TRANSFERIR_O,0),
                                                               NVL(N_EMB_UTILIZADA_CONVERSAO_FRN,0),
                                                               0, -->> ZERO para arredondar para baixo
                                                               'ARREDONDAMENTO PARA BAIXO (0%) DA QT. TRANSFERIR RESTANTE POR ESTOQUE INSUFICIENTE',
                                                               'N');                       -- Aqui não é arredondamento da Sugestão Fracionada - DDMEDICA-6815                  -- Recalcula a Quantidade a Transferir e a Sugestão do Produto de Destino
                  -- Recalcula a Quantidade a Transferir e a Sugestão do Produto de Destino
                  N_QTD_TRANSFERIR_O := NVL(N_QTD_CAIXAS_INDUSTRIA,0) * NVL(N_QTUNITCX_O,0);
                  N_QTD_SUGERIDA_D   := NVL(N_QTD_TRANSFERIR_O,0) * NVL(N_QTUNITCX_D,0);
                  PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. TRANSFERIR RESTANTE APOS ARREDONDAMENTO = ' || NVL(N_QTD_TRANSFERIR_O,0));
                END IF;
                -- Recalcula Valores do Destino
                IF    (P_TIPO_SUGESTAO = 'L') THEN
                  N_QTD_SUGERIDA_D := NVL(N_QTD_TRANSFERIR_O,0) * NVL(N_QTUNITCX_D,0);
                ELSE
                  N_QTD_SUGERIDA_D := NVL(N_QTD_TRANSFERIR_O,0);
                END IF;

                
                
              ELSE
                N_QTCANCESTOQUEMINSUG_O := 0;
                PFORMULA_QT_SUGERIDA(V_FORMULA_QT_SUGERIDA_D,'QT. CANCELADA POR ESTOQUE INSUFICIENTE = ' || NVL(N_QTCANCESTOQUEMINSUG_O,0));
              END IF;
              -- Baixa a Quantidade a Tranferir do Saldo em Memória
              IF (vtINDICE_PROD_O.EXISTS(N_CODPROD_O)) THEN
                I_INDICE_PROD := vtINDICE_PROD_O(N_CODPROD_O);
                vtQTESTDISP_O(I_INDICE_PROD) := vtQTESTDISP_O(I_INDICE_PROD) - NVL(N_QTD_TRANSFERIR_O,0);
              END IF;
            ELSE
              N_ESTMIN_O              := NULL;
              N_ESTOQUEMIN_O          := NULL;
              N_ESTOQUEMINSUG_O       := NULL;
              N_QTCANCESTOQUEMINSUG_O := NULL;
            END IF;
          END IF; -- FIM CONDIÇÃO: SE NÃO FOR PEDIDO AVARIA
          -- FÓRMULA
          IF (V_FORMULA_QT_SUGERIDA_D IS NOT NULL) THEN
            V_FORMULA := 'S';
          ELSE
            V_FORMULA := 'N';
          END IF;
          --------------------------------------------------------------------
          -- FIM: DDMEDICA-4666 - Respeitar estoque minimo na Filial de Origem
          --------------------------------------------------------------------

          ----------------------------------
          ----------------------------------
          -- SE CONSIDERA O ITEM NA SUGESTAO
          -- (OBS: Transferencia entre CDs, não permite transferir Produtos com Embalagem Diferentes (Produto Master e Produto Filho))
          ----------------------------------
          ----------------------------------
          IF ( (NVL(P_APENAS_ITENS_COM_SUG,'N') <> 'S') OR
               ((NVL(P_APENAS_ITENS_COM_SUG,'N') = 'S') AND (NVL(N_QTD_SUGERIDA_D,0) > 0)) )
             AND
             ( (NVL(P_APENAS_ABAIXO_MINIMO,'N') <> 'S') OR
               ((NVL(P_APENAS_ABAIXO_MINIMO,'N') = 'S') AND (NVL(V_QTD_EST_DEST,0) < NVL(PRODUTO.ESTMIN_D,0))) )
             AND
             ( (NVL(P_APENAS_EST_MAIOR_ZERO,'N') <> 'S') OR
               ((NVL(P_APENAS_EST_MAIOR_ZERO,'N') = 'S') AND (NVL(V_QTD_EST_ORIG,0) > 0)) )
             AND
             ( (TRIM(P_RUA) IS NULL) OR
               ((TRIM(P_RUA) IS NOT NULL) AND (TO_CHAR(N_RUA_O) = TRIM(P_RUA))) )
             AND
             ( (NVL(vUSAQTUNITPCEMBREPLOJA,'N') <> 'S') OR
               ((NVL(vUSAQTUNITPCEMBREPLOJA,'N') = 'S') AND (NVL(N_CODPROD_O,0) = NVL(N_CODPROD_D,0))) )
             AND
             ( (NVL(P_TIPO_SUGESTAO,' ') = 'L') OR
               ((NVL(P_TIPO_SUGESTAO,' ') = 'C') AND (NVL(N_CODPROD_O,0) = NVL(N_CODPROD_D,0))) )
             AND
             ( NVL(V_RESTRICOES,'N') = 'N' ) THEN

            -- INFO DAS QUEBRAS
            V_INFOQUEBRAS := SUBSTR(NVL(PRODUTO.CODFILIAL_O,0)        || ' + ' ||
                                    NVL(PRODUTO.CODFILIAL_D,0)        || ' + ' ||
                                    NVL(N_CODFORNECPRIORIDADE,0)      || ' + ' ||
                                    NVL(V_TIPO_SUG_COMPRA_TRANSF,'T') || ' + ' ||
                                    NVL(N_INTEGRADORA,0)              || ' + ' ||
                                    NVL(N_INTEGRADORAESPELHONF,0)     || ' + ' ||
                                    NVL(P_TIPO_QUEBRA,0)              || ' + ' ||
                                    NVL(V_QUEBRA1,' ')                || ' + ' ||
                                    NVL(V_QUEBRA2,' ')                || ' + ' ||
                                    NVL(V_QUEBRA3,' ')                || ' + ' ||
                                    NVL(V_QUEBRA4,' '),1,100);

            -- LAÇO DE LOTES
            FOR viIdxLote IN vtLotes.FIRST..vtLotes.LAST LOOP

              -- PEGA O LOTE E A QUANTIDADE A TRANSFERIR - DDMEDICA-5077
              IF (vtLotes(viIdxLote).vvSugestaoLote = 'S') THEN
                V_QTD_EST_ORIG     := vtLotes(viIdxLote).vnQtIndeniz;
                N_QTD_TRANSFERIR_O := vtLotes(viIdxLote).vnQtIndeniz;
                N_QTD_SUGERIDA_D   := vtLotes(viIdxLote).vnQtIndeniz;
                V_NUMLOTE          := vtLotes(viIdxLote).vvNumLote;
              ELSE
                V_NUMLOTE          := 'X';
              END IF;
              
              -- Recalcula a quantidade de acordo com o multiplo do destino -- DDVENDAS-45056
              IF (NVL(vUTILIZAVENDAPOREMBALAGEM,'N') <> 'S') and (N_QTD_SUGERIDA_D > 0) THEN
                -- Verifica se o cliente está configurado para utilizar multiplo
                BEGIN
                  SELECT NVL(PCCLIENT.VALIDARMULTIPLOVENDA,'N')
                    INTO vVALIDARMULTIPLOVENDA
                    FROM PCCLIENT, PCFILIAL
                   WHERE PCCLIENT.CODCLI = PCFILIAL.CODCLI
                     AND PCFILIAL.CODIGO = PRODUTO.CODFILIAL_D;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                   vVALIDARMULTIPLOVENDA := 'N';
                END;
                  
                IF vVALIDARMULTIPLOVENDA = 'S' AND vAPLICARVALIDACAOMULTIPLO = 'S' THEN
                  BEGIN
                    SELECT PCPRODFILIAL.MULTIPLO 
                      INTO vMULTIPLOPRODUTO
                      FROM PCPRODFILIAL
                     WHERE (CODFILIAL = PRODUTO.CODFILIAL_O)
                       AND (CODPROD   = N_CODPROD_O);
                       
                       IF NVL(vMULTIPLOPRODUTO,0) = 0 THEN
                          SELECT NVL(PCPRODUT.MULTIPLO ,1)
                            INTO vMULTIPLOPRODUTO
                            FROM PCPRODUT
                           WHERE (CODPROD = N_CODPROD_O);                         
                       END IF;  
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      SELECT NVL(PCPRODUT.MULTIPLO ,1)
                        INTO vMULTIPLOPRODUTO
                        FROM PCPRODUT
                       WHERE (CODPROD   = N_CODPROD_O);
                  END;
                  
                  N_QTD_TRANSFERIR_O := (NVL(N_QTD_TRANSFERIR_O,0) - REMAINDER(NVL(N_QTD_TRANSFERIR_O,0),NVL(vMULTIPLOPRODUTO,0)));
                  
                END IF;

              END IF;
              -- FIM -- DDVENDAS-45056


              -- INSERE NA TABELA TEMPORARIA
              INSERT INTO PCMED_TEMP_TRANSF_ATAC_VAR
                        ( DTGERACAO
                        , CODFILIAL_O
                        , CODFILIALRETIRA_O
                        , CODPROD_O
                        , DESCRICAO_O
                        , CODMARCA_O
                        , MARCA_O
                        , QTUNITCX_O
                        , QTD_EST_O
                        , QTD_SUGERIDA_O
                        , QTD_TRANSFERIR_O
                        , CODFILIAL_D
                        , PRIORIDADE_D
                        , CODPROD_D
                        , DESCRICAO_D
                        , TIPOSUGESTAO_D
                        , DESCTIPOSUGESTAO_D
                        , ESTOQUEMIN_D
                        , ESTOQUEMAX_D
                        , QTESTGER_D
                        , QTPEDIDA_D
                        , QTD_TRANSITO_D
                        , QTD_BLOQSEMAVARIA_D
                        , CLASSE_D
                        , PMC_D
                        , CUSTOULTENT_D
                        , PVENDA_D
                        , SUG_FRACIONADA_D
                        , QTUNITCX_D
                        , PERCARREDONDA_D
                        , QTD_SUGERIDA_D
                        , QTD_TRANSFERIR_D
                        , VLR_TRANSFERIR_D
                        , CODEQUIPE
                        , CODCATEGORIA
                        , CODSEC
                        , CODEPTO
                        , CODFORNEC
                        , EMBALAGEM
                        , UNIDADE
                        , TRIBUTACAO
                        , CODST
                        , QTVENDMES_D
                        , QTVENDMES1_D
                        , QTVENDMES2_D
                        , QTVENDMES3_D
                        , CODFAB_O
                        , CODFAB_D
                        , CODAUXILIAR_O
                        , CODAUXILIAR_D
                        , QUEBRA1
                        , QUEBRA2
                        , QUEBRA3
                        , QUEBRA4
                        , QTGIRODIA_D
                        , QTDIASREP_D
                        , QTPENDENTE_D
                        , DESCCONSIDERAESTPENDSUG_D
                        , PRAZOENTREGA_O
                        , PERCARREDONDA_O
                        , CXFORNEC_TRANSFERIR_O
                        , TIPO_SUG_LOJA_CD
                        , TIPO_SUG_COMPRA_TRANSF
                        , DESC_TIPO_SUG_COMPRA_TRANSF
                        , CODFORNECPRIORIDADE
                        , DESC_FORNECPRIORIDADE
                        , CODDESC_FORNECPRIORIDADE
                        , QTSUGCOMPRA_D
                        , QTIMPORT_D
                        , EMB_POR_FORNECEDOR_O
                        , PRECO_TRANSF_O
                        , CODPROD_TRANSITO_O -- Código do Produto para Busca do Trânsito (sem inversão de códigos)
                        , DESCRICAO_TRANSITO_O
                        , INTEGRADORA
                        , NOMEINTEGRADORA
                        , QTOPERLOG_O
                        , QTOPERLOG_D
                        , INTEGRADORAESPELHONF
                        , NOMEINTEGRADORAESPELHONF
                        , INFOQUEBRAS
                        , FORMULA
                        , FORMULA_QT_SUGERIDA_D
                        , TIPOCUSTOTRANSF
                        , ESTMIN_O
                        , ESTOQUEMIN_O
                        , ESTOQUEMINSUG_O
                        , QTCANCESTOQUEMINSUG_O
                        , PEDIDOAVARIA
                        , ESTOQUEPORLOTE
                        , NUMLOTE
                        )
                  VALUES( D_DTGERACAO
                        , PRODUTO.CODFILIAL_O
                        , PRODUTO.CODFILIALRETIRA_O
                        , N_CODPROD_O
                        , V_DESCRICAO_O
                        , PRODUTO.CODMARCA_O
                        , PRODUTO.MARCA_O
                        , N_QTUNITCX_O
                        , NVL(V_QTD_EST_ORIG,0)
                        , NVL(N_QTD_TRANSFERIR_O,0)
                        , NVL(N_QTD_TRANSFERIR_O,0)
                        , PRODUTO.CODFILIAL_D
                        , PRODUTO.PRIORIDADE_D
                        , N_CODPROD_D
                        , V_DESCRICAO_D
                        , PRODUTO.TIPOSUGESTAO_D
                        , PRODUTO.DESCTIPOSUGESTAO_D
                        , CASE WHEN P_TIPO_SUGESTAO = 'L' THEN
                            PRODUTO.ESTOQUEMIN_D
                          ELSE
                            PRODUTO.ESTMIN_D
                          END
                        , CASE WHEN P_TIPO_SUGESTAO = 'L' THEN
                            PRODUTO.ESTOQUEMAX_D
                          ELSE
                            NULL
                          END
                        , NVL(V_QTD_EST_DEST,0)
                        , PRODUTO.QTPEDIDA_D
                        , NVL(N_QTD_TRANSITO_D,0)
                        , NVL(v_QTBLOQSEMAVARIA_D,0)
                        , PRODUTO.CLASSE_D
                        , PRODUTO.PMC_D
                        , N_PRECO_TRANSF_D
                        , N_PVENDA_D
                        , NVL(N_SUG_FRACIONADA_D,0)
                        , N_QTUNITCX_D
                        , N_PERCARREDONDA_D
                        , NVL(N_QTD_SUGERIDA_D,0)
                        , NVL(N_QTD_SUGERIDA_D,0)
                        , (NVL(N_QTD_SUGERIDA_D,0) * NVL(N_PRECO_TRANSF_D,0))
                        , V_CODEQUIPE
                        , PRODUTO.CODCATEGORIA_O
                        , NVL(PRODUTO.CODSEC_O,0)
                        , NVL(PRODUTO.CODEPTO_O,0)
                        , NVL(PRODUTO.CODFORNEC_O,0)
                        , PRODUTO.EMBALAGEM_O
                        , PRODUTO.UNIDADE_O
                        , V_TRIBUTACAO
                        , V_CODST
                        , PRODUTO.QTVENDMES_D
                        , PRODUTO.QTVENDMES1_D
                        , PRODUTO.QTVENDMES2_D
                        , PRODUTO.QTVENDMES3_D
                        , V_CODFAB_O
                        , V_CODFAB_D
                        , NVL(N_CODAUXILIAR_PCEMB_O,PRODUTO.CODAUXILIAR_O) -- HIS.01408.2016 - Tratamento para Considerar se Houver o Código EAN da PCEMBALAGEM que estará gravado em N_CODAUXILIAR_PCEMB_O
                        , PRODUTO.CODAUXILIAR_D
                        , V_QUEBRA1
                        , V_QUEBRA2
                        , V_QUEBRA3
                        , V_QUEBRA4
                        , PRODUTO.QTGIRODIA_D
                        , N_QTDIASREP_D
                        , PRODUTO.QTPENDENTE_D
                        , V_DESCCONSIDERAESTPENDSUG_D
                        , N_PRAZOENTREGA_O
                        , N_PERCARREDONDA_O
                        , N_CXFORNEC_TRANSFERIR_O
                        , P_TIPO_SUGESTAO
                        , NVL(V_TIPO_SUG_COMPRA_TRANSF,'T') -- Garantir o NOT NULL para não afetar as Quebras de Pedidos
                        , V_DESC_TIPO_SUG_COMPRA_TRANSF
                        , NVL(N_CODFORNECPRIORIDADE,0)      -- Garantir o NOT NULL para não afetar as Quebras de Pedidos
                        , V_DESC_FORNECPRIORIDADE
                        , V_CODDESC_FORNECPRIORIDADE
                        , NVL(PRODUTO.QTSUGCOMPRA_D,0)
                        , N_QTIMPORT_D
                        , V_EMB_POR_FORNECEDOR_O
                        , N_PRECO_TRANSF_O
                        , PRODUTO.CODPROD_O    -- Código do Produto para busca do Trânsito (sem inversão de códigos)
                        , PRODUTO.DESCRICAO_O  -- Descrição do Produto utilizado na busca do Trânsito (sem inversão de códigos)
                        , NVL(N_INTEGRADORA,0) -- Garantir o NOT NULL para não afetar as Quebras de Pedidos
                        , V_NOMEINTEGRADORA
                        , PRODUTO.QTOPERLOG_O
                        , N_QTOPERLOG_D
                        , NVL(N_INTEGRADORAESPELHONF,0) -- Garantir o NOT NULL para não afetar as Quebras de Pedidos
                        , V_NOMEINTEGRADORAESPELHONF
                        , V_INFOQUEBRAS
                        , V_FORMULA
                        , V_FORMULA_QT_SUGERIDA_D
                        , V_TIPOCUSTOTRANSF_APLICAR
                        , N_ESTMIN_O
                        , N_ESTOQUEMIN_O
                        , N_ESTOQUEMINSUG_O
                        , N_QTCANCESTOQUEMINSUG_O
                        , P_PEDIDOAVARIA
                        , PRODUTO.ESTOQUEPORLOTE
                        , NVL(V_NUMLOTE,'X')
                        );

              -- EFETIVA TRANSACOES A CADA 1000 ATUALIZACOES
              I_CONTA_COMMIT := NVL(I_CONTA_COMMIT,0) + 1;
              IF (I_CONTA_COMMIT  > 1000) THEN
                COMMIT;
                I_CONTA_COMMIT := 0;
              END IF;

            END LOOP; -- FIM: LAÇO DE LOTES

          END IF; -- FIM CONDICAO SE CONSIDERA O ITEM NA SUGESTAO

        END IF; -- FIM CONDICAO AGENDA VÁLIDA

      END LOOP; -- FIM LACO DE PRODUTOS

      -- EFETIVA TRANSACOES PENDENTES
      COMMIT;

    EXCEPTION
      WHEN e_TratadoLocal THEN
        ROLLBACK;
        po_vMsgErroTratado := '______________________________________' || CHR(13) || CHR(13) || 'ATENÇÃO: ' || CHR(13) || po_vMsgErroTratado || CHR(13) || '______________________________________';
    END PCALCULA_SUGESTAO;

  /*******************************************************************************
                        INICIO DO PROCEDIMENTO PRINCIPAL
   *******************************************************************************/
  BEGIN

    -- REGRA ESPECÍFICA - Ignorar Produto Master (HIS.00011.2018)
   /*
    BEGIN
      SELECT VALOR
        INTO vIGNORARPRODMASTER2312
        FROM PCREGRASEXCECAOMED
       WHERE (NOME      = 'IGNORARPRODMASTER2312')
         AND (CODFILIAL = '99');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vIGNORARPRODMASTER2312 := 'N';
    END;
    */
    ----------------------------------------------------
    -- Parâmetro da Reposição de Lojas - MED-1896
    ----------------------------------------------------
    BEGIN
      SELECT VALOR
        INTO vIGNORARPRODMASTER2312
        FROM PCPARAMREPOSICAOLOJAS
       WHERE (NOME      = 'IGNORARPRODMASTER2312')
         AND (CODFILIAL = '99');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vIGNORARPRODMASTER2312 := NULL;
    END;

    -- REGRA ESPECÍFICA - Ignorar Qtde. Pedida (HIS.00005.2018)
   /*
    BEGIN
      SELECT VALOR
        INTO vIGNORARQTPEDIDA2312
        FROM PCREGRASEXCECAOMED
       WHERE (NOME      = 'IGNORARQTPEDIDA2312')
         AND (CODFILIAL = '99');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vIGNORARQTPEDIDA2312 := 'N';
    END;
    */
    ----------------------------------------------------
    -- Parâmetro da Reposição de Lojas - MED-1896
    ----------------------------------------------------
    BEGIN
      SELECT VALOR
        INTO vIGNORARQTPEDIDA2312
        FROM PCPARAMREPOSICAOLOJAS
       WHERE (NOME      = 'IGNORARQTPEDIDA2312')
         AND (CODFILIAL = '99');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vIGNORARQTPEDIDA2312 := NULL;
    END;

    ----------------------------------------------------------------------------
    -- REGRA ESPECÍFICA - Quantidade de dias para analisar o estoque em trânsito
    ----------------------------------------------------------------------------
    BEGIN
      SELECT TO_NUMBER(NVL(VALOR,'0'))
        INTO nQTDEDIASESTOQUETRANSITO
        FROM PCPARAMREPOSICAOLOJAS
       WHERE (NOME      = 'QTDEDIASESTOQUETRANSITO')
         AND (CODFILIAL = '99');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        nQTDEDIASESTOQUETRANSITO := 0;
      WHEN OTHERS THEN
        nQTDEDIASESTOQUETRANSITO := 0;
    END;
    POBTEM_PARAMFILIAL_STRING(P_CODFILIAL_ORIGEM,'DESCSTFORAUFTRANSF',
                                vDESCSTFORAUFTRANSF,vvErroPesqParam1,
                                vvMsgErroPesqParam1);


    IF (P_CODFILIAL_DESTINO IS NOT NULL) THEN
      BEGIN
      vSQL := 'SELECT UF
         FROM PCFILIAL
         WHERE (PCFILIAL.CODIGO in ('||P_CODFILIAL_DESTINO||'))
         AND ROWNUM = 1';
      EXECUTE IMMEDIATE vSQL INTO vUFDestino;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vUFDestino := NULL;

      END;
      ELSE
    vUFDestino := NULL;
    END IF;


       BEGIN
       SELECT UF
       INTO  vUFORIGEM
       FROM PCFILIAL
       WHERE (PCFILIAL.CODIGO = P_CODFILIAL_ORIGEM);
       EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vUFORIGEM := NULL;
     END;

   /*****************************************************
    Se Geração da Reposição de forma Automática ou Manual
    *****************************************************/
    IF    (NVL(P_AUTOMATICO_MANUAL,'M') IN ('A','M')) THEN

     /**************************************
      Tabela temporária de Dados da Sugestão
      **************************************/

      -- Limpa Tabela Temporária
      EXECUTE IMMEDIATE 'TRUNCATE TABLE PCMED_TEMP_ESTDESTINO';

      -- Prepara SQL
      IF (NVL(vIGNORARPRODMASTER2312,'N') = 'S') THEN
        -- OBS: Importante o DISTINCT por causa da inversão do código do produto master pelo código do produto
        vSqlEstDestino :=
        ' INSERT INTO PCMED_TEMP_ESTDESTINO
          (SELECT DISTINCT
                  FD.CODIGO CODFILIAL_D
                , PD.CODPROD CODPROD_D
                , ''' || P_CODFILIAL_ORIGEM || ''' CODFILIAL_O
                , PD.CODPROD CODPROD_O ';
      ELSE
        vSqlEstDestino :=
        ' INSERT INTO PCMED_TEMP_ESTDESTINO
          (SELECT FD.CODIGO CODFILIAL_D
                , PD.CODPROD CODPROD_D
                , ''' || P_CODFILIAL_ORIGEM || ''' CODFILIAL_O
                , NVL(PD.CODPRODMASTER,PD.CODPROD) CODPROD_O ';
      END IF;
      --
      IF (NVL(vIGNORARQTPEDIDA2312,'N') = 'S') THEN
        vSqlEstDestino := vSqlEstDestino ||
        '       , FD.CODGRUPOLOJA CODGRUPOLOJA_D
                , FD.CODCLI CODCLI_D
                , PD.CODMARCA CODMARCA_D
                , MD.MARCA MARCA_D
                , PD.CODCATEGORIA CODCATEGORIA_D
                , PD.CODSEC CODSEC_D
                , PD.CODEPTO CODEPTO_D
                , PD.CODFORNEC CODFORNEC_D
                , PD.DESCRICAO DESCRICAO_D
                , PD.EMBALAGEM EMBALAGEM_D
                , PD.UNIDADE UNIDADE_D
                , NVL(PD.QTUNITCX,1) QTUNITCX_D
                , NVL(ED.QTESTGER,0) QTESTGER_D
                , NVL(ED.QTRESERV,0) QTRESERV_D
                , NVL(ED.QTBLOQUEADA,0) QTBLOQUEADA_D
                , NVL(ED.QTINDENIZ,0) QTINDENIZ_D
                , NVL(PFD.ESTOQUEMIN,0) ESTOQUEMIN_D
                , NVL(PFD.ESTOQUEMAX,0) ESTOQUEMAX_D
                , 0 QTPEDIDA_D ';
      ELSE
        vSqlEstDestino := vSqlEstDestino ||
        '       , FD.CODGRUPOLOJA CODGRUPOLOJA_D
                , FD.CODCLI CODCLI_D
                , PD.CODMARCA CODMARCA_D
                , MD.MARCA MARCA_D
                , PD.CODCATEGORIA CODCATEGORIA_D
                , PD.CODSEC CODSEC_D
                , PD.CODEPTO CODEPTO_D
                , PD.CODFORNEC CODFORNEC_D
                , PD.DESCRICAO DESCRICAO_D
                , PD.EMBALAGEM EMBALAGEM_D
                , PD.UNIDADE UNIDADE_D
                , NVL(PD.QTUNITCX,1) QTUNITCX_D
                , NVL(ED.QTESTGER,0) QTESTGER_D
                , NVL(ED.QTRESERV,0) QTRESERV_D
                , NVL(ED.QTBLOQUEADA,0) QTBLOQUEADA_D
                , NVL(ED.QTINDENIZ,0) QTINDENIZ_D
                , NVL(PFD.ESTOQUEMIN,0) ESTOQUEMIN_D
                , NVL(PFD.ESTOQUEMAX,0) ESTOQUEMAX_D
                , NVL(ED.QTPEDIDA,0) QTPEDIDA_D ';
      END IF;
      --
      vSqlEstDestino := vSqlEstDestino ||
      '       , CASE WHEN (NVL(CL.TIPOCUSTOTRANSF,'' '') = ''E'') THEN
                       NVL(ED.CUSTOREP,0)
                     WHEN (NVL(CL.TIPOCUSTOTRANSF,'' '') = ''R'')
           AND  '''||vDESCSTFORAUFTRANSF||''' = ''S'' AND '''||(vUfOrigem|| ''' <>'''|| vUfDestino)||''' THEN
                        NVL(ED.CUSTOREALSEMST,0)
           WHEN  (NVL(CL.TIPOCUSTOTRANSF,'' '') = ''R'') THEN
            NVL(ED.CUSTOREAL,0)
                     WHEN (NVL(CL.TIPOCUSTOTRANSF,'' '') = ''C'')  THEN
                       NVL(ED.CUSTOCONT,0)
                     WHEN (NVL(CL.TIPOCUSTOTRANSF,'' '') = ''F'')
               AND  '''||vDESCSTFORAUFTRANSF||''' = ''S'' AND '''||(vUfOrigem|| ''' <>'''|| vUfDestino)||''' THEN
                         NVL(ED.CUSTOFINSEMST,0)
           WHEN (NVL(CL.TIPOCUSTOTRANSF,'' '') = ''F'') THEN
            NVL(ED.CUSTOFIN,0)
                     WHEN (NVL(CL.TIPOCUSTOTRANSF,'' '') = ''U'') THEN
                       NVL(ED.CUSTOULTENT,0)
                     WHEN (NVL(CL.TIPOCUSTOTRANSF,'' '') = ''V'') THEN
                       NVL(ED.VALORULTENT,0)
                     WHEN (NVL(CL.TIPOCUSTOTRANSF,'' '') = ''S'') THEN
                       NVL(ED.CUSTOREALSEMST,0)
                     WHEN (NVL(CL.TIPOCUSTOTRANSF,'' '') = ''T'') THEN
                       NVL(ED.VLULTENTCONTSEMST,0)
                     WHEN (NVL(CL.TIPOCUSTOTRANSF,'' '') = ''O'') THEN
                       NVL(ED.CUSTOFORNEC,0)
                     WHEN (NVL(CL.TIPOCUSTOTRANSF,'' '') = ''A'') THEN
                       NVL(ED.CUSTOULTENT,0)
                     ELSE
                       NVL(ED.CUSTOULTENT,0)
                END CUSTOULTENT_D
              , NVL(PFD.PERCARREDONDA,0) PERCARREDONDA_D
              , PFD.TIPOSUGESTAO TIPOSUGESTAO_D
              , DECODE(' || NVL(P_TIPOCLASSE,0) || ',0,PFD.CLASSEVENDA,PFD.CLASSEVENDAQT) CLASSE_D
              , (CASE WHEN NVL(RG.REGIAOZFM, ''N'') = ''N'' THEN PD.PRECOMAXCONSUM ELSE PD.PRECOMAXCONSUMZFM END) PMC_D
              , TB.PVENDA PVENDA_D
              , ED.QTVENDMES
              , ED.QTVENDMES1
              , ED.QTVENDMES2
              , ED.QTVENDMES3
              , ED.QTPENDENTE
              , PD.CODFAB
              , PD.CODAUXILIAR
              , ED.QTGIRODIA
              , ED.ESTMIN
              , PFD.ESTOQUEIDEAL
              , ''' || NVL(P_CODFILIALRETIRA,P_CODFILIAL_ORIGEM) || ''' CODFILIALRETIRA_O
           FROM PCPRODUT PD
              , PCMARCA MD
              , PCEST ED
              , PCFILIAL FD
              , PCPRODFILIAL PFD
              , PCCLIENT CL
              , PCPRACA PR
              , PCREGIAO RG
              , PCTABPR TB
          WHERE ED.CODPROD = PD.CODPROD
            AND ED.CODFILIAL = FD.CODIGO
            AND PD.CODMARCA = MD.CODMARCA(+)
            AND PFD.CODPROD = ED.CODPROD
            AND PFD.CODFILIAL = ED.CODFILIAL
            AND PD.TIPOMERC   <> ''CB'' '; -- DDMEDICA-6697
      -- Se passou o Grupo de Loja do Destino
      IF (TRIM(P_CODGRUPOLOJA) IS NOT NULL) THEN
        vSqlEstDestino := vSqlEstDestino ||
          ' AND FD.CODGRUPOLOJA IN ('      || P_CODGRUPOLOJA || ')';
      END IF;
      -- Se passou a Filial de Destino
      IF (TRIM(P_CODFILIAL_DESTINO) IS NOT NULL) THEN
        vSqlEstDestino := vSqlEstDestino ||
          ' AND FD.CODIGO IN ('          ||  P_CODFILIAL_DESTINO || ')';
      END IF;
      -- Não carrega a Filial de Destino que é igual à de Origem (Caso Multiseleção)
      vSqlEstDestino := vSqlEstDestino ||
        ' AND FD.CODIGO <> '           ||  '''' || P_CODFILIAL_ORIGEM || '''';
      -- Se passou o Código do Produto
      IF (TRIM(P_PRODUTO) IS NOT NULL) THEN
        vSqlEstDestino := vSqlEstDestino ||
          ' AND PD.CODPROD IN ('         || P_PRODUTO || ')';
      END IF;
      -- Se passou o Código o Departamento
      IF (TRIM(P_DEPARTAMENTO) IS NOT NULL) THEN
        vSqlEstDestino := vSqlEstDestino ||
          ' AND PD.CODEPTO IN ('         || P_DEPARTAMENTO || ')';
      END IF;
      -- Se passou a Seção
      IF (TRIM(P_SECAO) IS NOT NULL) THEN
        vSqlEstDestino := vSqlEstDestino ||
          ' AND PD.CODSEC IN ( '         || P_SECAO || ')';
      END IF;
      -- Se passou a Categoria
      IF (TRIM(P_CATEGORIA) IS NOT NULL) THEN
        vSqlEstDestino := vSqlEstDestino ||
          ' AND PD.CODCATEGORIA IN ('    || P_CATEGORIA || ')';
      END IF;
      -- Se passou a Marca
      IF (TRIM(P_SUBCATEGORIA) IS NOT NULL) THEN
        vSqlEstDestino := vSqlEstDestino ||
          ' AND PD.CODSUBCATEGORIA IN (' || P_SUBCATEGORIA || ')';
      END IF;
      -- Se passou a Marca
      IF (TRIM(P_MARCA) IS NOT NULL) THEN
        vSqlEstDestino := vSqlEstDestino ||
          ' AND PD.CODMARCA IN ('        || P_MARCA || ')';
      END IF;
      -- Se passou o Fornecedor
      IF (TRIM(P_FORNECEDOR) IS NOT NULL) THEN
        vSqlEstDestino := vSqlEstDestino ||
          ' AND PD.CODFORNEC IN ('       || P_FORNECEDOR || ')';
      END IF;
      -- Se passou a Linha
      IF (TRIM(P_LINHAPRODUTO) IS NOT NULL) THEN
        vSqlEstDestino := vSqlEstDestino ||
          ' AND PD.CODLINHAPROD IN ('    || P_LINHAPRODUTO || ')';
      END IF;
      -- Se passou a Classe
      IF (TRIM(P_CLASSE) IS NOT NULL) THEN
        IF (NVL(P_TIPOCLASSE,0) = 0) THEN
          vSqlEstDestino := vSqlEstDestino ||
            ' AND PFD.CLASSEVENDA IN ('         || P_CLASSE || ')';
        ELSE
          vSqlEstDestino := vSqlEstDestino ||
            ' AND PFD.CLASSEVENDAQT IN ('       || P_CLASSE || ')';
        END IF;
      END IF;
      -- Se passou a Unidade
      IF (TRIM(P_UNIDADE) IS NOT NULL) THEN
        vSqlEstDestino := vSqlEstDestino ||
          ' AND PD.UNIDADE IN ('         || P_UNIDADE || ')';
      END IF;
      -- Se passou Psicotropico
      IF (TRIM(P_PSICOTROPICO) IS NOT NULL) THEN
        vSqlEstDestino := vSqlEstDestino ||
          ' AND PD.PSICOTROPICO IN ('    || P_PSICOTROPICO || ')';
      END IF;
      -- Se passou Tipo Tribut. Medic.
      IF (TRIM(P_TIPOTRIBUTMEDIC) IS NOT NULL) THEN
        vSqlEstDestino := vSqlEstDestino ||
          ' AND PD.TIPOTRIBUTMEDIC IN (' || P_TIPOTRIBUTMEDIC || ')';
      END IF;
      -- Se Considera Produtos Fora de Linha
      IF (P_FORALINHA = 'N') THEN
        -- Quando não considera produtos fora da linha,
        -- restringe somente a produtos que não estão fora da Linha
        vSqlEstDestino := vSqlEstDestino ||
          ' AND NVL(PFD.FORALINHA,''N'') = ''N''';
      END IF;
      -- Se passou o Comprador da Marca
      IF (TRIM(P_COMPRADOR_MARCA) IS NOT NULL) THEN
        vSqlEstDestino := vSqlEstDestino ||
          ' AND MD.CODCOMPRADOR IN ('    || P_COMPRADOR_MARCA || ')';
      END IF;
      -- Continua as Condições do Sql
      vSqlEstDestino := vSqlEstDestino ||
          ' AND CL.CODCLI = FD.CODCLI
            AND PR.CODPRACA = CL.CODPRACA
            AND RG.NUMREGIAO = PR.NUMREGIAO
            AND TB.CODPROD = PD.CODPROD
            AND TB.NUMREGIAO = RG.NUMREGIAO
            AND NVL(PFD.PROIBIDAVENDA,''N'') = ''N''
            AND PFD.ATIVO = ''S'' ';
      -- Condição de Importação
      IF (P_IMPORTA_QTDE_TRANSF = 'S') THEN
        vSqlEstDestino := vSqlEstDestino ||
          ' AND EXISTS (SELECT 1
                          FROM PCMED_TEMP_IMPORT_ATAC_VAR
                         WHERE PCMED_TEMP_IMPORT_ATAC_VAR.CODPROD_D   = PD.CODPROD
                           AND PCMED_TEMP_IMPORT_ATAC_VAR.CODFILIAL_D = FD.CODIGO) ';
      END IF;
      -- Finaliza o Sql
      vSqlEstDestino := vSqlEstDestino || ')';

      -- Insere na Tabela Temporária
      EXECUTE IMMEDIATE vSqlEstDestino;

     /**********************************************
      Tabela temporária de Estoque em Trânsito
      TRANSITO = ESTOQUE BAIXADO NA FILIAL DE ORIGEM
                 QUE AINDA NAO DEU ENTRADA NO ESTOQUE
                 NA FILIAL DE DESTINO
      * FILIAL DE DESTINO - Encontrada através do
        Código do Cliente do Pedido.
        Através do Código do Cliente do Pedido, se
        acha o Código da Filial na PCFILIAL, onde
        PCFILIAL.CODCLI = PCPEDC.CODCLI
     ***********************************************/

      -- Limpa Tabela Temporária
      EXECUTE IMMEDIATE 'TRUNCATE TABLE PCMED_TEMP_ESTTRANSITO';

      vSqlEstTransito := '
        INSERT INTO PCMED_TEMP_ESTTRANSITO
        (
            SELECT X.CODFILIAL
                 , X.CODPROD
                 , SUM(X.QTTRANSITO) QTTRANSITO
                 , X.CODIGO
              FROM ( ';

      -- Prepara SQL com o Filtro de Produto
      IF (TRIM(P_PRODUTO) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                       SELECT PCPEDC.CODFILIAL
                            , PCPEDI.CODPROD
                            , PCPEDI.QT QTTRANSITO
                            , PCFILIAL.CODIGO
                         FROM PCPEDC
                            , PCPEDI
                            , PCFILIAL
                            , PCPRODUT';
            IF (TRIM(P_MARCA) IS NOT NULL) THEN
                vSqlEstTransito := vSqlEstTransito || ', PCMARCA ';
            END IF;
            vSqlEstTransito := vSqlEstTransito || '
                            , PCPRODUT TAB_PROD_FILHO
                        WHERE (   (NVL((SELECT PCPARAMFILIAL.VALOR
                                          FROM PCPARAMFILIAL
                                         WHERE PCPARAMFILIAL.CODFILIAL = PCFILIAL.CODIGO
                                           AND PCPARAMFILIAL.NOME = ''CONSIDERAQTDTRANSITOCOMPRAFILIAL''), ''N'') = ''N''
                                   AND PCPEDC.POSICAO IN (''B'', ''M'', ''L'', ''F''))
                               OR (NVL((SELECT PCPARAMFILIAL.VALOR
                                          FROM PCPARAMFILIAL
                                         WHERE PCPARAMFILIAL.CODFILIAL = PCFILIAL.CODIGO
                                           AND PCPARAMFILIAL.NOME = ''CONSIDERAQTDTRANSITOCOMPRAFILIAL''), ''N'') = ''S''
                                   AND PCPEDC.POSICAO IN (''B'', ''M'', ''L''))
                              )
                          AND PCPEDC.CONDVENDA = 10
                          AND PCPEDC.DTCANCEL IS NULL
                          AND PCPEDC.CODCLI = PCFILIAL.CODCLI
                          AND PCPEDI.NUMPED = PCPEDC.NUMPED
                          AND PCPEDC.SISTEMALEGADO IS NULL
                          AND PCPEDC.DTCANCEL IS NULL
                          AND PCPRODUT.CODPROD = PCPEDI.CODPROD';
        IF (TRIM(P_MARCA) IS NOT NULL) THEN
           vSqlEstTransito := vSqlEstTransito || '               AND PCPRODUT.CODMARCA = PCMARCA.CODMARCA(+) ';
        END IF;
        IF (NVL(vIGNORARPRODMASTER2312,'N') = 'S') THEN
          vSqlEstTransito := vSqlEstTransito || '
                          AND TAB_PROD_FILHO.CODPROD = PCPRODUT.CODPROD ';
        ELSE
          vSqlEstTransito := vSqlEstTransito || '
                          AND TAB_PROD_FILHO.CODPRODMASTER = PCPRODUT.CODPROD ';
        END IF;
      -- Prepara SQL sem o Filtro de Produto
      ELSE
        vSqlEstTransito := vSqlEstTransito || '
                       SELECT PCPEDC.CODFILIAL
                            , PCPEDI.CODPROD
                            , PCPEDI.QT QTTRANSITO
                            , PCFILIAL.CODIGO
                         FROM PCPEDC
                            , PCPEDI
                            , PCFILIAL
                            , PCPRODUT ';
            IF (TRIM(P_MARCA) IS NOT NULL) THEN
                vSqlEstTransito := vSqlEstTransito || ', PCMARCA ';
            END IF;
            vSqlEstTransito := vSqlEstTransito || '
                        WHERE (   (NVL((SELECT PCPARAMFILIAL.VALOR
                                          FROM PCPARAMFILIAL
                                         WHERE PCPARAMFILIAL.CODFILIAL = PCFILIAL.CODIGO
                                           AND PCPARAMFILIAL.NOME = ''CONSIDERAQTDTRANSITOCOMPRAFILIAL''), ''N'') = ''N''
                                   AND PCPEDC.POSICAO IN (''B'', ''M'', ''L'', ''F''))
                               OR (NVL((SELECT PCPARAMFILIAL.VALOR
                                          FROM PCPARAMFILIAL
                                         WHERE PCPARAMFILIAL.CODFILIAL = PCFILIAL.CODIGO
                                           AND PCPARAMFILIAL.NOME = ''CONSIDERAQTDTRANSITOCOMPRAFILIAL''), ''N'') = ''S''
                                   AND PCPEDC.POSICAO IN (''B'', ''M'', ''L''))
                              )
                          AND PCPEDC.CONDVENDA = 10
                          AND PCPEDC.DTCANCEL IS NULL
                          AND PCPEDC.CODCLI = PCFILIAL.CODCLI
                          AND PCPEDI.NUMPED = PCPEDC.NUMPED
                          AND PCPEDC.SISTEMALEGADO IS NULL
                          AND PCPEDC.DTCANCEL IS NULL
                          AND PCPRODUT.CODPROD = PCPEDI.CODPROD ';
               IF (TRIM(P_MARCA) IS NOT NULL) THEN
                  vSqlEstTransito := vSqlEstTransito || '        AND PCPRODUT.CODMARCA = PCMARCA.CODMARCA(+) ';
               END IF;
      END IF;

      -- Filial de Origem = OBRIGATORIO
      vSqlEstTransito := vSqlEstTransito || '
                          AND PCPEDC.CODFILIAL = ' || '''' || P_CODFILIAL_ORIGEM || '''';

      -- Se passou o Grupo de Loja do Destino
      IF (TRIM(P_CODGRUPOLOJA) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCFILIAL.CODGRUPOLOJA IN (' || P_CODGRUPOLOJA || ')';
      END IF;

      -- Se passou a Filial de Destino
      IF (TRIM(P_CODFILIAL_DESTINO) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCFILIAL.CODIGO IN (' || P_CODFILIAL_DESTINO || ')';
      END IF;

      -- Não carrega a Filial de Destino que é iguail à de Origem (Caso Multiseleção)
      vSqlEstTransito := vSqlEstTransito || '
                          AND PCFILIAL.CODIGO <> ' || '''' || P_CODFILIAL_ORIGEM || '''';
      -- Se passou o Código do Produto FILHO
      IF (TRIM(P_PRODUTO) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND TAB_PROD_FILHO.CODPROD IN (' || P_PRODUTO || ')';
      END IF;

      -- Se passou o Código o Departamento
      IF (TRIM(P_DEPARTAMENTO) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCPRODUT.CODEPTO IN (' || P_DEPARTAMENTO || ')';
      END IF;

      -- Se passou a Seção
      IF (TRIM(P_SECAO) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCPRODUT.CODSEC IN (' || P_SECAO || ')';
      END IF;

      -- Se passou a Categoria
      IF (TRIM(P_CATEGORIA) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCPRODUT.CODCATEGORIA IN (' || P_CATEGORIA || ')';
      END IF;

      -- Se passou a Marca
      IF (TRIM(P_SUBCATEGORIA) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCPRODUT.CODSUBCATEGORIA IN (' || P_SUBCATEGORIA || ')';
      END IF;

      -- Se passou a Marca
      IF (TRIM(P_MARCA) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCPRODUT.CODMARCA IN (' || P_MARCA || ')';
      END IF;

      -- Se passou o Fornecedor
      IF (TRIM(P_FORNECEDOR) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCPRODUT.CODFORNEC IN (' || P_FORNECEDOR || ')';
      END IF;

      -- Se passou a Linha
      IF (TRIM(P_LINHAPRODUTO) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCPRODUT.CODLINHAPROD IN (' || P_LINHAPRODUTO || ')';
      END IF;

      -- Se passou a Unidade
      IF (TRIM(P_UNIDADE) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCPRODUT.UNIDADE IN (' || P_UNIDADE || ')';
      END IF;

      -- Se passou Psicotropico
      IF (TRIM(P_PSICOTROPICO) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCPRODUT.PSICOTROPICO IN (' || P_PSICOTROPICO || ')';
      END IF;

      -- Se passou Tipo Tribut. Medic.
      IF (TRIM(P_TIPOTRIBUTMEDIC) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCPRODUT.TIPOTRIBUTMEDIC IN (' || P_TIPOTRIBUTMEDIC || ')';
      END IF;

      -- Se passou o Comprador da Marca
      IF (TRIM(P_COMPRADOR_MARCA) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCMARCA.CODCOMPRADOR IN (' || P_COMPRADOR_MARCA || ')';
      END IF;

      -- Condição de Importação
      IF (P_IMPORTA_QTDE_TRANSF = 'S') THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND EXISTS (SELECT 1
                                        FROM PCMED_TEMP_IMPORT_ATAC_VAR
                                       WHERE PCMED_TEMP_IMPORT_ATAC_VAR.CODPROD_D   = PCPRODUT.CODPROD
                                         AND PCMED_TEMP_IMPORT_ATAC_VAR.CODFILIAL_D = PCFILIAL.CODIGO) ';
      END IF;

      -- REGRA ESPECÍFICA - Quantidade de dias para analisar o estoque em trânsito
      IF (NVL(nQTDEDIASESTOQUETRANSITO,0) > 0) THEN
        vSqlEstTransito := vSqlEstTransito     || '
                          AND PCPEDC.DATA >= TRUNC(SYSDATE) - ' || NVL(nQTDEDIASESTOQUETRANSITO,0);
      END IF;

      -- Finaliza o SQL
      vSqlEstTransito := vSqlEstTransito || '
                          AND NOT EXISTS (SELECT 1
                                            FROM PCPEDIDO
                                           WHERE NUMTRANSVENDA = PCPEDC.NUMTRANSVENDA)
                       UNION ALL ';

      IF (TRIM(P_PRODUTO) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                       SELECT PCFILIAL.CODIGO CODFILIAL_ORIGEM
                            , PCEST.CODPROD
                            , NVL(PCEST.QTTRANSITOTV10, 0) QTTRANSITO
                            , PCEST.CODFILIAL CODIGO_DESTINO
                         FROM PCEST
                            , PCFILIAL
                            , PCPRODUT';
      IF (TRIM(P_MARCA) IS NOT NULL) THEN
         vSqlEstTransito := vSqlEstTransito || '                   , PCMARCA ';
      END IF;
      vSqlEstTransito := vSqlEstTransito || '                    , PCFILIAL PCFILIAL_D
                            , PCPRODUT TAB_PROD_FILHO
                        WHERE NVL((SELECT PCPARAMFILIAL.VALOR
                                     FROM PCPARAMFILIAL
                                    WHERE PCPARAMFILIAL.CODFILIAL = PCFILIAL.CODIGO
                                      AND PCPARAMFILIAL.NOME = ''CONSIDERAQTDTRANSITOCOMPRAFILIAL''), ''N'') = ''S''
                          AND PCEST.CODFILIAL <> PCFILIAL.CODIGO
                          AND PCEST.CODPROD = PCPRODUT.CODPROD ';
        IF (TRIM(P_MARCA) IS NOT NULL) THEN
           vSqlEstTransito := vSqlEstTransito || '                AND PCPRODUT.CODMARCA = PCMARCA.CODMARCA(+)';
        END IF;
        vSqlEstTransito := vSqlEstTransito || '                  AND PCEST.CODFILIAL = PCFILIAL_D.CODIGO ';

        IF (NVL(vIGNORARPRODMASTER2312,'N') = 'S') THEN
          vSqlEstTransito := vSqlEstTransito || '
                          AND TAB_PROD_FILHO.CODPROD = PCPRODUT.CODPROD ';
        ELSE
          vSqlEstTransito := vSqlEstTransito || '
                          AND TAB_PROD_FILHO.CODPRODMASTER = PCPRODUT.CODPROD ';
        END IF;
      ELSE
        vSqlEstTransito := vSqlEstTransito || '
                       SELECT PCFILIAL.CODIGO CODFILIAL_ORIGEM
                            , PCEST.CODPROD
                            , NVL(PCEST.QTTRANSITOTV10, 0) QTTRANSITO
                            , PCEST.CODFILIAL CODIGO_DESTINO
                         FROM PCEST
                            , PCFILIAL
                            , PCPRODUT';
          IF (TRIM(P_MARCA) IS NOT NULL) THEN
             vSqlEstTransito := vSqlEstTransito || '               , PCMARCA';
          END IF;
          vSqlEstTransito := vSqlEstTransito || '                  , PCFILIAL PCFILIAL_D
                            , PCPRODUT TAB_PROD_FILHO
                        WHERE NVL((SELECT PCPARAMFILIAL.VALOR
                                     FROM PCPARAMFILIAL
                                    WHERE PCPARAMFILIAL.CODFILIAL = PCFILIAL.CODIGO
                                      AND PCPARAMFILIAL.NOME = ''CONSIDERAQTDTRANSITOCOMPRAFILIAL''), ''N'') = ''S''
                          AND PCEST.CODFILIAL <> PCFILIAL.CODIGO
                          AND PCEST.CODPROD = PCPRODUT.CODPROD ';
          IF (TRIM(P_MARCA) IS NOT NULL) THEN
             vSqlEstTransito := vSqlEstTransito || '             AND PCPRODUT.CODMARCA = PCMARCA.CODMARCA(+)';
          END IF;
          vSqlEstTransito := vSqlEstTransito || '            AND PCEST.CODFILIAL = PCFILIAL_D.CODIGO ';
      END IF;

      -- Filial de Origem = OBRIGATORIO
      vSqlEstTransito := vSqlEstTransito || '
                          AND PCFILIAL.CODIGO = ' || '''' || P_CODFILIAL_ORIGEM || '''';

      -- Se passou o Grupo de Loja do Destino
      IF (TRIM(P_CODGRUPOLOJA) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCFILIAL_D.CODGRUPOLOJA IN (' || P_CODGRUPOLOJA || ')';
      END IF;

      -- Se passou a Filial de Destino
      IF (TRIM(P_CODFILIAL_DESTINO) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCFILIAL_D.CODIGO IN (' ||  P_CODFILIAL_DESTINO || ')';
      END IF;

      IF (TRIM(P_PRODUTO) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND TAB_PROD_FILHO.CODPROD IN (' || P_PRODUTO || ')';
      END IF;

      -- Se passou o Código o Departamento
      IF (TRIM(P_DEPARTAMENTO) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCPRODUT.CODEPTO IN (' || P_DEPARTAMENTO || ')';
      END IF;

      -- Se passou a Seção
      IF (TRIM(P_SECAO) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCPRODUT.CODSEC IN (' || P_SECAO || ')';
      END IF;

      -- Se passou a Categoria
      IF (TRIM(P_CATEGORIA) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCPRODUT.CODCATEGORIA IN (' || P_CATEGORIA || ')';
      END IF;

      -- Se passou a Marca
      IF (TRIM(P_SUBCATEGORIA) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCPRODUT.CODSUBCATEGORIA IN (' || P_SUBCATEGORIA || ')';
      END IF;

      -- Se passou a Marca
      IF (TRIM(P_MARCA) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCPRODUT.CODMARCA IN (' || P_MARCA || ')';
      END IF;

      -- Se passou o Fornecedor
      IF (TRIM(P_FORNECEDOR) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCPRODUT.CODFORNEC IN (' || P_FORNECEDOR || ')';
      END IF;

      -- Se passou a Linha
      IF (TRIM(P_LINHAPRODUTO) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCPRODUT.CODLINHAPROD IN (' || P_LINHAPRODUTO || ')';
      END IF;

      -- Se passou a Unidade
      IF (TRIM(P_UNIDADE) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCPRODUT.UNIDADE IN (' || P_UNIDADE || ')';
      END IF;

      -- Se passou Psicotropico
      IF (TRIM(P_PSICOTROPICO) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCPRODUT.PSICOTROPICO IN (' || P_PSICOTROPICO || ')';
      END IF;

      -- Se passou Tipo Tribut. Medic.
      IF (TRIM(P_TIPOTRIBUTMEDIC) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCPRODUT.TIPOTRIBUTMEDIC IN (' || P_TIPOTRIBUTMEDIC || ')';
      END IF;

      -- Se passou o Comprador da Marca
      IF (TRIM(P_COMPRADOR_MARCA) IS NOT NULL) THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND PCMARCA.CODCOMPRADOR IN (' || P_COMPRADOR_MARCA || ')';
      END IF;

      -- Condição de Importação
      IF (P_IMPORTA_QTDE_TRANSF = 'S') THEN
        vSqlEstTransito := vSqlEstTransito || '
                          AND EXISTS (SELECT 1
                                        FROM PCMED_TEMP_IMPORT_ATAC_VAR
                                       WHERE PCMED_TEMP_IMPORT_ATAC_VAR.CODPROD_D   = PCPRODUT.CODPROD
                                         AND PCMED_TEMP_IMPORT_ATAC_VAR.CODFILIAL_D = PCFILIAL_D.CODIGO) ';
      END IF;

      -- Finaliza o SQL
      vSqlEstTransito := vSqlEstTransito || '
                   ) X
            GROUP BY X.CODFILIAL
                   , X.CODPROD
                   , X.CODIGO
        )';

      -- Insere na Tabela Temporária
      EXECUTE IMMEDIATE vSqlEstTransito;

     /****************************************************
      Tabela temporária de Estoque de Operador Logistico
      PEDIDOS OL = Pedidos feitos para a Indústria,
                   aguardando a importação do pedido de OL
      * FILIAL ORIGEM - Código do Fornecedor do Pedido OL
      * FILIAL DE DESTINO - Filial do Pedido OL
     ***********************************************/

      -- Limpa Tabela Temporária
      EXECUTE IMMEDIATE 'TRUNCATE TABLE PCMED_TEMP_ESTOPERLOG';

      -- Prepara SQL com o Filtro de Produto
      IF (TRIM(P_PRODUTO) IS NOT NULL) THEN
        vSqlEstOperLog :=
        ' INSERT INTO PCMED_TEMP_ESTOPERLOG
          (SELECT FILIALORIGEM.CODIGO
                , PCPEDCOMPRAOPERLOGITE.CODPROD
                , SUM(PCPEDCOMPRAOPERLOGITE.QTPED) QTOPERLOG
                , FILIALDESTINO.CODIGO
             FROM PCPEDCOMPRAOPERLOGCAB
                , PCPEDCOMPRAOPERLOGITE
                , PCFILIAL FILIALORIGEM
                , PCFILIAL FILIALDESTINO
                , PCPRODUT
                , PCMARCA
                , PCPRODUT TAB_PROD_FILHO
            WHERE PCPEDCOMPRAOPERLOGCAB.NUMPED = PCPEDCOMPRAOPERLOGITE.NUMPED
              AND FILIALORIGEM.CODFORNEC = PCPEDCOMPRAOPERLOGCAB.CODFORNEC
              AND FILIALDESTINO.CODIGO = PCPEDCOMPRAOPERLOGCAB.CODFILIAL
              AND PCPEDCOMPRAOPERLOGCAB.SITUACAO IN (''P'',''A'')
              AND PCPRODUT.CODPROD = PCPEDCOMPRAOPERLOGITE.CODPROD
              AND PCPRODUT.CODMARCA = PCMARCA.CODMARCA(+) ';
        IF (NVL(vIGNORARPRODMASTER2312,'N') = 'S') THEN
          vSqlEstOperLog := vSqlEstOperLog || ' AND TAB_PROD_FILHO.CODPROD = PCPRODUT.CODPROD ';
        ELSE
          vSqlEstOperLog := vSqlEstOperLog || ' AND TAB_PROD_FILHO.CODPRODMASTER = PCPRODUT.CODPROD ';
        END IF;
      -- Prepara SQL sem o Filtro de Produto
      ELSE
        vSqlEstOperLog :=
        ' INSERT INTO PCMED_TEMP_ESTOPERLOG
          (SELECT FILIALORIGEM.CODIGO
                , PCPEDCOMPRAOPERLOGITE.CODPROD
                , SUM(PCPEDCOMPRAOPERLOGITE.QTPED) QTOPERLOG
                , FILIALDESTINO.CODIGO
             FROM PCPEDCOMPRAOPERLOGCAB
                , PCPEDCOMPRAOPERLOGITE
                , PCFILIAL FILIALORIGEM
                , PCFILIAL FILIALDESTINO
                , PCPRODUT
                , PCMARCA
            WHERE PCPEDCOMPRAOPERLOGCAB.NUMPED = PCPEDCOMPRAOPERLOGITE.NUMPED
              AND FILIALORIGEM.CODFORNEC = PCPEDCOMPRAOPERLOGCAB.CODFORNEC
              AND FILIALDESTINO.CODIGO = PCPEDCOMPRAOPERLOGCAB.CODFILIAL
              AND PCPEDCOMPRAOPERLOGCAB.SITUACAO = ''P''
              AND PCPRODUT.CODPROD = PCPEDCOMPRAOPERLOGITE.CODPROD
              AND PCPRODUT.CODMARCA = PCMARCA.CODMARCA(+) ';
      END IF;

      -- Filial de Origem = OBRIGATORIO
      vSqlEstOperLog := vSqlEstOperLog   ||
          ' AND FILIALORIGEM.CODIGO = ' ||  '''' || P_CODFILIAL_ORIGEM || '''';
      -- Se passou o Grupo de Loja do Destino
      IF (TRIM(P_CODGRUPOLOJA) IS NOT NULL) THEN
        vSqlEstOperLog := vSqlEstOperLog ||
          ' AND FILIALDESTINO.CODGRUPOLOJA IN (' || P_CODGRUPOLOJA || ')';
      END IF;
      -- Se passou a Filial de Destino
      IF (TRIM(P_CODFILIAL_DESTINO) IS NOT NULL) THEN
        vSqlEstOperLog := vSqlEstOperLog ||
          ' AND FILIALDESTINO.CODIGO IN (' ||  P_CODFILIAL_DESTINO || ')';
      END IF;
      -- Não carrega a Filial de Destino que é iguail à de Origem (Caso Multiseleção)
      vSqlEstOperLog := vSqlEstOperLog ||
        ' AND FILIALDESTINO.CODIGO <> '       ||  '''' || P_CODFILIAL_ORIGEM || '''';
      -- Se passou o Código do Produto FILHO
      IF (TRIM(P_PRODUTO) IS NOT NULL) THEN
        vSqlEstOperLog := vSqlEstOperLog   ||
          ' AND TAB_PROD_FILHO.CODPROD IN (' || P_PRODUTO || ')';
      END IF;
      -- Se passou o Código o Departamento
      IF (TRIM(P_DEPARTAMENTO) IS NOT NULL) THEN
        vSqlEstOperLog := vSqlEstOperLog ||
          ' AND PCPRODUT.CODEPTO IN ('     || P_DEPARTAMENTO || ')';
      END IF;
      -- Se passou a Seção
      IF (TRIM(P_SECAO) IS NOT NULL) THEN
        vSqlEstOperLog := vSqlEstOperLog ||
          ' AND PCPRODUT.CODSEC IN ('      || P_SECAO || ')';
      END IF;
      -- Se passou a Categoria
      IF (TRIM(P_CATEGORIA) IS NOT NULL) THEN
        vSqlEstOperLog := vSqlEstOperLog  ||
          ' AND PCPRODUT.CODCATEGORIA IN (' || P_CATEGORIA || ')';
      END IF;
      -- Se passou a Marca
      IF (TRIM(P_SUBCATEGORIA) IS NOT NULL) THEN
        vSqlEstOperLog := vSqlEstOperLog     ||
          ' AND PCPRODUT.CODSUBCATEGORIA IN (' || P_SUBCATEGORIA || ')';
      END IF;
      -- Se passou a Marca
      IF (TRIM(P_MARCA) IS NOT NULL) THEN
        vSqlEstOperLog := vSqlEstOperLog ||
          ' AND PCPRODUT.CODMARCA IN ('    || P_MARCA || ')';
      END IF;
      -- Se passou o Fornecedor
      IF (TRIM(P_FORNECEDOR) IS NOT NULL) THEN
        vSqlEstOperLog := vSqlEstOperLog ||
          ' AND PCPRODUT.CODFORNEC IN ('   || P_FORNECEDOR || ')';
      END IF;
      -- Se passou a Linha
      IF (TRIM(P_LINHAPRODUTO) IS NOT NULL) THEN
        vSqlEstOperLog := vSqlEstOperLog  ||
          ' AND PCPRODUT.CODLINHAPROD IN (' || P_LINHAPRODUTO || ')';
      END IF;
      -- Se passou a Unidade
      IF (TRIM(P_UNIDADE) IS NOT NULL) THEN
        vSqlEstOperLog := vSqlEstOperLog ||
          ' AND PCPRODUT.UNIDADE IN ('     || P_UNIDADE || ')';
      END IF;
      -- Se passou Psicotropico
      IF (TRIM(P_PSICOTROPICO) IS NOT NULL) THEN
        vSqlEstOperLog := vSqlEstOperLog  ||
          ' AND PCPRODUT.PSICOTROPICO IN (' || P_PSICOTROPICO || ')';
      END IF;
      -- Se passou Tipo Tribut. Medic.
      IF (TRIM(P_TIPOTRIBUTMEDIC) IS NOT NULL) THEN
        vSqlEstOperLog := vSqlEstOperLog     ||
          ' AND PCPRODUT.TIPOTRIBUTMEDIC IN (' || P_TIPOTRIBUTMEDIC || ')';
      END IF;
      -- Se passou o Comprador da Marca
      IF (TRIM(P_COMPRADOR_MARCA) IS NOT NULL) THEN
        vSqlEstOperLog := vSqlEstOperLog ||
          ' AND PCMARCA.CODCOMPRADOR IN (' || P_COMPRADOR_MARCA || ')';
      END IF;
      -- Condição de Importação
      IF (P_IMPORTA_QTDE_TRANSF = 'S') THEN
        --vSqlEstDestino := vSqlEstDestino ||
        vSqlEstOperLog := vSqlEstOperLog ||
          ' AND EXISTS (SELECT 1
                          FROM PCMED_TEMP_IMPORT_ATAC_VAR
                         WHERE PCMED_TEMP_IMPORT_ATAC_VAR.CODPROD_D   = PCPRODUT.CODPROD
                           AND PCMED_TEMP_IMPORT_ATAC_VAR.CODFILIAL_D = FILIALDESTINO.CODIGO) ';
      END IF;
      -- Finaliza o SQL
      vSqlEstOperLog := vSqlEstOperLog ||
          ' GROUP BY FILIALORIGEM.CODIGO, PCPEDCOMPRAOPERLOGITE.CODPROD, FILIALDESTINO.CODIGO) ';

      -- Insere na Tabela Temporária
      EXECUTE IMMEDIATE vSqlEstOperLog;

     /**********************************************
      Tabela temporária de Quantidade de Sugestão
      de Pedido de compra que ainda não gerou Pedido
      de Compra
     ***********************************************/

      -- Limpa Tabela Temporária
      EXECUTE IMMEDIATE 'TRUNCATE TABLE PCMED_TEMP_ESTSUGESTAO';

      -- Prepara SQL
      vSqlEstSugestao :=
      ' INSERT INTO PCMED_TEMP_ESTSUGESTAO
        (SELECT PCSUGESTAOCOMPRAC.CODFILIAL
              , PCSUGESTAOCOMPRAI.CODPROD
              , SUM(PCSUGESTAOCOMPRAI.QTSUGERIDA) QTSUGERIDA
           FROM PCSUGESTAOCOMPRAC
              , PCSUGESTAOCOMPRAI
              , PCFILIAL
              , PCPRODUT
              , PCMARCA
          WHERE PCSUGESTAOCOMPRAC.NUMSUGESTAO = PCSUGESTAOCOMPRAI.NUMSUGESTAO
            AND PCSUGESTAOCOMPRAC.CODFILIAL = PCFILIAL.CODIGO
            AND PCSUGESTAOCOMPRAI.STATUS IS NULL
            AND PCPRODUT.CODPROD = PCSUGESTAOCOMPRAI.CODPROD
            AND PCPRODUT.CODMARCA = PCMARCA.CODMARCA(+) ';
      -- Se passou o Grupo de Loja do Destino
      IF (TRIM(P_CODGRUPOLOJA) IS NOT NULL) THEN
        vSqlEstSugestao := vSqlEstSugestao ||
          ' AND PCFILIAL.CODGRUPOLOJA IN ('  || P_CODGRUPOLOJA || ')';
      END IF;
      -- Se passou a Filial de Destino
      IF (TRIM(P_CODFILIAL_DESTINO) IS NOT NULL) THEN
        vSqlEstSugestao := vSqlEstSugestao        ||
          ' AND PCSUGESTAOCOMPRAC.CODFILIAL IN (' ||  P_CODFILIAL_DESTINO || ')';
      END IF;
      -- Não carrega a Filial de Destino que é igual à de Origem (Caso Multiseleção)
      vSqlEstSugestao := vSqlEstSugestao       ||
        ' AND PCSUGESTAOCOMPRAC.CODFILIAL <> ' ||  '''' || P_CODFILIAL_ORIGEM || '''';
      -- Se passou o Código do Produto
      IF (TRIM(P_PRODUTO) IS NOT NULL) THEN
        vSqlEstSugestao := vSqlEstSugestao      ||
          ' AND PCSUGESTAOCOMPRAI.CODPROD IN (' || P_PRODUTO || ')';
      END IF;
      -- Se passou o Código o Departamento
      IF (TRIM(P_DEPARTAMENTO) IS NOT NULL) THEN
        vSqlEstSugestao := vSqlEstSugestao ||
          ' AND PCPRODUT.CODEPTO IN ('     || P_DEPARTAMENTO || ')';
      END IF;
      -- Se passou a Seção
      IF (TRIM(P_SECAO) IS NOT NULL) THEN
        vSqlEstSugestao := vSqlEstSugestao ||
          ' AND PCPRODUT.CODSEC IN ('      || P_SECAO || ')';
      END IF;
      -- Se passou a Categoria
      IF (TRIM(P_CATEGORIA) IS NOT NULL) THEN
        vSqlEstSugestao := vSqlEstSugestao  ||
          ' AND PCPRODUT.CODCATEGORIA IN (' || P_CATEGORIA || ')';
      END IF;
      -- Se passou a Marca
      IF (TRIM(P_SUBCATEGORIA) IS NOT NULL) THEN
        vSqlEstSugestao := vSqlEstSugestao     ||
          ' AND PCPRODUT.CODSUBCATEGORIA IN (' || P_SUBCATEGORIA || ')';
      END IF;
      -- Se passou a Marca
      IF (TRIM(P_MARCA) IS NOT NULL) THEN
        vSqlEstSugestao := vSqlEstSugestao ||
          ' AND PCPRODUT.CODMARCA IN ('    || P_MARCA || ')';
      END IF;
      -- Se passou o Fornecedor
      IF (TRIM(P_FORNECEDOR) IS NOT NULL) THEN
        vSqlEstSugestao := vSqlEstSugestao ||
          ' AND PCPRODUT.CODFORNEC IN ('   || P_FORNECEDOR || ')';
      END IF;
      -- Se passou a Linha
      IF (TRIM(P_LINHAPRODUTO) IS NOT NULL) THEN
        vSqlEstSugestao := vSqlEstSugestao  ||
          ' AND PCPRODUT.CODLINHAPROD IN (' || P_LINHAPRODUTO || ')';
      END IF;
      -- Se passou a Unidade
      IF (TRIM(P_UNIDADE) IS NOT NULL) THEN
        vSqlEstSugestao := vSqlEstSugestao ||
          ' AND PCPRODUT.UNIDADE IN ('     || P_UNIDADE || ')';
      END IF;
      -- Se passou Psicotropico
      IF (TRIM(P_PSICOTROPICO) IS NOT NULL) THEN
        vSqlEstSugestao := vSqlEstSugestao  ||
          ' AND PCPRODUT.PSICOTROPICO IN (' || P_PSICOTROPICO || ')';
      END IF;
      -- Se passou Tipo Tribut. Medic.
      IF (TRIM(P_TIPOTRIBUTMEDIC) IS NOT NULL) THEN
        vSqlEstSugestao := vSqlEstSugestao     ||
          ' AND PCPRODUT.TIPOTRIBUTMEDIC IN (' || P_TIPOTRIBUTMEDIC || ')';
      END IF;
      -- Se passou o Comprador da Marca
      IF (TRIM(P_COMPRADOR_MARCA) IS NOT NULL) THEN
        vSqlEstSugestao := vSqlEstSugestao ||
          ' AND PCMARCA.CODCOMPRADOR IN (' || P_COMPRADOR_MARCA || ')';
      END IF;
      -- Condição de Importação
      IF (P_IMPORTA_QTDE_TRANSF = 'S') THEN
        --vSqlEstDestino := vSqlEstDestino ||
        vSqlEstSugestao := vSqlEstSugestao ||
          ' AND EXISTS (SELECT 1
                          FROM PCMED_TEMP_IMPORT_ATAC_VAR
                         WHERE PCMED_TEMP_IMPORT_ATAC_VAR.CODPROD_D   = PCSUGESTAOCOMPRAI.CODPROD
                           AND PCMED_TEMP_IMPORT_ATAC_VAR.CODFILIAL_D = PCSUGESTAOCOMPRAC.CODFILIAL) ';
      END IF;
      -- Finaliza o SQL
      vSqlEstSugestao := vSqlEstSugestao ||
          ' GROUP BY PCSUGESTAOCOMPRAC.CODFILIAL, PCSUGESTAOCOMPRAI.CODPROD) ';

      -- Insere na Tabela Temporária
      EXECUTE IMMEDIATE vSqlEstSugestao;

     /********************************************
      Tabela temporária de vendas [Tarefa: 177608]
      ********************************************/

      -- Limpa Tabela Temporária
      EXECUTE IMMEDIATE 'TRUNCATE TABLE PCMED_TEMP_VENDA_DESTINO';

      -- Inicializa Data Inicial e Final
      IF (TRIM(P_DT_INICIAL_VENDA) IS NOT NULL) THEN

        vdDataInicialVenda := TO_DATE(P_DT_INICIAL_VENDA,'DD/MM/YYYY');
        vdDataFinalVenda   := TO_DATE(P_DT_FINAL_VENDA,'DD/MM/YYYY');

        -- Insere Dados na Tabela Temporária
        INSERT INTO PCMED_TEMP_VENDA_DESTINO
        (SELECT PCMOV.CODFILIAL
              , PCMOV.CODPROD
              , SUM(NVL(PCMOV.QT,0)) QT
           FROM PCMOV
              , PCMED_TEMP_ESTDESTINO
          WHERE PCMOV.CODOPER = 'S'
            AND PCMOV.CODFILIAL = PCMED_TEMP_ESTDESTINO.CODFILIAL_D
            AND PCMOV.CODPROD = PCMED_TEMP_ESTDESTINO.CODPROD_D
            AND PCMOV.DTMOV >= vdDataInicialVenda
            AND PCMOV.DTMOV <= vdDataFinalVenda
          GROUP BY PCMOV.CODFILIAL
                 , PCMOV.CODPROD);

      END IF;

     /******************
      Efetiva Transações
      ******************/
      COMMIT;

     /***************************
      Realiza Cálculo da Sugestão
      ***************************/
      PCALCULA_SUGESTAO(vvMsgErroTratado);
      IF (vvMsgErroTratado IS NOT NULL) THEN
        RAISE e_Tratado;
      END IF;

      -- Limpa Tabela Temporária usada na importação da Sugestão
      IF (P_IMPORTA_QTDE_TRANSF = 'S') THEN
        DELETE FROM pcmed_temp_import_atac_var;
        COMMIT;
      END IF;

   /*********************************************
    Se Geração de Dados de Histórico da Reposição
    *********************************************/
    ELSIF (NVL(P_AUTOMATICO_MANUAL,'M') IN ('H')) THEN

      -- Limpa Tabela Temporária
      EXECUTE IMMEDIATE 'TRUNCATE TABLE PCMED_TEMP_TRANSF_ATAC_VAR';
      EXECUTE IMMEDIATE 'TRUNCATE TABLE PCMED_TEMP_TRANSF_ATAC_VAR_ERR';
      EXECUTE IMMEDIATE 'TRUNCATE TABLE PCMED_TEMP_FALTAS_ATAC_VAR';

      -- Prepara SQL
      vSqlHistorico :=
      ' INSERT INTO PCMED_TEMP_TRANSF_ATAC_VAR
              ( NUMSUGESTAOREP
              , DTGERACAO
              , CODFILIAL_O
              , CODPROD_O
              , DESCRICAO_O
              , CODMARCA_O
              , MARCA_O
              , QTUNITCX_O
              , QTD_EST_O
              , QTD_SUGERIDA_O
              , QTD_TRANSFERIR_O
              , CODFILIAL_D
              , PRIORIDADE_D
              , CODPROD_D
              , DESCRICAO_D
              , TIPOSUGESTAO_D
              , DESCTIPOSUGESTAO_D
              , ESTOQUEMIN_D
              , ESTOQUEMAX_D
              , QTESTGER_D
              , QTPEDIDA_D
              , QTD_TRANSITO_D
              , QTD_BLOQSEMAVARIA_D
              , CLASSE_D
              , PMC_D
              , CUSTOULTENT_D
              , PVENDA_D
              , SUG_FRACIONADA_D
              , QTUNITCX_D
              , PERCARREDONDA_D
              , QTD_SUGERIDA_D
              , QTD_TRANSFERIR_D
              , VLR_TRANSFERIR_D
              , CODEQUIPE
              , CODCATEGORIA
              , CODSEC
              , CODEPTO
              , CODFORNEC
              , EMBALAGEM
              , UNIDADE
              , TRIBUTACAO
              , CODST
              , QTVENDMES_D
              , QTVENDMES1_D
              , QTVENDMES2_D
              , QTVENDMES3_D
              , CODFAB_O
              , CODFAB_D
              , CODAUXILIAR_O
              , CODAUXILIAR_D
              , QUEBRA1
              , QUEBRA2
              , QUEBRA3
              , QUEBRA4
              , QTGIRODIA_D
              , QTDIASREP_D
              , QTPENDENTE_D
              , DESCCONSIDERAESTPENDSUG_D
              , PRAZOENTREGA_O
              , PERCARREDONDA_O
              , CXFORNEC_TRANSFERIR_O
              , TIPO_SUG_LOJA_CD
              , TIPO_SUG_COMPRA_TRANSF
              , DESC_TIPO_SUG_COMPRA_TRANSF
              , CODFORNECPRIORIDADE
              , DESC_FORNECPRIORIDADE
              , CODDESC_FORNECPRIORIDADE
              , QTSUGCOMPRA_D
              , QTIMPORT_D
              , EMB_POR_FORNECEDOR_O
              , PRECO_TRANSF_O
              , NUMPED
              , QTPED
              , PRECOPED
              , OBSERVACAOREJEICAO
              , NUMSUGESTAO
              , CODPROD_TRANSITO_O
              , DESCRICAO_TRANSITO_O
              , CODCLI
              , NOMEFANTASIACLIENTE
              , QTFALTAPED
              , INTEGRADORA
              , NOMEINTEGRADORA
              , QTOPERLOG_O
              , QTOPERLOG_D
              , INTEGRADORAESPELHONF
              , NOMEINTEGRADORAESPELHONF
              , INFOQUEBRAS
              , CODFILIALRETIRA_O
              , ESTMIN_O
              , ESTOQUEMIN_O
              , ESTOQUEMINSUG_O
              , FORMULA_QT_SUGERIDA_D
              , TIPOCUSTOTRANSF
              , QTCANCESTOQUEMINSUG_O
              , FORMULA
              )
         SELECT HI.NUMSUGESTAOREP
              , HC.DTGERACAO
              , HI.CODFILIAL_O
              , HI.CODPROD_O
              , PO.DESCRICAO
              , HI.CODMARCA_O
              , MA.MARCA
              , HI.QTUNITCX_O
              , HI.QTD_EST_O
              , HI.QTD_SUGERIDA_O
              , HI.QTD_TRANSFERIR_O
              , HI.CODFILIAL_D
              , HI.PRIORIDADE_D
              , HI.CODPROD_D
              , PD.DESCRICAO
              , HI.TIPOSUGESTAO_D
              , HI.DESCTIPOSUGESTAO_D
              , HI.ESTOQUEMIN_D
              , HI.ESTOQUEMAX_D
              , HI.QTESTGER_D
              , HI.QTPEDIDA_D
              , HI.QTD_TRANSITO_D
              , HI.QTD_BLOQSEMAVARIA_D
              , HI.CLASSE_D
              , HI.PMC_D
              , HI.CUSTOULTENT_D
              , HI.PVENDA_D
              , HI.SUG_FRACIONADA_D
              , HI.QTUNITCX_D
              , HI.PERCARREDONDA_D
              , HI.QTD_SUGERIDA_D
              , HI.QTD_TRANSFERIR_D
              , HI.VLR_TRANSFERIR_D
              , HI.CODEQUIPE
              , HI.CODCATEGORIA
              , HI.CODSEC
              , HI.CODEPTO
              , HI.CODFORNEC
              , HI.EMBALAGEM
              , HI.UNIDADE
              , HI.TRIBUTACAO
              , HI.CODST
              , HI.QTVENDMES_D
              , HI.QTVENDMES1_D
              , HI.QTVENDMES2_D
              , HI.QTVENDMES3_D
              , HI.CODFAB_O
              , HI.CODFAB_D
              , HI.CODAUXILIAR_O
              , HI.CODAUXILIAR_D
              , HI.QUEBRA1
              , HI.QUEBRA2
              , HI.QUEBRA3
              , HI.QUEBRA4
              , HI.QTGIRODIA_D
              , HI.QTDIASREP_D
              , HI.QTPENDENTE_D
              , HI.DESCCONSIDERAESTPENDSUG_D
              , HI.PRAZOENTREGA_O
              , HI.PERCARREDONDA_O
              , HI.CXFORNEC_TRANSFERIR_O
              , HI.TIPO_SUG_LOJA_CD
              , HI.TIPO_SUG_COMPRA_TRANSF
              , HI.DESC_TIPO_SUG_COMPRA_TRANSF
              , HI.CODFORNECPRIORIDADE
              , SUBSTR(FR.FORNECEDOR,1,30)
              , HI.CODDESC_FORNECPRIORIDADE
              , HI.QTSUGCOMPRA_D
              , HI.QTIMPORT_D
              , HI.EMB_POR_FORNECEDOR_O
              , HI.PRECO_TRANSF_O
              , HI.NUMPED
              , HI.QTPED
              , HI.PRECOPED
              , HI.OBSERVACAOREJEICAO
              , HI.NUMSUGESTAO
              , HI.CODPROD_TRANSITO_O
              , POT.DESCRICAO
              , HI.CODCLI
              , CL.FANTASIA
              , HI.QTFALTAPED
              , HI.INTEGRADORA
              , HI.NOMEINTEGRADORA
              , HI.QTOPERLOG_O
              , HI.QTOPERLOG_D
              , HI.INTEGRADORAESPELHONF
              , HI.NOMEINTEGRADORAESPELHONF
              , HI.INFOQUEBRAS
              , HI.CODFILIALRETIRA_O
              , HI.ESTMIN_O
              , HI.ESTOQUEMIN_O
              , HI.ESTOQUEMINSUG_O
              , HI.FORMULA_QT_SUGERIDA_D
              , HI.TIPOCUSTOTRANSF
              , HI.QTCANCESTOQUEMINSUG_O
              , HI.FORMULA
           FROM PCSUGESTAOREPOSICAOMEDCAB HC
              , PCSUGESTAOREPOSICAOMEDITE HI
              , PCPRODUT                  PO
              , PCPRODUT                  POT
              , PCPRODUT                  PD
              , PCMARCA                   MA
              , PCFILIAL                  FD
              , PCCLIENT                  CL
              , PCFORNEC                  FR
          WHERE (HC.NUMSUGESTAOREP      = HI.NUMSUGESTAOREP)
            AND (HI.CODPROD_O           = PO.CODPROD(+))
            AND (HI.CODPROD_TRANSITO_O  = POT.CODPROD(+))
            AND (HI.CODPROD_D           = PD.CODPROD(+))
            AND (HI.CODMARCA_O          = MA.CODMARCA(+))
            AND (HI.CODFILIAL_D         = FD.CODIGO(+))
            AND (HI.CODCLI              = CL.CODCLI(+))
            AND (HI.CODFORNECPRIORIDADE = FR.CODFORNEC(+))
            ';

      -- Se passou o Grupo de Loja do Destino
      IF (TRIM(P_CODGRUPOLOJA) IS NOT NULL) THEN
        vSqlHistorico := vSqlHistorico ||
          ' AND FD.CODGRUPOLOJA IN ('  || P_CODGRUPOLOJA || ')';
      END IF;
      -- Se passou a Filial de Destino
      IF (TRIM(P_CODFILIAL_DESTINO) IS NOT NULL) THEN
        vSqlHistorico := vSqlHistorico ||
          ' AND FD.CODIGO IN ('        ||  P_CODFILIAL_DESTINO || ')';
      END IF;
      -- Não carrega a Filial de Destino que é igual à de Origem (Caso Multiseleção)
      vSqlHistorico := vSqlHistorico ||
        ' AND FD.CODIGO <> '         ||  '''' || P_CODFILIAL_ORIGEM || '''';
      -- Se passou o Código do Produto
      IF (TRIM(P_PRODUTO) IS NOT NULL) THEN
        vSqlHistorico := vSqlHistorico ||
          ' AND PD.CODPROD IN ('       || P_PRODUTO || ')';
      END IF;
      -- Se passou o Código o Departamento
      IF (TRIM(P_DEPARTAMENTO) IS NOT NULL) THEN
        vSqlHistorico := vSqlHistorico ||
          ' AND PD.CODEPTO IN ('       || P_DEPARTAMENTO || ')';
      END IF;
      -- Se passou a Seção
      IF (TRIM(P_SECAO) IS NOT NULL) THEN
        vSqlHistorico := vSqlHistorico ||
          ' AND PD.CODSEC IN ( '       || P_SECAO || ')';
      END IF;
      -- Se passou a Categoria
      IF (TRIM(P_CATEGORIA) IS NOT NULL) THEN
        vSqlHistorico := vSqlHistorico ||
          ' AND PD.CODCATEGORIA IN ('  || P_CATEGORIA || ')';
      END IF;
      -- Se passou a Marca
      IF (TRIM(P_SUBCATEGORIA) IS NOT NULL) THEN
        vSqlHistorico := vSqlHistorico   ||
          ' AND PD.CODSUBCATEGORIA IN (' || P_SUBCATEGORIA || ')';
      END IF;
      -- Se passou a Marca
      IF (TRIM(P_MARCA) IS NOT NULL) THEN
        vSqlHistorico := vSqlHistorico ||
          ' AND PD.CODMARCA IN ('      || P_MARCA || ')';
      END IF;
      -- Se passou o Fornecedor
      IF (TRIM(P_FORNECEDOR) IS NOT NULL) THEN
        vSqlHistorico := vSqlHistorico ||
          ' AND PD.CODFORNEC IN ('     || P_FORNECEDOR || ')';
      END IF;
      -- Se passou a Linha
      IF (TRIM(P_LINHAPRODUTO) IS NOT NULL) THEN
        vSqlHistorico := vSqlHistorico ||
          ' AND PD.CODLINHAPROD IN ('  || P_LINHAPRODUTO || ')';
      END IF;
      -- Se passou a Classe
      IF (TRIM(P_CLASSE) IS NOT NULL) THEN
        vSqlHistorico := vSqlHistorico ||
          ' AND HI.CLASSE_D IN ('      || P_CLASSE || ')';
      END IF;
      -- Se passou a Unidade
      IF (TRIM(P_UNIDADE) IS NOT NULL) THEN
        vSqlHistorico := vSqlHistorico ||
          ' AND PD.UNIDADE IN ('       || P_UNIDADE || ')';
      END IF;
      -- Se passou Psicotropico
      IF (TRIM(P_PSICOTROPICO) IS NOT NULL) THEN
        vSqlHistorico := vSqlHistorico ||
          ' AND PD.PSICOTROPICO IN ('  || P_PSICOTROPICO || ')';
      END IF;
      -- Se passou Tipo Tribut. Medic.
      IF (TRIM(P_TIPOTRIBUTMEDIC) IS NOT NULL) THEN
        vSqlHistorico := vSqlHistorico   ||
          ' AND PD.TIPOTRIBUTMEDIC IN (' || P_TIPOTRIBUTMEDIC || ')';
      END IF;
      -- Se passou o Comprador da Marca
      IF (TRIM(P_COMPRADOR_MARCA) IS NOT NULL) THEN
        vSqlHistorico := vSqlHistorico ||
          ' AND MA.CODCOMPRADOR IN ('  || P_COMPRADOR_MARCA || ')';
      END IF;

      -- Data Inicial (Obrigatório)
      vSqlHistorico := vSqlHistorico ||
        ' AND HC.DTGERACAO >= TO_DATE(' || '''' || P_DT_INICIAL_VENDA || '''' || ',' ||
                                           '''' || 'DD/MM/YYYY'       || '''' || ')';

      -- Data Final (Obrigatório)
      vSqlHistorico := vSqlHistorico   ||
        ' AND HC.DTGERACAO < TO_DATE(' || '''' || P_DT_FINAL_VENDA || '''' || ',' ||
                                          '''' || 'DD/MM/YYYY'     || '''' || ') + 1';

      -- Insere na Tabela Temporária
      EXECUTE IMMEDIATE vSqlHistorico;

      -- Efetiva  Transações
      COMMIT;

      -- Insere as Faltas na Tabela Temporária
      INSERT INTO PCMED_TEMP_FALTAS_ATAC_VAR
      (SELECT PCSUGESTAOREPOSICAOMEDFTA.NUMSUGESTAOREP
            , PCSUGESTAOREPOSICAOMEDFTA.SEQFALTA
            , PCSUGESTAOREPOSICAOMEDFTA.CODFILIALFALTA
            , PCSUGESTAOREPOSICAOMEDFTA.CODPRODFALTA
            , PCSUGESTAOREPOSICAOMEDFTA.CODFORNEC
            , PCSUGESTAOREPOSICAOMEDFTA.CODCLI
            , PCSUGESTAOREPOSICAOMEDFTA.QTFALTA
            , PCSUGESTAOREPOSICAOMEDFTA.CODFILIAL_O
            , PCSUGESTAOREPOSICAOMEDFTA.CODPROD_O
            , PCSUGESTAOREPOSICAOMEDFTA.QTFALTA_O
            , PCSUGESTAOREPOSICAOMEDFTA.CODFILIAL_D
            , PCSUGESTAOREPOSICAOMEDFTA.CODPROD_D
            , PCSUGESTAOREPOSICAOMEDFTA.QTFALTA_D
            , PCSUGESTAOREPOSICAOMEDFTA.NUMPED
            , PCSUGESTAOREPOSICAOMEDFTA.QTPED
            , PCSUGESTAOREPOSICAOMEDFTA.PRECOPED
            , PCSUGESTAOREPOSICAOMEDFTA.NUMSUGESTAO
            , PCSUGESTAOREPOSICAOMEDFTA.DTGERPED
            , PCSUGESTAOREPOSICAOMEDFTA.REJEICAOINICIAL
            , PCSUGESTAOREPOSICAOMEDFTA.OBSERVACAOREJEICAO
            , PCSUGESTAOREPOSICAOMEDFTA.CODFORNECPRIORIDADE
            , PCSUGESTAOREPOSICAOMEDFTA.TIPO_SUG_COMPRA_TRANSF
         FROM PCSUGESTAOREPOSICAOMEDFTA
        WHERE (PCSUGESTAOREPOSICAOMEDFTA.NUMSUGESTAOREP IN (SELECT NUMSUGESTAOREP FROM PCMED_TEMP_TRANSF_ATAC_VAR)));

      -- Insere na Tabela Temporária as Rejeições na Geração dos Pedidos a partir da Sugestão de Reposição
      INSERT INTO PCMED_TEMP_TRANSF_ATAC_VAR_ERR
                ( CODFILIAL_O
                , CODPROD_O
                , DESCRICAO_O
                , QTD_TRANSFERIR_O
                , CODFILIAL_D
                , CODPROD_D
                , MENSAGEM )
           SELECT PCMED_TEMP_TRANSF_ATAC_VAR.CODFILIAL_O
                , PCMED_TEMP_TRANSF_ATAC_VAR.CODPROD_O
                , PCMED_TEMP_TRANSF_ATAC_VAR.DESCRICAO_O
                , PCMED_TEMP_TRANSF_ATAC_VAR.QTD_TRANSFERIR_O
                , PCMED_TEMP_TRANSF_ATAC_VAR.CODFILIAL_D
                , PCMED_TEMP_TRANSF_ATAC_VAR.CODPROD_D
                , PCMED_TEMP_TRANSF_ATAC_VAR.OBSERVACAOREJEICAO
             FROM PCMED_TEMP_TRANSF_ATAC_VAR
            WHERE (PCMED_TEMP_TRANSF_ATAC_VAR.OBSERVACAOREJEICAO IS NOT NULL);

      -- Insere na Tabela Temporária as Rejeições na Geração dos Pedidos a partir das Faltas da Sugestão de Reposição
      INSERT INTO PCMED_TEMP_TRANSF_ATAC_VAR_ERR
                ( CODFILIAL_O
                , CODPROD_O
                , DESCRICAO_O
                , QTD_TRANSFERIR_O
                , CODFILIAL_D
                , CODPROD_D
                , MENSAGEM )
           SELECT PCMED_TEMP_FALTAS_ATAC_VAR.CODFILIAL_O
                , PCMED_TEMP_FALTAS_ATAC_VAR.CODPROD_O
                , PCPRODUT.DESCRICAO
                , PCMED_TEMP_FALTAS_ATAC_VAR.QTFALTA_O
                , PCMED_TEMP_FALTAS_ATAC_VAR.CODFILIAL_D
                , PCMED_TEMP_FALTAS_ATAC_VAR.CODPROD_D
                , PCMED_TEMP_FALTAS_ATAC_VAR.OBSERVACAOREJEICAO
             FROM PCMED_TEMP_FALTAS_ATAC_VAR
                , PCPRODUT
            WHERE (PCPRODUT.CODPROD = PCMED_TEMP_FALTAS_ATAC_VAR.CODPROD_O)
              AND (PCMED_TEMP_FALTAS_ATAC_VAR.OBSERVACAOREJEICAO IS NOT NULL);

     /******************
      Efetiva Transações
      ******************/
      COMMIT;

    END IF; -- Fim Condição se Geração Manual, Automática ou Geração do Histórico

  EXCEPTION
    WHEN e_Tratado THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20000,CHR(13) || vvMsgErroTratado);
  END PRC_PCMED_SUG_TRANSF_ATAC_VAR;

 /*****************************************************************************
  *****************************************************************************
  *****************************************************************************
  Nome         : PRC_PCMED_PED_TRANSF_ATAC_VAR
  Descricão    : Procedimento para Gerar os Pedidos de Transferências a partir
                 da Tabela Temporária com os Valores da Transferência
  #PROC2
  *****************************************************************************
  *****************************************************************************
  *****************************************************************************/
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
                                          pi_vPedidoAvaria       IN  VARCHAR2 DEFAULT NULL)
  IS

   /***********************
    Declaração de Variáveis
    ***********************/

    -- Número da Sugestão de Reposição
    vnProxNumSugestaoRep           PCSUGESTAOREPOSICAOMEDCAB.NUMSUGESTAOREP%TYPE;

    -- Parâmetros Gerais
    TYPE TRecParamFilial           IS RECORD(
         nCON_NUMCASASDECVENDA     NUMBER,
         nFIL_NUMMAXITENSNFE       NUMBER,
         vCON_CONDVENDA10          PCPARAMFILIAL.VALOR%TYPE, -- HIS.00636.2016
         vTRIBUTSAIDAORIGEMNACIMP  PCPARAMFILIAL.VALOR%TYPE, -- HIS.02786.2016
         nFIL_INDICECUSTOTRANSF    NUMBER,
         vUTILIZACONTROLEMEDICAM   PCPARAMFILIAL.VALOR%TYPE  -- HIS.03379.2017
         );
    vrParamFilial                  TRecParamFilial;

    -- Parâmetros PCONSUM
    TYPE TRecPcConsum              IS RECORD(
         vUSATRIBUTACAOPORUF       PCCONSUM.USATRIBUTACAOPORUF%TYPE,
         vCALCULARSTCOMIPI         PCCONSUM.CALCULARSTCOMIPI%TYPE,
         vMOSTRARPVENDASEMST       PCCONSUM.MOSTRARPVENDASEMST%TYPE,
         vTIPOCALCIPI              PCCONSUM.TIPOCALCIPI%TYPE,
         vTIPOCALCST               PCCONSUM.TIPOCALCST%TYPE,
         vCALCSTPF                 PCCONSUM.CALCSTPF%TYPE,
         vCONSIDERAISENTOSCOMOPF   PCCONSUM.CONSIDERAISENTOSCOMOPF%TYPE,
         vUSACOMISSAOPORCLIENTE    PCCONSUM.USACOMISSAOPORCLIENTE%TYPE,
         vUSACOMISSAOPORRCA        PCCONSUM.USACOMISSAOPORRCA%TYPE,
         vUSACOMISSAOPORLINHAPROD  PCCONSUM.USACOMISSAOPORLINHAPROD%TYPE,
         nTXVENDA                  PCCONSUM.TXVENDA%TYPE);
    vrPcConsum                     TRecPcConsum;

    -- Dados da Filial de Origem
    TYPE TRecFilOrigem             IS RECORD(
         vcAchouFilial             VARCHAR2(1),
         vvCgcFilial               PCFILIAL.CGC%TYPE,
         vnQtMaxPedido             PCFILIAL.QTMAXPEDIDO%TYPE,
         vvUfOrigem                PCFILIAL.UF%TYPE);
    vrFilOrigem                    TRecFilOrigem;

    -- Dados da Filial de Destino
    TYPE TRecFilDestino            IS RECORD(
         nCODCLI                   PCFILIAL.CODCLI%TYPE,
         vvUfDestino               PCFILIAL.UF%TYPE,
         vvTipoFilial              PCFILIAL.TIPOFILIAL%TYPE);
    vrFilDestino                   TRecFilDestino;

    -- Dados do Cliente
    TYPE TRecClienteDestino        IS RECORD(
         vvAchouDadosCliente       VARCHAR2(1),
         vvCgcClienteDestino       PCCLIENT.CGCENT%TYPE,
         vVALIDARMULTIPLOVENDA     PCCLIENT.VALIDARMULTIPLOVENDA%TYPE,
         nCODUSUR1                 PCCLIENT.CODUSUR1%TYPE,
         vCODCOB                   PCCLIENT.CODCOB%TYPE,
         nCODPLPAG                 PCCLIENT.CODPLPAG%TYPE,
         vOBSENTREGA1              PCCLIENT.OBSENTREGA1%TYPE,
         vOBSENTREGA2              PCCLIENT.OBSENTREGA2%TYPE,
         vOBSENTREGA3              PCCLIENT.OBSENTREGA3%TYPE,
         nCODPRACA                 PCCLIENT.CODPRACA%TYPE,
         vCGCENT                   PCCLIENT.CGCENT%TYPE,
         vTIPOCUSTOTRANSF          PCCLIENT.TIPOCUSTOTRANSF%TYPE,
         nPERACRESTRANSF           PCCLIENT.PERACRESTRANSF%TYPE,
         nISENTOIPI                PCCLIENT.ISENTOIPI%TYPE,
         vSULFRAMA                 PCCLIENT.SULFRAMA%TYPE,
         vTIPOFJ                   PCCLIENT.TIPOFJ%TYPE,
         vESTENT                   PCCLIENT.ESTENT%TYPE,
         vCALCULAST                PCCLIENT.CALCULAST%TYPE,
         vIEENT                    PCCLIENT.IEENT%TYPE,
         nPERCOMCLI                PCCLIENT.PERCOMCLI%TYPE,
         vTIPOEMPRESA              PCCLIENT.TIPOEMPRESA%TYPE,
         vUTILIZAIESIMPLIFICADA    PCCLIENT.UTILIZAIESIMPLIFICADA%TYPE,
         vFANTASIA                 PCCLIENT.FANTASIA%TYPE,
         vCLIENTEFONTEST           PCCLIENT.CLIENTEFONTEST%TYPE, -- HIS.03379.2017
         vFRETEDESPACHO            PCCLIENT.FRETEDESPACHO%TYPE);
    vrClienteDestino               TRecClienteDestino;

    -- Dados do Fornecedor
    TYPE TRecFornecDestino        IS RECORD(
         nCODFORNEC               PCFORNEC.CODFORNEC%TYPE,
         vRAZAOSOCIAL             PCFORNEC.FORNECEDOR%TYPE,
         nVLMINPEDREPOSICAO       PCFORNEC.VLMINPEDREPOSICAO%TYPE);
    vrFornecDestino               TRecFornecDestino;

    -- Dados da Praça
    TYPE TRecPracaCliDestino       IS RECORD(
         vcAchouPraca              VARCHAR2(1),
         nNUMREGIAO                PCPRACA.NUMREGIAO%TYPE);
    vrPracaCliDestino              TRecPracaCliDestino;

    -- Dados do Usuário
    TYPE TRecRca                   IS RECORD(
         vcAchouRCA                VARCHAR2(1),
         vCODDISTRIB               PCUSUARI.CODDISTRIB%TYPE,
         nCODSUPERVISOR            PCUSUARI.CODSUPERVISOR%TYPE,
         vTIPOVEND                 PCUSUARI.TIPOVEND%TYPE,
         nPERCENT2                 PCUSUARI.PERCENT2%TYPE);
    vrRca                          TRecRca;

    -- Dados do Plano de Pagamento
    TYPE TRecPlanoPag              IS RECORD(
         vcAchouPlPag              VARCHAR2(1),
         vTIPOVENDA                PCPLPAG.TIPOVENDA%TYPE,
         nNUMDIAS                  PCPLPAG.NUMDIAS%TYPE,
         nPRAZO1                   PCPLPAG.PRAZO1%TYPE,
         nPRAZO2                   PCPLPAG.PRAZO2%TYPE,
         nPRAZO3                   PCPLPAG.PRAZO3%TYPE,
         nPRAZO4                   PCPLPAG.PRAZO4%TYPE,
         nPRAZO5                   PCPLPAG.PRAZO5%TYPE,
         nPRAZO6                   PCPLPAG.PRAZO6%TYPE,
         nPRAZO7                   PCPLPAG.PRAZO7%TYPE,
         nPRAZO8                   PCPLPAG.PRAZO8%TYPE,
         nPRAZO9                   PCPLPAG.PRAZO9%TYPE,
         nPRAZO10                  PCPLPAG.PRAZO10%TYPE,
         nPRAZO11                  PCPLPAG.PRAZO11%TYPE,
         nPRAZO12                  PCPLPAG.PRAZO12%TYPE,
         nNUMPR                    PCPLPAG.NUMPR%TYPE);
    vrPlanoPag                     TRecPlanoPag;

    -- Dados do Produto
    TYPE TRecProduto               IS RECORD(
         nPERCIPIVENDA             PCPRODUT.PERCIPIVENDA%TYPE,
         nPCOMINT1                 PCPRODUT.PCOMINT1%TYPE,
         nPCOMEXT1                 PCPRODUT.PCOMEXT1%TYPE,
         nPCOMREP1                 PCPRODUT.PCOMREP1%TYPE,
         nCODLINHAPROD             PCPRODUT.CODLINHAPROD%TYPE,
         nPESOBRUTO                PCPRODUT.PESOBRUTO%TYPE,
         nVOLUME                   PCPRODUT.VOLUME%TYPE,
         vTIPOCUSTOTRANSF          PCPRODUT.TIPOCUSTOTRANSF%TYPE);
    vrProduto_O                    TRecProduto;

    -- Dados de Custo Produto da PCEST na Filial de Origem
    TYPE TRecCustoProdut           IS RECORD(
         nCUSTOREP                 PCEST.CUSTOREP%TYPE,
         nCUSTOREAL                PCEST.CUSTOREAL%TYPE,
         nCUSTOCONT                PCEST.CUSTOCONT%TYPE,
         nCUSTOFIN                 PCEST.CUSTOFIN%TYPE,
         nCUSTOULTENT              PCEST.CUSTOULTENT%TYPE,
         nVALORULTENT              PCEST.VALORULTENT%TYPE,
         nCUSTOREALSEMST           PCEST.CUSTOREALSEMST%TYPE,
         nVLULTENTCONTSEMST        PCEST.VLULTENTCONTSEMST%TYPE,
         nCUSTOFORNEC              PCEST.CUSTOFORNEC%TYPE,
         nCUSTOFINSEMST            PCEST.CUSTOFINSEMST%TYPE,
         nVLICMSBCR                PCEST.VLICMSBCR%TYPE);
    vrCustoProduto_O               TRecCustoProdut;

    -- Dados do Produto da Tabela de Preços
    TYPE TRecTabPreco              IS RECORD(
         nPVENDA1                  PCTABPR.PVENDA1%TYPE,
         nPVENDA2                  PCTABPR.PVENDA2%TYPE,
         nPVENDA3                  PCTABPR.PVENDA3%TYPE,
         nPVENDA4                  PCTABPR.PVENDA4%TYPE,
         nPVENDA5                  PCTABPR.PVENDA5%TYPE,
         nPVENDA6                  PCTABPR.PVENDA6%TYPE,
         nPVENDA7                  PCTABPR.PVENDA7%TYPE,
         nCODST                    PCTABPR.CODST%TYPE,
         nVLST                     PCTABPR.VLST%TYPE);
    vrTabPreco                     TRecTabPreco;

    -- Dados da Tributação do Produto
    TYPE TRecTribut                IS RECORD(
         nPAUTA                    PCTRIBUT.PAUTA%TYPE,
         nIVA                      PCTRIBUT.IVA%TYPE,
         nALIQICMS1                PCTRIBUT.ALIQICMS1%TYPE,
         nALIQICMS2                PCTRIBUT.ALIQICMS2%TYPE,
         nPERCBASEREDST            PCTRIBUT.PERCBASEREDST%TYPE,
         vTIPOCALCULOGNRE          PCTRIBUT.TIPOCALCULOGNRE%TYPE,
         nCODICMTABTRANSF          PCTRIBUT.CODICMTABTRANSF%TYPE,
         nCODICMTABPF              PCTRIBUT.CODICMTABPF%TYPE,
         nPERDESCCUSTO             PCTRIBUT.PERDESCCUSTO%TYPE,
         nCODICMTABINTERNAC        PCTRIBUT.CODICMTAB%TYPE, -- HIS.02786.2016
         vUSAVLULTENTMEDIOBASEST   PCTRIBUT.USAVLULTENTMEDIOBASEST%TYPE );
    vrTribut                       TRecTribut;

    -- Dados do Pedido
    TYPE TRecPedido                IS RECORD(
         nNUMPED                   PCPEDC.NUMPED%TYPE,
         dDATA                     PCPEDC.DATA%TYPE,
         vGERACP                   PCPEDC.GERACP%TYPE,
         vUSACFOPVENDANATV10       PCPEDC.USACFOPVENDANATV10%TYPE,
         nPRAZO1                   PCPEDC.PRAZO1%TYPE,
         nPRAZO2                   PCPEDC.PRAZO2%TYPE,
         nPRAZO3                   PCPEDC.PRAZO3%TYPE,
         nPRAZO4                   PCPEDC.PRAZO4%TYPE,
         nPRAZO5                   PCPEDC.PRAZO5%TYPE,
         nPRAZO6                   PCPEDC.PRAZO6%TYPE,
         nPRAZO7                   PCPEDC.PRAZO7%TYPE,
         nPRAZO8                   PCPEDC.PRAZO8%TYPE,
         nPRAZO9                   PCPEDC.PRAZO9%TYPE,
         nPRAZO10                  PCPEDC.PRAZO10%TYPE,
         nPRAZO11                  PCPEDC.PRAZO11%TYPE,
         nPRAZO12                  PCPEDC.PRAZO12%TYPE,
         nCONDVENDA                PCPEDC.CONDVENDA%TYPE,
         nPERCVENDA                PCPEDC.PERCVENDA%TYPE,
         -- Totais
         nVLATEND                  PCPEDC.VLATEND%TYPE,
         nNUMITENS                 PCPEDC.NUMITENS%TYPE,
         nVLCUSTOFIN               PCPEDC.VLCUSTOFIN%TYPE,
         nVLCUSTOREAL              PCPEDC.VLCUSTOREAL%TYPE,
         nTOTPESO                  PCPEDC.TOTPESO%TYPE,
         nTOTVOLUME                PCPEDC.TOTVOLUME%TYPE,
         nVLCUSTOCONT              PCPEDC.VLCUSTOCONT%TYPE,
         nVLCUSTOREP               PCPEDC.VLCUSTOREP%TYPE,
         nVLTABELA                 PCPEDC.VLTABELA%TYPE,
         nVLTOTAL                  PCPEDC.VLTOTAL%TYPE,
         nVLOUTRASDESP             PCPEDC.VLOUTRASDESP%TYPE,
         nVLFRETE                  PCPEDC.VLFRETE%TYPE,
         nVLDESCONTO               PCPEDC.VLDESCONTO%TYPE,
         nNUMSUGESTAO              PCSUGESTAOCOMPRAC.NUMSUGESTAO%TYPE,
         nNUMPEDOPERLOG            PCPEDCOMPRAOPERLOGCAB.NUMPED%TYPE,
         -- Processo TV10 OL
         nNUMPEDRCA                PCPEDC.NUMPEDRCA%TYPE,
         nDTABERTURAPEDPALM        PCPEDC.DTABERTURAPEDPALM%TYPE,
         vUTILIZAVENDAPOREMBALAGEM PCPEDC.UTILIZAVENDAPOREMBALAGEM%TYPE
         );
    vrPedido                       TRecPedido;
    vrLimpaPedido                  TRecPedido;

    -- Dados do Item do Pedido
    TYPE TRecItemPedido            IS RECORD(
         nQTDETRANSFERIR           PCPEDI.QT%TYPE,
         nQT                       PCPEDI.QT%TYPE,
         nPTABELA                  PCPEDI.PTABELA%TYPE,
         nPVENDA                   PCPEDI.PVENDA%TYPE,
         nPVENDABASE               PCPEDI.PVENDABASE%TYPE,
         nPERDESC                  PCPEDI.PERDESC%TYPE,
         nCODST                    PCPEDI.CODST%TYPE,
         nST                       PCPEDI.ST%TYPE,
         nPERCIPI                  PCPEDI.PERCIPI%TYPE,
         nVLIPI                    PCPEDI.VLIPI%TYPE,
         nIVA                      PCPEDI.IVA%TYPE,
         nPAUTA                    PCPEDI.PAUTA%TYPE,
         nALIQICMS1                PCPEDI.ALIQICMS1%TYPE,
         nALIQICMS2                PCPEDI.ALIQICMS2%TYPE,
         nPERCBASEREDST            PCPEDI.PERCBASEREDST%TYPE,
         nSTCLIENTEGNRE            PCPEDI.STCLIENTEGNRE%TYPE,
         nPERCOM                   PCPEDI.PERCOM%TYPE,
         nVLCUSTOCONT              PCPEDI.VLCUSTOCONT%TYPE,
         nVLCUSTOREP               PCPEDI.VLCUSTOREP%TYPE,
         nVLCUSTOREAL              PCPEDI.VLCUSTOREAL%TYPE,
         nVLCUSTOFIN               PCPEDI.VLCUSTOFIN%TYPE,
         nVLDESCCUSTOCMV           PCPEDI.VLDESCCUSTOCMV%TYPE,
         nQTFALTA                  PCPEDI.QTFALTA%TYPE,
         nPRECOMAXCONSUM           PCPEDI.PRECOMAXCONSUM%TYPE,
         nBASEICST                 PCPEDI.BASEICST%TYPE,
         nREGIMEESPISENSTFONTE     PCPEDI.REGIMEESPISENSTFONTE%TYPE,
         nPVENDA1                  PCPEDI.PVENDA1%TYPE,
         nQTUNITEMB                PCPEDI.QTUNITEMB%TYPE,
         nCODAUXILIAR              PCPEDI.CODAUXILIAR%TYPE,
         nCODICMTAB                PCPEDI.CODICMTAB%TYPE,         -- HIS.02786.2016
         vPRODIMPORTADOPEPS        PCPEDI.PRODIMPORTADOPEPS%TYPE, -- HIS.02786.2016
         nNUMTRANSENTPEPS          PCPEDI.NUMTRANSENTPEPS%TYPE,    -- HIS.02786.2016
         vINDESCALARELEVANTE       PCPEDI.INDESCALARELEVANTE%TYPE, -- HIS.03379.2017
         vCNPJFABRICANTE           PCPEDI.CNPJFABRICANTE%TYPE,     -- HIS.03379.2017
         vFABRICANTE               PCPEDI.FABRICANTE%TYPE,         -- HIS.03379.2017
         nBASEFECP                 PCPEDI.VLBASEFCPST%TYPE,
         nALIQFECP                 PCPEDI.ALIQICMSFECP%TYPE,
         nVLFECP                   PCPEDI.VLFECP%TYPE,
         vOBSERVACAOSTFONTE        PCPEDI.OBSERVACAOSTFONTE%TYPE,  -- HIS.03379.2017
         vNUMLOTE                  PCPEDI.NUMLOTE%TYPE
         );
    vrItemPedido                   TRecItemPedido;

    -- Array de Mensagens
    TYPE TRecMensagem              IS RECORD(
         vnCodFilial_O             PCMED_TEMP_TRANSF_ATAC_VAR_ERR.CODFILIAL_O%TYPE,
         vnCodProd_O               PCMED_TEMP_TRANSF_ATAC_VAR_ERR.CODPROD_O%TYPE,
         vvDescricao_O             PCMED_TEMP_TRANSF_ATAC_VAR_ERR.DESCRICAO_O%TYPE,
         vnQtdeTransferir_O        PCMED_TEMP_TRANSF_ATAC_VAR_ERR.QTD_TRANSFERIR_O%TYPE,
         vnCodFilial_D             PCMED_TEMP_TRANSF_ATAC_VAR_ERR.CODFILIAL_D%TYPE,
         vnCodProd_D               PCMED_TEMP_TRANSF_ATAC_VAR_ERR.CODPROD_D%TYPE,
         vnSeqFalta                PCMED_TEMP_PED_ATAC_VAR.SEQFALTA%TYPE,
         vvMensagem                PCMED_TEMP_TRANSF_ATAC_VAR_ERR.MENSAGEM%TYPE,
         vvNumLote                 PCLOTE.NUMLOTE%TYPE);
    TYPE TTvMensagens              IS TABLE OF TRecMensagem INDEX BY BINARY_INTEGER;
    vtMensagensAux                 TTvMensagens;
    vtMensagens                    TTvMensagens;
    -- Sequencial de Mensagem
    viSeqMensAux                   INTEGER;

    -- Identificação de Erros ao Pesquisar Parâmetros
    vvErroPesqParam                VARCHAR2(1);
    vvMsgErroPesqParam             VARCHAR2(2000);
    -- Contador de Itens Inseridos no Pedido
    viContaItensPed                INTEGER;
    -- Motivo de Rejeição do Item
    vbAceitaItem                   BOOLEAN;
    vMotivoRejeicao                VARCHAR2(2000);
    -- Cálculo do IPI
    vvIsentoIPI                    PCCLIENT.ISENTOIPI%TYPE;
    -- Cálculo ST
    vbCalculouST                   BOOLEAN;
    vvMsgRetornoCalculoST          VARCHAR2(240);
    --vnPercBaseRedST                NUMBER;
    -- Cálculo do Custo
    vnCodIcmTab                    NUMBER;
    -- Gerar Despesas
    vvGeraCPagar                   PCPEDC.GERACP%TYPE;
    -- Multiplo
    vVALIDARMULTIPLOVENDA          PCCLIENT.VALIDARMULTIPLOVENDA%TYPE;
    vAPLICARVALIDACAOMULTIPLO      PCPARAMREPOSICAOLOJAS.VALOR%TYPE;
    vMULTIPLOPRODUTO               PCPRODUT.MULTIPLO%TYPE;
    vCodfilial_Dest                PCFILIAL.CODIGO%TYPE;

    -- Array com os Pedidos Gerados
    TYPE TRecPedidosGerados        IS RECORD(
         vnNumPed                  PCPEDC.NUMPED%TYPE,
         vvCodFilial               PCPEDC.CODFILIAL%TYPE,
         vdData                    PCPEDC.DATA%TYPE,
         vnCodUsur                 PCPEDC.CODUSUR%TYPE,
         vnCodCli                  PCPEDC.CODCLI%TYPE,
         vvFantasia                PCCLIENT.FANTASIA%TYPE,
         vvQuebra1                 PCMED_TEMP_PED_ATAC_VAR.QUEBRA1%TYPE,
         vvQuebra2                 PCMED_TEMP_PED_ATAC_VAR.QUEBRA1%TYPE,
         vvQuebra3                 PCMED_TEMP_PED_ATAC_VAR.QUEBRA1%TYPE,
         vvQuebra4                 PCMED_TEMP_PED_ATAC_VAR.QUEBRA1%TYPE,
         vvCodFilialRetira         PCPEDC.CODFILIAL%TYPE,
         vvCodFilialDestino        PCPEDC.CODFILIAL%TYPE);
    TYPE TTvPedidosGerados         IS TABLE OF TRecPedidosGerados INDEX BY BINARY_INTEGER;
    vtPedidosGerados               TTvPedidosGerados;
    viIndicePedGerado              INTEGER;

    -- Sequencial da Falta
    nSEQFALTA                      PCMED_TEMP_FALTAS_ATAC_VAR.SEQFALTA%TYPE;

    -- Flag de Controle de Valor Minimo do Pedido
    nVLTOTALPEDIDOCOMPRA           NUMBER;
    bATINGIUVLMINPEDIDO            BOOLEAN;

    -- Tipo de Custo Transf a aplicar
    V_TIPOCUSTOTRANSF_APLICAR      PCCLIENT.TIPOCUSTOTRANSF%TYPE;

    -- Array de Faltas
    TYPE TRecFalta                 IS RECORD(
      nCODPROD                     PCFALTA.CODPROD%TYPE,
      nCODUSUR                     PCFALTA.CODUSUR%TYPE,
      nCODCLI                      PCFALTA.CODCLI%TYPE,
      nQT                          PCFALTA.QT%TYPE,
      nPVENDA                      PCFALTA.PVENDA%TYPE,
      vCODFILIAL                   PCFALTA.CODFILIAL%TYPE,
      vQUEBRA1                     PCMED_TEMP_PED_ATAC_VAR.QUEBRA1%TYPE,
      vQUEBRA2                     PCMED_TEMP_PED_ATAC_VAR.QUEBRA2%TYPE,
      vQUEBRA3                     PCMED_TEMP_PED_ATAC_VAR.QUEBRA3%TYPE,
      vQUEBRA4                     PCMED_TEMP_PED_ATAC_VAR.QUEBRA4%TYPE,
      vCODFILIALRETIRA             PCFALTA.CODFILIAL%TYPE,
      vNUMLOTE                     PCLOTE.NUMLOTE%TYPE);
    TYPE TTvFalta                  IS TABLE OF TRecFalta INDEX BY BINARY_INTEGER;
    vtFalta                        TTvFalta;
    viIdxFalta                     INTEGER;
    -- Declaração de Tipos de Variáveis
    TYPE TT_FTA_CODFILIAL          IS TABLE OF PCPEDC.CODFILIAL%TYPE INDEX BY BINARY_INTEGER;
    TYPE TT_FTA_CODPROD            IS TABLE OF PCPEDI.CODPROD%TYPE INDEX BY BINARY_INTEGER;
    TYPE TT_FTA_QT                 IS TABLE OF PCPEDI.QTFALTA%TYPE INDEX BY BINARY_INTEGER;
    TYPE TT_FTA_CODFILIALRETIRA    IS TABLE OF PCPEDC.CODFILIAL%TYPE INDEX BY BINARY_INTEGER;
    -- Declaração de Variáveis
    vtFTA_CODFILIAL                TT_FTA_CODFILIAL;
    vtFTA_CODPROD                  TT_FTA_CODPROD;
    vtFTA_QT                       TT_FTA_QT;
    vtFTA_CODFILIALRETIRA          TT_FTA_CODFILIALRETIRA;

    --  Variável para receber o número do pedido para registrar falta
    vnNumPedidoRegistrarFalta      PCPEDC.NUMPED%TYPE;
    --  Variável para receber a Data do Pedido para registrar falta
    vdDataPedidoRegistrarFalta     PCPEDC.DATA%TYPE;

    -- Data de Geração de Pedidos de Operador Logístico
    vdDtPedOperLog                 DATE;

    -- Código do Projeto da Integradora
    vvCodigoProjetoIntegradora     PCINTEGRADORA.CODIGOPROJETO%TYPE;

    -- Tratamento de Erros - 4056.125049.2015
    vvMsgErroTratado               VARCHAR2(200);
    e_Tratado                      EXCEPTION;

    -- Mensage STFonte - HIS.00636.2016
    --vvMensagemStFonte              VARCHAR2(2000);

    -- PARÂMETROS DE REPOSIÇÃO DE LOJAS - Utilizar Conversão PCEMBALAGEM e não validar múltiplo da PCEMBALAGEM
    vUSAQTUNITPCEMBREPLOJA         PCPARAMREPOSICAOLOJAS.VALOR%TYPE;
    vIGNORARVALIDACAOMULTIPLOEMB   PCPARAMREPOSICAOLOJAS.VALOR%TYPE; -- MED-1896
    -- REGRA ESPECÍFICA - Arredondar Embalagem Fornecedor na Falta
    vUSAREGRAARREDEMBFRNFTAREP     PCREGRASEXCECAOMED.VALOR%TYPE;
    -- REGRA ESPECÍFICA - Aplicar Indice Transferência
    vUSAREGRAAPLICARINDICETRANSF   PCREGRASEXCECAOMED.VALOR%TYPE;

    -- Mensagem Erro Proc PEPS - HIS.02786.2016
    --vvMsgErroObterPepsIcms         VARCHAR2(2000);

    -- Mensagem Erros PMC - HIS.03379.2017
    vvErrosPmc                     VARCHAR2(2000);
    -- Mensagem Erros ST Fonte - HIS.03379.2017
    vvErrosStFonte                 VARCHAR2(2000);
    -- Preço Fábrica - HIS.03379.2017
    vnPrecoFabrica                 NUMBER;

    -- Preço sem Imposto
    vnPrecoSemImposto              PCTABPR.PTABELA%TYPE;
    vDESCSTFORAUFTRANSF            pcparamfilial.valor%Type;
    -- MED-1876 - Retorno Package Estoque
    --vvMsgRetornoPkgEstoque         VARCHAR2(2000);
    -- MED-1876 - Log Itens de Pedidos Gerados
    TYPE TRecItensPedGerados       IS RECORD(
         vCODFILIAL_O              PCMED_TEMP_TRANSF_ATAC_VAR.CODFILIAL_O%TYPE,
         nCODPROD_O                PCMED_TEMP_TRANSF_ATAC_VAR.CODPROD_O%TYPE,
         vDESCRICAO_O              PCMED_TEMP_TRANSF_ATAC_VAR.DESCRICAO_O%TYPE,
         nQTD_TRANSFERIR_O         PCMED_TEMP_TRANSF_ATAC_VAR.QTD_TRANSFERIR_O%TYPE,
         vCODFILIAL_D              PCMED_TEMP_TRANSF_ATAC_VAR.CODFILIAL_D%TYPE,
         nCODPROD_D                PCMED_TEMP_TRANSF_ATAC_VAR.CODPROD_D%TYPE,
         nNUMPED                   PCMED_TEMP_TRANSF_ATAC_VAR.NUMPED%TYPE,
         vNUMLOTE                  PCMED_TEMP_TRANSF_ATAC_VAR.NUMLOTE%TYPE);
    TYPE TTvItensPedGerados        IS TABLE OF TRecItensPedGerados INDEX BY BINARY_INTEGER;
    vtItensPedGerados              TTvItensPedGerados;
    viIdxItensPedGerados           INTEGER;

    -- Dados dos Itens do Funcep - HIS.04200.2017
    TYPE TRecDadosFuncep               IS RECORD(
         nVLBASEFCPICMS                PCPEDI.VLBASEFCPICMS%TYPE,      -- HIS.04200.2017
         nVLBASEFCPST                  PCPEDI.VLBASEFCPST%TYPE,        -- HIS.04200.2017
         nVLBCFCPSTRET                 PCPEDI.VLBCFCPSTRET%TYPE,       -- HIS.04200.2017
         nPERFCPSTRET                  PCPEDI.PERFCPSTRET%TYPE,        -- HIS.04200.2017
         nVLFCPSTRET                   PCPEDI.VLFCPSTRET%TYPE,         -- HIS.04200.2017
         nPERFCPSN                     PCPEDI.PERFCPSN%TYPE,           -- HIS.04200.2017
         nVLFECP                       PCPEDI.VLFECP%TYPE,             -- HIS.04200.2017
         nVLACRESCIMOFUNCEP            PCPEDI.VLACRESCIMOFUNCEP%TYPE,  -- HIS.04200.2017
         nPERACRESCIMOFUNCEP           PCPEDI.PERACRESCIMOFUNCEP%TYPE, -- HIS.04200.2017
         nALIQICMSFECP                 PCPEDI.ALIQICMSFECP%TYPE,       -- HIS.04200.2017
         nVLCREDFCPICMSSN              PCPEDI.VLCREDFCPICMSSN%TYPE,    -- HIS.04200.2017
         nCODCONFIGFUNCEPMED           PCPEDI.CODCONFIGFUNCEPMED%TYPE  -- HIS.04200.2017
         );
    vrDadosFuncep                      TRecDadosFuncep;
    vrLimpaDadosFuncep                 TRecDadosFuncep;

    -- Parâmetros PMC
    TYPE TRecParamPmc                  IS RECORD(
         pi_vCodFilial                 PCPEDC.CODFILIAL%TYPE,
         pi_nCodProd                   PCPEDI.CODPROD%TYPE,
         pi_vUfCliente                 PCCLIENT.ESTENT%TYPE,
         pi_nRegiao                    PCPEDC.NUMREGIAO%TYPE,
         po_nPmc                       PCPEDI.PRECOMAXCONSUM%TYPE,
         po_nPrecoFabrica              PCPEDI.PRECOMAXCONSUM%TYPE,
         po_vMensagem                  VARCHAR2(2000));
    vrParamPmc                         TRecParamPmc;

    -- Parâmetros ST Fonte
    TYPE TRecParamStFonte              IS RECORD(
         pi_vCodFilial                 PCPEDC.CODFILIAL%TYPE,
         pi_nCodProd                   PCPEDI.CODPROD%TYPE,
         pi_nCodCli                    PCPEDC.CODCLI%TYPE,
         pi_nNumRegiao                 PCPEDC.NUMREGIAO%TYPE,
         pi_nCondVenda                 PCPEDC.CONDVENDA%TYPE,
         pi_nPercVenda                 PCPEDC.PERCVENDA%TYPE,
         pio_nCodSt                    PCPEDI.CODST%TYPE,
         pi_vPVenda                    PCPEDI.PVENDA%TYPE,
         pi_nValorIpi                  PCPEDI.VLIPI%TYPE,
         pi_nPrecoMaxConsum            PCPEDI.PRECOMAXCONSUM%TYPE,
         pi_nValorUltEnt               PCEST.VALORULTENT%TYPE,
         pi_nCustoNfSemSt              PCEST.CUSTOULTENTSEMST%TYPE,
         pi_nPTabela                   PCPEDI.PTABELA%TYPE,
         pi_vSomenteIVATribut          VARCHAR2(1),
         pi_vPesquisarCustos           VARCHAR2(1),
         pi_vItemBonific               VARCHAR2(1),
         pi_nVlFreteOutrasDesp         PCPEDC.VLOUTRASDESP%TYPE,
         po_nBaseStFonte               PCPEDI.BASEICST%TYPE,
         po_nValorStFonte              PCPEDI.ST%TYPE,
         po_vMensagem                  VARCHAR2(2000),
         po_vRegimeEspIsenStFonte      PCPEDI.REGIMEESPISENSTFONTE%TYPE,
         po_nAliqIcms1                 PCPEDI.ALIQICMS1%TYPE,
         po_nAliqIcms2                 PCPEDI.ALIQICMS2%TYPE,
         po_nIva                       PCPEDI.IVA%TYPE,
         po_nPercBaseRedStFonte        PCPEDI.PERCBASEREDSTFONTE%TYPE,
         pi_vTipoChamada               VARCHAR2(1),
         pi_nQt                        PCPEDI.QT%TYPE,
         pi_nNumPedido                 PCPEDI.NUMPED%TYPE,
         pi_nCodFilialNf               PCPEDC.CODFILIALNF%TYPE,
         po_nPautaFonte                PCPEDI.PAUTA%TYPE,
         po_vObservacaoStFonte         PCPEDI.OBSERVACAOSTFONTE%TYPE,
         po_vIndEscalaRelevante        PCPEDI.INDESCALARELEVANTE%TYPE,
         po_vCnpjFabricante            PCPEDI.CNPJFABRICANTE%TYPE,
         po_vFabricante                PCPEDI.FABRICANTE%TYPE,
         po_nVlBaseFcpIcms             PCPEDI.VLBASEFCPICMS%TYPE,
         po_nVlBaseFcpSt               PCPEDI.VLBASEFCPST%TYPE,
         po_nVlBcFcpstRet              PCPEDI.VLBCFCPSTRET%TYPE,
         po_nPerFcpStRet               PCPEDI.PERFCPSTRET%TYPE,
         po_nVlFcpStRet                PCPEDI.VLFCPSTRET%TYPE,
         po_nPerFcpSn                  PCPEDI.PERFCPSN%TYPE,
         po_nVlFecp                    PCPEDI.VLFECP%TYPE,
         po_nVlAcrescimoFuncep         PCPEDI.VLACRESCIMOFUNCEP%TYPE,
         po_nPerAcrescimoFuncep        PCPEDI.PERACRESCIMOFUNCEP%TYPE,
         po_nAliqIcmsFecp              PCPEDI.ALIQICMSFECP%TYPE,
         po_nVlCredFcpIcmsSn           PCPEDI.VLCREDFCPICMSSN%TYPE,
         po_nCodConfigFuncepMed        PCPEDI.CODCONFIGFUNCEPMED%TYPE,
         pi_vOrdemCalculo              VARCHAR2(1),
         pi_vMemoriaCalculo            VARCHAR2(1),
         pi_nValorNotaFiscal           PCPEDC.VLTOTAL%TYPE);
    vrParamStFonte                     TRecParamStFonte;

    -- String para executar Bloco de Procedure
    vvBlocoExecucaoProcedure           VARCHAR2(32000);

    -- Parâmetro da Reposição de Lojas - DDMEDICA-4845
    vIGNORARCALCULOCOMISSREPLOJA       PCPARAMREPOSICAOLOJAS.VALOR%TYPE;
    vIGNORARCALCULOCOMISSREPCD         PCPARAMREPOSICAOLOJAS.VALOR%TYPE;

    -- Parâmetro se a Filial de Origem Utiliza Venda por Embalagem - DDMEDICA-5012
    vUTILIZAVENDAPOREMBALAGEM          PCPARAMFILIAL.VALOR%TYPE;
   -- vDESCSTFORAUFTRANSF                PCPARAMFILIAL.VALOR%TYPE;
    -- Estoque Indenizado - DDMEDICA-5077
    vnQtIndenizLoteDisponivel          PCEST.QTINDENIZ%TYPE;
    vnQtIndenizDisponivel              PCEST.QTINDENIZ%TYPE;
    vnQtIndenizUtilizado               PCEST.QTINDENIZ%TYPE;
    vvInformacaoLoteFab                VARCHAR2(255);
    vnTotalAvariaPrefat                NUMBER;

    -- Retorno do Faturamento do Pedido - DDMEDICA-5077
    vvErroFaturarPedido                VARCHAR2(1);
    vvMsgErroFaturarPedido             VARCHAR2(2000);
    vvErroPesqParam1                       VARCHAR2(1);
    vvMsgErroPesqParam1                VARCHAR2(2000);
    -- Verificação dos Radicais de CNPJ - DDMEDICA-5286
    v_REGRADEFINICAOGERARDESPESAS      PCPARAMREPOSICAOLOJAS.VALOR%TYPE;

    -- Arredondamento PCEMBALAGEM - DDVENDAS-37042
    vnQtUnitEmbalagem                  PCEMBALAGEM.QTUNIT%TYPE;
    vnValorIpi                         PCTABPR.VLIPI%TYPE;
    vnValorStPrecificacao              PCTABPR.VLST%TYPE;
    vnPrecoComImpostos                 PCTABPR.PVENDA1%TYPE;
    vnPrecoCusto                       PCEST.CUSTOFIN%TYPE;
    vbArredondaPreco                   BOOLEAN;
    vvRETIRAIMPOSTO201                 VARCHAR2(1);
  vnNumviasmapasep                   NUMBER;
   /**********************
    Declaração de Cursores
    **********************/

    -- Cursor de Dados de Cabeçalho classificados pelas prioriedades de
    -- atendimento definidas em cada Filial de Origem
    CURSOR c_Dados_Cab IS
      SELECT DISTINCT
             PCMED_TEMP_PED_ATAC_VAR.CODFILIAL_O
           , PCMED_TEMP_PED_ATAC_VAR.CODFILIALRETIRA_O
           , PCMED_TEMP_PED_ATAC_VAR.CODFILIAL_D
           , NVL(PCFILIALPRIORIDADE.PRIORIDADE,99) PRIORIDADE
           , PCMED_TEMP_PED_ATAC_VAR.CODFORNECPRIORIDADE
           , PCMED_TEMP_PED_ATAC_VAR.TIPO_SUG_COMPRA_TRANSF
           , PCMED_TEMP_PED_ATAC_VAR.INTEGRADORA
           , PCMED_TEMP_PED_ATAC_VAR.INTEGRADORAESPELHONF
           , PCMED_TEMP_PED_ATAC_VAR.QUEBRA1
           , PCMED_TEMP_PED_ATAC_VAR.QUEBRA2
           , PCMED_TEMP_PED_ATAC_VAR.QUEBRA3
           , PCMED_TEMP_PED_ATAC_VAR.QUEBRA4
        FROM PCMED_TEMP_PED_ATAC_VAR
           , PCFILIALPRIORIDADE
       WHERE (PCMED_TEMP_PED_ATAC_VAR.CODFILIAL_O = PCFILIALPRIORIDADE.CODFILIAL(+))
         AND (PCMED_TEMP_PED_ATAC_VAR.CODFILIAL_D = PCFILIALPRIORIDADE.CODFILIALDESTINO(+))
       ORDER BY PCMED_TEMP_PED_ATAC_VAR.CODFILIAL_O
              , PRIORIDADE;

    -- Cursor dos Itens para o Cabeçalho passado no Parâmetro com Quantidade a Transferir
    CURSOR c_Dados_Ite(pi_vFilialOrigem         IN VARCHAR2,
                       pi_vFilialRetiraOrigem   IN VARCHAR2,
                       pi_vFilialDestino        IN VARCHAR2,
                       pi_nCodFornecPrioridade  IN NUMBER,
                       pi_vTipoSugCompraTransf  IN VARCHAR2,
                       pi_vQuebra1              IN VARCHAR2,
                       pi_vQuebra2              IN VARCHAR2,
                       pi_vQuebra3              IN VARCHAR2,
                       pi_vQuebra4              IN VARCHAR2,
                       pi_nIntegradora          IN NUMBER,
                       pi_nIntegradoraEspelhoNF IN NUMBER) IS
      SELECT PCMED_TEMP_PED_ATAC_VAR.CODPROD_O
           , PCMED_TEMP_PED_ATAC_VAR.DESCRICAO_O
           , PCMED_TEMP_PED_ATAC_VAR.QTD_TRANSFERIR_O
           , PCMED_TEMP_PED_ATAC_VAR.QTD_EST_O
           , PCMED_TEMP_PED_ATAC_VAR.CODPROD_D
           , PCMED_TEMP_PED_ATAC_VAR.PRECO_TRANSF_O
           , PCMED_TEMP_PED_ATAC_VAR.SEQFALTA
           , PCMED_TEMP_PED_ATAC_VAR.QTUNITCX_D
           , PCMED_TEMP_PED_ATAC_VAR.CODAUXILIAR_O
           , PCMED_TEMP_PED_ATAC_VAR.ESTOQUEPORLOTE
           , PCMED_TEMP_PED_ATAC_VAR.NUMLOTE
        FROM PCMED_TEMP_PED_ATAC_VAR
       WHERE (PCMED_TEMP_PED_ATAC_VAR.CODFILIAL_O                 = pi_vFilialOrigem)
         AND (PCMED_TEMP_PED_ATAC_VAR.CODFILIALRETIRA_O           = pi_vFilialRetiraOrigem)
         AND (PCMED_TEMP_PED_ATAC_VAR.CODFILIAL_D                 = pi_vFilialDestino)
         AND (PCMED_TEMP_PED_ATAC_VAR.CODFORNECPRIORIDADE         = pi_nCodFornecPrioridade)
         AND (PCMED_TEMP_PED_ATAC_VAR.TIPO_SUG_COMPRA_TRANSF      = pi_vTipoSugCompraTransf)
         AND (PCMED_TEMP_PED_ATAC_VAR.QUEBRA1                     = pi_vQuebra1)
         AND (PCMED_TEMP_PED_ATAC_VAR.QUEBRA2                     = pi_vQuebra2)
         AND (PCMED_TEMP_PED_ATAC_VAR.QUEBRA3                     = pi_vQuebra3)
         AND (PCMED_TEMP_PED_ATAC_VAR.QUEBRA4                     = pi_vQuebra4)
         AND (NVL(PCMED_TEMP_PED_ATAC_VAR.INTEGRADORA,0)          = NVL(pi_nIntegradora,0))
         AND (NVL(PCMED_TEMP_PED_ATAC_VAR.INTEGRADORAESPELHONF,0) = NVL(pi_nIntegradoraEspelhoNF,0));

   /**********************************
    Procedimentos e Funcoes Auxiliares
    **********************************/

   /********************************************************************
    PROCEDURE : P_INSERE_LOG_ALTERACAO_DADOS
    DESCRIÇÃO : Insere Log de Alteração de Dados
    OBSERVACAO: pi_vTipoColuna = 'A' - Alfanumérico
                                 'N' - Number
    ********************************************************************/
    PROCEDURE P_INSERE_LOG_ALTERACAO_DADOS(pi_vTipoColuna      IN VARCHAR2,
                                           pi_nNumPed          IN NUMBER,
                                           pi_vTabela          IN VARCHAR2,
                                           pi_nColuna          IN VARCHAR2,
                                           pi_vTextoNew        IN VARCHAR2,
                                           pi_vTextoOld        IN VARCHAR2,
                                           pi_vNumeroNew       IN NUMBER,
                                           pi_vNumeroOld       IN NUMBER,
                                           pi_vMotivoResumido  IN VARCHAR2,
                                           pi_vMotivoDetalhado IN VARCHAR2) IS
      vvHost     VARCHAR2(64);
      vvModule   VARCHAR2(30);
      vvOsUser   VARCHAR2(30);
    BEGIN

      BEGIN

        -- Sessão
        SELECT SUBSTR(sys_context ('USERENV', 'HOST'),1,64)
             , SUBSTR(sys_context ('USERENV', 'MODULE'),1,30)
             , SUBSTR(sys_context ('USERENV', 'OS_USER'),1,30)
          INTO vvHost
             , vvModule
             , vvOsUser
          FROM DUAL;

         -- Insere Log
         INSERT INTO PCLOGALTERACAODADOS
                  ( DATA,
                    CODFUNC,
                    CODROTINA,
                    TABELA,
                    COLUNA,
                    TIPOVALOR,
                    VALORNUM,
                    VALORNUMANT,
                    VALORALFA,
                    VALORALFAANT,
                    OBSERVACOES,
                    OBSERVACOES2,
                    OBSERVACOES3,
                    MAQUINA,
                    PROGRAMA,
                    OSUSER )
           VALUES ( SYSDATE,
                    pi_nCodMatricula,
                    3602,
                    pi_vTabela,
                    pi_nColuna,
                    pi_vTipoColuna,
                    DECODE(pi_vTipoColuna,'N',pi_vNumeroNew,NULL),
                    DECODE(pi_vTipoColuna,'N',pi_vNumeroOld,NULL),
                    DECODE(pi_vTipoColuna,'A',pi_vTextoNew,NULL),
                    DECODE(pi_vTipoColuna,'A',pi_vTextoOld,NULL),
                    SUBSTR(pi_vMotivoResumido ||' DO PEDIDO: ' || pi_nNumPed,1,100),
                    pi_vMotivoDetalhado,
                    NULL,
                    vvHost,
                    vvModule,
                    vvOsUser);

      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;

    END P_INSERE_LOG_ALTERACAO_DADOS;

    ------------------------------------------------------------------------------
    -- Procedimento para Obter o Parâmetro da Filial NUMBER
    ------------------------------------------------------------------------------
    PROCEDURE POBTEM_PARAMFILIAL_NUMBER(pi_vCodFilial IN  VARCHAR2,
                                        pi_vNomeCampo IN  VARCHAR2,
                                        po_nValor     OUT NUMBER,
                                        po_vErro      OUT VARCHAR2,
                                        po_vMsgErro   OUT VARCHAR2) IS

      vvValorString PCPARAMFILIAL.VALOR%TYPE;

    BEGIN
      -- Inicializa Retornos
      po_nValor   := 0;
      po_vErro    := 'N';
      po_vMsgErro := NULL;

      -- Pesquisa Parametro
      BEGIN
        SELECT PCPARAMFILIAL.VALOR
          INTO vvValorString
          FROM PCPARAMFILIAL
         WHERE (PCPARAMFILIAL.CODFILIAL = pi_vCodFilial)
           AND (PCPARAMFILIAL.NOME      = pi_vNomeCampo);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          po_vErro      := 'S';
          po_vMsgErro   := 'Não foi encontrado o parâmetro "' || pi_vNomeCampo || '" na filial ' || pi_vCodFilial;
          vvValorString := NULL;
      END;

      -- Se não ocorreu erro ao pesquisar o parâmetro
      IF (po_vErro = 'N') THEN

        -- Tira Espaços em Branco do Valor
        vvValorString := TRIM(vvValorString);
        IF (vvValorString IS NULL) THEN
          vvValorString := '0';
        END IF;

        -- Converte String para Number
        BEGIN
          po_nValor := TO_NUMBER(vvValorString);
        EXCEPTION
          WHEN OTHERS THEN
            po_vErro      := 'S';
            po_vMsgErro   := 'Erro ao converter em numérico o texto "' || vvValorString || '" do parâmetro "' || pi_vNomeCampo || '" na filial ' || pi_vCodFilial;
            po_nValor     := 0;
        END;

      END IF; -- Fim Condição Se não ocorreu erro ao pesquisar o parâmetro

    END POBTEM_PARAMFILIAL_NUMBER;

    ------------------------------------------------------------------------------
    -- Função para Obter o Próximo Número do Pedido
    ------------------------------------------------------------------------------
    FUNCTION FOBTEM_PROX_NUMPED(pi_nCodUsur IN NUMBER)
    RETURN NUMBER IS
      vnRetProxNumPed NUMBER;
    BEGIN

      -- Como o Código do RCA é obrigatório, e já foi validado anteriormente,
      -- sempre vai encontrar dados
      BEGIN
        SELECT NVL(PROXNUMPED,0) PROXNUMPED
          INTO vnRetProxNumPed
          FROM PCUSUARI
         WHERE CODUSUR = pi_nCodUsur
           FOR UPDATE;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnRetProxNumPed := 0;
      END;

      -- Incrementa Número do Pedido
      UPDATE PCUSUARI
         SET PROXNUMPED = NVL(PROXNUMPED,0) + 1
       WHERE (CODUSUR = pi_nCodUsur);

      -- Efetiva Transações
      COMMIT;

      -- Retorna o Sequencial
      RETURN vnRetProxNumPed;

    END FOBTEM_PROX_NUMPED;

    ------------------------------------------------------------------------------
    -- Função para Obter o Próximo Número do Pedido RCA
    ------------------------------------------------------------------------------
    FUNCTION FOBTEM_PROX_NUMPEDRCA(pi_nCodUsur IN NUMBER)
    RETURN NUMBER IS
      vnRetProxNumPedForca NUMBER;
    BEGIN

      -- Como o Código do RCA é obrigatório, e já foi validado anteriormente,
      -- sempre vai encontrar dados
      BEGIN
        SELECT NVL(PROXNUMPEDFORCA,0) PROXNUMPEDFORCA
          INTO vnRetProxNumPedForca
          FROM PCUSUARI
         WHERE CODUSUR = pi_nCodUsur
           FOR UPDATE;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnRetProxNumPedForca := 0;
      END;

      -- Incrementa Número do Pedido
      UPDATE PCUSUARI
         SET PROXNUMPEDFORCA = NVL(PROXNUMPEDFORCA,0) + 1
       WHERE (CODUSUR = pi_nCodUsur);

      -- Efetiva Transações
      COMMIT;

      -- Retorna o Sequencial
      RETURN vnRetProxNumPedForca;

    END FOBTEM_PROX_NUMPEDRCA;

    ------------------------------------------------------------------------------
    -- Função para Obter o Código do Projeto da Integradora
    ------------------------------------------------------------------------------
    FUNCTION FOBTEM_CODIGOPROJETO_INTEGRAD(pi_nIntegradora IN NUMBER)
    RETURN VARCHAR2 IS
      vvRetCodigoProjeto PCINTEGRADORA.CODIGOPROJETO%TYPE;
    BEGIN

      -- Como o Código do RCA é obrigatório, e já foi validado anteriormente,
      -- sempre vai encontrar dados
      BEGIN
        SELECT PCINTEGRADORA.CODIGOPROJETO
          INTO vvRetCodigoProjeto
          FROM PCINTEGRADORA
         WHERE INTEGRADORA = pi_nIntegradora;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvRetCodigoProjeto := '';
      END;

      -- Retorna o Código Projeto
      RETURN vvRetCodigoProjeto;

    END FOBTEM_CODIGOPROJETO_INTEGRAD;

    ----------------------------------------------------------------------------------
    -- Função para verificar se o próximo número do pedido é válido - 4056.125049.2015
    ----------------------------------------------------------------------------------
    FUNCTION F_PROX_NUMPED_VALIDO(pi_nNumPed  IN NUMBER)
    RETURN BOOLEAN IS
      vvPedidoExiste VARCHAR2(1);
      vbNumPedValido BOOLEAN;
    BEGIN

      -- Verifica se o Pedido já existe
      BEGIN
        SELECT 'S'
          INTO vvPedidoExiste
          FROM PCPEDC
         WHERE (NUMPED = pi_nNumPed);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvPedidoExiste := 'N';
      END;

      -- Se já existe Pedido
      IF (vvPedidoExiste = 'S') THEN
        vbNumPedValido := FALSE;
      ELSE
        vbNumPedValido := TRUE;
      END IF;

      -- Retorna se Número de Pedido Válido
      RETURN vbNumPedValido;

    END F_PROX_NUMPED_VALIDO;

    ------------------------------------------------------------------------------
    -- Função para Obter o Próximo Número da Sugestão de Compra
    ------------------------------------------------------------------------------
    FUNCTION FOBTEM_PROX_NUMSUGESTAO
    RETURN NUMBER IS
      vnRetProxNumSugestao NUMBER;
    BEGIN

      SELECT NVL(DFSEQ_PCSUGESTAOCOMPRAC.NEXTVAL,0) PROXNUMSUGESTAO
        INTO vnRetProxNumSugestao
        FROM DUAL;

      -- Retorna o Sequencial
      RETURN vnRetProxNumSugestao;

    END FOBTEM_PROX_NUMSUGESTAO;

    ------------------------------------------------------------------------------
    -- Função para Obter o Próximo Número de Pedido de Operador Logístico
    ------------------------------------------------------------------------------
    FUNCTION FOBTEM_PROX_NUMPEDOPERLOG
    RETURN NUMBER IS
      vnRetProxNumPedOperLog NUMBER;
    BEGIN

      SELECT NVL(PCPEDCOMPRAOPERLOGCAB_DFSEQ.NEXTVAL,0) PROXNUMPEDOPERLOG
        INTO vnRetProxNumPedOperLog
        FROM DUAL;

      -- Retorna o Sequencial
      RETURN vnRetProxNumPedOperLog;

    END FOBTEM_PROX_NUMPEDOPERLOG;

    ------------------------------------------------------------------------------
    -- Função para Obter o Próximo Número da Sugestão de Reposição
    ------------------------------------------------------------------------------
    FUNCTION FOBTEM_PROX_NUMSUGESTAOREP
    RETURN NUMBER IS
      vnRetProxNumSugestaoRep NUMBER;
    BEGIN

      SELECT NVL(DFSEQ_PCSUGESTAOREPOSICAOMED.NEXTVAL,0) PROXNUMSUGESTAOREP
        INTO vnRetProxNumSugestaoRep
        FROM DUAL;

      -- Retorna o Sequencial
      RETURN vnRetProxNumSugestaoRep;

    END FOBTEM_PROX_NUMSUGESTAOREP;

    ------------------------------------------------------------------------------
    -- Função para Determinar se Usa CFOP de Venda
    ------------------------------------------------------------------------------
    FUNCTION FUSA_CFOP_VENDA(pi_vCgcCliente IN VARCHAR2,
                             pi_vCgcFilial  IN VARCHAR2)
    RETURN VARCHAR2 IS
      vvRetUsaCfopVenda VARCHAR2(1);
      vvCgcCliente      VARCHAR2(100);
      vvCgcFilial       VARCHAR2(100);
    BEGIN
      -- Pega o CGC do Cliente e retira caracteres especiais
      vvCgcCliente := TRIM(REPLACE(REPLACE(REPLACE(REPLACE(pi_vCgcCliente,'.',''),'/',''),'\',''),'-',''));
      -- Pega o CGC da Filial e retira caracteres especiais
      vvCgcFilial := TRIM(REPLACE(REPLACE(REPLACE(REPLACE(pi_vCgcFilial,'.',''),'/',''),'\',''),'-',''));

      -- Se a Raiz do CNPJ do Cliente for igual ao da Filial
      IF (SUBSTR(vvCgcCliente,1,8) = SUBSTR(vvCgcFilial,1,8)) THEN
        -- Não usa CFOP de Venda, será usado o de Transferência
        vvRetUsaCfopVenda := 'N';
      ELSE
        -- Usa CFOP de Venda
        vvRetUsaCfopVenda := 'S';
      END IF;

      -- Retorno
      RETURN vvRetUsaCfopVenda;

    END FUSA_CFOP_VENDA;

   /******************************************************************************
    FUNCAO   : FCALCULARPRECOVENDATRANSF
    DESCRICAO: Agregar no Preço de Venda da Transferência o ICMS
    ******************************************************************************/
    FUNCTION FCALCULARPRECOVENDATRANSF(pi_nPTabela    IN NUMBER,
                                       pi_nCodSt      IN NUMBER,
                                       pi_vCgcCliente IN VARCHAR2,
                                       pi_vCgcFilial  IN VARCHAR2)
    RETURN NUMBER IS
      vnRetPrecoTransf PCPEDI.PTABELA%TYPE;
    BEGIN

      -- Se Venda
      IF (FUSA_CFOP_VENDA(pi_vCgcCliente,
                          pi_vCgcFilial) = 'S') THEN
        -- Aplica CODICM
        BEGIN
          SELECT CASE WHEN NVL(AGREGARICMSNOVLTRANSF, 'N') = 'N' THEN
                   pi_nPTabela
                 ELSE
                   pi_nPTabela / (1 -  ((NVL(PCTRIBUT.CODICM, 0)/100) *
                                        DECODE (NVL(PCTRIBUT.PERCBASERED,0), 0 , 100, PCTRIBUT.PERCBASERED)/100) )
                 END PVENDA
                INTO vnRetPrecoTransf
                FROM PCTRIBUT
               WHERE CODST = pi_nCodSt;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnRetPrecoTransf := pi_nPTabela;
        END;
      -- Se Transferência
      ELSE
        -- Aplica CODICMTRANSF
        BEGIN
          SELECT CASE WHEN NVL(AGREGARICMSNOVLTRANSF, 'N') = 'N' THEN
                   pi_nPTabela
                 ELSE
                   pi_nPTabela / (1 -  ((NVL(PCTRIBUT.CODICMTRANSF, 0)/100) *
                                        DECODE (NVL(PCTRIBUT.PERCBASEREDTRANFSAID,0), 0 , 100, PCTRIBUT.PERCBASEREDTRANFSAID)/100) )
                 END PVENDA
                INTO vnRetPrecoTransf
                FROM PCTRIBUT
               WHERE CODST = pi_nCodSt;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnRetPrecoTransf := pi_nPTabela;
        END;
      END IF;

      -- Retorno
      RETURN vnRetPrecoTransf;

    END FCALCULARPRECOVENDATRANSF;

    ------------------------------------------------------------------------------
    -- Função para Calcular o ST
    ------------------------------------------------------------------------------
    FUNCTION FCALCULAR_ST(pi_vTIPOCUSTOTRANSF        IN VARCHAR2,
                          pi_vCODFILIAL              IN VARCHAR2,
                          pi_vCODFILIANF             IN VARCHAR2,
                          pi_vCODFILIALRETIRA        IN VARCHAR2,
                          pi_nCODCLI                 IN NUMBER,
                          pi_nCODPLPAG               IN NUMBER,
                          pi_nCODPROD                IN NUMBER,
                          pi_nCODAUXILIAR            IN NUMBER,
                          pi_nCONDVENDA              IN NUMBER,
                          pi_nPTABELA                IN NUMBER,
                          pi_nVLST_TABPRECOS         IN NUMBER,
                          pio_vMensagem              IN OUT VARCHAR2,
                          pio_nST                    IN OUT NUMBER,
                          pio_nBASEST                IN OUT NUMBER,
                          pio_nVALORIPI              IN OUT NUMBER,
                          pio_nBASEFECP              IN OUT NUMBER,
                          pio_nALIQFECP              IN OUT NUMBER,
                          pio_nVLFECP                IN OUT NUMBER,
                          po_vINDESCALARELEVANTE     OUT VARCHAR2, -- HIS.03379.2017
                          po_vCNPJFABRICANTE         OUT VARCHAR2, -- HIS.03379.2017
                          po_vFABRICANTE             OUT VARCHAR2, -- HIS.03379.2017
                          po_nPrecoSemImposto        OUT NUMBER,   -- MED-1573
                          pi_nPRECOCUSTO             IN NUMBER,       -- DDVENDAS-37042
                          pio_vOBSERVACAOSTFONTE     IN OUT VARCHAR2, -- DDVENDAS-37042
                          pi_vRETIRAIMPOSTO201       IN VARCHAR2)
    RETURN BOOLEAN IS

      -- Declaração de Variáveis da Função
      vbResult             BOOLEAN;
      vnBaseST             NUMBER;
      vnValorST            NUMBER;
      vvMensagem           VARCHAR2(240);
      --
      vnPTabelaSemImpostos NUMBER;
      vnBaseFecp           NUMBER;
      vnAliqFecp           NUMBER;
      vnVlFecp             NUMBER;

    BEGIN

      -- Inicializa Variáveis
      vbResult     := FALSE;
      vnBaseST     := 0;
      vnValorST    := 0;
      vvMensagem   := '';

     /*****************************************************
      Pesquisa Dados do Produto por Filial - HIS.03371.2017
      *****************************************************/
      BEGIN
        SELECT NVL(PCPRODFILIAL.INDESCALARELEVANTE,'S') -->> PADRÃO SIM PARA CALCULAR ST (INDUSTRIA FARMACEUTICA RELEVANTE)
             , PCPRODFILIAL.CNPJFABRICANTE
             , PCPRODFILIAL.FABRICANTE
          INTO po_vINDESCALARELEVANTE
             , po_vCNPJFABRICANTE
             , po_vFABRICANTE
          FROM PCPRODFILIAL
         WHERE (CODPROD   = pi_nCODPROD)
           AND (CODFILIAL = pi_vCODFILIAL);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          po_vINDESCALARELEVANTE := 'S'; -->> PADRÃO SIM PARA CALCULAR ST (INDUSTRIA FARMACEUTICA RELEVANTE)
          po_vCNPJFABRICANTE     := NULL;
          po_vFABRICANTE         := NULL;
      END;

      BEGIN

        -- PREÇO TABELA: SE TRANSFERINDO PELO CUSTO
        IF (NVL(pi_vTIPOCUSTOTRANSF,' ') IN ('E','R','C','F','U','V','S','T','O','A')) AND
           (NVL(pi_nPRECOCUSTO,0) > 0) THEN -- DDVENDAS-37042

          vnPTabelaSemImpostos := NVL(pi_nPRECOCUSTO,0); -->> O PREÇO DE TABELA AQUI JÁ É O CUSTO

          pio_vOBSERVACAOSTFONTE := pio_vOBSERVACAOSTFONTE || ' ; Custo ' || vnPTabelaSemImpostos;

        -- PREÇO TABELA: SE TRANSFERINDO PELO PRECO DE VENDA
        ELSE

          -- Calcula o Preço sem Imposto
          BEGIN
            SELECT VALORSEMIMPOSTO
              INTO vnPTabelaSemImpostos
            FROM TABLE(PKG_TRIBUTACAO.CALCULAR_PVENDA_SEM_IMPOSTO(pi_vCODFILIAL,
                                                                  pi_vCODFILIANF,
                                                                  pi_vCODFILIALRETIRA,
                                                                  pi_nCODCLI,
                                                                  pi_nCODPLPAG,
                                                                  pi_nCODPROD,
                                                                  pi_nCODAUXILIAR,
                                                                  pi_nCONDVENDA,
                                                                  'N',
                                                                  pi_nVLST_TABPRECOS, -- PASSA O ST DA 201 PARA AUXILIAR A RETORNAR O PREÇO SEM IMPOSTOS
                                                                  0,
                                                                  pi_nPTABELA, -- PASSA O PREÇO DA 201 PARA RETORNAR ELE SEM IMPOSTOS
                                                                  pi_vRETIRAIMPOSTO201,
                                                                  'S',
                                                                  'N'));
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vnPTabelaSemImpostos := 0;
          END;

          pio_vOBSERVACAOSTFONTE := pio_vOBSERVACAOSTFONTE || ' ; PTabelaSemImpostos ' || vnPTabelaSemImpostos;

        END IF; -- FIM CONDIÇÃO: DEFINE PREÇO TABELA

        -- VALOR IPI
        BEGIN
          SELECT VALORIPI
            INTO pio_nVALORIPI
          FROM TABLE(PKG_TRIBUTACAO.CALCULAR_IPI(pi_vCODFILIAL,
                                                 pi_vCODFILIANF,
                                                 pi_vCODFILIALRETIRA,
                                                 pi_nCODCLI,
                                                 pi_nCODPROD,
                                                 pi_nCODAUXILIAR,
                                                 pi_nCONDVENDA,
                                                 'N',
                                                 vnPTabelaSemImpostos,
                                                 'N'));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            pio_nVALORIPI := 0;
        END;

        -- BASE E VALOR DO ST
        -- DDMEDICA-579 - Novos parâmetros de entrada para que possam ser usadas as alíquotas da aba transferência da rotina 514
        BEGIN
          SELECT BASEST
               , ST
               , BASEFECP
               , ALIQFECP
               , VLRFECP
            INTO vnBaseST
               , vnValorST
               , vnBaseFecp
               , vnAliqFecp
               , vnVlFecp
          FROM TABLE(PKG_TRIBUTACAO.CALCULAR_ST(pi_vCODFILIAL,
                                                pi_vCODFILIANF,
                                                pi_vCODFILIALRETIRA,
                                                pi_nCODCLI,
                                                pi_nCODPLPAG,
                                                pi_nCODPROD,
                                                pi_nCODAUXILIAR,
                                                pi_nCONDVENDA,
                                                'N',
                                                vnPTabelaSemImpostos,
                                                0,
                                                'N',
                                                0,
                                                0,
                                                0,
                                                NULL,
                                                'S'  --HIS.01188.2013 (verifique história)
                                                )); --DDVENDAS-37042 - Igual a 316 para não dar diferença de ST (pTransferencia indica que é 1419 ou 1436, não para a 316)
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnBaseST   := 0;
            vnValorST  := 0;
            vnBaseFecp := 0;
            vnAliqFecp := 0;
            vnVlFecp   := 0;
        END;

        -- Sucesso no Cálculo do ST
        vbResult := TRUE;

      EXCEPTION
        WHEN OTHERS THEN
          vvMensagem := SUBSTR(SQLERRM,1,240);
      END;

      -- Verificado no Cliente que rejeita se tiver Base mas não tiver Valor
      IF (NVL(vnValorST,0) = 0) THEN
        vnBaseST := 0;
      END IF;

      -- Atualiza Retornos da Função
      pio_nST       := vnValorST;
      pio_nBASEST   := vnBaseST;
      --
      pio_nBASEFECP := vnBaseFecp;
      pio_nALIQFECP := vnAliqFecp;
      pio_nVLFECP   := vnVlFecp;
      --
      pio_vMensagem := vvMensagem;
      --
      po_nPrecoSemImposto := vnPTabelaSemImpostos; -- MED-1573
      -- Retorno de Sucesso
      RETURN vbResult;

    END FCALCULAR_ST;

    ------------------------------------------------------------------------------
    -- Procedimento para Atualizar a Qtde. Pendente
    ------------------------------------------------------------------------------
    PROCEDURE PATUALIZA_MENSAGEM_ESTOQUE(pi_vMsgErroEstoque IN VARCHAR2) IS
    BEGIN
      IF (vtItensPedGerados.COUNT > 0) THEN
        FOR viIdxMsgEstoque IN vtItensPedGerados.FIRST..vtItensPedGerados.LAST LOOP

          -- Gera novo Sequencial
          viSeqMensAux := NVL(vtMensagensAux.COUNT,0) + 1;

          -- Adiciona Mensagem ao Array
          vtMensagensAux(viSeqMensAux).vnCodFilial_O      := vtItensPedGerados(viIdxMsgEstoque).vCODFILIAL_O;
          vtMensagensAux(viSeqMensAux).vnCodProd_O        := vtItensPedGerados(viIdxMsgEstoque).nCODPROD_O;
          vtMensagensAux(viSeqMensAux).vvDescricao_O      := vtItensPedGerados(viIdxMsgEstoque).vDESCRICAO_O;
          vtMensagensAux(viSeqMensAux).vnQtdeTransferir_O := vtItensPedGerados(viIdxMsgEstoque).nQTD_TRANSFERIR_O; -->> Qtde. Transferir Original sem Cortes
          vtMensagensAux(viSeqMensAux).vnCodFilial_D      := vtItensPedGerados(viIdxMsgEstoque).vCODFILIAL_D;
          vtMensagensAux(viSeqMensAux).vnCodProd_D        := vtItensPedGerados(viIdxMsgEstoque).nCODPROD_D;
          vtMensagensAux(viSeqMensAux).vvMensagem         := SUBSTR(pi_vMsgErroEstoque,1,240);

        END LOOP;
      END IF;
    END;

    ------------------------------------------------------------------------------
    -- Procedimento para Atualizar a Qtde. Pendente
    ------------------------------------------------------------------------------
    FUNCTION FATUALIZA_QTPENDENTE(pi_vCodFilial IN VARCHAR2,
                                  pi_nNumPed    IN NUMBER)
    RETURN BOOLEAN IS
      -- Declaração de Tipos de Variáveis
      TYPE TT_PED_NUMPED    IS TABLE OF PCPEDI.NUMPED%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_PED_CODFILIAL IS TABLE OF PCPEDC.CODFILIAL%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_PED_CODPROD   IS TABLE OF PCPEDI.CODPROD%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_PED_QT        IS TABLE OF PCPEDI.QT%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_PED_DTSAIDA   IS TABLE OF DATE INDEX BY BINARY_INTEGER;
      -- Declaração de Variáveis
      vtPED_NUMPED           TT_PED_NUMPED;
      vtPED_CODFILIAL        TT_PED_CODFILIAL;
      vtPED_CODPROD          TT_PED_CODPROD;
      vtPED_QT               TT_PED_QT;
      vtPED_DTSAIDA          TT_PED_DTSAIDA;
      -- MED-1876 - Retorno Package Estoque
      vvMsgRetornoPkgEstoque VARCHAR2(2000);
      vvValidoPkgEstoque     VARCHAR2(1);
      e_PkgEstoque           EXCEPTION;
    BEGIN

      -- Limpa Arrays
      vtPED_NUMPED.DELETE;
      vtPED_CODFILIAL.DELETE;
      vtPED_CODPROD.DELETE;
      vtPED_QT.DELETE;
      vtPED_DTSAIDA.DELETE;

      -- Carrega Itens do Pedido em Array
      SELECT PCPEDI.NUMPED
           , pi_vCodFilial
           , PCPEDI.CODPROD
           , PCPEDI.QT
           , TRUNC(SYSDATE)
        BULK COLLECT INTO vtPED_NUMPED
                        , vtPED_CODFILIAL
                        , vtPED_CODPROD
                        , vtPED_QT
                        , vtPED_DTSAIDA
        FROM PCPEDI
       WHERE (NUMPED = pi_nNumPed);

      -- Se carregou Array com Itens do Pedido
      IF (vtPED_NUMPED.COUNT > 0) THEN

         -- Executa Bloco de Atualização ForAll na Tabela PCEST
         FORALL viIndPos IN vtPED_NUMPED.FIRST..vtPED_NUMPED.LAST
           UPDATE PCEST
              SET PCEST.DTULTSAIDA = vtPED_DTSAIDA(viIndPos)
            WHERE (PCEST.CODPROD   = vtPED_CODPROD(viIndPos))
              AND (PCEST.CODFILIAL = vtPED_CODFILIAL(viIndPos));

      END IF; -- Fim Condição Se carregou Array com Itens do Pedido

      -- Atualiza Estoque Pendente
      vvValidoPkgEstoque := PKG_ESTOQUE.PENDENTE_INCLUIR_PEDIDO(vrPedido.nNUMPED,
                                                                'IN',
                                                                vvMsgRetornoPkgEstoque);
      IF (NVL(vvValidoPkgEstoque,'N') <> 'S') THEN
        RAISE e_PkgEstoque;
      END IF;

      -- EFETIVA TRANSAÇÕES
      COMMIT;

      -- LIMPA ARRAY com Itens Inseridos Pedido Commitado
      vtItensPedGerados.DELETE;

      -- RETORNO SUCESSO
      RETURN TRUE;

    EXCEPTION
      -- MED-1876 - Erro Tratado
      WHEN e_PkgEstoque THEN
        ROLLBACK;
        -- Atualiza Log
        PATUALIZA_MENSAGEM_ESTOQUE('Erro Objeto Estoque: ' || vvMsgRetornoPkgEstoque);
        -- LIMPA ARRAY com Itens Inseridos Pedido Commitado
        vtItensPedGerados.DELETE;
        -- RETORNO ERRO
        RETURN FALSE;
      -- MED-1876 - Erro Genérico
      WHEN OTHERS THEN
        ROLLBACK;
        -- Atualiza Log
        PATUALIZA_MENSAGEM_ESTOQUE('Erro Estoque Pendente: ' || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM,1,2000));
        -- LIMPA ARRAY com Itens Inseridos Pedido Commitado
        vtItensPedGerados.DELETE;
        -- RETORNO ERRO
        RETURN FALSE;
    END FATUALIZA_QTPENDENTE;

    ------------------------------------------------------------------------------
    -- Procedimento para Liberar Pedido
    ------------------------------------------------------------------------------
    PROCEDURE PLIBERA_PEDIDO(pi_vCodFilial                 IN VARCHAR2,
                             pi_nNumPed                    IN NUMBER,
                             pi_dData                      IN DATE,
                             pi_nCodUsur                   IN NUMBER,
                             pi_nCodCli                    IN NUMBER,
                             pi_vFantasia                  IN VARCHAR2,
                             pi_vUSAQTUNITPCEMBREPLOJA     IN VARCHAR2,
                             pi_vUSAREGRAARREDEMBFRNFTAREP IN VARCHAR2,
                             pi_vCodFilialRetira           IN VARCHAR2) IS

      -- Declaração de Tipos de Variáveis
      TYPE TT_PED_NUMPED         IS TABLE OF PCPEDI.NUMPED%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_PED_CODPROD        IS TABLE OF PCPEDI.CODPROD%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_PED_QT             IS TABLE OF PCPEDI.QT%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_PED_PVENDA         IS TABLE OF PCPEDI.PVENDA%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_PED_PTABELA        IS TABLE OF PCPEDI.PTABELA%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_PED_NUMSEQ         IS TABLE OF PCPEDI.NUMSEQ%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_PED_DTSAIDA        IS TABLE OF DATE INDEX BY BINARY_INTEGER;
      TYPE TT_PED_QTUNITEMB      IS TABLE OF PCPEDI.QTUNITEMB%TYPE INDEX BY BINARY_INTEGER;
      --
      TYPE TT_EST_CODPROD        IS TABLE OF PCEST.CODPROD%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_EST_QTESTGER       IS TABLE OF PCEST.QTESTGER%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_EST_QTPENDENTE     IS TABLE OF PCEST.QTPENDENTE%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_EST_QTRESERV       IS TABLE OF PCEST.QTRESERV%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_EST_QTBLOQUEADA    IS TABLE OF PCEST.QTBLOQUEADA%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_EST_QTVENDAPERDIDA IS TABLE OF PCEST.QTVENDAPERDIDA%TYPE INDEX BY BINARY_INTEGER;
      TYPE TT_EST_DTULTSAIDA     IS TABLE OF PCEST.DTULTSAIDA%TYPE INDEX BY BINARY_INTEGER;
      -- Declaração de Variáveis
      vtPED_NUMPED               TT_PED_NUMPED;
      vtPED_CODPROD              TT_PED_CODPROD;
      vtPED_QT                   TT_PED_QT;
      vtPED_PVENDA               TT_PED_PVENDA;
      vtPED_PTABELA              TT_PED_PTABELA;
      vtPED_NUMSEQ               TT_PED_NUMSEQ;
      vtPED_DTSAIDA              TT_PED_DTSAIDA;
      vtPED_QTUNITEMB            TT_PED_QTUNITEMB;
      --
      vtEST_IND_CODPROD          TT_EST_CODPROD;
      vtEST_CODPROD              TT_EST_CODPROD;
      vtEST_QTESTGER             TT_EST_QTESTGER;
      vtEST_QTPENDENTE           TT_EST_QTPENDENTE;
      vtEST_QTRESERV             TT_EST_QTRESERV;
      vtEST_QTBLOQUEADA          TT_EST_QTBLOQUEADA;
      vtEST_QTVENDAPERDIDA       TT_EST_QTVENDAPERDIDA;
      vtEST_DTULTSAIDA           TT_EST_DTULTSAIDA;
      -- Outras Variáveis
      --vbProblemasBaixarEstoque   BOOLEAN;
      --vbEncontrouProdutoPCEST    BOOLEAN;
      vnCodProd                  PCPEDI.CODPROD%TYPE;
      vnQtdeOriginalPedido       PCPEDI.QT%TYPE;
      vnQtdeAtend                PCPEDI.QT%TYPE;
      vnPVenda                   PCPEDI.PVENDA%TYPE;
      vnPTabela                  PCPEDI.PTABELA%TYPE;
      vnNumSeq                   PCPEDI.NUMSEQ%TYPE;
      vnQtUnitEmb                PCPEDI.QTUNITEMB%TYPE;
      vnEstoqueDisponivel        PCEST.QTEST%TYPE;
      vnQtdeFalta                PCPEDI.QTFALTA%TYPE;
      vnQtdeGuardaFalta          PCPEDI.QTFALTA%TYPE;
      vvDescricaoExclusaoPedido  VARCHAR2(80);
      vnVlTotalOriginalPedido    PCPEDC.VLTOTAL%TYPE;
      -- Variáveis Totalizadoras do Pedido
      vnTotQTITENS               NUMBER(10);
      vnTotVLCUSTOFIN            PCPEDC.VLCUSTOFIN%TYPE;
      vnTotVLCUSTOREAL           PCPEDC.VLCUSTOREAL%TYPE;
      vnTotVLCUSTOCONT           PCPEDC.VLCUSTOCONT%TYPE;
      vnTotVLCUSTOREP            PCPEDC.VLCUSTOREP%TYPE;
      vnTotVLTABELA              PCPEDC.VLTABELA%TYPE;
      vnTotVLATEND               PCPEDC.VLATEND%TYPE;
      vnTotTOTPESO               PCPEDC.TOTPESO%TYPE;
      vnTotTOTVOLUME             PCPEDC.TOTVOLUME%TYPE;
      vnTotVLTOTAL               PCPEDC.VLTOTAL%TYPE;
      -- Variável para Cálculo do QTPENDENTE
      vnNovaQtPendente           PCEST.QTPENDENTE%TYPE;
      -- MED-1876 - Retorno Package Estoque
      vvMsgRetornoPkgEstoque     VARCHAR2(2000);
      vvValidoPkgEstoque         VARCHAR2(1);
      e_PkgEstoquePendente       EXCEPTION;
      e_PkgEstoqueReservado      EXCEPTION;
      -- Exceção
      e_AbortaBaixaEstoque       EXCEPTION;


     /******************************************************************************
      REGRA ESPECÍFICA - Utilizar Arredondamento da Embalagem do Fornecedor na Falta
      ******************************************************************************/
      FUNCTION F_RETORNAR_QT_ARREOND_EMB_FORN(pi_nNumPed    IN NUMBER,
                                              pi_nCodProd   IN NUMBER,
                                              pi_nQtdeAtend IN NUMBER)
      RETURN NUMBER IS
        -- Variáveis para Arredondamento da Embalagem do Fornecedor na Falta
        vCODFILIAL_O          PCMED_TEMP_TRANSF_ATAC_VAR.CODFILIAL_O%TYPE;
        nCODPROD_O            PCMED_TEMP_TRANSF_ATAC_VAR.CODPROD_O%TYPE;
        vDESCRICAO_O          PCMED_TEMP_TRANSF_ATAC_VAR.DESCRICAO_O%TYPE;
        vCODFILIAL_D          PCMED_TEMP_TRANSF_ATAC_VAR.CODFILIAL_D%TYPE;
        nCODPROD_D            PCMED_TEMP_TRANSF_ATAC_VAR.CODPROD_D%TYPE;
        vEMB_POR_FORNECEDOR_O PCMED_TEMP_TRANSF_ATAC_VAR.EMB_POR_FORNECEDOR_O%TYPE;
        nQTUNITCX_O           PCMED_TEMP_TRANSF_ATAC_VAR.QTUNITCX_O%TYPE;
        --
        viSeqMensagem         INTEGER;
        -- Retorno
        vnRetQtAtend          NUMBER;
      BEGIN
        -- Inicializa Retorno
        vnRetQtAtend := NVL(pi_nQtdeAtend,0);

        -- Pesquisa memória de cálculo
        BEGIN
          SELECT PCMED_TEMP_TRANSF_ATAC_VAR.CODFILIAL_O
               , PCMED_TEMP_TRANSF_ATAC_VAR.CODPROD_O
               , PCMED_TEMP_TRANSF_ATAC_VAR.DESCRICAO_O
               , PCMED_TEMP_TRANSF_ATAC_VAR.CODFILIAL_D
               , PCMED_TEMP_TRANSF_ATAC_VAR.CODPROD_D
               , PCMED_TEMP_TRANSF_ATAC_VAR.EMB_POR_FORNECEDOR_O
               , PCMED_TEMP_TRANSF_ATAC_VAR.QTUNITCX_O
            INTO vCODFILIAL_O
               , nCODPROD_O
               , vDESCRICAO_O
               , vCODFILIAL_D
               , nCODPROD_D
               , vEMB_POR_FORNECEDOR_O
               , nQTUNITCX_O
            FROM PCMED_TEMP_TRANSF_ATAC_VAR
           WHERE (PCMED_TEMP_TRANSF_ATAC_VAR.NUMPED    = pi_nNumPed)
             AND (PCMED_TEMP_TRANSF_ATAC_VAR.CODPROD_O = pi_nCodProd)
             AND (ROWNUM                               = 1);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vCODFILIAL_O          := NULL;
            nCODPROD_O            := NULL;
            vDESCRICAO_O          := NULL;
            vCODFILIAL_D          := NULL;
            nCODPROD_D            := NULL;
            vEMB_POR_FORNECEDOR_O := 'N';
            nQTUNITCX_O           := 0;
        END;

        -- Se usa Arredondamento e Não atingiu a qtde mínima = qt. embalagem fornecedor da reposição
        IF (vEMB_POR_FORNECEDOR_O = 'S') AND
           (NVL(vnRetQtAtend,0) < NVL(nQTUNITCX_O,0)) THEN
          -- Não pode atender o Produto
          vnRetQtAtend := 0;
          -- ********** LOG ********** ---
          -- Gera novo Sequencial
          viSeqMensagem := NVL(vtMensagens.COUNT,0) + 1;
          -- Adiciona Mensagem Temporária ao Array de Mensagens Definitivas
          vtMensagens(viSeqMensagem).vnCodFilial_O      := vCODFILIAL_O;
          vtMensagens(viSeqMensagem).vnCodProd_O        := nCODPROD_O;
          vtMensagens(viSeqMensagem).vvDescricao_O      := vDESCRICAO_O;
          vtMensagens(viSeqMensagem).vnQtdeTransferir_O := NVL(pi_nQtdeAtend,0);
          vtMensagens(viSeqMensagem).vnCodFilial_D      := vCODFILIAL_D;
          vtMensagens(viSeqMensagem).vnCodProd_D        := nCODPROD_D;
          vtMensagens(viSeqMensagem).vnSeqFalta         := NULL;
          vtMensagens(viSeqMensagem).vvMensagem         := 'Estoque Disponivel: ' || NVL(pi_nQtdeAtend,0) || ' inferior à embalagem de reposição: ' || NVL(nQTUNITCX_O,0);
        END IF;

        -- Retorno
        RETURN vnRetQtAtend;
      END F_RETORNAR_QT_ARREOND_EMB_FORN;

    BEGIN
      -- Inicializa controle de Problemas ao Baixar Estoque
      --vbProblemasBaixarEstoque  := FALSE;

      -- Inicializa a Descrição da Exclusão do Pedido
      vvDescricaoExclusaoPedido := SUBSTR('Cliente: ' || TO_CHAR(pi_nCodCli) || '-' || pi_vFantasia || ' PEDIDO: ' || TO_CHAR(pi_nNumPed), 1, 80);

      -- Inicializa o Valor Total Original do Pedido
      vnVlTotalOriginalPedido   := 0;
    POBTEM_PARAMFILIAL_STRING(pi_vCodFilial,'DESCSTFORAUFTRANSF',
                                vDESCSTFORAUFTRANSF,vvErroPesqParam,
                                vvMsgErroPesqParam);
      -- Limpa Arrays
      vtPED_NUMPED.DELETE;
      vtPED_CODPROD.DELETE;
      vtPED_QT.DELETE;
      vtPED_PVENDA.DELETE;
      vtPED_PTABELA.DELETE;
      vtPED_NUMSEQ.DELETE;
      vtPED_DTSAIDA.DELETE;

      -- Carrega Itens do Pedido em Array
      SELECT PCPEDI.NUMPED
           , PCPEDI.CODPROD
           , PCPEDI.QT
           , PCPEDI.PVENDA
           , PCPEDI.PTABELA
           , PCPEDI.NUMSEQ
           , TRUNC(SYSDATE)
           , PCPEDI.QTUNITEMB
        BULK COLLECT INTO vtPED_NUMPED
                        , vtPED_CODPROD
                        , vtPED_QT
                        , vtPED_PVENDA
                        , vtPED_PTABELA
                        , vtPED_NUMSEQ
                        , vtPED_DTSAIDA
                        , vtPED_QTUNITEMB
        FROM PCPEDI
       WHERE (NUMPED = pi_nNumPed)
         FOR UPDATE NOWAIT;

      -- Limpa Arrays
      vtEST_CODPROD.DELETE;
      vtEST_QTESTGER.DELETE;
      vtEST_QTPENDENTE.DELETE;
      vtEST_QTRESERV.DELETE;
      vtEST_QTBLOQUEADA.DELETE;
      vtEST_QTVENDAPERDIDA.DELETE;
      vtEST_DTULTSAIDA.DELETE;

      -- Carrega Dados de Estoque dos Itens do Pedido, com Lock nos Registros
      SELECT CODPROD
           , NVL(QTESTGER,0)       QTESTGER
           , NVL(QTPENDENTE,0)     QTPENDENTE
           , NVL(QTRESERV,0)       QTRESERV
           , NVL(QTBLOQUEADA,0)    QTBLOQUEADA
           , NVL(QTVENDAPERDIDA,0) QTVENDAPERDIDA
           , DTULTSAIDA
        BULK COLLECT INTO vtEST_CODPROD
                        , vtEST_QTESTGER
                        , vtEST_QTPENDENTE
                        , vtEST_QTRESERV
                        , vtEST_QTBLOQUEADA
                        , vtEST_QTVENDAPERDIDA
                        , vtEST_DTULTSAIDA
        FROM PCEST
       WHERE CODFILIAL = NVL(pi_vCodFilialRetira,pi_vCodFilial) -->> Filial Retira ou Filial Origem
         AND CODPROD IN (SELECT CODPROD
                           FROM PCPEDI
                          WHERE NUMPED = pi_nNumPed)
         FOR UPDATE; -->> SEM O NOWAIT
      IF (vtEST_CODPROD.COUNT > 0) THEN
        FOR viInEst IN vtEST_CODPROD.FIRST..vtEST_CODPROD.LAST LOOP
          vtEST_IND_CODPROD(vtEST_CODPROD(viInEst)) := viInEst;
        END LOOP;
      END IF;

      -- Se carregou Array com Itens do Pedido
      IF (vtPED_NUMPED.COUNT > 0) THEN

       /****************************************************************
        ESTORNA A QUANTIDADE PENDENTE DO PEDIDO QUE CHEGA AQUI BLOQUEADO
        ****************************************************************/

        -- Atualiza Estoque Pendente (BAIXAR)
        vvValidoPkgEstoque := PKG_ESTOQUE.PENDENTE_BAIXAR_PEDIDO(pi_nNumPed,
                                                                 'B',
                                                                 vvMsgRetornoPkgEstoque);
        IF (NVL(vvValidoPkgEstoque,'N') <> 'S') THEN
          RAISE e_PkgEstoquePendente;
        END IF;

       /********************************
        ATUALIZAÇÃO DA POSIÇÃO DO PEDIDO
        ********************************/

        -- Atualiza Posição do Pedido
        UPDATE PCPEDC
           SET POSICAO = 'L'
         WHERE (NUMPED = pi_nNumPed);

        -- Atualiza Posição do Item do Pedido
        UPDATE PCPEDI
           SET POSICAO = 'L'
         WHERE (NUMPED = pi_nNumPed);


        -- Processa os Itens do Pedido
        FOR viSeqItemPed IN vtPED_NUMPED.FIRST..vtPED_NUMPED.LAST LOOP

          -- Inicializa Dados do Item do Pedido
          vnCodProd               := vtPED_CODPROD(viSeqItemPed);
          vnQtdeOriginalPedido    := NVL(vtPED_QT(viSeqItemPed),0);
          vnQtdeAtend             := NVL(vtPED_QT(viSeqItemPed),0);
          vnPVenda                := NVL(vtPED_PVENDA(viSeqItemPed),0);
          vnPTabela               := NVL(vtPED_PTABELA(viSeqItemPed),0);
          vnNumSeq                := NVL(vtPED_NUMSEQ(viSeqItemPed),0);
          vnQtUnitEmb             := NVL(vtPED_QTUNITEMB(viSeqItemPed),0);

          -- Acumula o Valor Total Original do Pedido
          vnVlTotalOriginalPedido := NVL(vnVlTotalOriginalPedido,0) + (NVL(vnQtdeOriginalPedido,0) * NVL(vnPVenda,0));

         /************************************************************
          CALCULO DA QT. ATENDIDA E FALTA COM BASE NO ESTOQUE DA PCEST
          ************************************************************/

          -- Obtém Estoque Disponível (Desconsiderando o Bloqueado - Parâmetro 'P')
          BEGIN
            vnEstoqueDisponivel := PKG_ESTOQUE.ESTOQUE_DISPONIVEL(vnCodProd
                                                                 ,NVL(pi_vCodFilialRetira,pi_vCodFilial)
                                                                 ,'P');
          EXCEPTION
            WHEN OTHERS THEN
              vvMsgRetornoPkgEstoque := 'Erro: ' || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM,1,2000);
              RAISE e_AbortaBaixaEstoque;
          END;

         /*************************************************
          REGRA ESPECÍFICA - Utilizar Conversão PCEMBALAGEM
          *************************************************/
          IF (NVL(pi_vUSAQTUNITPCEMBREPLOJA,'N') = 'S') THEN
            -- Rebaixa o Estoque para atender ao menos múltiplo da PCEMBALAGEM
            IF (NVL(vnQtUnitEmb,0) > 0) THEN
              IF (NVL(vIGNORARVALIDACAOMULTIPLOEMB,'N') <> 'S') THEN
                vnEstoqueDisponivel := TRUNC(NVL(vnEstoqueDisponivel,0) / NVL(vnQtUnitEmb,0)) * NVL(vnQtUnitEmb,0);
              END IF;
            ELSE
              vnEstoqueDisponivel := 0;
            END IF;
          END IF;

          -- Regra para multiplo do produto -- DDVENDAS-45056
          POBTEM_PARAMFILIAL_STRING(NVL(pi_vCodFilialRetira,pi_vCodFilial),
                                    'FIL_UTILIZAVENDAPOREMBALAGEM',
                                    vUTILIZAVENDAPOREMBALAGEM,
                                    vvErroPesqParam,
                                    vvMsgErroPesqParam);
          IF (vUTILIZAVENDAPOREMBALAGEM IS NULL) THEN
            POBTEM_PARAMFILIAL_STRING('99',
                                      'CON_UTILIZAVENDAPOREMBALAGEM',
                                      vUTILIZAVENDAPOREMBALAGEM,
                                      vvErroPesqParam,
                                      vvMsgErroPesqParam);
          END IF;
          
          IF (NVL(vUTILIZAVENDAPOREMBALAGEM,'N') <> 'S') and (vnEstoqueDisponivel > 0) THEN
            -- Verifica se o cliente está configurado para utilizar multiplo
          SELECT PCMED_TEMP_TRANSF_ATAC_VAR.CODFILIAL_D
            INTO vCodfilial_Dest
            FROM PCMED_TEMP_TRANSF_ATAC_VAR
           WHERE (PCMED_TEMP_TRANSF_ATAC_VAR.NUMPED    = pi_nNumPed)
             AND (ROWNUM = 1);

            BEGIN
              SELECT NVL(PCCLIENT.VALIDARMULTIPLOVENDA,'N')
                INTO vVALIDARMULTIPLOVENDA
                FROM PCCLIENT, PCFILIAL
               WHERE PCCLIENT.CODCLI = PCFILIAL.CODCLI
                 AND PCFILIAL.CODIGO = vCodfilial_Dest;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
               vVALIDARMULTIPLOVENDA := 'N';
            END;

            IF vVALIDARMULTIPLOVENDA = 'S' AND vAPLICARVALIDACAOMULTIPLO = 'S' THEN
              BEGIN
                SELECT PCPRODFILIAL.MULTIPLO
                  INTO vMULTIPLOPRODUTO
                  FROM PCPRODFILIAL
                 WHERE (CODFILIAL = NVL(pi_vCodFilialRetira,pi_vCodFilial))
                   AND (CODPROD   = vnCodProd);
                       
                   IF NVL(vMULTIPLOPRODUTO,0) = 0 THEN
                      SELECT NVL(PCPRODUT.MULTIPLO ,1)
                        INTO vMULTIPLOPRODUTO
                        FROM PCPRODUT
                       WHERE (CODPROD = vnCodProd);                         
                   END IF;  
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  SELECT NVL(PCPRODUT.MULTIPLO ,1)
                    INTO vMULTIPLOPRODUTO
                    FROM PCPRODUT
                   WHERE (CODPROD = vnCodProd);
              END;
                  
              vnEstoqueDisponivel := TRUNC(NVL(vnEstoqueDisponivel,0) / NVL(vMULTIPLOPRODUTO,0)) * NVL(vMULTIPLOPRODUTO,0);
                  
            END IF;
          END IF;
          -- FIM -- DDVENDAS-45056

          -- Se não tem Quantidade suficiente para atender a Quantidade do Item do Pedido
          IF (NVL(vnEstoqueDisponivel,0) < NVL(vnQtdeAtend,0)) THEN
            -- A Quantidade Atendida será Restringida ao Estoque Disponivel
            vnQtdeAtend := NVL(vnEstoqueDisponivel,0);
           /******************************************************************************
            REGRA ESPECÍFICA - Utilizar Arredondamento da Embalagem do Fornecedor na Falta
            ******************************************************************************/
            IF (NVL(pi_vUSAREGRAARREDEMBFRNFTAREP,'N') = 'S') THEN
              vnQtdeAtend := F_RETORNAR_QT_ARREOND_EMB_FORN(pi_nNumPed,
                                                            vnCodProd,
                                                            vnQtdeAtend);
            END IF;
          END IF;


          -- Calcula a Quantidade de Faltas
          vnQtdeFalta := (NVL(vnQtdeOriginalPedido,0) - NVL(vnQtdeAtend,0));

          -- Calcula a Quantidade de Faltas que serão guardadas
          IF (NVL(pi_vGuardaFalta,'N') = 'S') THEN
            vnQtdeGuardaFalta := NVL(vnQtdeFalta,0);
          ELSE
            vnQtdeGuardaFalta := 0;
          END IF;

          -- Se ocorreram Faltas
          IF (NVL(vnQtdeFalta,0) > 0) THEN

           /*****************************************
            ATUALIZAÇÃO DA PCPEDI SE OCORRERAM FALTAS
            *****************************************/

            -- Se existir Quantidade Atendida
            IF (NVL(vnQtdeAtend,0) > 0) THEN

              -- Atualiza PCPEDI
              UPDATE PCPEDI
                 SET QT      = NVL(vnQtdeAtend,0)
                   , QTFALTA = NVL(vnQtdeFalta,0)
               WHERE (NUMPED  = pi_nNumPed)
                 AND (CODPROD = vnCodProd)
                 AND (NUMSEQ  = vnNumSeq);

            -- Se NÃO existir Quantidade Atendida
            ELSE

              -- Exclui Item do Pedido porque não existe quantidade atendida
              DELETE FROM PCPEDI
                    WHERE (NUMPED  = pi_nNumPed)
                      AND (CODPROD = vnCodProd)
                      AND (NUMSEQ  = vnNumSeq);

              -- Insere no Log de Itens Excluídos
              INSERT INTO PCNFCANITEM
                        ( NUMPED
                        , CODROTINA
                        , MOTIVO
                        , CODCLI
                        , CODPROD
                        , PVENDA
                        , PTABELA
                        , NUMSEQ
                        , DATACANC
                        , CODFUNCCANC
                        , DATAEMISSAO
                        , CODFUNCEMITE
                        , DESCRICAO
                        , CODUSUR
                        , NUMCAR
                        , QT )
                 VALUES ( pi_nNumPed
                        , 3602
                        , 'ITEM NÃO ATENDIDO, EXCLUIDO PEDIDO'
                        , pi_nCodCli
                        , vnCodProd
                        , vnPVenda
                        , vnPTabela
                        , vnNumSeq
                        , TRUNC(SYSDATE)
                        , pi_nCodMatricula
                        , pi_dData
                        , pi_nCodMatricula
                        , vvDescricaoExclusaoPedido
                        , pi_nCodUsur
                        , 0
                        , NVL(vnQtdeOriginalPedido,0));

            END IF; -- Fim Condição se existir ou não Quantidade Atendida

           /**************************************************************
            INCLUSAO DO LOG DAS FALTAS SE EXISTEM FALTAS A SEREM GUARDADAS
            **************************************************************/
            IF (NVL(vnQtdeGuardaFalta,0) > 0) THEN

              -- Insere Falta no Log
              INSERT INTO PCFALTA
                        ( NUMPED
                        , DATA
                        , CODPROD
                        , CODUSUR
                        , CODCLI
                        , QT
                        , PVENDA
                        , CODFILIAL
                        , NUMSEQ )
                 VALUES ( pi_nNumPed
                        , pi_dData
                        , vnCodProd
                        , pi_nCodUsur
                        , pi_nCodCli
                        , NVL(vnQtdeGuardaFalta,0) -- Quantidade de Faltas que serão guardadas
                        , vnPVenda
                        , pi_vCodFilial
                        , vnNumSeq );

            END IF; -- Fim Condição para Inclusão no Log de Faltas

            -- No LOG da Reposição, sempre Grava as Faltas independente do parâmetro Se Guarda Faltas
            UPDATE PCMED_TEMP_TRANSF_ATAC_VAR
               SET QTFALTAPED = NVL(vnQtdeFalta,0)
             WHERE (CODFILIAL_O = pi_vCodFilial)
               AND (CODPROD_O   = vnCodProd)
               AND (NUMPED      = pi_nNumPed);

            -- Insere na Tabela Temporária de Faltas para Atendimento pelo Próximo Fornecedor da Prioridade
            nSEQFALTA := NVL(nSEQFALTA,0) + 1;
            INSERT INTO PCMED_TEMP_FALTAS_ATAC_VAR
                      ( NUMSUGESTAOREP
                      , SEQFALTA
                      , CODFILIALFALTA
                      , CODPRODFALTA
                      , CODCLI
                      , QTFALTA )
               VALUES ( vnProxNumSugestaoRep
                      , nSEQFALTA
                      , pi_vCodFilial
                      , vnCodProd
                      , pi_nCodCli
                      ,  NVL(vnQtdeFalta,0) );

          END IF; -- Fim Condição Se ocorreram Faltas

         /********************
          ATUALIZAÇÃO DA PCEST
          ********************/

          -- Calcula nova Qtde. Pendente, com tratamento para não deixar negativo
          IF (vtEST_IND_CODPROD.EXISTS(vnCodProd)) THEN
            vnNovaQtPendente := vtEST_QTPENDENTE(vtEST_IND_CODPROD(vnCodProd));
          ELSE
            vnNovaQtPendente := 0;
          END IF;
          vnNovaQtPendente := (NVL(vnNovaQtPendente,0) - NVL(vnQtdeOriginalPedido,0));
          IF (NVL(vnNovaQtPendente,0) < 0) THEN
            vnNovaQtPendente := 0;
          END IF;

          -------------------------
          -- ATUALIZAÇÃO DO ESTOQUE
          -------------------------

          -- Se o Produto teve Quantidade Atendida
          IF (NVL(vnQtdeAtend,0) > 0) THEN

            -- Atualiza Qtde. Venda Perdida
            UPDATE PCEST
               SET QTVENDAPERDIDA = NVL(QTVENDAPERDIDA,0) + NVL(vnQtdeFalta,0)
                 , DTULTSAIDA     = TRUNC(SYSDATE) -- Se atendeu ao menos uma unidade Atualiza DTULTSAIDA
             WHERE (CODFILIAL = NVL(pi_vCodFilialRetira,pi_vCodFilial)) -->> Filial Retira ou Filial Origem
               AND (CODPROD   = vnCodProd);

            -- Atualiza Estoque Reservado (INCLUIR)
            IF (PKG_ESTOQUE.RESERVA_INCLUIR ( pi_nNumPed
                                            , vnCodProd
                                            , vnNumSeq
                                            , TRUE -- Pedido Existe
                                            , 'IN'
                                            , vvMsgRetornoPkgEstoque ) <> 'S') THEN
              RAISE e_PkgEstoqueReservado;
            END IF;

          -- Se o Produto NÃO teve Quantidade Atendida
          ELSE

            -- Atualiza Qtde. Venda Perdida
            UPDATE PCEST
               SET QTVENDAPERDIDA = NVL(QTVENDAPERDIDA,0) + NVL(vnQtdeFalta,0)
             WHERE (CODFILIAL = NVL(pi_vCodFilialRetira,pi_vCodFilial)) -->> Filial Retira ou Filial Origem
               AND (CODPROD   = vnCodProd);
          END IF;

        END LOOP; -- Fim Laço do Processa os Itens do Pedido

       /*****************************************
        ATUALIZAÇÃO DA POSIÇÃO E TOTAIS DA PCPEDC
        *****************************************/

        -- Calcula o novo Total do Pedido
        SELECT COUNT(*)                                        QT,
               SUM(NVL(PCPEDI.QT,0)*NVL(PCPEDI.VLCUSTOFIN,0))  VLCUSTOFIN,
               SUM(NVL(PCPEDI.QT,0)*NVL(PCPEDI.VLCUSTOREAL,0)) VLCUSTOREAL,
               SUM(NVL(PCPEDI.QT,0)*NVL(PCPEDI.VLCUSTOCONT,0)) VLCUSTOCONT,
               SUM(NVL(PCPEDI.QT,0)*NVL(PCPEDI.VLCUSTOREP,0))  VLCUSTOREP,
               SUM(NVL(PCPEDI.QT,0)*NVL(PCPEDI.PTABELA,0))     VLTABELA,
               SUM(NVL(PCPEDI.QT,0)*NVL(PCPEDI.PVENDA,0))      VLATEND,
               SUM(NVL(PCPEDI.QT,0)*NVL(PCPRODUT.PESOBRUTO,0)) TOTPESOBRUTO,
               SUM(NVL(PCPEDI.QT,0)*NVL(PCPRODUT.VOLUME,0))    TOTVOLUME,
               SUM ((NVL (PCPEDI.QT, 0) + NVL (PCPEDI.QTFALTA, 0)) * PCPEDI.PVENDA) VLTOTAL
          INTO vnTotQTITENS
             , vnTotVLCUSTOFIN
             , vnTotVLCUSTOREAL
             , vnTotVLCUSTOCONT
             , vnTotVLCUSTOREP
             , vnTotVLTABELA
             , vnTotVLATEND
             , vnTotTOTPESO
             , vnTotTOTVOLUME
             , vnTotVLTOTAL
          FROM PCPEDI,
               PCPRODUT
         WHERE (PCPEDI.CODPROD = PCPRODUT.CODPROD)
           AND (PCPEDI.NUMPED  = pi_nNumPed);

        -- Se existem Itens no Pedido
        IF (NVL(vnTotQTITENS,0) > 0) THEN

          -- Atualiza Totais do Pedido
          UPDATE PCPEDC
             SET VLATEND   = (NVL(vnTotVLATEND,0) -
                              NVL(VLDESCONTO,0)   + -- Desconto já gravado no Pedido
                              NVL(VLOUTRASDESP,0) + -- Outras Despesas já gravado no Pedido
                              NVL(VLFRETE,0))       -- Frete já gravado no Pedido
               , NUMITENS    = vnTotQTITENS
               , VLCUSTOFIN  = vnTotVLCUSTOFIN
               , VLCUSTOREAL = vnTotVLCUSTOREAL
               , TOTPESO     = vnTotTOTPESO
               , TOTVOLUME   = vnTotTOTVOLUME
               , VLCUSTOCONT = vnTotVLCUSTOCONT
               , VLCUSTOREP  = vnTotVLCUSTOREP
               , VLTABELA    = (NVL(vnTotVLTABELA,0) +
                                NVL(VLOUTRASDESP,0)  + -- Outras Despesas já gravado no Pedido
                                NVL(VLFRETE,0))        -- Frete já gravado no Pedido
               , VLTOTAL     = (NVL(vnTotVLTOTAL,0) -
                                NVL(VLDESCONTO,0)   +  -- Desconto já gravado no Pedido
                                NVL(VLOUTRASDESP,0) +  -- Outras Despesas já gravado no Pedido
                                NVL(VLFRETE,0))        -- Frete já gravado no Pedido
          WHERE (NUMPED = pi_nNumPed);

          -- Log de Alteração de Dados - MED-2196
          P_INSERE_LOG_ALTERACAO_DADOS('A',
                                       pi_nNumPed,
                                       'PCPEDC',
                                       'POSICAO',
                                       'L',  -- pi_vTextoNew
                                       'B',  -- pi_vTextoOld
                                       NULL, -- pi_vNumeroNew
                                       NULL, -- pi_vNumeroOld
                                       'MUDANCA DE POSICAO',
                                       NULL);
          --
          P_INSERE_LOG_ALTERACAO_DADOS('N',
                                       pi_nNumPed,
                                       'PCPEDC',
                                       'NUMITENS',
                                       NULL,         -- pi_vTextoNew
                                       NULL,         -- pi_vTextoOld
                                       vnTotQTITENS, -- pi_vNumeroNew
                                       NULL,         -- pi_vNumeroOld
                                       'QTDE. ITENS LIBERADOS',
                                       NULL);

        -- Se NÃO existem Itens no Pedido
        ELSE

          -- Apaga Cabeçalho do Pedido
          DELETE FROM PCPEDC
                WHERE (NUMPED = pi_nNumPed);

          -- Insere no Log do Cabeçalho do Pedido
          INSERT INTO PCNFCAN
                    ( NUMPED
                    , CODROTINA
                    , MOTIVO
                    , CODCLI
                    , VLTOTAL
                    , DATACANC
                    , CODFUNCCANC
                    , DATAEMISSAO
                    , CODFUNCEMITE
                    , DESCRICAO
                    , NUMPEDRCA )
             VALUES ( pi_nNumPed
                    , 3602
                    , 'ITENS NÃO ATENDIDOS, EXCLUIDO PEDIDO'
                    , pi_nCodCli
                    , NVL(vnVlTotalOriginalPedido,0)
                    , TRUNC(SYSDATE)
                    , pi_nCodMatricula
                    , pi_dDATA
                    , pi_nCodMatricula
                    , vvDescricaoExclusaoPedido
                    , 0 );

          -- Log de Alteração de Dados - MED-2196
          P_INSERE_LOG_ALTERACAO_DADOS('A',
                                       pi_nNumPed,
                                       'PCPEDC',
                                       'POSICAO',
                                       'C',  -- pi_vTextoNew
                                       'B',  -- pi_vTextoOld
                                       NULL, -- pi_vNumeroNew
                                       NULL, -- pi_vNumeroOld
                                       'EXCLUSAO POR CORTE TOTAL',
                                       NULL);

        END IF; -- Fim Condição se existe Itens no Pedido

        -- EFETIVA TRANSACOES APOS PROCESSAR TODOS OS ITENS
        COMMIT;

      -- Se NÃO carregou Array com Itens do Pedido
      ELSE

         -- DESFAZ TRANSACOES
         ROLLBACK;

      END IF; -- Fim Condição Se carregou Array com Itens do Pedido

    EXCEPTION
      -- MED-1876 - Erro Package Estoque - Estoque Pendente
      WHEN e_PkgEstoquePendente THEN
        -- DESFAZ TRANSACOES
        ROLLBACK;
        -- Log de Alteração de Dados - MED-2196
        P_INSERE_LOG_ALTERACAO_DADOS('A',
                                     pi_nNumPed,
                                     'PCPEDC',
                                     'POSICAO',
                                     'C',  -- pi_vTextoNew
                                     'B',  -- pi_vTextoOld
                                     NULL, -- pi_vNumeroNew
                                     NULL, -- pi_vNumeroOld
                                     'EXCLUSAO POR ERRO ESTOQUE PENDENTE',
                                     'Erro Objeto Estoque: ' || vvMsgRetornoPkgEstoque);
        -- EFETIVA TRANSAÇÃO DO LOG
        COMMIT;
      -- MED-1876 - Erro Package Estoque - Estoque Reservado
      WHEN e_PkgEstoqueReservado THEN
        -- DESFAZ TRANSACOES
        ROLLBACK;
        -- Log de Alteração de Dados - MED-2196
        P_INSERE_LOG_ALTERACAO_DADOS('A',
                                     pi_nNumPed,
                                     'PCPEDC',
                                     'POSICAO',
                                     'C',  -- pi_vTextoNew
                                     'B',  -- pi_vTextoOld
                                     NULL, -- pi_vNumeroNew
                                     NULL, -- pi_vNumeroOld
                                     'EXCLUSAO POR ERRO ESTOQUE RESERVADO',
                                     'Erro Objeto Estoque: ' || vvMsgRetornoPkgEstoque);
        -- EFETIVA TRANSAÇÃO DO LOG
        COMMIT;
      WHEN e_AbortaBaixaEstoque THEN
        -- DESFAZ TRANSACOES
        ROLLBACK;
        -- Log de Alteração de Dados - MED-2196
        P_INSERE_LOG_ALTERACAO_DADOS('A',
                                     pi_nNumPed,
                                     'PCPEDC',
                                     'POSICAO',
                                     'C',  -- pi_vTextoNew
                                     'B',  -- pi_vTextoOld
                                     NULL, -- pi_vNumeroNew
                                     NULL, -- pi_vNumeroOld
                                     'EXCLUSAO POR ERRO ESTOQUE DISPONIVEL',
                                     'Erro Função Estoque: ' || SUBSTR(vvMsgRetornoPkgEstoque,1,2000));
        -- EFETIVA TRANSAÇÃO DO LOG
        COMMIT;
      WHEN OTHERS THEN
        -- DESFAZ TRANSACOES
        ROLLBACK;
        -- Log de Alteração de Dados - MED-2196
        P_INSERE_LOG_ALTERACAO_DADOS('A',
                                     pi_nNumPed,
                                     'PCPEDC',
                                     'POSICAO',
                                     'C',  -- pi_vTextoNew
                                     'B',  -- pi_vTextoOld
                                     NULL, -- pi_vNumeroNew
                                     NULL, -- pi_vNumeroOld
                                     'EXCLUSAO POR ERRO AO LIBERAR PEDIDO REPOSICAO',
                                     'Erro: ' || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM,1,2000));
        -- EFETIVA TRANSAÇÃO DO LOG
        COMMIT;
    END PLIBERA_PEDIDO;

    ------------------------------------------------------------------------------
    -- Procedimento para Faturar o Pedido - DDMEDICA-5077
    ------------------------------------------------------------------------------
    PROCEDURE PFATURA_PEDIDO(pi_nNumPed                IN NUMBER,
                             pi_nMatricula             IN NUMBER,
                             po_vErroFaturarPedido    OUT VARCHAR2,
                             po_vMsgErroFaturarPedido OUT VARCHAR2) IS
      -- Record de Parâmetros
      TYPE TRecParamFat IS RECORD(
           pvc2emitente      VARCHAR2(255),
           pncaregamento     PCPEDC.NUMCAR%TYPE,
           pvncodigocobranca PCPEDC.CODCOB%TYPE,
           pcodmotorista     NUMBER,
           pcodveiculo       NUMBER,
           pvc2codigofilial  PCPEDC.CODFILIAL%TYPE,
           pnnumnotafiscal   NUMBER,
           pnnumselonf       NUMBER,
           pvc2menssagen     VARCHAR2(2000));
      vrParamFat             TRecParamFat;
      --  Indicador de PréFat
      vvExistePrefat         VARCHAR2(1);
    BEGIN

      -- Inicializa Retornos
      po_vErroFaturarPedido    := 'N';
      po_vMsgErroFaturarPedido := NULL;

      -------------------
      -- Obtem PMC por UF
      -------------------
      BEGIN

        -- Parâmetros Faturamento
        BEGIN
          SELECT PCEMPR.NOME_GUERRA
            INTO vrParamFat.pvc2emitente
            FROM PCEMPR
           WHERE (PCEMPR.MATRICULA = pi_nMatricula);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vrParamFat.pvc2emitente  := NULL;
            po_vErroFaturarPedido    := 'S';
            po_vMsgErroFaturarPedido := 'Funcionário não encontrado para a matrícula: ' || pi_nMatricula;
        END;
        vrParamFat.pncaregamento := -1;
        BEGIN
          SELECT PCPEDC.CODCOB
               , PCPEDC.CODFILIAL
            INTO vrParamFat.pvncodigocobranca
               , vrParamFat.pvc2codigofilial
            FROM PCPEDC
           WHERE (PCPEDC.NUMPED = pi_nNumPed);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vrParamFat.pvncodigocobranca := NULL;
            vrParamFat.pvc2codigofilial  := NULL;
            po_vErroFaturarPedido        := 'S';
            po_vMsgErroFaturarPedido     := 'Pedido não encontrado: ' || pi_nNumPed;
        END;
        vrParamFat.pcodmotorista    := 0;
        vrParamFat.pcodveiculo      := 0;
        vrParamFat.pnnumnotafiscal  := 0;
        vrParamFat.pnnumselonf      := 0;

        -- Se não ocorreram Erros ao preparar parâmetros
        IF (po_vErroFaturarPedido = 'N') THEN

          -- Muda a Posição e Carregamento para Faturar
          UPDATE PCPEDC
             SET NUMCAR  = -1
               , POSICAO = 'M'
           WHERE (NUMPED = pi_nNumPed);
          UPDATE PCPEDI
             SET NUMCAR  = -1
               , POSICAO = 'M'
           WHERE (NUMPED = pi_nNumPed);

          -- String para executar Bloco de Cálculo de ST Fonte
          vvBlocoExecucaoProcedure := 'BEGIN FATURAMENTO.faturarpedido(TRUNC(SYSDATE),:pvc2emitente,:pncaregamento,:pvncodigocobranca,TRUNC(SYSDATE),TRUNC(SYSDATE),:pcodmotorista,:pcodveiculo,:pvc2codigofilial,:pnnumnotafiscal,:pnnumselonf,:pvc2menssagen); END;';

          -- Executa Bloco
          EXECUTE IMMEDIATE vvBlocoExecucaoProcedure
            USING in vrParamFat.pvc2emitente
                , in vrParamFat.pncaregamento
                , in vrParamFat.pvncodigocobranca
                , in vrParamFat.pcodmotorista
                , in vrParamFat.pcodveiculo
                , in vrParamFat.pvc2codigofilial
                , in vrParamFat.pnnumnotafiscal
                , in vrParamFat.pnnumselonf
                , out vrParamFat.pvc2menssagen;

          -- Se ocorreram erros no Faturamento
          IF (NVL(vrParamFat.pvc2menssagen,'X') <> 'OK') THEN
            po_vErroFaturarPedido    := 'S';
            po_vMsgErroFaturarPedido := 'Erro no faturamento : ' || SUBSTR(vrParamFat.pvc2menssagen,1,2000);
          END IF;

        END IF;

      EXCEPTION
        -- Se erro ao Faturar
        WHEN OTHERS THEN
          po_vErroFaturarPedido    := 'S';
          po_vMsgErroFaturarPedido := 'Erro ao executar procedure de faturamento : ' || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM,1,2000);
      END;

      -- Se erros no Faturamento, exclui o Pedido
      IF (po_vErroFaturarPedido = 'S') THEN

        -- Antes de excluir, verifica se gerou PreFat
        BEGIN
          SELECT 'S'
            INTO vvExistePrefat
            FROM PCNFSAIDPREFAT
           WHERE (PCNFSAIDPREFAT.NUMPED = pi_nNumPed)
             AND (ROWNUM                = 1);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvExistePrefat := 'N';
        END;

        -- Somente se não existir Prefat exclui
        IF (vvExistePrefat = 'N') THEN
          DELETE FROM PCPEDI WHERE NUMPED = pi_nNumPed;
          DELETE FROM PCPEDC WHERE NUMPED = pi_nNumPed;
          IF (NVL(SQL%ROWCOUNT,0) > 0) THEN
            po_vMsgErroFaturarPedido := 'Pedido de Avaria "' || pi_nNumPed || '" foi excluído por não conseguir gerar a nota fiscal: ' || po_vMsgErroFaturarPedido;
          END IF;
        END IF;

      END IF;

      -- EFETIVA TRANSAÇÕES
      COMMIT;

    END PFATURA_PEDIDO;

    ------------------------------------------------------------------------------
    -- Procedimento para Calcular os Totais do Pedido
    ------------------------------------------------------------------------------
    PROCEDURE PTOTAIS_PEDIDO(pi_nNumPed IN NUMBER) IS
    BEGIN

      -- Calcula os Totais do Pedido
      SELECT SUM((NVL(PCPEDI.QT,0) * NVL(PCPEDI.PVENDA,0)))
           , COUNT(*)
           , SUM((NVL(PCPEDI.QT,0) * NVL(PCPEDI.VLCUSTOFIN,0)))
           , SUM((NVL(PCPEDI.QT,0) * NVL(PCPEDI.VLCUSTOREAL,0)))
           , SUM((NVL(PCPEDI.QT,0) * NVL(PCPRODUT.PESOBRUTO,0)))
           , SUM((NVL(PCPEDI.QT,0) * NVL(PCPRODUT.VOLUME,0)))
           , SUM((NVL(PCPEDI.QT,0) * NVl(PCPEDI.VLCUSTOCONT,0)))
           , SUM((NVL(PCPEDI.QT,0) * NVL(PCPEDI.VLCUSTOREP,0)))
           , SUM((NVL(PCPEDI.QT,0) * NVL(PCPEDI.PTABELA,0)))
           , SUM(((NVL(PCPEDI.QT,0) + NVL(PCPEDI.QTFALTA,0)) * NVL(PCPEDI.PVENDA,0)))
        INTO vrPedido.nVLATEND
           , vrPedido.nNUMITENS
           , vrPedido.nVLCUSTOFIN
           , vrPedido.nVLCUSTOREAL
           , vrPedido.nTOTPESO
           , vrPedido.nTOTVOLUME
           , vrPedido.nVLCUSTOCONT
           , vrPedido.nVLCUSTOREP
           , vrPedido.nVLTABELA
           , vrPedido.nVLTOTAL
        FROM PCPEDI
           , PCPRODUT
       WHERE (PCPEDI.CODPROD = PCPRODUT.CODPROD)
         AND (NUMPED = pi_nNumPed);

      -- Valores não implementados na 2312
      vrPedido.nVLOUTRASDESP  := 0;
      vrPedido.nVLFRETE       := 0;
      vrPedido.nVLDESCONTO    := 0;

      -- Complementa alguns Totais com Valores de Cabeçalho
      vrPedido.nVLATEND       := NVL(vrPedido.nVLATEND,0) - NVL(vrPedido.nVLDESCONTO,0) + NVL(vrPedido.nVLOUTRASDESP,0) + NVL(vrPedido.nVLFRETE,0);
      vrPedido.nVLTABELA      := NVL(vrPedido.nVLTABELA,0) + NVL(vrPedido.nVLOUTRASDESP,0) + NVL(vrPedido.nVLFRETE,0);
      vrPedido.nVLTOTAL       := NVL(vrPedido.nVLTOTAL,0) - NVL(vrPedido.nVLDESCONTO,0) + NVL(vrPedido.nVLOUTRASDESP,0) + NVL(vrPedido.nVLFRETE,0);

    END PTOTAIS_PEDIDO;

    ------------------------------------------------------------------------------
    -- Procedimento para Atualizar Array de Mensagens
    ------------------------------------------------------------------------------
    PROCEDURE PATUALIZA_MENSAGENS IS
      viSeqMensagem INTEGER;
    BEGIN

      -- Se existem Mensagens
      IF (vtMensagensAux.COUNT > 0) THEN
        FOR viIndMsg IN vtMensagensAux.FIRST..vtMensagensAux.LAST LOOP

          -- Gera novo Sequencial
          viSeqMensagem := NVL(vtMensagens.COUNT,0) + 1;

          -- Adiciona Mensagem Temporária ao Array de Mensagens Definitivas
          vtMensagens(viSeqMensagem).vnCodFilial_O      := vtMensagensAux(viIndMsg).vnCodFilial_O;
          vtMensagens(viSeqMensagem).vnCodProd_O        := vtMensagensAux(viIndMsg).vnCodProd_O;
          vtMensagens(viSeqMensagem).vvDescricao_O      := vtMensagensAux(viIndMsg).vvDescricao_O;
          vtMensagens(viSeqMensagem).vnQtdeTransferir_O := vtMensagensAux(viIndMsg).vnQtdeTransferir_O;
          vtMensagens(viSeqMensagem).vnCodFilial_D      := vtMensagensAux(viIndMsg).vnCodFilial_D;
          vtMensagens(viSeqMensagem).vnCodProd_D        := vtMensagensAux(viIndMsg).vnCodProd_D;
          vtMensagens(viSeqMensagem).vnSeqFalta         := vtMensagensAux(viIndMsg).vnSeqFalta;
          vtMensagens(viSeqMensagem).vvMensagem         := vtMensagensAux(viIndMsg).vvMensagem;
          vtMensagens(viSeqMensagem).vvNumLote          := vtMensagensAux(viIndMsg).vvNumLote;

        END LOOP;
      END IF;

      -- Limpa Mensagens Temporárias
      vtMensagensAux.DELETE;

    END PATUALIZA_MENSAGENS;

    ------------------------------------------------------------------------------
    -- Procedimento para Gravar as Mensagens
    ------------------------------------------------------------------------------
    PROCEDURE PGRAVA_MENSAGENS IS
    BEGIN

      -- Se existem Mensagens
      IF (vtMensagens.COUNT > 0) THEN
        FOR viIndMsg IN vtMensagens.FIRST..vtMensagens.LAST LOOP

          -- Retira as Quebras de Linha
          vtMensagens(viIndMsg).vvMensagem := REPLACE(vtMensagens(viIndMsg).vvMensagem,CHR(13),' ');
          vtMensagens(viIndMsg).vvMensagem := REPLACE(vtMensagens(viIndMsg).vvMensagem,CHR(10),' ');

          -- Insere na Tabela Temporária
          INSERT INTO PCMED_TEMP_TRANSF_ATAC_VAR_ERR
                    ( CODFILIAL_O
                    , CODPROD_O
                    , DESCRICAO_O
                    , QTD_TRANSFERIR_O
                    , CODFILIAL_D
                    , CODPROD_D
                    , MENSAGEM )
             VALUES ( vtMensagens(viIndMsg).vnCodFilial_O
                    , vtMensagens(viIndMsg).vnCodProd_O
                    , vtMensagens(viIndMsg).vvDescricao_O
                    , vtMensagens(viIndMsg).vnQtdeTransferir_O
                    , vtMensagens(viIndMsg).vnCodFilial_D
                    , vtMensagens(viIndMsg).vnCodProd_D
                    , vtMensagens(viIndMsg).vvMensagem );

          -- Se Geração Automática, atualiza Motivo na Tabela Temporária
          IF (pi_vAutomaticoManual = 'A') THEN
            -- Se Chamado da Geração dos Pedidos a partir da Sugestão de Reposição
            IF    (pi_nOrigemChamada = 1) THEN
              UPDATE PCMED_TEMP_TRANSF_ATAC_VAR
                 SET OBSERVACAOREJEICAO = SUBSTR(vtMensagens(viIndMsg).vvMensagem,1, 240)
               WHERE (CODFILIAL_O = vtMensagens(viIndMsg).vnCodFilial_O)
                 AND (CODPROD_O   = vtMensagens(viIndMsg).vnCodProd_O)
                 AND (CODFILIAL_D = vtMensagens(viIndMsg).vnCodFilial_D)
                 AND (CODPROD_D   = vtMensagens(viIndMsg).vnCodProd_D);
            -- Se Geração dos Pedidos a partir das Faltas da Sugestão de Reposição
            ELSIF (pi_nOrigemChamada = 2) THEN
              UPDATE PCMED_TEMP_FALTAS_ATAC_VAR
                 SET REJEICAOINICIAL    = 'N'
                   , OBSERVACAOREJEICAO = SUBSTR(vtMensagens(viIndMsg).vvMensagem,1, 240)
               WHERE (SEQFALTA = vtMensagens(viIndMsg).vnSeqFalta);
            END IF;
          END IF;

          -- Efetiva Transações
          COMMIT;

        END LOOP;
      END IF;

      -- Se chamado da Geração dos Pedidos a partir das Faltas da Sugestão de Reposição,
      -- carrega na Tabela Temporária de Erros as Rejeições Iniciais das Faltas
      -- que não permitiram o processamento delas nesta procedure (Dados Incompletos
      -- ou não achou Fornecedor da Próxima Prioridade), para poderem aparecer no
      -- Relatório no Processamento Manual
      -- OBS: No relatório do processamento automático, a tabela temporária de erros
      --      é carregada a partir da própria tabela de histórico de faltas, portanto
      --      consegue apresentar as rejeições iniciais e de processamento, portanto
      --      não precisa desta adição de informação à tabela temporária
      IF ((pi_nOrigemChamada = 2) AND
          (pi_vAutomaticoManual = 'M')) THEN
        -- Insere
        INSERT INTO PCMED_TEMP_TRANSF_ATAC_VAR_ERR
                  ( CODFILIAL_O
                  , CODPROD_O
                  , DESCRICAO_O
                  , QTD_TRANSFERIR_O
                  , CODFILIAL_D
                  , CODPROD_D
                  , MENSAGEM )
             SELECT PCMED_TEMP_FALTAS_ATAC_VAR.CODFILIAL_O
                  , PCMED_TEMP_FALTAS_ATAC_VAR.CODPROD_O
                  , PCPRODUT.DESCRICAO
                  , PCMED_TEMP_FALTAS_ATAC_VAR.QTFALTA_O
                  , PCMED_TEMP_FALTAS_ATAC_VAR.CODFILIAL_D
                  , PCMED_TEMP_FALTAS_ATAC_VAR.CODPROD_D
                  , PCMED_TEMP_FALTAS_ATAC_VAR.OBSERVACAOREJEICAO
               FROM PCMED_TEMP_FALTAS_ATAC_VAR
                  , PCPRODUT
              WHERE (PCMED_TEMP_FALTAS_ATAC_VAR.CODPROD_O       = PCPRODUT.CODPROD)
                AND (PCMED_TEMP_FALTAS_ATAC_VAR.REJEICAOINICIAL = 'S');
        -- Efetiva Transações
        COMMIT;
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        -- Ocorreram Erros
        po_vOcorreramErros := 'S';
        po_vMsgErros       := SQLERRM;
    END PGRAVA_MENSAGENS;

    ------------------------------------------------------------------------------
    -- Procedimento para a Gravação da Sugestão de Reposição Automática (Cab/Item)
    ------------------------------------------------------------------------------
    PROCEDURE GRAVA_SUGESTAOREPOSICAOCABITE(pi_nNumSugestaoRep IN NUMBER) IS

      -- Variáveis auxiliares
      vdDtGeracao          DATE;
      iContaCommit         NUMBER(12);

    BEGIN

      -- Inicializa Controle do Commit
      iContaCommit := 0;

      -- Define a Data da Geração
      vdDtGeracao  := SYSDATE;

      -- Insere Cabeçalho da Sugestão de Reposição
      INSERT INTO PCSUGESTAOREPOSICAOMEDCAB
                ( NUMSUGESTAOREP
                , DTGERACAO
                , CODFUNCGER )
         VALUES ( pi_nNumSugestaoRep
                , vdDtGeracao
                , pi_nCodMatricula );

      -- Cursor com os Itens da Sugestão de Reposição
      FOR vc_Reposicao IN ( SELECT CODFILIAL_O
                                 , CODPROD_O
                                 , CODFILIAL_D
                                 , CODPROD_D
                                 , CODMARCA_O
                                 , QTUNITCX_O
                                 , QTD_EST_O
                                 , QTD_SUGERIDA_O
                                 , QTD_TRANSFERIR_O
                                 , PRIORIDADE_D
                                 , TIPOSUGESTAO_D
                                 , DESCTIPOSUGESTAO_D
                                 , ESTOQUEMIN_D
                                 , ESTOQUEMAX_D
                                 , QTESTGER_D
                                 , QTPEDIDA_D
                                 , QTD_TRANSITO_D
                                 , QTD_BLOQSEMAVARIA_D
                                 , CLASSE_D
                                 , PMC_D
                                 , CUSTOULTENT_D
                                 , PVENDA_D
                                 , SUG_FRACIONADA_D
                                 , QTUNITCX_D
                                 , PERCARREDONDA_D
                                 , QTD_SUGERIDA_D
                                 , QTD_TRANSFERIR_D
                                 , VLR_TRANSFERIR_D
                                 , CODEQUIPE
                                 , CODCATEGORIA
                                 , CODSEC
                                 , CODEPTO
                                 , CODFORNEC
                                 , EMBALAGEM
                                 , UNIDADE
                                 , TRIBUTACAO
                                 , CODST
                                 , QTVENDMES_D
                                 , QTVENDMES1_D
                                 , QTVENDMES2_D
                                 , QTVENDMES3_D
                                 , QTPENDENTE_D
                                 , CODFAB_O
                                 , CODFAB_D
                                 , CODAUXILIAR_O
                                 , CODAUXILIAR_D
                                 , QUEBRA1
                                 , QUEBRA2
                                 , QUEBRA3
                                 , QUEBRA4
                                 , NUMPED
                                 , QTPED
                                 , QTFALTAPED
                                 , CODCLI
                                 , QTGIRODIA_D
                                 , QTDIASREP_D
                                 , DESCCONSIDERAESTPENDSUG_D
                                 , PRAZOENTREGA_O
                                 , PERCARREDONDA_O
                                 , CXFORNEC_TRANSFERIR_O
                                 , TIPO_SUG_LOJA_CD
                                 , TIPO_SUG_COMPRA_TRANSF
                                 , DESC_TIPO_SUG_COMPRA_TRANSF
                                 , CODFORNECPRIORIDADE
                                 , CODDESC_FORNECPRIORIDADE
                                 , NUMSUGESTAO
                                 , QTSUGCOMPRA_D
                                 , QTIMPORT_D
                                 , EMB_POR_FORNECEDOR_O
                                 , PRECO_TRANSF_O
                                 , PRECOPED
                                 , CODPROD_TRANSITO_O
                                 , OBSERVACAOREJEICAO
                                 , INTEGRADORA
                                 , NOMEINTEGRADORA
                                 , QTOPERLOG_O
                                 , QTOPERLOG_D
                                 , INTEGRADORAESPELHONF
                                 , NOMEINTEGRADORAESPELHONF
                                 , INFOQUEBRAS
                                 , CODFILIALRETIRA_O
                                 , ESTMIN_O
                                 , ESTOQUEMIN_O
                                 , ESTOQUEMINSUG_O
                                 , FORMULA_QT_SUGERIDA_D
                                 , TIPOCUSTOTRANSF
                                 , QTCANCESTOQUEMINSUG_O
                                 , FORMULA
                              FROM PCMED_TEMP_TRANSF_ATAC_VAR ) LOOP

          -- Itens da Sugestão de Reposição
          INSERT INTO PCSUGESTAOREPOSICAOMEDITE(
                      NUMSUGESTAOREP
                    , CODFILIAL_O
                    , CODPROD_O
                    , CODFILIAL_D
                    , CODPROD_D
                    , CODMARCA_O
                    , QTUNITCX_O
                    , QTD_EST_O
                    , QTD_SUGERIDA_O
                    , QTD_TRANSFERIR_O
                    , PRIORIDADE_D
                    , TIPOSUGESTAO_D
                    , DESCTIPOSUGESTAO_D
                    , ESTOQUEMIN_D
                    , ESTOQUEMAX_D
                    , QTESTGER_D
                    , QTPEDIDA_D
                    , QTD_TRANSITO_D
                    , QTD_BLOQSEMAVARIA_D
                    , CLASSE_D
                    , PMC_D
                    , CUSTOULTENT_D
                    , PVENDA_D
                    , SUG_FRACIONADA_D
                    , QTUNITCX_D
                    , PERCARREDONDA_D
                    , QTD_SUGERIDA_D
                    , QTD_TRANSFERIR_D
                    , VLR_TRANSFERIR_D
                    , CODEQUIPE
                    , CODCATEGORIA
                    , CODSEC
                    , CODEPTO
                    , CODFORNEC
                    , EMBALAGEM
                    , UNIDADE
                    , TRIBUTACAO
                    , CODST
                    , QTVENDMES_D
                    , QTVENDMES1_D
                    , QTVENDMES2_D
                    , QTVENDMES3_D
                    , QTPENDENTE_D
                    , CODFAB_O
                    , CODFAB_D
                    , CODAUXILIAR_O
                    , CODAUXILIAR_D
                    , QUEBRA1
                    , QUEBRA2
                    , QUEBRA3
                    , QUEBRA4
                    , NUMPED
                    , QTPED
                    , QTFALTAPED
                    , CODCLI
                    , QTGIRODIA_D
                    , QTDIASREP_D
                    , DESCCONSIDERAESTPENDSUG_D
                    , PRAZOENTREGA_O
                    , PERCARREDONDA_O
                    , CXFORNEC_TRANSFERIR_O
                    , TIPO_SUG_LOJA_CD
                    , TIPO_SUG_COMPRA_TRANSF
                    , DESC_TIPO_SUG_COMPRA_TRANSF
                    , CODFORNECPRIORIDADE
                    , CODDESC_FORNECPRIORIDADE
                    , NUMSUGESTAO
                    , QTSUGCOMPRA_D
                    , QTIMPORT_D
                    , EMB_POR_FORNECEDOR_O
                    , PRECO_TRANSF_O
                    , PRECOPED
                    , CODPROD_TRANSITO_O
                    , OBSERVACAOREJEICAO
                    , INTEGRADORA
                    , NOMEINTEGRADORA
                    , QTOPERLOG_O
                    , QTOPERLOG_D
                    , INTEGRADORAESPELHONF
                    , NOMEINTEGRADORAESPELHONF
                    , INFOQUEBRAS
                    , CODFILIALRETIRA_O
                    , ESTMIN_O
                    , ESTOQUEMIN_O
                    , ESTOQUEMINSUG_O
                    , FORMULA_QT_SUGERIDA_D
                    , TIPOCUSTOTRANSF
                    , QTCANCESTOQUEMINSUG_O
                    , FORMULA
                    )
              VALUES( pi_nNumSugestaoRep
                    , vc_Reposicao.CODFILIAL_O
                    , vc_Reposicao.CODPROD_O
                    , vc_Reposicao.CODFILIAL_D
                    , vc_Reposicao.CODPROD_D
                    , vc_Reposicao.CODMARCA_O
                    , vc_Reposicao.QTUNITCX_O
                    , vc_Reposicao.QTD_EST_O
                    , vc_Reposicao.QTD_SUGERIDA_O
                    , vc_Reposicao.QTD_TRANSFERIR_O
                    , vc_Reposicao.PRIORIDADE_D
                    , vc_Reposicao.TIPOSUGESTAO_D
                    , vc_Reposicao.DESCTIPOSUGESTAO_D
                    , vc_Reposicao.ESTOQUEMIN_D
                    , vc_Reposicao.ESTOQUEMAX_D
                    , vc_Reposicao.QTESTGER_D
                    , vc_Reposicao.QTPEDIDA_D
                    , vc_Reposicao.QTD_TRANSITO_D
                    , vc_Reposicao.QTD_BLOQSEMAVARIA_D
                    , vc_Reposicao.CLASSE_D
                    , vc_Reposicao.PMC_D
                    , vc_Reposicao.CUSTOULTENT_D
                    , vc_Reposicao.PVENDA_D
                    , vc_Reposicao.SUG_FRACIONADA_D
                    , vc_Reposicao.QTUNITCX_D
                    , vc_Reposicao.PERCARREDONDA_D
                    , vc_Reposicao.QTD_SUGERIDA_D
                    , vc_Reposicao.QTD_TRANSFERIR_D
                    , vc_Reposicao.VLR_TRANSFERIR_D
                    , vc_Reposicao.CODEQUIPE
                    , vc_Reposicao.CODCATEGORIA
                    , vc_Reposicao.CODSEC
                    , vc_Reposicao.CODEPTO
                    , vc_Reposicao.CODFORNEC
                    , vc_Reposicao.EMBALAGEM
                    , vc_Reposicao.UNIDADE
                    , vc_Reposicao.TRIBUTACAO
                    , vc_Reposicao.CODST
                    , vc_Reposicao.QTVENDMES_D
                    , vc_Reposicao.QTVENDMES1_D
                    , vc_Reposicao.QTVENDMES2_D
                    , vc_Reposicao.QTVENDMES3_D
                    , vc_Reposicao.QTPENDENTE_D
                    , vc_Reposicao.CODFAB_O
                    , vc_Reposicao.CODFAB_D
                    , vc_Reposicao.CODAUXILIAR_O
                    , vc_Reposicao.CODAUXILIAR_D
                    , vc_Reposicao.QUEBRA1
                    , vc_Reposicao.QUEBRA2
                    , vc_Reposicao.QUEBRA3
                    , vc_Reposicao.QUEBRA4
                    , vc_Reposicao.NUMPED
                    , vc_Reposicao.QTPED
                    , vc_Reposicao.QTFALTAPED
                    , vc_Reposicao.CODCLI
                    , vc_Reposicao.QTGIRODIA_D
                    , vc_Reposicao.QTDIASREP_D
                    , vc_Reposicao.DESCCONSIDERAESTPENDSUG_D
                    , vc_Reposicao.PRAZOENTREGA_O
                    , vc_Reposicao.PERCARREDONDA_O
                    , vc_Reposicao.CXFORNEC_TRANSFERIR_O
                    , vc_Reposicao.TIPO_SUG_LOJA_CD
                    , vc_Reposicao.TIPO_SUG_COMPRA_TRANSF
                    , vc_Reposicao.DESC_TIPO_SUG_COMPRA_TRANSF
                    , vc_Reposicao.CODFORNECPRIORIDADE
                    , vc_Reposicao.CODDESC_FORNECPRIORIDADE
                    , vc_Reposicao.NUMSUGESTAO
                    , vc_Reposicao.QTSUGCOMPRA_D
                    , vc_Reposicao.QTIMPORT_D
                    , vc_Reposicao.EMB_POR_FORNECEDOR_O
                    , vc_Reposicao.PRECO_TRANSF_O
                    , vc_Reposicao.PRECOPED
                    , vc_Reposicao.CODPROD_TRANSITO_O
                    , vc_Reposicao.OBSERVACAOREJEICAO
                    , vc_Reposicao.INTEGRADORA
                    , vc_Reposicao.NOMEINTEGRADORA
                    , vc_Reposicao.QTOPERLOG_O
                    , vc_Reposicao.QTOPERLOG_D
                    , vc_Reposicao.INTEGRADORAESPELHONF
                    , vc_Reposicao.NOMEINTEGRADORAESPELHONF
                    , vc_Reposicao.INFOQUEBRAS
                    , vc_Reposicao.CODFILIALRETIRA_O
                    , vc_Reposicao.ESTMIN_O
                    , vc_Reposicao.ESTOQUEMIN_O
                    , vc_Reposicao.ESTOQUEMINSUG_O
                    , vc_Reposicao.FORMULA_QT_SUGERIDA_D
                    , vc_Reposicao.TIPOCUSTOTRANSF
                    , vc_Reposicao.QTCANCESTOQUEMINSUG_O
                    , vc_Reposicao.FORMULA
                    );

        -- Efetiva Transações
        iContaCommit := NVL(iContaCommit,0) + 1;
        IF (NVL(iContaCommit,0) > 1000) THEN
          COMMIT;
          iContaCommit := 0;
        END IF;

      END LOOP; -- Fim Cursor dos Itens da Reposição

      -- Efetiva Transações Pendentes
      COMMIT;

    EXCEPTION
      WHEN OTHERS THEN
        -- Desfaz Transações
        ROLLBACK;
        -- Ocorreram Erros
        po_vOcorreramErros := 'S';
        po_vMsgErros       := SQLERRM;
    END GRAVA_SUGESTAOREPOSICAOCABITE;

    ------------------------------------------------------------------------------
    -- Procedimento para Gravação das Faltas da Sugestão de Reposição Automática
    ------------------------------------------------------------------------------
    PROCEDURE GRAVA_FALTA_SUGESTAOREPOSICAO IS

      -- Variáveis auxiliares
      iContaCommit NUMBER(12);

    BEGIN

      -- Inicializa Controle do Commit
      iContaCommit := 0;

      -- Cursor com as Faltas da Sugestão de Reposição
      FOR vc_FaltasReposicao IN ( SELECT NUMSUGESTAOREP
                                       , SEQFALTA
                                       , CODFILIALFALTA
                                       , CODPRODFALTA
                                       , CODFORNEC
                                       , CODCLI
                                       , QTFALTA
                                       , CODFILIAL_O
                                       , CODPROD_O
                                       , QTFALTA_O
                                       , CODFILIAL_D
                                       , CODPROD_D
                                       , QTFALTA_D
                                       , NUMPED
                                       , QTPED
                                       , PRECOPED
                                       , NUMSUGESTAO
                                       , DTGERPED
                                       , REJEICAOINICIAL
                                       , OBSERVACAOREJEICAO
                                       , CODFORNECPRIORIDADE
                                       , TIPO_SUG_COMPRA_TRANSF
                                    FROM PCMED_TEMP_FALTAS_ATAC_VAR ) LOOP

        INSERT INTO PCSUGESTAOREPOSICAOMEDFTA
                  ( NUMSUGESTAOREP
                  , SEQFALTA
                  , CODFILIALFALTA
                  , CODPRODFALTA
                  , CODFORNEC
                  , CODCLI
                  , QTFALTA
                  , CODFILIAL_O
                  , CODPROD_O
                  , QTFALTA_O
                  , CODFILIAL_D
                  , CODPROD_D
                  , QTFALTA_D
                  , NUMPED
                  , QTPED
                  , PRECOPED
                  , NUMSUGESTAO
                  , DTGERPED
                  , REJEICAOINICIAL
                  , OBSERVACAOREJEICAO
                  , CODFORNECPRIORIDADE
                  , TIPO_SUG_COMPRA_TRANSF )
           VALUES ( vc_FaltasReposicao.NUMSUGESTAOREP
                  , vc_FaltasReposicao.SEQFALTA
                  , vc_FaltasReposicao.CODFILIALFALTA
                  , vc_FaltasReposicao.CODPRODFALTA
                  , vc_FaltasReposicao.CODFORNEC
                  , vc_FaltasReposicao.CODCLI
                  , vc_FaltasReposicao.QTFALTA
                  , vc_FaltasReposicao.CODFILIAL_O
                  , vc_FaltasReposicao.CODPROD_O
                  , vc_FaltasReposicao.QTFALTA_O
                  , vc_FaltasReposicao.CODFILIAL_D
                  , vc_FaltasReposicao.CODPROD_D
                  , vc_FaltasReposicao.QTFALTA_D
                  , vc_FaltasReposicao.NUMPED
                  , vc_FaltasReposicao.QTPED
                  , vc_FaltasReposicao.PRECOPED
                  , vc_FaltasReposicao.NUMSUGESTAO
                  , vc_FaltasReposicao.DTGERPED
                  , vc_FaltasReposicao.REJEICAOINICIAL
                  , vc_FaltasReposicao.OBSERVACAOREJEICAO
                  , vc_FaltasReposicao.CODFORNECPRIORIDADE
                  , vc_FaltasReposicao.TIPO_SUG_COMPRA_TRANSF );

        -- Efetiva Transações
        iContaCommit := NVL(iContaCommit,0) + 1;
        IF (NVL(iContaCommit,0) > 1000) THEN
          COMMIT;
          iContaCommit := 0;
        END IF;

      END LOOP; -- Fim Cursor das Faltas da Reposição

      -- Efetiva Transações Pendentes
      COMMIT;

    EXCEPTION
      WHEN OTHERS THEN
        -- Desfaz Transações
        ROLLBACK;
        -- Ocorreram Erros
        po_vOcorreramErros := 'S';
        po_vMsgErros       := SQLERRM;
    END GRAVA_FALTA_SUGESTAOREPOSICAO;

    ----------------------------------------------------------------------------
    -- Função para Retornar o Preço da Entrada
    ----------------------------------------------------------------------------
    FUNCTION FOBTEM_PRECO_ENTRADA(pi_vCodFilial    IN VARCHAR2,
                                  pi_nCodProd      IN NUMBER,
                                  pi_nValorDefault IN NUMBER)
    RETURN NUMBER IS
      vnRetPrecoEntrada NUMBER;
    BEGIN

      SELECT MAX(DECODE(PUNIT, 0, PUNITCONT, PUNIT)) AS PUNIT
        INTO vnRetPrecoEntrada
        FROM PCMOV
       WHERE (PCMOV.DTCANCEL IS NULL)
         AND (PCMOV.CODOPER LIKE 'E%')
         AND (NUMTRANSVENDA IS NULL)
         AND (PCMOV.CODPROD = pi_nCodProd)
         AND (PCMOV.CODFILIAL = pi_vCodFilial);

      IF ((NVL(vnRetPrecoEntrada,0) <= 0) AND
          (NVL(pi_nValorDefault,0)   > 0)) THEN
        vnRetPrecoEntrada := NVL(pi_nValorDefault,0);
      END IF;

      RETURN NVL(vnRetPrecoEntrada,0);

    END FOBTEM_PRECO_ENTRADA;

  /*******************************************************************************
                        INICIO DO PROCEDIMENTO PRINCIPAL
   *******************************************************************************/
  BEGIN

    -- Inicializa Quantidade de Pedidos Gerados
    po_nQtdePedidosGerados      := 0;
    -- Inicializa Retorno de Erros
    po_vOcorreramErros          := 'N';
    po_vMsgErros                := NULL;
    -- Inicializa Data de Geração de Pedido de Operador Logístico
    vdDtPedOperLog              := SYSDATE;

    ------------------------------------------------------------
    -- GERACAO DO SEQUENCIAL DE SUGESTAO DE REPOSICAO AUTOMATICA
    ------------------------------------------------------------
    IF ((pi_nOrigemChamada    =  1 ) AND
        (pi_vAutomaticoManual = 'A')) THEN
      -- Novo Número da Sugestão de Reposição
      vnProxNumSugestaoRep := FOBTEM_PROX_NUMSUGESTAOREP;
    ELSE
      -- Sem Número da Sugestão de Reposição
      vnProxNumSugestaoRep := NULL;
    END IF;

   /*-----------------------------------------------------------------
    Carga da Tabela Temporária para Geração dos Pedidos quando chamado
        da Geração dos Pedidos a partir da Sugestão de Reposição

    (OSERVAÇÃO: Quando pi_nOrigemChamada = 2, as faltas já estarão
                estarão carregadas na Tabela PCMED_TEMP_PED_ATAC_VAR)
    -----------------------------------------------------------------*/
    IF    (pi_nOrigemChamada = 1) THEN

      -- Limpa Tabela de Erros no Processamento
      EXECUTE IMMEDIATE 'TRUNCATE TABLE PCMED_TEMP_TRANSF_ATAC_VAR_ERR';

      -- Limpa Tabela Temporária para receber os Dados para Geração dos Pedidos
      EXECUTE IMMEDIATE 'TRUNCATE TABLE PCMED_TEMP_PED_ATAC_VAR';

      -- Insere na Tabela Temporária os Dados para Geração dos Pedidos
      INSERT INTO PCMED_TEMP_PED_ATAC_VAR
                ( CODFILIAL_O
                , CODFILIALRETIRA_O
                , CODPROD_O
                , CODFILIAL_D
                , CODPROD_D
                , DTGERACAO
                , DESCRICAO_O
                , QTD_TRANSFERIR_O
                , QTD_EST_O
                , PRECO_TRANSF_O
                , CODFORNECPRIORIDADE
                , TIPO_SUG_COMPRA_TRANSF
                , QUEBRA1
                , QUEBRA2
                , QUEBRA3
                , QUEBRA4
                , INTEGRADORA
                , INTEGRADORAESPELHONF
                , QTUNITCX_D
                , CODAUXILIAR_O
                , ESTOQUEPORLOTE
                , NUMLOTE )
           SELECT CODFILIAL_O
                , CODFILIALRETIRA_O
                , CODPROD_O
                , CODFILIAL_D
                , CODPROD_D
                , DTGERACAO
                , DESCRICAO_O
                , QTD_TRANSFERIR_O
                , QTD_EST_O
                , PRECO_TRANSF_O
                , CODFORNECPRIORIDADE
                , TIPO_SUG_COMPRA_TRANSF
                , QUEBRA1
                , QUEBRA2
                , QUEBRA3
                , QUEBRA4
                , INTEGRADORA
                , INTEGRADORAESPELHONF
                , QTUNITCX_D
                , CODAUXILIAR_O
                , ESTOQUEPORLOTE
                , NUMLOTE
             FROM PCMED_TEMP_TRANSF_ATAC_VAR
            WHERE (QTD_TRANSFERIR_O > 0); -->> Somente Linhas com Quantidade a Transferir

      -- Efetiva Transações
      COMMIT;

    END IF; -- Fim Condição Chamado da Geração dos Pedidos a partir da Sugestão de Reposição

   /*-----------------------------
    Pesquisa dos Parâmetros Gerais
    -----------------------------*/

    -- Parâmetro de Número de Casas Decimais do Preço de Venda
    POBTEM_PARAMFILIAL_NUMBER('99',
                              'CON_NUMCASASDECVENDA',
                              vrParamFilial.nCON_NUMCASASDECVENDA, --> Valor do Parâmetro
                              vvErroPesqParam,
                              vvMsgErroPesqParam);

    -- Parâmetro de Transferência TV10 Somando ST ao Preço quando formado pelo Custo -- HIS.00636.2016
    POBTEM_PARAMFILIAL_STRING('99',
                              'CON_CONDVENDA10',
                              vrParamFilial.vCON_CONDVENDA10, --> Valor do Parâmetro
                              vvErroPesqParam,
                              vvMsgErroPesqParam);

    -- Parâmetro Utiliza Controle de Medicamentos -- HIS.03379.2017
    POBTEM_PARAMFILIAL_STRING('99',
                              'CON_UTILIZACONTROLEMEDICAMENTOS',
                              vrParamFilial.vUTILIZACONTROLEMEDICAM, --> Valor do Parâmetro
                              vvErroPesqParam,
                              vvMsgErroPesqParam);

    -- Verifica Parâmetros Gerais
    BEGIN
      SELECT NVL(PCCONSUM.USATRIBUTACAOPORUF,'N')      USATRIBUTACAOPORUF
           , NVL(PCCONSUM.CALCULARSTCOMIPI,'N')        CALCULARSTCOMIPI
           , NVL(PCCONSUM.MOSTRARPVENDASEMST,'N')      MOSTRARPVENDASEMST
           , NVL(PCCONSUM.TIPOCALCIPI,'T2')            TIPOCALCIPI
           , NVL(PCCONSUM.TIPOCALCST,'T2')             TIPOCALCST
           , NVL(PCCONSUM.CALCSTPF,' ')                CALCSTPF
           , NVL(PCCONSUM.CONSIDERAISENTOSCOMOPF,' ')  CONSIDERAISENTOSCOMOPF
           , NVL(PCCONSUM.USACOMISSAOPORCLIENTE,' ')   USACOMISSAOPORCLIENTE
           , NVL(PCCONSUM.USACOMISSAOPORRCA,' ')       USACOMISSAOPORRCA
           , NVL(PCCONSUM.USACOMISSAOPORLINHAPROD,'N') USACOMISSAOPORLINHAPROD
           , PCCONSUM.TXVENDA
        INTO vrPcConsum.vUSATRIBUTACAOPORUF
           , vrPcConsum.vCALCULARSTCOMIPI
           , vrPcConsum.vMOSTRARPVENDASEMST
           , vrPcConsum.vTIPOCALCIPI
           , vrPcConsum.vTIPOCALCST
           , vrPcConsum.vCALCSTPF
           , vrPcConsum.vCONSIDERAISENTOSCOMOPF
           , vrPcConsum.vUSACOMISSAOPORCLIENTE
           , vrPcConsum.vUSACOMISSAOPORRCA
           , vrPcConsum.vUSACOMISSAOPORLINHAPROD
           , vrPcConsum.nTXVENDA
        FROM PCCONSUM;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vrPcConsum.vUSATRIBUTACAOPORUF      := 'N';
        vrPcConsum.vCALCULARSTCOMIPI        := 'N';
        vrPcConsum.vMOSTRARPVENDASEMST      := 'N';
        vrPcConsum.vTIPOCALCIPI             := 'T2';
        vrPcConsum.vTIPOCALCST              := 'T2';
        vrPcConsum.vCALCSTPF                := ' ';
        vrPcConsum.vCONSIDERAISENTOSCOMOPF  := ' ';
        vrPcConsum.vUSACOMISSAOPORCLIENTE   := ' ';
        vrPcConsum.vUSACOMISSAOPORLINHAPROD := 'N';
        vrPcConsum.nTXVENDA                 := 0;
    END;

    ----------------------------------
    -- Parâmetro da Reposição de Lojas
    ----------------------------------
    BEGIN
      SELECT VALOR
        INTO vIGNORARVALIDACAOMULTIPLOEMB
        FROM PCPARAMREPOSICAOLOJAS
       WHERE (NOME      = 'IGNORARVALIDACAOMULTIPLOEMB')
         AND (CODFILIAL = '99');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vIGNORARVALIDACAOMULTIPLOEMB := NULL;
    END;

    ---------------------------------------------------------------------------------
    -- REGRA ESPECÍFICA - Utilizar Arredondamento da Embalagem do Fornecedor na Falta
    ---------------------------------------------------------------------------------
    BEGIN
      SELECT VALOR
        INTO vUSAREGRAARREDEMBFRNFTAREP
        FROM PCREGRASEXCECAOMED
       WHERE (NOME      = 'USAREGRAARREDEMBFRNFTAREP')
         AND (CODFILIAL = '99');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vUSAREGRAARREDEMBFRNFTAREP := NULL;
    END;

    ---------------------------------------------------------------------------------
    -- REGRA ESPECÍFICA - Aplicar Indice Transferência
    ---------------------------------------------------------------------------------
   /*
    BEGIN
      SELECT VALOR
        INTO vUSAREGRAAPLICARINDICETRANSF
        FROM PCREGRASEXCECAOMED
       WHERE (NOME      = 'USAREGRAAPLICARINDICETRANSF2312')
         AND (CODFILIAL = '99');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vUSAREGRAAPLICARINDICETRANSF := NULL;
    END;
    */
    ----------------------------------------------------
    -- Parâmetro da Reposição de Lojas - MED-1896
    ----------------------------------------------------
    BEGIN
      SELECT VALOR
        INTO vUSAREGRAAPLICARINDICETRANSF
        FROM PCPARAMREPOSICAOLOJAS
       WHERE (NOME      = 'USAREGRAAPLICARINDICETRANSF')
         AND (CODFILIAL = '99');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vUSAREGRAAPLICARINDICETRANSF := NULL;
    END;

    ----------------------------------------------------
    -- Parâmetro da Reposição de Lojas - DDMEDICA-4845
    ----------------------------------------------------
    BEGIN
      SELECT VALOR
        INTO vIGNORARCALCULOCOMISSREPLOJA
        FROM PCPARAMREPOSICAOLOJAS
       WHERE (NOME      = 'IGNORARCALCULOCOMISSREPLOJA')
         AND (CODFILIAL = '99');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vIGNORARCALCULOCOMISSREPLOJA := 'N';
    END;
    BEGIN
      SELECT VALOR
        INTO vIGNORARCALCULOCOMISSREPCD
        FROM PCPARAMREPOSICAOLOJAS
       WHERE (NOME      = 'IGNORARCALCULOCOMISSREPCD')
         AND (CODFILIAL = '99');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vIGNORARCALCULOCOMISSREPCD := 'N';
    END;

   /******************************************************************************
    Cursor de Dados de Cabeçalho (Por Filial de Origem/Destino)
    ***********************************************************/
    FOR vc_Dados_Cab IN c_Dados_Cab LOOP

     /*-------------------------------------------
      Limpa Record que receberá os dados do Pedido
      -------------------------------------------*/
      vrPedido := vrLimpaPedido;

     /*--------------------------
      Inicializa Totais do Pedido
      --------------------------*/
      vrPedido.nVLATEND      := 0;
      vrPedido.nNUMITENS     := 0;
      vrPedido.nVLCUSTOFIN   := 0;
      vrPedido.nVLCUSTOREAL  := 0;
      vrPedido.nTOTPESO      := 0;
      vrPedido.nTOTVOLUME    := 0;
      vrPedido.nVLCUSTOCONT  := 0;
      vrPedido.nVLCUSTOREP   := 0;
      vrPedido.nVLTABELA     := 0;
      vrPedido.nVLTOTAL      := 0;
      vrPedido.nVLOUTRASDESP := 0;
      vrPedido.nVLFRETE      := 0;
      vrPedido.nVLDESCONTO   := 0;

      ---------------------------------------------
      -- Parâmetro da Reposição de Lojas - MED-1896
      ---------------------------------------------
      BEGIN
        SELECT VALOR
          INTO vUSAQTUNITPCEMBREPLOJA
          FROM PCPARAMREPOSICAOLOJAS
         WHERE (NOME      = 'USAQTUNITPCEMBREPLOJA')
           AND (CODFILIAL = '99');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vUSAQTUNITPCEMBREPLOJA := NULL;
      END;
      -- Parâmetro se a Filial de Origem Utiliza Venda por Embalagem - DDMEDICA-5012
      IF (vUSAQTUNITPCEMBREPLOJA = 'S') THEN
        POBTEM_PARAMFILIAL_STRING(vc_Dados_Cab.CODFILIAL_O,
                                  'FIL_UTILIZAVENDAPOREMBALAGEM',
                                  vUTILIZAVENDAPOREMBALAGEM,
                                  vvErroPesqParam,
                                  vvMsgErroPesqParam);
        IF (vUTILIZAVENDAPOREMBALAGEM IS NULL) THEN
          POBTEM_PARAMFILIAL_STRING('99',
                                    'CON_UTILIZAVENDAPOREMBALAGEM',
                                    vUTILIZAVENDAPOREMBALAGEM,
                                    vvErroPesqParam,
                                    vvMsgErroPesqParam);
        END IF;
        IF (NVL(vUTILIZAVENDAPOREMBALAGEM,'N') <> 'S') THEN
          vUSAQTUNITPCEMBREPLOJA := 'N';
        END IF;
      END IF;

      ----------------------------------------------------
      -- REGRA ESPECÍFICA - Utilizar Conversão PCEMBALAGEM
      ----------------------------------------------------
      IF (NVL(vUSAQTUNITPCEMBREPLOJA,'N') = 'S') THEN
        vrPedido.vUTILIZAVENDAPOREMBALAGEM := 'S';
      ELSE
        vrPedido.vUTILIZAVENDAPOREMBALAGEM := NULL;
      END IF;

      ----------------------------------------------------
      -- REGRA ESPECÍFICA - Aplicar Indice Transferência
      ----------------------------------------------------
      IF (vUSAREGRAAPLICARINDICETRANSF = 'S') THEN
        POBTEM_PARAMFILIAL_NUMBER(vc_Dados_Cab.CODFILIAL_D,
                                  'FIL_INDICECUSTOTRANSF',
                                  vrParamFilial.nFIL_INDICECUSTOTRANSF, --> Valor do Parâmetro
                                  vvErroPesqParam,
                                  vvMsgErroPesqParam);
      END IF;

     /*-----------------------------------------
      Pesquisa de Parâmetros da Filial de Origem
      -----------------------------------------*/

      -- Pesquisa Dados da Filial de Origem
      BEGIN
        SELECT 'S'
             , PCFILIAL.CGC
             , PCFILIAL.QTMAXPEDIDO
             , PCFILIAL.UF
          INTO vrFilOrigem.vcAchouFilial
             , vrFilOrigem.vvCgcFilial
             , vrFilOrigem.vnQtMaxPedido
             , vrFilOrigem.vvUfOrigem
          FROM PCFILIAL
         WHERE (PCFILIAL.CODIGO = vc_Dados_Cab.CODFILIAL_O);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vrFilOrigem.vcAchouFilial := 'N';
          vrFilOrigem.vvCgcFilial   := NULL;
          vrFilOrigem.vnQtMaxPedido := 0;
          vrFilOrigem.vvUfOrigem    := null;
      END;

      -- Parâmetro de Quantidade Máxima de Itens da NFe na Filial de Origem - TRANSFERENCIA ou PEDIDO OPERADOR LOGISTICO
      IF    (vc_Dados_Cab.TIPO_SUG_COMPRA_TRANSF IN ('T','L')) THEN
        -- Obtem Valor do Parâmetro
        POBTEM_PARAMFILIAL_NUMBER(vc_Dados_Cab.CODFILIAL_O,
                                  'FIL_NUMMAXITENSNFE',
                                  vrParamFilial.nFIL_NUMMAXITENSNFE, --> Valor do Parâmetro
                                  vvErroPesqParam,
                                  vvMsgErroPesqParam);
        -- Se informou a Quantidade Máxima de Itens na Filial e for menor que o estabelecido na NFe
        IF ( (NVL(vrFilOrigem.vnQtMaxPedido,0) > 0) AND
             (NVL(vrFilOrigem.vnQtMaxPedido,0) < NVL(vrParamFilial.nFIL_NUMMAXITENSNFE,0)) ) THEN
          -- O Limite de Itens no Pedido será o informado na Filial e não o da NF-e
          vrParamFilial.nFIL_NUMMAXITENSNFE := NVL(vrFilOrigem.vnQtMaxPedido,0);
        END IF;
        IF (vrParamFilial.nFIL_NUMMAXITENSNFE <= 0) THEN
          vrParamFilial.nFIL_NUMMAXITENSNFE := 99;
        END IF;
      -- Parâmetro de Quantidade Máxima de Itens da NFe NÃO EXISTIRÁ NA COMPRA (Coloca um valor bem alto para não Quebrar o Pedido)
      ELSIF (vc_Dados_Cab.TIPO_SUG_COMPRA_TRANSF = 'C') THEN
        vrParamFilial.nFIL_NUMMAXITENSNFE := 999999;
      END IF;

      -- Parâmetro de Tributação - HIS.02786.2016
      POBTEM_PARAMFILIAL_STRING(vc_Dados_Cab.CODFILIAL_O,
                                'TRIBUTSAIDAORIGEMNACIMP',
                                vrParamFilial.vTRIBUTSAIDAORIGEMNACIMP, --> Valor do Parâmetro
                                vvErroPesqParam,
                                vvMsgErroPesqParam);

        POBTEM_PARAMFILIAL_STRING(vc_Dados_Cab.CODFILIAL_O,'DESCSTFORAUFTRANSF',
                                vDESCSTFORAUFTRANSF,vvErroPesqParam,
                                vvMsgErroPesqParam);
     /*------------------------------------------------
      Pesquisa de Dados do Cliente da Filial de Destino
      ------------------------------------------------*/

      -- Pesquisa Cliente da Filial de Destino
      BEGIN
        SELECT PCFILIAL.CODCLI
             , PCFILIAL.UF
             , PCFILIAL.TIPOFILIAL
          INTO vrFilDestino.nCODCLI
             , vrFilDestino.vvUfDestino
             , vrFilDestino.vvTipoFilial
          FROM PCFILIAL
         WHERE (PCFILIAL.CODIGO = vc_Dados_Cab.CODFILIAL_D);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vrFilDestino.nCODCLI      := NULL;
          vrFilDestino.vvUfDestino  := NULL;
          vrFilDestino.vvTipoFilial := NULL;
      END;

      -- Pesquisa Dados do Cliente
      BEGIN
        SELECT 'S' ACHOU_CLIENTE
             , PCCLIENT.CGCENT
             , PCCLIENT.VALIDARMULTIPLOVENDA
             , PCCLIENT.CODUSUR1
             , PCCLIENT.CODCOB
             , PCCLIENT.CODPLPAG
             , PCCLIENT.OBSENTREGA1
             , PCCLIENT.OBSENTREGA2
             , PCCLIENT.OBSENTREGA3
             , PCCLIENT.CODPRACA
             , PCCLIENT.CGCENT
             , NVL(PCCLIENT.TIPOCUSTOTRANSF,'E') TIPOCUSTOTRANSF
             , NVL(PCCLIENT.PERACRESTRANSF,0) PERACRESTRANSF
             , PCCLIENT.ISENTOIPI
             , PCCLIENT.SULFRAMA
             , PCCLIENT.TIPOFJ
             , PCCLIENT.ESTENT
             , PCCLIENT.CALCULAST
             , UPPER(PCCLIENT.IEENT) IEENT
             , PCCLIENT.PERCOMCLI
             , PCCLIENT.TIPOEMPRESA
             , NVL(PCCLIENT.UTILIZAIESIMPLIFICADA,'N') UTILIZAIESIMPLIFICADA
             , PCCLIENT.FANTASIA
             , NVL(PCCLIENT.CLIENTEFONTEST,'N') -- HIS.03379.2017
             , NVL(PCCLIENT.FRETEDESPACHO, 'C')
          INTO vrClienteDestino.vvAchouDadosCliente
             , vrClienteDestino.vvCgcClienteDestino
             , vrClienteDestino.vVALIDARMULTIPLOVENDA
             , vrClienteDestino.nCODUSUR1
             , vrClienteDestino.vCODCOB
             , vrClienteDestino.nCODPLPAG
             , vrClienteDestino.vOBSENTREGA1
             , vrClienteDestino.vOBSENTREGA2
             , vrClienteDestino.vOBSENTREGA3
             , vrClienteDestino.nCODPRACA
             , vrClienteDestino.vCGCENT
             , vrClienteDestino.vTIPOCUSTOTRANSF
             , vrClienteDestino.nPERACRESTRANSF
             , vrClienteDestino.nISENTOIPI
             , vrClienteDestino.vSULFRAMA
             , vrClienteDestino.vTIPOFJ
             , vrClienteDestino.vESTENT
             , vrClienteDestino.vCALCULAST
             , vrClienteDestino.vIEENT
             , vrClienteDestino.nPERCOMCLI
             , vrClienteDestino.vTIPOEMPRESA
             , vrClienteDestino.vUTILIZAIESIMPLIFICADA
             , vrClienteDestino.vFANTASIA
             , vrClienteDestino.vCLIENTEFONTEST -- HIS.03379.2017
             , vrClienteDestino.vFRETEDESPACHO
          FROM PCCLIENT
         WHERE (PCCLIENT.CODCLI = vrFilDestino.nCODCLI);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vrClienteDestino.vvAchouDadosCliente    := NULL;
          vrClienteDestino.vvCgcClienteDestino    := NULL;
          vrClienteDestino.vVALIDARMULTIPLOVENDA  := NULL;
          vrClienteDestino.nCODUSUR1              := NULL;
          vrClienteDestino.vCODCOB                := NULL;
          vrClienteDestino.nCODPLPAG              := NULL;
          vrClienteDestino.vOBSENTREGA1           := NULL;
          vrClienteDestino.vOBSENTREGA2           := NULL;
          vrClienteDestino.vOBSENTREGA3           := NULL;
          vrClienteDestino.nCODPRACA              := NULL;
          vrClienteDestino.vCGCENT                := NULL;
          vrClienteDestino.vTIPOCUSTOTRANSF       := NULL;
          vrClienteDestino.nPERACRESTRANSF        := NULL;
          vrClienteDestino.nISENTOIPI             := NULL;
          vrClienteDestino.vSULFRAMA              := NULL;
          vrClienteDestino.vTIPOFJ                := NULL;
          vrClienteDestino.vESTENT                := NULL;
          vrClienteDestino.vCALCULAST             := NULL;
          vrClienteDestino.vIEENT                 := NULL;
          vrClienteDestino.nPERCOMCLI             := NULL;
          vrClienteDestino.vTIPOEMPRESA           := NULL;
          vrClienteDestino.vUTILIZAIESIMPLIFICADA := NULL;
          vrClienteDestino.vFANTASIA              := NULL;
          vrClienteDestino.vCLIENTEFONTEST        := NULL;
          vrClienteDestino.vFRETEDESPACHO         := NULL;
      END;

     /*------------------------------------------
      Pesquisa de Parâmetros da Filial de Destino
      ------------------------------------------*/

      V_REGRADEFINICAOGERARDESPESAS := F_OBTER_PARAM_REPOSICAO_LOJAS('99',
                                                                     'REGRADEFINICAOGERARDESPESAS',
                                                                     '1');
      -- Verificação dos Radicais de CNPJ - DDMEDICA-5286
      IF (NVL(v_REGRADEFINICAOGERARDESPESAS,'1') = '2') THEN
        IF (FUSA_CFOP_VENDA(vrFilOrigem.vvCgcFilial,
                            vrClienteDestino.vvCgcClienteDestino) = 'S') THEN
          vvGeraCPagar := 'N';
        ELSE
          vvGeraCPagar := 'S';
        END IF;
      -- Parâmetro de Gerar Despesas na Reposição da Filial de Destino
      ELSE
        POBTEM_PARAMFILIAL_STRING(vc_Dados_Cab.CODFILIAL_D,
                                  'GERARDESPESASREPOSICAO',
                                  vvGeraCPagar, --> Valor do Parâmetro
                                  vvErroPesqParam,
                                  vvMsgErroPesqParam);
      END IF;

      -- Pesquisa Dados do Cliente por Filial - HIS.03379.2017
      BEGIN
        SELECT NVL(PCCLIENTFILIALMED.CLIENTEFONTEST,'N')
          INTO vrClienteDestino.vCLIENTEFONTEST
          FROM PCCLIENTFILIALMED
         WHERE (PCCLIENTFILIALMED.CODCLI    = vrFilDestino.nCODCLI)
           AND (PCCLIENTFILIALMED.CODFILIAL = vc_Dados_Cab.CODFILIAL_O);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL; -->> Se não achar não faz nada, mantém dados da PCCLIENT
      END;

      -- Pesquisa Regiao do Cliente por Filial
      BEGIN
        SELECT 'S'
             , NUMREGIAO
          INTO vrPracaCliDestino.vcAchouPraca
             , vrPracaCliDestino.nNUMREGIAO
          FROM PCTABPRCLI
         WHERE (CODCLI      = vrFilDestino.nCODCLI)
           AND (CODFILIALNF = vc_Dados_Cab.CODFILIAL_O);
      EXCEPTION
        -- Se não encontrar Regiao do Cliente por Filial
        WHEN NO_DATA_FOUND THEN
          -- Pesquisa a Região do Cliente
          BEGIN
            SELECT 'S'
                 , PCPRACA.NUMREGIAO
              INTO vrPracaCliDestino.vcAchouPraca
                 , vrPracaCliDestino.nNUMREGIAO
              FROM PCPRACA
             WHERE (PCPRACA.CODPRACA = vrClienteDestino.nCODPRACA);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vrPracaCliDestino.vcAchouPraca := 'N';
              vrPracaCliDestino.nNUMREGIAO   := NULL;
          END;
      END;

      -- Pesquisa dados do RCA
      BEGIN
        SELECT 'S'
             , PCUSUARI.CODDISTRIB
             , PCUSUARI.CODSUPERVISOR
             , PCUSUARI.TIPOVEND
             , PCUSUARI.PERCENT2
          INTO vrRca.vcAchouRCA
             , vrRca.vCODDISTRIB
             , vrRca.nCODSUPERVISOR
             , vrRca.vTIPOVEND
             , vrRca.nPERCENT2
          FROM PCUSUARI
         WHERE (PCUSUARI.CODUSUR = vrClienteDestino.nCODUSUR1);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vrRca.vcAchouRCA     := 'N';
          vrRca.vCODDISTRIB    := NULL;
          vrRca.nCODSUPERVISOR := NULL;
          vrRca.vTIPOVEND      := NULL;
          vrRca.nPERCENT2      := NULL;
      END;

      -- Pesquisa dados do Plano de Pagamento
      BEGIN
        SELECT 'S'
             , PCPLPAG.TIPOVENDA
             , PCPLPAG.NUMDIAS
             , PCPLPAG.PRAZO1
             , PCPLPAG.PRAZO2
             , PCPLPAG.PRAZO3
             , PCPLPAG.PRAZO4
             , PCPLPAG.PRAZO5
             , PCPLPAG.PRAZO6
             , PCPLPAG.PRAZO7
             , PCPLPAG.PRAZO8
             , PCPLPAG.PRAZO9
             , PCPLPAG.PRAZO10
             , PCPLPAG.PRAZO11
             , PCPLPAG.PRAZO12
             , PCPLPAG.NUMPR
          INTO vrPlanoPag.vcAchouPlPag
             , vrPlanoPag.vTIPOVENDA
             , vrPlanoPag.nNUMDIAS
             , vrPlanoPag.nPRAZO1
             , vrPlanoPag.nPRAZO2
             , vrPlanoPag.nPRAZO3
             , vrPlanoPag.nPRAZO4
             , vrPlanoPag.nPRAZO5
             , vrPlanoPag.nPRAZO6
             , vrPlanoPag.nPRAZO7
             , vrPlanoPag.nPRAZO8
             , vrPlanoPag.nPRAZO9
             , vrPlanoPag.nPRAZO10
             , vrPlanoPag.nPRAZO11
             , vrPlanoPag.nPRAZO12
             , vrPlanoPag.nNUMPR
          FROM PCPLPAG
         WHERE (PCPLPAG.CODPLPAG = vrClienteDestino.nCODPLPAG);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vrPlanoPag.vcAchouPlPag := 'N';
          vrPlanoPag.vTIPOVENDA   := NULL;
          vrPlanoPag.nNUMDIAS     := NULL;
          vrPlanoPag.nPRAZO1      := NULL;
          vrPlanoPag.nPRAZO2      := NULL;
          vrPlanoPag.nPRAZO3      := NULL;
          vrPlanoPag.nPRAZO4      := NULL;
          vrPlanoPag.nPRAZO5      := NULL;
          vrPlanoPag.nPRAZO6      := NULL;
          vrPlanoPag.nPRAZO7      := NULL;
          vrPlanoPag.nPRAZO8      := NULL;
          vrPlanoPag.nPRAZO9      := NULL;
          vrPlanoPag.nPRAZO10     := NULL;
          vrPlanoPag.nPRAZO11     := NULL;
          vrPlanoPag.nPRAZO12     := NULL;
          vrPlanoPag.nNUMPR       := NULL;
      END;

      -- Pesquisa Dados do Fornecedor
      IF   (vc_Dados_Cab.TIPO_SUG_COMPRA_TRANSF = 'C') THEN
        BEGIN
          SELECT CODFORNEC
               , FORNECEDOR
               , VLMINPEDREPOSICAO
            INTO vrFornecDestino.nCODFORNEC
               , vrFornecDestino.vRAZAOSOCIAL
               , vrFornecDestino.nVLMINPEDREPOSICAO
            FROM PCFORNEC
           WHERE (PCFORNEC.CODFORNEC = vc_Dados_Cab.CODFORNECPRIORIDADE);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vrFornecDestino.nCODFORNEC         := NULL;
            vrFornecDestino.vRAZAOSOCIAL       := NULL;
            vrFornecDestino.nVLMINPEDREPOSICAO := NULL;
        END;
     ELSIF (vc_Dados_Cab.TIPO_SUG_COMPRA_TRANSF IN ('T','L')) THEN
        BEGIN
          SELECT PCFORNEC.CODFORNEC
               , SUBSTR(PCFORNEC.FORNECEDOR,1,30)
               , PCFORNEC.VLMINPEDREPOSICAO
            INTO vrFornecDestino.nCODFORNEC
               , vrFornecDestino.vRAZAOSOCIAL
               , vrFornecDestino.nVLMINPEDREPOSICAO
            FROM PCFILIAL
               , PCFORNEC
           WHERE (PCFILIAL.CODFORNEC = PCFORNEC.CODFORNEC)
             AND (PCFILIAL.CODIGO    = vc_Dados_Cab.CODFILIAL_O)
             AND (ROWNUM             = 1);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vrFornecDestino.nCODFORNEC         := NULL;
            vrFornecDestino.vRAZAOSOCIAL       := NULL;
            vrFornecDestino.nVLMINPEDREPOSICAO := NULL;
        END;
     END IF;

      -- Campo PERCVENDA = 100%
      vrPedido.nPERCVENDA := 100;

      -- Definição da Tipo de Venda = 10 - Transferência
      vrPedido.nCONDVENDA := 10;

      -- Definição se Gera Contas a Pagar
      vrPedido.vGERACP := NVL(vvGeraCPagar,'N');

      -- Definição se Usa CFOP de Venda na Transferência
      vrPedido.vUSACFOPVENDANATV10 := FUSA_CFOP_VENDA(vrFilOrigem.vvCgcFilial,
                                                      vrClienteDestino.vvCgcClienteDestino);

      -- Definição dos Prazos do Pedido
      IF (NVL(vrPlanoPag.nPRAZO1,0)  > 0) THEN vrPedido.nPRAZO1  := NVL(vrPlanoPag.nPRAZO1,0);  ELSE vrPedido.nPRAZO1  := NULL; END IF;
      IF (NVL(vrPlanoPag.nPRAZO2,0)  > 0) THEN vrPedido.nPRAZO2  := NVL(vrPlanoPag.nPRAZO2,0);  ELSE vrPedido.nPRAZO2  := NULL; END IF;
      IF (NVL(vrPlanoPag.nPRAZO3,0)  > 0) THEN vrPedido.nPRAZO3  := NVL(vrPlanoPag.nPRAZO3,0);  ELSE vrPedido.nPRAZO3  := NULL; END IF;
      IF (NVL(vrPlanoPag.nPRAZO4,0)  > 0) THEN vrPedido.nPRAZO4  := NVL(vrPlanoPag.nPRAZO4,0);  ELSE vrPedido.nPRAZO4  := NULL; END IF;
      IF (NVL(vrPlanoPag.nPRAZO5,0)  > 0) THEN vrPedido.nPRAZO5  := NVL(vrPlanoPag.nPRAZO5,0);  ELSE vrPedido.nPRAZO5  := NULL; END IF;
      IF (NVL(vrPlanoPag.nPRAZO6,0)  > 0) THEN vrPedido.nPRAZO6  := NVL(vrPlanoPag.nPRAZO6,0);  ELSE vrPedido.nPRAZO6  := NULL; END IF;
      IF (NVL(vrPlanoPag.nPRAZO7,0)  > 0) THEN vrPedido.nPRAZO7  := NVL(vrPlanoPag.nPRAZO7,0);  ELSE vrPedido.nPRAZO7  := NULL; END IF;
      IF (NVL(vrPlanoPag.nPRAZO8,0)  > 0) THEN vrPedido.nPRAZO8  := NVL(vrPlanoPag.nPRAZO8,0);  ELSE vrPedido.nPRAZO8  := NULL; END IF;
      IF (NVL(vrPlanoPag.nPRAZO9,0)  > 0) THEN vrPedido.nPRAZO9  := NVL(vrPlanoPag.nPRAZO9,0);  ELSE vrPedido.nPRAZO9  := NULL; END IF;
      IF (NVL(vrPlanoPag.nPRAZO10,0) > 0) THEN vrPedido.nPRAZO10 := NVL(vrPlanoPag.nPRAZO10,0); ELSE vrPedido.nPRAZO10 := NULL; END IF;
      IF (NVL(vrPlanoPag.nPRAZO11,0) > 0) THEN vrPedido.nPRAZO11 := NVL(vrPlanoPag.nPRAZO11,0); ELSE vrPedido.nPRAZO11 := NULL; END IF;
      IF (NVL(vrPlanoPag.nPRAZO12,0) > 0) THEN vrPedido.nPRAZO12 := NVL(vrPlanoPag.nPRAZO12,0); ELSE vrPedido.nPRAZO12 := NULL; END IF;

      -- Inicializa Contador de Itens Inseridos no Pedido
      -- Começa com o valor máximo para forçar a quebra do Pedido no primeiro processamento
      IF (NVL(vrParamFilial.nFIL_NUMMAXITENSNFE,0) > 0) THEN
        viContaItensPed := NVL(vrParamFilial.nFIL_NUMMAXITENSNFE,0) + 1;
      ELSE
        viContaItensPed := 999;
      END IF;

     /*************************************************************
      SE PEDIDO DE COMPRA E SE  SE INFORMOU VALOR MINIMO DO PEDIDO,
      VERIFICA O VALOR MINIMO DO PEDIDO
      *************************************************************/
      -- Flag de Controle de Valor Minimo do Pedido
      bATINGIUVLMINPEDIDO := TRUE;
      IF (NVL(vrFornecDestino.nVLMINPEDREPOSICAO,0) > 0) THEN
        -- Calcula O Valor Total do Pedido
        nVLTOTALPEDIDOCOMPRA := 0;
        FOR vc_Dados_Ite IN c_Dados_Ite(vc_Dados_Cab.CODFILIAL_O
                                      , vc_Dados_Cab.CODFILIALRETIRA_O
                                      , vc_Dados_Cab.CODFILIAL_D
                                      , vc_Dados_Cab.CODFORNECPRIORIDADE
                                      , vc_Dados_Cab.TIPO_SUG_COMPRA_TRANSF
                                      , vc_Dados_Cab.QUEBRA1
                                      , vc_Dados_Cab.QUEBRA2
                                      , vc_Dados_Cab.QUEBRA3
                                      , vc_Dados_Cab.QUEBRA4
                                      , vc_Dados_Cab.INTEGRADORA
                                      , vc_Dados_Cab.INTEGRADORAESPELHONF
                                      ) LOOP
          -- Acumula Valor Total do Pedido
          nVLTOTALPEDIDOCOMPRA := NVL(nVLTOTALPEDIDOCOMPRA,0) + (NVL(vc_Dados_Ite.QTD_TRANSFERIR_O,0) * NVL(vc_Dados_Ite.PRECO_TRANSF_O,0));
        END LOOP;
        -- Se não atingiu o Valor Mínimo do Pedido
        IF (NVL(nVLTOTALPEDIDOCOMPRA,0) < NVL(vrFornecDestino.nVLMINPEDREPOSICAO,0)) THEN
          bATINGIUVLMINPEDIDO := FALSE;
        END IF;
      END IF;

     /****************************************************************************
      Cursor dos Itens para cada Cabeçalho
      ************************************/
      FOR vc_Dados_Ite IN c_Dados_Ite(vc_Dados_Cab.CODFILIAL_O
                                    , vc_Dados_Cab.CODFILIALRETIRA_O
                                    , vc_Dados_Cab.CODFILIAL_D
                                    , vc_Dados_Cab.CODFORNECPRIORIDADE
                                    , vc_Dados_Cab.TIPO_SUG_COMPRA_TRANSF
                                    , vc_Dados_Cab.QUEBRA1
                                    , vc_Dados_Cab.QUEBRA2
                                    , vc_Dados_Cab.QUEBRA3
                                    , vc_Dados_Cab.QUEBRA4
                                    , vc_Dados_Cab.INTEGRADORA
                                    , vc_Dados_Cab.INTEGRADORAESPELHONF) LOOP

       /*---------------------------------------------
             Inicializa Variáveis do Item do Pedido
        ---------------------------------------------*/

        -- Campos do processo de conversão da PCEMBALAGEM
        vrItemPedido.nQTUNITEMB   := NULL;
        vrItemPedido.nCODAUXILIAR := NULL;

        ----------------------------------
        -- Lote do Produto - DDMEDICA-5077
        ----------------------------------

        -- Inicialização do Lote
        vrItemPedido.vNUMLOTE := NULL;
        vvInformacaoLoteFab   := NULL;

        -- Se Pedido de Avaria
        IF    (nvl(pi_vPedidoAvaria,'N') = 'S') THEN

          -- Atribui Lote se Controlar Estoque por Lote
          IF (NVL(vc_Dados_Ite.ESTOQUEPORLOTE,'N') = 'S') THEN

            vrItemPedido.vNUMLOTE := vc_Dados_Ite.NUMLOTE;
            vvInformacaoLoteFab   := ' e Lote Fab. ' || vc_Dados_Ite.NUMLOTE;

          END IF;

        END IF;

       /*---------------------------------------------
        DDVENDAS-37042 - Fator PCEMBALAGEM
        ---------------------------------------------*/
        vnQtUnitEmbalagem := F_OBTEM_QTUNIT_EMBALAGEM(vc_Dados_Ite.CODAUXILIAR_O,
                                                      vc_Dados_Cab.CODFILIAL_O,
                                                      vUSAQTUNITPCEMBREPLOJA);

       /*---------------------------------------------
        Verifica se o Item pode ser Inserido no Pedido
        ---------------------------------------------*/

        -- Iniciliza Controle indicando que aceita o Item
        vbAceitaItem    := TRUE;
        vMotivoRejeicao := NULL;

        -- Crítica de Código do Cliente existente
        IF (NVL(vrFilDestino.nCODCLI,0) = 0) THEN

          -- Rejeita Item
          vbAceitaItem    := FALSE;
          vMotivoRejeicao := '0001 - Código do cliente não informado do cadastro da filial de destino ' || vc_Dados_Cab.CODFILIAL_D;

        ELSE

          -- Crítica de dados do Cliente existentes
          IF (NVL(vrClienteDestino.vvAchouDadosCliente,'N') = 'N') THEN

            -- Rejeita Item
            vbAceitaItem    := FALSE;
            vMotivoRejeicao := '0002 - Não foram encontrados dados para o cliente ' || vrFilDestino.nCODCLI;

          ELSE

            -- Crítica de dados do RCA existentes
            IF (NVL(vrRca.vcAchouRCA,'N') = 'N') THEN

              -- Rejeita Item
              vbAceitaItem    := FALSE;
              vMotivoRejeicao := '0003 - Não foram encontrados dados do RCA ' || vrClienteDestino.nCODUSUR1 || ' do cliente ' || vrFilDestino.nCODCLI;

            ELSE

              -- Crítica de dados do Plano de Pagamento existentes
              IF (NVL(vrPlanoPag.vcAchouPlPag,'N') = 'N') THEN

                -- Rejeita Item
                vbAceitaItem    := FALSE;
                vMotivoRejeicao := '0004 - Não foram encontrados dados do plano de pagamento ' || vrClienteDestino.nCODPLPAG || ' do cliente ' || vrFilDestino.nCODCLI;

              ELSE

                -- Crítica de dados da Filial de Origem existentes
                IF (NVL(vrFilOrigem.vcAchouFilial,'N') = 'N') THEN

                  -- Rejeita Item
                  vbAceitaItem    := FALSE;
                  vMotivoRejeicao := '0005 - Não foram encontrados os dados da filial de origem ' || vc_Dados_Cab.CODFILIAL_O;

                ELSE

                  -- Crítica de dados da Praça existentes
                  IF (NVL(vrPracaCliDestino.vcAchouPraca,'N') = 'N') THEN

                    -- Rejeita Item
                    vbAceitaItem    := FALSE;
                    vMotivoRejeicao := '0006 - Não foram encontrados os dados da praça ' || vrClienteDestino.nCODPRACA;

                  ELSE

                    -- Crítica da Região
                    IF (NVL(vrPracaCliDestino.nNUMREGIAO,0) = 0) THEN

                      -- Rejeita Item
                      vbAceitaItem    := FALSE;
                      vMotivoRejeicao := '0007 - Região não informada na praça ' || vrClienteDestino.nCODPRACA;

                    END IF;

                  END IF;

                END IF;

              END IF; -- Fim Condição Crítica de dados do Plano de Pagamento existentes

            END IF; -- Fim Condição Crítica de dados do RCA existentes

          END IF; -- Fim Condição Crítica de dados do Cliente existentes

        END IF; -- Fim Condição Crítica de Código do Cliente existente

       /*------------------------------------------------
        Se aceitar o Item, Critica Valor Mínimo do Pedido
        ------------------------------------------------*/
        IF (vbAceitaItem) THEN
          -- Critica Valor Mínimo do Pedido
          IF (NOT bATINGIUVLMINPEDIDO) THEN
            -- Rejeita Item
            vbAceitaItem    := FALSE;
            vMotivoRejeicao := '0022 - Valor do Pedido: ' || NVL(nVLTOTALPEDIDOCOMPRA,0) ||
                               ' abaixo do Mínimo: '      || NVL(vrFornecDestino.nVLMINPEDREPOSICAO,0) ||
                               ' para o Fornecedor: '     || NVL(vrFornecDestino.nCODFORNEC,0);
          END IF; -- Critica Valor Mínimo do Pedido
        END IF;

       /****************************************************************************************************************
        SE PEDIDO DE TRANSFERENCIA OU PEDIDO OPERADOR LOGISTICO, PROCEDE AO CALCULO DO PREÇO, IMPOSTO, COMISSÃO, CMV ...
        ****************************************************************************************************************/
         /* vvMsgErroTratado := 'PRECO = ' ||vrItemPedido.nPTABELA || ' ; ' ||  vc_Dados_Cab.TIPO_SUG_COMPRA_TRANSF ||';'||vc_Dados_Cab.CODFILIAL_O||';'||vrFilOrigem.vvUfOrigem||'; DEST '||vrFilDestino.vvUfDestino;
                RAISE e_Tratado;*/
        IF (vc_Dados_Cab.TIPO_SUG_COMPRA_TRANSF IN ('T','L')) THEN

         /*-------------------------------------------
          Se aceitar o Item, Pesquisa dados do Produto
          -------------------------------------------*/
          IF (vbAceitaItem) THEN

            -- Inicializa Preço de Tabela e Venda e Desconto
            vrItemPedido.nPTABELA    := 0;
            vrItemPedido.nPVENDA     := 0;
            vrItemPedido.nPVENDABASE := 0;
            vrItemPedido.nPERDESC    := 0;
            vrItemPedido.nPVENDA1    := 0;

            -- Pesquisa Dados do Produto
            BEGIN
              SELECT PCPRODUT.PERCIPIVENDA
                   , PCPRODUT.PCOMINT1
                   , PCPRODUT.PCOMEXT1
                   , PCPRODUT.PCOMREP1
                   , PCPRODUT.CODLINHAPROD
                   , PCPRODUT.PESOBRUTO
                   , PCPRODUT.VOLUME
                   , PCPRODUT.TIPOCUSTOTRANSF
                INTO vrProduto_O.nPERCIPIVENDA
                   , vrProduto_O.nPCOMINT1
                   , vrProduto_O.nPCOMEXT1
                   , vrProduto_O.nPCOMREP1
                   , vrProduto_O.nCODLINHAPROD
                   , vrProduto_O.nPESOBRUTO
                   , vrProduto_O.nVOLUME
                   , vrProduto_O.vTIPOCUSTOTRANSF
                FROM PCPRODUT
               WHERE (PCPRODUT.CODPROD = vc_Dados_Ite.CODPROD_O);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- Rejeita Item
                vbAceitaItem                 := FALSE;
                vMotivoRejeicao              := '0008 - Não foram encontrados dados do produto ' || vc_Dados_Ite.CODPROD_O || vvInformacaoLoteFab;
                vrProduto_O.nPERCIPIVENDA    := 0;
                vrProduto_O.nPCOMINT1        := 0;
                vrProduto_O.nPCOMEXT1        := 0;
                vrProduto_O.nPCOMREP1        := 0;
                vrProduto_O.nCODLINHAPROD    := NULL;
                vrProduto_O.nPESOBRUTO       := 0;
                vrProduto_O.nVOLUME          := 0;
                vrProduto_O.vTIPOCUSTOTRANSF := NULL;
            END;

            -- Se encontrou dados do produto
            IF (vbAceitaItem) THEN

              -- Pesquisa Dados da PCEST para o Produto NA FILIAL DE ORIGEM
              BEGIN
                SELECT PCEST.CUSTOREP
                     , PCEST.CUSTOREAL
                     , PCEST.CUSTOCONT
                     , PCEST.CUSTOFIN
                     , PCEST.CUSTOULTENT
                     , PCEST.VALORULTENT
                     , PCEST.CUSTOREALSEMST
                     , PCEST.VLULTENTCONTSEMST
                     , PCEST.CUSTOFORNEC
                     , PCEST.CUSTOFINSEMST
                     , PCEST.VLICMSBCR
                  INTO vrCustoProduto_O.nCUSTOREP
                     , vrCustoProduto_O.nCUSTOREAL
                     , vrCustoProduto_O.nCUSTOCONT
                     , vrCustoProduto_O.nCUSTOFIN
                     , vrCustoProduto_O.nCUSTOULTENT
                     , vrCustoProduto_O.nVALORULTENT
                     , vrCustoProduto_O.nCUSTOREALSEMST
                     , vrCustoProduto_O.nVLULTENTCONTSEMST
                     , vrCustoProduto_O.nCUSTOFORNEC
                     , vrCustoProduto_O.nCUSTOFINSEMST
                     , vrCustoProduto_O.nVLICMSBCR
                  FROM PCEST
                 WHERE (PCEST.CODPROD   = vc_Dados_Ite.CODPROD_O)
                   AND (PCEST.CODFILIAL = NVL(vc_Dados_Cab.CODFILIALRETIRA_O,vc_Dados_Cab.CODFILIAL_O)); -->> Na Filial Retira (Se não tiver Na Filial de Origem)
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  vrCustoProduto_O.nCUSTOREP          := 0;
                  vrCustoProduto_O.nCUSTOREAL         := 0;
                  vrCustoProduto_O.nCUSTOCONT         := 0;
                  vrCustoProduto_O.nCUSTOFIN          := 0;
                  vrCustoProduto_O.nCUSTOULTENT       := 0;
                  vrCustoProduto_O.nVALORULTENT       := 0;
                  vrCustoProduto_O.nCUSTOREALSEMST    := 0;
                  vrCustoProduto_O.nVLULTENTCONTSEMST := 0;
                  vrCustoProduto_O.nCUSTOFORNEC       := 0;
                  vrCustoProduto_O.nCUSTOFINSEMST     := 0;
                  vrCustoProduto_O.nVLICMSBCR         := 0;
              END;

              -- Pesquisa Dados da Tabela de Preços do Produto
              BEGIN
                SELECT PCTABPR.PVENDA1
                     , PCTABPR.PVENDA2
                     , PCTABPR.PVENDA3
                     , PCTABPR.PVENDA4
                     , PCTABPR.PVENDA5
                     , PCTABPR.PVENDA6
                     , PCTABPR.PVENDA7
                     , PCTABPR.CODST
                     , PCTABPR.VLST
                  INTO vrTabPreco.nPVENDA1
                     , vrTabPreco.nPVENDA2
                     , vrTabPreco.nPVENDA3
                     , vrTabPreco.nPVENDA4
                     , vrTabPreco.nPVENDA5
                     , vrTabPreco.nPVENDA6
                     , vrTabPreco.nPVENDA7
                     , vrTabPreco.nCODST
                     , vrTabPreco.nVLST
                  FROM PCTABPR
                 WHERE (PCTABPR.CODPROD   = vc_Dados_Ite.CODPROD_O)
                   AND (PCTABPR.NUMREGIAO = vrPracaCliDestino.nNUMREGIAO);
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  -- Rejeita Item
                  vbAceitaItem        := FALSE;
                  vMotivoRejeicao     := '0009 - Não existe tabela de preco do produto ' || vc_Dados_Ite.CODPROD_O || vvInformacaoLoteFab || ' na região ' || vrPracaCliDestino.nNUMREGIAO;
                  vrTabPreco.nPVENDA1 := NULL;
                  vrTabPreco.nPVENDA2 := NULL;
                  vrTabPreco.nPVENDA3 := NULL;
                  vrTabPreco.nPVENDA4 := NULL;
                  vrTabPreco.nPVENDA5 := NULL;
                  vrTabPreco.nPVENDA6 := NULL;
                  vrTabPreco.nPVENDA7 := NULL;
                  vrTabPreco.nCODST   := NULL;
                  vrTabPreco.nVLST    := NULL;
              END;

              -- Se encontrou dados do Produto na Tabela de Preços
              IF (vbAceitaItem) THEN

                -- Inicializa o tipo de custo de transferencia que sera aplicado com valor informado no cliente
                V_TIPOCUSTOTRANSF_APLICAR := vrClienteDestino.vTIPOCUSTOTRANSF;
                -- Se tiver tratamento diferenciado de custo de transferencia entre CD's por produto
                IF ((pi_vTipoSugestao = 'C') AND
                    (NVL(vrProduto_O.vTIPOCUSTOTRANSF,' ') IN ('E','R','C','F','U','V','S','T','O','A'))) THEN
                  -- Sera aplicado o valor informado no produto
                  V_TIPOCUSTOTRANSF_APLICAR := vrProduto_O.vTIPOCUSTOTRANSF;
                END IF;

                -- Define o PTABELA da Tabela PCPEDI (Preço Bruto) conforme o Tipo de Custo da Transferência
                IF    (V_TIPOCUSTOTRANSF_APLICAR = 'E') THEN
                  vrItemPedido.nPTABELA := NVL(vrCustoProduto_O.nCUSTOREP,0);
                ELSIF (V_TIPOCUSTOTRANSF_APLICAR = 'R') THEN
                  IF (vDESCSTFORAUFTRANSF = 'S') AND (vrFilOrigem.vvUfOrigem   <>  vrFilDestino.vvUfDestino) THEN
                     vrItemPedido.nPTABELA := NVL(vrCustoProduto_O.nCUSTOREALSEMST,0) ;
                  ELSE
                     vrItemPedido.nPTABELA := NVL(vrCustoProduto_O.nCUSTOREAL,0);
                  END IF;
                ELSIF (V_TIPOCUSTOTRANSF_APLICAR = 'C') THEN

                     vrItemPedido.nPTABELA := NVL(vrCustoProduto_O.nCUSTOCONT,0);

                ELSIF (V_TIPOCUSTOTRANSF_APLICAR = 'F') THEN
                     IF vDESCSTFORAUFTRANSF = 'S' AND vrFilOrigem.vvUfOrigem  <>  vrFilDestino.vvUfDestino THEN
                       vrItemPedido.nPTABELA := NVL(vrCustoProduto_O.nCUSTOFINSEMST,0) ;
                      ELSE
                       vrItemPedido.nPTABELA := NVL(vrCustoProduto_O.nCUSTOFIN,0);
                      END IF;
                ELSIF (V_TIPOCUSTOTRANSF_APLICAR = 'U') THEN
                  vrItemPedido.nPTABELA := NVL(vrCustoProduto_O.nCUSTOULTENT,0);
                ELSIF (V_TIPOCUSTOTRANSF_APLICAR = 'V') THEN
                  vrItemPedido.nPTABELA := NVL(vrCustoProduto_O.nVALORULTENT,0);
                ELSIF (V_TIPOCUSTOTRANSF_APLICAR = 'S') THEN
                  vrItemPedido.nPTABELA := NVL(vrCustoProduto_O.nCUSTOREALSEMST,0);
                ELSIF (V_TIPOCUSTOTRANSF_APLICAR = 'T') THEN
                  vrItemPedido.nPTABELA := NVL(vrCustoProduto_O.nVLULTENTCONTSEMST,0);
                ELSIF (V_TIPOCUSTOTRANSF_APLICAR = 'O') THEN
                  vrItemPedido.nPTABELA := NVL(vrCustoProduto_O.nCUSTOFORNEC,0);
                ELSIF (V_TIPOCUSTOTRANSF_APLICAR = 'A') THEN
                  vrItemPedido.nPTABELA := FOBTEM_PRECO_ENTRADA(NVL(vc_Dados_Cab.CODFILIALRETIRA_O,vc_Dados_Cab.CODFILIAL_O), -->> Na Filial Retira (Se não tiver Na Filial de Origem)
                                                                vc_Dados_Ite.CODPROD_O,
                                                                vrCustoProduto_O.nCUSTOULTENT);
                END IF;


                -- Se utilizar Fator de Embalagem não pode arredondar o Preço aqui - DDVENDAS-37042
                IF (NVL(vnQtUnitEmbalagem,0) > 1) THEN
                  vbArredondaPreco := FALSE;
                ELSE
                  vbArredondaPreco := TRUE;
                END IF;

                -- Define o Arredondamento do PTABELA com base no Parâmetro de Número de Casas Decimais do Preço de Venda
                IF (vbArredondaPreco) THEN
                  vrItemPedido.nPTABELA := ROUND(vrItemPedido.nPTABELA, NVL(vrParamFilial.nCON_NUMCASASDECVENDA,0));
                END IF;

                -- Se não conseguiu formar o Preço de Venda a partir da PCEST
                IF (NVL(vrItemPedido.nPTABELA,0) <= 0) THEN

                  -- Define o PTABELA da Tabela PCPEDI (Preço Bruto) conforme a Tabela de Preços e o Número do Prazo do Plano de Pagamento
                  IF    (vrPlanoPag.nNUMPR = 1) THEN
                    vrItemPedido.nPTABELA := NVL(vrTabPreco.nPVENDA1,0);
                  ELSIF (vrPlanoPag.nNUMPR = 2) THEN
                    vrItemPedido.nPTABELA := NVL(vrTabPreco.nPVENDA2,0);
                  ELSIF (vrPlanoPag.nNUMPR = 3) THEN
                    vrItemPedido.nPTABELA := NVL(vrTabPreco.nPVENDA3,0);
                  ELSIF (vrPlanoPag.nNUMPR = 4) THEN
                    vrItemPedido.nPTABELA := NVL(vrTabPreco.nPVENDA4,0);
                  ELSIF (vrPlanoPag.nNUMPR = 5) THEN
                    vrItemPedido.nPTABELA := NVL(vrTabPreco.nPVENDA5,0);
                  ELSIF (vrPlanoPag.nNUMPR = 6) THEN
                    vrItemPedido.nPTABELA := NVL(vrTabPreco.nPVENDA6,0);
                  ELSIF (vrPlanoPag.nNUMPR = 7) THEN
                    vrItemPedido.nPTABELA := NVL(vrTabPreco.nPVENDA7,0);
                  END IF;

                END IF; -- Fim Condição Se não conseguiu formar o Preço de Venda a partir da PCEST

                -- Se conseguiu formar o Preço de Tabela
                IF (NVL(vrItemPedido.nPTABELA,0) > 0) THEN

                  /* DEFINE O PREÇO DE VENDA */

                  -- Guarda no PVENDA1 o Preço Inicial antes de qualquer alteração para auditoria
                  vrItemPedido.nPVENDA1 := vrItemPedido.nPTABELA;

                  ----------------------------------------------------
                  -- REGRA ESPECÍFICA - Aplicar Indice Transferência
                  ----------------------------------------------------
                  IF (vUSAREGRAAPLICARINDICETRANSF = 'S') THEN
                    -->> SOMENTE SE NÃO TIVER ACRÉSCIMO NA TRANSFERÊNCIA
                    IF (NVL(vrClienteDestino.nPERACRESTRANSF,0) = 0) THEN
                      IF (vbArredondaPreco) THEN
                        vrItemPedido.nPTABELA := ROUND((vrItemPedido.nPTABELA * vrParamFilial.nFIL_INDICECUSTOTRANSF), vrParamFilial.nCON_NUMCASASDECVENDA);
                      ELSE
                        -- DDVENDAS-37042
                        vrItemPedido.nPTABELA := (vrItemPedido.nPTABELA * vrParamFilial.nFIL_INDICECUSTOTRANSF);
                      END IF;
                      -- Tem que alterar a Tabela Temp pra mostrar na Tela o valor certo
                      UPDATE PCMED_TEMP_TRANSF_ATAC_VAR
                         SET PRECO_TRANSF_O = vrItemPedido.nPTABELA
                       WHERE (CODFILIAL_O      = vc_Dados_Cab.CODFILIAL_O)
                         AND (CODPROD_O        = vc_Dados_Ite.CODPROD_O)
                         AND (CODFILIAL_D      = vc_Dados_Cab.CODFILIAL_D)
                         AND (CODPROD_D        = vc_Dados_Ite.CODPROD_D)
                         AND (NVL(NUMLOTE,'X') = NVL(vrItemPedido.vNUMLOTE,'X'));
                    END IF;
                  END IF;

                  -- Agrega ao Preço Bruto o Percentual de Acréscimo da Transferência
                  IF (vbArredondaPreco) THEN
                    vrItemPedido.nPTABELA := ROUND((vrItemPedido.nPTABELA * (1 + (vrClienteDestino.nPERACRESTRANSF / 100))), vrParamFilial.nCON_NUMCASASDECVENDA);
                  -- DDVENDAS-37042
                  ELSE
                    vrItemPedido.nPTABELA := (vrItemPedido.nPTABELA * (1 + (vrClienteDestino.nPERACRESTRANSF / 100)));
                  END IF;
                  IF (NVL(vrClienteDestino.nPERACRESTRANSF,0) > 0) THEN
                    -- Tem que alterar a Tabela Temp pra mostrar na Tela o valor certo
                    UPDATE PCMED_TEMP_TRANSF_ATAC_VAR
                       SET PRECO_TRANSF_O = vrItemPedido.nPTABELA
                     WHERE (CODFILIAL_O      = vc_Dados_Cab.CODFILIAL_O)
                       AND (CODPROD_O        = vc_Dados_Ite.CODPROD_O)
                       AND (CODFILIAL_D      = vc_Dados_Cab.CODFILIAL_D)
                       AND (CODPROD_D        = vc_Dados_Ite.CODPROD_D)
                       AND (NVL(NUMLOTE,'X') = NVL(vrItemPedido.vNUMLOTE,'X'));
                  END IF;

                  -- Define o Preço de Venda a partir do Preço de Tabela
                  vrItemPedido.nPVENDA  := vrItemPedido.nPTABELA;

                  -- Define o Preço de Venda Base a partir do Preço de Tabela
                  vrItemPedido.nPVENDABASE  := vrItemPedido.nPTABELA;

                  /* PESQUISA TRIBUTAÃO DO PRODUTO */

                  -- Se utiliza Tributação por UF, pesquisa na Tabela de Tributação por UF o Código da Tributação
                  IF (NVL(vrPcConsum.vUSATRIBUTACAOPORUF,'N') = 'S') THEN
                    BEGIN
                      SELECT PCTABTRIB.CODST
                        INTO vrItemPedido.nCODST
                        FROM PCTABTRIB
                       WHERE (PCTABTRIB.CODPROD     = vc_Dados_Ite.CODPROD_O)
                         AND (PCTABTRIB.CODFILIALNF = vc_Dados_Cab.CODFILIAL_O)   -->> Tributação na Filial de Origem
                         AND (PCTABTRIB.UFDESTINO   = vrFilDestino.vvUfDestino);  -->> Para a UF da Filial de Destino
                    EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                        -- Rejeita Item
                        vbAceitaItem        := FALSE;
                        vMotivoRejeicao     := '0011 - Não foi encontrada a tributação do produto ' || vc_Dados_Ite.CODPROD_O || vvInformacaoLoteFab ||
                                               ' na filial de origem ' || vc_Dados_Cab.CODFILIAL_O  ||
                                               ' para a UF ' || vrFilDestino.vvUfDestino;
                        vrItemPedido.nCODST := NULL;
                    END;
                  -- Se NÃO utiliza Tributação por UF, utiliza o Código da Tributação da Tabela de Preços
                  ELSE
                    vrItemPedido.nCODST := vrTabPreco.nCODST;
                  END IF;

                  -- Se não ocorreram problemas ao pesquisar a Tributação do Produto
                  IF (vbAceitaItem) THEN

                    -- Crítica do valor do Código da Tributação
                    IF (NVL(vrItemPedido.nCODST,0) = 0) THEN

                      -- Rejeita Item
                      vbAceitaItem    := FALSE;
                      vMotivoRejeicao := '0012 - Produto produto ' || vc_Dados_Ite.CODPROD_O || vvInformacaoLoteFab || ' sem tributação na filial de origem ' || vc_Dados_Cab.CODFILIAL_O;

                    -- Se não tem existem Problemas no valor do Código da Tributação do Produto
                    ELSE

                     /*--------------------
                      Tributação do Produto
                      --------------------*/
                      -- Pesquisa Dados da Tributação do Produto
                      BEGIN
                        SELECT PCTRIBUT.PAUTA
                             , PCTRIBUT.IVA
                             , PCTRIBUT.ALIQICMS1
                             , PCTRIBUT.ALIQICMS2
                             , PCTRIBUT.PERCBASEREDST
                             , NVL(PCTRIBUT.TIPOCALCULOGNRETRANSF,NVL(PCTRIBUT.TIPOCALCULOGNRE,'P')) TIPOCALCULOGNRE
                             , PCTRIBUT.CODICMTABTRANSF
                             , PCTRIBUT.CODICMTABPF
                             , PCTRIBUT.PERDESCCUSTO
                             , PCTRIBUT.CODICMTABINTERNAC -- HIS.02786.2016
                             , PCTRIBUT.USAVLULTENTMEDIOBASEST
                          INTO vrTribut.nPAUTA
                             , vrTribut.nIVA
                             , vrTribut.nALIQICMS1
                             , vrTribut.nALIQICMS2
                             , vrTribut.nPERCBASEREDST
                             , vrTribut.vTIPOCALCULOGNRE
                             , vrTribut.nCODICMTABTRANSF
                             , vrTribut.nCODICMTABPF
                             , vrTribut.nPERDESCCUSTO
                             , vrTribut.nCODICMTABINTERNAC -- HIS.02786.2016
                             , vrTribut.vUSAVLULTENTMEDIOBASEST
                          FROM PCTRIBUT
                         WHERE (PCTRIBUT.CODST = vrItemPedido.nCODST);
                      EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                          -- Rejeita Item
                          vbAceitaItem                := FALSE;
                          vMotivoRejeicao             := '0013 - Não foram encontrados os dados da tributação '|| vrItemPedido.nCODST;
                          vrTribut.nPAUTA             := NULL;
                          vrTribut.nIVA               := NULL;
                          vrTribut.nALIQICMS1         := NULL;
                          vrTribut.nALIQICMS2         := NULL;
                          vrTribut.nPERCBASEREDST     := NULL;
                          vrTribut.vTIPOCALCULOGNRE   := NULL;
                          vrTribut.nCODICMTABTRANSF   := NULL;
                          vrTribut.nCODICMTABPF       := NULL;
                          vrTribut.nPERDESCCUSTO      := NULL;
                          vrTribut.nCODICMTABINTERNAC := NULL; -- HIS.02786.2016
                      END;
                      -- Define Isenção de IPI
                      vvIsentoIPI := NVL(vrClienteDestino.nISENTOIPI,'N');
                      IF    ((vrClienteDestino.vSULFRAMA IS NOT NULL) OR
                              (NVL(vrClienteDestino.vTIPOFJ,' ') = 'E')) THEN
                        vvIsentoIPI := 'S';
                      ELSIF (vrClienteDestino.vESTENT = 'EX') THEN
                        vvIsentoIPI := 'S';
                      END IF;

                    END IF; -- Fim Condição da Crítica do valor do Código da Tributação

                  END IF; -- Fim Condição Se não ocorreram problemas ao pesquisar a Tributação do Produto

                -- Se NÃO conseguiu formar o Preço de Tabela
                ELSE

                  -- Rejeita Item
                  vbAceitaItem    := FALSE;
                  vMotivoRejeicao := '0010 - Não foi encontrado o preço do produto ' || vc_Dados_Ite.CODPROD_O || vvInformacaoLoteFab || ' na filial de origem ' || vc_Dados_Cab.CODFILIAL_O;

                END IF; -- Fim Condição Se não conseguiu formar o Preço de Venda a partir da PCEST

              END IF; -- Fim Condição Se encontrou dados do produto

            END IF; -- Fim Condição Se encontrou dados do Produto na Tabela de Preços

          END IF; -- Fim Condição pesquisa dados do Produto

         /*----------------------------------------------------
          Se aceitar o Item, Critica Embalagem - DDVENDAS-38358
          ----------------------------------------------------*/
          IF (vbAceitaItem) THEN
            IF (NVL(vUSAQTUNITPCEMBREPLOJA,'N') = 'S') THEN

              IF (NVL(vc_Dados_Ite.CODAUXILIAR_O,0) = 0) THEN
                -- Rejeita Item
                vbAceitaItem    := FALSE;
                vMotivoRejeicao := '0025 - EAN não encontrado para o Produto: ' || NVL(vc_Dados_Ite.CODPROD_O,0);
              END IF; -- Critica Embalagem

            END IF;
          END IF;

         /*---------------------------------------------
          Se aceitar o Item, Calcula Impostos do Produto
          ---------------------------------------------*/
          IF (vbAceitaItem) THEN

            -- Inicializa Valor do ST
            vrItemPedido.nST                   := 0;
            -- Inicializa Percentual e Valor do IPI
            vrItemPedido.nPERCIPI              := 0;
            vrItemPedido.nVLIPI                := 0;
            -- Inicializa Composição do Imposto
            vrItemPedido.nIVA                  := 0;
            vrItemPedido.nPAUTA                := 0;
            vrItemPedido.nALIQICMS1            := 0;
            vrItemPedido.nALIQICMS2            := 0;
            vrItemPedido.nPERCBASEREDST        := 0;
            -- Inicializa ST Cliente GNRE
            vrItemPedido.nSTCLIENTEGNRE        := 0;
            -- Inicializa Custos do Item do Pedido
            vrItemPedido.nVLCUSTOCONT          := 0;
            vrItemPedido.nVLCUSTOREP           := 0;
            vrItemPedido.nVLCUSTOREAL          := 0;
            -- Inicializa Preço Máx. Consum
            vrItemPedido.nPRECOMAXCONSUM       := NULL;
            -- Inicializa Base ICST
            vrItemPedido.nBASEICST             := NULL;
            -- Inicializa Regime Especial Isenção ST Fonte
            vrItemPedido.nREGIMEESPISENSTFONTE := NULL;
            -- Inicializa Campos Relevância - HIS.03379.2017
            vrItemPedido.vINDESCALARELEVANTE   := NULL;
            vrItemPedido.vCNPJFABRICANTE       := NULL;
            vrItemPedido.vFABRICANTE           := NULL;
            -- Inicializa Campos de ST do FUNCEP
            vrItemPedido.nBASEFECP             := NULL;
            vrItemPedido.nALIQFECP             := NULL;
            vrItemPedido.nVLFECP               := NULL;
            -- Inicializa Observação ST Fonte - HIS.03379.2017
            vrItemPedido.vOBSERVACAOSTFONTE    := NULL;
            -- Inicializa Dados do FECP
            vrDadosFuncep                      := vrLimpaDadosFuncep;

           /*********************************************************************
            S T    F O N T E (HIS.03379.2017)
            *********************************/
            IF (NVL(vrParamFilial.vUTILIZACONTROLEMEDICAM,'N') = 'S') AND
               (NVL(vrClienteDestino.vCLIENTEFONTEST,'N')      = 'S') THEN

              -------------------
              -- Obtem PMC por UF
              -------------------
              BEGIN

                -- Parâmetros PMC
                vrParamPmc.pi_vCodFilial    := vc_Dados_Cab.CODFILIAL_O;
                vrParamPmc.pi_nCodProd      := vc_Dados_Ite.CODPROD_O;
                vrParamPmc.pi_vUfCliente    := vrClienteDestino.vESTENT;
                vrParamPmc.pi_nRegiao       := vrPracaCliDestino.nNUMREGIAO;
                vrParamPmc.po_nPmc          := NULL;
                vrParamPmc.po_nPrecoFabrica := NULL;
                vrParamPmc.po_vMensagem     := NULL;

                -- String para executar Bloco de Cálculo de ST Fonte
                vvBlocoExecucaoProcedure := 'BEGIN PRC_MED_OBTEM_PMC_PRODUTO(:pi_vCodFilial,:pi_nCodProd,:pi_vUfCliente,:pi_nRegiao,:po_nPmc,:po_nPrecoFabrica,:po_vMensagem); END;';

                -- Executa Bloco
                EXECUTE IMMEDIATE vvBlocoExecucaoProcedure
                  USING in vrParamPmc.pi_vCodFilial
                      , in vrParamPmc.pi_nCodProd
                      , in vrParamPmc.pi_vUfCliente
                      , in vrParamPmc.pi_nRegiao
                      , out vrParamPmc.po_nPmc
                      , out vrParamPmc.po_nPrecoFabrica
                      , out vrParamPmc.po_vMensagem;

                -- Pega Valores que serão utilizados neste procedimento
                vrItemPedido.nPRECOMAXCONSUM := vrParamPmc.po_nPmc;
                vnPrecoFabrica               := vrParamPmc.po_nPrecoFabrica;
                vvErrosPmc                   := vrParamPmc.po_vMensagem;

              EXCEPTION
                -- Se erro ao obter PMC
                WHEN OTHERS THEN
                  -- Rejeita Item
                  vbAceitaItem    := FALSE;
                  vMotivoRejeicao := '0014 - Erro ao executar procedure do PMC : ' || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM,1,2000);
              END;

              -------------------
              -- CALCULA ST FONTE
              -------------------
              BEGIN

                -- Parâmetros ST Fonte
                vrParamStFonte.pi_vCodFilial            := vc_Dados_Cab.CODFILIAL_O;
                vrParamStFonte.pi_nCodProd              := vc_Dados_Ite.CODPROD_O;
                vrParamStFonte.pi_nCodCli               := vrFilDestino.nCODCLI;
                vrParamStFonte.pi_nNumRegiao            := vrPracaCliDestino.nNUMREGIAO;
                vrParamStFonte.pi_nCondVenda            := vrPedido.nCONDVENDA;
                vrParamStFonte.pi_nPercVenda            := vrPedido.nPERCVENDA;
                vrParamStFonte.pio_nCodSt               := vrItemPedido.nCODST;
                vrParamStFonte.pi_vPVenda               := vrItemPedido.nPVENDA;
                vrParamStFonte.pi_nValorIpi             := 0;
                vrParamStFonte.pi_nPrecoMaxConsum       := vrItemPedido.nPRECOMAXCONSUM;
                vrParamStFonte.pi_nValorUltEnt          := NULL;
                vrParamStFonte.pi_nCustoNfSemSt         := NULL;
                vrParamStFonte.pi_nPTabela              := vrItemPedido.nPTABELA;
                vrParamStFonte.pi_vSomenteIVATribut     := 'N'; -->> Padrão Não (Simples Nacional)
                vrParamStFonte.pi_vPesquisarCustos      := 'N'; -->> Não Pesquisa Custos
                vrParamStFonte.pi_vItemBonific          := 'N'; -->> Não é Item Bonificado
                vrParamStFonte.pi_nVlFreteOutrasDesp    := 0;   -->> Não passa Frete e Outras Despesas
                vrParamStFonte.po_nBaseStFonte          := NULL;
                vrParamStFonte.po_nValorStFonte         := NULL;
                vrParamStFonte.po_vMensagem             := NULL;
                vrParamStFonte.po_vRegimeEspIsenStFonte := NULL;
                vrParamStFonte.po_nAliqIcms1            := NULL;
                vrParamStFonte.po_nAliqIcms2            := NULL;
                vrParamStFonte.po_nIva                  := NULL;
                vrParamStFonte.po_nPercBaseRedStFonte   := NULL;
                vrParamStFonte.pi_vTipoChamada          := 'O';   -->> Chamada = Outros
                vrParamStFonte.pi_nQt                   := 0;    -->> Não é preciso passar Qtde. para PEPS
                vrParamStFonte.pi_nNumPedido            := NULL; -->> Não é preciso passar Número do Pedido para PEPS
                vrParamStFonte.pi_nCodFilialNf          := vc_Dados_Cab.CODFILIAL_O;
                vrParamStFonte.po_nPautaFonte           := NULL;
                vrParamStFonte.po_vObservacaoStFonte    := NULL;
                vrParamStFonte.po_vIndEscalaRelevante   := NULL;
                vrParamStFonte.po_vCnpjFabricante       := NULL;
                vrParamStFonte.po_vFabricante           := NULL;
                vrParamStFonte.po_nVlBaseFcpIcms        := NULL;
                vrParamStFonte.po_nVlBaseFcpSt          := NULL;
                vrParamStFonte.po_nVlBcFcpstRet         := NULL;
                vrParamStFonte.po_nPerFcpStRet          := NULL;
                vrParamStFonte.po_nVlFcpStRet           := NULL;
                vrParamStFonte.po_nPerFcpSn             := NULL;
                vrParamStFonte.po_nVlFecp               := NULL;
                vrParamStFonte.po_nVlAcrescimoFuncep    := NULL;
                vrParamStFonte.po_nPerAcrescimoFuncep   := NULL;
                vrParamStFonte.po_nAliqIcmsFecp         := NULL;
                vrParamStFonte.po_nVlCredFcpIcmsSn      := NULL;
                vrParamStFonte.po_nCodConfigFuncepMed   := NULL;
                vrParamStFonte.pi_vOrdemCalculo         := 'F'; -->> Default Cálculo ST para a Frente
                vrParamStFonte.pi_vMemoriaCalculo       := 'N'; -->> Default sem Memória de Cálculo
                vrParamStFonte.pi_nValorNotaFiscal      := 0;   -->> Default sem Valor NF para Cálculo ST Reverso

                -- String para executar Bloco de Cálculo de ST Fonte
                vvBlocoExecucaoProcedure := 'BEGIN PKG_MEDICAMENTOS.P_OBTEM_STFONTE_40(:pi_vCodFilial,:pi_nCodProd,:pi_nCodCli,:pi_nNumRegiao,:pi_nCondVenda,:pi_nPercVenda,:pio_nCodSt,:pi_vPVenda,:pi_nValorIpi,:pi_nPrecoMaxConsum,:pi_nValorUltEnt,:pi_nCustoNfSemSt,:pi_nPTabela,:pi_vSomenteIVATribut,:pi_vPesquisarCustos,:pi_vItemBonific,:pi_nVlFreteOutrasDesp,:po_nBaseStFonte,:po_nValorStFonte,:po_vMensagem,:po_vRegimeEspIsenStFonte,:po_nAliqIcms1,:po_nAliqIcms2,:po_nIva,:po_nPercBaseRedStFonte,:pi_vTipoChamada,:pi_nQt,:pi_nNumPedido,:pi_nCodFilialNf,:po_nPautaFonte,:po_vObservacaoStFonte,:po_vIndEscalaRelevante,:po_vCnpjFabricante,:po_vFabricante,:po_nVlBaseFcpIcms,:po_nVlBaseFcpSt,:po_nVlBcFcpstRet,:po_nPerFcpStRet,:po_nVlFcpStRet,:po_nPerFcpSn,:po_nVlFecp,:po_nVlAcrescimoFuncep,:po_nPerAcrescimoFuncep,:po_nAliqIcmsFecp,:po_nVlCredFcpIcmsSn,:po_nCodConfigFuncepMed,:pi_vOrdemCalculo,:pi_vMemoriaCalculo,:pi_nValorNotaFiscal); END;';

                -- Executa Bloco
                EXECUTE IMMEDIATE vvBlocoExecucaoProcedure
                  USING in vrParamStFonte.pi_vCodFilial
                      , in vrParamStFonte.pi_nCodProd
                      , in vrParamStFonte.pi_nCodCli
                      , in vrParamStFonte.pi_nNumRegiao
                      , in vrParamStFonte.pi_nCondVenda
                      , in vrParamStFonte.pi_nPercVenda
                      , in out vrParamStFonte.pio_nCodSt
                      , in vrParamStFonte.pi_vPVenda
                      , in vrParamStFonte.pi_nValorIpi
                      , in vrParamStFonte.pi_nPrecoMaxConsum
                      , in vrParamStFonte.pi_nValorUltEnt
                      , in vrParamStFonte.pi_nCustoNfSemSt
                      , in vrParamStFonte.pi_nPTabela
                      , in vrParamStFonte.pi_vSomenteIVATribut
                      , in vrParamStFonte.pi_vPesquisarCustos
                      , in vrParamStFonte.pi_vItemBonific
                      , in vrParamStFonte.pi_nVlFreteOutrasDesp
                      , out vrParamStFonte.po_nBaseStFonte
                      , out vrParamStFonte.po_nValorStFonte
                      , out vrParamStFonte.po_vMensagem
                      , out vrParamStFonte.po_vRegimeEspIsenStFonte
                      , out vrParamStFonte.po_nAliqIcms1
                      , out vrParamStFonte.po_nAliqIcms2
                      , out vrParamStFonte.po_nIva
                      , out vrParamStFonte.po_nPercBaseRedStFonte
                      , in vrParamStFonte.pi_vTipoChamada
                      , in vrParamStFonte.pi_nQt
                      , in vrParamStFonte.pi_nNumPedido
                      , in vrParamStFonte.pi_nCodFilialNf
                      , out vrParamStFonte.po_nPautaFonte
                      , out vrParamStFonte.po_vObservacaoStFonte
                      , out vrParamStFonte.po_vIndEscalaRelevante
                      , out vrParamStFonte.po_vCnpjFabricante
                      , out vrParamStFonte.po_vFabricante
                      , out vrParamStFonte.po_nVlBaseFcpIcms
                      , out vrParamStFonte.po_nVlBaseFcpSt
                      , out vrParamStFonte.po_nVlBcFcpstRet
                      , out vrParamStFonte.po_nPerFcpStRet
                      , out vrParamStFonte.po_nVlFcpStRet
                      , out vrParamStFonte.po_nPerFcpSn
                      , out vrParamStFonte.po_nVlFecp
                      , out vrParamStFonte.po_nVlAcrescimoFuncep
                      , out vrParamStFonte.po_nPerAcrescimoFuncep
                      , out vrParamStFonte.po_nAliqIcmsFecp
                      , out vrParamStFonte.po_nVlCredFcpIcmsSn
                      , out vrParamStFonte.po_nCodConfigFuncepMed
                      , in vrParamStFonte.pi_vOrdemCalculo
                      , in vrParamStFonte.pi_vMemoriaCalculo
                      , in vrParamStFonte.pi_nValorNotaFiscal;

                -- Pega Valores que serão utilizados neste procedimento
                vrItemPedido.nCODST                := vrParamStFonte.pio_nCodSt;
                --
                vrItemPedido.nBASEICST             := vrParamStFonte.po_nBaseStFonte;
                vrItemPedido.nST                   := vrParamStFonte.po_nValorStFonte;
                vvErrosStFonte                     := vrParamStFonte.po_vMensagem;
                vrItemPedido.nREGIMEESPISENSTFONTE := vrParamStFonte.po_vRegimeEspIsenStFonte;
                vrItemPedido.nALIQICMS1            := vrParamStFonte.po_nAliqIcms1;
                vrItemPedido.nALIQICMS2            := vrParamStFonte.po_nAliqIcms2;
                vrItemPedido.nIVA                  := vrParamStFonte.po_nIva;
                vrItemPedido.nPERCBASEREDST        := vrParamStFonte.po_nPercBaseRedStFonte;
                --
                vrItemPedido.nPAUTA                := vrParamStFonte.po_nPautaFonte;
                vrItemPedido.vOBSERVACAOSTFONTE    := vrParamStFonte.po_vObservacaoStFonte;
                vrItemPedido.vINDESCALARELEVANTE   := vrParamStFonte.po_vIndEscalaRelevante;
                vrItemPedido.vCNPJFABRICANTE       := vrParamStFonte.po_vCnpjFabricante;
                vrItemPedido.vFABRICANTE           := vrParamStFonte.po_vFabricante;
                --
                vrDadosFuncep.nVLBASEFCPICMS       := vrParamStFonte.po_nVlBaseFcpIcms;
                vrDadosFuncep.nVLBASEFCPST         := vrParamStFonte.po_nVlBaseFcpSt;
                vrDadosFuncep.nVLBCFCPSTRET        := vrParamStFonte.po_nVlBcFcpstRet;
                vrDadosFuncep.nPERFCPSTRET         := vrParamStFonte.po_nPerFcpStRet;
                vrDadosFuncep.nVLFCPSTRET          := vrParamStFonte.po_nVlFcpStRet;
                vrDadosFuncep.nPERFCPSN            := vrParamStFonte.po_nPerFcpSn;
                vrDadosFuncep.nVLFECP              := vrParamStFonte.po_nVlFecp;
                vrDadosFuncep.nVLACRESCIMOFUNCEP   := vrParamStFonte.po_nVlAcrescimoFuncep;
                vrDadosFuncep.nPERACRESCIMOFUNCEP  := vrParamStFonte.po_nPerAcrescimoFuncep;
                vrDadosFuncep.nALIQICMSFECP        := vrParamStFonte.po_nAliqIcmsFecp;
                vrDadosFuncep.nVLCREDFCPICMSSN     := vrParamStFonte.po_nVlCredFcpIcmsSn;
                vrDadosFuncep.nCODCONFIGFUNCEPMED  := vrParamStFonte.po_nCodConfigFuncepMed;

                -- Se não calculou ST
                IF (vvErrosStFonte IS NOT NULL) THEN

                  -- Rejeita Item
                  vbAceitaItem    := FALSE;
                  vMotivoRejeicao := '0014 - Erro no Cálculo do ST Fonte do produto ' || vc_Dados_Ite.CODPROD_O || vvInformacaoLoteFab ||
                                     ' com Tributação ' || vrItemPedido.nCODST || ' : ' || vvErrosStFonte;

                -- Se calculou ST
                ELSE

                  -----------------------------------------------------------
                  -- Atualiza Variáveis Comuns ao FECP: Módulo Farma e Pacote
                  -- (Serão gravados em ambos os casos no Item do Pedido)
                  -----------------------------------------------------------
                  vrItemPedido.nBASEFECP := vrDadosFuncep.nVLBASEFCPST;
                  vrItemPedido.nALIQFECP := vrDadosFuncep.nALIQICMSFECP;
                  vrItemPedido.nVLFECP   := vrDadosFuncep.nVLFECP;

                  -- Se o tipo do cálculo de GNRE for por Cliente
                  -- o ST deverá ser retirado do preço e zerado
                  IF (vrTribut.vTIPOCALCULOGNRE = 'C') THEN

                    -- Log Cálculo
                    vrItemPedido.vOBSERVACAOSTFONTE := vrItemPedido.vOBSERVACAOSTFONTE || ';GNRE';

                    vrItemPedido.nSTCLIENTEGNRE := vrItemPedido.nST;
                    vrItemPedido.nST            := 0;    -->> ST Zerado
                    vrItemPedido.nBASEICST      := NULL; -->> Continuarei sem Gravar a Base se ST CLIENTE GNRE

                  END IF;

                 -- Soma o ST Fonte ao PTabela e PVenda (Idem o FECP)
                 vrItemPedido.nPVENDA  := ROUND((NVL(vrItemPedido.nPVENDA,0)  + NVL(vrItemPedido.nST,0) + NVL(vrItemPedido.nVLFECP,0)), NVL(vrParamFilial.nCON_NUMCASASDECVENDA,0));
                 vrItemPedido.nPTABELA := ROUND((NVL(vrItemPedido.nPTABELA,0) + NVL(vrItemPedido.nST,0) + NVL(vrItemPedido.nVLFECP,0)), NVL(vrParamFilial.nCON_NUMCASASDECVENDA,0));

               END IF;

            EXCEPTION
              -- Se erro no Cálculo do ST
              WHEN OTHERS THEN
                -- Rejeita Item
                vbAceitaItem    := FALSE;
                vMotivoRejeicao := '0014 - Erro ao executar procedure de cálculo do ST Fonte : ' || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM,1,2000);
            END;

           /*********************************************************************
            S T    P R E C I F I C A Ç Ã O
            ******************************/
            ELSE

              -- Log Cálculo
              vrItemPedido.vOBSERVACAOSTFONTE := 'Calc. ST Precificação sobre ' || vrItemPedido.nPTABELA || ' (Tipo Custo ' || V_TIPOCUSTOTRANSF_APLICAR || ')';

              -- DDVENDAS-37042 - Preço Tabela para Calcular ST conforme PCEMBALAGEM
              IF (NVL(vnQtUnitEmbalagem,0) > 1) THEN
                vnPrecoComImpostos    := ROUND((vrItemPedido.nPTABELA * vnQtUnitEmbalagem),NVL(vrParamFilial.nCON_NUMCASASDECVENDA,0));
                vnPrecoCusto          := ROUND((vrItemPedido.nPTABELA * vnQtUnitEmbalagem),NVL(vrParamFilial.nCON_NUMCASASDECVENDA,0));
                vnValorIpi            := (vrItemPedido.nVLIPI   * vnQtUnitEmbalagem);
                vnValorStPrecificacao := (vrTabPreco.nVLST      * vnQtUnitEmbalagem);
                -- Log Cálculo
                vrItemPedido.vOBSERVACAOSTFONTE := vrItemPedido.vOBSERVACAOSTFONTE || ' ; fatorEmb ' || vnQtUnitEmbalagem;
                vrItemPedido.vOBSERVACAOSTFONTE := vrItemPedido.vOBSERVACAOSTFONTE || ' ; Preço com Fator ' || vnPrecoComImpostos;
              ELSE
                vnPrecoComImpostos    := vrItemPedido.nPTABELA;
                vnPrecoCusto          := vrItemPedido.nPTABELA;
                vnValorIpi            := vrItemPedido.nVLIPI;
                vnValorStPrecificacao := vrTabPreco.nVLST;
              END IF;

              --------------------------------------------------------
              -- Procede ao Cálculo do IPI e ST usando Regra do Pacote
              --------------------------------------------------------

              -- Primeira vez que vai calcular o ST
              -- SE TRANSFERINDO PELO CUSTO
              IF (NVL(V_TIPOCUSTOTRANSF_APLICAR,' ') IN ('E','R','C','F','U','V','S','T','O','A')) THEN
                vvRETIRAIMPOSTO201 := 'N';
              -- SE TRANSFERINDO PELO PRECO DE VENDA
              ELSE
                vvRETIRAIMPOSTO201 := 'S';
              END IF;

              IF (NVL(vUSAQTUNITPCEMBREPLOJA,'N') = 'S') THEN
                vrItemPedido.nCODAUXILIAR := NVL(vc_Dados_Ite.CODAUXILIAR_O,0);
              ELSE
                vrItemPedido.nCODAUXILIAR := NULL;
              END IF;

              -- Calcula o ST
              vbCalculouST := FCALCULAR_ST(V_TIPOCUSTOTRANSF_APLICAR,
                                           vc_Dados_Cab.CODFILIAL_O,
                                           vc_Dados_Cab.CODFILIAL_O, -- Código Filial NF
                                           vc_Dados_Cab.CODFILIALRETIRA_O,
                                           vrFilDestino.nCODCLI,
                                           vrClienteDestino.nCODPLPAG,
                                           vc_Dados_Ite.CODPROD_O,
                                           vrItemPedido.nCODAUXILIAR,
                                           vrPedido.nCONDVENDA,
                                           vnPrecoComImpostos, -- DDVENDAS-37042
                                           vnValorStPrecificacao, -- DDVENDAS-37042
                                           vvMsgRetornoCalculoST,
                                           vrItemPedido.nST,
                                           vrItemPedido.nBASEICST,
                                           vnValorIpi, -- DDVENDAS-37042
                                           vrItemPedido.nBASEFECP,
                                           vrItemPedido.nALIQFECP,
                                           vrItemPedido.nVLFECP,
                                           vrItemPedido.vINDESCALARELEVANTE, -- HIS.03379.2017
                                           vrItemPedido.vCNPJFABRICANTE, -- HIS.03379.2017
                                           vrItemPedido.vFABRICANTE, -- HIS.03379.2017
                                           vnPrecoSemImposto, -- MED-1573
                                           vnPrecoCusto, -- DDVENDAS-37042
                                           vrItemPedido.vOBSERVACAOSTFONTE,
                                           vvRETIRAIMPOSTO201); -- DDVENDAS-37042

              vrItemPedido.nVLIPI  := NVL(vnValorIpi,0);

              -- Agrega o ICMS no Preço da Transferência (Módulo Vendas) (antes do cálculo de ST - DDMEDICA-2444)
              -- DDVENDAS-37042 - A 316 aplica após calcular o ST
              IF (NVL(vrParamFilial.vUTILIZACONTROLEMEDICAM,'N') <> 'S') THEN

                -- DDVENDAS-37042 - A 316 aplica o Acréscimo no Preço com ST
                IF (vbCalculouST) THEN

                  -- Inicializa os Preços a partir do Preço sem Imposto
                  vrItemPedido.nPVENDA  := NVL(vnPrecoSemImposto,0);
                  vrItemPedido.nPTABELA := NVL(vnPrecoSemImposto,0);

                  -- Acrescenta o ST e IPI no Preço de Venda e no Preço de Tabela sem Imposto
                  vrItemPedido.nPVENDA  := (NVL(vrItemPedido.nPVENDA,0)  + NVL(vrItemPedido.nST,0) + NVL(vrItemPedido.nVLFECP,0) + NVL(vnValorIpi,0)); -->> DDVENDAS-37042 - Aqui não arredonda para ficar igual à 316
                  vrItemPedido.nPTABELA := (NVL(vrItemPedido.nPTABELA,0) + NVL(vrItemPedido.nST,0) + NVL(vrItemPedido.nVLFECP,0) + NVL(vnValorIpi,0));

                ELSE

                  -- Log Cálculo - DDVENDAS-37042
                  vrItemPedido.vOBSERVACAOSTFONTE := vrItemPedido.vOBSERVACAOSTFONTE || ' ; semStParaAcrIcms';

                END IF;

                -- Log Cálculo - DDVENDAS-37042
                vrItemPedido.vOBSERVACAOSTFONTE := vrItemPedido.vOBSERVACAOSTFONTE || ' ; stAplicarAcrIcms '    || vrItemPedido.nST;
                vrItemPedido.vOBSERVACAOSTFONTE := vrItemPedido.vOBSERVACAOSTFONTE || ' ; precoAplicarAcrIcms ' || vrItemPedido.nPTABELA;

                vrItemPedido.nPTABELA := FCALCULARPRECOVENDATRANSF(vrItemPedido.nPTABELA,
                                                                   vrItemPedido.nCODST,
                                                                   vrFilOrigem.vvCgcFilial,
                                                                   vrClienteDestino.vvCgcClienteDestino);
                vrItemPedido.nPTABELA := vrItemPedido.nPTABELA; -->> Arredonda conforme Casas Decimais
                vrItemPedido.nPVENDA  := vrItemPedido.nPTABELA; -->> Preço de Venda será igual ao novo Preço de Tabela

                -- Log Cálculo - DDVENDAS-37042
                vrItemPedido.vOBSERVACAOSTFONTE := vrItemPedido.vOBSERVACAOSTFONTE || ' ; precoAplicadoAcrIcms ' || vrItemPedido.nPTABELA;

                -- DDVENDAS-37042 - Calcula o ST novamente baseado no Preço com o Acréscimo
                vbCalculouST := FCALCULAR_ST(V_TIPOCUSTOTRANSF_APLICAR,
                                             vc_Dados_Cab.CODFILIAL_O,
                                             vc_Dados_Cab.CODFILIAL_O, -- Código Filial NF
                                             vc_Dados_Cab.CODFILIALRETIRA_O,
                                             vrFilDestino.nCODCLI,
                                             vrClienteDestino.nCODPLPAG,
                                             vc_Dados_Ite.CODPROD_O,
                                             vrItemPedido.nCODAUXILIAR,
                                             vrPedido.nCONDVENDA,
                                             vrItemPedido.nPTABELA,
                                             vnValorStPrecificacao, -- DDVENDAS-37042
                                             vvMsgRetornoCalculoST,
                                             vrItemPedido.nST,
                                             vrItemPedido.nBASEICST,
                                             vnValorIpi,
                                             vrItemPedido.nBASEFECP,
                                             vrItemPedido.nALIQFECP,
                                             vrItemPedido.nVLFECP,
                                             vrItemPedido.vINDESCALARELEVANTE, -- HIS.03379.2017
                                             vrItemPedido.vCNPJFABRICANTE, -- HIS.03379.2017
                                             vrItemPedido.vFABRICANTE, -- HIS.03379.2017
                                             vnPrecoSemImposto, -- MED-1573
                                             0, -- AQUI NÃO PASSA O CUSTO, PARA CALCULAR O IMPOSTO SOBRE O PREÇO FINAL - DDVENDAS-37042
                                             vrItemPedido.vOBSERVACAOSTFONTE, -- DDVENDAS-37042
                                             'N'); -- A partir da segunda vez que calcula o imposto, pi_vRETIRAIMPOSTO201 deverá ser NÃO

              END IF;

              -- Se não calculou ST
              IF (NOT vbCalculouST) THEN

                -- Rejeita Item
                vbAceitaItem        := FALSE;
                vMotivoRejeicao     := '0014 - Erro no Cálculo do ST do produto ' || vc_Dados_Ite.CODPROD_O || vvInformacaoLoteFab ||
                                       ' com Tributação ' || vrItemPedido.nCODST || ' : ' || vvMsgRetornoCalculoST;

              -- Se calculou ST sem problemas
              ELSE

                -- Log Cálculo - DDVENDAS-37042
                vrItemPedido.vOBSERVACAOSTFONTE := vrItemPedido.vOBSERVACAOSTFONTE || ' ; PrecoSemImposto ' || vnPrecoSemImposto;
                vrItemPedido.vOBSERVACAOSTFONTE := vrItemPedido.vOBSERVACAOSTFONTE || ' ; St '              || vrItemPedido.nST;

                -- Inicializa os Preços a partir do Preço sem Imposto - MED-1573
                vrItemPedido.nPVENDA  := NVL(vnPrecoSemImposto,0);
                vrItemPedido.nPTABELA := NVL(vnPrecoSemImposto,0);

                -- Percentual de IPI
                IF (NVL(vnValorIpi,0) <> 0) THEN
                  vrItemPedido.nPERCIPI := NVL(vrProduto_O.nPERCIPIVENDA,0);
                END IF;

                -- Acrescenta o IPI no Preço de Venda e no Preço de Tabela
                -- Usando Preço sem Imposto pode somar - MED-1573
                vrItemPedido.nPVENDA  := ROUND((NVL(vrItemPedido.nPVENDA,0)  + NVL(vnValorIpi,0)), NVL(vrParamFilial.nCON_NUMCASASDECVENDA,0));
                vrItemPedido.nPTABELA := ROUND((NVL(vrItemPedido.nPTABELA,0) + NVL(vnValorIpi,0)), NVL(vrParamFilial.nCON_NUMCASASDECVENDA,0));

                -- Se o tipo do cálculo de GNRE for por Cliente
                -- o ST deverá ser retirado do preço e zerado
                IF (NVL(vrTribut.vTIPOCALCULOGNRE,' ') = 'C') THEN

                  vrItemPedido.nSTCLIENTEGNRE := NVL(vrItemPedido.nST,0); -->> Aqui difere dos demais, gravará no ST Cliente GNRE

                  -- Não tem ST Normal
                  vrItemPedido.nST            := 0;
                  vrItemPedido.nBASEICST      := NULL; -->> Continuarei sem Gravar a Base se ST CLIENTE GNRE

                  -- Soma ST FCP ao Preço de Venda e Preço de Tabela conforme parametrização
                  -- Usando Preço sem Imposto pode somar - MED-1573
                  vrItemPedido.nPVENDA        := ROUND((NVL(vrItemPedido.nPVENDA,0)  + NVL(vrItemPedido.nVLFECP,0)), NVL(vrParamFilial.nCON_NUMCASASDECVENDA,0));
                  vrItemPedido.nPTABELA       := ROUND((NVL(vrItemPedido.nPTABELA,0) + NVL(vrItemPedido.nVLFECP,0)), NVL(vrParamFilial.nCON_NUMCASASDECVENDA,0));

                ELSE

                  -- Não tem ST GNRE
                  vrItemPedido.nSTCLIENTEGNRE := NULL;

                  -- Soma ST ao Preço de Venda e Preço de Tabela conforme parametrização
                  -- Usando Preço sem Imposto pode somar - MED-1573
                  vrItemPedido.nPVENDA        := ROUND((NVL(vrItemPedido.nPVENDA,0)  + NVL(vrItemPedido.nST,0) + NVL(vrItemPedido.nVLFECP,0)), NVL(vrParamFilial.nCON_NUMCASASDECVENDA,0));
                  vrItemPedido.nPTABELA       := ROUND((NVL(vrItemPedido.nPTABELA,0) + NVL(vrItemPedido.nST,0) + NVL(vrItemPedido.nVLFECP,0)), NVL(vrParamFilial.nCON_NUMCASASDECVENDA,0));

                END IF;

                -- Guarda Composição do Imposto que será gravado nos Itens do Pedido
                vrItemPedido.nIVA           := vrTribut.nIVA;
                vrItemPedido.nPAUTA         := vrTribut.nPAUTA;
                vrItemPedido.nALIQICMS1     := vrTribut.nALIQICMS1;
                vrItemPedido.nALIQICMS2     := vrTribut.nALIQICMS2;
                vrItemPedido.nPERCBASEREDST := vrTribut.nPERCBASEREDST;

                -- DDVENDAS-37042
                IF (NVL(vnQtUnitEmbalagem,0) > 1) THEN

                  vrItemPedido.vOBSERVACAOSTFONTE := vrItemPedido.vOBSERVACAOSTFONTE || ' ; pVenda '   || vrItemPedido.nPVENDA;
                  vrItemPedido.vOBSERVACAOSTFONTE := vrItemPedido.vOBSERVACAOSTFONTE || ' ; baseIcst ' || vrItemPedido.nBASEICST;
                  vrItemPedido.vOBSERVACAOSTFONTE := vrItemPedido.vOBSERVACAOSTFONTE || ' ; nSt '      || vrItemPedido.nST;

                  vrItemPedido.nPVENDA   := ROUND(NVL(vrItemPedido.nPVENDA,0)  / NVL(vnQtUnitEmbalagem,0), NVL(vrParamFilial.nCON_NUMCASASDECVENDA,0));
                  vrItemPedido.nPTABELA  := ROUND(NVL(vrItemPedido.nPTABELA,0) / NVL(vnQtUnitEmbalagem,0), NVL(vrParamFilial.nCON_NUMCASASDECVENDA,0));
                  vrItemPedido.nBASEICST := NVL(vrItemPedido.nBASEICST,0)      / NVL(vnQtUnitEmbalagem,0);
                  vrItemPedido.nST       := NVL(vrItemPedido.nST,0)            / NVL(vnQtUnitEmbalagem,0);
                  vrItemPedido.nBASEFECP := NVL(vrItemPedido.nBASEFECP,0)      / NVL(vnQtUnitEmbalagem,0);
                  vrItemPedido.nVLFECP   := NVL(vrItemPedido.nVLFECP,0)        / NVL(vnQtUnitEmbalagem,0);

                  vrItemPedido.vOBSERVACAOSTFONTE := vrItemPedido.vOBSERVACAOSTFONTE || ' ; pVendaSemFator '   || vrItemPedido.nPVENDA;
                  vrItemPedido.vOBSERVACAOSTFONTE := vrItemPedido.vOBSERVACAOSTFONTE || ' ; baseIcstSemFator ' || vrItemPedido.nBASEICST;
                  vrItemPedido.vOBSERVACAOSTFONTE := vrItemPedido.vOBSERVACAOSTFONTE || ' ; nStSemFator '      || vrItemPedido.nST;

                END IF;

                -- Atualiza Preço do Resultado do Processamento
                UPDATE PCMED_TEMP_TRANSF_ATAC_VAR
                   SET PRECO_TRANSF_O = NVL(vrItemPedido.nPVENDA,0)
                 WHERE (PCMED_TEMP_TRANSF_ATAC_VAR.CODFILIAL_O                 = vc_Dados_Cab.CODFILIAL_O)
                   AND (PCMED_TEMP_TRANSF_ATAC_VAR.CODFILIALRETIRA_O           = vc_Dados_Cab.CODFILIALRETIRA_O)
                   AND (PCMED_TEMP_TRANSF_ATAC_VAR.CODFILIAL_D                 = vc_Dados_Cab.CODFILIAL_D)
                   AND (PCMED_TEMP_TRANSF_ATAC_VAR.CODFORNECPRIORIDADE         = vc_Dados_Cab.CODFORNECPRIORIDADE)
                   AND (PCMED_TEMP_TRANSF_ATAC_VAR.TIPO_SUG_COMPRA_TRANSF      = vc_Dados_Cab.TIPO_SUG_COMPRA_TRANSF)
                   AND (PCMED_TEMP_TRANSF_ATAC_VAR.QUEBRA1                     = vc_Dados_Cab.QUEBRA1)
                   AND (PCMED_TEMP_TRANSF_ATAC_VAR.QUEBRA2                     = vc_Dados_Cab.QUEBRA2)
                   AND (PCMED_TEMP_TRANSF_ATAC_VAR.QUEBRA3                     = vc_Dados_Cab.QUEBRA3)
                   AND (PCMED_TEMP_TRANSF_ATAC_VAR.QUEBRA4                     = vc_Dados_Cab.QUEBRA4)
                   AND (NVL(PCMED_TEMP_TRANSF_ATAC_VAR.INTEGRADORA,0)          = NVL(vc_Dados_Cab.INTEGRADORA,0))
                   AND (NVL(PCMED_TEMP_TRANSF_ATAC_VAR.INTEGRADORAESPELHONF,0) = NVL(vc_Dados_Cab.INTEGRADORAESPELHONF,0))
                   AND (PCMED_TEMP_TRANSF_ATAC_VAR.CODPROD_O                   = vc_Dados_Ite.CODPROD_O)
                   AND (PCMED_TEMP_TRANSF_ATAC_VAR.CODPROD_D                   = vc_Dados_Ite.CODPROD_D);

              END IF; -- Fim Condição Calculou ST sem Problemas

            END IF; -- Fim Condição: Se ST Fonte Farma Hospitalar ou ST da Precificação Pacote

          END IF; -- Fim Condição Calcula Impostos do Produto -- IF (vbAceitaItem) THEN

          -- Rejeita Item se ST igual ou superior ao PVENDA - 4056.122709.2017
          IF (NVL(vrItemPedido.nST,0) >= NVL(vrItemPedido.nPVENDA,0)) THEN
            vbAceitaItem     := FALSE;
            vMotivoRejeicao  := '0016 - Erro de ST superior ao Preço de Venda '       || ' , ST :  '     || NVL(vrItemPedido.nST,0) ||
                                ' , Preço de Venda : ' || NVL(vrItemPedido.nPVENDA,0) || ' , Produto : ' ||  vc_Dados_Ite.CODPROD_O || vvInformacaoLoteFab ||
                                ' com Tributação '     || vrItemPedido.nCODST         || '. Verifique a Precificação.';
          END IF;

          -- Rejeita Item se não tiver quantidade sugerida
          IF (NVL(vc_Dados_Ite.QTD_TRANSFERIR_O,0) = 0) THEN -- DDMEDICA-3571
            vbAceitaItem        := FALSE;
            vMotivoRejeicao     :=  '0016 - Produto ' || vc_Dados_Ite.CODPROD_O || vvInformacaoLoteFab || ' sem quantidade sugerida. Verifique as regras de arredondamento de embalagem master.';
          END IF;

         /*-------------------------------------------------
          Se não ocorreram problemas no Cálculo dos Impostos
          -------------------------------------------------*/
          IF (vbAceitaItem) THEN

            ---------------------------------
            -- Procede ao Cálculo da Comissão
            ---------------------------------
            IF ((NVL(vIGNORARCALCULOCOMISSREPLOJA,'N') = 'S') AND (NVL(vrFilDestino.vvTipoFilial,'1') = '2')) OR
               ((NVL(vIGNORARCALCULOCOMISSREPCD,'N')   = 'S') AND (NVL(vrFilDestino.vvTipoFilial,'1') = '1')) THEN

              -- DDMEDICA-4845 - Ignora Comissão
              vrItemPedido.nPERCOM := 0;

            ELSE

              -- Comissão por Produto - Vendedor Interno
              IF    (NVL(vrRca.vTIPOVEND,' ') = 'I') THEN
                vrItemPedido.nPERCOM := NVL(vrProduto_O.nPCOMINT1,0);
              -- Comissão por Produto - Vendedor Externo
              ELSIF (NVL(vrRca.vTIPOVEND,' ') = 'E') THEN
                vrItemPedido.nPERCOM := NVL(vrProduto_O.nPCOMEXT1,0);
              -- Comissão por Produto - Representante
              ELSIF (NVL(vrRca.vTIPOVEND,' ') = 'R') THEN
                vrItemPedido.nPERCOM := NVL(vrProduto_O.nPCOMREP1,0);
              ELSE
                vrItemPedido.nPERCOM := 0;
              END IF;

              -- Comissão Por Cliente
              IF (vrPcConsum.vUSACOMISSAOPORCLIENTE = 'S') THEN
                IF (vrClienteDestino.nPERCOMCLI IS NOT NULL) THEN
                  vrItemPedido.nPERCOM := NVL(vrClienteDestino.nPERCOMCLI,0);
                END IF;
              END IF;

              -- Comissão por RCA
              IF (vrPcConsum.vUSACOMISSAOPORRCA = 'S') then
                IF (vrRca.nPERCENT2 IS NOT NULL) THEN
                  vrItemPedido.nPERCOM := NVL(vrRca.nPERCENT2,0);
                END IF;
              END IF;

              -- Comissão por Linha de Produto
              IF (vrPcConsum.vUSACOMISSAOPORLINHAPROD = 'S') THEN
                BEGIN
                  SELECT NVL(PCPLPAGI.PERCCOMISS,0) PERCCOMISS
                    INTO vrItemPedido.nPERCOM
                    FROM PCPLPAGI
                   WHERE (PCPLPAGI.CODPLPAG     = vrClienteDestino.nCODPLPAG)
                     AND (PCPLPAGI.CODLINHAPROD = vrProduto_O.nCODLINHAPROD);
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    NULL; -->> Se não achar a Comissão por Linha de Produto, não altera o Percentual de Comissão
                END;
              END IF;

            END IF; -- Fim Condição não Ignora Comissão

            ----------------------------
            -- Procede ao Cálculo do CMV
            ----------------------------

            -- Atualiza os custos do Item do Pedido
            vrItemPedido.nVLCUSTOCONT := NVL(vrCustoProduto_O.nCUSTOCONT,0);
            vrItemPedido.nVLCUSTOREP  := NVL(vrCustoProduto_O.nCUSTOREP,0);

            -- Inicializa CodIcmTab
            vnCodIcmTab := NVL(vrTribut.nCODICMTABTRANSF,0);

            -- Redefine CodIcmTab conforme Parametrização
            -- A partir da DDMEDICA-4968 assume exclusivamente o % Importos da Transferência por ser TV10
            /*
            IF (NVL(vrClienteDestino.vTIPOEMPRESA,' ') = 'NRPA') THEN
              vnCodIcmTab :=  NVL(vrTribut.nCODICMTAB,0);
            ELSE
              IF ((vrClienteDestino.vTIPOFJ = 'F') AND
                  (vrClienteDestino.vUTILIZAIESIMPLIFICADA = 'N') AND
                  ((vrClienteDestino.vIEENT = 'ISENTO') OR (vrClienteDestino.vIEENT = 'ISENTA')) AND
                  (vrTribut.nCODICMTABPF IS NOT NULL)) THEN
                 vnCodIcmTab := vrTribut.nCODICMTABPF;
              END IF;
            END IF;
            */

            -- Se Utiliza PEPS para Nacional e Importado - ICMS - HIS.02786.2016
           /*
            IF (vrParamFilial.vTRIBUTSAIDAORIGEMNACIMP = 'S') THEN
              FUNCOES_MED.OBTER_DADOS_PEPS_ICMS(vc_Dados_Ite.CODPROD_O,
                                                vc_Dados_Cab.CODFILIAL_O,
                                                vc_Dados_Ite.QTD_TRANSFERIR_O,
                                                TRUNC(SYSDATE), -->> Data atual será a Data da Transferência
                                                vrItemPedido.vPRODIMPORTADOPEPS,
                                                vrItemPedido.nNUMTRANSENTPEPS,
                                                vvMsgErroObterPepsIcms);
              IF (vrItemPedido.vPRODIMPORTADOPEPS = 'S') THEN
                vnCodIcmTab := nvl(vrTribut.nCODICMTABINTERNAC, 0);
              END IF;
            END IF;
            */

            -- Calcula o Custo Real do Item do Pedido
            vrItemPedido.nVLCUSTOREAL :=
              (NVL(vrCustoProduto_O.nCUSTOREAL,0) -
                (NVL(vrCustoProduto_O.nCUSTOREAL,0) * NVL(vrTribut.nPERDESCCUSTO,0) / 100) +
                (NVL(vrItemPedido.nPVENDA,0) * NVL(vrPcConsum.nTXVENDA,0) / 100) +
                (NVL(vrItemPedido.nPVENDA,0) * NVL(vrItemPedido.nPERCOM,0) / 100) +
                ((NVL(vrItemPedido.nPVENDA,0) - NVL(vrItemPedido.nST,0) - NVL(vrItemPedido.nVLIPI,0)) * NVL(vnCodIcmTab,0) / 100)
                + NVL(vrItemPedido.nST,0)
                + NVL(vrItemPedido.nVLIPI,0));

            -- Calcula o Custo Financeiro do Item do Pedido
            vrItemPedido.nVLCUSTOFIN :=
              (NVL(vrCustoProduto_O.nCUSTOFIN,0) -
                (NVL(vrCustoProduto_O.nCUSTOFIN,0) * NVL(vrTribut.nPERDESCCUSTO,0) / 100) +
                (NVL(vrItemPedido.nPVENDA,0) * NVL(vrPcConsum.nTXVENDA,0) / 100) +
                (NVL(vrItemPedido.nPVENDA,0) * NVL(vrItemPedido.nPERCOM,0) / 100) +
                ((NVL(vrItemPedido.nPVENDA,0) - NVL(vrItemPedido.nST,0) - NVL(vrItemPedido.nVLIPI,0)) * NVL(vnCodIcmTab,0) / 100)
                + NVL(vrItemPedido.nST,0)
                + NVL(vrItemPedido.nVLIPI,0));

            -- Guarda os encargos de impostos para gravação na PCPEDI - HIS.02786.2016
            vrItemPedido.nCODICMTAB := NVL(vnCodIcmTab,0);

            -- Calcula o Percentual de Desconto
            IF (NVL(vrItemPedido.nPTABELA,0) <> 0) then
              vrItemPedido.nPERDESC := (((NVL(vrItemPedido.nPTABELA,0) -
                NVL(vrItemPedido.nPVENDA,0)) /
                NVL(vrItemPedido.nPTABELA,0)) * 100);
            END IF;

            -- Valor do Desconto no Custo Financeiro
            vrItemPedido.nVLDESCCUSTOCMV := (ROUND(((NVL(vrCustoProduto_O.nCUSTOFIN,0) * NVL(vrTribut.nPERDESCCUSTO,0) / 100) * 100))) / 100;

          END IF; -- Fim Condição Se não ocorreram problemas no Cálculo dos Impostos

         /*---------------------------------------------------
          Após o Cálculo dos Impostos Critica o Preço de Venda
          ---------------------------------------------------*/
          IF (vbAceitaItem) THEN
            IF (NVL(vrItemPedido.nPVENDA,0) <= 0) THEN

              -- Rejeita Item
              vbAceitaItem        := FALSE;
              vMotivoRejeicao     := '0020 - Produto ' || vc_Dados_Ite.CODPROD_O || vvInformacaoLoteFab || ' sem PVENDA após o cálculo dos impostos';

            END IF;
          END IF;

       /******************************************************************
        SE SUGESTAO DE COMPRA, SOMENTE CRITICA O PREÇO DO PEDIDO DE COMPRA
        ******************************************************************/
        ELSIF (vc_Dados_Cab.TIPO_SUG_COMPRA_TRANSF = 'C') THEN

          IF (vbAceitaItem) THEN
            IF (NVL(vc_Dados_Ite.PRECO_TRANSF_O,0) <= 0) THEN

              -- Rejeita Item
              vbAceitaItem        := FALSE;
              vMotivoRejeicao     := '0021 - Produto ' || vc_Dados_Ite.CODPROD_O || vvInformacaoLoteFab || ' sem Preço Negociado no Fornecedor ' || vc_Dados_Cab.CODFORNECPRIORIDADE;

            END IF;
          END IF;

        END IF;

       /*----------------------------------------------------
        Se não ocorreram erros no Cálculo da Comissão e Custo
        ----------------------------------------------------*/
        IF (vbAceitaItem) THEN

          -----------------------------------------------------
          -- Se Gera Pedido de Estoque Avariado - DDMEDICA-5077
          -----------------------------------------------------
          IF    (nvl(pi_vPedidoAvaria,'N') = 'S') THEN

            -- Inicia a Sugestão na sua Totalidade
            vrItemPedido.nQTDETRANSFERIR := NVL(vc_Dados_Ite.QTD_TRANSFERIR_O,0);

            -- Atribui Lote se Controlar Estoque por Lote
            IF (NVL(vc_Dados_Ite.ESTOQUEPORLOTE,'N') = 'S') THEN

              vrItemPedido.vNUMLOTE := vc_Dados_Ite.NUMLOTE;

              -- Obtém Estoque por Lote Disponível Avariado
              BEGIN
                SELECT QTINDENIZ
                  INTO vnQtIndenizLoteDisponivel
                  FROM PCLOTE
                 WHERE (CODFILIAL = vc_Dados_Cab.CODFILIAL_O) -->> Sem Filial Retira
                   AND (CODPROD   = vc_Dados_Ite.CODPROD_O)
                   AND (NUMLOTE   = vc_Dados_Ite.NUMLOTE);
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  vnQtIndenizLoteDisponivel := 0;
              END;

              -- SOMA O QUE ESTIVER EM PREFAT PARA O LOTE
              SELECT SUM(QT)
                INTO vnTotalAvariaPrefat
                FROM PCMOVPREFAT
                   , PCPEDC
               WHERE (PCMOVPREFAT.CODFILIAL = vc_Dados_Cab.CODFILIAL_O) -->> Sem Filial Retira
                 AND (PCMOVPREFAT.CODPROD   = vc_Dados_Ite.CODPROD_O)
                 AND (PCMOVPREFAT.NUMLOTE   = vc_Dados_Ite.NUMLOTE)
                 AND (PCMOVPREFAT.NUMPED    = PCPEDC.NUMPED)
                 AND (PCPEDC.PEDIDOAVARIA   = 'S');
              IF (vnTotalAvariaPrefat > 0) THEN
                vnQtIndenizLoteDisponivel := vnQtIndenizLoteDisponivel - NVL(vnTotalAvariaPrefat,0);
                IF (vnQtIndenizLoteDisponivel < 0) THEN
                  vnQtIndenizLoteDisponivel := 0;
                END IF;
              END IF;

              -- Se não tiver estoque suficiente
              IF (NVL(vrItemPedido.nQTDETRANSFERIR,0) > NVL(vnQtIndenizLoteDisponivel,0)) THEN

                -- Altera a Quantidade a Transferir
                vrItemPedido.nQTDETRANSFERIR := NVL(vnQtIndenizLoteDisponivel,0);

                -- Rejeita Item
                IF (NVL(vrItemPedido.nQTDETRANSFERIR,0) <= 0) THEN
                  vbAceitaItem := FALSE;
                  vMotivoRejeicao := '0018 - Corte Total do produto ' || vc_Dados_Ite.CODPROD_O || vvInformacaoLoteFab ||
                                     ' na Filial Origem '             || vc_Dados_Cab.CODFILIAL_O || ' para a Filial Destino ' || vc_Dados_Cab.CODFILIAL_D || ' por estoque por lote insuficiente';
                -- Rejeita PARTE do Item, mas ACEITA o ITEM
                ELSE
                  vbAceitaItem := TRUE;
                  vMotivoRejeicao := '0019 - Corte Parcial de ' || (NVL(vc_Dados_Ite.QTD_TRANSFERIR_O,0) - NVL(vrItemPedido.nQTDETRANSFERIR,0)) ||
                                     ' unidade(s) do produto '  || vc_Dados_Ite.CODPROD_O   || vvInformacaoLoteFab ||
                                     ' na Filial Origem '       || vc_Dados_Cab.CODFILIAL_O || ' para a Filial Destino ' || vc_Dados_Cab.CODFILIAL_D || ' por estoque por lote insuficiente';
                  -- Adiciona Mensagem ao Array com a quantidade perdida por não ter estoque suficiente
                  viSeqMensAux := NVL(vtMensagensAux.COUNT,0) + 1;
                  vtMensagensAux(viSeqMensAux).vnCodFilial_O      := vc_Dados_Cab.CODFILIAL_O;
                  vtMensagensAux(viSeqMensAux).vnCodProd_O        := vc_Dados_Ite.CODPROD_O;
                  vtMensagensAux(viSeqMensAux).vvDescricao_O      := vc_Dados_Ite.DESCRICAO_O;
                  vtMensagensAux(viSeqMensAux).vnQtdeTransferir_O := vc_Dados_Ite.QTD_TRANSFERIR_O; -->> Qtde. Transferir Original sem Cortes
                  vtMensagensAux(viSeqMensAux).vnCodFilial_D      := vc_Dados_Cab.CODFILIAL_D;
                  vtMensagensAux(viSeqMensAux).vnCodProd_D        := vc_Dados_Ite.CODPROD_D;
                  vtMensagensAux(viSeqMensAux).vnSeqFalta         := vc_Dados_Ite.SEQFALTA;
                  vtMensagensAux(viSeqMensAux).vvMensagem         := SUBSTR(vMotivoRejeicao,1,240);
                  vtMensagensAux(viSeqMensAux).vvNumLote          := NVL(vrItemPedido.vNUMLOTE,'X');
                END IF;

              END IF;

            END IF; -- Fim Condição: Atribuição Lote

            -- Se passou pela Validação do Estoque por Lote
            IF (NVL(vrItemPedido.nQTDETRANSFERIR,0) > 0) THEN

              -- Obtém Estoque Disponível Avariado
              BEGIN
                SELECT QTINDENIZ
                  INTO vnQtIndenizDisponivel
                  FROM PCEST
                 WHERE (CODFILIAL = vc_Dados_Cab.CODFILIAL_O) -->> Sem Filial Retira
                   AND (CODPROD   = vc_Dados_Ite.CODPROD_O);
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  vnQtIndenizDisponivel := 0;
              END;

              -- SOMA O QUE ESTIVER EM PREFAT
              SELECT SUM(QT)
                INTO vnTotalAvariaPrefat
                FROM PCMOVPREFAT
                   , PCPEDC
               WHERE (PCMOVPREFAT.CODFILIAL = vc_Dados_Cab.CODFILIAL_O) -->> Sem Filial Retira
                 AND (PCMOVPREFAT.CODPROD   = vc_Dados_Ite.CODPROD_O)
                 AND (PCMOVPREFAT.NUMPED    = PCPEDC.NUMPED)
                 AND (PCPEDC.PEDIDOAVARIA   = 'S');
              IF (vnTotalAvariaPrefat > 0) THEN
                vnQtIndenizDisponivel := vnQtIndenizDisponivel - NVL(vnTotalAvariaPrefat,0);
                IF (vnQtIndenizDisponivel < 0) THEN
                  vnQtIndenizDisponivel := 0;
                END IF;
              END IF;

              -- Verifica o que já incluiu no Pedido de Outros Lotes
              SELECT SUM(QT)
                INTO vnQtIndenizUtilizado
                FROM PCPEDI
               WHERE (NUMPED  = vrPedido.nNUMPED)
                 AND (CODPROD = vc_Dados_Ite.CODPROD_O);

              -- Abate a Quantidade utilizada
              vnQtIndenizDisponivel := NVL(vnQtIndenizDisponivel,0) - NVL(vnQtIndenizUtilizado,0);
              IF (NVL(vnQtIndenizDisponivel,0) < 0) THEN
                vnQtIndenizDisponivel := 0;
              END IF;

              -- Se não tiver estoque suficiente
              IF (NVL(vrItemPedido.nQTDETRANSFERIR,0) > NVL(vnQtIndenizDisponivel,0)) THEN

                -- Altera a Quantidade a Transferir
                vrItemPedido.nQTDETRANSFERIR         := NVL(vnQtIndenizDisponivel,0);

                -- Rejeita Item
                IF (NVL(vrItemPedido.nQTDETRANSFERIR,0) <= 0) THEN
                  vbAceitaItem := FALSE;
                  vMotivoRejeicao := '0018 - Corte Total do produto ' || vc_Dados_Ite.CODPROD_O || vvInformacaoLoteFab ||
                                     ' na Filial Origem '             || vc_Dados_Cab.CODFILIAL_O || ' para a Filial Destino ' || vc_Dados_Cab.CODFILIAL_D;
                -- Rejeita PARTE do Item, mas ACEITA o ITEM
                ELSE
                  vbAceitaItem := TRUE;
                  vMotivoRejeicao := '0019 - Corte Parcial de ' || (NVL(vc_Dados_Ite.QTD_TRANSFERIR_O,0) - NVL(vrItemPedido.nQTDETRANSFERIR,0)) ||
                                     ' unidade(s) do produto '  || vc_Dados_Ite.CODPROD_O   || vvInformacaoLoteFab ||
                                     ' na Filial Origem '       || vc_Dados_Cab.CODFILIAL_O || ' para a Filial Destino ' || vc_Dados_Cab.CODFILIAL_D;
                  -- Adiciona Mensagem ao Array com a quantidade perdida por não ter estoque suficiente
                  viSeqMensAux := NVL(vtMensagensAux.COUNT,0) + 1;
                  vtMensagensAux(viSeqMensAux).vnCodFilial_O      := vc_Dados_Cab.CODFILIAL_O;
                  vtMensagensAux(viSeqMensAux).vnCodProd_O        := vc_Dados_Ite.CODPROD_O;
                  vtMensagensAux(viSeqMensAux).vvDescricao_O      := vc_Dados_Ite.DESCRICAO_O;
                  vtMensagensAux(viSeqMensAux).vnQtdeTransferir_O := vc_Dados_Ite.QTD_TRANSFERIR_O; -->> Qtde. Transferir Original sem Cortes
                  vtMensagensAux(viSeqMensAux).vnCodFilial_D      := vc_Dados_Cab.CODFILIAL_D;
                  vtMensagensAux(viSeqMensAux).vnCodProd_D        := vc_Dados_Ite.CODPROD_D;
                  vtMensagensAux(viSeqMensAux).vnSeqFalta         := vc_Dados_Ite.SEQFALTA;
                  vtMensagensAux(viSeqMensAux).vvMensagem         := SUBSTR(vMotivoRejeicao,1,240);
                  vtMensagensAux(viSeqMensAux).vvNumLote          := NVL(vrItemPedido.vNUMLOTE,'X');
                END IF;

              END IF;

            END IF; -- Fim Condição: Se passou pela Validação do Estoque por Lote

          --------------------------------------------------
          -- SE FOR PEDIDO NORMAL
          --------------------------------------------------
          -- Se Gera Pedido sem ter Estoque
          ELSIF (NVL(pi_vGeraPedSemEstoque,'S') = 'S') THEN

            -- VALIDAR MULTIPLO    
            -- Regra para multiplo do produto -- DDVENDAS-45056
            POBTEM_PARAMFILIAL_STRING(vc_Dados_Cab.CODFILIAL_O,
                                      'FIL_UTILIZAVENDAPOREMBALAGEM',
                                      vUTILIZAVENDAPOREMBALAGEM,
                                      vvErroPesqParam,
                                      vvMsgErroPesqParam);
            IF (vUTILIZAVENDAPOREMBALAGEM IS NULL) THEN
              POBTEM_PARAMFILIAL_STRING('99',
                                        'CON_UTILIZAVENDAPOREMBALAGEM',
                                        vUTILIZAVENDAPOREMBALAGEM,
                                        vvErroPesqParam,
                                        vvMsgErroPesqParam);
            END IF;
            
            IF (NVL(vUTILIZAVENDAPOREMBALAGEM,'N') <> 'S') THEN

               vAPLICARVALIDACAOMULTIPLO := F_OBTER_PARAM_REPOSICAO_LOJAS('99',
                                                                          'APLICARVALIDACAOMULTIPLO',
                                                                          'N');

              -- Verifica se o cliente está configurado para utilizar multiplo
              BEGIN
                SELECT NVL(PCCLIENT.VALIDARMULTIPLOVENDA,'N')
                  INTO vVALIDARMULTIPLOVENDA
                  FROM PCCLIENT, PCFILIAL
                 WHERE PCCLIENT.CODCLI = PCFILIAL.CODCLI
                   AND PCFILIAL.CODIGO = vc_Dados_Cab.CODFILIAL_D;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                 vVALIDARMULTIPLOVENDA := 'N';
              END;

              IF vVALIDARMULTIPLOVENDA = 'S' AND vAPLICARVALIDACAOMULTIPLO = 'S' THEN
                BEGIN
                  SELECT PCPRODFILIAL.MULTIPLO
                    INTO vMULTIPLOPRODUTO
                    FROM PCPRODFILIAL
                   WHERE (CODFILIAL = vc_Dados_Cab.CODFILIAL_O)
                     AND (CODPROD   = vc_Dados_Ite.CODPROD_O);
                         
                     IF NVL(vMULTIPLOPRODUTO,0) = 0 THEN
                        SELECT NVL(PCPRODUT.MULTIPLO ,1)
                          INTO vMULTIPLOPRODUTO
                          FROM PCPRODUT
                         WHERE (CODPROD = vc_Dados_Ite.CODPROD_O);                         
                     END IF;  
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    SELECT NVL(PCPRODUT.MULTIPLO ,1)
                      INTO vMULTIPLOPRODUTO
                      FROM PCPRODUT
                     WHERE (CODPROD = vc_Dados_Ite.CODPROD_O);
                END;
                    
                vc_Dados_Ite.QTD_EST_O := TRUNC(NVL(vc_Dados_Ite.QTD_EST_O,0) / NVL(vMULTIPLOPRODUTO,0)) * NVL(vMULTIPLOPRODUTO,0);    
                    
              END IF;
            END IF;
            -- FIM -- DDVENDAS-45056


            -- Se Transferência/Operador Logísticoe
            -- Se Filial Destino do Tipo Varejo e
            -- Se Libera Pedido Automaticamente e
            -- Se Guarda Faltas na Reposição do Varejo
            IF ((NVL(vc_Dados_Cab.TIPO_SUG_COMPRA_TRANSF,' ') IN ('T','L')) AND
                (NVL(vrFilDestino.vvTipoFilial,'1')           = '2') AND
                (NVL(pi_vLiberaPedido,'S')                    = 'S') AND
                (NVL(pi_vGuardaFalta,'S')                     = 'S')) THEN

              -- Se não tiver estoque
              IF (NVL(vc_Dados_Ite.QTD_EST_O,0) <= 0) THEN

                -- Sem Estoque para Sugestão
                vrItemPedido.nQTDETRANSFERIR := 0;

                -- Guarda Falta em Array
                viIdxFalta                           := NVL(vtFalta.COUNT,0) + 1;
                vtFalta(viIdxFalta).nCODPROD         := vc_Dados_Ite.CODPROD_O;
                vtFalta(viIdxFalta).nCODUSUR         := vrClienteDestino.nCODUSUR1;
                vtFalta(viIdxFalta).nCODCLI          := vrFilDestino.nCODCLI;
                vtFalta(viIdxFalta).nQT              := NVL(vc_Dados_Ite.QTD_TRANSFERIR_O,0);
                vtFalta(viIdxFalta).nPVENDA          := vrItemPedido.nPVENDA;
                vtFalta(viIdxFalta).vCODFILIAL       := vc_Dados_Cab.CODFILIAL_O;
                vtFalta(viIdxFalta).vQUEBRA1         := vc_Dados_Cab.QUEBRA1;
                vtFalta(viIdxFalta).vQUEBRA2         := vc_Dados_Cab.QUEBRA2;
                vtFalta(viIdxFalta).vQUEBRA3         := vc_Dados_Cab.QUEBRA3;
                vtFalta(viIdxFalta).vQUEBRA4         := vc_Dados_Cab.QUEBRA4;
                vtFalta(viIdxFalta).vCODFILIALRETIRA := vc_Dados_Cab.CODFILIALRETIRA_O; -->> Precisa pra atualizar QTVENDAPERDIDA
                vtFalta(viIdxFalta).vNUMLOTE         := NVL(vrItemPedido.vNUMLOTE,'X');

              -- Se tiver algum estoque
              ELSE

                -- Aceita a Sugestão na sua Totalidade
                vrItemPedido.nQTDETRANSFERIR := NVL(vc_Dados_Ite.QTD_TRANSFERIR_O,0);

              END IF;

            -- Demais casos
            ELSE

              -- Aceita a Sugestão na sua Totalidade
              vrItemPedido.nQTDETRANSFERIR := NVL(vc_Dados_Ite.QTD_TRANSFERIR_O,0);

            END IF;

          -- Se não Gera Pedido sem ter Estoque
          ELSE
            
            -- VALIDAR MULTIPLO    
            -- Regra para multiplo do produto -- DDVENDAS-45056
            POBTEM_PARAMFILIAL_STRING(vc_Dados_Cab.CODFILIAL_O,
                                      'FIL_UTILIZAVENDAPOREMBALAGEM',
                                      vUTILIZAVENDAPOREMBALAGEM,
                                      vvErroPesqParam,
                                      vvMsgErroPesqParam);
            IF (vUTILIZAVENDAPOREMBALAGEM IS NULL) THEN
              POBTEM_PARAMFILIAL_STRING('99',
                                        'CON_UTILIZAVENDAPOREMBALAGEM',
                                        vUTILIZAVENDAPOREMBALAGEM,
                                        vvErroPesqParam,
                                        vvMsgErroPesqParam);
            END IF;
            
            IF (NVL(vUTILIZAVENDAPOREMBALAGEM,'N') <> 'S') THEN

               vAPLICARVALIDACAOMULTIPLO := F_OBTER_PARAM_REPOSICAO_LOJAS('99',
                                                                          'APLICARVALIDACAOMULTIPLO',
                                                                          'N');

              -- Verifica se o cliente está configurado para utilizar multiplo
              BEGIN
                SELECT NVL(PCCLIENT.VALIDARMULTIPLOVENDA,'N')
                  INTO vVALIDARMULTIPLOVENDA
                  FROM PCCLIENT, PCFILIAL
                 WHERE PCCLIENT.CODCLI = PCFILIAL.CODCLI
                   AND PCFILIAL.CODIGO = vc_Dados_Cab.CODFILIAL_D;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                 vVALIDARMULTIPLOVENDA := 'N';
              END;

              IF vVALIDARMULTIPLOVENDA = 'S' AND vAPLICARVALIDACAOMULTIPLO = 'S' THEN
                BEGIN
                  SELECT PCPRODFILIAL.MULTIPLO
                    INTO vMULTIPLOPRODUTO
                    FROM PCPRODFILIAL
                   WHERE (CODFILIAL = vc_Dados_Cab.CODFILIAL_O)
                     AND (CODPROD   = vc_Dados_Ite.CODPROD_O);
                         
                     IF NVL(vMULTIPLOPRODUTO,0) = 0 THEN
                        SELECT NVL(PCPRODUT.MULTIPLO ,1)
                          INTO vMULTIPLOPRODUTO
                          FROM PCPRODUT
                         WHERE (CODPROD = vc_Dados_Ite.CODPROD_O);                         
                     END IF;  
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    SELECT NVL(PCPRODUT.MULTIPLO ,1)
                      INTO vMULTIPLOPRODUTO
                      FROM PCPRODUT
                     WHERE (CODPROD = vc_Dados_Ite.CODPROD_O);
                END;
                    
                -- vc_Dados_Ite.QTD_EST_O := (NVL(vc_Dados_Ite.QTD_EST_O,0) - Rr os EMAINDER(NVL(vc_Dados_Ite.QTD_EST_O,0),NVL(vMULTIPLOPRODUTO,0)));
                vc_Dados_Ite.QTD_EST_O := TRUNC(NVL(vc_Dados_Ite.QTD_EST_O,0) / NVL(vMULTIPLOPRODUTO,0)) * NVL(vMULTIPLOPRODUTO,0);    
              END IF;
            END IF;
            -- FIM -- DDVENDAS-45056

            -- Se a Sugestão Exceder o Estoque
            IF (NVL(vc_Dados_Ite.QTD_TRANSFERIR_O,0) > NVL(vc_Dados_Ite.QTD_EST_O,0)) THEN

              -- Limita a Sugestão ao Estoque
              vrItemPedido.nQTDETRANSFERIR := NVL(vc_Dados_Ite.QTD_EST_O,0);

              -- Se Transferência/Operador Logístico e
              -- Se Filial Destino do Tipo Varejo e
              -- Se Libera Pedido Automaticamente e
              -- Se Guarda Faltas na Reposição do Varejo
              IF ((NVL(vc_Dados_Cab.TIPO_SUG_COMPRA_TRANSF,' ') IN ('T','L')) AND
                  (NVL(vrFilDestino.vvTipoFilial,'1')           = '2') AND
                  (NVL(pi_vLiberaPedido,'S')                    = 'S') AND
                  (NVL(pi_vGuardaFalta,'S')                     = 'S')) THEN

                -- Guarda Falta em Array
                viIdxFalta                         := NVL(vtFalta.COUNT,0) + 1;
                vtFalta(viIdxFalta).nCODPROD       := vc_Dados_Ite.CODPROD_O;
                vtFalta(viIdxFalta).nCODUSUR       := vrClienteDestino.nCODUSUR1;
                vtFalta(viIdxFalta).nCODCLI        := vrFilDestino.nCODCLI;
                vtFalta(viIdxFalta).nQT            := (NVL(vc_Dados_Ite.QTD_TRANSFERIR_O,0) - NVL(vc_Dados_Ite.QTD_EST_O,0));
                vtFalta(viIdxFalta).nPVENDA        := vrItemPedido.nPVENDA;
                vtFalta(viIdxFalta).vCODFILIAL     := vc_Dados_Cab.CODFILIAL_O;
                vtFalta(viIdxFalta).vQUEBRA1       := vc_Dados_Cab.QUEBRA1;
                vtFalta(viIdxFalta).vQUEBRA2       := vc_Dados_Cab.QUEBRA2;
                vtFalta(viIdxFalta).vQUEBRA3       := vc_Dados_Cab.QUEBRA3;
                vtFalta(viIdxFalta).vQUEBRA4       := vc_Dados_Cab.QUEBRA4;
                vtFalta(viIdxFalta).vNUMLOTE       := NVL(vrItemPedido.vNUMLOTE,'X');

             END IF;

            -- Se a Sugestão não exceder o Estoque
            ELSE

              -- Aceita a Sugestão na sua Totalidade
              vrItemPedido.nQTDETRANSFERIR := NVL(vc_Dados_Ite.QTD_TRANSFERIR_O,0);

            END IF;

          END IF; -- Fim Condição Parâmetro Verifica Estoque

          -- Se ocorreram Cortes no Processo Normal
          IF (NVL(pi_vPedidoAvaria,'N') <> 'S') THEN -- (Pedido de Avaria a Validação ocorreu mais acima)
            IF (NVL(vrItemPedido.nQTDETRANSFERIR,0) <> NVL(vc_Dados_Ite.QTD_TRANSFERIR_O,0)) THEN

              -- Se cortou TUDO
              IF (NVL(NVL(vrItemPedido.nQTDETRANSFERIR,0),0) <= 0) THEN

                -- Rejeita Item
                vbAceitaItem        := FALSE;
                vMotivoRejeicao     := '0018 - Corte Total do produto ' || vc_Dados_Ite.CODPROD_O || vvInformacaoLoteFab ||
                                       ' na Filial Origem '             || vc_Dados_Cab.CODFILIAL_O || ' para a Filial Destino ' || vc_Dados_Cab.CODFILIAL_D;

              -- Se Corte PARCIAL
              ELSE

                -- Rejeita PARTE do Item, mas ACEITA o ITEM
                vbAceitaItem        := TRUE;
                vMotivoRejeicao     := '0019 - Corte Parcial de ' || (NVL(vc_Dados_Ite.QTD_TRANSFERIR_O,0) - NVL(vrItemPedido.nQTDETRANSFERIR,0)) ||
                                       ' unidade(s) do produto '  || vc_Dados_Ite.CODPROD_O   || vvInformacaoLoteFab ||
                                       ' na Filial Origem '       || vc_Dados_Cab.CODFILIAL_O || ' para a Filial Destino ' || vc_Dados_Cab.CODFILIAL_D;

                -- Gera novo Sequencial
                viSeqMensAux := NVL(vtMensagensAux.COUNT,0) + 1;

                -- Adiciona Mensagem ao Array
                vtMensagensAux(viSeqMensAux).vnCodFilial_O      := vc_Dados_Cab.CODFILIAL_O;
                vtMensagensAux(viSeqMensAux).vnCodProd_O        := vc_Dados_Ite.CODPROD_O;
                vtMensagensAux(viSeqMensAux).vvDescricao_O      := vc_Dados_Ite.DESCRICAO_O;
                vtMensagensAux(viSeqMensAux).vnQtdeTransferir_O := vc_Dados_Ite.QTD_TRANSFERIR_O; -->> Qtde. Transferir Original sem Cortes
                vtMensagensAux(viSeqMensAux).vnCodFilial_D      := vc_Dados_Cab.CODFILIAL_D;
                vtMensagensAux(viSeqMensAux).vnCodProd_D        := vc_Dados_Ite.CODPROD_D;
                vtMensagensAux(viSeqMensAux).vnSeqFalta         := vc_Dados_Ite.SEQFALTA;
                vtMensagensAux(viSeqMensAux).vvMensagem         := SUBSTR(vMotivoRejeicao,1,240);
                vtMensagensAux(viSeqMensAux).vvNumLote          := NVL(vrItemPedido.vNUMLOTE,'X');

              END IF;

            END IF; -- Fim Condição ocorreram Cortes
          END IF; -- Fim Condição não é pedido de avaria

         /*************************************************
          REGRA ESPECÍFICA - Utilizar Conversão PCEMBALAGEM
          *************************************************/
          IF (NVL(vUSAQTUNITPCEMBREPLOJA,'N') = 'S') THEN

            -- Tem que ter Embalagem de Venda conforme regra específica
            IF (NVL(vc_Dados_Ite.QTUNITCX_D,0) = 0) THEN

              -- Rejeita Item
              vbAceitaItem    := FALSE;
              vMotivoRejeicao := '0023 - Sem PCEMBALAGEM para Transferência para o produto ' || vc_Dados_Ite.CODPROD_O || vvInformacaoLoteFab ||
                                 ' na Filial Origem '  || vc_Dados_Cab.CODFILIAL_O || ' para a Filial Destino ' || vc_Dados_Cab.CODFILIAL_D;

            ELSE

              -- Tem que ser Múltiplo da Embalagem de Venda
              IF (MOD(NVL(vrItemPedido.nQTDETRANSFERIR,0),NVL(vc_Dados_Ite.QTUNITCX_D,0)) <> 0) THEN

                -- Rejeita Item
                -- MED-1896 - Somente se não ignorar esta validação
                IF (NVL(vIGNORARVALIDACAOMULTIPLOEMB,'N') = 'N') THEN

                  vbAceitaItem    := FALSE;
                  vMotivoRejeicao := '0024 - Quantidade não múltipla de ' || NVL(vc_Dados_Ite.QTUNITCX_D,0) || ' unidades conforme PCEMBALAGEM para o produto ' || vc_Dados_Ite.CODPROD_O || vvInformacaoLoteFab ||
                                     ' na Filial Origem ' || vc_Dados_Cab.CODFILIAL_O || ' para a Filial Destino ' || vc_Dados_Cab.CODFILIAL_D;

                ELSE

                  -- MED-1896 - Precisa gravar os campos se ignorar esta validação
                  vrItemPedido.nQTUNITEMB   := NVL(vc_Dados_Ite.QTUNITCX_D,0);
                  vrItemPedido.nCODAUXILIAR := NVL(vc_Dados_Ite.CODAUXILIAR_O,0);

                END IF;

              -- Se Passou pelas Validações de Embalagem
              ELSE

                vrItemPedido.nQTUNITEMB   := NVL(vc_Dados_Ite.QTUNITCX_D,0);
                vrItemPedido.nCODAUXILIAR := NVL(vc_Dados_Ite.CODAUXILIAR_O,0);

              END IF;

            END IF;

          END IF;

        END IF; -- Fim Condição Se não ocorreram erros no Cálculo da Comissão e Custo



       /*--------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------
        --                                                                                         --
        --          Se aceitar o Item, continua processamento, iniciando a gravação do pedido      --
        --                                                                                         --
        ---------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------
        ---------------------------------------------------------------------------------------------
        -------------------------------------------------------------------------------------------*/
        IF (vbAceitaItem) THEN



          -- Incrementa Quantidade de Itens do Pedido
          viContaItensPed := NVL(viContaItensPed,0) + 1;


         /*******************************************************************************************
          *******************************************************************************************
          *******************************************************************************************
          ** Insere Cabeçalho do Pedido sempre exceder o Limite de Itens no Pedido **
          ***************************************************************************
          ***************************************************************************/
          IF (NVL(viContaItensPed,0) > NVL(vrParamFilial.nFIL_NUMMAXITENSNFE,0)) THEN

            -- Se não for a primeira vez (se já gerou um pedido ou uma sugestão)
            IF ((NVL(vrPedido.nNUMPED,0) + NVL(vrPedido.nNUMSUGESTAO,0)) <> 0) THEN

             /**************************
              SE PEDIDO DE TRANSFERENCIA
              **************************/
              IF (NVL(vc_Dados_Cab.TIPO_SUG_COMPRA_TRANSF,'X') = 'T') THEN

                -------------------------------
                -- ATUALIZA TOTAIS DO PEDIDO --
                -------------------------------

                -- Calcula Totais do Pedido
                PTOTAIS_PEDIDO(vrPedido.nNUMPED);

                -- Atualiza PCPEDC
                UPDATE PCPEDC
                   SET PCPEDC.VLATEND       = vrPedido.nVLATEND
                     , PCPEDC.NUMITENS      = vrPedido.nNUMITENS
                     , PCPEDC.VLCUSTOFIN    = vrPedido.nVLCUSTOFIN
                     , PCPEDC.VLCUSTOREAL   = vrPedido.nVLCUSTOREAL
                     , PCPEDC.TOTPESO       = vrPedido.nTOTPESO
                     , PCPEDC.TOTVOLUME     = vrPedido.nTOTVOLUME
                     , PCPEDC.VLCUSTOCONT   = vrPedido.nVLCUSTOCONT
                     , PCPEDC.VLCUSTOREP    = vrPedido.nVLCUSTOREP
                     , PCPEDC.VLTABELA      = vrPedido.nVLTABELA
                     , PCPEDC.VLTOTAL       = vrPedido.nVLTOTAL
                     , PCPEDC.VLOUTRASDESP  = vrPedido.nVLOUTRASDESP
                     , PCPEDC.VLFRETE       = vrPedido.nVLFRETE
                     , PCPEDC.VLDESCONTO    = vrPedido.nVLDESCONTO
                 WHERE (PCPEDC.NUMPED = vrPedido.nNUMPED);

                -- Log de Alteração de Dados - MED-2196
                P_INSERE_LOG_ALTERACAO_DADOS('N',
                                             vrPedido.nNUMPED,
                                             'PCPEDC',
                                             'NUMITENS',
                                             NULL,               -- pi_vTextoNew
                                             NULL,               -- pi_vTextoOld
                                             vrPedido.nNUMITENS, -- pi_vNumeroNew
                                             0,                  -- pi_vNumeroOld
                                             'ALTERACAO DA QTDE',
                                             NULL);

                --------------------------
                -- ATUALIZA QT PENDENTE --
                --------------------------
                IF (NVL(pi_vPedidoAvaria,'N') = 'S') THEN
                  -- Pedido Avaria somente Incrementa Quantidade de Pedidos Gerados
                  po_nQtdePedidosGerados := NVL(po_nQtdePedidosGerados,0) + 1;
                ELSE
                  -- Pedido Normal atualiza a Quantidade Pendente
                  IF (FATUALIZA_QTPENDENTE(NVL(vc_Dados_Cab.CODFILIALRETIRA_O,vc_Dados_Cab.CODFILIAL_O), -->> Na Filial Retira (Se não tiver Na Filial de Origem)
                                           vrPedido.nNUMPED)) THEN
                    -- Incrementa Quantidade de Pedidos Gerados
                    po_nQtdePedidosGerados := NVL(po_nQtdePedidosGerados,0) + 1;
                  END IF;
                END IF;

             /**********************************
              SE NÃO FOR PEDIDO DE TRANSFERENCIA
              **********************************/
              ELSE

                -- Incrementa Quantidade de Pedidos Gerados
                po_nQtdePedidosGerados := NVL(po_nQtdePedidosGerados,0) + 1;

              END IF; -- FIM CONDICAO SE PEDIDO DE TRANSFERENCIA

              ----------------------------------
              -- EFETIVA TRANCACOES PENDENTES --
              ----------------------------------
              COMMIT;

              ------------------------
              -- ATUALIZA MENSAGENS --
              ------------------------
              PATUALIZA_MENSAGENS;

            END IF; -- Fim Condição não for a primeira vez que Gerou Pedido de Transferência ou Sugestão de Compra

           /**********************
            NOVO PEDIDO POR QUEBRA
            **********************/

           /*--------------------------
            Inicializa Totais do Pedido
            --------------------------*/
            vrPedido.nVLATEND      := 0;
            vrPedido.nNUMITENS     := 0;
            vrPedido.nVLCUSTOFIN   := 0;
            vrPedido.nVLCUSTOREAL  := 0;
            vrPedido.nTOTPESO      := 0;
            vrPedido.nTOTVOLUME    := 0;
            vrPedido.nVLCUSTOCONT  := 0;
            vrPedido.nVLCUSTOREP   := 0;
            vrPedido.nVLTABELA     := 0;
            vrPedido.nVLTOTAL      := 0;
            vrPedido.nVLOUTRASDESP := 0;
            vrPedido.nVLFRETE      := 0;
            vrPedido.nVLDESCONTO   := 0;

           /*-------------------------------------
            Inicializa Num. Pedido e Num. Sugestão
            -------------------------------------*/
            vrPedido.nNUMPED       := NULL;
            vrPedido.nNUMSUGESTAO  := NULL;

           /***********************
            PEDIDO DE TRANSFERENCIA
            ***********************/
            IF    (vc_Dados_Cab.TIPO_SUG_COMPRA_TRANSF = 'T') THEN

              -- Gera o Número do Pedido
              vrPedido.nNUMPED := FOBTEM_PROX_NUMPED(vrClienteDestino.nCODUSUR1);
              -- 4056.125049.2015
              IF (NOT F_PROX_NUMPED_VALIDO(vrPedido.nNUMPED)) THEN
                vvMsgErroTratado := 'NUMPED ' || vrPedido.nNUMPED || ' já existe. Verique o próximo NUMPED do RCA.';
                RAISE e_Tratado;
              END IF;
              -- Define a Data do Pedido
              vrPedido.dDATA   := TRUNC(SYSDATE);

              -- Processo TV10 OL
              IF (NVL(vc_Dados_Cab.INTEGRADORAESPELHONF,0) > 0) THEN
                -- Gera o Número do Pedido RCA
                vrPedido.nNUMPEDRCA         := FOBTEM_PROX_NUMPEDRCA(vrClienteDestino.nCODUSUR1);
                vrPedido.nDTABERTURAPEDPALM := SYSDATE;
                -- Obtém o Código do Projeto da Integradora
                vvCodigoProjetoIntegradora  := FOBTEM_CODIGOPROJETO_INTEGRAD(vc_Dados_Cab.INTEGRADORAESPELHONF);
                -- Insere na PCPEDRETORNO
                INSERT INTO PCPEDRETORNO
                          ( NUMPEDRCA
                          , CODUSUR
                          , CGCCLI
                          , DTABERTURAPEDPALM
                          , INTEGRADORA
                          , DTIMPORTACAO
                          , NUMPEDCLI
                          , NUMPEDVAN
                          , ARQUIVOPED
                          , CODFILIAL
                          , CODCLI
                          , GEROURET
                          , GEROUNOT
                          , ORIGEMPED
                          , TIPOFV
                          , CODIGOPROJETO
                          , NUMQUEBRA
                          , NUMPED )
                   VALUES ( vrPedido.nNUMPEDRCA
                          , vrClienteDestino.nCODUSUR1
                          , vrClienteDestino.vvCgcClienteDestino
                          , vrPedido.nDTABERTURAPEDPALM
                          , vc_Dados_Cab.INTEGRADORAESPELHONF
                          , TRUNC(vrPedido.nDTABERTURAPEDPALM)
                          , ''   -- NUMPEDCLI
                          , ''   -- NUMPEDVAN
                          , ''   -- ARQUIVOPED
                          , vc_Dados_Cab.CODFILIAL_O
                          , vrFilDestino.nCODCLI
                          , 'S'  -- GEROURET
                          , 'N'  -- GEROUNOT
                          , 'T'  -- ORIGEMPED
                          , 'OL' -- TIPOFV
                          , vvCodigoProjetoIntegradora
                          , 1    -- NUMQUEBRA
                          , vrPedido.nNUMPED );
              ELSE
                vrPedido.nNUMPEDRCA         := NULL;
                vrPedido.nDTABERTURAPEDPALM := NULL;
              END IF;
        vnNumviasmapasep := 0;
              IF pi_vAutomaticoManual <> 'A' then
                vnNumviasmapasep := -1;
              END IF;
              -- Insere na PCPEDC
              INSERT INTO PCPEDC
                        ( NUMPED
                        , PERCVENDA
                        , DATA
                        , CODCLI
                        , CODUSUR
                        , CODCOB
                        , POSICAO
                        , CONDVENDA
                        , CODFILIAL
                        , CODFILIALNF
                        , CODDISTRIB
                        , OPERACAO
                        , TIPOVENDA
                        , PRAZOMEDIO
                        , TIPOCARGA
                        , FRETEDESPACHO
                        , FRETEREDESPACHO
                        , DTENTREGA
                        , CODPLPAG
                        , OBSENTREGA1
                        , OBSENTREGA2
                        , OBSENTREGA3
                        , TIPOEMBALAGEM
                        , ORIGEMPED
                        , CODPRACA
                        , NUMCAR
                        , CODSUPERVISOR
                        , CODEMITENTE
                        , HORA
                        , MINUTO
                        , OBS
                        , GERACP
                        , USACFOPVENDANATV10
                        , PRAZO1
                        , PRAZO2
                        , PRAZO3
                        , PRAZO4
                        , PRAZO5
                        , PRAZO6
                        , PRAZO7
                        , PRAZO8
                        , PRAZO9
                        , PRAZO10
                        , PRAZO11
                        , PRAZO12
                        , ROTINALANC
                        -- Processo TV10 OL
                        , NUMPEDRCA
                        , DTABERTURAPEDPALM
                        , UTILIZAVENDAPOREMBALAGEM
                        , NUMREGIAO
                        , PEDIDOAVARIA
                        , VERSAOROTINA
            , NUMVIASMAPASEP
                        )
                  VALUES( vrPedido.nNUMPED                      -- NUMPED
                        , 100                                   -- PERCVENDA
                        , vrPedido.dDATA                        -- DATA
                        , vrFilDestino.nCODCLI                  -- CODCLI
                        , vrClienteDestino.nCODUSUR1            -- CODUSUR
                        , vrClienteDestino.vCODCOB              -- CODCOB
                        , DECODE(NVL(pi_vPedidoAvaria,'N'),'S','L','B') -- POSICAO (O Pedido sempre será gerado como Bloqueado se não for Avaria, se for Avaria grava como Liberado)
                        , vrPedido.nCONDVENDA                   -- CONDVENDA
                        , vc_Dados_Cab.CODFILIAL_O              -- CODFILIAL
                        , vc_Dados_Cab.CODFILIAL_O              -- CODFILIALNF
                        , vrRca.vCODDISTRIB                     -- CODDISTRIB
                        , 'N'                                   -- OPERACAO
                        , vrPlanoPag.vTIPOVENDA                 -- TIPOVENDA
                        , vrPlanoPag.nNUMDIAS                   -- PRAZOMEDIO
                        , 'R'                                   -- TIPOCARGA
                        , vrClienteDestino.vFRETEDESPACHO       -- FRETEDESPACHO
                        , vrClienteDestino.vFRETEDESPACHO       -- FRETEREDESPACHO
                        , vrPedido.dDATA                        -- DTENTREGA
                        , vrClienteDestino.nCODPLPAG            -- CODPLPAG
                        , vrClienteDestino.vOBSENTREGA1         -- OBSENTREGA1
                        , vrClienteDestino.vOBSENTREGA2         -- OBSENTREGA2
                        , vrClienteDestino.vOBSENTREGA3         -- OBSENTREGA3
                        , 'U'                                   -- TIPOEMBALAGEM
                        , 'T'                                   -- ORIGEMPED
                        , vrClienteDestino.nCODPRACA            -- CODPRACA
                        , 0                                     -- NUMCAR
                        , vrRca.nCODSUPERVISOR                  -- CODSUPERVISOR
                        , pi_nCodMatricula                      -- CODEMITENTE
                        , TO_CHAR(SYSDATE,'HH24')               -- HORA
                        , TO_CHAR(SYSDATE,'MI')                 -- MINUTO
                        , 'Ped. Transf. Rotina 3602'            -- OBS
                        , vrPedido.vGERACP                      -- GERACP
                        , vrPedido.vUSACFOPVENDANATV10          -- USACFOPVENDANATV10
                        , vrPedido.nPRAZO1                      -- PRAZO1
                        , vrPedido.nPRAZO2                      -- PPRAZO2
                        , vrPedido.nPRAZO3                      -- PPRAZO3
                        , vrPedido.nPRAZO4                      -- PPRAZO4
                        , vrPedido.nPRAZO5                      -- PPRAZO5
                        , vrPedido.nPRAZO6                      -- PPRAZO6
                        , vrPedido.nPRAZO7                      -- PPRAZO7
                        , vrPedido.nPRAZO8                      -- PPRAZO8
                        , vrPedido.nPRAZO9                      -- PPRAZO9
                        , vrPedido.nPRAZO10                     -- PPRAZO10
                        , vrPedido.nPRAZO11                     -- PPRAZO11
                        , vrPedido.nPRAZO12                     -- PPRAZO12
                        , 'PCSIS3602.EXE'                       -- ROTINALANC
                        -- Processo TV10 OL
                        , vrPedido.nNUMPEDRCA                   -- NUMPEDRCA
                        , vrPedido.nDTABERTURAPEDPALM           -- DTABERTURAPEDPALM
                        , vrPedido.vUTILIZAVENDAPOREMBALAGEM
                        , vrPracaCliDestino.nNUMREGIAO
                        , DECODE(NVL(pi_vPedidoAvaria,'N'),'S','S',NULL)
                        , (SELECT 'PCSIS3600.EXE ' || PCVERSAOBD.VERSAO FROM PCVERSAOBD WHERE PCVERSAOBD.ROTINA = 'PCSIS3600.PC' AND OPCAO = 1)
            , vnNumviasmapasep
                        );

              -- Log de Alteração de Dados - MED-2196
              P_INSERE_LOG_ALTERACAO_DADOS('A',
                                           vrPedido.nNUMPED,
                                           'PCPEDC',
                                           'POSICAO',
                                           'B',  -- pi_vTextoNew
                                           NULL, -- pi_vTextoOld
                                           NULL, -- pi_vNumeroNew
                                           NULL, -- pi_vNumeroOld
                                           'INCLUSAO DA POSICAO',
                                           NULL);

              -- Insere em Lista de Pedidos Gerados
              viIndicePedGerado := NVL(vtPedidosGerados.COUNT,0) + 1;
              vtPedidosGerados(viIndicePedGerado).vvCodFilial        := vc_Dados_Cab.CODFILIAL_O;
              vtPedidosGerados(viIndicePedGerado).vnNumPed           := vrPedido.nNUMPED;
              vtPedidosGerados(viIndicePedGerado).vdData             := vrPedido.dDATA;
              vtPedidosGerados(viIndicePedGerado).vnCodUsur          := vrClienteDestino.nCODUSUR1;
              vtPedidosGerados(viIndicePedGerado).vnCodCli           := vrFilDestino.nCODCLI;
              vtPedidosGerados(viIndicePedGerado).vvFantasia         := vrClienteDestino.vFANTASIA;
              vtPedidosGerados(viIndicePedGerado).vvQuebra1          := vc_Dados_Cab.QUEBRA1;
              vtPedidosGerados(viIndicePedGerado).vvQuebra2          := vc_Dados_Cab.QUEBRA2;
              vtPedidosGerados(viIndicePedGerado).vvQuebra3          := vc_Dados_Cab.QUEBRA3;
              vtPedidosGerados(viIndicePedGerado).vvQuebra4          := vc_Dados_Cab.QUEBRA4;
              vtPedidosGerados(viIndicePedGerado).vvCodFilialRetira  := vc_Dados_Cab.CODFILIALRETIRA_O;
              vtPedidosGerados(viIndicePedGerado).vvCodFilialDestino := vc_Dados_Cab.CODFILIAL_D;

           /****************************
            PEDIDO DE OPERADOR LOGISTICO
            ****************************/
            ELSIF (vc_Dados_Cab.TIPO_SUG_COMPRA_TRANSF = 'L') THEN

              -- Gera o Número de Pedido de Operador Logístico
              vrPedido.nNUMPEDOPERLOG := FOBTEM_PROX_NUMPEDOPERLOG;
              -- Define a Data do Pedido (Tem que ser Data e Hora)
              -- Soma 3 segundos a cada Pedido de Operador Logístico gerado,
              -- para que os Pedidos não tenham a mesma Data/Hora:Min:Seg,
              -- porque a Exportação do Arquivo de Pedido exige essa unicidade para não sobrescrever o Arquivo
              vdDtPedOperLog          := vdDtPedOperLog + 0.00003; --> Incremento dos Segundos
              vrPedido.dDATA          := vdDtPedOperLog;

              -- Insere na PCPEDCOMPRAOPERLOGCAB
              INSERT INTO PCPEDCOMPRAOPERLOGCAB
                        ( NUMPED
                        , DTPED
                        , CODFORNEC
                        , CODFILIAL
                        , CODUSUARIO
                        , INTEGRADORA
                        , SITUACAO
                        )
                  VALUES( vrPedido.nNUMPEDOPERLOG
                        , vrPedido.dDATA
                        , vc_Dados_Cab.CODFORNECPRIORIDADE
                        , vc_Dados_Cab.CODFILIAL_D
                        , pi_nCodMatricula
                        , vc_Dados_Cab.INTEGRADORA
                        , 'P' -- Situação Pendente
                        );

           /******************
            SUGESTAO DE COMPRA
            ******************/
            ELSIF (vc_Dados_Cab.TIPO_SUG_COMPRA_TRANSF = 'C') THEN

              -- Gera o Número da Sugestão
              vrPedido.nNUMSUGESTAO := FOBTEM_PROX_NUMSUGESTAO;
              -- Define a Data da Sugestão
              vrPedido.dDATA        := TRUNC(SYSDATE);

              -- Insere na PCSUGESTAOCOMPRAC
              INSERT INTO PCSUGESTAOCOMPRAC
                        ( NUMSUGESTAO
                        , CODFORNEC
                        , CODFILIAL
                        , CODUSUARIOSUGESTAO
                        , DATASUGESTAO
                        )
                  VALUES( vrPedido.nNUMSUGESTAO
                        , vc_Dados_Cab.CODFORNECPRIORIDADE
                        , vc_Dados_Cab.CODFILIAL_D
                        , pi_nCodMatricula
                        , vrPedido.dDATA
                        );

            END IF; -- FIM CONDIÇÃO PEDIDO TRANSFERENCIA/SUGESTAO DE COMPRA


            -- Inicializa a Quantidade de Itens do Pedido
            viContaItensPed := 1;

          END IF; -- Fim Condição Insere Cabeçalho do Pedido



         /*******************************************************************************************
          *******************************************************************************************
          *******************************************************************************************
          ** Insere Item do Pedido **
          ***************************
          ***************************
          ***************************/

         /*******************************
          ITEM DE PEDIDO DE TRANSFERENCIA
          *******************************/
          IF (vc_Dados_Cab.TIPO_SUG_COMPRA_TRANSF = 'T') THEN

            -- Insere na PCPEDI
            INSERT INTO PCPEDI
                      ( NUMPED
                      , CODPROD
                      , NUMSEQ
                      , QT
                      , PVENDA
                      , DATA
                      , CODCLI
                      , CODUSUR
                      , PTABELA
                      , POSICAO
                      , NUMCAR
                      , PVENDABASE
                      , CODST
                      , PERDESC
                      , ST
                      , PERCIPI
                      , VLIPI
                      , IVA
                      , PAUTA
                      , ALIQICMS1
                      , ALIQICMS2
                      , PERCBASEREDST
                      , STCLIENTEGNRE
                      , PERCOM
                      , VLCUSTOCONT
                      , VLCUSTOREP
                      , VLCUSTOREAL
                      , VLCUSTOFIN
                      , VLDESCCUSTOCMV
                      , PRECOMAXCONSUM
                      , BASEICST
                      , REGIMEESPISENSTFONTE
                      , PVENDA1
                      , QTUNITEMB
                      , CODAUXILIAR
                      , CODICMTAB         -- HIS.02786.2016
                      , PRODIMPORTADOPEPS -- HIS.02786.2016
                      , NUMTRANSENTPEPS   -- HIS.02786.2016
                      , CODFILIALRETIRA
                      , INDESCALARELEVANTE  -- HIS.03379.2017
                      , CNPJFABRICANTE      -- HIS.03379.2017
                      , FABRICANTE          -- HIS.03379.2017
                      , VLBASEFCPST
                      , ALIQICMSFECP
                      , VLFECP
                      , UTILIZOUMOTORCALCULO
                      , OBSERVACAOSTFONTE   -- HIS.03379.2017
                      , VLBASEFCPICMS       -- HIS.04200.2017
                      , VLBCFCPSTRET        -- HIS.04200.2017
                      , PERFCPSTRET         -- HIS.04200.2017
                      , VLFCPSTRET          -- HIS.04200.2017
                      , PERFCPSN            -- HIS.04200.2017
                      , VLACRESCIMOFUNCEP   -- HIS.04200.2017
                      , PERACRESCIMOFUNCEP  -- HIS.04200.2017
                      , VLCREDFCPICMSSN     -- HIS.04200.2017
                      , CODCONFIGFUNCEPMED
                      , ROTINALANC
                      , NUMLOTE
                      )
                VALUES( vrPedido.nNUMPED                      -- NUMPED
                      , vc_Dados_Ite.CODPROD_O                -- CODPROD
                      , viContaItensPed                       -- NUMSEQ
                      , vrItemPedido.nQTDETRANSFERIR          -- QT
                      , vrItemPedido.nPVENDA                  -- PVENDA
                      , vrPedido.dDATA                        -- DATA
                      , vrFilDestino.nCODCLI                  -- CODCLI
                      , vrClienteDestino.nCODUSUR1            -- CODUSUR
                      , vrItemPedido.nPTABELA                 -- PTABELA
                      , DECODE(NVL(pi_vPedidoAvaria,'N'),'S','L','B') -- POSICAO
                      , 0                                     -- NUMCAR
                      , vrItemPedido.nPVENDABASE              -- PVENDABASE
                      , vrItemPedido.nCODST                   -- CODST
                      , vrItemPedido.nPERDESC                 -- PERDESC
                      , vrItemPedido.nST                      -- ST
                      , vrItemPedido.nPERCIPI                 -- PERCIPI
                      , vrItemPedido.nVLIPI                   -- VLIPI
                      , vrItemPedido.nIVA                     -- IVA
                      , vrItemPedido.nPAUTA                   -- PAUTA
                      , vrItemPedido.nALIQICMS1               -- ALIQICMS1
                      , vrItemPedido.nALIQICMS2               -- ALIQICMS2
                      , vrItemPedido.nPERCBASEREDST           -- PERCBASEREDST
                      , vrItemPedido.nSTCLIENTEGNRE           -- STCLIENTEGNRE
                      , vrItemPedido.nPERCOM                  -- PERCOM
                      , vrItemPedido.nVLCUSTOCONT             -- VLCUSTOCONT
                      , vrItemPedido.nVLCUSTOREP              -- VLCUSTOREP
                      , vrItemPedido.nVLCUSTOREAL             -- VLCUSTOREAL
                      , vrItemPedido.nVLCUSTOFIN              -- VLCUSTOFIN
                      , vrItemPedido.nVLDESCCUSTOCMV          -- VLDESCCUSTOCMV
                      , vrItemPedido.nPRECOMAXCONSUM          -- PRECOMAXCONSUM
                      , vrItemPedido.nBASEICST                -- BASEICST
                      , vrItemPedido.nREGIMEESPISENSTFONTE    -- REGIMEESPISENSTFONTE
                      , vrItemPedido.nPVENDA1                 -- PVENDA1
                      , vrItemPedido.nQTUNITEMB               -- QTUNITEMB
                      , vrItemPedido.nCODAUXILIAR             -- CODAUXILIAR
                      , vrItemPedido.nCODICMTAB               -- HIS.02786.2016
                      , vrItemPedido.vPRODIMPORTADOPEPS       -- HIS.02786.2016
                      , vrItemPedido.nNUMTRANSENTPEPS         -- HIS.02786.2016
                      , NVL(vc_Dados_Cab.CODFILIALRETIRA_O,vc_Dados_Cab.CODFILIAL_O) -->> Na Filial Retira (Se não tiver Na Filial de Origem)
                      , vrItemPedido.vINDESCALARELEVANTE      -- HIS.03379.2017
                      , vrItemPedido.vCNPJFABRICANTE          -- HIS.03379.2017
                      , vrItemPedido.vFABRICANTE              -- HIS.03379.2017
                      , vrItemPedido.nBASEFECP
                      , vrItemPedido.nALIQFECP
                      , vrItemPedido.nVLFECP
                      ,'S'
                      , vrItemPedido.vOBSERVACAOSTFONTE       -- HIS.03379.2017
                      , vrDadosFuncep.nVLBASEFCPICMS          -- HIS.04200.2017
                      , vrDadosFuncep.nVLBCFCPSTRET           -- HIS.04200.2017
                      , vrDadosFuncep.nPERFCPSTRET            -- HIS.04200.2017
                      , vrDadosFuncep.nVLFCPSTRET             -- HIS.04200.2017
                      , vrDadosFuncep.nPERFCPSN               -- HIS.04200.2017
                      , vrDadosFuncep.nVLACRESCIMOFUNCEP      -- HIS.04200.2017
                      , vrDadosFuncep.nPERACRESCIMOFUNCEP     -- HIS.04200.2017
                      , vrDadosFuncep.nVLCREDFCPICMSSN        -- HIS.04200.2017
                      , vrDadosFuncep.nCODCONFIGFUNCEPMED
                      , '3602'
                      , vrItemPedido.vNUMLOTE
                      );

            -- Atualiza Tabela Temporária com os dados do Pedido Gerado
            IF (pi_nOrigemChamada = 1) THEN
              UPDATE PCMED_TEMP_TRANSF_ATAC_VAR
                 SET NUMPED                = vrPedido.nNUMPED
                   , QTPED                 = vrItemPedido.nQTDETRANSFERIR
                   , PRECOPED              = vrItemPedido.nPVENDA
                   , CODCLI                = vrFilDestino.nCODCLI
                   , NOMEFANTASIACLIENTE   = vrClienteDestino.vFANTASIA
               WHERE (CODFILIAL_O      = vc_Dados_Cab.CODFILIAL_O)
                 AND (CODPROD_O        = vc_Dados_Ite.CODPROD_O)
                 AND (CODFILIAL_D      = vc_Dados_Cab.CODFILIAL_D)
                 AND (CODPROD_D        = vc_Dados_Ite.CODPROD_D)
                 AND (NVL(NUMLOTE,'X') = NVL(vrItemPedido.vNUMLOTE,'X'));

              -- INICIO: MED-1876 - Guarda Itens Gerados para Log de Erro ao Reservar Estoque Pendente
              viIdxItensPedGerados := NVL(vtItensPedGerados.COUNT,0) + 1;
              vtItensPedGerados(viIdxItensPedGerados).vCODFILIAL_O      := vc_Dados_Cab.CODFILIAL_O;
              vtItensPedGerados(viIdxItensPedGerados).nCODPROD_O        := vc_Dados_Ite.CODPROD_O;
              vtItensPedGerados(viIdxItensPedGerados).vDESCRICAO_O      := vc_Dados_Ite.DESCRICAO_O;
              vtItensPedGerados(viIdxItensPedGerados).nQTD_TRANSFERIR_O := vc_Dados_Ite.QTD_TRANSFERIR_O; -->> Qtde. Transferir Original sem Cortes
              vtItensPedGerados(viIdxItensPedGerados).vCODFILIAL_D      := vc_Dados_Cab.CODFILIAL_D;
              vtItensPedGerados(viIdxItensPedGerados).nCODPROD_D        := vc_Dados_Ite.CODPROD_D;
              vtItensPedGerados(viIdxItensPedGerados).nNUMPED           := vrPedido.nNUMPED;
              vtItensPedGerados(viIdxItensPedGerados).vNUMLOTE          := NVL(vrItemPedido.vNUMLOTE,'X');
              -- FIM: MED-1876 - Guarda Itens Gerados para Log de Erro ao Reservar Estoque Pendente
            ELSIF (pi_nOrigemChamada = 2) THEN
              UPDATE PCMED_TEMP_FALTAS_ATAC_VAR
                 SET NUMPED      = vrPedido.nNUMPED
                   , QTPED       = vrItemPedido.nQTDETRANSFERIR
                   , PRECOPED    = vrItemPedido.nPVENDA
                   , CODFORNEC   = vc_Dados_Cab.CODFORNECPRIORIDADE
                   , DTGERPED    = vrPedido.dDATA
               WHERE (SEQFALTA = vc_Dados_Ite.SEQFALTA);
            END IF;

         /************************************
          ITEM DE PEDIDO DE OPERADOR LOGISTICO
          ************************************/
          ELSIF (vc_Dados_Cab.TIPO_SUG_COMPRA_TRANSF = 'L') THEN

            -- Insere na PCPEDCOMPRAOPERLOGITE
            INSERT INTO PCPEDCOMPRAOPERLOGITE
                      ( NUMPED
                      , CODPROD
                      , NUMSEQ
                      , QTPED )
                VALUES( vrPedido.nNUMPEDOPERLOG
                      , vc_Dados_Ite.CODPROD_O
                      , viContaItensPed
                      , vrItemPedido.nQTDETRANSFERIR );

            -- Atualiza Tabela Temporária com os dados do Pedido Gerado
            IF (pi_nOrigemChamada = 1) THEN
              UPDATE PCMED_TEMP_TRANSF_ATAC_VAR
                 SET NUMPED                = vrPedido.nNUMPEDOPERLOG -->> Número de Pedido de Operador Logistico
                   , QTPED                 = vrItemPedido.nQTDETRANSFERIR
                   , PRECOPED              = vrItemPedido.nPVENDA
                   , CODCLI                = vrFilDestino.nCODCLI
                   , NOMEFANTASIACLIENTE   = vrClienteDestino.vFANTASIA
               WHERE (CODFILIAL_O      = vc_Dados_Cab.CODFILIAL_O)
                 AND (CODPROD_O        = vc_Dados_Ite.CODPROD_O)
                 AND (CODFILIAL_D      = vc_Dados_Cab.CODFILIAL_D)
                 AND (CODPROD_D        = vc_Dados_Ite.CODPROD_D)
                 AND (NVL(NUMLOTE,'X') = NVL(vrItemPedido.vNUMLOTE,'X'));
            ELSIF (pi_nOrigemChamada = 2) THEN
              UPDATE PCMED_TEMP_FALTAS_ATAC_VAR
                 SET NUMPED      = vrPedido.nNUMPEDOPERLOG -->> Número de Pedido de Operador Logistico
                   , QTPED       = vrItemPedido.nQTDETRANSFERIR
                   , PRECOPED    = vrItemPedido.nPVENDA
                   , CODFORNEC   = vc_Dados_Cab.CODFORNECPRIORIDADE
                   , DTGERPED    = vrPedido.dDATA
               WHERE (SEQFALTA = vc_Dados_Ite.SEQFALTA);
            END IF;

         /**************************
          ITEM DE SUGESTAO DE COMPRA
          **************************/
          ELSIF (vc_Dados_Cab.TIPO_SUG_COMPRA_TRANSF = 'C') THEN

            -- Insere na PCSUGESTAOCOMPRAI
            INSERT INTO PCSUGESTAOCOMPRAI
                      ( NUMSUGESTAO
                      , CODPROD
                      , QTSUGERIDA
                      , STATUS
                      , PCOMPRALIQSUGERIDO )
                VALUES( vrPedido.nNUMSUGESTAO
                      , vc_Dados_Ite.CODPROD_O
                      , vc_Dados_Ite.QTD_TRANSFERIR_O
                      , NULL
                      , vc_Dados_Ite.PRECO_TRANSF_O );

            -- Atualiza Tabela Temporária com os dados da Sugestão Gerada
            IF    (pi_nOrigemChamada = 1) THEN
              UPDATE PCMED_TEMP_TRANSF_ATAC_VAR
                 SET NUMSUGESTAO = vrPedido.nNUMSUGESTAO -->> No Número da Sugestão
                   , QTPED       = vc_Dados_Ite.QTD_TRANSFERIR_O
                   , PRECOPED    = vc_Dados_Ite.PRECO_TRANSF_O
               WHERE (CODFILIAL_O      = vc_Dados_Cab.CODFILIAL_O)
                 AND (CODPROD_O        = vc_Dados_Ite.CODPROD_O)
                 AND (CODFILIAL_D      = vc_Dados_Cab.CODFILIAL_D)
                 AND (CODPROD_D        = vc_Dados_Ite.CODPROD_D)
                 AND (NVL(NUMLOTE,'X') = NVL(vrItemPedido.vNUMLOTE,'X'));
            ELSIF (pi_nOrigemChamada = 2) THEN
              UPDATE PCMED_TEMP_FALTAS_ATAC_VAR
                 SET NUMSUGESTAO = vrPedido.nNUMSUGESTAO -->> No Número da Sugestão
                   , QTPED       = vc_Dados_Ite.QTD_TRANSFERIR_O
                   , PRECOPED    = vc_Dados_Ite.PRECO_TRANSF_O
                   , CODFORNEC   = vc_Dados_Cab.CODFORNECPRIORIDADE
                   , DTGERPED    = vrPedido.dDATA
               WHERE (SEQFALTA = vc_Dados_Ite.SEQFALTA);
            END IF;

          END IF; -- FIM CONDIÇÃO ITEM DO PEDIDO TRANSFERENCIA/SUGESTAO DE COMPRA

       /*-----------------------------------------------------
        Se não aceitar o Item, aborta processamento e gera Log
        -----------------------------------------------------*/
        ELSE

          -- Gera novo Sequencial
          viSeqMensAux := NVL(vtMensagensAux.COUNT,0) + 1;

          -- Adiciona Mensagem ao Array
          vtMensagensAux(viSeqMensAux).vnCodFilial_O      := vc_Dados_Cab.CODFILIAL_O;
          vtMensagensAux(viSeqMensAux).vnCodProd_O        := vc_Dados_Ite.CODPROD_O;
          vtMensagensAux(viSeqMensAux).vvDescricao_O      := vc_Dados_Ite.DESCRICAO_O;
          vtMensagensAux(viSeqMensAux).vnQtdeTransferir_O := vc_Dados_Ite.QTD_TRANSFERIR_O; -->> Qtde. Transferir Original sem Cortes
          vtMensagensAux(viSeqMensAux).vnCodFilial_D      := vc_Dados_Cab.CODFILIAL_D;
          vtMensagensAux(viSeqMensAux).vnCodProd_D        := vc_Dados_Ite.CODPROD_D;
          vtMensagensAux(viSeqMensAux).vnSeqFalta         := vc_Dados_Ite.SEQFALTA;
          vtMensagensAux(viSeqMensAux).vvMensagem         := SUBSTR(vMotivoRejeicao,1,240);
          vtMensagensAux(viSeqMensAux).vvNumLote          := NVL(vrItemPedido.vNUMLOTE,'X');

        END IF; -- Fim Condição Se Aceita o Item

      END LOOP; -- Fim Cursor de Itens para cada Cabeçalho

     /**************************
      SE PEDIDO DE TRANSFERENCIA
      **************************/
      IF (NVL(vc_Dados_Cab.TIPO_SUG_COMPRA_TRANSF,'X') = 'T') THEN

        -- Se o Ultimo Pedido gerado foi de Transferência
        IF (NVL(vrPedido.nNUMPED,0) > 0) THEN

          -------------------------------
          -- ATUALIZA TOTAIS DO PEDIDO --
          -------------------------------

          -- Calcula Totais do Pedido
          PTOTAIS_PEDIDO(vrPedido.nNUMPED);

          -- Atualiza PCPEDC
          UPDATE PCPEDC
             SET PCPEDC.VLATEND       = vrPedido.nVLATEND
               , PCPEDC.NUMITENS      = vrPedido.nNUMITENS
               , PCPEDC.VLCUSTOFIN    = vrPedido.nVLCUSTOFIN
               , PCPEDC.VLCUSTOREAL   = vrPedido.nVLCUSTOREAL
               , PCPEDC.TOTPESO       = vrPedido.nTOTPESO
               , PCPEDC.TOTVOLUME     = vrPedido.nTOTVOLUME
               , PCPEDC.VLCUSTOCONT   = vrPedido.nVLCUSTOCONT
               , PCPEDC.VLCUSTOREP    = vrPedido.nVLCUSTOREP
               , PCPEDC.VLTABELA      = vrPedido.nVLTABELA
               , PCPEDC.VLTOTAL       = vrPedido.nVLTOTAL
               , PCPEDC.VLOUTRASDESP  = vrPedido.nVLOUTRASDESP
               , PCPEDC.VLFRETE       = vrPedido.nVLFRETE
               , PCPEDC.VLDESCONTO    = vrPedido.nVLDESCONTO
           WHERE (PCPEDC.NUMPED = vrPedido.nNUMPED);

          -- Log de Alteração de Dados - MED-2196
          P_INSERE_LOG_ALTERACAO_DADOS('N',
                                       vrPedido.nNUMPED,
                                       'PCPEDC',
                                       'NUMITENS',
                                       NULL,               -- pi_vTextoNew
                                       NULL,               -- pi_vTextoOld
                                       vrPedido.nNUMITENS, -- pi_vNumeroNew
                                       0,                  -- pi_vNumeroOld
                                       'ALTERACAO DA QUANTIDADE',
                                       NULL);

          --------------------------
          -- ATUALIZA QT PENDENTE --
          --------------------------
          IF (NVL(pi_vPedidoAvaria,'N') = 'S') THEN
            -- Pedido Avaria somente Incrementa Quantidade de Pedidos Gerados
            po_nQtdePedidosGerados := NVL(po_nQtdePedidosGerados,0) + 1;
          ELSE
            IF (FATUALIZA_QTPENDENTE(NVL(vc_Dados_Cab.CODFILIALRETIRA_O,vc_Dados_Cab.CODFILIAL_O), -->> Na Filial Retira (Se não tiver Na Filial de Origem)
                                     vrPedido.nNUMPED)) THEN
              -- Incrementa Quantidade de Pedidos Gerados
              po_nQtdePedidosGerados := NVL(po_nQtdePedidosGerados,0) + 1;
            END IF;
          END IF;

        END IF; -- Fim Condição Se o Ultimo Pedido gerado foi de Transferência

     /**********************************
      SE NÃO FOR PEDIDO DE TRANSFERENCIA
      **********************************/
      ELSE

        -- Incrementa Quantidade de Pedidos Gerados se Gerou Sugestão de Compra
        IF (NVL(vrPedido.nNUMSUGESTAO,0) > 0) THEN
          po_nQtdePedidosGerados := NVL(po_nQtdePedidosGerados,0) + 1;
        END IF;

      END IF; -- FIM CONDICAO SE PEDIDO DE TRANSFERENCIA

      ----------------------------------
      -- EFETIVA TRANCACOES PENDENTES --
      ----------------------------------
      COMMIT;

      ------------------------
      -- ATUALIZA MENSAGENS --
      ------------------------
      PATUALIZA_MENSAGENS;

    END LOOP; -- Fim Cursor de Dados de Cabeçalho

   /*********************************************************
    LIBERA PEDIDOS DE TRANSFERÊNCIA AO FINAL DO PROCESSAMENTO
    *********************************************************/

    -- Limpa Tabela Temporária das Faltas (DDMEDICA-133 - Independe se Libera ou Não)
    IF (pi_nOrigemChamada = 1) THEN
      EXECUTE IMMEDIATE 'TRUNCATE TABLE PCMED_TEMP_FALTAS_ATAC_VAR';
    END IF;

    IF ((pi_nOrigemChamada = 1) AND -->>> Garante que os dados da PCMED_TEMP_FALTAS_ATAC_VAR não sejam apagados para consulta na 2312 das Compras de Faltas
        (pi_vLiberaPedido  = 'S')) THEN

      -- Inicializa Sequencial da Falta
      nSEQFALTA := 0;

      --------------------------------------------------------
      -- Processa os Pedidos Gerados para LIBERACAO AUTOMATICA
      --------------------------------------------------------
      IF (vtPedidosGerados.COUNT > 0) THEN
        FOR viIndicePedGerado IN vtPedidosGerados.FIRST..vtPedidosGerados.LAST LOOP

          -- Procedimento para Faturar o Pedido Automaticamente
          IF (NVL(pi_vPedidoAvaria,'N') = 'S') THEN
            PFATURA_PEDIDO(vtPedidosGerados(viIndicePedGerado).vnNumPed,
                           pi_nCodMatricula,
                           vvErroFaturarPedido,
                           vvMsgErroFaturarPedido);
            IF (vvErroFaturarPedido = 'S') THEN
              -- Adiciona Mensagem ao Array vtMensagens
              viSeqMensAux := NVL(vtMensagens.COUNT,0) + 1;
              vtMensagens(viSeqMensAux).vnCodFilial_O      := vtPedidosGerados(viIndicePedGerado).vvCodFilial;
              vtMensagens(viSeqMensAux).vnCodProd_O        := 0;
              vtMensagens(viSeqMensAux).vvDescricao_O      := NULL;
              vtMensagens(viSeqMensAux).vnQtdeTransferir_O := 0;
              vtMensagens(viSeqMensAux).vnCodFilial_D      := vtPedidosGerados(viIndicePedGerado).vvCodFilialDestino;
              vtMensagens(viSeqMensAux).vnCodProd_D        := 0;
              vtMensagens(viSeqMensAux).vnSeqFalta         := 0;
              vtMensagens(viSeqMensAux).vvMensagem         := SUBSTR(vvMsgErroFaturarPedido,1,240);
              vtMensagens(viSeqMensAux).vvNumLote          := 'X';
            END IF;
          -- Procedimento para Liberar o Pedido
          ELSE
            PLIBERA_PEDIDO(vtPedidosGerados(viIndicePedGerado).vvCodFilial,
                           vtPedidosGerados(viIndicePedGerado).vnNumPed,
                           vtPedidosGerados(viIndicePedGerado).vdData,
                           vtPedidosGerados(viIndicePedGerado).vnCodUsur,
                           vtPedidosGerados(viIndicePedGerado).vnCodCli,
                           vtPedidosGerados(viIndicePedGerado).vvFantasia,
                           vUSAQTUNITPCEMBREPLOJA,
                           vUSAREGRAARREDEMBFRNFTAREP,
                           vtPedidosGerados(viIndicePedGerado).vvCodFilialRetira);
          END IF;

        END LOOP; -- Fim do Laço de Processamento dos Pedidos Gerados
      END IF;

      -----------------------------------------------------------
      -- Processa as Faltas calculadas antes de Gerar os Pedidos,
      -- para guardá-las na tabela PCFALTA
      -----------------------------------------------------------
      IF (vtFalta.COUNT > 0) THEN

        -- Processa as Faltas guardadas antes da Geração dos Pedidos
        FOR viIdxFalta IN vtFalta.FIRST..vtFalta.LAST LOOP

          -- Incializa Variaveis para receber o Numero e Data do Pedido
          vnNumPedidoRegistrarFalta  := NULL;
          vdDataPedidoRegistrarFalta := NULL;

          -- Pesquisa pelo pedido de mesma quebra
          IF (vtPedidosGerados.COUNT > 0) THEN
            FOR viIndicePedGerado IN vtPedidosGerados.FIRST..vtPedidosGerados.LAST LOOP
              -- Enquanto não encontrar o Pedido
              IF (vnNumPedidoRegistrarFalta IS NULL) THEN

                -- Se encontrou Pedido para mesma Quebra
                IF ((vtFalta(viIdxFalta).nCODCLI          = vtPedidosGerados(viIndicePedGerado).vnCodCli)    AND
                    (vtFalta(viIdxFalta).vCODFILIAL       = vtPedidosGerados(viIndicePedGerado).vvCodFilial) AND
                    (vtFalta(viIdxFalta).vQUEBRA1         = vtPedidosGerados(viIndicePedGerado).vvQuebra1)   AND
                    (vtFalta(viIdxFalta).vQUEBRA2         = vtPedidosGerados(viIndicePedGerado).vvQuebra2)   AND
                    (vtFalta(viIdxFalta).vQUEBRA3         = vtPedidosGerados(viIndicePedGerado).vvQuebra3)   AND
                    (vtFalta(viIdxFalta).vQUEBRA4         = vtPedidosGerados(viIndicePedGerado).vvQuebra4))  THEN
                  -- Guarda o Pedido e Data
                  vnNumPedidoRegistrarFalta  := vtPedidosGerados(viIndicePedGerado).vnNumPed;
                  vdDataPedidoRegistrarFalta := vtPedidosGerados(viIndicePedGerado).vdData;
                END IF;

              END IF;
            END LOOP; -- Fim do Laço de Processamento dos Pedidos Gerados
          END IF; -- Fim Condição Pesquisa pelo pedido de mesma quebra

          -- Se não encontrou Pedido a mesma quebra
          IF (vnNumPedidoRegistrarFalta IS NULL) THEN
            -- Pesquisa pelo pedido de mesmo cliente e filial
            IF (vtPedidosGerados.COUNT > 0) THEN
              FOR viIndicePedGerado IN vtPedidosGerados.FIRST..vtPedidosGerados.LAST LOOP
                -- Enquanto não encontrar o Pedido
                IF (vnNumPedidoRegistrarFalta IS NULL) THEN

                  -- Se encontrou Pedido para mesmo cliente e filial
                  IF ((vtFalta(viIdxFalta).nCODCLI    = vtPedidosGerados(viIndicePedGerado).vnCodCli)     AND
                      (vtFalta(viIdxFalta).vCODFILIAL = vtPedidosGerados(viIndicePedGerado).vvCodFilial)) THEN
                    -- Guarda o Pedido e Data
                    vnNumPedidoRegistrarFalta  := vtPedidosGerados(viIndicePedGerado).vnNumPed;
                    vdDataPedidoRegistrarFalta := vtPedidosGerados(viIndicePedGerado).vdData;
                  END IF;

                END IF;
              END LOOP; -- Fim do Laço de Processamento dos Pedidos Gerados
            END IF; -- Fim Condição Pesquisa pelo pedido de mesmo cliente e filial
          END IF; -- Fim Condição Se não encontrou Pedido para a mesma quebra

          -- Se encontrou Pedido para Registrar Falta
          IF (vnNumPedidoRegistrarFalta IS NOT NULL) THEN

            BEGIN
              -- Insere Falta no Log
              INSERT INTO PCFALTA
                        ( NUMPED
                        , DATA
                        , CODPROD
                        , CODUSUR
                        , CODCLI
                        , QT
                        , PVENDA
                        , CODFILIAL
                        , NUMSEQ )
                 VALUES ( vnNumPedidoRegistrarFalta
                        , vdDataPedidoRegistrarFalta
                        , vtFalta(viIdxFalta).nCODPROD
                        , vtFalta(viIdxFalta).nCODUSUR
                        , vtFalta(viIdxFalta).nCODCLI
                        , NVL(vtFalta(viIdxFalta).nQT,0) -- Quantidade de Faltas que serão guardadas
                        , vtFalta(viIdxFalta).nPVENDA
                        , vtFalta(viIdxFalta).vCODFILIAL
                        , 1 );

              -- Adiciona Falta ao Array para Atualização da Venda Perdida na Tabela PCEST
              vtFTA_CODFILIAL(NVL(vtFTA_CODFILIAL.COUNT,0)             + 1) := vtFalta(viIdxFalta).vCODFILIAL;
              vtFTA_CODPROD(NVL(vtFTA_CODPROD.COUNT,0)                 + 1) := vtFalta(viIdxFalta).nCODPROD;
              vtFTA_QT(NVL(vtFTA_QT.COUNT,0)                           + 1) := NVL(vtFalta(viIdxFalta).nQT,0);
              vtFTA_CODFILIALRETIRA(NVL(vtFTA_CODFILIALRETIRA.COUNT,0) + 1) := vtFalta(viIdxFalta).vCODFILIALRETIRA;

              -- Insere na Tabela Temporária de Faltas para Atendimento pelo Próximo Fornecedor da Prioridade
              nSEQFALTA := NVL(nSEQFALTA,0) + 1;
              INSERT INTO PCMED_TEMP_FALTAS_ATAC_VAR
                        ( NUMSUGESTAOREP
                        , SEQFALTA
                        , CODFILIALFALTA
                        , CODPRODFALTA
                        , CODCLI
                        , QTFALTA )
                 VALUES ( vnProxNumSugestaoRep
                        , nSEQFALTA
                        , vtFalta(viIdxFalta).vCODFILIAL
                        , vtFalta(viIdxFalta).nCODPROD
                        , vtFalta(viIdxFalta).nCODCLI
                        ,  NVL(vtFalta(viIdxFalta).nQT,0) );
            EXCEPTION
              WHEN OTHERS THEN
                NULL;
            END;

          END IF; -- Fim Condição Se encontrou Pedido para Registrar Falta

        END LOOP; -- Fim do Laço de Processamento das Faltas

        -- Executa Bloco de Atualização ForAll na Tabela PCEST
        IF (vtFTA_CODPROD.COUNT > 0) THEN
          FORALL viIdxFalta IN vtFTA_CODPROD.FIRST..vtFTA_CODPROD.LAST
            UPDATE PCEST
               SET PCEST.QTVENDAPERDIDA = NVL(PCEST.QTVENDAPERDIDA,0) + NVL(vtFTA_QT(viIdxFalta),0)
             WHERE (PCEST.CODPROD   = vtFTA_CODPROD(viIdxFalta))
               AND (PCEST.CODFILIAL = NVL(vtFTA_CODFILIAL(viIdxFalta),vtFTA_CODFILIALRETIRA(viIdxFalta)));
        END IF;

        -- Efetiva Transações
        COMMIT;

      END IF; -- Fim Condição se existem Faltas para Processar

    END IF; -- FIM CONDIÇÃO PARA LIBERAÇÃO DE PEDIDOS DE TRANSFERÊNCIA

    ---------------------
    -- GRAVA MENSAGENS --
    ---------------------
    PGRAVA_MENSAGENS;

    -----------------------------------------------------------------
    -- GRAVA CABECALHO E ITENS DA SUGESTAO DE REPOSICAO AUTOMATICA --
    -----------------------------------------------------------------
    IF (pi_vAutomaticoManual = 'A') THEN
      -- Se Chamado da Geração dos Pedidos a partir da Sugestão de Reposição
      IF    (pi_nOrigemChamada = 1) THEN
        GRAVA_SUGESTAOREPOSICAOCABITE(vnProxNumSugestaoRep);
      -- Se Geração dos Pedidos a partir das Faltas da Sugestão de Reposição
      ELSIF (pi_nOrigemChamada = 2) THEN
        GRAVA_FALTA_SUGESTAOREPOSICAO;
      END IF;
    END IF;

  EXCEPTION
    WHEN e_Tratado THEN
      -- Desfaz Transações
      ROLLBACK;

      -- Ocorreram Erros
      po_vOcorreramErros := 'S';
      po_vMsgErros       := vvMsgErroTratado;

      ------------------------
      -- ATUALIZA MENSAGENS --
      ------------------------
      PATUALIZA_MENSAGENS;

      -- Grava na Rejeição o motivo do Erro
      vMotivoRejeicao := 'Erro: ' || SUBSTR(po_vMsgErros,1,2000);
      -- Adiciona Rejeicao nas Mensagens
      vtMensagens(NVL(vtMensagens.COUNT,0)+1).vvMensagem := vMotivoRejeicao;

      ------------------------
      -- ATUALIZA MENSAGENS --
      ------------------------
      PGRAVA_MENSAGENS;

      -----------------------------------------------------------------
      -- GRAVA CABECALHO E ITENS DA SUGESTAO DE REPOSICAO AUTOMATICA --
      -----------------------------------------------------------------
      IF (pi_vAutomaticoManual = 'A') THEN
        -- Se Chamado da Geração dos Pedidos a partir da Sugestão de Reposição
        IF    (pi_nOrigemChamada = 1) THEN
          GRAVA_SUGESTAOREPOSICAOCABITE(vnProxNumSugestaoRep);
        -- Se Geração dos Pedidos a partir das Faltas da Sugestão de Reposição
        ELSIF (pi_nOrigemChamada = 2) THEN
          GRAVA_FALTA_SUGESTAOREPOSICAO;
        END IF;
      END IF;
    WHEN OTHERS THEN
      -- Desfaz Transações
      ROLLBACK;

      -- Ocorreram Erros
      po_vOcorreramErros := 'S';
      po_vMsgErros       := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM;

      ------------------------
      -- ATUALIZA MENSAGENS --
      ------------------------
      PATUALIZA_MENSAGENS;

      -- Grava na Rejeição o motivo do Erro
      vMotivoRejeicao := 'Erro: ' || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM,1,2000);
      -- Adiciona Rejeicao nas Mensagens
      vtMensagens(NVL(vtMensagens.COUNT,0)+1).vvMensagem := vMotivoRejeicao;

      ------------------------
      -- ATUALIZA MENSAGENS --
      ------------------------
      PGRAVA_MENSAGENS;

      -----------------------------------------------------------------
      -- GRAVA CABECALHO E ITENS DA SUGESTAO DE REPOSICAO AUTOMATICA --
      -----------------------------------------------------------------
      IF (pi_vAutomaticoManual = 'A') THEN
        -- Se Chamado da Geração dos Pedidos a partir da Sugestão de Reposição
        IF    (pi_nOrigemChamada = 1) THEN
          GRAVA_SUGESTAOREPOSICAOCABITE(vnProxNumSugestaoRep);
        -- Se Geração dos Pedidos a partir das Faltas da Sugestão de Reposição
        ELSIF (pi_nOrigemChamada = 2) THEN
          GRAVA_FALTA_SUGESTAOREPOSICAO;
        END IF;
      END IF;
  END PRC_PCMED_PED_TRANSF_ATAC_VAR;

 /*******************************************************************************
  *******************************************************************************
  *******************************************************************************
  Nome         : PRC_PCMED_FTA_TRANSF_ATAC_VAR
  Descricão    : Procedimento para Gerar os Pedidos de Faltas da Reposição
  #PROC3
  *******************************************************************************
  *******************************************************************************
  *******************************************************************************/
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
                                          po_vMsgErros           OUT VARCHAR2)
  IS

    -- Data da Geração
    vdDtGeracao                      DATE;
    -- Filial que está sendo Atendida
    vvCodFilialDestino               PCFILIAL.CODIGO%TYPE;
    -- Código do Produto de Destino
    vnCodProdDestino                 PCPRODUT.CODPROD%TYPE;
    -- Qtde. da Falta de Destino
    vnQtdeFaltaDestino               PCPEDI.QT%TYPE;
    -- Código Fornecedor que provocou a Falta
    vnCodFornecFalta                 PCFORNEC.CODFORNEC%TYPE;
    vnPrioridadeFornecFalta          PCPRODFORNREPOSICAO.PRIORIDADE%TYPE;
    -- Variáveis para pesquisa da próxima Prioridade
    vnCodFornecProximaPrioridade     PCFORNEC.CODFORNEC%TYPE;
    vbAchouProximaPrioridade         BOOLEAN;
    -- Variáveis para preencher a Tabela de Geração de Pedido de Reposição
    TYPE TRecItensReposicao          IS RECORD(
      vvCodFilial_O                  PCMED_TEMP_PED_ATAC_VAR.CODFILIAL_O%TYPE,
      vnCodProd_O                    PCMED_TEMP_PED_ATAC_VAR.CODPROD_O%TYPE,
      vvDescricao_O                  PCMED_TEMP_PED_ATAC_VAR.DESCRICAO_O%TYPE,
      vnPrecoTransf_O                PCMED_TEMP_PED_ATAC_VAR.PRECO_TRANSF_O%TYPE,
      vnQtdTransferir_O              PCMED_TEMP_PED_ATAC_VAR.QTD_TRANSFERIR_O%TYPE,
      vdDtGeracao                    PCMED_TEMP_PED_ATAC_VAR.DTGERACAO%TYPE);
    vrItensResposicao                TRecItensReposicao;
    -- Variáveis para Conversão de Embalagem
    vnQtUnitCx                       PCPRODUT.QTUNITCX%TYPE;
    vnPercArredonda                  PCPRODFILIAL.PERCARREDONDA%TYPE;
    -- PCCONSUM
    n_con_numcasasdeccusto           NUMBER;
    -- Identificação de erros ao pesquisar Parâmetros
    vvErroPesqParam                  VARCHAR2(1);
    vvMsgErroPesqParam               VARCHAR2(2000);
    -- Tipo de Sugestão
    vvTipoSugCompraTransf            PCMED_TEMP_TRANSF_ATAC_VAR.TIPO_SUG_COMPRA_TRANSF%TYPE;
    -- Mensagem de Dados Incompletos
    vvMsgDadosIncompletos            VARCHAR2(200);

    -- REGRA ESPECÍFICA - Ignorar Produto Master (HIS.00011.2018)
    vIGNORARPRODMASTER2312           PCREGRASEXCECAOMED.VALOR%TYPE;

    -- Parâmetro de Arredondamento da Sugestão Fracionada - DDMEDICA-6815
    vARREDONDARSUGESTAOFRACIONADA    PCPARAMREPOSICAOLOJAS.VALOR%TYPE;

    -- Cursor de Fornecedores da Prioridade
    CURSOR c_FornecPrioridade(pi_vCodFilial IN VARCHAR2,
                              pi_nCodProd   IN NUMBER) IS
      SELECT PRIORIDADE
           , CODFORNEC
        FROM PCPRODFORNREPOSICAO
       WHERE (CODFILIAL = pi_vCodFilial)
         AND CODPROD   = pi_nCodProd
       ORDER BY PRIORIDADE;

    ------------------------------------------------------------------------------
    -- Procedimento para Obter o Parâmetro da Filial NUMBER
    ------------------------------------------------------------------------------
    PROCEDURE POBTEM_PARAMFILIAL_NUMBER(pi_vCodFilial IN  VARCHAR2,
                                        pi_vNomeCampo IN  VARCHAR2,
                                        po_nValor     OUT NUMBER,
                                        po_vErro      OUT VARCHAR2,
                                        po_vMsgErro   OUT VARCHAR2) IS

      vvValorString PCPARAMFILIAL.VALOR%TYPE;

    BEGIN
      -- Inicializa Retornos
      po_nValor   := 0;
      po_vErro    := 'N';
      po_vMsgErro := NULL;

      -- Pesquisa Parametro
      BEGIN
        SELECT PCPARAMFILIAL.VALOR
          INTO vvValorString
          FROM PCPARAMFILIAL
         WHERE (PCPARAMFILIAL.CODFILIAL = pi_vCodFilial)
           AND (PCPARAMFILIAL.NOME      = pi_vNomeCampo);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          po_vErro      := 'S';
          po_vMsgErro   := 'Não foi encontrado o parâmetro "' || pi_vNomeCampo || '" na filial ' || pi_vCodFilial;
          vvValorString := NULL;
      END;

      -- Se não ocorreu erro ao pesquisar o parâmetro
      IF (po_vErro = 'N') THEN

        -- Tira Espaços em Branco do Valor
        vvValorString := TRIM(vvValorString);
        IF (vvValorString IS NULL) THEN
          vvValorString := '0';
        END IF;

        -- Converte String para Number
        BEGIN
           po_nValor := TO_NUMBER(vvValorString);
        EXCEPTION
          WHEN OTHERS THEN
            po_vErro      := 'S';
            po_vMsgErro   := 'Erro ao converter em numérico o texto "' || vvValorString || '" do parâmetro "' || pi_vNomeCampo || '" na filial ' || pi_vCodFilial;
            po_nValor     := 0;
        END;

      END IF; -- Fim Condição Se não ocorreu erro ao pesquisar o parâmetro

    END POBTEM_PARAMFILIAL_NUMBER;

    -------------------------------------------------------------------------------
    -- Função para Retornar a Quantidade de Caixas conforme Regra de Arredondamento
    -------------------------------------------------------------------------------
    FUNCTION FOBTEM_QTDE_CAIXAS(pi_nSugestaoUnitaria          IN NUMBER,
                                pi_nQtUnitCx                  IN NUMBER,
                                pi_nPercArredonda             IN NUMBER,
                                pi_vARREDONDARSUGESTAOFRACION IN VARCHAR2) -- DDMEDICA-6815
    RETURN NUMBER IS

      vnRetQtCaixas PCPRODUT.QTUNITCX%TYPE;
      vnQtdeSobra   PCEST.QTESTGER%TYPE;

    BEGIN

      -- Se tem Quantidade de Unidades da Caixa
      IF (NVL(pi_nQtUnitCx,0) > 0) THEN

        -- CALCULO DA QUANTIDADE DE VOLUMES PARA A SUGESTAO UNITARIA
        vnRetQtCaixas := TRUNC(NVL(pi_nSugestaoUnitaria,0) / NVL(pi_nQtUnitCx,0));
        vnQtdeSobra   := NVL(pi_nSugestaoUnitaria,0) - (NVL(vnRetQtCaixas,0) * NVL(pi_nQtUnitCx,0));
        -- SE REALIZA ARREDONDAMENTO PARA EMBALAGEM MASTER E SOBRA IGUAL OU SUPERIOR AO VALOR BASE DE ARREDONDAMENTO
        IF (NVL(pi_nPercArredonda,0) > 0) AND
           (NVL(vnQtdeSobra,0) >= (NVL(pi_nQtUnitCx,0) * (NVL(pi_nPercArredonda,0)/100))) THEN
          vnRetQtCaixas := vnRetQtCaixas + 1;
        END IF;
        -- NAO PERMITE SUGESTAO NEGATIVA
        IF (NVL(vnRetQtCaixas,0) < 0) THEN
          vnRetQtCaixas := 0;
        END IF;

      -- Se não tem Quantidade de Unidades da Caixa
      ELSE

        vnRetQtCaixas := 0;

      END IF;

      -- DDMEDICA-6815
      IF (pi_vARREDONDARSUGESTAOFRACION = 'S') THEN
        vnRetQtCaixas := ROUND(vnRetQtCaixas,0);
      END IF;

      -- Retorno da Função
      RETURN vnRetQtCaixas;

    END FOBTEM_QTDE_CAIXAS;

  /*******************************************************************************
                        INICIO DO PROCEDIMENTO PRINCIPAL
   *******************************************************************************/
  BEGIN

    -- REGRA ESPECÍFICA - Ignorar Produto Master (HIS.00011.2018)
   /*
    BEGIN
      SELECT VALOR
        INTO vIGNORARPRODMASTER2312
        FROM PCREGRASEXCECAOMED
       WHERE (NOME      = 'IGNORARPRODMASTER2312')
         AND (CODFILIAL = '99');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vIGNORARPRODMASTER2312 := 'N';
    END;
    */
    ----------------------------------------------------
    -- Parâmetro da Reposição de Lojas - MED-1896
    ----------------------------------------------------
    IF (NVL(pi_nOrigemChamada,0) > 0) THEN
      BEGIN
        SELECT VALOR
          INTO vIGNORARPRODMASTER2312
          FROM PCPARAMREPOSICAOLOJAS
         WHERE (NOME      = 'IGNORARPRODMASTER2312')
           AND (CODFILIAL = '99');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vIGNORARPRODMASTER2312 := NULL;
      END;
    ELSE
      BEGIN
        SELECT VALOR
          INTO vIGNORARPRODMASTER2312
          FROM PCPARAMREPOSICAOLOJAS
         WHERE (NOME      = 'IGNORARPRODMASTER2312')
           AND (CODFILIAL = '99');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vIGNORARPRODMASTER2312 := NULL;
      END;
    END IF;

    -- Inicializa Retorno indicando que não gerou Faltas
    po_vGerouFaltas := 'N';

    -- Limpa Tabela Temporária para receber os Dados para Geração dos Pedidos
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PCMED_TEMP_PED_ATAC_VAR';

    -- Data da Geração
    vdDtGeracao := TRUNC(SYSDATE);

    -- Parâmetro de Número de Casas Decimais do Custo
    POBTEM_PARAMFILIAL_NUMBER('99',
                              'CON_NUMCASASDECCUSTO',
                              n_con_numcasasdeccusto, --> Valor do Parâmetro
                              vvErroPesqParam,
                              vvMsgErroPesqParam);

    -- Parâmetro de Arredondamento da Sugestão Fracionada - DDMEDICA-6815
    vARREDONDARSUGESTAOFRACIONADA := F_OBTER_PARAM_REPOSICAO_LOJAS('99',
                                                                   'ARREDONDARSUGESTAOFRACIONADA',
                                                                   'N');

   /********************
    CURSOR COM AS FALTAS
    ********************/
    FOR vc_Faltas IN (SELECT SEQFALTA
                           , CODFILIALFALTA
                           , CODFORNEC
                           , CODCLI
                           , CODPRODFALTA
                           , QTFALTA
                        FROM PCMED_TEMP_FALTAS_ATAC_VAR) LOOP

      ----------------------------------------------
      -- Pesquisa o Próximo Fornecedor da Prioridade
      ----------------------------------------------

      -- Se a Falta foi Registrada a partir de um Cliente ------------------------
      IF (NVL(vc_Faltas.CODCLI,0) > 0) THEN

        -- Pesquisa a Filial de Destino pelo Código do Cliente da Transferência
        BEGIN
          SELECT CODIGO
            INTO vvCodFilialDestino
            FROM PCFILIAL
           WHERE (CODCLI = vc_Faltas.CODCLI)
             AND (ROWNUM = 1);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvCodFilialDestino := NULL;
        END;

        -- Pesquisa o Código do Fornecedor que provocou a Falta do Produto (Filial do Pedido de Transferência)
        BEGIN
          SELECT CODFORNEC
            INTO vnCodFornecFalta
            FROM PCFILIAL
           WHERE (CODIGO = vc_Faltas.CODFILIALFALTA)
             AND (ROWNUM = 1);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnCodFornecFalta := NULL;
        END;

        -- Pesquisa o Código do Produto de Destino (Código de Produto Filho se o Código do Produto da Falta for um Produto Master)
        IF (NVL(vIGNORARPRODMASTER2312,'N') = 'S') THEN
          -- Se a Transferência não foi na Embalagem Master,
          -- o Código do Produto de destino será o mesmo da Falta
          vnCodProdDestino   := vc_Faltas.CODPRODFALTA;
          -- Qtde. da Falta de Destino na mesma Embalagem da Falta
          vnQtdeFaltaDestino := NVL(vc_Faltas.QTFALTA,0);
        ELSE
          BEGIN
            SELECT CODPROD
              INTO vnCodProdDestino
              FROM PCPRODUT
             WHERE (CODPRODMASTER  = vc_Faltas.CODPRODFALTA)
               AND (CODPRODMASTER <> CODPROD) --> Desconsidera Produtos onde o Produto Master = Código do Produto (Não pegar o próprio Master como Destino)
               AND (ROWNUM        = 1);
            -- Pesquisa a Qtde. Unidades na Caixa Master
            BEGIN
              SELECT QTUNITCX
                INTO vnQtUnitCx
                FROM PCPRODUT
               WHERE (CODPROD = vnCodProdDestino);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vnQtUnitCx  := 0;
            END;
            -- MULTIPLICA A QUANTIDADE FALTAS PELA QTDE UNIDADES DA CAIXA
            vnQtdeFaltaDestino := NVL(vc_Faltas.QTFALTA,0) * NVL(vnQtUnitCx,0);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- Se a Transferência não foi na Embalagem Master,
              -- o Código do Produto de destino será o mesmo da Falta
              vnCodProdDestino   := vc_Faltas.CODPRODFALTA;
              -- Qtde. da Falta de Destino na mesma Embalagem da Falta
              vnQtdeFaltaDestino := NVL(vc_Faltas.QTFALTA,0);
          END;
        END IF;

      -- Se a Falta NÃO foi Registrada a partir de um Cliente --------------------
      ELSE

        -- A Filial de Destino será a Filial do Pedido de Compra que provocou a Falta
        vvCodFilialDestino := vc_Faltas.CODFILIALFALTA;

        -- Código do Fornecedor que provocou a Falta (Fornecedor do Pedido de Compra)
        vnCodFornecFalta   := vc_Faltas.CODFORNEC;

        -- O Código do Produto de Destino numa Falta de uma Compra será ele mesmo (Não terá conversão para Embalagem Master)
        vnCodProdDestino   := vc_Faltas.CODPRODFALTA;

        -- Qtde. da Falta de Destino na mesma Embalagem da Falta
        vnQtdeFaltaDestino := NVL(vc_Faltas.QTFALTA,0);

      END IF;

      -- Pesquisa próximo Fornecedor da Prioridade na Filial de Destino
      vbAchouProximaPrioridade     := FALSE;
      vnCodFornecProximaPrioridade := NULL;
      vnPrioridadeFornecFalta      := NULL;
      FOR vc_FornecPrioridade IN c_FornecPrioridade(vvCodFilialDestino,
                                                    vnCodProdDestino) LOOP
        -- Enquanto não achar o Fornecedor da próxima Prioridade
        IF (NOT vbAchouProximaPrioridade) THEN
          -- Se o Fornecedor da prioridade for o que provocou a Falta, guarda o número da Prioridade do Fornecedor da Falta
          IF (vc_FornecPrioridade.CODFORNEC = vnCodFornecFalta) THEN
            vnPrioridadeFornecFalta := vc_FornecPrioridade.PRIORIDADE;
          END IF;
          -- Ao encontrar a prioridade posterior à prioridade do fornecedor que provocou a Falta
          IF ((vnPrioridadeFornecFalta IS NOT NULL) AND
              (vc_FornecPrioridade.PRIORIDADE > vnPrioridadeFornecFalta)) THEN
            -- Achou o próximo Fornecedor da Prioridade
            vbAchouProximaPrioridade     := TRUE;
            vnCodFornecProximaPrioridade := vc_FornecPrioridade.CODFORNEC;
          END IF;
        END IF;
      END LOOP; -- Fim Cursor de pesquisa próximo Fornecedor da Prioridade

      -------------------------------------------------------------------------
      -- Se achar Fornecedor da próxima Prioridade, calcula a próxima Reposição
      -------------------------------------------------------------------------
      IF (vbAchouProximaPrioridade) THEN

        -- Verifica o Tipo de Sugestão de Reposição para o Fornecedor da próxima prioridade
        BEGIN
          SELECT 'T' -->> Se o Fornecedor for uma Filial, será uma Transferência
            INTO vvTipoSugCompraTransf
            FROM PCFILIAL
           WHERE (PCFILIAL.CODFORNEC = vnCodFornecProximaPrioridade)
             AND (ROWNUM             = 1);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- Se o Fornecedor não estiver cadastrado como Filial, será uma Compra
            vvTipoSugCompraTransf := 'C';
        END;

       /************************************
        Dados da Reposição por Transferência
        ************************************/
        IF    (vvTipoSugCompraTransf = 'T') THEN

          -- Pesquisa Filial de Origem da Transferência
          BEGIN
            SELECT CODIGO
              INTO vrItensResposicao.vvCodFilial_O
              FROM PCFILIAL
             WHERE (CODFORNEC = vnCodFornecProximaPrioridade)
               AND (ROWNUM    = 1);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vrItensResposicao.vvCodFilial_O := NULL;
          END;

          -- Pesquisa Código Produto de Origem, que na Transferência sempre será pelo Código do Produto Master
          IF (NVL(vIGNORARPRODMASTER2312,'N') = 'S') THEN
            -- Se a Transferência não foi na Embalagem Master,
            -- o Código do Produto de destino será o mesmo da Falta
            vrItensResposicao.vnCodProd_O := vnCodProdDestino;
            vnQtUnitCx                    := 1;
          ELSE
            BEGIN
              SELECT CODPRODMASTER
                   , QTUNITCX
                INTO vrItensResposicao.vnCodProd_O
                   , vnQtUnitCx
                FROM PCPRODUT
               WHERE (CODPROD = vnCodProdDestino);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vrItensResposicao.vnCodProd_O := NULL;
                vnQtUnitCx                    := 0;
            END;
          END IF;

          -- Se ocorrer conversão para Embalagem Master
          IF (NVL(vnCodProdDestino,0) <> NVL(vrItensResposicao.vnCodProd_O,0)) THEN

            -- Pesquisa o Percentual de Arredondamento
            BEGIN
              SELECT PERCARREDONDA
                INTO vnPercArredonda
                FROM PCPRODFILIAL
               WHERE (CODFILIAL = vvCodFilialDestino)
                 AND (CODPROD   = vnCodProdDestino);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vnPercArredonda := 0;
            END;

            -- ARREDONDAMENTO DA SUGESTAO UNITARIA DO PRODUTO DESTINO COM BASE NA EMBALAGEM MASTER
            -- (PARA NAO FRACIONAR O PRODUTO MASTER)
            vrItensResposicao.vnQtdTransferir_O := FOBTEM_QTDE_CAIXAS(NVL(vnQtdeFaltaDestino,0), -->> BASE = QUANTIDADE FALTAS NO DESTINO
                                                                      NVL(vnQtUnitCx,0),
                                                                      NVL(vnPercArredonda,0),
                                                                      vARREDONDARSUGESTAOFRACIONADA); -- DDMEDICA-6815;
            vnQtdeFaltaDestino                  := (NVL(vrItensResposicao.vnQtdTransferir_O,0) * NVL(vnQtUnitCx,0));

          -- Se NÃO ocorrer conversão para Embalagem Master
          ELSE

            -- Vai gerar Reposição na Quantidade que Faltou no Destino
            vrItensResposicao.vnQtdTransferir_O :=  NVL(vnQtdeFaltaDestino,0);

          END IF;

          -- Não Precisa calcular o Preço da Transferência, será calculado na PROC de Geração dos Pedidos
          vrItensResposicao.vnPrecoTransf_O := 0;

          -- Atualiza Data da Geração
          vrItensResposicao.vdDtGeracao   := vdDtGeracao;

       /*****************************
        Dados da Reposição por Compra
        *****************************/
        ELSIF (vvTipoSugCompraTransf = 'C') THEN

          -- Atualiza Código da Filial com a própria Filial de Destino da Compra
          vrItensResposicao.vvCodFilial_O     := vvCodFilialDestino;

          -- O Código de Produto de Origem de uma Compra sempre será o próprio Código Produto de Destino
          vrItensResposicao.vnCodProd_O       := vnCodProdDestino;

          -- Vai gerar Reposição na Quantidade que Faltou no Destino
          vrItensResposicao.vnQtdTransferir_O :=  NVL(vnQtdeFaltaDestino,0);

          -- PESQUISA PREÇO DA COMPRA DO PRODUTO DESTINO NO FORNECEDOR DA PRIORIDADE PARA A FILIAL DE DESTINO
          BEGIN
            SELECT ((((((((((
                       (CUSTOREP * (1 - (NVL(PERCDESC,0)/100)))
                     * (1 - (NVL(PERCDESC1,0)/100)))
                     * (1 - (NVL(PERCDESC2,0)/100)))
                     * (1 - (NVL(PERCDESC3,0)/100)))
                     * (1 - (NVL(PERCDESC4,0)/100)))
                     * (1 - (NVL(PERCDESC5,0)/100)))
                     * (1 - (NVL(PERCDESC6,0)/100)))
                     * (1 - (NVL(PERCDESC7,0)/100)))
                     * (1 - (NVL(PERCDESC8,0)/100)))
                     * (1 - (NVL(PERCDESC9,0)/100)))
                     * (1 - (NVL(PERCDESC10,0)/100))) AS PLIQ
              INTO vrItensResposicao.vnPrecoTransf_O
              FROM PCNEGFORNEC
             WHERE (PCNEGFORNEC.CODPROD   = vnCodProdDestino)
               AND (PCNEGFORNEC.CODFORNEC = vnCodFornecProximaPrioridade)
               AND (PCNEGFORNEC.CODFILIAL = vvCodFilialDestino);
             -- Arredonda com base no número de casas decimais do Parâmetro de Custo
             vrItensResposicao.vnPrecoTransf_O := ROUND(vrItensResposicao.vnPrecoTransf_O, N_CON_NUMCASASDECCUSTO);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              -- Se não achou, zera o Preços, porque não tem Preço de Compra
              vrItensResposicao.vnPrecoTransf_O := 0;
          END;

        END IF; -- Fim Condição Pesquisa Dados de Compra ou Transferência

        -- Insere na Tabela Temporária para Geração dos Pedidos
        IF ((vrItensResposicao.vvCodFilial_O    IS NOT NULL) AND
            (vvCodFilialDestino                 IS NOT NULL) AND
            (NVL(vrItensResposicao.vnCodProd_O,0)       > 0) AND
            (NVL(vrItensResposicao.vnQtdTransferir_O,0) > 0) AND
            (NVL(vnCodProdDestino,0)                    > 0)) THEN

          -- Pesquisa a Descrição do Produto de Origem
          BEGIN
            SELECT DESCRICAO
              INTO vrItensResposicao.vvDescricao_O
              FROM PCPRODUT
             WHERE (CODPROD = vrItensResposicao.vnCodProd_O);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vrItensResposicao.vvDescricao_O := NULL;
          END;

          -- Insere na Tabela Temporária para Geração dos Pedidos
          INSERT INTO PCMED_TEMP_PED_ATAC_VAR
                    ( CODFILIAL_O
                    , CODFILIALRETIRA_O
                    , CODFILIAL_D
                    , CODFORNECPRIORIDADE
                    , TIPO_SUG_COMPRA_TRANSF
                    , QUEBRA1
                    , QUEBRA2
                    , QUEBRA3
                    , QUEBRA4
                    , CODPROD_O
                    , DESCRICAO_O
                    , QTD_TRANSFERIR_O
                    , PRECO_TRANSF_O
                    , CODPROD_D
                    , DTGERACAO
                    , SEQFALTA )
             VALUES ( vrItensResposicao.vvCodFilial_O
                    , vrItensResposicao.vvCodFilial_O -->> Aqui a Filial Retira será sempre a mesma da Filial de Origem (Pedido de Compra)
                    , vvCodFilialDestino
                    , vnCodFornecProximaPrioridade
                    , vvTipoSugCompraTransf
                    , '0'
                    , 'N'
                    , '0'
                    , 'C'
                    , vrItensResposicao.vnCodProd_O
                    , vrItensResposicao.vvDescricao_O
                    , vrItensResposicao.vnQtdTransferir_O
                    , vrItensResposicao.vnPrecoTransf_O
                    , vnCodProdDestino
                    , vdDtGeracao
                    , vc_Faltas.SEQFALTA );

          -- Atualiza Tabela Temporária de Faltas
          UPDATE PCMED_TEMP_FALTAS_ATAC_VAR
             SET CODFILIAL_O            = vrItensResposicao.vvCodFilial_O
               , CODPROD_O              = vrItensResposicao.vnCodProd_O
               , QTFALTA_O              = vrItensResposicao.vnQtdTransferir_O
               , CODFILIAL_D            = vvCodFilialDestino
               , CODPROD_D              = vnCodProdDestino
               , QTFALTA_D              = vnQtdeFaltaDestino
               , CODFORNECPRIORIDADE    = vnCodFornecProximaPrioridade
               , TIPO_SUG_COMPRA_TRANSF = vvTipoSugCompraTransf
           WHERE (SEQFALTA = vc_Faltas.SEQFALTA);

          -- Atualiza Retorno indicando que foram geradas Faltas
          po_vGerouFaltas := 'S';

        ELSE

          -- Dados que estão incompletos
          vvMsgDadosIncompletos := ' ';
          IF (vrItensResposicao.vvCodFilial_O IS NULL) THEN
            vvMsgDadosIncompletos := vvMsgDadosIncompletos || ',Fil.Origem';
          END IF;
          IF (vvCodFilialDestino IS NULL) THEN
            vvMsgDadosIncompletos := vvMsgDadosIncompletos || ',Fil.Destino';
          END IF;
          IF (NVL(vrItensResposicao.vnCodProd_O,0) = 0) THEN
            vvMsgDadosIncompletos := vvMsgDadosIncompletos || ',Prod.Origem';
          END IF;
          IF (NVL(vrItensResposicao.vnQtdTransferir_O,0) = 0) THEN
            vvMsgDadosIncompletos := vvMsgDadosIncompletos || ',Qt.Falta';
          END IF;
          IF (NVL(vnCodProdDestino,0) = 0) THEN
            vvMsgDadosIncompletos := vvMsgDadosIncompletos || ',Prod.Destino';
          END IF;
          vvMsgDadosIncompletos := SUBSTR(vvMsgDadosIncompletos,3,200); -- Tira primeira vírgula e espaço em branco

          -- Atualiza Tabela Temporária de Faltas
          UPDATE PCMED_TEMP_FALTAS_ATAC_VAR
             SET CODFILIAL_O            = vrItensResposicao.vvCodFilial_O
               , CODPROD_O              = vrItensResposicao.vnCodProd_O
               , QTFALTA_O              = vrItensResposicao.vnQtdTransferir_O
               , CODFILIAL_D            = vvCodFilialDestino
               , CODPROD_D              = vnCodProdDestino
               , QTFALTA_D              = vnQtdeFaltaDestino
               , REJEICAOINICIAL        = 'S'
               , OBSERVACAOREJEICAO     = SUBSTR('Dados incompletos para processamento da falta: ' || vvMsgDadosIncompletos,1,240)
               , CODFORNECPRIORIDADE    = vnCodFornecProximaPrioridade
               , TIPO_SUG_COMPRA_TRANSF = vvTipoSugCompraTransf
           WHERE (SEQFALTA = vc_Faltas.SEQFALTA);

        END IF; -- Fim Condição para Inserir na Tabela Temporária para Geração dos Pedidos

      -- Se não achou o Fornecedor da Próxima Prioridade
      ELSE

        -- Atualiza Tabela Temporária de Faltas
        UPDATE PCMED_TEMP_FALTAS_ATAC_VAR
           SET CODFILIAL_O            = vc_Faltas.CODFILIALFALTA
             , CODPROD_O              = vc_Faltas.CODPRODFALTA
             , QTFALTA_O              = vc_Faltas.QTFALTA
             , CODFILIAL_D            = vvCodFilialDestino
             , CODPROD_D              = vnCodProdDestino
             , QTFALTA_D              = vnQtdeFaltaDestino
             , REJEICAOINICIAL        = 'S'
             , OBSERVACAOREJEICAO     = 'Não foi encontrado Fornecedor de próxima Prioridade de Atendimento'
         WHERE (SEQFALTA = vc_Faltas.SEQFALTA);

      END IF; -- Fim Condição se achar o Fornecedor da Próxima Prioridade

    END LOOP; -- FIM CURSOR COM AS FILIAIS DE ORIGEM DAS FALTAS

    -- EFETIVA TRANSACOES
    COMMIT;

    -- SE GEROU FALTAS, EXECUTA PROCEDURE PARA GERAÇÃO DOS PEDIDOS DAS FALTAS
    IF (po_vGerouFaltas = 'S') THEN

      PRC_PCMED_PED_TRANSF_ATAC_VAR(2, -- Chamado da Geração dos Pedidos a partir das Faltas
                                    pi_nCodMatricula,
                                    pi_vGeraPedSemEstoque,
                                    pi_vAutomaticoManual,
                                    pi_vLiberaPedido,
                                    pi_vGuardaFalta,
                                    pi_vTipoSugestao,
                                    po_nQtdePedidosGerados,
                                    po_vOcorreramErros,
                                    po_vMsgErros);
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      -- Desfaz Transações
      ROLLBACK;

      -- Ocorreram Erros
      po_vOcorreramErros := 'S';
      po_vMsgErros       := 'Erro Proc. Falta: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM;
  END PRC_PCMED_FTA_TRANSF_ATAC_VAR;

END PKG_REPOSICAOLOJAS;
