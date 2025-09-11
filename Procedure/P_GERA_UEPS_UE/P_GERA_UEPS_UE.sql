CREATE OR REPLACE PROCEDURE P_GERA_UEPS_UE(PCODFILIAL IN VARCHAR2,
                                           PDTINICIAL IN DATE,
                                           PDTFINAL   IN DATE,
                                           PCODPROD   IN NUMBER,
                                           PQTMESES_ENT   IN NUMBER,                                           
                                           MSG        OUT VARCHAR2) IS
   ------------------------------------------------------------------------
   -- Programa criado para manter um conta corrente das saidas com relação
   -- às entradas - UEPS
   ------------------------------------------------------------------------
   V_NUMTRANSVENDA NUMBER;
   ------------------------------------------------------------------------
   -- Deleção de movimentação do produto, período e filial
   PROCEDURE DELETAR_DADOS IS
   BEGIN
   ------------------------------------------------------------------------
      -- Apaga os registros de vínculos do período informado em diante
      DELETE FROM PCUEPSSAIDUE
      WHERE DTSAIDA BETWEEN PDTINICIAL AND PDTFINAL
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
                            P_NUMSEQ_ENT    IN NUMBER,
                            P_NUMSEQ        IN NUMBER) IS
   BEGIN
      INSERT INTO PCUEPSSAIDUE
         (CODFILIAL,
          NUMTRANSVENDA,
          NUMTRANSENT,
          CODPROD,
          DTENT,
          DTSAIDA,
          NUMSEQENTULTENT,
          NUMSEQ)
      VALUES
         (PCODFILIAL,
          P_NUMTRANSVENDA,
          P_NUMTRANSENT,
          P_CODPROD,
          P_DTENT,
          P_DTSAIDA,
          P_NUMSEQ_ENT,
          P_NUMSEQ);
   END;
   ------------------------------------------------------------------------
   -- Insere registro de controle de saída
   PROCEDURE ENTRADAS(P_NUMTRANSVENDA IN NUMBER,
                      P_DTSAIDA       IN DATE,
                      P_CODPROD       IN NUMBER) IS
   BEGIN
      V_NUMTRANSVENDA := P_NUMTRANSVENDA;
      
      FOR ENTRADAS IN (
                       SELECT T.TIPO AS CODFILIAL, 
                              T.NUMTRANSENT, 
                              T.CODPROD, 
                              T.DATA, 
                              T.CODCONT AS NUMSEQENTULTENT, 
                              T.SEQMOV AS NUMSEQ        
                         FROM PCDADOS1070_TEMP T
                        WHERE T.TIPO = PCODFILIAL
                          AND T.DATA BETWEEN ADD_MONTHS(PDTINICIAL,-PQTMESES_ENT) AND PDTFINAL
                          AND T.CODPROD = P_CODPROD
                          AND T.DATA <= P_DTSAIDA
                       ORDER BY T.DATA DESC, T.NUMTRANSENT DESC
                       )
                       
      LOOP
   ------------------------------------------------------------------------
         IF P_NUMTRANSVENDA = V_NUMTRANSVENDA THEN
            V_NUMTRANSVENDA := 0;
            INSERIR_SAIDAS(P_NUMTRANSVENDA,
                           ENTRADAS.NUMTRANSENT,
                           P_CODPROD,
                           ENTRADAS.DATA,
                           P_DTSAIDA,
                           ENTRADAS.NUMSEQENTULTENT,
                           ENTRADAS.NUMSEQ);
         END IF;
      END LOOP;
   ------------------------------------------------------------------------
   END;
   ------------------------------------------------------------------------
BEGIN
      ------------------------------------------------------------------------
      DELETAR_DADOS;
      ------------------------------------------------------------------------
      -- LIMPANDO TABELA TEMPORARIA
      DELETE FROM PCDADOS1070_TEMP; 
      -- INSERT ENTRADA
      INSERT INTO PCDADOS1070_TEMP (TIPO, NUMTRANSENT, CODPROD, DATA, CODCONT , SEQMOV)
       SELECT NVL(E.CODFILIALNF,E.CODFILIAL) CODFILIAL,
              E.NUMTRANSENT,
              M.CODPROD,
              E.DTENT DATA,
              MAX(NVL(CP.NUMSEQENT, 1)) NUMSEQENTULTENT,
              MAX(NVL(M.NUMSEQ, 1)) NUMSEQ
       FROM PCNFENT E,
            PCMOV M,
            PCMOVCOMPLE CP
       WHERE E.CODFILIAL   = M.CODFILIAL
         AND E.NUMTRANSENT = M.NUMTRANSENT
         AND E.NUMNOTA     = M.NUMNOTA
         AND M.NUMTRANSITEM = CP.NUMTRANSITEM
         AND NVL(E.CODFILIALNF,E.CODFILIAL) = PCODFILIAL
         AND E.DTENT BETWEEN ADD_MONTHS(PDTINICIAL,-PQTMESES_ENT) AND PDTFINAL
         --AND M.CODPROD = P_CODPROD
         AND M.NUMTRANSENT > 0
         AND E.ESPECIE = 'NF'
         AND M.QTCONT > 0
         AND M.STATUS IN ('A','AB')
         AND E.TIPODESCARGA <> 'F'
         AND NVL(E.NFENTREGAFUTURA,'N') = 'N'
         AND M.CODOPER IN ('E','EB','ET','ER','EI')
         AND M.SITTRIBUT NOT IN (40,41,90)
         AND M.DTCANCEL IS NULL
         AND E.TIPODESCARGA NOT IN ('P','G')
         --AND E.DTENT <= P_DTSAIDA
       GROUP BY M.CODPROD, E.DTENT, NVL(E.CODFILIALNF, E.CODFILIAL), E.NUMTRANSENT
       ORDER BY DATA DESC, NUMTRANSENT DESC;
      --------------------------------------------------------------------------------------------                 
      -- Definição de cursor
      FOR SAIDAS IN (SELECT N.NUMTRANSVENDA,
                            N.DTSAIDA,
                            M.CODPROD
                     FROM PCNFSAID N,
                          PCMOV M
                     WHERE N.CODFILIAL      = M.CODFILIAL
                       AND N.NUMTRANSVENDA  = M.NUMTRANSVENDA
                       AND N.NUMNOTA        = M.NUMNOTA                       
                       AND NVL(M.CODFILIALNF, M.CODFILIAL) = PCODFILIAL
                       AND NVL(N.CODFILIALNF, N.CODFILIAL) = PCODFILIAL
                       AND N.DTSAIDA BETWEEN PDTINICIAL AND PDTFINAL                       
                       AND (M.CODPROD = PCODPROD OR  PCODPROD = 0)
                       AND M.NUMTRANSVENDA > 0
                       AND N.ESPECIE = 'NF'
                       AND M.QTCONT > 0
                       AND M.STATUS IN ('A','AB')
                       AND M.CODOPER IN ('S','SB','ST','SD','SP','SR','SI','SA','SL','SM','SV')
                       AND NVL(M.CODFISCAL,0) NOT IN (5929,6929)
                       AND NVL(N.CONDVENDA,0) NOT IN (3,6,7,12,13)
                       AND NVL(N.FINALIDADENFE,'O') <> 'C'
                       AND M.DTCANCEL IS NULL
                       AND N.DTCANCEL IS NULL
                       AND NOT EXISTS (SELECT 1
                                       FROM PCUEPSSAIDUE U
                                       WHERE U.CODPROD = M.CODPROD
                                         AND NVL(M.CODFILIALNF,M.CODFILIAL) = U.CODFILIAL
                                         AND M.NUMTRANSVENDA = U.NUMTRANSVENDA)
                     GROUP BY N.NUMTRANSVENDA, N.DTSAIDA, M.CODPROD
                     ORDER BY M.CODPROD, DTSAIDA, NUMTRANSVENDA)
      LOOP
         ENTRADAS(SAIDAS.NUMTRANSVENDA, SAIDAS.DTSAIDA, SAIDAS.CODPROD);
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
         MSG := 'ERRO AO GERAR UEPS - ÚLTIMA ENTRADA: ' || CHR(13) ||
                sqlcode || ' ' || sqlerrm;
      END;
   ------------------------------------------------------------------------
   ------------------------------------------------------------------------
END; 
-- última alteração : 07/02/2021 - Gleibe
-- Atualização da versão master e dev