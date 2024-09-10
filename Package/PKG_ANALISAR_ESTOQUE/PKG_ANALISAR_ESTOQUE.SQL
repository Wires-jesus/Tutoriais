CREATE OR REPLACE PACKAGE PKG_ANALISAR_ESTOQUE
  AUTHID CURRENT_USER
  IS
  /***********************************************************************
                                   TYPEs
  ------------------------------------------------------------------------*/
  -- Type padrão para executar os recalculos e analise
  TYPE TP_ENTRADA IS RECORD
   (CODFILIAL                    PCFILIAL.CODIGO%TYPE
   ,CODDEPOSITO                  PCESTOQUEDEPOSITO.CODDEPOSITO%TYPE DEFAULT 0
   ,CODPROD                      PCPRODUT.CODPROD%TYPE
   ,NUMLOTE                      PCLOTE.NUMLOTE%TYPE
   ,DTINICIAL                    PCMOV.DTMOV%TYPE
   ,DTFINAL                      PCMOV.DTMOV%TYPE DEFAULT TRUNC(SYSDATE)
   ,TIPOCHAMADA                  VARCHAR2(50) DEFAULT NULL
   ,DTLIMITE                     PCMOV.DTMOV%TYPE DEFAULT NULL
   ,GERAR_LOG                    VARCHAR2(1) DEFAULT 'S'
   ,USA_FUNCAO_1070              VARCHAR2(1) DEFAULT 'N'
   ,LISTA_DE_PRODUTOS            VARCHAR2(32767)
   ,LISTA_DE_DEPOSITOS           VARCHAR2(32767)
   ,LISTA_DE_DEPARTAMENTOS       VARCHAR2(32767)
   ,LISTA_DE_FORNECEDORES        VARCHAR2(32767)
   ,LISTA_DE_SECOES              VARCHAR2(32767)
   ,LISTA_DE_CATEGORIAS          VARCHAR2(32767)
   ,LISTA_DE_SUBCATEGORIAS       VARCHAR2(32767)
   ,LISTA_DE_MARCAS              VARCHAR2(32767)
   ,LISTA_DE_LOTES               VARCHAR2(32767)
   ,QUANTIDADE                   PCPEDI.QT%TYPE);

  -- Type para analise do estoque reservado
  TYPE T_ANALISAR_ESTOQUE IS RECORD
    (PROBLEMA                 VARCHAR2(2000)
    ,SUGESTAO                 VARCHAR2(2000)
    ,CODFILIAL                PCEST.CODFILIAL%TYPE
    ,CODPROD                  PCEST.CODPROD%TYPE
    ,CODDEPOSITO              PCESTOQUEDEPOSITOPROD.CODDEPOSITO%TYPE
    ,DESCRICAO                PCESTOQUEDEPOSITO.DESCRICAO%TYPE
    ,ESTOQUE_ATUAL            PCEST.QTESTGER%TYPE
    ,ESTOQUE_DEPOSITO         PCESTOQUEDEPOSITOPROD.QTESTOQUE%TYPE
    ,QTRESERVADA_ATUAL        PCEST.QTRESERV%TYPE
    ,QTRESERVADA_DEPOSITO     PCESTOQUEDEPOSITOPROD.QTRESERVADA%TYPE
    ,QTRESERVADA_PEDIDOS      PCEST.QTRESERV%TYPE
    ,QTPENDENTE_ATUAL         PCEST.QTPENDENTE%TYPE
    ,QTPENDENTE_DEPOSITO      PCESTOQUEDEPOSITOPROD.QTPENDENTE%TYPE
    ,QTPENDENTE_PEDIDOS       PCEST.QTPENDENTE%TYPE
    ,QTBLOQUEADA_ATUAL        PCEST.QTBLOQUEADA%TYPE
    ,QTBLOQUEADA_DEPOSITO     PCESTOQUEDEPOSITOPROD.QTBLOQUEADA%TYPE
    ,QTBLOQUEADA_NOTAS        PCEST.QTBLOQUEADA%TYPE);

  -- Type para analise das vendas assisitdas
  TYPE T_ANALISAR_VENDA_ASSISTIDA IS RECORD
    (PROBLEMA                 VARCHAR2(2000)
    ,SUGESTAO                 VARCHAR2(2000)
    ,CODFILIAL                PCEST.CODFILIAL%TYPE
    ,CODPROD                  PCEST.CODPROD%TYPE
    ,NUMPED_TV7               PCPEDC.NUMPED%TYPE
    ,QTDE_VENDA_TV7           NUMBER
    ,QTDE_DEVOL_TV7           NUMBER
    ,NUMPED_TV8               PCPEDC.NUMPED%TYPE
    ,QTDE_VENDA_TV8           NUMBER
    ,QTDE_DEVOL_TV8           NUMBER);

  -- Type de estrutura da tabela TB_RETIRA
  TYPE TR_RETIRA IS RECORD (
    CODPROD            PCMOV.CODPROD%TYPE
   ,DTMOV              PCMOV.DTMOV%TYPE
   ,DTMOVLOG           PCMOV.DTMOVLOG%TYPE
   ,ROTINACAD          PCMOV.ROTINACAD%TYPE
   ,ROTINALANC         PCMOV.ROTINALANC%TYPE
   ,CODOPER            PCMOV.CODOPER%TYPE
   ,STATUS             PCMOV.STATUS%TYPE
   ,QT                 PCMOV.QT%TYPE
   ,QTCONT             PCMOV.QTCONT%TYPE
   ,FIL_NF             PCMOV.CODFILIALNF%TYPE
   ,FILIAL             PCMOV.CODFILIAL%TYPE
   ,FIL_RET            PCMOV.CODFILIALRETIRA%TYPE
   ,TIPO_TRANSF        VARCHAR2(10)
   ,NUMPED             PCMOV.NUMPED%TYPE
   ,NUMTRANSVENDA      PCMOV.NUMTRANSVENDA%TYPE
   ,NUMNOTA            PCMOV.NUMNOTA%TYPE
   ,NUMTRANSENT        PCMOV.NUMTRANSENT%TYPE
   ,CONDVENDA          PCNFSAID.CONDVENDA%TYPE
   ,NUMCUPOM           PCNFSAID.NUMCUPOM%TYPE
   ,DTCANCEL           PCMOV.DTCANCEL%TYPE
   ,TIPOVENDA          PCNFSAID.TIPOVENDA%TYPE
   ,EMITENTE           PCNFSAID.ROTINALANC%TYPE
   ,FINALIDADENFE      PCNFSAID.FINALIDADENFE%TYPE);

  -- Type de estrutura da tabela TB_VALIDAR_PERIODO
  TYPE TR_VALIDAR_PERIODO IS RECORD (
    DTULTINVENTARIO    PCEST.DTULTINVENT%TYPE
   ,QTULTINVENTARIO    PCEST.QTULTINVENT%TYPE
   ,OBS                VARCHAR2(2000));

  -- Type de estrutura da tabela TB_TODAS_MOV
  TYPE TR_TODAS_MOV IS RECORD (
    ID                 VARCHAR2(20)
   ,DTMOV              PCMOV.DTMOV%TYPE
   ,CODFILIAL          PCMOV.CODFILIAL%TYPE
   ,CODPROD            PCMOV.CODPROD%TYPE
   ,SALDO              PCMOV.QT%TYPE);

  TYPE TR_SOMA_MOV_LOTE IS RECORD (
    ID                 VARCHAR2(20)
   ,CODFILIAL          PCMOV.CODFILIAL%TYPE
   ,CODPROD            PCMOV.CODPROD%TYPE
   ,NUMLOTE            PCMOV.NUMLOTE%TYPE
   ,SALDO              PCMOV.QT%TYPE);

  -- Type de estrutura da tabela TB_HIST_ANTERIOR
  TYPE TR_HIST_ANTERIOR IS RECORD (
     DATA              PCHISTEST.DATA%TYPE
    ,QTESTGER          PCHISTEST.QTESTGER%TYPE
    ,QTEST             PCHISTEST.QTESTGER%TYPE);

  -- Type de estrutura da tabela TB_HIST_VERSOS_PCMOV
  TYPE TR_HIST_VERSOS_PCMOV IS RECORD (
     DTMOV             PCMOV.DTMOV%TYPE
    ,CODFILIAL         PCMOV.CODFILIAL%TYPE
    ,CODPROD           PCMOV.CODPROD%TYPE
    ,QTHISTCONT        PCHISTEST.QTEST%TYPE
    ,QTMOVCONT         PCMOV.QTCONT%TYPE
    ,QTHISTGER         PCHISTEST.QTESTGER%TYPE
    ,QTMOVGER          PCMOV.QT%TYPE
    ,DIFERENCA         PCMOV.QT%TYPE);

  -- Type de estrutura da tabela TB_MOV
  TYPE TR_MOVIMENTACOES IS RECORD (
    ID                 VARCHAR2(20)
   ,DTMOV              PCMOV.DTMOV%TYPE
   ,CODFILIAL          PCMOV.CODFILIAL%TYPE
   ,CODPROD            PCMOV.CODPROD%TYPE
   ,NUMLOTE            PCMOV.NUMLOTE%TYPE
   ,SALDO              PCMOV.QT%TYPE);

  -- Type de estrutura da tabela TB_SOMA_MOV
  TYPE TR_SOMA_MOV IS RECORD (
    ID                 VARCHAR2(20)
   ,CODFILIAL          PCMOV.CODFILIAL%TYPE
   ,CODPROD            PCMOV.CODPROD%TYPE
   ,SALDO              PCMOV.QT%TYPE);

  -- Type de estrutura da tabela TB_SOMA_MOVIMENTACOES
  TYPE TR_VALIDA_MOV IS RECORD (
    ID                 VARCHAR2(20)
   ,SALDO              PCMOV.QT%TYPE);

  -- Type de estrutura da procedure
  TYPE TR_ENTRADA_MONITOR_ESTOQUE IS RECORD (
     TIPOCHAMADA       VARCHAR2(20) DEFAULT NULL
    ,DESTINO           VARCHAR2(10) DEFAULT 'TOTVS'
    ,CODUSUARIO        PCRECFUNC.CODFUNCDEST%TYPE  DEFAULT '1'
    ,CODFILIAL         PCMOV.CODFILIALNF%TYPE
    ,CODPROD           PCMOV.CODPROD%TYPE
    ,NUMLOTE           PCMOV.NUMLOTE%TYPE
    ,CODENDERECO       PCESTENDERECO.CODENDERECO%TYPE);

  TYPE TR_MSG_MON IS RECORD
    (ID                   VARCHAR2(20) DEFAULT NULL
    ,PROB_NO_HISTORICO    BOOLEAN
    ,DESTINO              VARCHAR2(10) DEFAULT 'TOTVS'
    ,CODUSUARIO           PCRECFUNC.CODFUNCDEST%TYPE  DEFAULT '1'
    ,DTINICIAL            PCMOV.DTMOV%TYPE
    ,DTFINAL              PCMOV.DTMOV%TYPE
    ,CODFILIAL            PCMOV.CODFILIALNF%TYPE
    ,CODPROD              PCMOV.CODPROD%TYPE
    ,NUMLOTE              PCMOV.NUMLOTE%TYPE
    ,EXCLUIDO             VARCHAR2(4) DEFAULT 'Não'
    -- Variaveis para armazenar os dados de antes
    ,DATA_ANTES           PCHISTEST.DATA%TYPE
    ,DATA_ANTES_LOTE      PCHISTESTLOTE.DATA%TYPE
    ,QTDE_ANTES_CONT      PCHISTEST.QTEST%TYPE
    ,QTDE_ANTES_GER       PCHISTEST.QTESTGER%TYPE
    ,QTDE_ANTES_LOTE      PCHISTESTLOTE.QT%TYPE
    -- Variaveis para armazenar as movimentações
    ,QTDE_GER_MOVIMENTADA  PCHISTEST.QTESTGER%TYPE
    ,QTDE_CONT_MOVIMENTADA PCHISTEST.QTEST%TYPE
    -- Variaveis para armazenar os saldos (O que tinha antes mais o que movimentou)
    ,QTDE_SALDO_GER       PCHISTEST.QTESTGER%TYPE
    ,QTDE_SALDO_CONT      PCHISTEST.QTEST%TYPE
    ,QTDE_SALDO_LOTE      PCHISTESTLOTE.QT%TYPE
    -- Variaveis para armazenar os dados atuais
    ,DATA_ATUAL           PCHISTEST.DATA%TYPE
    ,DATA_ATUAL_LOTE      PCHISTESTLOTE.DATA%TYPE
    ,QTDE_ATUAL_CONT      PCHISTEST.QTEST%TYPE
    ,QTDE_ATUAL_GER       PCHISTEST.QTESTGER%TYPE
    ,QTDE_ATUAL_LOTE      PCHISTESTLOTE.QT%TYPE
    -- Variáveis para armazenar os dados corretos e a diferença
    ,QTDE_CORRETA_GER     PCHISTEST.QTESTGER%TYPE
    ,QTDE_CORRETA_CONT    PCHISTEST.QTEST%TYPE
    ,QTDE_DIF_GER         PCHISTEST.QTESTGER%TYPE
    ,QTDE_DIF_CONT        PCHISTEST.QTEST%TYPE
    -- Variáveis para armazenar os dados da mensagem
    ,COD_MSG              VARCHAR2(40)
    ,LITERAL_1            VARCHAR2(200)
    ,LITERAL_2            VARCHAR2(200)
    ,LITERAL_3            VARCHAR2(200)
    ,NUMERICO_1           NUMBER(30)
    ,NUMERICO_2           NUMBER(30)
    ,NUMERICO_3           NUMBER(30)
    ,NUMERICO_4           NUMBER(30)
    ,NUMERICO_5           NUMBER(30)
    ,NUMERICO_6           NUMBER(30)
    ,MSG_ASSUNTO_1        VARCHAR2(500)
    ,MSG_ASSUNTO_2        VARCHAR2(500)
    ,MSG_CORPO_1          VARCHAR2(1000)
    ,MSG_CORPO_2          VARCHAR2(1000)
    ,MSG_CORPO_3          VARCHAR2(1000)
    ,MSG_MOTIVO_1         VARCHAR2(1000)
    ,MSG_MOTIVO_2         VARCHAR2(1000)
    ,MSG_MOTIVO_3         VARCHAR2(1000)
    ,MSG_SOLUCAO_1        VARCHAR2(2000)
    ,MSG_SOLUCAO_2        VARCHAR2(2000));

  /***********************************************************************
                             Tabelas virtuais
  ------------------------------------------------------------------------*/
  -- Tabela para armazenar os dados da PCHISTEST versos da PCMOV (RETORNO PIPELINED)
  TYPE TB_HIST_VERSOS_PCMOV IS TABLE OF TR_HIST_VERSOS_PCMOV;
  -- Tabela para armazenar os dados da PCHISTEST do dia anterior a data informada (RETORNO PIPELINED)
  TYPE TB_HIST_ANTERIOR IS TABLE OF TR_HIST_ANTERIOR;
  -- Tabela para armazenar as movimentações (RETORNO PIPELINED)
  TYPE TB_TODAS_MOV IS TABLE OF TR_TODAS_MOV;
  -- Tabela para armazenar os dados da filial retira (RETORNO PIPELINED)
  TYPE TB_RETIRA IS TABLE OF TR_RETIRA;
  -- Tabela para armazenar os dados da reserva (RETORNO PIPELINED)
  TYPE TB_ANALISAR_ESTOQUE IS TABLE OF T_ANALISAR_ESTOQUE;
  -- Tabela para armazenar os dados da reserva (RETORNO PIPELINED)
  TYPE TB_ANALISAR_VENDA_ASSISTIDA IS TABLE OF T_ANALISAR_VENDA_ASSISTIDA;
  -- Tabela para armazenar os dados do ultimo inventário (RETORNO PIPELINED)
  TYPE TB_VALIDAR_PERIODO IS TABLE OF TR_VALIDAR_PERIODO;

  /***********************************************************************
                              FUNÇÕES
  ------------------------------------------------------------------------*/
  -- Função para buscar dados da PCHISTEST
  FUNCTION F_CONS_HIST (psOPERACAO IN VARCHAR2) RETURN VARCHAR2;

  -- Função para consulta dados na PCPRODUT
  FUNCTION F_CONS_PRODUTO (psOPERACAO IN VARCHAR2) RETURN VARCHAR2;

  -- Função do tipo tabela para analisar dados do processo de filial retira
  FUNCTION F_RETIRA (pnCODPROD IN PCMOV.CODPROD%TYPE
                    ,pnNUMPED  IN PCMOV.NUMPED%TYPE)
    RETURN TB_RETIRA
    PIPELINED;

  -- Função criada para analisar o esotque da filial, depósito ou do produto
  FUNCTION F_ANALISAR_ESTOQUE (psCODFILIAL   IN PCFILIAL.CODIGO%TYPE
                              ,pnCODPRODUTO  IN PCPRODUT.CODPROD%TYPE)
    RETURN TB_ANALISAR_ESTOQUE
    PIPELINED;

  FUNCTION F_VALIDAR_PERIODO (psCODFILIAL IN PCFILIAL.CODIGO%TYPE
                             ,pnCODPROD   IN PCMOV.CODPROD%TYPE DEFAULT NULL
                             ,pdDATA      IN PCMOV.DTMOV%TYPE DEFAULT NULL)
    RETURN TB_VALIDAR_PERIODO
    PIPELINED;

  /***********************************************************************
                              PROCEDUREs
  ------------------------------------------------------------------------*/
  -- Procedure para corrigir o histórico de produtos com erros durante a atualização diária
  PROCEDURE PRC_EXECUTAR_LISTA (P_ENTRADA IN TP_ENTRADA);

  -- Procedure para criar as fotos do PCHISTEST com base na pcest para a rotina 820
  PROCEDURE PRC_ARMAZENARSALDOSESTOQUE(psCODFILIAL IN PCMOV.CODFILIAL%TYPE DEFAULT NULL);
  
  FUNCTION F_ARMAZENARSALDOSESTOQUE_TST(vsCODFILIAL IN PCMOV.CODFILIAL%TYPE DEFAULT NULL)
  RETURN NUMBER;
  
  -- Procedure para criar as fotos do PCHISTEST com base na pcest na 504.
  PROCEDURE PRC_ARMAZENARSALDOSESTOQUE_504;
  
  FUNCTION F_ARMAZENARSALDOSESTOQUE_504_T(vsCODFILIAL IN PCMOV.CODFILIAL%TYPE DEFAULT NULL)
  RETURN NUMBER;
  
  FUNCTION F_VALIDA_DTPRIMERIAMOV_TESTE(VSCODFILIAL IN VARCHAR2)   
  RETURN NUMBER;

  -- Procedure para corrigir as fotos do PCHISTEST com base nas movimentações
  PROCEDURE PRC_CORRIGIR_PCHISTEST (P_ENTRADA IN TP_ENTRADA);

  -- Procedure para corrigir as fotos do PCHISTESTLOTE com base nas movimentações do lote
  PROCEDURE PRC_CORRIGIR_HIST_LOTE (P_ENTRADA IN OUT TP_ENTRADA);

  -- Procedure para criar a tabela PCANALISEDOESTOQUE
  PROCEDURE PRC_CRIAR_ANALISEDOESTOQUE;

  -- Procedure para criar a tabela PCLOGRECEST
  PROCEDURE PRC_CRIAR_LOGRECEST;

  -- Procedure para criar a tabela PCPRODNAORECALCULADO
  PROCEDURE PRC_CRIAR_PRODNAORECALCULADO;

  -- Procedure para listar os dias do periodo
  PROCEDURE PRC_INS_LISTA_DIAS (pdDTINICIAL IN PCMOV.DTMOV%TYPE
                               ,pdDTFINAL   IN PCMOV.DTMOV%TYPE);

  /*Procedure para gerar log de execução*/
  PROCEDURE PRC_INS_LOG (ptLOG IN PCLOGRECEST%ROWTYPE);

  -- Procedure para incluir PCHISTEST
  PROCEDURE PRC_INS_PCHISTEST;

  -- Procedure para limpar a tabela PCANALISEDOESTOQUE
  PROCEDURE PRC_LIMPAR_ANALISEDOESTOQUE;

  -- Procedure para limpar a tabela PCPRODNAORECALCULADO
  PROCEDURE PRC_LIMPAR_PRODNAORECALCULADO;

  -- Procedure para limpar a tabela dados das tabelas MOVGERENCIAIS, MOVCONTABEIS e MOVLOTE
  PROCEDURE PRC_LIMPAR_SALDOS;

  -- Procedure para monitorar o estoque no dia anterior
  PROCEDURE PRC_MONITORAR_ESTOQUE (ptENTRADA_MONITOR IN OUT TR_ENTRADA_MONITOR_ESTOQUE);

  -- Procedure para monitorar o lote no dia anterior
  PROCEDURE PRC_MONITORAR_LOTE (ptENTRADA_MONITOR IN OUT TR_ENTRADA_MONITOR_ESTOQUE);

  -- Procedure para monitorar o estoque reservado
  PROCEDURE PRC_MON_RESERV;

  -- Procedure para buscar as movimentações contábeis (1070)
  PROCEDURE PRC_MOV_CONT (psCODFILIAL       IN PCMOV.CODFILIALNF%TYPE DEFAULT NULL
                         ,pnCODPROD         IN PCMOV.CODPROD%TYPE DEFAULT NULL

                         ,pdDTINICIAL       IN PCMOV.DTMOV%TYPE
                         ,pdDTFINAL         IN PCMOV.DTMOV%TYPE
                         ,psTIPOCHAMADA     IN VARCHAR2 DEFAULT NULL);
  -- Procedure para buscar as movimentações do endereço (WMS)
  PROCEDURE PRC_MOV_END (psCODFILIAL IN PCMOV.CODFILIALNF%TYPE DEFAULT NULL
                        ,pnCODPROD   IN PCMOV.CODPROD%TYPE DEFAULT NULL
                        ,pdDTINICIAL IN PCMOV.DTMOV%TYPE
                        ,pdDTFINAL   IN PCMOV.DTMOV%TYPE);

  -- Procedure para buscar as movimentações do endereço do lote (WMS)
  PROCEDURE PRC_MOV_END_LOTE (psCODFILIAL IN PCMOV.CODFILIALNF%TYPE DEFAULT NULL
                             ,pnCODPROD   IN PCMOV.CODPROD%TYPE DEFAULT NULL
                             ,psNUMLOTE   IN PCMOV.NUMLOTE%TYPE DEFAULT NULL
                             ,pdDTINICIAL IN PCMOV.DTMOV%TYPE
                             ,pdDTFINAL   IN PCMOV.DTMOV%TYPE);

  -- Procedure para buscar as movimentações gerenciais (1118)
  PROCEDURE PRC_MOV_GER (psCODFILIAL IN PCMOV.CODFILIALNF%TYPE DEFAULT NULL
                        ,pnCODPROD   IN PCMOV.CODPROD%TYPE DEFAULT NULL
                        ,pdDTINICIAL IN PCMOV.DTMOV%TYPE
                        ,pdDTFINAL   IN PCMOV.DTMOV%TYPE);

  -- Procedure para buscar as movimentações do lote
  PROCEDURE PRC_MOV_LOTE (psCODFILIAL IN PCMOV.CODFILIALNF%TYPE
                         ,pnCODPROD   IN PCMOV.CODPROD%TYPE
                         ,psNUMLOTE   IN PCMOV.NUMLOTE%TYPE
                         ,pdDTINICIAL IN PCMOV.DTMOV%TYPE
                         ,pdDTFINAL   IN PCMOV.DTMOV%TYPE);

  -- Procedure para recaular o estoque com base nas movimentações
  PROCEDURE PRC_RECALCULO (P_ENTRADA IN OUT TP_ENTRADA);

  -- Procedure para recaular o lote com base nas movimentações
  PROCEDURE PRC_REC_LOTE (P_ENTRADA IN OUT TP_ENTRADA);

  -- Procedure para recalcular as tabelas PCFINANC e FINANC2 (rotina 117)
  PROCEDURE PRC_REC_PAT_LIQ (pnCODROTINA IN NUMBER
                            ,pnCODFUNC   IN NUMBER
                            ,psCODFILIAL IN VARCHAR2
                            ,pdDATA      IN DATE);

  -- Procedure para recalcular o estoque em transito das vendas manifesto
  PROCEDURE PRC_REC_TRANSITO_TV13 (psCODFILIAL IN PCMOV.CODFILIAL%TYPE DEFAULT NULL
                                  ,pnCODPROD   IN PCMOV.CODPROD%TYPE DEFAULT NULL
                                  ,pdDATAINI   IN PCMOV.DTMOV%TYPE);

  -- Procedure para recalcular o estoque reservado e pendente do sistema WinThor
  PROCEDURE PRC_RESERVADO (pENTRADA IN TP_ENTRADA);

  PROCEDURE PRC_RECRIAR_PCHISTEST (psCODFILIAL  IN VARCHAR2
                                  ,pdDATA_BASE  IN DATE
                                  ,pdDTINICIAL  IN DATE
                                  ,pdDTFINAL    IN DATE);

  FUNCTION F_RECRIAR_PCHISTEST (VSCODFILIAL  IN VARCHAR2
                                ,VDDATA_BASE  IN DATE
                                ,VDDTINICIAL  IN DATE
                                ,VDDTFINAL    IN DATE)
  RETURN NUMBER;                                  

  -- Procedure para validar se existe erros no estoque
  PROCEDURE PRC_VALIDAR_ESTOQUE_GERAL (psCODFILIAL   IN PCMOV.CODFILIAL%TYPE
                                      ,pnCODPROD     IN PCMOV.CODPROD%TYPE DEFAULT NULL
                                      ,pdDATA        IN PCMOV.DTMOV%TYPE DEFAULT NULL
                                      ,psTIPOCHAMADA IN VARCHAR2 /* EXTERNA ou INTERNA */);
  
  FUNCTION F_RECRIAR_PCHISTEST (VSCODFILIAL  IN VARCHAR2
                                ,VDDATA_BASE  IN DATE
                                ,VDDTINICIAL  IN DATE
                                ,VDDTFINAL    IN DATE
                                ,VSVALIDA_DELETE IN VARCHAR2
                                ,VSLIMPOU_PCRECALCULOPROD OUT VARCHAR2
                                ,VSLIMPOU_PCHISTESTFILA OUT VARCHAR2)
  RETURN NUMBER;                     

END PKG_ANALISAR_ESTOQUE;
