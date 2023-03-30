CREATE OR REPLACE PROCEDURE PRC_FECHAMENTO_CONVENIO (P_CODCONVENIADO PCCLIENT.CODCLI%TYPE
                                                   ,P_MENSAGEM      IN OUT VARCHAR2
                                                   ,P_CODCOOPERADO  VARCHAR2 DEFAULT NULL
                                                   ,P_CODCOB        PCCOB.CODCOB%TYPE DEFAULT NULL
                                                   ,P_DTVENC        PCPREST.DTVENC%TYPE DEFAULT NULL
                                                   ,P_DUPLIC_BASE   PCPREST.DUPLIC%TYPE DEFAULT NULL
                                                   ,P_PREST_BASE    PCPREST.PREST%TYPE DEFAULT NULL
                                                   ,P_OBS           PCPREST.OBS%TYPE DEFAULT NULL
                                                   ,P_MANUAL        VARCHAR2 DEFAULT NULL
                                                   ,P_PLANOPAGTO    PCPLPAG.CODPLPAG%TYPE DEFAULT NULL
                                                   ,P_DTBASE        PCPREST.DTVENC%TYPE DEFAULT NULL
                                                   ,P_VALORTOTAL    PCPREST.VALOR%TYPE DEFAULT NULL
                                                   ,P_QTDPARCELAS   NUMBER DEFAULT NULL) IS
  V_CODCOB        PCCOB.CODCOB%TYPE;
  V_DTVENC        PCPREST.DTVENC%TYPE;
  V_COUNT         NUMBER;
  V_COUNT_PREST   NUMBER;
  V_NUMTRANSVENDA PCPREST.NUMTRANSVENDA%TYPE;
  REC_PCPREST     PCPREST%ROWTYPE;
  REC_PCDESD      PCDESD%ROWTYPE;
  REC_PCCOB       PCCOB%ROWTYPE;
  REC_PCFECHA     PCFECHACONVENIO%ROWTYPE;
  V_PRAZO         VARCHAR2(2000);
  V_DIAS          NUMBER;
  V_PARCELA       PCPREST.PREST%TYPE;
  V_VALORPARCELA  PCPREST.VALOR%TYPE;
  V_VALORTOTAL    PCPREST.VALOR%TYPE;
  V_DIFERENCA     PCPREST.VALOR%TYPE;
  V_PARAM_DESDTITULOFECHACONV PCPARAMFILIAL.VALOR%TYPE;

  TYPE REGISTRO IS RECORD(
     CODCONVENIADO PCPREST.CODCLI%TYPE
    ,CONVENIADO    PCCLIENT.CLIENTE%TYPE
    ,CODCOOPERADO  PCPREST.CODCLI%TYPE
    ,COOPERADO     PCCLIENT.CLIENTE%TYPE
    ,DUPLIC        PCPREST.DUPLIC%TYPE
    ,PREST         PCPREST.PREST%TYPE
    ,VALOR         PCPREST.VALOR%TYPE
    ,VALOREMABERTO PCPREST.VALOR%TYPE
    ,DTVENC        PCPREST.DTVENC%TYPE
    ,DTEMISSAO     PCPREST.DTEMISSAO%TYPE
    ,NUMTRANSVENDA PCPREST.NUMTRANSVENDA%TYPE
    ,DTCXMOT       PCPREST.DTCXMOT%TYPE
    ,RID           VARCHAR2(100));

  L_CURSOR SYS_REFCURSOR;
  R_TITULO REGISTRO;
  V_SQL    VARCHAR2(3000);
BEGIN
  V_CODCOB   := P_CODCOB;
  V_DTVENC   := P_DTVENC;
  P_MENSAGEM := '';

  BEGIN
   SELECT NVL(VALOR,'S')
   INTO V_PARAM_DESDTITULOFECHACONV
   FROM PCPARAMFILIAL
   WHERE NOME = 'DESDTITULOFECHACONV'
   AND CODFILIAL = '99';
  END;


  -- VERIFICA SE O CONVENIADO FOI INFORMADO
  IF P_CODCONVENIADO IS NULL THEN
    P_MENSAGEM := P_MENSAGEM || 'E#CONVENIADO NÃO INFORMADO!#';
    P_MENSAGEM := P_MENSAGEM || 'E#FECHAMENTO INTERROMPIDO.#';
    RETURN;
  END IF;

  FOR R_FILIAL IN (SELECT CODIGO CODFILIAL
                     FROM PCFILIAL F
                    WHERE F.DTEXCLUSAO IS NULL
                      AND F.CODIGO <> '99')
  LOOP

    -- RECUPERA O CÓDIGO DE COBRANÇA SE NÃO INFORMADO
    IF V_CODCOB IS NULL THEN
      BEGIN
        SELECT PARAMFILIAL.ObterComoVarchar2('CODCOBFECHAMENTOCONVENIO', R_FILIAL.CODFILIAL)
          INTO V_CODCOB
          FROM DUAL;
      EXCEPTION
        WHEN OTHERS THEN
          BEGIN
            SELECT VALOR
              INTO V_CODCOB
              FROM PCPARAMFILIAL
             WHERE NOME = 'CODCOBFECHAMENTOCONVENIO'
               AND CODFILIAL = '99';
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAGEM := P_MENSAGEM ||
                            'E#PARÂMETRO POR FILIAL INDICANDO O CÓDIGO DE COBRANÇA PARA FECHAMENTO DE CONVÊNIO NÃO INFORMADO!#';
              P_MENSAGEM := P_MENSAGEM || 'E#FECHAMENTO INTERROMPIDO.#';
              RETURN;
          END;
      END;
    END IF;

    SELECT * INTO REC_PCCOB FROM PCCOB WHERE CODCOB = V_CODCOB;

    -- RECUPERA A DATA DE VENCIMENTO SE NÃO INFORMADA
    IF V_DTVENC IS NULL THEN
      SELECT DIA_CONVENIO || '/' || CASE
               WHEN DIA_HOJE > DIA_CONVENIO THEN
                CASE
               WHEN TO_CHAR(TO_CHAR(SYSDATE, 'MM') + 1) > 12 THEN
                '01' || '/' || TO_CHAR(TO_CHAR(SYSDATE, 'YYYY') + 1)
               ELSE
                TO_CHAR(TO_CHAR(SYSDATE, 'MM') + 1) || '/' ||
                TO_CHAR(SYSDATE, 'YYYY')
             END ELSE TO_CHAR(SYSDATE, 'MM') || '/' || TO_CHAR(SYSDATE, 'YYYY') END DIA_CONVENIO
        INTO V_DTVENC
        FROM (SELECT CASE
                       WHEN NVL(PCCLIENT.DIAFECHACONVENIO, 0) -
                            NVL(PCCLIENT.QTDIASCARENCIACONV, 0) < 0 THEN
                        TO_NUMBER(TO_CHAR(LAST_DAY(TO_DATE('01/' ||
                                                           TO_CHAR(TO_NUMBER(TO_CHAR(SYSDATE,
                                                                                     'MM')) - 1) || '/' ||
                                                           TO_CHAR(SYSDATE,
                                                                   'YYYY'),
                                                           'DD/MM/YYYY')),
                                          'DD')) +
                        (NVL(PCCLIENT.DIAFECHACONVENIO, 0) -
                         NVL(PCCLIENT.QTDIASCARENCIACONV, 0))
                       WHEN NVL(PCCLIENT.DIAFECHACONVENIO, 0) -
                            NVL(PCCLIENT.QTDIASCARENCIACONV, 0) < 0 THEN
                        TO_NUMBER(TO_CHAR(LAST_DAY(TO_DATE('01/' ||
                                                           TO_CHAR(TO_NUMBER(TO_CHAR(SYSDATE,
                                                                                     'MM')) - 1) || '/' ||
                                                           TO_CHAR(SYSDATE,
                                                                   'YYYY'),
                                                           'DD/MM/YYYY')),
                                          'DD'))
                       ELSE
                        NVL(PCCLIENT.DIAFECHACONVENIO, 0) -
                        NVL(PCCLIENT.QTDIASCARENCIACONV, 0)
                     END DIA_CONVENIO
                    ,TO_CHAR(SYSDATE, 'DD') DIA_HOJE
                FROM PCCLIENT
               WHERE PCCLIENT.QTDIASCARENCIACONV IS NOT NULL
                 AND PCCLIENT.CODCLI = P_CODCONVENIADO);
    END IF;
    
    
    IF P_PLANOPAGTO IS NOT NULL THEN    
      SELECT  PRAZO1 || '-' || 
              DECODE(PRAZO2, NULL, '', PRAZO2 || '-') || 
              DECODE(PRAZO3, NULL, '', PRAZO3 || '-') || 
              DECODE(PRAZO4, NULL, '', PRAZO4 || '-') || 
              DECODE(PRAZO5, NULL, '', PRAZO5 || '-') || 
              DECODE(PRAZO6, NULL, '', PRAZO6 || '-') || 
              DECODE(PRAZO7, NULL, '', PRAZO7 || '-') || 
              DECODE(PRAZO8, NULL, '', PRAZO8 || '-') || 
              DECODE(PRAZO9, NULL, '', PRAZO9 || '-') || 
              DECODE(PRAZO10, NULL, '', PRAZO10 || '-') || 
              DECODE(PRAZO11, NULL, '', PRAZO11 || '-') || 
              DECODE(PRAZO12, NULL, '', PRAZO12 || '-')
        INTO V_PRAZO
       FROM PCPLPAG
      WHERE CODPLPAG = P_PLANOPAGTO;       
    END IF;

    V_COUNT := 0;

    REC_PCPREST.DUPLIC := 0;

    V_SQL := 'SELECT CONVENIO.CODCLI CODCONVENIADO, ' ||
             '       CONVENIO.CLIENTE CONVENIADO, ' ||
             '       PCPREST.CODCLI CODCOOPERADO, ' ||
             '       PCCLIENT.CLIENTE COOPERADO, ' ||
             '       PCPREST.DUPLIC, ' ||
             '       PCPREST.PREST, ' ||
             '       PCPREST.VALOR, ' ||
             '       PCPREST.VALOR - NVL(PCPREST.VPAGO, 0) VALOREMABERTO,' ||
             '       PCPREST.DTVENC,' ||
             '       PCPREST.DTEMISSAO,' ||
             '       PCPREST.NUMTRANSVENDA,' ||
             '       PCPREST.DTCXMOT' ||
             '       , PCPREST.ROWID RID ' ||
             '  FROM PCPREST ' ||
             '     , PCCLIENT ' ||
             '     , PCCOB' ||
             '     , PCCLIENT CONVENIO ' ||
             ' WHERE PCPREST.DTBAIXA IS NULL' ||
             '   AND PCPREST.CODCLI = PCCLIENT.CODCLI' ||
             '   AND PCCLIENT.CODCLIPRINC = CONVENIO.CODCLI' ||
             '   AND PCCOB.CODCOB = PCPREST.CODCOB' ||
             '   AND ((PCCOB.CONVENIO = ''S'') OR (PCPREST.CODCOB = ''CONV''))    ' ||
             '   AND PCPREST.CODFILIAL =  ''' || R_FILIAL.CODFILIAL || '''' ||
             '   AND PCPREST.DTCANCEL IS NULL ';

    IF UPPER(P_MANUAL) = UPPER('SIM') THEN
      V_SQL := V_SQL || '     AND (PCPREST.TIPO = ''X'')';
    ELSE
      V_SQL := V_SQL || '     AND (TRUNC(PCPREST.DTVENC) <= ' || V_DTVENC || ')';
    END IF;

    IF P_CODCONVENIADO IS NOT NULL THEN
      V_SQL := V_SQL || '     AND PCCLIENT.CODCLIPRINC IN (' || P_CODCONVENIADO || ') ';
    END IF;

    IF P_CODCOOPERADO IS NOT NULL THEN
      V_SQL := V_SQL || ' AND PCPREST.CODCLI IN (' || P_CODCOOPERADO || ')';
    END IF;
/*
    V_SQL := V_SQL || ' UNION ALL ';

    V_SQL := V_SQL || 'SELECT PCCLIENT.CODCLI CODCONVENIADO, ' ||
                      '       PCCLIENT.CLIENTE CONVENIADO,  ' ||
                      '       C2.CODCLI CODCOOPERADO, ' ||
                      '       C2.CLIENTE COOPERADO, ' ||
                      '       PCPREST.DUPLIC, ' ||
                      '       PCPREST.PREST, ' ||
                      '       PCPREST.VALOR, ' ||
                      '       PCPREST.VALOR - NVL(PCPREST.VPAGO, 0) VALOREMABERTO, ' ||
                      '       PCPREST.DTVENC, ' ||
                      '       PCPREST.DTEMISSAO, ' ||
                      '       PCPREST.NUMTRANSVENDA, ' ||
                      '       PCPREST.DTCXMOT, ' ||
                      '       PCPREST.ROWID ' ||
                      '  FROM PCPREST, PCCLIENT, PCCOB, PCCLIENT C2 ' ||
                      ' WHERE PCPREST.DTBAIXA IS NULL ' ||
                      '   AND PCPREST.CODCLI = C2.CODCLI ' ||
                      '   AND PCCLIENT.CODCLI = C2.CODCLIPRINC ' ||
                      '   AND PCCOB.CODCOB = PCPREST.CODCOB ' ||
                      '   AND PCPREST.CODCOB = ''CONV''  ' ||
                      '   AND PCPREST.DTCANCEL IS NULL ' ||
                      '   AND PCPREST.CODFILIAL = ''' || R_FILIAL.CODFILIAL || '''';

    IF UPPER(P_MANUAL) = UPPER('SIM') THEN
      V_SQL := V_SQL || '   AND (PCPREST.TIPO = ''X'')';
    ELSE
      V_SQL := V_SQL || '   AND (TRUNC(PCPREST.DTVENC) <= ' || V_DTVENC || ')';
    END IF;

    IF P_CODCONVENIADO IS NOT NULL THEN
      V_SQL := V_SQL || '   AND PCCLIENT.CODCLI IN (' || P_CODCONVENIADO || ') ';
    END IF;

    IF P_CODCOOPERADO IS NOT NULL THEN
      V_SQL := V_SQL || '   AND C2.CODCLI IN (' || P_CODCOOPERADO || ')';
    END IF;
*/
    DBMS_OUTPUT.put_line('V_SQL=' || V_SQL);

    OPEN L_CURSOR FOR V_SQL;
    BEGIN
      LOOP
        FETCH L_CURSOR INTO R_TITULO;
        EXIT WHEN L_CURSOR%NOTFOUND;

        -- VERIFICA SE O TÍTULO JÁ FOI ACERTADO
        IF R_TITULO.DTCXMOT IS NULL THEN P_MENSAGEM := P_MENSAGEM ||
                                                       'E#DUPLICATA ' ||
                                                       R_TITULO.DUPLIC || '-' ||
                                                       R_TITULO.PREST ||
                                                       ' NÃO ACERTADA NO CAIXA VIA ROTINA 6019.#';
        P_MENSAGEM := P_MENSAGEM || 'E#FECHAMENTO INTERROMPIDO.#';
--        ROLLBACK;
        RETURN;
      ELSE

      -- RECUPERA O TÍTULO BASE CASO NÃO INFORMADO
      IF REC_PCPREST.DUPLIC = 0 THEN
        IF P_DUPLIC_BASE IS NULL THEN
        BEGIN
            SELECT *
              INTO REC_PCPREST
              FROM PCPREST
             WHERE PCPREST.ROWID = R_TITULO.RID;
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAGEM := P_MENSAGEM || 'E#DUPLICATA ' || P_DUPLIC_BASE || '-' ||
                            P_PREST_BASE || ' NÃO ENCONTRADA.#';
              P_MENSAGEM := P_MENSAGEM || 'E#FECHAMENTO INTERROMPIDO.#';
--              ROLLBACK;
              RETURN;
          END;
        ELSE
          BEGIN
            SELECT *
              INTO REC_PCPREST
              FROM PCPREST
             WHERE PCPREST.DUPLIC = P_DUPLIC_BASE
               AND PCPREST.PREST = P_PREST_BASE;
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAGEM := P_MENSAGEM || 'E#DUPLICATA ' || P_DUPLIC_BASE || '-' ||
                            P_PREST_BASE || ' NÃO ENCONTRADA.#';
              P_MENSAGEM := P_MENSAGEM || 'E#FECHAMENTO INTERROMPIDO.#';
--              ROLLBACK;
              RETURN;
          END;
        END IF;

        -- PEGA O NUMERO DA PRÓXIMA PARCELA
        SELECT PCCONSUM.PROXNUMTRANSVENDA
          INTO V_NUMTRANSVENDA
          FROM PCCONSUM
         WHERE ROWNUM <= 1
           FOR UPDATE;

        -- PARCELA ÚNICA
        REC_PCPREST.PREST := 1;

        -- POR CONTA DE ERRO DE PK, VERIFICA SE O NÚMERO JÁ ESTÁ SENDO UTILIZADO
        SELECT COUNT(1)
          INTO V_COUNT_PREST
          FROM PCPREST
         WHERE PCPREST.NUMTRANSVENDA = V_NUMTRANSVENDA
           AND PCPREST.PREST = 1;

        -- SE JÁ EXISTIR, FAZ UM MAX
        IF V_COUNT_PREST > 0 THEN
          SELECT MAX(PCPREST.NUMTRANSVENDA) + 1
            INTO V_NUMTRANSVENDA
            FROM PCPREST;
        END IF;

        -- ALTERA A NUMERAÇÃO NA PCCONSUM
        UPDATE PCCONSUM
           SET PCCONSUM.PROXNUMTRANSVENDA = V_NUMTRANSVENDA + 1;

        -- SETA OS NÚMEROS
        REC_PCPREST.NUMTRANSVENDA := V_NUMTRANSVENDA;
        REC_PCPREST.DUPLIC        := V_NUMTRANSVENDA;

        P_MENSAGEM := P_MENSAGEM || 'I#GERADA DUPLICATA ' ||
                      REC_PCPREST.DUPLIC || '-' || REC_PCPREST.PREST ||
                      ' COM DATA DE VENCIMENTO ' || V_DTVENC ||
                      ' PARA O FECHAMENTO DOS CONVÊNIOS.#';

        -- ALTERA O CLIENTE PARA O CONVENIADO
        REC_PCPREST.CODCLI := P_CODCONVENIADO;

        -- SETA OUTROS CAMPOS
        REC_PCPREST.VALOR         := 0;
        REC_PCPREST.DTVENC        := V_DTVENC;
        REC_PCPREST.CODCOB        := V_CODCOB;
        REC_PCPREST.CODCOBORIG    := V_CODCOB;
        REC_PCPREST.VPAGO         := NULL;
        REC_PCPREST.DTPAG         := NULL;
        REC_PCPREST.DTEMISSAO     := TRUNC(SYSDATE);
        REC_PCPREST.DTEMISSAOORIG := TRUNC(SYSDATE);
        REC_PCPREST.OPERACAO      := 'N';
        REC_PCPREST.STATUS        := 'A';
        REC_PCPREST.VALORDESC     := 0;
        REC_PCPREST.NUMCAR        := 1;
        REC_PCPREST.DTFECHA       := TRUNC(SYSDATE);
        REC_PCPREST.OBS           := '';
        REC_PCPREST.DTVENCORIG    := V_DTVENC;
        REC_PCPREST.CODBANCO      := REC_PCCOB.CODBANCO;
        REC_PCPREST.CODCOBBANCO   := REC_PCCOB.CODMOEDA;
        REC_PCPREST.DTCXMOT       := TRUNC(SYSDATE);
        REC_PCPREST.DTINCLUSAO    := TRUNC(SYSDATE);
        REC_PCPREST.TIPO          := '';
        REC_PCPREST.OBS           := SUBSTR(P_OBS, 1, 100);

      END IF;

      -- INSERE TÍTULOS NA PCDESD
      REC_PCDESD                   := NULL;
      REC_PCDESD.NUMTRANSVENDADEST := REC_PCPREST.NUMTRANSVENDA;
      REC_PCDESD.PRESTDEST         := REC_PCPREST.PREST;
      REC_PCDESD.CODCLIDEST        := R_TITULO.CODCONVENIADO;
      REC_PCDESD.NUMTRANSVENDAORIG := R_TITULO.NUMTRANSVENDA;
      REC_PCDESD.PRESTORIG         := R_TITULO.PREST;
      REC_PCDESD.CODCLIORIG        := R_TITULO.CODCOOPERADO;
      REC_PCDESD.DTLANC            := TRUNC(SYSDATE);
      REC_PCDESD.CODFUNCCXMOT      := NVL(REC_PCPREST.CODFUNCCXMOT, 1);
      REC_PCDESD.CODROTINA         := 6014;

      INSERT INTO PCDESD VALUES REC_PCDESD;

      -- INSERE TABELA DE FECHAMENTO
      REC_PCFECHA := NULL;

      SELECT DFSEQ_PCFECHACONVENIO.NEXTVAL
        INTO REC_PCFECHA.NUMFECHAMENTO
        FROM DUAL;

      REC_PCFECHA.CODCLI            := R_TITULO.CODCONVENIADO;
      REC_PCFECHA.DTFECPREST        := SYSDATE;
      REC_PCFECHA.CODFUNCFECPREST   := NVL(REC_PCPREST.CODFUNCCXMOT, 1);
      REC_PCFECHA.NUMTRANSVENDADEST := REC_PCPREST.NUMTRANSVENDA;
      REC_PCFECHA.PRESTDEST         := REC_PCPREST.PREST;
      REC_PCFECHA.NUMVIASREL        := 0;
      REC_PCFECHA.SITUACAO          := 'RN'; -- PENDENTE RELATÓRIO E NF
      REC_PCFECHA.CODFILIAL         := R_FILIAL.CODFILIAL;

      -- ALTERA O TÍTULO PARA QUITADO

     IF V_PARAM_DESDTITULOFECHACONV = 'N' THEN
      UPDATE PCPREST
         SET PCPREST.CODCOBORIG = PCPREST.CODCOB
            ,PCPREST.DTPAG      = TRUNC(SYSDATE)
            ,PCPREST.VPAGO      = PCPREST.VALOR
            ,PCPREST.TIPO       = NULL
       WHERE PCPREST.ROWID = R_TITULO.RID;
     ELSE
      UPDATE PCPREST
         SET PCPREST.CODCOBORIG = PCPREST.CODCOB
            ,PCPREST.CODCOB     = 'DESD'
            ,PCPREST.DTPAG      = TRUNC(SYSDATE)
            ,PCPREST.VPAGO      = PCPREST.VALOR
            ,PCPREST.TIPO       = NULL
       WHERE PCPREST.ROWID = R_TITULO.RID;
     END IF;


      -- ATUALIZA O VALOR NO TITULO BASE
      REC_PCPREST.VALOR := REC_PCPREST.VALOR + R_TITULO.VALOREMABERTO;

      -- IMPLEMENTA O CONTADOR
      V_COUNT := V_COUNT + 1;

    END IF;


      END LOOP;
      CLOSE L_CURSOR;

      P_MENSAGEM := P_MENSAGEM || 'I#FILIAL ' || R_FILIAL.CODFILIAL ||
                    ': FECHAMENTO REALIZADO COM SUCESSO.#';
    EXCEPTION
      WHEN INVALID_CURSOR THEN
         RAISE_APPLICATION_ERROR(-20001,'Erro na execução do cursor -- Caixa.');
      WHEN OTHERS THEN
         RAISE_APPLICATION_ERROR(-20001,'Erro  -- Caixa. ' || SQLERRM);
    END;

  /*Atribuir valores para não apresentar em caixas*/
  REC_PCPREST.NUMCHECKOUT     := NULL;
  REC_PCPREST.CODFUNCCHECKOUT := NULL;
  REC_PCPREST.DTFECHA         := TRUNC(SYSDATE);
  REC_PCPREST.VPAGO           := 0;

  -- INSERE O TITULO DESDOBRADO E FECHAMENTO
  IF V_COUNT > 0 THEN
    IF V_PRAZO IS NULL THEN    
       INSERT INTO PCPREST VALUES REC_PCPREST;
       INSERT INTO PCFECHACONVENIO VALUES REC_PCFECHA;
     ELSE
       V_PARCELA := 1;
       
       V_VALORPARCELA := TRUNC(P_VALORTOTAL / P_QTDPARCELAS, 2);
       V_DIFERENCA := P_VALORTOTAL - (V_VALORPARCELA * P_QTDPARCELAS);
       WHILE V_PRAZO IS NOT NULL LOOP
         V_DIAS := SUBSTR(V_PRAZO, 1, INSTR(V_PRAZO, '-') -1);            
         
         REC_PCPREST.DTVENC := P_DTBASE + V_DIAS;
         REC_PCPREST.PREST := V_PARCELA;
         REC_PCPREST.VALOR := V_VALORPARCELA + V_DIFERENCA;
         
         V_DIFERENCA := 0;
         
         INSERT INTO PCPREST VALUES REC_PCPREST;
            
         V_PRAZO := SUBSTR(V_PRAZO,  INSTR(V_PRAZO, '-') + 1, LENGTH(V_PRAZO));
         V_PARCELA := V_PARCELA + 1;        
       END LOOP;                
       
       INSERT INTO PCFECHACONVENIO VALUES REC_PCFECHA;       
     END IF;
  END IF;

  IF V_COUNT = 0 THEN
    IF P_MENSAGEM IS NULL THEN
      P_MENSAGEM := 'A#FILIAL ' || R_FILIAL.CODFILIAL ||
                    ': FECHAMENTO NÃO REALIZADO, NENHUM TÍTULO ENCONTRADO.#';
    ELSE
      P_MENSAGEM := P_MENSAGEM || 'A#FILIAL ' || R_FILIAL.CODFILIAL ||
                    ': FECHAMENTO NÃO REALIZADO, NENHUM TÍTULO ENCONTRADO.#';
    END IF;
--  ELSE
--    COMMIT;
  END IF;

END LOOP;

--COMMIT;

END PRC_FECHAMENTO_CONVENIO;
