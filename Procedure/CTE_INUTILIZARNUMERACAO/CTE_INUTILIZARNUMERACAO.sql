CREATE OR REPLACE PROCEDURE CTE_INUTILIZARNUMERACAO(P_CODFILIAL           VARCHAR2,
                                                    P_DTHORAPROCESSAMENTO VARCHAR2,
                                                    P_NUMINICIAL          NUMBER,
                                                    P_NUMFINAL            NUMBER,
                                                    P_SERIE               NUMBER,
                                                    P_ANO                 NUMBER,
                                                    P_JUSTIFICATIVA       VARCHAR2,
                                                    P_PROTOCOLO           VARCHAR2,
                                                    P_AMBIENTE            VARCHAR2,
                                                    P_CODUSUARIO          NUMBER) IS
  VNPROXNUMTRANSVENDA PCNFSAID.NUMTRANSVENDA%TYPE;
  VNCODCLI            PCNFSAID.CODCLI%TYPE;
  VNTOTAL             NUMBER;
  V_DTHORAPROCESSAMENTO DATE;
BEGIN
  V_DTHORAPROCESSAMENTO := TO_DATE(P_DTHORAPROCESSAMENTO, 'DD/MM/YYYY');

  SELECT NVL(COUNT(1), 0)
    INTO VNTOTAL
    FROM PCINUTILIZACAOCTE
   WHERE CODFILIAL = P_CODFILIAL
     AND P_NUMINICIAL BETWEEN NUMNOTAINICIAL AND NUMNOTAFINAL
     AND P_NUMFINAL BETWEEN NUMNOTAINICIAL AND NUMNOTAFINAL
     AND SERIE = P_SERIE
     AND AMBIENTE = P_AMBIENTE;

  IF VNTOTAL = 0 THEN
  
    INSERT INTO PCINUTILIZACAOCTE
      (CODFILIAL,
       DTHORAPROCESSAMENTO,
       JUSTIFICATIVA,
       AMBIENTE,
       PROTOCOLOINUTILIZACAO,
       NUMNOTAINICIAL,
       NUMNOTAFINAL,
       SERIE,
       ANO,
       CODUSUARIO)
    VALUES
      (P_CODFILIAL,
       V_DTHORAPROCESSAMENTO,
       P_JUSTIFICATIVA,
       P_AMBIENTE,
       P_PROTOCOLO,
       P_NUMINICIAL,
       P_NUMFINAL,
       P_SERIE,
       P_ANO,
       P_CODUSUARIO);
  
  END IF;

  SELECT CODCLI INTO VNCODCLI FROM PCFILIAL WHERE CODIGO = P_CODFILIAL;
  VNTOTAL := 0;
  FOR I IN P_NUMINICIAL .. P_NUMFINAL LOOP
  
    SELECT COUNT(1)
      INTO VNTOTAL
      FROM PCNFSAID, PCFILIAL
     WHERE PCNFSAID.NUMNOTA = I
       AND NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL) = PCFILIAL.CODIGO
       AND SERIE = TO_CHAR(P_SERIE)
       AND PCFILIAL.CODIGO = P_CODFILIAL
       AND PCNFSAID.DTSAIDA >= TRUNC(PCFILIAL.DTUTILIZACTE);
  
    IF VNTOTAL = 0 THEN
    
      SELECT NVL(PROXNUMTRANSVENDA, 1)
        INTO VNPROXNUMTRANSVENDA
        FROM PCCONSUM
         FOR UPDATE;
    
      UPDATE PCCONSUM
         SET PROXNUMTRANSVENDA = NVL(PROXNUMTRANSVENDA, 1) + 1;
    
      INSERT INTO PCNFBASE
        (NUMTRANSVENDA, ALIQUOTA, VLBASE, VLICMS, TIPO, CODFISCAL, CODCONT)
      VALUES
        (VNPROXNUMTRANSVENDA, 0, 0, 0, '1', 5949, 0);
    
      INSERT INTO PCNFSAID
        (NUMTRANSVENDA,
         NUMNOTA,
         SERIE,
         ESPECIE,
         CODFISCAL,
         VLTOTAL,
         DTENTREGA,
         DTSAIDA,
         ICMSRETIDO,
         BCST,
         VLDESCONTO,
         OBS,
         CODCLI,
         CODCONT,
         CODFILIAL,
         CODFILIALNF,
         VLIPI,
         VLBASEIPI,
         VLFRETE,
         VLOUTRASDESP,
         CODPRACA,
         CAIXA,
         CODUSUR,
         TIPOVENDA,
         PERBASEREDOUTRASDESP,
         CODCLINF,
         CODFISCALFRETE,
         CODFISCALOUTRASDESP,
         PERCICMFRETE,
         ALIQICMOUTRASDESP,
         DTLANCTO,
         SITUACAOCTE,
         NOTADUPLIQUESVC,
         DTCANCEL)
      VALUES
        (VNPROXNUMTRANSVENDA,
         I,
         TO_CHAR(P_SERIE),
         'CO',
         599,
         0,
         TRUNC(V_DTHORAPROCESSAMENTO),
         TRUNC(V_DTHORAPROCESSAMENTO),
         0,
         0,
         0,
         'INUTILIZAÇÃO DE NÚMERO',
         VNCODCLI,
         0,
         P_CODFILIAL,
         P_CODFILIAL,
         0,
         0,
         0,
         0,
         0,
         0,
         0,
         '1',
         0,
         VNCODCLI,
         0,
         0,
         0,
         0,
         SYSDATE,
         102,
         'S',
         SYSDATE);
    ELSE
      UPDATE PCNFSAID
         SET SITUACAOCTE = 102, ESPECIE = 'CO'
       WHERE NUMNOTA = I
         AND SERIE = TO_CHAR(P_SERIE)
         AND CODFILIAL = P_CODFILIAL;
    END IF;
  END LOOP;
  COMMIT;
END;