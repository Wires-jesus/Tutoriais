CREATE OR REPLACE FUNCTION F_MED_LIVRO_RMV(pi_vCodFilial      IN VARCHAR2,
                         pi_vDataInicial    IN VARCHAR2,
                         pi_vDataFinal      IN VARCHAR2,
                         pi_vInListas       IN VARCHAR2,
                         pi_vInProdutos     IN VARCHAR2,
                         pi_nTipoHistorico  IN NUMBER,
                         pi_nTipoObservacao IN NUMBER,
                         pi_vsConsiderarFilialNF IN VARCHAR2 DEFAULT 'N',
                         pi_vCodFilialNF    IN VARCHAR2 DEFAULT NULL)
/*******************************************************************************
 Nome         : F_MED_LIVRO_RMV
 Descricão    : Função para retornar Tabela com as Movimetações do Livro RMV
 Parâmetros   : pi_vCodFilial      - Código da Filial
                pi_vDataInicial    - Data Inicio
                pi_vDataFinal      - Data Fim
                pi_vListas         - Listas
                pi_vInProdutos     - Produtos
                pi_nTipoHistorico  - Tipo Historico
                                     1 - RMV - GO
                                     2 - Balanço de Medicamentos Controlados
                                     3 - Formulário II - BSPO (Balanço Completo Entrada/Saída)
                                     4 - Formulário III - BSPO (Balanço de Aquisições)
                                     5 - Formulário IV - BSPO (Balanço de Vendas)
                                     6 - Todos os Formulário BSPO
                                     7 - RMV - TO (Saídas)
                                     8 - RMV - PE
                                     9 - RelatorioLivroRegistroSP
                pi_nTipoObservacao - Tipo Observacao
                                     1 - RMV - GO
                                     2 - RMV - TO (Saídas)
                                     3 - RMV - PE
                                     4 - RMV - TO (Saídas) AGLON
 Alteracão    : Anderson Silva - 14/09/2012 - Criação da Função
              : Anderson Silva - 11/10/2012 - Desconsiderar Notas Fiscais com 
                                              Especie NE
              : Anderson Silva - 25/06/2013 - Balanço de Medicamentos Controlados
              : Anderson Silva - 30/08/2013 - Formulários BSPC
              : Anderson Silva - 25/09/2013 - Formulários BSPC - Inclusão Importação
              : Anderson Silva - 09/01/2014 - RMV - TO - Saídas (HIS.01208.2013)
              : Anderson Silva - 12/03/2014 - RMV - GO - 3427.027352.2014
                                              Ordenar por codoper para as entradas
                                              serem listadas primeiro
                                              Param. para considerar todas as movimentações
                                              ou somente que movimentam estoque gerencial
                                              Unificar condições em todos os selects de
                                              histórico - saldo inicial - especie
              : Anderson Silva - 12/03/2014 - HIS.00742.2013
                                              RMV - GO - colocar o lote na entrada                                              
              : Anderson Silva - 05/03/2014 - HIS.00742.2013
                                              - Tratamento somente Inventários sem Lote e desdobramentos
              : Anderson Silva - 05/08/2015 - Adicionada a Marca e Unidade
              : Anderson Silva - 22/10/2015 - HIS.03778.2015  - Auto Inutilização
              : Anderson Silva - 26/01/2016 - 5232.002911.2016 - Garantir Registros Unicos no Select (Usar PCMOV.NUMTRANSITEM)
              : Anderson Silva - 20/04/2016 - Desconsiderar 'SV' para tudo, por causa do WMS que gera SV nos ajustes
              : Anderson Silva - 01/06/2016 - Embalagem
              : Anderson Silva - 14/09/2016 - Regra Específica - NF na Perda
              : Anderson Silva - 27/09/2016 - Tipo 5 - Somente Mov. Contábil
              : Anderson Silva - 03/01/2017 - 5666.146396.2016 - Tipo 5 - Somente Mov. Contábil considerando EI Tipo B
              : Anderson Silva - 05/01/2016 - 1870.001198.2017 - Tirar o EA das Aquisições
              : Anderson Silva - 13/09/2017 - 6065.107358.2017 - Alter Join Balannço Produtos Controlados (Histórico = 2)
              : Frank - 26/10/2017 - HIS.02268.2017  - Duas substâncias no mesmo Produto
              : Anderson Silva - 10/11/2017 - MED-327 - Parâmetro para Apenas Movimentações Contábeis
              : Jorge Humberto - 20/08/2018 - MED-1500 - Criação de mais duas colunas para o relatório de RMV Paraíba (Fiscal)
              : Anderson Silva - 28/10/2018 - MED-1672 - Merge à MED-1500 - Criação de mais duas colunas para o relatório de RMV Paraíba (Fiscal)              
              : Marcos Levi    - 22/07/2020 - DDMEDICA-3377 - ORDENAÇÃO POR DESCRIÇAO DO PRODUTO
 ********************************************************************************/
RETURN TABELA_MED_LIVRO_RMV
PARALLEL_ENABLE
PIPELINED IS

  -- Tabelas para uso no BulkCollect
  TYPE TT_TIPOREG         IS TABLE OF NUMBER(1) INDEX BY BINARY_INTEGER; 
  TYPE TT_CODPROD         IS TABLE OF PCMOV.CODPROD%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_DESCRICAOPROD   IS TABLE OF PCPRODUT.DESCRICAO%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_DCB             IS TABLE OF VARCHAR2(240) INDEX BY BINARY_INTEGER; 
  TYPE TT_DESCRICAODCB    IS TABLE OF VARCHAR2(240) INDEX BY BINARY_INTEGER;   
  TYPE TT_UNIDADE         IS TABLE OF PCPRODUT.UNIDADE%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_EMBALAGEM       IS TABLE OF PCPRODUT.EMBALAGEM%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_DTMOV           IS TABLE OF PCMOV.DTMOV%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_DTEMISSENT      IS TABLE OF PCNFENT.DTEMISSAO%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_CODCLI          IS TABLE OF PCMOV.CODCLI%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_NUMNOTA         IS TABLE OF PCMOV.NUMNOTA%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_NUMLOTE         IS TABLE OF PCMOV.NUMLOTE%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_NUMTRANSENT     IS TABLE OF PCMOV.NUMTRANSENT%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_NUMTRANSVENDA   IS TABLE OF PCMOV.NUMTRANSVENDA%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_CODOPER         IS TABLE OF PCMOV.CODOPER%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_QTESTINICIAL    IS TABLE OF PCMOV.QT%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_QTENT           IS TABLE OF PCMOV.QT%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_QTSAI           IS TABLE OF PCMOV.QT%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_QTPERDA         IS TABLE OF PCMOV.QT%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_QTESTOQUE       IS TABLE OF PCMOV.QT%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_HISTORICO       IS TABLE OF VARCHAR2(100) INDEX BY BINARY_INTEGER; 
  TYPE TT_OBSERVACOES     IS TABLE OF VARCHAR2(100) INDEX BY BINARY_INTEGER; 
  TYPE TT_CODFUNCLANC     IS TABLE OF PCMOV.CODFUNCLANC%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_SUBSTANCIA      IS TABLE OF VARCHAR2(240) INDEX BY BINARY_INTEGER; 
  TYPE TT_CNPJ            IS TABLE OF PCCLIENT.CGCENT%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_RAZAOSOCIAL     IS TABLE OF VARCHAR2(100) INDEX BY BINARY_INTEGER;   
  TYPE TT_FORMULARIOBSPO  IS TABLE OF NUMBER(1) INDEX BY BINARY_INTEGER;
  TYPE TT_DTEMISSAONF     IS TABLE OF DATE INDEX BY BINARY_INTEGER; 
  TYPE TT_ENDERECO        IS TABLE OF VARCHAR2(200) INDEX BY BINARY_INTEGER;   
  TYPE TT_UF              IS TABLE OF PCCLIENT.ESTENT%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_MARCA           IS TABLE OF PCMARCA.MARCA%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_NUMTRANSITEM    IS TABLE OF PCMOV.NUMTRANSITEM%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_CGCENT          IS TABLE OF PCCLIENT.CGCENT%TYPE INDEX BY BINARY_INTEGER;
  TYPE TT_ENDERENT        IS TABLE OF PCCLIENT.ENDERENT%TYPE INDEX BY BINARY_INTEGER; 
  TYPE TT_DTSAIDANF       IS TABLE OF PCNFSAID.DTSAIDANF%TYPE INDEX BY BINARY_INTEGER; 
  vtTIPOREG               TT_TIPOREG;
  vtCODPROD               TT_CODPROD;
  vtDESCRICAOPROD         TT_DESCRICAOPROD;
  vtDCB                   TT_DCB;
  vtDESCRICAODCB          TT_DESCRICAODCB;
  vtUNIDADE               TT_UNIDADE;
  vtEMBALAGEM             TT_EMBALAGEM;
  vtDTMOV                 TT_DTMOV;
  vtDTEMISSENT            TT_DTEMISSENT;
  vtCODCLI                TT_CODCLI;
  vtNUMNOTA               TT_NUMNOTA;
  vtNUMLOTE               TT_NUMLOTE;
  vtNUMTRANSENT           TT_NUMTRANSENT;
  vtNUMTRANSVENDA         TT_NUMTRANSVENDA;
  vtCODOPER               TT_CODOPER;
  vtQTESTINICIAL          TT_QTESTINICIAL;
  vtQTENT                 TT_QTENT;
  vtQTSAI                 TT_QTSAI;
  vtQTPERDA               TT_QTPERDA;
  vtQTESTOQUE             TT_QTESTOQUE;
  vtHISTORICO             TT_HISTORICO;
  vtOBSERVACOES           TT_OBSERVACOES;
  vtCODFUNCLANC           TT_CODFUNCLANC;
  vtSUBSTANCIA            TT_SUBSTANCIA;
  vtCNPJ                  TT_CNPJ;  
  vtRAZAOSOCIAL           TT_RAZAOSOCIAL;
  vtFORMULARIOBSPO        TT_FORMULARIOBSPO;
  vtDTEMISSAONF           TT_DTEMISSAONF;
  vtENDERECO              TT_ENDERECO;
  vtUF                    TT_UF;
  vtMARCA                 TT_MARCA;
  vtNUMTRANSITEM          TT_NUMTRANSITEM;
  vtCGCENT                TT_CGCENT;
  vtENDERENT              TT_ENDERENT;
  vtDTSAIDANF             TT_DTSAIDANF;  
  
  -- Array para receber os Dados do Cliente
  TYPE TTRazaoCliente     IS TABLE OF VARCHAR2(100) INDEX BY BINARY_INTEGER;
  vtRazaoCliente          TTRazaoCliente;    
  TYPE TTCgcCliente       IS TABLE OF PCCLIENT.CGCENT%TYPE INDEX BY BINARY_INTEGER;
  vtCgcCliente            TTCgcCliente;    
  TYPE TTFantasiaCliente  IS TABLE OF VARCHAR2(100) INDEX BY BINARY_INTEGER;
  vtFantasiaCliente       TTFantasiaCliente;    
  TYPE TTEnderecoCliente  IS TABLE OF VARCHAR2(200) INDEX BY BINARY_INTEGER;
  vtEnderecoCliente       TTEnderecoCliente;    
  TYPE TTUfCliente        IS TABLE OF PCCLIENT.ESTENT%TYPE INDEX BY BINARY_INTEGER;
  vtUfCliente             TTUfCliente;    
  -- Array para Receber a Especie da NF de Saida
  TYPE TTEspecieNFSaida   IS TABLE OF PCNFSAID.ESPECIE%TYPE INDEX BY BINARY_INTEGER;
  vtEspecieNFSaida        TTEspecieNFSaida;    
  -- Array para Receber a Especie da NF de Entrada
  TYPE TTEspecieNFEntrada IS TABLE OF PCNFENT.ESPECIE%TYPE INDEX BY BINARY_INTEGER;
  vtEspecieNFEntrada      TTEspecieNFEntrada;    
  -- Array para Receber o Tipo Descarga da NF de Entrada
  TYPE TTipoDescargaNFEnt IS TABLE OF PCNFENT.TIPODESCARGA%TYPE INDEX BY BINARY_INTEGER;
  vtTipoDescargaNFEnt     TTipoDescargaNFEnt;    
  -- MED-1672 - Array para Receber a Data da NF de Saida
  TYPE TTDataNFSaida      IS TABLE OF PCNFSAID.DTSAIDA%TYPE INDEX BY BINARY_INTEGER;
  vtDataNFSaida           TTDataNFSaida;    
  -- MED-1672 - Array para Receber a Data da NF de Entrada
  TYPE TTDataNFEntrada    IS TABLE OF PCNFENT.DTEMISSAO%TYPE INDEX BY BINARY_INTEGER;
  vtDataNFEntrada         TTDataNFEntrada;    
  --  MED-1672 - Arraay para receber os dados do cliente
  TYPE TRecDadosCli       IS RECORD(
       vvCgcEnt           PCCLIENT.CGCENT%TYPE,
       vvEnderEnt         PCCLIENT.ENDERENT%TYPE);
  vrDadosCli              TRecDadosCli;
  TYPE TTvDadosCli        IS TABLE OF TRecDadosCli INDEX BY BINARY_INTEGER;
  vtDadosCli              TTvDadosCli;        
    
  -- Sql
  vvSql                   VARCHAR2(32000);  
  
  -- Condições complementares ao Sql
  vvWhereFilial           VARCHAR2(32000);  
  vvWherePerAnterior      VARCHAR2(32000);  
  vvWherePeriodo          VARCHAR2(32000);  
  vvInLista               VARCHAR2(32000);  
  vvInProdutos            VARCHAR2(32000);  
  
  -- Variaveis Auxiliares
  vnCodProdAnt            PCMOV.CODPROD%TYPE;
  vnSaldoEstoque          PCMOV.QT%TYPE;
  vvRazaoSocial           VARCHAR2(100);
  vvFantasia              VARCHAR2(100);
  vvEndereco              VARCHAR2(200);
  vvUf                    VARCHAR2(2);
  vvCnpj                  PCCLIENT.CGCENT%TYPE;
  vdDtEmissao             DATE;  
  vvHistorico             VARCHAR2(100);
  vvObservacao            VARCHAR2(100);
  vbExistemMovimProduto   BOOLEAN;  
  vnNumReg                NUMBER(16,0);
  vvEspecie               PCNFSAID.ESPECIE%TYPE;
  vvDtNfSaid              PCNFSAID.DTSAIDANF%TYPE;
  viValorMaxInteger       INTEGER := 999999999;
  vbConsideraMovimentacao BOOLEAN;
  vvMultiplasSubstancias  NUMBER(1);
  -- Tipo Descarga da Nota
  vvTipoDescarga          PCNFENT.TIPODESCARGA%TYPE;
  -- Parâmetro
  --vnCodContFor            PCCONSUM.CODCONTFOR%TYPE;
  
  -- Parâmetro
  vvTipoMovEscrituracaoMed     VARCHAR2(1);
  vvApresAutoInutilizEscritMed VARCHAR2(1);
  
  -- Array Auxiliar para Totalizar Estoque
  TYPE TRecEstoque        IS RECORD(
       vnCodProd          PCMOV.CODPROD%TYPE,
       vvDescricao        PCPRODUT.DESCRICAO%TYPE,
       vvDcb              PCPRINCIPATIVO.DCB%TYPE,
       vvDescDcb          VARCHAR2(240),       
       vvSubstancia       PCPRODUT.SUBSTANCIA%TYPE,       
       vvUnidade          PCPRODUT.UNIDADE%TYPE,
       vvEmbalagem        PCPRODUT.EMBALAGEM%TYPE,
       vnEstEnt           PCMOV.QT%TYPE,
       vnEstSai           PCMOV.QT%TYPE,
       vnQtImport         PCMOV.QT%TYPE,
       vnQtAquis          PCMOV.QT%TYPE,
       vnQtEnt            PCMOV.QT%TYPE,
       vnQtSai            PCMOV.QT%TYPE,
       vnQtPerda          PCMOV.QT%TYPE,
       vvMarca            PCMARCA.MARCA%TYPE);
  TYPE TTvEstoque         IS TABLE OF TRecEstoque INDEX BY BINARY_INTEGER;
  vtEstoque               TTvEstoque;
  TYPE TTListaProdutos    IS TABLE OF PCMOV.CODPROD%TYPE INDEX BY BINARY_INTEGER;
  vtListaProdutos         TTListaProdutos;
  idxProduto              INTEGER;
  
  -- OBS Auto Inutilização
  vvObsAutoInutilizacao   PCMOVAVARIA.OBS%TYPE;
  
  -- Regra Específica
  vbUsaRegraNfObsPerda2318 BOOLEAN;
  
  -- Tipo Objeto
  OUTROW TIPO_MED_LIVRO_RMV := TIPO_MED_LIVRO_RMV(NULL,  -- TIPOREG
                                                  NULL,  -- NUMREG
                                                  NULL,  -- CODPROD
                                                  NULL,  -- DESCRICAOPROD
                                                  NULL,  -- DCB
                                                  NULL,  -- DESCRICAODCB
                                                  NULL,  -- DTMOV
                                                  NULL,  -- DMEMISSENT
                                                  NULL,  -- CODCLI
                                                  NULL,  -- NUMNOTA
                                                  NULL,  -- NUMLOTE
                                                  NULL,  -- CODOPER
                                                  NULL,  -- QTESTINICIAL
                                                  NULL,  -- QTENT
                                                  NULL,  -- QTIMPORT
                                                  NULL,  -- QTAQUISICAO
                                                  NULL,  -- QTSAI
                                                  NULL,  -- QTPERDA
                                                  NULL,  -- QTESTOQUE
                                                  NULL,  -- HISTORICO
                                                  NULL,  -- OBSERVACOES
                                                  NULL,  -- SUBSTANCIA
                                                  NULL,  -- UNIDADEMEDIDA
                                                  NULL,  -- CNPJ
                                                  NULL,  -- RAZAOSOCIAL
                                                  NULL,  -- FORMULARIOBSPO
                                                  NULL,  -- DTEMISSAONOTAFISC
                                                  NULL,  -- ENDERECO
                                                  NULL,  -- UF
                                                  NULL,  -- MARCA
                                                  NULL,  -- EMBALAGEM
                                                  NULL,  -- CGCENT
                                                  NULL,  -- ENDERENT
                                                  NULL   -- DTSAIDANF
                                                  );
                                                  
  ------------------------------------------------------------------------------
  -- FUNCAO PARA RETORNAR O TEXTO DELIMITADO COM ASPAS SIMPLES
  ------------------------------------------------------------------------------
  FUNCTION FQUOTEDSTR(pi_vTexto IN VARCHAR) 
  RETURN VARCHAR2 IS
  BEGIN
    RETURN CHR(39) || pi_vTexto || CHR(39);
  END FQUOTEDSTR;                                                 

  ------------------------------------------------------------------------------
  -- PROCEDIMENTO PARA LIMPAR ARRAYS
  ------------------------------------------------------------------------------
  PROCEDURE PLIMPARRAYS IS
  BEGIN
    vtCODPROD.DELETE;
    vtDESCRICAOPROD.DELETE;
    vtDCB.DELETE;
    vtDESCRICAODCB.DELETE;
    vtSUBSTANCIA.DELETE;
    vtNUMTRANSENT.DELETE;
    vtNUMTRANSVENDA.DELETE;
    vtQTESTINICIAL.DELETE;
    vtQTENT.DELETE;
    vtQTSAI.DELETE;
    vtQTPERDA.DELETE;
    vtMARCA.DELETE;
    vtUNIDADE.DELETE;
    vtEMBALAGEM.DELETE;
  END PLIMPARRAYS;

  ------------------------------------------------------------------------------
  -- FUNCAO PARA OBTER O NUMERO DO LOTE DO INVENTÁRIO PARA OBSERVAÇÃO
  ------------------------------------------------------------------------------
  FUNCTION FOBTER_OBS_NUMLOTE(pi_vCodFilial              IN VARCHAR2,
                              pi_nNumNota                IN NUMBER,
                              pi_nCodProd                IN NUMBER,
                              pi_vCodOper                IN VARCHAR2,
                              pi_bUsaRegraNfObsPerda2318 IN BOOLEAN) 
  RETURN VARCHAR2 IS
    vvRetNumLote VARCHAR2(100);
  BEGIN
    -- Pesquisa Número de Lote
    BEGIN
      SELECT PCMOV.NUMLOTE
        INTO vvRetNumLote
        FROM PCMOV
       WHERE (PCMOV.CODFILIAL = pi_vCodFilial)
         AND (PCMOV.NUMNOTA   = pi_nNumNota)
         AND (PCMOV.CODPROD   = pi_nCodProd)
         AND (PCMOV.CODOPER   = pi_vCodOper)
         AND (PCMOV.NUMLOTE   IS NOT NULL) -->> Somente movimentações com Lote de Fabricação
         AND (ROWNUM          = 1);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvRetNumLote := NULL;
    END;
    -- Se achou algum Lote
    IF (vvRetNumLote IS NOT NULL) THEN
      IF (pi_bUsaRegraNfObsPerda2318) THEN
        vvRetNumLote := pi_vCodOper || ' - NF: ' || pi_nNumNota || '  Lote: ' || vvRetNumLote;
      ELSE
        vvRetNumLote := pi_vCodOper || ': ' || pi_nNumNota || ' Lote: ' || vvRetNumLote;
      END IF;
    -- Se NÃO achou algum Lote
    ELSE
      IF (pi_bUsaRegraNfObsPerda2318) THEN
        vvRetNumLote := pi_vCodOper || ' - NF: ' || pi_nNumNota;
      ELSE
        vvRetNumLote := pi_vCodOper || ': ' || pi_nNumNota;
      END IF;
    END IF;
    -- Retorno
    RETURN vvRetNumLote;
  END FOBTER_OBS_NUMLOTE;                                                 

  ------------------------------------------------------------------------------
  -- FUNCAO PARA OBTER O NOME DO FUNCIONARIO
  ------------------------------------------------------------------------------
  FUNCTION FOBTER_FUNCIONARIO(pi_vCodFilial IN VARCHAR2,
                              pi_nMatricula IN NUMBER) 
  RETURN VARCHAR2 IS
    vvRazaoSocialFilial PCFILIAL.RAZAOSOCIAL%TYPE;
    vvRetFuncionario    VARCHAR2(200);
  BEGIN
    -- Pesquisa Razão Social da Filial
    BEGIN
      SELECT PCFILIAL.RAZAOSOCIAL        
        INTO vvRazaoSocialFilial
        FROM PCFILIAL
       WHERE (PCFILIAL.CODIGO = pi_vCodFilial);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvRazaoSocialFilial := NULL;
    END;
    -- Pesquisa Funcionário
    BEGIN
      SELECT PCEMPR.NOME
        INTO vvRetFuncionario
        FROM PCEMPR
       WHERE (PCEMPR.MATRICULA = pi_nMatricula);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvRetFuncionario := NULL;
    END;
    -- Se achou algum Funcionário
    IF (vvRetFuncionario IS NOT NULL) THEN
      vvRetFuncionario := vvRazaoSocialFilial || ' / ' || vvRetFuncionario;
    ELSE
      vvRetFuncionario := vvRazaoSocialFilial;
    END IF;
    -- Retorno
    RETURN vvRetFuncionario;
  END FOBTER_FUNCIONARIO;   
  
  ------------------------------------------------------------------------------
  -- Função para Verificar se Usa Regra Específica de Medicamentos --
  -------------------------------------------------------------------
  FUNCTION FUSA_REGRA_MEDICAMENTOS(pi_vCodFilial IN VARCHAR2,
                                   pi_vNome      IN VARCHAR2)
  RETURN VARCHAR2 IS
    vvRetUsaRegraMedicamentos VARCHAR2(1);
  BEGIN
    -- Verifica se usa regra
    BEGIN
      EXECUTE IMMEDIATE ' SELECT VALOR FROM PCREGRASEXCECAOMED WHERE NOME = ' || '''' || pi_vNome || '''' || ' AND CODFILIAL = ' || '''' || pi_vCodFilial || ''''
                   INTO vvRetUsaRegraMedicamentos;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvRetUsaRegraMedicamentos := 'N';
      WHEN OTHERS THEN
        vvRetUsaRegraMedicamentos := 'N';
    END;
    -- Retorno
    RETURN vvRetUsaRegraMedicamentos;
  END FUSA_REGRA_MEDICAMENTOS;                                                

BEGIN

  -- Condições Complementares ao SQL
  IF (pi_vsConsiderarFilialNF = 'S' ) AND (pi_vCodFilialNF IS NOT NULL) THEN
    vvWhereFilial      := ' AND (NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = ' || FQUOTEDSTR(pi_vCodFilialNF) || ') ';
  ELSE
    vvWhereFilial      := ' AND (PCMOV.CODFILIAL = ' || FQUOTEDSTR(pi_vCodFilial) || ') ';
  END IF;

  -- Where de Periodo Anterior
  vvWherePerAnterior := ' AND (PCMOV.DTMOV  < TO_DATE(' || FQUOTEDSTR(pi_vDataInicial)  || ',' || FQUOTEDSTR('DD/MM/YYYY') || ')) ';
  -- Where de Período
  vvWherePeriodo     := ' AND ((PCMOV.DTMOV >= TO_DATE(' || FQUOTEDSTR(pi_vDataInicial) || ',' || FQUOTEDSTR('DD/MM/YYYY') || ')) AND ' ||
                        '      (PCMOV.DTMOV  < TO_DATE(' || FQUOTEDSTR(pi_vDataFinal)   || ',' || FQUOTEDSTR('DD/MM/YYYY') || ')+1)) ';
  IF (TRIM(pi_vInListas) IS NOT NULL) THEN
    vvInLista        := ' AND ( (NVL(PCPRINCIPATIVO1.SUBSTANCIA,PCPRODUT.SUBSTANCIA) IN (' || pi_vInListas || ')) OR (PCPRINCIPATIVO2.SUBSTANCIA IN (' || pi_vInListas || ')) )';  
  ELSE    
    vvInLista        := ' ';
  END IF;    
  IF (TRIM(pi_vInProdutos) IS NOT NULL) THEN
    vvInProdutos     := ' AND (PCMOV.CODPROD IN (' || pi_vInProdutos || ')) ';  
  ELSE    
    vvInProdutos     := ' ';
  END IF;    
  
  -- Pesquisa Parâmetro Geral
  -- OBS: '1' - Todas as Movimentações e todos os Acertos de Inventário      
  --      '2' - Somente Gerencial e todos os Acertos de Inventário      
  --      '3' - Todas as Movimentações e somente Acerto de Estoque de Inventário
  --      '4' - Somente Gerencial e somente Acerto de Estoque de Inventário
  --      '5' - Inventário Inicial + Movimentações Contábeis
  --      '6' - Somente Contábil (Clientes cujo Inventário Inicial foi AB)
  BEGIN
    SELECT NVL(VALOR,'1') -->> Valor Default = '1' - Todas as Movimentações e todos os Acertos de Inventário      
      INTO vvTipoMovEscrituracaoMed
      FROM PCPARAMFILIAL
     WHERE (NOME      = 'TIPOMOVESCRITURACAOMED')
       AND (CODFILIAL = '99');
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -->> Valor Default = '1' - Todas as Movimentações e todos os Acertos de Inventário      
      vvTipoMovEscrituracaoMed := '1';
  END;
  --
  BEGIN
    SELECT NVL(VALOR,'N') -->> Valor Default = 'N' - Não
      INTO vvApresAutoInutilizEscritMed
      FROM PCPARAMFILIAL
     WHERE (NOME      = 'APRESAUTOINUTILIZESCRITMED')
       AND (CODFILIAL = pi_vCodFilial);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -->> Valor Default = 'N' - Não
      vvApresAutoInutilizEscritMed := 'N';
  END;  
  
  -- Regra Específica
  BEGIN
    vbUsaRegraNfObsPerda2318 := (FUSA_REGRA_MEDICAMENTOS('99','USAREGRANFOBSPERDA2318') = 'S');
  EXCEPTION
    WHEN OTHERS THEN
      vbUsaRegraNfObsPerda2318 := FALSE;
  END;
  
  -- Se informou mais de uma Substância no Filtro
  IF INSTR(pi_vInListas,',') > 0 THEN
    vvMultiplasSubstancias := 1;
  ELSE
    vvMultiplasSubstancias := 0;
  END IF;
    
 /******************************************************************************  
  Se RMV GOIAS ou Movimentações BSPO ou RMV TO (Saídas)
  *****************************************************/  
  IF    (pi_nTipoHistorico IN (1,4,5,6,7,8,9)) THEN  

    -- Prepara Sql
    vvSql := ' ';
    
    -- Se RMV - GO terá o Select de Saldo Inicial
    IF (pi_nTipoHistorico IN (1,9)) THEN
    
      vvSql := vvSql ||
            ' SELECT 0 TIPOREG
                   , PCMOV.CODPROD 
                   , PCPRODUT.DESCRICAO DESCRICAOPROD
                   -- Concatenar DCB apenas se informado mais de uma Substância no Filtro e produto possui Princípio ativo 2
                   , CASE 
                       WHEN (1 = ' || vvMultiplasSubstancias || ') AND (NVL(PCPRODUT.CODPRINCIPATIVO2,0) > 0) THEN
                         PCPRINCIPATIVO1.DCB || '' / '' || PCPRINCIPATIVO2.DCB
                      ELSE
                         PCPRINCIPATIVO1.DCB    
                     END DCB    
                   , CASE 
                       WHEN (1 = ' || vvMultiplasSubstancias || ') AND (NVL(PCPRODUT.CODPRINCIPATIVO2,0) > 0) THEN
                         PCPRINCIPATIVO1.DESCRICAO || '' / '' || PCPRINCIPATIVO2.DESCRICAO
                      ELSE
                         PCPRINCIPATIVO1.DESCRICAO    
                     END DESCRICAODCB
                   , PCPRODUT.UNIDADE 
                   , PCPRODUT.EMBALAGEM 
                   , NULL DTMOV
                   , NULL DTEMISSENT
                   , NULL CODCLI
                   , NULL NUMNOTA
                   , NULL NUMLOTE
                   , NULL NUMTRANSENT
                   , NULL NUMTRANSVENDA
                   , NULL CODOPER
                   , 0 QTENT
                   , 0 QTSAI
                   , 0 QTPERDA
                   , SUM(NVL(CASE WHEN (SUBSTR(PCMOV.CODOPER,1,1) = ''E'') THEN 
                                    DECODE(NVL(PCMOV.QTCONT,0),0,NVL(PCMOV.QT,0),NVL(PCMOV.QTCONT,0)) 
                                  WHEN (SUBSTR(PCMOV.CODOPER,1,1) = ''S'') THEN 
                                    (DECODE(NVL(PCMOV.QTCONT,0),0,NVL(PCMOV.QT,0),NVL(PCMOV.QTCONT,0)) * -1) 
                                  ELSE 
                                    0 
                              END,0)) QTESTOQUE
                   , NULL HISTORICO
                   , NULL OBSERVACOES
                   , NULL CODFUNCLANC
                   , PCMARCA.MARCA
                   -- Concatenar Substância apenas se informado mais de uma Substância no Filtro e produto possui Princípio ativo 2
                   , CASE 
                       WHEN (1 = ' || vvMultiplasSubstancias || ') AND (NVL(PCPRODUT.CODPRINCIPATIVO2,0) > 0) THEN
                         NVL(PCPRINCIPATIVO1.SUBSTANCIA,PCPRODUT.SUBSTANCIA) ||  '' / '' || PCPRINCIPATIVO2.SUBSTANCIA
                      ELSE
                         NVL(PCPRINCIPATIVO1.SUBSTANCIA,PCPRODUT.SUBSTANCIA)
                     END SUBSTANCIA
                   , 0 NUMTRANSITEM
                FROM PCMOV 
                   , PCPRODUT 
                   , PCPRINCIPATIVO PCPRINCIPATIVO1
                   , PCPRINCIPATIVO PCPRINCIPATIVO2
                   , PCMARCA
               WHERE (PCPRODUT.CODPROD = PCMOV.CODPROD) 
                 AND (PCPRODUT.CODPRINCIPATIVO = PCPRINCIPATIVO1.CODPRINCIPATIVO(+))
                 AND (PCPRODUT.CODPRINCIPATIVO2 = PCPRINCIPATIVO2.CODPRINCIPATIVO(+))
                 AND (PCPRODUT.CODMARCA = PCMARCA.CODMARCA(+))
                 AND ((PCMOV.PERCQUEBRADO IS NULL) OR (PCMOV.PERCQUEBRADO = 0)) ' || vvWhereFilial || vvWherePerAnterior || vvInLista || vvInProdutos;
      -- Filtro de Tipo de Movimentações no Saldo Inicial
      IF (vvTipoMovEscrituracaoMed IN ('5')) THEN
        vvSql := vvSql || ' AND ( (PCMOV.STATUS IN (''A'',''AB'')) OR ((PCMOV.STATUS = ''B'') AND (PCMOV.CODOPER = ''EI'')) ) ';      
      -- Filtro de Tipo de Movimentações Contábeis
      ELSIF (vvTipoMovEscrituracaoMed IN ('6')) THEN
        vvSql := vvSql || ' AND (PCMOV.STATUS IN (''A'',''AB'')) ';      
      ELSE
        IF (vvTipoMovEscrituracaoMed IN ('2','4')) THEN
          vvSql := vvSql || ' AND (PCMOV.STATUS IN (''B'',''AB'')) ';      
        END IF;
        -- Filtro de Somente Acertos de Estoque de Inventário
        IF (vvTipoMovEscrituracaoMed IN ('3','4')) THEN
          vvSql := vvSql || ' AND ((PCMOV.CODOPER IN (''EI'', ''SI'') AND PCMOV.NUMLOTE IS NULL) OR (PCMOV.CODOPER NOT IN (''EI'', ''SI''))) ';      
          vvSql := vvSql || ' AND (DECODE(NVL(PCMOV.QTCONT,0),0,NVL(PCMOV.QT,0),NVL(PCMOV.QTCONT,0)) <> 0) ';      
        END IF;
      END IF;       
      -- Não enviar o "SV" para não Duplicar as Movimentações
      vvSql := vvSql || ' AND (PCMOV.CODOPER NOT IN (''SV'')) ';      
      --      
      vvSql := vvSql ||
             ' GROUP BY PCMOV.CODPROD
                      , PCPRODUT.DESCRICAO
                      , CASE 
                          WHEN (1 = ' || vvMultiplasSubstancias || ') AND (NVL(PCPRODUT.CODPRINCIPATIVO2,0) > 0) THEN
                            PCPRINCIPATIVO1.DCB || '' / '' || PCPRINCIPATIVO2.DCB
                          ELSE
                            PCPRINCIPATIVO1.DCB    
                        END
                      , CASE 
                          WHEN (1 = ' || vvMultiplasSubstancias || ') AND (NVL(PCPRODUT.CODPRINCIPATIVO2,0) > 0) THEN
                            PCPRINCIPATIVO1.DESCRICAO || '' / '' || PCPRINCIPATIVO2.DESCRICAO
                          ELSE
                            PCPRINCIPATIVO1.DESCRICAO    
                        END
                      , PCPRODUT.UNIDADE 
                      , PCPRODUT.EMBALAGEM 
                      , PCMARCA.MARCA
                      , CASE 
                          WHEN (1 = ' || vvMultiplasSubstancias || ') AND (NVL(PCPRODUT.CODPRINCIPATIVO2,0) > 0) THEN
                            NVL(PCPRINCIPATIVO1.SUBSTANCIA,PCPRODUT.SUBSTANCIA) ||  '' / '' || PCPRINCIPATIVO2.SUBSTANCIA
                          ELSE
                            NVL(PCPRINCIPATIVO1.SUBSTANCIA,PCPRODUT.SUBSTANCIA)
                        END
               UNION ';
               
    END IF; -- Fim Condição Se RMV - GO terá o Select de Saldo Inicial          
    
    -- Em todos terá as Movimentações
    vvSql := vvSql ||
            ' SELECT 1 TIPOREG
                   , PCMOV.CODPROD 
                   , PCPRODUT.DESCRICAO DESCRICAOPROD
                   -- Concatenar DCB apenas se informado mais de uma Substância no Filtro e produto possui Princípio ativo 2
                   , CASE 
                       WHEN (1 = ' || vvMultiplasSubstancias || ') AND (NVL(PCPRODUT.CODPRINCIPATIVO2,0) > 0) THEN
                         PCPRINCIPATIVO1.DCB || '' / '' || PCPRINCIPATIVO2.DCB
                      ELSE
                         PCPRINCIPATIVO1.DCB    
                     END DCB   
                   , CASE 
                       WHEN (1 = ' || vvMultiplasSubstancias || ') AND (NVL(PCPRODUT.CODPRINCIPATIVO2,0) > 0) THEN
                         PCPRINCIPATIVO1.DESCRICAO || '' / '' || PCPRINCIPATIVO2.DESCRICAO
                      ELSE
                         PCPRINCIPATIVO1.DESCRICAO    
                     END DESCRICAODCB
                   , PCPRODUT.UNIDADE 
                   , PCPRODUT.EMBALAGEM 
                   , PCMOV.DTMOV
                   , NULL DTEMISSENT
                   , PCMOV.CODCLI                       
                   , PCMOV.NUMNOTA
                   , PCMOV.NUMLOTE
                   , PCMOV.NUMTRANSENT
                   , PCMOV.NUMTRANSVENDA
                   , PCMOV.CODOPER
                   , NVL(CASE WHEN (SUBSTR(PCMOV.CODOPER,1,1) = ''E'') THEN 
                                DECODE(NVL(PCMOV.QTCONT,0),0,NVL(PCMOV.QT,0),NVL(PCMOV.QTCONT,0)) 
                         END,0) QTENT 
                   , NVL(CASE WHEN ((SUBSTR(PCMOV.CODOPER,1,1) = ''S'') AND 
                                   (PCMOV.CODOPER NOT IN (''SA'', ''SI''))) THEN 
                                DECODE(NVL(PCMOV.QTCONT,0),0,NVL(PCMOV.QT,0),NVL(PCMOV.QTCONT,0)) 
                         END,0) QTSAI 
                   , NVL(CASE WHEN ((SUBSTR(PCMOV.CODOPER,1,1) = ''S'') AND 
                                   (PCMOV.CODOPER IN (''SA'', ''SI''))) THEN 
                                DECODE(NVL(PCMOV.QTCONT,0),0,NVL(PCMOV.QT,0),NVL(PCMOV.QTCONT,0)) 
                         END,0) QTPERDA 
                   , 0 QTESTOQUE          
                   , NULL HISTORICO
                   , NULL OBSERVACOES
                   , PCMOV.CODFUNCLANC
                   , PCMARCA.MARCA
                   , CASE 
                       WHEN (1 = ' || vvMultiplasSubstancias || ') AND (NVL(PCPRODUT.CODPRINCIPATIVO2,0) > 0) THEN
                         NVL(PCPRINCIPATIVO1.SUBSTANCIA,PCPRODUT.SUBSTANCIA) ||  '' / '' || PCPRINCIPATIVO2.SUBSTANCIA
                       ELSE
                         NVL(PCPRINCIPATIVO1.SUBSTANCIA,PCPRODUT.SUBSTANCIA)
                     END
                   , PCMOV.NUMTRANSITEM
                FROM PCMOV 
                   , PCPRODUT 
                   , PCPRINCIPATIVO PCPRINCIPATIVO1
                   , PCPRINCIPATIVO PCPRINCIPATIVO2
                   , PCMARCA
               WHERE (PCPRODUT.CODPROD = PCMOV.CODPROD) 
                 AND (PCPRODUT.CODPRINCIPATIVO = PCPRINCIPATIVO1.CODPRINCIPATIVO(+))
                 AND (PCPRODUT.CODPRINCIPATIVO2 = PCPRINCIPATIVO2.CODPRINCIPATIVO(+))
                 AND (PCPRODUT.CODMARCA = PCMARCA.CODMARCA(+))
                 AND (PCMOV.DTCANCEL IS NULL) -- Movimentações somente que não foram Canceladas
                 AND ((PCMOV.PERCQUEBRADO IS NULL) OR (PCMOV.PERCQUEBRADO = 0)) ' || vvWhereFilial || vvWherePeriodo || vvInLista || vvInProdutos;

    -- Se Formulário III - BSPO (Balanço de Aquisições), somente considera Entradas
    IF    (pi_nTipoHistorico = 4) THEN
      vvSql := vvSql || ' AND (SUBSTR(PCMOV.CODOPER,1,1) = ''E'') ' ||
                        ' AND (PCMOV.CODOPER <> ''EA'') '; -- 1870.001198.2017
    -- Se Formulário IV - BSPO (Balanço de Vendas) somente considera Vendas
    ELSIF (pi_nTipoHistorico IN (5)) THEN
      vvSql := vvSql || ' AND ((SUBSTR(PCMOV.CODOPER,1,1) = ''S'') AND 
                              (PCMOV.CODOPER NOT IN (''SA'', ''SI''))) ';
    -- RMV - (Saídas) somente considera Saidas
    ELSIF (pi_nTipoHistorico IN (7)) THEN
      vvSql := vvSql || ' AND (PCMOV.CODOPER = ''S'') ';
    END IF;
    
    -- Filtro de Tipo de Movimentações nas Movimentações
    IF (vvTipoMovEscrituracaoMed IN ('5')) THEN
      vvSql := vvSql || ' AND ( (PCMOV.STATUS IN (''A'',''AB'')) OR ((PCMOV.STATUS = ''B'') AND (PCMOV.CODOPER = ''EI'')) ) ';      
    -- Filtro de Tipo de Movimentações Contábeis
    ELSIF (vvTipoMovEscrituracaoMed IN ('6')) THEN
      vvSql := vvSql || ' AND (PCMOV.STATUS IN (''A'',''AB'')) ';      
    ELSE
      IF (vvTipoMovEscrituracaoMed IN ('2','4')) THEN
        vvSql := vvSql || ' AND (PCMOV.STATUS IN (''B'',''AB'')) ';      
      END IF;
      -- Filtro de Somente Acertos de Estoque de Inventário
      IF (vvTipoMovEscrituracaoMed IN ('3','4')) THEN
        vvSql := vvSql || ' AND ((PCMOV.CODOPER IN (''EI'', ''SI'') AND PCMOV.NUMLOTE IS NULL) OR (PCMOV.CODOPER NOT IN (''EI'', ''SI''))) ';      
        vvSql := vvSql || ' AND (DECODE(NVL(PCMOV.QTCONT,0),0,NVL(PCMOV.QT,0),NVL(PCMOV.QTCONT,0)) <> 0) ';      
      END IF;    
    END IF;         
    -- Filtro para quem usa o Auto Inutilização - HIS.03778.2015
    -- NÃO APRESENTAR SV PARA TUDO
    --IF (vvApresAutoInutilizEscritMed = 'S') THEN
    -- Somente mandar o "SA" da Movimentação da Saída de Perda de Avaria (Contábil), não enviar o "SV" para não Duplicar as Movimentações
    -- Não enviar o "SV" para não Duplicar as Movimentações
    vvSql := vvSql || ' AND (PCMOV.CODOPER NOT IN (''SV'')) ';      
    --END IF;
    -- Finaliza Select com o Order By (priorizar CODOPER no mesmo dia para as entradas sairem primeiro)

   /* vvSql := vvSql ||
             ' ORDER BY CODPROD, TIPOREG, DTMOV, CODOPER, NUMNOTA ';*/

    vvSql := vvSql ||
             ' ORDER BY DESCRICAOPROD,CODPROD,TIPOREG,DTMOV,CODOPER, NUMNOTA';

    -- Insere Dados em Arrays
    EXECUTE IMMEDIATE vvSql
      BULK COLLECT INTO vtTIPOREG,
                        vtCODPROD,
                        vtDESCRICAOPROD,
                        vtDCB,
                        vtDESCRICAODCB,
                        vtUNIDADE,
                        vtEMBALAGEM,
                        vtDTMOV,
                        vtDTEMISSENT,
                        vtCODCLI,
                        vtNUMNOTA,
                        vtNUMLOTE,
                        vtNUMTRANSENT,
                        vtNUMTRANSVENDA,
                        vtCODOPER,
                        vtQTENT,
                        vtQTSAI,
                        vtQTPERDA,
                        vtQTESTOQUE,
                        vtHISTORICO,
                        vtOBSERVACOES,
                        vtCODFUNCLANC,
                        vtMARCA,
                        vtSUBSTANCIA,
                        vtNUMTRANSITEM;

    -- Se achou Movimentações
    IF (vtTIPOREG.COUNT > 0) THEN

      -- Inicializa Número do Registro
      vnNumReg       := 0;
      -- Inicializa Controle de Quebra de Produtox
      vnCodProdAnt   := -1;
      -- Inicializa Saldo de Estoque
      vnSaldoEstoque := 0;

      -- Laço de Movimentações 
      FOR viLaco IN vtTIPOREG.FIRST..vtTIPOREG.LAST LOOP

        -- Inicializa Flag indicando que Considera a Movimentação
        vbConsideraMovimentacao  := TRUE;
        -- Inicializa Identificador de Formulário BSPO
        vtFORMULARIOBSPO(viLaco) := NULL;
        -- Inicializa a Data de Emissão da NF
        vtDTEMISSAONF(viLaco)    := NULL;
        -- Data de emissão nf saida
        vtDTSAIDANF(viLaco)      := NULL;
        
        --  MED-1672 - Busca dados do Cliente 
        IF (NVL(vtCODCLI(viLaco),0) > 0) THEN
          IF NOT (vtDadosCli.EXISTS(vtCODCLI(viLaco))) THEN
            BEGIN
              SELECT CGCENT
                   , ENDERENT
                INTO vrDadosCli.vvCgcEnt
                   , vrDadosCli.vvEnderEnt
                FROM PCCLIENT
               WHERE CODCLI = vtCODCLI(viLaco);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vrDadosCli.vvCgcEnt := NULL;
                vrDadosCli.vvEnderEnt := NULL;
            END;  
            vtDadosCli(vtCODCLI(viLaco)) := vrDadosCli;         
          END IF;
          vtCGCENT(viLaco)   := vtDadosCli(vtCODCLI(viLaco)).vvCgcEnt;
          vtENDERENT(viLaco) := vtDadosCli(vtCODCLI(viLaco)).vvEnderEnt;         
        ELSE
          vtCGCENT(viLaco)   := NULL;
          vtENDERENT(viLaco) := NULL;
        END IF;

        -- Verifica se Rejeita a Movimentação de Saída -------------------------
        IF (UPPER(SUBSTR(vtCODOPER(viLaco),1,1)) = 'S') THEN
   
          -- Formulário BSPO de Vendas
          vtFORMULARIOBSPO(viLaco) := 4;
        
          -- Se a Transação for um INTEGER, utiliza pesquisa em memória para otimizar processo
          IF (NVL(vtNUMTRANSVENDA(viLaco),0) BETWEEN 1 AND viValorMaxInteger) THEN 
            -- Primeiro pesquisa a Especie da NF em memória,
            -- se não existir em memória pesquisa na base de dados
            IF NOT (vtEspecieNFSaida.EXISTS(vtNUMTRANSVENDA(viLaco))) THEN
              BEGIN
                SELECT PCNFSAID.ESPECIE
                     , PCNFSAID.DTSAIDA
                  INTO vvEspecie                
                     , vvDtNfSaid
                  FROM PCNFSAID
                 WHERE (PCNFSAID.NUMTRANSVENDA = vtNUMTRANSVENDA(viLaco));
              EXCEPTION
                WHEN NO_DATA_FOUND THEN          
                  vvEspecie  := NULL;
                  vvDtNfSaid := NULL;
              END;
              vtEspecieNFSaida(vtNUMTRANSVENDA(viLaco)) := vvEspecie;
              vtDataNFSaida(vtNUMTRANSVENDA(viLaco))    := vvDtNfSaid;
            ELSE
              vvEspecie  := vtEspecieNFSaida(vtNUMTRANSVENDA(viLaco));
              vvDtNfSaid := vtDataNFSaida(vtNUMTRANSVENDA(viLaco));              
            END IF;
          -- Se a Transação não for um INTEGER, pequisa sempre no Banco de Dados
          ELSE
            BEGIN
              SELECT PCNFSAID.ESPECIE
                   , PCNFSAID.DTSAIDA
                INTO vvEspecie                
                   , vvDtNfSaid
                FROM PCNFSAID
               WHERE (PCNFSAID.NUMTRANSVENDA = vtNUMTRANSVENDA(viLaco));
            EXCEPTION
              WHEN NO_DATA_FOUND THEN          
                vvEspecie  := NULL;
                vvDtNfSaid := NULL;
            END;
          END IF; 
          -- Se a Especie da NF for igual a 'NE', indica que está aguardando autorização do SEFAZ,
          -- nesse caso ignora a Movimentação
          IF (vvEspecie = 'NE') THEN
            vbConsideraMovimentacao := FALSE;
          END IF;  
          
          -- Atualizando campo no laço com a Dt de emissão de nf de saída.
          IF vvDtNfSaid IS NOT NULL THEN
            vtDTSAIDANF(viLaco) := vvDtNfSaid;
          END IF;                
          
        END IF; -- Fim Condição Saídas
        
        -- Verifica se Rejeita a Movimentação de Entrada -----------------------
        IF (UPPER(SUBSTR(vtCODOPER(viLaco),1,1)) = 'E') THEN
        
          -- Formulário BSPO de Aquisições
          vtFORMULARIOBSPO(viLaco) := 3;
          
          -- Se a Transação for um INTEGER, utiliza pesquisa em memória para otimizar processo
          IF (NVL(vtNUMTRANSENT(viLaco),0) BETWEEN 1 AND viValorMaxInteger) THEN 
            -- Primeiro pesquisa a Especie da NF em memória,
            -- se não existir em memória pesquisa na base de dados
            IF NOT (vtEspecieNFEntrada.EXISTS(vtNUMTRANSENT(viLaco))) THEN
              BEGIN
                SELECT PCNFENT.ESPECIE
                     , PCNFENT.TIPODESCARGA
                     , PCNFENT.DTEMISSAO
                  INTO vvEspecie           
                     , vvTipoDescarga                       
                     , vvDtNfSaid
                  FROM PCNFENT
                 WHERE (PCNFENT.NUMTRANSENT = vtNUMTRANSENT(viLaco))
                   AND (ROWNUM              = 1);
              EXCEPTION
                WHEN NO_DATA_FOUND THEN          
                  vvEspecie      := NULL;
                  vvTipoDescarga := NULL;   
                  vvDtNfSaid     := NULL;                    
              END;
              vtEspecieNFEntrada(vtNUMTRANSENT(viLaco))  := vvEspecie;
              vtTipoDescargaNFEnt(vtNUMTRANSENT(viLaco)) := vvTipoDescarga;
              vtDataNFEntrada(vtNUMTRANSENT(viLaco))     := vvDtNfSaid;
            ELSE
              vvEspecie      := vtEspecieNFEntrada(vtNUMTRANSENT(viLaco));
              vvTipoDescarga := vtTipoDescargaNFEnt(vtNUMTRANSENT(viLaco));
              vvDtNfSaid     := vtDataNFEntrada(vtNUMTRANSENT(viLaco));
            END IF;
          -- Se a Transação não for um INTEGER, pequisa sempre no Banco de Dados
          ELSE
            BEGIN
              SELECT PCNFENT.ESPECIE
                   , PCNFENT.TIPODESCARGA
                   , PCNFENT.DTEMISSAO
                INTO vvEspecie                
                   , vvTipoDescarga                       
                   , vvDtNfSaid
                FROM PCNFENT
               WHERE (PCNFENT.NUMTRANSENT = vtNUMTRANSENT(viLaco))
                 AND (ROWNUM              = 1);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN          
                vvEspecie      := NULL;
                vvTipoDescarga := NULL;
                vvDtNfSaid     := NULL;                                    
            END;
          END IF; 
          -- Se a Especie da NF for igual a 'NE', indica que está aguardando autorização do SEFAZ,
          -- nesse caso ignora a Movimentação
          -- Desconsidera Transação de Atualização de Estoque de Importação
          IF ((NVL(vvEspecie     ,' ') = 'NE') OR
              (NVL(vvTipoDescarga,' ') = 'I' )) THEN
            vbConsideraMovimentacao := FALSE;
          END IF;        
          
          -- Atualizando campo no laço com a Dt de emissão de nf de ENTRADA.
          IF vvDtNfSaid IS NOT NULL THEN
            vtDTSAIDANF(viLaco) := vvDtNfSaid;
          END IF;        
          
        END IF; -- Fim Condição Entradas

       /***************************
        Se Considera a Movimentação
        ***************************/
        IF (vbConsideraMovimentacao) THEN   
        
          -- Se ocorreu quebra de Produto ------------------------------------------
          IF (NVL(vnCodProdAnt,0) <> NVL(vtCODPROD(viLaco),0)) THEN
        
            -- Atualiza Controle de Quebra de Produto
            vnCodProdAnt := vtCODPROD(viLaco);
          
            -- Se o Registro da Quebra de Produto for do Tipo 0 - Estoque Inicial
            IF (vtTIPOREG(viLaco) = 0) THEN

              -- Pega Estoque Inicial do Registro Tipo 0
              vnSaldoEstoque := NVL(vtQTESTOQUE(viLaco),0);

              -- Verifica se o próximo registro pertence ao mesmo produto
              IF (vtCODPROD.EXISTS(viLaco+1)) THEN
                -- Se o próximo registro pertencer ao mesmo produto, 
                -- ele só poderá ser de movimentações, tendo em vista que só  
                -- existirá um registro tipo 0 (zero) por produto
                IF (vtCODPROD(viLaco+1) = vtCODPROD(viLaco)) THEN            
                  vbExistemMovimProduto := TRUE; 
                ELSE
                  vbExistemMovimProduto := FALSE; 
                END IF;              
              ELSE
                -- Se não existirem mais dados no Array, isso em sim já garante que
                -- não existem movimentações para este produto 
                vbExistemMovimProduto := FALSE; 
              END IF;
                    
            -- Se Registro da Quebra for do Tipo 1 - Movimentações 
            -- (ocorre quando não existe histórico de estoque inicial por ausência de
            -- movimentações anteriores à data inicial passada no parâmetro)
            ELSE

              -- Não existem movimentações anteriores à data inicial, inicia com estoque zero
              vnSaldoEstoque := 0;

              -- Se o Registro da quebra do Produto é do tipo movimentação, 
              -- isso em si já garante que existem movimentações para o produto
              -- no periodo passado no parâmetro
              vbExistemMovimProduto := TRUE;
                    
            END IF;        

            -- Se existirem movimentações no período passado no parâmetro para o Produto
            IF (vbExistemMovimProduto) THEN
          
              -- Se RMV - GO terá dados na TABLE de Saldo Inicial
              IF (pi_nTipoHistorico in (1,9)) THEN
          
                -- Define Histórico
                IF (pi_nTipoObservacao IN (1,3,9)) THEN
                  vvHistorico    := 'Saldo Inicial'; 
                END IF;          
          
                -- Atualiza Campos da Table 
                vnNumReg              := NVL(vnNumReg,0) + 1;
                OUTROW.NUMREG         := NVL(vnNumReg,0);
                OUTROW.TIPOREG        := 0; -- Registro de Estoque Inicial
                OUTROW.CODPROD        := vtCODPROD(viLaco);
                OUTROW.DESCRICAOPROD  := vtDESCRICAOPROD(viLaco);
                OUTROW.DCB            := vtDCB(viLaco);
                OUTROW.DESCRICAODCB   := vtDESCRICAODCB(viLaco);
                OUTROW.DTMOV          := NULL; -- Sem Data Movimento
                OUTROW.DTEMISSENT     := NULL; -- Sem Data Emissão Origem
                OUTROW.CODCLI         := NULL; -- Sem Código do Cliente
                OUTROW.NUMNOTA        := NULL; -- Sem NF
                OUTROW.NUMLOTE        := NULL; -- Sem Lote
                OUTROW.CODOPER        := NULL; -- Sem Código de Operação
                OUTROW.QTENT          := NULL; -- Sem Qtde. Entrada
                OUTROW.QTSAI          := NULL; -- Sem Qtde. Saida
                OUTROW.QTPERDA        := NULL; -- Sem Qtde. Perdas
                OUTROW.QTESTOQUE      := vnSaldoEstoque;
                OUTROW.HISTORICO      := vvHistorico;
                OUTROW.OBSERVACOES    := NULL; -- Sem Observação
                OUTROW.MARCA          := vtMARCA(viLaco);
                OUTROW.UNIDADEMEDIDA  := vtUNIDADE(viLaco);
                OUTROW.SUBSTANCIA     := vtSUBSTANCIA(viLaco);
                OUTROW.EMBALAGEM      := vtEMBALAGEM(viLaco);
                OUTROW.CGCENT         := vtCGCENT(viLaco);
                OUTROW.ENDERENT       := vtENDERENT(viLaco);
                OUTROW.DTSAIDANF      := vtDTSAIDANF(viLaco);
        
                -- Insere dados na Table
                PIPE ROW(OUTROW);
              
              END IF; -- Fim Condição Se RMV - GO terá dados na TABLE de Saldo Inicial
            
            END IF; -- Fim Condição Se existirem movimentações no período passado no parâmetro para o Produto
           
          END IF; -- Fim Condição Se ocorreu quebra de Produto
                                    
          ------------------------------------------------------------------------
          -- Se Registro de Movimentações ----------------------------------------
          ------------------------------------------------------------------------
          IF (vtTIPOREG(viLaco) = 1) THEN
     
            -- Entradas ------------------------------------------------------------
            IF    (UPPER(SUBSTR(vtCODOPER(viLaco),1,1)) = 'E') THEN
          
              -- Incrementa Saldo Estoque
              vnSaldoEstoque := NVL(vnSaldoEstoque,0) + NVL(vtQTENT(viLaco),0);
             
              -- Define Observação
              IF (NVL(vtCODOPER(viLaco),' ') IN ('EA', 'EI')) THEN -->> Se perdas, não tem NF
                -- Filtro de Somente Acertos de Estoque de Inventário
                IF (vvTipoMovEscrituracaoMed IN ('3','4')) THEN
                  vvObservacao := FOBTER_OBS_NUMLOTE(pi_vCodFilial,
                                                     vtNUMNOTA(viLaco),
                                                     vtCODPROD(viLaco),
                                                     vtCODOPER(viLaco),
                                                     vbUsaRegraNfObsPerda2318) ;
                ELSE
                  IF (vbUsaRegraNfObsPerda2318) THEN
                    vvObservacao := 'NF: ' || vtNUMNOTA(viLaco) || '  ' || 'Lote: ' || vtNUMLOTE(viLaco);
                  ELSE
                    vvObservacao := 'Lote: ' || vtNUMLOTE(viLaco);
                  END IF;
                END IF;
              ELSE
                vvObservacao := 'NF: '   || vtNUMNOTA(viLaco) || '  ' || 'Lote: ' || vtNUMLOTE(viLaco);
              END IF;

              -- Pesquisa Dados da Entrada de Devolução de Clientes
              IF (NVL(vtCODOPER(viLaco),' ') = 'ED') THEN 
                BEGIN
                  SELECT PCNFENT.DTEMISSAO
                       , PCCLIENT.CLIENTE
                       , PCCLIENT.CGCENT
                       , PCCLIENT.FANTASIA
                       , SUBSTR('END: ' || PCCLIENT.ENDERENT || ', ' || PCCLIENT.NUMEROENT || ',' || 'BAIRRO: ' || PCCLIENT.BAIRROENT || '. ' || PCCLIENT.MUNICENT,1,100)
                       , PCCLIENT.ESTENT
                    INTO vdDtEmissao
                        , vvRazaoSocial
                        , vvCnpj
                        , vvFantasia
                        , vvEndereco
                        , vvUf
                    FROM PCNFENT
                       , PCCLIENT
                   WHERE (PCNFENT.NUMTRANSENT = vtNUMTRANSENT(viLaco))
                     AND (PCNFENT.NUMNOTA     = vtNUMNOTA(viLaco))
                     AND (PCNFENT.CODFORNEC   = PCCLIENT.CODCLI(+))
                     AND (ROWNUM              = 1);
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN          
                    vdDtEmissao   := NULL;
                    vvRazaoSocial := NULL;
                    vvCnpj        := NULL;
                    vvFantasia    := NULL;
                    vvEndereco    := NULL;
                    vvUf          := NULL;
                END;
              -- Pesquisa Dados da Entrada de Fornecedor
              ELSE
                BEGIN
                  SELECT PCNFENT.DTEMISSAO
                       , PCFORNEC.FORNECEDOR
                       , PCFORNEC.CGC
                       , PCFORNEC.FANTASIA
                       , SUBSTR('END: ' || PCFORNEC.ENDERCOB || ', ' || PCFORNEC.NUMEROEND || ',' || 'BAIRRO: ' || PCFORNEC.BAIRROCOB || '. ' || PCFORNEC.MUNICOB,1,100)
                       , PCFORNEC.ESTADO
                    INTO vdDtEmissao
                       , vvRazaoSocial
                       , vvCnpj
                       , vvFantasia
                       , vvEndereco
                       , vvUf
                    FROM PCNFENT
                       , PCFORNEC
                   WHERE (PCNFENT.NUMTRANSENT = vtNUMTRANSENT(viLaco))
                     AND (PCNFENT.NUMNOTA     = vtNUMNOTA(viLaco))
                     AND (PCNFENT.CODFORNEC   = PCFORNEC.CODFORNEC(+))
                     AND (ROWNUM              = 1);
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN          
                    vdDtEmissao   := NULL;
                    vvRazaoSocial := NULL;
                    vvCnpj        := NULL; 
                    vvFantasia    := NULL;
                    vvEndereco    := NULL;
                    vvUf          := NULL;
                END;
              END IF;
             
              -- Observação Somente para RMV - PE
              IF (pi_nTipoObservacao = 3) THEN
                -- Se perdas e nao achou razao social
                IF ((NVL(vtCODOPER(viLaco),' ') IN ('EA', 'EI')) AND
                    (vvRazaoSocial IS NULL)) THEN
                  -- Pega Razão Social da Filial
                  BEGIN
                    SELECT PCFILIAL.RAZAOSOCIAL
                         , PCFILIAL.CGC
                         , PCFILIAL.RAZAOSOCIAL -->> Aqui não será Fantasia, será Razão Social 
                         , SUBSTR('END: ' || PCFILIAL.ENDERECO || ', ' || PCFILIAL.NUMERO || ',' || 'BAIRRO: ' || PCFILIAL.BAIRRO || '. ' || PCFILIAL.CIDADE,1,200)
                         , PCFILIAL.UF
                      INTO vvRazaoSocial
                         , vvCnpj
                         , vvFantasia
                         , vvEndereco
                         , vvUf
                      FROM PCFILIAL
                     WHERE (PCFILIAL.CODIGO = pi_vCodFilial);
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      vvRazaoSocial := NULL;
                      vvCnpj        := NULL; 
                      vvFantasia    := NULL; 
                      vvEndereco    := NULL; 
                      vvUf          := NULL;
                  END;              
                END IF;              
              END IF; -- Fim Observação Somente para RMV - PE
             
              -- Atualiza Array de Dt. Emissão da Entrada
              vtDTEMISSENT(viLaco)  := TRUNC(vdDtEmissao);
              -- Guarda a Data de Emissão da NF comum a todas as Movimentações
              vtDTEMISSAONF(viLaco) := TRUNC(vdDtEmissao);
            
            -- Saídas ------------------------------------------------------------
            ELSIF (UPPER(SUBSTR(vtCODOPER(viLaco),1,1)) = 'S') THEN

              -- Diminui Saldo Estoque        
              vnSaldoEstoque := NVL(vnSaldoEstoque,0) - (NVL(vtQTSAI(viLaco),0) + NVL(vtQTPERDA(viLaco),0));

              -- Define Observação
              IF (pi_nTipoObservacao IN (1,3)) THEN
                IF    (NVL(vtCODOPER(viLaco),' ') IN ('SA', 'SI')) THEN -->> Se perdas, não tem NF
                  -- Filtro de Somente Acertos de Estoque de Inventário
                  IF (vvTipoMovEscrituracaoMed IN ('3','4')) THEN
                    vvObservacao := FOBTER_OBS_NUMLOTE(pi_vCodFilial,
                                                       vtNUMNOTA(viLaco),
                                                       vtCODPROD(viLaco),
                                                       vtCODOPER(viLaco),
                                                       vbUsaRegraNfObsPerda2318) ;
                  ELSE
                    IF (vbUsaRegraNfObsPerda2318) THEN
                      vvObservacao := 'NF: ' || vtNUMNOTA(viLaco) || '  ' || 'Lote: ' || vtNUMLOTE(viLaco);
                    ELSE
                      vvObservacao := 'Lote: ' || vtNUMLOTE(viLaco);
                    END IF;
                  END IF;
                ELSE
                  vvObservacao := 'NF: '   || vtNUMNOTA(viLaco) || '  ' || 'Lote: ' || vtNUMLOTE(viLaco);
                END IF;
              END IF;
           
              -- Pesquisa Dados do Cliente
              IF (NVL(vtCODCLI(viLaco),0) = 0) THEN
                -- Se o Cliente não existir na PCMOV, pesquisa na PCNFSAID
                BEGIN
                  SELECT PCCLIENT.CLIENTE
                       , PCCLIENT.CGCENT
                       , PCCLIENT.FANTASIA
                       , SUBSTR('END: ' || PCCLIENT.ENDERENT || ', ' || PCCLIENT.NUMEROENT || ',' || 'BAIRRO: ' || PCCLIENT.BAIRROENT || '. ' || PCCLIENT.MUNICENT,1,100)
                       , PCCLIENT.ESTENT
                    INTO vvRazaoSocial                    
                       , vvCnpj
                       , vvFantasia
                       , vvEndereco
                       , vvUf
                    FROM PCNFSAID
                       , PCCLIENT
                   WHERE (PCNFSAID.NUMTRANSVENDA = vtNUMTRANSVENDA(viLaco))
                     AND (PCNFSAID.CODCLI        = PCCLIENT.CODCLI(+))
                     AND (ROWNUM                 = 1);
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN          
                    vvRazaoSocial := NULL;
                    vvCnpj        := NULL;
                    vvFantasia    := NULL;
                    vvEndereco    := NULL;
                    vvUf          := NULL;
                END;
              ELSE
                -- Se o Cliente existir na PCMOV, pesquisa primeiro em memoria,
                -- se não existir em memória pesquisa na base de dados
                IF NOT (vtRazaoCliente.EXISTS(vtCODCLI(viLaco))) THEN
                  BEGIN
                    SELECT PCCLIENT.CLIENTE
                         , PCCLIENT.CGCENT
                         , PCCLIENT.FANTASIA
                         , SUBSTR('END: ' || PCCLIENT.ENDERENT || ', ' || PCCLIENT.NUMEROENT || ',' || 'BAIRRO: ' || PCCLIENT.BAIRROENT || '. ' || PCCLIENT.MUNICENT,1,100)
                         , PCCLIENT.ESTENT
                      INTO vvRazaoSocial
                         , vvCnpj
                         , vvFantasia
                         , vvEndereco
                         , vvUf
                      FROM PCCLIENT
                     WHERE (PCCLIENT.CODCLI = vtCODCLI(viLaco));
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      vvRazaoSocial := NULL;
                      vvCnpj        := NULL; 
                      vvFantasia    := NULL;
                      vvEndereco    := NULL;
                      vvUf          := NULL;
                  END;
                  vtRazaoCliente(vtCODCLI(viLaco))    := vvRazaoSocial;  
                  vtCgcCliente(vtCODCLI(viLaco))      := vvCnpj;  
                  vtFantasiaCliente(vtCODCLI(viLaco)) := vvFantasia;  
                  vtEnderecoCliente(vtCODCLI(viLaco)) := vvEndereco;  
                  vtUfCliente(vtCODCLI(viLaco))       := vvUf;  
                ELSE            
                  vvRazaoSocial := vtRazaoCliente(vtCODCLI(viLaco)); 
                  vvCnpj        := vtCgcCliente(vtCODCLI(viLaco)); 
                  vvFantasia    := vtFantasiaCliente(vtCODCLI(viLaco)); 
                  vvEndereco    := vtEnderecoCliente(vtCODCLI(viLaco)); 
                  vvUf          := vtUfCliente(vtCODCLI(viLaco)); 
                END IF;
              END IF;
            
              -- Se perdas e nao achou razao social
              IF ((NVL(vtCODOPER(viLaco),' ') IN ('SA', 'SI')) AND
                  (vvRazaoSocial IS NULL)) THEN
                -- Pega Razão Social da Filial
                  IF (pi_vsConsiderarFilialNF = 'S' ) AND (pi_vCodFilialNF IS NOT NULL) THEN
                  BEGIN
                    SELECT PCFILIAL.RAZAOSOCIAL
                         , PCFILIAL.CGC
                         , PCFILIAL.RAZAOSOCIAL -->> Aqui não será Fantasia, será Razão Social 
                        , SUBSTR('END: ' || PCFILIAL.ENDERECO || ', ' || PCFILIAL.NUMERO || ',' || 'BAIRRO: ' || PCFILIAL.BAIRRO || '. ' || PCFILIAL.CIDADE,1,200)
                        , PCFILIAL.UF
                      INTO vvRazaoSocial
                        , vvCnpj
                        , vvFantasia
                        , vvEndereco
                        , vvUf
                      FROM PCFILIAL
                    WHERE (PCFILIAL.CODIGO = pi_vCodFilialNF);
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      vvRazaoSocial := NULL;
                      vvCnpj        := NULL; 
                      vvFantasia    := NULL; 
                      vvEndereco    := NULL; 
                      vvUf          := NULL;
                  END;
                ELSE
                  BEGIN
                    SELECT PCFILIAL.RAZAOSOCIAL
                        , PCFILIAL.CGC
                        , PCFILIAL.RAZAOSOCIAL -->> Aqui não será Fantasia, será Razão Social 
                        , SUBSTR('END: ' || PCFILIAL.ENDERECO || ', ' || PCFILIAL.NUMERO || ',' || 'BAIRRO: ' || PCFILIAL.BAIRRO || '. ' || PCFILIAL.CIDADE,1,200)
                        , PCFILIAL.UF
                     INTO vvRazaoSocial
                        , vvCnpj
                        , vvFantasia
                        , vvEndereco
                        , vvUf
                     FROM PCFILIAL
                    WHERE (PCFILIAL.CODIGO = pi_vCodFilial);
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                     vvRazaoSocial := NULL;
                     vvCnpj        := NULL; 
                     vvFantasia    := NULL; 
                     vvEndereco    := NULL; 
                     vvUf          := NULL;
                  END;
                END IF;
              END IF;              
                      
              -- Guarda a Data de Emissão da NF comum a todas as Movimentações
              -- A Data de Emissão da Nota Fiscal de Saída é o próprio DTMOV
              vtDTEMISSAONF(viLaco) := TRUNC(vtDTMOV(viLaco));

            END IF; -- Fim Condição Entradas ou Saídas

            -- Define Histórico
            IF (pi_nTipoObservacao IN (1,3)) THEN

              -- Ajustes/Inventário
              IF (NVL(vtCODOPER(viLaco),' ') IN ('EA', 'EI', 'SA', 'SI')) THEN 
                -- Filtro de Somente Acertos de Estoque de Inventário
                IF (vvTipoMovEscrituracaoMed IN ('3','4')) THEN
                  vvHistorico := FOBTER_FUNCIONARIO(pi_vCodFilial,
                                                    vtCODFUNCLANC(viLaco));
                ELSE
                  vvHistorico := vvRazaoSocial; 
                END IF;
              -- Outras Movimentações
              ELSE
                vvHistorico := vvRazaoSocial; 
              END IF;
              
            ELSIF (pi_nTipoObservacao) = 4 THEN

              IF (NVL(vtCODOPER(viLaco),' ') IN ('EA', 'EI'))  AND (vvRazaoSocial IS NULL) THEN 
                vvRazaoSocial := FOBTER_FUNCIONARIO(pi_vCodFilial,
                                                  null);
             END IF;
              
            END IF;          
            
            -- Redefine Histórico quando do Auto Inutilização - HIS.03778.2015
            IF (vvApresAutoInutilizEscritMed = 'S')  AND
               (NVL(vtCODOPER(viLaco),' ')   = 'SA') THEN 
              -- Pesquisa Observação do Auto de Inutilização
              BEGIN
                SELECT PCMOVAVARIA.OBS
                  INTO vvObsAutoInutilizacao
                  FROM PCMOVAVARIA
                 WHERE (PCMOVAVARIA.NUMTRANSVENDA = vtNUMTRANSVENDA(viLaco))
                   AND (ROWNUM                    = 1);
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  vvObsAutoInutilizacao := NULL;
              END;
              IF (TRIM(vvObsAutoInutilizacao) IS NOT NULL) THEN
                vvHistorico := SUBSTR(vvObsAutoInutilizacao,1,100);
              END IF;               
            END IF;
            
            -- Formata CNPJ
            IF (pi_nTipoObservacao IN (2,4)) THEN
              IF (length (replace(replace(replace(vvCnpj,'.',''),'-',''),'/','')) = 14) THEN
                vvCnpj :=  substr(REPLACE(REPLACE(REPLACE(NVL(vvCnpj,'0'),'.',''),'-',''),'/',''),1,2) || '.' ||
                           substr(REPLACE(REPLACE(REPLACE(NVL(vvCnpj,'0'),'.',''),'-',''),'/',''),3,3) || '.' ||
                           substr(REPLACE(REPLACE(REPLACE(NVL(vvCnpj,'0'),'.',''),'-',''),'/',''),6,3) || '/' ||
                           substr(REPLACE(REPLACE(REPLACE(NVL(vvCnpj,'0'),'.',''),'-',''),'/',''),9,4) || '-' ||
                           substr(REPLACE(REPLACE(REPLACE(NVL(vvCnpj,'0'),'.',''),'-',''),'/',''),13,2);
              ELSIF (length (replace(replace(replace(vvCnpj,'.',''),'-',''),'/','')) = 11) THEN
                vvCnpj := substr(REPLACE(REPLACE(REPLACE(NVL(vvCnpj,'0'),'.',''),'-',''),'/',''),1,3) || '.' ||
                          substr(REPLACE(REPLACE(REPLACE(NVL(vvCnpj,'0'),'.',''),'-',''),'/',''),4,3) || '.' ||
                          substr(REPLACE(REPLACE(REPLACE(NVL(vvCnpj,'0'),'.',''),'-',''),'/',''),7,3) || '-' ||
                          substr(REPLACE(REPLACE(REPLACE(NVL(vvCnpj,'0'),'.',''),'-',''),'/',''),10,2);
              END IF; 
            END IF;          

            -- Atualiza Arrays comuns às Movimentações
            vtQTESTOQUE(viLaco)   := NVL(vnSaldoEstoque,0);
            vtHISTORICO(viLaco)   := vvHistorico; 
            vtOBSERVACOES(viLaco) := vvObservacao;
            vtCNPJ(viLaco)        := vvCnpj;
            vtRAZAOSOCIAL(viLaco) := vvRazaoSocial;
            vtENDERECO(viLaco)    := vvEndereco;
            vtUF(viLaco)          := vvUf;

            -- Atualiza Campos da Table 
            vnNumReg              := NVL(vnNumReg,0) + 1;
            OUTROW.NUMREG         := NVL(vnNumReg,0);
            OUTROW.TIPOREG        := vtTIPOREG(viLaco);
            OUTROW.CODPROD        := vtCODPROD(viLaco);
            OUTROW.DESCRICAOPROD  := vtDESCRICAOPROD(viLaco);
            OUTROW.DCB            := vtDCB(viLaco);
            OUTROW.DESCRICAODCB   := vtDESCRICAODCB(viLaco);
            OUTROW.DTMOV          := TRUNC(vtDTMOV(viLaco));
            OUTROW.DTEMISSENT     := TRUNC(vtDTEMISSENT(viLaco));
            OUTROW.CODCLI         := vtCODCLI(viLaco);
            OUTROW.NUMNOTA        := vtNUMNOTA(viLaco);
            OUTROW.NUMLOTE        := vtNUMLOTE(viLaco);
            OUTROW.CODOPER        := vtCODOPER(viLaco);
            OUTROW.QTENT          := vtQTENT(viLaco);
            OUTROW.QTSAI          := vtQTSAI(viLaco);
            OUTROW.QTPERDA        := vtQTPERDA(viLaco);
            OUTROW.QTESTOQUE      := vtQTESTOQUE(viLaco);
            OUTROW.HISTORICO      := vtHISTORICO(viLaco);
            OUTROW.OBSERVACOES    := vtOBSERVACOES(viLaco);
            OUTROW.UNIDADEMEDIDA  := vtUNIDADE(viLaco);
            OUTROW.CNPJ           := vtCNPJ(viLaco);
            OUTROW.RAZAOSOCIAL    := vtRAZAOSOCIAL(viLaco);
            OUTROW.FORMULARIOBSPO := vtFORMULARIOBSPO(viLaco); 
            OUTROW.DTEMISSAONF    := vtDTEMISSAONF(viLaco);
            OUTROW.ENDERECO       := vtENDERECO(viLaco);
            OUTROW.UF             := vtUF(viLaco);
            OUTROW.MARCA          := vtMARCA(viLaco);
            OUTROW.SUBSTANCIA     := vtSUBSTANCIA(viLaco);
            OUTROW.EMBALAGEM      := vtEMBALAGEM(viLaco);
            OUTROW.CGCENT         := vtCGCENT(viLaco);
            OUTROW.ENDERENT       := vtENDERENT(viLaco);
            OUTROW.DTSAIDANF      := vtDTSAIDANF(viLaco);

            -- Insere dados na Table
            PIPE ROW(OUTROW);
    
          END IF; -- Fim Condição Tipo Registro de Movimentações

        END IF; -- Fim Condição Se Considera a Movimentação
   
      END LOOP; -- Fim Laço Movimentações
      
    END IF; -- Fim Condição Achou Movimentações

  END IF; -- FIM CONDIÇÃO Se RMV GOIAS e Movimentações BSPO

 /******************************************************************************  
  Se Balanço de Medicamentos Controlados
  *****************************************************************************/  
  IF (pi_nTipoHistorico IN (2)) THEN  

    vvSql := 'SELECT PRO.CODPROD 
                   , PRO.DESCRICAO 
                   , PRO.DCB 
                   , PRO.DESC_DCB 
                   , PRO.SUBSTANCIA 
                   , NVL(HIS.ESTOQUEINICIAL,0) ESTOQUEINICIAL
                   , NVL(MOV.ENTRADAS,0) ENTRADAS 
                   , NVL(MOV.SAIDAS,0) SAIDAS 
                   , NVL(MOV.PERDAS,0) PERDAS 
                   , (NVL(HIS.ESTOQUEINICIAL,0) + NVL(MOV.ENTRADAS,0) - NVL(MOV.SAIDAS,0) - NVL(MOV.PERDAS,0)) ESTOQUEFINAL 
                   , PRO.MARCA
                   , PRO.UNIDADE
                   , PRO.EMBALAGEM
                FROM 
                     (SELECT PCPRODUT.CODPROD 
                           , PCPRODUT.DESCRICAO 
                           -- Concatenar Substância e DCB apenas se informado mais de uma Substância no Filtro e produto possui Princípio ativo 2
                           , CASE 
                               WHEN (1 = ' || vvMultiplasSubstancias || ') AND (NVL(PCPRODUT.CODPRINCIPATIVO2,0) > 0) THEN
                                 NVL(PCPRINCIPATIVO1.SUBSTANCIA,PCPRODUT.SUBSTANCIA) ||  '' / '' || PCPRINCIPATIVO2.SUBSTANCIA
                               ELSE
                                 NVL(PCPRINCIPATIVO1.SUBSTANCIA,PCPRODUT.SUBSTANCIA)
                             END SUBSTANCIA
                           
                           , CASE 
                               WHEN (1 = ' || vvMultiplasSubstancias || ') AND (NVL(PCPRODUT.CODPRINCIPATIVO2,0) > 0) THEN
                                 PCPRINCIPATIVO1.DCB || '' / '' || PCPRINCIPATIVO2.DCB
                              ELSE
                                 PCPRINCIPATIVO1.DCB    
                             END DCB   
                           , CASE 
                               WHEN (1 = ' || vvMultiplasSubstancias || ') AND (NVL(PCPRODUT.CODPRINCIPATIVO2,0) > 0) THEN
                                 PCPRINCIPATIVO1.DESCRICAO || '' / '' || PCPRINCIPATIVO2.DESCRICAO
                              ELSE
                                 PCPRINCIPATIVO1.DESCRICAO    
                             END DESC_DCB
                           , PCMARCA.MARCA
                           , PCPRODUT.UNIDADE
                           , PCPRODUT.EMBALAGEM
                        FROM PCPRODUT 
                           , PCPRINCIPATIVO PCPRINCIPATIVO1
                           , PCPRINCIPATIVO PCPRINCIPATIVO2
                           , PCMARCA
                       WHERE (PCPRODUT.CODPRINCIPATIVO  = PCPRINCIPATIVO1.CODPRINCIPATIVO(+))
                         AND (PCPRODUT.CODPRINCIPATIVO2 = PCPRINCIPATIVO2.CODPRINCIPATIVO(+))
                         AND (PCPRODUT.CODMARCA         = PCMARCA.CODMARCA(+)) ' || vvInLista ||
                   ' ) PRO 
                   , (SELECT PCMOV.CODPROD 
                           , SUM(NVL(CASE WHEN (SUBSTR(PCMOV.CODOPER,1,1) = ''E'') THEN 
                                       DECODE(NVL(PCMOV.QTCONT,0),0,NVL(PCMOV.QT,0),NVL(PCMOV.QTCONT,0)) 
                                          WHEN (SUBSTR(PCMOV.CODOPER,1,1) = ''S'') THEN 
                                       (DECODE(NVL(PCMOV.QTCONT,0),0,NVL(PCMOV.QT,0),NVL(PCMOV.QTCONT,0)) * -1) 
                                     ELSE 
                                       0 
                                     END,0)) ESTOQUEINICIAL 
                        FROM PCMOV 
                           , PCPRODUT 
                           , PCPRINCIPATIVO PCPRINCIPATIVO1
                           , PCPRINCIPATIVO PCPRINCIPATIVO2
                       WHERE (PCPRODUT.CODPROD = PCMOV.CODPROD) 
                         AND (PCPRODUT.CODPRINCIPATIVO = PCPRINCIPATIVO1.CODPRINCIPATIVO(+))
                         AND (PCPRODUT.CODPRINCIPATIVO2 = PCPRINCIPATIVO2.CODPRINCIPATIVO(+))
                         AND ((PCMOV.PERCQUEBRADO IS NULL) OR (PCMOV.PERCQUEBRADO = 0)) ' ||  vvWhereFilial || vvWherePerAnterior || vvInLista;
      -- Filtro de Tipo de Movimentações no Histórico
      IF (vvTipoMovEscrituracaoMed IN ('5')) THEN
        vvSql := vvSql || ' AND ( (PCMOV.STATUS IN (''A'',''AB'')) OR ((PCMOV.STATUS = ''B'') AND (PCMOV.CODOPER = ''EI'')) ) ';      
      -- Filtro de Tipo de Movimentações Contábeis
      ELSIF (vvTipoMovEscrituracaoMed IN ('6')) THEN
        vvSql := vvSql || ' AND (PCMOV.STATUS IN (''A'',''AB'')) ';      
      ELSE
        IF (vvTipoMovEscrituracaoMed IN ('2','4')) THEN
          vvSql := vvSql || ' AND (PCMOV.STATUS IN (''B'',''AB'')) ';      
        END IF;
        -- Filtro de Somente Acertos de Estoque de Inventário
        IF (vvTipoMovEscrituracaoMed IN ('3','4')) THEN
          vvSql := vvSql || ' AND ((PCMOV.CODOPER IN (''EI'', ''SI'') AND PCMOV.NUMLOTE IS NULL) OR (PCMOV.CODOPER NOT IN (''EI'', ''SI''))) ';      
          vvSql := vvSql || ' AND (DECODE(NVL(PCMOV.QTCONT,0),0,NVL(PCMOV.QT,0),NVL(PCMOV.QTCONT,0)) <> 0) ';      
        END IF;
      END IF;
      -- Não enviar o "SV" para não Duplicar as Movimentações
      vvSql := vvSql || ' AND (PCMOV.CODOPER NOT IN (''SV'')) ';      
      --
      vvSql := vvSql ||
                     ' GROUP BY PCMOV.CODPROD) HIS 
                   , (SELECT PCMOV.CODPROD 
                           , SUM(NVL(CASE WHEN (SUBSTR(PCMOV.CODOPER,1,1) = ''E'') THEN 
                                       DECODE(NVL(PCMOV.QTCONT,0),0,NVL(PCMOV.QT,0),NVL(PCMOV.QTCONT,0)) 
                                     END,0)) ENTRADAS 
                           , SUM(NVL(CASE WHEN ((SUBSTR(PCMOV.CODOPER,1,1) = ''S'') AND 
                                                (PCMOV.CODOPER NOT IN (''SA'', ''SI''))) THEN 
                                       DECODE(NVL(PCMOV.QTCONT,0),0,NVL(PCMOV.QT,0),NVL(PCMOV.QTCONT,0)) 
                                     END,0)) SAIDAS 
                           , SUM(NVL(CASE WHEN ((SUBSTR(PCMOV.CODOPER,1,1) = ''S'') AND 
                                                (PCMOV.CODOPER IN (''SA'', ''SI''))) THEN 
                                       DECODE(NVL(PCMOV.QTCONT,0),0,NVL(PCMOV.QT,0),NVL(PCMOV.QTCONT,0)) 
                                     END,0)) PERDAS 
                        FROM PCMOV 
                           , PCPRODUT 
                           , PCPRINCIPATIVO PCPRINCIPATIVO1
                           , PCPRINCIPATIVO PCPRINCIPATIVO2                           
                       WHERE (PCPRODUT.CODPROD = PCMOV.CODPROD) 
                         AND (PCPRODUT.CODPRINCIPATIVO = PCPRINCIPATIVO1.CODPRINCIPATIVO(+))
                         AND (PCPRODUT.CODPRINCIPATIVO2 = PCPRINCIPATIVO2.CODPRINCIPATIVO(+))
                         AND ((PCMOV.PERCQUEBRADO IS NULL) OR (PCMOV.PERCQUEBRADO = 0)) ' || vvWhereFilial || vvWherePeriodo || vvInLista;
      IF (vvTipoMovEscrituracaoMed IN ('5')) THEN
        vvSql := vvSql || ' AND ( (PCMOV.STATUS IN (''A'',''AB'')) OR ((PCMOV.STATUS = ''B'') AND (PCMOV.CODOPER = ''EI'')) ) ';      
      -- Filtro de Tipo de Movimentações Contábeis
      ELSIF (vvTipoMovEscrituracaoMed IN ('6')) THEN
        vvSql := vvSql || ' AND (PCMOV.STATUS IN (''A'',''AB'')) ';      
      ELSE
        -- Filtro de Tipo de Movimentações nas Movimentações
        IF (vvTipoMovEscrituracaoMed IN ('2','4')) THEN
          vvSql := vvSql || ' AND (PCMOV.STATUS IN (''B'',''AB'')) ';      
        END IF;
        -- Filtro de Somente Acertos de Estoque de Inventário
        IF (vvTipoMovEscrituracaoMed IN ('3','4')) THEN
          vvSql := vvSql || ' AND ((PCMOV.CODOPER IN (''EI'', ''SI'') AND PCMOV.NUMLOTE IS NULL) OR (PCMOV.CODOPER NOT IN (''EI'', ''SI''))) ';      
          vvSql := vvSql || ' AND (DECODE(NVL(PCMOV.QTCONT,0),0,NVL(PCMOV.QT,0),NVL(PCMOV.QTCONT,0)) <> 0) ';      
        END IF;
      END IF;
      -- Não enviar o "SV" para não Duplicar as Movimentações
      vvSql := vvSql || ' AND (PCMOV.CODOPER NOT IN (''SV'')) ';      
      --
      vvSql := vvSql ||
                     ' GROUP BY PCMOV.CODPROD) MOV 
                 WHERE PRO.CODPROD = MOV.CODPROD(+)  
                   AND PRO.CODPROD = HIS.CODPROD(+) 
             ORDER BY PRO.SUBSTANCIA, PRO.CODPROD, PRO.DESCRICAO ';

    -- Insere Dados em Arrays
    EXECUTE IMMEDIATE vvSql
      BULK COLLECT INTO vtCODPROD,
                        vtDESCRICAOPROD,
                        vtDCB,
                        vtDESCRICAODCB,
                        vtSUBSTANCIA,
                        vtQTESTINICIAL,
                        vtQTENT,
                        vtQTSAI,
                        vtQTPERDA,
                        vtQTESTOQUE,
                        vtMARCA,
                        vtUNIDADE,
                        vtEMBALAGEM;

    -- Se achou Produtos
    IF (vtCODPROD.COUNT > 0) THEN

      -- Inicializa Número do Registro
      vnNumReg := 0;

      -- Laço de Produtos 
      FOR viLaco IN vtCODPROD.FIRST..vtCODPROD.LAST LOOP
     
        -- Atualiza Campos da Table 
        vnNumReg              := NVL(vnNumReg,0) + 1;
        OUTROW.NUMREG         := NVL(vnNumReg,0);
        OUTROW.CODPROD        := vtCODPROD(viLaco);
        OUTROW.DESCRICAOPROD  := vtDESCRICAOPROD(viLaco);
        OUTROW.DCB            := vtDCB(viLaco);
        OUTROW.DESCRICAODCB   := vtDESCRICAODCB(viLaco);
        OUTROW.SUBSTANCIA     := vtSUBSTANCIA(viLaco);
        OUTROW.QTESTINICIAL   := vtQTESTINICIAL(viLaco);
        OUTROW.QTENT          := vtQTENT(viLaco);
        OUTROW.QTSAI          := vtQTSAI(viLaco);
        OUTROW.QTPERDA        := vtQTPERDA(viLaco);
        OUTROW.QTESTOQUE      := vtQTESTOQUE(viLaco);
        OUTROW.UNIDADEMEDIDA  := vtUNIDADE(viLaco);
        OUTROW.FORMULARIOBSPO := 2; 
        OUTROW.MARCA          := vtMARCA(viLaco);
        OUTROW.EMBALAGEM      := vtEMBALAGEM(viLaco);
                
        -- Insere dados na Table
        PIPE ROW(OUTROW);
    
      END LOOP; -- Fim Laço Movimentações
    
    END IF; -- Fim Condição Achou Movimentações
  
  END IF; -- FIM CONDIÇÃO Se Balanço de Medicamentos Controlados

 /******************************************************************************  
  Se Balanço Completo Entrada/Saída BSPO
  *****************************************************************************/  
  IF (pi_nTipoHistorico IN (3,6)) THEN  
  
    -- Pesquisa o CODCONT da NF de Entrada
    --BEGIN
    --  SELECT CODCONTFOR
    --    INTO vnCodContFor
    --    FROM PCCONSUM;        
    --EXCEPTION
    --  WHEN NO_DATA_FOUND THEN
    --    vnCodContFor := NULL;
    --END;

    ----------------------------------------------------------------------------    
    -- CARREGA PRODUTOS --------------------------------------------------------
    ----------------------------------------------------------------------------    
    -- Prepara Select
    vvSql := 'SELECT PCPRODUT.CODPROD 
                   , PCPRODUT.DESCRICAO 
                   -- Concatenar Substância e DCB apenas se informado mais de uma Substância no Filtro e produto possui Princípio ativo 2                         
                   , CASE 
                       WHEN (1 = ' || vvMultiplasSubstancias || ') AND (NVL(PCPRODUT.CODPRINCIPATIVO2,0) > 0) THEN
                         PCPRINCIPATIVO1.DCB || '' / '' || PCPRINCIPATIVO2.DCB
                      ELSE
                         PCPRINCIPATIVO1.DCB    
                     END DCB   
                   , CASE 
                       WHEN (1 = ' || vvMultiplasSubstancias || ') AND (NVL(PCPRODUT.CODPRINCIPATIVO2,0) > 0) THEN
                         PCPRINCIPATIVO1.DESCRICAO || '' / '' || PCPRINCIPATIVO2.DESCRICAO
                      ELSE
                         PCPRINCIPATIVO1.DESCRICAO    
                     END DESC_DCB
                   , CASE 
                       WHEN (1 = ' || vvMultiplasSubstancias || ') AND (NVL(PCPRODUT.CODPRINCIPATIVO2,0) > 0) THEN
                         NVL(PCPRINCIPATIVO1.SUBSTANCIA,PCPRODUT.SUBSTANCIA) ||  '' / '' || PCPRINCIPATIVO2.SUBSTANCIA
                       ELSE
                         NVL(PCPRINCIPATIVO1.SUBSTANCIA,PCPRODUT.SUBSTANCIA)
                     END SUBSTANCIA        
                   , PCPRODUT.UNIDADE 
                   , PCPRODUT.EMBALAGEM
                   , PCMARCA.MARCA
                FROM PCPRODUT 
                   , PCPRINCIPATIVO PCPRINCIPATIVO1
                   , PCPRINCIPATIVO PCPRINCIPATIVO2
                   , PCMARCA
               WHERE (PCPRODUT.CODPRINCIPATIVO  = PCPRINCIPATIVO1.CODPRINCIPATIVO(+))
                 AND (PCPRODUT.CODPRINCIPATIVO2 = PCPRINCIPATIVO2.CODPRINCIPATIVO(+))
                 AND (PCPRODUT.CODMARCA         = PCMARCA.CODMARCA(+)) ' || vvInLista ||
           ' ORDER BY NVL(PCPRINCIPATIVO1.SUBSTANCIA,PCPRODUT.SUBSTANCIA) || DECODE(NVL(PCPRINCIPATIVO2.SUBSTANCIA,'' ''),'' '',NULL,'' / '' || PCPRINCIPATIVO2.SUBSTANCIA), PCPRODUT.CODPROD, PCPRODUT.DESCRICAO ';
    -- Limpa Arrays
    PLIMPARRAYS;
    -- Insere Dados em Arrays
    EXECUTE IMMEDIATE vvSql
      BULK COLLECT INTO vtCODPROD,
                        vtDESCRICAOPROD,
                        vtDCB,
                        vtDESCRICAODCB,
                        vtSUBSTANCIA,
                        vtUNIDADE,
                        vtEMBALAGEM,
                        vtMARCA;
    -- Se achou Produtos
    IF (vtCODPROD.COUNT > 0) THEN
      -- Laço de Produtos 
      FOR viLaco IN vtCODPROD.FIRST..vtCODPROD.LAST LOOP
        -- Guarda Produto em Lista
        idxProduto                  := NVL(vtListaProdutos.COUNT,0) + 1;
        vtListaProdutos(idxProduto) := vtCODPROD(viLaco);
        -- Adiciona Dados do Produto em Array Indexado pelo Código do Produto
        vtEstoque(vtCODPROD(viLaco)).vnCodProd    := vtCODPROD(viLaco);
        vtEstoque(vtCODPROD(viLaco)).vvDescricao  := vtDESCRICAOPROD(viLaco);
        vtEstoque(vtCODPROD(viLaco)).vvDcb        := vtDCB(viLaco);
        vtEstoque(vtCODPROD(viLaco)).vvDescDcb    := vtDESCRICAODCB(viLaco);
        vtEstoque(vtCODPROD(viLaco)).vvSubstancia := vtSUBSTANCIA(viLaco);
        vtEstoque(vtCODPROD(viLaco)).vvUnidade    := vtUNIDADE(viLaco);
        vtEstoque(vtCODPROD(viLaco)).vvEmbalagem  := vtEMBALAGEM(viLaco);
        vtEstoque(vtCODPROD(viLaco)).vnEstEnt     := 0;
        vtEstoque(vtCODPROD(viLaco)).vnEstSai     := 0;
        vtEstoque(vtCODPROD(viLaco)).vnQtImport   := 0;
        vtEstoque(vtCODPROD(viLaco)).vnQtAquis    := 0;
        vtEstoque(vtCODPROD(viLaco)).vnQtEnt      := 0;
        vtEstoque(vtCODPROD(viLaco)).vnQtSai      := 0;        
        vtEstoque(vtCODPROD(viLaco)).vvMarca      := vtMARCA(viLaco);
      END LOOP; -- Fim Laço Produtos
    END IF;
    
    ----------------------------------------------------------------------------    
    -- CARREGA HISTORICO -------------------------------------------------------
    ----------------------------------------------------------------------------    
    -- Prepara Select
    vvSql := 'SELECT PCMOV.CODPROD 
                   , PCMOV.NUMTRANSENT
                   , PCMOV.NUMTRANSVENDA
                   , SUM(NVL(CASE WHEN (SUBSTR(PCMOV.CODOPER,1,1) = ''E'') THEN 
                               DECODE(NVL(PCMOV.QTCONT,0),0,NVL(PCMOV.QT,0),NVL(PCMOV.QTCONT,0)) 
                             ELSE 
                               0 
                             END,0)) ESTENT 
                   , SUM(NVL(CASE WHEN (SUBSTR(PCMOV.CODOPER,1,1) = ''S'') THEN 
                               DECODE(NVL(PCMOV.QTCONT,0),0,NVL(PCMOV.QT,0),NVL(PCMOV.QTCONT,0))
                             ELSE 
                               0 
                             END,0)) ESTSAI 
                        FROM PCMOV 
                           , PCPRODUT 
                           , PCPRINCIPATIVO PCPRINCIPATIVO1
                           , PCPRINCIPATIVO PCPRINCIPATIVO2
               WHERE (PCPRODUT.CODPROD = PCMOV.CODPROD) 
                 AND (PCPRODUT.CODPRINCIPATIVO  = PCPRINCIPATIVO1.CODPRINCIPATIVO(+))
                 AND (PCPRODUT.CODPRINCIPATIVO2 = PCPRINCIPATIVO2.CODPRINCIPATIVO(+))
                 AND ((PCMOV.PERCQUEBRADO IS NULL) OR (PCMOV.PERCQUEBRADO = 0)) ' ||  vvWhereFilial || vvWherePerAnterior || vvInLista;
    -- Filtro de Tipo de Movimentações no Histórico
    IF (vvTipoMovEscrituracaoMed IN ('5')) THEN
      vvSql := vvSql || ' AND ( (PCMOV.STATUS IN (''A'',''AB'')) OR ((PCMOV.STATUS = ''B'') AND (PCMOV.CODOPER = ''EI'')) ) ';      
    -- Filtro de Tipo de Movimentações Contábeis
    ELSIF (vvTipoMovEscrituracaoMed IN ('6')) THEN
      vvSql := vvSql || ' AND (PCMOV.STATUS IN (''A'',''AB'')) ';      
    ELSE
      IF (vvTipoMovEscrituracaoMed IN ('2','4')) THEN
        vvSql := vvSql || ' AND (PCMOV.STATUS IN (''B'',''AB'')) ';      
      END IF;
      -- Filtro de Somente Acertos de Estoque de Inventário
      IF (vvTipoMovEscrituracaoMed IN ('3','4')) THEN
        vvSql := vvSql || ' AND ((PCMOV.CODOPER IN (''EI'', ''SI'') AND PCMOV.NUMLOTE IS NULL) OR (PCMOV.CODOPER NOT IN (''EI'', ''SI''))) ';      
        vvSql := vvSql || ' AND (DECODE(NVL(PCMOV.QTCONT,0),0,NVL(PCMOV.QT,0),NVL(PCMOV.QTCONT,0)) <> 0) ';      
      END IF;
    END IF;
    -- Não enviar o "SV" para não Duplicar as Movimentações
    vvSql := vvSql || ' AND (PCMOV.CODOPER NOT IN (''SV'')) ';      
    --
     vvSql := vvSql ||
             ' GROUP BY PCMOV.CODPROD
                      , PCMOV.NUMTRANSENT
                      , PCMOV.NUMTRANSVENDA ';
    -- Limpa Arrays
    PLIMPARRAYS;
    -- Insere Dados em Arrays
    EXECUTE IMMEDIATE vvSql
      BULK COLLECT INTO vtCODPROD,
                        vtNUMTRANSENT,
                        vtNUMTRANSVENDA,
                        vtQTENT,
                        vtQTSAI;
    -- Se achou Produtos
    IF (vtCODPROD.COUNT > 0) THEN
      -- Laço de Movimentações Produtos 
      FOR viLaco IN vtCODPROD.FIRST..vtCODPROD.LAST LOOP
        -- Se o Produto existir no Array
        IF (vtEstoque.EXISTS(vtCODPROD(viLaco))) THEN
          -- Se Entrada
          IF (NVL(vtQTENT(viLaco),0) > 0) THEN
            -- Se a Transação for um INTEGER, utiliza pesquisa em memória para otimizar processo
            IF (NVL(vtNUMTRANSENT(viLaco),0) BETWEEN 1 AND viValorMaxInteger) THEN 
              -- Primeiro pesquisa a Especie da NF em memória,
              -- se não existir em memória pesquisa na base de dados
              IF NOT (vtEspecieNFEntrada.EXISTS(vtNUMTRANSENT(viLaco))) THEN
                BEGIN
                  SELECT PCNFENT.ESPECIE
                       , PCNFENT.TIPODESCARGA
                       , PCNFENT.DTEMISSAO
                    INTO vvEspecie           
                       , vvTipoDescarga                       
                       , vvDtNfSaid
                  FROM PCNFENT
                   WHERE (PCNFENT.NUMTRANSENT = vtNUMTRANSENT(viLaco))
                     AND (ROWNUM              = 1);
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN          
                    vvEspecie      := NULL;
                    vvTipoDescarga := NULL;                       
                    vvDtNfSaid     := NULL;
                END;
                vtEspecieNFEntrada(vtNUMTRANSENT(viLaco))  := vvEspecie;
                vtTipoDescargaNFEnt(vtNUMTRANSENT(viLaco)) := vvTipoDescarga;
                 vtDataNFEntrada(vtNUMTRANSENT(viLaco))    := vvDtNfSaid;
              ELSE
                vvEspecie      := vtEspecieNFEntrada(vtNUMTRANSENT(viLaco));
                vvTipoDescarga := vtTipoDescargaNFEnt(vtNUMTRANSENT(viLaco));
                vvDtNfSaid     := vtDataNFEntrada(vtNUMTRANSENT(viLaco));
              END IF;
            -- Se a Transação não for um INTEGER, pequisa sempre no Banco de Dados
            ELSE
              BEGIN
                SELECT PCNFENT.ESPECIE
                     , PCNFENT.TIPODESCARGA
                     , PCNFENT.DTEMISSAO
                  INTO vvEspecie                
                     , vvTipoDescarga                       
                     , vvDtNfSaid
                  FROM PCNFENT
                 WHERE (PCNFENT.NUMTRANSENT = vtNUMTRANSENT(viLaco))
                   AND (ROWNUM              = 1);
              EXCEPTION
                WHEN NO_DATA_FOUND THEN          
                  vvEspecie      := NULL;
                  vvTipoDescarga := NULL;
                  vvDtNfSaid     := NULL;
              END;
            END IF; 
            -- Se a Especie da NF for igual a 'NE', indica que está aguardando autorização do SEFAZ,
            -- nesse caso ignora a Movimentação
            -- Desconsidera Transação de Atualização de Estoque de Importação
            IF (--(NVL(vvEspecie     ,' ') <> 'NE') AND -- PARA NÃO DIVERGIR DOS OUTROS RELATORIOS
                (NVL(vvTipoDescarga,' ') <> 'I' )) THEN
              vtEstoque(vtCODPROD(viLaco)).vnEstEnt := NVL(vtEstoque(vtCODPROD(viLaco)).vnEstEnt,0) + NVL(vtQTENT(viLaco),0);
            END IF;
          END IF;
          -- Se Saída
          IF (NVL(vtQTSAI(viLaco),0) > 0) THEN
            -- Se a Transação for um INTEGER, utiliza pesquisa em memória para otimizar processo
            IF (NVL(vtNUMTRANSVENDA(viLaco),0) BETWEEN 1 AND viValorMaxInteger) THEN 
              -- Primeiro pesquisa a Especie da NF em memória,
              -- se não existir em memória pesquisa na base de dados
              IF NOT (vtEspecieNFSaida.EXISTS(vtNUMTRANSVENDA(viLaco))) THEN
                BEGIN
                  SELECT PCNFSAID.ESPECIE
                       , PCNFSAID.DTSAIDA
                    INTO vvEspecie       
                       , vvDtNfSaid         
                    FROM PCNFSAID
                   WHERE (PCNFSAID.NUMTRANSVENDA = vtNUMTRANSVENDA(viLaco));
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN          
                    vvEspecie  := NULL;
                    vvDtNfSaid := NULL;
                END;
                vtEspecieNFSaida(vtNUMTRANSVENDA(viLaco)) := vvEspecie;
                vtDataNFSaida(vtNUMTRANSVENDA(viLaco))    := vvDtNfSaid;                
              ELSE
                vvEspecie  := vtEspecieNFSaida(vtNUMTRANSVENDA(viLaco));
                vvDtNfSaid := vtDataNFSaida(vtNUMTRANSVENDA(viLaco));                
              END IF;
            -- Se a Transação não for um INTEGER, pequisa sempre no Banco de Dados
            ELSE
              BEGIN
                SELECT PCNFSAID.ESPECIE
                     , PCNFSAID.DTSAIDA
                  INTO vvEspecie      
                     , vvDtNfSaid           
                  FROM PCNFSAID
                 WHERE (PCNFSAID.NUMTRANSVENDA = vtNUMTRANSVENDA(viLaco));
              EXCEPTION
                WHEN NO_DATA_FOUND THEN          
                  vvEspecie  := NULL;
                  vvDtNfSaid := NULL;
              END;
            END IF; 
            -- Se a Especie da NF for igual a 'NE', indica que está aguardando autorização do SEFAZ,
            -- nesse caso ignora a Movimentação
            --IF (vvEspecie <> 'NE') THEN          -- PARA NÃO DIVERGIR DOS OUTROS RELATÓRIOS
              vtEstoque(vtCODPROD(viLaco)).vnEstSai := NVL(vtEstoque(vtCODPROD(viLaco)).vnEstSai,0) + NVL(vtQTSAI(viLaco),0);
            --END IF;
          END IF;
        END IF; -- Fim Condição Se o Produto existir no Array
      END LOOP; -- Fim Laço Movimentações
    END IF; -- Fim Condição Achou Movimentações

    ----------------------------------------------------------------------------    
    -- CARREGA MOVIMENTAÇÕES ---------------------------------------------------
    ----------------------------------------------------------------------------    
    -- Prepara Select
    vvSql := 'SELECT PCMOV.CODPROD 
                   , PCMOV.NUMTRANSENT
                   , PCMOV.NUMTRANSVENDA
                   , SUM(NVL(CASE WHEN (SUBSTR(PCMOV.CODOPER,1,1) = ''E'') THEN 
                               DECODE(NVL(PCMOV.QTCONT,0),0,NVL(PCMOV.QT,0),NVL(PCMOV.QTCONT,0)) 
                             END,0)) ENTRADAS 
                   , SUM(NVL(CASE WHEN ((SUBSTR(PCMOV.CODOPER,1,1) = ''S'') AND 
                                        (PCMOV.CODOPER NOT IN (''SA'', ''SI''))) THEN 
                               DECODE(NVL(PCMOV.QTCONT,0),0,NVL(PCMOV.QT,0),NVL(PCMOV.QTCONT,0)) 
                             END,0)) SAIDAS 
                   , SUM(NVL(CASE WHEN ((SUBSTR(PCMOV.CODOPER,1,1) = ''S'') AND 
                                        (PCMOV.CODOPER IN (''SA'', ''SI''))) THEN 
                                DECODE(NVL(PCMOV.QTCONT,0),0,NVL(PCMOV.QT,0),NVL(PCMOV.QTCONT,0)) 
                             END,0)) PERDAS 
                FROM PCMOV 
                   , PCPRODUT 
                   , PCPRINCIPATIVO PCPRINCIPATIVO1
                   , PCPRINCIPATIVO PCPRINCIPATIVO2
               WHERE (PCPRODUT.CODPROD = PCMOV.CODPROD) 
                 AND (PCPRODUT.CODPRINCIPATIVO  = PCPRINCIPATIVO1.CODPRINCIPATIVO(+))
                 AND (PCPRODUT.CODPRINCIPATIVO2 = PCPRINCIPATIVO2.CODPRINCIPATIVO(+))
                 AND ((PCMOV.PERCQUEBRADO IS NULL) OR (PCMOV.PERCQUEBRADO = 0)) ' || vvWhereFilial || vvWherePeriodo || vvInLista;                 
      -- Filtro de Tipo de Movimentações nas Movimentações
      IF (vvTipoMovEscrituracaoMed IN ('5')) THEN
        vvSql := vvSql || ' AND ( (PCMOV.STATUS IN (''A'',''AB'')) OR ((PCMOV.STATUS = ''B'') AND (PCMOV.CODOPER = ''EI'')) ) ';      
      -- Filtro de Tipo de Movimentações Contábeis
      ELSIF (vvTipoMovEscrituracaoMed IN ('6')) THEN
        vvSql := vvSql || ' AND (PCMOV.STATUS IN (''A'',''AB'')) ';      
      ELSE      
        IF (vvTipoMovEscrituracaoMed IN ('2','4')) THEN
          vvSql := vvSql || ' AND (PCMOV.STATUS IN (''B'',''AB'')) ';      
        END IF;
        -- Filtro de Somente Acertos de Estoque de Inventário
        IF (vvTipoMovEscrituracaoMed IN ('3','4')) THEN
          vvSql := vvSql || ' AND ((PCMOV.CODOPER IN (''EI'', ''SI'') AND PCMOV.NUMLOTE IS NULL) OR (PCMOV.CODOPER NOT IN (''EI'', ''SI''))) ';      
          vvSql := vvSql || ' AND (DECODE(NVL(PCMOV.QTCONT,0),0,NVL(PCMOV.QT,0),NVL(PCMOV.QTCONT,0)) <> 0) ';      
        END IF;
      END IF;
      -- Não enviar o "SV" para não Duplicar as Movimentações
      vvSql := vvSql || ' AND (PCMOV.CODOPER NOT IN (''SV'')) ';      
      --
      vvSql := vvSql ||
             ' GROUP BY PCMOV.CODPROD
                      , PCMOV.NUMTRANSENT
                      , PCMOV.NUMTRANSVENDA ';
    -- Limpa Arrays
    PLIMPARRAYS;
    -- Insere Dados em Arrays
    EXECUTE IMMEDIATE vvSql
      BULK COLLECT INTO vtCODPROD,
                        vtNUMTRANSENT,
                        vtNUMTRANSVENDA,
                        vtQTENT,
                        vtQTSAI,
                        vtQTPERDA;
    -- Se achou Produtos
    IF (vtCODPROD.COUNT > 0) THEN
      -- Laço de Movimentações Produtos 
      FOR viLaco IN vtCODPROD.FIRST..vtCODPROD.LAST LOOP
        -- Se o Produto existir no Array
        IF (vtEstoque.EXISTS(vtCODPROD(viLaco))) THEN
          -- Se Entrada
          IF (NVL(vtQTENT(viLaco),0) > 0) THEN
            -- Se a Transação for um INTEGER, utiliza pesquisa em memória para otimizar processo
            IF (NVL(vtNUMTRANSENT(viLaco),0) BETWEEN 1 AND viValorMaxInteger) THEN 
              -- Primeiro pesquisa a Especie da NF em memória,
              -- se não existir em memória pesquisa na base de dados
              IF NOT (vtEspecieNFEntrada.EXISTS(vtNUMTRANSENT(viLaco))) THEN
                BEGIN
                  SELECT PCNFENT.ESPECIE
                       , PCNFENT.TIPODESCARGA
                       , PCNFENT.DTEMISSAO
                    INTO vvEspecie           
                       , vvTipoDescarga                       
                       , vvDtNfSaid
                    FROM PCNFENT
                   WHERE (PCNFENT.NUMTRANSENT = vtNUMTRANSENT(viLaco))
                     AND (ROWNUM              = 1);
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN          
                    vvEspecie      := NULL;
                    vvTipoDescarga := NULL;                       
                    vvDtNfSaid     := NULL;
                END;
                vtEspecieNFEntrada(vtNUMTRANSENT(viLaco))  := vvEspecie;
                vtTipoDescargaNFEnt(vtNUMTRANSENT(viLaco)) := vvTipoDescarga;
                vtDataNFEntrada(vtNUMTRANSENT(viLaco))     := vvDtNfSaid;
              ELSE
                vvEspecie      := vtEspecieNFEntrada(vtNUMTRANSENT(viLaco));
                vvTipoDescarga := vtTipoDescargaNFEnt(vtNUMTRANSENT(viLaco));
                vvDtNfSaid     := vtDataNFEntrada(vtNUMTRANSENT(viLaco));
              END IF;
            -- Se a Transação não for um INTEGER, pequisa sempre no Banco de Dados
            ELSE
              BEGIN
                SELECT PCNFENT.ESPECIE
                     , PCNFENT.TIPODESCARGA
                     , PCNFENT.DTEMISSAO
                  INTO vvEspecie                
                     , vvTipoDescarga  
                     , vvDtNfSaid                     
                  FROM PCNFENT
                 WHERE (PCNFENT.NUMTRANSENT = vtNUMTRANSENT(viLaco))
                   AND (ROWNUM              = 1);
              EXCEPTION
                WHEN NO_DATA_FOUND THEN          
                  vvEspecie      := NULL;
                  vvTipoDescarga := NULL;
                  vvDtNfSaid     := NULL;
              END;
            END IF; 
            -- Se a Especie da NF for igual a 'NE', indica que está aguardando autorização do SEFAZ,
            -- nesse caso ignora a Movimentação
            -- Desconsidera Transação de Atualização de Estoque de Importação
            IF ((NVL(vvEspecie     ,' ') <> 'NE') AND
                (NVL(vvTipoDescarga,' ') <> 'I' )) THEN
              -- Importação
              IF (NVL(vvTipoDescarga,' ') IN ('N','F')) THEN
                vtEstoque(vtCODPROD(viLaco)).vnQtImport := NVL(vtEstoque(vtCODPROD(viLaco)).vnQtImport,0) + NVL(vtQTENT(viLaco),0);
              -- Aquisição
              ELSE
                vtEstoque(vtCODPROD(viLaco)).vnQtAquis  := NVL(vtEstoque(vtCODPROD(viLaco)).vnQtAquis,0)  + NVL(vtQTENT(viLaco),0);
              END IF;
              -- Entrada - Ambos (Importação + Aquisição)
              vtEstoque(vtCODPROD(viLaco)).vnQtEnt      := NVL(vtEstoque(vtCODPROD(viLaco)).vnQtEnt,0)    + NVL(vtQTENT(viLaco),0);
            END IF;
          END IF;
          -- Se Saída
          IF (NVL(vtQTSAI(viLaco),0) > 0) THEN
            -- Se a Transação for um INTEGER, utiliza pesquisa em memória para otimizar processo
            IF (NVL(vtNUMTRANSVENDA(viLaco),0) BETWEEN 1 AND viValorMaxInteger) THEN 
              -- Primeiro pesquisa a Especie da NF em memória,
              -- se não existir em memória pesquisa na base de dados
              IF NOT (vtEspecieNFSaida.EXISTS(vtNUMTRANSVENDA(viLaco))) THEN
                BEGIN
                  SELECT PCNFSAID.ESPECIE
                       , PCNFSAID.DTSAIDA
                    INTO vvEspecie       
                       , vvDtNfSaid         
                    FROM PCNFSAID
                   WHERE (PCNFSAID.NUMTRANSVENDA = vtNUMTRANSVENDA(viLaco));
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN          
                    vvEspecie  := NULL;
                    vvDtNfSaid := NULL;
                END;
                vtEspecieNFSaida(vtNUMTRANSVENDA(viLaco)) := vvEspecie;
                vtDataNFSaida(vtNUMTRANSVENDA(viLaco))    := vvDtNfSaid;
              ELSE
                vvEspecie  := vtEspecieNFSaida(vtNUMTRANSVENDA(viLaco));
                vvDtNfSaid := vtDataNFSaida(vtNUMTRANSVENDA(viLaco));
              END IF;
            -- Se a Transação não for um INTEGER, pequisa sempre no Banco de Dados
            ELSE
              BEGIN
                SELECT PCNFSAID.ESPECIE
                     , PCNFSAID.DTSAIDA
                  INTO vvEspecie      
                     , vvDtNfSaid          
                  FROM PCNFSAID
                 WHERE (PCNFSAID.NUMTRANSVENDA = vtNUMTRANSVENDA(viLaco));
              EXCEPTION
                WHEN NO_DATA_FOUND THEN          
                  vvEspecie  := NULL;
                  vvDtNfSaid := NULL;
              END;
            END IF; 
            -- Se a Especie da NF for igual a 'NE', indica que está aguardando autorização do SEFAZ,
            -- nesse caso ignora a Movimentação
            IF (vvEspecie <> 'NE') THEN          
              vtEstoque(vtCODPROD(viLaco)).vnQtSai := NVL(vtEstoque(vtCODPROD(viLaco)).vnQtSai,0) + NVL(vtQTSAI(viLaco),0);
            END IF;
          END IF;
          -- Se Perdas
          IF (NVL(vtQTPERDA(viLaco),0) > 0) THEN
            vtEstoque(vtCODPROD(viLaco)).vnQtPerda := NVL(vtEstoque(vtCODPROD(viLaco)).vnQtPerda,0) + NVL(vtQTPERDA(viLaco),0);
          END IF;
        END IF; -- Fim Condição Se o Produto existir no Array
      END LOOP; -- Fim Laço Movimentações
    END IF; -- Fim Condição Achou Movimentações

    ----------------------------------------------------------------------------    
    -- CARREGA TABLE -----------------------------------------------------------
    ----------------------------------------------------------------------------    

    -- Se achou Produtos
    IF (vtListaProdutos.COUNT > 0) THEN

      -- Inicializa Número do Registro
      vnNumReg := 0;

      -- Laço de Produtos 
      FOR viLaco IN vtListaProdutos.FIRST..vtListaProdutos.LAST LOOP
        -- Se o Produto existir no Array
        IF (vtEstoque.EXISTS(vtListaProdutos(viLaco))) THEN
      
          -- Atualiza Campos da Table 
          vnNumReg              := NVL(vnNumReg,0) + 1;
          OUTROW.NUMREG         := NVL(vnNumReg,0);
          OUTROW.CODPROD        := vtListaProdutos(viLaco);
          OUTROW.DESCRICAOPROD  := vtEstoque(vtListaProdutos(viLaco)).vvDescricao;
          OUTROW.DCB            := vtEstoque(vtListaProdutos(viLaco)).vvDcb;
          OUTROW.DESCRICAODCB   := vtEstoque(vtListaProdutos(viLaco)).vvDescDcb;
          OUTROW.SUBSTANCIA     := vtEstoque(vtListaProdutos(viLaco)).vvSubstancia;
          OUTROW.QTESTINICIAL   := (NVL(vtEstoque(vtListaProdutos(viLaco)).vnEstEnt,0) - 
                                      NVL(vtEstoque(vtListaProdutos(viLaco)).vnEstSai,0));
          OUTROW.QTIMPORT       := vtEstoque(vtListaProdutos(viLaco)).vnQtImport;
          OUTROW.QTAQUISICAO    := vtEstoque(vtListaProdutos(viLaco)).vnQtAquis;
          OUTROW.QTENT          := vtEstoque(vtListaProdutos(viLaco)).vnQtEnt;
          OUTROW.QTSAI          := vtEstoque(vtListaProdutos(viLaco)).vnQtSai;
          OUTROW.QTPERDA        := vtEstoque(vtListaProdutos(viLaco)).vnQtPerda;
          OUTROW.QTESTOQUE      := (NVL(vtEstoque(vtListaProdutos(viLaco)).vnEstEnt,0) - 
                                      NVL(vtEstoque(vtListaProdutos(viLaco)).vnEstSai,0)) + 
                                   NVL(vtEstoque(vtListaProdutos(viLaco)).vnQtEnt,0) -  
                                   NVL(vtEstoque(vtListaProdutos(viLaco)).vnQtSai,0) -
                                   NVL(vtEstoque(vtListaProdutos(viLaco)).vnQtPerda,0);
          OUTROW.UNIDADEMEDIDA  := vtEstoque(vtListaProdutos(viLaco)).vvUnidade;
          OUTROW.MARCA          := vtEstoque(vtListaProdutos(viLaco)).vvMarca;
          OUTROW.FORMULARIOBSPO := 2; 
          OUTROW.EMBALAGEM      := vtEstoque(vtListaProdutos(viLaco)).vvEmbalagem;
        
          -- Insere dados na Table
          PIPE ROW(OUTROW);
    
        END IF; -- Fim Condição Se o Produto existir no Array
      END LOOP; -- Fim Laço Movimentações
    
    END IF; -- Fim Condição Achou Movimentações
  
  END IF; -- FIM CONDIÇÃO Se Balanço Completo Entrada/Saída BSPO

EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20000, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM);
END;