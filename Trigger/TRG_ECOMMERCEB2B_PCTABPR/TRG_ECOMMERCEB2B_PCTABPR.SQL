CREATE OR REPLACE TRIGGER TRG_ECOMMERCEB2B_PCTABPR
   BEFORE INSERT OR UPDATE OF PVENDA1, PVENDA2, PVENDA3, PVENDA4, PVENDA5, PVENDA6, PVENDA7 
   ON PCTABPR REFERENCING NEW AS NEW OLD AS OLD FOR EACH ROW
BEGIN
   IF (NVL(:NEW.PVENDA1, 0) > 0) AND 
      (NVL(:NEW.PVENDA2, 0) > 0) AND (NVL(:NEW.PVENDA3, 0) > 0) AND 
      (NVL(:NEW.PVENDA4, 0) > 0) AND (NVL(:NEW.PVENDA5, 0) > 0) AND 
      (NVL(:NEW.PVENDA6, 0) > 0) AND (NVL(:NEW.PVENDA7, 0) > 0) THEN
      FOR REGISTROS IN (SELECT DISTINCT 
                               EP.CODFILIAL,
                               EP.TIPOINTEGRACAO,
                               P.ROWID ID
                        FROM PCECOMMERCEB2BPRODUTO EP,
                             PCPRODUT P,
                             PCECOMMERCEB2B E
                        WHERE EP.CODPROD = P.CODPROD
                          AND EP.CODFILIAL = E.CODFILIAL
                          AND EP.TIPOINTEGRACAO = E.TIPOINTEGRACAO
                          AND E.NUMREGIAO = NVL(:NEW.NUMREGIAO,:OLD.NUMREGIAO)
                          AND EP.CODPROD = :NEW.CODPROD)
      LOOP
         BEGIN --Inserindo registros a ser enviado para todas as configurações validas
	    INSERT INTO PCECOMMERCEB2BFILA (CODFILIAL, 
                                            TIPOINTEGRACAO, 
                                            TABELA, 
                                            ID, 
                                            DTINCLUSAO
                                            )
	        VALUES (REGISTROS.CODFILIAL
                      , REGISTROS.TIPOINTEGRACAO
                      , 'PRECO'
                      , REGISTROS.ID
                      , SYSDATE
                      );
         EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
            NULL;
         END;
      END LOOP;
   END IF;  
END;
