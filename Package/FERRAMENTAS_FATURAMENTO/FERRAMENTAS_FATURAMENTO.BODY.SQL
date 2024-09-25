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
          select nvl(pcest.qtvenddia, 0) qtvenddia,
                 nvl(pcest.qtvendsemana, 0) qtvendsemana,
                 nvl(pcest.qtvendmes, 0) qtvendmes,
                 nvl(pcest.vlvenddia, 0) vlvenddia,
                 nvl(pcest.vlvendmes, 0) vlvendmes,
                 nvl(pcest.vlvenddiareal, 0) vlvenddiareal,
                 nvl(pcest.vlvendmesreal, 0) vlvendmesreal,
                 nvl(pcest.vlcustodiareal, 0) vlcustodiareal,
                 nvl(pcest.vlcustomesreal, 0) vlcustomesreal,
                 nvl(pcest.vlcustodiafin, 0) vlcustodiafin,
                 nvl(pcest.vlcustomesfin, 0) vlcustomesfin
            into vAtualizarTotaisVenda.QuantidadeVendaDia,
                 vAtualizarTotaisVenda.QuantidadeVendaSemana,
                 vAtualizarTotaisVenda.QuantidadeVendaMes,
                 vAtualizarTotaisVenda.ValorVendaDia,
                 vAtualizarTotaisVenda.ValorVendaMes,
                 vAtualizarTotaisVenda.ValorVendaRealDia,
                 vAtualizarTotaisVenda.ValorVendaRealMes,
                 vAtualizarTotaisVenda.ValorCustoRealDia,
                 vAtualizarTotaisVenda.ValorCustoRealMes,
                 vAtualizarTotaisVenda.ValorCustoFinanceiroDia,
                 vAtualizarTotaisVenda.ValorCustoFinanceiroMes
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

        vAtualizarTotaisVenda.codigoProduto           := movimentacao.codprod;
        vAtualizarTotaisVenda.codigoFilial            := movimentacao.codfilial;
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

END FERRAMENTAS_FATURAMENTO;
