CREATE OR REPLACE PROCEDURE P_CTBCONTABILIZALANCAMENTOS(PCODFILIAL        IN VARCHAR2,
                                                        PCODREGRA         IN NUMBER,
                                                        PDTINICIO         IN DATE,
                                                        PDTFINAL          IN DATE,
                                                        PCODPLANOCONTA    IN NUMBER,
                                                        PCODFUNCLOGADO    IN NUMBER,
                                                        PGERAADVERTENCIAS IN VARCHAR2,
                                                        PCONSOLIDAR       IN VARCHAR2,
                                                        RESULTADO        OUT VARCHAR2) IS

  --VARIÁVEIS
  VN_NUMLANCTOANTERIOR          NUMBER;
  VN_NUMTRANSLANCTO             NUMBER;
  VN_NUMLANCTOLANCINTERMEDIARIA NUMBER;
  VS_CODCONTAREDUZIDO VARCHAR2(40);
  VN_NUMLANCTOCONTABIL          NUMBER;
  VN_NUMLANCTOAUX               NUMBER;
  VN_NUMSEQ                     NUMBER DEFAULT 0;
  VN_NUMSEQOUT                  NUMBER DEFAULT 0;
  VN_NUMSEQAUX                  NUMBER DEFAULT 0;
  VD_DATALANCTO                 DATE;
  VD_DATALANCTO_ORIG            DATE;
  VN_VALORLANCTO                NUMBER;
  V_SQLERRO                     VARCHAR2(2000);
  VN_MESLANCTO                  NUMBER;
  VN_DIALANCTO                  NUMBER;
  VN_ANOLANCTO                  NUMBER;
  VS_DATASITUACAOESPECIAL       VARCHAR2(1) := 'N';
  VS_MESABERTO                  VARCHAR2(1);
  VS_MESBLOQUEADO               VARCHAR2(1);
  VS_DIABLOQUEADO               VARCHAR2(1);
  VS_PERIODOABERTO              VARCHAR2(1);
  VS_PODECONTABILIZAR           VARCHAR2(1);
  VS_USACENTROCUSTO             VARCHAR2(2);
  VS_USACENTRORECEITA           VARCHAR2(2);
  VN_LOTEINTEGRACAO             NUMBER(22);
  V_SQL                         CLOB;
  VN_CODGRUPOBEM                NUMBER;
  VS_AGRUPAMENTOREGRA           PCREGRACONTABIL.AGRUPAMENTOREGRA%TYPE;
  VN_ANOLANCTO_LINHAANT    PCLANCAMENTO.ANO%TYPE;
  VN_MESLANCTO_LINHAANT    PCLANCAMENTO.ANO%TYPE;
  VN_NUMLANCTOCONTABIL_LINHAANT    PCLANCAMENTO.NUMLANCTO%TYPE;
  VN_CONTADOR_COMMIT            NUMBER DEFAULT 0;

  TYPE TYPE_INTERMEDIARIA IS RECORD(
   CODFILIAL            PCLANCAMENTO.CODFILIAL%TYPE,
   NUMTRANSLANCTO       PCLANCINTERMEDIARIA.NUMTRANSLANCTO%TYPE,
   DATALANCTO           PCLANCAMENTO.DTLANC%TYPE,
   CODREDUZIDO_PC       PCMODELOPC.CODREDUZIDO_PC%TYPE,
   VALOR                PCLANCAMENTO.VALOR%TYPE,
   NATUREZA             PCLANCAMENTO.NATUREZA%TYPE,
   DOCUMENTO            PCLANCAMENTO.DOCUMENTO%TYPE,
   CODHISTORICO         PCLANCAMENTO.CODHISTORICO%TYPE,
   HISTORICO_COMPL      PCLANCAMENTO.HISTORICO_COMPL%TYPE,
   CODREGRA             PCLANCAMENTO.CODREGRAINTEGRACAO%TYPE,
   NUMTRANSOPERACAO     PCLANCINTERMEDIARIA.NUMTRANSOPERACAO%TYPE,
   DATAINTEGRACAO       PCLANCAMENTO.DATAINTEGRACAO%TYPE,
   INCONSISTENCIA       PCLANCINTERMEDIARIA.INCONSISTENCIA%TYPE,
   AGRUPAMENTOREGRA     PCREGRACONTABIL.AGRUPAMENTOREGRA%TYPE,
   DIACONTABILIZACAO    PCREGRACONTABIL.DIACONTABILIZACAO%TYPE,
   CODFATOGERADOR       PCREGRACONTABIL.CODFATOGERADOR%TYPE,
   NUMTRANSCENTROCUSTO  PCLANCINTERMEDIARIA.NUMTRANSCENTROCUSTO%TYPE,
   CODPARCEIRO          PCLANCAMENTO.CODPARCEIRO%TYPE,
   TIPOPARCEIRO         PCLANCAMENTO.TIPOPARCEIRO%TYPE,
   CODGRUPOBEM          PCPRODCIAP.CODGRUPOBEM%TYPE,
   NUMSEQ               PCLANCINTERMEDIARIA.NUMSEQ%TYPE,
   CODCONTA_PC          PCMODELOPC.CODCONTA_PC%TYPE
);

  LANCINTERMEDIARIA TYPE_INTERMEDIARIA;

  CURSOR_LANCAMENTOS SYS_REFCURSOR;

  TYPE T_FILIAIS IS TABLE OF VARCHAR2(2);
  FILIAIS T_FILIAIS;


  PROCEDURE P_INSERE_LANCAMENTO_FILA(PCODFILIAL IN VARCHAR2,
                                     PCODPLANOCONTA IN NUMBER,
                                     PMES IN NUMBER,
                                     PANO IN NUMBER,
                                     PCODREDUZIDO_PC IN VARCHAR2,
                                     PCODCONTA_PC IN VARCHAR2,
                                     PVALORDEBITO IN NUMBER,
                                     PVALORCREDITO IN NUMBER,
                                     PVLRDEBENCERRAMENTO IN NUMBER,
                                     PVLRCREENCERRAMENTO IN NUMBER,
                                     PVLRDEBCONCIL IN NUMBER,
                                     PVLRCRECONCIL IN NUMBER,
                                     PVLRDEBCONCILENCERRAMENTO IN NUMBER,
                                     PVLRCRECONCILENCERRAMENTO IN NUMBER,
                                     PS_TIPOPARCEIRO IN VARCHAR2,
                                     PN_CODPARCEIRO IN NUMBER ) IS
  BEGIN

      INSERT INTO PCFILASALDOCNB
      (CODIGO,
       CODFILIAL,
       CODPLANOCONTA,
       MES,
       ANO,
       CODREDUZIDO_PC,
       CODCONTA_PC,
       VALORDEBITO,
       VALORCREDITO,
       VLRDEBENCERRAMENTO,
       VLRCREENCERRAMENTO,
       VLRDEBCONCIL,
       VLRCRECONCIL,
       VLRDEBCONCILENCERRAMENTO,
       VLRCRECONCILENCERRAMENTO,
       EQUIPAMENTO,
       ROTINA,
       USUARIO,
       DATAHORA,
       CODPARCEIRO,
       TIPOPARCEIRO)
    VALUES
      (DFSEQ_PCFILASALDOCNB.NEXTVAL,
       PCODFILIAL,                   
       PCODPLANOCONTA,               
       PMES,                         
       PANO,                         
       PCODREDUZIDO_PC,              
       PCODCONTA_PC,                  
       PVALORDEBITO,                 
       PVALORCREDITO,                
       PVLRDEBENCERRAMENTO,          
       PVLRCREENCERRAMENTO,          
       PVLRDEBCONCIL,                
       PVLRCRECONCIL,                
       PVLRDEBCONCILENCERRAMENTO,    
       PVLRCRECONCILENCERRAMENTO,    
       NULL,--SYS_CONTEXT('USERENV', 'TERMINAL'),    
       NULL,--SYS_CONTEXT('USERENV', 'MODULE'),    
       NULL,--SYS_CONTEXT('USERENV', 'OS_USER'),   
       SYSDATE,
       PN_CODPARCEIRO,
       PS_TIPOPARCEIRO);                    
  
  END;

  /****************************************************************************
   PROCEDURE PARA GRAVAR OS DADOS DA TABELA PCLANCAMENTO
  *****************************************************************************/
  PROCEDURE P_GRAVA_DADOS_PCLANCAMENTO(PN_NUMTRANSLANCTO     IN   NUMBER,
                                       PN_NUMLANCTO          IN   NUMBER,
                                       PN_NUMSEQ             IN   NUMBER,
                                       PN_MES                IN   NUMBER,
                                       PN_ANO                IN   NUMBER,
                                       PS_CODFILIAL          IN   VARCHAR2,
                                       PN_CODPLANOCONTA      IN   NUMBER,
                                       PS_CODREDUZIDO_PC     IN   VARCHAR2,
                                       PD_DTLANC             IN   DATE,
                                       PS_NATUREZA           IN   VARCHAR2,
                                       PS_DOCUMENTO          IN   VARCHAR2,
                                       PN_VALOR              IN   NUMBER,
                                       PN_CODHISTORICO       IN   NUMBER,
                                       PS_HISTORICO_COMPL    IN  VARCHAR2,
                                       PN_CODREGRAINTEGRACAO IN  NUMBER,
                                       PN_CODPARCEIRO        IN  NUMBER,
                                       PS_TIPOPARCEIRO       IN  VARCHAR2,
                                       PN_CODGRUPOBEM        IN  NUMBER DEFAULT NULL,
                                       PN_NUMTRANSPCLANCINT  IN  NUMBER,
                                       PS_CODFILIALPCLANCINT IN  VARCHAR2,
                                       PN_NUMSEQPCLANCINT    IN  NUMBER,
                                       PS_CODCONTA_PC        IN VARCHAR2,
                                       PD_DATALANCTO_ORIG    IN DATE) IS
  BEGIN
     IF NOT (PS_CODFILIAL member of FILIAIS) THEN
       FILIAIS.EXTEND;
       FILIAIS(FILIAIS.COUNT) := PS_CODFILIAL;
     END IF;

     INSERT INTO PCLANCAMENTO
      (NUMTRANSLANCTO,
       NUMLANCTO,
       NUMSEQ,
       MES,
       ANO,
       CODFILIAL,
       CODPLANOCONTA,
       CODREDUZIDO_PC,
       DTLANC,
       NATUREZA,
       DOCUMENTO,
       LOTE,
       VALOR,
       CODHISTORICO,
       HISTORICO_COMPL,
       TIPO_LANCAMENTO,
       EXCLUIDO,
       ENCERRADO,
       DTHRALTERACAO,
       CODFUNCALTERACAO,
       CONCILIADO,
       CODREGRAINTEGRACAO,
       CODFUNCINTEGRACAO,
       DATAINTEGRACAO,
       CODPARCEIRO,
       TIPOPARCEIRO,
       LOTEINTEGRACAO,
       CODGRUPOBEM,
       MULTIFILIAL)
    VALUES
      (PN_NUMTRANSLANCTO,
       PN_NUMLANCTO,
       PN_NUMSEQ,
       PN_MES,
       PN_ANO,
       PS_CODFILIAL,
       PN_CODPLANOCONTA,
       PS_CODREDUZIDO_PC,
       TRUNC(PD_DTLANC),
       PS_NATUREZA,
       PS_DOCUMENTO,
       '0',
       PN_VALOR,
       PN_CODHISTORICO,
       PS_HISTORICO_COMPL,
       'I',
       'N',
       'N',
       SYSDATE,
       PCODFUNCLOGADO,
       'N',
       PN_CODREGRAINTEGRACAO,
       PCODFUNCLOGADO,
       TRUNC(SYSDATE),
       PN_CODPARCEIRO,
       PS_TIPOPARCEIRO,
       VN_LOTEINTEGRACAO,
       PN_CODGRUPOBEM,
       'N' --TRATADO NO METODO ATUALIZA_CAMPO_MULTIFILIAL()
       );

	INSERT INTO PCLOGLANCAMENTO
      (CODALTERACAO,
	   NUMTRANSLANCTO,
       NUMLANCTO,
       NUMSEQ,
       MES,
       ANO,
       CODFILIAL,
       CODPLANOCONTA,
       CODREDUZIDO_PC,
       DTLANC,
       NATUREZA,
       DOCUMENTO,
       LOTE,
       VALOR,
       CODHISTORICO,
       HISTORICO_COMPL,
       EXCLUIDO,
       ENCERRADO,
       DTHRALTERACAO,
       CODFUNCALTERACAO,
       CONCILIADO,
       CODREGRAINTEGRACAO,
       CODFUNCINTEGRACAO,
       DATAINTEGRACAO,
       CODPARCEIRO,
       TIPOPARCEIRO,
       LOTEINTEGRACAO,
       CODGRUPOBEM,
       MULTIFILIAL,
	   DTHREXCLUSAO,
       MAQUINA,
       PROGRAMA,
       USUARIOREDE,
       OPERACAO)
    VALUES
      (DEFSEQ_PCLOGLANCAMENTO.NEXTVAL,
	   PN_NUMTRANSLANCTO,
       PN_NUMLANCTO,
       PN_NUMSEQ,
       PN_MES,
       PN_ANO,
       PS_CODFILIAL,
       PN_CODPLANOCONTA,
       PS_CODREDUZIDO_PC,
       TRUNC(PD_DTLANC),
       PS_NATUREZA,
       PS_DOCUMENTO,
       '0',
       PN_VALOR,
       PN_CODHISTORICO,
       PS_HISTORICO_COMPL,
       'N',
       'N',
       SYSDATE,
       PCODFUNCLOGADO,
       'N',
       PN_CODREGRAINTEGRACAO,
       PCODFUNCLOGADO,
       TRUNC(SYSDATE),
       PN_CODPARCEIRO,
       PS_TIPOPARCEIRO,
       VN_LOTEINTEGRACAO,
       PN_CODGRUPOBEM,
       'N', --TRATADO NO METODO ATUALIZA_CAMPO_MULTIFILIAL()
	   SYSDATE,
	   SUBSTR(SYS_CONTEXT('USERENV', 'TERMINAL'), 1, 64),
	   SUBSTR(SYS_CONTEXT('USERENV', 'MODULE'), 1, 48),
       SUBSTR(SYS_CONTEXT('USERENV', 'OS_USER'), 1, 30),
       'I'
       );



       P_INSERE_LANCAMENTO_FILA(PS_CODFILIAL,
                                PN_CODPLANOCONTA,
                                PN_MES,
                                PN_ANO,
                                PS_CODREDUZIDO_PC,
                                PS_CODCONTA_PC,
                                CASE WHEN PS_NATUREZA = 'D' THEN PN_VALOR ELSE 0 END,
                                CASE WHEN PS_NATUREZA = 'C' THEN PN_VALOR ELSE 0 END,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
                                PS_TIPOPARCEIRO,
                                PN_CODPARCEIRO);


  IF PN_NUMSEQPCLANCINT IS NULL /*REGRA TOTALIZA*/ THEN
   UPDATE PCLANCINTERMEDIARIA
      SET  NUMTRANSPCLANCAMENTO = PN_NUMTRANSLANCTO
           ,DATALANCTO =  PD_DTLANC
     WHERE NUMTRANSLANCTO       = PN_NUMTRANSPCLANCINT
       AND CODPLANOCONTA            = PN_CODPLANOCONTA
       AND CODREDUZIDO_PC       = PS_CODREDUZIDO_PC
       AND NATUREZA             = PS_NATUREZA
       AND DATALANCTO           = PD_DATALANCTO_ORIG
	   AND NUMTRANSPCLANCAMENTO IS NULL;
  ELSE
   UPDATE PCLANCINTERMEDIARIA
      SET NUMTRANSPCLANCAMENTO = PN_NUMTRANSLANCTO
          ,DATALANCTO =  PD_DTLANC
    WHERE NUMTRANSLANCTO    = PN_NUMTRANSPCLANCINT
      AND CODFILIAL = PS_CODFILIALPCLANCINT
      AND NUMSEQ  = PN_NUMSEQPCLANCINT
      AND DATALANCTO           = PD_DATALANCTO_ORIG;
   END IF;

  END;

  /****************************************************************************
   PROCEDURE PARA GRAVAR OS DADOS DA TABELA PCRATEIOCONTABILCC - CENTRO DE CUSTO
  *****************************************************************************/
  PROCEDURE P_GRAVA_DADOS_CENTROCUSTO(PN_NUMTRANS_CENTROCUSTO    NUMBER,
                                      PN_NUMTRANSLANCTO_CONTABIL NUMBER,
                                      PS_NATUREZA                VARCHAR2
                                      ,PS_AGRUPALANCAMENTO VARCHAR2) IS
  BEGIN
    FOR CENTROCUSTO IN (SELECT LC.CODIGOCENTROCUSTO,
                        CC.DESCRICAO DESCCENTROCUSTO,
                        LC.CODFILIAL,
                        SUM(LC.VALOR) VALOR,
                        MAX(LC.PERCRATEIO) PERCRATEIO,
                        LC.NUMTRANSLANCTO
                  FROM PCLANCINTERMEDIARIACC LC, PCCENTROCUSTO CC
                  WHERE LC.CODIGOCENTROCUSTO = CC.CODIGOCENTROCUSTO
                  AND   LC.NUMTRANSLANCTO = PN_NUMTRANS_CENTROCUSTO
                  AND   LC.AGRUPALANCAMENTO = PS_AGRUPALANCAMENTO
                  AND NOT EXISTS (
                        SELECT 1
                        FROM PCLANCINTERMEDIARIACC A
                        WHERE A.NUMTRANSLANCTO = LC.NUMTRANSLANCTO 
                        AND A.NUMTRANSCENTROCUSTO = LC.NUMTRANSCENTROCUSTO
                        HAVING SUM(A.PERCRATEIO) > 100 AND COUNT(DISTINCT A.PERCRATEIO) > 1
                        GROUP BY A.CODIGOCENTROCUSTO
                            ,A.CODFILIAL
                            ,A.PERCRATEIO
                            ,A.NUMTRANSLANCTO)
                   GROUP BY LC.CODIGOCENTROCUSTO, CC.DESCRICAO, LC.CODFILIAL, LC.NUMTRANSLANCTO
                   UNION ALL
                  SELECT LC.CODIGOCENTROCUSTO
                       ,CC.DESCRICAO DESCCENTROCUSTO
                       ,LC.CODFILIAL
                       ,SUM(LC.VALOR) VALOR
                       ,MAX(LC.PERCRATEIO) PERCRATEIO
                       ,LC.NUMTRANSLANCTO
                    FROM PCLANCINTERMEDIARIACC LC, PCCENTROCUSTO CC
                   WHERE LC.CODIGOCENTROCUSTO = CC.CODIGOCENTROCUSTO
                     AND LC.NUMTRANSCENTROCUSTO = PN_NUMTRANS_CENTROCUSTO
                   GROUP BY LC.CODIGOCENTROCUSTO
                         ,CC.DESCRICAO
                         ,LC.CODFILIAL
                         ,LC.NUMTRANSLANCTO     )
    LOOP
      INSERT INTO PCRATEIOCONTABILCC
        (CODFILIAL,
         NUMTRANSLANCTO,
         CODIGOCENTROCUSTO,
         NATUREZA,
         VALOR,
         PERCRATEIO)
      VALUES
        (CENTROCUSTO.CODFILIAL,
         PN_NUMTRANSLANCTO_CONTABIL,
         CENTROCUSTO.CODIGOCENTROCUSTO,
         PS_NATUREZA,
         ABS(CENTROCUSTO.VALOR),
         CENTROCUSTO.PERCRATEIO);
    END LOOP;
  END;

  /****************************************************************************
   PROCEDURE PARA GRAVAR OS DADOS DA TABELA PCRATEIOCONTABILCR - CENTRO DE RECEITA
  *****************************************************************************/
  PROCEDURE P_GRAVA_DADOS_CENTRORECEITA( PN_NUMTRANS_CENTRORECEITA    NUMBER
                                       , PN_VALOR                     NUMBER
                                       , PN_NUMTRANSLANCTO_CONTABIL   NUMBER
                                       , PS_NATUREZA                  VARCHAR2
                                       , PS_CODREDUZIDO_PC            VARCHAR2
                                       , PN_CODREGRA                  NUMBER
                                       , PD_DATALANCTO                DATE) IS
  BEGIN
    FOR CENTRORECEITA IN (WITH LANCAMENTOS
                            AS (SELECT PCLANCINTERMEDIARIA.NUMTRANSOPERACAO
                                     , PCREGRACONTABIL.CODFATOGERADOR
                                     , PCLANCINTERMEDIARIA.VALOR
                                  FROM PCLANCINTERMEDIARIA
                                     , PCMODELOPC
                                     , PCREGRACONTABIL
                                 WHERE PCLANCINTERMEDIARIA.NUMTRANSOPERACAO = PN_NUMTRANS_CENTRORECEITA
                                   AND PCLANCINTERMEDIARIA.VALOR            = PN_VALOR
                                   AND PCLANCINTERMEDIARIA.CODREDUZIDO_PC   = PCMODELOPC.CODREDUZIDO_PC
                                   AND PCLANCINTERMEDIARIA.CODPLANOCONTA    = PCMODELOPC.CODPLANOCONTA
                                   AND PCLANCINTERMEDIARIA.CODREGRA         = PN_CODREGRA
                                   AND PCLANCINTERMEDIARIA.CODREDUZIDO_PC   = PS_CODREDUZIDO_PC
                                   AND PCLANCINTERMEDIARIA.CODREGRA         = PCREGRACONTABIL.CODREGRA
                                   --AND PCLANCINTERMEDIARIA.DATALANCTO       = PD_DATALANCTO
                                   AND PCMODELOPC.USACENTRORECEITA          = 'S'
                                   AND PCLANCINTERMEDIARIA.DATALANCTO       = PD_DATALANCTO 
                                 GROUP
                                    BY PCLANCINTERMEDIARIA.NUMTRANSOPERACAO
                                     , PCLANCINTERMEDIARIA.VALOR
                                     , PCREGRACONTABIL.CODFATOGERADOR
                               )

                          SELECT C.*
                               , CASE WHEN C.CODFATOGERADOR NOT IN (2, 6, 8)
                                      THEN C.VALORBASE - C.VALORTEMPORARIO
                                      ELSE C.VALORBASE - SUM(C.VALORTEMPORARIO) OVER()
                                 END VLDIFERENCA
                               , CASE WHEN C.MAIORVALOR = MAX(C.MAIORVALOR) OVER() --Aplicar a diferença no maior VALORTEMPORARIO
                                      THEN C.VALORTEMPORARIO + CASE WHEN C.CODFATOGERADOR NOT IN (2, 6, 8)
                                                                    THEN (SUM(C.VALORBASE - C.VALORTEMPORARIO) OVER())
                                                                    ELSE (C.VALORBASE - SUM(C.VALORTEMPORARIO) OVER())
                                                               END
                                      ELSE C.VALORTEMPORARIO
                                 END VALOR
                            FROM (SELECT B.*
                                       , ROUND(CASE WHEN B.CODFATOGERADOR NOT IN (2, 6, 8)
                                                    THEN (SUM(B.VALORBASE) OVER())
                                                    ELSE B.VALORBASE
                                               END * (B.PERCRATEIO / 100), 2) VALORTEMPORARIO
                                       , ROW_NUMBER()
                                            OVER(PARTITION BY B.NUMTRANSLANCTO
                                                 ORDER BY
                                                    B.VALORBASE) MAIORVALOR
                                    FROM (SELECT A.*
                                               , CASE WHEN (SUM(A.VALORBASE) OVER (PARTITION BY A.NUMTRANSLANCTO)) <> 0
                                                      THEN ROUND(((A.VALORBASE / (SUM(A.VALORBASE) OVER (PARTITION BY A.NUMTRANSLANCTO))) * 100), 2)
                                                      ELSE 0
                                                  END PERCRATEIO
                                            FROM (SELECT PCCENTRORECEITA.CODIGOCENTRORECEITA
                                                       , PCCENTRORECEITA.DESCRICAO
                                                       , PCCONSOLIDARECEITA.CODFILIAL
                                                       , LANCAMENTOS.CODFATOGERADOR
                                                       , NVL(PCCONSOLIDARECEITA.NUMTRANSVENDA, PCCONSOLIDARECEITA.NUMTRANSENT) NUMTRANSLANCTO
                                                       , CASE WHEN LANCAMENTOS.CODFATOGERADOR IN (2, 6, 8)
                                                              THEN LANCAMENTOS.VALOR
                                                              ELSE SUM(PCCONSOLIDARECEITA.VLTOTALNOTA)
                                                         END VALORBASE
                                                    FROM PCCONSOLIDARECEITA
                                                       , PCCENTRORECEITA
                                                       , PCITENSCLASSIFICACAOCR
                                                       , LANCAMENTOS
                                                   WHERE PCCONSOLIDARECEITA.CODIGO = PCITENSCLASSIFICACAOCR.CODIGOITEMCLASSIFICACAO
                                                     AND PCCONSOLIDARECEITA.CLASSIFICACAOCENTRORECEITA = PCITENSCLASSIFICACAOCR.CLASSIFICACAO
                                                     AND PCITENSCLASSIFICACAOCR.CODIGOCENTRORECEITA = PCCENTRORECEITA.CODIGOCENTRORECEITA
                                                     AND NVL(PCCONSOLIDARECEITA.NUMTRANSVENDA, PCCONSOLIDARECEITA.NUMTRANSENT) = LANCAMENTOS.NUMTRANSOPERACAO
                                                   GROUP
                                                      BY PCCENTRORECEITA.CODIGOCENTRORECEITA, PCCENTRORECEITA.DESCRICAO
                                                       , PCCONSOLIDARECEITA.CODFILIAL, NVL(PCCONSOLIDARECEITA.NUMTRANSVENDA, PCCONSOLIDARECEITA.NUMTRANSENT)
                                                       , LANCAMENTOS.CODFATOGERADOR, LANCAMENTOS.VALOR
                                                 ) A
                                         ) B
                                 ) C
    )
    LOOP
      INSERT INTO PCRATEIOCONTABILCR
        (CODFILIAL,
         NUMTRANSLANCTO,
         CODIGOCENTRORECEITA,
         NATUREZA,
         VALOR,
         PERCRATEIO)
      VALUES
        (CENTRORECEITA.CODFILIAL,
         PN_NUMTRANSLANCTO_CONTABIL,
         CENTRORECEITA.CODIGOCENTRORECEITA,
         PS_NATUREZA,
         ABS(CENTRORECEITA.VALOR),
         CENTRORECEITA.PERCRATEIO);
    END LOOP;
  END;

  /****************************************************************************
   FUNÇÃO QUE VERIFICA SE LANÇAMENTO JÁ EXISTE E PEGA O VALOR DELE SE EXISTIR
  *****************************************************************************/
  FUNCTION F_VALOR_SE_TIVER_LANCTO(PS_CODFILIAL   IN VARCHAR2,
                                   PD_DATA        IN DATE,
                                   PS_CODREDUZIDO IN VARCHAR2,
                                   PN_CODREGRA    IN NUMBER,
                                   PS_NATUREZA    IN VARCHAR2)
    RETURN NUMBER IS
    VN_VALOR NUMBER;
  BEGIN
    BEGIN
    IF PS_CODFILIAL = -1 THEN

      SELECT VALOR
      INTO VN_VALOR
      FROM PCLANCAMENTO
      WHERE MULTIFILIAL = 'S'
      AND   CODPLANOCONTA = PCODPLANOCONTA
      AND   CODREDUZIDO_PC     = PS_CODREDUZIDO
      AND   DTLANC             = PD_DATA
      AND   CODREGRAINTEGRACAO = PN_CODREGRA
      AND   TIPO_LANCAMENTO    = 'I'
      AND   NATUREZA           = PS_NATUREZA
      AND   LOTEINTEGRACAO     = VN_LOTEINTEGRACAO;

    ELSE

      SELECT VALOR
      INTO VN_VALOR
      FROM PCLANCAMENTO
      WHERE (CODFILIAL = PS_CODFILIAL)
      AND   CODPLANOCONTA = PCODPLANOCONTA
      AND   CODREDUZIDO_PC     = PS_CODREDUZIDO
      AND   DTLANC             = PD_DATA
      AND   CODREGRAINTEGRACAO = PN_CODREGRA
      AND   TIPO_LANCAMENTO    = 'I'
      AND   NATUREZA           = PS_NATUREZA
      AND   LOTEINTEGRACAO     = VN_LOTEINTEGRACAO;


    END IF;
    EXCEPTION
      WHEN OTHERS THEN
      VN_VALOR := 0;
    END;

    RETURN VN_VALOR;
  END;

  /****************************************************************************
   FUNÇÃO QUE VERIFICA SE LANÇAMENTO JÁ EXISTE E PEGA O VALOR DELE SE EXISTIR
   PARA UM GRUPO DE BEM
  *****************************************************************************/
  FUNCTION F_VALOR_LANCTO_GRUPOBEM(PS_CODFILIAL   IN VARCHAR2,
                                   PD_DATA        IN DATE,
                                   PS_CODREDUZIDO IN VARCHAR2,
                                   PN_CODREGRA    IN NUMBER,
                                   PS_NATUREZA    IN VARCHAR2,
                                   PN_GRUPOBEM    IN NUMBER)
    RETURN NUMBER IS
    VN_VALOR NUMBER;
  BEGIN
    BEGIN
      SELECT VALOR
      INTO VN_VALOR
      FROM PCLANCAMENTO
      WHERE (CODFILIAL = PS_CODFILIAL OR (PS_CODFILIAL = -1 AND MULTIFILIAL = 'S'))
      AND   CODPLANOCONTA = PCODPLANOCONTA
      AND   CODREDUZIDO_PC     = PS_CODREDUZIDO
      AND   DTLANC             = PD_DATA
      AND   CODREGRAINTEGRACAO = PN_CODREGRA
      AND   TIPO_LANCAMENTO    = 'I'
      AND   NATUREZA           = PS_NATUREZA
      /* AND   LOTEINTEGRACAO     = VN_LOTEINTEGRACAO */
      AND   NVL(LOTEINTEGRACAO, 0) = NVL(VN_LOTEINTEGRACAO, 0)
      AND   CODGRUPOBEM        = PN_GRUPOBEM;
    EXCEPTION
      WHEN OTHERS THEN
      VN_VALOR := 0;
    END;

    RETURN VN_VALOR;
  END;


  /****************************************************************************
   FUNÇÃO QUE VERIFICA SE LANÇAMENTO JÁ EXISTE E PEGA O VALOR DELE SE EXISTIR
  *****************************************************************************/
  FUNCTION F_TEM_LANC_DIARIO(PD_DATA      IN DATE,
                             PN_CODREGRA  IN NUMBER,
                             VN_NUMSEQAUX OUT NUMBER)
    RETURN NUMBER IS
    VN_NUMLANCTO NUMBER;
  BEGIN
     BEGIN
      SELECT NUMLANCTO
      INTO VN_NUMLANCTO
      FROM PCLANCAMENTO
      WHERE CODPLANOCONTA      = PCODPLANOCONTA
      AND   DTLANC             = PD_DATA
      AND   CODREGRAINTEGRACAO = PN_CODREGRA
      AND   TIPO_LANCAMENTO    = 'I'
      AND   LOTEINTEGRACAO     = VN_LOTEINTEGRACAO
      GROUP BY NUMLANCTO;

    EXCEPTION
      WHEN OTHERS THEN
        VN_NUMLANCTO := 0;
    END;

    IF VN_NUMLANCTO > 0 THEN
      BEGIN
        SELECT MAX(NUMSEQ) AS SEQLANCAMENTO
        INTO VN_NUMSEQAUX
        FROM PCLANCAMENTO
        WHERE CODPLANOCONTA      = PCODPLANOCONTA
        AND   DTLANC             = PD_DATA
        AND   NUMLANCTO          = VN_NUMLANCTO
        GROUP BY NUMLANCTO;
      EXCEPTION
        WHEN OTHERS THEN
          VN_NUMSEQAUX := 0;
      END;
    END IF;

    RETURN VN_NUMLANCTO;
  END;

  /****************************************************************************
   FUNÇÃO QUE VERIFICA SE O MÊS ESTÁ ENCERRADO
  *****************************************************************************/
  FUNCTION F_VERIFICA_MES_ABERTO(PS_CODFILIAL IN VARCHAR2,
                                 PN_ANO       IN NUMBER,
                                 PN_MES       IN NUMBER,
								 PD_DATA      IN DATE)
    RETURN VARCHAR2 IS
    VN_CODENCERRAMENTO NUMBER;
  BEGIN
    BEGIN
      SELECT CODENCERRAMENTO
      INTO VN_CODENCERRAMENTO
      FROM PCENCERRAMENTO
      WHERE CODFILIAL = PS_CODFILIAL
      AND   ANO       = PN_ANO
      --AND   EXTRACT(MONTH FROM DATAINICIAL) <= PN_MES
      --AND   EXTRACT(MONTH FROM DATAFINAL) >= PN_MES;
      AND DATAINICIAL <= PD_DATA
      AND DATAFINAL   >= PD_DATA;


    EXCEPTION
      WHEN OTHERS THEN
        VN_CODENCERRAMENTO := 0;
    END;

    IF VN_CODENCERRAMENTO = 0 THEN
       RETURN 'S';
    ELSE
       RETURN 'N';
    END IF;
  END;

  /****************************************************************************
   FUNÇÃO QUE VERIFICA SE O DIA ESTÁ BLOQUEADO
  *****************************************************************************/
  FUNCTION F_VERIFICA_DIA_BLOQUEADO(PS_CODFILIAL IN VARCHAR2,
                                    PN_ANO       IN NUMBER,
                                    PN_MES       IN NUMBER,
                                    PN_DIA       IN NUMBER)
    RETURN VARCHAR2 IS
    V_SQLAUX VARCHAR(500);
    VS_BLOQUEADO VARCHAR2(1);
  BEGIN
    BEGIN
      V_SQLAUX := 'SELECT NVL(BLOQUEADO, ''N'') BLOQUEADO
                   FROM PCBLOQCONTABDIA
                   WHERE CODFILIAL IN ( ''' || PS_CODFILIAL  || ''' )
                     AND ANO = :PANO
                     AND MES = :PMES
                     AND DIA = :PDIA';

      EXECUTE IMMEDIATE V_SQLAUX INTO VS_BLOQUEADO USING PN_ANO, PN_MES, PN_DIA;
    EXCEPTION
       WHEN NO_DATA_FOUND  THEN 
         VS_BLOQUEADO := 'N';
      WHEN OTHERS THEN
        VS_BLOQUEADO := 'X';
    END;

    RETURN VS_BLOQUEADO;
  END;


  /****************************************************************************
   FUNÇÃO QUE VERIFICA SE O MÊS ESTÁ BLOQUEADO PELA 2106
  *****************************************************************************/
  FUNCTION F_VERIFICA_MES_BLOQUEADO(PS_CODFILIAL IN VARCHAR2,
                                    PN_ANO       IN NUMBER,
                                    PN_MES       IN NUMBER)
    RETURN VARCHAR2 IS
    --VS_MES VARCHAR2(15);
    V_SQLAUX VARCHAR(500);
    VS_BLOQUEADO VARCHAR2(1);
  BEGIN
    BEGIN
      V_SQLAUX := 'SELECT NVL(BLOQUEADO, ''N'') BLOQUEADO
                   FROM PCBLOQCONTABMES
                   WHERE CODFILIAL IN ( ''' || PS_CODFILIAL  || ''' )
                     AND ANO = :PANO
                     AND MES = :PMES';

      EXECUTE IMMEDIATE V_SQLAUX INTO VS_BLOQUEADO USING PN_ANO, PN_MES;
    EXCEPTION
      WHEN NO_DATA_FOUND  THEN 
         VS_BLOQUEADO := 'N';
      WHEN OTHERS THEN
        VS_BLOQUEADO := 'X';
    END;

    RETURN VS_BLOQUEADO;
  END;

    /****************************************************************************
   FUNÇÃO QUE VERIFICA SE A FILIAL ESTA COM SITUAÇÃO ESPECIAL
  *****************************************************************************/
  FUNCTION F_VERIFICA_DTSITUACAOESPECIAL(PS_CODFILIAL IN VARCHAR2,
                                         PD_DATALANCTO IN DATE)
    RETURN VARCHAR2 IS
    VN_CONTADOR NUMBER(3);
    V_SQLAUX VARCHAR(500);
    VS_BLOQUEADO VARCHAR2(1);
  BEGIN
    BEGIN
      V_SQLAUX := 'SELECT COUNT(1)
                    FROM PCCONFFILIALSITUACAOESPECIAL F
                   WHERE F.SITUACAOESPECIAL IN (1, 2, 3, 5)
                     AND F.CODFILIAL  IN ( ''' || PS_CODFILIAL  || ''' )
                     AND F.DATASITUACAOESPECIAL < :DATALANCTO ';

      EXECUTE IMMEDIATE V_SQLAUX INTO VN_CONTADOR USING PD_DATALANCTO;
    EXCEPTION
      WHEN OTHERS THEN
        VN_CONTADOR := 0;
    END;

    IF VN_CONTADOR > 0 THEN
       VS_BLOQUEADO := 'S';
    ELSE
       VS_BLOQUEADO := 'N';
    END IF;

    RETURN VS_BLOQUEADO;
  END;


  /****************************************************************************
   PROCEDURE PARA ATUALIZAR VALOR DO LANÇAMENTO
  *****************************************************************************/
  PROCEDURE P_ATUALIZA_VALOR_LANCTO(PS_CODFILIAL   IN VARCHAR2,
                                    PN_VALOR       IN NUMBER,
                                    PD_DATA        IN DATE,
                                    PS_CODREDUZIDO IN VARCHAR2,
                                    PN_CODREGRA    IN NUMBER,
                                    PS_NATUREZA    IN VARCHAR2,
                                    PN_CODGRUPOBEM IN NUMBER DEFAULT NULL,
                                    PN_NUMTRANSLANCTO IN NUMBER,
                                    PN_NUMTRANSPCLANCINT IN NUMBER,
                                    PS_CODFILIALPCLANCINT IN VARCHAR2,
                                    PN_NUMSEQPCLANCINT IN NUMBER,
                                    PD_DATA_ORIG IN DATE) IS

    V_NUMTRANSLANCTO   NUMBER(38);
    V_PD_DATA_TRUNCADE DATE;
  BEGIN
    
    V_NUMTRANSLANCTO   := 0;
    V_PD_DATA_TRUNCADE := TRUNC(PD_DATA);

    IF PN_CODGRUPOBEM IS NULL THEN
      
      UPDATE PCLANCAMENTO
        SET  VALOR                        = PN_VALOR
      WHERE  CODFILIAL                    = PS_CODFILIAL
      AND    CODPLANOCONTA                = PCODPLANOCONTA
      AND    CODREDUZIDO_PC               = PS_CODREDUZIDO
      AND    DTLANC                       = V_PD_DATA_TRUNCADE
      AND    CODREGRAINTEGRACAO           = PN_CODREGRA
      AND    TIPO_LANCAMENTO              = 'I'
      AND    NATUREZA                     = PS_NATUREZA
      AND    COALESCE(LOTEINTEGRACAO, 0)  = COALESCE(VN_LOTEINTEGRACAO, 0)
      AND    VALOR                        != PN_VALOR;

/*      SELECT  MAX(NUMTRANSLANCTO)
        INTO  V_NUMTRANSLANCTO
      FROM    PCLANCAMENTO
      WHERE   CODFILIAL                    = PS_CODFILIAL
        AND   CODPLANOCONTA                = PCODPLANOCONTA
        AND   CODREDUZIDO_PC               = PS_CODREDUZIDO
        AND   DTLANC                       = V_PD_DATA_TRUNCADE
        AND   CODREGRAINTEGRACAO           = PN_CODREGRA
        AND   TIPO_LANCAMENTO              = 'I'
        AND   NATUREZA                     = PS_NATUREZA
        AND   COALESCE(LOTEINTEGRACAO, 0)  = COALESCE(VN_LOTEINTEGRACAO, 0);*/

    ELSE

        UPDATE PCLANCAMENTO
          SET  VALOR                        = PN_VALOR
        WHERE  CODFILIAL                    = PS_CODFILIAL
        AND    CODPLANOCONTA                = PCODPLANOCONTA
        AND    CODREDUZIDO_PC               = PS_CODREDUZIDO
        AND    DTLANC                       = V_PD_DATA_TRUNCADE
        AND    CODREGRAINTEGRACAO           = PN_CODREGRA
        AND    TIPO_LANCAMENTO              = 'I'
        AND    NATUREZA                     = PS_NATUREZA
        AND    COALESCE(LOTEINTEGRACAO, 0)  = COALESCE(VN_LOTEINTEGRACAO, 0)
        AND    CODGRUPOBEM                  = PN_CODGRUPOBEM
        AND    VALOR                        != PN_VALOR;

/*        SELECT  MAX(NUMTRANSLANCTO)
          INTO  V_NUMTRANSLANCTO
        FROM    PCLANCAMENTO
        WHERE   CODFILIAL                    = PS_CODFILIAL
          AND   CODPLANOCONTA                = PCODPLANOCONTA
          AND   CODREDUZIDO_PC               = PS_CODREDUZIDO
          AND   DTLANC                       = V_PD_DATA_TRUNCADE
          AND   CODREGRAINTEGRACAO           = PN_CODREGRA
          AND   TIPO_LANCAMENTO              = 'I'
          AND   NATUREZA                     = PS_NATUREZA
          AND   COALESCE(LOTEINTEGRACAO, 0)  = COALESCE(VN_LOTEINTEGRACAO, 0)
          AND   CODGRUPOBEM                  = PN_CODGRUPOBEM;*/

    END IF;

/*    UPDATE PCLANCINTERMEDIARIA
      SET  NUMTRANSPCLANCAMENTO   = V_NUMTRANSLANCTO,
           DATALANCTO             = PD_DATA
    WHERE NUMTRANSLANCTO = PN_NUMTRANSPCLANCINT
      AND CODFILIAL      = PS_CODFILIALPCLANCINT
--      AND NUMSEQ  		 = PN_NUMSEQPCLANCINT 
--      AND DATAINTEGRACAO = (PD_DATA_ORIG)
      AND DATALANCTO     = (PD_DATA_ORIG);
      */

  END;

  /****************************************************************************
   PROCEDURE PARA ATUALIZAR VALOR DO CENTRO DE CUSTO
  *****************************************************************************/
  PROCEDURE P_ATUALIZA_VALOR_CENTROCUSTO(PN_NUMTRANS_INTERMEDIARIACC IN NUMBER,
                                         PS_CODFILIAL                IN VARCHAR2,
                                         PD_DATA                     IN DATE,
                                         PS_CODREDUZIDO              IN VARCHAR2,
                                         PN_CODREGRA                 IN NUMBER) IS

    VN_NUMTRANSLANCTO NUMBER(38);
    VN_NUMTRANSLANCTO_CENTROCUSTO NUMBER(38);
    VN_TOTAL_CENTROCUSTO NUMBER(12,2);
    VN_TOTAL_PERC_RATEIO NUMBER(6,2);
    VN_PERC_RATEIO NUMBER(6,2);
    VN_QTD_RATEIO NUMBER(6);
    VN_QTD_TOTAL_RATEIO NUMBER(6);
    VS_NATUREZA VARCHAR2(1);
  BEGIN
    VN_TOTAL_PERC_RATEIO          := 0;
    VN_PERC_RATEIO                := 0;
    VN_NUMTRANSLANCTO             := 0;
    VN_NUMTRANSLANCTO_CENTROCUSTO := 0;
    VN_TOTAL_CENTROCUSTO          := 0;
    VN_QTD_RATEIO                 := 0;
    VN_QTD_TOTAL_RATEIO           := 0;

    BEGIN
      SELECT NUMTRANSLANCTO, NATUREZA
      INTO VN_NUMTRANSLANCTO, VS_NATUREZA
      FROM PCLANCAMENTO
      WHERE CODFILIAL          = PS_CODFILIAL
      AND   CODPLANOCONTA      = PCODPLANOCONTA
      AND   CODREDUZIDO_PC     = PS_CODREDUZIDO
      AND   DTLANC             = PD_DATA
      AND   CODREGRAINTEGRACAO = PN_CODREGRA
      AND   TIPO_LANCAMENTO    = 'I';
    EXCEPTION
      WHEN OTHERS THEN
        VN_NUMTRANSLANCTO := 0;
    END;

    IF VN_NUMTRANSLANCTO > 0 THEN
      FOR CENTROCUSTO IN (SELECT CODFILIAL,
                                 CODIGOCENTROCUSTO,
                                 VALOR,
                                 PERCRATEIO
                          FROM PCLANCINTERMEDIARIACC
                          WHERE NUMTRANSCENTROCUSTO = PN_NUMTRANS_INTERMEDIARIACC)
      LOOP
        BEGIN
          SELECT NUMTRANSLANCTO
          INTO VN_NUMTRANSLANCTO_CENTROCUSTO
          FROM PCRATEIOCONTABILCC
          WHERE NUMTRANSLANCTO    = VN_NUMTRANSLANCTO
          AND   CODIGOCENTROCUSTO = CENTROCUSTO.CODIGOCENTROCUSTO
          AND   CODFILIAL         = PS_CODFILIAL;
        EXCEPTION
          WHEN OTHERS THEN
            VN_NUMTRANSLANCTO_CENTROCUSTO := 0;
        END;

        --CASO NÃO EXISTA O REGISTRO DO LANÇAMENTO, INSERE UM NOVO
        IF VN_NUMTRANSLANCTO_CENTROCUSTO = 0 THEN
          INSERT INTO PCRATEIOCONTABILCC
            (CODFILIAL,
             NUMTRANSLANCTO,
             CODIGOCENTROCUSTO,
             NATUREZA,
             VALOR,
             PERCRATEIO)
          VALUES
            (CENTROCUSTO.CODFILIAL,
             VN_NUMTRANSLANCTO,
             CENTROCUSTO.CODIGOCENTROCUSTO,
             VS_NATUREZA,
             ABS(CENTROCUSTO.VALOR),
             CENTROCUSTO.PERCRATEIO);
        ELSE
          --EDITA O VALOR PARA OS LANCTOS ENCONTRADOS
          UPDATE PCRATEIOCONTABILCC
            SET VALOR = VALOR + ABS(CENTROCUSTO.VALOR)
          WHERE NUMTRANSLANCTO = VN_NUMTRANSLANCTO
          AND   CODIGOCENTROCUSTO = CENTROCUSTO.CODIGOCENTROCUSTO
          AND   CODFILIAL         = PS_CODFILIAL;
        END IF;
      END LOOP;

      --TOTALIZA OS VALORES DE CENTRO DE CUSTO PARA EDITAR O PERCENTUAL
      FOR CENTROCUSTO IN (SELECT VALOR
                          FROM PCRATEIOCONTABILCC
                          WHERE NUMTRANSLANCTO = VN_NUMTRANSLANCTO)
      LOOP
        VN_TOTAL_CENTROCUSTO := VN_TOTAL_CENTROCUSTO + ABS(CENTROCUSTO.VALOR);
        VN_QTD_TOTAL_RATEIO  := VN_QTD_TOTAL_RATEIO + 1;
      END LOOP;

      --EDITA OS PERCENTUAIS DO CENTRO DE CUSTO
      FOR CENTROCUSTO IN (SELECT VALOR,
                                 CODFILIAL,
                                 CODIGOCENTROCUSTO
                          FROM PCRATEIOCONTABILCC
                          WHERE NUMTRANSLANCTO = VN_NUMTRANSLANCTO)
      LOOP
        VN_QTD_RATEIO  := VN_QTD_RATEIO + 1;
        VN_PERC_RATEIO := ROUND((ABS(CENTROCUSTO.VALOR) * 100) / VN_TOTAL_CENTROCUSTO, 2);

        --TOTAIS
        VN_TOTAL_PERC_RATEIO := VN_TOTAL_PERC_RATEIO + ROUND((ABS(CENTROCUSTO.VALOR) * 100) / VN_TOTAL_CENTROCUSTO, 2);

        IF (VN_QTD_RATEIO = VN_QTD_TOTAL_RATEIO) AND (VN_TOTAL_PERC_RATEIO < 100) THEN
           VN_PERC_RATEIO := VN_PERC_RATEIO + (100 - VN_TOTAL_PERC_RATEIO);
        END IF;

        UPDATE PCRATEIOCONTABILCC
          SET PERCRATEIO = VN_PERC_RATEIO
        WHERE NUMTRANSLANCTO = VN_NUMTRANSLANCTO
        AND   CODIGOCENTROCUSTO = CENTROCUSTO.CODIGOCENTROCUSTO
        AND   CODFILIAL         = PS_CODFILIAL;
      END LOOP;
    END IF;
  END;


  /****************************************************************************
   PROCEDURE PARA PASSAR O STATUS DO LANÇAMENTO PARA 'I - INTEGRADO'
  *****************************************************************************/
  PROCEDURE P_PASSA_STATUS_INTEGRADO(PN_NUMTRANSLANCTO    IN NUMBER,
                                     PN_NUMLANCTOCONTABIL IN NUMBER,
                                     PN_NUMTRANSLANCTOPCLANC   IN NUMBER,
                                     PS_CODFILIAL         IN VARCHAR2, 
                                     PD_DTLANCINI IN DATE,
                                     PD_DTLANCFIM IN DATE,
                                     PD_DTLANCTO IN DATE ,
                                     PS_AGRUPAMENTO IN VARCHAR2,
                                     PS_CODREDUZIDO IN VARCHAR2) IS
  BEGIN
  
  IF PS_AGRUPAMENTO = 'I' THEN
    UPDATE PCLANCINTERMEDIARIA
      SET STATUS            = 'I',
          NUMLANCTOCONTABIL = PN_NUMLANCTOCONTABIL
    WHERE NUMTRANSLANCTO    = PN_NUMTRANSLANCTO
      AND DATAINTEGRACAO BETWEEN PD_DTLANCINI AND PD_DTLANCFIM
      AND STATUS            != 'I';
  ELSE
    UPDATE PCLANCINTERMEDIARIA
      SET STATUS            = 'I',
          NUMLANCTOCONTABIL = PN_NUMLANCTOCONTABIL,
          DATALANCTO = PD_DTLANCTO,
          NUMTRANSPCLANCAMENTO = PN_NUMTRANSLANCTOPCLANC
    WHERE NUMTRANSLANCTO    = PN_NUMTRANSLANCTO
      AND DATAINTEGRACAO BETWEEN PD_DTLANCINI AND PD_DTLANCFIM
      AND CODREDUZIDO_PC = PS_CODREDUZIDO
      AND STATUS            != 'I';  
  
  END IF;
      
  END;

  PROCEDURE ATUALIZA_CAMPO_MULTIFILIAL(PANO NUMBER,PMES NUMBER,PNUMLANCTO NUMBER, PDTLANC DATE) IS
  BEGIN
    /*UPDATE PCLANCAMENTO
       SET MULTIFILIAL = CASE WHEN (SELECT COUNT(DISTINCT L2.CODFILIAL)
                                      FROM PCLANCAMENTO L2
                                     WHERE L2.CODPLANOCONTA = PCLANCAMENTO.CODPLANOCONTA
                                       AND L2.ANO           = PCLANCAMENTO.ANO
                                       AND L2.MES           = PCLANCAMENTO.MES
									   AND L2.DTLANC        = PCLANCAMENTO.DTLANC
                                       AND L2.NUMLANCTO     = PCLANCAMENTO.NUMLANCTO) > 1
                              THEN 'S' ELSE 'N' END
     WHERE CODPLANOCONTA = PCODPLANOCONTA
       AND ANO           = PANO
       AND MES           = PMES
       AND NUMLANCTO     = PNUMLANCTO;*/
    IF FILIAIS.COUNT > 1 THEN
      UPDATE PCLANCAMENTO SET MULTIFILIAL = 'S'
       WHERE CODPLANOCONTA = PCODPLANOCONTA
         AND ANO           = PANO
         AND MES           = PMES
		 AND DTLANC BETWEEN '01/' || TO_CHAR(PMES) || '/' || TO_CHAR(PANO) AND LAST_DAY('01/' || TO_CHAR(PMES) || '/' || TO_CHAR(PANO))
         AND NUMLANCTO     = PNUMLANCTO;
    END IF;

    FILIAIS.DELETE;
  END;


  FUNCTION F_PERIODOABERTO(PN_ANO       IN NUMBER,
                           PS_CODFILIAL IN VARCHAR2) RETURN VARCHAR2 IS
    VN_ANOEXERCICIO NUMBER;
  BEGIN
    BEGIN
      SELECT C.ANO
      INTO VN_ANOEXERCICIO
      FROM V_CTBCONFEXERCICIO C
      WHERE ANO = PN_ANO
      AND   CODFILIAL = PS_CODFILIAL;
    EXCEPTION
      WHEN OTHERS THEN
        VN_ANOEXERCICIO := 0;
    END;

    IF VN_ANOEXERCICIO = 0 THEN
       RETURN 'N';
    ELSE
       RETURN 'S';
    END IF;
  END;
BEGIN
  FILIAIS              := T_FILIAIS();
  VN_NUMLANCTOCONTABIL := 0;
  VN_NUMSEQ            := 0;
  VN_NUMSEQOUT         := 0;
  VN_MESLANCTO         := 0;
  VN_DIALANCTO         := 0;
  VN_ANOLANCTO         := 0;
  RESULTADO            := '';
  VS_MESABERTO         := '';
  VS_MESBLOQUEADO      := '';
  VS_PERIODOABERTO     := '';

  VS_PODECONTABILIZAR  := '';
  VN_NUMLANCTOANTERIOR := 0;

  VN_CONTADOR_COMMIT   := 0;

  BEGIN
    SELECT
     AGRUPAMENTOREGRA
     INTO VS_AGRUPAMENTOREGRA
    FROM PCREGRACONTABIL
    WHERE CODREGRA = PCODREGRA;
  EXCEPTION
    WHEN OTHERS THEN
    VS_AGRUPAMENTOREGRA := '';
  END;

  SELECT SEQ_PCLANCAMENTOLOTEINTEGRACAO.NEXTVAL
    INTO VN_LOTEINTEGRACAO
  FROM DUAL;

  V_SQL := '
  SELECT * FROM (
 SELECT A.CODFILIAL,
        A.NUMTRANSLANCTO,
        A.DATALANCTO,
        A.CODREDUZIDO_PC,
        A.VALOR,
        A.NATUREZA,
        A.DOCUMENTO,
        A.CODHISTORICO,
        A.HISTORICO_COMPL,
        A.CODREGRA,
        A.NUMTRANSOPERACAO,
        A.DATAINTEGRACAO,
        A.INCONSISTENCIA,
        R.AGRUPAMENTOREGRA,
        NVL(R.DIACONTABILIZACAO, '''') DIACONTABILIZACAO,
        R.CODFATOGERADOR,
        A.NUMTRANSCENTROCUSTO,
        A.CODPARCEIRO,
        A.TIPOPARCEIRO,
        A.CODGRUPOBEM,
        A.NUMSEQ,
        M.CODCONTA_PC
   FROM PCLANCINTERMEDIARIA A,
        PCREGRACONTABIL R,
        PCREGRAFILIAL RF,
        PCMODELOPC M,

        (SELECT CODFILIAL
           FROM PCCONFFILIAL
          WHERE DECODE(:PCONSOLIDAR,
                       ''S'',
                       TO_CHAR(CODGRUPOFILIAL),
                       CODFILIAL) IN (:CODFILIAL)
            AND ANO = EXTRACT(YEAR FROM TO_DATE(:PDTFINAL))) FI
  WHERE A.CODFILIAL IN (FI.CODFILIAL)
    AND A.DATAINTEGRACAO BETWEEN :PDTINICIO AND :PDTFINAL
    AND A.CODREGRA = :PCODREGRA
    AND A.CODFILIAL = RF.CODFILIAL
    AND M.CODPLANOCONTA = A.CODPLANOCONTA
    AND M.CODREDUZIDO_PC = A.CODREDUZIDO_PC
    AND A.CODREGRA = RF.CODREGRA
    AND RF.CODREGRA = R.CODREGRA
    AND A.INCONSISTENCIA IN (''0'', ''6'')
    AND A.STATUS = ''P''
    AND NVL(A.REGRATOTALIZA,''N'') = ''N''
    AND A.CONTABILIZAR = ''S''
UNION ALL
SELECT  CODFILIAL,
        NUMTRANSLANCTO,
        DATALANCTO,
        CODREDUZIDO_PC,
        SUM(VALOR) VALOR,
        NATUREZA,
        DOCUMENTO,
        CODHISTORICO,
        HISTORICO_COMPL,
        CODREGRA,
        NUMTRANSOPERACAO,
        DATAINTEGRACAO,
        INCONSISTENCIA,
        AGRUPAMENTOREGRA,
        DIACONTABILIZACAO,
        CODFATOGERADOR,

        NUMTRANSCENTROCUSTO,
        CODPARCEIRO,
        TIPOPARCEIRO,
        CODGRUPOBEM,
        null as NUMSEQ
        ,CODCONTA_PC
FROM (
 SELECT A.CODFILIAL,
        A.NUMTRANSLANCTO,
        A.DATALANCTO,
        A.CODREDUZIDO_PC,
        SUM(A.VALOR) VALOR,
        A.NATUREZA,
        A.DOCUMENTO,
        A.CODHISTORICO,
        A.HISTORICO_COMPL,
        A.CODREGRA,
        A.NUMTRANSOPERACAO,
        A.DATAINTEGRACAO,
        A.INCONSISTENCIA,
        R.AGRUPAMENTOREGRA,
        NVL(R.DIACONTABILIZACAO, '''') DIACONTABILIZACAO,
        R.CODFATOGERADOR,
        NVL((SELECT C.NUMTRANSLANCTO
            FROM PCLANCINTERMEDIARIACC C

           WHERE C.NUMTRANSLANCTO = A.NUMTRANSLANCTO
             AND A.NUMTRANSCENTROCUSTO IS NOT NULL
             AND EXISTS (SELECT 1
                    FROM PCLANCINTERMEDIARIACC C1
                   WHERE C1.NUMTRANSLANCTO = C.NUMTRANSLANCTO
                     AND C1.CODIGOCENTROCUSTO = C.CODIGOCENTROCUSTO
                AND c.NUMTRANSCENTROCUSTO <> c1.NUMTRANSCENTROCUSTO
                     AND C1.PERCRATEIO = C.PERCRATEIO
                     AND C1.AGRUPALANCAMENTO = C.AGRUPALANCAMENTO
                     AND EXISTS (SELECT 1 FROM PCLANCINTERMEDIARIACC B
                        WHERE B.NUMTRANSLANCTO = C1.NUMTRANSLANCTO
                        AND B.CODIGOCENTROCUSTO =  C1.CODIGOCENTROCUSTO
                        AND C1.NUMTRANSCENTROCUSTO = A.NUMTRANSCENTROCUSTO)  )
           GROUP BY C.NUMTRANSLANCTO), A.NUMTRANSCENTROCUSTO)  AS NUMTRANSCENTROCUSTO,
        0 AS CODPARCEIRO,
        ''0'' AS TIPOPARCEIRO,
        A.CODGRUPOBEM,
        NULL NUMSEQ,
        M.CODCONTA_PC
   FROM PCLANCINTERMEDIARIA A,
        PCREGRACONTABIL R,
        PCREGRAFILIAL RF,
        PCMODELOPC M,
        
        (SELECT CODFILIAL
           FROM PCCONFFILIAL
          WHERE DECODE(:PCONSOLIDAR,
                       ''S'',
                       TO_CHAR(CODGRUPOFILIAL),
                       CODFILIAL) IN (:CODFILIAL)
            AND ANO = EXTRACT(YEAR FROM TO_DATE(:PDTFINAL))) FI
  WHERE A.CODFILIAL IN (FI.CODFILIAL)
    AND A.DATAINTEGRACAO BETWEEN :PDTINICIO AND :PDTFINAL
    AND A.CODREGRA = :PCODREGRA
    AND A.CODFILIAL = RF.CODFILIAL
    AND A.CODREGRA = RF.CODREGRA
    AND RF.CODREGRA = R.CODREGRA
    AND M.CODPLANOCONTA = A.CODPLANOCONTA
    AND M.CODREDUZIDO_PC = A.CODREDUZIDO_PC
    AND A.INCONSISTENCIA IN (''0'', ''6'')
    AND A.STATUS = ''P''
    AND NVL(A.REGRATOTALIZA,''N'') = ''S''
    AND A.CONTABILIZAR = ''S''
GROUP BY A.CODFILIAL,
         A.NUMTRANSLANCTO,
         A.DATALANCTO,
         A.CODREDUZIDO_PC,
         A.NATUREZA,
         A.DOCUMENTO,
         A.CODHISTORICO,
         A.HISTORICO_COMPL,
         A.CODREGRA,
         A.NUMTRANSOPERACAO,
         A.DATAINTEGRACAO,
         A.INCONSISTENCIA,
         R.AGRUPAMENTOREGRA,
         NVL(R.DIACONTABILIZACAO, ''''),
         R.CODFATOGERADOR,
         A.NUMTRANSCENTROCUSTO,
         A.CODGRUPOBEM,
         M.CODCONTA_PC
         )
         GROUP BY         CODFILIAL,
        NUMTRANSLANCTO,
        DATALANCTO,
        CODREDUZIDO_PC,

        NATUREZA,
        DOCUMENTO,
        CODHISTORICO,
        HISTORICO_COMPL,
        CODREGRA,
        NUMTRANSOPERACAO,
        DATAINTEGRACAO,
        INCONSISTENCIA,
        AGRUPAMENTOREGRA,
        DIACONTABILIZACAO,
        CODFATOGERADOR,

        NUMTRANSCENTROCUSTO,
        CODPARCEIRO,
        TIPOPARCEIRO,
        CODGRUPOBEM,
        CODCONTA_PC
         )        ';

  IF VS_AGRUPAMENTOREGRA = 'GRUPO_BEM' THEN
    V_SQL := V_SQL || ' ORDER BY CODGRUPOBEM, EXTRACT(MONTH FROM DATALANCTO), NUMTRANSLANCTO, NUMSEQ '; --todo NUMSEQ
  ELSIF VS_AGRUPAMENTOREGRA = 'D' THEN
    V_SQL := V_SQL || ' ORDER BY DATALANCTO, CODREDUZIDO_PC, NUMTRANSLANCTO ';
  ELSE
    V_SQL := V_SQL || ' ORDER BY EXTRACT(MONTH FROM DATALANCTO), NUMTRANSLANCTO, NUMSEQ ';
  END IF;


  --INSERT INTO SQL_GERADO VALUES(SYSDATE,V_SQL,NULL);
  --COMMIT;

  OPEN CURSOR_LANCAMENTOS FOR DBMS_LOB.SUBSTR(PKG_CTBFUNCOESCONTEIS.TRATARMULTIFILIAL(PCODFILIAL,':CODFILIAL','N',V_SQL))
      USING PCONSOLIDAR, PDTFINAL, PDTINICIO, PDTFINAL, PCODREGRA,
            PCONSOLIDAR, PDTFINAL, PDTINICIO, PDTFINAL, PCODREGRA;
  LOOP
  FETCH CURSOR_LANCAMENTOS
  INTO LANCINTERMEDIARIA;
  EXIT WHEN CURSOR_LANCAMENTOS%NOTFOUND;

    IF (VN_MESLANCTO <> EXTRACT(MONTH FROM LANCINTERMEDIARIA.DATALANCTO)) OR
       (VN_ANOLANCTO <> EXTRACT(YEAR FROM LANCINTERMEDIARIA.DATALANCTO))  THEN
       VN_MESLANCTO := EXTRACT(MONTH FROM LANCINTERMEDIARIA.DATALANCTO);
       VN_ANOLANCTO := EXTRACT(YEAR FROM LANCINTERMEDIARIA.DATALANCTO);
       VN_DIALANCTO := EXTRACT(DAY FROM LANCINTERMEDIARIA.DATALANCTO);

       VS_MESABERTO := F_VERIFICA_MES_ABERTO(LANCINTERMEDIARIA.CODFILIAL, VN_ANOLANCTO, VN_MESLANCTO, LANCINTERMEDIARIA.DATALANCTO);

       IF VS_MESABERTO = 'S' THEN
          VS_MESBLOQUEADO := F_VERIFICA_MES_BLOQUEADO(LANCINTERMEDIARIA.CODFILIAL, VN_ANOLANCTO, VN_MESLANCTO);
          IF VS_MESBLOQUEADO = 'N' THEN
             VS_MESABERTO := 'S';
             VS_DIABLOQUEADO := F_VERIFICA_DIA_BLOQUEADO(LANCINTERMEDIARIA.CODFILIAL, VN_ANOLANCTO, VN_MESLANCTO, VN_DIALANCTO);
             VS_DATASITUACAOESPECIAL := F_VERIFICA_DTSITUACAOESPECIAL(LANCINTERMEDIARIA.CODFILIAL,LANCINTERMEDIARIA.DATALANCTO);
          ELSE
             VS_MESABERTO := 'N';
          END IF;
       END IF;
    END IF;

    IF (EXTRACT(YEAR FROM PDTINICIO) <> EXTRACT(YEAR FROM LANCINTERMEDIARIA.DATALANCTO)) THEN
       VS_PERIODOABERTO := F_PERIODOABERTO(EXTRACT(YEAR FROM LANCINTERMEDIARIA.DATALANCTO), LANCINTERMEDIARIA.CODFILIAL);
    ELSE
       VS_PERIODOABERTO := 'S';
    END IF;

    IF (VS_DIABLOQUEADO = 'N') AND (VS_MESABERTO = 'S') AND (VS_PERIODOABERTO = 'S') AND
       (VS_DATASITUACAOESPECIAL = 'N') AND
       ((LANCINTERMEDIARIA.INCONSISTENCIA = '0') OR
        ((LANCINTERMEDIARIA.INCONSISTENCIA = '6') AND (PGERAADVERTENCIAS = 'S'))) THEN

      --Verifica se a conta usa centro de custo
      SELECT 
        CASE 
          WHEN LANCINTERMEDIARIA.NUMTRANSCENTROCUSTO IS NOT NULL THEN
            COALESCE(M.USACENTROCUSTO,'N')
          ELSE 
            'N'
          END
            ,COALESCE(M.USACENTRORECEITA,'N')
          INTO
             VS_USACENTROCUSTO
            ,VS_USACENTRORECEITA
      FROM PCMODELOPC M
      WHERE M.CODREDUZIDO_PC = LANCINTERMEDIARIA.CODREDUZIDO_PC
        AND M.CODPLANOCONTA  = PCODPLANOCONTA;

      VN_CONTADOR_COMMIT := VN_CONTADOR_COMMIT + 1;

      --Inicia processo
      IF (VN_NUMLANCTOLANCINTERMEDIARIA IS NOT NULL)                         AND
         (VN_NUMLANCTOLANCINTERMEDIARIA <> LANCINTERMEDIARIA.NUMTRANSLANCTO) OR
         ((VS_CODCONTAREDUZIDO <> LANCINTERMEDIARIA.CODREDUZIDO_PC) AND 
          (VN_NUMLANCTOLANCINTERMEDIARIA = LANCINTERMEDIARIA.NUMTRANSLANCTO) AND
          (LANCINTERMEDIARIA.AGRUPAMENTOREGRA <> 'I') ) THEN
         P_PASSA_STATUS_INTEGRADO(VN_NUMLANCTOLANCINTERMEDIARIA, VN_NUMLANCTOCONTABIL, VN_NUMTRANSLANCTO, LANCINTERMEDIARIA.CODFILIAL, PDTINICIO, PDTFINAL, VD_DATALANCTO, LANCINTERMEDIARIA.AGRUPAMENTOREGRA, VS_CODCONTAREDUZIDO);

         VN_NUMSEQ      := 0;
         VN_VALORLANCTO := 0;
         ATUALIZA_CAMPO_MULTIFILIAL(VN_ANOLANCTO_LINHAANT,VN_MESLANCTO_LINHAANT,VN_NUMLANCTOCONTABIL_LINHAANT, LANCINTERMEDIARIA.DATALANCTO);

       IF VN_CONTADOR_COMMIT >= 500 THEN
         VN_CONTADOR_COMMIT := 0;
         COMMIT;
       END IF;

      END IF;

      VD_DATALANCTO := LANCINTERMEDIARIA.DATALANCTO;
      VD_DATALANCTO_ORIG := LANCINTERMEDIARIA.DATALANCTO;
      VN_CODGRUPOBEM := 0;

      IF (LANCINTERMEDIARIA.AGRUPAMENTOREGRA = 'M') AND (LANCINTERMEDIARIA.DIACONTABILIZACAO = 'P') THEN
         VD_DATALANCTO := TO_DATE('01' || TO_CHAR(VD_DATALANCTO, 'MM') || TO_CHAR(VD_DATALANCTO, 'YYYY'), 'DDMMYYYY');
      ELSIF (LANCINTERMEDIARIA.AGRUPAMENTOREGRA = 'M') AND (LANCINTERMEDIARIA.DIACONTABILIZACAO = 'U') THEN
         VD_DATALANCTO := LAST_DAY(VD_DATALANCTO);
      ELSIF (LANCINTERMEDIARIA.AGRUPAMENTOREGRA = 'GRUPO_BEM') THEN
         VN_CODGRUPOBEM := LANCINTERMEDIARIA.CODGRUPOBEM;
         VD_DATALANCTO := LAST_DAY(VD_DATALANCTO);
      END IF;

      ---------------------------------------------------------------------------------
      -- AGRUPAMENTO INDIVIDUAL
      ---------------------------------------------------------------------------------
      IF LANCINTERMEDIARIA.AGRUPAMENTOREGRA = 'I' THEN
        ---------------------------------------------------------------------------------
        V_SQLERRO := 'GERANDO PRÓXIMO NUMLANCTOCONTABIL';
        ---------------------------------------------------------------------------------
        IF VN_NUMSEQ = 0 THEN
           P_CTBSEQLANCAMENTO(LANCINTERMEDIARIA.CODFILIAL, PCODPLANOCONTA, VD_DATALANCTO, TRUE, VN_NUMLANCTOCONTABIL);
        END IF;

        VN_NUMSEQ := NVL(VN_NUMSEQ,0) + 1;

        SELECT SEQPCLANCAMENTO.NEXTVAL
         INTO VN_NUMTRANSLANCTO
        FROM DUAL;

        ---------------------------------------------------------------------------------
        V_SQLERRO := 'GRAVANDO DADOS CONTÁBEIS P_GRAVA_DADOS_PCLANCAMENTO()';
        ---------------------------------------------------------------------------------
        P_GRAVA_DADOS_PCLANCAMENTO(VN_NUMTRANSLANCTO, VN_NUMLANCTOCONTABIL, VN_NUMSEQ,
                                   EXTRACT(MONTH FROM VD_DATALANCTO), EXTRACT(YEAR FROM VD_DATALANCTO),
                                   LANCINTERMEDIARIA.CODFILIAL, PCODPLANOCONTA, LANCINTERMEDIARIA.CODREDUZIDO_PC, VD_DATALANCTO,
                                   LANCINTERMEDIARIA.NATUREZA, LANCINTERMEDIARIA.DOCUMENTO, LANCINTERMEDIARIA.VALOR,
                                   LANCINTERMEDIARIA.CODHISTORICO, LANCINTERMEDIARIA.HISTORICO_COMPL, LANCINTERMEDIARIA.CODREGRA,
                                   LANCINTERMEDIARIA.CODPARCEIRO, LANCINTERMEDIARIA.TIPOPARCEIRO, NULL,
                                   LANCINTERMEDIARIA.NUMTRANSLANCTO, LANCINTERMEDIARIA.CODFILIAL, LANCINTERMEDIARIA.NUMSEQ, LANCINTERMEDIARIA.CODCONTA_PC, VD_DATALANCTO_ORIG);


        VN_NUMSEQ := NVL(VN_NUMSEQ,0) + NVL(VN_NUMSEQOUT,0);

        ---------------------------------------------------------------------------------
        V_SQLERRO := 'VALIDA SE A PERNA DO LANÇAMENTO TEM CENTRO DE CUSTO';
        ---------------------------------------------------------------------------------
        IF (LANCINTERMEDIARIA.NUMTRANSCENTROCUSTO IS NOT NULL) AND (VS_USACENTROCUSTO = 'S') THEN
           P_GRAVA_DADOS_CENTROCUSTO(LANCINTERMEDIARIA.NUMTRANSCENTROCUSTO, VN_NUMTRANSLANCTO, LANCINTERMEDIARIA.NATUREZA, LANCINTERMEDIARIA.HISTORICO_COMPL || LANCINTERMEDIARIA.CODREDUZIDO_PC || LANCINTERMEDIARIA.CODFILIAL);
        END IF;
        IF (VS_USACENTRORECEITA = 'S') THEN
           P_GRAVA_DADOS_CENTRORECEITA(LANCINTERMEDIARIA.NUMTRANSOPERACAO, LANCINTERMEDIARIA.VALOR, VN_NUMTRANSLANCTO, LANCINTERMEDIARIA.NATUREZA, LANCINTERMEDIARIA.CODREDUZIDO_PC, LANCINTERMEDIARIA.CODREGRA, VD_DATALANCTO);
        END IF;

      ---------------------------------------------------------------------------------
      -- AGRUPAMENTO POR GRUPO DO BEM
      ---------------------------------------------------------------------------------
      ELSIF (VN_CODGRUPOBEM > 0) AND (LANCINTERMEDIARIA.AGRUPAMENTOREGRA = 'GRUPO_BEM') THEN

        ---------------------------------------------------------------------------------
        V_SQLERRO := 'EXECUTANDO FUNÇÃO F_VALOR_LANCTO_GRUPOBEM()';
        ---------------------------------------------------------------------------------
        VN_VALORLANCTO := F_VALOR_LANCTO_GRUPOBEM(LANCINTERMEDIARIA.CODFILIAL, VD_DATALANCTO,
                                                  LANCINTERMEDIARIA.CODREDUZIDO_PC, LANCINTERMEDIARIA.CODREGRA,
                                                  LANCINTERMEDIARIA.NATUREZA, LANCINTERMEDIARIA.CODGRUPOBEM);

        IF (VN_VALORLANCTO = 0) THEN
           ---------------------------------------------------------------------------------
           V_SQLERRO := 'EXECUTANDO FUNÇÃO F_TEM_LANC_DIARIO()';
           ---------------------------------------------------------------------------------
           VN_NUMSEQAUX := 0;

           VN_NUMLANCTOAUX := F_TEM_LANC_DIARIO(VD_DATALANCTO, LANCINTERMEDIARIA.CODREGRA, VN_NUMSEQAUX);

           IF VN_NUMLANCTOAUX = 0 THEN
              ---------------------------------------------------------------------------------
              V_SQLERRO := 'GERANDO PRÓXIMO NUMLANCTOCONTABIL';
              ---------------------------------------------------------------------------------
              P_CTBSEQLANCAMENTO(LANCINTERMEDIARIA.CODFILIAL, PCODPLANOCONTA, VD_DATALANCTO, TRUE, VN_NUMLANCTOCONTABIL);
           ELSE
              VN_NUMLANCTOCONTABIL := VN_NUMLANCTOAUX;
              VN_NUMSEQ            := VN_NUMSEQAUX;
           END IF;

           VN_NUMSEQ := NVL(VN_NUMSEQ,0) + 1;

           SELECT SEQPCLANCAMENTO.NEXTVAL
           INTO VN_NUMTRANSLANCTO
           FROM DUAL;

           ---------------------------------------------------------------------------------
           V_SQLERRO := 'GRAVANDO DADOS CONTÁBEIS P_GRAVA_DADOS_PCLANCAMENTO()';
           ---------------------------------------------------------------------------------
           P_GRAVA_DADOS_PCLANCAMENTO(VN_NUMTRANSLANCTO, VN_NUMLANCTOCONTABIL, VN_NUMSEQ,
                                      EXTRACT(MONTH FROM VD_DATALANCTO), EXTRACT(YEAR FROM VD_DATALANCTO),
                                      LANCINTERMEDIARIA.CODFILIAL, PCODPLANOCONTA, LANCINTERMEDIARIA.CODREDUZIDO_PC, VD_DATALANCTO,
                                      LANCINTERMEDIARIA.NATUREZA, '', LANCINTERMEDIARIA.VALOR, LANCINTERMEDIARIA.CODHISTORICO,
                                      'LANÇAMENTOS REFERENTE A INTEGRAÇÃO DO DIA: ' || TO_CHAR(VD_DATALANCTO, 'DD/MM/YYYY'), LANCINTERMEDIARIA.CODREGRA,
                                      0,'N', LANCINTERMEDIARIA.CODGRUPOBEM,
                                      LANCINTERMEDIARIA.NUMTRANSLANCTO, LANCINTERMEDIARIA.CODFILIAL, LANCINTERMEDIARIA.NUMSEQ, LANCINTERMEDIARIA.CODCONTA_PC, VD_DATALANCTO_ORIG);

           VN_NUMSEQ := NVL(VN_NUMSEQ,0) + NVL(VN_NUMSEQOUT,0);

           ---------------------------------------------------------------------------------
           V_SQLERRO := 'VALIDA SE A PERNA DO LANÇAMENTO TEM CENTRO DE CUSTO';
           ---------------------------------------------------------------------------------
           --IF (LANCINTERMEDIARIA.NUMTRANSCENTROCUSTO IS NOT NULL) AND (VS_USACENTROCUSTO = 'S') THEN
           --   P_GRAVA_DADOS_CENTROCUSTO(LANCINTERMEDIARIA.NUMTRANSCENTROCUSTO, VN_NUMTRANSLANCTO, LANCINTERMEDIARIA.NATUREZA);
           --END IF;

        ELSE
          ---------------------------------------------------------------------------------
          V_SQLERRO := 'EXECUTANDO PROCEDURE P_ATUALIZA_VALOR_LANCTO()';
          ---------------------------------------------------------------------------------
          IF (VN_NUMLANCTOCONTABIL IS NULL) OR (VN_NUMLANCTOCONTABIL = 0) THEN
             VN_NUMLANCTOCONTABIL := F_TEM_LANC_DIARIO(VD_DATALANCTO, LANCINTERMEDIARIA.CODREGRA, VN_NUMSEQAUX);
             VN_NUMSEQ            := VN_NUMSEQAUX;
          END IF;

          P_ATUALIZA_VALOR_LANCTO(LANCINTERMEDIARIA.CODFILIAL, VN_VALORLANCTO + LANCINTERMEDIARIA.VALOR,
                                  VD_DATALANCTO, LANCINTERMEDIARIA.CODREDUZIDO_PC, LANCINTERMEDIARIA.CODREGRA,
                                  LANCINTERMEDIARIA.NATUREZA, LANCINTERMEDIARIA.CODGRUPOBEM,
                                  VN_NUMTRANSLANCTO, LANCINTERMEDIARIA.NUMTRANSLANCTO,LANCINTERMEDIARIA.CODFILIAL, LANCINTERMEDIARIA.NUMSEQ, VD_DATALANCTO_ORIG);
          
            P_INSERE_LANCAMENTO_FILA(LANCINTERMEDIARIA.CODFILIAL,
                                PCODPLANOCONTA,
                                EXTRACT(MONTH FROM VD_DATALANCTO),
                                EXTRACT(YEAR FROM VD_DATALANCTO),
                                LANCINTERMEDIARIA.CODREDUZIDO_PC,
                                LANCINTERMEDIARIA.CODCONTA_PC,
                                CASE WHEN LANCINTERMEDIARIA.NATUREZA = 'D' THEN LANCINTERMEDIARIA.VALOR ELSE 0 END,
                                CASE WHEN LANCINTERMEDIARIA.NATUREZA = 'C' THEN LANCINTERMEDIARIA.VALOR ELSE 0 END,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
                                LANCINTERMEDIARIA.TIPOPARCEIRO,
                                LANCINTERMEDIARIA.CODPARCEIRO);
          --IF (LANCINTERMEDIARIA.NUMTRANSCENTROCUSTO IS NOT NULL) AND (VS_USACENTROCUSTO = 'S') THEN
          --   P_ATUALIZA_VALOR_CENTROCUSTO(LANCINTERMEDIARIA.NUMTRANSCENTROCUSTO,
          --                                LANCINTERMEDIARIA.CODFILIAL,
          --                                VD_DATALANCTO,
          --                                LANCINTERMEDIARIA.CODREDUZIDO_PC,
          --                                LANCINTERMEDIARIA.CODREGRA);
          --END IF;
        END IF;

      ---------------------------------------------------------------------------------
      -- AGRUPAMENTO POR DATA: MENSAL OU DIÁRIO
      ---------------------------------------------------------------------------------
      ELSE
        ---------------------------------------------------------------------------------
        V_SQLERRO := 'EXECUTANDO FUNÇÃO F_VALOR_SE_TIVER_LANCTO()';
        ---------------------------------------------------------------------------------
        VN_VALORLANCTO := F_VALOR_SE_TIVER_LANCTO(LANCINTERMEDIARIA.CODFILIAL, VD_DATALANCTO,
                                                  LANCINTERMEDIARIA.CODREDUZIDO_PC, LANCINTERMEDIARIA.CODREGRA,
                                                  LANCINTERMEDIARIA.NATUREZA);

        IF (VN_VALORLANCTO = 0) THEN
           ---------------------------------------------------------------------------------
           V_SQLERRO := 'EXECUTANDO FUNÇÃO F_TEM_LANC_DIARIO()';
           ---------------------------------------------------------------------------------
           VN_NUMSEQAUX := 0;

           VN_NUMLANCTOAUX := F_TEM_LANC_DIARIO(VD_DATALANCTO, LANCINTERMEDIARIA.CODREGRA, VN_NUMSEQAUX);

           IF VN_NUMLANCTOAUX = 0 THEN
              ---------------------------------------------------------------------------------
              V_SQLERRO := 'GERANDO PRÓXIMO NUMLANCTOCONTABIL';
              ---------------------------------------------------------------------------------
              P_CTBSEQLANCAMENTO(LANCINTERMEDIARIA.CODFILIAL, PCODPLANOCONTA, VD_DATALANCTO, TRUE, VN_NUMLANCTOCONTABIL);
           ELSE
              VN_NUMLANCTOCONTABIL := VN_NUMLANCTOAUX;
              VN_NUMSEQ            := VN_NUMSEQAUX;
           END IF;

           VN_NUMSEQ := NVL(VN_NUMSEQ,0) + 1;

           SELECT SEQPCLANCAMENTO.NEXTVAL
           INTO VN_NUMTRANSLANCTO
           FROM DUAL;

           ---------------------------------------------------------------------------------
           V_SQLERRO := 'GRAVANDO DADOS CONTÁBEIS P_GRAVA_DADOS_PCLANCAMENTO()';
           ---------------------------------------------------------------------------------
           P_GRAVA_DADOS_PCLANCAMENTO(VN_NUMTRANSLANCTO, VN_NUMLANCTOCONTABIL, VN_NUMSEQ,
                                      EXTRACT(MONTH FROM VD_DATALANCTO), EXTRACT(YEAR FROM VD_DATALANCTO),
                                      LANCINTERMEDIARIA.CODFILIAL, PCODPLANOCONTA, LANCINTERMEDIARIA.CODREDUZIDO_PC, VD_DATALANCTO,
                                      LANCINTERMEDIARIA.NATUREZA, '', LANCINTERMEDIARIA.VALOR, LANCINTERMEDIARIA.CODHISTORICO,
                                      'LANÇAMENTOS REFERENTE A INTEGRAÇÃO DO DIA: ' || TO_CHAR(VD_DATALANCTO, 'DD/MM/YYYY'), LANCINTERMEDIARIA.CODREGRA,
                                      0,'N',NULL,LANCINTERMEDIARIA.NUMTRANSLANCTO, LANCINTERMEDIARIA.CODFILIAL, LANCINTERMEDIARIA.NUMSEQ, LANCINTERMEDIARIA.CODCONTA_PC, VD_DATALANCTO_ORIG);

           VN_NUMSEQ := NVL(VN_NUMSEQ,0) + NVL(VN_NUMSEQOUT,0);

           ---------------------------------------------------------------------------------
           V_SQLERRO := 'VALIDA SE A PERNA DO LANÇAMENTO TEM CENTRO DE CUSTO';
           ---------------------------------------------------------------------------------
           IF (LANCINTERMEDIARIA.NUMTRANSCENTROCUSTO IS NOT NULL) AND (VS_USACENTROCUSTO = 'S') THEN
              P_GRAVA_DADOS_CENTROCUSTO(LANCINTERMEDIARIA.NUMTRANSCENTROCUSTO, VN_NUMTRANSLANCTO, LANCINTERMEDIARIA.NATUREZA, LANCINTERMEDIARIA.HISTORICO_COMPL || LANCINTERMEDIARIA.CODREDUZIDO_PC || LANCINTERMEDIARIA.CODFILIAL);
           END IF;
           IF (VS_USACENTRORECEITA = 'S') THEN
              P_GRAVA_DADOS_CENTRORECEITA(LANCINTERMEDIARIA.NUMTRANSOPERACAO, LANCINTERMEDIARIA.VALOR, VN_NUMTRANSLANCTO, LANCINTERMEDIARIA.NATUREZA, LANCINTERMEDIARIA.CODREDUZIDO_PC, LANCINTERMEDIARIA.CODREGRA, VD_DATALANCTO);
           END IF;
        ELSE
          ---------------------------------------------------------------------------------
          V_SQLERRO := 'EXECUTANDO PROCEDURE P_ATUALIZA_VALOR_LANCTO()';
          ---------------------------------------------------------------------------------
          IF (VN_NUMLANCTOCONTABIL IS NULL) OR (VN_NUMLANCTOCONTABIL = 0) THEN
             VN_NUMLANCTOCONTABIL := F_TEM_LANC_DIARIO(VD_DATALANCTO, LANCINTERMEDIARIA.CODREGRA, VN_NUMSEQAUX);
             VN_NUMSEQ            := VN_NUMSEQAUX;
          END IF;

          P_ATUALIZA_VALOR_LANCTO(LANCINTERMEDIARIA.CODFILIAL, VN_VALORLANCTO + LANCINTERMEDIARIA.VALOR,
                                  VD_DATALANCTO, LANCINTERMEDIARIA.CODREDUZIDO_PC, LANCINTERMEDIARIA.CODREGRA,
                                  LANCINTERMEDIARIA.NATUREZA, NULL, VN_NUMTRANSLANCTO, LANCINTERMEDIARIA.NUMTRANSLANCTO,LANCINTERMEDIARIA.CODFILIAL, LANCINTERMEDIARIA.NUMSEQ, VD_DATALANCTO_ORIG);
          
           P_INSERE_LANCAMENTO_FILA(LANCINTERMEDIARIA.CODFILIAL,
                                PCODPLANOCONTA,
                                EXTRACT(MONTH FROM VD_DATALANCTO),
                                EXTRACT(YEAR FROM VD_DATALANCTO),
                                LANCINTERMEDIARIA.CODREDUZIDO_PC,
                                LANCINTERMEDIARIA.CODCONTA_PC,
                                CASE WHEN LANCINTERMEDIARIA.NATUREZA = 'D' THEN LANCINTERMEDIARIA.VALOR ELSE 0 END,
                                CASE WHEN LANCINTERMEDIARIA.NATUREZA = 'C' THEN LANCINTERMEDIARIA.VALOR ELSE 0 END,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
                                LANCINTERMEDIARIA.TIPOPARCEIRO,
                                LANCINTERMEDIARIA.CODPARCEIRO);
           
           IF (LANCINTERMEDIARIA.NUMTRANSCENTROCUSTO IS NOT NULL) AND (VS_USACENTROCUSTO = 'S') THEN
              P_ATUALIZA_VALOR_CENTROCUSTO(LANCINTERMEDIARIA.NUMTRANSCENTROCUSTO,
                                           LANCINTERMEDIARIA.CODFILIAL,
                                           VD_DATALANCTO,
                                           LANCINTERMEDIARIA.CODREDUZIDO_PC,
                                           LANCINTERMEDIARIA.CODREGRA);
           END IF;
        END IF;
      END IF;


      VN_ANOLANCTO_LINHAANT         := EXTRACT(YEAR FROM LANCINTERMEDIARIA.DATALANCTO);
      VN_MESLANCTO_LINHAANT         := EXTRACT(MONTH FROM LANCINTERMEDIARIA.DATALANCTO);
      VN_NUMLANCTOCONTABIL_LINHAANT := VN_NUMLANCTOCONTABIL;
      VN_NUMLANCTOLANCINTERMEDIARIA := LANCINTERMEDIARIA.NUMTRANSLANCTO;
      VS_CODCONTAREDUZIDO           := LANCINTERMEDIARIA.CODREDUZIDO_PC;
    ELSE
      IF VS_DATASITUACAOESPECIAL = 'S' THEN
        RESULTADO := 'Encontrado Lançamento(s) posterior(es) a data de situação especial, informada na rotina 2106. Operação não permitida!';
      ELSIF (VS_MESBLOQUEADO = 'X') OR (VS_DIABLOQUEADO = 'X') THEN 
         RESULTADO := 'Ocorreu um erro inesperado ao verificar se o período está bloqueado para integração, favor contactar o suporte da TOTVS.';
      ELSE
         RESULTADO := 'Encontrado lançamento(s) em mês fechado ou período não aberto, os mesmos não serão contabilizados até que o mês/período seja reaberto.';
      END IF;
    END IF;
    
    IF VN_CONTADOR_COMMIT >= 500 THEN
         VN_CONTADOR_COMMIT := 0;
         COMMIT;
    END IF;
    
  END LOOP;

  IF VN_ANOLANCTO_LINHAANT IS NOT NULL THEN
    ATUALIZA_CAMPO_MULTIFILIAL(VN_ANOLANCTO_LINHAANT,VN_MESLANCTO_LINHAANT,VN_NUMLANCTOCONTABIL_LINHAANT, LANCINTERMEDIARIA.DATALANCTO);
   COMMIT;
  END IF;

  IF (VN_NUMLANCTOLANCINTERMEDIARIA IS NOT NULL) THEN
     P_PASSA_STATUS_INTEGRADO(VN_NUMLANCTOLANCINTERMEDIARIA, VN_NUMLANCTOCONTABIL, VN_NUMTRANSLANCTO, LANCINTERMEDIARIA.CODFILIAL, PDTINICIO, PDTFINAL, LANCINTERMEDIARIA.DATALANCTO, LANCINTERMEDIARIA.AGRUPAMENTOREGRA, VS_CODCONTAREDUZIDO);
  END IF;

  IF RESULTADO IS NULL THEN
     RESULTADO := 'Ok';
  END IF;

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    BEGIN
      ROLLBACK;
      RESULTADO := 'Ocorreu um erro quando: ' || V_SQLERRO || CHR(13) ||
                   'Erro Original: ' || SQLERRM;
    END;
END P_CTBCONTABILIZALANCAMENTOS;