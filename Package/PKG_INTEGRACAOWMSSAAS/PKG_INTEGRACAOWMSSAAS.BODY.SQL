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
    v_COUNT NUMBER;

  BEGIN

    vDOCUMENTOFOIDIVIDIDO       := 'N';
    vDOCUMENTOFOIGERADOFRAC     := 'N';
    vDOCUMENTOFOIGERADOCX       := 'N';
    v_COUNT := 0;

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

    IF pTIPODOCWINTHOR = 'PEDIDO_VENDA' THEN

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
                     AND ITEM.NUMSEQ IS NOT NULL)

       LOOP
        --VERIFICA SE ESTÁ APTO A GERAR DOIS DOCUMENTOS (CAIXA E FRACIONADO)
        IF vDIVIDIRDOCUMENTO = 'S' AND
           (REG.FRACIONADO = 'S' OR REG.EMBALADO = 'S') THEN

          vDOCUMENTOFOIDIVIDIDO := 'S';

          --GERA DOCUMENTO COM A QUANTIDADE FRACIONADA
          IF REG.QTUNIDADESFORACAIXA > 0 THEN
            INSERT INTO PCINTEGRACAOWMSSAASITEM
              (NUMDOCWMSSAAS, CODPROD, QTORIG, QT, NUMSEQ)
            VALUES
              (vDOCWMSSAAS_FRACIONADO,
               REG.CODPROD,
               REG.QTUNIDADESFORACAIXA,
               REG.QTUNIDADESFORACAIXA,
               REG.NUMSEQ);
            vDOCUMENTOFOIGERADOFRAC := 'S';
          END IF;

          --GERA DOCUMENTO COM A QUANTIDADE UN(CAIXA)
          IF REG.QTUNIDADESDENTROCAIXA > 0 THEN
            INSERT INTO PCINTEGRACAOWMSSAASITEM
              (NUMDOCWMSSAAS, CODPROD, QTORIG, QT, NUMSEQ)
            VALUES
              (vDOCWMSSAAS_CAIXA,
               REG.CODPROD,
               REG.QTUNIDADESDENTROCAIXA,
               REG.QTUNIDADESDENTROCAIXA,
               REG.NUMSEQ);
            vDOCUMENTOFOIGERADOCX := 'S';
          END IF;


          --CASO CONTRARIO GERA APENAS UM DOCUMENTO
        ELSE
          INSERT INTO PCINTEGRACAOWMSSAASITEM
            (NUMDOCWMSSAAS, CODPROD, QTORIG, QT, NUMSEQ)
          VALUES
            (REG.NUMPED, REG.CODPROD, REG.QT, REG.QT, REG.NUMSEQ);

          vDOCUMENTOFOIGERADOCOMPLETO := 'S';

        END IF;

      END LOOP;

      --GERAR CABECHALO DOS DOCUMETOS (COMPLETO, FRACIONADO ou CAIXA)

      IF vDOCUMENTOFOIGERADOCOMPLETO = 'S' THEN

      --VALIDACAO PARA NÃO GERAR PCINTEGRACAOWMSSAAS, AVALIAR POSTERIORMENTE O MOTIVO DESSA POSSIVEL DUPLICIDADE----
        SELECT COUNT(1) INTO v_COUNT
          FROM PCINTEGRACAOWMSSAAS
          WHERE NUMDOCWINTHOR = pNUMDOCWINTHOR
          AND NUMDOCWMSSAAS = pNUMDOCWINTHOR
          AND CODFILIAL = pCODFILIAL
          AND TIPOGERACAODOC = 'COMPLETO'
          AND TIPODOCWINTHOR = pTIPODOCWINTHOR
          AND DTCANCELAMENTO IS NULL
          AND DTFIMSEPARACAO IS NULL
          AND DTFILAINTEGRACAO IS NOT NULL;

          IF v_COUNT = 0 THEN
            ENVIARDOCFILAINTEGRACAO(pCODFILIAL,
                                pNUMDOCWINTHOR,
                                pNUMDOCWINTHOR,
                                pTIPOINTEGRACAO,
                                pTIPODOCWINTHOR,
                                'COMPLETO',
                                'S');
          END IF;

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
    vEXPORTAINFODOCORIGINAL VARCHAR2(2);
  
  BEGIN
  
    vOBS                    := '';
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
  
    SELECT DECODE(NVL((SELECT NVL(VALOR, 'N')
                        FROM PCPARAMINTEGRACAOWMSSAAS
                       WHERE PARAMETRO = 'EXPORTA_RAMO_ATIVIDADE_CLIENTE'
                         AND CODFILIAL = '1'),
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
       vOBS);
  
  END ENVIARDOCFILAINTEGRACAO;
  
    PROCEDURE FINALIZARSEPARACAOITEMFILA(pCODFILIAL     IN VARCHAR2,
                                       pNUMDOCWMSSAAS IN NUMBER,
                                       pCODPROD       IN NUMBER,
                                       pNUMSEQ        IN NUMBER,
                                       pQTSEPARADA    IN NUMBER,
                                       pNUMLOTE       IN VARCHAR2) IS
  
    vREGISTRO_NOVO PCINTEGRACAOWMSSAASITEM%ROWTYPE;
  
  BEGIN
  
    UPDATE PCINTEGRACAOWMSSAASITEM
       SET QTSEPARADA = pQTSEPARADA, NUMLOTE = pNUMLOTE
     WHERE NUMDOCWMSSAAS = pNUMDOCWMSSAAS
       AND CODPROD = pCODPROD
       AND NUMSEQ = pNUMSEQ
       AND NVL(QTSEPARADA, 0) = 0;
  
    IF SQL%ROWCOUNT = 0 THEN
      FOR vREG IN (SELECT *
                     FROM PCINTEGRACAOWMSSAASITEM
                    WHERE NUMDOCWMSSAAS = pNUMDOCWMSSAAS
                      AND CODPROD = pCODPROD
                      AND ROWNUM = 1) LOOP
        vREGISTRO_NOVO            := vREG;
        vREGISTRO_NOVO.NUMLOTE    := pNUMLOTE;
        vREGISTRO_NOVO.QTSEPARADA := pQTSEPARADA;
        INSERT INTO PCINTEGRACAOWMSSAASITEM VALUES vREGISTRO_NOVO;
      END LOOP;
    END IF;
  
  END FINALIZARSEPARACAOITEMFILA;
  
  PROCEDURE EFETUAR_AJUSTE_ESTOQUE(pCODFILIAL           IN VARCHAR2,
                                        pCODPROD         IN NUMBER,
                                        pQUANTIDADE      IN NUMBER,
                                        pTIPO            IN VARCHAR2,
                                        pVALIDADE        IN DATE,
                                        pNUMLOTE         IN VARCHAR2) IS
    v_PROX_NUM_LANCAMENTO NUMBER;
    v_NUMTRANSENT NUMBER;
    v_NUMTRANSVENDA NUMBER;      
    v_CODCONTAJUSTEEST NUMBER; 
    v_CODOPER VARCHAR2(2); 
    v_COUNT NUMBER; 
    v_USA_ESTOQUE_POR_LOTE VARCHAR2(1);
    v_CODEPTO NUMBER; 
    v_CODSEC NUMBER;
    v_CUSTOULTENT NUMBER;
    v_CUSTOCONT NUMBER;
    v_CUSTOREAL NUMBER;
    v_CUSTOFIN NUMBER;
    v_msg_retorno    VARCHAR2(4000);
    v_RESULTADO NUMBER;
    v_NUMLANC NUMBER;
    v_PRAZOVAL NUMBER;
  
                               
    BEGIN
    
    --Carrega valores das transaÃ§Ãµes e da conta de ajuste
    SELECT PROXNUMLANC, PROXNUMTRANSENT, PROXNUMTRANSVENDA, CODCONTAJUSTEEST 
     INTO v_PROX_NUM_LANCAMENTO, v_NUMTRANSENT, v_NUMTRANSVENDA, v_CODCONTAJUSTEEST
    FROM PCCONSUM FOR UPDATE;

    UPDATE PCCONSUM SET PROXNUMLANC = PROXNUMLANC + 1, PROXNUMTRANSENT = PROXNUMTRANSENT + 1, PROXNUMTRANSVENDA = PROXNUMTRANSVENDA + 1;
    
    SELECT NVL(ESTOQUEPORLOTE, 'N'), NVL(CODEPTO,0), NVL(CODSEC,0), NVL(PRAZOVAL,0)
    INTO v_USA_ESTOQUE_POR_LOTE, v_CODEPTO, v_CODSEC, v_PRAZOVAL
    FROM PCPRODUT WHERE CODPROD = pCODPROD;
    
    --Carrega valores de custos dos produtos
    select nvl(pcest.CUSTOULTENT,0) CUSTOULTENT, nvl(pcest.CUSTOCONT,0) CUSTOCONT, 
    nvl(pcest.CUSTOREAL,0) CUSTOREAL, nvl(pcest.CUSTOFIN,0) CUSTOFIN 
    INTO v_CUSTOULTENT, v_CUSTOCONT, v_CUSTOREAL, v_CUSTOFIN
    from pcest
    where codprod = pCODPROD
    and codfilial = pCODFILIAL;
    
    
    IF pTIPO = 'E' THEN
    v_CODOPER := 'EA';
    
      IF v_USA_ESTOQUE_POR_LOTE = 'S' THEN
      
      
        ---Caso seja uma entrada de um lote novo, o mesmo deve ser inserido na PCMOV
        select count(numlote) INTO v_COUNT from pclote where codprod = pCODPROD and numlote = pNUMLOTE and codfilial = pCODFILIAL;
      
        IF v_COUNT = 0 THEN
        INSERT INTO PCLOTE (CODPROD, CODFILIAL, QT, DTVALIDADE, NUMLOTE, NUMTRANSENT, QTEST, DATAFABRICACAO) 
        VALUES (pCODPROD, pCODFILIAL, pQUANTIDADE, pVALIDADE, pNUMLOTE, v_NUMTRANSENT,0, TRUNC(pVALIDADE) - v_PRAZOVAL);
        END IF;
      
      END IF;
    
    END IF;
    
    IF pTIPO = 'S' THEN
    v_CODOPER := 'SA';
    END IF;
    
    --CriaÃ§Ã£o da MovimentaÃ§Ã£o 
    INSERT INTO PCMOV (DTMOV, CODPROD, NUMNOTA, CODOPER, QT, QTBLOQUEADA,PUNIT, CODFILIAL, CODCLI, CODUSUR, CUSTOFIN,                                                           
    CUSTOCONT, CUSTOREAL, STATUS, CODEPTO, CODSEC,CODFORNEC, CODFUNCLANC,NUMTRANSVENDA,NUMTRANSENT, CODDEVOL, NUMLOTE )                                  
    VALUES (TRUNC(SYSDATE),pCODPROD, 0, v_CODOPER, pQUANTIDADE, pQUANTIDADE, 
    0, pCODFILIAL, 0, 0, v_CUSTOFIN, v_CUSTOCONT, v_CUSTOREAL, 'B', v_CODEPTO, v_CODSEC, 0, 1,DECODE(v_CODOPER, 'SA',v_NUMTRANSVENDA,0),DECODE(v_CODOPER, 'EA',v_NUMTRANSENT,0), 0,                                                
    DECODE((SELECT NVL(ESTOQUEPORLOTE,'N') FROM PCPRODUT WHERE CODPROD = pCODPROD),'S',pNUMLOTE,NULL));  
    
    
    IF pTIPO = 'E' THEN
    
      v_RESULTADO := PKG_ESTOQUE.LOGISTICA_ENTRADA(v_NUMTRANSENT, 'N', v_msg_retorno);
      
      IF v_msg_retorno <> 'OK' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Erro ao executar LOGISTICA_ENTRADA: ' || v_msg_retorno);
      END IF;

    END IF;
    
    
    
    IF pTIPO = 'S' THEN
    
      v_RESULTADO := PKG_ESTOQUE.LOGISTICA_SAIDA(v_NUMTRANSVENDA, 'N', v_msg_retorno);
      
      IF v_msg_retorno <> 'OK' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Erro ao executar LOGISTICA_SAIDA: ' || v_msg_retorno);
      END IF;
    
    END IF;
    
    
        SELECT NVL(PROXNUMLANC,0) NUMLANC, NVL(CODCONTAJUSTEEST,0) CODCONTAJUSTEEST 
    INTO v_NUMLANC, v_CODCONTAJUSTEEST
    FROM PCCONSUM FOR UPDATE;
    
    UPDATE PCCONSUM SET PROXNUMLANC = NVL(PROXNUMLANC,0) + 1;
    
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
    PROCESSACENTRODECUSTO(pCODFILIAL, v_CODCONTAJUSTEEST, 'FINANCEIRO',v_NUMLANC);
    
    

    
    END EFETUAR_AJUSTE_ESTOQUE;          


  FUNCTION GET_VALIDADE_MINIMA_PRODUTO(PNUMPED  IN NUMBER,
                                       PCODPROD IN NUMBER) RETURN VARCHAR2 IS
    v_CODCLI                   NUMBER := 0;
    v_CONTROLA_LOTE            VARCHAR2(1) := 'N';
    v_CONTROLA_VALIDADE        VARCHAR2(1) := 'N';
    v_PRAZO_VALIDADE_DIAS      NUMBER := 0;
    v_PERC_TOLERANCIA_VALIDADE NUMBER := 0;
    v_DATA_MINIMA              DATE;
    v_CODFILIAL                VARCHAR2(1);
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
                                        

END PKG_INTEGRACAOWMSSAAS;