CREATE OR REPLACE TRIGGER TRG_ECOMMERCEB2B_PCCARREG 
   BEFORE INSERT OR UPDATE OF DTFECHA ON PCCARREG
   REFERENCING NEW AS NEW OLD AS OLD FOR EACH ROW
BEGIN
   IF :NEW.DTFECHA IS NOT NULL THEN
      BEGIN
         INSERT INTO PCECOMMERCEB2BFILA (CODFILIAL, TABELA, TIPOINTEGRACAO, ID, DTINCLUSAO, OBSERVACAO)
            SELECT NVL(PCPEDCTEMP.SERIEMANIF, PCPEDCTEMP.CODFILIAL),'PEDIDO', PCPEDCTEMP.INTEGRADORA, PCPEDCTEMP.ROWID, SYSDATE, 'ENT'
            FROM PCPEDCTEMP
            WHERE PCPEDCTEMP.INTEGRADORA IN (SELECT R.VALOR
                                             FROM PCROTULOITEM R,
                                                  PCECOMMERCEB2B B
                                             WHERE R.ID = 'TIPOINTEGRADORA'
                                               AND R.VALOR IN (B.TIPOINTEGRACAO))
              AND PCPEDCTEMP.NUMPED > 0
              AND PCPEDCTEMP.NUMPED  IN (SELECT PCPEDC.NUMPED
                                         FROM PCPEDC
                                         WHERE PCPEDC.DTCANCEL IS NULL
                                           AND PCPEDC.POSICAO = 'F'
                                           AND PCPEDC.INTEGRADORA IN (SELECT R.VALOR
                                                                      FROM PCROTULOITEM R,
                                                                           PCECOMMERCEB2B B
                                                                      WHERE R.ID = 'TIPOINTEGRADORA'
                                                                        AND R.VALOR IN (B.TIPOINTEGRACAO))
                                           AND PCPEDC.NUMCAR = :NEW.NUMCAR) ;
      EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
         NULL;
      END;                                            
   END IF;
END;
