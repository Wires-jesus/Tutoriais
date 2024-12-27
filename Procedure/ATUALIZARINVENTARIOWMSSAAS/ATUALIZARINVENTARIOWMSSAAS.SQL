CREATE OR REPLACE PROCEDURE ATUALIZARINVENTARIOWMSSAAS(pCodfilial IN VARCHAR2,
                                                       pNuminvent IN NUMBER) IS
  vNUMINVENT       NUMBER(8);
  vCODFILIAL       VARCHAR2(2);
  vNUMTRANSVENDA   NUMBER(10);
  vNUMTRANSENT     NUMBER(10);
  vNUMLANCAMENTO   NUMBER(10);
  vCODOPER         VARCHAR2(2);
  vQTDIVERGENTE    NUMBER(20, 6);
  vPUNIT           NUMBER(20, 6);
  vCUSTOREAL       NUMBER(20, 6);
  vCUSTOREP        NUMBER(20, 6);
  vCUSTOFIN        NUMBER(20, 6);
  vCUSTOULTENT     NUMBER(20, 6);
  vCUSTOCONT       NUMBER(20, 6);
  vTIPOCONTAAJUSTE VARCHAR2(2);
  vCUSTOINVENTARIO NUMBER(20, 6);
  vCODCONTAAJUSTE  NUMBER(10);
  VNUMTRANSITEM    NUMBER(18);

  RETORNO NUMBER;
  vnERRO EXCEPTION;
  vsMSGRETORNO VARCHAR2(1000) := 'OK';
  
  
  /*---------------------Carrega os custos dos Produtos--------------------------*/
  PROCEDURE CARREGARCUSTOSDOPRODUTO(vCODPROD NUMBER, vCODFILIAL VARCHAR2) IS
  BEGIN
    SELECT DECODE(vTIPOCONTAAJUSTE,
                  'R',
                  NVL(CUSTOREAL, 0),
                  'P',
                  NVL(CUSTOREP, 0),
                  'F',
                  NVL(CUSTOFIN, 0),
                  'U',
                  NVL(CUSTOULTENT, 0),
                  0) AS PUNIT,
           NVL(CUSTOREAL, 0) AS CUSTOREAL,
           NVL(CUSTOREP, 0) AS CUSTOREP,
           NVL(CUSTOFIN, 0) AS CUSTOFIN,
           NVL(CUSTOULTENT, 0) AS CUSTOULTENT,
           NVL(CUSTOCONT, 0) AS CUSTOCONT
    
      INTO vPUNIT,
           vCUSTOREAL,
           vCUSTOREP,
           vCUSTOFIN,
           vCUSTOULTENT,
           vCUSTOCONT
      FROM PCEST
     WHERE CODPROD = vCODPROD
       AND CODFILIAL = vCODFILIAL
       AND ROWNUM = 1;
  END;

BEGIN
  vNUMTRANSVENDA   := 0;
  vNUMTRANSENT     := 0;
  vNUMLANCAMENTO   := 0;
  vCODOPER         := 'X';
  vQTDIVERGENTE    := 0;
  vTIPOCONTAAJUSTE := 'X';
  vCUSTOINVENTARIO := 0;
  vPUNIT           := 0;
  vCUSTOREAL       := 0;
  vCUSTOREP        := 0;
  vCUSTOFIN        := 0;
  vCUSTOULTENT     := 0;
  vCUSTOCONT       := 0;
  vCODCONTAAJUSTE  := 0;
  vNUMINVENT       := pNuminvent;
  vCODFILIAL       := pCodfilial;
  VNUMTRANSITEM    := 0;
  RETORNO          := 0;
  
  -------VERIFICANDO TIPO DE AJUSTE DA 132 PARA GRAVAR O PUNIT E A CONTA PARA GRAVAR A PCLANC--------
  select tipocustoajuste, CODCONTAJUSTEEST
    INTO vTIPOCONTAAJUSTE, vCODCONTAAJUSTE
    from Pcconsum
   where rownum = 1;

  ------Buscar transações de entrada para inserir PCMOV ---------
  SELECT NVL(PROXNUMTRANSENT, 1) AS PROXNUMTRANSENT
    INTO vNUMTRANSENT
    FROM PCCONSUM
     FOR UPDATE;

  UPDATE PCCONSUM SET PROXNUMTRANSENT = NVL(PROXNUMTRANSENT, 1) + 1;

  ------Buscar transações de saída para inserir PCMOV ---------
  SELECT NVL(PROXNUMTRANSVENDA, 1) AS PROXNUMTRANSVENDA
    INTO vNUMTRANSVENDA
    FROM PCCONSUM
     FOR UPDATE;

  UPDATE PCCONSUM SET PROXNUMTRANSVENDA = NVL(PROXNUMTRANSVENDA, 1) + 1;

  ------Buscar o numero do proximo lançamento para inserir PCLANC ---------
  SELECT DECODE(NVL(PROXNUMLANC, 0), 0, 1, PROXNUMLANC)
    INTO vNUMLANCAMENTO
    FROM PCCONSUM
     FOR UPDATE;

  UPDATE PCCONSUM
     SET PROXNUMLANC = DECODE(NVL(PROXNUMLANC, 0), 0, 1, PROXNUMLANC) + 1;

  ----LAÇO PARA GRAVAR A PCMOV de Produtos sem controle de Lote---
  FOR REG IN (SELECT W.numinvent,
                     W.codprod,
                     W.codfilial,
                     NVL(W.ATUALIZARITEM, 'N') AS ATUALIZARITEM,
                     NVL(P.ESTOQUEPORLOTE, 0) AS ESTOQUEPORLOTE,
                     (nvl(SUM(W.qtwms), 0) -
                     (SELECT NVL(SUM(QTESTGER), 0)
                         FROM PCEST
                        WHERE CODPROD = W.CODPROD
                          AND CODFILIAL = W.CODFILIAL)) AS QTDIV,
                     (SELECT NVL(SUM(QTESTGER), 0)
                        FROM PCEST
                       WHERE CODPROD = W.CODPROD
                         AND CODFILIAL = W.CODFILIAL) AS QTWINTHOR,
                     PKG_ESTOQUE.ESTOQUE_DISPONIVEL(W.CODPROD,
                                                    W.CODFILIAL,
                                                    'V') AS QTDISPWINTHOR,
                     NVL(SUM(W.qtavariawms), 0) AS QTAVARIAWMS,
                     NVL(SUM(W.qtbloqueadawms), 0) AS QTBLOQUEDAWMS
                FROM PCINTEGRACAOINVENTWMS W, PCPRODUT P
               WHERE W.NUMINVENT = vNUMINVENT
                 AND W.DTATUALIZACAO IS NULL
                 AND NVL(W.ATUALIZARITEM, 'N') = 'S'
                 AND W.CODPROD = P.CODPROD
               GROUP BY W.numinvent,
                        W.codprod,
                        W.codfilial,
                        W.ATUALIZARITEM,
                        P.ESTOQUEPORLOTE)
  
   LOOP
  
    ----ATUALIZAR QUANTIDADE ANTERIOR AO INVENTARIO, AVARIA E DATA DO ULTIMO INVENTARIO -----
    IF REG.ATUALIZARITEM = 'S' THEN
      UPDATE PCEST
         SET QTULTINVENT = QTESTGER,
             PCUSTOANT   = CUSTOFIN,
             DTULTINVENT = SYSDATE,
             QTINDENIZ   = REG.QTAVARIAWMS,
             QTBLOQUEADA = REG.QTAVARIAWMS + REG.QTBLOQUEDAWMS
       WHERE CODPROD = REG.CODPROD
         AND CODFILIAL = REG.CODFILIAL;
    END IF;
  
    vQTDIVERGENTE := REG.QTDIV;
  
    IF vQTDIVERGENTE > 0 THEN
      vCODOPER := 'EI';
    END IF;
  
    IF vQTDIVERGENTE < 0 THEN
      vCODOPER := 'SI';
    END IF;
  
    IF vQTDIVERGENTE = 0 THEN
      vCODOPER := 'X';
    END IF;
  
    CARREGARCUSTOSDOPRODUTO(REG.CODPROD, REG.CODFILIAL);
  
    UPDATE PCINTEGRACAOINVENTWMS
       SET CUSTO         = vPUNIT,
           QTWINTHOR     = REG.QTWINTHOR,
           QTDISPWINTHOR = REG.QTDISPWINTHOR
     WHERE NUMINVENT = vNUMINVENT
       AND CODPROD = REG.CODPROD;
  
    IF ((vCODOPER = 'EI') OR (vCODOPER = 'SI')) AND
       (REG.ESTOQUEPORLOTE = 'N') AND (REG.ATUALIZARITEM = 'S') THEN
    
      vCUSTOINVENTARIO := vCUSTOINVENTARIO + (ABS(vQTDIVERGENTE) * vPUNIT);
    
      ----GERAR PCMOV 'EI' e 'SI' -----
      INSERT INTO PCMOV
        (DTMOV,
         CODPROD,
         NUMLOTE,
         NUMNOTA,
         CODOPER,
         QT,
         CODFILIAL,
         STATUS,
         CODFUNCLANC,
         NUMTRANSENT,
         NUMTRANSVENDA,
         ROTINALANC,
         QTESTGERANT,
         COMPLEMENTO,
         CUSTOFIN,
         CUSTOCONT,
         CUSTOREAL,
         CUSTOREP,
         PUNIT)
      values
        (SYSDATE,
         REG.CODPROD,
         DECODE(REG.ESTOQUEPORLOTE, 'S', '1', NULL),
         REG.NUMINVENT,
         DECODE(vCODOPER, 'EI', 'EI', 'SI'),
         ABS(REG.QTDIV),
         REG.CODFILIAL,
         'B',
         1,
         DECODE(vCODOPER, 'EI', vNUMTRANSENT, 0),
         DECODE(vCODOPER, 'SI', vNUMTRANSVENDA, 0),
         'INTEGRACAO WMS SAAS',
         (SELECT QTESTGER
            FROM PCEST
           WHERE CODPROD = REG.CODPROD
             AND CODFILIAL = REG.CODFILIAL),
         'INTEGRACAO WMS SAAS',
         vCUSTOFIN,
         vCUSTOCONT,
         vCUSTOREAL,
         vCUSTOREP,
         vPUNIT);
    
    END IF;
  END LOOP;
  ----FIM DO LAÇO PARA GRAVAR A PCMOV Operações 'EI' e 'SI' para movimentar a PCEST---

  -----------GERAÇÃO DA PCMOV PARA AJUSTES PARA PRODUTOS QUE USAM CONTROLE DE LOTE ------------

  FOR LOTES IN (SELECT W.codprod,
                       W.codfilial,
                       W.numlote,
                       'S' AS ATUALIZARITEM,
                       W.dtvalidade as dtval,
                       NVL(SUM(W.qt), 0) AS QT,
                       NVL(SUM(W.qtindeniz), 0) AS QTAVARIA,
                       NVL(SUM(W.qtbloqueada), 0) AS QTBLOQUEADA,
                       NVL(SUM(W.qt), 0) AS QTDIV,
                       'S' AS EXISTEREGISTROPCLOTE,
                       'LOTE_INEXISTENTE_WMS' AS SITUACAOLOTE
                  FROM PCLOTE W, PCPRODUT P
                 WHERE W.CODPROD IN
                       (SELECT DISTINCT CODPROD
                          FROM PCINTEGRACAOINVENTWMS W
                         WHERE W.NUMINVENT = vNUMINVENT
                           AND W.ATUALIZARITEM = 'S')
                   AND W.CODPROD = P.CODPROD
                   AND P.ESTOQUEPORLOTE = 'S'
                   AND NOT EXISTS (SELECT 1
                          FROM PCINTEGINVENTWMSLOTES
                         WHERE CODPROD = W.CODPROD
                           AND NUMLOTE = W.NUMLOTE)
                 GROUP BY W.codprod, W.codfilial, W.numlote, W.dtvalidade
                UNION ALL
                
                SELECT W.codprod,
                       W.codfilial,
                       W.numlote,
                       'S' AS ATUALIZARITEM,
                       W.dtval,
                       NVL(SUM(W.qtwms), 0) AS QT,
                       NVL(SUM(W.qtavariawms), 0) AS QTAVARIA,
                       NVL(SUM(W.qtbloqueadawms), 0) AS QTBLOQUEADA,
                       NVL((SUM(qtwms) - NVL((SELECT SUM(QT)
                                               FROM PCLOTE
                                              WHERE CODPROD = W.CODPROD
                                                AND CODFILIAL = W.CODFILIAL
                                                AND NUMLOTE = W.NUMLOTE),
                                             0)),
                           0) AS QTDIV,
                       DECODE((SELECT COUNT(1)
                                FROM PCLOTE
                               WHERE CODPROD = W.CODPROD
                                 AND NUMLOTE = W.NUMLOTE),
                              0,
                              'N',
                              'S') AS EXISTEREGISTROPCLOTE,
                       'LOTE_EXISTENTE_WMS' AS SITUACAOLOTE
                  FROM PCINTEGINVENTWMSLOTES W
                 WHERE W.NUMINVENT = vNUMINVENT
                   AND 'S' = DECODE((SELECT COUNT(1)
                                      FROM PCINTEGRACAOINVENTWMS
                                     WHERE NUMINVENT = vNUMINVENT
                                       AND CODPROD = W.CODPROD
                                       AND ATUALIZARITEM = 'S'),
                                    0,
                                    'N',
                                    'S')
                 GROUP BY W.codprod, W.codfilial, W.numlote, W.dtval)
  
   LOOP
    vCODOPER := 'X';
  
    IF (LOTES.QTDIV > 0) AND (LOTES.SITUACAOLOTE = 'LOTE_EXISTENTE_WMS') THEN
      vCODOPER := 'EI';
    END IF;
  
    IF (LOTES.QTDIV < 0 AND (LOTES.SITUACAOLOTE = 'LOTE_EXISTENTE_WMS')) OR
       (LOTES.QTDIV > 0 AND (LOTES.SITUACAOLOTE = 'LOTE_INEXISTENTE_WMS')) THEN
      vCODOPER := 'SI';
    END IF;
  
    CARREGARCUSTOSDOPRODUTO(LOTES.CODPROD, LOTES.CODFILIAL);
  
    UPDATE PCINTEGRACAOINVENTWMS
       SET CUSTO         = vPUNIT,
           QTWINTHOR     = (SELECT SUM(QTESTGER)
                              FROM PCEST
                             WHERE CODPROD = LOTES.CODPROD
                               AND CODFILIAL = LOTES.CODFILIAL),
           QTDISPWINTHOR = PKG_ESTOQUE.ESTOQUE_DISPONIVEL(LOTES.CODPROD,
                                                          LOTES.CODFILIAL,
                                                          'V')
     WHERE NUMINVENT = vNUMINVENT
       AND CODPROD = LOTES.CODPROD;
  
    IF ((vCODOPER = 'EI') OR (vCODOPER = 'SI')) AND
       (LOTES.ATUALIZARITEM = 'S') THEN
    
      vCUSTOINVENTARIO := vCUSTOINVENTARIO + (ABS(LOTES.QTDIV) * vPUNIT);
    
      ----GERAR PCMOV para movimentação dos lotes -----
      INSERT INTO PCMOV
        (DTMOV,
         CODPROD,
         NUMLOTE,
         NUMNOTA,
         CODOPER,
         QT,
         CODFILIAL,
         STATUS,
         CODFUNCLANC,
         NUMTRANSENT,
         NUMTRANSVENDA,
         ROTINALANC,
         QTESTGERANT,
         COMPLEMENTO,
         CUSTOFIN,
         CUSTOCONT,
         CUSTOREAL,
         CUSTOREP,
         PUNIT)
      values
        (SYSDATE,
         LOTES.CODPROD,
         LOTES.NUMLOTE,
         vNUMINVENT,
         DECODE(vCODOPER, 'EI', 'EI', 'SI'),
         ABS(LOTES.QTDIV),
         LOTES.CODFILIAL,
         'B',
         1,
         DECODE(vCODOPER, 'EI', vNUMTRANSENT, 0),
         DECODE(vCODOPER, 'SI', vNUMTRANSVENDA, 0),
         'INTEGRACAO WMS SAAS',
         (SELECT QTESTGER
            FROM PCEST
           WHERE CODPROD = LOTES.CODPROD
             AND CODFILIAL = LOTES.CODFILIAL),
         'INTEGRACAO WMS SAAS',
         vCUSTOFIN,
         vCUSTOCONT,
         vCUSTOREAL,
         vCUSTOREP,
         vPUNIT
         
         );
    
    END IF;
  
    ------ATUALIZAÇÃO DA AVARIA NO LOTE DO GESTÃO--------
  
    IF LOTES.ATUALIZARITEM = 'S' THEN
      UPDATE PCLOTE
      
         SET QTINDENIZ   = LOTES.QTAVARIA,
             QTBLOQUEADA = LOTES.QTAVARIA + LOTES.QTBLOQUEADA
       WHERE CODPROD = LOTES.CODPROD
         AND CODFILIAL = LOTES.CODFILIAL
         AND NUMLOTE = LOTES.NUMLOTE;
    END IF;
  
  END LOOP;
  -----------FIM GERAÇÃO DA PCMOV PARA AJUSTES DOS LOTES OPERAÇÕES 'EA' e 'SA'------------

  -----Ajuste de possivel divergencia de lote-----
  FOR AJUSTELOTES IN (SELECT W.CODFILIAL,
                             W.CODPROD,
                             W.NUMLOTE,
                             MAX(W.DTVAL) AS DTVAL,
                             SUM(W.QTWMS) AS QTWMS,
                             SUM(L.QT) AS QTLOTEGESTAO,
                             SUM(W.qtavariawms) AS QTAVARIA,
                             SUM(L.QTINDENIZ) AS QTLOTEGESTAOAVARIA,
                             'AJUSTE' AS ACAO
                        FROM PCINTEGINVENTWMSLOTES W, PCLOTE L, PCPRODUT P
                       WHERE W.NUMLOTE = L.NUMLOTE
                         AND W.CODPROD = L.CODPROD
                         AND W.CODPROD = P.CODPROD
                         AND P.ESTOQUEPORLOTE = 'S'
                         AND W.NUMINVENT = vNUMINVENT
                         AND 'S' = DECODE((SELECT COUNT(1)
                                            FROM PCINTEGRACAOINVENTWMS
                                           WHERE NUMINVENT = vNUMINVENT
                                             AND CODPROD = W.CODPROD
                                             AND ATUALIZARITEM = 'S'),
                                          0,
                                          'N',
                                          'S')
                         AND W.CODFILIAL = L.CODFILIAL
                       GROUP BY W.CODFILIAL,
                                W.CODPROD,
                                W.NUMLOTE,
                                P.ESTOQUEPORLOTE
                      UNION ALL
                      
                      SELECT L.CODFILIAL,
                             L.CODPROD,
                             L.NUMLOTE,
                             MAX(L.dtvalidade) AS DTVAL,
                             0 AS QTWMS,
                             SUM(L.QT) AS QTLOTEGESTAO,
                             0 AS QTAVARIA,
                             SUM(L.QTINDENIZ) AS QTLOTEGESTAOAVARIA,
                             'EXCLUIR' AS ACAO
                        FROM PCLOTE L, PCPRODUT P
                       WHERE NOT EXISTS (SELECT 1
                                FROM PCINTEGINVENTWMSLOTES
                               WHERE CODPROD = L.CODPROD
                                 AND NUMLOTE = L.NUMLOTE
                                 AND NUMINVENT = vNUMINVENT)
                         AND L.CODPROD = P.CODPROD
                         AND P.ESTOQUEPORLOTE = 'S'
                         AND L.CODPROD IN
                             (SELECT DISTINCT CODPROD
                                FROM PCINTEGRACAOINVENTWMS
                               WHERE NUMINVENT = vNUMINVENT
                                 AND ATUALIZARITEM = 'S')
                         AND L.CODFILIAL = vCODFILIAL
                       GROUP BY L.CODFILIAL,
                                L.CODPROD,
                                L.NUMLOTE,
                                P.ESTOQUEPORLOTE)
  
   LOOP
    IF AJUSTELOTES.ACAO = 'EXCLUIR' THEN
      DELETE PCLOTE
       WHERE CODPROD = AJUSTELOTES.CODPROD
         AND NUMLOTE = AJUSTELOTES.NUMLOTE
         AND CODFILIAL = AJUSTELOTES.CODFILIAL;
    END IF;
  
    IF AJUSTELOTES.ACAO = 'AJUSTE' THEN
      UPDATE PCLOTE
         SET QT = AJUSTELOTES.QTWMS, DTVALIDADE = AJUSTELOTES.DTVAL
       WHERE CODPROD = AJUSTELOTES.CODPROD
         AND NUMLOTE = AJUSTELOTES.NUMLOTE
         AND CODFILIAL = AJUSTELOTES.CODFILIAL;
    END IF;
  
  END LOOP;

  -----fim do Ajuste de possivel divergencia de lote-----

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
    (vNUMLANCAMENTO,
     TRUNC(SYSDATE),
     vCODCONTAAJUSTE,
     0,
     'REF ATUALIZACAO INVENTARIO VIA INTEGRACAO SAAS',
     vNUMINVENT,
     '1',
     vCUSTOINVENTARIO * (-1),
     TRUNC(SYSDATE),
     vCUSTOINVENTARIO * (-1),
     TRUNC(SYSDATE),
     vCODFILIAL,
     'B',
     'O',
     'INTEGRACAO WMS SAAS');

  -----------PROCESSA CENTRO DE CUSTO LANÇAMENTO FINANCEIRO---------------
  ProcessaCentroDeCusto(vCODFILIAL, vCODCONTAAJUSTE, 'FINANCEIRO', vNUMLANCAMENTO);

  -----GERAR PCMOVCOMPLE DO INVENTARIO------
  FOR MOV IN (SELECT ROWID ID, NUMNOTA
                FROM PCMOV
               WHERE NUMNOTA = vNUMINVENT
                 AND CODOPER IN ('EI', 'SI', 'SA', 'EA')
                 AND STATUS = 'B'
                 AND TRUNC(DTMOV) = TRUNC(SYSDATE)
               ORDER BY ROWID) LOOP
  
    SELECT DFSEQ_PCMOVCOMPLE.NEXTVAL INTO VNUMTRANSITEM FROM DUAL;
  
    UPDATE PCMOV SET NUMTRANSITEM = VNUMTRANSITEM WHERE ROWID = MOV.ID;
  
    INSERT INTO PCMOVCOMPLE
      (NUMTRANSITEM, DTREGISTRO, NUMINVENT)
    VALUES
      (VNUMTRANSITEM, TRUNC(SYSDATE), MOV.NUMNOTA);
  
  END LOOP;

  ----ATUALIZAÇÃO DA PCEST USANDO A PKG_ESTOQUE(SAIDA)-----
  SELECT COUNT(1)
    INTO RETORNO
    FROM PCMOV
   WHERE NUMTRANSVENDA = vNUMTRANSVENDA
     AND NUMNOTA = vNUMINVENT
     AND CODOPER = 'SI';

  IF RETORNO > 0 THEN
    BEGIN
      RETORNO := PKG_ESTOQUE.VENDAS_SAIDA(vNUMTRANSVENDA, 'N', vsMSGRETORNO);
      IF NVL(vsMSGRETORNO, 'OK') <> 'OK' THEN
        RAISE vnERRO;
      END IF;
    
      IF RETORNO <= 0 THEN
        VSMSGRETORNO := 'Não houve movimentação de estoque para a transação informada';
        RAISE vnERRO;
      END IF;
    
    EXCEPTION
      WHEN vnERRO THEN
        RAISE_APPLICATION_ERROR(-20099, vsMSGRETORNO);
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20010,
                                'Erro ao executar movimentação de estoque.' ||
                                CHR(13) || SQLERRM);
    END;
  END IF;

  ----ATUALIZAÇÃO DA PCEST USANDO A PKG_ESTOQUE(ENTRADA)-----
  SELECT COUNT(1)
    INTO RETORNO
    FROM PCMOV
   WHERE NUMTRANSENT = vNUMTRANSENT
     AND NUMNOTA = vNUMINVENT
     AND CODOPER = 'EI';

  IF RETORNO > 0 THEN
    BEGIN
      RETORNO := PKG_ESTOQUE.VENDAS_ENTRADA(vNUMTRANSENT, 'N', vsMSGRETORNO);
      IF NVL(vsMSGRETORNO, 'OK') <> 'OK' THEN
        RAISE vnERRO;
      END IF;
    
      IF RETORNO <= 0 THEN
        VSMSGRETORNO := 'Não houve movimentação de estoque para a transação informada';
        RAISE vnERRO;
      END IF;
    
    EXCEPTION
      WHEN vnERRO THEN
        RAISE_APPLICATION_ERROR(-20099, vsMSGRETORNO);
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20010,
                                'Erro ao executar movimentação de estoque.' ||
                                CHR(13) || SQLERRM);
    END;
  END IF;

  ----Ajuste caso antes da Atualização já houver divergencia entre PCEST x PCLOTE no Gestao

  FOR DIVPCESTPCLOTE IN (SELECT DISTINCT W.CODPROD, W.CODFILIAL
                           FROM PCINTEGRACAOINVENTWMS W, PCPRODUT P
                          WHERE NUMINVENT = vNUMINVENT
                            AND W.CODPROD = P.CODPROD
                            AND NVL(W.ATUALIZARITEM, 'N') = 'S'
                            AND W.DTATUALIZACAO IS NULL
                            AND P.ESTOQUEPORLOTE = 'S')
  
   LOOP
    UPDATE PCEST
       SET QTESTGER    = NVL((SELECT SUM(NVL(QT, 0))
                               FROM PCLOTE
                              WHERE CODPROD = DIVPCESTPCLOTE.CODPROD
                                AND CODFILIAL = DIVPCESTPCLOTE.CODFILIAL),
                             0),
           QTINDENIZ   = NVL((SELECT SUM(NVL(QTINDENIZ, 0))
                               FROM PCLOTE
                              WHERE CODPROD = DIVPCESTPCLOTE.CODPROD
                                AND CODFILIAL = DIVPCESTPCLOTE.CODFILIAL),
                             0),
           QTBLOQUEADA = NVL((SELECT SUM(NVL(QTBLOQUEADA, 0))
                               FROM PCLOTE
                              WHERE CODPROD = DIVPCESTPCLOTE.CODPROD
                                AND CODFILIAL = DIVPCESTPCLOTE.CODFILIAL),
                             0)
     WHERE CODPROD = DIVPCESTPCLOTE.CODPROD
       AND CODFILIAL = DIVPCESTPCLOTE.CODFILIAL;
  END LOOP;
  ----Fim Ajuste caso antes da Atualização já houver divergencia entre PCEST x PCLOTE no Gestao

  UPDATE PCINTEGRACAOINVENTWMS
     SET DTATUALIZACAO = TRUNC(SYSDATE)
   WHERE NUMINVENT = vNUMINVENT;

  --------ATUALIZAR INFORMAÇÕES DE HISTORICO GERENCIAL DOS ITENS NÃO ATUALIZADOS-----------

  FOR NAOATUALIZADOS IN (SELECT W.CODPROD,
                                W.CODFILIAL,
                                (SELECT NVL(SUM(QTESTGER), 0)
                                   FROM PCEST
                                  WHERE CODPROD = W.CODPROD
                                    AND CODFILIAL = W.CODFILIAL) AS QTWINTHOR,
                                PKG_ESTOQUE.ESTOQUE_DISPONIVEL(W.CODPROD,
                                                               W.CODFILIAL,
                                                               'V') AS QTDISPWINTHOR
                           FROM PCINTEGRACAOINVENTWMS W
                          WHERE W.NUMINVENT = vNUMINVENT
                            AND NVL(W.ATUALIZARITEM, 'N') = 'N')
  
   LOOP
    CARREGARCUSTOSDOPRODUTO(NAOATUALIZADOS.CODPROD,
                            NAOATUALIZADOS.CODFILIAL);
  
    UPDATE PCINTEGRACAOINVENTWMS
       SET CUSTO         = vPUNIT,
           QTWINTHOR     = NAOATUALIZADOS.QTWINTHOR,
           QTDISPWINTHOR = NAOATUALIZADOS.QTDISPWINTHOR
     WHERE NUMINVENT = vNUMINVENT
       AND CODPROD = NAOATUALIZADOS.CODPROD;
  
  END LOOP;
END;
