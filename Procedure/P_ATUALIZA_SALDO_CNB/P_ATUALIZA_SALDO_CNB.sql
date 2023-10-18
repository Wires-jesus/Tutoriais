CREATE OR REPLACE PROCEDURE "P_ATUALIZA_SALDO_CNB" IS
  V_CONTADOR         NUMBER(10) := 0;
  V_PROCEDUREOCUPADA NUMBER(10) := 0;
  V_MAIOR_REGISTRO   NUMBER(20) := 0;
  V_SQL              VARCHAR2(4000);
  L_CURSOR           SYS_REFCURSOR;
  VS_ERRO            VARCHAR2(10000);
  V_PASSO            VARCHAR2(100);
  V_ROTINA           VARCHAR2(100);
  TYPE TABELA IS RECORD(
    CODCONTA_PC    VARCHAR2(40),
    CODREDUZIDO_PC VARCHAR2(12));
  CONTASACIMA TABELA;

  V_CODCONTA     PCMODELOPC.CODCONTA_PC%TYPE;
  V_POSSUIPARCEIRO VARCHAR2(1) := 'N';

  -- PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN
  V_PASSO := '--PASSO 1';
  SELECT COUNT(1) INTO V_CONTADOR FROM PCFILASALDOCNB;
  V_PASSO := '--PASSO 2';
  SELECT COUNT(1) INTO V_PROCEDUREOCUPADA FROM PCVERIFICAFILA;
  V_PASSO := '--PASSO 3';
  IF (V_CONTADOR > 0) AND (V_PROCEDUREOCUPADA = 0) THEN
    V_PASSO := '--PASSO 4';
    INSERT INTO PCVERIFICAFILA VALUES ('OCUPADO');
    COMMIT;
  
    SELECT CASE
             WHEN COUNT(PCFILASALDOCNB.TIPOPARCEIRO) > 0 THEN
              'S'
             ELSE
              'N'
           END
      INTO V_POSSUIPARCEIRO
      FROM PCFILASALDOCNB
	  WHERE NVL(TIPOPARCEIRO, '0') <> '0';
      
    IF V_POSSUIPARCEIRO = 'S' THEN
    
 FOR DADOS IN (SELECT SUM(VALORDEBITO) VALORDEBITO,
                         SUM(VALORCREDITO) VALORCREDITO,
                         SUM(VLRDEBENCERRAMENTO) VLRDEBENCERRAMENTO,
                         SUM(VLRCREENCERRAMENTO) VLRCREENCERRAMENTO,
                         SUM(VLRDEBCONCIL) VLRDEBCONCIL,
                         SUM(VLRCRECONCIL) VLRCRECONCIL,
                         SUM(VLRDEBCONCILENCERRAMENTO) VLRDEBCONCILENCERRAMENTO,
                         SUM(VLRCRECONCILENCERRAMENTO) VLRCRECONCILENCERRAMENTO,
                         S.MES,
                         S.ANO,
                         S.CODREDUZIDO_PC,
                         S.CODFILIAL,
                         S.CODPLANOCONTA,
                         MAX(S.CODIGO) CODIGO,
                         S.CODCONTA_PC,                         
                         S.TIPOPARCEIRO,
                         S.CODPARCEIRO                         
                    FROM PCFILASALDOCNB S
		    	   WHERE NVL(TIPOPARCEIRO, '0') <> '0'
                   GROUP BY S.MES,
                            S.ANO,
                            S.CODREDUZIDO_PC,
                            S.CODFILIAL,
                            S.CODPLANOCONTA,
                            S.CODCONTA_PC,                            
                            S.TIPOPARCEIRO,
                            S.CODPARCEIRO
                            ORDER BY S.ANO, S.MES, S.CODREDUZIDO_PC, S.CODPARCEIRO) LOOP

      V_ROTINA := 'COD. REDUZIDO_PC:' || DADOS.CODREDUZIDO_PC || ' COD. FILIAL:' || DADOS.CODFILIAL;
      V_PASSO  := '--PASSO 6';
      IF DADOS.CODCONTA_PC IS NULL THEN
        V_PASSO := '--PASSO 7';
        SELECT CODCONTA_PC
          INTO V_CODCONTA
          FROM PCMODELOPC M
         WHERE M.CODPLANOCONTA = DADOS.CODPLANOCONTA
           AND M.CODREDUZIDO_PC = DADOS.CODREDUZIDO_PC;
      
      ELSE
        V_PASSO    := '--PASSO 8';
        V_CODCONTA := DADOS.CODCONTA_PC;
      
      END IF;
      V_PASSO := '--PASSO 9';
      V_SQL   := ' SELECT M.CODCONTA_PC,
                        M.CODREDUZIDO_PC
                 FROM PCMODELOPC M
                WHERE M.CODPLANOCONTA = :CODPLANOCONTA
                  AND (' ||
                 F_RETORNACONTASSINTETICAS(V_CODCONTA, 'M.CODCONTA_PC') || ')';
      V_PASSO := '--PASSO 10';
      OPEN L_CURSOR FOR V_SQL
        USING DADOS.CODPLANOCONTA;
      LOOP
        FETCH L_CURSOR
          INTO CONTASACIMA;
        EXIT WHEN L_CURSOR%NOTFOUND;
        BEGIN
          V_PASSO := '--PASSO 11';
        
          UPDATE PCSALDOPARCEIROS S
             SET S.VALORDEBITO              = DADOS.VALORDEBITO +
                                              S.VALORDEBITO,
                 S.VALORCREDITO             = DADOS.VALORCREDITO +
                                              S.VALORCREDITO,
                 S.VLRDEBENCERRAMENTO       = DADOS.VLRDEBENCERRAMENTO +
                                              S.VLRDEBENCERRAMENTO,
                 S.VLRCREDENCERRAMENTO       = DADOS.VLRCREENCERRAMENTO +
                                              S.VLRCREDENCERRAMENTO
           WHERE S.CODPLANOCONTA = DADOS.CODPLANOCONTA
             AND S.CODFILIAL = DADOS.CODFILIAL
             AND S.MES = DADOS.MES
             AND S.ANO = DADOS.ANO
             AND S.CODPARCEIRO = DADOS.CODPARCEIRO
             AND S.TIPOPARCEIRO = DADOS.TIPOPARCEIRO
             AND S.CODREDUZIDO_PC = CONTASACIMA.CODREDUZIDO_PC;
          V_PASSO := '--PASSO 12';
          IF SQL%ROWCOUNT = 0 THEN
            V_PASSO := '--PASSO 13';
            INSERT INTO PCSALDOPARCEIROS
              (CODFILIAL,
               CODPLANOCONTA,
               MES,
               ANO,
               CODREDUZIDO_PC,
               VALORDEBITO,
               VALORCREDITO,
               VLRDEBENCERRAMENTO,
               VLRCREDENCERRAMENTO,
               TIPOPARCEIRO,
               CODPARCEIRO)
            VALUES
              (DADOS.CODFILIAL,
               DADOS.CODPLANOCONTA,
               DADOS.MES,
               DADOS.ANO,
               CONTASACIMA.CODREDUZIDO_PC,
               DADOS.VALORDEBITO,
               DADOS.VALORCREDITO,
               DADOS.VLRDEBENCERRAMENTO,
               DADOS.VLRCREENCERRAMENTO,
               DADOS.TIPOPARCEIRO,
               DADOS.CODPARCEIRO);
            V_PASSO := '--PASSO 14';
          END IF;
          V_PASSO := '--PASSO 15';
        END;
        V_PASSO := '--PASSO 16';
      END LOOP;
      V_PASSO := '--PASSO 17';
      CLOSE L_CURSOR;
    END LOOP;    
    
    END IF;  
  
    V_PASSO := '--PASSO 5';
    FOR DADOS IN (SELECT SUM(VALORDEBITO) VALORDEBITO,
                         SUM(VALORCREDITO) VALORCREDITO,
                         SUM(VLRDEBENCERRAMENTO) VLRDEBENCERRAMENTO,
                         SUM(VLRCREENCERRAMENTO) VLRCREENCERRAMENTO,
                         SUM(VLRDEBCONCIL) VLRDEBCONCIL,
                         SUM(VLRCRECONCIL) VLRCRECONCIL,
                         SUM(VLRDEBCONCILENCERRAMENTO) VLRDEBCONCILENCERRAMENTO,
                         SUM(VLRCRECONCILENCERRAMENTO) VLRCRECONCILENCERRAMENTO,
                         S.MES,
                         S.ANO,
                         S.CODREDUZIDO_PC,
                         S.CODFILIAL,
                         S.CODPLANOCONTA,
                         MAX(S.CODIGO) CODIGO,
                         S.CODCONTA_PC,
                         S.ROTINA
                         
                    FROM PCFILASALDOCNB S
                   GROUP BY S.MES,
                            S.ANO,
                            S.CODREDUZIDO_PC,
                            S.CODFILIAL,
                            S.CODPLANOCONTA,
                            S.CODCONTA_PC,
                            S.ROTINA
                   ORDER BY MAX(S.CODIGO)) LOOP

      V_ROTINA := DADOS.ROTINA;
      V_PASSO  := '--PASSO 6';
      IF DADOS.CODCONTA_PC IS NULL THEN
        V_PASSO := '--PASSO 7';
        SELECT CODCONTA_PC
          INTO V_CODCONTA
          FROM PCMODELOPC M
         WHERE M.CODPLANOCONTA = DADOS.CODPLANOCONTA
           AND M.CODREDUZIDO_PC = DADOS.CODREDUZIDO_PC;
      
      ELSE
        V_PASSO    := '--PASSO 8';
        V_CODCONTA := DADOS.CODCONTA_PC;
      
      END IF;
      V_PASSO := '--PASSO 9';
      V_SQL   := ' SELECT M.CODCONTA_PC,
                        M.CODREDUZIDO_PC
                 FROM PCMODELOPC M
                WHERE M.CODPLANOCONTA = :CODPLANOCONTA
                  AND (' ||
                 F_RETORNACONTASSINTETICAS(V_CODCONTA, 'M.CODCONTA_PC') || ')';
      V_PASSO := '--PASSO 10';
      OPEN L_CURSOR FOR V_SQL
        USING DADOS.CODPLANOCONTA;
      LOOP
        FETCH L_CURSOR
          INTO CONTASACIMA;
        EXIT WHEN L_CURSOR%NOTFOUND;
        BEGIN
          V_PASSO := '--PASSO 11';
        
          UPDATE PCSALDO S
             SET S.VALORDEBITO              = DADOS.VALORDEBITO +
                                              S.VALORDEBITO,
                 S.VALORCREDITO             = DADOS.VALORCREDITO +
                                              S.VALORCREDITO,
                 S.VLRDEBENCERRAMENTO       = DADOS.VLRDEBENCERRAMENTO +
                                              S.VLRDEBENCERRAMENTO,
                 S.VLRCREENCERRAMENTO       = DADOS.VLRCREENCERRAMENTO +
                                              S.VLRCREENCERRAMENTO,
                 S.VLRDEBCONCIL             = DADOS.VLRDEBCONCIL +
                                              S.VLRDEBCONCIL,
                 S.VLRCRECONCIL             = DADOS.VLRCRECONCIL +
                                              S.VLRCRECONCIL,
                 S.VLRDEBCONCILENCERRAMENTO = DADOS.VLRDEBCONCILENCERRAMENTO +
                                              S.VLRDEBCONCILENCERRAMENTO,
                 S.VLRCRECONCILENCERRAMENTO = DADOS.VLRCRECONCILENCERRAMENTO +
                                              S.VLRCRECONCILENCERRAMENTO
           WHERE S.CODPLANOCONTA = DADOS.CODPLANOCONTA
             AND S.CODFILIAL = DADOS.CODFILIAL
             AND S.MES = DADOS.MES
             AND S.ANO = DADOS.ANO
             AND S.CODREDUZIDO_PC = CONTASACIMA.CODREDUZIDO_PC;
          V_PASSO := '--PASSO 12';
          IF SQL%ROWCOUNT = 0 THEN
            V_PASSO := '--PASSO 13';
            INSERT INTO PCSALDO
              (CODFILIAL,
               CODPLANOCONTA,
               MES,
               ANO,
               CODREDUZIDO_PC,
               VALORDEBITO,
               VALORCREDITO,
               VLRDEBENCERRAMENTO,
               VLRCREENCERRAMENTO,
               VLRDEBCONCIL,
               VLRCRECONCIL,
               VLRDEBCONCILENCERRAMENTO,
               VLRCRECONCILENCERRAMENTO)
            VALUES
              (DADOS.CODFILIAL,
               DADOS.CODPLANOCONTA,
               DADOS.MES,
               DADOS.ANO,
               CONTASACIMA.CODREDUZIDO_PC,
               DADOS.VALORDEBITO,
               DADOS.VALORCREDITO,
               DADOS.VLRDEBENCERRAMENTO,
               DADOS.VLRCREENCERRAMENTO,
               DADOS.VLRDEBCONCIL,
               DADOS.VLRCRECONCIL,
               DADOS.VLRDEBCONCILENCERRAMENTO,
               DADOS.VLRCRECONCILENCERRAMENTO);
            V_PASSO := '--PASSO 14';
          END IF;
          V_PASSO := '--PASSO 15';
        END;
        V_PASSO := '--PASSO 16';
      END LOOP;
      V_PASSO := '--PASSO 17';
      CLOSE L_CURSOR;
      V_PASSO          := '--PASSO 18';
      V_MAIOR_REGISTRO := DADOS.CODIGO;
      V_PASSO          := '--PASSO 19';
    END LOOP;
    V_PASSO := '--PASSO 20';
    DELETE PCFILASALDOCNB WHERE CODIGO <= V_MAIOR_REGISTRO;
    V_PASSO := '--PASSO 21';
    DELETE PCVERIFICAFILA;
    V_PASSO := '--PASSO 22';
    COMMIT;
    V_PASSO := '--PASSO 23';
  END IF;
  V_PASSO := '--PASSO 24';
EXCEPTION
  WHEN OTHERS THEN
    BEGIN
    
      VS_ERRO := 'Ocorreu erro ao executar o SQL de dados.' || CHR(13) ||
                 '------------------------------' || CHR(13) ||
                 'ERRO GERAL' || CHR(13) ||
                 '------------------------------' || CHR(13) ||
                 DBMS_UTILITY.FORMAT_ERROR_STACK || CHR(13) ||
                 '------------------------------' || CHR(13) ||
                 'INICIO DO ERRO' || CHR(13) ||
                 '------------------------------' || CHR(13) ||
                 DBMS_UTILITY.FORMAT_CALL_STACK ||
                 '------------------------------' || CHR(13) ||
                 'SEQUENCIA DE CHAMADAS' || CHR(13) ||
                 '------------------------------' || CHR(13) ||
                 DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    
      INSERT INTO PCLOGALTERACAODADOS
        (DATA, TABELA, VALORALFA, VALORALFAANT, OBSERVACOES2, OBSERVACOES)
      VALUES
        (SYSDATE,
         'PCFILASALDOCNB',
         SUBSTR(VS_ERRO, 1, 2000),
         SUBSTR(VS_ERRO, 2001, 4000),
         SUBSTR(VS_ERRO, 4001, 6000),
         V_PASSO || ' - ' || V_ROTINA);
      COMMIT;
    
    END;
  
END;

 
