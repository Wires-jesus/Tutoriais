CREATE OR REPLACE PACKAGE FISCAL IS

   VMENSAGEMPISCOFINS VARCHAR2(4000);
   VCODFILIAL         VARCHAR2(2);
   VVLPIS_NF          NUMBER;
   VVLCOFINS_NF       NUMBER;

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

   FUNCTION NFE_DENEGADA(P_SITUACAONFE IN VARCHAR2) RETURN VARCHAR2;
   FUNCTION CTE_DENEGADO(P_SITUACAOCTE IN VARCHAR2) RETURN VARCHAR2;
END;

