CREATE OR REPLACE TRIGGER TRG_ECOMMERCEB2B_PCNFSAID AFTER INSERT
   ON PCNFSAID REFERENCING NEW AS NEW OLD AS OLD FOR EACH ROW
DECLARE
   vCODFILIAL PCNFSAID.CODFILIALNF%TYPE;
   vROWID PCECOMMERCEB2BFILA.ID%TYPE;
   vTIPOINTEGRACAO PCECOMMERCEB2BFILA.TIPOINTEGRACAO%TYPE;
   vQTDEPEDIDO INTEGER;
   vQTPOSICAO INTEGER;
   vQTPOSICAONF INTEGER;
   vNUMPED PCNFSAID.NUMPED%TYPE;
BEGIN
   vNUMPED := NVL(NVL(:NEW.NUMPED,:OLD.NUMPED),0);

   IF vNUMPED > 0 THEN  
      BEGIN
         SELECT COUNT(1)
         INTO vQTDEPEDIDO
         FROM PCPEDCTEMP
         WHERE PCPEDCTEMP.NUMPED > 0
           AND PCPEDCTEMP.NUMPEDWEB = (SELECT PCPEDC.NUMPEDWEB
                                       FROM PCPEDC
                                       WHERE PCPEDC.NUMPED = vNUMPED
                                         AND ROWNUM = 1);
      EXCEPTION WHEN OTHERS THEN
         vQTDEPEDIDO := 0;
      END;
      ------------------------------------------------------------------------
      IF vQTDEPEDIDO = 1 THEN
         BEGIN
            SELECT COALESCE(T.SERIEMANIF,T.CODFILIAL) CODFILIAL,
                   T.ROWID IDROWID,
                   T.INTEGRADORA
            INTO vCODFILIAL,
                 vROWID,
                 vTIPOINTEGRACAO
            FROM PCPEDCTEMP T
            WHERE T.INTEGRADORA IN (SELECT R.VALOR
                                    FROM PCROTULOITEM R,
                                         PCECOMMERCEB2B B
                                    WHERE R.ID = 'TIPOINTEGRADORA'
                                      AND R.VALOR IN (B.TIPOINTEGRACAO))
              AND COALESCE(T.NUMPED,0) > 0
              AND T.NUMPED = vNUMPED
              AND ROWNUM = 1;
         EXCEPTION WHEN OTHERS THEN
            vCODFILIAL := NULL;
            vROWID := NULL;
         END;

         IF vCODFILIAL IS NOT NULL AND vROWID IS NOT NULL THEN
            BEGIN
               INSERT INTO PCECOMMERCEB2BFILA(CODFILIAL, TABELA, ID, DTINCLUSAO, TIPOINTEGRACAO, OBSERVACAO)
                  VALUES(vCODFILIAL, 'PEDIDO', vROWID, SYSDATE, vTIPOINTEGRACAO, NULL);
            EXCEPTION WHEN OTHERS THEN
               NULL;
            END;
         END IF;       
      END IF;
      ------------------------------------------------------------------------
      IF vQTDEPEDIDO > 1 THEN
         BEGIN
            SELECT CONT
            INTO vQTPOSICAO
            FROM (SELECT COUNT(POSICAO) CONT
                  FROM PCPEDC
                  WHERE PCPEDC.DTCANCEL IS NULL
                    AND PCPEDC.NUMPEDRCA > 0
                    AND PCPEDC.INTEGRADORA IN (SELECT R.VALOR
                                               FROM PCROTULOITEM R,
                                                    PCECOMMERCEB2B B
                                               WHERE R.ID = 'TIPOINTEGRADORA'
                                                 AND R.VALOR IN (B.TIPOINTEGRACAO))
                    AND PCPEDC.POSICAO <> 'F'
                    AND PCPEDC.NUMPEDRCA = (SELECT PCPEDC.NUMPEDWEB
                                            FROM PCPEDC
                                            WHERE PCPEDC.NUMPED = vNUMPED
                                              AND ROWNUM = 1)
                  GROUP BY POSICAO)
            WHERE ROWNUM = 1;
         EXCEPTION WHEN OTHERS THEN
            vQTPOSICAO := 0;
         END;
         ---------------------------------------------------------------------
         IF vQTPOSICAO = 0 THEN
            BEGIN
               SELECT COUNT(DISTINCT(M.NUMPED))
               INTO vQTPOSICAONF
               FROM PCMOV M
               WHERE M.NUMTRANSVENDA IN (SELECT NUMTRANSVENDA
                                         FROM PCPEDC C,
                                              (SELECT PCPEDC.NUMPEDWEB, PCPEDC.DATA
                                               FROM PCPEDC
                                               WHERE PCPEDC.NUMPED = vNUMPED
                                                 AND ROWNUM = 1) D
                                         WHERE C.NUMPEDWEB = D.NUMPEDWEB
                                           AND C.DATA = D.DATA);
            EXCEPTION WHEN OTHERS THEN
               vQTPOSICAONF := 0;
            END;
         END IF;
         ---------------------------------------------------------------------
         IF (vQTPOSICAO > 1) OR (vQTPOSICAO = 0 AND vQTPOSICAONF > 1) THEN
            BEGIN
               SELECT COALESCE(T.SERIEMANIF,T.CODFILIAL) CODFILIAL,
                      T.ROWID IDROWID,
                      T.INTEGRADORA
               INTO vCODFILIAL,
                    vROWID,
                    vTIPOINTEGRACAO
               FROM PCPEDCTEMP T
               WHERE T.INTEGRADORA IN (SELECT R.VALOR
                                       FROM PCROTULOITEM R,
                                            PCECOMMERCEB2B B
                                       WHERE R.ID = 'TIPOINTEGRADORA'
                                         AND R.VALOR IN (B.TIPOINTEGRACAO))
                 AND COALESCE(T.NUMPED,0) > 0
                 AND T.NUMPED = vNUMPED
                 AND ROWNUM = 1;
            EXCEPTION WHEN OTHERS THEN
               vCODFILIAL := NULL;
               vROWID := NULL;
            END;

            IF vCODFILIAL IS NOT NULL AND vROWID IS NOT NULL THEN
               BEGIN
                  INSERT INTO PCECOMMERCEB2BFILA(CODFILIAL, TABELA, ID, DTINCLUSAO, TIPOINTEGRACAO, OBSERVACAO)
                     VALUES(vCODFILIAL, 'PEDIDO', vROWID, SYSDATE, vTIPOINTEGRACAO, NULL);
               EXCEPTION WHEN OTHERS THEN
                  NULL;
               END;
            END IF;
         END IF;
      END IF;
   END IF;
EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
   NULL;
END;
