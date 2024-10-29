CREATE OR REPLACE FUNCTION FCT_MED_VALIDARKIT (
   pnNUMPED                NUMBER
  ,pnCODPROMOCAOMED       NUMBER
)
   RETURN NUMBER
/*******************************************************************************
 Nome         : FCT_MED_VALIDARKIT
 Descricão    : Função para retornar a quantidade de combos do kit no pedido
 Alteracão    : Rubens Junior - 15/08/2015
********************************************************************************/                                       
IS
  vnINICIOINTERVALOPROMOCAOMED  NUMBER;
  vnQTDECOMBO                   NUMBER;
  vnQTDECOMBOMED                NUMBER;
  vvTIPOPROMOCAOMED             PCPROMOCAOMED.TIPOPROMOCAO%TYPE;
  vvTIPOLITICAMED               PCPROMOCAOMED.TIPOPOLITICA%TYPE;
    
BEGIN
   vnQTDECOMBO   := 0;
  BEGIN
   SELECT PCPROMOCAOMED.TIPOPROMOCAO,PCPROMOCAOMED.TIPOPOLITICA 
     INTO vvTIPOPROMOCAOMED,vvTIPOLITICAMED
   FROM  PCPROMOCAOMED 
   WHERE CODPROMOCAOMED = pnCODPROMOCAOMED;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      vvTIPOPROMOCAOMED := NULL;
      vvTIPOLITICAMED   := NULL;
  END; 
   
  IF ((vvTIPOPROMOCAOMED = 'K') AND 
      (vvTIPOLITICAMED = 'Q'))
  THEN    
    FOR CR IN (SELECT CODPROD
                     , QT,CODDESCONTO
                  FROM PCPEDI
                 WHERE NUMPED = pnNUMPED
                 AND CODPROMOCAOMED = pnCODPROMOCAOMED                 
                 ORDER BY NUMSEQ
                        , CODPROD)
     LOOP
        -- BUSCANDO O INTERVALO INICIAL DO PRODUTO NA PROMOÿÿO (KIT)
        BEGIN
            SELECT INICIOINTERVALOPROMOCAOMED, QTCOMBOMED 
             INTO vnINICIOINTERVALOPROMOCAOMED,vnQTDECOMBOMED
            FROM
            (SELECT INICIOINTERVALOPROMOCAOMED,PCPROMOCAOMED.TIPOPROMOCAO,PCPROMOCAOMED.TIPOPOLITICA,NVL(PCDESCONTO.QTCOMBOMED,0) QTCOMBOMED     
              FROM PCDESCONTO,PCPROMOCAOMED
             WHERE PCDESCONTO.CODPROMOCAOMED = PCPROMOCAOMED.CODPROMOCAOMED
--               AND PCDESCONTO.CODPROMOCAOMED = pnCODPROMOCAOMED
               AND CODPROD = CR.CODPROD AND CODDESCONTO = CR.CODDESCONTO );
               
            -- VERIFICANDO SE TEM RESTO DE DIVISÿO, SE ACHAR E PORQUE O COMBO
            -- FOI MANIPULADO E NÿO FOI INFORMADO MULTIPLO.
            IF (vnQTDECOMBOMED > 1) THEN
              IF (MOD(CR.QT,vnQTDECOMBOMED) > 0) THEN
                vnQTDECOMBO := 0;
                EXIT;
              END IF;    
              
              -- SE QTDECOMBO FOR ZERO ÿ PQ ÿ O PRIMEIRO ITEM, ENTÿO IRÁ ACHAR A QTDE 
              -- BASE DO COMBO.
              IF vnQTDECOMBO = 0 THEN
                vnQTDECOMBO := (CR.QT/vnQTDECOMBOMED);
              ELSE
    
                IF  (vnQTDECOMBO <> ((CR.QT/vnQTDECOMBOMED))) THEN
                   vnQTDECOMBO := 0;
                   EXIT;
                END IF;
              END IF;
            ELSE 
              
              IF MOD(CR.QT , vnINICIOINTERVALOPROMOCAOMED) > 0 THEN
                vnQTDECOMBO := 0;
                EXIT;
              END IF;    
              
              -- SE QTDECOMBO FOR ZERO ÿ PQ ÿ O PRIMEIRO ITEM, ENTÿO IRÁ ACHAR A QTDE 
              -- BASE DO COMBO.
              IF vnQTDECOMBO = 0 THEN
                vnQTDECOMBO := CR.QT / vnINICIOINTERVALOPROMOCAOMED;
              ELSE
                -- A PARTIR DO SEGUNDO ITEM EM DIANTE A QUANTIDADE DE COMBO NÿO PODERÁ 
                -- SER DIFERENTE DO PRIMEIRO. 
                IF  vnQTDECOMBO <> (CR.QT / vnINICIOINTERVALOPROMOCAOMED) THEN
                   vnQTDECOMBO := 0;
                   EXIT;
                END IF;
              END IF;     
            END IF;
               
        EXCEPTION
          WHEN OTHERS THEN        
             vnQTDECOMBO := 0;
        END;
     
     END LOOP;
  ELSE
  
     FOR CR IN (SELECT CODPROD
                     , QT 
                  FROM PCPEDI
                 WHERE  NUMPED = pnNUMPED
                 AND CODPROMOCAOMED = pnCODPROMOCAOMED   
                 ORDER BY NUMSEQ
                        , CODPROD)
     LOOP
        -- BUSCANDO O INTERVALO INICIAL DO PRODUTO NA PROMOÿÿO (KIT)
        BEGIN
           SELECT INICIOINTERVALOPROMOCAOMED,PCPROMOCAOMED.TIPOPROMOCAO,PCPROMOCAOMED.TIPOPOLITICA,NVL(PCDESCONTO.QTCOMBOMED,0) QTCOMBOMED     
            INTO vnINICIOINTERVALOPROMOCAOMED,vvTIPOPROMOCAOMED,vvTIPOLITICAMED,vnQTDECOMBOMED
              FROM PCDESCONTO,PCPROMOCAOMED
             WHERE PCDESCONTO.CODPROMOCAOMED = PCPROMOCAOMED.CODPROMOCAOMED
               AND PCDESCONTO.CODPROMOCAOMED = pnCODPROMOCAOMED
               AND CODPROD = CR.CODPROD
               AND ROWNUM = 1;
               
            -- VERIFICANDO SE TEM RESTO DE DIVISÿO, SE ACHAR E PORQUE O COMBO
            -- FOI MANIPULADO E NÿO FOI INFORMADO MULTIPLO.
             IF MOD(CR.QT , vnINICIOINTERVALOPROMOCAOMED) > 0 THEN
                vnQTDECOMBO := 0;
                EXIT;
              END IF;    
              
              -- SE QTDECOMBO FOR ZERO ÿ PQ ÿ O PRIMEIRO ITEM, ENTÿO IRÁ ACHAR A QTDE 
              -- BASE DO COMBO.
              IF vnQTDECOMBO = 0 THEN
                vnQTDECOMBO := CR.QT / vnINICIOINTERVALOPROMOCAOMED;
              ELSE
                -- A PARTIR DO SEGUNDO ITEM EM DIANTE A QUANTIDADE DE COMBO NÿO PODERÁ 
                -- SER DIFERENTE DO PRIMEIRO. 
                IF  vnQTDECOMBO <> (CR.QT / vnINICIOINTERVALOPROMOCAOMED) THEN
                   vnQTDECOMBO := 0;
                   EXIT;
                END IF;
              END IF;     
           
               
        EXCEPTION
          WHEN OTHERS THEN        
             vnQTDECOMBO := 0;
        END;
     
     END LOOP;
   END IF;
   RETURN vnQTDECOMBO;

END;
