CREATE OR REPLACE PACKAGE FERRAMENTAS_FATURAMENTO IS

  TYPE T_ATUALIZAR_TOTAIS_VENDA IS RECORD(  
    codigoProduto           pcest.codprod%type,
    codigoFilial            pcest.codfilial%type,  
    quantidadeVendaDia      pcest.qtvenddia%type,
    quantidadeVendaSemana   pcest.qtvendsemana%type,
    quantidadeVendaMes      pcest.qtvendmes%type,
    valorVendaDia           pcest.vlvenddia%type,
    valorVendaMes           pcest.vlvendmes%type,
    valorVendaRealDia       pcest.vlvenddiareal%type,
    valorVendaRealMes       pcest.vlvendmesreal%type,
    valorCustoRealDia       pcest.vlcustodiareal%type,
    valorCustoRealMes       pcest.vlcustomesreal%type,
    valorCustoFinanceiroDia pcest.vlcustodiafin%type,
    valorCustoFinanceiroMes pcest.vlcustomesfin%type,
    dataUltimoFaturamento   pcest.dtultfat%type
    );
  
  TYPE T_PRODUTO_MOVIMENTACAO IS RECORD(  
    numeroTransacaoItem pcmov.numtransitem%type,
    numeroTransacao pcmov.numtransvenda%type,
    codigoProduto pcmov.codprod%type,
    codigoFilial pcmov.codfilial%type,
    quantidade pcmov.qt%type,
    quantidadeContabil pcmov.qtcont%type,
    custoContabil pcmov.custocont%type,
    custoReal pcmov.custoreal%type,
    custoReposicao pcmov.custorep%type,
    custoFinanceiro pcmov.custofin%type,
    valorUltimaEntrada pcmov.valorultent%type,
    precoUnitario pcmov.punit%type,
    numeroNota pcmov.numnota%type,
    valorVenda pcmov.punitcont%type,
    quantidadeVenda pcmov.qtcont%type,
    valorFrete pcmov.vlfrete%type,
    valorOutrasDespesas pcmov.vloutrasdesp%type,
    valorFreteRateio pcmov.vlfrete_rateio%type,
    valorOutros pcmov.vloutros%type,
    valorRepasse pcmov.vlrepasse%type
    ); 

  /*****************************************************************************************/
  
  PROCEDURE atualizarTotaisVenda(pParametros IN T_ATUALIZAR_TOTAIS_VENDA);
  
  PROCEDURE buscarEatualizarTotaisVenda(pNumtransvenda in pcnfsaid.numtransvenda%type);

END FERRAMENTAS_FATURAMENTO;