CREATE OR REPLACE PACKAGE PKG_INTEGRACAOCONTABIL IS
  VD_DATALANCTO            DATE;
  VD_DATAINTEGRACAO        DATE;
  VS_FORMADTCONTABILIZACAO VARCHAR2(1);
  VS_DOCPESQUISADO         VARCHAR2(30);
  VS_CONTA                 VARCHAR2(40);
  VS_NUMTRANSCENTROCUSTO   VARCHAR2(12);
  VS_TEMCONTAINEXISTENTE   CHAR(1);
  VS_NATUREZA              CHAR(1);
  VS_HISTORICO             VARCHAR2(5000);
  VS_DOCUMENTO             VARCHAR2(30);
  VN_NUMTRANSACAO          NUMBER;
  VN_NUMTRANSOPERACAO      NUMBER;
  VN_NUMSEQ                NUMBER;
  VN_TOTALCREDITO          NUMBER;
  VN_TOTALDEBITO           NUMBER;
  VS_SEQGERADO             CHAR(1);
  VS_CODFILIAL             VARCHAR2(2);
  VS_BUSCARDADOSPELADATA   VARCHAR2(2);

  VN_POSICAO              NUMBER;
  VN_POSICAO_EM_ALTERACAO NUMBER;

  VS_FORMULA     VARCHAR2(3000);
  VN_VALORLANCTO NUMBER;

  DATA_INTEGRACAO constant NUMBER := 0;
  DATA_LANCAMENTO constant NUMBER := 1;




  V_SQLERRO VARCHAR2(2048);

  FUNCTION F_PREPARA_SQL_FATO_GERADOR(PCODREGRA IN NUMBER,
                                      PNUMTRANSOPERACAO IN NUMBER,
                                      PCODFILIAL IN VARCHAR2) RETURN CLOB;

  FUNCTION F_RETORNA_FILTROS_REGRA(PCODREGRA IN NUMBER, V_FILTROCODMOEDA OUT VARCHAR2) RETURN CLOB;

  FUNCTION F_PREPARA_SQL_FATO_PELA_REGRA(PCODREGRA IN NUMBER,
                                         PCODFILIAL IN VARCHAR2) RETURN CLOB;

  PROCEDURE P_EXCLUI_LANCINTERMEDIARIA_GER(PCODREGRA IN NUMBER,
                                           PCODFILIAL IN VARCHAR2,
                                           PDATAINI IN DATE,
                                           PDATAFIM IN DATE,
                                           PCONSOLIDAR IN VARCHAR2);

  PROCEDURE P_VERIFICAR_CONTA_DMPLDLPA(PCODFILIAL        IN VARCHAR2,
                                         PCODREGRA         IN NUMERIC,
                                         PDTINICIO         IN DATE,
                                         PDTFINAL          IN DATE,
                                         PCODPLANOCONTA    IN NUMERIC,
                                         PCONSOLIDAR       IN VARCHAR2);

  --FATO GERADOR 1 - ENTRADAS
  PROCEDURE P_DADOS_ENTRADAS(CURSOR_DADOS    IN SYS_REFCURSOR,
                             PCODREGRA       IN NUMBER,
                             PCODPLANOCONTA  IN NUMBER,
                             RESULTADO      OUT VARCHAR2);

  --FATO GERADOR 2 - SAIDAS
  PROCEDURE P_DADOS_SAIDAS(CURSOR_DADOS    IN SYS_REFCURSOR,
                           PCODREGRA       IN NUMBER,
                           PCODPLANOCONTA  IN NUMBER,
                           RESULTADO      OUT VARCHAR2);

  --FATO GERADOR 3 - PAGAMENTOS
  PROCEDURE P_DADOS_PAGAMENTOS(CURSOR_DADOS    IN SYS_REFCURSOR,
                               PCODREGRA       IN NUMBER,
                               PCODPLANOCONTA  IN NUMBER,
                               RESULTADO      OUT VARCHAR2);

  --FATO GERADOR 4 - RECEBIMENTOS
  PROCEDURE P_DADOS_RECEBIMENTOS(CURSOR_DADOS    IN SYS_REFCURSOR,
                                 PCODREGRA       IN NUMBER,
                                 PCODPLANOCONTA  IN NUMBER,
                                 RESULTADO      OUT VARCHAR2);

  --FATO GERADOR 5 - DEVOLUÇÃO DE FORNECEDORES
  PROCEDURE P_DADOS_DEVFORNECEDORES(CURSOR_DADOS    IN SYS_REFCURSOR,
                                    PCODREGRA       IN NUMBER,
                                    PCODPLANOCONTA  IN NUMBER,
                                    RESULTADO      OUT VARCHAR2);

  --FATO GERADOR 6 - DEVOLUÇÕES DE CLIENTE
  PROCEDURE P_DADOS_DEVCLIENTES(CURSOR_DADOS    IN SYS_REFCURSOR,
                                PCODREGRA       IN NUMBER,
                                PCODPLANOCONTA  IN NUMBER,
                                RESULTADO      OUT VARCHAR2);

  --FATO GERADOR 7 - TRANSFERÊNCIA DE NUMERÁRIOS
  PROCEDURE P_DADOS_TRANSFNUMERARIOS(CURSOR_DADOS    IN SYS_REFCURSOR,
                                     PCODREGRA       IN NUMBER,
                                     PCODPLANOCONTA  IN NUMBER,
                                     RESULTADO      OUT VARCHAR2);

  --FATO GERADOR 8 - MOVIMENTAÇÃO DE ESTOQUE
  PROCEDURE P_DADOS_MOVESTOQUES(CURSOR_DADOS    IN SYS_REFCURSOR,
                                PCODREGRA       IN NUMBER,
                                PCODPLANOCONTA  IN NUMBER,
                                RESULTADO      OUT VARCHAR2);

  --FATO GERADOR 9 - LANÇAMENTOS DE PROVISÕES
  PROCEDURE P_DADOS_LANCPROVISOES(CURSOR_DADOS    IN SYS_REFCURSOR,
                                  PCODREGRA       IN NUMBER,
                                  PCODPLANOCONTA  IN NUMBER,
                                  RESULTADO      OUT VARCHAR2);

  --FATO GERADOR 10 - RECEBIMENTO DE ACERTO DE CARGAS
  PROCEDURE P_DADOS_ACERTOCARGAS(CURSOR_DADOS    IN SYS_REFCURSOR,
                                 PCODREGRA       IN NUMBER,
                                 PCODPLANOCONTA  IN NUMBER,
                                 RESULTADO      OUT VARCHAR2);

  --FATO GERADOR 11 - CUPONS FISCAIS
  PROCEDURE P_DADOS_CUPONS(CURSOR_DADOS    IN SYS_REFCURSOR,
                           PCODREGRA       IN NUMBER,
                           PCODPLANOCONTA  IN NUMBER,
                           RESULTADO      OUT VARCHAR2);

  --FATO GERADOR 12 - NOTAS FISCAIS DE SERVICO
  PROCEDURE P_DADOS_NFSERVICO(CURSOR_DADOS    IN SYS_REFCURSOR,
                           PCODREGRA       IN NUMBER,
                           PCODPLANOCONTA  IN NUMBER,
                           RESULTADO      OUT VARCHAR2);

    --FATO GERADOR 13 - PAGAMENTOS COM ADIANTAMENTO FORNECEDOR
  PROCEDURE P_DADOS_ADIANTAMENTOFORNECEDOR(CURSOR_DADOS    IN SYS_REFCURSOR,
                                           PCODREGRA       IN NUMBER,
                                           PCODPLANOCONTA  IN NUMBER,
                                           RESULTADO      OUT VARCHAR2);

  -- FATO GERADOR 14 - INCLUSÃO MANUAL RECEBER
  PROCEDURE P_DADOS_INCLUSAOMANUALRECEBER(CURSOR_DADOS    IN SYS_REFCURSOR,
                                          PCODREGRA       IN NUMBER,
                                          PCODPLANOCONTA  IN NUMBER,
                                          RESULTADO      OUT VARCHAR2);

  -- FATO GERADOR 15 - BAIXA DE ATIVO IMOBILIZADO
  PROCEDURE P_DADOS_BAIXAATIVOIMOBILIZADO(CURSOR_DADOS    IN SYS_REFCURSOR,
                                          PCODREGRA       IN NUMBER,
                                          PCODPLANOCONTA  IN NUMBER,
                                          RESULTADO      OUT VARCHAR2);

  -- FATO GERADOR 16 - BAIXA DE TITULOS COM CREDITO DE CLIENTE
  PROCEDURE P_DADOS_BAIXAATITULOSCRED(CURSOR_DADOS    IN SYS_REFCURSOR,
                                      PCODREGRA       IN NUMBER,
                                      PCODPLANOCONTA  IN NUMBER,
                                      RESULTADO      OUT VARCHAR2);

  -- FATO GERADOR 17 - INCLUSAO COM CREDITO DE CLIENTE
  PROCEDURE P_DADOS_INCLUSAOCREDITOCLIENTE(CURSOR_DADOS    IN SYS_REFCURSOR,
                                           PCODREGRA       IN NUMBER,
                                           PCODPLANOCONTA  IN NUMBER,
                                           RESULTADO      OUT VARCHAR2);

  -- FATO GERADOR 18 - CONTRATOS FINIMP E FINAME
  PROCEDURE P_DADOS_CONTRATOSFINIMPFINAME(CURSOR_DADOS    IN SYS_REFCURSOR,
                                          PCODREGRA       IN NUMBER,
                                          PCODPLANOCONTA  IN NUMBER,
                                          RESULTADO      OUT VARCHAR2);

  -- FATO GERADOR 19 - PIS/COFINS SERVIÇOS TOMADOS
  PROCEDURE P_DADOS_PISCOFINSSERVTOMADOS(CURSOR_DADOS    IN SYS_REFCURSOR,
                                         PCODREGRA       IN NUMBER,
                                         PCODPLANOCONTA  IN NUMBER,
                                         RESULTADO      OUT VARCHAR2);

   -- FATO GERADOR 20 - SAIDAS CANCELADAS TECHFIN
  PROCEDURE P_DADOS_SAIDAS_CANC_TECHFIN (CURSOR_DADOS     IN     SYS_REFCURSOR,
                                              PCODREGRA        IN     NUMBER,
                                              PCODPLANOCONTA   IN     NUMBER,
                                              RESULTADO           OUT VARCHAR2);
                                              
  -- FATO GERADOR 21 - PROVISAO RECEITA TECHFIN
  PROCEDURE P_DADOS_PROV_TECHFIN (CURSOR_DADOS     IN     SYS_REFCURSOR,
                                  PCODREGRA        IN     NUMBER,
                                  PCODPLANOCONTA   IN     NUMBER,
                                  RESULTADO           OUT VARCHAR2);                                              

END PKG_INTEGRACAOCONTABIL;
