BEGIN
   FOR REG IN (SELECT S.NUMTRANSVENDA
                    , S.ROWID LINHA
                 FROM PCNFSAID S
                WHERE S.NOTADUPLIQUESVC = 'S'
                  AND EXISTS(
                         SELECT 1
                           FROM PCMOV M
                          WHERE M.DTCANCEL IS NOT NULL
                            AND M.NUMTRANSVENDA = S.NUMTRANSVENDA
                            AND TRUNC(NVL(S.DTCANCEL, SYSDATE)) <> TRUNC(M.DTCANCEL))
                  AND S.SITUACAONFE IN(101, 151)
                  AND S.DTSAIDA >= TO_DATE('01-01-2025', 'DD-MM-YYYY'))
   LOOP
      UPDATE PCNFSAID
         SET DTCANCEL = (SELECT TRUNC(MAX(MOV.DTCANCEL))
                           FROM PCMOV MOV
                          WHERE MOV.NUMTRANSVENDA = REG.NUMTRANSVENDA)
       WHERE PCNFSAID.ROWID = REG.LINHA;
      COMMIT;
   END LOOP;
END;
