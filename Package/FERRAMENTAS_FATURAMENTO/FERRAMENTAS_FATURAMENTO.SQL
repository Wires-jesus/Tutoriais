CREATE OR REPLACE PACKAGE FERRAMENTAS_FATURAMENTO IS

  vrPARAMETROS PCPARAMFAT%ROWTYPE;
  
  TYPE T_ATUALIZAR_TOTAIS_VENDA IS RECORD(  
    codigoProduto           pcest.codprod%type,
    codigoFilial            pcest.codfilial%type,
    numregiao               pcmov.numregiao%type,  
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
    
  FUNCTION TRANSF_CARREGAMENTO(PNUMCARORIGEM IN PCCARREG.NUMCAR%TYPE,
                               PNUMCARDESTINO IN PCCARREG.NUMCAR%TYPE,
                               PMSGRETORNO OUT VARCHAR2,
                               PCODFUNCTRANSF IN PCLOGTRANSFNFCARREG.CODFUNCTRANSF%TYPE DEFAULT NULL,
                               PCODMOTIVO IN PCLOGTRANSFNFCARREG.CODMOTIVO%TYPE DEFAULT NULL,
                               PMOTIVOTRANSF IN PCLOGTRANSFNFCARREG.MOTIVOTRANSF%TYPE DEFAULT '',
                               PNUMPED IN PCNFSAID.NUMPED%TYPE DEFAULT 0,
                               PNUMTRANSVENDA IN PCNFSAID.NUMTRANSVENDA%TYPE DEFAULT 0) RETURN VARCHAR2;

  FUNCTION buscarEatualizarTotaisVenda(pNumtransvenda in pcnfsaid.numtransvenda%type, pMensagemRetorno OUT VARCHAR2) RETURN VARCHAR2;
  
  FUNCTION SINC_INFOXML_SAIDA_ENTRADA(pNumtransvenda IN pcnfsaid.numtransvenda%type, pMensagemRetorno OUT VARCHAR2) RETURN VARCHAR2;

  FUNCTION GRAVAR_INFOXML(PINFOXML IN FERRAMENTAS_DOCFISCAL.T_INFOXML, PMENSAGEMRETORNO OUT VARCHAR2) RETURN VARCHAR2;
					  
  PROCEDURE CALCULAR_VITEM(PNUMTRANSVENDA in PCMOV.NUMTRANSVENDA%TYPE);

  FUNCTION GRAVAR_DADOSXML(PDADOSXML IN PCDADOSXML%ROWTYPE, PMENSAGEMRETORNO OUT VARCHAR2) RETURN VARCHAR2;

  PROCEDURE GRAVARLOG(PPARAMS IN OUT PCPARAMFAT%ROWTYPE, PSLINHAMSG IN VARCHAR2 DEFAULT '');

END FERRAMENTAS_FATURAMENTO;