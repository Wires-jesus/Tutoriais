CREATE OR REPLACE TRIGGER TRG_ECOMMERCE_PCNFSAID
   AFTER INSERT ON PCNFSAID 
   REFERENCING NEW AS NEW OLD AS OLD FOR EACH ROW
DECLARE
   VCODFILIAL PCNFSAID.CODFILIALNF%TYPE;
   VROWID PCECOMMERCEUNILEVERFILA.ID%TYPE;
   vnQTDEPEDIDO INTEGER;
   VQTPOSICAO INTEGER;
   VQTPOSICAONF INTEGER;
   vNUMPED PCNFSAID.NUMPED%TYPE;
BEGIN
   vNUMPED := NVL(NVL(:NEW.NUMPED,:OLD.NUMPED),0);
   IF vNUMPED > 0 THEN  
      BEGIN
         SELECT COUNT(1) CONT
         INTO vnQTDEPEDIDO
         FROM PCPEDCTEMP
         WHERE PCPEDCTEMP.NUMPED > 0
           AND PCPEDCTEMP.NUMPEDWEB = (SELECT PCPEDC.NUMPEDWEB
                                       FROM PCPEDC
                                       WHERE PCPEDC.NUMPED = vNUMPED
                                         AND ROWNUM = 1);
      EXCEPTION
         WHEN OTHERS THEN
            vnQTDEPEDIDO := 0;
      END;
      ------------------------------------------------------------------------
      ------------------------------------------------------------------------
      IF vnQTDEPEDIDO = 1 THEN
         BEGIN
            SELECT COALESCE(T.SERIEMANIF,T.CODFILIAL) CODFILIAL,
                   T.ROWID IDROWID
            INTO VCODFILIAL,
                 VROWID
            FROM PCPEDCTEMP T
            WHERE T.INTEGRADORA = 29
              AND COALESCE(T.NUMPED,0) > 0
              AND T.NUMPED = vNUMPED
              AND ROWNUM = 1;
         EXCEPTION
            WHEN OTHERS THEN
               VCODFILIAL := NULL;
               VROWID := NULL;
         END;

         IF VCODFILIAL IS NOT NULL AND VROWID IS NOT NULL THEN
            INSERT INTO PCECOMMERCEUNILEVERFILA (CODFILIAL, TABELA, ID, DTINCLUSAO)
                   VALUES(VCODFILIAL, 'SELECTPEDIDO', VROWID, SYSDATE);
         END IF;       
      END IF;
      ------------------------------------------------------------------------
      ------------------------------------------------------------------------
      IF vnQTDEPEDIDO > 1 THEN
         BEGIN
            SELECT CONT
            INTO VQTPOSICAO
            FROM (SELECT COUNT(POSICAO) CONT
                  FROM PCPEDC
                  WHERE PCPEDC.DTCANCEL IS NULL
                    AND PCPEDC.NUMPEDRCA > 0
                    AND PCPEDC.INTEGRADORA = 29
                    AND PCPEDC.POSICAO <> 'F'
                    AND PCPEDC.NUMPEDRCA = (SELECT PCPEDC.NUMPEDWEB
                                            FROM PCPEDC
                                            WHERE PCPEDC.NUMPED = vNUMPED
                                              AND ROWNUM = 1)
                  GROUP BY POSICAO)
            WHERE ROWNUM = 1;
         EXCEPTION
            WHEN OTHERS THEN
               VQTPOSICAO := 0;
         END;
         ---------------------------------------------------------------------
         IF VQTPOSICAO = 0 THEN
            BEGIN
               SELECT COUNT(DISTINCT(M.NUMPED)) CONT
                INTO vQTPOSICAONF
                FROM PCMOV M
               WHERE M.NUMTRANSVENDA IN
                     (SELECT NUMTRANSVENDA
                        FROM PCPEDC C,
                             (SELECT PCPEDC.NUMPEDWEB, PCPEDC.DATA
                                FROM PCPEDC
                               WHERE PCPEDC.NUMPED = vNUMPED
                                 AND ROWNUM = 1) D
                       WHERE C.NUMPEDWEB = D.NUMPEDWEB
                         AND C.DATA = D.DATA);
            EXCEPTION
               WHEN OTHERS THEN
                  vQTPOSICAONF := 0;
            END;
         END IF;
         ---------------------------------------------------------------------
         IF (VQTPOSICAO > 1) OR (VQTPOSICAO = 0 AND VQTPOSICAONF > 1) THEN
            BEGIN
               SELECT COALESCE(T.SERIEMANIF,T.CODFILIAL) CODFILIAL,
                      T.ROWID IDROWID
               INTO VCODFILIAL,
                    VROWID
               FROM PCPEDCTEMP T
               WHERE T.INTEGRADORA = 29
                 AND COALESCE(T.NUMPED,0) > 0
                 AND T.NUMPED = vNUMPED
                 AND ROWNUM = 1;
            EXCEPTION
               WHEN OTHERS THEN
                  VCODFILIAL := NULL;
                  VROWID := NULL;
            END;

            IF VCODFILIAL IS NOT NULL AND VROWID IS NOT NULL THEN
               INSERT INTO PCECOMMERCEUNILEVERFILA (CODFILIAL, TABELA, ID, DTINCLUSAO)
                      VALUES(VCODFILIAL, 'SELECTPEDIDO', VROWID, SYSDATE);
            END IF;       
         END IF;    
         ---------------------------------------------------------------------
      END IF;
      ------------------------------------------------------------------------
      ------------------------------------------------------------------------
   END IF;
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
   NULL;
END;
