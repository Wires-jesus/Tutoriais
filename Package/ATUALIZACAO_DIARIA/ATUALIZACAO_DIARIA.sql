CREATE OR REPLACE PACKAGE ATUALIZACAO_DIARIA IS

  VSVERSAOPACKAGE VARCHAR(100) := '34.0.0.50';

  PORCENTAGEM NUMBER := 20;
  
  TYPE VALIDAR_PERIODO IS RECORD(
    CODFILIAL     PCFILIAL.CODIGO%TYPE
   ,RAZAOSOCIAL   PCFILIAL.RAZAOSOCIAL%TYPE
   ,DATA          DATE);
    
  TYPE TB_VALIDAR_PERIODO IS TABLE OF VALIDAR_PERIODO;

  PROCEDURE PC_CONSOLIDA_PLANOVOO (PDTINICIO  IN  DATE,
                                  PDTTERMINO IN  DATE,
                                  POPCAO     IN  VARCHAR2,
                                  PMENSAGEM  OUT VARCHAR2,
                                  PLISTACODIGO IN VARCHAR2 DEFAULT NULL,
                                  PCODFILIAL IN  VARCHAR2 DEFAULT NULL);
  
  PROCEDURE P_PC_ORDENAR_SEQUENCIA_ROTACLI( P_DTPROXVISITA IN PCROTACLI.DTPROXVISITA%TYPE
                                           , P_CODUSUR IN PCROTACLI.CODUSUR%TYPE DEFAULT 0
                                           , P_ROWID IN VARCHAR2 DEFAULT ''
                                           );

  PROCEDURE P_PC_GERAROTACLI(PI_DTPROCESSAMENTO IN DATE);

  --Bloquear Produto FL sem Estoque  (P_PC_BLOQPRODFLSEMESTOQUE)
  PROCEDURE P_PC_BLOQPRODFLSEMESTOQUE(
                                      -- Parametros de entrada
                                      PDTPROCESSAMENTO IN DATE,
                                      -- Parametro de saida
                                      PVC2MENSSAGEN OUT VARCHAR2);

  PROCEDURE P_PC_ZERARACUMVENDADIA(PCODFILIAL IN  VARCHAR2,
                                   -- Parametro de saida
                                   PVC2MENSSAGEN OUT VARCHAR2);

  --Armazenar Saldos Caixa Banco  (P_PC_ARMAZENASALDOCAIXABANCO)
  PROCEDURE P_PC_ARMAZENASALDOCAIXABANCO(
                                         -- Parametros de entrada
                                         PDTPROCESSAMENTO IN DATE,
                                         -- Parametro de saida
                                         PVC2MENSSAGEN OUT VARCHAR2);

  --Armazenar Saldos Estoque  (P_PC_ARMAZENARSALDOSESTOQUE)
  PROCEDURE P_PC_ARMAZENARSALDOSESTOQUE(
                                        -- Parametros de entrada
                                        PDTPROCESSAMENTO IN DATE,
                                         PCODFILIAL IN VARCHAR2,
                                        -- Parametro de saida
                                        PVC2MENSSAGEN OUT VARCHAR2);

  --Armazenar Saldos Estoque de Lote  (P_PC_ARMAZENASALDOESTOQUELOTE)
  PROCEDURE P_PC_ARMAZENASALDOESTOQUELOTE(
                                          -- Parametros de entrada
                                          PDTPROCESSAMENTO IN DATE,
                                          PCODFILIAL IN VARCHAR2,
                                          -- Parametro de saida
                                          PVC2MENSSAGEN OUT VARCHAR2);

  --Bloqueia/Desbloqueia Clientes Automaticamente  (P_PC_BLOQUEARCLIENTES)
  PROCEDURE P_PC_BLOQUEARCLIENTES( PUSUARIO IN VARCHAR2 DEFAULT '',
                                  -- Parametro de saida
                                  PVC2MENSSAGEN OUT VARCHAR2);

  --Bloqueia Clientes Inativos a mais de X Dias  (P_PC_BLOQUEACLIENTEINATIVO)
  PROCEDURE P_PC_BLOQUEACLIENTEINATIVO(USUARIO IN NUMBER,
                                       OPCAO   IN NUMBER,
                                       pCODIGOROTINA IN NUMBER DEFAULT 504,
                                       -- Parametro de saida
                                       PVC2MENSSAGEN OUT VARCHAR2);

  --Recálculo do %Venda para Pessoa Física  (P_PC_RECALCPERCENTVENDAPF)
  PROCEDURE P_PC_RECALCPERCENTVENDAPF(PCODFILIAL IN VARCHAR2,
                                      -- Parametro de saida
                                      PVC2MENSSAGEN OUT VARCHAR2);

  FUNCTION FC_RETORNA_VERSAO RETURN VARCHAR2;
  --Procedimento para bloqueio de clientes atravez do codigo;
  PROCEDURE P_PC_BLOQUEIOCLIENTEPORCODIGO(PCODCLI       NUMBER,
                                          PVC2MENSSAGEN OUT VARCHAR2, PUSUARIO IN VARCHAR2 DEFAULT '');

    /*Procedure responsavel pelo bloqueio e desbloqueio de cliente de forma automatica*/
    PROCEDURE P_PC_BLOQUEARCLIENTE(PCODCLI NUMBER,
                                   PVC2MENSSAGEN OUT VARCHAR2,
                                   PUSUARIO IN VARCHAR2 DEFAULT '');

    /* Procedure responsável por gravar log dos clientes que estão sendo bloqueados */
    PROCEDURE P_PC_GRAVARLOGBLOQAUTOM(PCODCLI IN VARCHAR2,
                                  PUSUARIO IN VARCHAR2,
                                  PROTINA IN VARCHAR2,
                                  POBS1 IN VARCHAR2,
                                  PLIMCREDANT IN NUMBER DEFAULT NULL,
                                  PBLOQUEIOANT IN VARCHAR2 DEFAULT NUll,
                                  PDTREGLIMANT IN DATE DEFAULT NUll,
                                  PDTVENCLIMANT IN DATE DEFAULT NUll,
                                  POBSANT IN VARCHAR2 DEFAULT NUll,
                                  PPRAZOANT IN NUMBER DEFAULT NUll,
                                  PCODCOBANT IN VARCHAR2 DEFAULT NUll,
                                  PCODPLPAGANT IN VARCHAR2 DEFAULT NUll,
                                  PDESCRICAO IN VARCHAR2 DEFAULT NULL);

   /*Gerar PCFINANC*/
  PROCEDURE GERAR_PCFINANC( PCODFILIAL VARCHAR2
                          , PCODROTINA NUMBER
                          , PCODFUNC NUMBER
                          , PDATAPROCESSADA  DATE);

  /*Gerar PCFINANC2*/
  PROCEDURE GERAR_PCFINANC2( PCODFILIAL VARCHAR2
                           , PCODROTINA NUMBER
                           , PCODFUNC NUMBER
                           , PDATAPROCESSADA  DATE);

  /*Incluir PCFINANC2*/
  procedure PCFINANC2_GRAVAR( PDATA DATE
                            , PCODFILIAL VARCHAR2
                            , PTIPODADO VARCHAR2
                            , PCODIGON NUMBER
                            , PCODIGOA VARCHAR2
                            , PVALOR NUMBER
                            , PDTGERACAO DATE
                            , PCODROTINA NUMBER
                            , PCODFUNC NUMBER
                            , PVALOR2 NUMBER
                            , PPARMULTIFILIALCAIXABANCO3882 VARCHAR2 DEFAULT 'N'
                            , PLISTAFILIAIS VARCHAR2 DEFAULT NULL);

 /*Gerar saldos financceiros PCFINANC2, PCFINANC*/
 PROCEDURE ATUALIZARSALDOSFINANCEIROS( PCODFILIAL VARCHAR2
                                     , PCODROTINA NUMBER
                                     , PCODFUNC NUMBER
                                     , PDATAPROCESSADA  DATE
                                     , PATUALIZARDTPROCESSAMENTO VARCHAR2);
                            
  /*Chamadas sem código filial para compatibilidade com 504 e outros processos que não usam 820*/
  
  PROCEDURE P_PC_ZERARACUMVENDADIA(
                                   -- Parametro de saida
                                   PVC2MENSSAGEN OUT VARCHAR2);
                          
  --Armazenar Saldos Estoque  (P_PC_ARMAZENARSALDOSESTOQUE)
  PROCEDURE P_PC_ARMAZENARSALDOSESTOQUE(
                                        -- Parametros de entrada
                                        PDTPROCESSAMENTO IN DATE,
                                        -- Parametro de saida
                                        PVC2MENSSAGEN OUT VARCHAR2);

  --Armazenar Saldos Estoque de Lote  (P_PC_ARMAZENASALDOESTOQUELOTE)
  PROCEDURE P_PC_ARMAZENASALDOESTOQUELOTE(
                                          -- Parametros de entrada
                                          PDTPROCESSAMENTO IN DATE,
                                          -- Parametro de saida
                                          PVC2MENSSAGEN OUT VARCHAR2);
                                
  --Recálculo do %Venda para Pessoa Física  (P_PC_RECALCPERCENTVENDAPF)
  PROCEDURE P_PC_RECALCPERCENTVENDAPF(
                                      -- Parametro de saida
                                      PVC2MENSSAGEN OUT VARCHAR2);  

 PROCEDURE P_CALC_SALDO_CONTASRECEBER(PSCODFILIAL      VARCHAR2,
                                       PNCODROTINA      NUMBER,
                                       PNCODFUNC        NUMBER,
                                       PDDATAPROCESSADA DATE);

  PROCEDURE P_CALC_SALDO_VERBAS(PSCODFILIAL      VARCHAR2,
                                PNCODROTINA      NUMBER,
                                PNCODFUNC        NUMBER,
                                PDDATAPROCESSADA DATE);

  PROCEDURE P_CALC_SALDO_CONTASPAGARFORNEC(PSCODFILIAL              VARCHAR2,
                                           PNCODROTINA              NUMBER,
                                           PNCODFUNC                NUMBER,
                                           PDDATAPROCESSADA         DATE,
                                           PSEXIBIRSALDOBRUTOFORNEC VARCHAR2);

  PROCEDURE P_CALC_SALDO_CONTASPAGAROUTROS(PSCODFILIAL              VARCHAR2,
                                           PNCODROTINA              NUMBER,
                                           PNCODFUNC                NUMBER,
                                           PDDATAPROCESSADA         DATE,
                                           PSEXIBIRSALDOBRUTOFORNEC VARCHAR2);

  PROCEDURE P_DELETAR_PCFINANC2E3(PSCODFILIAL VARCHAR2, PNCODROTINA NUMBER);

  FUNCTION F_CABECALHO_INSERT_PCFINANC2 RETURN VARCHAR2;
  
  FUNCTION TEM_DADOS_RETROATIVOS(pnCODFILIAL IN VARCHAR DEFAULT NULL) RETURN TB_VALIDAR_PERIODO PIPELINED;
  
  PROCEDURE PRC_EXECUTAR_DADOS_RETROATIVOS(psCODFILIAL IN PCMOV.CODFILIAL%TYPE
                                          ,pdDATA_PROCESSAMENTO IN DATE
                                          ,psMSG_RETORNO OUT VARCHAR2);

  PROCEDURE P_DEL_PEDIDO_SEM_CABECALHO(psCODFILIAL VARCHAR2);
END;