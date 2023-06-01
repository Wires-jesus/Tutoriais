
















CREATE OR REPLACE TRIGGER TRG_ECOMMERCE_PCPRODUT AFTER INSERT OR DELETE OR UPDATE 
   OF USAECOMMERCEUNILEVER, QTUNIT, QTUNITCX, MULTIPLO, EMBVENDAECOMMERCEUNILEVER, CODAUXILIAR ON PCPRODUT
   REFERENCING NEW AS NEW OLD AS OLD FOR EACH ROW
DECLARE 
   vsENVIARREGISTRO VARCHAR2(1);
   vnUSAALIENACAOPRODUTO NUMBER;
   vnFILIALPOSSUIPRODUTO NUMBER;
   vbOBSERVACAO VARCHAR2(1);
   vPVENDA1 PCTABPR.PVENDA1%TYPE;
   vPVENDA2 PCTABPR.PVENDA2%TYPE;
   vPVENDA3 PCTABPR.PVENDA3%TYPE;
   vPVENDA4 PCTABPR.PVENDA4%TYPE;
   vPVENDA5 PCTABPR.PVENDA5%TYPE;
   vPVENDA6 PCTABPR.PVENDA6%TYPE;
   vPVENDA7 PCTABPR.PVENDA7%TYPE;   
   vCODFILIAL PCFILIAL.CODIGO%TYPE;
   vCODAUXILIAR VARCHAR2(30);
   vROWID VARCHAR2(30);   
BEGIN
   vCODAUXILIAR := '';
   vbOBSERVACAO := 'N';  
   vsENVIARREGISTRO := 'N';

   IF (NVL(:NEW.USAECOMMERCEUNILEVER,'N') <> 'N') THEN
      vsENVIARREGISTRO := 'S';
   ELSIF NVL(:NEW.USAECOMMERCEUNILEVER,'N') <> NVL(:OLD.USAECOMMERCEUNILEVER,'N') THEN
      vsENVIARREGISTRO := 'S';
   ELSIF :NEW.DTEXCLUSAO IS NOT NULL THEN
      vsENVIARREGISTRO := 'S';
   END IF;

   IF TO_CHAR(:NEW.CODAUXILIAR) <> TO_CHAR(:OLD.CODAUXILIAR) THEN
      vsENVIARREGISTRO := 'S';
      vbOBSERVACAO := 'S';
   END IF;
   
   IF :NEW.MULTIPLO <> :OLD.MULTIPLO THEN
      vsENVIARREGISTRO := 'S';
      vbOBSERVACAO := 'S';
   END IF;
   
   IF :NEW.QTUNIT <> :OLD.QTUNIT THEN
      vsENVIARREGISTRO := 'S';
      vbOBSERVACAO := 'S';
   END IF;
   
   IF :NEW.QTUNITCX <> :OLD.QTUNITCX THEN
      vsENVIARREGISTRO := 'S';
      vbOBSERVACAO := 'S';
   END IF;
   
   IF :NEW.EMBVENDAECOMMERCEUNILEVER <> :OLD.EMBVENDAECOMMERCEUNILEVER THEN
      vsENVIARREGISTRO := 'S';
      vbOBSERVACAO := 'S';
   END IF;

   IF vsENVIARREGISTRO = 'S' THEN  
      BEGIN
         SELECT COUNT(1)
         INTO vnUSAALIENACAOPRODUTO
         FROM PCECOMMERCEUNILEVERPRODUTO;
      EXCEPTION WHEN NO_DATA_FOUND THEN
         vnUSAALIENACAOPRODUTO := 0;
      END;

      FOR REGISTRO IN (SELECT NVL(P.VALOR,'N') VALOR,
                              NVL(E.CODFILIAL,'') CODFILIAL
                       FROM PCPARAMFILIAL P,
                            PCECOMMERCEUNILEVER E
                       WHERE P.NOME = 'FIL_UTILIZAVENDAPOREMBALAGEM'
                         AND P.CODFILIAL = E.CODFILIAL)
      LOOP
         BEGIN
            SELECT COUNT(1)
            INTO vnFILIALPOSSUIPRODUTO
            FROM PCECOMMERCEUNILEVERPRODUTO
            WHERE PCECOMMERCEUNILEVERPRODUTO.CODPROD = :NEW.CODPROD
              AND PCECOMMERCEUNILEVERPRODUTO.CODFILIAL = REGISTRO.CODFILIAL;
         EXCEPTION WHEN NO_DATA_FOUND THEN
            vnFILIALPOSSUIPRODUTO := 0;
         END;

         IF ((vnUSAALIENACAOPRODUTO = 0) OR (vnFILIALPOSSUIPRODUTO > 0)) THEN
            BEGIN
               SELECT NVL(T.PVENDA1,0) PVENDA1,
                      NVL(T.PVENDA2,0) PVENDA2,
                      NVL(T.PVENDA3,0) PVENDA3,
                      NVL(T.PVENDA4,0) PVENDA4,
                      NVL(T.PVENDA5,0) PVENDA5,
                      NVL(T.PVENDA6,0) PVENDA6,
                      NVL(T.PVENDA7,0) PVENDA7
               INTO vPVENDA1,
                    vPVENDA2,
                    vPVENDA3,
                    vPVENDA4,
                    vPVENDA5,
                    vPVENDA6,
                    vPVENDA7
               FROM PCTABPR T
               WHERE T.CODPROD = :NEW.CODPROD
                 AND T.NUMREGIAO = (SELECT MAX(U.NUMREGIAO)
                                    FROM PCECOMMERCEUNILEVER U
                                    WHERE U.CODFILIAL = REGISTRO.CODFILIAL);
            EXCEPTION WHEN OTHERS THEN
               vPVENDA1 := 0;
               vPVENDA2 := 0;
               vPVENDA3 := 0;
               vPVENDA4 := 0;
               vPVENDA5 := 0;
               vPVENDA6 := 0;
               vPVENDA7 := 0;
            END;

            IF REGISTRO.VALOR = 'N' THEN
               BEGIN --Inserindo registros a ser enviado para todas as configurações validas
                  --Enviar estoque
                  INSERT INTO PCECOMMERCEUNILEVERFILA (CODFILIAL, TABELA, ID, DTINCLUSAO, OBSERVACAO)
                  SELECT PCECOMMERCEUNILEVER.CODFILIAL
                       , 'SELECTESTOQUE'
                       , :NEW.ROWID
                       , SYSDATE
                       , FNC_ECOMMERCEUNILEVER_CODAUX(:OLD.CODPROD,:OLD.QTUNIT,:OLD.QTUNITCX,:OLD.EMBVENDAECOMMERCEUNILEVER,TO_CHAR(:OLD.CODAUXILIAR),:OLD.MULTIPLO,PCECOMMERCEUNILEVER.CODFILIAL,:OLD.CODFORNEC,vbOBSERVACAO, 0)
                  FROM PCECOMMERCEUNILEVER
                  WHERE PCECOMMERCEUNILEVER.CODFILIAL = REGISTRO.CODFILIAL
                    AND ((vnUSAALIENACAOPRODUTO = 0)
                     OR  ((vnUSAALIENACAOPRODUTO > 0) AND EXISTS (SELECT 1
                                                                  FROM PCECOMMERCEUNILEVERPRODUTO
                                                                  WHERE PCECOMMERCEUNILEVERPRODUTO.CODPROD = :NEW.CODPROD
                                                                    AND PCECOMMERCEUNILEVERPRODUTO.CODFILIAL = PCECOMMERCEUNILEVER.CODFILIAL)));
               EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
                  NULL;
               END;

               BEGIN
                  SELECT NVL(PCECOMMERCEUNILEVER.CODFILIAL,'')
                       , :NEW.ROWID
                       , NVL(FNC_ECOMMERCEUNILEVER_CODAUX(:OLD.CODPROD,:OLD.QTUNIT,:OLD.QTUNITCX,:OLD.EMBVENDAECOMMERCEUNILEVER,TO_CHAR(:OLD.CODAUXILIAR),:OLD.MULTIPLO,PCECOMMERCEUNILEVER.CODFILIAL,:OLD.CODFORNEC,vbOBSERVACAO, 0), '')
                  INTO vCODFILIAL,
                       vROWID,
                       vCODAUXILIAR
                  FROM PCECOMMERCEUNILEVER
                  WHERE PCECOMMERCEUNILEVER.CODFILIAL = REGISTRO.CODFILIAL 
                    AND ((vnUSAALIENACAOPRODUTO = 0)
                     OR  ((vnUSAALIENACAOPRODUTO > 0) AND EXISTS (SELECT 1
                                                                  FROM PCECOMMERCEUNILEVERPRODUTO
                                                                  WHERE PCECOMMERCEUNILEVERPRODUTO.CODPROD = :NEW.CODPROD
                                                                    AND PCECOMMERCEUNILEVERPRODUTO.CODFILIAL = PCECOMMERCEUNILEVER.CODFILIAL)));
               EXCEPTION WHEN OTHERS THEN
                  vCODFILIAL   := '';
                  vROWID       := '';
                  vCODAUXILIAR := '';
               END;			  
               --Se a variável vCODAUXILIAR for igual a nulo, deverá receber o valor vazio ('').
               IF vCODAUXILIAR = NULL THEN
                  vCODAUXILIAR := '';
               END IF;
               --Enviar preço
               BEGIN --Inserindo registros a ser enviado para todas as configurações validas
                  IF (NVL(vPVENDA1,0) > 0) AND (NVL(vPVENDA2,0) > 0) AND (NVL(vPVENDA3,0) > 0) AND 
                     (NVL(vPVENDA4,0) > 0) AND (NVL(vPVENDA5,0) > 0) AND (NVL(vPVENDA6,0) > 0) AND (NVL(vPVENDA7,0) > 0) THEN
                     INSERT INTO PCECOMMERCEUNILEVERFILA (CODFILIAL, TABELA, ID, DTINCLUSAO, OBSERVACAO)
                        VALUES(vCODFILIAL, 'SELECTPRECO', vROWID, SYSDATE, vCODAUXILIAR);
                  ELSE 
                     IF (NVL(vCODAUXILIAR,'') <> '') THEN
                        INSERT INTO PCECOMMERCEUNILEVERFILA (CODFILIAL, TABELA, ID, DTINCLUSAO, OBSERVACAO)
                           VALUES(vCODFILIAL, 'SELECTPRECO', vROWID, SYSDATE, vCODAUXILIAR);
                     END IF;
                  END IF;
               EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
                  NULL;
               END;
            ELSE
               BEGIN --Inserindo registros a ser enviado para todas as configurações validas
                  --Enviar estoque
                  INSERT INTO PCECOMMERCEUNILEVERFILA (CODFILIAL, TABELA, ID, DTINCLUSAO, OBSERVACAO)
                  SELECT PCECOMMERCEUNILEVER.CODFILIAL
                       , 'SELECTESTOQUE'
                       , :NEW.ROWID
                       , SYSDATE
                       , FNC_ECOMMERCEUNILEVER_CODAUX(:OLD.CODPROD,PCEMBALAGEM.QTUNIT,:OLD.QTUNITCX,:OLD.EMBVENDAECOMMERCEUNILEVER,TO_CHAR(TO_CHAR(:OLD.CODAUXILIAR)),:OLD.MULTIPLO,PCECOMMERCEUNILEVER.CODFILIAL,:OLD.CODFORNEC,vbOBSERVACAO, TO_CHAR(PCEMBALAGEM.CODAUXILIAR))
                  FROM PCECOMMERCEUNILEVER, PCEMBALAGEM 
                  WHERE PCECOMMERCEUNILEVER.CODFILIAL = REGISTRO.CODFILIAL 
                    AND PCEMBALAGEM.CODFILIAL = PCECOMMERCEUNILEVER.CODFILIAL
                    AND NVL(PCEMBALAGEM.USAECOMMERCEUNILEVER,'N') = 'S'
                    AND ((vnUSAALIENACAOPRODUTO = 0)
                     OR  ((vnUSAALIENACAOPRODUTO > 0) AND EXISTS (SELECT 1
                                                                  FROM PCECOMMERCEUNILEVERPRODUTO
                                                                  WHERE PCECOMMERCEUNILEVERPRODUTO.CODPROD = :NEW.CODPROD
                                                                    AND PCECOMMERCEUNILEVERPRODUTO.CODFILIAL = PCECOMMERCEUNILEVER.CODFILIAL)));
               EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
                  NULL;
               END;

               BEGIN
                  SELECT NVL(PCECOMMERCEUNILEVER.CODFILIAL,'')
                       , :NEW.ROWID
                       , NVL(FNC_ECOMMERCEUNILEVER_CODAUX(:OLD.CODPROD,PCEMBALAGEM.QTUNIT,:OLD.QTUNITCX,:OLD.EMBVENDAECOMMERCEUNILEVER,TO_CHAR(:OLD.CODAUXILIAR),:OLD.MULTIPLO,PCECOMMERCEUNILEVER.CODFILIAL,:OLD.CODFORNEC,vbOBSERVACAO, TO_CHAR(PCEMBALAGEM.CODAUXILIAR)), '')
                  INTO vCODFILIAL,
                       vROWID,
                       vCODAUXILIAR
                  FROM PCECOMMERCEUNILEVER, PCEMBALAGEM 
                  WHERE PCECOMMERCEUNILEVER.CODFILIAL = REGISTRO.CODFILIAL
                    AND PCEMBALAGEM.CODFILIAL = PCECOMMERCEUNILEVER.CODFILIAL
                    AND NVL(PCEMBALAGEM.USAECOMMERCEUNILEVER,'N') = 'S'
                    AND ((vnUSAALIENACAOPRODUTO = 0)
                     OR  ((vnUSAALIENACAOPRODUTO > 0) AND EXISTS (SELECT 1
                                                                  FROM PCECOMMERCEUNILEVERPRODUTO
                                                                  WHERE PCECOMMERCEUNILEVERPRODUTO.CODPROD = :NEW.CODPROD
                                                                    AND PCECOMMERCEUNILEVERPRODUTO.CODFILIAL = PCECOMMERCEUNILEVER.CODFILIAL)));
               EXCEPTION WHEN OTHERS THEN
                  vCODFILIAL   := '';
                  vROWID       := '';
                  vCODAUXILIAR := '';
               END;
               --Se a variável vCODAUXILIAR for igual a nulo, deverá receber o valor vazio ('').
               IF vCODAUXILIAR = NULL THEN
                  vCODAUXILIAR := '';
               END IF;
               --Enviar preço
               BEGIN --Inserindo registros a ser enviado para todas as configurações validas
                  IF ((NVL(vCODFILIAL,'') <> '') AND (NVL(vPVENDA1,0) > 0) AND (NVL(vPVENDA2,0) > 0) AND (NVL(vPVENDA3,0) > 0) AND
                      (NVL(vPVENDA4,0) > 0) AND (NVL(vPVENDA5,0) > 0) AND (NVL(vPVENDA6,0) > 0) AND (NVL(vPVENDA7,0) > 0)) THEN
                      INSERT INTO PCECOMMERCEUNILEVERFILA (CODFILIAL, TABELA, ID, DTINCLUSAO, OBSERVACAO)
                         VALUES(vCODFILIAL, 'SELECTPRECO', vROWID, SYSDATE, vCODAUXILIAR);
                  ELSE
                     IF (NVL(vCODAUXILIAR,'') <> '') THEN
                        INSERT INTO PCECOMMERCEUNILEVERFILA (CODFILIAL, TABELA, ID, DTINCLUSAO, OBSERVACAO)
                           VALUES(vCODFILIAL, 'SELECTPRECO', vROWID, SYSDATE, vCODAUXILIAR);
                     END IF;
                  END IF;
               EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
                  NULL;
               END;
            END IF;
         END IF;
      END LOOP;
   END IF;
END;
