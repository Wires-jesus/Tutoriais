CREATE OR REPLACE PROCEDURE NFCE_INUTILIZARNUMERACAO
(
   P_CODFILIAL           VARCHAR2
  ,P_DTHORAPROCESSAMENTO DATE
  ,P_NUMINICIAL          NUMBER
  ,P_NUMFINAL            NUMBER
  ,P_SERIE               NUMBER
  ,P_ANO                 NUMBER
  ,P_JUSTIFICATIVA       VARCHAR2
  ,P_PROTOCOLO           VARCHAR2
  ,P_AMBIENTE            VARCHAR2
  ,P_CODUSUARIO          NUMBER
  ,P_TIPOMOV             VARCHAR2 DEFAULT 'S'
  ,P_CAIXA               NUMBER DEFAULT NULL
) IS
   VNPROXNUMTRANSVENDA PCNFSAID.NUMTRANSVENDA%TYPE;
   VNPROXNUMTRANSENT   PCNFENT.NUMTRANSENT%TYPE;
   VNCODCLI            PCNFSAID.CODCLI%TYPE;
   VNCODFORNEC         PCNFENT.CODFORNEC%TYPE;
   VNTOTAL             NUMBER;
BEGIN

   SELECT NVL(COUNT(1) ,0)
   INTO   VNTOTAL
   FROM   PCINUTILIZACAONFCE
   WHERE  CODFILIAL = P_CODFILIAL
   AND    P_NUMINICIAL BETWEEN NUMNOTAINICIAL AND NUMNOTAFINAL
   AND    P_NUMFINAL BETWEEN NUMNOTAINICIAL AND NUMNOTAFINAL
   AND    SERIE = P_SERIE
   AND    AMBIENTE = P_AMBIENTE;

   IF VNTOTAL = 0 THEN

      INSERT INTO PCINUTILIZACAONFCE
         (CODFILIAL
         ,DTHORAPROCESSAMENTO
         ,JUSTIFICATIVA
         ,AMBIENTE
         ,PROTOCOLOINUTILIZACAO
         ,NUMNOTAINICIAL
         ,NUMNOTAFINAL
         ,SERIE
         ,ANO
         ,CODUSUARIO
         ,NUMCAIXA
         ,DATA)
      VALUES
         (P_CODFILIAL
         ,P_DTHORAPROCESSAMENTO
         ,P_JUSTIFICATIVA
         ,P_AMBIENTE
         ,P_PROTOCOLO
         ,P_NUMINICIAL
         ,P_NUMFINAL
         ,P_SERIE
         ,P_ANO
         ,P_CODUSUARIO
         ,P_CAIXA
         ,TRUNC(P_DTHORAPROCESSAMENTO));
   END IF;

-- PARTE DA SAIDA
   IF P_TIPOMOV = 'S' THEN

      SELECT CODCLI
      INTO VNCODCLI
      FROM PCFILIAL
      WHERE CODIGO = P_CODFILIAL;

      VNTOTAL := 0;

      FOR I IN P_NUMINICIAL .. P_NUMFINAL LOOP

         SELECT COUNT(1)
         INTO   VNTOTAL
         FROM   PCNFSAID,PCFILIAL
         WHERE  PCNFSAID.NUMNOTA = I
         AND    NVL(PCNFSAID.CODFILIALNF,PCNFSAID.CODFILIAL) = PCFILIAL.CODIGO
         AND    SERIE = TO_CHAR(P_SERIE)
         AND    PCFILIAL.CODIGO = P_CODFILIAL
         AND    SUBSTR(TO_CHAR(PCNFSAID.DTSAIDA, 'YYYY' ), 3,2) = SUBSTR( LPAD( TO_CHAR(P_ANO),4,'0' ) ,3 , 2)
         AND    PCNFSAID.DTSAIDA >= TRUNC(PCFILIAL.DTUTILIZANFE)
         AND    NVL(PCNFSAID.DOCEMISSAO,'X') = 'CE'
         AND    SITUACAONFE = 102;

         IF VNTOTAL = 0 THEN

            SELECT NVL(PROXNUMTRANSVENDA ,1)
            INTO   VNPROXNUMTRANSVENDA
            FROM   PCCONSUM
            FOR    UPDATE;

            UPDATE PCCONSUM SET
                   PROXNUMTRANSVENDA = NVL(PROXNUMTRANSVENDA ,1) + 1;

            INSERT INTO PCNFBASE (
                NUMTRANSVENDA
               ,ALIQUOTA
               ,VLBASE
               ,VLICMS
               ,TIPO
               ,CODFISCAL
               ,CODCONT
            ) VALUES (
                VNPROXNUMTRANSVENDA
               ,0
               ,0
               ,0
               ,'1'
               ,5949
               ,0
            );

            INSERT INTO PCNFSAID (
                 NUMTRANSVENDA
                ,NUMNOTA
                ,SERIE
                ,ESPECIE
                ,CODFISCAL
                ,VLTOTAL
                ,DTENTREGA
                ,DTSAIDA
                ,ICMSRETIDO
                ,BCST
                ,VLDESCONTO
                ,OBS
                ,CODCLI
                ,CODCONT
                ,CODFILIAL
                ,CODFILIALNF
                ,VLIPI
                ,VLBASEIPI
                ,VLFRETE
                ,VLOUTRASDESP
                ,CODPRACA
                ,CAIXA
                ,CODUSUR
                ,TIPOVENDA
                ,PERBASEREDOUTRASDESP
                ,CODCLINF
                ,CODFISCALFRETE
                ,CODFISCALOUTRASDESP
                ,PERCICMFRETE
                ,ALIQICMOUTRASDESP
                ,SITUACAONFE
                ,DTLANCTO
                ,NOTADUPLIQUESVC
                ,NUMCAIXAFISCAL
                ,DOCEMISSAO
                ,ROTINALANC
                ,ROTINACAD
            ) VALUES (
                 VNPROXNUMTRANSVENDA
                ,I
                ,TO_CHAR(P_SERIE)
                ,'NF'
                ,599
                ,0
                ,TRUNC(P_DTHORAPROCESSAMENTO)
                ,TRUNC(P_DTHORAPROCESSAMENTO)
                ,0
                ,0
                ,0
                ,'INUTILIZAÇÃO DE NÚMERO'
                ,VNCODCLI
                ,0
                ,P_CODFILIAL
                ,P_CODFILIAL
                ,0
                ,0
                ,0
                ,0
                ,0
                ,P_CAIXA
                ,0
                ,'1'
                ,0
                ,VNCODCLI
                ,0
                ,0
                ,0
                ,0
                ,102
                ,SYSDATE
                ,'N'
                ,P_SERIE
                ,'CE'
                ,'2097'
                ,'2097'
            );
         ELSE
     
       UPDATE PCNFSAID SET
          CAIXA = P_CAIXA,
          DOCEMISSAO = 'CE',  
          SITUACAONFE = 102,
          ESPECIE = 'NF',
          NUMCAIXAFISCAL = TO_NUMBER(SERIE)
      WHERE NUMNOTA = I
        AND SERIE = TO_CHAR(P_SERIE)
        AND NVL(DOCEMISSAO,'X') = 'CE'
        AND CODFILIAL = P_CODFILIAL;
        
         END IF;
      END LOOP;
   END IF;
 COMMIT;

END; 