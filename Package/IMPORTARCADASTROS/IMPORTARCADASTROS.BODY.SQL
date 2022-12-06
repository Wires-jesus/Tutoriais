create or replace package body IMPORTARCADASTROS is

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

procedure proc_alterarImportado(p_importado    in pcclientfv.importado%type,
                                dtinclusao     in pcclientfv.dtinclusao%type,
                                codusur1       in pcclientfv.codusur1%type,
                                vddatainicial  in date,
                                vddatafinal    in date) is
 PRAGMA autonomous_transaction;
  begin

     update pcclientfv set importado = 4 where importado = p_importado
                                         AND (NVL(trunc(dtinclusao),trunc(sysdate)) BETWEEN vddatainicial AND vddatafinal)
                                         AND (codusur1 = codusur1 or codusur1 is null)
                                         AND (importado <> 4);
 commit;

 end proc_alterarImportado;

procedure proc_destravarcliente(chave        in varchar2) is
 PRAGMA autonomous_transaction;
  begin

     update pcclientfv set importado = 3 where importado = 4 and rowid = chave;
     commit;

  end proc_destravarcliente;

FUNCTION F_PROX_CODCLI
  RETURN NUMBER
  IS
  /************************************************************************************************************
  ->Nome da FUNCTION  : F_PROX_CODCLI
  ->Objetivo          : Buscar o próximo código cliente em transação autônoma(separada).
  ->Utilizado por     : IMPORTARCADASTRO

  -------------------------------- Historico ------------------------------------------------------------------
  Data          Responsavel       Tarefa  Comentarios
  ------------  ---------------   ------  ----------------------------------------------------------------------
  18/10/2017    Rodrigo Santos            Criada nova função F_PROX_CODCLI.
  ------------  ---------------   ---------------------------------------------------------------------------*/
  PRAGMA AUTONOMOUS_TRANSACTION;
  vnproxnumcli  NUMBER;
  BEGIN

    select NVL(pcconsum.proxnumcli, 1)
      into vnproxnumcli
      from pcconsum
       for update;

    update pcconsum set proxnumcli = NVL(pcconsum.proxnumcli, 0) + 1;

    COMMIT;

    RETURN vnproxnumcli;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END F_PROX_CODCLI;

PROCEDURE F_PROX_CODCLIPALM(Codusur in pcusuari.codusur%type, codclipalm  in pcusuari.proxcodclipalm%type)

  IS
  /************************************************************************************************************
  ->Nome da FUNCTION  : F_PROX_CODCLI
  ->Objetivo          : Buscar o próximo código cliente em transação autônoma(separada).
  ->Utilizado por     : IMPORTARCADASTRO

  -------------------------------- Historico ------------------------------------------------------------------
  Data          Responsavel       Tarefa  Comentarios
  ------------  ---------------   ------  ----------------------------------------------------------------------
  18/10/2017    Rodrigo Santos            Criada nova função F_PROX_CODCLI.
  ------------  ---------------   ---------------------------------------------------------------------------*/
  PRAGMA AUTONOMOUS_TRANSACTION;
  vnproxnumcli     NUMBER;
  v_proxcodclipalm NUMBER;

  BEGIN
    SELECT NVL(codclipalm, proxcodclipalm)
      INTO v_proxcodclipalm
      FROM pcusuari
     WHERE codusur = Codusur
      FOR UPDATE;

   UPDATE pcusuari
      SET proxcodclipalm = NVL(codclipalm, proxcodclipalm) + 1
    WHERE codusur = Codusur;

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      null;
  END F_PROX_CODCLIPALM;

procedure proc_registralog(p_numped        in pcpedc.numped%type,
                             p_numpedrca     in pcpedc.numpedrca%type,
                             p_codprod       in pcprodut.codprod%type,
                             p_codauxiliar   in pcpedi.codauxiliar%type,
                             p_cgcent        in pcclient.cgcent%type,
                             p_codigocotacao in pccota.codcotacao%type,
                             p_numrecadofv   in pcrecfunc.numrecadofv%type,
                             p_numcontagem   in pcgondolac.numcontagem%type,
                             p_codusur       in pcpedc.codusur%type,
                             p_data          in date,
                             p_cancelada     in varchar2,
                             p_tiporeg       in varchar2,
                            -- 1 = generico / -1 = Clientes /2 = cabecalho / 3 = itens /4 = Contatos
                             p_erro     in varchar2,
                             p_linhareg in number) is
  begin
    vngcontador := vngcontador + 1;
    gvetregistralog(vngcontador).numped        := p_numped;
    gvetregistralog(vngcontador).numpedrca     := p_numpedrca;
    gvetregistralog(vngcontador).codprod       := p_codprod;
    gvetregistralog(vngcontador).codauxiliar   := p_codauxiliar;
    gvetregistralog(vngcontador).cgcent        := p_cgcent;
    gvetregistralog(vngcontador).codigocotacao := p_codigocotacao;
    gvetregistralog(vngcontador).numrecadofv   := p_numrecadofv;
    gvetregistralog(vngcontador).numcontagem   := p_numcontagem;
    gvetregistralog(vngcontador).codusur       := p_codusur;
    gvetregistralog(vngcontador).data          := p_data;
    gvetregistralog(vngcontador).cancelada     := p_cancelada;
    gvetregistralog(vngcontador).tiporeg       := p_tiporeg;
    gvetregistralog(vngcontador).erro          := p_erro;
    gvetregistralog(vngcontador).linhareg      := p_linhareg;

  end proc_registralog;

  procedure proc_lerparametros(p_existerro in out boolean) is
    vsdirimportacaofv pcconsum.dirimportacaofv%type;
  begin
    select * into gregpcconsum from pcconsum;
    gregpcconsum.codfilialfv      := NVL(gregpcconsum.codfilialfv, '1');
    gregpcconsum.numcasasdecvenda := NVL(gregpcconsum.numcasasdecvenda, 2);


  exception
    when others then
      p_existerro := true;
      proc_registralog(null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       '1',
                       'Erro ao ler parametros#;' || sqlcode || '-' ||
                       sqlerrm || ';',
                       null);
  end proc_lerparametros;


PROCEDURE proc_processarleitura(p_existerro   IN OUT BOOLEAN,
                                p_tipoleitura IN NUMBER,
                                p_datainicial IN DATE,
                                p_datafinal   IN DATE,
                                p_tiporeg     IN NUMBER,
                                p_codusur     IN NUMBER) IS
    vblercliok        boolean;
    vblercontatook    boolean;
    vblermensok       boolean;
    vblergondolacok   boolean;
    vblergondolaiok   boolean;
    vblervisitaok     boolean;
    vblercotacaook    boolean;
    vblerclirefok     boolean;
    vncontcli         integer;
    vncontcontato     integer;
    vncontgondolac    integer;
    vncontgondolai    integer;
    vncontvisita      integer;
    vncontcotacao     integer;
    vncontcliref      integer;
    vncontmens        integer;

    vddatainicial     date;
    vddatafinal       date;

  BEGIN
    /*
       Campo IMPORTADO:
       Valor 0 = registro bloqueado.
       Valor 1 = registro liberado para leitura.
       Valor 2 = registro lido.
       Valor 3 = registro liberado para leitura novamente (rejeitado anteriormente).
    */

    -- Ajusta a faixa de datas conforme parametro.
    IF p_tipoleitura = 1
    THEN
      vddatainicial := TRUNC(SYSDATE) - 365;
      vddatafinal   := TRUNC(SYSDATE);
    ELSE
      vddatainicial := p_datainicial;
      vddatafinal   := p_datafinal;
    END IF;

    vncontcli         := 0;
    vncontcontato     := 0;
    vncontgondolac    := 0;
    vncontgondolai    := 0;
    vncontvisita      := 0;
    vncontcotacao     := 0;
    vncontcliref      := 0;
    vncontmens        := 0;

    vngdatainicio     := vddatainicial;
    vngdatafim        := vddatafinal;




  -- clientes
  if p_tiporeg is null or p_tiporeg = 1 then

  FOR cr_cli in (SELECT   cgcent,
                        cliente,
                        fantasia,
                        ieent,
                        iment,
                        rg,
                        orgaorg,
                        codclipalm,
                        codatv1,
                        enderent,
                        numeroent,
                        complementoent,
                        bairroent,
                        telent,
                        municent,
                        estent,
                        cepent,
                        paisent,
                        pontorefer,
                        endercob,
                        numerocob,
                        complementocob,
                        bairrocob,
                        telcob,
                        municcob,
                        estcob,
                        cepcob,
                        endercom,
                        numerocom,
                        complementocom,
                        bairrocom,
                        telcom,
                        municcom,
                        estcom,
                        cepcom,
                        faxcom,
                        codusur1,
                        codusur2,
                        faxcli,
                        codpraca,
                        predioproprio,
                        obs,
                        obs2,
                        obs3,
                        obs4,
                        obs5,
                        obscredito,
                        telent1,
                        email,
                        caixapostal,
                        obsentrega1,
                        obsentrega2,
                        obsentrega3,
                        obsentrega4,
                        numbanco1,
                        numagencia1,
                        numccorrente1,
                        numbanco2,
                        numagencia2,
                        numccorrente2,
                        qtcheckout,
                        site,
                        obsgerencial1,
                        obsgerencial2,
                        obsgerencial3,
                        latitude,
                        longitude,
                        datacoleta,
                        tipooperacao,
                        codcli,
                        codcob,
                        codplpag,
                        emailnfe,
                        codcidadeibge,
                        codfilialnf,
                        consumidorfinal,
                        contribuinte,
                        clientprotesto,
                        envionfemailcom,
                        diasemana,
                        numsemana,
                        sequencia,
                        periodicidade,
                        simplesnacional,
                        codpais,
                        fretedespacho,
                        telcelent, --HIS.03111.2017
                        rownum linha,
                        calculast,
                        clientefontest,
                        rowid chave,
                        dtinclusao,
                        importado,
                        dtnasc,
						cgcentrega
                      from pcclientfv
                       WHERE (importado = p_tipoleitura)
                         AND (NVL(trunc(dtinclusao),trunc(sysdate)) BETWEEN vddatainicial AND vddatafinal)
                         AND (codusur1 = p_codusur or p_codusur is null)
                         AND (importado <> 4)
                         AND (importado <> 2)
                         )loop

   begin
      INSERT INTO pclogfv
        (arquivo, codcli, DATA, motivo, numped, numpedcli, numpedrca, status)
          VALUES
          ('PCCLIENTFV',
          cr_cli.codcli,
          SYSDATE,
          'Chamou a proc_alterarImportado do cliente',
          NULL,
          NULL,
          NULL,
          'N');

      proc_alterarImportado(cr_cli.importado,
                             cr_cli.dtinclusao,
                             p_codusur,
                             vddatainicial,
                             vddatafinal);
      INSERT INTO pclogfv
        (arquivo, codcli, DATA, motivo, numped, numpedcli, numpedrca, status)
          VALUES
          ('PCCLIENTFV',
          cr_cli.codcli,
          SYSDATE,
          'Passou na proc_alterarImportado',
          NULL,
          NULL,
          NULL,
          'N');

      vblercliok := false;

      gregcli.tipooperacao                  := upper(cr_cli.tipooperacao);
      gregcli.cgcent                        := cr_cli.cgcent;
      gregcli.cliente                       := cr_cli.cliente;
      gregcli.fantasia                      := cr_cli.fantasia;
      gregcli.ieent                         := upper(trim(cr_cli.ieent));
      gregcli.iment                         := cr_cli.iment;
      gregcli.rg                            := cr_cli.rg;
      gregcli.orgaorg                       := cr_cli.orgaorg;
      gregcli.codclipalm                    := cr_cli.codclipalm;
      gregcli.codatv1                       := cr_cli.codatv1;
      gregcli.enderent                      := cr_cli.endercom;
      gregcli.numeroent                     := cr_cli.numerocom;
      gregcli.complementoent                := cr_cli.complementocom;
      gregcli.bairroent                     := cr_cli.bairrocom;
      gregcli.telent                        := cr_cli.telcom;
      gregcli.municent                      := cr_cli.municcom;
      gregcli.estent                        := cr_cli.estcom;
      gregcli.cepent                        := cr_cli.cepcom;
      gregcli.paisent                       := cr_cli.paisent;
      gregcli.pontorefer                    := cr_cli.pontorefer;
      gregcli.endercob                      := cr_cli.endercob;
      gregcli.numerocob                     := cr_cli.numerocob;
      gregcli.complementocob                := cr_cli.complementocob;
      gregcli.bairrocob                     := cr_cli.bairrocob;
      gregcli.telcob                        := cr_cli.telcob;
      gregcli.municcob                      := cr_cli.municcob;
      gregcli.estcob                        := cr_cli.estcob;
      gregcli.cepcob                        := cr_cli.cepcob;
      gregcli.endercom                      := cr_cli.enderent;
      gregcli.numerocom                     := cr_cli.numeroent;
      gregcli.complementocom                := cr_cli.complementoent;
      gregcli.bairrocom                     := cr_cli.bairroent;
      gregcli.telcom                        := cr_cli.telent;
      gregcli.municcom                      := cr_cli.municent;
      gregcli.estcom                        := cr_cli.estent;
      gregcli.cepcom                        := cr_cli.cepent;
      gregcli.faxcom                        := cr_cli.faxcom;
      gregcli.codusur1                      := cr_cli.codusur1;
      gregcli.codusur2                      := cr_cli.codusur2;
      gregcli.faxcli                        := cr_cli.faxcli;
      gregcli.codpraca                      := cr_cli.codpraca;
      gregcli.predioproprio                 := cr_cli.predioproprio;
      gregcli.obs                           := cr_cli.obs;
      gregcli.obs2                          := cr_cli.obs2;
      gregcli.obs3                          := cr_cli.obs3;
      gregcli.obs4                          := cr_cli.obs4;
      gregcli.obs5                          := cr_cli.obs5;
      gregcli.obscredito                    := cr_cli.obscredito;
      gregcli.telent1                       := cr_cli.telent1;
      gregcli.email                         := lower(cr_cli.email);
      gregcli.caixapostal                   := cr_cli.caixapostal;
      gregcli.obsentrega1                   := cr_cli.obsentrega1;
      gregcli.obsentrega2                   := cr_cli.obsentrega2;
      gregcli.obsentrega3                   := cr_cli.obsentrega3;
      gregcli.obsentrega4                   := cr_cli.obsentrega4;
      gregcli.numbanco1                     := cr_cli.numbanco1;
      gregcli.numagencia1                   := cr_cli.numagencia1;
      gregcli.numccorrente1                 := cr_cli.numccorrente1;
      gregcli.numbanco2                     := cr_cli.numbanco2;
      gregcli.numagencia2                   := cr_cli.numagencia2;
      gregcli.numccorrente2                 := cr_cli.numccorrente2;
      gregcli.qtcheckout                    := cr_cli.qtcheckout;
      gregcli.site                          := cr_cli.site;
      gregcli.obsgerencial1                 := cr_cli.obsgerencial1;
      gregcli.obsgerencial2                 := cr_cli.obsgerencial2;
      gregcli.obsgerencial3                 := cr_cli.obsgerencial3;
      gregcli.latitude                      := cr_cli.latitude;
      gregcli.longitude                     := cr_cli.longitude;
      gregcli.datacoleta                    := cr_cli.datacoleta;
      gregcli.codcli                        := cr_cli.codcli;
      gregcli.codcob                        := cr_cli.codcob;
      gregcli.codplpag                      := cr_cli.codplpag;
      gregcli.emailnfe                      := lower(cr_cli.emailnfe);
      gregcli.codcidadeibge                 := cr_cli.codcidadeibge;
      gregcli.codfilialnf                   := cr_cli.codfilialnf;
      gregcli.consumidorfinal               := cr_cli.consumidorfinal;
      gregcli.contribuinte                  := cr_cli.contribuinte;
      gregcli.clientprotesto                := cr_cli.clientprotesto;
      gregcli.envionfeemailcom              := cr_cli.envionfemailcom;
      gregcli.diasemana                     := cr_cli.diasemana;
      gregcli.numsemana                     := cr_cli.numsemana;
      gregcli.sequencia                     := cr_cli.sequencia;
      gregcli.periodicidade                 := cr_cli.periodicidade;
      gregcli.simplesnacional               := nvl(cr_cli.simplesnacional, 'N');
      gregcli.codpais                       := cr_cli.codpais;
      gregcli.chave                         := cr_cli.chave;
      gregcli.fretedespacho                 := cr_cli.fretedespacho;
      gregcli.telcelent                     := cr_cli.telcelent; --HIS.03111.2017
      gregcli.calculast                     := cr_cli.calculast;
      gregcli.clientefontest                := cr_cli.clientefontest;
      gregcli.dtnasc                        := cr_cli.dtnasc;
      gregcli.cgcentrega                    := cr_cli.cgcentrega;

      vblercliok := true;

      IF vblercliok = TRUE
        THEN
          vncontcli := vncontcli + 1;
          gvet_regcli(vncontcli) := gregcli;
        END IF;


       EXCEPTION
        WHEN OTHERS THEN
          proc_registralog(NULL,
                           null,
                           null,
                           null,
                           gregcli.cgcent,
                           NULL,
                           NULL,
                           null,
                           null,
                           null,
                           null,
                           '-1',
                           'Erro ao ler cliente#;' || SQLCODE || '-' ||
                           SQLERRM || ';',
                           cr_cli.linha);
   end;


    end loop;

  end if;
    --fim clientes

    --Contatos
  if p_tiporeg is null or p_tiporeg = 2 then

  FOR cr_contato in (SELECT   cgccli,
                              nomecontato,
                              tipocontato,
                              cgccpf,
                              dtnascimento,
                              hobbie,
                              time,
                              nomeconjuge,
                              dtnascconjuge,
                              endereco,
                              bairro,
                              cidade,
                              cep,
                              cargo,
                              telefone,
                              celular,
                              email,
                              estado,
                              codcli,
                              rownum linha
                      from pccontatofv
                       WHERE (importado = p_tipoleitura)
                         AND (NVL(trunc(dtinclusao),trunc(sysdate)) BETWEEN vddatainicial AND vddatafinal))loop

   begin

      vblercontatook := false;

      gregcontato.cgccli            := cr_contato.cgccli;
      gregcontato.nomecontato       := cr_contato.nomecontato;
      gregcontato.tipocontato       := cr_contato.tipocontato;
      gregcontato.cgccpf            := cr_contato.cgccpf;
      gregcontato.dtnascimento      := cr_contato.dtnascimento;
      gregcontato.hobbie            := cr_contato.hobbie;
      gregcontato.time              := cr_contato.time;
      gregcontato.nomeconjuge       := cr_contato.nomeconjuge;
      gregcontato.dtnascconjuge     := cr_contato.dtnascconjuge;
      gregcontato.endereco          := cr_contato.endereco;
      gregcontato.bairro            := cr_contato.bairro;
      gregcontato.cidade            := cr_contato.cidade;
      gregcontato.cep               := cr_contato.cep;
      gregcontato.cargo             := cr_contato.cargo;
      gregcontato.telefone          := cr_contato.telefone;
      gregcontato.celular           := cr_contato.celular;
      gregcontato.email             := cr_contato.email;
      gregcontato.estado            := cr_contato.estado;
      gregcontato.codcli            := cr_contato.codcli;

      vblercontatook := true;

      IF vblercontatook = TRUE
        THEN
          vncontcontato := vncontcontato + 1;
          gvet_regcontato(vncontcontato) := gregcontato;
        END IF;


       EXCEPTION
        WHEN OTHERS THEN
          proc_registralog(NULL,
                           null,
                           null,
                           null,
                           gregcontato.cgccli,
                           NULL,
                           NULL,
                           null,
                           null,
                           null,
                           null,
                           '4',
                           'ERRO AO LER CONTATO;' || SQLCODE || '-' ||
                           SQLERRM || ';',
                           cr_contato.linha);
   end;


    end loop;
  end if;

   --fim contatos

 
  --Recados Funcionarios ( mensagens do rca -> funcionários da empresa)

 if p_tiporeg is null or p_tiporeg = 3 then

  FOR cr_mens in (SELECT  codfuncdest,
                          assunto,
                          textorecado,
                          numrecadofv,
                          codusur,
                          rownum linha
                      from pcrecfuncfv
                       WHERE (importado = p_tipoleitura)
                         AND (NVL(trunc(dtinclusao),trunc(sysdate)) BETWEEN vddatainicial AND vddatafinal)
                         AND  (codusur = p_codusur or p_codusur is null))loop

   begin

      vblermensok := false;

      gregmens.codfuncdest     := cr_mens.codfuncdest;
      gregmens.assunto         := cr_mens.assunto;
      gregmens.textorecado     := cr_mens.textorecado;
      gregmens.numrecadofv     := cr_mens.numrecadofv;
      gregmens.codusur         := cr_mens.codusur;

      vblermensok := true;

      IF vblermensok = TRUE
        THEN
          vncontmens := vncontmens + 1;
          gvet_regmens(vncontmens) := gregmens;
        END IF;


       EXCEPTION
        WHEN OTHERS THEN
          proc_registralog(NULL,
                           null,
                           null,
                           null,
                           null,
                           NULL,
                           cr_mens.numrecadofv,
                           null,
                           null,
                           null,
                           null,
                           '5',
                           'ERRO AO LER MENSAGENS DO RCA PARA FUNCIONARIOS (PCRECFUNCFV);' || SQLCODE || '-' ||
                           SQLERRM || ';',
                           cr_mens.linha);
   end;


    end loop;

  end if;
   --fim mensagens 
 
    --Gondolas
 if p_tiporeg is null or p_tiporeg = 4 then

  FOR cr_gondolac in (SELECT  numcontagem,
                              dtcontagem,
                              codusur,
                              cgccli,
                              codconc,
                              horainicial,
                              horafinal,
                              codcli,
                              numvisita,
                              rownum linha
                        from pcgondolafv
                         WHERE (importado = p_tipoleitura)
                           AND (NVL(trunc(dtinclusao),trunc(sysdate)) BETWEEN vddatainicial AND vddatafinal)
                           AND  (codusur = p_codusur or p_codusur is null))loop

   begin

      vblergondolacok := false;

      greggondolac.numcontagem    := cr_gondolac.numcontagem;
      greggondolac.dtcontagem     := cr_gondolac.dtcontagem;
      greggondolac.codusur        := cr_gondolac.codusur;
      greggondolac.cgccli         := cr_gondolac.cgccli;
      greggondolac.codconc        := cr_gondolac.codconc;
      greggondolac.horainicial    := cr_gondolac.horainicial;
      greggondolac.horafinal      := cr_gondolac.horafinal;
      greggondolac.codcli         := cr_gondolac.codcli;
      greggondolac.numvisita      := cr_gondolac.numvisita;

      vblergondolacok := true;

      IF vblergondolacok = TRUE
        THEN
          vncontgondolac := vncontgondolac + 1;
          gvet_reggondolac(vncontgondolac) := greggondolac;
        END IF;


       IF vblergondolacok = TRUE then

            FOR cr_itemgondola in (SELECT numcontagem,
                                          codprod,
                                          qt,
                                          pvenda,
                                          codusur,
                                          cgccli,
                                          qtperdas,
                                          girosellout,
                                          giromedio,
                                          rownum linha
                                   from pcgondolaifv
                                   where numcontagem = cr_gondolac.numcontagem
                                   and   cgccli      = cr_gondolac.cgccli
                                   and   codusur     = cr_gondolac.codusur ) loop
            begin

              vblergondolaiok := false;

              greggondolai.numcontagem    := cr_itemgondola.numcontagem;
              greggondolai.cgccli         := cr_itemgondola.cgccli;
              greggondolai.codusur        := cr_itemgondola.codusur;
              greggondolai.codprod        := cr_itemgondola.codprod;
              greggondolai.qt             := cr_itemgondola.qt;
              greggondolai.pvenda         := cr_itemgondola.pvenda;
              greggondolai.qtperdas       := cr_itemgondola.qtperdas;
              greggondolai.girosellout    := cr_itemgondola.girosellout;
              greggondolai.giromedio      := cr_itemgondola.giromedio;
              

              vblergondolaiok := true;

              IF vblergondolaiok = TRUE
                THEN
                  vncontgondolai := vncontgondolai + 1;
                  gvet_reggondolai(vncontgondolai) := greggondolai;
                END IF;


            EXCEPTION
            WHEN OTHERS THEN
              proc_registralog(NULL,
                               null,
                               cr_itemgondola.codprod,
                               null,
                               cr_itemgondola.cgccli,
                               NULL,
                               null,
                               cr_itemgondola.numcontagem,
                               cr_itemgondola.codusur,
                               null,
                               null,
                               '7',
                               'ERRO AO LER ITENS DE GONDOLA;' || SQLCODE || '-' ||
                               SQLERRM || ';',
                               cr_itemgondola.linha);

            end;
            end loop;


       END IF;



       EXCEPTION
        WHEN OTHERS THEN
          proc_registralog(NULL,
                           null,
                           null,
                           null,
                           cr_gondolac.cgccli,
                           NULL,
                           null,
                           cr_gondolac.numcontagem,
                           cr_gondolac.codusur,
                           null,
                           null,
                           '6',
                           'ERRO AO LER GONDOLAS;' || SQLCODE || '-' ||
                           SQLERRM || ';',
                           cr_gondolac.linha);
   end;


    end loop;
 end if;
   --fim Gondolas


    --Visitas
 if p_tiporeg is null or p_tiporeg = 7 then

  FOR cr_visita in (SELECT   cgccli,
                             codmotivo,
                             data ,
                             horainicial,
                             minutoinicial,
                             horafinal,
                             minutofinal,
                             assunto,
                             codusur,
                             codcli,
                             codrota,
                             rownum linha
                      from pcvisitafv
                       WHERE (importado = p_tipoleitura)
                         AND (NVL(trunc(dtinclusao),trunc(sysdate)) BETWEEN vddatainicial AND vddatafinal)
                         AND  (codusur = p_codusur or p_codusur is null))loop

   begin

      vblervisitaok := false;

      gregvisita.cgccli            := cr_visita.cgccli;
      gregvisita.codmotivo         := cr_visita.codmotivo;
      gregvisita.DATA              := cr_visita.data;
      gregvisita.hrinicial         := cr_visita.horainicial;
      gregvisita.minutoinicial     := cr_visita.minutoinicial;
      gregvisita.hrfinal           := cr_visita.horafinal;
      gregvisita.minutofinal       := cr_visita.minutofinal;
      gregvisita.assunto           := cr_visita.assunto;
      gregvisita.codusur           := cr_visita.codusur;
      gregvisita.codcli            := cr_visita.codcli;
      gregvisita.codrota           := cr_visita.codrota;

      vblervisitaok := true;

      IF vblervisitaok = TRUE
        THEN
          vncontvisita := vncontvisita + 1;
          gvet_regvisita(vncontvisita) := gregvisita;
        END IF;


       EXCEPTION
        WHEN OTHERS THEN
          proc_registralog(NULL,
                           null,
                           null,
                           null,
                           gregvisita.cgccli,
                           gregvisita.codmotivo,
                           gregvisita.hrinicial,
                           gregvisita.minutoinicial,
                           gregvisita.codusur,
                           null,
                           null,
                           '8',
                           'ERRO AO LER VISITA;' || SQLCODE || '-' ||
                           SQLERRM || ';',
                           cr_visita.linha);
   end;


    end loop;

 end if;
   --fim visitas



  -- referencia de clientes
  if p_tiporeg is null or p_tiporeg = 11 then

  FOR cr_cliref in (SELECT cgccli,
                           codref,
                           codcli,
                           emprefer,
                           telrefer,
                           contatorefer,
                           limcredrefer,
                           dtcadastrorefer,
                           dtultcomprefer,
                           vlultcomprefer,
                           obs,
                           dtmaiorcomprefer,
                           vlmaiorcomprefer,
                           codcobrefer,
                           rownum linha
                      from pcclireffv
                       WHERE (importado = p_tipoleitura)
                         AND (NVL(trunc(dtinclusao),trunc(sysdate)) BETWEEN vddatainicial AND vddatafinal)
                         )loop

   begin

      vblerclirefok := false;


      gregcliref.cgccli                     := cr_cliref.cgccli;
      gregcliref.codref                     := cr_cliref.codref;
      gregcliref.codcli                     := cr_cliref.codcli;
      gregcliref.emprefer                   := cr_cliref.emprefer;
      gregcliref.telrefer                   := cr_cliref.telrefer;
      gregcliref.contatorefer               := cr_cliref.contatorefer;
      gregcliref.limcredrefer               := cr_cliref.limcredrefer;
      gregcliref.dtcadastrorefer            := cr_cliref.dtcadastrorefer;
      gregcliref.dtultcomprefer             := cr_cliref.dtultcomprefer;
      gregcliref.vlultcomprefer             := cr_cliref.vlultcomprefer;
      gregcliref.obs                        := cr_cliref.obs;
      gregcliref.dtmaiorcomprefer           := cr_cliref.dtmaiorcomprefer;
      gregcliref.vlmaiorcomprefer           := cr_cliref.vlmaiorcomprefer;
      gregcliref.codcobrefer                := cr_cliref.codcobrefer;


      vblerclirefok := true;

      IF vblerclirefok = TRUE
        THEN
          vncontcliref := vncontcliref + 1;
          gvet_regcliref(vncontcliref) := gregcliref;
        END IF;


       EXCEPTION
        WHEN OTHERS THEN
          proc_registralog(NULL,
                           null,
                           null,
                           null,
                           gregcliref.cgccli,
                           gregcliref.codref,
                           NULL,
                           null,
                           null,
                           null,
                           null,
                           '14',
                           'Erro ao ler referencia comercial de cliente#;' || SQLCODE || '-' ||
                           SQLERRM || ';',
                           cr_cliref.linha);
   end;


    end loop;

  end if;
    --fim referencia de clientes



 --Cotações
 if p_tiporeg is null or p_tiporeg = 8 then

  FOR cr_cotacao in (SELECT   codprod,
                              codconc,
                              codcli,
                              cgccli,
                              numseq,
                              punit,
                              data,
                              codusur,
                              numregiao,
                              codfilial,
                              ptabela,
                              codplpag,
                              custofin,
                              custoreal,
                              prazo,
                              datadoc,
                              precocon1,
                              precocon2,
                              precocon3,
                              precocon4,
                              precocon5,
                              obs,
                              estoque,
                              codauxiliar,
                              lista,
                              percmaxdescmercado,
                              obs2,
                              codprodconc,
                             rownum linha
                      from pccotafv
                       WHERE (importado = p_tipoleitura)
                         AND (NVL(trunc(dtinclusao),trunc(data)) BETWEEN vddatainicial AND vddatafinal)
                         AND  (codusur = p_codusur or p_codusur is null))loop

   begin

      vblercotacaook := false;

      gregcotacao.codprod              := cr_cotacao.codprod;
      gregcotacao.codauxiliar          := cr_cotacao.codauxiliar;
      gregcotacao.numseq               := cr_cotacao.numseq;
      gregcotacao.codconc              := cr_cotacao.codconc;
      gregcotacao.cgccli               := cr_cotacao.cgccli;
      gregcotacao.codcli               := cr_cotacao.codcli;
      gregcotacao.codusur              := cr_cotacao.codusur;
      gregcotacao.punit                := cr_cotacao.punit;
      gregcotacao.datadoc              := cr_cotacao.datadoc;
      gregcotacao.numregiao            := cr_cotacao.numregiao;
      gregcotacao.codfilial            := cr_cotacao.codfilial;
      gregcotacao.ptabela              := cr_cotacao.ptabela;
      gregcotacao.codplpag             := cr_cotacao.codplpag;
      gregcotacao.custofin             := cr_cotacao.custofin;
      gregcotacao.custoreal            := cr_cotacao.custoreal;
      gregcotacao.prazo                := cr_cotacao.prazo;
      gregcotacao.precocon1            := cr_cotacao.precocon1;
      gregcotacao.precocon2            := cr_cotacao.precocon2;
      gregcotacao.precocon3            := cr_cotacao.precocon3;
      gregcotacao.precocon4            := cr_cotacao.precocon4;
      gregcotacao.precocon5            := cr_cotacao.precocon5;
      gregcotacao.obs                  := cr_cotacao.obs;
      gregcotacao.obs2                 := cr_cotacao.obs2;
      gregcotacao.estoque              := cr_cotacao.estoque;
      gregcotacao.lista                := cr_cotacao.lista;
      gregcotacao.percmaxdescmercado   := cr_cotacao.percmaxdescmercado;
      gregcotacao.codprodconc          := cr_cotacao.codprodconc;
      gregcotacao.data                 := cr_cotacao.data;

      vblercotacaook := true;

      IF vblercotacaook = TRUE
        THEN
          vncontcotacao := vncontcotacao + 1;
          gvet_regcotacao(vncontcotacao) := gregcotacao;
        END IF;


       EXCEPTION
        WHEN OTHERS THEN
            proc_registralog(null
                            ,null
                            ,cr_cotacao.codprod
                            ,cr_cotacao.codauxiliar
                            ,cr_cotacao.cgccli
                            ,null
                            ,cr_cotacao.codconc
                            ,cr_cotacao.numseq
                            ,cr_cotacao.codusur
                            ,cr_cotacao.DATA
                            ,null
                            ,'13'
                           ,'ERRO AO LER COTACOES;' || SQLCODE || '-' ||
                           SQLERRM || ';'
                           ,cr_cotacao.linha);
   end;


    end loop;

 end if;
   --fim cotações
  EXCEPTION
    WHEN OTHERS THEN
      p_existerro := TRUE;
      proc_registralog(NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       null,
                       null,
                       null,
                       null,
                       '1',
                       'ERRO AO LER REGISTROS;' || SQLCODE || '-' || SQLERRM || ';',
                       NULL);
  END proc_processarleitura;

FUNCTION INT_CHECK_EMAIL(EMAIL IN VARCHAR2) RETURN NUMBER IS
  N NUMBER;
BEGIN

     SELECT COUNT(*) INTO N
       FROM DUAL
      WHERE REGEXP_LIKE(UPPER(EMAIL),
                        '[A-Z0-9._%-]+@[A-Z0-9._%-]+\.[A-Z]{2,4}');

    RETURN N;

END INT_CHECK_EMAIL;

procedure proc_validarcliente(p_regcliente in out t_cliente) is
    vsmensagem                    varchar2(32767) := null;
    vschar                        varchar2(1) default '#';
    vicontador                    number;
    vstipofj                      varchar2(1);
    vscgcent                      varchar2(14);
    vnproxnumcli                  number;
    vsbloqcliautfv                varchar2(1);
    vnperiodicidade               number;
    vsobrigatorioemailnfecliente  varchar2(1);
    vnemailvalido                 number;
    vCodibge                      number;
  begin

    p_regcliente.valido := true;

    p_Regcliente.bloqueio := 'S';
    
-- tarefa 192086
   begin
      select nvl(p.valor,'S')
      into vsbloqcliautfv
      from pcparamfilial p
      where p.codfilial = p_regcliente.codfilialnf
      and   p.nome = 'BLOQCLIAUTFV';
      exception
     when no_Data_found  then 
      begin


        select nvl(p.valor,'S')
        into vsbloqcliautfv
        from pcparamfilial p
        where p.codfilial = '99'
        and   p.nome = 'BLOQCLIAUTFVGERAL';
        exception 
         when no_data_found then
          vsbloqcliautfv := 'S';
         when others then
          vsbloqcliautfv := 'S'; 
      end; 
     
     when others then
      vsbloqcliautfv := 'S';

     end;


    if vsbloqcliautfv = 'N' then
    
      p_Regcliente.bloqueio := 'N';
    
    end if;


 ---tarefa 209911
   begin
     select nvl(p.valor,'S')
     into vsobrigatorioemailnfecliente
     from pcparamfilial p
     where p.codfilial = '99'
     and   p.nome = 'OBRIGATORIOEMAILNFECLIENTE';
    exception 
     when no_data_found then
      vsobrigatorioemailnfecliente := 'N';
     when others then
      vsobrigatorioemailnfecliente := 'N'; 

  end;


    vscgcent := FERRAMENTAS.SONUMEROS(p_regcliente.cgcent);

    -- 01. Verificar Tipo de Pessoa Fisica
    if LENGTH(vscgcent) = 11 then
      p_regcliente.tipofj := 'F';
    elsif LENGTH(vscgcent) = 14 then
      p_regcliente.tipofj := 'J';
    else

      p_regcliente.valido := false;

      if vsmensagem is not null then
        vschar := '#';
      else
        vschar := null;
      end if;

      vsmensagem := vsmensagem || vschar || 'CNPJ/CPF INVALIDO;';
    end if;

if p_regcliente.codcob is not null then
    
       select count(*)
       into   vicontador
       from pccob
       where codcob = p_regcliente.codcob;
       
       if vicontador = 0 then
       
          if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;
          
          
          if p_regcliente.tipooperacao = 'I' then
        
             vsmensagem := vsmensagem || vschar || 'COBRANCA INVALIDA. SERA GRAVADA A COBRANCA INICIAL DA ROTINA 132;';
       
            p_regcliente.codcob := gregpcconsum.codcobinicial;
          else
          
            vsmensagem := vsmensagem || vschar || 'COBRANCA INVALIDA. NAO SERA ALTERADA COBRANCA;';
            p_regcliente.codcob := null;
          
          end if;  
       
       
       end if;
    
    else
      if p_regcliente.tipooperacao = 'I' then
    
        p_regcliente.codcob := gregpcconsum.codcobinicial;
      end if;  
    
    end if;


if p_regcliente.codplpag is not null then
    
       select count(*)
       into   vicontador
       from pcplpag
       where codplpag = p_regcliente.codplpag;
       
       if vicontador = 0 then
       
          if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;
          
          if p_regcliente.tipooperacao = 'I' then
        
             vsmensagem := vsmensagem || vschar || 'PLANO DE PAGAMENTO INVALIDO. SERA GRAVADO O PLANO INICIAL DA ROTINA 132;';
       
             p_regcliente.codplpag := gregpcconsum.codplpaginicial;
           else
             vsmensagem := vsmensagem || vschar || 'PLANO DE PAGAMENTO INVALIDO. NAO SERA ALTERADO O PLANO DE PAGAMENTO;';
       
             p_regcliente.codplpag := null;
           
           end if;  
       
       
       end if;
    
    else
       if p_regcliente.tipooperacao = 'I' then
         p_regcliente.codplpag := gregpcconsum.codplpaginicial;
       end if;  
    
    end if;

    begin
      select pccidade.codibge
      into vCodibge
      from pccidade
      where pccidade.codibge = p_regcliente.codcidadeibge
      and   rownum = 1;
      exception when others then
         vCodibge := null;
    end;

	if vCodibge is null then

      begin
      select pccidade.codibge
      into p_regcliente.codcidadeibge
      from pccidade
      where pccidade.codcidade = p_regcliente.codcidadeibge
      and   rownum = 1;
	  exception when others then
         p_regcliente.codcidadeibge := null;		 
      end;
    end if;	

    if p_regcliente.codcidadeibge is not null then

      begin
        select pccidade.codcidade
        into p_regcliente.codcidade
        from pccidade
        where pccidade.codibge = p_regcliente.codcidadeibge
        and   rownum = 1;
        exception when others then
         p_regcliente.codcidade := null;      
      end;
    else
	    vsmensagem := vsmensagem || vschar || 'CODIGO IBGE INVALIDO. NAO SERA ALTERADO A CIDADE;';
		p_Regcliente.valido := false;
    end if;


  --Valida campos roteirização
  
  if p_regcliente.diasemana is not null then
  
     if p_regcliente.diasemana not in ('SEGUNDA','TERCA','QUARTA','QUINTA','SEXTA','SABADO') then
    
         if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;
          
          vsmensagem := vsmensagem || vschar || 'DIA DA SEMANA INVALIDO PARA ROTERIRIZACAO !';
          
          p_regcliente.diasemana := null;
     
     end if;
  
  end if;
  
  if p_regcliente.periodicidade is not null then
  
     if p_Regcliente.periodicidade = '0' then

         if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;
          
          vsmensagem := vsmensagem || vschar || 'PERIODICIDADE 0 É INVALIDA PARA ROTERIRIZACAO !';
          
          p_regcliente.diasemana := null;

     else
     
       begin
       
         select to_number(p_regcliente.periodicidade)
         into vnperiodicidade
         from dual;
         exception when others then

         if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;
          
          vsmensagem := vsmensagem || vschar || 'PERIODICIDADE INVALIDA PARA ROTERIRIZACAO !';
          
          p_regcliente.diasemana := null;
       
       end;
     end if;
  
  end if;
  
  --valida simplesnacional
  
  if p_regcliente.simplesnacional not in ('N','S') then
  
     p_regcliente.simplesnacional := null;
  
  end if;


  --valida email


       
  if p_regcliente.email is not null then
    begin
  
     vnemailvalido := INT_CHECK_EMAIL(p_regcliente.email);
     
     if vnemailvalido = 0 then
         if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;
          
          vsmensagem := vsmensagem || vschar || 'CAMPO EMAIL INVALIDO!';
     
         p_Regcliente.valido := false;
     
     end if;
     
    exception when others then
      null;
    
    end; 
    
  end if;

   
  
  if p_regcliente.emailnfe is null then
  
    if vsobrigatorioemailnfecliente = 'S' and p_regcliente.tipooperacao = 'I'  then
  
        if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;
          
          vsmensagem := vsmensagem || vschar || 'CAMPO EMAILNFE NAO PODE SER NULO, DEVIDO AO PARAMETRO 2351 !';
     
         p_Regcliente.valido := false;
     
    end if; 
  
  else
  
    begin
  
     vnemailvalido := INT_CHECK_EMAIL(p_regcliente.emailnfe);
     
     if vnemailvalido = 0 then
         if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;
          
          vsmensagem := vsmensagem || vschar || 'CAMPO EMAILNFE INVALIDO!';
     
         p_Regcliente.valido := false;
     
     end if;
     
    exception when others then
      null;
    
    end; 
  
  end if;
  

  --valida pais
  if nvl(p_regcliente.codpais,0) <> 0 then
  
     select count(*)
     into vicontador
     from pcpais
     where pcpais.codpais = p_regcliente.codpais;
     
     if vicontador = 0 then
     
         if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;
          
          vsmensagem := vsmensagem || vschar || 'CODIGO DO PAIS INVALIDO!';
     
         p_Regcliente.valido := false;
     
     
     end if;
  
  end if;

  if Length(p_regcliente.complementoent) > 60 then
    if vsmensagem is not null then
      vschar := '#';
    else
      vschar := null;
    end if;

    vsmensagem := vsmensagem || vschar || 'CAMPO COMPLEMENTO ENDEREÇO COMERCIAL INVÁLIDO. MÁXIMO 60 CARACTERES!';

    p_Regcliente.valido := false;
  end if;

  if Length(p_regcliente.complementocob) > 60 then
    if vsmensagem is not null then
      vschar := '#';
    else
      vschar := null;
    end if;

    vsmensagem := vsmensagem || vschar || 'CAMPO COMPLEMENTO ENDEREÇO COBRANÇA INVÁLIDO. MÁXIMO 60 CARACTERES!';

    p_Regcliente.valido := false;
  end if;

  if Length(p_regcliente.complementocom) > 60 then
    if vsmensagem is not null then
      vschar := '#';
    else
      vschar := null;
    end if;

    vsmensagem := vsmensagem || vschar || 'CAMPO COMPLEMENTO ENDEREÇO ENTREGA INVÁLIDO. MÁXIMO 60 CARACTERES!';

    p_Regcliente.valido := false;
  end if;

  --valida inscrição estadual
  /************************************************************
  *Responsável: Rafael Soares
  *Solicitação: HIS.02164.2015
  *Data: 14/10/2015
  *Alteração: Quando o parametro IECLIEXCLUSIVA estiver igual a 'S', e a inscrição estadual
  *           for diferente de ISENTO,não deve ser permitido o cadastro do cliente.
  *************************************************************/
  if (p_regcliente.tipooperacao = 'I') and
     ((ferramentas.F_BUSCARPARAMETRO_ALFA('CON_IECLIEXCLUSIVA', '99','N') = 'S') and
     ((p_regcliente.ieent <> 'ISENTO') AND (p_regcliente.ieent <> 'ISENTA') OR (p_regcliente.ieent <> NULL))) then

     SELECT count(*)
     INTO vicontador
     FROM pcclient
     WHERE pcclient.ieent = p_regcliente.ieent AND
           pcclient.dtexclusao IS NULL;

     if vicontador > 0 then

        if vsmensagem is not null then
          vschar := '#';
        else
          vschar := null;
        end if;

        vsmensagem := vsmensagem || vschar || 'JÁ EXISTEM CLIENTES INSERIDOS COM ESSA INSCIÇÃO ESTADUAL!';

        p_Regcliente.valido := false;

     end if;

  end if;

  --Nova validação na inserção se o CGCEXCLUSIVO ESTIVER COMO SIM rejeitar dupliciades de cpfs na insercão
  if (p_regcliente.tipooperacao = 'I') and
     ((ferramentas.F_BUSCARPARAMETRO_ALFA('CON_CGCCLIEXCLUSIVO', '99','N') = 'S')) and (p_regcliente.estent <> 'EX')then

     vscgcent := FERRAMENTAS.SONUMEROS(p_regcliente.cgcent);

     SELECT count(*)
     INTO vicontador
     FROM pcclient
     WHERE FERRAMENTAS.SONUMEROS(pcclient.cgcent) = FERRAMENTAS.SONUMEROS(p_regcliente.cgcent);

     if vicontador > 0 then

        if vsmensagem is not null then
          vschar := '#';
        else
          vschar := null;
        end if;

        vsmensagem := vsmensagem || vschar || 'JÁ EXISTEM CLIENTES INSERIDOS COM ESSE CPF/CNPJ! PARAMETRO 1391 da 132!';

        p_Regcliente.valido := false;

     end if;

  end if;

  -- 02. Verificar se cliente ja esta cadastrado
  -- Validação repassada para a trigger  TRG_PCCLIENT_CGC_EXCLUSIVO
   /*if (gregpcconsum.cgccliexclusivo = 'S') and (p_regcliente.tipooperacao = 'I') then

     select count(*)
       into vicontador
       from pcclient
      where trim(replace(replace(replace(replace(replace(replace(cgcent,' ',''), '.', ''),
                                                 ',',
                                                 ''),
                                         '-',
                                         ''),
                                 '/',
                                 ''),
                         '\',
                         '')) = vscgcent;
     if vicontador > 0 then

       p_regcliente.valido := false;

       if vsmensagem is not null then
         vschar := '#';
       else
         vschar := null;
       end if;

       vsmensagem := vsmensagem || vschar || 'CLIENTE JA CADASTRADO;';

     end if;

  end if;  */

  if p_regcliente.tipooperacao = 'I' then

     --05. Verificar existência da praça

     select count(*)
      into vicontador
      from pcpraca
      where codpraca = p_regcliente.codpraca;

    if vicontador = 0 then

      p_regcliente.valido := false;

      if vsmensagem is not null then
        vschar := '#';
      else
        vschar := null;
      end if;

      vsmensagem := vsmensagem || vschar || 'COD. PRACA NAO EXISTE;';

    end if;


    --06. Buscar regiao do cliente
    begin

      select pcpraca.numregiao
        into p_regcliente.numregiaocli
        from pcpraca
       where codpraca = p_regcliente.codpraca;

    exception
      when others then
        p_regcliente.numregiaocli := 0;
    end;

    -- 03. Numeracao do Cliente
    if p_regcliente.valido = true then

      if gregpcconsum.numautomaticcli = 'S' then

        begin

          p_regcliente.codcli := F_PROX_CODCLI;

          --F_PROX_CODCLIPALM(p_regcliente.codusur1,p_regcliente.codclipalm);

        exception
          when others then
            rollback;
            p_regcliente.valido := false;

            if vsmensagem is not null then
              vschar := '#';
            else
              vschar := null;
            end if;

            vsmensagem := vsmensagem || vschar ||
                          'ERRO AO GERAR CODCLI :'||SQLCODE||' '||SQLERRM||';';
        end;
      else

        p_regcliente.valido := false;

            if vsmensagem is not null then
              vschar := '#';
            else
              vschar := null;
            end if;

            vsmensagem := vsmensagem || vschar ||
                          'O PARÂMETRO NUMAUTOMATICCLI PRECISA ESTAR MARCADO PARA GERAR O CODCLI'||';';
      end if;
    end if;

    --04. Checar existencia do cod. cliente
    select count(*)
      into vicontador
      from pcclient
     where codcli = p_regcliente.codcli;

    if vicontador > 0 then

          p_regcliente.valido := false;

          if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;

          vsmensagem := vsmensagem || vschar || 'COD. CLIENTE JA EXISTE;';


    end if;

    --Tipooperacao = 'A'
    elsif p_Regcliente.tipooperacao = 'A' then

        --07. Checar existencia do cod. cliente
        select count(*)
          into vicontador
          from pcclient
         where FERRAMENTAS.SONUMEROS(cgcent) = vscgcent
          and dtexclusao is null ;


       if vicontador = 0 then

           p_regcliente.valido := false;

          if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;

          vsmensagem := vsmensagem || vschar || 'CLIENTE NAO EXISTE PARA SER ALTERADO;';

       elsif vicontador = 1 then

         select codcli
          into p_regcliente.codcli
          from pcclient
         where FERRAMENTAS.SONUMEROS(cgcent) = vscgcent
          and dtexclusao is null;

          if p_regcliente.codpraca is not null then

              -- verificar existência da praça
              select count(*)
               into vicontador
               from pcpraca
               where codpraca = p_regcliente.codpraca;

              if vicontador = 0 then
                 p_regcliente.valido := false;

                 if vsmensagem is not null then
                   vschar := '#';
                 else
                   vschar := null;
                 end if;

                 vsmensagem := vsmensagem || vschar || 'COD. PRACA NAO EXISTE;';
              end if;

              -- valida se existe pedido não faturado e não cancelado para  o cliente se for alterar a praça
              begin
                select count(1)
                  into vicontador
                  from pcpedc, pcclient
                where pcpedc.codcli = pcclient.codcli
                  and pcclient.codcli = p_regcliente.codcli
                  and pcclient.codpraca <> p_regcliente.codpraca -- apenas para alteração de praça
                  and pcpedc.posicao not in ('F', 'C');

                if vicontador > 0 then
                   p_regcliente.valido := false;

                   if vsmensagem is not null then
                      vschar := '#';
                   else
                      vschar := null;
                   end if;

                   vsmensagem := vsmensagem || vschar || 'PRAÇA NÃO PODE SER ALTERADA, CLIENTE TEM PEDIDOS NÃO FATURADOS;';
                end if;
              exception
                when others then
                  rollback;
                  p_regcliente.valido := false;

                  if vsmensagem is not null then
                    vschar := '#';
                  else
                    vschar := null;
                  end if;

                  vsmensagem := vsmensagem || vschar ||
                                'ERRO AO VALIDAR COD. PRAÇA :'||SQLCODE||' '||SQLERRM||';';
              end;
          end if;
       else


         if p_Regcliente.codcli is null then

           p_regcliente.valido := false;

          if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;

          vsmensagem := vsmensagem || vschar || 'EXISTE MAIS DE UM CLIENTE PARA ESTE CGC/CPF;';

         else

         begin

          select codcli
          into p_regcliente.codcli
          from pcclient
         where FERRAMENTAS.SONUMEROS(cgcent) = vscgcent
          and dtexclusao is null
          and pcclient.codcli = p_Regcliente.codcli   ;
          exception when others then

            if vsmensagem is not null then
              vschar := '#';
            else
              vschar := null;
            end if;
            vsmensagem           := vsmensagem || vschar ||
                                    'ERRO AO BUSCAR CLIENTE PARA ATUALIZAR;';
            p_regcliente.valido := false;

          end;
         end if;


      end if;

    else

      p_regcliente.valido := false;

      if vsmensagem is not null then
        vschar := '#';
      else
        vschar := null;
      end if;

      vsmensagem := vsmensagem || vschar || 'TIPOOPERACAO INVALIDO;';

    end if;

    -- registra log
    if (vsmensagem is not null) then

     INSERT INTO pclogfv
      (arquivo, codcli, DATA, motivo, numped, numpedcli, numpedrca, status)
     VALUES
      ('PCCLIENTFV',
      null,
      SYSDATE,
      'falhou as validações para este cpf: ' || p_regcliente.cgcent,
      NULL,
      NULL,
      NULL,
      'N');
      commit;

      proc_registralog(null,
                       null,
                       null,
                       null,
                       p_regcliente.cgcent,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       '-1',
                       vsmensagem,
                       null);
    end if;

  exception
    when others then
      p_regcliente.valido := false;
      proc_registralog(null,
                       null,
                       null,
                       null,
                       p_regcliente.cgcent,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       '-1',
                       sqlcode || '-' || sqlerrm,
                       null);
  end proc_validarcliente;


procedure proc_validarcontato(p_regcontato in out t_contato) is
    vsmensagem   varchar2(32767) := null;
    vschar       varchar2(1) default '#';
    vicontador   number;
    vscgcent     varchar2(14);
    vsvalor      varchar2(1);
    vscodcli     pccontato.codcli%type;
  begin

    p_regcontato.valido := true;

    vscgcent := FERRAMENTAS.SONUMEROS(p_regcontato.cgccli);

    if (nvl(p_regcontato.codcli,0) = 0 ) then
      BEGIN
            select CODCLI
            into p_regcontato.codcli
            from pcclient
           where  FERRAMENTAS.SONUMEROS(cgcent) = vscgcent
          and dtexclusao is null;
      EXCEPTION
       WHEN NO_DATA_FOUND  THEN
        BEGIN
          p_regcontato.valido := false;

          if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;

          vsmensagem := vsmensagem || vschar || 'CLIENTE NAO EXISTE ;';
        END;

       WHEN TOO_MANY_ROWS THEN
       BEGIN
          p_regcontato.valido := false;

          if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;

          vsmensagem := vsmensagem || vschar || 'EXISTE MAIS DE UM CLIENTE PARA ESTE CGC/CPF;';
       END;

       WHEN OTHERS THEN
       BEGIN
          if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;
          vsmensagem           := vsmensagem || vschar ||
                                  'ERRO AO BUSCAR CLIENTE DO CONTATO;';
          p_regcontato.valido := false;
       END;
      END;
    end if;

    -- 02. Numeracao do Contato
    if p_regcontato.valido = true then
        begin

          select dfseq_pccontato.nextval
            into p_regcontato.codcontato
            from dual;

        exception
          when others then

            p_regcontato.valido := false;

            if vsmensagem is not null then
              vschar := '#';
            else
              vschar := null;
            end if;

            vsmensagem := vsmensagem || vschar ||
                          'ERRO AO GERAR CODCONTATO :'||SQLCODE||' '||SQLERRM||';';
        end;

    end if;



    --03. Checar existencia do cod. contato
    select count(*)
      into vicontador
      from pccontato
     where codcontato = p_regcontato.codcontato;

    if vicontador > 0 then

          p_regcontato.valido := false;

          if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;

          vsmensagem := vsmensagem || vschar || 'COD. CONTATO JA EXISTE. VERIFIQUE A SEQUENCE DFSEQ_PCCONTATO;';


    end if;

    begin
      select nvl(max(CODCLI),0) 
        into vscodcli
        from PCCONTATO
      where  FERRAMENTAS.SONUMEROS(CGCCPF) =  FERRAMENTAS.SONUMEROS(p_regcontato.cgccpf);          
      if vscodcli > 0 then
             SELECT NVL(MAX(VALOR),'N') INTO vsvalor FROM PCPARAMFILIAL
             WHERE PCPARAMFILIAL.NOME = 'RESTRINGIRMESMOCONTATOREDEDIF' 
               AND PCPARAMFILIAL.CODFILIAL = '99'; 
          if vsvalor = 'S' then
             if vsmensagem is not null then
               vschar := '#';
             else
               vschar := null;
             end if;  
             p_regcontato.valido := false;    
             vsmensagem := vsmensagem || vschar || 'Contato já cadastrado para outro Cliente! Código do cliente como contato Existente ' || vscodcli || ' e RESTRINGIRMESMOCONTATOREDEDIF = S;';
          end if;
      end if;
    exception
          when others then

            p_regcontato.valido := false;

            if vsmensagem is not null then
              vschar := '#';
            else
              vschar := null;
            end if;

            vsmensagem := vsmensagem || vschar ||
                          'ERRO AO VERIFICAR RESTRINGIRMESMOCONTATOREDEDIF :'||SQLCODE||' '||SQLERRM||';';
    end;




    -- registra log
    if (vsmensagem is not null) then
      proc_registralog(null,
                       null,
                       null,
                       null,
                       p_regcontato.cgccli,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       '4',
                       vsmensagem,
                       null);
    end if;

  exception
    when others then
      p_regcontato.valido := false;
      proc_registralog(null,
                       null,
                       null,
                       null,
                       p_regcontato.cgccli,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       '4',
                       sqlcode || '-' || sqlerrm,
                       null);
  end proc_validarcontato;

  procedure proc_validarvisita(p_regvisita in out t_visita) is
    vsmensagem      varchar2(32767):= null;
    vschar          varchar2(1) default '#';
    vicontador      number;

  begin
    p_regvisita.valido := true;
    vsmensagem         := null;

    if (nvl(p_regvisita.codcli,0) = 0 ) then
      BEGIN
            select CODCLI
            into p_regvisita.codcli
            from pcclient
           where  FERRAMENTAS.SONUMEROS(cgcent) = FERRAMENTAS.SONUMEROS(p_regvisita.cgccli)
          and dtexclusao is null;
      EXCEPTION
       WHEN NO_DATA_FOUND  THEN
        BEGIN
          if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;
          vsmensagem           := vsmensagem || vschar ||
                                  'CLIENTE NAO CADASTRADO OU EXCLUIDO;';
          p_regvisita.valido := false;
        END;

       WHEN TOO_MANY_ROWS THEN
       BEGIN
          if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;
          vsmensagem           := vsmensagem || vschar ||
                                  'ENCONTRADO MAIS DE UM CLIENTE PARA ESTE CNPJ/CPF;';
          p_regvisita.valido := false;
       END;

       WHEN OTHERS THEN
       BEGIN
          if vsmensagem is not null then
             vschar := '#';
          else
             vschar := null;
           end if;
           vsmensagem           := vsmensagem || vschar ||
                                   'ERRO AO BUSCAR CLIENTE DA VISITA;';
           p_regvisita.valido := false;
       END;
      END;
    end if;


    if p_regvisita.codmotivo is not null then

        --02 Verifica se codmotivo está cadastrado
        select count(*)
        into vicontador
        from pcmotnaocompra
        where codmotivo = p_regvisita.codmotivo;

        if vicontador = 0 then

          if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;
          vsmensagem           := vsmensagem || vschar ||
                                  'CODMOTIVO NAO CADASTRADO;';
          p_regvisita.valido := false;

        end if;
    end if;

      --03 Verifica se visita já está cadastrada
      select count(*)
      into vicontador
      from pcvisita
      where (codmotivo      = p_regvisita.codmotivo or codmotivo is null)
      and   codcli         = p_Regvisita.codcli
      and   codusur        = p_regvisita.codusur
      and   data           = p_Regvisita.DATA
      and   hrinicial      = p_regvisita.hrinicial
      and   minutoinicial  = p_Regvisita.minutoinicial;

      if vicontador <> 0 then

        if vsmensagem is not null then
          vschar := '#';
        else
          vschar := null;
        end if;
        vsmensagem           := vsmensagem || vschar ||
                                'VISITA JA CADASTRADA;';
        p_regvisita.valido := false;

      end if;

    -- registra log
    if (vsmensagem is not null) then
      proc_registralog(null,
                       null,
                       null,
                       null,
                       p_regvisita.cgccli,
                       p_regvisita.codmotivo,
                       p_regvisita.hrinicial,
                       p_regvisita.minutoinicial,
                       p_regvisita.codusur,
                       p_regvisita.DATA,
                       null,
                       '8',
                       vsmensagem,
                       null);
    end if;
  exception
    when others then
      p_regvisita.valido := false;
      proc_registralog(null,
                       null,
                       null,
                       null,
                       p_regvisita.cgccli,
                       p_regvisita.codmotivo,
                       p_regvisita.hrinicial,
                       p_regvisita.minutoinicial,
                       p_regvisita.codusur,
                       p_regvisita.DATA,
                       null,
                       '8',
                       sqlcode || '-' || sqlerrm,
                       null);
  end proc_validarvisita;

procedure proc_validarcliref(p_regcliref in out t_cliref) is
    vsmensagem      varchar2(32767):= null;
    vschar          varchar2(1) default '#';
    vicontador      number;

  begin
    p_regcliref.valido := true;
    vsmensagem         := null;

    if (nvl(p_regcliref.cgccli,'0') <> '0' ) then
      BEGIN
            select CODCLI
            into p_regcliref.codcli
            from pcclient
           where  FERRAMENTAS.SONUMEROS(cgcent) = FERRAMENTAS.SONUMEROS(p_regcliref.cgccli)
          and dtexclusao is null;
      EXCEPTION
       WHEN NO_DATA_FOUND  THEN
        BEGIN
          if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;
          vsmensagem           := vsmensagem || vschar ||
                                  'CLIENTE NAO CADASTRADO OU EXCLUIDO;';
          p_regcliref.valido := false;
        END;

       WHEN TOO_MANY_ROWS THEN
       BEGIN
          if vsmensagem is not null then
            vschar := '#';
          else
            vschar := null;
          end if;
          vsmensagem           := vsmensagem || vschar ||
                                  'ENCONTRADO MAIS DE UM CLIENTE PARA ESTE CNPJ/CPF;';
          p_regcliref.valido := false;
       END;

       WHEN OTHERS THEN
       BEGIN
           if vsmensagem is not null then
             vschar := '#';
           else
             vschar := null;
           end if;
           vsmensagem           := vsmensagem || vschar ||
                                   'ERRO AO BUSCAR CLIENTE REFERENCIADO;' ||SQLCODE||' '||SQLERRM||';';
           p_regcliref.valido := false;
       END;
      END;
    else
      if vsmensagem is not null then
        vschar := '#';
      else
        vschar := null;
      end if;
      vsmensagem := vsmensagem || vschar ||
        'CGC INVALIDO PARA CLIENTE REFERENCIADO.';
        p_regcliref.valido := false;

    end if;

    -- registra log
    if (vsmensagem is not null) then
      proc_registralog(null,
                       null,
                       null,
                       null,
                       p_regcliref.cgccli,
                       p_regcliref.codref,
                       null,
                       null,
                       null,
                       null,
                       null,
                       '14',
                       vsmensagem,
                       null);
    end if;
  exception
    when others then
      p_regcliref.valido := false;
      proc_registralog(null,
                       null,
                       null,
                       null,
                       p_regcliref.cgccli,
                       p_regcliref.codref,
                       null,
                       null,
                       null,
                       null,
                       null,
                       '14',
                       sqlcode || '-' || sqlerrm,
                       null);
  end proc_validarcliref;




  procedure proc_validargondolac(p_reggondolac in out t_gondolac) is
    vsmensagem      varchar2(32767) := null;
    vschar          varchar2(1) default '#';
    vicontador      number;
    vsnome          varchar2(30);

  begin
    p_reggondolac.valido := true;
    vsmensagem           := null;


      --01. Verificar se o Cliente esta Cadastrado
      select count(*)
        into vicontador
        from pcclient
       where  FERRAMENTAS.SONUMEROS(cgcent) = FERRAMENTAS.SONUMEROS(p_reggondolac.cgccli)
      and dtexclusao is null    ;

      if vicontador = 0 then
        if vsmensagem is not null then
          vschar := '#';
        else
          vschar := null;
        end if;
        vsmensagem           := vsmensagem || vschar ||
                                'CLIENTE NAO CADASTRADO OU EXCLUIDO;';
        p_reggondolac.valido := false;

      elsif vicontador = 1 then


          select codcli
            into p_reggondolac.codcli
            from pcclient
           where  FERRAMENTAS.SONUMEROS(cgcent) = FERRAMENTAS.SONUMEROS(p_reggondolac.cgccli)
          and dtexclusao is  null    ;


      else


        if p_reggondolac.codcli is null then

            if vsmensagem is not null then
              vschar := '#';
            else
              vschar := null;
            end if;
            vsmensagem           := vsmensagem || vschar ||
                                    'ENCONTRADO MAIS DE UM CLIENTE PARA ESTE CNPJ/CPF;';
            p_reggondolac.valido := false;



        else

         begin

          select codcli
            into p_reggondolac.codcli
            from pcclient
           where  FERRAMENTAS.SONUMEROS(cgcent) = FERRAMENTAS.SONUMEROS(p_reggondolac.cgccli)
          and dtexclusao is  null
          and pcclient.codcli = p_reggondolac.codcli   ;
          exception when others then

            if vsmensagem is not null then
              vschar := '#';
            else
              vschar := null;
            end if;
            vsmensagem           := vsmensagem || vschar ||
                                    'ERRO AO BUSCAR CLIENTE DO PEDIDO;';
            p_reggondolac.valido := false;

          end;

         end if;


      end if;

    -- 02. Verificar Concorrente
    if p_reggondolac.codconc is not null then
      select count(*)
        into vicontador
        from pcconcor
       where codconc = p_reggondolac.codconc;

      if vicontador = 0 then
        if vsmensagem is not null then
          vschar := '#';
        else
          vschar := null;
        end if;
        vsmensagem           := vsmensagem || vschar ||
                                'CONCORRENTE NAO CADASTRADO;';
        p_reggondolac.valido := false;
      end if;
    end if;

    -- 03. Verificar se gondola ja existe
    select count(*)
      into vicontador
      from pcgondolac
     where numcontagem = p_reggondolac.numcontagem
       and codusur = p_reggondolac.codusur
       and codcli = p_reggondolac.codcli;

    if vicontador <> 0 then
      if vsmensagem is not null then
        vschar := '#';
      else
        vschar := null;
      end if;
      vsmensagem           := vsmensagem || vschar ||
                              'GONDOLA JA INFORMADA;';
      p_reggondolac.valido := false;
    end if;


    -- registra log
    if (vsmensagem is not null) then
      proc_registralog(null,
                       null,
                       null,
                       null,
                       p_reggondolac.cgccli,
                       null,
                       null,
                       p_reggondolac.numcontagem,
                       p_reggondolac.codusur,
                       null,
                       null,
                       '6',
                       vsmensagem,
                       null);
    end if;
  exception
    when others then
      p_reggondolac.valido := false;
      proc_registralog(null,
                       null,
                       null,
                       null,
                       p_reggondolac.cgccli,
                       null,
                       null,
                       p_reggondolac.numcontagem,
                       p_reggondolac.codusur,
                       null,
                       null,
                       '6',
                       sqlcode || '-' || sqlerrm||';',
                       null);
  end proc_validargondolac;

  procedure proc_validargondolai(p_reggondolai in out t_gondolai,
                                 p_reggondolac in     t_gondolac) is
    vsmensagem      varchar2(32767) := null;
    vschar          varchar2(1) default '#';
    vicontador      number;


  begin
    p_reggondolai.valido := true;
    p_reggondolai.codcli := p_Reggondolac.codcli;
    vsmensagem           := null;

    -- 01. Verificar Produto
    select count(*)
      into vicontador
      from pcprodut
     where codprod = p_reggondolai.codprod;

    if vicontador = 0 then
      if vsmensagem is not null then
        vschar := '#';
      else
        vschar := null;
      end if;
      vsmensagem           := vsmensagem || vschar ||
                              'PRODUTO NAO CADASTRADO;';
      p_reggondolai.valido := false;
    end if;

    -- registra log
    if (vsmensagem is not null) then
      proc_registralog(null,
                       null,
                       p_reggondolai.codprod ,
                       null,
                       p_reggondolac.cgccli,
                       null,
                       null,
                       p_reggondolai.numcontagem,
                       p_reggondolac.codusur,
                       null,
                       null,
                       '7',
                       vsmensagem,
                       null);
    end if;
  exception
    when others then
      p_reggondolai.valido := false;
      proc_registralog(null,
                       null,
                       p_reggondolai.codprod ,
                       null,
                       p_reggondolac.cgccli,
                       null,
                       null,
                       p_reggondolai.numcontagem,
                       p_reggondolac.codusur,
                       null,
                       null,
                       '7',
                       sqlcode || '-' || sqlerrm,
                       null);
  end proc_validargondolai;

procedure proc_validarcotacao(p_regcotacao in out t_cotacao) is
    vsmensagem      varchar2(32767);
    vschar          varchar2(1) default '#';
    vicontador      number;
    vncodclienteaux pcclient.codcli%type;
    vscgccli        pcclient.cgcent%type;
  begin
    p_regcotacao.valido := true;
    vncodclienteaux     := 0;
    vsmensagem          := null;

    --verifica se cliente existe
          --01. Verificar se o Cliente esta Cadastrado
       vscgccli :=   FERRAMENTAS.SONUMEROS(p_regcotacao.cgccli);

      select count(*)
        into vicontador
        from pcclient
       where  FERRAMENTAS.SONUMEROS(cgcent) = vscgccli
      and dtexclusao is null    ;

      if vicontador = 0 then
        if vsmensagem is not null then
          vschar := '#';
        else
          vschar := null;
        end if;
        vsmensagem           := vsmensagem || vschar ||
                                'CLIENTE NAO CADASTRADO OU EXCLUIDO;';
        p_regcotacao.valido := false;

      elsif vicontador = 1 then


          select codcli
            into p_regcotacao.codcli
            from pcclient
           where FERRAMENTAS.SONUMEROS(cgcent) = vscgccli
          and dtexclusao is  null    ;


      else


         if p_regcotacao.codcli is null then

              if vsmensagem is not null then
                vschar := '#';
              else
                vschar := null;
              end if;
              vsmensagem           := vsmensagem || vschar ||
                                      'ENCONTRADO MAIS DE UM CLIENTE PARA ESTE CNPJ/CPF;';
              p_regcotacao.valido := false;

          else
               begin
                select codcli
                  into p_regcotacao.codcli
                  from pcclient
                 where FERRAMENTAS.SONUMEROS(cgcent) = vscgccli
                and dtexclusao is  null
                and pcclient.codcli = p_regcotacao.codcli   ;
                exception when others then

                  if vsmensagem is not null then
                    vschar := '#';
                  else
                    vschar := null;
                  end if;
                  vsmensagem           := vsmensagem || vschar ||
                                          'ERRO AO BUSCAR CLIENTE DA VISITA;';
                  p_regcotacao.valido := false;

                end;


          end if;


      end if;



    -- Verifica se Produto existe.
    select count(*) into vicontador from pcprodut where codprod = p_regcotacao.codprod;

    if vicontador = 0
    then
      if vsmensagem is not null
      then
        vschar := '#';
      else
        vschar := null;
      end if;

      vsmensagem          := vsmensagem || vschar || 'Produto nao cadastrado.';
      p_regcotacao.valido := false;

    else

       if nvl(p_regcotacao.codauxiliar,0) <> 0 then
       
      
          begin
             select count(*) 
             into vicontador 
             from pcembalagem 
             where codprod = p_regcotacao.codprod 
             and codauxiliar = p_regcotacao.codauxiliar;

          end;
          
          if vicontador = 0 then
          
            select count(*)
            into vicontador
            from pcprodut
            where codprod = p_regcotacao.codprod
            and   codauxiliar = p_regcotacao.codauxiliar;
          
          end if;

              if vicontador = 0
              then
                if vsmensagem is not null
                then
                  vschar := '#';
                else
                  vschar := null;
                end if;

                vsmensagem          := vsmensagem || vschar || 'Produto nao cadastrado com este codauxiliar.';
                p_regcotacao.valido := false;

               end if;


       end if;

    end if;


   -- Verifica se RCA existe
   select count(*)
   into vicontador
   from pcusuari
   where codusur = p_regcotacao.codusur;

    if vicontador = 0
    then
      if vsmensagem is not null
      then
        vschar := '#';
      else
        vschar := null;
      end if;

      vsmensagem          := vsmensagem || vschar || 'RCA nao cadastrado.';
      p_regcotacao.valido := false;
    end if;

    -- Verifica se Concorrente existe.
    select count(*)
    into vicontador
    from pcconcor
    where trim(codconc) = p_regcotacao.codconc;

    if vicontador = 0
    then
      if vsmensagem is not null
      then
        vschar := '#';
      else
        vschar := null;
      end if;

      vsmensagem          := vsmensagem || vschar || 'Concorrente nao cadastrado.';
      p_regcotacao.valido := false;
    end if;


    -- Busca Prazo do Plano de Pagamento
    select count(*) into vicontador from pcplpag where codplpag = p_regcotacao.codplpag;

    if vicontador > 0
    then
      select numdias
      into p_regcotacao.prazo
      from pcplpag
      where codplpag = p_regcotacao.codplpag;
    else
      begin
        -- Busca Prazo do Plano de Pagamento do Cliente
        select pcclient.codplpag,
               pcplpag.numdias
        into p_regcotacao.codplpag,
             p_regcotacao.prazo
        from pcclient,
             pcplpag
        where pcclient.codcli = p_regcotacao.codcli
              and pcclient.codplpag = pcplpag.codplpag;
      exception
        when others then
          if vsmensagem is not null
          then
            vschar := '#';
          else
            vschar := null;
          end if;

          vsmensagem          := vsmensagem || vschar ||
                                 'Prazo do Plano nao localizado.';
          p_regcotacao.valido := false;
      end;
    end if;

    -- Verifica se Regiao existe.
    if NVL(p_regcotacao.numregiao, 0) = 0  then
      select count(*)
      into vicontador
      from pcclient,
           pcpraca
      where pcclient.codcli = p_regcotacao.codcli
            and pcclient.codpraca = pcpraca.codpraca;

      if vicontador > 0
      then
        select pcpraca.numregiao
        into p_regcotacao.numregiao
        from pcclient,
             pcpraca
        where pcclient.codcli = p_regcotacao.codcli
              and pcclient.codpraca = pcpraca.codpraca;
      else
        if vsmensagem is not null
        then
          vschar := '#';
        else
          vschar := null;
        end if;

        vsmensagem          := vsmensagem || vschar || 'Regiao nao localizada.';
        p_regcotacao.valido := false;
      end if;
    end if;

    -- Busca Custos do Produto
    begin
      select NVL(pcest.custofin, 0),
             NVL(pcest.custoreal, 0)
      into p_regcotacao.custofin,
           p_regcotacao.custoreal
      from pcest
      where pcest.codfilial = p_regcotacao.codfilial
            and pcest.codprod = p_regcotacao.codprod;
    exception
      when others then
        if vsmensagem is not null
        then
          vschar := '#';
        else
          vschar := null;
        end if;

        vsmensagem          := vsmensagem || vschar ||
                               'Custos do Produto nao localizados.';
        p_regcotacao.valido := false;
    end;

    -- Verifica se Cotacao ja existe.
    select count(*)
    into vicontador
    from pccota
    where codcli = p_regcotacao.codcli
          and codprod = p_regcotacao.codprod
          and pccota.codconc = p_regcotacao.codconc
          and pccota.codusur = p_regcotacao.codusur
          and pccota.DATA = p_regcotacao.data;

    if vicontador > 0
    then
      if vsmensagem is not null
      then
        vschar := '#';
      else
        vschar := null;
      end if;

      vsmensagem          := vsmensagem || vschar || 'Cotacao ja cadastrada.';
      p_regcotacao.valido := false;
    end if;

    -- registra log
    if (vsmensagem is not null)
    then
      proc_registralog(null
                      ,null
                      ,p_regcotacao.codprod
                      ,p_regcotacao.codauxiliar
                      ,p_regcotacao.cgccli
                      ,null
                      ,p_regcotacao.codconc
                      ,p_regcotacao.numseq
                      ,p_regcotacao.codusur
                      ,p_regcotacao.DATA
                      ,null
                      ,'13'
                      ,vsmensagem
                      ,null);
    end if;
  exception
    when others then
      p_regcotacao.valido := false;
      proc_registralog(null
                      ,null
                      ,p_regcotacao.codprod
                      ,p_regcotacao.codauxiliar
                      ,p_regcotacao.cgccli
                      ,null
                      ,p_regcotacao.codconc
                      ,p_regcotacao.numseq
                      ,p_regcotacao.codusur
                      ,p_regcotacao.DATA
                      ,null
                      ,'13'
                      ,sqlcode || '-' || sqlerrm
                      ,null);
  end proc_validarcotacao;

procedure proc_validarmensagem(p_regmensagem    in out t_mens
                                 ) is
    vsmensagem varchar2(32767):= null;
    vschar     varchar2(1) default '#';
    vicontador number;
    vsnome     pcusuari.nome%type;

  begin

    p_regmensagem.valido := true;
    p_regmensagem.codfuncab := 8888;
    p_Regmensagem.dtab  := sysdate;

    vsmensagem           := null;

    -- Verifica se Destinatario existe.
    select count(*)
      into vicontador
      from pcempr
     where matricula = p_regmensagem.codfuncdest;

    if vicontador = 0 then
      if vsmensagem is not null then
        vschar := '#';
      else
        vschar := null;
      end if;
      vsmensagem           := vsmensagem || vschar ||
                              'DESTINATARIO NAO LOCALIZADO;';
      p_regmensagem.valido := false;
    else

      select pcempr.codsetor
        into p_regmensagem.codsetordest
        from pcempr
       where pcempr.matricula = p_regmensagem.codfuncdest;

    end if;

    --2. Verificar remetente
    select count(*)
      into vicontador
      from pcempr
     where pcempr.matricula = p_regmensagem.codfuncab;

    if vicontador <> 0 then
      select pcempr.codsetor
        into p_regmensagem.codsetororig
        from pcempr
       where pcempr.matricula = p_regmensagem.codfuncab;
    end if;

    -- 3. Verificar se recado ja existe
    select count(*)
      into vicontador
      from pcrecfunc
     where numrecadofv = p_regmensagem.numrecadofv
       and codusur = p_regmensagem.codusur;

    if vicontador <> 0 then
      p_regmensagem.valido := false;
      if vsmensagem is not null then
        vschar := '#';
      else
        vschar := null;
      end if;
      vsmensagem           := vsmensagem || vschar ||
                              'MENSAGEM JA INCLUIDA ANTERIORMENTE.;';
      p_regmensagem.valido := false;
    end if;


    -- registra log
    if (vsmensagem is not null) then
      proc_registralog(null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       p_regmensagem.numrecadofv,
                       null,
                       null,
                       null,
                       null,
                       '5',
                       vsmensagem,
                       null);
    end if;
  exception
    when others then
      p_regmensagem.valido := false;
      proc_registralog(null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       p_regmensagem.numrecadofv,
                       null,
                       null,
                       null,
                       null,
                       '5',
                       sqlcode || '-' || sqlerrm||';',
                       null);

  end proc_validarmensagem;
  
  procedure proc_reorganizarotacli(p_regcliente in t_cliente) is

    vicont              number;
    vnsequencia         pcrotacli.sequencia%type;
    vsreordenaseqvisita varchar2(1);

  begin

    begin

      select nvl(p.valor, 'N')
        into vsreordenaseqvisita
        from pcparamfilial p
       where p.nome = 'REORDENASEQVISITA'
         and p.codfilial = '99';
    exception
      when others then
        vsreordenaseqvisita := 'N';

    end;

    --verifica se na rota do rca para o numero da semana, existe algum cliente para a sequencia enviada
    --Alterado para reordenar como a 354
    /*select count(*)
    into vicont
    from pcrotacli p
    where p.codusur = p_regcliente.codusur1
    and   p.dtproxvisita = trunc(sysdate) + p_regcliente.periodicidade
    and   p.sequencia = p_regcliente.sequencia;*/

    SELECT COUNT(*)
      INTO VICONT
      FROM PCROTACLI
     WHERE CODUSUR = p_regcliente.codusur1
       AND DIASEMANA = p_regcliente.diasemana
       AND NUMSEMANA = p_regcliente.numsemana;

    if vicont <> 0 and vsreordenaseqvisita = 'S' then

      vnsequencia := p_regcliente.sequencia;



      FOR REG IN (SELECT PCROTACLI.ROWID,
                         PCROTACLI.CODUSUR,
                         PCROTACLI.CODCLI,
                         PCROTACLI.DIASEMANA,
                         PCROTACLI.SEQUENCIA,
                         PCROTACLI.NUMSEMANA
                    FROM PCROTACLI, PCCLIENT
                   WHERE PCROTACLI.CODUSUR = p_regcliente.codusur1
                     AND PCROTACLI.CODCLI = PCCLIENT.CODCLI(+)
                     AND PCROTACLI.DIASEMANA = p_regcliente.diasemana
                     AND PCROTACLI.NUMSEMANA = p_regcliente.numsemana
                     AND   PCROTACLI.SEQUENCIA >= vnsequencia
                   ORDER BY PCROTACLI.SEQUENCIA) LOOP

        VNSEQUENCIA := VNSEQUENCIA + 1;

        UPDATE PCROTACLI P
           SET SEQUENCIA = VNSEQUENCIA
         WHERE P.ROWID = REG.ROWID;

      END LOOP;

      /* for reg in (select rowid
                 from pcrotacli p
                 where p.codusur = p_Regcliente.codusur1
                 and   p.dtproxvisita = trunc(sysdate) + p_regcliente.periodicidade
                 and   p.sequencia >= p_regcliente.sequencia
                 order by sequencia) loop


           vnsequencia := vnsequencia + 1;

           update pcrotacli p
           set sequencia = vnsequencia
           where p.rowid = reg.rowid;

      end loop;   */

    end if;

    select count(*)
      into vicont
      from pcrotacli p
     where p.codcli = p_regcliente.codcli
       and p.codusur = p_Regcliente.codusur1;

    if p_regcliente.tipooperacao = 'I' or vicont = 0 then

      begin
        insert into pcrotacli
          (codusur,
           diasemana,
           codcli,
           sequencia,
           periodicidade,
           dtproxvisita,
           numsemana,
           dtinicio,
           dtfinal)
        values
          (p_regcliente.codusur1,
           p_regcliente.diasemana,
           p_regcliente.codcli,
           p_regcliente.sequencia,
           p_regcliente.periodicidade,
           trunc(sysdate) + p_regcliente.periodicidade,
           p_regcliente.numsemana,
           trunc(sysdate),
           (trunc(sysdate) + 365));

      exception
        when others then

          proc_registralog(null,
                           null,
                           null,
                           null,
                           p_regcliente.cgcent,
                           null,
                           null,
                           null,
                           null,
                           null,
                           null,
                           '-1',
                           'ERRO AO GRAVAR ROTA DE CLIENTE#' || sqlcode || '-' ||
                           sqlerrm || ';',
                           null);

      end;

    else

      begin

        update pcrotacli
           set diasemana     = nvl(p_regcliente.diasemana, diasemana),
               numsemana     = nvl(p_regcliente.numsemana, numsemana),
               sequencia     = nvl(p_regcliente.sequencia, sequencia),
               periodicidade = nvl(p_regcliente.periodicidade, periodicidade)
         where codcli = p_regcliente.codcli
           and codusur = p_regcliente.codusur1;

      exception
        when others then

          proc_registralog(null,
                           null,
                           null,
                           null,
                           p_regcliente.cgcent,
                           null,
                           null,
                           null,
                           null,
                           null,
                           null,
                           '-1',
                           'ERRO AO ATUALIZAR ROTA DE CLIENTE#' || sqlcode || '-' ||
                           sqlerrm || ';',
                           null);

      end;

    end if;

  end proc_reorganizarotacli;

procedure inserir_logaltcli(p_regcliente in t_cliente, nomeCampo varchar2, valorAnt varchar2, valorNovo varchar2) is
begin
  if nvl(valorAnt, '') <> nvl(valorNovo, '')then
    insert into pclogaltcli
        (matricula, codcli, dtalteracao, rotina, campo, valorant, valoratu)
    values
        (8888, p_regcliente.codcli, sysdate, 'FORCA DE VENDAS', nomeCampo, valorAnt, valorNovo);
  end if;
end;

procedure pr_log_alteracao_cliente(p_regcliente in t_cliente) is
begin
  for cliente_ant in (select fantasia,
       enderent,
       numeroent,
       complementoent,
       bairroent,
       telent,
       municent,
       estent,
       cepent,
       paisent,
       pontorefer,
       endercob,
       numerocob,
       complementocob,
       bairrocob,
       telcob,
       municcob,
       estcob,
       cepcob,
       endercom,
       numerocom,
       complementocom,
       bairrocom,
       telcom,
       municcom,
       estcom,
       cepcom,
       faxcom,
       faxcli,
       obs,
       obs2,
       obs3,
       obs4,
       obs5,
       obscredito,
       telent1,
       email,
       caixapostal,
       obsentrega1,
       obsentrega2,
       obsentrega3,
       obsentrega4,
       numbanco1,
       numagencia1,
       numccorrente1,
       numbanco2,
       numagencia2,
       numccorrente2,
       qtcheckout,
       site,
       obsgerencial1,
       obsgerencial2,
       obsgerencial3,
       latitude,
       longitude,
       datacoleta,
       codcob,
       codplpag,
       emailnfe,
       codcidade,
       codfilialnf,
       consumidorfinal,
       contribuinte,
       clientprotesto,
       envionfeemailcom,
       codpais,
       codatv1,
       codfuncultalter,
       dtultalter,
       horacadastro,
       codmunicipio,
       simplesnacional,
       rg,
       ORGAORG,
       fretedespacho,
       telcelent,
       calculast,
       clientefontest
  from pcclient
 where codcli = p_regcliente.codcli) loop
    inserir_logaltcli(p_regcliente, 'FANTASIA', cliente_ant.fantasia, p_regcliente.fantasia);
    inserir_logaltcli(p_regcliente, 'ENDERENT', cliente_ant.enderent, p_regcliente.enderent);
    inserir_logaltcli(p_regcliente, 'NUMEROENT', cliente_ant.numeroent, p_regcliente.numeroent);
    inserir_logaltcli(p_regcliente, 'COMPLEMENTOENT', cliente_ant.complementoent, p_regcliente.complementoent);
    inserir_logaltcli(p_regcliente, 'BAIRROENT', cliente_ant.bairroent, p_regcliente.bairroent);
    inserir_logaltcli(p_regcliente, 'TELENT', cliente_ant.telent, p_regcliente.telent);
    inserir_logaltcli(p_regcliente, 'MUNICENT', cliente_ant.municent, p_regcliente.municent);
    inserir_logaltcli(p_regcliente, 'ESTENT', cliente_ant.estent, p_regcliente.estent);
    inserir_logaltcli(p_regcliente, 'CEPENT', cliente_ant.cepent, p_regcliente.cepent);
    inserir_logaltcli(p_regcliente, 'PAISENT', cliente_ant.paisent, p_regcliente.paisent);
    inserir_logaltcli(p_regcliente, 'PONTOREFER', cliente_ant.pontorefer, p_regcliente.pontorefer);
    inserir_logaltcli(p_regcliente, 'ENDERCOB', cliente_ant.endercob, p_regcliente.endercob);
    inserir_logaltcli(p_regcliente, 'NUMEROCOB', cliente_ant.numerocob, p_regcliente.numerocob);
    inserir_logaltcli(p_regcliente, 'COMPLEMENTOCOB', cliente_ant.complementocob, p_regcliente.complementocob);
    inserir_logaltcli(p_regcliente, 'BAIRROCOB', cliente_ant.bairrocob, p_regcliente.bairrocob);
    inserir_logaltcli(p_regcliente, 'TELCOB', cliente_ant.telcob, p_regcliente.telcob);
    inserir_logaltcli(p_regcliente, 'MUNICCOB', cliente_ant.municcob, p_regcliente.municcob);
    inserir_logaltcli(p_regcliente, 'ESTCOB', cliente_ant.estcob, p_regcliente.estcob);
    inserir_logaltcli(p_regcliente, 'CEPCOB', cliente_ant.cepcob, p_regcliente.cepcob);
    inserir_logaltcli(p_regcliente, 'ENDERCOM', cliente_ant.endercom, p_regcliente.endercom);
    inserir_logaltcli(p_regcliente, 'NUMEROCOM', cliente_ant.numerocom, p_regcliente.numerocom);
    inserir_logaltcli(p_regcliente, 'COMPLEMENTOCOM', cliente_ant.complementocom, p_regcliente.complementocom);
    inserir_logaltcli(p_regcliente, 'BAIRROCOM', cliente_ant.bairrocom, p_regcliente.bairrocom);
    inserir_logaltcli(p_regcliente, 'TELCOM', cliente_ant.telcom, p_regcliente.telcom);
    inserir_logaltcli(p_regcliente, 'MUNICCOM', cliente_ant.municcom, p_regcliente.municcom);
    inserir_logaltcli(p_regcliente, 'ESTCOM', cliente_ant.estcom, p_regcliente.estcom);
    inserir_logaltcli(p_regcliente, 'CEPCOM', cliente_ant.cepcom, p_regcliente.cepcom);
    inserir_logaltcli(p_regcliente, 'FAXCOM', cliente_ant.faxcom, p_regcliente.faxcom);
    inserir_logaltcli(p_regcliente, 'FAXCLI', cliente_ant.faxcli, p_regcliente.faxcli);
    inserir_logaltcli(p_regcliente, 'OBS', cliente_ant.obs, p_regcliente.obs);
    inserir_logaltcli(p_regcliente, 'OBS2', cliente_ant.obs2, p_regcliente.obs2);
    inserir_logaltcli(p_regcliente, 'OBS3', cliente_ant.obs3, p_regcliente.obs3);
    inserir_logaltcli(p_regcliente, 'OBS4', cliente_ant.obs4, p_regcliente.obs4);
    inserir_logaltcli(p_regcliente, 'OBS5', cliente_ant.obs5, p_regcliente.obs5);
    inserir_logaltcli(p_regcliente, 'OBSCREDITO', cliente_ant.obscredito, p_regcliente.obscredito);
    inserir_logaltcli(p_regcliente, 'TELENT1', cliente_ant.telent1, p_regcliente.telent1);
    inserir_logaltcli(p_regcliente, 'EMAIL', cliente_ant.email, p_regcliente.email);
    inserir_logaltcli(p_regcliente, 'CAIXAPOSTAL', cliente_ant.caixapostal, p_regcliente.caixapostal);
    inserir_logaltcli(p_regcliente, 'OBSENTREGA1', cliente_ant.obsentrega1, p_regcliente.obsentrega1);
    inserir_logaltcli(p_regcliente, 'OBSENTREGA2', cliente_ant.obsentrega2, p_regcliente.obsentrega2);
    inserir_logaltcli(p_regcliente, 'OBSENTREGA3', cliente_ant.obsentrega3, p_regcliente.obsentrega3);
    inserir_logaltcli(p_regcliente, 'OBSENTREGA4', cliente_ant.obsentrega4, p_regcliente.obsentrega4);
    inserir_logaltcli(p_regcliente, 'NUMBANCO1', cliente_ant.numbanco1, p_regcliente.numbanco1);
    inserir_logaltcli(p_regcliente, 'NUMAGENCIA1', cliente_ant.numagencia1, p_regcliente.numagencia1);
    inserir_logaltcli(p_regcliente, 'NUMCCORRENTE1', cliente_ant.numccorrente1, p_regcliente.numccorrente1);
    inserir_logaltcli(p_regcliente, 'NUMBANCO2', cliente_ant.numbanco2, p_regcliente.numbanco2);
    inserir_logaltcli(p_regcliente, 'NUMAGENCIA2', cliente_ant.numagencia2, p_regcliente.numagencia2);
    inserir_logaltcli(p_regcliente, 'NUMCCORRENTE2', cliente_ant.numccorrente2, p_regcliente.numccorrente2);
    inserir_logaltcli(p_regcliente, 'QTCHECKOUT', cliente_ant.qtcheckout, p_regcliente.qtcheckout);
    inserir_logaltcli(p_regcliente, 'SITE', cliente_ant.site, p_regcliente.site);
    inserir_logaltcli(p_regcliente, 'OBSGERENCIAL1', cliente_ant.obsgerencial1, p_regcliente.obsgerencial1);
    inserir_logaltcli(p_regcliente, 'OBSGERENCIAL2', cliente_ant.obsgerencial2, p_regcliente.obsgerencial2);
    inserir_logaltcli(p_regcliente, 'OBSGERENCIAL3', cliente_ant.obsgerencial3, p_regcliente.obsgerencial3);
    inserir_logaltcli(p_regcliente, 'LATITUDE', cliente_ant.latitude, p_regcliente.latitude);
    inserir_logaltcli(p_regcliente, 'LONGITUDE', cliente_ant.longitude, p_regcliente.longitude);
    inserir_logaltcli(p_regcliente, 'DATACOLETA', cliente_ant.datacoleta, p_regcliente.datacoleta);
    inserir_logaltcli(p_regcliente, 'CODCOB', cliente_ant.codcob, p_regcliente.codcob);
    inserir_logaltcli(p_regcliente, 'CODPLPAG', to_char(cliente_ant.codplpag), to_char(p_regcliente.codplpag));
    inserir_logaltcli(p_regcliente, 'EMAILNFE', cliente_ant.emailnfe, p_regcliente.emailnfe);
    inserir_logaltcli(p_regcliente, 'CODCIDADE', to_char(cliente_ant.codcidade), to_char(p_regcliente.codcidade));
    inserir_logaltcli(p_regcliente, 'CODFILIALNF', cliente_ant.codfilialnf, p_regcliente.codfilialnf);
    inserir_logaltcli(p_regcliente, 'CONSUMIDORFINAL', cliente_ant.consumidorfinal, p_regcliente.consumidorfinal);
    inserir_logaltcli(p_regcliente, 'CONTRIBUINTE', cliente_ant.contribuinte, p_regcliente.contribuinte);
    inserir_logaltcli(p_regcliente, 'CLIENTPROTESTO', cliente_ant.clientprotesto, p_regcliente.clientprotesto);
    inserir_logaltcli(p_regcliente, 'ENVIONFEEMAILCOM', cliente_ant.envionfeemailcom, p_regcliente.envionfeemailcom);
    inserir_logaltcli(p_regcliente, 'CODPAIS', to_char(cliente_ant.codpais), to_char(p_regcliente.codpais));
    inserir_logaltcli(p_regcliente, 'CODATV1', to_char(cliente_ant.codatv1), to_char(p_regcliente.codatv1));
    inserir_logaltcli(p_regcliente, 'CODMUNICIPIO', to_char(cliente_ant.codmunicipio), to_char(p_regcliente.codcidadeibge));
    inserir_logaltcli(p_regcliente, 'SIMPLESNACIONAL', cliente_ant.simplesnacional, p_regcliente.simplesnacional);
    inserir_logaltcli(p_regcliente, 'RG  ', cliente_ant.rg, p_regcliente.rg);
    inserir_logaltcli(p_regcliente, 'ORGAORG', cliente_ant.ORGAORG, p_regcliente.ORGAORG);
    inserir_logaltcli(p_regcliente, 'FRETEDESPACHO', cliente_ant.fretedespacho, p_regcliente.fretedespacho);
    inserir_logaltcli(p_regcliente, 'TELCELENT', cliente_ant.telcelent, p_regcliente.telcelent);
    inserir_logaltcli(p_regcliente, 'CALCULAST', cliente_ant.calculast, p_regcliente.calculast);
    inserir_logaltcli(p_regcliente, 'CLIENTEFONTEST', cliente_ant.clientefontest, p_regcliente.clientefontest);
  
  end loop;
end;

function func_inserircliente(p_regcliente in t_cliente) return boolean is

  begin
    begin

      if p_regcliente.tipooperacao = 'I' then

      insert into pcclient
        ( cgcent,	--1
          cliente,	--2
          fantasia,	--3
          ieent,	--4
          iment,	--5
          rg,	--6
          orgaorg,	--7
          codclipalm,	--8
          codatv1,	--9
          enderent,	--10
          numeroent,	--11
          complementoent,	--12
          bairroent,	--13
          telent,	--14
          municent,	--15
          estent,	--16
          cepent,	--17
          paisent,	--18
          pontorefer,	--19
          endercob,	--20
          numerocob,	--21
          complementocob,	--22
          bairrocob,	--23
          telcob,	--24
          municcob,	--25
          estcob,	--26
          cepcob,	--27
          endercom,	--28
          numerocom,	--29
          complementocom,	--30
          bairrocom,	--31
          telcom,	--32
          municcom,	--33
          estcom,	--34
          cepcom,	--35
          faxcom,	--36
          codusur1,	--37
          codusur2,	--38
          faxcli,	--39
          codpraca,	--40
          predioproprio,	--41
          obs,	--42
          obs2,	--43
          obs3,	--44
          obs4,	--45
          obscredito,	--46
          telent1,	--47
          email,	--48
          caixapostal,	--49
          obsentrega1,	--50
          obsentrega2,	--51
          obsentrega3,	--52
          obsentrega4,	--53
          numbanco1,	--54
          numagencia1,	--55
          numccorrente1,	--56
          numbanco2,	--57
          numagencia2,	--58
          numccorrente2,	--59
          qtcheckout,	--60
          site,	--61
          obsgerencial1,	--62
          obsgerencial2,	--63
          obsgerencial3,	--64
          latitude,	--65
          longitude,	--66
          datacoleta,	--67
          codcli,	--68
          tipofj,	--69
          numregiaocli,	--70
          dtcadastro, --71
          codcob, --72
          codplpag, --73
          limcred, --74
          bloqueio, --75
          dtbloq,            --76
          dtlancpotenciallimcred, --77
          vlpotenciallimcred, --78
          codfunccadastro,   --79
          codfunclancpotenciallimcred, --80
          condvenda1,        --81
          condvenda5,        --82
          codcliprinc,       --83
          emitedup,          --84
          vip,               --85
          prazoadicional,    --86
          perdescfin,        --87
          perdescisentoicms, --88
          icmsantecip,       --89
          isentoicms,        --90
          isentotxboleto,    --91
          emailnfe,          --92
          codcidade,         --93
          codfilialnf,       --94
          consumidorfinal,   --95
          contribuinte,      --96
          clientprotesto,    --97
          envionfeemailcom , --98
          condvenda10,       --99
          condvenda11,       --100
          condvenda13,       --101
          condvenda14,       --102
          condvenda20,       --103
          condvenda4,        --104
          condvenda7,        --105
          condvenda8,        --106
          condvenda9,        --107
          simplesnacional ,  --108
          codpais,           --109
          horacadastro,      --110 Adicionado conforme versão 22 da rotina 302
          codmunicipio,      --111
          fretedespacho,     --112
          telcelent,         --113 HIS.03111.2017
          calculast,         --114
          clientefontest,    --115
          dtnasc,            --116
          obs5,               --117
		  cgcentrega         --118
)
      values
        (  p_regcliente.cgcent,	--1
           upper(p_regcliente.cliente),	--2
           upper(p_regcliente.fantasia),	--3
           p_regcliente.ieent,	--4
           p_regcliente.iment,	--5
           p_regcliente.rg,	--6
           p_regcliente.orgaorg,	--7
           p_regcliente.codclipalm,	--8
           p_regcliente.codatv1,	--9
           upper(p_regcliente.enderent),	--10
           p_regcliente.numeroent,	--11
           upper(p_regcliente.complementoent),	--12
           upper(p_regcliente.bairroent),	--13
           p_regcliente.telent,	--14
           upper(p_regcliente.municent),	--15
           upper(p_regcliente.estent),	--16
           p_regcliente.cepent,	--17
           upper(p_regcliente.paisent),	--18
           upper(p_regcliente.pontorefer),	--19
           upper(p_regcliente.endercob),	--20
           p_regcliente.numerocob,	--21
           upper(p_regcliente.complementocob),	--22
           upper(p_regcliente.bairrocob),	--23
           p_regcliente.telcob,	--24
           upper(p_regcliente.municcob),	--25
           upper(p_regcliente.estcob),	--26
           p_regcliente.cepcob,	--27
           upper(p_regcliente.endercom),	--28
           p_regcliente.numerocom,	--29
           upper(p_regcliente.complementocom),	--30
           upper(p_regcliente.bairrocom),	--31
           p_regcliente.telcom,	--32
           upper(p_regcliente.municcom),	--33
           upper(p_regcliente.estcom),	--34
           p_regcliente.cepcom,	--35
           p_regcliente.faxcom,	--36
           p_regcliente.codusur1,	--37
           p_regcliente.codusur2,	--38
           p_regcliente.faxcli,	--39
           p_regcliente.codpraca,	--40
           upper(p_regcliente.predioproprio),	--41
           nvl(p_regcliente.obs, 'BLOQ. CADASTRO AUT. RCA'),	--42
           upper(p_regcliente.obs2),	--43
           upper(p_regcliente.obs3),	--44
           upper(p_regcliente.obs4),	--45
           upper(p_regcliente.obscredito),	--46
           p_regcliente.telent1,	--47
           p_regcliente.email,	--48
           p_regcliente.caixapostal,	--49
           upper(p_regcliente.obsentrega1),	--50
           upper(p_regcliente.obsentrega2),	--51
           upper(p_regcliente.obsentrega3),	--52
           upper(p_regcliente.obsentrega4),	--53
           p_regcliente.numbanco1,	--54
           p_regcliente.numagencia1,	--55
           p_regcliente.numccorrente1,	--56
           p_regcliente.numbanco2,	--57
           p_regcliente.numagencia2,	--58
           p_regcliente.numccorrente2,	--59
           p_regcliente.qtcheckout,	--60
           upper(p_regcliente.site),	--61
           upper(p_regcliente.obsgerencial1),	--62
           upper(p_regcliente.obsgerencial2),	--63
           upper(p_regcliente.obsgerencial3),	--64
           p_regcliente.latitude,	--65
           p_regcliente.longitude,	--66
           p_regcliente.datacoleta,	--67
           p_regcliente.codcli,	--68
           p_regcliente.tipofj,	--69
           p_regcliente.numregiaocli,	--70
           sysdate, --71 retirado o trunc, conforme versão 22 da rotina 302
           p_regcliente.codcob, --72
           p_regcliente.codplpag, --73
           DECODE(p_regcliente.tipofj,'F',
                NVL(gregpcconsum.limcredinicialpf, 0),
                NVL(gregpcconsum.limcredinicial, 0)), --74
           p_Regcliente.bloqueio, --75
           DECODE(p_Regcliente.bloqueio, 'S', trunc(sysdate), null), --76
           trunc(sysdate), --77
           DECODE(p_regcliente.tipofj, 'F',
                NVL(gregpcconsum.limcredinicialpf, 0),
                NVL(gregpcconsum.limcredinicial, 0)), --78
           '8888', --79
           p_regcliente.codusur1, --80
           gregpcconsum.condvenda1, --81
           gregpcconsum.condvenda5, --82
           p_Regcliente.codcli, --83
          'N', --84
          'E', --85
           0,  --86
           0,  --87
           0, --88
          'N', --89
          'N', --90
          'N', --91
          p_regcliente.emailnfe, --92
          p_regcliente.codcidade,      --93
          p_regcliente.codfilialnf,    --94
          p_regcliente.consumidorfinal,  --95
          p_regcliente.contribuinte,     --96
          p_regcliente.clientprotesto,   --97
          p_regcliente.envionfeemailcom,  --98
          gregpcconsum.condvenda10,       --99
          gregpcconsum.condvenda11,        --100
          gregpcconsum.condvenda13,        --101
          gregpcconsum.condvenda14,        --102
          gregpcconsum.condvenda20,        --103
          gregpcconsum.condvenda4,         --104
          gregpcconsum.condvenda7,         --105
          gregpcconsum.condvenda8,         --106
          gregpcconsum.condvenda9,         --107
          p_regcliente.simplesnacional,    --108
          p_regcliente.codpais,            --109
          sysdate,                         --110
          p_regcliente.codcidadeibge,      -- 111
          p_regcliente.fretedespacho,      --112
          p_regcliente.telcelent,           --113 HIS.03111.2017
          p_regcliente.calculast,          --114
          p_regcliente.clientefontest,     --115
          p_regcliente.dtnasc,             --116
          upper(p_regcliente.obs5),        --117
		  p_regcliente.cgcentrega          --118  
           );

     else
       pr_log_alteracao_cliente(p_regcliente);

       update pcclient
       set    fantasia        = nvl(upper(p_regcliente.fantasia),fantasia),
              cliente         = nvl(upper(p_regcliente.cliente),cliente),
              enderent        = nvl(upper(p_regcliente.enderent),enderent),
              numeroent       = nvl(p_regcliente.numeroent,numeroent),
              complementoent  = nvl(upper(p_regcliente.complementoent),complementoent),
              bairroent       = nvl(upper(p_regcliente.bairroent),bairroent),
              telent          = nvl(p_regcliente.telent,telent),
              municent        = nvl(upper(p_regcliente.municent),municent),
              estent          = nvl(upper(p_regcliente.estent),estent),
              cepent          = nvl(p_regcliente.cepent,cepent),
              paisent         = nvl(upper(p_regcliente.paisent),paisent),
              pontorefer      = nvl(upper(p_regcliente.pontorefer),pontorefer),
              endercob        = nvl(upper(p_regcliente.endercob),endercob),
              numerocob       = nvl(p_regcliente.numerocob,numerocob),
              complementocob  = nvl(upper(p_Regcliente.complementocob),complementocob),
              bairrocob       = nvl(upper(p_regcliente.bairrocob),bairrocob),
              telcob          = nvl(p_regcliente.telcob,telcob),
              municcob        = nvl(upper(p_regcliente.municcob),municcob),
              estcob          = nvl(upper(p_regcliente.estcob),estcob),
              cepcob          = nvl(p_regcliente.cepcob,cepcob),
              endercom        = nvl(upper(p_regcliente.endercom),endercom),
              numerocom       = nvl(p_regcliente.numerocom,numerocom),
              complementocom  = nvl(upper(p_Regcliente.complementocom),complementocom),
              bairrocom       = nvl(upper(p_regcliente.bairrocom),bairrocom),
              telcom          = nvl(p_regcliente.telcom,telcom),
              municcom 	      = nvl(upper(p_regcliente.municcom),municcom),
              estcom          = nvl(upper(p_regcliente.estcom),estcom),
              cepcom          = nvl(p_regcliente.cepcom,cepcom),
              faxcom          = nvl(p_regcliente.faxcom,faxcom),
              faxcli          = nvl(p_regcliente.faxcli,faxcli),
              obs             = nvl(upper(p_regcliente.obs),obs),
              obs2            = nvl(upper(p_regcliente.obs2),obs2),
              obs3            = nvl(upper(p_regcliente.obs3),obs3),
              obs4            = nvl(upper(p_regcliente.obs4),obs4),
              obs5            = nvl(upper(p_regcliente.obs5),obs5),
              obscredito      = nvl(upper(p_regcliente.obscredito),obscredito),
              telent1         = nvl(p_regcliente.telent1,telent1),
              email           = nvl(p_regcliente.email,email),
              caixapostal     = nvl(p_regcliente.caixapostal,caixapostal),
              obsentrega1     = nvl(upper(p_regcliente.obsentrega1),obsentrega1),
              obsentrega2     = nvl(upper(p_regcliente.obsentrega2),obsentrega2),
              obsentrega3     = nvl(upper(p_regcliente.obsentrega3),obsentrega3),
              obsentrega4     = nvl(upper(p_regcliente.obsentrega4),obsentrega4),
              numbanco1       = nvl(p_regcliente.numbanco1,numbanco1),
              numagencia1     = nvl(p_regcliente.numagencia1,numagencia1),
              numccorrente1   = nvl(p_regcliente.numccorrente1,numccorrente1),
              numbanco2       = nvl(p_regcliente.numbanco2,numbanco2),
              numagencia2     = nvl(p_regcliente.numagencia2,numagencia2),
              numccorrente2   = nvl(p_regcliente.numccorrente2,numccorrente2),
              qtcheckout      = nvl(p_regcliente.qtcheckout,qtcheckout),
              site            = nvl(upper(p_regcliente.site),site),
              obsgerencial1   = nvl(upper(p_regcliente.obsgerencial1),obsgerencial1),
              obsgerencial2   = nvl(upper(p_regcliente.obsgerencial2),obsgerencial2),
              obsgerencial3   = nvl(upper(p_regcliente.obsgerencial3),obsgerencial3),
              latitude        = nvl(p_regcliente.latitude,latitude),
              longitude       = nvl(p_regcliente.longitude,longitude),
              datacoleta      = nvl(p_regcliente.datacoleta,datacoleta),
              codcob          = nvl(p_regcliente.codcob,codcob),
              codplpag        = nvl(p_regcliente.codplpag,codplpag),
              emailnfe        = nvl(p_regcliente.emailnfe,emailnfe),
              codcidade       = nvl(p_regcliente.codcidade,codcidade),
              codfilialnf     = nvl(p_regcliente.codfilialnf,codfilialnf),
              consumidorfinal = nvl(p_regcliente.consumidorfinal,consumidorfinal),
              contribuinte    = nvl(p_regcliente.contribuinte,contribuinte),
              clientprotesto  = nvl(p_regcliente.clientprotesto,clientprotesto),
              envionfeemailcom = nvl(p_regcliente.envionfeemailcom,envionfeemailcom),
              codpais          = nvl(p_regcliente.codpais,codpais),
              codatv1          = nvl(p_regcliente.codatv1,codatv1),
              codfuncultalter  = '8888',
              dtultalter       = trunc(sysdate),
              horacadastro     = sysdate,
              codmunicipio     = nvl(p_regcliente.codcidadeibge,codmunicipio),
              simplesnacional  = nvl(p_regcliente.simplesnacional, simplesnacional),
              rg               = nvl(p_regcliente.rg, rg),
              ORGAORG          = nvl(p_regcliente.ORGAORG, ORGAORG),
              fretedespacho    = nvl(p_regcliente.fretedespacho, fretedespacho),
              telcelent        = nvl(p_regcliente.telcelent, telcelent), --HIS.03111.2017
              calculast        = nvl(p_regcliente.calculast, calculast),
              clientefontest   = nvl(p_regcliente.clientefontest, clientefontest),
              codpraca         = nvl(p_regcliente.codpraca, codpraca),
              dtnasc           = nvl(p_regcliente.dtnasc, dtnasc),
			  cgcentrega       = p_regcliente.cgcentrega

       where codcli = p_regcliente.codcli;




     end if;

    if p_regcliente.diasemana is not null then 
   
         proc_reorganizarotacli(p_regcliente);
         
         
    end if;   
  

      insert into pclogaltcli
        (matricula, codcli, dtalteracao, rotina)
      values
        (8888, p_regcliente.codcli, sysdate, 'FORCA DE VENDAS');

      return true;
    exception
      when others then
        proc_registralog(null,
                         null,
                         null,
                         null,
                         p_regcliente.cgcent,
                         null,
                         null,
                         null,
                         null,
                         null,
                         null,
                         '-1',
                         'ERRO AO GRAVAR CLIENTE#' || sqlcode || '-' ||
                         sqlerrm || ';',
                         null);
        return false;
    end;
  end func_inserircliente;


function func_inserircontato(p_regcontato in t_contato) return boolean is

  begin
    begin



      insert into pccontato
        (codcontato, --1
         codcli,  --2
         nomecontato, --3
         tipocontato, --4
         cgccpf, --5
         dtnascimento, --6
         hobbie, --7
         time, --8
         nomeconjuge, --9
         dtnascconjuge, --10
         endereco, --11
         bairro, --12
         cidade, --13
         cep,  --14
         cargo, --15
         telefone, --16
         celular, --17
         email, --18
         estado, --19
         autorch --20
)
      values
        ( p_regcontato.codcontato, --1
          p_regcontato.codcli, --2
          upper(p_regcontato.nomecontato), --3
          p_regcontato.tipocontato,--4
          p_Regcontato.cgccpf, --5
          p_regcontato.dtnascimento, --6
          p_regcontato.hobbie, --7
          p_regcontato.time, --8
          p_Regcontato.nomeconjuge, --9
          p_regcontato.dtnascconjuge, --10
          p_regcontato.endereco, --11
          p_regcontato.bairro, --12
          p_regcontato.cidade,--13
          p_regcontato.cep, --14
          p_regcontato.cargo, --15
          p_regcontato.telefone, --16
          p_regcontato.celular, --17
          p_regcontato.email, --18
          p_regcontato.estado, --19
          'N' --20
                );




      return true;
    exception
      when others then
        proc_registralog(null,
                         null,
                         null,
                         null,
                         p_regcontato.cgccli,
                         null,
                         null,
                         null,
                         null,
                         null,
                         null,
                         '4',
                         'ERRO AO CONTATO#;' || sqlcode || '-' ||
                         sqlerrm || ';',
                         null);
        return false;
    end;
  end func_inserircontato;



  function func_inserirmensagem(p_regmensagem in out t_mens) return boolean is

    vnnumrecado    pcrecfunc.numrecado%type;
  begin

    select dfseq_pcrecfunc.nextval into vnnumrecado from DUAL;

    p_regmensagem.numrecado := vnnumrecado;

    insert into pcrecfunc
      (numrecado, --1
       codfuncab, --2
       dtab,      --3
       codsetororig, --4
       codsetordest, --5
       codfuncdest, --6
       assunto, --7
       textorecado, --8
       numrecadofv,--9
       codusur, --10
       comunicado--11
      )
    values
      (vnnumrecado, --1
       '8888',      --2
       p_regmensagem.dtab, --3
       nvl(p_regmensagem.codsetororig,0),     --4
       p_regmensagem.codsetordest, --5
       p_regmensagem.codfuncdest, --6
       p_regmensagem.assunto, --7
       p_regmensagem.textorecado, --8
       p_regmensagem.numrecadofv, --9
       p_regmensagem.codusur, --10
       'N' --11
      );

    return true;

  exception
    when others then
      proc_registralog(null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       p_regmensagem.numrecadofv,
                       null,
                       null,
                       null,
                       null,
                       '5',
                       'ERRO AO GRAVAR MENSAGEM #' || sqlcode || '-' ||
                       sqlerrm || ';',
                       null);
      return false;

  end func_inserirmensagem;

  function func_inserirgondola(p_reggondolac in t_gondolac) return boolean is
  begin

    insert into pcgondolac
      (numcontagem, --1
       dtcontagem,  --2
       codusur,     --3
       codcli,      --4
       codconc,     --5
       horainicial, --6
       horafinal,     --7
       numvisita      --8       
       )
    values
      (p_reggondolac.numcontagem, --1
       p_reggondolac.dtcontagem,  --2
       p_reggondolac.codusur,   --3
       p_reggondolac.codcli,     --4
       p_reggondolac.codconc,    --5
       p_reggondolac.horainicial,  --6
       p_reggondolac.horafinal,     --7
       p_reggondolac.numvisita      --8       
       );

    return true;

  exception
    when others then
      proc_registralog(null,
                       null,
                       null,
                       null,
                       p_reggondolac.cgccli,
                       null,
                       null,
                       p_reggondolac.numcontagem,
                       p_reggondolac.codusur,
                       null,
                       null,
                       '6',
                       'ERRO AO GRAVAR GONDOLA#' || sqlcode || '-' ||
                       sqlerrm || ';',
                       null);
      return false;
  end func_inserirgondola;

  function func_inseriritemgondola(p_reggondolai in t_gondolai)

    return boolean is
    vncodcli pcclient.codcli%type;

  begin


      insert into pcgondolai
        (numcontagem, --1
         codprod,     --2
         qt,          --3
         pvenda,      --4
         codcli,      --5
         codusur ,     --6
         qtperdas,     --7
         giromedio,    --8
         girosellout   --9  
         
         )
      values
        (p_reggondolai.numcontagem, --1
         p_reggondolai.codprod,     --2
         p_reggondolai.qt,          --3
         p_reggondolai.pvenda,      --4
         p_reggondolai.codcli,      --5
         p_reggondolai.codusur,      --6
         p_reggondolai.qtperdas,     --7
         p_reggondolai.giromedio,    --8
         p_reggondolai.girosellout   --9  
         
         );

      return true;


  exception
    when others then
      proc_registralog(null,
                       null,
                       null,
                       null,
                       p_reggondolai.cgccli,
                       null,
                       null,
                       p_reggondolai.numcontagem,
                       p_reggondolai.codusur,
                       null,
                       null,
                       '7',
                       'ERRO AO GRAVAR ITEM DA GONDOLA#' || sqlcode || '-' ||
                       sqlerrm || ';',
                       null);
      return false;

  end func_inseriritemgondola;



  function func_inserirvisita(p_regvisita in out t_visita
                             ) return boolean is

  vsmensagematurota            varchar2(1000);
  vbjustvalida                 boolean;
  vsutilizaroteirizacao        varchar2(1);
  vsatualizarotanomomentovenda varchar2(1);

  vscodfilial                  pcusuari.codfilial%type;

  begin


   select codfilial
   into vscodfilial
   from pcusuari
   where codusur = p_regvisita.codusur;


  -- tarefa 158674
   begin
      select nvl(p.valor,'N')
      into vsutilizaroteirizacao
      from pcparamfilial p
      where p.codfilial = '99'
      and   p.nome = 'UTILIZAROTEIRIZACAO';
      exception
     when no_Data_found  then 
      begin


        select nvl(p.valor,'N')
        into vsutilizaroteirizacao
        from pcparamfilial p
        where p.codfilial = vscodfilial
        and   p.nome = 'UTILIZAROTEIRIZACAO';
        exception 
         when no_data_found then
          vsutilizaroteirizacao := 'N';
         when others then
          vsutilizaroteirizacao := 'N'; 
      end; 
     
     when others then
      vsutilizaroteirizacao := 'N';

     end;



   begin
      select nvl(p.valor,'N')
      into vsatualizarotanomomentovenda
      from pcparamfilial p
      where p.codfilial = '99'
      and   p.nome = 'ATUALIZAROTANOMOMENTOVENDA';
      exception
     when no_Data_found then
       begin
          select nvl(p.valor,'N')
          into vsatualizarotanomomentovenda
          from pcparamfilial p
          where p.codfilial = vscodfilial
          and   p.nome = 'ATUALIZAROTANOMOMENTOVENDA';
       exception
       when no_Data_found then
            vsatualizarotanomomentovenda := 'N';
        when others then    
            vsatualizarotanomomentovenda := 'N';
       end;
      
     when others then
       vsatualizarotanomomentovenda := 'N';

     end;
     
     


  vbjustvalida := true;

    select dfseq_pcvisita.nextval into p_regvisita.codvisita from DUAL;

      if vsutilizaroteirizacao = 'S' and vsatualizarotanomomentovenda = 'S' then

       PRC_ATUALIZA_ROTA (vsutilizaroteirizacao,
                          vsatualizarotanomomentovenda,
                          p_regvisita.codcli,
                          p_regvisita.codusur,
                          'VIS',
                          null,
                          p_regvisita.DATA,
                          p_regvisita.codrota,
                          p_regvisita.codvisita,
                          p_regvisita.codmotivo,
                          vsmensagematurota,
                          vbjustvalida) ;

       if vsmensagematurota is not null then


       proc_registralog(null,
                       null,
                       null,
                       null,
                       p_regvisita.cgccli,
                       p_regvisita.codmotivo,
                       p_regvisita.hrinicial,
                       p_regvisita.minutoinicial,
                       p_regvisita.codusur,
                       p_regvisita.DATA,
                       null,
                       '8',
                       vsmensagematurota || ';',
                       null);

       end if;


    end if;



  if vbjustvalida = true then


    insert into pcvisita
      (codvisita,    --1
       codcli,       --2
       DATA,         --3
       codmotivo,    --4
       codoperadora, --5
       assunto,      --6
       hrinicial,    --7
       hrfinal,      --8
       minutoinicial, --9
       minutofinal,   --10
       codusur,       --11
       visitado,      --12
       tipooperacao   --13
       )
    values
      (p_regvisita.codvisita, --1
       p_regvisita.codcli,    --2
       p_regvisita.DATA,      --3
       p_regvisita.codmotivo, --4
       8888,                  --5
       p_regvisita.assunto,   --6
       p_regvisita.hrinicial,  --7
       p_regvisita.hrfinal,    --8
       p_regvisita.minutoinicial, --9
       p_regvisita.minutofinal, --10
       p_regvisita.codusur,     --11
       'S',                     --12
       'S'                      --13
       );

    return true;

   else

    return false;

   end if;
  exception
    when others then
      proc_registralog(null,
                       null,
                       null,
                       null,
                       p_regvisita.cgccli,
                       p_regvisita.codmotivo,
                       p_regvisita.hrinicial,
                       p_regvisita.minutoinicial,
                       p_regvisita.codusur,
                       p_regvisita.DATA,
                       null,
                       '8',
                       'ERRO AO GRAVAR VISITA#' || sqlcode || '-' ||
                       sqlerrm || ';',
                       null);
      return false;

  end func_inserirvisita;


function func_inserircliref(p_regcliref in out t_cliref) return boolean is
  begin


     insert into pccliref
     (codcli,           --1
      numseqrefer,      --2
      emprefer,         --3
      telrefer,         --4
      contatorefer,     --5
      limcredrefer,     --6
      dtcadastrorefer,  -- 7
      dtultcomprefer,   --8
      vlultcomprefer,   --9
      obs,              --10
      dtmaiorcomprefer,  --11
      vlmaiorcomprefer,  --12
      codcobrefer       --13

      )
     values
     (p_regcliref.codcli,        --1
      dfseq_pccliref.nextval,    --2
      p_regcliref.emprefer,      --3
      p_regcliref.telrefer,         --4
      p_regcliref.contatorefer,     --5
      p_regcliref.limcredrefer,     --6
      p_regcliref.dtcadastrorefer,  -- 7
      p_regcliref.dtultcomprefer,   --8
      p_regcliref.vlultcomprefer,   --9
      p_regcliref.obs,              --10
      p_regcliref.dtmaiorcomprefer,  --11
      p_regcliref.vlmaiorcomprefer,  --12
      p_regcliref.codcobrefer       --13


      );

      UPDATE  PCCLIREFFV SET IMPORTADO = 2, OBSERVACAO_PC = 'REFERENCIA DE CLIENTE IMPORTADO COM SUCESSO'
      WHERE PCCLIREFFV.CGCCLI = P_REGCLIREF.CGCCLI AND
            PCCLIREFFV.CODREF = P_REGCLIREF.CODREF;

    return true;
  exception
    when others then


      UPDATE  PCCLIREFFV SET IMPORTADO = 3, OBSERVACAO_PC = 'ERRO AO GRAVAR REFERENCIA DO CLIENTE'
      WHERE PCCLIREFFV.CGCCLI = P_REGCLIREF.CGCCLI AND
            PCCLIREFFV.CODREF = P_REGCLIREF.CODREF;

      proc_registralog(null,
                       null,
                       null,
                       null,
                       p_regcliref.cgccli,
                       null,
                       null,
                       null,
                       null,
                       null,
                       null,
                       '14',
                       'ERRO AO GRAVAR REFERENCIA DO CLIENTE#' || sqlcode || '-' ||
                       sqlerrm || ';',
                       null);
      return false;

  end func_inserircliref;

function func_inserircotacao(p_regcotacao in out t_cotacao) return boolean is
  begin
    select dfseq_pccota.nextval into p_regcotacao.codcotacao from DUAL;

    insert into pccota
      (codcotacao,
       codprod,
       codconc,
       codcli,
       punit,
       DATA,
       codusur,
       numregiao,
       codfilial,
       ptabela,
       codplpag,
       fonte,
       custofin,
       custoreal,
       prazo,
       datadoc,
       obs,
       precocon1,
       precocon2,
       precocon3,
       precocon4,
       precocon5,
       estoque,
       codauxiliar,
       lista,
       percmaxdescmercado,
       obs2,
       codprodconc)
    values
      (p_regcotacao.codcotacao,
       p_regcotacao.codprod,
       p_regcotacao.codconc,
       p_regcotacao.codcli,
       p_regcotacao.punit,
       p_regcotacao.data,
       p_regcotacao.codusur,
       p_regcotacao.numregiao,
       p_regcotacao.codfilial,
       p_regcotacao.ptabela,
       p_regcotacao.codplpag,
       'R',
       p_regcotacao.custofin,
       p_regcotacao.custoreal,
       p_regcotacao.prazo,
       p_regcotacao.datadoc,
       p_regcotacao.obs,
       p_regcotacao.precocon1,
       p_regcotacao.precocon2,
       p_regcotacao.precocon3,
       p_regcotacao.precocon4,
       p_regcotacao.precocon5,
       p_regcotacao.estoque,
       p_regcotacao.codauxiliar,
       p_regcotacao.lista,
       p_regcotacao.percmaxdescmercado,
       p_regcotacao.obs2,
       p_regcotacao.codprodconc);


    return true;
  exception
    when others then
      proc_registralog(null
                      ,null
                      ,p_regcotacao.codprod
                      ,p_regcotacao.codauxiliar
                      ,p_regcotacao.cgccli
                      ,null
                      ,p_regcotacao.codconc
                      ,p_regcotacao.numseq
                      ,p_regcotacao.codusur
                      ,p_regcotacao.DATA
                      ,null
                      ,'13'
                      ,';Erro ao gravar cotacao#;' || sqlcode || '-' || sqlerrm || '.'
                      ,null);
      return false;
  end func_inserircotacao;


procedure proc_processarclientes is
    vncontcli number;
  begin
    vncontcli := gvet_regcli.count;

    if vncontcli > 0 then

      for i in 1 .. vncontcli loop

        proc_validarcliente(gvet_regcli(i));
        BEGIN
          INSERT INTO pclogfv
          (arquivo, codcli, DATA, motivo, numped, numpedcli, numpedrca, status)
          VALUES
            ('PCCLIENTFV',
             gvet_regcli(i).codcli,
             SYSDATE,
             'Passou na Validação do cliente',
             NULL,
             NULL,
             NULL,
             'N');

        END;
        if gvet_regcli(i).valido = true then
            gvet_regcli(i).valido := func_inserircliente(gvet_regcli(i));
            BEGIN
              INSERT INTO pclogfv
              (arquivo, codcli, DATA, motivo, numped, numpedcli, numpedrca, status)
              VALUES
                ('PCCLIENTFV',
                 gvet_regcli(i).codcli,
                 SYSDATE,
                 'Passou na Inserção do cliente',
                 NULL,
                 NULL,
                 NULL,
                 'N');

            END;
          if gvet_regcli(i).valido = true then
            commit;
          else
            rollback;
          end if;

        else
          rollback;
        end if;

      end loop;
    end if;

  end proc_processarclientes;


procedure proc_processarcontatos is
    vncontcontato number;
  begin
    vncontcontato := gvet_regcontato.count;

    if vncontcontato > 0 then

      for i in 1 .. vncontcontato loop

        proc_validarcontato(gvet_regcontato(i));

        if gvet_regcontato(i).valido = true then
            gvet_regcontato(i).valido := func_inserircontato(gvet_regcontato(i));

          if gvet_regcontato(i).valido = true then
            commit;
          else
            rollback;
          end if;

        else
          rollback;
        end if;

      end loop;
    end if;

  end proc_processarcontatos;
  
procedure proc_processarmensagens is
    vncontmsg     number;
    vbmensvalida  boolean;
    vstextorecado varchar2(4000);

  begin
    vncontmsg     := gvet_regmens.count;

    if vncontmsg > 0 then

      for i in 1 .. vncontmsg loop

        proc_validarmensagem(gvet_regmens(i));

          if gvet_regmens(i).valido = true then

            gvet_regmens(i).valido := func_inserirmensagem(gvet_regmens(i));

            if gvet_regmens(i).valido = true then
              commit;
            else
              rollback;
            end if;

          end if;
      end loop;
    end if;

  end proc_processarmensagens;  

  procedure proc_processargondola is
    vncontgondc number;
    vncontgondi number;
    vicontador  number;
  begin

    vncontgondc := gvet_reggondolac.count;
    vncontgondi := gvet_reggondolai.count;

    if vncontgondc > 0 then
      for i in 1 .. vncontgondc loop
        proc_validargondolac(gvet_reggondolac(i));

        if gvet_reggondolac(i).valido = true then

           for j in 1 .. vncontgondi loop


               if gvet_reggondolac(i).numcontagem = gvet_reggondolai(j).numcontagem  and
                  gvet_reggondolac(i).cgccli      = gvet_reggondolai(j).cgccli  and
                  gvet_reggondolac(i).codusur     = gvet_reggondolai(j).codusur  then

               proc_validargondolai(gvet_reggondolai(j),gvet_reggondolac(i));

                 if gvet_reggondolai(j).valido = true then
                    gvet_reggondolai(j).valido := func_inseriritemgondola(gvet_reggondolai(j));
                 end if;
              end if;
           end loop;

           select count(*)
           into vicontador
           from pcgondolai
           where numcontagem = gvet_Reggondolac(i).numcontagem
           and   codcli      = gvet_reggondolac(i).codcli
           and   codusur     = gvet_reggondolac(i).codusur;

           if vicontador > 0 then

             gvet_reggondolac(i).valido := func_inserirgondola(gvet_reggondolac(i));

                if gvet_reggondolac(i).valido = true then
                  commit;
                else
                  rollback;
                end if;
           end if;


      else
          rollback;
      end if;
      end loop;
    end if;

  end proc_processargondola;




  procedure proc_processarvisitas is
    vncontvisita number;
  begin
    vncontvisita := gvet_regvisita.count;

    if vncontvisita > 0 then

      for i in 1 .. vncontvisita loop

        proc_validarvisita(gvet_regvisita(i));

        if gvet_regvisita(i).valido = true then
          gvet_regvisita(i).valido := func_inserirvisita(gvet_regvisita(i)   );

          if gvet_regvisita(i).valido = true then
            commit;
          else
            rollback;
          end if;
        end if;
      end loop;
    end if;

  end proc_processarvisitas;


procedure proc_processarcliref is
    vncontcliref number;
  begin
    vncontcliref := gvet_regcliref.count;

    if vncontcliref > 0 then

      for i in 1 .. vncontcliref loop

        proc_validarcliref(gvet_regcliref(i));

        if gvet_regcliref(i).valido = true then
          gvet_regcliref(i).valido := func_inserircliref(gvet_regcliref(i));

          if gvet_regcliref(i).valido = true then
            commit;
          else
            rollback;
          end if;
        end if;
      end loop;
    end if;

  end proc_processarcliref;

procedure proc_processarcotacoes is
    vncontcota number;
  begin
    vncontcota := gvet_regcotacao.count;

    if vncontcota > 0
    then
      for i in 1 .. vncontcota
      loop
        proc_validarcotacao(gvet_regcotacao(i));

        if gvet_regcotacao(i).valido = true
        then
          gvet_regcotacao(i).valido := func_inserircotacao(gvet_regcotacao(i));

          if gvet_regcotacao(i).valido = true
          then
            commit;
          else
            rollback;
          end if;
        end if;
      end loop;
    end if;
  end proc_processarcotacoes;
  
PROCEDURE proc_processaretornotab(p_existerro IN BOOLEAN) IS

    vncontlog                   number;
    vicontador                  number;
    vncontcli                   number;
    vncontcontato               number;
    vncontgondola               number;
    vncontitemgondola           number;
    vncontvisita                number;
    vncontcotacao               number;
    vncontcliref                number;
    vncontmens                  number;
    vsobservacaocli             varchar2(32767) := null;
    vsobservacaocontato         varchar2(32767) := null;
    vsobservacaogondola         varchar2(32767) := null;
    vsobservacaoitemgondola     varchar2(32767) := null;
    vsobservacaovisita          varchar2(32767) := null;
    vsobservacaocotacao         varchar2(32767) := null;
    vsobservacaocliref          varchar2(32767) := null;
    vsobservacaomens            varchar2(32767) := null;
    vftotcli                    number;


     BEGIN
    -- Retorna erros genericos tiporeg = 1
    IF p_existerro = TRUE
    THEN
      vncontlog := gvetregistralog.COUNT;


      FOR i IN 1 .. vncontlog LOOP
        IF gvetregistralog(i).tiporeg = 1
        THEN
          -- Gravar log de processamento de pedidos
          BEGIN
            INSERT INTO pclogfv
              (arquivo, codcli, DATA, motivo, numped, numpedcli, numpedrca, status)
            VALUES
              ('PCCLIENTFV',
               NULL,
               SYSDATE,
               SUBSTR(replace(replace(gvetregistralog(i).erro, '#', ' '),';',CHR(13)), 1, 100),
               NULL,
               NULL,
               NULL,
               'N');

            COMMIT;
          EXCEPTION
            WHEN OTHERS THEN
              ROLLBACK;
          END;
        END IF;
      END LOOP;
    END IF;


      ----------------- INICIO CLIENTE  -----------------
      -- Retorna Clientes gravados com sucesso
      vncontcli := gvet_regcli.count;


      for i in 1 .. vncontcli
      loop
        if gvet_regcli(i).valido = true
        then
        
         vsobservacaocli := null;

          -- recupera critica do cliente.
          vncontlog := gvetregistralog.count;

          for j in 1 .. vncontlog
          loop
            if (gvetregistralog(j).tiporeg = -1)
               and (gvetregistralog(j).cgcent = gvet_regcli(i).cgcent)
            then

             if length(vsobservacaocli) <= 3000 or vsobservacaocli is null then

               if trim(gvetregistralog(j).erro) <> ';' then

                  vsobservacaocli := vsobservacaocli ||
                                 replace(replace(gvetregistralog(j).erro, '#', ' '),';',CHR(13));
                end if;
              end if;
            end if;
          end loop;
        
        
          select count(1)
          into vftotcli
          from pcclient
          where codcli = gvet_regcli(i).codcli;

          if (gvet_regcli(i).codcli > 0) or (gvet_regcli(i).tipooperacao = 'A' ) then
            update pcclientfv
            set importado         =  2,
                observacao_pc     =  decode(tipooperacao,'I','CLIENTE GRAVADO COM SUCESSO','CLIENTE ALTERADO COM SUCESSO')/*||CHR(13)||
                                      vsobservacaocli*/,
                codcli            =  gvet_regcli(i).codcli
            where cgcent          =  gvet_regcli(i).cgcent
            and   ((importado     =  vngtipoleitura) OR (importado = 4))
            and   NVL(trunc(dtinclusao),trunc(sysdate))      >= vngdatainicio
            and   NVL(trunc(dtinclusao),trunc(sysdate))      <= vngdatafim
            and   rowid           = gvet_regcli(i).chave ;
          else
            update pcclientfv
            set importado         =  3,
                observacao_pc     = 'Falha na Inclusão do cliente' ||CHR(13)||
                                      vsobservacaocli,
                codcli            =  gvet_regcli(i).codcli
            --where cgcent          =  gvet_regcli(i).cgcent
            where rowid            = gvet_regcli(i).chave
            and   ((importado       =  vngtipoleitura) OR (importado = 4))
            and   NVL(trunc(dtinclusao),trunc(sysdate))      >= vngdatainicio
            and   NVL(trunc(dtinclusao),trunc(sysdate))      <= vngdatafim
           -- and   rowid            = gvet_regcli(i).chave ;
            and cgcent          =  gvet_regcli(i).cgcent;
          end if;

          commit;
        end if;
        --proc_destravarcliente(gvet_regcli(i).chave);
      end loop;

      -- Retorna Cliente nao gravados pela validacao/gravacao
      vncontcli := gvet_regcli.count;


      for i in 1 .. vncontcli
      loop
        if gvet_regcli(i).valido = false
        then
         vsobservacaocli := null;

          -- recupera critica do cliente.
          vncontlog := gvetregistralog.count;

          for j in 1 .. vncontlog
          loop
            if (gvetregistralog(j).tiporeg = -1)
               and (gvetregistralog(j).cgcent = gvet_regcli(i).cgcent)
            then

             if length(vsobservacaocli) <= 3000 or vsobservacaocli is null then

               if trim(gvetregistralog(j).erro) <> ';' then

                  vsobservacaocli := vsobservacaocli ||
                                 replace(replace(gvetregistralog(j).erro, '#', ' '),';',CHR(13));
                end if;
              end if;
            end if;
          end loop;

          IF INSTR(vsobservacaocli, '-29999') > 0 THEN
            vsobservacaocli := 'CLIENTE JÁ CADASTRADO.';
          END IF;

          update pcclientfv
          set importado           = 3,
              observacao_pc       = substr(vsobservacaocli, 1, 4000)
          --where cgcent            =  gvet_regcli(i).cgcent
          where  rowid             = gvet_regcli(i).chave
          and   ((importado       =  vngtipoleitura) OR (importado = 4))
          and   NVL(trunc(dtinclusao),trunc(sysdate))      >= vngdatainicio
          and   NVL(trunc(dtinclusao),trunc(sysdate))      <= vngdatafim
          --and   rowid             = gvet_regcli(i).chave;
          and cgcent            =  gvet_regcli(i).cgcent;
          commit;

        end if;
        proc_destravarcliente(gvet_regcli(i).chave);
      end loop;

      -- Retorna clientes rejeitados durante a leitura
      vncontlog := gvetregistralog.count;


      for i in 1 .. vncontlog
      loop
        if (gvetregistralog(i).tiporeg = -1)
           and (gvetregistralog(i).linhareg is not null)
        then
          update pcclientfv
          set importado           = 3,
              observacao_pc       = substr(replace(replace(gvetregistralog(i).erro, '#', ' '),';',CHR(13))
                                          ,1
                                          ,4000)
          where cgcent            =  gvetregistralog(i).cgcent
          and   ((importado       =  vngtipoleitura) OR (importado = 4))
          and   NVL(trunc(dtinclusao),trunc(sysdate))      >= vngdatainicio
          and   NVL(trunc(dtinclusao),trunc(sysdate))      <= vngdatafim ;

          commit;
        end if;
      end loop;

      ----------------- FIM CLIENTE  -----------------



      ----------------- INICIO CONTATO  -----------------
      -- Retorna Contatos gravados com sucesso
      vncontcontato := gvet_regcontato.count;


      for i in 1 .. vncontcontato
      loop
        if gvet_regcontato(i).valido = true
        then
          update pccontatofv
          set importado         =  2,
              observacao_pc     =  'CONTATO GRAVADO COM SUCESSO'
          where cgccli          =  gvet_regcontato(i).cgccli
          and   importado       =  vngtipoleitura
          and   trunc(dtinclusao)      >= vngdatainicio
          and   trunc(dtinclusao)      <= vngdatafim ;

          commit;
        end if;
      end loop;

      -- Retorna Contato nao gravados pela validacao/gravacao
      vncontcontato := gvet_regcontato.count;


      for i in 1 .. vncontcontato
      loop
        if gvet_regcontato(i).valido = false
        then

        vsobservacaocontato := null;

          -- recupera critica do contato.
          vncontlog := gvetregistralog.count;

          for j in 1 .. vncontlog
          loop
            if (gvetregistralog(j).tiporeg = 4)
               and (gvetregistralog(j).cgcent = gvet_regcontato(i).cgccli)
            then

             if length(vsobservacaocontato) <= 3000 or vsobservacaocontato is null then

               if trim(gvetregistralog(j).erro) <> ';' then

              vsobservacaocontato := vsobservacaocontato ||
                                 replace(replace(gvetregistralog(j).erro, '#', ' '),';',CHR(13));

                 end if;
              end if;

            end if;
          end loop;

          update pccontatofv
          set importado           = 3,
              observacao_pc       = substr(vsobservacaocontato, 1, 4000)
          where cgccli            =  gvet_regcontato(i).cgccli
          and   importado         =  vngtipoleitura
          and   trunc(dtinclusao)      >= vngdatainicio
          and   trunc(dtinclusao)      <= vngdatafim ;

          commit;

        end if;
      end loop;

      -- Retorna contatos rejeitados durante a leitura
      vncontlog := gvetregistralog.count;


      for i in 1 .. vncontlog
      loop
        if (gvetregistralog(i).tiporeg = 4)
           and (gvetregistralog(i).linhareg is not null)
        then
          update pccontatofv
          set importado           = 3,
              observacao_pc       = substr(replace(replace(gvetregistralog(i).erro, '#', ' '),';',CHR(13))
                                          ,1
                                          ,4000)
          where cgccli            =  gvetregistralog(i).cgcent
          and   importado         =  vngtipoleitura
          and   trunc(dtinclusao)      >= vngdatainicio
          and   trunc(dtinclusao)      <= vngdatafim ;

          commit;
        end if;
      end loop;

      ----------------- FIM CONTATO  -----------------


      ----------------- INICIO MENSAGENS (PCRECFUNCFV)  -----------------

      -- Retorna Mensagens gravadas com sucesso
      vncontmens := gvet_regmens.count;


      for i in 1 .. vncontmens
      loop
        if gvet_regmens(i).valido = true
        then
          update pcrecfuncfv
          set importado         =  2,
              observacao_pc     =  'MENSAGEM COM SUCESSO'
          where numrecadofv     =  gvet_regmens(i).numrecadofv
          and   importado       =  vngtipoleitura
          and   trunc(dtinclusao)      >= vngdatainicio
          and   trunc(dtinclusao)      <= vngdatafim ;

          commit;
        end if;
      end loop;

      -- Retorna Mensagens nao gravadas pela validacao/gravacao
      vncontmens := gvet_regmens.count;


      for i in 1 .. vncontmens
      loop
        if gvet_regmens(i).valido = false
        then

        vsobservacaomens := null;
          -- recupera critica das mensagens.
          vncontlog := gvetregistralog.count;

          for j in 1 .. vncontlog
          loop
            if (gvetregistralog(j).tiporeg = 5)
               and (gvetregistralog(j).numrecadofv = gvet_regmens(i).numrecadofv)
            then

             if length(vsobservacaomens) <= 3000 or vsobservacaomens is null then

              if trim(gvetregistralog(j).erro) <> ';' then

                 vsobservacaomens := vsobservacaomens ||
                                 replace(replace(gvetregistralog(j).erro, '#', ' '),';',CHR(13));
               end if;

              end if;
            end if;
          end loop;

          update pcrecfuncfv
          set importado           = 3,
              observacao_pc       = substr(vsobservacaomens, 1, 4000)
          where numrecadofv       =  gvet_regmens(i).numrecadofv
          and   importado         =  vngtipoleitura
          and   trunc(dtinclusao)      >= vngdatainicio
          and   trunc(dtinclusao)      <= vngdatafim ;

          commit;

        end if;
      end loop;

      -- Retorna mensagens rejeitadas durante a leitura
      vncontlog := gvetregistralog.count;


      for i in 1 .. vncontlog
      loop
        if (gvetregistralog(i).tiporeg = 5)
           and (gvetregistralog(i).linhareg is not null)
        then
          update pcrecfuncfv
          set importado           = 3,
              observacao_pc       = substr(replace(replace(gvetregistralog(i).erro, '#', ' '),';',CHR(13))
                                          ,1
                                          ,4000)
          where numrecadofv       =  gvetregistralog(i).numrecadofv
          and   importado         =  vngtipoleitura
          and   trunc(dtinclusao)      >= vngdatainicio
          and   trunc(dtinclusao)      <= vngdatafim ;

          commit;
        end if;
      end loop;

      ----------------- FIM MENSAGENS (PCRECFUNCFV)  -----------------


      ----------------- INICIO GONDOLAS -----------------------------

      -- Retorna gondolas gravadas com sucesso
    vncontgondola := gvet_reggondolac.COUNT;


    FOR i IN 1 .. vncontgondola LOOP
      IF  gvet_reggondolac(i).valido = TRUE
      THEN
        -- recupera critica do cabecalho.
        vncontlog          := gvetregistralog.COUNT;
        vsobservacaogondola := '';

        FOR j IN 1 .. vncontlog LOOP
          IF (gvetregistralog(j).tiporeg = 6) AND
             (gvetregistralog(j).numcontagem =  gvet_reggondolac(i).numcontagem) AND
             (gvetregistralog(j).cgcent      =  gvet_reggondolac(i).cgccli) AND
             (gvetregistralog(j).codusur     =  gvet_reggondolac(i).codusur)
          THEN
            if length(vsobservacaogondola) <= 3000 or vsobservacaogondola is null then

               if trim(gvetregistralog(j).erro) <> ';' then

                vsobservacaogondola := vsobservacaogondola ||
                                  replace(replace(gvetregistralog(j).erro, '#', ' '),';',CHR(13));
               end if;
            end if;
          END IF;
        END LOOP;

        BEGIN
          --- atualiza cabecalho do pedido.
          UPDATE pcgondolafv
             SET importado        = 2,
                 observacao_pc    = 'GONDOLA GRAVADA COM SUCESSO !'
           WHERE numcontagem      = gvet_reggondolac(i).numcontagem
           and   cgccli           = gvet_reggondolac(i).cgccli
           and   codusur          = gvet_reggondolac(i).codusur;

          COMMIT;
        EXCEPTION
          WHEN OTHERS THEN
            ROLLBACK;
        END;


        FOR cr_gondi IN (SELECT codprod
                             FROM pcgondolaifv
                            WHERE numcontagem =  gvet_reggondolac(i).numcontagem
                            and   cgccli      =  gvet_reggondolac(i).cgccli
                            and   codusur     =  gvet_reggondolac(i).codusur) LOOP

          -- recupera critica do item
          vncontlog           := gvetregistralog.COUNT;
          vsobservacaoitemgondola := '';

          FOR j IN 1 .. vncontlog LOOP
            IF (gvetregistralog(j).tiporeg = 7) AND
               (gvetregistralog(j).numcontagem =  gvet_reggondolac(i).numcontagem) AND
               (gvetregistralog(j).cgcent      =  gvet_reggondolac(i).cgccli) AND
               (gvetregistralog(j).codusur     =  gvet_reggondolac(i).codusur) AND
               (gvetregistralog(j).codprod     =  cr_gondi.codprod)
            THEN

             if length(vsobservacaoitemgondola) <= 3000 or vsobservacaoitemgondola is null then

               if trim(gvetregistralog(j).erro) <> ';' then

              vsobservacaoitemgondola := vsobservacaoitemgondola ||
                                     replace(replace(gvetregistralog(j).erro, '#', ' '),';',CHR(13));
                end if;

              end if;
            END IF;
          END LOOP;


          BEGIN
            UPDATE pcgondolaifv
               SET observacao_pc          = SUBSTR(vsobservacaoitemgondola, 1, 4000)
             WHERE numcontagem   = gvet_reggondolac(i).numcontagem
               AND cgccli        = gvet_reggondolac(i).cgccli
               and codusur       = gvet_reggondolac(i).codusur
               AND codprod       = cr_gondi.codprod;

            COMMIT;
          EXCEPTION
            WHEN OTHERS THEN
              ROLLBACK;
          END;
        END LOOP;
      END IF;
    END LOOP;

    -- Retorna gondolas nao gravadss
    vncontgondola :=  gvet_reggondolac.COUNT;


    FOR i IN 1 .. vncontgondola LOOP
      IF  gvet_reggondolac(i).valido = FALSE
      THEN
        -- recupera critica do cabecalho.
        vncontlog          := gvetregistralog.COUNT;
        vsobservacaogondola := '';

        FOR j IN 1 .. vncontlog LOOP
          IF (gvetregistralog(j).tiporeg = 6) AND
             (gvetregistralog(j).numcontagem =  gvet_reggondolac(i).numcontagem) AND
             (gvetregistralog(j).cgcent      =  gvet_reggondolac(i).cgccli) AND
             (gvetregistralog(j).codusur     =  gvet_reggondolac(i).codusur)
          THEN

           if length(vsobservacaogondola) <= 3000 or vsobservacaogondola is null then

            if trim(gvetregistralog(j).erro) <> ';' then

            vsobservacaogondola := vsobservacaogondola ||
                                 replace(replace(gvetregistralog(j).erro, '#', ' '),';',CHR(13));
             end if;

           end if;
          END IF;
        END LOOP;

        BEGIN
          --- atualiza cabecalho do pedido.
          UPDATE pcgondolafv
             SET importado        = 3,
                 observacao_pc    = SUBSTR(vsobservacaogondola, 1, 4000)
             WHERE numcontagem   = gvet_reggondolac(i).numcontagem
               AND cgccli        = gvet_reggondolac(i).cgccli
               and codusur       = gvet_reggondolac(i).codusur ;


          COMMIT;
        EXCEPTION
          WHEN OTHERS THEN
            ROLLBACK;
        END;


        FOR cr_gondi IN (SELECT codprod
                             FROM pcgondolaifv
                            WHERE numcontagem =  gvet_reggondolac(i).numcontagem
                            and   cgccli      =  gvet_reggondolac(i).cgccli
                            and   codusur     =  gvet_reggondolac(i).codusur) LOOP

          -- recupera critica do item
          vncontlog           := gvetregistralog.COUNT;
          vsobservacaoitemgondola := '';

          FOR j IN 1 .. vncontlog LOOP
            IF (gvetregistralog(j).tiporeg = 7) AND
             (gvetregistralog(j).numcontagem =  gvet_reggondolac(i).numcontagem) AND
             (gvetregistralog(j).cgcent      =  gvet_reggondolac(i).cgccli) AND
             (gvetregistralog(j).codusur     =  gvet_reggondolac(i).codusur) AND
             (gvetregistralog(j).codprod = cr_gondi.codprod)
            THEN

              if length(vsobservacaoitemgondola) <= 3000 or vsobservacaogondola is null then

                 if trim(gvetregistralog(j).erro) <> ';' then

              vsobservacaoitemgondola := vsobservacaoitemgondola ||
                                     replace(replace(gvetregistralog(j).erro, '#', ' '),';',CHR(13));
                 end if;

               end if;
            END IF;
          END LOOP;

          BEGIN
            UPDATE pcgondolaifv
               SET observacao_pc = SUBSTR(vsobservacaoitemgondola, 1, 4000)
             WHERE numcontagem   = gvet_reggondolac(i).numcontagem
               AND cgccli        = gvet_reggondolac(i).cgccli
               and codusur       = gvet_reggondolac(i).codusur
               AND codprod       = cr_gondi.codprod;

            COMMIT;
          EXCEPTION
            WHEN OTHERS THEN
              ROLLBACK;
          END;
        END LOOP;
      END IF;
    END LOOP;

    -- Retorna gondolas rejeitadas durante a leitura
    vncontlog := gvetregistralog.COUNT;


    FOR i IN 1 .. vncontlog LOOP
      IF (gvetregistralog(i).tiporeg = 6) AND (gvetregistralog(i).linhareg IS NOT NULL)
      THEN
        BEGIN
          --- atualiza cabecalho do pedido.
          UPDATE pcgondolafv
             SET importado        = 3,
                 observacao_pc    = SUBSTR(replace(replace(gvetregistralog(i).erro, '#', ' '),';',CHR(13)),
                                           1,
                                           4000)
           WHERE numcontagem = gvetregistralog(i).numcontagem
           and   cgccli      = gvetregistralog(i).cgcent
           and   codusur     = gvetregistralog(i).codusur;

          COMMIT;
        EXCEPTION
          WHEN OTHERS THEN
            ROLLBACK;
        END;

      END IF;
    END LOOP;



      ----------------- FIM GONDOLAS --------------------------------

      ----------------- INICIO VISITAS  -----------------
      -- Retorna visitas gravadas com sucesso
      vncontvisita := gvet_regvisita.count;


      for i in 1 .. vncontvisita
      loop
        if gvet_regvisita(i).valido = true
        then
          update pcvisitafv
          set importado         =  2,
              observacao_pc     =  'VISITA GRAVADA COM SUCESSO'
          where cgccli          =  gvet_regvisita(i).cgccli
          and   codusur         =  gvet_regvisita(i).codusur
          and   (codmotivo       =  gvet_regvisita(i).codmotivo or codmotivo is null)
          and   data            =  gvet_regvisita(i).data
          and   horainicial     =  gvet_regvisita(i).hrinicial
          and   minutoinicial   =  gvet_regvisita(i).minutoinicial
          and   horafinal     =  gvet_regvisita(i).hrfinal
          and   minutofinal     =  gvet_regvisita(i).minutofinal
          and   importado       =  vngtipoleitura
          and   trunc(dtinclusao)      >= vngdatainicio
          and   trunc(dtinclusao)      <= vngdatafim ;

          commit;
        end if;
      end loop;

      -- Retorna visitas nao gravadas pela validacao/gravacao
      vncontvisita := gvet_regvisita.count;


      for i in 1 .. vncontvisita
      loop
        if gvet_regvisita(i).valido = false
        then
          -- recupera critica da visita.
          vncontlog := gvetregistralog.count;
          vsobservacaovisita := null;

          for j in 1 .. vncontlog
          loop
            if (gvetregistralog(j).tiporeg           = 8) AND
                (gvetregistralog(j).cgcent        = gvet_regvisita(i).cgccli) AND
                (gvetregistralog(j).codusur       = gvet_regvisita(i).codusur) AND
                ((gvetregistralog(j).codigocotacao = gvet_regvisita(i).codmotivo) or gvetregistralog(j).codigocotacao is null) AND
                (gvetregistralog(j).data          = gvet_regvisita(i).data) AND
                (gvetregistralog(j).numrecadofv   = gvet_regvisita(i).hrinicial) AND
                (gvetregistralog(j).numcontagem   = gvet_regvisita(i).minutoinicial)
            then

             if length(vsobservacaovisita) <= 3000 or vsobservacaovisita is null then

                  if trim(gvetregistralog(j).erro) <> ';' then

                 vsobservacaovisita := vsobservacaovisita ||
                                 replace(replace(gvetregistralog(j).erro, '#', ' '),';',CHR(13));
                  end if;

              end if;
            end if;
          end loop;

          update pcvisitafv
          set importado           = 3,
              observacao_pc       = substr(vsobservacaovisita, 1, 4000)
          where cgccli          =  gvet_regvisita(i).cgccli
          and   codusur         =  gvet_regvisita(i).codusur
          and   (codmotivo       =  gvet_regvisita(i).codmotivo or codmotivo is null)
          and   data            =  gvet_regvisita(i).data
          and   horainicial     =  gvet_regvisita(i).hrinicial
          and   minutoinicial   =  gvet_regvisita(i).minutoinicial
          and   horafinal     =  gvet_regvisita(i).hrfinal
          and   minutofinal     =  gvet_regvisita(i).minutofinal
          and   importado       =  vngtipoleitura
          and   trunc(dtinclusao)      >= vngdatainicio
          and   trunc(dtinclusao)      <= vngdatafim ;

          commit;

        end if;
      end loop;

      -- Retorna visitas rejeitadas durante a leitura
      vncontlog := gvetregistralog.count;


      for i in 1 .. vncontlog
      loop
        if (gvetregistralog(i).tiporeg = 8)
           and (gvetregistralog(i).linhareg is not null)
        then
          update pcvisitafv
          set importado           = 3,
              observacao_pc       = substr(replace(replace(gvetregistralog(i).erro, '#', ' '),';',CHR(13))
                                          ,1
                                          ,4000)
          where cgccli          =  gvetregistralog(i).cgcent
          and   codusur         =  gvetregistralog(i).codusur
          and   codmotivo       =  gvetregistralog(i).codigocotacao
          and   data            =  gvetregistralog(i).data
          and   horainicial     =  gvetregistralog(i).numrecadofv
          and   minutoinicial   =  gvetregistralog(i).numcontagem
          and   importado       =  vngtipoleitura
          and   trunc(dtinclusao)      >= vngdatainicio
          and   trunc(dtinclusao)      <= vngdatafim ;

          commit;
        end if;
      end loop;

      ----------------- FIM VISITAS  -----------------

      ----------------- INICIO REFERNCIA COMERCIAL  -----------------
      -- Retorna Referencias comerciais gravadas com sucesso
      vncontcliref := gvet_regcliref.count;


      for i in 1 .. vncontcliref
      loop
        if gvet_regcliref(i).valido = true
        then
          update pcclireffv
          set importado         =  2,
              observacao_pc     =  'REFERENCIA GRAVADA COM SUCESSO'
          where cgccli          =  gvet_regcliref(i).cgccli
          and   codref          =  gvet_regcliref(i).codref
          and   importado       =  vngtipoleitura
          and   trunc(dtinclusao)      >= vngdatainicio
          and   trunc(dtinclusao)      <= vngdatafim ;

          commit;
        end if;
      end loop;

      -- Retorna Referencias Comerciais nao gravados pela validacao/gravacao
      vncontcliref := gvet_regcliref.count;


      for i in 1 .. vncontcliref
      loop
        if gvet_regcliref(i).valido = false
        then

        vsobservacaocliref := null;

          -- recupera critica da referencia comericial.
          vncontlog := gvetregistralog.count;

          for j in 1 .. vncontlog
          loop
            if (gvetregistralog(j).tiporeg = 14)
               and (gvetregistralog(j).cgcent = gvet_regcliref(i).cgccli)
            then

             if length(vsobservacaocliref) <= 3000 or vsobservacaocliref is null then

                if trim(gvetregistralog(j).erro) <> ';' then

              vsobservacaocliref := vsobservacaocliref ||
                                 replace(replace(gvetregistralog(j).erro, '#', ' '),';',CHR(13));

                 end if;
              end if;

            end if;
          end loop;

          update pcclireffv
          set importado           = 3,
              observacao_pc       = substr(vsobservacaocliref, 1, 4000)
          where cgccli            =  gvet_regcliref(i).cgccli
          and   codref            =  gvet_regcliref(i).codref
          and   importado         =  vngtipoleitura
          and   trunc(dtinclusao)      >= vngdatainicio
          and   trunc(dtinclusao)      <= vngdatafim ;

          commit;

        end if;
      end loop;

      -- Retorna referencias rejeitadas durante a leitura
      vncontlog := gvetregistralog.count;


      for i in 1 .. vncontlog
      loop
        if (gvetregistralog(i).tiporeg = 14)
           and (gvetregistralog(i).linhareg is not null)
        then
          update pcclireffv
          set importado           = 3,
              observacao_pc       = substr(replace(replace(gvetregistralog(i).erro, '#', ' '),';',CHR(13))
                                          ,1
                                          ,4000)
          where cgccli            =  gvetregistralog(i).cgcent
          and   codref            =  gvetregistralog(i).codigocotacao
          and   importado         =  vngtipoleitura
          and   trunc(dtinclusao)      >= vngdatainicio
          and   trunc(dtinclusao)      <= vngdatafim ;

          commit;
        end if;
      end loop;

      ----------------- FIM REFERENCIA COMERCIAL  -----------------


      ----------------- INICIO COTACOES  -----------------
      -- Retorna cotacoes gravadas com sucesso
      vncontcotacao := gvet_regcotacao.count;


      for i in 1 .. vncontcotacao
      loop
        if gvet_regcotacao(i).valido = true
        then
          update pccotafv
          set importado         =  2,
              observacao_pc     =  'COTACAO GRAVADA COM SUCESSO'
          where cgccli          =  gvet_regcotacao(i).cgccli
          and   codusur         =  gvet_regcotacao(i).codusur
          and   data            =  gvet_regcotacao(i).data
          and   codprod         =  gvet_regcotacao(i).codprod
          and   numseq          =  gvet_regcotacao(i).numseq
          and   codconc         =  gvet_regcotacao(i).codconc
          and   importado       =  vngtipoleitura ;

          commit;
        end if;
      end loop;

      -- Retorna cotacoes nao gravadas pela validacao/gravacao
      vncontcotacao := gvet_regcotacao.count;


      for i in 1 .. vncontcotacao
      loop
        if gvet_regcotacao(i).valido = false
        then
          -- recupera critica da cotacao.
          vncontlog := gvetregistralog.count;
          vsobservacaocotacao := null;

          for j in 1 .. vncontlog
          loop
            if (gvetregistralog(j).tiporeg           = 13) AND
                (gvetregistralog(j).cgcent        = gvet_regcotacao(i).cgccli) AND
                (gvetregistralog(j).codusur       = gvet_regcotacao(i).codusur) AND
                (gvetregistralog(j).data          = gvet_regcotacao(i).data) AND
                (gvetregistralog(j).numrecadofv   = gvet_regcotacao(i).codconc) AND
                (gvetregistralog(j).numcontagem   = gvet_regcotacao(i).numseq) AND
                (gvetregistralog(j).codprod       = gvet_regcotacao(i).codprod)
            then

             if length(vsobservacaocotacao) <= 3000 or vsobservacaocotacao is null then

             if trim(gvetregistralog(j).erro) <> ';' then

              vsobservacaocotacao := vsobservacaocotacao ||
                                 replace(replace(gvetregistralog(j).erro, '#', ' '),';',CHR(13));
               end if;
              end if;
            end if;
          end loop;

          update pccotafv
          set importado           = 3,
              observacao_pc       = substr(vsobservacaocotacao, 1, 4000)
          where cgccli          =  gvet_regcotacao(i).cgccli
          and   codusur         =  gvet_regcotacao(i).codusur
          and   data            =  gvet_regcotacao(i).data
          and   codprod         =  gvet_regcotacao(i).codprod
          and   numseq          =  gvet_regcotacao(i).numseq
          and   codconc         =  gvet_regcotacao(i).codconc
          and   importado       =  vngtipoleitura;

          commit;

        end if;
      end loop;

      -- Retorna cotacoes rejeitadas durante a leitura
      vncontlog := gvetregistralog.count;


      for i in 1 .. vncontlog
      loop
        if (gvetregistralog(i).tiporeg = 13)
           and (gvetregistralog(i).linhareg is not null)
        then
          update pccotafv
          set importado           = 3,
              observacao_pc       = substr(replace(replace(gvetregistralog(i).erro, '#', ' '),';',CHR(13))
                                          ,1
                                          ,4000)
          where cgccli          =  gvetregistralog(i).cgcent
          and   codusur         =  gvetregistralog(i).codusur
          and   codprod         =  gvetregistralog(i).codprod
          and   data            =  gvetregistralog(i).data
          and   codconc         =  gvetregistralog(i).numrecadofv
          and   numseq          =  gvetregistralog(i).numcontagem
          and   importado       =  vngtipoleitura;

          commit;
        end if;
      end loop;

      ----------------- FIM COTACOES  -----------------




  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END proc_processaretornotab;  

PROCEDURE importar(p_tipoleitura IN NUMBER DEFAULT 1,
                   p_datainicial IN DATE DEFAULT TRUNC(SYSDATE),
                   p_datafinal   IN DATE DEFAULT TRUNC(SYSDATE),
                   p_tiporeg     IN NUMBER default null,
                   p_codusur     IN NUMBER default null) is

  vbexisterro     boolean;
    vddatafinal     date;
    vddatainicial   date;
    vicontcancelada number;
    vscodfilial     pcfilial.codigo%type;

    vLog            PCLOG_INTEGRADORA%ROWTYPE := NULL;
    VSOWNER         VARCHAR2(100);
    VSNAME          VARCHAR2(100);
    VNLINE          NUMBER;
    VSTYPE          VARCHAR2(100);
    VSPROGRAMA      VARCHAR2(60);


  BEGIN
    OWA_UTIL.WHO_CALLED_ME(VSOWNER, VSNAME, VNLINE, VSTYPE);
    VSPROGRAMA := F_OBTERNOMEAPLICACAO;

    vLog.CODUSUR           := -9999;
    vLog.NUMPEDRCA         := -9999;
    vLog.DATA              := SYSDATE;
    vLog.MSG               := 'Importando cadastros de clientes. Parametros: ' || chr(13) ||
                              ' p_tipoleitura : ' || p_tipoleitura || chr(13) ||
                              ' p_datainicial : ' || p_datainicial || chr(13) ||
                              ' p_datafinal   : ' || p_datafinal   || chr(13) ||
                              ' p_tiporeg     : ' || p_tiporeg 	   || chr(13) ||
                              ' p_codusur     : ' || p_codusur     || chr(13) ||
                              ' objeto_origem : ' || VSNAME        || chr(13) ||
                              ' linha_origem  : ' || VNLINE        || chr(13) ||
                              ' tipo_origem   : ' || VSTYPE        || chr(13) ||
                              ' programa_orig : ' || VSPROGRAMA;

    PRC_LOG_INTEGRADORA(vLog, (CASE WHEN vLog.MSG LIKE '%ORA-%' THEN DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ELSE TO_CHAR($$PLSQL_LINE) END));




    vngcontador := 0;

    vngtipoleitura := p_tipoleitura;
    vngtiporeg     := p_tiporeg;

    vbexisterro := false;


    -- leitura dos parametros do sistema (PCCONSUM).
    if not vbexisterro then
      proc_lerparametros(vbexisterro);
    end if;


    if p_tipoleitura = 1
    then
      vddatainicial := TRUNC(sysdate) - 365;
      vddatafinal   := TRUNC(sysdate);
    else
      vddatainicial := p_datainicial;
      vddatafinal   := p_datafinal;
    end if;




     -- zerar para o caso de cancelamento de nota ainda não importada
    gvetregistralog.delete;
    gvet_regcli.delete;
    gvet_regcontato.delete;
    gvet_reggondolac.delete;
    gvet_reggondolai.delete;
    gvet_regvisita.delete;
    gvet_regcotacao.delete;
    gvet_regcliref.delete;
    gvet_regmens.delete;


     vngcontador := 0;
    vbexisterro := false;

    -- leitura dos pedidos
    if not vbexisterro then
      -- leitura do conteudo do arquivo de entrada (p_arquivo).
      proc_processarleitura(vbexisterro,p_tipoleitura,p_datainicial,p_datafinal,p_tiporeg,p_codusur);
    end if;


    if not vbexisterro then
      -- processamento de cliente
      proc_processarclientes;
    end if;

    if not vbexisterro then
      -- processamento de cliente
      proc_processarcontatos;
    end if;

    if not vbexisterro then
      -- processamento de mensagens
      proc_processarmensagens;
    end if;


    if not vbexisterro then
      -- processamento de gondolas
      proc_processargondola;
    end if;

    if not vbexisterro then
      -- processamento de visitas
      proc_processarvisitas;
    end if;

    if not vbexisterro then
      -- processamento de cotações
      proc_processarcotacoes;
    end if;

    if not vbexisterro then
      -- processamento de referencias de clientes
      proc_processarcliref;
    end if;


    -- processamento do retorno.
    proc_processaretornotab(vbexisterro);

    -- Caso existe algum importado igual a 4 a rotina altera para importado igual a 3
    --proc_destravarcliente;

    -- Remove todos os elementos das tabelas.
    gvetregistralog.delete;
    gvet_regcli.delete;
    gvet_regcontato.delete;
    gvet_reggondolac.delete;
    gvet_reggondolai.delete;
    gvet_regvisita.delete;
    gvetregistralog.delete;
    gvet_regcotacao.delete;
    gvet_regcliref.delete;
    gvet_regmens.delete;

 end importar  ;




end; --IMPORTARCADASTROS
