CREATE OR REPLACE PROCEDURE P_CTBIMPORTACAO(PCODFILIAL IN VARCHAR,
                                            PCODREGRA  IN NUMERIC,
                                            PDTINICIO  IN DATE,
                                            PDTFINAL   IN DATE,
                                            PCODFUNC   IN NUMERIC,
                                            PCAMPOSJOINCC IN VARCHAR,
                                            RETORNO    OUT STRING) IS

  -----------------------------------------------------------------------------
  -- CURSOR
  -----------------------------------------------------------------------------
  TYPE REG_CRIMP IS RECORD (
    DTMOVIMENTO DATE,
    VALORLANCTO PCLANCAMENTO.VALOR%TYPE,
    HISTORICO_COMP PCLANCAMENTO.HISTORICO_COMPL%TYPE,
    DOCUMENTO PCLANCAMENTO.DOCUMENTO%TYPE,
    CODCONTACRED PCMODELOPC.CODREDUZIDO_PC%TYPE,
    CODCONTADEB PCMODELOPC.CODREDUZIDO_PC%TYPE,
    RECNUM PCLANC.RECNUM%TYPE,
    RECNUMPRINC PCLANC.RECNUMPRINC%TYPE
  );
  TYPE REF_CRIMP IS REF CURSOR RETURN REG_CRIMP;

  TYPE CENTRO_CUSTO IS RECORD(
    CODFILIAL         VARCHAR2(2),
    PERCRATEIO        NUMBER(5,2),
    VALOR             NUMBER(22,4),
    CODIGOCENTROCUSTO VARCHAR2(30)
  );

  --RECORD PARA TOTALIZAÇÃO CENTRO DE CUSTOS
  TYPE VALORES_CENTROCUSTO IS RECORD(
    CODFILIAL           VARCHAR2(2),
    CODIGOCENTROCUSTO   VARCHAR2(40),
    PERCRATEIO          NUMBER(6,2),
    VALOR               NUMBER(12,2)
    );

  TYPE TABELAVALORES_CENTROCUSTO IS TABLE OF VALORES_CENTROCUSTO;

  -----------------------------------------------------------------------------
  -- CURSOR
  -----------------------------------------------------------------------------
  CRIMP REF_CRIMP;
  CR REG_CRIMP;

  -----------------------------------------------------------------------------
  -- CURSOR QUE CONTÉM OS LANCAMENTOS PAIS....
  -----------------------------------------------------------------------------
  V_CODPLANOCONTA    PCREGRAINTEGRACAOCTB.CODPLANOCONTA%TYPE;
  V_CODREDUZIDO_DB   PCREGRAINTEGRACAOCTB.CODREDUZIDO_DB%TYPE;
  V_CODREDUZIDO_CR   PCREGRAINTEGRACAOCTB.CODREDUZIDO_CR%TYPE;
  V_CODHISTORICO     PCREGRAINTEGRACAOCTB.CODHISTORICO%TYPE;
  V_HISTORICO_DESC   PCREGRAINTEGRACAOCTB.HISTORICO_COMPL%TYPE;
  V_HISTORICO_COMPL  PCREGRAINTEGRACAOCTB.HISTORICO_COMPL%TYPE;
  V_SCRIPTSQL        PCREGRAINTEGRACAOCTB.SCRIPTSQL%TYPE;
  V_NUMLANCTO        PCLANCAMENTO.NUMLANCTO%TYPE;
  V_SEQLOG           PCLOGINTEGRACAOCTB.CODLOGINTEGRACAO%TYPE;
  V_MSG              VARCHAR2(4000);
  V_DTCALCULO        DATE;
  V_STATUSPERIODO    VARCHAR2(50);
  V_RECEBE_LANCTO    VARCHAR2(1);
  V_QTLOGENCONTRADOS NUMERIC;
  V_QTLOGREGISTROS   NUMERIC;
  V_QTCONTA          NUMERIC;
  V_VALORLANCTO      NUMBER(20,2);
  VN_ANOATUAL        NUMBER;
  V_SQLAUX           VARCHAR2(2000);
--  VS_MESBLOQ         VARCHAR2(40);
  VS_MESESTABLOQUEADO  VARCHAR2(40);
  VS_DIAESTABLOQUEADO  VARCHAR2(1);
  VN_CONTADOR NUMBER(3) := 0;
  V_ERROCONTA EXCEPTION;
  V_ERROTABBLOQDIA EXCEPTION;  

  V_SEQ_NUMTRANSLANCTO_DEBITO  PCLANCAMENTO.NUMTRANSLANCTO%TYPE;
  V_SEQ_NUMTRANSLANCTO_CREDITO PCLANCAMENTO.NUMTRANSLANCTO%TYPE;
  V_SEQ_NUMTRANSLANCTO_CC      PCLANCAMENTO.NUMTRANSLANCTO%TYPE;
  V_DESTINORATEIOCC            PCREGRAINTEGRACAOCTB.DESTINORATEIOCC%TYPE;
  V_NATUREZACC                 PCRATEIOCONTABILCC.NATUREZA%TYPE;
  V_CONTA_DEBITO               PCLANCAMENTO.CODREDUZIDO_PC%TYPE;
  V_CONTA_CREDITO              PCLANCAMENTO.CODREDUZIDO_PC%TYPE;
  V_CONTA_USACENTROCUSTO       PCMODELOPC.USACENTROCUSTO%TYPE;
  V_UTILIZACENTROCUSTO         VARCHAR2(1);

  VALORES_POSSIVEIS_CENTROCUSTO TABELAVALORES_CENTROCUSTO;
  V_RECNUM_RECNUMPRINC         PCLANC.RECNUM%TYPE;
  VN_POSICAO NUMBER;
  V_QTLOGREGISTROS_CC   NUMERIC;
  
  V_CODCONTA_PC_CRED PCMODELOPC.CODCONTA_PC%TYPE;
  V_CODCONTA_PC_DEB  PCMODELOPC.CODCONTA_PC%TYPE;  

  -----------------------------------------------------------------------------
  
  PROCEDURE P_INSERE_LANCAMENTO_FILA(PCODFILIAL IN VARCHAR2,
                                     PCODPLANOCONTA IN NUMBER,
                                     PMES IN NUMBER,                         
                                     PANO IN NUMBER,  
                                     PCODREDUZIDO_PC IN VARCHAR2,              
                                     PCODCONTA_PC IN VARCHAR2,                  
                                     PVALORDEBITO IN NUMBER,                 
                                     PVALORCREDITO IN NUMBER,                
                                     PVLRDEBENCERRAMENTO IN NUMBER,          
                                     PVLRCREENCERRAMENTO IN NUMBER,          
                                     PVLRDEBCONCIL IN NUMBER,                
                                     PVLRCRECONCIL IN NUMBER,                
                                     PVLRDEBCONCILENCERRAMENTO IN NUMBER,    
                                     PVLRCRECONCILENCERRAMENTO IN NUMBER ) IS
  BEGIN
  
      INSERT INTO PCFILASALDOCNB       
      (CODIGO,                       
       CODFILIAL,                    
       CODPLANOCONTA,                
       MES,                          
       ANO,                          
       CODREDUZIDO_PC,               
       CODCONTA_PC,                  
       VALORDEBITO,                  
       VALORCREDITO,                 
       VLRDEBENCERRAMENTO,           
       VLRCREENCERRAMENTO,           
       VLRDEBCONCIL,                 
       VLRCRECONCIL,                 
       VLRDEBCONCILENCERRAMENTO,     
       VLRCRECONCILENCERRAMENTO,     
       EQUIPAMENTO,                  
       ROTINA,                       
       USUARIO,                      
       DATAHORA)                     
    VALUES                           
      (DFSEQ_PCFILASALDOCNB.NEXTVAL,
       PCODFILIAL,                   
       PCODPLANOCONTA,               
       PMES,                         
       PANO,                         
       PCODREDUZIDO_PC,              
       PCODCONTA_PC,                  
       PVALORDEBITO,                 
       PVALORCREDITO,                
       PVLRDEBENCERRAMENTO,          
       PVLRCREENCERRAMENTO,          
       PVLRDEBCONCIL,                
       PVLRCRECONCIL,                
       PVLRDEBCONCILENCERRAMENTO,    
       PVLRCRECONCILENCERRAMENTO,    
       SYS_CONTEXT('USERENV', 'TERMINAL'),    
       SYS_CONTEXT('USERENV', 'MODULE'),    
       SYS_CONTEXT('USERENV', 'OS_USER'),   
       SYSDATE);                    
  
  END;

  -----------------------------------------------------------------------------  

  FUNCTION CONCATENA_REC_NUMS(PRECNUMPRINC NUMBER) RETURN VARCHAR2 IS
    RETORNO VARCHAR2(2000);
    LINHA CENTRO_CUSTO;
    VIRGULA VARCHAR(1);
  BEGIN
    FOR LINHA IN (SELECT RECNUM FROM PCLANC WHERE PRECNUMPRINC IN (RECNUMPRINC,RECNUM))
    LOOP
      RETORNO := RETORNO || VIRGULA || LINHA.RECNUM;
      VIRGULA := ',';
    END LOOP;
    RETURN RETORNO;
  END;

  FUNCTION TOTALIZAR_CENTRO_CUSTO(RECNUMS VARCHAR2) RETURN NUMBER IS
    RCC_CURSOR SYS_REFCURSOR;
    RETORNO NUMBER;
  BEGIN
    OPEN RCC_CURSOR FOR 'SELECT SUM(VALOR) VALOR FROM PCRATEIOCENTROCUSTO WHERE RECNUM IN (' || RECNUMS || ')';
    LOOP
      FETCH RCC_CURSOR INTO RETORNO;
      EXIT;
    END LOOP;
    CLOSE RCC_CURSOR;
    RETURN RETORNO;
  END;

  FUNCTION CARREGA_VALORES_POSSIVEIS_CC(PRECNUM_RECNUMPRINC IN NUMERIC) RETURN TABELAVALORES_CENTROCUSTO IS
    RECNUMS VARCHAR2(4000);
    TOTAL      NUMBER;
    POS        NUMBER;

    CUR_RCC SYS_REFCURSOR;
    LINHA CENTRO_CUSTO;

    RETORNO  TABELAVALORES_CENTROCUSTO;
    LANCCC   VALORES_CENTROCUSTO;
  BEGIN

      IF PRECNUM_RECNUMPRINC > 0 THEN

        RECNUMS    := CONCATENA_REC_NUMS(PRECNUM_RECNUMPRINC);
        TOTAL      := TOTALIZAR_CENTRO_CUSTO(RECNUMS);
        RETORNO    := TABELAVALORES_CENTROCUSTO();

        IF TOTAL > 0 THEN
          OPEN CUR_RCC FOR ' SELECT CODFILIAL,0 PERCRATEIO,SUM(VALOR) VALOR,CODIGOCENTROCUSTO '
                        || ' FROM PCRATEIOCENTROCUSTO '
                        || ' WHERE RECNUM IN (' || RECNUMS || ') '
                        || ' GROUP BY CODFILIAL,CODIGOCENTROCUSTO';
          LOOP
            FETCH CUR_RCC INTO LINHA;
            EXIT WHEN CUR_RCC%NOTFOUND;

            POS := NVL(POS,0) + 1;

            LANCCC.CODFILIAL           := LINHA.CODFILIAL;
            LANCCC.PERCRATEIO          := 100*LINHA.VALOR/TOTAL;
            LANCCC.CODIGOCENTROCUSTO   := LINHA.CODIGOCENTROCUSTO;
            LANCCC.VALOR               := LINHA.VALOR;

            RETORNO.EXTEND;
            RETORNO(POS) := LANCCC;

          END LOOP;
          CLOSE CUR_RCC;

        END IF;
      END IF;

    RETURN RETORNO;

  END;

BEGIN
  V_MSG            := NULL;
  V_CODREDUZIDO_DB := NVL(V_CODREDUZIDO_DB, '0');
  V_CODREDUZIDO_CR := NVL(V_CODREDUZIDO_CR, '0');
  V_QTLOGREGISTROS_CC := 0;
  -----------------------------------------------------------------------------
  -- VERIFICANDO SE HÁ REGISTROS A IMPORTAR
  -----------------------------------------------------------------------------
  BEGIN
    SELECT COUNT(*)
    INTO   V_QTLOGREGISTROS
    FROM   V_CTBEXPIMP;
  EXCEPTION
    WHEN OTHERS THEN
      BEGIN
        V_QTLOGENCONTRADOS := 0;
      END;
  END;
  -----------------------------------------------------------------------------
  IF V_QTLOGREGISTROS <= 1
  THEN
    BEGIN
      SELECT VALORLANCTO
      INTO   V_VALORLANCTO
      FROM   V_CTBEXPIMP;
      IF NVL(V_VALORLANCTO, 0) = 0
      THEN
        V_MSG := 'Nenhum registro foi encontrado para integração';
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        BEGIN
          V_MSG := 'Nenhum registro foi encontrado para integração';
        END;
    END;
  END IF;
  -----------------------------------------------------------------------------
  -- VERIFICANDO SE PERIODO ESTÁ ENCERRADO
  -----------------------------------------------------------------------------
  IF V_MSG IS NULL
  THEN
    V_DTCALCULO := PDTINICIO;
    WHILE V_DTCALCULO < PDTFINAL
    LOOP
      SELECT F_CTBACEITALANCTO(PCODFILIAL, V_CODPLANOCONTA, V_DTCALCULO)
      INTO   V_STATUSPERIODO
      FROM   DUAL;
      IF (V_STATUSPERIODO = 'ENCERRADO_TOTAL')
         OR (V_STATUSPERIODO = 'ENCERRADO')
      THEN
        V_MSG := 'Período informado já está encerrado. Não será possivel efetuar a integração.';
        EXIT;
      ELSE
        V_DTCALCULO     := LAST_DAY(V_DTCALCULO) + 1;
        V_STATUSPERIODO := '';
      END IF;
    END LOOP;
  END IF;
  -----------------------------------------------------------------------------
  -- Verificando se o período já foi Importado
  -----------------------------------------------------------------------------
  IF V_MSG IS NULL
  THEN
    BEGIN
      SELECT COUNT(*)
      INTO   V_QTLOGENCONTRADOS
      FROM   PCLOGINTEGRACAOCTB
      WHERE  CODFILIAL = PCODFILIAL
      AND    CODREGRA = PCODREGRA
      AND    EXISTS
       (SELECT NUMLANCTO
              FROM   PCLANCAMENTO
              WHERE  CODLOGINTEGRACAO = PCLOGINTEGRACAOCTB.CODLOGINTEGRACAO
              AND    CODFILIAL = PCODFILIAL)
      AND    ((DTINICIO BETWEEN PDTINICIO AND PDTFINAL) OR
            (DTFINAL BETWEEN PDTINICIO AND PDTFINAL));
    EXCEPTION
      WHEN OTHERS THEN
        BEGIN
          V_QTLOGENCONTRADOS := 0;
        END;
    END;
    IF V_QTLOGENCONTRADOS > 0
    THEN
      V_MSG := 'Foi localizado integrações entre o período informado. Integração abortada.';
    END IF;
  END IF;
  -----------------------------------------------------------------------------
  -- PEGANDO INFORMAÇÕES DA REGRA CRIADA PARA EXPORTAÇÃO/IMPORTAÇÃO
  -----------------------------------------------------------------------------
  IF V_MSG IS NULL
  THEN
    BEGIN
      SELECT A.CODPLANOCONTA,
             A.CODREDUZIDO_DB,
             A.CODREDUZIDO_CR,
             A.CODHISTORICO,
             A.HISTORICO_COMPL,
             B.NOME_HISTORICO,
             A.SCRIPTSQL,
             A.DESTINORATEIOCC
      INTO   V_CODPLANOCONTA,
             V_CODREDUZIDO_DB,
             V_CODREDUZIDO_CR,
             V_CODHISTORICO,
             V_HISTORICO_COMPL,
             V_HISTORICO_DESC,
             V_SCRIPTSQL,
             V_DESTINORATEIOCC
      FROM   PCREGRAINTEGRACAOCTB A,
             PCHISTORICO          B
      WHERE  A.CODREGRA = PCODREGRA
      AND    A.CODHISTORICO = B.CODHISTORICO(+);
    EXCEPTION
      WHEN OTHERS THEN
        BEGIN
          V_MSG := 'Erro pesquisando informações de regra.';
        END;
    END;
  END IF;
  -----------------------------------------------------------------------------
  -- GERANDO LOG;
  -----------------------------------------------------------------------------
  IF V_MSG IS NULL
  THEN
    BEGIN
      SELECT SEQPCLOGINTEGRACAOCTB.NEXTVAL
      INTO   V_SEQLOG
      FROM   DUAL;
      INSERT INTO PCLOGINTEGRACAOCTB
        (CODREGRA,
         CODLOGINTEGRACAO,
         DTINICIO,
         DTFINAL,
         DTHRALTERACAO,
         CODFUNCALTERACAO,
         CODFILIAL)
      VALUES
        (PCODREGRA,
         V_SEQLOG,
         TRUNC(PDTINICIO),
         TRUNC(PDTFINAL),
         SYSDATE,
         PCODFUNC,
         PCODFILIAL);
    EXCEPTION
      WHEN OTHERS THEN
        BEGIN
          V_MSG := 'Erro Gerando Log.';
        END;
    END;
  END IF;
  IF V_MSG IS NULL
  THEN
    BEGIN
      VN_ANOATUAL := 0;

       V_UTILIZACENTROCUSTO := PARAMFILIAL.OBTERCOMOVARCHAR2('UTILIZACENTROCUSTO',
                                                              PCODFILIAL);

       IF PCAMPOSJOINCC = 'RECNUM' THEN

         OPEN CRIMP FOR
          SELECT DTMOVIMENTO,
                 NVL(VALORLANCTO, 0) AS VALORLANCTO,
                 NVL(HISTORICO_COMP, '0') AS HISTORICO_COMP,
                 DOCUMENTO,
                 CODCONTACRED,
                 CODCONTADEB,
                 RECNUM,
                 NULL RECNUMPRINC
          FROM   V_CTBEXPIMP
          WHERE  VALORLANCTO > 0
          ORDER  BY DTMOVIMENTO;

       ELSIF PCAMPOSJOINCC = 'RECNUMPRINC' THEN

         OPEN CRIMP FOR
          SELECT DTMOVIMENTO,
                 NVL(VALORLANCTO, 0) AS VALORLANCTO,
                 NVL(HISTORICO_COMP, '0') AS HISTORICO_COMP,
                 DOCUMENTO,
                 CODCONTACRED,
                 CODCONTADEB,
                 NULL RECNUM,
                 RECNUMPRINC
          FROM   V_CTBEXPIMP
          WHERE  VALORLANCTO > 0
          ORDER  BY DTMOVIMENTO;

       ELSIF PCAMPOSJOINCC = 'RECNUMRECNUMPRINC' THEN

         OPEN CRIMP FOR
          SELECT DTMOVIMENTO,
                 NVL(VALORLANCTO, 0) AS VALORLANCTO,
                 NVL(HISTORICO_COMP, '0') AS HISTORICO_COMP,
                 DOCUMENTO,
                 CODCONTACRED,
                 CODCONTADEB,
                 RECNUM,
                 RECNUMPRINC
          FROM   V_CTBEXPIMP
          WHERE  VALORLANCTO > 0
          ORDER  BY DTMOVIMENTO;

       ELSE -- NÃO PRECISAR BUSCAR DADOS NECESSÁRIAMENTE NA PCLANC

         OPEN CRIMP FOR
          SELECT DTMOVIMENTO,
                 NVL(VALORLANCTO, 0) AS VALORLANCTO,
                 NVL(HISTORICO_COMP, '0') AS HISTORICO_COMP,
                 DOCUMENTO,
                 CODCONTACRED,
                 CODCONTADEB,
                 NULL RECNUM,
                 NULL RECNUMPRINC
          FROM   V_CTBEXPIMP
          WHERE  VALORLANCTO > 0
          ORDER  BY DTMOVIMENTO;

       END IF;

      -- EXECUTANDO LANÇAMENTOS DE FECHAMENTO DE EXERCÍCIO.
      --FOR CR IN CRIMP
      LOOP
        FETCH CRIMP INTO CR;
        EXIT WHEN CRIMP%NOTFOUND;

        IF VN_ANOATUAL <> EXTRACT(YEAR FROM TO_DATE( CR.DTMOVIMENTO, 'DD/MM/YYYY')) THEN
           VN_ANOATUAL := EXTRACT(YEAR FROM TO_DATE( CR.DTMOVIMENTO, 'DD/MM/YYYY'));

           BEGIN
             SELECT CODPLANOCONTA
             INTO V_CODPLANOCONTA
             FROM V_CTBCONFEXERCICIO
             WHERE CODFILIAL = PCODFILIAL
             AND   ANO = VN_ANOATUAL;
           EXCEPTION
             WHEN OTHERS THEN
               V_CODPLANOCONTA := V_CODPLANOCONTA;
           END;
        END IF;

        -- LANÇAMENTO DE ZERAMENTO DE CONTA.
        P_CTBSEQLANCAMENTO(PCODFILIAL,
                           V_CODPLANOCONTA,
                           CR.DTMOVIMENTO,
                           FALSE,
                           V_NUMLANCTO);
        -------------------------------------------------------------------------------
        SELECT NVL(MAX(CODREDUZIDO_PC), 0),
               NVL(MAX(RECEBE_LANCTO), 'N')
        INTO   V_QTCONTA,
               V_RECEBE_LANCTO
        FROM   PCMODELOPC
        WHERE  CODREDUZIDO_PC = DECODE(NVL(CR.CODCONTADEB, 0),
                                       0,
                                       V_CODREDUZIDO_DB,
                                       CR.CODCONTADEB)
        AND    CODPLANOCONTA = V_CODPLANOCONTA;
        -------------------------------------------------------------------------------
        IF V_QTCONTA = 0
        THEN
          V_MSG := 'A regra contém uma conta débito inexistente no plano de contas. ' ||
                   CHR(13) || CHR(10) || 'Data: ' ||
                   TO_CHAR(CR.DTMOVIMENTO) || ' Documento: ' ||
                   CR.DOCUMENTO || ' Valor: ' ||
                   TO_CHAR(CR.VALORLANCTO, 'FM999999999999990.00');
          RAISE V_ERROCONTA;
        ELSE
          IF V_RECEBE_LANCTO = 'N'
          THEN
            V_MSG := 'A regra contém uma conta débito sintética, ou seja, não recebe lançamentos. ' ||
                     CHR(13) || CHR(10) || 'Data: ' ||
                     TO_CHAR(CR.DTMOVIMENTO) || ' Documento: ' ||
                     CR.DOCUMENTO || ' Valor: ' ||
                     TO_CHAR(CR.VALORLANCTO, 'FM999999999999990.00');
            RAISE V_ERROCONTA;
          END IF;
        END IF;
        -------------------------------------------------------------------------------
        SELECT NVL(MAX(CODREDUZIDO_PC), 0),
               NVL(MAX(RECEBE_LANCTO), 'N')
        INTO   V_QTCONTA,
               V_RECEBE_LANCTO
        FROM   PCMODELOPC
        WHERE  CODREDUZIDO_PC = DECODE(NVL(CR.CODCONTACRED, 0),
                                       0,
                                       V_CODREDUZIDO_CR,
                                       CR.CODCONTACRED)
        AND    CODPLANOCONTA = V_CODPLANOCONTA;
        -------------------------------------------------------------------------------
        IF V_QTCONTA = 0
        THEN
          V_MSG := 'A regra contém uma conta crédito inexistente no plano de contas.' ||
                   CHR(13) || CHR(10) || 'Data: ' ||
                   TO_CHAR(CR.DTMOVIMENTO) || ' Documento: ' ||
                   CR.DOCUMENTO || ' Valor: ' ||
                   TO_CHAR(CR.VALORLANCTO, 'FM999999999999990.00');
          RAISE V_ERROCONTA;
        ELSE
          IF V_RECEBE_LANCTO = 'N'
          THEN
            V_MSG := 'A regra contém uma conta crédito sintética, ou seja, não recebe lançamentos.' ||
                     CHR(13) || CHR(10) || 'Data: ' ||
                     TO_CHAR(CR.DTMOVIMENTO) || ' Documento: ' ||
                     CR.DOCUMENTO || ' Valor: ' ||
                     TO_CHAR(CR.VALORLANCTO, 'FM999999999999990.00');
            RAISE V_ERROCONTA;
          END IF;
        END IF;

        VS_MESESTABLOQUEADO := '';
        VS_DIAESTABLOQUEADO := '';

        --VALIDANDO SE MÊS ESTÁ ABERTO
        /*
        IF    TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'MM')) = 1 THEN --JANEIRO
              VS_MESBLOQ := 'BLOQJANEIRO';
        ELSIF TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'MM')) = 2 THEN --FEVEREIRO
              VS_MESBLOQ := 'BLOQFEVEREIRO';
        ELSIF TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'MM')) = 3 THEN --MARÇO
              VS_MESBLOQ := 'BLOQMARCO';
        ELSIF TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'MM')) = 4 THEN --ABRIL
              VS_MESBLOQ := 'BLOQABRIL';
        ELSIF TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'MM')) = 5 THEN --MAIO
              VS_MESBLOQ := 'BLOQMAIO';
        ELSIF TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'MM')) = 6 THEN --JUNHO
              VS_MESBLOQ := 'BLOQJUNHO';
        ELSIF TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'MM')) = 7 THEN --JULHO
              VS_MESBLOQ := 'BLOQJULHO';
        ELSIF TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'MM')) = 8 THEN --AGOSTO
              VS_MESBLOQ := 'BLOQAGOSTO';
        ELSIF TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'MM')) = 9 THEN --SETEMBRO
              VS_MESBLOQ := 'BLOQSETEMBRO';
        ELSIF TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'MM')) = 10 THEN --OUTUBRO
              VS_MESBLOQ := 'BLOQOUTUBRO';
        ELSIF TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'MM')) = 11 THEN --NOVEMBRO
              VS_MESBLOQ := 'BLOQNOVEMBRO';
        ELSIF TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'MM')) = 12 THEN --DEZEMBRO
              VS_MESBLOQ := 'BLOQDEZEMBRO';
        END IF;
        */

        V_SQLAUX := 'SELECT NVL(BLOQUEADO, ''N'') BLOQUEADO
                     FROM PCBLOQCONTABMES d
                     WHERE CODFILIAL = :CODFILIAL
                       AND ANO = :ANO
                       AND MES = :MES
                       AND EXISTS (
                        SELECT
                         1
                        FROM
                          PCCONFFILIAL p
                        WHERE
                              P.ano = d.ANO
                          AND P.CODCONFEXERCICIO = d.CODCONFEXERCICIO
                          AND P.CODFILIAL = d.CODFILIAL
                        )
                       ';
					   
		BEGIN  			   

        EXECUTE IMMEDIATE V_SQLAUX INTO VS_MESESTABLOQUEADO USING PCODFILIAL, TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'YYYY')), TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'MM'));
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
		      VS_MESESTABLOQUEADO := 'N';
		END;

        IF VS_MESESTABLOQUEADO = 'S' THEN
            V_MSG := 'O mês: ' || TO_CHAR(CR.DTMOVIMENTO, 'MM/YYYY') || ' está bloqueado/fechado para movimentações, não é possível continuar!';
            RAISE V_ERROCONTA;
        ELSE 
          V_SQLAUX := 'SELECT COUNT(1)   
                    FROM PCCONFFILIALSITUACAOESPECIAL F           
                   WHERE F.SITUACAOESPECIAL IN (1, 2, 3, 5)  
                     AND F.CODFILIAL  = :CODFILIAL 
                     AND F.DATASITUACAOESPECIAL < :DATALANCTO ';
      
        EXECUTE IMMEDIATE V_SQLAUX INTO VN_CONTADOR USING PCODFILIAL, CR.DTMOVIMENTO;
       
         IF VN_CONTADOR > 0 THEN
           V_MSG := 'Lançamento posterior a data de situação especial, informada na rotina 2106. Operação não permitida!';
              RAISE V_ERROCONTA;
        ELSE
		  BEGIN
            V_SQLAUX := 'SELECT NVL(BLOQUEADO, ''N'') BLOQUEADO
                         FROM PCBLOQCONTABDIA D
                         WHERE CODFILIAL = :CODFILIAL
                           AND ANO = :ANO
                           AND MES = :MES
                           AND DIA = :PDIA
                           AND EXISTS (
                              SELECT
                               1
                              FROM
                                PCCONFFILIAL p
                              WHERE
                                    P.ano = d.ANO
                                AND P.CODCONFEXERCICIO = d.CODCONFEXERCICIO
                                AND P.CODFILIAL = d.CODFILIAL
                            )
                          ';
            BEGIN 
              EXECUTE IMMEDIATE V_SQLAUX INTO VS_DIAESTABLOQUEADO
              USING PCODFILIAL, TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'YYYY')), TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'MM')), TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'DD'));
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
			       VS_DIAESTABLOQUEADO := 'N';
			END;  

            IF VS_DIAESTABLOQUEADO = 'S' THEN
              V_MSG := 'O dia: ' || TO_CHAR(CR.DTMOVIMENTO, 'DD/MM/YYYY') || ' está bloqueado/fechado para movimentações, não é possível continuar!';
              RAISE V_ERROCONTA;
            END IF;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
            BEGIN
  	          V_MSG := 'Não foram encontrados os dados sobre Bloqueio Diário para o período informado.' || 
                       CHR(13) || CHR(10) ||
					   'Não é possível continuar!' ||
					   CHR(13) || CHR(10) ||
			           'Verifique a configuração do período na Rotina 2106 (na versão 28.2 em diante).';
  			  RAISE V_ERROTABBLOQDIA;
            END;
            WHEN OTHERS THEN RAISE;
          END;

        END IF;
        
        END IF;

        -------------------------------------------------------------------------------
        IF V_MSG IS NULL
        THEN

          SELECT
            DECODE(NVL(CR.CODCONTADEB, 0), 0,
              V_CODREDUZIDO_DB,
              CR.CODCONTADEB)
          INTO
            V_CONTA_DEBITO
          FROM DUAL;

          SELECT
            DECODE(NVL(CR.CODCONTACRED, 0), 0,
              V_CODREDUZIDO_CR,
              CR.CODCONTACRED)
          INTO
            V_CONTA_CREDITO
          FROM DUAL;
          
		  BEGIN
			  SELECT
				 CODCONTA_PC
			  INTO
				 V_CODCONTA_PC_DEB
			  FROM PCMODELOPC
			  WHERE 1=1
					AND PCMODELOPC.CODPLANOCONTA  = V_CODPLANOCONTA
					AND PCMODELOPC.CODREDUZIDO_PC = V_CONTA_DEBITO;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
			V_MSG := 'A conta parametrizada para o débito não foi encontrada no plano de contas do ano de busca.';
          RAISE V_ERROCONTA;
		  END; 
          BEGIN		  
			  SELECT
				CODCONTA_PC
			  INTO
				V_CODCONTA_PC_CRED
			  FROM PCMODELOPC
			  WHERE 1=1
					AND PCMODELOPC.CODPLANOCONTA  = V_CODPLANOCONTA
					AND PCMODELOPC.CODREDUZIDO_PC = V_CONTA_CREDITO;
		  EXCEPTION
            WHEN NO_DATA_FOUND THEN
			V_MSG := 'A conta parametrizada para o crédito não foi encontrada no plano de contas do ano de busca.';
          RAISE V_ERROCONTA;
		  END; 			

          SELECT SEQPCLANCAMENTO.NEXTVAL INTO V_SEQ_NUMTRANSLANCTO_DEBITO FROM DUAL;

          INSERT INTO PCLANCAMENTO
            (NUMTRANSLANCTO,
             NUMLANCTO,
             NUMSEQ,
             MES,
             ANO,
             CODFILIAL,
             CODPLANOCONTA,
             CODREDUZIDO_PC,
             DTLANC,
             NATUREZA,
             DOCUMENTO,
             LOTE,
             VALOR,
             CODHISTORICO,
             HISTORICO_COMPL,
             TIPO_LANCAMENTO,
             EXCLUIDO,
             ENCERRADO,
             DTHRALTERACAO,
             CODFUNCALTERACAO,
             CODLOGINTEGRACAO,
             CODREGRAINTEGRACAO,
             MULTIFILIAL)
          VALUES
            (V_SEQ_NUMTRANSLANCTO_DEBITO,
             V_NUMLANCTO,
             1,
             TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'MM')),
             TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'YYYY')),
             PCODFILIAL,
             V_CODPLANOCONTA,
             V_CONTA_DEBITO,
             TRUNC(CR.DTMOVIMENTO),
             'D',
             CR.DOCUMENTO,
             '',
             ABS(CR.VALORLANCTO),
             V_CODHISTORICO,
             SUBSTR(V_HISTORICO_DESC || ' ' ||
                    NVL(CR.HISTORICO_COMP, V_HISTORICO_COMPL),
                    1,
                    200),
             'W',
             'N',
             'N',
             SYSDATE,
             PCODFUNC,
             V_SEQLOG,
             PCODREGRA,
             'N');
			 
			INSERT INTO PCLOGLANCAMENTO
            (CODALTERACAO,
			 NUMTRANSLANCTO,
             NUMLANCTO,
             NUMSEQ,
             MES,
             ANO,
             CODFILIAL,
             CODPLANOCONTA,
             CODREDUZIDO_PC,
             DTLANC,
             NATUREZA,
             DOCUMENTO,
             LOTE,
             VALOR,
             CODHISTORICO,
             HISTORICO_COMPL,

             EXCLUIDO,
             ENCERRADO,
             DTHRALTERACAO,
             CODFUNCALTERACAO,
             CODLOGINTEGRACAO,
             CODREGRAINTEGRACAO,
             MULTIFILIAL,
			 DTHREXCLUSAO,
			 MAQUINA,
			 PROGRAMA,
			 USUARIOREDE,
			 OPERACAO)
          VALUES
            (DEFSEQ_PCLOGLANCAMENTO.NEXTVAL,
			 V_SEQ_NUMTRANSLANCTO_DEBITO,
             V_NUMLANCTO,
             1,
             TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'MM')),
             TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'YYYY')),
             PCODFILIAL,
             V_CODPLANOCONTA,
             V_CONTA_DEBITO,
             TRUNC(CR.DTMOVIMENTO),
             'D',
             CR.DOCUMENTO,
             '',
             ABS(CR.VALORLANCTO),
             V_CODHISTORICO,
             SUBSTR(V_HISTORICO_DESC || ' ' ||
                    NVL(CR.HISTORICO_COMP, V_HISTORICO_COMPL),
                    1,
                    200),

             'N',
             'N',
             SYSDATE,
             PCODFUNC,
             V_SEQLOG,
             PCODREGRA,
             'N',
			 SYSDATE,
			 SUBSTR(SYS_CONTEXT('USERENV', 'TERMINAL'), 1, 64),
			 SUBSTR(SYS_CONTEXT('USERENV', 'MODULE'), 1, 48),
			 SUBSTR(SYS_CONTEXT('USERENV', 'OS_USER'), 1, 30),
			 'I'); 
			 
          P_INSERE_LANCAMENTO_FILA(PCODFILIAL,
                                V_CODPLANOCONTA,
                                TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'MM')),
                                TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'YYYY')),
                                V_CONTA_DEBITO,
                                V_CODCONTA_PC_DEB,
                                ABS(CR.VALORLANCTO),
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0);
			 
          -------------------------------------------------------------------------------

          SELECT SEQPCLANCAMENTO.NEXTVAL INTO V_SEQ_NUMTRANSLANCTO_CREDITO FROM DUAL;

         
			 
			  INSERT INTO PCLANCAMENTO
            (NUMTRANSLANCTO,
             NUMLANCTO,
             NUMSEQ,
             MES,
             ANO,
             CODFILIAL,
             CODPLANOCONTA,
             CODREDUZIDO_PC,
             DTLANC,
             NATUREZA,
             DOCUMENTO,
             LOTE,
             VALOR,
             CODHISTORICO,
             HISTORICO_COMPL,
             TIPO_LANCAMENTO,
             EXCLUIDO,
             ENCERRADO,
             DTHRALTERACAO,
             CODFUNCALTERACAO,
             CODLOGINTEGRACAO,
             CODREGRAINTEGRACAO,
             MULTIFILIAL)
          VALUES
            (V_SEQ_NUMTRANSLANCTO_CREDITO,
             V_NUMLANCTO,
             2,
             TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'MM')),
             TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'YYYY')),
             PCODFILIAL,
             V_CODPLANOCONTA,
             V_CONTA_CREDITO,
             TRUNC(CR.DTMOVIMENTO),
             'C',
             CR.DOCUMENTO,
             '',
             ABS(CR.VALORLANCTO),
             V_CODHISTORICO,
             SUBSTR(V_HISTORICO_DESC || ' ' ||
                    NVL(CR.HISTORICO_COMP, V_HISTORICO_COMPL),
                    1,
                    200),
             'W',
             'N',
             'N',
             SYSDATE,
             PCODFUNC,
             V_SEQLOG,
             PCODREGRA,
             'N'); 
			 
			  INSERT INTO PCLOGLANCAMENTO
            (CODALTERACAO,
			 NUMTRANSLANCTO,
             NUMLANCTO,
             NUMSEQ,
             MES,
             ANO,
             CODFILIAL,
             CODPLANOCONTA,
             CODREDUZIDO_PC,
             DTLANC,
             NATUREZA,
             DOCUMENTO,
             LOTE,
             VALOR,
             CODHISTORICO,
             HISTORICO_COMPL,

             EXCLUIDO,
             ENCERRADO,
             DTHRALTERACAO,
             CODFUNCALTERACAO,
             CODLOGINTEGRACAO,
             CODREGRAINTEGRACAO,
             MULTIFILIAL,
			 DTHREXCLUSAO,
			 MAQUINA,
			 PROGRAMA,
			 USUARIOREDE,
			 OPERACAO)
          VALUES
            (DEFSEQ_PCLOGLANCAMENTO.NEXTVAL,
			 V_SEQ_NUMTRANSLANCTO_CREDITO,
             V_NUMLANCTO,
             2,
             TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'MM')),
             TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'YYYY')),
             PCODFILIAL,
             V_CODPLANOCONTA,
             V_CONTA_CREDITO,
             TRUNC(CR.DTMOVIMENTO),
             'C',
             CR.DOCUMENTO,
             '',
             ABS(CR.VALORLANCTO),
             V_CODHISTORICO,
             SUBSTR(V_HISTORICO_DESC || ' ' ||
                    NVL(CR.HISTORICO_COMP, V_HISTORICO_COMPL),
                    1,
                    200),
  
             'N',
             'N',
             SYSDATE,
             PCODFUNC,
             V_SEQLOG,
             PCODREGRA,
             'N',
			 SYSDATE,
			 SUBSTR(SYS_CONTEXT('USERENV', 'TERMINAL'), 1, 64),
			 SUBSTR(SYS_CONTEXT('USERENV', 'MODULE'), 1, 48),
			 SUBSTR(SYS_CONTEXT('USERENV', 'OS_USER'), 1, 30),
			 'I');
			 		 
          P_INSERE_LANCAMENTO_FILA(PCODFILIAL,
                                V_CODPLANOCONTA,
                                TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'MM')),
                                TO_NUMBER(TO_CHAR(CR.DTMOVIMENTO, 'YYYY')),
                                V_CONTA_CREDITO,
                                V_CODCONTA_PC_CRED,
                                0,
                                ABS(CR.VALORLANCTO),								
                                0,
                                0,
                                0,
                                0,
                                0,
                                0);				

           IF V_UTILIZACENTROCUSTO = 'S' THEN

             IF  V_DESTINORATEIOCC IN ('D','C') THEN
			 BEGIN
                SELECT
                 NVL(USACENTROCUSTO, 'N') USACENTROCUSTO
                 INTO V_CONTA_USACENTROCUSTO
                FROM PCMODELOPC
                WHERE CODPLANOCONTA = V_CODPLANOCONTA
                  AND CODREDUZIDO_PC = DECODE(V_DESTINORATEIOCC, 'D',
                                         V_CONTA_DEBITO,
                                         V_CONTA_CREDITO);
			 EXCEPTION
				WHEN NO_DATA_FOUND THEN 
 				  V_CONTA_USACENTROCUSTO := 'N';
			 END;							 
             ELSE
               V_CONTA_USACENTROCUSTO := 'N';
             END IF;

           ELSE
             V_CONTA_USACENTROCUSTO := 'N';
           END IF;

           IF V_CONTA_USACENTROCUSTO = 'S' THEN

             IF PCAMPOSJOINCC = 'RECNUM' THEN
               V_RECNUM_RECNUMPRINC := CR.RECNUM;

             ELSIF PCAMPOSJOINCC = 'RECNUMPRINC' THEN
               V_RECNUM_RECNUMPRINC := CR.RECNUMPRINC;

             ELSIF PCAMPOSJOINCC = 'RECNUMRECNUMPRINC' THEN
               V_RECNUM_RECNUMPRINC := NVL(CR.RECNUMPRINC, CR.RECNUM);

             END IF;

             IF V_DESTINORATEIOCC = 'D' THEN
                V_SEQ_NUMTRANSLANCTO_CC := V_SEQ_NUMTRANSLANCTO_DEBITO;
                V_NATUREZACC := 'D';
             ELSIF V_DESTINORATEIOCC = 'C' THEN
                V_SEQ_NUMTRANSLANCTO_CC := V_SEQ_NUMTRANSLANCTO_CREDITO;
                V_NATUREZACC := 'C';
             END IF;

             VALORES_POSSIVEIS_CENTROCUSTO := CARREGA_VALORES_POSSIVEIS_CC(V_RECNUM_RECNUMPRINC);

             FOR VN_POSICAO IN 1 .. VALORES_POSSIVEIS_CENTROCUSTO.COUNT LOOP

               INSERT INTO PCRATEIOCONTABILCC (
                 CODFILIAL
                 , CODIGOCENTROCUSTO
                 , NATUREZA
                 , NUMTRANSLANCTO
                 , PERCRATEIO
                 , VALOR
               ) VALUES (
                 VALORES_POSSIVEIS_CENTROCUSTO(VN_POSICAO).CODFILIAL
                 , VALORES_POSSIVEIS_CENTROCUSTO(VN_POSICAO).CODIGOCENTROCUSTO
                 , V_NATUREZACC
                 , V_SEQ_NUMTRANSLANCTO_CC
                 , VALORES_POSSIVEIS_CENTROCUSTO(VN_POSICAO).PERCRATEIO
                 , VALORES_POSSIVEIS_CENTROCUSTO(VN_POSICAO).VALOR
               );

               V_QTLOGREGISTROS_CC := V_QTLOGREGISTROS_CC + 1;

             END LOOP;

           END IF;

        END IF;

      END LOOP;

      -----------------------------------------------------------------------------
      COMMIT;
      -----------------------------------------------------------------------------

      CLOSE CRIMP;

    EXCEPTION
      WHEN V_ERROCONTA THEN
        BEGIN
          ROLLBACK;
        END;
      WHEN V_ERROTABBLOQDIA THEN
        BEGIN
          ROLLBACK;
        END;		
      WHEN OTHERS THEN
        BEGIN
          V_MSG := 'Ocorreu um erro ao efetuar integração. ' || SQLCODE ||
                   ' - ' || SQLERRM;
          ROLLBACK;
        END;
    END;
  END IF;
  -----------------------------------------------------------------------------
  -- MENSAGEM DE SUCESSO;
  -----------------------------------------------------------------------------
  IF V_MSG IS NULL
  THEN
    IF V_QTLOGREGISTROS_CC > 0 THEN
      V_MSG := 'OK-TOTREG:' || V_QTLOGREGISTROS || '-TOTREGCC:' || V_QTLOGREGISTROS_CC || '-NUMLOG:' || V_SEQLOG || '-';
    ELSE
      V_MSG := 'OK-TOTREG:' || V_QTLOGREGISTROS || '-NUMLOG:' || V_SEQLOG || '-';
    END IF;
  END IF;

  RETORNO := V_MSG;
END P_CTBIMPORTACAO;

