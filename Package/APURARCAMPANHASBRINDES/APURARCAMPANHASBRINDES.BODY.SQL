create or replace package body Apurarcampanhasbrindes is

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

*/
function func_buscar_qtde_fv(
      p_numpedrca         in pcpedc.numpedrca%type,
      p_codusur           in pcpedc.codusur%type,
      p_cgccli            in pcclient.cgcent%type,
      p_dtaberturapedpalm in pcpedc.dtaberturapedpalm%type,
      p_codprod           in pcpedi.codprod%type,
      p_gerar_brinde      out boolean) return number is
  vnqtbrindefv number;
  begin
    -- Validar Quantidade de pedido Força de Venda
    p_gerar_brinde := true;
    begin
      SELECT NVL(QT,0)
      INTO vnqtbrindefv
      FROM PCBRINDEFV
      WHERE NUMPEDRCA = p_numpedrca
        AND CODUSUR   = p_codusur
        AND CGCCLI    = p_cgccli
        AND DTABERTURAPEDPALM = p_dtaberturapedpalm
        AND CODPROD   = p_codprod;
      
      if vnqtbrindefv = 0 then
        p_gerar_brinde := false;
      end if;

    exception 
      when no_data_found then
        vnqtbrindefv := 0;
    end;
    
    return vnqtbrindefv;
  end func_buscar_qtde_fv;

procedure proc_pcparamfilial (p_codfilial in pcfilial.codigo%type,
                              p_nome       in pcparamfilial.nome%type,
                              p_padrao     in pcparamfilial.valor%type,
                              p_valor      out pcparamfilial.valor%type) is

  vsnome      pcparamfilial.nome%type;

 begin

   vsnome := upper(trim(p_nome));


      begin
      select nvl(p.valor,p_padrao)
      into p_valor
      from pcparamfilial p
      where upper(trim(p.nome)) = vsnome
      and  p.codfilial = p_codfilial;
      exception

      when no_Data_found then

        BEGIN

          select nvl(p.valor,p_padrao)
          into p_valor
          from pcparamfilial p
          where upper(trim(p.nome)) = vsnome
          and  p.codfilial = '99';
        exception
          when no_data_found then

             p_valor := p_padrao;

        end;

      when others then
       p_valor  := p_padrao;

      end;



 end proc_pcparamfilial ;



/************************************************************************************************************
  ->Nome da FUNCTION  : PROC_VERIFICAFILIALBRINDE
  ->Objetivo          : Centralizar o ponto onde a apuração de brindes define qual a filial de venda e a filial
                        retira da geração do pedido TV5 de brinde
  ->Utilizado por     : APURARCAMPANHASBRINDES

  -------------------------------- Historico ------------------------------------------------------------------
  Data          Responsável       Tarefa           Comentários
  ------------  ---------------   ------           ----------------------------------------------------------------------
  28/08/2015    Rafael Soares     HIS.03512.2015   função criada para definir qual será a filial de venda e a filial retira do brinde
   ------------  ---------------   ---------------------------------------------------------------------------*/
procedure proc_verificafilialbrinde (p_numpedvenda       in pcpedc.numped%type,
                                     p_codfilialvenda    in pcfilial.codigo%type,
                                     p_codprod           in pcparamfilial.nome%type,
                                     p_codfilialretira   in out pcfilial.codigo%type) is

  vscodfilialretira      pcfilial.codigo%type;
  vsfilialretiraigualtv1 varchar2(1);
begin
  --1º filial retira do pedido integrado (PCPEDCFV)
  if p_codfilialretira is not null then
    p_codfilialretira := p_codfilialretira;
  else
    --2º filial retira igual a filial retira do pedido de venda
    proc_pcparamfilial(p_codfilialvenda,
                       'GERABRINDEFILIALRETIRAIGUALTV1',
                       'N',
                       vsfilialretiraigualtv1);
    
    if vsfilialretiraigualtv1 = 'S' then
      begin
        select codfilialretira
        into   vscodfilialretira
        from   pcpedi
        where  numped = p_numpedvenda
        group
        by     codfilialretira;
        
        p_codfilialretira := vscodfilialretira;
      exception
        when others then
          vscodfilialretira := NULL;
      end;
    end if;
    
    if vscodfilialretira is null then
      --3º filial retira igual a filial retira do brinde do cadastro da 238 (PCPRODFILIAL.CODFILIALRETIRABRINDE)
      begin
        select codfilialretira
        into   vscodfilialretira
        from   pcpedi
        where  numped = p_numpedvenda
        group
        by     codfilialretira;
        
        p_codfilialretira := vscodfilialretira;
      exception
        when others then
          vscodfilialretira := NULL;
      end;
      
      if vscodfilialretira is null then
        --4º filial retira igual do cadastro da 203
        select codfilialretira
        into   vscodfilialretira
        from   pcprodut
        where  codprod = p_codprod;
        
        p_codfilialretira := vscodfilialretira;
        
        if vscodfilialretira is null then
          --5º filial retira igual a filial o pedido de venda
          p_codfilialretira := p_codfilialvenda;
        end if;
      end if;
    end if;
  end if;
end proc_verificafilialbrinde ;

procedure proc_buscadados (p_numped     in   pcpedc.numped%type,
                           p_regpedido  out  t_pedido,
                           p_regrca     out  t_rca,
                           p_regcliente out  t_cliente,
                           p_regplpag   out  t_planodepagamento,
                           p_regfilial  out  t_filial,
                           p_regregiao  out  t_regiao,
                           vsmensagem   out varchar2

                           ) is


  begin


      -- Dados da Empresa
      select *
      into gregpcconsum
      from pcconsum;

      --Dados do pedido
     begin

         select numped,numpedrca,codfilial,codusur,codcli,posicao,percvenda,codfilialnf,numregiao,codplpag,
                localdesembaraco,ufdesembaraco,origemped,numpedcli,dtentrega,dtaberturapedpalm,condvenda,posicao,
                fretedespacho,codfornecfrete,data, numcar, descintermediador, cnpjintermediador, codendentcli
                ,usadebcredrca, brinde, bonificaltdebcredrca ,trocaaltdebcredrca, broker ,brokeraltdebcredrca,  crmaltdebcredrca     
         into p_regpedido
         from pcpedc
         where numped = p_numped;
     exception when others then

        vsmensagem := 'Erro ao selecionar dados do pedido original. '||SQLCODE||' '||SQLERRM;

     end;

      -- Pegando plano de pagamento
      begin
        select codplpag
          into p_regpedido.codplpag
          from pcplpag
         where tipoprazo = 'B';
      exception
        when others then
          -- mantem o valor do pedido original
          null;
      end;

     p_regpedido.posicaoini := p_regpedido.posicao;


    --Dados do RCA
    begin
     select codsupervisor,coddistrib,tipovend,percent,percent2
     into p_regrca
     from pcusuari
     where codusur = p_regpedido.codusur;
     exception when others then

        if vsmensagem is null then

           vsmensagem := 'Erro ao selecionar dados do rca. '||SQLCODE||' '||SQLERRM;
        else

            vsmensagem := vsmensagem||CHR(13)||'Erro ao selecionar dados do rca. '||SQLCODE||' '||SQLERRM;
        end if;

     end;


     --Dados do cliente
     begin
       select codatv1,nvl(calculast,'S'),upper(ieent),tipofj,estent,nvl(isentoipi,'N'),sulframa,nvl(contribuinte,'S'),nvl(utilizaiesimplificada,'N'),
              consumidorfinal,nvl(clientefontest,'N'),nvl(isentoicms,'N'),tipoempresa, nvl(usaivafontediferenciado,'N'),nvl(ivafonte,0),
              nvl(tipodescisencao,'N'),nvl(perdescisentoicms,0),codpraca,classevenda,orgaopub,orgaopubfederal,nvl(isencaosuframa,'T'),
              percomcli,codcliprinc,codfilialnf,NVL(USADESCONTOICMS,'N'),
              nvl(aceitavendafracao, 'S'), usadebcredrca
       into p_regcliente
       from pcclient
       where codcli = p_regpedido.codcli;
       exception when others then

        if vsmensagem is null then

           vsmensagem := 'Erro ao selecionar dados do cliente. '||SQLCODE||' '||SQLERRM;
        else

            vsmensagem := vsmensagem||CHR(13)||'Erro ao selecionar dados do cliente. '||SQLCODE||' '||SQLERRM;
        end if;

     end;


     --Dados do plano de pagamento
     begin

       select codplpag,numpr,numdias,prazo1,prazo2,prazo3,prazo4,prazo5,prazo6,prazo7,prazo8,prazo9,prazo10,prazo11,prazo12,
              tipovenda,pertxfim
       into p_regplpag
       from pcplpag
       where codplpag = p_regpedido.codplpag;
       exception when others then

        if vsmensagem is null then

           vsmensagem := 'Erro ao selecionar dados do plano de pagamento. '||SQLCODE||' '||SQLERRM;
        else

            vsmensagem := vsmensagem||CHR(13)||'Erro ao selecionar dados do plano de pagamento. '||SQLCODE||' '||SQLERRM;
        end if;

     end;

     --Dados da filial
     begin

       select origemcustofilialretira,uf,calcularipivenda, 'N','N','N','P',broker,pcfilial.considerarcomissaozero,nvl(pcfilial.tipoavaliacaocomissao,1),'N',
              'N','N', 'N'
       into p_regfilial
       from pcfilial
       where codigo = p_regpedido.codfilial;
       exception when others then

        if vsmensagem is null then

           vsmensagem := 'Erro ao selecionar dados da filial. '||SQLCODE||' '||SQLERRM;
        else

            vsmensagem := vsmensagem||CHR(13)||'Erro ao selecionar dados da filial. '||SQLCODE||' '||SQLERRM;
        end if;


     end;

     --Dados da Regiao
     begin

       select nvl(p.perfreteterceiros,0),nvl(p.perfreteterceiros,0)
       into p_regregiao
       from pcregiao p
       where p.numregiao = p_regpedido.numregiao;

       exception when others then
        if vsmensagem is null then

           vsmensagem := 'Erro ao selecionar dados da regiao. '||SQLCODE||' '||SQLERRM;
        else

            vsmensagem := vsmensagem||CHR(13)||'Erro ao selecionar dados da regiao. '||SQLCODE||' '||SQLERRM;
        end if;


     end;


     -- Dados 132

     proc_pcparamfilial(p_regpedido.codfilial,
                        'ACEITAVENDASEMESTFV',
                        'N',
                         p_regfilial.ACEITAVENDASEMESTFV);

    proc_pcparamfilial(p_regpedido.codfilial,
                        'FIL_UTILIZAVENDAPOREMBALAGEM',
                        'N',
                         p_regfilial.utilizavendaporembalagem);

    proc_pcparamfilial(p_regpedido.codfilial,
                        'FIL_PRECOPOREMBALAGEM',
                        'N',
                         p_regfilial.precoporembalagem);


    proc_pcparamfilial(p_regpedido.codfilial,
                        'FIL_TIPOPRECIFICACAO',
                        'P',
                         p_regfilial.tipoprecificacao);

    proc_pcparamfilial(p_regpedido.codfilial,
                        'NAOUSARAUTDEBCREDPOLDESC',
                        'N',
                         p_regfilial.naousarautdebcredpoldesc);

    proc_pcparamfilial(p_regpedido.codfilial,
                        'VERIFICAESTOQUECONT',
                        'N',
                         p_regfilial.verificaestoquecont);

    proc_pcparamfilial(p_regpedido.codfilial,
                        'CON_VERIFICAESTOQUECONT',
                        'N',
                         p_regfilial.con_verificaestoquecont);

    proc_pcparamfilial(p_regpedido.codfilial,
                        'DEDUZIRPISCOFINSICMSDOCMV',
                        'N',
                         p_regfilial.DEDUZIRPISCOFINSICMSDOCMV);




end proc_buscadados;

function func_inseriritemcesta
  ( p_numped     in pcpedc.numped%type,
    p_codprod    in pcpedi.codprod%type,
    p_regpedido  in t_pedido,
    p_regrca     in t_rca,
    p_regcliente in t_cliente,
    p_regregiao  in t_regiao,
    p_regfilial  in t_filial,
    p_codplpag   in pcplpag.codplpag%type,
    p_tipovenda  in pcplpag.tipovenda%type,
    p_numseq     in number

  ) return boolean is

    vslinha            varchar2(10);
    vncountitenscesta  number := 0;
    vnnumseq           number;
    vbcalcularst       boolean;
    vsmensagem_st      varchar2(1000);
    vnstfonte          number;
    vsmensagem_stfonte varchar2(1000);
    vsmensagem_comiss  varchar2(1000);
    vnperdesc           number;
    vbcodicmtabpf       boolean;
    vnbaseicstfonte     pcpedi.baseicst%type;
    vsmensagem          varchar2(1000);

    vbUsaPcTabComiss           boolean;
    vbUsaPcComissaoUsur        boolean;
    vbUsaPCComissaoPlPag       boolean;
    vbUsaPCComissaoRegiao      boolean;
    vicont                     number;
    vbUsaPCComissaofilial      boolean;
    vnperluc                   number;

    vncodcomis                 pcorigemcomis.codcomis%type;
    vscodrotinacomis           pcorigemcomis.codrotinacomis%type;
    vsLetraComiss              pcpedi.letracomiss%type;
    vnpercom                   pcpedi.percom%type;
    vsConsiderarIpiAliqicms2   varchar2(1);

  begin

    vsmensagem := null;

    vncountitenscesta := gvet_regitenscesta.count;
    vnnumseq          := 0;

    for i in 1 .. vncountitenscesta
    loop

      if p_numped = gvet_regitenscesta(i).numped  and p_codprod = gvet_regitenscesta(i).codprodcesta
      then

         vsConsiderarIpiAliqicms2 := 'N';

        if (p_regcliente.ConsumidorFinal = 'S') and ((gvet_regitenscesta(i).Importado = 'S') or (gvet_regitenscesta(i).Importado = 'D')) and
           (p_regfilial.uf <> p_regcliente.estent) and (gvet_regitenscesta(i).AGREGARIPICALCULOST = 'S') then

           vsConsiderarIpiAliqicms2 := 'S';
        end if;


        vbcalcularst := funcoesvendas.calcularst(gvet_regitenscesta(i).pvenda
                                                ,0
                                                ,p_regpedido.percvenda
                                                ,gregpcconsum.tipocalcst
                                                ,gregpcconsum.calcstpf
                                                ,gvet_regitenscesta(i).mostrarpvendasemst
                                                ,gregpcconsum.consideraisentoscomopf
                                                ,p_regcliente.calculast
                                                ,p_regcliente.ieent
                                                ,p_regcliente.tipofj
                                                ,gvet_regitenscesta(i).pauta
                                                ,gvet_regitenscesta(i).iva
                                                ,gvet_regitenscesta(i).aliqicms1
                                                ,gvet_regitenscesta(i).aliqicms2
                                                ,gvet_regitenscesta(i).percbaseredst
                                                ,gregpcconsum.numcasasdecvenda
                                                ,0
                                                ,p_regfilial.uf
                                                ,p_regcliente.estent
                                                , gvet_regitenscesta(i).usavalorultentbasest
                                                , gvet_regitenscesta(i).usavalorultentbasest2
                                                ,gvet_regitenscesta(i).valorultent
                                                ,p_regcliente.contribuinte
                                                ,p_regcliente.utilizaiesimplificada
                                                ,vsmensagem_st
                                                ,gvet_regitenscesta(i).st
                                                ,gvet_regitenscesta(i).baseicst
                                                ,gregpcconsum.aceitapfcontribuinte
                                                ,gvet_regitenscesta(i).usapmcbasest
                                                ,gvet_regitenscesta(i).precomaxconsum
                                                ,gvet_regitenscesta(i).custonfsemst
                                                ,p_regcliente.consumidorfinal
                                                ,vsConsiderarIpiAliqicms2
                                                ,gvet_regitenscesta(i).usavlultentmediobasest
                                                ,gvet_regitenscesta(i).vlultentmes

                                                );

                  if gvet_regitenscesta(i).tipocalculognre = 'C' then

                      --24 parâmetros
                      vbcalcularst := funcoesvendas.calcularst(gvet_regitenscesta(i).pvenda,
                                                                    0,
                                                                    p_regpedido.percvenda,
                                                                    gregpcconsum.tipocalcst,
                                                                    gregpcconsum.calcstpf,
                                                                    gvet_regitenscesta(i).mostrarpvendasemst,
                                                                    gregpcconsum.consideraisentoscomopf,
                                                                    p_regcliente.calculast,
                                                                    p_regcliente.ieent,
                                                                    p_regcliente.tipofj,
                                                                    gvet_regitenscesta(i).pauta,
                                                                    gvet_regitenscesta(i).iva,
                                                                    gvet_regitenscesta(i).aliqicms1,
                                                                    gvet_regitenscesta(i).aliqicms2,
                                                                    gvet_regitenscesta(i).percbaseredst,
                                                                    gregpcconsum.numcasasdecvenda,
                                                                    1,
                                                                    p_regfilial.uf,
                                                                    p_regcliente.estent,
                                                                    nvl(gvet_regitenscesta(i).usavalorultentbasest,'N'),
                                                                    nvl(gvet_regitenscesta(i).usavalorultentbasest2,'N'),
                                                                    gvet_regitenscesta(i).valorultent,
                                                                    p_regcliente.contribuinte,
                                                                    p_regcliente.utilizaiesimplificada,
                                                                    vsmensagem_st,
                                                                    gvet_regitenscesta(i).st,
                                                                    gvet_regitenscesta(i).baseicst,
                                                                    gregpcconsum.aceitapfcontribuinte,
                                                                    gvet_regitenscesta(i).usapmcbasest,
                                                                    gvet_regitenscesta(i).precomaxconsum,
                                                                    gvet_regitenscesta(i).custonfsemst,
                                                                    p_regcliente.consumidorfinal,
                                                                    vsConsiderarIpiAliqicms2,
                                                                    gvet_regitenscesta(i).usavlultentmediobasest,
                                                                    gvet_regitenscesta(i).vlultentmes);

                      gvet_regitenscesta(i).stclientegnre := gvet_regitenscesta(i).st;
                      gvet_regitenscesta(i).st := 0;

                    end if;

                    if vsmensagem_st is not null then


                        if vsmensagem is null then

                           vsmensagem := vsmensagem_st;
                        else

                            vsmensagem := vsmensagem||CHR(13)||vsmensagem_st;
                        end if;
                    end if;

        vnstfonte := 0;

        vnstfonte := funcoesvendas.calcularstfonte(gvet_regitenscesta(i).codprodcesta
                                                  ,p_regpedido.condvenda
                                                  ,p_regpedido.percvenda
                                                  ,gvet_regitenscesta(i).iva
                                                  ,gvet_regitenscesta(i).ivafonte
                                                  ,gvet_regitenscesta(i).aliqicms1fonte
                                                  ,gvet_regitenscesta(i).aliqicms2fonte
                                                  ,gvet_regitenscesta(i).percbaseredstfonte
                                                  ,gvet_regitenscesta(i).perbaserednrpa
                                                  , gvet_regitenscesta(i).percbaseredconsumidor
                                                  , gvet_regitenscesta(i).utilizapercbaseredpf
                                                  ,gregpcconsum.tipocalcst
                                                  ,gregpcconsum.calcstpf
                                                  ,gregpcconsum.utilizapercbaseredpf
                                                  ,p_regcliente.clientefontest
                                                  ,p_regcliente.calculast
                                                  ,p_regcliente.ieent
                                                  ,p_regcliente.tipofj
                                                  ,p_regcliente.isentoicms
                                                  ,p_regcliente.consumidorfinal
                                                  ,p_regcliente.utilizaiesimplificada
                                                  ,p_regcliente.tipoempresa
                                                  ,gregpcconsum.consideraisentoscomopf
                                                  ,gvet_regitenscesta(i).pvenda
                                                  ,0
                                                  ,p_regfilial.uf
                                                  ,p_regcliente.estent
                                                  ,gvet_regitenscesta(i).usavalorultentbasest
                                                  ,gvet_regitenscesta(i).valorultent
                                                  ,p_regcliente.usaivafontediferenciado
                                                  ,p_regcliente.ivafonte
                                                  ,gregpcconsum.aceitapfcontribuinte
                                                  ,gvet_regitenscesta(i).aliqicms1
                                                  ,gvet_regitenscesta(i).aliqicms2
                                                  ,p_Regcliente.contribuinte
                                                  ,gregpcconsum.numcasasdecvenda
                                                  ,vnbaseicstfonte
                                                  ,vsmensagem_stfonte
                                                  ,gvet_regitenscesta(i).custonfsemst
                                                  ,gvet_regitenscesta(i).usavalorultentbasest2
                                                  ,gvet_regitenscesta(i).usapmcbasest
                                                  ,gvet_regitenscesta(i).precomaxconsum);

        if vnbaseicstfonte > 0 then

         gvet_regitenscesta(i).baseicst := vnbaseicstfonte;

        end if;


        if vsmensagem_stfonte is not null
        then
              if vsmensagem is null then

                 vsmensagem := vsmensagem_stfonte;
              else

                  vsmensagem := vsmensagem||CHR(13)||vsmensagem_stfonte;
              end if;
        end if;

        if (gvet_regitenscesta(i).st = 0)
           and (vnSTFONTE <> 0)
        then

          gvet_regitenscesta(i).st := vnSTFONTE;

          gvet_regitenscesta(i).PVENDA := Round(gvet_regitenscesta(i).PVENDA + vnSTFONTE
                                               ,gregpcconsum.numcasasdecvenda);


          gvet_regitenscesta(i).PTABELA := Round(gvet_regitenscesta(i)
                                                 .PTABELA + vnSTFONTE
                                                ,gregpcconsum.numcasasdecvenda);

          gvet_regitenscesta(i).IVA := gvet_regitenscesta(i).ivafonte;

          gvet_regitenscesta(i).PAUTA := 0;

          gvet_regitenscesta(i).ALIQICMS1 := gvet_regitenscesta(i).aliqicms1fonte;

          gvet_regitenscesta(i).ALIQICMS2 := gvet_regitenscesta(i).aliqicms2fonte;

          gvet_regitenscesta(i).PERCBASEREDST := gvet_regitenscesta(i).percbaseredst;

          gvet_regitenscesta(i).PERCBASEREDSTFONTE := gvet_regitenscesta(i)
                                                     .PERCBASEREDSTFONTE;
        end if;



       if gvet_regitenscesta(i).codicmtabpf is null
        then
          vbcodicmtabpf := true;
        else
          vbcodicmtabpf := false;
        end if;

        funcoesvendas.calcularCMV(gregpcconsum.abaterimpostoscomissaorca
                                 ,gregpcconsum.aplicarindicecmv
                                 ,gregpcconsum.Incluircomissaosugpvendacmv
                                 ,nvl(gregpcconsum.txvenda, 0)
                                 ,p_regcliente.tipofj
                                 ,p_regcliente.utilizaiesimplificada
                                 ,p_regcliente.ieent
                                 ,gvet_regitenscesta(i).freteespecial
                                 ,p_regregiao.PERFRETETERCEIROS
                                 ,p_regregiao.PERFRETEESPECIAL
                                 ,gvet_regitenscesta(i).vlcustofin
                                 ,gvet_regitenscesta(i).vlcustoreal
                                 ,gvet_regitenscesta(i).perdesccusto
                                 ,gvet_regitenscesta(i).codicmtab
                                 ,vbcodicmtabpf
                                 ,gvet_regitenscesta(i).codicmtabpf
                                 ,p_regpedido.percvenda
                                 ,gvet_regitenscesta(i).pvenda
                                 ,0
                                 ,gvet_regitenscesta(i).ST
                                 ,0
                                 ,0
                                 ,p_regcliente.contribuinte
                                 , 0
                                 , 0--nvl(gvet_Regitem(j).VLREDPVENDASIMPLESNA,0)
                                 , p_regcliente.consumidorfinal
                                 , nvl(gregpcconsum.consideraisentoscomopf,'N')
                                 ,gvet_regitenscesta(i).perfretecmv
                                 ,gvet_regitenscesta(i).CUSTOFINEST
                                 ,gvet_regitenscesta(i).txvenda
                                 ,gvet_regitenscesta(i).perdesccusto
                                 ,gvet_regitenscesta(i).CODICMTAB
                                 ,gvet_regitenscesta(i).VLCUSTOREAL
                                 ,gvet_regitenscesta(i).VLCUSTOFIN
                                 ,gvet_regitenscesta(i).VLDESCCUSTOCMV);



         vnperdesc := ((gvet_regitenscesta(i).ptabela - gvet_regitenscesta(i).pvenda) / gvet_regitenscesta(i).ptabela) * 100;
         vnperdesc := ROUND(vnperdesc, gregpcconsum.numcasasdecvenda);

          vnperluc := ((gvet_regitenscesta(i).pvenda - gvet_regitenscesta(i).vlcustofin) / gvet_regitenscesta(i).pvenda) * 100;

              -- busca percentual de comissao
/*        vsmensagem_comiss := null;


              select count(*)
              into vicont
              from pctabcomiss p;

              if vicont <> 0 then
                vbUsaPcTabComiss := true;
              else
                vbUsaPcTabComiss := false;
              end if;

              select count(*)
              into vicont
              from pccomissaousur p;

              if vicont <> 0 then
                vbUsaPcComissaoUsur := true;
              else
                vbUsaPcComissaoUsur := false;
              end if;


              select count(*)
              into vicont
              from pccomissaoplpag p;

              if vicont <> 0 then
                vbUsaPcComissaoplpag := true;
              else
                vbUsaPCComissaoPlPag := false;
              end if;


              select count(*)
              into vicont
              from pccomissaoregiao p;

              if vicont <> 0 then
                vbUsaPcComissaoregiao := true;
              else
                vbUsaPcComissaoregiao := false;
              end if;

              if p_regfilial.broker = 'S' then
                 vbUsaPCComissaofilial := true;
              else
                 vbUsaPCComissaofilial := false;
              end if;

               begin


              gvet_regitenscesta(i).percom := FUNCOESVENDAS.Definir_Comissao_Item_Vendido
                                 (p_regpedido.numregiao,
                                  vnperluc,
                                  vnperdesc,
                                  vbUsaPcTabComiss,
                                  vbUsaPcComissaoUsur,
                                  vbUsaPCComissaoPlPag,
                                  vbUsaPCComissaoRegiao,
                                  vbUsaPCComissaofilial,
                                  gregpcconsum.usacomissaoporrca,
                                  gregpcconsum.OrdemAvaliacaoComissaoRCA,
                                  gregpcconsum.usacomissaoporcliente,
                                  gregpcconsum.USACOMISSAOPORLINHAPROD,
                                  gregpcconsum.comissaorcatipovenda,
                                  p_regrca.tipovend,
                                  p_regrca.percent,
                                  p_regrca.percent2,
                                  gvet_regitenscesta(i).codprodmp,
                                  gvet_regitenscesta(i).pcomint1,
                                  gvet_regitenscesta(i).PCOMEXT1,
                                  gvet_regitenscesta(i).PCOMREP1,
                                  gvet_regitenscesta(i).codlinhaprod,
                                  gvet_regitenscesta(i).tipocomissao,
                                  gvet_regitenscesta(i).codepto,
                                  gvet_regitenscesta(i).codsec,
                                  gvet_regitenscesta(i).classe,
                                  p_regplpag.tipovenda,
                                  p_regplpag.codplpag,
                                  p_regpedido.data,
                                  p_regpedido.codfilial,
                                  p_regpedido.codusur,
                                  p_regfilial.considerarcomissaozero,
                                  p_regfilial.tipoavaliacaocomissao,
                                  p_regcliente.percomcli,
                                  p_regpedido.codcli,
                                  null,
                                  vncodcomis,
                                  vscodrotinacomis,
                                  vsLetraComiss,
                                  vsmensagem_comiss,
                                  gvet_regitenscesta(i).codauxiliar ,
                                  null ,--regprecos.pcomint1_emb,
                                  null ,--regprecos.PCOMEXT1_emb,
                                  null ,--regprecos.PCOMREP1_emb,
                                  p_regfilial.utilizavendaporembalagem);
                           exception when others then
                              if vsmensagem is null then

                                 vsmensagem := vsmensagem_comiss ;
                              else

                                  vsmensagem := vsmensagem||CHR(13)||vsmensagem_comiss;
                              end if;
                        end ;

                     if nvl(gregpcconsum.incluircomissaocmvvenda,'S') = 'N' then
                          vnpercom := 0;
                     else
                         vnpercom := gvet_regitenscesta(i).percom;
                     end if;*/


        funcoesvendas.calcularCMV(gregpcconsum.abaterimpostoscomissaorca
                                 ,gregpcconsum.aplicarindicecmv
                                 ,gregpcconsum.Incluircomissaosugpvendacmv
                                 ,nvl(gregpcconsum.txvenda, 0)
                                 ,p_regcliente.tipofj
                                 ,p_regcliente.utilizaiesimplificada
                                 ,p_regcliente.ieent
                                 ,gvet_regitenscesta(i).freteespecial
                                 ,p_regregiao.PERFRETETERCEIROS
                                 ,p_regregiao.PERFRETEESPECIAL
                                 ,gvet_regitenscesta(i).vlcustofin
                                 ,gvet_regitenscesta(i).vlcustoreal
                                 ,gvet_regitenscesta(i).perdesccusto
                                 ,gvet_regitenscesta(i).codicmtab
                                 ,vbcodicmtabpf
                                 ,gvet_regitenscesta(i).codicmtabpf
                                 ,p_regpedido.percvenda
                                 ,gvet_regitenscesta(i).pvenda
                                 ,0 --vnPERCOM
                                 ,gvet_regitenscesta(i).ST
                                 ,0
                                 ,0
                                 ,p_regcliente.contribuinte
                                 , 0
                                 , 0--nvl(gvet_Regitem(j).VLREDPVENDASIMPLESNA,0)
                                 , p_regcliente.consumidorfinal
                                 , nvl(gregpcconsum.consideraisentoscomopf,'N')
                                 ,gvet_regitenscesta(i).perfretecmv
                                 ,gvet_regitenscesta(i).CUSTOFINEST
                                 ,gvet_regitenscesta(i).txvenda
                                 ,gvet_regitenscesta(i).perdesccusto
                                 ,gvet_regitenscesta(i).CODICMTAB
                                 ,gvet_regitenscesta(i).VLCUSTOREAL
                                 ,gvet_regitenscesta(i).VLCUSTOFIN
                                 ,gvet_regitenscesta(i).VLDESCCUSTOCMV);


        insert into pcpedicesta
          (numped,
           codprod,
           numseq,
           codprodmp,
           qtmp,
           pvenda,
           ptabela,
           pbaserca,
           st,
           vlcustofin,
           vlcustoreal,
           percom,
           baseicst,
           aliqicms1,
           aliqicms2,
           percbaseredst,
           iva,
           pauta,
           percbaseredstfonte,
           percbasered,
           codst,
           vlcustorep,
           vlcustocont,
           custofinest,
           perdesccusto,
           codicmtab,
           perfretecmv,
           txvenda,
           vldesccustocmv,
           codauxiliar,
           stclientegnre)
        values
          (p_numped,
           p_codprod,
           p_numseq,
           gvet_regitenscesta(i).codprodmp,
           gvet_regitenscesta(i).qt,
           gvet_regitenscesta(i).pvenda,
           gvet_regitenscesta(i).ptabela,
           gvet_regitenscesta(i).ptabela,
           gvet_regitenscesta(i).st,
           gvet_regitenscesta(i).vlcustofin,
           gvet_regitenscesta(i).vlcustoreal,
           0 ,--gvet_regitenscesta(i).percom,
           gvet_regitenscesta(i).baseicst,
           gvet_regitenscesta(i).aliqicms1,
           gvet_regitenscesta(i).aliqicms2,
           gvet_regitenscesta(i).percbaseredst,
           gvet_regitenscesta(i).iva,
           gvet_regitenscesta(i).pauta,
           gvet_regitenscesta(i).percbaseredstfonte,
           gvet_regitenscesta(i).percbasered,
           gvet_regitenscesta(i).codst,
           gvet_regitenscesta(i).custorep,
           gvet_regitenscesta(i).custocont,
           gvet_regitenscesta(i).custofinest,
           gvet_regitenscesta(i).perdesccusto,
           gvet_regitenscesta(i).codicmtab,
           gvet_regitenscesta(i).perfretecmv,
           gvet_regitenscesta(i).txvenda,
           gvet_regitenscesta(i).vldesccustocmv,
           gvet_regitenscesta(i).codauxiliar,
           gvet_regitenscesta(i).stclientegnre
           );
      end if;
    end loop;


    return true;
  exception
    when others then


        if vsmensagem is null then

           vsmensagem := 'Problemas na gravacao o item de cesta ' || sqlcode || '-' ||sqlerrm;
        else

            vsmensagem := vsmensagem||CHR(13)||'Problemas na gravacao o item de cesta ' || sqlcode || '-' ||SQLERRM;
       end if;


      return false;
  end func_inseriritemcesta;

procedure proc_verificaprecofixocesta (  p_codprod    in   pcpedi.codprod%type,
                                         p_regpedido  in   t_pedido,
                                         p_regcliente in   t_cliente,
                                         p_mensagem   out  varchar2,
                                         p_valido     out  boolean) is

      vicontador             number;
      vsutilizaprecofixorede pcprecocestac.utilizaprecofixorede%type;
      vncountitenscesta      number;
      vntotalcesta           number;
      vntotalcestatemp       number;
      vncodprecocesta        pcprecocestac.codprecocesta%type;


  begin

     p_mensagem := null;
     p_valido := false;

     select count(*)
     into vicontador
     from PCPRECOCESTAC p
     where p.dtexclusao is null
     and   p.dtinicio <= trunc(sysdate)
     and   p.dtfim    >= trunc(sysdate)
     and   p.codprodacab = p_codprod
     and   (p.codfilial   = p_regpedido.codfilial or p.codfilial is null)
     and   (p.numregiao   = p_regpedido.numregiao or p.numregiao is null)
     and   (p.codplpag    = p_regpedido.codplpag or p.codplpag is null)
     and   ( p.codcli      = decode(p.utilizaprecofixorede,'S',p_regcliente.codcliprinc,p_regpedido.codcli) or p.codcli is null);


     if vicontador > 0 then

         if vicontador > 1 then

             vntotalcesta := 0;

         -- verificar qual cesta utilizar ( buscando a que tem o menor preço fixo)
                 for reg in (select p.codprecocesta
                             from PCPRECOCESTAC p
                             where p.dtexclusao is null
                             and   p.dtinicio <= trunc(sysdate)
                             and   p.dtfim    >= trunc(sysdate)
                             and   p.codprodacab = p_codprod
                             and   (p.codfilial   = p_regpedido.codfilial or p.codfilial is null)
                             and   (p.numregiao   = p_regpedido.numregiao or p.numregiao is null)
                             and   (p.codplpag    = p_regpedido.codplpag or p.codplpag is null)
                             and   ( p.codcli      = decode(p.utilizaprecofixorede,'S',p_regcliente.codcliprinc,p_regpedido.codcli) or p.codcli is null)
                             ) loop



                --verifica se tem algum item da cesta que está sem preco fixo
                 select count(*)
                 into vicontador
                 from pcformprod f
                 where f.codprodacab   = p_codprod
                 and   not exists (select 'x' from pcprecocestai i
                                   where  i.codprodmp = f.codprodmp
                                   and i.codprecocesta = reg.codprecocesta);



                  --todos os itens da cesta estão com preço fixo
                 if vicontador = 0 then

                     vncountitenscesta := gvet_regitenscesta.count;

                     vntotalcestatemp := 0;

                        for i in 1 .. vncountitenscesta
                        loop

                          if p_regpedido.numped = gvet_regitenscesta(i).numped
                             and p_codprod = gvet_regitenscesta(i).codprodcesta
                          then




                                 for regi in ( select i.precofixo , p.qtprodmp
                                                        from pcprecocestai i,pcformprod p
                                                        where i.codprecocesta = reg.codprecocesta
                                                        and   i.codprodacab   = p_codprod
                                                        and   i.codprodmp     = gvet_regitenscesta(i).codprodmp
                                                        and   i.codprodacab   = p.codprodacab
                                                        and   i.codprodmp     = p.codprodmp ) loop



                                         vntotalcestatemp := nvl(vntotalcestatemp,0) + (regi.precofixo * regi.qtprodmp);

                                    end loop;
                               end if;

                           end loop;


                          if vntotalcestatemp < vntotalcesta or vntotalcesta = 0 then

                             vntotalcesta := vntotalcestatemp;
                             vncodprecocesta := reg.codprecocesta;

                          end if;

                     end if;

                 end loop;


          else --tem apenas 1 campanha de preço fixo de cesta

               select p.codprecocesta
               into vncodprecocesta
               from PCPRECOCESTAC p
               where p.dtexclusao is null
               and   p.dtinicio <= trunc(sysdate)
               and   p.dtfim    >= trunc(sysdate)
               and   p.codprodacab = p_codprod
               and   (p.codfilial   = p_regpedido.codfilial or p.codfilial is null)
               and   (p.numregiao   = p_regpedido.numregiao or p.numregiao is null)
               and   (p.codplpag    = p_regpedido.codplpag or p.codplpag is null)
               and   ( p.codcli      = decode(p.utilizaprecofixorede,'S',p_regcliente.codcliprinc,p_regpedido.codcli) or p.codcli is null)  ;

            end if;


             vntotalcesta := 0;

                --verifica se tem algum item da cesta que está sem preco fixo
                 select count(*)
                 into vicontador
                 from pcformprod f
                 where f.codprodacab   = p_codprod
                 and   not exists (select 'x' from pcprecocestai i
                                   where  i.codprodmp = f.codprodmp
                                   and i.codprecocesta = vncodprecocesta);



                  --todos os itens da cesta estão com preço fixo
                 if vicontador = 0 then

                     vncountitenscesta := gvet_regitenscesta.count;


                        for i in 1 .. vncountitenscesta
                        loop

                          if p_regpedido.numped = gvet_regitenscesta(i).numped
                             and p_codprod = gvet_regitenscesta(i).codprodcesta
                          then

                              for regi in ( select i.precofixo , p.qtprodmp
                                                  from pcprecocestai i,pcformprod p
                                                  where i.codprecocesta = vncodprecocesta
                                                  and   i.codprodacab   = p_codprod
                                                  and   i.codprodmp     = gvet_regitenscesta(i).codprodmp
                                                  and   i.codprodacab   = p.codprodacab
                                                  and   i.codprodmp     = p.codprodmp ) loop



                                   gvet_regitenscesta(i).ptabela := regi.precofixo;
                                   gvet_regitenscesta(i).pvenda  := regi.precofixo;

                                   vntotalcesta := nvl(vntotalcesta,0) + (regi.precofixo * regi.qtprodmp);

                              end loop;


                         end if;
                        end loop;


                         if nvl(vntotalcesta,0) > 0 then
                          p_valido := true;
                         end if;

                 else
                 p_mensagem := 'Preço Fixo da cesta inválida. Será o utilizado o preço de tabela.';

                 end if;



     end if;




  end proc_verificaprecofixocesta;

procedure proc_buscaprecocesta(p_numped     in pcpedc.numped%type,
                               p_codprod    in pcpedi.codprod%type,
                               p_qt         in pcpedi.qt%type,
                               p_regpedido  in t_pedido,
                               p_regregiao  in t_regiao,
                               p_numpr      in pcplpag.numpr%type,
                               p_regcliente in t_cliente,
                               p_regfilial  in t_filial,
                               p_ptabela    out pcpedi.ptabela%type,
                               p_valido     out boolean) is

 vnptabela           pcpedi.ptabela%type;
 vbcesta             boolean;
 vsmensagemcesta     varchar2(1000);
 vsmensagem          varchar2(1000);

    vnqtde                       number;
    vbecesta                     boolean;
    vnptabelacesta               number;
    vnsubtotal                   number;
    vnperdesccesta               number := 0;
    vncount                      number := 0;


    vniva                        pcpedi.iva%type;
    vnpauta                      pcpedi.pauta%type;
    vnaliqicms1                  pcpedi.aliqicms1%type;
    vnaliqicms2                  pcpedi.aliqicms2%type;
    vnivafonte                   pctribut.ivafonte%type;
    vnaliqicms1fonte             pctribut.aliqicms1fonte%type;
    vnaliqicms2fonte             pctribut.aliqicms2fonte%type;
    vnpercbaseredst              pctribut.percbaseredst%type;
    vnpercbasered                pctribut.percbasered%type;
    vsusavalorultentbasest       pctribut.usavalorultentbasest%type;
    vsusavalorultentbasest2      pctribut.usavalorultentbasest2%type;
    vnvalorultent                pcest.valorultent%type;
    vnpercbaseredconsumidor      pctribut.percbaseredconsumidor%type;
    vsutilizapercbaseredpf       pctribut.utilizapercbaseredpf%type;
    vnpercbaseredstfonte         pctribut.percbaseredstfonte%type;

    vnperdesccusto               pctribut.perdesccusto%Type;
    vncustocont                  pcest.custocont%type;
    vncustorep                   pcest.custorep%type;
    vncodicmtab                  pctribut.codicmtab%type;


    vnvlcustofin                 pcpedi.vlcustofin%type;
    vnvlcustoreal                pcpedi.vlcustoreal%type;
    vnpvenda                     number;

    vnpcomint1                   pcprodut.pcomint1%type;
    vnpcomext1                   pcprodut.pcomext1%type;
    vnpcomrep1                   pcprodut.pcomrep1%type;
    vncodlinhaprod               pcprodut.codlinhaprod%type;
    vncodsec                     pcprodut.codsec%type;
    vncodepto                    pcprodut.codepto%type;
    vncodicmtabpf                pctribut.codicmtabpf%type;
    vnfreteespecial              pcprodut.freteespecial%type;
    vnpvendamaior                number;
    vnreg                        number;
    vndif                        number;
    vsmostrarpvendasemst         pctribut.mostrarpvendasemst%type;

    vsmensagemprecofixocesta     varchar2(32767);
    vbvalidoprecofixocesta       boolean;

    vsusapmcbasest               pctribut.usapmcbasest%type;
    vnprecomaxconsum             pcprodut.precomaxconsum%type;
    vncustonfsemst               pcest.custonfsemst%type;
    vncodst                      pctribut.codst%type;
    vsAPLICAACRESCPJISENTA       pctribut.aplicaacrescpjisenta%type;
    vnperacrescismopf            pctribut.peracrescismopf%type;
    vicontador                   number;

    vnqtminimaatacado            pcembalagem.qtminimaatacado%type;
    vnqtunit                     pcembalagem.qtunit%type;
    vnpvendaatac                 pcembalagem.pvendaatac%type;
    vnpvendaemb                  pcembalagem.pvenda%type;
    vnpoferta                    pcembalagem.poferta%type;
    vddtofertaini                pcembalagem.dtofertaini%type;
    vddtofertafim                pcembalagem.dtofertafim%type;
    vddtofertaatacini            pcembalagem.dtofertaatacini%type;
    vddtofertaatacfim            pcembalagem.dtofertaatacfim%type;
    vnpofertaatac                pcembalagem.pofertaatac%type;

    vstipocomissao               pcprodut.tipocomissao%type;
    vsclasse                     pcprodut.classe%type;
    vstipocalculognre            pctribut.tipocalculognre%type;

    vsusavlultentmediobasest     pctribut.usavlultentmediobasest%type;
    vnvlultentmes                pctabpr.vlultentmes%type;
    vsimportado                  pcprodut.importado%type;
    vsAGREGARIPICALCULOST        pctribut.agregaripicalculost%type;

    vnCODICMTABBONIF             pctribut.codicmtabbonif%type;
    vncodicmtabpfbonif           pctribut.codicmtabpfbonif%type;
    vbClienteAplicaReducoesTrib  boolean;
    vsDEDUZIRPISCOFINSICMSDOCMV  varchar2(1);
begin

  p_valido := true;

        funcoesvendas.buscarprecocestabasica(p_numped
                                            ,p_codprod
                                            ,p_regpedido.numregiao
                                            ,p_numpr
                                            ,vbcesta
                                            ,vnptabelacesta
                                            ,vsmensagemcesta
                                            ,p_regfilial.utilizavendaporembalagem
                                            ,p_regfilial.precoporembalagem
                                            ,p_regfilial.tipoprecificacao
                                            ,p_regpedido.codfilial
                                            ,p_qt);


        if vbcesta = false
        then

          if vsmensagem is null  then

           vsmensagem :=  ' Nao encontrado cadastro como cesta';

          else

          vsmensagem       := vsmensagem || CHR(13) || ' Nao encontrado cadastro como cesta';

         end if;

          p_valido := false;

        else



          vncount := 0;
          for reg_itenscesta in (select p.codprodmp,
                                        p.codauxiliarmp,
                                        p.qtprodmp
                                 from pcformprod p
                                 where p.codprodacab = p_codprod)
          loop

            vncount := vncount + 1;

          --utiliza venda por embalagem
       /*   if p_regfilial.utilizavendaporembalagem = 'S' then

           if gregpcconsum.usatributacaoporuf = 'S' then


                 select count(*)
                into vicontador
                from pctabtrib p
                where p.codprod     = reg_itenscesta.codprodmp
                and   p.codfilialnf = nvl(p_regpedido.codfilialnf,nvl(p_regcliente.codfilialnf,p_regpedido.codfilial))
                and   p.ufdestino   = p_Regcliente.estent;

                if vicontador = 0 then


                    if vsmensagem is null  then

                     vsmensagem :=  ' Nao encontrado cadastro como cesta';

                    else

                    vsmensagem       := vsmensagem || CHR(13) || ' Não encontrada tributação por estado para item da cesta';

                   end if;

                     p_valido := false;


                else

                    select p.codst
                    into vncodst
                    from pctabtrib p
                    where p.codprod     = reg_itenscesta.codprodmp
                    and   p.codfilialnf = nvl(p_regpedido.codfilialnf,nvl(p_regcliente.codfilialnf,p_regpedido.codfilial))
                    and   p.ufdestino   = p_Regcliente.estent
                    and   rownum = 1;

               begin

                select decode(p_numpr
                             ,1
                             ,pctabpr.pvenda1
                             ,2
                             ,pctabpr.pvenda2
                             ,3
                             ,pctabpr.pvenda3
                             ,4
                             ,pctabpr.pvenda4
                             ,5
                             ,pctabpr.pvenda5
                             ,6
                             ,pctabpr.pvenda6
                             ,7
                             ,pctabpr.pvenda7
                             ,0),
                       nvl(pctribut.pauta,0),
                       nvl(pctribut.aliqicms1,0),
                       nvl(pctribut.aliqicms2,0),
                       nvl(pcest.custofin,0),
                       nvl(pcest.custoreal,0),
                       nvl(pctribut.iva,0),
                       nvl(pctribut.aliqicms1fonte,0),
                       nvl(pctribut.aliqicms2fonte,0),
                       nvl(pctribut.percbaseredst,0),
                       nvl(pctribut.percbasered,0),
                       pctribut.usavalorultentbasest,
                       pctribut.usavalorultentbasest2,
                       nvl(pcest.valorultent,0),
                       nvl(pctribut.percbaseredconsumidor,0),
                       pctribut.utilizapercbaseredpf,
                       nvl(pctribut.percbaseredstfonte,0),
                       pctabpr.codst,
                       nvl(pctribut.perdesccusto,0),
                       nvl(pcest.custocont,0),
                       nvl(pcest.custorep,0),
                       pctribut.codicmtab,
                       nvl(pcprodut.pcomint1,0),
                       nvl(pcprodut.pcomext1,0),
                       nvl(pcprodut.pcomrep1,0),
                       pcprodut.codlinhaprod,
                       pcprodut.codsec,
                       pcprodut.codepto,
                       NVL(pctribut.codicmtabpf, 0),
                       pcprodut.freteespecial,
                       nvl(pctribut.mostrarpvendasemst,nvl(gregpcconsum.mostrarpvendasemst,'N')),
                       nvl(pctribut.usapmcbasest,'N'),
                       nvl(pcprodut.precomaxconsum,0) ,
                       nvl(pcest.custonfsemst,pcest.valorultent),
                       nvl(pctribut.peracrescismopf,0),
                       nvl(pctribut.aplicaacrescpjisenta,'N' ),
                       nvl(pcembalagem.qtminimaatacado,0) qtminimaatacado,
                       nvl(pcembalagem.qtunit,1) qtunit,
                      (decode(nvl(pcembalagem.pvendaatac,0),0,nvl(pcembalagem.pvenda,0),nvl(pcembalagem.pvendaatac,0)) * decode(nvl(pcembalagem.fatorpreco, 1),0,1,nvl(pcembalagem.fatorpreco, 1))) pvendaatac,
                      (nvl(pcembalagem.pvenda,0) * decode(nvl(pcembalagem.fatorpreco, 1),0,1,nvl(pcembalagem.fatorpreco, 1))) pvendaemb,
                      (nvl(pcembalagem.poferta,0) * decode(nvl(pcembalagem.fatorpreco, 1),0,1,nvl(pcembalagem.fatorpreco, 1))) poferta,
                       pcembalagem.dtofertaini dtofertaini,
                       pcembalagem.dtofertafim dtofertafim,
                       pcembalagem.dtofertaatacini dtofertaatacini,
                       pcembalagem.dtofertaatacfim dtofertaatacfim,
                       nvl(pcembalagem.pofertaatac,0)pofertaatac ,
                       pcprodut.tipocomissao,
                       pcprodut.classe,
                       pctribut.tipocalculognre,
                       nvl(pctribut.agregaripicalculost, 'N'),
                       pcprodut.importado,
                       nvl(pctribut.usavlultentmediobasest, 'N'),
                       nvl(pctabpr.vlultentmes,0)
                into vnptabela,
                     vnpauta,
                     vnaliqicms1,
                     vnaliqicms2,
                     vnvlcustofin,
                     vnvlcustoreal,
                     vniva,
                     vnaliqicms1fonte,
                     vnaliqicms2fonte,
                     vnpercbaseredst,
                     vnpercbasered,
                     vsusavalorultentbasest,
                     vsusavalorultentbasest2,
                     vnvalorultent,
                     vnpercbaseredconsumidor,
                     vsutilizapercbaseredpf,
                     vnPERCBASEREDSTFONTE,
                     vncodst,
                     vnperdesccusto,
                     vncustocont,
                     vncustorep,
                     vncodicmtab,
                     vnpcomint1,
                     vnpcomext1,
                     vnpcomrep1,
                     vncodlinhaprod,
                     vncodsec,
                     vncodepto,
                     vncodicmtabpf,
                     vnfreteespecial,
                     vsmostrarpvendasemst,
                     vsusapmcbasest,
                     vnprecomaxconsum,
                     vncustonfsemst,
                     vnperacrescismopf,
                     vsAPLICAACRESCPJISENTA,
                     vnqtminimaatacado,
                     vnqtunit,
                     vnpvendaatac,
                     vnpvendaemb,
                     vnpoferta,
                     vddtofertaini,
                     vddtofertafim,
                     vddtofertaatacini,
                     vddtofertaatacfim,
                     vnpofertaatac,
                     vstipocomissao,
                     vsclasse,
                     vstipocalculognre,
                     vsagregaripicalculost,
                     vsimportado,
                     vsusavlultentmediobasest,
                     vnvlultentmes
                from pctabpr,
                     pctribut,
                     pcest,
                     pcprodut,
                     pcembalagem
                where pctribut.codst  = vncodst
                  and pctabpr.codprod = reg_itenscesta.codprodmp
                  and pcest.codprod = reg_itenscesta.codprodmp
                  and pctabpr.numregiao = p_regpedido.numregiao
                  and pcest.codfilial = p_regpedido.codfilial
                  and pctabpr.codprod = pcprodut.codprod
                  and pcembalagem.codprod = reg_itenscesta.codprodmp
                  and pcembalagem.codauxiliar = reg_itenscesta.codauxiliarmp
                  and pcembalagem.codfilial = p_regpedido.codfilial;

                  exception when others then

                 if vsmensagem is null  then

                     vsmensagem :=  ' Problema ao buscar preço do item da cesta : '||reg_itenscesta.codprodmp;

                    else

                    vsmensagem       := vsmensagem || CHR(13) || ' Problema ao buscar preço do item da cesta : '||reg_itenscesta.codprodmp;

                   end if;

                     p_valido := false;

               end;
              end if;

           --Nao usa tributacao por estado
           else

           begin
                select decode(p_numpr
                             ,1
                             ,pctabpr.pvenda1
                             ,2
                             ,pctabpr.pvenda2
                             ,3
                             ,pctabpr.pvenda3
                             ,4
                             ,pctabpr.pvenda4
                             ,5
                             ,pctabpr.pvenda5
                             ,6
                             ,pctabpr.pvenda6
                             ,7
                             ,pctabpr.pvenda7
                             ,0),
                       nvl(pctribut.pauta,0),
                       nvl(pctribut.aliqicms1,0),
                       nvl(pctribut.aliqicms2,0),
                       nvl(pcest.custofin,0),
                       nvl(pcest.custoreal,0),
                       nvl(pctribut.iva,0),
                       nvl(pctribut.aliqicms1fonte,0),
                       nvl(pctribut.aliqicms2fonte,0),
                       nvl(pctribut.percbaseredst,0),
                       nvl(pctribut.percbasered,0),
                       pctribut.usavalorultentbasest,
                       pctribut.usavalorultentbasest2,
                       nvl(pcest.valorultent,0),
                       nvl(pctribut.percbaseredconsumidor,0),
                       pctribut.utilizapercbaseredpf,
                       nvl(pctribut.percbaseredstfonte,0),
                       pctabpr.codst,
                       nvl(pctribut.perdesccusto,0),
                       nvl(pcest.custocont,0),
                       nvl(pcest.custorep,0),
                       pctribut.codicmtab,
                       nvl(pcprodut.pcomint1,0),
                       nvl(pcprodut.pcomext1,0),
                       nvl(pcprodut.pcomrep1,0),
                       pcprodut.codlinhaprod,
                       pcprodut.codsec,
                       pcprodut.codepto,
                       NVL(pctribut.codicmtabpf, 0),
                       pcprodut.freteespecial,
                       nvl(pctribut.mostrarpvendasemst,nvl(gregpcconsum.mostrarpvendasemst,'N')),
                       nvl(pctribut.usapmcbasest,'N'),
                       nvl(pcprodut.precomaxconsum,0) ,
                       nvl(pcest.custonfsemst,pcest.valorultent),
                       nvl(pctribut.peracrescismopf,0),
                       nvl(pctribut.aplicaacrescpjisenta,'N' ),
                       nvl(pcembalagem.qtminimaatacado,0) qtminimaatacado,
                       nvl(pcembalagem.qtunit,1) qtunit,
                      (decode(nvl(pcembalagem.pvendaatac,0),0,nvl(pcembalagem.pvenda,0),nvl(pcembalagem.pvendaatac,0)) * decode(nvl(pcembalagem.fatorpreco, 1),0,1,nvl(pcembalagem.fatorpreco, 1))) pvendaatac,
                      (nvl(pcembalagem.pvenda,0) * decode(nvl(pcembalagem.fatorpreco, 1),0,1,nvl(pcembalagem.fatorpreco, 1))) pvendaemb,
                      (nvl(pcembalagem.poferta,0) * decode(nvl(pcembalagem.fatorpreco, 1),0,1,nvl(pcembalagem.fatorpreco, 1))) poferta,
                       pcembalagem.dtofertaini dtofertaini,
                       pcembalagem.dtofertafim dtofertafim,
                       pcembalagem.dtofertaatacini dtofertaatacini,
                       pcembalagem.dtofertaatacfim dtofertaatacfim,
                       nvl(pcembalagem.pofertaatac,0)pofertaatac,
                       pcprodut.tipocomissao,
                       pcprodut.classe,
                       pctribut.tipocalculognre,
                       nvl(pctribut.agregaripicalculost, 'N'),
                       pcprodut.importado,
                       nvl(pctribut.usavlultentmediobasest, 'N'),
                       nvl(pctabpr.vlultentmes,0)
                into vnptabela,
                     vnpauta,
                     vnaliqicms1,
                     vnaliqicms2,
                     vnvlcustofin,
                     vnvlcustoreal,
                     vniva,
                     vnaliqicms1fonte,
                     vnaliqicms2fonte,
                     vnpercbaseredst,
                     vnpercbasered,
                     vsusavalorultentbasest,
                     vsusavalorultentbasest2,
                     vnvalorultent,
                     vnpercbaseredconsumidor,
                     vsutilizapercbaseredpf,
                     vnPERCBASEREDSTFONTE,
                     vncodst,
                     vnperdesccusto,
                     vncustocont,
                     vncustorep,
                     vncodicmtab,
                     vnpcomint1,
                     vnpcomext1,
                     vnpcomrep1,
                     vncodlinhaprod,
                     vncodsec,
                     vncodepto,
                     vncodicmtabpf,
                     vnfreteespecial,
                     vsmostrarpvendasemst,
                     vsusapmcbasest,
                     vnprecomaxconsum,
                     vncustonfsemst,
                     vnperacrescismopf,
                     vsAPLICAACRESCPJISENTA,
                     vnqtminimaatacado,
                     vnqtunit,
                     vnpvendaatac,
                     vnpvendaemb,
                     vnpoferta,
                     vddtofertaini,
                     vddtofertafim,
                     vddtofertaatacini,
                     vddtofertaatacfim,
                     vnpofertaatac,
                     vstipocomissao,
                     vsclasse,
                     vstipocalculognre,
                     vsagregaripicalculost,
                     vsimportado,
                     vsusavlultentmediobasest,
                     vnvlultentmes
                from pctabpr,
                     pctribut,
                     pcest,
                     pcprodut,
                     pcembalagem
                where pctabpr.codst = pctribut.codst
                      and pctabpr.codprod = reg_itenscesta.codprodmp
                      and pcest.codprod = reg_itenscesta.codprodmp
                      and pctabpr.numregiao = p_regpedido.numregiao
                      and pcest.codfilial = p_regpedido.codfilial
                      and pctabpr.codprod = pcprodut.codprod
                      and pcembalagem.codprod = reg_itenscesta.codprodmp
                      and pcembalagem.codauxiliar = reg_itenscesta.codauxiliarmp
                      and pcembalagem.codfilial = p_regpedido.codfilial;

                  exception when others then

                 if vsmensagem is null  then

                     vsmensagem :=  ' Problema ao buscar preço do item da cesta : '||reg_itenscesta.codprodmp;

                    else

                    vsmensagem       := vsmensagem || CHR(13) || ' Problema ao buscar preço do item da cesta : '||reg_itenscesta.codprodmp;

                   end if;

                     p_valido := false;

               end;
           end if;

         --nao utiliza venda por embalagem
         else*/

              if gregpcconsum.usatributacaoporuf = 'S' then


                 select count(*)
                into vicontador
                from pctabtrib p
                where p.codprod     = reg_itenscesta.codprodmp
                and   p.codfilialnf = nvl(p_regpedido.codfilialnf,nvl(p_regcliente.codfilialnf,p_regpedido.codfilial))
                and   p.ufdestino   = p_Regcliente.estent;

                if vicontador = 0 then


                    if vsmensagem is null  then

                     vsmensagem :=  ' Nao encontrado cadastro como cesta';

                    else

                    vsmensagem       := vsmensagem || CHR(13) || ' Não encontrada tributação por estado para item da cesta';

                   end if;

                     p_valido := false;


                else

                    select p.codst
                    into vncodst
                    from pctabtrib p
                    where p.codprod     = reg_itenscesta.codprodmp
                    and   p.codfilialnf = nvl(p_regpedido.codfilialnf,nvl(p_regcliente.codfilialnf,p_regpedido.codfilial))
                    and   p.ufdestino   = p_Regcliente.estent
                    and   rownum = 1;


                begin

                select decode(p_numpr
                             ,1
                             ,pctabpr.pvenda1
                             ,2
                             ,pctabpr.pvenda2
                             ,3
                             ,pctabpr.pvenda3
                             ,4
                             ,pctabpr.pvenda4
                             ,5
                             ,pctabpr.pvenda5
                             ,6
                             ,pctabpr.pvenda6
                             ,7
                             ,pctabpr.pvenda7
                             ,0),
                       nvl(pctribut.pauta,0),
                       nvl(pctribut.aliqicms1,0),
                       nvl(pctribut.aliqicms2,0),
                       nvl(pcest.custofin,0),
                       nvl(pcest.custoreal,0),
                       nvl(pctribut.iva,0),
                       nvl(pctribut.aliqicms1fonte,0),
                       nvl(pctribut.aliqicms2fonte,0),
                       nvl(pctribut.percbaseredst,0),
                       nvl(pctribut.percbasered,0),
                       pctribut.usavalorultentbasest,
                       pctribut.usavalorultentbasest2,
                       nvl(pcest.valorultent,0),
                       nvl(pctribut.percbaseredconsumidor,0),
                       pctribut.utilizapercbaseredpf,
                       nvl(pctribut.percbaseredstfonte,0),
                       pctabpr.codst,
                       nvl(pctribut.perdesccusto,0),
                       nvl(pcest.custocont,0),
                       nvl(pcest.custorep,0),
                       pctribut.codicmtab,
                       nvl(pcprodut.pcomint1,0),
                       nvl(pcprodut.pcomext1,0),
                       nvl(pcprodut.pcomrep1,0),
                       pcprodut.codlinhaprod,
                       pcprodut.codsec,
                       pcprodut.codepto,
                       NVL(pctribut.codicmtabpf, 0),
                       pcprodut.freteespecial,
                       nvl(pctribut.mostrarpvendasemst,nvl(gregpcconsum.mostrarpvendasemst,'N')),
                       nvl(pctribut.usapmcbasest,'N'),
                       nvl(pcprodut.precomaxconsum,0) ,
                       nvl(pcest.custonfsemst,pcest.valorultent),
                       nvl(pctribut.peracrescismopf,0),
                       nvl(pctribut.aplicaacrescpjisenta,'N' ),
                       nvl(pcprodut.qtunit,1),
                       pcprodut.tipocomissao,
                       pcprodut.classe,
                       pctribut.tipocalculognre,
                       nvl(pctribut.agregaripicalculost, 'N'),
                       pcprodut.importado,
                       nvl(pctribut.usavlultentmediobasest, 'N'),
                       nvl(pctabpr.vlultentmes,0),
                       nvl(pctribut.codicmtabbonif,pctribut.codicmtab),
                       nvl(pctribut.codicmtabpfbonif,pctribut.codicmtabpf)

                into vnptabela,
                     vnpauta,
                     vnaliqicms1,
                     vnaliqicms2,
                     vnvlcustofin,
                     vnvlcustoreal,
                     vniva,
                     vnaliqicms1fonte,
                     vnaliqicms2fonte,
                     vnpercbaseredst,
                     vnpercbasered,
                     vsusavalorultentbasest,
                     vsusavalorultentbasest2,
                     vnvalorultent,
                     vnpercbaseredconsumidor,
                     vsutilizapercbaseredpf,
                     vnPERCBASEREDSTFONTE,
                     vncodst,
                     vnperdesccusto,
                     vncustocont,
                     vncustorep,
                     vncodicmtab,
                     vnpcomint1,
                     vnpcomext1,
                     vnpcomrep1,
                     vncodlinhaprod,
                     vncodsec,
                     vncodepto,
                     vncodicmtabpf,
                     vnfreteespecial,
                     vsmostrarpvendasemst,
                     vsusapmcbasest,
                     vnprecomaxconsum,
                     vncustonfsemst,
                     vnperacrescismopf,
                     vsAPLICAACRESCPJISENTA,
                     vnqtunit,
                     vstipocomissao,
                     vsclasse,
                     vstipocalculognre,
                     vsagregaripicalculost,
                     vsimportado,
                     vsusavlultentmediobasest,
                     vnvlultentmes,
                     vnCODICMTABBONIF,
                     vncodicmtabpfbonif

                from pctabpr,
                     pctribut,
                     pcest,
                     pcprodut
                where pctribut.codst  = vncodst
                  and pctabpr.codprod = reg_itenscesta.codprodmp
                  and pcest.codprod = reg_itenscesta.codprodmp
                  and pctabpr.numregiao = p_regpedido.numregiao
                  and pcest.codfilial = p_regpedido.codfilial
                  and pctabpr.codprod = pcprodut.codprod;
               exception when others then

                 if vsmensagem is null  then

                     vsmensagem :=  ' Problema ao buscar preço do item da cesta : '||reg_itenscesta.codprodmp;

                    else

                    vsmensagem       := vsmensagem || CHR(13) || ' Problema ao buscar preço do item da cesta : '||reg_itenscesta.codprodmp;

                   end if;

                     p_valido := false;

               end;

              end if;

           --Nao usa tributacao por estado
           else

             begin

                select decode(p_numpr
                             ,1
                             ,pctabpr.pvenda1
                             ,2
                             ,pctabpr.pvenda2
                             ,3
                             ,pctabpr.pvenda3
                             ,4
                             ,pctabpr.pvenda4
                             ,5
                             ,pctabpr.pvenda5
                             ,6
                             ,pctabpr.pvenda6
                             ,7
                             ,pctabpr.pvenda7
                             ,0),
                       nvl(pctribut.pauta,0),
                       nvl(pctribut.aliqicms1,0),
                       nvl(pctribut.aliqicms2,0),
                       nvl(pcest.custofin,0),
                       nvl(pcest.custoreal,0),
                       nvl(pctribut.iva,0),
                       nvl(pctribut.aliqicms1fonte,0),
                       nvl(pctribut.aliqicms2fonte,0),
                       nvl(pctribut.percbaseredst,0),
                       nvl(pctribut.percbasered,0),
                       pctribut.usavalorultentbasest,
                       pctribut.usavalorultentbasest2,
                       nvl(pcest.valorultent,0),
                       nvl(pctribut.percbaseredconsumidor,0),
                       pctribut.utilizapercbaseredpf,
                       nvl(pctribut.percbaseredstfonte,0),
                       pctabpr.codst,
                       nvl(pctribut.perdesccusto,0),
                       nvl(pcest.custocont,0),
                       nvl(pcest.custorep,0),
                       pctribut.codicmtab,
                       nvl(pcprodut.pcomint1,0),
                       nvl(pcprodut.pcomext1,0),
                       nvl(pcprodut.pcomrep1,0),
                       pcprodut.codlinhaprod,
                       pcprodut.codsec,
                       pcprodut.codepto,
                       NVL(pctribut.codicmtabpf, 0),
                       pcprodut.freteespecial,
                       nvl(pctribut.mostrarpvendasemst,nvl(gregpcconsum.mostrarpvendasemst,'N')),
                       nvl(pctribut.usapmcbasest,'N'),
                       nvl(pcprodut.precomaxconsum,0) ,
                       nvl(pcest.custonfsemst,pcest.valorultent),
                       nvl(pctribut.peracrescismopf,0),
                       nvl(pctribut.aplicaacrescpjisenta,'N' ),
                       nvl(pcprodut.qtunit,1),
                       pcprodut.tipocomissao,
                       pcprodut.classe,
                       pctribut.tipocalculognre,
                       nvl(pctribut.agregaripicalculost, 'N'),
                       pcprodut.importado,
                       nvl(pctribut.usavlultentmediobasest, 'N'),
                       nvl(pctabpr.vlultentmes,0),
                       nvl(pctribut.codicmtabbonif,pctribut.codicmtab),
                       nvl(pctribut.codicmtabpfbonif,pctribut.codicmtabpf)

                into vnptabela,
                     vnpauta,
                     vnaliqicms1,
                     vnaliqicms2,
                     vnvlcustofin,
                     vnvlcustoreal,
                     vniva,
                     vnaliqicms1fonte,
                     vnaliqicms2fonte,
                     vnpercbaseredst,
                     vnpercbasered,
                     vsusavalorultentbasest,
                     vsusavalorultentbasest2,
                     vnvalorultent,
                     vnpercbaseredconsumidor,
                     vsutilizapercbaseredpf,
                     vnPERCBASEREDSTFONTE,
                     vncodst,
                     vnperdesccusto,
                     vncustocont,
                     vncustorep,
                     vncodicmtab,
                     vnpcomint1,
                     vnpcomext1,
                     vnpcomrep1,
                     vncodlinhaprod,
                     vncodsec,
                     vncodepto,
                     vncodicmtabpf,
                     vnfreteespecial,
                     vsmostrarpvendasemst,
                     vsusapmcbasest,
                     vnprecomaxconsum,
                     vncustonfsemst,
                     vnperacrescismopf,
                     vsAPLICAACRESCPJISENTA,
                     vnqtunit,
                     vstipocomissao,
                     vsclasse,
                     vstipocalculognre,
                     vsagregaripicalculost,
                     vsimportado,
                     vsusavlultentmediobasest,
                     vnvlultentmes,
                     vnCODICMTABBONIF,
                     vncodicmtabpfbonif
                from pctabpr,
                     pctribut,
                     pcest,
                     pcprodut
                where pctabpr.codst = pctribut.codst
                      and pctabpr.codprod = reg_itenscesta.codprodmp
                      and pcest.codprod = reg_itenscesta.codprodmp
                      and pctabpr.numregiao = p_regpedido.numregiao
                      and pcest.codfilial = p_regpedido.codfilial
                      and pctabpr.codprod = pcprodut.codprod;

                exception when others then

                 if vsmensagem is null  then

                     vsmensagem :=  ' Problema ao buscar preço do item da cesta : '||reg_itenscesta.codprodmp;

                    else

                    vsmensagem       := vsmensagem || CHR(13) || ' Problema ao buscar preço do item da cesta : '||reg_itenscesta.codprodmp;

                   end if;

                     p_valido := false;

               end;

           end if;


/*         end if;


         if p_regfilial.PRECOPOREMBALAGEM = 'S' and p_regfilial.utilizavendaporembalagem = 'S' then


           --Varejo
            IF p_regfilial.tipoprecificacao <> 'A' THEN
             IF vnqtminimaatacado > 1 THEN
              IF (p_qt * reg_itenscesta.qtprodmp) >= vnqtminimaatacado THEN
                vnptabela := nvl(vnpvendaatac,vnpvendaemb)/vnqtunit;
              ELSE
                vnptabela := vnpvendaemb/vnqtunit;
              END IF;
             ELSE
               vnptabela := vnpvendaemb/vnqtunit;
             END IF;
             --Atacado
            ELSE
              vnptabela := nvl(vnpvendaatac,vnpvendaemb)/vnqtunit;

            END IF;

           --tarefa 70944 verificar poferta como preco minimo
           IF (vnpoferta > 0) AND
               trunc(SYSDATE) BETWEEN vddtofertaini AND
               vddtofertafim then

               if (p_qt * reg_itenscesta.qtprodmp) < vnqtminimaatacado then
                  vnptabela := vnpoferta/vnqtunit;
               end if;
            END IF;

            IF p_regfilial.tipoprecificacao <> 'A' THEN
             IF (vnpoferta > 0) AND
                (trunc(SYSDATE) BETWEEN vddtofertaini AND
                 vddtofertafim) THEN
              IF (p_qt * reg_itenscesta.qtprodmp) < vnqtminimaatacado then

              vnptabela := vnpoferta/vnQTUNIT;
              END IF;
             END IF;
            ELSE
             IF (vnpofertaatac > 0) AND
                (trunc(SYSDATE) BETWEEN vddtofertaatacini AND
                vddtofertaatacfim) THEN
              IF (p_qt * reg_itenscesta.qtprodmp) >= vnqtminimaatacado THEN
                vnptabela := vnpofertaatac/vnQTUNIT;
              END IF;
             END IF;
            END IF;


           end if;*/

                if nvl(vnptabela,0) = 0 then


                 if vsmensagem is null  then

                     vsmensagem :=  ' Item da cesta '|| reg_itenscesta.codprodmp ||' com preço de tabela zerado.';

                    else

                    vsmensagem       := vsmensagem || CHR(13) || ' Item da cesta '|| reg_itenscesta.codprodmp ||' com preço de tabela zerado.';

                   end if;

                     p_valido := false;


                end if;



                IF (p_regpedido.condvenda <> 3 AND p_regpedido.condvenda <> 6 AND
                   p_regpedido.condvenda <> 12) OR gregpcconsum.aplicaacrescpftv3 = 'S'
                THEN
                  IF gregpcconsum.acrescimopfcomie = 'S'
                  THEN
                    if ((((vsAPLICAACRESCPJISENTA = 'S')
                        and ((p_regcliente.IEENT = 'ISENTA')
                        or (p_regcliente.IEENT = 'ISENTO')))
                        or ((p_regcliente.TIPOFJ = 'F')
                        or (p_regcliente.CONSUMIDORFINAL = 'S')))
                        and (p_regcliente.Contribuinte = 'N')) THEN

                      vnptabela := (vnptabela + (vnptabela * vnperacrescismopf / 100));


                    END IF;
                  ELSE
                    if ((((vsAPLICAACRESCPJISENTA = 'S')
                        and ((p_regcliente.IEENT = 'ISENTA')
                        or (p_regcliente.IEENT = 'ISENTO')))
                        or (((p_regcliente.TIPOFJ = 'F')
                        or (p_regcliente.CONSUMIDORFINAL = 'S'))
                        and (Trim(p_regcliente.IEENT) = '')))
                        and (p_regcliente.Contribuinte = 'N')) then

                      vnptabela := (vnptabela + (vnptabela * vnperacrescismopf / 100));


                    END IF;
                  END IF;
                END IF;



            gvet_regitenscesta(vncount).numped := p_numped;
            gvet_regitenscesta(vncount).codprodcesta := p_codprod;
            gvet_regitenscesta(vncount).codprodmp := reg_itenscesta.codprodmp;
            gvet_regitenscesta(vncount).pvenda := vnptabela;
            gvet_regitenscesta(vncount).ptabela := vnptabela;
            gvet_regitenscesta(vncount).qt := reg_itenscesta.qtprodmp;
            gvet_regitenscesta(vncount).pauta := vnpauta;
            gvet_regitenscesta(vncount).iva := vniva;
            gvet_regitenscesta(vncount).aliqicms1 := vnaliqicms1;
            gvet_regitenscesta(vncount).aliqicms2 := vnaliqicms2;
            gvet_regitenscesta(vncount).vlcustofin := vnvlcustofin;
            gvet_regitenscesta(vncount).vlcustoreal := vnvlcustoreal;
            gvet_regitenscesta(vncount).ivafonte := vnivafonte;
            gvet_regitenscesta(vncount).aliqicms1fonte := vnaliqicms1fonte;
            gvet_regitenscesta(vncount).aliqicms2fonte := vnaliqicms2fonte;
            gvet_regitenscesta(vncount).percbaseredst := vnpercbaseredst;
            gvet_regitenscesta(vncount).percbasered := vnpercbasered;
            gvet_regitenscesta(vncount).usavalorultentbasest := vsusavalorultentbasest;
            gvet_regitenscesta(vncount).usavalorultentbasest2 := vsusavalorultentbasest2;
            gvet_regitenscesta(vncount).valorultent := vnvalorultent;
            gvet_regitenscesta(vncount).utilizapercbaseredpf := vsutilizapercbaseredpf;
            gvet_regitenscesta(vncount).PERCBASEREDSTFONTE := vnPERCBASEREDSTFONTE;
            gvet_regitenscesta(vncount).codst := vncodst;
            gvet_regitenscesta(vncount).perdesccusto :=  vnperdesccusto;
            gvet_regitenscesta(vncount).custocont :=    vncustocont;
            gvet_regitenscesta(vncount).custorep :=    vncustorep;
            gvet_regitenscesta(vncount).codicmtab :=  vncodicmtab;
            gvet_regitenscesta(vncount).pcomint1  := vnpcomint1;
            gvet_regitenscesta(vncount).pcomext1   := vnpcomext1;
            gvet_regitenscesta(vncount).pcomrep1   := vnpcomrep1;
            gvet_regitenscesta(vncount).codlinhaprod := vncodlinhaprod;
            gvet_regitenscesta(vncount).codsec := vncodsec;
            gvet_regitenscesta(vncount).codepto := vncodepto;
            gvet_regitenscesta(vncount).codicmtabpf :=  vncodicmtabpf;
            gvet_regitenscesta(vncount).freteespecial := vnfreteespecial;
            gvet_regitenscesta(vncount).mostrarpvendasemst := vsmostrarpvendasemst;
            gvet_regitenscesta(vncount).usapmcbasest := vsusapmcbasest;
            gvet_regitenscesta(vncount).precomaxconsum := vnprecomaxconsum;
            gvet_regitenscesta(vncount).custonfsemst := vncustonfsemst;
            gvet_regitenscesta(vncount).codauxiliar := reg_itenscesta.codauxiliarmp;
            gvet_regitenscesta(vncount).tipocomissao := vstipocomissao;
            gvet_regitenscesta(vncount).classe := vsclasse;
            gvet_regitenscesta(vncount).tipocalculognre := vstipocalculognre;
            gvet_regitenscesta(vncount).usavlultentmediobasest := vsusavlultentmediobasest;
            gvet_regitenscesta(vncount).vlultentmes := vnvlultentmes;
            gvet_regitenscesta(vncount).agregaripicalculost := vsagregaripicalculost;
            gvet_regitenscesta(vncount).importado := vsimportado;

            if ((p_regcliente.tipoempresa = 'R') or
                (p_regcliente.orgaopub = 'S') or
                (p_regcliente.USADESCONTOICMS = 'S') or
                (p_regcliente.orgaopubfederal = 'S') or
                (p_regcliente.suframa is not null)) then

                vbClienteAplicaReducoesTrib := true;
            else
               vbClienteAplicaReducoesTrib := false;
            end if;

            vsDEDUZIRPISCOFINSICMSDOCMV := p_regfiliaL.DEDUZIRPISCOFINSICMSDOCMV;

            IF ((NOT vbClienteAplicaReducoesTrib) OR
              ((vbClienteAplicaReducoesTrib) AND (vsDEDUZIRPISCOFINSICMSDOCMV = 'N')) ) THEN
              gvet_regitenscesta(vncount).codicmtab := vnCODICMTABBONIF;
              gvet_regitenscesta(vncount).codicmtabpf := vncodicmtabpfbonif;
            END IF;


          end loop;

          --preco fixo cesta básica
          proc_verificaprecofixocesta(p_codprod,
                                      p_regpedido,
                                      p_regcliente,
                                      vsmensagemprecofixocesta,
                                      vbvalidoprecofixocesta);




        end if;

        if trim(vsmensagemcesta) is not null
        then

          if vsmensagem is null
          then
            vsmensagem := vsmensagemcesta;

          else
            vsmensagem       := vsmensagem || CHR(13) || vsmensagemcesta;
          end if;

          p_valido := false;

        end if;

        if trim(vsmensagemprecofixocesta) is not null
        then

          if vsmensagem is null
          then
            vsmensagem := vsmensagemprecofixocesta;

          else
            vsmensagem := vsmensagem || CHR(13) || vsmensagemprecofixocesta;

          end if;

          p_valido := false;

        end if;


   p_ptabela := vnptabelacesta;


end;

procedure proc_buscaprecoitem(p_regitempedbrinde   in t_itempedbrinde,
                              p_tipomerc           in pcprodut.tipomerc%type,
                              p_regpedido          in t_pedido,
                              p_regregiao          in t_regiao,
                              p_regcliente         in t_cliente,
                              p_regfilial          in t_filial,
                              p_regprecos          out t_precosetributacao,
                              p_valido          in out boolean,
                              p_mensagem           out varchar2)  is


viconttabtrib         number;
vbvalido              boolean;
vsmensagem            varchar2(1000);
vncodst               pctribut.codst%type;


begin

vbvalido := p_valido;

if p_tipomerc <> 'CB' then


             if gregpcconsum.usatributacaoporuf = 'S' then


                 select count(*)
                into viconttabtrib
                from pctabtrib p
                where p.codprod     = p_regitempedbrinde.codprod
                and   p.codfilialnf = nvl(p_regpedido.codfilialnf,nvl(p_regcliente.codfilialnf,p_regpedido.codfilial))
                and   p.ufdestino   = p_Regcliente.estent;

                if viconttabtrib = 0 then


                   if vsmensagem is null then

                       vsmensagem := 'Não encontrada tributação por estado para o brinde :' || CHR(13)||
                       p_regitempedbrinde.codprod ||' '||p_regitempedbrinde.descricao|| CHR(13);
                    else

                        vsmensagem := vsmensagem||CHR(13)||'Não encontrada tributação por estado para item.' || CHR(13)||
                        p_regitempedbrinde.codprod ||' '||p_regitempedbrinde.descricao|| CHR(13);
                    end if;

                    vbvalido := false;


                else

                    select p.codst
                    into vncodst
                    from pctabtrib p
                    where p.codprod     = p_regitempedbrinde.codprod
                    and   p.codfilialnf = nvl(p_regpedido.codfilialnf,nvl(p_regcliente.codfilialnf,p_regpedido.codfilial))
                    and   p.ufdestino   = p_Regcliente.estent
                    and   rownum = 1;

                  begin
                    select nvl(pctribut.aliqicms1, 0),
                           nvl(pctribut.aliqicms2, 0),
                           nvl(pctribut.codicmtab, 0),
                           pctribut.codst,
                           nvl(pcest.custocont, 0),
                           nvl(pcest.custofin, 0),
                           nvl(pcest.custoreal, 0),
                           nvl(pcest.custorep, 0),
                           nvl(pcest.custoultent, 0),
                           nvl(pctabpr.excluido, 'N'),
                           nvl(pctribut.iva, 0),
                           nvl(pctribut.pauta, 0),
                           nvl(pctribut.peracrescismopf, 0),
                           nvl(pctabpr.perdescautor, 0),
                           nvl(pctribut.perdesccusto, 0),
                           nvl(pctabpr.perdescmax, 0),
                           nvl(pctabpr.perdescmaxesp, 0),
                           pctribut.perdestab,
                           nvl(pctabpr.precominimovenda, 0),
                           nvl(pctabpr.pvenda, 0),
                           nvl(pctabpr.pvenda1, 0),
                           nvl(pctabpr.pvenda2, 0),
                           nvl(pctabpr.pvenda3, 0),
                           nvl(pctabpr.pvenda4, 0),
                           nvl(pctabpr.pvenda5, 0),
                           nvl(pctabpr.pvenda6, 0),
                           nvl(pctabpr.pvenda7, 0),
                           nvl(pctabpr.qtdescautor, 0),
                           nvl(pctribut.aplicaacrescpjisenta, 'N'),
                           nvl(pctribut.percbaseredst, 0),
                           nvl(pctribut.tipocalculognre, 'P'),
                           NVL(pctribut.ivafonte, 0),
                           NVL(pctribut.aliqicms1fonte, 0),
                           NVL(pctribut.aliqicms2fonte, 0),
                           NVL(pctribut.percbaseredstfonte, 0),
                           nvl(pctribut.percbasered, 0),
                           nvl(pctribut.perbaserednrpa, 0),
                           nvl(pctribut.percbaseredconsumidor, 0),
                           nvl(utilizapercbaseredpf, 'N'),
                           pcest.valorultent,
                           nvl(pctribut.usavalorultentbasest, 'N'),
                           nvl(pctribut.usavalorultentbasest2, 'N'),
                           NVL(pctribut.codicmtabpf, 0),
                           nvl(pctribut.perdescsuframa, 0),
                           nvl(pctribut.perdescicmisencao, 0),
                           pctabpr.descontafrete,
                           nvl(pctribut.percdescpis, 0),
                           nvl(pctribut.percdesccofins, 0),
                           nvl(pctribut.perdescrepasse,0)  ,
                           nvl(pctabpr.precomaxconsum,0) ,
                           1 ,
                           1,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0,
                           null,
                           null,
                           null,
                           null,
                           0 ,
                            nvl(pctribut.mostrarpvendasemst,gregpcconsum.mostrarpvendasemst),
                           nvl(pctribut.usapmcbasest,'N'),
                           nvl(pcest.custonfsemst,nvl(pcest.valorultent,0)),
                           nvl(pctribut.percredpvendasimplesnac,0),
                           nvl(pcest.vlstultent,0),
                           nvl(pctribut.percdifaliquotas,0),
                           nvl(pcest.custonfsemstguiaultent,0),
                           nvl(pcest.ivaultent,0),
                           nvl(pcest.aliqicms1ultent,0),
                           nvl(pcest.aliqicms2ultent,0),
                           nvl(pcest.redbaseivaultent,100),
                           nvl(pcest.percicmsfretefobstultent,0),
                           nvl(pcest.vlfreteconhecultent,0),
                           nvl(pcest.percaliqextguiaultent,0),
                           nvl(pcest.baseicmsultent,0),
                           nvl(pcest.vlstguiaultent,0),
                           nvl(pctribut.usaisencaoicmsvp,'S'),
                           nvl(pctribut.usavlultentmediobasest, 'N'),
                           nvl(pctabpr.vlultentmes,0),
                           nvl(pctribut.codicmtabbonif, pctribut.codicmtab),
                           nvl(pctribut.codicmtabpfbonif,pctribut.codicmtabpf),
                           nvl(pctribut.pagtonomedocliente,'N'),
                           nvl(pctabpr.vlst,0)
                      into p_regprecos
                      from pctabpr, pctribut, pcest
                     where pctribut.codst = vncodst
                       and pctabpr.codprod = p_regitempedbrinde.codprod
                       and pcest.codprod = p_regitempedbrinde.codprod
                       and pctabpr.numregiao = p_regpedido.numregiao
                       and pcest.codfilial = decode(p_regfilial.origemcustofilialretira,'V',p_regpedido.codfilial,p_Regitempedbrinde.codfilialretira);
                  exception
                    when others then


                   if vsmensagem is null then

                       vsmensagem := 'Erro ao buscar preço do brinde : ' ||
                                       p_regitempedbrinde.codprod ||' '||p_regitempedbrinde.descricao|| CHR(13)||
                                       SQLCODE||' '||SQLERRM||CHR(13);
                    else

                        vsmensagem := vsmensagem||CHR(13)||'Erro ao buscar preço do brinde : ' ||
                                       p_regitempedbrinde.codprod||' '||p_regitempedbrinde.descricao||CHR(13)||
                                       SQLCODE||SQLERRM||CHR(13);
                    end if;


                      vbvalido := false;
                  end;

              end if;

            --nao usa tributacao por uf
            else

                              begin
                    select nvl(pctribut.aliqicms1, 0),
                           nvl(pctribut.aliqicms2, 0),
                           nvl(pctribut.codicmtab, 0),
                           pctabpr.codst,
                           nvl(pcest.custocont, 0),
                           nvl(pcest.custofin, 0),
                           nvl(pcest.custoreal, 0),
                           nvl(pcest.custorep, 0),
                           nvl(pcest.custoultent, 0),
                           nvl(pctabpr.excluido, 'N'),
                           nvl(pctribut.iva, 0),
                           nvl(pctribut.pauta, 0),
                           nvl(pctribut.peracrescismopf, 0),
                           nvl(pctabpr.perdescautor, 0),
                           nvl(pctribut.perdesccusto, 0),
                           nvl(pctabpr.perdescmax, 0),
                           nvl(pctabpr.perdescmaxesp, 0),
                           pctribut.perdestab,
                           nvl(pctabpr.precominimovenda, 0),
                           nvl(pctabpr.pvenda, 0),
                           nvl(pctabpr.pvenda1, 0),
                           nvl(pctabpr.pvenda2, 0),
                           nvl(pctabpr.pvenda3, 0),
                           nvl(pctabpr.pvenda4, 0),
                           nvl(pctabpr.pvenda5, 0),
                           nvl(pctabpr.pvenda6, 0),
                           nvl(pctabpr.pvenda7, 0),
                           nvl(pctabpr.qtdescautor, 0),
                           nvl(pctribut.aplicaacrescpjisenta, 'N'),
                           nvl(pctribut.percbaseredst, 0),
                           nvl(pctribut.tipocalculognre, 'P'),
                           NVL(pctribut.ivafonte, 0),
                           NVL(pctribut.aliqicms1fonte, 0),
                           NVL(pctribut.aliqicms2fonte, 0),
                           NVL(pctribut.percbaseredstfonte, 0),
                           nvl(pctribut.percbasered, 0),
                           nvl(pctribut.perbaserednrpa, 0),
                           nvl(pctribut.percbaseredconsumidor, 0),
                           nvl(utilizapercbaseredpf, 'N'),
                           pcest.valorultent,
                           nvl(pctribut.usavalorultentbasest, 'N'),
                           nvl(pctribut.usavalorultentbasest2, 'N'),
                           NVL(pctribut.codicmtabpf, 0),
                           nvl(pctribut.perdescsuframa, 0),
                           nvl(pctribut.perdescicmisencao, 0),
                           pctabpr.descontafrete,
                           nvl(pctribut.percdescpis, 0),
                           nvl(pctribut.percdesccofins, 0),
                           nvl(pctribut.perdescrepasse,0)  ,
                           nvl(pctabpr.precomaxconsum,0) ,
                           1 ,
                           1,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0,
                           null,
                           null,
                           null,
                           null,
                           0 ,
                            nvl(pctribut.mostrarpvendasemst,gregpcconsum.mostrarpvendasemst),
                           nvl(pctribut.usapmcbasest,'N'),
                           nvl(pcest.custonfsemst,nvl(pcest.valorultent,0)),
                           nvl(pctribut.percredpvendasimplesnac,0),
                           nvl(pcest.vlstultent,0),
                           nvl(pctribut.percdifaliquotas,0),
                           nvl(pcest.custonfsemstguiaultent,0),
                           nvl(pcest.ivaultent,0),
                           nvl(pcest.aliqicms1ultent,0),
                           nvl(pcest.aliqicms2ultent,0),
                           nvl(pcest.redbaseivaultent,100),
                           nvl(pcest.percicmsfretefobstultent,0),
                           nvl(pcest.vlfreteconhecultent,0),
                           nvl(pcest.percaliqextguiaultent,0),
                           nvl(pcest.baseicmsultent,0),
                           nvl(pcest.vlstguiaultent,0),
                           nvl(pctribut.usaisencaoicmsvp,'S'),
                           nvl(pctribut.usavlultentmediobasest, 'N'),
                           nvl(pctabpr.vlultentmes,0),
                           nvl(pctribut.codicmtabbonif, pctribut.codicmtab),
                           nvl(pctribut.codicmtabpfbonif,pctribut.codicmtabpf),
                           nvl(pctribut.pagtonomedocliente,'N'),
                           nvl(pctabpr.vlst,0)
                      into p_regprecos
                      from pctabpr, pctribut, pcest
                     where pctabpr.codst = pctribut.codst
                       and pctabpr.codprod = p_regitempedbrinde.codprod
                       and pcest.codprod = p_regitempedbrinde.codprod
                       and pctabpr.numregiao = p_regpedido.numregiao
                       and pcest.codfilial = decode(p_regfilial.origemcustofilialretira,'V',p_regpedido.codfilial,p_Regitempedbrinde.codfilialretira);
                  exception
                    when others then


                   if vsmensagem is null then

                       vsmensagem := 'Erro ao buscar preço do brinde : ' ||
                                       p_regitempedbrinde.codprod ||' '||p_regitempedbrinde.descricao|| CHR(13)||
                                       SQLCODE||' '||SQLERRM||CHR(13);
                    else

                        vsmensagem := vsmensagem||CHR(13)||'Erro ao buscar preço do brinde : ' ||
                                       p_regitempedbrinde.codprod||' '||p_regitempedbrinde.descricao||CHR(13)||
                                       SQLCODE||SQLERRM||CHR(13);
                    end if;


                      vbvalido := false;
                  end;


            end if;

        --cesta
       else

            begin

            select nvl(pctribut.aliqicms1, 0),
                   nvl(pctribut.aliqicms2, 0),
                   nvl(pctribut.codicmtab, 0),
                   pctabpr.codst,
                   nvl(pcest.custocont, 0),
                   nvl(pcest.custofin, 0),
                   nvl(pcest.custoreal, 0),
                   nvl(pcest.custorep, 0),
                   nvl(pcest.custoultent, 0),
                   nvl(pctabpr.excluido, 'N'),
                   nvl(pctribut.iva, 0),
                   nvl(pctribut.pauta, 0),
                   nvl(pctribut.peracrescismopf, 0),
                   nvl(pctabpr.perdescautor, 0),
                   nvl(pctribut.perdesccusto, 0),
                   nvl(pctabpr.perdescmax, 0),
                   nvl(pctabpr.perdescmaxesp, 0),
                   pctribut.perdestab,
                   nvl(pctabpr.precominimovenda, 0),
                   nvl(pctabpr.pvenda, 0),
                   nvl(pctabpr.pvenda1, 0),
                   nvl(pctabpr.pvenda2, 0),
                   nvl(pctabpr.pvenda3, 0),
                   nvl(pctabpr.pvenda4, 0),
                   nvl(pctabpr.pvenda5, 0),
                   nvl(pctabpr.pvenda6, 0),
                   nvl(pctabpr.pvenda7, 0),
                   nvl(pctabpr.qtdescautor, 0),
                   nvl(pctribut.aplicaacrescpjisenta, 'N'),
                   nvl(pctribut.percbaseredst, 0),
                   nvl(pctribut.tipocalculognre, 'P'),
                   NVL(pctribut.ivafonte, 0),
                   NVL(pctribut.aliqicms1fonte, 0),
                   NVL(pctribut.aliqicms2fonte, 0),
                   NVL(pctribut.percbaseredstfonte, 0),
                   nvl(pctribut.percbasered, 0),
                   nvl(pctribut.perbaserednrpa, 0),
                   nvl(pctribut.percbaseredconsumidor, 0),
                   nvl(utilizapercbaseredpf, 'N'),
                   pcest.valorultent,
                   nvl(pctribut.usavalorultentbasest, 'N'),
                   nvl(pctribut.usavalorultentbasest2, 'N'),
                   NVL(pctribut.codicmtabpf, 0),
                   nvl(pctribut.perdescsuframa, 0),
                   nvl(pctribut.perdescicmisencao, 0),
                   pctabpr.descontafrete,
                   nvl(pctribut.percdescpis, 0),
                   nvl(pctribut.percdesccofins, 0),
                   nvl(pctribut.perdescrepasse,0)  ,
                   nvl(pctabpr.precomaxconsum,0) ,
                   1 ,
                   1,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   0,
                   null,
                   null,
                   null,
                   null,
                   0 ,
                    nvl(pctribut.mostrarpvendasemst,gregpcconsum.mostrarpvendasemst),
                   nvl(pctribut.usapmcbasest,'N'),
                   nvl(pcest.custonfsemst,nvl(pcest.valorultent,0)),
                   nvl(pctribut.percredpvendasimplesnac,0),
                   nvl(pcest.vlstultent,0),
                   nvl(pctribut.percdifaliquotas,0),
                   nvl(pcest.custonfsemstguiaultent,0),
                   nvl(pcest.ivaultent,0),
                   nvl(pcest.aliqicms1ultent,0),
                   nvl(pcest.aliqicms2ultent,0),
                   nvl(pcest.redbaseivaultent,100),
                   nvl(pcest.percicmsfretefobstultent,0),
                   nvl(pcest.vlfreteconhecultent,0),
                   nvl(pcest.percaliqextguiaultent,0),
                   nvl(pcest.baseicmsultent,0),
                   nvl(pcest.vlstguiaultent,0),
                   nvl(pctribut.usaisencaoicmsvp,'S'),
                   nvl(pctribut.usavlultentmediobasest, 'N'),
                   nvl(pctabpr.vlultentmes,0),
                   nvl(pctribut.codicmtabbonif, pctribut.codicmtab),
                   nvl(pctribut.codicmtabpfbonif,pctribut.codicmtabpf),
                   nvl(pctribut.pagtonomedocliente,'N'),
                   nvl(pctabpr.vlst,0)
              into p_regprecos
              from pctabpr, pctribut, pcest
            where  pctabpr.codst = pctribut.codst(+)
              and  pcest.codprod = pctabpr.codprod(+)
              and pcest.codprod = p_regitempedbrinde.codprod
              and p_regpedido.numregiao = pctabpr.numregiao(+)
              and pcest.codfilial = decode(p_regfilial.origemcustofilialretira,'V',p_regpedido.codfilial,p_Regitempedbrinde.codfilialretira);
          exception
            when others then


           if vsmensagem is null then

               vsmensagem := 'Erro ao buscar preço do brinde : ' ||
                               p_regitempedbrinde.codprod ||' '||p_regitempedbrinde.descricao|| CHR(13)||
                               SQLCODE||' '||SQLERRM||CHR(13);
            else

                vsmensagem := vsmensagem||CHR(13)||'Erro ao buscar preço do brinde : ' ||
                              p_regitempedbrinde.codprod||' '||p_regitempedbrinde.descricao||CHR(13)||
                               SQLCODE||SQLERRM||CHR(13);
            end if;


              vbvalido := false;
          end;


       end if;

   p_mensagem := vsmensagem;
   p_valido   := vbvalido;


end proc_buscaprecoitem;

procedure proc_validapoliticas (p_regitempedbrinde   in     t_itempedbrinde,
                                p_regpedido          in     t_pedido,
                                p_regfilial          in     t_filial,
                                p_regcliente         in     t_cliente,
                                p_regrca             in     t_rca,
                                p_codprodprinc       in     pcprodut.codprodprinc%type,
                                p_codplpag           in     pcplpag.codplpag%type,
                                p_numdias            in     pcplpag.numdias%type,
                                p_pertxfim           in     pcplpag.pertxfim%type,
                                p_ptabela            in out pcpedi.ptabela%type,
                                p_pbaserca           in out pcpedi.pbaserca%type,
                                p_mensagem              out varchar2) is



    vsmensagempolitica           varchar2(1000);
    vbexistepolitica             boolean;
    vsbasecreddebrca             pcdesconto.basecreddebrca%type;
    vnpercdescpolitica_acres     pcdesconto.percdesc%type;
    vnppolitica                  pcpedi.ptabela%type;
    vsalteraptabela              pcdesconto.alteraptabela%type;
    vsmensagemprecofixo          varchar2(1000);
    vsaplicadescontosimples      pcdesconto.aplicadescsimplesnacional%type;
    vbvalidoprecofixo            boolean;
    vnppolitica_pbaserca         pcpedi.ptabela%type;
    vscreditasobrepolitica       pcdesconto.creditasobrepolitica%type;
    vddtfim                      pcdesconto.dtfim%type;
    vnpercdescpolitica           pcdesconto.percdesc%type;
    vnpercpbaserca               pcdesconto.percdesc%type;
    vnprecofixo                  pcprecoprom.precofixo%type;
    vsprioritaria                varchar2(2);
    vsquestionaprioritaria       pcdesconto.questionausoprioritaria%type;
    vncodpolpbaserca_561         pcdesconto.coddesconto%type;


begin



          vsmensagempolitica := 'S'; --indica para usar politica prioritaria

         vbexistepolitica := funcoesvendas.validarpoliticasdesconto(p_regitempedbrinde.codprod
                                                                ,p_regpedido.DATA
                                                                ,p_regpedido.codfilial
                                                                ,p_regpedido.numregiao
                                                                ,p_regpedido.codcli
                                                                ,p_regpedido.codusur
                                                                ,p_regpedido.origemped
                                                                ,p_codprodprinc
                                                                ,gregpcconsum.numcasasdecvenda
                                                                ,p_codplpag
                                                                ,gregpcconsum.tratarrestricaoacrescimo
                                                                ,p_regcliente.classevenda
                                                                ,1
                                                                ,p_numdias
                                                                ,vddtfim
                                                                ,vsmensagempolitica
                                                                ,vnpercdescpolitica
                                                                ,vsbasecreddebrca
                                                                ,vscreditasobrepolitica
                                                                ,vnpercdescpolitica_acres
                                                                ,vsalteraptabela
                                                                ,vnpercpbaserca
                                                                ,vsprioritaria
                                                                ,vsquestionaprioritaria
                                                                ,p_regfilial.naousarautdebcredpoldesc
                                                                ,null
                                                                ,null
                                                                ,vncodpolpbaserca_561);




            if NVL(vsbasecreddebrca, 'N') = 'S'
            then


                vnppolitica_pbaserca := (ROUND(p_ptabela,
                                      gregpcconsum.numcasasdecvenda)) *
                               (1 - (vnpercpbaserca / 100));
                vnppolitica_pbaserca := ROUND(vnppolitica_pbaserca,
                                     gregpcconsum.numcasasdecvenda);


                if nvl(vscreditasobrepolitica, 'S') = 'N' and p_ptabela > nvl(vnppolitica_pbaserca, 0)
                then
                  p_pbaserca := p_ptabela;
                else
                  p_pbaserca := vnppolitica_pbaserca;

                end if;



             end if;

             if nvl(vnpercdescpolitica_acres,0) > 0 then

                    vnppolitica := (ROUND(p_ptabela,
                                    gregpcconsum.numcasasdecvenda)) *
                             (1 + (vnpercdescpolitica_acres / 100));
                   vnppolitica := ROUND(vnppolitica,
                                   gregpcconsum.numcasasdecvenda);


             end if;

             if NVL(vnpercdescpolitica, 0) > 0 then
                vnppolitica := (ROUND(p_ptabela,
                                      gregpcconsum.numcasasdecvenda)) *
                               (1 - (vnpercdescpolitica / 100));
                vnppolitica := ROUND(vnppolitica,
                                     gregpcconsum.numcasasdecvenda);

             end if;

            if vsalteraptabela = 'S' then

              p_ptabela := NVL(vnppolitica, p_ptabela);


            end if;


    --preco fixo

      vsmensagemprecofixo := null;

      vsAPLICADESCONTOSIMPLES := 'S';

      vbvalidoprecofixo   := funcoesvendas.validarpoliticaprecofixo(p_regitempedbrinde.codprod,
                                                                    p_regpedido.DATA,
                                                                    p_regpedido.numregiao,
                                                                    p_regpedido.codcli,
                                                                    p_regpedido.condvenda,
                                                                    p_regpedido.codplpag,
                                                                    p_ptabela,
                                                                    gregpcconsum.validapvendabonific,
                                                                    gregpcconsum.utilizapercfinprecoprom,
                                                                    p_pertxfim,
                                                                    p_numdias,
                                                                    p_regcliente.codcliprinc,
                                                                    p_codprodprinc,
                                                                    p_regcliente.codpraca,
                                                                    p_regpedido.codusur,
                                                                    p_regrca.codsupervisor,
                                                                    null,
                                                                    p_regpedido.origemped,
                                                                    p_regcliente.codatv1,
                                                                    vddtfim,
                                                                    vsmensagemprecofixo,
                                                                    vnprecofixo,
                                                                    p_regpedido.codfilial,
                                                                    'N',--p_regfilial.validarprecovendatv20,
                                                                    p_regfilial.broker,
                                                                    p_regfilial.utilizavendaporembalagem,
                                                                    p_regfilial.precoporembalagem,
                                                                    p_codplpag);

      if vbvalidoprecofixo = true then

        p_ptabela          := vnprecofixo;
        p_pbaserca         := vnprecofixo;


       end if;

        if vsmensagemprecofixo is not null then

           if vsmensagempolitica is not null and vsmensagempolitica not in ('S','N') then
              p_mensagem := vsmensagempolitica ||CHR(13)||vsmensagemprecofixo;
           else
               p_mensagem := vsmensagemprecofixo;
           end if;
        end if;




end proc_validapoliticas;

procedure proc_apurarcampanha  (p_numped          in pcpedc.numped%type,
                                p_codfilialretira in pcpedc.codfilial%type,   --utilizado quando o força envia no pedido original a filial que deve retirar o estoque dos itens
                                p_cgccli          in pcclient.cgcent%type,    --obrigatorio apenas para pedidos do força de vendas
                                p_numseq          in number,
                                p_integradora     in varchar2,
                                p_mensagem        out varchar2,
                                p_geroubrinde     out varchar2) is

    p_regprecos               t_precosetributacao;
    p_regpedido               t_pedido;
    p_regrca                  t_rca;
    p_regcliente              t_cliente;
    p_regplpag                t_planodepagamento;
    p_regfilial               t_filial;
    p_regregiao               t_regiao;
    p_regproduto              t_produto;
    vtITEM_PRECOS             T_PRECOSIMPOSTOS;

    vs_movest                 varchar2(4000);
    msgest                    varchar2(4000);

    vicontador                number;
    vnqtprodmax               number;
    vnqtprodzero              number;
    vnnumseq                  number;
    vnqtbrinde                number;
    vncodauxiliar             number;
    vnqtminbrinde             number;
    vnqtvenda                 number;
    vnqt                      number;
    vnqtunit                  number;
    vnqtprod                  number;
    vnqtdispbrinde            number;
    vnnumitensbonific         number;
    vnproxnumped              pcusuari.proxnumped%type;
    vncontitensvalidos        number;
    vnvltotped                number := 0;
    vnvltottab                number;
    vnvlcustocontped          number := 0;
    vnvlcustofinped           number := 0;
    vnvlcustorealped          number;
    vnvlcustorepped           number := 0;
    vnvlcustocont             number;
    vnvlcustorep              number;
    vnvlcustofin              number;
    vnvlcustofinest           number;
    vnvlcustoreal             number;
    vnptabela                 number;
    VTOTALBONIFIC             number;
    vnst                      pcpedi.st%type;
    vnvltotpesoped            pcpedc.totpeso%type := 0;
    vnvltotvolumeped          pcpedc.totvolume%type := 0;
    vsmensagem_st             varchar2(1000);
    vbcalculast_valido        boolean;
    vnbaseicst                pcpedi.baseicst%type;
    vnbaseicst_fonte          pcpedi.baseicst%type;
    vnstfonte                 pcpedi.st%type;
    vsmensagem_stfonte        varchar2(1000);
    vniva                     pcpedi.iva%type;
    vnpauta                   pcpedi.pauta%type;
    vnaliqicms1               pcpedi.aliqicms1%type;
    vnaliqicms2               pcpedi.aliqicms2%type;
    vnpercbaseredst           pcpedi.percbaseredst%type;
    vnpercbaseredstfonte      pcpedi.percbaseredstfonte%type;
    vsmensagem_rest           varchar2(300);
    vbvalido                  boolean;
    vicont                    number;
    vncodplpag                pcplpag.codplpag%type;
    vnnumpr                   pcplpag.numpr%type;
    vnnumdias                 pcplpag.numdias%type;
    vnprazo1                  pcplpag.prazo1%type;
    vnprazo2                  pcplpag.prazo2%type;
    vnprazo3                  pcplpag.prazo3%type;
    vnprazo4                  pcplpag.prazo4%type;
    vnprazo5                  pcplpag.prazo5%type;
    vnprazo6                  pcplpag.prazo6%type;
    vnprazo7                  pcplpag.prazo7%type;
    vnprazo8                  pcplpag.prazo8%type;
    vnprazo9                  pcplpag.prazo9%type;
    vnprazo10                 pcplpag.prazo10%type;
    vnprazo11                 pcplpag.prazo11%type;
    vnprazo12                 pcplpag.prazo12%type;
    vstipovenda               pcplpag.tipovenda%type;
    vsuffilialnf              pcfilial.uf%type;
    vnvlipi                   pcpedi.vlipi%type;
    vnpercipi                 pcpedi.percipi%type;
    vnpercipivenda            pcprodut.percipivenda%type;
    vnvldescsuframa           pcpedi.vldescsuframa%type;
    vnperdescisentoicms       pcpedi.perdescisentoicms%type;
    vnvldescicmisencao        pcpedi.vldescicmisencao%type;
    vncondvenda               pcpedc.condvenda%type;
    vinaoexistemix            number := 0;
    vnnumcampanha             number;
    vncontcampanha            number;
    vsdescricao               pcprodut.descricao%type;
    vicontzeropcpromi         number := 0;
    vicontpcpromi             number := 0;
    vnqtpedido                number;
    vnqttotitens              number;
    vnvltotitens              number;
    vnqttotalitens            number;

    vnvlmaxfaixafornec        number;
    vnvlminmaiorfaixafornec   number;
    vicont2                   number;
    vscodfilialretira         pcpedi.codfilialretira%type;
    vnqtlimite                number;
    vnqtbrindeutil            number;
    vnqtsaldo                 number;
    vbnaoatende               boolean;
    vnqtvendida               number;
    vnvltotitensrest          number;
    vnqtprodrest              number;
    vsposicao                 pcpedc.posicao%type;

    vsmensagem                varchar2(32000);
    vsmensagemresttransp      varchar2(32000);

    vnvlsaldoped              number;
    vnvldisponivel            number;
    vbsaldorca                boolean;
    vbvalidocesta             boolean;
    vncustofinest             pcpedi.custofinest%type;
    viconttabtrib             number;
    vnstclientegnre           pcpedi.stclientegnre%type;
    vnpbaserca                pcpedi.pbaserca%type;
    vsmensagempolitica        varchar2(1000);
    vnpertxfim                pcplpag.pertxfim%type;
    vsmensagemprecoitem       varchar2(1000);
    vnqtdispbrindecont        number;
    vnqttotprod               number;

    viexisterestref           number;
    viexisterest              number;
    vnreprocessarbrinde       number;

    vsauxpedido               pcpedc.numped%TYPE;

    vncodbnf pctipobonific.codbnf%TYPE;
    vnQtPadrao number(5,0);

    /* ICMS PARTILHA */
    tICMSPARTILHA tipo_icms_partilha;
    vsMSGPartilha varchar2(1000);
    vnCodMSGPartilha number;
    vsufEnt varchar2(2);

    T_PCPEDI                     PCPEDI%ROWTYPE;
    T_PCPEDC                     PCPEDC%ROWTYPE;
    VNSITTRIBUT               NUMBER;
    VNCODFISCAL               NUMBER;
    vsmensagemcodfiscal       varchar2(1000);
    vnCONTACODPRODSEMEST      NUMBER := 0;
    vbClienteAplicaReducoesTrib boolean;
    vsDEDUZIRPISCOFINSICMSDOCMV varchar2(1);
    vsBLOQUEIAVENDAESTPENDENTE  VARCHAR2(1);
    iTentativa                NUMBER;
    erro_PROXNUMPEDZERADO     EXCEPTION;
    vnQtNoPedido              PCPEDI.QT%TYPE;

    TYPE reg_brinde_dinamico IS RECORD (
      codbrinde pcprodut.codprod%type,
      codcamp   pcpedc.numped%TYPE,
      embalagem pcprodut.embalagem%type,
      qtde PCPEDI.QT%TYPE,
      descricao pcprodut.descricao%type,
      usadebcredrca VARCHAR2(1),
      grpregrabrinde NUMBER
    );

    l_cursor_brindex   SYS_REFCURSOR;

    reg_brindeex   reg_brinde_dinamico;

    vsMeuSqlDinamicoBrindes   varchar2(4000);
    vsSOMAQTPEDVENDA VARCHAR2(1);
    vsaceitavendafracao     pcprodfilial.aceitavendafracao%type;
    vsRegraQuem             varchar2(10);
	vnqtbrindefv            NUMBER;
	vbgerarbrindefv         BOOLEAN;

  begin

    gvet_regitempedbrinde.delete;
    gvet_regcampanha.delete;
    gvet_regitenscesta.delete;

    vsmensagem := null;
    p_geroubrinde := null;


    vnnumseq          := p_numseq;
    vnnumitensbonific := 0;
    vnnumcampanha     := 0;
    vncontcampanha    := 0;

    vnreprocessarbrinde := 0;
   vsSOMAQTPEDVENDA := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_SOMAQTPEDVENDA','99','N');
   vsBLOQUEIAVENDAESTPENDENTE := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_BLOQUEIAVENDAESTPENDENTE','99','N');
   proc_buscadados(p_numped,
                  p_regpedido,
                  p_regrca,
                  p_regcliente,
                  p_regplpag,
                  p_regfilial,
                  p_regregiao,
                  vsmensagem);


    begin

      for cr_pcpromc in (select pcpromc.codigo,
                                nvl(pcpromc.produtoprinc, 'N') produtoprinc,
                                nvl(pcpromc.tipocampanha, 'QT') tipocampanha,
                                pcpromc.codfornec,
                                pcpromc.codprod,
                                pcpromc.grupocampanha,
                                pcpromc.qttotvenda,
                                pcpromc.vltotvenda,
                                pcpromc.multiplo,
                                pcpromc.qtbrinde,
                                pcpromc.variosbrinde,
                                nvl(pcpromc.obrigavendamix, 'N') obrigavendamix,
                                pcpromc.vltotvendamax,
                                nvl(pcpromc.qtlimitebrinde,0) qtlimitebrinde,
                                pcpromc.restricaovalormin,
                                pcpromc.restricaoqtmin,
                                 nvl(pcpromc.usadebcredrcabrind,'N')usadebcredrcabrind
                           from pcpromc
                          where ((exists
                                 (select 'x'
                                     from pcpromcregiao
                                    where PCPROMC.Codigo =
                                          pcpromcregiao.codigo
                                      and pcpromcregiao.numregiao =
                                          p_regpedido.numregiao)) or
                                (not exists
                                 (select 'x'
                                     from pcpromcregiao
                                    where PCPROMC.Codigo =
                                          pcpromcregiao.codigo)))
                            and pcpromc.dtinicio <= trunc(sysdate)
                            and pcpromc.dtfim >= trunc(sysdate)
                            and (pcpromc.codfilial = p_regpedido.codfilial or
                                nvl(pcpromc.codfilial, '99') = '99')
                            and (pcpromc.codativ = p_regcliente.codatv1 or
                                pcpromc.codativ is null)
                            and (pcpromc.codsupervisor =
                                p_regrca.codsupervisor or
                                pcpromc.codsupervisor is null)
                            and (pcpromc.classevenda = p_regcliente.classevenda or pcpromc.classevenda is null)  ) loop

        --Identificar tipo de campanha
        if cr_pcpromc.codfornec is null then

          if cr_pcpromc.grupocampanha is null then

            --Campanha por Quantidade E Valor  Total
            if cr_pcpromc.tipocampanha = 'QV' and cr_pcpromc.vltotvenda > 0 and
               cr_pcpromc.qttotvenda > 0 then

              vnnumcampanha := vnnumcampanha + 1;
              gvet_regcampanha(vnnumcampanha).codigocampanha   := cr_pcpromc.codigo;
              gvet_regcampanha(vnnumcampanha).numcampanha      := 6;
              gvet_regcampanha(vnnumcampanha).produtoprinc     := cr_pcpromc.produtoprinc;
              gvet_regcampanha(vnnumcampanha).tipocampanha     := cr_pcpromc.tipocampanha;
              gvet_regcampanha(vnnumcampanha).codfornec        := cr_pcpromc.codfornec;
              gvet_regcampanha(vnnumcampanha).codprod          := cr_pcpromc.codprod;
              gvet_regcampanha(vnnumcampanha).grupocampanha    := cr_pcpromc.grupocampanha;
              gvet_regcampanha(vnnumcampanha).qttotvenda       := cr_pcpromc.qttotvenda;
              gvet_regcampanha(vnnumcampanha).vltotvenda       := cr_pcpromc.vltotvenda;
              gvet_regcampanha(vnnumcampanha).multiplo         := cr_pcpromc.multiplo;
              gvet_regcampanha(vnnumcampanha).qtbrinde         := cr_pcpromc.qtbrinde;
              gvet_regcampanha(vnnumcampanha).variosbrinde     := cr_pcpromc.variosbrinde;
              gvet_regcampanha(vnnumcampanha).obrigavendamix   := cr_pcpromc.obrigavendamix;
              gvet_regcampanha(vnnumcampanha).QTLIMITEBRINDE   := cr_pcpromc.QTLIMITEBRINDE;
              gvet_regcampanha(vnnumcampanha).usadebcredrcabrind := cr_pcpromc.usadebcredrcabrind;

            end if;

            --Campanha por Quantidade OU Valor total
            if cr_pcpromc.tipocampanha = 'OU' and cr_pcpromc.vltotvenda > 0 and
               cr_pcpromc.qttotvenda > 0 then

              vnnumcampanha := vnnumcampanha + 1;
              gvet_regcampanha(vnnumcampanha).codigocampanha   := cr_pcpromc.codigo;
              gvet_regcampanha(vnnumcampanha).numcampanha      := 7;
              gvet_regcampanha(vnnumcampanha).produtoprinc     := cr_pcpromc.produtoprinc;
              gvet_regcampanha(vnnumcampanha).tipocampanha     := cr_pcpromc.tipocampanha;
              gvet_regcampanha(vnnumcampanha).codfornec        := cr_pcpromc.codfornec;
              gvet_regcampanha(vnnumcampanha).codprod          := cr_pcpromc.codprod;
              gvet_regcampanha(vnnumcampanha).grupocampanha    := cr_pcpromc.grupocampanha;
              gvet_regcampanha(vnnumcampanha).qttotvenda       := cr_pcpromc.qttotvenda;
              gvet_regcampanha(vnnumcampanha).vltotvenda       := cr_pcpromc.vltotvenda;
              gvet_regcampanha(vnnumcampanha).multiplo         := cr_pcpromc.multiplo;
              gvet_regcampanha(vnnumcampanha).qtbrinde         := cr_pcpromc.qtbrinde;
              gvet_regcampanha(vnnumcampanha).variosbrinde     := cr_pcpromc.variosbrinde;
              gvet_regcampanha(vnnumcampanha).obrigavendamix   := cr_pcpromc.obrigavendamix;
              gvet_regcampanha(vnnumcampanha).QTLIMITEBRINDE   := cr_pcpromc.QTLIMITEBRINDE;
              gvet_regcampanha(vnnumcampanha).usadebcredrcabrind := cr_pcpromc.usadebcredrcabrind;

            end if;

           --Campanha por Valor total com Restricoes
            if cr_pcpromc.tipocampanha = 'VR' and cr_pcpromc.vltotvenda > 0 then

              vnnumcampanha := vnnumcampanha + 1;
              gvet_regcampanha(vnnumcampanha).codigocampanha   := cr_pcpromc.codigo;
              gvet_regcampanha(vnnumcampanha).numcampanha      := 9;
              gvet_regcampanha(vnnumcampanha).produtoprinc     := cr_pcpromc.produtoprinc;
              gvet_regcampanha(vnnumcampanha).tipocampanha     := cr_pcpromc.tipocampanha;
              gvet_regcampanha(vnnumcampanha).codfornec        := cr_pcpromc.codfornec;
              gvet_regcampanha(vnnumcampanha).codprod          := cr_pcpromc.codprod;
              gvet_regcampanha(vnnumcampanha).grupocampanha    := cr_pcpromc.grupocampanha;
              gvet_regcampanha(vnnumcampanha).qttotvenda       := cr_pcpromc.qttotvenda;
              gvet_regcampanha(vnnumcampanha).vltotvenda       := cr_pcpromc.vltotvenda;
              gvet_regcampanha(vnnumcampanha).multiplo         := cr_pcpromc.multiplo;
              gvet_regcampanha(vnnumcampanha).qtbrinde         := cr_pcpromc.qtbrinde;
              gvet_regcampanha(vnnumcampanha).variosbrinde     := cr_pcpromc.variosbrinde;
              gvet_regcampanha(vnnumcampanha).obrigavendamix   := cr_pcpromc.obrigavendamix;
              gvet_regcampanha(vnnumcampanha).QTLIMITEBRINDE   := cr_pcpromc.QTLIMITEBRINDE;
              gvet_regcampanha(vnnumcampanha).restricaovalormin := cr_pcpromc.restricaovalormin;
              gvet_regcampanha(vnnumcampanha).restricaoqtmin   := cr_pcpromc.restricaoqtmin;
              gvet_regcampanha(vnnumcampanha).usadebcredrcabrind := cr_pcpromc.usadebcredrcabrind;

            end if;

           --Campanha por Valor  Total e obrigatorio ou não a quantidade para alguns itens
            if cr_pcpromc.tipocampanha = 'VO' and cr_pcpromc.vltotvenda > 0  then

              vnnumcampanha := vnnumcampanha + 1;
              gvet_regcampanha(vnnumcampanha).codigocampanha := cr_pcpromc.codigo;
              gvet_regcampanha(vnnumcampanha).numcampanha := 8;
              gvet_regcampanha(vnnumcampanha).produtoprinc := cr_pcpromc.produtoprinc;
              gvet_regcampanha(vnnumcampanha).tipocampanha := cr_pcpromc.tipocampanha;
              gvet_regcampanha(vnnumcampanha).codfornec := cr_pcpromc.codfornec;
              gvet_regcampanha(vnnumcampanha).codprod := cr_pcpromc.codprod;
              gvet_regcampanha(vnnumcampanha).grupocampanha := cr_pcpromc.grupocampanha;
              gvet_regcampanha(vnnumcampanha).qttotvenda := cr_pcpromc.qttotvenda;
              gvet_regcampanha(vnnumcampanha).vltotvenda := cr_pcpromc.vltotvenda;
              gvet_regcampanha(vnnumcampanha).multiplo := cr_pcpromc.multiplo;
              gvet_regcampanha(vnnumcampanha).qtbrinde := cr_pcpromc.qtbrinde;
              gvet_regcampanha(vnnumcampanha).variosbrinde := cr_pcpromc.variosbrinde;
              gvet_regcampanha(vnnumcampanha).obrigavendamix := cr_pcpromc.obrigavendamix;
              gvet_regcampanha(vnnumcampanha).QTLIMITEBRINDE   := cr_pcpromc.QTLIMITEBRINDE;
              gvet_regcampanha(vnnumcampanha).usadebcredrcabrind := cr_pcpromc.usadebcredrcabrind;

            end if;
            --Campanha por valor total
            if cr_pcpromc.tipocampanha = 'VL' then
              if cr_pcpromc.qttotvenda is null and
                 cr_pcpromc.vltotvenda > 0 then

                vnnumcampanha := vnnumcampanha + 1;
                gvet_regcampanha(vnnumcampanha).codigocampanha := cr_pcpromc.codigo;
                gvet_regcampanha(vnnumcampanha).numcampanha    := 3;
                gvet_regcampanha(vnnumcampanha).produtoprinc   := cr_pcpromc.produtoprinc;
                gvet_regcampanha(vnnumcampanha).tipocampanha   := cr_pcpromc.tipocampanha;
                gvet_regcampanha(vnnumcampanha).codfornec      := cr_pcpromc.codfornec;
                gvet_regcampanha(vnnumcampanha).codprod        := cr_pcpromc.codprod;
                gvet_regcampanha(vnnumcampanha).grupocampanha  := cr_pcpromc.grupocampanha;
                gvet_regcampanha(vnnumcampanha).qttotvenda     := cr_pcpromc.qttotvenda;
                gvet_regcampanha(vnnumcampanha).vltotvenda     := cr_pcpromc.vltotvenda;
                gvet_regcampanha(vnnumcampanha).multiplo       := cr_pcpromc.multiplo;
                gvet_regcampanha(vnnumcampanha).qtbrinde       := cr_pcpromc.qtbrinde;
                gvet_regcampanha(vnnumcampanha).variosbrinde   := cr_pcpromc.variosbrinde;
                gvet_regcampanha(vnnumcampanha).obrigavendamix := cr_pcpromc.obrigavendamix;
                gvet_regcampanha(vnnumcampanha).vltotvendamax  := cr_pcpromc.vltotvendamax;
                gvet_regcampanha(vnnumcampanha).QTLIMITEBRINDE   := cr_pcpromc.QTLIMITEBRINDE;
                gvet_regcampanha(vnnumcampanha).usadebcredrcabrind := cr_pcpromc.usadebcredrcabrind;

              end if;

              --cr_pcpromc.tipocampanha = 'VL'
            else
              if nvl(cr_pcpromc.qttotvenda, 0) > 0 then

                --Campanha por Quantidade Total
                if cr_pcpromc.tipocampanha = 'QT' then

                vnnumcampanha := vnnumcampanha + 1;
                gvet_regcampanha(vnnumcampanha).codigocampanha := cr_pcpromc.codigo;
                gvet_regcampanha(vnnumcampanha).numcampanha    := 2;
                gvet_regcampanha(vnnumcampanha).produtoprinc   := cr_pcpromc.produtoprinc;
                gvet_regcampanha(vnnumcampanha).tipocampanha   := cr_pcpromc.tipocampanha;
                gvet_regcampanha(vnnumcampanha).codfornec      := cr_pcpromc.codfornec;
                gvet_regcampanha(vnnumcampanha).codprod        := cr_pcpromc.codprod;
                gvet_regcampanha(vnnumcampanha).grupocampanha  := cr_pcpromc.grupocampanha;
                gvet_regcampanha(vnnumcampanha).qttotvenda     := cr_pcpromc.qttotvenda;
                gvet_regcampanha(vnnumcampanha).vltotvenda     := cr_pcpromc.vltotvenda;
                gvet_regcampanha(vnnumcampanha).multiplo       := cr_pcpromc.multiplo;
                gvet_regcampanha(vnnumcampanha).qtbrinde       := cr_pcpromc.qtbrinde;
                gvet_regcampanha(vnnumcampanha).variosbrinde   := cr_pcpromc.variosbrinde;
                gvet_regcampanha(vnnumcampanha).obrigavendamix := cr_pcpromc.obrigavendamix;
                gvet_regcampanha(vnnumcampanha).QTLIMITEBRINDE   := cr_pcpromc.QTLIMITEBRINDE;
                gvet_regcampanha(vnnumcampanha).usadebcredrcabrind := cr_pcpromc.usadebcredrcabrind;

                end if;
                --nvl(cr_pcpromc.qttotvenda,0) > 0
              else

                --Campanha por Mix
                if cr_pcpromc.tipocampanha = 'QT' then

                vnnumcampanha := vnnumcampanha + 1;
                gvet_regcampanha(vnnumcampanha).codigocampanha := cr_pcpromc.codigo;
                gvet_regcampanha(vnnumcampanha).numcampanha    := 1;
                gvet_regcampanha(vnnumcampanha).produtoprinc   := cr_pcpromc.produtoprinc;
                gvet_regcampanha(vnnumcampanha).tipocampanha   := cr_pcpromc.tipocampanha;
                gvet_regcampanha(vnnumcampanha).codfornec      := cr_pcpromc.codfornec;
                gvet_regcampanha(vnnumcampanha).codprod        := cr_pcpromc.codprod;
                gvet_regcampanha(vnnumcampanha).grupocampanha  := cr_pcpromc.grupocampanha;
                gvet_regcampanha(vnnumcampanha).qttotvenda     := cr_pcpromc.qttotvenda;
                gvet_regcampanha(vnnumcampanha).vltotvenda     := cr_pcpromc.vltotvenda;
                gvet_regcampanha(vnnumcampanha).multiplo       := cr_pcpromc.multiplo;
                gvet_regcampanha(vnnumcampanha).qtbrinde       := cr_pcpromc.qtbrinde;
                gvet_regcampanha(vnnumcampanha).variosbrinde   := cr_pcpromc.variosbrinde;
                gvet_regcampanha(vnnumcampanha).obrigavendamix := cr_pcpromc.obrigavendamix;
                gvet_regcampanha(vnnumcampanha).QTLIMITEBRINDE   := cr_pcpromc.QTLIMITEBRINDE;
                gvet_regcampanha(vnnumcampanha).usadebcredrcabrind := cr_pcpromc.usadebcredrcabrind;

                end if;
              end if;
            end if;
            --cr_pcpromc.grupocampanha is null
          else
            -- Campanha por Grupo de fornecedores
            --tipototalprodprinc is null ( I está no nvl)
            if cr_pcpromc.produtoprinc = 'N' and
               cr_pcpromc.tipocampanha = 'QT' and
               cr_pcpromc.qttotvenda is null and
               cr_pcpromc.vltotvenda is null then

                vnnumcampanha := vnnumcampanha + 1;
                gvet_regcampanha(vnnumcampanha).codigocampanha := cr_pcpromc.codigo;
                gvet_regcampanha(vnnumcampanha).numcampanha    := 5;
                gvet_regcampanha(vnnumcampanha).produtoprinc   := cr_pcpromc.produtoprinc;
                gvet_regcampanha(vnnumcampanha).tipocampanha   := cr_pcpromc.tipocampanha;
                gvet_regcampanha(vnnumcampanha).codfornec      := cr_pcpromc.codfornec;
                gvet_regcampanha(vnnumcampanha).codprod        := cr_pcpromc.codprod;
                gvet_regcampanha(vnnumcampanha).grupocampanha  := cr_pcpromc.grupocampanha;
                gvet_regcampanha(vnnumcampanha).qttotvenda     := cr_pcpromc.qttotvenda;
                gvet_regcampanha(vnnumcampanha).vltotvenda     := cr_pcpromc.vltotvenda;
                gvet_regcampanha(vnnumcampanha).multiplo       := cr_pcpromc.multiplo;
                gvet_regcampanha(vnnumcampanha).qtbrinde       := cr_pcpromc.qtbrinde;
                gvet_regcampanha(vnnumcampanha).variosbrinde   := cr_pcpromc.variosbrinde;
                gvet_regcampanha(vnnumcampanha).obrigavendamix := cr_pcpromc.obrigavendamix;
                gvet_regcampanha(vnnumcampanha).QTLIMITEBRINDE   := cr_pcpromc.QTLIMITEBRINDE;
                gvet_regcampanha(vnnumcampanha).usadebcredrcabrind := cr_pcpromc.usadebcredrcabrind;

            end if;
          end if;
          --cr_pcpromc.codfornec is null
        else
          --Campanha por faixa de valor de um fornecedor
          if cr_pcpromc.grupocampanha is null then
            --tipototalprodprinc is null ( I está no nvl)
            if cr_pcpromc.produtoprinc = 'N' and
               cr_pcpromc.tipocampanha = 'QT' and
               cr_pcpromc.qttotvenda is null and
               cr_pcpromc.vltotvenda is null then

                vnnumcampanha := vnnumcampanha + 1;
                gvet_regcampanha(vnnumcampanha).codigocampanha := cr_pcpromc.codigo;
                gvet_regcampanha(vnnumcampanha).numcampanha    := 4;
                gvet_regcampanha(vnnumcampanha).produtoprinc   := cr_pcpromc.produtoprinc;
                gvet_regcampanha(vnnumcampanha).tipocampanha   := cr_pcpromc.tipocampanha;
                gvet_regcampanha(vnnumcampanha).codfornec      := cr_pcpromc.codfornec;
                gvet_regcampanha(vnnumcampanha).codprod        := cr_pcpromc.codprod;
                gvet_regcampanha(vnnumcampanha).grupocampanha  := cr_pcpromc.grupocampanha;
                gvet_regcampanha(vnnumcampanha).qttotvenda     := cr_pcpromc.qttotvenda;
                gvet_regcampanha(vnnumcampanha).vltotvenda     := cr_pcpromc.vltotvenda;
                gvet_regcampanha(vnnumcampanha).multiplo       := cr_pcpromc.multiplo;
                gvet_regcampanha(vnnumcampanha).qtbrinde       := cr_pcpromc.qtbrinde;
                gvet_regcampanha(vnnumcampanha).variosbrinde   := cr_pcpromc.variosbrinde;
                gvet_regcampanha(vnnumcampanha).obrigavendamix := cr_pcpromc.obrigavendamix;
                gvet_regcampanha(vnnumcampanha).QTLIMITEBRINDE   := cr_pcpromc.QTLIMITEBRINDE;
                gvet_regcampanha(vnnumcampanha).usadebcredrcabrind := cr_pcpromc.usadebcredrcabrind;

            end if;
          end if;
        end if;
      end loop;
    exception
      when others then

      if vsmensagem is null then

           vsmensagem := 'Erro ao buscar campanhas ativas. '||SQLCODE||' '||SQLERRM;
        else

            vsmensagem := vsmensagem||CHR(13)||'Erro ao buscar campanhas ativas. '||SQLCODE||' '||SQLERRM;
        end if;



    end;

    vncontcampanha := gvet_regcampanha.count;

   begin

    for i in 1 .. vncontcampanha loop

      vinaoexistemix := 0;

      select count(distinct pcpromi.codprod)
        into vinaoexistemix
        from pcpromi
       where codigo = gvet_regcampanha(i).codigocampanha
         and (not exists (select 'x'
                            from pcpedi, pcprodut
                           where pcpedi.numped = p_regpedido.numped
                             and pcpedi.codprod = pcprodut.codprod
                             and pcpromi.codprod =
                                 decode(gvet_regcampanha(i).produtoprinc,
                                        'N',
                                        pcprodut.codprod,
                                        pcprodut.codprodprinc)));

      -- MIX
      if gvet_regcampanha(i).numcampanha = 1 then

        vicont  := 0;
        vicont2 := 0;
        vnqtminbrinde := 0;

        if vinaoexistemix = 0 then

          --verifica quantos itens existem na pcpedi e na pcpromi
          begin
            select count(*)
              into vicont
              from pcpromi, pcpedi, pcprodut
             where pcpedi.codprod = pcprodut.codprod
               and pcpromi.codprod =
                   decode(gvet_regcampanha(i).produtoprinc,
                          'N',
                          pcprodut.codprod,
                          pcprodut.codprodprinc)
               --and pcpedi.qt >= pcpromi.qt
               and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
               and pcpedi.numped = p_regpedido.numped;
          exception
            when no_data_found then

              vicont := 0;

          end;


          --verifica quantos itens que existem na pcpedi e na pcpromi com as quantidades atendidas
          begin
            select count(*)
              into vicont2
              from pcpromi, pcpedi, pcprodut
             where pcpedi.codprod = pcprodut.codprod
               and pcpromi.codprod =
                   decode(gvet_regcampanha(i).produtoprinc,
                          'N',
                          pcprodut.codprod,
                          pcprodut.codprodprinc)
               and pcpedi.qt >= pcpromi.qt
               and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
               and pcpedi.numped = p_regpedido.numped;
          exception
            when no_data_found then

              vicont2 := 0;

          end;

           if gvet_Regcampanha(i).produtoprinc = 'S' then

           begin
                select counT(*)
                into vicont2
                from pcpromi p,pcpedi i,pcprodut t,
                     (select pcpromi.codprod,sum(pcpedi.qt) qt
                              from pcpromi, pcpedi, pcprodut
                             where pcpedi.codprod = pcprodut.codprod
                               and pcpromi.codprod =  decode(gvet_regcampanha(i).produtoprinc, 'N',  pcprodut.codprod,  pcprodut.codprodprinc)
                               and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
                               and pcpedi.numped = p_regpedido.numped
                       group by pcpromi.codprod) tab
                where p.codprod = tab.codprod
                and   tab.qt >= p.qt
                and   p.codigo = gvet_regcampanha(i).codigocampanha
                and   i.codprod = t.codprod
                and   p.codprod =  decode(gvet_regcampanha(i).produtoprinc, 'N',  t.codprod,  t.codprodprinc)
                and   i.numped =   p_regpedido.numped
                               ;
            exception when no_data_found then
              vicont2 := 0;
            end;

           end if;



          if vicont = vicont2 then

            vnqtminbrinde := 0;

            for reg_prod in ( select decode(gvet_regcampanha(i).produtoprinc,'N',
                                           pcprodut.codprod, pcprodut.codprodprinc) codprod,
                           -- sum(pcpedi.qt) qt,
                         --   count(distinct(pcpedi.codprod)) qtprod,
                            pcpromi.qt,
                            trunc(sum(pcpedi.qt) /
                              decode(nvl(pcpromi.qt, 0), 0, 1, pcpromi.qt)) qtminbrinde

                from pcpromi, pcpedi, pcprodut
               where pcpedi.codprod = pcprodut.codprod
                 and pcpromi.codprod =
                     decode(gvet_regcampanha(i).produtoprinc,
                            'N',
                            pcprodut.codprod,
                            pcprodut.codprodprinc)
                 --and pcpedi.qt >= pcpromi.qt
                 and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
                 and pcpedi.numped = p_regpedido.numped
                 group by decode(gvet_regcampanha(i).produtoprinc,'N',
                                           pcprodut.codprod, pcprodut.codprodprinc),pcpromi.qt) loop


                  if reg_prod.qtminbrinde < vnqtminbrinde or
                       vnqtminbrinde = 0 then

                      vnqtminbrinde := trunc(reg_prod.qtminbrinde);
                  end if;

             end loop;

            select descricao
              into vsdescricao
              from pcprodut
             where codprod = gvet_regcampanha(i).codprod;


            select count(*)
              into vicontzeropcpromi
              from pcpromi, pcpedi, pcprodut
             where pcpromi.codigo = gvet_regcampanha(i)
            .codigocampanha
               and pcpromi.qt = 0
               and pcpromi.codprod =
                   decode(gvet_regcampanha(i).produtoprinc,
                          'N',
                          pcprodut.codprod,
                          pcprodut.codprodprinc)
               and pcpedi.codprod = pcprodut.codprod
               and pcpedi.numped = p_regpedido.numped;

            select descricao
              into vsdescricao
              from pcprodut
             where codprod = gvet_regcampanha(i).codprod;

            vnqtbrinde := 0;


            --todos os registros da pcpromi com quantidade maior que zero
            if vicontzeropcpromi = 0 then

              if gvet_regcampanha(i).variosbrinde = 'S' then

                vnqtbrinde := trunc(vnqtminbrinde * gvet_regcampanha(i)
                                    .qtbrinde);

              else

                vnqtbrinde := gvet_regcampanha(i).qtbrinde;
              end if;

              if vnqtbrinde > 0 then

                vnqtdispbrinde := 0;
                vnqtdispbrindecont := 0;

                vscodfilialretira := p_codfilialretira;

                proc_verificafilialbrinde(p_Regpedido.numped,
                                          p_Regpedido.codfilial,
                                          gvet_regcampanha(i).codprod,
                                          vscodfilialretira);
                begin
                  -- Verificar Estoque para evitar o Corte do Brinde

                  BEGIN
                    SELECT NVL(QT, 0)
                      INTO vnQtNoPedido
                      FROM PCPEDI
                     WHERE CODPROD = GVET_REGCAMPANHA(I).CODPROD
                       AND CODFILIALRETIRA = vscodfilialretira
                       AND NUMPED = P_NUMPED;
                  EXCEPTION
                    WHEN OTHERS THEN
                      vnQtNoPedido := 0;
                  END;

                  select greatest(nvl(qtestger, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        DECODE(vsBLOQUEIAVENDAESTPENDENTE, 'S', NVL(QTPENDENTE, 0), 0)-
                        greatest(nvl(qtbloqueada, 0), 0) -
                        greatest(vnQtNoPedido) ,
                        greatest(nvl(qtest, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        greatest(vnQtNoPedido)
                    into vnqtdispbrinde,vnqtdispbrindecont
                    from pcest
                   where pcest.codprod = gvet_regcampanha(i).codprod
                     and pcest.codfilial = vscodfilialretira;

                exception
                  when others then
                    vnqtdispbrinde := 0;
                    vnqtdispbrindecont := 0;
                end;




                if  --se tem estoque gerencial disponivel OU
                    (
                      ((nvl(vnqtdispbrinde, 0) >= vnqtbrinde  ) or
                    --não tem estoque gerencial disp, mas o parametro permita gravar pendente E
                    ((nvl(vnqtdispbrinde, 0) < vnqtbrinde  ) and p_regfilial.aceitavendasemestfv = 'S')) AND
                    -- Um dos parametros para verificar estoque contábil marcado e tem disponivel contábil OU
                    (((nvl(vnqtdispbrindecont, 0) >= vnqtbrinde) and (NVL(p_regfilial.verificaestoquecont,p_regfilial.con_verificaestoquecont) = 'S') ) or
                    -- Parametros para verificar estoque contábil desmarcados
                     (p_regfilial.verificaestoquecont = 'N' or p_regfilial.con_verificaestoquecont = 'N'))
                    ) then

                   if nvl(vnqtdispbrinde, 0) < vnqtbrinde then
                      p_regpedido.posicao := 'P';

                       if vsmensagem is null then

                           vsmensagem := 'Pedido de brinde gravado Pendente. Brinde sem estoque disponivel. : '||gvet_regcampanha(i).codprod||' '||vsdescricao;
                        else

                            vsmensagem := vsmensagem||CHR(13)||'Pedido de brinde gravado Pendente. Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao || CHR(13);
                        end if;

                    end if;

                  vnnumitensbonific := vnnumitensbonific + 1;
                  gvet_regitempedbrinde(vnnumitensbonific).numpedrca         := p_regpedido.numpedrca;
                  gvet_regitempedbrinde(vnnumitensbonific).codprod           := gvet_regcampanha(i).codprod;
                  gvet_regitempedbrinde(vnnumitensbonific).qt                := vnqtbrinde;
                  gvet_regitempedbrinde(vnnumitensbonific).codfilialretira := vscodfilialretira;
                  gvet_regitempedbrinde(vnnumitensbonific).qtlimitebrinde    := gvet_regcampanha(i).qtlimitebrinde;
                  gvet_regitempedbrinde(vnnumitensbonific).numcampanha       := gvet_regcampanha(i).numcampanha;
                  gvet_regitempedbrinde(vnnumitensbonific).codigocampanha    := gvet_regcampanha(i).codigocampanha;
                  gvet_regitempedbrinde(vnnumitensbonific).descricao         := vsdescricao;
                  gvet_regitempedbrinde(vnnumitensbonific).usadebcredrcabrind := gvet_regcampanha(i).usadebcredrcabrind;

                  begin
                    select codauxiliar
                      into gvet_regitempedbrinde(vnnumitensbonific).codauxiliar
                      from pcprodut
                     where codprod = gvet_regcampanha(i).codprod;
                  exception
                    when others then
                      gvet_regitempedbrinde(vnnumitensbonific) := null;
                  end;

                else

                   if vsmensagem is null then

                       vsmensagem := 'Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao ;
                    else

                        vsmensagem := vsmensagem||CHR(13)||'Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao || CHR(13);
                    end if;



                end if;
              end if;
            end if;
          end if;
        end if;

        --Quantidade Total
      elsif gvet_regcampanha(i).numcampanha = 2 then

        vicont        := 0;
        vnqtminbrinde := 0;

        if (gvet_regcampanha(i).obrigavendamix = 'S' and vinaoexistemix = 0) or
           (gvet_regcampanha(i).obrigavendamix = 'N') then

          begin
            select count(*)
              into vicont
              from pcpromi, pcpedi, pcprodut
             where pcpedi.codprod = pcprodut.codprod
               and pcpromi.codprod =
                   decode(gvet_regcampanha(i).produtoprinc,
                          'N',
                          pcprodut.codprod,
                          pcprodut.codprodprinc)
               and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
               and pcpedi.numped = p_regpedido.numped;
          exception
            when no_data_found then
              vicont := 0;
          end;

          select descricao
            into vsdescricao
            from pcprodut
           where codprod = gvet_regcampanha(i).codprod;

          if vicont <> 0 then
            select count(*)
              into vicontpcpromi
              from pcpromi, pcpedi, pcprodut
             where pcpedi.codprod = pcprodut.codprod
               and pcpromi.codprod =
                   decode(gvet_regcampanha(i).produtoprinc,
                          'N',
                          pcprodut.codprod,
                          pcprodut.codprodprinc)
               and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
               and pcpedi.numped = p_regpedido.numped
               and pcpromi.qt > 0;

            --Não existe nenhum item com quantidade informada na pcpromi
            if vicontpcpromi = 0 then

              select sum(pcpedi.qt) qt,
                     count(distinct(pcpedi.codprod)) qtprod,
                     round(min((pcpedi.qt /
                         decode(nvl(pcpromi.qt, 0), 0, 1, pcpromi.qt)))) qtminbrinde
                into vnqttotitens, vnqtprod, vnqtminbrinde
                from pcpromi, pcpedi, pcprodut
               where pcpedi.codprod = pcprodut.codprod
                 and pcpromi.codprod =
                     decode(gvet_regcampanha(i).produtoprinc,
                            'N',
                            pcprodut.codprod,
                            pcprodut.codprodprinc)
                 and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
                 and pcpedi.numped = p_regpedido.numped;

              vnqtbrinde := 0;

              if vnqttotitens >= gvet_regcampanha(i).qttotvenda then
                vnqtminbrinde := gvet_regcampanha(i).qtbrinde;

                if vnqtbrinde = 0 then
                  vnqtbrinde := trunc(vnqtminbrinde);
                else
                  if vnqtbrinde > trunc(vnqtminbrinde) then
                    vnqtbrinde := trunc(vnqtminbrinde);
                  end if;
                end if;

                if gvet_regcampanha(i).variosbrinde = 'S' then
                  vnqtbrinde := trunc(trunc(vnqttotitens /
                                            to_number(gvet_regcampanha(i).qttotvenda)) *
                                      vnqtminbrinde);
                else
                  vnqtbrinde := trunc(vnqtminbrinde);
                end if;

              end if;

              if vnqtbrinde > 0 then
                vnqtdispbrinde := 0;
                vnqtdispbrindecont := 0;


                vscodfilialretira := p_codfilialretira;

                proc_verificafilialbrinde(p_Regpedido.numped,
                                          p_Regpedido.codfilial,
                                          gvet_regcampanha(i).codprod,
                                          vscodfilialretira);


                begin
                  -- Verificar Estoque para evitar o Corte do Brinde

                  BEGIN
                    SELECT NVL(QT, 0)
                      INTO vnQtNoPedido
                      FROM PCPEDI
                     WHERE CODPROD = GVET_REGCAMPANHA(I).CODPROD
                       AND CODFILIALRETIRA = vscodfilialretira
                       AND NUMPED = P_NUMPED;
                  EXCEPTION
                    WHEN OTHERS THEN
                      vnQtNoPedido := 0;
                  END;

                  select greatest(nvl(qtestger, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        DECODE(vsBLOQUEIAVENDAESTPENDENTE, 'S', NVL(QTPENDENTE, 0), 0)-
                        greatest(nvl(qtbloqueada, 0), 0) -
                        greatest(vnQtNoPedido),
                        greatest(nvl(qtest, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        greatest(vnQtNoPedido)
                    into vnqtdispbrinde,vnqtdispbrindecont
                    from pcest
                   where pcest.codprod = gvet_regcampanha(i).codprod
                     and pcest.codfilial = vscodfilialretira;

                exception
                  when others then
                    vnqtdispbrinde := 0;
                    vnqtdispbrindecont := 0;
                end;




                if  --se tem estoque gerencial disponivel OU
                    (
                      ((nvl(vnqtdispbrinde, 0) >= vnqtbrinde  ) or
                    --não tem estoque gerencial disp, mas o parametro permita gravar pendente E
                    ((nvl(vnqtdispbrinde, 0) < vnqtbrinde  ) and p_regfilial.aceitavendasemestfv = 'S')) AND
                    -- Um dos parametros para verificar estoque contábil marcado e tem disponivel contábil OU
                    (((nvl(vnqtdispbrindecont, 0) >= vnqtbrinde) and (NVL(p_regfilial.verificaestoquecont,p_regfilial.con_verificaestoquecont) = 'S') ) or
                    -- Parametros para verificar estoque contábil desmarcados
                     (p_regfilial.verificaestoquecont = 'N' or p_regfilial.con_verificaestoquecont = 'N'))
                    ) then

                   if nvl(vnqtdispbrinde, 0) < vnqtbrinde then
                      p_regpedido.posicao := 'P';

                       if vsmensagem is null then

                           vsmensagem := 'Pedido de brinde gravado Pendente. Brinde sem estoque disponivel. : '||gvet_regcampanha(i).codprod||' '||vsdescricao ;
                        else

                            vsmensagem := vsmensagem||CHR(13)||'Pedido de brinde gravado Pendente. Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao || CHR(13);
                        end if;


                   end if;

                  vnnumitensbonific := vnnumitensbonific + 1;
                  gvet_regitempedbrinde(vnnumitensbonific).numpedrca          := p_regpedido.numpedrca;
                  gvet_regitempedbrinde(vnnumitensbonific).codprod            := gvet_regcampanha(i).codprod;
                  gvet_regitempedbrinde(vnnumitensbonific).qt                 := vnqtbrinde;
                  gvet_regitempedbrinde(vnnumitensbonific).codfilialretira    := vscodfilialretira;
                  gvet_regitempedbrinde(vnnumitensbonific).qtlimitebrinde    := gvet_regcampanha(i).qtlimitebrinde;
                  gvet_regitempedbrinde(vnnumitensbonific).numcampanha       := gvet_regcampanha(i).numcampanha;
                  gvet_regitempedbrinde(vnnumitensbonific).codigocampanha    := gvet_regcampanha(i).codigocampanha;
                  gvet_regitempedbrinde(vnnumitensbonific).descricao         := vsdescricao;
                  gvet_regitempedbrinde(vnnumitensbonific).usadebcredrcabrind := gvet_regcampanha(i).usadebcredrcabrind;

                  begin
                    select codauxiliar
                      into gvet_regitempedbrinde(vnnumitensbonific).codauxiliar
                      from pcprodut
                     where codprod = gvet_regcampanha(i).codprod;
                  exception
                    when others then
                      gvet_regitempedbrinde(vnnumitensbonific) := null;
                  end;

                else
                   if vsmensagem is null then

                       vsmensagem := 'Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao ;
                    else

                        vsmensagem := vsmensagem||CHR(13)||'Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao ;
                    end if;


                end if;
              end if;
            end if;
          end if;
        end if;

        --Valor Total
      elsif gvet_regcampanha(i).numcampanha = 3 then
        vicont     := 0;
        vnqtbrinde := 0;

        if (gvet_regcampanha(i).obrigavendamix = 'S' and vinaoexistemix = 0) or
           (gvet_regcampanha(i).obrigavendamix = 'N') then

          begin
            select count(*)
              into vicont
              from pcpromi, pcpedi, pcprodut
             where pcpedi.codprod = pcprodut.codprod
               and pcpromi.codprod =
                   decode(gvet_regcampanha(i).produtoprinc,
                          'N',
                          pcprodut.codprod,
                          pcprodut.codprodprinc)
               and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
               and pcpedi.numped = p_regpedido.numped;

          exception
            when no_data_found then
              vicont := 0;
          end;

          select descricao
            into vsdescricao
            from pcprodut
           where codprod = gvet_regcampanha(i).codprod;

          if vicont > 0 then
            select count(*)
              into vicontpcpromi
              from pcpromi, pcpedi, pcprodut
             where pcpedi.codprod = pcprodut.codprod
               and pcpromi.codprod =
                   decode(gvet_regcampanha(i).produtoprinc,
                          'N',
                          pcprodut.codprod,
                          pcprodut.codprodprinc)
               and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
               and pcpedi.numped = p_regpedido.numped;

            --Não existe nenhum item com quantidade informada na pcpromi
            if vicontpcpromi > 0 then

              select sum(pcpedi.qt * pcpedi.pvenda) valor,
                     count(distinct(pcpedi.codprod)) qtprod
                into vnvltotitens, vnqtprod
                from pcpromi, pcpedi, pcprodut
               where pcpedi.codprod = pcprodut.codprod
                 and pcpromi.codprod =
                     decode(gvet_regcampanha(i).produtoprinc,
                            'N',
                            pcprodut.codprod,
                            pcprodut.codprodprinc)
                 and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
                 and pcpedi.numped = p_regpedido.numped;

              vnqtbrinde    := 0;
              vnqtminbrinde := 0;

              if vnvltotitens >= gvet_regcampanha(i).vltotvenda then

                  --tarefa 130108
                 if (gvet_regcampanha(i).vltotvendamax is not null and (vnvltotitens <= gvet_regcampanha(i).vltotvendamax)) or
                     gvet_regcampanha(i).vltotvendamax is null then

                      vnqtminbrinde := gvet_regcampanha(i).qtbrinde;
                      vnqtbrinde := trunc(vnqtminbrinde);

                      if gvet_regcampanha(i).variosbrinde = 'S' then
                        vnqtbrinde := trunc(trunc(vnvltotitens /
                                                  to_number(gvet_regcampanha(i).vltotvenda)) *
                                            nvl(vnqtminbrinde, 0));
                      else
                        vnqtbrinde := trunc(vnqtminbrinde);
                      end if;

               end if;
              end if;

              if vnqtbrinde > 0 then

                vnqtdispbrinde := 0;
                vnqtdispbrindecont := 0;

                vscodfilialretira := p_codfilialretira;

                proc_verificafilialbrinde(p_Regpedido.numped,
                                          p_Regpedido.codfilial,
                                          gvet_regcampanha(i).codprod,
                                          vscodfilialretira);

                begin
                  -- Verificar Estoque para evitar o Corte do Brinde

                  BEGIN
                    SELECT NVL(QT, 0)
                      INTO vnQtNoPedido
                      FROM PCPEDI
                     WHERE CODPROD = GVET_REGCAMPANHA(I).CODPROD
                       AND CODFILIALRETIRA = vscodfilialretira
                       AND NUMPED = P_NUMPED;
                  EXCEPTION
                    WHEN OTHERS THEN
                      vnQtNoPedido := 0;
                  END;

                  select greatest(nvl(qtestger, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        DECODE(vsBLOQUEIAVENDAESTPENDENTE, 'S', NVL(QTPENDENTE, 0), 0)-
                        greatest(nvl(qtbloqueada, 0), 0) -
                        greatest(vnQtNoPedido),
                        greatest(nvl(qtest, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        greatest(vnQtNoPedido)
                    into vnqtdispbrinde,vnqtdispbrindecont
                    from pcest
                   where pcest.codprod = gvet_regcampanha(i).codprod
                     and pcest.codfilial = vscodfilialretira;

                exception
                  when others then
                    vnqtdispbrinde := 0;
                    vnqtdispbrindecont := 0;
                end;




                if  --se tem estoque gerencial disponivel OU
                    (
                      ((nvl(vnqtdispbrinde, 0) >= vnqtbrinde  ) or
                    --não tem estoque gerencial disp, mas o parametro permita gravar pendente E
                    ((nvl(vnqtdispbrinde, 0) < vnqtbrinde  ) and p_regfilial.aceitavendasemestfv = 'S')) AND
                    -- Um dos parametros para verificar estoque contábil marcado e tem disponivel contábil OU
                    (((nvl(vnqtdispbrindecont, 0) >= vnqtbrinde) and (NVL(p_regfilial.verificaestoquecont,p_regfilial.con_verificaestoquecont) = 'S') ) or
                    -- Parametros para verificar estoque contábil desmarcados
                     (p_regfilial.verificaestoquecont = 'N' or p_regfilial.con_verificaestoquecont = 'N'))
                    ) then

                   if nvl(vnqtdispbrinde, 0) < vnqtbrinde then
                      p_regpedido.posicao := 'P';

                       if vsmensagem is null then

                           vsmensagem := 'Pedido de brinde gravado Pendente. Brinde sem estoque disponivel. : '||gvet_regcampanha(i).codprod||' '||vsdescricao ;
                        else

                            vsmensagem := vsmensagem||CHR(13)||'Pedido de brinde gravado Pendente. Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao || CHR(13);
                        end if;

                   end if;

                  vnnumitensbonific := vnnumitensbonific + 1;
                  gvet_regitempedbrinde(vnnumitensbonific).numpedrca        := p_regpedido.numpedrca;
                  gvet_regitempedbrinde(vnnumitensbonific).codprod          := gvet_regcampanha(i).codprod;
                  gvet_regitempedbrinde(vnnumitensbonific).qt               := vnqtbrinde;
                  gvet_regitempedbrinde(vnnumitensbonific).codfilialretira  := vscodfilialretira;
                  gvet_regitempedbrinde(vnnumitensbonific).qtlimitebrinde    := gvet_regcampanha(i).qtlimitebrinde;
                  gvet_regitempedbrinde(vnnumitensbonific).numcampanha       := gvet_regcampanha(i).numcampanha;
                  gvet_regitempedbrinde(vnnumitensbonific).codigocampanha    := gvet_regcampanha(i).codigocampanha;
                  gvet_regitempedbrinde(vnnumitensbonific).descricao         := vsdescricao;
                  gvet_regitempedbrinde(vnnumitensbonific).usadebcredrcabrind := gvet_regcampanha(i).usadebcredrcabrind;

                  begin
                    select codauxiliar
                      into gvet_regitempedbrinde(vnnumitensbonific).codauxiliar
                      from pcprodut
                     where codprod = gvet_regcampanha(i).codprod;
                  exception
                    when others then
                      gvet_regitempedbrinde(vnnumitensbonific) := null;
                  end;

                else

                   if vsmensagem is null then

                       vsmensagem := 'Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao ;
                    else

                        vsmensagem := vsmensagem||CHR(13)||'Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao || CHR(13);
                    end if;


                end if;
              end if;
            end if;
          end if;
        end if;

        --Valor fornecedor
      elsif gvet_regcampanha(i).numcampanha = 4 then

        vicont     := 0;
        vnqtbrinde := 0;

        begin
          select count(*)
            into vicont
            from pcpromi, pcpedi, pcprodut
           where pcpedi.codprod = pcprodut.codprod
             and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
             and pcpedi.numped = p_regpedido.numped
             and pcprodut.codfornec = gvet_regcampanha(i).codfornec;
        exception
          when no_data_found then
            vicont := 0;
        end;

        if vicont <> 0 then

          select count(*)
            into vicontpcpromi
            from pcpedi, pcprodut, pcpromi
           where pcpedi.codprod = pcprodut.codprod
             and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
             and pcpedi.numped = p_regpedido.numped
             and pcprodut.codfornec = gvet_regcampanha(i).codfornec
             and pcpromi.qt = 0;

          --Não existe nenhum item sem quantidade informada na pcpromi
          if vicontpcpromi = 0 then

            select sum((pcpedi.qt * pcpedi.pvenda)) valor,
                   count(distinct(pcpedi.codprod)) qtprod
              into vnvltotitens, vnqtprod
              from pcpedi
             where pcpedi.numped = p_regpedido.numped
               and exists
             (select 'x'
                      from pcpromi, pcprodut
                     where pcpedi.codprod = pcprodut.codprod
                       and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
                       and pcprodut.codfornec = gvet_regcampanha(i).codfornec);

            vnqtbrinde    := 0;
            vnqtminbrinde := 0;

            for regitens in (select pcpromi.codprod,
                                    pcpromi.vlvendamin,
                                    pcpromi.vlvendamax,
                                    pcpromi.qt,
                                    nvl(pcpromi.qtlimitebrinde,0) qtlimitebrinde
                               from pcpromi
                              where codigo = gvet_regcampanha(i).codigocampanha
                              order by vlvendamin) loop

              select descricao
                into vsdescricao
                from pcprodut
               where codprod = regitens.codprod;

              --ainda não teve brinde em nenhuma faixa
              if nvl(vnqtbrinde, 0) = 0 then
                -- esta dentro da faixa

                if ((to_number(vnvltotitens) >=
                   to_number(regitens.vlvendamin)) and
                   (to_number(vnvltotitens) <=
                   to_number(regitens.vlvendamax))) then
                  vnqtminbrinde := to_number(regitens.qt);
                end if;

                --é maior que o valor maximo da faixa
                if (to_number(vnvltotitens) >
                   to_number(regitens.vlvendamax)) then
                  if to_number(regitens.vlvendamax) <> 0 then

                    select max(nvl(pcpromi.vlvendamax, 0))
                      into vnvlmaxfaixafornec
                      from pcpromi
                     where codigo = gvet_regcampanha(i).codigocampanha;

                    select nvl(pcpromi.vlvendamin, 0)
                      into vnvlminmaiorfaixafornec
                      from pcpromi
                     where codigo = gvet_regcampanha(i).codigocampanha
                       and pcpromi.vlvendamax = vnvlmaxfaixafornec;

                    -- é a maior faixa desta campanha
                    if regitens.vlvendamax = vnvlmaxfaixafornec then
                      vnqtminbrinde := regitens.qt;

                      if gvet_regcampanha(i).multiplo = 'S' then
                        vnqtminbrinde := trunc(trunc(to_number(vnvltotitens) /
                                                     to_number(regitens.vlvendamax)) *
                                               to_number(regitens.qt));
                      end if;
                      --não é a maior faixa desta campanha
                    else

                      --valor de venda é menor que o valor minimo da maior faixa
                      if vnvltotitens < vnvlminmaiorfaixafornec then

                        select count(*)
                          into vicont
                          from pcpromi
                         where codigo = gvet_regcampanha(i).codigocampanha
                           and pcpromi.vlvendamin > regitens.vlvendamax
                           and pcpromi.vlvendamax < vnvlminmaiorfaixafornec;

                        --se não tiver nenhuma faixa intermediária
                        if vicont = 0 then
                          vnqtminbrinde := to_number(regitens.qt);
                          if gvet_regcampanha(i).multiplo = 'S' then
                            vnqtminbrinde := trunc(trunc(to_number(vnvltotitens) /
                                                         to_number(regitens.vlvendamax)) *
                                                   to_number(regitens.qt));
                          end if;
                        end if;
                      end if;
                    end if;
                  end if;
                end if;

                if nvl(vnqtminbrinde, 0) > 0 then
                  vnqtbrinde := trunc(vnqtminbrinde);
                end if;

                if vnqtbrinde > 0 then
                  vnqtdispbrinde := 0;
                  vnqtdispbrindecont := 0;

                vscodfilialretira := p_codfilialretira;

                proc_verificafilialbrinde(p_Regpedido.numped,
                                          p_Regpedido.codfilial,
                                          gvet_regcampanha(i).codprod,
                                          vscodfilialretira);

                  select descricao
                    into vsdescricao
                    from pcprodut
                   where codprod = regitens.codprod;




                begin
                  -- Verificar Estoque para evitar o Corte do Brinde

                  BEGIN
                    SELECT NVL(QT, 0)
                      INTO vnQtNoPedido
                      FROM PCPEDI
                     WHERE CODPROD = regitens.codprod
                       AND CODFILIALRETIRA = vscodfilialretira
                       AND NUMPED = P_NUMPED;
                  EXCEPTION
                    WHEN OTHERS THEN
                      vnQtNoPedido := 0;
                  END;

                  select greatest(nvl(qtestger, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        DECODE(vsBLOQUEIAVENDAESTPENDENTE, 'S', NVL(QTPENDENTE, 0), 0)-
                        greatest(nvl(qtbloqueada, 0), 0) -
                        greatest(vnQtNoPedido),
                        greatest(nvl(qtest, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        greatest(vnQtNoPedido)
                    into vnqtdispbrinde,vnqtdispbrindecont
                    from pcest
                   where pcest.codprod =  regitens.codprod
                     and pcest.codfilial = vscodfilialretira;

                exception
                  when others then
                    vnqtdispbrinde := 0;
                    vnqtdispbrindecont := 0;
                end;




                if  --se tem estoque gerencial disponivel OU
                    (
                      ((nvl(vnqtdispbrinde, 0) >= vnqtbrinde  ) or
                    --não tem estoque gerencial disp, mas o parametro permita gravar pendente E
                    ((nvl(vnqtdispbrinde, 0) < vnqtbrinde  ) and p_regfilial.aceitavendasemestfv = 'S')) AND
                    -- Um dos parametros para verificar estoque contábil marcado e tem disponivel contábil OU
                    (((nvl(vnqtdispbrindecont, 0) >= vnqtbrinde) and (NVL(p_regfilial.verificaestoquecont,p_regfilial.con_verificaestoquecont) = 'S') ) or
                    -- Parametros para verificar estoque contábil desmarcados
                     (p_regfilial.verificaestoquecont = 'N' or p_regfilial.con_verificaestoquecont = 'N'))
                    ) then


                   if nvl(vnqtdispbrinde, 0) < vnqtbrinde then
                      p_regpedido.posicao := 'P';


                       if vsmensagem is null then

                           vsmensagem := 'Pedido de brinde gravado Pendente. Brinde sem estoque disponivel. : '||regitens.codprod||' '||vsdescricao ;
                        else

                            vsmensagem := vsmensagem||CHR(13)||'Pedido de brinde gravado Pendente. Brinde sem estoque disponivel : '||regitens.codprod||' '||vsdescricao || CHR(13);
                        end if;

                   end if;

                    vnnumitensbonific := vnnumitensbonific + 1;
                    gvet_regitempedbrinde(vnnumitensbonific).numpedrca        := p_regpedido.numpedrca;
                    gvet_regitempedbrinde(vnnumitensbonific).codprod          := regitens.codprod;
                    gvet_regitempedbrinde(vnnumitensbonific).qt               := vnqtbrinde;
                    gvet_regitempedbrinde(vnnumitensbonific).codfilialretira  := vscodfilialretira;
                    gvet_regitempedbrinde(vnnumitensbonific).qtlimitebrinde    := regitens.qtlimitebrinde;
                    gvet_regitempedbrinde(vnnumitensbonific).numcampanha       := gvet_regcampanha(i).numcampanha;
                    gvet_regitempedbrinde(vnnumitensbonific).codigocampanha    := gvet_regcampanha(i).codigocampanha;
                    gvet_regitempedbrinde(vnnumitensbonific).descricao         := vsdescricao;
                    gvet_regitempedbrinde(vnnumitensbonific).usadebcredrcabrind := gvet_regcampanha(i).usadebcredrcabrind;

                    begin
                    select codauxiliar
                      into gvet_regitempedbrinde(vnnumitensbonific).codauxiliar
                      from pcprodut
                     where codprod = gvet_regcampanha(i).codprod;
                  exception
                    when others then
                      gvet_regitempedbrinde(vnnumitensbonific) := null;
                  end;

                  else

                   if vsmensagem is null then

                       vsmensagem := 'Brinde sem estoque disponivel : '||regitens.codprod||' '||vsdescricao ;
                    else

                        vsmensagem := vsmensagem||CHR(13)||'Brinde sem estoque disponivel : '||regitens.codprod||' '||vsdescricao || CHR(13);
                    end if;


                  end if;
                end if;
              end if;
            end loop;
          end if;
        end if;

        --Grupo fornecedor
      elsif gvet_regcampanha(i).numcampanha = 5 then

        vicont     := 0;
        vnqtbrinde := 0;

        begin
          select count(*)
            into vicont
            from pcpromi, pcpedi, pcprodut, pcfornec
           where pcpedi.codprod = pcprodut.codprod
             and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
             and pcpedi.numped = p_regpedido.numped
             and pcprodut.codfornec = pcfornec.codfornec
             and pcfornec.grupocampanha = gvet_regcampanha(i).grupocampanha;
        exception
          when no_data_found then
            vicont := 0;
        end;

        if vicont <> 0 then

          select count(*)
            into vicontpcpromi
            from pcpromi, pcpedi, pcprodut, pcfornec
           where pcpedi.codprod = pcprodut.codprod
             and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
             and pcpedi.numped = p_regpedido.numped
             and pcprodut.codfornec = pcfornec.codfornec
             and pcfornec.grupocampanha = gvet_regcampanha(i).grupocampanha
             and pcpromi.qt = 0;

          --Não existe nenhum item sem quantidade informada na pcpromi
          if vicontpcpromi = 0 then

            select sum((pcpedi.qt * pcpedi.pvenda)) valor,
                   count(distinct(pcpedi.codprod)) qtprod
              into vnvltotitens, vnqtprod
              from pcpedi
             where pcpedi.numped = p_regpedido.numped
               and exists
             (select 'x'
                      from pcpromi, pcprodut, pcfornec
                     where pcpedi.codprod = pcprodut.codprod
                       and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
                       and pcprodut.codfornec = pcfornec.codfornec
                       and pcfornec.grupocampanha = gvet_regcampanha(i).grupocampanha);

            vnqtbrinde    := 0;
            vnqtminbrinde := 0;

            for regitens in (select pcpromi.codprod,
                                    pcpromi.vlvendamin,
                                    pcpromi.vlvendamax,
                                    pcpromi.qt,
                                    nvl(pcpromi.qtlimitebrinde,0) qtlimitebrinde
                               from pcpromi
                              where codigo = gvet_regcampanha(i).codigocampanha
                              order by vlvendamin) loop

              select descricao
                into vsdescricao
                from pcprodut
               where codprod = regitens.codprod;

              --ainda não teve brinde em nenhuma faixa
              if nvl(vnqtbrinde, 0) = 0 then
                -- esta dentro da faixa
                if ((to_number(vnvltotitens) >=
                   to_number(regitens.vlvendamin)) and
                   (to_number(vnvltotitens) <=
                   to_number(regitens.vlvendamax))) then
                  vnqtminbrinde := to_number(regitens.qt);
                end if;

                --é maior que o valor maximo da faixa
                if (to_number(vnvltotitens) >
                   to_number(regitens.vlvendamax)) then

                  if to_number(regitens.vlvendamax) <> 0 then
                    select max(nvl(pcpromi.vlvendamax, 0))
                      into vnvlmaxfaixafornec
                      from pcpromi
                     where codigo = gvet_regcampanha(i).codigocampanha;

                    select max(nvl(pcpromi.vlvendamax, 0))
                      into vnvlminmaiorfaixafornec
                      from pcpromi
                     where codigo = gvet_regcampanha(i).codigocampanha
                       and pcpromi.vlvendamax = vnvlmaxfaixafornec;

                    -- é a maior faixa desta campanha
                    if regitens.vlvendamax = vnvlmaxfaixafornec then

                      vnqtminbrinde := regitens.qt;

                      if gvet_regcampanha(i).multiplo = 'S' then
                        vnqtminbrinde := trunc(trunc(to_number(vnvltotitens) /
                                                     to_number(regitens.vlvendamax)) *
                                               to_number(regitens.qt));
                      end if;
                      --não é a maior faixa desta campanha
                    else
                      --valor de venda é menor que o valor minimo da maior faixa
                      if vnvltotitens < vnvlminmaiorfaixafornec then
                        select count(*)
                          into vicont
                          from pcpromi
                         where codigo = gvet_regcampanha(i).codigocampanha
                           and pcpromi.vlvendamin > regitens.vlvendamax
                           and pcpromi.vlvendamax < vnvlminmaiorfaixafornec;

                        --se não tiver nenhuma faixa intermediária
                        if vicont = 0 then

                          vnqtminbrinde := to_number(regitens.qt);

                          if gvet_regcampanha(i).multiplo = 'S' then
                            vnqtminbrinde := trunc(trunc(to_number(vnvltotitens) /
                                                         to_number(regitens.vlvendamax)) *
                                                   to_number(regitens.qt));
                          end if;
                        end if;
                      end if;
                    end if;
                  end if;
                end if;

                if nvl(vnqtminbrinde, 0) > 0 then
                  vnqtbrinde := trunc(vnqtminbrinde);
                end if;

                if vnqtbrinde > 0 then
                  vnqtdispbrinde := 0;

                vscodfilialretira := p_codfilialretira;

                proc_verificafilialbrinde(p_Regpedido.numped,
                                          p_Regpedido.codfilial,
                                          gvet_regcampanha(i).codprod,
                                          vscodfilialretira);

                begin
                  -- Verificar Estoque para evitar o Corte do Brinde

                  BEGIN
                    SELECT NVL(QT, 0)
                      INTO vnQtNoPedido
                      FROM PCPEDI
                     WHERE CODPROD = regitens.codprod
                       AND CODFILIALRETIRA = vscodfilialretira
                       AND NUMPED = P_NUMPED;
                  EXCEPTION
                    WHEN OTHERS THEN
                      vnQtNoPedido := 0;
                  END;

                  select greatest(nvl(qtestger, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        DECODE(vsBLOQUEIAVENDAESTPENDENTE, 'S', NVL(QTPENDENTE, 0), 0)-
                        greatest(nvl(qtbloqueada, 0), 0) -
                        greatest(vnQtNoPedido),
                        greatest(nvl(qtest, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        greatest(vnQtNoPedido)
                    into vnqtdispbrinde,vnqtdispbrindecont
                    from pcest
                   where pcest.codprod = regitens.codprod
                     and pcest.codfilial = vscodfilialretira;

                exception
                  when others then
                    vnqtdispbrinde := 0;
                    vnqtdispbrindecont := 0;
                end;




                if  --se tem estoque gerencial disponivel OU
                    (
                      ((nvl(vnqtdispbrinde, 0) >= vnqtbrinde  ) or
                    --não tem estoque gerencial disp, mas o parametro permita gravar pendente E
                    ((nvl(vnqtdispbrinde, 0) < vnqtbrinde  ) and p_regfilial.aceitavendasemestfv = 'S')) AND
                    -- Um dos parametros para verificar estoque contábil marcado e tem disponivel contábil OU
                    (((nvl(vnqtdispbrindecont, 0) >= vnqtbrinde) and (NVL(p_regfilial.verificaestoquecont,p_regfilial.con_verificaestoquecont) = 'S') ) or
                    -- Parametros para verificar estoque contábil desmarcados
                     (p_regfilial.verificaestoquecont = 'N' or p_regfilial.con_verificaestoquecont = 'N'))
                    ) then

                   if nvl(vnqtdispbrinde, 0) < vnqtbrinde then
                      p_regpedido.posicao := 'P';

                       if vsmensagem is null then

                           vsmensagem := 'Pedido de brinde gravado Pendente. Brinde sem estoque disponivel. : '||gvet_regcampanha(i).codprod||' '||vsdescricao;
                        else

                            vsmensagem := vsmensagem||CHR(13)||'Pedido de brinde gravado Pendente. Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao || CHR(13);
                        end if;

                   end if;

                    vnnumitensbonific := vnnumitensbonific + 1;
                    gvet_regitempedbrinde(vnnumitensbonific).numpedrca        := p_regpedido.numpedrca;
                    gvet_regitempedbrinde(vnnumitensbonific).codprod          := regitens.codprod;
                    gvet_regitempedbrinde(vnnumitensbonific).qt               := vnqtbrinde;
                    gvet_regitempedbrinde(vnnumitensbonific).codfilialretira  := vscodfilialretira;
                    gvet_regitempedbrinde(vnnumitensbonific).qtlimitebrinde    := regitens.qtlimitebrinde;
                    gvet_regitempedbrinde(vnnumitensbonific).numcampanha       := gvet_regcampanha(i).numcampanha;
                    gvet_regitempedbrinde(vnnumitensbonific).codigocampanha    := gvet_regcampanha(i).codigocampanha;
                    gvet_regitempedbrinde(vnnumitensbonific).descricao         := vsdescricao;
                    gvet_regitempedbrinde(vnnumitensbonific).usadebcredrcabrind := gvet_regcampanha(i).usadebcredrcabrind;

                    begin
                    select codauxiliar
                      into gvet_regitempedbrinde(vnnumitensbonific).codauxiliar
                      from pcprodut
                     where codprod = gvet_regcampanha(i).codprod;
                  exception
                    when others then
                      gvet_regitempedbrinde(vnnumitensbonific) := null;
                  end;


                  else

                   if vsmensagem is null then

                       vsmensagem := 'Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao ;
                    else

                        vsmensagem := vsmensagem||CHR(13)||'Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao || CHR(13);
                    end if;


                  end if;
                end if;
              end if;
            end loop;
          end if;
        end if;

        --Quantidade E Valor
      elsif gvet_regcampanha(i).numcampanha = 6 then

        vicont        := 0;
        vnqtbrinde    := 0;
        vnqtminbrinde := 0;

        if (gvet_regcampanha(i).obrigavendamix = 'S' and vinaoexistemix = 0) or
           (gvet_regcampanha(i).obrigavendamix = 'N') then

          begin
            select count(*)
              into vicont
              from pcpromi, pcpedi, pcprodut
             where pcpedi.codprod = pcprodut.codprod
               and pcpromi.codprod =
                   decode(gvet_regcampanha(i).produtoprinc,
                          'N',
                          pcprodut.codprod,
                          pcprodut.codprodprinc)
               and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
               and pcpedi.numped = p_regpedido.numped;
          exception
            when no_data_found then
              vicont := 0;
          end;

          select descricao
            into vsdescricao
            from pcprodut
           where codprod = gvet_regcampanha(i).codprod;

          if vicont <> 0 then
            select sum(pcpedi.qt * pcpedi.pvenda) valor,
                   count(distinct(pcpedi.codprod)) qtprod,
                   sum(pcpedi.qt) qttotal
              into vnvltotitens, vnqtprod, vnqttotalitens
              from pcpedi
             where pcpedi.numped = p_regpedido.numped
               and exists
             (select 'x'
                      from pcpromi, pcprodut
                     where pcpedi.codprod = pcprodut.codprod
                       and pcpromi.codprod =
                           decode(gvet_regcampanha(i).produtoprinc,
                                  'N',
                                  pcprodut.codprod,
                                  pcprodut.codprodprinc)
                       and pcpromi.codigo = gvet_regcampanha(i).codigocampanha);

            if vnvltotitens >= gvet_regcampanha(i)
            .vltotvenda and vnqttotalitens >= gvet_regcampanha(i).qttotvenda then
              vnqtminbrinde := gvet_regcampanha(i).qtbrinde;

              if gvet_regcampanha(i).variosbrinde = 'S' then
                vnqtbrinde := trunc((least((vnvltotitens /
                                           gvet_regcampanha(i).vltotvenda),
                                           (vnqttotalitens /
                                           gvet_regcampanha(i).qttotvenda))))* vnqtminbrinde;
              else
                vnqtbrinde := trunc(vnqtminbrinde);
              end if;

              if vnqtbrinde > 0 then

                vnqtdispbrinde := 0;
                vnqtdispbrindecont := 0;

                vscodfilialretira := p_codfilialretira;

                proc_verificafilialbrinde(p_Regpedido.numped,
                                          p_Regpedido.codfilial,
                                          gvet_regcampanha(i).codprod,
                                          vscodfilialretira);
                begin
                  -- Verificar Estoque para evitar o Corte do Brinde

                  BEGIN
                    SELECT NVL(QT, 0)
                      INTO vnQtNoPedido
                      FROM PCPEDI
                     WHERE CODPROD = GVET_REGCAMPANHA(I).CODPROD
                       AND CODFILIALRETIRA = vscodfilialretira
                       AND NUMPED = P_NUMPED;
                  EXCEPTION
                    WHEN OTHERS THEN
                      vnQtNoPedido := 0;
                  END;

                  select greatest(nvl(qtestger, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        DECODE(vsBLOQUEIAVENDAESTPENDENTE, 'S', NVL(QTPENDENTE, 0), 0)-
                        greatest(nvl(qtbloqueada, 0), 0) -
                        greatest(vnQtNoPedido),
                        greatest(nvl(qtest, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        greatest(vnQtNoPedido)
                    into vnqtdispbrinde,vnqtdispbrindecont
                    from pcest
                   where pcest.codprod = gvet_regcampanha(i).codprod
                     and pcest.codfilial = vscodfilialretira;

                exception
                  when others then
                    vnqtdispbrinde := 0;
                    vnqtdispbrindecont := 0;
                end;




                if  --se tem estoque gerencial disponivel OU
                    (
                      ((nvl(vnqtdispbrinde, 0) >= vnqtbrinde  ) or
                    --não tem estoque gerencial disp, mas o parametro permita gravar pendente E
                    ((nvl(vnqtdispbrinde, 0) < vnqtbrinde  ) and p_regfilial.aceitavendasemestfv = 'S')) AND
                    -- Um dos parametros para verificar estoque contábil marcado e tem disponivel contábil OU
                    (((nvl(vnqtdispbrindecont, 0) >= vnqtbrinde) and (NVL(p_regfilial.verificaestoquecont,p_regfilial.con_verificaestoquecont) = 'S') ) or
                    -- Parametros para verificar estoque contábil desmarcados
                     (p_regfilial.verificaestoquecont = 'N' or p_regfilial.con_verificaestoquecont = 'N'))
                    ) then

                   if nvl(vnqtdispbrinde, 0) < vnqtbrinde then
                      p_regpedido.posicao := 'P';


                       if vsmensagem is null then

                           vsmensagem := 'Pedido de brinde gravado Pendente. Brinde sem estoque disponivel. : '||gvet_regcampanha(i).codprod||' '||vsdescricao ;
                        else

                            vsmensagem := vsmensagem||CHR(13)||'Pedido de brinde gravado Pendente. Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao || CHR(13);
                        end if;

                   end if;

                  vnnumitensbonific := vnnumitensbonific + 1;
                  gvet_regitempedbrinde(vnnumitensbonific).numpedrca        := p_regpedido.numpedrca;
                  gvet_regitempedbrinde(vnnumitensbonific).codprod          := gvet_regcampanha(i).codprod;
                  gvet_regitempedbrinde(vnnumitensbonific).qt               := vnqtbrinde;
                  gvet_regitempedbrinde(vnnumitensbonific).codfilialretira  := vscodfilialretira;
                  gvet_regitempedbrinde(vnnumitensbonific).qtlimitebrinde    := gvet_regcampanha(i).qtlimitebrinde;
                  gvet_regitempedbrinde(vnnumitensbonific).numcampanha       := gvet_regcampanha(i).numcampanha;
                  gvet_regitempedbrinde(vnnumitensbonific).codigocampanha    := gvet_regcampanha(i).codigocampanha;
                  gvet_regitempedbrinde(vnnumitensbonific).descricao         := vsdescricao;
                  gvet_regitempedbrinde(vnnumitensbonific).usadebcredrcabrind := gvet_regcampanha(i).usadebcredrcabrind;

                  begin
                    select codauxiliar
                      into gvet_regitempedbrinde(vnnumitensbonific).codauxiliar
                      from pcprodut
                     where codprod = gvet_regcampanha(i).codprod;
                  exception
                    when others then
                      gvet_regitempedbrinde(vnnumitensbonific) := null;
                  end;

                else

                   if vsmensagem is null then

                       vsmensagem := 'Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao;
                    else

                        vsmensagem := vsmensagem||CHR(13)||'Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao || CHR(13);
                    end if;


                end if;
              end if;
            end if;
          end if;
        end if;

        --Quantidade OU Valor
      elsif gvet_regcampanha(i).numcampanha = 7 then

        vicont := 0;

        if (gvet_regcampanha(i).obrigavendamix = 'S' and vinaoexistemix = 0) or
           (gvet_regcampanha(i).obrigavendamix = 'N') then

          begin
            select count(*)
              into vicont
              from pcpromi, pcpedi, pcprodut
             where pcpedi.codprod = pcprodut.codprod
               and pcpromi.codprod =
                   decode(gvet_regcampanha(i).produtoprinc,
                          'N',
                          pcprodut.codprod,
                          pcprodut.codprodprinc)
               and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
               and pcpedi.numped = p_regpedido.numped;
          exception
            when no_data_found then
              vicont := 0;
          end;

          select descricao
            into vsdescricao
            from pcprodut
           where codprod = gvet_regcampanha(i).codprod;

          vnqtbrinde    := 0;
          vnqtminbrinde := 0;

          if vicont <> 0 then
            select sum(pcpedi.qt * pcpedi.pvenda) valor,
                   count(distinct(pcpedi.codprod)) qtprod,
                   sum(pcpedi.qt) qttotal
              into vnvltotitens, vnqtprod, vnqttotalitens
              from pcpedi
             where pcpedi.numped = p_regpedido.numped
               and exists
             (select 'x'
                      from pcpromi, pcprodut
                     where pcpedi.codprod = pcprodut.codprod
                       and pcpromi.codprod =
                           decode(gvet_regcampanha(i).produtoprinc,
                                  'N',
                                  pcprodut.codprod,
                                  pcprodut.codprodprinc)
                       and pcpromi.codigo = gvet_regcampanha(i).codigocampanha);

            if (vnvltotitens >= gvet_regcampanha(i).vltotvenda) or
               (vnqttotalitens >= gvet_regcampanha(i).qttotvenda) then

              vnqtminbrinde := gvet_regcampanha(i).qtbrinde;

              if gvet_regcampanha(i).variosbrinde = 'S' then
                vnqtbrinde := trunc((greatest((vnvltotitens /
                                              gvet_regcampanha(i).vltotvenda),
                                              (vnqttotalitens /
                                              gvet_regcampanha(i).qttotvenda))))*vnqtminbrinde;
              else
                vnqtbrinde := trunc(vnqtminbrinde);
              end if;

              if vnqtbrinde > 0 then

                vnqtdispbrinde := 0;
                vnqtdispbrindecont := 0;

                vscodfilialretira := p_codfilialretira;

                proc_verificafilialbrinde(p_Regpedido.numped,
                                          p_Regpedido.codfilial,
                                          gvet_regcampanha(i).codprod,
                                          vscodfilialretira);


                begin
                  -- Verificar Estoque para evitar o Corte do Brinde
                  BEGIN
                    SELECT NVL(QT, 0)
                      INTO vnQtNoPedido
                      FROM PCPEDI
                     WHERE CODPROD = GVET_REGCAMPANHA(I).CODPROD
                       AND CODFILIALRETIRA = vscodfilialretira
                       AND NUMPED = P_NUMPED;
                  EXCEPTION
                    WHEN OTHERS THEN
                      vnQtNoPedido := 0;
                  END;

                  select greatest(nvl(qtestger, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        DECODE(vsBLOQUEIAVENDAESTPENDENTE, 'S', NVL(QTPENDENTE, 0), 0)-
                        greatest(nvl(qtbloqueada, 0), 0) -
                        greatest(vnQtNoPedido),
                        greatest(nvl(qtest, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        greatest(vnQtNoPedido)
                    into vnqtdispbrinde,vnqtdispbrindecont
                    from pcest
                   where pcest.codprod = gvet_regcampanha(i).codprod
                     and pcest.codfilial = vscodfilialretira;

                exception
                  when others then
                    vnqtdispbrinde := 0;
                    vnqtdispbrindecont := 0;
                end;




                if  --se tem estoque gerencial disponivel OU
                    (
                      ((nvl(vnqtdispbrinde, 0) >= vnqtbrinde  ) or
                    --não tem estoque gerencial disp, mas o parametro permita gravar pendente E
                    ((nvl(vnqtdispbrinde, 0) < vnqtbrinde  ) and p_regfilial.aceitavendasemestfv = 'S')) AND
                    -- Um dos parametros para verificar estoque contábil marcado e tem disponivel contábil OU
                    (((nvl(vnqtdispbrindecont, 0) >= vnqtbrinde) and (NVL(p_regfilial.verificaestoquecont,p_regfilial.con_verificaestoquecont) = 'S') ) or
                    -- Parametros para verificar estoque contábil desmarcados
                     (p_regfilial.verificaestoquecont = 'N' or p_regfilial.con_verificaestoquecont = 'N'))
                    ) then

                   if nvl(vnqtdispbrinde, 0) < vnqtbrinde then
                      p_regpedido.posicao := 'P';


                       if vsmensagem is null then

                           vsmensagem := 'Pedido de brinde gravado Pendente. Brinde sem estoque disponivel. : '||gvet_regcampanha(i).codprod||' '||vsdescricao;
                        else

                            vsmensagem := vsmensagem||CHR(13)||'Pedido de brinde gravado Pendente. Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao || CHR(13);
                        end if;

                   end if;

                  vnnumitensbonific := vnnumitensbonific + 1;
                  gvet_regitempedbrinde(vnnumitensbonific).numpedrca        := p_regpedido.numpedrca;
                  gvet_regitempedbrinde(vnnumitensbonific).codprod          := gvet_regcampanha(i).codprod;
                  gvet_regitempedbrinde(vnnumitensbonific).qt               := vnqtbrinde;
                  gvet_regitempedbrinde(vnnumitensbonific).codfilialretira  := vscodfilialretira;
                  gvet_regitempedbrinde(vnnumitensbonific).qtlimitebrinde    := gvet_regcampanha(i).qtlimitebrinde;
                  gvet_regitempedbrinde(vnnumitensbonific).numcampanha       := gvet_regcampanha(i).numcampanha;
                  gvet_regitempedbrinde(vnnumitensbonific).codigocampanha    := gvet_regcampanha(i).codigocampanha;
                  gvet_regitempedbrinde(vnnumitensbonific).descricao         := vsdescricao;
                  gvet_regitempedbrinde(vnnumitensbonific).usadebcredrcabrind := gvet_regcampanha(i).usadebcredrcabrind;

                  begin
                    select codauxiliar
                      into gvet_regitempedbrinde(vnnumitensbonific).codauxiliar
                      from pcprodut
                     where codprod = gvet_regcampanha(i).codprod;
                  exception
                    when others then
                      gvet_regitempedbrinde(vnnumitensbonific) := null;
                  end;

                else

                   if vsmensagem is null then

                       vsmensagem := 'Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao ;
                    else

                        vsmensagem := vsmensagem||CHR(13)||'Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao || CHR(13);
                    end if;



                end if;
              end if;
            end if;
          end if;
        end if;


      --Valor Total e quantidade para alguns itens
      elsif gvet_regcampanha(i).numcampanha = 8 then

        vicont := 0;
           vnqtminbrinde := 0;

        if (gvet_regcampanha(i).obrigavendamix = 'S' and vinaoexistemix = 0) or
           (gvet_regcampanha(i).obrigavendamix = 'N') then

          begin
            select count(*)
              into vicont
              from pcpromi, pcpedi, pcprodut
             where pcpedi.codprod = pcprodut.codprod
               and pcpromi.codprod =
                   decode(gvet_regcampanha(i).produtoprinc,
                          'N',
                          pcprodut.codprod,
                          pcprodut.codprodprinc)
               and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
               and pcpedi.numped = p_regpedido.numped;
          exception
            when no_data_found then

              vicont := 0;

          end;

          select descricao
            into vsdescricao
            from pcprodut
           where codprod = gvet_regcampanha(i).codprod;

            vnqtbrinde := 0;



          if vicont <> 0 then

            select sum(pcpedi.qt * pcpedi.pvenda) valor
              into vnvltotitens
              from pcpedi
              where pcpedi.numped = p_regpedido.numped
              and exists (select 'x'
                          from  pcpromi, pcprodut
                           where pcpedi.codprod = pcprodut.codprod
                             and pcpromi.codprod =
                                 decode(gvet_regcampanha(i).produtoprinc,
                                        'N',
                                        pcprodut.codprod,
                                        pcprodut.codprodprinc)
                             and pcpromi.codigo = gvet_regcampanha(i).codigocampanha);



            if (vnvltotitens >= gvet_regcampanha(i).vltotvenda)  then

                vbnaoatende := false;

                --verifica se as quantidades dos itens obrigatorios foram atendidas
               for reg1 in ( select pcprodut.codprod,pcpromi.qt,pcpromi.prodobrig
                             from  pcpromi, pcprodut
                              where pcpromi.codprod =
                                                 decode(gvet_regcampanha(i).produtoprinc,
                                                        'N',
                                                        pcprodut.codprod,
                                                        pcprodut.codprodprinc)
                              and pcpromi.codigo = gvet_regcampanha(i).codigocampanha) loop


                     Begin
                       select pcpedi.qt
                         into vnqtvendida
                         from pcpedi
                        where numped = p_regpedido.numped
                          and codprod = reg1.codprod;
                     exception
                       when others then
                         vnqtvendida := 0;
                     end;


                     if reg1.prodobrig = 'S' and reg1.qt > vnqtvendida then

                        vbnaoatende := true;

                     end if;


               end loop;

               if vbnaoatende = false then


                      vnqtminbrinde := gvet_regcampanha(i).qtbrinde;



                    if gvet_regcampanha(i).variosbrinde = 'S' then

                      vnqtbrinde := trunc((vnvltotitens / gvet_regcampanha(i).vltotvenda))*vnqtminbrinde;

                    else

                      vnqtbrinde := trunc(vnqtminbrinde);
                    end if;

                    if vnqtbrinde > 0 then
                      vnqtdispbrinde := 0;
                      vnqtdispbrindecont := 0;


                vscodfilialretira := p_codfilialretira;

                proc_verificafilialbrinde(p_Regpedido.numped,
                                          p_Regpedido.codfilial,
                                          gvet_regcampanha(i).codprod,
                                          vscodfilialretira);


                begin
                  -- Verificar Estoque para evitar o Corte do Brinde

                  BEGIN
                    SELECT NVL(QT, 0)
                      INTO vnQtNoPedido
                      FROM PCPEDI
                     WHERE CODPROD = GVET_REGCAMPANHA(I).CODPROD
                       AND CODFILIALRETIRA = vscodfilialretira
                       AND NUMPED = P_NUMPED;
                  EXCEPTION
                    WHEN OTHERS THEN
                      vnQtNoPedido := 0;
                  END;

                  select greatest(nvl(qtestger, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        DECODE(vsBLOQUEIAVENDAESTPENDENTE, 'S', NVL(QTPENDENTE, 0), 0)-
                        greatest(nvl(qtbloqueada, 0), 0) -
                        greatest(vnQtNoPedido),
                        greatest(nvl(qtest, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        greatest(vnQtNoPedido)
                    into vnqtdispbrinde,vnqtdispbrindecont
                    from pcest
                   where pcest.codprod = gvet_regcampanha(i).codprod
                     and pcest.codfilial = vscodfilialretira;

                exception
                  when others then
                    vnqtdispbrinde := 0;
                    vnqtdispbrindecont := 0;
                end;




                if  --se tem estoque gerencial disponivel OU
                    (
                      ((nvl(vnqtdispbrinde, 0) >= vnqtbrinde  ) or
                    --não tem estoque gerencial disp, mas o parametro permita gravar pendente E
                    ((nvl(vnqtdispbrinde, 0) < vnqtbrinde  ) and p_regfilial.aceitavendasemestfv = 'S')) AND
                    -- Um dos parametros para verificar estoque contábil marcado e tem disponivel contábil OU
                    (((nvl(vnqtdispbrindecont, 0) >= vnqtbrinde) and (NVL(p_regfilial.verificaestoquecont,p_regfilial.con_verificaestoquecont) = 'S') ) or
                    -- Parametros para verificar estoque contábil desmarcados
                     (p_regfilial.verificaestoquecont = 'N' or p_regfilial.con_verificaestoquecont = 'N'))
                    ) then

                   if nvl(vnqtdispbrinde, 0) < vnqtbrinde then
                      p_regpedido.posicao := 'P';

                       if vsmensagem is null then

                           vsmensagem := 'Pedido de brinde gravado Pendente. Brinde sem estoque disponivel. : '||gvet_regcampanha(i).codprod||' '||vsdescricao;
                        else

                            vsmensagem := vsmensagem||CHR(13)||'Pedido de brinde gravado Pendente. Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao || CHR(13);
                        end if;

                   end if;

                        vnnumitensbonific := vnnumitensbonific + 1;
                        gvet_regitempedbrinde(vnnumitensbonific).numpedrca         := p_regpedido.numped;
                        gvet_regitempedbrinde(vnnumitensbonific).codprod           := gvet_regcampanha(i).codprod;
                        gvet_regitempedbrinde(vnnumitensbonific).qt                := vnqtbrinde;
                        gvet_regitempedbrinde(vnnumitensbonific).codfilialretira   := vscodfilialretira;
                        gvet_regitempedbrinde(vnnumitensbonific).qtlimitebrinde    := gvet_regcampanha(i).qtlimitebrinde;
                        gvet_regitempedbrinde(vnnumitensbonific).numcampanha       := gvet_regcampanha(i).numcampanha;
                        gvet_regitempedbrinde(vnnumitensbonific).codigocampanha    := gvet_regcampanha(i).codigocampanha;
                        gvet_regitempedbrinde(vnnumitensbonific).descricao         := vsdescricao;
                        gvet_regitempedbrinde(vnnumitensbonific).usadebcredrcabrind := gvet_regcampanha(i).usadebcredrcabrind;

                        begin
                    select codauxiliar
                      into gvet_regitempedbrinde(vnnumitensbonific).codauxiliar
                      from pcprodut
                     where codprod = gvet_regcampanha(i).codprod;
                  exception
                    when others then
                      gvet_regitempedbrinde(vnnumitensbonific) := null;
                  end;


                      else

                         if vsmensagem is null then

                             vsmensagem := 'Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao ;
                          else

                              vsmensagem := vsmensagem||CHR(13)||'Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao || CHR(13);
                          end if;

                  end if;
                end if;
            end if;
          end if;
         end if;
        end if;

        --Valor Total  com Restricoes
      elsif gvet_regcampanha(i).numcampanha = 9 then

        vicont     := 0;
        vicont2    := 0;
        vnqtbrinde := 0;

        if (gvet_regcampanha(i).obrigavendamix = 'S' and vinaoexistemix = 0) or
           (gvet_regcampanha(i).obrigavendamix = 'N') then

          begin
            select count(*)
              into vicont
              from pcpromi, pcpedi, pcprodut
             where pcpedi.codprod = pcprodut.codprod
               and pcpromi.codprod =
                   decode(gvet_regcampanha(i).produtoprinc,
                          'N',
                          pcprodut.codprod,
                          pcprodut.codprodprinc)
               and pcpromi.codigo = gvet_regcampanha(i)
            .codigocampanha
               and pcpedi.numped = p_regpedido.numped;
          exception
            when no_data_found then

              vicont := 0;

          end;

          select descricao
            into vsdescricao
            from pcprodut
           where codprod = gvet_regcampanha(i).codprod;

          if vicont <> 0 then

            select count(*)
              into vicontpcpromi
              from pcpromi, pcpedi, pcprodut
             where pcpedi.codprod = pcprodut.codprod
               and pcpromi.codprod =
                   decode(gvet_regcampanha(i).produtoprinc,
                          'N',
                          pcprodut.codprod,
                          pcprodut.codprodprinc)
               and pcpromi.codigo = gvet_regcampanha(i)
            .codigocampanha
               and pcpedi.numped = p_regpedido.numped
               and pcpromi.qt > 0;

            --Não existe nenhum item com quantidade informada na pcpromi
            if vicontpcpromi = 0 then

              select sum(pcpedi.qt * pcpedi.pvenda) valor,
                     sum(pcpedi.qt) qtprod
                into vnvltotitens, vnqtprod
                from pcpromi, pcpedi, pcprodut
               where pcpedi.codprod = pcprodut.codprod
                 and pcpromi.codprod =
                     decode(gvet_regcampanha(i).produtoprinc,
                            'N',
                            pcprodut.codprod,
                            pcprodut.codprodprinc)
                 and pcpromi.codigo = gvet_regcampanha(i)
              .codigocampanha
                 and pcpedi.numped = p_regpedido.numped;

            vnqtbrinde := 0;
            vnqtminbrinde := 0;


              if vnvltotitens >= gvet_regcampanha(i).vltotvenda then


                 if gvet_Regcampanha(i).restricaovalormin is not null or gvet_Regcampanha(i).restricaoqtmin is not null then

                        select sum(pcpedi.qt * pcpedi.pvenda) valor,
                               sum(pcpedi.qt) qtprod
                          into vnvltotitensrest, vnqtprodrest
                          from pcpromi, pcpedi, pcprodut
                         where pcpedi.codprod = pcprodut.codprod
                           and pcpromi.codprod =
                               decode(gvet_regcampanha(i).produtoprinc,
                                      'N',
                                      pcprodut.codprod,
                                      pcprodut.codprodprinc)
                           and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
                           and pcpedi.numped = p_regpedido.numped
                           and pcpromi.restricaogrupo = 'S';


                        if (gvet_Regcampanha(i).restricaovalormin is null OR (gvet_Regcampanha(i).restricaovalormin is not null and
                             nvl(vnvltotitensrest,0) >= gvet_Regcampanha(i).restricaovalormin) ) AND
                            (gvet_Regcampanha(i).restricaoqtmin is null OR (gvet_Regcampanha(i).restricaoqtmin is not null and
                             nvl(vnqtprodrest,0) >= gvet_Regcampanha(i).restricaoqtmin) ) then

                            vnqtminbrinde := gvet_regcampanha(i).qtbrinde;

                            vnqtbrinde := trunc(vnqtminbrinde);

                              if gvet_regcampanha(i).variosbrinde = 'S' then

                                vnqtbrinde := trunc(trunc(vnvltotitens / to_number(gvet_regcampanha(i)
                                                                 .vltotvenda)))* nvl(vnqtminbrinde,0);
                              else

                                vnqtbrinde := trunc(vnqtminbrinde);
                              end if;
                        end if;


                  else


                            --verifica quantos itens existem na pcpedi e na pcpromi
                            begin
                              select count(*)
                                into vicont
                                from pcpromi, pcpedi, pcprodut
                               where pcpedi.codprod = pcprodut.codprod
                                 and pcpromi.codprod =
                                     decode(gvet_regcampanha(i).produtoprinc,
                                            'N',
                                            pcprodut.codprod,
                                            pcprodut.codprodprinc)
                                 --and pcpedi.qt >= pcpromi.qt
                                 and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
                                 and pcpedi.numped = p_regpedido.numped;
                            exception
                              when no_data_found then

                                vicont := 0;

                            end;


                            --verifica quantos itens que existem na pcpedi e na pcpromi com as quantidades ou valores atendidos
                            begin
                              select count(*)
                                into vicont2
                                from pcpromi, pcpedi, pcprodut
                               where pcpedi.codprod = pcprodut.codprod
                                 and pcpromi.codprod =
                                     decode(gvet_regcampanha(i).produtoprinc,
                                            'N',
                                            pcprodut.codprod,
                                            pcprodut.codprodprinc)
                                 and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
                                 and pcpedi.numped = p_regpedido.numped
                                 and (((pcpromi.restricaoqtmin is null) or (pcpromi.restricaoqtmin is not null and pcpedi.qt >= pcpromi.restricaoqtmin)) and
                                      ((pcpromi.restricaovalormin is null) or (pcpromi.restricaovalormin is not null and (pcpedi.qt * pcpedi.pvenda) >= pcpromi.restricaovalormin)));

                            exception
                              when no_data_found then

                                vicont2 := 0;

                            end;

                             if gvet_Regcampanha(i).produtoprinc = 'S' then

                             begin
                                  select counT(*)
                                  into vicont2
                                  from pcpromi p,pcpedi i,pcprodut t,
                                       (select pcpromi.codprod,sum(pcpedi.qt) qt,sum(pcpedi.qt * pcpedi.pvenda) valor
                                                from pcpromi, pcpedi, pcprodut
                                               where pcpedi.codprod = pcprodut.codprod
                                                 and pcpromi.codprod =  decode(gvet_regcampanha(i).produtoprinc, 'N',  pcprodut.codprod,  pcprodut.codprodprinc)
                                                 and pcpromi.codigo = gvet_regcampanha(i).codigocampanha
                                                 and pcpedi.numped = p_regpedido.numped
                                         group by pcpromi.codprod) tab
                                  where p.codprod = tab.codprod
                                  and   p.codigo = gvet_regcampanha(i).codigocampanha
                                  and   i.codprod = t.codprod
                                  and   p.codprod =  decode(gvet_regcampanha(i).produtoprinc, 'N',  t.codprod,  t.codprodprinc)
                                  and   i.numped =   p_regpedido.numped
                                  and (((p.restricaoqtmin is null) or (p.restricaoqtmin is not null and tab.qt >= p.restricaoqtmin)) and
                                      ((p.restricaovalormin is null) or (p.restricaovalormin is not null and tab.valor >= p.restricaovalormin)));
                              exception when no_data_found then
                                vicont2 := 0;
                              end;

                             end if;

                             if vicont = vicont2 then


                                vnqtminbrinde := gvet_regcampanha(i).qtbrinde;

                                vnqtbrinde := trunc(vnqtminbrinde);

                                  if gvet_regcampanha(i).variosbrinde = 'S' then

                                    vnqtbrinde := trunc(trunc(vnvltotitens / to_number(gvet_regcampanha(i)
                                                                     .vltotvenda)))* nvl(vnqtminbrinde,0);
                                  else

                                    vnqtbrinde := trunc(vnqtminbrinde);
                                  end if;


                             end if;



                  end if;

              end if;

                vscodfilialretira := p_codfilialretira;

                proc_verificafilialbrinde(p_Regpedido.numped,
                                          p_Regpedido.codfilial,
                                          gvet_regcampanha(i).codprod,
                                          vscodfilialretira);

              if vnqtbrinde > 0 then
                vnqtdispbrinde := 0;
                vnqtdispbrindecont := 0;

                begin
                  -- Verificar Estoque para evitar o Corte do Brinde
                  BEGIN
                    SELECT NVL(QT, 0)
                      INTO vnQtNoPedido
                      FROM PCPEDI
                     WHERE CODPROD = GVET_REGCAMPANHA(I).CODPROD
                       AND CODFILIALRETIRA = vscodfilialretira
                       AND NUMPED = P_NUMPED;
                  EXCEPTION
                    WHEN OTHERS THEN
                      vnQtNoPedido := 0;
                  END;

                  select greatest(nvl(qtestger, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        DECODE(vsBLOQUEIAVENDAESTPENDENTE, 'S', NVL(QTPENDENTE, 0), 0)-
                        greatest(nvl(qtbloqueada, 0), 0) -
                        greatest(vnQtNoPedido),
                        greatest(nvl(qtest, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        greatest(vnQtNoPedido)
                    into vnqtdispbrinde,vnqtdispbrindecont
                    from pcest
                   where pcest.codprod = gvet_regcampanha(i).codprod
                     and pcest.codfilial = vscodfilialretira;

                exception
                  when others then
                    vnqtdispbrinde := 0;
                    vnqtdispbrindecont := 0;
                end;




                if  --se tem estoque gerencial disponivel OU
                    (
                      ((nvl(vnqtdispbrinde, 0) >= vnqtbrinde  ) or
                    --não tem estoque gerencial disp, mas o parametro permita gravar pendente E
                    ((nvl(vnqtdispbrinde, 0) < vnqtbrinde  ) and p_regfilial.aceitavendasemestfv = 'S')) AND
                    -- Um dos parametros para verificar estoque contábil marcado e tem disponivel contábil OU
                    (((nvl(vnqtdispbrindecont, 0) >= vnqtbrinde) and (NVL(p_regfilial.verificaestoquecont,p_regfilial.con_verificaestoquecont) = 'S') ) or
                    -- Parametros para verificar estoque contábil desmarcados
                     (p_regfilial.verificaestoquecont = 'N' or p_regfilial.con_verificaestoquecont = 'N'))
                    ) then

                   if nvl(vnqtdispbrinde, 0) < vnqtbrinde then
                      p_regpedido.posicao := 'P';


                       if vsmensagem is null then

                           vsmensagem := 'Pedido de brinde gravado Pendente. Brinde sem estoque disponivel. : '||gvet_regcampanha(i).codprod||' '||vsdescricao ;
                        else

                            vsmensagem := vsmensagem||CHR(13)||'Pedido de brinde gravado Pendente. Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao || CHR(13);
                        end if;

                   end if;

                  vnnumitensbonific := vnnumitensbonific + 1;
                  gvet_regitempedbrinde(vnnumitensbonific).numpedrca := p_regpedido.numpedrca;
                  gvet_regitempedbrinde(vnnumitensbonific).codprod   := gvet_regcampanha(i).codprod;
                  gvet_regitempedbrinde(vnnumitensbonific).qt        := vnqtbrinde;
                  gvet_regitempedbrinde(vnnumitensbonific).codfilialretira   := vscodfilialretira;
                  gvet_regitempedbrinde(vnnumitensbonific).qtlimitebrinde    := gvet_regcampanha(i).qtlimitebrinde;
                  gvet_regitempedbrinde(vnnumitensbonific).numcampanha       := gvet_regcampanha(i).numcampanha;
                  gvet_regitempedbrinde(vnnumitensbonific).codigocampanha    := gvet_regcampanha(i).codigocampanha;
                  gvet_regitempedbrinde(vnnumitensbonific).descricao         := vsdescricao;
                  gvet_regitempedbrinde(vnnumitensbonific).usadebcredrcabrind := gvet_regcampanha(i).usadebcredrcabrind;

                  begin
                    select codauxiliar
                      into gvet_regitempedbrinde(vnnumitensbonific).codauxiliar
                      from pcprodut
                     where codprod = gvet_regcampanha(i).codprod;
                  exception
                    when others then
                      gvet_regitempedbrinde(vnnumitensbonific) := null;
                  end;



                else
                   if vsmensagem is null then

                       vsmensagem := 'Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao ;
                    else

                        vsmensagem := vsmensagem||CHR(13)||'Brinde sem estoque disponivel : '||gvet_regcampanha(i).codprod||' '||vsdescricao || CHR(13);
                    end if;


                end if;
              end if;
            end if;
          end if;

        end if;


      end if;
    end loop;

    exception when others then

           if vsmensagem is null then

               vsmensagem := 'Erro ao verificar Brindes :'||SQLCODE||' - '||SQLERRM || CHR(13);
            else

                vsmensagem := vsmensagem||CHR(13)||'Erro ao verificar Brindes :'||SQLCODE||' - '||SQLERRM ||CHR(13);
            end if;




    end;


    --tarefa 162743 Verificação de Brindes Express
    <<REPROCESSABRINDE>>
    BEGIN
    --monta o sql dinamico para trazer agrupado já as qtdes dos brindes com produtos iguais ou não
     --depedendo do parametro 1105 da rotina 132
     if vsSOMAQTPEDVENDA = 'S' Then
        vsMeuSqlDinamicoBrindes := 'SELECT codbrinde,
                               MAX(codcamp) codcamp,
                               embalagem,
                               sum(qtde) as qtde,
                               descricao,
                               usadebcredrca,
                                MAX(grpregrabrinde) grpregrabrinde
                          FROM TABLE(PKG_BRINDEEX.REL_BRINDES('||p_regpedido.numped||')) p
                          GROUP BY codbrinde, embalagem, descricao, usadebcredrca';
       else
         vsMeuSqlDinamicoBrindes := 'SELECT codbrinde,
                                 codcamp,
                                 embalagem,
                                 sum(qtde) as qtde,
                                 descricao,
                                 usadebcredrca,
                                 grpregrabrinde
                            FROM TABLE(PKG_BRINDEEX.REL_BRINDES('||p_regpedido.numped||')) p
                           GROUP BY codbrinde,
                                    codcamp,
                                    embalagem,
                                    descricao,
                                    usadebcredrca,
                                 grpregrabrinde';
       end if;

    /* for reg_brindeex in  ( SELECT codbrinde
                                       ,codcamp
                                       ,embalagem
                                       ,sum(qtde) as qtde
                                       ,descricao
                                       ,usadebcredrca
                                       ,grpregrabrinde
                                 FROM TABLE(PKG_BRINDEEX.REL_BRINDES(p_regpedido.numped)) p
                                   GROUP BY codbrinde,codcamp,embalagem,descricao,usadebcredrca,grpregrabrinde) loop
       */
       OPEN l_cursor_brindex FOR
         vsMeuSqlDinamicoBrindes;

       loop


           FETCH l_cursor_brindex INTO reg_brindeex;

           EXIT WHEN l_cursor_brindex%NOTFOUND;
              --if reg_brindeex.estdisp = 'S' then

                vnqtdispbrinde := 0;
                vnqtdispbrindecont := 0;

                vscodfilialretira := p_codfilialretira;
                IF nvl(reg_brindeex.codcamp,0) > 0 and nvl(reg_brindeex.qtde,0) = 0 then
                  VSMENSAGEM := VSMENSAGEM || CHR(13) ||
                                            'Produto brinde ' || reg_brindeex.codbrinde ||
                                             ', do codigo de campanha ' || reg_brindeex.codcamp || ' retornou com quantidade = 0.'
                                              || chr(13) ||
                                             'Favor verificar quantidade de brinde a ser concedido cadastro na rotina 3320.';

                  VBVALIDO := FALSE;
                END IF;

                IF nvl(reg_brindeex.codcamp, 0) > 0 and
                  (nvl(reg_brindeex.qtde, 0) > 0 and nvl(reg_brindeex.qtde, 0) < 1) then

                  begin
                    select nvl(pcprodfilial.aceitavendafracao, 'N')
                      into vsaceitavendafracao
                      from pcprodfilial
                     where pcprodfilial.codfilial = p_codfilialretira
                       and pcprodfilial.codprod = reg_brindeex.codbrinde;
                  exception
                    when others then
                      vsaceitavendafracao := 'N';
                  end;

                  if ((p_regcliente.aceitavendafracao = 'N') or
                     (vsaceitavendafracao = 'N')) then

                    vsRegraQuem := case
                                     when (p_regcliente.aceitavendafracao = 'N') then
                                      'CLIENTE'
                                     else
                                      'PRODUTO'
                                   end;

                    VSMENSAGEM := VSMENSAGEM || CHR(13) || 'Produto brinde ' ||
                                  reg_brindeex.codbrinde ||
                                  ', do codigo de campanha ' ||
                                  reg_brindeex.codcamp ||
                                  ' retornou com quantidade brinde fracionada: ' ||
                                  reg_brindeex.qtde || ' e ' || vsRegraQuem ||
                                  ' não aceita quantidade fracionada. ' || chr(13) ||
                                  'Favor verificar quantidade de brinde a ser concedido cadastro na rotina 3320. ';

                    VBVALIDO := FALSE;
                  END IF;
                END IF;

                proc_verificafilialbrinde(p_Regpedido.numped,
                                          p_Regpedido.codfilial,
                                          reg_brindeex.codbrinde,
                                          vscodfilialretira);

                -- Obter qtunit para conversão de embalagem
                if p_regfilial.utilizavendaporembalagem = 'S' then
                  BEGIN
                    SELECT NVL(CODAUXILIAR, 0) CODAUXILIAR
                      INTO VNCODAUXILIAR
                      FROM PCBRINDEEXPREMIO
                     WHERE CODPROD = REG_BRINDEEX.CODBRINDE
                       AND CODBREX = REG_BRINDEEX.CODCAMP
					   AND GRUPOREGRA = REG_BRINDEEX.GRPREGRABRINDE;
                  EXCEPTION
                    WHEN OTHERS THEN
                      VNCODAUXILIAR := 0;
                  END;

                  IF NVL(VNCODAUXILIAR, 0) = 0 THEN
                    BEGIN
                      SELECT NVL(CODAUXILIAR, 0) CODAUXILIAR
                        INTO VNCODAUXILIAR
                        FROM PCPRODUT
                       WHERE CODPROD = REG_BRINDEEX.CODBRINDE;
                    EXCEPTION
                      WHEN OTHERS THEN
                        VNCODAUXILIAR := 0;
                    END;
                  END IF;

                  IF VNCODAUXILIAR = 0 THEN
                    IF VSMENSAGEM IS NULL
                    THEN
                      VSMENSAGEM := 'NÃO FOI LOCALIZADO O CÓDIGO AUXILIAR PARA BUSCAR A EMBALAGEM.';
                    ELSE
                      VSMENSAGEM := VSMENSAGEM || CHR(13) ||
                                    'NÃO FOI LOCALIZADO O CÓDIGO AUXILIAR PARA BUSCAR A EMBALAGEM.';
                    END IF;
                    VBVALIDO := FALSE;
                  END IF;

                  begin
                    select e.qtunit into vnqtunit
                      from pcembalagem e
                     where e.codprod     = reg_brindeex.codbrinde
                       and e.codfilial   = vscodfilialretira
                       and e.codauxiliar = VNCODAUXILIAR;

                       p_regproduto.qtunit := vnqtunit;
                  exception when others then
                    vnqtunit := 1;
                    vncodauxiliar := null;
                  end;
                end if;

                begin
                  -- Verificar Estoque para evitar o Corte do Brinde
                  BEGIN
                    SELECT NVL(QT, 0)
                      INTO vnQtNoPedido
                      FROM PCPEDI
                     WHERE CODPROD = reg_brindeex.codbrinde
                       AND CODFILIALRETIRA = vscodfilialretira
                       AND NUMPED = P_NUMPED;
                  EXCEPTION
                    WHEN OTHERS THEN
                      vnQtNoPedido := 0;
                  END;

                  select greatest(nvl(qtestger, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        DECODE(vsBLOQUEIAVENDAESTPENDENTE, 'S', NVL(QTPENDENTE, 0), 0)-
                        greatest(nvl(qtbloqueada, 0), 0) -
                        greatest(vnQtNoPedido),
                        greatest(nvl(qtest, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        greatest(vnQtNoPedido)
                    into vnqtdispbrinde,vnqtdispbrindecont
                    from pcest
                   where pcest.codprod = reg_brindeex.codbrinde
                     and pcest.codfilial = vscodfilialretira;

                exception
                  when others then
                    vnqtdispbrinde := 0;
                    vnqtdispbrindecont := 0;
                end;

                        vnqtbrinde := reg_brindeex.qtde * nvl(vnqtunit, 1);
                reg_brindeex.qtde := vnqtbrinde;


                if  --se tem estoque gerencial disponivel OU
                    (
                      ((nvl(vnqtdispbrinde, 0) >= vnqtbrinde  ) or
                    --não tem estoque gerencial disp, mas o parametro permita gravar pendente E
                    ((nvl(vnqtdispbrinde, 0) < vnqtbrinde  ) and p_regfilial.aceitavendasemestfv = 'S')) AND
                    -- Um dos parametros para verificar estoque contábil marcado e tem disponivel contábil OU
                    (((nvl(vnqtdispbrindecont, 0) >= vnqtbrinde) and (NVL(p_regfilial.verificaestoquecont,p_regfilial.con_verificaestoquecont) = 'S') ) or
                    -- Parametros para verificar estoque contábil desmarcados
                     (p_regfilial.verificaestoquecont = 'N' or p_regfilial.con_verificaestoquecont = 'N'))
                    ) then

                   if nvl(vnqtdispbrinde, 0) < reg_brindeex.qtde then
                      p_regpedido.posicao := 'P';

                   end if;



                  vnnumitensbonific := nvl(vnnumitensbonific,0) + 1;
                  gvet_regitempedbrinde(vnnumitensbonific).numpedrca := p_regpedido.numpedrca;
                  gvet_regitempedbrinde(vnnumitensbonific).codprod   := reg_brindeex.codbrinde;
                  gvet_regitempedbrinde(vnnumitensbonific).qt        :=  reg_brindeex.qtde;
                  gvet_regitempedbrinde(vnnumitensbonific).codfilialretira   := vscodfilialretira;
                  gvet_regitempedbrinde(vnnumitensbonific).qtlimitebrinde    := null;
                  gvet_regitempedbrinde(vnnumitensbonific).numcampanha       := 10;
                  gvet_regitempedbrinde(vnnumitensbonific).codigocampanha    := reg_brindeex.codcamp;
                  gvet_regitempedbrinde(vnnumitensbonific).descricao         := reg_brindeex.descricao;
                  gvet_regitempedbrinde(vnnumitensbonific).usadebcredrcabrind := reg_brindeex.usadebcredrca;
                  gvet_regitempedbrinde(vnnumitensbonific).grpregrabrinde       := reg_brindeex.grpregrabrinde;
                  gvet_regitempedbrinde(vnnumitensbonific).qtunit               := vnqtunit;

                  if p_regfilial.utilizavendaporembalagem <> 'S' or vncodauxiliar is null then
                    begin
                      select codauxiliar
                        into gvet_regitempedbrinde(vnnumitensbonific).codauxiliar
                        from pcprodut
                       where codprod = reg_brindeex.codbrinde;
                    exception
                      when others then
                        gvet_regitempedbrinde(vnnumitensbonific) := null;
                    end;
                  else
                      gvet_regitempedbrinde(vnnumitensbonific).codauxiliar := vncodauxiliar;
                end if;
                else
                   select descricao
                     into vsdescricao
                     from pcprodut
                    where codprod = reg_brindeex.codbrinde;

                   if vsmensagem is null then

                       vsmensagem := 'Brinde sem estoque disponivel : '||reg_brindeex.codbrinde||' '||vsdescricao ;
                    else

                        vsmensagem := vsmensagem||CHR(13)||'Brinde sem estoque disponivel : '||reg_brindeex.codbrinde||' '||vsdescricao || CHR(13);
                end if;
                end if;

               --end if;

           end loop;
		   
		   CLOSE l_cursor_brindex;

         EXCEPTION
           WHEN OTHERS THEN
              IF SQLERRM LIKE '%04061%' AND vnreprocessarbrinde = 0 THEN
                 vnreprocessarbrinde := 1;
                 GOTO REPROCESSABRINDE;
              ELSE
                IF VSMENSAGEM IS NULL THEN

                   VSMENSAGEM := 'ERRO AO BUSCAR CAMPANHAS ATIVAS. '||SQLCODE||' '||SQLERRM;
                ELSE

                    VSMENSAGEM := VSMENSAGEM||CHR(13)||'ERRO AO BUSCAR CAMPANHAS ATIVAS. '||SQLCODE||' '||SQLERRM;
                END IF;
              END IF;

        END;

    -- fim tarefa 162743

    -- Gravar pedido bonificado
    if vnnumitensbonific > 0 then

      if nvl(gregpcconsum.gerarbrindepedbonific, 'N') = 'S' then

        vnnumseq := 0;
        vnvlsaldoped := 0;

        begin
          --2127.121737.2017
          vnproxnumped := 0;

          iTentativa := 0;
          while iTentativa < 50 or vnproxnumped = 0
          loop
            vnproxnumped := ferramentas.F_PROX_NUMPED(p_regpedido.codusur);
             if vnproxnumped > 0 then
               exit;
             end if;
            iTentativa := iTentativa+1;
          end loop;
        exception
          when others then

           if vsmensagem is null then

               vsmensagem := 'Erro ao buscar numero pedido bonificado.' || CHR(13);
            else

                vsmensagem := vsmensagem||CHR(13)||'Erro ao buscar numero pedido bonificado.' || CHR(13);
            end if;
        end;

        if (vnproxnumped <= 0) then  --VEN-6545
            RAISE erro_PROXNUMPEDZERADO;
        end if;

        if p_regpedido.posicao = 'B' then
          PKG_MOTIVOBLOQUEIO.INSERTMOTIVO(vnproxnumped,20,'Pedido TV1 bloqueado: ' || p_regpedido.numped,'C');
        end if;

        vsposicao := p_regpedido.posicao;

        if gregpcconsum.bloquearpedbonific = 'S' then

           vsposicao := 'B';
           PKG_MOTIVOBLOQUEIO.INSERTMOTIVO(vnproxnumped,20,'Parametro BLOQUEARPEDBONIFIC = ''S''','C');

        end if;

        select count(*)
          into vicont
          from pcplpag
         where pcplpag.tipoprazo = 'B';

        if vicont = 0 then
          vncodplpag  := p_regplpag.codplpag;
          vnnumpr     := p_regplpag.numpr;
          vnnumdias   := p_regplpag.numdias;
          vnprazo1    := p_regplpag.prazo1;
          vnprazo2    := p_regplpag.prazo2;
          vnprazo3    := p_regplpag.prazo3;
          vnprazo4    := p_regplpag.prazo4;
          vnprazo5    := p_regplpag.prazo5;
          vnprazo6    := p_regplpag.prazo6;
          vnprazo7    := p_regplpag.prazo7;
          vnprazo8    := p_regplpag.prazo8;
          vnprazo9    := p_regplpag.prazo9;
          vnprazo10   := p_regplpag.prazo10;
          vnprazo11   := p_regplpag.prazo11;
          vnprazo12   := p_regplpag.prazo12;
          vstipovenda := p_regplpag.tipovenda;
          vnpertxfim  := p_regplpag.pertxfim;
        else

          select codplpag,
                 numpr,
                 numdias,
                 prazo1,
                 prazo2,
                 prazo3,
                 prazo4,
                 prazo5,
                 prazo6,
                 prazo7,
                 prazo8,
                 prazo9,
                 prazo10,
                 prazo11,
                 prazo12,
                 tipovenda,
                 pertxfim
            into vncodplpag,
                 vnnumpr,
                 vnnumdias,
                 vnprazo1,
                 vnprazo2,
                 vnprazo3,
                 vnprazo4,
                 vnprazo5,
                 vnprazo6,
                 vnprazo7,
                 vnprazo8,
                 vnprazo9,
                 vnprazo10,
                 vnprazo11,
                 vnprazo12,
                 vstipovenda,
                 vnpertxfim
            from pcplpag
           where pcplpag.tipoprazo = 'B'
             and rownum = 1;
        end if;

        for i in 1 .. vnnumitensbonific loop

        vtITEM_PRECOS.ptabela  := null;
        vtITEM_PRECOS.pvenda   := null;
        vtITEM_PRECOS.pbaserca := null;

        if gvet_regitempedbrinde(i).numcampanha in (4,5) then

         select p.qtlimitebrinde
         into vnqtlimite
         from pcpromi p
         where p.codigo = gvet_regitempedbrinde(i).codigocampanha
         and   p.codprod = gvet_regitempedbrinde(i).codprod
         for update;

        elsif gvet_regitempedbrinde(i).numcampanha = 10 then

           null;

        else
         select p.qtlimitebrinde
         into vnqtlimite
         from pcpromc p
         where p.codigo = gvet_regitempedbrinde(i).codigocampanha
         for update;

        end if;

          vnnumseq := vnnumseq + 1;
          vbvalido := true;

              select pcprodut.codsec, pcprodut.codepto,nvl(pcprodut.percipivenda,0),nvl(pcprodut.percipivendatab,0), nvl(pcprodut.vlpautaipivenda,0),
                 nvl(pcprodut.vlpautaipivendatab,0),nvl(pcprodut.vlipiporkgvenda,0),nvl(pcprodut.vlipiporkgvendatab,0),nvl(pcprodut.pesobruto,0),
                 nvl(pcprodut.precomaxconsum,0),pcprodut.volume,pcprodut.codfornec,pcprodut.classe,pcprodut.importado,nvl(tipomerc,' '),nvl(pcprodut.qtunit,1),
                 pcprodut.codprodprinc
            into p_regproduto
            from pcprodut
           where pcprodut.codprod = gvet_regitempedbrinde(i).codprod;

          if p_regfilial.utilizavendaporembalagem = 'S' then
               p_regproduto.qtunit := gvet_regitempedbrinde(i).qtunit;
          END IF;

          vnvltotpesoped   := vnvltotpesoped +
                              (p_regproduto.pesobruto * gvet_regitempedbrinde(i).qt);
          vnvltotvolumeped := vnvltotvolumeped +
                              (p_regproduto.volume * gvet_regitempedbrinde(i).qt);


         proc_buscaprecoitem(gvet_regitempedbrinde(i),
                             p_regproduto.tipomerc,
                             p_regpedido,
                             p_regregiao,
                             p_regcliente,
                             p_regfilial,
                             p_regprecos,
                             vbvalido,
                             vsmensagemprecoitem);

           if vsmensagem is null then

               vsmensagem := vsmensagemprecoitem ;
            else

                vsmensagem := vsmensagem||CHR(13)||vsmensagemprecoitem || CHR(13);
            end if;

          -- Alterado para pegar pvenda do mesmo plano de pagamento
          -- do TV1
          -- 4371.062250.2017
          vnnumpr := p_regplpag.numpr;

          if vbvalido = true then

           if p_regproduto.tipomerc <> 'CB' then

            if vnnumpr = 1 then
              vnptabela := p_regprecos.pvenda1;
            elsif vnnumpr = 2 then
              vnptabela := p_regprecos.pvenda2;
            elsif vnnumpr = 3 then
              vnptabela := p_regprecos.pvenda3;
            elsif vnnumpr = 4 then
              vnptabela := p_regprecos.pvenda4;
            elsif vnnumpr = 5 then
              vnptabela := p_regprecos.pvenda5;
            elsif vnnumpr = 6 then
              vnptabela := p_regprecos.pvenda6;
            elsif vnnumpr = 7 then
              vnptabela := p_regprecos.pvenda7;
            end if;

           else

            proc_buscaprecocesta(vnproxnumped,
                                 gvet_regitempedbrinde(i).codprod,
                                 gvet_regitempedbrinde(i).qt,
                                 p_regpedido,
                                 p_regregiao,
                                 vnnumpr,
                                 p_regcliente,
                                 p_regfilial,
                                 vnptabela,
                                 vbvalido);

           end if;


         vnpbaserca := vnptabela;


          proc_validapoliticas(gvet_regitempedbrinde(i),
                               p_regpedido,
                               p_regfilial,
                               p_regcliente,
                               p_regrca,
                               p_regproduto.codprodprinc,
                               vncodplpag,
                               vnnumdias,
                               vnpertxfim,
                               vnptabela,
                               vnpbaserca,
                               vsmensagempolitica);

             if vsmensagempolitica is not null and vsmensagempolitica not in ('S','N') then

                if vsmensagem is null then

                   vsmensagem := vsmensagempolitica;
                 else

                    vsmensagem := vsmensagem||CHR(13)||vsmensagempolitica|| CHR(13);
                end if;


             end if;



            if vnptabela <= 0 then

               if vsmensagem is null then

                   vsmensagem := 'Item de brinde com preço inválido : ' ||
                                   gvet_regitempedbrinde(i).codprod ||' '||gvet_regitempedbrinde(i).descricao;
                else

                    vsmensagem := vsmensagem||CHR(13)||'Item de brinde com preço inválido : ' ||
                                   gvet_regitempedbrinde(i).codprod ||' '||gvet_regitempedbrinde(i).descricao|| CHR(13);
                end if;


             vbvalido := false;

          end if;


          if vbvalido = true then

            begin
              select pcfilial.uf
                into vsuffilialnf
                from pcfilial
               where pcfilial.codigo = p_Regpedido.codfilialnf;
            exception
              when others then
                vsuffilialnf := null;
            end;

            /** CALCULO IMPOSTOS **/
            /*

            vbcalculast_valido := funcoesvendas.calcularimpostos(vnptabela,
                                                                 vnptabela,
                                                                 vnpbaserca,
                                                                 vnvlipi,
                                                                 vnpercipi,
                                                                 nvl(p_regproduto.percipivenda,
                                                                     0),
                                                                 p_regpedido.percvenda,
                                                                 gregpcconsum.tipocalcst,
                                                                 gregpcconsum.calcstpf,
                                                                 p_regprecos.mostrarpvendasemst,
                                                                 gregpcconsum.consideraisentoscomopf,
                                                                 p_regcliente.calculast,
                                                                 p_regcliente.ieent,
                                                                 p_regcliente.tipofj,
                                                                 p_regprecos.pauta,
                                                                 p_regprecos.iva,
                                                                 p_regprecos.aliqicms1,
                                                                 p_regprecos.aliqicms2,
                                                                 p_regprecos.percbaseredst,
                                                                 gregpcconsum.numcasasdecvenda,
                                                                 0,
                                                                 p_regfilial.uf,
                                                                 p_regcliente.estent,
                                                                 nvl(p_regprecos.usavalorultentbasest,'N'),
                                                                 nvl(p_regprecos.usavalorultentbasest2,'N'),
                                                                 p_regprecos.valorultent,
                                                                 p_regcliente.isentoipi,
                                                                 p_regcliente.suframa,
                                                                 gregpcconsum.calcularstcomipi,
                                                                 gregpcconsum.tipocalcipi,
                                                                 nvl(p_regpedido.codfilialnf,nvl(p_regcliente.codfilialnf,p_regpedido.codfilial)),
                                                                 5,
                                                                 p_regcliente.contribuinte,
                                                                 vsuffilialnf,
                                                                 p_regproduto.importado,
                                                                 p_regfilial.calcularipivenda,
                                                                 p_regproduto.PERCIPIVENDATAB,
                                                                 p_regproduto.VLPAUTAIPIVENDA,
                                                                 p_regproduto.VLPAUTAIPIVENDATAB,
                                                                 p_regproduto.VLIPIPORKGVENDA,
                                                                 p_regproduto.VLIPIPORKGVENDATAB,
                                                                 p_regproduto.pesobruto,
                                                                 p_regprecos.tipocalculognre,
                                                                 'N',--p_regcliente.simplesnacional,
                                                                 0, --p_regprecos.percredpvendasimplesnac,
                                                                 'N',
                                                                 p_regcliente.utilizaiesimplificada,
                                                                 vsmensagem_st,
                                                                 vnst,
                                                                 vnbaseicst,
                                                                 gregpcconsum.aceitapfcontribuinte,
                                                                 p_regprecos.custonfsemst,
                                                                 p_regprecos.usapmcbasest,
                                                                 p_regproduto.precomaxconsum,
                                                                 p_regcliente.consumidorfinal,
                                                                 'N',
                                                                 'N',
                                                                 'N',
                                                                  'N',
                                                                 0, --60
                                                                  0,
                                                                  p_regprecos.usavlultentmediobasest);


                  if p_regprecos.tipocalculognre = 'C' then

                      --24 parâmetros
                      vbcalculast_valido := funcoesvendas.calcularst(vnptabela,
                                                                    0,
                                                                    p_regpedido.percvenda,
                                                                    gregpcconsum.tipocalcst,
                                                                    gregpcconsum.calcstpf,
                                                                    p_regprecos.mostrarpvendasemst,
                                                                    gregpcconsum.consideraisentoscomopf,
                                                                    p_regcliente.calculast,
                                                                    p_regcliente.ieent,
                                                                    p_regcliente.tipofj,
                                                                    p_regprecos.pauta,
                                                                    p_regprecos.iva,
                                                                    p_regprecos.aliqicms1,
                                                                    p_regprecos.aliqicms2,
                                                                    p_regprecos.percbaseredst,
                                                                    gregpcconsum.numcasasdecvenda,
                                                                    1,
                                                                    p_regfilial.uf,
                                                                    p_regcliente.estent,
                                                                    nvl(p_regprecos.usavalorultentbasest,'N'),
                                                                    nvl(p_regprecos.usavalorultentbasest2,'N'),
                                                                    p_regprecos.valorultent,
                                                                    p_regcliente.contribuinte,
                                                                    p_regcliente.utilizaiesimplificada,
                                                                    vsmensagem_st,
                                                                    vnst,
                                                                    vnbaseicst,
                                                                    gregpcconsum.aceitapfcontribuinte,
                                                                    p_regprecos.usapmcbasest,
                                                                    p_regproduto.precomaxconsum,
                                                                    p_regprecos.custonfsemst,
                                                                    p_regcliente.consumidorfinal);

                      vnstclientegnre := vnst;
                      vnst := 0;

                    end if;

                    if vsmensagem_st is not null then


                        if vsmensagem is null then

                           vsmensagem := vsmensagem_st;
                        else

                            vsmensagem := vsmensagem||CHR(13)||vsmensagem_st;
                        end if;
                    end if;


            vnstfonte := 0;

            vnstfonte := funcoesvendas.calcularstfonte(gvet_regitempedbrinde(i).codprod,
                                                       5,
                                                       p_regpedido.percvenda,
                                                       p_regprecos.iva,
                                                       p_regprecos.ivafonte,
                                                       p_regprecos.aliqicms1fonte,
                                                       p_regprecos.aliqicms2fonte,
                                                       p_regprecos.percbaseredstfonte,
                                                       p_regprecos.perbaserednrpa,
                                                       p_regprecos.percbaseredconsumidor,
                                                       p_regprecos.utilizapercbaseredpf,
                                                       gregpcconsum.tipocalcst,
                                                       NVL(gregPCCONSUM.CALCSTFONTEPF,
                                                       NVL(gregPCCONSUM.CALCSTPF,'S')),
                                                       gregpcconsum.utilizapercbaseredpf,
                                                       p_regcliente.clientefontest,
                                                       p_regcliente.calculast,
                                                       p_regcliente.ieent,
                                                       p_regcliente.tipofj,
                                                       p_regcliente.isentoicms,
                                                       p_regcliente.consumidorfinal,
                                                       p_regcliente.utilizaiesimplificada,
                                                       p_regcliente.tipoempresa,
                                                       gregpcconsum.consideraisentoscomopf,
                                                       (vnptabela - nvl(vnvlipi,0) - nvl(vnst,0)),
                                                       vnvlipi,
                                                       p_regfilial.uf,
                                                       p_regcliente.estent,
                                                       nvl(p_regprecos.usavalorultentbasest,'N'),
                                                       p_regprecos.valorultent,
                                                       p_regcliente.usaivafontediferenciado,
                                                       p_regcliente.ivafonte,
                                                       gregpcconsum.aceitapfcontribuinte,
                                                       p_Regprecos.aliqicms1,
                                                       p_regprecos.aliqicms2,
                                                       p_regcliente.contribuinte,
                                                       gregpcconsum.numcasasdecvenda,
                                                       vnbaseicst_fonte,
                                                       vsmensagem_stfonte,
                                                       p_regprecos.custonfsemst,
                                                       p_regprecos.usavalorultentbasest2,
                                                       p_regprecos.usapmcbasest,
                                                       p_regproduto.precomaxconsum);
            if vnbaseicst_fonte > 0 then
              vnbaseicst := vnbaseicst_fonte;
            end if;

            if (vnST = 0) and (vnSTFONTE <> 0) then
              vnst := vnSTFONTE;
              vnptabela := Round(vnptabela + vnSTFONTE,
                                 gregpcconsum.numcasasdecvenda);

              vnpbaserca := Round(vnpbaserca + vnSTFONTE,
                                 gregpcconsum.numcasasdecvenda);

              vnIVA := p_regprecos.ivafonte;
              vnPAUTA := 0;
              vnALIQICMS1 := p_regprecos.aliqicms1fonte;
              vnALIQICMS2 := p_regprecos.aliqicms2fonte;
              vnPERCBASEREDST := p_regprecos.percbaseredst;
              vnPERCBASEREDSTFONTE := p_regprecos.PERCBASEREDSTFONTE;

              p_regprecos.iva := vnIVA;
              p_regprecos.aliqicms1 := vnALIQICMS1;
              p_regprecos.aliqicms2 := vnALIQICMS2;

            end if;


            --Cálculo do %Desc. Suframa

            vnVlDescSuframa := 0;

            if trim(p_regCLIENTe.SUFRAMA) is not null then
              vnVlDescSuframa := ((vnptabela - nvl(vnst,0) - 0) *
                                 (p_regpedido.percvenda / 100)) *
                                 (nvl(p_regprecos.PERDESCSUFRAMA, 0) / 100);
              if gregpcconsum.TIPOCALCSULFRAMA = 'T2' then
                --Calcular ST - Truncar com 2 casas decimais
                vnVlDescSuframa := Trunc((vnVlDescSuframa) * 100) / 100;
              elsif gregPCCONSUM.TIPOCALCSULFRAMA = 'A2' then
                --Calcular ST - Arredondar com 2 casas decimais
                vnVlDescSuframa := Round((vnVlDescSuframa) * 100) / 100;
              elsif gregPCCONSUM.TIPOCALCSULFRAMA = 'PV' then
                --Calcular ST - Conf. Casas Dec. Venda
                vnVlDescSuframa := Round(vnVlDescSuframa,
                                         gregpcconsum.numcasasdecvenda);
              end if;
              vnptabela := Round(vnptabela - nvl(vnVLDESCSUFRAMA,0),
                                 gregpcconsum.numcasasdecvenda);

              vnpbaserca := Round(vnpbaserca - nvl(vnVLDESCSUFRAMA,0),
                                 gregpcconsum.numcasasdecvenda);

            end if;

            if p_regCLIENTe.tipodescisencao = 'C' then
              vnperdescisentoicms := p_regCLIENTe.perdescisentoicms;
            elsif p_regCLIENTe.tipodescisencao = 'T' then
              vnperdescisentoicms := p_regprecos.perdescicmisencao;
            else
              vnperdescisentoicms := 0;
            end if;


              --tarefa 152983
              if (p_regcliente.ORGAOPUB = 'S') or
                 (p_regcliente.ORGAOPUBFEDERAL = 'S') or trim(p_regcliente.suframa) is not null then

                 if p_regcliente.isencaosuframa = 'I' then

                     vnperdescisentoicms := 0;
                     vnvldescicmisencao := 0;

                 end if;

              end if;


              --tarefa 151307
              if vstipovenda = 'VP' then

                 if p_regprecos.usaisencaoicmsvp = 'N' then

                     vnperdescisentoicms := 0;
                     vnvldescicmisencao := 0;

                 end if;

              end if;


            if nvl(vnperdescisentoicms, 0) > 0 then
              vnVLDESCICMISENCAO := ((vnptabela - nvl(vnST,0) - 0) *
                                    (p_regpedido.PERCVENDA / 100)) *
                                    (vnperdescisentoicms / 100);
              vnptabela := Round(vnptabela - nvl(vnVLDESCICMISENCAO,0),
                                 gregpcconsum.numcasasdecvenda);
              vnpbaserca := Round(vnpbaserca - nvl(vnVLDESCICMISENCAO,0),
                                 gregpcconsum.numcasasdecvenda);

            end if;

            if ((p_regcliente.tipoempresa = 'R') or
                (p_regcliente.orgaopub = 'S') or
                (p_regcliente.USADESCONTOICMS = 'S') or
                (p_regcliente.orgaopubfederal = 'S') or
                (p_regcliente.suframa is not null)) then

                vbClienteAplicaReducoesTrib := true;
            else
               vbClienteAplicaReducoesTrib := false;
            end if;

            vsDEDUZIRPISCOFINSICMSDOCMV := p_regfiliaL.DEDUZIRPISCOFINSICMSDOCMV;

            IF ((NOT vbClienteAplicaReducoesTrib) OR
              ((vbClienteAplicaReducoesTrib) AND (vsDEDUZIRPISCOFINSICMSDOCMV = 'N')) ) THEN
              p_regprecos.codicmtab := p_regprecos.CODICMTABBONIF;

              IF FERRAMENTAS.VERIFICAR_FJ(p_regcliente.codcliprinc) = 'PESSOA FISICA' THEN
                p_regprecos.codicmtab := p_regprecos.codicmtabpfbonif;
              END IF;

            END IF;
            */

             vnvldisponivel := pc_pkg_controlarsaldorca.ccrca_checar_disponivel_atual(p_regpedido.codusur);



            if (vnvldisponivel - ( (gvet_regitempedbrinde(i).qt*vnptabela) + vnvlsaldoped) < 0  and 
               gvet_regitempedbrinde(i).usadebcredrcabrind = 'S')
                 and (PC_PKG_CONTROLARSALDORCA.CONTROLASALDORCA(FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USACREDRCA','99','N'),    
                                                        p_regpedido.usadebcredrca,           
                                                        p_regpedido.brinde,                  
                                                        p_regpedido.bonificaltdebcredrca,                                                        
                                                        p_regpedido.trocaaltdebcredrca,
                                                        p_regpedido.broker,                                                                      
                                                        p_regpedido.brokeraltdebcredrca,                                                         
                                                        p_regpedido.origemped,                                                                   
                                                        p_regpedido.crmaltdebcredrca,       
                                                        p_regcliente.usadebcredrca,    
                                                        p_regpedido.condvenda,               
                                                        gvet_regitempedbrinde(i).usadebcredrcabrind ) = 'S') then   
              vbvalido := false;

              if vsmensagem is null then

                 vsmensagem := 'Rca sem credito disponivel para liberar brinde. ' ||' '||gvet_regitempedbrinde(i).codprod||' '||gvet_regitempedbrinde(i).descricao ;
              else

                  vsmensagem := vsmensagem||CHR(13)||'Rca sem credito disponivel para liberar brinde. '||' '||gvet_regitempedbrinde(i).codprod||' '||gvet_regitempedbrinde(i).descricao ||CHR(13);
              end if;

            else

               vnvlsaldoped := vnvlsaldoped + nvl(vnptabela,0) ;


            select count(*)
              into vicontador
              from pcpedi
             where numped = vnproxnumped
               and codprod = gvet_regitempedbrinde(i).codprod;

            vnqtdispbrinde := 0;
            vnqtdispbrindecont := 0;

                begin
                  -- Verificar Estoque para evitar o Corte do Brinde
                  BEGIN
                    SELECT NVL(QT, 0)
                      INTO vnQtNoPedido
                      FROM PCPEDI
                     WHERE CODPROD = GVET_REGCAMPANHA(I).CODPROD
                       AND CODFILIALRETIRA = vscodfilialretira
                       AND NUMPED = P_NUMPED;
                  EXCEPTION
                    WHEN OTHERS THEN
                      vnQtNoPedido := 0;
                  END;

                  select greatest(nvl(qtestger, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        DECODE(vsBLOQUEIAVENDAESTPENDENTE, 'S', NVL(QTPENDENTE, 0), 0)-
                        greatest(nvl(qtbloqueada, 0), 0) -
                        greatest(vnQtNoPedido),
                        greatest(nvl(qtest, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        greatest(vnQtNoPedido)
                    into vnqtdispbrinde,vnqtdispbrindecont
                    from pcest
                   where pcest.codprod = gvet_regitempedbrinde(i).codprod
                     and pcest.codfilial = gvet_regitempedbrinde(i).codfilialretira;
                   --for update  ;

                exception
                  when others then
                    vnqtdispbrinde := 0;
                    vnqtdispbrindecont := 0;
                end;

             /*    vnqttotprod := 0;

                begin
                 SELECT sum(qt)
                 into vnqttotprod
                 FROM pcpedi
                 WHERE numped = vnproxnumped
                 AND codprod = gvet_regitempedbrinde(i).codprod
                 and numseq < nvl(vnnumseq,1)
                 and codfilialretira = gvet_regitempedbrinde(i).codfilialretira;
                 exception when others then
                 vnqttotprod := 0;
                end;


             vnqtdispbrinde     := greatest(vnqtdispbrinde,0) - nvl(vnqttotprod,0);
             vnqtdispbrindecont := greatest(vnqtdispbrindecont,0) - nvl(vnqttotprod,0); */


            if ( (vnqtdispbrinde >= gvet_regitempedbrinde(i).qt)  AND
                 ( (vnqtdispbrindecont >= gvet_regitempedbrinde(i).qt) and
                   (NVL(p_regfilial.verificaestoquecont,p_regfilial.con_verificaestoquecont) = 'S')) or
                   (NVL(p_regfilial.verificaestoquecont,p_regfilial.con_verificaestoquecont) = 'N') )
                OR
                (vsposicao in ('P','B')) then

             if gvet_regitempedbrinde(i).numcampanha <> 10 then

             begin
              select sum(qt)
              into vnqtbrindeutil
              from pcpedi p
              where p.codigobrinde = to_char(gvet_regitempedbrinde(i).codigocampanha)
              and   p.codprod     = gvet_regitempedbrinde(i).codprod
              and   p.posicao     <> 'C';
              exception when others then

                   if vsmensagem is null then

                       vsmensagem := 'Erro ao verificar qtd de brinde utilizada. ' ||' '||gvet_regitempedbrinde(i).codprod||' '||gvet_regitempedbrinde(i).descricao|| CHR(13)||
                                     SQLCODE||' ' ||SQLERRM ;
                    else

                        vsmensagem := vsmensagem||CHR(13)||'Erro ao verificar qtd de brinde utilizada. '||' '||gvet_regitempedbrinde(i).codprod||' '||gvet_regitempedbrinde(i).descricao|| CHR(13)||
                                      SQLCODE||' '||SQLERRM;
                    end if;



              end;

              select nvl(vnqtlimite,0) - nvl(vnqtbrindeutil,0)
              into vnqtsaldo
              from dual;

              if vnqtlimite > 0  then

              if vnqtsaldo <= 0  then
                 gvet_regitempedbrinde(i).qt := 0;


                   if vsmensagem is null then

                       vsmensagem := 'Brinde ultrapassou limite estipulado na campanha. ' ||' '||gvet_regitempedbrinde(i).codprod||' '||gvet_regitempedbrinde(i).descricao ;
                    else

                        vsmensagem := vsmensagem||CHR(13)||'Brinde ultrapassou limite estipulado na campanha' ||' '||gvet_regitempedbrinde(i).codprod||' '||gvet_regitempedbrinde(i).descricao|| CHR(13);
                    end if;



              else

                 if vnqtsaldo < gvet_regitempedbrinde(i).qt then

                    gvet_regitempedbrinde(i).qt := vnqtsaldo;

                   if vsmensagem is null then

                       vsmensagem := 'Brinde ultrapassou limite estipulado na campanha, tera quantidade reduzida. '||' '||gvet_regitempedbrinde(i).codprod||' '||gvet_regitempedbrinde(i).descricao;
                    else

                        vsmensagem := vsmensagem||CHR(13)||'Brinde ultrapassou limite estipulado na campanha, tera quantidade reduzida '||' '||gvet_regitempedbrinde(i).codprod||' '||gvet_regitempedbrinde(i).descricao|| CHR(13);
                    end if;

                 end if;
                end if;

              end if;

              end if;

           -- Integração Força de Venda
           vnqtbrindefv := func_buscar_qtde_fv(
                  p_regpedido.numpedrca,
                  p_regpedido.codusur,
                  p_cgccli,
                  p_regpedido.dtaberturapedpalm,
                  gvet_regitempedbrinde(i).codprod,
                  vbgerarbrindefv) ;
                  
           if not vbgerarbrindefv then
              gvet_regitempedbrinde(i).qt := 0;
              if vsmensagem is null then
                vsmensagem := 'Brinde zerado pelo Força de Venda. '||gvet_regitempedbrinde(i).codprod||' '||gvet_regitempedbrinde(i).descricao;
              else
                vsmensagem := vsmensagem||CHR(13)||'Brinde zerado pelo Força de Venda. '||gvet_regitempedbrinde(i).codprod||' '||gvet_regitempedbrinde(i).descricao;
              end if;
           end if;                  
              
           if gvet_regitempedbrinde(i).qt > 0 then
              
              if vnqtbrindefv > 0 and 
                vnqtbrindefv < gvet_regitempedbrinde(i).qt then
                gvet_regitempedbrinde(i).qt := vnqtbrindefv;
                if vsmensagem is null then
                  vsmensagem := 'Quantidade de Brindes alterada pelo Força de Venda. '||gvet_regitempedbrinde(i).codprod||' '||gvet_regitempedbrinde(i).descricao;
                else
                  vsmensagem := vsmensagem||CHR(13)||'Quantidade de Brindes alterada pelo Força de Venda. '||gvet_regitempedbrinde(i).codprod||' '||gvet_regitempedbrinde(i).descricao;
                end if;
              end if; 

              if vicontador = 0 then

                T_PCPEDC.CODCLI := p_regpedido.codcli;
                T_PCPEDC.CODFILIAL := P_REGPEDIDO.codfilial;
                T_PCPEDC.CODFILIALNF := P_REGPEDIDO.codfilialnf;
                T_PCPEDC.CONDVENDA := 5;
                T_PCPEDC.CODCOB := 'BNF';

                T_PCPEDI.PVENDA := vnptabela;
                T_PCPEDI.CODST  := p_regprecos.CODST;
                T_PCPEDI.CODPROD := gvet_regitempedbrinde(i).codprod;

                FERRAMENTAS.DEFINIRCODFISCAL(T_PCPEDC, T_PCPEDI, VNCODFISCAL, VNSITTRIBUT, vsmensagemcodfiscal);
                vsmensagem := vsmensagem || ' ' ||  vsmensagemcodfiscal;

                -- Preço de tabela
                vtITEM_PRECOS.pvenda   := round(vnptabela, gregpcconsum.numcasasdecvenda);
                vtITEM_PRECOS.ptabela  := round(vnptabela, gregpcconsum.numcasasdecvenda);
                vtITEM_PRECOS.pbaserca := round(vnptabela, gregpcconsum.numcasasdecvenda);

                -- ST de tabela
                vnst := p_regprecos.vlst;

                -- Tratamento para venda por embalagem
                if nvl(p_regfilial.utilizavendaporembalagem,'N') = 'N' or NVL(gvet_regitempedbrinde(i).qtunit,0) <= 0 then
                   gvet_regitempedbrinde(i).qtunit := 1;
                end if;

				SELECT VALOR_DESCONTO_SUFRAMA,
					   PERC_DESCONTO_ICMS,
					   VALOR_DESCONTO_ICMS
				  INTO VNVLDESCSUFRAMA,VNPERDESCISENTOICMS,              
					   VNVLDESCICMISENCAO
                FROM TABLE(PKG_TRIBUTACAO.CALCULAR_DESC_PIS_COFINS_ICMS(p_regpedido.codfilial,
                                                                        p_regpedido.codfilialnf,
                                                                        gvet_regitempedbrinde(i).codfilialretira,
                                                                        p_regpedido.codcli,
                                                                        gvet_regitempedbrinde(i).codprod,
                                                                        vtITEM_PRECOS.ptabela,
                                                                        0,
                                                                        0));
																		
				vtITEM_PRECOS.ptabela := vtITEM_PRECOS.ptabela - VNVLDESCSUFRAMA - VNVLDESCICMISENCAO;	

				SELECT VALOR_DESCONTO_SUFRAMA,
					   PERC_DESCONTO_ICMS,
					   VALOR_DESCONTO_ICMS
				  INTO VNVLDESCSUFRAMA,VNPERDESCISENTOICMS,              
					   VNVLDESCICMISENCAO
                FROM TABLE(PKG_TRIBUTACAO.CALCULAR_DESC_PIS_COFINS_ICMS(p_regpedido.codfilial,
                                                                        p_regpedido.codfilialnf,
                                                                        gvet_regitempedbrinde(i).codfilialretira,
                                                                        p_regpedido.codcli,
                                                                        gvet_regitempedbrinde(i).codprod,
                                                                        vtITEM_PRECOS.pbaserca,
                                                                        0,
                                                                        0));
																		
				vtITEM_PRECOS.pbaserca  := vtITEM_PRECOS.pbaserca - VNVLDESCSUFRAMA - VNVLDESCICMISENCAO;
				
				SELECT VALOR_DESCONTO_SUFRAMA,
					   PERC_DESCONTO_ICMS,
					   VALOR_DESCONTO_ICMS
				  INTO VNVLDESCSUFRAMA,VNPERDESCISENTOICMS,              
					   VNVLDESCICMISENCAO
                FROM TABLE(PKG_TRIBUTACAO.CALCULAR_DESC_PIS_COFINS_ICMS(p_regpedido.codfilial,
                                                                        p_regpedido.codfilialnf,
                                                                        gvet_regitempedbrinde(i).codfilialretira,
                                                                        p_regpedido.codcli,
                                                                        gvet_regitempedbrinde(i).codprod,
                                                                        vtITEM_PRECOS.pvenda,
                                                                        0,
                                                                        0));			
				vtITEM_PRECOS.pvenda := vtITEM_PRECOS.pvenda  - VNVLDESCSUFRAMA - VNVLDESCICMISENCAO;	
				
                -- Calcula Preço sem Imposto
                SELECT round(VALORSEMIMPOSTO * gvet_regitempedbrinde(i).qtunit,gregpcconsum.numcasasdecvenda), MSG
                  INTO vtITEM_PRECOS.ptabela_semimpostos, vsMSGPartilha
                FROM TABLE(PKG_TRIBUTACAO.CALCULAR_PVENDA_SEM_IMPOSTO(p_regpedido.codfilial,
                                                                      p_regpedido.codfilialnf,
                                                                      gvet_Regitempedbrinde(i).codfilialretira,
                                                                      p_regpedido.codcli,
                                                                      p_regpedido.codplpag,
                                                                      gvet_regitempedbrinde(i).codprod,
                                                                      gvet_regitempedbrinde(i).codauxiliar,
                                                                      p_regpedido.condvenda,
                                                                      'N',
                                                                      vnst, --1,
                                                                      0,
                                                                      ROUND(vtITEM_PRECOS.ptabela, gregpcconsum.numcasasdecvenda),
                                                                      'S',
                                                                      'S',
                                                                      'N',
                                                                      '',--0,
                                                                      NULL,
                                                                      'N',
                                                                      'N',
                                                                      'N',
                                                                      'N',
                                                                      0,
                                                                      'N',
                                                                      'I'));

                -- Calcula ICMS Partilha
                pkg_fwpc_fiscal.icmspartilha_calcular_1_4(nvl(p_regpedido.codfilialnf,p_regpedido.codfilial),
                                                         p_regpedido.codcli,
                                                         '',
                                                         vsufEnt,
                                                         p_regpedido.data,
                                                         vtITEM_PRECOS.ptabela_semimpostos,
                                                         p_regprecos.codst,
                                                         gvet_regitempedbrinde(i).codprod,
                                                         VNCODFISCAL,--CFOP
                                                         VNSITTRIBUT,--CST
                                                         tICMSPARTILHA,
                                                         vnCodMSGPartilha,
                                                         vsMSGPartilha);

               -- Agrega o ICMS Partilha no preço
               vtITEM_PRECOS.ptabela_semimpostos := vtITEM_PRECOS.ptabela_semimpostos + nvl(tICMSPARTILHA.VLICMSPART,0);

               -- Calcula o valor de IPI
               SELECT VALORIPI, PERCENTUAL_IPI
                       INTO vtITEM_PRECOS.vlipi_ptabela, vtITEM_PRECOS.percipi
                 FROM TABLE(PKG_TRIBUTACAO.CALCULAR_IPI(p_regpedido.codfilial,
                                                        p_regpedido.codfilialnf,
                                                        gvet_regitempedbrinde(i).codfilialretira,
                                                        p_regpedido.codcli,
                                                        gvet_regitempedbrinde(i).codprod,
                                                        gvet_regitempedbrinde(i).codauxiliar,
                                                        p_regpedido.condvenda,
                                                        'N',
                                                        vtITEM_PRECOS.ptabela_semimpostos,
                                                        'N',
                                                        null,
                                                        'N',--transferencia
                                                        'N',--transferenciaVirtual
                                                        'N',
                                                        'F',
                                                        null,
                                                        'I'));


                -- Calcula ST e FECP
                SELECT BASEST,
                       ST,
                       VLRFECP,
                       BASEFECP,
                       ALIQFECP,
                       PAUTA,
                       IVA,
                       ALIQICMS1,
                       ALIQICMS2
                  INTO vtITEM_PRECOS.basest_ptabela,
                       vtITEM_PRECOS.vlst_ptabela,
                       vtITEM_PRECOS.VLFECP,
                       vtITEM_PRECOS.BaseFECP,
                       vtITEM_PRECOS.ALIQFECP,
                       vtITEM_PRECOS.pauta,
                       p_regprecos.iva,
                       p_regprecos.aliqicms1,
                       p_regprecos.aliqicms2
                FROM TABLE(PKG_TRIBUTACAO.CALCULAR_ST(p_regpedido.codfilial,
                                                      p_regpedido.codfilialnf,
                                                      gvet_regitempedbrinde(i).codfilialretira,
                                                      p_regpedido.codcli,
                                                      p_regpedido.codplpag,
                                                      gvet_regitempedbrinde(i).codprod,
                                                      gvet_regitempedbrinde(i).codauxiliar,
                                                      p_regpedido.condvenda,
                                                      'N',
                                                      vtITEM_PRECOS.ptabela_semimpostos,
                                                      0));

                -- Calcula o preço final
                IF p_regprecos.tipocalculognre <> 'C' THEN
                   vnptabela := vtITEM_PRECOS.ptabela_semimpostos + vtITEM_PRECOS.vlipi_ptabela + vtITEM_PRECOS.vlst_ptabela + vtITEM_PRECOS.VLFECP;
                   -- Tratamento para venda por embalagem
                   if nvl(p_regfilial.utilizavendaporembalagem,'N') = 'S' then
                      vnptabela := ROUND(vnptabela/gvet_regitempedbrinde(i).qtunit, gregpcconsum.numcasasdecvenda);
                      vtITEM_PRECOS.ptabela_semimpostos := ROUND(vtITEM_PRECOS.ptabela_semimpostos/gvet_regitempedbrinde(i).qtunit, gregpcconsum.numcasasdecvenda);
                      vtITEM_PRECOS.vlipi_ptabela := ROUND(vtITEM_PRECOS.vlipi_ptabela/gvet_regitempedbrinde(i).qtunit, gregpcconsum.numcasasdecvenda);
                      tICMSPARTILHA.VLICMSPART := ROUND(tICMSPARTILHA.VLICMSPART/gvet_regitempedbrinde(i).qtunit, gregpcconsum.numcasasdecvenda);
                      vtITEM_PRECOS.basest_ptabela := ROUND(vtITEM_PRECOS.basest_ptabela/gvet_regitempedbrinde(i).qtunit, gregpcconsum.numcasasdecvenda);
                      vtITEM_PRECOS.vlst_ptabela := ROUND(vtITEM_PRECOS.vlst_ptabela/gvet_regitempedbrinde(i).qtunit, gregpcconsum.numcasasdecvenda);
                      vtITEM_PRECOS.VLFECP := ROUND(vtITEM_PRECOS.VLFECP/gvet_regitempedbrinde(i).qtunit, gregpcconsum.numcasasdecvenda);
                      vtITEM_PRECOS.BaseFECP := ROUND(vtITEM_PRECOS.BaseFECP/gvet_regitempedbrinde(i).qtunit, gregpcconsum.numcasasdecvenda);
                      vtITEM_PRECOS.pauta := ROUND(vtITEM_PRECOS.pauta/gvet_regitempedbrinde(i).qtunit, gregpcconsum.numcasasdecvenda);
                   end if;
                   vnst := vtITEM_PRECOS.vlst_ptabela;
                ELSE
                   vnptabela := vtITEM_PRECOS.ptabela_semimpostos + vtITEM_PRECOS.vlipi_ptabela;
                   -- Tratamento para venda por embalagem
                   if nvl(p_regfilial.utilizavendaporembalagem,'N') = 'S' then
                      vnptabela := ROUND(vnptabela/gvet_regitempedbrinde(i).qtunit, gregpcconsum.numcasasdecvenda);
                      vtITEM_PRECOS.ptabela_semimpostos := ROUND(vtITEM_PRECOS.ptabela_semimpostos/gvet_regitempedbrinde(i).qtunit, gregpcconsum.numcasasdecvenda);
                      vtITEM_PRECOS.vlipi_ptabela := ROUND(vtITEM_PRECOS.vlipi_ptabela/gvet_regitempedbrinde(i).qtunit, gregpcconsum.numcasasdecvenda);
                      tICMSPARTILHA.VLICMSPART := ROUND(tICMSPARTILHA.VLICMSPART/gvet_regitempedbrinde(i).qtunit, gregpcconsum.numcasasdecvenda);
                      vtITEM_PRECOS.basest_ptabela := ROUND(vtITEM_PRECOS.basest_ptabela/gvet_regitempedbrinde(i).qtunit, gregpcconsum.numcasasdecvenda);
                      vtITEM_PRECOS.vlst_ptabela := ROUND(vtITEM_PRECOS.vlst_ptabela/gvet_regitempedbrinde(i).qtunit, gregpcconsum.numcasasdecvenda);
                      vtITEM_PRECOS.VLFECP := ROUND(vtITEM_PRECOS.VLFECP/gvet_regitempedbrinde(i).qtunit, gregpcconsum.numcasasdecvenda);
                      vtITEM_PRECOS.BaseFECP := ROUND(vtITEM_PRECOS.BaseFECP/gvet_regitempedbrinde(i).qtunit, gregpcconsum.numcasasdecvenda);
                      vtITEM_PRECOS.pauta := ROUND(vtITEM_PRECOS.pauta/gvet_regitempedbrinde(i).qtunit, gregpcconsum.numcasasdecvenda);
                   end if;
                   vnst := 0;
                END IF;

                -- buscar custos do item
                vnvlcustocont   := p_regprecos.custocont;
                vnvlcustorep    := p_regprecos.custorep;
                vnvlcustofinest := p_regprecos.custofin;
                vnvlcustofin  := (p_regprecos.custofin -
                                 (p_regprecos.custofin *
                                 p_regprecos.perdesccusto / 100) +
                                 (vnptabela * nvl(gregpcconsum.txvenda, 0) / 100)
                                 --              + (p_regitem.pvenda * p_regitem.percom / 100)
                                 + ((vtITEM_PRECOS.ptabela_semimpostos - nvl(tICMSPARTILHA.VLICMSPART,0)) * p_regprecos.codicmtab / 100) + vtITEM_PRECOS.vlipi_ptabela + vtITEM_PRECOS.vlst_ptabela + vtITEM_PRECOS.VLFECP + nvl(tICMSPARTILHA.VLICMSPART,0));
                vnvlcustoreal := (p_regprecos.custoreal -
                                 (p_regprecos.custoreal *
                                 p_regprecos.perdesccusto / 100) +
                                 (vnptabela * nvl(gregpcconsum.txvenda, 0) / 100)
                                 --              + (p_regitem.pvenda * p_regitem.percom / 100)
                                 + ((vtITEM_PRECOS.ptabela_semimpostos - nvl(tICMSPARTILHA.VLICMSPART,0)) * p_regprecos.codicmtab / 100) + vtITEM_PRECOS.vlipi_ptabela + vtITEM_PRECOS.vlst_ptabela + vtITEM_PRECOS.VLFECP + nvl(tICMSPARTILHA.VLICMSPART,0));
								 
                                                              
																		
                /** INSERT PCPEDI **/
                insert into pcpedi
                  (codcli,     --1
                   codicmtab,  --2
                   codprod,    --3
                   codst,      --4
                   codusur,    --5
                   data,       --6
                   numped,     --7
                   numseq,     --8
                   percom,     --9
                   perdesc,    --10
                   posicao,    --11
                   ptabela,    --12
                   pvenda,     --13
                   qt,         --14
                   qtfalta,    --15
                   st,         --16
                   vlcustocont,  --17
                   vlcustofin,   --18
                   vlcustoreal,  --19
                   vlcustorep,   --20
                   baseicst,     --21
                   vlipi,        --22
                   percipi,      --23
                   vldescsuframa,  --24
                   perdescisentoicms, --25
                   vldescicmisencao,   --26
                   brinde  ,           --27
                   pbaserca,            --28
                   codfilialretira,      --29
                   codigobrinde,           --30
                   rotinalanc,             --31
                   usadebcredrcabrind,     --32
                   qtunitemb,               --33
                   grpregrabrinde,             --34
                   bonific,                    --35
                   stclientegnre,               --36
                   numcar,                     --37
                   codpromocao,                --38
                   codauxiliar,                --39
                   pbonific,                    --40
                   vlbonific,
                   iva,
                   aliqicms1,
                   aliqicms2,
                   stptabela,
                   vlipiptabela,
                   vlbasepartdest,    --45
                   aliqfcp,           --46
                   aliqinternadest,   --47
                   vlfcppart,         --48
                   vlicmspartdest,    --49
                   vlicmspart,        --50
                   VLICMSDIFALIQPART, --51
                   PERCBASEREDPART,   --52
                   PERCPROVPART,       --53
                   VLICMSPARTREM,     --54
                   ALIQINTERORIGPART, --55
                   custofinest,        --56
                   geragnre_cnpjcliente, --57
                   vlfecp,               --58
                   aliqicmsfecp,         --59
                   vlbasefcpst,           --60
                   pauta                  --61
                   )
                values
                  (p_regpedido.codcli,          --1
                   p_regprecos.codicmtab,       --2
                   gvet_regitempedbrinde(i).codprod, --3
                   p_regprecos.codst,              --4
                   p_regpedido.codusur,            --5
                   trunc(sysdate),                 --6
                   vnproxnumped,                    --7
                   vnnumseq,                        --8
                   0,                               --9
                   0,                               --10
                   vsposicao,                        --11
                   vnptabela,                       --12
                   vnptabela,                       --13
                   gvet_regitempedbrinde(i).qt,     --14
                   0,                               --15
                   vtITEM_PRECOS.vlst_ptabela,      --16
                   vnvlcustocont,                    --17
                   vnvlcustofin,                     --18
                   vnvlcustoreal,                    --19
                   vnvlcustorep,                     --20
                   vtITEM_PRECOS.basest_ptabela,     --21
                   vtITEM_PRECOS.vlipi_ptabela,       --22
                   vtITEM_PRECOS.percipi,             --23
                   vnVlDescSuframa,                   --24
                   vnperdescisentoicms,               --25
                   vnvldescicmisencao,                --26
                   'S' ,                               --27
                   vnptabela,                          --28
                   gvet_Regitempedbrinde(i).codfilialretira, --29
                   gvet_regitempedbrinde(i).codigocampanha,   --30
                   '2596',                                     --31
                   gvet_regitempedbrinde(i).usadebcredrcabrind,  --32
                   gvet_regitempedbrinde(i).qtunit,                              --33
                   gvet_regitempedbrinde(i).grpregrabrinde,  --34
                   case nvl(gregpcconsum.gerarbrindepedbonific, 'N')
                    when 'N' then 'F'
                    else null
                   end,                                  --35
                   vnstclientegnre ,                          --36
                   p_regpedido.numcar,                                         --37
                   gvet_regitempedbrinde(i).codigocampanha,   --38
                   gvet_regitempedbrinde(i).codauxiliar,      --39
                   vnptabela,                                  --40
                   vnptabela,                                  --40
                   p_regprecos.iva,
                   p_regprecos.aliqicms1,
                   p_regprecos.aliqicms2,
                   vnst,
                   vnvlipi,
                   tICMSPARTILHA.vlbasepartdest,    --45
                   tICMSPARTILHA.aliqfcp,           --46
                   tICMSPARTILHA.aliqinternadest,   --47
                   tICMSPARTILHA.vlfcppart,         --48
                   tICMSPARTILHA.vlicmspartdest,    --49
                   tICMSPARTILHA.vlicmspart,        --50
                   tICMSPARTILHA.VLICMSDIFALIQ, --51
                   tICMSPARTILHA.PERCBASERED,   --52
                   tICMSPARTILHA.percprovpart,       --53
                   tICMSPARTILHA.vlicmspartrem,     --54
                   tICMSPARTILHA.ALIQINTERESTADUAL, --55
                   vnvlcustofinest,                  --56
                   case when p_regprecos.tipocalculognre = 'P' and p_regprecos.pagtonomedocliente = 'S' then
                        'S'
                   else
                       'N'
                   end, --57
                   vtITEM_PRECOS.VLFECP, --58
                   vtITEM_PRECOS.ALIQFECP, --59
                   vtITEM_PRECOS.BaseFECP, --60
                   vtITEM_PRECOS.pauta --61
                   );

                 gvet_regitempedbrinde(i).numseq :=  vnnumseq;

                 if p_regproduto.tipomerc = 'CB' then

                    vbvalidocesta := func_inseriritemcesta( vnproxnumped,
                                                            gvet_regitempedbrinde(i).codprod,
                                                            p_regpedido,
                                                            p_regrca,
                                                            p_regcliente,
                                                            p_regregiao,
                                                            p_regfilial,
                                                            vncodplpag,
                                                            vstipovenda,
                                                           vnnumseq );

                    select sum(p.qtmp*vlcustofin),sum(p.qtmp*vlcustoreal),sum(p.qtmp*vlcustorep),sum(p.qtmp*custofinest),sum(p.qtmp*vlcustocont)
                    into vnvlcustofin,vnvlcustoreal,vnvlcustorep,vncustofinest,vnvlcustocont
                    from pcpedicesta p
                    where numped = vnproxnumped
                    and   codprod =  gvet_regitempedbrinde(i).codprod
                    and   numseq  = vnnumseq;

                    update pcpedi
                    set vlcustofin = vnvlcustofin,
                        vlcustoreal = vnvlcustoreal,
                        vlcustorep = vnvlcustorep,
                        vlcustocont = vnvlcustocont,
                        custofinest  = vncustofinest
                    where numped = vnproxnumped
                    and   codprod =  gvet_regitempedbrinde(i).codprod
                    and   numseq  = vnnumseq;



                 end if;

               gvet_regitempedbrinde(i).numseq := vnnumseq;



                   if vsmensagem is null then

                       vsmensagem := 'BRINDE : '|| gvet_regitempedbrinde(i).codprod||'-'||gvet_regitempedbrinde(i).descricao ||CHR(13)||
                                      'QT : '||gvet_regitempedbrinde(i).qt ;
                    else

                        vsmensagem := vsmensagem||CHR(13)||'BRINDE : '|| gvet_regitempedbrinde(i).codprod||'-'||gvet_regitempedbrinde(i).descricao ||CHR(13)||
                                      'QT : '||gvet_regitempedbrinde(i).qt ||CHR(13);
                    end if;

                   p_geroubrinde := 'S';



                      if p_integradora = 'S' then --só insere se o pedido está sendo feito pela integradora

                        --inserir na tabela de retorno de itens de brinde


                        insert into PCRETORNOITV5FV
                          (numpedrca,         --1
                           dtaberturapedpalm, --2
                           codusur,           --3
                           cgccli,            --4
                           codcli,            --5
                           codprod,           --6
                           codauxiliar,       --7
                           qt,                --8
                           qt_faturada,       --9
                           ptabela,           --10
                           numseq,            --11
                           codfilialretira,   --12
                           numpedtv5,         --13
                           numpedorigem       --14
                           )
                         values
                          (p_regpedido.numpedrca,         --1
                           p_regpedido.dtaberturapedpalm, --2
                           p_regpedido.codusur,           --3
                           p_cgccli,                      --4
                           p_regpedido.codcli,            --5
                           gvet_regitempedbrinde(i).codprod,           --6
                           null,                           --7
                           gvet_regitempedbrinde(i).qt,     --8
                           gvet_regitempedbrinde(i).qt,    --9
                           vnptabela,           --10
                           vnnumseq,            --11
                           gvet_regitempedbrinde(i).codfilialretira,   --12
                           vnproxnumped,                               --13
                           p_regpedido.numped                          --14
                           );


                         end if;



              else


                select count(*)
                into vicontador
                from pcpedi
               where numped = vnproxnumped
                 and codprod = gvet_regitempedbrinde(i).codprod
                 and codigobrinde = to_char(gvet_regitempedbrinde(i).codigocampanha);

                 if vicontador = 0 then -- o item que já existe no pedido com mesmo codprod pertence a outra campanha

                   T_PCPEDC.CODCLI := p_regpedido.codcli;
                   T_PCPEDC.CODFILIAL := P_REGPEDIDO.codfilial;
                   T_PCPEDC.CODFILIALNF := P_REGPEDIDO.codfilialnf;
                   T_PCPEDC.CONDVENDA := 5;
                   T_PCPEDC.CODCOB := 'BNF';


                   T_PCPEDI.PVENDA := vnptabela;
                   T_PCPEDI.CODST  := p_regprecos.CODST;
                   T_PCPEDI.CODPROD := gvet_regitempedbrinde(i).codprod;

                   FERRAMENTAS.DEFINIRCODFISCAL(T_PCPEDC, T_PCPEDI, VNCODFISCAL, VNSITTRIBUT, vsmensagemcodfiscal);
                   vsmensagem := vsmensagem || ' ' ||  vsmensagemcodfiscal;

                   -- Preço de tabela
                vtITEM_PRECOS.pvenda   := round(vnptabela, gregpcconsum.numcasasdecvenda);
                vtITEM_PRECOS.ptabela  := round(vnptabela, gregpcconsum.numcasasdecvenda);
                vtITEM_PRECOS.pbaserca := round(vnptabela, gregpcconsum.numcasasdecvenda);

                -- ST de tabela
                vnst := p_regprecos.vlst;

                -- Calcula Preço sem Imposto
                SELECT round(VALORSEMIMPOSTO,gregpcconsum.numcasasdecvenda), MSG
                  INTO vtITEM_PRECOS.ptabela_semimpostos, vsMSGPartilha
                FROM TABLE(PKG_TRIBUTACAO.CALCULAR_PVENDA_SEM_IMPOSTO(p_regpedido.codfilial,
                                                                      p_regpedido.codfilialnf,
                                                                      gvet_Regitempedbrinde(i).codfilialretira,
                                                                      p_regpedido.codcli,
                                                                      p_regpedido.codplpag,
                                                                      gvet_regitempedbrinde(i).codprod,
                                                                      gvet_regitempedbrinde(i).codauxiliar,
                                                                      p_regpedido.condvenda,
                                                                      'N',
                                                                      vnst, --1,
                                                                      0,
                                                                      ROUND(vtITEM_PRECOS.ptabela, gregpcconsum.numcasasdecvenda),
                                                                      'S',
                                                                      'S',
                                                                      'N',
                                                                      '',--0,
                                                                      NULL,
                                                                      'N',
                                                                      'N',
                                                                      'N',
                                                                      'N',
                                                                      0,
                                                                      'N',
                                                                      'I'));

                -- Calcula ICMS Partilha
                pkg_fwpc_fiscal.icmspartilha_calcular_1_4(nvl(p_regpedido.codfilialnf,p_regpedido.codfilial),
                                                         p_regpedido.codcli,
                                                         '',
                                                         vsufEnt,
                                                           trunc(sysdate),
                                                         vtITEM_PRECOS.ptabela_semimpostos,
                                                         p_regprecos.codst,
                                                         gvet_regitempedbrinde(i).codprod,
                                                         VNCODFISCAL,--CFOP
                                                         VNSITTRIBUT,--CST
                                                         tICMSPARTILHA,
                                                         vnCodMSGPartilha,
                                                         vsMSGPartilha);

               -- Agrega o ICMS Partilha no preço
               vtITEM_PRECOS.ptabela_semimpostos := vtITEM_PRECOS.ptabela_semimpostos + nvl(tICMSPARTILHA.VLICMSPART,0);

               -- Calcula o valor de IPI
               SELECT VALORIPI, PERCENTUAL_IPI
                       INTO vtITEM_PRECOS.vlipi_ptabela, vtITEM_PRECOS.percipi
                 FROM TABLE(PKG_TRIBUTACAO.CALCULAR_IPI(p_regpedido.codfilial,
                                                        p_regpedido.codfilialnf,
                                                        gvet_regitempedbrinde(i).codfilialretira,
                                                        p_regpedido.codcli,
                                                        gvet_regitempedbrinde(i).codprod,
                                                        gvet_regitempedbrinde(i).codauxiliar,
                                                        p_regpedido.condvenda,
                                                        'N',
                                                        vtITEM_PRECOS.ptabela_semimpostos,
                                                        'N',
                                                        null,
                                                        'N',--transferencia
                                                        'N',--transferenciaVirtual
                                                        'N',
                                                        'F',
                                                        null,
                                                        'I'));


                -- Calcula ST e FECP
                SELECT BASEST,
                       ST,
                       VLRFECP,
                       BASEFECP,
                       ALIQFECP,
                       PAUTA,
                       IVA,
                       ALIQICMS1,
                       ALIQICMS2
                  INTO vtITEM_PRECOS.basest_ptabela,
                       vtITEM_PRECOS.vlst_ptabela,
                       vtITEM_PRECOS.VLFECP,
                       vtITEM_PRECOS.BaseFECP,
                       vtITEM_PRECOS.ALIQFECP,
                       vtITEM_PRECOS.pauta,
                       p_regprecos.iva,
                       p_regprecos.aliqicms1,
                       p_regprecos.aliqicms2
                FROM TABLE(PKG_TRIBUTACAO.CALCULAR_ST(p_regpedido.codfilial,
                                                      p_regpedido.codfilialnf,
                                                      gvet_regitempedbrinde(i).codfilialretira,
                                                      p_regpedido.codcli,
                                                      p_regpedido.codplpag,
                                                      gvet_regitempedbrinde(i).codprod,
                                                      gvet_regitempedbrinde(i).codauxiliar,
                                                      p_regpedido.condvenda,
                                                      'N',
                                                      vtITEM_PRECOS.ptabela_semimpostos,
                                                      0));

                -- Calcula o preço final
                IF p_regprecos.tipocalculognre <> 'C' THEN
                   vnptabela := vtITEM_PRECOS.ptabela_semimpostos + vtITEM_PRECOS.vlipi_ptabela + vtITEM_PRECOS.vlst_ptabela + vtITEM_PRECOS.VLFECP;
                   vnst := vtITEM_PRECOS.vlst_ptabela;
                ELSE
                   vnptabela := vtITEM_PRECOS.ptabela_semimpostos + vtITEM_PRECOS.vlipi_ptabela;
                   vnst := 0;
                END IF;

                -- buscar custos do item
                vnvlcustocont   := p_regprecos.custocont;
                vnvlcustorep    := p_regprecos.custorep;
                vnvlcustofinest := p_regprecos.custofin;
                vnvlcustofin  := (p_regprecos.custofin -
                                 (p_regprecos.custofin *
                                 p_regprecos.perdesccusto / 100) +
                                 (vnptabela * nvl(gregpcconsum.txvenda, 0) / 100)
                                 --              + (p_regitem.pvenda * p_regitem.percom / 100)
                                 + ((vtITEM_PRECOS.ptabela_semimpostos - nvl(tICMSPARTILHA.VLICMSPART,0)) * p_regprecos.codicmtab / 100) + vtITEM_PRECOS.vlipi_ptabela + vtITEM_PRECOS.vlst_ptabela + vtITEM_PRECOS.VLFECP + nvl(tICMSPARTILHA.VLICMSPART,0));
                vnvlcustoreal := (p_regprecos.custoreal -
                                 (p_regprecos.custoreal *
                                 p_regprecos.perdesccusto / 100) +
                                 (vnptabela * nvl(gregpcconsum.txvenda, 0) / 100)
                                 --              + (p_regitem.pvenda * p_regitem.percom / 100)
                                 + ((vtITEM_PRECOS.ptabela_semimpostos - nvl(tICMSPARTILHA.VLICMSPART,0)) * p_regprecos.codicmtab / 100) + vtITEM_PRECOS.vlipi_ptabela + vtITEM_PRECOS.vlst_ptabela + vtITEM_PRECOS.VLFECP + nvl(tICMSPARTILHA.VLICMSPART,0));


                 insert into pcpedi
                  (codcli,     --1
                   codicmtab,  --2
                   codprod,    --3
                   codst,      --4
                   codusur,    --5
                   data,       --6
                   numped,     --7
                   numseq,     --8
                   percom,     --9
                   perdesc,    --10
                   posicao,    --11
                   ptabela,    --12
                   pvenda,     --13
                   qt,         --14
                   qtfalta,    --15
                   st,         --16
                   vlcustocont,  --17
                   vlcustofin,   --18
                   vlcustoreal,  --19
                   vlcustorep,   --20
                   baseicst,     --21
                   vlipi,        --22
                   percipi,      --23
                   vldescsuframa,  --24
                   perdescisentoicms, --25
                   vldescicmisencao,   --26
                   brinde  ,           --27
                   pbaserca,            --28
                   codfilialretira,      --29
                   codigobrinde,           --30
                   rotinalanc,             --31
                   usadebcredrcabrind,     --32
                   qtunitemb,               --33
                   grpregrabrinde,             --34
                   bonific,                    --35
                   stclientegnre,               --36
                   numcar,                     --37
                   codpromocao,                --38
                   codauxiliar,                --39
                   pbonific,                    --40
                   vlbonific,
                   iva,
                   aliqicms1,
                   aliqicms2,
                   stptabela,
                   vlipiptabela,
                   vlbasepartdest,    --45
                   aliqfcp,           --46
                   aliqinternadest,   --47
                   vlfcppart,         --48
                   vlicmspartdest,    --49
                   vlicmspart,        --50
                   VLICMSDIFALIQPART, --51
                   PERCBASEREDPART,   --52
                   PERCPROVPART,       --53
                   VLICMSPARTREM,     --54
                   ALIQINTERORIGPART, --55
                   custofinest,        --56
                   geragnre_cnpjcliente, --57
                   vlfecp,               --58
                   aliqicmsfecp,         --59
                   vlbasefcpst,           --60
                   pauta                  --61
                   )
                values
                  (p_regpedido.codcli,          --1
                   p_regprecos.codicmtab,       --2
                   gvet_regitempedbrinde(i).codprod, --3
                   p_regprecos.codst,              --4
                   p_regpedido.codusur,            --5
                   trunc(sysdate),                 --6
                   vnproxnumped,                    --7
                   vnnumseq,                        --8
                   0,                               --9
                   0,                               --10
                   vsposicao,                        --11
                   vnptabela,                       --12
                   vnptabela,                       --13
                   gvet_regitempedbrinde(i).qt,     --14
                   0,                               --15
                   vtITEM_PRECOS.vlst_ptabela,      --16
                   vnvlcustocont,                    --17
                   vnvlcustofin,                     --18
                   vnvlcustoreal,                    --19
                   vnvlcustorep,                     --20
                   vtITEM_PRECOS.basest_ptabela,     --21
                   vtITEM_PRECOS.vlipi_ptabela,       --22
                   vtITEM_PRECOS.percipi,             --23
                   vnVlDescSuframa,                   --24
                   vnperdescisentoicms,               --25
                   vnvldescicmisencao,                --26
                   'S' ,                               --27
                   vnptabela,                          --28
                   gvet_Regitempedbrinde(i).codfilialretira, --29
                   gvet_regitempedbrinde(i).codigocampanha,   --30
                   '2596',                                     --31
                   gvet_regitempedbrinde(i).usadebcredrcabrind,  --32
                   p_regproduto.qtunit,                           --33
                   gvet_regitempedbrinde(i).grpregrabrinde,  --34
                   case nvl(gregpcconsum.gerarbrindepedbonific, 'N')
                    when 'N' then 'F'
                    else null
                   end,                                  --35
                   vnstclientegnre ,                          --36
                   p_regpedido.numcar,                                         --37
                   gvet_regitempedbrinde(i).codigocampanha,   --38
                   gvet_regitempedbrinde(i).codauxiliar,      --39
                   vnptabela,                                  --40
                   vnptabela,                                  --40
                   p_regprecos.iva,
                   p_regprecos.aliqicms1,
                   p_regprecos.aliqicms2,
                   vnst,
                   vnvlipi,
                   tICMSPARTILHA.vlbasepartdest,    --45
                   tICMSPARTILHA.aliqfcp,           --46
                   tICMSPARTILHA.aliqinternadest,   --47
                   tICMSPARTILHA.vlfcppart,         --48
                   tICMSPARTILHA.vlicmspartdest,    --49
                   tICMSPARTILHA.vlicmspart,        --50
                   tICMSPARTILHA.VLICMSDIFALIQ, --51
                   tICMSPARTILHA.PERCBASERED,   --52
                   tICMSPARTILHA.percprovpart,       --53
                   tICMSPARTILHA.vlicmspartrem,     --54
                   tICMSPARTILHA.ALIQINTERESTADUAL, --55
                   vnvlcustofinest,                  --56
                   case when p_regprecos.tipocalculognre = 'P' and p_regprecos.pagtonomedocliente = 'S' then
                        'S'
                   else
                       'N'
                   end, --57
                   vtITEM_PRECOS.VLFECP, --58
                   vtITEM_PRECOS.ALIQFECP, --59
                   vtITEM_PRECOS.BaseFECP, --60
                   vtITEM_PRECOS.pauta --61
                   );

                 gvet_regitempedbrinde(i).numseq :=  vnnumseq;

                 if p_regproduto.tipomerc = 'CB' then

                    vbvalidocesta := func_inseriritemcesta( vnproxnumped,
                                                            gvet_regitempedbrinde(i).codprod,
                                                            p_regpedido,
                                                            p_regrca,
                                                            p_regcliente,
                                                            p_regregiao,
                                                            p_regfilial,
                                                            vncodplpag,
                                                            vstipovenda,
                                                           vnnumseq );

                    select sum(p.qtmp*vlcustofin),sum(p.qtmp*vlcustoreal),sum(p.qtmp*vlcustorep),sum(p.qtmp*custofinest),sum(p.qtmp*vlcustocont)
                    into vnvlcustofin,vnvlcustoreal,vnvlcustorep,vncustofinest,vnvlcustocont
                    from pcpedicesta p
                    where numped = vnproxnumped
                    and   codprod =  gvet_regitempedbrinde(i).codprod
                    and   numseq  = vnnumseq;

                    update pcpedi
                    set vlcustofin = vnvlcustofin,
                        vlcustoreal = vnvlcustoreal,
                        vlcustorep = vnvlcustorep,
                        vlcustocont = vnvlcustocont,
                        custofinest  = vncustofinest
                    where numped = vnproxnumped
                    and   codprod =  gvet_regitempedbrinde(i).codprod
                    and   numseq  = vnnumseq;



                 end if;


                      if p_integradora = 'S' then --só insere se o pedido está sendo feito pela integradora
                        --inserir na tabela de retorno de itens de brinde
                        insert into PCRETORNOITV5FV
                          (numpedrca,         --1
                           dtaberturapedpalm, --2
                           codusur,           --3
                           cgccli,            --4
                           codcli,            --5
                           codprod,           --6
                           codauxiliar,       --7
                           qt,                --8
                           qt_faturada,       --9
                           ptabela,           --10
                           numseq,            --11
                           codfilialretira,   --12
                           numpedtv5,         --13
                           numpedorigem       --14
                           )
                         values
                          (p_regpedido.numpedrca,         --1
                           p_regpedido.dtaberturapedpalm, --2
                           p_regpedido.codusur,           --3
                           p_cgccli,                      --4
                           p_regpedido.codcli,            --5
                           gvet_regitempedbrinde(i).codprod,           --6
                           null,                           --7
                           gvet_regitempedbrinde(i).qt,     --8
                           gvet_regitempedbrinde(i).qt,    --9
                           vnptabela,           --10
                           vnnumseq,            --11
                           gvet_regitempedbrinde(i).codfilialretira,   --12
                           vnproxnumped,         --13
                           p_regpedido.numped       --14
                           );

                         end if;

                         gvet_regitempedbrinde(i).numseq := vnnumseq;



                 else -- o item que já existe no pedido com mesmo codprod pertence a mesma campanha
                      update pcpedi
                         set qt = qt + gvet_regitempedbrinde(i).qt
                       where numped = vnproxnumped
                         and codprod = gvet_regitempedbrinde(i).codprod;

                      select max(numseq), max(posicao)
                        into gvet_regitempedbrinde(i).numseq, vsposicao
                        from pcpedi
                       where numped = vnproxnumped
                         and codprod = gvet_regitempedbrinde(i).codprod;



                   if p_integradora = 'S' then --só altera se o pedido está sendo feito pela integradora
                        --alterar a qt na tabela de retorno de itens de brinde
                       update PCRETORNOITV5FV
                       set qt = qt + gvet_regitempedbrinde(i).qt
                       where numpedrca = p_regpedido.numpedrca
                       and   codusur   = p_regpedido.codusur
                       and   cgccli    = p_cgccli
                       and   dtaberturapedpalm = p_regpedido.dtaberturapedpalm
                       and   codprod   = gvet_regitempedbrinde(i).codprod;
                   end if;


                  end if;

                         if vsmensagem is null then

                             vsmensagem := 'BRINDE : '|| gvet_regitempedbrinde(i).codprod||'-'||gvet_regitempedbrinde(i).descricao ||CHR(13)||
                                      'QT : '||gvet_regitempedbrinde(i).qt;
                          else

                              vsmensagem := vsmensagem||CHR(13)||'BRINDE : '|| gvet_regitempedbrinde(i).codprod||'-'||gvet_regitempedbrinde(i).descricao ||CHR(13)||
                                      'QT : '||gvet_regitempedbrinde(i).qt ||CHR(13);
                          end if;

                         p_geroubrinde := 'S';


              end if;


             end if;


            else

                   if vsmensagem is null then

                       vsmensagem := 'Brinde sem estoque disponivel : '|| gvet_regitempedbrinde(i).codprod||'-'||gvet_regitempedbrinde(i).descricao ;
                    else

                        vsmensagem := vsmensagem||CHR(13)||'Brinde sem estoque disponivel : '|| gvet_regitempedbrinde(i).codprod||'-'||gvet_regitempedbrinde(i).descricao ||CHR(13);
                    end if;


            end if;

          end if;
          end if;
          end if;


        end loop;

        select count(*),
               sum(pcpedi.qt * pcpedi.pvenda),
               sum(pcpedi.qt * pcpedi.ptabela),
               sum(pcpedi.qt * pcpedi.vlcustocont),
               sum(pcpedi.qt * pcpedi.vlcustofin),
               sum(pcpedi.qt * pcpedi.vlcustoreal),
               sum(pcpedi.qt * pcpedi.vlcustorep)
          into vncontitensvalidos,
               vnvltotped,
               vnvltottab,
               vnvlcustocontped,
               vnvlcustofinped,
               vnvlcustorealped,
               vnvlcustorepped
          from pcpedi
         where pcpedi.numped = vnproxnumped;

        if vncontitensvalidos <> 0 then

          vncodbnf := null;
          select count(*) into vnQtPadrao from pctipobonific where bonifpadrao = 'S';
          if vnQtPadrao > 0 then
             SELECT pctipobonific.codbnf into vncodbnf FROM pctipobonific
                 WHERE pctipobonific.bonifpadrao = 'S' and rownum = '1';
          end if;

          insert into pcpedc
            (codcli,           --1
             codcob,           --2
             coddistrib,       --3
             codemitente,      --4
             codfilial,        --5
             codfilialnf,      --6
             codplpag,         --7
             codpraca,         --8
             codsupervisor,    --9
             codusur,          --10
             condvenda,        --11
             data,             --12
             dtentrega,        --13
             hora,             --14
             minuto,           --15
             numcar,           --16
             numitens,         --17
             numped,           --18
             numpedcli,        --19
             numpedrca,        --20
             operacao,         --21
             origemped,        --22
             percvenda,        --23
             perdesc,          --24
             posicao,          --25
             prazo1,           --26
             prazo2,           --27
             prazo3,           --28
             prazo4,           --29
             prazo5,           --30
             prazo6,           --31
             prazo7,           --32
             prazo8,           --33
             prazo9,           --34
             prazo10,          --35
             prazo11,          --36
             prazo12,          --37
             prazomedio,       --38
             tipovenda,        --39
             totpeso,          --40
             totvolume,        --41
             vlatend,          --42
             vlcustocont,      --43
             vlcustofin,       --44
             vlcustoreal,      --45
             vlcustorep,       --46
             vltabela,         --47
             vltotal,          --48
             numpedtv1,        --49
             brinde,           --50
             localdesembaraco, --51
             ufdesembaraco,     --52
             dtaberturapedpalm,  --53
             fretedespacho,       --54
             codfornecfrete,       --55
             codbnf,             --56
             usaintegracaowms,    --57
             numregiao,           --58
             descintermediador,   --59
             cnpjintermediador,   --60
             codendentcli)   --61
          values
            (p_regpedido.codcli,      --1
             'BNF',                   --2
             p_regrca.coddistrib,     --3
             8888,                    --4
             p_Regpedido.codfilial,      --5
             p_regpedido.codfilialnf,    --6
             vncodplpag,                 --7
             p_regcliente.codpraca,      --8
             p_regrca.codsupervisor,     --9
             p_regpedido.codusur,           --10
             5,                          --11
             trunc(sysdate),                           --12
             nvl(p_regpedido.dtentrega, trunc(sysdate)), --13
             to_number(to_char(sysdate, 'HH24')),        --14
             to_number(to_char(sysdate, 'MI')),          --15
             p_regpedido.numcar,                                           --16
             vncontitensvalidos,                         --17
             vnproxnumped,                               --18
             p_regpedido.numpedcli,                      --19
             p_regpedido.numpedrca,                      --20
             'N',                                        --21
             p_regpedido.origemped,                      --22
             p_regpedido.percvenda,                      --23
             0,                                          --24
             vsposicao,                                  --25
             vnprazo1,                                   --26
             vnprazo2,                                   --27
             vnprazo3,                                   --28
             vnprazo4,                                   --29
             vnprazo5,                                   --30
             vnprazo6,                                   --31
             vnprazo7,                                   --32
             vnprazo8,                                   --33
             vnprazo9,                                   --34
             vnprazo10,                                  --35
             vnprazo11,                                  --36
             vnprazo12,                                  --37
             vnnumdias,                                  --38
             vstipovenda,                                --39
             vnvltotpesoped,                             --40
             vnvltotvolumeped,                           --41
             0,                                          --42
             vnvlcustocontped,                            --43
             vnvlcustofinped,                            --44
             vnvlcustorealped,                           --45
             vnvlcustorepped,                            --46
             vnvltottab,                                 --47
             vnvltotped,                                 --48
             p_regpedido.numped,                         --49
             'S',                                        --50
             p_regpedido.localdesembaraco,               --51
             p_regpedido.ufdesembaraco,                  --52
             p_regpedido.dtaberturapedpalm,              --53
             p_regpedido.fretedespacho ,                 --54
             p_regpedido.codfornecfrete,                 --55
             vncodbnf,                                   --56
             ferramentas.F_BUSCARPARAMETRO_ALFA('FIL_USAINTEGRACAOWMS', p_regpedido.codfilial, 'N'),  --57
             p_regpedido.numregiao,                  --58
             p_regpedido.descintermediador,          --59
             p_regpedido.cnpjintermediador,         --60
             p_regpedido.codendentcli);         --61

          update pcpedc
             set pcpedc.numpedbnf = vnproxnumped
           where numped = p_regpedido.numped;


         for reg_itens in (select codprod,numseq,qt
                           from pcpedi
                           where numped = vnproxnumped ) loop

         vbsaldorca := pc_pkg_controlarsaldorca.ccrca_incluir_item_pedido (
                              8888,
                              2596,
                              p_regpedido.codusur,
                              vnproxnumped,
                              reg_itens.codprod,
                              reg_itens.numseq);
         end loop;



        ---------------------------------
        IF ferramentas.F_BUSCARPARAMETRO_ALFA('SEPARARPRODCOMRESTRICAOTRANSP', p_regpedido.codfilial, 'S') = 'S' THEN

          prc_gerarpedidorestricaotransp(vnproxnumped,
                                         vsauxpedido,
                                         vsmensagemresttransp);

          if vsmensagem is null then
             vsmensagem := vsmensagemresttransp;
          else
             vsmensagem := vsmensagem || chr(13) || vsmensagemresttransp;
          end if;

        ELSE

            SELECT COUNT(*)
              INTO viexisterest
              FROM pcpedi,
                   pcprodut
             WHERE pcpedi.numped = vnproxnumped
               AND pcpedi.codprod = pcprodut.codprod
               AND nvl(pcprodut.restricaotransp,
                       'N') = 'S';

            SELECT COUNT(*)
              INTO viexisterestref
              FROM pcpedi,
                   pcprodut
             WHERE pcpedi.numped = vnproxnumped
               AND pcpedi.codprod = pcprodut.codprod
               AND nvl(pcprodut.restricaotransp,
                       'N') = 'R';


            IF viexisterestref > 0
            THEN

              UPDATE pcpedc
                 SET pcpedc.restricaotransp = 'R'
               WHERE numped = vnproxnumped;


            ELSE

              IF viexisterest > 0
              THEN

                UPDATE pcpedc
                   SET pcpedc.restricaotransp = 'S'
                 WHERE numped = vnproxnumped;


              END IF;
            END IF;
        END IF;
        ---------------------------------

            if vsmensagem is null then

                vsmensagem := 'GERADO PEDIDO DE BRINDE : '|| vnproxnumped;
            else

                vsmensagem := vsmensagem||CHR(13)||'GERADO PEDIDO DE BRINDE : '|| vnproxnumped|| CHR(13);
            end if;


           if p_integradora = 'S' then --só insere se o pedido está sendo feito pela integradora
                 --inserir na tabela de retorno de pedido de brinde
                 insert into PCRETORNOCTV5FV
                 (numpedrca,          --1
                  dtaberturapedpalm,  --2
                  codusur,            --3
                  cgccli,             --4
                  codcli,             --5
                  numpedorigem,       --6
                  numpedtv5,          --7
                  retorno,            --8
                  posicao_Atual,      --9
                  codfilial,          --10
                  codfilialnf,        --11
                  codfilialretira,    --12
                  dtentrega,          --13
                  gerarbrindepedbonific   --14
                  )
                 values
                  (p_regpedido.numpedrca,          --1
                   p_regpedido.dtaberturapedpalm,  --2
                   p_regpedido.codusur,            --3
                   p_cgccli,                       --4
                   p_regpedido.codcli,             --5
                   p_regpedido.numped,             --6
                   vnproxnumped,                   --7
                   2,                              --8
                   vsposicao,                      --9
                   p_regpedido.codfilial,          --10
                   p_regpedido.codfilialnf,        --11
                   p_codfilialretira,              --12
                   p_regpedido.dtentrega,          --13
                   'S'                             --14
                   );
                end if;




        end if;
      else

        -- não gerar pedido de brinde separado

        vsposicao := p_regpedido.posicao;

        for i in 1 .. vnnumitensbonific loop

          vnnumseq := vnnumseq + 1;
          vnvlsaldoped := 0;
          vbvalido := true;

              select pcprodut.codsec, pcprodut.codepto,nvl(pcprodut.percipivenda,0),nvl(pcprodut.percipivendatab,0), nvl(pcprodut.vlpautaipivenda,0),
                 nvl(pcprodut.vlpautaipivendatab,0),nvl(pcprodut.vlipiporkgvenda,0),nvl(pcprodut.vlipiporkgvendatab,0),nvl(pcprodut.pesobruto,0),
                 nvl(pcprodut.precomaxconsum,0),pcprodut.volume,pcprodut.codfornec,pcprodut.classe,pcprodut.importado,nvl(pcprodut.tipomerc,' '),
                 nvl(pcprodut.qtunit,1),codprodprinc
            into p_regproduto
            from pcprodut
           where pcprodut.codprod = gvet_regitempedbrinde(i).codprod;

          if p_regfilial.utilizavendaporembalagem = 'S' then
               p_regproduto.qtunit := gvet_regitempedbrinde(i).qtunit;
          END IF;

          vnvltotpesoped   := vnvltotpesoped +
                              (p_regproduto.pesobruto * gvet_regitempedbrinde(i).qt);
          vnvltotvolumeped := vnvltotvolumeped +
                              (p_regproduto.volume * gvet_regitempedbrinde(i).qt);



         proc_buscaprecoitem(gvet_regitempedbrinde(i),
                             p_regproduto.tipomerc,
                             p_regpedido,
                             p_regregiao,
                             p_regcliente,
                             p_regfilial,
                             p_regprecos,
                             vbvalido,
                             vsmensagemprecoitem);

           if vsmensagem is null then

               vsmensagem := vsmensagemprecoitem;
            else

                vsmensagem := vsmensagem||CHR(13)||vsmensagemprecoitem|| CHR(13);
            end if;



          if vbvalido = true then

           if p_regproduto.tipomerc <> 'CB' then

            if p_regplpag.numpr = 1 then
              vnptabela := p_regprecos.pvenda1;
            elsif p_regplpag.numpr = 2 then
              vnptabela := p_regprecos.pvenda2;
            elsif p_regplpag.numpr = 3 then
              vnptabela := p_regprecos.pvenda3;
            elsif p_regplpag.numpr = 4 then
              vnptabela := p_regprecos.pvenda4;
            elsif p_regplpag.numpr = 5 then
              vnptabela := p_regprecos.pvenda5;
            elsif p_regplpag.numpr = 6 then
              vnptabela := p_regprecos.pvenda6;
            elsif p_regplpag.numpr = 7 then
              vnptabela := p_regprecos.pvenda7;
            end if;

           else

            proc_buscaprecocesta(p_numped,
                                 gvet_regitempedbrinde(i).codprod,
                                 gvet_regitempedbrinde(i).qt,
                                 p_regpedido,
                                 p_regregiao,
                                 p_regplpag.numpr,
                                 p_regcliente,
                                 p_Regfilial,
                                 vnptabela,
                                 vbvalido);

           end if;

         vnpbaserca := vnptabela;
         vtITEM_PRECOS.ptabela := vnptabela;

          proc_validapoliticas(gvet_regitempedbrinde(i),
                               p_regpedido,
                               p_regfilial,
                               p_regcliente,
                               p_regrca,
                               p_regproduto.codprodprinc,
                               p_regplpag.codplpag,
                               p_regplpag.numdias,
                               p_regplpag.pertxfim,
                               vnptabela,
                               vnpbaserca,
                               vsmensagempolitica);

             if vsmensagempolitica is not null and vsmensagempolitica not in ('S','N') then

                if vsmensagem is null then

                   vsmensagem := vsmensagempolitica;
                 else

                    vsmensagem := vsmensagem||CHR(13)||vsmensagempolitica|| CHR(13);
                end if;


             end if;



            if vnptabela <= 0 then


                   if vsmensagem is null then

                       vsmensagem := 'Item de brinde com preço inválido : '|| gvet_regitempedbrinde(i).codprod||'-'||gvet_regitempedbrinde(i).descricao ;
                    else

                        vsmensagem := vsmensagem||CHR(13)||'Item de brinde com preço inválido : '|| gvet_regitempedbrinde(i).codprod||'-'||gvet_regitempedbrinde(i).descricao ||CHR(13);
                    end if;

             vbvalido := false;

          end if;


          if vbvalido = true then

            begin
              select pcfilial.uf
                into vsuffilialnf
                from pcfilial
               where pcfilial.codigo = p_Regpedido.codfilialnf;
            exception
              when others then
                vsuffilialnf := null;
            end;

            vbcalculast_valido := funcoesvendas.calcularimpostos(vnptabela,
                                                                 vnptabela,
                                                                 vnpbaserca,
                                                                 vnvlipi,
                                                                 vnpercipi,
                                                                 nvl(vnpercipivenda,
                                                                     0),
                                                                 p_regpedido.percvenda,
                                                                 gregpcconsum.tipocalcst,
                                                                 gregpcconsum.calcstpf,
                                                                 p_regprecos.mostrarpvendasemst,
                                                                 gregpcconsum.consideraisentoscomopf,
                                                                 p_regcliente.calculast,
                                                                 p_regcliente.ieent,
                                                                 p_regcliente.tipofj,
                                                                 p_regprecos.pauta,
                                                                 p_regprecos.iva,
                                                                 p_regprecos.aliqicms1,
                                                                 p_regprecos.aliqicms2,
                                                                 p_regprecos.percbaseredst,
                                                                 gregpcconsum.numcasasdecvenda,
                                                                 0,
                                                                 p_regfilial.uf,
                                                                 p_regcliente.estent,
                                                                 nvl(p_regprecos.usavalorultentbasest,'N'),
                                                                 nvl(p_regprecos.usavalorultentbasest2,'N'),
                                                                 p_regprecos.valorultent,
                                                                 p_regcliente.isentoipi,
                                                                 p_regcliente.suframa,
                                                                 gregpcconsum.calcularstcomipi,
                                                                 gregpcconsum.tipocalcipi,
                                                                 p_regpedido.codfilialnf,
                                                                 5,
                                                                 p_regcliente.contribuinte,
                                                                 vsuffilialnf,
                                                                 p_regproduto.importado,
                                                                 p_regfilial.calcularipivenda,
                                                                 p_regproduto.PERCIPIVENDATAB,
                                                                 p_regproduto.VLPAUTAIPIVENDA,
                                                                 p_regproduto.VLPAUTAIPIVENDATAB,
                                                                 p_regproduto.VLIPIPORKGVENDA,
                                                                 p_regproduto.VLIPIPORKGVENDATAB,
                                                                 p_regproduto.pesobruto,
                                                                 p_regprecos.tipocalculognre,
                                                                 'N', --p_regcliente.simplesnacional,
                                                                 0, --p_regprecos.percredpvendasimplesnac,
                                                                 'N',
                                                                 p_regcliente.utilizaiesimplificada,
                                                                 vsmensagem_st,
                                                                 vnst,
                                                                 vnbaseicst,
                                                                 gregpcconsum.aceitapfcontribuinte,
                                                                 p_regprecos.custonfsemst,
                                                                 p_regprecos.usapmcbasest,
                                                                 p_regproduto.precomaxconsum,
                                                                 p_regcliente.consumidorfinal,
                                                                 'N',
                                                                 'N',
                                                                 'N',
                                                                  'N',
                                                                 0, --60
                                                                  0,
                                                                  p_regprecos.usavlultentmediobasest);



                  if p_regprecos.tipocalculognre = 'C' then

                      --24 parâmetros
                      vbcalculast_valido := funcoesvendas.calcularst(vnptabela,
                                                                    0,
                                                                    p_regpedido.percvenda,
                                                                    gregpcconsum.tipocalcst,
                                                                    gregpcconsum.calcstpf,
                                                                    p_regprecos.mostrarpvendasemst,
                                                                    gregpcconsum.consideraisentoscomopf,
                                                                    p_regcliente.calculast,
                                                                    p_regcliente.ieent,
                                                                    p_regcliente.tipofj,
                                                                    p_regprecos.pauta,
                                                                    p_regprecos.iva,
                                                                    p_regprecos.aliqicms1,
                                                                    p_regprecos.aliqicms2,
                                                                    p_regprecos.percbaseredst,
                                                                    gregpcconsum.numcasasdecvenda,
                                                                    1,
                                                                    p_regfilial.uf,
                                                                    p_regcliente.estent,
                                                                    nvl(p_regprecos.usavalorultentbasest,'N'),
                                                                    nvl(p_regprecos.usavalorultentbasest2,'N'),
                                                                    p_regprecos.valorultent,
                                                                    p_regcliente.contribuinte,
                                                                    p_regcliente.utilizaiesimplificada,
                                                                    vsmensagem_st,
                                                                    vnst,
                                                                    vnbaseicst,
                                                                    gregpcconsum.aceitapfcontribuinte,
                                                                    p_regprecos.usapmcbasest,
                                                                    p_regproduto.precomaxconsum,
                                                                    p_regprecos.custonfsemst,
                                                                    p_regcliente.consumidorfinal);

                      vnstclientegnre := vnst;
                      vnst := 0;

                    end if;

                    if vsmensagem_st is not null then


                        if vsmensagem is null then

                           vsmensagem := vsmensagem_st;
                        else

                            vsmensagem := vsmensagem||CHR(13)||vsmensagem_st;
                        end if;
                    end if;



            vnstfonte := 0;

            vnstfonte := funcoesvendas.calcularstfonte(gvet_regitempedbrinde(i).codprod,
                                                       5,
                                                       p_regpedido.percvenda,
                                                       p_regprecos.iva,
                                                       p_regprecos.ivafonte,
                                                       p_regprecos.aliqicms1fonte,
                                                       p_regprecos.aliqicms2fonte,
                                                       p_regprecos.percbaseredstfonte,
                                                       p_regprecos.perbaserednrpa,
                                                       p_regprecos.percbaseredconsumidor,
                                                       p_regprecos.utilizapercbaseredpf,
                                                       gregpcconsum.tipocalcst,
                                                       NVL(gregPCCONSUM.CALCSTFONTEPF,
                                                           NVL(gregPCCONSUM.CALCSTPF,
                                                               'S')),
                                                       gregpcconsum.utilizapercbaseredpf,
                                                       p_regcliente.clientefontest,
                                                       p_regcliente.calculast,
                                                       p_regcliente.ieent,
                                                       p_regcliente.tipofj,
                                                       p_regcliente.isentoicms,
                                                       p_regcliente.consumidorfinal,
                                                       p_regcliente.utilizaiesimplificada,
                                                       p_regcliente.tipoempresa,
                                                       gregpcconsum.consideraisentoscomopf,
                                                       (vnptabela - nvl(vnvlipi,0) - nvl(vnst,0)),
                                                       vnvlipi,
                                                       p_regfilial.uf,
                                                       p_regcliente.estent,
                                                       nvl(p_regprecos.usavalorultentbasest,'N'),
                                                       p_regprecos.valorultent,
                                                       p_regcliente.usaivafontediferenciado,
                                                       p_regcliente.ivafonte,
                                                       gregpcconsum.aceitapfcontribuinte,
                                                       p_Regprecos.aliqicms1,
                                                       p_regprecos.aliqicms2,
                                                       p_regcliente.contribuinte,
                                                       gregpcconsum.numcasasdecvenda,
                                                       vnbaseicst_fonte,
                                                       vsmensagem_stfonte,
                                                       p_regprecos.custonfsemst,
                                                       p_regprecos.usavalorultentbasest2,
                                                       p_regprecos.usapmcbasest,
                                                       p_regproduto.precomaxconsum);
            if vnbaseicst_fonte > 0 then
              vnbaseicst := vnbaseicst_fonte;
            end if;

            if (vnST = 0) and (vnSTFONTE <> 0) then
              vnst := vnSTFONTE;
              vnptabela := Round(vnptabela + vnSTFONTE,
                                 gregpcconsum.numcasasdecvenda);
              vnpbaserca := Round(vnpbaserca + vnSTFONTE,
                                 gregpcconsum.numcasasdecvenda);

              vnIVA := p_regprecos.ivafonte;
              vnPAUTA := 0;
              vnALIQICMS1 := p_regprecos.aliqicms1fonte;
              vnALIQICMS2 := p_regprecos.aliqicms2fonte;
              vnPERCBASEREDST := p_regprecos.percbaseredst;
              vnPERCBASEREDSTFONTE := p_regprecos.PERCBASEREDSTFONTE;

              p_regprecos.iva := vnIVA;
              p_regprecos.aliqicms1 := vnALIQICMS1;
              p_regprecos.aliqicms2 := vnALIQICMS2;

            end if;


            --Cálculo do %Desc. Suframa

            vnVlDescSuframa := 0;

            if trim(p_regCLIENTe.SUFRAMA) is not null then
              vnVlDescSuframa := ((vnptabela - nvl(vnst,0) - 0) *
                                 (p_regpedido.percvenda / 100)) *
                                 (nvl(p_regprecos.PERDESCSUFRAMA, 0) / 100);
              if gregpcconsum.TIPOCALCSULFRAMA = 'T2' then
                --Calcular ST - Truncar com 2 casas decimais
                vnVlDescSuframa := Trunc((vnVlDescSuframa) * 100) / 100;
              elsif gregPCCONSUM.TIPOCALCSULFRAMA = 'A2' then
                --Calcular ST - Arredondar com 2 casas decimais
                vnVlDescSuframa := Round((vnVlDescSuframa) * 100) / 100;
              elsif gregPCCONSUM.TIPOCALCSULFRAMA = 'PV' then
                --Calcular ST - Conf. Casas Dec. Venda
                vnVlDescSuframa := Round(vnVlDescSuframa,
                                         gregpcconsum.numcasasdecvenda);
              end if;
              vnptabela := Round(vnptabela - nvl(vnVLDESCSUFRAMA,0),
                                 gregpcconsum.numcasasdecvenda);
            end if;

            if p_regCLIENTe.tipodescisencao = 'C' then
              vnperdescisentoicms := p_regCLIENTe.perdescisentoicms;
            elsif p_regCLIENTe.tipodescisencao = 'T' then
              vnperdescisentoicms := p_regprecos.perdescicmisencao;
            else
              vnperdescisentoicms := 0;
            end if;

            if nvl(vnperdescisentoicms, 0) > 0 then
              vnVLDESCICMISENCAO := ((vnptabela - nvl(vnST,0) - 0) *
                                    (p_regpedido.PERCVENDA / 100)) *
                                    (vnperdescisentoicms / 100);
              vnptabela := Round(vnptabela - vnVLDESCICMISENCAO,
                                 gregpcconsum.numcasasdecvenda);
            end if;

            -- buscar custos do item
            vnvlcustocont := p_regprecos.custocont;
            vnvlcustorep  := p_regprecos.custorep;
            vnvlcustofin  := (p_regprecos.custofin -
                             (p_regprecos.custofin *
                             p_regprecos.perdesccusto / 100) +
                             (vnptabela * nvl(gregpcconsum.txvenda, 0) / 100)
                             --              + (p_regitem.pvenda * p_regitem.percom / 100)
                             + ((vnptabela - vnst) * p_regprecos.codicmtab / 100) + vnst);
            vnvlcustoreal := (p_regprecos.custoreal -
                             (p_regprecos.custoreal *
                             p_regprecos.perdesccusto / 100) +
                             (vnptabela * nvl(gregpcconsum.txvenda, 0) / 100)
                             --              + (p_regitem.pvenda * p_regitem.percom / 100)
                             + ((vnptabela - vnst) * p_regprecos.codicmtab / 100) + vnst);

         vnvldisponivel := pc_pkg_controlarsaldorca.ccrca_checar_disponivel_atual(p_regpedido.codusur);



            if vnvldisponivel - ( vnptabela + vnvlsaldoped) < 0  and gvet_regitempedbrinde(i).usadebcredrcabrind = 'S' 
              and (PC_PKG_CONTROLARSALDORCA.CONTROLASALDORCA(FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USACREDRCA','99','N'),    
                                                                      p_regpedido.usadebcredrca,           
                                                                      p_regpedido.brinde,                  
                                                                      p_regpedido.bonificaltdebcredrca,                                                        
                                                                      p_regpedido.trocaaltdebcredrca,
                                                                      p_regpedido.broker,                                                                      
                                                                      p_regpedido.brokeraltdebcredrca,                                                         
                                                                      p_regpedido.origemped,                                                                   
                                                                      p_regpedido.crmaltdebcredrca,       
                                                                      p_regcliente.usadebcredrca,    
                                                                      p_regpedido.condvenda,               
                                                                      gvet_regitempedbrinde(i).usadebcredrcabrind ) = 'S') then             

              vbvalido := false;

              if vsmensagem is null then

                 vsmensagem := 'Rca sem credito disponivel para liberar brinde. ' ||' '||gvet_regitempedbrinde(i).codprod||' '||gvet_regitempedbrinde(i).descricao;
              else

                  vsmensagem := vsmensagem||CHR(13)||'Rca sem credito disponivel para liberar brinde. '||' '||gvet_regitempedbrinde(i).codprod||' '||gvet_regitempedbrinde(i).descricao|| CHR(13);
              end if;

            else

               vnvlsaldoped := vnvlsaldoped + nvl(vnptabela,0) ;

          select count(*)
            into vicontador
            from pcpedi
           where numped = p_regpedido.numped
             and codprod = gvet_regitempedbrinde(i).codprod;

          vnqtdispbrinde := 0;

            vnqtdispbrindecont := 0;

                begin
                  -- Verificar Estoque para evitar o Corte do Brinde

                  BEGIN
                    SELECT NVL(QT, 0)
                      INTO vnQtNoPedido
                      FROM PCPEDI
                     WHERE CODPROD = GVET_REGCAMPANHA(I).CODPROD
                       AND CODFILIALRETIRA = vscodfilialretira
                       AND NUMPED = P_NUMPED;
                  EXCEPTION
                    WHEN OTHERS THEN
                      vnQtNoPedido := 0;
                  END;

                  select greatest(nvl(qtestger, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        DECODE(vsBLOQUEIAVENDAESTPENDENTE, 'S', NVL(QTPENDENTE, 0), 0)-
                        greatest(nvl(qtbloqueada, 0), 0) -
                        greatest(vnQtNoPedido),
                        greatest(nvl(qtest, 0), 0) -
                        greatest(nvl(qtreserv, 0), 0) -
                        greatest(vnQtNoPedido)
                    into vnqtdispbrinde,vnqtdispbrindecont
                    from pcest
                   where pcest.codprod = gvet_regitempedbrinde(i).codprod
                     and pcest.codfilial = gvet_regitempedbrinde(i).codfilialretira;
                --   for update  ;

                exception
                  when others then
                    vnqtdispbrinde := 0;
                    vnqtdispbrindecont := 0;
                end;

               /*  vnqttotprod := 0;

                begin
                 SELECT sum(qt)
                 into vnqttotprod
                 FROM pcpedi
                 WHERE numped = vnproxnumped
                 AND codprod = gvet_regitempedbrinde(i).codprod
                 and numseq < nvl(vnnumseq,1)
                 and codfilialretira = gvet_regitempedbrinde(i).codfilialretira;
                 exception when others then
                 vnqttotprod := 0;
                end;


             vnqtdispbrinde     := greatest(vnqtdispbrinde,0) - nvl(vnqttotprod,0);
             vnqtdispbrindecont := greatest(vnqtdispbrindecont,0) - nvl(vnqttotprod,0); */


            if ( (vnqtdispbrinde >= gvet_regitempedbrinde(i).qt)  AND
                 ( (vnqtdispbrindecont >= gvet_regitempedbrinde(i).qt) and
                   (NVL(p_regfilial.verificaestoquecont,p_regfilial.con_verificaestoquecont) = 'S')) or
                   (NVL(p_regfilial.verificaestoquecont,p_regfilial.con_verificaestoquecont) = 'N') )
                OR
                (p_regpedido.posicaoini in ('P','B')) then



            if gvet_regitempedbrinde(i).numcampanha <> 10 then

             begin
              select sum(qt)
              into vnqtbrindeutil
              from pcpedi p
              where p.codigobrinde = to_char(gvet_regitempedbrinde(i).codigocampanha)
              and   p.codprod     = gvet_regitempedbrinde(i).codprod
              and   p.posicao     <> 'C';
              exception when others then

                   if vsmensagem is null then

                       vsmensagem := 'Erro ao verificar qtd de brinde utilizada : '|| gvet_regitempedbrinde(i).codprod||'-'||gvet_regitempedbrinde(i).descricao ||CHR(13)||
                        SQLCODE||' '||SQLERRM;
                    else

                        vsmensagem := vsmensagem||CHR(13)||'Erro ao verificar qtd de brinde utilizada : '|| gvet_regitempedbrinde(i).codprod||'-'||gvet_regitempedbrinde(i).descricao ||CHR(13)||
                         SQLCODE||' '||SQLERRM;
                    end if;
              end;

              if nvl(gregpcconsum.gerarbrindepedbonific, 'N') = 'N' and vnqtlimite is null
              THEN
               if gvet_regitempedbrinde(i).numcampanha in (4,5) then
                 select p.qtlimitebrinde
                 into vnqtlimite
                 from pcpromi p
                 where p.codigo = gvet_regitempedbrinde(i).codigocampanha
                 and   p.codprod = gvet_regitempedbrinde(i).codprod
                 for update;

                elsif gvet_regitempedbrinde(i).numcampanha = 10 then

                   null;

                else
                 select p.qtlimitebrinde
                 into vnqtlimite
                 from pcpromc p
                 where p.codigo = gvet_regitempedbrinde(i).codigocampanha
                 for update;

                end if;

              END IF;

              select nvl(vnqtlimite,0) - nvl(vnqtbrindeutil,0)
              into vnqtsaldo
              from dual;

              if nvl(vnqtlimite,0) > 0  then

              if vnqtsaldo <= 0 then
                 gvet_regitempedbrinde(i).qt := 0;


                   if vsmensagem is null then

                       vsmensagem := 'Brinde ultrapassou limite estipulado na campanha : : '|| gvet_regitempedbrinde(i).codprod||'-'||gvet_regitempedbrinde(i).descricao ;
                    else

                        vsmensagem := vsmensagem||CHR(13)||'Brinde ultrapassou limite estipulado na campanha : '|| gvet_regitempedbrinde(i).codprod||'-'||gvet_regitempedbrinde(i).descricao ||CHR(13);
                    end if;



              else

                 if vnqtsaldo < gvet_regitempedbrinde(i).qt then

                    gvet_regitempedbrinde(i).qt := vnqtsaldo;


                   if vsmensagem is null then

                       vsmensagem := 'Brinde ultrapassou limite estipulado na campanha, tera quantidade reduzida : '|| gvet_regitempedbrinde(i).codprod||'-'||gvet_regitempedbrinde(i).descricao;
                    else

                        vsmensagem := vsmensagem||CHR(13)||'Brinde ultrapassou limite estipulado na campanha, tera quantidade reduzida : '|| gvet_regitempedbrinde(i).codprod||'-'||gvet_regitempedbrinde(i).descricao ||CHR(13);
                    end if;



                 end if;

              end if;
             end if;
           end if;

           -- Integração Força de Venda
           vnqtbrindefv := func_buscar_qtde_fv(
                  p_regpedido.numpedrca,
                  p_regpedido.codusur,
                  p_cgccli,
                  p_regpedido.dtaberturapedpalm,
                  gvet_regitempedbrinde(i).codprod,
                  vbgerarbrindefv) ;
                  
           if not vbgerarbrindefv then
              gvet_regitempedbrinde(i).qt := 0;
              if vsmensagem is null then
                vsmensagem := 'Brinde zerado pelo Força de Venda. '||gvet_regitempedbrinde(i).codprod||' '||gvet_regitempedbrinde(i).descricao;
              else
                vsmensagem := vsmensagem||CHR(13)||'Brinde zerado pelo Força de Venda. '||gvet_regitempedbrinde(i).codprod||' '||gvet_regitempedbrinde(i).descricao;
              end if;
           end if;                  
              
           if gvet_regitempedbrinde(i).qt > 0 then
              
              if vnqtbrindefv > 0 and 
                vnqtbrindefv < gvet_regitempedbrinde(i).qt then
                gvet_regitempedbrinde(i).qt := vnqtbrindefv;
                if vsmensagem is null then
                  vsmensagem := 'Quantidade de Brindes alterada pelo Força de Venda. '||gvet_regitempedbrinde(i).codprod||' '||gvet_regitempedbrinde(i).descricao;
                else
                  vsmensagem := vsmensagem||CHR(13)||'Quantidade de Brindes alterada pelo Força de Venda. '||gvet_regitempedbrinde(i).codprod||' '||gvet_regitempedbrinde(i).descricao;
                end if;
              end if; 


            if vicontador = 0 then

               T_PCPEDC.CODCLI := p_regpedido.codcli;
               T_PCPEDC.CODFILIAL := P_REGPEDIDO.codfilial;
               T_PCPEDC.CODFILIALNF := P_REGPEDIDO.codfilialnf;
               T_PCPEDC.CONDVENDA := 5;
               T_PCPEDC.CODCOB := 'BNF';


               T_PCPEDI.PVENDA := vnptabela;
               T_PCPEDI.CODST  := p_regprecos.CODST;
               T_PCPEDI.CODPROD := gvet_regitempedbrinde(i).codprod;

               FERRAMENTAS.DEFINIRCODFISCAL(T_PCPEDC, T_PCPEDI, VNCODFISCAL, VNSITTRIBUT, vsmensagemcodfiscal);
               vsmensagem := vsmensagem || ' ' ||  vsmensagemcodfiscal;

               -- Preço de tabela
                vtITEM_PRECOS.pvenda   := round(vnptabela, gregpcconsum.numcasasdecvenda);
                vtITEM_PRECOS.ptabela  := round(vnptabela, gregpcconsum.numcasasdecvenda);
                vtITEM_PRECOS.pbaserca := round(vnptabela, gregpcconsum.numcasasdecvenda);

                -- ST de tabela
                vnst := p_regprecos.vlst;

                -- Calcula Preço sem Imposto
                SELECT round(VALORSEMIMPOSTO,gregpcconsum.numcasasdecvenda), MSG
                  INTO vtITEM_PRECOS.ptabela_semimpostos, vsMSGPartilha
                FROM TABLE(PKG_TRIBUTACAO.CALCULAR_PVENDA_SEM_IMPOSTO(p_regpedido.codfilial,
                                                                      p_regpedido.codfilialnf,
                                                                      gvet_Regitempedbrinde(i).codfilialretira,
                                                                      p_regpedido.codcli,
                                                                      p_regpedido.codplpag,
                                                                      gvet_regitempedbrinde(i).codprod,
                                                                      gvet_regitempedbrinde(i).codauxiliar,
                                                                      p_regpedido.condvenda,
                                                                      'N',
                                                                      vnst, --1,
                                                                      0,
                                                                      ROUND(vtITEM_PRECOS.ptabela, gregpcconsum.numcasasdecvenda),
                                                                      'S',
                                                                      'S',
                                                                      'N',
                                                                      '',--0,
                                                                      NULL,
                                                                      'N',
                                                                      'N',
                                                                      'N',
                                                                      'N',
                                                                      0,
                                                                      'N',
                                                                      'I'));

                -- Calcula ICMS Partilha
                pkg_fwpc_fiscal.icmspartilha_calcular_1_4(nvl(p_regpedido.codfilialnf,p_regpedido.codfilial),
                                                         p_regpedido.codcli,
                                                         '',
                                                         vsufEnt,
                                                         p_regpedido.data,
                                                         vtITEM_PRECOS.ptabela_semimpostos,
                                                         p_regprecos.codst,
                                                         gvet_regitempedbrinde(i).codprod,
                                                         VNCODFISCAL,--CFOP
                                                         VNSITTRIBUT,--CST
                                                         tICMSPARTILHA,
                                                         vnCodMSGPartilha,
                                                         vsMSGPartilha);

               -- Agrega o ICMS Partilha no preço
               vtITEM_PRECOS.ptabela_semimpostos := vtITEM_PRECOS.ptabela_semimpostos + nvl(tICMSPARTILHA.VLICMSPART,0);

               -- Calcula o valor de IPI
               SELECT VALORIPI, PERCENTUAL_IPI
                       INTO vtITEM_PRECOS.vlipi_ptabela, vtITEM_PRECOS.percipi
                 FROM TABLE(PKG_TRIBUTACAO.CALCULAR_IPI(p_regpedido.codfilial,
                                                        p_regpedido.codfilialnf,
                                                        gvet_regitempedbrinde(i).codfilialretira,
                                                        p_regpedido.codcli,
                                                        gvet_regitempedbrinde(i).codprod,
                                                        gvet_regitempedbrinde(i).codauxiliar,
                                                        p_regpedido.condvenda,
                                                        'N',
                                                        vtITEM_PRECOS.ptabela_semimpostos,
                                                        'N',
                                                        null,
                                                        'N',--transferencia
                                                        'N',--transferenciaVirtual
                                                        'N',
                                                        'F',
                                                        null,
                                                        'I'));


                -- Calcula ST e FECP
                SELECT BASEST,
                       ST,
                       VLRFECP,
                       BASEFECP,
                       ALIQFECP,
                       PAUTA,
                       IVA,
                       ALIQICMS1,
                       ALIQICMS2
                  INTO vtITEM_PRECOS.basest_ptabela,
                       vtITEM_PRECOS.vlst_ptabela,
                       vtITEM_PRECOS.VLFECP,
                       vtITEM_PRECOS.BaseFECP,
                       vtITEM_PRECOS.ALIQFECP,
                       vtITEM_PRECOS.pauta,
                       p_regprecos.iva,
                       p_regprecos.aliqicms1,
                       p_regprecos.aliqicms2
                FROM TABLE(PKG_TRIBUTACAO.CALCULAR_ST(p_regpedido.codfilial,
                                                      p_regpedido.codfilialnf,
                                                      gvet_regitempedbrinde(i).codfilialretira,
                                                      p_regpedido.codcli,
                                                      p_regpedido.codplpag,
                                                      gvet_regitempedbrinde(i).codprod,
                                                      gvet_regitempedbrinde(i).codauxiliar,
                                                      p_regpedido.condvenda,
                                                      'N',
                                                      vtITEM_PRECOS.ptabela_semimpostos,
                                                      0));

                -- Calcula o preço final
                IF p_regprecos.tipocalculognre <> 'C' THEN
                   vnptabela := vtITEM_PRECOS.ptabela_semimpostos + vtITEM_PRECOS.vlipi_ptabela + vtITEM_PRECOS.vlst_ptabela + vtITEM_PRECOS.VLFECP;
                   vnst := vtITEM_PRECOS.vlst_ptabela;
                ELSE
                   vnptabela := vtITEM_PRECOS.ptabela_semimpostos + vtITEM_PRECOS.vlipi_ptabela;
                   vnst := 0;
                END IF;

                -- buscar custos do item
                vnvlcustocont   := p_regprecos.custocont;
                vnvlcustorep    := p_regprecos.custorep;
                vnvlcustofinest := p_regprecos.custofin;
                vnvlcustofin  := (p_regprecos.custofin -
                                 (p_regprecos.custofin *
                                 p_regprecos.perdesccusto / 100) +
                                 (vnptabela * nvl(gregpcconsum.txvenda, 0) / 100)
                                 --              + (p_regitem.pvenda * p_regitem.percom / 100)
                                 + ((vtITEM_PRECOS.ptabela_semimpostos - nvl(tICMSPARTILHA.VLICMSPART,0)) * p_regprecos.codicmtab / 100) + vtITEM_PRECOS.vlipi_ptabela + vtITEM_PRECOS.vlst_ptabela + vtITEM_PRECOS.VLFECP + nvl(tICMSPARTILHA.VLICMSPART,0));
                vnvlcustoreal := (p_regprecos.custoreal -
                                 (p_regprecos.custoreal *
                                 p_regprecos.perdesccusto / 100) +
                                 (vnptabela * nvl(gregpcconsum.txvenda, 0) / 100)
                                 --              + (p_regitem.pvenda * p_regitem.percom / 100)
                                 + ((vtITEM_PRECOS.ptabela_semimpostos - nvl(tICMSPARTILHA.VLICMSPART,0)) * p_regprecos.codicmtab / 100) + vtITEM_PRECOS.vlipi_ptabela + vtITEM_PRECOS.vlst_ptabela + vtITEM_PRECOS.VLFECP + nvl(tICMSPARTILHA.VLICMSPART,0));


                 insert into pcpedi
                  (codcli,     --1
                   codicmtab,  --2
                   codprod,    --3
                   codst,      --4
                   codusur,    --5
                   data,       --6
                   numped,     --7
                   numseq,     --8
                   percom,     --9
                   perdesc,    --10
                   posicao,    --11
                   ptabela,    --12
                   pvenda,     --13
                   qt,         --14
                   qtfalta,    --15
                   st,         --16
                   vlcustocont,  --17
                   vlcustofin,   --18
                   vlcustoreal,  --19
                   vlcustorep,   --20
                   baseicst,     --21
                   vlipi,        --22
                   percipi,      --23
                   vldescsuframa,  --24
                   perdescisentoicms, --25
                   vldescicmisencao,   --26
                   brinde  ,           --27
                   pbaserca,            --28
                   codfilialretira,      --29
                   codigobrinde,           --30
                   rotinalanc,             --31
                   usadebcredrcabrind,     --32
                   qtunitemb,               --33
                   grpregrabrinde,             --34
                   bonific,                    --35
                   stclientegnre,               --36
                   numcar,                     --37
                   codpromocao,                --38
                   codauxiliar,                --39
                   pbonific,                    --40
                   vlbonific,
                   iva,
                   aliqicms1,
                   aliqicms2,
                   stptabela,
                   vlipiptabela,
                   vlbasepartdest,    --45
                   aliqfcp,           --46
                   aliqinternadest,   --47
                   vlfcppart,         --48
                   vlicmspartdest,    --49
                   vlicmspart,        --50
                   VLICMSDIFALIQPART, --51
                   PERCBASEREDPART,   --52
                   PERCPROVPART,       --53
                   VLICMSPARTREM,     --54
                   ALIQINTERORIGPART, --55
                   custofinest,        --56
                   geragnre_cnpjcliente, --57
                   vlfecp,               --58
                   aliqicmsfecp,         --59
                   vlbasefcpst,           --60
                   pauta                  --61
                   )
                values
                  (p_regpedido.codcli,          --1
                   p_regprecos.codicmtab,       --2
                   gvet_regitempedbrinde(i).codprod, --3
                   p_regprecos.codst,              --4
                   p_regpedido.codusur,            --5
                   trunc(sysdate),                 --6
                   p_regpedido.numped,              --7
                   vnnumseq,                        --8
                   0,                               --9
                   0,                               --10
                   p_regpedido.posicao,             --11
                   vnptabela,                       --12
                   vnptabela,                       --13
                   gvet_regitempedbrinde(i).qt,     --14
                   0,                               --15
                   vtITEM_PRECOS.vlst_ptabela,      --16
                   vnvlcustocont,                    --17
                   vnvlcustofin,                     --18
                   vnvlcustoreal,                    --19
                   vnvlcustorep,                     --20
                   vtITEM_PRECOS.basest_ptabela,     --21
                   vtITEM_PRECOS.vlipi_ptabela,       --22
                   vtITEM_PRECOS.percipi,             --23
                   vnVlDescSuframa,                   --24
                   vnperdescisentoicms,               --25
                   vnvldescicmisencao,                --26
                   'S' ,                               --27
                   vnptabela,                          --28
                   gvet_Regitempedbrinde(i).codfilialretira, --29
                   gvet_regitempedbrinde(i).codigocampanha,   --30
                   '2596',                                     --31
                   gvet_regitempedbrinde(i).usadebcredrcabrind,  --32
                   p_regproduto.qtunit,                           --33
                   gvet_regitempedbrinde(i).grpregrabrinde,  --34
                   case nvl(gregpcconsum.gerarbrindepedbonific, 'N')
                    when 'N' then 'F'
                    else null
                   end,                                  --35
                   vnstclientegnre ,                          --36
                   p_regpedido.numcar,                                         --37
                   gvet_regitempedbrinde(i).codigocampanha,   --38
                   gvet_regitempedbrinde(i).codauxiliar,      --39
                   vnptabela,                                  --40
                   vnptabela,                                  --40
                   p_regprecos.iva,
                   p_regprecos.aliqicms1,
                   p_regprecos.aliqicms2,
                   vnst,
                   vnvlipi,
                   tICMSPARTILHA.vlbasepartdest,    --45
                   tICMSPARTILHA.aliqfcp,           --46
                   tICMSPARTILHA.aliqinternadest,   --47
                   tICMSPARTILHA.vlfcppart,         --48
                   tICMSPARTILHA.vlicmspartdest,    --49
                   tICMSPARTILHA.vlicmspart,        --50
                   tICMSPARTILHA.VLICMSDIFALIQ, --51
                   tICMSPARTILHA.PERCBASERED,   --52
                   tICMSPARTILHA.percprovpart,       --53
                   tICMSPARTILHA.vlicmspartrem,     --54
                   tICMSPARTILHA.ALIQINTERESTADUAL, --55
                   vnvlcustofinest,                  --56
                   case when p_regprecos.tipocalculognre = 'P' and p_regprecos.pagtonomedocliente = 'S' then
                        'S'
                   else
                       'N'
                   end, --57
                   vtITEM_PRECOS.VLFECP, --58
                   vtITEM_PRECOS.ALIQFECP, --59
                   vtITEM_PRECOS.BaseFECP, --60
                   vtITEM_PRECOS.pauta --61
                   );

                 gvet_regitempedbrinde(i).numseq :=  vnnumseq;

                 if p_regproduto.tipomerc = 'CB' then

                    vbvalidocesta := func_inseriritemcesta( p_numped,
                                                            gvet_regitempedbrinde(i).codprod,
                                                            p_regpedido,
                                                            p_regrca,
                                                            p_regcliente,
                                                            p_regregiao,
                                                            p_regfilial,
                                                            p_regplpag.codplpag,
                                                            p_regplpag.tipovenda,
                                                           vnnumseq );

                    select sum(p.qtmp*vlcustofin),sum(p.qtmp*vlcustoreal),sum(p.qtmp*vlcustorep),sum(p.qtmp*custofinest),sum(p.qtmp*vlcustocont)
                    into vnvlcustofin,vnvlcustoreal,vnvlcustorep,vncustofinest,vnvlcustocont
                    from pcpedicesta p
                    where numped = p_Regpedido.numped
                    and   codprod =  gvet_regitempedbrinde(i).codprod
                    and   numseq  = vnnumseq;

                    update pcpedi
                    set vlcustofin = vnvlcustofin,
                        vlcustoreal = vnvlcustoreal,
                        vlcustorep = vnvlcustorep,
                        vlcustocont = vnvlcustocont,
                        custofinest  = vncustofinest
                    where numped = p_Regpedido.numped
                    and   codprod =  gvet_regitempedbrinde(i).codprod
                    and   numseq  = vnnumseq;



                 end if;


                      if p_integradora = 'S' then --só insere se o pedido está sendo feito pela integradora
                        --inserir na tabela de retorno de itens de brinde
                        insert into PCRETORNOITV5FV
                          (numpedrca,         --1
                           dtaberturapedpalm, --2
                           codusur,           --3
                           cgccli,            --4
                           codcli,            --5
                           codprod,           --6
                           codauxiliar,       --7
                           qt,                --8
                           qt_faturada,       --9
                           ptabela,           --10
                           numseq,            --11
                           codfilialretira,   --12
                           numpedtv5,         --13
                           numpedorigem       --14
                           )
                         values
                          (p_regpedido.numpedrca,         --1
                           p_regpedido.dtaberturapedpalm, --2
                           p_regpedido.codusur,           --3
                           p_cgccli,                      --4
                           p_regpedido.codcli,            --5
                           gvet_regitempedbrinde(i).codprod,           --6
                           null,                           --7
                           gvet_regitempedbrinde(i).qt,     --8
                           gvet_regitempedbrinde(i).qt,    --9
                           vnptabela,           --10
                           vnnumseq,            --11
                           gvet_regitempedbrinde(i).codfilialretira,   --12
                           null,                                       --13
                           p_regpedido.numped                          --14
                           );

                         end if;

                gvet_regitempedbrinde(i).numseq := vnnumseq;


                   if vsmensagem is null then

                       vsmensagem := 'BRINDE : '|| gvet_regitempedbrinde(i).codprod||'-'||gvet_regitempedbrinde(i).descricao ||CHR(13)||
                                      'QT : '||gvet_regitempedbrinde(i).qt;
                    else

                        vsmensagem := vsmensagem||CHR(13)||'BRINDE : '|| gvet_regitempedbrinde(i).codprod||'-'||gvet_regitempedbrinde(i).descricao ||CHR(13)||
                                      'QT : '||gvet_regitempedbrinde(i).qt ||CHR(13);
                    end if;

                  p_geroubrinde := 'S';


            else

              select count(*)
                into vicontador
                from pcpedi
               where numped = p_regpedido.numped
                 and codprod = gvet_regitempedbrinde(i).codprod
                 and codigobrinde = to_char(gvet_regitempedbrinde(i).codigocampanha)
                 and brinde = 'S';

              if vicontador = 0 then

                 T_PCPEDC.CODCLI := p_regpedido.codcli;
                 T_PCPEDC.CODFILIAL := P_REGPEDIDO.codfilial;
                 T_PCPEDC.CODFILIALNF := P_REGPEDIDO.codfilialnf;
                 T_PCPEDC.CONDVENDA := 5;
                 T_PCPEDC.CODCOB := 'BNF';


                 T_PCPEDI.PVENDA := vnptabela;
                 T_PCPEDI.CODST  := p_regprecos.CODST;
                 T_PCPEDI.CODPROD := gvet_regitempedbrinde(i).codprod;

                 FERRAMENTAS.DEFINIRCODFISCAL(T_PCPEDC, T_PCPEDI, VNCODFISCAL, VNSITTRIBUT, vsmensagemcodfiscal);
                 vsmensagem := vsmensagem || ' ' ||  vsmensagemcodfiscal;

                -- Preço de tabela
                vtITEM_PRECOS.pvenda   := round(vnptabela, gregpcconsum.numcasasdecvenda);
                vtITEM_PRECOS.ptabela  := round(vnptabela, gregpcconsum.numcasasdecvenda);
                vtITEM_PRECOS.pbaserca := round(vnptabela, gregpcconsum.numcasasdecvenda);

                -- ST de tabela
                vnst := p_regprecos.vlst;

                -- Calcula Preço sem Imposto
                SELECT round(VALORSEMIMPOSTO,gregpcconsum.numcasasdecvenda), MSG
                  INTO vtITEM_PRECOS.ptabela_semimpostos, vsMSGPartilha
                FROM TABLE(PKG_TRIBUTACAO.CALCULAR_PVENDA_SEM_IMPOSTO(p_regpedido.codfilial,
                                                                      p_regpedido.codfilialnf,
                                                                      gvet_Regitempedbrinde(i).codfilialretira,
                                                                      p_regpedido.codcli,
                                                                      p_regpedido.codplpag,
                                                                      gvet_regitempedbrinde(i).codprod,
                                                                      gvet_regitempedbrinde(i).codauxiliar,
                                                                      p_regpedido.condvenda,
                                                                      'N',
                                                                      vnst, --1,
                                                                      0,
                                                                      ROUND(vtITEM_PRECOS.ptabela, gregpcconsum.numcasasdecvenda),
                                                                      'S',
                                                                      'S',
                                                                      'N',
                                                                      '',--0,
                                                                      NULL,
                                                                      'N',
                                                                      'N',
                                                                      'N',
                                                                      'N',
                                                                      0,
                                                                      'N',
                                                                      'I'));

                -- Calcula ICMS Partilha
                pkg_fwpc_fiscal.icmspartilha_calcular_1_4(nvl(p_regpedido.codfilialnf,p_regpedido.codfilial),
                                                         p_regpedido.codcli,
                                                         '',
                                                         vsufEnt,
                                                         p_regpedido.data,
                                                         vtITEM_PRECOS.ptabela_semimpostos,
                                                         p_regprecos.codst,
                                                         gvet_regitempedbrinde(i).codprod,
                                                         VNCODFISCAL,--CFOP
                                                         VNSITTRIBUT,--CST
                                                         tICMSPARTILHA,
                                                         vnCodMSGPartilha,
                                                         vsMSGPartilha);

               -- Agrega o ICMS Partilha no preço
               vtITEM_PRECOS.ptabela_semimpostos := vtITEM_PRECOS.ptabela_semimpostos + nvl(tICMSPARTILHA.VLICMSPART,0);

                vncodbnf := null;
                select count(*) into vnQtPadrao from pctipobonific where bonifpadrao = 'S';
                if vnQtPadrao > 0 then
                   SELECT pctipobonific.codbnf into vncodbnf FROM pctipobonific
                       WHERE pctipobonific.bonifpadrao = 'S' and rownum = '1';
                end if;

               -- Calcula o valor de IPI
               SELECT VALORIPI, PERCENTUAL_IPI
                 INTO vtITEM_PRECOS.vlipi_ptabela, vtITEM_PRECOS.percipi
                 FROM TABLE(PKG_TRIBUTACAO.CALCULAR_IPI(p_regpedido.codfilial,
                                                        p_regpedido.codfilialnf,
                                                        gvet_regitempedbrinde(i).codfilialretira,
                                                        p_regpedido.codcli,
                                                        gvet_regitempedbrinde(i).codprod,
                                                        gvet_regitempedbrinde(i).codauxiliar,
                                                        p_regpedido.condvenda,
                                                        'N',
                                                        vtITEM_PRECOS.ptabela_semimpostos,
                                                        'N',
                                                        'F',
                                                        vtITEM_PRECOS.ptabela_semimpostos,
                                                        '',
                                                        vncodbnf,
                                                        'I'));

                -- Calcula ST e FECP
                SELECT BASEST,
                       ST,
                       VLRFECP,
                       BASEFECP,
                       ALIQFECP,
                       PAUTA,
                       IVA,
                       ALIQICMS1,
                       ALIQICMS2
                  INTO vtITEM_PRECOS.basest_ptabela,
                       vtITEM_PRECOS.vlst_ptabela,
                       vtITEM_PRECOS.VLFECP,
                       vtITEM_PRECOS.BaseFECP,
                       vtITEM_PRECOS.ALIQFECP,
                       vtITEM_PRECOS.pauta,
                       p_regprecos.iva,
                       p_regprecos.aliqicms1,
                       p_regprecos.aliqicms2
                FROM TABLE(PKG_TRIBUTACAO.CALCULAR_ST(p_regpedido.codfilial,
                                                      p_regpedido.codfilialnf,
                                                      gvet_regitempedbrinde(i).codfilialretira,
                                                      p_regpedido.codcli,
                                                      p_regpedido.codplpag,
                                                      gvet_regitempedbrinde(i).codprod,
                                                      gvet_regitempedbrinde(i).codauxiliar,
                                                      p_regpedido.condvenda,
                                                      'N',
                                                      vtITEM_PRECOS.ptabela_semimpostos,
                                                      0));

                -- Calcula o preço final
                IF p_regprecos.tipocalculognre <> 'C' THEN
                   vnptabela := vtITEM_PRECOS.ptabela_semimpostos + vtITEM_PRECOS.vlipi_ptabela + vtITEM_PRECOS.vlst_ptabela + vtITEM_PRECOS.VLFECP;
                   vnst := vtITEM_PRECOS.vlst_ptabela;
                ELSE
                   vnptabela := vtITEM_PRECOS.ptabela_semimpostos + vtITEM_PRECOS.vlipi_ptabela;
                   vnst := 0;
                END IF;

                -- buscar custos do item
                vnvlcustocont   := p_regprecos.custocont;
                vnvlcustorep    := p_regprecos.custorep;
                vnvlcustofinest := p_regprecos.custofin;
                vnvlcustofin  := (p_regprecos.custofin -
                                 (p_regprecos.custofin *
                                 p_regprecos.perdesccusto / 100) +
                                 (vnptabela * nvl(gregpcconsum.txvenda, 0) / 100)
                                 --              + (p_regitem.pvenda * p_regitem.percom / 100)
                                 + ((vtITEM_PRECOS.ptabela_semimpostos - nvl(tICMSPARTILHA.VLICMSPART,0)) * p_regprecos.codicmtab / 100) + vtITEM_PRECOS.vlipi_ptabela + vtITEM_PRECOS.vlst_ptabela + vtITEM_PRECOS.VLFECP + nvl(tICMSPARTILHA.VLICMSPART,0));
                vnvlcustoreal := (p_regprecos.custoreal -
                                 (p_regprecos.custoreal *
                                 p_regprecos.perdesccusto / 100) +
                                 (vnptabela * nvl(gregpcconsum.txvenda, 0) / 100)
                                 --              + (p_regitem.pvenda * p_regitem.percom / 100)
                                 + ((vtITEM_PRECOS.ptabela_semimpostos - nvl(tICMSPARTILHA.VLICMSPART,0)) * p_regprecos.codicmtab / 100) + vtITEM_PRECOS.vlipi_ptabela + vtITEM_PRECOS.vlst_ptabela + vtITEM_PRECOS.VLFECP + nvl(tICMSPARTILHA.VLICMSPART,0));


                 insert into pcpedi
                  (codcli,     --1
                   codicmtab,  --2
                   codprod,    --3
                   codst,      --4
                   codusur,    --5
                   data,       --6
                   numped,     --7
                   numseq,     --8
                   percom,     --9
                   perdesc,    --10
                   posicao,    --11
                   ptabela,    --12
                   pvenda,     --13
                   qt,         --14
                   qtfalta,    --15
                   st,         --16
                   vlcustocont,  --17
                   vlcustofin,   --18
                   vlcustoreal,  --19
                   vlcustorep,   --20
                   baseicst,     --21
                   vlipi,        --22
                   percipi,      --23
                   vldescsuframa,  --24
                   perdescisentoicms, --25
                   vldescicmisencao,   --26
                   brinde  ,           --27
                   pbaserca,            --28
                   codfilialretira,      --29
                   codigobrinde,           --30
                   rotinalanc,             --31
                   usadebcredrcabrind,     --32
                   qtunitemb,               --33
                   grpregrabrinde,             --34
                   bonific,                    --35
                   stclientegnre,               --36
                   numcar,                     --37
                   codpromocao,                --38
                   codauxiliar,                --39
                   pbonific,                    --40
                   vlbonific,
                   iva,
                   aliqicms1,
                   aliqicms2,
                   stptabela,
                   vlipiptabela,
                   vlbasepartdest,    --45
                   aliqfcp,           --46
                   aliqinternadest,   --47
                   vlfcppart,         --48
                   vlicmspartdest,    --49
                   vlicmspart,        --50
                   VLICMSDIFALIQPART, --51
                   PERCBASEREDPART,   --52
                   PERCPROVPART,       --53
                   VLICMSPARTREM,     --54
                   ALIQINTERORIGPART, --55
                   custofinest,        --56
                   geragnre_cnpjcliente, --57
                   vlfecp,               --58
                   aliqicmsfecp,         --59
                   vlbasefcpst,           --60
                   pauta                  --61
                   )
                values
                  (p_regpedido.codcli,          --1
                   p_regprecos.codicmtab,       --2
                   gvet_regitempedbrinde(i).codprod, --3
                   p_regprecos.codst,              --4
                   p_regpedido.codusur,            --5
                   trunc(sysdate),                 --6
                   p_regpedido.numped,               --7
                   vnnumseq,                        --8
                   0,                               --9
                   0,                               --10
                   p_regpedido.posicao,             --11
                   vnptabela,                       --12
                   vnptabela,                       --13
                   gvet_regitempedbrinde(i).qt,     --14
                   0,                               --15
                   vtITEM_PRECOS.vlst_ptabela,      --16
                   vnvlcustocont,                    --17
                   vnvlcustofin,                     --18
                   vnvlcustoreal,                    --19
                   vnvlcustorep,                     --20
                   vtITEM_PRECOS.basest_ptabela,     --21
                   vtITEM_PRECOS.vlipi_ptabela,       --22
                   vtITEM_PRECOS.percipi,             --23
                   vnVlDescSuframa,                   --24
                   vnperdescisentoicms,               --25
                   vnvldescicmisencao,                --26
                   'S' ,                               --27
                   vnptabela,                          --28
                   gvet_Regitempedbrinde(i).codfilialretira, --29
                   gvet_regitempedbrinde(i).codigocampanha,   --30
                   '2596',                                     --31
                   gvet_regitempedbrinde(i).usadebcredrcabrind,  --32
                   p_regproduto.qtunit,                           --33
                   gvet_regitempedbrinde(i).grpregrabrinde,  --34
                   case nvl(gregpcconsum.gerarbrindepedbonific, 'N')
                    when 'N' then 'F'
                    else null
                   end,                                  --35
                   vnstclientegnre ,                          --36
                   p_regpedido.numcar,                                         --37
                   gvet_regitempedbrinde(i).codigocampanha,   --38
                   gvet_regitempedbrinde(i).codauxiliar,      --39
                   vnptabela,                                  --40
                   vnptabela,                                  --40
                   p_regprecos.iva,
                   p_regprecos.aliqicms1,
                   p_regprecos.aliqicms2,
                   vnst,
                   vnvlipi,
                   tICMSPARTILHA.vlbasepartdest,    --45
                   tICMSPARTILHA.aliqfcp,           --46
                   tICMSPARTILHA.aliqinternadest,   --47
                   tICMSPARTILHA.vlfcppart,         --48
                   tICMSPARTILHA.vlicmspartdest,    --49
                   tICMSPARTILHA.vlicmspart,        --50
                   tICMSPARTILHA.VLICMSDIFALIQ, --51
                   tICMSPARTILHA.PERCBASERED,   --52
                   tICMSPARTILHA.percprovpart,       --53
                   tICMSPARTILHA.vlicmspartrem,     --54
                   tICMSPARTILHA.ALIQINTERESTADUAL, --55
                   vnvlcustofinest,                  --56
                   case when p_regprecos.tipocalculognre = 'P' and p_regprecos.pagtonomedocliente = 'S' then
                        'S'
                   else
                       'N'
                   end, --57
                   vtITEM_PRECOS.VLFECP, --58
                   vtITEM_PRECOS.ALIQFECP, --59
                   vtITEM_PRECOS.BaseFECP, --60
                   vtITEM_PRECOS.pauta --61
                   );

                 gvet_regitempedbrinde(i).numseq :=  vnnumseq;

                 if p_regproduto.tipomerc = 'CB' then

                    vbvalidocesta := func_inseriritemcesta( p_numped,
                                                            gvet_regitempedbrinde(i).codprod,
                                                            p_regpedido,
                                                            p_regrca,
                                                            p_regcliente,
                                                            p_regregiao,
                                                            p_regfilial,
                                                            p_regplpag.codplpag,
                                                            p_regplpag.tipovenda,
                                                           vnnumseq );

                    select sum(p.qtmp*vlcustofin),sum(p.qtmp*vlcustoreal),sum(p.qtmp*vlcustorep),sum(p.qtmp*custofinest),sum(p.qtmp*vlcustocont)
                    into vnvlcustofin,vnvlcustoreal,vnvlcustorep,vncustofinest,vnvlcustocont
                    from pcpedicesta p
                    where numped = p_Regpedido.numped
                    and   codprod =  gvet_regitempedbrinde(i).codprod
                    and   numseq  = vnnumseq;

                    update pcpedi
                    set vlcustofin = vnvlcustofin,
                        vlcustoreal = vnvlcustoreal,
                        vlcustorep = vnvlcustorep,
                        vlcustocont = vnvlcustocont,
                        custofinest  = vncustofinest
                    where numped = p_Regpedido.numped
                    and   codprod =  gvet_regitempedbrinde(i).codprod
                    and   numseq  = vnnumseq;



                 end if;

                      if p_integradora = 'S' then --só insere se o pedido está sendo feito pela integradora
                        --inserir na tabela de retorno de itens de brinde
                        insert into PCRETORNOITV5FV
                          (numpedrca,         --1
                           dtaberturapedpalm, --2
                           codusur,           --3
                           cgccli,            --4
                           codcli,            --5
                           codprod,           --6
                           codauxiliar,       --7
                           qt,                --8
                           qt_faturada,       --9
                           ptabela,           --10
                           numseq,            --11
                           codfilialretira ,  --12
                           numpedtv5,         --13
                           numpedorigem       --14
                           )
                         values
                          (p_regpedido.numpedrca,         --1
                           p_regpedido.dtaberturapedpalm, --2
                           p_regpedido.codusur,           --3
                           p_cgccli,                      --4
                           p_regpedido.codcli,            --5
                           gvet_regitempedbrinde(i).codprod,           --6
                           null,                           --7
                           gvet_regitempedbrinde(i).qt,     --8
                           gvet_regitempedbrinde(i).qt,    --9
                           vnptabela,           --10
                           vnnumseq,            --11
                           gvet_regitempedbrinde(i).codfilialretira,   --12
                           null,                                       --13
                           p_regpedido.numped                          --14
                           );

                         end if;

                       gvet_regitempedbrinde(i).numseq := vnnumseq;

              else

                update pcpedi
                   set qt = qt + gvet_regitempedbrinde(i).qt
                 where codprod = gvet_regitempedbrinde(i).codprod
                   and numped = p_regpedido.numped;

                select max(numseq), max(posicao)
                  into gvet_regitempedbrinde(i).numseq, vsposicao
                  from pcpedi
                 where numped = p_regpedido.numped
                   and codprod = gvet_regitempedbrinde(i).codprod;


                   if p_integradora = 'S' then --só altera se o pedido está sendo feito pela integradora
                        --alterar a qt na tabela de retorno de itens de brinde
                       update PCRETORNOITV5FV
                       set qt = qt + gvet_regitempedbrinde(i).qt
                       where numpedrca = p_regpedido.numpedrca
                       and   codusur   = p_regpedido.codusur
                       and   cgccli    = p_cgccli
                       and   dtaberturapedpalm = p_regpedido.dtaberturapedpalm
                       and   codprod   = gvet_regitempedbrinde(i).codprod;
                   end if;

              end if;

                   if vsmensagem is null then

                       vsmensagem := 'BRINDE : '|| gvet_regitempedbrinde(i).codprod||'-'||gvet_regitempedbrinde(i).descricao ||CHR(13)||
                                      'QT : '||gvet_regitempedbrinde(i).qt ;
                    else

                        vsmensagem := vsmensagem||CHR(13)||'BRINDE : '|| gvet_regitempedbrinde(i).codprod||'-'||gvet_regitempedbrinde(i).descricao ||CHR(13)||
                                      'QT : '||gvet_regitempedbrinde(i).qt ||CHR(13);
                    end if;


                   p_geroubrinde := 'S';



              end if;
            end if;
          else

                   if vsmensagem is null then

                       vsmensagem := 'Brinde sem estoque disponivel : '|| gvet_regitempedbrinde(i).codprod||'-'||gvet_regitempedbrinde(i).descricao ;
                    else

                        vsmensagem := vsmensagem||CHR(13)||'Brinde sem estoque disponivel : '|| gvet_regitempedbrinde(i).codprod||'-'||gvet_regitempedbrinde(i).descricao ||CHR(13);
                    end if;


          end if;
          end if;
          end if;
         end if;

        end loop;


         if p_integradora = 'S' then --só insere se o pedido está sendo feito pela integradora
                 --inserir na tabela de retorno de pedido de brinde
                 insert into PCRETORNOCTV5FV
                 (numpedrca,          --1
                  dtaberturapedpalm,  --2
                  codusur,            --3
                  cgccli,             --4
                  codcli,             --5
                  numpedorigem,       --6
                  numpedtv5,          --7
                  retorno,            --8
                  posicao_Atual,      --9
                  codfilial,          --10
                  codfilialnf,        --11
                  codfilialretira,    --12
                  dtentrega,          --13
                  gerarbrindepedbonific  --14
                  )
                 values
                  (p_regpedido.numpedrca,          --1
                   p_regpedido.dtaberturapedpalm,  --2
                   p_regpedido.codusur,            --3
                   p_cgccli,                       --4
                   p_regpedido.codcli,             --5
                   p_regpedido.numped,             --6
                   null,                           --7
                   2,                              --8
                   p_Regpedido.posicaoini,            --9
                   p_regpedido.codfilial,          --10
                   p_regpedido.codfilialnf,        --11
                   p_codfilialretira,              --12
                   p_regpedido.dtentrega,          --13
                   'N'                             --14
                   );
                end if;

               BEGIN
                 SELECT NVL(SUM(PVENDA * QT),0)
                   INTO VTOTALBONIFIC
                   FROM PCPEDI
                  WHERE NUMPED = p_regpedido.numped
                    AND BONIFIC <> 'N';

                  UPDATE PCPEDC SET VLBONIFIC = VTOTALBONIFIC WHERE NUMPED =  p_regpedido.numped;
               EXCEPTION
                 WHEN OTHERS THEN
                   if vsmensagem is null then

                     vsmensagem := ' ERRO AO ATUALIZAR VLBONIFIC DO PEDIDO ';
                   else

                     vsmensagem := vsmensagem ||
                                   ' ERRO AO ATUALIZAR VLBONIFIC DO PEDIDO ';
                   end if;
               END;

      end if;
    end if;

    -- 2970.026789.2018
    SELECT COUNT(PCPEDI.CODPROD) CONTACODPROD --PCPEDI.QT, PEDTV1.QTDISP_QTTV1
      into vnCONTACODPRODSEMEST
      FROM PCPEDI,
           PCPEDC,
           (SELECT PCPEDI.CODPROD,
                   (SELECT QTDISP

                      FROM TABLE(VENDAS.ESTOQUE_DISPONIVEL(PCPEDI.CODPROD,
                                                           NVL(PCPEDI.CODFILIALRETIRA,
                                                               PCPEDC.CODFILIAL)))) - PCPEDI.QT QTDISP_QTTV1
              FROM PCPEDI, PCPEDC
             WHERE PCPEDC.NUMPED = PCPEDI.NUMPED
               AND PCPEDI.NUMPED = p_numped) PEDTV1
     WHERE PCPEDC.NUMPED = PCPEDI.NUMPED
       AND PCPEDI.CODPROD = PEDTV1.CODPROD
       AND PCPEDI.NUMPED = vnproxnumped
       AND PEDTV1.QTDISP_QTTV1 - PCPEDI.QT <= 0;

    if vnCONTACODPRODSEMEST > 0 then
      vsposicao := 'P';

      UPDATE PCPEDI SET POSICAO = vsposicao WHERE NUMPED = vnproxnumped;
      UPDATE PCPEDC SET POSICAO = vsposicao WHERE NUMPED = vnproxnumped;
    END IF;

    if (vbvalido) and nvl(vnproxnumped, 0) = 0 and nvl(vsauxpedido, 0) = 0 and
       vnnumitensbonific > 0 then
      for i in 1 .. vnnumitensbonific loop
        if vsposicao in('L','M') then
          vs_movest := pkg_estoque.RESERVA_INCLUIR(nvl(vnproxnumped,
                                                       p_regpedido.numped),
                                                   gvet_regitempedbrinde(i)
                                                   .codprod,
                                                   gvet_regitempedbrinde(i)
                                                   .numseq,
                                                   true,
                                                   null,
                                                   msgest);
        else
          vs_movest := pkg_estoque.PENDENTE_INCLUIR(nvl(vnproxnumped,
                                                        p_regpedido.numped),
                                                    gvet_regitempedbrinde(i)
                                                    .codprod,
                                                    gvet_regitempedbrinde(i)
                                                    .numseq,
                                                    true,
                                                    null,
                                                    msgest);
        end if;

        IF vs_movest = 'N' THEN
          vsmensagem := vsmensagem || 'ERRO AO ATUALIZAR ESTOQUE.' ||
                        CHR(13) || msgest;
        END IF;
      end loop;
    end if;

    if (vbvalido) and ((nvl(vnproxnumped, 0) <> 0) or (nvl(vsauxpedido, 0) <> 0)) then
      begin
        for dados in (select codprod, numseq, numped
                        from pcpedi
                       where numped in (vnproxnumped, vsauxpedido)
                       order by numped, numseq) loop
          if vsposicao in('L','M') then
            vs_movest := pkg_estoque.RESERVA_INCLUIR(dados.numped,
                                                     dados.codprod,
                                                     dados.numseq,
                                                     true,
                                                     null,
                                                     msgest);
          else
            vs_movest := pkg_estoque.PENDENTE_INCLUIR(dados.numped,
                                                      dados.codprod,
                                                      dados.numseq,
                                                      true,
                                                      null,
                                                      msgest);
          end if;

          IF vs_movest = 'N' THEN
            vsmensagem := vsmensagem || 'ERRO AO ATUALIZAR ESTOQUE.' ||
                          CHR(13) || msgest;
          END IF;
        end loop;
      end;
    end if;

    p_mensagem := substr(vsmensagem,1,3000);

   EXCEPTION
    WHEN erro_PROXNUMPEDZERADO THEN
      p_mensagem := 'ERRO AO GERAR BRINDE - Não foi possível obter número do pedido de! brinde, verifique se a tabela PCUSUARI não esta lockada';

  end proc_apurarcampanha;

  function func_calcularimpostos
  ( p_numped     in pcpedc.numped%type,
    p_codprod    in pcpedi.codprod%type,
    p_regpedido  in t_pedido,
    p_regrca     in t_rca,
    p_regcliente in t_cliente,
    p_regregiao  in t_regiao,
    p_regfilial  in t_filial,
    p_codplpag   in pcplpag.codplpag%type,
    p_tipovenda  in pcplpag.tipovenda%type,
    p_numseq     in number

  ) return boolean is
  begin



  return true;
  end func_calcularimpostos;

end; -- Apurarcampanhasbrindes

