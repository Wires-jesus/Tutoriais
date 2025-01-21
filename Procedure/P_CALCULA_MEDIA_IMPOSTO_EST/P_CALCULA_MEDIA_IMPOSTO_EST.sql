CREATE OR REPLACE PROCEDURE P_CALCULA_MEDIA_IMPOSTO_EST(PCODFILIAL IN VARCHAR2,
                                                        PDTINICIAL IN DATE,
                                                        PDTFINAL IN DATE,
                                                        PCALCULAMEDIACOMBASEQTDESTOQUE IN VARCHAR2,
                                                        PATUALIZAMEDIADIASEGUINTEENT IN VARCHAR2,
                                                        PQTMESES_ENT IN NUMBER,
                                                        MSG        OUT VARCHAR2) IS

   ------------------------------------------------------------------------
   -- Programa criado para manter um conta corrente das saidas com relação
   -- às entradas - UEPS
   ------------------------------------------------------------------------
   ------------------------------------------------------------------------
   vMSG                     Varchar2(50);
   VDATAINICIAL             DATE;
   V_QT_ENTRADA_USADA       NUMBER;
   V_QTEST_ANTERIOR         NUMBER;

   V_VL_TOTAL_ICMS          NUMBER;
   V_VL_TOTAL_ST            NUMBER;
   V_VL_TOTAL_FCPST         NUMBER;
   V_VL_TOTAL_BASE_ST       NUMBER;

   V_VL_MEDIA_ICMS          NUMBER;
   V_VL_MEDIA_ST            NUMBER;
   V_VL_MEDIA_VLMEDIA_FCPST NUMBER;

   V_VL_MEDIA_BASE_ST       NUMBER;
   --V_DIFERENCA_QT_ESTOQUE   NUMBER;

   PROCEDURE LIMPAR_DADOS_MEDIA_PERIODO AS
   BEGIN
      UPDATE PCHISTEST V
         SET V.VLMEDIAST = NULL,
             V.VLMEDIAICMS = NULL,
             V.VLMEDIAFCPST = NULL,
             V.VLMEDIABASEST = NULL
       WHERE V.CODFILIAL = PCODFILIAL
         AND V.DATA BETWEEN PDTINICIAL AND PDTFINAL
         --AND V.CODPROD IN ()
       ;
   END;


   PROCEDURE CALCULA_PRIMEIRA_VEZ(P_CODPROD NUMBER,
                                  P_DATA_INVENTARIO DATE,
                                  P_QUANTIDADE_ESTOQUE NUMBER) AS
   BEGIN
     V_QT_ENTRADA_USADA       := 0;
     V_QTEST_ANTERIOR         := 0;

     V_VL_TOTAL_ICMS          := 0;
     V_VL_TOTAL_ST            := 0;
     V_VL_TOTAL_FCPST         := 0;

     V_VL_MEDIA_ICMS          := 0;
     V_VL_MEDIA_ST            := 0;
     V_VL_MEDIA_VLMEDIA_FCPST := 0;

     V_VL_TOTAL_BASE_ST       := 0;
     V_VL_MEDIA_BASE_ST       := 0;

     FOR ENTRADAS IN (SELECT  NVL(E.CODFILIALNF,E.CODFILIAL) CODFILIAL,
                              E.NUMTRANSENT,
                              E.NUMNOTA,
                              M.CODPROD,
                              E.DTENT,
                              M.QTCONT,
                              CASE WHEN (NVL(M.BASEICMS,0) = 0) AND
                                        (NVL(M.STBCR,0) > 0) THEN
                                (NVL(M.VLICMSBCR,0) * M.QTCONT)
                              ELSE  
                                (((NVL(M.BASEICMS,0) + NVL(CP.VLBASEOUTROS,0) + NVL(CP.VLBASEFRETE,0)) * M.QTCONT) * (M.PERCICM /100))                              
                              END VLICMS,
                              (NVL(M.ST,0) * M.QTCONT) VLST,
                              (NVL(M.VLDESPADICIONAL,0) * M.QTCONT) VLSTFORANF,
                              (NVL(M.STBCR,0) * M.QTCONT) VLSTSTBCR,
                              (NVL(CP.VLFECP,0) * M.QTCONT) VLFECP,
                              (NVL(CP.VLFECPSTGUIA,0) * M.QTCONT) VLFECPSTGUIA,
                              (NVL(CP.VLFCPSTRET,0) * M.QTCONT) VLFCPSTRET,
                              (NVL(M.VLBASESTFORANF,0)  * M.QTCONT) VLBASESTFORANF,
                              (NVL(M.BASEBCR,0)  * M.QTCONT) BASEBCR,
                              (NVL(M.BASEICST,0)  * M.QTCONT) BASEICST
                       FROM PCNFENT E,
                            PCMOV M,
                            PCMOVCOMPLE CP
                       WHERE E.CODFILIAL    = M.CODFILIAL
                         AND E.NUMTRANSENT  = M.NUMTRANSENT
                         AND E.NUMNOTA      = M.NUMNOTA                         
                         AND M.NUMTRANSITEM = CP.NUMTRANSITEM
                         AND NVL(E.CODFILIALNF,E.CODFILIAL) = PCODFILIAL
                         AND M.CODPROD = P_CODPROD
                         AND CASE 
                                WHEN PATUALIZAMEDIADIASEGUINTEENT = 'S' THEN
                                  CASE
                                    WHEN E.DTENT = LAST_DAY(E.DTENT) THEN 
                                      TRUNC(ADD_MONTHS(E.DTENT, 1), 'MM')
                                    ELSE E.DTENT + 1
                                  END
                              ELSE
                                E.DTENT
                              END <= P_DATA_INVENTARIO
                         AND CASE 
                                WHEN PATUALIZAMEDIADIASEGUINTEENT = 'S' THEN
                                  CASE
                                    WHEN E.DTENT = LAST_DAY(E.DTENT) THEN 
                                      TRUNC(ADD_MONTHS(E.DTENT, 1), 'MM')
                                    ELSE E.DTENT + 1
                                  END
                              ELSE
                                E.DTENT
                              END >= ADD_MONTHS(PDTINICIAL, -PQTMESES_ENT)
                         AND E.ESPECIE = 'NF'
                         AND M.QTCONT > 0
                         AND M.STATUS IN ('A','AB')
                         AND E.TIPODESCARGA <> 'F'
                         AND NVL(E.NFENTREGAFUTURA,'N') = 'N'
                         AND M.CODOPER IN ('E','ET')
                         AND M.DTCANCEL IS NULL
                         AND (NVL(M.ST,0) +  NVL(M.VLDESPADICIONAL,0) + NVL(M.STBCR,0) > 0)
                       ORDER BY DTENT DESC, NUMTRANSENT DESC)
     LOOP
       MSG := 'ENTROU NO LOOP PRIMEIRA VEZ';


       IF (ENTRADAS.VLST + ENTRADAS.VLSTFORANF > 0) THEN
         V_VL_TOTAL_ICMS         := V_VL_TOTAL_ICMS    + ENTRADAS.VLICMS;
         V_VL_TOTAL_ST           := V_VL_TOTAL_ST      + (ENTRADAS.VLST + ENTRADAS.VLSTFORANF);
         V_VL_TOTAL_FCPST        := V_VL_TOTAL_FCPST   + (ENTRADAS.VLFECP + ENTRADAS.VLFECPSTGUIA);

         V_VL_TOTAL_BASE_ST     := V_VL_TOTAL_BASE_ST   + (ENTRADAS.BASEICST + ENTRADAS.VLBASESTFORANF);
       ELSE
         V_VL_TOTAL_ICMS        := V_VL_TOTAL_ICMS    + ENTRADAS.VLICMS;
         V_VL_TOTAL_ST          := V_VL_TOTAL_ST      + ENTRADAS.VLSTSTBCR;
         V_VL_TOTAL_BASE_ST     := V_VL_TOTAL_BASE_ST + (ENTRADAS.BASEBCR);
       END IF;

       V_QT_ENTRADA_USADA      := V_QT_ENTRADA_USADA + ENTRADAS.QTCONT;

       IF (V_QT_ENTRADA_USADA = P_QUANTIDADE_ESTOQUE) AND
          (PCALCULAMEDIACOMBASEQTDESTOQUE = 'S')  THEN
         EXIT;
       END IF;

       IF (V_QT_ENTRADA_USADA > P_QUANTIDADE_ESTOQUE)  AND
          (PCALCULAMEDIACOMBASEQTDESTOQUE = 'S') THEN
         --V_DIFERENCA_QT_ESTOQUE := V_QT_ENTRADA_USADA - P_QUANTIDADE_ESTOQUE;
         --V_QT_ENTRADA_USADA     := V_QT_ENTRADA_USADA - V_DIFERENCA_QT_ESTOQUE;
         EXIT;
       END IF;

     END LOOP;   


     --CALCULANDO A MÉDIA
     MSG := 'CALCULANDO A MÉDIA PRIMEIRA VEZ';
     IF (V_QT_ENTRADA_USADA > 0) THEN
       V_VL_MEDIA_ICMS          := ROUND((V_VL_TOTAL_ICMS  / V_QT_ENTRADA_USADA),6);
       V_VL_MEDIA_ST            := ROUND((V_VL_TOTAL_ST    / V_QT_ENTRADA_USADA),6);
       V_VL_MEDIA_VLMEDIA_FCPST := ROUND((V_VL_TOTAL_FCPST / V_QT_ENTRADA_USADA),6);

       V_VL_MEDIA_BASE_ST       := ROUND((V_VL_TOTAL_BASE_ST / V_QT_ENTRADA_USADA),6);

       --ATUALIZA A PCHISTEST COM O VALOR DA MÉDIA
       UPDATE PCHISTEST
          SET VLMEDIAICMS   = V_VL_MEDIA_ICMS,
              VLMEDIAST     = V_VL_MEDIA_ST,
              VLMEDIAFCPST  = V_VL_MEDIA_VLMEDIA_FCPST,
              VLMEDIABASEST = V_VL_MEDIA_BASE_ST
        WHERE CODFILIAL = PCODFILIAL
          AND CODPROD   = P_CODPROD
          AND DATA      = P_DATA_INVENTARIO;
      --  COMMIT;
     END IF;
   END;


   PROCEDURE CALCULA_MEDIA_DIA(P_CODPROD NUMBER,
                               P_DATA_INVENTARIO DATE,
                               P_QTEST_ANTERIOR NUMBER,
                               P_VLMEDIAICMS_ANTERIOR NUMBER,
                               P_VLMEDIAST_ANTERIOR NUMBER,
                               P_VLMEDIAFCPST_ANTERIOR NUMBER,
                               P_VLMEDIABASEST_ANTERIOR  NUMBER,
                               P_QTEST_DIA NUMBER) AS
   BEGIN
     V_QT_ENTRADA_USADA       := 0;
     V_QTEST_ANTERIOR         := 0;

     V_VL_TOTAL_ICMS          := 0;
     V_VL_TOTAL_ST            := 0;
     V_VL_TOTAL_FCPST         := 0;

     V_VL_MEDIA_ICMS          := 0;
     V_VL_MEDIA_ST            := 0;
     V_VL_MEDIA_VLMEDIA_FCPST := 0;

     V_VL_TOTAL_BASE_ST       := 0;
     V_VL_MEDIA_BASE_ST       := 0;

     FOR ENTRADAS IN (SELECT  NVL(E.CODFILIALNF,E.CODFILIAL) CODFILIAL,
                              E.NUMTRANSENT,
                              E.NUMNOTA,
                              M.CODPROD,
                              E.DTENT,
                              M.QTCONT,
                              CASE WHEN (NVL(M.BASEICMS,0) = 0) AND
                                        (NVL(M.STBCR,0) > 0) THEN
                                (NVL(M.VLICMSBCR,0) * M.QTCONT)
                              ELSE  
                                (((NVL(M.BASEICMS,0) + NVL(CP.VLBASEOUTROS,0) + NVL(CP.VLBASEFRETE,0)) * M.QTCONT) * (M.PERCICM /100))                              
                              END VLICMS,
                              (NVL(M.ST,0) * M.QTCONT) VLST,
                              (NVL(M.VLDESPADICIONAL,0) * M.QTCONT) VLSTFORANF,
                              (NVL(M.STBCR,0) * M.QTCONT) VLSTSTBCR,
                              (NVL(CP.VLFECP,0) * M.QTCONT) VLFECP,
                              (NVL(CP.VLFECPSTGUIA,0) * M.QTCONT) VLFECPSTGUIA,
                              (NVL(CP.VLFCPSTRET,0) * M.QTCONT) VLFCPSTRET,
                              (NVL(M.VLBASESTFORANF,0)  * M.QTCONT) VLBASESTFORANF,
                              (NVL(M.BASEBCR,0)  * M.QTCONT) BASEBCR,
                              (NVL(M.BASEICST,0)  * M.QTCONT) BASEICST
                       FROM PCNFENT E,
                            PCMOV M,
                            PCMOVCOMPLE CP
                       WHERE E.CODFILIAL   = M.CODFILIAL
                         AND E.NUMTRANSENT = M.NUMTRANSENT
                         AND E.NUMNOTA     = M.NUMNOTA
                         AND M.NUMTRANSITEM = CP.NUMTRANSITEM
                         AND NVL(E.CODFILIALNF,E.CODFILIAL) = PCODFILIAL
                         AND M.CODPROD = P_CODPROD
                         AND CASE 
                                WHEN PATUALIZAMEDIADIASEGUINTEENT = 'S' THEN
                                  CASE
                                    WHEN E.DTENT = LAST_DAY(E.DTENT) THEN 
                                      TRUNC(ADD_MONTHS(E.DTENT, 1), 'MM')
                                    ELSE E.DTENT + 1
                                  END
                              ELSE
                                E.DTENT
                              END = P_DATA_INVENTARIO
                         AND E.ESPECIE = 'NF'
                         AND M.QTCONT > 0
                         AND M.STATUS IN ('A','AB')
                         AND E.TIPODESCARGA <> 'F'
                         AND NVL(E.NFENTREGAFUTURA,'N') = 'N'
                         AND M.CODOPER IN ('E','ET')
                         AND M.DTCANCEL IS NULL
                         AND (NVL(M.ST,0) +  NVL(M.VLDESPADICIONAL,0) + NVL(M.STBCR,0) > 0)
                       ORDER BY DTENT DESC, NUMTRANSENT DESC)
     LOOP

       IF (ENTRADAS.VLST + ENTRADAS.VLSTFORANF > 0) THEN
         V_VL_TOTAL_ICMS         := V_VL_TOTAL_ICMS    + ENTRADAS.VLICMS;
         V_VL_TOTAL_ST           := V_VL_TOTAL_ST      + (ENTRADAS.VLST + ENTRADAS.VLSTFORANF);
         V_VL_TOTAL_FCPST        := V_VL_TOTAL_FCPST   + (ENTRADAS.VLFECP + ENTRADAS.VLFECPSTGUIA);

         V_VL_TOTAL_BASE_ST     := V_VL_TOTAL_BASE_ST   + (ENTRADAS.BASEICST + ENTRADAS.VLBASESTFORANF);
       ELSE
         V_VL_TOTAL_ICMS        := V_VL_TOTAL_ICMS    + ENTRADAS.VLICMS;
         V_VL_TOTAL_ST          := V_VL_TOTAL_ST      + ENTRADAS.VLSTSTBCR;
         V_VL_TOTAL_BASE_ST     := V_VL_TOTAL_BASE_ST   + (ENTRADAS.BASEBCR);
       END IF;

       V_QT_ENTRADA_USADA      := V_QT_ENTRADA_USADA + ENTRADAS.QTCONT;
     END LOOP;
     
     V_QTEST_ANTERIOR := P_QTEST_ANTERIOR;
     IF PATUALIZAMEDIADIASEGUINTEENT = 'S' THEN
       V_QTEST_ANTERIOR := GREATEST(V_QTEST_ANTERIOR - V_QT_ENTRADA_USADA,0);
     END IF;

     IF (P_VLMEDIAICMS_ANTERIOR < 0) THEN
       V_VL_MEDIA_ICMS          := 0;
     ELSE
       V_VL_MEDIA_ICMS          := P_VLMEDIAICMS_ANTERIOR;
     END IF;

     IF (P_VLMEDIAST_ANTERIOR < 0) THEN
       V_VL_MEDIA_ST          := 0;
     ELSE
       V_VL_MEDIA_ST            := P_VLMEDIAST_ANTERIOR;
     END IF;

     IF (P_VLMEDIAFCPST_ANTERIOR < 0) THEN
       V_VL_MEDIA_VLMEDIA_FCPST          := 0;
     ELSE
       V_VL_MEDIA_VLMEDIA_FCPST := P_VLMEDIAFCPST_ANTERIOR;
     END IF;

     IF (P_VLMEDIABASEST_ANTERIOR < 0) THEN
       V_VL_MEDIA_BASE_ST          := 0;
     ELSE
       V_VL_MEDIA_BASE_ST := P_VLMEDIABASEST_ANTERIOR;
     END IF;

     --CALCULANDO A MÉDIA
     IF (V_QT_ENTRADA_USADA > 0) THEN
       V_VL_MEDIA_ICMS          := ROUND(( ((P_VLMEDIAICMS_ANTERIOR * V_QTEST_ANTERIOR)  + V_VL_TOTAL_ICMS ) /(V_QT_ENTRADA_USADA + V_QTEST_ANTERIOR)   ),6);
       V_VL_MEDIA_ST            := ROUND(( ((P_VLMEDIAST_ANTERIOR * V_QTEST_ANTERIOR)  + V_VL_TOTAL_ST) /(V_QT_ENTRADA_USADA + V_QTEST_ANTERIOR)   ),6);
       V_VL_MEDIA_VLMEDIA_FCPST := ROUND(( ((P_VLMEDIAFCPST_ANTERIOR * V_QTEST_ANTERIOR)  + V_VL_TOTAL_FCPST) /(V_QT_ENTRADA_USADA + V_QTEST_ANTERIOR)   ),6);

       V_VL_MEDIA_BASE_ST       := ROUND(( ((P_VLMEDIABASEST_ANTERIOR * V_QTEST_ANTERIOR)  + V_VL_TOTAL_BASE_ST) /(V_QT_ENTRADA_USADA + V_QTEST_ANTERIOR)   ),6);
     END IF;
     
     IF (V_QT_ENTRADA_USADA > 0) AND
        (V_QTEST_ANTERIOR = 0) THEN
       V_VL_MEDIA_ICMS          := ROUND(( V_VL_TOTAL_ICMS  /V_QT_ENTRADA_USADA   ),6);
       V_VL_MEDIA_ST            := ROUND(( V_VL_TOTAL_ST    / V_QT_ENTRADA_USADA   ),6);
       V_VL_MEDIA_VLMEDIA_FCPST := ROUND(( V_VL_TOTAL_FCPST /V_QT_ENTRADA_USADA   ),6);

       V_VL_MEDIA_BASE_ST       := ROUND(( V_VL_TOTAL_BASE_ST /V_QT_ENTRADA_USADA ),6);
     END IF;
     


     UPDATE PCHISTEST
        SET VLMEDIAICMS   = V_VL_MEDIA_ICMS,
            VLMEDIAST     = V_VL_MEDIA_ST,
            VLMEDIAFCPST  = V_VL_MEDIA_VLMEDIA_FCPST,
            VLMEDIABASEST = V_VL_MEDIA_BASE_ST
      WHERE CODFILIAL = PCODFILIAL
        AND CODPROD   = P_CODPROD
        AND DATA      = P_DATA_INVENTARIO;

    -- COMMIT;
   END;


   -- Inicio -----------------------------------------------------------------------------------------------------------------------
BEGIN

   VDATAINICIAL := PDTINICIAL-1;

   --- Iniciamos com a limpeza da informação de média do período.
   LIMPAR_DADOS_MEDIA_PERIODO;

   FOR PRODUTO_ESTOQUE IN (SELECT H.CODFILIAL,
                                  H.DATA,
                                  H.CODPROD
                             FROM PCHISTEST H
                            WHERE H.CODFILIAL = PCODFILIAL
                              AND H.CODPROD NOT IN (SELECT CODPROD FROM PCLISTAPROD_TMP)
                              AND H.DATA BETWEEN VDATAINICIAL AND PDTFINAL
                              --and h.codprod = 35884
                              order by h.data asc)
   LOOP
     FOR PRODUTO IN (SELECT H.CODFILIAL,
                            H.DATA,
                            H.CODPROD,
                            NVL(H.VLMEDIAICMS,-1) VLMEDIAICMS,
                            NVL(H.VLMEDIAST,-1) VLMEDIAST,
                            NVL(H.VLMEDIAFCPST,-1) VLMEDIAFCPST,
                            NVL(H.VLMEDIABASEST,-1) VLMEDIABASEST,
                            H.QTEST,
                            CASE WHEN LAG(H.QTEST, 1, -1) OVER (ORDER BY DATA) < 0 THEN 0 ELSE LAG(H.QTEST, 1, -1) OVER (ORDER BY DATA) END AS QTEST_ANTERIOR,
                            LAG(NVL(H.VLMEDIAICMS,-1), 1, -1) OVER (ORDER BY DATA) AS VLMEDIAICMS_ANTERIOR,
                            LAG(NVL(H.VLMEDIAST,-1), 1, -1) OVER (ORDER BY DATA) AS VLMEDIAST_ANTERIOR,
                            LAG(NVL(H.VLMEDIAFCPST,-1), 1, -1) OVER (ORDER BY DATA) AS VLMEDIAFCPST_ANTERIOR,
                            LAG(NVL(H.VLMEDIABASEST,-1), 1, -1) OVER (ORDER BY DATA) AS VLMEDIABASEST_ANTERIOR
                       FROM PCHISTEST H
                      WHERE H.CODFILIAL = PRODUTO_ESTOQUE.CODFILIAL
                        AND H.CODPROD   = PRODUTO_ESTOQUE.CODPROD
                        AND H.DATA      BETWEEN PRODUTO_ESTOQUE.DATA -1 AND PRODUTO_ESTOQUE.DATA
                   ORDER BY H.DATA ASC)
     LOOP
       ------------------------------------------------------------------------
       ------------------------------------------------------------------------


       IF PRODUTO.DATA = PRODUTO_ESTOQUE.DATA THEN
         IF ((PRODUTO_ESTOQUE.DATA = PDTINICIAL) AND
             (PCALCULAMEDIACOMBASEQTDESTOQUE = 'S')) THEN
            --CHAMA PRIMEIRO CÁLCULO
             CALCULA_PRIMEIRA_VEZ(PRODUTO.CODPROD,
                                  PRODUTO.DATA,
                                  PRODUTO.QTEST);
         ELSIF (PRODUTO_ESTOQUE.DATA >= PDTINICIAL) THEN


            CALCULA_MEDIA_DIA(PRODUTO.CODPROD,
                              PRODUTO.DATA,
                              PRODUTO.QTEST_ANTERIOR,
                              PRODUTO.VLMEDIAICMS_ANTERIOR,
                              PRODUTO.VLMEDIAST_ANTERIOR,
                              PRODUTO.VLMEDIAFCPST_ANTERIOR,
                              PRODUTO.VLMEDIABASEST_ANTERIOR,
                              PRODUTO.QTEST);
         END IF;
       ------------------------------------------------------------------------
       ------------------------------------------------------------------------
       END IF;                    
     END LOOP;
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
      MSG := 'ERRO AO CÁLCULO DA MÉDIA DE IMPOSTOS: ' || CHR(13) ||
             sqlcode || ' ' || sqlerrm;
   END;
   ------------------------------------------------------------------------
   ------------------------------------------------------------------------
END;
-- Rotina 1068
-- Última alteração: 24/08/2021 - Implementado alteração na composição do campo qtest_anterior. Não será considerado valor negativo
--
