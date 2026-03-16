CREATE OR REPLACE PACKAGE BODY PKG_INTEGRACAOWMSSAAS IS

  PROCEDURE INTEGRARDOCMANUALMENTEWMSSAAS(pCODFILIAL      IN VARCHAR2,
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
      RETURN;
    END IF;

    IF (pTIPODOCWINTHOR = 'PEDIDO_VENDA') AND (v_COUNT = 0) THEN
      GRAVAR_LOG('PKG_INTEGRACAOWMSSAAS.INTEGRARDOCMANUALMENTEWMSSAAS',
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
          /***INSERIR ITEM NA TABELA DE GESTÃO DE INTEGRAÇÃO MANUAL***/
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

          GRAVAR_LOG('PKG_INTEGRACAOWMSSAAS.INTEGRARDOCMANUALMENTEWMSSAAS',
                     'INSERT_PCINTEGRACAOWMSSAASITEM',
                     vBODY ||
                     ', Descrição: Inserção do item na tabela PCINTEGRACAOWMSSAASITEM');



      END LOOP;

      --GERAR CABECHALO DOS DOCUMETOS (COMPLETO)

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

        GRAVAR_LOG('PKG_INTEGRACAOWMSSAAS.INTEGRARDOCMANUALMENTEWMSSAAS',
                   'INSERT_PCINTEGRACAOWMSSAAS',
                   vBODY ||
                   ', Descrição: Inserção do documento na tabela PCINTEGRACAOWMSSAAS');

      END IF;


    END IF;
  END INTEGRARDOCMANUALMENTEWMSSAAS;

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

  /***METODO FINALIZARSEPARACAOITEMFILA DEPRECIADO***/
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
      vLOTE := pNUMLOTE;

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
            raise_application_error(-20002,
                                    'VALIDADE DO LOTE INFORMADO NÃO ENCONTRADA');
        END;
      ELSE
        /*CASO SEJA UM AJUSTE DE ESTOQUE A VALIDADE DEVE SER INFORMADA*/
        IF vDATAVALIDADE = 'VAL_NAO_INFO' THEN
          raise_application_error(-20002, 'VALIDADE DO LOTE NÃO INFORMADA');
        END IF;

        BEGIN
          vDATAVALIDADE := TO_DATE(pVALIDADE, 'yyyymmdd');
        EXCEPTION
          WHEN OTHERS THEN
            raise_application_error(-20002,
                                    'ERRO AO CONVERTER VALIDADE INFORMADA: ' ||
                                    SQLERRM);
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

  PROCEDURE CANCELAR_SEPARACAO_PEDIDO(pNUMPED IN NUMBER) IS

    vTIPOGERACAODOC             VARCHAR2(20);
    vNUMPED                     NUMBER;
    vQTRESERVADA                NUMBER;
    vPOSICAO                    VARCHAR2(2);
    vEXISTE_PENDENCIA_SEPARACAO VARCHAR2(2);
    vDTCANCEL                   DATE;

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

    /****INICIO DO CANCELAMENTO DA SEPARACAO PEDIDO***/
  BEGIN

    BEGIN
      SELECT POSICAO, DTCANCEL, NUMPED
        INTO vPOSICAO, vDTCANCEL, vNUMPED
        FROM PCPEDC
       WHERE NUMPED = pNUMPED;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vPOSICAO := 'F';
        vNUMPED  := 0;
    END;

    IF vNUMPED = 0 THEN
      RETURN;
    END IF;


    IF vDTCANCEL IS NOT NULL THEN
      RETURN;
    END IF;

    /*SE O PEDIDO JÁ ESTÁ FATURADO ENTÃO NÃO PODE ESTORNAR AS RESERVAS, DEVE APENAS LIMPAR A QUANTIDADE SEPARADA PELO WMS*/
    IF vPOSICAO = 'F' THEN
      CANCELAR_SEPARACAO_PCPEDI;
      CANCELAR_SEPARACAO_PCPEDC;
      RETURN;
    END IF;

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
                                    ' não encontrado para o produto ' ||
                                    REG_PED_ITEM.CODPROD || ' na filial ' ||
                                    REG_PED_ITEM.CODFILIAL);
        END;

        /*ATUALIZAÇÃO DA QUANTIDADE RESERVADA DO LOTE*/
        IF vQTRESERVADA < REG_PED_ITEM.QTSEPARADA THEN
          RAISE_APPLICATION_ERROR(-20001,
                                  'Não foi possível remover a reserva. Produto: ' ||
                                  REG_PED_ITEM.CODPROD || ', Lote: ' ||
                                  REG_PED_ITEM.NUMLOTE || ', Filial: ' ||
                                  REG_PED_ITEM.CODFILIAL ||
                                  '. Reservado atual: ' || vQTRESERVADA ||
                                  ', Quantidade a remover: ' ||
                                  REG_PED_ITEM.QTSEPARADA);
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

    /*CANCELAR FINALIZAÇÃO DA SEPARAÇÃO DO CABEÇALHO DO PEDIDO NO ERP*/
    CANCELAR_SEPARACAO_PCPEDC;

  END CANCELAR_SEPARACAO_PEDIDO;

  FUNCTION HORARIO_VALIDO_PARA_INTEGRACAO(pCODFILIAL IN VARCHAR2)
    RETURN VARCHAR2 IS
    v_HORARIO_INICIAL NUMBER := 0;
    v_HORARIO_FINAL   NUMBER := 0;
    v_HORARIO_ATUAL   NUMBER := 0;
    v_CODFILIAL       VARCHAR2(2);
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

    IF (v_HORARIO_ATUAL >= v_HORARIO_INICIAL) AND
       (v_HORARIO_ATUAL <= v_HORARIO_FINAL) THEN
      RETURN 'S';
    ELSE
      RETURN 'N';
    END IF;

  END HORARIO_VALIDO_PARA_INTEGRACAO;

  PROCEDURE EFETUAR_MOV_POR_TIPO_ESTOQUE(pCODFILIAL            IN VARCHAR2,
                                         pCODPROD              IN NUMBER,
                                         pQUANTIDADE           IN NUMBER,
                                         pNUMLOTE              IN VARCHAR2,
                                         pTIPO_ESTOQUE_ORIGEM  IN VARCHAR2,
                                         pTIPO_ESTOQUE_DESTINO IN VARCHAR2) IS
    vNUMTRANSENT  NUMBER(10);
    VSRETORNO     VARCHAR2(60);
    PSMSG_RETORNO VARCHAR2(6000);

    vTIPO_ESTOQUE_ORIGEM_BLOQUEIO  VARCHAR2(1);
    vTIPO_ESTOQUE_DESTINO_BLOQUEIO VARCHAR2(1);

  BEGIN

    SELECT DECODE(COUNT(1), 0, 'N', 'S')
      INTO vTIPO_ESTOQUE_ORIGEM_BLOQUEIO
      FROM PCMAPEAMENTOTIPOESTOQUEWMSSAAS
     WHERE CODFILIAL = pCODFILIAL
       AND TIPOESTOQUE = pTIPO_ESTOQUE_ORIGEM;

    SELECT DECODE(COUNT(1), 0, 'N', 'S')
      INTO vTIPO_ESTOQUE_DESTINO_BLOQUEIO
      FROM PCMAPEAMENTOTIPOESTOQUEWMSSAAS
     WHERE CODFILIAL = pCODFILIAL
       AND TIPOESTOQUE = pTIPO_ESTOQUE_DESTINO;

    /**SE A TROCA DO TIPO DE ESTOQUE FOR DE NORMAL PARA UM ESTOQUE MAPEADO NA PCMAPEAMENTOTIPOESTOQUEWMSSAAS PARA BLOQUEIO, ENTÃO EFETUAR BLOQUEIO**/
    IF vTIPO_ESTOQUE_ORIGEM_BLOQUEIO = 'N' AND
       vTIPO_ESTOQUE_DESTINO_BLOQUEIO = 'S' THEN

      VSRETORNO := PKG_ESTOQUE.BLOQUEIO_INCLUIR(PNIDENTIFICADOR => 0,
                                                PSCODFILIAL     => pCODFILIAL,
                                                PNCODPROD       => pCODPROD,
                                                PNNUMSEQ        => 0,
                                                PNQTDE          => pQUANTIDADE,
                                                PNQTAVARIA      => 0,
                                                PSOPERACAO      => 'IU',
                                                psCODOPER       => 'IG',
                                                psOBSERVACAO    => 'BLOQUEIO DE ESTOQUE',
                                                psNUMLOTE       => pNUMLOTE,
                                                PSMSG_RETORNO   => PSMSG_RETORNO);

      IF VSRETORNO <> 'S' THEN
        raise_application_error(-20002,
                                'Não foi possível efetuar bloqueio');
      END IF;

    END IF;

    /**SE A TROCA DO TIPO DE ESTOQUE FOR DE UM ESTOQUE MAPEADO NA PCMAPEAMENTOTIPOESTOQUEWMSSAAS PARA BLOQUEIO, PARA UM TIPO DE ESTOQUE NÃO MAPEADO PARA BLOQUEIO, ENTÃO DESBLOQUEAR**/
    IF vTIPO_ESTOQUE_ORIGEM_BLOQUEIO = 'S' AND
       vTIPO_ESTOQUE_DESTINO_BLOQUEIO = 'N' THEN

      VSRETORNO := PKG_ESTOQUE.BLOQUEIO_BAIXAR(PNIDENTIFICADOR => 0,
                                               PSCODFILIAL     => pCODFILIAL,
                                               PNCODPROD       => pCODPROD,
                                               PNNUMSEQ        => 0,
                                               PNQTDE          => pQUANTIDADE,
                                               PNQTAVARIA      => 0,
                                               PSOPERACAO      => 'BU',
                                               psCODOPER       => 'BG',
                                               psOBSERVACAO    => 'DESBLOQUEIO DE ESTOQUE',
                                               psNUMLOTE       => pNUMLOTE,
                                               PSMSG_RETORNO   => PSMSG_RETORNO);

      IF VSRETORNO <> 'S' THEN
        raise_application_error(-20002,
                                'Não foi possível efetuar desbloqueio');
      END IF;

    END IF;

  END EFETUAR_MOV_POR_TIPO_ESTOQUE;

  PROCEDURE FINALIZARSEPARACAOPEDIDO(pCODFILIAL IN VARCHAR2,
                                     pNUMPED    IN NUMBER,
                                     pVOLUME    IN NUMBER) IS

    vSEPARACAO_DIVERGENTE         VARCHAR2(1);
    vBODY                         VARCHAR2(500);
    vPEDIDO_FAT VARCHAR2(1);

  BEGIN

    SELECT DECODE(COUNT(1), 0, 'N', 'S')
      INTO vPEDIDO_FAT
      FROM PCPEDC
     WHERE NUMPED = pNUMPED
       AND POSICAO = 'F';


    SELECT DECODE(COUNT(1), 0, 'N', 'S') SEPARACAO_DIVERGENTE
      INTO vSEPARACAO_DIVERGENTE
      FROM PCPEDI
     WHERE NUMPED = pNUMPED
       AND NVL(QT, 0) <> NVL(QTSEPARADA, 0);

    UPDATE PCPEDC
       SET DTINICIALSEP      = TRUNC(SYSDATE),
           DTFINALSEP        = TRUNC(SYSDATE),
           DTINICIALCHECKOUT = TRUNC(SYSDATE),
           DTFINALCHECKOUT   = TRUNC(SYSDATE),
           CODFUNCSEP        = 1,
           CODFUNCCONF       = 1,
           NUMVOLUME         = pVOLUME
     WHERE NUMPED = pNUMPED;

    /***SE O EDIDO JÁ ESTÁ FATURADO ENTÃO NÃO TEM CORTE****/
    IF vPEDIDO_FAT = 'S' THEN
      RETURN;
    END IF;

    /***ATUALIZAR PEDIDO COM QUANTIDADES SEPARADAS (CORTE OU ACRESCIMO), CASO HAJA QUANTIDADES DIVERGENTES DO PEDIDO ORIGINAL ****/
    IF vSEPARACAO_DIVERGENTE = 'S' THEN

      /***ATUALIZANDO ITEMS***/
      PROCESSAR_CORTE(pCODFILIAL, pNUMPED);

    END IF;

  END FINALIZARSEPARACAOPEDIDO;

  PROCEDURE PROCESSAR_CORTE(pCODFILIAL IN VARCHAR2, pNUMPED IN NUMBER) IS

    vVLDESCONTO   NUMBER := 0;
    vVLOUTRASDESP NUMBER := 0;
    vVLFRETE      NUMBER := 0;
    vCONDVENDA    NUMBER := 0;

    vVLATEND_AGG  NUMBER := 0;
    vVLTOTAL_AGG  NUMBER := 0;
    vVLTABELA_AGG NUMBER := 0;
    vVLCUSTOFIN   NUMBER := 0;
    vVLCUSTOREAL  NUMBER := 0;
    vVLCUSTOREP   NUMBER := 0;
    vVLCUSTOCONT  NUMBER := 0;
    vNUMITENS     NUMBER := 0;
    vTOTPESO      NUMBER := 0;
    vTOTVOLUME    NUMBER := 0;

    vVlTotal  NUMBER := 0;
    vVlAtend  NUMBER := 0;
    vVlTabela NUMBER := 0;

    v_COUNT          NUMBER := 0;
    vNUMCAR          NUMBER := 0;
    vNUMPED          NUMBER := 0;
    vCODCLI          NUMBER := 0;
    vPOSICAO         VARCHAR2(1);
    vTIPODIVERGENCIA VARCHAR2(20);
    vsMSGCCRCA       VARCHAR2(2000);
    vbgerousaldorca  BOOLEAN;

  BEGIN

    BEGIN
      SELECT NVL(NUMCAR, 0),
             NVL(NUMPED, 0),
             NVL(CODCLI, 0),
             CONDVENDA,
             POSICAO
        INTO vNUMCAR, vNUMPED, vCODCLI, vCONDVENDA, vPOSICAO
        FROM PCPEDC
       WHERE NUMPED = pNUMPED;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vNUMCAR    := 0;
        vNUMPED    := 0;
        vCODCLI    := 0;
        vCONDVENDA := 0;
        vPOSICAO   := 'X';
    END;

    /***ARMAZENANDO QUANTIDADES ORIGINAIS DO PEDIDO***/
    UPDATE PCPEDI SET QTORIG = QT WHERE NUMPED = pNUMPED;

    /***ATUALIZANDO ITEMS (PCPEDI)***/
    FOR REG IN (SELECT ROWID,
                       NUMPED,
                       CODPROD,
                       NVL(QTORIG, 0) AS QTORIG,
                       NVL(QT, 0) AS QT,
                       NVL(QTSEPARADA, 0) AS QTSEPARADA,
                       NUMSEQ,
                       NVL(CODFILIALRETIRA, pCODFILIAL) CODFILIAL,
                       PTABELA,
                       PBASERCA,
                       CODAUXILIAR
                  FROM PCPEDI
                 WHERE NVL(QT, 0) <> NVL(QTSEPARADA, 0)
                   AND NUMPED = pNUMPED) LOOP
      UPDATE PCPEDI
         SET QT = QTSEPARADA, QTAPANHA = QTSEPARADA
       WHERE NUMPED = REG.NUMPED
         AND NUMSEQ = REG.NUMSEQ
         AND CODPROD = REG.CODPROD
         AND ROWID = REG.ROWID;

      /***GERA TABELAS PCCORTE E PCCORTEI***/
      IF REG.QTSEPARADA < REG.QT THEN

        /***GERA PCCORTE**/
        IF vNUMCAR > 0 THEN
          UPDATE pccorte
             SET qtseparada = REG.QTSEPARADA,
                 qtcortada  = (REG.QT - REG.QTSEPARADA),
                 DATA       = TRUNC(SYSDATE),
                 hora       = TO_NUMBER(TO_CHAR(SYSDATE, 'HH24')),
                 minuto     = TO_NUMBER(TO_CHAR(SYSDATE, 'MI')),
                 codfunc    = 1,
                 numped     = REG.NUMPED,
                 codrotina  = 1402,
                 codcli     = vCODCLI,
                 condvenda  = vCONDVENDA
           WHERE codprod = REG.CODPROD
             AND numcar = vNUMCAR;

          v_COUNT := SQL%ROWCOUNT;

          IF v_COUNT = 0 THEN

            INSERT INTO PCCORTE
              (data,
               qtseparada,
               qtcortada,
               codfunc,
               numped,
               codrotina,
               codcli,
               condvenda,
               numcar,
               codprod)
            VALUES
              (sysdate,
               REG.QTSEPARADA,
               (REG.QT - REG.QTSEPARADA),
               1,
               REG.NUMPED,
               1402,
               vCODCLI,
               vCONDVENDA,
               vNUMCAR,
               REG.CODPROD);

          END IF;

        END IF;

        /***GERA PCCORTEI**/
        IF vNUMPED > 0 THEN

          UPDATE pccortei
             SET qtseparada = REG.QTSEPARADA,
                 qtcortada  = (REG.QT - REG.QTSEPARADA),
                 DATA       = TRUNC(SYSDATE),
                 hora       = TO_NUMBER(TO_CHAR(SYSDATE, 'HH24')),
                 minuto     = TO_NUMBER(TO_CHAR(SYSDATE, 'MI')),
                 codfunc    = 1,
                 numped     = REG.NUMPED,
                 codrotina  = 1402,
                 codcli     = vCODCLI,
                 condvenda  = vCONDVENDA
           WHERE codprod = REG.CODPROD
             AND numped = REG.NUMPED
             AND NUMSEQ = REG.NUMSEQ;

          IF v_COUNT = 0 THEN

            INSERT INTO PCCORTEI
              (codprod,
               qtseparada,
               qtcortada,
               NUMSEQ,
               DATA,
               hora,
               minuto,
               numcar,
               codfunc,
               numped,
               pvenda,
               codfilial,
               codrotina,
               codcli,
               condvenda,
               motivo)
            VALUES
              (REG.CODPROD,
               REG.QTSEPARADA,
               (REG.QT - REG.QTSEPARADA),
               REG.NUMSEQ,
               SYSDATE,
               TO_NUMBER(TO_CHAR(SYSDATE, 'HH24')),
               TO_NUMBER(TO_CHAR(SYSDATE, 'MI')),
               vNUMCAR,
               1,
               REG.NUMPED,
               NVL((select max(pvenda)
                     from pcpedi
                    where numped = REG.NUMPED
                      and codprod = REG.CODPROD),
                   0),
               pCODFILIAL,
               1402,
               vCODCLI,
               vCONDVENDA,
               'Corte no WMS Saas');

          END IF;

        END IF;

      END IF;

      IF PC_PKG_CONTROLARSALDORCA.CONTROLASALDORCA(REG.NUMPED, vsMSGCCRCA) = 'S' THEN
        vbgerousaldorca := pc_pkg_controlarsaldorca.ccrca_alterar_preco_qt(1,
                                                                           1401,
                                                                           1,
                                                                           REG.NUMPED,
                                                                           REG.CODPROD,
                                                                           REG.NUMSEQ,
                                                                           REG.QTORIG);
      END IF;

      /***IMPLEMNETAR FLUXO DE CANCELAMENTO PCNFCAN NO CORTE TOTAL DO ITEM****/
      IF REG.QTSEPARADA = 0 THEN

        INSERT INTO PCNFCANITEM
          (NUMPED,
           CODROTINA,
           MOTIVO,
           CODCLI,
           CodProd,
           PVENDA,
           PTABELA,
           NUMSEQ,
           DATACANC,
           CODFUNCCANC,
           DATAEMISSAO,
           CODFUNCEMITE,
           CODUSUR,
           NUMCAR,
           QT,
           PBASERCA,
           HORACANC,
           CODAUXILIAR)
        VALUES
          (REG.NUMPED,
           1700,
           'CANCELAMENTO AUTOMATICO POR MOTIVO DE CORTE TOTAL',
           vCODCLI,
           REG.CODPROD,
           NVL((select max(pvenda)
                 from pcpedi
                where numped = REG.NUMPED
                  and codprod = REG.CODPROD),
               0),
           REG.PTABELA,
           REG.NUMSEQ,
           TRUNC(SYSDATE),
           1,
           TRUNC(SYSDATE),
           1,
           1,
           vNUMCAR,
           REG.QT,
           REG.PBASERCA,
           SYSDATE,
           REG.CODAUXILIAR);

        DELETE PCPEDI
         WHERE ROWID = REG.ROWID
           AND CODPROD = REG.CODPROD
           AND NVL(QTSEPARADA, 0) = 0;
      END IF;

    END LOOP;

    /***ATUALIZANDO CABECALHO (PCPEDC)***/

    BEGIN
      SELECT NVL(c.VLDESCONTO, 0) AS VLDESCONTO,
             NVL(c.VLOUTRASDESP, 0) AS VLOUTRASDESP,
             NVL(c.VLFRETE, 0) AS VLFRETE,
             c.CONDVENDA AS CONDVENDA,

             /***VLATEND ***/
             SUM(ROUND(DECODE(c.CONDVENDA,
                              4,
                              0,
                              5,
                              0,
                              8,
                              0,
                              11,
                              0,
                              NVL(i.QT, 0) * NVL(i.PVENDA, 0)),
                       2)) AS VLATEND,

             /***VLTOTAL ***/
             SUM(ROUND((NVL(i.QT, 0) + NVL(i.QTFALTA, 0)) *
                       NVL(i.PVENDA, 0),
                       2)) AS VLTOTAL,

             /***VLTABELA***/
             SUM(ROUND(DECODE(c.CONDVENDA,
                              4,
                              0,
                              7,
                              0,
                              NVL(i.QT, 0) * NVL(i.PTABELA, 0)),
                       2)) AS VLTABELA,

             /***CUSTOS ***/
             SUM(DECODE(c.CONDVENDA,
                        4,
                        0,
                        7,
                        0,
                        NVL(i.QT, 0) * NVL(i.VLCUSTOFIN, 0))) AS VLCUSTOFIN,

             SUM(DECODE(c.CONDVENDA,
                        4,
                        0,
                        7,
                        0,
                        NVL(i.QT, 0) * NVL(i.VLCUSTOREAL, 0))) AS VLCUSTOREAL,

             COUNT(*) AS NUMITENS,

             SUM(NVL(i.QT, 0) * NVL(i.VLCUSTOREP, 0)) AS VLCUSTOREP,
             SUM(NVL(i.QT, 0) * NVL(i.VLCUSTOCONT, 0)) AS VLCUSTOCONT,

             SUM(NVL(i.QT, 0) * NVL(p.PESOBRUTO, 0)) AS TOTPESO,
             SUM(NVL(i.QT, 0) * NVL(p.VOLUME, 0)) AS TOTVOLUME

        INTO vVLDESCONTO,
             vVLOUTRASDESP,
             vVLFRETE,
             vCONDVENDA,
             vVLATEND_AGG,
             vVLTOTAL_AGG,
             vVLTABELA_AGG,
             vVLCUSTOFIN,
             vVLCUSTOREAL,
             vNUMITENS,
             vVLCUSTOREP,
             vVLCUSTOCONT,
             vTOTPESO,
             vTOTVOLUME
        FROM PCPEDI i
        JOIN PCPEDC c ON c.NUMPED = i.NUMPED
        JOIN PCPRODUT p ON p.CODPROD = i.CODPROD
       WHERE c.NUMPED = vNUMPED
       GROUP BY NVL(c.VLDESCONTO, 0),
                NVL(c.VLOUTRASDESP, 0),
                NVL(c.VLFRETE, 0),
                c.CONDVENDA;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN;
    END;

    /** VLTOTAL CALCULANDO VALOR TOTAL ***/
    vVlTotal := vVLTOTAL_AGG - vVLDESCONTO + vVLOUTRASDESP + vVLFRETE;

    IF vCONDVENDA NOT IN (4, 5, 8, 11) THEN
      vVlAtend := vVLATEND_AGG - vVLDESCONTO + vVLOUTRASDESP + vVLFRETE;
    ELSE
      vVlAtend := 0;
    END IF;

    IF vCONDVENDA NOT IN (4, 7) THEN
      vVlTabela := vVLTABELA_AGG - vVLDESCONTO + vVLOUTRASDESP + vVLFRETE;

    ELSE
      vVlTabela    := 0;
      vVLCUSTOFIN  := 0;
      vVLCUSTOREAL := 0;
      vVLCUSTOREP  := 0;
      vVLCUSTOCONT := 0;
    END IF;

    /** UPDATE PCPEDC***/
    UPDATE PCPEDC
       SET TOTPESO     = vTOTPESO,
           TOTVOLUME   = vTOTVOLUME,
           NUMITENS    = vNUMITENS,
           VLATEND     = vVlAtend,
           VLTABELA    = vVlTabela,
           VLCUSTOFIN  = vVLCUSTOFIN,
           VLCUSTOREAL = vVLCUSTOREAL,
           VLCUSTOREP  = vVLCUSTOREP,
           VLCUSTOCONT = vVLCUSTOCONT
     WHERE NUMPED = vNUMPED;

    /** UPDATE PCCARREG***/
    IF vNUMCAR > 0 THEN
      UPDATE pccarreg car
         SET (vltotal, totpeso, totvolume) = (SELECT SUM(NVL(i.qt, 0) *
                                                         NVL(i.pvenda, 0)),
                                                     SUM(NVL(i.qt, 0) *
                                                         NVL(p.pesobruto, 0)),
                                                     SUM(NVL(i.qt, 0) *
                                                         NVL(p.volume, 0))
                                                FROM pcpedc   c,
                                                     pcpedi   i,
                                                     pcprodut p
                                               WHERE i.numped = c.numped
                                                 AND i.codprod = p.codprod
                                                 AND c.numcar = vNUMCAR)
       WHERE car.numcar = vNUMCAR;
    END IF;

    /** ATUALIZA QUANTIDADE RESERVADA PARA PRODUTOS MONTADOS OU LIBERADOS**/
    IF vPOSICAO IN ('M', 'L') THEN

      FOR REG_RESERV IN (SELECT CODPROD,
                                SUM(NVL(QTORIG, 0)) AS QTORIGINAL,
                                SUM(NVL(QTSEPARADA, 0)) AS QTSEPARADA
                           FROM PCPEDI
                          WHERE NUMPED = vNUMPED HAVING
                          SUM(NVL(QTORIG, 0)) <>
                                SUM(NVL(QTSEPARADA, 0))
                          GROUP BY CODPROD)

       LOOP

        /****RETIRANDO A QUANTIDADE CORTADA DA RESERVA****/
        IF REG_RESERV.QTORIGINAL > REG_RESERV.QTSEPARADA THEN

          UPDATE PCEST
             SET qtreserv = Least(greatest(0,
                                           NVL(qtreserv, 0) -
                                           (REG_RESERV.QTORIGINAL -
                                            REG_RESERV.QTSEPARADA)),
                                  nvl(qtestger, 0))
           WHERE codfilial = pCODFILIAL
             AND codprod = REG_RESERV.CODPROD;

        END IF;

        IF REG_RESERV.QTORIGINAL < REG_RESERV.QTSEPARADA THEN

          UPDATE PCEST
             SET qtreserv = Least(greatest(0,
                                           NVL(qtreserv, 0) +
                                           (REG_RESERV.QTSEPARADA -
                                            REG_RESERV.QTORIGINAL)),
                                  nvl(qtestger, 0))
           WHERE codfilial = pCODFILIAL
             AND codprod = REG_RESERV.CODPROD;

        END IF;

      END LOOP;

    END IF;

  END PROCESSAR_CORTE;

  PROCEDURE SEPERAR_ITEM_PEDIDO_POR_LOTE(pCODFILIAL     IN VARCHAR2,
                                         pNUMPED        IN NUMBER,
                                         pCODPROD       IN NUMBER,
                                         pNUMSEQ        IN NUMBER,
                                         pQUANTIDADESEP IN NUMBER,
                                         pNUMLOTE       IN VARCHAR2) IS

    v_COUNT                      NUMBER;
    vITEM_COM_SEPARACAO_INICIADA VARCHAR2(1);
    VPROX_NUM_PED                NUMBER;
    VROW_PCPEDI                  PCPEDI%ROWTYPE;
    vPOSICAOPEDIDO               VARCHAR2(1);
    vNUMPED                      NUMBER;

  BEGIN

    BEGIN
      SELECT POSICAO, NUMPED
        INTO vPOSICAOPEDIDO, vNUMPED
        FROM PCPEDC
       WHERE NUMPED = pNUMPED;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vPOSICAOPEDIDO := 'X';
        vNUMPED        := 0;
    END;

    /***SE O PEDIDO NÃO FOR ENCONTRADO NÃO FAZER NADA ***/
    IF vNUMPED = 0 THEN
      RETURN;
    END IF;

    /***SE O PEDIDO JÁ ESTÁ FATURADO NÃO FAZER NADA ***/
    IF vPOSICAOPEDIDO = 'F' THEN
      RETURN;
    END IF;

    vITEM_COM_SEPARACAO_INICIADA := 'N';

    SELECT COUNT(1)
      INTO v_COUNT
      FROM PCPEDI
     WHERE NVL(QTSEPARADA, 0) > 0
       AND CODPROD = pCODPROD
       AND NUMSEQ = pNUMSEQ
       AND NUMPED = pNUMPED;

    IF v_COUNT > 0 THEN
      vITEM_COM_SEPARACAO_INICIADA := 'S';
    END IF;

    IF vITEM_COM_SEPARACAO_INICIADA = 'S' THEN
      /****TENTA ATUALIZAR UMA LINHA QUE JA EXISTA COM AQUELE LOTE****/
      UPDATE PCPEDI
         SET QTSEPARADA   = NVL(QTSEPARADA, 0) + pQUANTIDADESEP,
             DTINICIALSEP = TRUNC(SYSDATE),
             QTAPANHA     = NVL(QTAPANHA, 0) + pQUANTIDADESEP,
             DTFINALSEP   = TRUNC(SYSDATE),
             DATACONF     = TRUNC(SYSDATE),
             DATACONFFIM  = TRUNC(SYSDATE),
             CODFUNCSEP   = 1,
             CODFUNCCONF  = 1
       WHERE NUMPED = pNUMPED
         AND CODPROD = pCODPROD
         AND NUMSEQ = pNUMSEQ
         AND NUMLOTE = pNUMLOTE;

      v_COUNT := SQL%ROWCOUNT;

      /****SE NÃO ENCONTRAR, SIGNIFICA QUE A LINHA DESSE RESPECTIVO PRODUTO/NUMSEQ JÁ FOI SEPARADA COM OUTRO LOTE PORTANTO SERÁ NECESSARIO DESDOBRAR A LINHA PARA O NOVO LOTE ****/
      /***INICIO DESDOBRAMENTO LOTE PCPEDI ***/
      IF v_COUNT = 0 THEN

        /***CLONANDO A LINHA CODPROD/NUMSEQ***/
        SELECT I.*
          INTO VROW_PCPEDI
          FROM PCPEDI I
         WHERE I.NUMPED = PNUMPED
           AND I.CODPROD = PCODPROD
           AND I.NUMSEQ = PNUMSEQ;

        /***DESCONTANDO A QUANTIDADE QUE VAI SER INSERIDA EM OUTRA LINHA***/
        VROW_PCPEDI.QT := VROW_PCPEDI.QT - pQUANTIDADESEP;

        UPDATE PCPEDI I
           SET I.QT = VROW_PCPEDI.QT
         WHERE I.NUMPED = VROW_PCPEDI.NUMPED
           AND I.CODPROD = VROW_PCPEDI.CODPROD
           AND I.NUMSEQ = VROW_PCPEDI.NUMSEQ;

        SELECT MAX(COALESCE(PCPEDI.NUMSEQ, 0)) + 1
          INTO VPROX_NUM_PED
          FROM PCPEDI
         WHERE NUMPED = PNUMPED;

        VROW_PCPEDI.NUMSEQ     := VPROX_NUM_PED;
        VROW_PCPEDI.QT         := pQUANTIDADESEP;
        VROW_PCPEDI.QTSEPARADA := pQUANTIDADESEP;
        VROW_PCPEDI.QTAPANHA   := pQUANTIDADESEP;
        VROW_PCPEDI.NUMLOTE    := pNUMLOTE;

        INSERT INTO PCPEDI VALUES VROW_PCPEDI;

      END IF;
      /***FIM DESDOBRAMENTO LOTE PCPEDI ***/

    ELSE
      /****ATUALIZAÇÃO DA PRIMEIRA LINHA DO CODPROD/NUMSEQ****/
      UPDATE PCPEDI
         SET QTSEPARADA   = NVL(QTSEPARADA, 0) + pQUANTIDADESEP,
             DTINICIALSEP = TRUNC(SYSDATE),
             QTAPANHA     = NVL(QTAPANHA, 0) + pQUANTIDADESEP,
             DTFINALSEP   = TRUNC(SYSDATE),
             DATACONF     = TRUNC(SYSDATE),
             DATACONFFIM  = TRUNC(SYSDATE),
             CODFUNCSEP   = 1,
             CODFUNCCONF  = 1,
             NUMLOTE      = pNUMLOTE
       WHERE NUMPED = pNUMPED
         AND CODPROD = pCODPROD
         AND NUMSEQ = pNUMSEQ;

    END IF;

  END SEPERAR_ITEM_PEDIDO_POR_LOTE;

  PROCEDURE INATIVAR_INTEGRACAO_DOC_SAIDA(pCODFILIAL     IN VARCHAR2,
                                          pNUMDOC        IN NUMBER,
                                          pTIPODOCUMENTO IN VARCHAR2) IS

    v_COUNT NUMBER;

  BEGIN

    IF pTIPODOCUMENTO = 'PEDIDO DE VENDA' THEN
      UPDATE PCPEDC
         SET DTWMS = NULL
       WHERE NUMPED = pNUMDOC
         AND CODFILIAL = pCODFILIAL;

      UPDATE PCPEDI SET CODIGOINTEGRACAOWMS = NULL WHERE NUMPED = pNUMDOC;


      /****DELETANDO TABELAS DE REGISTRO DE INTEGRAÇÃO MANUAL****/
      DELETE PCINTEGRACAOWMSSAASITEM WHERE NUMDOCWMSSAAS = pNUMDOC;
      DELETE PCINTEGRACAOWMSSAAS WHERE NUMDOCWINTHOR = pNUMDOC;

    END IF;

    IF pTIPODOCUMENTO = 'NOTA FISCAL' THEN
      UPDATE PCNFSAID
         SET DTWMS = NULL
       WHERE NUMNOTA = pNUMDOC
         AND CODFILIAL = pCODFILIAL;
    END IF;

  END INATIVAR_INTEGRACAO_DOC_SAIDA;

END PKG_INTEGRACAOWMSSAAS;