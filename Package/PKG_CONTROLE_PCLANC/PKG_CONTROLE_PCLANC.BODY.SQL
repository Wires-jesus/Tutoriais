CREATE OR REPLACE PACKAGE BODY PKG_CONTROLE_PCLANC
IS

VGRECNUMNOVO  NUMBER;

    PROCEDURE LANCAR_CONTRAPARTIDA_CC
    ( PNRECNUMORIG IN NUMBER
    , PNRECNUMDEST IN NUMBER
    , PNTIPO       IN VARCHAR2);

  PROCEDURE GERAR_PCMOVCR
   ( PSFORMAPAGAMENTO IN VARCHAR
    , PSNATUREZA       IN VARCHAR
    , PSHISTORICO      IN VARCHAR
    , PSHISTORICO2     IN VARCHAR
    , PNNUMERARIO      IN NUMBER
    , PNNUMBANCO       IN NUMBER
    , PSMOEDA          IN VARCHAR
    , PNNUMTRANS       IN NUMBER
    , PNCODFUNCIONARIO IN NUMBER
    , PNCODROTINA      IN NUMBER
    , PNCODCONTABIL    IN NUMBER
    , PNVALORPCMOVCR   IN NUMBER
    , PNNUMNOTA        IN NUMBER
    , PNNUMCARR        IN NUMBER
    , PDDTCOMPENSACAO    IN DATE
    );

   /*****************************************************************************
   Descri??o: Obter o pr?ximo recnum
   Data.....: 20/02/2013
   Autor....: Fernando.Carmo
   *****************************************************************************/
   FUNCTION GERAR_RECNUM
      RETURN NUMBER
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      VNVALOR   NUMBER;
   BEGIN
      --Obtendo o valor do pr?ximo recnum
      SELECT PCCONSUM.PROXNUMLANC
        INTO VNVALOR
        FROM PCCONSUM
         FOR UPDATE;

      --Atualizando o proximo n?mero
      UPDATE PCCONSUM
         SET PCCONSUM.PROXNUMLANC = PCCONSUM.PROXNUMLANC + 1;

      COMMIT;
      --Retornando valor encontrado
      RETURN VNVALOR;
   END;

   /*****************************************************************************
   Descri??o: Obter o saldo atual do PCESTCR
   Data.....: 20/02/2013
   Autor....: Fernando.Carmo
   *****************************************************************************/
   FUNCTION OBTER_SALDO_PCESTCR
    ( PNNUMBANCO          IN NUMBER
    , PSCODMOEDA          IN VARCHAR
    , PNVALOR             IN NUMBER)
      RETURN NUMBER
    IS VNSALDO   NUMBER;
    BEGIN
      --Coloca o valor passado como parametro negativo, para caso n?o exista
      --Registro na tabela este ser? o saldo de partida deste banco/moeda
--      VNSALDO := NVL(PNVALOR,0) * (-1);

      BEGIN --Obtendo o saldo atual
        SELECT NVL(PCESTCR.VALOR, 0) - PNVALOR
          INTO VNSALDO
          FROM PCESTCR
         WHERE PCESTCR.CODBANCO = PNNUMBANCO
           AND PCESTCR.CODCOB = PSCODMOEDA
           FOR UPDATE;

         --Atualizando o saldo
         UPDATE PCESTCR
            SET PCESTCR.VALOR = NVL(PCESTCR.VALOR, 0) - PNVALOR
          WHERE PCESTCR.CODBANCO = PNNUMBANCO
            AND PCESTCR.CODCOB = PSCODMOEDA;

        EXCEPTION
          WHEN NO_DATA_FOUND THEN --Caso n?o tenha o saldo gera o lan?amento negativo

            IF VNSALDO IS NULL OR NVL(VNSALDO,0) = 0 THEN --Caso n?o exista nenhum saldo anterior, o saldo a ser inserido recebe o lan?amento negativo
              VNSALDO := PNVALOR * (-1);
            END IF;
            INSERT INTO PCESTCR (CODBANCO, CODCOB, VALOR)
                         VALUES (PNNUMBANCO, PSCODMOEDA, VNSALDO);


      END;

      --Retornando valor encontrado
      RETURN VNSALDO;
    END;

   /*****************************************************************************
   Descri??o: Baixa de t?tulos
   Data.....: 20/02/2013
   Autor....: Fernando.Carmo
   *****************************************************************************/
   PROCEDURE BAIXAR
    ( PSFORMAPAGAMENTO   IN VARCHAR  --(B)order?, (C)heque, Cai(X)a/Banco
    , PSHISTORICO        IN VARCHAR  --Hist?rico a ser informado no t?tulos
    , PSNOMEFUNCIONARIO  IN VARCHAR  --Nome do funcion?rio da baixa
    , PNNUMERARIO        IN NUMBER   --C?digo da transa??o: N?m. border?, N?m. cheque2 ou N?m. Transa??o, conforme a forma pagto
    , PNNUMBANCO         IN NUMBER   --N?mero do banco da baixa
    , PSMOEDA            IN VARCHAR  --Moeda
    , PNCODFUNCIONARIO   IN NUMBER   --C?digo do funcion?rio que esta baixando o t?tulo
    , PNCODROTINA        IN NUMBER   --C?digo da rotina que esta executando a baixa
    , PNNUMTRANS         IN NUMBER   --N?mero de transa??o da baixa
    , PNNUMNOTA          IN NUMBER   --N?mero da nota fiscal
    , PNNUMCARR          IN NUMBER
    , PNCODCONTA         IN NUMBER
    , PNCODPROJETO       IN NUMBER
    , PSMENSAGEM        OUT VARCHAR
    , PDDTCOMPENSACAO    IN DATE default null
    )
   IS
     VNVALORPAGAMENTO       NUMBER;
     VNCODCONTABIL          NUMBER;
     VNDESCONTO_FINANCEIRO  NUMBER;
     VNDESCONTO_VERBA       NUMBER;
     VNDESCONTO_DEV_VERBA   NUMBER;
     VSSCRIPT              VARCHAR2(500);
   BEGIN
     BEGIN
       --Valida??o das contas
       IF PARAMFILIAL.obtercomonumber('CON_CODCONTANTPAG') IS NULL THEN
         PSMENSAGEM := '{Par?metro n?o informado "1358 - C?d. conta desconto financeiro". Processo de baixa ser? abortado!}';
         RAISE_APPLICATION_ERROR(-20016,PSMENSAGEM);
       END IF;
       IF PARAMFILIAL.obtercomonumber('CON_CODCONTPAGJUR') IS NULL THEN
         PSMENSAGEM := '{Par?metro n?o informado "1360 - Conta para pagamento de juros". Processo de baixa ser? abortado!}';
         RAISE_APPLICATION_ERROR(-20016,PSMENSAGEM);
       END IF;

       --Obtendo o valor total do pagamento e o código contabil
       SELECT SUM(NVL(PCLANC.VALOR, 0)
                - NVL(PCLANC.VALORDEV, 0)
                + NVL(PCLANC.TXPERM, 0)
                - NVL(PCLANC.DESCONTOFIN, 0)
                + NVL(PCLANC.VLVARIACAOCAMBIAL,0))
            , MAX(PCBANCO.CODCONTABIL)
         INTO VNVALORPAGAMENTO
            , VNCODCONTABIL
         FROM PCLANC
            , PCBANCO
        WHERE PCLANC.NUMBANCO    = PCBANCO.CODBANCO
          AND PCLANC.NUMBANCO    = PNNUMBANCO
          AND ((PSFORMAPAGAMENTO = 'B' AND PCLANC.NUMBORDERO = PNNUMERARIO)
           OR  (PSFORMAPAGAMENTO = 'C' AND PCLANC.NUMCHEQUE2 = PNNUMERARIO)
           OR  (PSFORMAPAGAMENTO = 'X' AND PCLANC.NUMTRANS = PNNUMERARIO))
           AND PCLANC.DTESTORNOBAIXA IS NULL;

       --Efetuando a baixa dos titulos selecionados
       UPDATE PCLANC
          SET PCLANC.VPAGO = NVL(PCLANC.VALOR, 0)
                           - NVL(PCLANC.VALORDEV, 0)
            , PCLANC.VPAGOBORDERO = CASE WHEN PSFORMAPAGAMENTO = 'X'
                                         THEN NULL
                                         ELSE NVL(PCLANC.VALOR, 0)
                                            - NVL(PCLANC.VALORDEV, 0)
                                            + NVL(PCLANC.TXPERM, 0)
                                            - NVL(PCLANC.DESCONTOFIN, 0)
                                            + NVL(PCLANC.VLVARIACAOCAMBIAL,0)
                                    END
            , PCLANC.LOCALIZACAO = DECODE(TRIM(NVL(PCLANC.LOCALIZACAO, ''))
                                         , '', TO_CHAR(PNNUMTRANS)
                                             , PCLANC.LOCALIZACAO)
            , PCLANC.DTPAGTO        = TRUNC(SYSDATE)
            , PCLANC.CODFUNCBAIXA   = PNCODFUNCIONARIO
            , PCLANC.CODROTINABAIXA = PNCODROTINA
            , PCLANC.NUMBANCO       = PNNUMBANCO
            , PCLANC.NUMTRANS       = DECODE(VNVALORPAGAMENTO,0,NULL,DECODE(NVL(PNNUMTRANS,0), 0, PCLANC.NUMTRANS, PNNUMTRANS))
            , PCLANC.CODCONTA       = DECODE(NVL(PNCODCONTA,0), 0, PCLANC.CODCONTA, PNCODCONTA)
            , PCLANC.CODPROJETO     = DECODE(NVL(PNCODPROJETO,0), 0, PCLANC.CODPROJETO, PNCODPROJETO)
            , PCLANC.NUMNOTA        = DECODE(NVL(PNNUMNOTA,0), 0, PCLANC.NUMNOTA, PNNUMNOTA)
       WHERE PCLANC.DTPAGTO IS NULL
         AND PCLANC.NUMBANCO    = PNNUMBANCO
         AND ((PSFORMAPAGAMENTO = 'B' AND PCLANC.NUMBORDERO = PNNUMERARIO)
          OR  (PSFORMAPAGAMENTO = 'C' AND PCLANC.NUMCHEQUE2 = PNNUMERARIO)
          OR  (PSFORMAPAGAMENTO = 'X' AND PCLANC.NUMTRANS = PNNUMERARIO));

       IF SQL%ROWCOUNT = 0 THEN --VALIDA??O PARA QUE ENTRAR NA EXCESS?O SE N?O TIVER CONSEGUIDO FAZER A BAIXA DO BORDER?!
         RAISE NO_DATA_FOUND;
       END IF;

     EXCEPTION --Caso n?o tenha alterado nenhum registro
       WHEN NO_DATA_FOUND THEN
         RAISE_APPLICATION_ERROR(-20016,'Erro: Nenhum titulo encontrado para ser baixado.'|| SQLERRM);
         PSMENSAGEM := 'Erro:' || SQLERRM;
     END;

     BEGIN
       FOR REGISTROS IN (SELECT CODFILIAL
                              , PARAMFILIAL.OBTERCOMONUMBER('FIL_NUMMAXDIASRETRODTCOMPENSACAO',CODFILIAL) MAXDIAS
                           FROM PCLANC
                          WHERE NUMBANCO = PNNUMBANCO
                            AND ((PSFORMAPAGAMENTO = 'B' AND PCLANC.NUMBORDERO = PNNUMERARIO)
                             OR  (PSFORMAPAGAMENTO = 'C' AND PCLANC.NUMCHEQUE2 = PNNUMERARIO)
                             OR  (PSFORMAPAGAMENTO = 'X' AND PCLANC.NUMTRANS = PNNUMERARIO))
                       GROUP BY CODFILIAL)
       LOOP
         IF REGISTROS.MAXDIAS > 0 AND
            PDDTCOMPENSACAO < TRUNC(SYSDATE) - REGISTROS.MAXDIAS
         THEN
           PSMENSAGEM := 'A data de compensa??o informada ? menor que o maior permitido no par?metro 2137 da rotina 132!';
           RAISE_APPLICATION_ERROR(-20017,PSMENSAGEM);
         END IF;
       END LOOP;

        --Lan?ar juros, descontos ou varia??o cambial
       FOR REGISTROS IN (SELECT PCLANC.RECNUM
                              , PCLANC.CODFILIAL
                              , NVL(PCLANC.TXPERM, 0) VLJUROS
                              , NVL(PCLANC.DESCONTOFIN, 0) VLDESCONTOS
                              , NVL(PCLANC.VLVARIACAOCAMBIAL, 0) VLVARIACAOCAMBIAL
                              , NVL(PCLANC.VALORDEV, 0) VLDEVOLUCAO
                           FROM PCLANC
                          WHERE PCLANC.NUMBANCO = PNNUMBANCO
                            AND PCLANC.VALOR > 0
                            AND ((PCLANC.TXPERM > 0)
                             OR  (PCLANC.DESCONTOFIN > 0)
                             OR  (PCLANC.VLVARIACAOCAMBIAL <> 0)
                             OR  (PCLANC.VALORDEV <> 0))
                            AND ((PSFORMAPAGAMENTO = 'B' AND PCLANC.NUMBORDERO = PNNUMERARIO)
                             OR  (PSFORMAPAGAMENTO = 'C' AND PCLANC.NUMCHEQUE2 = PNNUMERARIO)
                             OR  (PSFORMAPAGAMENTO = 'X' AND PCLANC.NUMTRANS = PNNUMERARIO)))
       LOOP
         --Valor de devolucao
         IF (REGISTROS.VLDEVOLUCAO > 0) THEN
         BEGIN
            SELECT NVL(SUM(PCMOVCRFOR.VALOR), 0) VALORDEV
              INTO VNDESCONTO_DEV_VERBA
              FROM PCMOVCRFOR, PCVERBA
             WHERE PCVERBA.NUMVERBA     = PCMOVCRFOR.NUMVERBA
               AND PCVERBA.ORIGEM       = 'D' 
               AND PCMOVCRFOR.NUMLANC   = REGISTROS.RECNUM
               AND PCMOVCRFOR.CODFILIAL = REGISTROS.CODFILIAL
               AND PCMOVCRFOR.TIPO      = 'C'
               AND PCMOVCRFOR.DTESTORNO IS NULL;
         EXCEPTION --Caso n?o tenha alterado nenhum registro
          WHEN OTHERS THEN
            VNDESCONTO_DEV_VERBA := 0;
         END;
         ELSE
            VNDESCONTO_DEV_VERBA := 0;
         END IF;

         --Inicializando variavel que ira calcular o desconto financeiro
         VNDESCONTO_VERBA := 0;
         VNDESCONTO_FINANCEIRO := 0;

         --Gerando lan?amentos de desconto em verbas com base no recnum informado
         IF (REGISTROS.VLDESCONTOS > 0) THEN
           VNDESCONTO_FINANCEIRO := REGISTROS.VLDESCONTOS;
         END IF;

           IF (REGISTROS.VLDEVOLUCAO > 0) THEN
             VNDESCONTO_FINANCEIRO := VNDESCONTO_FINANCEIRO + VNDESCONTO_DEV_VERBA;
           END IF;

           --Um lan?amento para cada cr?dito de verba vinculado a duplicata
           FOR DEVOLUCOES IN (SELECT PCMOVCRFOR.CODCONTA,
                                     SUM(DECODE(PCMOVCRFOR.TIPO, 'C', PCMOVCRFOR.VALOR, PCMOVCRFOR.VALOR * (-1))) AS VLDESCVERBA --Deve ser gerado negativo
                                FROM PCMOVCRFOR
                               WHERE PCMOVCRFOR.NUMLANC = REGISTROS.RECNUM
                                 AND PCMOVCRFOR.DTESTORNO IS NULL
                               GROUP BY PCMOVCRFOR.CODCONTA)LOOP
             --Totalizando o total do desconto utilizado em verbas
             VNDESCONTO_VERBA := VNDESCONTO_VERBA + DEVOLUCOES.VLDESCVERBA;

             VNDESCONTO_FINANCEIRO := VNDESCONTO_FINANCEIRO - ROUND(DEVOLUCOES.VLDESCVERBA, 2);

             IF ABS(DEVOLUCOES.VLDESCVERBA) > 0 THEN
               VSSCRIPT := 'begin PKG_CONTROLE_PCLANC.LANCAMENTOS_ADICIONAIS(''DESCONTO FINANC. PAG. DUPLICATA'','
                               || TO_CHAR(REGISTROS.RECNUM)
                               || ','
                               || REPLACE(TO_CHAR(DEVOLUCOES.VLDESCVERBA * -1), ',', '.') --Juros deve ser lan?ados negativos
                               || ','
                               ||  DEVOLUCOES.CODCONTA
                               || '); end;';
               EXECUTE IMMEDIATE VSSCRIPT;
             END IF;
           END LOOP; --Fim do la?o DEVOLUCOES

         --Totalizando o saldo do desconto que N?O foi utilizado na verba para ser aplicado junto com o desconto financeiro
         VNDESCONTO_FINANCEIRO := ABS(VNDESCONTO_FINANCEIRO) * -1;
         --Gerando lan?amento de descontos com base no recnum informado
         IF (VNDESCONTO_FINANCEIRO < 0) THEN
           VSSCRIPT := 'begin PKG_CONTROLE_PCLANC.LANCAMENTOS_ADICIONAIS(''DESCONTO FINANC. PAG. DUPLICATA'','
                          || TO_CHAR(REGISTROS.RECNUM)
                          || ','
                          || REPLACE(TO_CHAR(VNDESCONTO_FINANCEIRO), ',', '.')
                          || ','
                          ||  PARAMFILIAL.obtercomonumber('CON_CODCONTANTPAG')
                          || '); end;';
           EXECUTE IMMEDIATE VSSCRIPT;
         END IF;

         --Gerando lan?amento de juros com base no recnum informado
         IF (REGISTROS.VLJUROS > 0) THEN
           VSSCRIPT := 'begin PKG_CONTROLE_PCLANC.LANCAMENTOS_ADICIONAIS(''JUROS PAG. DUPLICATA'','
                          || TO_CHAR(REGISTROS.RECNUM)
                          || ','
                          || REPLACE(TO_CHAR(REGISTROS.VLJUROS), ',', '.') --Juros deve ser lan?ados negativos
                          || ','
                          ||  PARAMFILIAL.obtercomonumber('CON_CODCONTPAGJUR')
                          || '); end;';
           EXECUTE IMMEDIATE VSSCRIPT;
         END IF;

         --Gerando lan?amento de varia??o cambial com base no recnum informado
         IF (REGISTROS.VLVARIACAOCAMBIAL > 0) OR (REGISTROS.VLVARIACAOCAMBIAL < 0) THEN
         BEGIN
           IF PARAMFILIAL.obtercomonumber('CON_CODCONTACAMBIAL') IS NULL THEN
             PSMENSAGEM := '{Par?metro n?o informado "1232 - Conta da varia??o cambial". Processo de baixa ser? abortado!}';
             RAISE_APPLICATION_ERROR(-20016,PSMENSAGEM);
           END IF;

           IF (REGISTROS.VLVARIACAOCAMBIAL > 0) THEN --AGIO
             VSSCRIPT := 'begin PKG_CONTROLE_PCLANC.LANCAMENTOS_ADICIONAIS(''VARIACAO CAMBIAL AGIO'','
                            || TO_CHAR(REGISTROS.RECNUM)
                            || ','
                            || REPLACE(TO_CHAR(REGISTROS.VLVARIACAOCAMBIAL), ',', '.')
                            || ','
                            ||  PARAMFILIAL.obtercomonumber('CON_CODCONTACAMBIAL')
                            || '); end;';
             EXECUTE IMMEDIATE VSSCRIPT;
           ELSIF (REGISTROS.VLVARIACAOCAMBIAL < 0) THEN --DESAGIO
             VSSCRIPT := 'begin PKG_CONTROLE_PCLANC.LANCAMENTOS_ADICIONAIS(''VARIACAO CAMBIAL DESAGIO'','
                            || TO_CHAR(REGISTROS.RECNUM)
                            || ','
                            || REPLACE(TO_CHAR(REGISTROS.VLVARIACAOCAMBIAL), ',', '.')
                            || ','
                            ||  PARAMFILIAL.obtercomonumber('CON_CODCONTACAMBIAL')
                            || '); end;';
             EXECUTE IMMEDIATE VSSCRIPT;
           END IF;
         END;
         END IF;
       END LOOP; --Fim do la?o REGISTROS

       IF (VNVALORPAGAMENTO > 0) THEN
       BEGIN
         -- GERAR_PCMOVCR
         GERAR_PCMOVCR(PSFORMAPAGAMENTO
                     , 'C'
                     , PSHISTORICO
                     , SUBSTR((CASE WHEN PSFORMAPAGAMENTO = 'B' THEN 'VL.PAGTO.CF.BORDERO ' || PNNUMERARIO
                                    WHEN PSFORMAPAGAMENTO = 'C' THEN 'VL.PAGTO.CF.CH.NUM. ' || PNNUMBANCO || '/' || PNNUMERARIO
                                    WHEN PSFORMAPAGAMENTO = 'X' THEN 'VL.PAGTO.CF.CAIXA '  || PNNUMERARIO
                                    ELSE NULL
                                    END),1,40) -- HISTORICO2
                     , PNNUMERARIO
                     , PNNUMBANCO
                     , PSMOEDA
                     , PNNUMTRANS
                     , PNCODFUNCIONARIO
                     , PNCODROTINA
                     , VNCODCONTABIL
                     , VNVALORPAGAMENTO
                     , PNNUMNOTA
                     , PNNUMCARR
                     , PDDTCOMPENSACAO);
         EXCEPTION --Caso n?o tenha alterado nenhum registro
           WHEN NO_DATA_FOUND THEN
             RAISE_APPLICATION_ERROR(-20016,'Erro: ao efetuar lançamentos adicionais baixado.'|| SQLERRM);
             PSMENSAGEM := 'Erro:' || SQLERRM;
         END;
       END IF;
      END;

     PSMENSAGEM := 'Baixa realizada com sucesso!';
   END; --Procedure Baixar
   /******************************************************** Baixa de t?tulos **/

   /*****************************************************************************
   Descri??o: Lan?amentos de juros durante a baixa de t?tulos
   Data.....: 20/02/2013
   Autor....: Fernando.Carmo
   *****************************************************************************/
   PROCEDURE LANCAMENTOS_ADICIONAIS( PSHISTORICO IN VARCHAR
                                   , PNRECNUM    IN NUMBER
                                   , PNVALOR     IN NUMBER
                                   , PNCODCONTA  IN NUMBER)
   IS --Declara??o das variaveis
      VNNOVORECNUM    NUMBER;
      VSSCRIPTINSERT  VARCHAR2(32767);
      VSSCRIPTSELECT  VARCHAR2(32767);
     VPARAMVARIACAOCAMBIAL VARCHAR2(1);
      CURSOR CURSOR_TABELA --Campos da tabela PCLANC
      IS
         SELECT COLUMN_NAME COLUNA
           FROM USER_TAB_COLUMNS
          WHERE UPPER(TABLE_NAME) = 'PCLANC'
            AND COLUMN_NAME NOT IN
                   ('RECNUM' --Colunas que terão um tratamento especial
                  , 'VALOR'
                  , 'VPAGOBORDERO'
                  , 'VPAGO'
                  , 'VLVARIACAOCAMBIAL'
                  , 'VALORDEV'
                  , 'VLCSRF'
                  , 'VLDESPFIN'
                  , 'VLINSS'
                  , 'VLINSSTOMADOR'
                  , 'VLIRRF'
                  , 'VLISS'
                  , 'VLOUTRAS'
                  , 'VLPIS'
                  , 'VLRPARIDADEMOEDA'
                  , 'VLRUTILIZADOADIANTFORNEC'
                  , 'VLSESTSENAT'
                  , 'TXPERM'
                  , 'DESCONTOFIN'
                  , 'DTLANC'
                  , 'CODROTINACAD'
                  , 'CODCONTA'
                  , 'LOCALIZACAO'
                  , 'NUMSEQBORDERO'
                  , 'HISTORICO'
                  , 'HISTORICO2'
                  , 'DTASSINATURA'
                  , 'ASSINATURA'
                  , 'MOEDAESTRANGEIRA'
                  , 'COTACAO'
                  , 'DTCOTACAO'
                  , 'VALORMOEDAESTRANGEIRA'
                  , 'RECNUMBAIXA'
                  , 'DTCOMPETENCIA'
                  , 'CODSERVICOSPEDEFD'
                  , 'MOEDA'
                  , 'COTACAOBAIXA'
                  , 'DTCOTACAOBAIXA'
                  , 'VLVARIACAOCAMBIAL'
                  );

      LINHA_TABELA_SELECIONADA   CURSOR_TABELA%ROWTYPE;
   BEGIN
      -- Inicializando as variaveis
      VPARAMVARIACAOCAMBIAL      := PARAMFILIAL.ObterComoVarchar2('VARIACAOCAMBIAL');
      VSSCRIPTINSERT             := 'INSERT INTO PCLANC (';
      VSSCRIPTSELECT             := 'SELECT ';
      --Listando os campos da tabela
      OPEN CURSOR_TABELA;
      LOOP
         FETCH CURSOR_TABELA
          INTO LINHA_TABELA_SELECIONADA;

         EXIT WHEN CURSOR_TABELA%NOTFOUND;
         VSSCRIPTINSERT := VSSCRIPTINSERT || LINHA_TABELA_SELECIONADA.COLUNA || ', ';
         VSSCRIPTSELECT := VSSCRIPTSELECT || LINHA_TABELA_SELECIONADA.COLUNA || ', ';
      END LOOP;

      CLOSE CURSOR_TABELA;

      VNNOVORECNUM :=  PKG_CONTROLE_PCLANC.GERAR_RECNUM();
      --Novo Recnum
      VSSCRIPTINSERT := VSSCRIPTINSERT || 'RECNUM';
      VSSCRIPTSELECT := VSSCRIPTSELECT || VNNOVORECNUM;
      --Valor da baixa
      VSSCRIPTINSERT := VSSCRIPTINSERT || ', VALOR, VPAGOBORDERO, VPAGO';
      VSSCRIPTSELECT := VSSCRIPTSELECT || ', ' || PNVALOR || ', ' || PNVALOR || ', ' || PNVALOR;
      --C?digo da conta
      VSSCRIPTINSERT := VSSCRIPTINSERT || ', CODCONTA';
      VSSCRIPTSELECT := VSSCRIPTSELECT || ', ' || PNCODCONTA;
      --Campos a ser zerados
      VSSCRIPTINSERT := VSSCRIPTINSERT || ', TXPERM, DESCONTOFIN, VLVARIACAOCAMBIAL, NUMSEQBORDERO, VALORDEV';
      VSSCRIPTSELECT := VSSCRIPTSELECT || ', 0     , 0          , 0                , 0            , 0';
      VSSCRIPTINSERT := VSSCRIPTINSERT || ', VLCSRF, VLDESPFIN, VLINSS, VLINSSTOMADOR, VLIRRF, VLISS';
      VSSCRIPTSELECT := VSSCRIPTSELECT || ', 0     , 0        , 0     , 0            , 0     , 0';
      VSSCRIPTINSERT := VSSCRIPTINSERT || ', VLOUTRAS, VLPIS, VLRPARIDADEMOEDA, VLRUTILIZADOADIANTFORNEC, VLSESTSENAT';
      VSSCRIPTSELECT := VSSCRIPTSELECT || ', 0       , 0    , 0               , 0                       , 0';
      --Data de lan?amento
      VSSCRIPTINSERT := VSSCRIPTINSERT || ', DTLANC';
      VSSCRIPTSELECT := VSSCRIPTSELECT || ', TRUNC(SYSDATE)';
      --Localiza??o
      VSSCRIPTINSERT := VSSCRIPTINSERT || ', LOCALIZACAO';
      VSSCRIPTSELECT := VSSCRIPTSELECT || ', TO_CHAR(NUMTRANS)';
      --Hist?rico
      VSSCRIPTINSERT := VSSCRIPTINSERT || ', HISTORICO';
      VSSCRIPTSELECT := VSSCRIPTSELECT || ', ''' || SUBSTR(PSHISTORICO, 1, 40) || ''' ';
      --C?digo da rotina de lan?amento
      VSSCRIPTINSERT := VSSCRIPTINSERT || ', CODROTINACAD';
      VSSCRIPTSELECT := VSSCRIPTSELECT || ', CODROTINABAIXA';
      --RecNumBaixa liga??o com o lan?amento principal
      VSSCRIPTINSERT := VSSCRIPTINSERT || ', RECNUMBAIXA';
      VSSCRIPTSELECT := VSSCRIPTSELECT || ', ' || TO_CHAR(PNRECNUM)     ;
      --DTCOMPETENCIA - Data de compet?ncia do fato
      VSSCRIPTINSERT := VSSCRIPTINSERT || ', DTCOMPETENCIA';
      VSSCRIPTSELECT := VSSCRIPTSELECT || ', NVL(DTCOMPETENCIA,TRUNC(SYSDATE)) DTCOMPETENCIA';
      VSSCRIPTINSERT := VSSCRIPTINSERT || ', CODSERVICOSPEDEFD ';
      VSSCRIPTSELECT := VSSCRIPTSELECT || ', CODSERVICOSPEDEFD ';
      -- DDLEGFIN-2132
      -- Se calcular variação cambial automaticamente = SIM, insere Moeda = R
      IF NVL(VPARAMVARIACAOCAMBIAL,'N') = 'S' THEN
         VSSCRIPTINSERT := VSSCRIPTINSERT || ', MOEDA ';
         VSSCRIPTSELECT := VSSCRIPTSELECT || ', ''R'' ';
      ELSE
         VSSCRIPTINSERT := VSSCRIPTINSERT || ', MOEDA ';
         VSSCRIPTSELECT := VSSCRIPTSELECT || ', MOEDA ';
      END IF;
      --Fechando os script
      VSSCRIPTINSERT := VSSCRIPTINSERT || ') ';
      VSSCRIPTSELECT := VSSCRIPTSELECT || ' FROM PCLANC WHERE RECNUM = ' || TO_CHAR(PNRECNUM);
      --Campos n?o gravados:
      --HISTORICO2, DTASSINATURA, ASSINATURA, MOEDAESTRANGEIRA, COTACAO, DTCOTACAO, VALORMOEDAESTRANGEIRA, COTACAOBAIXA, DTCOTACAOBAIXA, VLVARIACAOCAMBIAL
      VSSCRIPTINSERT := VSSCRIPTINSERT || VSSCRIPTSELECT;

      BEGIN
         EXECUTE IMMEDIATE VSSCRIPTINSERT;
      EXCEPTION
      WHEN OTHERS THEN
         RAISE_APPLICATION_ERROR(-20016,'Erro: no lan?amento adicional.'|| SQLERRM);
      END;
   END;

   PROCEDURE LANCAR_CONTRAPARTIDA(PNRECNUM    IN NUMBER
                                , PNNUMTRANS  IN NUMBER
                                , PNNUMERARIO IN NUMBER
                                , PSFORMAPAGAMENTO IN VARCHAR2
                                , PNCODFUNCIONARIO IN NUMBER)
   IS
     VNNOVORECNUM NUMBER;
   BEGIN
     VNNOVORECNUM := PKG_CONTROLE_PCLANC.NOVA_PCLANC( TO_CHAR(PNRECNUM)  -- RECNUM
                                                     , 'C' -- TIPO CONTRAPARTIDA
                                                     , TO_CHAR(PNNUMTRANS)-- NOVO NUMTRANS
                                                     , TO_CHAR(PNNUMERARIO)-- NUMERO BORDERO/CAIXA/CHEQUE
                                                     , TO_CHAR(PSFORMAPAGAMENTO)
                                                     , TO_CHAR(PNCODFUNCIONARIO));
   END;

   FUNCTION LANCAR_NOVAPCLANC(PNRECNUM    IN NUMBER
                             , PNNUMERARIO IN NUMBER
                             , PSFORMAPAGAMENTO IN VARCHAR2
                             , PNCODFUNCIONARIO IN NUMBER)
   RETURN NUMBER
   IS
   BEGIN
     RETURN PKG_CONTROLE_PCLANC.NOVA_PCLANC( TO_CHAR(PNRECNUM)     -- RECNUM
                                           , 'N'                  -- TIPO NOVA PCLANC EM ABERTO
                                           , 0                    -- NUMTRANS ZERADO PARA A NOVA PCLANC
                                           , TO_CHAR(PNNUMERARIO) -- NUMERO BORDERO/CAIXA/CHEQUE
                                           , TO_CHAR(PSFORMAPAGAMENTO)
                                           , TO_CHAR(PNCODFUNCIONARIO));
   END;

   FUNCTION NOVA_PCLANC(PNRECNUM    IN NUMBER
                       , PNTIPO      IN VARCHAR2
                       , PNNUMTRANS  IN NUMBER
                       , PNNUMERARIO IN NUMBER
                       , PSFORMAPAGAMENTO IN VARCHAR2
                       , PNCODFUNCIONARIO IN NUMBER)
   RETURN NUMBER
   IS --Declara??o das variaveis
      VNNOVORECNUM         NUMBER;
      VSSCRIPTINSERT       VARCHAR2(32767);
      VSSCRIPTSELECT       VARCHAR2(32767);
      VSIDCONTROLEEMBARQUE VARCHAR2(20);
     VVARIACAOCAMBIAL     VARCHAR2(1);

      CURSOR CURSOR_TABELA --Campos da tabela PCLANC
      IS
         SELECT COLUMN_NAME COLUNA
           FROM USER_TAB_COLUMNS
          WHERE UPPER(TABLE_NAME) = 'PCLANC'
            AND COLUMN_NAME NOT IN
                   ('RECNUM' --Colunas que ter?o um tratamento especial
                  , 'VALOR'
                  , 'VPAGO'
                  , 'VPAGOBORDERO'
                  , 'HISTORICO2'
                  , 'DTLANC'
                  , 'CODROTINACAD'
                  , 'DTPAGTO'
                  , 'NUMTRANS'
                  , 'NUMBORDERO'
                  , 'NUMCHEQUE'
                  , 'NUMCHEQUE2'
                  , 'DTBORDER'
                  , 'DTCHEQ'
                  , 'ASSINATURA'
                  , 'DTASSINATURA'
                  , 'NUMSEQBORDERO'
                  , 'DTESTORNOBAIXA'
                  , 'DTAGENDAMENTO'
                  , 'DTIMPRESSAO'
                  , 'AGENDAMENTO'
                  , 'TIPOPAGTO'
                  , 'NUMBANCO'
                  , 'CODFUNCBAIXA'
                  , 'CODROTINABAIXA'
                  , 'PORTADORCHEQUE'
                  , 'CODFUNCULTALTER'
                  , 'TXPERM'
                  , 'DESCONTOFIN'
                  , 'VALORDEV'
                  , 'VLVARIACAOCAMBIAL'
                  , 'CODFUNCESTORNOBAIXA'
              , 'COTACAOBAIXA'
                  , 'DTCOTACAOBAIXA'
                  , 'VALORMOEDAESTRANGEIRA');

      LINHA_TABELA_SELECIONADA   CURSOR_TABELA%ROWTYPE;
   BEGIN
      -- Inicializando as variaveis
      VVARIACAOCAMBIAL := PARAMFILIAL.ObterComoVarchar2('VARIACAOCAMBIAL');
      VSSCRIPTINSERT := 'INSERT INTO PCLANC (';
      VSSCRIPTSELECT := 'SELECT ';
      --Listando os campos da tabela
      OPEN CURSOR_TABELA;
      LOOP
         FETCH CURSOR_TABELA
          INTO LINHA_TABELA_SELECIONADA;

         EXIT WHEN CURSOR_TABELA%NOTFOUND;
         VSSCRIPTINSERT := VSSCRIPTINSERT || LINHA_TABELA_SELECIONADA.COLUNA || ', ';
         VSSCRIPTSELECT := VSSCRIPTSELECT || LINHA_TABELA_SELECIONADA.COLUNA || ', ';
      END LOOP;

      CLOSE CURSOR_TABELA;

      VNNOVORECNUM   := GERAR_RECNUM();
      VGRECNUMNOVO   := VNNOVORECNUM; -- Atribuindo RECNUM novo ? vari?vel global para ser usado no estorno caso necess?rio.

      --Novo Recnum
      VSSCRIPTINSERT := VSSCRIPTINSERT || 'RECNUM';
      VSSCRIPTSELECT := VSSCRIPTSELECT || VNNOVORECNUM;

      --Valor da baixa
      VSSCRIPTINSERT := VSSCRIPTINSERT || ', VALOR';

      IF PNTIPO = 'C' THEN
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', VALOR * (-1)';
      ELSE
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', VALOR';
      END IF;

      --Valor Pago
      IF PNTIPO = 'C' THEN
        VSSCRIPTINSERT := VSSCRIPTINSERT || ', VPAGO';
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', VPAGO * (-1)';
      END IF;

      --Valor Pago Border?
      IF PNTIPO = 'C' THEN
        VSSCRIPTINSERT := VSSCRIPTINSERT || ', VPAGOBORDERO';
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', VPAGOBORDERO * (-1)';
      END IF;

      --Hist?rico 2
      IF PNTIPO = 'C' THEN

        VSSCRIPTINSERT := VSSCRIPTINSERT || ', HISTORICO2';

        IF PNTIPO = 'C' THEN
          VSSCRIPTSELECT := VSSCRIPTSELECT || ', ''ESTORNO DO CONTAS A PAGAR LANCTO.: || ' || TO_CHAR(PNRECNUM) || '''' ;
        ELSE
          VSSCRIPTSELECT := VSSCRIPTSELECT || ', ''Clone do registro RecNum: || ' ||  TO_CHAR(PNRECNUM) || '''' ;
        END IF;

      ELSE
      --Replicando o Historico2 para os novos titulos de estorno
        VSSCRIPTINSERT := VSSCRIPTINSERT || ', HISTORICO2';
        VSSCRIPTSELECT := VSSCRIPTSELECT  || ', HISTORICO2';

      END IF;

      --Data do pagamento
      IF PNTIPO = 'C' THEN
        VSSCRIPTINSERT := VSSCRIPTINSERT || ', DTPAGTO';
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', TRUNC(SYSDATE)';
      END IF;

      --Data de lan?amento
      VSSCRIPTINSERT := VSSCRIPTINSERT || ', DTLANC';
      VSSCRIPTSELECT := VSSCRIPTSELECT || ', TRUNC(SYSDATE)';
      --C?digo da rotina de lan?amento
      VSSCRIPTINSERT := VSSCRIPTINSERT || ', CODROTINACAD';
      VSSCRIPTSELECT := VSSCRIPTSELECT || ', CODROTINABAIXA';

      --Numtrans
      IF PNTIPO = 'C' THEN
        VSSCRIPTINSERT := VSSCRIPTINSERT || ', NUMTRANS';
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', ' || PNNUMTRANS;
      END IF;

      --NumBordero/Numcheque/Caixa
      IF (PSFORMAPAGAMENTO <> 'X') AND (PNTIPO = 'C') THEN

        IF PSFORMAPAGAMENTO = 'B' THEN

          VSSCRIPTINSERT := VSSCRIPTINSERT || ', NUMBORDERO';
          VSSCRIPTSELECT := VSSCRIPTSELECT || ', ' || PNNUMERARIO;

        ELSIF PSFORMAPAGAMENTO = 'C' THEN

          VSSCRIPTINSERT := VSSCRIPTINSERT || ', NUMCHEQUE';
          VSSCRIPTSELECT := VSSCRIPTSELECT || ', NUMCHEQUE';

          VSSCRIPTINSERT := VSSCRIPTINSERT || ', NUMCHEQUE2';
          VSSCRIPTSELECT := VSSCRIPTSELECT || ', NUMCHEQUE2';

        END IF;

      END IF;

      -- DtCheque/DtBorder
      IF (PSFORMAPAGAMENTO <> 'X') AND (PNTIPO = 'C') THEN

        IF PSFORMAPAGAMENTO = 'C' THEN
          VSSCRIPTINSERT := VSSCRIPTINSERT || ', DTCHEQ';
          VSSCRIPTSELECT := VSSCRIPTSELECT || ', DTCHEQ';
        ELSIF PSFORMAPAGAMENTO = 'B' THEN
          VSSCRIPTINSERT := VSSCRIPTINSERT || ', DTBORDER';
          VSSCRIPTSELECT := VSSCRIPTSELECT || ', DTBORDER';
        END IF;

      END IF;

      IF PNTIPO = 'C' THEN
        /*VSSCRIPTINSERT := VSSCRIPTINSERT || ', DTESTORNOBAIXA';
          VSSCRIPTSELECT := VSSCRIPTSELECT || ', DTESTORNOBAIXA';

          S? era executado este trecho de fonte acima;
          OBS: - T?tulos de estorno de cheque e border? ficam dentro do mesmo cheque/border?
               dos lan?amentos originais.
               - O fonte acima n?o funcionava, pois no momento que a fun??o LANCAR_CONTRAPARTIDA
               ? chamada, o update que preenche o estorno (VPAGO, DTPAGTO, CODFUNCBAIXA, CODROTINABAIXA,
               HISTORICO, DTESTORNOBAIXA, CODFUNCESTORNOBAIXA) ainda n?o foi executado.
               - Por consequ?ncia, a rotina copiava o DTESTORNOBAIXA do t?tulo original (NULO)
               para o lan?amento de estorno (QUE TAMB?M FICAVA NULO);
               - O erro s? n?o era visto porque o update que preenche os campos do estorno
               (VPAGO, DTPAGTO, CODFUNCBAIXA, CODROTINABAIXA, HISTORICO, DTESTORNOBAIXA, CODFUNCESTORNOBAIXA)
               usa o NUMBORDERO/NUMCHEQUE/NUMTRANS como filtro. Como os lan?amentos de estorno ficam dentro
               do border?/cheque, o campo acabava sendo gravado neste update.
               - O update mencionado acima n?o funcionava para estornos de baixas referntes a
               caixa/banco, pois os lan?amentos de estorno de tais baixas n?o ficam no mesmo NUMTRANS
               dos lan?amentos originais. Logo, o update (que passa o NUMTRANS da baixa original) n?o
               'corrigia' o campo.
               - Foi tratado aqui para, quando for estorno de caixa/banco, j? gravar o
               DTESTORNOBAIXA e o CODFUNCESTORNOBAIXA no momento da gera??o da perna de estorno.
        */

        IF PSFORMAPAGAMENTO = 'X' THEN
          VSSCRIPTINSERT := VSSCRIPTINSERT || ', DTESTORNOBAIXA';
          VSSCRIPTSELECT := VSSCRIPTSELECT || ', TRUNC(SYSDATE)';
          VSSCRIPTINSERT := VSSCRIPTINSERT || ', CODFUNCESTORNOBAIXA';
          VSSCRIPTSELECT := VSSCRIPTSELECT || ', ' || PNCODFUNCIONARIO;
        ELSE
          VSSCRIPTINSERT := VSSCRIPTINSERT || ', DTESTORNOBAIXA';
          VSSCRIPTSELECT := VSSCRIPTSELECT || ', DTESTORNOBAIXA';
          VSSCRIPTINSERT := VSSCRIPTINSERT || ', CODFUNCESTORNOBAIXA';
          VSSCRIPTSELECT := VSSCRIPTSELECT || ', CODFUNCESTORNOBAIXA';
        END IF;

      END IF;

      -- Assinatura e Data Assinatura s?o clonadas para Lan?amento de contra partida.
      -- Para a pclanc em aberto ? NULL
      IF PNTIPO = 'C' THEN
        VSSCRIPTINSERT := VSSCRIPTINSERT || ', ASSINATURA';
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', ASSINATURA';

        VSSCRIPTINSERT := VSSCRIPTINSERT || ', DTASSINATURA';
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', DTASSINATURA';
      END IF;

      IF PNTIPO = 'C' THEN
        VSSCRIPTINSERT := VSSCRIPTINSERT || ', DTAGENDAMENTO';
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', DTAGENDAMENTO';

        VSSCRIPTINSERT := VSSCRIPTINSERT || ', AGENDAMENTO';
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', AGENDAMENTO';

        VSSCRIPTINSERT := VSSCRIPTINSERT || ', DTIMPRESSAO';
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', DTIMPRESSAO';

        VSSCRIPTINSERT := VSSCRIPTINSERT || ', TIPOPAGTO';
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', TIPOPAGTO';

        VSSCRIPTINSERT := VSSCRIPTINSERT || ', NUMBANCO';
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', NUMBANCO';

        VSSCRIPTINSERT := VSSCRIPTINSERT || ', CODFUNCBAIXA';
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', CODFUNCBAIXA';

        VSSCRIPTINSERT := VSSCRIPTINSERT || ', CODROTINABAIXA';
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', CODROTINABAIXA';

        VSSCRIPTINSERT := VSSCRIPTINSERT || ', PORTADORCHEQUE';
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', PORTADORCHEQUE';

      ELSE

        VSSCRIPTINSERT := VSSCRIPTINSERT || ', CODFUNCULTALTER';
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', ' || PNCODFUNCIONARIO;

      END IF;

      --VALOR DOS JUROS
      VSSCRIPTINSERT := VSSCRIPTINSERT || ', TXPERM';

      IF PNTIPO = 'C' THEN
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', TXPERM * (-1)';
      ELSE
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', TXPERM';
      END IF;

      --VALOR DO DESCONTO FINANCEIRO
      VSSCRIPTINSERT := VSSCRIPTINSERT || ', DESCONTOFIN';

      IF PNTIPO = 'C' THEN
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', DESCONTOFIN * (-1)';
      ELSE
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', DESCONTOFIN';
      END IF;

      --VALOR DO VALORDEV
      VSSCRIPTINSERT := VSSCRIPTINSERT || ', VALORDEV';

      IF PNTIPO = 'C' THEN
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', VALORDEV * (-1)';
      ELSE
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', VALORDEV';
      END IF;
      -- DDLEGFIN-2132 -> Se parâmetro 2431 marcado, limpar VLVARIACAOCAMBIAL, COTACAOBAIXA e DTCOTACAOBAIXA do título em aberto
      --VALOR DA VLVARIACAOCAMBIAL
      VSSCRIPTINSERT := VSSCRIPTINSERT || ', VLVARIACAOCAMBIAL';
     VSSCRIPTINSERT := VSSCRIPTINSERT || ', VALORMOEDAESTRANGEIRA';

      IF PNTIPO = 'C' THEN
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', VLVARIACAOCAMBIAL * (-1)';
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', VALORMOEDAESTRANGEIRA * (-1)';
      ELSIF NVL(VVARIACAOCAMBIAL,'N') = 'S' THEN
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', NULL';
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', VALORMOEDAESTRANGEIRA';
      ELSE
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', VLVARIACAOCAMBIAL';
      VSSCRIPTSELECT := VSSCRIPTSELECT || ', VALORMOEDAESTRANGEIRA';
      END IF;
      --VALOR DA COTACAOBAIXA e DTCOTACAOBAIXA
      VSSCRIPTINSERT := VSSCRIPTINSERT || ', COTACAOBAIXA';
      VSSCRIPTINSERT := VSSCRIPTINSERT || ', DTCOTACAOBAIXA';

      IF (PNTIPO <> 'C') AND (NVL(VVARIACAOCAMBIAL,'N') = 'S') then
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', NULL ';
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', NULL ';
      ELSE
        VSSCRIPTSELECT := VSSCRIPTSELECT || ' , COTACAOBAIXA ';
        VSSCRIPTSELECT := VSSCRIPTSELECT || ' , DTCOTACAOBAIXA ';
      END IF;
      -- FIM - DDLEGFIN-2132 -----------------------------------------------------------------------------------------------------
      --Fechando os script
      VSSCRIPTINSERT := VSSCRIPTINSERT || ') ';
      VSSCRIPTSELECT := VSSCRIPTSELECT || ' FROM PCLANC WHERE RECNUM = ' || TO_CHAR(PNRECNUM);

      EXECUTE IMMEDIATE VSSCRIPTINSERT || VSSCRIPTSELECT;

     BEGIN
       UPDATE PCPRESTACAOCONTADETALHE
         SET RECNUM = VNNOVORECNUM
       WHERE RECNUM = PNRECNUM;
     EXCEPTION
      WHEN OTHERS THEN
         NULL;
     END;

      -- Inserir Rateio Centro de Custo para a nova PCLANC
      LANCAR_CONTRAPARTIDA_CC(PNRECNUM, VNNOVORECNUM, PNTIPO);

      -- Retorna RECNUM gerado (DDFINAN-4782)
      RETURN VNNOVORECNUM;

      --Inicio - Atualizando o novo RECNUM na tabela PCDESPESAIMPCE, caso houver
      BEGIN
        SELECT PCLANC.IDCONTROLEEMBARQUE
          INTO VSIDCONTROLEEMBARQUE
          FROM PCLANC
         WHERE PCLANC.RECNUM = PNRECNUM;
      EXCEPTION
        WHEN OTHERS THEN
          VSIDCONTROLEEMBARQUE := '';
      END;

      IF (VSIDCONTROLEEMBARQUE IS NOT NULL) OR (TRIM(VSIDCONTROLEEMBARQUE) <> '') THEN
        UPDATE PCDESPESAIMPCE
           SET RECNUM = VNNOVORECNUM
         WHERE RECNUM = PNRECNUM
           AND IDCONTROLEEMBARQUE = VSIDCONTROLEEMBARQUE;
      END IF;
      --Fim - Atualizando o novo RECNUM na tabela PCDESPESAIMPCE, caso houver

    END;

    PROCEDURE LANCAR_CONTRAPARTIDA_CC( PNRECNUMORIG IN NUMBER
                                     , PNRECNUMDEST IN NUMBER
                                     , PNTIPO       IN VARCHAR2)
    IS
      VSSCRIPTINSERT VARCHAR2(32767);
      VSSCRIPTSELECT VARCHAR2(32767);
      CURSOR CURSOR_TABELA --Campos da tabela PCLANC
      IS
         SELECT COLUMN_NAME COLUNA
           FROM USER_TAB_COLUMNS
          WHERE UPPER(TABLE_NAME) = 'PCRATEIOCENTROCUSTO'
            AND COLUMN_NAME NOT IN
                   ('RECNUM' --Colunas que ter?o um tratamento especial
                  , 'CONTRAPARTIDA'
                  , 'VALOR');
      LINHA_TABELA_SELECIONADA   CURSOR_TABELA%ROWTYPE;
    BEGIN
        -- Inicializando as variaveis
        VSSCRIPTINSERT := 'INSERT INTO PCRATEIOCENTROCUSTO (';
        VSSCRIPTSELECT := 'SELECT ';
        --Listando os campos da tabela
        OPEN CURSOR_TABELA;
        LOOP
           FETCH CURSOR_TABELA
           INTO LINHA_TABELA_SELECIONADA;

           EXIT WHEN CURSOR_TABELA%NOTFOUND;
           VSSCRIPTINSERT := VSSCRIPTINSERT || LINHA_TABELA_SELECIONADA.COLUNA || ', ';
           VSSCRIPTSELECT := VSSCRIPTSELECT || LINHA_TABELA_SELECIONADA.COLUNA || ', ';
        END LOOP;

        CLOSE CURSOR_TABELA;

        --Novo Recnum
        VSSCRIPTINSERT := VSSCRIPTINSERT || 'RECNUM';
        VSSCRIPTSELECT := VSSCRIPTSELECT || PNRECNUMDEST;

        --Valor do rateio
        VSSCRIPTINSERT := VSSCRIPTINSERT || ', VALOR';
        VSSCRIPTSELECT := VSSCRIPTSELECT || ', VALOR';
        IF PNTIPO = 'C' THEN
          VSSCRIPTSELECT := VSSCRIPTSELECT || ' * (-1)';
        END IF;

        --Contra partida
        VSSCRIPTINSERT := VSSCRIPTINSERT || ', CONTRAPARTIDA';

        IF PNTIPO = 'C' THEN
          VSSCRIPTSELECT := VSSCRIPTSELECT || ', ''S'' ';
        ELSE
          VSSCRIPTSELECT := VSSCRIPTSELECT || ', ''N'' ';
        END IF;

        --Fechando os script
        VSSCRIPTINSERT := VSSCRIPTINSERT || ') ';
        VSSCRIPTSELECT := VSSCRIPTSELECT || ' FROM PCRATEIOCENTROCUSTO WHERE RECNUM = ' || TO_CHAR(PNRECNUMORIG);
        EXECUTE IMMEDIATE VSSCRIPTINSERT || VSSCRIPTSELECT;
    END;

   PROCEDURE ESTORNAR
    ( PSFORMAPAGAMENTO IN VARCHAR
    , PSHISTORICO      IN VARCHAR
    , PNNUMERARIO      IN NUMBER
    , PNNUMBANCO       IN NUMBER
    , PSMOEDA          IN VARCHAR
    , PNNUMTRANS       IN NUMBER
    , PNCODFUNCIONARIO IN NUMBER
    , PNCODROTINA      IN NUMBER
    , PSMENSAGEM       OUT VARCHAR
    )
   IS
     VSSCRIPT               VARCHAR2(500);
     VNCODCONTABIL          NUMBER;
     VNVALORPCMOVCR         NUMBER;
     VNMOEDA                VARCHAR2(4);
     VNVALORDEVOLUCAO_VERBA NUMBER;
   BEGIN
     BEGIN
       VNVALORDEVOLUCAO_VERBA := 0;

       --Gerando os lan?amentos de contrapartida dos registros baixados e os lan?amentos em aberto
       FOR REGISTROS IN (SELECT PCLANC.RECNUM,
                                PCLANC.NUMTRANS,
                                NVL(PCLANC.RECNUMBAIXA, 0) RECNUMBAIXA,
                                NVL(PCLANC.DESCONTOFIN, 0) DESCONTOFIN,
                                NVL(PCLANC.VALORDEV, 0) VALORDEV
                                 FROM PCLANC
                                WHERE PCLANC.NUMBANCO = PNNUMBANCO
                                  AND ((PSFORMAPAGAMENTO = 'B' AND PCLANC.NUMBORDERO = PNNUMERARIO)
                                   OR  (PSFORMAPAGAMENTO = 'C' AND PCLANC.NUMCHEQUE2 = PNNUMERARIO)
                                   OR  (PSFORMAPAGAMENTO = 'X' AND PCLANC.NUMTRANS   = PNNUMERARIO))
                                  AND PCLANC.DTESTORNOBAIXA IS NULL)
       LOOP

         IF (REGISTROS.DESCONTOFIN <> 0) AND (REGISTROS.VALORDEV <> 0) THEN
           VNVALORDEVOLUCAO_VERBA := VNVALORDEVOLUCAO_VERBA + VALOR_DEVOLUCAO_VERBA(REGISTROS.RECNUM, PNNUMBANCO);
         END IF;

         IF (REGISTROS.RECNUMBAIXA = 0) THEN

           VSSCRIPT := 'begin PKG_CONTROLE_PCLANC.LANCAR_NOVAPCLANC('
                         || TO_CHAR(REGISTROS.RECNUM)
                         || ', '
                         || TO_CHAR(PNNUMERARIO)
                         || ', '''
                         || TO_CHAR(PSFORMAPAGAMENTO)
                         || ''', '
                         || TO_CHAR(PNCODFUNCIONARIO)
                         || '); end;';

           EXECUTE IMMEDIATE VSSCRIPT;

           --Atualizando NUMLANC na Tabela PCMOVCRFOR
           UPDATE PCMOVCRFOR
              SET NUMLANC = VGRECNUMNOVO
            WHERE NUMLANC = REGISTROS.RECNUM;

         END IF;

         --TRATAMENTO QUE SEJA POSS?VEL ENCONTRAR A PCLANC ORIGINAL PELA FUN??O: F_BUSCARLISTASRECNUMORIGEM
         --Insere desdobramento do t?tulo original para o novo
         if VGRECNUMNOVO is not null then
           EXECUTE IMMEDIATE 'INSERT INTO PCDESDLANC(RECNUM,NUMTRANSENT,RECNUMORIG,RECNUMDESTINO) VALUES('
                             || TO_CHAR(REGISTROS.RECNUM)
                             || ', '
                             || TO_CHAR(0)
                             || ', '
                             || TO_CHAR(REGISTROS.RECNUM)
                             || ', '
                             || TO_CHAR(VGRECNUMNOVO)
                             || ')';
         end if;

         VSSCRIPT := 'begin PKG_CONTROLE_PCLANC.LANCAR_CONTRAPARTIDA('
                      || TO_CHAR(REGISTROS.RECNUM)
                      || ', '
                      || TO_CHAR(PNNUMTRANS)
                      || ', '
                      || TO_CHAR(PNNUMERARIO)
                      || ', '''
                      ||  TO_CHAR(PSFORMAPAGAMENTO)
                      || ''', '
                      || TO_CHAR(PNCODFUNCIONARIO)
                      || '); end;';
         EXECUTE IMMEDIATE VSSCRIPT;

       END LOOP;
      EXCEPTION --Caso n?o tenha alterado nenhum registro
       WHEN NO_DATA_FOUND THEN
         RAISE_APPLICATION_ERROR(-20016,'Erro: Nenhum titulo encontrado para ser estornado.'|| SQLERRM);
         PSMENSAGEM := 'Erro:' || SQLERRM;
     END;

     -- Quitação dos títulos a serem estornados
    BEGIN
    -- Valor a ser lançado na PCMOVCR
       SELECT PCBANCO.CODCONTABIL, PCMOVCR.CODCOB, SUM(VPAGO)
         INTO VNCODCONTABIL
            , VNMOEDA
            , VNVALORPCMOVCR
         FROM PCLANC
            , PCBANCO
            , PCMOVCR
        WHERE PCLANC.NUMBANCO    = PCBANCO.CODBANCO
          AND PCLANC.NUMTRANS    = PCMOVCR.NUMTRANS
          AND PCLANC.NUMBANCO    = PNNUMBANCO
          AND PCLANC.DTESTORNOBAIXA IS NULL
          --Retirar lançamentos duplicados pelo processo de estorno de conciliação da 604
          AND PCMOVCR.DTESTORNO IS NULL
          AND NVL(PCMOVCR.ESTORNO,'N') = 'N'
          AND ((PSFORMAPAGAMENTO = 'B' AND PCLANC.NUMBORDERO = PNNUMERARIO)
           OR  (PSFORMAPAGAMENTO = 'C' AND PCLANC.NUMCHEQUE2 = PNNUMERARIO)
           OR  (PSFORMAPAGAMENTO = 'X' AND PCLANC.NUMTRANS = PNNUMERARIO))
--          AND ROWNUM = 1
        GROUP BY PCBANCO.CODCONTABIL, PCMOVCR.CODCOB;
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
          RAISE_APPLICATION_ERROR(-20016,'Não foi encontrada movimentação (PCMOVCR) para o borderô ' ||  TO_CHAR(PNNUMERARIO) || '.' || CHR(10)||
                                         'Favor entrar em contato com a PC Sistemas.' || CHR(10));
       PSMENSAGEM := 'Erro:' || SQLERRM;
    END;

     BEGIN

       IF PSFORMAPAGAMENTO <> 'X' THEN
         VNMOEDA := PSMOEDA;
       END IF;

       -- GERAR_PCMOVCR
       GERAR_PCMOVCR(PSFORMAPAGAMENTO
                   , 'D'
                   , PSHISTORICO
                   , SUBSTR((CASE WHEN PSFORMAPAGAMENTO = 'B' THEN 'REF. A CANCELAMENTO DE BORDERO ' || PNNUMERARIO
                                  WHEN PSFORMAPAGAMENTO = 'C' THEN 'REF. A CANCELAMENTO DE CH.NUM. ' || PNNUMBANCO || '/' || PNNUMERARIO
                                  WHEN PSFORMAPAGAMENTO = 'X' THEN 'REF. A CANCELAMENTO DE CAIXA '  || PNNUMERARIO
                                  ELSE NULL
                                  END),1,40) -- HISTORICO2
                   , PNNUMERARIO
                   , PNNUMBANCO
                   , VNMOEDA
                   , PNNUMTRANS
                   , PNCODFUNCIONARIO
                   , PNCODROTINA
                   , VNCODCONTABIL
                   , (VNVALORPCMOVCR + VNVALORDEVOLUCAO_VERBA) * (-1)
                   , 0
                   , 0
                   , null);
       EXCEPTION --Caso n?o tenha alterado nenhum registro
         WHEN NO_DATA_FOUND THEN
          RAISE_APPLICATION_ERROR(-20016,'Erro: ao efetuar lan?amentos de contra partida.'|| SQLERRM);
          PSMENSAGEM := 'Erro:' || SQLERRM;
       END;

     BEGIN
       UPDATE PCLANC
          SET VPAGO = NVL(VALOR, 0) - NVL(VALORDEV, 0)
            , DTPAGTO = DECODE(DTPAGTO, NULL, TRUNC(SYSDATE), DTPAGTO)
            , CODFUNCBAIXA = DECODE(CODFUNCBAIXA, NULL, PNCODFUNCIONARIO, CODFUNCBAIXA)
            , CODROTINABAIXA = DECODE(CODROTINABAIXA, NULL, PNCODROTINA, CODROTINABAIXA)
            , HISTORICO = PSHISTORICO
            , DTESTORNOBAIXA = TRUNC(SYSDATE)
            , CODFUNCESTORNOBAIXA = PNCODFUNCIONARIO
        WHERE PCLANC.NUMBANCO = PNNUMBANCO
          AND PCLANC.DTESTORNOBAIXA IS NULL
          AND ((PSFORMAPAGAMENTO = 'B' AND PCLANC.NUMBORDERO = PNNUMERARIO)
           OR  (PSFORMAPAGAMENTO = 'C' AND PCLANC.NUMCHEQUE2 = PNNUMERARIO)
           OR  (PSFORMAPAGAMENTO = 'X' AND PCLANC.NUMTRANS   = PNNUMERARIO));
     EXCEPTION --Caso n?o tenha alterado nenhum registro
       WHEN NO_DATA_FOUND THEN
         RAISE_APPLICATION_ERROR(-20016,'Erro: Nenhum titulo encontrado para ser estornado.'|| SQLERRM);
         PSMENSAGEM := 'Erro:' || SQLERRM;
     END;

     PSMENSAGEM := 'Estorno realizado com sucesso!';
   END;

   PROCEDURE ESTORNAR_ITEM_BORDERO
   (  PSFORMAPAGAMENTO IN VARCHAR
    , PSHISTORICO      IN VARCHAR
    , PNNUMERARIO      IN NUMBER
    , PNNUMBANCO       IN NUMBER
    , PSMOEDA          IN VARCHAR
    , PNNUMTRANS       IN NUMBER
    , PNCODFUNCIONARIO IN NUMBER
    , PNCODROTINA      IN NUMBER
    , PNRECNUM         IN NUMBER
    , PSMENSAGEM       OUT VARCHAR
    )
   IS
     VSSCRIPT       VARCHAR2(500);
     VNUMTRANS      NUMBER;
     VNUMBORDERO    NUMBER;
     VNCODCONTABIL  NUMBER;
     VNVALORPCMOVCR NUMBER;
     VSMOEDA        VARCHAR(4);
     VNNEWRECNUM    NUMBER;
   BEGIN
     -- Quita??o do titulo a ser estornado
     BEGIN

       --VALIDACAO DO ESTORNO DE ADIANTAMENTO DA ROTINA 782. ONDE NAO PODE GERAR O  LANCAMENTO DO ESTORNO EM ABERTO
       IF NOT (PNCODROTINA = 782) THEN
         --Gerando o lan?amento em aberto
         VNNEWRECNUM := PKG_CONTROLE_PCLANC.LANCAR_NOVAPCLANC(TO_CHAR(PNRECNUM)
                                                             ,TO_CHAR(PNNUMERARIO)
                                                             ,TO_CHAR(PSFORMAPAGAMENTO)
                                                             ,TO_CHAR(PNCODFUNCIONARIO));
       END IF;
       --Atualizando NUMLANC na Tabela PCMOVCRFOR
       UPDATE PCMOVCRFOR
         SET NUMLANC = VGRECNUMNOVO
       WHERE NUMLANC = PNRECNUM;

       --Insere desdobramento do t?tulo original para o novo
       if VGRECNUMNOVO is not null then
           EXECUTE IMMEDIATE 'INSERT INTO PCDESDLANC(RECNUM,NUMTRANSENT,RECNUMORIG,RECNUMDESTINO) VALUES('
                             || TO_CHAR(PNRECNUM)
                             || ', '
                             || TO_CHAR(0)
                             || ', '
                             || TO_CHAR(PNRECNUM)
                             || ', '
                             || TO_CHAR(VGRECNUMNOVO)
                             || ')';
         end if;

     EXCEPTION --Caso n?o tenha alterado nenhum registro
       WHEN NO_DATA_FOUND THEN
         RAISE_APPLICATION_ERROR(-20016,'Erro: N?o foi poss?vel gerar o novo lan?amento em aberto.'|| SQLERRM);
         PSMENSAGEM := 'Erro:' || SQLERRM;
     END;

     BEGIN
       UPDATE PCLANC
          SET VPAGO = NVL(VALOR, 0) - NVL(VALORDEV, 0)
            , DTPAGTO = DECODE(DTPAGTO, NULL, TRUNC(SYSDATE), DTPAGTO)
            , CODFUNCBAIXA = DECODE(CODFUNCBAIXA, NULL, PNCODFUNCIONARIO, CODFUNCBAIXA)
            , CODROTINABAIXA = DECODE(CODROTINABAIXA, NULL, PNCODROTINA, CODROTINABAIXA)
            , HISTORICO = PSHISTORICO
            , DTESTORNOBAIXA = TRUNC(SYSDATE)
            , CODFUNCESTORNOBAIXA = PNCODFUNCIONARIO
        WHERE PCLANC.NUMBANCO = PNNUMBANCO
          AND PCLANC.RECNUM = PNRECNUM
           OR PCLANC.RECNUMBAIXA = PNRECNUM
          AND PCLANC.DTESTORNOBAIXA IS NULL;
     EXCEPTION --Caso n?o tenha alterado nenhum registro
       WHEN NO_DATA_FOUND THEN
         RAISE_APPLICATION_ERROR(-20016,'Erro: Nenhum titulo encontrado para ser estornado.'|| SQLERRM);
         PSMENSAGEM := 'Erro:' || SQLERRM;
     END;

     BEGIN
       --Gerando os lan?amentos de contrapartida dos registros baixados
         FOR REGISTROS IN (SELECT PCLANC.RECNUM, PCLANC.NUMTRANS, NVL(PCLANC.RECNUMBAIXA, 0) RECNUMBAIXA, DTESTORNOBAIXA
                                   FROM PCLANC
                                  WHERE PCLANC.NUMBANCO = PNNUMBANCO
                                    AND PCLANC.RECNUM = PNRECNUM
                                     OR PCLANC.RECNUMBAIXA = PNRECNUM)
         LOOP
           IF REGISTROS.DTESTORNOBAIXA IS NOT NULL THEN
             VSSCRIPT := 'begin PKG_CONTROLE_PCLANC.LANCAR_CONTRAPARTIDA('
                       || TO_CHAR(REGISTROS.RECNUM)
                       || ', '
                       || TO_CHAR(PNNUMTRANS)
                       || ', '
                       || TO_CHAR(PNNUMERARIO)
                       || ','''
                       || TO_CHAR(PSFORMAPAGAMENTO)
                       || ''', '
                       || TO_CHAR(PNCODFUNCIONARIO)
                       || '); end;';

             EXECUTE IMMEDIATE VSSCRIPT;
           END IF;
         END LOOP;
     EXCEPTION --Caso n?o tenha alterado nenhum registro
       WHEN NO_DATA_FOUND THEN
         RAISE_APPLICATION_ERROR(-20016,'Erro: N?o foi poss?vel gerar as contra partidas.'|| SQLERRM);
         PSMENSAGEM := 'Erro:' || SQLERRM;
     END;

     BEGIN
       -- Valor a ser lan?ado na PCMOVCR
       SELECT PCMOVCR.NUMTRANS
            , PCBANCO.CODCONTABIL
            , PCLANC.NUMBORDERO
            , PCMOVCR.CODCOB
            , SUM(NVL(PCLANC.VALOR, 0)
                - NVL(PCLANC.VALORDEV, 0)
                + NVL(PCLANC.TXPERM, 0)
                - NVL(PCLANC.DESCONTOFIN, 0)
                + NVL(PCLANC.VLVARIACAOCAMBIAL,0))
         INTO VNUMTRANS
            , VNCODCONTABIL
            , VNUMBORDERO
            , VSMOEDA
            , VNVALORPCMOVCR
         FROM PCLANC, PCMOVCR, PCBANCO
        WHERE PCLANC.NUMTRANS = PCMOVCR.NUMTRANS
          AND PCLANC.NUMBANCO = PCBANCO.CODBANCO
          AND PCLANC.RECNUM   = PNRECNUM
          --Retirar lan?amentos duplicados pelo processo de estorno de concilia??o da 604
          AND PCMOVCR.DTESTORNO IS NULL
          AND NVL(PCMOVCR.ESTORNO, 'N') = 'N'
        GROUP BY PCMOVCR.NUMTRANS
               , PCBANCO.CODCONTABIL
               , PCLANC.NUMBORDERO
               , PCMOVCR.CODCOB;

       IF PSFORMAPAGAMENTO <> 'X' THEN
         VSMOEDA := PSMOEDA;
       END IF;

       -- GERAR_PCMOVCR
       GERAR_PCMOVCR(PSFORMAPAGAMENTO
                   , 'D'
                   , PSHISTORICO
                   , SUBSTR(('REF. A CANCELAMENTO DE BORDERO ' || PNNUMERARIO), 1, 40) -- HISTORICO2
                   , PNNUMERARIO
                   , PNNUMBANCO
                   , VSMOEDA
                   , PNNUMTRANS
                   , PNCODFUNCIONARIO
                   , PNCODROTINA
                   , VNCODCONTABIL
                   , VNVALORPCMOVCR * (-1)
                   , 0
                   , 0
                   , null);
     EXCEPTION --Caso n?o tenha alterado nenhum registro
       WHEN NO_DATA_FOUND THEN
         RAISE_APPLICATION_ERROR(-20016,'Erro: N?o foi poss?vel gerar a movimenta??o de numer?rios.'|| SQLERRM);
         PSMENSAGEM := 'Erro:' || SQLERRM;
     END;

     PSMENSAGEM := 'Estorno realizado com sucesso!';
   END;

   PROCEDURE GERAR_PCMOVCR
   (  PSFORMAPAGAMENTO IN VARCHAR
    , PSNATUREZA       IN VARCHAR
    , PSHISTORICO      IN VARCHAR
    , PSHISTORICO2     IN VARCHAR
    , PNNUMERARIO      IN NUMBER
    , PNNUMBANCO       IN NUMBER
    , PSMOEDA          IN VARCHAR
    , PNNUMTRANS       IN NUMBER
    , PNCODFUNCIONARIO IN NUMBER
    , PNCODROTINA      IN NUMBER
    , PNCODCONTABIL    IN NUMBER
    , PNVALORPCMOVCR   IN NUMBER
    , PNNUMNOTA        IN NUMBER
    , PNNUMCARR        IN NUMBER
    , PDDTCOMPENSACAO    IN DATE
    )
   IS
     VNSALDOBANCO NUMBER;
     VNVALORPCMOVCR_POSITIVO NUMBER;
   BEGIN
     --Saldo do caixa
     VNSALDOBANCO := PKG_CONTROLE_PCLANC.OBTER_SALDO_PCESTCR( PNNUMBANCO
                                                            , PSMOEDA
                                                            , PNVALORPCMOVCR);

     IF PNVALORPCMOVCR < 0 THEN
       VNVALORPCMOVCR_POSITIVO := PNVALORPCMOVCR * (-1);
     ELSE
       VNVALORPCMOVCR_POSITIVO := PNVALORPCMOVCR;
     END IF;

     --Movimenta??o do caixa
     INSERT INTO PCMOVCR( CODBANCO
                        , CODCOB
                        , NUMCARR
                        , NUMCARREG
                        , HISTORICO
                        , TIPO
                        , VALOR
                        , NUMTRANS
                        , CODFUNC
                        , DATA
                        , VLSALDO
                        , CODROTINALANC
                        , OPERACAO
                        , NUMCHEQUE
                        , HORA
                        , MINUTO
                        , INDICE
                        , HISTORICO2
                        , CODCONTACRED
                        , DTCOMPENSACAO
                        )
                 VALUES ( PNNUMBANCO  --CODBANCO
                        , PSMOEDA     --CODCOB
                        , CASE WHEN PSFORMAPAGAMENTO = 'X'
                                 THEN DECODE(PNNUMNOTA, 0, NULL, PNNUMNOTA)
                                 ELSE TO_CHAR(PNNUMERARIO)
                            END  --NUMCARR
                          , CASE WHEN PSFORMAPAGAMENTO = 'X'
                                 THEN DECODE(PNNUMCARR, 0, NULL, PNNUMCARR)
                                 ELSE NULL
                            END --NUMCARREG
                        , PSHISTORICO
                        , PSNATUREZA --TIPO
                        , NVL(VNVALORPCMOVCR_POSITIVO,0) --VALOR
                        , PNNUMTRANS --NUMTRANS
                        , PNCODFUNCIONARIO --CODFUNC
                        , TRUNC(SYSDATE) --DATA
                        , VNSALDOBANCO --VLSALDO
                        , PNCODROTINA --CODROTINALANC
                        , CASE WHEN PSFORMAPAGAMENTO = 'X'
                               THEN '1'
                               ELSE NULL
                          END --OPERACAO
                        , CASE WHEN PSFORMAPAGAMENTO = 'C'
                               THEN PNNUMBANCO || '/' || PNNUMERARIO
                               ELSE NULL
                          END --NUMCHEQUE
                        , TO_CHAR(SYSDATE, 'HH24') --HORA
                        , TO_CHAR(SYSDATE, 'MI') --MINUTO
                        , 'A' --INDICE
                        , SUBSTR(PSHISTORICO2, 1, 40) --HISTORICO2
                        , PNCODCONTABIL --CODCONTACRED
                        , PDDTCOMPENSACAO
                        );
   END;

   FUNCTION VALOR_DEVOLUCAO_VERBA(PNRECNUM IN NUMBER,
                                  PNNUMBANCO IN NUMBER) RETURN NUMBER IS
     VN_VLDEVOLUCAO       NUMBER;
     VNDESCONTO_DEVOLUCAO NUMBER;
   BEGIN
     VNDESCONTO_DEVOLUCAO := 0;

     SELECT NVL(PCLANC.VALORDEV, 0) VLDEVOLUCAO
       INTO VN_VLDEVOLUCAO
       FROM PCLANC
      WHERE RECNUM = PNRECNUM;

     IF VN_VLDEVOLUCAO > 0 THEN
     BEGIN
         SELECT SUM(PCMOVCRFOR.VALOR) VALORDEV
           INTO VNDESCONTO_DEVOLUCAO
           FROM PCVERBA, PCMOVCRFOR
          WHERE PCVERBA.NUMVERBA = PCMOVCRFOR.NUMVERBA
            AND PCMOVCRFOR.NUMLANC = PNRECNUM
            AND PCVERBA.ORIGEM = 'D'
            AND PCMOVCRFOR.DTESTORNO IS NULL
       GROUP BY PCVERBA.CODCONTA;

          IF NVL(VNDESCONTO_DEVOLUCAO, 0) = 0 THEN
             VNDESCONTO_DEVOLUCAO := 0;
          END IF;
       EXCEPTION
         --Caso n?o tenha alterado nenhum registro
         WHEN OTHERS THEN
           VNDESCONTO_DEVOLUCAO := 0;
       END;
     ELSE
       VNDESCONTO_DEVOLUCAO := 0;
     END IF;

     RETURN VNDESCONTO_DEVOLUCAO;
   END;

   PROCEDURE ESTRONAR_DESCONTO_DEVOLUCAO
    ( PSFORMAPAGAMENTO IN VARCHAR
    , PSHISTORICO      IN VARCHAR
    , PNNUMERARIO      IN NUMBER
    , PNNUMBANCO       IN NUMBER
    , PSMOEDA          IN VARCHAR
    , PNNUMTRANS       IN NUMBER
    , PNCODFUNCIONARIO IN NUMBER
    , PNCODROTINA      IN NUMBER
    , PNRECNUM         IN NUMBER
    , PSMENSAGEM       OUT VARCHAR
    )
   IS
     VSSCRIPT               VARCHAR2(500);
     VNCODCONTABIL          NUMBER;
     VNVALORPCMOVCR         NUMBER;
     VNMOEDA                VARCHAR2(4);
   BEGIN
     BEGIN
       --Gerando os lançamentos de contrapartida dos registros baixados e os lançamentos em aberto
       FOR REGISTROS IN (
                        SELECT PCLANC.RECNUM,
                             PCLANC.NUMTRANS,
                             NVL(PCLANC.VALOR, 0)                   VALORBAIXA,
                             NVL(PCLANC.RECNUMBAIXA, 0)   RECNUMBAIXA,
                             NVL(PCLANC.DESCONTOFIN, 0)   DESCONTOFIN,
                                NVL(PCLANC.VALORDEV, 0)      VALORDEV
                                 FROM PCLANC
                                WHERE PCLANC.NUMBANCO = PNNUMBANCO
                                  AND ((PSFORMAPAGAMENTO = 'B' AND PCLANC.NUMBORDERO = PNNUMERARIO)
                                   OR  (PSFORMAPAGAMENTO = 'C' AND PCLANC.NUMCHEQUE2 = PNNUMERARIO)
                                   OR  (PSFORMAPAGAMENTO = 'X' AND PCLANC.NUMTRANS   = PNNUMERARIO))
                                  AND PCLANC.DTESTORNOBAIXA IS NULL
                  )
    LOOP
        IF (REGISTROS.DESCONTOFIN = REGISTROS.VALORBAIXA) OR
         (REGISTROS.VALORDEV    = REGISTROS.VALORBAIXA) OR
         ((REGISTROS.DESCONTOFIN + REGISTROS.VALORDEV) = REGISTROS.VALORBAIXA)THEN

         VSSCRIPT := 'begin PKG_CONTROLE_PCLANC.LANCAR_NOVAPCLANC( '|| TO_CHAR(REGISTROS.RECNUM)
                                                      || ', '
                                                      || TO_CHAR(PNNUMERARIO)
                                                      || ', '''
                                                      || TO_CHAR(PSFORMAPAGAMENTO)
                                                      || ''', '
                                                      || TO_CHAR(PNCODFUNCIONARIO)
                                                      || '); end;';

         EXECUTE IMMEDIATE VSSCRIPT;

         --TRATAMENTO QUE SEJA POSSÍVEL ENCONTRAR A PCLANC ORIGINAL PELA FUNÇÃO: F_BUSCARLISTASRECNUMORIGEM
         --Insere desdobramento do título original para o novo
         if VGRECNUMNOVO is not null then
            BEGIN
               EXECUTE IMMEDIATE 'INSERT INTO PCDESDLANC(RECNUM,NUMTRANSENT,RECNUMORIG,RECNUMDESTINO) VALUES('
                            || TO_CHAR(REGISTROS.RECNUM)
                            || ', '
                            || TO_CHAR(0)
                            || ', '
                            || TO_CHAR(REGISTROS.RECNUM)
                            || ', '
                            || TO_CHAR(VGRECNUMNOVO)
                            || ')';

               /*Atualizando NUMLANC na Tabela PCMOVCRFOR*/
               UPDATE PCMOVCRFOR
                  SET NUMLANC = VGRECNUMNOVO
                WHERE NUMLANC = REGISTROS.RECNUM;
            END;
         end if;

          BEGIN
            UPDATE PCLANC
                 SET VPAGO = NVL(VALOR, 0) - NVL(VALORDEV, 0)
                   , DTPAGTO = DECODE(DTPAGTO, NULL, TRUNC(SYSDATE), DTPAGTO)
                   , CODFUNCBAIXA = DECODE(CODFUNCBAIXA, NULL, PNCODFUNCIONARIO, CODFUNCBAIXA)
                   , CODROTINABAIXA = DECODE(CODROTINABAIXA, NULL, PNCODROTINA, CODROTINABAIXA)
                   , HISTORICO = PSHISTORICO
                   , DTESTORNOBAIXA = TRUNC(SYSDATE)
                   , CODFUNCESTORNOBAIXA = PNCODFUNCIONARIO
             WHERE PCLANC.NUMBANCO = PNNUMBANCO
                 AND PCLANC.DTESTORNOBAIXA IS NULL
               AND ((PSFORMAPAGAMENTO = 'B' AND PCLANC.NUMBORDERO = PNNUMERARIO)
                OR  (PSFORMAPAGAMENTO = 'C' AND PCLANC.NUMCHEQUE2 = PNNUMERARIO)
                OR  (PSFORMAPAGAMENTO = 'X' AND PCLANC.NUMTRANS   = PNNUMERARIO));

         EXCEPTION --Caso n?o tenha alterado nenhum registro
            WHEN NO_DATA_FOUND THEN
               RAISE_APPLICATION_ERROR(-20016,'Erro: Nenhum titulo encontrado para ser estornado.'|| SQLERRM);
               PSMENSAGEM := 'Erro:' || SQLERRM;
            END;
        ELSE
         BEGIN
            IF (REGISTROS.VALORBAIXA < 0) THEN
               BEGIN
                  VSSCRIPT := 'begin PKG_CONTROLE_PCLANC.LANCAR_CONTRAPARTIDA('
                                          || TO_CHAR(REGISTROS.RECNUM)
                                          || ', '
                                          || TO_CHAR(PNNUMTRANS)
                                          || ', '
                                          || TO_CHAR(PNNUMERARIO)
                                          || ', '''
                                          ||  TO_CHAR(PSFORMAPAGAMENTO)
                                          || ''', '
                                          || TO_CHAR(PNCODFUNCIONARIO)
                                          || '); end;';
                  EXECUTE IMMEDIATE VSSCRIPT;
               END;
            END IF;
         END;
      END IF;
    END LOOP;
      EXCEPTION --Caso não tenha alterado nenhum registro
         WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20016,'Erro: Nenhum titulo encontrado para ser estornado.'|| SQLERRM);
            PSMENSAGEM := 'Erro:' || SQLERRM;
         END;

       PSMENSAGEM := 'Estorno realizado com sucesso!';
    END;

     PROCEDURE ESTRONAR_ITEM_DESC_DEV(PSFORMAPAGAMENTO IN VARCHAR,
                                   PSHISTORICO      IN VARCHAR,
                                   PNNUMERARIO      IN NUMBER,
                                   PNNUMBANCO       IN NUMBER,
                                   PSMOEDA          IN VARCHAR,
                                   PNNUMTRANS       IN NUMBER,
                                   PNCODFUNCIONARIO IN NUMBER,
                                   PNCODROTINA      IN NUMBER,
                                   PNRECNUM         IN NUMBER,
                                   PSMENSAGEM       OUT VARCHAR) IS
    VSSCRIPT       VARCHAR2(500);
    VNUMTRANS      NUMBER;
    VNUMBORDERO    NUMBER;
    VNCODCONTABIL  NUMBER;
    VNVALORPCMOVCR NUMBER;
    VSMOEDA        VARCHAR(4);
  BEGIN
    VSSCRIPT := 'begin PKG_CONTROLE_PCLANC.LANCAR_NOVAPCLANC( ' ||
                TO_CHAR(PNRECNUM) || ', ' || TO_CHAR(PNNUMERARIO) || ', ''' ||
                TO_CHAR(PSFORMAPAGAMENTO) || ''', ' ||
                TO_CHAR(PNCODFUNCIONARIO) || '); end;';

    EXECUTE IMMEDIATE VSSCRIPT;

    --TRATAMENTO QUE SEJA POSSÍVEL ENCONTRAR A PCLANC ORIGINAL PELA FUNÇÃO: F_BUSCARLISTASRECNUMORIGEM
    --Insere desdobramento do título original para o novo
    if VGRECNUMNOVO is not null then
      BEGIN
        EXECUTE IMMEDIATE 'INSERT INTO PCDESDLANC(RECNUM,NUMTRANSENT,RECNUMORIG,RECNUMDESTINO) VALUES(' ||
                          TO_CHAR(PNRECNUM) || ', ' || TO_CHAR(0) || ', ' ||
                          TO_CHAR(PNRECNUM) || ', ' ||
                          TO_CHAR(VGRECNUMNOVO) || ')';

        /*Atualizando NUMLANC na Tabela PCMOVCRFOR*/
        UPDATE PCMOVCRFOR
           SET NUMLANC = VGRECNUMNOVO
         WHERE NUMLANC = PNRECNUM;
      END;
    end if;

    BEGIN
      UPDATE PCLANC
         SET VPAGO               = NVL(VALOR, 0) - NVL(VALORDEV, 0),
             DTPAGTO             = DECODE(DTPAGTO,
                                          NULL,
                                          TRUNC(SYSDATE),
                                          DTPAGTO),
             CODFUNCBAIXA        = DECODE(CODFUNCBAIXA,
                                          NULL,
                                          PNCODFUNCIONARIO,
                                          CODFUNCBAIXA),
             CODROTINABAIXA      = DECODE(CODROTINABAIXA,
                                          NULL,
                                          PNCODROTINA,
                                          CODROTINABAIXA),
             HISTORICO           = PSHISTORICO,
             DTESTORNOBAIXA      = TRUNC(SYSDATE),
             CODFUNCESTORNOBAIXA = PNCODFUNCIONARIO
       WHERE PCLANC.NUMBANCO = PNNUMBANCO
         AND PCLANC.DTESTORNOBAIXA IS NULL
         AND PCLANC.RECNUM = PNRECNUM;
    END;
  END;
END;