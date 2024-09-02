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
  
  BEGIN
  
    vDOCUMENTOFOIDIVIDIDO       := 'N';
    vDOCUMENTOFOIGERADOFRAC     := 'N';
    vDOCUMENTOFOIGERADOCX       := 'N';
  
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
        ENVIARDOCFILAINTEGRACAO(pCODFILIAL,
                                pNUMDOCWINTHOR,
                                pNUMDOCWINTHOR,
                                pTIPOINTEGRACAO,
                                pTIPODOCWINTHOR,
                                'COMPLETO',
                                'S');
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

END PKG_INTEGRACAOWMSSAAS;