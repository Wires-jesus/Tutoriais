CREATE OR REPLACE TRIGGER TRG_ECOMMERCE_PCPEDC 
BEFORE
   DELETE OR UPDATE OF POSICAO, CHAVENFE, NUMCAR ON PCPEDC
   REFERENCING NEW AS NEW OLD AS OLD FOR EACH ROW
DECLARE
   vnQTDEPEDIDO NUMBER;
   vnEXISTENAFILA NUMBER;
   vsPOSICAOOUTROPEDIDO VARCHAR2(1);
BEGIN
   IF (:OLD.NUMPEDRCA IS NOT NULL) AND (:OLD.INTEGRADORA = 29) THEN
      --Enviar sempre o limite de crédito também
      BEGIN
         FOR DADOS IN (SELECT DISTINCT
                              PCECOMMERCEUNILEVERCLIENTE.CODFILIAL,
                              'SELECTLIMITE' TABELA,
                              PCCLIENT.ROWID ID
                       FROM PCECOMMERCEUNILEVERCLIENTE,
                            PCCLIENT
                       WHERE PCCLIENT.CODCLI = NVL(:OLD.CODCLI,:NEW.CODCLI)
                         AND PCECOMMERCEUNILEVERCLIENTE.CODCLI = PCCLIENT.CODCLI
                         AND NVL(PCCLIENT.SITUACAOECOMMERCEUNILEVER,'NAO') <> 'NAO')
         LOOP
            BEGIN
               INSERT INTO PCECOMMERCEUNILEVERFILA (CODFILIAL, TABELA, ID, DTINCLUSAO)
               VALUES (DADOS.CODFILIAL, DADOS.TABELA, DADOS.ID , SYSDATE);
            EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
               NULL;
            END;
         END LOOP;
      EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
         NULL;
      END;
      --Verificar se existe esse pedido na fila
      BEGIN
         SELECT COUNT(1)
         INTO vnEXISTENAFILA
         FROM PCECOMMERCEUNILEVERFILA
         WHERE PCECOMMERCEUNILEVERFILA.ID = (SELECT PCPEDCTEMP.ROWID
                                             FROM PCPEDCTEMP
                                             WHERE PCPEDCTEMP.NUMPEDRCA = :OLD.NUMPEDRCA
                                               AND PCPEDCTEMP.INTEGRADORA = 29
                                               AND ROWNUM = 1);
      EXCEPTION WHEN NO_DATA_FOUND THEN
         vnEXISTENAFILA := 0;
      END;

      IF DELETING THEN
         IF vnEXISTENAFILA = 0 THEN
            FOR DADOS IN (SELECT DISTINCT
                                 NVL(PCPEDCTEMP.SERIEMANIF,PCPEDCTEMP.CODFILIAL) CODFILIAL,
                                 'SELECTPEDIDO' TABELA,
                                 PCPEDCTEMP.ROWID ID
                          FROM PCPEDCTEMP
                          WHERE PCPEDCTEMP.NUMPEDRCA = :OLD.NUMPEDRCA
                            AND PCPEDCTEMP.INTEGRADORA = 29
                            AND NVL(PCPEDCTEMP.NUMPED,0) > 0
                            AND PCPEDCTEMP.NUMPED = :OLD.NUMPED
                            AND ROWNUM = 1)
            LOOP
               BEGIN
                  --Campo SerieManif grava o código da filial utilizada pelo e-commerce
                  INSERT INTO PCECOMMERCEUNILEVERFILA (CODFILIAL, TABELA, ID, DTINCLUSAO)
                  VALUES (DADOS.CODFILIAL, DADOS.TABELA, DADOS.ID, SYSDATE);
               EXCEPTION WHEN OTHERS THEN
                  NULL;
               END;
            END LOOP;
         END IF;
      ELSE
         BEGIN
            --Verificar se existe mais de um pedido para o pedido do E-Commerce
            BEGIN
               SELECT COUNT(1)
               INTO vnQTDEPEDIDO
               FROM PCPEDCTEMP
               WHERE PCPEDCTEMP.NUMPEDRCA = :OLD.NUMPEDRCA
                 AND PCPEDCTEMP.NUMPED > 0;
            EXCEPTION WHEN NO_DATA_FOUND THEN
               vnQTDEPEDIDO := 0;
            END;

            IF vnQTDEPEDIDO = 1 THEN --Inserir na fila quando for apenas um pedido
               IF vnEXISTENAFILA = 0 THEN
                  BEGIN
                     FOR DADOS IN (SELECT DISTINCT
                                          NVL(PCPEDCTEMP.SERIEMANIF,PCPEDCTEMP.CODFILIAL) CODFILIAL,
                                          'SELECTPEDIDO' TABELA,
                                          PCPEDCTEMP.ROWID ID
                                   FROM PCPEDCTEMP
                                   WHERE PCPEDCTEMP.NUMPEDRCA = :OLD.NUMPEDRCA
                                     AND PCPEDCTEMP.NUMPED > 0
                                     AND PCPEDCTEMP.INTEGRADORA = 29)
                     LOOP
                        BEGIN
                           --Campo SerieManif grava o código da filial utilizada pelo e-commerce
                           INSERT INTO PCECOMMERCEUNILEVERFILA (CODFILIAL, TABELA, ID, DTINCLUSAO)
                           VALUES (DADOS.CODFILIAL, DADOS.TABELA, DADOS.ID, SYSDATE);
                        EXCEPTION WHEN OTHERS THEN
                           NULL;
                        END;
                     END LOOP;
                  EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
                     NULL;
                  END;
               END IF;
            ELSE
               BEGIN 
                  --Caso seja mais de um pedido, analisar a posição do segundo
                  SELECT POSICAO
                  INTO vsPOSICAOOUTROPEDIDO
                  FROM PCPEDC
                  WHERE PCPEDC.DTCANCEL IS NULL
                    AND PCPEDC.NUMPEDRCA = :OLD.NUMPEDRCA
                    AND PCPEDC.NUMPED <> :OLD.NUMPED
                    AND PCPEDC.NUMPEDRCA > 0
                    AND PCPEDC.INTEGRADORA = 29
                    AND ROWNUM = 1;
               EXCEPTION WHEN NO_DATA_FOUND THEN
                  vsPOSICAOOUTROPEDIDO := :NEW.POSICAO;
               END;
               --Somente coloca na fila se estiverem na mesma posição
               IF (vsPOSICAOOUTROPEDIDO = :NEW.POSICAO) THEN
                  BEGIN
                     FOR DADOS IN (SELECT DISTINCT
                                   NVL(PCPEDCTEMP.SERIEMANIF,PCPEDCTEMP.CODFILIAL) CODFILIAL,
                                   'SELECTPEDIDO' TABELA,
                                   PCPEDCTEMP.ROWID ID
                                   FROM PCPEDCTEMP
                                   WHERE PCPEDCTEMP.NUMPEDRCA = :OLD.NUMPEDRCA
                                     AND PCPEDCTEMP.NUMPED > 0
                                     AND PCPEDCTEMP.INTEGRADORA = 29)
                     LOOP
                        BEGIN
                           --Campo SerieManif grava o código da filial utilizada pelo e-commerce
                           INSERT INTO PCECOMMERCEUNILEVERFILA (CODFILIAL, TABELA, ID, DTINCLUSAO)
                           VALUES (DADOS.CODFILIAL, DADOS.TABELA, DADOS.ID, SYSDATE);
                        EXCEPTION WHEN OTHERS THEN
                           NULL;
                        END;
                     END LOOP;
                  EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
                     NULL;
                  END;
               END IF;
            END IF;
         EXCEPTION WHEN OTHERS THEN
            NULL;
         END;
      END IF;
   END IF;
END;
