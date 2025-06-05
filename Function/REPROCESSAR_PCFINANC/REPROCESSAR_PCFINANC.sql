CREATE OR REPLACE FUNCTION REPROCESSAR_PCFINANC(VDATA      IN DATE,
                                                VCODFILIAL IN VARCHAR2)
  RETURN VARCHAR2 IS
  VTOTALPCFINANC  NUMBER;
  VTOTALPCFINANC2 NUMBER;
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  BEGIN
    SELECT COUNT(1) TOTAL
      INTO VTOTALPCFINANC
      FROM PCFINANC
     WHERE DATA = VDATA
       AND CODFILIAL = VCODFILIAL
       AND LISTAFILIAISBANCOCAIXA = VCODFILIAL;
  
    SELECT COUNT(1) TOTAL
      INTO VTOTALPCFINANC2
      FROM PCFINANC2
     WHERE DATA = VDATA
       AND CODFILIAL = VCODFILIAL
       AND LISTAFILIAISBANCOCAIXA = VCODFILIAL;
  
    IF VTOTALPCFINANC = 0 AND VTOTALPCFINANC2 = 0 THEN
    
      --GERANDO A PCFINANC ZERADA
      INSERT INTO PCFINANC
        (DATA,
         CODFILIAL,
         SALDOEMPRESTATIVO,
         SALDOCX,
         SALDOINVESTATIVO,
         SALDOCRFOR,
         SALDOCTRANS,
         SALDOCP,
         SALDOEMPRESTPASSIVO,
         SALDOBCO,
         SALDOINVESTPASSIVO,
         SALDOCREDCLI,
         SALDOVALE,
         SALDOESTREAL,
         SALDOCR,
         CODROTINA,
         CODFUNC,
         DTGERACAO,
         SALDOESTFIN,
         SALDOADIANTFOR,
         LISTAFILIAISBANCOCAIXA,
         PARMULTIFILIALCAIXABANCO3882)
      VALUES
        (VDATA,
         VCODFILIAL,
         0,
         0,
         0,
         0,
         0,
         0,
         0,
         0,
         0,
         0,
         0,
         0,
         0,
         504,
         1,
         SYSDATE,
         0,
         0,
         VCODFILIAL,
         'N');
    
      --INICIO DE GERAÇÃO DE DADOS DA PCFINANC BUSCANDO DA PCFINANC2
      FOR FINANC2 IN (SELECT SUM(NVL(PCFINANC2.VALOR, 0)) VALOR,
                             PCFINANC2.DATA,
                             PCFINANC2.CODFILIAL,
                             PCFINANC2.TIPODADO,
                             NVL(PCFINANC2.LISTAFILIAISBANCOCAIXA, 'VAZIO') AS LISTAFILIAISBANCOCAIXA,
                             NVL(PCFINANC2.PARMULTIFILIALCAIXABANCO3882, 'N') AS PARMULTIFILIALCAIXABANCO3882
                        FROM PCFINANC2
                       WHERE PCFINANC2.DATA = VDATA
                         AND PCFINANC2.CODFILIAL = VCODFILIAL
                       GROUP BY PCFINANC2.DATA,
                                PCFINANC2.CODFILIAL,
                                PCFINANC2.TIPODADO,
                                PCFINANC2.LISTAFILIAISBANCOCAIXA,
                                PCFINANC2.PARMULTIFILIALCAIXABANCO3882) LOOP
        /*ATUALIZANDO SALDOS DA PCFINANC*/
        UPDATE PCFINANC
           SET PCFINANC.SALDOEMPRESTATIVO = DECODE(TRIM(FINANC2.TIPODADO),
                                                   'EMPRESTA',
                                                   FINANC2.VALOR,
                                                   PCFINANC.SALDOEMPRESTATIVO),
               PCFINANC.SALDOCX           = DECODE(TRIM(FINANC2.TIPODADO),
                                                   'CAIXA',
                                                   FINANC2.VALOR,
                                                   PCFINANC.SALDOCX),
               PCFINANC.SALDOINVESTATIVO  = DECODE(TRIM(FINANC2.TIPODADO),
                                                   'INVEST',
                                                   FINANC2.VALOR,
                                                   PCFINANC.SALDOINVESTATIVO),
               PCFINANC.SALDOCRFOR        = DECODE(TRIM(FINANC2.TIPODADO),
                                                   'CRFORNEC',
                                                   FINANC2.VALOR,
                                                   PCFINANC.SALDOCRFOR),
               PCFINANC.SALDOCTRANS       = DECODE(TRIM(FINANC2.TIPODADO),
                                                   'CTRANS',
                                                   FINANC2.VALOR,
                                                   PCFINANC.SALDOCTRANS),
               PCFINANC.SALDOCP           = DECODE(TRIM(FINANC2.TIPODADO),
                                                   'CPAGAR',
                                                   FINANC2.VALOR,
                                                   PCFINANC.SALDOCP)
               --,PCFINANC.SALDOEMPRESTPASSIVO = DECODE (TRIM(FINANC2.TIPODADO), 'EMPRESTP' , FINANC2.VALOR, PCFINANC.SALDOEMPRESTPASSIVO)
              ,
               PCFINANC.SALDOEMPRESTPASSIVO        = PCFINANC.SALDOEMPRESTPASSIVO +
                                                     DECODE(TRIM(FINANC2.TIPODADO),
                                                            'EMPRESTP',
                                                            FINANC2.VALOR,
                                                            'FINIMP',
                                                            FINANC2.VALOR,
                                                            0),
               PCFINANC.SALDOBCO                   = DECODE(TRIM(FINANC2.TIPODADO),
                                                            'BANCO',
                                                            FINANC2.VALOR,
                                                            PCFINANC.SALDOBCO),
               PCFINANC.SALDOINVESTPASSIVO         = DECODE(TRIM(FINANC2.TIPODADO),
                                                            'INVESTP',
                                                            FINANC2.VALOR,
                                                            PCFINANC.SALDOINVESTPASSIVO),
               PCFINANC.SALDOCREDCLI               = DECODE(TRIM(FINANC2.TIPODADO),
                                                            'CREDCLI',
                                                            FINANC2.VALOR,
                                                            PCFINANC.SALDOCREDCLI),
               PCFINANC.SALDOVALE                  = DECODE(TRIM(FINANC2.TIPODADO),
                                                            'VALE',
                                                            FINANC2.VALOR,
                                                            PCFINANC.SALDOVALE),
               PCFINANC.SALDOESTREAL               = DECODE(TRIM(FINANC2.TIPODADO),
                                                            'ESTOQUE',
                                                            FINANC2.VALOR,
                                                            PCFINANC.SALDOESTREAL),
               PCFINANC.SALDOCR                    = DECODE(TRIM(FINANC2.TIPODADO),
                                                            'CRECEBER',
                                                            FINANC2.VALOR,
                                                            PCFINANC.SALDOCR),
               PCFINANC.SALDOADIANTFOR             = DECODE(TRIM(FINANC2.TIPODADO),
                                                            'ADFORNEC',
                                                            FINANC2.VALOR,
                                                            PCFINANC.SALDOADIANTFOR),
               PCFINANC.SALDOESTFIN                = DECODE(TRIM(FINANC2.TIPODADO),
                                                            'ESTOQUE',
                                                            FINANC2.VALOR,
                                                            PCFINANC.SALDOESTFIN),
               PCFINANC.SALDOTITULOVENDOR          = DECODE(TRIM(FINANC2.TIPODADO),
                                                            'VENDOR',
                                                            FINANC2.VALOR,
                                                            PCFINANC.SALDOTITULOVENDOR),
               PCFINANC.SALDOCPOUTROS              = DECODE(TRIM(FINANC2.TIPODADO),
                                                            'CPOUTROS',
                                                            FINANC2.VALOR,
                                                            PCFINANC.SALDOCPOUTROS),
               PCFINANC.SALDOESTOQUECONSUMOINTERNO = DECODE(TRIM(FINANC2.TIPODADO),
                                                            'ESTOQUECI',
                                                            FINANC2.VALOR,
                                                            PCFINANC.SALDOESTOQUECONSUMOINTERNO)
         WHERE PCFINANC.DATA = FINANC2.DATA
           AND PCFINANC.CODFILIAL = FINANC2.CODFILIAL
           AND NVL(PCFINANC.PARMULTIFILIALCAIXABANCO3882, 'N') =
               NVL(FINANC2.PARMULTIFILIALCAIXABANCO3882, 'N');
      END LOOP;
    
      -- FINAL DA ATUALIZAÇÃO DOS SALDOS DA PCFINANC
    
      -- ATUALIZANDO SALDOREAL E SALDOFIN
    
      UPDATE PCFINANC
         SET PCFINANC.SALDOREAL = PCFINANC.SALDOCX /*CAIXA*/
                                  +PCFINANC.SALDOBCO /*BANCO*/
                                  +PCFINANC.SALDOVALE /*VALES*/
                                  +PCFINANC.SALDOEMPRESTATIVO /*EMPREST. ATIVO*/
                                  +PCFINANC.SALDOCTRANS /*CONTAS TRANSITORIAS*/
                                  +PCFINANC.SALDOCR /*CONTAS A RECEBER*/
                                  +PCFINANC.SALDOCRFOR /*CONTAS A RECEBER DE FORNECEDOR*/
                                  +PCFINANC.SALDOESTFIN /*VL. ESTOQUE*/
                                  +PCFINANC.SALDOINVESTATIVO /*INVEST. ATIVO*/
                                  +PCFINANC.SALDOADIANTFOR /*ADIANT. DE FORNEC.*/
                                  -PCFINANC.SALDOCP /*CONTAS A PAGAR*/
                                  -PCFINANC.SALDOEMPRESTPASSIVO /*EMP. PASSIVO*/
                                  -PCFINANC.SALDOCREDCLI /*CREDITO DE CLIENTE*/
                                  -PCFINANC.SALDOINVESTPASSIVO /*INVEST. PASSIVO*/
                                  -PCFINANC.SALDOTITULOVENDOR /*TÍTULOS DESCONTADOR/VENDOR*/
                                  -PCFINANC.SALDOCPOUTROS /*CONTAS A PAGAR OUTROS FORNECEDORES*/
             
            ,
             PCFINANC.SALDOFIN = PCFINANC.SALDOCX /*CAIXA*/
                                 +PCFINANC.SALDOBCO /*BANCO*/
                                 +PCFINANC.SALDOVALE /*VALES*/
                                 +PCFINANC.SALDOEMPRESTATIVO /*EMPREST. ATIVO*/
                                 +PCFINANC.SALDOCTRANS /*CONTAS TRANSITORIAS*/
                                 +PCFINANC.SALDOCR /*CONTAS A RECEBER*/
                                 +PCFINANC.SALDOCRFOR /*CONTAS A RECEBER DE FORNECEDOR*/
                                 +PCFINANC.SALDOESTFIN /*VL. ESTOQUE*/
                                 +PCFINANC.SALDOINVESTATIVO /*INVEST. ATIVO*/
                                 +PCFINANC.SALDOADIANTFOR /*ADIANT. DE FORNEC.*/
                                 -PCFINANC.SALDOCP /*CONTAS A PAGAR*/
                                 -PCFINANC.SALDOEMPRESTPASSIVO /*EMP. PASSIVO*/
                                 -PCFINANC.SALDOCREDCLI /*CREDITO DE CLIENTE*/
                                 -PCFINANC.SALDOINVESTPASSIVO /*INVEST. PASSIVO*/
                                 -PCFINANC.SALDOTITULOVENDOR /*TÍTULOS DESCONTADOR/VENDOR*/
                                 -PCFINANC.SALDOCPOUTROS /*CONTAS A PAGAR OUTROS FORNECEDORES*/
       WHERE PCFINANC.DATA = VDATA
         AND PCFINANC.CODFILIAL = VCODFILIAL;
    
      --ATUALIZANDO SALDOCPMANUAL
      UPDATE PCFINANC
         SET PCFINANC.SALDOCPMANUAL =
             (SELECT NVL(SUM(NVL(PCLANC.VALOR, 0) -
                             NVL(PCLANC.DESCONTOFIN, 0) +
                             NVL(PCLANC.TXPERM, 0) - NVL(PCLANC.VALORDEV, 0)),
                         0)
                FROM PCLANC, PCCONSUM
               WHERE PCLANC.DTPAGTO IS NULL
                 AND PCLANC.CODCONTA <> PCCONSUM.CODCONTAJUSTEEST
                 AND PCLANC.CODCONTA <> PCCONSUM.CODCONTRECJUR
                 AND PCLANC.CODCONTA <> PCCONSUM.CODCONTPAGJUR
                 AND PCLANC.CODCONTA <> PCCONSUM.CODCONTANTPAG
                 AND PCLANC.CODFILIAL IN (VCODFILIAL))
       WHERE PCFINANC.DATA = VDATA
         AND PCFINANC.CODFILIAL = VCODFILIAL;
    
      --FINALIZANDO CALCULO DO SALDOCPMANUAL SUBTRAINDO DO SALDOCP
      UPDATE PCFINANC
         SET SALDOCPMANUAL = SALDOCPMANUAL - SALDOCP
       WHERE CODFILIAL = VCODFILIAL
         AND DATA = VDATA;
    
      COMMIT;
    
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20001, ('ERRO'));
  END;

  RETURN 'OK';

END;
