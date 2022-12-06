create or replace package Apurarcampanhasbrindes is

  /*

      Package de Apuracao de Campanhas de Brinde

      ----------------     Historico     ----------------
      Data        Responsável    Tarefa     Comentario
      02/02/2012  Andréa         154920     Primeira versão
      06/02/2012  Andréa         133659     Incluir validação da coluna classevenda na pcpromc
      28/02/2012  Andréa         152983     Calcular percentual de desconto de isencao de impostos do produto de acordo com a parametrizacao do campo "%Desc.Isencao(Suframa)" do cadastro do cliente
      28/02/2012  Andréa         151307     Validar o parâmetro "Utiliza %Desc Isencao ICMS para vendas a prazo"
      29/02/2012  Andréa         157415     Acrescentar arredondamento em brinde por mix
      29/03/2012  Andréa         159152     Acrescentar verificação da coluna pcpromc.usadebcredrcabrind para atualizar ou não a conta corrente do rca
      22/05/2012  Andréa         162743     Inclusão da chamada da package PKG_BRINDEEX
      16/07/2012  Andréa         167522     Correção em campanha de brinde por Mix
      14/08/2012  Andréa         166753     Incluir possiblidade do brinde se um produto cesta basica
      24/08/2012  Andrea         171877     Corrigir variavel que recebe o campo tipomerc da pcprodut
      10/09/2012  Andrea         173575     Incluir tributacao por estado
      28/09/2012  Andréa         175686     Correção em verificação de limite disponivel de brinde
      12/11/2012  Andréa         180111     Incluir verificação do parametro aceitavendasemestfv no caso de brindes sem estoque
      14/11/2012  Andréa         180947     Utilizar filial do pedido na validação da tributação por estado, caso a filialnf do pedido esteja nula e a filianf do cadastro do cliente também esteja nula
      26/12/2012  Andréa         185204     Gravar campo fretedespacho na pcpedc
      07/01/2013  Andréa         185760     Gravar qtunitemb na pcpedi com o valor da pcprodut.qtunit
      18/04/2013  Andréa         195951     Gravar codigo da campanha de brinde no campo codigobrinde
      24/04/2013  Andréa         196686     Gravar campo grpregracamp da package brindeex na pcpedi
      08/05/2013  Unilson        198152     Alteração do campo GRPREGRACAMP para GRPREGRABRINDE da tabela PCPEDI
      28/05/2013  Andréa                    Correção em geração de pedido de brinde com item de cesta básica
      04/06/2013  Andréa         201124     Gravar campo bonific na pcpedi com o valor fixo F
      13/06/2013  Andréa         202192     Gravar campo codfornecfrete, buscando do pedido de venda
      03/07/2013  Andréa         178683     Incluir opção de utilizar venda e preço por embalagem nos itens da cesta
      05/07/2013  Andréa         204123     Comentar alteração da tarefa 178683
      17/07/2013  Andréa         204407     Corrigir gravação de cmv para produto cesta  e atualizar processo de comissão dos itens da cesta
      24/07/2013  Andréa         205559     Incluir calculo de stclientegnre
      10/10/2013  Andréa         213518     Correção em campanha de brinde por MIX
      18/10/2013  Andréa         213518     Ajuste da tarefa 213518
      18/10/2013  Andréa         213375     Incluir validação de desconto/acrescimo das rotinas 561 e 357
      29/10/2013  Andréa          HIS.00045.2013    Inclusão de regra de st para clientes de MG ( legislação)
      18/11/2013  Andréa         2729.007153.2013   Correção em campanha de Valor com restricao
      20/11/2013  Andréa         2729.007153.2013   Correção em campanha por valor Total com restrição de quantidade
      17/12/2013  Andréa         1168.010921.2013   Corrigir para enviar na mensagem de retorno, todos os os itens de brinde
      26/12/2013  Andréa          664.020774.2013   Corrigir gravação de itens da cesta para gravar comissão zero
      07/01/2014  Andréa          664.001976.2014   Correção em campanha por fornecedor
      20/01/2014  Andréa          3019.004583.2014  Gravar numcar = 0 na pcpedi
      13/02/2014  Andréa          HIS.00492.2014    Utilizar o parâmetro con_verificaestoquecont em conjunto com o verificaestoquecont da pcparamfilial.
                                                    Se algum deles estiver 'S' irá verificar o estoque contábil
      21/05/2014  Luciano Lima   3346.043530.2014  Corrigir geração de Brinde.
      27/06/2014  Luciano Lima   2752.053980.2014  Ajuste no cálculo da quantidade de brindes gerados em todas as campanhas.
      20/02/2015  Leandro Bastos 2121.019996.2015  Tamanho da variável vsmensagem alterado para 32k
      30/04/2015  Leandro Bastos 2550.041206.2015  inserir corretamente o campo restricaotransp na tabela pcpedc
  */

  type t_itempedbrinde is record(
    numpedrca          pcpedc.numpedrca%type,
    codprod            pcpedi.codprod%type,
    qt                 pcpedi.qt%type,
    codfilialretira    pcpedi.codfilialretira%type,
    codigocampanha     pcpromc.codigo%type,
    qtlimitebrinde     pcpromc.qtlimitebrinde%type,
    numcampanha        number,
    descricao          pcprodut.descricao%type,
    usadebcredrcabrind pcpromc.usadebcredrcabrind%type,
    grpregrabrinde     pcpedi.grpregrabrinde%type,
    codauxiliar        pcpedi.codauxiliar%type,
    numseq             pcpedi.numseq%type,
    qtunit             pcpedi.qtunitemb%type);

  type t_campanha is record(
    codigocampanha     pcpromc.codigo%type,
    numcampanha        number,
    produtoprinc       pcpromc.produtoprinc%type,
    tipocampanha       pcpromc.tipocampanha%type,
    codfornec          pcpromc.codfornec%type,
    codprod            pcpromc.codprod%type,
    grupocampanha      pcpromc.grupocampanha%type,
    qttotvenda         pcpromc.qttotvenda%type,
    vltotvenda         pcpromc.vltotvenda%type,
    multiplo           pcpromc.multiplo%type,
    qtbrinde           pcpromc.qtbrinde%type,
    variosbrinde       pcpromc.variosbrinde%type,
    obrigavendamix     pcpromc.obrigavendamix%type,
    vltotvendamax      pcpromc.vltotvendamax%type,
    qtlimitebrinde     pcpromc.qtlimitebrinde%type,
    restricaovalormin  pcpromc.restricaovalormin%type,
    restricaoqtmin     pcpromc.restricaoqtmin%type,
    usadebcredrcabrind pcpromc.usadebcredrcabrind%type);

  type t_precosetributacao is record(
    aliqicms1                pctribut.aliqicms1%type,
    aliqicms2                pctribut.aliqicms2%type,
    codicmtab                pctribut.codicmtab%type,
    codst                    pctabpr.codst%type,
    custocont                pcest.custocont%type,
    custofin                 pcest.custofin%type,
    custoreal                pcest.custoreal%type,
    custorep                 pcest.custorep%type,
    custoultent              pcest.custoultent%type,
    excluido                 pctabpr.excluido%type,
    iva                      pctribut.iva%type,
    pauta                    pctribut.pauta%type,
    peracrescismopf          pctribut.peracrescismopf%type,
    perdescautor             pctabpr.perdescautor%type,
    perdesccusto             pctribut.perdesccusto%type,
    perdescmax               pctabpr.perdescmax%type,
    perdescmaxesp            pctabpr.perdescmaxesp%type,
    perdesctab               pctribut.perdestab%type,
    precominimovenda         pctabpr.precominimovenda%type,
    pvenda                   pctabpr.pvenda%type,
    pvenda1                  pctabpr.pvenda1%type,
    pvenda2                  pctabpr.pvenda2%type,
    pvenda3                  pctabpr.pvenda3%type,
    pvenda4                  pctabpr.pvenda4%type,
    pvenda5                  pctabpr.pvenda5%type,
    pvenda6                  pctabpr.pvenda6%type,
    pvenda7                  pctabpr.pvenda7%type,
    qtdescautor              pctabpr.qtdescautor%type,
    aplicaacrescpjisenta     pctribut.aplicaacrescpjisenta%type,
    percbaseredst            pctribut.percbaseredst%type,
    tipocalculognre          pctribut.tipocalculognre%type,
    ivafonte                 pctribut.ivafonte%type,
    aliqicms1fonte           pctribut.aliqicms1fonte%type,
    aliqicms2fonte           pctribut.aliqicms2fonte%type,
    percbaseredstfonte       pctribut.percbaseredstfonte%type,
    percbasered              pctribut.percbasered%type,
    perbaserednrpa           pctribut.perbaserednrpa%type,
    percbaseredconsumidor    pctribut.percbaseredconsumidor%type,
    utilizapercbaseredpf     pctribut.utilizapercbaseredpf%type,
    valorultent              pcest.valorultent%type,
    usavalorultentbasest     pctribut.usavalorultentbasest%type,
    usavalorultentbasest2    pctribut.usavalorultentbasest2%type,
    codicmtabpf              pctribut.codicmtabpf%type,
    perdescsuframa           pctribut.perdescsuframa%type,
    perdescicmisencao        pctribut.perdescicmisencao%type,
    descontafrete            pctabpr.descontafrete%type,
    percdescpis              pctribut.percdescpis%type,
    percdesccofins           pctribut.percdesccofins%type,
    perdescrepasse           pctribut.perdescrepasse%type,
    precomaxconsum           pctabpr.precomaxconsum%type,
    qtunit                   pcembalagem.qtunit%type,
    fatorpreco               pcembalagem.fatorpreco%TYPE,
    qtminimaatacado          pcembalagem.qtminimaatacado%TYPE,
    pvendaatac               pcembalagem.pvendaatac%TYPE,
    pvendaemb                pcembalagem.pvenda%TYPE,
    poferta                  pcembalagem.poferta%TYPE,
    pvendaatac1              pctabpr.pvendaatac1%TYPE,
    pvendaatac2              pctabpr.pvendaatac2%TYPE,
    pvendaatac3              pctabpr.pvendaatac3%TYPE,
    pvendaatac4              pctabpr.pvendaatac4%TYPE,
    pvendaatac5              pctabpr.pvendaatac5%TYPE,
    pvendaatac6              pctabpr.pvendaatac6%TYPE,
    pvendaatac7              pctabpr.pvendaatac7%TYPE,
    dtofertaini              pcembalagem.dtofertaini%TYPE,
    dtofertafim              pcembalagem.dtofertafim%TYPE,
    dtofertaatacini          pcembalagem.dtofertaatacini%TYPE,
    dtofertaatacfim          pcembalagem.dtofertaatacfim%TYPE,
    pofertaatac              pcembalagem.pofertaatac%TYPE,
    mostrarpvendasemst       pctribut.mostrarpvendasemst%type,
    usapmcbasest             pctribut.usapmcbasest%type,
    custonfsemst             pcest.custonfsemst%type,
    percredpvendasimplesnac  pctribut.percredpvendasimplesnac%type,
    vlstultent               pcest.vlstultent%type,
    percdifaliquotas         pctribut.percdifaliquotas%type,
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
    usavlultentmediobasest   pctribut.usavlultentmediobasest%type,
    vlultentmes              pctabpr.vlultentmes%type,
    CODICMTABBONIF           pctribut.codicmtabbonif%type ,
    codicmtabpfbonif         pctribut.codicmtabpfbonif%type,
    pagtonomedocliente       pctribut.pagtonomedocliente%type,
    vlst                     pctabpr.vlst%type);

  type t_pedido is record(
    numped            pcpedc.numped%type,
    numpedrca         pcpedc.numpedrca%type,
    codfilial         pcpedc.codfilial%type,
    codusur           pcpedc.codusur%type,
    codcli            pcpedc.codcli%type,
    posicao           pcpedc.posicao%type,
    percvenda         pcpedc.percvenda%type,
    codfilialnf       pcpedc.codfilialnf%type,
    numregiao         pcpedc.numregiao%type,
    codplpag          pcpedc.codplpag%type,
    localdesembaraco  pcpedc.localdesembaraco%type,
    ufdesembaraco     pcpedc.ufdesembaraco%type,
    origemped         pcpedc.origemped%type,
    numpedcli         pcpedc.numpedcli%type,
    dtentrega         pcpedc.dtentrega%type,
    dtaberturapedpalm pcpedc.dtaberturapedpalm%type,
    condvenda         pcpedc.condvenda%type,
    posicaoini        pcpedc.posicao%type,
    fretedespacho     pcpedc.fretedespacho%type,
    codfornecfrete    pcpedc.codfornecfrete%type,
    data              pcpedc.data%type,
    numcar            pcpedc.numcar%type,
    descintermediador pcpedc.descintermediador%type,
    cnpjintermediador pcpedc.cnpjintermediador%type,
    codendentcli      pcpedc.codendentcli%type,
    usadebcredrca     pcpedc.usadebcredrca%type,
    brinde            pcpedc.brinde%type,
    bonificaltdebcredrca pcpedc.bonificaltdebcredrca%type,
    trocaaltdebcredrca   pcpedc.trocaaltdebcredrca%type,  
    broker               pcpedc.broker%type,              
    brokeraltdebcredrca  pcpedc.brokeraltdebcredrca%type,
    crmaltdebcredrca     pcpedc.crmaltdebcredrca%type);

  type t_rca is record(
    codsupervisor pcusuari.codsupervisor%type,
    coddistrib    pcusuari.coddistrib%type,
    tipovend      pcusuari.tipovend%type,
    percent       pcusuari.percent%type,
    percent2      pcusuari.percent2%type);

  type t_cliente is record(
    codatv1                 pcclient.codatv1%type,
    calculast               pcclient.calculast%type,
    ieent                   pcclient.ieent%type,
    tipofj                  pcclient.tipofj%type,
    estent                  pcclient.estent%type,
    isentoipi               pcclient.isentoipi%type,
    suframa                 pcclient.sulframa%type,
    contribuinte            pcclient.contribuinte%type,
    utilizaiesimplificada   pcclient.utilizaiesimplificada%type,
    consumidorfinal         pcclient.consumidorfinal%type,
    clientefontest          pcclient.clientefontest%type,
    isentoicms              pcclient.isentoicms%type,
    tipoempresa             pcclient.tipoempresa%type,
    usaivafontediferenciado pcclient.usaivafontediferenciado%type,
    ivafonte                pcclient.ivafonte%type,
    tipodescisencao         pcclient.tipodescisencao%type,
    perdescisentoicms       pcclient.perdescisentoicms%type,
    codpraca                pcclient.codpraca%type,
    classevenda             pcclient.classevenda%type,
    orgaopub                pcclient.orgaopub%type,
    orgaopubfederal         pcclient.orgaopubfederal%type,
    isencaosuframa          pcclient.isencaosuframa%type,
    percomcli               pcclient.percomcli%type,
    codcliprinc             pcclient.codcliprinc%type,
    codfilialnf             pcclient.codfilialnf%type,
    USADESCONTOICMS         pcclient.usadescontoicms%type,
    aceitavendafracao       pcclient.aceitavendafracao%type,
    usadebcredrca           pcclient.Usadebcredrca%type);

  type t_filial is record(
    origemcustofilialretira  pcfilial.origemcustofilialretira%type,
    uf                       pcfilial.uf%type,
    calcularipivenda         pcfilial.calcularipivenda%type,
    aceitavendasemestfv      varchar2(1),
    utilizavendaporembalagem varchar2(1),
    precoporembalagem        varchar2(1),
    tipoprecificacao         varchar2(3),
    broker                   pcfilial.broker%type,
    considerarcomissaozero   pcfilial.considerarcomissaozero%type,
    tipoavaliacaocomissao    pcfilial.tipoavaliacaocomissao%type,
    naousarautdebcredpoldesc varchar2(2),
    verificaestoquecont      varchar2(2),
    con_verificaestoquecont  varchar2(2),
    DEDUZIRPISCOFINSICMSDOCMV varchar2(1));

  type t_planodepagamento is record(
    codplpag  pcplpag.codplpag%type,
    numpr     pcplpag.numpr%type,
    numdias   pcplpag.numdias%type,
    prazo1    pcplpag.prazo1%type,
    prazo2    pcplpag.prazo2%type,
    prazo3    pcplpag.prazo3%type,
    prazo4    pcplpag.prazo4%type,
    prazo5    pcplpag.prazo5%type,
    prazo6    pcplpag.prazo6%type,
    prazo7    pcplpag.prazo7%type,
    prazo8    pcplpag.prazo8%type,
    prazo9    pcplpag.prazo9%type,
    prazo10   pcplpag.prazo10%type,
    prazo11   pcplpag.prazo11%type,
    prazo12   pcplpag.prazo12%type,
    tipovenda pcplpag.tipovenda%type,
    pertxfim  pcplpag.pertxfim%type);

  type t_itenscesta is record(
    numped                 pcpedi.numped%type,
    codprodcesta           pcpedicesta.codprod%type,
    codprodmp              pcpedicesta.codprodmp%type,
    pvenda                 pcpedicesta.pvenda%type,
    ptabela                pcpedicesta.ptabela%type,
    qt                     pcpedicesta.qtmp%type,
    iva                    pctribut.iva%type,
    pauta                  pctribut.pauta%type,
    aliqicms1              pctribut.aliqicms1%type,
    aliqicms2              pctribut.aliqicms2%type,
    vlcustofin             pcpedi.vlcustofin%type,
    vlcustoreal            pcpedi.vlcustoreal%type,
    st                     pcpedicesta.st%type,
    ivafonte               pctribut.ivafonte%type,
    aliqicms1fonte         pctribut.aliqicms1fonte%type,
    aliqicms2fonte         pctribut.aliqicms2fonte%type,
    percbaseredst          pctribut.percbaseredst%type,
    percbasered            pctribut.percbasered%type,
    usavalorultentbasest   pctribut.usavalorultentbasest%type,
    usavalorultentbasest2  pctribut.usavalorultentbasest2%type,
    valorultent            pcest.valorultent%type,
    perbaserednrpa         pctribut.perbaserednrpa%type,
    baseicst               pcpedi.baseicst%type,
    percbaseredconsumidor  pctribut.percbaseredconsumidor%type,
    utilizapercbaseredpf   pctribut.utilizapercbaseredpf%type,
    PERCBASEREDSTFONTE     pctribut.percbaseredstfonte%type,
    codst                  pctribut.codst%type,
    perdesccusto           pctribut.perdesccusto%type,
    custocont              pcest.custocont%type,
    custorep               pcest.custorep%type,
    codicmtab              pctribut.codicmtab%type,
    pcomint1               pcprodut.pcomint1%type,
    pcomext1               pcprodut.pcomext1%type,
    pcomrep1               pcprodut.pcomrep1%type,
    codlinhaprod           pcprodut.codlinhaprod%type,
    codsec                 pcprodut.codsec%type,
    codepto                pcprodut.codepto%type,
    percom                 pcpedicesta.percom%type,
    codicmtabpf            pctribut.codicmtabpf%type,
    freteespecial          pcprodut.freteespecial%type,
    custofinest            pcpedicesta.custofinest%type,
    perfretecmv            pcpedicesta.perfretecmv%type,
    txvenda                pcpedicesta.txvenda%type,
    vldesccustocmv         pcpedicesta.vldesccustocmv%type,
    mostrarpvendasemst     pctribut.mostrarpvendasemst%type,
    usapmcbasest           pctribut.usapmcbasest%type,
    precomaxconsum         pcprodut.precomaxconsum%type,
    custonfsemst           pcest.custonfsemst%type,
    codauxiliar            pcpedicesta.codauxiliar%type,
    tipocomissao           pcprodut.tipocomissao%type,
    classe                 pcprodut.classe%type,
    tipocalculognre        pctribut.tipocalculognre%type,
    stclientegnre          pcpedicesta.stclientegnre%type,
    importado              pcprodut.importado%type,
    agregaripicalculost    pctribut.agregaripicalculost%type,
    usavlultentmediobasest pctribut.usavlultentmediobasest%type,
    vlultentmes            pctabpr.vlultentmes%type

    );

  type t_regiao is record(
    perfreteterceiros pcregiao.perfreteterceiros%type,
    perfreteespecial  pcregiao.perfreteespecial%type);

  type t_produto is record(
    codsec             pcprodut.codsec%type,
    codepto            pcprodut.codepto%type,
    percipivenda       pcprodut.percipivenda%type,
    percipivendatab    pcprodut.percipivendatab%type,
    vlpautaipivenda    pcprodut.vlpautaipivenda%type,
    vlpautaipivendatab pcprodut.vlpautaipivendatab%type,
    vlipiporkgvenda    pcprodut.vlipiporkgvenda%type,
    vlipiporkgvendatab pcprodut.vlipiporkgvendatab%type,
    pesobruto          pcprodut.pesobruto%type,
    precomaxconsum     pcprodut.precomaxconsum%type,
    volume             pcprodut.volume%type,
    codfornec          pcprodut.codfornec%type,
    classe             pcprodut.classe%type,
    importado          pcprodut.importado%type,
    tipomerc           pcprodut.tipomerc%type,
    qtunit             pcprodut.qtunit%type,
    codprodprinc       pcprodut.codprodprinc%type);

  TYPE T_PRECOSIMPOSTOS IS RECORD(
    codprod                  pcpedi.codprod%TYPE,
    numseq                   pcpedi.numseq%TYPE,
    pvenda                   pcpedi.pvenda%TYPE,
    pvenda_semimpostos       pcpedi.pvenda%TYPE,
    basest_pvenda            pcpedi.baseicst%TYPE,
    vlst_pvenda              pcpedi.st%TYPE,
    vlstfonte_pvenda         pcpedi.st%TYPE,
    vlipi_pvenda             pcpedi.vlipi%TYPE,
    vlredsimplesnac_pvenda   pcpedi.VLREDPVENDASIMPLESNA%TYPE,
    ptabela                  pcpedi.PTABELA%TYPE,
    ptabela_semimpostos      pcpedi.PTABELA%TYPE,
    basest_ptabela           pcpedi.baseicst%TYPE,
    vlst_ptabela             pcpedi.st%TYPE,
    vlstfonte_ptabela        pcpedi.st%TYPE,
    vlipi_ptabela            pcpedi.vlipi%TYPE,
    vlredsimplesnac_ptabela  pcpedi.VLREDPVENDASIMPLESNA%TYPE,
    pbaserca                 pcpedi.PBASERCA%TYPE,
    pbaserca_semimpostos     pcpedi.PBASERCA%TYPE,
    basest_pbaserca          pcpedi.baseicst%TYPE,
    vlst_pbaserca            pcpedi.st%TYPE,
    vlstfonte_pbaserca       pcpedi.st%TYPE,
    vlipi_pbaserca           pcpedi.vlipi%TYPE,
    vlredsimplesnac_pbaserca pcpedi.VLREDPVENDASIMPLESNA%TYPE,
    VLFECP                   pcpedi.VLFECP%type,
    BASEFECP                 pcpedi.vlbasefcpst%type,
    ALIQFECP                 pcpedi.aliqicmsfecp%type,
    percipi                  pcpedi.percipi%type,
    pauta                    pcpedi.pauta%type);

  type tb_itempedbrinde is table of t_itempedbrinde index by binary_integer;

  type tb_campanha is table of t_campanha index by binary_integer;

  TYPE tb_itenscesta IS TABLE OF t_itenscesta INDEX BY BINARY_INTEGER;

  procedure proc_apurarcampanha(p_numped          in pcpedc.numped%type,
                                p_codfilialretira in pcpedc.codfilial%type, --utilizado quando o força envia no pedido original a filial que deve retirar o estoque dos itens
                                p_cgccli          in pcclient.cgcent%type, --obrigatorio apenas para pedidos do força de vendas
                                p_numseq          in number,
                                p_integradora     in varchar2,
                                p_mensagem        out varchar2,
                                p_geroubrinde     out varchar2);

  gregitempedbrinde     t_itempedbrinde;
  gvet_regitempedbrinde tb_itempedbrinde;

  gregcampanha       t_campanha;
  gvet_regcampanha   tb_campanha;
  gvet_regitenscesta tb_itenscesta;

  gregpcconsum pcconsum%rowtype; -- parametros do sistema

end; -- Apurarcampanhasbrindes
