DECLARE
   VMENSAGEM VARCHAR2(400);
   VRETONO   VARCHAR2(1);
BEGIN
   EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_DATE_LANGUAGE = ''ENGLISH''';
   FOR REG IN (SELECT NF.*
                 FROM (SELECT PCNFENT.NUMTRANSENT
                            , PCNFSAID.NUMTRANSVENDA
                         FROM PCNFENT
                            , PCNFSAID
                        WHERE TRIM(PCNFSAID.CHAVENFE) IS NOT NULL
                          AND PCNFENT.ESPECIE = 'TP'
                          AND PCNFENT.DTEMISSAO >= '01-oct-2024'
                          AND PCNFSAID.NUMTRANSENTORIGEM > 0
                          AND PCNFENT.NUMTRANSENT = PCNFSAID.NUMTRANSENTORIGEM
                       UNION
                       SELECT PCNFENT.NUMTRANSENT
                            , PCNFSAID.NUMTRANSVENDA
                         FROM PCNFENT
                            , PCNFSAIDPREFAT PCNFSAID
                        WHERE TRIM(PCNFSAID.CHAVENFE) IS NOT NULL
                          AND PCNFENT.ESPECIE = 'TP'
                          AND PCNFENT.DTEMISSAO >= '01-oct-2024'
                          AND PCNFSAID.NUMTRANSENTORIGEM > 0
                          AND PCNFENT.NUMTRANSENT = PCNFSAID.NUMTRANSENTORIGEM) NF)
   LOOP
     BEGIN
       VRETONO := FERRAMENTAS_FATURAMENTO.SINC_INFOXML_SAIDA_ENTRADA(REG.NUMTRANSVENDA, VMENSAGEM);
       IF ((VRETONO = 'N') AND (VMENSAGEM <> 'OK')) THEN
         ROLLBACK;
       END IF;
       COMMIT;
     EXCEPTION
       WHEN OTHERS THEN
         ROLLBACK;
     END;
   END LOOP;
END;
