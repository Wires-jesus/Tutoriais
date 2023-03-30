CREATE OR REPLACE TRIGGER TRG_ECOMMERCEB2B_PCPEDC BEFORE INSERT OR DELETE OR UPDATE 
   OF POSICAO ON PCPEDC REFERENCING NEW AS NEW OLD AS OLD FOR EACH ROW
DECLARE
   vsTIPO VARCHAR2(10);
   vQTINI INTEGER;
   vQTCOMP INTEGER;
BEGIN
   vQTINI  := 0;
   vQTCOMP := 0;

   SELECT COUNT(*) 
   INTO vQTINI
   FROM PCECOMMERCEB2BPCPEDC P 
   WHERE P.NUMPEDWEB = :NEW.NUMPEDWEB
     AND P.TIPOPAGAMENTO NOT IN ('CREDIT_CARD','BILL','COUPON');

   IF :NEW.POSICAO NOT IN ('L','B','P') THEN
      vQTCOMP := 1;
   END IF;
   -------------------------------------------------------------------------------
   -- DELETAR
   -------------------------------------------------------------------------------
   CASE WHEN DELETING THEN
      BEGIN
         INSERT INTO PCECOMMERCEB2BFILA (CODFILIAL, TIPOINTEGRACAO, TABELA, ID, DTINCLUSAO, OBSERVACAO)
            SELECT NVL(PCPEDCTEMP.SERIEMANIF, PCPEDCTEMP.CODFILIAL), PCPEDCTEMP.INTEGRADORA,
                   'PEDIDO', 
                   PCPEDCTEMP.ROWID, 
                   SYSDATE,
                   CASE WHEN PCNFCAN.NUMTRANSVENDA IS NULL AND MOTIVO = 'Cliente sem limite de crédito' THEN 'MNA' ELSE 'CAN' END
            FROM PCPEDCTEMP, 
                 PCNFCAN
            WHERE PCPEDCTEMP.NUMPEDRCA = :OLD.NUMPEDRCA
              AND PCPEDCTEMP.NUMPED = PCNFCAN.NUMPED(+)
              AND PCPEDCTEMP.INTEGRADORA IN (SELECT PCROTULOITEM.VALOR 
                                             FROM PCROTULOITEM, 
                                                  PCECOMMERCEB2B 
                                             WHERE PCROTULOITEM.ID = 'TIPOINTEGRADORA'
                                               AND PCROTULOITEM.VALOR IN (PCECOMMERCEB2B.TIPOINTEGRACAO))
              AND PCPEDCTEMP.NUMPED > 0
              AND ROWNUM = 1;

         IF :OLD.POSICAO = 'L' THEN
            BEGIN
               INSERT INTO PCECOMMERCEB2BFILA(CODFILIAL, TIPOINTEGRACAO, TABELA, ID, DTINCLUSAO)
                  SELECT PCECOMMERCEB2BCLIENTE.CODFILIAL,
                         PCECOMMERCEB2BCLIENTE.TIPOINTEGRACAO,
                         'LIMITE',
                         PCCLIENT.ROWID,
                         SYSDATE
                  FROM PCECOMMERCEB2BCLIENTE, 
                       PCCLIENT
                  WHERE PCECOMMERCEB2BCLIENTE.CODCLI = PCCLIENT.CODCLI
                    AND PCCLIENT.CODCLI = NVL(:OLD.CODCLI,:NEW.CODCLI)
                    AND PCECOMMERCEB2BCLIENTE.TIPOINTEGRACAO = :OLD.INTEGRADORA
                    AND PCECOMMERCEB2BCLIENTE.CODFILIAL = NVL(:OLD.CODFILIALNF,:OLD.CODFILIAL)
                    AND NVL(PCECOMMERCEB2BCLIENTE.SITUACAOECOMMERCEB2B,'NAO') <> 'NAO';
            EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
               NULL;
            END;
         END IF;
      EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
         NULL;
      END;
   -------------------------------------------------------------------------------
   -- INCLUIR
   -------------------------------------------------------------------------------
   WHEN INSERTING THEN
      BEGIN
         IF :NEW.POSICAO = 'L' THEN
            BEGIN
               INSERT INTO PCECOMMERCEB2BFILA (CODFILIAL, TIPOINTEGRACAO, TABELA, ID, DTINCLUSAO)
                  SELECT PCECOMMERCEB2BCLIENTE.CODFILIAL
                       , PCECOMMERCEB2BCLIENTE.TIPOINTEGRACAO
                       , 'LIMITE'
                       , PCCLIENT.ROWID
                       , SYSDATE
                  FROM PCECOMMERCEB2BCLIENTE
                     , PCCLIENT
                  WHERE PCCLIENT.CODCLI = NVL(:OLD.CODCLI, :NEW.CODCLI)
                    AND PCECOMMERCEB2BCLIENTE.CODCLI = PCCLIENT.CODCLI
                    AND PCECOMMERCEB2BCLIENTE.TIPOINTEGRACAO = :OLD.INTEGRADORA
                    AND PCECOMMERCEB2BCLIENTE.CODFILIAL = NVL(:OLD.CODFILIALNF,:OLD.CODFILIAL)
                    AND NVL(PCECOMMERCEB2BCLIENTE.SITUACAOECOMMERCEB2B,'NAO') <> 'NAO';
            EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
               NULL;
            END;
         END IF;
     
         IF (vQTINI > 0) OR (vQTCOMP > 0) THEN
           BEGIN
              INSERT INTO PCECOMMERCEB2BFILA (CODFILIAL, TIPOINTEGRACAO, TABELA, ID, DTINCLUSAO, OBSERVACAO)
                 SELECT NVL(PCPEDCTEMP.SERIEMANIF,PCPEDCTEMP.CODFILIAL),
                        PCPEDCTEMP.INTEGRADORA,
                        'PEDIDO',
                        PCPEDCTEMP.ROWID,
                        SYSDATE,
                        vsTIPO
                 FROM PCPEDCTEMP
                 WHERE PCPEDCTEMP.NUMPEDRCA = :NEW.NUMPEDRCA
                   AND PCPEDCTEMP.INTEGRADORA IN (SELECT PCROTULOITEM.VALOR
                                                  FROM PCROTULOITEM, PCECOMMERCEB2B
                                                  WHERE PCROTULOITEM.ID = 'TIPOINTEGRADORA'
                                                    AND PCROTULOITEM.VALOR = PCECOMMERCEB2B.TIPOINTEGRACAO);
            EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
               NULL;
            END;
         END IF;
      EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
         NULL;
      END;
   -------------------------------------------------------------------------------
   -- ALTERAR
   -------------------------------------------------------------------------------
   WHEN UPDATING THEN
      BEGIN
         IF ((:OLD.POSICAO IN ('B','P')) AND (:NEW.POSICAO = 'L')) OR
            ((:OLD.POSICAO IN ('L','M')) AND (:NEW.POSICAO IN ('B','P','F'))) THEN
            BEGIN
            INSERT INTO PCECOMMERCEB2BFILA (CODFILIAL, TIPOINTEGRACAO, TABELA, ID, DTINCLUSAO)
               SELECT PCECOMMERCEB2BCLIENTE.CODFILIAL
                    , PCECOMMERCEB2BCLIENTE.TIPOINTEGRACAO
                    , 'LIMITE'
                    , PCCLIENT.ROWID
                    , SYSDATE
               FROM PCECOMMERCEB2BCLIENTE
                  , PCCLIENT
               WHERE PCCLIENT.CODCLI = NVL(:OLD.CODCLI, :NEW.CODCLI)
                 AND PCECOMMERCEB2BCLIENTE.CODCLI = PCCLIENT.CODCLI
                 AND PCECOMMERCEB2BCLIENTE.TIPOINTEGRACAO = :OLD.INTEGRADORA
                 AND PCECOMMERCEB2BCLIENTE.CODFILIAL = NVL(:OLD.CODFILIALNF,:OLD.CODFILIAL)
                 AND NVL(PCECOMMERCEB2BCLIENTE.SITUACAOECOMMERCEB2B,'NAO') <> 'NAO';
            EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
               NULL;
            END;
         END IF;

         IF :NEW.POSICAO = 'M' THEN
            BEGIN
               INSERT INTO PCECOMMERCEB2BFILA (CODFILIAL, TIPOINTEGRACAO, TABELA, ID, DTINCLUSAO, OBSERVACAO)
                  SELECT NVL(PCPEDCTEMP.SERIEMANIF, PCPEDCTEMP.CODFILIAL),
                         PCPEDCTEMP.INTEGRADORA,
                         'PEDIDO',
                         PCPEDCTEMP.ROWID,
                         SYSDATE, 
                         vsTIPO
                  FROM PCPEDCTEMP
                  WHERE PCPEDCTEMP.NUMPEDRCA = :NEW.NUMPEDRCA
                    AND PCPEDCTEMP.INTEGRADORA IN (SELECT PCROTULOITEM.VALOR 
                                                   FROM PCROTULOITEM, PCECOMMERCEB2B
                                                   WHERE PCROTULOITEM.ID = 'TIPOINTEGRADORA'
                                                     AND PCROTULOITEM.VALOR = PCECOMMERCEB2B.TIPOINTEGRACAO);
            EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
               NULL;
            END;
         END IF;
      EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
         NULL;
      END;
   END CASE;
END;


