CREATE OR REPLACE PACKAGE BODY PKG_CONTINGENCIA_SVC IS

    V_NUMTRANSACAO PCNFSAID.NUMTRANSVENDA%TYPE;
    V_PROCESSO PCLOGFATURAMENTO.PROCESSO%TYPE;
                           
    PROCEDURE GERAR_LOG(P_MOVIMENTO IN VARCHAR2,
                        P_MENSAGEM  IN VARCHAR2) IS
       PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
      INSERT INTO PCLOGFATURAMENTO
                  (CODLOG
                 , DATAHORA
                 , MAQUINA
                 , TERMINAL
                 , OSUSER
                 , PROCESSO
                 , CODIGOIDENTIFICADOR
                 , TIPOLOG
                 , LOG)
           VALUES (DFSEQ_PCLOGFATURAMENTO.NEXTVAL
                 , SYSDATE
                 , SYS_CONTEXT('USERENV', 'TERMINAL')
                 , SYS_CONTEXT('USERENV', 'MODULE')
                 , SYS_CONTEXT('USERENV', 'OS_USER')
                 , V_PROCESSO
                 , V_NUMTRANSACAO
                 , DECODE(P_MOVIMENTO, 'S', 'SAIDA', 'ENTRADA')
                 , P_MENSAGEM);
        COMMIT;
    END GERAR_LOG;
    
    FUNCTION OBTER_CFOPINVERSO(P_CODFISCAL IN NUMBER) 
      RETURN NUMBER IS
      V_CFOPINVERSO NUMBER := 0;
    BEGIN
      SELECT NVL(CFOPINVERSO, 0) INTO V_CFOPINVERSO FROM PCCFO WHERE CODFISCAL = P_CODFISCAL;
      RETURN V_CFOPINVERSO;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN V_CFOPINVERSO;
    END;
       
    FUNCTION DUPLICARNFE(P_CODFILIAL    IN VARCHAR2,
                         P_NUMNOTA      IN NUMBER,
                         P_SERIE        IN VARCHAR2,
                         P_CHAVENFE     IN VARCHAR2,
                         P_PROTOCOLONFE IN VARCHAR2,
                         P_SITUACAONFE  IN NUMBER,
                         P_TIPOMOV      IN VARCHAR2,
                         P_MENSAGEM     OUT VARCHAR2)
      RETURN BOOLEAN IS
      V_RETORNO BOOLEAN := FALSE;
      V_ENCONTROUNOTA BOOLEAN := FALSE;
      V_NUMTRANSITEMORIGINAL PCMOV.NUMTRANSITEM%TYPE;
      V_RETORNOPKGESTOQUE INTEGER;      
      VMSG_RETORNORECALCULOESTOQUE VARCHAR2(1000);      
    BEGIN
      P_MENSAGEM := '';
      V_PROCESSO := 'DUPLICARNFE';
      --DUPLICAR NOTA EM SVC
      
      IF P_TIPOMOV = 'S' THEN
        FOR DADOS IN (SELECT PCINUTILIZARNFE.NUMTRANSACAO
                           , PCINUTILIZARNFE.NUMNOTA
                           , NVL(PCINUTILIZARNFE.NUMTRANSACAONOVA, 0) NUMTRANSACAONOVA
                           , (CASE WHEN (PCNFSAID.DTCANCEL IS NOT NULL) AND (NVL(PCNFSAID.VLTOTAL, 0) = 0) THEN 'S' ELSE 'N' END) NF_ORIGEM_CANCELADA
                           , (SELECT SUM(ROUND(QTCONT * NVL(PUNITCONT,PUNIT),2))
                                FROM PCMOV
                               WHERE NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA
                                 AND NVL(QTCONT,QT)> 0) AS NF_ORIGEM_VLTOTAL
                           , PCNFSAID.ROWID REGISTRO
                        FROM PCINUTILIZARNFE, PCNFSAID
                       WHERE PCNFSAID.NUMTRANSVENDA = PCINUTILIZARNFE.NUMTRANSACAO
                         AND NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL) = P_CODFILIAL
                         AND PCINUTILIZARNFE.NUMNOTA = P_NUMNOTA
                         AND PCINUTILIZARNFE.SERIE = P_SERIE
                         AND PCINUTILIZARNFE.TIPOMOV = P_TIPOMOV) 
        LOOP
          V_ENCONTROUNOTA := TRUE;
          V_NUMTRANSACAO := DADOS.NUMTRANSACAO;
          IF DADOS.NUMTRANSACAONOVA <= 0 THEN
            SELECT * INTO CAB_SAIDA
              FROM PCNFSAID
             WHERE ROWID = DADOS.REGISTRO;
          
            CAB_SAIDA.NUMTRANSVENDA            := FERRAMENTAS.F_PROX_NUMTRANSVENDA;
            CAB_SAIDA.NUMNOTA                  := DADOS.NUMNOTA;
            CAB_SAIDA.ESPECIE                  := 'NF';
            CAB_SAIDA.SITUACAONFE              := P_SITUACAONFE;
            CAB_SAIDA.SERIE                    := P_SERIE;
            CAB_SAIDA.CHAVENFE                 := P_CHAVENFE;
            CAB_SAIDA.PROTOCOLONFE             := P_PROTOCOLONFE;
            CAB_SAIDA.CONDVENDA                := 4;
            CAB_SAIDA.TIPOVENDA                := 'VP';
            CAB_SAIDA.NOTADUPLIQUESVC          := 'S';
            CAB_SAIDA.DTCANCEL                 := NULL;
            CAB_SAIDA.OBS                      := 'NOTA FISCAL DUPLICADA. NUMTRANSVENDA REF: ' || DADOS.NUMTRANSACAO;
            CAB_SAIDA.TIPOEMISSAO              := SUBSTR(CAB_SAIDA.CHAVENFE, 35, 1);
            CAB_SAIDA.VLTOTGER                 := 0;
            CAB_SAIDA.TIPOVENDA                := 'S';
            CAB_SAIDA.CODFUNCCANCEL            := NULL;
            CAB_SAIDA.DTCANCELWMS              := NULL;
            CAB_SAIDA.NUMTRANSENTORIGEM        := NULL;
            CAB_SAIDA.UIDREGISTRO              := NULL;
            CAB_SAIDA.IDPARCEIRO               := NULL;
            CAB_SAIDA.NUMCAR                   := NULL;
            CAB_SAIDA.NUMPED                   := NULL;
            CAB_SAIDA.DTHORAAUTORIZACAOSEFAZ   := NULL;
            
            IF (DADOS.NF_ORIGEM_CANCELADA = 'S') THEN
              CAB_SAIDA.VLTOTAL := DADOS.NF_ORIGEM_VLTOTAL;
            END IF;
             
            V_NUMTRANSACAO := CAB_SAIDA.NUMTRANSVENDA;     
            INSERT INTO PCNFSAID VALUES CAB_SAIDA;
            
            FOR REG IN (SELECT ROWID ID
                          FROM PCMOV
                         WHERE NUMTRANSVENDA = DADOS.NUMTRANSACAO
                           AND NVL(QTCONT, QT) > 0) LOOP
              
              SELECT * INTO ITEM FROM PCMOV WHERE ROWID = REG.ID;         
              
              ITEM.NUMTRANSVENDA := CAB_SAIDA.NUMTRANSVENDA;
              ITEM.NUMNOTA       := CAB_SAIDA.NUMNOTA;
              ITEM.NUMPED        := NULL;
              ITEM.NUMCAR        := NULL;  
              ITEM.NUMBONUS      := NULL;
                
              ITEM.STATUS := 'A';
              IF NVL(ITEM.TIPOITEM, 'N') = 'C' THEN
                ITEM.STATUS:= 'B';
              END IF;
                
              ITEM.QTDEVOL       := 0;
              ITEM.DTCANCEL      := NULL;
              ITEM.QT            := 0;
              ITEM.CODOPER       := 'S';
              ITEM.MOVESTOQUEGERENCIAL := 'N';
              ITEM.MOVESTOQUECONTABIL  := 'S';
              ITEM.DATAESTOQUE   := NULL;
              
              IF ITEM.NUMTRANSITEM IS NOT NULL THEN
                V_NUMTRANSITEMORIGINAL := ITEM.NUMTRANSITEM;
                
                SELECT DFSEQ_PCMOVCOMPLE.NEXTVAL
                  INTO ITEM.NUMTRANSITEM
                  FROM DUAL;
              END IF;
              
              INSERT INTO PCMOV VALUES ITEM;
              
              IF ITEM.NUMTRANSITEM IS NOT NULL THEN
                BEGIN
                  SELECT *
                    INTO ITEMCOMPLE
                    FROM PCMOVCOMPLE
                   WHERE NUMTRANSITEM = V_NUMTRANSITEMORIGINAL;
                  
                  ITEMCOMPLE.NUMTRANSITEM := ITEM.NUMTRANSITEM;
                  
                  INSERT INTO PCMOVCOMPLE VALUES ITEMCOMPLE;
                EXCEPTION
                  WHEN OTHERS THEN
                    NULL;
                END;
              END IF;
            END LOOP;
              
           UPDATE PCINUTILIZARNFE
              SET NUMTRANSACAONOVA = CAB_SAIDA.NUMTRANSVENDA
            WHERE NUMTRANSACAO = DADOS.NUMTRANSACAO
              AND NUMNOTA = DADOS.NUMNOTA
              AND TIPOMOV = P_TIPOMOV
              AND CHAVENFE = CAB_SAIDA.CHAVENFE;
             
            V_RETORNOPKGESTOQUE := PKG_ESTOQUE.VENDAS_SAIDA(CAB_SAIDA.NUMTRANSVENDA, 'N', VMSG_RETORNORECALCULOESTOQUE);
            IF NVL(V_RETORNOPKGESTOQUE, 0) <= 0 THEN
              ROLLBACK;
              P_MENSAGEM := 'OCORREU UM ERRO AO MOVIMENTAR O ESTOQUE.' || ' - ' || VMSG_RETORNORECALCULOESTOQUE;
              GERAR_LOG(P_TIPOMOV, VMSG_RETORNORECALCULOESTOQUE);
            ELSE 
              COMMIT;
              v_RETORNO := TRUE;
              GERAR_LOG(P_TIPOMOV, 'NOTA SVC CRIADA COM SUCESSO.');
            END IF;
          ELSE
            P_MENSAGEM := 'NOTA FISCAL JÁ CONSTA COMO DUPLICADA.';
            GERAR_LOG(P_TIPOMOV, P_MENSAGEM);
          END IF;  
        END LOOP;
                
      ELSIF P_TIPOMOV = 'E' THEN
        
        FOR DADOS IN (SELECT PCINUTILIZARNFE.NUMTRANSACAO
                           , PCINUTILIZARNFE.NUMNOTA
                           , NVL(PCINUTILIZARNFE.NUMTRANSACAONOVA, 0) NUMTRANSACAONOVA
                           , (CASE WHEN (PCNFENT.DTCANCEL IS NOT NULL) AND (NVL(PCNFENT.VLTOTAL, 0) = 0) THEN 'S' ELSE 'N' END) NF_ORIGEM_CANCELADA
                           , (SELECT SUM(ROUND(QTCONT * NVL(PUNITCONT,PUNIT),2))
                                FROM PCMOV
                               WHERE NUMTRANSENT = PCNFENT.NUMTRANSENT
                                 AND NVL(QTCONT,QT)> 0) AS NF_ORIGEM_TOTAL
                           , PCNFENT.ROWID REGISTRO
                      FROM PCINUTILIZARNFE, PCNFENT
                     WHERE PCNFENT.NUMTRANSENT = PCINUTILIZARNFE.NUMTRANSACAO
                       AND NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = P_CODFILIAL
                       AND PCINUTILIZARNFE.NUMNOTA = P_NUMNOTA
                       AND PCINUTILIZARNFE.SERIE = P_SERIE
                       AND PCINUTILIZARNFE.TIPOMOV = P_TIPOMOV
                       AND PCNFENT.ESPECIE IN ('NE', 'NF'))
        LOOP
          V_ENCONTROUNOTA := TRUE;
          V_NUMTRANSACAO := DADOS.NUMTRANSACAO;
          IF DADOS.NUMTRANSACAONOVA <= 0 THEN
            SELECT *
              INTO CAB_ENT
              FROM PCNFENT
             WHERE ROWID = DADOS.REGISTRO;
          
            CAB_ENT.NUMTRANSENT     := FERRAMENTAS.F_PROX_NUMTRANSENT;
            CAB_ENT.NUMNOTA         := DADOS.NUMNOTA;
            CAB_ENT.ESPECIE         := 'NF';
            CAB_ENT.SITUACAONFE     := P_SITUACAONFE;
            CAB_ENT.SERIE           := P_SERIE;
            CAB_ENT.CHAVENFE        := P_CHAVENFE;
            CAB_ENT.PROTOCOLONFE    := P_PROTOCOLONFE;
            CAB_ENT.NOTADUPLIQUESVC := 'S';
            CAB_ENT.DTCANCEL        := NULL;
            CAB_ENT.OBS             := 'NOTA FISCAL DUPLICADA. NUMTRANSENT REF: ' || DADOS.NUMTRANSACAO;
            CAB_ENT.TIPOEMISSAO     := SUBSTR(CAB_ENT.CHAVENFE, 35, 1);
            CAB_ENT.DTHORAAUTORIZACAOSEFAZ := NULL;
            
            IF (DADOS.NF_ORIGEM_CANCELADA = 'S') THEN
              CAB_ENT.VLTOTAL := DADOS.NF_ORIGEM_TOTAL;
            END IF;                        
          
            V_NUMTRANSACAO := CAB_ENT.NUMTRANSENT;
            INSERT INTO PCNFENT VALUES CAB_ENT;
            
            FOR REG IN (SELECT ROWID ID
                          FROM PCMOV
                         WHERE NUMTRANSENT = DADOS.NUMTRANSACAO
                           AND NVL(QTCONT,QT) > 0) LOOP
            
              SELECT * INTO ITEM FROM PCMOV WHERE ROWID = REG.ID;
            
              ITEM.NUMTRANSENT := CAB_ENT.NUMTRANSENT;
              ITEM.NUMNOTA     := CAB_ENT.NUMNOTA;
              ITEM.STATUS      := 'A';
              ITEM.QTDEVOL     := 0;
              ITEM.DTCANCEL    := NULL;
              ITEM.QT          := 0;
              ITEM.NUMPED      := NULL;
              ITEM.NUMCAR      := NULL;  
              ITEM.NUMBONUS    := NULL;
              ITEM.MOVESTOQUEGERENCIAL := 'N';
              ITEM.MOVESTOQUECONTABIL  := 'S';
              ITEM.DATAESTOQUE := NULL;
              
              ITEM.STATUS := 'A';
              IF NVL(ITEM.TIPOITEM, 'N') = 'C' THEN
                ITEM.STATUS:= 'B';
              END IF;
            
              IF ITEM.NUMTRANSITEM IS NOT NULL THEN
                V_NUMTRANSITEMORIGINAL := ITEM.NUMTRANSITEM;
              
                SELECT DFSEQ_PCMOVCOMPLE.NEXTVAL
                  INTO ITEM.NUMTRANSITEM
                  FROM DUAL;
              END IF;
            
              INSERT INTO PCMOV VALUES ITEM;
            
              IF ITEM.NUMTRANSITEM IS NOT NULL THEN
                BEGIN
                  SELECT *
                    INTO ITEMCOMPLE
                    FROM PCMOVCOMPLE
                   WHERE NUMTRANSITEM = V_NUMTRANSITEMORIGINAL;
                
                  ITEMCOMPLE.NUMTRANSITEM := ITEM.NUMTRANSITEM;
                
                  INSERT INTO PCMOVCOMPLE VALUES ITEMCOMPLE;
                EXCEPTION
                  WHEN OTHERS THEN
                    NULL;
                END;              
              END IF;
            END LOOP;
          
            UPDATE PCINUTILIZARNFE
               SET NUMTRANSACAONOVA = CAB_ENT.NUMTRANSENT
             WHERE NUMTRANSACAO = DADOS.NUMTRANSACAO
               AND NUMNOTA = DADOS.NUMNOTA
               AND CHAVENFE = P_CHAVENFE
               AND TIPOMOV = P_TIPOMOV;           
             
            V_RETORNOPKGESTOQUE := PKG_ESTOQUE.VENDAS_ENTRADA(CAB_ENT.NUMTRANSENT, 'N', VMSG_RETORNORECALCULOESTOQUE);
            IF NVL(V_RETORNOPKGESTOQUE, 0) <= 0 THEN
              ROLLBACK;
              P_MENSAGEM := 'OCORREU UM ERRO AO MOVIMENTAR O ESTOQUE.'|| ' - ' || VMSG_RETORNORECALCULOESTOQUE;
              GERAR_LOG(P_TIPOMOV, VMSG_RETORNORECALCULOESTOQUE);
            ELSE 
              COMMIT;
              v_RETORNO := TRUE;
              GERAR_LOG(P_TIPOMOV, 'NOTA SVC CRIADA COM SUCESSO.');
            END IF;
          ELSE
            P_MENSAGEM := 'NOTA FISCAL JÁ CONSTA COMO DUPLICADA.';
            GERAR_LOG(P_TIPOMOV, P_MENSAGEM);
          END IF;
        END LOOP;
      END IF;
      
      IF (NOT V_ENCONTROUNOTA) THEN
         P_MENSAGEM := 'NÃO ENCONTRAMOS A NFE: '||P_NUMNOTA||' NA FILIAL: '||P_CODFILIAL||' PARA DUPLICAR.';
         GERAR_LOG(P_TIPOMOV, P_MENSAGEM);
      END IF;
      
      RETURN v_RETORNO;
    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        P_MENSAGEM := SQLCODE || '-' || SQLERRM || CHR(13) || 'ERRO EM DUPLICARNFE!'|| ' - ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
        GERAR_LOG(P_TIPOMOV, P_MENSAGEM);
        RETURN v_RETORNO;
    END DUPLICARNFE;
      
    FUNCTION CANCELAR_NUMERACAONFE(P_CODFILIAL             IN VARCHAR2,
                                   P_DTEMISSAO             IN DATE,
                                   P_NUMNOTA               IN NUMBER,
                                   P_CODCLIFORNEC          IN NUMBER,
                                   P_CHAVENFE              IN VARCHAR2,
                                   P_PROTOCOLOCANCELAMENTO IN VARCHAR2,
                                   P_DTCANCEL              IN DATE,
                                   P_TIPOMOV               IN VARCHAR2,
                                   P_MENSAGEM              OUT VARCHAR2)
      RETURN BOOLEAN IS
      v_RETORNO BOOLEAN := FALSE;
      V_NUMTRANSITEMORIGINAL PCMOV.NUMTRANSITEM%TYPE;
      V_NUMTRANSACAOGERADA PCNFSAID.NUMTRANSVENDA%TYPE;
      V_DTNOTA PCNFSAID.DTSAIDA%TYPE;
      V_TOTAL_NOTA PCNFSAID.VLTOTAL%TYPE;
      V_RETORNOPKGESTOQUE INTEGER;
      VMSG_RETORNORECALCULOESTOQUE VARCHAR2(1000);      
    BEGIN
      P_MENSAGEM := '';
      V_PROCESSO := 'CANCELAR_NUMERACAONFE';
      --CANCELAR NUMERAÇÃO DE NF DE SVC
      
      IF P_TIPOMOV = 'S' THEN
        BEGIN
          SELECT PCNFSAID.NUMTRANSVENDA, PCNFSAID.DTSAIDA, PCNFSAID.VLTOTAL
            INTO V_NUMTRANSACAOGERADA, V_DTNOTA, V_TOTAL_NOTA
            FROM PCNFSAID, PCFILIAL
           WHERE PCNFSAID.NUMNOTA = P_NUMNOTA
             AND NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL) = PCFILIAL.CODIGO
             AND PCNFSAID.ESPECIE = 'NF'
             AND PCNFSAID.NOTADUPLIQUESVC = 'S'
             AND PCFILIAL.CODIGO = P_CODFILIAL
             AND PCNFSAID.DTSAIDA = P_DTEMISSAO
             AND PCNFSAID.CHAVENFE = P_CHAVENFE
             AND PCNFSAID.DTCANCEL IS NULL
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            V_NUMTRANSACAOGERADA := 0;
        END;
        
        V_NUMTRANSACAO := V_NUMTRANSACAOGERADA;
        IF NVL(V_NUMTRANSACAOGERADA, 0) <> 0 THEN
          UPDATE PCNFSAID
             SET SITUACAONFE = 101
               , DTCANCEL = TRUNC(P_DTCANCEL)
               , PROTOCOLOCANCELAMENTO = P_PROTOCOLOCANCELAMENTO
               , VLTOTAL = 0
               , ICMSRETIDO = 0
               , BCST = 0
               , VLDESCONTO = 0
               , VLIPI = 0
               , VLBASEIPI = 0
               , VLFRETE = 0
               , VLOUTRASDESP = 0
               , PERCICMFRETE = 0
               , ALIQICMOUTRASDESP = 0
               , NUMPED = NULL
               , NUMCAR = NULL
           WHERE NUMTRANSVENDA = V_NUMTRANSACAOGERADA;
        
          INSERT INTO PCNFCAN
                      (NUMTRANSVENDA
                     , CODFUNCCANC
                     , DATACANC
                     , CODCLI
                     , MOTIVO
                     , CODFUNCEMITE
                     , DATAEMISSAO
                     , VLTOTAL
                     , CODROTINA
                     , DESCRICAO
                     , NUMPED
                     , CODFILIAL
                     , DTDENEGADA
                     , HORADENEGADA)
               VALUES (V_NUMTRANSACAOGERADA
                     , 1
                     , P_DTEMISSAO
                     , P_CODCLIFORNEC
                     , 'NF CANCELADA'
                     , 1
                     , P_DTEMISSAO
                     , V_TOTAL_NOTA
                     , 1452
                     , NULL
                     , NULL
                     , P_CODFILIAL
                     , NULL
                     , NULL);
                     
          FOR REG IN (SELECT ROWID ID
                        FROM PCMOV
                       WHERE PCMOV.NUMTRANSVENDA = V_NUMTRANSACAOGERADA
                         AND PCMOV.QTCONT > 0) LOOP
          
            SELECT * INTO ITEM FROM PCMOV WHERE ROWID = REG.ID;
          
            ITEM.NUMTRANSVENDA := V_NUMTRANSACAOGERADA;
            ITEM.NUMNOTA       := P_NUMNOTA;
            ITEM.STATUS        := 'A';
            ITEM.QT            := 0;
            ITEM.DTCANCEL      := TRUNC(SYSDATE);
            ITEM.QTDEVOL       := 0;
            ITEM.TIPOITEM      := 'N';
            ITEM.NUMBONUS      := NULL;
            ITEM.DATAESTOQUE   := NULL;
            ITEM.QTCONT        := ITEM.QTCONT * (-1);
            ITEM.MOVESTOQUEGERENCIAL := 'N';
            ITEM.MOVESTOQUECONTABIL  := 'S';
          
            IF (ITEM.NUMTRANSITEM IS NOT NULL) THEN
              V_NUMTRANSITEMORIGINAL := ITEM.NUMTRANSITEM;
            
              SELECT DFSEQ_PCMOVCOMPLE.NEXTVAL
                INTO ITEM.NUMTRANSITEM
                FROM DUAL;
            END IF;          
          
            INSERT INTO PCMOV VALUES ITEM;
            UPDATE PCMOV SET DTCANCEL = TRUNC(SYSDATE) WHERE ROWID = REG.ID;
          
            IF (ITEM.NUMTRANSITEM IS NOT NULL) THEN
              BEGIN
                SELECT *
                  INTO ITEMCOMPLE
                  FROM PCMOVCOMPLE
                 WHERE NUMTRANSITEM = V_NUMTRANSITEMORIGINAL;
              
                ITEMCOMPLE.NUMTRANSITEM := ITEM.NUMTRANSITEM;
                INSERT INTO PCMOVCOMPLE VALUES ITEMCOMPLE;
              EXCEPTION
                WHEN OTHERS THEN
                  NULL;
              END;
            END IF;
          END LOOP;
          
          V_RETORNOPKGESTOQUE := PKG_ESTOQUE.VENDAS_SAIDA(V_NUMTRANSACAOGERADA, 'S', VMSG_RETORNORECALCULOESTOQUE);  
          IF NVL(V_RETORNOPKGESTOQUE, 0) <= 0 THEN
            ROLLBACK;
            P_MENSAGEM := 'OCORREU UM ERRO AO MOVIMENTAR O ESTOQUE.'|| ' - ' || VMSG_RETORNORECALCULOESTOQUE;
            GERAR_LOG(P_TIPOMOV, VMSG_RETORNORECALCULOESTOQUE);
          ELSE 
            COMMIT;
            v_RETORNO := TRUE;
            GERAR_LOG(P_TIPOMOV, 'NOTA SVC CANCELADA COM SUCESSO.');
          END IF;
        ELSE
          P_MENSAGEM := 'NÃO ENCONTRAMOS REGISTROS DE SVC PARA CANCELAR.';
          GERAR_LOG(P_TIPOMOV, P_MENSAGEM);
        END IF;
        
      ELSIF P_TIPOMOV = 'E' THEN
        
        BEGIN
          SELECT PCNFENT.NUMTRANSENT, PCNFENT.DTENT, PCNFENT.VLTOTAL
            INTO V_NUMTRANSACAOGERADA, V_DTNOTA, V_TOTAL_NOTA
            FROM PCNFENT, PCFILIAL
           WHERE PCNFENT.NUMNOTA = P_NUMNOTA
             AND NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = PCFILIAL.CODIGO
             AND PCNFENT.ESPECIE = 'NF'
             AND PCNFENT.NOTADUPLIQUESVC = 'S'
             AND PCFILIAL.CODIGO = P_CODFILIAL
             AND PCNFENT.DTSAIDA = P_DTEMISSAO
             AND PCNFENT.CHAVENFE = P_CHAVENFE
             AND PCNFENT.DTCANCEL IS NULL
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            V_NUMTRANSACAOGERADA := 0;
        END;
      
        V_NUMTRANSACAO := V_NUMTRANSACAOGERADA;
        IF NVL(V_NUMTRANSACAOGERADA, 0) <> 0 THEN
          UPDATE PCNFENT
             SET SITUACAONFE = 101
               , DTCANCEL = TRUNC(P_DTCANCEL)
               , PROTOCOLOCANCELAMENTO = P_PROTOCOLOCANCELAMENTO
               , VLTOTAL = 0
               , VLST = 0
               , BASEICST = 0
               , VLDESCONTO = 0
               , VLIPI = 0
               , VLBASEIPI = 0
               , VLFRETE = 0
               , VLOUTRAS = 0
               , PERBASEREDOUTRASDESP = 0
               , PERCICMFRETE = 0
               , ALIQICMOUTRASDESP = 0
           WHERE NUMTRANSENT = V_NUMTRANSACAOGERADA;
           
          INSERT INTO PCNFCAN
                      (NUMTRANSENT
                     , CODFUNCCANC
                     , DATACANC
                     , CODCLI
                     , MOTIVO
                     , CODFUNCEMITE
                     , DATAEMISSAO
                     , VLTOTAL
                     , CODROTINA
                     , DESCRICAO
                     , NUMPED
                     , CODFILIAL
                     , DTDENEGADA
                     , HORADENEGADA)
               VALUES (V_NUMTRANSACAOGERADA
                     , 1
                     , P_DTEMISSAO
                     , P_CODCLIFORNEC
                     , 'NF CANCELADA'
                     , 1
                     , P_DTEMISSAO
                     , V_TOTAL_NOTA
                     , 1452
                     , NULL
                     , NULL
                     , P_CODFILIAL
                     , NULL
                     , NULL); 
                     
          FOR REG IN (SELECT ROWID ID
                        FROM PCMOV
                       WHERE PCMOV.NUMTRANSENT = V_NUMTRANSACAOGERADA
                         AND PCMOV.QTCONT > 0) LOOP
          
            SELECT * INTO ITEM FROM PCMOV WHERE ROWID = REG.ID;
          
            ITEM.NUMTRANSENT := V_NUMTRANSACAOGERADA;
            ITEM.NUMNOTA     := P_NUMNOTA;
            ITEM.STATUS      := 'A';
            ITEM.QT          := 0;
            ITEM.DTCANCEL    := TRUNC(SYSDATE);
            ITEM.QTDEVOL     := 0;
            ITEM.NUMBONUS    := NULL;
            ITEM.QTCONT      := ITEM.QTCONT * (-1);
            ITEM.DATAESTOQUE := NULL;
            ITEM.MOVESTOQUEGERENCIAL := 'N';
            ITEM.MOVESTOQUECONTABIL  := 'S';
          
            IF (ITEM.NUMTRANSITEM IS NOT NULL) THEN
              V_NUMTRANSITEMORIGINAL := ITEM.NUMTRANSITEM;
            
              SELECT DFSEQ_PCMOVCOMPLE.NEXTVAL
                INTO ITEM.NUMTRANSITEM
                FROM DUAL;
            END IF;
          
            INSERT INTO PCMOV VALUES ITEM;
            UPDATE PCMOV SET DTCANCEL = TRUNC(SYSDATE) WHERE ROWID = REG.ID;
          
            IF (ITEM.NUMTRANSITEM IS NOT NULL) THEN
              BEGIN
                SELECT *
                  INTO ITEMCOMPLE
                  FROM PCMOVCOMPLE
                 WHERE NUMTRANSITEM = V_NUMTRANSITEMORIGINAL;
              
                ITEMCOMPLE.NUMTRANSITEM := ITEM.NUMTRANSITEM;
                INSERT INTO PCMOVCOMPLE VALUES ITEMCOMPLE;
              EXCEPTION
                WHEN OTHERS THEN
                  NULL;
              END;
            END IF;
          END LOOP; 
          
          V_RETORNOPKGESTOQUE := PKG_ESTOQUE.VENDAS_ENTRADA(V_NUMTRANSACAOGERADA, 'S', VMSG_RETORNORECALCULOESTOQUE);
          IF NVL(V_RETORNOPKGESTOQUE, 0) <= 0 THEN
            ROLLBACK;
            P_MENSAGEM := 'OCORREU UM ERRO AO MOVIMENTAR O ESTOQUE.'|| ' - ' || VMSG_RETORNORECALCULOESTOQUE;
            GERAR_LOG(P_TIPOMOV, VMSG_RETORNORECALCULOESTOQUE);
          ELSE 
            COMMIT;
            v_RETORNO := TRUE;
            GERAR_LOG(P_TIPOMOV, 'NOTA SVC CANCELADA COM SUCESSO.');
          END IF;
        ELSE
          P_MENSAGEM := 'NÃO ENCONTRAMOS REGISTROS DE SVC PARA CANCELAR.';
          GERAR_LOG(P_TIPOMOV, P_MENSAGEM);          
        END IF;
      END IF;
      
      RETURN v_RETORNO;         
    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        P_MENSAGEM := SQLCODE || '-' || SQLERRM || CHR(13) || 'ERRO EM CANCELAR_NUMERACAONFE!' || ' - ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
        GERAR_LOG(P_TIPOMOV, P_MENSAGEM);
        RETURN v_RETORNO;      
    END CANCELAR_NUMERACAONFE;
    
    FUNCTION GETCOLUNAS(P_TABELAA IN VARCHAR2,
                        P_TABELAB IN VARCHAR2) 
      RETURN VARCHAR2 IS
      VS_SCRIPT VARCHAR2(32767);
    BEGIN
       FOR COLUNAS IN (SELECT ROWNUM IDR
                            , TBL.COLUMN_NAME
                         FROM (SELECT COLUMN_NAME
                                 FROM USER_TAB_COLS
                                WHERE TABLE_NAME = P_TABELAA
                            INTERSECT
                               SELECT COLUMN_NAME
                                 FROM USER_TAB_COLS
                                WHERE TABLE_NAME = P_TABELAB
                             ORDER BY 1) TBL
                        WHERE TBL.COLUMN_NAME NOT IN ('NUMTRANSENT', 'NUMTRANSVENDA', 'CODCLI', 'CODFORNEC')
                     ORDER BY 1)
       LOOP
          IF COLUNAS.IDR = 1 THEN
             VS_SCRIPT := VS_SCRIPT || COLUNAS.COLUMN_NAME || CHR(13);
          ELSE
             VS_SCRIPT := VS_SCRIPT || ',' || COLUNAS.COLUMN_NAME || CHR(13);
          END IF;
       END LOOP;
       
       RETURN VS_SCRIPT;
    END GETCOLUNAS;      
      
    FUNCTION GERARCONTRAPARTIDA(P_NUMTRANSACAO IN NUMBER,
                                P_TIPOMOV      IN VARCHAR2,
                                P_MENSAGEM     OUT VARCHAR2)
      RETURN BOOLEAN IS
      V_RETORNO BOOLEAN := FALSE;
      V_CFOPINVERSO PCCFO.CFOPINVERSO%TYPE;
      V_NUMTRANSACAO PCNFSAID.NUMTRANSVENDA%TYPE;
      V_NUMTRANSITEMORIGINAL PCMOV.NUMTRANSITEM%TYPE;
      V_RETORNOPKGESTOQUE INTEGER;
      EXC_CFOP EXCEPTION;
      VS_SCRIPT VARCHAR2(32767);
      VMSG_RETORNORECALCULOESTOQUE VARCHAR2(1000);      
    BEGIN
      P_MENSAGEM := '';
      V_PROCESSO := 'GERARCONTRAPARTIDA';
      V_NUMTRANSACAO := P_NUMTRANSACAO;
      --GERAR NOTA DE DEVOLUÇÃO DE DUPLICAÇÃO SVC
      
      IF P_TIPOMOV = 'S' THEN
        BEGIN
          SELECT PCNFSAID.*
            INTO CAB_SAIDA
            FROM PCNFSAID
           WHERE PCNFSAID.NUMTRANSVENDA = P_NUMTRANSACAO
             AND NOT EXISTS(SELECT 1 FROM PCNFENT WHERE NUMTRANSVENDAORIG = PCNFSAID.NUMTRANSVENDA)
             AND PCNFSAID.SITUACAONFE = 100
             AND PCNFSAID.ESPECIE = 'NF'
             AND PCNFSAID.NOTADUPLIQUESVC = 'S'
             AND PCNFSAID.DTCANCEL IS NULL
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            P_MENSAGEM := 'NOTA DE SAÍDA DE SVC NÃO ENCONTRADA OU CONTRAPARTIDA JÁ REALIZADA.';
            GERAR_LOG(P_TIPOMOV, P_MENSAGEM);
            RETURN v_RETORNO; 
        END; 
        
        V_NUMTRANSACAO := FERRAMENTAS.F_PROX_NUMTRANSENT;
        VS_SCRIPT := GETCOLUNAS('PCNFENT', 'PCNFSAID');
        VS_SCRIPT := 'INSERT INTO PCNFENT (NUMTRANSENT, CODFORNEC, '||VS_SCRIPT||') 
                      SELECT '||V_NUMTRANSACAO||','||CAB_SAIDA.CODCLI||','||VS_SCRIPT||' FROM PCNFSAID WHERE NUMTRANSVENDA = '||P_NUMTRANSACAO;
        EXECUTE IMMEDIATE VS_SCRIPT;
        
        SELECT * INTO CAB_ENT FROM PCNFENT WHERE NUMTRANSENT = V_NUMTRANSACAO;
        
        CAB_ENT.ESPECIE         := 'NE';
        CAB_ENT.SITUACAONFE     := 0;
        CAB_ENT.CHAVENFE        := '';
        CAB_ENT.PROTOCOLONFE    := '';
        CAB_ENT.NOTADUPLIQUESVC := '';
        CAB_ENT.OBS             := 'NFE DE CONTRAPARTIDA. NUMTRANSVENDA REF: ' || P_NUMTRANSACAO;
        CAB_ENT.TIPOEMISSAO     := '1';
        CAB_ENT.CONSUMIUNUMNFE  := 'N';
        CAB_ENT.TIPODESCARGA    := '8';
        CAB_ENT.FINALIDADENFE   := '1';
        CAB_ENT.GERANFDEVCLI    := 'S';
        CAB_ENT.DTEMISSAO       := TRUNC(SYSDATE);
        CAB_ENT.DTSAIDA         := TRUNC(SYSDATE);
        CAB_ENT.DTENT           := TRUNC(SYSDATE);
        CAB_ENT.NUMTRANSVENDAORIG      := P_NUMTRANSACAO;        
        CAB_ENT.DTHORAAUTORIZACAOSEFAZ := NULL;
        
        UPDATE PCNFENT E SET ROW = CAB_ENT WHERE E.NUMTRANSENT = V_NUMTRANSACAO;
        
        INSERT INTO PCDOCREFERENCIADO
                    (CODIGO
                   , NUMTRANSACAO
                   , TIPO
                   , CHAVENFEREF
                   , NUMNOTAREF
                   , SERIEREF
                   , MODELOREF
                   , DTEMISSAOREF)
             VALUES (DFSEQ_PCDOCREFERENCIADO.NEXTVAL
                   , V_NUMTRANSACAO
                   , 'E'
                   , CAB_SAIDA.CHAVENFE
                   , CAB_SAIDA.NUMNOTA
                   , CAB_SAIDA.SERIE
                   , '55'
                   , CAB_SAIDA.DTSAIDA);
        
        FOR REG IN (SELECT ROWID ID
                      FROM PCMOV
                     WHERE NUMTRANSVENDA = P_NUMTRANSACAO
                       AND QTCONT > 0) LOOP
            
          SELECT * INTO ITEM FROM PCMOV WHERE ROWID = REG.ID;
          
          V_CFOPINVERSO := OBTER_CFOPINVERSO(ITEM.CODFISCAL);
          IF V_CFOPINVERSO <= 0 THEN
            P_MENSAGEM := 'INFORME O CFOP INVERSO PARA O CFOP: '||ITEM.CODFISCAL||' NA ROTINA 543.';
            RAISE EXC_CFOP;
          END IF;
            
          ITEM.NUMTRANSENT   := CAB_ENT.NUMTRANSENT;
          ITEM.NUMNOTA       := CAB_ENT.NUMNOTA;
          ITEM.NUMTRANSVENDA := NULL;
          ITEM.CODFISCAL     := V_CFOPINVERSO;
          ITEM.STATUS        := 'A';
          ITEM.QTDEVOL       := 0;
          ITEM.DTCANCEL      := NULL;
          ITEM.QT            := 0;
          ITEM.CODOPER       := 'ED';          
          ITEM.NUMPED        := NULL;
          ITEM.NUMCAR        := NULL;  
          ITEM.NUMBONUS      := NULL;
          ITEM.DATAESTOQUE   := NULL;
          ITEM.DTMOV         := TRUNC(SYSDATE);
          ITEM.DTMOVLOG      := SYSDATE;
          ITEM.MOVESTOQUEGERENCIAL := 'N';
          ITEM.MOVESTOQUECONTABIL  := 'S';           
          
          ITEM.STATUS        := 'A';
          IF NVL(ITEM.TIPOITEM, 'N') = 'C' THEN
            ITEM.STATUS      := 'B';
          END IF;          
            
          IF ITEM.NUMTRANSITEM IS NOT NULL THEN
            V_NUMTRANSITEMORIGINAL := ITEM.NUMTRANSITEM;
              
            SELECT DFSEQ_PCMOVCOMPLE.NEXTVAL
              INTO ITEM.NUMTRANSITEM
              FROM DUAL;
          END IF;
            
          INSERT INTO PCMOV VALUES ITEM;
            
          IF ITEM.NUMTRANSITEM IS NOT NULL THEN
            BEGIN
              SELECT *
                INTO ITEMCOMPLE
                FROM PCMOVCOMPLE
               WHERE NUMTRANSITEM = V_NUMTRANSITEMORIGINAL;
                
              ITEMCOMPLE.NUMTRANSITEM := ITEM.NUMTRANSITEM;
                
              INSERT INTO PCMOVCOMPLE VALUES ITEMCOMPLE;
            EXCEPTION
              WHEN OTHERS THEN
                NULL;
            END;              
          END IF;
        END LOOP;
        
        V_RETORNOPKGESTOQUE := PKG_ESTOQUE.VENDAS_ENTRADA(CAB_ENT.NUMTRANSENT, 'N', VMSG_RETORNORECALCULOESTOQUE);
        IF NVL(V_RETORNOPKGESTOQUE, 0) <= 0 THEN
          ROLLBACK;
          P_MENSAGEM := 'OCORREU UM ERRO AO MOVIMENTAR O ESTOQUE.'|| ' - ' || VMSG_RETORNORECALCULOESTOQUE;
          GERAR_LOG(P_TIPOMOV, VMSG_RETORNORECALCULOESTOQUE);
        ELSE 
          COMMIT;
          v_RETORNO := TRUE;
          GERAR_LOG(P_TIPOMOV, 'NFE DE ENTRADA PROVENIENTE DE SVC CRIADA COM SUCESSO.');
        END IF;
        
      ELSIF P_TIPOMOV = 'E' THEN
        
        BEGIN
          SELECT PCNFENT.*
            INTO CAB_ENT
            FROM PCNFENT
           WHERE PCNFENT.NUMTRANSENT = P_NUMTRANSACAO
             AND NOT EXISTS(SELECT 1 FROM PCNFSAID WHERE NUMTRANSENTORIGEM = PCNFENT.NUMTRANSENT)
             AND PCNFENT.SITUACAONFE = 100
             AND PCNFENT.ESPECIE = 'NF'
             AND PCNFENT.NOTADUPLIQUESVC = 'S'
             AND PCNFENT.DTCANCEL IS NULL
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            P_MENSAGEM := 'NOTA DE ENTRADA DE SVC NÃO ENCONTRADA OU CONTRAPARTIDA JÁ REALIZADA.';
            GERAR_LOG(P_TIPOMOV, P_MENSAGEM);
            RETURN v_RETORNO; 
        END;   
              
        V_NUMTRANSACAO := FERRAMENTAS.F_PROX_NUMTRANSVENDA;
        VS_SCRIPT := GETCOLUNAS('PCNFSAID', 'PCNFENT');
        VS_SCRIPT := 'INSERT INTO PCNFSAID (NUMTRANSVENDA, CODCLI, '||VS_SCRIPT||') 
                      SELECT '||V_NUMTRANSACAO||','||CAB_ENT.CODFORNEC||','||VS_SCRIPT||' FROM PCNFENT WHERE NUMTRANSENT = '||P_NUMTRANSACAO;
        EXECUTE IMMEDIATE VS_SCRIPT;
        
        SELECT * INTO CAB_SAIDA FROM PCNFSAID WHERE NUMTRANSVENDA = V_NUMTRANSACAO; 
        
        CAB_SAIDA.ESPECIE                := 'NE';
        CAB_SAIDA.DTSAIDA                := TRUNC(SYSDATE);
        CAB_SAIDA.SITUACAONFE            := 0;
        CAB_SAIDA.CHAVENFE               := '';
        CAB_SAIDA.PROTOCOLONFE           := '';
        CAB_SAIDA.CONDVENDA              := 4;
        CAB_SAIDA.TIPOVENDA              := 'VP';
        CAB_SAIDA.NOTADUPLIQUESVC        := '';
        CAB_SAIDA.DTCANCEL               := NULL;
        CAB_SAIDA.OBS                    := 'NFE DE CONTRAPARTIDA. NUMTRANSENT REF: ' || P_NUMTRANSACAO;
        CAB_SAIDA.TIPOEMISSAO            := NULL;
        CAB_SAIDA.VLTOTGER               := 0;
        CAB_SAIDA.TIPOVENDA              := 'S';
        CAB_SAIDA.CODFUNCCANCEL          := NULL;
        CAB_SAIDA.DTCANCELWMS            := NULL;
        CAB_SAIDA.DTHORAAUTORIZACAOSEFAZ := NULL;
        CAB_SAIDA.FINALIDADENFE          := '1';        
        CAB_SAIDA.NUMTRANSENTORIGEM      := P_NUMTRANSACAO;
        CAB_SAIDA.UIDREGISTRO            := NULL;
        CAB_SAIDA.IDPARCEIRO             := NULL;
        CAB_SAIDA.NUMCAR                 := NULL;
        CAB_SAIDA.NUMPED                 := NULL;
        CAB_SAIDA.CONSUMIUNUMNFE         := 'N';
        CAB_SAIDA.DTHORAAUTORIZACAOSEFAZ := NULL;
                
        UPDATE PCNFSAID S SET ROW = CAB_SAIDA WHERE S.NUMTRANSVENDA = V_NUMTRANSACAO;
        
        INSERT INTO PCDOCREFERENCIADO
                    (CODIGO
                   , NUMTRANSACAO
                   , TIPO
                   , CHAVENFEREF
                   , NUMNOTAREF
                   , SERIEREF
                   , MODELOREF
                   , DTEMISSAOREF)
             VALUES (DFSEQ_PCDOCREFERENCIADO.NEXTVAL
                   , V_NUMTRANSACAO
                   , 'S'
                   , CAB_ENT.CHAVENFE
                   , CAB_ENT.NUMNOTA
                   , CAB_ENT.SERIE
                   , '55'
                   , CAB_ENT.DTEMISSAO);        
        
        FOR REG IN (SELECT ROWID ID
                      FROM PCMOV
                     WHERE NUMTRANSENT = P_NUMTRANSACAO
                       AND QTCONT > 0) LOOP
              
            SELECT * INTO ITEM FROM PCMOV WHERE ROWID = REG.ID;        
            
            V_CFOPINVERSO := OBTER_CFOPINVERSO(ITEM.CODFISCAL);
            IF V_CFOPINVERSO <= 0 THEN
              P_MENSAGEM := 'INFORME O CFOP INVERSO PARA O CFOP: '||ITEM.CODFISCAL||' NA ROTINA 543.';
              RAISE EXC_CFOP;
            END IF;
              
            ITEM.NUMTRANSVENDA := CAB_SAIDA.NUMTRANSVENDA;
            ITEM.NUMNOTA       := CAB_SAIDA.NUMNOTA;
            ITEM.NUMTRANSENT   := NULL;
            ITEM.CODFISCAL     := V_CFOPINVERSO;
            ITEM.NUMPED        := NULL;
            ITEM.NUMCAR        := NULL;  
            ITEM.NUMBONUS      := NULL;
            ITEM.QTDEVOL       := 0;
            ITEM.DTCANCEL      := NULL;
            ITEM.QT            := 0;
            ITEM.CODOPER       := 'S';
            ITEM.DATAESTOQUE   := NULL;
            ITEM.DTMOV         := TRUNC(SYSDATE);
            ITEM.DTMOVLOG      := SYSDATE;
            ITEM.MOVESTOQUEGERENCIAL := 'N';
            ITEM.MOVESTOQUECONTABIL  := 'S';            
            
            ITEM.STATUS        := 'A';
            IF NVL(ITEM.TIPOITEM, 'N') = 'C' THEN
              ITEM.STATUS      := 'B';
            END IF;
              
            IF ITEM.NUMTRANSITEM IS NOT NULL THEN
              V_NUMTRANSITEMORIGINAL := ITEM.NUMTRANSITEM;
                
              SELECT DFSEQ_PCMOVCOMPLE.NEXTVAL
                INTO ITEM.NUMTRANSITEM
                FROM DUAL;
            END IF;
              
            INSERT INTO PCMOV VALUES ITEM;
              
            IF ITEM.NUMTRANSITEM IS NOT NULL THEN
              BEGIN
                SELECT *
                  INTO ITEMCOMPLE
                  FROM PCMOVCOMPLE
                 WHERE NUMTRANSITEM = V_NUMTRANSITEMORIGINAL;
                  
                ITEMCOMPLE.NUMTRANSITEM := ITEM.NUMTRANSITEM;
                  
                INSERT INTO PCMOVCOMPLE VALUES ITEMCOMPLE;
              EXCEPTION
                WHEN OTHERS THEN
                  NULL;
              END;
            END IF;
          END LOOP;
             
         V_RETORNOPKGESTOQUE := PKG_ESTOQUE.VENDAS_SAIDA(CAB_SAIDA.NUMTRANSVENDA, 'N', VMSG_RETORNORECALCULOESTOQUE);
         IF NVL(V_RETORNOPKGESTOQUE, 0) <= 0 THEN
           ROLLBACK;
           P_MENSAGEM := 'OCORREU UM ERRO AO MOVIMENTAR O ESTOQUE.' || ' - ' || VMSG_RETORNORECALCULOESTOQUE;
           GERAR_LOG(P_TIPOMOV, VMSG_RETORNORECALCULOESTOQUE);
         ELSE 
           COMMIT;
           v_RETORNO := TRUE;
           GERAR_LOG(P_TIPOMOV, 'NFE DE SAIDA PROVENIENTE DE SVC CRIADA COM SUCESSO.');
         END IF;
      END IF;
        
      RETURN v_RETORNO;         
    EXCEPTION
      WHEN EXC_CFOP THEN
        ROLLBACK;
        P_MENSAGEM := P_MENSAGEM || ' - ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
        GERAR_LOG(P_TIPOMOV, P_MENSAGEM);
        RETURN v_RETORNO;      
      WHEN OTHERS THEN
        ROLLBACK;
        P_MENSAGEM := SQLCODE || '-' || SQLERRM || CHR(13) || 'ERRO EM DEVOLVERNFE!' || ' - ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
        GERAR_LOG(P_TIPOMOV, P_MENSAGEM);
        RETURN v_RETORNO;    
    END GERARCONTRAPARTIDA;      
         
END;
