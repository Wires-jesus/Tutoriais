CREATE OR REPLACE PROCEDURE PRC_FATURAR_CUPONS_MONTADOS (pdata IN DATE, psmensagem OUT VARCHAR2)
IS
   vicontador               NUMBER;
   vsusanumcarvendabalcao   VARCHAR2 (1);
BEGIN
   psmensagem := '';
   vicontador := 0;

   BEGIN
      SELECT usanumcarvendabalcao
        INTO vsusanumcarvendabalcao
        FROM pcconsum
       WHERE ROWNUM = 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE;
   END;

   FOR carregamento IN (SELECT   DATA, numcar, codfilial
                            FROM pcpedc
                           WHERE DATA >= pdata
                             AND posicao = 'M'
                             AND serieecf = 'X'
                             AND origemped = 'A'
                        GROUP BY DATA, numcar, codfilial)
   LOOP
      BEGIN
         prc_fatura_cupom (carregamento.DATA,
                           'SUPERVISOR',
                           carregamento.numcar,
                           '001',
                           carregamento.DATA,
                           carregamento.DATA,
                           0,
                           0,
                           carregamento.codfilial,
                           0,
                           0,
                           psmensagem
                          );

         IF psmensagem = 'OK'
         THEN
            prc_aux_dados_checkout (carregamento.numcar, psmensagem);

            IF psmensagem = 'OK'
            THEN
               prc_aux_desd_titulos (carregamento.numcar, psmensagem);

               IF psmensagem = 'OK'
               THEN
                  IF NVL (vsusanumcarvendabalcao, 'N') = 'N'
                  THEN
                     BEGIN
                        --GRAVACAO DO NUMCAR = 0 para o PCPREST //
                        UPDATE pcprest
                           SET numcar = 0
                         WHERE numcar = carregamento.numcar;

                        -- GRAVACAO DO NUMCAR = 0 para o PCNFSAID //
                        UPDATE pcnfsaid
                           SET numcar = 0
                         WHERE numcar = carregamento.numcar;

                        COMMIT;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           ROLLBACK;
                     END;
                  ELSE
                    BEGIN
                        --GRAVACAO DO NUMCAR = 0 para o PCPREST com pedidos do auto-serviço
                        UPDATE pcprest
                           SET numcar = 0
                         WHERE numcar = carregamento.numcar
                           AND numtransvenda in (select numtransvenda 
                                                 from pcpedc 
                                                 where origemped='A' 
                                                 and numcar=carregamento.numcar);

                        -- GRAVACAO DO NUMCAR = 0 para o PCNFSAID com pedidos do auto-serviço
                        UPDATE pcnfsaid
                           SET numcar = 0
                         WHERE numcar = carregamento.numcar
                           AND numtransvenda in (select numtransvenda 
                                                 from pcpedc 
                                                 where origemped='A' 
                                                 and numcar=carregamento.numcar);
                    EXCEPTION
                       WHEN OTHERS
                       THEN
                          ROLLBACK;                   
                    END;
                  END IF;                            --se usanumcarvendabalcao
               END IF;
            END IF;
         END IF;

         vicontador := vicontador + 1;
      EXCEPTION
         WHEN OTHERS
         THEN
            RAISE;
      END;
   END LOOP;
   if psmensagem = 'OK'
   THEN
       psmensagem := vicontador || ' carregamentos faturados.';
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      psmensagem := psmensagem || 'ERRO ' || SQLCODE || ' ' || SQLERRM;
END;                                                              -- Procedure
