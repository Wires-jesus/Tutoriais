CREATE OR REPLACE PACKAGE BODY PKG_RECEBIMENTO IS

  PROCEDURE WMS_MOV_AJUSTE_LOTES(pCodfilial IN VARCHAR2,pNumbonus  IN NUMBER) IS
    LINHA_ORIGINAL          PCMOV%ROWTYPE;
    vQTENTRADA_AJUSTE       NUMBER(20, 6);
    vQTSAIDA_AJUSTE         NUMBER(20, 6);
    vQTJAULIZADASAIDAAJUSTE NUMBER(20, 6);
    vNUMTRANSVENDA          NUMBER(10);
    vNUMTRANSENT            NUMBER(10);
    vNUMTRANSENTORIGINAL    NUMBER(10);
    vNUMLANCAMENTO          NUMBER(10);
    vQTLINHASPCLOTE         NUMBER(10);
    vNUMBONUS               NUMBER(8);
    vCODFILIAL              VARCHAR2(2);
  
  BEGIN
  
    vQTENTRADA_AJUSTE       := 0;
    vQTSAIDA_AJUSTE         := 0;
    vNUMTRANSENT            := 0;
    vNUMTRANSVENDA          := 0;
    vNUMTRANSENTORIGINAL    := 0;
    vQTJAULIZADASAIDAAJUSTE := 0;
    vNUMLANCAMENTO          := 0;
    vQTLINHASPCLOTE         := 0;
  
    vNUMBONUS  := pNumbonus;
    vCODFILIAL := pCodfilial;
  
    SELECT DECODE(NVL(PROXNUMLANC, 0), 0, 1, PROXNUMLANC),
           NVL(PROXNUMTRANSENT, 1) AS PROXNUMTRANSENT,
           NVL(PROXNUMTRANSVENDA, 1) AS PROXNUMTRANSVENDA
      INTO vNUMLANCAMENTO, vNUMTRANSENT, vNUMTRANSVENDA
      FROM PCCONSUM
       FOR UPDATE;
  
    UPDATE PCCONSUM
       SET PROXNUMLANC       = DECODE(NVL(PROXNUMLANC, 0), 0, 1, PROXNUMLANC) + 1,
           PROXNUMTRANSENT   = NVL(PROXNUMTRANSENT, 1) + 1,
           PROXNUMTRANSVENDA = NVL(PROXNUMTRANSVENDA, 1) + 1;
  
    SELECT NUMTRANSENT
      INTO vNUMTRANSENTORIGINAL
      FROM PCMOV
     WHERE NUMBONUS = vNUMBONUS
       AND ROWNUM = 1;
  
    ---BUSCAR OS LOTES QUE NÃO EXISTIAM NA NOTA E FORAM CONFERIDOS NO BONUS E O LOTE QUE EXISTIAM MAS FORAM CONFERIDOS COM QT MAIOR QUE A NOTA
    FOR REGLOTES IN (SELECT B.NUMBONUS,
                            B.CODPROD,
                            SUM(B.QTENTRADA) AS QTAJUSTEDEENTRADA,
                            SUM(B.QTAVARIA) AS QTAVARIA,
                            B.NUMLOTE,
                            B.DTVALIDADE,
                            'LOTE NÃO EXISTE NA NOTA' AS SITUACAO
                       FROM PCBONUSI B, PCPRODUT P
                      WHERE B.NUMBONUS = vNUMBONUS
                        AND B.CODPROD = P.CODPROD
                        AND P.ESTOQUEPORLOTE = 'S'
                        AND NOT EXISTS (SELECT 1
                               FROM PCMOV
                              WHERE NUMBONUS = B.NUMBONUS
                                AND CODPROD = B.CODPROD
                                AND NUMLOTE = B.NUMLOTE
                                AND ROWNUM = 1)
                      GROUP BY B.NUMBONUS,
                               B.CODPROD,
                               B.NUMLOTE,
                               B.DTVALIDADE
                     
                     UNION ALL
                     
                     SELECT B.NUMBONUS,
                            B.CODPROD,
                            (SUM(B.QTENTRADA) -
                            (NVL((SELECT SUM(QT)
                                    FROM PCMOV
                                   WHERE NUMBONUS = B.NUMBONUS
                                     AND CODPROD = B.CODPROD
                                     AND NUMLOTE = B.NUMLOTE),
                                  0))) AS QTAJUSTEDEENTRADA,
                            SUM(B.QTAVARIA) AS QTAVARIA,
                            B.NUMLOTE,
                            B.DTVALIDADE,
                            'LOTE COM QUANTIDADE MAIOR QUE NA NOTA' AS SITUACAO
                       FROM PCBONUSI B, PCPRODUT P
                      WHERE B.NUMBONUS = vNUMBONUS
                        AND B.CODPROD = P.CODPROD
                        AND P.ESTOQUEPORLOTE = 'S'
                        AND EXISTS
                      (SELECT 1
                               FROM PCMOV
                              WHERE NUMBONUS = B.NUMBONUS
                                AND CODPROD = B.CODPROD
                                AND NUMLOTE = B.NUMLOTE
                                AND ROWNUM = 1)
                        AND (NVL((SELECT SUM(QTENTRADA)
                                   FROM PCBONUSI
                                  WHERE NUMBONUS = B.NUMBONUS
                                    AND CODPROD = B.CODPROD
                                    AND NUMLOTE = B.NUMLOTE),
                                 0)) > (NVL((SELECT SUM(QT)
                                              FROM PCMOV
                                             WHERE NUMBONUS = B.NUMBONUS
                                               AND CODPROD = B.CODPROD
                                               AND NUMLOTE = B.NUMLOTE),
                                            0))
                      GROUP BY B.NUMBONUS,
                               B.CODPROD,
                               B.NUMLOTE,
                               B.DTVALIDADE)
    
     LOOP
    
      IF REGLOTES.QTAJUSTEDEENTRADA > 0 THEN
      
        vQTENTRADA_AJUSTE := REGLOTES.QTAJUSTEDEENTRADA;
      
        SELECT COUNT(1)
          INTO vQTLINHASPCLOTE
          FROM PCLOTE
         WHERE CODPROD = REGLOTES.CODPROD
           AND NUMLOTE = REGLOTES.NUMLOTE
           AND CODFILIAL = vCODFILIAL;
      
        IF vQTLINHASPCLOTE = 0 THEN
          --INSERÇÃO DO LOTE CASO NÃO EXISTA--
          INSERT INTO PCLOTE
            (CODPROD,
             QT,
             QTBLOQUEADA,
             QTEST,
             QTINDENIZ,
             DTVALIDADE,
             DTULTMOVENT,
             NUMLOTE,
             CODFILIAL,
             NUMTRANSENT)
          VALUES
            (REGLOTES.CODPROD,
             0,
             0,
             0,
             0,
             REGLOTES.DTVALIDADE,
             TRUNC(SYSDATE),
             REGLOTES.NUMLOTE,
             vCODFILIAL,
             vNUMTRANSENT);
        END IF;
      
        --CLONANDO EM UMA VARIÁVEL O REGISTRO ORIGINAL DA PCMOV PARA GERAR A SAÍDA DE AJUSTE
        SELECT *
          INTO LINHA_ORIGINAL
          FROM PCMOV
         WHERE CODPROD = REGLOTES.CODPROD
           AND NUMBONUS = REGLOTES.NUMBONUS
           AND ROWNUM = 1;
      
        LINHA_ORIGINAL.NUMLOTE                 := REGLOTES.NUMLOTE;
        LINHA_ORIGINAL.QT                      := vQTENTRADA_AJUSTE;
        LINHA_ORIGINAL.QTAVARIA                := REGLOTES.QTAVARIA;
        LINHA_ORIGINAL.QTBLOQUEADA             := vQTENTRADA_AJUSTE;
        LINHA_ORIGINAL.CODOPER                 := 'EA';
        LINHA_ORIGINAL.NUMNOTA                 := 0;
        LINHA_ORIGINAL.CODCLI                  := 0;
        LINHA_ORIGINAL.CODUSUR                 := 0;
        LINHA_ORIGINAL.NUMTRANSVENDA           := 0;
        LINHA_ORIGINAL.NUMTRANSENTORIGDESDLOTE := vNUMTRANSENTORIGINAL;
        LINHA_ORIGINAL.NUMTRANSENT             := vNUMTRANSENT;
        LINHA_ORIGINAL.NUMTRANSITEM            := NULL;
      
        ---GERAR ENTRADA DE AJUSTE---
        INSERT INTO PCMOV VALUES LINHA_ORIGINAL;
      
        vQTSAIDA_AJUSTE := REGLOTES.QTAJUSTEDEENTRADA;
        ----BUSCAR OS LOTES QUE ESTÃO APTOS A RECEBER A SAÍDA DE AJUSTE----
      
        FOR REGLOTESAIDAAJUSTE IN (SELECT M.ROWID,
                                          M.NUMBONUS,
                                          M.NUMNOTA,
                                          M.CODPROD,
                                          M.NUMLOTE,
                                          M.QT,
                                          M.QTAVARIA
                                     FROM PCMOV M
                                    WHERE M.NUMBONUS = REGLOTES.NUMBONUS
                                      AND CODPROD = REGLOTES.CODPROD
                                      AND CODOPER NOT IN ('SA', 'EA')
                                      AND M.QT >
                                          NVL((SELECT SUM(QTENTRADA)
                                                FROM PCBONUSI
                                               WHERE NUMBONUS = M.NUMBONUS
                                                 AND CODPROD = M.CODPROD
                                                 AND NUMLOTE = M.NUMLOTE),
                                              0))
        
         LOOP
        
          BEGIN
            SELECT NVL(SUM(QTORIGEM), 0)
              INTO vQTJAULIZADASAIDAAJUSTE
              FROM PCLOTEDESD
             WHERE CODPROD = REGLOTESAIDAAJUSTE.CODPROD
               AND NUMLOTEORIGEM = REGLOTESAIDAAJUSTE.NUMLOTE
               AND NUMTRANSVENDADESTINO = vNUMTRANSVENDA;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vQTJAULIZADASAIDAAJUSTE := 0;
          END;
        
          IF ((REGLOTESAIDAAJUSTE.QT - vQTJAULIZADASAIDAAJUSTE) > 0) AND
             (vQTSAIDA_AJUSTE > 0) THEN
          
            ---CASO LOTE TENHA TODA A QUANTIDADE PARA EFETUAR A SAÍDA NECESSÁRIA---
            IF (REGLOTESAIDAAJUSTE.QT - vQTJAULIZADASAIDAAJUSTE) >=
               vQTSAIDA_AJUSTE THEN
            
              SELECT *
                INTO LINHA_ORIGINAL
                FROM PCMOV
               WHERE ROWID = REGLOTESAIDAAJUSTE.ROWID;
            
              LINHA_ORIGINAL.NUMLOTE                 := REGLOTESAIDAAJUSTE.NUMLOTE;
              LINHA_ORIGINAL.QT                      := vQTSAIDA_AJUSTE;
              LINHA_ORIGINAL.QTAVARIA                := REGLOTESAIDAAJUSTE.QTAVARIA;
              LINHA_ORIGINAL.QTBLOQUEADA             := 0;
              LINHA_ORIGINAL.CODOPER                 := 'SA';
              LINHA_ORIGINAL.NUMNOTA                 := 0;
              LINHA_ORIGINAL.CODCLI                  := 0;
              LINHA_ORIGINAL.CODUSUR                 := 0;
              LINHA_ORIGINAL.NUMTRANSENTORIGDESDLOTE := vNUMTRANSENTORIGINAL;
              LINHA_ORIGINAL.NUMTRANSENT             := 0;
              LINHA_ORIGINAL.NUMTRANSVENDA           := vNUMTRANSVENDA;
              LINHA_ORIGINAL.NUMTRANSITEM            := NULL;
            
              INSERT INTO PCMOV VALUES LINHA_ORIGINAL;
            
              INSERT INTO PCLOTEDESD
                (CODPROD,
                 NUMLOTEORIGEM,
                 NUMLOTEDESTINO,
                 NUMTRANSVENDADESTINO,
                 QTORIGEM,
                 QTDESTINO)
              VALUES
                (REGLOTESAIDAAJUSTE.CODPROD,
                 REGLOTESAIDAAJUSTE.NUMLOTE,
                 REGLOTES.NUMLOTE,
                 vNUMTRANSVENDA,
                 vQTSAIDA_AJUSTE,
                 vQTSAIDA_AJUSTE);
            
              vQTSAIDA_AJUSTE := 0;
            
            ELSE
            
              ---CASO LOTE NÃO TENHA TODA A QUANTIDADE PARA EFETUAR A SAÍDA NECESSÁRIA---
            
              SELECT *
                INTO LINHA_ORIGINAL
                FROM PCMOV
               WHERE ROWID = REGLOTESAIDAAJUSTE.ROWID;
            
              LINHA_ORIGINAL.NUMLOTE                 := REGLOTESAIDAAJUSTE.NUMLOTE;
              LINHA_ORIGINAL.QT                      := (REGLOTESAIDAAJUSTE.QT -
                                                        vQTJAULIZADASAIDAAJUSTE);
              LINHA_ORIGINAL.QTAVARIA                := REGLOTESAIDAAJUSTE.QTAVARIA;
              LINHA_ORIGINAL.QTBLOQUEADA             := 0;
              LINHA_ORIGINAL.CODOPER                 := 'SA';
              LINHA_ORIGINAL.NUMNOTA                 := 0;
              LINHA_ORIGINAL.CODCLI                  := 0;
              LINHA_ORIGINAL.CODUSUR                 := 0;
              LINHA_ORIGINAL.NUMTRANSENTORIGDESDLOTE := vNUMTRANSENTORIGINAL;
              LINHA_ORIGINAL.NUMTRANSENT             := 0;
              LINHA_ORIGINAL.NUMTRANSVENDA           := vNUMTRANSVENDA;
              LINHA_ORIGINAL.NUMTRANSITEM            := NULL;
            
              INSERT INTO PCMOV VALUES LINHA_ORIGINAL;
            
              INSERT INTO PCLOTEDESD
                (CODPROD,
                 NUMLOTEORIGEM,
                 NUMLOTEDESTINO,
                 NUMTRANSVENDADESTINO,
                 QTORIGEM,
                 QTDESTINO)
              VALUES
                (REGLOTESAIDAAJUSTE.CODPROD,
                 REGLOTESAIDAAJUSTE.NUMLOTE,
                 REGLOTES.NUMLOTE,
                 vNUMTRANSVENDA,
                 (REGLOTESAIDAAJUSTE.QT - vQTJAULIZADASAIDAAJUSTE),
                 (REGLOTESAIDAAJUSTE.QT - vQTJAULIZADASAIDAAJUSTE));
            
              vQTSAIDA_AJUSTE := vQTSAIDA_AJUSTE - (REGLOTESAIDAAJUSTE.QT -
                                 vQTJAULIZADASAIDAAJUSTE);
            
            END IF;
          
          END IF;
        
        END LOOP;
      
      END IF;
    
    END LOOP;
  
  END WMS_MOV_AJUSTE_LOTES;
  
      PROCEDURE WMS_MOV_AJUSTE_BONUS(pCodfilial IN VARCHAR2,pNumbonus  IN NUMBER) IS
    LINHA_ORIGINAL          PCMOV%ROWTYPE;
    vQT_AJUSTE              NUMBER(20, 6);
    vNUMTRANSVENDA          NUMBER(10);
    vNUMTRANSENT            NUMBER(10);
    vNUMTRANSENTORIGINAL    NUMBER(10);
    vNUMLANCAMENTO          NUMBER(10);
    vNUMBONUS               NUMBER(8);
    vCODFILIAL              VARCHAR2(2);
    vCODOPER                VARCHAR2(2);
    vTIPO                   VARCHAR2(2);
    vPOSSUI_AJUSTE          VARCHAR2(2);
  
  BEGIN
  
    vQT_AJUSTE              := 0;
    vNUMTRANSENT            := 0;
    vNUMTRANSVENDA          := 0;
    vNUMTRANSENTORIGINAL    := 0;
    vNUMLANCAMENTO          := 0;
    vCODOPER                := 'X';
    vPOSSUI_AJUSTE          := 'N';
  
    vNUMBONUS  := pNumbonus;
    vCODFILIAL := pCodfilial;
  
    SELECT DECODE(NVL(PROXNUMLANC, 0), 0, 1, PROXNUMLANC),
           NVL(PROXNUMTRANSENT, 1) AS PROXNUMTRANSENT,
           NVL(PROXNUMTRANSVENDA, 1) AS PROXNUMTRANSVENDA
      INTO vNUMLANCAMENTO, vNUMTRANSENT, vNUMTRANSVENDA
      FROM PCCONSUM
       FOR UPDATE;
  
    UPDATE PCCONSUM
       SET PROXNUMLANC       = DECODE(NVL(PROXNUMLANC, 0), 0, 1, PROXNUMLANC) + 1,
           PROXNUMTRANSENT   = NVL(PROXNUMTRANSENT, 1) + 1,
           PROXNUMTRANSVENDA = NVL(PROXNUMTRANSVENDA, 1) + 1;
  
    SELECT NUMTRANSENT
      INTO vNUMTRANSENTORIGINAL
      FROM PCMOV
     WHERE NUMBONUS = vNUMBONUS
       AND ROWNUM = 1;
       
    
    /**BUSCAR OS PRODUTOS FORAM CONFERIDOS COM QUANTIDADES DIVERGENTES NA NOTA E PRODUTOS ESTEJAM NA NOTA MAS NÃO TENHAM SIDO INFORMADOS NO RECEBIMENTO.**/
    FOR REG IN (SELECT B.NUMBONUS,B.CODPROD,B.DTVALIDADE,B.NUMLOTE,
                            SUM(B.QTENTRADA) AS QTENTRADA,
                            SUM(B.QTAVARIA) AS QTAVARIA,
                            MAX(B.QTNF) AS QTNF,
                            'PRODUTO CONFERIDO NO RECEBIMENTO' AS SITUACAO
                       FROM PCBONUSI B, PCPRODUT P, PCBONUSC C
                      WHERE B.NUMBONUS = vNUMBONUS
                        AND C.NUMBONUS = B.NUMBONUS
                        AND C.CODFILIAL = vCODFILIAL
                        AND B.CODPROD = P.CODPROD
                        AND P.ESTOQUEPORLOTE = 'N'
                      GROUP BY B.NUMBONUS,
                               B.CODPROD,
                               B.DTVALIDADE,
                               B.NUMLOTE

UNION ALL

SELECT M.NUMBONUS,M.CODPROD,M.DATAVALIDADE,M.NUMLOTE,
                            SUM(M.QT) AS QTENTRADA,
                            NVL(SUM(M.QTAVARIA),0) AS QTAVARIA,
                            MAX(M.QT) AS QTNF,
                            'PRODUTO EXISTE NA NOTA MAS NÃO FOI CONFERIDO NO RECEBIMENTO' AS SITUACAO
                       FROM PCMOV M, PCPRODUT P
                      WHERE M.NUMBONUS = vNUMBONUS
                        AND M.CODFILIAL = vCODFILIAL
                        AND M.CODPROD = P.CODPROD
                        AND P.ESTOQUEPORLOTE = 'N'
                        AND NOT EXISTS (SELECT 1 FROM PCBONUSI WHERE NUMBONUS = M.NUMBONUS AND CODPROD = M.CODPROD)
                        
                      GROUP BY M.NUMBONUS,
                               M.CODPROD,
                               M.DATAVALIDADE,
                               M.NUMLOTE )
    
     LOOP
     
      /**VERIFICANDO SE EXISTEM MOVIMENTACOES DE AJUSTES A SEREM GERADAS**/
      IF REG.SITUACAO = 'PRODUTO CONFERIDO NO RECEBIMENTO' THEN
        IF REG.QTENTRADA > REG.QTNF THEN
         vPOSSUI_AJUSTE := 'S';
         vCODOPER := 'EA';
         vTIPO := 'E';
         vQT_AJUSTE := REG.QTENTRADA - REG.QTNF;
        END IF;
        
        IF REG.QTENTRADA < REG.QTNF THEN
         vPOSSUI_AJUSTE := 'S';
         vCODOPER := 'SA';
         vTIPO := 'S';
         vQT_AJUSTE := REG.QTNF - REG.QTENTRADA;
        END IF;
        
      END IF;
      
      
      IF REG.SITUACAO = 'PRODUTO EXISTE NA NOTA MAS NÃO FOI CONFERIDO NO RECEBIMENTO' THEN
        
      vPOSSUI_AJUSTE := 'S';
      vCODOPER := 'SA';
      vTIPO := 'S';
      vQT_AJUSTE := REG.QTENTRADA;
      
      END IF;
      
      
      IF vPOSSUI_AJUSTE = 'S' THEN
        /**CLONANDO EM UMA VARIÁVEL O REGISTRO ORIGINAL DA PCMOV PARA GERAR A MOVIMENTACAO DE AJUSTE**/
        /** SELECT *
          INTO LINHA_ORIGINAL
          FROM PCMOV
         WHERE CODPROD = REG.CODPROD
           AND NUMBONUS = REG.NUMBONUS
           AND ROWNUM = 1;
      
        LINHA_ORIGINAL.NUMLOTE                 := '1';
        LINHA_ORIGINAL.QT                      := vQT_AJUSTE;
        LINHA_ORIGINAL.QTAVARIA                := REG.QTAVARIA;
        LINHA_ORIGINAL.QTBLOQUEADA             := 0;
        LINHA_ORIGINAL.CODOPER                 := vCODOPER;
        LINHA_ORIGINAL.NUMNOTA                 := 0;
        LINHA_ORIGINAL.CODCLI                  := 0;
        LINHA_ORIGINAL.CODUSUR                 := 0;
        LINHA_ORIGINAL.NUMTRANSVENDA           := 0;
        LINHA_ORIGINAL.NUMTRANSENTORIGDESDLOTE := vNUMTRANSENTORIGINAL;
        LINHA_ORIGINAL.NUMTRANSENT             := vNUMTRANSENT;
        LINHA_ORIGINAL.NUMTRANSITEM            := NULL;
        LINHA_ORIGINAL.DTMOV                   := TRUNC(SYSDATE);
      
        ---GERAR ENTRADA/SAIDA DE AJUSTE---
        INSERT INTO PCMOV VALUES LINHA_ORIGINAL;**/
        
        PKG_INTEGRACAOWMSSAAS.EFETUAR_AJUSTE_ESTOQUE(
    pCODFILIAL   => vCODFILIAL,
    pCODPROD     => REG.CODPROD,
    pQUANTIDADE  => vQT_AJUSTE,
    pTIPO        => vTIPO,
    pVALIDADE    => REG.DTVALIDADE,
    pNUMLOTE     => REG.NUMLOTE
  );
  
      END IF;
      
      vPOSSUI_AJUSTE := 'N';
         
    END LOOP;
  
  END WMS_MOV_AJUSTE_BONUS;

END PKG_RECEBIMENTO;