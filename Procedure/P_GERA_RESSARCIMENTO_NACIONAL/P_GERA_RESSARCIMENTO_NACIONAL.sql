gaucha
CREATE OR REPLACE PROCEDURE P_GERA_RESSARCIMENTO_NACIONAL(PCODFILIAL IN VARCHAR2,
                                                          PDTINICIAL IN DATE,
                                                          PDTFINAL IN DATE,
                                                          PRESTITUI_COMPL_INT_CONS_FINAL VARCHAR2,
                                                          PCODPRODUTO NUMBER,
                                                          MSG        OUT VARCHAR2) IS
  VDATAESTOQUEINICIO DATE;
  VCODIGOMOTIVO      VARCHAR2(10);
  VQTCONT_ACUMULADO  NUMBER;
  VCALCULOCAMPO15_17 NUMBER;

  V_VLMEDIABASEST PCHISTEST.VLMEDIABASEST%TYPE;
  V_VLMEDIAICMS   PCHISTEST.VLMEDIAICMS%TYPE;
  V_VLMEDIAST     PCHISTEST.VLMEDIAST%TYPE;
  V_VLMEDIAFCPST  PCHISTEST.VLMEDIAFCPST%TYPE;
    
  VC185_C10_VL_UNIT_ICMS          PCRESSARCIMENTONACIONAL.C185_C10_VL_UNIT_ICMS%TYPE;
  VC185_C12_VL_UNIT_ICMS_OP_EST   PCRESSARCIMENTONACIONAL.C185_C12_VL_UNIT_ICMS_OP_EST%TYPE;
  VC185_C13_VL_UNIT_ICMS_ST_EST   PCRESSARCIMENTONACIONAL.C185_C13_VL_UNIT_ICMS_ST_EST%TYPE;
  VC185_C14_VL_UNIT_FCP_ST_EST    PCRESSARCIMENTONACIONAL.C185_C14_VL_UNIT_FCP_ST_EST%TYPE;
  VC185_C15_VL_UNIT_ICMS_ST_REST  PCRESSARCIMENTONACIONAL.C185_C15_VL_UNIT_ICMS_ST_REST%TYPE;
  VC185_C16_VL_UNIT_FCP_ST_REST   PCRESSARCIMENTONACIONAL.C185_C16_VL_UNIT_FCP_ST_REST%TYPE;
  VC185_C17_VL_UNIT_ICMS_ST_COMP  PCRESSARCIMENTONACIONAL.C185_C17_VL_UNIT_ICMS_ST_COMPL%TYPE;
  VC185_C18_VL_UNIT_FCP_ST_COMPL  PCRESSARCIMENTONACIONAL.C185_C18_VL_UNIT_FCP_ST_COMPL%TYPE;

  VREG_1255_C03_CREDITO_ICMS_OP    PCRESSARCIMENTONACIONAL.REG_1255_C03_CREDITO_ICMS_OP%TYPE;
  VREG_1255_C04_ICMS_ST_REST       PCRESSARCIMENTONACIONAL.REG_1255_C04_ICMS_ST_REST%TYPE;
  VREG_1255_C05_FCP_ST_REST        PCRESSARCIMENTONACIONAL.REG_1255_C05_FCP_ST_REST%TYPE;
  VREG_1255_C06_ICMS_ST_COMPL      PCRESSARCIMENTONACIONAL.REG_1255_C06_ICMS_ST_COMPL%TYPE;
  VREG_1255_C07_FCP_ST_COMPL       PCRESSARCIMENTONACIONAL.REG_1255_C07_FCP_ST_COMPL%TYPE;



  CURSOR C_MOVIMENTACAO(PCOD_PRODUTO NUMBER) IS(
                         SELECT 'E' TIPO_OPERACAO,
                                M.CODOPER,
                                NVL(E.CODFILIALNF, E.CODFILIAL) CODFILIAL,
                                E.DTENT DATA_OPERACAO,
                                E.NUMNOTA,
                                E.NUMTRANSENT NUMTRANSACAO,
                                'N'  AS TIPO_CLIENTE,
                                M.CODPROD,
                                NVL(MC.NITEMXML, NVL(MC.NUMSEQENT, M.NUMSEQ)) NUMSEQ,
                                FISCAL.FORMATAR_CST_ICMS(M.SITTRIBUT, NVL(M.IMPORTADO, P.IMPORTADO),NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), E.DTENT) CST,
                                M.QTCONT,
                                M.PUNITCONT,
                                M.CODFISCAL,
                                NVL(Mc.DESCRICAONFE, M.DESCRICAO) DESCRICAO,
                                MC.CODCEST,
                                NVL(MC.UNIDADECOMERCIAL, M.UNIDADE) UNIDADE,
                                (((NVL(M.BASEICMS,0) + NVL(MC.VLBASEOUTROS,0) + NVL(MC.VLBASEFRETE,0)) * M.QTCONT) * (M.PERCICM /100)) VLICMS_ENTRADA,


                                (CASE WHEN ((NVL(M.BASEICST,0) + NVL(M.VLBASESTFORANF,0)) > 0) THEN
                                    NVL(M.BASEICST,0) +NVL(M.VLBASESTFORANF,0)
                                 WHEN (NVL(M.BASEBCR,0) > 0) THEN
                                    NVL(M.BASEBCR,0)
                                 END) VLBASEICMSST_ENTRADA,

                                (CASE WHEN ((NVL(M.BASEICST,0) + NVL(M.VLBASESTFORANF,0)) > 0) THEN
                                    NVL(M.ST,0) +NVL(M.VLDESPADICIONAL,0)
                                 WHEN (NVL(M.BASEBCR,0) > 0) THEN
                                    NVL(M.STBCR,0)
                                 END) VLICMSST_ENTRADA,

                                (CASE WHEN ((NVL(M.BASEICST,0) + NVL(M.VLBASESTFORANF,0)) > 0) THEN
                                    NVL(MC.VLFECP,0)
                                 WHEN (NVL(M.BASEBCR,0) > 0) THEN
                                    NVL(MC.VLFCPSTRET,0)
                                 END) VLFCPST_ENTRADA,
                                 PF.PERCALIQVIGINT
                           FROM PCNFENT E,
                                PCMOV M,
                                PCMOVCOMPLE MC,
                                PCPRODUT P,
                                PCPRODFILIAL PF
                         WHERE NVL(E.CODFILIALNF, E.CODFILIAL) = NVL(M.CODFILIALNF, M.CODFILIAL)
                           AND E.NUMTRANSENT = M.NUMTRANSENT
                           AND E.NUMNOTA     = M.NUMNOTA
                           AND E.CODFILIAL    = M.CODFILIAL                           
                           AND M.NUMTRANSITEM  = MC.NUMTRANSITEM
                           AND M.CODPROD     = P.CODPROD
                           AND M.CODPROD     = PF.CODPROD(+)
                           AND NVL(M.CODFILIALNF, M.CODFILIAL) = PF.CODFILIAL(+)
                           AND NVL(E.CODFILIALNF, E.CODFILIAL)   = PCODFILIAL
                           AND M.CODPROD     = PCOD_PRODUTO
                           AND E.DTENT BETWEEN PDTINICIAL AND PDTFINAL
                     UNION ALL
                         SELECT 'S' TIPO_OPERACAO,
                                M.CODOPER,
                                NVL(S.CODFILIALNF, S.CODFILIAL) CODFILIAL,
                                S.DTSAIDA DATA_OPERACAO,
                                S.NUMNOTA,
                                S.NUMTRANSVENDA NUMTRANSACAO,
                                CASE
                                  WHEN NVL(S.ORGAOPUBFEDERAL,'N') = 'S' THEN
                                    'F'
                                  WHEN NVL(S.ORGAOPUB,'N') = 'S' THEN
                                    'E'
                                  WHEN NVL(S.ORGAOPUBMUNICIPAL,'N') = 'S' THEN
                                    'D'
                                  WHEN NVL(S.CONSUMIDORFINAL,'N') = 'S' AND
                                       NVL(S.CONTRIBUINTE,'N')= 'N' THEN
                                    'C'
                                  WHEN NVL(S.CONSUMIDORFINAL,'N') = 'S' AND
                                       NVL(S.CONTRIBUINTE,'N') = 'S' THEN
                                    'B'
                                  WHEN NVL(S.CONTRIBUINTE,'N') = 'S'  THEN
                                    'A'
                                END AS TIPO_CLIENTE,
                                M.CODPROD,
                                NVL(MC.NITEMXML, M.NUMSEQ) NUMSEQ,
                                FISCAL.FORMATAR_CST_ICMS(M.SITTRIBUT, NVL(M.IMPORTADO, P.IMPORTADO),NVL(MC.ORIGMERCTRIB,PF.ORIGMERCTRIB), S.DTSAIDA) CST,
                                M.QTCONT,
                                M.PUNITCONT,
                                M.CODFISCAL,
                                NVL(MC.DESCRICAONFE, M.DESCRICAO) DESCRICAO,
                                MC.CODCEST,
                                NVL(MC.UNIDADECOMERCIAL, M.UNIDADE) UNIDADE,                                
                               0 VLICMS_ENTRADA,
                               0 VLBASEICMSST_ENTRADA,
                               0 VLICMSST_ENTRADA,
                               0 VLFCPST_ENTRADA,
                               PF.PERCALIQVIGINT
                           FROM PCNFSAID S,
                                PCMOV M,
                                PCMOVCOMPLE MC,
                                PCPRODUT P,
                                PCPRODFILIAL PF
                         WHERE NVL(S.CODFILIALNF, S.CODFILIAL) = NVL(M.CODFILIALNF, M.CODFILIAL)
                           AND S.NUMTRANSVENDA = M.NUMTRANSVENDA
                           AND S.NUMNOTA       = M.NUMNOTA
                           AND S.CODFILIAL     = M.CODFILIAL
                           AND M.DTMOV         = S.DTSAIDA                           
                           AND M.NUMTRANSITEM  = MC.NUMTRANSITEM
                           AND M.CODPROD       = P.CODPROD
                           AND M.CODPROD       = PF.CODPROD(+)
                           AND NVL(M.CODFILIALNF, M.CODFILIAL) = PF.CODFILIAL(+)
                           AND NVL(S.CODFILIALNF, S.CODFILIAL) = PCODFILIAL
                           AND S.DTSAIDA BETWEEN PDTINICIAL AND PDTFINAL
                           AND M.CODPROD       = PCOD_PRODUTO
                          ) ORDER BY DATA_OPERACAO, TIPO_OPERACAO, NUMNOTA;


  PROCEDURE LIMPARDADOS(PCODFILIAL     VARCHAR2,
                        PDATA_OPERACAO DATE,
                        PCODPROD       INTEGER,
                        PTIPO_OPERACAO VARCHAR2) IS
  BEGIN
    IF (PTIPO_OPERACAO = 'T') THEN
      DELETE PCRESSARCIMENTONACIONAL
       WHERE CODFILIAL     = PCODFILIAL
         AND DATA_OPERACAO BETWEEN PDATA_OPERACAO AND PDTFINAL
         AND DECODE(PCODPROD, 0, 0, CODPROD)  = DECODE(PCODPROD, 0, 0, PCODPROD);
    ELSE   
      DELETE PCRESSARCIMENTONACIONAL
       WHERE CODFILIAL     = PCODFILIAL
         AND DATA_OPERACAO = PDATA_OPERACAO
         AND DECODE(PCODPROD, 0, 0, CODPROD)  = DECODE(PCODPROD, 0, 0, PCODPROD)
         AND TIPO_OPERACAO = PTIPO_OPERACAO;       
    END IF;  
    COMMIT; 
  END;


  FUNCTION GET_CODIGOMOTIVO(PCODFISCAL NUMBER,
                            PTIPO_CLIENTE VARCHAR2) RETURN VARCHAR2 IS
  VCODIGO_MOTIVO VARCHAR2(10);
  BEGIN
    VCODIGO_MOTIVO := NULL;
    BEGIN
      SELECT CODMOTIVO
        INTO VCODIGO_MOTIVO
        FROM (SELECT DISTINCT
                      (SELECT VALOR_TEXTO CODMOTIVO
                         FROM PCDADOSGENERICOS G
                        WHERE G.DADOSID = PRINC.DADOSID
                          AND G.REGISTRO = PRINC.REGISTRO
                          AND G.CAMPO = 'CodMotivo'
                          AND G.CODREGISTRO = PRINC.CODREGISTRO) CODMOTIVO,
                      (SELECT VALOR_TEXTO CODMOTIVO
                         FROM PCDADOSGENERICOS G
                        WHERE G.DADOSID = PRINC.DADOSID
                          AND G.REGISTRO = PRINC.REGISTRO
                          AND G.CAMPO = 'CFOP'
                          AND G.CODREGISTRO = PRINC.CODREGISTRO) CFOP,
                (SELECT VALOR_TEXTO CODMOTIVO
                         FROM PCDADOSGENERICOS G
                        WHERE G.DADOSID = PRINC.DADOSID
                          AND G.REGISTRO = PRINC.REGISTRO
                          AND G.CAMPO = 'TipoCliente'
                          AND G.CODREGISTRO = PRINC.CODREGISTRO) TIPOCLIENTE
                  FROM PCDADOSGENERICOS PRINC
                 WHERE PRINC.DADOSID = 'RESSNAC'
                   AND PRINC.REGISTRO = 'NACMOTI'
                   AND PRINC.CODFILIAL = PCODFILIAL)
       WHERE CFOP        = PCODFISCAL
         AND TIPOCLIENTE = PTIPO_CLIENTE
         AND ROWNUM      = 1;
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
       BEGIN
                SELECT CODMOTIVO
                  INTO VCODIGO_MOTIVO
                  FROM (SELECT DISTINCT
                                (SELECT VALOR_TEXTO CODMOTIVO
                                   FROM PCDADOSGENERICOS G
                                  WHERE G.DADOSID = PRINC.DADOSID
                                    AND G.REGISTRO = PRINC.REGISTRO
                                    AND G.CAMPO = 'CodMotivo'
                                    AND G.CODREGISTRO = PRINC.CODREGISTRO) CODMOTIVO,
                                (SELECT VALOR_TEXTO CODMOTIVO
                                   FROM PCDADOSGENERICOS G
                                  WHERE G.DADOSID = PRINC.DADOSID
                                    AND G.REGISTRO = PRINC.REGISTRO
                                    AND G.CAMPO = 'CFOP'
                                    AND G.CODREGISTRO = PRINC.CODREGISTRO) CFOP,
                          (SELECT VALOR_TEXTO CODMOTIVO
                                   FROM PCDADOSGENERICOS G
                                  WHERE G.DADOSID = PRINC.DADOSID
                                    AND G.REGISTRO = PRINC.REGISTRO
                                    AND G.CAMPO = 'TipoCliente'
                                    AND G.CODREGISTRO = PRINC.CODREGISTRO) TIPOCLIENTE
                            FROM PCDADOSGENERICOS PRINC
                           WHERE PRINC.DADOSID = 'RESSNAC'
                             AND PRINC.REGISTRO = 'NACMOTI'
                             AND PRINC.CODFILIAL = PCODFILIAL)
                 WHERE CFOP = PCODFISCAL
                   AND TIPOCLIENTE IS NULL
                   AND ROWNUM = 1;
           EXCEPTION
           WHEN NO_DATA_FOUND THEN
              MSG := 'Nenhum código de motivo foi localizado';

       END;
    END;
    RETURN VCODIGO_MOTIVO;
  END;


BEGIN
  -- PKG_DEBUGGING_FWPC.ATIVARDEBUG('P_GERA_RESSARCIMENTO_NACIONAL', '1.0');
   
   ------------- Inicio ----------------
   VDATAESTOQUEINICIO := PDTINICIAL-1;
 
 
   ----------- limpa os registros da PCRESSARCIMENTONACIONAL que são do tipo SI(Saldo Inicial) -------------------
   PKG_DEBUGGING_FWPC.LOG_MSG('1 - Limpando os dados produto: ');
     
   LIMPARDADOS(PCODFILIAL,
               VDATAESTOQUEINICIO,
               NVL(PCODPRODUTO,0),
               'T');

   FOR PRODUTO_ESTOQUE IN (SELECT H.CODFILIAL,
                                  H.DATA DATA_OPERACAO,
                                  H.CODPROD,
                                  'SI' TIPO_OPERACAO,
                                  H.QTEST,
                                  H.VLMEDIABASEST,
                                  H.VLMEDIAST,
                                  H.VLMEDIAICMS,
                                  H.VLMEDIAFCPST
                             FROM PCHISTEST H
                            WHERE H.CODFILIAL = PCODFILIAL
                              AND H.CODPROD NOT IN (SELECT CODPROD FROM PCLISTAPROD_TMP)
                              AND H.DATA = VDATAESTOQUEINICIO
                              AND DECODE(NVL(PCODPRODUTO,0), 0, 0, H.CODPROD)  = DECODE(NVL(PCODPRODUTO,0), 0, 0, NVL(PCODPRODUTO,0))
                              )
   LOOP
     ---------------------------------------------------------------------------------------------------------------
     ----------------------------------- Inserir os registros de Saldo inicial -------------------------------------
     ---------------------------------------------------------------------------------------------------------------
     PKG_DEBUGGING_FWPC.LOG_MSG('2 - Inserindo os dados produto: '||PRODUTO_ESTOQUE.CODPROD);
     
     INSERT INTO PCRESSARCIMENTONACIONAL(CODFILIAL,
                                         DATA_OPERACAO,
                                         CODPROD,
                                         TIPO_OPERACAO,
                                         QTEST,
                                         VLMEDIABASEST_UNIT,
                                         VLMEDIAICMS_UNIT,
                                         VLMEDIAST_UNIT,
                                         VLMEDIAFCPST_UNIT,
                                         VLMEDIABASEST_SALDO,
                                         VLMEDIAICMS_SALDO,
                                         VLMEDIAST_SALDO,
                                         VLMEDIAFCPST_SALDO)
                                         VALUES
                                        (PRODUTO_ESTOQUE.CODFILIAL,
                                         PRODUTO_ESTOQUE.DATA_OPERACAO,
                                         PRODUTO_ESTOQUE.CODPROD,
                                         PRODUTO_ESTOQUE.TIPO_OPERACAO,
                                         PRODUTO_ESTOQUE.QTEST,
                                         PRODUTO_ESTOQUE.VLMEDIABASEST,
                                         PRODUTO_ESTOQUE.VLMEDIAICMS,
                                         PRODUTO_ESTOQUE.VLMEDIAST,
                                         PRODUTO_ESTOQUE.VLMEDIAFCPST,
                                         PRODUTO_ESTOQUE.VLMEDIABASEST * PRODUTO_ESTOQUE.QTEST,
                                         PRODUTO_ESTOQUE.VLMEDIAICMS * PRODUTO_ESTOQUE.QTEST,
                                         PRODUTO_ESTOQUE.VLMEDIAST * PRODUTO_ESTOQUE.QTEST,
                                         PRODUTO_ESTOQUE.VLMEDIAFCPST * PRODUTO_ESTOQUE.QTEST
                                         );

     ---------------------------------------------------------------------------------------------------------------
     ------------------------------- Inserir os dados da movimentação Entrada / saída ------------------------------
     ---------------------------------------------------------------------------------------------------------------
     VQTCONT_ACUMULADO := PRODUTO_ESTOQUE.QTEST;
     
     V_VLMEDIABASEST := PRODUTO_ESTOQUE.VLMEDIABASEST;
     V_VLMEDIAICMS   := PRODUTO_ESTOQUE.VLMEDIAICMS;
     V_VLMEDIAST     := PRODUTO_ESTOQUE.VLMEDIAST;
     V_VLMEDIAFCPST  := PRODUTO_ESTOQUE.VLMEDIAFCPST;        

     PKG_DEBUGGING_FWPC.LOG_MSG('3 - Inicio consulta movimentação produto: '||PRODUTO_ESTOQUE.CODPROD);
     
     FOR DADOS_MOVIMENTACAO IN C_MOVIMENTACAO(PRODUTO_ESTOQUE.CODPROD)
     LOOP
       PKG_DEBUGGING_FWPC.LOG_MSG('4 - Movimentação produto: '||DADOS_MOVIMENTACAO.CODPROD);

       VC185_C10_VL_UNIT_ICMS          := NULL;
       VC185_C12_VL_UNIT_ICMS_OP_EST   := NULL;
       VC185_C13_VL_UNIT_ICMS_ST_EST   := NULL;
       VC185_C14_VL_UNIT_FCP_ST_EST    := NULL;
       VC185_C15_VL_UNIT_ICMS_ST_REST  := NULL;
       VC185_C16_VL_UNIT_FCP_ST_REST   := NULL;
       VC185_C17_VL_UNIT_ICMS_ST_COMP  := NULL;
       VC185_C18_VL_UNIT_FCP_ST_COMPL  := NULL;

       VREG_1255_C03_CREDITO_ICMS_OP   := NULL;
       VREG_1255_C04_ICMS_ST_REST      := NULL;
       VREG_1255_C05_FCP_ST_REST       := NULL;
       VREG_1255_C06_ICMS_ST_COMPL     := NULL;
       VREG_1255_C07_FCP_ST_COMPL      := NULL;
                     
       -------- BUSCANDO A MÉDIA DOS IMPOSTOS --------------       
       IF DADOS_MOVIMENTACAO.TIPO_OPERACAO = 'E' THEN
         BEGIN
           SELECT VLMEDIABASEST,
                  VLMEDIAICMS,
                  VLMEDIAST,
                  VLMEDIAFCPST
             INTO V_VLMEDIABASEST,
                  V_VLMEDIAICMS,
                  V_VLMEDIAST,
                  V_VLMEDIAFCPST             
             FROM PCHISTEST 
            WHERE DATA      = DADOS_MOVIMENTACAO.DATA_OPERACAO
              AND CODPROD   = DADOS_MOVIMENTACAO.CODPROD
              AND CODFILIAL = DADOS_MOVIMENTACAO.CODFILIAL
              AND ROWNUM    = 1;
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
             BEGIN
               V_VLMEDIABASEST := PRODUTO_ESTOQUE.VLMEDIABASEST;
               V_VLMEDIAICMS   := PRODUTO_ESTOQUE.VLMEDIAICMS;
               V_VLMEDIAST     := PRODUTO_ESTOQUE.VLMEDIAST;
               V_VLMEDIAFCPST  := PRODUTO_ESTOQUE.VLMEDIAFCPST;
             END;              
         END;
       END IF;
       
       PKG_DEBUGGING_FWPC.LOG_MSG('5 - Buscando código do motivo produto: '||DADOS_MOVIMENTACAO.CODPROD);
       VCODIGOMOTIVO := GET_CODIGOMOTIVO(DADOS_MOVIMENTACAO.CODFISCAL,
                                         DADOS_MOVIMENTACAO.TIPO_CLIENTE);

       IF (DADOS_MOVIMENTACAO.TIPO_OPERACAO = 'S') THEN
         VQTCONT_ACUMULADO := VQTCONT_ACUMULADO - DADOS_MOVIMENTACAO.QTCONT;
       ELSE
         VQTCONT_ACUMULADO := VQTCONT_ACUMULADO + DADOS_MOVIMENTACAO.QTCONT;
       END IF;


       IF SUBSTR(VCODIGOMOTIVO,3,1) BETWEEN 0 AND 4 THEN
         VC185_C12_VL_UNIT_ICMS_OP_EST := V_VLMEDIAICMS;
         VC185_C13_VL_UNIT_ICMS_ST_EST := V_VLMEDIAST;
         VC185_C14_VL_UNIT_FCP_ST_EST  := V_VLMEDIAFCPST;
       END IF;


       IF (PRESTITUI_COMPL_INT_CONS_FINAL = 'S') AND
          (DADOS_MOVIMENTACAO.TIPO_CLIENTE = 'C') AND
          ((DADOS_MOVIMENTACAO.CODFISCAL > 5000) AND
           (DADOS_MOVIMENTACAO.CODFISCAL < 5999))   THEN

         VC185_C10_VL_UNIT_ICMS := (DADOS_MOVIMENTACAO.PUNITCONT * (DADOS_MOVIMENTACAO.PERCALIQVIGINT /100));

         VCALCULOCAMPO15_17 := (VC185_C12_VL_UNIT_ICMS_OP_EST + VC185_C13_VL_UNIT_ICMS_ST_EST - NVL(VC185_C10_VL_UNIT_ICMS,0));

         IF VCALCULOCAMPO15_17 > 0 THEN
           VC185_C15_VL_UNIT_ICMS_ST_REST   := VCALCULOCAMPO15_17;

           VREG_1255_C04_ICMS_ST_REST       := (VC185_C15_VL_UNIT_ICMS_ST_REST *DADOS_MOVIMENTACAO.QTCONT);
         ELSE
           VC185_C17_VL_UNIT_ICMS_ST_COMP := ABS(VCALCULOCAMPO15_17);
           VREG_1255_C06_ICMS_ST_COMPL    := (VC185_C17_VL_UNIT_ICMS_ST_COMP *DADOS_MOVIMENTACAO.QTCONT);
         END IF;
       ELSE
         IF ((DADOS_MOVIMENTACAO.CODFISCAL > 6000) AND
             (DADOS_MOVIMENTACAO.CODFISCAL < 6999)) THEN
           VC185_C15_VL_UNIT_ICMS_ST_REST := V_VLMEDIAST;
           
           VREG_1255_C04_ICMS_ST_REST := (VC185_C15_VL_UNIT_ICMS_ST_REST *DADOS_MOVIMENTACAO.QTCONT);
         END IF  ;
       END IF;

       PKG_DEBUGGING_FWPC.LOG_MSG('6 - Inserindo dados movimentacao produto: '||DADOS_MOVIMENTACAO.CODPROD);
       INSERT INTO PCRESSARCIMENTONACIONAL(CODFILIAL,
                                           DATA_OPERACAO,
                                           TIPO_OPERACAO,
                                           CODOPER,
                                           TIPO_CLIENTE,
                                           CODIGO_MOTIVO,
                                           NUMTRANSACAO,
                                           NUMNOTA,
                                           CODPROD,
                                           NUMSEQ,
                                           CST,
                                           CODFISCAL,
                                           DESCRICAO,
                                           CODCEST,
                                           UNIDADE,
                                           QTCONT,
                                           PUNITCONT,
                                           QTEST,
                                           ------- MÉDIA UNITARIA IGUAL DA PCHISTEST -----
                                           VLMEDIABASEST_UNIT,
                                           VLMEDIAICMS_UNIT,
                                           VLMEDIAST_UNIT,
                                           VLMEDIAFCPST_UNIT,
                                           ------- MÉDIA MULTIPLICADO PELA QUANTIDADE ATUALIZADA DO ESTOQUE -----
                                           VLMEDIABASEST_SALDO,
                                           VLMEDIAICMS_SALDO,
                                           VLMEDIAST_SALDO,
                                           VLMEDIAFCPST_SALDO,
                                           ------- MÉDIA MULTIPLICADO PELA QUANTIDADE QUE SAIU -----
                                           VLMEDIABASEST_DIARIA,
                                           VLMEDIAICMS_DIARIA,
                                           VLMEDIAST_DIARIA,
                                           VLMEDIAFCPST_DIARIA,
                                           ------- VALOR DOS IMPOSTOS DE ENTRADA -----
                                           VLBASEICMSST_ENTRADA,
                                           VLICMS_ENTRADA,
                                           VLICMSST_ENTRADA,
                                           VLFCPST_ENTRADA,
                                           ------- Dados do registro C185 -----
                                           C185_C10_VL_UNIT_ICMS,
                                           C185_C12_VL_UNIT_ICMS_OP_EST,
                                           C185_C13_VL_UNIT_ICMS_ST_EST,
                                           C185_C14_VL_UNIT_FCP_ST_EST,
                                           C185_C15_VL_UNIT_ICMS_ST_REST,
                                           C185_C16_VL_UNIT_FCP_ST_REST,
                                           C185_C17_VL_UNIT_ICMS_ST_COMPL,
                                           C185_C18_VL_UNIT_FCP_ST_COMPL,
                                           ------- Dados do registro 1255 -----
                                           REG_1255_C03_CREDITO_ICMS_OP,
                                           REG_1255_C04_ICMS_ST_REST,
                                           REG_1255_C05_FCP_ST_REST,
                                           REG_1255_C06_ICMS_ST_COMPL,
                                           REG_1255_C07_FCP_ST_COMPL
                                           )
                                           VALUES
                                          (DADOS_MOVIMENTACAO.CODFILIAL,
                                           DADOS_MOVIMENTACAO.DATA_OPERACAO,
                                           DADOS_MOVIMENTACAO.TIPO_OPERACAO,
                                           DADOS_MOVIMENTACAO.CODOPER,                                           
                                           DADOS_MOVIMENTACAO.TIPO_CLIENTE,
                                           VCODIGOMOTIVO,
                                           DADOS_MOVIMENTACAO.NUMTRANSACAO,
                                           DADOS_MOVIMENTACAO.NUMNOTA,
                                           DADOS_MOVIMENTACAO.CODPROD,
                                           DADOS_MOVIMENTACAO.NUMSEQ,
                                           DADOS_MOVIMENTACAO.CST,
                                           DADOS_MOVIMENTACAO.CODFISCAL,
                                           DADOS_MOVIMENTACAO.DESCRICAO,
                                           DADOS_MOVIMENTACAO.CODCEST,
                                           DADOS_MOVIMENTACAO.UNIDADE,
                                           DADOS_MOVIMENTACAO.QTCONT,
                                           DADOS_MOVIMENTACAO.PUNITCONT,
                                           VQTCONT_ACUMULADO,
                                           ------- MÉDIA UNITARIA IGUAL DA PCHISTEST -----
                                           V_VLMEDIABASEST,
                                           V_VLMEDIAICMS,
                                           V_VLMEDIAST,
                                           V_VLMEDIAFCPST,
                                           ------- MÉDIA MULTIPLICADO PELA QUANTIDADE ATUALIZADA DO ESTOQUE -----
                                           V_VLMEDIABASEST * VQTCONT_ACUMULADO,
                                           V_VLMEDIAICMS   * VQTCONT_ACUMULADO,
                                           V_VLMEDIAST     * VQTCONT_ACUMULADO,
                                           V_VLMEDIAFCPST  * VQTCONT_ACUMULADO,
                                           ------- MÉDIA MULTIPLICADO PELA QUANTIDADE QUE SAIU -----
                                           V_VLMEDIABASEST * DADOS_MOVIMENTACAO.QTCONT,
                                           V_VLMEDIAICMS   * DADOS_MOVIMENTACAO.QTCONT,
                                           V_VLMEDIAST     * DADOS_MOVIMENTACAO.QTCONT,
                                           V_VLMEDIAFCPST  * DADOS_MOVIMENTACAO.QTCONT,
                                           ------- VALOR DOS IMPOSTOS DE ENTRADA -----
                                           DADOS_MOVIMENTACAO.VLBASEICMSST_ENTRADA,
                                           DADOS_MOVIMENTACAO.VLICMS_ENTRADA,
                                           DADOS_MOVIMENTACAO.VLICMSST_ENTRADA,
                                           DADOS_MOVIMENTACAO.VLFCPST_ENTRADA,
                                           ------- Dados do registro C185 -----
                                           VC185_C10_VL_UNIT_ICMS,
                                           VC185_C12_VL_UNIT_ICMS_OP_EST,
                                           VC185_C13_VL_UNIT_ICMS_ST_EST,
                                           VC185_C14_VL_UNIT_FCP_ST_EST,
                                           VC185_C15_VL_UNIT_ICMS_ST_REST,
                                           VC185_C16_VL_UNIT_FCP_ST_REST,
                                           VC185_C17_VL_UNIT_ICMS_ST_COMP,
                                           VC185_C18_VL_UNIT_FCP_ST_COMPL,
                                           ------- Dados do registro 1255 -----
                                           VREG_1255_C03_CREDITO_ICMS_OP,
                                           VREG_1255_C04_ICMS_ST_REST,
                                           VREG_1255_C05_FCP_ST_REST,
                                           VREG_1255_C06_ICMS_ST_COMPL,
                                           VREG_1255_C07_FCP_ST_COMPL
                                           );
     COMMIT;
     END LOOP; --End Loop movimentação (Entrada/saída)
   END LOOP; -- End Loop Saldo Inicial PCHISTEST.
END;
