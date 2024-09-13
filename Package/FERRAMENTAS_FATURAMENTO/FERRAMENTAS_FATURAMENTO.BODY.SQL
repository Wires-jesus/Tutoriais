CREATE OR REPLACE PACKAGE BODY FERRAMENTAS_FATURAMENTO IS

  PROCEDURE atualizarTotaisVenda(pParametros IN T_ATUALIZAR_TOTAIS_VENDA) IS
  BEGIN
    --Este método já recebe todos os campos e valores calculados, apenas atualiza no banco de dados      
    UPDATE pcest
       SET qtvenddia = qtvenddia + nvl(pParametros.QuantidadeVendaDia, 0),
           qtvendsemana = qtvendsemana + nvl(pParametros.QuantidadeVendaSemana, 0),
           qtvendmes = qtvendmes + nvl(pParametros.QuantidadeVendaMes, 0),
           vlvenddia = vlvenddia + nvl(pParametros.ValorVendaDia, 0),
           vlvendmes = vlvendmes + nvl(pParametros.ValorVendaMes, 0),           
           vlvenddiareal = vlvenddiareal + nvl(pParametros.ValorVendaRealDia, 0),
           vlvendmesreal = vlvendmesreal + nvl(pParametros.ValorVendaRealMes, 0),
           vlcustodiareal = vlcustodiareal + nvl(pParametros.ValorCustoRealDia, 0),
           vlcustomesreal = vlcustomesreal + nvl(pParametros.ValorCustoRealMes, 0),
           vlcustodiafin = vlcustodiafin + nvl(pParametros.ValorCustoFinanceiroDia, 0),
           vlcustomesfin = vlcustomesfin + nvl(pParametros.ValorCustoFinanceiroMes, 0),
           dtultfat = sysdate
     where codprod = pParametros.codigoProduto
       AND codfilial = pParametros.CodigoFilial;           
  END;
  
  PROCEDURE buscarEatualizarTotaisVenda(pNumtransvenda in pcnfsaid.numtransvenda%type) IS
    vProdutoMovimentacao T_PRODUTO_MOVIMENTACAO;
    vAtualizarTotaisVenda T_ATUALIZAR_TOTAIS_VENDA;
  BEGIN
    --Este mpetodo já recebe apenas o código do produto e filial, e faz a busca e cálculo dos valores
    --para atualizar no banco de dados  
    
    select pcmov.numtransvenda
          ,pcmov.numtransitem
          ,pcmov.codprod
          ,pcmov.codfilial
          ,pcmov.numnota
          ,pcmov.custocont
          ,pcmov.custoreal
          ,pcmov.custorep
          ,pcmov.custofin
          ,coalesce(pcmov.punit, 0) punit
          ,coalesce(pcmov.qt, 0) qt
          ,coalesce(pcmov.qtcont, 0) qtcont
          ,(DECODE(NVL(pcmov.tipoitem, 'C'),
                      'C',
                      DECODE(pcmov.codoper,
                             'S',
                             DECODE(NVL(pcmov.tipoitem, 'C'),
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
                      pcmov.qtcont)) qtvenda
          ,ROUND((((DECODE(pcmov.codoper,
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
                                  NVL(pcmov.punit, 0) + NVL(pcmov.vlfrete, 0) +
                                  NVL(pcmov.vloutrasdesp, 0) +
                                  NVL(pcmov.vlfrete_rateio, 0) +
                                  NVL(pcmov.vloutros, 0) -
                                  NVL(pcmov.vlrepasse, 0)),
                           0)))),
                    2) vlvenda
          ,NVL(pcmov.vlfrete, 0) vlfrete
          ,NVL(pcmov.vloutrasdesp, 0) vloutrasdesp
          ,NVL(pcmov.vlfrete_rateio, 0) vlfrete_rateio
          ,NVL(pcmov.vloutros, 0) vloutros
          ,NVL(pcmov.vlrepasse, 0) vlrepasse
     into vProdutoMovimentacao.numeroTransacao,
          vProdutoMovimentacao.numeroTransacaoItem,
          vProdutoMovimentacao.codigoProduto,
          vProdutoMovimentacao.codigoFilial,
          vProdutoMovimentacao.numeroNota,
          vProdutoMovimentacao.custoContabil,
          vProdutoMovimentacao.custoReal,
          vProdutoMovimentacao.custoReposicao,
          vProdutoMovimentacao.custoFinanceiro,                   
          vProdutoMovimentacao.precoUnitario,
          vProdutoMovimentacao.quantidade,          
          vProdutoMovimentacao.quantidadeContabil,
          vProdutoMovimentacao.quantidadeVenda,
          vProdutoMovimentacao.valorVenda,
          vProdutoMovimentacao.valorFrete, 
          vProdutoMovimentacao.valorOutrasDespesas,
          vProdutoMovimentacao.valorFreteRateio,
          vProdutoMovimentacao.valorOutros,
          vProdutoMovimentacao.valorRepasse 
      from pcmov
         , pcnfsaid
         , pcmovcomple
     where pcmov.numtransvenda = pNumtransvenda
       and pcmov.numtransvenda = pcnfsaid.numtransvenda
       and pcmov.dtmov = pcnfsaid.dtsaida
       and pcmovcomple.numtransitem(+) = pcmov.numtransitem;      
     
    select coalesce(pcest.qtvenddia, 0) qtvenddia,
           coalesce(pcest.qtvendsemana, 0) qtvendsemana,
           coalesce(pcest.qtvendmes, 0) qtvendmes,
           coalesce(pcest.vlvenddia, 0) vlvenddia,
           coalesce(pcest.vlvendmes, 0) vlvendmes,
           coalesce(pcest.vlvenddiareal, 0) vlvenddiareal,
           coalesce(pcest.vlvendmesreal, 0) vlvendmesreal,
           coalesce(pcest.vlcustodiareal, 0) vlcustodiareal,
           coalesce(pcest.vlcustomesreal, 0) vlcustomesreal,
           coalesce(pcest.vlcustodiafin, 0) vlcustodiafin,
           coalesce(pcest.vlcustomesfin, 0) vlcustomesfin
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
     where pcest.codprod = vProdutoMovimentacao.codigoProduto
       and pcest.codfilial = vProdutoMovimentacao.codigoFilial; 
     
     vAtualizarTotaisVenda.QuantidadeVendaDia := GREATEST(vProdutoMovimentacao.QuantidadeVenda, vProdutoMovimentacao.QuantidadeContabil);
     vAtualizarTotaisVenda.QuantidadeVendaSemana := GREATEST(vProdutoMovimentacao.QuantidadeVenda, vProdutoMovimentacao.QuantidadeContabil);
     vAtualizarTotaisVenda.QuantidadeVendaMes := GREATEST(vProdutoMovimentacao.QuantidadeVenda, vProdutoMovimentacao.QuantidadeContabil);
     vAtualizarTotaisVenda.ValorVendaDia := vProdutoMovimentacao.ValorVenda;
     vAtualizarTotaisVenda.ValorVendaMes := vProdutoMovimentacao.ValorVenda;
     vAtualizarTotaisVenda.ValorVendaRealDia := vProdutoMovimentacao.ValorVenda;
     vAtualizarTotaisVenda.ValorVendaRealMes := vProdutoMovimentacao.ValorVenda;
     vAtualizarTotaisVenda.ValorCustoRealDia := (vProdutoMovimentacao.QuantidadeVenda * vProdutoMovimentacao.CustoReal);
     vAtualizarTotaisVenda.ValorCustoRealMes := (vProdutoMovimentacao.QuantidadeVenda * vProdutoMovimentacao.CustoReal);
     vAtualizarTotaisVenda.ValorCustoFinanceiroDia := (vProdutoMovimentacao.QuantidadeVenda * vProdutoMovimentacao.CustoFinanceiro);
     vAtualizarTotaisVenda.ValorCustoFinanceiroMes := (vProdutoMovimentacao.QuantidadeVenda * vProdutoMovimentacao.CustoFinanceiro);
     atualizarTotaisVenda(vAtualizarTotaisVenda);  
  end;

END FERRAMENTAS_FATURAMENTO;