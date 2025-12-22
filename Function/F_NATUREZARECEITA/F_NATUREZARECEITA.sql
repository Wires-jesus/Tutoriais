CREATE OR REPLACE FUNCTION F_NATUREZARECEITA(
   PDATA       IN DATE,
   PCST        IN VARCHAR2,
   PCODPROD    IN NUMERIC,
   PNCM        IN VARCHAR2,
   PNCMEXC     IN VARCHAR2,
   PTIPI       IN VARCHAR2)

   RETURN VARCHAR2 IS

   VNATRECEITA VARCHAR2(3);
   VEXISTEEXCESSAO VARCHAR2(1);
------------------------------------------------------------------------
   -- Função para verificar se existe exceções - PCEXCTABESCRSPED
------------------------------------------------------------------------
   FUNCTION EXISTE_EXCECAO(PSEQUENCIA IN NUMBER,
                           PNCMEXC IN VARCHAR2,
                           PTIPI IN VARCHAR2) RETURN VARCHAR2 IS
      VRETORNO VARCHAR2(1);
   BEGIN
      BEGIN
         VRETORNO := 'N';
         IF PNCMEXC <> '' OR PTIPI <> '' THEN
            FOR ITENS IN (SELECT SEQUENCIA,
                                 REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') NCM,
                                 CODEXTIPI
                          FROM PCEXCTABESCRSPED
                          WHERE SEQUENCIA = PSEQUENCIA)
            LOOP
               IF PNCMEXC <> '' AND PTIPI <> '' THEN
                  IF ITENS.NCM = SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCMEXC,' ',''),'.',''),',',''),'/',''),'-',''),'_','')
                                       ,1,LENGTH(ITENS.NCM)) AND ITENS.CODEXTIPI = PTIPI THEN
                     VRETORNO := 'S';
                     EXIT;
                  END IF;
               ELSIF PNCMEXC <> '' THEN
                  IF ITENS.NCM = PNCMEXC THEN
                     VRETORNO := 'S';
                     EXIT;
                  END IF;
               ELSIF PTIPI <> '' THEN
                  IF ITENS.NCM = SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCMEXC,' ',''),'.',''),',',''),'/',''),'-',''),'_','')
                                       ,1,LENGTH(ITENS.NCM)) THEN
                     VRETORNO := 'S';
                     EXIT;
                  END IF;
               END IF;
            END LOOP;
         END IF;

         RETURN VRETORNO;
      EXCEPTION
         WHEN OTHERS THEN
            RETURN 'N';
      END;
   END;
------------------------------------------------------------------------
   function RETORNANATPORNCM RETURN VARCHAR2 IS
     vResult VARCHAR2(4);
   begin
     vResult := '';
     case pCST
       WHEN 04 THEN
         SELECT max(T.CODNATREC) NAT
          into vResult
          FROM PCTABESCRSPED T
         WHERE T.CODPROD IS NULL
           AND REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') =
               REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')
           AND ((T.DATAINIESCR IS NULL AND T.DATAFINESCR IS NULL)
               OR  (T.DATAINIESCR <= PDATA AND T.DATAFINESCR IS NULL)
               OR  (PDATA BETWEEN T.DATAINIESCR AND T.DATAFINESCR AND T.DATAINIESCR IS NOT NULL AND T.DATAFINESCR IS NOT NULL))
           and T.TIPOREGISTRO IN ('M4310','C4311','B4311','A4311','P4312');
       WHEN 05 THEN
        SELECT max(T.CODNATREC)
          into vResult
          FROM PCTABESCRSPED T
         WHERE T.CODPROD IS NULL
           AND REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') =
               REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')
           AND ((T.DATAINIESCR IS NULL AND T.DATAFINESCR IS NULL)
               OR  (T.DATAINIESCR <= PDATA AND T.DATAFINESCR IS NULL)
               OR  (PDATA BETWEEN T.DATAINIESCR AND T.DATAFINESCR AND T.DATAINIESCR IS NOT NULL AND T.DATAFINESCR IS NOT NULL))
           and T.TIPOREGISTRO = 'P4312';
       WHEN 06 THEN
        SELECT max(T.CODNATREC)
          into vResult
          FROM PCTABESCRSPED T
         WHERE T.CODPROD IS NULL
           AND REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') =
               REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')
           AND ((T.DATAINIESCR IS NULL AND T.DATAFINESCR IS NULL)
               OR  (T.DATAINIESCR <= PDATA AND T.DATAFINESCR IS NULL)
               OR  (PDATA BETWEEN T.DATAINIESCR AND T.DATAFINESCR AND T.DATAINIESCR IS NOT NULL AND T.DATAFINESCR IS NOT NULL))
           and T.TIPOREGISTRO = 'R4313';
       WHEN 07 THEN
        SELECT max(T.CODNATREC)
          into vResult
          FROM PCTABESCRSPED T
         WHERE T.CODPROD IS NULL
           AND REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') =
               REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')
           AND ((T.DATAINIESCR IS NULL AND T.DATAFINESCR IS NULL)
               OR  (T.DATAINIESCR <= PDATA AND T.DATAFINESCR IS NULL)
               OR  (PDATA BETWEEN T.DATAINIESCR AND T.DATAFINESCR AND T.DATAINIESCR IS NOT NULL AND T.DATAFINESCR IS NOT NULL))
           and T.TIPOREGISTRO = 'I4314';
       WHEN 08 THEN
        SELECT max(T.CODNATREC)
          into vResult
          FROM PCTABESCRSPED T
         WHERE T.CODPROD IS NULL
           AND REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') =
               REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')
           AND ((T.DATAINIESCR IS NULL AND T.DATAFINESCR IS NULL)
               OR  (T.DATAINIESCR <= PDATA AND T.DATAFINESCR IS NULL)
               OR  (PDATA BETWEEN T.DATAINIESCR AND T.DATAFINESCR AND T.DATAINIESCR IS NOT NULL AND T.DATAFINESCR IS NOT NULL))
           and T.TIPOREGISTRO = 'I4315';
       ELSE
        SELECT max(T.CODNATREC)
          into vResult
          FROM PCTABESCRSPED T
         WHERE T.CODPROD IS NULL
           AND REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') =
               REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')
           AND ((T.DATAINIESCR IS NULL AND T.DATAFINESCR IS NULL)
               OR  (T.DATAINIESCR <= PDATA AND T.DATAFINESCR IS NULL)
               OR  (PDATA BETWEEN T.DATAINIESCR AND T.DATAFINESCR AND T.DATAINIESCR IS NOT NULL AND T.DATAFINESCR IS NOT NULL))
           and T.TIPOREGISTRO = 'S4316';
     END case;

     if vResult = '' or vResult is null  then
       vResult := '999';
     end if;
     return vResult;
   end;
BEGIN
   /*Iniciando Variaveis */
   VNATRECEITA := '999';
   VEXISTEEXCESSAO := 'N';

   ---------------------------------------------------------------------
   ---------------------------------------------------------------------
   -- Tabelas 4.3.10, 4.3.11, 4.3.11, 4.3.11 e 4.3.12 (M4310, C4311, B4311, A4311 e P4312)
   IF PCST = 04 THEN
      /*CONSULTA POR PRODUTO*/
      FOR DADOS IN (SELECT T.SEQUENCIA,
                           T.TIPOREGISTRO,
                           T.TABELA,
                           T.CODNATREC,
                           REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') NCM,
                           T.DATAINIESCR,
                           T.DATAFINESCR,
                           T.CODPROD
                    FROM PCTABESCRSPED T
                    WHERE T.TIPOREGISTRO IN ('M4310','C4311','B4311','A4311','P4312')
                      AND (T.CODPROD = PCODPROD OR PCODPROD = 0)
                      AND ((T.DATAINIESCR IS NULL AND T.DATAFINESCR IS NULL)
                       OR  (T.DATAINIESCR <= PDATA AND T.DATAFINESCR IS NULL)
                       OR  (PDATA BETWEEN T.DATAINIESCR AND T.DATAFINESCR AND T.DATAINIESCR IS NOT NULL AND T.DATAFINESCR IS NOT NULL)))
      LOOP
         IF PNCMEXC <> '' OR PTIPI <> '' THEN
            VEXISTEEXCESSAO := EXISTE_EXCECAO(DADOS.SEQUENCIA, PNCMEXC, PTIPI);
         END IF;

         IF (DADOS.CODPROD > 0 AND PCODPROD > 0) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.NCM = SUBSTR( REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') ,1,LENGTH(DADOS.NCM)) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.CODNATREC IS NOT NULL AND VNATRECEITA = '999' THEN
            RETURN DADOS.CODNATREC;
         END IF;
      END LOOP;

      /*CONSULTA POR NCM*/
      FOR DADOS IN (SELECT T.SEQUENCIA,
                           T.TIPOREGISTRO,
                           T.TABELA,
                           T.CODNATREC,
                           REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') NCM,
                           T.DATAINIESCR,
                           T.DATAFINESCR,
                           T.CODPROD
                    FROM PCTABESCRSPED T
                    WHERE T.TIPOREGISTRO IN ('M4310','C4311','B4311','A4311','P4312')
                      AND REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') =
                          SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_',''),1,
              LENGTH(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')))
                      AND ((T.DATAINIESCR IS NULL AND T.DATAFINESCR IS NULL)
                       OR  (T.DATAINIESCR <= PDATA AND T.DATAFINESCR IS NULL)
                       OR  (PDATA BETWEEN T.DATAINIESCR AND T.DATAFINESCR AND T.DATAINIESCR IS NOT NULL AND T.DATAFINESCR IS NOT NULL))
                       AND T.CODPROD IS NULL
                   ORDER BY LENGTH(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')) DESC)
      LOOP
         IF PNCMEXC <> '' OR PTIPI <> '' THEN
            VEXISTEEXCESSAO := EXISTE_EXCECAO(DADOS.SEQUENCIA, PNCMEXC, PTIPI);
         END IF;

         IF (DADOS.CODPROD > 0 AND PCODPROD > 0) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.NCM = SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_',''),1,LENGTH(DADOS.NCM)) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.CODNATREC IS NOT NULL AND VNATRECEITA = '999' THEN
            RETURN DADOS.CODNATREC;
         END IF;
      END LOOP;

      IF VNATRECEITA = '999' THEN
        VNATRECEITA := RETORNANATPORNCM;
      END IF;
   ---------------------------------------------------------------------
   ---------------------------------------------------------------------
   -- Tabela 4.3.12 = P4312
   ELSIF PCST = 05 THEN
      /*CONSULTA POR PRODUTO*/
      FOR DADOS IN (SELECT T.SEQUENCIA,
                           T.TIPOREGISTRO,
                           T.TABELA,
                           T.CODNATREC,
                           REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') NCM,
                           T.DATAINIESCR,
                           T.DATAFINESCR,
                           T.CODPROD
                    FROM PCTABESCRSPED T
                    WHERE T.TIPOREGISTRO = 'P4312'
                      AND (T.CODPROD = PCODPROD OR PCODPROD = 0)
                      AND ((T.DATAINIESCR IS NULL AND T.DATAFINESCR IS NULL)
                       OR  (T.DATAINIESCR <= PDATA AND T.DATAFINESCR IS NULL)
                       OR  (PDATA BETWEEN T.DATAINIESCR AND T.DATAFINESCR AND T.DATAINIESCR IS NOT NULL AND T.DATAFINESCR IS NOT NULL)))
      LOOP
         IF PNCMEXC <> '' OR PTIPI <> '' THEN
            VEXISTEEXCESSAO := EXISTE_EXCECAO(DADOS.SEQUENCIA, PNCMEXC, PTIPI);
         END IF;

         IF (DADOS.CODPROD > 0 AND PCODPROD > 0) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.NCM = SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')
                           ,1,LENGTH(DADOS.NCM)) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.CODNATREC IS NOT NULL AND VNATRECEITA = '999' THEN
            RETURN DADOS.CODNATREC;
         END IF;
      END LOOP;

      /*CONSULTA POR NCM*/
      FOR DADOS IN (SELECT T.SEQUENCIA,
                           T.TIPOREGISTRO,
                           T.TABELA,
                           T.CODNATREC,
                           REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') NCM,
                           T.DATAINIESCR,
                           T.DATAFINESCR,
                           T.CODPROD
                    FROM PCTABESCRSPED T
                    WHERE T.TIPOREGISTRO = 'P4312'
                      AND REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') =
                          SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_',''),1,
              LENGTH(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')))
                      AND ((T.DATAINIESCR IS NULL AND T.DATAFINESCR IS NULL)
                       OR  (T.DATAINIESCR <= PDATA AND T.DATAFINESCR IS NULL)
                       OR  (PDATA BETWEEN T.DATAINIESCR AND T.DATAFINESCR AND T.DATAINIESCR IS NOT NULL AND T.DATAFINESCR IS NOT NULL))
                      AND T.CODPROD IS NULL
                      ORDER BY LENGTH(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')) DESC)
      LOOP
         IF PNCMEXC <> '' OR PTIPI <> '' THEN
            VEXISTEEXCESSAO := EXISTE_EXCECAO(DADOS.SEQUENCIA, PNCMEXC, PTIPI);
         END IF;

         IF (DADOS.CODPROD > 0 AND PCODPROD > 0) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.NCM = SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')
                                 ,1,LENGTH(DADOS.NCM)) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.CODNATREC IS NOT NULL AND VNATRECEITA = '999' THEN
            RETURN DADOS.CODNATREC;
         END IF;
      END LOOP;

      IF VNATRECEITA = '999' THEN
        VNATRECEITA := RETORNANATPORNCM;
      END IF;
   ---------------------------------------------------------------------
   ---------------------------------------------------------------------
   -- Tabela 4.3.13 = R4313
   ELSIF PCST = 06 THEN
      /*CONSULTA POR PRODUTO*/
      FOR DADOS IN (SELECT T.SEQUENCIA,      
                           T.TIPOREGISTRO,
                           T.TABELA,
                           T.CODNATREC,
                           REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') NCM,
                           T.DATAINIESCR,
                           T.DATAFINESCR,
                           T.CODPROD
                    FROM PCTABESCRSPED T
                    WHERE T.TIPOREGISTRO = 'R4313'
                      AND (T.CODPROD = PCODPROD OR PCODPROD = 0)
                      AND ((T.DATAINIESCR IS NULL AND T.DATAFINESCR IS NULL)
                       OR  (T.DATAINIESCR <= PDATA AND T.DATAFINESCR IS NULL)
                       OR  (PDATA BETWEEN T.DATAINIESCR AND T.DATAFINESCR AND T.DATAINIESCR IS NOT NULL AND T.DATAFINESCR IS NOT NULL)))
      LOOP
         IF PNCMEXC <> '' OR PTIPI <> '' THEN
            VEXISTEEXCESSAO := EXISTE_EXCECAO(DADOS.SEQUENCIA, PNCMEXC, PTIPI);
         END IF;

         IF (DADOS.CODPROD > 0 AND PCODPROD > 0) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.NCM = SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')
                                 ,1,LENGTH(DADOS.NCM)) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.CODNATREC IS NOT NULL AND VNATRECEITA = '999' THEN
            RETURN DADOS.CODNATREC;
         END IF;
      END LOOP;

      /*CONSULTA POR NCM*/
      FOR DADOS IN (SELECT T.SEQUENCIA,
                           T.TIPOREGISTRO,
                           T.TABELA,
                           T.CODNATREC,
                           REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') NCM,
                           T.DATAINIESCR,
                           T.DATAFINESCR,
                           T.CODPROD
                    FROM PCTABESCRSPED T
                    WHERE T.TIPOREGISTRO = 'R4313'
                      AND REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') =
                          SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_',''),1,
              LENGTH(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')))
                      AND ((T.DATAINIESCR IS NULL AND T.DATAFINESCR IS NULL)
                       OR  (T.DATAINIESCR <= PDATA AND T.DATAFINESCR IS NULL)
                       OR  (PDATA BETWEEN T.DATAINIESCR AND T.DATAFINESCR AND T.DATAINIESCR IS NOT NULL AND T.DATAFINESCR IS NOT NULL))
                      AND T.CODPROD IS NULL
                  ORDER BY LENGTH(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')) DESC)
      LOOP
         IF PNCMEXC <> '' OR PTIPI <> '' THEN
            VEXISTEEXCESSAO := EXISTE_EXCECAO(DADOS.SEQUENCIA, PNCMEXC, PTIPI);
         END IF;

         IF (DADOS.CODPROD > 0 AND PCODPROD > 0) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.NCM = SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')
                                 ,1,LENGTH(DADOS.NCM)) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.CODNATREC IS NOT NULL AND VNATRECEITA = '999' THEN
            RETURN DADOS.CODNATREC;
         END IF;
      END LOOP;

      IF VNATRECEITA = '999' THEN
        VNATRECEITA := RETORNANATPORNCM;
      END IF;
   ---------------------------------------------------------------------
   ---------------------------------------------------------------------
   -- Tabela 4.3.14 = I4314
   ELSIF PCST = 07 THEN
      /*CONSULTA POR PRODUTO*/
      FOR DADOS IN (SELECT T.SEQUENCIA,
                           T.TIPOREGISTRO,
                           T.TABELA,
                           T.CODNATREC,
                           REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') NCM,
                           T.DATAINIESCR,
                           T.DATAFINESCR,
                           T.CODPROD
                    FROM PCTABESCRSPED T
                    WHERE T.TIPOREGISTRO = 'I4314'
                      AND (T.CODPROD = PCODPROD OR PCODPROD = 0)
                      AND ((T.DATAINIESCR IS NULL AND T.DATAFINESCR IS NULL)
                       OR  (T.DATAINIESCR <= PDATA AND T.DATAFINESCR IS NULL)
                       OR  (PDATA BETWEEN T.DATAINIESCR AND T.DATAFINESCR AND T.DATAINIESCR IS NOT NULL AND T.DATAFINESCR IS NOT NULL)))
      LOOP
         IF PNCMEXC <> '' OR PTIPI <> '' THEN
            VEXISTEEXCESSAO := EXISTE_EXCECAO(DADOS.SEQUENCIA, PNCMEXC, PTIPI);
         END IF;

         IF (DADOS.CODPROD > 0 AND PCODPROD > 0) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.NCM = SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')
                                 ,1,LENGTH(DADOS.NCM)) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.CODNATREC IS NOT NULL AND VNATRECEITA = '999' THEN
            RETURN DADOS.CODNATREC;
         END IF;
      END LOOP;

      /*CONSULTA POR NCM*/
      FOR DADOS IN (SELECT T.SEQUENCIA,
                           T.TIPOREGISTRO,
                           T.DATAINIESCR,
                           T.TABELA,
                           T.CODNATREC,
                           REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') NCM,
                           T.DATAFINESCR,
                           T.CODPROD
                    FROM PCTABESCRSPED T
                    WHERE T.TIPOREGISTRO = 'I4314'
                      AND REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') =
                          SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_',''),1,
              LENGTH(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')))
                      AND ((T.DATAINIESCR IS NULL AND T.DATAFINESCR IS NULL)
                       OR  (T.DATAINIESCR <= PDATA AND T.DATAFINESCR IS NULL)
                       OR  (PDATA BETWEEN T.DATAINIESCR AND T.DATAFINESCR AND T.DATAINIESCR IS NOT NULL AND T.DATAFINESCR IS NOT NULL))
                      AND T.CODPROD IS NULL
                  ORDER BY LENGTH(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')) DESC)
      LOOP
         IF PNCMEXC <> '' OR PTIPI <> '' THEN
            VEXISTEEXCESSAO := EXISTE_EXCECAO(DADOS.SEQUENCIA, PNCMEXC, PTIPI);
         END IF;

         IF (DADOS.CODPROD > 0 AND PCODPROD > 0) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.NCM = SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')
                                  ,1,LENGTH(DADOS.NCM)) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.CODNATREC IS NOT NULL AND VNATRECEITA = '999' THEN
            RETURN DADOS.CODNATREC;
         END IF;
      END LOOP;
      IF VNATRECEITA = '999' THEN
        VNATRECEITA := RETORNANATPORNCM;
      END IF;
   ---------------------------------------------------------------------
   ---------------------------------------------------------------------
   -- Tabela 4.3.15 = I4315
   ELSIF PCST = 08 THEN
      /*CONSULTA POR PRODUTO*/
      FOR DADOS IN (SELECT T.SEQUENCIA,
                           T.TIPOREGISTRO,
                           T.TABELA,
                           T.CODNATREC,
                           REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') NCM,
                           T.DATAINIESCR,
                           T.DATAFINESCR,
                           T.CODPROD
                    FROM PCTABESCRSPED T
                    WHERE T.TIPOREGISTRO = 'I4315'
                      AND (T.CODPROD = PCODPROD OR PCODPROD = 0)
                      AND ((T.DATAINIESCR IS NULL AND T.DATAFINESCR IS NULL)
                       OR  (T.DATAINIESCR <= PDATA AND T.DATAFINESCR IS NULL)
                       OR  (PDATA BETWEEN T.DATAINIESCR AND T.DATAFINESCR AND T.DATAINIESCR IS NOT NULL AND T.DATAFINESCR IS NOT NULL)))
      LOOP
         IF PNCMEXC <> '' OR PTIPI <> '' THEN
            VEXISTEEXCESSAO := EXISTE_EXCECAO(DADOS.SEQUENCIA, PNCMEXC, PTIPI);
         END IF;

         IF (DADOS.CODPROD > 0 AND PCODPROD > 0) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.NCM = SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')
                                 ,1,LENGTH(DADOS.NCM)) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.CODNATREC IS NOT NULL AND VNATRECEITA = '999' THEN
            RETURN DADOS.CODNATREC;
         END IF;
      END LOOP;

      /*CONSULTA POR NCM*/
      FOR DADOS IN (SELECT T.SEQUENCIA,
                           T.TIPOREGISTRO,
                           T.TABELA,
                           T.CODNATREC,
                           REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') NCM,
                           T.DATAINIESCR,
                           T.DATAFINESCR,
                           T.CODPROD
                    FROM PCTABESCRSPED T
                    WHERE T.TIPOREGISTRO = 'I4315'
                      AND REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') =
                          SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_',''),1,
              LENGTH(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')))
                      AND ((T.DATAINIESCR IS NULL AND T.DATAFINESCR IS NULL)
                       OR  (T.DATAINIESCR <= PDATA AND T.DATAFINESCR IS NULL)
                       OR  (PDATA BETWEEN T.DATAINIESCR AND T.DATAFINESCR AND T.DATAINIESCR IS NOT NULL AND T.DATAFINESCR IS NOT NULL))
                      AND T.CODPROD IS NULL
                  ORDER BY LENGTH(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')) DESC)
      LOOP
         IF PNCMEXC <> '' OR PTIPI <> '' THEN
            VEXISTEEXCESSAO := EXISTE_EXCECAO(DADOS.SEQUENCIA, PNCMEXC, PTIPI);
         END IF;

         IF (DADOS.CODPROD > 0 AND PCODPROD > 0) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.NCM = SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')
                           ,1,LENGTH(DADOS.NCM)) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.CODNATREC IS NOT NULL AND VNATRECEITA = '999' THEN
             RETURN DADOS.CODNATREC;
         END IF;         
      END LOOP;      
      IF VNATRECEITA = '999' THEN
        VNATRECEITA := RETORNANATPORNCM;
       END IF;      
   ---------------------------------------------------------------------
   ---------------------------------------------------------------------
   -- Tabela 4.3.16 = S4316
   ELSIF PCST = 09 THEN
      /*CONSULTA POR PRODUTO*/
      FOR DADOS IN (SELECT T.SEQUENCIA,
                           T.TIPOREGISTRO,
                           T.TABELA,
                           T.CODNATREC,
                           REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') NCM,
                           T.DATAINIESCR,
                           T.DATAFINESCR,
                           T.CODPROD
                    FROM PCTABESCRSPED T
                    WHERE T.TIPOREGISTRO = 'S4316'
                      AND (T.CODPROD = PCODPROD OR PCODPROD = 0)
                      AND ((T.DATAINIESCR IS NULL AND T.DATAFINESCR IS NULL)
                       OR  (T.DATAINIESCR <= PDATA AND T.DATAFINESCR IS NULL)
                       OR  (PDATA BETWEEN T.DATAINIESCR AND T.DATAFINESCR AND T.DATAINIESCR IS NOT NULL AND T.DATAFINESCR IS NOT NULL)))
      LOOP
         IF PNCMEXC <> '' OR PTIPI <> '' THEN
            VEXISTEEXCESSAO := EXISTE_EXCECAO(DADOS.SEQUENCIA, PNCMEXC, PTIPI);
         END IF;

         IF (DADOS.CODPROD > 0 AND PCODPROD > 0) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.NCM = SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')
                                 ,1,LENGTH(DADOS.NCM)) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.CODNATREC IS NOT NULL AND VNATRECEITA = '999' THEN
            RETURN DADOS.CODNATREC;
         END IF;
      END LOOP;

      /*CONSULTA POR NCM*/
      FOR DADOS IN (SELECT T.SEQUENCIA,
                           T.TIPOREGISTRO,
                           T.TABELA,
                           T.CODNATREC,
                           REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') NCM,
                           T.DATAINIESCR,
                           T.DATAFINESCR,
                           T.CODPROD
                    FROM PCTABESCRSPED T
                    WHERE T.TIPOREGISTRO = 'S4316'
                      AND REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','') =
                          SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_',''),1,
              LENGTH(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')))
                      AND ((T.DATAINIESCR IS NULL AND T.DATAFINESCR IS NULL)
                       OR  (T.DATAINIESCR <= PDATA AND T.DATAFINESCR IS NULL)
                       OR  (PDATA BETWEEN T.DATAINIESCR AND T.DATAFINESCR AND T.DATAINIESCR IS NOT NULL AND T.DATAFINESCR IS NOT NULL))
                      AND T.CODPROD IS NULL
                  ORDER BY LENGTH(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( REPLACE(T.NCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')) DESC)
      LOOP
         IF PNCMEXC <> '' OR PTIPI <> '' THEN
            VEXISTEEXCESSAO := EXISTE_EXCECAO(DADOS.SEQUENCIA, PNCMEXC, PTIPI);
         END IF;

         IF (DADOS.CODPROD > 0 AND PCODPROD > 0) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.NCM = SUBSTR(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PNCM,' ',''),'.',''),',',''),'/',''),'-',''),'_','')
                                 ,1,LENGTH(DADOS.NCM)) AND VEXISTEEXCESSAO = 'N' THEN
            RETURN DADOS.CODNATREC;
         ELSIF DADOS.CODNATREC IS NOT NULL AND VNATRECEITA = '999' THEN
            RETURN DADOS.CODNATREC;
         END IF;
      END LOOP;
      IF VNATRECEITA = '999' THEN
        VNATRECEITA := RETORNANATPORNCM;
      END IF;
   END IF;
   ---------------------------------------------------------------------
   ---------------------------------------------------------------------
   -- Retornando o código da Natureza da Receita que foi encontrado ou gerando o padrão 999
   RETURN VNATRECEITA;
END;
-- Versão Develop
-- Última Alteração: 28/06/2021
