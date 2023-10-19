CREATE OR REPLACE PACKAGE BODY PKG_INTEGRACAOCONTABIL
IS
    TYPE CENTRO_CUSTO IS RECORD
    (
        CODFILIAL VARCHAR2 (2),
        PERCRATEIO PCLANCINTERMEDIARIACC.PERCRATEIO%TYPE,
        VALOR PCLANCINTERMEDIARIACC.VALOR%TYPE,
        RECNUM NUMBER (10),
        CODIGOCENTROCUSTO VARCHAR2 (30)
    );

    --RECORD PARA TOTALIZAÇÃO DOS VALORES
    TYPE VALORES IS RECORD
    (
        CODFILIAL VARCHAR2 (2),
        NUMTRANSOPERACAO NUMBER (10),
        NATUREZA VARCHAR2 (1),
        CONTA VARCHAR2 (12),
        CODHISTORICO NUMBER (4),
        HISTORICOCOMPLE VARCHAR2 (200),
        CFOP NUMBER (8),
        CODBANCO NUMBER (4),
        CODMOEDA VARCHAR2 (4),
        NUMTRANSCENTROCUSTO VARCHAR2 (12),
        TOTALDEBITO NUMBER (14, 2),
        TOTALCREDITO NUMBER (14, 2),
        DATAINTEGRACAO DATE,
        CODGRUPOBEM NUMBER,
        CHAVEGESTAO NUMBER,
        CHAVEGESTAOAUX VARCHAR2 (100),
        FORMULA VARCHAR2 (500),
        CONTAVARIAVEL VARCHAR2 (100),
        TIPOMOVIMENTACAO VARCHAR2 (100),
        TABELAGESTAO VARCHAR2 (100),
        TIPOPARCEIRO VARCHAR2 (1),
        CODPARCEIRO NUMBER (8),
        DOCUMENTO VARCHAR2 (50),
        NUMTRANSACAO NUMBER (38)
    );

    --TABLE QUE FICARÁ ARMAZENADO OS VALORES
    TYPE TABELAVALORES IS TABLE OF VALORES;

    --RECORD PARA FILIAIS
    TYPE FILIAISLANCTO IS RECORD
    (
        CODFILIAL VARCHAR2 (2),
        CGCFILIAL VARCHAR2 (8)
    );

    --TABELA QUE FICARÁ ARMAZENDO AS FILIAIS
    TYPE TABELAFILIAISLANCTO IS TABLE OF FILIAISLANCTO;

    --ITENS DA TABELA PCITENSREGRACONTABIL
    TYPE CONSULTA_ITENS IS RECORD
    (
        CODREGRA NUMBER,
        CODREDUZIDO_PC VARCHAR2 (40),
        FORMULAS VARCHAR2 (500),
        NATUREZA CHAR (1),
        TOTALIZAVALOR CHAR (1),
        CODHISTORICO NUMBER,
        HISTCOMPLREGRA VARCHAR2 (200),
        NOME_HISTORICO VARCHAR2 (80),
        CODFILIAL VARCHAR2 (20),
        DOCUMENTO PCITENSREGRACONTABIL.DOCUMENTO%TYPE
    );

    TYPE CONTAS_LANCADAS IS TABLE OF VARCHAR2 (12);

    TYPE CGC_LANCADOS IS TABLE OF VARCHAR2 (8);

    TYPE CONSULTA_LANCPROVISOES IS RECORD
    (
        CODFILIAL VARCHAR2 (2),
        DATAOPERACAO DATE,
        DATAOPERACAO1 DATE,
        DATAOPERACAO2 DATE,
        DATAOPERACAO3 DATE,
        FORNECEDOR VARCHAR2 (60),
        HISTORICO VARCHAR2 (200),
        HISTORICO2 VARCHAR2 (200),
        NUMNOTA NUMBER (10),
        VALORTITULO PCLANCAMENTO.VALOR%TYPE,
        CODCONTA NUMBER (10),
        CODFORNEC NUMBER (8),
        CODROTINA NUMBER (6),
        CODROTINACAD VARCHAR2 (40),
        NUMTRANSOPERACAO NUMBER (10),
        NUMLANCTOORIGINAL NUMBER (10),
        STATUS VARCHAR2 (1),
        MOEDA VARCHAR2 (1),
        NOMECONTAGERENCIAL VARCHAR2 (40),
        NUMNEGOCIACAO PCLANC.NUMNEGOCIACAO%TYPE,
        NUMDIIMPORTACAO PCLANC.NUMDIIMPORTACAO%TYPE,
        IDCONTROLEEMBARQUE PCLANC.IDCONTROLEEMBARQUE%TYPE,
        DUPLICATA VARCHAR2 (10),
        TIPOLANCAMENTO VARCHAR2 (1),
        TIPOPARCEIRO VARCHAR2 (1),
        NOTADESERVICO VARCHAR2 (1),
        CODCONTADESP VARCHAR2 (12),
        CODCONTAFORNECEDOR VARCHAR2 (12),
        GERAPROVLANCCONTAB VARCHAR2 (1),
        NUMEROCONTRATO PCLANC.NUMCONTRATOCAMBIO%TYPE,
        FORNECEDORPRINC VARCHAR2 (100),
        RECNUM PCLANC.RECNUM%TYPE,
        IMPOSTO VARCHAR2 (2),
        NUMINVOCE VARCHAR2 (20),
        NUMPROFORMA VARCHAR2 (20),
        PERCRATEIO NUMBER (18, 6),
        TEMINTEGRACAO VARCHAR2 (1)
    );

    TYPE CONSULTAS_PROVISOES IS TABLE OF CONSULTA_LANCPROVISOES;

    CONTASDEBLANCTO          CONTAS_LANCADAS;
    CONTASCRELANCTO          CONTAS_LANCADAS;
    CGCSLANCTO               CGC_LANCADOS;

    CONSULTA_CENTRO_CUSTO    CENTRO_CUSTO;
    VS_LISTAS_TRANSOTORIAS   CONTAS_LANCADAS;

    TYPE VALOR_FORMULA IS RECORD
    (
        FORMULA VARCHAR2 (2000),                        /* VS_FORMULA%TYPE, */
        VALOR NUMBER (22, 2)
    );

    TYPE TYPE_LISTA_FORMULAS IS TABLE OF VALOR_FORMULA;

    LISTA_FORMULAS           TYPE_LISTA_FORMULAS;

    /****************************************************************************
      FUNÇÃO PARA OBTER NÚMERO VALIDO COM DUAS CASAS DECIMAIS
    *****************************************************************************/
    PROCEDURE VALID_NUMBER (VS_FORMULA IN OUT VARCHAR2)
    IS
        VN_VALORLANCTO   NUMBER;
        VN_PONTO         NUMBER;
    BEGIN
        EXECUTE IMMEDIATE
            'SELECT instr(''' || VS_FORMULA || ''', ''.'') FROM DUAL'
            INTO VN_PONTO;

        IF VN_PONTO > 0
        THEN
            EXECUTE IMMEDIATE
                   'select substr('''
                || VS_FORMULA
                || ''', 1, INSTR('''
                || VS_FORMULA
                || ''', ''.'') + 2) from dual '
                INTO VS_FORMULA;
        END IF;
    END;

    /****************************************************************************
      FUNÇÃO PARA OBTER DATA DE CONTABILIZAÇÃO OU DATA DE LANÇAMENTO
    *****************************************************************************/
    FUNCTION F_RETORNA_DATA_LANCPROVISOES (
        PCODFATOGERADOR           IN INTEGER,
        PCODREGRA                 IN INTEGER,
        DT_INTEGRACAO_OR_LANCTO   IN INTEGER,
        DATAOPERACAO              IN DATE,
        DATAOPERACAO1             IN DATE DEFAULT NULL,
        DATAOPERACAO2             IN DATE DEFAULT NULL,
        DATAOPERACAO3             IN DATE DEFAULT NULL,
        DATAPGTO                  IN DATE DEFAULT NULL,
        DATABAIXA                 IN DATE DEFAULT NULL)
        RETURN DATE
    IS
        VD_DATA                         DATE;
        VS_FORMADTCONTABILIZACAO        VARCHAR2 (2);
        VS_BUSCARDADOSPELADATA          VARCHAR2 (2);
        VS_AGRUPAMENTOREGRA             VARCHAR2 (2);
        VS_DIACONTABILIZACAO            VARCHAR2 (2);
        DATAINTEGRACAO         CONSTANT INTEGER := 0;
        DATALANCTO             CONSTANT INTEGER := 1;
        BAIXA                  CONSTANT VARCHAR2 (2) := 'B';
        COMPENSACAO            CONSTANT VARCHAR2 (2) := 'C';
        DEBITO                 CONSTANT VARCHAR2 (2) := 'D';
        ENTRADA                CONSTANT VARCHAR2 (2) := 'E';
        PAGAMENTO              CONSTANT VARCHAR2 (2) := 'P';
        SAIDA                  CONSTANT VARCHAR2 (2) := 'S';
        VENDA                  CONSTANT VARCHAR2 (2) := 'V';
        EMISSAO                CONSTANT VARCHAR2 (2) := 'E';
        DESDOBRAMENTO_CARTAO   CONSTANT VARCHAR2 (2) := 'D';
        AGRUPAMENTO_DIARIO     CONSTANT VARCHAR2 (2) := 'D';
        AGRUPAMENTO_MENSAL     CONSTANT VARCHAR2 (2) := 'M';
        AGRUPAMENTO_INDIVID    CONSTANT VARCHAR2 (2) := 'I';
        PRIMEIRO_DIA_MES       CONSTANT VARCHAR2 (2) := 'P';
        ULTIMO_DIA_MES         CONSTANT VARCHAR2 (2) := 'U';
        ESTORNO                CONSTANT VARCHAR2 (2) := 'T';
    BEGIN
        /*
        * DT_INTEGRACAO_OR_LANCTO ->
        * 0 : DATAINTEGRACAO
        * 1 : DATALANCTO
        */
        /*
         * Entrada :
         *  PCODREGRA         IN  INTEGER       : Código da regra para fazer a busca em PCREGRACONTABIL.
         *  PCODFATOGERADOR   IN  INTEGER       : Código do fato gerador, pois o comportamento muda conforme o fato.
         *  DATAOPERACAO      IN  DATE          : Encontrado no RECORD CONSULTA_LANCPROVISOES, padrão NULL.
         *  DATAOPERACAO1     IN  DATE          : Encontrado no RECORD CONSULTA_LANCPROVISOES, padrão NULL.
         *  DATAOPERACAO2     IN  DATE          : Encontrado no RECORD CONSULTA_LANCPROVISOES, padrão NULL.
         *  DATAOPERACAO3     IN  DATE          : Encontrado no RECORD CONSULTA_LANCPROVISOES, padrão NULL.
         *  DATAPGTO          IN  DATE          : Encontrado no RECORD CONSULTA_LANCPROVISOES, padrão NULL.
         *  DATABAIXA         IN  DATE          : Encontrado no RECORD CONSULTA_LANCPROVISOES, padrão NULL.
         *  DT_INTEGRACAO_OR_LANCTO IN INTEGER  : 0 : DATAINTEGRACAO OU  1 : DATALANCTO.
         *
         * Transformação :
         *  Selecionar a data com base nos códigos da tabela : PCREGRACONTABIL.
         *
         * Saída:
         *  VD_DATA DATE: Contendo a data selecionada.
         */

        --PEGA DATA DE LANÇAMENTO DE ACORDO COM SELECIONADO NA REGRA.

        SELECT NVL (FORMADTCONTABILIZACAO, 'X'),
               NVL (BUSCARDADOSPELADATA, 'Z'),
               NVL (PCREGRACONTABIL.AGRUPAMENTOREGRA, 'Y'),
               NVL (PCREGRACONTABIL.DIACONTABILIZACAO, 'W')
          INTO VS_FORMADTCONTABILIZACAO,
               VS_BUSCARDADOSPELADATA,
               VS_AGRUPAMENTOREGRA,
               VS_DIACONTABILIZACAO
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;


        --VS_FORMADTCONTABILIZACAO := 'C';
        --VS_BUSCARDADOSPELADATA   := 'C';

        VD_DATA :=
            (CASE
                 WHEN PCODFATOGERADOR IN (1,
                                          2,
                                          5,
                                          6,
                                          8,
                                          12,
                                          14,
                                          16,
                                          19)
                 THEN
                     DATAOPERACAO
                 WHEN PCODFATOGERADOR = 11
                 THEN
                     (CASE
                          WHEN VS_FORMADTCONTABILIZACAO = SAIDA
                          THEN
                              DATAOPERACAO
                          WHEN VS_FORMADTCONTABILIZACAO = EMISSAO
                          THEN
                              DATAOPERACAO1
                          WHEN VS_FORMADTCONTABILIZACAO =
                               DESDOBRAMENTO_CARTAO
                          THEN
                              DATAOPERACAO2
                      END)
                 WHEN PCODFATOGERADOR IN (3,
                                          4,
                                          7,
                                          9,
                                          10,
                                          13)
                 THEN
                     (CASE
                          WHEN DT_INTEGRACAO_OR_LANCTO = DATALANCTO
                          THEN
                              (CASE
                                   WHEN VS_FORMADTCONTABILIZACAO = BAIXA
                                   THEN
                                       DATAOPERACAO
                                   WHEN VS_FORMADTCONTABILIZACAO =
                                        COMPENSACAO
                                   THEN
                                       DATAOPERACAO1
                                   WHEN VS_FORMADTCONTABILIZACAO = DEBITO
                                   THEN
                                       DATAOPERACAO2
                                   WHEN VS_FORMADTCONTABILIZACAO = ESTORNO
                                   THEN
                                       DATAOPERACAO2
                                   WHEN VS_FORMADTCONTABILIZACAO = ENTRADA
                                   THEN
                                       DATAOPERACAO3
                                   WHEN VS_FORMADTCONTABILIZACAO = PAGAMENTO
                                   THEN
                                       DATAPGTO
                                   WHEN VS_FORMADTCONTABILIZACAO = SAIDA
                                   THEN
                                       DATAOPERACAO
                                   WHEN VS_FORMADTCONTABILIZACAO = VENDA
                                   THEN
                                       DATAOPERACAO2
                                   ELSE
                                       DATAOPERACAO
                               END)
                          WHEN DT_INTEGRACAO_OR_LANCTO = DATAINTEGRACAO
                          THEN
                              (CASE
                                   WHEN VS_BUSCARDADOSPELADATA = BAIXA
                                   THEN
                                       DATAOPERACAO
                                   WHEN VS_BUSCARDADOSPELADATA = COMPENSACAO
                                   THEN
                                       DATAOPERACAO1
                                   WHEN VS_BUSCARDADOSPELADATA = DEBITO
                                   THEN
                                       DATAOPERACAO2
                                   WHEN VS_BUSCARDADOSPELADATA = ENTRADA
                                   THEN
                                       DATAOPERACAO3
                                   WHEN VS_BUSCARDADOSPELADATA = PAGAMENTO
                                   THEN
                                       DATAPGTO
                                   WHEN VS_BUSCARDADOSPELADATA = SAIDA
                                   THEN
                                       DATAOPERACAO
                                   WHEN VS_BUSCARDADOSPELADATA = VENDA
                                   THEN
                                       DATAOPERACAO2
                                   ELSE
                                       DATAOPERACAO
                               END)
                      END)
                 WHEN PCODFATOGERADOR = 15
                 THEN
                     DATABAIXA
                 WHEN PCODFATOGERADOR = 18
                 THEN
                     DATAOPERACAO
                 WHEN PCODFATOGERADOR = 17
                 THEN
                     (CASE
                          WHEN DT_INTEGRACAO_OR_LANCTO = DATALANCTO
                          THEN
                              (CASE
                                   WHEN VS_FORMADTCONTABILIZACAO =
                                        COMPENSACAO
                                   THEN
                                       DATAOPERACAO1
                                   ELSE
                                       DATAOPERACAO
                               END)
                          WHEN DT_INTEGRACAO_OR_LANCTO = DATAINTEGRACAO
                          THEN
                              TRUNC (SYSDATE)
                      END)
                 ELSE
                     DATAOPERACAO
             END);
        VD_DATA :=
            CASE
                WHEN     (VS_AGRUPAMENTOREGRA = AGRUPAMENTO_MENSAL)
                     AND (DT_INTEGRACAO_OR_LANCTO = DATALANCTO)
                THEN
                    (CASE
                         WHEN VS_DIACONTABILIZACAO = ULTIMO_DIA_MES
                         THEN
                             LAST_DAY (TRUNC (VD_DATA))
                         WHEN VS_DIACONTABILIZACAO = PRIMEIRO_DIA_MES
                         THEN
                             TO_DATE (
                                    '01/'
                                 || TO_CHAR (EXTRACT (MONTH FROM VD_DATA))
                                 || '/'
                                 || TO_CHAR (EXTRACT (YEAR FROM VD_DATA)),
                                 'DD/MM/YYYY')
                     END)
                ELSE
                    VD_DATA
            END;
        RETURN VD_DATA;
    END;


    FUNCTION F_RETORNA_TIPO_INCONSISTENCIA (P_CONTAEXISTE IN VARCHAR2)
        RETURN VARCHAR2
    IS
        V_RETORNO   VARCHAR2 (2);
    BEGIN
        V_RETORNO :=
            CASE
                WHEN P_CONTAEXISTE = 'N' THEN                     /*CONTA OK*/
                                              '0'
                WHEN P_CONTAEXISTE = 'S' THEN          /*Contas Inexistentes*/
                                              '2'
                WHEN P_CONTAEXISTE = 'X' THEN /*Conta sintética informada no lugar de conta analítica  */
                                              '11'
                WHEN P_CONTAEXISTE = 'I' THEN /*Conta não existente no plano de contas do exercício  */
                                              '9'
                WHEN P_CONTAEXISTE = 'E' THEN /* Erro não mapeado na integração */
                                              '2'
            END;
        RETURN V_RETORNO;
    END;

    /****************************************************************************
      FUNÇÃO PREPARA SQL FATO GERADOR
    *****************************************************************************/
    FUNCTION F_PREPARA_SQL_FATO_GERADOR (PCODREGRA           IN NUMBER,
                                         PNUMTRANSOPERACAO   IN NUMBER,
                                         PCODFILIAL          IN VARCHAR2)
        RETURN CLOB
    IS
        V_SQLFATO                  CLOB;
        RESULTADO                  CLOB;
        V_FILTRO_AUX               CLOB;
        V_FILTRO_COBRANCA          VARCHAR2 (200);
        V_CODFATOGERADOR           NUMBER;
        VS_FORMADTCONTABILIZACAO   VARCHAR2 (1);
        VS_AGRUPAMENTOREGRA        PCREGRACONTABIL.AGRUPAMENTOREGRA%TYPE;
        VS_NF_RATEIO_CONTA         VARCHAR2 (2);
        VS_BUSCARDADOSPELADATA     VARCHAR2 (1);
    --PESQUISA_FILIAIS SYS_REFCURSOR;
    --PRAGMA AUTONOMOUS_TRANSACTION;


    BEGIN
        SELECT CODFATOGERADOR,
               FORMADTCONTABILIZACAO,
               NF_RATEIO_CONTA,
               BUSCARDADOSPELADATA
          INTO V_CODFATOGERADOR,
               VS_FORMADTCONTABILIZACAO,
               VS_NF_RATEIO_CONTA,
               VS_BUSCARDADOSPELADATA
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        RESULTADO := F_RETORNA_FILTROS_REGRA (PCODREGRA, V_FILTRO_COBRANCA);

        V_SQLFATO := F_PREPARA_SQL_FATO_PELA_REGRA (PCODREGRA, PCODFILIAL);

        V_SQLFATO := REPLACE (V_SQLFATO, 'PCODFILIAL', PCODFILIAL);

        IF (V_CODFATOGERADOR = 7)
        THEN
            IF (INSTR (V_FILTRO_COBRANCA, 'NOT IN') > 0)
            THEN
                V_FILTRO_COBRANCA :=
                    REPLACE (V_FILTRO_COBRANCA,
                             'NVL(CODMOEDA, 0)',
                             'B.CODCOB');
                V_FILTRO_COBRANCA := REPLACE (V_FILTRO_COBRANCA, 'NOT', '');
                V_FILTRO_AUX :=
                       'AND NOT EXISTS (SELECT 1 FROM PCMOVCR B WHERE M.NUMTRANS = B.NUMTRANS AND M.DATA = B.DATA '
                    || V_FILTRO_COBRANCA
                    || ')';
                V_SQLFATO :=
                    REPLACE (V_SQLFATO, '&MACROFILTROCOBRANCA', V_FILTRO_AUX);
            ELSE
                V_SQLFATO := REPLACE (V_SQLFATO, '&MACROFILTROCOBRANCA', '');
            END IF;
        END IF;

        /*
          PCLANC AS L,
          PCNFBASEENT AS A,
          -- AND L.DTEMISSAO = A.DTENTRADA
          Esse trecho foi comentado para solução de um probelma reltado em :
            https://jiraproducao.totvs.com.br/browse/DDCONT-4979
          Essa solução é de contorno, pois o serviço que grava a pclanc
          não validava essa regra ao inseri na PCLANC, entretanto pode gerar
          perca de desempenho, sendo assim fica em observação essa alteração.
          Valeria o mesmo se fosse: -- AND L.DTEMISSAO = A.DTEMISSAO
        */
        IF VS_NF_RATEIO_CONTA = 'S'
        THEN
            V_SQLFATO :=
                REPLACE (V_SQLFATO,
                         '&MACROVALORFATO1&',
                         ' 0  AS VLDESDOBRADO ,');
            V_SQLFATO :=
                REPLACE (
                    V_SQLFATO,
                    '&MACROWHEREEXISTSFATO1&',
                    ' AND EXISTS (SELECT 1 FROM PCLANC L 
                                                                 WHERE L.NUMTRANSENT = A.NUMTRANSENT      
                                                                    -- AND L.DTEMISSAO = A.DTENTRADA          
                                                                    AND L.UTILIZOURATEIOCONTA = ''S'')');
            V_SQLFATO := REPLACE (V_SQLFATO, '&MACROWHEREFATO1&', '');
        ELSE
            V_SQLFATO :=
                REPLACE (V_SQLFATO,
                         '&MACROVALORFATO1&',
                         'SUM(A.VLDESDOBRADO) AS VLDESDOBRADO,');
            V_SQLFATO :=
                REPLACE (
                    V_SQLFATO,
                    '&MACROWHEREEXISTSFATO1&',
                    ' AND NOT EXISTS (SELECT 1 FROM PCLANC L 
                                                                 WHERE L.NUMTRANSENT = A.NUMTRANSENT      
                                                                    -- AND L.DTEMISSAO = A.DTENTRADA          
                                                                    AND L.UTILIZOURATEIOCONTA = ''S'')');
            V_SQLFATO := REPLACE (V_SQLFATO, '&MACROWHEREFATO1&', 'AND 1=2');
        END IF;

        IF V_CODFATOGERADOR = 8
        THEN
            V_SQLFATO := REPLACE (V_SQLFATO, '&MACROFILTRO&', RESULTADO);
            RESULTADO := V_SQLFATO;
        ELSE
            RESULTADO :=
                   'SELECT * FROM ('
                || V_SQLFATO
                || ') WHERE 1 = 1 '
                || RESULTADO;
        END IF;

        IF (PNUMTRANSOPERACAO <> 0)
        THEN
            RESULTADO :=
                RESULTADO || ' AND NUMTRANSOPERACAO =  ' || PNUMTRANSOPERACAO;
        END IF;


        IF (V_CODFATOGERADOR = 4) AND (VS_FORMADTCONTABILIZACAO = 'P')
        THEN
            RESULTADO :=
                   RESULTADO
                || CHR (13)
                || CHR (10)
                || -- 'AND NVL(TEMINTEGRACAO, ''P'') <> ''I''' || CHR(13) || CHR(10) ||
                   'ORDER BY DATAPGTO, NUMTRANSOPERACAO';
        ELSIF (V_CODFATOGERADOR = 9) AND (VS_FORMADTCONTABILIZACAO = 'C')
        THEN
            RESULTADO :=
                   RESULTADO
                || CHR (13)
                || CHR (10)
                || -- 'AND NVL(TEMINTEGRACAO, ''P'') <> ''I''' || CHR(13) || CHR(10) ||
                   'ORDER BY DATAOPERACAO1, NUMTRANSOPERACAO';
        ELSIF (V_CODFATOGERADOR = 9) AND (VS_FORMADTCONTABILIZACAO = 'V')
        THEN
            RESULTADO :=
                   RESULTADO
                || CHR (13)
                || CHR (10)
                || -- 'AND NVL(TEMINTEGRACAO, ''P'') <> ''I''' || CHR(13) || CHR(10) ||
                   'ORDER BY DATAOPERACAO2, NUMTRANSOPERACAO';
		ELSIF (V_CODFATOGERADOR = 9) AND (VS_FORMADTCONTABILIZACAO = 'E')
        THEN
            RESULTADO :=
                   RESULTADO
                || CHR (13)
                || CHR (10)
                || 
                   'ORDER BY DATAOPERACAO3, NUMTRANSOPERACAO';		   
        ELSIF (V_CODFATOGERADOR = 14)
        THEN
            RESULTADO :=
                   RESULTADO
                || CHR (13)
                || CHR (10)
                || -- 'AND NVL(TEMINTEGRACAO, ''P'') <> ''I''' || CHR(13) || CHR(10) ||
                   'ORDER BY ORIGEM, DATAOPERACAO, NUMTRANSOPERACAO';
        ELSIF (V_CODFATOGERADOR = 15)
        THEN
            IF VS_AGRUPAMENTOREGRA = 'I'
            THEN
                RESULTADO :=
                       RESULTADO
                    || CHR (13)
                    || CHR (10)
                    || -- 'AND NVL(TEMINTEGRACAO, ''P'') <> ''I''' || CHR(13) || CHR(10) ||
                       'ORDER BY DATABAIXA, CODIGOGRUPOBEM, CODIGOBEM, NUMEROSEQUENCIA';
            ELSE
                RESULTADO :=
                       RESULTADO
                    || CHR (13)
                    || CHR (10)
                    || -- 'AND NVL(TEMINTEGRACAO, ''P'') <> ''I''' || CHR(13) || CHR(10) ||
                       'ORDER BY CODIGOGRUPOBEM, DATABAIXA, CODIGOBEM, NUMEROSEQUENCIA';
            END IF;
        ELSIF (V_CODFATOGERADOR = 16)
        THEN
            RESULTADO :=
                   RESULTADO
                || CHR (13)
                || CHR (10)
                || -- 'AND NVL(TEMINTEGRACAO, ''P'') <> ''I''' || CHR(13) || CHR(10) ||
                   'ORDER BY DATAOPERACAO, NUMTRANSOPERACAO, DUPLICATA, PRESTACAO';
        ELSIF (V_CODFATOGERADOR = 17)
        THEN
            RESULTADO :=
                   RESULTADO
                || CHR (13)
                || CHR (10)
                || -- 'AND NVL(TEMINTEGRACAO, ''P'') <> ''I''' || CHR(13) || CHR(10) ||
                   'ORDER BY DATAOPERACAO, NUMTRANSOPERACAO';
        /*
         * Correção da solicitação do erro do order by
         * daniel.cavalcante  21/12/2016 16:13:30
         * VersaoRotina | 28.0.9.6
         * Tarefa       | HIS.02723.2015
         * Rotina       | PCSIS2100.PC
         * Descricao    | Desenvolvido fato gerador de baixa de crédido de cliente.
         */

        ELSIF (V_CODFATOGERADOR = 8)
        THEN
            RESULTADO :=
                   RESULTADO
                || CHR (13)
                || CHR (10)
                || 'ORDER BY NUMTRANSOPERACAO, DATAOPERACAO';

        ELSE
            RESULTADO :=
                   RESULTADO
                || CHR (13)
                || CHR (10)
                || 'ORDER BY DATAOPERACAO, NUMTRANSOPERACAO';
        END IF;

        --  INSERT INTO SQL_GERADO (DATA, TEXTO_SQL, CODREGRA) VALUES (SYSDATE, RESULTADO, PCODREGRA);
        --  COMMIT;

        RETURN RESULTADO;
    END;

    /****************************************************************************
      PROCEDURE PARA EXCLUSÃO DOS DADOS GERAL DA PCLANCINTERMEDIARIA
    *****************************************************************************/
    PROCEDURE P_EXCLUI_LANCINTERMEDIARIA_GER (PCODREGRA     IN NUMBER,
                                              PCODFILIAL    IN VARCHAR2,
                                              PDATAINI      IN DATE,
                                              PDATAFIM      IN DATE,
                                              PCONSOLIDAR   IN VARCHAR2)
    IS
        VS_SQLAUX           VARCHAR2 (2000);
        FILIAIS             SYS_REFCURSOR;
        VS_CODFILIAL_AUX    VARCHAR2 (2);
        VN_CODFATOGERADOR   NUMBER;
    BEGIN
        SELECT CODFATOGERADOR
          INTO VN_CODFATOGERADOR
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        VS_SQLAUX := 'SELECT CODFILIAL
                    FROM PCCONFFILIAL
                   WHERE ANO = :ANO ';

        IF PCONSOLIDAR = 'S'
        THEN
            VS_SQLAUX :=
                VS_SQLAUX || 'AND TO_CHAR(CODGRUPOFILIAL) = :CODFILIAL ';

            OPEN FILIAIS FOR VS_SQLAUX
                USING EXTRACT (YEAR FROM PDATAFIM), PCODFILIAL;
        ELSE
            VS_SQLAUX :=
                VS_SQLAUX || 'AND CODFILIAL IN ( ' || PCODFILIAL || ' ) ';

            OPEN FILIAIS FOR VS_SQLAUX USING EXTRACT (YEAR FROM PDATAFIM);
        END IF;

        LOOP
            FETCH FILIAIS INTO VS_CODFILIAL_AUX;

            EXIT WHEN FILIAIS%NOTFOUND;

            --DELETE OS CENTRO DE CUSTOS GERADOS ANTERIORMENTE
            IF    (VN_CODFATOGERADOR = 3)
               OR (VN_CODFATOGERADOR = 9)
               OR (VN_CODFATOGERADOR = 1)
               OR (VN_CODFATOGERADOR = 5)
            THEN
                DELETE FROM PCLANCINTERMEDIARIACC
                      WHERE NUMTRANSCENTROCUSTO IN
                                (SELECT NUMTRANSCENTROCUSTO
                                   FROM PCLANCINTERMEDIARIA
                                  WHERE     DATAINTEGRACAO BETWEEN PDATAINI
                                                               AND PDATAFIM
                                        AND CODREGRA = PCODREGRA
                                        AND CODFILIAL = VS_CODFILIAL_AUX
                                        AND STATUS = 'P');
            END IF;

            DELETE FROM PCLANCINTERMEDIARIA
                  WHERE     DATAINTEGRACAO BETWEEN PDATAINI AND PDATAFIM
                        AND CODREGRA = PCODREGRA
                        AND CODFILIAL = VS_CODFILIAL_AUX
                        AND STATUS = 'P';
        END LOOP;

        CLOSE FILIAIS;
    END;

    /****************************************************************************
      PROCEDURE PARA EXCLUSÃO DOS DADOS INDIVIDUAL DA PCLANCINTERMEDIARIA
    *****************************************************************************/
    PROCEDURE P_EXCLUI_LANCINTERMEDIARIA_IND (PCODREGRA           IN NUMBER,
                                              PNUMTRANSOPERACAO   IN NUMBER,
                                              PDTLANC             IN DATE)
    IS
    BEGIN
        --DELETE OS CENTRO DE CUSTOS GERADOS ANTERIORMENTE
        DELETE FROM PCLANCINTERMEDIARIACC
              WHERE NUMTRANSCENTROCUSTO IN
                        (SELECT NUMTRANSCENTROCUSTO
                           FROM PCLANCINTERMEDIARIA
                          WHERE     CODREGRA = PCODREGRA
                                AND NUMTRANSOPERACAO = PNUMTRANSOPERACAO
                                AND STATUS = 'P');

        DELETE FROM PCLANCINTERMEDIARIA
              WHERE     CODREGRA = PCODREGRA
                    AND NUMTRANSOPERACAO = PNUMTRANSOPERACAO
                    AND STATUS = 'P'
                    AND DATALANCTO = PDTLANC;
    END;

    /****************************************************************************
      FUNÇÃO PREPARA ITENS DA REGRA CONTABIL
    *****************************************************************************/
    FUNCTION F_ITENS_REGRA_CONTABIL (
        PUSACONTATRANSITORIA   IN BOOLEAN DEFAULT FALSE)
        RETURN VARCHAR2
    IS
    BEGIN
        IF PUSACONTATRANSITORIA
        THEN
            RETURN 'SELECT *
              FROM (SELECT I.CODREGRA
                          ,I.CODREDUZIDO_PC
                          ,I.FORMULAS
                          ,I.NATUREZA
                          ,TOTALIZAVALOR
                          ,I.CODHISTORICO
                          ,I.HISTCOMPLREGRA
                          ,H.NOME_HISTORICO
                          ,I.CODFILIALLANCTO
                          ,I.DOCUMENTO
                      FROM PCITENSREGRACONTABIL I, PCHISTORICO H
                     WHERE I.CODHISTORICO = H.CODHISTORICO(+)
                       AND I.CODREGRA >= (SELECT MIN(CODREGRA) FROM PCITENSREGRACONTABIL)
                       AND CODREGRA = :CODREGRA
                    UNION ALL
                    SELECT I.CODREGRA
                          ,''CONTATRANSITORIA'' AS CODREDUZIDO_PC
                          ,I.FORMULAS
                          ,''D'' AS NATUREZA
                          ,TOTALIZAVALOR
                          ,I.CODHISTORICO
                          ,I.HISTCOMPLREGRA
                          ,H.NOME_HISTORICO
                          ,CASE WHEN I.NATUREZA = ''D'' THEN I.CODFILIALLANCTO ELSE ''FILIALTRANSITORIA'' END AS CODFILIALLANCTO
                          ,I.DOCUMENTO
                      FROM PCITENSREGRACONTABIL I, PCHISTORICO H
                     WHERE I.CODHISTORICO = H.CODHISTORICO(+)
                       AND I.CODREDUZIDO_PC = ''CONTACONTABILBANCO''
                       AND I.CODREGRA >= (SELECT MIN(CODREGRA) FROM PCITENSREGRACONTABIL)
                       AND CODREGRA = :CODREGRA
                    UNION ALL
                    SELECT I.CODREGRA
                          ,''CONTATRANSITORIA'' AS CODREDUZIDO_PC
                          ,I.FORMULAS
                          ,''C'' AS NATUREZA
                          ,TOTALIZAVALOR
                          ,I.CODHISTORICO
                          ,I.HISTCOMPLREGRA
                          ,H.NOME_HISTORICO
                          ,CASE WHEN I.NATUREZA = ''C'' THEN I.CODFILIALLANCTO ELSE ''FILIALTRANSITORIA'' END AS CODFILIALLANCTO
                          ,I.DOCUMENTO
                      FROM PCITENSREGRACONTABIL I, PCHISTORICO H
                     WHERE I.CODHISTORICO = H.CODHISTORICO(+)
                       AND I.CODREDUZIDO_PC = ''CONTACONTABILBANCO''
                       AND I.CODREGRA >= (SELECT MIN(CODREGRA) FROM PCITENSREGRACONTABIL)
                       AND CODREGRA = :CODREGRA)
             ORDER BY NATUREZA DESC';
        ELSE
            RETURN 'SELECT I.CODREGRA,
                 I.CODREDUZIDO_PC,
                 I.FORMULAS,
                 I.NATUREZA,
                 TOTALIZAVALOR,
                 I.CODHISTORICO,
                 I.HISTCOMPLREGRA,
                 H.NOME_HISTORICO,
                 I.CODFILIALLANCTO,
                 I.DOCUMENTO
          FROM PCITENSREGRACONTABIL I,
               PCHISTORICO H
          WHERE I.CODHISTORICO = H.CODHISTORICO(+)
          AND I.CODREGRA >= (SELECT MIN(CODREGRA) FROM PCITENSREGRACONTABIL)
          AND   CODREGRA       = :CODREGRA

          ORDER BY NATUREZA DESC';
        END IF;
    END;

    /****************************************************************************
    Faz tratamento do DePara para controlar se existe conta ou não
    *****************************************************************************/
    PROCEDURE TRATAR_CONTA_INEXISTENTE (
        PS_CONTA_EXISTE            IN     VARCHAR2,
        PS_TEM_CONTA_INEXISTENTE   IN OUT VARCHAR2)
    IS
    BEGIN
        IF PS_TEM_CONTA_INEXISTENTE NOT IN ('S', 'I')
        THEN
            PS_TEM_CONTA_INEXISTENTE :=
                CASE PS_CONTA_EXISTE
                    WHEN 'S' THEN 'N'                            --> ANALITICA
                    WHEN 'N' THEN 'S'  --> CONTA NÃO EXISTE NO PLANO DE CONTAS
                    WHEN 'X' THEN 'X'                            --> SINTETICA
                    WHEN 'I' THEN 'I'        --> INEXISTENTE NO BANCO DE DADOS
                    ELSE 'E'                                          --> ERRO
                END;
        END IF;
    END;


    /****************************************************************************
      FUNÇÃO QUE TESTA SE A CONTA INFORMADA EXISTE NO PLANO E NO BANCO DE DADOS
      S -> CONTA ANALÍTICA - CONTA EXISTE NO PLANO DE CONTAS
      N -> CONTA NÃO EXISTE NO PLANO DE CONTAS
      X -> CONTA SINTÉTICA - NÃO RECEBE LANÇAMENTO - EXISTE NO PLANO DE CONTAS
      I -> CONTA INEXISTENTE NO BANCO DE DADOS
    *****************************************************************************/
    FUNCTION F_VERIFICA_CONTA_EXISTE (PS_CODREDUZIDO_PC   IN VARCHAR2,
                                      PN_CODPLANOCONTA    IN NUMBER)
        RETURN VARCHAR2
    IS
        VS_EXISTE   VARCHAR2 (1);
    BEGIN
        VS_EXISTE := 'I';

        FOR DADOS
            IN (SELECT M.CODREDUZIDO_PC,
                       M.CODPLANOCONTA,
                       NVL (M.RECEBE_LANCTO, 'N') AS RECEBE_LANCTO
                  FROM PCMODELOPC M, PCPLANOCONTA P
                 WHERE     P.CODPLANOCONTA = M.CODPLANOCONTA
                       AND M.CODPLANOCONTA >=
                           (SELECT MIN (CODPLANOCONTA) FROM PCMODELOPC)
                       AND M.CODREDUZIDO_PC = PS_CODREDUZIDO_PC)
        LOOP
            VS_EXISTE := 'N';

            IF     DADOS.CODPLANOCONTA = PN_CODPLANOCONTA
               AND DADOS.RECEBE_LANCTO = 'S'
            THEN
                VS_EXISTE := 'S';
                EXIT;
            ELSIF     DADOS.CODPLANOCONTA = PN_CODPLANOCONTA
                  AND DADOS.RECEBE_LANCTO = 'N'
            THEN
                VS_EXISTE := 'X';
                EXIT;
            END IF;
        END LOOP;

        RETURN VS_EXISTE;
    END;


    FUNCTION F_RETORNA_RECNUM_JUROS_DESC (PN_RECNUM    IN NUMBER,
                                          PS_FORMULA   IN VARCHAR2)
        RETURN VARCHAR2
    IS
        V_RECNUM   NUMBER (20) := 0;
    BEGIN
        BEGIN
            IF PS_FORMULA = 'VALORJUROS'
            THEN
                SELECT L.RECNUM
                  INTO V_RECNUM
                  FROM PCLANC L, PCCONSUM
                 WHERE     L.RECNUMBAIXA = PN_RECNUM
                       AND L.CODCONTA = PCCONSUM.CODCONTPAGJUR
                       AND ROWNUM = 1;
            ELSIF PS_FORMULA = 'VALORDESCONTO'
            THEN
                SELECT L.RECNUM
                  INTO V_RECNUM
                  FROM PCLANC L, PCCONSUM
                 WHERE     L.RECNUMBAIXA = PN_RECNUM
                       AND L.CODCONTA IN
                               (PCCONSUM.CODCONTDESCCONC,
                                PCCONSUM.CODCONTANTPAG)
                       AND ROWNUM = 1;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                V_RECNUM := 0;
        END;

        RETURN TO_CHAR (V_RECNUM);
    END;

    /****************************************************************************
      PROCEDURE PARA DEFINIR QUE O LANÇAMENTO ESTÁ COM INCONSISTÊNCIAS
    *****************************************************************************/
    PROCEDURE P_PASSA_INCONSISTENCIA_LANC (
        PN_NUMTRANSLANCTO       IN NUMBER,
        PS_TIPOINCONSISTENCIA   IN VARCHAR2,
        PDTLANCINI              IN DATE,
        PDTLANCFIM              IN DATE)
    IS
    BEGIN
        --Se PS_TIPOINCONSISTENCIA = 1: Valores divergentes
        --Se PS_TIPOINCONSISTENCIA = 2: Contas Inexistentes
        --Se PS_TIPOINCONSISTENCIA = 3: Lançamentos duplicados --> não é mais utilizado no fatos geradores, garantir no select do fato
        --Se PS_TIPOINCONSISTENCIA = 4: Regras sem movimentação
        --Se PS_TIPOINCONSISTENCIA = 5: Lançamentos sem data de compensação
        --Se PS_TIPOINCONSISTENCIA = 6: Com advertência
        --Se PS_TIPOINCONSISTENCIA = 7: ERRO: CGC Divergentes
        --Se PS_TIPOINCONSISTENCIA = 8: ERRO: Lançamento deve ser integrado consolidado
        --Se PS_TIPOINCONSISTENCIA = 9: Conta não existente no plano de contas do exercício
        --Se PS_TIPOINCONSISTENCIA = 10: Conta que compões DMPL/DLPA, mas com histórico que não está marcado como DMPL/DLPA
        --Se PS_TIPOINCONSISTENCIA = 11: Conta sintética informada no lugar de conta analítica
        IF ((PDTLANCINI IS NOT NULL) AND (PDTLANCFIM IS NOT NULL))
        THEN
            UPDATE PCLANCINTERMEDIARIA
               SET INCONSISTENCIA = PS_TIPOINCONSISTENCIA
             WHERE     NUMTRANSLANCTO = PN_NUMTRANSLANCTO
                   AND DATALANCTO BETWEEN PDTLANCINI AND PDTLANCFIM;
        ELSE
            UPDATE PCLANCINTERMEDIARIA
               SET INCONSISTENCIA = PS_TIPOINCONSISTENCIA
             WHERE NUMTRANSLANCTO = PN_NUMTRANSLANCTO;
        END IF;
    END;


    /****************************************************************************
      PROCEDURE PARA GRAVAR OS DADOS DA TABELA INTERMEDIÁRIS
    *****************************************************************************/
    PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA (
        PS_CODFILIAL             IN VARCHAR2,
        PN_NUMTRANSLANCTO        IN NUMBER,
        PN_NUMSEQ                IN NUMBER,
        PD_DATALANCTO            IN DATE,
        PS_DOCUMENTO             IN VARCHAR2,
        PN_CODHISTORICO          IN NUMBER,
        PS_HISTORICO_COMPL       IN VARCHAR2,
        PN_CODPLANOCONTA         IN NUMBER,
        PS_CODREDUZIDO_PC        IN VARCHAR2,
        PS_NATUREZA              IN CHAR,
        PN_VALOR                 IN NUMBER,
        PN_CODREGRA              IN NUMBER,
        PS_OPERACAO              IN VARCHAR2,
        PN_NUMTRANSOPERACAO      IN NUMBER,
        PS_INCONSISTENCIA        IN CHAR,
        PS_STATUS                IN VARCHAR2,
        PD_DATAINTEGRACAO        IN DATE,
        PN_CFOP                  IN NUMBER,
        PN_CODBANCO              IN NUMBER,
        PS_CODMOEDA              IN VARCHAR2,
        PS_NUMTRANSCENTROCUSTO   IN VARCHAR2,
        PS_DATAINTEGRACAOAUTO    IN DATE,
        PN_CODPARCEIRO           IN NUMBER,
        PS_TIPOPARCEIRO          IN VARCHAR2,
        PN_CODGRUPOBEM           IN NUMBER,
        PN_CHAVEGESTAO           IN NUMBER,
        PN_CHAVEGESTAOAUX        IN VARCHAR2,
        PS_FORMULA               IN VARCHAR2,
        PS_CONTA                 IN VARCHAR2,
        PS_TIPOMOVIMENTACAO      IN VARCHAR2,
        PS_TABELA                IN VARCHAR2,
        PS_REGRATOTALIZA         IN VARCHAR2)
    IS
    BEGIN
        INSERT INTO PCLANCINTERMEDIARIA (CODFILIAL,
                                         NUMTRANSLANCTO,
                                         NUMSEQ,
                                         DATALANCTO,
                                         DOCUMENTO,
                                         CODHISTORICO,
                                         HISTORICO_COMPL,
                                         CODPLANOCONTA,
                                         CODREDUZIDO_PC,
                                         NATUREZA,
                                         VALOR,
                                         NUMLOTECONT,
                                         CODREGRA,
                                         OPERACAO,
                                         NUMTRANSOPERACAO,
                                         INCONSISTENCIA,
                                         STATUS,
                                         DATAINTEGRACAO,
                                         CFOP,
                                         CODBANCO,
                                         CODMOEDA,
                                         NUMTRANSCENTROCUSTO,
                                         DATAINTEGRACAOAUTO,
                                         CODPARCEIRO,
                                         TIPOPARCEIRO,
                                         CODGRUPOBEM,
                                         CHAVEGESTAO,
                                         CHAVEGESTAOAUX,
                                         FORMULA,
                                         CONTA,
                                         TIPOMOVIMENTACAO,
                                         TABELAGESTAO,
                                         REGRATOTALIZA)
             VALUES (PS_CODFILIAL,
                     PN_NUMTRANSLANCTO,
                     PN_NUMSEQ,
                     TRUNC (PD_DATALANCTO),
                     PS_DOCUMENTO,
                     PN_CODHISTORICO,
                     PS_HISTORICO_COMPL,
                     PN_CODPLANOCONTA,
                     PS_CODREDUZIDO_PC,
                     PS_NATUREZA,
                     PN_VALOR,
                     0,
                     PN_CODREGRA,
                     PS_OPERACAO,
                     PN_NUMTRANSOPERACAO,
                     PS_INCONSISTENCIA,
                     PS_STATUS,
                     TRUNC (PD_DATAINTEGRACAO),
                     PN_CFOP,
                     PN_CODBANCO,
                     PS_CODMOEDA,
                     PS_NUMTRANSCENTROCUSTO,
                     PS_DATAINTEGRACAOAUTO,
                     PN_CODPARCEIRO,
                     PS_TIPOPARCEIRO,
                     PN_CODGRUPOBEM,
                     PN_CHAVEGESTAO,
                     PN_CHAVEGESTAOAUX,
                     PS_FORMULA,
                     SUBSTR (PS_CONTA, 0, 20),
                     PS_TIPOMOVIMENTACAO,
                     PS_TABELA,
                     PS_REGRATOTALIZA);
    END;

    /****************************************************************************
      CENTRO CUSTO - PROCEDURE PARA GRAVAR OS DADOS DA TABELA INTERMEDIÁRIA CENTRO CUSTO
    *****************************************************************************/
    PROCEDURE P_GRAVA_PCINTER_CENTROCUSTO (
        PS_RECNUM_CENTROCUSTO        IN VARCHAR2,
        PS_NUMTRANS_CENTROCUSTO      IN VARCHAR2,
        PN_CODREGRA                  IN NUMBER,
        PD_DATAINTEGRACAO            IN DATE,
        PB_USARFATOR                 IN BOOLEAN DEFAULT FALSE,
        PN_VALORLANCAMENTO           IN NUMBER DEFAULT 0,
        PN_NUMTRANSLANCTO            IN NUMBER DEFAULT 0,
        PS_AGRUPAMENTO               IN VARCHAR2,
        PN_PERCENTUAL_RATEIO_CONTA   IN NUMBER)
    IS
        CURSOR_CENTRO_CUSTO       SYS_REFCURSOR;
        VN_TOTAL_LANCAMENTO       NUMBER;
        VN_TOTAL_CENTROCUSTO      NUMBER;
        VN_FATOR_CENTRO_CUSTO     NUMBER;
        VN_VALOR_RATEIO           NUMBER;
        VN_PERC_RATEIO            NUMBER;
        VN_PERC_TOTAL_RATEIO      NUMBER;
        VN_QTD_REGISTROS          NUMBER;
        VN_QTD_TOTAL_REGISTROS    NUMBER;
        VN_RECNUM_ANTERIOR        NUMBER;
        VS_SQL_CENTRO_CUSTO       VARCHAR2 (2000);

        V_VALOR_CC_RATEIO_CONTA   NUMBER := 0;
    BEGIN
        VN_QTD_REGISTROS := 0;
        VN_QTD_TOTAL_REGISTROS := 0;
        VN_PERC_TOTAL_RATEIO := 0;
        VN_RECNUM_ANTERIOR := 0;
        V_VALOR_CC_RATEIO_CONTA := 1;

        IF PN_PERCENTUAL_RATEIO_CONTA > 0
        THEN
            VS_SQL_CENTRO_CUSTO :=
                   'SELECT TRIM(CODFILIAL) CODFILIAL,
                                     PERCRATEIO,
                                     SUM(VALOR)  VALOR,
                                     RECNUM,
                                     CODIGOCENTROCUSTO
                                FROM PCRATEIOCENTROCUSTO
                               WHERE RECNUM IN ( '
                || PS_RECNUM_CENTROCUSTO
                || ')
                   AND PERCRATCONTREF = '
                || TO_CHAR (PN_PERCENTUAL_RATEIO_CONTA)
                || '
                              --  AND PERCRATCONTREF IS NULL
                               GROUP BY TRIM(CODFILIAL),
                                        CODIGOCENTROCUSTO,
                                        PERCRATEIO,
                                        RECNUM
                               ORDER BY RECNUM,
                                        PERCRATEIO,
                                        VALOR,
                                        CODIGOCENTROCUSTO';
        ELSE
            VS_SQL_CENTRO_CUSTO :=
                   'SELECT TRIM(CODFILIAL) CODFILIAL,
                                     PERCRATEIO,
                                     SUM(VALOR) VALOR,
                                     RECNUM,
                                     CODIGOCENTROCUSTO
                                FROM PCRATEIOCENTROCUSTO
                               WHERE RECNUM IN ( '
                || PS_RECNUM_CENTROCUSTO
                || ')
                                
                               GROUP BY TRIM(CODFILIAL),
                                        CODIGOCENTROCUSTO,
                                        PERCRATEIO,
                                        RECNUM
                               ORDER BY RECNUM,
                                        PERCRATEIO,
                                        VALOR,
                                        CODIGOCENTROCUSTO';
        END IF;



        IF PS_RECNUM_CENTROCUSTO IS NOT NULL
        THEN
            SELECT SUM (L.VALOR)
              INTO VN_TOTAL_LANCAMENTO
              FROM PCLANCINTERMEDIARIA L
             WHERE     L.NUMTRANSCENTROCUSTO = PS_NUMTRANS_CENTROCUSTO
                   -- Adicionados os dois campos para forçar o indice, evitando full scan
                   AND L.CODREGRA = PN_CODREGRA
                   AND L.DATAINTEGRACAO = PD_DATAINTEGRACAO;

            EXECUTE IMMEDIATE
                'SELECT COUNT(*) FROM (' || VS_SQL_CENTRO_CUSTO || ')'
                INTO VN_QTD_TOTAL_REGISTROS;

            IF PN_VALORLANCAMENTO = 0
            THEN
                OPEN CURSOR_CENTRO_CUSTO FOR VS_SQL_CENTRO_CUSTO;

                LOOP
                    FETCH CURSOR_CENTRO_CUSTO INTO CONSULTA_CENTRO_CUSTO;

                    EXIT WHEN CURSOR_CENTRO_CUSTO%NOTFOUND;

                    /* BEGIN
                         SELECT MAX(PERCRATCONTREF) / 100
                           INTO V_VALOR_CC_RATEIO_CONTA
                           FROM PCRATEIOCENTROCUSTO R
                          WHERE R.RECNUM = PS_RECNUM_CENTROCUSTO
                          AND R.PERCRATCONTREF IS NOT NULL
                          AND R.LANCIMPRETIDO = 'S'
                          ;
                     EXCEPTION
                       WHEN OTHERS THEN
                          V_VALOR_CC_RATEIO_CONTA := 1;
                     END; */

                    IF CONSULTA_CENTRO_CUSTO.VALOR <> 0
                    THEN
                        --2140.042116.2017 (AJUSTES PARA FATO GERADOR 1, 9)

                        IF VN_RECNUM_ANTERIOR <> CONSULTA_CENTRO_CUSTO.RECNUM
                        THEN
                            VN_QTD_REGISTROS := 0;
                            VN_PERC_TOTAL_RATEIO := 100;

                            EXECUTE IMMEDIATE
                                   'SELECT COUNT(*) FROM ('
                                || VS_SQL_CENTRO_CUSTO
                                || ') WHERE  RECNUM = '
                                || TO_CHAR (CONSULTA_CENTRO_CUSTO.RECNUM)
                                INTO VN_QTD_TOTAL_REGISTROS;
                        END IF;

                        VN_QTD_REGISTROS := VN_QTD_REGISTROS + 1;

                        IF PB_USARFATOR
                        THEN
                            EXECUTE IMMEDIATE
                                   'SELECT SUM(VALOR) FROM PCRATEIOCENTROCUSTO WHERE ((PERCRATCONTREF IS NULL) OR (PERCRATCONTREF = 0)) AND RECNUM IN('
                                || PS_RECNUM_CENTROCUSTO
                                || ')'
                                INTO VN_TOTAL_CENTROCUSTO;

                            VN_FATOR_CENTRO_CUSTO :=
                                LEAST (
                                      VN_TOTAL_LANCAMENTO
                                    / VN_TOTAL_CENTROCUSTO,
                                    1);
                        ELSE
                            VN_FATOR_CENTRO_CUSTO := 1;
                        END IF;

                        VN_VALOR_RATEIO :=
                              VN_FATOR_CENTRO_CUSTO
                            * CONSULTA_CENTRO_CUSTO.VALOR
                            * V_VALOR_CC_RATEIO_CONTA;
                        --  VN_PERC_RATEIO        := round(((VN_VALOR_RATEIO / VN_TOTAL_LANCAMENTO) * 100),2);
                        VN_PERC_RATEIO :=
                              CONSULTA_CENTRO_CUSTO.PERCRATEIO
                            * V_VALOR_CC_RATEIO_CONTA;

                        VN_PERC_TOTAL_RATEIO :=
                            ABS (VN_PERC_TOTAL_RATEIO) - ABS (VN_PERC_RATEIO);

                        IF VN_QTD_REGISTROS = VN_QTD_TOTAL_REGISTROS
                        THEN
                            IF (VN_PERC_RATEIO <> 100)
                            THEN
                                IF (VN_PERC_TOTAL_RATEIO > 0)
                                THEN
                                    IF (VN_PERC_RATEIO > 0)
                                    THEN
                                        VN_PERC_RATEIO :=
                                              VN_PERC_RATEIO
                                            + ABS (VN_PERC_TOTAL_RATEIO);
                                    ELSE
                                        VN_PERC_RATEIO :=
                                              VN_PERC_RATEIO
                                            - ABS (VN_PERC_TOTAL_RATEIO);
                                    END IF;
                                ELSE
                                    IF (VN_PERC_RATEIO > 0)
                                    THEN
                                        VN_PERC_RATEIO :=
                                              VN_PERC_RATEIO
                                            - ABS (VN_PERC_TOTAL_RATEIO);
                                    ELSE
                                        VN_PERC_RATEIO :=
                                              VN_PERC_RATEIO
                                            + ABS (VN_PERC_TOTAL_RATEIO);
                                    END IF;
                                END IF;
                            END IF;
                        END IF;

                        IF ABS (VN_PERC_RATEIO) > 100
                        THEN
                            V_SQLERRO :=
                                   'O recnum '''
                                || PS_RECNUM_CENTROCUSTO
                                || ''' esta com uma porcentagem de rateio inválida!';
                            RAISE_APPLICATION_ERROR (-20000, V_SQLERRO);
                        ELSE
                            INSERT INTO PCLANCINTERMEDIARIACC (
                                            NUMTRANSCENTROCUSTO,
                                            CODFILIAL,
                                            CODIGOCENTROCUSTO,
                                            PERCRATEIO,
                                            VALOR,
                                            NUMTRANSLANCTO,
                                            AGRUPALANCAMENTO)
                                     VALUES (
                                                PS_NUMTRANS_CENTROCUSTO,
                                                CONSULTA_CENTRO_CUSTO.CODFILIAL,
                                                CONSULTA_CENTRO_CUSTO.CODIGOCENTROCUSTO,
                                                VN_PERC_RATEIO,
                                                ABS (VN_VALOR_RATEIO),
                                                PN_NUMTRANSLANCTO,
                                                PS_AGRUPAMENTO);
                        END IF;

                        VN_RECNUM_ANTERIOR := CONSULTA_CENTRO_CUSTO.RECNUM;
                    END IF;     --FIM IF CONSULTA_CENTRO_CUSTO.VALOR <> 0 THEN
                END LOOP;
            ELSE
                OPEN CURSOR_CENTRO_CUSTO FOR
                    'SELECT TRIM(CODFILIAL) CODFILIAL,
                                  --ROUND(PERCRATEIO,2) PERCRATEIO,
                  PERCRATEIO,
                                     (VALOR) VALOR,
                               0 RECNUM,
                                     CODIGOCENTROCUSTO
                              FROM PCRATEIOCENTROCUSTO
                        WHERE RECNUM =  ' || PS_RECNUM_CENTROCUSTO;

                LOOP
                    FETCH CURSOR_CENTRO_CUSTO INTO CONSULTA_CENTRO_CUSTO;

                    EXIT WHEN CURSOR_CENTRO_CUSTO%NOTFOUND;

                    INSERT INTO PCLANCINTERMEDIARIACC (NUMTRANSCENTROCUSTO,
                                                       CODFILIAL,
                                                       CODIGOCENTROCUSTO,
                                                       PERCRATEIO,
                                                       VALOR,
                                                       NUMTRANSLANCTO,
                                                       AGRUPALANCAMENTO)
                             VALUES (
                                        PS_NUMTRANS_CENTROCUSTO,
                                        CONSULTA_CENTRO_CUSTO.CODFILIAL,
                                        CONSULTA_CENTRO_CUSTO.CODIGOCENTROCUSTO,
                                        CONSULTA_CENTRO_CUSTO.PERCRATEIO,
                                        ABS (
                                            (  CONSULTA_CENTRO_CUSTO.PERCRATEIO
                                             * PN_VALORLANCAMENTO
                                             / 100)),
                                        PN_NUMTRANSLANCTO,
                                        PS_AGRUPAMENTO);
                END LOOP;
            END IF;
        END IF;
    END;

    /****************************************************************************
      FUNÇÃO QUE GERA O NUMTRANSLANCTO DA TABELA PCLANCINTERMEDIARIA
    *****************************************************************************/
    FUNCTION F_GERA_NUM_TRANS_LANCTO
        RETURN NUMBER
    IS
        INUMTRANSLANCTO   NUMBER;
    BEGIN
        SELECT DFSEQ_PCLANCINTERMEDIARIA.NEXTVAL AS SEQUENCIA
          INTO INUMTRANSLANCTO
          FROM DUAL;

        RETURN INUMTRANSLANCTO;
    END;


    /****************************************************************************
      PROCEDURE PARA GRAVAÇÃO DOS VALORES TOTALIZADOS
    *****************************************************************************/
    PROCEDURE P_GRAVAR_ITENS_TOTALIZADOS (ITENS            IN TABELAVALORES,
                                          PCODREGRA        IN NUMBER,
                                          PCODPLANOCONTA   IN NUMBER)
    IS
        VN_POSICAO   NUMBER;
    BEGIN
        FOR VN_POSICAO IN 1 .. ITENS.COUNT
        LOOP
            IF ITENS (VN_POSICAO).NATUREZA = 'D'
            THEN
                IF ITENS (VN_POSICAO).TOTALDEBITO > 0
                THEN
                    VS_NATUREZA := 'D';
                    VN_VALORLANCTO :=
                          NVL (ITENS (VN_POSICAO).TOTALDEBITO, 0)
                        - NVL (ITENS (VN_POSICAO).TOTALCREDITO, 0);
                ELSE
                    VS_NATUREZA := 'C';
                    VN_VALORLANCTO :=
                        NVL (ITENS (VN_POSICAO).TOTALCREDITO, 0);
                END IF;
            ELSE
                IF ITENS (VN_POSICAO).TOTALCREDITO > 0
                THEN
                    VS_NATUREZA := 'C';
                    VN_VALORLANCTO :=
                          NVL (ITENS (VN_POSICAO).TOTALCREDITO, 0)
                        - NVL (ITENS (VN_POSICAO).TOTALDEBITO, 0);
                ELSE
                    VS_NATUREZA := 'D';
                    VN_VALORLANCTO := NVL (ITENS (VN_POSICAO).TOTALDEBITO, 0);
                END IF;
            END IF;

            VN_NUMSEQ := VN_NUMSEQ + 1;

            P_GRAVA_DADOS_TABINTERMEDIARIA (
                ITENS (VN_POSICAO).CODFILIAL,
                ITENS (VN_POSICAO).NUMTRANSACAO,
                VN_NUMSEQ,
                ITENS (VN_POSICAO).DATAINTEGRACAO,
                ITENS (VN_POSICAO).DOCUMENTO,
                ITENS (VN_POSICAO).CODHISTORICO,
                ITENS (VN_POSICAO).HISTORICOCOMPLE,
                PCODPLANOCONTA,
                ITENS (VN_POSICAO).CONTA,
                VS_NATUREZA,
                VN_VALORLANCTO,
                PCODREGRA,
                '',
                ITENS (VN_POSICAO).NUMTRANSOPERACAO,
                '0',
                'P',
                ITENS (VN_POSICAO).DATAINTEGRACAO,
                ITENS (VN_POSICAO).CFOP,
                ITENS (VN_POSICAO).CODBANCO,
                ITENS (VN_POSICAO).CODMOEDA,
                ITENS (VN_POSICAO).NUMTRANSCENTROCUSTO,
                TRUNC (SYSDATE),
                ITENS (VN_POSICAO).CODPARCEIRO,
                ITENS (VN_POSICAO).TIPOPARCEIRO,
                ITENS (VN_POSICAO).CODGRUPOBEM,
                ITENS (VN_POSICAO).CHAVEGESTAO,
                ITENS (VN_POSICAO).CHAVEGESTAOAUX,
                ITENS (VN_POSICAO).FORMULA,
                ITENS (VN_POSICAO).CONTAVARIAVEL,
                ITENS (VN_POSICAO).TIPOMOVIMENTACAO,
                ITENS (VN_POSICAO).TABELAGESTAO,
                'S');
        END LOOP;
    END;

    FUNCTION F_RETORNA_NUMTRANS_CENTROCUSTO
        RETURN VARCHAR2
    IS
        VS_NUMTRANSLANCTO_CENTROCUSTO   NUMBER;
    BEGIN
        SELECT DFSEQ_PCLANCINTERMEDIARIACC.NEXTVAL AS SEQUENCIA
          INTO VS_NUMTRANSLANCTO_CENTROCUSTO
          FROM DUAL;

        RETURN VS_NUMTRANSLANCTO_CENTROCUSTO;
    END;

    /****************************************************************************
     FUNÇÃO QUE PEGA O CGC DAS FILIAIS LANÇADAS
   *****************************************************************************/
    FUNCTION F_CGCFILIAL (PS_CODFILIAL IN VARCHAR2)
        RETURN VARCHAR2
    IS
        VS_CGC   VARCHAR2 (8);
    BEGIN
        BEGIN
            SELECT SUBSTR (
                       REPLACE (REPLACE (REPLACE (CGC, '/', ''), '.', ''),
                                '-',
                                ''),
                       1,
                       8)
                       AS CGCFILIAL
              INTO VS_CGC
              FROM PCFILIAL
             WHERE CODIGO = PS_CODFILIAL;
        EXCEPTION
            WHEN OTHERS
            THEN
                VS_CGC := '';
        END;

        RETURN VS_CGC;
    END;

    /****************************************************************************
      PROCEDURE PARA ARMAZENAR AS CONTAS A DÉBITO E CRÉDITO DO LANÇAMENTO
    *****************************************************************************/
    PROCEDURE P_ARMAZENA_CONTAS_FILIAIS_LANC (
        PS_CODREDUZIDO   IN VARCHAR2,
        PS_NATUREZA      IN VARCHAR2,
        PS_CODFILIAL     IN VARCHAR2,
        FILIAIS          IN TABELAFILIAISLANCTO)
    IS
        VN_POSIGUAIS    NUMBER;
        VN_POSFILIAIS   NUMBER;
        VS_CONTAIGUAL   VARCHAR2 (1);
        VS_CGCIGUAL     VARCHAR2 (1);
        VS_CGC          VARCHAR2 (8);
    BEGIN
        VS_CONTAIGUAL := 'N';
        VS_CGCIGUAL := 'N';

        --ARMAZENA CONTAS A DÉBITO JÁ LANÇADAS
        IF PS_NATUREZA = 'D'
        THEN
            FOR VN_POSIGUAIS IN 1 .. CONTASDEBLANCTO.COUNT
            LOOP
                IF CONTASDEBLANCTO (VN_POSIGUAIS) = PS_CODREDUZIDO
                THEN
                    VS_CONTAIGUAL := 'S';

                    EXIT;
                END IF;
            END LOOP;

            IF VS_CONTAIGUAL = 'N'
            THEN
                CONTASDEBLANCTO (CONTASDEBLANCTO.COUNT) := PS_CODREDUZIDO;
            END IF;
        ELSE
            --ARMAZENA CONTAS A CRÉDITO JÁ LANÇADAS
            FOR VN_POSIGUAIS IN 1 .. CONTASCRELANCTO.COUNT
            LOOP
                IF CONTASCRELANCTO (VN_POSIGUAIS) = PS_CODREDUZIDO
                THEN
                    VS_CONTAIGUAL := 'S';
                    EXIT;
                END IF;
            END LOOP;

            IF VS_CONTAIGUAL = 'N'
            THEN
                CONTASCRELANCTO (CONTASCRELANCTO.COUNT) := PS_CODREDUZIDO;
            END IF;
        END IF;

        --ARMAZENA FILIAIS JÁ LANÇADAS
        FOR VN_POSFILIAIS IN 1 .. FILIAIS.COUNT
        LOOP
            IF FILIAIS (VN_POSFILIAIS).CODFILIAL = PS_CODFILIAL
            THEN
                VS_CGC := FILIAIS (VN_POSFILIAIS).CGCFILIAL;

                FOR VN_POSIGUAIS IN 1 .. CGCSLANCTO.COUNT
                LOOP
                    IF CGCSLANCTO (VN_POSIGUAIS) =
                       FILIAIS (VN_POSFILIAIS).CGCFILIAL
                    THEN
                        VS_CGCIGUAL := 'S';
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        END LOOP;

        IF VS_CGCIGUAL = 'N'
        THEN
            CGCSLANCTO.EXTEND;
            CGCSLANCTO (CGCSLANCTO.COUNT) := VS_CGC;
        END IF;
    END;

    PROCEDURE P_VERIFICAR_CONTA_DMPLDLPA (PCODFILIAL       IN VARCHAR2,
                                          PCODREGRA        IN NUMERIC,
                                          PDTINICIO        IN DATE,
                                          PDTFINAL         IN DATE,
                                          PCODPLANOCONTA   IN NUMERIC,
                                          PCONSOLIDAR      IN VARCHAR2)
    IS
        TYPE TIPO_LANC IS RECORD
        (
            NUMTRANSLANCTO PCLANCINTERMEDIARIA.NUMTRANSLANCTO%TYPE
        );

        LANC          TIPO_LANC;

        CURSOR_LANC   SYS_REFCURSOR;
        VS_SQL        VARCHAR2 (4000);
    BEGIN
        VS_SQL :=
            'WITH
        CONTAS AS (
        SELECT CODREDUZIDO_PC
          FROM PCMODELOPC
         WHERE CODPLANOCONTA = :PCODPLANOCONTA
           AND (PCMODELOPC.COMPOE_DMPL = ''S'' OR PCMODELOPC.COMPOE_DLPA = ''S'')
      )
      , HISTORICO AS (
        SELECT CODHISTORICO
          FROM PCHISTORICO H
         WHERE NVL(H.COMPOE_DMPL_DLPA,''N'') = ''N''
      )
      , FILIAIS AS (
        SELECT CODFILIAL
        FROM PCCONFFILIAL
        WHERE DECODE(:CONSOLIDAR, ''S'', TO_CHAR(CODGRUPOFILIAL), CODFILIAL) IN ( :CODFILIAL )
          AND ANO = EXTRACT(YEAR FROM TO_DATE(:PDATAFINAL))
      )
      SELECT NUMTRANSLANCTO
      FROM
        PCLANCINTERMEDIARIA LI,
        CONTAS C,
        HISTORICO H,
        FILIAIS FI,
        PCREGRACONTABIL R
      WHERE LI.CODREGRA       = R.CODREGRA
        AND LI.CODPLANOCONTA  = R.CODPLANOCONTA
        AND LI.CODREDUZIDO_PC = C.CODREDUZIDO_PC
        AND LI.CODHISTORICO   = H.CODHISTORICO
        AND LI.CODFILIAL IN ( FI.CODFILIAL )
        AND LI.STATUS         = ''P''
        AND LI.INCONSISTENCIA IN ( ''0'', ''6'' )
        AND LI.CODREGRA       = :PCODREGRA
        AND LI.DATAINTEGRACAO BETWEEN :PDATAINICIAL AND :PDATAFINAL ';

        PKG_CTBFUNCOESCONTEIS.TRATARMULTIFILIAL (PCODFILIAL,
                                                 ':CODFILIAL',
                                                 FALSE,
                                                 VS_SQL);

        OPEN CURSOR_LANC FOR VS_SQL
            USING PCODPLANOCONTA,
                  PCONSOLIDAR,
                  PDTFINAL,
                  PCODREGRA,
                  PDTINICIO,
                  PDTFINAL;

        LOOP
            FETCH CURSOR_LANC INTO LANC;

            EXIT WHEN CURSOR_LANC%NOTFOUND;

            PKG_INTEGRACAOCONTABIL.P_PASSA_INCONSISTENCIA_LANC (
                LANC.NUMTRANSLANCTO,
                '10',
                PDTINICIO,
                PDTFINAL);
        END LOOP;

        CLOSE CURSOR_LANC;
    END;


    /****************************************************************************
      PROCEDURE QUE VERIFICA SE EXISTE INCONSISTÊNCIAS NO LANÇAMENTO(S)
    *****************************************************************************/
    PROCEDURE P_VERIFICA_INCONSISTENCIAS (
        PN_NUMTRANSLANCTO        IN NUMBER,
        PD_DATALANCTO            IN DATE,
        PS_TEMCONTAINEXISTENTE   IN VARCHAR2,
        PN_TOTDEBITO             IN NUMBER,
        PN_TOTCREDITO            IN NUMBER,
        PS_MULTIFILIAL           IN VARCHAR2           -- O VALOR PADRÃO É 'N'
                                            --,PN_CODFATOGERADOR      IN NUMBER  -- O CÓDIGO DO FATO GERADOR
                                            )
    IS
        VN_POSCONTADEBITO           NUMBER;
        VN_POSCONTACREDITO          NUMBER;
        VN_POSCONTATRANSITORIA      NUMBER;
        VB_LANCAMENTONAMESMACONTA   VARCHAR2 (1);
        VB_EH_CONTA_TRANSITORIA     BOOLEAN;
    BEGIN
        --Gera inconsistência caso lançamento necessite de ser contabilizado consolidado e não tenha sido.
        IF PS_MULTIFILIAL = 'S'
        THEN
            P_PASSA_INCONSISTENCIA_LANC (PN_NUMTRANSLANCTO,
                                         '8',
                                         PD_DATALANCTO,
                                         PD_DATALANCTO);
        -- Gera inconsitência para:
        -- Contas inexistentes -> S
        -- Conta não existe no plano de contas do exercício -> I
        -- Conta sintética -> X
        ELSIF PS_TEMCONTAINEXISTENTE = 'X'
        THEN
            P_PASSA_INCONSISTENCIA_LANC (PN_NUMTRANSLANCTO,
                                         '11',
                                         PD_DATALANCTO,
                                         PD_DATALANCTO);
        ELSIF (PS_TEMCONTAINEXISTENTE = 'I')
        THEN
            -- conta não existe no banco de dados
            P_PASSA_INCONSISTENCIA_LANC (PN_NUMTRANSLANCTO,
                                         '2',
                                         PD_DATALANCTO,
                                         PD_DATALANCTO);
        -- Conta não existe no plano de contas do exercício
        ELSIF (    (PS_TEMCONTAINEXISTENTE = 'S')
               AND (ROUND (PN_TOTDEBITO, 2) <> ROUND (PN_TOTCREDITO, 2)))
        THEN
            P_PASSA_INCONSISTENCIA_LANC (PN_NUMTRANSLANCTO,
                                         '9',
                                         PD_DATALANCTO,
                                         PD_DATALANCTO);
        --Gera inconsistência para lançamentos sem data
        ELSIF PD_DATALANCTO IS NULL
        THEN
            P_PASSA_INCONSISTENCIA_LANC (PN_NUMTRANSLANCTO,
                                         '5',
                                         PD_DATALANCTO,
                                         PD_DATALANCTO);
        --Gera inconsistência caso os valores sejam diferentes
        ELSIF    (ROUND (PN_TOTDEBITO, 2) - ROUND (PN_TOTCREDITO, 2) > 0.001)
              OR (ROUND (PN_TOTCREDITO, 2) - ROUND (PN_TOTDEBITO, 2) > 0.001)
        THEN
            P_PASSA_INCONSISTENCIA_LANC (PN_NUMTRANSLANCTO,
                                         '1',
                                         PD_DATALANCTO,
                                         PD_DATALANCTO);
        --Testa cgcs lançados para saber se empresas são do mesmo grupo de CNPJ
        ELSIF CGCSLANCTO.COUNT > 1
        THEN
            P_PASSA_INCONSISTENCIA_LANC (PN_NUMTRANSLANCTO,
                                         '7',
                                         PD_DATALANCTO,
                                         PD_DATALANCTO);
        -- =============================================================================
        -- PS_TIPOINCONSISTENCIA = 10
        -- Este tipo de inconsistência é tratada na procedure P_CTBINTEGRACAOCONTABIL
        -- Devido a performace
        -- =============================================================================

        ELSE
            --Testa contas lançadas para saber se conta a débito foi igual a crédito
            VB_LANCAMENTONAMESMACONTA := 'N';

            FOR VN_POSCONTADEBITO IN 1 .. CONTASDEBLANCTO.COUNT
            LOOP
                VB_EH_CONTA_TRANSITORIA := FALSE;

                FOR VN_POSCONTATRANSITORIA IN 1 ..
                                              VS_LISTAS_TRANSOTORIAS.COUNT
                LOOP
                    IF CONTASDEBLANCTO (VN_POSCONTADEBITO) =
                       VS_LISTAS_TRANSOTORIAS (VN_POSCONTATRANSITORIA)
                    THEN
                        VB_EH_CONTA_TRANSITORIA := TRUE;
                        EXIT;
                    END IF;
                END LOOP;

                IF NOT VB_EH_CONTA_TRANSITORIA
                THEN
                    FOR VN_POSCONTACREDITO IN 1 .. CONTASCRELANCTO.COUNT
                    LOOP
                        IF CONTASDEBLANCTO (VN_POSCONTADEBITO) =
                           CONTASCRELANCTO (VN_POSCONTACREDITO)
                        THEN
                            --Só deve passar a inconsistência de contas iguais existam débitos e créditos no mesmo valor para a mesma conta
                            BEGIN
                                SELECT 'S'
                                  INTO VB_LANCAMENTONAMESMACONTA
                                  FROM (  SELECT (SUM (
                                                      CASE I.NATUREZA
                                                          WHEN 'D' THEN I.VALOR
                                                          ELSE 0
                                                      END))
                                                     VALORDEBITO,
                                                 (SUM (
                                                      CASE I.NATUREZA
                                                          WHEN 'C' THEN I.VALOR
                                                          ELSE 0
                                                      END))
                                                     VALORCREDITO
                                            FROM PCLANCINTERMEDIARIA I
                                           WHERE     I.NUMTRANSLANCTO =
                                                     PN_NUMTRANSLANCTO
                                                 AND I.CODREDUZIDO_PC IN
                                                         (CONTASDEBLANCTO (
                                                              VN_POSCONTADEBITO),
                                                          CONTASCRELANCTO (
                                                              VN_POSCONTACREDITO))
                                                 AND I.DATALANCTO =
                                                     PD_DATALANCTO
                                        GROUP BY I.CODPLANOCONTA,
                                                 I.CODREDUZIDO_PC) S
                                 WHERE S.VALORDEBITO = S.VALORCREDITO;

                                P_PASSA_INCONSISTENCIA_LANC (
                                    PN_NUMTRANSLANCTO,
                                    '6',
                                    PD_DATALANCTO,
                                    PD_DATALANCTO);
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    VB_LANCAMENTONAMESMACONTA := 'N';
                            END;

                            IF VB_LANCAMENTONAMESMACONTA = 'S'
                            THEN
                                EXIT;
                            END IF;
                        END IF;

                        IF VB_LANCAMENTONAMESMACONTA = 'S'
                        THEN
                            EXIT;
                        END IF;
                    END LOOP;
                END IF;
            END LOOP;
        END IF;
    END;


    FUNCTION F_LANCTO_TEM_CENTROCUSTO (
        PS_CODREDUZIDO         IN VARCHAR2,
        PS_CODCONTAGERENCIAL   IN VARCHAR2,
        PS_CODFATOGERADOR      IN NUMBER,
        PS_NUMTRANSACAO        IN NUMBER DEFAULT 0,
        PS_CONTASPAGAR631      IN NUMBER DEFAULT 0,
        PS_FORMULA             IN VARCHAR2 DEFAULT '0',
        PN_CODPLANOCONTA       IN NUMBER)
        RETURN VARCHAR2
    IS
        V_CODCONTACONTABIL   VARCHAR2 (12);
        V_NUMTRANSENT        NUMBER (12);
        V_USACENTROCUSTO     VARCHAR2 (2);
    BEGIN
        V_USACENTROCUSTO := '';

        BEGIN
            SELECT COALESCE (USACENTROCUSTO, 'N')
              INTO V_USACENTROCUSTO
              FROM PCMODELOPC
             WHERE     PCMODELOPC.CODREDUZIDO_PC = PS_CODREDUZIDO
                   AND PCMODELOPC.CODPLANOCONTA = PN_CODPLANOCONTA;
        EXCEPTION
            WHEN OTHERS
            THEN
                V_USACENTROCUSTO := 'N';
        END;

        IF V_USACENTROCUSTO = 'S'
        THEN
            BEGIN
                IF PS_CODFATOGERADOR = 3
                THEN
                    IF PS_CONTASPAGAR631 = 1
                    THEN
                        SELECT CONTACONTABIL
                          INTO V_CODCONTACONTABIL
                          FROM PCCONTA
                         WHERE CODCONTA = PS_CODCONTAGERENCIAL;
                    ELSE
                        SELECT CONTACONTABIL
                          INTO V_CODCONTACONTABIL
                          FROM PCCONTA, PCCONSUM
                         WHERE     CODCONTA = PS_CODCONTAGERENCIAL
                               AND (   PCCONTA.CODCONTA =
                                       PCCONSUM.CODCONTPAGJUR
                                    OR PCCONTA.CODCONTA =
                                       PCCONSUM.CODCONTDESCCONC);
                    END IF;
                ELSIF PS_CODFATOGERADOR = 1
                THEN
                    SELECT PCCONTA.CONTACONTABIL
                      INTO V_CODCONTACONTABIL
                      FROM PCCONTA, PCLANC
                     WHERE     PCCONTA.CODCONTA = PCLANC.CODCONTA
                           AND PCLANC.NUMTRANSENT = PS_NUMTRANSACAO
                           AND PCLANC.CODCONTA = PS_CODCONTAGERENCIAL
                           AND ROWNUM = 1;
                ELSIF PS_CODFATOGERADOR = 5
                THEN
                    SELECT NUMTRANSENT
                      INTO V_NUMTRANSENT
                      FROM PCDEVFORNEC
                     WHERE NUMTRANSVENDA = PS_NUMTRANSACAO AND ROWNUM = 1;

                    IF NVL (V_NUMTRANSENT, 0) > 0
                    THEN
                        SELECT PCCONTA.CONTACONTABIL
                          INTO V_CODCONTACONTABIL
                          FROM PCCONTA, PCLANC
                         WHERE     PCCONTA.CODCONTA = PCLANC.CODCONTA
                               AND PCLANC.NUMTRANSENT = V_NUMTRANSENT
                               AND ROWNUM = 1;
                    END IF;
                ELSE
                    BEGIN
                        SELECT CODREDUZIDO_PC
                          INTO V_CODCONTACONTABIL
                          FROM PCMODELOPC
                         WHERE     CODCONTAGER = PS_CODCONTAGERENCIAL
                               AND PCMODELOPC.CODPLANOCONTA =
                                   PN_CODPLANOCONTA;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            V_CODCONTACONTABIL := '';
                    END;
                END IF;

                IF V_CODCONTACONTABIL IS NULL
                THEN
                    BEGIN
                        SELECT CONTACONTABIL
                          INTO V_CODCONTACONTABIL
                          FROM PCCONTA
                         WHERE CODCONTA = PS_CODCONTAGERENCIAL;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            V_CODCONTACONTABIL := '';
                    END;
                END IF;

                IF V_CODCONTACONTABIL = PS_CODREDUZIDO
                THEN
                    V_USACENTROCUSTO := 'S';
                ELSE
                    V_USACENTROCUSTO := 'N';
                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    V_USACENTROCUSTO := 'N';
            END;
        END IF;

        RETURN V_USACENTROCUSTO;
    END;

    PROCEDURE CALCULAREXPRESSAO
    IS
        VN_POSICAO          NUMBER;
        FORMULAENCONTRADA   BOOLEAN;
    BEGIN
        VS_FORMULA := TRIM (REPLACE (VS_FORMULA, ' + 0 ', ''));
        VS_FORMULA := TRIM (REPLACE (VS_FORMULA, ' - 0 ', ''));
        VS_FORMULA := TRIM (REPLACE (VS_FORMULA, ',', '.'));

        IF    INSTR (VS_FORMULA, '+') <> 0
           OR INSTR (VS_FORMULA, '-') <> 0
           OR INSTR (VS_FORMULA, '*') <> 0
           OR INSTR (VS_FORMULA, '/') <> 0
           OR INSTR (VS_FORMULA, '(') <> 0
           OR INSTR (VS_FORMULA, ')') <> 0
        THEN
            FORMULAENCONTRADA := FALSE;

            FOR VN_POSICAO IN 1 .. LISTA_FORMULAS.COUNT
            LOOP
                IF LISTA_FORMULAS (VN_POSICAO).FORMULA = VS_FORMULA
                THEN
                    VN_VALORLANCTO := LISTA_FORMULAS (VN_POSICAO).VALOR;
                    FORMULAENCONTRADA := TRUE;
                    EXIT;
                END IF;
            END LOOP;

            IF NOT FORMULAENCONTRADA
            THEN
                EXECUTE IMMEDIATE 'SELECT ' || VS_FORMULA || ' FROM DUAL '
                    INTO VN_VALORLANCTO;

                LISTA_FORMULAS.EXTEND;
                LISTA_FORMULAS (LISTA_FORMULAS.COUNT).FORMULA := VS_FORMULA;
                LISTA_FORMULAS (LISTA_FORMULAS.COUNT).VALOR := VN_VALORLANCTO;
            END IF;
        ELSE
            BEGIN
                VALID_NUMBER (VS_FORMULA);
                VN_VALORLANCTO := TO_NUMBER (VS_FORMULA);
            EXCEPTION
                WHEN OTHERS
                THEN
                    VS_FORMULA := TRIM (REPLACE (VS_FORMULA, '.', ','));
                    VN_VALORLANCTO := TO_NUMBER (VS_FORMULA);
            END;
        END IF;
    END CALCULAREXPRESSAO;

    /****************************************************************************
      PROCEDURE PARA GERAÇÃO DE 1 - ENTRADAS
    *****************************************************************************/
    PROCEDURE P_DADOS_ENTRADAS (CURSOR_DADOS     IN     SYS_REFCURSOR,
                                PCODREGRA        IN     NUMBER,
                                PCODPLANOCONTA   IN     NUMBER,
                                RESULTADO           OUT VARCHAR2)
    IS
        TYPE CONSULTA_ENTRADAS IS RECORD
        (
            CODFILIAL PCNFBASEENT.CODFILIALNF%TYPE,
            DATAOPERACAO PCNFBASEENT.DTENTRADA%TYPE,
            DATAEMISSAONF PCNFBASEENT.DTEMISSAO%TYPE,
            VALORTOTAL PCNFBASEENT.VLDESDOBRADO%TYPE,
            VALORICMS PCNFBASEENT.VLICMS%TYPE,
            VALORPISCALCDI PCNFBASEENT.VLPISCALCDI%TYPE,
            VALORCOFINSCALCDI PCNFBASEENT.VLCOFINSCALCDI%TYPE,
            VALORFRETECONT PCNFBASEENT.VLFRETECONT%TYPE,
            VALORPIS PCNFBASEENT.VLPIS%TYPE,
            VALORCOFINS PCNFBASEENT.VLCOFINS%TYPE,
            VALORISENTAS PCNFBASEENT.VLISENTAS%TYPE,
            VALOROUTRAS PCNFBASEENT.VLOUTRAS%TYPE,
            VALORFRETE PCNFBASEENT.VLFRETE%TYPE,
            VALORST PCNFBASEENT.VLST%TYPE,
            VALORIPI PCNFBASEENT.VLIPI%TYPE,
            VALORIMPOSTOESTADUAL PCNFBASEENT.VLIMPESTADUAL%TYPE,
            VALORSTFORANF PCNFBASEENT.VLSTFORANF%TYPE,
            VALORISENTAS_DAPI PCNFBASEENT.VLISENTAS_DAPI%TYPE,
            VALORNAOTRIB_DAPI PCNFBASEENT.VLNAOTRIB_DAPI%TYPE,
            VALORSUSPENSAS_DAPI PCNFBASEENT.VLSUSPENSAS_DAPI%TYPE,
            VALORST_DAPI PCNFBASEENT.VLST_DAPI%TYPE,
            VALOROUTRAS_DAPI PCNFBASEENT.VLOUTRAS_DAPI%TYPE,
            VALORISENTASIPI PCNFBASEENT.VLISENTASIPI%TYPE,
            VALOROUTRASIPI PCNFBASEENT.VLOUTRASIPI%TYPE,
            VALORIRRF PCNFENT.VLIRRF%TYPE,
            VALORSESTSENAT PCNFENT.VLSESTSENAT%TYPE,
            VALORISS PCNFENT.VLISS%TYPE,
            VALORINSS PCNFENT.VLINSS%TYPE,
            VALORCSRF PCNFENT.VLCSRF%TYPE,
            VALORCREDPRESUMIDO PCNFBASEENT.VLCREDPRESUMIDO%TYPE,
            VALORFUNDOCOMBPOBREZA PCNFBASEENT.VLFCP%TYPE,
            VALORICMSDIFALIQPARTILHA PCNFBASEENT.VLICMSDIFALIQPART%TYPE,
            VALORSISCOMEX PCNFBASEENT.VLSISCOMEX%TYPE,
            VALORIMPORTACAO PCNFBASEENT.VLIMPORTACAO%TYPE,
            VALORCAPATAZIA PCNFBASEENT.VLCAPATAZIA%TYPE,
            VALORAFRMM PCNFBASEENT.VLAFRMM%TYPE,
            VALORADUANEIRA PCNFBASEENT.VLADUANEIRA%TYPE,
            VALOROUTRASDESPIMP PCNFBASEENT.VLOUTRASDESP%TYPE,
            VALORANTIDUMPING PCNFBASEENT.VLANTIDUMPING%TYPE,
            VALORSEGURO PCNFBASEENT.VLSEGURO%TYPE,
            VALOROUTROSCUSTOS PCNFBASEENT.VLOUTROSCUSTOSCUSTO%TYPE,
            VALOROUTROSCUSTOSFORANF PCNFBASEENT.VLOUTROSCUSTOS%TYPE,
            VALORICMSANTECIPADO PCNFBASEENT.VLICMSANTECIPADO%TYPE,
            VALORIMPPRODUTORRURAL PCNFBASEENT.VLIMPPRODUTORURAL%TYPE,
            VALORDIFALIQUOTA PCNFBASEENT.VLDIFALIQUOTA%TYPE,
            VALORCREDITO_CIAP PCNFBASEENT.VLCREDITO_CIAP%TYPE,
            VALORICMSUFDEST PCNFBASEENT.VLICMSUFDEST%TYPE,
            VALORICMSUFREM PCNFBASEENT.VLICMSUFREM%TYPE,
            VALORDESPFORANF PCNFBASEENT.VLDESPFORANF%TYPE,
            VALORFRETECONHEC PCNFBASEENT.VLFRETECONHEC%TYPE,
            TIPODESCARGA PCNFBASEENT.TIPODESCARGA%TYPE,
            NUMNOTANF PCNFBASEENT.NUMNOTA%TYPE,
            ESPECIENF PCNFBASEENT.ESPECIE%TYPE,
            SERIENF PCNFBASEENT.SERIE%TYPE,
            CODFISCALNF PCCFO.CODFISCAL%TYPE,
            CODFORNECNF PCNFBASEENT.CODFORNEC%TYPE,
            CONTAGERENCIAL PCNFBASEENT.CODCONT%TYPE,
            UFNF PCNFBASEENT.UF%TYPE,
            SITUACAOTRIBUTARIA PCNFBASEENT.SITTRIBUT%TYPE,
            TIPOOPERACAO PCNFBASEENT.TIPOCOMPRA%TYPE,
            FORNECEDORNF PCNFBASEENT.FORNECEDOR%TYPE,
            NUMTRANSOPERACAO PCNFBASEENT.NUMTRANSENT%TYPE,
            TIPOFRETE PCNFENT.TIPOFRETECIFFOB%TYPE,
            CODCONTAFORNECEDOR VARCHAR2 (12),
            CONTACONTABIL PCCONTA.CONTACONTABIL%TYPE,
            NOMECONTAGERENCIAL PCCONTA.CONTA%TYPE,
            TEMINTEGRACAO VARCHAR2 (1),
            NUMEROCONTRATO PCNFENT.NUMCONTRATO%TYPE,
            NUMNEGOCIACAO PCNFENT.NUMNEGOCIACAO%TYPE,
            NUMPEDPRINC PCNFENT.NUMPEDPRINC%TYPE,
            NUMDIIMPORTACAO PCNFENT.NUMDIIMPORTACAO%TYPE,
            VALORFCEP PCNFBASEENT.VLFECP%TYPE,
            VALORACRESCIMOFUNCEP PCNFBASEENT.VLACRESCIMOFUNCEP%TYPE,
            NUMINVOCE PCPEDIDO.NUMINVOCE%TYPE,
            NUMPROFORMA PCPEDIDO.NUMPROFORMA%TYPE,
            CODCONTADESP PCMODELOPC.CODREDUZIDO_PC%TYPE,
            VALORICMSBCR PCNFBASEENT.VLICMSBCR%TYPE,
            VALORSTBCR PCNFBASEENT.VLSTBCR%TYPE,
            VALORFECPSTGUIA PCNFBASEENT.VLFECPSTGUIA%TYPE
        );

        ITEM                          CONSULTA_ENTRADAS;
        ITENSREGRA                    CONSULTA_ITENS;

        CURSOR_ITENS                  SYS_REFCURSOR;

        VS_RECNUM_CENTROCUSTO         VARCHAR2 (12);
        VS_LISTA_RECNUM_CENTROCUSTO   VARCHAR2 (4000);

        VN_NUMTRANSENT_ANTERIOR       NUMBER (20);
        V_CONTA_ANTERIOR              VARCHAR2 (40) := '';

        FILIAIS_LANCADAS              TABELAFILIAISLANCTO;
        FILIAIS                       FILIAISLANCTO;
        VS_CONTA_EXISTE               VARCHAR2 (1);

        VN_CODFISCAL_ANTERIOR         NUMBER (8);

        VS_SITTRIBUT_ANTERIOR         VARCHAR2 (10);
    BEGIN
        LISTA_FORMULAS := TYPE_LISTA_FORMULAS ();

        FILIAIS_LANCADAS := TABELAFILIAISLANCTO ();

        VS_SEQGERADO := 'N';
        VS_FORMADTCONTABILIZACAO := '';
        VN_NUMTRANSACAO := 0;
        VS_DOCUMENTO := '';
        VS_TEMCONTAINEXISTENTE := 'N';

        --BUSCA DADOS DA REGRA
        SELECT FORMADTCONTABILIZACAO
          INTO VS_FORMADTCONTABILIZACAO
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        V_SQLERRO := 'ABRINDO ENTRADAS';

        --INICIA LAÇO DOS DADOS
        LOOP
            FETCH CURSOR_DADOS INTO ITEM;

            EXIT WHEN CURSOR_DADOS%NOTFOUND;

            IF (ITEM.TEMINTEGRACAO IS NULL) OR (ITEM.TEMINTEGRACAO = 'P')
            THEN
                --------------------------------------------------------------------
                --VERIFICA SE ALTEROU O NUMTRANSOPERACAO PARA FAZER GRAVAÇÃO E RE-INICIAR VARIÁVEIS
                IF (VN_NUMTRANSOPERACAO <> ITEM.NUMTRANSOPERACAO)
                THEN
                    VS_SEQGERADO := 'N';

                    IF (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                        AND (ITEM.TEMINTEGRACAO = 'P'))
                    THEN
                        P_EXCLUI_LANCINTERMEDIARIA_IND (
                            PCODREGRA,
                            ITEM.NUMTRANSOPERACAO,
                            ITEM.DATAOPERACAO);
                    END IF;

                    --VERIFICA SE JÁ PASSOU POR ALGUM REGISTRO PARA ATRIBUIR INCONSISTÊNCIAS
                    IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) >
                       0
                    THEN
                        ---------------------------------------------------------------------------------
                        V_SQLERRO :=
                            '1 - ENTRADAS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
                        ---------------------------------------------------------------------------------
                        P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                                    VD_DATALANCTO,
                                                    VS_TEMCONTAINEXISTENTE,
                                                    VN_TOTALDEBITO,
                                                    VN_TOTALCREDITO,
                                                    'N');
                    END IF;

                    VS_TEMCONTAINEXISTENTE := 'N';
                END IF;

                --------------------------------------------------------------------

                --GERA NOVO NUMTRANSLANCTO
                IF VS_SEQGERADO = 'N'
                THEN
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '1 - ENTRADAS: EXECUTANDO FUNÇÃO GERA_NUM_TRANS_LANCTO';
                    ---------------------------------------------------------------------------------
                    VN_NUMTRANSACAO := F_GERA_NUM_TRANS_LANCTO ();

                    VN_NUMSEQ := 0;
                    VN_TOTALCREDITO := 0;
                    VN_TOTALDEBITO := 0;
                    VS_SEQGERADO := 'S';
                    VS_NUMTRANSCENTROCUSTO := '';

                    CONTASDEBLANCTO := CONTAS_LANCADAS ();
                    CONTASCRELANCTO := CONTAS_LANCADAS ();
                    CGCSLANCTO := CGC_LANCADOS ();
                    VS_LISTAS_TRANSOTORIAS := CONTAS_LANCADAS ();

                    CONTASDEBLANCTO.EXTEND;
                    CONTASCRELANCTO.EXTEND;
                END IF;

                VD_DATALANCTO :=
                    F_RETORNA_DATA_LANCPROVISOES (1,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO);

                VD_DATAINTEGRACAO :=
                    F_RETORNA_DATA_LANCPROVISOES (1,
                                                  PCODREGRA,
                                                  DATA_INTEGRACAO,
                                                  ITEM.DATAOPERACAO);

                --LAÇO NOS ITENS DA REGRA CONTABIL
                OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL ()
                    USING PCODREGRA;

                LOOP
                    FETCH CURSOR_ITENS INTO ITENSREGRA;

                    EXIT WHEN CURSOR_ITENS%NOTFOUND;

                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '1 - ENTRADAS: ATRIBUINDO VALOR DO DOCUMENTO';
                    ---------------------------------------------------------------------------------
                    VS_DOCUMENTO := ITENSREGRA.DOCUMENTO;
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO',
                                 TO_CHAR (ITEM.DATAOPERACAO, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMNOTANF', ITEM.NUMNOTANF);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMTRANSOPERACAO',
                                 ITEM.NUMTRANSOPERACAO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'SITUACAOTRIBUTARIA',
                                 ITEM.SITUACAOTRIBUTARIA);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMEROCONTRATO',
                                 ITEM.NUMEROCONTRATO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMDIIMPORTACAO',
                                 ITEM.NUMDIIMPORTACAO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMINVOCE', ITEM.NUMINVOCE);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMPROFORMA',
                                 ITEM.NUMPROFORMA);


                    --FORMULA INFORMADA NO FILTRO--------------------------------------------------------
                    ---------------------------------------------------------------------------------
                    V_SQLERRO := '1 - ENTRADAS: ATRIBUINDO VALOR DA FÓRMULA';
                    ---------------------------------------------------------------------------------
                    VN_VALORLANCTO := 0;

                    VS_FORMULA := ITENSREGRA.FORMULAS || ' + 0 ';
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORTOTAL([^_[:alnum:]])',
                                        NVL (ITEM.VALORTOTAL, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORICMS([^_[:alnum:]])',
                                        NVL (ITEM.VALORICMS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORPIS([^_[:alnum:]])',
                                        NVL (ITEM.VALORPIS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORCOFINS([^_[:alnum:]])',
                                        NVL (ITEM.VALORCOFINS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORISENTAS_DAPI([^_[:alnum:]])',
                            NVL (ITEM.VALORISENTAS_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORISENTAS([^_[:alnum:]])',
                                        NVL (ITEM.VALORISENTAS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALOROUTRAS_DAPI([^_[:alnum:]])',
                            NVL (ITEM.VALOROUTRAS_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALOROUTRAS([^_[:alnum:]])',
                                        NVL (ITEM.VALOROUTRAS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORFRETE([^_[:alnum:]])',
                                        NVL (ITEM.VALORFRETE, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORIPI([^_[:alnum:]])',
                                        NVL (ITEM.VALORIPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORIMPOSTOESTADUAL([^_[:alnum:]])',
                            NVL (ITEM.VALORIMPOSTOESTADUAL, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORSTFORANF([^_[:alnum:]])',
                                        NVL (ITEM.VALORSTFORANF, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORNAOTRIB_DAPI([^_[:alnum:]])',
                            NVL (ITEM.VALORNAOTRIB_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORSUSPENSAS_DAPI([^_[:alnum:]])',
                            NVL (ITEM.VALORSUSPENSAS_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORST_DAPI([^_[:alnum:]])',
                                        NVL (ITEM.VALORST_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORISENTASIPI([^_[:alnum:]])',
                            NVL (ITEM.VALORISENTASIPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALOROUTRASIPI([^_[:alnum:]])',
                                        NVL (ITEM.VALOROUTRASIPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORST([^_[:alnum:]])',
                                        NVL (ITEM.VALORST, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORIRRF([^_[:alnum:]])',
                                        NVL (ITEM.VALORIRRF, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORSESTSENAT([^_[:alnum:]])',
                                        NVL (ITEM.VALORSESTSENAT, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORISS([^_[:alnum:]])',
                                        NVL (ITEM.VALORISS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORINSS([^_[:alnum:]])',
                                        NVL (ITEM.VALORINSS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORCSRF([^_[:alnum:]])',
                                        NVL (ITEM.VALORCSRF, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORPISCALCDI([^_[:alnum:]])',
                                        NVL (ITEM.VALORPISCALCDI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORCOFINSCALCDI([^_[:alnum:]])',
                            NVL (ITEM.VALORCOFINSCALCDI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORFRETECONT([^_[:alnum:]])',
                                        NVL (ITEM.VALORFRETECONT, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORCREDPRESUMIDO([^_[:alnum:]])',
                            NVL (ITEM.VALORCREDPRESUMIDO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORSISCOMEX([^_[:alnum:]])',
                                        NVL (ITEM.VALORSISCOMEX, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORIMPORTACAO([^_[:alnum:]])',
                            NVL (ITEM.VALORIMPORTACAO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORCAPATAZIA([^_[:alnum:]])',
                                        NVL (ITEM.VALORCAPATAZIA, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORAFRMM([^_[:alnum:]])',
                                        NVL (ITEM.VALORAFRMM, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORADUANEIRA([^_[:alnum:]])',
                                        NVL (ITEM.VALORADUANEIRA, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALOROUTRASDESPIMP([^_[:alnum:]])',
                            NVL (ITEM.VALOROUTRASDESPIMP, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORANTIDUMPING([^_[:alnum:]])',
                            NVL (ITEM.VALORANTIDUMPING, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORSEGURO([^_[:alnum:]])',
                                        NVL (ITEM.VALORSEGURO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORFUNDOCOMBPOBREZA([^_[:alnum:]])',
                            NVL (ITEM.VALORFUNDOCOMBPOBREZA, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORICMSDIFALIQPARTILHA([^_[:alnum:]])',
                            NVL (ITEM.VALORICMSDIFALIQPARTILHA, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALOROUTROSCUSTOS([^_[:alnum:]])',
                            NVL (ITEM.VALOROUTROSCUSTOS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALOROUTROSCUSTOSFORANF([^_[:alnum:]])',
                            NVL (ITEM.VALOROUTROSCUSTOSFORANF, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORICMSANTECIPADO([^_[:alnum:]])',
                            NVL (ITEM.VALORICMSANTECIPADO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORIMPPRODUTORRURAL([^_[:alnum:]])',
                            NVL (ITEM.VALORIMPPRODUTORRURAL, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORDIFALIQUOTA([^_[:alnum:]])',
                            NVL (ITEM.VALORDIFALIQUOTA, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORCREDITO_CIAP([^_[:alnum:]])',
                            NVL (ITEM.VALORCREDITO_CIAP, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORICMSUFDEST([^_[:alnum:]])',
                            NVL (ITEM.VALORICMSUFDEST, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORICMSUFREM([^_[:alnum:]])',
                                        NVL (ITEM.VALORICMSUFREM, 0) || '\1');

                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORDESPFORANF([^_[:alnum:]])',
                            NVL (ITEM.VALORDESPFORANF, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORFRETECONHEC([^_[:alnum:]])',
                            NVL (ITEM.VALORFRETECONHEC, 0) || '\1');

                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORFCEP([^_[:alnum:]])',
                                        NVL (ITEM.VALORFCEP, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORACRESCIMOFUNCEP([^_[:alnum:]])',
                            NVL (ITEM.VALORACRESCIMOFUNCEP, 0) || '\1');

                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORICMSBCR([^_[:alnum:]])',
                                        NVL (ITEM.VALORICMSBCR, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORSTBCR([^_[:alnum:]])',
                                        NVL (ITEM.VALORSTBCR, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORFECPSTGUIA([^_[:alnum:]])',
                            NVL (ITEM.VALORFECPSTGUIA, 0) || '\1');


                    CALCULAREXPRESSAO;
                    --FIM DA FÓRMULA---------------------------------------------------------------------


                    VS_RECNUM_CENTROCUSTO := '';

                    IF VN_VALORLANCTO > 0
                    THEN
                        VS_CONTA := TRIM (ITENSREGRA.CODREDUZIDO_PC);
                        VS_CODFILIAL :=
                            CASE
                                WHEN ITENSREGRA.CODFILIAL =
                                     'FILIALLANCAMENTO'
                                THEN
                                    ITEM.CODFILIAL
                                ELSE
                                    ITENSREGRA.CODFILIAL
                            END;

                        IF     (SUBSTR (VS_CONTA, 1, 1) <> '0')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '1')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '2')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '3')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '4')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '5')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '6')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '7')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '8')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '9')
                        THEN
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTAFORNECEDOR',
                                         ITEM.CODCONTAFORNECEDOR);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CONTACONTABIL',
                                         ITEM.CONTACONTABIL);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTADESP',
                                         ITEM.CODCONTADESP);

                            --VERIFICA SE A PERNA DA INTEGRAÇÃO TEM CENTRO DE CUSTO
                            IF (F_LANCTO_TEM_CENTROCUSTO (
                                    VS_CONTA,
                                    ITEM.CONTAGERENCIAL,
                                    1,
                                    ITEM.NUMTRANSOPERACAO,
                                    0,
                                    '0',
                                    PCODPLANOCONTA) =
                                'S')
                            THEN
                                VS_RECNUM_CENTROCUSTO := 'S';
                            END IF;
                        END IF;

                        IF VS_TEMCONTAINEXISTENTE <> 'X'
                        THEN
                            VS_CONTA_EXISTE :=
                                F_VERIFICA_CONTA_EXISTE (VS_CONTA,
                                                         PCODPLANOCONTA);
                            TRATAR_CONTA_INEXISTENTE (VS_CONTA_EXISTE,
                                                      VS_TEMCONTAINEXISTENTE);
                        END IF;

                        IF VS_CONTA_EXISTE IN ('S', 'I', 'X')
                        THEN
                            --HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO---------------------------------------
                            ---------------------------------------------------------------------------------
                            V_SQLERRO :=
                                '1 - ENTRADAS: ATRIBUINDO VALOR DE HISTÓRICOS';
                            ---------------------------------------------------------------------------------
                            VS_HISTORICO := ITENSREGRA.HISTCOMPLREGRA;
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO]',
                                         ITEM.DATAOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAEMISSAONF]',
                                         ITEM.DATAEMISSAONF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMNOTANF]',
                                         ITEM.NUMNOTANF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[ESPECIENF]',
                                         ITEM.ESPECIENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[SERIENF]',
                                         ITEM.SERIENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODFISCALNF]',
                                         ITEM.CODFISCALNF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODFORNECNF]',
                                         ITEM.CODFORNECNF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[FORNECEDORNF]',
                                         ITEM.FORNECEDORNF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO, '[UFNF]', ITEM.UFNF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMTRANSOPERACAO]',
                                         ITEM.NUMTRANSOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMEROCONTRATO]',
                                         ITEM.NUMEROCONTRATO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMDIIMPORTACAO]',
                                         ITEM.NUMDIIMPORTACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NOMECONTAGERENCIAL]',
                                         ITEM.NOMECONTAGERENCIAL);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMNEGOCIACAO]',
                                         ITEM.NUMNEGOCIACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMPEDPRINC]',
                                         ITEM.NUMPEDPRINC);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMINVOCE]',
                                         ITEM.NUMINVOCE);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMPROFORMA]',
                                         ITEM.NUMPROFORMA);

                            VS_HISTORICO := SUBSTR (VS_HISTORICO, 1, 200);

                            --FIM HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO-----------------------------------

                            IF ITENSREGRA.NATUREZA = 'C'
                            THEN
                                VN_TOTALCREDITO :=
                                    ROUND (
                                          VN_TOTALCREDITO
                                        + ABS (VN_VALORLANCTO),
                                        2);
                                VS_NATUREZA := 'C';
                            ELSE
                                VN_TOTALDEBITO :=
                                    ROUND (
                                        VN_TOTALDEBITO + ABS (VN_VALORLANCTO),
                                        2);
                                VS_NATUREZA := 'D';
                            END IF;

                            --GUARDA FILIAIS
                            FILIAIS.CODFILIAL := '-1';

                            FOR VN_POSICAO IN 1 .. FILIAIS_LANCADAS.COUNT
                            LOOP
                                IF (FILIAIS_LANCADAS (VN_POSICAO).CODFILIAL =
                                    VS_CODFILIAL)
                                THEN
                                    FILIAIS := FILIAIS_LANCADAS (VN_POSICAO);
                                    VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

                                    EXIT;
                                END IF;
                            END LOOP;

                            IF (FILIAIS.CODFILIAL = '-1')
                            THEN
                                FILIAIS_LANCADAS.EXTEND;

                                FILIAIS :=
                                    FILIAIS_LANCADAS (FILIAIS_LANCADAS.COUNT);
                                VN_POSICAO_EM_ALTERACAO :=
                                    FILIAIS_LANCADAS.COUNT;

                                FILIAIS.CODFILIAL := VS_CODFILIAL;
                                FILIAIS.CGCFILIAL :=
                                    F_CGCFILIAL (VS_CODFILIAL);

                                FILIAIS_LANCADAS (VN_POSICAO_EM_ALTERACAO) :=
                                    FILIAIS;
                            END IF;

                            --Guarda as contas para verificar se estão iguais posteriormente
                            P_ARMAZENA_CONTAS_FILIAIS_LANC (VS_CONTA,
                                                            VS_NATUREZA,
                                                            VS_CODFILIAL,
                                                            FILIAIS_LANCADAS);

                            IF 'N' = 'S'
                            THEN
                                NULL;
                            ELSE
                                VS_LISTA_RECNUM_CENTROCUSTO := NULL;

                                IF (VS_RECNUM_CENTROCUSTO IS NOT NULL)
                                THEN
                                    IF    (VN_NUMTRANSENT_ANTERIOR IS NULL)
                                       OR (VN_NUMTRANSENT_ANTERIOR <>
                                           ITEM.NUMTRANSOPERACAO)
                                       OR ((ITEM.CONTAGERENCIAL <>
                                            V_CONTA_ANTERIOR))
                                       OR (    (ITEM.CONTAGERENCIAL =
                                                V_CONTA_ANTERIOR)
                                           AND (ITEM.CODFISCALNF <>
                                                VN_CODFISCAL_ANTERIOR))
                                       OR (    (ITEM.CONTAGERENCIAL =
                                                V_CONTA_ANTERIOR)
                                           AND (ITEM.SITUACAOTRIBUTARIA <>
                                                VS_SITTRIBUT_ANTERIOR))
                                    THEN
                                        VS_NUMTRANSCENTROCUSTO :=
                                            F_RETORNA_NUMTRANS_CENTROCUSTO ();
                                    END IF;
                                END IF;

                                ---------------------------------------------------------------------------------
                                V_SQLERRO :=
                                    '1 - ENTRADAS: EXECUTANDO PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA()';
                                ---------------------------------------------------------------------------------

                                --INSERE DADOS NA TABELA QUANDO NÃO ESTÁ TOTALIZANDO VALORES
                                VN_NUMSEQ := VN_NUMSEQ + 1;

                                P_GRAVA_DADOS_TABINTERMEDIARIA (
                                    VS_CODFILIAL,
                                    VN_NUMTRANSACAO,
                                    VN_NUMSEQ,
                                    VD_DATALANCTO,
                                    VS_DOCUMENTO,
                                    ITENSREGRA.CODHISTORICO,
                                    VS_HISTORICO,
                                    PCODPLANOCONTA,
                                    VS_CONTA,
                                    VS_NATUREZA,
                                    VN_VALORLANCTO,
                                    PCODREGRA,
                                    '',
                                    ITEM.NUMTRANSOPERACAO,
                                    F_RETORNA_TIPO_INCONSISTENCIA (
                                        VS_TEMCONTAINEXISTENTE),
                                    'P',
                                    ITEM.DATAOPERACAO,
                                    ITEM.CODFISCALNF,
                                    0,
                                    '',
                                    CASE
                                        WHEN VS_RECNUM_CENTROCUSTO IS NULL
                                        THEN
                                            ''
                                        ELSE
                                            VS_NUMTRANSCENTROCUSTO
                                    END,
                                    VD_DATAINTEGRACAO,
                                    ITEM.CODFORNECNF,
                                    'F',
                                    NULL,
                                    ITEM.NUMTRANSOPERACAO,
                                    ITEM.CONTAGERENCIAL,
                                    ITENSREGRA.FORMULAS,
                                    ITENSREGRA.CODREDUZIDO_PC,
                                    'ENTRADA',
                                    'PCNFENT',
                                    ITENSREGRA.TOTALIZAVALOR);

                                IF (VS_RECNUM_CENTROCUSTO IS NOT NULL)
                                THEN
                                    IF    (VN_NUMTRANSENT_ANTERIOR IS NULL)
                                       OR (VN_NUMTRANSENT_ANTERIOR <>
                                           ITEM.NUMTRANSOPERACAO)
                                       OR (ITEM.CONTAGERENCIAL <>
                                           V_CONTA_ANTERIOR)
                                       OR (    (ITEM.CONTAGERENCIAL =
                                                V_CONTA_ANTERIOR)
                                           AND (ITEM.CODFISCALNF <>
                                                VN_CODFISCAL_ANTERIOR))
                                       OR (    (ITEM.CONTAGERENCIAL =
                                                V_CONTA_ANTERIOR)
                                           AND (ITEM.SITUACAOTRIBUTARIA <>
                                                VS_SITTRIBUT_ANTERIOR))
                                    THEN
                                        FOR DADOS_PCLANC_CC
                                            IN (SELECT A.RECNUM
                                                  FROM PCLANC A
                                                 WHERE     A.NUMTRANSENT =
                                                           ITEM.NUMTRANSOPERACAO
                                                       AND A.CODCONTA =
                                                           ITEM.CONTAGERENCIAL
                                                       AND INSTR (
                                                               CODROTINACAD,
                                                               '737') =
                                                           0
                                                       AND INSTR (
                                                               CODROTINACAD,
                                                               '775') =
                                                           0
                                                       AND (    (INSTR (
                                                                     A.CODROTINACAD,
                                                                     '746') =
                                                                 0)
                                                            AND (NOT EXISTS
                                                                     (SELECT 1
                                                                        FROM PCLANC
                                                                             L1
                                                                       WHERE L1.RECNUM =
                                                                             (SELECT D1.RECNUMORIG
                                                                                FROM PCDESDLANC
                                                                                     D1
                                                                               WHERE     D1.RECNUMDESTINO =
                                                                                         A.RECNUM
                                                                                     AND (    (INSTR (
                                                                                                   D1.ROTINAINSERT,
                                                                                                   '737') =
                                                                                               0)
                                                                                          AND (INSTR (
                                                                                                   D1.ROTINAINSERT,
                                                                                                   '775') =
                                                                                               0))
                                                                                     AND ROWNUM =
                                                                                         1))))
                                                       AND NOT EXISTS
                                                               (SELECT 1
                                                                  FROM PCCONSUM
                                                                 WHERE    CODCONTPAGJUR =
                                                                          A.CODCONTA
                                                                       OR CODCONTACAMBIAL =
                                                                          A.CODCONTA
                                                                       OR CODCONTDESCCONC =
                                                                          A.CODCONTA))
                                        LOOP
                                            VN_NUMTRANSENT_ANTERIOR :=
                                                ITEM.NUMTRANSOPERACAO;
                                            V_CONTA_ANTERIOR :=
                                                ITEM.CONTAGERENCIAL;
                                            VN_CODFISCAL_ANTERIOR :=
                                                ITEM.CODFISCALNF;
                                            VS_SITTRIBUT_ANTERIOR :=
                                                ITEM.SITUACAOTRIBUTARIA;

                                            IF VS_LISTA_RECNUM_CENTROCUSTO
                                                   IS NULL
                                            THEN
                                                VS_LISTA_RECNUM_CENTROCUSTO :=
                                                    DADOS_PCLANC_CC.RECNUM;
                                            ELSE
                                                VS_LISTA_RECNUM_CENTROCUSTO :=
                                                       VS_LISTA_RECNUM_CENTROCUSTO
                                                    || ','
                                                    || DADOS_PCLANC_CC.RECNUM;
                                            END IF;
                                        -- VS_RECNUM_CENTROCUSTO := DADOS_PCLANC_CC.RECNUM;
                                        END LOOP;

                                        P_GRAVA_PCINTER_CENTROCUSTO (
                                            VS_LISTA_RECNUM_CENTROCUSTO,
                                            VS_NUMTRANSCENTROCUSTO,
                                            PCODREGRA,
                                            ITEM.DATAOPERACAO,
                                            TRUE,
                                            0,
                                            '',
                                               VS_HISTORICO
                                            || vs_conta
                                            || VS_CODFILIAL,
                                            0);

                                        --Conforme fato gerador 3
                                        VS_NUMTRANSCENTROCUSTO := '';
                                    ELSE
                                        VS_LISTA_RECNUM_CENTROCUSTO := '0';
                                    END IF;
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END LOOP;

                --GUARDA O NÚMERO DA TRANSAÇÃO
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            ELSE
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            END IF;
        END LOOP;

        --VERIFICA CONSISTÊNCIAS DO ÚLTIMO REGISTRO
        IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '1 - ENTRADAS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
            ---------------------------------------------------------------------------------
            P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                        VD_DATALANCTO,
                                        VS_TEMCONTAINEXISTENTE,
                                        VN_TOTALDEBITO,
                                        VN_TOTALCREDITO,
                                        'N');
        END IF;

        CLOSE CURSOR_DADOS;

        RESULTADO := 'OK';
    EXCEPTION
        WHEN OTHERS
        THEN
            RESULTADO :=
                   'Ocorreu um erro quando: '
                || V_SQLERRO
                || CHR (13)
                || 'Erro Original: '
                || SQLERRM;
    END;

    /****************************************************************************
      PROCEDURE PARA GERAÇÃO DE 2 - SAÍDAS
    *****************************************************************************/
    PROCEDURE P_DADOS_SAIDAS (CURSOR_DADOS     IN     SYS_REFCURSOR,
                              PCODREGRA        IN     NUMBER,
                              PCODPLANOCONTA   IN     NUMBER,
                              RESULTADO           OUT VARCHAR2)
    IS
        TYPE CONSULTA_SAIDAS IS RECORD
        (
            CODFILIAL PCNFBASESAID.CODFILIALNF%TYPE,
            DATAOPERACAO PCNFBASESAID.DTSAIDA%TYPE,
            NUMNOTANF PCNFBASESAID.NUMNOTA%TYPE,
            VALORTOTAL PCNFBASESAID.VLDESDOBRADO%TYPE,
            VALORICMS PCNFBASESAID.VLICMS%TYPE,
            VALORPIS PCNFBASESAID.VLPIS%TYPE,
            VALORCOFINS PCNFBASESAID.VLCOFINS%TYPE,
            VALORISENTAS PCNFBASESAID.VLISENTAS%TYPE,
            VALOROUTRAS PCNFBASESAID.VLOUTRAS%TYPE,
            VALORFRETE PCNFBASESAID.VLFRETE%TYPE,
            VALORST PCNFBASESAID.VLST%TYPE,
            VALORIPI PCNFBASESAID.VLIPI%TYPE,
            VALORIMPESTADUAL PCNFBASESAID.VLIMPESTADUAL%TYPE,
            VALORREPASSE PCNFBASESAID.VLREPASSE%TYPE,
            VALORSUBSTRETENCAO PCNFBASESAID.VLSTBCR%TYPE,
            VALORCREDPRESUMIDO PCNFBASESAID.VLCREDPRESUMIDO%TYPE,
            VALORISENTAS_DAPI PCNFBASESAID.VLISENTAS_DAPI%TYPE,
            VALORNAOTRIB_DAPI PCNFBASESAID.VLNAOTRIB_DAPI%TYPE,
            VALORBASERED_DAPI PCNFBASESAID.VLBASERED_DAPI%TYPE,
            VALORSUSPENSAS_DAPI PCNFBASESAID.VLSUSPENSAS_DAPI%TYPE,
            VALORST_DAPI PCNFBASESAID.VLST_DAPI%TYPE,
            VALOROUTRAS_DAPI PCNFBASESAID.VLOUTRAS_DAPI%TYPE,
            VALORISENTASIPI PCNFBASESAID.VLISENTASIPI%TYPE,
            VALOROUTRASIPI PCNFBASESAID.VLOUTRASIPI%TYPE,
            VALORFUNDOCOMBPOBREZA PCNFBASESAID.VLFCP%TYPE,
            VALORICMSDIFALIQPARTILHA PCNFBASESAID.VLICMSDIFALIQPART%TYPE,
            VALORICMSUFDEST PCNFBASESAID.VLICMSUFDEST%TYPE,
            VALORICMSUFREM PCNFBASESAID.VLICMSUFREM%TYPE,
            CODCOBRANCA PCNFSAID.CODCOB%TYPE,
            CODFISCALNF PCCFO.CODFISCAL%TYPE,
            TIPODEVENDANF PCNFSAID.CONDVENDA%TYPE,
            ESPECIENF PCNFBASESAID.ESPECIE%TYPE,
            TIPOOPERACAO PCNFBASESAID.TIPOVENDA%TYPE,
            CLIENTENF PCCLIENT.CLIENTE%TYPE,
            CODCLIENTENF PCNFBASESAID.CODCLI%TYPE,
            CLIENTEDESTINATARIO PCNFSAID.CLIENTE%TYPE,
            SERIENF PCNFBASESAID.SERIE%TYPE,
            UFNF PCNFBASESAID.UF%TYPE,
            FINALIDADENFE PCNFSAID.FINALIDADENFE%TYPE,
            SITUACAOTRIBUTARIA PCNFBASESAID.SITTRIBUT%TYPE,
            NUMTRANSOPERACAO PCNFBASESAID.NUMTRANSVENDA%TYPE,
            TIPOFRETE PCNFSAID.TIPOFRETE%TYPE,
            CODCONTAGERENCIAL PCNFSAID.CODCONT%TYPE,
            CODCONTACLIENTE PCCLIENT.CODCONTAB%TYPE,
            CONTACONTABIL PCCONTA.CONTACONTABIL%TYPE,
            CODREMETENTEFRETE PCNFSAID.CODREMETENTEFRETE%TYPE,
            VALOROUTRASDESPESAS PCNFBASESAID.VLOUTRASDESP%TYPE,
            MODELONFE VARCHAR2 (10),
            CONTAREMETENTEFRETE PCMODELOPC.CODREDUZIDO_PC%TYPE,
            TEMINTEGRACAO VARCHAR2 (1),
            VALORFCEP PCNFBASESAID.VLFECP%TYPE,
            VALORACRESCIMOFUNCEP PCNFBASESAID.VLACRESCIMOFUNCEP%TYPE,
            VALORICMSBCR PCNFBASESAID.VLICMSBCR%TYPE,
            VALORSTBCR PCNFBASESAID.VLSTBCR%TYPE
        );

        ITEM               CONSULTA_SAIDAS;
        ITENSREGRA         CONSULTA_ITENS;

        CURSOR_ITENS       SYS_REFCURSOR;

        FILIAIS_LANCADAS   TABELAFILIAISLANCTO;
        FILIAIS            FILIAISLANCTO;
        VS_CONTA_EXISTE    VARCHAR2 (1);
    BEGIN
        LISTA_FORMULAS := TYPE_LISTA_FORMULAS ();

        FILIAIS_LANCADAS := TABELAFILIAISLANCTO ();

        VS_SEQGERADO := 'N';
        VS_FORMADTCONTABILIZACAO := '';
        VN_NUMTRANSACAO := 0;
        VS_DOCUMENTO := '';
        VS_TEMCONTAINEXISTENTE := 'N';

        --BUSCA DADOS DA REGRA
        SELECT FORMADTCONTABILIZACAO
          INTO VS_FORMADTCONTABILIZACAO
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        V_SQLERRO := 'ABRINDO SAIDAS';

        --INICIA LAÇO DOS DADOS
        LOOP
            FETCH CURSOR_DADOS INTO ITEM;

            EXIT WHEN CURSOR_DADOS%NOTFOUND;

            IF    (ITEM.TEMINTEGRACAO IS NULL)
               OR (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                   AND (ITEM.TEMINTEGRACAO = 'P'))
            THEN
                --------------------------------------------------------------------
                --VERIFICA SE ALTEROU O NUMTRANSOPERACAO PARA FAZER GRAVAÇÃO E RE-INICIAR VARIÁVEIS
                IF (VN_NUMTRANSOPERACAO <> ITEM.NUMTRANSOPERACAO)
                THEN
                    VS_SEQGERADO := 'N';

                    IF (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                        AND (ITEM.TEMINTEGRACAO = 'P'))
                    THEN
                        P_EXCLUI_LANCINTERMEDIARIA_IND (
                            PCODREGRA,
                            ITEM.NUMTRANSOPERACAO,
                            ITEM.DATAOPERACAO);
                    END IF;

                    --VERIFICA SE JÁ PASSOU POR ALGUM REGISTRO PARA ATRIBUIR INCONSISTÊNCIAS
                    IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) >
                       0
                    THEN
                        ---------------------------------------------------------------------------------
                        V_SQLERRO :=
                            '2 - SAIDAS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
                        ---------------------------------------------------------------------------------
                        P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                                    VD_DATALANCTO,
                                                    VS_TEMCONTAINEXISTENTE,
                                                    VN_TOTALDEBITO,
                                                    VN_TOTALCREDITO,
                                                    'N');
                    END IF;

                    VS_TEMCONTAINEXISTENTE := 'N';
                END IF;

                --------------------------------------------------------------------

                --GERA NOVO NUMTRANSLANCTO
                IF VS_SEQGERADO = 'N'
                THEN
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '2 - SAIDAS: EXECUTANDO FUNÇÃO GERA_NUM_TRANS_LANCTO()';
                    ---------------------------------------------------------------------------------
                    VN_NUMTRANSACAO := F_GERA_NUM_TRANS_LANCTO ();

                    VN_NUMSEQ := 0;
                    VN_TOTALCREDITO := 0;
                    VN_TOTALDEBITO := 0;
                    VS_SEQGERADO := 'S';

                    CONTASDEBLANCTO := CONTAS_LANCADAS ();
                    CONTASCRELANCTO := CONTAS_LANCADAS ();
                    CGCSLANCTO := CGC_LANCADOS ();
                    VS_LISTAS_TRANSOTORIAS := CONTAS_LANCADAS ();

                    CONTASDEBLANCTO.EXTEND;
                    CONTASCRELANCTO.EXTEND;
                END IF;

                VD_DATALANCTO :=
                    F_RETORNA_DATA_LANCPROVISOES (2,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO);

                VD_DATAINTEGRACAO :=
                    F_RETORNA_DATA_LANCPROVISOES (2,
                                                  PCODREGRA,
                                                  DATA_INTEGRACAO,
                                                  ITEM.DATAOPERACAO);

                --LAÇO NOS ITENS DA REGRA CONTABIL
                OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL ()
                    USING PCODREGRA;

                LOOP
                    FETCH CURSOR_ITENS INTO ITENSREGRA;

                    EXIT WHEN CURSOR_ITENS%NOTFOUND;

                    ---------------------------------------------------------------------------------
                    V_SQLERRO := '2 - SAIDAS: ATRIBUINDO VALOR DO DOCUMENTO';
                    ---------------------------------------------------------------------------------
                    VS_DOCUMENTO := ITENSREGRA.DOCUMENTO;
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO',
                                 TO_CHAR (ITEM.DATAOPERACAO, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMNOTANF', ITEM.NUMNOTANF);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMTRANSOPERACAO',
                                 ITEM.NUMTRANSOPERACAO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'CODCONTAGERENCIAL',
                                 ITEM.CODCONTAGERENCIAL);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'SITUACAOTRIBUTARIA',
                                 ITEM.SITUACAOTRIBUTARIA);

                    --FORMULA INFORMADA NO FILTRO--------------------------------------------------------
                    ---------------------------------------------------------------------------------
                    V_SQLERRO := '2 - SAIDAS: ATRIBUINDO VALOR DA FÓRMULA';
                    ---------------------------------------------------------------------------------
                    VN_VALORLANCTO := 0;

                    VS_FORMULA := ITENSREGRA.FORMULAS || ' + 0 ';
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORTOTAL([^_[:alnum:]])',
                                        NVL (ITEM.VALORTOTAL, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORICMS([^_[:alnum:]])',
                                        NVL (ITEM.VALORICMS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORPIS([^_[:alnum:]])',
                                        NVL (ITEM.VALORPIS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORCOFINS([^_[:alnum:]])',
                                        NVL (ITEM.VALORCOFINS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORISENTAS([^_[:alnum:]])',
                                        NVL (ITEM.VALORISENTAS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALOROUTRAS([^_[:alnum:]])',
                                        NVL (ITEM.VALOROUTRAS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORFRETE([^_[:alnum:]])',
                                        NVL (ITEM.VALORFRETE, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORIPI([^_[:alnum:]])',
                                        NVL (ITEM.VALORIPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORIMPESTADUAL([^_[:alnum:]])',
                            NVL (ITEM.VALORIMPESTADUAL, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORREPASSE([^_[:alnum:]])',
                                        NVL (ITEM.VALORREPASSE, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORSUBSTRETENCAO([^_[:alnum:]])',
                            NVL (ITEM.VALORSUBSTRETENCAO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORISENTAS_DAPI([^_[:alnum:]])',
                            NVL (ITEM.VALORISENTAS_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORNAOTRIB_DAPI([^_[:alnum:]])',
                            NVL (ITEM.VALORNAOTRIB_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORBASERED_DAPI([^_[:alnum:]])',
                            NVL (ITEM.VALORBASERED_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORSUSPENSAS_DAPI([^_[:alnum:]])',
                            NVL (ITEM.VALORSUSPENSAS_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORST_DAPI([^_[:alnum:]])',
                                        NVL (ITEM.VALORST_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALOROUTRAS_DAPI([^_[:alnum:]])',
                            NVL (ITEM.VALOROUTRAS_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORISENTASIPI([^_[:alnum:]])',
                            NVL (ITEM.VALORISENTASIPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALOROUTRASIPI([^_[:alnum:]])',
                                        NVL (ITEM.VALOROUTRASIPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORST([^_[:alnum:]])',
                                        NVL (ITEM.VALORST, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORCREDPRESUMIDO([^_[:alnum:]])',
                            NVL (ITEM.VALORCREDPRESUMIDO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALOROUTRASDESPESAS([^_[:alnum:]])',
                            NVL (ITEM.VALOROUTRASDESPESAS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORFUNDOCOMBPOBREZA([^_[:alnum:]])',
                            NVL (ITEM.VALORFUNDOCOMBPOBREZA, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORICMSDIFALIQPARTILHA([^_[:alnum:]])',
                            NVL (ITEM.VALORICMSDIFALIQPARTILHA, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORICMSUFDEST([^_[:alnum:]])',
                            NVL (ITEM.VALORICMSUFDEST, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORICMSUFREM([^_[:alnum:]])',
                                        NVL (ITEM.VALORICMSUFREM, 0) || '\1');

                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORFECP([^_[:alnum:]])',
                                        NVL (ITEM.VALORFCEP, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORACRESCIMOFUNCEP([^_[:alnum:]])',
                            NVL (ITEM.VALORACRESCIMOFUNCEP, 0) || '\1');

                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORICMSBCR([^_[:alnum:]])',
                                        NVL (ITEM.VALORICMSBCR, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORSTBCR([^_[:alnum:]])',
                                        NVL (ITEM.VALORSTBCR, 0) || '\1');

                    CALCULAREXPRESSAO;

                    --FIM DA FÓRMULA---------------------------------------------------------------------

                    IF VN_VALORLANCTO > 0
                    THEN
                        VS_CONTA := TRIM (ITENSREGRA.CODREDUZIDO_PC);
                        VS_CODFILIAL :=
                            CASE
                                WHEN ITENSREGRA.CODFILIAL =
                                     'FILIALLANCAMENTO'
                                THEN
                                    ITEM.CODFILIAL
                                ELSE
                                    ITENSREGRA.CODFILIAL
                            END;


                        IF     (SUBSTR (VS_CONTA, 1, 1) <> '0')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '1')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '2')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '3')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '4')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '5')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '6')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '7')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '8')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '9')
                        THEN
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTACLIENTE',
                                         ITEM.CODCONTACLIENTE);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CONTACONTABIL',
                                         ITEM.CONTACONTABIL);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CONTAREMETENTEFRETE',
                                         ITEM.CONTAREMETENTEFRETE);
                        END IF;

                        VS_CONTA_EXISTE :=
                            F_VERIFICA_CONTA_EXISTE (VS_CONTA,
                                                     PCODPLANOCONTA);
                        TRATAR_CONTA_INEXISTENTE (VS_CONTA_EXISTE,
                                                  VS_TEMCONTAINEXISTENTE);

                        IF VS_CONTA_EXISTE IN ('S', 'I', 'X')
                        THEN
                            --HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO---------------------------------------
                            ---------------------------------------------------------------------------------
                            V_SQLERRO :=
                                '2 - SAIDAS: ATRIBUINDO VALOR DE HISTÓRICOS';
                            ---------------------------------------------------------------------------------
                            VS_HISTORICO := ITENSREGRA.HISTCOMPLREGRA;
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO]',
                                         ITEM.DATAOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMNOTANF]',
                                         ITEM.NUMNOTANF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODFISCALNF]',
                                         ITEM.CODFISCALNF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[ESPECIENF]',
                                         ITEM.ESPECIENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CLIENTENF]',
                                         ITEM.CLIENTENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODCLIENTENF]',
                                         ITEM.CODCLIENTENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CLIENTEDESTINATARIO]',
                                         ITEM.CLIENTEDESTINATARIO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[SERIENF]',
                                         ITEM.SERIENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO, '[UFNF]', ITEM.UFNF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMTRANSOPERACAO]',
                                         ITEM.NUMTRANSOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODCONTAGERENCIAL]',
                                         ITEM.CODCONTAGERENCIAL);
                            VS_HISTORICO := SUBSTR (VS_HISTORICO, 1, 200);

                            --FIM HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO-----------------------------------

                            IF ITENSREGRA.NATUREZA = 'C'
                            THEN
                                VN_TOTALCREDITO :=
                                    ROUND (
                                          VN_TOTALCREDITO
                                        + ABS (VN_VALORLANCTO),
                                        2);
                                VS_NATUREZA := 'C';
                            ELSE
                                VN_TOTALDEBITO :=
                                    ROUND (
                                        VN_TOTALDEBITO + ABS (VN_VALORLANCTO),
                                        2);
                                VS_NATUREZA := 'D';
                            END IF;

                            --GUARDA FILIAIS
                            FILIAIS.CODFILIAL := '-1';

                            FOR VN_POSICAO IN 1 .. FILIAIS_LANCADAS.COUNT
                            LOOP
                                IF (FILIAIS_LANCADAS (VN_POSICAO).CODFILIAL =
                                    VS_CODFILIAL)
                                THEN
                                    FILIAIS := FILIAIS_LANCADAS (VN_POSICAO);
                                    VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

                                    EXIT;
                                END IF;
                            END LOOP;

                            IF (FILIAIS.CODFILIAL = '-1')
                            THEN
                                FILIAIS_LANCADAS.EXTEND;

                                FILIAIS :=
                                    FILIAIS_LANCADAS (FILIAIS_LANCADAS.COUNT);
                                VN_POSICAO_EM_ALTERACAO :=
                                    FILIAIS_LANCADAS.COUNT;

                                FILIAIS.CODFILIAL := VS_CODFILIAL;
                                FILIAIS.CGCFILIAL :=
                                    F_CGCFILIAL (VS_CODFILIAL);

                                FILIAIS_LANCADAS (VN_POSICAO_EM_ALTERACAO) :=
                                    FILIAIS;
                            END IF;

                            --GUARDA AS CONTAS PARA VERIFICAR SE ESTÃO IGUAIS POSTERIORMENTE
                            P_ARMAZENA_CONTAS_FILIAIS_LANC (VS_CONTA,
                                                            VS_NATUREZA,
                                                            VS_CODFILIAL,
                                                            FILIAIS_LANCADAS);

                            IF 'N' = 'S'
                            THEN
                                NULL;
                            ELSE
                                ---------------------------------------------------------------------------------
                                V_SQLERRO :=
                                    '2 - SAIDAS: EXECUTANDO PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA()';
                                ---------------------------------------------------------------------------------
                                --INSERE DADOS NA TABELA QUANDO NÃO ESTÁ TOTALIZANDO VALORES
                                VN_NUMSEQ := VN_NUMSEQ + 1;

                                P_GRAVA_DADOS_TABINTERMEDIARIA (
                                    VS_CODFILIAL,
                                    VN_NUMTRANSACAO,
                                    VN_NUMSEQ,
                                    VD_DATALANCTO,
                                    VS_DOCUMENTO,
                                    ITENSREGRA.CODHISTORICO,
                                    VS_HISTORICO,
                                    PCODPLANOCONTA,
                                    VS_CONTA,
                                    VS_NATUREZA,
                                    VN_VALORLANCTO,
                                    PCODREGRA,
                                    '',
                                    ITEM.NUMTRANSOPERACAO,
                                    F_RETORNA_TIPO_INCONSISTENCIA (
                                        VS_TEMCONTAINEXISTENTE),
                                    'P',
                                    ITEM.DATAOPERACAO,
                                    ITEM.CODFISCALNF,
                                    0,
                                    '',
                                    '',
                                    VD_DATAINTEGRACAO,
                                    ITEM.CODCLIENTENF,
                                    'C',
                                    NULL,
                                    ITEM.NUMTRANSOPERACAO,
                                    '',
                                    ITENSREGRA.FORMULAS,
                                    ITENSREGRA.CODREDUZIDO_PC,
                                    'SAIDA',
                                    'PCNFSAID',
                                    ITENSREGRA.TOTALIZAVALOR);
                            END IF;
                        END IF;
                    END IF;
                END LOOP;

                --GUARDA O NÚMERO DA TRANSAÇÃO
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            ELSE
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            END IF;
        END LOOP;

        --VERIFICA CONSISTÊNCIAS DO ÚLTIMO REGISTRO
        IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '2 - SAIDAS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
            ---------------------------------------------------------------------------------
            P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                        VD_DATALANCTO,
                                        VS_TEMCONTAINEXISTENTE,
                                        VN_TOTALDEBITO,
                                        VN_TOTALCREDITO,
                                        'N');
        END IF;

        CLOSE CURSOR_DADOS;

        RESULTADO := 'OK';
    EXCEPTION
        WHEN OTHERS
        THEN
            RESULTADO :=
                   'Ocorreu um erro quando: '
                || V_SQLERRO
                || CHR (13)
                || 'Erro Original: '
                || SQLERRM;
    END;

    FUNCTION F_USA_CENTRO_CUSTO (
        PCODCONTA        IN VARCHAR2,
        PCODPLANOCONTA   IN PCMODELOPC.CODPLANOCONTA%TYPE)
        RETURN BOOLEAN
    IS
        VS_USACENTROCUSTO   VARCHAR2 (1);
    BEGIN
        BEGIN
            SELECT NVL (USACENTROCUSTO, 'N')
              INTO VS_USACENTROCUSTO
              FROM PCMODELOPC
             WHERE     CODPLANOCONTA = PCODPLANOCONTA
                   AND CODREDUZIDO_PC = PCODCONTA;
        EXCEPTION
            WHEN OTHERS
            THEN
                VS_USACENTROCUSTO := 'N';
        END;

        IF VS_USACENTROCUSTO = 'S'
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END;


    /****************************************************************************
      PROCEDURE PARA GERAÇÃO DE 3 - PAGAMENTOS
    *****************************************************************************/
    PROCEDURE P_DADOS_PAGAMENTOS (CURSOR_DADOS     IN     SYS_REFCURSOR,
                                  PCODREGRA        IN     NUMBER,
                                  PCODPLANOCONTA   IN     NUMBER,
                                  RESULTADO           OUT VARCHAR2)
    IS
        TYPE CONSULTA_PAGAMENTOS IS RECORD
        (
            CODFILIAL PCLANC.CODFILIAL%TYPE,
            DATAOPERACAO PCLANC.DTPAGTO%TYPE,
            DATAOPERACAO1 PCMOVCR.DTCOMPENSACAO%TYPE,
            DATAOPERACAO2 PCLANC.DTESTORNOBAIXA%TYPE,
            CODFORNEC PCLANC.CODFORNEC%TYPE,
            FORNECEDOR VARCHAR2 (100),
            HISTORICO PCLANC.HISTORICO%TYPE,
            HISTORICO2 PCLANC.HISTORICO2%TYPE,
            HISTORICOMOVBANCO PCMOVCR.HISTORICO%TYPE,
            HISTORICOMOVBANCO2 PCMOVCR.HISTORICO2%TYPE,
            NUMLANCTO PCLANC.RECNUM%TYPE,
            NUMNOTA PCLANC.NUMNOTA%TYPE,
            DUPLICATA PCLANC.DUPLIC%TYPE,
            VALORTITULO PCLANCAMENTO.VALOR%TYPE,
            VALORPAGO PCLANCAMENTO.VALOR%TYPE,
            VALORDESCONTO PCLANCAMENTO.VALOR%TYPE,
            VALORDESCVERBA PCLANCAMENTO.VALOR%TYPE,
            VALORJUROS PCLANC.TXPERM%TYPE,
            NUMNOTADEVOLUCAO PCLANC.NUMNOTADEV%TYPE,
            NUMBANCO PCLANC.NUMBANCO%TYPE,
            CODBANCO PCMOVCR.CODBANCO%TYPE,
            CODMOEDA PCMOVCR.CODCOB%TYPE,
            NOMEBANCOPGTO PCBANCO.NOME%TYPE,
            TIPODEPAGAMENTO PCLANC.TIPOPAGTO%TYPE,
            CODROTINA PCLANC.CODROTINABAIXA%TYPE,
            CODCONTA PCLANC.CODCONTA%TYPE,
            MOEDA PCLANC.MOEDA%TYPE,
            VALORIRRF PCLANC.VLIRRF%TYPE,
            VALORSESTSENAT PCLANC.VLSESTSENAT%TYPE,
            NUMTRANSOPERACAO NUMBER (10),
            TIPOPARCEIRO PCLANC.TIPOPARCEIRO%TYPE,
            STATUS PCLANC.INDICE%TYPE,
            TIPOLANCAMENTO PCMOVCR.TIPO%TYPE,
            NOMECONTAGERENCIAL PCCONTA.CONTA%TYPE,
            CODCONTARECEITA VARCHAR2 (12),
            NUMDOCTO VARCHAR2 (60),
            CODCONTADESPFORNEC VARCHAR2 (12),
            CONTACONTABILBANCO VARCHAR2 (12),
            TEMINTEGRACAO VARCHAR2 (1),
            VALORVARIACAOCAMBIALPOSITIVA PCLANC.VLVARIACAOCAMBIAL%TYPE,
            VALORVARIACAOCAMBIALNEGATIVA PCLANC.VLVARIACAOCAMBIAL%TYPE,
            NUMEROCONTRATO PCLANC.NUMCONTRATOCAMBIO%TYPE,
            FORNECEDORPRINC VARCHAR2 (100),
            CONTATRANSITORIA PCMODELOPC.CODREDUZIDO_PC%TYPE,
            CODFILIALBANCO PCFILIAL.CODIGO%TYPE,
            ERRO_MULTIFILIAL VARCHAR2 (1),
            VALORDEVOLUCAO PCLANC.VALORDEV%TYPE,
            VALORDESCVERBAMANUAL PCVERBA.VALOR%TYPE,
            GERAPROVLANCCONTAB PCCONTA.GERAPROVLANCCONTAB%TYPE
        );

        ITEM                      CONSULTA_PAGAMENTOS;
        ITENSREGRA                CONSULTA_ITENS;

        CURSOR_ITENS              SYS_REFCURSOR;

        FILIAIS_LANCADAS          TABELAFILIAISLANCTO;
        FILIAIS                   FILIAISLANCTO;

        VS_RECNUM_CENTROCUSTO     VARCHAR2 (12);
        VS_GERARCENTROCUSTO_631   VARCHAR2 (1);
        VS_ERRO_MULTIFILIAL VARCHAR2(1);


        TYPE RECORD_CODREDUZIDO_NUMTRANSCC IS RECORD
        (
            CODREDUZIDO_PC PCLANCINTERMEDIARIA.CODREDUZIDO_PC%TYPE,
            NUMTRANSCC PCLANCINTERMEDIARIA.NUMTRANSCENTROCUSTO%TYPE
        );

        TYPE TABELA_CODREDUZIDO_NUMTRANSCC
            IS TABLE OF RECORD_CODREDUZIDO_NUMTRANSCC;

        CODREDUZIDO_NUMTRANSCC    TABELA_CODREDUZIDO_NUMTRANSCC;

        VS_CONTAIGUAL             VARCHAR2 (1);

        VS_USACONTATRANSITORIA    VARCHAR2 (1);

        VS_CONTA_EXISTE           VARCHAR2 (1);
        VS_CONSIDERARPROVISAO     PCREGRACONTABIL.CONSIDERARPROVISAO%TYPE;

        VD_DATALANCTO_AUX         DATE;
    BEGIN
        LISTA_FORMULAS := TYPE_LISTA_FORMULAS ();
        FILIAIS_LANCADAS := TABELAFILIAISLANCTO ();

        VS_SEQGERADO := 'N';
        VS_FORMADTCONTABILIZACAO := '';
        VN_NUMTRANSACAO := 0;
        VS_DOCUMENTO := '';
        VS_TEMCONTAINEXISTENTE := 'N';
        VS_ERRO_MULTIFILIAL := 'N';

        --BUSCA DADOS DA REGRA
        SELECT FORMADTCONTABILIZACAO,
               BUSCARDADOSPELADATA,
               USACONTATRANSITORIA,
               CONSIDERARPROVISAO
          INTO VS_FORMADTCONTABILIZACAO,
               VS_BUSCARDADOSPELADATA,
               VS_USACONTATRANSITORIA,
               VS_CONSIDERARPROVISAO
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        V_SQLERRO := 'ABRINDO PAGAMENTOS';

        --INICIA LAÇO DOS DADOS
        LOOP
            FETCH CURSOR_DADOS INTO ITEM;

            EXIT WHEN CURSOR_DADOS%NOTFOUND;

            IF    (ITEM.TEMINTEGRACAO IS NULL)
               OR (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                   AND (ITEM.TEMINTEGRACAO = 'P'))
            THEN
                --------------------------------------------------------------------
                --VERIFICA SE ALTEROU O NUMTRANSOPERACAO PARA FAZER GRAVAÇÃO E RE-INICIAR VARIÁVEIS
                IF (VN_NUMTRANSOPERACAO <> ITEM.NUMTRANSOPERACAO)
                THEN
                    VS_SEQGERADO := 'N';

                    VD_DATALANCTO_AUX :=
                        F_RETORNA_DATA_LANCPROVISOES (3,
                                                      PCODREGRA,
                                                      DATA_LANCAMENTO,
                                                      ITEM.DATAOPERACAO,
                                                      ITEM.DATAOPERACAO1,
                                                      ITEM.DATAOPERACAO2);


                    IF (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                        AND (ITEM.TEMINTEGRACAO = 'P'))
                    THEN
                        P_EXCLUI_LANCINTERMEDIARIA_IND (
                            PCODREGRA,
                            ITEM.NUMTRANSOPERACAO,
                            VD_DATALANCTO_AUX);
                    END IF;

                    --VERIFICA SE JÁ PASSOU POR ALGUM REGISTRO PARA ATRIBUIR INCONSISTÊNCIAS
                    IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) >
                       0
                    THEN
                        ---------------------------------------------------------------------------------
                        V_SQLERRO :=
                            '3 - PAGAMENTOS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
                        ---------------------------------------------------------------------------------
                        P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                                    VD_DATALANCTO,
                                                    VS_TEMCONTAINEXISTENTE,
                                                    VN_TOTALDEBITO,
                                                    VN_TOTALCREDITO,
                                                    VS_ERRO_MULTIFILIAL);
                    END IF;

                    VN_TOTALDEBITO := 0;
                    VN_TOTALCREDITO := 0;
                    VS_TEMCONTAINEXISTENTE := 'N';
                END IF;


                --------------------------------------------------------------------

                --GERA NOVO NUMTRANSLANCTO
                IF VS_SEQGERADO = 'N'
                THEN
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '3 - PAGAMENTOS: EXECUTANDO FUNÇÃO GERA_NUM_TRANS_LANCTO()';
                    ---------------------------------------------------------------------------------
                    VN_NUMTRANSACAO := F_GERA_NUM_TRANS_LANCTO ();
                    VS_NUMTRANSCENTROCUSTO := '';

                    VN_NUMSEQ := 0;
                    VN_TOTALCREDITO := 0;
                    VN_TOTALDEBITO := 0;
                    VS_SEQGERADO := 'S';

                    CONTASDEBLANCTO := CONTAS_LANCADAS ();
                    CONTASCRELANCTO := CONTAS_LANCADAS ();
                    CGCSLANCTO := CGC_LANCADOS ();
                    VS_LISTAS_TRANSOTORIAS := CONTAS_LANCADAS ();

                    CONTASDEBLANCTO.EXTEND;
                    CONTASCRELANCTO.EXTEND;

                    CODREDUZIDO_NUMTRANSCC :=
                        TABELA_CODREDUZIDO_NUMTRANSCC ();
                END IF;
                VS_ERRO_MULTIFILIAL := ITEM.ERRO_MULTIFILIAL;
                VD_DATALANCTO :=
                    F_RETORNA_DATA_LANCPROVISOES (3,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO,
                                                  ITEM.DATAOPERACAO1,
                                                  ITEM.DATAOPERACAO2);

                VD_DATAINTEGRACAO :=
                    F_RETORNA_DATA_LANCPROVISOES (3,
                                                  PCODREGRA,
                                                  DATA_INTEGRACAO,
                                                  ITEM.DATAOPERACAO,
                                                  ITEM.DATAOPERACAO1,
                                                  ITEM.DATAOPERACAO2);

                --LAÇO NOS ITENS DA REGRA CONTABIL
                IF VS_USACONTATRANSITORIA = 'S'
                THEN
                    OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL (TRUE)
                        USING PCODREGRA, PCODREGRA, PCODREGRA;
                ELSE
                    OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL (FALSE)
                        USING PCODREGRA;
                END IF;

                LOOP
                    FETCH CURSOR_ITENS INTO ITENSREGRA;

                    EXIT WHEN CURSOR_ITENS%NOTFOUND;

                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '3 - PAGAMENTOS: ATRIBUINDO VALOR DO DOCUMENTO';
                    ---------------------------------------------------------------------------------
                    VS_DOCUMENTO := ITENSREGRA.DOCUMENTO;
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO1',
                                 TO_CHAR (ITEM.DATAOPERACAO1, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO2',
                                 TO_CHAR (ITEM.DATAOPERACAO2, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO',
                                 TO_CHAR (ITEM.DATAOPERACAO, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMLANCTO', ITEM.NUMLANCTO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMNOTA', ITEM.NUMNOTA);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMTRANSOPERACAO',
                                 ITEM.NUMTRANSOPERACAO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMDOCTO', ITEM.NUMDOCTO);

                    --FORMULA INFORMADA NO FILTRO--------------------------------------------------------
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '3 - PAGAMENTOS: ATRIBUINDO VALOR DA FÓRMULA';
                    ---------------------------------------------------------------------------------
                    VN_VALORLANCTO := 0;

                    VS_FORMULA := ITENSREGRA.FORMULAS || ' + 0 ';
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORTITULO([^_[:alnum:]])',
                                        NVL (ITEM.VALORTITULO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORPAGO([^_[:alnum:]])',
                                        NVL (ITEM.VALORPAGO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORDESCONTO([^_[:alnum:]])',
                                        NVL (ITEM.VALORDESCONTO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORDESCVERBA([^_[:alnum:]])',
                                        NVL (ITEM.VALORDESCVERBA, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORJUROS([^_[:alnum:]])',
                                        NVL (ITEM.VALORJUROS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORIRRF([^_[:alnum:]])',
                                        NVL (ITEM.VALORIRRF, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORSESTSENAT([^_[:alnum:]])',
                                        NVL (ITEM.VALORSESTSENAT, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORVARIACAOCAMBIALPOSITIVA([^_[:alnum:]])',
                               NVL (ITEM.VALORVARIACAOCAMBIALPOSITIVA, 0)
                            || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORVARIACAOCAMBIALNEGATIVA([^_[:alnum:]])',
                               NVL (ITEM.VALORVARIACAOCAMBIALNEGATIVA, 0)
                            || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORDEVOLUCAO([^_[:alnum:]])',
                                        NVL (ITEM.VALORDEVOLUCAO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORDESCVERBAMANUAL([^_[:alnum:]])',
                            NVL (ITEM.VALORDESCVERBAMANUAL, 0) || '\1');

                    CALCULAREXPRESSAO;

                    --FIM DA FÓRMULA---------------------------------------------------------------------

                    IF VN_VALORLANCTO <> 0
                    THEN
                        VS_CONTA := TRIM (ITENSREGRA.CODREDUZIDO_PC);

                        IF     (ITEM.CONTATRANSITORIA <> '-1')
                           AND (VS_USACONTATRANSITORIA = 'S')
                        THEN
                            VS_CODFILIAL :=
                                CASE
                                    WHEN     (ITENSREGRA.CODFILIAL =
                                              'FILIALLANCAMENTO')
                                         AND (ITENSREGRA.CODREDUZIDO_PC <>
                                              'CONTACONTABILBANCO')
                                         AND ((ITENSREGRA.CODREDUZIDO_PC <>
                                               'CONTATRANSITORIA'))
                                    THEN
                                        ITEM.CODFILIAL
                                    WHEN     (ITENSREGRA.CODFILIAL =
                                              'FILIALLANCAMENTO')
                                         AND (ITENSREGRA.CODREDUZIDO_PC =
                                              'CONTACONTABILBANCO')
                                    THEN
                                        ITEM.CODFILIALBANCO
                                    WHEN     (ITENSREGRA.CODFILIAL =
                                              'FILIALLANCAMENTO')
                                         AND (    (ITENSREGRA.CODREDUZIDO_PC =
                                                   'CONTATRANSITORIA')
                                              AND (ITEM.CODFILIAL <>
                                                   ITEM.CODFILIALBANCO))
                                    THEN
                                        ITEM.CODFILIAL
                                    WHEN     (ITENSREGRA.CODFILIAL =
                                              'FILIALTRANSITORIA')
                                         AND (ITEM.CODFILIAL <>
                                              ITEM.CODFILIALBANCO)
                                    THEN
                                        ITEM.CODFILIALBANCO
                                    WHEN    (ITENSREGRA.CODFILIAL =
                                             'FILIALTRANSITORIA')
                                         OR (    (ITENSREGRA.CODREDUZIDO_PC =
                                                  'CONTATRANSITORIA')
                                             AND (ITEM.CODFILIAL =
                                                  ITEM.CODFILIALBANCO))
                                    THEN
                                        '-1'
                                    ELSE
                                        ITENSREGRA.CODFILIAL
                                END;
                        ELSE
                            VS_CODFILIAL :=
                                CASE
                                    WHEN (ITENSREGRA.CODFILIAL =
                                          'FILIALLANCAMENTO')
                                    THEN
                                        ITEM.CODFILIAL
                                    WHEN    (ITENSREGRA.CODFILIAL =
                                             'FILIALTRANSITORIA')
                                         OR (ITENSREGRA.CODREDUZIDO_PC =
                                             'CONTATRANSITORIA')
                                    THEN
                                        '-1'
                                    ELSE
                                        ITENSREGRA.CODFILIAL
                                END;
                        END IF;

                        IF VS_CODFILIAL = '-1'
                        THEN
                            GOTO pula_registro;
                        END IF;

                        IF     (SUBSTR (VS_CONTA, 1, 1) <> '0')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '1')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '2')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '3')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '4')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '5')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '6')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '7')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '8')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '9')
                        THEN
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTADESPFORNEC',
                                         ITEM.CODCONTADESPFORNEC);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CONTACONTABILBANCO',
                                         ITEM.CONTACONTABILBANCO);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTARECEITA',
                                         ITEM.CODCONTARECEITA);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CONTATRANSITORIA',
                                         ITEM.CONTATRANSITORIA);

                            VS_CONTAIGUAL := 'N';

                            FOR VN_POSIGUAIS IN 1 ..
                                                VS_LISTAS_TRANSOTORIAS.COUNT
                            LOOP
                                IF VS_LISTAS_TRANSOTORIAS (VN_POSIGUAIS) =
                                   ITEM.CONTATRANSITORIA
                                THEN
                                    VS_CONTAIGUAL := 'S';
                                    EXIT;
                                END IF;
                            END LOOP;

                            IF VS_CONTAIGUAL = 'N'
                            THEN
                                VS_LISTAS_TRANSOTORIAS.EXTEND;
                                VS_LISTAS_TRANSOTORIAS (
                                    VS_LISTAS_TRANSOTORIAS.COUNT) :=
                                    ITEM.CONTATRANSITORIA;
                            END IF;
                        END IF;

                        SELECT NVL (R.GERARCENTROCUSTO_631, 'N')
                          INTO VS_GERARCENTROCUSTO_631
                          FROM PCREGRACONTABIL R
                         WHERE R.CODREGRA = PCODREGRA;

                        IF (   (    (ITEM.CODROTINA = '631')
                                AND (VS_GERARCENTROCUSTO_631 = 'S'))
                            OR (   ITEM.TIPOPARCEIRO IN ('O', 'M')
                                OR (TRIM (ITENSREGRA.FORMULAS) IN
                                        ('VALORJUROS', 'VALORDESCONTO'))) OR 
                                ((ITEM.GERAPROVLANCCONTAB = 'N') AND (VS_CONSIDERARPROVISAO = 'S')))
                        THEN
                            --VERIFICA SE A PERNA DA INTEGRAÇÃO TEM CENTRO DE CUSTO
                            IF F_LANCTO_TEM_CENTROCUSTO (
                                   VS_CONTA,
                                   ITEM.CODCONTA,
                                   3,
                                   0,
                                   1,
                                   TRIM (ITENSREGRA.FORMULAS),
                                   PCODPLANOCONTA) =
                               'S'
                            THEN
                                IF TRIM (ITENSREGRA.FORMULAS) = 'VALORJUROS'
                                THEN
                                    VS_RECNUM_CENTROCUSTO :=
                                        F_RETORNA_RECNUM_JUROS_DESC (
                                            ITEM.NUMLANCTO,
                                            'VALORJUROS');
                                ELSIF TRIM (ITENSREGRA.FORMULAS) =
                                      'VALORDESCONTO'
                                THEN
                                    VS_RECNUM_CENTROCUSTO :=
                                        F_RETORNA_RECNUM_JUROS_DESC (
                                            ITEM.NUMLANCTO,
                                            'VALORDESCONTO');
                                ELSE
                                    VS_RECNUM_CENTROCUSTO := ITEM.NUMLANCTO;
                                END IF;
                            ELSE
                                VS_RECNUM_CENTROCUSTO := '';
                            END IF;
                        ELSE
                            --VERIFICA SE A PERNA DA INTEGRAÇÃO TEM CENTRO DE CUSTO
                            IF F_LANCTO_TEM_CENTROCUSTO (VS_CONTA,
                                                         ITEM.CODCONTA,
                                                         3,
                                                         0,
                                                         0,
                                                         '0',
                                                         PCODPLANOCONTA) =
                               'S'
                            THEN
                                VS_RECNUM_CENTROCUSTO := ITEM.NUMLANCTO;
                            ELSE
                                VS_RECNUM_CENTROCUSTO := '';
                            END IF;
                        END IF;

                        IF VS_CONTA = '-1' /*Usa conta transitória, mas o lançamento em questão não tem conta transitória*/
                        THEN
                            VS_CONTA_EXISTE := 'T';
                        ELSE
                            VS_CONTA_EXISTE :=
                                F_VERIFICA_CONTA_EXISTE (VS_CONTA,
                                                         PCODPLANOCONTA);
                            TRATAR_CONTA_INEXISTENTE (VS_CONTA_EXISTE,
                                                      VS_TEMCONTAINEXISTENTE);
                        END IF;

                        IF VS_CONTA_EXISTE IN ('S', 'I', 'X')
                        THEN
                            --HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO---------------------------------------
                            ---------------------------------------------------------------------------------
                            V_SQLERRO :=
                                '3 - PAGAMENTOS: ATRIBUINDO VALOR DE HISTÓRICOS';
                            ---------------------------------------------------------------------------------
                            VS_HISTORICO := ITENSREGRA.HISTCOMPLREGRA;

                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[FORNECEDOR]',
                                         ITEM.FORNECEDOR);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO1]',
                                         ITEM.DATAOPERACAO1);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO2]',
                                         ITEM.DATAOPERACAO2);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO]',
                                         ITEM.DATAOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[HISTORICO]',
                                         ITEM.HISTORICO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[HISTORICO2]',
                                         ITEM.HISTORICO2);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[HISTORICOMOVBANCO2]',
                                         ITEM.HISTORICOMOVBANCO2);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[HISTORICOMOVBANCO]',
                                         ITEM.HISTORICOMOVBANCO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMLANCTO]',
                                         ITEM.NUMLANCTO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMNOTA]',
                                         ITEM.NUMNOTA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DUPLICATA]',
                                         ITEM.DUPLICATA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMNOTADEVOLUCAO]',
                                         ITEM.NUMNOTADEVOLUCAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMBANCO]',
                                         ITEM.NUMBANCO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODBANCO]',
                                         ITEM.CODBANCO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NOMEBANCOPGTO]',
                                         ITEM.NOMEBANCOPGTO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[TIPODEPAGAMENTO]',
                                         ITEM.TIPODEPAGAMENTO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[STATUS]',
                                         ITEM.STATUS);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMDOCTO]',
                                         ITEM.NUMDOCTO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMTRANSOPERACAO]',
                                         ITEM.NUMTRANSOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NOMECONTAGERENCIAL]',
                                         ITEM.NOMECONTAGERENCIAL);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODFORNEC]',
                                         ITEM.CODFORNEC);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[FORNECEDORPRINC]',
                                         ITEM.FORNECEDORPRINC);
                            VS_HISTORICO := SUBSTR (VS_HISTORICO, 1, 200);

                            --FIM HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO-----------------------------------

                            IF ITENSREGRA.NATUREZA = 'C'
                            THEN
                                --VN_TOTALCREDITO := ROUND(VN_TOTALCREDITO + ABS(VN_VALORLANCTO), 2);

                                IF VN_VALORLANCTO < 0
                                THEN
                                    VS_NATUREZA := 'D';
                                ELSE
                                    VS_NATUREZA := 'C';
                                END IF;
                            ELSE
                                --VN_TOTALDEBITO := ROUND(VN_TOTALDEBITO + ABS(VN_VALORLANCTO), 2);

                                IF VN_VALORLANCTO < 0
                                THEN
                                    VS_NATUREZA := 'C';
                                ELSE
                                    VS_NATUREZA := 'D';
                                END IF;
                            END IF;

                            IF VS_NATUREZA = 'C'
                            THEN
                                VN_TOTALCREDITO :=
                                    ROUND (
                                          VN_TOTALCREDITO
                                        + ABS (VN_VALORLANCTO),
                                        2);
                            ELSE
                                VN_TOTALDEBITO :=
                                    ROUND (
                                        VN_TOTALDEBITO + ABS (VN_VALORLANCTO),
                                        2);
                            END IF;

                            --GUARDA FILIAIS
                            FILIAIS.CODFILIAL := '-1';

                            FOR VN_POSICAO IN 1 .. FILIAIS_LANCADAS.COUNT
                            LOOP
                                IF (FILIAIS_LANCADAS (VN_POSICAO).CODFILIAL =
                                    VS_CODFILIAL)
                                THEN
                                    FILIAIS := FILIAIS_LANCADAS (VN_POSICAO);
                                    VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

                                    EXIT;
                                END IF;
                            END LOOP;

                            IF (FILIAIS.CODFILIAL = '-1')
                            THEN
                                FILIAIS_LANCADAS.EXTEND;

                                FILIAIS :=
                                    FILIAIS_LANCADAS (FILIAIS_LANCADAS.COUNT);
                                VN_POSICAO_EM_ALTERACAO :=
                                    FILIAIS_LANCADAS.COUNT;

                                FILIAIS.CODFILIAL := VS_CODFILIAL;
                                FILIAIS.CGCFILIAL :=
                                    F_CGCFILIAL (VS_CODFILIAL);

                                FILIAIS_LANCADAS (VN_POSICAO_EM_ALTERACAO) :=
                                    FILIAIS;
                            END IF;

                            --GUARDA AS CONTAS PARA VERIFICAR SE ESTÃO IGUAIS POSTERIORMENTE
                            P_ARMAZENA_CONTAS_FILIAIS_LANC (VS_CONTA,
                                                            VS_NATUREZA,
                                                            VS_CODFILIAL,
                                                            FILIAIS_LANCADAS);

                            IF 'N' = 'S'
                            THEN
                                NULL;
                            ELSE
                                ---------------------------------------------------------------------------------
                                V_SQLERRO :=
                                    '3 - PAGAMENTOS: EXECUTANDO PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA()';

                                ---------------------------------------------------------------------------------
                                --INSERE CENTRO DE CUSTO
                                IF VS_RECNUM_CENTROCUSTO IS NOT NULL
                                THEN
                                    IF VS_NUMTRANSCENTROCUSTO IS NULL
                                    THEN
                                        VS_NUMTRANSCENTROCUSTO :=
                                            F_RETORNA_NUMTRANS_CENTROCUSTO ();
                                    END IF;
                                END IF;

                                --INSERE DADOS NA TABELA QUANDO NÃO ESTÁ TOTALIZANDO VALORES
                                VN_NUMSEQ := VN_NUMSEQ + 1;

                                P_GRAVA_DADOS_TABINTERMEDIARIA (
                                    VS_CODFILIAL,
                                    VN_NUMTRANSACAO,
                                    VN_NUMSEQ,
                                    VD_DATALANCTO,
                                    VS_DOCUMENTO,
                                    ITENSREGRA.CODHISTORICO,
                                    VS_HISTORICO,
                                    PCODPLANOCONTA,
                                    VS_CONTA,
                                    VS_NATUREZA,
                                    ABS (VN_VALORLANCTO),
                                    PCODREGRA,
                                    '',
                                    ITEM.NUMTRANSOPERACAO,
                                    F_RETORNA_TIPO_INCONSISTENCIA (
                                        VS_TEMCONTAINEXISTENTE),
                                    'P',
                                    VD_DATAINTEGRACAO,
                                    0,
                                    ITEM.CODBANCO,
                                    ITEM.CODMOEDA,
                                    VS_NUMTRANSCENTROCUSTO,
                                    TRUNC (SYSDATE),
                                    ITEM.CODFORNEC,
                                    ITEM.TIPOPARCEIRO,
                                    NULL,
                                    ITEM.NUMLANCTO,
                                    '',
                                    ITENSREGRA.FORMULAS,
                                    ITENSREGRA.CODREDUZIDO_PC,
                                    'CPAGAR',
                                    'PCLANC',
                                    ITENSREGRA.TOTALIZAVALOR);

                                IF VS_RECNUM_CENTROCUSTO IS NOT NULL
                                THEN
                                    IF ITEM.TIPOPARCEIRO NOT IN ('O', 'M')
                                    THEN
                                        P_GRAVA_PCINTER_CENTROCUSTO (
                                            VS_RECNUM_CENTROCUSTO,
                                            VS_NUMTRANSCENTROCUSTO,
                                            PCODREGRA,
                                            (CASE
                                                 WHEN VS_BUSCARDADOSPELADATA =
                                                      'C'
                                                 THEN
                                                     NVL (ITEM.DATAOPERACAO1,
                                                          ITEM.DATAOPERACAO)
                                                 ELSE
                                                     ITEM.DATAOPERACAO
                                             END),
                                            FALSE,
                                            0,
                                            '',
                                               VS_HISTORICO
                                            || vs_conta
                                            || VS_CODFILIAL,
                                            0);
                                    ELSE
                                        P_GRAVA_PCINTER_CENTROCUSTO (
                                            VS_RECNUM_CENTROCUSTO,
                                            VS_NUMTRANSCENTROCUSTO,
                                            PCODREGRA,
                                            (CASE
                                                 WHEN VS_BUSCARDADOSPELADATA =
                                                      'C'
                                                 THEN
                                                     NVL (ITEM.DATAOPERACAO1,
                                                          ITEM.DATAOPERACAO)
                                                 ELSE
                                                     ITEM.DATAOPERACAO
                                             END),
                                            FALSE,
                                            ABS (VN_VALORLANCTO),
                                            VN_NUMTRANSACAO,
                                               VS_HISTORICO
                                            || vs_conta
                                            || VS_CODFILIAL,
                                            0);
                                    END IF;
                                END IF;

                                VS_NUMTRANSCENTROCUSTO := '';
                            END IF;
                        END IF;
                    END IF;

                   <<pula_registro>>
                    NULL;
                END LOOP;
            END IF;

            --GUARDA VARIAVEIS
            VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
        END LOOP;

        --VERIFICA CONSISTÊNCIAS DO ÚLTIMO REGISTRO
        IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '3 - PAGAMENTOS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
            ---------------------------------------------------------------------------------
            P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                        VD_DATALANCTO,
                                        VS_TEMCONTAINEXISTENTE,
                                        VN_TOTALDEBITO,
                                        VN_TOTALCREDITO,
                                        ITEM.ERRO_MULTIFILIAL);
        END IF;

        CLOSE CURSOR_DADOS;

        RESULTADO := 'OK';
    EXCEPTION
        WHEN OTHERS
        THEN
            RESULTADO :=
                   'Ocorreu um erro quando: '
                || V_SQLERRO
                || CHR (13)
                || 'Erro Original: '
                || SQLERRM;
    END;

    /****************************************************************************
      PROCEDURE PARA GERAÇÃO DE 4 - RECEBIMENTOS
    *****************************************************************************/
    PROCEDURE P_DADOS_RECEBIMENTOS (CURSOR_DADOS     IN     SYS_REFCURSOR,
                                    PCODREGRA        IN     NUMBER,
                                    PCODPLANOCONTA   IN     NUMBER,
                                    RESULTADO           OUT VARCHAR2)
    IS
        TYPE CONSULTA_RECEBIMENTOS IS RECORD
        (
            CODFILIAL VARCHAR2 (2),
            DATAOPERACAO DATE,
            DATAOPERACAO1 DATE,
            DATAPGTO DATE,
            DATAVENCIMENTO DATE,
            DATADEVOLUCAO DATE,
            VALORMOVIMENTACAOBCO PCLANCAMENTO.VALOR%TYPE,
            VALORTITULO PCLANCAMENTO.VALOR%TYPE,
            VALORPAGO PCLANCAMENTO.VALOR%TYPE,
            VALORJUROS PCLANCAMENTO.VALOR%TYPE,
            VALORDESCONTO PCLANCAMENTO.VALOR%TYPE,
            VALORDEVOLUCAO PCLANCAMENTO.VALOR%TYPE,
            VALORDESPCARTORAIS PCLANCAMENTO.VALOR%TYPE,
            VALORDESPBANCARIAS PCLANCAMENTO.VALOR%TYPE,
            VALOROUTROSACRESC PCLANCAMENTO.VALOR%TYPE,
            VALORIMPRENDAORGPUB PCLANCAMENTO.VALOR%TYPE,
            VALORCONTSOCIALORGPUB PCLANCAMENTO.VALOR%TYPE,
            VALORPISORGPUB PCLANCAMENTO.VALOR%TYPE,
            VALORCOFINSORGPUB PCLANCAMENTO.VALOR%TYPE,
            VALORICMSRETORGPUB PCLANCAMENTO.VALOR%TYPE,
            VALOROUTRASDEDUCOESORGPUB PCLANCAMENTO.VALOR%TYPE,
            VALORTAXABOLETO PCLANCAMENTO.VALOR%TYPE,
            CODBANCO NUMBER (4),
            DUPLICATA NUMBER (10),
            PRESTACAO VARCHAR2 (2),
            CLIENTE PCCLIENT.CLIENTE%TYPE,
            CODCLIENTE PCCLIENT.CODCLI%TYPE,
            CODMOEDA VARCHAR2 (4),
            CODCOBRANCA VARCHAR2 (4),
            CODCOBRANCAORIGINAL PCPREST.CODCOBORIG%TYPE,
            CODCOBRANCANF PCNFSAID.CODCOB%TYPE,
            HISTORICOMOVIMENTACAOBANCARIA PCMOVCR.HISTORICO%TYPE,
            HISTMOVBANCARIACLIENTE PCMOVCR.HISTORICO2%TYPE,
            ROTINALANCAMENTO NUMBER (6),
            NUMCONTABANCO VARCHAR2 (10),
            STATUS VARCHAR2 (1),
            STATUSTITULO VARCHAR2 (1),
            BANCOBAIXA VARCHAR2 (30),
            NUMTRANSOPERACAO NUMBER (10),
            TIPOOPERACAO CHAR (1),
            CONTACONTABILBANCO VARCHAR2 (12),
            VENDAASSISTIDA VARCHAR2 (1),
            NUMTRANSVENDA PCPREST.NUMTRANSVENDA%TYPE,
            CODCONTACONTABIL VARCHAR2 (12),
            TEMINTEGRACAO VARCHAR2 (1),
            VALORMULTA NUMBER (10, 2),
            CONTATRANSITORIA PCMODELOPC.CODREDUZIDO_PC%TYPE,
            CODFILIALBANCO PCFILIAL.CODIGO%TYPE,
            ERRO_MULTIFILIAL VARCHAR2 (1)
        );



        ITEM                     CONSULTA_RECEBIMENTOS;
        ITENSREGRA               CONSULTA_ITENS;

        CURSOR_ITENS             SYS_REFCURSOR;

        FILIAIS_LANCADAS         TABELAFILIAISLANCTO;
        FILIAIS                  FILIAISLANCTO;
        VS_RECNUM_CENTROCUSTO    VARCHAR2 (12);
        VB_ECONTA_PREDEFINIDA    BOOLEAN;
        VS_ERRO_MULTIFILIAL VARCHAR2(1);

        TYPE RECORD_CODREDUZIDO_NUMTRANSCC IS RECORD
        (
            CODREDUZIDO_PC PCLANCINTERMEDIARIA.CODREDUZIDO_PC%TYPE,
            NUMTRANSCC PCLANCINTERMEDIARIA.NUMTRANSCENTROCUSTO%TYPE
        );

        TYPE TABELA_CODREDUZIDO_NUMTRANSCC
            IS TABLE OF RECORD_CODREDUZIDO_NUMTRANSCC;

        CODREDUZIDO_NUMTRANSCC   TABELA_CODREDUZIDO_NUMTRANSCC;

        VS_CONTAIGUAL            VARCHAR2 (1);
        VS_USACONTATRANSITORIA   VARCHAR2 (1);

        VS_CONTA_EXISTE          VARCHAR2 (1);
        VD_DATALANCTO_AUX        DATE;
    BEGIN
        LISTA_FORMULAS := TYPE_LISTA_FORMULAS ();
        FILIAIS_LANCADAS := TABELAFILIAISLANCTO ();

        VS_SEQGERADO := 'N';
        VS_FORMADTCONTABILIZACAO := '';
        VN_NUMTRANSACAO := 0;
        VS_DOCUMENTO := '';
        VB_ECONTA_PREDEFINIDA := FALSE;
        VS_TEMCONTAINEXISTENTE := 'N';
        VS_ERRO_MULTIFILIAL := 'N';

        --BUSCA DADOS DA REGRA
        SELECT FORMADTCONTABILIZACAO,
               BUSCARDADOSPELADATA,
               USACONTATRANSITORIA
          INTO VS_FORMADTCONTABILIZACAO,
               VS_BUSCARDADOSPELADATA,
               VS_USACONTATRANSITORIA
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        V_SQLERRO := 'ABRINDO RECEBIMENTOS';

        --INICIA LAÇO DOS DADOS
        LOOP
            FETCH CURSOR_DADOS INTO ITEM;

            EXIT WHEN CURSOR_DADOS%NOTFOUND;

            IF    (ITEM.TEMINTEGRACAO IS NULL)
               OR (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                   AND (ITEM.TEMINTEGRACAO = 'P'))
            THEN
                --PEGA DATA DE LANÇAMENTO DE ACORDO COM SELECIONADO NA REGRA

                VD_DATALANCTO_AUX :=
                    F_RETORNA_DATA_LANCPROVISOES (4,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO,
                                                  ITEM.DATAOPERACAO1,
                                                  NULL,
                                                  NULL,
                                                  ITEM.DATAPGTO);

                --------------------------------------------------------------------
                --VERIFICA SE ALTEROU O NUMTRANSOPERACAO PARA FAZER GRAVAÇÃO E RE-INICIAR VARIÁVEIS
                IF    (VN_NUMTRANSOPERACAO <> ITEM.NUMTRANSOPERACAO)
                   OR (    (VN_NUMTRANSOPERACAO = ITEM.NUMTRANSOPERACAO)
                       AND (VS_FORMADTCONTABILIZACAO = 'P')
                       AND (VD_DATALANCTO <> ITEM.DATAPGTO))
                THEN
                    VS_SEQGERADO := 'N';

                    IF (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                        AND (ITEM.TEMINTEGRACAO = 'P'))
                    THEN
                        P_EXCLUI_LANCINTERMEDIARIA_IND (
                            PCODREGRA,
                            ITEM.NUMTRANSOPERACAO,
                            VD_DATALANCTO_AUX);
                    END IF;

                    --VERIFICA SE JÁ PASSOU POR ALGUM REGISTRO PARA ATRIBUIR INCONSISTÊNCIAS
                    IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) >
                       0
                    THEN
                        ---------------------------------------------------------------------------------
                        V_SQLERRO :=
                            '4 - RECEBIMENTOS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
                        ---------------------------------------------------------------------------------
                        P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                                    VD_DATALANCTO,
                                                    VS_TEMCONTAINEXISTENTE,
                                                    VN_TOTALDEBITO,
                                                    VN_TOTALCREDITO,
                                                    VS_ERRO_MULTIFILIAL);
                    END IF;

                    VS_TEMCONTAINEXISTENTE := 'N';
                END IF;

                --------------------------------------------------------------------

                --GERA NOVO NUMTRANSLANCTO
                IF VS_SEQGERADO = 'N'
                THEN
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '4 - RECEBIMENTOS: EXECUTANDO FUNÇÃO GERA_NUM_TRANS_LANCTO()';
                    ---------------------------------------------------------------------------------
                    VN_NUMTRANSACAO := F_GERA_NUM_TRANS_LANCTO ();
                    VS_NUMTRANSCENTROCUSTO := '';

                    VN_NUMSEQ := 0;
                    VN_TOTALCREDITO := 0;
                    VN_TOTALDEBITO := 0;
                    VS_SEQGERADO := 'S';

                    CONTASDEBLANCTO := CONTAS_LANCADAS ();
                    CONTASCRELANCTO := CONTAS_LANCADAS ();
                    CGCSLANCTO := CGC_LANCADOS ();
                    VS_LISTAS_TRANSOTORIAS := CONTAS_LANCADAS ();

                    CONTASDEBLANCTO.EXTEND;
                    CONTASCRELANCTO.EXTEND;
                    CODREDUZIDO_NUMTRANSCC :=
                        TABELA_CODREDUZIDO_NUMTRANSCC ();
                END IF;
                VS_ERRO_MULTIFILIAL := ITEM.ERRO_MULTIFILIAL;
                --PEGA DATA DE LANÇAMENTO DE ACORDO COM SELECIONADO NA REGRA
                VD_DATALANCTO :=
                    F_RETORNA_DATA_LANCPROVISOES (4,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO,
                                                  ITEM.DATAOPERACAO1,
                                                  NULL,
                                                  NULL,
                                                  ITEM.DATAPGTO);

                VD_DATAINTEGRACAO :=
                    F_RETORNA_DATA_LANCPROVISOES (4,
                                                  PCODREGRA,
                                                  DATA_INTEGRACAO,
                                                  ITEM.DATAOPERACAO,
                                                  ITEM.DATAOPERACAO1,
                                                  NULL,
                                                  NULL,
                                                  ITEM.DATAPGTO);

                --LAÇO NOS ITENS DA REGRA CONTABIL
                IF VS_USACONTATRANSITORIA = 'S'
                THEN
                    OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL (TRUE)
                        USING PCODREGRA, PCODREGRA, PCODREGRA;
                ELSE
                    OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL (FALSE)
                        USING PCODREGRA;
                END IF;

                LOOP
                    FETCH CURSOR_ITENS INTO ITENSREGRA;

                    EXIT WHEN CURSOR_ITENS%NOTFOUND;

                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '4 - RECEBIMENTOS: ATRIBUINDO VALOR DO DOCUMENTO';
                    ---------------------------------------------------------------------------------
                    VS_DOCUMENTO := ITENSREGRA.DOCUMENTO;
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAPGTO',
                                 TO_CHAR (ITEM.DATAPGTO, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAVENCIMENTO',
                                 TO_CHAR (ITEM.DATAVENCIMENTO, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'DUPLICATA', ITEM.DUPLICATA);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMTRANSOPERACAO',
                                 ITEM.NUMTRANSOPERACAO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO1',
                                 TO_CHAR (ITEM.DATAOPERACAO1, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO',
                                 TO_CHAR (ITEM.DATAOPERACAO, 'DD-MM-YYYY'));

                    --FORMULA INFORMADA NO FILTRO--------------------------------------------------------
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '4 - RECEBIMENTOS: ATRIBUINDO VALOR DA FÓRMULA';
                    ---------------------------------------------------------------------------------
                    VN_VALORLANCTO := 0;

                    VS_FORMULA := ITENSREGRA.FORMULAS || ' + 0 ';
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORMOVIMENTACAOBCO([^_[:alnum:]])',
                            NVL (ITEM.VALORMOVIMENTACAOBCO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORTITULO([^_[:alnum:]])',
                                        NVL (ITEM.VALORTITULO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORPAGO([^_[:alnum:]])',
                                        NVL (ITEM.VALORPAGO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORJUROS([^_[:alnum:]])',
                                        NVL (ITEM.VALORJUROS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORDESCONTO([^_[:alnum:]])',
                                        NVL (ITEM.VALORDESCONTO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORDEVOLUCAO([^_[:alnum:]])',
                                        NVL (ITEM.VALORDEVOLUCAO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORDESPCARTORAIS([^_[:alnum:]])',
                            NVL (ITEM.VALORDESPCARTORAIS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORDESPBANCARIAS([^_[:alnum:]])',
                            NVL (ITEM.VALORDESPBANCARIAS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALOROUTROSACRESC([^_[:alnum:]])',
                            NVL (ITEM.VALOROUTROSACRESC, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORIMPRENDAORGPUB([^_[:alnum:]])',
                            NVL (ITEM.VALORIMPRENDAORGPUB, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORCONTSOCIALORGPUB([^_[:alnum:]])',
                            NVL (ITEM.VALORCONTSOCIALORGPUB, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORPISORGPUB([^_[:alnum:]])',
                                        NVL (ITEM.VALORPISORGPUB, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORCOFINSORGPUB([^_[:alnum:]])',
                            NVL (ITEM.VALORCOFINSORGPUB, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORICMSRETORGPUB([^_[:alnum:]])',
                            NVL (ITEM.VALORICMSRETORGPUB, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALOROUTRASDEDUCOESORGPUB([^_[:alnum:]])',
                            NVL (ITEM.VALOROUTRASDEDUCOESORGPUB, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORTAXABOLETO([^_[:alnum:]])',
                            NVL (ITEM.VALORTAXABOLETO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORMULTA([^_[:alnum:]])',
                                        NVL (ITEM.VALORMULTA, 0) || '\1');

                    CALCULAREXPRESSAO;

                    --FIM DA FÓRMULA---------------------------------------------------------------------

                    IF VN_VALORLANCTO <> 0
                    THEN
                        VS_CONTA := TRIM (ITENSREGRA.CODREDUZIDO_PC);

                        IF     (ITEM.CONTATRANSITORIA <> '-1')
                           AND (VS_USACONTATRANSITORIA = 'S')
                        THEN
                            VS_CODFILIAL :=
                                CASE
                                    WHEN     (ITENSREGRA.CODFILIAL =
                                              'FILIALLANCAMENTO')
                                         AND (ITENSREGRA.CODREDUZIDO_PC <>
                                              'CONTACONTABILBANCO')
                                         AND ((ITENSREGRA.CODREDUZIDO_PC <>
                                               'CONTATRANSITORIA'))
                                    THEN
                                        ITEM.CODFILIAL
                                    WHEN     (ITENSREGRA.CODFILIAL =
                                              'FILIALLANCAMENTO')
                                         AND (ITENSREGRA.CODREDUZIDO_PC =
                                              'CONTACONTABILBANCO')
                                    THEN
                                        ITEM.CODFILIALBANCO
                                    WHEN     (ITENSREGRA.CODFILIAL =
                                              'FILIALLANCAMENTO')
                                         AND (    (ITENSREGRA.CODREDUZIDO_PC =
                                                   'CONTATRANSITORIA')
                                              AND (ITEM.CODFILIAL <>
                                                   ITEM.CODFILIALBANCO))
                                    THEN
                                        ITEM.CODFILIAL
                                    WHEN     (ITENSREGRA.CODFILIAL =
                                              'FILIALTRANSITORIA')
                                         AND (ITEM.CODFILIAL <>
                                              ITEM.CODFILIALBANCO)
                                    THEN
                                        ITEM.CODFILIALBANCO
                                    WHEN    (ITENSREGRA.CODFILIAL =
                                             'FILIALTRANSITORIA')
                                         OR (    (ITENSREGRA.CODREDUZIDO_PC =
                                                  'CONTATRANSITORIA')
                                             AND (ITEM.CODFILIAL =
                                                  ITEM.CODFILIALBANCO))
                                    THEN
                                        '-1'
                                    ELSE
                                        ITENSREGRA.CODFILIAL
                                END;
                        ELSE
                            VS_CODFILIAL :=
                                CASE
                                    WHEN (ITENSREGRA.CODFILIAL =
                                          'FILIALLANCAMENTO')
                                    THEN
                                        ITEM.CODFILIAL
                                    WHEN    (ITENSREGRA.CODFILIAL =
                                             'FILIALTRANSITORIA')
                                         OR (ITENSREGRA.CODREDUZIDO_PC =
                                             'CONTATRANSITORIA')
                                    THEN
                                        '-1'
                                    ELSE
                                        ITENSREGRA.CODFILIAL
                                END;
                        END IF;

                        IF VS_CODFILIAL = '-1'
                        THEN
                            GOTO pula_registro;
                        END IF;


                        VB_ECONTA_PREDEFINIDA := FALSE;

                        IF     (SUBSTR (VS_CONTA, 1, 1) <> '0')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '1')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '2')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '3')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '4')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '5')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '6')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '7')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '8')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '9')
                        THEN
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTACONTABIL',
                                         ITEM.CODCONTACONTABIL);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CONTACONTABILBANCO',
                                         ITEM.CONTACONTABILBANCO);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CONTATRANSITORIA',
                                         ITEM.CONTATRANSITORIA);
                            VB_ECONTA_PREDEFINIDA := TRUE;

                            VS_CONTAIGUAL := 'N';

                            FOR VN_POSIGUAIS IN 1 ..
                                                VS_LISTAS_TRANSOTORIAS.COUNT
                            LOOP
                                IF VS_LISTAS_TRANSOTORIAS (VN_POSIGUAIS) =
                                   ITEM.CONTATRANSITORIA
                                THEN
                                    VS_CONTAIGUAL := 'S';
                                    EXIT;
                                END IF;
                            END LOOP;

                            IF VS_CONTAIGUAL = 'N'
                            THEN
                                VS_LISTAS_TRANSOTORIAS.EXTEND;
                                VS_LISTAS_TRANSOTORIAS (
                                    VS_LISTAS_TRANSOTORIAS.COUNT) :=
                                    ITEM.CONTATRANSITORIA;
                            END IF;
                        END IF;

                        IF VS_CONTA = '-1' /*Usa conta transitória, mas o lançamento em questão não tem conta transitória*/
                        THEN
                            VS_CONTA_EXISTE := 'T';
                        ELSE
                            VS_CONTA_EXISTE :=
                                F_VERIFICA_CONTA_EXISTE (VS_CONTA,
                                                         PCODPLANOCONTA);
                            TRATAR_CONTA_INEXISTENTE (VS_CONTA_EXISTE,
                                                      VS_TEMCONTAINEXISTENTE);
                        END IF;

                        IF VS_CONTA_EXISTE IN ('S', 'I', 'X')
                        THEN
                            --HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO---------------------------------------
                            ---------------------------------------------------------------------------------
                            V_SQLERRO :=
                                '4 - RECEBIMENTOS: ATRIBUINDO VALOR DE HISTÓRICOS';
                            ---------------------------------------------------------------------------------
                            VS_HISTORICO := ITENSREGRA.HISTCOMPLREGRA;
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO1]',
                                         ITEM.DATAOPERACAO1);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO]',
                                         ITEM.DATAOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAPGTO]',
                                         ITEM.DATAPGTO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAVENCIMENTO]',
                                         ITEM.DATAVENCIMENTO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATADEVOLUCAO]',
                                         ITEM.DATADEVOLUCAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODBANCO]',
                                         ITEM.CODBANCO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DUPLICATA]',
                                         ITEM.DUPLICATA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[PRESTACAO]',
                                         ITEM.PRESTACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CLIENTE]',
                                         ITEM.CLIENTE);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODMOEDA]',
                                         ITEM.CODMOEDA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODCOBRANCA]',
                                         ITEM.CODCOBRANCA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[HISTORICOMOVIMENTACAOBANCARIA]',
                                         ITEM.HISTORICOMOVIMENTACAOBANCARIA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[HISTMOVBANCARIACLIENTE]',
                                         ITEM.HISTMOVBANCARIACLIENTE);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMCONTABANCO]',
                                         ITEM.NUMCONTABANCO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[STATUS]',
                                         ITEM.STATUS);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[BANCOBAIXA]',
                                         ITEM.BANCOBAIXA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMTRANSOPERACAO]',
                                         ITEM.NUMTRANSOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[VENDAASSISTIDA]',
                                         ITEM.VENDAASSISTIDA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODCLIENTE]',
                                         ITEM.CODCLIENTE);
                            VS_HISTORICO := SUBSTR (VS_HISTORICO, 1, 200);

                            --FIM HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO-----------------------------------

                            IF ITENSREGRA.NATUREZA = 'C'
                            THEN
                                --VN_TOTALCREDITO := ROUND(VN_TOTALCREDITO + ABS(VN_VALORLANCTO), 2);

                                IF VN_VALORLANCTO < 0
                                THEN
                                    VS_NATUREZA := 'D';
                                ELSE
                                    VS_NATUREZA := 'C';
                                END IF;
                            ELSE
                                --VN_TOTALDEBITO := ROUND(VN_TOTALDEBITO + ABS(VN_VALORLANCTO), 2);

                                IF VN_VALORLANCTO < 0
                                THEN
                                    VS_NATUREZA := 'C';
                                ELSE
                                    VS_NATUREZA := 'D';
                                END IF;
                            END IF;

                            IF VS_NATUREZA = 'C'
                            THEN
                                VN_TOTALCREDITO :=
                                    ROUND (
                                          VN_TOTALCREDITO
                                        + ABS (VN_VALORLANCTO),
                                        2);
                            ELSE
                                VN_TOTALDEBITO :=
                                    ROUND (
                                        VN_TOTALDEBITO + ABS (VN_VALORLANCTO),
                                        2);
                            END IF;

                            --GUARDA FILIAIS
                            FILIAIS.CODFILIAL := '-1';

                            FOR VN_POSICAO IN 1 .. FILIAIS_LANCADAS.COUNT
                            LOOP
                                IF (FILIAIS_LANCADAS (VN_POSICAO).CODFILIAL =
                                    VS_CODFILIAL)
                                THEN
                                    FILIAIS := FILIAIS_LANCADAS (VN_POSICAO);
                                    VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

                                    EXIT;
                                END IF;
                            END LOOP;

                            IF (FILIAIS.CODFILIAL = '-1')
                            THEN
                                FILIAIS_LANCADAS.EXTEND;

                                FILIAIS :=
                                    FILIAIS_LANCADAS (FILIAIS_LANCADAS.COUNT);
                                VN_POSICAO_EM_ALTERACAO :=
                                    FILIAIS_LANCADAS.COUNT;

                                FILIAIS.CODFILIAL := VS_CODFILIAL;
                                FILIAIS.CGCFILIAL :=
                                    F_CGCFILIAL (VS_CODFILIAL);

                                FILIAIS_LANCADAS (VN_POSICAO_EM_ALTERACAO) :=
                                    FILIAIS;
                            END IF;

                            --GUARDA AS CONTAS PARA VERIFICAR SE ESTÃO IGUAIS POSTERIORMENTE
                            P_ARMAZENA_CONTAS_FILIAIS_LANC (VS_CONTA,
                                                            VS_NATUREZA,
                                                            VS_CODFILIAL,
                                                            FILIAIS_LANCADAS);

                            IF 'N' = 'S'
                            THEN
                                NULL;
                            ELSE
                                ---------------------------------------------------------------------------------
                                V_SQLERRO :=
                                    '4 - RECEBIMENTOS: EXECUTANDO PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA()';
                                ---------------------------------------------------------------------------------
                                VS_RECNUM_CENTROCUSTO := '';

                                -- Se tem desconto e se o campo VALORDESCONTO consta na formula
                                IF     (NOT VB_ECONTA_PREDEFINIDA)
                                   AND F_USA_CENTRO_CUSTO (VS_CONTA,
                                                           PCODPLANOCONTA)
                                   AND (ITEM.VALORDESCONTO > 0)
                                   AND (TRIM (ITENSREGRA.FORMULAS) =
                                        'VALORDESCONTO')
                                THEN
                                    BEGIN
                                        SELECT RECNUM
                                          INTO VS_RECNUM_CENTROCUSTO
                                          FROM PCLANC, PCCONSUM
                                         WHERE     PCLANC.DUPLIC =
                                                   SUBSTR (ITEM.PRESTACAO,
                                                           1,
                                                           1)
                                               AND PCLANC.LOCALIZACAO =
                                                   TO_CHAR (
                                                       ITEM.NUMTRANSVENDA)
                                               AND PCLANC.NUMNOTA =
                                                   ITEM.DUPLICATA
                                               AND PCLANC.NUMTRANS =
                                                   ITEM.NUMTRANSOPERACAO
                                               AND PCLANC.HISTORICO LIKE
                                                          '%'
                                                       || ITEM.NUMTRANSVENDA
                                                       || '-'
                                                       || ITEM.PRESTACAO
                                               AND (   (PCLANC.CODCONTA IN
                                                            (PCCONSUM.CODCONTADESCCR,
                                                             PCCONSUM.CODCONTDESCCONC))
                                                    OR (PCLANC.CODCONTA IN
                                                            (PCCONSUM.CODCONTADESCCR,
                                                             PCCONSUM.CODCONTADESCCR))
                                                    OR (EXISTS
                                                            (SELECT 1
                                                               FROM PCCOB C
                                                              WHERE     C.CARTAO =
                                                                        'S'
                                                                    AND C.CODCONTACC =
                                                                        PCLANC.CODCONTA)))
                                               AND ROWNUM = 1;
                                    EXCEPTION
                                        WHEN NO_DATA_FOUND
                                        THEN
                                            VS_RECNUM_CENTROCUSTO := NULL;
                                    END;

                                    --INSERE CENTRO DE CUSTO
                                    IF VS_RECNUM_CENTROCUSTO IS NOT NULL
                                    THEN
                                        VS_NUMTRANSCENTROCUSTO :=
                                            F_RETORNA_NUMTRANS_CENTROCUSTO ();
                                    END IF;
                                END IF;

                                IF     (NOT VB_ECONTA_PREDEFINIDA)
                                   AND F_USA_CENTRO_CUSTO (VS_CONTA,
                                                           PCODPLANOCONTA)
                                   AND (ITEM.VALORJUROS > 0)
                                   AND (TRIM (ITENSREGRA.FORMULAS) =
                                        'VALORJUROS')
                                THEN
                                    BEGIN
                                        SELECT RECNUM
                                          INTO VS_RECNUM_CENTROCUSTO
                                          FROM PCLANC, PCCONSUM
                                         WHERE     PCLANC.DUPLIC =
                                                   SUBSTR (ITEM.PRESTACAO,
                                                           1,
                                                           1)
                                               AND PCLANC.LOCALIZACAO =
                                                   TO_CHAR (
                                                       ITEM.NUMTRANSVENDA)
                                               AND PCLANC.NUMNOTA =
                                                   ITEM.DUPLICATA
                                               AND PCLANC.NUMTRANS =
                                                   ITEM.NUMTRANSOPERACAO
                                               AND PCLANC.HISTORICO LIKE
                                                          '%'
                                                       || ITEM.NUMTRANSVENDA
                                                       || '-'
                                                       || ITEM.PRESTACAO
                                               AND (   (PCLANC.CODCONTA =
                                                        PCCONSUM.CODCONTRECJUR)
                                                    OR (EXISTS
                                                            (SELECT 1
                                                               FROM PCCOB C
                                                              WHERE     C.CARTAO =
                                                                        'S'
                                                                    AND C.CODCONTACC =
                                                                        PCLANC.CODCONTA)))
                                               AND ROWNUM = 1;
                                    EXCEPTION
                                        WHEN NO_DATA_FOUND
                                        THEN
                                            VS_RECNUM_CENTROCUSTO := NULL;
                                    END;

                                    --INSERE CENTRO DE CUSTO
                                    IF VS_RECNUM_CENTROCUSTO IS NOT NULL
                                    THEN
                                        VS_NUMTRANSCENTROCUSTO :=
                                            F_RETORNA_NUMTRANS_CENTROCUSTO ();
                                    END IF;
                                END IF;

                                IF     (NOT VB_ECONTA_PREDEFINIDA)
                                   AND F_USA_CENTRO_CUSTO (VS_CONTA,
                                                           PCODPLANOCONTA)
                                   AND (ITEM.VALORDESPCARTORAIS > 0)
                                   AND (TRIM (ITENSREGRA.FORMULAS) =
                                        'VALORDESPCARTORAIS')
                                THEN
                                    BEGIN
                                        SELECT RECNUM
                                          INTO VS_RECNUM_CENTROCUSTO
                                          FROM PCLANC
                                         WHERE     PCLANC.DUPLIC =
                                                   SUBSTR (ITEM.PRESTACAO,
                                                           1,
                                                           1)
                                               AND PCLANC.LOCALIZACAO =
                                                   TO_CHAR (
                                                       ITEM.NUMTRANSVENDA)
                                               AND PCLANC.NUMNOTA =
                                                   ITEM.DUPLICATA
                                               AND PCLANC.NUMTRANS =
                                                   ITEM.NUMTRANSOPERACAO
                                               AND PCLANC.HISTORICO LIKE
                                                          '%'
                                                       || ITEM.NUMTRANSVENDA
                                                       || '-'
                                                       || ITEM.PRESTACAO
                                               AND EXISTS
                                                       (SELECT 1
                                                          FROM PCPARAMFILIAL
                                                               F
                                                         WHERE     F.NOME =
                                                                   'CODCONTDESPCARTORIO'
                                                               AND F.VALOR =
                                                                   PCLANC.CODCONTA)
                                               AND ROWNUM = 1;
                                    EXCEPTION
                                        WHEN NO_DATA_FOUND
                                        THEN
                                            VS_RECNUM_CENTROCUSTO := NULL;
                                    END;

                                    --INSERE CENTRO DE CUSTO
                                    IF VS_RECNUM_CENTROCUSTO IS NOT NULL
                                    THEN
                                        VS_NUMTRANSCENTROCUSTO :=
                                            F_RETORNA_NUMTRANS_CENTROCUSTO ();
                                    END IF;
                                END IF;

                                IF     (NOT VB_ECONTA_PREDEFINIDA)
                                   AND F_USA_CENTRO_CUSTO (VS_CONTA,
                                                           PCODPLANOCONTA)
                                   AND (ITEM.VALORDESPBANCARIAS > 0)
                                   AND (TRIM (ITENSREGRA.FORMULAS) =
                                        'VALORDESPBANCARIAS')
                                THEN
                                    BEGIN
                                        SELECT RECNUM
                                          INTO VS_RECNUM_CENTROCUSTO
                                          FROM PCLANC, PCCONSUM
                                         WHERE     PCLANC.DUPLIC =
                                                   SUBSTR (ITEM.PRESTACAO,
                                                           1,
                                                           1)
                                               AND PCLANC.LOCALIZACAO =
                                                   TO_CHAR (
                                                       ITEM.NUMTRANSVENDA)
                                               AND PCLANC.NUMNOTA =
                                                   ITEM.DUPLICATA
                                               AND PCLANC.NUMTRANS =
                                                   ITEM.NUMTRANSOPERACAO
                                               AND PCLANC.HISTORICO LIKE
                                                          '%'
                                                       || ITEM.NUMTRANSVENDA
                                                       || '-'
                                                       || ITEM.PRESTACAO
                                               AND EXISTS
                                                       (SELECT 1
                                                          FROM PCPARAMFILIAL
                                                               F
                                                         WHERE     F.NOME =
                                                                   'CODCONTDESPBANCARIAS'
                                                               AND F.VALOR =
                                                                   PCLANC.CODCONTA)
                                               AND ROWNUM = 1;
                                    EXCEPTION
                                        WHEN NO_DATA_FOUND
                                        THEN
                                            VS_RECNUM_CENTROCUSTO := NULL;
                                    END;

                                    --INSERE CENTRO DE CUSTO
                                    IF VS_RECNUM_CENTROCUSTO IS NOT NULL
                                    THEN
                                        VS_NUMTRANSCENTROCUSTO :=
                                            F_RETORNA_NUMTRANS_CENTROCUSTO ();
                                    END IF;
                                END IF;

                                IF     (NOT VB_ECONTA_PREDEFINIDA)
                                   AND F_USA_CENTRO_CUSTO (VS_CONTA,
                                                           PCODPLANOCONTA)
                                   AND (ITEM.VALOROUTROSACRESC > 0)
                                   AND (TRIM (ITENSREGRA.FORMULAS) =
                                        'VALOROUTROSACRESC')
                                THEN
                                    BEGIN
                                        SELECT RECNUM
                                          INTO VS_RECNUM_CENTROCUSTO
                                          FROM PCLANC, PCCONSUM
                                         WHERE     PCLANC.DUPLIC =
                                                   SUBSTR (ITEM.PRESTACAO,
                                                           1,
                                                           1)
                                               AND PCLANC.LOCALIZACAO =
                                                   TO_CHAR (
                                                       ITEM.NUMTRANSVENDA)
                                               AND PCLANC.NUMNOTA =
                                                   ITEM.DUPLICATA
                                               AND PCLANC.NUMTRANS =
                                                   ITEM.NUMTRANSOPERACAO
                                               AND PCLANC.HISTORICO LIKE
                                                          '%'
                                                       || ITEM.NUMTRANSVENDA
                                                       || '-'
                                                       || ITEM.PRESTACAO
                                               AND EXISTS
                                                       (SELECT 1
                                                          FROM PCPARAMFILIAL
                                                               F
                                                         WHERE     F.NOME IN
                                                                       ('CODCONTOUTROSACRESCIMOSCR',
                                                                        'CODCONTRECEITAPAGMAIORCOBMAG')
                                                               AND F.VALOR =
                                                                   PCLANC.CODCONTA)
                                               AND ROWNUM = 1;
                                    EXCEPTION
                                        WHEN NO_DATA_FOUND
                                        THEN
                                            VS_RECNUM_CENTROCUSTO := NULL;
                                    END;

                                    --INSERE CENTRO DE CUSTO
                                    IF VS_RECNUM_CENTROCUSTO IS NOT NULL
                                    THEN
                                        VS_NUMTRANSCENTROCUSTO :=
                                            F_RETORNA_NUMTRANS_CENTROCUSTO ();
                                    END IF;
                                END IF;

                                IF     (NOT VB_ECONTA_PREDEFINIDA)
                                   AND F_USA_CENTRO_CUSTO (VS_CONTA,
                                                           PCODPLANOCONTA)
                                   AND (ITEM.VALORMULTA > 0)
                                   AND (TRIM (ITENSREGRA.FORMULAS) =
                                        'VALORMULTA')
                                THEN
                                    BEGIN
                                        SELECT RECNUM
                                          INTO VS_RECNUM_CENTROCUSTO
                                          FROM PCLANC, PCCONSUM
                                         WHERE     PCLANC.DUPLIC =
                                                   SUBSTR (ITEM.PRESTACAO,
                                                           1,
                                                           1)
                                               AND PCLANC.LOCALIZACAO =
                                                   TO_CHAR (
                                                       ITEM.NUMTRANSVENDA)
                                               AND PCLANC.NUMNOTA =
                                                   ITEM.DUPLICATA
                                               AND PCLANC.NUMTRANS =
                                                   ITEM.NUMTRANSOPERACAO
                                               AND PCLANC.HISTORICO LIKE
                                                          '%'
                                                       || ITEM.NUMTRANSVENDA
                                                       || '-'
                                                       || ITEM.PRESTACAO
                                               AND EXISTS
                                                       (SELECT 1
                                                          FROM PCPARAMFILIAL
                                                               F
                                                         WHERE     F.NOME =
                                                                   'CON_CODCONTRECMULTA'
                                                               AND F.VALOR =
                                                                   PCLANC.CODCONTA)
                                               AND ROWNUM = 1;
                                    EXCEPTION
                                        WHEN NO_DATA_FOUND
                                        THEN
                                            VS_RECNUM_CENTROCUSTO := NULL;
                                    END;

                                    --INSERE CENTRO DE CUSTO
                                    IF VS_RECNUM_CENTROCUSTO IS NOT NULL
                                    THEN
                                        VS_NUMTRANSCENTROCUSTO :=
                                            F_RETORNA_NUMTRANS_CENTROCUSTO ();
                                    END IF;
                                END IF;

                                --INSERE DADOS NA TABELA QUANDO NÃO ESTÁ TOTALIZANDO VALORES
                                VN_NUMSEQ := VN_NUMSEQ + 1;

                                P_GRAVA_DADOS_TABINTERMEDIARIA (
                                    VS_CODFILIAL,
                                    VN_NUMTRANSACAO,
                                    VN_NUMSEQ,
                                    VD_DATALANCTO,
                                    VS_DOCUMENTO,
                                    ITENSREGRA.CODHISTORICO,
                                    VS_HISTORICO,
                                    PCODPLANOCONTA,
                                    VS_CONTA,
                                    VS_NATUREZA,
                                    ABS (VN_VALORLANCTO),
                                    PCODREGRA,
                                    '',
                                    ITEM.NUMTRANSOPERACAO,
                                    F_RETORNA_TIPO_INCONSISTENCIA (
                                        VS_TEMCONTAINEXISTENTE),
                                    'P',
                                    VD_DATAINTEGRACAO,
                                    0,
                                    ITEM.CODBANCO,
                                    ITEM.CODMOEDA,
                                    VS_NUMTRANSCENTROCUSTO,
                                    TRUNC (SYSDATE),
                                    ITEM.CODCLIENTE,
                                    'C',
                                    NULL,
                                    ITEM.NUMTRANSVENDA,
                                    ITEM.PRESTACAO,
                                    ITENSREGRA.FORMULAS,
                                    ITENSREGRA.CODREDUZIDO_PC,
                                    'RECEBIMENTO',
                                    'PCPREST',
                                    ITENSREGRA.TOTALIZAVALOR);

                                IF VS_RECNUM_CENTROCUSTO IS NOT NULL
                                THEN
                                    P_GRAVA_PCINTER_CENTROCUSTO (
                                        VS_RECNUM_CENTROCUSTO,
                                        VS_NUMTRANSCENTROCUSTO,
                                        PCODREGRA,
                                        (CASE
                                             WHEN VS_BUSCARDADOSPELADATA =
                                                  'C'
                                             THEN
                                                 NVL (ITEM.DATAOPERACAO1,
                                                      ITEM.DATAOPERACAO)
                                             WHEN VS_BUSCARDADOSPELADATA =
                                                  'P'
                                             THEN
                                                 NVL (ITEM.DATAPGTO,
                                                      ITEM.DATAOPERACAO)
                                             ELSE
                                                 ITEM.DATAOPERACAO
                                         END),
                                        FALSE,
                                        0,
                                        VN_NUMTRANSACAO,
                                           VS_HISTORICO
                                        || vs_conta
                                        || VS_CODFILIAL,
                                        0);
                                END IF;

                                VS_NUMTRANSCENTROCUSTO := NULL;
                            END IF;
                        END IF;
                    END IF;

                   <<pula_registro>>
                    NULL;
                END LOOP;

                --GUARDA O NÚMERO DA TRANSAÇÃO
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            ELSE
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            END IF;
        END LOOP;

        --VERIFICA CONSISTÊNCIAS DO ÚLTIMO REGISTRO
        IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '4 - RECEBIMENTOS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
            ---------------------------------------------------------------------------------
            P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                        VD_DATALANCTO,
                                        VS_TEMCONTAINEXISTENTE,
                                        VN_TOTALDEBITO,
                                        VN_TOTALCREDITO,
                                        ITEM.ERRO_MULTIFILIAL);
        END IF;

        CLOSE CURSOR_DADOS;

        RESULTADO := 'OK';
    EXCEPTION
        WHEN OTHERS
        THEN
            RESULTADO :=
                   'Ocorreu um erro quando: '
                || V_SQLERRO
                || CHR (13)
                || 'Erro Original: '
                || SQLERRM;
    END;

    /****************************************************************************
      PROCEDURE PARA GERAÇÃO DE 5 - DEVOLUÇÃO DE FORNECEDORES
    *****************************************************************************/
    PROCEDURE P_DADOS_DEVFORNECEDORES (CURSOR_DADOS     IN     SYS_REFCURSOR,
                                       PCODREGRA        IN     NUMBER,
                                       PCODPLANOCONTA   IN     NUMBER,
                                       RESULTADO           OUT VARCHAR2)
    IS
        TYPE CONSULTA_DEVFORNECEDOR IS RECORD
        (
            CODFILIAL VARCHAR2 (2),
            DATAOPERACAO DATE,
            VALORTOTAL PCLANCAMENTO.VALOR%TYPE,
            VALORICMS PCLANCAMENTO.VALOR%TYPE,
            VALORPIS PCLANCAMENTO.VALOR%TYPE,
            VALORCOFINS PCLANCAMENTO.VALOR%TYPE,
            VALORISENTAS PCLANCAMENTO.VALOR%TYPE,
            VALOROUTRAS PCLANCAMENTO.VALOR%TYPE,
            VALORFRETE PCLANCAMENTO.VALOR%TYPE,
            VALORST PCLANCAMENTO.VALOR%TYPE,
            VALORIPI PCLANCAMENTO.VALOR%TYPE,
            VALORIMPESTADUAL PCLANCAMENTO.VALOR%TYPE,
            VALORREPASSE PCLANCAMENTO.VALOR%TYPE,
            VALORSUBSTRETENCAO PCLANCAMENTO.VALOR%TYPE,
            VALORISENTAS_DAPI PCLANCAMENTO.VALOR%TYPE,
            VALORNAOTRIB_DAPI PCLANCAMENTO.VALOR%TYPE,
            VALORSUSPENSAS_DAPI PCLANCAMENTO.VALOR%TYPE,
            VALORST_DAPI PCLANCAMENTO.VALOR%TYPE,
            VALOROUTRAS_DAPI PCLANCAMENTO.VALOR%TYPE,
            VALORFUNDOCOMBPOBREZA PCNFBASESAID.VLFCP%TYPE,
            VALORICMSDIFALIQPARTILHA PCNFBASESAID.VLICMSDIFALIQPART%TYPE,
            VALORISENTASIPI PCLANCAMENTO.VALOR%TYPE,
            VALOROUTRASIPI PCLANCAMENTO.VALOR%TYPE,
            VALORICMSUFDEST PCNFBASESAID.VLICMSUFDEST%TYPE,
            VALORICMSUFREM PCNFBASESAID.VLICMSUFREM%TYPE,
            VALOROUTRASDESP PCNFBASEENT.VLOUTRASDESP%TYPE,
            VALORSTFORANF PCNFBASEENT.VLSTFORANF%TYPE,
            TIPODEVENDANF NUMBER (5),
            TIPODEVOLUCAONF VARCHAR2 (2),
            ESPECIENF VARCHAR2 (3),
            TIPOOPERACAO VARCHAR2 (2),
            FORNECEDORNF VARCHAR2 (60),
            CODFORNECNF PCNFBASESAID.CODCLI%TYPE,
            NUMNOTANF NUMBER (10),
            SERIENF VARCHAR2 (3),
            CODFISCALNF NUMBER (8),
            UFNF VARCHAR2 (2),
            SITUACAOTRIBUTARIA PCNFBASESAID.SITTRIBUT%TYPE,
            NUMTRANSOPERACAO NUMBER (10),
            CODCOBRANCA VARCHAR2 (4),
            CONTACONTABIL VARCHAR2 (12),
            NUMNOTAENTRADA NUMBER (10),
            POSSUIDEVOLUCAOVERBA VARCHAR (6),
            CODCONTAFORNECEDOR VARCHAR2 (12),
            TEMINTEGRACAO VARCHAR2 (1),
            CODCONTA PCNFBASEENT.CODCONT%TYPE,
            CODCONTADEVOLCLIENTE PCMODELOPC.CODREDUZIDO_PC%TYPE,
            VALORFCEP PCNFBASEENT.VLFECP%TYPE,
            VALORACRESCIMOFUNCEP PCNFBASEENT.VLACRESCIMOFUNCEP%TYPE,
            VALORICMSBCR PCNFBASEENT.VLICMSBCR%TYPE,
            VALORSTBCR PCNFBASEENT.VLSTBCR%TYPE
        );

        ITEM                          CONSULTA_DEVFORNECEDOR;
        ITENSREGRA                    CONSULTA_ITENS;

        CURSOR_ITENS                  SYS_REFCURSOR;

        FILIAIS_LANCADAS              TABELAFILIAISLANCTO;
        FILIAIS                       FILIAISLANCTO;

        VS_RECNUM_CENTROCUSTO         VARCHAR2 (12);
        VS_LISTA_RECNUM_CENTROCUSTO   VARCHAR2 (4000);
        VN_NUMTRANSENT_ANTERIOR       NUMBER (10);
        VS_CONTA_EXISTE               VARCHAR2 (1);
    BEGIN
        LISTA_FORMULAS := TYPE_LISTA_FORMULAS ();


        FILIAIS_LANCADAS := TABELAFILIAISLANCTO ();

        VS_SEQGERADO := 'N';
        VS_FORMADTCONTABILIZACAO := '';
        VN_NUMTRANSACAO := 0;
        VS_DOCUMENTO := '';
        VS_LISTA_RECNUM_CENTROCUSTO := '0';
        VS_TEMCONTAINEXISTENTE := 'N';

        --BUSCA DADOS DA REGRA
        SELECT FORMADTCONTABILIZACAO
          INTO VS_FORMADTCONTABILIZACAO
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        V_SQLERRO := 'ABRINDO DEVOLUÇÃO DE FORNECEDORES';

        --INICIA LAÇO DOS DADOS
        LOOP
            FETCH CURSOR_DADOS INTO ITEM;

            EXIT WHEN CURSOR_DADOS%NOTFOUND;

            IF    (ITEM.TEMINTEGRACAO IS NULL)
               OR (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                   AND (ITEM.TEMINTEGRACAO = 'P'))
            THEN
                --------------------------------------------------------------------
                --VERIFICA SE ALTEROU O NUMTRANSOPERACAO PARA FAZER GRAVAÇÃO E RE-INICIAR VARIÁVEIS
                IF (VN_NUMTRANSOPERACAO <> ITEM.NUMTRANSOPERACAO)
                THEN
                    VS_SEQGERADO := 'N';

                    IF (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                        AND (ITEM.TEMINTEGRACAO = 'P'))
                    THEN
                        P_EXCLUI_LANCINTERMEDIARIA_IND (
                            PCODREGRA,
                            ITEM.NUMTRANSOPERACAO,
                            ITEM.DATAOPERACAO);
                    END IF;

                    --VERIFICA SE JÁ PASSOU POR ALGUM REGISTRO PARA ATRIBUIR INCONSISTÊNCIAS
                    IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) >
                       0
                    THEN
                        ---------------------------------------------------------------------------------
                        V_SQLERRO :=
                            '5 - DEVOLUÇÃO DE FORNECEDORES: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
                        ---------------------------------------------------------------------------------
                        P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                                    VD_DATALANCTO,
                                                    VS_TEMCONTAINEXISTENTE,
                                                    VN_TOTALDEBITO,
                                                    VN_TOTALCREDITO,
                                                    'N');
                    END IF;

                    VS_TEMCONTAINEXISTENTE := 'N';
                END IF;

                --------------------------------------------------------------------

                --GERA NOVO NUMTRANSLANCTO
                IF VS_SEQGERADO = 'N'
                THEN
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '5 - DEVOLUÇÃO DE FORNECEDORES: EXECUTANDO FUNÇÃO GERA_NUM_TRANS_LANCTO()';
                    ---------------------------------------------------------------------------------
                    VN_NUMTRANSACAO := F_GERA_NUM_TRANS_LANCTO ();

                    VN_NUMSEQ := 0;
                    VN_TOTALCREDITO := 0;
                    VN_TOTALDEBITO := 0;
                    VS_SEQGERADO := 'S';

                    CONTASDEBLANCTO := CONTAS_LANCADAS ();
                    CONTASCRELANCTO := CONTAS_LANCADAS ();
                    CGCSLANCTO := CGC_LANCADOS ();
                    VS_LISTAS_TRANSOTORIAS := CONTAS_LANCADAS ();

                    CONTASDEBLANCTO.EXTEND;
                    CONTASCRELANCTO.EXTEND;
                END IF;

                VD_DATALANCTO :=
                    F_RETORNA_DATA_LANCPROVISOES (5,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO);

                VD_DATAINTEGRACAO :=
                    F_RETORNA_DATA_LANCPROVISOES (5,
                                                  PCODREGRA,
                                                  DATA_INTEGRACAO,
                                                  ITEM.DATAOPERACAO);

                --LAÇO NOS ITENS DA REGRA CONTABIL
                OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL ()
                    USING PCODREGRA;

                LOOP
                    FETCH CURSOR_ITENS INTO ITENSREGRA;

                    EXIT WHEN CURSOR_ITENS%NOTFOUND;

                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '5 - DEVOLUÇÃO DE FORNECEDORES: ATRIBUINDO VALOR DO DOCUMENTO';
                    ---------------------------------------------------------------------------------
                    VS_DOCUMENTO := ITENSREGRA.DOCUMENTO;
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO',
                                 TO_CHAR (ITEM.DATAOPERACAO, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMNOTANF', ITEM.NUMNOTANF);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMTRANSOPERACAO',
                                 ITEM.NUMTRANSOPERACAO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMNOTAENTRADA',
                                 ITEM.NUMNOTAENTRADA);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'SITUACAOTRIBUTARIA',
                                 ITEM.SITUACAOTRIBUTARIA);

                    --FORMULA INFORMADA NO FILTRO--------------------------------------------------------
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '5 - DEVOLUÇÃO DE FORNECEDORES: ATRIBUINDO VALOR DA FÓRMULA';
                    ---------------------------------------------------------------------------------
                    VN_VALORLANCTO := 0;

                    VS_FORMULA := ITENSREGRA.FORMULAS || ' + 0 ';
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORTOTAL([^_[:alnum:]])',
                                        NVL (ITEM.VALORTOTAL, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORICMS([^_[:alnum:]])',
                                        NVL (ITEM.VALORICMS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORPIS([^_[:alnum:]])',
                                        NVL (ITEM.VALORPIS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORCOFINS([^_[:alnum:]])',
                                        NVL (ITEM.VALORCOFINS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORISENTAS([^_[:alnum:]])',
                                        NVL (ITEM.VALORISENTAS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALOROUTRAS([^_[:alnum:]])',
                                        NVL (ITEM.VALOROUTRAS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORFRETE([^_[:alnum:]])',
                                        NVL (ITEM.VALORFRETE, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORIPI([^_[:alnum:]])',
                                        NVL (ITEM.VALORIPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORIMPESTADUAL([^_[:alnum:]])',
                            NVL (ITEM.VALORIMPESTADUAL, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORREPASSE([^_[:alnum:]])',
                                        NVL (ITEM.VALORREPASSE, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORSUBSTRETENCAO([^_[:alnum:]])',
                            NVL (ITEM.VALORSUBSTRETENCAO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORISENTAS_DAPI([^_[:alnum:]])',
                            NVL (ITEM.VALORISENTAS_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORNAOTRIB_DAPI([^_[:alnum:]])',
                            NVL (ITEM.VALORNAOTRIB_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORSUSPENSAS_DAPI([^_[:alnum:]])',
                            NVL (ITEM.VALORSUSPENSAS_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORST_DAPI([^_[:alnum:]])',
                                        NVL (ITEM.VALORST_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALOROUTRAS_DAPI([^_[:alnum:]])',
                            NVL (ITEM.VALOROUTRAS_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORISENTASIPI([^_[:alnum:]])',
                            NVL (ITEM.VALORISENTASIPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALOROUTRASIPI([^_[:alnum:]])',
                                        NVL (ITEM.VALOROUTRASIPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORST([^_[:alnum:]])',
                                        NVL (ITEM.VALORST, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORFUNDOCOMBPOBREZA([^_[:alnum:]])',
                            NVL (ITEM.VALORFUNDOCOMBPOBREZA, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORICMSDIFALIQPARTILHA([^_[:alnum:]])',
                            NVL (ITEM.VALORICMSDIFALIQPARTILHA, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORICMSUFDEST([^_[:alnum:]])',
                            NVL (ITEM.VALORICMSUFDEST, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORICMSUFREM([^_[:alnum:]])',
                                        NVL (ITEM.VALORICMSUFREM, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALOROUTRASDESP([^_[:alnum:]])',
                            NVL (ITEM.VALOROUTRASDESP, 0) || '\1');

                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORFECP([^_[:alnum:]])',
                                        NVL (ITEM.VALORFCEP, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORACRESCIMOFUNCEP([^_[:alnum:]])',
                            NVL (ITEM.VALORACRESCIMOFUNCEP, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORSTFORANF([^_[:alnum:]])',
                                        NVL (ITEM.VALORSTFORANF, 0) || '\1');

                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORICMSBCR([^_[:alnum:]])',
                                        NVL (ITEM.VALORICMSBCR, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORSTBCR([^_[:alnum:]])',
                                        NVL (ITEM.VALORSTBCR, 0) || '\1');

                    CALCULAREXPRESSAO;

                    --FIM DA FÓRMULA---------------------------------------------------------------------

                    IF VN_VALORLANCTO > 0
                    THEN
                        VS_CONTA := TRIM (ITENSREGRA.CODREDUZIDO_PC);


                        --VERIFICA SE A PERNA DA INTEGRAÇÃO TEM CENTRO DE CUSTO
                        IF F_LANCTO_TEM_CENTROCUSTO (VS_CONTA,
                                                     ITEM.CODCONTA,
                                                     5,
                                                     ITEM.NUMTRANSOPERACAO,
                                                     0,
                                                     '0',
                                                     PCODPLANOCONTA) = 'S'
                        THEN
                            VS_RECNUM_CENTROCUSTO := 'S';
                        ELSE
                            VS_RECNUM_CENTROCUSTO := '';
                        END IF;

                        VS_CODFILIAL :=
                            CASE
                                WHEN ITENSREGRA.CODFILIAL =
                                     'FILIALLANCAMENTO'
                                THEN
                                    ITEM.CODFILIAL
                                ELSE
                                    ITENSREGRA.CODFILIAL
                            END;

                        IF     (SUBSTR (VS_CONTA, 1, 1) <> '0')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '1')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '2')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '3')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '4')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '5')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '6')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '7')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '8')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '9')
                        THEN
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CONTACONTABIL',
                                         ITEM.CONTACONTABIL);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTAFORNECEDOR',
                                         ITEM.CODCONTAFORNECEDOR);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTADEVOLCLIENTE',
                                         ITEM.CODCONTADEVOLCLIENTE);
                        END IF;

                        IF VS_TEMCONTAINEXISTENTE <> 'X'
                        THEN
                            VS_CONTA_EXISTE :=
                                F_VERIFICA_CONTA_EXISTE (VS_CONTA,
                                                         PCODPLANOCONTA);
                            TRATAR_CONTA_INEXISTENTE (VS_CONTA_EXISTE,
                                                      VS_TEMCONTAINEXISTENTE);
                        END IF;

                        IF VS_CONTA_EXISTE IN ('S', 'I', 'X')
                        THEN
                            --HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO---------------------------------------
                            ---------------------------------------------------------------------------------
                            V_SQLERRO :=
                                '5 - DEVOLUÇÃO DE FORNECEDORES: ATRIBUINDO VALOR DE HISTÓRICOS';
                            ---------------------------------------------------------------------------------
                            VS_HISTORICO := ITENSREGRA.HISTCOMPLREGRA;
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO]',
                                         ITEM.DATAOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMNOTANF]',
                                         ITEM.NUMNOTANF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODFISCALNF]',
                                         ITEM.CODFISCALNF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[ESPECIENF]',
                                         ITEM.ESPECIENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[FORNECEDORNF]',
                                         ITEM.FORNECEDORNF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODFORNECNF]',
                                         ITEM.CODFORNECNF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[SERIENF]',
                                         ITEM.SERIENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO, '[UFNF]', ITEM.UFNF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMNOTAENTRADA]',
                                         ITEM.NUMNOTAENTRADA);
                            VS_HISTORICO := SUBSTR (VS_HISTORICO, 1, 200);

                            --FIM HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO-----------------------------------

                            IF ITENSREGRA.NATUREZA = 'C'
                            THEN
                                VN_TOTALCREDITO :=
                                    ROUND (
                                          VN_TOTALCREDITO
                                        + ABS (VN_VALORLANCTO),
                                        2);
                                VS_NATUREZA := 'C';
                            ELSE
                                VN_TOTALDEBITO :=
                                    ROUND (
                                        VN_TOTALDEBITO + ABS (VN_VALORLANCTO),
                                        2);
                                VS_NATUREZA := 'D';
                            END IF;

                            --GUARDA FILIAIS
                            FILIAIS.CODFILIAL := '-1';

                            FOR VN_POSICAO IN 1 .. FILIAIS_LANCADAS.COUNT
                            LOOP
                                IF (FILIAIS_LANCADAS (VN_POSICAO).CODFILIAL =
                                    VS_CODFILIAL)
                                THEN
                                    FILIAIS := FILIAIS_LANCADAS (VN_POSICAO);
                                    VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

                                    EXIT;
                                END IF;
                            END LOOP;

                            IF (FILIAIS.CODFILIAL = '-1')
                            THEN
                                FILIAIS_LANCADAS.EXTEND;

                                FILIAIS :=
                                    FILIAIS_LANCADAS (FILIAIS_LANCADAS.COUNT);
                                VN_POSICAO_EM_ALTERACAO :=
                                    FILIAIS_LANCADAS.COUNT;

                                FILIAIS.CODFILIAL := VS_CODFILIAL;
                                FILIAIS.CGCFILIAL :=
                                    F_CGCFILIAL (VS_CODFILIAL);

                                FILIAIS_LANCADAS (VN_POSICAO_EM_ALTERACAO) :=
                                    FILIAIS;
                            END IF;

                            --GUARDA AS CONTAS PARA VERIFICAR SE ESTÃO IGUAIS POSTERIORMENTE
                            P_ARMAZENA_CONTAS_FILIAIS_LANC (VS_CONTA,
                                                            VS_NATUREZA,
                                                            VS_CODFILIAL,
                                                            FILIAIS_LANCADAS);

                            IF 'N' = 'S'
                            THEN
                                NULL;
                            ELSE
                                ---------------------------------------------------------------------------------
                                V_SQLERRO :=
                                    '5 - DEVOLUÇÃO DE FORNECEDORES: EXECUTANDO PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA()';

                                ---------------------------------------------------------------------------------
                                --INSERE CENTRO DE CUSTO
                                IF VS_RECNUM_CENTROCUSTO IS NOT NULL
                                THEN
                                    IF VS_NUMTRANSCENTROCUSTO IS NULL
                                    THEN
                                        VS_NUMTRANSCENTROCUSTO :=
                                            F_RETORNA_NUMTRANS_CENTROCUSTO ();
                                    END IF;
                                END IF;

                                --INSERE DADOS NA TABELA QUANDO NÃO ESTÁ TOTALIZANDO VALORES
                                VN_NUMSEQ := VN_NUMSEQ + 1;

                                P_GRAVA_DADOS_TABINTERMEDIARIA (
                                    VS_CODFILIAL,
                                    VN_NUMTRANSACAO,
                                    VN_NUMSEQ,
                                    VD_DATALANCTO,
                                    VS_DOCUMENTO,
                                    ITENSREGRA.CODHISTORICO,
                                    VS_HISTORICO,
                                    PCODPLANOCONTA,
                                    VS_CONTA,
                                    VS_NATUREZA,
                                    VN_VALORLANCTO,
                                    PCODREGRA,
                                    '',
                                    ITEM.NUMTRANSOPERACAO,
                                    F_RETORNA_TIPO_INCONSISTENCIA (
                                        VS_TEMCONTAINEXISTENTE),
                                    'P',
                                    ITEM.DATAOPERACAO,
                                    ITEM.CODFISCALNF,
                                    0,
                                    '',
                                    CASE
                                        WHEN VS_RECNUM_CENTROCUSTO IS NULL
                                        THEN
                                            ''
                                        ELSE
                                            VS_NUMTRANSCENTROCUSTO
                                    END,
                                    VD_DATAINTEGRACAO,
                                    ITEM.CODFORNECNF,
                                    'F',
                                    NULL,
                                    ITEM.NUMTRANSOPERACAO,
                                    '',
                                    ITENSREGRA.FORMULAS,
                                    ITENSREGRA.CODREDUZIDO_PC,
                                    'DEVFORNEC',
                                    'PCNFBASESAID',
                                    ITENSREGRA.TOTALIZAVALOR);

                                IF VS_RECNUM_CENTROCUSTO IS NOT NULL
                                THEN
                                    IF VN_NUMTRANSENT_ANTERIOR <>
                                       ITEM.NUMTRANSOPERACAO
                                    THEN
                                        VN_NUMTRANSENT_ANTERIOR :=
                                            ITEM.NUMTRANSOPERACAO;

                                        FOR DADOS_PCLANC_CC
                                            IN (SELECT RECNUM
                                                  FROM PCLANC
                                                 WHERE NUMTRANSENT =
                                                       ITEM.NUMTRANSOPERACAO)
                                        LOOP
                                            IF VS_LISTA_RECNUM_CENTROCUSTO
                                                   IS NULL
                                            THEN
                                                VS_LISTA_RECNUM_CENTROCUSTO :=
                                                    DADOS_PCLANC_CC.RECNUM;
                                            ELSE
                                                VS_LISTA_RECNUM_CENTROCUSTO :=
                                                       VS_LISTA_RECNUM_CENTROCUSTO
                                                    || ','
                                                    || DADOS_PCLANC_CC.RECNUM;
                                            END IF;
                                        END LOOP;

                                        P_GRAVA_PCINTER_CENTROCUSTO (
                                            VS_LISTA_RECNUM_CENTROCUSTO,
                                            VS_NUMTRANSCENTROCUSTO,
                                            PCODREGRA,
                                            ITEM.DATAOPERACAO,
                                            FALSE,
                                            0,
                                            '',
                                               VS_HISTORICO
                                            || vs_conta
                                            || VS_CODFILIAL,
                                            0);
                                    ELSE
                                        VS_LISTA_RECNUM_CENTROCUSTO := '0';
                                    END IF;
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END LOOP;

                --GUARDA O NÚMERO DA TRANSAÇÃO
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            ELSE
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            END IF;
        END LOOP;

        --VERIFICA CONSISTÊNCIAS DO ÚLTIMO REGISTRO
        IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '5 - DEVOLUÇÃO DE FORNECEDORES: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
            ---------------------------------------------------------------------------------
            P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                        VD_DATALANCTO,
                                        VS_TEMCONTAINEXISTENTE,
                                        VN_TOTALDEBITO,
                                        VN_TOTALCREDITO,
                                        'N');
        END IF;

        CLOSE CURSOR_DADOS;

        RESULTADO := 'OK';
    EXCEPTION
        WHEN OTHERS
        THEN
            RESULTADO :=
                   'Ocorreu um erro quando: '
                || V_SQLERRO
                || CHR (13)
                || 'Erro Original: '
                || SQLERRM;
    END;

    /****************************************************************************
      PROCEDURE PARA GERAÇÃO DE 6 - DEVOLUÇÕES DE CLIENTE
    *****************************************************************************/
    PROCEDURE P_DADOS_DEVCLIENTES (CURSOR_DADOS     IN     SYS_REFCURSOR,
                                   PCODREGRA        IN     NUMBER,
                                   PCODPLANOCONTA   IN     NUMBER,
                                   RESULTADO           OUT VARCHAR2)
    IS
        TYPE CONSULTA_DEVCLIENTES IS RECORD
        (
            CODFILIAL VARCHAR2 (2),
            DATAOPERACAO DATE,
            DATAEMISSAONF DATE,
            VALORTOTAL PCLANCAMENTO.VALOR%TYPE,
            VALORICMS PCLANCAMENTO.VALOR%TYPE,
            VALORPIS PCLANCAMENTO.VALOR%TYPE,
            VALORCOFINS PCLANCAMENTO.VALOR%TYPE,
            VALORISENTAS PCLANCAMENTO.VALOR%TYPE,
            VALOROUTRAS PCLANCAMENTO.VALOR%TYPE,
            VALORST PCLANCAMENTO.VALOR%TYPE,
            VALORIPI PCLANCAMENTO.VALOR%TYPE,
            VALORIMPOSTOESTADUAL PCLANCAMENTO.VALOR%TYPE,
            VALORSTFORANF PCLANCAMENTO.VALOR%TYPE,
            VALORISENTAS_DAPI PCLANCAMENTO.VALOR%TYPE,
            VALORNAOTRIB_DAPI PCLANCAMENTO.VALOR%TYPE,
            VALORSUSPENSAS_DAPI PCLANCAMENTO.VALOR%TYPE,
            VALORST_DAPI PCLANCAMENTO.VALOR%TYPE,
            VALOROUTRAS_DAPI PCLANCAMENTO.VALOR%TYPE,
            VALORISENTASIPI PCLANCAMENTO.VALOR%TYPE,
            VALOROUTRASIPI PCLANCAMENTO.VALOR%TYPE,
            VALORFUNDOCOMBPOBREZA PCNFBASEENT.VLFCP%TYPE,
            VALORICMSDIFALIQPARTILHA PCNFBASEENT.VLICMSDIFALIQPART%TYPE,
            VALORICMSUFDEST PCNFBASEENT.VLICMSUFDEST%TYPE,
            VALORICMSUFREM PCNFBASEENT.VLICMSUFREM%TYPE,
            TIPODESCARGA VARCHAR2 (1),
            NUMNOTANF NUMBER (10),
            NUMNOTASAIDA NUMBER (10),
            ESPECIENF VARCHAR2 (2),
            SERIENF VARCHAR2 (3),
            CODFISCALNF NUMBER (8),
            CODCLIENTENF PCCLIENT.CODCLI%TYPE,
            UFNF VARCHAR2 (2),
            SITUACAOTRIBUTARIA PCNFBASEENT.SITTRIBUT%TYPE,
            CLIENTENF VARCHAR2 (60),
            NUMTRANSOPERACAO NUMBER (10),
            TIPOOPERACAO VARCHAR2 (2),
            CODCONTAGERENCIAL PCNFSAID.CODCONT%TYPE,
            CODCONTACLIENTE VARCHAR2 (12),
            CODCONTADEVFORNEC VARCHAR2 (12),
            DEVOLUCAOGEROUCREDITO VARCHAR2 (1),
            TEMINTEGRACAO VARCHAR2 (1),
            VALORFCEP PCNFBASEENT.VLFECP%TYPE,
            VALORACRESCIMOFUNCEP PCNFBASEENT.VLACRESCIMOFUNCEP%TYPE,
            VALORICMSBCR PCNFBASEENT.VLICMSBCR%TYPE,
            VALORSTBCR PCNFBASEENT.VLSTBCR%TYPE,
            VALORFECPSTGUIA PCNFBASEENT.VLFECPSTGUIA%TYPE
        );

        ITEM               CONSULTA_DEVCLIENTES;
        ITENSREGRA         CONSULTA_ITENS;

        CURSOR_ITENS       SYS_REFCURSOR;

        FILIAIS_LANCADAS   TABELAFILIAISLANCTO;
        FILIAIS            FILIAISLANCTO;
        VS_CONTA_EXISTE    VARCHAR2 (1);
    BEGIN
        LISTA_FORMULAS := TYPE_LISTA_FORMULAS ();

        FILIAIS_LANCADAS := TABELAFILIAISLANCTO ();

        VS_SEQGERADO := 'N';
        VS_FORMADTCONTABILIZACAO := '';
        VN_NUMTRANSACAO := 0;
        VS_DOCUMENTO := '';
        VS_TEMCONTAINEXISTENTE := 'N';

        --BUSCA DADOS DA REGRA
        SELECT FORMADTCONTABILIZACAO
          INTO VS_FORMADTCONTABILIZACAO
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        V_SQLERRO := 'ABRINDO DEVOLUÇÕES DE CLIENTE';

        --INICIA LAÇO DOS DADOS
        LOOP
            FETCH CURSOR_DADOS INTO ITEM;

            EXIT WHEN CURSOR_DADOS%NOTFOUND;

            IF    (ITEM.TEMINTEGRACAO IS NULL)
               OR (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                   AND (ITEM.TEMINTEGRACAO = 'P'))
            THEN
                --------------------------------------------------------------------
                --VERIFICA SE ALTEROU O NUMTRANSOPERACAO PARA FAZER GRAVAÇÃO E RE-INICIAR VARIÁVEIS
                IF (VN_NUMTRANSOPERACAO <> ITEM.NUMTRANSOPERACAO)
                THEN
                    VS_SEQGERADO := 'N';

                    IF (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                        AND (ITEM.TEMINTEGRACAO = 'P'))
                    THEN
                        P_EXCLUI_LANCINTERMEDIARIA_IND (
                            PCODREGRA,
                            ITEM.NUMTRANSOPERACAO,
                            ITEM.DATAOPERACAO);
                    END IF;

                    --VERIFICA SE JÁ PASSOU POR ALGUM REGISTRO PARA ATRIBUIR INCONSISTÊNCIAS
                    IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) >
                       0
                    THEN
                        ---------------------------------------------------------------------------------
                        V_SQLERRO :=
                            '6 - DEVOLUÇÕES DE CLIENTE: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
                        ---------------------------------------------------------------------------------
                        P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                                    VD_DATALANCTO,
                                                    VS_TEMCONTAINEXISTENTE,
                                                    VN_TOTALDEBITO,
                                                    VN_TOTALCREDITO,
                                                    'N');
                    END IF;

                    VS_TEMCONTAINEXISTENTE := 'N';
                END IF;

                --------------------------------------------------------------------

                --GERA NOVO NUMTRANSLANCTO
                IF VS_SEQGERADO = 'N'
                THEN
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '6 - DEVOLUÇÕES DE CLIENTE: EXECUTANDO FUNÇÃO GERA_NUM_TRANS_LANCTO()';
                    ---------------------------------------------------------------------------------
                    VN_NUMTRANSACAO := F_GERA_NUM_TRANS_LANCTO ();

                    VN_NUMSEQ := 0;
                    VN_TOTALCREDITO := 0;
                    VN_TOTALDEBITO := 0;
                    VS_SEQGERADO := 'S';

                    CONTASDEBLANCTO := CONTAS_LANCADAS ();
                    CONTASCRELANCTO := CONTAS_LANCADAS ();
                    CGCSLANCTO := CGC_LANCADOS ();
                    VS_LISTAS_TRANSOTORIAS := CONTAS_LANCADAS ();

                    CONTASDEBLANCTO.EXTEND;
                    CONTASCRELANCTO.EXTEND;
                END IF;

                VD_DATALANCTO :=
                    F_RETORNA_DATA_LANCPROVISOES (6,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO);

                VD_DATAINTEGRACAO :=
                    F_RETORNA_DATA_LANCPROVISOES (6,
                                                  PCODREGRA,
                                                  DATA_INTEGRACAO,
                                                  ITEM.DATAOPERACAO);

                --LAÇO NOS ITENS DA REGRA CONTABIL
                OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL ()
                    USING PCODREGRA;

                LOOP
                    FETCH CURSOR_ITENS INTO ITENSREGRA;

                    EXIT WHEN CURSOR_ITENS%NOTFOUND;

                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '6 - DEVOLUÇÕES DE CLIENTE: ATRIBUINDO VALOR DO DOCUMENTO';
                    ---------------------------------------------------------------------------------
                    VS_DOCUMENTO := ITENSREGRA.DOCUMENTO;
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO',
                                 TO_CHAR (ITEM.DATAOPERACAO, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAEMISSAONF',
                                 TO_CHAR (ITEM.DATAEMISSAONF, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMNOTANF', ITEM.NUMNOTANF);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMTRANSOPERACAO',
                                 ITEM.NUMTRANSOPERACAO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'CODCONTAGERENCIAL',
                                 ITEM.CODCONTAGERENCIAL);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'SITUACAOTRIBUTARIA',
                                 ITEM.SITUACAOTRIBUTARIA);

                    --FORMULA INFORMADA NO FILTRO--------------------------------------------------------
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '6 - DEVOLUÇÕES DE CLIENTE: ATRIBUINDO VALOR DA FÓRMULA';
                    ---------------------------------------------------------------------------------
                    VN_VALORLANCTO := 0;

                    VS_FORMULA := ITENSREGRA.FORMULAS || ' + 0 ';
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORTOTAL([^_[:alnum:]])',
                                        NVL (ITEM.VALORTOTAL, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORICMS([^_[:alnum:]])',
                                        NVL (ITEM.VALORICMS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORPIS([^_[:alnum:]])',
                                        NVL (ITEM.VALORPIS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORCOFINS([^_[:alnum:]])',
                                        NVL (ITEM.VALORCOFINS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORISENTAS([^_[:alnum:]])',
                                        NVL (ITEM.VALORISENTAS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALOROUTRAS([^_[:alnum:]])',
                                        NVL (ITEM.VALOROUTRAS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORIPI([^_[:alnum:]])',
                                        NVL (ITEM.VALORIPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORIMPOSTOESTADUAL([^_[:alnum:]])',
                            NVL (ITEM.VALORIMPOSTOESTADUAL, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORSTFORANF([^_[:alnum:]])',
                                        NVL (ITEM.VALORSTFORANF, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORISENTAS_DAPI([^_[:alnum:]])',
                            NVL (ITEM.VALORISENTAS_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORNAOTRIB_DAPI([^_[:alnum:]])',
                            NVL (ITEM.VALORNAOTRIB_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORSUSPENSAS_DAPI([^_[:alnum:]])',
                            NVL (ITEM.VALORSUSPENSAS_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORST_DAPI([^_[:alnum:]])',
                                        NVL (ITEM.VALORST_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALOROUTRAS_DAPI([^_[:alnum:]])',
                            NVL (ITEM.VALOROUTRAS_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORISENTASIPI([^_[:alnum:]])',
                            NVL (ITEM.VALORISENTASIPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALOROUTRASIPI([^_[:alnum:]])',
                                        NVL (ITEM.VALOROUTRASIPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORST([^_[:alnum:]])',
                                        NVL (ITEM.VALORST, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORFUNDOCOMBPOBREZA([^_[:alnum:]])',
                            NVL (ITEM.VALORFUNDOCOMBPOBREZA, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORICMSDIFALIQPARTILHA([^_[:alnum:]])',
                            NVL (ITEM.VALORICMSDIFALIQPARTILHA, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORICMSUFDEST([^_[:alnum:]])',
                            NVL (ITEM.VALORICMSUFDEST, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORICMSUFREM([^_[:alnum:]])',
                                        NVL (ITEM.VALORICMSUFREM, 0) || '\1');

                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORFECP([^_[:alnum:]])',
                                        NVL (ITEM.VALORFCEP, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORACRESCIMOFUNCEP([^_[:alnum:]])',
                            NVL (ITEM.VALORACRESCIMOFUNCEP, 0) || '\1');

                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORICMSBCR([^_[:alnum:]])',
                                        NVL (ITEM.VALORICMSBCR, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORSTBCR([^_[:alnum:]])',
                                        NVL (ITEM.VALORSTBCR, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORFECPSTGUIA([^_[:alnum:]])',
                            NVL (ITEM.VALORFECPSTGUIA, 0) || '\1');

                    CALCULAREXPRESSAO;

                    --FIM DA FÓRMULA---------------------------------------------------------------------

                    IF VN_VALORLANCTO > 0
                    THEN
                        VS_CONTA := TRIM (ITENSREGRA.CODREDUZIDO_PC);
                        VS_CODFILIAL :=
                            CASE
                                WHEN ITENSREGRA.CODFILIAL =
                                     'FILIALLANCAMENTO'
                                THEN
                                    ITEM.CODFILIAL
                                ELSE
                                    ITENSREGRA.CODFILIAL
                            END;

                        IF     (SUBSTR (VS_CONTA, 1, 1) <> '0')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '1')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '2')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '3')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '4')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '5')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '6')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '7')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '8')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '9')
                        THEN
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTACLIENTE',
                                         ITEM.CODCONTACLIENTE);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTADEVFORNEC',
                                         ITEM.CODCONTADEVFORNEC);
                        END IF;

                        VS_CONTA_EXISTE :=
                            F_VERIFICA_CONTA_EXISTE (VS_CONTA,
                                                     PCODPLANOCONTA);
                        TRATAR_CONTA_INEXISTENTE (VS_CONTA_EXISTE,
                                                  VS_TEMCONTAINEXISTENTE);

                        IF VS_CONTA_EXISTE IN ('S', 'I', 'X')
                        THEN
                            --HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO---------------------------------------
                            ---------------------------------------------------------------------------------
                            V_SQLERRO :=
                                '6 - DEVOLUÇÕES DE CLIENTE: ATRIBUINDO VALOR DE HISTÓRICOS';
                            ---------------------------------------------------------------------------------
                            VS_HISTORICO := ITENSREGRA.HISTCOMPLREGRA;
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO]',
                                         ITEM.DATAOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMNOTANF]',
                                         ITEM.NUMNOTANF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMNOTASAIDA]',
                                         ITEM.NUMNOTASAIDA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAEMISSAONF]',
                                         ITEM.DATAEMISSAONF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODFISCALNF]',
                                         ITEM.CODFISCALNF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[ESPECIENF]',
                                         ITEM.ESPECIENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CLIENTENF]',
                                         ITEM.CLIENTENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODCLIENTENF]',
                                         ITEM.CODCLIENTENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[SERIENF]',
                                         ITEM.SERIENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO, '[UFNF]', ITEM.UFNF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMTRANSOPERACAO]',
                                         ITEM.NUMTRANSOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODCONTAGERENCIAL]',
                                         ITEM.CODCONTAGERENCIAL);
                            VS_HISTORICO := SUBSTR (VS_HISTORICO, 1, 200);

                            --FIM HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO-----------------------------------

                            IF ITENSREGRA.NATUREZA = 'C'
                            THEN
                                VN_TOTALCREDITO :=
                                    ROUND (
                                          VN_TOTALCREDITO
                                        + ABS (VN_VALORLANCTO),
                                        2);
                                VS_NATUREZA := 'C';
                            ELSE
                                VN_TOTALDEBITO :=
                                    ROUND (
                                        VN_TOTALDEBITO + ABS (VN_VALORLANCTO),
                                        2);
                                VS_NATUREZA := 'D';
                            END IF;

                            --GUARDA FILIAIS
                            FILIAIS.CODFILIAL := '-1';

                            FOR VN_POSICAO IN 1 .. FILIAIS_LANCADAS.COUNT
                            LOOP
                                IF (FILIAIS_LANCADAS (VN_POSICAO).CODFILIAL =
                                    VS_CODFILIAL)
                                THEN
                                    FILIAIS := FILIAIS_LANCADAS (VN_POSICAO);
                                    VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

                                    EXIT;
                                END IF;
                            END LOOP;

                            IF (FILIAIS.CODFILIAL = '-1')
                            THEN
                                FILIAIS_LANCADAS.EXTEND;

                                FILIAIS :=
                                    FILIAIS_LANCADAS (FILIAIS_LANCADAS.COUNT);
                                VN_POSICAO_EM_ALTERACAO :=
                                    FILIAIS_LANCADAS.COUNT;

                                FILIAIS.CODFILIAL := VS_CODFILIAL;
                                FILIAIS.CGCFILIAL :=
                                    F_CGCFILIAL (VS_CODFILIAL);

                                FILIAIS_LANCADAS (VN_POSICAO_EM_ALTERACAO) :=
                                    FILIAIS;
                            END IF;

                            --GUARDA AS CONTAS PARA VERIFICAR SE ESTÃO IGUAIS POSTERIORMENTE
                            P_ARMAZENA_CONTAS_FILIAIS_LANC (VS_CONTA,
                                                            VS_NATUREZA,
                                                            VS_CODFILIAL,
                                                            FILIAIS_LANCADAS);

                            IF 'N' = 'S'
                            THEN
                                NULL;
                            ELSE
                                ---------------------------------------------------------------------------------
                                V_SQLERRO :=
                                    '6 - DEVOLUÇÕES DE CLIENTE: EXECUTANDO PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA()';
                                ---------------------------------------------------------------------------------
                                --INSERE DADOS NA TABELA QUANDO NÃO ESTÁ TOTALIZANDO VALORES
                                VN_NUMSEQ := VN_NUMSEQ + 1;

                                P_GRAVA_DADOS_TABINTERMEDIARIA (
                                    VS_CODFILIAL,
                                    VN_NUMTRANSACAO,
                                    VN_NUMSEQ,
                                    VD_DATALANCTO,
                                    VS_DOCUMENTO,
                                    ITENSREGRA.CODHISTORICO,
                                    VS_HISTORICO,
                                    PCODPLANOCONTA,
                                    VS_CONTA,
                                    VS_NATUREZA,
                                    VN_VALORLANCTO,
                                    PCODREGRA,
                                    '',
                                    ITEM.NUMTRANSOPERACAO,
                                    F_RETORNA_TIPO_INCONSISTENCIA (
                                        VS_TEMCONTAINEXISTENTE),
                                    'P',
                                    ITEM.DATAOPERACAO,
                                    ITEM.CODFISCALNF,
                                    0,
                                    '',
                                    '',
                                    VD_DATAINTEGRACAO,
                                    ITEM.CODCLIENTENF,
                                    'C',
                                    NULL,
                                    ITEM.NUMTRANSOPERACAO,
                                    ITEM.CODCONTAGERENCIAL,
                                    ITENSREGRA.FORMULAS,
                                    ITENSREGRA.CODREDUZIDO_PC,
                                    'DEVCLI',
                                    '  PCNFBASEENT',
                                    ITENSREGRA.TOTALIZAVALOR);
                            END IF;
                        END IF;
                    END IF;
                END LOOP;

                --GUARDA O NÚMERO DA TRANSAÇÃO
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            ELSE
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            END IF;
        END LOOP;

        --VERIFICA CONSISTÊNCIAS DO ÚLTIMO REGISTRO
        IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '6 - DEVOLUÇÕES DE CLIENTE: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
            ---------------------------------------------------------------------------------
            P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                        VD_DATALANCTO,
                                        VS_TEMCONTAINEXISTENTE,
                                        VN_TOTALDEBITO,
                                        VN_TOTALCREDITO,
                                        'N');
        END IF;

        CLOSE CURSOR_DADOS;

        RESULTADO := 'OK';
    EXCEPTION
        WHEN OTHERS
        THEN
            RESULTADO :=
                   'Ocorreu um erro quando: '
                || V_SQLERRO
                || CHR (13)
                || 'Erro Original: '
                || SQLERRM;
    END;

    /****************************************************************************
      PROCEDURE PARA GERAÇÃO DE 7 - TRANSFERÊNCIA DE NUMERÁRIOS
    *****************************************************************************/
    PROCEDURE P_DADOS_TRANSFNUMERARIOS (CURSOR_DADOS     IN     SYS_REFCURSOR,
                                        PCODREGRA        IN     NUMBER,
                                        PCODPLANOCONTA   IN     NUMBER,
                                        RESULTADO           OUT VARCHAR2)
    IS
        TYPE CONSULTA_TRANSFNUMERARIOS IS RECORD
        (
            CODFILIAL VARCHAR2 (2),
            DATAOPERACAO DATE,
            DATA_INDEX DATE,
            DATAOPERACAO1 DATE,
            HISTORICOLANCTO PCMOVCR.HISTORICO%TYPE,
            HISTORICOCOMPLEMENTO PCMOVCR.HISTORICO2%TYPE,
            NUMTRANSOPERACAO NUMBER (10),
            VALORLANCTO PCLANCAMENTO.VALOR%TYPE,
            STATUS VARCHAR2 (1),
            CODBANCO NUMBER (4),
            CODMOEDA VARCHAR2 (4),
            CODROTINA NUMBER (6),
            NUMCARR PCMOVCR.NUMCARR%TYPE,
            CODCONTADEB VARCHAR2 (12),
            CODCONTACRED VARCHAR2 (12),
            NUMDOCUMENTO PCMOVCR.NUMDOC%TYPE,
            TEMINTEGRACAO VARCHAR2 (1),
            CODBANCODEB PCMOVCR.CODBANCO%TYPE,
            CODBANCOCRED PCMOVCR.CODBANCO%TYPE,
            CODMOEDADEB PCMOVCR.CODCOB%TYPE,
            CODMOEDACRED PCMOVCR.CODCOB%TYPE
        );

        ITEM                CONSULTA_TRANSFNUMERARIOS;
        ITENSREGRA          CONSULTA_ITENS;

        CURSOR_ITENS        SYS_REFCURSOR;

        FILIAIS_LANCADAS    TABELAFILIAISLANCTO;
        FILIAIS             FILIAISLANCTO;
        VS_CONTA_EXISTE     VARCHAR2 (1);

        VD_DATALANCTO_AUX   DATE;
    BEGIN
        LISTA_FORMULAS := TYPE_LISTA_FORMULAS ();

        FILIAIS_LANCADAS := TABELAFILIAISLANCTO ();

        VS_SEQGERADO := 'N';
        VS_FORMADTCONTABILIZACAO := '';
        VN_NUMTRANSACAO := 0;
        VS_DOCUMENTO := '';
        VS_TEMCONTAINEXISTENTE := 'N';

        --BUSCA DADOS DA REGRA
        SELECT FORMADTCONTABILIZACAO, BUSCARDADOSPELADATA
          INTO VS_FORMADTCONTABILIZACAO, VS_BUSCARDADOSPELADATA
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        --INICIA LAÇO DOS DADOS
        LOOP
            FETCH CURSOR_DADOS INTO ITEM;

            EXIT WHEN CURSOR_DADOS%NOTFOUND;

            IF    (ITEM.TEMINTEGRACAO IS NULL)
               OR (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                   AND (ITEM.TEMINTEGRACAO = 'P'))
            THEN
                VD_DATALANCTO_AUX :=
                    F_RETORNA_DATA_LANCPROVISOES (7,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO,
                                                  ITEM.DATAOPERACAO1);

                --------------------------------------------------------------------
                --VERIFICA SE ALTEROU O NUMTRANSOPERACAO PARA FAZER GRAVAÇÃO E RE-INICIAR VARIÁVEIS
                IF (VN_NUMTRANSOPERACAO <> ITEM.NUMTRANSOPERACAO)
                THEN
                    VS_SEQGERADO := 'N';

                    IF (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                        AND (ITEM.TEMINTEGRACAO = 'P'))
                    THEN
                        P_EXCLUI_LANCINTERMEDIARIA_IND (
                            PCODREGRA,
                            ITEM.NUMTRANSOPERACAO,
                            VD_DATALANCTO_AUX);
                    END IF;

                    --VERIFICA SE JÁ PASSOU POR ALGUM REGISTRO PARA ATRIBUIR INCONSISTÊNCIAS
                    IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) >
                       0
                    THEN
                        ---------------------------------------------------------------------------------
                        V_SQLERRO :=
                            '7 - TRANSFERÊNCIA DE NUMERÁRIOS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
                        ---------------------------------------------------------------------------------
                        P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                                    VD_DATALANCTO,
                                                    VS_TEMCONTAINEXISTENTE,
                                                    VN_TOTALDEBITO,
                                                    VN_TOTALCREDITO,
                                                    'N');
                    END IF;

                    VS_TEMCONTAINEXISTENTE := 'N';
                END IF;

                --------------------------------------------------------------------

                --GERA NOVO NUMTRANSLANCTO
                IF VS_SEQGERADO = 'N'
                THEN
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '7 - TRANSFERÊNCIA DE NUMERÁRIOS: EXECUTANDO FUNÇÃO GERA_NUM_TRANS_LANCTO()';
                    ---------------------------------------------------------------------------------
                    VN_NUMTRANSACAO := F_GERA_NUM_TRANS_LANCTO ();

                    VN_NUMSEQ := 0;
                    VN_TOTALCREDITO := 0;
                    VN_TOTALDEBITO := 0;
                    VS_SEQGERADO := 'S';

                    CONTASDEBLANCTO := CONTAS_LANCADAS ();
                    CONTASCRELANCTO := CONTAS_LANCADAS ();
                    CGCSLANCTO := CGC_LANCADOS ();
                    VS_LISTAS_TRANSOTORIAS := CONTAS_LANCADAS ();

                    CONTASDEBLANCTO.EXTEND;
                    CONTASCRELANCTO.EXTEND;
                END IF;

                VD_DATALANCTO :=
                    F_RETORNA_DATA_LANCPROVISOES (7,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO,
                                                  ITEM.DATAOPERACAO1);

                VD_DATAINTEGRACAO :=
                    F_RETORNA_DATA_LANCPROVISOES (7,
                                                  PCODREGRA,
                                                  DATA_INTEGRACAO,
                                                  ITEM.DATAOPERACAO,
                                                  ITEM.DATAOPERACAO1);

                --LAÇO NOS ITENS DA REGRA CONTABIL
                OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL ()
                    USING PCODREGRA;

                LOOP
                    FETCH CURSOR_ITENS INTO ITENSREGRA;

                    EXIT WHEN CURSOR_ITENS%NOTFOUND;

                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '7 - TRANSFERÊNCIA DE NUMERÁRIOS: ATRIBUINDO VALOR DO DOCUMENTO';
                    ---------------------------------------------------------------------------------
                    VS_DOCUMENTO := ITENSREGRA.DOCUMENTO;
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO1',
                                 TO_CHAR (ITEM.DATAOPERACAO1, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO',
                                 TO_CHAR (ITEM.DATAOPERACAO, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMTRANSOPERACAO',
                                 ITEM.NUMTRANSOPERACAO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMDOCUMENTO',
                                 ITEM.NUMDOCUMENTO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMCARR', ITEM.NUMCARR);

                    --FORMULA INFORMADA NO FILTRO--------------------------------------------------------
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '7 - TRANSFERÊNCIA DE NUMERÁRIOS: ATRIBUINDO VALOR DA FÓRMULA';
                    ---------------------------------------------------------------------------------
                    VN_VALORLANCTO := 0;

                    VS_FORMULA := ITENSREGRA.FORMULAS || ' + 0 ';
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORLANCTO([^_[:alnum:]])',
                                        NVL (ITEM.VALORLANCTO, 0) || '\1');

                    CALCULAREXPRESSAO;

                    --FIM DA FÓRMULA---------------------------------------------------------------------

                    IF VN_VALORLANCTO > 0
                    THEN
                        VS_CONTA :=
                            NVL (TRIM (ITENSREGRA.CODREDUZIDO_PC), '');
                        VS_CODFILIAL :=
                            CASE
                                WHEN ITENSREGRA.CODFILIAL =
                                     'FILIALLANCAMENTO'
                                THEN
                                    ITEM.CODFILIAL
                                ELSE
                                    ITENSREGRA.CODFILIAL
                            END;

                        IF     (SUBSTR (VS_CONTA, 1, 1) <> '0')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '1')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '2')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '3')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '4')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '5')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '6')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '7')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '8')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '9')
                        THEN
                            VS_CONTA :=
                                NVL (
                                    REPLACE (VS_CONTA,
                                             'CODCONTADEB',
                                             ITEM.CODCONTADEB),
                                    '');
                            VS_CONTA :=
                                NVL (
                                    REPLACE (VS_CONTA,
                                             'CODCONTACRED',
                                             ITEM.CODCONTACRED),
                                    '');
                        END IF;

                        VS_CONTA_EXISTE :=
                            F_VERIFICA_CONTA_EXISTE (VS_CONTA,
                                                     PCODPLANOCONTA);
                        TRATAR_CONTA_INEXISTENTE (VS_CONTA_EXISTE,
                                                  VS_TEMCONTAINEXISTENTE);

                        IF VS_CONTA_EXISTE IN ('S', 'I', 'X')
                        THEN
                            --HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO---------------------------------------
                            ---------------------------------------------------------------------------------
                            V_SQLERRO :=
                                '7 - TRANSFERÊNCIA DE NUMERÁRIOS: ATRIBUINDO VALOR DE HISTÓRICOS';
                            ---------------------------------------------------------------------------------
                            VS_HISTORICO := ITENSREGRA.HISTCOMPLREGRA;
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO1]',
                                         ITEM.DATAOPERACAO1);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO]',
                                         ITEM.DATAOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[HISTORICOLANCTO]',
                                         ITEM.HISTORICOLANCTO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[HISTORICOCOMPLEMENTO]',
                                         ITEM.HISTORICOCOMPLEMENTO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMTRANSOPERACAO]',
                                         ITEM.NUMTRANSOPERACAO);
                            VS_HISTORICO := SUBSTR (VS_HISTORICO, 1, 200);

                            --FIM HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO-----------------------------------

                            IF ITENSREGRA.NATUREZA = 'C'
                            THEN
                                VN_TOTALCREDITO :=
                                    ROUND (
                                          VN_TOTALCREDITO
                                        + ABS (VN_VALORLANCTO),
                                        2);
                                VS_NATUREZA := 'C';
                            ELSE
                                VN_TOTALDEBITO :=
                                    ROUND (
                                        VN_TOTALDEBITO + ABS (VN_VALORLANCTO),
                                        2);
                                VS_NATUREZA := 'D';
                            END IF;

                            --GUARDA FILIAIS
                            FILIAIS.CODFILIAL := '-1';

                            FOR VN_POSICAO IN 1 .. FILIAIS_LANCADAS.COUNT
                            LOOP
                                IF (FILIAIS_LANCADAS (VN_POSICAO).CODFILIAL =
                                    VS_CODFILIAL)
                                THEN
                                    FILIAIS := FILIAIS_LANCADAS (VN_POSICAO);
                                    VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

                                    EXIT;
                                END IF;
                            END LOOP;

                            IF (FILIAIS.CODFILIAL = '-1')
                            THEN
                                FILIAIS_LANCADAS.EXTEND;

                                FILIAIS :=
                                    FILIAIS_LANCADAS (FILIAIS_LANCADAS.COUNT);
                                VN_POSICAO_EM_ALTERACAO :=
                                    FILIAIS_LANCADAS.COUNT;

                                FILIAIS.CODFILIAL := VS_CODFILIAL;
                                FILIAIS.CGCFILIAL :=
                                    F_CGCFILIAL (VS_CODFILIAL);

                                FILIAIS_LANCADAS (VN_POSICAO_EM_ALTERACAO) :=
                                    FILIAIS;
                            END IF;

                            --GUARDA AS CONTAS PARA VERIFICAR SE ESTÃO IGUAIS POSTERIORMENTE
                            P_ARMAZENA_CONTAS_FILIAIS_LANC (VS_CONTA,
                                                            VS_NATUREZA,
                                                            VS_CODFILIAL,
                                                            FILIAIS_LANCADAS);

                            IF 'N' = 'S'
                            THEN
                                NULL;
                            ELSE
                                ---------------------------------------------------------------------------------
                                V_SQLERRO :=
                                    '7 - TRANSFERÊNCIA DE NUMERÁRIOS: EXECUTANDO PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA()';
                                ---------------------------------------------------------------------------------
                                --INSERE DADOS NA TABELA QUANDO NÃO ESTÁ TOTALIZANDO VALORES
                                VN_NUMSEQ := VN_NUMSEQ + 1;

                                P_GRAVA_DADOS_TABINTERMEDIARIA (
                                    VS_CODFILIAL,
                                    VN_NUMTRANSACAO,
                                    VN_NUMSEQ,
                                    VD_DATALANCTO,
                                    VS_DOCUMENTO,
                                    ITENSREGRA.CODHISTORICO,
                                    VS_HISTORICO,
                                    PCODPLANOCONTA,
                                    VS_CONTA,
                                    VS_NATUREZA,
                                    VN_VALORLANCTO,
                                    PCODREGRA,
                                    '',
                                    ITEM.NUMTRANSOPERACAO,
                                    F_RETORNA_TIPO_INCONSISTENCIA (
                                        VS_TEMCONTAINEXISTENTE),
                                    'P',
                                    VD_DATAINTEGRACAO,
                                    0,
                                    CASE
                                        WHEN VS_NATUREZA = 'D'
                                        THEN
                                            ITEM.CODBANCODEB
                                        ELSE
                                            ITEM.CODBANCOCRED
                                    END,
                                    CASE
                                        WHEN VS_NATUREZA = 'D'
                                        THEN
                                            ITEM.CODMOEDADEB
                                        ELSE
                                            ITEM.CODMOEDACRED
                                    END,
                                    '',
                                    TRUNC (SYSDATE),
                                    0,
                                    '',
                                    NULL,
                                    ITEM.NUMTRANSOPERACAO,
                                    '',
                                    ITENSREGRA.FORMULAS,
                                    ITENSREGRA.CODREDUZIDO_PC,
                                    'TRANSFERENCIA',
                                    'PCMOVCR',
                                    ITENSREGRA.TOTALIZAVALOR);
                            END IF;
                        END IF;
                    END IF;
                END LOOP;

                --GUARDA O NÚMERO DA TRANSAÇÃO
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            ELSE
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            END IF;
        END LOOP;

        --VERIFICA CONSISTÊNCIAS DO ÚLTIMO REGISTRO
        IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '7 - TRANSFERÊNCIA DE NUMERÁRIOS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
            ---------------------------------------------------------------------------------
            P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                        VD_DATALANCTO,
                                        VS_TEMCONTAINEXISTENTE,
                                        VN_TOTALDEBITO,
                                        VN_TOTALCREDITO,
                                        'N');
        END IF;

        CLOSE CURSOR_DADOS;

        RESULTADO := 'OK';
    EXCEPTION
        WHEN OTHERS
        THEN
            RESULTADO :=
                   'Ocorreu um erro quando: '
                || V_SQLERRO
                || CHR (13)
                || 'Erro Original: '
                || SQLERRM;
    END;

    /****************************************************************************
      PROCEDURE PARA GERAÇÃO DE 8 - MOVIMENTAÇÃO DE ESTOQUE
    *****************************************************************************/
    PROCEDURE P_DADOS_MOVESTOQUES (CURSOR_DADOS     IN     SYS_REFCURSOR,
                                   PCODREGRA        IN     NUMBER,
                                   PCODPLANOCONTA   IN     NUMBER,
                                   RESULTADO           OUT VARCHAR2)
    IS
        TYPE CONSULTA_MOVESTOQUES IS RECORD
        (
            CODFILIAL VARCHAR2 (2),
            DATAOPERACAO DATE,
            TIPOMOVIMENTACAO VARCHAR2 (2),
            DATACANCELADASAIDA DATE,
            DATACANCELADAENTRADA DATE,
            ESPECIENF PCNFBASEENT.ESPECIE%TYPE,
            SERIENF PCNFBASEENT.SERIE%TYPE,
            NUMNOTANF PCNFBASEENT.NUMNOTA%TYPE,
            CODCONTAGERENCIAL PCNFBASEENT.CODCONT%TYPE,
            CODPRODUTO PCPRODUT.CODPROD%TYPE,
            DESCRICAOPRODUTO PCPRODUT.DESCRICAO%TYPE,
            CODDEPARTAMENTO PCMOV.CODEPTO%TYPE,
            CODSECAO PCMOV.CODSEC%TYPE,
            TIPOEMBALAGEM PCMOV.EMBALAGEM%TYPE,
            TIPOUNIDADE PCMOV.UNIDADE%TYPE,
            TIPOOPERACAO PCMOV.CODOPER%TYPE,
            CODFISCALNF PCMOV.CODFISCAL%TYPE,
            TIPODESCARGA PCNFENT.TIPODESCARGA%TYPE,
            SITUACAOTRIBUTARIA PCMOV.SITTRIBUT%TYPE,
            HISTORICO VARCHAR2 (60),
            NUMTRANSOPERACAO NUMBER (10),
            TEMINTEGRACAO VARCHAR2 (1),
            VALORCUSTO NUMBER (22, 8)
        );

        ITEM                CONSULTA_MOVESTOQUES;
        ITENSREGRA          CONSULTA_ITENS;

        CURSOR_ITENS        SYS_REFCURSOR;

        VALORES_POSSIVEIS   TABELAVALORES;
        VALOR               VALORES;

        FILIAIS_LANCADAS    TABELAFILIAISLANCTO;
        FILIAIS             FILIAISLANCTO;
        VS_CONTA_EXISTE     VARCHAR2 (1);
    BEGIN
        LISTA_FORMULAS := TYPE_LISTA_FORMULAS ();
        VALORES_POSSIVEIS := TABELAVALORES ();
        FILIAIS_LANCADAS := TABELAFILIAISLANCTO ();

        VS_SEQGERADO := 'N';
        VS_FORMADTCONTABILIZACAO := '';
        VN_NUMTRANSACAO := 0;
        VS_DOCUMENTO := '';
        VS_TEMCONTAINEXISTENTE := 'N';

        --BUSCA DADOS DA REGRA
        SELECT FORMADTCONTABILIZACAO
          INTO VS_FORMADTCONTABILIZACAO
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        --INICIA LAÇO DOS DADOS
        LOOP
            FETCH CURSOR_DADOS INTO ITEM;

            EXIT WHEN CURSOR_DADOS%NOTFOUND;

            IF    (ITEM.TEMINTEGRACAO IS NULL)
               OR (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                   AND (ITEM.TEMINTEGRACAO = 'P'))
            THEN
                --------------------------------------------------------------------
                --VERIFICA SE ALTEROU O NUMTRANSOPERACAO PARA FAZER GRAVAÇÃO E RE-INICIAR VARIÁVEIS
                IF (VN_NUMTRANSOPERACAO <> ITEM.NUMTRANSOPERACAO)
                THEN
                    VS_SEQGERADO := 'N';

                    IF (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                        AND (ITEM.TEMINTEGRACAO = 'P'))
                    THEN
                        P_EXCLUI_LANCINTERMEDIARIA_IND (
                            PCODREGRA,
                            ITEM.NUMTRANSOPERACAO,
                            ITEM.DATAOPERACAO);
                    END IF;

                    --VERIFICA SE JÁ PASSOU POR ALGUM REGISTRO PARA ATRIBUIR INCONSISTÊNCIAS
                    IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) >
                       0
                    THEN
                        ---------------------------------------------------------------------------------
                        V_SQLERRO :=
                            '8 - MOVIMENTAÇÃO DE ESTOQUE: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
                        ---------------------------------------------------------------------------------
                        P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                                    VD_DATALANCTO,
                                                    VS_TEMCONTAINEXISTENTE,
                                                    VN_TOTALDEBITO,
                                                    VN_TOTALCREDITO,
                                                    'N');
                    END IF;

                    VS_TEMCONTAINEXISTENTE := 'N';
                END IF;

                --------------------------------------------------------------------

                --GERA NOVO NUMTRANSLANCTO
                IF VS_SEQGERADO = 'N'
                THEN
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '8 - MOVIMENTAÇÃO DE ESTOQUE: EXECUTANDO FUNÇÃO GERA_NUM_TRANS_LANCTO()';
                    ---------------------------------------------------------------------------------
                    VN_NUMTRANSACAO := F_GERA_NUM_TRANS_LANCTO ();

                    VN_NUMSEQ := 0;
                    VN_TOTALCREDITO := 0;
                    VN_TOTALDEBITO := 0;
                    VS_SEQGERADO := 'S';

                    CONTASDEBLANCTO := CONTAS_LANCADAS ();
                    CONTASCRELANCTO := CONTAS_LANCADAS ();
                    CGCSLANCTO := CGC_LANCADOS ();
                    VS_LISTAS_TRANSOTORIAS := CONTAS_LANCADAS ();

                    CONTASDEBLANCTO.EXTEND;
                    CONTASCRELANCTO.EXTEND;
                END IF;

                VD_DATALANCTO :=
                    F_RETORNA_DATA_LANCPROVISOES (8,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO);

                VD_DATAINTEGRACAO :=
                    F_RETORNA_DATA_LANCPROVISOES (8,
                                                  PCODREGRA,
                                                  DATA_INTEGRACAO,
                                                  ITEM.DATAOPERACAO);


                --LAÇO NOS ITENS DA REGRA CONTABIL
                OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL ()
                    USING PCODREGRA;

                LOOP
                    FETCH CURSOR_ITENS INTO ITENSREGRA;

                    EXIT WHEN CURSOR_ITENS%NOTFOUND;

                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '8 - MOVIMENTAÇÃO DE ESTOQUE: ATRIBUINDO VALOR DO DOCUMENTO';
                    ---------------------------------------------------------------------------------
                    VS_DOCUMENTO := ITENSREGRA.DOCUMENTO;
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO',
                                 TO_CHAR (ITEM.DATAOPERACAO, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'TIPOMOVIMENTACAO',
                                 ITEM.TIPOMOVIMENTACAO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMNOTANF', ITEM.NUMNOTANF);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMTRANSOPERACAO',
                                 ITEM.NUMTRANSOPERACAO);

                    --FORMULA INFORMADA NO FILTRO--------------------------------------------------------
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '8 - MOVIMENTAÇÃO DE ESTOQUE: ATRIBUINDO VALOR DA FÓRMULA';
                    ---------------------------------------------------------------------------------
                    VN_VALORLANCTO := 0;

                    VS_FORMULA := ITENSREGRA.FORMULAS || ' + 0 ';
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORCUSTO([^_[:alnum:]])',
                                        NVL (ITEM.VALORCUSTO, 0) || '\1');

                    CALCULAREXPRESSAO;

                    --FIM DA FÓRMULA---------------------------------------------------------------------

                    IF VN_VALORLANCTO <> 0
                    THEN
                        VS_CONTA := TRIM (ITENSREGRA.CODREDUZIDO_PC);
                        VS_CODFILIAL :=
                            CASE
                                WHEN ITENSREGRA.CODFILIAL =
                                     'FILIALLANCAMENTO'
                                THEN
                                    ITEM.CODFILIAL
                                ELSE
                                    ITENSREGRA.CODFILIAL
                            END;

                        VS_CONTA_EXISTE :=
                            F_VERIFICA_CONTA_EXISTE (VS_CONTA,
                                                     PCODPLANOCONTA);
                        TRATAR_CONTA_INEXISTENTE (VS_CONTA_EXISTE,
                                                  VS_TEMCONTAINEXISTENTE);

                        IF VS_CONTA_EXISTE IN ('S', 'I', 'X')
                        THEN
                            --HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO---------------------------------------
                            ---------------------------------------------------------------------------------
                            V_SQLERRO :=
                                '8 - MOVIMENTAÇÃO DE ESTOQUE: ATRIBUINDO VALOR DE HISTÓRICOS';
                            ---------------------------------------------------------------------------------
                            VS_HISTORICO := ITENSREGRA.HISTCOMPLREGRA;
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[TIPOMOVIMENTACAO]',
                                         ITEM.TIPOMOVIMENTACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMTRANSOPERACAO]',
                                         ITEM.NUMTRANSOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[ESPECIENF]',
                                         ITEM.ESPECIENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[SERIENF]',
                                         ITEM.SERIENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMNOTANF]',
                                         ITEM.NUMNOTANF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO]',
                                         ITEM.DATAOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODFISCALNF]',
                                         ITEM.CODFISCALNF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[TIPOEMBALAGEM]',
                                         ITEM.TIPOEMBALAGEM);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODDEPARTAMENTO]',
                                         ITEM.CODDEPARTAMENTO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODSECAO]',
                                         ITEM.CODSECAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODCONTAGERENCIAL]',
                                         ITEM.CODCONTAGERENCIAL);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODPRODUTO]',
                                         ITEM.CODPRODUTO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DESCRICAOPRODUTO]',
                                         ITEM.DESCRICAOPRODUTO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[TIPOUNIDADE]',
                                         ITEM.TIPOUNIDADE);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[HISTORICO]',
                                         ITEM.HISTORICO);
                            VS_HISTORICO := SUBSTR (VS_HISTORICO, 1, 200);

                            --FIM HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO-----------------------------------

                            IF ITENSREGRA.NATUREZA = 'C'
                            THEN
                                IF VN_VALORLANCTO < 0
                                THEN
                                    VS_NATUREZA := 'D';
                                ELSE
                                    VS_NATUREZA := 'C';
                                END IF;
                            ELSE
                                IF VN_VALORLANCTO < 0
                                THEN
                                    VS_NATUREZA := 'C';
                                ELSE
                                    VS_NATUREZA := 'D';
                                END IF;
                            END IF;

                            IF VS_NATUREZA = 'C'
                            THEN
                                VN_TOTALCREDITO :=
                                    ROUND (
                                          VN_TOTALCREDITO
                                        + ABS (VN_VALORLANCTO),
                                        2);
                            ELSE
                                VN_TOTALDEBITO :=
                                    ROUND (
                                        VN_TOTALDEBITO + ABS (VN_VALORLANCTO),
                                        2);
                            END IF;

                            --GUARDA FILIAIS
                            FILIAIS.CODFILIAL := '-1';

                            FOR VN_POSICAO IN 1 .. FILIAIS_LANCADAS.COUNT
                            LOOP
                                IF (FILIAIS_LANCADAS (VN_POSICAO).CODFILIAL =
                                    VS_CODFILIAL)
                                THEN
                                    FILIAIS := FILIAIS_LANCADAS (VN_POSICAO);
                                    VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

                                    EXIT;
                                END IF;
                            END LOOP;

                            IF (FILIAIS.CODFILIAL = '-1')
                            THEN
                                FILIAIS_LANCADAS.EXTEND;

                                FILIAIS :=
                                    FILIAIS_LANCADAS (FILIAIS_LANCADAS.COUNT);
                                VN_POSICAO_EM_ALTERACAO :=
                                    FILIAIS_LANCADAS.COUNT;

                                FILIAIS.CODFILIAL := VS_CODFILIAL;
                                FILIAIS.CGCFILIAL :=
                                    F_CGCFILIAL (VS_CODFILIAL);

                                FILIAIS_LANCADAS (VN_POSICAO_EM_ALTERACAO) :=
                                    FILIAIS;
                            END IF;

                            --GUARDA AS CONTAS PARA VERIFICAR SE ESTÃO IGUAIS POSTERIORMENTE
                            P_ARMAZENA_CONTAS_FILIAIS_LANC (VS_CONTA,
                                                            VS_NATUREZA,
                                                            VS_CODFILIAL,
                                                            FILIAIS_LANCADAS);

                            --GUARDA VALORES QUE FORAM TOTALIZADOS
                            IF 'N' = 'S' THEN
                            
                               NULL;
                            ELSE
                                ---------------------------------------------------------------------------------
                                V_SQLERRO :=
                                    '8 - MOVIMENTAÇÃO DE ESTOQUE: EXECUTANDO PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA()';
                                ---------------------------------------------------------------------------------
                                --INSERE DADOS NA TABELA QUANDO NÃO ESTÁ TOTALIZANDO VALORES
                                VN_NUMSEQ := VN_NUMSEQ + 1;

                                P_GRAVA_DADOS_TABINTERMEDIARIA (
                                    VS_CODFILIAL,
                                    VN_NUMTRANSACAO,
                                    VN_NUMSEQ,
                                    VD_DATALANCTO,
                                    VS_DOCUMENTO,
                                    ITENSREGRA.CODHISTORICO,
                                    VS_HISTORICO,
                                    PCODPLANOCONTA,
                                    VS_CONTA,
                                    VS_NATUREZA,
                                    ABS (VN_VALORLANCTO),
                                    PCODREGRA,
                                    '',
                                    ITEM.NUMTRANSOPERACAO,
                                    F_RETORNA_TIPO_INCONSISTENCIA (
                                        VS_TEMCONTAINEXISTENTE),
                                    'P',
                                    ITEM.DATAOPERACAO,
                                    ITEM.CODFISCALNF,
                                    0,
                                    '',
                                    '',
                                    VD_DATAINTEGRACAO,
                                    0,
                                    '',
                                    NULL,
                                    ITEM.NUMTRANSOPERACAO,
                                    ITEM.CODCONTAGERENCIAL,
                                    ITENSREGRA.FORMULAS,
                                    ITENSREGRA.CODREDUZIDO_PC,
                                    CASE
                                        WHEN SUBSTR (ITEM.TIPOOPERACAO, 1, 1) =
                                             'E'
                                        THEN
                                            'ESTOQUE_ENTRADA'
                                        ELSE
                                            'ESTOQUE_SAIDA'
                                    END,
                                    'PCMOV',
                                    ITENSREGRA.TOTALIZAVALOR);
                            END IF;
                        END IF;
                    END IF;
                END LOOP;

                --GUARDA O NÚMERO DA TRANSAÇÃO
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            ELSE
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            END IF;
        END LOOP;

        -- GRAVAR OS ITENS QUE AINDA NAO FORAM GRAVADOS DENTRO DE VALORES_POSSIVEIS
        IF VALORES_POSSIVEIS.COUNT > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '8 - MOVIMENTAÇÃO DE ESTOQUE: EXECUTANDO PROCEDURE P_GRAVAR_ITENS_TOTALIZADOS()';
            ---------------------------------------------------------------------------------
            P_GRAVAR_ITENS_TOTALIZADOS (VALORES_POSSIVEIS,
                                        PCODREGRA,
                                        PCODPLANOCONTA);
        END IF;

        --VERIFICA CONSISTÊNCIAS DO ÚLTIMO REGISTRO
        IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '8 - MOVIMENTAÇÃO DE ESTOQUE: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
            ---------------------------------------------------------------------------------
            P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                        VD_DATALANCTO,
                                        VS_TEMCONTAINEXISTENTE,
                                        VN_TOTALDEBITO,
                                        VN_TOTALCREDITO,
                                        'N');
        END IF;

        CLOSE CURSOR_DADOS;

        RESULTADO := 'OK';
    EXCEPTION
        WHEN OTHERS
        THEN
            RESULTADO :=
                   'Ocorreu um erro quando: '
                || V_SQLERRO
                || CHR (13)
                || 'Erro Original: '
                || SQLERRM;
    END;

    FUNCTION F_EH_CONTA_PRE_DEFINIDA (CODCONTA IN VARCHAR2)
        RETURN BOOLEAN
    IS
    BEGIN
        RETURN CODCONTA IN ('CODCONTADESP', 'CODCONTAFORNECEDOR');
    END;


    FUNCTION CONVERT_CURSOR_TO_ITENS (PONTEIRO IN SYS_REFCURSOR)
        RETURN CONSULTAS_PROVISOES
    IS
        ITEM    CONSULTA_LANCPROVISOES;
        ITENS   CONSULTAS_PROVISOES;
        POS     NUMBER (10);
    BEGIN
        ITENS := CONSULTAS_PROVISOES ();

        LOOP
            FETCH PONTEIRO INTO ITEM;

            EXIT WHEN PONTEIRO%NOTFOUND;
            ITENS.EXTEND;
            POS := ITENS.COUNT;
            ITENS (POS) := ITEM;
        END LOOP;

        RETURN ITENS;
    END;

    FUNCTION CONCATENA_REC_NUMS (PRECNUMPRINC NUMBER)
        RETURN VARCHAR2
    IS
        RETORNO   VARCHAR2 (2000);
        LINHA     CENTRO_CUSTO;
        VIRGULA   VARCHAR (1);
    BEGIN
        FOR LINHA IN (SELECT RECNUM
                        FROM PCLANC
                       WHERE PRECNUMPRINC IN (RECNUMPRINC, RECNUM))
        LOOP
            RETORNO := RETORNO || VIRGULA || LINHA.RECNUM;
            VIRGULA := ',';
        END LOOP;

        RETURN RETORNO;
    END;

    /****************************************************************************
      PROCEDURE PARA GERAÇÃO DE 9 - LANÇAMENTOS DE PROVISÕES
    *****************************************************************************/
    PROCEDURE P_DADOS_LANCPROVISOES (CURSOR_DADOS     IN     SYS_REFCURSOR,
                                     PCODREGRA        IN     NUMBER,
                                     PCODPLANOCONTA   IN     NUMBER,
                                     RESULTADO           OUT VARCHAR2)
    IS
        ITEM                    CONSULTA_LANCPROVISOES;
        ITENS                   CONSULTAS_PROVISOES;
        ITENSREGRA              CONSULTA_ITENS;

        CURSOR_ITENS            SYS_REFCURSOR;

        FILIAIS_LANCADAS        TABELAFILIAISLANCTO;
        FILIAIS                 FILIAISLANCTO;

        LANCTEMCENTROCUSTO      BOOLEAN;

        VS_RECNUM_CENTROCUSTO   VARCHAR2 (12);
        VS_CONTA_EXISTE         VARCHAR2 (1);
        VN_QTDECENTROCUSTO      NUMBER (5);

        VD_DATALANCTO_AUX       DATE;
    BEGIN
        LISTA_FORMULAS := TYPE_LISTA_FORMULAS ();

        FILIAIS_LANCADAS := TABELAFILIAISLANCTO ();

        VS_SEQGERADO := 'N';
        VS_FORMADTCONTABILIZACAO := '';
        VN_NUMTRANSACAO := 0;
        VS_DOCUMENTO := '';
        VS_TEMCONTAINEXISTENTE := 'N';
        VN_QTDECENTROCUSTO := 0;

        --BUSCA DADOS DA REGRA
        SELECT FORMADTCONTABILIZACAO, BUSCARDADOSPELADATA
          INTO VS_FORMADTCONTABILIZACAO, VS_BUSCARDADOSPELADATA
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        --INICIA LAÇO DOS DADOS
        ITENS := CONVERT_CURSOR_TO_ITENS (CURSOR_DADOS);

        --INICIA LAÇO DOS DADOS
        FOR POSITEM IN 1 .. ITENS.COUNT
        LOOP
            ITEM := ITENS (POSITEM);

            IF    (ITEM.TEMINTEGRACAO IS NULL)
               OR (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                   AND (ITEM.TEMINTEGRACAO = 'P'))
            THEN
                VD_DATALANCTO_AUX :=
                    F_RETORNA_DATA_LANCPROVISOES (9,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO,
                                                  ITEM.DATAOPERACAO1,
                                                  ITEM.DATAOPERACAO2,
                                                  ITEM.DATAOPERACAO3,
                                                  NULL);

                --------------------------------------------------------------------
                --VERIFICA SE ALTEROU O NUMTRANSOPERACAO PARA FAZER GRAVAÇÃO E RE-INICIAR VARIÁVEIS
                IF (   (VN_NUMTRANSOPERACAO <> ITEM.NUMTRANSOPERACAO)
                    OR (    (VN_NUMTRANSOPERACAO = ITEM.NUMTRANSOPERACAO)
                        AND (VS_FORMADTCONTABILIZACAO = 'B')
                        AND (VD_DATALANCTO <> ITEM.DATAOPERACAO))
                    OR (    (VN_NUMTRANSOPERACAO = ITEM.NUMTRANSOPERACAO)
                        AND (VS_FORMADTCONTABILIZACAO = 'C')
                        AND (VD_DATALANCTO <> ITEM.DATAOPERACAO1))
                    OR (    (VN_NUMTRANSOPERACAO = ITEM.NUMTRANSOPERACAO)
                        AND (VS_FORMADTCONTABILIZACAO = 'V')
                        AND (VD_DATALANCTO <> ITEM.DATAOPERACAO2))
                    OR (    (VN_NUMTRANSOPERACAO = ITEM.NUMTRANSOPERACAO)
                        AND (VS_FORMADTCONTABILIZACAO = 'E')
                        AND (VD_DATALANCTO <> ITEM.DATAOPERACAO3)))
                THEN
                    VS_SEQGERADO := 'N';

                    IF (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                        AND (ITEM.TEMINTEGRACAO = 'P'))
                    THEN
                        P_EXCLUI_LANCINTERMEDIARIA_IND (
                            PCODREGRA,
                            ITEM.NUMTRANSOPERACAO,
                            VD_DATALANCTO_AUX);
                    END IF;

                    --VERIFICA SE JÁ PASSOU POR ALGUM REGISTRO PARA ATRIBUIR INCONSISTÊNCIAS
                    IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) >
                       0
                    THEN
                        ---------------------------------------------------------------------------------
                        V_SQLERRO :=
                            '9 - LANÇAMENTOS DE PROVISÕES: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
                        ---------------------------------------------------------------------------------
                        P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                                    VD_DATALANCTO,
                                                    VS_TEMCONTAINEXISTENTE,
                                                    VN_TOTALDEBITO,
                                                    VN_TOTALCREDITO,
                                                    'N');
                    END IF;

                    VS_TEMCONTAINEXISTENTE := 'N';
                END IF;

                --------------------------------------------------------------------

                --GERA NOVO NUMTRANSLANCTO
                IF VS_SEQGERADO = 'N'
                THEN
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '9 - LANÇAMENTOS DE PROVISÕES: EXECUTANDO FUNÇÃO GERA_NUM_TRANS_LANCTO()';
                    ---------------------------------------------------------------------------------
                    VN_NUMTRANSACAO := F_GERA_NUM_TRANS_LANCTO ();
                    VS_NUMTRANSCENTROCUSTO := '';

                    VN_NUMSEQ := 0;
                    VN_TOTALCREDITO := 0;
                    VN_TOTALDEBITO := 0;
                    VS_SEQGERADO := 'S';

                    CONTASDEBLANCTO := CONTAS_LANCADAS ();
                    CONTASCRELANCTO := CONTAS_LANCADAS ();
                    CGCSLANCTO := CGC_LANCADOS ();
                    VS_LISTAS_TRANSOTORIAS := CONTAS_LANCADAS ();


                    CONTASDEBLANCTO.EXTEND;
                    CONTASCRELANCTO.EXTEND;
                END IF;

                VD_DATALANCTO :=
                    F_RETORNA_DATA_LANCPROVISOES (9,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO,
                                                  ITEM.DATAOPERACAO1,
                                                  ITEM.DATAOPERACAO2,
                                                  ITEM.DATAOPERACAO3,
                                                  NULL);

                VD_DATAINTEGRACAO :=
                    F_RETORNA_DATA_LANCPROVISOES (9,
                                                  PCODREGRA,
                                                  DATA_INTEGRACAO,
                                                  ITEM.DATAOPERACAO,
                                                  ITEM.DATAOPERACAO1,
                                                  ITEM.DATAOPERACAO2,
                                                  ITEM.DATAOPERACAO3,
                                                  NULL);

                --LAÇO NOS ITENS DA REGRA CONTABIL
                OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL ()
                    USING PCODREGRA;

                LOOP
                    FETCH CURSOR_ITENS INTO ITENSREGRA;

                    EXIT WHEN CURSOR_ITENS%NOTFOUND;

                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '9 - LANÇAMENTOS DE PROVISÕES: ATRIBUINDO VALOR DO DOCUMENTO';
                    ---------------------------------------------------------------------------------
                    VS_DOCUMENTO := ITENSREGRA.DOCUMENTO;
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMNOTA', ITEM.NUMNOTA);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMTRANSOPERACAO',
                                 ITEM.NUMTRANSOPERACAO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMLANCTOORIGINAL',
                                 ITEM.NUMTRANSOPERACAO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMINVOCE', ITEM.NUMINVOCE);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMPROFORMA',
                                 ITEM.NUMPROFORMA);


                    -------------------------------------

                    --FORMULA INFORMADA NO FILTRO--------------------------------------------------------
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '9 - LANÇAMENTOS DE PROVISÕES: ATRIBUINDO VALOR DA FÓRMULA';
                    ---------------------------------------------------------------------------------
                    VN_VALORLANCTO := 0;
                    VS_CODFILIAL :=
                        CASE
                            WHEN ITENSREGRA.CODFILIAL = 'FILIALLANCAMENTO'
                            THEN
                                ITEM.CODFILIAL
                            ELSE
                                ITENSREGRA.CODFILIAL
                        END;

                    VS_FORMULA := ITENSREGRA.FORMULAS || ' + 0 ';
                    VS_FORMULA :=
                        REPLACE (VS_FORMULA,
                                 'VALORTITULO',
                                 NVL (ITEM.VALORTITULO, 0));

                    CALCULAREXPRESSAO;

                    --FIM DA FÓRMULA---------------------------------------------------------------------

                    IF VN_VALORLANCTO > 0
                    THEN
                        VS_CONTA := TRIM (ITENSREGRA.CODREDUZIDO_PC);
                        VS_CODFILIAL :=
                            CASE
                                WHEN ITENSREGRA.CODFILIAL =
                                     'FILIALLANCAMENTO'
                                THEN
                                    ITEM.CODFILIAL
                                ELSE
                                    ITENSREGRA.CODFILIAL
                            END;

                        LANCTEMCENTROCUSTO := FALSE;

                        IF F_EH_CONTA_PRE_DEFINIDA (VS_CONTA)
                        THEN
                            IF VS_CONTA = 'CODCONTADESP'
                            THEN
                                VS_CONTA := ITEM.CODCONTADESP;

                                -- IF ITEM.NUMTRANSOPERACAO = ITEM.NUMLANCTOORIGINAL AND F_USA_CENTRO_CUSTO(VS_CONTA,PCODPLANOCONTA) THEN
                                SELECT COUNT (*)
                                  INTO VN_QTDECENTROCUSTO
                                  FROM PCRATEIOCENTROCUSTO C
                                 WHERE C.RECNUM = ITEM.RECNUM;

                                IF VN_QTDECENTROCUSTO > 0
                                THEN
                                    LANCTEMCENTROCUSTO := TRUE;
                                END IF;
                            ELSE
                                VS_CONTA := ITEM.CODCONTAFORNECEDOR;
                            END IF;
                        END IF;

                        --VERIFICA SE A PERNA DA INTEGRAÇÃO TEM CENTRO DE CUSTO
                        IF     F_LANCTO_TEM_CENTROCUSTO (VS_CONTA,
                                                         ITEM.CODCONTA,
                                                         9,
                                                         0,
                                                         0,
                                                         '0',
                                                         PCODPLANOCONTA) =
                               'S'
                           AND (LANCTEMCENTROCUSTO)
                        THEN
                            VS_RECNUM_CENTROCUSTO := ITEM.NUMLANCTOORIGINAL;
                        ELSIF ITEM.IMPOSTO = 'S' AND (LANCTEMCENTROCUSTO)
                        THEN
                            VS_RECNUM_CENTROCUSTO := ITEM.NUMLANCTOORIGINAL;
                        ELSE
                            VS_RECNUM_CENTROCUSTO := '';
                        END IF;

                        --AJUSTE TEMPORÁRIO POR CAUSA DE MELHORIA PENDENTE SOBRE "RATEIO DE CONTAS (COM RATEIO DE CENTRO DE CUSTO)"
                        --VIDE A SOLICITAÇÃO: FIN-4744
                        --09.10.2018 - JOAO TORRES
                        --ANALISTAS CIENTES: DANIEL CAVALCANTE E MARCELO ARISTEU
                        IF     (LANCTEMCENTROCUSTO)
                           AND (   VS_RECNUM_CENTROCUSTO = ''
                                OR VS_RECNUM_CENTROCUSTO IS NULL)
                        THEN
                            LANCTEMCENTROCUSTO := FALSE;
                        END IF;

                        VS_CONTA_EXISTE :=
                            F_VERIFICA_CONTA_EXISTE (VS_CONTA,
                                                     PCODPLANOCONTA);
                        TRATAR_CONTA_INEXISTENTE (VS_CONTA_EXISTE,
                                                  VS_TEMCONTAINEXISTENTE);

                        IF VS_CONTA_EXISTE IN ('S', 'I')
                        THEN
                            --HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO---------------------------------------
                            ---------------------------------------------------------------------------------
                            V_SQLERRO :=
                                '9 - LANÇAMENTOS DE PROVISÕES: ATRIBUINDO VALOR DE HISTÓRICOS';
                            ---------------------------------------------------------------------------------
                            VS_HISTORICO := ITENSREGRA.HISTCOMPLREGRA;
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[FORNECEDOR]',
                                         ITEM.FORNECEDOR);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODFORNEC]',
                                         ITEM.CODFORNEC);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[HISTORICO]',
                                         ITEM.HISTORICO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[HISTORICO2]',
                                         ITEM.HISTORICO2);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMNOTA]',
                                         ITEM.NUMNOTA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[STATUS]',
                                         ITEM.STATUS);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NOMECONTAGERENCIAL]',
                                         ITEM.NOMECONTAGERENCIAL);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMTRANSOPERACAO]',
                                         ITEM.NUMTRANSOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMLANCTOORIGINAL]',
                                         ITEM.NUMLANCTOORIGINAL);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DUPLICATA]',
                                         ITEM.DUPLICATA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[FORNECEDORPRINC]',
                                         ITEM.FORNECEDORPRINC);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMEROCONTRATO]',
                                         ITEM.NUMEROCONTRATO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMNEGOCIACAO]',
                                         ITEM.NUMNEGOCIACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMDIIMPORTACAO]',
                                         ITEM.NUMDIIMPORTACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[IDCONTROLEEMBARQUE]',
                                         ITEM.IDCONTROLEEMBARQUE);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMINVOCE]',
                                         ITEM.NUMINVOCE);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMPROFORMA]',
                                         ITEM.NUMPROFORMA);

                            VS_HISTORICO := SUBSTR (VS_HISTORICO, 1, 200);

                            --FIM HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO-----------------------------------

                            IF ITENSREGRA.NATUREZA = 'C'
                            THEN
                                VN_TOTALCREDITO :=
                                    ROUND (
                                          VN_TOTALCREDITO
                                        + ABS (VN_VALORLANCTO),
                                        2);
                                VS_NATUREZA := 'C';
                            ELSE
                                VN_TOTALDEBITO :=
                                    ROUND (
                                        VN_TOTALDEBITO + ABS (VN_VALORLANCTO),
                                        2);
                                VS_NATUREZA := 'D';
                            END IF;

                            --GUARDA FILIAIS
                            FILIAIS.CODFILIAL := '-1';

                            FOR VN_POSICAO IN 1 .. FILIAIS_LANCADAS.COUNT
                            LOOP
                                IF (FILIAIS_LANCADAS (VN_POSICAO).CODFILIAL =
                                    VS_CODFILIAL)
                                THEN
                                    FILIAIS := FILIAIS_LANCADAS (VN_POSICAO);
                                    VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

                                    EXIT;
                                END IF;
                            END LOOP;

                            IF (FILIAIS.CODFILIAL = '-1')
                            THEN
                                FILIAIS_LANCADAS.EXTEND;

                                FILIAIS :=
                                    FILIAIS_LANCADAS (FILIAIS_LANCADAS.COUNT);
                                VN_POSICAO_EM_ALTERACAO :=
                                    FILIAIS_LANCADAS.COUNT;

                                FILIAIS.CODFILIAL := VS_CODFILIAL;
                                FILIAIS.CGCFILIAL :=
                                    F_CGCFILIAL (VS_CODFILIAL);

                                FILIAIS_LANCADAS (VN_POSICAO_EM_ALTERACAO) :=
                                    FILIAIS;
                            END IF;

                            --GUARDA AS CONTAS PARA VERIFICAR SE ESTÃO IGUAIS POSTERIORMENTE
                            P_ARMAZENA_CONTAS_FILIAIS_LANC (VS_CONTA,
                                                            VS_NATUREZA,
                                                            VS_CODFILIAL,
                                                            FILIAIS_LANCADAS);

                            IF 'N' = 'S'
                            THEN
                                NULL;
                            ELSE
                                ---------------------------------------------------------------------------------
                                V_SQLERRO :=
                                    '9 - LANÇAMENTOS DE PROVISÕES: EXECUTANDO PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA()';

                                ---------------------------------------------------------------------------------
                                --INSERE CENTRO DE CUSTO
                                IF     LANCTEMCENTROCUSTO
                                   AND (VS_RECNUM_CENTROCUSTO IS NOT NULL)
                                THEN
                                    VS_NUMTRANSCENTROCUSTO :=
                                        F_RETORNA_NUMTRANS_CENTROCUSTO ();
                                END IF;

                                --INSERE DADOS NA TABELA QUANDO NÃO ESTÁ TOTALIZANDO VALORES
                                VN_NUMSEQ := VN_NUMSEQ + 1;

                                P_GRAVA_DADOS_TABINTERMEDIARIA (
                                    VS_CODFILIAL,
                                    VN_NUMTRANSACAO,
                                    VN_NUMSEQ,
                                    VD_DATALANCTO,
                                    VS_DOCUMENTO,
                                    ITENSREGRA.CODHISTORICO,
                                    VS_HISTORICO,
                                    PCODPLANOCONTA,
                                    VS_CONTA,
                                    VS_NATUREZA,
                                    VN_VALORLANCTO,
                                    PCODREGRA,
                                    '',
                                    ITEM.NUMTRANSOPERACAO,
                                    F_RETORNA_TIPO_INCONSISTENCIA (
                                        VS_TEMCONTAINEXISTENTE),
                                    'P',
                                    VD_DATAINTEGRACAO,
                                    0,
                                    0,
                                    '',
                                    VS_NUMTRANSCENTROCUSTO,
                                    TRUNC (SYSDATE),
                                    ITEM.CODFORNEC,
                                    ITEM.TIPOPARCEIRO,
                                    NULL,
                                    ITEM.NUMLANCTOORIGINAL,
                                    '',
                                    ITENSREGRA.FORMULAS,
                                    ITENSREGRA.CODREDUZIDO_PC,
                                    'CPREVISTAS',
                                    'PCLANC',
                                    ITENSREGRA.TOTALIZAVALOR);


                                IF     LANCTEMCENTROCUSTO
                                   AND (VS_RECNUM_CENTROCUSTO IS NOT NULL)
                                THEN
                                    P_GRAVA_PCINTER_CENTROCUSTO (
                                        ITEM.recnum,
                                        VS_NUMTRANSCENTROCUSTO,
                                        PCODREGRA,
                                        (CASE VS_BUSCARDADOSPELADATA
                                             WHEN 'C'
                                             THEN
                                                 NVL (ITEM.DATAOPERACAO1,
                                                      ITEM.DATAOPERACAO)
                                             WHEN 'E'
                                             THEN
                                                 NVL (ITEM.DATAOPERACAO3,
                                                      ITEM.DATAOPERACAO)
                                             ELSE
                                                 ITEM.DATAOPERACAO
                                         END),
                                        FALSE,
                                        0,
                                        VN_NUMTRANSACAO,
                                           VS_HISTORICO
                                        || vs_conta
                                        || VS_CODFILIAL,
                                        ITEM.PERCRATEIO);
                                END IF;

                                VS_NUMTRANSCENTROCUSTO := '';
                            END IF;
                        END IF;
                    END IF;
                END LOOP;

                --GUARDA O NÚMERO DA TRANSAÇÃO
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            ELSE
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            END IF;
        END LOOP;

        --VERIFICA CONSISTÊNCIAS DO ÚLTIMO REGISTRO
        IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '9 - LANÇAMENTOS DE PROVISÕES: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
            ---------------------------------------------------------------------------------
            P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                        VD_DATALANCTO,
                                        VS_TEMCONTAINEXISTENTE,
                                        VN_TOTALDEBITO,
                                        VN_TOTALCREDITO,
                                        'N');
        END IF;

        CLOSE CURSOR_DADOS;

        RESULTADO := 'OK';
    EXCEPTION
        WHEN OTHERS
        THEN
            RESULTADO :=
                   'Ocorreu um erro quando: '
                || V_SQLERRO
                || CHR (13)
                || 'Erro Original: '
                || SQLERRM;
    END;

    /****************************************************************************
      PROCEDURE PARA GERAÇÃO DE 10 - RECEBIMENTO DE ACERTO DE CARGAS
    *****************************************************************************/
    PROCEDURE P_DADOS_ACERTOCARGAS (CURSOR_DADOS     IN     SYS_REFCURSOR,
                                    PCODREGRA        IN     NUMBER,
                                    PCODPLANOCONTA   IN     NUMBER,
                                    RESULTADO           OUT VARCHAR2)
    IS
        TYPE CONSULTA_LANCPROVISOES IS RECORD
        (
            CODFILIAL VARCHAR2 (2),
            DATAOPERACAO DATE,
            DATAOPERACAO1 DATE,
            DATAPGTO DATE,
            DATAVENCIMENTO DATE,
            DATADEVOLUCAO DATE,
            VALORTITULO PCLANCAMENTO.VALOR%TYPE,
            VALORPAGO PCLANCAMENTO.VALOR%TYPE,
            VALORJUROS PCLANCAMENTO.VALOR%TYPE,
            VALORDESCONTO PCLANCAMENTO.VALOR%TYPE,
            VALORDEVOLUCAO PCLANCAMENTO.VALOR%TYPE,
            VALORDESPCARTORAIS PCLANCAMENTO.VALOR%TYPE,
            VALORDESPBANCARIAS PCLANCAMENTO.VALOR%TYPE,
            VALOROUTROSACRESC PCLANCAMENTO.VALOR%TYPE,
            VALORIMPRENDAORGPUB PCLANCAMENTO.VALOR%TYPE,
            VALORCONTSOCIALORGPUB PCLANCAMENTO.VALOR%TYPE,
            VALORPISORGPUB PCLANCAMENTO.VALOR%TYPE,
            VALORCOFINSORGPUB PCLANCAMENTO.VALOR%TYPE,
            VALORICMSRETORGPUB PCLANCAMENTO.VALOR%TYPE,
            VALOROUTRASDEDUCOESORGPUB PCLANCAMENTO.VALOR%TYPE,
            DUPLICATA NUMBER (10),
            PRESTACAO VARCHAR2 (2),
            CLIENTE PCCLIENT.CLIENTE%TYPE,
            CODCOBRANCA VARCHAR2 (4),
            CODCOBRANCAORIGINAL PCPREST.CODCOBORIG%TYPE,
            CODCOBRANCANF PCNFSAID.CODCOB%TYPE,
            HISTMOVBANCARIACLIENTE PCMOVCR.HISTORICO2%TYPE,
            ROTINALANCAMENTO NUMBER (6),
            NUMCONTABANCO VARCHAR2 (10),
            CODBANCO NUMBER (4),
            STATUS VARCHAR2 (1),
            STATUSTITULO VARCHAR2 (1),
            BANCOBAIXA VARCHAR2 (30),
            NUMTRANSOPERACAO NUMBER (10),
            TIPOOPERACAO VARCHAR2 (1),
            CONTACONTABILBANCO VARCHAR2 (12),
            NUMEROCARREGAMENTO NUMBER (12),
            VENDAASSISTIDA VARCHAR2 (1),
            CODCONTAGERENCIAL PCNFSAID.CODCONT%TYPE,
            CONTACONTABIL VARCHAR2 (12),
            CODCLI PCCLIENT.CODCLI%TYPE,
            NUMTRANSVENDA PCPREST.NUMTRANSVENDA%TYPE,
            TEMINTEGRACAO VARCHAR2 (1),
            VALORMULTA PCLANCAMENTO.VALOR%TYPE,
            CONTATRANSITORIA PCMODELOPC.CODREDUZIDO_PC%TYPE,
            CODFILIALBANCO PCFILIAL.CODIGO%TYPE,
            ERRO_MULTIFILIAL VARCHAR2 (1)
        );

        ITEM                     CONSULTA_LANCPROVISOES;
        ITENSREGRA               CONSULTA_ITENS;

        CURSOR_ITENS             SYS_REFCURSOR;

        FILIAIS_LANCADAS         TABELAFILIAISLANCTO;
        FILIAIS                  FILIAISLANCTO;

        VS_RECNUM_CENTROCUSTO    VARCHAR2 (12);
        VB_ECONTA_PREDEFINIDA    BOOLEAN;

        TYPE RECORD_CODREDUZIDO_NUMTRANSCC IS RECORD
        (
            CODREDUZIDO_PC PCLANCINTERMEDIARIA.CODREDUZIDO_PC%TYPE,
            NUMTRANSCC PCLANCINTERMEDIARIA.NUMTRANSCENTROCUSTO%TYPE
        );

        TYPE TABELA_CODREDUZIDO_NUMTRANSCC
            IS TABLE OF RECORD_CODREDUZIDO_NUMTRANSCC;

        CODREDUZIDO_NUMTRANSCC   TABELA_CODREDUZIDO_NUMTRANSCC;

        VS_CONTAIGUAL            VARCHAR2 (1);
        VS_USACONTATRANSITORIA   VARCHAR2 (1);

        VS_CONTA_EXISTE          VARCHAR2 (1);
        VD_DATALANCTO_AUX        DATE;
        VS_ERRO_MULTIFILIAL VARCHAR2(1);
    BEGIN
        LISTA_FORMULAS := TYPE_LISTA_FORMULAS ();


        FILIAIS_LANCADAS := TABELAFILIAISLANCTO ();

        VS_SEQGERADO := 'N';
        VS_FORMADTCONTABILIZACAO := '';
        VN_NUMTRANSACAO := 0;
        VS_DOCUMENTO := '';
        VB_ECONTA_PREDEFINIDA := FALSE;
        VS_TEMCONTAINEXISTENTE := 'N';
        VS_ERRO_MULTIFILIAL := 'N';

        --BUSCA DADOS DA REGRA
        SELECT FORMADTCONTABILIZACAO,
               BUSCARDADOSPELADATA,
               USACONTATRANSITORIA
          INTO VS_FORMADTCONTABILIZACAO,
               VS_BUSCARDADOSPELADATA,
               VS_USACONTATRANSITORIA
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        --INICIA LAÇO DOS DADOS
        LOOP
            FETCH CURSOR_DADOS INTO ITEM;

            EXIT WHEN CURSOR_DADOS%NOTFOUND;

            IF    (ITEM.TEMINTEGRACAO IS NULL)
               OR (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                   AND (ITEM.TEMINTEGRACAO = 'P'))
            THEN
                --PEGA DATA DE LANÇAMENTO DE ACORDO COM SELECIONADO NA REGRA
                VD_DATALANCTO_AUX :=
                    F_RETORNA_DATA_LANCPROVISOES (10,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO,
                                                  ITEM.DATAOPERACAO1,
                                                  NULL,
                                                  NULL,
                                                  ITEM.DATAPGTO);

                --------------------------------------------------------------------
                --VERIFICA SE ALTEROU O NUMTRANSOPERACAO PARA FAZER GRAVAÇÃO E RE-INICIAR VARIÁVEIS
                IF (VN_NUMTRANSOPERACAO <> ITEM.NUMTRANSOPERACAO)
                THEN
                    VS_SEQGERADO := 'N';

                    IF (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                        AND (ITEM.TEMINTEGRACAO = 'P'))
                    THEN
                        P_EXCLUI_LANCINTERMEDIARIA_IND (
                            PCODREGRA,
                            ITEM.NUMTRANSOPERACAO,
                            VD_DATALANCTO_AUX);
                    END IF;

                    --VERIFICA SE JÁ PASSOU POR ALGUM REGISTRO PARA ATRIBUIR INCONSISTÊNCIAS
                    IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) >
                       0
                    THEN
                        ---------------------------------------------------------------------------------
                        V_SQLERRO :=
                            '10 - RECEBIMENTO DE ACERTO DE CARGAS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
                        ---------------------------------------------------------------------------------
                        P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                                    VD_DATALANCTO,
                                                    VS_TEMCONTAINEXISTENTE,
                                                    VN_TOTALDEBITO,
                                                    VN_TOTALCREDITO,
                                                    VS_ERRO_MULTIFILIAL);
                    END IF;

                    VS_TEMCONTAINEXISTENTE := 'N';
                END IF;

                --------------------------------------------------------------------

                --GERA NOVO NUMTRANSLANCTO
                IF VS_SEQGERADO = 'N'
                THEN
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '10 - ACERTO DE CARGAS: EXECUTANDO FUNÇÃO GERA_NUM_TRANS_LANCTO()';
                    ---------------------------------------------------------------------------------
                    VN_NUMTRANSACAO := F_GERA_NUM_TRANS_LANCTO ();
                    VS_NUMTRANSCENTROCUSTO := '';

                    VN_NUMSEQ := 0;
                    VN_TOTALCREDITO := 0;
                    VN_TOTALDEBITO := 0;
                    VS_SEQGERADO := 'S';

                    CONTASDEBLANCTO := CONTAS_LANCADAS ();
                    CONTASCRELANCTO := CONTAS_LANCADAS ();
                    CGCSLANCTO := CGC_LANCADOS ();
                    VS_LISTAS_TRANSOTORIAS := CONTAS_LANCADAS ();

                    CONTASDEBLANCTO.EXTEND;
                    CONTASCRELANCTO.EXTEND;
                    CODREDUZIDO_NUMTRANSCC :=
                        TABELA_CODREDUZIDO_NUMTRANSCC ();
                END IF;

                VS_ERRO_MULTIFILIAL := ITEM.ERRO_MULTIFILIAL;

                --PEGA DATA DE LANÇAMENTO DE ACORDO COM SELECIONADO NA REGRA
                VD_DATALANCTO :=
                    F_RETORNA_DATA_LANCPROVISOES (10,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO,
                                                  ITEM.DATAOPERACAO1,
                                                  NULL,
                                                  NULL,
                                                  ITEM.DATAPGTO);

                VD_DATAINTEGRACAO :=
                    F_RETORNA_DATA_LANCPROVISOES (10,
                                                  PCODREGRA,
                                                  DATA_INTEGRACAO,
                                                  ITEM.DATAOPERACAO,
                                                  ITEM.DATAOPERACAO1,
                                                  NULL,
                                                  NULL,
                                                  ITEM.DATAPGTO);


                --LAÇO NOS ITENS DA REGRA CONTABIL
                IF VS_USACONTATRANSITORIA = 'S'
                THEN
                    OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL (TRUE)
                        USING PCODREGRA, PCODREGRA, PCODREGRA;
                ELSE
                    OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL (FALSE)
                        USING PCODREGRA;
                END IF;

                LOOP
                    FETCH CURSOR_ITENS INTO ITENSREGRA;

                    EXIT WHEN CURSOR_ITENS%NOTFOUND;

                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '10 - ACERTO DE CARGAS: ATRIBUINDO VALOR DO DOCUMENTO';
                    ---------------------------------------------------------------------------------
                    VS_DOCUMENTO := ITENSREGRA.DOCUMENTO;
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO1',
                                 TO_CHAR (ITEM.DATAOPERACAO1, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO',
                                 TO_CHAR (ITEM.DATAOPERACAO, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAPGTO',
                                 TO_CHAR (ITEM.DATAPGTO, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAVENCIMENTO',
                                 TO_CHAR (ITEM.DATAVENCIMENTO, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'DUPLICATA', ITEM.DUPLICATA);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMTRANSOPERACAO',
                                 ITEM.NUMTRANSOPERACAO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMEROCARREGAMENTO',
                                 ITEM.NUMEROCARREGAMENTO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'CODCONTAGERENCIAL',
                                 ITEM.CODCONTAGERENCIAL);
                    -------------------------------------

                    --FORMULA INFORMADA NO FILTRO--------------------------------------------------------
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '10 - ACERTO DE CARGAS: ATRIBUINDO VALOR DA FÓRMULA';
                    ---------------------------------------------------------------------------------
                    VN_VALORLANCTO := 0;

                    VS_FORMULA := ITENSREGRA.FORMULAS || ' + 0 ';
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORTITULO([^_[:alnum:]])',
                                        NVL (ITEM.VALORTITULO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORPAGO([^_[:alnum:]])',
                                        NVL (ITEM.VALORPAGO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORJUROS([^_[:alnum:]])',
                                        NVL (ITEM.VALORJUROS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORDESCONTO([^_[:alnum:]])',
                                        NVL (ITEM.VALORDESCONTO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORDEVOLUCAO([^_[:alnum:]])',
                                        NVL (ITEM.VALORDEVOLUCAO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORDESPCARTORAIS([^_[:alnum:]])',
                            NVL (ITEM.VALORDESPCARTORAIS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORDESPBANCARIAS([^_[:alnum:]])',
                            NVL (ITEM.VALORDESPBANCARIAS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALOROUTROSACRESC([^_[:alnum:]])',
                            NVL (ITEM.VALOROUTROSACRESC, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORIMPRENDAORGPUB([^_[:alnum:]])',
                            NVL (ITEM.VALORIMPRENDAORGPUB, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORCONTSOCIALORGPUB([^_[:alnum:]])',
                            NVL (ITEM.VALORCONTSOCIALORGPUB, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORPISORGPUB([^_[:alnum:]])',
                                        NVL (ITEM.VALORPISORGPUB, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORCOFINSORGPUB([^_[:alnum:]])',
                            NVL (ITEM.VALORCOFINSORGPUB, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORICMSRETORGPUB([^_[:alnum:]])',
                            NVL (ITEM.VALORICMSRETORGPUB, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALOROUTRASDEDUCOESORGPUB([^_[:alnum:]])',
                            NVL (ITEM.VALOROUTRASDEDUCOESORGPUB, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORMULTA([^_[:alnum:]])',
                                        NVL (ITEM.VALORMULTA, 0) || '\1');


                    CALCULAREXPRESSAO;
                    --FIM DA FÓRMULA---------------------------------------------------------------------

                    VN_VALORLANCTO := ABS (VN_VALORLANCTO);

                    IF VN_VALORLANCTO <> 0
                    THEN
                        VS_CONTA := TRIM (ITENSREGRA.CODREDUZIDO_PC);

                        IF     (ITEM.CONTATRANSITORIA <> '-1')
                           AND (VS_USACONTATRANSITORIA = 'S')
                        THEN
                            VS_CODFILIAL :=
                                CASE
                                    WHEN     (ITENSREGRA.CODFILIAL =
                                              'FILIALLANCAMENTO')
                                         AND (ITENSREGRA.CODREDUZIDO_PC <>
                                              'CONTACONTABILBANCO')
                                         AND ((ITENSREGRA.CODREDUZIDO_PC <>
                                               'CONTATRANSITORIA'))
                                    THEN
                                        ITEM.CODFILIAL
                                    WHEN     (ITENSREGRA.CODFILIAL =
                                              'FILIALLANCAMENTO')
                                         AND (ITENSREGRA.CODREDUZIDO_PC =
                                              'CONTACONTABILBANCO')
                                    THEN
                                        ITEM.CODFILIALBANCO
                                    WHEN     (ITENSREGRA.CODFILIAL =
                                              'FILIALLANCAMENTO')
                                         AND (    (ITENSREGRA.CODREDUZIDO_PC =
                                                   'CONTATRANSITORIA')
                                              AND (ITEM.CODFILIAL <>
                                                   ITEM.CODFILIALBANCO))
                                    THEN
                                        ITEM.CODFILIAL
                                    WHEN     (ITENSREGRA.CODFILIAL =
                                              'FILIALTRANSITORIA')
                                         AND (ITEM.CODFILIAL <>
                                              ITEM.CODFILIALBANCO)
                                    THEN
                                        ITEM.CODFILIALBANCO
                                    WHEN    (ITENSREGRA.CODFILIAL =
                                             'FILIALTRANSITORIA')
                                         OR (    (ITENSREGRA.CODREDUZIDO_PC =
                                                  'CONTATRANSITORIA')
                                             AND (ITEM.CODFILIAL =
                                                  ITEM.CODFILIALBANCO))
                                    THEN
                                        '-1'
                                    ELSE
                                        ITENSREGRA.CODFILIAL
                                END;
                        ELSE
                            VS_CODFILIAL :=
                                CASE
                                    WHEN (ITENSREGRA.CODFILIAL =
                                          'FILIALLANCAMENTO')
                                    THEN
                                        ITEM.CODFILIAL
                                    WHEN    (ITENSREGRA.CODFILIAL =
                                             'FILIALTRANSITORIA')
                                         OR (ITENSREGRA.CODREDUZIDO_PC =
                                             'CONTATRANSITORIA')
                                    THEN
                                        '-1'
                                    ELSE
                                        ITENSREGRA.CODFILIAL
                                END;
                        END IF;

                        IF VS_CODFILIAL = '-1'
                        THEN
                            GOTO pula_registro;
                        END IF;

                        VB_ECONTA_PREDEFINIDA := FALSE;

                        IF     (SUBSTR (VS_CONTA, 1, 1) <> '0')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '1')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '2')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '3')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '4')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '5')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '6')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '7')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '8')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '9')
                        THEN
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CONTACONTABILBANCO',
                                         ITEM.CONTACONTABILBANCO);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CONTACONTABIL',
                                         ITEM.CONTACONTABIL);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CONTATRANSITORIA',
                                         ITEM.CONTATRANSITORIA);
                            VB_ECONTA_PREDEFINIDA := TRUE;

                            VS_CONTAIGUAL := 'N';

                            FOR VN_POSIGUAIS IN 1 ..
                                                VS_LISTAS_TRANSOTORIAS.COUNT
                            LOOP
                                IF VS_LISTAS_TRANSOTORIAS (VN_POSIGUAIS) =
                                   ITEM.CONTATRANSITORIA
                                THEN
                                    VS_CONTAIGUAL := 'S';
                                    EXIT;
                                END IF;
                            END LOOP;

                            IF VS_CONTAIGUAL = 'N'
                            THEN
                                VS_LISTAS_TRANSOTORIAS.EXTEND;
                                VS_LISTAS_TRANSOTORIAS (
                                    VS_LISTAS_TRANSOTORIAS.COUNT) :=
                                    ITEM.CONTATRANSITORIA;
                            END IF;
                        END IF;

                        IF VS_CONTA = '-1' /*Usa conta transitória, mas o lançamento em questão não tem conta transitória*/
                        THEN
                            VS_CONTA_EXISTE := 'T';
                        ELSE
                            VS_CONTA_EXISTE :=
                                F_VERIFICA_CONTA_EXISTE (VS_CONTA,
                                                         PCODPLANOCONTA);
                            TRATAR_CONTA_INEXISTENTE (VS_CONTA_EXISTE,
                                                      VS_TEMCONTAINEXISTENTE);
                        END IF;

                        IF VS_CONTA_EXISTE IN ('S', 'I', 'X')
                        THEN
                            --HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO---------------------------------------
                            ---------------------------------------------------------------------------------
                            V_SQLERRO :=
                                '10 - ACERTO DE CARGAS: ATRIBUINDO VALOR DE HISTÓRICOS';
                            ---------------------------------------------------------------------------------
                            VS_HISTORICO := ITENSREGRA.HISTCOMPLREGRA;
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO1]',
                                         ITEM.DATAOPERACAO1);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO]',
                                         ITEM.DATAOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAPGTO]',
                                         ITEM.DATAPGTO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAVENCIMENTO]',
                                         ITEM.DATAVENCIMENTO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATADEVOLUCAO]',
                                         ITEM.DATADEVOLUCAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DUPLICATA]',
                                         ITEM.DUPLICATA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[PRESTACAO]',
                                         ITEM.PRESTACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CLIENTE]',
                                         ITEM.CLIENTE);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODCOBRANCA]',
                                         ITEM.CODCOBRANCA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[HISTMOVBANCARIACLIENTE]',
                                         ITEM.HISTMOVBANCARIACLIENTE);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMCONTABANCO]',
                                         ITEM.NUMCONTABANCO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[STATUS]',
                                         ITEM.STATUS);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[BANCOBAIXA]',
                                         ITEM.BANCOBAIXA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMTRANSOPERACAO]',
                                         ITEM.NUMTRANSOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMEROCARREGAMENTO]',
                                         ITEM.NUMEROCARREGAMENTO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODBANCO]',
                                         ITEM.CODBANCO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[VENDAASSISTIDA]',
                                         ITEM.VENDAASSISTIDA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODCONTAGERENCIAL]',
                                         ITEM.CODCONTAGERENCIAL);
                            VS_HISTORICO := SUBSTR (VS_HISTORICO, 1, 200);

                            --FIM HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO-----------------------------------

                            IF ITENSREGRA.NATUREZA = 'C'
                            THEN
                                IF VN_VALORLANCTO < 0
                                THEN
                                    VS_NATUREZA := 'D';
                                ELSE
                                    VS_NATUREZA := 'C';
                                END IF;
                            ELSE
                                IF VN_VALORLANCTO < 0
                                THEN
                                    VS_NATUREZA := 'C';
                                ELSE
                                    VS_NATUREZA := 'D';
                                END IF;
                            END IF;

                            IF VS_NATUREZA = 'C'
                            THEN
                                VN_TOTALCREDITO :=
                                    ROUND (
                                          VN_TOTALCREDITO
                                        + ABS (VN_VALORLANCTO),
                                        2);
                            ELSE
                                VN_TOTALDEBITO :=
                                    ROUND (
                                        VN_TOTALDEBITO + ABS (VN_VALORLANCTO),
                                        2);
                            END IF;

                            --GUARDA FILIAIS
                            FILIAIS.CODFILIAL := '-1';

                            FOR VN_POSICAO IN 1 .. FILIAIS_LANCADAS.COUNT
                            LOOP
                                IF (FILIAIS_LANCADAS (VN_POSICAO).CODFILIAL =
                                    VS_CODFILIAL)
                                THEN
                                    FILIAIS := FILIAIS_LANCADAS (VN_POSICAO);
                                    VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

                                    EXIT;
                                END IF;
                            END LOOP;

                            IF (FILIAIS.CODFILIAL = '-1')
                            THEN
                                FILIAIS_LANCADAS.EXTEND;

                                FILIAIS :=
                                    FILIAIS_LANCADAS (FILIAIS_LANCADAS.COUNT);
                                VN_POSICAO_EM_ALTERACAO :=
                                    FILIAIS_LANCADAS.COUNT;

                                FILIAIS.CODFILIAL := VS_CODFILIAL;
                                FILIAIS.CGCFILIAL :=
                                    F_CGCFILIAL (VS_CODFILIAL);

                                FILIAIS_LANCADAS (VN_POSICAO_EM_ALTERACAO) :=
                                    FILIAIS;
                            END IF;

                            --GUARDA AS CONTAS PARA VERIFICAR SE ESTÃO IGUAIS POSTERIORMENTE
                            P_ARMAZENA_CONTAS_FILIAIS_LANC (VS_CONTA,
                                                            VS_NATUREZA,
                                                            VS_CODFILIAL,
                                                            FILIAIS_LANCADAS);

                            IF 'N' = 'S'
                            THEN
                                NULL;
                            ELSE
                                ---------------------------------------------------------------------------------
                                V_SQLERRO :=
                                    '10 - ACERTO DE CARGAS: EXECUTANDO PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA()';

                                ---------------------------------------------------------------------------------

                                -- Se tem desconto e se o campo VALORDESCONTO consta na formula
                                IF     (NOT VB_ECONTA_PREDEFINIDA)
                                   AND F_USA_CENTRO_CUSTO (VS_CONTA,
                                                           PCODPLANOCONTA)
                                   AND (ITEM.VALORDESCONTO > 0)
                                   AND (TRIM (ITENSREGRA.FORMULAS) =
                                        'VALORDESCONTO')
                                THEN
                                    BEGIN
                                        SELECT RECNUM
                                          INTO VS_RECNUM_CENTROCUSTO
                                          FROM PCLANC
                                         WHERE     PCLANC.DUPLIC =
                                                   ITEM.PRESTACAO
                                               AND PCLANC.LOCALIZACAO =
                                                   TO_CHAR (
                                                       ITEM.NUMTRANSVENDA)
                                               AND PCLANC.NUMNOTA =
                                                   ITEM.DUPLICATA
                                               AND PCLANC.VALOR > 0;
                                    EXCEPTION
                                        WHEN NO_DATA_FOUND
                                        THEN
                                            VS_RECNUM_CENTROCUSTO := NULL;
                                    END;

                                    --INSERE CENTRO DE CUSTO
                                    IF VS_RECNUM_CENTROCUSTO IS NOT NULL
                                    THEN
                                        VS_NUMTRANSCENTROCUSTO :=
                                            F_RETORNA_NUMTRANS_CENTROCUSTO ();
                                    END IF;
                                END IF;

                                IF     (NOT VB_ECONTA_PREDEFINIDA)
                                   AND F_USA_CENTRO_CUSTO (VS_CONTA,
                                                           PCODPLANOCONTA)
                                   AND (ITEM.VALORDESPCARTORAIS > 0)
                                   AND (TRIM (ITENSREGRA.FORMULAS) =
                                        'VALORDESPCARTORAIS')
                                THEN
                                    BEGIN
                                        SELECT RECNUM
                                          INTO VS_RECNUM_CENTROCUSTO
                                          FROM PCLANC
                                         WHERE     PCLANC.DUPLIC =
                                                   SUBSTR (ITEM.PRESTACAO,
                                                           1,
                                                           1)
                                               AND PCLANC.LOCALIZACAO =
                                                   TO_CHAR (
                                                       ITEM.NUMTRANSVENDA)
                                               AND PCLANC.NUMNOTA =
                                                   ITEM.DUPLICATA
                                               AND PCLANC.NUMTRANS =
                                                   ITEM.NUMTRANSOPERACAO
                                               AND PCLANC.HISTORICO LIKE
                                                          '%'
                                                       || ITEM.NUMTRANSVENDA
                                                       || '-'
                                                       || ITEM.PRESTACAO
                                               AND EXISTS
                                                       (SELECT 1
                                                          FROM PCPARAMFILIAL
                                                               F
                                                         WHERE     F.NOME =
                                                                   'CODCONTDESPCARTORIO'
                                                               AND F.VALOR =
                                                                   PCLANC.CODCONTA)
                                               AND ROWNUM = 1;
                                    EXCEPTION
                                        WHEN NO_DATA_FOUND
                                        THEN
                                            VS_RECNUM_CENTROCUSTO := NULL;
                                    END;

                                    --INSERE CENTRO DE CUSTO
                                    IF VS_RECNUM_CENTROCUSTO IS NOT NULL
                                    THEN
                                        VS_NUMTRANSCENTROCUSTO :=
                                            F_RETORNA_NUMTRANS_CENTROCUSTO ();
                                    END IF;
                                END IF;

                                IF     (NOT VB_ECONTA_PREDEFINIDA)
                                   AND F_USA_CENTRO_CUSTO (VS_CONTA,
                                                           PCODPLANOCONTA)
                                   AND (ITEM.VALORDESPBANCARIAS > 0)
                                   AND (TRIM (ITENSREGRA.FORMULAS) =
                                        'VALORDESPBANCARIAS')
                                THEN
                                    BEGIN
                                        SELECT RECNUM
                                          INTO VS_RECNUM_CENTROCUSTO
                                          FROM PCLANC, PCCONSUM
                                         WHERE     PCLANC.DUPLIC =
                                                   SUBSTR (ITEM.PRESTACAO,
                                                           1,
                                                           1)
                                               AND PCLANC.LOCALIZACAO =
                                                   TO_CHAR (
                                                       ITEM.NUMTRANSVENDA)
                                               AND PCLANC.NUMNOTA =
                                                   ITEM.DUPLICATA
                                               AND PCLANC.NUMTRANS =
                                                   ITEM.NUMTRANSOPERACAO
                                               AND PCLANC.HISTORICO LIKE
                                                          '%'
                                                       || ITEM.NUMTRANSVENDA
                                                       || '-'
                                                       || ITEM.PRESTACAO
                                               AND EXISTS
                                                       (SELECT 1
                                                          FROM PCPARAMFILIAL
                                                               F
                                                         WHERE     F.NOME =
                                                                   'CODCONTDESPBANCARIAS'
                                                               AND F.VALOR =
                                                                   PCLANC.CODCONTA)
                                               AND ROWNUM = 1;
                                    EXCEPTION
                                        WHEN NO_DATA_FOUND
                                        THEN
                                            VS_RECNUM_CENTROCUSTO := NULL;
                                    END;

                                    --INSERE CENTRO DE CUSTO
                                    IF VS_RECNUM_CENTROCUSTO IS NOT NULL
                                    THEN
                                        VS_NUMTRANSCENTROCUSTO :=
                                            F_RETORNA_NUMTRANS_CENTROCUSTO ();
                                    END IF;
                                END IF;

                                IF     (NOT VB_ECONTA_PREDEFINIDA)
                                   AND F_USA_CENTRO_CUSTO (VS_CONTA,
                                                           PCODPLANOCONTA)
                                   AND (ITEM.VALOROUTROSACRESC > 0)
                                   AND (TRIM (ITENSREGRA.FORMULAS) =
                                        'VALOROUTROSACRESC')
                                THEN
                                    BEGIN
                                        SELECT RECNUM
                                          INTO VS_RECNUM_CENTROCUSTO
                                          FROM PCLANC, PCCONSUM
                                         WHERE     PCLANC.DUPLIC =
                                                   SUBSTR (ITEM.PRESTACAO,
                                                           1,
                                                           1)
                                               AND PCLANC.LOCALIZACAO =
                                                   TO_CHAR (
                                                       ITEM.NUMTRANSVENDA)
                                               AND PCLANC.NUMNOTA =
                                                   ITEM.DUPLICATA
                                               AND PCLANC.NUMTRANS =
                                                   ITEM.NUMTRANSOPERACAO
                                               AND PCLANC.HISTORICO LIKE
                                                          '%'
                                                       || ITEM.NUMTRANSVENDA
                                                       || '-'
                                                       || ITEM.PRESTACAO
                                               AND EXISTS
                                                       (SELECT 1
                                                          FROM PCPARAMFILIAL
                                                               F
                                                         WHERE     F.NOME =
                                                                   'CODCONTOUTROSACRESCIMOSCR'
                                                               AND F.VALOR =
                                                                   PCLANC.CODCONTA)
                                               AND ROWNUM = 1;
                                    EXCEPTION
                                        WHEN NO_DATA_FOUND
                                        THEN
                                            VS_RECNUM_CENTROCUSTO := NULL;
                                    END;

                                    --INSERE CENTRO DE CUSTO
                                    IF VS_RECNUM_CENTROCUSTO IS NOT NULL
                                    THEN
                                        VS_NUMTRANSCENTROCUSTO :=
                                            F_RETORNA_NUMTRANS_CENTROCUSTO ();
                                    END IF;
                                END IF;

                                IF     (NOT VB_ECONTA_PREDEFINIDA)
                                   AND F_USA_CENTRO_CUSTO (VS_CONTA,
                                                           PCODPLANOCONTA)
                                   AND (ITEM.VALORMULTA > 0)
                                   AND (TRIM (ITENSREGRA.FORMULAS) =
                                        'VALORMULTA')
                                THEN
                                    BEGIN
                                        SELECT RECNUM
                                          INTO VS_RECNUM_CENTROCUSTO
                                          FROM PCLANC, PCCONSUM
                                         WHERE     PCLANC.DUPLIC =
                                                   SUBSTR (ITEM.PRESTACAO,
                                                           1,
                                                           1)
                                               AND PCLANC.LOCALIZACAO =
                                                   TO_CHAR (
                                                       ITEM.NUMTRANSVENDA)
                                               AND PCLANC.NUMNOTA =
                                                   ITEM.DUPLICATA
                                               AND PCLANC.NUMTRANS =
                                                   ITEM.NUMTRANSOPERACAO
                                               AND PCLANC.HISTORICO LIKE
                                                          '%'
                                                       || ITEM.NUMTRANSVENDA
                                                       || '-'
                                                       || ITEM.PRESTACAO
                                               AND EXISTS
                                                       (SELECT 1
                                                          FROM PCPARAMFILIAL
                                                               F
                                                         WHERE     F.NOME =
                                                                   'CON_CODCONTRECMULTA'
                                                               AND F.VALOR =
                                                                   PCLANC.CODCONTA)
                                               AND ROWNUM = 1;
                                    EXCEPTION
                                        WHEN NO_DATA_FOUND
                                        THEN
                                            VS_RECNUM_CENTROCUSTO := NULL;
                                    END;

                                    --INSERE CENTRO DE CUSTO
                                    IF VS_RECNUM_CENTROCUSTO IS NOT NULL
                                    THEN
                                        VS_NUMTRANSCENTROCUSTO :=
                                            F_RETORNA_NUMTRANS_CENTROCUSTO ();
                                    END IF;
                                END IF;

                                IF     (NOT VB_ECONTA_PREDEFINIDA)
                                   AND F_USA_CENTRO_CUSTO (VS_CONTA,
                                                           PCODPLANOCONTA)
                                   AND (ITEM.VALORJUROS > 0)
                                   AND (TRIM (ITENSREGRA.FORMULAS) =
                                        'VALORJUROS')
                                THEN
                                    BEGIN
                                        SELECT RECNUM
                                          INTO VS_RECNUM_CENTROCUSTO
                                          FROM PCLANC, PCCONSUM
                                         WHERE     PCLANC.DUPLIC =
                                                   SUBSTR (ITEM.PRESTACAO,
                                                           1,
                                                           1)
                                               AND PCLANC.LOCALIZACAO =
                                                   TO_CHAR (
                                                       ITEM.NUMTRANSVENDA)
                                               AND PCLANC.NUMNOTA =
                                                   ITEM.DUPLICATA
                                               AND PCLANC.NUMTRANS =
                                                   ITEM.NUMTRANSOPERACAO
                                               AND PCLANC.HISTORICO LIKE
                                                          '%'
                                                       || ITEM.NUMTRANSVENDA
                                                       || '-'
                                                       || ITEM.PRESTACAO
                                               AND (   (PCLANC.CODCONTA =
                                                        PCCONSUM.CODCONTRECJUR)
                                                    OR (EXISTS
                                                            (SELECT 1
                                                               FROM PCCOB C
                                                              WHERE     C.CARTAO =
                                                                        'S'
                                                                    AND C.CODCONTACC =
                                                                        PCLANC.CODCONTA)))
                                               AND ROWNUM = 1;
                                    EXCEPTION
                                        WHEN NO_DATA_FOUND
                                        THEN
                                            VS_RECNUM_CENTROCUSTO := NULL;
                                    END;

                                    --INSERE CENTRO DE CUSTO
                                    IF VS_RECNUM_CENTROCUSTO IS NOT NULL
                                    THEN
                                        VS_NUMTRANSCENTROCUSTO :=
                                            F_RETORNA_NUMTRANS_CENTROCUSTO ();
                                    END IF;
                                END IF;

                                ---------------------------------------------------------------------------------
                                V_SQLERRO :=
                                    '10 - ACERTO DE CARGAS: EXECUTANDO PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA()';
                                ---------------------------------------------------------------------------------
                                --INSERE DADOS NA TABELA QUANDO NÃO ESTÁ TOTALIZANDO VALORES
                                VN_NUMSEQ := VN_NUMSEQ + 1;

                                P_GRAVA_DADOS_TABINTERMEDIARIA (
                                    VS_CODFILIAL,
                                    VN_NUMTRANSACAO,
                                    VN_NUMSEQ,
                                    VD_DATALANCTO,
                                    VS_DOCUMENTO,
                                    ITENSREGRA.CODHISTORICO,
                                    VS_HISTORICO,
                                    PCODPLANOCONTA,
                                    VS_CONTA,
                                    VS_NATUREZA,
                                    ABS (VN_VALORLANCTO),
                                    PCODREGRA,
                                    '',
                                    ITEM.NUMTRANSOPERACAO,
                                    F_RETORNA_TIPO_INCONSISTENCIA (
                                        VS_TEMCONTAINEXISTENTE),
                                    'P',
                                    VD_DATAINTEGRACAO,
                                    0,
                                    0,
                                    '',
                                    VS_NUMTRANSCENTROCUSTO,
                                    TRUNC (SYSDATE),
                                    ITEM.CODCLI,
                                    'C',
                                    NULL,
                                    ITEM.NUMTRANSVENDA,
                                    ITEM.PRESTACAO,
                                    ITENSREGRA.FORMULAS,
                                    ITENSREGRA.CODREDUZIDO_PC,
                                    'RECEBIMENTO',
                                    'PCPREST',
                                    ITENSREGRA.TOTALIZAVALOR);


                                IF VS_RECNUM_CENTROCUSTO IS NOT NULL
                                THEN
                                    P_GRAVA_PCINTER_CENTROCUSTO (
                                        VS_RECNUM_CENTROCUSTO,
                                        VS_NUMTRANSCENTROCUSTO,
                                        PCODREGRA,
                                        (CASE
                                             WHEN VS_BUSCARDADOSPELADATA =
                                                  'C'
                                             THEN
                                                 NVL (ITEM.DATAOPERACAO1,
                                                      ITEM.DATAOPERACAO)
                                             ELSE
                                                 ITEM.DATAOPERACAO
                                         END),
                                        FALSE,
                                        0,
                                        VN_NUMTRANSACAO,
                                           VS_HISTORICO
                                        || vs_conta
                                        || VS_CODFILIAL,
                                        0);
                                END IF;

                                VS_NUMTRANSCENTROCUSTO := NULL;
                            END IF;
                        END IF;
                    END IF;

                   <<pula_registro>>
                    NULL;
                END LOOP;

                --GUARDA O NÚMERO DA TRANSAÇÃO
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            ELSE
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            END IF;
        END LOOP;

        --VERIFICA CONSISTÊNCIAS DO ÚLTIMO REGISTRO
        IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '10 - ACERTO DE CARGAS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
            ---------------------------------------------------------------------------------
            P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                        VD_DATALANCTO,
                                        VS_TEMCONTAINEXISTENTE,
                                        VN_TOTALDEBITO,
                                        VN_TOTALCREDITO,
                                        ITEM.ERRO_MULTIFILIAL);
        END IF;

        CLOSE CURSOR_DADOS;

        RESULTADO := 'OK';
    EXCEPTION
        WHEN OTHERS
        THEN
            RESULTADO :=
                   'Ocorreu um erro quando: '
                || V_SQLERRO
                || CHR (13)
                || 'Erro Original: '
                || SQLERRM;
    END;

    /****************************************************************************
      PROCEDURE PARA GERAÇÃO DE 11 - CUPONS FISCAIS
    *****************************************************************************/
    PROCEDURE P_DADOS_CUPONS (CURSOR_DADOS     IN     SYS_REFCURSOR,
                              PCODREGRA        IN     NUMBER,
                              PCODPLANOCONTA   IN     NUMBER,
                              RESULTADO           OUT VARCHAR2)
    IS
        TYPE CONSULTA_SAIDAS IS RECORD
        (
            CODFILIAL PCNFSAID.CODFILIALNF%TYPE,
            DATAOPERACAO PCNFSAID.DTSAIDA%TYPE,
            DATAOPERACAO1 PCNFSAID.DTSAIDA%TYPE,
            DATAOPERACAO2 PCPREST.DTDESD%TYPE,
            NUMNOTANF PCNFSAID.NUMNOTA%TYPE,
            VALORICMS PCNFSAID.VLICMS%TYPE,
            VALORISENTAS PCNFSAID.VLISENTAS%TYPE,
            VALOROUTRAS PCNFSAID.VLOUTRAS%TYPE,
            VALORFRETE PCNFSAID.VLFRETE%TYPE,
            VALORST PCNFSAID.ICMSRETIDO%TYPE,
            VALORIPI PCNFSAID.VLIPI%TYPE,
            VALORPIS PCNFSAID.VLPIS%TYPE,
            VALORCOFINS PCNFSAID.VLCOFINS%TYPE,
            VALORTITULO PCPREST.VALOR%TYPE,
            VALORDESCONTO PCPREST.VALORDESC%TYPE,
            CODCOBRANCANF PCNFSAID.CODCOB%TYPE,
            TIPODEVENDANF PCNFSAID.CONDVENDA%TYPE,
            ESPECIENF PCNFSAID.ESPECIE%TYPE,
            TIPOOPERACAO PCNFSAID.TIPOVENDA%TYPE,
            DUPLICATA PCPREST.DUPLIC%TYPE,
            PRESTACAO PCPREST.PREST%TYPE,
            CODCLIENTETITULO PCPREST.CODCLI%TYPE,
            CODCOBRANCATITULO PCPREST.CODCOB%TYPE,
            CODCOBRANCAORIGTITULO PCPREST.CODCOB%TYPE,
            STATUSTITULO PCPREST.STATUS%TYPE,
            VENDAASSISTIDA PCNFSAID.VENDAASSISTIDA%TYPE,
            CLIENTENF PCCLIENT.CLIENTE%TYPE,
            CODCLIENTENF PCNFSAID.CODCLI%TYPE,
            SERIENF PCNFSAID.SERIE%TYPE,
            UFNF PCNFSAID.UF%TYPE,
            NUMTRANSOPERACAO PCNFSAID.NUMTRANSVENDA%TYPE,
            TIPOFRETE PCNFSAID.TIPOFRETE%TYPE,
            CODCONTAGERENCIAL PCNFSAID.CODCONT%TYPE,
            CODCONTACLIENTENF PCCLIENT.CODCONTAB%TYPE,
            CONTACONTABIL PCCONTA.CONTACONTABIL%TYPE,
            CODCONTACLIENTETITULO PCCLIENT.CODCONTAB%TYPE,
            TEMINTEGRACAO VARCHAR2 (1)
        );

        ITEM                CONSULTA_SAIDAS;
        ITENSREGRA          CONSULTA_ITENS;

        CURSOR_ITENS        SYS_REFCURSOR;

        FILIAIS_LANCADAS    TABELAFILIAISLANCTO;
        FILIAIS             FILIAISLANCTO;
        VS_CONTA_EXISTE     VARCHAR2 (1);
        VD_DATALANCTO_AUX   DATE;
    BEGIN
        LISTA_FORMULAS := TYPE_LISTA_FORMULAS ();

        FILIAIS_LANCADAS := TABELAFILIAISLANCTO ();

        VS_SEQGERADO := 'N';
        VS_FORMADTCONTABILIZACAO := '';
        VN_NUMTRANSACAO := 0;
        VS_DOCUMENTO := '';
        VS_TEMCONTAINEXISTENTE := 'N';

        --BUSCA DADOS DA REGRA
        SELECT FORMADTCONTABILIZACAO, BUSCARDADOSPELADATA
          INTO VS_FORMADTCONTABILIZACAO, VS_BUSCARDADOSPELADATA
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        V_SQLERRO := 'ABRINDO SAIDAS';

        --INICIA LAÇO DOS DADOS
        LOOP
            FETCH CURSOR_DADOS INTO ITEM;

            EXIT WHEN CURSOR_DADOS%NOTFOUND;

            IF    (ITEM.TEMINTEGRACAO IS NULL)
               OR (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                   AND (ITEM.TEMINTEGRACAO = 'P'))
            THEN
                --PEGA DATA DE LANÇAMENTO DE ACORDO COM SELECIONADO NA REGRA
                VD_DATALANCTO_AUX :=
                    F_RETORNA_DATA_LANCPROVISOES (11,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO,
                                                  ITEM.DATAOPERACAO1,
                                                  ITEM.DATAOPERACAO2);

                --------------------------------------------------------------------
                --VERIFICA SE ALTEROU O NUMTRANSOPERACAO PARA FAZER GRAVAÇÃO E RE-INICIAR VARIÁVEIS
                IF (VN_NUMTRANSOPERACAO <> ITEM.NUMTRANSOPERACAO)
                THEN
                    VS_SEQGERADO := 'N';

                    IF (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                        AND (ITEM.TEMINTEGRACAO = 'P'))
                    THEN
                        P_EXCLUI_LANCINTERMEDIARIA_IND (
                            PCODREGRA,
                            ITEM.NUMTRANSOPERACAO,
                            VD_DATALANCTO_AUX);
                    END IF;

                    --VERIFICA SE JÁ PASSOU POR ALGUM REGISTRO PARA ATRIBUIR INCONSISTÊNCIAS
                    IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) >
                       0
                    THEN
                        ---------------------------------------------------------------------------------
                        V_SQLERRO :=
                            '11 - SAIDAS CUPONS FISCAIS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
                        ---------------------------------------------------------------------------------
                        P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                                    VD_DATALANCTO,
                                                    VS_TEMCONTAINEXISTENTE,
                                                    VN_TOTALDEBITO,
                                                    VN_TOTALCREDITO,
                                                    'N');
                    END IF;

                    VS_TEMCONTAINEXISTENTE := 'N';
                END IF;

                --------------------------------------------------------------------

                --GERA NOVO NUMTRANSLANCTO
                IF VS_SEQGERADO = 'N'
                THEN
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '11 - CUPONS FISCAIS: EXECUTANDO FUNÇÃO GERA_NUM_TRANS_LANCTO()';
                    ---------------------------------------------------------------------------------
                    VN_NUMTRANSACAO := F_GERA_NUM_TRANS_LANCTO ();

                    VN_NUMSEQ := 0;
                    VN_TOTALCREDITO := 0;
                    VN_TOTALDEBITO := 0;
                    VS_SEQGERADO := 'S';

                    CONTASDEBLANCTO := CONTAS_LANCADAS ();
                    CONTASCRELANCTO := CONTAS_LANCADAS ();
                    CGCSLANCTO := CGC_LANCADOS ();
                    VS_LISTAS_TRANSOTORIAS := CONTAS_LANCADAS ();

                    CONTASDEBLANCTO.EXTEND;
                    CONTASCRELANCTO.EXTEND;
                END IF;

                --PEGA DATA DE LANÇAMENTO DE ACORDO COM SELECIONADO NA REGRA
                VD_DATALANCTO :=
                    F_RETORNA_DATA_LANCPROVISOES (11,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO,
                                                  ITEM.DATAOPERACAO1,
                                                  ITEM.DATAOPERACAO2);

                VD_DATAINTEGRACAO :=
                    F_RETORNA_DATA_LANCPROVISOES (11,
                                                  PCODREGRA,
                                                  DATA_INTEGRACAO,
                                                  ITEM.DATAOPERACAO,
                                                  ITEM.DATAOPERACAO1,
                                                  ITEM.DATAOPERACAO2);

                --LAÇO NOS ITENS DA REGRA CONTABIL
                OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL ()
                    USING PCODREGRA;

                LOOP
                    FETCH CURSOR_ITENS INTO ITENSREGRA;

                    EXIT WHEN CURSOR_ITENS%NOTFOUND;

                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '11 - CUPONS FISCAIS: ATRIBUINDO VALOR DO DOCUMENTO';
                    ---------------------------------------------------------------------------------
                    VS_DOCUMENTO := ITENSREGRA.DOCUMENTO;
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO2',
                                 TO_CHAR (ITEM.DATAOPERACAO2, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO1',
                                 TO_CHAR (ITEM.DATAOPERACAO1, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO',
                                 TO_CHAR (ITEM.DATAOPERACAO, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMNOTANF', ITEM.NUMNOTANF);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'DUPLICATA', ITEM.DUPLICATA);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMTRANSOPERACAO',
                                 ITEM.NUMTRANSOPERACAO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'CODCONTAGERENCIAL',
                                 ITEM.CODCONTAGERENCIAL);

                    --FORMULA INFORMADA NO FILTRO--------------------------------------------------------
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '11 - CUPONS FISCAIS: ATRIBUINDO VALOR DA FÓRMULA';
                    ---------------------------------------------------------------------------------
                    VN_VALORLANCTO := 0;

                    VS_FORMULA := ITENSREGRA.FORMULAS || ' + 0 ';
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORICMS([^_[:alnum:]])',
                                        NVL (ITEM.VALORICMS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORISENTAS([^_[:alnum:]])',
                                        NVL (ITEM.VALORISENTAS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALOROUTRAS([^_[:alnum:]])',
                                        NVL (ITEM.VALOROUTRAS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORFRETE([^_[:alnum:]])',
                                        NVL (ITEM.VALORFRETE, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORIPI([^_[:alnum:]])',
                                        NVL (ITEM.VALORIPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORST([^_[:alnum:]])',
                                        NVL (ITEM.VALORST, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORTITULO([^_[:alnum:]])',
                                        NVL (ITEM.VALORTITULO, 0) || '\1');

                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORDESCONTO([^_[:alnum:]])',
                                        NVL (ITEM.VALORDESCONTO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORPIS([^_[:alnum:]])',
                                        NVL (ITEM.VALORPIS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORCOFINS([^_[:alnum:]])',
                                        NVL (ITEM.VALORCOFINS, 0) || '\1');

                    CALCULAREXPRESSAO;

                    --FIM DA FÓRMULA---------------------------------------------------------------------

                    IF VN_VALORLANCTO > 0
                    THEN
                        VS_CONTA := TRIM (ITENSREGRA.CODREDUZIDO_PC);
                        VS_CODFILIAL :=
                            CASE
                                WHEN ITENSREGRA.CODFILIAL =
                                     'FILIALLANCAMENTO'
                                THEN
                                    ITEM.CODFILIAL
                                ELSE
                                    ITENSREGRA.CODFILIAL
                            END;

                        IF     (SUBSTR (VS_CONTA, 1, 1) <> '0')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '1')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '2')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '3')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '4')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '5')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '6')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '7')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '8')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '9')
                        THEN
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTACLIENTENF',
                                         ITEM.CODCONTACLIENTENF);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CONTACONTABIL',
                                         ITEM.CONTACONTABIL);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTACLIENTETITULO',
                                         ITEM.CODCONTACLIENTETITULO);
                        END IF;

                        VS_CONTA_EXISTE :=
                            F_VERIFICA_CONTA_EXISTE (VS_CONTA,
                                                     PCODPLANOCONTA);
                        TRATAR_CONTA_INEXISTENTE (VS_CONTA_EXISTE,
                                                  VS_TEMCONTAINEXISTENTE);

                        IF VS_CONTA_EXISTE IN ('S', 'I', 'X')
                        THEN
                            --HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO---------------------------------------
                            ---------------------------------------------------------------------------------
                            V_SQLERRO :=
                                '11 - CUPONS FISCAIS: ATRIBUINDO VALOR DE HISTÓRICOS';
                            ---------------------------------------------------------------------------------
                            VS_HISTORICO := ITENSREGRA.HISTCOMPLREGRA;
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO2]',
                                         ITEM.DATAOPERACAO2);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO1]',
                                         ITEM.DATAOPERACAO1);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO]',
                                         ITEM.DATAOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMNOTANF]',
                                         ITEM.NUMNOTANF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[ESPECIENF]',
                                         ITEM.ESPECIENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DUPLICATA]',
                                         ITEM.DUPLICATA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[PRESTACAO]',
                                         ITEM.PRESTACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODCLIENTETITULO]',
                                         ITEM.CODCLIENTETITULO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODCOBRANCATITULO]',
                                         ITEM.CODCOBRANCATITULO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODCOBRANCAORIGTITULO]',
                                         ITEM.CODCOBRANCAORIGTITULO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CLIENTENF]',
                                         ITEM.CLIENTENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODCLIENTENF]',
                                         ITEM.CODCLIENTENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[SERIENF]',
                                         ITEM.SERIENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO, '[UFNF]', ITEM.UFNF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMTRANSOPERACAO]',
                                         ITEM.NUMTRANSOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODCONTAGERENCIAL]',
                                         ITEM.CODCONTAGERENCIAL);
                            VS_HISTORICO := SUBSTR (VS_HISTORICO, 1, 200);

                            --FIM HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO-----------------------------------

                            IF ITENSREGRA.NATUREZA = 'C'
                            THEN
                                VN_TOTALCREDITO :=
                                    ROUND (
                                          VN_TOTALCREDITO
                                        + ABS (VN_VALORLANCTO),
                                        2);
                                VS_NATUREZA := 'C';
                            ELSE
                                VN_TOTALDEBITO :=
                                    ROUND (
                                        VN_TOTALDEBITO + ABS (VN_VALORLANCTO),
                                        2);
                                VS_NATUREZA := 'D';
                            END IF;

                            --GUARDA FILIAIS
                            FILIAIS.CODFILIAL := '-1';

                            FOR VN_POSICAO IN 1 .. FILIAIS_LANCADAS.COUNT
                            LOOP
                                IF (FILIAIS_LANCADAS (VN_POSICAO).CODFILIAL =
                                    VS_CODFILIAL)
                                THEN
                                    FILIAIS := FILIAIS_LANCADAS (VN_POSICAO);
                                    VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

                                    EXIT;
                                END IF;
                            END LOOP;

                            IF (FILIAIS.CODFILIAL = '-1')
                            THEN
                                FILIAIS_LANCADAS.EXTEND;

                                FILIAIS :=
                                    FILIAIS_LANCADAS (FILIAIS_LANCADAS.COUNT);
                                VN_POSICAO_EM_ALTERACAO :=
                                    FILIAIS_LANCADAS.COUNT;

                                FILIAIS.CODFILIAL := VS_CODFILIAL;
                                FILIAIS.CGCFILIAL :=
                                    F_CGCFILIAL (VS_CODFILIAL);

                                FILIAIS_LANCADAS (VN_POSICAO_EM_ALTERACAO) :=
                                    FILIAIS;
                            END IF;

                            --GUARDA AS CONTAS PARA VERIFICAR SE ESTÃO IGUAIS POSTERIORMENTE
                            P_ARMAZENA_CONTAS_FILIAIS_LANC (VS_CONTA,
                                                            VS_NATUREZA,
                                                            VS_CODFILIAL,
                                                            FILIAIS_LANCADAS);

                            IF 'N' = 'S'
                            THEN
                                NULL;
                            ELSE
                                ---------------------------------------------------------------------------------
                                V_SQLERRO :=
                                    '11 - CUPONS FISCAIS: EXECUTANDO PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA()';
                                ---------------------------------------------------------------------------------
                                --INSERE DADOS NA TABELA QUANDO NÃO ESTÁ TOTALIZANDO VALORES
                                VN_NUMSEQ := VN_NUMSEQ + 1;

                                P_GRAVA_DADOS_TABINTERMEDIARIA (
                                    VS_CODFILIAL,
                                    VN_NUMTRANSACAO,
                                    VN_NUMSEQ,
                                    VD_DATALANCTO,
                                    VS_DOCUMENTO,
                                    ITENSREGRA.CODHISTORICO,
                                    VS_HISTORICO,
                                    PCODPLANOCONTA,
                                    VS_CONTA,
                                    VS_NATUREZA,
                                    VN_VALORLANCTO,
                                    PCODREGRA,
                                    '',
                                    ITEM.NUMTRANSOPERACAO,
                                    F_RETORNA_TIPO_INCONSISTENCIA (
                                        VS_TEMCONTAINEXISTENTE),
                                    'P',
                                    VD_DATAINTEGRACAO,
                                    0,
                                    0,
                                    '',
                                    '',
                                    TRUNC (SYSDATE),
                                    ITEM.CODCLIENTETITULO,
                                    'C',
                                    NULL,
                                    ITEM.NUMTRANSOPERACAO,
                                    ITEM.PRESTACAO,
                                    ITENSREGRA.FORMULAS,
                                    ITENSREGRA.CODREDUZIDO_PC,
                                    'CUPOM',
                                    'PCPREST',
                                    ITENSREGRA.TOTALIZAVALOR);
                            END IF;
                        END IF;
                    END IF;
                END LOOP;

                --GUARDA O NÚMERO DA TRANSAÇÃO
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            ELSE
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            END IF;
        END LOOP;

        --VERIFICA CONSISTÊNCIAS DO ÚLTIMO REGISTRO
        IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '11 - CUPONS FISCAIS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
            ---------------------------------------------------------------------------------
            P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                        VD_DATALANCTO,
                                        VS_TEMCONTAINEXISTENTE,
                                        VN_TOTALDEBITO,
                                        VN_TOTALCREDITO,
                                        'N');
        END IF;

        CLOSE CURSOR_DADOS;

        RESULTADO := 'OK';
    EXCEPTION
        WHEN OTHERS
        THEN
            RESULTADO :=
                   'Ocorreu um erro quando: '
                || V_SQLERRO
                || CHR (13)
                || 'Erro Original: '
                || SQLERRM;
    END;

    /****************************************************************************
        PROCEDURE PARA GERAÇÃO DE 12 - NOTAS FISCAIS DE SERVICO
      *****************************************************************************/
    PROCEDURE P_DADOS_NFSERVICO (CURSOR_DADOS     IN     SYS_REFCURSOR,
                                 PCODREGRA        IN     NUMBER,
                                 PCODPLANOCONTA   IN     NUMBER,
                                 RESULTADO           OUT VARCHAR2)
    IS
        TYPE CONSULTA_NFSERVICO IS RECORD
        (
            CODFILIAL PCNFSAID.CODFILIALNF%TYPE,
            DATAOPERACAO PCNFSAID.DTSAIDA%TYPE,
            NUMNOTANF PCNFSAID.NUMNOTA%TYPE,
            VALORTOTAL PCNFSAID.VLTOTAL%TYPE,
            VALORDESCONTO PCNFSAID.VLDESCONTO%TYPE,
            VALORISS PCNFSAID.VLISS%TYPE,
            ISSRETIDO PCMOV.ISSRETIDO%TYPE,
            VALORIR PCNFSAID.VLIR%TYPE,
            VALORPIS PCNFSAID.VLPIS%TYPE,
            VALORINSS PCNFSAID.VLINSS%TYPE,
            CODCOBRANCA PCNFSAID.CODCOB%TYPE,
            TIPODEVENDANF PCNFSAID.CONDVENDA%TYPE,
            ESPECIENF PCNFSAID.ESPECIE%TYPE,
            TIPOOPERACAO PCNFSAID.TIPOVENDA%TYPE,
            CLIENTENF PCCLIENT.CLIENTE%TYPE,
            CODCLIENTENF PCNFSAID.CODCLI%TYPE,
            SERIENF PCNFSAID.SERIE%TYPE,
            UFNF PCNFSAID.UF%TYPE,
            NUMTRANSOPERACAO PCNFSAID.NUMTRANSVENDA%TYPE,
            TIPOFRETE PCNFSAID.TIPOFRETE%TYPE,
            CODCONTAGERENCIAL PCNFSAID.CODCONT%TYPE,
            CODCONTACLIENTE PCCLIENT.CODCONTAB%TYPE,
            CONTACONTABIL PCCONTA.CONTACONTABIL%TYPE,
            CODREMETENTEFRETE PCNFSAID.CODREMETENTEFRETE%TYPE,
            VALORCSLLRETIDO PCMOVCOMPLE.VLCSLLRETIDO%TYPE,
            VALORCOFINSRETIDO PCMOVCOMPLE.VLCOFINSRETIDO%TYPE,
            VALORCSLL PCNFSAID.VLCSLL%TYPE,
            VALORCOFINS PCNFSAID.VLCOFINS%TYPE,
            VALORPISRETIDO PCMOVCOMPLE.VLPISRETIDO%TYPE,
            TEMINTEGRACAO VARCHAR2 (1)
        );

        ITEM               CONSULTA_NFSERVICO;
        ITENSREGRA         CONSULTA_ITENS;

        CURSOR_ITENS       SYS_REFCURSOR;

        FILIAIS_LANCADAS   TABELAFILIAISLANCTO;
        FILIAIS            FILIAISLANCTO;

        VS_CONTA_EXISTE    VARCHAR2 (1);
    BEGIN
        LISTA_FORMULAS := TYPE_LISTA_FORMULAS ();

        FILIAIS_LANCADAS := TABELAFILIAISLANCTO ();

        VS_SEQGERADO := 'N';
        VS_FORMADTCONTABILIZACAO := '';
        VN_NUMTRANSACAO := 0;
        VS_DOCUMENTO := '';
        VS_TEMCONTAINEXISTENTE := 'N';

        --BUSCA DADOS DA REGRA
        SELECT FORMADTCONTABILIZACAO
          INTO VS_FORMADTCONTABILIZACAO
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        V_SQLERRO := 'ABRINDO NF SERVICO';

        --INICIA LAÇO DOS DADOS
        LOOP
            FETCH CURSOR_DADOS INTO ITEM;

            EXIT WHEN CURSOR_DADOS%NOTFOUND;

            IF    (ITEM.TEMINTEGRACAO IS NULL)
               OR (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                   AND (ITEM.TEMINTEGRACAO = 'P'))
            THEN
                --------------------------------------------------------------------
                --VERIFICA SE ALTEROU O NUMTRANSOPERACAO PARA FAZER GRAVAÇÃO E RE-INICIAR VARIÁVEIS
                IF (VN_NUMTRANSOPERACAO <> ITEM.NUMTRANSOPERACAO)
                THEN
                    VS_SEQGERADO := 'N';

                    IF (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                        AND (ITEM.TEMINTEGRACAO = 'P'))
                    THEN
                        P_EXCLUI_LANCINTERMEDIARIA_IND (
                            PCODREGRA,
                            ITEM.NUMTRANSOPERACAO,
                            ITEM.DATAOPERACAO);
                    END IF;

                    --VERIFICA SE JÁ PASSOU POR ALGUM REGISTRO PARA ATRIBUIR INCONSISTÊNCIAS
                    IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) >
                       0
                    THEN
                        ---------------------------------------------------------------------------------
                        V_SQLERRO :=
                            '12 - NF SERVICO: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
                        ---------------------------------------------------------------------------------
                        P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                                    VD_DATALANCTO,
                                                    VS_TEMCONTAINEXISTENTE,
                                                    VN_TOTALDEBITO,
                                                    VN_TOTALCREDITO,
                                                    'N');
                    END IF;

                    VS_TEMCONTAINEXISTENTE := 'N';
                END IF;

                --------------------------------------------------------------------

                --GERA NOVO NUMTRANSLANCTO
                IF VS_SEQGERADO = 'N'
                THEN
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '12 - NF SERVICO: EXECUTANDO FUNÇÃO GERA_NUM_TRANS_LANCTO()';
                    ---------------------------------------------------------------------------------
                    VN_NUMTRANSACAO := F_GERA_NUM_TRANS_LANCTO ();

                    VN_NUMSEQ := 0;
                    VN_TOTALCREDITO := 0;
                    VN_TOTALDEBITO := 0;
                    VS_SEQGERADO := 'S';

                    CONTASDEBLANCTO := CONTAS_LANCADAS ();
                    CONTASCRELANCTO := CONTAS_LANCADAS ();
                    CGCSLANCTO := CGC_LANCADOS ();
                    VS_LISTAS_TRANSOTORIAS := CONTAS_LANCADAS ();

                    CONTASDEBLANCTO.EXTEND;
                    CONTASCRELANCTO.EXTEND;
                END IF;

                VD_DATALANCTO :=
                    F_RETORNA_DATA_LANCPROVISOES (12,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO);

                VD_DATAINTEGRACAO :=
                    F_RETORNA_DATA_LANCPROVISOES (12,
                                                  PCODREGRA,
                                                  DATA_INTEGRACAO,
                                                  ITEM.DATAOPERACAO);

                --LAÇO NOS ITENS DA REGRA CONTABIL
                OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL ()
                    USING PCODREGRA;

                LOOP
                    FETCH CURSOR_ITENS INTO ITENSREGRA;

                    EXIT WHEN CURSOR_ITENS%NOTFOUND;

                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '12 - NF SERVICO: ATRIBUINDO VALOR DO DOCUMENTO';
                    ---------------------------------------------------------------------------------
                    VS_DOCUMENTO := ITENSREGRA.DOCUMENTO;
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMNOTANF', ITEM.NUMNOTANF);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMTRANSOPERACAO',
                                 ITEM.NUMTRANSOPERACAO);

                    --FORMULA INFORMADA NO FILTRO--------------------------------------------------------
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '12 - NF SERVICO: ATRIBUINDO VALOR DA FÓRMULA';
                    ---------------------------------------------------------------------------------
                    VN_VALORLANCTO := 0;

                    VS_FORMULA := ITENSREGRA.FORMULAS || ' + 0 ';
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORTOTAL([^_[:alnum:]])',
                                        NVL (ITEM.VALORTOTAL, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORDESCONTO([^_[:alnum:]])',
                                        NVL (ITEM.VALORDESCONTO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORISS([^_[:alnum:]])',
                                        NVL (ITEM.VALORISS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORIR([^_[:alnum:]])',
                                        NVL (ITEM.VALORIR, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORPIS([^_[:alnum:]])',
                                        NVL (ITEM.VALORPIS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORINSS([^_[:alnum:]])',
                                        NVL (ITEM.VALORINSS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORCSLLRETIDO([^_[:alnum:]])',
                            NVL (ITEM.VALORCSLLRETIDO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORCOFINSRETIDO([^_[:alnum:]])',
                            NVL (ITEM.VALORCOFINSRETIDO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORCSLL([^_[:alnum:]])',
                                        NVL (ITEM.VALORCSLL, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORCOFINS([^_[:alnum:]])',
                                        NVL (ITEM.VALORCOFINS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORPISRETIDO([^_[:alnum:]])',
                                        NVL (ITEM.VALORPISRETIDO, 0) || '\1');

                    CALCULAREXPRESSAO;

                    --FIM DA FÓRMULA---------------------------------------------------------------------

                    IF VN_VALORLANCTO > 0
                    THEN
                        VS_CONTA := TRIM (ITENSREGRA.CODREDUZIDO_PC);
                        VS_CODFILIAL :=
                            CASE
                                WHEN ITENSREGRA.CODFILIAL =
                                     'FILIALLANCAMENTO'
                                THEN
                                    ITEM.CODFILIAL
                                ELSE
                                    ITENSREGRA.CODFILIAL
                            END;


                        IF     (SUBSTR (VS_CONTA, 1, 1) <> '0')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '1')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '2')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '3')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '4')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '5')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '6')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '7')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '8')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '9')
                        THEN
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTACLIENTE',
                                         ITEM.CODCONTACLIENTE);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CONTACONTABIL',
                                         ITEM.CONTACONTABIL);
                        END IF;


                        VS_CONTA_EXISTE :=
                            F_VERIFICA_CONTA_EXISTE (VS_CONTA,
                                                     PCODPLANOCONTA);
                        TRATAR_CONTA_INEXISTENTE (VS_CONTA_EXISTE,
                                                  VS_TEMCONTAINEXISTENTE);

                        IF VS_CONTA_EXISTE IN ('S', 'I', 'X')
                        THEN
                            --HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO---------------------------------------
                            ---------------------------------------------------------------------------------
                            V_SQLERRO :=
                                '12 - NF SERVICO: ATRIBUINDO VALOR DE HISTÓRICOS';
                            ---------------------------------------------------------------------------------
                            VS_HISTORICO := ITENSREGRA.HISTCOMPLREGRA;
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO]',
                                         ITEM.DATAOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMNOTANF]',
                                         ITEM.NUMNOTANF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CLIENTENF]',
                                         ITEM.CLIENTENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODCLIENTENF]',
                                         ITEM.CODCLIENTENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[SERIENF]',
                                         ITEM.SERIENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMTRANSOPERACAO]',
                                         ITEM.NUMTRANSOPERACAO);
                            VS_HISTORICO := SUBSTR (VS_HISTORICO, 1, 200);

                            --FIM HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO-----------------------------------

                            IF ITENSREGRA.NATUREZA = 'C'
                            THEN
                                VN_TOTALCREDITO :=
                                    ROUND (
                                          VN_TOTALCREDITO
                                        + ABS (VN_VALORLANCTO),
                                        2);
                                VS_NATUREZA := 'C';
                            ELSE
                                VN_TOTALDEBITO :=
                                    ROUND (
                                        VN_TOTALDEBITO + ABS (VN_VALORLANCTO),
                                        2);
                                VS_NATUREZA := 'D';
                            END IF;

                            --GUARDA FILIAIS
                            FILIAIS.CODFILIAL := '-1';

                            FOR VN_POSICAO IN 1 .. FILIAIS_LANCADAS.COUNT
                            LOOP
                                IF (FILIAIS_LANCADAS (VN_POSICAO).CODFILIAL =
                                    VS_CODFILIAL)
                                THEN
                                    FILIAIS := FILIAIS_LANCADAS (VN_POSICAO);
                                    VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

                                    EXIT;
                                END IF;
                            END LOOP;

                            IF (FILIAIS.CODFILIAL = '-1')
                            THEN
                                FILIAIS_LANCADAS.EXTEND;

                                FILIAIS :=
                                    FILIAIS_LANCADAS (FILIAIS_LANCADAS.COUNT);
                                VN_POSICAO_EM_ALTERACAO :=
                                    FILIAIS_LANCADAS.COUNT;

                                FILIAIS.CODFILIAL := VS_CODFILIAL;
                                FILIAIS.CGCFILIAL :=
                                    F_CGCFILIAL (VS_CODFILIAL);

                                FILIAIS_LANCADAS (VN_POSICAO_EM_ALTERACAO) :=
                                    FILIAIS;
                            END IF;

                            --GUARDA AS CONTAS PARA VERIFICAR SE ESTÃO IGUAIS POSTERIORMENTE
                            P_ARMAZENA_CONTAS_FILIAIS_LANC (VS_CONTA,
                                                            VS_NATUREZA,
                                                            VS_CODFILIAL,
                                                            FILIAIS_LANCADAS);

                            IF 'N' = 'S'
                            THEN
                                NULL;
                            ELSE
                                ---------------------------------------------------------------------------------
                                V_SQLERRO :=
                                    '12 - NF SERVICO: EXECUTANDO PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA()';
                                ---------------------------------------------------------------------------------
                                --INSERE DADOS NA TABELA QUANDO NÃO ESTÁ TOTALIZANDO VALORES
                                VN_NUMSEQ := VN_NUMSEQ + 1;

                                P_GRAVA_DADOS_TABINTERMEDIARIA (
                                    VS_CODFILIAL,
                                    VN_NUMTRANSACAO,
                                    VN_NUMSEQ,
                                    VD_DATALANCTO,
                                    VS_DOCUMENTO,
                                    ITENSREGRA.CODHISTORICO,
                                    VS_HISTORICO,
                                    PCODPLANOCONTA,
                                    VS_CONTA,
                                    VS_NATUREZA,
                                    VN_VALORLANCTO,
                                    PCODREGRA,
                                    '',
                                    ITEM.NUMTRANSOPERACAO,
                                    F_RETORNA_TIPO_INCONSISTENCIA (
                                        VS_TEMCONTAINEXISTENTE),
                                    'P',
                                    ITEM.DATAOPERACAO,
                                    0,
                                    0,
                                    '',
                                    '',
                                    VD_DATAINTEGRACAO,
                                    ITEM.CODCLIENTENF,
                                    'C',
                                    NULL,
                                    ITEM.NUMTRANSOPERACAO,
                                    '',
                                    ITENSREGRA.FORMULAS,
                                    ITENSREGRA.CODREDUZIDO_PC,
                                    'NFSERVICO',
                                    'PCNFSAID',
                                    ITENSREGRA.TOTALIZAVALOR);
                            END IF;
                        END IF;
                    END IF;
                END LOOP;
            END IF;

            VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
        END LOOP;

        --VERIFICA CONSISTÊNCIAS DO ÚLTIMO REGISTRO
        IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '12 - NF SERVICO: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
            ---------------------------------------------------------------------------------
            P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                        VD_DATALANCTO,
                                        VS_TEMCONTAINEXISTENTE,
                                        VN_TOTALDEBITO,
                                        VN_TOTALCREDITO,
                                        'N');
        END IF;

        CLOSE CURSOR_DADOS;

        RESULTADO := 'OK';
    EXCEPTION
        WHEN OTHERS
        THEN
            RESULTADO :=
                   'Ocorreu um erro quando: '
                || V_SQLERRO
                || CHR (13)
                || 'Erro Original: '
                || SQLERRM;
    END;


    /****************************************************************************
        PROCEDURE PARA FATO GERADOR DE 13 - PAGAMENTOS COM ADIANTAMENTO FORNECEDOR
      *****************************************************************************/
    PROCEDURE P_DADOS_ADIANTAMENTOFORNECEDOR (
        CURSOR_DADOS     IN     SYS_REFCURSOR,
        PCODREGRA        IN     NUMBER,
        PCODPLANOCONTA   IN     NUMBER,
        RESULTADO           OUT VARCHAR2)
    IS
        TYPE CONSULTA_ADIANTAMENTOS IS RECORD
        (
            CODFILIAL PCLANC.CODFILIAL%TYPE,
            NUMNOTA PCLANC.NUMNOTA%TYPE,
            NUMLANCTO PCLANC.RECNUM%TYPE,
            DATAOPERACAO PCLANC.DTPAGTO%TYPE,
            DATAOPERACAO1 PCMOVCR.DTCOMPENSACAO%TYPE,
            DATAOPERACAO2 PCLANCADIANTFORNEC.DTESTORNO%TYPE,
            CODCONTA PCCONTA.CODCONTA%TYPE,
            CODFORNEC PCFORNEC.CODFORNEC%TYPE,
            FORNECEDOR PCFORNEC.FORNECEDOR%TYPE,
            CODCONTAVERBA PCMODELOPC.CODREDUZIDO_PC%TYPE,
            CODCONTADESPFORNECEDOR PCMODELOPC.CODREDUZIDO_PC%TYPE,
            CODCONTARECEITA PCMODELOPC.CODREDUZIDO_PC%TYPE,
            CODCONTABILBANCO PCMODELOPC.CODREDUZIDO_PC%TYPE,
            CODCONTACONTABADIANTFOR PCMODELOPC.CODREDUZIDO_PC%TYPE,
            VALORTITULO PCLANC.VALOR%TYPE,
            VALORDEVOLUCAO PCLANC.VALOR%TYPE,
            VALORJUROS PCLANC.VALOR%TYPE,
            VALORDESCONTO PCLANC.VALOR%TYPE,
            VALORDESCVERBA PCLANC.VALOR%TYPE,
            -- VALORDESCDEVOLUCAO     PCLANC.VALOR%TYPE,
            VALORPAGO PCLANC.VALOR%TYPE,
            HISTORICO PCLANC.HISTORICO%TYPE,
            HISTORICO2 PCLANC.HISTORICO2%TYPE,
            HISTORICOMOVBANCO PCMOVCR.HISTORICO%TYPE,
            DUPLICATA PCLANC.DUPLIC%TYPE,
            NUMNOTADEVOLUCAO PCLANC.NUMNOTADEV%TYPE,
            NUMBANCO PCLANC.NUMBANCO%TYPE,
            CODBANCO PCBANCO.CODBANCO%TYPE,
            NOMEBANCOPGTO PCBANCO.NOME%TYPE,
            TIPODEPAGAMENTO PCLANC.TIPOPAGTO%TYPE,
            NUMTRANSOPERACAO VARCHAR2 (50),
            STATUS PCLANC.INDICE%TYPE,
            NUMDOCTO PCLANCAMENTO.DOCUMENTO%TYPE,
            NOMECONTAGERENCIAL PCCONTA.CONTA%TYPE,
            CODMOEDA PCMOVCR.CODCOB%TYPE,
            TIPOPARCEIRO PCLANC.TIPOPARCEIRO%TYPE,
            TEMINTEGRACAO VARCHAR2 (5),
            VALORVARIACAOCAMBIALPOSITIVA PCLANC.VLVARIACAOCAMBIAL%TYPE,
            VALORVARIACAOCAMBIALNEGATIVA PCLANC.VLVARIACAOCAMBIAL%TYPE
        );

        ITEM                CONSULTA_ADIANTAMENTOS;
        ITENSREGRA          CONSULTA_ITENS;

        CURSOR_ITENS        SYS_REFCURSOR;

        FILIAIS_LANCADAS    TABELAFILIAISLANCTO;
        FILIAIS             FILIAISLANCTO;
        VS_CONTA_EXISTE     VARCHAR2 (1);

        VD_DATALANCTO_AUX   DATE;
    BEGIN
        LISTA_FORMULAS := TYPE_LISTA_FORMULAS ();
        FILIAIS_LANCADAS := TABELAFILIAISLANCTO ();

        VS_SEQGERADO := 'N';
        VS_FORMADTCONTABILIZACAO := '';
        VN_NUMTRANSACAO := 0;
        VS_DOCUMENTO := '';
        VS_TEMCONTAINEXISTENTE := 'N';

        --BUSCA DADOS DA REGRA
        SELECT FORMADTCONTABILIZACAO, BUSCARDADOSPELADATA
          INTO VS_FORMADTCONTABILIZACAO, VS_BUSCARDADOSPELADATA
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        V_SQLERRO := 'ABRINDO PAGAMENTOS';

        --INICIA LAÇO DOS DADOS
        LOOP
            FETCH CURSOR_DADOS INTO ITEM;

            EXIT WHEN CURSOR_DADOS%NOTFOUND;

            IF    (ITEM.TEMINTEGRACAO IS NULL)
               OR (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                   AND (ITEM.TEMINTEGRACAO = 'P'))
            THEN
                VD_DATALANCTO_AUX :=
                    F_RETORNA_DATA_LANCPROVISOES (13,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO,
                                                  ITEM.DATAOPERACAO1,
                                                  ITEM.DATAOPERACAO2);

                --------------------------------------------------------------------
                --VERIFICA SE ALTEROU O NUMTRANSOPERACAO PARA FAZER GRAVAÇÃO E RE-INICIAR VARIÁVEIS
                IF (VN_NUMTRANSOPERACAO <> ITEM.NUMTRANSOPERACAO)
                THEN
                    VS_SEQGERADO := 'N';

                    IF (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                        AND (ITEM.TEMINTEGRACAO = 'P'))
                    THEN
                        P_EXCLUI_LANCINTERMEDIARIA_IND (
                            PCODREGRA,
                            ITEM.NUMTRANSOPERACAO,
                            VD_DATALANCTO_AUX);
                    END IF;

                    --VERIFICA SE JÁ PASSOU POR ALGUM REGISTRO PARA ATRIBUIR INCONSISTÊNCIAS
                    IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) >
                       0
                    THEN
                        ---------------------------------------------------------------------------------
                        V_SQLERRO :=
                            '13 - PAGAMENTOS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
                        ---------------------------------------------------------------------------------
                        P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                                    VD_DATALANCTO,
                                                    VS_TEMCONTAINEXISTENTE,
                                                    VN_TOTALDEBITO,
                                                    VN_TOTALCREDITO,
                                                    'N');
                    END IF;

                    VS_TEMCONTAINEXISTENTE := 'N';
                END IF;

                --------------------------------------------------------------------

                --GERA NOVO NUMTRANSLANCTO
                IF VS_SEQGERADO = 'N'
                THEN
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '13 - PAGAMENTOS: EXECUTANDO FUNÇÃO GERA_NUM_TRANS_LANCTO()';
                    ---------------------------------------------------------------------------------
                    VN_NUMTRANSACAO := F_GERA_NUM_TRANS_LANCTO ();


                    VN_NUMSEQ := 0;
                    VN_TOTALCREDITO := 0;
                    VN_TOTALDEBITO := 0;
                    VS_SEQGERADO := 'S';

                    CONTASDEBLANCTO := CONTAS_LANCADAS ();
                    CONTASCRELANCTO := CONTAS_LANCADAS ();
                    CGCSLANCTO := CGC_LANCADOS ();
                    VS_LISTAS_TRANSOTORIAS := CONTAS_LANCADAS ();

                    CONTASDEBLANCTO.EXTEND;
                    CONTASCRELANCTO.EXTEND;
                END IF;

                VD_DATALANCTO :=
                    F_RETORNA_DATA_LANCPROVISOES (13,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO,
                                                  ITEM.DATAOPERACAO1,
                                                  ITEM.DATAOPERACAO2);

                VD_DATAINTEGRACAO :=
                    F_RETORNA_DATA_LANCPROVISOES (13,
                                                  PCODREGRA,
                                                  DATA_INTEGRACAO,
                                                  ITEM.DATAOPERACAO,
                                                  ITEM.DATAOPERACAO1,
                                                  ITEM.DATAOPERACAO2);

                --LAÇO NOS ITENS DA REGRA CONTABIL
                OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL ()
                    USING PCODREGRA;

                LOOP
                    FETCH CURSOR_ITENS INTO ITENSREGRA;

                    EXIT WHEN CURSOR_ITENS%NOTFOUND;

                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '13 - PAGAMENTOS: ATRIBUINDO VALOR DO DOCUMENTO';
                    ---------------------------------------------------------------------------------
                    VS_DOCUMENTO := ITENSREGRA.DOCUMENTO;
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO1',
                                 ITEM.DATAOPERACAO1);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO2',
                                 ITEM.DATAOPERACAO2);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO',
                                 ITEM.DATAOPERACAO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMLANCTO', ITEM.NUMLANCTO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMTRANSOPERACAO',
                                 ITEM.NUMTRANSOPERACAO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMDOCTO', ITEM.NUMDOCTO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMNOTA', ITEM.NUMNOTA);

                    --FORMULA INFORMADA NO FILTRO--------------------------------------------------------
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '13 - PAGAMENTOS: ATRIBUINDO VALOR DA FÓRMULA';
                    ---------------------------------------------------------------------------------
                    VN_VALORLANCTO := 0;

                    VS_FORMULA := ITENSREGRA.FORMULAS || ' + 0 ';
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORTITULO([^_[:alnum:]])',
                                        NVL (ITEM.VALORTITULO, 0));
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORDEVOLUCAO([^_[:alnum:]])',
                                        NVL (ITEM.VALORDEVOLUCAO, 0));
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORJUROS([^_[:alnum:]])',
                                        NVL (ITEM.VALORJUROS, 0));
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORDESCONTO([^_[:alnum:]])',
                                        NVL (ITEM.VALORDESCONTO, 0));
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORDESCVERBA([^_[:alnum:]])',
                                        NVL (ITEM.VALORDESCVERBA, 0));
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORJUROS([^_[:alnum:]])',
                                        NVL (ITEM.VALORJUROS, 0));
                    -- VS_FORMULA := REGEXP_REPLACE ( VS_FORMULA , 'VALORDESCDEVOLUCAO([^_[:alnum:]])', NVL(ITEM.VALORDESCDEVOLUCAO, 0) );
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORPAGO([^_[:alnum:]])',
                                        NVL (ITEM.VALORPAGO, 0));
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORVARIACAOCAMBIALPOSITIVA([^_[:alnum:]])',
                            NVL (ITEM.VALORVARIACAOCAMBIALPOSITIVA, 0));
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORVARIACAOCAMBIALNEGATIVA([^_[:alnum:]])',
                            NVL (ITEM.VALORVARIACAOCAMBIALNEGATIVA, 0));


                    CALCULAREXPRESSAO;

                    --FIM DA FÓRMULA---------------------------------------------------------------------

                    IF VN_VALORLANCTO <> 0
                    THEN
                        VS_CONTA := TRIM (ITENSREGRA.CODREDUZIDO_PC);
                        VS_CODFILIAL :=
                            CASE
                                WHEN ITENSREGRA.CODFILIAL =
                                     'FILIALLANCAMENTO'
                                THEN
                                    ITEM.CODFILIAL
                                ELSE
                                    ITENSREGRA.CODFILIAL
                            END;

                        IF     (SUBSTR (VS_CONTA, 1, 1) <> '0')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '1')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '2')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '3')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '4')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '5')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '6')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '7')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '8')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '9')
                        THEN
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTADESPFORNECEDOR',
                                         ITEM.CODCONTADESPFORNECEDOR);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTABILBANCO',
                                         ITEM.CODCONTABILBANCO);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTARECEITA',
                                         ITEM.CODCONTARECEITA);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTAVERBA',
                                         ITEM.CODCONTARECEITA);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTACONTABADIANTFOR',
                                         ITEM.CODCONTACONTABADIANTFOR);
                        END IF;


                        VS_CONTA_EXISTE :=
                            F_VERIFICA_CONTA_EXISTE (VS_CONTA,
                                                     PCODPLANOCONTA);
                        TRATAR_CONTA_INEXISTENTE (VS_CONTA_EXISTE,
                                                  VS_TEMCONTAINEXISTENTE);

                        IF VS_CONTA_EXISTE IN ('S', 'I', 'X')
                        THEN
                            --HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO---------------------------------------
                            ---------------------------------------------------------------------------------
                            V_SQLERRO :=
                                '13 - PAGAMENTOS: ATRIBUINDO VALOR DE HISTÓRICOS';
                            ---------------------------------------------------------------------------------
                            VS_HISTORICO := ITENSREGRA.HISTCOMPLREGRA;

                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[FORNECEDOR]',
                                         ITEM.FORNECEDOR);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO1]',
                                         ITEM.DATAOPERACAO1);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO2]',
                                         ITEM.DATAOPERACAO2);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO]',
                                         ITEM.DATAOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[HISTORICO]',
                                         ITEM.HISTORICO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[HISTORICO2]',
                                         ITEM.HISTORICO2);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[HISTORICOMOVBANCO]',
                                         ITEM.HISTORICOMOVBANCO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMLANCTO]',
                                         ITEM.NUMLANCTO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMNOTA]',
                                         ITEM.NUMNOTA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DUPLICATA]',
                                         ITEM.DUPLICATA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMNOTADEVOLUCAO]',
                                         ITEM.NUMNOTADEVOLUCAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMBANCO]',
                                         ITEM.NUMBANCO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODBANCO]',
                                         ITEM.CODBANCO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NOMEBANCOPGTO]',
                                         ITEM.NOMEBANCOPGTO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[TIPODEPAGAMENTO]',
                                         ITEM.TIPODEPAGAMENTO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[STATUS]',
                                         ITEM.STATUS);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMDOCTO]',
                                         ITEM.NUMDOCTO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMTRANSOPERACAO]',
                                         ITEM.NUMTRANSOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NOMECONTAGERENCIAL]',
                                         ITEM.NOMECONTAGERENCIAL);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODFORNEC]',
                                         ITEM.CODFORNEC);
                            VS_HISTORICO := SUBSTR (VS_HISTORICO, 1, 200);

                            --FIM HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO-----------------------------------

                            IF ITENSREGRA.NATUREZA = 'C'
                            THEN
                                --VN_TOTALCREDITO := ROUND(VN_TOTALCREDITO + ABS(VN_VALORLANCTO), 2);

                                IF VN_VALORLANCTO < 0
                                THEN
                                    VS_NATUREZA := 'D';
                                ELSE
                                    VS_NATUREZA := 'C';
                                END IF;
                            ELSE
                                --VN_TOTALDEBITO := ROUND(VN_TOTALDEBITO + ABS(VN_VALORLANCTO), 2);

                                IF VN_VALORLANCTO < 0
                                THEN
                                    VS_NATUREZA := 'C';
                                ELSE
                                    VS_NATUREZA := 'D';
                                END IF;
                            END IF;

                            IF VS_NATUREZA = 'C'
                            THEN
                                VN_TOTALCREDITO :=
                                    ROUND (
                                          VN_TOTALCREDITO
                                        + ABS (VN_VALORLANCTO),
                                        2);
                            ELSE
                                VN_TOTALDEBITO :=
                                    ROUND (
                                        VN_TOTALDEBITO + ABS (VN_VALORLANCTO),
                                        2);
                            END IF;

                            --GUARDA FILIAIS
                            FILIAIS.CODFILIAL := '-1';

                            FOR VN_POSICAO IN 1 .. FILIAIS_LANCADAS.COUNT
                            LOOP
                                IF (FILIAIS_LANCADAS (VN_POSICAO).CODFILIAL =
                                    VS_CODFILIAL)
                                THEN
                                    FILIAIS := FILIAIS_LANCADAS (VN_POSICAO);
                                    VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

                                    EXIT;
                                END IF;
                            END LOOP;

                            IF (FILIAIS.CODFILIAL = '-1')
                            THEN
                                FILIAIS_LANCADAS.EXTEND;

                                FILIAIS :=
                                    FILIAIS_LANCADAS (FILIAIS_LANCADAS.COUNT);
                                VN_POSICAO_EM_ALTERACAO :=
                                    FILIAIS_LANCADAS.COUNT;

                                FILIAIS.CODFILIAL := VS_CODFILIAL;
                                FILIAIS.CGCFILIAL :=
                                    F_CGCFILIAL (VS_CODFILIAL);

                                FILIAIS_LANCADAS (VN_POSICAO_EM_ALTERACAO) :=
                                    FILIAIS;
                            END IF;

                            --GUARDA AS CONTAS PARA VERIFICAR SE ESTÃO IGUAIS POSTERIORMENTE
                            P_ARMAZENA_CONTAS_FILIAIS_LANC (VS_CONTA,
                                                            VS_NATUREZA,
                                                            VS_CODFILIAL,
                                                            FILIAIS_LANCADAS);

                            IF 'N' = 'S'
                            THEN
                                NULL;
                            ELSE
                                ---------------------------------------------------------------------------------
                                V_SQLERRO :=
                                    '13 - PAGAMENTOS: EXECUTANDO PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA()';
                                ---------------------------------------------------------------------------------

                                --INSERE DADOS NA TABELA QUANDO NÃO ESTÁ TOTALIZANDO VALORES
                                VN_NUMSEQ := VN_NUMSEQ + 1;

                                P_GRAVA_DADOS_TABINTERMEDIARIA (
                                    VS_CODFILIAL,
                                    VN_NUMTRANSACAO,
                                    VN_NUMSEQ,
                                    VD_DATALANCTO,
                                    VS_DOCUMENTO,
                                    ITENSREGRA.CODHISTORICO,
                                    VS_HISTORICO,
                                    PCODPLANOCONTA,
                                    VS_CONTA,
                                    VS_NATUREZA,
                                    ABS (VN_VALORLANCTO),
                                    PCODREGRA,
                                    '',
                                    ITEM.NUMTRANSOPERACAO,
                                    F_RETORNA_TIPO_INCONSISTENCIA (
                                        VS_TEMCONTAINEXISTENTE),
                                    'P',
                                    VD_DATAINTEGRACAO,
                                    0,
                                    ITEM.CODBANCO,
                                    ITEM.CODMOEDA,
                                    '',
                                    TRUNC (SYSDATE),
                                    ITEM.CODFORNEC,
                                    'F',
                                    NULL,
                                    ITEM.NUMLANCTO,
                                    '',
                                    ITENSREGRA.FORMULAS,
                                    ITENSREGRA.CODREDUZIDO_PC,
                                    'PGADIANTAMENTO',
                                    'PCLANC',
                                    ITENSREGRA.TOTALIZAVALOR);
                            END IF;
                        END IF;
                    END IF;
                END LOOP;

                --GUARDA O NÚMERO DA TRANSAÇÃO
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            ELSE
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            END IF;
        END LOOP;

        --VERIFICA CONSISTÊNCIAS DO ÚLTIMO REGISTRO
        IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '13 - PAGAMENTOS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
            ---------------------------------------------------------------------------------
            P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                        VD_DATALANCTO,
                                        VS_TEMCONTAINEXISTENTE,
                                        VN_TOTALDEBITO,
                                        VN_TOTALCREDITO,
                                        'N');
        END IF;

        CLOSE CURSOR_DADOS;

        RESULTADO := 'OK';
    EXCEPTION
        WHEN OTHERS
        THEN
            RESULTADO :=
                   'Ocorreu um erro quando: '
                || V_SQLERRO
                || CHR (13)
                || 'Erro Original: '
                || SQLERRM;
    END;

    /****************************************************************************
      PROCEDURE PARA GERAÇÃO DE 14 - INCLUSÃO MANUAL DE CONTAS A RECEBER
    *****************************************************************************/
    PROCEDURE P_DADOS_INCLUSAOMANUALRECEBER (
        CURSOR_DADOS     IN     SYS_REFCURSOR,
        PCODREGRA        IN     NUMBER,
        PCODPLANOCONTA   IN     NUMBER,
        RESULTADO           OUT VARCHAR2)
    IS
        TYPE CONSULTA_RECEBIMENTOS IS RECORD
        (
            ORIGEM VARCHAR2 (10),
            CODFILIAL VARCHAR2 (2),
            VALORTITULO PCLANCAMENTO.VALOR%TYPE,
            DATAOPERACAO DATE,
            DUPLICATA NUMBER (10),
            NUMTRANSOPERACAO NUMBER (10),
            VLLANCTO PCLANCAMENTO.VALOR%TYPE,
            DOCUMENTO NUMBER (10),
            CODCONTAGERENCIAL VARCHAR2 (12),
            CODCONTABANCO VARCHAR2 (12),
            CODCONTACLIENTE VARCHAR2 (12),
            HISTORICOMOVIMENTACAOBANCARIA1 VARCHAR2 (200),
            HISTORICOMOVIMENTACAOBANCARIA2 VARCHAR2 (200),
            CODBANCO NUMBER (4, 0),
            CODCLIENTE PCCLIENT.CODCLI%TYPE,
            CODMOEDA VARCHAR2 (4),
            CODCOBRANCA VARCHAR2 (4),
            CODRCA NUMBER (4, 0),
            CONTAGERENCIAL NUMBER (10, 0),
            DATAVENCIMENTO DATE,
            PRESTACAO VARCHAR2 (2),
            CLIENTE PCCLIENT.CLIENTE%TYPE,
            HISTORICOLANCAMENTODESPESAS1 VARCHAR2 (200),
            HISTORICOLANCAMENTODESPESAS2 VARCHAR2 (200),
            TEMINTEGRACAO VARCHAR2 (1)
        );

        ITEM                     CONSULTA_RECEBIMENTOS;
        ITENSREGRA               CONSULTA_ITENS;

        CURSOR_ITENS             SYS_REFCURSOR;

        FILIAIS_LANCADAS         TABELAFILIAISLANCTO;
        FILIAIS                  FILIAISLANCTO;
        VS_RECNUM_CENTROCUSTO    VARCHAR2 (12);
        VB_ECONTA_PREDEFINIDA    BOOLEAN;
        VB_ECONTA_GERENCIAL      BOOLEAN;

        TYPE RECORD_CODREDUZIDO_NUMTRANSCC IS RECORD
        (
            CODREDUZIDO_PC PCLANCINTERMEDIARIA.CODREDUZIDO_PC%TYPE,
            NUMTRANSCC PCLANCINTERMEDIARIA.NUMTRANSCENTROCUSTO%TYPE
        );

        TYPE TABELA_CODREDUZIDO_NUMTRANSCC
            IS TABLE OF RECORD_CODREDUZIDO_NUMTRANSCC;

        CODREDUZIDO_NUMTRANSCC   TABELA_CODREDUZIDO_NUMTRANSCC;
        VS_CONTA_EXISTE          VARCHAR2 (1);
    BEGIN
        LISTA_FORMULAS := TYPE_LISTA_FORMULAS ();


        FILIAIS_LANCADAS := TABELAFILIAISLANCTO ();

        VS_SEQGERADO := 'N';
        VS_FORMADTCONTABILIZACAO := '';
        VN_NUMTRANSACAO := 0;
        VS_DOCUMENTO := '';
        VB_ECONTA_PREDEFINIDA := FALSE;
        VB_ECONTA_GERENCIAL := FALSE;
        VS_TEMCONTAINEXISTENTE := 'N';

        --BUSCA DADOS DA REGRA
        SELECT FORMADTCONTABILIZACAO, BUSCARDADOSPELADATA
          INTO VS_FORMADTCONTABILIZACAO, VS_BUSCARDADOSPELADATA
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        V_SQLERRO := 'ABRINDO INCLUSÃO MANUAL RECEBER';

        --INICIA LAÇO DOS DADOS
        LOOP
            FETCH CURSOR_DADOS INTO ITEM;

            EXIT WHEN CURSOR_DADOS%NOTFOUND;

            IF    (ITEM.TEMINTEGRACAO IS NULL)
               OR (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                   AND (ITEM.TEMINTEGRACAO = 'P'))
            THEN
                --------------------------------------------------------------------
                --VERIFICA SE ALTEROU O NUMTRANSOPERACAO PARA FAZER GRAVAÇÃO E RE-INICIAR VARIÁVEIS
                IF    (VN_NUMTRANSOPERACAO <> ITEM.NUMTRANSOPERACAO)
                   OR (    (VN_NUMTRANSOPERACAO = ITEM.NUMTRANSOPERACAO)
                       AND (VD_DATALANCTO <> ITEM.DATAOPERACAO))
                THEN
                    VS_SEQGERADO := 'N';

                    IF (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                        AND (ITEM.TEMINTEGRACAO = 'P'))
                    THEN
                        P_EXCLUI_LANCINTERMEDIARIA_IND (
                            PCODREGRA,
                            ITEM.NUMTRANSOPERACAO,
                            ITEM.DATAOPERACAO);
                    END IF;

                    --VERIFICA SE JÁ PASSOU POR ALGUM REGISTRO PARA ATRIBUIR INCONSISTÊNCIAS
                    IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) >
                       0
                    THEN
                        ---------------------------------------------------------------------------------
                        V_SQLERRO :=
                            '14 - INCLUSÃO MANUAL RECEBER: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
                        ---------------------------------------------------------------------------------
                        P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                                    VD_DATALANCTO,
                                                    VS_TEMCONTAINEXISTENTE,
                                                    VN_TOTALDEBITO,
                                                    VN_TOTALCREDITO,
                                                    'N');
                    END IF;

                    VS_TEMCONTAINEXISTENTE := 'N';
                END IF;

                --------------------------------------------------------------------

                --GERA NOVO NUMTRANSLANCTO
                IF VS_SEQGERADO = 'N'
                THEN
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '14 - INCLUSÃO MANUAL RECEBER: EXECUTANDO FUNÇÃO GERA_NUM_TRANS_LANCTO()';
                    ---------------------------------------------------------------------------------
                    VN_NUMTRANSACAO := F_GERA_NUM_TRANS_LANCTO ();
                    VS_NUMTRANSCENTROCUSTO := '';

                    VN_NUMSEQ := 0;
                    VN_TOTALCREDITO := 0;
                    VN_TOTALDEBITO := 0;
                    VS_SEQGERADO := 'S';

                    CONTASDEBLANCTO := CONTAS_LANCADAS ();
                    CONTASCRELANCTO := CONTAS_LANCADAS ();
                    CGCSLANCTO := CGC_LANCADOS ();
                    VS_LISTAS_TRANSOTORIAS := CONTAS_LANCADAS ();

                    CONTASDEBLANCTO.EXTEND;
                    CONTASCRELANCTO.EXTEND;
                    CODREDUZIDO_NUMTRANSCC :=
                        TABELA_CODREDUZIDO_NUMTRANSCC ();
                END IF;

                VD_DATALANCTO :=
                    F_RETORNA_DATA_LANCPROVISOES (14,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO);

                VD_DATAINTEGRACAO :=
                    F_RETORNA_DATA_LANCPROVISOES (14,
                                                  PCODREGRA,
                                                  DATA_INTEGRACAO,
                                                  ITEM.DATAOPERACAO);

                --LAÇO NOS ITENS DA REGRA CONTABIL
                OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL ()
                    USING PCODREGRA;

                LOOP
                    FETCH CURSOR_ITENS INTO ITENSREGRA;

                    EXIT WHEN CURSOR_ITENS%NOTFOUND;

                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '14 - INCLUSÃO MANUAL RECEBER: ATRIBUINDO VALOR DO DOCUMENTO';
                    ---------------------------------------------------------------------------------
                    VS_DOCUMENTO := ITENSREGRA.DOCUMENTO;
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO',
                                 TO_CHAR (ITEM.DATAOPERACAO, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'DUPLICATA', ITEM.DUPLICATA);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMTRANSOPERACAO',
                                 ITEM.NUMTRANSOPERACAO);

                    --FORMULA INFORMADA NO FILTRO--------------------------------------------------------
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '14 - INCLUSÃO MANUAL RECEBER: ATRIBUINDO VALOR DA FÓRMULA';
                    ---------------------------------------------------------------------------------
                    VN_VALORLANCTO := 0;

                    VS_FORMULA := ITENSREGRA.FORMULAS || ' + 0 ';
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORTITULO([^_[:alnum:]])',
                                        NVL (ITEM.VALORTITULO, 0) || '\1');

                    CALCULAREXPRESSAO;

                    --FIM DA FÓRMULA---------------------------------------------------------------------

                    IF VN_VALORLANCTO <> 0
                    THEN
                        VS_CONTA := TRIM (ITENSREGRA.CODREDUZIDO_PC);
                        VS_CODFILIAL :=
                            CASE
                                WHEN ITENSREGRA.CODFILIAL =
                                     'FILIALLANCAMENTO'
                                THEN
                                    ITEM.CODFILIAL
                                ELSE
                                    ITENSREGRA.CODFILIAL
                            END;

                        VB_ECONTA_PREDEFINIDA := FALSE;
                        VB_ECONTA_GERENCIAL := FALSE;

                        IF     (SUBSTR (VS_CONTA, 1, 1) <> '0')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '1')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '2')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '3')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '4')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '5')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '6')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '7')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '8')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '9')
                        THEN
                            IF VS_CONTA = 'CODCONTAGERENCIAL'
                            THEN
                                VB_ECONTA_GERENCIAL := TRUE;
                            END IF;

                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTAGERENCIAL',
                                         ITEM.CODCONTAGERENCIAL);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTABANCO',
                                         ITEM.CODCONTABANCO);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTACLIENTE',
                                         ITEM.CODCONTACLIENTE);

                            VB_ECONTA_PREDEFINIDA := TRUE;
                        END IF;

                        VS_CONTA_EXISTE :=
                            F_VERIFICA_CONTA_EXISTE (VS_CONTA,
                                                     PCODPLANOCONTA);
                        TRATAR_CONTA_INEXISTENTE (VS_CONTA_EXISTE,
                                                  VS_TEMCONTAINEXISTENTE);

                        IF VS_CONTA_EXISTE IN ('S', 'I', 'X')
                        THEN
                            --HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO---------------------------------------
                            ---------------------------------------------------------------------------------
                            V_SQLERRO :=
                                '14 - INCLUSÃO MANUAL RECEBER: ATRIBUINDO VALOR DE HISTÓRICOS';
                            ---------------------------------------------------------------------------------
                            VS_HISTORICO := ITENSREGRA.HISTCOMPLREGRA;
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DUPLICATA]',
                                         ITEM.DUPLICATA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODBANCO]',
                                         ITEM.CODBANCO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODCLIENTE]',
                                         ITEM.CODCLIENTE);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CLIENTE]',
                                         ITEM.CLIENTE);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAVENCIMENTO]',
                                         ITEM.DATAVENCIMENTO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[PRESTACAO]',
                                         ITEM.PRESTACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[HISTORICOMOVIMENTACAOBANCARIA1]',
                                         ITEM.HISTORICOMOVIMENTACAOBANCARIA1);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[HISTORICOMOVIMENTACAOBANCARIA2]',
                                         ITEM.HISTORICOMOVIMENTACAOBANCARIA2);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[HISTORICOLANCAMENTODESPESAS1]',
                                         ITEM.HISTORICOLANCAMENTODESPESAS1);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[HISTORICOLANCAMENTODESPESAS2]',
                                         ITEM.HISTORICOLANCAMENTODESPESAS2);

                            VS_HISTORICO := SUBSTR (VS_HISTORICO, 1, 200);

                            --FIM HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO-----------------------------------

                            IF ITENSREGRA.NATUREZA = 'C'
                            THEN
                                IF VN_VALORLANCTO < 0
                                THEN
                                    VS_NATUREZA := 'D';
                                ELSE
                                    VS_NATUREZA := 'C';
                                END IF;
                            ELSE
                                IF VN_VALORLANCTO < 0
                                THEN
                                    VS_NATUREZA := 'C';
                                ELSE
                                    VS_NATUREZA := 'D';
                                END IF;
                            END IF;

                            IF VS_NATUREZA = 'C'
                            THEN
                                VN_TOTALCREDITO :=
                                    ROUND (
                                          VN_TOTALCREDITO
                                        + ABS (VN_VALORLANCTO),
                                        2);
                            ELSE
                                VN_TOTALDEBITO :=
                                    ROUND (
                                        VN_TOTALDEBITO + ABS (VN_VALORLANCTO),
                                        2);
                            END IF;

                            --GUARDA FILIAIS
                            FILIAIS.CODFILIAL := '-1';

                            FOR VN_POSICAO IN 1 .. FILIAIS_LANCADAS.COUNT
                            LOOP
                                IF (FILIAIS_LANCADAS (VN_POSICAO).CODFILIAL =
                                    VS_CODFILIAL)
                                THEN
                                    FILIAIS := FILIAIS_LANCADAS (VN_POSICAO);
                                    VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

                                    EXIT;
                                END IF;
                            END LOOP;

                            IF (FILIAIS.CODFILIAL = '-1')
                            THEN
                                FILIAIS_LANCADAS.EXTEND;

                                FILIAIS :=
                                    FILIAIS_LANCADAS (FILIAIS_LANCADAS.COUNT);
                                VN_POSICAO_EM_ALTERACAO :=
                                    FILIAIS_LANCADAS.COUNT;

                                FILIAIS.CODFILIAL := VS_CODFILIAL;
                                FILIAIS.CGCFILIAL :=
                                    F_CGCFILIAL (VS_CODFILIAL);

                                FILIAIS_LANCADAS (VN_POSICAO_EM_ALTERACAO) :=
                                    FILIAIS;
                            END IF;

                            --GUARDA AS CONTAS PARA VERIFICAR SE ESTÃO IGUAIS POSTERIORMENTE
                            P_ARMAZENA_CONTAS_FILIAIS_LANC (VS_CONTA,
                                                            VS_NATUREZA,
                                                            VS_CODFILIAL,
                                                            FILIAIS_LANCADAS);

                            IF 'N' = 'S'
                            THEN
                                NULL;
                            ELSE
                                ---------------------------------------------------------------------------------
                                V_SQLERRO :=
                                    '14 - INCLUSÃO MANUAL RECEBER: EXECUTANDO PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA()';

                                ---------------------------------------------------------------------------------

                                -- CENTRO DE CUSTOS
                                IF     VB_ECONTA_PREDEFINIDA
                                   AND VB_ECONTA_GERENCIAL
                                   AND F_USA_CENTRO_CUSTO (VS_CONTA,
                                                           PCODPLANOCONTA)
                                THEN
                                    BEGIN
                                        SELECT RECNUM
                                          INTO VS_RECNUM_CENTROCUSTO
                                          FROM PCLANC
                                         WHERE     PCLANC.DUPLIC =
                                                   ITEM.PRESTACAO
                                               AND PCLANC.LOCALIZACAO =
                                                   TO_CHAR (
                                                       ITEM.NUMTRANSOPERACAO)
                                               AND PCLANC.NUMNOTA =
                                                   ITEM.DUPLICATA
                                               AND PCLANC.CODROTINABAIXA =
                                                   1206
                                               AND PCLANC.VALOR < 0;
                                    EXCEPTION
                                        WHEN NO_DATA_FOUND
                                        THEN
                                            VS_RECNUM_CENTROCUSTO := NULL;
                                    END;

                                    --INSERE CENTRO DE CUSTO
                                    IF VS_RECNUM_CENTROCUSTO IS NOT NULL
                                    THEN
                                        VS_NUMTRANSCENTROCUSTO :=
                                            F_RETORNA_NUMTRANS_CENTROCUSTO ();
                                    END IF;
                                END IF;

                                --INSERE DADOS NA TABELA QUANDO NÃO ESTÁ TOTALIZANDO VALORES
                                VN_NUMSEQ := VN_NUMSEQ + 1;

                                P_GRAVA_DADOS_TABINTERMEDIARIA (
                                    VS_CODFILIAL,
                                    VN_NUMTRANSACAO,
                                    VN_NUMSEQ,
                                    VD_DATALANCTO,
                                    VS_DOCUMENTO,
                                    ITENSREGRA.CODHISTORICO,
                                    VS_HISTORICO,
                                    PCODPLANOCONTA,
                                    VS_CONTA,
                                    VS_NATUREZA,
                                    ABS (VN_VALORLANCTO),
                                    PCODREGRA,
                                    '',
                                    ITEM.NUMTRANSOPERACAO,
                                    F_RETORNA_TIPO_INCONSISTENCIA (
                                        VS_TEMCONTAINEXISTENTE),
                                    'P',
                                    ITEM.DATAOPERACAO,
                                    0,
                                    ITEM.CODBANCO,
                                    ITEM.CODMOEDA,
                                    VS_NUMTRANSCENTROCUSTO,
                                    VD_DATAINTEGRACAO,
                                    ITEM.CODCLIENTE,
                                    'C',
                                    NULL,
                                    ITEM.NUMTRANSOPERACAO,
                                    ITEM.PRESTACAO,
                                    ITENSREGRA.FORMULAS,
                                    ITENSREGRA.CODREDUZIDO_PC,
                                    'PROVRECEBER',
                                    'PCPREST',
                                    ITENSREGRA.TOTALIZAVALOR);

                                IF VS_RECNUM_CENTROCUSTO IS NOT NULL
                                THEN
                                    P_GRAVA_PCINTER_CENTROCUSTO (
                                        VS_RECNUM_CENTROCUSTO,
                                        VS_NUMTRANSCENTROCUSTO,
                                        PCODREGRA,
                                        ITEM.DATAOPERACAO,
                                        FALSE,
                                        0,
                                        VN_NUMTRANSACAO,
                                           VS_HISTORICO
                                        || vs_conta
                                        || VS_CODFILIAL,
                                        0);
                                END IF;

                                VS_NUMTRANSCENTROCUSTO := NULL;
                            END IF;
                        END IF;
                    END IF;
                END LOOP;

                --GUARDA O NÚMERO DA TRANSAÇÃO
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            ELSE
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            END IF;
        END LOOP;

        --VERIFICA CONSISTÊNCIAS DO ÚLTIMO REGISTRO
        IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '14 - INCLUSÃO MANUAL RECEBER: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
            ---------------------------------------------------------------------------------
            P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                        VD_DATALANCTO,
                                        VS_TEMCONTAINEXISTENTE,
                                        VN_TOTALDEBITO,
                                        VN_TOTALCREDITO,
                                        'N');
        END IF;

        CLOSE CURSOR_DADOS;

        RESULTADO := 'OK';
    EXCEPTION
        WHEN OTHERS
        THEN
            RESULTADO :=
                   'Ocorreu um erro quando: '
                || V_SQLERRO
                || CHR (13)
                || 'Erro Original: '
                || SQLERRM;
    END;

    /****************************************************************************
      PROCEDURE PARA GERAÇÃO DE 15 - BAIXA DE ATIVO IMOBILIZADO
    *****************************************************************************/
    PROCEDURE P_DADOS_BAIXAATIVOIMOBILIZADO (
        CURSOR_DADOS     IN     SYS_REFCURSOR,
        PCODREGRA        IN     NUMBER,
        PCODPLANOCONTA   IN     NUMBER,
        RESULTADO           OUT VARCHAR2)
    IS
        TYPE CONSULTA_RECEBIMENTOS IS RECORD
        (
            CODIGOBEM PCBENSPATRIMONIAIS.CODPROD%TYPE,
            NUMEROSEQUENCIA PCBENSPATRIMONIAIS.SEQUENCIA%TYPE,
            VALORBEM PCDEPRECIACAO.VALORBEM%TYPE,
            VALORADEPRECBEM PCBENSPATRIMONIAIS.VLRADEPRECBEM%TYPE,
            VALORBEMRESIDUAL PCBENSPATRIMONIAIS.VLRBEMRESIDUAL%TYPE,
            VALORDEPRECACUMULADA PCDEPRECIACAO.VLRDEPRECACUMULADA%TYPE,
            VALORATUALBEM PCBENSPATRIMONIAIS.VLRATUALBEM%TYPE,
            CODFILIAL PCBENSPATRIMONIAIS.CODFILIAL%TYPE,
            NUMERONOTA PCBENSPATRIMONIAIS.NUMNOTA%TYPE,
            ROTINABAIXA VARCHAR2 (4),
            DATABAIXA PCBENSPATRIMONIAIS.DATABAIXA%TYPE,
            TIPOBAIXA PCBENSPATRIMONIAIS.TIPOBAIXA%TYPE,
            DESCTIPOBAIXA VARCHAR2 (20),
            TIPOTRANSACAO PCBENSPATRIMONIAIS.TIPOTRANSACAO%TYPE,
            DESCTIPOTRANSACAO VARCHAR2 (20),
            NUMTRANSVENDA PCBENSPATRIMONIAIS.NUMTRANSVENDA%TYPE,
            CODIGOGRUPOBEM PCBENSGRUPO.CODGRUPO%TYPE,
            DESCGRUPO PCBENSGRUPO.DESCGRUPO%TYPE,
            CODCONTAATIVO PCBENSGRUPO.CONTAATIVO%TYPE,
            CODCONTADEPRECIACAO PCBENSGRUPO.CONTADEPRECIACAO%TYPE,
            TEMINTEGRACAO VARCHAR2 (1)
        );

        ITEM                     CONSULTA_RECEBIMENTOS;
        ITENSREGRA               CONSULTA_ITENS;

        CURSOR_ITENS             SYS_REFCURSOR;

        FILIAIS_LANCADAS         TABELAFILIAISLANCTO;
        FILIAIS                  FILIAISLANCTO;
        VB_ECONTA_PREDEFINIDA    BOOLEAN;

        --VALORES_POSSIVEIS_CENTROCUSTO TABELAVALORES_CENTROCUSTO;
        --VALOR_CENTROCUSTO             VALORES_CENTROCUSTO;

        TYPE RECORD_CODREDUZIDO_NUMTRANSCC IS RECORD
        (
            CODREDUZIDO_PC PCLANCINTERMEDIARIA.CODREDUZIDO_PC%TYPE,
            NUMTRANSCC PCLANCINTERMEDIARIA.NUMTRANSCENTROCUSTO%TYPE
        );

        TYPE TABELA_CODREDUZIDO_NUMTRANSCC
            IS TABLE OF RECORD_CODREDUZIDO_NUMTRANSCC;

        CODREDUZIDO_NUMTRANSCC   TABELA_CODREDUZIDO_NUMTRANSCC;
        --CODREDUZIDO_NUMTRANSCC_ITEM RECORD_CODREDUZIDO_NUMTRANSCC;

        VS_CONTA_EXISTE          VARCHAR2 (1);
    BEGIN
        LISTA_FORMULAS := TYPE_LISTA_FORMULAS ();

        FILIAIS_LANCADAS := TABELAFILIAISLANCTO ();

        VS_SEQGERADO := 'N';
        VS_FORMADTCONTABILIZACAO := '';
        VN_NUMTRANSACAO := 0;
        VS_DOCUMENTO := '';
        --VB_ECONTA_PREDEFINIDA    := FALSE;
        VS_TEMCONTAINEXISTENTE := 'N';

        --BUSCA DADOS DA REGRA
        SELECT FORMADTCONTABILIZACAO, BUSCARDADOSPELADATA
          INTO VS_FORMADTCONTABILIZACAO, VS_BUSCARDADOSPELADATA
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        V_SQLERRO := 'ABRINDO BAIXA DE ATIVO IMOBILIZADO';

        --INICIA LAÇO DOS DADOS
        LOOP
            FETCH CURSOR_DADOS INTO ITEM;

            EXIT WHEN CURSOR_DADOS%NOTFOUND;

            IF    (ITEM.TEMINTEGRACAO IS NULL)
               OR (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                   AND (ITEM.TEMINTEGRACAO = 'P'))
            THEN
                --------------------------------------------------------------------
                --VERIFICA SE ALTEROU O NUMTRANSOPERACAO PARA FAZER GRAVAÇÃO E RE-INICIAR VARIÁVEIS
                IF    (VN_NUMTRANSOPERACAO <> ITEM.NUMEROSEQUENCIA)
                   OR (    (VN_NUMTRANSOPERACAO = ITEM.NUMEROSEQUENCIA)
                       AND (VD_DATALANCTO <> ITEM.DATABAIXA))
                THEN
                    VS_SEQGERADO := 'N';

                    IF (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                        AND (ITEM.TEMINTEGRACAO = 'P'))
                    THEN
                        P_EXCLUI_LANCINTERMEDIARIA_IND (PCODREGRA,
                                                        ITEM.NUMEROSEQUENCIA,
                                                        ITEM.DATABAIXA);
                    END IF;

                    --VERIFICA SE JÁ PASSOU POR ALGUM REGISTRO PARA ATRIBUIR INCONSISTÊNCIAS
                    IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) >
                       0
                    THEN
                        ---------------------------------------------------------------------------------
                        V_SQLERRO :=
                            '15 - BAIXA DE ATIVO IMOBILIZADO: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
                        ---------------------------------------------------------------------------------
                        P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                                    VD_DATALANCTO,
                                                    VS_TEMCONTAINEXISTENTE,
                                                    VN_TOTALDEBITO,
                                                    VN_TOTALCREDITO,
                                                    'N');
                    END IF;

                    VS_TEMCONTAINEXISTENTE := 'N';
                END IF;

                --------------------------------------------------------------------

                --GERA NOVO NUMTRANSLANCTO
                IF VS_SEQGERADO = 'N'
                THEN
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '15 - BAIXA DE ATIVO IMOBILIZADO: EXECUTANDO FUNÇÃO GERA_NUM_TRANS_LANCTO()';
                    ---------------------------------------------------------------------------------
                    VN_NUMTRANSACAO := F_GERA_NUM_TRANS_LANCTO ();
                    VS_NUMTRANSCENTROCUSTO := '';

                    VN_NUMSEQ := 0;
                    VN_TOTALCREDITO := 0;
                    VN_TOTALDEBITO := 0;
                    VS_SEQGERADO := 'S';

                    CONTASDEBLANCTO := CONTAS_LANCADAS ();
                    CONTASCRELANCTO := CONTAS_LANCADAS ();
                    CGCSLANCTO := CGC_LANCADOS ();
                    VS_LISTAS_TRANSOTORIAS := CONTAS_LANCADAS ();

                    CONTASDEBLANCTO.EXTEND;
                    CONTASCRELANCTO.EXTEND;
                    CODREDUZIDO_NUMTRANSCC :=
                        TABELA_CODREDUZIDO_NUMTRANSCC ();
                END IF;

                VD_DATALANCTO := ITEM.DATABAIXA;

                --LAÇO NOS ITENS DA REGRA CONTABIL
                OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL ()
                    USING PCODREGRA;

                LOOP
                    FETCH CURSOR_ITENS INTO ITENSREGRA;

                    EXIT WHEN CURSOR_ITENS%NOTFOUND;

                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '15 - BAIXA DE ATIVO IMOBILIZADO: ATRIBUINDO VALOR DO DOCUMENTO';
                    ---------------------------------------------------------------------------------
                    VS_DOCUMENTO := ITENSREGRA.DOCUMENTO;
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATABAIXA',
                                 TO_CHAR (ITEM.DATABAIXA, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'CODIGOBEM', ITEM.CODIGOBEM);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMEROSEQUENCIA',
                                 ITEM.NUMEROSEQUENCIA);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMERONOTA', ITEM.NUMERONOTA);

                    --FORMULA INFORMADA NO FILTRO--------------------------------------------------------
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '15 - BAIXA DE ATIVO IMOBILIZADO: ATRIBUINDO VALOR DA FÓRMULA';
                    ---------------------------------------------------------------------------------
                    VN_VALORLANCTO := 0;

                    VS_FORMULA := ITENSREGRA.FORMULAS || ' + 0 ';
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORBEM([^_[:alnum:]])',
                                        NVL (ITEM.VALORBEM, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORADEPRECBEM([^_[:alnum:]])',
                            NVL (ITEM.VALORADEPRECBEM, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORBEMRESIDUAL([^_[:alnum:]])',
                            NVL (ITEM.VALORBEMRESIDUAL, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORDEPRECACUMULADA([^_[:alnum:]])',
                            NVL (ITEM.VALORDEPRECACUMULADA, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORATUALBEM([^_[:alnum:]])',
                                        NVL (ITEM.VALORATUALBEM, 0) || '\1');

                    CALCULAREXPRESSAO;

                    --FIM DA FÓRMULA---------------------------------------------------------------------

                    IF VN_VALORLANCTO <> 0
                    THEN
                        VS_CONTA := TRIM (ITENSREGRA.CODREDUZIDO_PC);
                        VS_CODFILIAL :=
                            CASE
                                WHEN ITENSREGRA.CODFILIAL =
                                     'FILIALLANCAMENTO'
                                THEN
                                    ITEM.CODFILIAL
                                ELSE
                                    ITENSREGRA.CODFILIAL
                            END;

                        VB_ECONTA_PREDEFINIDA := FALSE;

                        IF     (SUBSTR (VS_CONTA, 1, 1) <> '0')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '1')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '2')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '3')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '4')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '5')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '6')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '7')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '8')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '9')
                        THEN
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTAATIVO',
                                         ITEM.CODCONTAATIVO);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTADEPRECIACAO',
                                         ITEM.CODCONTADEPRECIACAO);
                            VB_ECONTA_PREDEFINIDA := TRUE;
                        END IF;

                        VS_CONTA_EXISTE :=
                            F_VERIFICA_CONTA_EXISTE (VS_CONTA,
                                                     PCODPLANOCONTA);
                        TRATAR_CONTA_INEXISTENTE (VS_CONTA_EXISTE,
                                                  VS_TEMCONTAINEXISTENTE);

                        IF VS_CONTA_EXISTE IN ('S', 'I', 'X')
                        THEN
                            --            IF F_VERIFICA_CONTA_EXISTE(VS_CONTA, PCODPLANOCONTA) = 'S' THEN
                            --HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO---------------------------------------
                            ---------------------------------------------------------------------------------
                            V_SQLERRO :=
                                '15 - BAIXA DE ATIVO IMOBILIZADO: ATRIBUINDO VALOR DE HISTÓRICOS';
                            ---------------------------------------------------------------------------------
                            VS_HISTORICO := ITENSREGRA.HISTCOMPLREGRA;
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODIGOBEM]',
                                         ITEM.CODIGOBEM);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMEROSEQUENCIA]',
                                         ITEM.NUMEROSEQUENCIA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMERONOTA]',
                                         ITEM.NUMERONOTA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATABAIXA]',
                                         ITEM.DATABAIXA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[TIPOBAIXA]',
                                         ITEM.TIPOBAIXA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[TIPOTRANSACAO]',
                                         ITEM.TIPOTRANSACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMTRANSVENDA]',
                                         ITEM.NUMTRANSVENDA);

                            VS_HISTORICO := SUBSTR (VS_HISTORICO, 1, 200);

                            --FIM HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO-----------------------------------

                            IF ITENSREGRA.NATUREZA = 'C'
                            THEN
                                IF VN_VALORLANCTO < 0
                                THEN
                                    VS_NATUREZA := 'D';
                                ELSE
                                    VS_NATUREZA := 'C';
                                END IF;
                            ELSE
                                IF VN_VALORLANCTO < 0
                                THEN
                                    VS_NATUREZA := 'C';
                                ELSE
                                    VS_NATUREZA := 'D';
                                END IF;
                            END IF;

                            IF VS_NATUREZA = 'C'
                            THEN
                                VN_TOTALCREDITO :=
                                    ROUND (
                                          VN_TOTALCREDITO
                                        + ABS (VN_VALORLANCTO),
                                        2);
                            ELSE
                                VN_TOTALDEBITO :=
                                    ROUND (
                                        VN_TOTALDEBITO + ABS (VN_VALORLANCTO),
                                        2);
                            END IF;

                            --GUARDA FILIAIS
                            FILIAIS.CODFILIAL := '-1';

                            FOR VN_POSICAO IN 1 .. FILIAIS_LANCADAS.COUNT
                            LOOP
                                IF (FILIAIS_LANCADAS (VN_POSICAO).CODFILIAL =
                                    VS_CODFILIAL)
                                THEN
                                    FILIAIS := FILIAIS_LANCADAS (VN_POSICAO);
                                    VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

                                    EXIT;
                                END IF;
                            END LOOP;

                            IF (FILIAIS.CODFILIAL = '-1')
                            THEN
                                FILIAIS_LANCADAS.EXTEND;

                                FILIAIS :=
                                    FILIAIS_LANCADAS (FILIAIS_LANCADAS.COUNT);
                                VN_POSICAO_EM_ALTERACAO :=
                                    FILIAIS_LANCADAS.COUNT;

                                FILIAIS.CODFILIAL := VS_CODFILIAL;
                                FILIAIS.CGCFILIAL :=
                                    F_CGCFILIAL (VS_CODFILIAL);

                                FILIAIS_LANCADAS (VN_POSICAO_EM_ALTERACAO) :=
                                    FILIAIS;
                            END IF;

                            --GUARDA AS CONTAS PARA VERIFICAR SE ESTÃO IGUAIS POSTERIORMENTE
                            P_ARMAZENA_CONTAS_FILIAIS_LANC (VS_CONTA,
                                                            VS_NATUREZA,
                                                            VS_CODFILIAL,
                                                            FILIAIS_LANCADAS);

                            IF 'N' = 'S'
                            THEN
                                NULL;
                            ELSE
                                ---------------------------------------------------------------------------------
                                V_SQLERRO :=
                                    '15 - BAIXA DE ATIVO IMOBILIZADO: EXECUTANDO PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA()';
                                ---------------------------------------------------------------------------------

                                --INSERE DADOS NA TABELA QUANDO NÃO ESTÁ TOTALIZANDO VALORES
                                VN_NUMSEQ := VN_NUMSEQ + 1;

                                P_GRAVA_DADOS_TABINTERMEDIARIA (
                                    VS_CODFILIAL,
                                    VN_NUMTRANSACAO,
                                    VN_NUMSEQ,
                                    VD_DATALANCTO,
                                    VS_DOCUMENTO,
                                    ITENSREGRA.CODHISTORICO,
                                    VS_HISTORICO,
                                    PCODPLANOCONTA,
                                    VS_CONTA,
                                    VS_NATUREZA,
                                    ABS (VN_VALORLANCTO),
                                    PCODREGRA,
                                    '',
                                    ITEM.NUMEROSEQUENCIA,
                                    F_RETORNA_TIPO_INCONSISTENCIA (
                                        VS_TEMCONTAINEXISTENTE),
                                    'P',
                                    ITEM.DATABAIXA,
                                    0,
                                    0,
                                    '',
                                    VS_NUMTRANSCENTROCUSTO,
                                    TRUNC (SYSDATE),
                                    0,
                                    '',
                                    ITEM.CODIGOGRUPOBEM,
                                    ITEM.CODIGOBEM,
                                    ITEM.NUMEROSEQUENCIA,
                                    ITENSREGRA.FORMULAS,
                                    ITENSREGRA.CODREDUZIDO_PC,
                                    'IMOBILIZADO',
                                    'PCMOVCIAP',
                                    ITENSREGRA.TOTALIZAVALOR);
                                VS_NUMTRANSCENTROCUSTO := NULL;
                            END IF;
                        END IF;
                    END IF;
                END LOOP;

                --GUARDA O NÚMERO DA TRANSAÇÃO
                VN_NUMTRANSOPERACAO := ITEM.NUMEROSEQUENCIA;
            ELSE
                VN_NUMTRANSOPERACAO := ITEM.NUMEROSEQUENCIA;
            END IF;
        END LOOP;

        --VERIFICA CONSISTÊNCIAS DO ÚLTIMO REGISTRO
        IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '15 - BAIXA DE ATIVO IMOBILIZADO: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
            ---------------------------------------------------------------------------------
            P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                        VD_DATALANCTO,
                                        VS_TEMCONTAINEXISTENTE,
                                        VN_TOTALDEBITO,
                                        VN_TOTALCREDITO,
                                        'N');
        END IF;

        CLOSE CURSOR_DADOS;

        RESULTADO := 'OK';
    EXCEPTION
        WHEN OTHERS
        THEN
            RESULTADO :=
                   'Ocorreu um erro quando: '
                || V_SQLERRO
                || CHR (13)
                || 'Erro Original: '
                || SQLERRM;
    END;


    /****************************************************************************
      PROCEDURE PARA GERAÇÃO DE 16 - BAIXA DE CRÉDITOS COM TITULOS
    *****************************************************************************/
    PROCEDURE P_DADOS_BAIXAATITULOSCRED (CURSOR_DADOS     IN     SYS_REFCURSOR,
                                         PCODREGRA        IN     NUMBER,
                                         PCODPLANOCONTA   IN     NUMBER,
                                         RESULTADO           OUT VARCHAR2)
    IS
        TYPE CONSULTA_BAIXACREDITOS IS RECORD
        (
            TABELA VARCHAR2 (8),
            CODCLIENTE PCCLIENT.CODCLI%TYPE,
            CODFILIAL PCFILIAL.CODIGO%TYPE,
            DATAOPERACAO DATE,
            DUPLICATA PCPREST.DUPLIC%TYPE,
            PRESTACAO PCPREST.PREST%TYPE,
            CLIENTE PCCLIENT.CLIENTE%TYPE,
            VALORTITULO PCPREST.VALOR%TYPE,
            VALORDESCONTO PCPREST.VALORDESC%TYPE,
            VALORJUROS PCPREST.TXPERM%TYPE,
            VALORPAGO PCPREST.VPAGO%TYPE,
            VALORCREDITO PCCRECLI.VALOR%TYPE,
            NUMTRANSOPERACAO PCCRECLI.NUMCRED%TYPE,
            CODCONTACONTABIL PCMODELOPC.CODREDUZIDO_PC%TYPE,
            TEMINTEGRACAO PCLANCINTERMEDIARIA.STATUS%TYPE,
            ROTINABAIXA PCCRECLI.ROTINABAIXA%TYPE,
            DTLANCOCREDITO DATE,
            CODIGOCREDITO PCCRECLI.CODIGO%TYPE,
            HISTORICOCREDITO PCCRECLI.HISTORICO%TYPE,
            NUMEROCREDITO PCCRECLI.NUMCRED%TYPE,
            ROTINALANCCREDITO PCCRECLI.CODROTINA%TYPE
        );

        ITEM               CONSULTA_BAIXACREDITOS;
        ITENSREGRA         CONSULTA_ITENS;

        CURSOR_ITENS       SYS_REFCURSOR;

        FILIAIS_LANCADAS   TABELAFILIAISLANCTO;
        FILIAIS            FILIAISLANCTO;
        VS_CONTA_EXISTE    VARCHAR2 (1);
    BEGIN
        LISTA_FORMULAS := TYPE_LISTA_FORMULAS ();
        FILIAIS_LANCADAS := TABELAFILIAISLANCTO ();

        VS_SEQGERADO := 'N';
        VS_FORMADTCONTABILIZACAO := '';
        VN_NUMTRANSACAO := 0;
        VS_DOCUMENTO := '';
        VS_TEMCONTAINEXISTENTE := 'N';

        --BUSCA DADOS DA REGRA
        SELECT FORMADTCONTABILIZACAO
          INTO VS_FORMADTCONTABILIZACAO
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        --INICIA LAÇO DOS DADOS
        LOOP
            FETCH CURSOR_DADOS INTO ITEM;

            EXIT WHEN CURSOR_DADOS%NOTFOUND;

            IF    (ITEM.TEMINTEGRACAO IS NULL)
               OR (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                   AND (ITEM.TEMINTEGRACAO = 'P'))
            THEN
                --------------------------------------------------------------------
                --VERIFICA SE ALTEROU O NUMTRANSOPERACAO PARA FAZER GRAVAÇÃO E RE-INICIAR VARIÁVEIS
                IF (VN_NUMTRANSOPERACAO <> ITEM.NUMTRANSOPERACAO)
                THEN
                    VS_SEQGERADO := 'N';

                    IF (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                        AND (ITEM.TEMINTEGRACAO = 'P'))
                    THEN
                        P_EXCLUI_LANCINTERMEDIARIA_IND (
                            PCODREGRA,
                            ITEM.NUMTRANSOPERACAO,
                            ITEM.DATAOPERACAO);
                    END IF;

                    --VERIFICA SE JÁ PASSOU POR ALGUM REGISTRO PARA ATRIBUIR INCONSISTÊNCIAS
                    IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) >
                       0
                    THEN
                        ---------------------------------------------------------------------------------
                        V_SQLERRO :=
                            '16 - BAIXA DE CREDITO COM TITULOS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
                        ---------------------------------------------------------------------------------
                        P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                                    VD_DATALANCTO,
                                                    VS_TEMCONTAINEXISTENTE,
                                                    VN_TOTALDEBITO,
                                                    VN_TOTALCREDITO,
                                                    'N');
                    END IF;

                    VS_TEMCONTAINEXISTENTE := 'N';
                END IF;

                --------------------------------------------------------------------

                --GERA NOVO NUMTRANSLANCTO
                IF VS_SEQGERADO = 'N'
                THEN
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '16 - BAIXA DE CREDITO COM TITULOS: EXECUTANDO FUNÇÃO GERA_NUM_TRANS_LANCTO()';
                    ---------------------------------------------------------------------------------
                    VN_NUMTRANSACAO := F_GERA_NUM_TRANS_LANCTO ();

                    VN_NUMSEQ := 0;
                    VN_TOTALCREDITO := 0;
                    VN_TOTALDEBITO := 0;
                    VS_SEQGERADO := 'S';

                    CONTASDEBLANCTO := CONTAS_LANCADAS ();
                    CONTASCRELANCTO := CONTAS_LANCADAS ();
                    CGCSLANCTO := CGC_LANCADOS ();
                    VS_LISTAS_TRANSOTORIAS := CONTAS_LANCADAS ();

                    CONTASDEBLANCTO.EXTEND;
                    CONTASCRELANCTO.EXTEND;
                END IF;

                VD_DATALANCTO :=
                    F_RETORNA_DATA_LANCPROVISOES (16,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO);

                VD_DATAINTEGRACAO :=
                    F_RETORNA_DATA_LANCPROVISOES (16,
                                                  PCODREGRA,
                                                  DATA_INTEGRACAO,
                                                  ITEM.DATAOPERACAO);

                --LAÇO NOS ITENS DA REGRA CONTABIL
                OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL ()
                    USING PCODREGRA;

                LOOP
                    FETCH CURSOR_ITENS INTO ITENSREGRA;

                    EXIT WHEN CURSOR_ITENS%NOTFOUND;

                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '16 - BAIXA DE CREDITO COM TITULOS: ATRIBUINDO VALOR DO DOCUMENTO';
                    ---------------------------------------------------------------------------------
                    VS_DOCUMENTO := ITENSREGRA.DOCUMENTO;
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO',
                                 TO_CHAR (ITEM.DATAOPERACAO, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'DUPLICATA', ITEM.DUPLICATA);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMEROCREDITO',
                                 ITEM.NUMEROCREDITO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMTRANSOPERACAO',
                                 ITEM.NUMTRANSOPERACAO);

                    --FORMULA INFORMADA NO FILTRO--------------------------------------------------------
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '16 - BAIXA DE CREDITO COM TITULOS: ATRIBUINDO VALOR DA FÓRMULA';
                    ---------------------------------------------------------------------------------
                    VN_VALORLANCTO := 0;

                    VS_FORMULA := ITENSREGRA.FORMULAS || ' + 0 ';
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORTITULO([^_[:alnum:]])',
                                        NVL (ITEM.VALORTITULO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORDESCONTO([^_[:alnum:]])',
                                        NVL (ITEM.VALORDESCONTO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORJUROS([^_[:alnum:]])',
                                        NVL (ITEM.VALORJUROS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORPAGO([^_[:alnum:]])',
                                        NVL (ITEM.VALORPAGO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORCREDITO([^_[:alnum:]])',
                                        NVL (ITEM.VALORCREDITO, 0) || '\1');

                    CALCULAREXPRESSAO;

                    --FIM DA FÓRMULA---------------------------------------------------------------------

                    IF VN_VALORLANCTO <> 0
                    THEN
                        VS_CONTA := TRIM (ITENSREGRA.CODREDUZIDO_PC);

                        IF     (SUBSTR (VS_CONTA, 1, 1) <> '0')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '1')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '2')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '3')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '4')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '5')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '6')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '7')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '8')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '9')
                        THEN
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTACONTABIL',
                                         ITEM.CODCONTACONTABIL);
                        END IF;


                        VS_CODFILIAL :=
                            CASE
                                WHEN ITENSREGRA.CODFILIAL =
                                     'FILIALLANCAMENTO'
                                THEN
                                    ITEM.CODFILIAL
                                ELSE
                                    ITENSREGRA.CODFILIAL
                            END;

                        VS_CONTA_EXISTE :=
                            F_VERIFICA_CONTA_EXISTE (VS_CONTA,
                                                     PCODPLANOCONTA);
                        TRATAR_CONTA_INEXISTENTE (VS_CONTA_EXISTE,
                                                  VS_TEMCONTAINEXISTENTE);

                        IF VS_CONTA_EXISTE IN ('S', 'I', 'X')
                        THEN
                            --HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO---------------------------------------
                            ---------------------------------------------------------------------------------
                            V_SQLERRO :=
                                '16 - BAIXA DE CREDITO COM TITULOS: ATRIBUINDO VALOR DE HISTÓRICOS';
                            ---------------------------------------------------------------------------------
                            VS_HISTORICO := ITENSREGRA.HISTCOMPLREGRA;
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODCLIENTE]',
                                         ITEM.CODCLIENTE);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO]',
                                         ITEM.DATAOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DUPLICATA]',
                                         ITEM.DUPLICATA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[PRESTACAO]',
                                         ITEM.PRESTACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CLIENTE]',
                                         ITEM.CLIENTE);

                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DTLANCOCREDITO]',
                                         ITEM.DTLANCOCREDITO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODIGOCREDITO]',
                                         ITEM.CODIGOCREDITO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[HISTORICOCREDITO]',
                                         ITEM.HISTORICOCREDITO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMEROCREDITO]',
                                         ITEM.NUMEROCREDITO);

                            VS_HISTORICO := SUBSTR (VS_HISTORICO, 1, 200);

                            --FIM HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO-----------------------------------

                            IF ITENSREGRA.NATUREZA = 'C'
                            THEN
                                IF VN_VALORLANCTO < 0
                                THEN
                                    VS_NATUREZA := 'D';
                                ELSE
                                    VS_NATUREZA := 'C';
                                END IF;
                            ELSE
                                IF VN_VALORLANCTO < 0
                                THEN
                                    VS_NATUREZA := 'C';
                                ELSE
                                    VS_NATUREZA := 'D';
                                END IF;
                            END IF;

                            IF VS_NATUREZA = 'C'
                            THEN
                                VN_TOTALCREDITO :=
                                    ROUND (
                                          VN_TOTALCREDITO
                                        + ABS (VN_VALORLANCTO),
                                        2);
                            ELSE
                                VN_TOTALDEBITO :=
                                    ROUND (
                                        VN_TOTALDEBITO + ABS (VN_VALORLANCTO),
                                        2);
                            END IF;

                            --GUARDA FILIAIS
                            FILIAIS.CODFILIAL := '-1';

                            FOR VN_POSICAO IN 1 .. FILIAIS_LANCADAS.COUNT
                            LOOP
                                IF (FILIAIS_LANCADAS (VN_POSICAO).CODFILIAL =
                                    VS_CODFILIAL)
                                THEN
                                    FILIAIS := FILIAIS_LANCADAS (VN_POSICAO);
                                    VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

                                    EXIT;
                                END IF;
                            END LOOP;

                            IF (FILIAIS.CODFILIAL = '-1')
                            THEN
                                FILIAIS_LANCADAS.EXTEND;

                                FILIAIS :=
                                    FILIAIS_LANCADAS (FILIAIS_LANCADAS.COUNT);
                                VN_POSICAO_EM_ALTERACAO :=
                                    FILIAIS_LANCADAS.COUNT;

                                FILIAIS.CODFILIAL := VS_CODFILIAL;
                                FILIAIS.CGCFILIAL :=
                                    F_CGCFILIAL (VS_CODFILIAL);

                                FILIAIS_LANCADAS (VN_POSICAO_EM_ALTERACAO) :=
                                    FILIAIS;
                            END IF;

                            --GUARDA AS CONTAS PARA VERIFICAR SE ESTÃO IGUAIS POSTERIORMENTE
                            P_ARMAZENA_CONTAS_FILIAIS_LANC (VS_CONTA,
                                                            VS_NATUREZA,
                                                            VS_CODFILIAL,
                                                            FILIAIS_LANCADAS);

                            IF 'N' = 'S'
                            THEN
                                NULL;
                            ELSE
                                ---------------------------------------------------------------------------------
                                V_SQLERRO :=
                                    '16 - BAIXA DE CREDITO COM TITULOS: EXECUTANDO PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA()';
                                ---------------------------------------------------------------------------------
                                --INSERE DADOS NA TABELA QUANDO NÃO ESTÁ TOTALIZANDO VALORES
                                VN_NUMSEQ := VN_NUMSEQ + 1;

                                P_GRAVA_DADOS_TABINTERMEDIARIA (
                                    VS_CODFILIAL,
                                    VN_NUMTRANSACAO,
                                    VN_NUMSEQ,
                                    VD_DATALANCTO,
                                    VS_DOCUMENTO,
                                    ITENSREGRA.CODHISTORICO,
                                    VS_HISTORICO,
                                    PCODPLANOCONTA,
                                    VS_CONTA,
                                    VS_NATUREZA,
                                    ABS (VN_VALORLANCTO),
                                    PCODREGRA,
                                    '',
                                    ITEM.NUMTRANSOPERACAO,
                                    F_RETORNA_TIPO_INCONSISTENCIA (
                                        VS_TEMCONTAINEXISTENTE),
                                    'P',
                                    ITEM.DATAOPERACAO,
                                    0,
                                    0,
                                    '',
                                    '',
                                    VD_DATAINTEGRACAO,
                                    0,
                                    '',
                                    NULL,
                                    ITEM.NUMTRANSOPERACAO,
                                    '',
                                    ITENSREGRA.FORMULAS,
                                    ITENSREGRA.CODREDUZIDO_PC,
                                    'BAIXACREDITO',
                                    'PCCRECLI',
                                    ITENSREGRA.TOTALIZAVALOR);
                            END IF;
                        END IF;
                    END IF;
                END LOOP;

                --GUARDA O NÚMERO DA TRANSAÇÃO
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            ELSE
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            END IF;
        END LOOP;

        --VERIFICA CONSISTÊNCIAS DO ÚLTIMO REGISTRO
        IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '16 - BAIXA DE CREDITO COM TITULOS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
            ---------------------------------------------------------------------------------
            P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                        VD_DATALANCTO,
                                        VS_TEMCONTAINEXISTENTE,
                                        VN_TOTALDEBITO,
                                        VN_TOTALCREDITO,
                                        'N');
        END IF;

        CLOSE CURSOR_DADOS;


        RESULTADO := 'OK';
    EXCEPTION
        WHEN OTHERS
        THEN
            RESULTADO :=
                   'Ocorreu um erro quando: '
                || V_SQLERRO
                || CHR (13)
                || 'Erro Original: '
                || SQLERRM;
    END;


    FUNCTION F_RETORNA_FILTROS_REGRA (PCODREGRA          IN     NUMBER,
                                      V_FILTROCODMOEDA      OUT VARCHAR2)
        RETURN CLOB
    IS
        -- PRAGMA AUTONOMOUS_TRANSACTION;
        V_FILTROS                  CLOB;
        RESULTADO                  CLOB;
        LINHA                      CLOB;
        V_CODFATOGERADOR           NUMBER;
        CR_LINHAS                  SYS_REFCURSOR;
        VS_CONTABILIZAESTORNO      VARCHAR2 (1);
        VS_BUSCARDADOSPELADATA     VARCHAR2 (1);
        VS_FORMADTCONTABILIZACAO   VARCHAR2 (1);
        VS_BUSCAPORFILIALNF        VARCHAR2 (1);
    --PESQUISA_FILIAIS SYS_REFCURSOR;

    BEGIN
        SELECT FILTROS,
               CODFATOGERADOR,
               NVL (CONTABILIZAESTORNO, 'N') CONTABILIZAESTORNO,
               BUSCARDADOSPELADATA,
               FORMADTCONTABILIZACAO,
               BUSCAPORFILIALNF
          INTO V_FILTROS,
               V_CODFATOGERADOR,
               VS_CONTABILIZAESTORNO,
               VS_BUSCARDADOSPELADATA,
               VS_FORMADTCONTABILIZACAO,
               VS_BUSCAPORFILIALNF
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;



        V_FILTROS :=
            REPLACE (REPLACE (V_FILTROS, '''', ''''''),
                     CHR (13) || CHR (10),
                     ''' LINHA FROM DUAL UNION SELECT ''');
        V_FILTROS :=
            REPLACE (V_FILTROS,
                     CHR (13),
                     ''' LINHA FROM DUAL UNION SELECT ''');
        V_FILTROS :=
            REPLACE (V_FILTROS,
                     CHR (10),
                     ''' LINHA FROM DUAL UNION SELECT ''');

        RESULTADO := NULL;

        OPEN CR_LINHAS FOR
               'SELECT LINHA FROM (SELECT '''
            || DBMS_LOB.SUBSTR (V_FILTROS)
            || ''' LINHA FROM DUAL) WHERE LINHA IS NOT NULL';

        LOOP
            FETCH CR_LINHAS INTO LINHA;

            EXIT WHEN CR_LINHAS%NOTFOUND;

            -- As duas linhas abaixo (IS NULL e IS NOT NULL), foi para atender uma solicitação de filtro para data de cancelamento de nota, para, caso o cliente queira retirar os registros que tiveram a nota cancelada, ou vice versa, ser adicionado como filtro.
            LINHA :=
                REPLACE (UPPER (LINHA),
                         'NAO CONTIDO (''VAZIO'')',
                         'IS NOT NULL');
            LINHA :=
                REPLACE (UPPER (LINHA), 'CONTIDO (''VAZIO'')', 'IS NULL');

            LINHA := REPLACE (UPPER (LINHA), 'NAO CONTIDO', 'NOT IN');
            LINHA := REPLACE (UPPER (LINHA), 'CONTIDO', 'IN');
            LINHA := REPLACE (UPPER (LINHA), 'MENOR QUE', '<');
            LINHA := REPLACE (UPPER (LINHA), 'MAIOR QUE', '>');

            IF INSTR (UPPER (LINHA), 'NOT IN') > 0
            THEN
                LINHA :=
                       'NVL('
                    || SUBSTR (LINHA, 1, INSTR (UPPER (LINHA), 'NOT IN') - 2)
                    || ', ''0'') NOT IN '
                    || SUBSTR (LINHA, INSTR (UPPER (LINHA), 'NOT IN') + 7);
            END IF;

            IF V_CODFATOGERADOR = 8
            THEN
                LINHA :=
                    REPLACE (UPPER (LINHA), 'TIPOMOVIMENTACAO', 'M.TIPO');
                LINHA :=
                    REPLACE (UPPER (LINHA),
                             'DATACANCELADASAIDA',
                             'NS.DTCANCEL');
                LINHA :=
                    REPLACE (UPPER (LINHA),
                             'DATACANCELADAENTRADA',
                             'NE.DTCANCEL');
                LINHA := REPLACE (UPPER (LINHA), 'ESPECIENF', 'M.ESPECIE');
                LINHA := REPLACE (UPPER (LINHA), 'CODPRODUTO', 'M.CODPROD');
                LINHA :=
                    REPLACE (UPPER (LINHA), 'CODDEPARTAMENTO', 'M.CODEPTO');
                LINHA := REPLACE (UPPER (LINHA), 'CODSECAO', 'M.CODSEC');
                LINHA := REPLACE (UPPER (LINHA), 'TIPOUNIDADE', 'M.UNIDADE');
                LINHA := REPLACE (UPPER (LINHA), 'TIPOOPERACAO', 'M.CODOPER');
                LINHA :=
                    REPLACE (UPPER (LINHA), 'CODFISCALNF', 'M.CODFISCAL');
                LINHA :=
                    REPLACE (UPPER (LINHA), 'TIPODESCARGA', 'M.TIPODESCARGA');
                LINHA :=
                    REPLACE (UPPER (LINHA),
                             'SITUACAOTRIBUTARIA',
                             'M.SITUACAOTRIBUTARIA');
            ELSIF V_CODFATOGERADOR = 7
            THEN
                IF INSTR (LINHA, 'CODMOEDA') > 0
                THEN
                    V_FILTROCODMOEDA := ' AND ' || LINHA;
                END IF;
            END IF;



            RESULTADO :=
                RESULTADO || CHR (13) || CHR (10) || ' AND ' || LINHA;
        END LOOP;

        RETURN RESULTADO;
    END;

    FUNCTION F_PREPARA_SQL_FATO_PELA_REGRA (PCODREGRA    IN NUMBER,
                                            PCODFILIAL   IN VARCHAR2)
        RETURN CLOB
    IS
        -- PRAGMA AUTONOMOUS_TRANSACTION;
        V_SQLFATO                     CLOB;
        V_CODFATOGERADOR              NUMBER;
        VS_CONTABILIZAESTORNO         VARCHAR2 (1);
        VS_DESCLANCESTORNO            VARCHAR2 (1);
        VS_BUSCARDADOSPELADATA        VARCHAR2 (1);
        VN_USAFILIALFIXA              NUMBER (5);
        VS_BUSCAPORFILIALNF           VARCHAR2 (1);
        VS_BAIXA_ADIANT_FOR_MOV_NUM   VARCHAR2 (1);

        VN_TOTALIZAVALOR              NUMBER;

        --PESQUISA_FILIAIS SYS_REFCURSOR;
        LISTA_FILIAIS                 VARCHAR2 (200);
        VIRGULA                       VARCHAR2 (1);
    BEGIN
        SELECT CODFATOGERADOR,
               NVL (CONTABILIZAESTORNO, 'N') CONTABILIZAESTORNO,
               BUSCARDADOSPELADATA,
               FORMADTCONTABILIZACAO,
               BUSCAPORFILIALNF,
               NVL (BAIXA_ADIANTFOR_MOV_NUMERARIO, 'N'),
               NVL (DESCLANCESTORNO, 'N')    DESCLANCESTORNO
          INTO V_CODFATOGERADOR,
               VS_CONTABILIZAESTORNO,
               VS_BUSCARDADOSPELADATA,
               VS_FORMADTCONTABILIZACAO,
               VS_BUSCAPORFILIALNF,
               VS_BAIXA_ADIANT_FOR_MOV_NUM,
               VS_DESCLANCESTORNO
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        SELECT COUNT (1)
          INTO VN_USAFILIALFIXA
          FROM PCITENSREGRACONTABIL I
         WHERE     CODREGRA = PCODREGRA
               AND TRIM (I.CODFILIALLANCTO) <> 'FILIALLANCAMENTO';

        --Verifica se contabiliza estorno para buscar SQL
        IF VS_CONTABILIZAESTORNO = 'N'
        THEN
            SELECT SQLFATOGERADOR
              INTO V_SQLFATO
              FROM PCFATOGERADOR
             WHERE CODFATOGERADOR = V_CODFATOGERADOR;
        ELSIF V_CODFATOGERADOR = 3
        THEN
            SELECT SQLFATOGERADOR
              INTO V_SQLFATO
              FROM PCFATOGERADOR
             WHERE CODFATOGERADOR = V_CODFATOGERADOR;

            V_SQLFATO :=
                REPLACE (V_SQLFATO,
                         'NVL(L.VALOR, 0)',
                         '(NVL(L.VALOR, 0) - NVL(L.VALORDEV, 0))');
            V_SQLFATO :=
                REPLACE (V_SQLFATO,
                         'AND L.DTESTORNOBAIXA IS NULL',
                         'AND L.DTESTORNOBAIXA IS NOT NULL');
            V_SQLFATO :=
                REPLACE (V_SQLFATO,
                         'AND L.CODFUNCESTORNOBAIXA IS NULL',
                         'AND L.CODFUNCESTORNOBAIXA IS NOT NULL');
            V_SQLFATO :=
                REPLACE (V_SQLFATO, '/*ROTINALANCVALE*/', '''614'',');
            V_SQLFATO := REPLACE (V_SQLFATO, '/*CONTABESTORNO*/', '--');
        ELSIF V_CODFATOGERADOR IN (16)
        THEN
            SELECT SQLFATOGERADOR
              INTO V_SQLFATO
              FROM PCFATOGERADOR
             WHERE CODFATOGERADOR = V_CODFATOGERADOR;

            V_SQLFATO :=
                REPLACE (V_SQLFATO,
                         'AND P.DTESTORNO IS NULL',
                         'AND P.DTESTORNO IS NOT NULL');
            V_SQLFATO :=
                REPLACE (V_SQLFATO,
                         'AND P.CODFUNCESTORNO IS NULL',
                         'AND P.CODFUNCESTORNO IS NOT NULL');
        ELSIF V_CODFATOGERADOR = 13
        THEN
            SELECT SQLFATOGERADOR
              INTO V_SQLFATO
              FROM PCFATOGERADOR
             WHERE CODFATOGERADOR = V_CODFATOGERADOR;

            V_SQLFATO :=
                REPLACE (V_SQLFATO,
                         'AND L.DTESTORNOBAIXA IS NULL',
                         'AND L.DTESTORNOBAIXA IS NOT NULL');
            V_SQLFATO :=
                REPLACE (V_SQLFATO,
                         'AND L.CODFUNCESTORNOBAIXA IS NULL',
                         'AND L.CODFUNCESTORNOBAIXA IS NOT NULL');
        END IF;

        IF V_CODFATOGERADOR IN (4, 10, 7)
        THEN
            IF VS_DESCLANCESTORNO = 'N'
            THEN
                V_SQLFATO := REPLACE (V_SQLFATO, '&MACROESTORNO&', ' ');
                V_SQLFATO := REPLACE (V_SQLFATO, '&MACROESTORNO2&', ' ');
            ELSIF V_CODFATOGERADOR = 7
            THEN
                SELECT SQLFATOGERADOR
                  INTO V_SQLFATO
                  FROM PCFATOGERADOR
                 WHERE CODFATOGERADOR = V_CODFATOGERADOR;

                V_SQLFATO :=
                    REPLACE (V_SQLFATO,
                             '&MACROESTORNO&',
                             ' AND NVL(M.ESTORNO,''N'') = ''N'' ');
            ELSE
                SELECT SQLFATOGERADOR
                  INTO V_SQLFATO
                  FROM PCFATOGERADOR
                 WHERE CODFATOGERADOR = V_CODFATOGERADOR;

                V_SQLFATO :=
                    REPLACE (
                        V_SQLFATO,
                        '&MACROESTORNO&',
                        ' AND (P.PERMITEESTORNO = ''S'' OR ((P.CODCOB <> ''ESTR'') AND P.PERMITEESTORNO IS NULL))  ');
                V_SQLFATO :=
                    REPLACE (
                        V_SQLFATO,
                        '&MACROESTORNO2&',
                        ' AND (P2.PERMITEESTORNO = ''S'' OR ((P2.CODCOB <> ''ESTR'') AND P2.PERMITEESTORNO IS NULL))  ');
            END IF;
        END IF;

        IF V_CODFATOGERADOR = 8
        THEN
            SELECT COUNT (1)
              INTO VN_TOTALIZAVALOR
              FROM PCITENSREGRACONTABIL T
             WHERE 1 = 1 AND CODREGRA = PCODREGRA AND TOTALIZAVALOR = 'S';

            SELECT R.AGRUPAMENTOREGRA
              INTO VS_FORMADTCONTABILIZACAO
              FROM PCREGRACONTABIL R
              WHERE R.CODFATOGERADOR = V_CODFATOGERADOR
              AND R.CODREGRA = PCODREGRA;

            IF (VN_TOTALIZAVALOR > 0) AND (VS_FORMADTCONTABILIZACAO <> 'I') 
            THEN
                SELECT SQLFATOGERADOR
                  INTO V_SQLFATO
                  FROM PCFATOGERADOR
                 WHERE CODFATOGERADOR = V_CODFATOGERADOR;

                V_SQLFATO := REPLACE (V_SQLFATO, 'M.CODPROD', '0');
                V_SQLFATO := REPLACE (V_SQLFATO, 'M.DESCRICAO', '0');
                V_SQLFATO := REPLACE (V_SQLFATO, 'M.CODEPTO', '0');
                V_SQLFATO := REPLACE (V_SQLFATO, 'M.CODSEC', '0');
                V_SQLFATO := REPLACE (V_SQLFATO, 'M.EMBALAGEM', '0');
                V_SQLFATO := REPLACE (V_SQLFATO, 'M.UNIDADE', '0');
                V_SQLFATO := REPLACE (V_SQLFATO, 'M.CODOPER', '0');
                V_SQLFATO := REPLACE (V_SQLFATO, 'M.CODFISCAL', '0');
                V_SQLFATO := REPLACE (V_SQLFATO, 'M.TIPODESCARGA', '0');
                V_SQLFATO := REPLACE (V_SQLFATO, 'M.SITUACAOTRIBUTARIA', '0');
                V_SQLFATO :=
                    REPLACE (V_SQLFATO,
                             'DECODE(SUBSTR(0, 1, 1)',
                             'DECODE(SUBSTR(M.CODOPER, 1, 1)');
            END IF;
        END IF;


        LISTA_FILIAIS := '';
        VIRGULA := '';

        FOR DADOS
            IN (SELECT DISTINCT CODFILIALLANCTO
                  FROM PCITENSREGRACONTABIL
                 WHERE     CODREGRA = PCODREGRA
                       AND CODFILIALLANCTO <> 'FILIALLANCAMENTO')
        LOOP
            LISTA_FILIAIS :=
                   LISTA_FILIAIS
                || VIRGULA
                || ''''
                || DADOS.CODFILIALLANCTO
                || '''';
            VIRGULA := ',';
        END LOOP;

        IF LISTA_FILIAIS IS NOT NULL
        THEN
            V_SQLFATO :=
                REPLACE (V_SQLFATO, '''LISTA_FILIAIS''', LISTA_FILIAIS);
        END IF;

        IF (V_CODFATOGERADOR IN (3, 13)) AND (VS_BUSCARDADOSPELADATA = 'C')
        THEN
            V_SQLFATO :=
                REPLACE (V_SQLFATO,
                         'L.DTPAGTO BETWEEN',
                         'R.DTCOMPENSACAO BETWEEN');
        ELSIF (V_CODFATOGERADOR = 3) AND (VS_BUSCARDADOSPELADATA = 'T')
        THEN
            V_SQLFATO :=
                REPLACE (V_SQLFATO,
                         'L.DTPAGTO BETWEEN',
                         'L.DTESTORNOBAIXA BETWEEN');
        ELSIF (V_CODFATOGERADOR = 4) AND (VS_BUSCARDADOSPELADATA = 'C')
        THEN
            V_SQLFATO :=
                REPLACE (V_SQLFATO,
                         'P.DTBAIXA BETWEEN',
                         'R.DTCOMPENSACAO BETWEEN');
            V_SQLFATO :=
                REPLACE (V_SQLFATO,
                         'R.DATA BETWEEN',
                         'R.DTCOMPENSACAO BETWEEN');
        ELSIF (V_CODFATOGERADOR = 4) AND (VS_BUSCARDADOSPELADATA = 'P')
        THEN
            V_SQLFATO :=
                REPLACE (V_SQLFATO, 'P.DTBAIXA BETWEEN', 'P.DTPAG BETWEEN');
            V_SQLFATO :=
                REPLACE (V_SQLFATO, 'R.DATA BETWEEN', 'P2.DTPAG BETWEEN');
        ELSIF (V_CODFATOGERADOR = 7) AND (VS_BUSCARDADOSPELADATA = 'C')
        THEN
            --V_SQLFATO := REPLACE(V_SQLFATO, 'M.DATA BETWEEN', 'M.DTCOMPENSACAO BETWEEN');
            V_SQLFATO :=
                REPLACE (V_SQLFATO,
                         'S.DATAOPERACAO BETWEEN',
                         'S.DATAOPERACAO1 BETWEEN');
        ELSIF (V_CODFATOGERADOR = 9) AND (VS_BUSCARDADOSPELADATA = 'C')
        THEN
            V_SQLFATO :=
                REPLACE (V_SQLFATO,
                         'A.DTLANC BETWEEN',
                         'A.DTCOMPETENCIA BETWEEN');
        ELSIF (V_CODFATOGERADOR = 9) AND (VS_BUSCARDADOSPELADATA = 'E')
        THEN
            V_SQLFATO :=
                REPLACE (V_SQLFATO,
                         'A.DTLANC BETWEEN',
                         'NVL(A.DTEMISSAO, A.DTLANC) BETWEEN');
        ELSIF (V_CODFATOGERADOR = 10) AND (VS_BUSCARDADOSPELADATA = 'C')
        THEN
            V_SQLFATO :=
                REPLACE (V_SQLFATO,
                         'P.DTBAIXA BETWEEN',
                         'R.DTCOMPENSACAO BETWEEN');
            V_SQLFATO :=
                REPLACE (V_SQLFATO,
                         'R.DATA BETWEEN',
                         'R.DTCOMPENSACAO BETWEEN');
        ELSIF V_CODFATOGERADOR = 11
        THEN
            IF VS_BUSCARDADOSPELADATA = 'E'
            THEN
                V_SQLFATO :=
                    REPLACE (V_SQLFATO,
                             'S.DTSAIDA BETWEEN',
                             'P.DTEMISSAO BETWEEN');
            ELSIF VS_BUSCARDADOSPELADATA = 'D'
            THEN
                V_SQLFATO :=
                    REPLACE (V_SQLFATO,
                             'S.DTSAIDA BETWEEN',
                             'P.DTDESD BETWEEN');
            END IF;
        ELSIF V_CODFATOGERADOR = 17
        THEN
            IF VS_BUSCARDADOSPELADATA = 'C'
            THEN
                V_SQLFATO :=
                    REPLACE (V_SQLFATO,
                             'A.DTLANC BETWEEN',
                             'M.DTCOMPENSACAO BETWEEN');
                V_SQLFATO :=
                    REPLACE (V_SQLFATO,
                             'B.DTLANC BETWEEN',
                             'L.DTCOMPETENCIA BETWEEN');
            END IF;
        ELSIF V_CODFATOGERADOR = 19
        THEN
            IF VS_BUSCARDADOSPELADATA = 'L'
            THEN
                V_SQLFATO :=
                    REPLACE (V_SQLFATO,
                             'PCLANC.DTCOMPETENCIA BETWEEN',
                             'PCLANC.DTLANC BETWEEN');                
            END IF;        
        END IF;

        IF (V_CODFATOGERADOR = 13) AND (VS_BAIXA_ADIANT_FOR_MOV_NUM = 'N') THEN
		   V_SQLFATO := REPLACE(V_SQLFATO, '--BAIXA_ADIANT_FORNEC_MOV_NUM', 'AND NOT EXISTS (SELECT 1 FROM PCCONSUM WHERE PCCONSUM.CODCONTAADIANTFOR = L.CODCONTA OR L.CODCONTA = CODCONTAADIANTFOROUTROS)');
		ELSE
		   V_SQLFATO := REPLACE(V_SQLFATO, '--BAIXA_ADIANT_FORNEC_MOV_NUM', 'AND EXISTS (SELECT 1 FROM PCCONSUM WHERE PCCONSUM.CODCONTAADIANTFOR = L.CODCONTA OR L.CODCONTA = CODCONTAADIANTFOROUTROS)');    
		END IF;

        IF V_CODFATOGERADOR IN (4, 10) AND VS_BUSCAPORFILIALNF = 'N'
        THEN
            V_SQLFATO :=
                REPLACE (V_SQLFATO,
                         'NVL(P.CODFILIALNF,P.CODFILIAL)',
                         'P.CODFILIAL');
           V_SQLFATO :=
                REPLACE (V_SQLFATO,
                         'NVL(P2.CODFILIALNF,P2.CODFILIAL)',
                         'P2.CODFILIAL');                         
        END IF;

        IF     (VN_USAFILIALFIXA > 0)
           AND (V_CODFATOGERADOR IN (3,
                                     4,
                                     10,
                                     9))
        THEN
            IF V_CODFATOGERADOR = 3
            THEN
                V_SQLFATO :=
                    REPLACE (V_SQLFATO,
                             'AND L2.CODFILIAL = L.CODFILIAL)',
                             ')');
            ELSIF V_CODFATOGERADOR = 4
            THEN
                V_SQLFATO :=
                    REPLACE (
                        V_SQLFATO,
                        'AND L2.CODFILIAL = NVL(P.CODFILIALNF,P.CODFILIAL))',
                        ')');
            ELSIF V_CODFATOGERADOR = 10
            THEN
                V_SQLFATO :=
                    REPLACE (
                        V_SQLFATO,
                        'AND L2.CODFILIAL = NVL(P.CODFILIALNF,P.CODFILIAL))',
                        ')');
            ELSIF V_CODFATOGERADOR = 9
            THEN
                V_SQLFATO :=
                    REPLACE (V_SQLFATO,
                             'AND LA.CODFILIAL = LI.CODFILIAL(+)',
                             '');
            ELSE
                V_SQLFATO :=
                    REPLACE (V_SQLFATO,
                             'AND L2.CODFILIAL = P.CODFILIAL)',
                             ')');
            END IF;
        END IF;

        RETURN V_SQLFATO;
    END;


    PROCEDURE P_DADOS_INCLUSAOCREDITOCLIENTE (
        CURSOR_DADOS     IN     SYS_REFCURSOR,
        PCODREGRA        IN     NUMBER,
        PCODPLANOCONTA   IN     NUMBER,
        RESULTADO           OUT VARCHAR2)
    IS
        TYPE CONSULTA_INCLUSAOCREDITOS IS RECORD
        (
            CODCLIENTE PCCLIENT.CODCLI%TYPE,
            CLIENTE PCCLIENT.CLIENTE%TYPE,
            CODROTINA PCCRECLI.CODROTINA%TYPE,
            DATAOPERACAO DATE,
            DATAOPERACAO1 DATE,
            CODBANCO PCBANCO.CODBANCO%TYPE,
            NUMEROCREDITO PCCRECLI.NUMCRED%TYPE,
            CODCONTA PCCONTA.CODCONTA%TYPE,
            CODCONTABANCO PCMODELOPC.CODREDUZIDO_PC%TYPE,
            CODCONTACLIENTE PCMODELOPC.CODREDUZIDO_PC%TYPE,
            CODCONTADESP PCMODELOPC.CODREDUZIDO_PC%TYPE,
            NUMNOTA PCCRECLI.NUMNOTA%TYPE,
            NUMTRANSOPERACAO PCCRECLI.CODIGO%TYPE,
            NUMTRANSVENDA PCCRECLI.NUMTRANSVENDA%TYPE,
            HISTORICOCREDITO PCCRECLI.HISTORICO%TYPE,
            VALORCREDITO PCCRECLI.VALOR%TYPE,
            DTLANCAMENTO PCCRECLI.DTLANC%TYPE,
            DTCOMPENSACAONUM PCCRECLI.DTLANC%TYPE,
            DTCOMPESACAOCONTA PCCRECLI.DTLANC%TYPE,
            NUMTRANS PCCRECLI.NUMTRANS%TYPE,
            TIPOCREDITO VARCHAR2 (50),
            CODFILIAL PCFILIAL.CODIGO%TYPE,
            TEMINTEGRACAO VARCHAR2 (2)
        );

        ITEM                     CONSULTA_INCLUSAOCREDITOS;
        ITENSREGRA               CONSULTA_ITENS;

        CURSOR_ITENS             SYS_REFCURSOR;

        FILIAIS_LANCADAS         TABELAFILIAISLANCTO;
        FILIAIS                  FILIAISLANCTO;
        VS_CONTA_EXISTE          VARCHAR2 (1);
        VS_BUSCARDADOSPELADATA   VARCHAR2 (1);
        VD_DATALANCTO_AUX        DATE;
    BEGIN
        LISTA_FORMULAS := TYPE_LISTA_FORMULAS ();

        FILIAIS_LANCADAS := TABELAFILIAISLANCTO ();

        VS_SEQGERADO := 'N';
        VS_FORMADTCONTABILIZACAO := '';
        VN_NUMTRANSACAO := 0;
        VS_DOCUMENTO := '';
        VS_TEMCONTAINEXISTENTE := 'N';

        --BUSCA DADOS DA REGRA
        SELECT FORMADTCONTABILIZACAO, BUSCARDADOSPELADATA
          INTO VS_FORMADTCONTABILIZACAO, VS_BUSCARDADOSPELADATA
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        --INICIA LAÇO DOS DADOS
        LOOP
            FETCH CURSOR_DADOS INTO ITEM;

            EXIT WHEN CURSOR_DADOS%NOTFOUND;

            IF    (ITEM.TEMINTEGRACAO IS NULL)
               OR (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                   AND (ITEM.TEMINTEGRACAO = 'P'))
            THEN
                IF VS_BUSCARDADOSPELADATA = 'L'
                THEN
                    VD_DATALANCTO_AUX := ITEM.DATAOPERACAO;
                ELSE
                    VD_DATALANCTO_AUX := ITEM.DATAOPERACAO1;
                END IF;

                --------------------------------------------------------------------
                --VERIFICA SE ALTEROU O NUMTRANSOPERACAO PARA FAZER GRAVAÇÃO E RE-INICIAR VARIÁVEIS
                IF (VN_NUMTRANSOPERACAO <> ITEM.NUMTRANSOPERACAO)
                THEN
                    VS_SEQGERADO := 'N';

                    IF (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                        AND (ITEM.TEMINTEGRACAO = 'P'))
                    THEN
                        P_EXCLUI_LANCINTERMEDIARIA_IND (
                            PCODREGRA,
                            ITEM.NUMTRANSOPERACAO,
                            VD_DATALANCTO_AUX);
                    END IF;

                    --VERIFICA SE JÁ PASSOU POR ALGUM REGISTRO PARA ATRIBUIR INCONSISTÊNCIAS
                    IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) >
                       0
                    THEN
                        ---------------------------------------------------------------------------------
                        V_SQLERRO :=
                            '17 - INCLUSÃO CRÉDITO DE CLIENTE: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
                        ---------------------------------------------------------------------------------
                        P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                                    VD_DATALANCTO,
                                                    VS_TEMCONTAINEXISTENTE,
                                                    VN_TOTALDEBITO,
                                                    VN_TOTALCREDITO,
                                                    'N');
                    END IF;

                    VS_TEMCONTAINEXISTENTE := 'N';
                END IF;

                --------------------------------------------------------------------

                --GERA NOVO NUMTRANSLANCTO
                IF VS_SEQGERADO = 'N'
                THEN
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '17 - INCLUSÃO CRÉDITO DE CLIENTE: EXECUTANDO FUNÇÃO GERA_NUM_TRANS_LANCTO()';
                    ---------------------------------------------------------------------------------
                    VN_NUMTRANSACAO := F_GERA_NUM_TRANS_LANCTO ();

                    VN_NUMSEQ := 0;
                    VN_TOTALCREDITO := 0;
                    VN_TOTALDEBITO := 0;
                    VS_SEQGERADO := 'S';

                    CONTASDEBLANCTO := CONTAS_LANCADAS ();
                    CONTASCRELANCTO := CONTAS_LANCADAS ();
                    CGCSLANCTO := CGC_LANCADOS ();
                    VS_LISTAS_TRANSOTORIAS := CONTAS_LANCADAS ();

                    CONTASDEBLANCTO.EXTEND;
                    CONTASCRELANCTO.EXTEND;
                END IF;

                IF VS_FORMADTCONTABILIZACAO = 'C'
                THEN
                    VD_DATALANCTO := ITEM.DATAOPERACAO1;
                ELSE
                    VD_DATALANCTO := ITEM.DATAOPERACAO;
                END IF;

                --LAÇO NOS ITENS DA REGRA CONTABIL
                OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL ()
                    USING PCODREGRA;

                LOOP
                    FETCH CURSOR_ITENS INTO ITENSREGRA;

                    EXIT WHEN CURSOR_ITENS%NOTFOUND;

                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '17 - INCLUSÃO CRÉDITO DE CLIENTE: ATRIBUINDO VALOR DO DOCUMENTO';
                    ---------------------------------------------------------------------------------
                    VS_DOCUMENTO := ITENSREGRA.DOCUMENTO;
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMTRANSOPERACAO',
                                 ITEM.NUMTRANSOPERACAO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMNOTA', ITEM.NUMNOTA);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMTRANS', ITEM.NUMTRANS);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'CODCLI', ITEM.CODCLIENTE);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'CLIENTE', ITEM.CLIENTE);
					VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMEROCREDITO', ITEM.NUMEROCREDITO);

                    --FORMULA INFORMADA NO FILTRO--------------------------------------------------------
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '17 - INCLUSÃO CRÉDITO DE CLIENTE: ATRIBUINDO VALOR DA FÓRMULA';
                    ---------------------------------------------------------------------------------
                    VN_VALORLANCTO := 0;

                    VS_FORMULA := ITENSREGRA.FORMULAS || ' + 0 ';
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORCREDITO([^_[:alnum:]])',
                                        NVL (ITEM.VALORCREDITO, 0) || '\1');


                    CALCULAREXPRESSAO;

                    --FIM DA FÓRMULA---------------------------------------------------------------------

                    IF VN_VALORLANCTO <> 0
                    THEN
                        VS_CONTA := TRIM (ITENSREGRA.CODREDUZIDO_PC);

                        IF     (SUBSTR (VS_CONTA, 1, 1) <> '0')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '1')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '2')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '3')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '4')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '5')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '6')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '7')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '8')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '9')
                        THEN
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTACLIENTE',
                                         ITEM.CODCONTACLIENTE);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTABANCO',
                                         ITEM.CODCONTABANCO);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTADESP',
                                         ITEM.CODCONTADESP);
                        END IF;


                        VS_CODFILIAL :=
                            CASE
                                WHEN ITENSREGRA.CODFILIAL =
                                     'FILIALLANCAMENTO'
                                THEN
                                    ITEM.CODFILIAL
                                ELSE
                                    ITENSREGRA.CODFILIAL
                            END;

                        VS_CONTA_EXISTE :=
                            F_VERIFICA_CONTA_EXISTE (VS_CONTA,
                                                     PCODPLANOCONTA);
                        TRATAR_CONTA_INEXISTENTE (VS_CONTA_EXISTE,
                                                  VS_TEMCONTAINEXISTENTE);

                        IF VS_CONTA_EXISTE IN ('S', 'I', 'X')
                        THEN
                            --HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO---------------------------------------
                            ---------------------------------------------------------------------------------
                            V_SQLERRO :=
                                '17 - INCLUSÃO CRÉDITO DE CLIENTE: ATRIBUINDO VALOR DE HISTÓRICOS';
                            ---------------------------------------------------------------------------------
                            VS_HISTORICO := ITENSREGRA.HISTCOMPLREGRA;
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[HISTORICOCREDITO]',
                                         ITEM.HISTORICOCREDITO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMNOTA]',
                                         ITEM.NUMNOTA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMEROCREDITO]',
                                         ITEM.NUMEROCREDITO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMTRANSVENDA]',
                                         ITEM.NUMTRANSVENDA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMTRANSOPERACAO]',
                                         ITEM.NUMTRANSOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODCLI]',
                                         ITEM.CODCLIENTE);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CLIENTE]',
                                         ITEM.CLIENTE);
                            VS_HISTORICO := SUBSTR (VS_HISTORICO, 1, 200);

                            --FIM HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO-----------------------------------

                            IF ITENSREGRA.NATUREZA = 'C'
                            THEN
                                IF VN_VALORLANCTO < 0
                                THEN
                                    VS_NATUREZA := 'D';
                                ELSE
                                    VS_NATUREZA := 'C';
                                END IF;
                            ELSE
                                IF VN_VALORLANCTO < 0
                                THEN
                                    VS_NATUREZA := 'C';
                                ELSE
                                    VS_NATUREZA := 'D';
                                END IF;
                            END IF;

                            IF VS_NATUREZA = 'C'
                            THEN
                                VN_TOTALCREDITO :=
                                    ROUND (
                                          VN_TOTALCREDITO
                                        + ABS (VN_VALORLANCTO),
                                        2);
                            ELSE
                                VN_TOTALDEBITO :=
                                    ROUND (
                                        VN_TOTALDEBITO + ABS (VN_VALORLANCTO),
                                        2);
                            END IF;

                            --GUARDA FILIAIS
                            FILIAIS.CODFILIAL := '-1';

                            FOR VN_POSICAO IN 1 .. FILIAIS_LANCADAS.COUNT
                            LOOP
                                IF (FILIAIS_LANCADAS (VN_POSICAO).CODFILIAL =
                                    VS_CODFILIAL)
                                THEN
                                    FILIAIS := FILIAIS_LANCADAS (VN_POSICAO);
                                    VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

                                    EXIT;
                                END IF;
                            END LOOP;

                            IF (FILIAIS.CODFILIAL = '-1')
                            THEN
                                FILIAIS_LANCADAS.EXTEND;

                                FILIAIS :=
                                    FILIAIS_LANCADAS (FILIAIS_LANCADAS.COUNT);
                                VN_POSICAO_EM_ALTERACAO :=
                                    FILIAIS_LANCADAS.COUNT;

                                FILIAIS.CODFILIAL := VS_CODFILIAL;
                                FILIAIS.CGCFILIAL :=
                                    F_CGCFILIAL (VS_CODFILIAL);

                                FILIAIS_LANCADAS (VN_POSICAO_EM_ALTERACAO) :=
                                    FILIAIS;
                            END IF;

                            --GUARDA AS CONTAS PARA VERIFICAR SE ESTÃO IGUAIS POSTERIORMENTE
                            P_ARMAZENA_CONTAS_FILIAIS_LANC (VS_CONTA,
                                                            VS_NATUREZA,
                                                            VS_CODFILIAL,
                                                            FILIAIS_LANCADAS);

                            IF 'N' = 'S'
                            THEN
                                NULL;
                            ELSE
                                ---------------------------------------------------------------------------------
                                V_SQLERRO :=
                                    '17 - INCLUSÃO CRÉDITO DE CLIENTE: EXECUTANDO PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA()';
                                ---------------------------------------------------------------------------------
                                --INSERE DADOS NA TABELA QUANDO NÃO ESTÁ TOTALIZANDO VALORES
                                VN_NUMSEQ := VN_NUMSEQ + 1;

                                P_GRAVA_DADOS_TABINTERMEDIARIA (
                                    VS_CODFILIAL,
                                    VN_NUMTRANSACAO,
                                    VN_NUMSEQ,
                                    VD_DATALANCTO,
                                    VS_DOCUMENTO,
                                    ITENSREGRA.CODHISTORICO,
                                    VS_HISTORICO,
                                    PCODPLANOCONTA,
                                    VS_CONTA,
                                    VS_NATUREZA,
                                    ABS (VN_VALORLANCTO),
                                    PCODREGRA,
                                    '',
                                    ITEM.NUMTRANSOPERACAO,
                                    F_RETORNA_TIPO_INCONSISTENCIA (
                                        VS_TEMCONTAINEXISTENTE),
                                    'P',
                                    VD_DATALANCTO_AUX,
                                    0,
                                    0,
                                    '',
                                    '',
                                    TRUNC (SYSDATE),
                                    0,
                                    '',
                                    NULL,
                                    ITEM.NUMTRANSOPERACAO,
                                    '',
                                    ITENSREGRA.FORMULAS,
                                    ITENSREGRA.CODREDUZIDO_PC,
                                    'INCCREDITO',
                                    'PCCRECLI',
                                    ITENSREGRA.TOTALIZAVALOR);
                            END IF;
                        END IF;
                    END IF;
                END LOOP;

                --GUARDA O NÚMERO DA TRANSAÇÃO
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            ELSE
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            END IF;
        END LOOP;

        --VERIFICA CONSISTÊNCIAS DO ÚLTIMO REGISTRO
        IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '17 - INCLUSÃO CRÉDITO DE CLIENTE: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
            ---------------------------------------------------------------------------------
            P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                        VD_DATALANCTO,
                                        VS_TEMCONTAINEXISTENTE,
                                        VN_TOTALDEBITO,
                                        VN_TOTALCREDITO,
                                        'N');
        END IF;

        CLOSE CURSOR_DADOS;


        RESULTADO := 'OK';
    EXCEPTION
        WHEN OTHERS
        THEN
            RESULTADO :=
                   'Ocorreu um erro quando: '
                || V_SQLERRO
                || CHR (13)
                || 'Erro Original: '
                || SQLERRM;
    END;



    /****************************************************************************
      PROCEDURE PARA GERAÇÃO DE 18 - CONTRATOS FINIMP E FINAME
    *****************************************************************************/
    PROCEDURE P_DADOS_CONTRATOSFINIMPFINAME (
        CURSOR_DADOS     IN     SYS_REFCURSOR,
        PCODREGRA        IN     NUMBER,
        PCODPLANOCONTA   IN     NUMBER,
        RESULTADO           OUT VARCHAR2)
    IS
        TYPE CONSULTA_CONTRATOSFINIMPFINAME IS RECORD
        (
            NUMTRANSOPERACAO
                PCCONTRATOEMPRESTIMO.NUMSEQCONTRATOEMPRESTIMO%TYPE,
            CODFILIAL PCLANC.CODFILIAL%TYPE,
            DATAOPERACAO DATE,
            TIPOCONTRATO PCCONTRATOEMPRESTIMO.TIPOCONTRATO%TYPE,
            TIPOCONTRATODESCRICAO VARCHAR2 (10),
            CODCONTA PCCONTA.CODCONTA%TYPE,
            CONTA PCCONTA.CONTA%TYPE,
            NUMLANCTO PCLANC.RECNUM%TYPE,
            NUMNOTA PCLANC.NUMNOTA%TYPE,
            CODPROJETO PCPROJETO.CODPROJETO%TYPE,
            CODROTINA PCLANC.CODROTINACAD%TYPE,
            VALORTITULO PCLANC.VALOR%TYPE,
            VALORDESCONTO PCLANC.DESCONTOFIN%TYPE,
            VALORJUROS PCLANC.TXPERM%TYPE,
            VALORPAGO PCLANC.VPAGO%TYPE,
            VALORJUROSEMPRESTIMO PCLANC.TXPERM%TYPE,
            VALORVARIACAOCAMBIALPOSITIVA PCLANC.VLVARIACAOCAMBIAL%TYPE,
            VALORVARIACAOCAMBIALNEGATIVA PCLANC.VLVARIACAOCAMBIAL%TYPE,
            CODFORNECEMPRESTIMO PCCONTRATOEMPRESTIMO.CODFORNEC%TYPE,
            FORNECEMPRESTIMO PCFORNEC.FORNECEDOR%TYPE,
            CODFORNEC PCLANC.CODFORNEC%TYPE,
            FORNECEDOR PCFORNEC.FORNECEDOR%TYPE,
            NUMCONTRATO PCCONTRATOEMPRESTIMO.NUMCONTRATO%TYPE,
            CODMOEDA PCCONTRATOEMPRESTIMO.MOEDAESTRANGEIRA%TYPE,
            MOEDA PCCOTACAOMOEDAC.MOEDA%TYPE,
            CODCONTAFORNECEDOREMPRESTIMO PCMODELOPC.CODREDUZIDO_PC%TYPE,
            CODCONTAFORNECEDOR PCMODELOPC.CODREDUZIDO_PC%TYPE,
            CODCONTAGERENCIAL PCMODELOPC.CODREDUZIDO_PC%TYPE,
            HISTORICO PCLANC.HISTORICO%TYPE,
            HISTORICO2 PCLANC.HISTORICO2%TYPE,
            TEMINTEGRACAO VARCHAR2 (2)
        );

        ITEM               CONSULTA_CONTRATOSFINIMPFINAME;
        ITENSREGRA         CONSULTA_ITENS;

        CURSOR_ITENS       SYS_REFCURSOR;


        FILIAIS_LANCADAS   TABELAFILIAISLANCTO;
        FILIAIS            FILIAISLANCTO;
        VS_CONTA_EXISTE    VARCHAR2 (1);
    BEGIN
        LISTA_FORMULAS := TYPE_LISTA_FORMULAS ();
        FILIAIS_LANCADAS := TABELAFILIAISLANCTO ();

        VS_SEQGERADO := 'N';
        VS_FORMADTCONTABILIZACAO := '';
        VN_NUMTRANSACAO := 0;
        VS_DOCUMENTO := '';
        VS_TEMCONTAINEXISTENTE := 'N';

        --BUSCA DADOS DA REGRA
        SELECT FORMADTCONTABILIZACAO
          INTO VS_FORMADTCONTABILIZACAO
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        --INICIA LAÇO DOS DADOS
        LOOP
            FETCH CURSOR_DADOS INTO ITEM;

            EXIT WHEN CURSOR_DADOS%NOTFOUND;

            IF    (ITEM.TEMINTEGRACAO IS NULL)
               OR (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                   AND (ITEM.TEMINTEGRACAO = 'P'))
            THEN
                --PARA CONTRATOS FINIMP E FINAME, CONFORME A ESPECIFICAÇÃO, SERÁ SEMPRE A DATA DO CONTRATO

                --------------------------------------------------------------------
                --VERIFICA SE ALTEROU O NUMTRANSOPERACAO PARA FAZER GRAVAÇÃO E RE-INICIAR VARIÁVEIS
                IF (VN_NUMTRANSOPERACAO <> ITEM.NUMTRANSOPERACAO)
                THEN
                    VS_SEQGERADO := 'N';

                    IF (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                        AND (ITEM.TEMINTEGRACAO = 'P'))
                    THEN
                        P_EXCLUI_LANCINTERMEDIARIA_IND (
                            PCODREGRA,
                            ITEM.NUMTRANSOPERACAO,
                            ITEM.DATAOPERACAO);
                    END IF;

                    --VERIFICA SE JÁ PASSOU POR ALGUM REGISTRO PARA ATRIBUIR INCONSISTÊNCIAS
                    IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) >
                       0
                    THEN
                        ---------------------------------------------------------------------------------
                        V_SQLERRO :=
                            '18 - CONTRATOS FINIMP E FINAME: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
                        ---------------------------------------------------------------------------------
                        P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                                    VD_DATALANCTO,
                                                    VS_TEMCONTAINEXISTENTE,
                                                    VN_TOTALDEBITO,
                                                    VN_TOTALCREDITO,
                                                    'N');
                    END IF;

                    VS_TEMCONTAINEXISTENTE := 'N';
                END IF;

                --------------------------------------------------------------------

                --GERA NOVO NUMTRANSLANCTO
                IF VS_SEQGERADO = 'N'
                THEN
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '18 - CONTRATOS FINIMP E FINAME: EXECUTANDO FUNÇÃO GERA_NUM_TRANS_LANCTO()';
                    ---------------------------------------------------------------------------------
                    VN_NUMTRANSACAO := F_GERA_NUM_TRANS_LANCTO ();

                    VN_NUMSEQ := 0;
                    VN_TOTALCREDITO := 0;
                    VN_TOTALDEBITO := 0;
                    VS_SEQGERADO := 'S';

                    CONTASDEBLANCTO := CONTAS_LANCADAS ();
                    CONTASCRELANCTO := CONTAS_LANCADAS ();
                    CGCSLANCTO := CGC_LANCADOS ();
                    VS_LISTAS_TRANSOTORIAS := CONTAS_LANCADAS ();

                    CONTASDEBLANCTO.EXTEND;
                    CONTASCRELANCTO.EXTEND;
                END IF;

                VD_DATALANCTO := ITEM.DATAOPERACAO; --PARA CONTRATOS FINIMP E FINAME, CONFORME A ESPECIFICAÇÃO, SERÁ SEMPRE A DATA DO CONTRATO

                --LAÇO NOS ITENS DA REGRA CONTABIL
                OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL ()
                    USING PCODREGRA;

                LOOP
                    FETCH CURSOR_ITENS INTO ITENSREGRA;

                    EXIT WHEN CURSOR_ITENS%NOTFOUND;

                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '18 - CONTRATOS FINIMP E FINAME: ATRIBUINDO VALOR DO DOCUMENTO';
                    ---------------------------------------------------------------------------------
                    VS_DOCUMENTO := ITENSREGRA.DOCUMENTO;
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'TIPOCONTRATODESCRICAO',
                                 ITEM.TIPOCONTRATODESCRICAO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMCONTRATO',
                                 ITEM.NUMCONTRATO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO',
                                 ITEM.DATAOPERACAO);

                    --FORMULA INFORMADA NO FILTRO--------------------------------------------------------
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '18 - CONTRATOS FINIMP E FINAME: ATRIBUINDO VALOR DA FÓRMULA';
                    ---------------------------------------------------------------------------------
                    VN_VALORLANCTO := 0;

                    VS_FORMULA := ITENSREGRA.FORMULAS || ' + 0 ';
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORTITULO([^_[:alnum:]])',
                                        NVL (ITEM.VALORTITULO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORDESCONTO([^_[:alnum:]])',
                                        NVL (ITEM.VALORDESCONTO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORJUROS([^_[:alnum:]])',
                                        NVL (ITEM.VALORJUROS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORPAGO([^_[:alnum:]])',
                                        NVL (ITEM.VALORPAGO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORJUROSEMPRESTIMO([^_[:alnum:]])',
                            NVL (ITEM.VALORJUROSEMPRESTIMO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORVARIACAOCAMBIALPOSITIVA([^_[:alnum:]])',
                               NVL (ITEM.VALORVARIACAOCAMBIALPOSITIVA, 0)
                            || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORVARIACAOCAMBIALNEGATIVA([^_[:alnum:]])',
                               NVL (ITEM.VALORVARIACAOCAMBIALNEGATIVA, 0)
                            || '\1');

                    CALCULAREXPRESSAO;

                    --FIM DA FÓRMULA---------------------------------------------------------------------

                    IF VN_VALORLANCTO <> 0
                    THEN
                        VS_CONTA := TRIM (ITENSREGRA.CODREDUZIDO_PC);

                        IF     (SUBSTR (VS_CONTA, 1, 1) <> '0')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '1')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '2')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '3')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '4')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '5')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '6')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '7')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '8')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '9')
                        THEN
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTAFORNECEDOREMPRESTIMO',
                                         ITEM.CODCONTAFORNECEDOREMPRESTIMO);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTAFORNECEDOR',
                                         ITEM.CODCONTAFORNECEDOR);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTAGERENCIAL',
                                         ITEM.CODCONTAGERENCIAL);
                        END IF;

                        VS_CODFILIAL :=
                            CASE
                                WHEN ITENSREGRA.CODFILIAL =
                                     'FILIALLANCAMENTO'
                                THEN
                                    ITEM.CODFILIAL
                                ELSE
                                    ITENSREGRA.CODFILIAL
                            END;

                        VS_CONTA_EXISTE :=
                            F_VERIFICA_CONTA_EXISTE (VS_CONTA,
                                                     PCODPLANOCONTA);
                        TRATAR_CONTA_INEXISTENTE (VS_CONTA_EXISTE,
                                                  VS_TEMCONTAINEXISTENTE);

                        IF VS_CONTA_EXISTE IN ('S', 'I', 'X')
                        THEN
                            --HISTÓRICO COMPLEMENTAR INFORMADO NO FILTRO---------------------------------------
                            ---------------------------------------------------------------------------------
                            V_SQLERRO :=
                                '18 - CONTRATOS FINIMP E FINAME: ATRIBUINDO VALOR DE HISTÓRICOS';
                            ---------------------------------------------------------------------------------
                            VS_HISTORICO := ITENSREGRA.HISTCOMPLREGRA;
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[TIPOCONTRATODESCRICAO]',
                                         ITEM.TIPOCONTRATODESCRICAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODFORNEC]',
                                         ITEM.CODFORNEC);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[FORNECEDOR]',
                                         ITEM.FORNECEDOR);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODFORNECEMPRESTIMO]',
                                         ITEM.CODFORNECEMPRESTIMO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[FORNECEMPRESTIMO]',
                                         ITEM.FORNECEMPRESTIMO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMCONTRATO]',
                                         ITEM.NUMCONTRATO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMTRANSOPERACAO]',
                                         ITEM.NUMTRANSOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMNOTA]',
                                         ITEM.NUMNOTA);
                            VS_HISTORICO := SUBSTR (VS_HISTORICO, 1, 200);

                            --FIM HISTÓRICO COMPLEMENTAR INFORMADO NO FILTRO-----------------------------------

                            IF ITENSREGRA.NATUREZA = 'C'
                            THEN
                                IF VN_VALORLANCTO < 0
                                THEN
                                    VS_NATUREZA := 'D';
                                ELSE
                                    VS_NATUREZA := 'C';
                                END IF;
                            ELSE
                                IF VN_VALORLANCTO < 0
                                THEN
                                    VS_NATUREZA := 'C';
                                ELSE
                                    VS_NATUREZA := 'D';
                                END IF;
                            END IF;

                            IF VS_NATUREZA = 'C'
                            THEN
                                VN_TOTALCREDITO :=
                                    ROUND (
                                          VN_TOTALCREDITO
                                        + ABS (VN_VALORLANCTO),
                                        2);
                            ELSE
                                VN_TOTALDEBITO :=
                                    ROUND (
                                        VN_TOTALDEBITO + ABS (VN_VALORLANCTO),
                                        2);
                            END IF;

                            --GUARDA FILIAIS
                            FILIAIS.CODFILIAL := '-1';

                            FOR VN_POSICAO IN 1 .. FILIAIS_LANCADAS.COUNT
                            LOOP
                                IF (FILIAIS_LANCADAS (VN_POSICAO).CODFILIAL =
                                    VS_CODFILIAL)
                                THEN
                                    FILIAIS := FILIAIS_LANCADAS (VN_POSICAO);
                                    VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

                                    EXIT;
                                END IF;
                            END LOOP;

                            IF (FILIAIS.CODFILIAL = '-1')
                            THEN
                                FILIAIS_LANCADAS.EXTEND;

                                FILIAIS :=
                                    FILIAIS_LANCADAS (FILIAIS_LANCADAS.COUNT);
                                VN_POSICAO_EM_ALTERACAO :=
                                    FILIAIS_LANCADAS.COUNT;

                                FILIAIS.CODFILIAL := VS_CODFILIAL;
                                FILIAIS.CGCFILIAL :=
                                    F_CGCFILIAL (VS_CODFILIAL);

                                FILIAIS_LANCADAS (VN_POSICAO_EM_ALTERACAO) :=
                                    FILIAIS;
                            END IF;

                            --GUARDA AS CONTAS PARA VERIFICAR SE ESTÃO IGUAIS POSTERIORMENTE
                            P_ARMAZENA_CONTAS_FILIAIS_LANC (VS_CONTA,
                                                            VS_NATUREZA,
                                                            VS_CODFILIAL,
                                                            FILIAIS_LANCADAS);

                            IF 'N' = 'S'
                            THEN
                                NULL;
                            ELSE
                                ---------------------------------------------------------------------------------
                                V_SQLERRO :=
                                    '18 - CONTRATOS FINIMP E FINAME: EXECUTANDO PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA()';
                                ---------------------------------------------------------------------------------
                                --INSERE DADOS NA TABELA QUANDO NÃO ESTÁ TOTALIZANDO VALORES
                                VN_NUMSEQ := VN_NUMSEQ + 1;

                                P_GRAVA_DADOS_TABINTERMEDIARIA (
                                    VS_CODFILIAL,
                                    VN_NUMTRANSACAO,
                                    VN_NUMSEQ,
                                    VD_DATALANCTO,
                                    VS_DOCUMENTO,
                                    ITENSREGRA.CODHISTORICO,
                                    VS_HISTORICO,
                                    PCODPLANOCONTA,
                                    VS_CONTA,
                                    VS_NATUREZA,
                                    ABS (VN_VALORLANCTO),
                                    PCODREGRA,
                                    '',
                                    ITEM.NUMTRANSOPERACAO,
                                    F_RETORNA_TIPO_INCONSISTENCIA (
                                        VS_TEMCONTAINEXISTENTE),
                                    'P',
                                    ITEM.DATAOPERACAO,
                                    0,
                                    0,
                                    ITEM.CODMOEDA,
                                    '',
                                    TRUNC (SYSDATE),
                                    ITEM.CODFORNEC,
                                    'F',
                                    NULL,
                                    ITEM.NUMTRANSOPERACAO,
                                    '',
                                    ITENSREGRA.FORMULAS,
                                    ITENSREGRA.CODREDUZIDO_PC,
                                    'FINIMPFINAME',
                                    'PCCONTRATOEMPRESTIMO',
                                    ITENSREGRA.TOTALIZAVALOR);
                            END IF;
                        END IF;
                    END IF;
                END LOOP;

                --GUARDA O NÚMERO DA TRANSAÇÃO
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            ELSE
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            END IF;
        END LOOP;

        --VERIFICA CONSISTÊNCIAS DO ÚLTIMO REGISTRO
        IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '18 - CONTRATOS FINIMP E FINAME: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
            ---------------------------------------------------------------------------------
            P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                        VD_DATALANCTO,
                                        VS_TEMCONTAINEXISTENTE,
                                        VN_TOTALDEBITO,
                                        VN_TOTALCREDITO,
                                        'N');
        END IF;

        CLOSE CURSOR_DADOS;

        RESULTADO := 'OK';
    EXCEPTION
        WHEN OTHERS
        THEN
            RESULTADO :=
                   'Ocorreu um erro quando: '
                || V_SQLERRO
                || CHR (13)
                || 'Erro Original: '
                || SQLERRM;
    END;


    /****************************************************************************
      PROCEDURE PARA GERAÇÃO DE 19 - PIS/COFINS SERVIÇOS TOMADOS
    *****************************************************************************/
    PROCEDURE P_DADOS_PISCOFINSSERVTOMADOS (
        CURSOR_DADOS     IN     SYS_REFCURSOR,
        PCODREGRA        IN     NUMBER,
        PCODPLANOCONTA   IN     NUMBER,
        RESULTADO           OUT VARCHAR2)
    IS
        TYPE CONSULTA_PISCOFINSSERVTOMADOS IS RECORD
        (
            CODFILIAL PCNFENT.CODFILIAL%TYPE,
            DATAOPERACAO PCNFENT.DTENT%TYPE,
            HISTORICO VARCHAR2 (120),
            NUMNOTA PCNFENT.NUMNOTA%TYPE,
            ESPECIE PCNFENT.ESPECIE%TYPE,
            CODIGOFORNECEDOR PCFORNEC.CODFORNEC%TYPE,
            FORNECEDOR PCFORNEC.FORNECEDOR%TYPE,
            CODCONTAGERENCIAL PCCONTA.CODCONTA%TYPE,
            CONTAGERENCIAL PCCONTA.CONTA%TYPE,
            VALORBASEPIS PCNFENTPISCOFINS.VLBASEPIS%TYPE,
            VALORPIS PCNFENTPISCOFINS.VLPIS%TYPE,
            VALORBASECOFINS PCNFENTPISCOFINS.VLBASECOFINS%TYPE,
            VALORCOFINS PCNFENTPISCOFINS.VLCOFINS%TYPE,
            NUMTRANSOPERACAO PCNFENT.NUMTRANSENT%TYPE,
            CODCONTADESPFORNEC PCFORNEC.CODCONTAB%TYPE,
            CODCONTACRED PCCONTA.CONTACONTABIL%TYPE,
            TIPOPARCEIRO PCLANC.TIPOPARCEIRO%TYPE,
            MOEDA PCLANC.MOEDA%TYPE,
            RECNUMPRINC PCLANC.RECNUMPRINC%TYPE,
            TEMINTEGRACAO VARCHAR2 (2),
            CODCONTADESP PCCONTA.CONTA%TYPE
        );

        ITEM                CONSULTA_PISCOFINSSERVTOMADOS;
        ITENSREGRA          CONSULTA_ITENS;

        CURSOR_ITENS        SYS_REFCURSOR;

        VALORES_POSSIVEIS   TABELAVALORES;
        VALOR               VALORES;

        FILIAIS_LANCADAS    TABELAFILIAISLANCTO;
        FILIAIS             FILIAISLANCTO;

        VS_CONTA_EXISTE     VARCHAR2 (1);
    BEGIN
        LISTA_FORMULAS := TYPE_LISTA_FORMULAS ();
        VALORES_POSSIVEIS := TABELAVALORES ();
        FILIAIS_LANCADAS := TABELAFILIAISLANCTO ();

        VS_SEQGERADO := 'N';
        VS_FORMADTCONTABILIZACAO := '';
        VS_DOCPESQUISADO := '';
        VN_NUMTRANSACAO := 0;
        VS_DOCUMENTO := '';
        VS_TEMCONTAINEXISTENTE := 'N';

        V_SQLERRO := 'ABRINDO PIS/COFINS SERVIÇOS TOMADOS';

        --INICIA LAÇO DOS DADOS
        LOOP
            FETCH CURSOR_DADOS INTO ITEM;

            EXIT WHEN CURSOR_DADOS%NOTFOUND;

            IF    (ITEM.TEMINTEGRACAO IS NULL)
               OR (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                   AND (ITEM.TEMINTEGRACAO = 'P'))
            THEN
                --------------------------------------------------------------------
                --VERIFICA SE ALTEROU O NUMTRANSOPERACAO PARA FAZER GRAVAÇÃO E RE-INICIAR VARIÁVEIS
                IF (VN_NUMTRANSOPERACAO <> ITEM.NUMTRANSOPERACAO)
                THEN
                    VS_SEQGERADO := 'N';

                    IF (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                        AND (ITEM.TEMINTEGRACAO = 'P'))
                    THEN
                        P_EXCLUI_LANCINTERMEDIARIA_IND (
                            PCODREGRA,
                            ITEM.NUMTRANSOPERACAO,
                            ITEM.DATAOPERACAO);
                    END IF;

                    IF VALORES_POSSIVEIS.COUNT > 0
                    THEN
                        ---------------------------------------------------------------------------------
                        V_SQLERRO :=
                            '19 - PIS/COFINS SERVIÇOS TOMADOS: EXECUTANDO PROCEDURE P_GRAVAR_ITENS_TOTALIZADOS()';
                        ---------------------------------------------------------------------------------
                        P_GRAVAR_ITENS_TOTALIZADOS (VALORES_POSSIVEIS,
                                                    PCODREGRA,
                                                    PCODPLANOCONTA);

                        VALORES_POSSIVEIS := TABELAVALORES ();
                    END IF;

                    --VERIFICA SE JÁ PASSOU POR ALGUM REGISTRO PARA ATRIBUIR INCONSISTÊNCIAS
                    IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) >
                       0
                    THEN
                        ---------------------------------------------------------------------------------
                        V_SQLERRO :=
                            '19 - PIS/COFINS SERVIÇOS TOMADOS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
                        ---------------------------------------------------------------------------------
                        P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                                    VD_DATALANCTO,
                                                    VS_TEMCONTAINEXISTENTE,
                                                    VN_TOTALDEBITO,
                                                    VN_TOTALCREDITO,
                                                    'N');
                    END IF;

                    VS_TEMCONTAINEXISTENTE := 'N';
                END IF;

                --------------------------------------------------------------------

                --GERA NOVO NUMTRANSLANCTO
                IF VS_SEQGERADO = 'N'
                THEN
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '19 - PIS/COFINS SERVIÇOS TOMADOS: EXECUTANDO FUNÇÃO GERA_NUM_TRANS_LANCTO()';
                    ---------------------------------------------------------------------------------
                    VN_NUMTRANSACAO := F_GERA_NUM_TRANS_LANCTO ();

                    VN_NUMSEQ := 0;
                    VN_TOTALCREDITO := 0;
                    VN_TOTALDEBITO := 0;
                    VS_SEQGERADO := 'S';

                    CONTASDEBLANCTO := CONTAS_LANCADAS ();
                    CONTASCRELANCTO := CONTAS_LANCADAS ();
                    CGCSLANCTO := CGC_LANCADOS ();
                    VS_LISTAS_TRANSOTORIAS := CONTAS_LANCADAS ();

                    CONTASDEBLANCTO.EXTEND;
                    CONTASCRELANCTO.EXTEND;
                END IF;

                VD_DATALANCTO :=
                    F_RETORNA_DATA_LANCPROVISOES (19,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO);

                VD_DATAINTEGRACAO :=
                    F_RETORNA_DATA_LANCPROVISOES (19,
                                                  PCODREGRA,
                                                  DATA_INTEGRACAO,
                                                  ITEM.DATAOPERACAO);


                --LAÇO NOS ITENS DA REGRA CONTABIL
                OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL ()
                    USING PCODREGRA;

                LOOP
                    FETCH CURSOR_ITENS INTO ITENSREGRA;

                    EXIT WHEN CURSOR_ITENS%NOTFOUND;

                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '19 - PIS/COFINS SERVIÇOS TOMADOS: ATRIBUINDO VALOR DO DOCUMENTO';
                    ---------------------------------------------------------------------------------

                    VS_DOCUMENTO := ITENSREGRA.DOCUMENTO;
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMNOTA', ITEM.NUMNOTA);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMTRANSOPERACAO',
                                 ITEM.NUMTRANSOPERACAO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'RECNUMPRINC',
                                 ITEM.RECNUMPRINC);

                    VD_DATALANCTO :=
                        F_RETORNA_DATA_LANCPROVISOES (19,
                                                      PCODREGRA,
                                                      DATA_LANCAMENTO,
                                                      ITEM.DATAOPERACAO);

                    VD_DATAINTEGRACAO :=
                        F_RETORNA_DATA_LANCPROVISOES (19,
                                                      PCODREGRA,
                                                      DATA_INTEGRACAO,
                                                      ITEM.DATAOPERACAO);

                    --FORMULA INFORMADA NO FILTRO--------------------------------------------------------
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '19 - PIS/COFINS SERVIÇOS TOMADOS: ATRIBUINDO VALOR DA FÓRMULA';
                    ---------------------------------------------------------------------------------
                    VN_VALORLANCTO := 0;

                    VS_FORMULA := ITENSREGRA.FORMULAS || ' + 0 ';
                    /*          VS_FORMULA := REGEXP_REPLACE(VS_FORMULA,
                                                           'VALORBASEPIS([^_[:alnum:]])',
                                                           NVL(ITEM.VALORBASEPIS, 0) || '\1');*/
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORPIS([^_[:alnum:]])',
                                        NVL (ITEM.VALORPIS, 0) || '\1');
                    /*          VS_FORMULA := REGEXP_REPLACE(VS_FORMULA,
                                                           'VALORBASECOFINS([^_[:alnum:]])',
                                                           NVL(ITEM.VALORBASECOFINS, 0) || '\1');*/
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORCOFINS([^_[:alnum:]])',
                                        NVL (ITEM.VALORCOFINS, 0) || '\1');

                    CALCULAREXPRESSAO;

                    --FIM DA FÓRMULA---------------------------------------------------------------------

                    IF VN_VALORLANCTO <> 0
                    THEN
                        VS_CONTA := TRIM (ITENSREGRA.CODREDUZIDO_PC);

                        IF     (SUBSTR (VS_CONTA, 1, 1) <> '0')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '1')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '2')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '3')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '4')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '5')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '6')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '7')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '8')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '9')
                        THEN
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTADESPFORNEC',
                                         ITEM.CODCONTADESPFORNEC);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTACRED',
                                         ITEM.CODCONTACRED);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTADESP',
                                         ITEM.CODCONTADESP);
                        END IF;

                        VS_CODFILIAL :=
                            CASE
                                WHEN ITENSREGRA.CODFILIAL =
                                     'FILIALLANCAMENTO'
                                THEN
                                    ITEM.CODFILIAL
                                ELSE
                                    ITENSREGRA.CODFILIAL
                            END;

                        VS_CONTA_EXISTE :=
                            F_VERIFICA_CONTA_EXISTE (VS_CONTA,
                                                     PCODPLANOCONTA);
                        TRATAR_CONTA_INEXISTENTE (VS_CONTA_EXISTE,
                                                  VS_TEMCONTAINEXISTENTE);

                        IF VS_CONTA_EXISTE IN ('S', 'I', 'X')
                        THEN
                            --HISTÓRICO COMPLEMENTAR INFORMADO NO FILTRO---------------------------------------
                            ---------------------------------------------------------------------------------
                            V_SQLERRO :=
                                '19 - PIS/COFINS SERVIÇOS TOMADOS: ATRIBUINDO VALOR DE HISTÓRICOS';
                            ---------------------------------------------------------------------------------
                            VS_HISTORICO := ITENSREGRA.HISTCOMPLREGRA;
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[HISTORICO]',
                                         ITEM.HISTORICO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMNOTA]',
                                         ITEM.NUMNOTA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[ESPECIENF]',
                                         ITEM.ESPECIE);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODIGOFORNECEDOR]',
                                         ITEM.CODIGOFORNECEDOR);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[FORNECEDOR]',
                                         ITEM.FORNECEDOR);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODCONTAGERENCIAL]',
                                         ITEM.CODCONTAGERENCIAL);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CONTAGERENCIAL]',
                                         ITEM.CONTAGERENCIAL);
                            VS_HISTORICO := SUBSTR (VS_HISTORICO, 1, 200);

                            --FIM HISTÓRICO COMPLEMENTAR INFORMADO NO FILTRO-----------------------------------

                            IF ITENSREGRA.NATUREZA = 'C'
                            THEN
                                IF VN_VALORLANCTO < 0
                                THEN
                                    VS_NATUREZA := 'D';
                                ELSE
                                    VS_NATUREZA := 'C';
                                END IF;
                            ELSE
                                IF VN_VALORLANCTO < 0
                                THEN
                                    VS_NATUREZA := 'C';
                                ELSE
                                    VS_NATUREZA := 'D';
                                END IF;
                            END IF;

                            IF VS_NATUREZA = 'C'
                            THEN
                                VN_TOTALCREDITO :=
                                    ROUND (
                                          VN_TOTALCREDITO
                                        + ABS (VN_VALORLANCTO),
                                        2);
                            ELSE
                                VN_TOTALDEBITO :=
                                    ROUND (
                                        VN_TOTALDEBITO + ABS (VN_VALORLANCTO),
                                        2);
                            END IF;

                            --GUARDA FILIAIS
                            FILIAIS.CODFILIAL := '-1';

                            FOR VN_POSICAO IN 1 .. FILIAIS_LANCADAS.COUNT
                            LOOP
                                IF (FILIAIS_LANCADAS (VN_POSICAO).CODFILIAL =
                                    VS_CODFILIAL)
                                THEN
                                    FILIAIS := FILIAIS_LANCADAS (VN_POSICAO);
                                    VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

                                    EXIT;
                                END IF;
                            END LOOP;

                            IF (FILIAIS.CODFILIAL = '-1')
                            THEN
                                FILIAIS_LANCADAS.EXTEND;

                                FILIAIS :=
                                    FILIAIS_LANCADAS (FILIAIS_LANCADAS.COUNT);
                                VN_POSICAO_EM_ALTERACAO :=
                                    FILIAIS_LANCADAS.COUNT;

                                FILIAIS.CODFILIAL := VS_CODFILIAL;
                                FILIAIS.CGCFILIAL :=
                                    F_CGCFILIAL (VS_CODFILIAL);

                                FILIAIS_LANCADAS (VN_POSICAO_EM_ALTERACAO) :=
                                    FILIAIS;
                            END IF;

                            --GUARDA AS CONTAS PARA VERIFICAR SE ESTÃO IGUAIS POSTERIORMENTE
                            P_ARMAZENA_CONTAS_FILIAIS_LANC (VS_CONTA,
                                                            VS_NATUREZA,
                                                            VS_CODFILIAL,
                                                            FILIAIS_LANCADAS);


                            ---------------------------------------------------------------------------------
                            V_SQLERRO :=
                                '19 - PIS/COFINS SERVIÇOS TOMADOS: EXECUTANDO PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA()';
                            ---------------------------------------------------------------------------------
                            --INSERE DADOS NA TABELA QUANDO NÃO ESTÁ TOTALIZANDO VALORES
                            VN_NUMSEQ := VN_NUMSEQ + 1;

                            P_GRAVA_DADOS_TABINTERMEDIARIA (
                                VS_CODFILIAL,
                                VN_NUMTRANSACAO,
                                VN_NUMSEQ,
                                VD_DATALANCTO,
                                VS_DOCUMENTO,
                                ITENSREGRA.CODHISTORICO,
                                VS_HISTORICO,
                                PCODPLANOCONTA,
                                VS_CONTA,
                                VS_NATUREZA,
                                ABS (VN_VALORLANCTO),
                                PCODREGRA,
                                '',
                                ITEM.NUMTRANSOPERACAO,
                                F_RETORNA_TIPO_INCONSISTENCIA (
                                    VS_TEMCONTAINEXISTENTE),
                                'P',
                                ITEM.DATAOPERACAO,
                                0,
                                0,
                                '',
                                '',
                                VD_DATAINTEGRACAO,
                                ITEM.CODIGOFORNECEDOR,
                                ITEM.TIPOPARCEIRO,
                                NULL,
                                ITEM.NUMTRANSOPERACAO,
                                '',
                                ITENSREGRA.FORMULAS,
                                ITENSREGRA.CODREDUZIDO_PC,
                                'PISCOFINSSERVTOMADOS',
                                'PCNFENTPISCOFINS',
                                ITENSREGRA.TOTALIZAVALOR);
                        END IF;
                    END IF;
                END LOOP;

                --GUARDA O NÚMERO DA TRANSAÇÃO
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            ELSE
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            END IF;
        END LOOP;

        -- GRAVAR OS ITENS QUE AINDA NAO FORAM GRAVADOS DENTRO DE VALORES_POSSIVEIS
        IF VALORES_POSSIVEIS.COUNT > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '19 - PIS/COFINS SERVIÇOS TOMADOS: EXECUTANDO PROCEDURE P_GRAVAR_ITENS_TOTALIZADOS()';
            ---------------------------------------------------------------------------------
            P_GRAVAR_ITENS_TOTALIZADOS (VALORES_POSSIVEIS,
                                        PCODREGRA,
                                        PCODPLANOCONTA);
        END IF;

        --VERIFICA CONSISTÊNCIAS DO ÚLTIMO REGISTRO
        IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '19 - PIS/COFINS SERVIÇOS TOMADOS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
            ---------------------------------------------------------------------------------
            P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                        VD_DATALANCTO,
                                        VS_TEMCONTAINEXISTENTE,
                                        VN_TOTALDEBITO,
                                        VN_TOTALCREDITO,
                                        'N');
        END IF;

        CLOSE CURSOR_DADOS;

        RESULTADO := 'OK';
    EXCEPTION
        WHEN OTHERS
        THEN
            RESULTADO :=
                   'Ocorreu um erro quando: '
                || V_SQLERRO
                || CHR (13)
                || 'Erro Original: '
                || SQLERRM;
    END;
    
    
        /****************************************************************************
      PROCEDURE PARA GERAÇÃO DE 20 - SAÍDAS CANCELADAS TECHFIN
    *****************************************************************************/
    PROCEDURE P_DADOS_SAIDAS_CANC_TECHFIN (CURSOR_DADOS     IN     SYS_REFCURSOR,
                              PCODREGRA        IN     NUMBER,
                              PCODPLANOCONTA   IN     NUMBER,
                              RESULTADO           OUT VARCHAR2)
    IS
        TYPE CONSULTA_SAIDAS IS RECORD
        (
            CODFILIAL PCNFBASESAID.CODFILIALNF%TYPE,
            DATAOPERACAO PCNFBASESAID.DTSAIDA%TYPE,
            NUMNOTANF PCNFBASESAID.NUMNOTA%TYPE,
            VALORTOTAL PCNFBASESAID.VLDESDOBRADO%TYPE,
            VALORICMS PCNFBASESAID.VLICMS%TYPE,
            VALORPIS PCNFBASESAID.VLPIS%TYPE,
            VALORCOFINS PCNFBASESAID.VLCOFINS%TYPE,
            VALORISENTAS PCNFBASESAID.VLISENTAS%TYPE,
            VALOROUTRAS PCNFBASESAID.VLOUTRAS%TYPE,
            VALORFRETE PCNFBASESAID.VLFRETE%TYPE,
            VALORST PCNFBASESAID.VLST%TYPE,
            VALORIPI PCNFBASESAID.VLIPI%TYPE,
            VALORIMPESTADUAL PCNFBASESAID.VLIMPESTADUAL%TYPE,
            VALORREPASSE PCNFBASESAID.VLREPASSE%TYPE,
            VALORSUBSTRETENCAO PCNFBASESAID.VLSTBCR%TYPE,
            VALORCREDPRESUMIDO PCNFBASESAID.VLCREDPRESUMIDO%TYPE,
            VALORISENTAS_DAPI PCNFBASESAID.VLISENTAS_DAPI%TYPE,
            VALORNAOTRIB_DAPI PCNFBASESAID.VLNAOTRIB_DAPI%TYPE,
            VALORBASERED_DAPI PCNFBASESAID.VLBASERED_DAPI%TYPE,
            VALORSUSPENSAS_DAPI PCNFBASESAID.VLSUSPENSAS_DAPI%TYPE,
            VALORST_DAPI PCNFBASESAID.VLST_DAPI%TYPE,
            VALOROUTRAS_DAPI PCNFBASESAID.VLOUTRAS_DAPI%TYPE,
            VALORISENTASIPI PCNFBASESAID.VLISENTASIPI%TYPE,
            VALOROUTRASIPI PCNFBASESAID.VLOUTRASIPI%TYPE,
            VALORFUNDOCOMBPOBREZA PCNFBASESAID.VLFCP%TYPE,
            VALORICMSDIFALIQPARTILHA PCNFBASESAID.VLICMSDIFALIQPART%TYPE,
            VALORICMSUFDEST PCNFBASESAID.VLICMSUFDEST%TYPE,
            VALORICMSUFREM PCNFBASESAID.VLICMSUFREM%TYPE,
            CODCOBRANCA PCNFSAID.CODCOB%TYPE,
            CODFISCALNF PCCFO.CODFISCAL%TYPE,
            TIPODEVENDANF PCNFSAID.CONDVENDA%TYPE,
            ESPECIENF PCNFBASESAID.ESPECIE%TYPE,
            TIPOOPERACAO PCNFBASESAID.TIPOVENDA%TYPE,
            CLIENTENF PCCLIENT.CLIENTE%TYPE,
            CODCLIENTENF PCNFBASESAID.CODCLI%TYPE,
            CLIENTEDESTINATARIO PCNFSAID.CLIENTE%TYPE,
            SERIENF PCNFBASESAID.SERIE%TYPE,
            UFNF PCNFBASESAID.UF%TYPE,
            FINALIDADENFE PCNFSAID.FINALIDADENFE%TYPE,
            SITUACAOTRIBUTARIA PCNFBASESAID.SITTRIBUT%TYPE,
            NUMTRANSOPERACAO PCNFBASESAID.NUMTRANSVENDA%TYPE,
            TIPOFRETE PCNFSAID.TIPOFRETE%TYPE,
            CODCONTAGERENCIAL PCNFSAID.CODCONT%TYPE,
            CODCONTACLIENTE PCCLIENT.CODCONTAB%TYPE,
            CONTACONTABIL PCCONTA.CONTACONTABIL%TYPE,
            CODREMETENTEFRETE PCNFSAID.CODREMETENTEFRETE%TYPE,
            VALOROUTRASDESPESAS PCNFBASESAID.VLOUTRASDESP%TYPE,
            MODELONFE VARCHAR2 (10),
            CONTAREMETENTEFRETE PCMODELOPC.CODREDUZIDO_PC%TYPE,
            TEMINTEGRACAO VARCHAR2 (1),
            VALORFCEP PCNFBASESAID.VLFECP%TYPE,
            VALORACRESCIMOFUNCEP PCNFBASESAID.VLACRESCIMOFUNCEP%TYPE,
            VALORICMSBCR PCNFBASESAID.VLICMSBCR%TYPE,
            VALORSTBCR PCNFBASESAID.VLSTBCR%TYPE
        );

        ITEM               CONSULTA_SAIDAS;
        ITENSREGRA         CONSULTA_ITENS;

        CURSOR_ITENS       SYS_REFCURSOR;

        FILIAIS_LANCADAS   TABELAFILIAISLANCTO;
        FILIAIS            FILIAISLANCTO;
        VS_CONTA_EXISTE    VARCHAR2 (1);
    BEGIN
        LISTA_FORMULAS := TYPE_LISTA_FORMULAS ();

        FILIAIS_LANCADAS := TABELAFILIAISLANCTO ();

        VS_SEQGERADO := 'N';
        VS_FORMADTCONTABILIZACAO := '';
        VN_NUMTRANSACAO := 0;
        VS_DOCUMENTO := '';
        VS_TEMCONTAINEXISTENTE := 'N';

        --BUSCA DADOS DA REGRA
        SELECT FORMADTCONTABILIZACAO
          INTO VS_FORMADTCONTABILIZACAO
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        V_SQLERRO := 'ABRINDO SAIDAS';

        --INICIA LAÇO DOS DADOS
        LOOP
            FETCH CURSOR_DADOS INTO ITEM;

            EXIT WHEN CURSOR_DADOS%NOTFOUND;

            IF    (ITEM.TEMINTEGRACAO IS NULL)
               OR (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                   AND (ITEM.TEMINTEGRACAO = 'P'))
            THEN
                --------------------------------------------------------------------
                --VERIFICA SE ALTEROU O NUMTRANSOPERACAO PARA FAZER GRAVAÇÃO E RE-INICIAR VARIÁVEIS
                IF (VN_NUMTRANSOPERACAO <> ITEM.NUMTRANSOPERACAO)
                THEN
                    VS_SEQGERADO := 'N';

                    IF (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                        AND (ITEM.TEMINTEGRACAO = 'P'))
                    THEN
                        P_EXCLUI_LANCINTERMEDIARIA_IND (
                            PCODREGRA,
                            ITEM.NUMTRANSOPERACAO,
                            ITEM.DATAOPERACAO);
                    END IF;

                    --VERIFICA SE JÁ PASSOU POR ALGUM REGISTRO PARA ATRIBUIR INCONSISTÊNCIAS
                    IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) >
                       0
                    THEN
                        ---------------------------------------------------------------------------------
                        V_SQLERRO :=
                            '20 - SAIDAS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
                        ---------------------------------------------------------------------------------
                        P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                                    VD_DATALANCTO,
                                                    VS_TEMCONTAINEXISTENTE,
                                                    VN_TOTALDEBITO,
                                                    VN_TOTALCREDITO,
                                                    'N');
                    END IF;

                    VS_TEMCONTAINEXISTENTE := 'N';
                END IF;

                --------------------------------------------------------------------

                --GERA NOVO NUMTRANSLANCTO
                IF VS_SEQGERADO = 'N'
                THEN
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '20 - SAIDAS: EXECUTANDO FUNÇÃO GERA_NUM_TRANS_LANCTO()';
                    ---------------------------------------------------------------------------------
                    VN_NUMTRANSACAO := F_GERA_NUM_TRANS_LANCTO ();

                    VN_NUMSEQ := 0;
                    VN_TOTALCREDITO := 0;
                    VN_TOTALDEBITO := 0;
                    VS_SEQGERADO := 'S';

                    CONTASDEBLANCTO := CONTAS_LANCADAS ();
                    CONTASCRELANCTO := CONTAS_LANCADAS ();
                    CGCSLANCTO := CGC_LANCADOS ();
                    VS_LISTAS_TRANSOTORIAS := CONTAS_LANCADAS ();

                    CONTASDEBLANCTO.EXTEND;
                    CONTASCRELANCTO.EXTEND;
                END IF;

                VD_DATALANCTO :=
                    F_RETORNA_DATA_LANCPROVISOES (2,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO);

                VD_DATAINTEGRACAO :=
                    F_RETORNA_DATA_LANCPROVISOES (2,
                                                  PCODREGRA,
                                                  DATA_INTEGRACAO,
                                                  ITEM.DATAOPERACAO);

                --LAÇO NOS ITENS DA REGRA CONTABIL
                OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL ()
                    USING PCODREGRA;

                LOOP
                    FETCH CURSOR_ITENS INTO ITENSREGRA;

                    EXIT WHEN CURSOR_ITENS%NOTFOUND;

                    ---------------------------------------------------------------------------------
                    V_SQLERRO := '20 - SAIDAS: ATRIBUINDO VALOR DO DOCUMENTO';
                    ---------------------------------------------------------------------------------
                    VS_DOCUMENTO := ITENSREGRA.DOCUMENTO;
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO',
                                 TO_CHAR (ITEM.DATAOPERACAO, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'NUMNOTANF', ITEM.NUMNOTANF);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMTRANSOPERACAO',
                                 ITEM.NUMTRANSOPERACAO);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'CODCONTAGERENCIAL',
                                 ITEM.CODCONTAGERENCIAL);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'SITUACAOTRIBUTARIA',
                                 ITEM.SITUACAOTRIBUTARIA);

                    --FORMULA INFORMADA NO FILTRO--------------------------------------------------------
                    ---------------------------------------------------------------------------------
                    V_SQLERRO := '20 - SAIDAS: ATRIBUINDO VALOR DA FÓRMULA';
                    ---------------------------------------------------------------------------------
                    VN_VALORLANCTO := 0;

                    VS_FORMULA := ITENSREGRA.FORMULAS || ' + 0 ';
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORTOTAL([^_[:alnum:]])',
                                        NVL (ITEM.VALORTOTAL, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORICMS([^_[:alnum:]])',
                                        NVL (ITEM.VALORICMS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORPIS([^_[:alnum:]])',
                                        NVL (ITEM.VALORPIS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORCOFINS([^_[:alnum:]])',
                                        NVL (ITEM.VALORCOFINS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORISENTAS([^_[:alnum:]])',
                                        NVL (ITEM.VALORISENTAS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALOROUTRAS([^_[:alnum:]])',
                                        NVL (ITEM.VALOROUTRAS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORFRETE([^_[:alnum:]])',
                                        NVL (ITEM.VALORFRETE, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORIPI([^_[:alnum:]])',
                                        NVL (ITEM.VALORIPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORIMPESTADUAL([^_[:alnum:]])',
                            NVL (ITEM.VALORIMPESTADUAL, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORREPASSE([^_[:alnum:]])',
                                        NVL (ITEM.VALORREPASSE, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORSUBSTRETENCAO([^_[:alnum:]])',
                            NVL (ITEM.VALORSUBSTRETENCAO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORISENTAS_DAPI([^_[:alnum:]])',
                            NVL (ITEM.VALORISENTAS_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORNAOTRIB_DAPI([^_[:alnum:]])',
                            NVL (ITEM.VALORNAOTRIB_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORBASERED_DAPI([^_[:alnum:]])',
                            NVL (ITEM.VALORBASERED_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORSUSPENSAS_DAPI([^_[:alnum:]])',
                            NVL (ITEM.VALORSUSPENSAS_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORST_DAPI([^_[:alnum:]])',
                                        NVL (ITEM.VALORST_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALOROUTRAS_DAPI([^_[:alnum:]])',
                            NVL (ITEM.VALOROUTRAS_DAPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORISENTASIPI([^_[:alnum:]])',
                            NVL (ITEM.VALORISENTASIPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALOROUTRASIPI([^_[:alnum:]])',
                                        NVL (ITEM.VALOROUTRASIPI, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORST([^_[:alnum:]])',
                                        NVL (ITEM.VALORST, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORCREDPRESUMIDO([^_[:alnum:]])',
                            NVL (ITEM.VALORCREDPRESUMIDO, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALOROUTRASDESPESAS([^_[:alnum:]])',
                            NVL (ITEM.VALOROUTRASDESPESAS, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORFUNDOCOMBPOBREZA([^_[:alnum:]])',
                            NVL (ITEM.VALORFUNDOCOMBPOBREZA, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORICMSDIFALIQPARTILHA([^_[:alnum:]])',
                            NVL (ITEM.VALORICMSDIFALIQPARTILHA, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORICMSUFDEST([^_[:alnum:]])',
                            NVL (ITEM.VALORICMSUFDEST, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORICMSUFREM([^_[:alnum:]])',
                                        NVL (ITEM.VALORICMSUFREM, 0) || '\1');

                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORFECP([^_[:alnum:]])',
                                        NVL (ITEM.VALORFCEP, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (
                            VS_FORMULA,
                            'VALORACRESCIMOFUNCEP([^_[:alnum:]])',
                            NVL (ITEM.VALORACRESCIMOFUNCEP, 0) || '\1');

                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORICMSBCR([^_[:alnum:]])',
                                        NVL (ITEM.VALORICMSBCR, 0) || '\1');
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORSTBCR([^_[:alnum:]])',
                                        NVL (ITEM.VALORSTBCR, 0) || '\1');

                    CALCULAREXPRESSAO;

                    --FIM DA FÓRMULA---------------------------------------------------------------------

                    IF VN_VALORLANCTO > 0
                    THEN
                        VS_CONTA := TRIM (ITENSREGRA.CODREDUZIDO_PC);
                        VS_CODFILIAL :=
                            CASE
                                WHEN ITENSREGRA.CODFILIAL =
                                     'FILIALLANCAMENTO'
                                THEN
                                    ITEM.CODFILIAL
                                ELSE
                                    ITENSREGRA.CODFILIAL
                            END;


                        IF     (SUBSTR (VS_CONTA, 1, 1) <> '0')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '1')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '2')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '3')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '4')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '5')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '6')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '7')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '8')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '9')
                        THEN
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTACLIENTE',
                                         ITEM.CODCONTACLIENTE);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CONTACONTABIL',
                                         ITEM.CONTACONTABIL);
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CONTAREMETENTEFRETE',
                                         ITEM.CONTAREMETENTEFRETE);
                        END IF;

                        VS_CONTA_EXISTE :=
                            F_VERIFICA_CONTA_EXISTE (VS_CONTA,
                                                     PCODPLANOCONTA);
                        TRATAR_CONTA_INEXISTENTE (VS_CONTA_EXISTE,
                                                  VS_TEMCONTAINEXISTENTE);

                        IF VS_CONTA_EXISTE IN ('S', 'I', 'X')
                        THEN
                            --HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO---------------------------------------
                            ---------------------------------------------------------------------------------
                            V_SQLERRO :=
                                '20 - SAIDAS: ATRIBUINDO VALOR DE HISTÓRICOS';
                            ---------------------------------------------------------------------------------
                            VS_HISTORICO := ITENSREGRA.HISTCOMPLREGRA;
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO]',
                                         ITEM.DATAOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMNOTANF]',
                                         ITEM.NUMNOTANF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODFISCALNF]',
                                         ITEM.CODFISCALNF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[ESPECIENF]',
                                         ITEM.ESPECIENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CLIENTENF]',
                                         ITEM.CLIENTENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODCLIENTENF]',
                                         ITEM.CODCLIENTENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CLIENTEDESTINATARIO]',
                                         ITEM.CLIENTEDESTINATARIO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[SERIENF]',
                                         ITEM.SERIENF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO, '[UFNF]', ITEM.UFNF);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMTRANSOPERACAO]',
                                         ITEM.NUMTRANSOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODCONTAGERENCIAL]',
                                         ITEM.CODCONTAGERENCIAL);
                            VS_HISTORICO := SUBSTR (VS_HISTORICO, 1, 200);

                            --FIM HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO-----------------------------------

                            IF ITENSREGRA.NATUREZA = 'C'
                            THEN
                                VN_TOTALCREDITO :=
                                    ROUND (
                                          VN_TOTALCREDITO
                                        + ABS (VN_VALORLANCTO),
                                        2);
                                VS_NATUREZA := 'C';
                            ELSE
                                VN_TOTALDEBITO :=
                                    ROUND (
                                        VN_TOTALDEBITO + ABS (VN_VALORLANCTO),
                                        2);
                                VS_NATUREZA := 'D';
                            END IF;

                            --GUARDA FILIAIS
                            FILIAIS.CODFILIAL := '-1';

                            FOR VN_POSICAO IN 1 .. FILIAIS_LANCADAS.COUNT
                            LOOP
                                IF (FILIAIS_LANCADAS (VN_POSICAO).CODFILIAL =
                                    VS_CODFILIAL)
                                THEN
                                    FILIAIS := FILIAIS_LANCADAS (VN_POSICAO);
                                    VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

                                    EXIT;
                                END IF;
                            END LOOP;

                            IF (FILIAIS.CODFILIAL = '-1')
                            THEN
                                FILIAIS_LANCADAS.EXTEND;

                                FILIAIS :=
                                    FILIAIS_LANCADAS (FILIAIS_LANCADAS.COUNT);
                                VN_POSICAO_EM_ALTERACAO :=
                                    FILIAIS_LANCADAS.COUNT;

                                FILIAIS.CODFILIAL := VS_CODFILIAL;
                                FILIAIS.CGCFILIAL :=
                                    F_CGCFILIAL (VS_CODFILIAL);

                                FILIAIS_LANCADAS (VN_POSICAO_EM_ALTERACAO) :=
                                    FILIAIS;
                            END IF;

                            --GUARDA AS CONTAS PARA VERIFICAR SE ESTÃO IGUAIS POSTERIORMENTE
                            P_ARMAZENA_CONTAS_FILIAIS_LANC (VS_CONTA,
                                                            VS_NATUREZA,
                                                            VS_CODFILIAL,
                                                            FILIAIS_LANCADAS);

                            IF 'N' = 'S'
                            THEN
                                NULL;
                            ELSE
                                ---------------------------------------------------------------------------------
                                V_SQLERRO :=
                                    '20 - SAIDAS: EXECUTANDO PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA()';
                                ---------------------------------------------------------------------------------
                                --INSERE DADOS NA TABELA QUANDO NÃO ESTÁ TOTALIZANDO VALORES
                                VN_NUMSEQ := VN_NUMSEQ + 1;

                                P_GRAVA_DADOS_TABINTERMEDIARIA (
                                    VS_CODFILIAL,
                                    VN_NUMTRANSACAO,
                                    VN_NUMSEQ,
                                    VD_DATALANCTO,
                                    VS_DOCUMENTO,
                                    ITENSREGRA.CODHISTORICO,
                                    VS_HISTORICO,
                                    PCODPLANOCONTA,
                                    VS_CONTA,
                                    VS_NATUREZA,
                                    VN_VALORLANCTO,
                                    PCODREGRA,
                                    '',
                                    ITEM.NUMTRANSOPERACAO,
                                    F_RETORNA_TIPO_INCONSISTENCIA (
                                        VS_TEMCONTAINEXISTENTE),
                                    'P',
                                    ITEM.DATAOPERACAO,
                                    ITEM.CODFISCALNF,
                                    0,
                                    '',
                                    '',
                                    VD_DATAINTEGRACAO,
                                    ITEM.CODCLIENTENF,
                                    'C',
                                    NULL,
                                    ITEM.NUMTRANSOPERACAO,
                                    '',
                                    ITENSREGRA.FORMULAS,
                                    ITENSREGRA.CODREDUZIDO_PC,
                                    'SAIDA',
                                    'PCNFSAID',
                                    ITENSREGRA.TOTALIZAVALOR);
                            END IF;
                        END IF;
                    END IF;
                END LOOP;

                --GUARDA O NÚMERO DA TRANSAÇÃO
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            ELSE
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            END IF;
        END LOOP;

        --VERIFICA CONSISTÊNCIAS DO ÚLTIMO REGISTRO
        IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '20 - SAIDAS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
            ---------------------------------------------------------------------------------
            P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                        VD_DATALANCTO,
                                        VS_TEMCONTAINEXISTENTE,
                                        VN_TOTALDEBITO,
                                        VN_TOTALCREDITO,
                                        'N');
        END IF;

        CLOSE CURSOR_DADOS;

        RESULTADO := 'OK';
    EXCEPTION
        WHEN OTHERS
        THEN
            RESULTADO :=
                   'Ocorreu um erro quando: '
                || V_SQLERRO
                || CHR (13)
                || 'Erro Original: '
                || SQLERRM;
    END;


PROCEDURE P_DADOS_PROV_TECHFIN (CURSOR_DADOS     IN     SYS_REFCURSOR,
                                PCODREGRA        IN     NUMBER,
                                PCODPLANOCONTA   IN     NUMBER,
                                RESULTADO           OUT VARCHAR2)
    IS
        TYPE CONSULTA_PROV_TECHFIN IS RECORD
        (
            CODCLI PCCLIENT.CODCLI%TYPE,
            CODFILIAL PCFILIAL.CODIGO%TYPE,
            TIPOLANCAMENTO PCPROVLANCTECHFIN.TIPOLANCAMENTO%TYPE,
            MOTIVO PCPROVLANCTECHFIN.MOTIVO%TYPE,
            ERPID PCPROVLANCTECHFIN.ERPID%TYPE,
            NUMTRANSVENDA PCPROVLANCTECHFIN.NUMTRANSVENDA%TYPE,
            NUMNOTA PCPROVLANCTECHFIN.NUMNOTA%TYPE,
            DATAOPERACAO DATE,
            CODCONTADESP PCMODELOPC.CODREDUZIDO_PC%TYPE,
            VALOR PCPROVLANCTECHFIN.VALOR%TYPE, 
            NUMTRANSOPERACAO PCLANCINTERMEDIARIA.NUMTRANSOPERACAO%TYPE,
            TEMINTEGRACAO PCLANCINTERMEDIARIA.STATUS%TYPE
        );

        ITEM               CONSULTA_PROV_TECHFIN;
        ITENSREGRA         CONSULTA_ITENS;

        CURSOR_ITENS       SYS_REFCURSOR;

        FILIAIS_LANCADAS   TABELAFILIAISLANCTO;
        FILIAIS            FILIAISLANCTO;
        VS_CONTA_EXISTE    VARCHAR2 (1);
    BEGIN
        LISTA_FORMULAS := TYPE_LISTA_FORMULAS ();

        FILIAIS_LANCADAS := TABELAFILIAISLANCTO ();

        VS_SEQGERADO := 'N';
        VS_FORMADTCONTABILIZACAO := '';
        VN_NUMTRANSACAO := 0;
        VS_DOCUMENTO := '';
        VS_TEMCONTAINEXISTENTE := 'N';

        --BUSCA DADOS DA REGRA
        SELECT FORMADTCONTABILIZACAO
          INTO VS_FORMADTCONTABILIZACAO
          FROM PCREGRACONTABIL
         WHERE CODREGRA = PCODREGRA;

        V_SQLERRO := 'ABRINDO SAIDAS';

        --INICIA LAÇO DOS DADOS
        LOOP
            FETCH CURSOR_DADOS INTO ITEM;

            EXIT WHEN CURSOR_DADOS%NOTFOUND;

            IF    (ITEM.TEMINTEGRACAO IS NULL)
               OR (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                   AND (ITEM.TEMINTEGRACAO = 'P'))
            THEN
                --------------------------------------------------------------------
                --VERIFICA SE ALTEROU O NUMTRANSOPERACAO PARA FAZER GRAVAÇÃO E RE-INICIAR VARIÁVEIS
                IF (VN_NUMTRANSOPERACAO <> ITEM.NUMTRANSOPERACAO)
                THEN
                    VS_SEQGERADO := 'N';

                    IF (    (ITEM.TEMINTEGRACAO IS NOT NULL)
                        AND (ITEM.TEMINTEGRACAO = 'P'))
                    THEN
                        P_EXCLUI_LANCINTERMEDIARIA_IND (
                            PCODREGRA,
                            ITEM.NUMTRANSOPERACAO,
                            ITEM.DATAOPERACAO);
                    END IF;

                    --VERIFICA SE JÁ PASSOU POR ALGUM REGISTRO PARA ATRIBUIR INCONSISTÊNCIAS
                    IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) >
                       0
                    THEN
                        ---------------------------------------------------------------------------------
                        V_SQLERRO :=
                            '20 - SAIDAS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
                        ---------------------------------------------------------------------------------
                        P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                                    VD_DATALANCTO,
                                                    VS_TEMCONTAINEXISTENTE,
                                                    VN_TOTALDEBITO,
                                                    VN_TOTALCREDITO,
                                                    'N');
                    END IF;

                    VS_TEMCONTAINEXISTENTE := 'N';
                END IF;

                --------------------------------------------------------------------

                --GERA NOVO NUMTRANSLANCTO
                IF VS_SEQGERADO = 'N'
                THEN
                    ---------------------------------------------------------------------------------
                    V_SQLERRO :=
                        '20 - SAIDAS: EXECUTANDO FUNÇÃO GERA_NUM_TRANS_LANCTO()';
                    ---------------------------------------------------------------------------------
                    VN_NUMTRANSACAO := F_GERA_NUM_TRANS_LANCTO ();

                    VN_NUMSEQ := 0;
                    VN_TOTALCREDITO := 0;
                    VN_TOTALDEBITO := 0;
                    VS_SEQGERADO := 'S';

                    CONTASDEBLANCTO := CONTAS_LANCADAS ();
                    CONTASCRELANCTO := CONTAS_LANCADAS ();
                    CGCSLANCTO := CGC_LANCADOS ();
                    VS_LISTAS_TRANSOTORIAS := CONTAS_LANCADAS ();

                    CONTASDEBLANCTO.EXTEND;
                    CONTASCRELANCTO.EXTEND;
                END IF;

                VD_DATALANCTO :=
                    F_RETORNA_DATA_LANCPROVISOES (2,
                                                  PCODREGRA,
                                                  DATA_LANCAMENTO,
                                                  ITEM.DATAOPERACAO);

                VD_DATAINTEGRACAO :=
                    F_RETORNA_DATA_LANCPROVISOES (2,
                                                  PCODREGRA,
                                                  DATA_INTEGRACAO,
                                                  ITEM.DATAOPERACAO);

                --LAÇO NOS ITENS DA REGRA CONTABIL
                OPEN CURSOR_ITENS FOR F_ITENS_REGRA_CONTABIL ()
                    USING PCODREGRA;

                LOOP
                    FETCH CURSOR_ITENS INTO ITENSREGRA;

                    EXIT WHEN CURSOR_ITENS%NOTFOUND;

                    ---------------------------------------------------------------------------------
                    V_SQLERRO := '20 - SAIDAS: ATRIBUINDO VALOR DO DOCUMENTO';
                    ---------------------------------------------------------------------------------
                    VS_DOCUMENTO := ITENSREGRA.DOCUMENTO;
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'DATAOPERACAO',
                                 TO_CHAR (ITEM.DATAOPERACAO, 'DD-MM-YYYY'));
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO, 'ERPID', ITEM.ERPID);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMTRANSVENDA',
                                 ITEM.NUMTRANSVENDA);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'CODCLI',
                                 ITEM.CODCLI);
                    VS_DOCUMENTO :=
                        REPLACE (VS_DOCUMENTO,
                                 'NUMNOTA',
                                 ITEM.NUMNOTA);             


                    --FORMULA INFORMADA NO FILTRO--------------------------------------------------------
                    ---------------------------------------------------------------------------------
                    V_SQLERRO := '20 - SAIDAS: ATRIBUINDO VALOR DA FÓRMULA';
                    ---------------------------------------------------------------------------------
                    VN_VALORLANCTO := 0;

                    VS_FORMULA := ITENSREGRA.FORMULAS || ' + 0 ';
                    VS_FORMULA :=
                        REGEXP_REPLACE (VS_FORMULA,
                                        'VALORTITULO([^_[:alnum:]])',
                                        NVL (ITEM.VALOR, 0) || '\1');
                    

                    CALCULAREXPRESSAO;

                    --FIM DA FÓRMULA---------------------------------------------------------------------

                    IF VN_VALORLANCTO > 0
                    THEN
                        VS_CONTA := TRIM (ITENSREGRA.CODREDUZIDO_PC);
                        VS_CODFILIAL :=
                            CASE
                                WHEN ITENSREGRA.CODFILIAL =
                                     'FILIALLANCAMENTO'
                                THEN
                                    ITEM.CODFILIAL
                                ELSE
                                    ITENSREGRA.CODFILIAL
                            END;


                        IF     (SUBSTR (VS_CONTA, 1, 1) <> '0')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '1')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '2')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '3')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '4')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '5')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '6')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '7')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '8')
                           AND (SUBSTR (VS_CONTA, 1, 1) <> '9')
                        THEN
                            VS_CONTA :=
                                REPLACE (VS_CONTA,
                                         'CODCONTADESP',
                                         ITEM.CODCONTADESP);
                        END IF;

                        VS_CONTA_EXISTE :=
                            F_VERIFICA_CONTA_EXISTE (VS_CONTA,
                                                     PCODPLANOCONTA);
                        TRATAR_CONTA_INEXISTENTE (VS_CONTA_EXISTE,
                                                  VS_TEMCONTAINEXISTENTE);

                        IF VS_CONTA_EXISTE IN ('S', 'I', 'X')
                        THEN
                            --HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO---------------------------------------
                            ---------------------------------------------------------------------------------
                            V_SQLERRO :=
                                '20 - SAIDAS: ATRIBUINDO VALOR DE HISTÓRICOS';
                            ---------------------------------------------------------------------------------
                            VS_HISTORICO := ITENSREGRA.HISTCOMPLREGRA;
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[DATAOPERACAO]',
                                         ITEM.DATAOPERACAO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[ERPID]',
                                         ITEM.ERPID);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMTRANSVENDA]',
                                         ITEM.NUMTRANSVENDA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMNOTA]',
                                         ITEM.NUMNOTA);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[TIPOLANCAMENTO]',
                                         ITEM.TIPOLANCAMENTO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[MOTIVO]',
                                         ITEM.MOTIVO);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[CODCLI]',
                                         ITEM.CODCLI);
                            VS_HISTORICO :=
                                REPLACE (VS_HISTORICO,
                                         '[NUMTRANSOPERACAO]',
                                         ITEM.NUMTRANSOPERACAO);             
                          
                            VS_HISTORICO := SUBSTR (VS_HISTORICO, 1, 200);

                            --FIM HISTÓRICO COMPLEMENTAR INFORMADA NO FILTRO-----------------------------------

                            IF ITENSREGRA.NATUREZA = 'C'
                            THEN
                                VN_TOTALCREDITO :=
                                    ROUND (
                                          VN_TOTALCREDITO
                                        + ABS (VN_VALORLANCTO),
                                        2);
                                VS_NATUREZA := 'C';
                            ELSE
                                VN_TOTALDEBITO :=
                                    ROUND (
                                        VN_TOTALDEBITO + ABS (VN_VALORLANCTO),
                                        2);
                                VS_NATUREZA := 'D';
                            END IF;

                            --GUARDA FILIAIS
                            FILIAIS.CODFILIAL := '-1';

                            FOR VN_POSICAO IN 1 .. FILIAIS_LANCADAS.COUNT
                            LOOP
                                IF (FILIAIS_LANCADAS (VN_POSICAO).CODFILIAL =
                                    VS_CODFILIAL)
                                THEN
                                    FILIAIS := FILIAIS_LANCADAS (VN_POSICAO);
                                    VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

                                    EXIT;
                                END IF;
                            END LOOP;

                            IF (FILIAIS.CODFILIAL = '-1')
                            THEN
                                FILIAIS_LANCADAS.EXTEND;

                                FILIAIS :=
                                    FILIAIS_LANCADAS (FILIAIS_LANCADAS.COUNT);
                                VN_POSICAO_EM_ALTERACAO :=
                                    FILIAIS_LANCADAS.COUNT;

                                FILIAIS.CODFILIAL := VS_CODFILIAL;
                                FILIAIS.CGCFILIAL :=
                                    F_CGCFILIAL (VS_CODFILIAL);

                                FILIAIS_LANCADAS (VN_POSICAO_EM_ALTERACAO) :=
                                    FILIAIS;
                            END IF;

                            --GUARDA AS CONTAS PARA VERIFICAR SE ESTÃO IGUAIS POSTERIORMENTE
                            P_ARMAZENA_CONTAS_FILIAIS_LANC (VS_CONTA,
                                                            VS_NATUREZA,
                                                            VS_CODFILIAL,
                                                            FILIAIS_LANCADAS);

                            IF 'N' = 'S'
                            THEN
                                NULL;
                            ELSE
                                ---------------------------------------------------------------------------------
                                V_SQLERRO :=
                                    '20 - SAIDAS: EXECUTANDO PROCEDURE P_GRAVA_DADOS_TABINTERMEDIARIA()';
                                ---------------------------------------------------------------------------------
                                --INSERE DADOS NA TABELA QUANDO NÃO ESTÁ TOTALIZANDO VALORES
                                VN_NUMSEQ := VN_NUMSEQ + 1;

                                P_GRAVA_DADOS_TABINTERMEDIARIA (
                                    VS_CODFILIAL,
                                    VN_NUMTRANSACAO,
                                    VN_NUMSEQ,
                                    VD_DATALANCTO,
                                    VS_DOCUMENTO,
                                    ITENSREGRA.CODHISTORICO,
                                    VS_HISTORICO,
                                    PCODPLANOCONTA,
                                    VS_CONTA,
                                    VS_NATUREZA,
                                    VN_VALORLANCTO,
                                    PCODREGRA,
                                    '',
                                    ITEM.NUMTRANSOPERACAO,
                                    F_RETORNA_TIPO_INCONSISTENCIA (
                                        VS_TEMCONTAINEXISTENTE),
                                    'P',
                                    ITEM.DATAOPERACAO,
                                    0,
                                    0,
                                    '',
                                    '',
                                    VD_DATAINTEGRACAO,
                                    0,
                                    '',
                                    NULL,
                                    ITEM.NUMTRANSOPERACAO,
                                    '',
                                    ITENSREGRA.FORMULAS,
                                    ITENSREGRA.CODREDUZIDO_PC,
                                    'PROVTECH',
                                    'PCPROVLANCTECHFIN',
                                    ITENSREGRA.TOTALIZAVALOR);
                            END IF;
                        END IF;
                    END IF;
                END LOOP;

                --GUARDA O NÚMERO DA TRANSAÇÃO
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            ELSE
                VN_NUMTRANSOPERACAO := ITEM.NUMTRANSOPERACAO;
            END IF;
        END LOOP;

        --VERIFICA CONSISTÊNCIAS DO ÚLTIMO REGISTRO
        IF ROUND (VN_TOTALDEBITO, 2) + ROUND (VN_TOTALCREDITO, 2) > 0
        THEN
            ---------------------------------------------------------------------------------
            V_SQLERRO :=
                '20 - SAIDAS: EXECUTANDO PROCEDURE P_VERIFICA_INCONSISTENCIAS()';
            ---------------------------------------------------------------------------------
            P_VERIFICA_INCONSISTENCIAS (VN_NUMTRANSACAO,
                                        VD_DATALANCTO,
                                        VS_TEMCONTAINEXISTENTE,
                                        VN_TOTALDEBITO,
                                        VN_TOTALCREDITO,
                                        'N');
        END IF;

        CLOSE CURSOR_DADOS;

        RESULTADO := 'OK';
    EXCEPTION
        WHEN OTHERS
        THEN
            RESULTADO :=
                   'Ocorreu um erro quando: '
                || V_SQLERRO
                || CHR (13)
                || 'Erro Original: '
                || SQLERRM;
    END;


    
END PKG_INTEGRACAOCONTABIL;
--19/09/2012 - Eduardo
