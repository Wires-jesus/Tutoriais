create or replace package IMPORTARINDENIZACOES is

  /*

    Package de Integracao do Winthor com Sistemas de Forca de Vendas para importar Indenizações

    ----------------     Historico     ----------------
    Data        Responsável    Tarefa          Comentario
    03/10/2013  Andréa         212669           Primeira Versao - (alteracoes iniciais)
    16/01/2014  Andréa         HIS.00043.2014   Gravar no historico da tabela pccrecli o número da indenização
  */



  type t_clientepedido is record(
    bloqueio                   pcclient.bloqueio%type,
    calculast                  pcclient.calculast%type,
    cliente                    pcclient.cliente%type,
    codcli                     pcclient.codcli%type,
    codcliprinc                pcclient.codcliprinc%type,
    codcob                     pcclient.codcob%type,
    codfilialnf                pcclient.codfilialnf%type,
    codplpag                   pcclient.codplpag%type,
    codpraca                   pcclient.codpraca%type,
    condvenda1                 pcclient.condvenda1%type,
    condvenda2                 pcclient.condvenda2%type,
    condvenda3                 pcclient.condvenda3%type,
    condvenda4                 pcclient.condvenda4%type,
    condvenda5                 pcclient.condvenda5%type,
    condvenda6                 pcclient.condvenda6%type,
    condvenda10                pcclient.condvenda10%type,
    descproduto                pcclient.descproduto%type,
    estent                     pcclient.estent%type,
    ieent                      pcclient.ieent%type,
    limcred                    pcclient.limcred%type,
    numdias                    pcplpag.numdias%type,
    percomcli                  pcclient.percomcli%type,
    perdesc                    pcclient.perdesc%type,
    prazoadicional             pcclient.prazoadicional%type,
    tipofj                     pcclient.tipofj%type,
    numregiao                  pcpraca.numregiao%type,
    codatv1                    pcclient.codatv1%type,
    validamaxvendapf           pcclient.validamaxvendapf%type,
    consumidorfinal            pcclient.consumidorfinal%type,
    clientefontest             pcclient.clientefontest%type,
    isentoicms                 pcclient.isentoicms%type,
    utilizaiesimplificada      pcclient.utilizaiesimplificada%type,
    tipoempresa                pcclient.tipoempresa%type,
    contribuinte               pcclient.contribuinte%type,
    classevenda                pcclient.classevenda%type,
    isentoipi                  pcclient.isentoipi%type,
    suframa                    pcclient.sulframa%type,
    tipodescisencao            pcclient.tipodescisencao%type,
    perdescisentoicms          pcclient.perdescisentoicms%type,
    usaivafontediferenciado    pcclient.usaivafontediferenciado%type,
    ivafonte                   pcclient.ivafonte%type,
    orgaopub                   pcclient.orgaopub%type,
    orgaopubfederal            pcclient.orgaopubfederal%type,
    cepent                     pcclient.cepent%type,
    municent                   pcclient.municent%type,
    enderent                   pcclient.enderent%type,
    cgcent                     pcclient.cgcent%type,
    origempreco                pcclient.origempreco%type,
    repasse                    pcclient.repasse%type,
    dtvencalvara               pcclient.dtvencalvara%type,
    dtvencalvarafunc           pcclient.dtvencalvarafunc%type,
    dtvencalvaraanvisa         pcclient.dtvencalvaraanvisa%type,
    dtvenccrf                  pcclient.dtvenccrf%type ,
    simplesnacional            pcclient.simplesnacional%type,
    validarmultiplovenda       pcclient.validarmultiplovenda%type,
    clientemonitorado          pcclient.clientemonitorado%type,
    codrede                    pcclient.codrede%type ,
    validarcampanhabrinde      pcclient.validarcampanhabrinde%type,
    utilizaplpagmedicamento    pcclient.utilizaplpagmedicamento%type,
    codplpagetico              pcclient.codplpagetico%type,
    codplpaggenerico           pcclient.codplpaggenerico%type,
    bloqueiosefaz              pcclient.bloqueiosefaz%type,
    tipocustotransf            pcclient.tipocustotransf%type,
    peracrestransf             pcclient.peracrestransf%type,
    registroibama              pcclient.registroibama%type,
    dtvalidadeibama            pcclient.dtvalidadeibama%type,
    isencaosuframa             pcclient.isencaosuframa%type,
    fretedespacho              pcclient.fretedespacho%type,
    turnoentrega               pcclient.turnoentrega%type,
    telent                     pcclient.telent%type,
    bairroent                  pcclient.bairroent%type,
    usadescontoicms            pcclient.usadescontoicms%type,
    utilizacalculostmt         pcclient.utilizacalculostmt%type,
    percargatribmedia          pccnae.percargatribmedia%type,
    margemmva                  pccnae.margemmva%type,
    aceitavendafracao          pcclient.aceitavendafracao%type,
    obsentrega1                pcclient.obsentrega1%type,
    obsentrega2                pcclient.obsentrega2%type,
    obsentrega3                pcclient.obsentrega3%type,
    obsentrega4                pcclient.obsentrega4%type,
    usadebcredrca              pcclient.usadebcredrca%type
    );


  type t_rca is record(
    bloqueio                   pcusuari.bloqueio%type,
    coddistrib                 pcusuari.coddistrib%type,
    codsupervisor              pcusuari.codsupervisor%type,
    codusur                    pcusuari.codusur%type,
    nome                       pcusuari.nome%type,
    percent2                   pcusuari.percent2%type,
    PERCENT                    pcusuari.PERCENT%type,
    proxnumped                 pcusuari.proxnumped%type,
    tipovend                   pcusuari.tipovend%type,
    permaxvenda                pcusuari.permaxvenda%type,
    usadebcredrca              pcusuari.usadebcredrca%type,
    vlvendaminped              pcusuari.vlvendaminped%type,
    percacresfv                pcusuari.percacresfv%type);

  type t_planodepagamento is record(
    codplpag                   pcplpag.codplpag%type,
    numdias                    pcplpag.numdias%type,
    numitensminimo             pcplpag.numitensminimo%type,
    numpr                      pcplpag.numpr%type,
    obs                        pcplpag.obs%type,
    pertxfim                   pcplpag.pertxfim%type,
    prazo1                     pcplpag.prazo1%type,
    prazo2                     pcplpag.prazo2%type,
    prazo3                     pcplpag.prazo3%type,
    prazo4                     pcplpag.prazo4%type,
    prazo5                     pcplpag.prazo5%type,
    prazo6                     pcplpag.prazo6%type,
    prazo7                     pcplpag.prazo7%type,
    prazo8                     pcplpag.prazo8%type,
    prazo9                     pcplpag.prazo9%type,
    prazo10                    pcplpag.prazo10%type,
    prazo11                    pcplpag.prazo11%type,
    prazo12                    pcplpag.prazo12%type,
    tipoprazo                  pcplpag.tipoprazo%type,
    tipovenda                  pcplpag.tipovenda%type,
    vlminpedido                pcplpag.vlminpedido%type,
    vendabk                    pcplpag.vendabk%type,
    tiporestricao              pcplpag.tiporestricao%type,
    codrestricao               pcplpag.codrestricao%type,
    codfilial                  pcplpag.codfilial%type,
    formaparcelamento          pcplpag.formaparcelamento%type,
    usamultifilial             pcplpag.usamultifilial%type,
    diasminparcela             pcplpag.diasminparcela%type,
    diasmaxparcela             pcplpag.diasmaxparcela%type,
    vlminparcela               pcplpag.vlminparcela%type,
    numparcelas                pcplpag.numparcelas%type,
    tipoentrada                pcplpag.tipoentrada%type,
    margemmin                  pcplpag.margemmin%type,
    descentlimcredcli          pcplpag.descentlimcredcli%type);



  type t_regiaocliente is record(
    numregiao                  pcregiao.numregiao%type,
    perfrete                   pcregiao.perfrete%type,
    perfreteterceiros          pcregiao.perfreteterceiros%type,
    perfreteespecial           pcregiao.perfreteespecial%type,
    regiaozfm                  pcregiao.regiaozfm%type,
    codestabelecimento         pcregiao.codestabelecimento%type);

  type t_produto is record(
    codcategoria               pcprodut.codcategoria%type,
    codepto                    pcprodut.codepto%type,
    codfornec                  pcprodut.codfornec%type,
    codprod                    pcprodut.codprod%type,
    codsec                     pcprodut.codsec%type,
    descricao                  pcprodut.descricao%type,
    embalagem                  pcprodut.embalagem%type,
    obs                        pcprodut.obs%type,
    obs2                       pcprodut.obs2%type,
    pcomext1                   pcprodut.pcomext1%type,
    pcomint1                   pcprodut.pcomint1%type,
    pcomrep1                   pcprodut.pcomrep1%type,
    pesobruto                  pcprodut.pesobruto%type,
    ptabela                    number,
    qtunit                     pcprodut.qtunit%type,
    volume                     pcprodut.volume%type,
    codprodprinc               pcprodut.codprodprinc%type,
    perindeniz                 pcprodut.perindeniz%type,
    codlinhaprod               pcprodut.codlinhaprod%type,
    coddistrib                 pcprodut.coddistrib%type,
    freteespecial              pcprodut.freteespecial%type,
    classe                     pcprodut.classe%type,
    percipivenda               pcprodut.percipivenda%type,
    prazomediovenda            pcprodut.prazomediovenda%type,
    importado                  pcprodut.importado%type,
    percipivendatab            pcprodut.percipivendatab%type,
    vlpautaipivenda            pcprodut.vlpautaipivenda%type,
    vlpautaipivendatab         pcprodut.vlpautaipivendatab%type,
    vlipiporkgvenda            pcprodut.vlipiporkgvenda%type,
    vlipiporkgvendatab         pcprodut.vlipiporkgvendatab%type,
    prazomaxindenizacao        pcprodut.prazomaxindenizacao%type,
    pesobrutomaster            pcprodut.pesobrutomaster%type,
    pesopeca                   pcprodut.pesopeca%type,
    tipoestoque                pcprodut.tipoestoque%type,
    tipomerc                   pcprodut.tipomerc%type,
    custorep                   pcprodut.custorep%type,
    custorepzfm                pcprodut.custorepzfm%type,
    psicotropico               pcprodut.psicotropico%type,
    percbonificvenda           pcprodut.percbonificvenda%type,
    utilizaprecomaxconsumidor  pcprodut.utilizaprecomaxconsumidor%type,
    precomaxconsum             pcprodut.precomaxconsum%type,
    unidademaster              pcprodut.unidademaster%type,
    multiplo                   pcprodut.multiplo%type,
    checarmultiplovendabnf     pcprodut.checarmultiplovendabnf%type,
    codfilialretira            pcprodut.codfilialretira%type ,
    tipocomissao               pcprodut.tipocomissao%type,
    grupofaturamento           pcprodut.grupofaturamento%type,
    codsubcategoria            pcprodut.codsubcategoria%type,
    controladoibama            pcprodut.controladoibama%type,
    revenda                    pcprodut.revenda%type,
    aceitavendafracao          pcprodut.aceitavendafracao%type,
    restricaotransp            pcprodut.restricaotransp%type
   );


  type t_precosetributacao is record(
    aliqicms1                  pctribut.aliqicms1%type,
    aliqicms2                  pctribut.aliqicms2%type,
    codicmtab                  pctribut.codicmtab%type,
    codst                      pctabpr.codst%type,
    custocont                  pcest.custocont%type,
    custofin                   pcest.custofin%type,
    custoreal                  pcest.custoreal%type,
    custorep                   pcest.custorep%type,
    custoultent                pcest.custoultent%type,
    excluido                   pctabpr.excluido%type,
    iva                        pctribut.iva%type,
    pauta                      pctribut.pauta%type,
    peracrescismopf            pctribut.peracrescismopf%type,
    perdescautor               pctabpr.perdescautor%type,
    perdesccusto               pctribut.perdesccusto%type,
    perdescmax                 pctabpr.perdescmax%type,
    perdescmaxesp              pctabpr.perdescmaxesp%type,
    perdesctab                 pctribut.perdestab%type,
    precominimovenda           pctabpr.precominimovenda%type,
    pvenda                     pctabpr.pvenda%type,
    pvenda1                    pctabpr.pvenda1%type,
    pvenda2                    pctabpr.pvenda2%type,
    pvenda3                    pctabpr.pvenda3%type,
    pvenda4                    pctabpr.pvenda4%type,
    pvenda5                    pctabpr.pvenda5%type,
    pvenda6                    pctabpr.pvenda6%type,
    pvenda7                    pctabpr.pvenda7%type,
    qtdescautor                pctabpr.qtdescautor%type,
    aplicaacrescpjisenta       pctribut.aplicaacrescpjisenta%type,
    percbaseredst              pctribut.percbaseredst%type,
    tipocalculognre            pctribut.tipocalculognre%type,
    ivafonte                   pctribut.ivafonte%type,
    aliqicms1fonte             pctribut.aliqicms1fonte%type,
    aliqicms2fonte             pctribut.aliqicms2fonte%type,
    percbaseredstfonte         pctribut.percbaseredstfonte%type,
    percbasered                pctribut.percbasered%type,
    perbaserednrpa             pctribut.perbaserednrpa%type,
    percbaseredconsumidor      pctribut.percbaseredconsumidor%type,
    utilizapercbaseredpf       pctribut.utilizapercbaseredpf%type,
    valorultent                pcest.valorultent%type,
    usavalorultentbasest       pctribut.usavalorultentbasest%type,
    usavalorultentbasest2      pctribut.usavalorultentbasest2%type,
    codicmtabpf                pctribut.codicmtabpf%type,
    perdescsuframa             pctribut.perdescsuframa%type,
    perdescicmisencao          pctribut.perdescicmisencao%type,
    descontafrete              pctabpr.descontafrete%type,
    percdescpis                pctribut.percdescpis%type,
    percdesccofins             pctribut.percdesccofins%type,
    perdescrepasse             pctribut.perdescrepasse%type,
    precomaxconsum             pctabpr.precomaxconsum%type,
    qtunit                     pcembalagem.qtunit%type,
    fatorpreco                 pcembalagem.fatorpreco%TYPE,
    qtminimaatacado            pcembalagem.qtminimaatacado%TYPE,
    pvendaatac                 pcembalagem.pvendaatac%TYPE,
    pvendaemb                  pcembalagem.pvenda%TYPE,
    poferta                    pcembalagem.poferta%TYPE,
    pvendaatac1                pctabpr.pvendaatac1%TYPE,
    pvendaatac2                pctabpr.pvendaatac2%TYPE,
    pvendaatac3                pctabpr.pvendaatac3%TYPE,
    pvendaatac4                pctabpr.pvendaatac4%TYPE,
    pvendaatac5                pctabpr.pvendaatac5%TYPE,
    pvendaatac6                pctabpr.pvendaatac6%TYPE,
    pvendaatac7                pctabpr.pvendaatac7%TYPE,
    dtofertaini                pcembalagem.dtofertaini%TYPE,
    dtofertafim                pcembalagem.dtofertafim%TYPE,
    dtofertaatacini            pcembalagem.dtofertaatacini%TYPE,
    dtofertaatacfim            pcembalagem.dtofertaatacfim%TYPE,
    pofertaatac                pcembalagem.pofertaatac%TYPE,
    mostrarpvendasemst         pctribut.mostrarpvendasemst%type,
    usapmcbasest               pctribut.usapmcbasest%type,
    custonfsemst               pcest.custonfsemst%type,
    percredpvendasimplesnac    pctribut.percredpvendasimplesnac%type,
    vlstultent            pcest.vlstultent%type,
    percdifaliquotas      pctribut.percdifaliquotas%type,
    custonfsemstguiaultent   pcest.custonfsemstguiaultent%type,
    ivaultent                pcest.ivaultent%type,
    aliqicms1ultent          pcest.aliqicms1ultent%type,
    aliqicms2ultent          pcest.aliqicms2ultent%type,
    redbaseivaultent         pcest.redbaseivaultent%type,
    percicmsfretefobstultent pcest.percicmsfretefobstultent%type,
    vlfreteconhecultent      pcest.vlfreteconhecultent%type,
    percaliqextguiaultent    pcest.percaliqextguiaultent%type,
    baseicmsultent           pcest.baseicmsultent%type,
    vlstguiaultent           pcest.vlstguiaultent%type,
    usaisencaoicmsvp         pctribut.usaisencaoicmsvp%type,
    pagtonomedocliente       pctribut.pagtonomedocliente%type,
    perdescmaxbalcao         pctabpr.perdescmaxbalcao%type,
    usaaliqicmssimplesnacional pctribut.usaaliqicmssimplesnacional%type,
    aliqstsimplesnacional    pctribut.aliqstsimplesnacional%type,
    agregaripicalculost      pctribut.agregaripicalculost%type,
    precofab                 pctabpr.precofab%type,
    pcomint1_emb             pcembalagem.pcomint1%type,
    PCOMEXT1_emb             pcembalagem.pcomext1%type,
    PCOMREP1_emb             pcembalagem.pcomrep1%type
     );




  type t_registralog is record(
    numped                     pcpedc.numped%type,
    numpedrca                  pcpedc.numpedrca%type,
    codprod                    pcprodut.codprod%type,
    codauxiliar                pcpedi.codauxiliar%type,
    cgcent                     pcclient.cgcent%type,
    codigocotacao              pccota.codcotacao%type,
    numrecadofv                pcrecfunc.numrecadofv%type,
    numcontagem                pcgondolac.numcontagem%type,
    codusur                    pcpedc.codusur%type,
    data                       date,
    cancelada                  varchar2(1), -- utilizado pela pronta entrega
    tiporeg                    varchar2(2),
    -- 1 = generico / -1 = Clientes /2 = cabecalho / 3 = itens /4 = Contatos/5= PCRECFUN/6 = gondolac/7- gondolai/ 8= Visitas/9 = indenizacao/10= item idenizacao
    -- 11 = pronta entrega /12 = intes pronta entrega /13=cotaçõs
    erro                       varchar2(32767),
    linhareg                   number);

  type t_pccob is record(
    nivelvenda                 pccob.nivelvenda%type,
    prazomaximovenda           pccob.prazomaximovenda%type,
    boleto                     pccob.boleto%type,
    codfilial                  pccob.codfilial%type,
    cartao                     pccob.cartao%type);

  type t_filial is record(
    codigo                       pcfilial.codigo%type,
    uf                           pcfilial.uf%type,
    permitirvendainterestadualpf pcfilial.permitirvendainterestadualpf%type,
    permitirvendaestadualpfcomie pcfilial.permitirvendaestadualpfcomie%type,
    permitirvendaestadualpfsemie pcfilial.permitirvendaestadualpfsemie%type,
    calcestdispcomqtminautoserv  pcfilial.calcestdispcomqtminautoserv%type,
    usaintegracaowms             pcfilial.usaintegracaowms%type,
    tipobroker                   varchar2(10),
    calcularipivenda             pcfilial.calcularipivenda%type,
    utilizacontrolemedicamentos  varchar2(2),
    broker                       varchar2(2),
    utilizavendaporembalagem     varchar2(2),
    precoporembalagem            varchar2(2),
    tipoprecificacao             varchar2(2),
    validaalvaraporitem          varchar2(2),
    arredondaqtembalfrios        varchar2(2),
    aceitavendasemestfv          varchar2(2),
    origemcustofilialretira      pcfilial.origemcustofilialretira%type,
    naousarautdebcredpoldesc     varchar2(2),
    aceitadesctmkfv              varchar2(2),
    aceitavendarcasemsaldofv     varchar2(2),
    tipoavaliacaocomissao        pcfilial.tipoavaliacaocomissao%type,
    considerarcomissaozero       pcfilial.considerarcomissaozero%type,
    bloquearpedidosabaixovlminimo varchar2(2),
    tipoimportacaovenda           varchar2(2),
    somacreditocliprincipal       varchar2(2),
    usabnflimitecredito           varchar2(2),
    aceitavendaavistaclibloq      varchar2(2),
    validarpoliticasdescclibloq   varchar2(2),
    verificabloqueiosefaz         varchar2(2),
    vlmaxvendabonificmes          number(18,6),
    aceitavendasemdtvencfv        varchar2(2),
    permaxdescvenda               number(18,6),
    obrigatoriovinculartv5comtv1  varchar2(2),
    separarprodcomrestricaotransp varchar2(2),
    usaabatimento                 varchar2(2),
    percmaxabatimento             number(18,6),
    utilizaroteirizacao           varchar2(2),
    atualizarotanomomentovenda    varchar2(2),
    validarprecovendatv20         varchar2(2),
    vlminvendabkfilial            number(18,6),
    montarkitautomaticamente      varchar2(2),
    vlminvenda                    number(18,6),
    modemissaonfetv14             varchar2(3),
    bloqpedlimcred                varchar2(2),
    abatimentodebitarccrca        varchar2(2),
    numregiaobalcaointer          pcregiao.numregiao%type,
    vlminvendafv                  number(18,6),
    vlminvendabnffv               number(18,6),
    validavlminvendabalcao        varchar2(2),
    informarecebedorvenda         varchar2(2),
    utilizanfe                    varchar2(2),
    usacodclivenda                varchar2(2),
    separarprodcomst              varchar2(2),
    verificaestoquecont           varchar2(2),
    validarclisefaz               varchar2(2),
    reservarestoquetv7            varchar2(2),
    bloqpedabaixomargemfv         varchar2(1),
    gerarcreditoindenizfv         varchar2(1),
    codcontadespindeniz           number(10)
    );

  type t_indenizacao is record(
    numindeniz                 pcindc.numindeniz%type,
    codindeniz                 number,
    data                       pcindc.data%type,
    vltotal                    pcindc.vltotal%type,
    vltotalpedido              pcpedc.vltotal%type,
    codcli                     pcindc.codcli%type,
    cgccli                     pcclient.cgcent%type,
    codfilial                  pcindc.codfilial%type,
    totpeso                    pcindc.totpeso%type,
    totvolume                  pcindc.totvolume%type,
    numitens                   pcindc.numitens%type,
    codemitente                pcindc.codemitente%type,
    numnota                    pccrecli.numnota%type,
    numtransvenda              pccrecli.numtransvenda%type,
    posicao                    pcindc.posicao%type,
    numped                     pcindc.numped%type,
    numpedrca                  pcpedc.numpedrca%type,
    codusur                    pcindc.codusur%type,
    tipoindeniz                pcindc.tipoindeniz%type,
    obs                        pcindc.obs%type,
    datapedido                 date,
    numregiao                  pcpedc.numregiao%type,
    codfilialnf                pcpedc.codfilialnf%type,
    valido                     boolean);

  type t_itemindenizacao is record(
    numindeniz                 pcindi.numindeniz%type,
    codindeniz                 number,
    codprod                    pcindi.codprod%type,
    qt                         pcindi.qt%type,
    pvenda                     pcindi.pvenda%type,
    perdesc                    pcindi.perdesc%type,
    ptabela                    pcindi.ptabela%type,
    obs                        pcindi.obs%type,
    recolher                   pcindi.recolher%type,
    valido                     boolean);



  type tb_registralog is table of t_registralog index by binary_integer;


  type tb_indenizacao is table of t_indenizacao index by binary_integer;

  type tb_itemindenizacao is table of t_itemindenizacao index by binary_integer;


FUNCTION func_lockindenizacao(P_NUMPEDRCA   IN NUMBER,
                           P_CODUSUR     IN NUMBER,
                           P_DATA        IN DATE,
                           P_CGCCLI      IN VARCHAR,
                           P_TIPOLEITURA IN NUMBER) RETURN BOOLEAN;

  -- As procedures devem ser habilitadas conforme a empresa prestadora.
PROCEDURE importarpedido(p_tipoleitura IN NUMBER DEFAULT 1,
                         p_datainicial IN DATE DEFAULT TRUNC(SYSDATE),
                         p_datafinal   IN DATE DEFAULT TRUNC(SYSDATE),
                         p_codfilial   IN VARCHAR2 DEFAULT '99',
                         p_tiporeg     IN NUMBER default null,
                         p_codusur     IN NUMBER default null
                         ) ;




  --   {FIM ALT}
  gregpcconsum pcconsum%rowtype; -- parametros do sistema
  vngcontador  integer default 0;


  gvetregistralog         tb_registralog;


  gregindenizacao         t_indenizacao;
  gvet_regindenizacao     tb_indenizacao;

  gregitemindenizacao     t_itemindenizacao;
  gvet_regitemindenizacao tb_itemindenizacao;


  vngtipoleitura          number(2);
  vngdatainicio           date;
  vngdatafim              date;
  vngtiporeg              number(2);

end; -- IMPORTARINDENIZACOES

