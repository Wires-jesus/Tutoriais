CREATE OR REPLACE PROCEDURE NFE_DUPLICARNOTASVC(P_CODFILIAL    VARCHAR2,
                                                P_NUMNOTA      NUMBER,
                                                P_SERIE        VARCHAR2,
                                                P_CHAVENFE     VARCHAR2,
                                                P_PROTOCOLONFE VARCHAR2,
                                                P_SITUACAONFE  VARCHAR2,
                                                P_TIPOMOV      VARCHAR2) IS

  V_NUMTRANSITEMORIGINAL      PCMOV.NUMTRANSITEM%TYPE;
  CAB_SAIDA                   PCNFSAID%ROWTYPE;
  CAB_ENT                     PCNFENT%ROWTYPE;
  ITEM                        PCMOV%ROWTYPE;
  ITEMCOMPLE                  PCMOVCOMPLE%ROWTYPE;
  VMSGRETORNORECALCULOESTOQUE VARCHAR2(1000);
  Vcontador integer;  
  VNRETORNOPKGESTOQUE INTEGER;
  
  PROCEDURE GERAR_LOG(PNUMNOTA       IN NUMBER,
                      PCHAVENFE      IN VARCHAR2,
                      PNUMTRANSVENDA IN VARCHAR2,
                      PMENSAGEM      IN VARCHAR2,
                      PMENSAGEM_ERRO IN VARCHAR2) IS
  BEGIN
    INSERT INTO PCLOGALTERACAODADOS
      (DATA,
       TABELA,
       COLUNA,
       TIPOVALOR,
       VALORALFA,
       TERMINAL,
       MAQUINA,
       PROGRAMA,
       OSUSER,
       OBSERVACOES,
       OBSERVACOES2)
    VALUES
      (SYSDATE,
       'INDEFINIDA',
       'INDEFINIDA',
       'A',
       'DUPLICACAO DE NOTA DO PROCESSO SVC NUMTRANSVENDA ORIG. : ' || PNUMTRANSVENDA,
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       SUBSTR(PMENSAGEM || PNUMNOTA || ' CHAVENFE: ' || PCHAVENFE,1,100),
       SUBSTR('ERRO ORIGINAL: ' || PMENSAGEM_ERRO, 1, 100));
  END;
BEGIN
  IF P_TIPOMOV = 'S' THEN
    FOR DADOS IN (SELECT PCINUTILIZARNFE.NUMTRANSACAO,
                         PCINUTILIZARNFE.NUMNOTA,
                         NVL(PCINUTILIZARNFE.NUMTRANSACAONOVA, 0) NUMTRANSACAONOVA,
                         (CASE WHEN (PCNFSAID.DTCANCEL IS NOT NULL) AND (NVL(PCNFSAID.VLTOTAL, 0) = 0) THEN
                            'S'
                          ELSE
                            'N'
                          END) NF_ORIGEM_CANCELADA,
                          
                         (SELECT SUM(ROUND(QTCONT * NVL(PUNITCONT,PUNIT),2))
                          FROM PCMOV
                          WHERE NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA
                          AND NVL(QTCONT,QT)> 0) AS NF_ORIGEM_VLTOTAL,
                           
                         PCNFSAID.ROWID ID
                    FROM PCINUTILIZARNFE, PCNFSAID
                   WHERE 1 = 1
                     AND PCNFSAID.NUMTRANSVENDA =
                         PCINUTILIZARNFE.NUMTRANSACAO
                     AND NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL) =
                         P_CODFILIAL
                     AND PCINUTILIZARNFE.NUMNOTA = P_NUMNOTA
                     AND PCINUTILIZARNFE.SERIE = P_SERIE
                     AND PCINUTILIZARNFE.TIPOMOV = P_TIPOMOV) LOOP
    
      IF DADOS.NUMTRANSACAONOVA <= 0 THEN
      
        SELECT *
          INTO CAB_SAIDA
          FROM PCNFSAID
         WHERE ROWID = DADOS.ID;
      
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
        CAB_SAIDA.OBS                      := 'NOTA FISCAL DUPLICADA. NUMTRANSVENDA REF: ' ||
                                              DADOS.NUMTRANSACAO;
        CAB_SAIDA.TIPOEMISSAO              := SUBSTR(CAB_SAIDA.CHAVENFE,
                                                     35,
                                                     1);
        CAB_SAIDA.VLTOTGER                 := 0;
        CAB_SAIDA.TIPOVENDA                := 'S';
        CAB_SAIDA.CODFUNCCANCEL            := NULL;
        CAB_SAIDA.DTCANCELWMS              := NULL;
        CAB_SAIDA.PROTOCOLOCANCELAMENTO    := NULL;
        CAB_SAIDA.DTHORACANCELAMENTOSEFAZ  := NULL;
        CAB_SAIDA.PROTOCOLOCANCELAMENTOCTE := NULL;
        CAB_SAIDA.ENVIADOEMAILCANCELADO    := NULL;
        CAB_SAIDA.NUMTRANSENTORIGEM        := NULL;
        CAB_SAIDA.UIDREGISTRO              := NULL;
        CAB_SAIDA.IDPARCEIRO               := NULL;
        CAB_SAIDA.NUMCAR                   := NULL;
        CAB_SAIDA.NUMPED                   := NULL;
        
        --INSERE VALOR TOTAL APROXIMADO CASO A NOTA ORIGEM ESTEJA CANCELADA VLTOTAL = 0
        IF (DADOS.NF_ORIGEM_CANCELADA = 'S') THEN
          CAB_SAIDA.VLTOTAL := DADOS.NF_ORIGEM_VLTOTAL;
        END IF;
              
        INSERT INTO PCNFSAID VALUES CAB_SAIDA;
      
        FOR REG IN (SELECT ROWID ID
                    FROM PCMOV
                    WHERE NUMTRANSVENDA = DADOS.NUMTRANSACAO
                    AND NVL(QTCONT,QT) > 0) LOOP
        
          SELECT * INTO ITEM FROM PCMOV WHERE ROWID = REG.ID;         
          
          ITEM.NUMTRANSVENDA := CAB_SAIDA.NUMTRANSVENDA;
          ITEM.NUMNOTA       := CAB_SAIDA.NUMNOTA;
          
          --PRODUTO CESTA/KIT (TIPOITEM = 'C') SÓ MOVIMENTA O GERENCIAL B
          IF NVL(ITEM.TIPOITEM,'N') = 'C' THEN
            ITEM.STATUS:= 'B';
          ELSE
            ITEM.STATUS := 'A';  
          END IF;
          
          ITEM.QTDEVOL       := 0;
          ITEM.DTCANCEL      := NULL;
          ITEM.QT            := 0;
          ITEM.CODOPER       := 'S';--NECESSÁRIO PARA OS ITENS APARECEREM NA 1303 PARA DEVOLUÇÃO
          ITEM.MOVESTOQUEGERENCIAL := 'N';
          ITEM.DATAESTOQUE   := NULL;
        
          IF ITEM.NUMTRANSITEM IS NOT NULL THEN
            V_NUMTRANSITEMORIGINAL := ITEM.NUMTRANSITEM;
          
            SELECT DFSEQ_PCMOVCOMPLE.NEXTVAL
              INTO ITEM.NUMTRANSITEM
              FROM DUAL;
          END IF;
        
          -- INSERIR PCMOV
          INSERT INTO PCMOV VALUES ITEM;
        
          -- INSERIR PCMOVCOMPLE
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
           SET PCINUTILIZARNFE.NUMTRANSACAONOVA = CAB_SAIDA.NUMTRANSVENDA
         WHERE PCINUTILIZARNFE.NUMTRANSACAO = DADOS.NUMTRANSACAO
           AND PCINUTILIZARNFE.NUMNOTA = DADOS.NUMNOTA
           AND PCINUTILIZARNFE.TIPOMOV = P_TIPOMOV
           AND PCINUTILIZARNFE.CHAVENFE = CAB_SAIDA.CHAVENFE;
       COMMIT;
       
      VNRETORNOPKGESTOQUE := PKG_ESTOQUE.VENDAS_SAIDA(CAB_SAIDA.NUMTRANSVENDA, 'N', VMSGRETORNORECALCULOESTOQUE);
      
      IF NVL(VNRETORNOPKGESTOQUE, 0) <= 0 THEN
        GERAR_LOG(P_NUMNOTA,
          P_CHAVENFE,
          CAB_SAIDA.NUMTRANSVENDA,
          'OCORREU UM ERRO AO MOVIMENTAR O ESTOQUE ' ||
          VMSGRETORNORECALCULOESTOQUE,
          '');
      END IF;
        
      END IF;
    END LOOP;
  ELSE
    FOR DADOS IN (SELECT PCINUTILIZARNFE.NUMTRANSACAO,
                         PCINUTILIZARNFE.NUMNOTA,
                         NVL(PCINUTILIZARNFE.NUMTRANSACAONOVA, 0) NUMTRANSACAONOVA,
                         (CASE WHEN (PCNFENT.DTCANCEL IS NOT NULL) AND (NVL(PCNFENT.VLTOTAL, 0) = 0) THEN
                            'S'
                          ELSE
                            'N'
                          END) NF_ORIGEM_CANCELADA,
                         (SELECT SUM(ROUND(QTCONT * NVL(PUNITCONT,PUNIT),2))
                          FROM PCMOV
                          WHERE NUMTRANSENT = PCNFENT.NUMTRANSENT
                          AND NVL(QTCONT,QT)> 0) AS NF_ORIGEM_TOTAL,
                         PCNFENT.ROWID ID
                    FROM PCINUTILIZARNFE, PCNFENT
                   WHERE PCINUTILIZARNFE.NUMNOTA = P_NUMNOTA
                     AND PCNFENT.NUMTRANSENT = PCINUTILIZARNFE.NUMTRANSACAO
                     AND NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) =P_CODFILIAL
                     AND PCINUTILIZARNFE.SERIE = P_SERIE
                     AND PCINUTILIZARNFE.TIPOMOV = P_TIPOMOV
                     AND PCNFENT.ESPECIE IN ('NE', 'NF')) LOOP
    
      IF DADOS.NUMTRANSACAONOVA <= 0 THEN
      
        SELECT *
          INTO CAB_ENT
          FROM PCNFENT
         WHERE ROWID = DADOS.ID;
      
        CAB_ENT.NUMTRANSENT     := FERRAMENTAS.F_PROX_NUMTRANSENT;
        CAB_ENT.NUMNOTA         := DADOS.NUMNOTA;
        CAB_ENT.ESPECIE         := 'NF';
        CAB_ENT.SITUACAONFE     := P_SITUACAONFE; -- REVER
        CAB_ENT.SERIE           := P_SERIE;
        CAB_ENT.CHAVENFE        := P_CHAVENFE;
        CAB_ENT.PROTOCOLONFE    := P_PROTOCOLONFE;
        CAB_ENT.NOTADUPLIQUESVC := 'S';
        CAB_ENT.DTCANCEL        := NULL;
        CAB_ENT.OBS             := 'NOTA FISCAL DUPLICADA. NUMTRANSENT REF: ' ||
                                   DADOS.NUMTRANSACAO;
        CAB_ENT.TIPOEMISSAO     := SUBSTR(CAB_ENT.CHAVENFE, 35, 1);
        CAB_ENT.NUMBONUS        := NULL;
        
        IF (DADOS.NF_ORIGEM_CANCELADA = 'S') THEN
          CAB_ENT.VLTOTAL := DADOS.NF_ORIGEM_TOTAL;
        END IF;                        
      
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
          ITEM.MOVESTOQUEGERENCIAL := 'N';
          ITEM.DATAESTOQUE := NULL;
        
          IF ITEM.NUMTRANSITEM IS NOT NULL THEN
            V_NUMTRANSITEMORIGINAL := ITEM.NUMTRANSITEM;
          
            SELECT DFSEQ_PCMOVCOMPLE.NEXTVAL
              INTO ITEM.NUMTRANSITEM
              FROM DUAL;
          END IF;
        
          -- INSERIR PCMOV
          INSERT INTO PCMOV VALUES ITEM;
        
          -- INSERIR PCMOVCOMPLE
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
           SET PCINUTILIZARNFE.NUMTRANSACAONOVA = CAB_ENT.NUMTRANSENT
         WHERE PCINUTILIZARNFE.NUMTRANSACAO = DADOS.NUMTRANSACAO
           AND PCINUTILIZARNFE.NUMNOTA = DADOS.NUMNOTA
           AND PCINUTILIZARNFE.CHAVENFE = P_CHAVENFE
           AND PCINUTILIZARNFE.TIPOMOV = P_TIPOMOV;
        COMMIT;
        
        VNRETORNOPKGESTOQUE := PKG_ESTOQUE.VENDAS_ENTRADA(CAB_ENT.NUMTRANSENT, 'N', VMSGRETORNORECALCULOESTOQUE);
      
        IF NVL(VNRETORNOPKGESTOQUE, 0) <= 0 THEN
          GERAR_LOG(P_NUMNOTA,
            P_CHAVENFE,
            CAB_ENT.NUMTRANSENT,
            'OCORREU UM ERRO AO MOVIMENTAR O ESTOQUE ' ||
            VMSGRETORNORECALCULOESTOQUE,
            '');
        END IF;
      
      END IF;
    END LOOP;
  END IF;
  COMMIT;
END;