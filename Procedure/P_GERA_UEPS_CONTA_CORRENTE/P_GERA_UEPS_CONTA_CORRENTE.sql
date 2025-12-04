CREATE OR REPLACE PROCEDURE P_GERA_UEPS_CONTA_CORRENTE(PCODFILIAL IN VARCHAR2,
                                                       PDTINICIAL IN DATE,
                                                       PDTFINAL   IN DATE,
                                                       PCODPROD   IN NUMBER,
                                                       PQTMESES_ENT IN NUMBER,
                                                       PCONSIDERAENTINVENTARIO  IN VARCHAR2 DEFAULT 'S',
                                                       MSG        OUT VARCHAR2) IS
   ------------------------------------------------------------------------
   -- Programa criado para manter um conta corrente das saidas com relação
   -- às entradas - UEPS
   ------------------------------------------------------------------------
   ------------------------------------------------------------------------
   V_CONTADOR       NUMBER;
   V_SALDO_ENT      NUMBER;
   V_SALDO_SAI      NUMBER;
   V_SALDO_SAI_TEMP NUMBER;
   V_SALDO_SAI_TELA NUMBER;
   V_NUMTRANSVENDA  NUMBER;
   V_SALDO_ENTR_MAIOR_SAID VARCHAR2(1);
   -- Deleção de movimentação do produto, período e filial
   PROCEDURE DELETAR_DADOS IS
   BEGIN
   ------------------------------------------------------------------------
      -- Apaga os registros de entrada do período informado em diante
      DELETE FROM PCUEPSSALDOSAID
      WHERE DTSAIDA BETWEEN PDTINICIAL AND PDTFINAL
        AND (NVL(PCODPROD,0) = 0 OR CODPROD = NVL(PCODPROD,0))
        AND CODFILIAL = PCODFILIAL;
   ------------------------------------------------------------------------
      -- Apaga os registros de saída do período informado em diante
      DELETE FROM PCUEPSSALDOENT
      WHERE DATA BETWEEN ADD_MONTHS(PDTINICIAL,-PQTMESES_ENT) AND PDTFINAL
        AND (NVL(PCODPROD,0) = 0 OR CODPROD = NVL(PCODPROD,0))
        AND CODFILIAL = PCODFILIAL;
   END;
   ------------------------------------------------------------------------
   -- Insere registro de controle de saída
   PROCEDURE INSERIR_SAIDAS(P_NUMTRANSVENDA IN NUMBER,
                            P_NUMTRANSENT   IN NUMBER,
                            P_CODPROD       IN NUMBER,
                            P_DTENT         IN DATE,
                            P_DTSAIDA       IN DATE,
                            P_QTDE          IN NUMBER) IS
   BEGIN
      INSERT INTO PCUEPSSALDOSAID
         (CODFILIAL,
          NUMTRANSVENDA,
          NUMTRANSENT,
          CODPROD,
          DTENT,
          DTSAIDA,
          QTCONT)
      VALUES
         (PCODFILIAL,
          P_NUMTRANSVENDA,
          P_NUMTRANSENT,
          P_CODPROD,
          P_DTENT,
          P_DTSAIDA,
          P_QTDE);
   END;
   ------------------------------------------------------------------------
   -- Insere registro de controle de entradas
   PROCEDURE INSERIR_TABELA_ENT(P_DATA          IN DATE,
                                P_NUMTRANSENT   IN NUMBER,
                                P_CODPROD       IN NUMBER,
                                P_QTCONT        IN NUMBER,
                                P_SALDO         IN NUMBER,
                                P_NUMSEQ        IN NUMBER) IS
   BEGIN
      INSERT INTO PCUEPSSALDOENT
         (CODFILIAL,
          NUMTRANSENT,
          CODPROD,
          DATA,
          QTCONT,
          SALDO,
          NUMSEQENTULTENT)
      VALUES
         (PCODFILIAL,
          P_NUMTRANSENT,
          P_CODPROD,
          P_DATA,
          P_QTCONT,
          P_SALDO,
          P_NUMSEQ);
   END;
   ------------------------------------------------------------------------
   -- Atualiza saldo de controle de entrada
   PROCEDURE ATUALIZAR_ENTRADA(P_NUMTRANSENT IN NUMBER,
                               P_CODPROD     IN NUMBER,
                               P_SALDO       IN NUMBER) AS
   BEGIN
      UPDATE PCUEPSSALDOENT SET SALDO = NVL(P_SALDO, QTCONT)
      WHERE NUMTRANSENT = P_NUMTRANSENT
        AND CODPROD = P_CODPROD;
   END;
   ------------------------------------------------------------------------
   -- Insere ou atualiza os saldos da tabela de entrada
   PROCEDURE INSERIR_ENTRADAS(P_DATA          IN DATE,
                              P_NUMTRANSENT   IN NUMBER,
                              P_CODPROD       IN NUMBER,
                              P_QTCONT        IN NUMBER,
                              P_SALDO         IN NUMBER,
                              P_NUMSEQ        IN NUMBER) IS
   BEGIN
   ------------------------------------------------------------------------
      SELECT COUNT(*)
      INTO V_CONTADOR
      FROM PCUEPSSALDOENT
      WHERE NUMTRANSENT = P_NUMTRANSENT
        AND CODPROD = P_CODPROD
        AND DATA = P_DATA;
   ------------------------------------------------------------------------
      IF NVL(V_CONTADOR,0) > 0 THEN
         ATUALIZAR_ENTRADA(P_NUMTRANSENT, 
                           P_CODPROD, 
                           NVL(P_SALDO, P_QTCONT)
                          );
      ELSE
         INSERIR_TABELA_ENT(P_DATA,
                            P_NUMTRANSENT,
                            P_CODPROD,
                            P_QTCONT,
                            P_SALDO,
                            P_NUMSEQ
                           );
      END IF;
   ------------------------------------------------------------------------
   END;
   ------------------------------------------------------------------------
   -- Insere registro de controle de saída
   PROCEDURE ENTRADAS(P_NUMTRANSVENDA IN NUMBER,
                      P_DTSAIDA       IN DATE,
                      P_QTSAIDA       IN NUMBER,
                      P_CODPROD       IN NUMBER) IS
   BEGIN
   ------------------------------------------------------------------------
      V_NUMTRANSVENDA  := P_NUMTRANSVENDA;
      V_SALDO_SAI      := 0;
      V_SALDO_SAI_TEMP := P_QTSAIDA;
      V_SALDO_ENT      := 0;
      V_SALDO_ENTR_MAIOR_SAID := 'S';
      V_SALDO_SAI_TELA := P_QTSAIDA;
   ------------------------------------------------------------------------
      FOR ENTRADAS IN (SELECT 'NF' TIPO,
                              NVL(E.CODFILIALNF,E.CODFILIAL) CODFILIAL,
                              E.NUMTRANSENT,
                              M.CODPROD,
                              E.DTENT DATA,
                              SUM(M.QTCONT) QTCONT,
                              MAX(NVL(CP.NUMSEQENT, 1)) NUMSEQENTULTENT
                       FROM PCNFENT E,
                            PCMOV M,
                            PCMOVCOMPLE CP
                       WHERE E.NUMTRANSENT = M.NUMTRANSENT
                         AND E.NUMNOTA = M.NUMNOTA
                         AND M.NUMTRANSITEM = CP.NUMTRANSITEM(+)
                         AND NVL(E.CODFILIALNF,E.CODFILIAL) = PCODFILIAL
                         AND E.DTENT BETWEEN ADD_MONTHS(PDTINICIAL,-PQTMESES_ENT) AND PDTFINAL
                         AND M.CODPROD = P_CODPROD
                         AND M.DTMOV >= (SELECT MIN(DTMOV) FROM PCMOV)
                         AND E.ESPECIE = 'NF'
                         AND M.QTCONT > 0
                         AND M.STATUS IN ('A','AB')
                         AND E.TIPODESCARGA NOT IN ('F','P')
                         AND NVL(E.NFENTREGAFUTURA,'N') = 'N'
                         AND M.CODOPER IN ('E','EB','ET','ER',DECODE(PCONSIDERAENTINVENTARIO,'S', 'EI') )
                         AND M.DTCANCEL IS NULL
                         AND E.DTENT <= P_DTSAIDA
                         -- Necessário para que não traga as notas na movimentação, pois iria dobrar a quantidade da entrada
                         AND NOT EXISTS (SELECT CODPROD
                                         FROM PCUEPSSALDOENT
                                         WHERE NUMTRANSENT = E.NUMTRANSENT
                                           AND CODFILIAL = NVL(E.CODFILIALNF,E.CODFILIAL)
                                           AND CODPROD = M.CODPROD)
                       GROUP BY M.CODPROD, E.DTENT, NVL(E.CODFILIALNF, E.CODFILIAL), E.NUMTRANSENT
                       -------------------------------------------------------
                       UNION ALL
                       -------------------------------------------------------
                       SELECT 'SALDO' TIPO,
                              UE.CODFILIAL,
                              UE.NUMTRANSENT,
                              UE.CODPROD,
                              UE.DATA,
                              NVL(UE.SALDO,0) QTCONT,
                              UE.NUMSEQENTULTENT
                       FROM PCUEPSSALDOENT UE
                       WHERE UE.DATA BETWEEN ADD_MONTHS(PDTINICIAL,-PQTMESES_ENT) AND PDTFINAL
                         AND UE.CODFILIAL = PCODFILIAL
                         AND UE.CODPROD = P_CODPROD
                         AND UE.DATA <= P_DTSAIDA
                         AND UE.SALDO > 0
                       -------------------------------------------------------
                       ORDER BY DATA DESC, NUMTRANSENT DESC)
      LOOP
   ------------------------------------------------------------------------
   ------------------------------------------------------------------------
         --Criado para atualização do Saldo, apenas para quantidade de produto da nota 
         --de entrada que comporta a quantidade do produto da nota de saída.
         --Exemplo: Quantidade de produto da entrada 30 e quantidade de produto
         --         de saída 20 ou que varie de 1 a 30.
         IF (ENTRADAS.QTCONT >= V_SALDO_SAI_TELA AND V_SALDO_ENTR_MAIOR_SAID = 'S') THEN
            -- Para gerar apenas uma vez quando a quantidade de sáida for suficiente.
            V_SALDO_SAI := 0;
   ------------------------------------------------------------------------
            INSERIR_SAIDAS(P_NUMTRANSVENDA,
                           ENTRADAS.NUMTRANSENT,
                           P_CODPROD,
                           ENTRADAS.DATA,
                           P_DTSAIDA,
                           V_SALDO_SAI_TELA);
   ------------------------------------------------------------------------ 
            INSERIR_ENTRADAS(ENTRADAS.DATA,
                             ENTRADAS.NUMTRANSENT,
                             P_CODPROD,
                             ENTRADAS.QTCONT,
                             ENTRADAS.QTCONT - V_SALDO_SAI_TELA,
                             ENTRADAS.NUMSEQENTULTENT);
   ------------------------------------------------------------------------
            EXIT;
   ------------------------------------------------------------------------
         --Criado para atualizar e inserir informações quendo a quantidade do produto na 
         --entrada, não comporta a quantidade da saída.
         --Exemplo: Quantidade de produto da entrada 30 e quantidade de produto 
         --         de saída 40 (Nesse caso tenho que encontrar as quantidades de entrada
         --         notas no período anterior ao que está sendo realidado no momento).
         ELSE
            V_SALDO_ENTR_MAIOR_SAID := 'N';
   ------------------------------------------------------------------------
            IF V_SALDO_SAI_TEMP > ENTRADAS.QTCONT THEN
               V_SALDO_SAI := ENTRADAS.QTCONT;
               V_SALDO_ENT := 0;
            ELSE
               V_SALDO_SAI := V_SALDO_SAI_TEMP;
               V_SALDO_ENT := ENTRADAS.QTCONT - V_SALDO_SAI_TEMP;
            END IF;
   ------------------------------------------------------------------------
            V_SALDO_SAI_TEMP := V_SALDO_SAI_TEMP - ENTRADAS.QTCONT;
   ------------------------------------------------------------------------
            IF V_SALDO_SAI > 0 THEN
               INSERIR_SAIDAS(P_NUMTRANSVENDA,
                              ENTRADAS.NUMTRANSENT,
                              P_CODPROD,
                              ENTRADAS.DATA,
                              P_DTSAIDA,
                              V_SALDO_SAI);
            END IF;
   ------------------------------------------------------------------------
            INSERIR_ENTRADAS(ENTRADAS.DATA,
                             ENTRADAS.NUMTRANSENT,
                             P_CODPROD,
                             ENTRADAS.QTCONT,
                             V_SALDO_ENT,
                             ENTRADAS.NUMSEQENTULTENT);
   ------------------------------------------------------------------------
            IF V_SALDO_SAI_TEMP <= 0 THEN
               EXIT;
   ------------------------------------------------------------------------
            END IF;
         END IF;
      END LOOP;
   ------------------------------------------------------------------------
   ------------------------------------------------------------------------
   END;
   ------------------------------------------------------------------------
BEGIN
   ------------------------------------------------------------------------
   DELETAR_DADOS;
   ------------------------------------------------------------------------
   -- Definição de cursor
   FOR SAIDAS IN (SELECT N.NUMTRANSVENDA,
                         N.DTSAIDA,
                         M.CODPROD,
                         SUM(M.QTCONT) QTCONT
                  FROM PCNFSAID N,
                       PCMOV M
                  WHERE NVL(M.CODFILIALNF, M.CODFILIAL) = PCODFILIAL
                    AND M.DTMOV BETWEEN PDTINICIAL AND PDTFINAL
                    AND M.NUMTRANSVENDA = N.NUMTRANSVENDA
                    AND (M.CODPROD = NVL(PCODPROD,0)
                     OR  NVL(PCODPROD,0) = 0)
                    AND N.ESPECIE = 'NF'
                    AND M.QTCONT > 0
                    AND M.STATUS IN ('A','AB')
                    AND M.CODOPER IN ('S','SB','ST','SD','SP','SR','SI','SM','SV')
                    AND NVL(M.CODFISCAL,0) NOT IN (5929,6929)
                    AND NVL(N.CONDVENDA,0) NOT IN (3,6,7,12,13)
                    AND NVL(N.FINALIDADENFE,'O') <> 'C'
                    AND M.DTCANCEL IS NULL
                    AND N.DTCANCEL IS NULL
                    -- Caso o vínculo estava em períodos diferente do selecinado, não deverá fazer novo vínculo.
                    AND NOT EXISTS (SELECT 1
                                    FROM PCUEPSSALDOSAID U
                                    WHERE U.CODPROD = M.CODPROD
                                      AND NVL(M.CODFILIALNF,M.CODFILIAL) = U.CODFILIAL
                                      AND M.NUMTRANSVENDA = U.NUMTRANSVENDA)
                  GROUP BY N.NUMTRANSVENDA, N.DTSAIDA, M.CODPROD
                  ORDER BY M.CODPROD, DTSAIDA, NUMTRANSVENDA)
   LOOP
      ENTRADAS(SAIDAS.NUMTRANSVENDA, SAIDAS.DTSAIDA, SAIDAS.QTCONT, SAIDAS.CODPROD);
   END LOOP;
   ------------------------------------------------------------------------
   ------------------------------------------------------------------------
   MSG := 'OK';
   COMMIT;
   ------------------------------------------------------------------------
   /************************ FIM CORPO DA PROCEDURE **********************/
   EXCEPTION
   WHEN OTHERS THEN
   BEGIN
      ROLLBACK;
      MSG := 'ERRO AO GERAR UEPS CONTA CORRENTE: ' || CHR(13) ||
             sqlcode || ' ' || sqlerrm;
   END;
   ------------------------------------------------------------------------
   ------------------------------------------------------------------------
END; -- 10/05/2022 - Gleibe