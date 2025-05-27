CREATE OR REPLACE PROCEDURE P_GERA_RESSARCIMENTO_NACIONAL(PCODFILIAL IN VARCHAR2,
                                                          PDTINICIAL IN DATE,
                                                          PDTFINAL IN DATE,
                                                          PRESTITUI_COMPL_INT_CONS_FINAL VARCHAR2,
                                                          PCODPRODUTO NUMBER,
                                                          PATUALIZAMEDIADIASEGUINTEENT IN VARCHAR2,
                                                          MSG OUT VARCHAR2) IS
  VDATAESTOQUEINICIO DATE;
  VCODIGOMOTIVO      VARCHAR2(10);
  VQTCONT_ACUMULADO  NUMBER;
  VCALCULOCAMPO15_17 NUMBER;
  vnVLSOMAC12C13 NUMBER;
  VRESSARCICOMEMENTA      VARCHAR2(1);
  VGERACAMPO11C185ZERADO  VARCHAR2(1);

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
                                CASE WHEN X.VUNTRIB IS NOT NULL THEN
                                   X.VUNTRIB 
                                ELSE M.PUNITCONT
                                END PUNITCONT,
                                M.QTUNITCX,
                                M.CODFISCAL,
                                NVL(Mc.DESCRICAONFE, M.DESCRICAO) DESCRICAO,
                                MC.CODCEST,
                                NVL(M.UNIDADE, P.UNIDADE) UNIDADE,
                                NVL(MC.UNIDADECOMERCIAL, M.UNIDADE) UNIDADECOMERCIAL,
                                (((NVL(M.BASEICMS,0) + NVL(MC.VLBASEOUTROS,0) + NVL(MC.VLBASEFRETE,0))) * (M.PERCICM /100)) VLICMS_ENTRADA,


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
                                 0 VLBASEICMSST_SAIDA,
                                 0 VLICMSST_SAIDA,
                                 0 VLFCPST_SAIDA,
                                 PF.PERCALIQVIGINT
                           FROM PCNFENT E,
                                PCMOV M,
                                PCMOVCOMPLE MC,
                                PCPRODUT P,
                                PCPRODFILIAL PF,
                                PCDADOSXML X
                          WHERE NVL(E.CODFILIALNF, E.CODFILIAL) = NVL(M.CODFILIALNF, M.CODFILIAL)
                            AND E.NUMTRANSENT = M.NUMTRANSENT
                            AND E.NUMNOTA     = M.NUMNOTA
                            AND E.CODFILIAL    = M.CODFILIAL
                            AND M.NUMTRANSITEM  = MC.NUMTRANSITEM
                            AND M.CODPROD     = P.CODPROD
                            AND M.CODPROD     = PF.CODPROD(+)
                            AND M.NUMTRANSITEM = X.NUMTRANSITEM(+)
                            AND M.DTCANCEL IS NULL
                            AND M.QTCONT  > 0
                            AND NVL(M.CODFILIALNF, M.CODFILIAL) = PF.CODFILIAL(+)
                            AND NVL(E.CODFILIALNF, E.CODFILIAL)   = PCODFILIAL
                            AND M.CODPROD     = PCOD_PRODUTO
                            AND E.DTENT BETWEEN PDTINICIAL AND PDTFINAL
                            AND M.DTMOV BETWEEN PDTINICIAL AND PDTFINAL
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
                                CASE WHEN X.VUNTRIB IS NOT NULL THEN
                                   X.VUNTRIB 
                                ELSE M.PUNITCONT
                                END PUNITCONT,
                                M.QTUNITCX,
                                M.CODFISCAL,
                                NVL(MC.DESCRICAONFE, M.DESCRICAO) DESCRICAO,
                                MC.CODCEST,
                                NVL(P.UNIDADE, M.UNIDADE) UNIDADE,
                                NVL(MC.UNIDADECOMERCIAL, M.UNIDADE) UNIDADECOMERCIAL,
                                0 VLICMS_ENTRADA,
                                0 VLBASEICMSST_ENTRADA,
                                0 VLICMSST_ENTRADA,
                                0 VLFCPST_ENTRADA,
                                NVL(M.BASEICST,0)  VLBASEICMSST_SAIDA,
                                NVL(M.ST,0) VLICMSST_SAIDA,
                                NVL(MC.VLFECP,0) VLFCPST_SAIDA,
                                PF.PERCALIQVIGINT
                           FROM PCNFSAID S,
                                PCMOV M,
                                PCMOVCOMPLE MC,
                                PCPRODUT P,
                                PCPRODFILIAL PF,
                                PCDADOSXML X
                         WHERE NVL(S.CODFILIALNF, S.CODFILIAL) = NVL(M.CODFILIALNF, M.CODFILIAL)
                           AND S.NUMTRANSVENDA = M.NUMTRANSVENDA
                           AND S.NUMNOTA       = M.NUMNOTA
                           AND S.CODFILIAL     = M.CODFILIAL
                           AND M.DTMOV         = S.DTSAIDA
                           AND M.NUMTRANSITEM  = MC.NUMTRANSITEM
                           AND M.CODPROD       = P.CODPROD
                           AND M.CODPROD       = PF.CODPROD(+)
                           AND M.NUMTRANSITEM  = X.NUMTRANSITEM(+)
                           AND M.DTCANCEL IS NULL
                           AND M.QTCONT  > 0
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


  FUNCTION GET_CODIGOMOTIVO(PCODFISCAL            NUMBER,
                            PTIPO_CLIENTE         VARCHAR2,
                            PRESTITUI_COMPLEMENTO VARCHAR2) RETURN VARCHAR2 IS
    VCODIGO_MOTIVO VARCHAR2(10);
  BEGIN
    VCODIGO_MOTIVO := NULL;
    BEGIN
      SELECT CODMOTIVO
        INTO VCODIGO_MOTIVO
        FROM (SELECT DISTINCT (SELECT VALOR_TEXTO CODMOTIVO
                                 FROM PCDADOSGENERICOS G
                                WHERE G.DADOSID = PRINC.DADOSID
                                  AND G.REGISTRO = PRINC.REGISTRO
                                  AND G.CAMPO = 'CodMotivo'
                                  AND G.CODREGISTRO = PRINC.CODREGISTRO) CODMOTIVO,
                              (SELECT VALOR_TEXTO CODMOTIVO
                                 FROM PCDADOSGENERICOS G
                                WHERE G.DADOSID = PRINC.DADOSID
                                  AND G.REGISTRO = PRINC.REGISTRO
                                  AND G.CAMPO = 'TipoCodigoMotivo'
                                  AND G.CODREGISTRO = PRINC.CODREGISTRO) TIPOCODMOTIVO,
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
         AND TIPOCLIENTE = PTIPO_CLIENTE
         AND TIPOCODMOTIVO = PRESTITUI_COMPLEMENTO
         AND ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        BEGIN
          SELECT CODMOTIVO
            INTO VCODIGO_MOTIVO
            FROM (SELECT DISTINCT (SELECT VALOR_TEXTO CODMOTIVO
                                     FROM PCDADOSGENERICOS G
                                    WHERE G.DADOSID = PRINC.DADOSID
                                      AND G.REGISTRO = PRINC.REGISTRO
                                      AND G.CAMPO = 'CodMotivo'
                                      AND G.CODREGISTRO = PRINC.CODREGISTRO) CODMOTIVO,
                                  (SELECT VALOR_TEXTO CODMOTIVO
                                     FROM PCDADOSGENERICOS G
                                    WHERE G.DADOSID = PRINC.DADOSID
                                      AND G.REGISTRO = PRINC.REGISTRO
                                      AND G.CAMPO = 'TipoCodigoMotivo'
                                      AND G.CODREGISTRO = PRINC.CODREGISTRO) TIPOCODMOTIVO,
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
             AND TIPOCODMOTIVO = PRESTITUI_COMPLEMENTO
             AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            BEGIN
              SELECT CODMOTIVO
                INTO VCODIGO_MOTIVO
                FROM (SELECT DISTINCT (SELECT VALOR_TEXTO CODMOTIVO
                                         FROM PCDADOSGENERICOS G
                                        WHERE G.DADOSID = PRINC.DADOSID
                                          AND G.REGISTRO = PRINC.REGISTRO
                                          AND G.CAMPO = 'CodMotivo'
                                          AND G.CODREGISTRO = PRINC.CODREGISTRO) CODMOTIVO,
                                      (SELECT VALOR_TEXTO CODMOTIVO
                                         FROM PCDADOSGENERICOS G
                                        WHERE G.DADOSID = PRINC.DADOSID
                                          AND G.REGISTRO = PRINC.REGISTRO
                                          AND G.CAMPO = 'TipoCodigoMotivo'
                                          AND G.CODREGISTRO = PRINC.CODREGISTRO) TIPOCODMOTIVO,
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
                 AND TIPOCLIENTE = PTIPO_CLIENTE
                 AND TIPOCODMOTIVO IS NULL
                 AND ROWNUM = 1;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                BEGIN
                  SELECT CODMOTIVO
                    INTO VCODIGO_MOTIVO
                    FROM (SELECT DISTINCT (SELECT VALOR_TEXTO CODMOTIVO
                                             FROM PCDADOSGENERICOS G
                                            WHERE G.DADOSID = PRINC.DADOSID
                                              AND G.REGISTRO = PRINC.REGISTRO
                                              AND G.CAMPO = 'CodMotivo'
                                              AND G.CODREGISTRO =
                                                  PRINC.CODREGISTRO) CODMOTIVO,
                                          (SELECT VALOR_TEXTO CODMOTIVO
                                             FROM PCDADOSGENERICOS G
                                            WHERE G.DADOSID = PRINC.DADOSID
                                              AND G.REGISTRO = PRINC.REGISTRO
                                              AND G.CAMPO = 'TipoCodigoMotivo'
                                              AND G.CODREGISTRO =
                                                  PRINC.CODREGISTRO) TIPOCODMOTIVO,
                                          (SELECT VALOR_TEXTO CODMOTIVO
                                             FROM PCDADOSGENERICOS G
                                            WHERE G.DADOSID = PRINC.DADOSID
                                              AND G.REGISTRO = PRINC.REGISTRO
                                              AND G.CAMPO = 'CFOP'
                                              AND G.CODREGISTRO =
                                                  PRINC.CODREGISTRO) CFOP,
                                          (SELECT VALOR_TEXTO CODMOTIVO
                                             FROM PCDADOSGENERICOS G
                                            WHERE G.DADOSID = PRINC.DADOSID
                                              AND G.REGISTRO = PRINC.REGISTRO
                                              AND G.CAMPO = 'TipoCliente'
                                              AND G.CODREGISTRO =
                                                  PRINC.CODREGISTRO) TIPOCLIENTE
                            FROM PCDADOSGENERICOS PRINC
                           WHERE PRINC.DADOSID = 'RESSNAC'
                             AND PRINC.REGISTRO = 'NACMOTI'
                             AND PRINC.CODFILIAL = PCODFILIAL)
                   WHERE CFOP = PCODFISCAL
                     AND TIPOCLIENTE IS NULL
                     AND TIPOCODMOTIVO IS NULL
                     AND ROWNUM = 1;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    MSG := 'Nenhum código de motivo foi localizado';

                END;
            END;
        END;
    END;
    RETURN VCODIGO_MOTIVO;
  END;




BEGIN
  -- PKG_DEBUGGING_FWPC.ATIVARDEBUG('P_GERA_RESSARCIMENTO_NACIONAL', '1.0');

  ------------- Inicio ----------------
  VDATAESTOQUEINICIO := PDTINICIAL-1;

  -- Buscar parametros da 4011
  begin
    select G.VALOR_TEXTO
      into VGERACAMPO11C185ZERADO
      from PCDADOSGENERICOS G
     where G.REGISTRO = 'RESSNAC'
       and G.CAMPO IN ('GeraCampo11C185Zerado');
  exception
   when others then
     VGERACAMPO11C185ZERADO := 'N';
  end;

   ----------- limpa os registros da PCRESSARCIMENTONACIONAL que são do tipo SI(Saldo Inicial) -------------------
   PKG_DEBUGGING_FWPC.LOG_MSG('1 - Limpando os dados produto: ');

   LIMPARDADOS(PCODFILIAL,
               VDATAESTOQUEINICIO,
               NVL(PCODPRODUTO,0),
               'T');
               
   -- 001 - INSERIR PRODUTO QUE TEM ENTRADA NO PERIODO E NÃO TEM ESTOQUE INICIAL. ITEM QUE ENTROU A PRIMEIRA VEZ
   -- 001.1 - LIMPAR TABELA TEMPORARIA 
   DELETE FROM PCMOVTEMP;
   -- 001.2 - INSERINDO ITEM NA PCMOVTEMP
   FOR DADOS IN (SELECT DISTINCT M.CODPROD    
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
                            AND M.DTCANCEL IS NULL
                            AND M.QTCONT  > 0
                            AND NVL(M.CODFILIALNF, M.CODFILIAL) = PF.CODFILIAL(+)
                            AND NVL(E.CODFILIALNF, E.CODFILIAL)   = PCODFILIAL
                            AND E.DTENT BETWEEN PDTINICIAL AND PDTFINAL
                            AND M.DTMOV BETWEEN PDTINICIAL AND PDTFINAL
                            AND M.CODPROD NOT IN (SELECT CODPROD FROM PCLISTAPROD_TMP)
                            AND DECODE(NVL(PCODPRODUTO,0), 0, 0, M.CODPROD)  = 
                                  DECODE(NVL(PCODPRODUTO,0), 0, 0, NVL(PCODPRODUTO,0))
                            AND M.CODPROD NOT IN (SELECT DISTINCT H.CODPROD 
                                                    FROM PCHISTEST H
                                                   WHERE H.CODFILIAL = PCODFILIAL
                                                     AND H.CODPROD NOT IN (SELECT CODPROD FROM PCLISTAPROD_TMP)
                                                     AND H.DATA = VDATAESTOQUEINICIO
                                                     AND DECODE(NVL(PCODPRODUTO,0), 0, 0, H.CODPROD)  = 
                                                           DECODE(NVL(PCODPRODUTO,0), 0, 0, NVL(PCODPRODUTO,0))))
   LOOP 
      INSERT INTO PCMOVTEMP (CODPROD) VALUES (DADOS.CODPROD);
   END LOOP; 

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
                              --AND H.CODPROD = 165800
                              AND DECODE(NVL(PCODPRODUTO,0), 0, 0, H.CODPROD)  = DECODE(NVL(PCODPRODUTO,0), 0, 0, NVL(PCODPRODUTO,0))
                           ----------------------------   
                           UNION ALL 
                           ----------------------------
                           SELECT PCODFILIAL AS CODFILIAL,
                                  VDATAESTOQUEINICIO DATA_OPERACAO,
                                  H.CODPROD,
                                  'SI' TIPO_OPERACAO,
                                  0 QTEST,
                                  0 VLMEDIABASEST,
                                  0 VLMEDIAST,
                                  0 VLMEDIAICMS,
                                  0 VLMEDIAFCPST
                             FROM PCMOVTEMP H)  
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
       IF ((DADOS_MOVIMENTACAO.TIPO_OPERACAO = 'E') OR
           (PATUALIZAMEDIADIASEGUINTEENT = 'S')) THEN
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

       -- Simulando Cálculo de Restituição ou Complemento a consumidor final com saida interna
       -- para encontrar o CodMotivo correto conforme cadatro da 4011
       IF (PRESTITUI_COMPL_INT_CONS_FINAL = 'S') AND
          (DADOS_MOVIMENTACAO.TIPO_CLIENTE = 'C') AND
          ((DADOS_MOVIMENTACAO.CODFISCAL > 5000) AND
           (DADOS_MOVIMENTACAO.CODFISCAL < 5999)) THEN

          VC185_C10_VL_UNIT_ICMS := (DADOS_MOVIMENTACAO.PUNITCONT *
                                    (DADOS_MOVIMENTACAO.PERCALIQVIGINT /100));

          -- Simulando a soma dos campos C12 e C13
          vnVLSOMAC12C13 := V_VLMEDIAICMS + V_VLMEDIAST;

          IF vnVLSOMAC12C13 > 0 THEN
             VCALCULOCAMPO15_17 := (vnVLSOMAC12C13 - NVL(VC185_C10_VL_UNIT_ICMS,0));

             IF VCALCULOCAMPO15_17 > 0 THEN
                VRESSARCICOMEMENTA             := 'R';
             ELSE
                VRESSARCICOMEMENTA             := 'C';
             END IF;

         END IF;

       END IF;
       -------------------------------------------------------------------------------
       -- Simulando Cálculo de Restituição ou Complemento a saída interestadual ou estadual
       -- com vlbaseicmsst > 0 ou saida de perda (5927) para encontrar o CodMotivo correto conforme cadatro da 4011
       IF ((DADOS_MOVIMENTACAO.CODFISCAL > 6000) AND
           (DADOS_MOVIMENTACAO.CODFISCAL < 6999)) OR
          (((DADOS_MOVIMENTACAO.CODFISCAL > 5000) AND
            (DADOS_MOVIMENTACAO.CODFISCAL < 5999)) AND
            (DADOS_MOVIMENTACAO.VLBASEICMSST_SAIDA > 0)) OR
          (DADOS_MOVIMENTACAO.CODFISCAL = 5927)  THEN

        VRESSARCICOMEMENTA := 'R';

       END IF;
       -------------------------------------------------------------------------------

       -------------------------------------------------------------------------------


       PKG_DEBUGGING_FWPC.LOG_MSG('5 - Buscando código do motivo produto: '||DADOS_MOVIMENTACAO.CODPROD);
       VCODIGOMOTIVO := GET_CODIGOMOTIVO(DADOS_MOVIMENTACAO.CODFISCAL,
                                         DADOS_MOVIMENTACAO.TIPO_CLIENTE,
                                         VRESSARCICOMEMENTA);

       IF SUBSTR(VCODIGOMOTIVO,3,1) BETWEEN 0 AND 4 THEN
          VC185_C12_VL_UNIT_ICMS_OP_EST := V_VLMEDIAICMS;
          VC185_C13_VL_UNIT_ICMS_ST_EST := V_VLMEDIAST + V_VLMEDIAFCPST;
          VC185_C14_VL_UNIT_FCP_ST_EST  := V_VLMEDIAFCPST;
       END IF;

       -- Movimentação interna a consumidor
       IF (PRESTITUI_COMPL_INT_CONS_FINAL = 'S') AND
          (DADOS_MOVIMENTACAO.TIPO_CLIENTE = 'C') AND
          ((DADOS_MOVIMENTACAO.CODFISCAL > 5000) AND
           (DADOS_MOVIMENTACAO.CODFISCAL < 5999))   THEN

          -- Calculando C10
          VC185_C10_VL_UNIT_ICMS := (DADOS_MOVIMENTACAO.PUNITCONT * (DADOS_MOVIMENTACAO.PERCALIQVIGINT /100));

          -- Somando C12 e C13
          vnVLSOMAC12C13 := VC185_C12_VL_UNIT_ICMS_OP_EST + VC185_C13_VL_UNIT_ICMS_ST_EST;

          -- Se C12 e C13 maior que zero, continua calculos, pois não pode considerar
          -- credito ou complemento se essas colunas zeradas
          IF vnVLSOMAC12C13 > 0 THEN
             VCALCULOCAMPO15_17 := (vnVLSOMAC12C13 - NVL(VC185_C10_VL_UNIT_ICMS,0));

             IF VCALCULOCAMPO15_17 > 0 THEN
                VC185_C15_VL_UNIT_ICMS_ST_REST := VCALCULOCAMPO15_17;
                VREG_1255_C04_ICMS_ST_REST     := (VC185_C15_VL_UNIT_ICMS_ST_REST * DADOS_MOVIMENTACAO.QTCONT);
                --VRESSARCICOMEMENTA             := 'R';
             ELSE
                VC185_C17_VL_UNIT_ICMS_ST_COMP := ABS(VCALCULOCAMPO15_17);
                VREG_1255_C06_ICMS_ST_COMPL    := (VC185_C17_VL_UNIT_ICMS_ST_COMP * DADOS_MOVIMENTACAO.QTCONT);
                --VRESSARCICOMEMENTA             := 'C';
             END IF;

          END IF;

       END IF;
       -------------------------------------------------------------------------------

       -- Movimentação Externa
       IF ((DADOS_MOVIMENTACAO.CODFISCAL > 6000) AND
           (DADOS_MOVIMENTACAO.CODFISCAL < 6999)) OR
          (((DADOS_MOVIMENTACAO.CODFISCAL > 5000) AND
            (DADOS_MOVIMENTACAO.CODFISCAL < 5999)) AND
            (DADOS_MOVIMENTACAO.VLBASEICMSST_SAIDA > 0)) OR
          (DADOS_MOVIMENTACAO.CODFISCAL = 5927)  THEN

         IF DADOS_MOVIMENTACAO.CODFISCAL = 5411 THEN 
             VC185_C15_VL_UNIT_ICMS_ST_REST := NULL;
          ELSE 
             VC185_C15_VL_UNIT_ICMS_ST_REST := V_VLMEDIAST + V_VLMEDIAFCPST;
          END IF;  

         VREG_1255_C04_ICMS_ST_REST := (VC185_C15_VL_UNIT_ICMS_ST_REST * DADOS_MOVIMENTACAO.QTCONT);
       END IF;
       -------------------------------------------------------------------------------

       IF (DADOS_MOVIMENTACAO.TIPO_OPERACAO = 'S') THEN
         VQTCONT_ACUMULADO := VQTCONT_ACUMULADO - DADOS_MOVIMENTACAO.QTCONT;
       ELSE
         VQTCONT_ACUMULADO := VQTCONT_ACUMULADO + DADOS_MOVIMENTACAO.QTCONT;
       END IF;

       -- CALCULANDO COLUNA REG_1255_C03_CREDITO_ICMS_OP
       VREG_1255_C03_CREDITO_ICMS_OP := NVL(VC185_C12_VL_UNIT_ICMS_OP_EST,0) *
                                        NVL(DADOS_MOVIMENTACAO.QTCONT,0);

       -- Recalculando coluna "C185_C15_VL_UNIT_ICMS_ST_REST" se Motivo = 2
       IF SUBSTR(VCODIGOMOTIVO,3,1) = 2 THEN
          IF VGERACAMPO11C185ZERADO = 'S' THEN
             VC185_C15_VL_UNIT_ICMS_ST_REST := (VC185_C12_VL_UNIT_ICMS_OP_EST +
                                                VC185_C13_VL_UNIT_ICMS_ST_EST);
          ELSE
             VC185_C15_VL_UNIT_ICMS_ST_REST := (VC185_C13_VL_UNIT_ICMS_ST_EST);
          END IF;

           VREG_1255_C04_ICMS_ST_REST := (VC185_C15_VL_UNIT_ICMS_ST_REST * DADOS_MOVIMENTACAO.QTCONT);
       END IF;
       
       -- Preenchendo variável da coluna C185_C16_VL_UNIT_FCP_ST_REST 
       IF VC185_C15_VL_UNIT_ICMS_ST_REST > 0 THEN
          VC185_C16_VL_UNIT_FCP_ST_REST := VC185_C14_VL_UNIT_FCP_ST_EST;
       END IF;  
       
       -- Preenchendo VREG_1255_C05_FCP_ST_REST se C185_C16 > 0 
       IF VC185_C16_VL_UNIT_FCP_ST_REST > 0 THEN   
          VREG_1255_C05_FCP_ST_REST := VC185_C16_VL_UNIT_FCP_ST_REST * DADOS_MOVIMENTACAO.QTCONT;
       END IF;

       PKG_DEBUGGING_FWPC.LOG_MSG('6 - Inserindo dados movimentacao produto: '||DADOS_MOVIMENTACAO.CODPROD);
       INSERT INTO PCRESSARCIMENTONACIONAL(CODFILIAL,                        -- 49
                                           DATA_OPERACAO,                    -- 48
                                           TIPO_OPERACAO,                    -- 47
                                           CODOPER,                          -- 46
                                           TIPO_CLIENTE,                     -- 45
                                           CODIGO_MOTIVO,                    -- 44
                                           NUMTRANSACAO,                     -- 43
                                           NUMNOTA,                          -- 42
                                           CODPROD,                          -- 41
                                           NUMSEQ,                           -- 40
                                           CST,                              -- 39
                                           CODFISCAL,                        -- 38
                                           DESCRICAO,                        -- 37
                                           CODCEST,                          -- 36
                                           UNIDADE,                          -- 35
                                           UNIDADECOMERCIAL,                 -- 34
                                           QTCONT,                           -- 33
                                           QTUNITCX,                         -- 32
                                           PUNITCONT,                        -- 31
                                           QTEST,                            -- 30
                                           ------- MÉDIA UNITARIA IGUAL DA PCHISTEST -----
                                           VLMEDIABASEST_UNIT,               -- 29
                                           VLMEDIAICMS_UNIT,                 -- 28
                                           VLMEDIAST_UNIT,                   -- 27
                                           VLMEDIAFCPST_UNIT,                -- 26
                                           ------- MÉDIA MULTIPLICADO PELA QUANTIDADE ATUALIZADA DO ESTOQUE -----
                                           VLMEDIABASEST_SALDO,              -- 25
                                           VLMEDIAICMS_SALDO,                -- 24
                                           VLMEDIAST_SALDO,                  -- 23
                                           VLMEDIAFCPST_SALDO,               -- 22
                                           ------- MÉDIA MULTIPLICADO PELA QUANTIDADE QUE SAIU -----
                                           VLMEDIABASEST_DIARIA,             -- 21
                                           VLMEDIAICMS_DIARIA,               -- 20
                                           VLMEDIAST_DIARIA,                 -- 19
                                           VLMEDIAFCPST_DIARIA,              -- 18
                                           ------- VALOR DOS IMPOSTOS DE ENTRADA -----
                                           VLBASEICMSST_ENTRADA,             -- 17
                                           VLICMS_ENTRADA,                   -- 16
                                           VLICMSST_ENTRADA,                 -- 15
                                           VLFCPST_ENTRADA,                  -- 14
                                           ------- Dados do registro C185 -----
                                           C185_C10_VL_UNIT_ICMS,            -- 13
                                           C185_C12_VL_UNIT_ICMS_OP_EST,     -- 12
                                           C185_C13_VL_UNIT_ICMS_ST_EST,     -- 11
                                           C185_C14_VL_UNIT_FCP_ST_EST,      -- 10
                                           C185_C15_VL_UNIT_ICMS_ST_REST,    -- 09
                                           C185_C16_VL_UNIT_FCP_ST_REST,     -- 08
                                           C185_C17_VL_UNIT_ICMS_ST_COMPL,   -- 07
                                           C185_C18_VL_UNIT_FCP_ST_COMPL,    -- 06
                                           ------- Dados do registro 1255 -----
                                           REG_1255_C03_CREDITO_ICMS_OP,     -- 05
                                           REG_1255_C04_ICMS_ST_REST,        -- 04
                                           REG_1255_C05_FCP_ST_REST,         -- 03
                                           REG_1255_C06_ICMS_ST_COMPL,       -- 02
                                           REG_1255_C07_FCP_ST_COMPL         -- 01
                                           ) VALUES
                                          (DADOS_MOVIMENTACAO.CODFILIAL,        -- 49
                                           DADOS_MOVIMENTACAO.DATA_OPERACAO,    -- 48
                                           DADOS_MOVIMENTACAO.TIPO_OPERACAO,    -- 47
                                           DADOS_MOVIMENTACAO.CODOPER,          -- 46
                                           DADOS_MOVIMENTACAO.TIPO_CLIENTE,     -- 45
                                           VCODIGOMOTIVO,                       -- 44
                                           DADOS_MOVIMENTACAO.NUMTRANSACAO,     -- 43
                                           DADOS_MOVIMENTACAO.NUMNOTA,          -- 42
                                           DADOS_MOVIMENTACAO.CODPROD,          -- 41
                                           DADOS_MOVIMENTACAO.NUMSEQ,           -- 40
                                           DADOS_MOVIMENTACAO.CST,              -- 39
                                           DADOS_MOVIMENTACAO.CODFISCAL,        -- 38
                                           DADOS_MOVIMENTACAO.DESCRICAO,        -- 37
                                           DADOS_MOVIMENTACAO.CODCEST,          -- 36
                                           DADOS_MOVIMENTACAO.UNIDADE,          -- 35
                                           DADOS_MOVIMENTACAO.UNIDADECOMERCIAL, -- 34
                                           DADOS_MOVIMENTACAO.QTCONT,           -- 33
                                           DADOS_MOVIMENTACAO.QTUNITCX,         -- 32
                                           DADOS_MOVIMENTACAO.PUNITCONT,    -- 31
                                           VQTCONT_ACUMULADO,               -- 30
                                           ------- MÉDIA UNITARIA IGUAL DA PCHISTEST -----
                                           V_VLMEDIABASEST,                 -- 29
                                           V_VLMEDIAICMS,                   -- 28
                                           V_VLMEDIAST,                     -- 27
                                           V_VLMEDIAFCPST,                  -- 26
                                           ------- MÉDIA MULTIPLICADO PELA QUANTIDADE ATUALIZADA DO ESTOQUE -----
                                           V_VLMEDIABASEST * VQTCONT_ACUMULADO, -- 25
                                           V_VLMEDIAICMS   * VQTCONT_ACUMULADO, -- 24
                                           V_VLMEDIAST     * VQTCONT_ACUMULADO, -- 23
                                           V_VLMEDIAFCPST  * VQTCONT_ACUMULADO, -- 22
                                           ------- MÉDIA MULTIPLICADO PELA QUANTIDADE QUE SAIU -----
                                           V_VLMEDIABASEST * DADOS_MOVIMENTACAO.QTCONT, -- 21
                                           V_VLMEDIAICMS   * DADOS_MOVIMENTACAO.QTCONT, -- 20
                                           V_VLMEDIAST     * DADOS_MOVIMENTACAO.QTCONT, -- 19
                                           V_VLMEDIAFCPST  * DADOS_MOVIMENTACAO.QTCONT, -- 18
                                           ------- VALOR DOS IMPOSTOS DE ENTRADA -----
                                           DADOS_MOVIMENTACAO.VLBASEICMSST_ENTRADA, -- 17
                                           DADOS_MOVIMENTACAO.VLICMS_ENTRADA,       -- 16
                                           DADOS_MOVIMENTACAO.VLICMSST_ENTRADA,     -- 15
                                           DADOS_MOVIMENTACAO.VLFCPST_ENTRADA,      -- 14
                                           ------- Dados do registro C185 -----
                                           VC185_C10_VL_UNIT_ICMS,                  -- 13
                                           VC185_C12_VL_UNIT_ICMS_OP_EST,           -- 12
                                           VC185_C13_VL_UNIT_ICMS_ST_EST,           -- 11
                                           VC185_C14_VL_UNIT_FCP_ST_EST,            -- 10
                                           VC185_C15_VL_UNIT_ICMS_ST_REST,          -- 09
                                           VC185_C16_VL_UNIT_FCP_ST_REST,           -- 08
                                           VC185_C17_VL_UNIT_ICMS_ST_COMP,          -- 07
                                           VC185_C18_VL_UNIT_FCP_ST_COMPL,          -- 06
                                           ------- Dados do registro 1255 -----
                                           VREG_1255_C03_CREDITO_ICMS_OP,           -- 05
                                           VREG_1255_C04_ICMS_ST_REST,              -- 04
                                           VREG_1255_C05_FCP_ST_REST,               -- 03
                                           VREG_1255_C06_ICMS_ST_COMPL,             -- 02
                                           VREG_1255_C07_FCP_ST_COMPL               -- 01
                                           );

     COMMIT;
     VRESSARCICOMEMENTA := '';
     END LOOP; --End Loop movimentação (Entrada/saída)
   END LOOP; -- End Loop Saldo Inicial PCHISTEST.
END;
-- 27/05/2025 - GAM - V 010