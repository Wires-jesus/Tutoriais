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
  
  /*****************************************************************************************/
  
  FUNCTION atualizarTotaisVenda(pParametros IN T_ATUALIZAR_TOTAIS_VENDA, pMensagemRetorno OUT VARCHAR2) RETURN VARCHAR2;
  
  FUNCTION buscarEatualizarTotaisVenda(pNumtransvenda in pcnfsaid.numtransvenda%type, pMensagemRetorno OUT VARCHAR2) RETURN VARCHAR2;

END FERRAMENTAS_FATURAMENTO;