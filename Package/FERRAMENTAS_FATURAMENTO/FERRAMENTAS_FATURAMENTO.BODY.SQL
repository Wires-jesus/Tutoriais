CREATE OR REPLACE PACKAGE BODY FERRAMENTAS_FATURAMENTO IS

  PROCEDURE atualizarTotaisVenda(pParametros      IN T_ATUALIZAR_TOTAIS_VENDA,
                                pMensagemRetorno OUT VARCHAR2) IS
  BEGIN
    --Este método já recebe todos os campos e valores calculados, apenas atualiza no banco de dados
    pMensagemRetorno := 'OK';
    BEGIN
      UPDATE pcest
         SET qtvenddia      = qtvenddia + nvl(pParametros.QuantidadeVendaDia, 0),
             qtvendsemana   = qtvendsemana + nvl(pParametros.QuantidadeVendaSemana, 0),
             qtvendmes      = qtvendmes + nvl(pParametros.QuantidadeVendaMes, 0),
             vlvenddia      = vlvenddia + nvl(pParametros.ValorVendaDia, 0),
             vlvendmes      = vlvendmes + nvl(pParametros.ValorVendaMes, 0),
             vlvenddiareal  = vlvenddiareal + nvl(pParametros.ValorVendaRealDia, 0),
             vlvendmesreal  = vlvendmesreal + nvl(pParametros.ValorVendaRealMes, 0),
             vlcustodiareal = vlcustodiareal + nvl(pParametros.ValorCustoRealDia, 0),
             vlcustomesreal = vlcustomesreal + nvl(pParametros.ValorCustoRealMes, 0),
             vlcustodiafin  = vlcustodiafin + nvl(pParametros.ValorCustoFinanceiroDia, 0),
             vlcustomesfin  = vlcustomesfin + nvl(pParametros.ValorCustoFinanceiroMes, 0),
             dtultfat       = sysdate
       where codprod = pParametros.codigoProduto
         AND codfilial = pParametros.CodigoFilial;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        pMensagemRetorno := 'Erro ao atualizar totais de venda na tabela PCEST. Dados não encontrados para o produto ' ||
                            pParametros.codigoProduto || ' e filial ' ||
                            pParametros.CodigoFilial;
        RAISE;
      WHEN OTHERS THEN
        pMensagemRetorno := 'Erro ao atualizar totais de venda na tabela PCEST (Produto: ' ||
                            pParametros.codigoProduto || ', filial: ' ||
                            pParametros.CodigoFilial || '). Erro orignal: ' ||
                            SQLERRM;
        RAISE;
    END;
  END;

  FUNCTION buscarEatualizarTotaisVenda(pNumtransvenda   in pcnfsaid.numtransvenda%type,
                                       pMensagemRetorno OUT VARCHAR2)
    RETURN VARCHAR2 IS
    vAtualizarTotaisVenda T_ATUALIZAR_TOTAIS_VENDA;
  BEGIN
    --Este mpetodo já recebe apenas o código do produto e filial, e faz a busca e cálculo dos valores
    --para atualizar no banco de dados
    pMensagemRetorno := 'OK';
    IF ((pNumtransvenda IS NULL) OR (pNumtransvenda = 0)) THEN
      pMensagemRetorno := 'Parâmetro pNumtransvenda não foi informado!';
      RETURN 'N';
    END IF;
   
    BEGIN
      for movimentacao in (select pcmov.codprod,
                                  pcmov.codfilial,
                                  pcmov.numnota,
                                  pcmov.custoreal,
                                  pcmov.custofin,
                                  nvl(pcmov.qtcont, 0) qtcont,
                                  (DECODE(NVL(pcmov.tipoitem, 'C'),
                                          'C',
                                          DECODE(pcmov.codoper,
                                                 'S',
                                                 DECODE(NVL(pcmov.tipoitem,
                                                            'C'),
                                                        'C',
                                                        (NVL(DECODE(pcnfsaid.condvenda,
                                                                    7,
                                                                    pcmov.qtcont,
                                                                    pcmov.qt),
                                                             0)),
                                                        pcmov.qtcont),
                                                 'ST',
                                                 (NVL(DECODE(pcnfsaid.condvenda,
                                                             7,
                                                             pcmov.qtcont,
                                                             pcmov.qt),
                                                      0)),
                                                 'SM',
                                                 (NVL(DECODE(pcnfsaid.condvenda,
                                                             7,
                                                             pcmov.qtcont,
                                                             pcmov.qt),
                                                      0)),
                                                 0),
                                          pcmov.qtcont)) qtvenda,
                                  ROUND((((DECODE(pcmov.codoper,
                                                  'S',
                                                  (NVL(DECODE(pcnfsaid.condvenda,
                                                              7,
                                                              pcmov.qtcont,
                                                              pcmov.qt),
                                                       0)),
                                                  'ST',
                                                  (NVL(DECODE(pcnfsaid.condvenda,
                                                              7,
                                                              pcmov.qtcont,
                                                              pcmov.qt),
                                                       0)),
                                                  'SM',
                                                  (NVL(DECODE(pcnfsaid.condvenda,
                                                              7,
                                                              pcmov.qtcont,
                                                              pcmov.qt),
                                                       0)),
                                                  0)) *
                                        (NVL(DECODE(pcnfsaid.condvenda,
                                                      7,
                                                      pcmov.punitcont,
                                                      NVL(pcmov.punit, 0) +
                                                      NVL(pcmov.vlfrete, 0) +
                                                      NVL(pcmov.vloutrasdesp,
                                                          0) +
                                                      NVL(pcmov.vlfrete_rateio,
                                                          0) +
                                                      NVL(pcmov.vloutros, 0) -
                                                      NVL(pcmov.vlrepasse, 0)),
                                               0)))),
                                        2) vlvenda
                             from pcmov, pcnfsaid, pcmovcomple
                            where pcmov.numtransvenda = pNumtransvenda
                              and pcmov.numtransvenda = pcnfsaid.numtransvenda
                              and pcmov.dtmov = pcnfsaid.dtsaida
                              and pcmovcomple.numtransitem(+) = pcmov.numtransitem
                              and pcnfsaid.numped > 0) LOOP

        BEGIN
          select pcest.codprod,
                 pcest.codfilial
            into vAtualizarTotaisVenda.codigoProduto,
                 vAtualizarTotaisVenda.codigoFilial
            from pcest
           where pcest.codprod = movimentacao.codprod
             and pcest.codfilial = movimentacao.codfilial;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            pMensagemRetorno := 'Dados não encontrados na tabela PCEST para o produto ' ||
                                movimentacao.codprod || ' e filial ' ||
                                movimentacao.codfilial;
            RETURN 'N';
          WHEN OTHERS THEN
            pMensagemRetorno := 'Erro ao buscar dados dos totais de venda na tabela PCEST (Produto: ' ||
                                movimentacao.codprod || ', filial: ' ||
                                movimentacao.codfilial ||
                                '). Erro orignal: ' || SQLERRM;
            RETURN 'N';
        END;

        vAtualizarTotaisVenda.QuantidadeVendaDia      := GREATEST(movimentacao.qtvenda, movimentacao.qtcont);
        vAtualizarTotaisVenda.QuantidadeVendaSemana   := GREATEST(movimentacao.qtvenda, movimentacao.qtcont);
        vAtualizarTotaisVenda.QuantidadeVendaMes      := GREATEST(movimentacao.qtvenda, movimentacao.qtcont);
        vAtualizarTotaisVenda.ValorVendaDia           := movimentacao.vlvenda;
        vAtualizarTotaisVenda.ValorVendaMes           := movimentacao.vlvenda;
        vAtualizarTotaisVenda.ValorVendaRealDia       := movimentacao.vlvenda;
        vAtualizarTotaisVenda.ValorVendaRealMes       := movimentacao.vlvenda;
        vAtualizarTotaisVenda.ValorCustoRealDia       := (movimentacao.qtvenda * movimentacao.custoreal);
        vAtualizarTotaisVenda.ValorCustoRealMes       := (movimentacao.qtvenda * movimentacao.custoreal);
        vAtualizarTotaisVenda.ValorCustoFinanceiroDia := (movimentacao.qtvenda * movimentacao.custofin);
        vAtualizarTotaisVenda.ValorCustoFinanceiroMes := (movimentacao.qtvenda * movimentacao.custofin);
        atualizarTotaisVenda(vAtualizarTotaisVenda, pMensagemRetorno);
      END LOOP;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        pMensagemRetorno := 'Dados não encontrados na movimentação da nota com transação ' ||
                            pNumtransvenda;
        RETURN 'N';
      WHEN OTHERS THEN
        pMensagemRetorno := 'Erro buscar dados da movimentação da nota com transação ' ||
                            pNumtransvenda || '. Erro orignal: ' || SQLERRM;
        RETURN 'N';
    END;
    
    RETURN 'S';
  END;
  
  FUNCTION SINC_INFOXML_SAIDA_ENTRADA(pNumtransvenda IN pcnfsaid.numtransvenda%type, pMensagemRetorno OUT VARCHAR2) 
    RETURN VARCHAR2 IS
    PINFOXML T_INFOXML;
    vRetono VARCHAR2(1) := 'S';
  BEGIN
     pMensagemRetorno := 'OK';
     BEGIN
     FOR REG IN (SELECT NF.*
                   FROM (SELECT PCNFENT.NUMTRANSENT
                              , PCNFSAID.CHAVENFE
                              , PCNFSAID.NUMNOTA
                              , PCNFSAID.ESPECIE
                              , PCNFSAID.SERIE
                              , TO_CHAR(PCNFSAID.OBSNFE) OBSNFE
                              , PCNFSAID.NUMTRANSVENDA
                           FROM PCNFENT
                              , PCNFSAID
                          WHERE TRIM(PCNFSAID.CHAVENFE) IS NOT NULL
                            AND PCNFSAID.NUMTRANSENTORIGEM > 0
                            AND PCNFENT.NUMTRANSENT = PCNFSAID.NUMTRANSENTORIGEM
                            AND PCNFSAID.NUMTRANSVENDA = pNumtransvenda
                         UNION
                         SELECT PCNFENT.NUMTRANSENT
                              , PCNFSAID.CHAVENFE
                              , PCNFSAID.NUMNOTA
                              , PCNFSAID.ESPECIE
                              , PCNFSAID.SERIE
                              , TO_CHAR(PCNFSAID.OBSNFE) OBSNFE
                              , PCNFSAID.NUMTRANSVENDA
                           FROM PCNFENT
                              , PCNFSAIDPREFAT PCNFSAID
                          WHERE TRIM(PCNFSAID.CHAVENFE) IS NOT NULL
                            AND PCNFSAID.NUMTRANSENTORIGEM > 0
                            AND PCNFENT.NUMTRANSENT = PCNFSAID.NUMTRANSENTORIGEM
                            AND PCNFSAID.NUMTRANSVENDA = pNumtransvenda) NF
                  WHERE ROWNUM = 1)
     LOOP
        UPDATE PCNFENT
           SET CHAVENFE = REG.CHAVENFE
             , ESPECIE = REG.ESPECIE
             , SERIE = REG.SERIE
             , MODELO = DECODE(NVL(REG.CHAVENFE, '0'), '0', '01', '55')
             , NUMNOTA = REG.NUMNOTA
             , OBSNFE = REG.OBSNFE
         WHERE NUMTRANSENT = REG.NUMTRANSENT;

        FOR ORIGEM IN (SELECT NFI.*
                         FROM (SELECT PCMOV.CODPROD
                                    , PCMOV.NUMSEQ
                                    , PCMOV.NUMTRANSITEM
                                    , PCMOVCOMPLE.DESCRICAONFE
                                    , PCMOVCOMPLE.NITEMXML
                                    , PCMOVCOMPLE.UNIDADECOMERCIAL
                                    , PCMOVCOMPLE.XML_QCOM
                                    , PCMOVCOMPLE.XML_QTRIB
                                 FROM PCMOVCOMPLE
                                    , PCMOV
                                WHERE PCMOVCOMPLE.NUMTRANSITEM = PCMOV.NUMTRANSITEM
                                  AND PCMOV.NUMTRANSVENDA = REG.NUMTRANSVENDA
                               UNION
                               SELECT PCMOV.CODPROD
                                    , PCMOV.NUMSEQ
                                    , PCMOV.NUMTRANSITEM
                                    , PCMOVCOMPLE.DESCRICAONFE
                                    , PCMOVCOMPLE.NITEMXML
                                    , PCMOVCOMPLE.UNIDADECOMERCIAL
                                    , PCMOVCOMPLE.XML_QCOM
                                    , PCMOVCOMPLE.XML_QTRIB
                                 FROM PCMOVCOMPLEPREFAT PCMOVCOMPLE
                                    , PCMOVPREFAT PCMOV
                                WHERE PCMOVCOMPLE.NUMTRANSITEM = PCMOV.NUMTRANSITEM
                                  AND PCMOV.NUMTRANSVENDA = REG.NUMTRANSVENDA) NFI)
        LOOP
           PINFOXML.DESCRICAONFE := ORIGEM.DESCRICAONFE;
           PINFOXML.NITEMXML := ORIGEM.NITEMXML;
           PINFOXML.NUMSEQENT := ORIGEM.NITEMXML;
           PINFOXML.UNIDADECOMERCIAL := ORIGEM.UNIDADECOMERCIAL;
           PINFOXML.XML_QCOM := ORIGEM.XML_QCOM;
           PINFOXML.XML_QTRIB := ORIGEM.XML_QTRIB;
           
           BEGIN
             SELECT NUMTRANSITEM
               INTO PINFOXML.NUMTRANSITEM
               FROM PCMOV
              WHERE NUMTRANSENT = REG.NUMTRANSENT
                AND CODPROD = ORIGEM.CODPROD
                AND NUMSEQ = ORIGEM.NUMSEQ;
                
             IF (GRAVAR_INFOXML(PINFOXML, pMensagemRetorno) = 'N') THEN
               pMensagemRetorno := pMensagemRetorno ||' Transação de entrada: '|| REG.NUMTRANSENT 
                 ||' Produto: '|| ORIGEM.CODPROD ||' Sequencia: '||ORIGEM.NUMSEQ;
               vRetono := 'N';
             END IF;            
             
             FOR DADOSXML IN (SELECT PCDADOSXML.*
                                FROM PCDADOSXML
                               WHERE PCDADOSXML.NUMTRANSITEM = ORIGEM.NUMTRANSITEM)
             LOOP
                DADOSXML.NUMTRANSITEM := PINFOXML.NUMTRANSITEM;
                IF (GRAVAR_DADOSXML(DADOSXML, pMensagemRetorno) = 'N') THEN
                   pMensagemRetorno := pMensagemRetorno ||' Transação de entrada: '|| REG.NUMTRANSENT 
                     ||' Produto: '|| ORIGEM.CODPROD ||' Sequencia: '|| ORIGEM.NUMSEQ ||' TransItem: '|| PINFOXML.NUMTRANSITEM;
                   vRetono := 'N';
                END IF;               
             END LOOP;
           EXCEPTION
              WHEN NO_DATA_FOUND THEN
                pMensagemRetorno := 'Não encontramos vinculo no destino para transação de entrada: '
                  || REG.NUMTRANSENT ||' Produto: '|| ORIGEM.CODPROD ||' Sequencia: '||ORIGEM.NUMSEQ;
                vRetono := 'N';
           END;
        END LOOP;
     END LOOP;    
     EXCEPTION
        WHEN OTHERS THEN
          pMensagemRetorno := 'Erro buscar dados da movimentação da nota com transação ' ||
                              pNumtransvenda || '. Erro orignal: ' || SQLERRM;
         vRetono := 'N';
     END;
    
     RETURN vRetono;
  END;
  
  FUNCTION GRAVAR_INFOXML(PINFOXML IN T_INFOXML, pMensagemRetorno OUT VARCHAR2)
    RETURN VARCHAR2 IS
  BEGIN
    pMensagemRetorno := 'OK';
    BEGIN
       UPDATE PCMOVCOMPLE
          SET DESCRICAONFE = PINFOXML.DESCRICAONFE
            , NITEMXML = PINFOXML.NITEMXML
            , NUMSEQENT = PINFOXML.NITEMXML
            , UNIDADECOMERCIAL = PINFOXML.UNIDADECOMERCIAL
            , XML_QCOM = PINFOXML.XML_QCOM
            , XML_QTRIB = PINFOXML.XML_QTRIB
        WHERE NUMTRANSITEM = PINFOXML.NUMTRANSITEM;
       
       IF (SQL%ROWCOUNT = 0) THEN
         UPDATE PCMOVCOMPLEPREFAT
            SET DESCRICAONFE = PINFOXML.DESCRICAONFE
              , NITEMXML = PINFOXML.NITEMXML
              , NUMSEQENT = PINFOXML.NITEMXML
              , UNIDADECOMERCIAL = PINFOXML.UNIDADECOMERCIAL
              , XML_QCOM = PINFOXML.XML_QCOM
              , XML_QTRIB = PINFOXML.XML_QTRIB
          WHERE NUMTRANSITEM = PINFOXML.NUMTRANSITEM;         
       END IF;   
    EXCEPTION
       WHEN OTHERS THEN
         pMensagemRetorno := 'Erro ao gravar dados do xml na movimentação. ' ||
                             PINFOXML.NUMTRANSITEM || '. Erro orignal: ' || SQLERRM;
        RETURN 'N';
    END;
    
    RETURN 'S';    
  END;
  
  FUNCTION GRAVAR_DADOSXML(PDADOSXML IN PCDADOSXML%ROWTYPE, pMensagemRetorno OUT VARCHAR2)
    RETURN VARCHAR2 IS
  BEGIN
    pMensagemRetorno := 'OK';
    BEGIN
      UPDATE PCDADOSXML
         SET ROW = PDADOSXML
       WHERE NUMTRANSITEM = PDADOSXML.NUMTRANSITEM;

      IF (SQL%ROWCOUNT = 0) THEN
         INSERT INTO PCDADOSXML
              VALUES PDADOSXML;
      END IF;  
    EXCEPTION
       WHEN OTHERS THEN
         pMensagemRetorno := 'Erro ao gravar dados do xml na PCDADOSXML. ' ||
                             PDADOSXML.NUMTRANSITEM || '. Erro orignal: ' || SQLERRM;
        RETURN 'N';
    END;
    
    RETURN 'S';
  END;  

END FERRAMENTAS_FATURAMENTO;
