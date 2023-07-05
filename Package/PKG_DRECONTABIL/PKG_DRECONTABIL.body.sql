CREATE OR REPLACE PACKAGE BODY PKG_DRECONTABIL IS

   FUNCTION FNC_RETORNADADOS (
      PCODFILIAL                IN   VARCHAR2,
      PCODPLANOCONTA            IN   NUMBER,
      PCODDRE                   IN   NUMBER,
      PMESINI                   IN   NUMBER,
      PMESFIM                   IN   NUMBER,
      PANO                      IN   NUMBER,
      PCONSOLIDAR               IN   VARCHAR2,
      PAGRUPAFILIAL             IN   VARCHAR2,
      PCONSIDERARSALDOINI       IN   VARCHAR2,
      PANTESDOENCERRAMENTO      IN   VARCHAR2,
      PANALISEHORIZONTAL        IN   VARCHAR2,
      PANALISEVERTICAL          IN   VARCHAR2,
      PEXIBIRCONTASANALITICAS   IN   VARCHAR2,
      PEXIBIRCONTASSALDOZERO    IN   VARCHAR2,
      PEXIBIRCODREDUZIDO        IN   VARCHAR2,
      PEXIBIRRATEIO_RECEITA_CUSTO IN VARCHAR2,
      PSALDOANOANTERIOR         IN VARCHAR2 DEFAULT 'N',
      PDATAINI_ESP              IN DATE DEFAULT NULL, 
      PDATAFIM_ESP              IN DATE DEFAULT NULL)
      RETURN DRECONTABIL_DATATABLE IS                                                                               /*PARALLEL_ENABLE PIPELINED*/
/****************************************************************************
  Declaração de variáveis
*****************************************************************************/
  --Declara Valores de Saí­da
  OUTROW DRECONTABIL_DATAROW := DRECONTABIL_DATAROW(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                                                    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,NULL, NULL);
  --Arrays
  VRETORNO                  DRECONTABIL_DATATABLE := DRECONTABIL_DATATABLE ();

  TYPE CONSULTA IS RECORD (CODDEMONST       PCCONFIGDRE.CODDEMONST%TYPE,
                           CODCONFIG        PCCONFIGDRE.CODCONFIG %TYPE,
                           ORDEM            PCCONFIGDRE.ORDEM%TYPE,
                           DESC_OPERACAO    PCCONFIGDRE.DESC_OPERACAO%TYPE,
                           TIPORESULTADO    PCCONFIGDRE.TIPORESULTADO%TYPE,
                           REGRA            VARCHAR2(15),
                           VALORMANUAL      PCCONFIGDRE.VALORMANUAL%TYPE,
                           CODCONTAREDUZIDO PCCONFIGDRE.CODCONTAREDUZIDO%TYPE,
                           CODCONFIGPAI     PCCONFIGDRE.CODCONFIGPAI%TYPE,
                           DESC_RESULTADO   PCCONFIGDRE.DESC_RESULTADO%TYPE,
                           SALDODFC         PCCONFIGDRE.SALDODFC%TYPE,
                           NATUREZALANC     PCCONFIGDRE.NATUREZALANC%TYPE,
					            	   CODCONTA_PC      PCMODELOPC.CODCONTA_PC%TYPE,
                           RECEBELANCTO     PCMODELOPC.RECEBE_LANCTO%TYPE,
                           NATUREZACONTA    PCMODELOPC.NATUREZA%TYPE,
                           TIPOCONTA        PCMODELOPC.TIPOCONTA%TYPE);

  DRE_ANALITICO CONSULTA; --SERÁ SETADO OS VALORES DO SQL FILHO AQUI.

  CURSORANALITICO SYS_REFCURSOR;

  TYPE RATEIO_CONTAS IS RECORD(
    CODREDUZIDO_PC  VARCHAR(12),
    CODPLANOCONTA   NUMBER(5),
    CODIGO          VARCHAR2(40),
    DESCRICAO       VARCHAR2(40),
    VALOR           NUMBER(22,2),
    PERCENTUAL      NUMBER(22,2)
  );

  RATEIO RATEIO_CONTAS;

  RATEIOCURSOR SYS_REFCURSOR;

  --VARIÁVEIS AUXILIARES
  V_SQL                     VARCHAR2(30000);
  V_SQL_RATEIO              VARCHAR2(30000);
  VS_ERRO                   VARCHAR2(500);
  VN_POSICAO                NUMBER(10) := 0;
  VN_POSICAO_EM_ALTERACAO   NUMBER(10) := 0;
  VN_POSICAOATUAL           NUMBER(10) := 0;
  VN_VALOR                  NUMBER(22, 2);
  VN_VALORANTERIOR          NUMBER(22, 2);
  VN_VALORCONTAANALITICA    NUMBER(22, 2);
  VN_VALORCONTAANALITICAANT NUMBER(22, 2);
  VN_CODCONFIGPAI           NUMBER(5);
  VS_TIPOPAI                VARCHAR2(1);
  VS_TIPOREGRA              VARCHAR2(1);
  VS_NATUREZA               VARCHAR2(1);
  VS_CODCONTAANALITICA      VARCHAR2(40);
  VS_MASCARA_PC             VARCHAR2(40);
  VCONTCONTASANALITICAS     NUMBER;
  VCONTCONTASPAIS           NUMBER;
  VN_VLRTOTAL               NUMBER(22,2);
  VN_VLRSUBTOTAL            NUMBER(22,2);
  VN_VLRSUBTOTALANTERIOR    NUMBER(22,2);
  VN_VLRBASE                NUMBER(22,2);
  VS_ESTRUTURADFC           VARCHAR2(1);
  VS_NOTAEXPLICATIVA        CLOB;

  /****************************************************************************
  Limpa Variaveis
  *****************************************************************************/
  PROCEDURE LIMPAVARIAVEIS IS
  BEGIN
     OUTROW.ORDEM            := NULL;
     OUTROW.DESCRICAO        := NULL;
     OUTROW.VALOR            := NULL;
     OUTROW.TIPO             := NULL;
     OUTROW.RESULTADO        := NULL;
     OUTROW.ORDEMCONFIG      := NULL;
     OUTROW.SEMREGRA         := NULL;
     OUTROW.BASEVERTICAL     := NULL;
     OUTROW.VALORBASE        := NULL;
     OUTROW.PERCVERTICAL     := NULL;
     OUTROW.VALORANTERIOR    := NULL;
     OUTROW.CODCONFIG        := NULL;
     OUTROW.CODCONFIGPAI     := NULL;
     OUTROW.NOTAEXPLICATIVA  := NULL;
     OUTROW.CODCONTA_PC      := NULL;
     OUTROW.RECEBELANCTO     := NULL;
     OUTROW.NATUREZACONTA    := NULL;
     OUTROW.TIPOCONTA        := NULL;
  END LIMPAVARIAVEIS;

  
  
  
  /****************************************************************************
    FUNÇÃO: RETORNA O SALDO DA CONTA SEM SER DFC
  *****************************************************************************/
  FUNCTION CALCULASALDOTOTAL (PCODREDUZIDO     IN  VARCHAR2,
                              PMESINI          IN  NUMBER,
                              PMESFIM          IN  NUMBER,
                              PANO             IN  NUMBER,
                              PDATAINI         IN DATE,
                              PDATAFIM         IN DATE,
                              PVLRENCERRAMENTO OUT NUMBER,
                              PNATUREZA        OUT VARCHAR2)

     RETURN NUMBER IS

     VS_CODREDUZIDO            VARCHAR2 (50);
     VN_SALDOTOTAL             NUMBER (22, 2);
     VN_SALDOTOTENCERRAMENTO   NUMBER (22, 2);
     VS_NATUREZA               VARCHAR2 (1);
     V_SQLAUX2                 VARCHAR2 (10000);
     V_RECEBE_LANCTO CHAR(1);
     V_CODCONTA VARCHAR2(50);
  BEGIN
     IF (PDATAINI IS  NULL) OR ((EXTRACT(DAY FROM PDATAINI) = 1) AND  (EXTRACT(DAY FROM LAST_DAY(PDATAFIM)) = EXTRACT(DAY FROM PDATAFIM)) ) THEN
       V_SQLAUX2 := 'SELECT S.CODREDUZIDO_PC,
                            M.NATUREZA,
                            SUM(S.VALORCREDITO - S.VALORDEBITO) AS SALDOTOTAL,
                            SUM(S.VLRCREENCERRAMENTO - S.VLRDEBENCERRAMENTO) AS SALDOTOTENCERRAMENTO
                     FROM PCSALDO S, PCMODELOPC M
                     WHERE S.CODREDUZIDO_PC = M.CODREDUZIDO_PC
                     AND   S.CODPLANOCONTA  = M.CODPLANOCONTA
                     AND   S.MES BETWEEN :MESINI AND :MESFIM
                     AND   S.CODREDUZIDO_PC = :CODREDUZIDO_PC';
  
       IF PCONSOLIDAR = 'S' THEN
          V_SQLAUX2 := V_SQLAUX2 || '   AND S.CODFILIAL IN (SELECT CODFILIAL
                                                            FROM PCCONFFILIAL
                                                            WHERE CODGRUPOFILIAL = :PCODFILIAL
                                                            AND   ANO            = :PANO) ';
       ELSE
          IF PAGRUPAFILIAL = 'N' THEN
             V_SQLAUX2 := V_SQLAUX2 || ' AND S.CODFILIAL IN ( :PCODFILIAL ) ';
          ELSE
             V_SQLAUX2 := V_SQLAUX2 || ' AND S.CODFILIAL IN (SELECT V.CODIGO
                                                             FROM V_CTBFILIAL V, PCCONFFILIAL C
                                                             WHERE SUBSTR(REPLACE(REPLACE(REPLACE(V.CGC, ''.''), ''/''), ''-''), 1, 8) LIKE
                                                                   (SELECT SUBSTR(REPLACE(REPLACE(REPLACE(F.CGC, ''.''), ''/''), ''-''), 1, 8)
                                                                    FROM V_CTBFILIAL F
                                                                    WHERE F.CODIGO = :PCODFILIAL
                                                                    AND   F.CODPLANOCONTA = ' || PCODPLANOCONTA ||' AND ROWNUM = 1) || ''%''
                                                             AND V.CODPLANOCONTA = ' || PCODPLANOCONTA || '
                                                             AND V.CODIGO = C.CODFILIAL
                                                             AND C.ANO = ' || PANO || '
                                                             AND C.CODGRUPOFILIAL = V.CODGRUPOFILIAL
                                                             AND V.CODGRUPOFILIAL = (SELECT CODGRUPOFILIAL FROM PCCONFFILIAL WHERE CODFILIAL = :PCODFILIAL  AND ANO =  ' || PANO || '))';
          END IF;
       END IF;
  
       V_SQLAUX2 := V_SQLAUX2 || ' AND  S.CODPLANOCONTA = :CODPLANOCONTA
                                   AND  S.ANO = :ANO
                                   GROUP BY S.CODREDUZIDO_PC, M.NATUREZA';
  
       -- Troca o parâmetro de filial pela stingr repassada no método
       PKG_CTBFUNCOESCONTEIS.TRATARMULTIFILIAL(PCODFILIAL,':PCODFILIAL', FALSE, V_SQLAUX2);
       
       
  
       IF PCONSOLIDAR = 'S' THEN
  --        EXECUTE IMMEDIATE V_SQLAUX2 INTO VS_CODREDUZIDO, VS_NATUREZA, VN_SALDOTOTAL, VN_SALDOTOTENCERRAMENTO
  --                                    USING PMESINI, PMESFIM, PCODREDUZIDO, PCODFILIAL, PANO, PCODPLANOCONTA, PANO;
          EXECUTE IMMEDIATE V_SQLAUX2 INTO VS_CODREDUZIDO, VS_NATUREZA, VN_SALDOTOTAL, VN_SALDOTOTENCERRAMENTO
                                      USING PMESINI, PMESFIM, PCODREDUZIDO, PANO, PCODPLANOCONTA, PANO;
       ELSE
  --        EXECUTE IMMEDIATE V_SQLAUX2 INTO VS_CODREDUZIDO, VS_NATUREZA, VN_SALDOTOTAL, VN_SALDOTOTENCERRAMENTO
  --                                    USING PMESINI, PMESFIM, PCODREDUZIDO, PCODFILIAL, PCODPLANOCONTA, PANO;
          EXECUTE IMMEDIATE V_SQLAUX2 INTO VS_CODREDUZIDO, VS_NATUREZA, VN_SALDOTOTAL, VN_SALDOTOTENCERRAMENTO
                                      USING PMESINI, PMESFIM, PCODREDUZIDO, PCODPLANOCONTA, PANO;
       END IF;
     ELSE
     
     IF PCODREDUZIDO IS NOT NULL THEN
        SELECT M.RECEBE_LANCTO , M.CODCONTA_PC, NATUREZA
          INTO V_RECEBE_LANCTO, V_CODCONTA, VS_NATUREZA
        FROM PCMODELOPC M
        WHERE M.CODREDUZIDO_PC = PCODREDUZIDO
        AND M.CODPLANOCONTA = PCODPLANOCONTA;
   
        END IF;
       
       V_SQLAUX2 := ' SELECT 
                                 SUM(DECODE(L.NATUREZA, ''C'', L.VALOR, 0)) -
                                 SUM(DECODE(L.NATUREZA, ''D'', L.VALOR, 0)) AS SALDOTOTAL,
                                 SUM(DECODE(L.TIPO_LANCAMENTO,
                                            ''E'',
                                            DECODE(L.NATUREZA, ''C'', L.VALOR, 0),
                                            0)) - SUM(DECODE(L.TIPO_LANCAMENTO,
                                                             ''E'',
                                                             DECODE(L.NATUREZA, ''D'', L.VALOR, 0),
                                                             0)) AS SALDOTOTENCERRAMENTO
                          
                            FROM PCLANCAMENTO L, PCMODELOPC M
                           WHERE L.DTLANC BETWEEN :DATA1 AND :DATA2
                             AND M.CODREDUZIDO_PC = L.CODREDUZIDO_PC
                             AND M.CODPLANOCONTA = L.CODPLANOCONTA
                             AND L.CODPLANOCONTA = ' || PCODPLANOCONTA ||' ';
                             
      IF V_RECEBE_LANCTO  = 'S' THEN 
       
            V_SQLAUX2 := V_SQLAUX2 || ' AND L.CODREDUZIDO_PC = :CODCONTA ';
            V_CODCONTA := PCODREDUZIDO;
      ELSE
           V_SQLAUX2 := V_SQLAUX2 || ' AND M.CODCONTA_PC LIKE :CODCONTA || ''%'' '  ;
      END IF; 
                            
      V_SQLAUX2 := V_SQLAUX2 || ' AND L.MES BETWEEN ' || PMESINI || ' AND ' || PMESFIM || '
                             AND L.ANO = ' || PANO || '';
                             
      IF PCONSOLIDAR = 'S' THEN
          V_SQLAUX2 := V_SQLAUX2 || '   AND L.CODFILIAL IN (SELECT CODFILIAL
                                                            FROM PCCONFFILIAL
                                                            WHERE CODGRUPOFILIAL = :PCODFILIAL
                                                            AND   ANO            = ' || PANO || ') ';
       ELSE
          IF PAGRUPAFILIAL = 'N' THEN
             V_SQLAUX2 := V_SQLAUX2 || ' AND L.CODFILIAL IN ( :PCODFILIAL ) ';
          ELSE
             V_SQLAUX2 := V_SQLAUX2 || ' AND L.CODFILIAL IN (SELECT V.CODIGO
                                                             FROM V_CTBFILIAL V, PCCONFFILIAL C
                                                             WHERE SUBSTR(REPLACE(REPLACE(REPLACE(V.CGC, ''.''), ''/''), ''-''), 1, 8) LIKE
                                                                   (SELECT SUBSTR(REPLACE(REPLACE(REPLACE(F.CGC, ''.''), ''/''), ''-''), 1, 8)
                                                                    FROM V_CTBFILIAL F
                                                                    WHERE F.CODIGO = :PCODFILIAL
                                                                    AND   F.CODPLANOCONTA = ' || PCODPLANOCONTA ||' AND ROWNUM = 1) || ''%''
                                                             AND V.CODPLANOCONTA = ' || PCODPLANOCONTA || '
                                                             AND V.CODIGO = C.CODFILIAL
                                                             AND C.ANO = ' || PANO || '
                                                             AND C.CODGRUPOFILIAL = V.CODGRUPOFILIAL
                                                             AND V.CODGRUPOFILIAL = (SELECT CODGRUPOFILIAL FROM PCCONFFILIAL WHERE CODFILIAL = :PCODFILIAL  AND ANO =  ' || PANO || '))';
          END IF;
       END IF;                             
       -- Troca o parâmetro de filial pela stingr repassada no método
       PKG_CTBFUNCOESCONTEIS.TRATARMULTIFILIAL(PCODFILIAL,':PCODFILIAL', FALSE, V_SQLAUX2);
       

        
        EXECUTE IMMEDIATE V_SQLAUX2 INTO VN_SALDOTOTAL, VN_SALDOTOTENCERRAMENTO
                                      USING PDATAINI, PDATAFIM, V_CODCONTA;
        
     END IF;  
     
     IF VN_SALDOTOTAL IS NULL THEN
      VN_SALDOTOTAL := 0;
      VN_SALDOTOTENCERRAMENTO := 0;
     END IF; 
       
     VS_CODREDUZIDO   := V_CODCONTA;
     PVLRENCERRAMENTO    := VN_SALDOTOTENCERRAMENTO;
     PNATUREZA           := VS_NATUREZA;

     RETURN VN_SALDOTOTAL;
  EXCEPTION
     WHEN OTHERS THEN
        VN_SALDOTOTAL           := 0;
        VS_CODREDUZIDO          := '';
        VS_NATUREZA             := '';
        VN_SALDOTOTENCERRAMENTO := 0;

        PVLRENCERRAMENTO := VN_SALDOTOTENCERRAMENTO;
        PNATUREZA        := VS_NATUREZA;
        RETURN VN_SALDOTOTAL;
  END CALCULASALDOTOTAL;

  /****************************************************************************
    FUNÇÃO: RETORNA O SALDO DA DFC
  *****************************************************************************/
  FUNCTION CALCULASALDOTOTAL_DFC(PCODREDUZIDO     IN  VARCHAR2,
                                 PNATUREZA_DFC    IN VARCHAR2,
                                 PSALDO_DFC       IN NUMBER,
                                 PANO             IN NUMBER)

     RETURN NUMBER IS

     VS_NATUREZA               VARCHAR2(1);
     VN_VLRSALDOINICIAL        NUMBER(22, 2);
     VN_VALORDEBITO            NUMBER(22, 2);
     VN_VALORCREDITO           NUMBER(22, 2);
     VN_VALORDEBITO_T          NUMBER(22, 2);
     VN_VALORCREDITO_T         NUMBER(22, 2);
     V_SQLAUX2                 VARCHAR2(10000);
  BEGIN
     V_SQLAUX2 := 'SELECT CASE WHEN SUM(DECODE(NATUREZACONTRPARTIDA, ''D'', TOTDEB, TOTDEB*(-1))) > 0 THEN ''D'' ELSE ''C'' END NATUREZACONTRPARTIDA,
                            NVL(ABS(SUM(DECODE(NATUREZACONTRPARTIDA, ''D'', TOTDEB, TOTDEB*(-1)))),0) TOTDEB,
                            NVL(ABS(SUM(DECODE(NATUREZACONTRPARTIDA, ''D'', TOTCRE, TOTCRE*(-1)))),0) TOTCRE FROM (
                   SELECT CONTRAPARTIDA.NATUREZACONTRPARTIDA,
                          SUM(DECODE(L.NATUREZA, ''C'', L.VALOR, 0)) TOTDEB,
                          SUM(DECODE(L.NATUREZA, ''D'', L.VALOR, 0)) TOTCRE
                   FROM PCMODELOPC M,
                        PCLANCAMENTO L,
                        (SELECT      M1.NATUREZA NATUREZACONTRPARTIDA,
                                     NUMLANCTO,  ';

     IF (PCONSOLIDAR <> 'S') AND (PAGRUPAFILIAL <> 'S') THEN
       V_SQLAUX2 := V_SQLAUX2 || '   CODFILIAL,';
     END IF;

      V_SQLAUX2 := V_SQLAUX2 ||'     MAX(NUMSEQ) NUMSEQ,
                                     MES,
                                     ANO,
									 A.DTLANC
                                FROM PCLANCAMENTO A, PCMODELOPC M1
                               WHERE M1.CODPLANOCONTA = A.CODPLANOCONTA
                                 AND M1.CODREDUZIDO_PC = A.CODREDUZIDO_PC ';

      IF PCONSOLIDAR = 'S' THEN
        V_SQLAUX2 := V_SQLAUX2 || '   AND A.CODFILIAL IN (SELECT CODFILIAL
                                                          FROM PCCONFFILIAL
                                                          WHERE CODGRUPOFILIAL = :PCODFILIAL
                                                          AND   ANO            = :PANO) ';
     ELSE
        IF PAGRUPAFILIAL = 'N' THEN
           V_SQLAUX2 := V_SQLAUX2 || ' AND A.CODFILIAL IN ( :PCODFILIAL ) ';
        ELSE
           V_SQLAUX2 := V_SQLAUX2 || ' AND A.CODFILIAL IN (SELECT V.CODIGO
                                                           FROM V_CTBFILIAL V, PCCONFFILIAL C
                                                           WHERE SUBSTR(REPLACE(REPLACE(REPLACE(V.CGC, ''.''), ''/''), ''-''), 1, 8) LIKE
                                                                 (SELECT SUBSTR(REPLACE(REPLACE(REPLACE(F.CGC, ''.''), ''/''), ''-''), 1, 8)
                                                                  FROM V_CTBFILIAL F
                                                                  WHERE F.CODIGO = :PCODFILIAL
                                                                  AND   F.CODPLANOCONTA = ' || PCODPLANOCONTA ||' AND ROWNUM = 1) || ''%''
                                                           AND V.CODPLANOCONTA = ' || PCODPLANOCONTA || '
                                                           AND V.CODIGO = C.CODFILIAL
                                                           AND C.ANO = ' || PANO || '
                                                           AND C.CODGRUPOFILIAL = V.CODGRUPOFILIAL
                                                           AND V.CODGRUPOFILIAL = (SELECT CODGRUPOFILIAL FROM PCCONFFILIAL WHERE CODFILIAL = :PCODFILIAL  AND ANO =  ' || PANO || '))';
        END IF;
     END IF;

    V_SQLAUX2 := V_SQLAUX2 || '  AND A.CODPLANOCONTA = :PCODPLANOCONTA
                                 AND A.ANO = :PANO
                                 AND A.MES BETWEEN :PMESINI AND :PMESFIM
								 AND A.DTLANC BETWEEN TO_DATE(''01/''||TO_CHAR(' || PMESINI || ')||''/''||TO_CHAR(' || PANO || '),''DD/MM/YYYY'') AND LAST_DAY(TO_DATE(''01/''||TO_CHAR(' || PMESFIM || ')||''/''||TO_CHAR(' || PANO || '),''DD/MM/YYYY''))

                                 AND M1.COMPORDFC = ''S''
                                 --Agrupamento feito para forí§ar a somar a contrapartida de DFC somente uma vez
                                 GROUP BY M1.NATUREZA, NUMLANCTO, A.DTLANC, ';

    IF (PCONSOLIDAR <> 'S') AND (PAGRUPAFILIAL <> 'S') THEN
      V_SQLAUX2 := V_SQLAUX2 || '         CODFILIAL, ';
    END IF;

    V_SQLAUX2 := V_SQLAUX2 ||
                   '           MES, ANO ) CONTRAPARTIDA
                       WHERE M.CODPLANOCONTA = L.CODPLANOCONTA
                         AND M.CODREDUZIDO_PC = L.CODREDUZIDO_PC ';

     IF PCONSOLIDAR = 'S' THEN
        V_SQLAUX2 := V_SQLAUX2 || '   AND L.CODFILIAL IN (SELECT CODFILIAL
                                                          FROM PCCONFFILIAL
                                                          WHERE CODGRUPOFILIAL = :PCODFILIAL
                                                          AND   ANO            = :PANO) ';
     ELSE
        IF PAGRUPAFILIAL = 'N' THEN
           V_SQLAUX2 := V_SQLAUX2 || ' AND L.CODFILIAL IN ( :PCODFILIAL ) ';
        ELSE
           V_SQLAUX2 := V_SQLAUX2 || ' AND L.CODFILIAL IN (SELECT V.CODIGO
                                                           FROM V_CTBFILIAL V, PCCONFFILIAL C
                                                           WHERE SUBSTR(REPLACE(REPLACE(REPLACE(V.CGC, ''.''), ''/''), ''-''), 1, 8) LIKE
                                                                 (SELECT SUBSTR(REPLACE(REPLACE(REPLACE(F.CGC, ''.''), ''/''), ''-''), 1, 8)
                                                                  FROM V_CTBFILIAL F
                                                                  WHERE F.CODIGO = :PCODFILIAL
                                                                  AND   F.CODPLANOCONTA = ' || PCODPLANOCONTA ||' AND ROWNUM = 1) || ''%''
                                                           AND V.CODPLANOCONTA = ' || PCODPLANOCONTA || '
                                                           AND V.CODIGO = C.CODFILIAL
                                                           AND C.ANO = ' || PANO || '
                                                           AND C.CODGRUPOFILIAL = V.CODGRUPOFILIAL
                                                           AND V.CODGRUPOFILIAL = (SELECT CODGRUPOFILIAL FROM PCCONFFILIAL WHERE CODFILIAL = :PCODFILIAL AND ANO =  ' || PANO || '))';
        END IF;
     END IF;

   V_SQLAUX2 := V_SQLAUX2 || ' AND M.CODPLANOCONTA = :PCODPLANOCONTA
                               AND L.ANO = :PANO
                               AND L.MES BETWEEN :PMESINI AND :PMESFIM
							   AND L.DTLANC BETWEEN TO_DATE(''01/''||TO_CHAR(' || PMESINI || ')||''/''||TO_CHAR(' || PANO || '),''DD/MM/YYYY'') AND LAST_DAY(TO_DATE(''01/''||TO_CHAR(' || PMESFIM || ')||''/''||TO_CHAR(' || PANO || '),''DD/MM/YYYY''))
                               AND M.CODREDUZIDO_PC = :PCODREDUZIDO
                               AND CONTRAPARTIDA.MES = L.MES
                               AND CONTRAPARTIDA.ANO = L.ANO
							   AND CONTRAPARTIDA.DTLANC = L.DTLANC
                               AND CONTRAPARTIDA.NUMLANCTO = L.NUMLANCTO ';

   IF (PCONSOLIDAR <> 'S') AND (PAGRUPAFILIAL <> 'S') THEN
     V_SQLAUX2 := V_SQLAUX2 ||
                     '         AND CONTRAPARTIDA.CODFILIAL = L.CODFILIAL';
   END IF;

   V_SQLAUX2 := V_SQLAUX2 ||
                   '   AND CONTRAPARTIDA.NUMSEQ <> L.NUMSEQ
                             GROUP BY CONTRAPARTIDA.NATUREZACONTRPARTIDA )';
     -- Troca o parâmetro de filial pela stingr repassada no método
     PKG_CTBFUNCOESCONTEIS.TRATARMULTIFILIAL(PCODFILIAL,':PCODFILIAL', FALSE, V_SQLAUX2);

     IF PCONSOLIDAR = 'S' THEN
        EXECUTE IMMEDIATE V_SQLAUX2 INTO VS_NATUREZA, VN_VALORDEBITO, VN_VALORCREDITO
                                    USING PANO, PCODPLANOCONTA, PANO, PMESINI, PMESFIM,
                                          PANO, PCODPLANOCONTA, PANO, PMESINI, PMESFIM, PCODREDUZIDO;
     ELSE
        EXECUTE IMMEDIATE V_SQLAUX2 INTO VS_NATUREZA, VN_VALORDEBITO, VN_VALORCREDITO
                                    USING PCODPLANOCONTA, PANO, PMESINI, PMESFIM,
                                          PCODPLANOCONTA, PANO, PMESINI, PMESFIM, PCODREDUZIDO;
     END IF;

     IF DRE_ANALITICO.TIPORESULTADO = 'S' THEN
        RETURN F_FUNCOESCONTABEIS(PCODFILIAL, PCONSOLIDAR, PAGRUPAFILIAL, PCODPLANOCONTA, PMESINI,
                                                 PMESFIM, PANO, 'F_SALDOCONTA', PCODREDUZIDO,
                                                 VN_VALORDEBITO, VN_VALORCREDITO);

     ELSIF (DRE_ANALITICO.TIPORESULTADO = 'E') THEN
        RETURN VN_VALORDEBITO - VN_VALORCREDITO;

     ELSIF (DRE_ANALITICO.TIPORESULTADO = 'F') THEN
        RETURN VN_VALORDEBITO - VN_VALORCREDITO;
		
     ELSIF    PNATUREZA_DFC = 'A' THEN
        VN_VLRSALDOINICIAL := F_FUNCOESCONTABEIS(PCODFILIAL, PCONSOLIDAR, PAGRUPAFILIAL, PCODPLANOCONTA, PMESINI,
                                                 PMESFIM, PANO, 'F_SALDOCONTA', PCODREDUZIDO,
                                                 VN_VALORDEBITO_T, VN_VALORCREDITO_T);

        RETURN VN_VLRSALDOINICIAL + VN_VALORDEBITO - VN_VALORCREDITO;


     ELSIF NVL(PNATUREZA_DFC,'S') = 'S' THEN
        RETURN VN_VALORDEBITO - VN_VALORCREDITO;


     ELSIF PNATUREZA_DFC = 'C' THEN
       RETURN  VN_VALORDEBITO * -1;

     ELSIF PNATUREZA_DFC = 'D' THEN
       RETURN  VN_VALORCREDITO; 

     END IF;

  EXCEPTION
     WHEN OTHERS THEN
        RETURN 0;
  END CALCULASALDOTOTAL_DFC;

  /****************************************************************************
    FUNÇÃO: BUSCA VALORES
  *****************************************************************************/
  FUNCTION BUSCAVALOR(PCODREDUZIDO  IN VARCHAR2,
                      PTIPOSALDO    IN VARCHAR2,
                      PANO          IN NUMBER,
                      PNATUREZA_DFC IN VARCHAR2,
                      PSALDO_DFC    IN NUMBER,
                      PRETORNASALDOANTERIOR IN VARCHAR2,
                      PNATUREZA    OUT VARCHAR2,
                      PDATAINI IN DATE,
                      PDATAFIM IN DATE)
  RETURN NUMBER IS
    VN_MES                 NUMBER (2);
    VN_MESFIM                 NUMBER (2);
    VN_ANO NUMBER(4);
    VN_VALOR               NUMBER (22, 2);
    VN_VALORENCERRAMENTO   NUMBER (22, 2);
    VS_NATUREZA            VARCHAR2 (1);
    VN_SALDOACUMULADODFC   NUMBER(22,2);
    VD_DATAINI DATE;
    VD_DATAFIM DATE;
    VN_DIA NUMBER(2);
    
  BEGIN
     VN_VALORENCERRAMENTO := 0;
     VN_SALDOACUMULADODFC := 0;
     
     IF VS_ESTRUTURADFC = 'S' THEN
       
     IF PTIPOSALDO = 'I' THEN
       VN_SALDOACUMULADODFC := VN_SALDOACUMULADODFC + CALCULASALDOTOTAL_DFC(PCODREDUZIDO, PNATUREZA_DFC, PSALDO_DFC,PANO);
     ELSE
        FOR DADOS IN (SELECT M.CODREDUZIDO_PC
                        FROM PCMODELOPC M
                       WHERE M.CODCONTA_PC LIKE ( SELECT M1.CODCONTA_PC
                                                    FROM PCMODELOPC M1
                                                   WHERE M1.CODREDUZIDO_PC = PCODREDUZIDO
                                                     AND M1.CODPLANOCONTA = PCODPLANOCONTA) || '%'
                         AND M.CODPLANOCONTA = PCODPLANOCONTA) LOOP

           VN_SALDOACUMULADODFC := VN_SALDOACUMULADODFC + CALCULASALDOTOTAL_DFC(DADOS.CODREDUZIDO_PC, PNATUREZA_DFC, PSALDO_DFC,PANO);

        END LOOP;
       END IF; 
        RETURN VN_SALDOACUMULADODFC;
     ELSE
       IF PTIPOSALDO = 'F' THEN
          IF PCONSIDERARSALDOINI = 'S' THEN
             VN_MES := 0;
          ELSE
             VN_MES := PMESINI;
          END IF;
          
          
          IF PRETORNASALDOANTERIOR = 'S' THEN  
           IF (PMESINI = 1) OR ((PMESINI <> 1) AND (PMESFIM = 12) AND (PMESINI <> 10)) THEN

             IF (PMESFIM = 12) AND (PMESINI = 1) THEN
               VN_MES := 1;
             ELSE
               VN_MES := 10;
             END IF;


              VN_MESFIM := 12;
              VN_ANO := PANO;
            ELSIF PMESFIM - PMESINI > 2 THEN
			  VN_MES := 1;
			  VN_MESFIM := PMESINI -1; 
			  VN_ANO := PANO + 1;
			ELSE
              VN_MES :=  PMESFIM - PMESINI ;
              VN_MESFIM := PMESINI -1;
			  IF VN_MESFIM - VN_MES = 0 THEN
			    VN_MES := 1;
			  ELSE
                VN_MES := VN_MESFIM - VN_MES;
			  END IF;
              VN_ANO := PANO + 1;
            END IF;
             VN_DIA := EXTRACT(DAY FROM PDATAINI);
              VD_DATAINI := TO_DATE(to_char(VN_DIA)||'/'||to_char(VN_MES) ||'/'||to_char(VN_ANO), 'DD/MM/YYYY');
              VN_DIA := EXTRACT(DAY FROM PDATAFIM);
              VD_DATAFIM := LAST_DAY(TO_DATE( '01/'||to_char(VN_MESFIM) ||'/'||to_char(VN_ANO), 'DD/MM/YYYY'));
             VN_VALOR := CALCULASALDOTOTAL(PCODREDUZIDO, VN_MES, VN_MESFIM, VN_ANO, VD_DATAINI, VD_DATAFIM, VN_VALORENCERRAMENTO, VS_NATUREZA);
          ELSE
		     IF PDATAINI IS NOT NULL THEN
		       VN_VALOR := CALCULASALDOTOTAL(PCODREDUZIDO, VN_MES, PMESFIM, PANO, PDATAINI, PDATAFIM, VN_VALORENCERRAMENTO, VS_NATUREZA); 
             ELSE			 
               VN_VALOR := CALCULASALDOTOTAL(PCODREDUZIDO, VN_MES, PMESFIM, PANO, null, null, VN_VALORENCERRAMENTO, VS_NATUREZA); 
             END IF;			 
          END IF;

          IF PANTESDOENCERRAMENTO = 'S' THEN
             VN_VALOR := (VN_VALORENCERRAMENTO * -1) + VN_VALOR;
          END IF;

          RETURN VN_VALOR;
       ELSIF PTIPOSALDO = 'I' THEN
          VN_VALOR := CALCULASALDOTOTAL (PCODREDUZIDO, 0, 0, PANO, NULL, NULL, VN_VALORENCERRAMENTO, VS_NATUREZA);

          IF VN_VALOR >= 0 THEN
             PNATUREZA := VS_NATUREZA;
          ELSIF VN_VALOR < 0 THEN
             IF VS_NATUREZA = 'D' THEN
                PNATUREZA := 'C';
             ELSE
                PNATUREZA := 'D';
             END IF;
          END IF;

          RETURN VN_VALOR;
       END IF;
     END IF;
  END BUSCAVALOR;

  FUNCTION CALCULAREXPRESSAO(PEXPRESSAO IN VARCHAR2,
                             PANO       IN NUMBER,
                             PANTERIOR  IN VARCHAR2)
  RETURN NUMBER IS
    VS_FORMULA CLOB;
    VN_POSINI NUMBER(30);
    VN_POSFIM NUMBER(30);
    VN_GRUPO  NUMBER(30);
    VS_CONTA  VARCHAR2(50);
    VN_VALOR  NUMBER(22,2);
    VN_ARGUMENTO VARCHAR2(4000);
  BEGIN
    VS_FORMULA       := PEXPRESSAO;
    VN_POSINI        := 0;
    VN_POSFIM        := 0;
    VN_VALORANTERIOR := 0;

    VS_ERRO := 'Favor verificar os totalizadores!';

    LOOP
      --EXECUTA ENQUANTO TIVER [
      IF INSTR(VS_FORMULA, '[') = 0 THEN
         EXIT;
      END IF;

      VN_POSINI := INSTR(VS_FORMULA, '[');
      VN_POSFIM := INSTR(VS_FORMULA, ']');
      VN_GRUPO := SUBSTR(to_char(VS_FORMULA), VN_POSINI + 1, (VN_POSFIM - VN_POSINI) -1);

      IF    VN_POSINI = 1 THEN
            VS_FORMULA := SUBSTR(VS_FORMULA, VN_POSFIM + 1);
      ELSIF VN_POSINI > 1 THEN
            VS_FORMULA := SUBSTR(VS_FORMULA, 1, VN_POSINI -1) || SUBSTR(VS_FORMULA, VN_POSFIM + 1);
      END IF;

      VN_POSICAO_EM_ALTERACAO := 0;
      FOR VN_POSICAO IN 1 .. VRETORNO.COUNT
      LOOP
        IF VRETORNO(VN_POSICAO).ORDEM = VN_GRUPO THEN
           OUTROW                  := VRETORNO(VN_POSICAO);
           VN_POSICAO_EM_ALTERACAO := VN_POSICAO;
           EXIT;
        END IF;
      END LOOP;

      IF VN_POSICAO_EM_ALTERACAO > 0 THEN
         IF PANTERIOR = 'N' THEN
           VN_VALOR := OUTROW.VALORTEMP;
         ELSE
           VN_VALOR := OUTROW.VALORTEMPANTERIOR;
         END IF;
      ELSE
         VN_VALOR := 0;
      END IF;


      VN_ARGUMENTO := TO_CHAR(VN_VALOR);
      IF    VN_POSINI = 1 THEN
            VS_FORMULA := '(' || VN_ARGUMENTO || ')' || VS_FORMULA;
      ELSIF VN_POSINI > 1 THEN
            VS_FORMULA := SUBSTR(VS_FORMULA, 1, VN_POSINI -1) || '(' || VN_ARGUMENTO || ')' || SUBSTR(VS_FORMULA, VN_POSINI);
      END IF;

    END LOOP;

    --BUSCA VALORES DE CONTAS NA EXPRESSÃO
    LOOP
      --EXECUTA ENQUANTO TIVER {
      IF INSTR(VS_FORMULA, '{') = 0 THEN
         EXIT;
      END IF;

      VN_POSINI := INSTR(VS_FORMULA, '{');
      VN_POSFIM := INSTR(VS_FORMULA, '}');
      VS_CONTA := SUBSTR(VS_FORMULA, VN_POSINI + 1, (VN_POSFIM - VN_POSINI) -1);

      IF    VN_POSINI = 1 THEN
            VS_FORMULA := SUBSTR(VS_FORMULA, VN_POSFIM + 1);
      ELSIF VN_POSINI > 1 THEN
            VS_FORMULA := SUBSTR(VS_FORMULA, 1, VN_POSINI -1) || SUBSTR(VS_FORMULA, VN_POSFIM + 1);
      END IF;

      VN_VALOR := BUSCAVALOR(VS_CONTA, 'F', PANO, '', 0, 'N', VS_NATUREZA, PDATAINI_ESP, PDATAFIM_ESP);
      VN_ARGUMENTO := TO_CHAR(VN_VALOR);
      IF    VN_POSINI = 1 THEN
            VS_FORMULA := '(' || VN_ARGUMENTO || ')' || VS_FORMULA;
      ELSIF VN_POSINI > 1 THEN
            VS_FORMULA := SUBSTR(VS_FORMULA, 1, VN_POSINI -1) || '(' || VN_ARGUMENTO || ')' || SUBSTR(VS_FORMULA, VN_POSINI);
      END IF;

    END LOOP;

    IF TRIM(VS_FORMULA) = '' THEN
       VS_FORMULA := '0';
    END IF;
   VS_FORMULA := Replace(VS_FORMULA, ',','.');
    V_SQL  :=  'SELECT '||VS_FORMULA ||' AS VALOR FROM DUAL';
    EXECUTE IMMEDIATE V_SQL INTO VN_VALOR;
    RETURN VN_VALOR;
	
  EXCEPTION
     WHEN OTHERS THEN
        RETURN 0; 
	
  END;

  FUNCTION CALCULARINDICE(PEXPRESSAO IN VARCHAR2,
                          PANO       IN NUMBER,
                          PANTERIOR  IN VARCHAR2)
  RETURN NUMBER IS
    VS_FORMULA VARCHAR2(200);
    VS_VALOR   VARCHAR2(50);
    VS_TEMP     VARCHAR2(200);
    VS_OPERADOR VARCHAR2(1);
    VN_QTDEXPRESSOES NUMBER(3);
    VN_POSINI NUMBER(3);
    VN_POSFIM NUMBER(3);
    VS_CONTA  VARCHAR2(200);
    VN_VALOR  NUMBER(22,2);
    VN_VALOR2  NUMBER(22,2);
    VN_VALORANTERIOR NUMBER(22,2);
  BEGIN
    VS_FORMULA       := PEXPRESSAO;
    VS_TEMP          := PEXPRESSAO;
    VN_QTDEXPRESSOES := 0;
    VN_POSINI        := 0;
    VN_POSFIM        := 0;
    VN_VALORANTERIOR := 0;

    --BUSCA VALORES DE CONTAS NA EXPRESSÃO
    LOOP
      --EXECUTA ENQUANTO TIVER {
      IF INSTR(VS_FORMULA, '{') = 0 THEN
         EXIT;
      END IF;

      VN_QTDEXPRESSOES := VN_QTDEXPRESSOES + 1;

      VS_OPERADOR := '';

      IF (VN_QTDEXPRESSOES > 1) AND (INSTR(VS_TEMP, '-') > 0) THEN
        VS_OPERADOR := '-';

        VS_TEMP := SUBSTR(VS_TEMP, 1, INSTR(VS_TEMP, '-') -1) || SUBSTR(VS_TEMP, INSTR(VS_TEMP, '-') +1);
      END IF;

      VN_POSINI := INSTR(VS_FORMULA, '{');
      VN_POSFIM := INSTR(VS_FORMULA, '}');

      VS_CONTA := SUBSTR(VS_FORMULA, VN_POSINI + 1, (VN_POSFIM - VN_POSINI) -1);

      IF    VN_POSINI = 1 THEN
            VS_FORMULA := SUBSTR(VS_FORMULA, VN_POSFIM + 1);
      ELSIF VN_POSINI > 1 THEN
            VS_FORMULA := SUBSTR(VS_FORMULA, 1, VN_POSINI -1) || SUBSTR(VS_FORMULA, VN_POSFIM + 1);
      END IF;
      VN_VALOR2 :=  0;
      BEGIN
          --PEGANDO O VALOR DO PARAMETRO
            SELECT NVL (T.TOTAL, 0) TOTAL into VN_VALOR
              FROM (SELECT P.CODIGOPARAMETRO,
                           P.DESCRICAOPARAMETRO,
                           (SELECT ABS (SUM (S.VALORDEBITO) - SUM (S.VALORCREDITO))
                              FROM PCSALDO S
                             WHERE S.CODREDUZIDO_PC IN (SELECT CODREDUZIDO_PC
                                                          FROM PCCONTAPARAMETRO
                                                         WHERE CODIGOPARAMETRO = P.CODIGOPARAMETRO)
                               AND S.MES BETWEEN PMESINI AND PMESFIM
                               AND S.CODPLANOCONTA = PCODPLANOCONTA
                               AND S.ANO = PANO) AS TOTAL
                      FROM PCPARAMETROCONTACONTABIL P) T
             WHERE T.DESCRICAOPARAMETRO = VS_CONTA;
        EXCEPTION
        WHEN OTHERS THEN
            VN_VALOR    :=  0;
      END;
      if PCONSIDERARSALDOINI = 'S' then
      BEGIN
          --PEGANDO O VALOR DO PARAMETRO
            SELECT NVL (T.TOTAL, 0) TOTAL into VN_VALOR2
              FROM (SELECT P.CODIGOPARAMETRO,
                           P.DESCRICAOPARAMETRO,
                           (SELECT ABS (SUM (S.VALORDEBITO) - SUM (S.VALORCREDITO))
                              FROM PCSALDO S
                             WHERE S.CODREDUZIDO_PC IN (SELECT CODREDUZIDO_PC
                                                          FROM PCCONTAPARAMETRO
                                                         WHERE CODIGOPARAMETRO = P.CODIGOPARAMETRO)
                               AND S.MES BETWEEN 0 AND 0
                               AND S.CODPLANOCONTA = PCODPLANOCONTA
                               AND S.ANO = PANO) AS TOTAL
                      FROM PCPARAMETROCONTACONTABIL P) T
             WHERE T.DESCRICAOPARAMETRO = VS_CONTA;
        EXCEPTION
        WHEN OTHERS THEN
            VN_VALOR2    :=  0;
      END;
        VN_VALOR  :=  VN_VALOR + VN_VALOR2;
      END IF;

      IF PANTERIOR = 'N' THEN
        VS_VALOR := TRIM(TO_CHAR(OUTROW.VALORTEMP, '999,999,999,999.99'));
      ELSE
        VS_VALOR := TRIM(TO_CHAR(OUTROW.VALORTEMPANTERIOR, '999,999,999,999.99'));
      END IF;

      IF ((VS_OPERADOR = '-') AND (VN_VALOR < 0) AND (VN_VALORANTERIOR >= 0)) OR
         ((VS_OPERADOR = '-') AND (VN_VALOR > 0) AND (VN_VALORANTERIOR < 0)) THEN
         IF    VN_POSINI = 1 THEN
               VS_FORMULA := '(' || TO_CHAR(VN_VALOR * -1) || ')' || VS_FORMULA;
         ELSIF VN_POSINI > 1 THEN
               VS_FORMULA := SUBSTR(VS_FORMULA, 1, VN_POSINI -1) || '(' || TO_CHAR(VN_VALOR * -1) || ')' || SUBSTR(VS_FORMULA, VN_POSINI);
         END IF;

         VN_VALORANTERIOR :=  VN_VALOR * -1;
      ELSE
         IF    VN_POSINI = 1 THEN
               VS_FORMULA := '(' || TO_CHAR((VN_VALOR)) || ')' || VS_FORMULA;
         ELSIF VN_POSINI > 1 THEN
               VS_FORMULA := SUBSTR(VS_FORMULA, 1, VN_POSINI -1) || '(' || TO_CHAR(VN_VALOR) || ')' || SUBSTR(VS_FORMULA, VN_POSINI);
         END IF;

         VN_VALORANTERIOR :=  VN_VALOR;
      END IF;
    END LOOP;

    IF TRIM(VS_FORMULA) = '' THEN
       VS_FORMULA := 0;
    END IF;

    BEGIN
      V_SQL  :=  'SELECT '||VS_FORMULA ||' AS VALOR FROM DUAL';

      EXECUTE IMMEDIATE V_SQL INTO VN_VALOR;
    EXCEPTION
      WHEN OTHERS THEN
        VN_VALOR := 0;
    END;

    RETURN VN_VALOR;
  END CALCULARINDICE;

  
/****************************************************************************
    FUNÇÃO: RETORNA O SALDO CREDITO DA CONTA DA FORMULA MATEMÁTICA
  *****************************************************************************/
  FUNCTION CALCULASLDTOTCREDFORMULA (PCODREDUZIDO     IN  VARCHAR2,
                              PMESINI          IN  NUMBER,
                              PMESFIM          IN  NUMBER,
                              PANO             IN  NUMBER,
                              PVLRENCERRAMENTO OUT NUMBER,
                              PNATUREZA        OUT VARCHAR2)

     RETURN NUMBER IS

     VS_CODREDUZIDO            VARCHAR2 (12);
     VN_SALDOTOTAL             NUMBER (22, 2);
     VN_SALDOTOTENCERRAMENTO   NUMBER (22, 2);
     VS_NATUREZA               VARCHAR2 (1);
     V_SQLAUX2                 VARCHAR2 (10000);
  BEGIN
     V_SQLAUX2 := 'SELECT S.CODREDUZIDO_PC,
                          M.NATUREZA,
                          SUM(S.VALORCREDITO) AS SALDOTOTAL,
                          SUM(S.VLRCREENCERRAMENTO) AS SALDOTOTENCERRAMENTO
                   FROM PCSALDO S, PCMODELOPC M
                   WHERE S.CODREDUZIDO_PC = M.CODREDUZIDO_PC
                   AND   S.CODPLANOCONTA  = M.CODPLANOCONTA
                   AND   S.MES BETWEEN :MESINI AND :MESFIM
                   AND   S.CODREDUZIDO_PC = :CODREDUZIDO_PC';

     IF PCONSOLIDAR = 'S' THEN
        V_SQLAUX2 := V_SQLAUX2 || '   AND S.CODFILIAL IN (SELECT CODFILIAL
                                                          FROM PCCONFFILIAL
                                                          WHERE CODGRUPOFILIAL = :PCODFILIAL
                                                          AND   ANO            = :PANO) ';
     ELSE
        IF PAGRUPAFILIAL = 'N' THEN
           V_SQLAUX2 := V_SQLAUX2 || ' AND S.CODFILIAL IN ( :PCODFILIAL ) ';
        ELSE
           V_SQLAUX2 := V_SQLAUX2 || ' AND S.CODFILIAL IN (SELECT V.CODIGO
                                                           FROM V_CTBFILIAL V, PCCONFFILIAL C
                                                           WHERE SUBSTR(REPLACE(REPLACE(REPLACE(V.CGC, ''.''), ''/''), ''-''), 1, 8) LIKE
                                                                 (SELECT SUBSTR(REPLACE(REPLACE(REPLACE(F.CGC, ''.''), ''/''), ''-''), 1, 8)
                                                                  FROM V_CTBFILIAL F
                                                                  WHERE F.CODIGO = :PCODFILIAL
                                                                  AND   F.CODPLANOCONTA = ' || PCODPLANOCONTA ||' AND ROWNUM = 1) || ''%''
                                                           AND V.CODPLANOCONTA = ' || PCODPLANOCONTA || '
                                                           AND V.CODIGO = C.CODFILIAL
                                                           AND C.ANO = ' || PANO || '
                                                           AND C.CODGRUPOFILIAL = V.CODGRUPOFILIAL
                                                           AND V.CODGRUPOFILIAL = (SELECT CODGRUPOFILIAL FROM PCCONFFILIAL WHERE CODFILIAL = :PCODFILIAL  AND ANO =  ' || PANO || '))';
        END IF;
     END IF;

     V_SQLAUX2 := V_SQLAUX2 || ' AND  S.CODPLANOCONTA = :CODPLANOCONTA
                                 AND  S.ANO = :ANO
								 AND  S.MES <> 0
                                 GROUP BY S.CODREDUZIDO_PC, M.NATUREZA';

     -- Troca o parâmetro de filial pela stingr repassada no método
     PKG_CTBFUNCOESCONTEIS.TRATARMULTIFILIAL(PCODFILIAL,':PCODFILIAL', FALSE, V_SQLAUX2);

     IF PCONSOLIDAR = 'S' THEN
        EXECUTE IMMEDIATE V_SQLAUX2 INTO VS_CODREDUZIDO, VS_NATUREZA, VN_SALDOTOTAL, VN_SALDOTOTENCERRAMENTO
                                    USING PMESINI, PMESFIM, PCODREDUZIDO, PANO, PCODPLANOCONTA, PANO;
     ELSE
        EXECUTE IMMEDIATE V_SQLAUX2 INTO VS_CODREDUZIDO, VS_NATUREZA, VN_SALDOTOTAL, VN_SALDOTOTENCERRAMENTO
                                    USING PMESINI, PMESFIM, PCODREDUZIDO, PCODPLANOCONTA, PANO;
     END IF;

     PVLRENCERRAMENTO    := VN_SALDOTOTENCERRAMENTO;
     PNATUREZA           := VS_NATUREZA;

     RETURN VN_SALDOTOTAL;
  EXCEPTION
     WHEN OTHERS THEN
        VN_SALDOTOTAL           := 0;
        VS_CODREDUZIDO          := '';
        VS_NATUREZA             := '';
        VN_SALDOTOTENCERRAMENTO := 0;

        PVLRENCERRAMENTO := VN_SALDOTOTENCERRAMENTO;
        PNATUREZA        := VS_NATUREZA;
        RETURN VN_SALDOTOTAL;
  END CALCULASLDTOTCREDFORMULA;


   /****************************************************************************
    FUNÇÃO: RETORNA O SALDO DEBITO DA CONTA DA FORMULA MATEMATICA
   *****************************************************************************/
  FUNCTION CALCULASLDTOTDEBFORMULA (PCODREDUZIDO     IN  VARCHAR2,
                              PMESINI          IN  NUMBER,
                              PMESFIM          IN  NUMBER,
                              PANO             IN  NUMBER,
                              PVLRENCERRAMENTO OUT NUMBER,
                              PNATUREZA        OUT VARCHAR2)

     RETURN NUMBER IS

     VS_CODREDUZIDO            VARCHAR2 (12);
     VN_SALDOTOTAL             NUMBER (22, 2);
     VN_SALDOTOTENCERRAMENTO   NUMBER (22, 2);
     VS_NATUREZA               VARCHAR2 (1);
     V_SQLAUX2                 VARCHAR2 (10000);
  BEGIN
     V_SQLAUX2 := 'SELECT S.CODREDUZIDO_PC,
                          M.NATUREZA,
                          SUM(S.VALORDEBITO) AS SALDOTOTAL,
                          SUM(S.VLRDEBENCERRAMENTO) AS SALDOTOTENCERRAMENTO
                   FROM PCSALDO S, PCMODELOPC M
                   WHERE S.CODREDUZIDO_PC = M.CODREDUZIDO_PC
                   AND   S.CODPLANOCONTA  = M.CODPLANOCONTA
                   AND   S.MES BETWEEN :MESINI AND :MESFIM
                   AND   S.CODREDUZIDO_PC = :CODREDUZIDO_PC';

     IF PCONSOLIDAR = 'S' THEN
        V_SQLAUX2 := V_SQLAUX2 || '   AND S.CODFILIAL IN (SELECT CODFILIAL
                                                          FROM PCCONFFILIAL
                                                          WHERE CODGRUPOFILIAL = :PCODFILIAL
                                                          AND   ANO            = :PANO) ';
     ELSE
        IF PAGRUPAFILIAL = 'N' THEN
           V_SQLAUX2 := V_SQLAUX2 || ' AND S.CODFILIAL IN ( :PCODFILIAL ) ';
        ELSE
           V_SQLAUX2 := V_SQLAUX2 || ' AND S.CODFILIAL IN (SELECT V.CODIGO
                                                           FROM V_CTBFILIAL V, PCCONFFILIAL C
                                                           WHERE SUBSTR(REPLACE(REPLACE(REPLACE(V.CGC, ''.''), ''/''), ''-''), 1, 8) LIKE
                                                                 (SELECT SUBSTR(REPLACE(REPLACE(REPLACE(F.CGC, ''.''), ''/''), ''-''), 1, 8)
                                                                  FROM V_CTBFILIAL F
                                                                  WHERE F.CODIGO = :PCODFILIAL
                                                                  AND   F.CODPLANOCONTA = ' || PCODPLANOCONTA ||' AND ROWNUM = 1) || ''%''
                                                           AND V.CODPLANOCONTA = ' || PCODPLANOCONTA || '
                                                           AND V.CODIGO = C.CODFILIAL
                                                           AND C.ANO = ' || PANO || '
                                                           AND C.CODGRUPOFILIAL = V.CODGRUPOFILIAL
                                                           AND V.CODGRUPOFILIAL = (SELECT CODGRUPOFILIAL FROM PCCONFFILIAL WHERE CODFILIAL = :PCODFILIAL  AND ANO =  ' || PANO || '))';
        END IF;
     END IF;

     V_SQLAUX2 := V_SQLAUX2 || ' AND  S.CODPLANOCONTA = :CODPLANOCONTA
                                 AND  S.ANO = :ANO
								 AND  S.MES <> 0
                                 GROUP BY S.CODREDUZIDO_PC, M.NATUREZA';

     -- Troca o parâmetro de filial pela stingr repassada no método
     PKG_CTBFUNCOESCONTEIS.TRATARMULTIFILIAL(PCODFILIAL,':PCODFILIAL', FALSE, V_SQLAUX2);

     IF PCONSOLIDAR = 'S' THEN
        EXECUTE IMMEDIATE V_SQLAUX2 INTO VS_CODREDUZIDO, VS_NATUREZA, VN_SALDOTOTAL, VN_SALDOTOTENCERRAMENTO
                                    USING PMESINI, PMESFIM, PCODREDUZIDO, PANO, PCODPLANOCONTA, PANO;
     ELSE
        EXECUTE IMMEDIATE V_SQLAUX2 INTO VS_CODREDUZIDO, VS_NATUREZA, VN_SALDOTOTAL, VN_SALDOTOTENCERRAMENTO
                                    USING PMESINI, PMESFIM, PCODREDUZIDO, PCODPLANOCONTA, PANO;
     END IF;

     PVLRENCERRAMENTO    := VN_SALDOTOTENCERRAMENTO;
     PNATUREZA           := VS_NATUREZA;

     RETURN VN_SALDOTOTAL;
  EXCEPTION
     WHEN OTHERS THEN
        VN_SALDOTOTAL           := 0;
        VS_CODREDUZIDO          := '';
        VS_NATUREZA             := '';
        VN_SALDOTOTENCERRAMENTO := 0;

        PVLRENCERRAMENTO := VN_SALDOTOTENCERRAMENTO;
        PNATUREZA        := VS_NATUREZA;
        RETURN VN_SALDOTOTAL;
  END CALCULASLDTOTDEBFORMULA;

  /****************************************************************************
    FUNÇÃO: BUSCA VALORES DA FORMULA PARA DFC INDIRETO
  *****************************************************************************/
  FUNCTION BUSCAVALORFORMULA(PCODREDUZIDO            IN VARCHAR2,
                      PFORMULA_DESC_RESULTADO IN VARCHAR2,
                      PANO                    IN NUMBER,
                      PNATUREZA_DFC           IN VARCHAR2,
                      PSALDO_DFC              IN NUMBER,
                      PNATUREZA               OUT VARCHAR2)
  RETURN NUMBER IS
    VN_MES                 NUMBER(2);
    VN_VALOR               NUMBER(22,2);
    VN_VALORENCERRAMENTO   NUMBER(22,2);
    VS_NATUREZA            VARCHAR2(1);
    VN_SALDOACUMULADODFC   NUMBER(22,2);

    VN_SALDOAINICIAL       NUMBER(22,2);
    VN_SALDOAFINAL         NUMBER(22,2);
    VN_MOVIMCREDITO        NUMBER(22,2);
    VN_MOVIMDEBITO         NUMBER(22,2);

    VS_SALDO_INICIAL       VARCHAR2(20);
    VS_SALDO_FINAL         VARCHAR2(20);
    VS_MOVIM_CREDITO       VARCHAR2(20);
    VS_MOVIM_DEBITO        VARCHAR2(20);
	
    V_SQL                 VARCHAR2 (1000);	
    VS_FORMULA            VARCHAR2 (1000);		
  BEGIN

  VN_SALDOAINICIAL    := 0;
  VN_SALDOAFINAL      := 0;
  VN_MOVIMCREDITO     := 0;
  VN_MOVIMDEBITO      := 0;

  VS_SALDO_INICIAL    := '{SALDO_INICIAL}';
  VS_SALDO_FINAL      := '{SALDO_FINAL}';
  VS_MOVIM_CREDITO    := '{MOVIM_CREDITO}';
  VS_MOVIM_DEBITO     := '{MOVIM_DEBITO}';
  
  VS_FORMULA          := PFORMULA_DESC_RESULTADO;

  /*** SALDO INICIAL ***/
  IF INSTR(VS_FORMULA, VS_SALDO_INICIAL) > 0 THEN
    VN_SALDOAINICIAL := CALCULASALDOTOTAL (PCODREDUZIDO, 0, 0, PANO, PDATAINI_ESP, PDATAFIM_ESP, VN_VALORENCERRAMENTO, VS_NATUREZA);
    IF VN_SALDOAINICIAL >= 0 THEN
      PNATUREZA := VS_NATUREZA;
    ELSIF VN_SALDOAINICIAL < 0 THEN
      IF VS_NATUREZA = 'D' THEN
        PNATUREZA := 'C';
      ELSE
        PNATUREZA := 'D';
      END IF;
    END IF;
	VS_FORMULA := REGEXP_REPLACE( VS_FORMULA , VS_SALDO_INICIAL, NVL(VN_SALDOAINICIAL, 0));
  END IF;
  /*** SALDO INICIAL ***/

  /*** SALDO FINAL ***/
  IF INSTR(VS_FORMULA, VS_SALDO_FINAL) > 0 THEN
    VN_VALORENCERRAMENTO := 0;
    IF PCONSIDERARSALDOINI = 'S' THEN
      VN_MES := 0;
    ELSE
      VN_MES := PMESINI;
    END IF;
    VN_SALDOAFINAL := CALCULASALDOTOTAL(PCODREDUZIDO, VN_MES, PMESFIM, PANO, PDATAINI_ESP, PDATAFIM_ESP, VN_VALORENCERRAMENTO, VS_NATUREZA);
    IF PANTESDOENCERRAMENTO = 'S' THEN
      VN_SALDOAFINAL := (VN_VALORENCERRAMENTO * -1) + VN_SALDOAFINAL;
    END IF;
	VS_FORMULA := REGEXP_REPLACE( VS_FORMULA , VS_SALDO_FINAL, NVL(VN_SALDOAFINAL, 0));
  END IF;
  /*** SALDO FINAL ***/

  /*** MOVIMENTAÇÃO DE CRÉDITO ***/
  IF INSTR(VS_FORMULA, VS_MOVIM_CREDITO) > 0 THEN
    VN_VALORENCERRAMENTO := 0;
    VN_SALDOACUMULADODFC := 0;
    IF PCONSIDERARSALDOINI = 'S' THEN
      VN_MES := 0;
    ELSE
      VN_MES := PMESINI;
    END IF;
    VN_MOVIMCREDITO := CALCULASLDTOTCREDFORMULA(PCODREDUZIDO, VN_MES, PMESFIM, PANO, VN_VALORENCERRAMENTO, VS_NATUREZA);
    IF PANTESDOENCERRAMENTO = 'S' THEN
      VN_MOVIMCREDITO := (VN_VALORENCERRAMENTO * -1) + VN_MOVIMCREDITO;
    END IF;
	VS_FORMULA := REGEXP_REPLACE(VS_FORMULA , VS_MOVIM_CREDITO, NVL(VN_MOVIMCREDITO, 0));
  END IF;
  /*** MOVIMENTAÇÃO DE CRÉDITO ***/

  /*** MOVIMENTAÇÃO DE DÉBITO ***/
  IF INSTR(VS_FORMULA, VS_MOVIM_DEBITO) > 0 THEN
    VN_VALORENCERRAMENTO := 0;
    VN_SALDOACUMULADODFC := 0;
    IF PCONSIDERARSALDOINI = 'S' THEN
      VN_MES := 0;
    ELSE
      VN_MES := PMESINI;
    END IF;
    VN_MOVIMDEBITO := CALCULASLDTOTDEBFORMULA(PCODREDUZIDO, VN_MES, PMESFIM, PANO, VN_VALORENCERRAMENTO, VS_NATUREZA);
    IF PANTESDOENCERRAMENTO = 'S' THEN
      VN_MOVIMDEBITO := (VN_VALORENCERRAMENTO * -1) + VN_MOVIMDEBITO;
    END IF;
	VS_FORMULA := REGEXP_REPLACE( VS_FORMULA , VS_MOVIM_DEBITO, NVL(VN_MOVIMDEBITO, 0));

  END IF;
  /*** MOVIMENTAÇÃO DE DÉBITO ***/

  V_SQL  :=  'SELECT '|| VS_FORMULA ||' AS VALOR FROM DUAL';
  EXECUTE IMMEDIATE V_SQL INTO VN_VALOR;
  RETURN VN_VALOR;

  EXCEPTION
     WHEN OTHERS THEN
        RETURN 0; 

  END BUSCAVALORFORMULA;  
    
  
/****************************************************************************
  Inicio Função Principal
*****************************************************************************/
BEGIN
  VN_CODCONFIGPAI        := 0;
  VN_VLRTOTAL            := 0;
  VN_VLRSUBTOTAL         := 0;
  VN_VLRSUBTOTALANTERIOR := 0;
  VS_ESTRUTURADFC        := '';
  VS_NOTAEXPLICATIVA     := '';

  BEGIN
     SELECT MASCARA
       INTO VS_MASCARA_PC
       FROM PCPLANOCONTA
      WHERE CODPLANOCONTA = PCODPLANOCONTA;
  EXCEPTION
     WHEN OTHERS THEN
        VS_MASCARA_PC    := '';
  END;

  VCONTCONTASPAIS  :=  0;

  BEGIN
    SELECT DFC, NOTAEXPLICATIVA
    INTO VS_ESTRUTURADFC, VS_NOTAEXPLICATIVA
    FROM PCDEMONSTRATIVOCTB
    WHERE CODDEMONST = PCODDRE;
  EXCEPTION
     WHEN OTHERS THEN
        VS_ESTRUTURADFC := '';
  END;

  --CONSULTA INICIAL DAS CONTAS PAI
  FOR DRE_CABECALHO IN (SELECT CODDEMONST,
                               CODPLANOCONTA,
                               CODCONFIG,
                               ORDEM,
                               DESC_OPERACAO,
                               DESC_RESULTADO,
                               NVL (TIPORESULTADO, 'G') TIPORESULTADO,
                               0 VALORTEMP,
                               NVL (BASEVERTICAL, 'N') BASEVERTICAL
                          FROM PCCONFIGDRE
                         WHERE NVL (CODCONFIGPAI, 0) = 0
                           AND CODDEMONST = PCODDRE
                           AND CODPLANOCONTA = PCODPLANOCONTA
                         ORDER BY ORDEM)
  LOOP
    OUTROW.ORDEM     := -1;
    VCONTCONTASPAIS  :=  VCONTCONTASPAIS +   1;

    VRETORNO.EXTEND;
    VN_POSICAO_EM_ALTERACAO  := VRETORNO.COUNT;
    OUTROW.ORDEM             := DRE_CABECALHO.ORDEM;
    OUTROW.TIPO              := DRE_CABECALHO.TIPORESULTADO;
    OUTROW.DESCRICAO         := DRE_CABECALHO.DESC_OPERACAO;
    OUTROW.RESULTADO         := DRE_CABECALHO.DESC_RESULTADO;
    OUTROW.BASEVERTICAL      := DRE_CABECALHO.BASEVERTICAL;
    OUTROW.CODCONFIG         := DRE_CABECALHO.CODCONFIG;
    OUTROW.VALORTEMP         := 0;
    OUTROW.VALORTEMPANTERIOR := 0;
    OUTROW.SEMREGRA          := '';
    OUTROW.NOTAEXPLICATIVA   := VS_NOTAEXPLICATIVA;
  	OUTROW.CODCONTA_PC       := '';
    OUTROW.RECEBELANCTO      := '';
    OUTROW.NATUREZACONTA     := '';
    OUTROW.TIPOCONTA         := '';

    IF (DRE_CABECALHO.TIPORESULTADO = 'G') OR (DRE_CABECALHO.TIPORESULTADO = 'T') OR (DRE_CABECALHO.TIPORESULTADO = 'A') THEN
       OUTROW.NEGRITO := 'S';
    ELSE
       OUTROW.NEGRITO := 'N';
    END IF;

    VRETORNO(VN_POSICAO_EM_ALTERACAO) := OUTROW;

    --RETORNA VALORES ANALÍTICOS

     VS_NATUREZA     := '';

     VN_CODCONFIGPAI := OUTROW.CODCONFIG;
     VS_TIPOPAI      := OUTROW.TIPO;

     V_SQL_RATEIO :=
        'SELECT
          A.CODPLANOCONTA,
          A.CODPLANOCONTA,
          A.CODIGO,
          A.DESCRICAO,
          A.VALOR,
          ROUND(A.VALOR / (SUM(A.VALOR) OVER()) * 100,2) PERCENTUAL
        FROM (SELECT PCLANCAMENTO.CODREDUZIDO_PC
          , PCLANCAMENTO.CODPLANOCONTA
          , PCCENTRORECEITA.CODIGOCENTRORECEITA CODIGO
          , PCCENTRORECEITA.DESCRICAO
          , SUM(DECODE(PCRATEIOCONTABILCR.NATUREZA, ''D'', PCRATEIOCONTABILCR.VALOR * -1, PCRATEIOCONTABILCR.VALOR)) VALOR
        FROM PCRATEIOCONTABILCR
          , PCLANCAMENTO
          , PCCENTRORECEITA
          , PCMODELOPC
        WHERE PCLANCAMENTO.NUMTRANSLANCTO         = PCRATEIOCONTABILCR.NUMTRANSLANCTO
          AND PCCENTRORECEITA.CODIGOCENTRORECEITA = PCRATEIOCONTABILCR.CODIGOCENTRORECEITA
          AND PCLANCAMENTO.CODPLANOCONTA          = PCMODELOPC.CODPLANOCONTA
          AND PCLANCAMENTO.CODREDUZIDO_PC         = PCMODELOPC.CODREDUZIDO_PC
          AND PCMODELOPC.NATUREZA                 = PCLANCAMENTO.NATUREZA
          AND PCMODELOPC.CODREDUZIDO_PC           = :CODCONTAREDUZIDO
          AND PCMODELOPC.CODPLANOCONTA            = :PCODPLANOCONTA
          AND PCLANCAMENTO.ANO                    = :PANO
          AND PCLANCAMENTO.MES              BETWEEN :PMESINI AND :PMESFIM ';
      
            
     IF PCONSOLIDAR = 'S' THEN
        V_SQL_RATEIO := V_SQL_RATEIO || '   AND PCLANCAMENTO.CODFILIAL IN (SELECT CODFILIAL
                                                          FROM PCCONFFILIAL
                                                          WHERE CODGRUPOFILIAL = :PCODFILIAL
                                                          AND   ANO            = ' || PANO || ' ) ';
     ELSE
        IF PAGRUPAFILIAL = 'N' THEN
           V_SQL_RATEIO := V_SQL_RATEIO || ' AND PCLANCAMENTO.CODFILIAL IN ( :PCODFILIAL ) ';
        ELSE
           V_SQL_RATEIO := V_SQL_RATEIO || ' AND PCLANCAMENTO.CODFILIAL IN (SELECT V.CODIGO
                                                           FROM V_CTBFILIAL V, PCCONFFILIAL C
                                                           WHERE SUBSTR(REPLACE(REPLACE(REPLACE(V.CGC, ''.''), ''/''), ''-''), 1, 8) LIKE
                                                                 (SELECT SUBSTR(REPLACE(REPLACE(REPLACE(F.CGC, ''.''), ''/''), ''-''), 1, 8)
                                                                  FROM V_CTBFILIAL F
                                                                  WHERE F.CODIGO = :PCODFILIAL
                                                                  AND   F.CODPLANOCONTA = ' || PCODPLANOCONTA ||' AND ROWNUM = 1) || ''%''
                                                           AND V.CODPLANOCONTA = ' || PCODPLANOCONTA || '
                                                           AND V.CODIGO = C.CODFILIAL
                                                           AND C.ANO = ' || PANO || '
                                                           AND C.CODGRUPOFILIAL = V.CODGRUPOFILIAL
                                                           AND V.CODGRUPOFILIAL = (SELECT CODGRUPOFILIAL FROM PCCONFFILIAL WHERE CODFILIAL = :PCODFILIAL  AND ANO =  ' || PANO || '))';
        END IF;
     END IF;
     V_SQL_RATEIO := V_SQL_RATEIO || '     
         
        GROUP
         BY PCLANCAMENTO.CODREDUZIDO_PC
          , PCLANCAMENTO.CODPLANOCONTA
          , PCCENTRORECEITA.CODIGOCENTRORECEITA
          , PCCENTRORECEITA.DESCRICAO

        UNION ALL
        SELECT PCLANCAMENTO.CODREDUZIDO_PC
          , PCLANCAMENTO.CODPLANOCONTA
          , PCCENTROCUSTO.CODIGOCENTROCUSTO CODIGO
          , PCCENTROCUSTO.DESCRICAO
          , SUM(DECODE(PCRATEIOCONTABILCC.NATUREZA, ''D'', PCRATEIOCONTABILCC.VALOR * -1, PCRATEIOCONTABILCC.VALOR)) VALOR
        FROM PCRATEIOCONTABILCC
          , PCLANCAMENTO
          , PCCENTROCUSTO
          , PCMODELOPC
        WHERE PCLANCAMENTO.NUMTRANSLANCTO         = PCRATEIOCONTABILCC.NUMTRANSLANCTO
          AND PCCENTROCUSTO.CODIGOCENTROCUSTO     = PCRATEIOCONTABILCC.CODIGOCENTROCUSTO
          AND PCLANCAMENTO.CODPLANOCONTA          = PCMODELOPC.CODPLANOCONTA
          AND PCLANCAMENTO.CODREDUZIDO_PC         = PCMODELOPC.CODREDUZIDO_PC
          AND PCMODELOPC.NATUREZA                 = PCLANCAMENTO.NATUREZA
          AND PCMODELOPC.CODREDUZIDO_PC           = :CODCONTAREDUZIDO
          AND PCMODELOPC.CODPLANOCONTA            = :PCODPLANOCONTA
          AND PCLANCAMENTO.ANO                    = :PANO
          AND PCLANCAMENTO.MES              BETWEEN :PMESINI AND :PMESFIM ';
          
          
     IF PCONSOLIDAR = 'S' THEN
        V_SQL_RATEIO := V_SQL_RATEIO || '   AND PCLANCAMENTO.CODFILIAL IN (SELECT CODFILIAL
                                                          FROM PCCONFFILIAL
                                                          WHERE CODGRUPOFILIAL = :PCODFILIAL
                                                          AND   ANO            =  ' || PANO || ' ) ';
     ELSE
        IF PAGRUPAFILIAL = 'N' THEN
           V_SQL_RATEIO := V_SQL_RATEIO || ' AND PCLANCAMENTO.CODFILIAL IN ( :PCODFILIAL ) ';
        ELSE
           V_SQL_RATEIO := V_SQL_RATEIO || ' AND PCLANCAMENTO.CODFILIAL IN (SELECT V.CODIGO
                                                           FROM V_CTBFILIAL V, PCCONFFILIAL C
                                                           WHERE SUBSTR(REPLACE(REPLACE(REPLACE(V.CGC, ''.''), ''/''), ''-''), 1, 8) LIKE
                                                                 (SELECT SUBSTR(REPLACE(REPLACE(REPLACE(F.CGC, ''.''), ''/''), ''-''), 1, 8)
                                                                  FROM V_CTBFILIAL F
                                                                  WHERE F.CODIGO = :PCODFILIAL
                                                                  AND   F.CODPLANOCONTA = ' || PCODPLANOCONTA ||' AND ROWNUM = 1) || ''%''
                                                           AND V.CODPLANOCONTA = ' || PCODPLANOCONTA || '
                                                           AND V.CODIGO = C.CODFILIAL
                                                           AND C.ANO = ' || PANO || '
                                                           AND C.CODGRUPOFILIAL = V.CODGRUPOFILIAL
                                                           AND V.CODGRUPOFILIAL = (SELECT CODGRUPOFILIAL FROM PCCONFFILIAL WHERE CODFILIAL = :PCODFILIAL  AND ANO =  ' || PANO || '))';
        END IF;
     END IF;
     V_SQL_RATEIO := V_SQL_RATEIO || '       
                    GROUP
                     BY PCLANCAMENTO.CODREDUZIDO_PC
                      , PCLANCAMENTO.CODPLANOCONTA
                      , PCCENTROCUSTO.CODIGOCENTROCUSTO
                      , PCCENTROCUSTO.DESCRICAO
                    ) A
                    ORDER
                    BY A.CODIGO';

     PKG_CTBFUNCOESCONTEIS.TRATARMULTIFILIAL(PCODFILIAL,':PCODFILIAL', FALSE, V_SQL_RATEIO);

     V_SQL := 'SELECT CODDEMONST,
                      CODCONFIG,
                      ORDEM,
                      DESC_OPERACAO,
                      TIPORESULTADO,
                      DECODE (TIPORESULTADO,
                              ''C'', ''Conta Contabil'',
                              ''S'', ''Saldo Inicial'',
                              ''V'', ''Valor Manual'',
                              ''F'', ''Formula'',							  
                              ''E'', ''Expressao'') REGRA,
                      VALORMANUAL,
                      CODCONTAREDUZIDO,
                      CODCONFIGPAI,
                      DESC_RESULTADO,
                      NVL(SALDODFC, 0) SALDODFC,
                      NVL(NATUREZALANC, ''D'') NATUREZALANC,
					            M.CODCONTA_PC,
                      NVL(M.RECEBE_LANCTO, ''N'') RECEBE_LANCTO,
                      M.NATUREZA AS NATUREZACONTA,
                      M.TIPOCONTA
                 FROM PCCONFIGDRE, PCMODELOPC M
                WHERE CODCONFIGPAI > 0
                  AND CODDEMONST =    :PCODDRE
                  AND PCCONFIGDRE.CODPLANOCONTA = :PCODPLANOCONTA
				          AND M.CODPLANOCONTA(+) = PCCONFIGDRE.CODPLANOCONTA
				          AND M.CODREDUZIDO_PC(+) = PCCONFIGDRE.CODCONTAREDUZIDO
                  AND CODCONFIGPAI =  :PCODCONFIGPAI
                  ORDER BY ORDEM ';

     OPEN CURSORANALITICO FOR V_SQL USING PCODDRE, PCODPLANOCONTA, VN_CODCONFIGPAI;
     FETCH CURSORANALITICO INTO DRE_ANALITICO;
     --Caso não tenha encontrado nenhum registro filho
        IF (DRE_CABECALHO.TIPORESULTADO = 'G') AND (CURSORANALITICO%NOTFOUND) THEN
            OUTROW.SEMREGRA                   :=  'S';
            VRETORNO(VN_POSICAO_EM_ALTERACAO) := OUTROW;
        ELSIF (DRE_CABECALHO.TIPORESULTADO = 'I') AND (CURSORANALITICO%NOTFOUND) THEN
            LIMPAVARIAVEIS;
            OUTROW.DESCRICAO :=  'Fórmula: '||DRE_CABECALHO.DESC_RESULTADO;
            OUTROW.VALOR     :=  TRIM(TO_CHAR(CALCULARINDICE(DRE_CABECALHO.DESC_RESULTADO, PANO, 'N'), '999,999,999,999.99'));

            IF OUTROW.VALOR = '.00' THEN
               OUTROW.VALOR := '0.00';
            END IF;

            IF OUTROW.VALORANTERIOR = '.00' THEN
               OUTROW.VALORANTERIOR := '0.00';
            END IF;

            VRETORNO.EXTEND;
            VN_POSICAO_EM_ALTERACAO           := VRETORNO.COUNT;
            VRETORNO(VN_POSICAO_EM_ALTERACAO) := OUTROW;
        END IF;
     LOOP
        EXIT WHEN CURSORANALITICO%NOTFOUND;

        IF VS_TIPOPAI = 'G' THEN
           IF DRE_ANALITICO.TIPORESULTADO IN ('C', 'S', 'F') THEN --Tipo C e S (e F (fórmula DFC-indireto))
              IF DRE_ANALITICO.TIPORESULTADO = 'C' THEN
                 VN_VALOR     := BUSCAVALOR(DRE_ANALITICO.CODCONTAREDUZIDO, 'F', PANO, DRE_ANALITICO.NATUREZALANC, DRE_ANALITICO.SALDODFC,'N', VS_NATUREZA, PDATAINI_ESP, PDATAFIM_ESP);
                 VS_TIPOREGRA := 'F';

                 IF PANALISEHORIZONTAL = 'S' THEN
                    VN_VALORANTERIOR := BUSCAVALOR(DRE_ANALITICO.CODCONTAREDUZIDO, 'F', PANO - 1, DRE_ANALITICO.NATUREZALANC, DRE_ANALITICO.SALDODFC, PSALDOANOANTERIOR, VS_NATUREZA, PDATAINI_ESP, PDATAFIM_ESP);
                 END IF;
              ELSIF DRE_ANALITICO.TIPORESULTADO = 'F' THEN
                 VN_VALOR     := BUSCAVALORFORMULA(DRE_ANALITICO.CODCONTAREDUZIDO, DRE_ANALITICO.DESC_RESULTADO, PANO, DRE_ANALITICO.NATUREZALANC, DRE_ANALITICO.SALDODFC, VS_NATUREZA);

                 IF PANALISEHORIZONTAL = 'S' THEN
                    VN_VALORANTERIOR := BUSCAVALORFORMULA(DRE_ANALITICO.CODCONTAREDUZIDO, DRE_ANALITICO.DESC_RESULTADO, PANO - 1, DRE_ANALITICO.NATUREZALANC, DRE_ANALITICO.SALDODFC, VS_NATUREZA);
                 END IF;
              ELSE
                 VS_TIPOREGRA := 'I';
                 VN_VALOR     := BUSCAVALOR(DRE_ANALITICO.CODCONTAREDUZIDO, 'I', PANO, DRE_ANALITICO.NATUREZALANC, DRE_ANALITICO.SALDODFC, 'N', VS_NATUREZA, PDATAINI_ESP, PDATAFIM_ESP);

                 IF PANALISEHORIZONTAL = 'S' THEN
                    VN_VALORANTERIOR := BUSCAVALOR(DRE_ANALITICO.CODCONTAREDUZIDO, 'I', PANO - 1, DRE_ANALITICO.NATUREZALANC, DRE_ANALITICO.SALDODFC,'N', VS_NATUREZA, PDATAINI_ESP, PDATAFIM_ESP);
                 END IF;
              END IF;
			  
              --BUSCA TODAS AS CONTAS ANALÍTICAS DO GRUPO INFORMADO
              IF PEXIBIRCONTASANALITICAS = 'S' THEN
                 BEGIN
                   SELECT CODCONTA_PC
                     INTO VS_CODCONTAANALITICA
                     FROM PCMODELOPC
                    WHERE CODREDUZIDO_PC = DRE_ANALITICO.CODCONTAREDUZIDO
                      AND CODPLANOCONTA = PCODPLANOCONTA;
                 EXCEPTION 
                   WHEN NO_DATA_FOUND THEN
                     VS_CODCONTAANALITICA := 'X';
                 END;

                 VCONTCONTASANALITICAS := 0;

                 SELECT COUNT (*)
                   INTO VCONTCONTASANALITICAS
                   FROM PCMODELOPC
                  WHERE CODCONTA_PC LIKE VS_CODCONTAANALITICA || '%';

                 FOR CONTASANALITICAS IN (SELECT CODCONTA_PC,
                                                 CODREDUZIDO_PC,
                                                 NOME_CONTA,
                                                 PCMODELOPC.RECEBE_LANCTO,
                                                 PCMODELOPC.NATUREZA,
                                                 PCMODELOPC.TIPOCONTA
                                          FROM PCMODELOPC
                                          WHERE CODCONTA_PC LIKE VS_CODCONTAANALITICA || '%'
                                          AND CODPLANOCONTA = PCODPLANOCONTA
                                          ORDER BY CODCONTA_PC)

                 LOOP
                    VN_VALORCONTAANALITICAANT := 0;
                    VN_VALORCONTAANALITICA    := 0;

                    IF DRE_ANALITICO.TIPORESULTADO = 'F' THEN
                                VN_VALORCONTAANALITICA := BUSCAVALORFORMULA(CONTASANALITICAS.CODREDUZIDO_PC, DRE_ANALITICO.DESC_RESULTADO, PANO, DRE_ANALITICO.NATUREZALANC, DRE_ANALITICO.SALDODFC, VS_NATUREZA);
                    ELSE
                                VN_VALORCONTAANALITICA := BUSCAVALOR (CONTASANALITICAS.CODREDUZIDO_PC, VS_TIPOREGRA, PANO, DRE_ANALITICO.NATUREZALANC, DRE_ANALITICO.SALDODFC,'N', VS_NATUREZA, PDATAINI_ESP, PDATAFIM_ESP);
                    END IF;

                    IF PANALISEHORIZONTAL = 'S' THEN
                      IF DRE_ANALITICO.TIPORESULTADO = 'F' THEN
                        VN_VALORCONTAANALITICAANT := BUSCAVALORFORMULA(CONTASANALITICAS.CODREDUZIDO_PC, DRE_ANALITICO.DESC_RESULTADO, PANO - 1, DRE_ANALITICO.NATUREZALANC, DRE_ANALITICO.SALDODFC, VS_NATUREZA);
                      ELSE
                        VN_VALORCONTAANALITICAANT := BUSCAVALOR(CONTASANALITICAS.CODREDUZIDO_PC, VS_TIPOREGRA, PANO - 1, DRE_ANALITICO.NATUREZALANC, DRE_ANALITICO.SALDODFC, PSALDOANOANTERIOR, VS_NATUREZA, PDATAINI_ESP, PDATAFIM_ESP);
                      END IF;            
                    END IF;

                    IF ((PEXIBIRCONTASSALDOZERO = 'N') AND (VN_VALORCONTAANALITICA = 0) AND (VN_VALORCONTAANALITICAANT = 0)) THEN
                       NULL;
                    ELSE
                       IF (VN_VALORCONTAANALITICA = 0) AND (PEXIBIRCONTASSALDOZERO = 'S') THEN
                          LIMPAVARIAVEIS ();

                          VRETORNO.EXTEND;
                          VN_POSICAO_EM_ALTERACAO := VRETORNO.COUNT;

                          --Atribui valores se não estiver marcado para exibir código reduzido
                          IF PEXIBIRCODREDUZIDO = 'N' THEN
                             IF (LENGTH (VS_MASCARA_PC) = LENGTH (CONTASANALITICAS.CODCONTA_PC)) AND (VCONTCONTASANALITICAS > 1) THEN
                                OUTROW.DESCRICAO := '        ' || CONTASANALITICAS.NOME_CONTA;
                             ELSE
                                OUTROW.DESCRICAO := '    ' || CONTASANALITICAS.NOME_CONTA;
                             END IF;
                          ELSE
                             IF (LENGTH (VS_MASCARA_PC) = LENGTH (CONTASANALITICAS.CODCONTA_PC)) AND (VCONTCONTASANALITICAS > 1) THEN
                                OUTROW.DESCRICAO := '        ' || CONTASANALITICAS.CODREDUZIDO_PC || ' - ' || CONTASANALITICAS.NOME_CONTA;
                             ELSE
                                OUTROW.DESCRICAO := '    ' || CONTASANALITICAS.CODREDUZIDO_PC || ' - ' || CONTASANALITICAS.NOME_CONTA;
                             END IF;
                          END IF;
                          
                          OUTROW.CODCONTA_PC   := CONTASANALITICAS.CODCONTA_PC;
                          OUTROW.RECEBELANCTO  := CONTASANALITICAS.RECEBE_LANCTO;
                          OUTROW.NATUREZACONTA := CONTASANALITICAS.NATUREZA;
                          OUTROW.TIPOCONTA     := CONTASANALITICAS.TIPOCONTA;
                          OUTROW.VALOR         := TRIM(TO_CHAR(VN_VALORCONTAANALITICA, '999,999,999,999.99'));
                          
                          IF VN_VALORCONTAANALITICA < 0 THEN
                           OUTROW.VALORANTERIOR := '(' || TRIM(TO_CHAR(ABS(VN_VALORCONTAANALITICA), '999,999,999,999.99')) || ')';
                          ELSE
                           OUTROW.VALORANTERIOR := TRIM(TO_CHAR(ABS(VN_VALORCONTAANALITICA), '999,999,999,999.99'));
                          END IF;
                          
                          OUTROW.VALORBASE     := VN_VALORCONTAANALITICA;
                          OUTROW.ORDEM         := NULL;
                          OUTROW.NEGRITO       := 'N';

                          IF OUTROW.VALOR = '.00' THEN
                             OUTROW.VALOR := '0.00';
                          END IF;

                          IF OUTROW.VALORANTERIOR = '.00' THEN
                             OUTROW.VALORANTERIOR := '0.00';
                          END IF;

                          VRETORNO(VN_POSICAO_EM_ALTERACAO) := OUTROW;
                       ELSIF (VN_VALORCONTAANALITICA <> 0) OR (VN_VALORCONTAANALITICAANT <> 0) THEN
                          LIMPAVARIAVEIS ();
                          VRETORNO.EXTEND;
                          VN_POSICAO_EM_ALTERACAO := VRETORNO.COUNT;

                          --Atribui valores se não estiver marcado para exibir código reduzido
                          IF PEXIBIRCODREDUZIDO = 'N' THEN
                             IF (LENGTH (VS_MASCARA_PC) = LENGTH (CONTASANALITICAS.CODCONTA_PC)) AND (VCONTCONTASANALITICAS > 1) THEN
                                OUTROW.DESCRICAO    := '        ' || CONTASANALITICAS.NOME_CONTA;
                             ELSE
                                OUTROW.DESCRICAO    := '    ' || CONTASANALITICAS.NOME_CONTA;
                             END IF;
                          ELSE
                             IF (LENGTH (VS_MASCARA_PC) = LENGTH (CONTASANALITICAS.CODCONTA_PC)) AND (VCONTCONTASANALITICAS > 1) THEN
                                OUTROW.DESCRICAO    := '        ' || CONTASANALITICAS.CODREDUZIDO_PC || ' - ' || CONTASANALITICAS.NOME_CONTA;
                             ELSE
                                OUTROW.DESCRICAO    := '    ' || CONTASANALITICAS.CODREDUZIDO_PC || ' - ' || CONTASANALITICAS.NOME_CONTA;
                             END IF;
                          END IF;
						  
                          IF NVL(VS_ESTRUTURADFC, 'N') = 'N' OR (DRE_ANALITICO.TIPORESULTADO = 'S') then
                            IF VN_VALORCONTAANALITICAANT < 0 THEN
                              OUTROW.VALORANTERIOR := '(' || TRIM(TO_CHAR(ABS(VN_VALORCONTAANALITICAANT), '999,999,999,999.99')) || ')';
                            ELSE
                              OUTROW.VALORANTERIOR := TRIM(TO_CHAR(ABS(VN_VALORCONTAANALITICAANT), '999,999,999,999.99'));
                            END IF;

                            IF VN_VALORCONTAANALITICA < 0 THEN
                              OUTROW.VALOR         := '(' || TRIM(TO_CHAR(ABS(VN_VALORCONTAANALITICA), '999,999,999,999.99')) || ')';
                            ELSE
                              OUTROW.VALOR         := TRIM(TO_CHAR(ABS(VN_VALORCONTAANALITICA), '999,999,999,999.99'));
                            END IF;
                          ELSE
                            IF VN_VALORCONTAANALITICAANT > 0 THEN
                              OUTROW.VALORANTERIOR := '(' || TRIM(TO_CHAR(ABS(VN_VALORCONTAANALITICAANT), '999,999,999,999.99')) || ')';
                            ELSE
                              OUTROW.VALORANTERIOR := TRIM(TO_CHAR(ABS(VN_VALORCONTAANALITICAANT), '999,999,999,999.99'));
                            END IF;

                            IF VN_VALORCONTAANALITICA > 0 THEN
                              OUTROW.VALOR         := '(' || TRIM(TO_CHAR(ABS(VN_VALORCONTAANALITICA), '999,999,999,999.99')) || ')';
                            ELSE
                              OUTROW.VALOR         := TRIM(TO_CHAR(ABS(VN_VALORCONTAANALITICA), '999,999,999,999.99'));
                            END IF;
                          END IF;

                          IF OUTROW.VALOR = '.00' THEN
                             OUTROW.VALOR := '0.00';
                          END IF;

                          IF OUTROW.VALORANTERIOR = '.00' THEN
                             OUTROW.VALORANTERIOR := '0.00';
                          END IF;

                          OUTROW.ORDEM                      := NULL;
                          OUTROW.VALORBASE                  := VN_VALORCONTAANALITICA;
                          OUTROW.NEGRITO                    := 'N';
						              OUTROW.CODCONTA_PC                := CONTASANALITICAS.CODCONTA_PC;
                          OUTROW.RECEBELANCTO               := CONTASANALITICAS.RECEBE_LANCTO;
                          OUTROW.NATUREZACONTA              := CONTASANALITICAS.NATUREZA;
                          OUTROW.TIPOCONTA                  := CONTASANALITICAS.TIPOCONTA;

                          VRETORNO(VN_POSICAO_EM_ALTERACAO) := OUTROW;
                       END IF;
                    END IF;
                 END LOOP;
              END IF;
           ELSIF DRE_ANALITICO.TIPORESULTADO = 'V' THEN                                                                                --Tipo V
              VN_VALOR := DRE_ANALITICO.VALORMANUAL;
           ELSIF DRE_ANALITICO.TIPORESULTADO = 'E' THEN                                                                                --Tipo E
              VN_VALOR := CALCULAREXPRESSAO(DRE_ANALITICO.DESC_RESULTADO, PANO, 'N');

              IF PANALISEHORIZONTAL = 'S' THEN
                 VN_VALORANTERIOR := CALCULAREXPRESSAO(DRE_ANALITICO.DESC_RESULTADO, PANO -1, 'S');
              END IF;
           END IF;

           --ATRIBUI VALORES QUANDO NÃO FOR CONTAS ANALÍTICAS MARCADO = 'S'
           IF ((VN_VALOR <> 0) OR (VN_VALORANTERIOR <> 0) OR (PEXIBIRCONTASSALDOZERO = 'S')) AND (PEXIBIRCONTASANALITICAS = 'N') THEN
              LIMPAVARIAVEIS ();
              VRETORNO.EXTEND;

              IF PEXIBIRCODREDUZIDO = 'N' THEN
                 OUTROW.DESCRICAO := '    ' || DRE_ANALITICO.DESC_OPERACAO;
              ELSE
                 OUTROW.DESCRICAO := '    ' || DRE_ANALITICO.CODCONTAREDUZIDO || '-' || DRE_ANALITICO.DESC_OPERACAO;
              END IF;
              
							IF (NVL(VS_ESTRUTURADFC, 'N') = 'N') OR (DRE_ANALITICO.TIPORESULTADO = 'S') then
							  --Colocar os parêntes caso o valor seja negativo
							  IF VN_VALOR < 0 THEN
								  OUTROW.VALOR := '(' || TRIM(TO_CHAR(ABS(VN_VALOR), '999,999,999,999.99')) || ')';
							  ELSE
								  OUTROW.VALOR := TRIM(TO_CHAR(ABS(VN_VALOR), '999,999,999,999.99'));
							  END IF;

							  IF VN_VALORANTERIOR < 0 THEN
								  OUTROW.VALORANTERIOR := '(' ||
														TRIM(TO_CHAR(ABS(VN_VALORANTERIOR),
															 '999,999,999,999.99')) || ')';
							  ELSE
								  OUTROW.VALORANTERIOR := TRIM(TO_CHAR(ABS(VN_VALORANTERIOR),
															 '999,999,999,999.99'));
							  END IF;
							ELSE
                IF DRE_ANALITICO.TIPORESULTADO = 'S' THEN 
                 IF VN_VALOR < 0 THEN
                    OUTROW.VALOR := '(' || TRIM(TO_CHAR(ABS(VN_VALOR), '999,999,999,999.99')) || ')';
                  ELSE
                    OUTROW.VALOR := TRIM(TO_CHAR(ABS(VN_VALOR), '999,999,999,999.99'));
                  END IF;                
                ELSE  
							  --Colocar os parêntes caso o valor seja positivo
                  IF VN_VALOR > 0 THEN
                    OUTROW.VALOR := '(' || TRIM(TO_CHAR(ABS(VN_VALOR), '999,999,999,999.99')) || ')';
                  ELSE
                    OUTROW.VALOR := TRIM(TO_CHAR(ABS(VN_VALOR), '999,999,999,999.99'));
                  END IF;
                END IF;

							  IF VN_VALORANTERIOR > 0 THEN
								  OUTROW.VALORANTERIOR := '(' ||
														TRIM(TO_CHAR(ABS(VN_VALORANTERIOR),
															 '999,999,999,999.99')) || ')';
							  ELSE
								  OUTROW.VALORANTERIOR := TRIM(TO_CHAR(ABS(VN_VALORANTERIOR),
															 '999,999,999,999.99'));
							  END IF;
			  
							END IF;

              IF OUTROW.VALOR = '.00' THEN
                 OUTROW.VALOR := '0.00';
              END IF;

              IF OUTROW.VALORANTERIOR = '.00' THEN
                 OUTROW.VALORANTERIOR := '0.00';
              END IF;

              OUTROW.ORDEM           := NULL;
              OUTROW.VALORBASE       := VN_VALOR;
              OUTROW.CODCONFIGPAI    := VN_POSICAO_EM_ALTERACAO;
              OUTROW.NEGRITO         := 'N';
              OUTROW.NOTAEXPLICATIVA := VS_NOTAEXPLICATIVA;
              OUTROW.CODCONTA_PC     := DRE_ANALITICO.CODCONTA_PC;
              OUTROW.RECEBELANCTO    := DRE_ANALITICO.RECEBELANCTO;
              OUTROW.NATUREZACONTA   := DRE_ANALITICO.NATUREZACONTA;
              OUTROW.TIPOCONTA       := DRE_ANALITICO.TIPOCONTA;
              VRETORNO(VRETORNO.COUNT) := OUTROW;
           END IF;
        END IF;
        
        IF NVL(VS_ESTRUTURADFC, 'N') = 'N' OR DRE_ANALITICO.TIPORESULTADO = 'S' THEN
          VN_VLRTOTAL            := VN_VLRTOTAL + VN_VALOR;
          VN_VLRSUBTOTAL         := VN_VLRSUBTOTAL + VN_VALOR;
          VN_VLRSUBTOTALANTERIOR := VN_VLRSUBTOTALANTERIOR + VN_VALORANTERIOR;
        ELSE    
          VN_VLRTOTAL            := VN_VLRTOTAL - VN_VALOR;
          VN_VLRSUBTOTAL         := VN_VLRSUBTOTAL - VN_VALOR;
          VN_VLRSUBTOTALANTERIOR := VN_VLRSUBTOTALANTERIOR - VN_VALORANTERIOR;        
        END IF;

        IF PEXIBIRRATEIO_RECEITA_CUSTO = 'S' THEN

          OPEN RATEIOCURSOR FOR V_SQL_RATEIO
          USING
            DRE_ANALITICO.CODCONTAREDUZIDO, PCODPLANOCONTA, PANO, PMESINI, PMESFIM,
            DRE_ANALITICO.CODCONTAREDUZIDO, PCODPLANOCONTA, PANO, PMESINI, PMESFIM;
          LOOP
            FETCH RATEIOCURSOR INTO RATEIO;
            EXIT WHEN RATEIOCURSOR%NOTFOUND;

            VRETORNO.EXTEND;
            VN_POSICAO_EM_ALTERACAO := VRETORNO.COUNT;
            OUTROW.DESCRICAO    := '                        ' || RATEIO.CODIGO || '-'|| RATEIO.DESCRICAO;
            IF RATEIO.VALOR < 0 THEN
               OUTROW.VALOR    :=  '(' || TRIM(TO_CHAR(ABS(RATEIO.VALOR), '999,999,999,999.99')) || ')';
            ELSE
               OUTROW.VALOR    :=   TRIM(TO_CHAR(ABS(RATEIO.VALOR), '999,999,999,999.99'));
            END IF;

            OUTROW.VALOR         := OUTROW.VALOR;
            OUTROW.ORDEM         := NULL;
            OUTROW.VALORBASE     := RATEIO.VALOR;
            OUTROW.NEGRITO       := 'N';
            OUTROW.PERCVERTICAL  := RATEIO.PERCENTUAL; --Quando esta opção esta marcado, o função vertical e desabilitada na rotina 2122

            VRETORNO(VN_POSICAO_EM_ALTERACAO) := OUTROW;
          END LOOP;
        END IF;

        FETCH CURSORANALITICO INTO DRE_ANALITICO;
     END LOOP LOOP_SUBCONSULTA_DO_ANALITICO;


     --ACHA POSIÇÃO PRINCIPAL PARA SETAR VALORES ACHADOS NAS INFORMAí‡í•ES ANALÍTICAS
     VN_POSICAO_EM_ALTERACAO := 0;

     FOR VN_POSICAO IN 1 .. VRETORNO.COUNT
     LOOP
       IF (VRETORNO(VN_POSICAO).ORDEM = DRE_CABECALHO.ORDEM) THEN
          OUTROW                     := VRETORNO(VN_POSICAO);
          VN_POSICAO_EM_ALTERACAO    := VN_POSICAO;
          EXIT;
       END IF;
     END LOOP;

     IF (VN_POSICAO_EM_ALTERACAO > 0) THEN
        IF OUTROW.TIPO = 'G' THEN
				IF VN_VLRSUBTOTAL < 0 THEN
					 OUTROW.VALOR := '(' || TRIM(TO_CHAR(ABS(VN_VLRSUBTOTAL), '999,999,999,999.99')) || ')';
				  ELSE
					 OUTROW.VALOR := TRIM(TO_CHAR(ABS(VN_VLRSUBTOTAL), '999,999,999,999.99'));
				  END IF;
				IF NVL(VS_ESTRUTURADFC, 'N') = 'N' OR DRE_ANALITICO.TIPORESULTADO = 'S' then
				  

				  IF VN_VLRSUBTOTALANTERIOR < 0 THEN   
					 OUTROW.VALORANTERIOR := '(' || TRIM(TO_CHAR(ABS(VN_VLRSUBTOTALANTERIOR), '999,999,999,999.99')) || ')';
				  ELSE
					 OUTROW.VALORANTERIOR := TRIM(TO_CHAR(ABS(VN_VLRSUBTOTALANTERIOR), '999,999,999,999.99'));
				  END IF;
				ELSE

 

				  IF VN_VLRSUBTOTALANTERIOR > 0 THEN
					 OUTROW.VALORANTERIOR := '(' || TRIM(TO_CHAR(ABS(VN_VLRSUBTOTALANTERIOR), '999,999,999,999.99')) || ')';
				  ELSE
					 OUTROW.VALORANTERIOR := TRIM(TO_CHAR(ABS(VN_VLRSUBTOTALANTERIOR), '999,999,999,999.99'));
				  END IF;
	  
				END IF;

        OUTROW.VALORBASE := VN_VLRSUBTOTAL;
     END IF;

        IF OUTROW.VALOR = '.00' THEN
           OUTROW.VALOR := '0.00';
        END IF;

        IF OUTROW.VALORANTERIOR = '.00' THEN
           OUTROW.VALORANTERIOR := '0.00';
        END IF;

        OUTROW.VALORTEMP         := VN_VLRSUBTOTAL;
        OUTROW.VALORTEMPANTERIOR := VN_VLRSUBTOTALANTERIOR;

        VRETORNO(VN_POSICAO_EM_ALTERACAO) := OUTROW;
     END IF;

     VN_VLRSUBTOTAL         := 0;
     VN_VLRSUBTOTALANTERIOR := 0;
  END LOOP LOOP_CONSULTA_CONTAS_PAI;

  FOR VN_POSICAO IN 1 .. VRETORNO.COUNT
  LOOP
    IF (VRETORNO(VN_POSICAO).TIPO = 'T') OR (VRETORNO(VN_POSICAO).TIPO = 'A') THEN
      VN_POSICAOATUAL := VN_POSICAO;

      OUTROW := VRETORNO(VN_POSICAOATUAL);

      VN_VALOR := CALCULAREXPRESSAO(OUTROW.RESULTADO, PANO, 'N');

      OUTROW := VRETORNO(VN_POSICAOATUAL);

      IF PANALISEHORIZONTAL = 'S' THEN
         VN_VALORANTERIOR := CALCULAREXPRESSAO(OUTROW.RESULTADO, PANO -1, 'S');
         OUTROW := VRETORNO(VN_POSICAOATUAL);
      END IF;


       IF VN_VALOR < 0  THEN
             OUTROW.VALOR := '(' || TRIM(TO_CHAR(ABS(VN_VALOR), '999,999,999,999.99')) || ')';
        ELSE
             OUTROW.VALOR := TRIM(TO_CHAR(ABS(VN_VALOR), '999,999,999,999.99'));
       END IF;


      IF VN_VALORANTERIOR < 0 THEN
         OUTROW.VALORANTERIOR := '(' || TRIM(TO_CHAR(ABS(VN_VALORANTERIOR), '999,999,999,999.99')) || ')';
      ELSE
         OUTROW.VALORANTERIOR := TRIM(TO_CHAR(ABS(VN_VALORANTERIOR), '999,999,999,999.99'));
      END IF;

      IF OUTROW.VALOR = '.00' THEN
         OUTROW.VALOR := '0.00';
      END IF;

      IF OUTROW.VALORANTERIOR = '.00' THEN
         OUTROW.VALORANTERIOR := '0.00';
      END IF;

      OUTROW.VALORTEMP          := VN_VALOR;
      OUTROW.VALORTEMPANTERIOR  := VN_VALORANTERIOR;
      OUTROW.VALORBASE          := VN_VALOR;
      OUTROW.CODCONFIGPAI       := VN_POSICAOATUAL;
      OUTROW.NEGRITO            := 'S';
      OUTROW.SEMREGRA           := 'N';
      OUTROW.NOTAEXPLICATIVA    := VS_NOTAEXPLICATIVA;
      VRETORNO(VN_POSICAOATUAL) := OUTROW;
      IF NVL(VS_ESTRUTURADFC, 'N') = 'N' OR DRE_ANALITICO.TIPORESULTADO = 'S' THEN
        VN_VLRTOTAL := VN_VLRTOTAL + VN_VALOR;
      ELSE
         VN_VLRTOTAL := VN_VLRTOTAL - VN_VALOR;
      END IF;   
    END IF;
  END LOOP;

  VN_VLRBASE := 0;

  IF PANALISEVERTICAL = 'S' THEN
    FOR VN_POSICAO IN 1 .. VRETORNO.COUNT
    LOOP
      OUTROW                  := VRETORNO(VN_POSICAO);
      VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

      IF OUTROW.BASEVERTICAL = 'S' THEN
         VN_VLRBASE := OUTROW.VALORBASE;
      END IF;

      IF (VN_VLRBASE <> 0) AND (TRIM(OUTROW.VALOR) IS NOT NULL) THEN
         OUTROW.PERCVERTICAL := ROUND((OUTROW.VALORBASE * 100) / VN_VLRBASE, 2);
      END IF;

      VRETORNO(VN_POSICAO_EM_ALTERACAO) := OUTROW;
    END LOOP;
  END IF;

  --LIMPA VETOR COM VALORES ZERADOS E OPÇÃO EXIBIRSALDOZERO = 'N'
  IF (PEXIBIRCONTASSALDOZERO = 'N') AND (PEXIBIRCONTASANALITICAS = 'N') THEN
    FOR VN_POSICAO IN 1 .. VRETORNO.COUNT
    LOOP
      OUTROW                  := VRETORNO(VN_POSICAO);
      VN_POSICAO_EM_ALTERACAO := VN_POSICAO;

      IF OUTROW.VALORBASE = 0 AND OUTROW.VALORANTERIOR = '0,00' THEN
         VRETORNO.DELETE(VN_POSICAO_EM_ALTERACAO);
      END IF;
    END LOOP;
  END IF;

  RETURN VRETORNO;
EXCEPTION
   WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR (-20000, 'Ocorreu erro ao executar o SQL de dados.' || CHR (13) || CHR(13) || VS_ERRO || CHR (13) || SQLERRM);
END FNC_RETORNADADOS;

END PKG_DRECONTABIL;
--Eduardo - 24/07/2012
