CREATE OR REPLACE PROCEDURE CRIAR_TABTRIB (
   pcodfilialnf IN VARCHAR2,
   pufdestino IN VARCHAR2,
   pcodepto IN VARCHAR2,
   pcodsec IN VARCHAR2,
   pcodprod IN VARCHAR2,
   pcodst IN VARCHAR2,
   pPCTABPR IN VARCHAR2,
   pmensagem OUT VARCHAR2)
/*******************************************************************************
                         Historico de Alteracoes
--------------------------------------------------------------------------------
 Data        Responsavel    Alteracao
 ----------  -------------  ----------------------------------------------------
 17/04/2007  Carolina       Tarefa 42159: passar a gravar o cod.st. (CODST) nas tabelas: PCTABTRIB e PCTABPR
 11/10/2005  Sabrina        Tarefa 22027: Gravar UF sempre em maiuscula
*******************************************************************************/
IS
   smensagem                     VARCHAR2 (100);
BEGIN
   SET TRANSACTION USE ROLLBACK SEGMENT rb_grande;

   -- Se estado de origem n?o estiver preenchido
   IF pcodfilialnf IS NULL
   THEN
      FOR c_pcfilial IN  (SELECT pcfilial.codigo
                          FROM   pcfilial)
      LOOP
         --Se estado de destino n?o estiver preenchido
         IF UPPER(pufdestino) IS NULL
         THEN
            FOR c_pcclient IN  (SELECT DISTINCT (UPPER(pcclient.estent)) estent
                                FROM            pcclient
                                WHERE           estent IS NOT NULL)
            LOOP
               -- N?o informou o produto
               IF (pcodprod IS NULL)
               THEN
                  --N?o informou o departamento
                  IF (pcodepto IS NULL)
                  THEN
                     --N?o informou a sec?o
                     IF (pcodsec IS NULL)
                     THEN
                        BEGIN
                          IF pcodst <> 0 and PPCTABPR = 'S' THEN
                             UPDATE Pctabpr
                                SET codst = pcodst
                              WHERE codprod IN (SELECT codprod 
                                                  FROM pcprodut
                                                 WHERE codprod NOT IN (SELECT codprod
                                                                         FROM  pctabtrib
                                                                        WHERE  codfilialnf =
                                                                          c_pcfilial.codigo
                                                                          AND  ufdestino = 
                                                                          UPPER(c_pcclient.estent)))
                      
                               AND numregiao IN (SELECT numregiao
                                                   FROM pcregiao
                                                  WHERE codfilial = c_pcfilial.codigo
                                                    AND uf = UPPER(c_pcclient.estent));
               
                           END IF;
                        
                           INSERT INTO pctabtrib
                                       (codst,
                                        codfilialnf,
                                        ufdestino,
                                        codprod)
                              (SELECT pcodst,
                                      c_pcfilial.codigo,
                                      UPPER(c_pcclient.estent),
                                      codprod
                               FROM   pcprodut
                               WHERE  codprod NOT IN
                                         (SELECT codprod
                                          FROM   pctabtrib
                                          WHERE  codfilialnf =
                                                            c_pcfilial.codigo
AND                                              ufdestino =
                                                            UPPER(c_pcclient.estent)));

                           smensagem :=
                              'Foram incluidos ' || SQL%ROWCOUNT || ' registros.';
                           COMMIT;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              smensagem := 'Nao foi incluido nenhum registro.';
                              ROLLBACK;
                        END;
                     ELSE --> Informou a sec?o
                        BEGIN
                          IF pcodst <> 0 and PPCTABPR = 'S' THEN
                             UPDATE Pctabpr
                                SET codst = pcodst
                              WHERE codprod IN (SELECT codprod 
                                                  FROM pcprodut
                                                 WHERE codsec = pcodsec
                                                   AND codprod NOT IN (SELECT codprod
                                                                         FROM  pctabtrib
                                                                        WHERE  codfilialnf =
                                                                          c_pcfilial.codigo
                                                                          AND  ufdestino = 
                                                                          UPPER(c_pcclient.estent)))
                      
                               AND numregiao IN (SELECT numregiao
                                                   FROM pcregiao
                                                  WHERE codfilial = c_pcfilial.codigo
                                                    AND uf = UPPER(c_pcclient.estent));
               
                           END IF;
                        
                           INSERT INTO pctabtrib
                                       (codst,
                                        codfilialnf,
                                        ufdestino,
                                        codprod)
                              (SELECT pcodst,
                                      c_pcfilial.codigo,
                                      UPPER(c_pcclient.estent),
                                      codprod
                               FROM   pcprodut
                               WHERE  codsec = pcodsec
AND                                   codprod NOT IN
                                         (SELECT codprod
                                          FROM   pctabtrib
                                          WHERE  codfilialnf =
                                                            c_pcfilial.codigo
AND                                              ufdestino =
                                                            UPPER(c_pcclient.estent)));

                           smensagem :=
                              'Foram incluidos ' || SQL%ROWCOUNT || ' registros.';
                           COMMIT;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              smensagem := 'Nao foi incluido nenhum registro.';
                              ROLLBACK;
                        END;
                     END IF; --> fim informou sec?o
                  ELSE --> Informou o departamento
                     --N?o informou a sec?o
                     IF (pcodsec IS NULL)
                     THEN
                        BEGIN
                          IF pcodst <> 0 and PPCTABPR = 'S' THEN
                             UPDATE Pctabpr
                                SET codst = pcodst
                              WHERE codprod IN (SELECT codprod 
                                                  FROM pcprodut
                                                 WHERE codepto = pcodepto
                                                   AND codprod NOT IN (SELECT codprod
                                                                         FROM  pctabtrib
                                                                        WHERE  codfilialnf =
                                                                          c_pcfilial.codigo
                                                                          AND  ufdestino = 
                                                                          UPPER(c_pcclient.estent)))
                      
                               AND numregiao IN (SELECT numregiao
                                                   FROM pcregiao
                                                  WHERE codfilial = c_pcfilial.codigo
                                                    AND uf = UPPER(c_pcclient.estent));
               
                           END IF;
                        
                           INSERT INTO pctabtrib
                                       (codst,
                                        codfilialnf,
                                        ufdestino,
                                        codprod)
                              (SELECT pcodst,
                                      c_pcfilial.codigo,
                                      UPPER(c_pcclient.estent),
                                      codprod
                               FROM   pcprodut
                               WHERE  codepto = pcodepto
AND                                   codprod NOT IN
                                         (SELECT codprod
                                          FROM   pctabtrib
                                          WHERE  codfilialnf =
                                                            c_pcfilial.codigo
AND                                              ufdestino =
                                                            UPPER(c_pcclient.estent)));

                           smensagem :=
                              'Foram incluidos ' || SQL%ROWCOUNT || ' registros.';
                           COMMIT;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              smensagem := 'Nao foi incluido nenhum registro.';
                              ROLLBACK;
                        END;
                     ELSE --> Informou a sec?o
                        BEGIN
                       IF pcodst <> 0 and PPCTABPR = 'S' THEN
                          UPDATE Pctabpr
                             SET codst = pcodst
                           WHERE codprod IN (SELECT codprod 
                                               FROM pcprodut
                                              WHERE codepto = pcodepto
                                                AND codsec = pcodsec
                                                AND codprod NOT IN (SELECT codprod
                                                                      FROM  pctabtrib
                                                                     WHERE  codfilialnf =
                                                                       c_pcfilial.codigo
                                                                       AND  ufdestino = 
                                                                       UPPER(c_pcclient.estent)))
                      
                            AND numregiao IN (SELECT numregiao
                                                FROM pcregiao
                                               WHERE codfilial = c_pcfilial.codigo
                                                 AND uf = UPPER(c_pcclient.estent));
            
                        END IF;
                        
                           INSERT INTO pctabtrib
                                       (codst,
                                        codfilialnf,
                                        ufdestino,
                                        codprod)
                              (SELECT pcodst,
                                      c_pcfilial.codigo,
                                      UPPER(c_pcclient.estent),
                                      codprod
                               FROM   pcprodut
                               WHERE  codepto = pcodepto
AND                                   codsec = pcodsec
AND                                   codprod NOT IN
                                         (SELECT codprod
                                          FROM   pctabtrib
                                          WHERE  codfilialnf =
                                                            c_pcfilial.codigo
AND                                              ufdestino =
                                                            UPPER(c_pcclient.estent)));

                           smensagem :=
                              'Foram incluidos ' || SQL%ROWCOUNT || ' registros.';
                           COMMIT;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              smensagem := 'Nao foi incluido nenhum registro.';
                              ROLLBACK;
                        END;
                     END IF; --> fim informou sec?o
                  END IF; -->fim informou departamento
               -- Informou o produto
               ELSE
                  BEGIN
                    IF pcodst <> 0 and PPCTABPR = 'S' THEN
                       UPDATE Pctabpr
                          SET codst = pcodst
                        WHERE codprod = pcodprod
                          AND numregiao IN (SELECT numregiao
                                               FROM pcregiao
                                              WHERE codfilial = c_pcfilial.codigo
                                                AND uf = UPPER(c_pcclient.estent));
            
                     END IF;
                  
                     INSERT INTO pctabtrib
                                 (codst,
                                  codfilialnf,
                                  ufdestino,
                                  codprod)
                     VALUES      (pcodst,
                                  c_pcfilial.codigo,
                                  UPPER(c_pcclient.estent),
                                  pcodprod);

                     smensagem :=
                              'Foram incluidos ' || SQL%ROWCOUNT || ' registros.';
                     COMMIT;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        smensagem := 'Nao foi incluido nenhum registro.';
                        ROLLBACK;
                  END;
               END IF; --> Informou o produto
            END LOOP; --> Estados de Destino
         ELSE ---> Se estado de destino estiver preenchido
            -- N?o informou o produto
            IF (pcodprod IS NULL)
            THEN
               --N?o informou o departamento
               IF (pcodepto IS NULL)
               THEN
                  --N?o informou a sec?o
                  IF (pcodsec IS NULL)
                  THEN
                     BEGIN
                       IF pcodst <> 0 and PPCTABPR = 'S' THEN
                          UPDATE Pctabpr
                             SET codst = pcodst
                           WHERE codprod IN (SELECT codprod 
                                               FROM pcprodut
                                              WHERE codprod NOT IN (SELECT codprod
                                                                      FROM  pctabtrib
                                                                     WHERE  codfilialnf =
                                                                       c_pcfilial.codigo
                                                                       AND  ufdestino = 
                                                                       UPPER(pufdestino)))
                      
                            AND numregiao IN (SELECT numregiao
                                                FROM pcregiao
                                               WHERE codfilial = c_pcfilial.codigo
                                                 AND uf = UPPER(pufdestino));
            
                        END IF;
                     
                        INSERT INTO pctabtrib
                                    (codst,
                                     codfilialnf,
                                     ufdestino,
                                     codprod)
                           (SELECT pcodst,
                                   c_pcfilial.codigo,
                                   UPPER(pufdestino),
                                   codprod
                            FROM   pcprodut
                            WHERE  codprod NOT IN
                                      (SELECT codprod
                                       FROM   pctabtrib
                                       WHERE  codfilialnf = c_pcfilial.codigo
AND                                           ufdestino = UPPER(pufdestino)));

                        smensagem :=
                              'Foram incluidos ' || SQL%ROWCOUNT || ' registros.';
                        COMMIT;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           smensagem := 'Nao foi incluido nenhum registro.';
                           ROLLBACK;
                     END;
                  ELSE --> Informou a sec?o
                     BEGIN
                       IF pcodst <> 0 and PPCTABPR = 'S' THEN
                          UPDATE Pctabpr
                             SET codst = pcodst
                           WHERE codprod IN (SELECT codprod 
                                               FROM pcprodut
                                              WHERE codsec = pcodsec
                                                AND codprod NOT IN (SELECT codprod
                                                                      FROM  pctabtrib
                                                                     WHERE  codfilialnf =
                                                                       c_pcfilial.codigo
                                                                       AND  ufdestino = 
                                                                       UPPER(pufdestino)))
                      
                            AND numregiao IN (SELECT numregiao
                                                FROM pcregiao
                                               WHERE codfilial = c_pcfilial.codigo
                                                 AND uf = UPPER(pufdestino));
            
                        END IF;
                     
                        INSERT INTO pctabtrib
                                    (codst,
                                     codfilialnf,
                                     ufdestino,
                                     codprod)
                           (SELECT pcodst,
                                   c_pcfilial.codigo,
                                   UPPER(pufdestino),
                                   codprod
                            FROM   pcprodut
                            WHERE  codsec = pcodsec
AND                                codprod NOT IN
                                      (SELECT codprod
                                       FROM   pctabtrib
                                       WHERE  codfilialnf = c_pcfilial.codigo
AND                                           ufdestino = UPPER(pufdestino)));

                        smensagem :=
                              'Foram incluidos ' || SQL%ROWCOUNT || ' registros.';
                        COMMIT;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           smensagem := 'Nao foi incluido nenhum registro.';
                           ROLLBACK;
                     END;
                  END IF; --> fim informou sec?o
               ELSE --> Informou o departamento
                  --N?o informou a sec?o
                  IF (pcodsec IS NULL)
                  THEN
                     BEGIN
                       IF pcodst <> 0 and PPCTABPR = 'S' THEN
                          UPDATE Pctabpr
                             SET codst = pcodst
                           WHERE codprod IN (SELECT codprod 
                                               FROM pcprodut
                                              WHERE codepto = pcodepto
                                                AND codprod NOT IN (SELECT codprod
                                                                      FROM  pctabtrib
                                                                     WHERE  codfilialnf =
                                                                       c_pcfilial.codigo
                                                                       AND  ufdestino = 
                                                                       UPPER(pufdestino)))
                      
                            AND numregiao IN (SELECT numregiao
                                                FROM pcregiao
                                               WHERE codfilial = c_pcfilial.codigo
                                                 AND uf = UPPER(pufdestino));
            
                        END IF;
                     
                        INSERT INTO pctabtrib
                                    (codst,
                                     codfilialnf,
                                     ufdestino,
                                     codprod)
                           (SELECT pcodst,
                                   c_pcfilial.codigo,
                                   UPPER(pufdestino),
                                   codprod
                            FROM   pcprodut
                            WHERE  codepto = pcodepto
AND                                codprod NOT IN
                                      (SELECT codprod
                                       FROM   pctabtrib
                                       WHERE  codfilialnf = c_pcfilial.codigo
AND                                           ufdestino = UPPER(pufdestino)));

                        smensagem :=
                              'Foram incluidos ' || SQL%ROWCOUNT || ' registros.';
                        COMMIT;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           smensagem := 'Nao foi incluido nenhum registro.';
                           ROLLBACK;
                     END;
                  ELSE --> Informou a sec?o
                     BEGIN
                       IF pcodst <> 0 and PPCTABPR = 'S' THEN
                          UPDATE Pctabpr
                             SET codst = pcodst
                           WHERE codprod IN (SELECT codprod 
                                               FROM pcprodut
                                              WHERE codepto = pcodepto
                                                AND codsec = pcodsec
                                                AND codprod NOT IN (SELECT codprod
                                                                      FROM  pctabtrib
                                                                     WHERE  codfilialnf =
                                                                       c_pcfilial.codigo
                                                                       AND  ufdestino = 
                                                                       UPPER(pufdestino)))
                      
                            AND numregiao IN (SELECT numregiao
                                                FROM pcregiao
                                               WHERE codfilial = c_pcfilial.codigo
                                                 AND uf = UPPER(pufdestino));
            
                        END IF;
                     
                        INSERT INTO pctabtrib
                                    (codst,
                                     codfilialnf,
                                     ufdestino,
                                     codprod)
                           (SELECT pcodst,
                                   c_pcfilial.codigo,
                                   UPPER(pufdestino),
                                   codprod
                            FROM   pcprodut
                            WHERE  codepto = pcodepto
AND                                codsec = pcodsec
AND                                codprod NOT IN
                                      (SELECT codprod
                                       FROM   pctabtrib
                                       WHERE  codfilialnf = c_pcfilial.codigo
AND                                           ufdestino = UPPER(pufdestino)));

                        smensagem :=
                              'Foram incluidos ' || SQL%ROWCOUNT || ' registros.';
                        COMMIT;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           smensagem := 'Nao foi incluido nenhum registro.';
                           ROLLBACK;
                     END;
                  END IF; --> fim informou sec?o
               END IF; -->fim informou departamento
            -- Informou o produto
            ELSE
               BEGIN
                 IF pcodst <> 0 and PPCTABPR = 'S' THEN
                    UPDATE Pctabpr
                       SET codst = pcodst
                     WHERE codprod = pcodprod
                       AND numregiao IN (SELECT numregiao
                                           FROM pcregiao
                                          WHERE codfilial = c_pcfilial.codigo
                                            AND uf = UPPER(pufdestino));
            
                 END IF;
               
                  INSERT INTO pctabtrib
                              (codst,
                               codfilialnf,
                               ufdestino,
                               codprod)
                  VALUES      (pcodst,
                               c_pcfilial.codigo,
                               UPPER(pufdestino),
                               pcodprod);

                  smensagem :=
                              'Foram incluidos ' || SQL%ROWCOUNT || ' registros.';
                  COMMIT;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     smensagem := 'Nao foi incluido nenhum registro.';
                     ROLLBACK;
               END;
            END IF; --> Informou o produto
         END IF; --> Estado de Destino
      END LOOP; --> Estados de Origem
   ELSE --> Se estado de origem estiver preenchido
        --Se estado de destino n?o estiver preenchido
      IF pufdestino IS NULL
      THEN
         FOR c_pcclient IN  (SELECT DISTINCT (UPPER(pcclient.estent)) estent
                             FROM            pcclient
                             WHERE           estent IS NOT NULL)
         LOOP
            -- N?o informou o produto
            IF (pcodprod IS NULL)
            THEN
               --N?o informou o departamento
               IF (pcodepto IS NULL)
               THEN
                  --N?o informou a sec?o
                  IF (pcodsec IS NULL)
                  THEN
                     BEGIN
                       IF pcodst <> 0 and PPCTABPR = 'S' THEN
                          UPDATE Pctabpr
                             SET codst = pcodst
                           WHERE codprod IN (SELECT codprod 
                                               FROM pcprodut
                                              WHERE codprod NOT IN (SELECT codprod
                                                                      FROM  pctabtrib
                                                                     WHERE  codfilialnf =
                                                                       pcodfilialnf
                                                                       AND  ufdestino = 
                                                                       UPPER(c_pcclient.estent)))
                      
                            AND numregiao IN (SELECT numregiao
                                                FROM pcregiao
                                               WHERE codfilial = pcodfilialnf
                                                 AND uf = UPPER(c_pcclient.estent));
            
                        END IF;
                     
                        INSERT INTO pctabtrib
                                    (codst,
                                     codfilialnf,
                                     ufdestino,
                                     codprod)
                           (SELECT pcodst,
                                   pcodfilialnf,
                                   UPPER(c_pcclient.estent),
                                   codprod
                            FROM   pcprodut
                            WHERE  codprod NOT IN
                                      (SELECT codprod
                                       FROM   pctabtrib
                                       WHERE  codfilialnf = pcodfilialnf
AND                                           ufdestino = UPPER(c_pcclient.estent)));

                        smensagem :=
                              'Foram incluidos ' || SQL%ROWCOUNT || ' registros.';
                        COMMIT;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           smensagem := 'Nao foi incluido nenhum registro.';
                           ROLLBACK;
                     END;
                  ELSE --> Informou a sec?o
                     BEGIN
                       IF pcodst <> 0 and PPCTABPR = 'S' THEN
                          UPDATE Pctabpr
                             SET codst = pcodst
                           WHERE codprod IN (SELECT codprod 
                                               FROM pcprodut
                                              WHERE codsec = pcodsec
                                                AND codprod NOT IN (SELECT codprod
                                                                      FROM  pctabtrib
                                                                     WHERE  codfilialnf =
                                                                       pcodfilialnf
                                                                       AND  ufdestino = 
                                                                       UPPER(c_pcclient.estent)))
                      
                            AND numregiao IN (SELECT numregiao
                                                FROM pcregiao
                                               WHERE codfilial = pcodfilialnf
                                                 AND uf = UPPER(c_pcclient.estent));
            
                        END IF;

                        INSERT INTO pctabtrib
                                    (codst,
                                     codfilialnf,
                                     ufdestino,
                                     codprod)
                           (SELECT pcodst,
                                   pcodfilialnf,
                                   UPPER(c_pcclient.estent),
                                   codprod
                            FROM   pcprodut
                            WHERE  codsec = pcodsec
AND                                codprod NOT IN
                                      (SELECT codprod
                                       FROM   pctabtrib
                                       WHERE  codfilialnf = pcodfilialnf
AND                                           ufdestino = UPPER(c_pcclient.estent)));

                        smensagem :=
                              'Foram incluidos ' || SQL%ROWCOUNT || ' registros.';
                        COMMIT;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           smensagem := 'Nao foi incluido nenhum registro.';
                           ROLLBACK;
                     END;
                  END IF; --> fim informou sec?o
               ELSE --> Informou o departamento
                  --N?o informou a sec?o
                  IF (pcodsec IS NULL)
                  THEN
                     BEGIN
                       IF pcodst <> 0 and PPCTABPR = 'S' THEN
                          UPDATE Pctabpr
                             SET codst = pcodst
                           WHERE codprod IN (SELECT codprod 
                                               FROM pcprodut
                                              WHERE codepto = pcodepto
                                                AND codprod NOT IN (SELECT codprod
                                                                      FROM  pctabtrib
                                                                     WHERE  codfilialnf =
                                                                       pcodfilialnf
                                                                       AND  ufdestino = 
                                                                       UPPER(c_pcclient.estent)))
                      
                            AND numregiao IN (SELECT numregiao
                                                FROM pcregiao
                                               WHERE codfilial = pcodfilialnf
                                                 AND uf = UPPER(c_pcclient.estent));
            
                        END IF;
                     
                        INSERT INTO pctabtrib
                                    (codst,
                                     codfilialnf,
                                     ufdestino,
                                     codprod)
                           (SELECT pcodst,
                                   pcodfilialnf,
                                   UPPER(c_pcclient.estent),
                                   codprod
                            FROM   pcprodut
                            WHERE  codepto = pcodepto
AND                                codprod NOT IN
                                      (SELECT codprod
                                       FROM   pctabtrib
                                       WHERE  codfilialnf = pcodfilialnf
AND                                           ufdestino = UPPER(c_pcclient.estent)));

                        smensagem :=
                              'Foram incluidos ' || SQL%ROWCOUNT || ' registros.';
                        COMMIT;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           smensagem := 'Nao foi incluido nenhum registro.';
                           ROLLBACK;
                     END;
                  ELSE --> Informou a sec?o
                     BEGIN
                       IF pcodst <> 0 and PPCTABPR = 'S' THEN
                          UPDATE Pctabpr
                             SET codst = pcodst
                           WHERE codprod IN (SELECT codprod 
                                               FROM pcprodut
                                              WHERE codepto = pcodepto
                                                AND codsec = pcodsec
                                                AND codprod NOT IN (SELECT codprod
                                                                      FROM  pctabtrib
                                                                     WHERE  codfilialnf =
                                                                       pcodfilialnf
                                                                       AND  ufdestino = 
                                                                       UPPER(c_pcclient.estent)))
                      
                            AND numregiao IN (SELECT numregiao
                                                FROM pcregiao
                                               WHERE codfilial = pcodfilialnf
                                                 AND uf = UPPER(c_pcclient.estent));
            
                        END IF;
                     
                        INSERT INTO pctabtrib
                                    (codst,
                                     codfilialnf,
                                     ufdestino,
                                     codprod)
                           (SELECT pcodst,
                                   pcodfilialnf,
                                   UPPER(c_pcclient.estent),
                                   codprod
                            FROM   pcprodut
                            WHERE  codepto = pcodepto
AND                                codsec = pcodsec
AND                                codprod NOT IN
                                      (SELECT codprod
                                       FROM   pctabtrib
                                       WHERE  codfilialnf = pcodfilialnf
AND                                           ufdestino = UPPER(c_pcclient.estent)));

                        smensagem :=
                              'Foram incluidos ' || SQL%ROWCOUNT || ' registros.';
                        COMMIT;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           smensagem := 'Nao foi incluido nenhum registro.';
                           ROLLBACK;
                     END;
                  END IF; --> fim informou sec?o
               END IF; -->fim informou departamento
            -- Informou o produto
            ELSE
               BEGIN
                  INSERT INTO pctabtrib
                              (codst,
                               codfilialnf,
                               ufdestino,
                               codprod)
                  VALUES      (pcodst,
                               pcodfilialnf,
                               UPPER(c_pcclient.estent),
                               pcodprod);

                  smensagem :=
                              'Foram incluidos ' || SQL%ROWCOUNT || ' registros.';
                  COMMIT;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     smensagem := 'Nao foi incluido nenhum registro.';
                     ROLLBACK;
               END;
            END IF; --> Informou o produto
         END LOOP; --> Estados de Destino
      ELSE ---> Se estado de destino estiver preenchido
         -- N?o informou o produto
         IF (pcodprod IS NULL)
         THEN
            --N?o informou o departamento
            IF (pcodepto IS NULL)
            THEN
               --N?o informou a sec?o
               IF (pcodsec IS NULL)
               THEN
                  BEGIN
                    IF pcodst <> 0 and PPCTABPR = 'S' THEN
                      UPDATE Pctabpr
                        SET codst = pcodst
                      WHERE codprod IN (SELECT codprod 
                                          FROM pcprodut
                                         WHERE codprod NOT IN (SELECT codprod
                                                                 FROM  pctabtrib
                                                                WHERE  codfilialnf =
                                                                 pcodfilialnf
                                                                  AND  ufdestino = UPPER(pufdestino)))
                      
                        AND numregiao IN (SELECT numregiao
                                            FROM pcregiao
                                           WHERE codfilial = pcodfilialnf
                                             AND uf = UPPER(pufdestino));
            
                     END IF;
                  
                     INSERT INTO pctabtrib
                                 (codst,
                                  codfilialnf,
                                  ufdestino,
                                  codprod)
                        (SELECT pcodst,
                                pcodfilialnf,
                                UPPER(pufdestino),
                                codprod
                         FROM   pcprodut
                         WHERE  codprod NOT IN (SELECT codprod
                                                FROM   pctabtrib
                                                WHERE  codfilialnf =
                                                                 pcodfilialnf
AND                                                    ufdestino = UPPER(pufdestino)));

                     smensagem :=
                              'Foram incluidos ' || SQL%ROWCOUNT || ' registros.';
                     COMMIT;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        smensagem := 'Nao foi incluido nenhum registro.';
                        ROLLBACK;
                  END;
               ELSE --> Informou a sec?o
                  BEGIN
                    IF pcodst <> 0 and PPCTABPR = 'S' THEN
                      UPDATE Pctabpr
                        SET codst = pcodst
                      WHERE codprod IN (SELECT codprod 
                                          FROM pcprodut
                                         WHERE codsec = pcodsec
                                           AND codprod NOT IN (SELECT codprod
                                                                 FROM  pctabtrib
                                                                WHERE  codfilialnf =
                                                                 pcodfilialnf
                                                                  AND  ufdestino = UPPER(pufdestino)))
                      
                        AND numregiao IN (SELECT numregiao
                                            FROM pcregiao
                                           WHERE codfilial = pcodfilialnf
                                             AND uf = UPPER(pufdestino));
            
                     END IF;
                  
                     INSERT INTO pctabtrib
                                 (codst,
                                  codfilialnf,
                                  ufdestino,
                                  codprod)
                        (SELECT pcodst,
                                pcodfilialnf,
                                UPPER(pufdestino),
                                codprod
                         FROM   pcprodut
                         WHERE  codsec = pcodsec
AND                             codprod NOT IN (SELECT codprod
                                                FROM   pctabtrib
                                                WHERE  codfilialnf =
                                                                 pcodfilialnf
AND                                                    ufdestino = UPPER(pufdestino)));

                     smensagem :=
                              'Foram incluidos ' || SQL%ROWCOUNT || ' registros.';
                     COMMIT;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        smensagem := 'Nao foi incluido nenhum registro.';
                        ROLLBACK;
                  END;
               END IF; --> fim informou sec?o
            ELSE --> Informou o departamento
               --N?o informou a sec?o
               IF (pcodsec IS NULL)
               THEN
                  BEGIN
                    IF pcodst <> 0 and PPCTABPR = 'S' THEN
                      UPDATE Pctabpr
                        SET codst = pcodst
                      WHERE codprod IN (SELECT codprod 
                                          FROM pcprodut
                                         WHERE codepto = pcodepto
                                           AND codprod NOT IN (SELECT codprod
                                                                 FROM  pctabtrib
                                                                WHERE  codfilialnf =
                                                                 pcodfilialnf
                                                                  AND  ufdestino = UPPER(pufdestino)))
                      
                        AND numregiao IN (SELECT numregiao
                                            FROM pcregiao
                                           WHERE codfilial = pcodfilialnf
                                             AND uf = UPPER(pufdestino));
            
                     END IF;
                  
                     INSERT INTO pctabtrib
                                 (codst,
                                  codfilialnf,
                                  ufdestino,
                                  codprod)
                        (SELECT pcodst,
                                pcodfilialnf,
                                UPPER(pufdestino),
                                codprod
                         FROM   pcprodut
                         WHERE  codepto = pcodepto
AND                             codprod NOT IN (SELECT codprod
                                                FROM   pctabtrib
                                                WHERE  codfilialnf =
                                                                 pcodfilialnf
AND                                                    ufdestino = UPPER(pufdestino)));

                     smensagem :=
                              'Foram incluidos ' || SQL%ROWCOUNT || ' registros.';
                     COMMIT;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        smensagem := 'Nao foi incluido nenhum registro.';
                        ROLLBACK;
                  END;
               ELSE --> Informou a sec?o
                  BEGIN
                    IF pcodst <> 0 and PPCTABPR = 'S' THEN
                      UPDATE Pctabpr
                        SET codst = pcodst
                      WHERE codprod IN (SELECT codprod 
                                          FROM pcprodut
                                         WHERE codepto = pcodepto
                                           AND codsec = pcodsec
                                           AND codprod NOT IN (SELECT codprod
                                                                 FROM  pctabtrib
                                                                WHERE  codfilialnf =
                                                                 pcodfilialnf
                                                                  AND  ufdestino = UPPER(pufdestino)))
                      
                        AND numregiao IN (SELECT numregiao
                                            FROM pcregiao
                                           WHERE codfilial = pcodfilialnf
                                             AND uf = UPPER(pufdestino));
            
                     END IF;
                  
                     INSERT INTO pctabtrib
                                 (codst,
                                  codfilialnf,
                                  ufdestino,
                                  codprod)
                        (SELECT pcodst,
                                pcodfilialnf,
                                UPPER(pufdestino),
                                codprod
                         FROM   pcprodut
                         WHERE  codepto = pcodepto
AND                             codsec = pcodsec
AND                             codprod NOT IN (SELECT codprod
                                                FROM   pctabtrib
                                                WHERE  codfilialnf =
                                                                 pcodfilialnf
AND                                                    ufdestino = UPPER(pufdestino)));

                     smensagem :=
                              'Foram incluidos ' || SQL%ROWCOUNT || ' registros.';
                     COMMIT;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        smensagem := 'Nao foi incluido nenhum registro.';
                        ROLLBACK;
                  END;
               END IF; --> fim informou sec?o
            END IF; -->fim informou departamento
         -- Informou o produto
         ELSE
            BEGIN
            IF pcodst <> 0 and PPCTABPR = 'S' THEN
                     UPDATE Pctabpr
                        SET codst = pcodst
                      WHERE codprod = pcodprod
                        AND numregiao IN (SELECT numregiao
                                            FROM pcregiao
                                           WHERE codfilial = pcodfilialnf
                                             AND uf = UPPER(pufdestino));
            
            END IF;
            
               INSERT INTO pctabtrib
                           (codst,
                            codfilialnf,
                            ufdestino,
                            codprod)
               VALUES      (pcodst,
                            pcodfilialnf,
                            UPPER(pufdestino),
                            pcodprod);

               smensagem := 'Foram incluidos ' || SQL%ROWCOUNT || ' registros.';
               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  smensagem := 'Nao foi incluido nenhum registro.';
                  ROLLBACK;
            END;
         END IF; --> Informou o produto
      END IF; --> Estado de Destino
   END IF; --> Estado de Origem

   pmensagem := smensagem;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
END; -- Procedure

/
EXIT
/
