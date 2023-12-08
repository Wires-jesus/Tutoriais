CREATE OR REPLACE PROCEDURE NFE_INUTILIZARNUMERACAO(P_CODFILIAL           VARCHAR2,
                                                    P_DTHORAPROCESSAMENTO VARCHAR2,
                                                    P_NUMINICIAL          NUMBER,
                                                    P_NUMFINAL            NUMBER,
                                                    P_SERIE               NUMBER,
                                                    P_ANO                 NUMBER,
                                                    P_JUSTIFICATIVA       VARCHAR2,
                                                    P_PROTOCOLO           VARCHAR2,
                                                    P_AMBIENTE            VARCHAR2,
                                                    P_CODUSUARIO          NUMBER,
                                                    P_TIPOMOV             VARCHAR2 DEFAULT 'S') IS
  VNPROXNUMTRANSVENDA PCNFSAID.NUMTRANSVENDA%TYPE;
  VNPROXNUMTRANSENT   PCNFENT.NUMTRANSENT%TYPE;
  VNCODCLI            PCNFSAID.CODCLI%TYPE;
  VNCODFORNEC         PCNFENT.CODFORNEC%TYPE;
  VNTOTAL             NUMBER;
  VPREFATURAMENTO     VARCHAR2(1);
  V_DTHORAPROCESSAMENTO DATE;

  procedure GRAVAR_PCNFSAID(P_NUMTRANSVENDA_INTERNO       NUMBER,
                            P_NUMNOTA_INTERNO             NUMBER,
                            P_DTHORAPROCESSAMENTO_INTERNO DATE,
                            P_CODCLI_INTERNO              NUMBER,
                            P_CODFILIAL_INTERNO           VARCHAR2,
                            P_SERIE_INTERNO               VARCHAR2,
                            P_PREFATURAMENTO              VARCHAR2) IS
  BEGIN
    IF P_PREFATURAMENTO = 'S' THEN
      INSERT INTO PCNFSAIDPREFAT
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
         SITUACAONFE,
         DTLANCTO,
         NOTADUPLIQUESVC)
      VALUES
        (P_NUMTRANSVENDA_INTERNO,
         P_NUMNOTA_INTERNO,
         TO_CHAR(P_SERIE_INTERNO),
         'NF',
         599,
         0,
         TRUNC(P_DTHORAPROCESSAMENTO_INTERNO),
         TRUNC(P_DTHORAPROCESSAMENTO_INTERNO),
         0,
         0,
         0,
         'INUTILIZAÇÃO DE NÚMERO',
         P_CODCLI_INTERNO,
         0,
         P_CODFILIAL_INTERNO,
         P_CODFILIAL_INTERNO,
         0,
         0,
         0,
         0,
         0,
         0,
         0,
         '1',
         0,
         P_CODCLI_INTERNO,
         0,
         0,
         0,
         0,
         102,
         SYSDATE,
         'S');
    ELSE

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
         SITUACAONFE,
         DTLANCTO,
         NOTADUPLIQUESVC)
      VALUES
        (P_NUMTRANSVENDA_INTERNO,
         P_NUMNOTA_INTERNO,
         TO_CHAR(P_SERIE_INTERNO),
         'NF',
         599,
         0,
         TRUNC(P_DTHORAPROCESSAMENTO_INTERNO),
         TRUNC(P_DTHORAPROCESSAMENTO_INTERNO),
         0,
         0,
         0,
         'INUTILIZAÇÃO DE NÚMERO',
         P_CODCLI_INTERNO,
         0,
         P_CODFILIAL_INTERNO,
         P_CODFILIAL_INTERNO,
         0,
         0,
         0,
         0,
         0,
         0,
         0,
         '1',
         0,
         P_CODCLI_INTERNO,
         0,
         0,
         0,
         0,
         102,
         SYSDATE,
         'S');

    END IF;

  END;
BEGIN

  V_DTHORAPROCESSAMENTO := TO_DATE(P_DTHORAPROCESSAMENTO, 'DD/MM/YYYY'); 
  SELECT NVL(COUNT(1), 0)
    INTO VNTOTAL
    FROM PCINUTILIZACAONFE
   WHERE CODFILIAL = P_CODFILIAL
     AND P_NUMINICIAL BETWEEN NUMNOTAINICIAL AND NUMNOTAFINAL
     AND P_NUMFINAL BETWEEN NUMNOTAINICIAL AND NUMNOTAFINAL
     AND SERIE = P_SERIE
     AND AMBIENTE = P_AMBIENTE;

  IF VNTOTAL = 0 THEN

    INSERT INTO PCINUTILIZACAONFE
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

  -- PARTE DA SAIDA 
  IF P_TIPOMOV = 'S' THEN

    SELECT CODCLI INTO VNCODCLI FROM PCFILIAL WHERE CODIGO = P_CODFILIAL;

    VNTOTAL := 0;

    FOR I IN P_NUMINICIAL .. P_NUMFINAL LOOP

      SELECT SUM(QT), MAX(PREFTURAMENTO)
        INTO VNTOTAL, VPREFATURAMENTO
        FROM (SELECT COUNT(*) QT, MAX('S') PREFTURAMENTO
                FROM PCNFSAIDPREFAT, PCFILIAL
               WHERE PCNFSAIDPREFAT.NUMNOTA = I
                 AND NVL(PCNFSAIDPREFAT.CODFILIALNF,
                         PCNFSAIDPREFAT.CODFILIAL) = PCFILIAL.CODIGO
                 AND SERIE = TO_CHAR(P_SERIE)
                 AND ESPECIE <> 'NS'
                 AND PCFILIAL.CODIGO = P_CODFILIAL
                 AND SUBSTR(TO_CHAR(PCNFSAIDPREFAT.DTSAIDA, 'YYYY'), 3, 2) =
                     SUBSTR(LPAD(TO_CHAR(P_ANO), 4, '0'), 3, 2)
                 AND PCNFSAIDPREFAT.DTSAIDA >= TRUNC(PCFILIAL.DTUTILIZANFE)
              UNION ALL
              SELECT COUNT(*) QT, MAX('N') PREFTURAMENTO
                FROM PCNFSAID, PCFILIAL
               WHERE PCNFSAID.NUMNOTA = I
                 AND NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL) =
                     PCFILIAL.CODIGO
                 AND SERIE = TO_CHAR(P_SERIE)
                 AND ESPECIE <> 'NS'
                 AND PCFILIAL.CODIGO = P_CODFILIAL
                 AND SUBSTR(TO_CHAR(PCNFSAID.DTSAIDA, 'YYYY'), 3, 2) =
                     SUBSTR(LPAD(TO_CHAR(P_ANO), 4, '0'), 3, 2)
                 AND PCNFSAID.DTSAIDA >= TRUNC(PCFILIAL.DTUTILIZANFE));

      IF VNTOTAL = 0 THEN

        SELECT NVL(PROXNUMTRANSVENDA, 1)
          INTO VNPROXNUMTRANSVENDA
          FROM PCCONSUM
           FOR UPDATE;

        UPDATE PCCONSUM
           SET PROXNUMTRANSVENDA = NVL(PROXNUMTRANSVENDA, 1) + 1;

        IF (VPREFATURAMENTO = 'S') THEN
          INSERT INTO PCNFBASEPREFAT
            (NUMTRANSVENDA,
             ALIQUOTA,
             VLBASE,
             VLICMS,
             TIPO,
             CODFISCAL,
             CODCONT)
          VALUES
            (VNPROXNUMTRANSVENDA, 0, 0, 0, '1', 5949, 0);

        ELSE

          INSERT INTO PCNFBASE
            (NUMTRANSVENDA,
             ALIQUOTA,
             VLBASE,
             VLICMS,
             TIPO,
             CODFISCAL,
             CODCONT)
          VALUES
            (VNPROXNUMTRANSVENDA, 0, 0, 0, '1', 5949, 0);
        END IF;

        GRAVAR_PCNFSAID(VNPROXNUMTRANSVENDA,
                        I,
                        V_DTHORAPROCESSAMENTO,
                        VNCODCLI,
                        P_CODFILIAL,
                        P_SERIE,
                        VPREFATURAMENTO);

      ELSE
        IF VPREFATURAMENTO = 'S' THEN

          UPDATE PCNFSAIDPREFAT
             SET SITUACAONFE = 102, ESPECIE = 'NF'
           WHERE NUMNOTA = I
             AND SERIE = TO_CHAR(P_SERIE)
             AND NVL(CODFILIALNF, CODFILIAL) = P_CODFILIAL
             AND ESPECIE <> 'NS';
        ELSE

          UPDATE PCNFSAID
             SET SITUACAONFE = 102, ESPECIE = 'NF'
           WHERE NUMNOTA = I
             AND SERIE = TO_CHAR(P_SERIE)
             AND NVL(CODFILIALNF, CODFILIAL) = P_CODFILIAL
             AND ESPECIE <> 'NS';
        END IF;
      END IF;
    END LOOP;

    -- PARTE DA ENTRADA 
  ELSE
    SELECT CODFORNEC
      INTO VNCODFORNEC
      FROM PCFILIAL
     WHERE CODIGO = P_CODFILIAL;

    VNTOTAL := 0;

    FOR I IN P_NUMINICIAL .. P_NUMFINAL LOOP

      SELECT COUNT(1)
        INTO VNTOTAL
        FROM PCNFENT, PCFILIAL
       WHERE PCNFENT.NUMNOTA = I
         AND NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = PCFILIAL.CODIGO
         AND SERIE = TO_CHAR(P_SERIE)
         AND ESPECIE <> 'NS'
         AND PCFILIAL.CODIGO = P_CODFILIAL
         AND PCNFENT.DTENT >= TRUNC(PCFILIAL.DTUTILIZANFE);

      IF VNTOTAL = 0 THEN

        SELECT NVL(PROXNUMTRANSENT, 1)
          INTO VNPROXNUMTRANSENT
          FROM PCCONSUM
           FOR UPDATE;

        UPDATE PCCONSUM SET PROXNUMTRANSENT = NVL(PROXNUMTRANSENT, 1) + 1;

        INSERT INTO PCNFBASE
          (NUMTRANSENT, ALIQUOTA, VLBASE, VLICMS, TIPO, CODFISCAL, CODCONT)
        VALUES
          (VNPROXNUMTRANSENT, 0, 0, 0, '1', 1949, 0);

        INSERT INTO PCNFENT
          (NUMTRANSENT,
           NUMNOTA,
           SERIE,
           ESPECIE,
           CODFISCAL,
           VLTOTAL,
           DTEMISSAO,
           DTENT,
           VLST,
           BASEICST,
           VLDESCONTO,
           OBS,
           CODFORNEC,
           CODCONT,
           CODFILIAL,
           CODFILIALNF,
           VLIPI,
           VLBASEIPI,
           VLFRETE,
           VLOUTRAS,
           TIPODESCARGA,
           PERBASEREDOUTRASDESP,
           CODFORNECNF,
           CODFISCALFRETE,
           CODFISCALOUTRASDESP,
           PERCICMFRETE,
           ALIQICMOUTRASDESP,
           SITUACAONFE,
           DTLANCTO,
           GERANFVENDA,
           NOTADUPLIQUESVC)
        VALUES
          (VNPROXNUMTRANSENT,
           I,
           TO_CHAR(P_SERIE),
           'NF',
           599,
           0,
           TRUNC(V_DTHORAPROCESSAMENTO),
           TRUNC(V_DTHORAPROCESSAMENTO),
           0,
           0,
           0,
           'INUTILIZAÇÃO DE NÚMERO',
           VNCODFORNEC,
           0,
           P_CODFILIAL,
           P_CODFILIAL,
           0,
           0,
           0,
           0,
           '1',
           0,
           VNCODFORNEC,
           0,
           0,
           0,
           0,
           102,
           SYSDATE,
           'S',
           'S');
      ELSE
        UPDATE PCNFENT
           SET SITUACAONFE = 102, ESPECIE = 'NF'
         WHERE NUMNOTA = I
           AND SERIE = TO_CHAR(P_SERIE)
           AND NVL(CODFILIALNF, CODFILIAL) = P_CODFILIAL
           AND ESPECIE <> 'NS';
      END IF;
    END LOOP;
  END IF;
  COMMIT;

END;