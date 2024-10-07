CREATE OR REPLACE PACKAGE FERRAMENTAS_FATURAMENTO IS

  R_DADOSXML PCDADOSXML%ROWTYPE;

  TYPE T_INFOXML IS RECORD(
       DESCRICAONFE PCMOVCOMPLE.DESCRICAONFE%TYPE,
       NITEMXML PCMOVCOMPLE.NITEMXML%TYPE,
       NUMSEQENT PCMOVCOMPLE.NUMSEQENT%TYPE,
       UNIDADECOMERCIAL PCMOVCOMPLE.UNIDADECOMERCIAL%TYPE,
       XML_QCOM PCMOVCOMPLE.XML_QCOM%TYPE,
       XML_QTRIB PCMOVCOMPLE.XML_QTRIB%TYPE,
       NUMTRANSITEM PCMOVCOMPLE.NUMTRANSITEM%TYPE
  );
  
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

  FUNCTION buscarEatualizarTotaisVenda(pNumtransvenda in pcnfsaid.numtransvenda%type, pMensagemRetorno OUT VARCHAR2) RETURN VARCHAR2;
  
  FUNCTION SINC_INFOXML_SAIDA_ENTRADA(pNumtransvenda IN pcnfsaid.numtransvenda%type, pMensagemRetorno OUT VARCHAR2) RETURN VARCHAR2;
  
  FUNCTION GRAVAR_INFOXML(PINFOXML IN T_INFOXML, pMensagemRetorno OUT VARCHAR2) RETURN VARCHAR2;
  
  FUNCTION GRAVAR_DADOSXML(PDADOSXML IN PCDADOSXML%ROWTYPE, pMensagemRetorno OUT VARCHAR2) RETURN VARCHAR2;

END FERRAMENTAS_FATURAMENTO;
