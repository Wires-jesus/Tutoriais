CREATE OR REPLACE PROCEDURE "PRC_MED_IMPORT_PEDOPERLOG" (pi_nTipoChamada      IN  NUMBER,
                                    pi_nIntegradora      IN  NUMBER,
                                    po_nQtdeRegProc      OUT NUMBER,
                                    po_vOcorreramErros   OUT VARCHAR2,
                                    po_vMsgErros         OUT VARCHAR2)
/*******************************************************************************
 Nome         : PRC_MED_IMPORT_PEDOPERLOG
 Descricão    : Procedimento para Controle da Importação de Pedidos de Operador
                Logístico
 Parâmetros   : ENTRADA:
                pi_nTipoChamada    = 1 - Atualização do Status de Importação
                                         dos Pedidos
                                     2 - Geração dos Retornos
                pi_nIntegradora    = Código da Integradora
                SAIDA:         
                po_nQtdeRegProc    = Quantidade de Registros Processados
                po_vOcorreramErros = S-Sim; N-Não      
                po_vMsgErros       = Mensagem de Erros 
 Alteracão    : Anderson Silva - 06/06/2013 - Criação da Procedure
 Alteração    : Anderson Silva - 21/06/2013 - Gerar Retorno Pedidos em Analise             
********************************************************************************/                                       
IS

 /***********************
  Declaração de Variáveis
  ***********************/
  
  -- Mensagem de Exceção
  vvMsgErros                 VARCHAR2(2000); 
  
  -- Controle de Erros na Importação
  vbErrosImportacao          BOOLEAN;
  -- Posição do Pedido
  vvPosicao                  PCPEDC.POSICAO%TYPE;
  -- Importado
  viImportado                PCPEDCFV.IMPORTADO%TYPE;
  -- Observação     
  vvObservacao               PCPEDCFV.OBSERVACAO_PC%TYPE;
  vvObservacaoGeral          PCPEDCFV.OBSERVACAO_PC%TYPE;
  -- Contador de Pedidos Importados
  viContaPedidosImport       INTEGER;
  -- Prazo Medio e Cond. Venda do Pedido
  vnPrazoMedio               PCPEDC.PRAZOMEDIO%TYPE;
  vnQtdePrazos               PCPEDC.PRAZOMEDIO%TYPE;
  vnSomaPrazos               PCPEDC.PRAZOMEDIO%TYPE;
  vnPrazo1                   PCPEDC.PRAZO1%TYPE;
  vnPrazo2                   PCPEDC.PRAZO2%TYPE;
  vnPrazo3                   PCPEDC.PRAZO3%TYPE;
  vnPrazo4                   PCPEDC.PRAZO4%TYPE;
  vnPrazo5                   PCPEDC.PRAZO5%TYPE;
  vnPrazo6                   PCPEDC.PRAZO6%TYPE;
  vnPrazo7                   PCPEDC.PRAZO7%TYPE;
  vnPrazo8                   PCPEDC.PRAZO8%TYPE;
  vnPrazo9                   PCPEDC.PRAZO9%TYPE;
  vnPrazo10                  PCPEDC.PRAZO10%TYPE;
  vnPrazo11                  PCPEDC.PRAZO11%TYPE;
  vnPrazo12                  PCPEDC.PRAZO12%TYPE;
  vnCondVenda                PCPEDC.CONDVENDA%TYPE;
  -- Valores do Produto do Pedido Faturado
  vnQtAtend                  PCPEDI.QT%TYPE;
  vnQtNaoAtend               PCPEDI.QT%TYPE;
  vnPerDesc                  PCPEDI.PERDESC%TYPE;
  vnPrecoBruto               PCPEDI.PTABELA%TYPE;
  vnPrecoLiquido             PCPEDI.PTABELA%TYPE;
  vnSt                       PCPEDI.ST%TYPE;
  vnVlRepasse                PCPEDI.VLREPASSE%TYPE;
  vnPrecoContabil            PCPEDI.PVENDA%TYPE;
  vnAliqIcms                 PCMOV.PERCICM%TYPE;
  vnCodSt                    PCPEDI.CODST%TYPE;
  -- Informações Adicionais do Produto no Retorno
  vnSitAtendItem             PCRETIOPERLOG.SITATEND%TYPE;
  vnCodMotivoNaoAtendItem    PCMOTIVONAOATEND.DESCRICAO%TYPE;
  vvCodMotivoNaoAtendLayout  PCMOTIVONAOATENDLAYOUT.CODMOTIVOLAYOUT%TYPE;
  vvDescMotivoNaoAtendLayout PCMOTIVONAOATENDLAYOUT.DESCMOTIVOLAYOUT%TYPE;
  -- Totais do Pedido      
  vnSitAtendCab              PCRETCOPERLOG.SITATEND%TYPE;
  vnTotalQtUnidAtend         PCRETCOPERLOG.QTUNIDATEND%TYPE;
  vnTotalQtUnidNaoAtend      PCRETCOPERLOG.QTUNIDNAOATEND%TYPE;
  vnQtItensAtend             PCRETCOPERLOG.QTITENSATEND%TYPE;
  vnQtItensNaoAtend          PCRETCOPERLOG.QTITENSNAOATEND%TYPE;
  -- CGC da Filial
  vvCgcFilial                PCPEDCOPERLOG.CGCFILIAL%TYPE;

 /**********************
  Declaração de Cursores
  **********************/
  
  -- Cursor de Pedidos Importados
  CURSOR c_PedRetorno(pi_nIntegradora IN NUMBER,
                      pi_vCgcCli      IN VARCHAR2,
                      pi_vNumPedVan   IN VARCHAR2,
                      pi_dDtInclusao  IN DATE) IS 
    SELECT NUMPEDRCA
         , CODUSUR
         , CGCCLI
         , DTABERTURAPEDPALM
         , NUMPED
         , NUMQUEBRA
      FROM PCPEDRETORNO
     WHERE (INTEGRADORA          = pi_nIntegradora)
       AND (CGCCLI               = pi_vCgcCli)
       AND (NUMPEDVAN            = pi_vNumPedVan)
       AND (DTINCLUSAOPEDOPERLOG = pi_dDtInclusao)
     ORDER BY DTABERTURAPEDPALM DESC;      
     
  -- Cursor de Itens do Retorno do Pedido
  CURSOR c_ItensRetorno(pi_nNumpedRca         IN NUMBER,
                        pi_vCgcCli            IN VARCHAR2,
                        pi_nCodUsur           IN NUMBER,
                        pi_dDtAberturaPedPalm IN DATE) IS 
    SELECT CODPROD
         , TIPOCODINTEGRACAO
         , CODPRODOL
         , NUMSEQ
         , QT
         , CODMOTIVONAOATEND
      FROM PCPEDIFV
     WHERE (PCPEDIFV.NUMPEDRCA         = pi_nNumpedRca)
       AND (PCPEDIFV.CGCCLI            = pi_vCgcCli)
       AND (PCPEDIFV.CODUSUR           = pi_nCodUsur)
       AND (PCPEDIFV.DTABERTURAPEDPALM = pi_dDtAberturaPedPalm);

 /***********************
  Procedure: PMUDA_STATUS
  ***********************/
  PROCEDURE PMUDA_STATUS(pi_vStatus       IN VARCHAR2,
                         pi_vObservacao   IN VARCHAR2,
                         pi_nIntegradora  IN NUMBER,
                         pi_vCgcCli       IN VARCHAR2,
                         pi_vNumPedVan    IN VARCHAR2,
                         pi_dDataInclusao IN DATE) IS
  BEGIN

    -- Atualiza Status   
    UPDATE PCPEDCOPERLOG
       SET STATUS     = pi_vStatus
         , OBSERVACAO = pi_vObservacao
         , DATAPROC   = SYSDATE
     WHERE (PCPEDCOPERLOG.INTEGRADORA = pi_nIntegradora)
       AND (PCPEDCOPERLOG.CGCCLI      = pi_vCgcCli)
       AND (PCPEDCOPERLOG.NUMPEDVAN   = pi_vNumPedVan)
       AND (PCPEDCOPERLOG.DTINCLUSAO  = pi_dDataInclusao);  
       
    -- Efetiva Transações
    COMMIT;
  
  END PMUDA_STATUS;                         

 /***********************
  INICIO DO PROCESSAMENTO
  ***********************/
BEGIN

  -- Inicializa Retornos
  po_nQtdeRegProc    := 0;
  po_vOcorreramErros := 'N';
  po_vMsgErros       := NULL;

 /******************************************************************************
  Se chamado Atualização do Status de Importação dos Pedidos
  **********************************************************/
  IF    (pi_nTipoChamada = 1) THEN
  
    -- Cursor de Pesquisa os Pedidos que estão em Processamento
    FOR vc_PedidosOperLog IN (SELECT INTEGRADORA
                                   , CGCCLI
                                   , NUMPEDVAN
                                   , DTINCLUSAO
                                FROM PCPEDCOPERLOG
                               WHERE (STATUS = 'EP')
                                 AND (INTEGRADORA = pi_nIntegradora)) LOOP

      -- Inicializa Contador de Pedidos Importados
      viContaPedidosImport := 0;

      -- Inicializa Controle de Erros na Importação
      vbErrosImportacao    := FALSE;
      -- Inicializa Observação Geral
      vvObservacaoGeral    := NULL; 

      -- Cursor de Pesquisa Pedidos Gerados
      FOR vc_PedRetorno IN c_PedRetorno(vc_PedidosOperLog.INTEGRADORA,
                                        vc_PedidosOperLog.CGCCLI,
                                        vc_PedidosOperLog.NUMPEDVAN,
                                        vc_PedidosOperLog.DTINCLUSAO) LOOP

        -- Incrementa Contador de Pedidos Importados
        viContaPedidosImport := NVL(viContaPedidosImport,0) + 1;

        -- Inicializa Observação do Pedido Importado
        vvObservacao := NULL;
                                        
        -- Se foi gerado Pedido, verifica se ele não foi cancelado
        IF (NVL(vc_PedRetorno.NUMPED,0) > 0) THEN
        
          -- Pesquisa Posição do Pedido
          BEGIN
            SELECT POSICAO
              INTO vvPosicao
              FROM PCPEDC
             WHERE (PCPEDC.NUMPED = vc_PedRetorno.NUMPED);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vvPosicao := 'C';
          END;        
          
          -- Se o Pedido foi Cancelado
          IF (NVL(vvPosicao,'L') = 'C') THEN
            -- Observação de Pedido Cancelado
            vvObservacao := 'Pedido ' || TO_CHAR(vc_PedRetorno.NUMPED) || ' importado, mas foi cancelado';
          ELSE
            -- Observação de Pedido Processado
            vvObservacao := 'Pedido ' || TO_CHAR(vc_PedRetorno.NUMPED) || ' importado. Posição atual: ' || NVL(vvPosicao,' ');
          END IF;            

        -- Se não foi Gerado Pedido
        ELSE

          -- Pesquisa Flag Importado e Observação do Pedido
          BEGIN
            SELECT IMPORTADO
                 , OBSERVACAO_PC
              INTO viImportado
                 , vvObservacao
              FROM PCPEDCFV
             WHERE (NUMPEDRCA         = vc_PedRetorno.NUMPEDRCA)
               AND (CODUSUR           = vc_PedRetorno.CODUSUR)
               AND (CGCCLI            = vc_PedRetorno.CGCCLI)
               AND (DTABERTURAPEDPALM = vc_PedRetorno.DTABERTURAPEDPALM);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              viImportado  := 3;
              vvObservacao := 'Dados não encontrados na Tabela PCPEDCFV para NUMPEDRCA ' || vc_PedRetorno.NUMPEDRCA;
          END;        

          -- Atualiza Controle de Erros na Importação
          IF (viImportado = 3) THEN
            vbErrosImportacao := TRUE;
          END IF;
                
        END IF; -- Fim Condição Se foi gerado Pedido
        
        -- Se não vai estourar o tamanho da Mensagem Geral
        IF (NVL(LENGTH(vvObservacaoGeral),0) + NVL(LENGTH(vvObservacao),0) < 4000) THEN
          -- Quebra de Linha da Observação Geral
          IF (vvObservacaoGeral IS NOT NULL) THEN
            vvObservacaoGeral := vvObservacaoGeral || CHR(13);
          END IF;
          -- Concatena à Observação Geral a Observação do Pedido Importado
          vvObservacaoGeral := vvObservacaoGeral || NVL(vvObservacao,' ');      
        END IF;  
                                                
      END LOOP; -- Fim do Cursor de Pesquisa dos Pedidos Gerados
      
      -- Se não encontrou ao menos um Pedido Importado        
      IF (NVL(viContaPedidosImport,0) = 0) THEN
        vbErrosImportacao := TRUE;
        vvObservacaoGeral := 'Não foram encontrados dados para importação do Pedido';
      END IF;
      
      -- Se ocorreram erros na Importação
      IF (vbErrosImportacao) THEN
      
        PMUDA_STATUS('ER',
                     vvObservacaoGeral,
                     vc_PedidosOperLog.INTEGRADORA,
                     vc_PedidosOperLog.CGCCLI,
                     vc_PedidosOperLog.NUMPEDVAN,
                     vc_PedidosOperLog.DTINCLUSAO);
                     
      -- Se NÃO ocorreram Erros na Importação
      ELSE

        PMUDA_STATUS('PR',
                     '', -- SEM OBSERVAÇÃO
                     vc_PedidosOperLog.INTEGRADORA,
                     vc_PedidosOperLog.CGCCLI,
                     vc_PedidosOperLog.NUMPEDVAN,
                     vc_PedidosOperLog.DTINCLUSAO);
      
      END IF;
                          
    END LOOP; -- Fim do Cursor de Pesquisa os Pedidos que estão em Processamento                          
    
 /******************************************************************************
  Se chamado da Geração dos Retornos
  **********************************/
  ELSIF (pi_nTipoChamada = 2) THEN

    -- Cursor de Pesquisa dos Retornos Pendentes de Geração
    FOR vc_CabRetorno IN (SELECT PCPEDRETORNO.NUMPEDRCA
                               , PCPEDRETORNO.CODUSUR
                               , PCPEDRETORNO.CGCCLI
                               , PCPEDRETORNO.DTABERTURAPEDPALM
                               , PCPEDRETORNO.NUMPEDVAN
                               , PCPEDRETORNO.NUMPED
                               , PCPEDRETORNO.NUMQUEBRA
                               , PCPEDRETORNO.CODFILIAL
                               , PCPEDRETORNO.DTINCLUSAOPEDOPERLOG
                               , PCPEDRETORNO.VERSAO
                               , PCPEDCFV.CODMOTIVONAOATEND
                               , PCPEDCFV.POSICAO_ATUAL
                            FROM PCPEDRETORNO
                               , PCPEDCFV
                           WHERE (PCPEDCFV.NUMPEDRCA             = PCPEDRETORNO.NUMPEDRCA)
                             AND (PCPEDCFV.CODUSUR               = PCPEDRETORNO.CODUSUR)
                             AND (PCPEDCFV.DTABERTURAPEDPALM     = PCPEDRETORNO.DTABERTURAPEDPALM)
                             AND (PCPEDCFV.CGCCLI                = PCPEDRETORNO.CGCCLI)
                             AND (PCPEDRETORNO.INTEGRADORA       = pi_nIntegradora)
                             AND ( ((NVL(PCPEDRETORNO.GEROURET,'N') = 'N') AND ((PCPEDCFV.IMPORTADO = 2 AND PCPEDCFV.POSICAO_ATUAL IN ('L', 'F', 'C')) OR (PCPEDCFV.IMPORTADO = 3))) OR
                                   (PCPEDCFV.IMPORTADO = 2 AND PCPEDCFV.POSICAO_ATUAL IN ('B')) ) 
                             ) LOOP
                             
      BEGIN                             
      
        -- Pesquisa a CGC da Filial
        BEGIN
          SELECT CGC
            INTO vvCgcFilial
            FROM PCFILIAL
           WHERE (CODIGO = vc_CabRetorno.CODFILIAL);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvCgcFilial := NULL;
        END;            
        vvCgcFilial := SUBSTR(vvCgcFilial, 1, 2) || '.' ||
                       SUBSTR(vvCgcFilial, 3, 3) || '.' ||
                       SUBSTR(vvCgcFilial, 6, 3) || '/' ||
                       SUBSTR(vvCgcFilial, 9, 4) || '-' ||
                       SUBSTR(vvCgcFilial, 13, 2);

        -- Pesquisa Prazo Médio de Cond. Venda do Pedido
        IF (NVL(vc_CabRetorno.NUMPED,0) > 0) THEN
          BEGIN
            SELECT PRAZO1
                 , PRAZO2
                 , PRAZO3
                 , PRAZO4
                 , PRAZO5
                 , PRAZO6
                 , PRAZO7
                 , PRAZO8
                 , PRAZO9
                 , PRAZO10
                 , PRAZO11
                 , PRAZO12
                 , CONDVENDA
              INTO vnPrazo1
                 , vnPrazo2
                 , vnPrazo3
                 , vnPrazo4
                 , vnPrazo5
                 , vnPrazo6
                 , vnPrazo7
                 , vnPrazo8
                 , vnPrazo9
                 , vnPrazo10
                 , vnPrazo11
                 , vnPrazo12
                 , vnCondVenda 
              FROM PCPEDC
             WHERE (NUMPED = vc_CabRetorno.NUMPED);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vnPrazo1     := NULL;
              vnPrazo2     := NULL;
              vnPrazo3     := NULL;
              vnPrazo4     := NULL;
              vnPrazo5     := NULL;
              vnPrazo6     := NULL;
              vnPrazo7     := NULL;
              vnPrazo8     := NULL;
              vnPrazo9     := NULL;
              vnPrazo10    := NULL;
              vnPrazo11    := NULL;
              vnPrazo12    := NULL;
              vnCondVenda  := NULL;
          END; 
          vnQtdePrazos := 0;
          vnSomaPrazos := 0;
          IF (vnPrazo1  IS NOT NULL) THEN vnSomaPrazos := NVL(vnSomaPrazos,0) + vnPrazo1;  vnQtdePrazos := NVL(vnQtdePrazos,0) + 1;  END IF;       
          IF (vnPrazo2  IS NOT NULL) THEN vnSomaPrazos := NVL(vnSomaPrazos,0) + vnPrazo2;  vnQtdePrazos := NVL(vnQtdePrazos,0) + 1;  END IF;       
          IF (vnPrazo3  IS NOT NULL) THEN vnSomaPrazos := NVL(vnSomaPrazos,0) + vnPrazo3;  vnQtdePrazos := NVL(vnQtdePrazos,0) + 1;  END IF;       
          IF (vnPrazo4  IS NOT NULL) THEN vnSomaPrazos := NVL(vnSomaPrazos,0) + vnPrazo4;  vnQtdePrazos := NVL(vnQtdePrazos,0) + 1;  END IF;       
          IF (vnPrazo5  IS NOT NULL) THEN vnSomaPrazos := NVL(vnSomaPrazos,0) + vnPrazo5;  vnQtdePrazos := NVL(vnQtdePrazos,0) + 1;  END IF;       
          IF (vnPrazo6  IS NOT NULL) THEN vnSomaPrazos := NVL(vnSomaPrazos,0) + vnPrazo6;  vnQtdePrazos := NVL(vnQtdePrazos,0) + 1;  END IF;       
          IF (vnPrazo7  IS NOT NULL) THEN vnSomaPrazos := NVL(vnSomaPrazos,0) + vnPrazo7;  vnQtdePrazos := NVL(vnQtdePrazos,0) + 1;  END IF;       
          IF (vnPrazo8  IS NOT NULL) THEN vnSomaPrazos := NVL(vnSomaPrazos,0) + vnPrazo8;  vnQtdePrazos := NVL(vnQtdePrazos,0) + 1;  END IF;       
          IF (vnPrazo9  IS NOT NULL) THEN vnSomaPrazos := NVL(vnSomaPrazos,0) + vnPrazo9;  vnQtdePrazos := NVL(vnQtdePrazos,0) + 1;  END IF;       
          IF (vnPrazo10 IS NOT NULL) THEN vnSomaPrazos := NVL(vnSomaPrazos,0) + vnPrazo10; vnQtdePrazos := NVL(vnQtdePrazos,0) + 1;  END IF;       
          IF (vnPrazo11 IS NOT NULL) THEN vnSomaPrazos := NVL(vnSomaPrazos,0) + vnPrazo11; vnQtdePrazos := NVL(vnQtdePrazos,0) + 1;  END IF;       
          IF (vnPrazo12 IS NOT NULL) THEN vnSomaPrazos := NVL(vnSomaPrazos,0) + vnPrazo12; vnQtdePrazos := NVL(vnQtdePrazos,0) + 1;  END IF;       
          --
          IF (NVL(vnQtdePrazos,0) > 0) THEN
            vnPrazoMedio := (NVL(vnSomaPrazos,0) / NVL(vnQtdePrazos,0));
          ELSE
            vnPrazoMedio := 0;
          END IF;
        ELSE
          vnPrazoMedio := 0;
          vnCondVenda  := NULL;
        END IF;
                                                                
        -- Insere Cabeçalho do Retorno
        BEGIN
          INSERT INTO PCRETCOPERLOG
                    ( INTEGRADORA
                    , CGCCLI
                    , NUMPEDVAN
                    , DTINCLUSAO
                    , NUMQUEBRA
                    , NUMPED
                    , CGCFILIAL
                    , VERSAO
                    , PRAZOMEDIO
                    , STATUS )
             VALUES ( pi_nIntegradora
                    , vc_CabRetorno.CGCCLI
                    , vc_CabRetorno.NUMPEDVAN
                    , vc_CabRetorno.DTINCLUSAOPEDOPERLOG
                    , vc_CabRetorno.NUMQUEBRA
                    , vc_CabRetorno.NUMPED
                    , vvCgcFilial
                    , vc_CabRetorno.VERSAO
                    , vnPrazoMedio
                    , 'NP' );                                      
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
            -- Se o Cabeçalho já existir, apaga Itens (Regeração do Retorno)
            DELETE FROM PCRETIOPERLOG
                  WHERE (INTEGRADORA = pi_nIntegradora)
                    AND (CGCCLI      = vc_CabRetorno.CGCCLI)
                    AND (NUMPEDVAN   = vc_CabRetorno.NUMPEDVAN)
                    AND (DTINCLUSAO  = vc_CabRetorno.DTINCLUSAOPEDOPERLOG)
                    AND (NUMQUEBRA   = vc_CabRetorno.NUMQUEBRA);
        END;                  

        -- Inicializa Totais do Pedido
        vnTotalQtUnidAtend    := 0;
        vnTotalQtUnidNaoAtend := 0; 
        vnQtItensAtend        := 0;
        vnQtItensNaoAtend     := 0;

        -- Cursor de Pesquisa dos Itens do Retorno
        FOR vc_ItensRetorno IN c_ItensRetorno(vc_CabRetorno.NUMPEDRCA,
                                              vc_CabRetorno.CGCCLI,
                                              vc_CabRetorno.CODUSUR,
                                              vc_CabRetorno.DTABERTURAPEDPALM) LOOP
              
          -- Pesquisa o Totais do Pedido Faturado
          SELECT SUM(PCPEDI.QT)
               , MAX(PCPEDI.PERDESC)
               , MAX(NVL(PCPEDI.PORIGINAL,PCPEDI.PTABELA))
               , MAX((NVL(PCPEDI.PORIGINAL,PCPEDI.PTABELA) * (1 - (PCPEDI.PERDESC/100))))
               , MAX(PCPEDI.ST)
               , MAX(PCPEDI.VLREPASSE)
               , MAX(PCPEDI.PVENDA)
               , MAX(PCPEDI.CODST)
            INTO vnQtAtend
               , vnPerDesc
               , vnPrecoBruto
               , vnPrecoLiquido
               , vnSt
               , vnVlRepasse
               , vnPrecoContabil
               , vnCodSt
            FROM PCPEDI
            WHERE (PCPEDI.NUMPED  = vc_CabRetorno.NUMPED)
              AND (PCPEDI.CODPROD = vc_ItensRetorno.CODPROD);
              
          -- Pesquisa a Aliquota de ICMS
          BEGIN
            IF (NVL(vnCondVenda,0) = 10) THEN
              SELECT CODICMTRANSF
                INTO vnAliqIcms
                FROM PCTRIBUT
               WHERE (CODST = vnCodSt);
            ELSE
              SELECT CODICM
                INTO vnAliqIcms
                FROM PCTRIBUT
               WHERE (CODST = vnCodSt);
             END IF; 
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vnAliqIcms := 0;
          END;
              
          -- Calcula a Quantidade não atendida            
          vnQtNaoAtend := (NVL(vc_ItensRetorno.QT,0) - NVL(vnQtAtend,0)); 
          IF (NVL(vnQtNaoAtend,0) < 0) THEN
            vnQtNaoAtend := 0;
          END IF;
          
          -- Define se o Item foi Atendido 
          IF    (NVL(vnQtAtend,0)  = 0) THEN
            -- Rejeitado
            vnSitAtendItem := 3;
          ELSIF (NVL(vnQtAtend,0) >= NVL(vc_ItensRetorno.QT,0)) THEN
            -- Atendimento Total
            vnSitAtendItem := 1;
          ELSE
            -- Atendimento Parcial
            vnSitAtendItem := 2;
          END IF;
          
          -- Se ocorreu Atendimento Parcial ou Total e o Pedido está em Anáise de Crédito
          IF    ((NVL(vnQtAtend,0) > 0) AND
                 (NVL(vc_CabRetorno.POSICAO_ATUAL,' ') = 'B')) THEN
            -- Define Motivo Pedido em Análise de Crédito
            vnCodMotivoNaoAtendItem := 800;
            -- Pesquisa o Motivo de Não Atendimento
            BEGIN
              SELECT CODMOTIVOLAYOUT
                   , DESCMOTIVOLAYOUT
                INTO vvCodMotivoNaoAtendLayout
                   , vvDescMotivoNaoAtendLayout
                FROM PCMOTIVONAOATENDLAYOUT
               WHERE (CODMOTIVONAOATEND = vnCodMotivoNaoAtendItem)
                 AND (LAYOUT            = 16)
                 AND (TIPOREG           = 'A');
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vvCodMotivoNaoAtendLayout  := NULL;
                vvDescMotivoNaoAtendLayout := NULL;
            END;
          -- Se ocorreram Rejeições, define o Motivo de Não Atendimento
          ELSIF (NVL(vnQtNaoAtend,0) > 0) THEN
            -- Se tem Motivo no Item, pega o do Item
            IF (NVL(vc_ItensRetorno.CODMOTIVONAOATEND,0) > 0) THEN
              vnCodMotivoNaoAtendItem := vc_ItensRetorno.CODMOTIVONAOATEND;
            -- Se NÃO tem Motivo no Item, pega o do Cabeçalho
            ELSE
              vnCodMotivoNaoAtendItem := vc_CabRetorno.CODMOTIVONAOATEND;
            END IF;
            -- Se continua sem Motivo, o motivo será Corte Logístico
            IF (NVL(vnCodMotivoNaoAtendItem,0) = 0) THEN
              vnCodMotivoNaoAtendItem := 40;
            END IF;
            -- Pesquisa o Motivo de Não Atendimento
            BEGIN
              SELECT CODMOTIVOLAYOUT
                   , DESCMOTIVOLAYOUT
                INTO vvCodMotivoNaoAtendLayout
                   , vvDescMotivoNaoAtendLayout
                FROM PCMOTIVONAOATENDLAYOUT
               WHERE (CODMOTIVONAOATEND = vnCodMotivoNaoAtendItem)
                 AND (LAYOUT            = 16)
                 AND (TIPOREG           = 'A');
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vvCodMotivoNaoAtendLayout  := NULL;
                vvDescMotivoNaoAtendLayout := NULL;
            END;
          ELSE
            vvCodMotivoNaoAtendLayout  := NULL;
            vvDescMotivoNaoAtendLayout := NULL;
          END IF;
                    
          -- Insere Item do Pedido no Retorno
          INSERT INTO PCRETIOPERLOG
                    ( INTEGRADORA
                    , CGCCLI
                    , NUMPEDVAN
                    , DTINCLUSAO
                    , NUMQUEBRA
                    , NUMSEQ
                    , TIPOCODINTEGRACAO
                    , CODINTEGRACAO
                    , SITATEND
                    , QTATEND
                    , QTNAOATEND
                    , CODMOTIVONAOATEND
                    , DESCMOTIVONAOATEND
                    , PRECOBRUTO
                    , PERCDESC
                    , PRECOLIQUIDO
                    , VLST
                    , VLREPASSE
                    , PRECOCONTABIL
                    , ALIQICMS )
             VALUES ( pi_nIntegradora
                    , vc_CabRetorno.CGCCLI
                    , vc_CabRetorno.NUMPEDVAN
                    , vc_CabRetorno.DTINCLUSAOPEDOPERLOG
                    , vc_CabRetorno.NUMQUEBRA
                    , vc_ItensRetorno.NUMSEQ
                    , vc_ItensRetorno.TIPOCODINTEGRACAO
                    , vc_ItensRetorno.CODPRODOL
                    , vnSitAtendItem
                    , NVL(vnQtAtend,0)
                    , NVL(vnQtNaoAtend,0)
                    , vvCodMotivoNaoAtendLayout
                    , vvDescMotivoNaoAtendLayout
                    , vnPrecoBruto
                    , vnPerDesc
                    , vnPrecoLiquido
                    , vnSt
                    , vnVlRepasse
                    , vnPrecoContabil
                    , vnAliqIcms );

          -- Acumula Totais do Pedido
          vnTotalQtUnidAtend    := NVL(vnTotalQtUnidAtend,0)    + NVL(vnQtAtend,0);
          vnTotalQtUnidNaoAtend := NVL(vnTotalQtUnidNaoAtend,0) + NVL(vnQtNaoAtend,0); 
          IF (NVL(vnQtAtend,0) > 0) THEN
            vnQtItensAtend      := NVL(vnQtItensAtend,0)        + 1;
          ELSE
            vnQtItensNaoAtend   := NVL(vnQtItensNaoAtend,0)     + 1;
          END IF;
                                               
        END LOOP; -- Fim Cursor de Pesquisa dos Itens do Retorno                                           
        
        -- Define se o Pedido foi Atendido 
        IF    (NVL(vnTotalQtUnidAtend,0) = 0) THEN
          -- Rejeitado
          vnSitAtendCab := 3;
        ELSIF ((NVL(vnTotalQtUnidAtend   ,0) >= 0) AND
               (NVL(vnTotalQtUnidNaoAtend,0)  = 0)) THEN
          -- Atendimento Total
          vnSitAtendCab := 1;
        ELSE
          -- Atendimento Parcial
          vnSitAtendCab := 2;
        END IF;
        
        -- Atualiza Cabeçalho do Retorno
        UPDATE PCRETCOPERLOG
           SET STATUS          = 'NP' -- Caso já exista e seja reprocessamento
             , OBSERVACAO      = NULL
             , DATAPROC        = NULL                  
             , SITATEND        = vnSitAtendCab
             , QTUNIDATEND     = NVL(vnTotalQtUnidAtend,0)
             , QTUNIDNAOATEND  = NVL(vnTotalQtUnidNaoAtend,0)
             , QTITENSATEND    = NVL(vnQtItensAtend,0)
             , QTITENSNAOATEND = NVL(vnQtItensNaoAtend,0)
         WHERE (INTEGRADORA = pi_nIntegradora)
           AND (CGCCLI      = vc_CabRetorno.CGCCLI)
           AND (NUMPEDVAN   = vc_CabRetorno.NUMPEDVAN)
           AND (DTINCLUSAO  = vc_CabRetorno.DTINCLUSAOPEDOPERLOG)
           AND (NUMQUEBRA   = vc_CabRetorno.NUMQUEBRA);
           
        -- Atualiza Flag de Geração do Retorno se não estiver Bloqueado
        IF (NVL(vc_CabRetorno.POSICAO_ATUAL,' ') <> 'B') THEN
          UPDATE PCPEDRETORNO
             SET GEROURET = 'S'
               , DTGERRET = SYSDATE
           WHERE (NUMPEDRCA         = vc_CabRetorno.NUMPEDRCA)
             AND (CGCCLI            = vc_CabRetorno.CGCCLI)
             AND (CODUSUR           = vc_CabRetorno.CODUSUR)
             AND (DTABERTURAPEDPALM = vc_CabRetorno.DTABERTURAPEDPALM);
        END IF;
        
        -- EFETIVA TRANSACOES
        COMMIT; 

        -- Quantidade de Registros Processados
        po_nQtdeRegProc := NVL(po_nQtdeRegProc,0) + 1;
      
      EXCEPTION
        WHEN OTHERS THEN
          -- Desfaz Transações
          ROLLBACK;
          -- Retorno com os Erros
          po_vOcorreramErros := 'S';
          po_vMsgErros       := NVL(po_vMsgErros,' ') || '[Pedido VAN: ' || vc_CabRetorno.NUMPEDVAN || ' Erro : ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM || '] ';
      END;
                 
    END LOOP; -- Fim do Cursor de Pesquisa dos Retornos
                          
  END IF; -- Fim Condição Tipo Chamada

EXCEPTION  
  WHEN OTHERS THEN      
    -- Desfaz Transações
    ROLLBACK;
    -- Retorno com os Erros
    po_vOcorreramErros := 'S';
    po_vMsgErros       := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM;
END PRC_MED_IMPORT_PEDOPERLOG;
 
 
 