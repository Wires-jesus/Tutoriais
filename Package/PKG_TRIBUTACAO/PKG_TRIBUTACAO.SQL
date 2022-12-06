CREATE OR REPLACE PACKAGE PKG_TRIBUTACAO IS

  TYPE T_VENDA_AUTOSERVICO IS RECORD(

    BASEST            NUMBER(18, 6),
    ST  	          NUMBER(18, 6),
    VLIPI             NUMBER(18, 6),
    PVENDA            NUMBER(18, 6),
    PVENDASEMIMPOSTOS NUMBER(18,6),
    CALCULOUSTFONTE   VARCHAR2(1),
    BASEFECP          NUMBER(18, 6),
    ALIQFECP          NUMBER(18, 6),
    VLRFECP           NUMBER(18, 6),
    MENSAGEM          VARCHAR2(1000)
    );

  TYPE TB_VENDA_AUTOSERVICO IS TABLE OF T_VENDA_AUTOSERVICO;

  type T_PARAMETROS_132 IS RECORD(
    TratarRestricaoAcrescimo      PCCONSUM.TRATARRESTRICAOACRESCIMO%TYPE,
    NumCasasDecimais              PCCONSUM.NUMCASASDECVENDA%TYPE,
    UsaTributacaoPorUF            pcconsum.usatributacaoporuf%TYPE,
    TipoAliqoutrasdesp            pcconsum.tipoaliqoutrasdesp%TYPE,
    AliqIcmoutrasdesp             pcconsum.aliqicmoutrasdesp%TYPE,
    AliqIcminteroutrasdesp        pcconsum.Aliqicminteroutrasdesp%TYPE,
    CalcSTpf                      pcconsum.calcstpf%TYPE,
    ConsideraIsentoscomopf        pcconsum.consideraisentoscomopf%TYPE,
    IncluiFreteOutrasDespepBaseST pcfilial.incluifreteoutrasdespbasest%TYPE,
    --       Numcasasdecvenda
    --       AbaterImpostoscomissaorca
    TxVenda            pcconsum.txvenda%TYPE,
    Tipocalcst         pcconsum.tipocalcst%TYPE,
    PercicmFrete       pcconsum.percicmfrete%TYPE,
    PercIcminterfrete  pcconsum.percicminterfrete%TYPE,
    MostrarPvendasemst pcconsum.mostrarpvendasemst%TYPE,
    CalcularIPIVenda             VARCHAR2(5),
    CalcularSTComIPI             VARCHAR2(5),
    RetiraIpiPedidoTV8           VARCHAR2(5),
    AceitaPFContribuinte         VARCHAR2(5),
    UtilizaPercBaseredPF         VARCHAR2(5),
    UsaDescSimplesNac            VARCHAR2(5),
    UsarTributacaoTransfTV10     VARCHAR2(5),
    ValidarIpiPor                VARCHAR2(5),
    ConsideraPrecoSemDescCalcIpi VARCHAR2(2),
    PrecoPorEmbalagem            VARCHAR2(1),
    AgregStOutrasDesp            VARCHAR2(1),
    UtilizaTribEndEnt            VARCHAR2(1),
    UTILIZARTRIBUTEAJUSTEESTOQUE VARCHAR2(1),
    CALCULAIPICUPOMFISCAL        VARCHAR2(1),
    AGREGARFRETEBASEIPI          VARCHAR2(1),
    ConsVlUltEntContSSTPrecific  VARCHAR2(1),
    Utilizacontrolemedicamentos  VARCHAR2(1)
    );

  type T_PRECIFICACAO IS RECORD(
    PrecoTabela         PCTABPR.PTABELA%TYPE,
    PrecoTabelaAVista   PCTABPR.PTABELA%TYPE,
    VLIPI               PCTABPR.VLIPI%TYPE,
    VlUltEntMes         PCTABPR.VLULTENTMES%TYPE,
    PERCDESCSIMPLESNAC  PCTABPR.PERCDESCSIMPLESNAC%TYPE,
    CALCULARIPI         PCTABPR.CALCULARIPI%TYPE, -- HIS.00288.2016
    FormulaPrecific     PCTABPR.FORMULA%TYPE,
    CALCULARFECPSTVENDA PCTABPR.CALCULARFECPSTVENDA%TYPE,
    VLFCPST				      PCTABPR.VLFCPST%TYPE,
    VLULTENTCONTSEMST   PCTABPR.VLULTENTCONTSEMST%TYPE);

  type T_REGIAO IS RECORD(
    NumRegiao PCREGIAO.NUMREGIAO%TYPE,
    Regiao    PCREGIAO.REGIAO%TYPE);

  type T_PRACA IS RECORD(
    CodPraca PCPRACA.CODPRACA%TYPE,
    Praca    PCPRACA.PRACA%TYPE,
    Regiao   T_REGIAO);

  TYPE T_CNAE IS RECORD(
    CODCNAE           PCCNAE.CODCNAE%TYPE,
    MARGEMMVA         PCCNAE.MARGEMMVA%TYPE,
    PERCARGATRIBMEDIA PCCNAE.PERCARGATRIBMEDIA%TYPE);

  type T_PRODUTO_FILIAL IS RECORD(
    CalculaIpi PCPRODFILIAL.CALCULAIPI%TYPE,
    Relevante  PCPRODFILIAL.INDESCALARELEVANTE%TYPE,
    PerAcresBaseIPI PCPRODFILIAL.PERACRESBASEIPI%TYPE --HIS.02641.2017
    );

  type T_PRODUTO IS RECORD(
    CodProd                   PCPRODUT.CODPROD%TYPE,
    Descricao                 PCPRODUT.DESCRICAO%TYPE,
    CodProdPrinc              PCPRODUT.CODPRODPRINC%TYPE,
    CodCategoria              PCPRODUT.CODCATEGORIA%TYPE,
    CodSubCategoria           PCPRODUT.CODSUBCATEGORIA%TYPE,
    CodFornec                 PCPRODUT.CODFORNEC%TYPE,
    CodMarca                  PCPRODUT.CODMARCA%TYPE,
    FreteEspecial             PCPRODUT.Freteespecial%TYPE,
    Percipi                   PCPRODUT.Percipi%TYPE,
    --PercDifAliquotas        PCPRODUT.Percdifaliquotas%TYPE,
    PrecoMaxConsum            PCPRODUT.PrecoMaxConsum%TYPE,
    Importado                 PCPRODUT.Importado%TYPE,
    VlPautaIpi                PCPRODUT.Vlpautaipi%TYPE,
    VlIpiPorKGVenda           PCPRODUT.Vlipiporkgvenda%TYPE,
    PesoBruto                 PCPRODUT.PESOBRUTO%TYPE,
    PrecoFixo                 PCPRODUT.PRECOFIXO%TYPE,
    AplicaPercRedAliqIpi      PCPRODUT.APLICAPERCREDALIQIPI%TYPE,
    VerificRamoAtiviCalcST    PCPRODUT.VERIFCRAMOATIVCALCST%TYPE,
  	TipoMercadoria			      PCPRODUT.TIPOMERC%TYPE,
    VlIpiPautaTV10            PCPRODUT.VLIPIPAUTATV10%TYPE,
    ProdutoFilial             T_PRODUTO_FILIAL,
    IsentoSTClienteCozinaInd  PCPRODUT.ISENTOSTCOZINHAINDUSTRIAL%TYPE);

  TYPE T_EMBALAGEM IS RECORD(
    CODAUXILIAR PCEMBALAGEM.CODAUXILIAR%TYPE,
    CODPROD     PCEMBALAGEM.CODPROD%TYPE,
    CODFILIAL   PCEMBALAGEM.CODFILIAL%TYPE,
    QTUNIT      PCEMBALAGEM.QTUNIT%TYPE

    );

  TYPE T_ESTOQUE IS RECORD(
    CodFilial                PCEST.codfilial%TYPE,
    CodProd                  PCEST.Codprod%TYPE,
    VALORULTENT              PCEST.VLULTPCOMPRA%TYPE,
    VLSTULTENT               PCEST.VLSTULTENT%TYPE,
    VLSTGUIAULTENT           PCEST.VLSTGUIAULTENT%TYPE,
    IVAULTENT                PCEST.IVAULTENT%TYPE,
    ALIQICMS1ULTENT          PCEST.ALIQICMS1ULTENT%TYPE,
    ALIQICMS2ULTENT          PCEST.ALIQICMS2ULTENT%TYPE,
    REDBASEIVAULTENT         PCEST.REDBASEIVAULTENT%TYPE,
    PERCICMSFRETEFOBSTULTENT PCEST.PERCICMSFRETEFOBSTULTENT%TYPE,
    VLFRETECONHECULTENT      PCEST.VLFRETECONHECULTENT%TYPE,
    PERCALIQEXTGUIAULTENT    PCEST.PERCALIQEXTGUIAULTENT%TYPE,
    BASEICMSULTENT           PCEST.BASEICMSULTENT%TYPE,
    CUSTONFSEMST             PCEST.CUSTONFSEMST%TYPE,
    CUSTONFSEMSTGUIAULTENT   PCEST.CUSTONFSEMSTGUIAULTENT%TYPE,
    PERCMVAORIGULTENT        PCEST.PERCMVAORIGULTENT%TYPE);

  type T_PLANO_PAGAMENTO IS RECORD(
    CodPlPag  PCPLPAG.CODPLPAG%TYPE,
    Descricao PCPLPAG.DESCRICAO%TYPE,
    NumPR     PCPLPAG.NUMPR%TYPE,
    NumDias   PCPLPAG.NUMDIAS%TYPE);

  TYPE T_TRIBUTACAO IS RECORD(
    Codicmtab                 pctribut.codicmtab%TYPE,
    CodST                     pctribut.codst%TYPE,
    IVA                       pctribut.Iva%TYPE,
    Aliqicms1                 pctribut.aliqicms1%TYPE,
    Aliqicms2                 pctribut.aliqicms2%TYPE,
    IVATransf                 pctribut.Ivatransf%TYPE,
    Aliqicms1Transf           pctribut.aliqicms1transf%TYPE,
    Aliqicms2Transf           pctribut.aliqicms2transf%TYPE,
    IVAFonte                  pctribut.Ivafonte%TYPE,
    Aliqicms1Fonte            pctribut.aliqicms1fonte%TYPE,
    Aliqicms2Fonte            pctribut.aliqicms2fonte%TYPE,
    Pauta                     pctribut.pauta%TYPE,
    PautaTransf               pctribut.pautaTransf%TYPE,
    CodIcmtabPF               pctribut.codicmtabpf%TYPE,
    PerDescCusto              pctribut.perdesccusto%TYPE,
    PercBaseRedSTTransf       pctribut.percbaseredst%TYPE,
    PercBaseRedSTFonte        pctribut.percbaseredstfonte%TYPE,
    PercBaseRedST             pctribut.percbaseredsttransf%TYPE,
    MostrarPvendaSemST        pctribut.mostrarpvendasemst%TYPE,
    UsaValorultEntbaseST      pctribut.usavalorultentbasest%TYPE,
    UsaValorultEntbaseST2     pctribut.usavalorultentbasest2%TYPE,
    UsaPMCBasest              pctribut.usapmcbasest%TYPE,
    TipoCalculoGnre           pctribut.tipocalculognre%TYPE,
    AgregarIpiCalculoST       pctribut.agregaripicalculost%TYPE,
    UsaVlultentMedioBasest    pctribut.usavlultentmediobasest%TYPE,
    PercBasestRJ              pctribut.percbasestrj%TYPE,
    UtilizaPercBaseredPF      pctribut.utilizapercbaseredpf%TYPE,
    PERCDIFALIQUOTAS          PCTRIBUT.PERCDIFALIQUOTAS%TYPE,
    PercRedPvendaSimplesnac   PCTRIBUT.Percredpvendasimplesnac%TYPE,
    IsentNumEmpenho           PCTRIBUT.ISENTNUMEMPENHO%TYPE,
    PercDescPIS               PCTRIBUT.PERCDESCPIS%TYPE,
    PercDescCOFINS            PCTRIBUT.PERCDESCCOFINS%TYPE,
    PerDescSUFRAMA            PCTRIBUT.PERDESCSUFRAMA%TYPE,
    PerDescICMIsencao         PCTRIBUT.PERDESCICMISENCAO%TYPE,
    UsaIsencaoIcmsVP          PCTRIBUT.USAISENCAOICMSVP%TYPE,
    BNFNAOCALCULAICMS         PCTRIBUT.BNFNAOCALCULAICMS%TYPE,
    AlteraFatorAjusteIVASN    PCTRIBUT.ALTERAFATORAJUSTEIVASN%TYPE,
    mostrarpvendasemipi       PCTRIBUT.Mostrarpvendasemipi%TYPE,
    compararpautacomst        PCTRIBUT.COMPARARPAUTACOMST%TYPE,
    UsaValorultEntbaseSTFonte PCTRIBUT.UsaValorultEntbaseSTFonte%TYPE,
    UsaValorStFonte           PCTRIBUT.USAVALORSTFONTE%TYPE,
    AgregaPisCofinsST2        PCTRIBUT.AGREGAPISCOFINSST2%TYPE,
    AgregaICMSIsencaoST2      PCTRIBUT.AGREGAICMSISENCAOST2%TYPE,
    AgregaSUFRAMAST2          PCTRIBUT.AGREGASUFRAMAST2%TYPE,
    AgregaPisCofinsST1        PCTRIBUT.AGREGAPISCOFINSST1%TYPE,
    AgregaICMSIsencaoST1      PCTRIBUT.AGREGAICMSISENCAOST1%TYPE,
    AgregaSUFRAMAST1          PCTRIBUT.AGREGASUFRAMAST1%TYPE,
    AgregaDescST1             PCTRIBUT.AGREGADESCST1%TYPE,
    RioLogIsentoSt            PCTRIBUT.RIOLOGISENTOST%TYPE,
    Tv9IsentoST               PCTRIBUT.TV9ISENTOST%TYPE,
    ---
    UsaBaseIcmsReduzida       PCTRIBUT.USABASEICMSREDUZIDA%TYPE,
    ZerarBaseIcmsOrgPubSuf    PCTRIBUT.ZERARBASEICMSORGPUBSUFRAMA%TYPE,
    PercRedNormal             PCTRIBUT.PERCBASERED%TYPE,
    PercRedConsfinal          PCTRIBUT.PERCBASEREDCONSUMIDOR%TYPE,
    PercRedNormalNrpa         PCTRIBUT.PERBASEREDNRPA%TYPE,
    PercRedNormalsimplesnac   PCTRIBUT.PERBASEREDSIMPLESNAC%TYPE,
    PercBaseRedTransfSaid     PCTRIBUT.PERCBASEREDTRANFSAID%TYPE,
    IvaTransfVirt             PCTRIBUT.IVATRANSFVIRT%TYPE,
    AliqICMS1TransfVirt       PCTRIBUT.ALIQICMS1TRANSFVIRT%TYPE,
    AliqICMS2TransfVirt       PCTRIBUT.ALIQICMS2TRANSFVIRT%TYPE,
    PautaTransfVirt           PCTRIBUT.PAUTATRANSFVIRT%TYPE,
    PercBaseRedSTTransfVirt   PCTRIBUT.PERCBASEREDSTTRANSFVIRT%TYPE,
    CodICMTransFVirt          PCTRIBUT.CODICMTRANSFVIRT%TYPE,
    SitTributTransfVirt       PCTRIBUT.SITTRIBUTTRANSFVIRT%TYPE,
    SitTributTransvfVirtEnt   PCTRIBUT.SITTRIBUTTRANSVFVIRTENT%TYPE,
    PerDiferencialTransfVirt  PCTRIBUT.PERDIFERENCIALTRANSFVIRT%TYPE,
    PerBaseredTransfVirtEnt   PCTRIBUT.PERBASEREDTRANSFVIRTENT%TYPE,
    PercBaseRedTransfVirtSaid PCTRIBUT.PERCBASEREDTRANFVIRTSAID%TYPE,
    CalcStTransf              PCTRIBUT.CALCSTTRANSF%TYPE,
    PercBaseRedST2Transf      PCTRIBUT.PERCBASEREDST2TRANSF%TYPE,
    PercBaseRedST2TransfVirt  PCTRIBUT.PERCBASEREDST2TRANSFVIRT%TYPE,
    IndiceCompBaseStMt        PCTRIBUT.INDICECOMPBASESTMT%TYPE,
    IndiceCompBaseStMg        PCTRIBUT.INDICECOMPBASESTMG%TYPE,
    PercRedBaseStCliSN        PCTRIBUT.PERCREDBCSTCLISN%TYPE,
    CalcMediaPondsStMG        PCTRIBUT.CALCMEDIAPONDSTMG%TYPE,
    CALCULASTMT               PCTRIBUT.CALCULASTMT%TYPE,
    UtilizaMotorCalculo		    PCTRIBUT.UTILIZAMOTORCALCULO%TYPE,
    FormulaPVENDA			        PCTRIBUT.FORMULAPVENDA%TYPE,
    FormulaPVENDATRANSF		    PCTRIBUT.FORMULAPVENDATRANSF%TYPE,
    FormulaPVENDATRANSFVIRT   PCTRIBUT.FORMULAPVENDATRANSFVIRT%TYPE,
    SITTRIBUT_MC              PCTRIBUT.SITTRIBUT_MC%TYPE,
    ALIQICMS2_MC              PCTRIBUT.ALIQICMS2_MC%TYPE,
    IVA_MC                    PCTRIBUT.IVA_MC%TYPE,
    PERCBASEREDST_MC          PCTRIBUT.PERCBASEREDST_MC%TYPE,
    PERCBASERED_MC            PCTRIBUT.PERCBASERED_MC%TYPE,
    CODICM_MC                 PCTRIBUT.CODICM_MC%TYPE,
    PAUTA_MC                  PCTRIBUT.PAUTA_MC%TYPE,
    ALIQICMS1_MC              PCTRIBUT.ALIQICMS1_MC%TYPE,
    BNFNAOCALCULAICMSTV14     PCTRIBUT.BNFNAOCALCULAICMSTV14%TYPE,
    ALIQICMSFECP              PCTRIBUT.ALIQICMSFECP%TYPE,
    PercAcrescimoFuncep       PCTRIBUT.PERACRESCIMOFUNCEP%TYPE,
    VLPAUTAICMSINTEREST       PCTRIBUT.VLPAUTAICMSINTEREST%TYPE,
    VLPAUTAICMSEST            PCTRIBUT.VLPAUTAICMSEST%TYPE,
    TipoCalculoGNRETransf     PCTRIBUT.TIPOCALCULOGNRETRANSFTAB%TYPE,	
    formula_preco             PCFORMULATEMP%ROWTYPE
	);

  TYPE T_FILIAL IS RECORD(
    CodFilial                    pcfilial.codigo%TYPE,
    UF                           pcfilial.uf%TYPE,
    UtilizaVendaporEmbalagem     pcfilial.UTILIZAVENDAPOREMBALAGEM%TYPE,
    UsaRegiaoFilialVendaEstadual PCFILIAL.USAREGIAOFILIALVENDAESTADUAL%Type,
    NumRegiaoPadrao              PCFILIAL.NUMREGIAOPADRAO%TYPE,
    UsaRegiaoFilialVendaInter    PCFILIAL.USAREGIAOFILIALVENDAINTEREST%Type,
    NumRegiaoPadraoInter         PCFILIAL.NUMREGIAOBALCAOINTER%TYPE,
    CGC                          PCFILIAL.CGC%TYPE,
    CodCli                       PCFILIAL.CODCLI%TYPE);

  ------------ 1400 - PKG FATURAMENTO-----------
  TYPE T_ITEMPEDIDO IS RECORD(
    VLOUTRASDESP        PCPEDI.VLOUTRASDESP%TYPE,
    VLFRETE             PCPEDI.VLFRETE%TYPE,
    ST                  PCPEDI.ST%TYPE,
    VLIPI               PCPEDI.VLIPI%TYPE,
    VLDESCICMISENCAO    PCPEDI.VLDESCICMISENCAO%TYPE,
    VLDESCREDUCAOPIS    PCPEDI.VLDESCREDUCAOPIS%TYPE,
    VLDESCREDUCAOCOFINS PCPEDI.VLDESCREDUCAOCOFINS%TYPE,
    VLDESCSUFRAMA       PCPEDI.VLDESCSUFRAMA%TYPE,
    VLFECP              PCPEDI.VLFECP%TYPE,
    VLICMSPARTREM       PCPEDI.VLICMSPARTREM%TYPE,
    CODST               PCPEDI.CODST%TYPE);
  ----------------------------------------------

    --HIS.03069.2016
  TYPE T_BONIFICACAO IS RECORD(
    CODBNF     PCTIPOBONIFIC.CODBNF%TYPE,
    CALCULAIPI PCTIPOBONIFIC.CALCULAIPI%TYPE);
  ----------------------------------------------
  TYPE T_ENDERECO_ENTREGA IS RECORD(
    CODENDENT    PCCLIENTENDENT.CODENDENTCLI%TYPE,
    NUMREGIAO    PCCLIENTENDENT.NUMREGIAO%TYPE,
    ESTENT       PCCLIENTENDENT.ESTENT%TYPE
  );
  -----------------------------------------------
  TYPE T_PEDIDO IS RECORD(
    CondVenda             PCPEDC.CONDVENDA%TYPE,
    VendaTriangular       PCPEDC.VENDATRIANGULAR%TYPE,
    RotinaConsum          VARCHAR2(10),
    OrigemPedido          PCPEDC.ORIGEMPED%TYPE,
    VendaExportacao       PCPEDC.VENDAEXPORTACAO%TYPE,
    VendaLocalEstrangeira PCPEDC.VENDALOCESTRANG%TYPE,
    Transferencia         VARCHAR2(2),
    TransferenciaVirtual  varchar2(2),
    CodEnderecoEntrega    PCPEDC.CODENDENTCLI%TYPE,
    NumPed                PCPEDC.NUMPED%TYPE,
    TipoDocumento         PCPEDC.TIPODOCUMENTO%TYPE
  );

  TYPE T_IMPOSTO IS RECORD(
    Cliente         FERRAMENTAS.T_CLIENTE,
    Produto         T_PRODUTO,
    Embalagem       T_EMBALAGEM,
    PlanoPagamento  T_PLANO_PAGAMENTO,
    Precificacao    T_PRECIFICACAO,
    Tributacao      T_TRIBUTACAO,
    Estoque         T_ESTOQUE,
    Filial          T_FILIAL,
    FilialNF        T_FILIAL,
    FilialRetira    T_FILIAL,
    Cnae            T_CNAE,
    Parametros132   T_PARAMETROS_132,
    ItemPedido      T_ITEMPEDIDO,
    Bonificacao     T_BONIFICACAO, --HIS.03069.2016
    EnderecoEntrega T_ENDERECO_ENTREGA,
    Pedido          T_PEDIDO,
    Praca           T_PRACA);

  -----------------DADOS ST----------------
  TYPE T_CALCULOST IS RECORD(
    BASEST            NUMBER,
    ST                NUMBER,
    ALIQICMS1         NUMBER(18,6),
    ALIQICMS2         NUMBER(18,6),
    PAUTA             NUMBER(18,6),
    REDUCAO           NUMBER(18,6),
    TIPO_ST           VARCHAR2(10),
    IVA               NUMBER(18,6),
    STGNRE            VARCHAR2(1),
    BASEFECP          NUMBER,
    ALIQFECP          NUMBER(18,6),
    VLRFECP           NUMBER
    );

  TYPE TB_CALCULOST IS TABLE OF T_CALCULOST;
  ------------------------------------------

  -----------------DADOS IPI----------------
  TYPE T_CALCULOIPI IS RECORD(
    VALORIPI           NUMBER(18, 8),
    PERCENTUAL_IPI     NUMBER(18,8),
    PERCENTUAL_REDUCAO NUMBER(18,8),
    BASE_IPI           NUMBER(18,9));

  TYPE TB_CALCULOIPI IS TABLE OF T_CALCULOIPI;
  ------------------------------------------

  --------------DADOS PREÇO DE VENDA SEM IMOPOSTO --------------
  TYPE T_CALCULOPVENDASEMIMPOSTO IS RECORD(
    VALORSEMIMPOSTO NUMBER(18, 6),
    MSG             VARCHAR2(3000));

  TYPE TB_CALCULOPVENDASEMIMPOSTO IS TABLE OF T_CALCULOPVENDASEMIMPOSTO;
  ---------------------------------------------------------------

  ------------DADOS DESCCONTO DE PIS/COFINS/ICMS-----------------
  TYPE T_DESCONTO_PIS_CONFINS_ICMS IS RECORD(

    VALOR_DESCONTO_PIS     NUMBER(18, 6),
    PERC_DESCONTO_PIS      NUMBER(18, 6),
    VALOR_DESCONTO_COFINS  NUMBER(18, 6),
    PERC_DESCONTO_COFINS   NUMBER(18, 6),
    VALOR_DESCONTO_ICMS    NUMBER(18, 6),
    PERC_DESCONTO_ICMS     NUMBER(18, 6),
    VALOR_DESCONTO_SUFRAMA NUMBER(18, 6),
    PERC_DESCONTO_SUFRAMA  NUMBER(18, 6)

    );

  TYPE TB_DESCONTO_PIS_CONFINS_ICMS IS TABLE OF T_DESCONTO_PIS_CONFINS_ICMS;

  ---------------------------------------------------------------

  ------------DADOS REDUCAO DE SIMPLES NACIONAL-----------------
  TYPE T_REDUCAO_SIMPLES_NACIONAL IS RECORD(

    VALOR_REDUCAO_SIMPLES_NACIONAL NUMBER(18, 6),
    PERC_REDUCAO_SIMPLES_NACIONAL  NUMBER(18, 6),
    NOVO_PRECO_SIMPLES_NACIONAL    NUMBER(18, 6),
    VL_RED_SIMPLES_NACIONAL_UNIT   NUMBER(18, 6 )

    );

  TYPE TB_REDUCAO_SIMPLES_NACIONAL IS TABLE OF T_REDUCAO_SIMPLES_NACIONAL;
  ---------------------------------------------------------------

  FUNCTION CALCULAR_ST(psCodFilial              VARCHAR2,
                       psCodFilialNF            VARCHAR2,
                       psCodFilialRetira        VARCHAR2,
                       pCodCli                  IN NUMBER,
                       pCodPlPag                IN NUMBER,
                       pCodProd                 IN NUMBER,
                       pCodAuxiliar             IN NUMBER,
                       pCondVenda               IN NUMBER,
                       psVendaExportacao        IN VARCHAR2,
                       pPvenda                  IN FLOAT,
                       pPerDesconto             IN FLOAT,
                       pItemTV1Bnf              IN VARCHAR2 DEFAULT 'N',
                       pValorDescPIS_COFINS     IN NUMBER   DEFAULT 0,
                       pValorDescICMS           IN NUMBER   DEFAULT 0,
                       pValorSUFRAMA            IN NUMBER   DEFAULT 0,
                       pROWID                   IN VARCHAR2 DEFAULT NULL,
                       pCalculaIPI              IN VARCHAR2 DEFAULT 'S', --HIS.01188.2013 (verifique história)
                       pTransferencia           IN VARCHAR2 DEFAULT 'N', --HIS.01188.2013 (verifique história)
                       pOrigemPedido            IN VARCHAR2 DEFAULT 'T',
                       pVendaLocalEstrangeira   IN VARCHAR2 DEFAULT 'N',
                       pCodPrecoFixo            IN NUMBER   DEFAULT 0,
                       pTransferenciaVirtual    IN VARCHAR2 DEFAULT 'N',
                       pPtabelaSemImposto       IN NUMBER   DEFAULT 0,     --HIS.01742.2016
                       pVendaTriangular         IN VARCHAR2 DEFAULT 'N',
                       pRotinaConsum            IN VARCHAR2 DEFAULT 'T',
                       pCodBnf                  IN NUMBER   DEFAULT 0, -- HIS.03069.2016
                       pCodEndEnt               IN NUMBER   DEFAULT 0,
                       pNaoArredondar           IN VARCHAR2 DEFAULT 'N',
                       pTipoDocumento           IN VARCHAR2 DEFAULT 'N', --Tipo do documento do pedido N = Nota, C = Cupom etc...
                       pconsultardblink         IN VARCHAR2 DEFAULT 'N',  --quando usando banco caixa, se vai no servidor ou não
                       pcontaordem              IN VARCHAR2 DEFAULT 'N', -- Conta e ordem TV8
                       pValorICMSPartilhaRem    IN NUMBER   DEFAULT 0,
                       pORIGEM                  IN VARCHAR2 DEFAULT 'PA',
					   pCodst                   IN NUMBER   DEFAULT 0
                       )
    RETURN TB_CALCULOST
    PIPELINED;

  FUNCTION CALCULAR_IPI(psCodFilial            VARCHAR2,
                        psCodFilialNF          VARCHAR2,
                        psCodFilialRetira      VARCHAR2,
                        pCodCli                IN NUMBER,
                        pCodProd               IN NUMBER,
                        pCodAuxiliar           IN NUMBER,
                        pCondVenda             IN NUMBER,
                        psVendaExportacao      IN VARCHAR2,
                        pVenda                 IN NUMBER,
                        pVendaLocalEstrangeira IN VARCHAR2 DEFAULT 'N',
                        pOrigemPedido          IN VARCHAR2 DEFAULT 'T',
                        pPtabelaSemImposto     IN NUMBER DEFAULT 0,
                        pRotinaConsum          IN VARCHAR2 DEFAULT 'T',
                        pCodBnf                IN NUMBER  DEFAULT 0,  -- HIS.03069.2016
                        pNaoArredondar         IN VARCHAR2 DEFAULT 'N'
                   ) RETURN TB_CALCULOIPI
  PIPELINED;

  FUNCTION CALCULAR_IPI(psCodFilial            VARCHAR2,
                        psCodFilialNF          VARCHAR2,
                        psCodFilialRetira      VARCHAR2,
                        pCodCli                IN NUMBER,
                        pCodProd               IN NUMBER,
                        pCodAuxiliar           IN NUMBER,
                        pCondVenda             IN NUMBER,
                        psVendaExportacao      IN VARCHAR2,
                        pVenda                 IN NUMBER,
                        pVendaTriangular       IN VARCHAR2,
                        pCodEndEnt             IN NUMBER ,
                        pTransferencia         IN VARCHAR2,
                        pTransferenciaVirtual  IN VARCHAR2,
                        pVendaLocalEstrangeira IN VARCHAR2 DEFAULT 'N',
                        pOrigemPedido          IN VARCHAR2 DEFAULT 'T',
                        pPtabelaSemImposto     IN NUMBER DEFAULT 0,   --HIS.01742.2016
                        pRotinaConsum          IN VARCHAR2 DEFAULT 'T',
                        pCodBnf                IN NUMBER   DEFAULT 0, -- HIS.03069.2016
                        pNaoArredondar         IN VARCHAR2 DEFAULT 'N',
                        pTipoDocumento         IN VARCHAR2 DEFAULT 'N', --Tipo do documento do pedido N = Nota, C = Cupom etc...
                        pconsultardblink         IN VARCHAR2 DEFAULT 'N',  --quando usando banco caixa, se vai no servidor ou não
                        pcontaordem            IN VARCHAR2 DEFAULT 'N', -- Conta e ordem
						pCodst                   IN NUMBER   DEFAULT 0
                        ) RETURN TB_CALCULOIPI
    PIPELINED;



  function CALCULAR_PVENDA_SEM_IMPOSTO(psCodFilial            VARCHAR2,
                                       psCodFilialNF          VARCHAR2,
                                       psCodFilialRetira      VARCHAR2,
                                       pCodCli                IN NUMBER,
                                       pCodPlPag              IN NUMBER,
                                       pCodProd               IN NUMBER,
                                       pCodAuxiliar           IN NUMBER,
                                       pCondVenda             IN NUMBER,
                                       psVendaExportacao      IN VARCHAR2,
                                       pSTPrecificado         IN NUMBER,
                                       pVendaSemImposto       IN NUMBER,
                                       pVenda                 IN NUMBER,
                                       pRetiraImposto201      IN VARCHAR2 DEFAULT 'N',
                                       pFoiPrecificadoIPI     IN VARCHAR2 DEFAULT 'S',
                                       pItemTV1Bnf            IN VARCHAR2 DEFAULT 'N',
                                       pCodPrecoFixo          IN NUMBER   DEFAULT 0,
                                       psOrigemPedido         IN VARCHAR2 DEFAULT NULL,
                                       pUtilizaCustoVendaTV10 IN VARCHAR2 DEFAULT 'N',
                                       pTransferencia         IN VARCHAR2 DEFAULT 'N',
                                       pVendaLocalEstrangeira IN VARCHAR2 DEFAULT 'N',
                                       pTransferenciaVirtual  IN VARCHAR2 DEFAULT 'N',
                                       pPtabela               IN NUMBER   DEFAULT 0,  --HIS.01742.2016
                                       pVendaTriangular       IN VARCHAR2 DEFAULT 'N',
                                       pRotinaConsum          IN VARCHAR2 DEFAULT 'T',
                                       pCodBnf                IN NUMBER   DEFAULT 0, -- HIS.03069.2016
                                       pCodEndEnt             IN NUMBER   DEFAULT 0,
                                       pTipoDocumento         IN VARCHAR2 DEFAULT 'N', --Tipo do documento do pedido N = Nota, C = Cupom etc...
                                       pconsultardblink       IN VARCHAR2 DEFAULT 'N',  --quando usando banco caixa, se vai no servidor ou não
                                       pcontaordem            IN VARCHAR2 DEFAULT 'N', -- Conta e ordem TV8
                                       pValorICMSPartilhaRem  IN NUMBER   DEFAULT 0,
                                       pRetiraFecp            IN VARCHAR2 DEFAULT 'N' --Retirar FECEP para sem somado futuramente no preço
                                       )
    RETURN TB_CALCULOPVENDASEMIMPOSTO
    PIPELINED;

  FUNCTION CALCULAR_DESC_PIS_COFINS_ICMS(psCodFilial       VARCHAR2,
                                         psCodFilialNF     VARCHAR2,
                                         psCodFilialRetira VARCHAR2,
                                         pCodCli           IN NUMBER,
                                         pCodProd          IN NUMBER,
                                         pPreco            IN FLOAT,
                                         pNumEmpenho       IN NUMBER,
                                         pPrazoMedioPedido IN NUMBER,
                                         pVendaTriangular  IN VARCHAR2 DEFAULT 'N',
										 pCodEndEnt        IN NUMBER DEFAULT 0,
										 pCodst IN NUMBER DEFAULT 0)
    RETURN TB_DESCONTO_PIS_CONFINS_ICMS
    PIPELINED;

  FUNCTION CALCULAR_RED_SIMPLES_NACIONAL(psCodFilial            VARCHAR2,
                                         psCodFilialNF          VARCHAR2,
                                         psCodFilialRetira      VARCHAR2,
                                         pCodCli                IN NUMBER,
                                         pCodPlPag              IN NUMBER,
                                         pCodProd               IN NUMBER,
                                         pCodAuxiliar           IN NUMBER,
                                         pCondVenda             IN NUMBER,
                                         psVendaExportacao      IN VARCHAR2,
                                         pPreco                 IN NUMBER,
                                         pPrecoTributado        IN NUMBER,
                                         pVendaLocalEstrangeira IN VARCHAR2 DEFAULT 'N',
                                         pconsultardblink       IN VARCHAR2 DEFAULT 'N',  --quando usando banco caixa, se vai no servidor ou não
										 pCodst                 IN NUMBER DEFAULT 0
                                         )
    RETURN TB_REDUCAO_SIMPLES_NACIONAL
    PIPELINED;

  FUNCTION GET_CLIENTE_SUFRAMADO(PCODCLI IN NUMBER, PDATANF IN DATE Default TRUNC(SYSDATE))
   RETURN VARCHAR2;

  FUNCTION RETORNA_CODIGO_TRIBUTACAO(pCodCli           IN NUMBER,
                                     pCodProd          IN NUMBER,
                                     psCodFilial       VARCHAR2,
                                     pnNumRegiao       IN NUMBER DEFAULT 0,
                                     psVendaTriangular IN VARCHAR2 DEFAULT 'N',
                                     pCondVenda        IN NUMBER DEFAULT 0,
                                     pCodEndEnt        IN NUMBER DEFAULT 0) RETURN NUMBER;

  FUNCTION CALCULAR_PVENDA_E_IMPOSTOS   (psCodFilial               VARCHAR2,
                                         psCodFilialNF          VARCHAR2,
                                         psCodFilialRetira      VARCHAR2,
                                         pCodCli                IN NUMBER,
                                         pCodPlPag              IN NUMBER,
                                         pCodProd               IN NUMBER,
                                         pCodAuxiliar           IN NUMBER,
                                         pCondVenda             IN NUMBER,
                                         psVendaExportacao      IN VARCHAR2,
                                         pPrecoVenda            IN NUMBER,
                                         pPrecoSI210            IN NUMBER,
                                         pST210                 IN NUMBER,
                                         pTipoDocumento         IN VARCHAR2 DEFAULT 'N', --Tipo do documento do pedido N = Nota, C = Cupom etc...
                                         pconsultardblink         IN VARCHAR2 DEFAULT 'N',  --quando usando banco caixa, se vai no servidor ou não
                                         palteracao         IN VARCHAR2 DEFAULT 'N'
                                         )
    RETURN TB_VENDA_AUTOSERVICO
    PIPELINED;
END;
