CREATE OR REPLACE PACKAGE VENDAS IS

-- HISTÓRICO DE MODIFICAÇÕES
-- Nome                Data        Comentários
-- --------------      ----------  ------------------------------------------
-- LUCIANO LIMA        24/09/2013  CRIAÇÃO DA PKG
-- Rafael Braga        14/03/2014  Comentando recurso da função ESTOQUE_CB para obrigar o uso do parâmetro de código do produto e filial, melhorando a performance.
-- Rafael Braga        05/06/2014  4579.059634.2014: ajuste para caso o produto tenha 0 no campo CODPRODACAB da PCFORMPROD, considerar 1, pois caso esteja 0, o estoque disponível é apresentado 0. Esse campo nunca é gravado diferente de 1 quando cadastramos uma cesta, mas ao alterá-la, grava 0.
-- Leandro/Masrcos     30/01/2015  1106.129682.2014: Ajuste da procedure CALCULARGIRODIA para commitar as alterações após cada update em vez de uma única vez ao fim do processamento como era feito anteriormente.
-- Marcoa              12/03/2015  2311.024136.2015: Alterado o select para verificar se há desconto por quantidade vigente e apresentar na grid como era antes.
-- Leandro Bastos      14/08/2015  959.090426.2015:  Criação Procedura MONTAR_CB (Pendete verificar estoque através da ESTOQUE_CB)
-- Guilherme Freitas   11/09/2015  1486.101952.2015 : Ajustado para quando encontrar um política de desconto prioritária, ao buscar a política para o PBASERCA, irá buscar entre as prioritárias
-- Rafael Soares       01/10/2015  HIS.02657.2015: Criado a procedure VLLIMITECNAE (Retorna o limite de venda para o CNAE do cliente)
-- Rafael Braga        15/08/2016  4648.088849.2016: Caso seja acréscimo, não alterar novamente o PTABELADESC pois isso faz o pbaserca ficar incorreto
-- Rafael Braga		   10/01/2016  VEN-2139: Unificando PKG_PRODUTO com VENDAS.
-- --------------      ----------  ------------------------------------------

  MSG   VARCHAR2(200) DEFAULT '';
  vproxnumtrans integer;
  vPROXNUMVALE integer;
  vRecnumVale integer;
  vHora varchar2(2);
  vMinuto varchar2(2);
  vTIPOPARCEIRO varchar2(2);
  vVlSaldo number;
  vRecNumLanc integer;
  vCODPARCEIRO INTEGER;
  vCODBANCO INTEGER;
  vCODCONTA INTEGER;
  vCodFornec integer;
  vNOMEPARCEIRO VARCHAR2(200);

  MSG_ERRO EXCEPTION;

  TYPE T_CLI IS RECORD
  (CODCLI   NUMBER,
   CLIENTE  VARCHAR2(60));

  TYPE T_RCA IS RECORD
  (CODRCA   NUMBER,
   NOME     VARCHAR2(60));

  type t_composicaopreco is record(
       codfilial           PCPRODFILIAL.CODFILIAL%type,
       tipoestoqueminimo   PCPRODFILIAL.TIPOESTOQUEMINIMO%type,
       tipoestoquemaximo   PCPRODFILIAL.TIPOESTOQUEMAXIMO%type,
       participagiro       PCMOVCOMPLE.PARTICIPAGIRO%type,
       codprod             PCMOV.CODPROD%type,
       diasestoquemin      PCRECOMPOSICAOESTOQUE.DIASESTOQUEMIN%type,
       diasestoquemax      PCRECOMPOSICAOESTOQUE.DIASESTOQUEMAX%type);


  TYPE T_ESTOQUE IS RECORD
  (CODFILIAL     VARCHAR2(2),
   CODPROD       NUMBER,
   QTEST         NUMBER,
   QTESTGER      NUMBER,
   QTDISP        NUMBER,
   QTDISP_CONT   NUMBER);

  TYPE TB_ESTOQUE IS TABLE OF T_ESTOQUE;

  TYPE TB_CLIENTES IS TABLE OF T_CLI;

  TYPE TB_RCAS IS TABLE OF T_RCA;

  TYPE T_ESTOQUE_DIVERGENTE IS RECORD (
    CODFILIAL      VARCHAR2(2),
    CODPROD        NUMBER,
    MOVIMENTA      VARCHAR2(1),
    NUMTRANSVENDA  NUMBER(10),
    NUMTRANSENT    NUMBER(10)
  );

  TYPE TB_ESTOQUE_DIVERGENTE IS TABLE OF T_ESTOQUE_DIVERGENTE;

  TYPE T_RAMO_ATIVIDADE IS RECORD(
    PercRedAliqIpi PCATIVI.PERCREDALIQIPI%TYPE,
    CalculaSt      PCATIVI.CALCULAST%TYPE
    );

  TYPE T_ENDERECO_ENTREGA IS RECORD(
    CODENDENT PCCLIENTENDENT.CODENDENTCLI%TYPE,
    NUMREGIAO PCCLIENTENDENT.NUMREGIAO%TYPE,
    ESTENT    PCCLIENTENDENT.ESTENT%TYPE);

  TYPE T_CLIENTE IS RECORD(
      CodCli                  PCCLIENT.CODCLI%TYPE,
      CodcliPrinc             PCCLIENT.CODCLIPRINC%TYPE,
      ClasseVenda             PCCLIENT.CLASSEVENDA%TYPE,
      TipoPessoa              PCCLIENT.TIPOFJ%TYPE,
      CodRede                 PCCLIENT.CODREDE%TYPE,
      CodAtiv1                PCCLIENT.CODATV1%TYPE,
      SimplesNacional         PCCLIENT.SIMPLESNACIONAL%TYPE,
      NumRegiao               PCCLIENT.NUMREGIAOCLI%TYPE,
      EstEnt                  PCCLIENT.estent%TYPE,
      CalculaSt               PCCLIENT.calculast%TYPE,
      CalculaStFonte          PCCLIENT.Clientefontest%TYPE,
      UsaivaFonteDiferenciado PCCLIENT.Usaivafontediferenciado%TYPE,
      IvaFonte                PCCLIENT.Ivafonte%TYPE,
      IEEnt                   PCCLIENT.ieent%TYPE,
      Utilizaiesimplificada   PCCLIENT.utilizaiesimplificada%TYPE,
      Isentoipi               PCCLIENT.isentoipi%TYPE,
      Isentoicms              PCCLIENT.Isentoicms%TYPE,
      Sulframa                PCCLIENT.sulframa%TYPE,
      IsencaoSuframa          PCCLIENT.ISENCAOSUFRAMA%TYPE,
      Contribuinte            PCCLIENT.contribuinte%TYPE,
      ConsumidorFinal         PCCLIENT.consumidorfinal%TYPE,
      UtilizaCalculoSTMT      PCCLIENT.UTILIZACALCULOSTMT%TYPE,
      TipoEmpresa             PCCLIENT.TIPOEMPRESA%TYPE,
      TipoDescIsencao         PCCLIENT.TIPODESCISENCAO%TYPE,
      PerDescIsentoICMS       PCCLIENT.PERDESCISENTOICMS%TYPE,
      OrgaoPub                PCCLIENT.ORGAOPUB%TYPE,
      OrgaoPubFederal         PCCLIENT.ORGAOPUBFEDERAL%TYPE,
      UsaDescontoICMS         PCCLIENT.USADESCONTOICMS%TYPE,
      PessoaFisicaJuridica    VARCHAR2(60),
      CodCnae                 PCCLIENT.CODCNAE%TYPE,
      CodPraca                PCCLIENT.CodPraca%TYPE,
      OrigemPreco             PCCLIENT.Origempreco%TYPE,
      ValidarMultiploVenda    PCCLIENT.VALIDARMULTIPLOVENDA%TYPE,
      Perdescativ             PCATIVI.PERCDESC%TYPE,
      RegiaoZFM               PCREGIAO.REGIAOZFM%TYPE,
      Repasse                 PCCLIENT.REPASSE%TYPE,
      Tv10usacustoproduto     PCCLIENT.TV10USACUSTOPRODUTO%TYPE,
      TipoCustoTransf         PCCLIENT.Tipocustotransf%TYPE,
      PerAcrescTransf         PCCLIENT.Peracrestransf%TYPE,
      RamoAtividade           T_RAMO_ATIVIDADE,
      CodFilialNf             PCCLIENT.codfilialnf%TYPE,
      TIPOCUSTOMANIF          PCCLIENT.TIPOCUSTOMANIF%TYPE);

  type T_PRODUTO IS RECORD(
       CodProd         PCPRODUT.CODPROD%TYPE,
       Descricao       PCPRODUT.DESCRICAO%TYPE,
       CodProdPrinc    PCPRODUT.CODPRODPRINC%TYPE,
       CodCategoria    PCPRODUT.CODCATEGORIA%TYPE,
       CodSubCategoria PCPRODUT.CODSUBCATEGORIA%TYPE,
       CodFornec       PCPRODUT.CODFORNEC%TYPE,
       CodMarca        PCPRODUT.CODMARCA%TYPE,
       CodSec          PCPRODUT.CODSEC%TYPE,
       CoDepto         PCPRODUT.CoDepto%TYPE,
       Classe          PCPRODUT.CLASSE%TYPE
       );

  type T_PLANO_PAGAMENTO IS RECORD(
    CodPlPag  PCPLPAG.CODPLPAG%TYPE,
    PERTXFIM  PCPLPAG.PERTXFIM%TYPE,
    Descricao PCPLPAG.DESCRICAO%TYPE,
    NumPR     PCPLPAG.NUMPR%TYPE,
    NumDias   PCPLPAG.NUMDIAS%TYPE);

  type T_PRECIFICACAO IS RECORD(
       PrecoTabela         PCTABPR.PTABELA%TYPE,
       PrecoTabelaAVista   PCTABPR.PTABELA%TYPE);

  type T_PARAMETROS_132 IS RECORD(
    TratarRestricaoAcrescimo    PCCONSUM.TRATARRESTRICAOACRESCIMO%TYPE,
    NumCasasDecimais            PCCONSUM.NUMCASASDECVENDA%TYPE,
    UsaTributacaoPorUF          pcconsum.usatributacaoporuf%TYPE,
    UtilizaVendaPorEmbalagem    pcconsum.Utilizavendaporembalagem%TYPE,
    PrecoPorEmbalagem           pcconsum.precoporembalagem%TYPE,
    TipoAliqoutrasdesp          pcconsum.tipoaliqoutrasdesp%TYPE,
    AliqIcmoutrasdesp           pcconsum.aliqicmoutrasdesp%TYPE,
    AliqIcminteroutrasdesp      pcconsum.Aliqicminteroutrasdesp%TYPE,
    CalcSTpf                    pcconsum.calcstpf%TYPE,
    ConsideraIsentoscomopf      pcconsum.consideraisentoscomopf%TYPE,
    TxVenda                     pcconsum.txvenda%TYPE,
    Tipocalcst                  pcconsum.tipocalcst%TYPE,
    PercicmFrete                pcconsum.percicmfrete%TYPE,
    PercIcminterfrete           pcconsum.percicminterfrete%TYPE,
    MostrarPvendasemst          pcconsum.mostrarpvendasemst%TYPE,
    TipoPrecificacao            VARCHAR2(5),
    UtilizaPCUSURFORNEC         VARCHAR2(5),
    ValidaRestricoesVendaPorRCA VARCHAR2(5),
    CalcularIPIVenda            VARCHAR2(5),
    CalcularSTComIPI            VARCHAR2(5),
    AceitaPFContribuinte        VARCHAR2(5),
    UtilizaPercBaseredPF        VARCHAR2(5),
    UsaDescSimplesNac           VARCHAR2(5),
    PercAcrescimoTelemarketing  Number,
    PercAcrescimoBalcao         Number,
    UsaDescPorLinhaProd         VARCHAR2(5),
    ValidaPvendaBonific         VARCHAR2(5),
    UtilizaPercFinPrecoProm     VARCHAR2(5),
    ValidarPrecoVendaTV20       VARCHAR2(5),
    UsarTribTransfVenda10       VARCHAR2(5),
    RetiraIPIPedidoTV8          varchar2(5),
    AceitaDescPrecoFixo         varchar2(5),
    ACRESCIMOPFCOMIE            varchar2(5),
    UtilizaControleMedicamentos VARCHAR2(5),
    ValidarPrecoVendaTV8        VARCHAR2(1),
    AcrescePartilhaPreco        varchar2(1),
	  AceitaDescontoPrecoFixo     PCCONSUM.ACEITADESCPRECOFIXO%TYPE);

  type T_PEDIDO IS RECORD(
       SomenteDescAut VARCHAR2(1),
       QtdeItem PCPEDI.QT%TYPE,
       PercDescInformado PCPEDI.PERDESC%TYPE,
       OrigemPed PCPEDC.ORIGEMPED%TYPE,
       TipoCarga PCPEDC.TIPOCARGA%TYPE,
       CodFilial PCPEDC.CODFILIAL%TYPE,
       Visualizando VARCHAR2(1), -- para saber se o item está visualizando ou incluíndo
       DataPedido PCPEDC.DATA%TYPE,
       PVenda PCPEDI.Pvenda%TYPE);

  type T_RCAS IS RECORD(
    CodUsur                    PCUSUARI.CODUSUR%TYPE,
    Nome                       PCUSUARI.NOME%TYPE,
    AreaAtuacao                PCUSUARI.AREAATUACAO%TYPE,
    CodSupervisor              PCUSUARI.CODSUPERVISOR%TYPE,
    ValidarAcrescDescPrecoFixo PCUSUARI.VALIDARACRESCDESCPRECOFIXO%TYPE);

  type T_FUNCIONARIO IS RECORD(
    Matricula          PCEMPR.MATRICULA%TYPE
    );


  type T_DESCONTO IS RECORD(
       Cliente         T_CLIENTE,
       Produto         T_PRODUTO,
       PlanoPagamento  T_PLANO_PAGAMENTO,
       Precificacao    T_PRECIFICACAO,
       Pedido          T_PEDIDO,
       RCA             T_RCAS,
       Parametros132   T_PARAMETROS_132,
       Funcionario     T_FUNCIONARIO);

  Desconto T_DESCONTO;

  TYPE T_CAMPANHA_COMBO IS RECORD (
    CODIGO PCDESCONTOC.CODIGO%TYPE
  );

  TYPE TB_CAMPANHA_COMBO IS TABLE OF T_CAMPANHA_COMBO;

  PROCEDURE prc_desdobrar_ped_tv8(pnumped_tv7 IN NUMBER,
                                  pncodfunc   IN NUMBER,
                                  pmsg        OUT VARCHAR2);

  PROCEDURE buscardadoscliente(pcodcli                  IN pcclient.codcli%TYPE,
                               vncodigopraca            IN OUT pcclient.codpraca%TYPE,
                               vnprazoadicional         IN OUT pcclient.prazoadicional%TYPE,
                               vnperdescfin             IN OUT pcclient.perdescfin%TYPE,
                               vnperdescisentoicms      IN OUT pcclient.perdescisentoicms%TYPE,
                               vsisentotxboleto         IN OUT pcclient.isentotxboleto%TYPE,
                               vddtvencprazoadicional   IN OUT pcclient.dtvencprazoadicional%TYPE,
                               vsusacreclifat           IN OUT pcclient.usacreclifat%TYPE,
                               vsatualizasaldoccdescfin IN OUT pcclient.atualizasaldoccdescfin%TYPE,
                               psgeratitulost           IN OUT pcclient.geratitulost%TYPE,
                               piprazovencst            IN OUT pcclient.prazovencst%TYPE,
                               psagregarvalorstdescfin  IN OUT pcclient.agregarvalorstdescfin%TYPE,
                               pstipotratamentodescfin  IN OUT pcclient.tipotratamentodescfin%TYPE,
                               pnqtddiasaplicdescfin    IN OUT pcclient.qtddiasaplicdescfin%TYPE,
                               vnvlminimost             IN OUT pcclient.vlminimost%TYPE,
                               psutilizapedclinfe       IN OUT pcclient.utilizapedclinfe%TYPE,
                               pssulframa               IN OUT pcclient.sulframa%TYPE,
                               psusadescontoicms        IN OUT pcclient.usadescontoicms%TYPE,
                               pncodcidade              IN OUT pcclient.codcidade%TYPE,
                               pmensagem                IN OUT VARCHAR);

  PROCEDURE buscardadosclientenf(pcodcli                   IN pcclient.codcli%TYPE,
                                 pnumped                   IN pcpedc.numped%TYPE,
                                 vc2uf_cliente             IN OUT pcclient.estent%TYPE,
                                 vc2tipopessoa             IN OUT pcclient.tipofj%TYPE,
                                 vc2codigosuframa          IN OUT pcclient.sulframa%TYPE,
                                 vc2isentoicms             IN OUT pcclient.isentoicms%TYPE,
                                 vc2codigocacex            IN OUT pcclient.cacex%TYPE,
                                 vsieent                   IN OUT pcclient.ieent%TYPE,
                                 vscalculast               IN OUT pcclient.calculast%TYPE,
                                 vsclientefontest          IN OUT pcclient.clientefontest%TYPE,
                                 vsutilizaiesimplificada   IN OUT pcclient.utilizaiesimplificada%TYPE,
                                 vsconsumidorfinal         IN OUT pcclient.consumidorfinal%TYPE,
                                 vstipoempresa             IN OUT pcclient.tipoempresa%TYPE,
                                 vsorgaopub                IN OUT pcclient.orgaopub%TYPE,
                                 vscontribuinte            IN OUT pcclient.contribuinte%TYPE,
                                 vsusaivafontediferenciado IN OUT pcclient.usaivafontediferenciado%TYPE,
                                 vnivafonte                IN OUT pcclient.ivafonte%TYPE,
                                 vsorgaopubfederal         IN OUT pcclient.orgaopubfederal%TYPE,
                                 vsparticipafuncep         IN OUT pcclient.participafuncep%TYPE,
                                 vnnumregiao               IN OUT pcpraca.numregiao%TYPE,
                                 pncodcidade               IN OUT pcclient.codcidade%TYPE,
                                 psorgaopubmunicipal       IN OUT pcclient.orgaopubmunicipal%TYPE,
                                 pmensagem                 IN OUT VARCHAR);

  PROCEDURE buscartributacao(pcodprod                       IN NUMBER,
                             pnumregiao                     IN NUMBER,
                             pcodfilialnf                   IN VARCHAR2,
                             pufcliente                     IN VARCHAR2,
                             pusatributacaoporuf            IN pcconsum.usatributacaoporuf%TYPE,
                             pnumnotaconsig                 IN pcpedc.numnotaconsig%TYPE,
                             vncodicmtab                    IN OUT pctribut.codicmtab%TYPE,
                             vssittribut                    IN OUT VARCHAR,
                             vssittributpf                  IN OUT VARCHAR,
                             vncodicm                       IN OUT pctribut.codicm%TYPE,
                             vnpercbasered                  IN OUT pctribut.percbasered%TYPE,
                             vnpercbaseredst                IN OUT pctribut.percbaseredst%TYPE,
                             vnpercbaseredstfonte           IN OUT pctribut.percbaseredstfonte%TYPE,
                             vnpercbaseredconsumidor        IN OUT pctribut.percbaseredconsumidor%TYPE,
                             vnperbaserednrpa               IN OUT pctribut.perbaserednrpa%TYPE,
                             vsutilizapercbaseredpf_trib    IN OUT pctribut.utilizapercbaseredpf%TYPE,
                             vnpauta                        IN OUT pctribut.pauta%TYPE,
                             vniva                          IN OUT pctribut.iva%TYPE,
                             vnivafonte                     IN OUT pctribut.ivafonte%TYPE,
                             vscalcbcicmsnf                 IN OUT pctribut.calcbcicmsnf%TYPE,
                             vncfoest                       IN OUT pctribut.codfiscal%TYPE,
                             vncfointer                     IN OUT pctribut.codfiscalinter%TYPE,
                             vncfoestpf                     IN OUT pctribut.codfiscalpf%TYPE,
                             vncfointerpf                   IN OUT pctribut.codfiscalinterpf%TYPE,
                             vncfobonific                   IN OUT pctribut.codfiscalbonific%TYPE,
                             vncfobonificinter              IN OUT pctribut.codfiscalbonificinter%TYPE,
                             vncfotransf                    IN OUT pctribut.codfiscaltransf%TYPE,
                             vncfotransfinter               IN OUT pctribut.codfiscaltransfinter%TYPE,
                             vncfointernasc                 IN OUT pctribut.codfiscalinternasc%TYPE,
                             vncfointernascpf               IN OUT pctribut.codfiscalinternascpf%TYPE,
                             vncfodevcliinternasc           IN OUT pctribut.codfiscaldevcliinternasc%TYPE,
                             vncfotransfinternasc           IN OUT pctribut.codfiscaltransfinternasc%TYPE,
                             vncfobonificinternasc          IN OUT pctribut.codfiscalbonificinternasc%TYPE,
                             vncfodevcliboninternasc        IN OUT pctribut.codfiscaldevcliboninternasc%TYPE,
                             vncfodevcliproentinternasc     IN OUT pctribut.codfiscaldevcliproentinternasc%TYPE,
                             vncfoprontaentinternasc        IN OUT pctribut.codfiscalprontaentinternasc%TYPE,
                             vncodst                        IN OUT pctribut.codst%TYPE,
                             vncodicmpf                     IN OUT pctribut.codicmpf%TYPE,
                             vncfoprontaent                 IN OUT pctribut.codfiscalprontaent%TYPE,
                             vncfoprontaentinter            IN OUT pctribut.codfiscalprontaentinter%TYPE,
                             vncfovendaconsig               IN OUT pctribut.codfiscalvendaconsig%TYPE,
                             vncfovendaconsiginter          IN OUT pctribut.codfiscalvendaconsiginter%TYPE,
                             vncfovendaconsiginternasc      IN OUT pctribut.codfiscalvendaconsiginternasc%TYPE,
                             vncfovendaentfut               IN OUT pctribut.codfiscalvendaentfut%TYPE,
                             vncfovendaentfutinter          IN OUT pctribut.codfiscalvendaentfutinter%TYPE,
                             vncfosimpentfut                IN OUT pctribut.codfiscalsimpentfut%TYPE,
                             vncfosimpentfutinter           IN OUT pctribut.codfiscalsimpentfutinter%TYPE,
                             vncfomercadoriaconsig          IN OUT pctribut.codfiscalmercconsig%TYPE,
                             vncfomercadoriaconsiginter     IN OUT pctribut.codfiscalmercconsiginter%TYPE,
                             vncfomercadoriaconsiginternasc IN OUT pctribut.codfiscalmercconsiginternasc%TYPE,
                             vncfovendaprontaent            IN OUT pctribut.codfiscalvendaprontaent%TYPE,
                             vncfovendaprontaentinter       IN OUT pctribut.codfiscalprontaentinter%TYPE,
                             vnpercacrescbasepfest          IN OUT pctribut.percacrescbasepfest%TYPE,
                             vstipocalculognre              IN OUT pctribut.tipocalculognre%TYPE,
                             vncodfiscalisentost            IN OUT pctribut.codfiscalisentost%TYPE,
                             vncodfiscalisentostinter       IN OUT pctribut.codfiscalisentostinter%TYPE,
                             vncodfiscalisentostinternasc   IN OUT pctribut.codfiscalisentostinternasc%TYPE,
                             vssittributisentost            IN OUT pctribut.sittributisentost%TYPE,
                             vncodfiscaltroca               IN OUT pctribut.codfiscaltroca%TYPE,
                             vncodfiscaltrocainter          IN OUT pctribut.codfiscaltrocainter%TYPE,
                             vncodfiscaltrocainternasc      IN OUT pctribut.codfiscaltrocainternasc%TYPE,
                             vnaliqstsaida                  IN OUT pctribut.aliqstsaida%TYPE,
                             vnaliqstsaidapf                IN OUT pctribut.aliqstsaidapf%TYPE,
                             vssittributnrpa                IN OUT pctribut.sittributnrpa%TYPE,
                             vnpercivamex                   IN OUT pctribut.percivamex%TYPE,
                             vnaliqicms1transf              IN OUT pctribut.aliqicms1transf%TYPE,
                             vnaliqicms2transf              IN OUT pctribut.aliqicms2transf%TYPE,
                             vnivatransf                    IN OUT pctribut.ivatransf%TYPE,
                             vnpautatransf                  IN OUT pctribut.pautatransf%TYPE,
                             vnpercbaseredsttransf          IN OUT pctribut.percbaseredsttransf%TYPE,
                             vncodicmtransf                 IN OUT pctribut.codicmtransf%TYPE,
                             vssittributtransf              IN OUT pctribut.sittributtransf%TYPE,
                             vncodicmprodrural              IN OUT pctribut.codicmprodrural%TYPE,
                             vnperpautaicms                 IN OUT pctribut.perpautaicms%TYPE,
                             vnperpautaicmsinter            IN OUT pctribut.perpautaicmsinter%TYPE,
                             vnpercbaseredadicional         IN OUT pctribut.percbaseredadicional%TYPE,
                             vnpercbaseredadicionalinter    IN OUT pctribut.percbaseredadicionalinter%TYPE,
                             vsdescicmsreduzbaseicms        IN OUT pctribut.descicmsreduzbaseicms%TYPE,
                             vnaliqicms1fonte               IN OUT pctribut.aliqicms1fonte%TYPE,
                             vnaliqicms2fonte               IN OUT pctribut.aliqicms2fonte%TYPE,
                             vsusacfopbnfparabrinde         IN OUT pctribut.usacfopbnfparabrinde%TYPE,
                             vscalcularicmssittribut060     IN OUT pctribut.calcularicmssittribut060%TYPE,
                             vscodfiscaltv9                 IN OUT pctribut.codfiscaltv9%TYPE,
                             vscodfiscalintertv9            IN OUT pctribut.codfiscalintertv9%TYPE,
                             vscodfiscalinternasctv9        IN OUT pctribut.codfiscalinternasctv9%TYPE,
                             vnperacrescimocusto            IN OUT pctribut.peracrescimocusto%TYPE,
                             vnperacrescimofuncep           IN OUT pctribut.peracrescimofuncep%TYPE,
                             vnpercbaseredtranfsaid         IN OUT pctribut.percbaseredtranfsaid%TYPE,
                             vncodfiscalconsig              IN OUT pctribut.codfiscalconsig%TYPE,
                             vncodfiscalconsiginter         IN OUT pctribut.codfiscalconsiginter%TYPE,
                             vncodfiscalconsiginternac      IN OUT pctribut.codfiscalconsiginternac%TYPE,
                             vnpercacrescbasepfint          IN OUT pctribut.percacrescbasepfint%TYPE,
                             vspagtonomedoremetente         IN OUT pctribut.pagtonomedoremetente%TYPE,
                             vncodfiscaltriangular          IN OUT pctribut.codfiscaltriangular%TYPE,
                             vncodfiscaltriangularinter     IN OUT pctribut.codfiscaltriangularinter%TYPE,
                             vncodfiscaltriangularinternasc IN OUT pctribut.codfiscaltriangularinternasc%TYPE,
                             vncfoptriangularpf             IN OUT pctribut.codfiscaltriangularpf%TYPE,
                             vncfoptriangularinterpf        IN OUT pctribut.codfiscaltriangularinterpf%TYPE,
                             vncfoptriangularinternascpf    IN OUT pctribut.codfiscaltriangularinternascpf%TYPE,
                             vnperdifereimentoicms          IN OUT pctribut.perdifereimentoicms%TYPE,
                             vncfopcontaordem               IN OUT pctribut.codfiscalcontaordem%TYPE,
                             vncfopcontaordeminter          IN OUT pctribut.codfiscalcontaordeminter%TYPE,
                             vncfopcontaordemsimpent        IN OUT pctribut.codfiscalcontaordemsimpent%TYPE,
                             vncfopcontaordemsimpentinte    IN OUT pctribut.codfiscalcontaordemsimpentinte%TYPE,
                             vszerarbaseicmsorgpubsuframa   IN OUT pctribut.zerarbaseicmsorgpubsuframa%TYPE,
                             --Tarefa 126672
                             vspagtonomedesttransf         IN OUT pctribut.pagtonomedesttransf%TYPE,
                             vspagtonomeremettransf        IN OUT pctribut.pagtonomeremettransf%TYPE,
                             vstipocalculognretransf       IN OUT pctribut.tipocalculognretransf%TYPE,
                             vspagtonomedocliente          IN OUT pctribut.pagtonomedocliente%TYPE,
                             psreduzbaseicmdecretomaranhao IN OUT pctribut.reduzbaseicmdecretomaranhao%TYPE,
                             pssittributtv7                IN OUT pctribut.sittributtv7%TYPE,
                             --Tarefa 134475
                             psutilizaparcadicfecp IN OUT pctribut.utilizaparcadicfecp%TYPE,
                             --Tarefa 141140
                             pnaliqicmsfecp IN OUT pctribut.aliqicmsfecp%TYPE,
                             --Tarefa 141140
                             psisentaicmsbonific     IN OUT pctribut.isentaicmsbonific%TYPE,
                             pssittributbonific      IN OUT pctribut.sittributbonific%TYPE,
                             pssittributtv8          IN OUT pctribut.sittributtv8%TYPE,
                             pncodfiscalsuframa      IN OUT pctribut.codfiscalsuframa%TYPE,
                             pssittributsuframa      IN OUT pctribut.sittributsuframa%TYPE,
                             pncodfiscalsuframainter IN OUT pctribut.codfiscalsuframainter%TYPE,
                             psusaisencaoicmsvp      IN OUT pctribut.usaisencaoicmsvp%TYPE,
                             pdaliqicmstv9           IN OUT pctribut.aliqicmstv9%TYPE,
                             paplicaredicmssemipiba  IN OUT pctribut.aplicaredicmssemipiba%TYPE, --Tarefa: 168659
                             psittributpautaicms     IN OUT pctribut.sittributpautaicms%TYPE,
                             pvlpautaicmsinterest    IN OUT pctribut.vlpautaicmsinterest%TYPE,
                             psittributpautaicmspf   IN OUT pctribut.sittributpautaicmspf%TYPE, --Tarefa: 181175
                             vncodicmsimplesnac      IN OUT pctribut.CODICMSIMPLESNAC%TYPE, --tarefa 192644
                             vnperbaseredsimplesnac  IN OUT pctribut.PERBASEREDSIMPLESNAC%type, --tarefa 192644
                             vnperctributos          IN OUT pctribut.perctributos%type,
                             vncodprodgnre           IN OUT pctribut.codprodgnre%TYPE,
                             pssittributorgaopub     IN OUT PCTRIBUT.SITTRIBUTORGAOPUB%TYPE,
                             psusavlultentmediobasest IN OUT PCTRIBUT.USAVLULTENTMEDIOBASEST%TYPE,
                             pnvlultentmes           IN OUT PCTABPR.vlultentmes%TYPE,
                             vssittribsimplesnac     IN OUT PCTRIBUT.SITTRIBUTSIMPLESNAC%TYPE,--HIS.00875.2013
                             pmensagem               IN OUT VARCHAR,
                             ppessoafisica           IN OUT BOOLEAN,
                             pnpercacresicmspf_pi    IN OUT NUMBER,
                             --HIS.04000.2014
                             pssittribstfontepf      IN OUT VARCHAR,
                             pssittribstfontepj      IN OUT VARCHAR,
                             pncodfiscalstfonteest   IN OUT NUMBER,
                             pncodfiscalstfonteinterest IN OUT NUMBER,
                             pncodfiscalstfonteinternac IN OUT NUMBER,
                             -- HIS.02114.2015
                             pncodfiscalsimplesnacest      IN OUT NUMBER,
                             pncodfiscalsimplesnacinterest in OUT NUMBER,
                             ------------------
                             pnperdiferimentoicmstransf   IN OUT NUMBER,
                             --HIS.02571.2015
                             psBNFNAOCALCULAICMS          IN OUT PCTRIBUT.BNFNAOCALCULAICMS%TYPE,
                             psSITTRIBUTBNFTV1            IN OUT PCTRIBUT.SITTRIBUTBNFTV1%TYPE,
                             pngeraricmslivrofiscal       IN OUT PCTRIBUT.Geraricmslivrofiscal%TYPE, --HIS.03545.2015
                             pscodcest                    IN OUT PCTRIBUT.CODCEST%TYPE, --HIS.03419.2015
                             -- HIS.02754.2015
                             psUsaValorultEntbaseICMS      IN OUT PCTRIBUT.USAVALORULTENTBASEICMS%TYPE,
                             psUsaValorultEntbaseICMSTONTE IN OUT PCTRIBUT.USAVALORULTENTBASEICMSFONTE%TYPE,
                             pssittributtv9                IN OUT PCTRIBUT.SITTRIBUTTV9%TYPE,
                             pPERCPISRETORGPUB             IN OUT PCTRIBUT.PERCPISRETORGPUB%TYPE,
                             pPERCCOFINSRETORGPUB          IN OUT PCTRIBUT.PERCCOFINSRETORGPUB%TYPE,
                             pPERCIRPJRETORGPUB            IN OUT PCTRIBUT.PERCIRPJRETORGPUB%TYPE,
                             pPERCCSLLRETORGPUB            IN OUT PCTRIBUT.PERCCSLLRETORGPUB%TYPE,
                             pPERCPISRETORGPUBEST          IN OUT PCTRIBUT.PERCPISRETORGPUB%TYPE,
                             pPERCCOFINSRETORGPUBEST       IN OUT PCTRIBUT.PERCCOFINSRETORGPUB%TYPE,
                             pPERCIRPJRETORGPUBEST         IN OUT PCTRIBUT.PERCIRPJRETORGPUB%TYPE,
                             pPERCCSLLRETORGPUBEST         IN OUT PCTRIBUT.PERCCSLLRETORGPUB%TYPE,
                             pPERCPISRETORGPUBMUN          IN OUT PCTRIBUT.PERCPISRETORGPUB%TYPE,
                             pPERCCOFINSRETORGPUBMUN       IN OUT PCTRIBUT.PERCCOFINSRETORGPUB%TYPE,
                             pPERCIRPJRETORGPUBMUN         IN OUT PCTRIBUT.PERCIRPJRETORGPUB%TYPE,
                             pPERCCSLLRETORGPUBMUN         IN OUT PCTRIBUT.PERCCSLLRETORGPUB%TYPE,
                              --HIS.03465.2015
                             pSITTRIBUTTRIANG               IN OUT PCTRIBUT.SITTRIBUTTRIANG%TYPE,
                             pAPLICAACRESPFJURIDICA         IN OUT PCTRIBUT.APLICAACRESPFJURIDICA%TYPE,
                             pCalculaFECPCLIMEI             IN OUT PCTRIBUT.CALCULAFECPCLIMEI%TYPE,
                             pagregadescst1                 IN OUT PCTRIBUT.agregadescst1%TYPE,
                             pcodfiscalisentostramo         IN OUT PCTRIBUT.codfiscalisentostramo%TYPE,
                             pcodfiscalisentostramointer    IN OUT PCTRIBUT.codfiscalisentostramointer%TYPE,
                             psittributisentostramo         IN OUT PCTRIBUT.sittributisentostramo%TYPE,
                             psVendaTriangular              IN     PCPEDC.VENDATRIANGULAR%TYPE,
                             psCalcBaseicmsMediaEnt         IN OUT PCTRIBUT.CalcBaseicmsMediaEnt%TYPE,
                             psCalcularFECPISENTOie         IN OUT PCTRIBUT.CalcularFECPISENTOie%TYPE,
                             psCalcularFUNCEPISENTOie       IN OUT PCTRIBUT.CalcularFUNCEPISENTOie%TYPE,
                             psMEINAOCALCDIF                IN OUT PCTRIBUT.MEINAOCALCDIF%TYPE,
                             pssittributmei                 IN OUT PCTRIBUT.sittributmei%TYPE,
                             pnCODFISCALISENTOSTCONT        IN OUT PCTRIBUT.CODFISCALISENTOSTCONT%TYPE,
                             pnCODFISCALISENTOSTCONTINTER   IN OUT PCTRIBUT.CODFISCALISENTOSTCONTINTER%TYPE,
                             pnCODFISCALISENSTCONTINTERNASC IN OUT PCTRIBUT.CODFISCALISENTOSTCONTINTERNASC%TYPE,
                             pnCODFISCALCONSUFINAL          IN OUT PCTRIBUT.CODFISCALCONSUFINAL%TYPE,
                             pnCODFISCALCONSUFINALINTER     IN OUT PCTRIBUT.CODFISCALCONSUFINALINTER%TYPE,
                             pnCODFISCALCONSUFINALINTERNASC IN OUT PCTRIBUT.CODFISCALCONSUFINALINTERNASC%TYPE,
                             psAplicaMVABaseIcms            IN OUT PCTRIBUT.APLICAMVABASEICMS%TYPE,
                             psUTILIZAMOTORCALCULO          IN OUT PCTRIBUT.UTILIZAMOTORCALCULO%TYPE,
							 psNAOPERSISTEIVAPCMOV			IN OUT PCTRIBUT.NAOPERSISTEIVAPCMOV%TYPE,
                             psisentaicmssittribut041       IN OUT pctribut.isentaicmssittribut041%TYPE);

  PROCEDURE buscardadospcprodut(pncodprod                      IN pcprodut.codprod%TYPE,
                                pscodfilialnf                  IN pcpedc.codfilialnf%TYPE,
                                pssulframa_client              IN pcclient.sulframa%TYPE,
                                vncodepto                      IN OUT pcprodut.codepto%TYPE,
                                vncodsec                       IN OUT pcprodut.codsec%TYPE,
                                vc2descricao                   IN OUT pcprodut.descricao%TYPE,
                                vc2classe                      IN OUT pcprodut.classe%TYPE,
                                vnpesobruto                    IN OUT pcprodut.pesobruto%TYPE,
                                vnpesoliq                      IN OUT pcprodut.pesoliq%TYPE,
                                vnvolume                       IN OUT pcprodut.volume%TYPE,
                                vncodfornecedor                IN OUT pcprodut.codfornec%TYPE,
                                vnperpis                       IN OUT pcprodut.perpis%TYPE,
                                vstipomerc_prod                IN OUT pcprodut.tipomerc%TYPE,
                                vscoddistrib_prod              IN OUT pcfornec.coddistrib%TYPE,
                                vsconfaz                       IN OUT pcprodut.confaz%TYPE,
                                vstipoestoque                  IN OUT pcprodut.tipoestoque%TYPE,
                                vnpercofins                    IN OUT pcprodut.percofins%TYPE,
                                vsgeraicmslivrofiscal          IN OUT pcprodfilial.geraicmslivrofiscal%TYPE,
                                vncustofornec                  IN OUT pcprodut.custofornec%TYPE,
                                vscompraconsignado             IN OUT pcprodut.compraconsignado%TYPE,
                                vnpesoembalagem                IN OUT pcprodut.pesoembalagem%TYPE,
                                vnpisretido                    IN OUT pcprodut.pisretido%TYPE,
                                vncofinsretido                 IN OUT pcprodut.cofinsretido%TYPE,
                                vnirretido                     IN OUT pcprodut.irretido%TYPE,
                                vncsllretido                   IN OUT pcprodut.csllretido%TYPE,
                                vsextipi                       IN OUT pcprodut.extipi%TYPE,
                                vnvalorpislitragem_produt      IN OUT pcprodut.valorpislitragem%TYPE,
                                vnvalorcofinslitragem_produt   IN OUT pcprodut.valorcofinslitragem%TYPE,
                                vnbasepiscofinslitragem_produt IN OUT pcprodut.basepiscofinslitragem%TYPE,
                                vsimportado_produt             IN OUT pcprodut.importado%TYPE,
                                picondvenda                    IN OUT pcpedc.condvenda%TYPE,
                                VSCONTROLANUMSERIE             IN OUT pcprodfilial.controlanumserie%TYPE,--211613
                                VSPERCCARGEFETIV               IN OUT pcprodfilial.perccargefetiv%TYPE, --HIS.01889.2015
                                vnPercAcrecimoBaseIPI          IN OUT pcprodfilial.PERACRESBASEIPI%TYPE, --HIS.02641.2017
                                vsembalagem                    IN OUT PCPRODUT.EMBALAGEM%TYPE, --HIS.04349.2015
                                vnDV                           IN OUT PCPRODUT.DV%TYPE,        --HIS.04349.2015
                                psBONIFIC                      IN PCPEDI.BONIFIC%TYPE, --HIS.02571.2015
                                pmensagem                      IN OUT VARCHAR);

  PROCEDURE validarinserircobranca(pscodcob   IN pccob.codcob%TYPE,
                                   psmensagem IN OUT VARCHAR2);

  PROCEDURE CALCULARGIRODIA(DATA1 IN DATE, DATA2 IN DATE, MENSAGEM OUT VARCHAR2, PCODPROD IN NUMBER DEFAULT 0, PFILIAL IN VARCHAR2 DEFAULT '-1', PTIPOCALCULODIAS IN NUMBER);

  PROCEDURE ATUALIZARCUSTOFINANCEIRO(VALOR IN NUMBER);

  FUNCTION retorna_prazomedido_plpagfixo(pcodplpag IN pcplpag.codplpag%TYPE)
    RETURN NUMBER;

  FUNCTION TIPO_TRANSFERENCIA (PFILIALVENDA  VARCHAR2,
                               PFILIALRETIRA VARCHAR2,
                               PFILIALNF     VARCHAR2)
    RETURN VARCHAR2;

  FUNCTION USA_CFAT(PNUMCAR IN NUMBER, PNUMPED IN NUMBER)
    RETURN VARCHAR2;

  PROCEDURE DEFINIR_MOVESTOQUE (PNUMTRANSACAO IN NUMBER,
                                POPERACAO     IN VARCHAR2);

  FUNCTION ORIGEM_TRANSFERENCIA (PNUMTRANSTRANSF IN NUMBER)
    RETURN VARCHAR2;

  FUNCTION CLIENTES_DO_RCA (PCODUSUR IN NUMBER)
    RETURN TB_CLIENTES
    PIPELINED;

  FUNCTION RCAS_DO_CLIENTE (PCODCLI IN NUMBER)
    RETURN TB_RCAS
    PIPELINED;

  FUNCTION ESTOQUE_CB (PCODPROD   		 IN NUMBER   DEFAULT 0,
                       PCODFILIAL 		 IN VARCHAR2 DEFAULT '99',
					   P_CAMPO_CALCULADO IN VARCHAR2 DEFAULT 'N')
    RETURN TB_ESTOQUE
    PIPELINED;

  PROCEDURE MONTAR_CB(PCODPROD   IN NUMBER DEFAULT 0,
                      PCODFILIAL IN VARCHAR2 DEFAULT '99',
                      PQT        IN NUMBER DEFAULT 0,
                      PMSG             IN OUT VARCHAR,
                      PCODFILIALRETIRA IN VARCHAR2 DEFAULT '99',
                      PCODFILIALNF     IN VARCHAR2 DEFAULT '99',
                      PORIGEMPED       IN VARCHAR2 DEFAULT '');


  FUNCTION DESCONTO_CAB_VENDA_SIMUL(pCodCli      NUMBER,
                                    pCodPlPag    NUMBER,
                                    pCodUsur     NUMBER,
                                    pNumPed      NUMBER,
                                    pOrigemPed   VARCHAR2,
                                    pTipoCarga   VARCHAR2,
                                    pCodFilial   VARCHAR2,
                                    pCodFilialNF VARCHAR2,
                                    pDataPedido  DATE
                                                 )
    RETURN TD_DESCONTO_SIMUL
    PIPELINED;

  FUNCTION DESCONTO_ITEM_VENDA(pCODCLI NUMBER,
                               pCODPROD NUMBER,
                               pCODPLPAG NUMBER,
                               pCODUSUR NUMBER,
                               pPERCDESCINFORMADO NUMBER,
                               pPTABELA NUMBER,
                               pPTABELAAVISTA NUMBER,
                               pQTITEM NUMBER,
                               pORIGEMPED VARCHAR2,
                               pTIPOCARGA VARCHAR2,
                               pCODFILIAL VARCHAR2,
                               pDATAPEDIDO DATE,
                               pSomenteDescAut in VARCHAR2 default 'N',
                               pPrecoFixo IN VARCHAR2 DEFAULT 'N',
                               pPVenda NUMBER DEFAULT 0,
                               pDescontoPautado NUMBER DEFAULT 0,
                               pCODFILIALNF varchar2 default '',
                               pTipoDesc varchar2 default '',
                               pCodDesconto number default 0,
                               pCODAUXILIAR PCEMBALAGEM.CODAUXILIAR%TYPE DEFAULT 0,
                               PSOMENTESIMULADOR  VARCHAR2 DEFAULT 'N',
                               pDIFESTOQUEMOVIMENTADO NUMBER DEFAULT 0,
                               pNUMPED                NUMBER DEFAULT 0,
                               pNUMSEQ                NUMBER DEFAULT 0,
                               psTipoOperacao         VARCHAR2 DEFAULT 'I',
                               pnNumeroOrcamento      NUMBER DEFAULT 0,
                               psTipoEntrega          VARCHAR2 DEFAULT '',
                               psTipoDesconto         VARCHAR2 DEFAULT '',
                               pnMatriculaFuncionario NUMBER DEFAULT 0,
                               pnCondvenda            PCPEDC.CONDVENDA%TYPE DEFAULT '',
                               psCalculaPrecoRCA      VARCHAR2 DEFAULT 'S')
    RETURN TD_DESCONTO_VENDA
    PIPELINED;

  FUNCTION ESTOQUE_DISPONIVEL (PCODPROD     IN NUMBER,
                               PCODFILIAL   IN VARCHAR2,
                               PUSAGREATEST IN VARCHAR2 DEFAULT 'S')
    RETURN TB_ESTOQUE
    PIPELINED;

  FUNCTION ESTOQUE_DIVERGENTE (PCODFILIAL   IN VARCHAR2,
                               PCODPROD     IN NUMBER
                               )
    RETURN TB_ESTOQUE_DIVERGENTE
    PIPELINED;

  FUNCTION CAMPANHA_COMBO(pDATAPEDIDO     IN DATE,
                          pCodFilial      IN VARCHAR2,
                          pCodRegiao      IN NUMBER,
                          pCodRamo        IN NUMBER,
                          pCodSupervisor  IN NUMBER,
                          pCodRca         IN NUMBER,
                          pCodCli         IN NUMBER,
                          pCodDistrib     IN VARCHAR2,
                          pCodPlPag       IN NUMBER DEFAULT 0
                        )
    RETURN TB_CAMPANHA_COMBO
    PIPELINED;

  FUNCTION VLLIMITECNAE(PNCODCLI  IN NUMBER)
   RETURN NUMBER;

  FUNCTION getORIGEMPEDIDO(pNUMPED IN NUMBER, pbisOrcamento boolean default false) RETURN varchar2;

  FUNCTION VALIDA_VLR_LIM_VENDA_MEI(pnCodCli            in NUMBER,
                                    pnValorPedDigitacao in NUMBER,
                                    pnNumped            in NUMBER default 0) RETURN VARCHAR2;

  TYPE T_DADOS_PRODUTO IS RECORD(
    ---------------------------------
    --campos do preço de tabela
    PTABELA1                   NUMBER,
    PTABELA2                   NUMBER,
    PTABELA3                   NUMBER,
    PTABELA4                   NUMBER,
    PTABELA5                   NUMBER,
    PTABELA6                   NUMBER,
    PTABELA7                   NUMBER,
    PUNIT                      NUMBER,
    PUNIT1                     NUMBER,
    PUNIT2                     NUMBER,
    PUNIT3                     NUMBER,
    PUNIT4                     NUMBER,
    PUNIT5                     NUMBER,
    PUNIT6                     NUMBER,
    PUNIT7                     NUMBER,
    PTABELA_SEMDESCONTOS       NUMBER,
    PTABELA_NUMPR1             NUMBER,
    STCALCULADO                NUMBER,
    DATAFIMPRECOFIXO           DATE,
    PERCOMTABELA               NUMBER,
    BASEST                     NUMBER,
    VLIPI                      NUMBER,
    VALORDIFALIQUOTAS          NUMBER,
    --campos da política de desconto
    ---------------------------------
    vsMSG               VARCHAR2(4000),
    CODESCONTO          NUMBER,
    CODESCONTOBASE      NUMBER,
    POLITICABASECREDITA VARCHAR2(1),
    POLITICABASEDEBITA  VARCHAR2(1),
    PERCDESCBASE        NUMBER,
    DATAFINAL           DATE,
    PERCDESC            NUMBER,
    PERCDESCAUT         NUMBER,
    PTABELADESC         NUMBER,
    PVENDADESC          NUMBER,
    PBASERCA            NUMBER,
    QUESTIONAUSO        VARCHAR2(1),
    ALTERAPTABELA       VARCHAR2(1),
    FORCARUTILIZACAO    VARCHAR2(1),
    PERCDESCMAX         NUMBER,
    DATAINICIO          DATE,
    QTINI               NUMBER,
    QTFIM               NUMBER,
    VLRMINIMO_DESCONTO  NUMBER,
    VLRMAXIMO_DESCONTO  NUMBER,
    ---------------------------------
    CODPROD                   PCPRODUT.CODPROD%TYPE,
    VLST                      PCTABPR.VLST%TYPE,
    CODFORNEC                 PCPRODUT.CODFORNEC%TYPE,
    PERCDIFALIQUOTAS          PCTRIBUT.PERCDIFALIQUOTAS%TYPE,
    PERDESCCUSTOTRANSF        PCTRIBUT.PERDESCCUSTOTRANSF%TYPE,
    MOSTRARPVENDASEMST        PCTRIBUT.MOSTRARPVENDASEMST%TYPE,
    PERDESCFOB                PCTABPR.PERDESCFOB%TYPE,
    PTABELAFABRICAZFM         PCPRODUT.CUSTOREPZFM%TYPE,
    PTABELAFABRICA            PCPRODUT.CUSTOREP%TYPE,
    PVENDA                    PCTABPR.PVENDA%TYPE,
    QTUNIT                    PCPRODUT.QTUNIT%TYPE,
    CODAUXILIAR               PCPRODUT.CODAUXILIAR%TYPE,
    FATORPRECO                NUMBER(18, 6),
    PVENDA1                   PCTABPR.PVENDA1%TYPE,
    PVENDA2                   PCTABPR.PVENDA2%TYPE,
    PVENDA3                   PCTABPR.PVENDA3%TYPE,
    PVENDA4                   PCTABPR.PVENDA4%TYPE,
    PVENDA5                   PCTABPR.PVENDA5%TYPE,
    PVENDA6                   PCTABPR.PVENDA6%TYPE,
    PVENDA7                   PCTABPR.PVENDA7%TYPE,
    PVENDAATAC                NUMBER(18, 6),
    PVENDAATAC1               PCTABPR.PVENDAATAC1%TYPE,
    PVENDAATAC2               PCTABPR.PVENDAATAC2%TYPE,
    PVENDAATAC3               PCTABPR.PVENDAATAC3%TYPE,
    PVENDAATAC4               PCTABPR.PVENDAATAC4%TYPE,
    PVENDAATAC5               PCTABPR.PVENDAATAC5%TYPE,
    PVENDAATAC6               PCTABPR.PVENDAATAC6%TYPE,
    PVENDAATAC7               PCTABPR.PVENDAATAC7%TYPE,
    POFERTA                   NUMBER(18, 6),
    DTOFERTAINI               DATE,
    DTOFERTAFIM               DATE,
    POFERTAATAC               NUMBER(18, 6),
    DTOFERTAATACINI           DATE,
    DTOFERTAATACFIM           DATE,
    QTMULTIPLA                NUMBER(18, 6),
    QTMINIMAATACADO           NUMBER(18, 6),
    CODST                     PCTRIBUT.CODST%TYPE,
    PERCBONIFICVENDA          PCPRODUT.PERCBONIFICVENDA%TYPE,
    PERACRESCISMOPF           PCTRIBUT.PERACRESCISMOPF%TYPE,
    PRECOFIXO                 PCPRODUT.PRECOFIXO%TYPE,
    CODLINHAPROD              PCPRODUT.CODLINHAPROD%TYPE,
    MULTIPLO                  NUMBER(18, 6),
    TIPOMERC                  PCPRODUT.TIPOMERC%TYPE,
    CODPRODPRINC              PCPRODUT.CODPROD%TYPE,
    APLICAACRESCPJISENTA      PCTRIBUT.APLICAACRESCPJISENTA%TYPE,
    CHECARMULTIPLOVENDABNF    PCPRODUT.CHECARMULTIPLOVENDABNF%TYPE,
    PTABELA                   PCTABPR.PTABELA%TYPE,
    PERCREDPVENDASIMPLESNAC   PCTRIBUT.PERCREDPVENDASIMPLESNAC%TYPE,
    PERCDESCSIMPLESNAC        PCTABPR.PERCDESCSIMPLESNAC%TYPE,
    TIPOCUSTOTRANSF           PCPRODUT.TIPOCUSTOTRANSF%TYPE,
    BNFNAOCALCULAICMS         PCTRIBUT.BNFNAOCALCULAICMS%TYPE,
    PERACRESCISMOSIMPNAC      PCTRIBUT.PERACRESCISMOSIMPNAC%TYPE,
    VALOR_DESCONTO_ICMS       NUMBER(18, 6),
    CODIGOPRECOFIXO           NUMBER(10),
    USANDOPOFERTA             varchar2(1),
    PERCENTUAL_REDUCAO_IPI    PCATIVI.PERCREDALIQIPI%TYPE
    );

  TYPE T_CODFISCAL IS RECORD(
    msg       varchar2(400),
    codfiscal number(8),
    sittribut varchar2(3));
  ----------------------------------------------------------
  TYPE T_PRECO_FIXO IS RECORD(
    precoFixo                number(18, 6),
    ConsideraPrecoSemImposto varchar2(1));
  ----------------------------------------------------------
  TYPE T_ACRESCIMOS_PF_SN IS RECORD(
    percAcrescimoPF number(18, 6),
    aplicaAcrescimo boolean);
  ----------------------------------------------------------

  FUNCTION BUSCAR_PRECO_TABELA(  codigoFilial            IN varchar,
                                 CodFilialNF          IN varchar,
                                 CodFilialRetira      IN varchar,
                                 Oferta               IN varchar,
                                 OfertaAtac           IN varchar,
                                 Qtde                 IN number,
                                 Codprod              IN number,
                                 NumRegiao            IN number,
                                 CodUsur              IN number,
                                 AbateFrete           IN varchar,
                                 PerFrete             IN number,
                                 Codcli               IN number,
                                 CodContrato          IN number,
                                 CodPlPag             IN number,
                                 CodCob               IN varchar2,
                                 DescPlanoCustomizado IN number,
                                 CodAuxiliar          IN number,
                                 CondVenda            IN number,
                                 VendaExportacao      IN varchar,
                                 Origemped            IN varchar,
                                 ItemBNFTV1           IN varchar,
                                 TipoDocumento        IN varchar,
                                 CodCombo             IN number,
                                 NumPedTV7            IN number default 0,
                                 VendaTriangular      in varchar2 default 'N',
                                 NumEmpenho           IN number default 0,
                                 PrazoMedio           in number default 0,
                                 CodEnderecoEntrega   in number default 0,
                                 Transferencia        in varchar2 default 'N',
                                 TransferenciaVirtual in varchar2 default 'N')
    RETURN varchar2;

  cMSG_ERR_SEM_PRECO_TABELA CONSTANT varchar2(1000) := 'Produto sem Preço de Tabela!' ||
                                                       CHR(13) ||
                                                       'Favor atualizar a rotina 500 opção: "Package vendas".' ||
                                                       CHR(13) ||
                                                       'Caso a package esteja atualizada, favor seguir uma das duas opções seguintes:' ||
                                                       CHR(13) || CHR(13) ||
                                                       '1. Acessar a rotina 507, recalcular o preço de venda da região e, em seguida, acessar a rotina 552 e atualizar o preço conforme foi recalculado;' ||
                                                       CHR(13) ||
                                                       '2. Acessar a rotina 201, recalcular o preço de venda do produto e, em seguida, aplicar para venda externa.' ||
                                                       CHR(13) || CHR(13) ||
                                                       'Caso o sistema esteja utilizando venda por embalagem verifique a rotina 2017 ou ' ||
                                                       CHR(13) ||
                                                       'verifique no cadastro da embalagem se a mesma está disponível para o tipo de venda selecionado.';

  PROCEDURE APLICAR_VERBACAMPANHA(pNUMPED       IN PCPEDI.NUMPED%TYPE,
                                  pCODPROD      IN PCPEDI.CODPROD%TYPE,
                                  pNUMSEQ       IN PCPEDI.NUMSEQ%TYPE,
                                  pCODFILIAL    IN PCPEDC.CODFILIAL%TYPE DEFAULT NULL);

  PROCEDURE CALCULAR_ICMS_EFETIVO(pNUMTRANSITEM in NUMBER);
  PROCEDURE REPLICAR_ICMS_SUBSTITUTO(pNUMTRANSITEM in NUMBER);
  PROCEDURE PROCURAR_ESTOQUE( psCODFILIAL IN PCPEDC.CODFILIAL%TYPE
                            , pnNUMPED    IN PCPEDI.NUMPED%TYPE
                            , pnCODPROD   IN PCPEDI.CODPROD%TYPE
                            , pnNUMSEQ    IN PCPEDI.NUMSEQ%TYPE);

  FUNCTION CALCULAR_QTVASILHAME_MOTORISTA(pNumcar IN NUMBER,
                                        vsMsg   IN OUT VARCHAR2)  RETURN VARCHAR2;

  PROCEDURE buscarserienf(pscodfilialnf                IN pcpedc.codfilialnf%TYPE,
                          pncondvenda                  IN pcpedc.condvenda%TYPE,
                          pnpercvenda                  IN pcpedc.percvenda%TYPE,
                          psorigemped                  IN pcpedc.origemped%TYPE,
                          psgeranftipo8                IN pcconsum.geranftipo8%TYPE,
                          vc2uf_filial                 IN OUT pcfilial.uf%TYPE,
                          vsnumidf                     IN OUT pcfilial.numidf%TYPE,
                          vncoddocnf                   IN OUT pcfilial.coddocnf%TYPE,
                          vsindustria                  IN OUT pcfilial.industria%TYPE,
                          vnvltarifa                   IN OUT pcfilial.vltarifa%TYPE,
                          vnvlmintarifabanc            IN OUT pcfilial.vlmintarifabanc%TYPE,
                          vnvlmaxtarifabanc            IN OUT pcfilial.vlmaxtarifabanc%TYPE,
                          vssomatarifabancduplic       IN OUT pcfilial.somatarifabancduplic%TYPE,
                          vstipobroker                 IN OUT pcfilial.tipobroker%TYPE,
                          psmsg                        IN OUT VARCHAR2,
                          vc2serie                     IN OUT PCNFSAIDPREFAT.serie%TYPE,
                          vsutipercbaseredoutrasdesppf IN OUT pcfilial.utilizapercbaseredoutrasdesppf%TYPE,
                          vsbloqdesdemitentedif        IN OUT pcfilial.bloqdesdemitentedif%TYPE,
                          vncodcontavendaentregafut    IN OUT pcfilial.codcontavendaentregafut%TYPE,
                          vsusaintegracaowms           IN OUT pcfilial.usaintegracaowms%TYPE);
  
  -- Procedure para INSERIR origem de preço
  PROCEDURE INSERIR_ORIGEM_PRECO (pnROTINA          IN PCPEDI.ROTINALANC%TYPE,
                                  pnNUMPED          IN PCPEDI.NUMPED%TYPE,
                                  pnCODPROD         IN PCPEDI.CODPROD%TYPE,
                                  pnNUMSEQANTIGO    IN PCPEDI.NUMSEQ%TYPE,
                                  pnNUMSEQNOVO      IN PCPEDI.NUMSEQ%TYPE);
                                  
  -- Apagar origem de preço do pedido
  PROCEDURE DELETAR_ORIGEM_PRECO (pnROTINA          IN PCPEDI.ROTINALANC%TYPE,
                                  pnNUMPED          IN PCPEDI.NUMPED%TYPE,
                                  pnCODPROD         IN PCPEDI.CODPROD%TYPE,
                                  pnNUMSEQANTIGO    IN PCPEDI.NUMSEQ%TYPE);
                                  
  -- Procedure para INSERIR PCFILAMAISNEGLOG
  PROCEDURE INSERIR_PCFILAMAISNEGLOG(pnNUMPED       IN PCFILAMAISNEGLOG.NUMPED%TYPE,
                                  psCODFILIAL       IN PCFILAMAISNEGLOG.CODFILIAL%TYPE);						  

  -- Procedure para INSERIR PCFILAMAISNEGENVIO
  PROCEDURE INSERIR_PCFILAMAISNEGENVIO(pnNUMPED     IN PCPEDC.NUMPED%TYPE,
                                  psCODFILIAL       IN PCPEDC.CODFILIAL%TYPE,
                                  psTIPOTRANCACAO   IN PCFILAMAISNEGENVIO.TIPOTRANSACAO%TYPE);                                  

  FUNCTION APROVACAO_MAISNEGOCIOS(pnNUMPED          IN PCPEDC.NUMPED%TYPE,
                                  pnNUMCAR          IN PCPEDC.NUMCAR%TYPE,
                                  psmsg             OUT VARCHAR2) RETURN VARCHAR2;

						  
						  

END;
