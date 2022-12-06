create or replace package IMPORTARCADASTROS is

 /*
    Package de Importação de Cadastros com Sistemas de Forca de Vendas

    ----------------     Historico     ----------------
    Data        Responsável    Tarefa     Comentario
    17/07/2012  Andréa         164694     Primeira Versao - (alteracoes iniciais)
    24/07/2012  Andréa         168256     Validar parâmetros : UTILIZAROTEIRIZACAO e ATUALIZAROTANOMOMENTOVENDA utilizado para o processo de roteirização, primeiro para a filial '99', 
                                           caso não encontre verificar para a filial do rca para visitas                                            
    06/09/2012  Andrea         171931     Incluir gravação de campos na pcgondolac e pcgondolai.   
    20/09/2012  Andréa         174865     Incluir parâmetros codusur (para todos os registros que tenha codusur na tabela) e 
                                           numpedrca ( apenas para os pedidos de venda normal) para disparar a package
    05/10/2012  Andréa         175044     Gravar campos : condvenda10,condvenda11,condvenda13,condvenda14,condvenda20,condvenda4,condvenda7,condvenda8  e condvenda9 na pcclient
    18/06/2013  Andréa         192086     Incluir validacao do parametro bloqcliautfv para gravar o novo cliente bloqueado ou não    
    01/07/2013  Andréa         203771     Caso seja enviado codauxiliar e não exista na pcembalagem, validar na pcprodut.    
    23/07/2013  Andréa         205669     Gravar campo pcrecfunc.dtab com data e horario  
    20/08/2013  Andréa         207042     Incluir gravação/atualização de pcrotacli e opção de reorganizar rotas.   
    30/08/2013  Andréa         209199     Corrigir alteração de cadastro de cliente para não colocar o campo email maiusculo       
    05/09/2013  Andréa         209913     Acrescentar importação do campo simples nacional   
    05/09/2013  Andréa         209911     Validar campos email e emailnfe.    
    27/09/2013  Andréa         212283     Corrigir validação de email
    07/10/2013  Andréa         213017     Retirar a obrigatoriedade do campo email  
    28/10/2013  Andréa         1436.001079.2013  Alterar função de validação de email para não rejeitar cadastro com menos de 5 caracteres antes do @           
    12/11/2013  Andréa         213879            Incluir importação de código de pais com as validações pertinentes e corrigir gravação de observação gerencial 2, quando esta está sendo alterada.     
    16/01/2014  Andréa         HIS.00059.2014    Gravar campos codfuncalter e dtultalter da pcclient quando o cadastro do cliente for alterado    
    06/02/2014  Andréa         3625.013865.2014  Permitir atualizar o codigo de atividade do cadasto do cliente
    26/03/2014  Unilson        HIS.01262.2014    Atualizar os campos HORACADASTRO e DTCADASTRO com data e hora, conforme versão 22 da rotina 302    
*/

  type t_cliente is record(
    tipooperacao               varchar2(1),
    cgcent                     pcclient.cgcent%type,
    cliente                    pcclient.cliente%type,
    fantasia                   pcclient.fantasia%type,
    ieent                      pcclient.ieent%type,
    iment                      pcclient.iment%type,
    rg                         pcclient.rg%type,
    orgaorg                    pcclient.orgaorg%type,
    codclipalm                 pcclient.codclipalm%type,
    codatv1                    pcclient.codatv1%type,
    enderent                   pcclient.enderent%type,
    numeroent                  pcclient.numeroent%type,
    complementoent             pcclient.complementoent%type,
    bairroent                  pcclient.bairroent%type,
    telent                     pcclient.telent%type,
    municent                   pcclient.municent%type,
    estent                     pcclient.estent%type,
    cepent                     pcclient.cepent%type,
    paisent                    pcclient.paisent%type,
    pontorefer                 pcclient.pontorefer%type,
    endercob                   pcclient.endercob%type,
    numerocob                  pcclient.numerocob%type,
    complementocob             pcclient.complementocob%type,
    bairrocob                  pcclient.bairrocob%type,
    telcob                     pcclient.telcob%type,
    municcob                   pcclient.municcob%type,
    estcob                     pcclient.estcob%type,
    cepcob                     pcclient.cepcob%type,
    endercom                   pcclient.endercom%type,
    numerocom                  pcclient.numerocom%type,
    complementocom             pcclient.complementocom%type,
    bairrocom                  pcclient.bairrocom%type,
    telcom                     pcclient.telcom%type,
    municcom                   pcclient.municcom%type,
    estcom                     pcclient.estcom%type,
    cepcom                     pcclient.cepcom%type,
    faxcom                     pcclient.faxcom%type,
    codusur1                   pcclient.codusur1%type,
    codusur2                   pcclient.codusur2%type,
    faxcli                     pcclient.faxcli%type,
    codpraca                   pcclient.codpraca%type,
    predioproprio              pcclient.predioproprio%type,
    obs                        pcclient.obs%type,
    obs2                       pcclient.obs2%type,
    obs3                       pcclient.obs3%type,
    obs4                       pcclient.obs4%type,
    obs5                       pcclient.obs5%type,
    obscredito                 pcclient.obscredito%type,
    telent1                    pcclient.telent1%type,
    email                      pcclient.email%type,
    caixapostal                pcclient.caixapostal%type,
    obsentrega1                pcclient.obsentrega1%type,
    obsentrega2                pcclient.obsentrega2%type,
    obsentrega3                pcclient.obsentrega3%type,
    obsentrega4                pcclient.obsentrega4%type,
    numbanco1                  pcclient.numbanco1%type,
    numagencia1                pcclient.numagencia1%type,
    numccorrente1              pcclient.numccorrente1%type,
    numbanco2                  pcclient.numbanco2%type,
    numagencia2                pcclient.numagencia2%type,
    numccorrente2              pcclient.numccorrente2%type,
    qtcheckout                 pcclient.qtcheckout%type,
    site                       pcclient.site%type,
    obsgerencial1              pcclient.obsgerencial1%type,
    obsgerencial2              pcclient.obsgerencial2%type,
    obsgerencial3              pcclient.obsgerencial3%type,
    latitude                   pcclient.latitude%type,
    longitude                  pcclient.longitude%type,
    datacoleta                 pcclient.datacoleta%type,
    codcli                     pcclient.codcli%type,
    tipofj                     pcclient.tipofj%type,
    numregiaocli               pcclient.numregiaocli%type,
    codcob                     pcclient.codcob%type,
    codplpag                   pcclient.codplpag%type,
    emailnfe                   pcclient.emailnfe%type,
    codcidadeibge              pccidade.codibge%type,
    codcidade                  pcclient.codcidade%type,
    codfilialnf                pcclient.codfilialnf%type,
    consumidorfinal            pcclient.consumidorfinal%type,
    contribuinte               pcclient.contribuinte%type,
    clientprotesto             pcclient.clientprotesto%type,
    envionfeemailcom           pcclient.envionfeemailcom%type,
    bloqueio                   pcclient.bloqueio%type,
    diasemana                  pcclientfv.diasemana%type,
    numsemana                  pcclientfv.numsemana%type,
    sequencia                  pcclientfv.sequencia%type,
    periodicidade              pcclientfv.periodicidade%type,
    simplesnacional            pcclientfv.simplesnacional%type,
    codpais                    pcclient.codpais%type,
    valido                     boolean,
    fretedespacho              pcclientfv.fretedespacho%type,
    chave                      varchar2(50),
    telcelent                  pcclientfv.telcelent%TYPE, --HIS.03111.2017
    calculast                  pcclientfv.calculast%type,
    clientefontest             pcclientfv.clientefontest%type,
    dtinclusao                 pcclientfv.dtinclusao%type,
    importado                  pcclientfv.importado%type,
    dtnasc                     pcclientfv.dtnasc%type,
	cgcentrega                 pcclientfv.cgcentrega%type
    );


  type t_contato is record(
    cgccli                     pcclient.cgcent%type,
    codcli                     pccontato.codcli%type,
    codcontato                 pccontato.codcontato%type,
    nomecontato                pccontato.nomecontato%type,
    tipocontato                pccontato.tipocontato%type,
    cgccpf                     pccontato.cgccpf%type,
    dtnascimento               pccontato.dtnascimento%type,
    hobbie                     pccontato.hobbie%type,
    time                       pccontato.time%type,
    nomeconjuge                pccontato.nomeconjuge%type,
    dtnascconjuge              pccontato.dtnascconjuge%type,
    endereco                   pccontato.endereco%type,
    bairro                     pccontato.bairro%type,
    cidade                     pccontato.cidade%type,
    cep                        pccontato.cep%type,
    cargo                      pccontato.cargo%type,
    telefone                   pccontato.telefone%type,
    celular                    pccontato.celular%type,
    email                      pccontato.email%type,
    estado                     pccontato.estado%type,
    valido                     boolean  );
    
type t_mens is record(
    codfuncab                  pcrecfunc.codfuncab%type,
    dtab                       pcrecfunc.dtab%type,
    codsetororig               pcrecfunc.codsetororig%type,
    codsetordest               pcrecfunc.codsetordest%type,
    codfuncdest                pcrecfunc.codfuncdest%type,
    assunto                    pcrecfunc.assunto%type,
    comunicado                 pcrecfunc.comunicado%type,
    numrecado                  pcrecfunc.numrecado%type,
    numrecadofv                pcrecfunc.numrecadofv%type,
    textorecado                pcrecfunc.textorecado%type,
    codusur                    pcrecfunc.codusur%type,
    valido                     boolean);

type t_gondolac is record(
    numcontagem                pcgondolac.numcontagem%type,
    dtcontagem                 pcgondolac.dtcontagem%type,
    codusur                    pcgondolac.codusur%type,
    cgccli                     pcclient.cgcent%type,
    codcli                     pcgondolac.codcli%type,
    codconc                    pcgondolac.codconc%type,
    horainicial                pcgondolac.horainicial%type,
    horafinal                  pcgondolac.horafinal%type,
    numvisita                  pcgondolac.numvisita%type,
    valido                     boolean);


  type t_gondolai is record(
    numcontagem                pcgondolai.numcontagem%type,
    codprod                    pcgondolai.codprod%type,
    qt                         pcgondolai.qt%type,
    pvenda                     pcgondolai.pvenda%type,
    codusur                    pcgondolai.codusur%type,
    codcli                     pcgondolai.codcli%type,
    cgccli                     pcclient.cgcent%type,
    qtperdas                   pcgondolai.qtperdas%type,
    girosellout                pcgondolai.girosellout%type,
    giromedio                  pcgondolai.giromedio%type,
   valido                     boolean);

  type t_visita is record(
    codvisita                  pcvisita.codvisita%type,
    codcli                     pcvisita.codcli%type,
    cgccli                     pcclient.cgcent%type,
    DATA                       pcvisita.DATA%type,
    codmotivo                  pcvisita.codmotivo%type,
    codoperadora               pcvisita.codoperadora%type,
    assunto                    pcvisita.assunto%type,
    hrinicial                  pcvisita.hrinicial%type,
    hrfinal                    pcvisita.hrfinal%type,
    minutoinicial              pcvisita.minutoinicial%type,
    minutofinal                pcvisita.minutofinal%type,
    codusur                    pcvisita.codusur%type,
    codrota                    pcvisitafv.codrota%type,
    valido                     boolean);


type t_cotacao is record(
    codcotacao                 pccota.codcotacao%type,
    codprod                    pccota.codprod%type,
    numseq                     number,
    codconc                    pccota.codconc%type,
    codcli                     pccota.codcli%type,
    cgccli                     pcclient.cgcent%type,
    punit                      pccota.punit%type,
    DATA                       pccota.DATA%type,
    codusur                    pccota.codusur%type,
    numregiao                  pccota.numregiao%type,
    codfilial                  pccota.codfilial%type,
    ptabela                    pccota.ptabela%type,
    codplpag                   pccota.codplpag%type,
    prazo                      pccota.prazo%type,
    custofin                   pccota.custofin%type,
    custoreal                  pccota.custoreal%type,
    datadoc                    pccota.datadoc%type,
    precocon1                  pccota.precocon1%type,
    precocon2                  pccota.precocon2%type,
    precocon3                  pccota.precocon3%type,
    precocon4                  pccota.precocon4%type,
    precocon5                  pccota.precocon5%type,
    obs                        pccota.obs%type,
    estoque                    pccota.estoque%type,
    codauxiliar                pccota.codauxiliar%type,
    lista                      pccota.lista%type,
    percmaxdescmercado         pccota.percmaxdescmercado%type,
    obs2                       pccota.obs2%type,
    codprodconc                pccota.codprodconc%type,
    valido                     boolean);

 type t_cliref is record(

    cgccli                      pcclireffv.cgccli%type,
    codref                      pcclireffv.codref%type,
    codcli                      pcclireffv.codcli%type,
    emprefer                    pcclireffv.emprefer%type,
    telrefer                    pcclireffv.telrefer%type,
    contatorefer                pcclireffv.contatorefer%type,
    limcredrefer                pcclireffv.limcredrefer%type,
    dtcadastrorefer             pcclireffv.dtcadastrorefer%type,
    dtultcomprefer              pcclireffv.dtultcomprefer%type,
    vlultcomprefer              pcclireffv.vlultcomprefer%type,
    obs                         pccliref.obs%type,
    dtmaiorcomprefer            pcclireffv.dtmaiorcomprefer%type,
    vlmaiorcomprefer            pcclireffv.vlmaiorcomprefer%type,
    codcobrefer                 pcclireffv.codcobrefer%type,
    valido                      boolean);


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
    
    
    

  type tb_registralog is table of t_registralog index by binary_integer;

  type tb_cli is table of t_cliente index by binary_integer;

  type tb_contato is table of t_contato index by binary_integer;

  type tb_visita is table of t_visita index by binary_integer;
  
  type tb_mens is table of t_mens index by binary_integer;

  type tb_gondolac is table of t_gondolac index by binary_integer;

  type tb_gondolai is table of t_gondolai index by binary_integer;

  type tb_cotacao is table of t_cotacao index by binary_integer;

  type tb_cliref is table of t_cliref index by binary_integer;


PROCEDURE importar(p_tipoleitura IN NUMBER DEFAULT 1,
                   p_datainicial IN DATE DEFAULT TRUNC(SYSDATE),
                   p_datafinal   IN DATE DEFAULT TRUNC(SYSDATE),
                   p_tiporeg     IN NUMBER default null,
                   p_codusur     IN NUMBER default null) ;


  gregpcconsum pcconsum%rowtype; -- parametros do sistema
  vngcontador  integer default 0;


  gvetregistralog         tb_registralog;

  gregcli                 t_cliente;
  gvet_regcli             tb_cli;

  gregcontato             t_contato;
  gvet_regcontato         tb_contato;
  
  gregmens                t_mens;
  gvet_regmens            tb_mens;

  greggondolac            t_gondolac;
  gvet_reggondolac        tb_gondolac;

  greggondolai            t_gondolai;
  gvet_reggondolai        tb_gondolai;

  gregvisita              t_visita;
  gvet_regvisita          tb_visita;

  gregcotacao             t_cotacao;
  gvet_regcotacao         tb_cotacao;

  gregcliref               t_cliref;
  gvet_regcliref           tb_cliref;

  vngtipoleitura          number(2);
  vngdatainicio           date;
  vngdatafim              date;
  vngtiporeg              number(2);

end; --IMPORTARCADASTROS
