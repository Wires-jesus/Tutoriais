CREATE OR REPLACE PACKAGE BODY PKG_INTEGRACAOWMSSAAS IS

  PROCEDURE INTEGRARDOCUMENTONOWMSSAAS(pCODFILIAL      IN VARCHAR2,
                                       pNUMDOCWINTHOR  IN NUMBER,
                                       pTIPOINTEGRACAO IN VARCHAR2,
                                       pTIPODOCWINTHOR IN VARCHAR2) IS

    vDIVIDIRDOCUMENTO           VARCHAR2(2);
    vDOCWMSSAAS_FRACIONADO      NUMBER(14);
    vDOCWMSSAAS_CAIXA           NUMBER(14);
    vDOCUMENTOFOIDIVIDIDO       VARCHAR2(2);
    vDOCUMENTOFOIGERADOCOMPLETO VARCHAR2(2);
    vDOCUMENTOFOIGERADOFRAC     VARCHAR2(2);
    vDOCUMENTOFOIGERADOCX       VARCHAR2(2);
    vLIBERARINTEGRACAODOCCAIXA  VARCHAR2(2);
    v_COUNT                     NUMBER;
    vBODY                       VARCHAR2(500);
    vIDENTIFCADOR_OPERACAO      VARCHAR2(30);
    V_NOW                       DATE;

  BEGIN

    vDOCUMENTOFOIDIVIDIDO   := 'N';
    vDOCUMENTOFOIGERADOFRAC := 'N';
    vDOCUMENTOFOIGERADOCX   := 'N';
    v_COUNT                 := 0;

    ---AGUARDA 2 SEGUNDOS PARA INICIAR EXECUÇÃO
    SELECT SYSDATE INTO V_NOW FROM DUAL;
    LOOP
      EXIT WHEN V_NOW +(2 * (1 / 86400)) <= SYSDATE;
    END LOOP;

    vIDENTIFCADOR_OPERACAO := TO_CHAR(SYSTIMESTAMP, 'yyyymmddhh24missff3');

    vBODY := 'Filial: ' || pCODFILIAL || ', Documento Winthor: ' ||
             TO_CHAR(pNUMDOCWINTHOR) || ', Tipo Integração: ' ||
             pTIPOINTEGRACAO || ', Identificador: ' ||
             vIDENTIFCADOR_OPERACAO || ', Tipo Documento: ' ||
             pTIPODOCWINTHOR;

    vDOCWMSSAAS_FRACIONADO := TO_NUMBER(TO_CHAR(pNUMDOCWINTHOR) || '0001');
    vDOCWMSSAAS_CAIXA      := TO_NUMBER(TO_CHAR(pNUMDOCWINTHOR) || '0002');

    BEGIN
      SELECT VALOR
        INTO vDIVIDIRDOCUMENTO
        FROM PCPARAMINTEGRACAOWMSSAAS
       WHERE PARAMETRO = 'DIVIDIRDOCUMENTOENTRECXEFRACIONADO'
         AND CODFILIAL = pCODFILIAL;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vDIVIDIRDOCUMENTO := 'N';
    END;

    --VERIFA SE ´PEDIDO JÁ NÃO FOI COLOCADO NA LISTA DE PENDENCIAS DE INTEGRAÇÕES
    SELECT COUNT(1)
      INTO v_COUNT
      FROM PCINTEGRACAOWMSSAAS
     WHERE NUMDOCWINTHOR = pNUMDOCWINTHOR
       AND CODFILIAL = pCODFILIAL
       AND TIPODOCWINTHOR = pTIPODOCWINTHOR
       AND DTCANCELAMENTO IS NULL
       AND DTFIMSEPARACAO IS NULL
       AND DTFILAINTEGRACAO IS NOT NULL;

    IF (v_COUNT > 0) THEN
      ----DOCUMENTO JÁ EXISTE NA FILA DE INTEGRAÇÃO
      GRAVAR_LOG('PKG_INTEGRACAOWMSSAAS.INTEGRARDOCUMENTONOWMSSAAS',
                 'PROCESSAMENTO_INTERNO_OBJETO',
                 vBODY ||
                 ', Descrição: Tentou processar documento já existente, quantidade existente:' ||
                 TO_CHAR(v_COUNT));
    END IF;

    IF (pTIPODOCWINTHOR = 'PEDIDO_VENDA') AND (v_COUNT = 0) THEN
      GRAVAR_LOG('PKG_INTEGRACAOWMSSAAS.INTEGRARDOCUMENTONOWMSSAAS',
                 'PROCESSAMENTO_INTERNO_OBJETO',
                 vBODY || ', Descrição: Integração de novo documento');

      FOR REG IN (SELECT DISTINCT ITEM.CODPROD,
                                  ITEM.QT,
                                  WMS_QTUNITCXFILIAL(ITEM.CODPROD, FL.CODIGO) AS QTUNITCX,
                                  PRODFILIAL.FRACIONADO,
                                  DECODE(PRODFILIAL.TIPOPROD, 5, 'S', 'N') AS EMBALADO,
                                  MOD(ITEM.QT,
                                      WMS_QTUNITCXFILIAL(ITEM.CODPROD,
                                                         FL.CODIGO)) AS QTUNIDADESFORACAIXA,
                                  FLOOR(ITEM.QT /
                                        WMS_QTUNITCXFILIAL(ITEM.CODPROD,
                                                           FL.CODIGO)) *
                                  WMS_QTUNITCXFILIAL(ITEM.CODPROD, FL.CODIGO) AS QTUNIDADESDENTROCAIXA,
                                  ITEM.NUMPED,
                                  PRODUTO.DESCRICAO,
                                  PRODUTO.UNIDADE,
                                  COALESCE(ITEM.CODFILIALRETIRA,
                                           PED.CODFILIAL) CODFILIAL,
                                  FL.RAZAOSOCIAL NOMEFILIAL,
                                  ITEM.PVENDA,
                                  ROUND(ITEM.QT * ITEM.PVENDA, 2) VLTOTAL,
                                  ITEM.QTSEPARADA,
                                  ITEM.DTINICIALSEP,
                                  ITEM.DTFINALSEP,
                                  ITEM.NUMSEQ,
                                  ITEM.NUMCAR,
                                  PRODUTO.TIPOESTOQUE,
                                  PRODUTO.TIPOMERC,
                                  DECODE(NVL(PRODUTO.CODCATEGORIA, 0),
                                         0,
                                         NULL,
                                         NVL((SELECT CATEGORIA
                                               FROM PCCATEGORIA
                                              WHERE CODCATEGORIA =
                                                    PRODUTO.CODCATEGORIA
                                                AND CODSEC = PRODUTO.CODSEC
                                                AND ROWNUM = 1),
                                             0)) CATEGORIA_PRODUTO,
                                  ---SKU
                                  PRODUTO.CODAUXILIAR SKU_CODBARRAS,
                                  PRODUTO.EMBALAGEM   SKU_DESCRICAO,
                                  PRODUTO.QTUNIT      SKU_QTUNIT,
                                  ---SKU 2
                                  PRODUTO.CODAUXILIAR2 SKU_CODBARRAS_2,
                                  PRODUTO.EMBALAGEMMASTER SKU_DESCRICAO_2,
                                  PRODUTO.QTUNITCX SKU_QTUNIT_2,
                                  ITEM.NUMLOTE

                    FROM PCPEDI       ITEM,
                         PCPRODUT     PRODUTO,
                         PCPEDC       PED,
                         PCFILIAL     FL,
                         PCPRODFILIAL PRODFILIAL
                   WHERE PED.NUMPED = ITEM.NUMPED
                     AND ITEM.NUMPED = pNUMDOCWINTHOR
                     AND FL.CODIGO =
                         COALESCE(ITEM.CODFILIALRETIRA, PED.CODFILIAL)
                     AND FL.CODIGO = pCODFILIAL
                     AND FL.CODIGO = PRODFILIAL.CODFILIAL
                     AND ITEM.CODPROD = PRODFILIAL.CODPROD
                     AND ITEM.CODPROD = PRODUTO.CODPROD
                     AND ITEM.NUMSEQ IS NOT NULL
                     AND NOT EXISTS
                   (SELECT 1
                            FROM PCINTEGRACAOWMSSAAS
                           WHERE NUMDOCWINTHOR = pNUMDOCWINTHOR
                             AND CODFILIAL = pCODFILIAL
                             AND TIPODOCWINTHOR = pTIPODOCWINTHOR
                             AND DTCANCELAMENTO IS NULL
                             AND DTFIMSEPARACAO IS NULL
                             AND DTFILAINTEGRACAO IS NOT NULL))

       LOOP
        --VERIFICA SE ESTÁ APTO A GERAR DOIS DOCUMENTOS (CAIXA E FRACIONADO)
        IF vDIVIDIRDOCUMENTO = 'S' AND
           (REG.FRACIONADO = 'S' OR REG.EMBALADO = 'S') THEN

          vDOCUMENTOFOIDIVIDIDO := 'S';

          --GERA DOCUMENTO COM A QUANTIDADE FRACIONADA
          IF REG.QTUNIDADESFORACAIXA > 0 THEN

            ENVIARDOCFILAINTEGRACAOITEM(vDOCWMSSAAS_FRACIONADO,
                                        REG.CODPROD,
                                        REG.QTUNIDADESFORACAIXA,
                                        REG.QTUNIDADESFORACAIXA,
                                        REG.NUMSEQ);

            vDOCUMENTOFOIGERADOFRAC := 'S';
          END IF;

          --GERA DOCUMENTO COM A QUANTIDADE UN(CAIXA)
          IF REG.QTUNIDADESDENTROCAIXA > 0 THEN

            ENVIARDOCFILAINTEGRACAOITEM(vDOCWMSSAAS_CAIXA,
                                        REG.CODPROD,
                                        REG.QTUNIDADESDENTROCAIXA,
                                        REG.QTUNIDADESDENTROCAIXA,
                                        REG.NUMSEQ);

            vDOCUMENTOFOIGERADOCX := 'S';
          END IF;

          vBODY := 'Filial: ' || pCODFILIAL || ', Documento Winthor: ' ||
                   TO_CHAR(REG.NUMPED) || ', Codprod: ' ||
                   TO_CHAR(REG.CODPROD) || ', Fracionado: ' ||
                   REG.FRACIONADO || ', Qt.Fracionada(UN): ' ||
                   TO_CHAR(REG.QTUNIDADESFORACAIXA) || ', Qt.Caixas(UN): ' ||
                   TO_CHAR(REG.QTUNIDADESDENTROCAIXA) || ', Embalado: ' ||
                   REG.EMBALADO || ', Documento dividido: ' || 'S' ||
                   ', Numseq: ' || TO_CHAR(REG.NUMSEQ) ||
                   ', Identificador: ' || vIDENTIFCADOR_OPERACAO ||
                   ', Quantidade: ' || TO_CHAR(REG.QT) ||
                   ', Tipo Documento: ' || pTIPODOCWINTHOR;

          GRAVAR_LOG('PKG_INTEGRACAOWMSSAAS.INTEGRARDOCUMENTONOWMSSAAS',
                     'INSERT_PCINTEGRACAOWMSSAASITEM',
                     vBODY ||
                     ', Descrição: Inserção do item na tabela PCINTEGRACAOWMSSAASITEM');

          --CASO CONTRARIO GERA APENAS UM DOCUMENTO
        ELSE

          ENVIARDOCFILAINTEGRACAOITEM(REG.NUMPED,
                                      REG.CODPROD,
                                      REG.QT,
                                      REG.QT,
                                      REG.NUMSEQ);

          vDOCUMENTOFOIGERADOCOMPLETO := 'S';

          vBODY := 'Filial: ' || pCODFILIAL || ', Documento Winthor: ' ||
                   TO_CHAR(REG.NUMPED) || ', Codprod: ' ||
                   TO_CHAR(REG.CODPROD) || ', Fracionado: ' ||
                   REG.FRACIONADO || ', Embalado: ' || REG.EMBALADO ||
                   ', Documento dividido: ' || 'N' || ', Numseq: ' ||
                   TO_CHAR(REG.NUMSEQ) || ', Identificador: ' ||
                   vIDENTIFCADOR_OPERACAO || ', Quantidade: ' ||
                   TO_CHAR(REG.QT) || ', Tipo Documento: ' ||
                   pTIPODOCWINTHOR;

          GRAVAR_LOG('PKG_INTEGRACAOWMSSAAS.INTEGRARDOCUMENTONOWMSSAAS',
                     'INSERT_PCINTEGRACAOWMSSAASITEM',
                     vBODY ||
                     ', Descrição: Inserção do item na tabela PCINTEGRACAOWMSSAASITEM');

        END IF;

      END LOOP;

      --GERAR CABECHALO DOS DOCUMETOS (COMPLETO, FRACIONADO ou CAIXA)

      IF vDOCUMENTOFOIGERADOCOMPLETO = 'S' THEN
        ENVIARDOCFILAINTEGRACAO(pCODFILIAL,
                                pNUMDOCWINTHOR,
                                pNUMDOCWINTHOR,
                                pTIPOINTEGRACAO,
                                pTIPODOCWINTHOR,
                                'COMPLETO',
                                'S');

        vBODY := 'Filial: ' || pCODFILIAL || ', Documento Winthor: ' ||
                 TO_CHAR(pNUMDOCWINTHOR) || ', Documento WMS Saas:' ||
                 TO_CHAR(pNUMDOCWINTHOR) || ', Tipo Integração: ' ||
                 pTIPOINTEGRACAO || ', Identificador: ' ||
                 vIDENTIFCADOR_OPERACAO || ', Tipo Geração Doc: ' ||
                 'COMPLETO' || ', Tipo Documento: ' || pTIPODOCWINTHOR;

        GRAVAR_LOG('PKG_INTEGRACAOWMSSAAS.INTEGRARDOCUMENTONOWMSSAAS',
                   'INSERT_PCINTEGRACAOWMSSAAS',
                   vBODY ||
                   ', Descrição: Inserção do documento na tabela PCINTEGRACAOWMSSAAS');

      END IF;

      IF vDOCUMENTOFOIDIVIDIDO = 'S' THEN

        IF vDOCUMENTOFOIGERADOFRAC = 'S' THEN
          ENVIARDOCFILAINTEGRACAO(pCODFILIAL,
                                  pNUMDOCWINTHOR,
                                  vDOCWMSSAAS_FRACIONADO,
                                  pTIPOINTEGRACAO,
                                  pTIPODOCWINTHOR,
                                  'FRACIONADO',
                                  'S');

          vBODY := 'Filial: ' || pCODFILIAL || ', Documento Winthor: ' ||
                   TO_CHAR(pNUMDOCWINTHOR) || ', Documento WMS Saas:' ||
                   TO_CHAR(vDOCWMSSAAS_FRACIONADO) || ', Tipo Integração: ' ||
                   pTIPOINTEGRACAO || ', Identificador: ' ||
                   vIDENTIFCADOR_OPERACAO || ', Tipo Geração Doc: ' ||
                   'FRACIONADO' || ', Tipo Documento: ' || pTIPODOCWINTHOR;

          GRAVAR_LOG('PKG_INTEGRACAOWMSSAAS.INTEGRARDOCUMENTONOWMSSAAS',
                     'INSERT_PCINTEGRACAOWMSSAAS',
                     vBODY ||
                     ', Descrição: Inserção do documento na tabela PCINTEGRACAOWMSSAAS');

        END IF;

        IF vDOCUMENTOFOIGERADOCX = 'S' THEN

          vLIBERARINTEGRACAODOCCAIXA := 'S';
          IF vDOCUMENTOFOIGERADOFRAC = 'S' THEN
            vLIBERARINTEGRACAODOCCAIXA := 'N';
          END IF;

          ENVIARDOCFILAINTEGRACAO(pCODFILIAL,
                                  pNUMDOCWINTHOR,
                                  vDOCWMSSAAS_CAIXA,
                                  pTIPOINTEGRACAO,
                                  pTIPODOCWINTHOR,
                                  'CAIXA',
                                  vLIBERARINTEGRACAODOCCAIXA);

          vBODY := 'Filial: ' || pCODFILIAL || ', Documento Winthor: ' ||
                   TO_CHAR(pNUMDOCWINTHOR) || ', Documento WMS Saas:' ||
                   TO_CHAR(vDOCWMSSAAS_CAIXA) || ', Tipo Integração: ' ||
                   pTIPOINTEGRACAO || ', Identificador: ' ||
                   vIDENTIFCADOR_OPERACAO || ', Tipo Geração Doc: ' ||
                   'CAIXA' || ', Tipo Documento: ' || pTIPODOCWINTHOR;

          GRAVAR_LOG('PKG_INTEGRACAOWMSSAAS.INTEGRARDOCUMENTONOWMSSAAS',
                     'INSERT_PCINTEGRACAOWMSSAAS',
                     vBODY ||
                     ', Descrição: Inserção do documento na tabela PCINTEGRACAOWMSSAAS');
        END IF;

      END IF;

    END IF;
  END INTEGRARDOCUMENTONOWMSSAAS;

  PROCEDURE ENVIARDOCFILAINTEGRACAO(pCODFILIAL              IN VARCHAR2,
                                    pNUMDOCWINTHOR          IN NUMBER,
                                    pNUMDOCSAAS             IN NUMBER,
                                    pTIPOINTEGRACAO         IN VARCHAR2,
                                    pTIPODOCWINTHOR         IN VARCHAR2,
                                    pTIPOGERACAODOC         IN VARCHAR2,
                                    pLIBERADOPARAINTEGRACAO IN VARCHAR2) IS

    vNUMCAR                 NUMBER(8);
    vCODCLI                 NUMBER(12);
    vOBS                    VARCHAR2(500);
    vOBS_ORIGINAL           VARCHAR2(500);
    vEXPORTAINFODOCORIGINAL VARCHAR2(2);
    vBODY                   VARCHAR2(500);
    vIDENTIFCADOR_OPERACAO  VARCHAR2(30);

  BEGIN

    vOBS                    := '';
    vOBS_ORIGINAL           := '';
    vEXPORTAINFODOCORIGINAL := 'N';
    vNUMCAR                 := 0;
    vCODCLI                 := 0;

    IF pTIPOGERACAODOC IN ('CAIXA', 'FRACIONADO') THEN
      vEXPORTAINFODOCORIGINAL := 'S';
    END IF;

    BEGIN
      SELECT NUMCAR, CODCLI
        INTO vNUMCAR, vCODCLI
        FROM PCPEDC
       WHERE NUMPED = pNUMDOCWINTHOR;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vNUMCAR := 0;
        vCODCLI := 0;
    END;

    SELECT NVL(OBS, '')
      INTO vOBS_ORIGINAL
      FROM PCPEDC
     WHERE NUMPED = pNUMDOCWINTHOR;

    SELECT DECODE(NVL((SELECT NVL(VALOR, 'N')
                        FROM PCPARAMINTEGRACAOWMSSAAS
                       WHERE PARAMETRO = 'EXPORTA_RAMO_ATIVIDADE_CLIENTE'
                         AND CODFILIAL = pCODFILIAL),
                      'N'),
                  'S',
                  DECODE(ATIV.RAMO,
                         NULL,
                         '',
                         ' / RAMO DE ATIVIDADE DO CLIENTE: ' || ATIV.RAMO ||
                         ' / TIPO DE VENDA: ' || PED.CONDVENDA),
                  NULL) || DECODE(vEXPORTAINFODOCORIGINAL,
                                  'S',
                                  '/ PEDIDO DE VENDA ORIGINAL WINTHOR: ' ||
                                  TO_CHAR(pNUMDOCWINTHOR),
                                  '') AS OBS
      INTO vOBS
      FROM PCATIVI ATIV, PCCLIENT CLI, PCPEDC PED
     WHERE CLI.CODATV1 = ATIV.CODATIV(+)
       AND PED.CODCLI = CLI.CODCLI
       AND PED.NUMPED = pNUMDOCWINTHOR;

    BEGIN
      INSERT INTO PCINTEGRACAOWMSSAAS
        (CODFILIAL,
         NUMDOCWINTHOR,
         TIPODOCWINTHOR,
         NUMCAR,
         NUMDOCWMSSAAS,
         TIPOGERACAODOC,
         DTFILAINTEGRACAO,
         DATADOCWINTHOR,
         LIBERADOINTEGRACAO,
         TIPOINTEGRACAO,
         CODCLI,
         DTENTREGA,
         OBS)
      VALUES
        (pCODFILIAL,
         pNUMDOCWINTHOR,
         pTIPODOCWINTHOR,
         vNUMCAR,
         pNUMDOCSAAS,
         pTIPOGERACAODOC,
         SYSDATE,
         (SELECT DATA
            FROM PCPEDC
           WHERE NUMPED = pNUMDOCWINTHOR
             AND ROWNUM = 1),
         pLIBERADOPARAINTEGRACAO,
         pTIPOINTEGRACAO,
         vCODCLI,
         (SELECT DTENTREGA
            FROM PCPEDC
           WHERE NUMPED = pNUMDOCWINTHOR
             AND ROWNUM = 1),
         vOBS_ORIGINAL || vOBS);
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        vIDENTIFCADOR_OPERACAO := TO_CHAR(SYSTIMESTAMP,
                                          'yyyymmddhh24missff3');

        vBODY := 'Filial: ' || pCODFILIAL || ', Documento Winthor: ' ||
                 TO_CHAR(pNUMDOCWINTHOR) || ', Tipo Integração: ' ||
                 pTIPOINTEGRACAO || ', Identificador: ' ||
                 vIDENTIFCADOR_OPERACAO || ', Tipo Documento: ' ||
                 pTIPODOCWINTHOR;

        GRAVAR_LOG('PKG_INTEGRACAOWMSSAAS.ENVIARDOCFILAINTEGRACAO',
                   'ERRO_DUPLICIDADE_INSERCAO_PCINTEGRACAOWMSSAAS',
                   vBODY ||
                   ', Descrição: Falha na inserção na PCINTEGRACAOWMSSAAS por violação da UK');
    END;

  END ENVIARDOCFILAINTEGRACAO;

  PROCEDURE FINALIZARSEPARACAOITEMFILA(pCODFILIAL     IN VARCHAR2,
                                       pNUMDOCWMSSAAS IN NUMBER,
                                       pCODPROD       IN NUMBER,
                                       pNUMSEQ        IN NUMBER,
                                       pQTSEPARADA    IN NUMBER,
                                       pNUMLOTE       IN VARCHAR2) IS

    vREGISTRO_NOVO         PCINTEGRACAOWMSSAASITEM%ROWTYPE;
    vIDENTIFCADOR_OPERACAO VARCHAR2(30);
    v_COUNT                NUMBER;
    vBODY                  VARCHAR2(500);

  BEGIN
    vIDENTIFCADOR_OPERACAO := TO_CHAR(SYSTIMESTAMP, 'yyyymmddhh24missff3');

    UPDATE PCINTEGRACAOWMSSAASITEM
       SET QTSEPARADA = pQTSEPARADA, NUMLOTE = pNUMLOTE
     WHERE NUMDOCWMSSAAS = pNUMDOCWMSSAAS
       AND CODPROD = pCODPROD
       AND NUMSEQ = pNUMSEQ
       AND NVL(QTSEPARADA, 0) = 0;

    v_COUNT := SQL%ROWCOUNT;

    vBODY := 'Filial: ' || pCODFILIAL || ', Documento WMS Saas:' ||
             TO_CHAR(pNUMDOCWMSSAAS) || ', Codprod: ' || TO_CHAR(pCODPROD) ||
             ', Sequencia: ' || TO_CHAR(pNUMSEQ) || ', Qt.Separada: ' ||
             TO_CHAR(pQTSEPARADA) || ', Lote: ' || pNUMLOTE ||
             ', Linhas Altedas: ' || TO_CHAR(v_COUNT) ||
             ', Identificador: ' || vIDENTIFCADOR_OPERACAO;

    GRAVAR_LOG('PKG_INTEGRACAOWMSSAAS.FINALIZARSEPARACAOITEMFILA',
               'UPDATE_PCINTEGRACAOWMSSAASITEM',
               vBODY ||
               ', Descrição: Finalização da separação na tabela PCINTEGRACAOWMSSAASITEM');

    IF v_COUNT = 0 THEN
      ---TRATAR CENARIO ONDE PRODUTO COM MESMO LOTE E CONFERIDO DUAS VEZES.
      UPDATE PCINTEGRACAOWMSSAASITEM
         SET QTSEPARADA = NVL(QTSEPARADA, 0) + pQTSEPARADA
       WHERE NUMDOCWMSSAAS = pNUMDOCWMSSAAS
         AND CODPROD = pCODPROD
         AND NUMSEQ = pNUMSEQ
         AND NUMLOTE = pNUMLOTE
         AND NVL(QTSEPARADA, 0) > 0;

      v_COUNT := SQL%ROWCOUNT;
      IF v_COUNT = 0 THEN
        FOR vREG IN (SELECT *
                       FROM PCINTEGRACAOWMSSAASITEM
                      WHERE NUMDOCWMSSAAS = pNUMDOCWMSSAAS
                        AND CODPROD = pCODPROD
                        AND ROWNUM = 1) LOOP
          vREGISTRO_NOVO            := vREG;
          vREGISTRO_NOVO.NUMLOTE    := pNUMLOTE;
          vREGISTRO_NOVO.QTSEPARADA := pQTSEPARADA;
          INSERT INTO PCINTEGRACAOWMSSAASITEM VALUES vREGISTRO_NOVO;

          GRAVAR_LOG('PKG_INTEGRACAOWMSSAAS.FINALIZARSEPARACAOITEMFILA',
                     'INSERT_PCINTEGRACAOWMSSAASITEM',
                     vBODY ||
                     ', Descrição: Finalização da separação na tabela PCINTEGRACAOWMSSAASITEM)');
        END LOOP;
      END IF;

    END IF;

  END FINALIZARSEPARACAOITEMFILA;

  PROCEDURE EFETUAR_AJUSTE_ESTOQUE(pCODFILIAL  IN VARCHAR2,
                                   pCODPROD    IN NUMBER,
                                   pQUANTIDADE IN NUMBER,
                                   pTIPO       IN VARCHAR2,
                                   --pVALIDADE   IN DATE,
                                   pVALIDADE IN VARCHAR2,
                                   pNUMLOTE  IN VARCHAR2) IS
    v_PROX_NUM_LANCAMENTO  NUMBER;
    v_NUMTRANSENT          NUMBER;
    v_NUMTRANSVENDA        NUMBER;
    v_CODCONTAJUSTEEST     NUMBER;
    v_CODOPER              VARCHAR2(2);
    v_COUNT                NUMBER;
    v_USA_ESTOQUE_POR_LOTE VARCHAR2(1);
    v_CODEPTO              NUMBER;
    v_CODSEC               NUMBER;
    v_CUSTOULTENT          NUMBER;
    v_CUSTOCONT            NUMBER;
    v_CUSTOREAL            NUMBER;
    v_CUSTOFIN             NUMBER;
    v_msg_retorno          VARCHAR2(4000);
    v_RESULTADO            NUMBER;
    v_NUMLANC              NUMBER;
    v_PRAZOVAL             NUMBER;

  BEGIN
    --Carrega valores das transaÃ§Ãµes e da conta de ajuste
    SELECT PROXNUMLANC,
           PROXNUMTRANSENT,
           PROXNUMTRANSVENDA,
           CODCONTAJUSTEEST
      INTO v_PROX_NUM_LANCAMENTO,
           v_NUMTRANSENT,
           v_NUMTRANSVENDA,
           v_CODCONTAJUSTEEST
      FROM PCCONSUM
       FOR UPDATE;

    UPDATE PCCONSUM
       SET PROXNUMLANC       = PROXNUMLANC + 1,
           PROXNUMTRANSENT   = PROXNUMTRANSENT + 1,
           PROXNUMTRANSVENDA = PROXNUMTRANSVENDA + 1;

    SELECT NVL(ESTOQUEPORLOTE, 'N'),
           NVL(CODEPTO, 0),
           NVL(CODSEC, 0),
           NVL(PRAZOVAL, 0)
      INTO v_USA_ESTOQUE_POR_LOTE, v_CODEPTO, v_CODSEC, v_PRAZOVAL
      FROM PCPRODUT
     WHERE CODPROD = pCODPROD;

    --Carrega valores de custos dos produtos
    select nvl(pcest.CUSTOULTENT, 0) CUSTOULTENT,
           nvl(pcest.CUSTOCONT, 0) CUSTOCONT,
           nvl(pcest.CUSTOREAL, 0) CUSTOREAL,
           nvl(pcest.CUSTOFIN, 0) CUSTOFIN
      INTO v_CUSTOULTENT, v_CUSTOCONT, v_CUSTOREAL, v_CUSTOFIN
      from pcest
     where codprod = pCODPROD
       and codfilial = pCODFILIAL;

    IF pTIPO = 'E' THEN
      v_CODOPER := 'EA';

      IF v_USA_ESTOQUE_POR_LOTE = 'S' THEN

        ---Caso seja uma entrada de um lote novo, o mesmo deve ser inserido na PCMOV
        select count(numlote)
          INTO v_COUNT
          from pclote
         where codprod = pCODPROD
           and numlote = pNUMLOTE
           and codfilial = pCODFILIAL;

        IF v_COUNT = 0 THEN
          INSERT INTO PCLOTE
            (CODPROD,
             CODFILIAL,
             QT,
             DTVALIDADE,
             NUMLOTE,
             NUMTRANSENT,
             QTEST,
             DATAFABRICACAO)
          VALUES
            (pCODPROD,
             pCODFILIAL,
             pQUANTIDADE,
             TO_DATE(pVALIDADE, 'dd/mm/yyyy'),
             pNUMLOTE,
             v_NUMTRANSENT,
             0,
             TRUNC(TO_DATE(pVALIDADE, 'dd/mm/yyyy')) - v_PRAZOVAL);
        END IF;

      END IF;

    END IF;

    IF pTIPO = 'S' THEN
      v_CODOPER := 'SA';
    END IF;

    --CriaÃ§Ã£o da MovimentaÃ§Ã£o
    INSERT INTO PCMOV
      (DTMOV,
       CODPROD,
       NUMNOTA,
       CODOPER,
       QT,
       QTBLOQUEADA,
       PUNIT,
       CODFILIAL,
       CODCLI,
       CODUSUR,
       CUSTOFIN,
       CUSTOCONT,
       CUSTOREAL,
       STATUS,
       CODEPTO,
       CODSEC,
       CODFORNEC,
       CODFUNCLANC,
       NUMTRANSVENDA,
       NUMTRANSENT,
       CODDEVOL,
       NUMLOTE)
    VALUES
      (TRUNC(SYSDATE),
       pCODPROD,
       0,
       v_CODOPER,
       pQUANTIDADE,
       pQUANTIDADE,
       0,
       pCODFILIAL,
       0,
       0,
       v_CUSTOFIN,
       v_CUSTOCONT,
       v_CUSTOREAL,
       'B',
       v_CODEPTO,
       v_CODSEC,
       0,
       1,
       DECODE(v_CODOPER, 'SA', v_NUMTRANSVENDA, 0),
       DECODE(v_CODOPER, 'EA', v_NUMTRANSENT, 0),
       0,
       DECODE((SELECT NVL(ESTOQUEPORLOTE, 'N')
                FROM PCPRODUT
               WHERE CODPROD = pCODPROD),
              'S',
              pNUMLOTE,
              NULL));

    IF pTIPO = 'E' THEN

      v_RESULTADO := PKG_ESTOQUE.LOGISTICA_ENTRADA(v_NUMTRANSENT,
                                                   'N',
                                                   v_msg_retorno);

      IF v_msg_retorno <> 'OK' THEN
        RAISE_APPLICATION_ERROR(-20001,
                                'Erro ao executar LOGISTICA_ENTRADA: ' ||
                                v_msg_retorno);
      END IF;

    END IF;

    IF pTIPO = 'S' THEN

      v_RESULTADO := PKG_ESTOQUE.LOGISTICA_SAIDA(v_NUMTRANSVENDA,
                                                 'N',
                                                 v_msg_retorno);

      IF v_msg_retorno <> 'OK' THEN
        RAISE_APPLICATION_ERROR(-20001,
                                'Erro ao executar LOGISTICA_SAIDA: ' ||
                                v_msg_retorno);
      END IF;

    END IF;

    SELECT NVL(PROXNUMLANC, 0) NUMLANC,
           NVL(CODCONTAJUSTEEST, 0) CODCONTAJUSTEEST
      INTO v_NUMLANC, v_CODCONTAJUSTEEST
      FROM PCCONSUM
       FOR UPDATE;

    UPDATE PCCONSUM SET PROXNUMLANC = NVL(PROXNUMLANC, 0) + 1;

    ----------Inserindo PCLANC------
    INSERT INTO PCLANC
      (RECNUM,
       DTLANC,
       CODCONTA,
       CODFORNEC,
       HISTORICO,
       NUMNOTA,
       DUPLIC,
       VALOR,
       DTVENC,
       VPAGO,
       DTPAGTO,
       CODFILIAL,
       INDICE,
       TIPOPARCEIRO,
       NOMEFUNC)
    VALUES
      (v_NUMLANC,
       TRUNC(SYSDATE),
       v_CODCONTAJUSTEEST,
       0,
       'AJUSTE DE ESTOQUE VIA INTEGRACAO WMS SAAS',
       0,
       '0',
       DECODE(pTIPO, 'S', pQUANTIDADE * (-1), pQUANTIDADE),
       TRUNC(SYSDATE),
       DECODE(pTIPO, 'S', pQUANTIDADE * (-1), pQUANTIDADE),
       TRUNC(SYSDATE),
       pCODFILIAL,
       'B',
       'O',
       'PCADMIN');

    --Processa Centro de custo.
    PROCESSACENTRODECUSTO(pCODFILIAL,
                          v_CODCONTAJUSTEEST,
                          'FINANCEIRO',
                          v_NUMLANC);

  END EFETUAR_AJUSTE_ESTOQUE;

  PROCEDURE EFETUAR_TROCA_ESTOQUE_AVARIA(pCODFILIAL  IN VARCHAR2,
                                         pCODPROD    IN NUMBER,
                                         pQUANTIDADE IN NUMBER,
                                         pTIPO       IN VARCHAR2,
                                         pNUMLOTE    IN VARCHAR2) IS
    v_NUMTRANSENT          NUMBER(10);
    v_NUMTRANSVENDA        NUMBER(10);
    v_USA_ESTOQUE_POR_LOTE VARCHAR2(2);
    VSRETORNO              VARCHAR2(1000);
    PSMSG_RETORNO          VARCHAR2(6000);
    v_LOTE                 VARCHAR2(15);

  BEGIN

    SELECT PROXNUMTRANSENT, PROXNUMTRANSVENDA
      INTO v_NUMTRANSENT, v_NUMTRANSVENDA
      FROM PCCONSUM
       FOR UPDATE;

    UPDATE PCCONSUM
       SET PROXNUMTRANSENT   = PROXNUMTRANSENT + 1,
           PROXNUMTRANSVENDA = PROXNUMTRANSVENDA + 1;

    SELECT NVL(ESTOQUEPORLOTE, 'N')
      INTO v_USA_ESTOQUE_POR_LOTE
      FROM PCPRODUT
     WHERE CODPROD = pCODPROD;

    v_LOTE := pNUMLOTE;

    IF v_USA_ESTOQUE_POR_LOTE = 'N' THEN
      v_LOTE := NULL;
    END IF;

    IF pTIPO = 'E' THEN

      VSRETORNO := PKG_ESTOQUE.BLOQUEIO_INCLUIR(PNIDENTIFICADOR => v_NUMTRANSENT,
                                                PSCODFILIAL     => pCODFILIAL,
                                                PNCODPROD       => pCODPROD,
                                                PNNUMSEQ        => 0,
                                                PNQTDE          => 0,
                                                PNQTAVARIA      => pQUANTIDADE,
                                                PSOPERACAO      => 'IG',
                                                psCODOPER       => 'EA',
                                                psOBSERVACAO    => 'ENTRADA DE AVARIA',
                                                psNUMLOTE       => v_LOTE,
                                                PSMSG_RETORNO   => PSMSG_RETORNO);

      IF VSRETORNO <> 'S' THEN
        raise_application_error(-20002,
                                'NÃO FOI POSSIVEL INCLUIR BLOQUEIO DE AVARIA');
      END IF;

      UPDATE PCMOVAVARIA
         SET CODFUNCLANC = 1
       WHERE NUMTRANSENT = v_NUMTRANSENT
         AND CODFUNCLANC IS NULL;

    END IF;

    IF pTIPO = 'S' THEN

      VSRETORNO := PKG_ESTOQUE.BLOQUEIO_BAIXAR(PNIDENTIFICADOR => v_NUMTRANSVENDA,
                                               PSCODFILIAL     => pCODFILIAL,
                                               PNCODPROD       => pCODPROD,
                                               PNNUMSEQ        => 0,
                                               PNQTDE          => 0,
                                               PNQTAVARIA      => pQUANTIDADE,
                                               PSOPERACAO      => 'BG',
                                               psCODOPER       => 'SR',
                                               psOBSERVACAO    => 'SAIDA DE AVARIA',
                                               psNUMLOTE       => v_LOTE,
                                               PSMSG_RETORNO   => PSMSG_RETORNO);

      IF VSRETORNO <> 'S' THEN
        raise_application_error(-20002,
                                'NÃO FOI POSSIVEL BAIXAR BLOQUEIO DE AVARIA');
      END IF;

      UPDATE PCMOVAVARIA
         SET CODFUNCLANC = 1
       WHERE NUMTRANSENT = v_NUMTRANSVENDA
         AND CODFUNCLANC IS NULL;

    END IF;

  END EFETUAR_TROCA_ESTOQUE_AVARIA;

  PROCEDURE GERAR_PENDENCIA_MOV_ESTOQUE(pCODFILIAL  IN VARCHAR2,
                                          pCODPROD    IN NUMBER,
                                          pCODOPER    IN VARCHAR2,
                                          pQUANTIDADE IN NUMBER,
                                          pORIGEM     IN VARCHAR2,
                                          pNUMLOTE    IN VARCHAR2,
                                          pVALIDADE   IN VARCHAR2) IS
      vIDENTIFICADOR        NUMBER;
      vCODFILIAL            VARCHAR2(2) := pCODFILIAL;
      vCODPROD              NUMBER := pCODPROD;
      vCODOPER              VARCHAR2(1) := pCODOPER;
      vQT                   NUMBER := pQUANTIDADE;
      vORIGEM               VARCHAR2(50) := pORIGEM;
      vNUMLOTE              VARCHAR2(20) := pNUMLOTE;
      vDATAVALIDADE         DATE;
      vLOTE                 VARCHAR2(15);
      vUSA_ESTOQUE_POR_LOTE VARCHAR2(2);

    BEGIN

      SELECT NVL(ESTOQUEPORLOTE, 'N')
        INTO vUSA_ESTOQUE_POR_LOTE
        FROM PCPRODUT
       WHERE CODPROD = pCODPROD;

      IF vUSA_ESTOQUE_POR_LOTE = 'N' THEN
        vLOTE         := NULL;
        vDATAVALIDADE := NULL;
      END IF;

      IF vUSA_ESTOQUE_POR_LOTE = 'S' THEN
        vLOTE         := pNUMLOTE;

        /*CASO SEJA UMA TROCA DE ESTOQUE O LOTE INFORMADO JÁ DEVE EXISTIR*/
        IF pORIGEM LIKE '%AVARIA%' THEN
          BEGIN
            SELECT DTVALIDADE
              INTO vDATAVALIDADE
              FROM PCLOTE
             WHERE CODFILIAL = pCODFILIAL
               AND CODPROD = pCODPROD
               AND NUMLOTE = pNUMLOTE;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
              raise_application_error(-20002, 'VALIDADE DO LOTE INFORMADO NÃO ENCONTRADA');
          END;
        ELSE
          /*CASO SEJA UM AJUSTE DE ESTOQUE A VALIDADE DEVE SER INFORMADA*/
          IF vDATAVALIDADE = 'VAL_NAO_INFO' THEN
          raise_application_error (-20002,'VALIDADE DO LOTE NÃO INFORMADA' );
          END IF;

          BEGIN
          vDATAVALIDADE := TO_DATE(pVALIDADE, 'yyyymmdd');
      EXCEPTION
          WHEN OTHERS THEN
              raise_application_error(-20002, 'ERRO AO CONVERTER VALIDADE INFORMADA: ' || SQLERRM);
      END;

        END IF;

      END IF;

      IF vCODOPER = 'E' THEN
        SELECT NVL(PROXNUMTRANSENT, 1)
          INTO vIDENTIFICADOR
          FROM PCCONSUM
           FOR UPDATE;

        UPDATE PCCONSUM SET PROXNUMTRANSENT = NVL(PROXNUMTRANSENT, 1) + 1;

      ELSIF vCODOPER = 'S' THEN
        SELECT NVL(PROXNUMTRANSVENDA, 1)
          INTO vIDENTIFICADOR
          FROM PCCONSUM
           FOR UPDATE;

        UPDATE PCCONSUM
           SET PROXNUMTRANSVENDA = NVL(PROXNUMTRANSVENDA, 1) + 1;
      END IF;

      INSERT INTO PCMOVESTOQUEWMSSAAS
        (IDENTIFICADOR,
         CODFILIAL,
         CODPROD,
         CODOPER,
         QT,
         ORIGEM,
         NUMLOTE,
         DATAVALIDADE,
         DATACRIACAO,
         DTCANCEL,
         DTFINALIZACAO)
      VALUES
        (vIDENTIFICADOR,
         vCODFILIAL,
         vCODPROD,
         vCODOPER,
         vQT,
         vORIGEM,
         vLOTE,
         vDATAVALIDADE,
         SYSDATE,
         NULL,
         NULL);

  END GERAR_PENDENCIA_MOV_ESTOQUE;

  FUNCTION GET_VALIDADE_MINIMA_PRODUTO(PNUMPED  IN NUMBER,
                                       PCODPROD IN NUMBER) RETURN VARCHAR2 IS
    v_CODCLI                   NUMBER := 0;
    v_CONTROLA_LOTE            VARCHAR2(1) := 'N';
    v_CONTROLA_VALIDADE        VARCHAR2(1) := 'N';
    v_PRAZO_VALIDADE_DIAS      NUMBER := 0;
    v_PERC_TOLERANCIA_VALIDADE NUMBER := 0;
    v_DATA_MINIMA              DATE;
    v_CODFILIAL                VARCHAR2(2);
    v_CALCULAR_DATA_VAL_MINIMA VARCHAR2(1);
  BEGIN
    BEGIN
      SELECT CODCLI, CODFILIAL
        INTO v_CODCLI, v_CODFILIAL
        FROM PCPEDC
       WHERE NUMPED = PNUMPED;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_CODCLI := 0;
    END;

    BEGIN
      SELECT NVL(PERCTOLVALIDADEPRODWMS, 0)
        INTO v_PERC_TOLERANCIA_VALIDADE
        FROM PCCLIENT
       WHERE CODCLI = v_CODCLI;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_PERC_TOLERANCIA_VALIDADE := 0;
    END;

    BEGIN
      SELECT NVL(ESTOQUEPORLOTE, 'N'),
             NVL(ESTOQUEPORDTVALIDADE, 'N'),
             NVL(PRAZOVAL, 0)
        INTO v_CONTROLA_LOTE, v_CONTROLA_VALIDADE, v_PRAZO_VALIDADE_DIAS
        FROM PCPRODUT
       WHERE CODPROD = PCODPROD;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_CONTROLA_LOTE       := 'N';
        v_CONTROLA_VALIDADE   := 'N';
        v_PRAZO_VALIDADE_DIAS := 0;
    END;

    BEGIN
      SELECT NVL(VALOR, 'N')
        INTO v_CALCULAR_DATA_VAL_MINIMA
        FROM PCPARAMINTEGRACAOWMSSAAS
       WHERE PARAMETRO = 'CALCULAR_DATA_VALIDADE_MINIMA'
         AND CODFILIAL = v_CODFILIAL;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_CALCULAR_DATA_VAL_MINIMA := 'N';
    END;

    IF v_CODCLI > 0 AND v_PRAZO_VALIDADE_DIAS > 0 AND
       v_CALCULAR_DATA_VAL_MINIMA = 'S' AND v_PERC_TOLERANCIA_VALIDADE > 0 AND
       (v_CONTROLA_LOTE = 'S' OR v_CONTROLA_VALIDADE = 'S') THEN

      v_DATA_MINIMA := SYSDATE + (v_PRAZO_VALIDADE_DIAS *
                       (1 - (v_PERC_TOLERANCIA_VALIDADE / 100)));

      RETURN TO_CHAR(v_DATA_MINIMA, 'YYYYMMDD');
    ELSE
      RETURN 'NAO_VALIDA_DATA_VALIDADE';
    END IF;
  END GET_VALIDADE_MINIMA_PRODUTO;

  PROCEDURE GRAVAR_LOG(pPATCH IN VARCHAR2,
                       pTIPO  IN VARCHAR2,
                       pBODY  IN VARCHAR2) IS
  BEGIN
    BEGIN
      INSERT INTO PCLOGINTEGRACOESWMSSAAS
        (DATA, PATCH, TIPO, BODY)
      VALUES
        (SYSDATE, pPATCH, pTIPO, pBODY);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  END GRAVAR_LOG;

  PROCEDURE ENVIARDOCFILAINTEGRACAOITEM(pNUMDOCWMSSAAS IN NUMBER,
                                        pCODPROD       IN NUMBER,
                                        pQTORIG        IN NUMBER,
                                        pQT            IN NUMBER,
                                        pNUMSEQ        IN NUMBER) IS

    vBODY                  VARCHAR2(500);
    vIDENTIFCADOR_OPERACAO VARCHAR2(30);

  BEGIN

    BEGIN
      INSERT INTO PCINTEGRACAOWMSSAASITEM
        (NUMDOCWMSSAAS, CODPROD, QTORIG, QT, NUMSEQ)
      VALUES
        (pNUMDOCWMSSAAS, pCODPROD, pQTORIG, pQT, pNUMSEQ);
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        vIDENTIFCADOR_OPERACAO := TO_CHAR(SYSTIMESTAMP,
                                          'yyyymmddhh24missff3');

        vBODY := 'Identificador: ' || vIDENTIFCADOR_OPERACAO ||
                 'Documento WMS Saas: ' || TO_CHAR(pNUMDOCWMSSAAS) ||
                 ',Item: ' || TO_CHAR(pCODPROD);

        GRAVAR_LOG('PKG_INTEGRACAOWMSSAAS.ENVIARDOCFILAINTEGRACAOITEM',
                   'ERRO_DUPLICIDADE_INSERCAO_PCINTEGRACAOWMSSAASITEM',
                   vBODY ||
                   ', Descrição: Falha na inserção na PCINTEGRACAOWMSSAASITEM por violação da UK');
    END;

  END ENVIARDOCFILAINTEGRACAOITEM;

  PROCEDURE CANCELAR_SEPARACAO_PEDIDO(pNUMDOCWMSSAAS IN NUMBER) IS

      vTIPOGERACAODOC             VARCHAR2(20);
      vNUMPED                     NUMBER;
      vQTRESERVADA                NUMBER;
      vPOSICAO                    VARCHAR2(2);
      vEXISTE_PENDENCIA_SEPARACAO VARCHAR2(2);
      vDTCANCEL DATE;

    PROCEDURE CANCELAR_SEPARACAO_PCPEDI IS
    BEGIN
      UPDATE PCPEDI
           SET QTSEPARADA   = NULL,
               DTINICIALSEP = NULL,
               DTFINALSEP   = NULL,
               QTAPANHA     = NULL,
               DATACONF     = NULL,
               DATACONFFIM  = NULL,
               CODFUNCSEP   = NULL,
               CODFUNCCONF  = NULL,
               NUMLOTE      = NULL
         WHERE NUMPED = vNUMPED;
    END;

    PROCEDURE CANCELAR_SEPARACAO_PCPEDC IS
    BEGIN
      UPDATE PCPEDC
             SET DTINICIALSEP      = NULL,
                 DTFINALSEP        = NULL,
                 DTINICIALCHECKOUT = NULL,
                 DTFINALCHECKOUT   = NULL,
                 CODFUNCSEP        = NULL,
                 CODFUNCCONF       = NULL,
                 NUMVOLUME         = NULL
           WHERE NUMPED = vNUMPED;
    END;

    PROCEDURE CANCELAR_SEP_INTEGRACAO_ITEM IS
    BEGIN
      UPDATE PCINTEGRACAOWMSSAASITEM
           SET QTSEPARADA = NULL, NUMLOTE = NULL, DTVALIDADE = NULL
         WHERE NUMDOCWMSSAAS = pNUMDOCWMSSAAS;
    END;

    PROCEDURE CANCELAR_SEP_INTEGRACAO IS
    BEGIN
      UPDATE PCINTEGRACAOWMSSAAS
             SET DTFIMSEPARACAO = NULL, TOTVOLUME = NULL
           WHERE NUMDOCWMSSAAS = pNUMDOCWMSSAAS;
    END;

    /*INICIO DE EXECUÇÃO DA PROCEDURE*/
    BEGIN

      BEGIN
        SELECT TIPOGERACAODOC, NUMDOCWINTHOR
          INTO vTIPOGERACAODOC, vNUMPED
          FROM PCINTEGRACAOWMSSAAS
         WHERE NUMDOCWMSSAAS = pNUMDOCWMSSAAS;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE_APPLICATION_ERROR(-20001, 'PEDIDO NÃO ENCONTRADO NO WINTHOR - PCINTEGRACAOWMSSAAS');
      END;

      BEGIN
        SELECT POSICAO, DTCANCEL
         INTO vPOSICAO, vDTCANCEL
        FROM PCPEDC WHERE NUMPED = vNUMPED;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE_APPLICATION_ERROR(-20001, 'PEDIDO NÃO ENCONTRADO NO WINTHOR - PCPEDC');
      END;

      IF vPOSICAO = 'F' THEN
        RAISE_APPLICATION_ERROR(-20001, 'PEDIDO JÁ FATURADO!');
      END IF;

      IF vDTCANCEL IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'PEDIDO JÁ CANCELADO!');
      END IF;

      /* 1 - FLUXO PADRÃO, QUANDO O PEDIDO DO ERP NÃO FOI SEGREGADO EM DOIS (CAIXA E FRACIONADO) AO ENVIAR PARA O WMS SAAS*/
      IF vTIPOGERACAODOC = 'COMPLETO' THEN

        /*BUSCAR LOTES PARA RETIRAR RESERVAS DOS LOTES DA SEPARAÇÃO QUE VAI SER CANCELADA*/
        FOR REG_PED_ITEM IN (SELECT C.CODFILIAL,
                                    I.CODPROD,
                                    I.NUMLOTE,
                                    I.QTSEPARADA,
                                    NVL(P.ESTOQUEPORLOTE, 'N') AS ESTOQUEPORLOTE
                               FROM PCPEDI I, PCPEDC C, PCPRODUT P
                              WHERE C.NUMPED = I.NUMPED
                                AND P.CODPROD = I.CODPROD
                                AND C.DTFINALSEP IS NOT NULL
                                AND C.NUMPED = vNUMPED)

         LOOP
          /* INICIO LAÇO REG_PED_ITEM*/
          /*RETIRAR RESERVA DO LOTES*/
          IF REG_PED_ITEM.ESTOQUEPORLOTE = 'S' THEN
            BEGIN
              SELECT NVL(QTRESERV, 0)
                INTO vQTRESERVADA
                FROM PCLOTE
               WHERE CODFILIAL = REG_PED_ITEM.CODFILIAL
                 AND CODPROD = REG_PED_ITEM.CODPROD
                 AND NUMLOTE = REG_PED_ITEM.NUMLOTE;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20001,
                                        'Lote ' || REG_PED_ITEM.NUMLOTE ||
                                        ' não encontrado para o produto ' || REG_PED_ITEM.CODPROD ||
                                        ' na filial ' || REG_PED_ITEM.CODFILIAL);
            END;

            /*ATUALIZAÇÃO DA QUANTIDADE RESERVADA DO LOTE*/
            IF vQTRESERVADA < REG_PED_ITEM.QTSEPARADA THEN
              RAISE_APPLICATION_ERROR(-20001,
                                      'Não foi possível remover a reserva. Produto: ' || REG_PED_ITEM.CODPROD ||
                                      ', Lote: ' || REG_PED_ITEM.NUMLOTE ||
                                      ', Filial: ' || REG_PED_ITEM.CODFILIAL ||
                                      '. Reservado atual: ' || vQTRESERVADA ||
                                      ', Quantidade a remover: ' || REG_PED_ITEM.QTSEPARADA);
            ELSE
              UPDATE PCLOTE
                 SET QTRESERV = QTRESERV - REG_PED_ITEM.QTSEPARADA
               WHERE CODFILIAL = REG_PED_ITEM.CODFILIAL
                 AND CODPROD = REG_PED_ITEM.CODPROD
                 AND NUMLOTE = REG_PED_ITEM.NUMLOTE;
            END IF;

          END IF;

        /* FINAL LAÇO REG_PED_ITEM*/
        END LOOP;

        /*RETIRAR QUANTIDADE SEPARADA DOS ITENS DO PEDIDO*/
        CANCELAR_SEPARACAO_PCPEDI;

        /*ELIMINANDO POSSIVEIS LINHAS DUPLICADAS DO PRODUTO PROVENIENTES DE DESDOBRAMENTOS ANTERIORES - PCPEDI*/
        DELETE FROM PCPEDI I
         WHERE I.ROWID NOT IN (SELECT MIN(J.ROWID)
                                 FROM PCPEDI J
                                WHERE J.NUMPED = vNUMPED
                                GROUP BY J.CODPROD)
           AND I.NUMPED = vNUMPED;

        /*CANCELAR FINALIZAÇÃO DA SEPARAÇÃO DOS ITENS DO PEDIDO WMS SAAS (PCINTEGRACAOWMSSAAS) */
        CANCELAR_SEP_INTEGRACAO_ITEM;

        /*ELIMINANDO POSSIVEIS LINHAS DUPLICADAS DO PRODUTO PROVENIENTES DE DESDOBRAMENTOS ANTERIORES - PCINTEGRACAOWMSSAASITEM*/
        DELETE FROM PCINTEGRACAOWMSSAASITEM I
         WHERE I.ROWID NOT IN (SELECT MIN(J.ROWID)
                                 FROM PCINTEGRACAOWMSSAASITEM J
                                WHERE J.NUMDOCWMSSAAS = pNUMDOCWMSSAAS
                                GROUP BY J.CODPROD)
           AND I.NUMDOCWMSSAAS = pNUMDOCWMSSAAS;

        /*CANCELAR FINALIZAÇÃO DA SEPARAÇÃO DO CABEÇALHO DO PEDIDO NO ERP*/
        CANCELAR_SEPARACAO_PCPEDC;

        /*CANCELAR FINALIZAÇÃO DA SEPARAÇÃO DO CABEÇALHO DO PEDIDO WMS SAAS (PCINTEGRACAOWMSSAAS) */
        CANCELAR_SEP_INTEGRACAO;

      ELSE
        /*2 - FLUXO DE DOCUMENTO SEGREGADO ENTRE CAIXA E FRACIONADO, NESSE CASO O PEDIDO ORIGINAL DO ERP (PCPEDC) FOI DIVIDIDO EM DOIS (PCINTEGRACAOWMSSAAS)
        E ESSES DOCUMENTOS SEGREGADOS ENTRE CAIXA E FRACIONADO E QUE FORAM ENVIADOS PARA O WMS SAAS*/

        /*VERIFICANDO SE OS DOIS DOCUMENTOS (CAIXA/FRACIONADO) JÁ TIVERAM SEPARAÇÃO FINALIZADA, SE NÃO HOUVER BASTA RETIRAR A SEPARAÇÃO DA TABELA INTERMEDIARIA PCINTEGRACAOWMSSAAS
        POIS A ATUALIZAÇÃO NA TABELA DO ERP PCPEDI SOMENTE E FEITA QUANDO TODOS OS DOCUMENTOS SEGREGADOS ASSOCIADOS A ESSE PEDIDO SÃO SEPARADOS*/
        SELECT DECODE(COUNT(1), 0, 'N', 'S')
          INTO vEXISTE_PENDENCIA_SEPARACAO
          FROM PCINTEGRACAOWMSSAAS
         WHERE DTFIMSEPARACAO IS NULL
           AND NUMDOCWINTHOR = vNUMPED;

        IF vEXISTE_PENDENCIA_SEPARACAO = 'S' THEN
          /*CANCELAR FINALIZAÇÃO DA SEPARAÇÃO DO CABEÇALHO DO PEDIDO WMS SAAS (PCINTEGRACAOWMSSAAS) */
          CANCELAR_SEP_INTEGRACAO;

          /*CANCELAR FINALIZAÇÃO DA SEPARAÇÃO DOS ITENS DO PEDIDO WMS SAAS (PCINTEGRACAOWMSSAAS) */
          CANCELAR_SEP_INTEGRACAO_ITEM;

          /*ELIMINANDO POSSIVEIS LINHAS DUPLICADAS DO PRODUTO PROVENIENTES DE DESDOBRAMENTOS ANTERIORES - PCINTEGRACAOWMSSAASITEM*/
          DELETE FROM PCINTEGRACAOWMSSAASITEM I
           WHERE I.ROWID NOT IN (SELECT MIN(J.ROWID)
                                   FROM PCINTEGRACAOWMSSAASITEM J
                                  WHERE J.NUMDOCWMSSAAS = pNUMDOCWMSSAAS
                                  GROUP BY J.CODPROD)
             AND I.NUMDOCWMSSAAS = pNUMDOCWMSSAAS;

        ELSE
          /*NESSE CENARIO TODOS OS DOCUMENTOS SEGREGADOS JÁ TIVERAM SUA SEPARAÇÃO FINALIZADAS, PORTANTO SE DEVE DEDUZIR A QUANTIDADE SEPARADA NO PEDIDO DO ERP
          E LIMPAR A QUANTIDADE SEPARADA DAQUELE DOCUMENTO NA TABELA INTERMEDIARIA DE INTEGRAÇÃO */

          FOR REG_DOC_WMS_SAAS IN (SELECT ROWID,
                                          CODPROD,
                                          NUMLOTE,
                                          NVL(QTSEPARADA, 0) AS QTSEPARADA
                                     FROM PCINTEGRACAOWMSSAASITEM
                                    WHERE NUMDOCWMSSAAS = pNUMDOCWMSSAAS)

           LOOP
            /*CANCELAR FINALIZAÇÃO DA SEPARAÇÃO DOS ITENS DO PEDIDO WMS SAAS (PCINTEGRACAOWMSSAAS) */
            UPDATE PCINTEGRACAOWMSSAASITEM
               SET QTSEPARADA = NULL, NUMLOTE = NULL, DTVALIDADE = NULL
             WHERE ROWID = REG_DOC_WMS_SAAS.ROWID;

            /*DEDUZINDO QUANTIDADE SEPARADA DO DOCUMENTO COM SEPARAÇÃO CANCELADA*/
            UPDATE PCPEDI
               SET QTSEPARADA = NVL(QTSEPARADA, 0) -
                                REG_DOC_WMS_SAAS.QTSEPARADA
             WHERE NUMPED = vNUMPED
               AND CODPROD = REG_DOC_WMS_SAAS.CODPROD
               AND NVL(NUMLOTE, 1) = NVL(REG_DOC_WMS_SAAS.NUMLOTE, 1);

            /*RETIRANDO DUPLICIDADE E POSSIVEL LINHA ZERADA EXTRA, APÓS A DEDUÇÃO DA QUANTIDADE SEPARADA*/
            DELETE PCPEDI
             WHERE NUMPED = vNUMPED
               AND CODPROD = REG_DOC_WMS_SAAS.CODPROD
               AND NVL(NUMLOTE, 1) = NVL(REG_DOC_WMS_SAAS.NUMLOTE, 1)
               AND NVL(QTSEPARADA, 0) = 0
               AND EXISTS
             (SELECT 1
                      FROM PCPEDI
                     WHERE NUMPED = vNUMPED
                       AND CODPROD = REG_DOC_WMS_SAAS.CODPROD
                       AND NVL(NUMLOTE, 1) = NVL(REG_DOC_WMS_SAAS.NUMLOTE, 1)
                       AND NVL(QTSEPARADA, 0) > 0);

          END LOOP;

          /*CANCELAR FINALIZAÇÃO DA SEPARAÇÃO DO CABEÇALHO DO PEDIDO WMS SAAS (PCINTEGRACAOWMSSAAS) */
          CANCELAR_SEP_INTEGRACAO;

          /*CANCELAR FINALIZAÇÃO DA SEPARAÇÃO DO CABEÇALHO DO PEDIDO NO ERP*/
          CANCELAR_SEPARACAO_PCPEDC;

        END IF;

      END IF;

    END CANCELAR_SEPARACAO_PEDIDO;

    FUNCTION HORARIO_VALIDO_PARA_INTEGRACAO(pCODFILIAL  IN VARCHAR2) RETURN VARCHAR2 IS
        v_HORARIO_INICIAL          NUMBER := 0;
        v_HORARIO_FINAL            NUMBER := 0;
        v_HORARIO_ATUAL            NUMBER := 0;
        v_CODFILIAL                VARCHAR2(2);
      BEGIN

        BEGIN
          SELECT TO_NUMBER(TO_CHAR(SYSDATE, 'HH24')) AS hora_atual
          INTO v_HORARIO_ATUAL
          FROM DUAL;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_HORARIO_ATUAL := 0;
        END;


        BEGIN
          SELECT TO_NUMBER(VALOR)
          INTO v_HORARIO_INICIAL
          FROM PCPARAMINTEGRACAOWMSSAAS
          WHERE PARAMETRO = 'HORA_INICIAL_PERIODO_INTEGRACAO'
          AND CODFILIAL = pCODFILIAL;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_HORARIO_INICIAL := 0;
        END;


        BEGIN
          SELECT TO_NUMBER(VALOR)
          INTO v_HORARIO_FINAL
          FROM PCPARAMINTEGRACAOWMSSAAS
          WHERE PARAMETRO = 'HORA_FINAL_PERIODO_INTEGRACAO'
          AND CODFILIAL = pCODFILIAL;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_HORARIO_FINAL := 23;
        END;


        IF (v_HORARIO_ATUAL >= v_HORARIO_INICIAL) AND (v_HORARIO_ATUAL <= v_HORARIO_FINAL) THEN
        RETURN 'S';
        ELSE
        RETURN 'N';
        END IF;

      END HORARIO_VALIDO_PARA_INTEGRACAO;

END PKG_INTEGRACAOWMSSAAS;