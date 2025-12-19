CREATE OR REPLACE PACKAGE FISCAL IS

   VMENSAGEMPISCOFINS VARCHAR2(4000);
   VCODFILIAL         VARCHAR2(2);
   VVLPIS_NF          NUMBER;
   VVLCOFINS_NF       NUMBER;

  TYPE TIPO_GRUPO_COMPRA_GOV IS RECORD (
     TIPO_ORGAOPUBLICO        VARCHAR2(2),
     PERC_RED_ORGAO_PUB       NUMBER(7,4),
     PERC_CBS_COMPRA_GOV      NUMBER(7,4),
     VALOR_CBS_COMPRA_GOV     NUMBER(23,10),          
     PERC_IBS_UF_COMPRA_GOV   NUMBER(7,4),
     VALOR_IBS_UF_COMPRA_GOV  NUMBER(23,10),
     PERC_IBS_MUN_COMPRA_GOV  NUMBER(7,4),
     VALOR_IBS_MUN_COMPRA_GOV NUMBER(23,10));

  TYPE TIPO_TRIBUT_REFORMA IS RECORD (
      CODFILIAL         VARCHAR2(2),
      CODCLI            NUMBER(9),
      UF_CLIENTE        VARCHAR2(2),
      CODFORNEC         NUMBER(6),
      UF_FORNECEDOR     VARCHAR2(2),
      TIPO_OPERACAO     VARCHAR2(1),
      DEVOLUCAO         VARCHAR2(1),
      CODIGO_MUNICIPIO  VARCHAR2(10),
      TIPO_IMPOSTO      VARCHAR2(6),
      CODIGO_ENDERECO_CLI NUMBER(6),
      --Filtros adicionais
      CODPROD           NUMBER(6),
      NCM               VARCHAR2(15),
      CFOP              VARCHAR2(15),
      CONSUMIDOR_FINAL  VARCHAR2(1),
      TIPO_EMPRESA      VARCHAR2(4),
      TIPO_PESSOA       VARCHAR2(1),
      CONTRIBUINTE      VARCHAR2(1),
      ORGAO_PUBLICO     VARCHAR2(1),
      ORIGEM_MERCADORIA VARCHAR2(1),
      TIPO_MERC         VARCHAR2(2),
      --Valores para formação da base de cáluclo por meio da fórmula
      VALOR_PRODUTO         NUMBER(18,6),
      VALOR_ICMS_ST         NUMBER(18,6),
      VALOR_FCP_ST          NUMBER(18,6),
      VALOR_IPI             NUMBER(18,6),
      VALOR_FRETE           NUMBER(18,6),
      VALOR_OUTROS          NUMBER(18,6),
      VALOR_SEGURO          NUMBER(18,6), -- vSeg
      VALOR_DESCONTO        NUMBER(18,6), -- vDesc
      VALOR_VII             NUMBER(18,6), -- vII
      VALOR_PIS             NUMBER(18,6), -- vPIS
      VALOR_COFINS          NUMBER(18,6), -- vCOFINS
      VALOR_ICMS            NUMBER(18,6), -- vICMS
      VALOR_ICMSUFDEST      NUMBER(18,6), -- vICMSUFDest
      VALOR_FCP             NUMBER(18,6), -- vFCP
      VALOR_FCPUFDEST       NUMBER(18,6), -- vFCPUFDest
      --Dados retorno  CBSIBS
      CODIGO_TRIBUTACAO_CBSIBS        NUMBER(10),
      FORMULA_BASE_CALCULO_CBSIBS     VARCHAR2(4000),
      FORMULA_VALOR_TRIBUTO_CBSIBS    VARCHAR2(4000),
      COD_FORMULA_BASE_CBSIBS VARCHAR2(200),
      SOMATOTALNF_CBSIBS              VARCHAR2(1),
      CST_CBSIBS                      VARCHAR2(3),
      CCLASSTRIB_CBSIBS               VARCHAR2(6),
      VALOR_BASE_CBSIBS               NUMBER(23,10),
      --Retorno valores CBS
      PERC_CBS                NUMBER(7,4),
      PERC_RED_CBS            NUMBER(7,4),
      ALIQ_EFETIVA_CBS        NUMBER(7,4),
      VALOR_CBS               NUMBER(23,10),
      FORMULA_VALOR_TRIBUTO_CBS VARCHAR2(4000),
      --Retorno valores IBS UF
      PERC_IBS_UF             NUMBER(7,4),
      PERC_RED_ALIQ_IBS_UF    NUMBER(7,4),
      ALIQ_EFETIVA_IBS_UF     NUMBER(7,4),
      VALOR_IBS_UF            NUMBER(23,10),
      FORMULA_VALOR_TRIBUTO_IBS_UF VARCHAR2(4000),
      --Retorno valores IBS
      PERC_IBS_MUN           NUMBER(7,4),
      PERC_RED_ALIQ_IBS_MUN  NUMBER(7,4),
      ALIQ_EFETIVA_IBS_MUN   NUMBER(7,4),
      VALOR_IBS_MUN          NUMBER(23,10),
      FORMULA_VALOR_TRIBUTO_IBS_MUN VARCHAR2(4000),
      --Retornos valores IS
      CODIGO_TRIBUTACAO_IS        NUMBER(10),
      FORMULA_BASE_CALCULO_IS     VARCHAR2(4000),
      FORMULA_VALOR_TRIBUTO_IS    VARCHAR2(4000),
      COD_FORMULA_BASE_CALCULO_IS VARCHAR2(200),
      SOMATOTALNF_IS              VARCHAR2(1),
      CST_IS                      VARCHAR2(3),
      CCLASSTRIB_IS               VARCHAR2(6),
      VALOR_BASE_IS               NUMBER(23,10),
      PERC_IS                     NUMBER(7,4),
      VALOR_IS                    NUMBER(23,10), -- vIS
      VLTOTALIBS                  NUMBER(23,10),
      -- Retorno valores Compra Governamental
      COMPRA_GOVERNAMENTAL        TIPO_GRUPO_COMPRA_GOV
   );


   FUNCTION FORMATAR_CST_ICMS(PSITTRIBUT    IN VARCHAR2,
                              PIMPORTADO    IN VARCHAR2,
                              PORIGMERCTRIB IN VARCHAR2,
                              PDATAOPER IN DATE DEFAULT TO_DATE('01/01/1950'))
      RETURN VARCHAR2;

   FUNCTION GET_CODTRIBEXCECAO_PISCOFINS(PCODTRIBPISCOFINS IN NUMBER,
                                         PCODFISCAL        IN NUMBER,
                                         PCODOPER          IN VARCHAR2,
                                         PCONDVENDA        IN NUMBER,
                                         PCLIENTESUFRAMA   IN VARCHAR2,
                                         PPRODUTOIMPORTADO IN VARCHAR2,
                                         PTIPOCLIENT       IN VARCHAR2,
                                         PPISCOFINSCUM     IN VARCHAR2,
                                         PFILIALORIGEM     IN VARCHAR2,
                                         PDATAVIGENCIA     IN DATE,
                                         PCODIGOCLIENTE    IN VARCHAR2,
                                         PCODEXCTRIBPISCOFINS IN INTEGER,
                                         PNCM    IN VARCHAR2)
      RETURN NUMBER;

   FUNCTION CALCULARPISCOFINS_VENDA(NUMTRANSACAO IN NUMBER,
                                    MSG          OUT VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION RETORNAULTIMAENTRADA(PCOPROD IN NUMBER,
                                 PDATA   IN DATE,
                                 PFILIAL IN VARCHAR2)
      RETURN NUMBER;

   FUNCTION GET_DADOS_ICMS(P_CODFILIAL   IN VARCHAR2
                           ,P_TIPO       IN VARCHAR2
                           ,P_CURSOR     IN VARCHAR2
                           ,P_ROWIDPCMOV IN VARCHAR2
                           ,P_ESTENT     IN VARCHAR2
                           ,P_CHAVENFE   IN VARCHAR2
                           ,P_CONSLIVRO  IN VARCHAR2 := 'S')
      RETURN NUMBER;

   FUNCTION CALCULARPISCOFINS_TRANSPORTE(NUMTRANSACAO IN NUMBER,
                                         MSG          OUT VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION CALCULARPISCOFINS_DEVOLUCAO(NUMTRANSACAO IN NUMBER,
                                        MSG          OUT VARCHAR2)
      RETURN VARCHAR2;

   PROCEDURE CALCULAR_RATEIO_DESPESAS(P_TRANSACAO IN NUMBER,
                                      MSG         OUT VARCHAR2);

   PROCEDURE CALCULAR_RATEIO_DESPESAS_DEVOL(P_TRANSACAO IN NUMBER,
                                            MSG         OUT VARCHAR2);

   FUNCTION GET_DADOS_TRIBUTACAO_IPI(P_CODCLI           IN NUMBER,
                                     P_CODPROD          IN NUMBER,
                                     P_CODFILIAL        IN VARCHAR2,
                                     P_DATAOPERACAO     IN DATE,
                                     P_CST_ENTRADA      OUT NUMBER,
                                     P_CST_SAIDA        OUT NUMBER,
                                     P_GERABASEALIQZERO OUT VARCHAR2,
                                     P_MSG              OUT VARCHAR2,
                                     P_CODFISCAL        IN NUMBER DEFAULT NULL,
                                     P_TIPO_VENDA      IN VARCHAR2 DEFAULT NULL,
                                     P_TIPO_ENTRADA    IN VARCHAR2 DEFAULT NULL,
                                     P_CODIGO_OPERACAO IN VARCHAR2 DEFAULT NULL,
                                     P_FINALIDADENFE   IN VARCHAR2 := 'N')
      RETURN VARCHAR2;

   FUNCTION GET_DADOS_TRIBUTACAO_IPI(P_CODCLI           IN NUMBER,
                                     P_CODPROD          IN NUMBER,
                                     P_CODFILIAL        IN VARCHAR2,
                                     P_DATAOPERACAO     IN DATE,
                                     P_CST_ENTRADA      OUT NUMBER,
                                     P_CST_SAIDA        OUT NUMBER,
                                     P_GERABASEALIQZERO OUT VARCHAR2,
                                     P_MSG              OUT VARCHAR2,
                                     P_CODFISCAL        IN NUMBER DEFAULT NULL,
                                     P_TIPO_VENDA      IN VARCHAR2 DEFAULT NULL,
                                     P_TIPO_ENTRADA    IN VARCHAR2 DEFAULT NULL,
                                     P_CODIGO_OPERACAO IN VARCHAR2 DEFAULT NULL,
                                     P_CODENQENTRADA   OUT VARCHAR2,
                                     P_CODENQSAIDA     OUT VARCHAR2,
                                     P_FINALIDADENFE   IN VARCHAR2 := 'N')
      RETURN VARCHAR2;

   FUNCTION CALCULARDESONERACAOICMS_SAIDA(NUMTRANSACAO IN NUMBER,
                                          MSG OUT VARCHAR2)
      RETURN VARCHAR2;

   PROCEDURE GRAVAR_ENQUADRAMENTO_IPI(P_TRANSACAO IN NUMBER,
                                      P_MOVIMENTO IN VARCHAR2,
                                      MSG OUT VARCHAR2);

   PROCEDURE GERA_CONTAS_CONTABEIS_SPED(PCODFILIAL IN VARCHAR2,
                                        PDATA1     IN DATE,
                                        PDATA2     IN DATE,
                                        PTRANSACAO IN NUMBER,
                                        PTIPOMOV   IN VARCHAR2);

   PROCEDURE GERA_CONTAS_CONTAB_SPED_ITEM(PCODFILIAL IN VARCHAR2,
                                          PESPECIE   IN VARCHAR2,
                                          PCFOP      IN NUMBER,
                                          PCST       IN VARCHAR2,
                                          PNUMTRANSITEM IN NUMBER);

  PROCEDURE GERA_NATUREZA_RECEITA(PCODFILIAL IN VARCHAR2,
                                  PDATA1     IN DATE,
                                  PDATA2     IN DATE,
                                  PTRANSACAO IN NUMBER,
                                  PREPROCESSAR_TODOS   IN VARCHAR2);

   PROCEDURE GERA_NATUREZA_RECEITA_ITEM(PCODFILIAL IN VARCHAR2,
                                        PDATA      IN DATE,
                                        PCODPROD   IN NUMBER,
                                        PCST       IN VARCHAR2,
                                        PNCM       IN VARCHAR2,
                                        PEXTIPI    IN NUMBER,
                                        PNUMTRANSITEM IN NUMBER);

   FUNCTION GET_CSTPISCONFINS_DEV(P_TRIB IN VARCHAR2,
                                  P_DATA IN DATE,
                                  P_CONSUMIDOR IN VARCHAR2)
      RETURN NUMBER;

   PROCEDURE CALCULAR_PARTILHA_ICMS_1_5(P_CODFILIAL     IN VARCHAR2
                                        ,P_CODCLI       IN NUMBER
                                        ,P_UFOPERCONSUM IN VARCHAR2
                                        ,P_UFENTREGA    IN VARCHAR2
                                        ,P_DATAOPER     IN DATE
                                        ,P_VLPRODUTO    IN NUMBER
                                        ,P_CODTRIBUT    IN NUMBER
                                        ,P_CODPROD      IN NUMBER
                                        ,P_CFOP         IN NUMBER
                                        ,P_CST          IN VARCHAR2
                                        ,P_RETORNO      OUT VARCHAR2
                                        ,P_CODMSG       OUT NUMBER
                                        ,P_MSG          OUT VARCHAR2);

   PROCEDURE CALCULAR_PARTILHA_ICMS_1_6(P_CODFILIAL     IN VARCHAR2
                                        ,P_CODCLI       IN NUMBER
                                        ,P_UFOPERCONSUM IN VARCHAR2
                                        ,P_UFENTREGA    IN VARCHAR2
                                        ,P_DATAOPER     IN DATE
                                        ,P_VLPRODUTO    IN NUMBER
                                        ,P_CODTRIBUT    IN NUMBER
                                        ,P_CODPROD      IN NUMBER
                                        ,P_CFOP         IN NUMBER
                                        ,P_BASEICMS     IN NUMBER
                                        ,P_CST          IN VARCHAR2
                                        ,P_RETORNO      OUT VARCHAR2
                                        ,P_CODMSG       OUT NUMBER
                                        ,P_MSG          OUT VARCHAR2);

   PROCEDURE CALCULAR_PARTILHA_ICMS_1_7(P_CODFILIAL     IN VARCHAR2
                                        ,P_CODCLI       IN NUMBER
                                        ,P_UFOPERCONSUM IN VARCHAR2
                                        ,P_UFENTREGA    IN VARCHAR2
                                        ,P_DATAOPER     IN DATE
                                        ,P_VLPRODUTO    IN NUMBER
                                        ,P_CODTRIBUT    IN NUMBER
                                        ,P_CODPROD      IN NUMBER
                                        ,P_CFOP         IN NUMBER
                                        ,P_BASEICMS     IN NUMBER
                                        ,P_CST          IN VARCHAR2
                                        ,P_ROTINA       in varchar2  := 'X'
                                        ,P_RETORNO      OUT VARCHAR2
                                        ,P_CODMSG       OUT NUMBER
                                        ,P_MSG          OUT VARCHAR2);

   PROCEDURE CALCULAR_PARTILHA_ICMS_1_8(P_NUMTRANSACAO in number
                                       ,P_TIPOMOV      varchar2
                                       ,P_ATIVARLOG    varchar2 := 'N'
                                       ,P_MSG      out varchar2);

   FUNCTION F_CALCULAR_PARTILHA_ICMS_1_9(P_NUMTRANSACAO in number
                                        ,P_TIPOMOV      varchar2
                                        ,P_ATIVARLOG    varchar2 := 'N'
                                        ,P_CODMSG   out varchar2
                                        ,P_MSG      out varchar2)
   RETURN VARCHAR2;

   PROCEDURE OBTERCODIGOCEST_1_3(P_CODPROD       IN NUMBER
                                 ,P_CSTICMS      IN VARCHAR2
                                 ,P_TIPOMOV      IN VARCHAR2
                                 ,P_TIPOOPERACAO IN VARCHAR2
                                 ,P_CODOPER      IN VARCHAR2
                                 ,P_CFOP         IN NUMBER
                                 ,P_CODPART      IN NUMBER
                                 ,P_VLST         IN NUMBER
                                 ,P_CODFILIAL    IN VARCHAR2
                                 ,P_CODCEST      OUT VARCHAR2
                                 ,P_CODMSG       OUT NUMBER
                                 ,P_MSG          OUT VARCHAR2);

   FUNCTION PODE_DEDUZIR_ICMS_BCPISCOFINS(P_CODFILIAL IN VARCHAR2,
                                          P_DATA IN DATE)
      RETURN VARCHAR2;

   FUNCTION GET_HORACERTA_TIMEZONE(P_UF VARCHAR2) RETURN DATE;

   FUNCTION OBTER_ALIQUOTAS_PISCOFINS(P_CODPROD   IN NUMBER,
                                      P_CODFISCAL IN NUMBER,
                                      P_CODOPER   IN VARCHAR2,
                                      P_CONDVENDA IN NUMBER,
                                      P_CODTRIB   IN NUMBER,
                                      P_CODIGO_FILIAL  IN VARCHAR2,
                                      P_DATAO_PERACAO  IN DATE,
                                      P_CODIGO_CLIENTE IN VARCHAR2,
                                      P_NCM            IN VARCHAR2,
                                      P_PERPIS           OUT NUMBER,
                                      P_PERCOFINS        OUT NUMBER,
                                      P_MENSAGEM_RETORNO OUT VARCHAR2)
      RETURN BOOLEAN;

   FUNCTION GET_NATUREZAOPERACAO(P_CODFISCAL IN VARCHAR2,
                                P_CODOPER IN VARCHAR2,
                                P_CODROTINAEMISSAO IN VARCHAR2 := 0) RETURN VARCHAR2;

   FUNCTION NFE_DENEGADA(P_SITUACAONFE IN VARCHAR2,
                         P_DATADOCUMENTOS IN DATE := SYSDATE) RETURN VARCHAR2;
   FUNCTION CTE_DENEGADO(P_SITUACAOCTE IN VARCHAR2) RETURN VARCHAR2;
   FUNCTION GET_DESCRICAO_NATUREZA_OP(
                                      P_CODFISCAL       NUMBER,
                                      P_CODOPER         VARCHAR2,
                                      P_CODROTINAORIGEM NUMBER DEFAULT 0,
                                      P_CHEQUEMORADIA VARCHAR2 DEFAULT 'N'
                                      ) RETURN VARCHAR2;

   FUNCTION GET_FORMULA_CREDPRESUMIDO (
                                      P_CODBENEFICIOFISCAL IN VARCHAR2,
                                      P_CODST IN NUMBER,
                                      P_ALIQICMSNF IN NUMBER,
                                      P_CONTRIBUINTECONSFINAL IN VARCHAR2,
                                      P_TIPO_EMPRESA IN VARCHAR2 DEFAULT NULL,
                                      P_TIPO_PESSOA IN VARCHAR2 DEFAULT NULL,
                                      P_ORIGEM_MERC IN VARCHAR2 DEFAULT NULL,
                                      P_SIT_TRIBUT IN VARCHAR2 DEFAULT NULL,
                                      P_CODFISCAL IN NUMBER DEFAULT NULL,
                                      P_NCM IN VARCHAR2 DEFAULT NULL,
                                      P_ALIQCREDPRESUMIDO OUT NUMBER,
                                      P_FORMULACREDPRES OUT VARCHAR2,
                                      P_CCREDPRESUMIDO OUT VARCHAR2,
                                      P_IDCREDPRESUMIDO OUT NUMBER

    )
    RETURN VARCHAR2;

   FUNCTION GET_DADOS_CREDITOPRESUMIDO (
                                        P_CODBENEFICIOFISCAL IN VARCHAR2, -- Código Beneficio Fiscal
                                        P_CODST IN NUMBER, -- Figura tributária rotina 514
                                        P_ALIQICMSNF IN NUMBER, -- Alíquota ICMS NF
                                        P_CONTRIBUINTECONSFINAL IN VARCHAR2 DEFAULT NULL, -- Contribuinte consumidor final (Opcional)
                                        P_TIPO_EMPRESA IN VARCHAR2 DEFAULT NULL, -- Tipo de empresa (Opcional)
                                        P_TIPO_PESSOA IN VARCHAR2 DEFAULT NULL, -- Tipo de pessoa (Opcional)
                                        P_ORIGEM_MERC IN VARCHAR2 DEFAULT NULL, -- Origem da mercadoria (Opcional)
                                        P_SIT_TRIBUT IN VARCHAR2 DEFAULT NULL, -- Situação tributária (Opcional)
                                        P_CODFISCAL IN NUMBER DEFAULT NULL, -- Código fiscal(CFOP) (Opcional)
                                        P_NCM IN VARCHAR2 DEFAULT NULL, -- NCM da mercadoria (Opcional)
                                        P_PUNITCONT IN NUMBER DEFAULT 0, -- Preço unitário
                                        P_VLIPI IN NUMBER DEFAULT 0, -- Valor do IPI

                                        P_VLFRETE IN NUMBER DEFAULT 0, -- Valor do frete
                                        P_VLST IN NUMBER DEFAULT 0, -- Valor do ST
                                        P_VLOUTROS IN NUMBER DEFAULT 0, -- Valor de outros
                                        P_BASEICMS IN NUMBER DEFAULT 0, -- Base ICMS
                                        P_PERCBASERED IN NUMBER DEFAULT 0, -- Redução Base ICMS
                                        -- Declarando as variáveis de saída
                                        P_BASECREDITOPRESUMIDO OUT PCMOV.BASEICMS%TYPE,
                                        P_VLCREDITOPRESUMIDO OUT PCMOV.VLCREDPRESUMIDO%TYPE,
                                        P_ALIQCREDITOPRESUMIDO OUT PCMOV.PERCCREDICMPRESUMIDO%TYPE,
                                        P_CCREDPRESUMIDO OUT PCMOVCOMPLE.CCREDPRESUMIDO%TYPE,
                                        P_IDCREDPRESUMIDO OUT NUMBER,
                                        P_MSG OUT VARCHAR2
  )
     RETURN VARCHAR2;

  FUNCTION CALCULAR_CREDITOPRESUMIDO(P_NUMTRANSACAO in number
                                     ,P_TIPOMOV      varchar2
                                     ,P_ATIVARLOG    varchar2 := 'N'
                                     ,P_MSG      out varchar2)
  RETURN VARCHAR2;


  FUNCTION CALCULAR_TODOS_TRIBUTOS(P_PARAMETROS in TIPO_TRIBUT_REFORMA,
                        P_MSG      out varchar2)
  RETURN TIPO_TRIBUT_REFORMA;

  FUNCTION CALCULAR_CBSIBS(P_PARAMETROS in TIPO_TRIBUT_REFORMA,
                        P_MSG      out varchar2)
  RETURN TIPO_TRIBUT_REFORMA;


  FUNCTION CALCULAR_IS(P_PARAMETROS in TIPO_TRIBUT_REFORMA,
                        P_MSG      out varchar2)
  RETURN TIPO_TRIBUT_REFORMA;


  FUNCTION CALCULAR_CBSIBS(P_PARAMETROS in TIPO_TRIBUT_REFORMA,
                        P_USASUFIXO IN VARCHAR2,
                        P_MSG      out varchar2)
  RETURN TIPO_TRIBUT_REFORMA;


  FUNCTION CALCULAR_IS(P_PARAMETROS in TIPO_TRIBUT_REFORMA,
                       P_USASUFIXO IN VARCHAR2,
                       P_MSG      out varchar2)
  RETURN TIPO_TRIBUT_REFORMA;

  PROCEDURE CADASTRAR_TRIBUTACAO_PADRAO;

END;
