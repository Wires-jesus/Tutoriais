CREATE OR REPLACE PROCEDURE OBTERPROXIMONUMERONOTACTE(P_CODIGOFILIAL IN VARCHAR2 DEFAULT '',
                                                      P_TRANSACAO    IN NUMBER DEFAULT 0,
                                                      P_MOVIMENTO    IN VARCHAR2 DEFAULT 'S',
                                                      P_NUMERO       OUT NUMBER,
                                                      P_SERIE        OUT NUMBER,
                                                      P_RESULTADO    OUT NUMBER,
                                                      P_MENSAGEM     OUT VARCHAR2) IS

  NUMNOTA_ATUAL     PCNFSAID.NUMNOTA%TYPE;
  SERIE_ATUAL       PCNFSAID.SERIE%TYPE;
  JA_UTILIZOUNUMCTE PCNFSAID.CONSUMIUNUMCTE%TYPE;
  NUMTRANSACAOORIG  NUMBER(10);
  UF_COLETA         VARCHAR2(2);
  UF_FILIAL         VARCHAR2(2);
  EXISTUFFILIAL     BOOLEAN;
  V_OBTEVEUFFILIAL  BOOLEAN;

  
   PROCEDURE OBTER_NUMERO_SERIE_NF_FILIAL is
   begin
      V_OBTEVEUFFILIAL := True;
      SELECT DECODE(NVL(PCFILIAL.PROXNUMCTE, 1),
                  0,
                  1,
                  NVL(PCFILIAL.PROXNUMCTE, 1)),
           TO_NUMBER(DECODE(NVL(PCFILIAL.SERIECTE, 'U'),
                            'U',
                            '0',
                            PCFILIAL.SERIECTE))
      INTO P_NUMERO, P_SERIE
      FROM PCFILIAL
      WHERE CODIGO = P_CODIGOFILIAL
      FOR UPDATE;
      
      
   end;
  
  
BEGIN
  P_NUMERO         := 0;
  P_SERIE          := 0;
  P_RESULTADO      := 0;
  NUMTRANSACAOORIG := 0;
  P_MENSAGEM       := '';
  UF_COLETA        := '';
  EXISTUFFILIAL    := False;
  V_OBTEVEUFFILIAL := False;
  
BEGIN  
  IF UPPER(P_MOVIMENTO) = 'S' THEN
  BEGIN
    --Movimento de Saída
      
        SELECT PCNFSAID.NUMNOTA,
               PCNFSAID.SERIE,
               NVL(PCNFSAID.NUMTRANSENTORIGEM, 0),
               NVL(PCNFSAID.CONSUMIUNUMCTE, 'N'),
               NVL((SELECT UF FROM PCCIDADE WHERE CODCIDADE = PCNFSAID.CODCIDADECOLETA), (SELECT UF FROM PCFILIAL WHERE CODIGO = NVL(PCNFSAID.CODFILIALNF,PCNFSAID.CODFILIAL))) AS UFCOLETA,
               NVL((SELECT UF FROM PCFILIAL WHERE CODIGO = NVL(PCNFSAID.CODFILIALNF,PCNFSAID.CODFILIAL) ), '') AS UFFILIAL
          INTO NUMNOTA_ATUAL, SERIE_ATUAL, NUMTRANSACAOORIG, JA_UTILIZOUNUMCTE, UF_COLETA, UF_FILIAL
          FROM PCNFSAID
         WHERE PCNFSAID.NUMTRANSVENDA = P_TRANSACAO;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          P_RESULTADO := 50;
          P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                         ' - Conhecimento de transporte inexistente para esta transação. ' ||
                         SQLCODE || ' - ' || SQLERRM;
          RETURN;
        WHEN OTHERS THEN
          P_RESULTADO := 51;
          P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                         ' - Erro ao buscar os dados na tabela PCNFSAID. ' ||
                         SQLCODE || ' - ' || SQLERRM;
          RETURN;
      END;
    
      IF (JA_UTILIZOUNUMCTE = 'N') THEN
        BEGIN
            BEGIN
               SELECT DECODE(NVL(PCFILIALCTEESTADO.NUMCTE, 1),
                             0,
                             1,
                             NVL(PCFILIALCTEESTADO.NUMCTE, 1)),
                      TO_NUMBER(DECODE(NVL(PCFILIALCTEESTADO.SERIECTE, 'U'),
                                       'U',
                                       '0',
                                       PCFILIALCTEESTADO.SERIECTE))
               INTO P_NUMERO, P_SERIE                                
               FROM PCFILIALCTEESTADO
               WHERE CODFILIAL = P_CODIGOFILIAL
                 AND UF = UF_COLETA;

            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  EXISTUFFILIAL := (NVL(P_NUMERO, '') <> '');
               WHEN OTHERS THEN
                  P_RESULTADO := 2;
                  P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                                 ' - Erro ao buscar os dados da filial "' ||
                                 P_CODIGOFILIAL || '". ' || SQLCODE || ' - ' ||
                                 SQLERRM;
                  RETURN;
        END;
        
          EXISTUFFILIAL := (NVL(P_NUMERO, '') <> '');

          IF (UF_COLETA = UF_FILIAL) OR NOT(EXISTUFFILIAL) THEN 
            
            OBTER_NUMERO_SERIE_NF_FILIAL;
            
          ELSE 
            BEGIN
              SELECT DECODE(NVL(PCFILIALCTEESTADO.NUMCTE, 1),
                            0,
                            1,
                            NVL(PCFILIALCTEESTADO.NUMCTE, 1)),
                     TO_NUMBER(DECODE(NVL(PCFILIALCTEESTADO.SERIECTE, 'U'),
                                      'U',
                                      '0',
                                      PCFILIALCTEESTADO.SERIECTE))
                INTO P_NUMERO, P_SERIE                                
                FROM PCFILIALCTEESTADO
               WHERE CODFILIAL = P_CODIGOFILIAL
                 AND UF = UF_COLETA
                 FOR UPDATE;
            EXCEPTION           
              WHEN NO_DATA_FOUND THEN
                OBTER_NUMERO_SERIE_NF_FILIAL;
            END;
          END IF; 
          
               
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            
            OBTER_NUMERO_SERIE_NF_FILIAL;
            
          WHEN OTHERS THEN
            P_RESULTADO := 2;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao buscar os dados da filial "' ||
                           P_CODIGOFILIAL || '". ' || SQLCODE || ' - ' ||
                           SQLERRM;
            RETURN;
        END;
        --Atualiza na filial informada, o próximo número    
        BEGIN
          IF (UF_COLETA = UF_FILIAL) OR NOT(EXISTUFFILIAL) THEN 
            UPDATE PCFILIAL
               SET PCFILIAL.PROXNUMCTE = P_NUMERO + 1
             WHERE CODIGO = P_CODIGOFILIAL;    
            COMMIT;
          ELSE
            IF V_OBTEVEUFFILIAL THEN
                UPDATE PCFILIAL
                   SET PCFILIAL.PROXNUMCTE = P_NUMERO + 1
                 WHERE CODIGO = P_CODIGOFILIAL;    
                COMMIT;
            ELSE
                UPDATE PCFILIALCTEESTADO
                   SET PCFILIALCTEESTADO.NUMCTE = P_NUMERO + 1
                 WHERE CODFILIAL = P_CODIGOFILIAL
                   AND UF = UF_COLETA;
                COMMIT;
            END IF;
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            P_RESULTADO := 3;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao atualizar os dados do próximo número de nota. ' ||
                           ' - Filial: ' || P_CODIGOFILIAL || ' - ' || SQLCODE ||
                           ' - ' || SQLERRM;
            ROLLBACK;
            RETURN;
        END;  
        -- 1. Atualizar PCNFSAID CTE
        BEGIN    
          UPDATE PCNFSAID
             SET PCNFSAID.NUMNOTA        = P_NUMERO,
                 PCNFSAID.SERIE          = P_SERIE,
                 PCNFSAID.CONSUMIUNUMCTE = 'S'
           WHERE NUMTRANSVENDA = P_TRANSACAO;    
        EXCEPTION
          WHEN OTHERS THEN
            P_RESULTADO := 100;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao atualizar a tabela "PCNFSAID". ' ||
                           SQLCODE || ' - ' || SQLERRM;
            ROLLBACK;
            RETURN;
        END; 
        --2. Atualiza - PCPREST Saida 
        BEGIN
        
          UPDATE PCPREST
             SET PCPREST.DUPLIC = P_NUMERO
           WHERE PCPREST.NUMTRANSVENDA = P_TRANSACAO;    
        EXCEPTION
          WHEN OTHERS THEN
            P_RESULTADO := 101;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao atualizar a tabela "PCPREST". ' ||
                           SQLCODE || ' - ' || SQLERRM;
            ROLLBACK;
            RETURN;
        END; 
        --3. Atualizar PCNFENT  
        IF NUMTRANSACAOORIG > 0 THEN
          BEGIN      
            UPDATE PCNFENT
               SET PCNFENT.NUMNOTA = P_NUMERO, PCNFENT.SERIE = P_SERIE
             WHERE NUMTRANSENT = NUMTRANSACAOORIG;      
          EXCEPTION
            WHEN OTHERS THEN
              P_RESULTADO := 102;
              P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                             ' - Erro ao atualizar a tabela "PCNFENT". ' ||
                             SQLCODE || ' - ' || SQLERRM;
              ROLLBACK;
              RETURN;
          END;
        
          /*
          4. Atualiza - PCLANC ENTRADA
          */
        
          BEGIN
          
            UPDATE PCLANC
               SET PCLANC.NUMNOTA = P_NUMERO
             WHERE PCLANC.NUMTRANSENT = NUMTRANSACAOORIG;
          
          EXCEPTION
            WHEN OTHERS THEN
              P_RESULTADO := 103;
              P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                             ' - Erro ao atualizar a tabela "PCLANC". ' ||
                             SQLCODE || ' - ' || SQLERRM;
              ROLLBACK;
              RETURN;
          END;
         
        END IF;
        
       /*
        5. Atualiza - PCLANC SAIDA (ROTINA 1450)
        */
      
        BEGIN
        
          UPDATE PCLANC
             SET PCLANC.NUMNOTA = P_NUMERO
           WHERE PCLANC.NUMTRANSVENDA = P_TRANSACAO;
        
        EXCEPTION
          WHEN OTHERS THEN
            P_RESULTADO := 104;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao atualizar a tabela "PCLANC". ' ||
                           SQLCODE || ' - ' || SQLERRM;
            ROLLBACK;
            RETURN;
        END;
      
        COMMIT;
      
      ELSE
        P_NUMERO    := NUMNOTA_ATUAL;
        P_SERIE     := SERIE_ATUAL;
        P_RESULTADO := 0;
        P_MENSAGEM  := '';
        ROLLBACK;
      
      END IF;
   
   ELSE
   
   --MOVIMENTAÇÃO DE ENTRADA   
      BEGIN
        SELECT PCNFENT.NUMNOTA,
               PCNFENT.SERIE,
               NVL(PCNFENT.CONSUMIUNUMCTE, 'N'),
               NVL((SELECT UF FROM PCFILIAL WHERE CODIGO = NVL(PCNFENT.CODFILIALNF,PCNFENT.CODFILIAL)), '') AS UFCOLETA,
               NVL((SELECT UF FROM PCFILIAL WHERE CODIGO = NVL(PCNFENT.CODFILIALNF,PCNFENT.CODFILIAL)), '') AS UFFILIAL
          INTO NUMNOTA_ATUAL, SERIE_ATUAL, JA_UTILIZOUNUMCTE, UF_COLETA, UF_FILIAL
          FROM PCNFENT
         WHERE PCNFENT.NUMTRANSENT = P_TRANSACAO;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          P_RESULTADO := 50;
          P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                         ' - Conhecimento de transporte inexistente para esta transação. ' ||
                         SQLCODE || ' - ' || SQLERRM;
          RETURN;

        WHEN OTHERS THEN
          P_RESULTADO := 51;
          P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                         ' - Erro ao buscar os dados na tabela PCNFENT. ' ||
                         SQLCODE || ' - ' || SQLERRM;
          RETURN;
      END;
    
      IF (JA_UTILIZOUNUMCTE = 'N') THEN
      BEGIN
         -- Buscar informações na filial informada, o próximo número

          BEGIN
            SELECT DECODE(NVL(PCFILIAL.PROXNUMCTE, 1),
                          0,
                          1,
                          NVL(PCFILIAL.PROXNUMCTE, 1)),
                   TO_NUMBER(DECODE(NVL(PCFILIAL.SERIECTE, 'U'),
                                    'U',
                                    '0',
                                    PCFILIAL.SERIECTE))
              INTO P_NUMERO, P_SERIE
              FROM PCFILIAL
             WHERE CODIGO = P_CODIGOFILIAL;
          EXCEPTION           
              WHEN NO_DATA_FOUND THEN
                P_RESULTADO := 4;
                P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                               ' - Não foi encontrado a serie para a filial informada : "' ||
                               UF_COLETA || '". ' || SQLCODE || ' - ' ||
                               SQLERRM;
                RETURN;

              WHEN OTHERS THEN
                P_RESULTADO := 2;
                P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                               ' - Erro ao buscar os dados da filial "' ||
                               P_CODIGOFILIAL || '". ' || SQLCODE || ' - ' ||
                               SQLERRM;
                RETURN;
            END;
        --Atualiza na filial informada, o próximo número    
        BEGIN

            UPDATE PCFILIAL
               SET PCFILIAL.PROXNUMCTE = P_NUMERO + 1
             WHERE CODIGO = P_CODIGOFILIAL;    
            COMMIT;

        EXCEPTION
          WHEN OTHERS THEN
            P_RESULTADO := 3;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao atualizar os dados do próximo número de nota. ' ||
                           ' - Filial: ' || P_CODIGOFILIAL || ' - ' || SQLCODE ||
                           ' - ' || SQLERRM;
            ROLLBACK;
            RETURN;
        END;  
       
        --1. Atualizar PCNFENT  
          BEGIN      
            UPDATE PCNFENT
               SET PCNFENT.NUMNOTA = P_NUMERO, 
                   PCNFENT.SERIE = P_SERIE,
                   PCNFENT.CONSUMIUNUMCTE = 'S'  
             WHERE NUMTRANSENT = P_TRANSACAO;      
          EXCEPTION
            WHEN OTHERS THEN
              P_RESULTADO := 102;
              P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                             ' - Erro ao atualizar a tabela "PCNFENT". ' ||
                             SQLCODE || ' - ' || SQLERRM;
              ROLLBACK;
              RETURN;
          END;
        
          --2. Atualiza - PCLANC ENTRADA
         
          BEGIN
            UPDATE PCLANC
               SET PCLANC.NUMNOTA = P_NUMERO
             WHERE PCLANC.NUMTRANSENT = P_TRANSACAO;
          
          EXCEPTION
            WHEN OTHERS THEN
              P_RESULTADO := 103;
              P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                             ' - Erro ao atualizar a tabela "PCLANC". ' ||
                             SQLCODE || ' - ' || SQLERRM;
              ROLLBACK;
              RETURN;
          END;
        
        END;
      
        COMMIT;
      
      ELSE
        P_NUMERO    := NUMNOTA_ATUAL;
        P_SERIE     := SERIE_ATUAL;
        P_RESULTADO := 0;
        P_MENSAGEM  := '';
        ROLLBACK;
      END IF;
    END IF; 
    
  EXCEPTION
    WHEN OTHERS THEN
      P_RESULTADO := 1;
      P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                     ' - Erro ao tentar atualizar o próximo numero para o CT-e informado. ' ||
                     SQLCODE || ' - ' || SQLERRM;
      ROLLBACK;
      RETURN;
  END;  

END OBTERPROXIMONUMERONOTACTE;