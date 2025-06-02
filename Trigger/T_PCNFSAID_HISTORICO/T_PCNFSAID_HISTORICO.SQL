CREATE OR REPLACE TRIGGER T_PCNFSAID_HISTORICO BEFORE INSERT OR UPDATE
       ON PCNFSAID REFERENCING NEW AS NEW FOR EACH ROW
DECLARE
  /************************************************************************************************
  Proposito: Trigger para gravação dos dados de cadastro (historico de movimentação)
  Rotina: Pacote
  Utilizada por: rotinas que fazem inclusão na PCNFSAID
  ------------------------------------------------------------------------------------------------
  Data        Responsavel       Descricao
  ----------  --------------    --------------------------------------------------------------------
  17/11/2008  Ricardo           Criação da trigger
  01/03/2010  Ricardo           Trigger não mais travará o processo, apenas gerará Log na tabela
                                PCLOGALTERACAODADOS.
  08/03/2010  Ricardo           Trigger alterada para pegar dados da PCVENDACONSUM somente se
                                CODCLI for 1, 2 ou 3.
  03/09/2010  Natanael          Trigger alterada para gravar o AmbienteNFE no qual a nota foi aprovada.
  07/04/2011  Thiago Melo       Alterada trigger para gravação do campo PCNFSAID.IEENT de acordo com o
                                campo PCCLIENT.IEENT.
  10/10/2012  Rodrigo Guimaraes Alterado a trigger para gravar o endereço de entrega do pedido de acordo
                                com a tabela PCENDERECOENTREGAPEDIDO. Caso não existe o registro na
                                tabela, mantém a regra de gravação atual.
   25/06/2019 Gleibe Alterado a verificação do parametro DEDUZIRICMSBASEPISCOFINS 
                                 para EXCLUIRICMSBASEPISCOFINS. O excluir é o representante da saída 
                                 e deverá ser gravado no campo PCNFSAID.DEDUZIRICMSBASEPISCOFINS.
  ************************************************************************************************/

  VTIPOALIQOUTRASDESP          PCNFSAID.TIPOALIQOUTRASDESP%type;
  VAGREGARSTPRODSINTEGRA       PCNFSAID.AGREGARSTPRODSINTEGRA%type;
  VCODCONTCLI                  PCNFSAID.CODCONTCLI%type;
  VPERCICMFRETE                PCNFSAID.PERCICMFRETE%type;
  VPERCICMINTERFRETE           number(4, 2);
  VALIQICMOUTRASDESP           PCNFSAID.ALIQICMOUTRASDESP%type;
  VALIQICMINTEROUTRASDESP      number(4, 2);
  VCODFISCALFRETE              PCNFSAID.CODFISCALFRETE%type;
  VCODFISCALINTERFRETE         number(4);
  VCODFISCALOUTRASDESP         PCNFSAID.CODFISCALOUTRASDESP%type;
  VCODFISCALINTEROUTRASDESP    number(4);
  VCODFISCALDEVOUTRASDESP      number(4);
  VCODFISCALINTERDEVOUTRASDESP number(4);
  VUFFILIAL                    PCNFSAID.UFFILIAL%type;
  VCODFILIAL                   PCNFSAID.CODFILIAL%type;
  VCFOPFRETE                   number(4);
  VCFOPDESPESA                 number(4);
  VALIQICMSFRETE               number(4, 2);
  VALIQICMSDESPESA             number(4, 2);
  VVLPIS                       PCNFSAID.VLPIS%type;
  VVLCOFINS                    PCNFSAID.VLCOFINS%type;
  VCODFISCALNF                 PCNFSAID.CODFISCALNF%type;
  VMENSAGEM_ERRO               varchar2(100);
  VAMBIENTENFE                 PCNFSAID.AMBIENTENFE%type;
  VAMBIENTECTE                 PCNFSAID.AMBIENTECTE%type;
  VGERARBCRNFE                 PCNFSAID.GERARBCRNFE%type;
  VSIEENT                      PCCLIENT.IEENT%type;
  VENDERECOENTREGAPEDIDO       PCENDERECOENTREGAPEDIDO%rowtype;
  VERRO_TRIBUTACAO             exception;
  VNUMTRANSITEM                NUMBER;
  VTIPODANFE                   PCFILIAL.TIPODANFE%type;
  ------------------------------------------------------------------------------------------------
  -- FUNÇÕES GERAR LOG SE OCORRER UM ERRO
  ------------------------------------------------------------------------------------------------
  procedure GERAR_LOG(PMENSAGEM_ERRO in varchar2, PLINHA_ERRO in varchar2) is
  begin
    insert into PCLOGALTERACAODADOS
      (DATA,
       TABELA,
       COLUNA,
       TIPOVALOR,
       VALORALFA,
       TERMINAL,
       MAQUINA,
       PROGRAMA,
       OSUSER,
       OBSERVACOES,
       OBSERVACOES2)
    values
      (sysdate,
       'PCNFSAID',
       'INDEFINIDA',
       'A',
       'ERRO NA INCLUSÃO DO REGISTRO',
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       'ERRO TRIGGER HISTORICO: NUMTRANSVENDA: ' ||
       TO_CHAR(NVL(:new.NUMTRANSVENDA, 0)) || ' NUMNOTA: ' ||
       TO_CHAR(NVL(:new.NUMNOTA, 0)),
       'ERRO ORIGINAL: ' || PMENSAGEM_ERRO || PLINHA_ERRO);
  end;

  /****************************************************************************/
  function GET_VALORCLIENTE(PCODCLI        in number,
                            PCONSUMIDOR    in varchar2,
                            PVENDACONSUM   in varchar2,
                            PVALOR_CONSUM  in varchar2,
                            PVALOR_CLIENTE in varchar2,
                            PVALOR_FILIAL  in varchar2) return varchar2 is
  begin
    case
      when PCODCLI in (1, 2, 3) then
        if PVENDACONSUM = 'S'
        then
          return PVALOR_CONSUM;
        elsif PCONSUMIDOR = 'S'
        then
          return PVALOR_FILIAL;
        else
          return PVALOR_CLIENTE;
        end if;
      else
        return PVALOR_CLIENTE;
    end case;
  end;
  ------------------------------------------------------------------------------------------------
  -- FUNÇÕES PARA RECUPERAR INFORMAÇÕES SOBRE A TRIBUTAÇÃO DE FRETE E DESPESAS ACESSORRIAS
  ------------------------------------------------------------------------------------------------
  procedure ATUALIZAR_TRIBUTACOES is
  begin
    if VTIPOALIQOUTRASDESP <> 'T'
    then
      VCFOPFRETE       := case when VUFFILIAL = :new.UF then VCODFISCALFRETE else VCODFISCALINTERFRETE end;
      VCFOPDESPESA     := case when VUFFILIAL = :new.UF then VCODFISCALOUTRASDESP else VCODFISCALINTEROUTRASDESP end;
      VALIQICMSFRETE   := case when VUFFILIAL = :new.UF then VPERCICMFRETE else VPERCICMINTERFRETE end;
      VALIQICMSDESPESA := case when VUFFILIAL = :new.UF then VALIQICMOUTRASDESP else VALIQICMINTEROUTRASDESP end;
    else
      begin
        select DECODE(:new.TIPOVENDA,
                      'DF',
                      NVL(CODFISCALFRETEDEVFORNEC, CODFISCALFRETE),
                      DECODE(NVL(:new.CONSUMIDORFINAL, 'N') || :new.TIPOFJ,
                             'SF',
                             NVL(CODFISCALFRETEPF, CODFISCALFRETE),
                             CODFISCALFRETE)),
               DECODE(:new.TIPOVENDA,
                      'DF',
                      DECODE(NVL(:new.CONSUMIDORFINAL, 'N') || :new.TIPOFJ,
                             'SF',
                             NVL(CODFISCALDEVOUTRASDESPPF,
                                 CODFISCALDEVOUTRASDESP),
                             CODFISCALDEVOUTRASDESP),
                      DECODE(NVL(:new.CONSUMIDORFINAL, 'N') || :new.TIPOFJ,
                             'SF',
                             CODFISCALOUTRASDESPPF,
                             CODFISCALOUTRASDESP)),
               DECODE(:new.TIPOVENDA,
                      'DF',
                      NVL(ALIQICMFRETEDEVFORNEC, PERCICMFRETE),
                      DECODE(NVL(:new.CONSUMIDORFINAL, 'N') || :new.TIPOFJ,
                             'SF',
                             NVL(PERCICMFRETEPF, PERCICMFRETE),
                             PERCICMFRETE)),
               DECODE(NVL(:new.CONSUMIDORFINAL, 'N') || :new.TIPOFJ,
                      'SF',
                      NVL(ALIQICMOUTRASDESPPF, ALIQICMOUTRASDESP),
                      ALIQICMOUTRASDESP)
          into VCFOPFRETE, VCFOPDESPESA, VALIQICMSFRETE, VALIQICMSDESPESA
          from PCTRIBOUTROS
         where UFDESTINO = :new.UF
           and CODFILIALNF = VCODFILIAL;
      exception
        when others then
          VMENSAGEM_ERRO := 'TRIBUTAÇÃO POR ESTADO INEXISTENTE (ROTINA 596)! FILIAL: ' ||
                            VCODFILIAL || ' UF DESTINO: ' || :new.UF;
          raise VERRO_TRIBUTACAO;
      end;
    end if;
  end;
begin
   IF INSERTING
   THEN
----------------------------------------------------------------------------------
     -- BUSCAR PARAMETROS GERAIS
     ----------------------------------------------------------------------------------
     begin
       select TIPOALIQOUTRASDESP,
              PERCICMFRETE,
              PERCICMINTERFRETE,
              ALIQICMOUTRASDESP,
              ALIQICMINTEROUTRASDESP,
              CODFISCALFRETE,
              CODFISCALINTERFRETE,
              CODFISCALOUTRASDESP,
              CODFISCALINTEROUTRASDESP,
              CODFISCALDEVOUTRASDESP,
              CODFISCALINTERDEVOUTRASDESP,
              AGREGARSTPRODSINTEGRA,
              CODCONTCLI
         into VTIPOALIQOUTRASDESP,
              VPERCICMFRETE,
              VPERCICMINTERFRETE,
              VALIQICMOUTRASDESP,
              VALIQICMINTEROUTRASDESP,
              VCODFISCALFRETE,
              VCODFISCALINTERFRETE,
              VCODFISCALOUTRASDESP,
              VCODFISCALINTEROUTRASDESP,
              VCODFISCALDEVOUTRASDESP,
              VCODFISCALINTERDEVOUTRASDESP,
              VAGREGARSTPRODSINTEGRA,
              VCODCONTCLI
         from PCCONSUM;
     exception
       when others then
         null;
     end;

     ----------------------------------------------------------------------------------
     -- BUSCAR PARAMETROS DA TABELA PCPARAMFILIAL (NOVA 132)
     ----------------------------------------------------------------------------------
     begin
       select VALOR AMBIENTENFE
         into VAMBIENTENFE
         from PCPARAMFILIAL
        where CODFILIAL = NVL(:new.CODFILIALNF, :new.CODFILIAL)
          and NOME = 'AMBIENTENFE';
     exception
       when others then
         null;
     end;
     
     begin
       select VALOR AMBIENTECTE
         into VAMBIENTECTE
         from PCPARAMFILIAL
        where CODFILIAL = NVL(:new.CODFILIALNF, :new.CODFILIAL)
          and NOME = 'AMBIENTECTE';
     exception
       when others then
         null;
     end;

    ----------------------------------------------------------------------------------
     -- BUSCAR PARAMETROS DA TABELA PCPARAMFILIAL, BUSCAR O PARAMETRO GERARCRNFE (NOVA 132)
     ----------------------------------------------------------------------------------
     begin
       select VALOR  GERARBCRNFE
         into VGERARBCRNFE
         from PCPARAMFILIAL
        where CODFILIAL = NVL(:new.CODFILIALNF, :new.CODFILIAL)
           and NOME = 'GERARBCRNFE';
     exception
       when others then
         null;
     end;

     ----------------------------------------------------------------------------------
     -- BUSCAR DADOS DO CLIENTE DA NOTA
     ----------------------------------------------------------------------------------
     begin
       select PCCLIENT.IEENT
         into VSIEENT
         from PCCLIENT
        where PCCLIENT.CODCLI = :new.CODCLI;
     end;

     ----------------------------------------------------------------------------------
     -- BUSCAR PARAMETROS POR FILIAL
     ----------------------------------------------------------------------------------
     begin
       select CODIGO, UF, TIPODANFE
         into VCODFILIAL, VUFFILIAL, VTIPODANFE
         from PCFILIAL
        where CODIGO = NVL(:new.CODFILIALNF, :new.CODFILIAL);
     exception
       when others then
         null;
     end;

     ----------------------------------------------------------------------------------
     if VTIPOALIQOUTRASDESP = 'F'
     then
       begin
         select ALIQICMOUTRASDESP,
                ALIQICMINTEROUTRASDESP,
                CODFISCALOUTRASDESP,
                CODFISCALINTEROUTRASDESP
           into VALIQICMOUTRASDESP,
                VALIQICMINTEROUTRASDESP,
                VCODFISCALOUTRASDESP,
                VCODFISCALINTEROUTRASDESP
           from PCFILIAL
          where CODIGO = VCODFILIAL;
       exception
         when others then
           null;
       end;
     end if;

     ----------------------------------------------------------------------------------
     for DADOS in (select C.CLIENTE,
                          C.CODCLI,
                          case
                            when trim(UPPER(C.CLIENTE)) like '%CONSUMIDOR%' then
                             'S'
                            else
                             'N'
                          end CLIENTE_CONSUMIDOR,
                          C.CGCENT CGCCLIENTE,
                          C.IEENT IECLIENTE,
                          C.ENDERENT ENDERCLIENTE,
                          C.BAIRROENT BAIRROCLIENTE,
                          C.MUNICENT CIDADECLIENTE,
                          C.CEPENT CEPCLIENTE,
                          C.ESTENT UFCLIENTE,
                          C.TIPOFJ TIPOFJCLIENTE,
                          C.CODCIDADE CODCIDADECLIENTE,
                          C.CONSUMIDORFINAL,
                          C.CLIENTEFONTEST,
                          C.SULFRAMA,
                          C.ORGAOPUB,
                          C.ORGAOPUBFEDERAL,
                          C.ORGAOPUBMUNICIPAL,
                          C.TIPOEMPRESA,
                          C.CONTRIBUINTE,
                          C.CODATV1,
                          C.TELENT TELEFONECLI,
                          C.EMAIL EMAILCLI,
                          C.NUMEROENT NUMEROCLI,
                          FL.CODCLI CODCLIFILIAL,
                          NVL((select ATACADISTA
                                from PCATIVI
                               where CODATIV = C.CODATV1),
                              'S') ATACADISTA,
                          case
                            when (C.CODCLI in (1, 2, 3)) then
                             'S'
                            else
                             'N'
                          end CODCLI_123,
                          case
                            when (NVL((select NUMPED
                                        from PCVENDACONSUM
                                       where NUMPED = :new.NUMPED),
                                      0) > 0) and (C.CODCLI in (1, 2, 3)) then
                             'S'
                            else
                             'N'
                          end VENDACONSUM,
                          (select FORNECEDOR
                             from PCFORNEC
                            where CODFORNEC = :new.CODFORNECFRETE) TRANSPORTADORA,
                          (select CGC
                             from PCFORNEC
                            where CODFORNEC = :new.CODFORNECFRETE) CGCFRETE,
                          (select IE
                             from PCFORNEC
                            where CODFORNEC = :new.CODFORNECFRETE) IEFRETE,
                          (select ESTADO
                             from PCFORNEC
                            where CODFORNEC = :new.CODFORNECFRETE) UFFRETE,
                          (select CLIENTE
                             from PCVENDACONSUM
                            where NUMPED = :new.NUMPED) CONSUMIDOR,
                          (select CGCENT
                             from PCVENDACONSUM
                            where NUMPED = :new.NUMPED) CGCCONSUM,
                          (select IEENT
                             from PCVENDACONSUM
                            where NUMPED = :new.NUMPED) IECONSUM,
                          (select ENDERENT
                             from PCVENDACONSUM
                            where NUMPED = :new.NUMPED) ENDERCONSUM,
                          (select BAIRROENT
                             from PCVENDACONSUM
                            where NUMPED = :new.NUMPED) BAIRROCONSUM,
                          (select MUNICENT
                             from PCVENDACONSUM
                            where NUMPED = :new.NUMPED) CIDADECONSUM,
                          (select CEPENT
                             from PCVENDACONSUM
                            where NUMPED = :new.NUMPED) CEPCONSUM,
                          (select ESTENT
                             from PCVENDACONSUM
                            where NUMPED = :new.NUMPED) UFCONSUM,
                          (select CODCIDADE
                             from PCVENDACONSUM
                            where NUMPED = :new.NUMPED) CODCIDADECONSUM,
                          'F' TIPOFJCONSUM,
                          C.PAISENT CODPAIS_CLIENTE,
                          (select CODPAIS from PCPAIS where CODPAIS = E.CODPAIS) CODPAIS,
                          (select DESCRICAO
                             from PCPAIS
                            where CODPAIS = E.CODPAIS) DESCPAIS,
                          (select TELENT
                             from PCVENDACONSUM
                            where NUMPED = :new.NUMPED) TELEFONECONSUM,
                          (select NUMEROENT
                             from PCVENDACONSUM
                            where NUMPED = :new.NUMPED) NUMEROCONSUM,
                          (select EMAIL
                             from PCVENDACONSUM
                            where NUMPED = :new.NUMPED) EMAILCONSUM,
                          FL.CIDADE CIDADEFILIAL,
                          FL.BAIRRO BAIRROFILIAL,
                          FL.ENDERECO ENDERFILIAL,
                          FL.CODMUN CODIBGEFILIAL,
                          FL.CEP CEPFILIAL,
                          FL.CGC CGCFILIAL,
                          FL.IE IEFILIAL,
                          FL.UF UFFILIAL,
                          FL.CODFORNEC CODFORFILIAL,
                          (select ST.IESUBSTTRIBUT
                             from PCINSCRICAOST ST
                            where ST.CODFILIAL = FL.CODIGO
                              and ST.UF = C.ESTENT) IESUBSTTRIBUT,
                          (select V.PLACA
                             from PCCARREG CA, PCVEICUL V
                            where CA.NUMCAR = :new.NUMCAR
                              and NVL(V.SITUACAO(+), '-') <> 'I'
                              and CA.CODVEICULO = V.CODVEICULO(+)) PLACA,
                          (select V.UFPLACAVEICULO
                             from PCCARREG CA, PCVEICUL V
                            where CA.NUMCAR = :new.NUMCAR
                              and NVL(V.SITUACAO(+), '-') <> 'I'
                              and CA.CODVEICULO = V.CODVEICULO(+)) UFPLACA,
                          E.CODIGO UFCODIGO,
                          NVL((select VLPAUTAFRETE
                                from PCPRACA
                               where CODPRACA = :new.CODPRACA),
                              0) VLPAUTAFRETE,
                          (select COBRANCA from PCCOB where CODCOB = :new.CODCOB) COBRANCA,
                          FL.EMAIL EMAILFIL,
                          FL.TELEFONE TELEFONEFIL,
                          TO_CHAR(FL.NUMERO) NUMEROFIL,
                          C.SIMPLESNACIONAL,
                          TRIM(UPPER(C.CLIENTE)) NOME_CLIENTE
                     from PCCLIENT C, PCFILIAL FL, PCESTADO E
                    where C.CODCLI = DECODE(NVL(:new.CODCLINF, 0),
                                            0,
                                            :new.CODCLI,
                                            :new.CODCLINF)
                      and C.ESTENT = E.UF(+)
                      and FL.CODIGO(+) = VCODFILIAL)
     loop
       --------------------------------------------------------------------------------
       -- Processo para integracao com e-commerce
       -- Recuperar na tabela PCENDERECOENTREGAPEDIDO o endereco informado no pedido
       --------------------------------------------------------------------------------
       begin
         select * into VENDERECOENTREGAPEDIDO
         from PCENDERECOENTREGAPEDIDO
         where NUMPED = :new.NUMPED and rownum = 1;
       exception
         when others then
            VENDERECOENTREGAPEDIDO := null;
       end;

       --------------------------------------------------------------------------------
       begin
         select sum(QTCONT * NVL(VLPIS, 0)) VLPIS,
                sum(QTCONT * NVL(VLCOFINS, 0)) VLCOFINS,
                min(CODFISCAL) CODFISCALNF
           into VVLPIS, VVLCOFINS, VCODFISCALNF
           from PCMOV
          where NUMTRANSVENDA = :new.NUMTRANSVENDA
            and DTCANCEL is null
            and QTCONT > 0;
       exception
         when others then
           begin
             VVLPIS    := 0;
             VVLCOFINS := 0;

             begin
               select max(CODFISCAL)
                 into VCODFISCALNF
                 from PCNFBASE
                where NUMTRANSVENDA = :new.NUMTRANSVENDA;
             exception
               when others then
                 null;
             end;
           end;
       end;

       --------------------------------------------------------------------------------
       :new.IEENT        := VSIEENT;
       :new.CLIENTE      := NVL(:new.CLIENTE, case when DADOS.CODCLI_123 = 'S' and DADOS.VENDACONSUM = 'S' then DADOS.CONSUMIDOR else DADOS.CLIENTE end);
       :new.CGC          := NVL(:new.CGC, case when DADOS.CODCLI_123 = 'S' and DADOS.VENDACONSUM = 'S' then DADOS.CGCCONSUM else DADOS.CGCCLIENTE end);
       :new.IE           := NVL(:new.IE, case when DADOS.CODCLI_123 = 'S' and DADOS.VENDACONSUM = 'S' then DADOS.IECONSUM else DADOS.IECLIENTE end);
       :new.ENDERECO     := NVL(VENDERECOENTREGAPEDIDO.ENDERECO, NVL(:new.ENDERECO,
                                GET_VALORCLIENTE(DADOS.CODCLI,
                                                 DADOS.CLIENTE_CONSUMIDOR,
                                                 DADOS.VENDACONSUM,
                                                 DADOS.ENDERCONSUM,
                                                 DADOS.ENDERCLIENTE,
                                                 DADOS.ENDERFILIAL)));
       :new.BAIRRO       := NVL(VENDERECOENTREGAPEDIDO.BAIRRO, NVL(:new.BAIRRO,
                                GET_VALORCLIENTE(DADOS.CODCLI,
                                                 DADOS.CLIENTE_CONSUMIDOR,
                                                 DADOS.VENDACONSUM,
                                                 DADOS.BAIRROCONSUM,
                                                 DADOS.BAIRROCLIENTE,
                                                 DADOS.BAIRROFILIAL)));
       :new.MUNICIPIO    := NVL(VENDERECOENTREGAPEDIDO.MUNICIPIO, NVL(:new.MUNICIPIO,
                                GET_VALORCLIENTE(DADOS.CODCLI,
                                                 DADOS.CLIENTE_CONSUMIDOR,
                                                 DADOS.VENDACONSUM,
                                                 DADOS.CIDADECONSUM,
                                                 DADOS.CIDADECLIENTE,
                                                 DADOS.CIDADEFILIAL)));
       :new.CEP          := NVL(VENDERECOENTREGAPEDIDO.CEP, NVL(:new.CEP,
                                GET_VALORCLIENTE(DADOS.CODCLI,
                                                 DADOS.CLIENTE_CONSUMIDOR,
                                                 DADOS.VENDACONSUM,
                                                 DADOS.CEPCONSUM,
                                                 DADOS.CEPCLIENTE,
                                                 DADOS.CEPFILIAL)));
       :new.UF           := NVL(VENDERECOENTREGAPEDIDO.ESTADO, NVL(:new.UF,
                                GET_VALORCLIENTE(DADOS.CODCLI,
                                                 DADOS.CLIENTE_CONSUMIDOR,
                                                 DADOS.VENDACONSUM,
                                                 DADOS.UFCONSUM,
                                                 DADOS.UFCLIENTE,
                                                 DADOS.UFFILIAL)));
       :new.TIPOFJ       := NVL(:new.TIPOFJ, case when DADOS.CODCLI_123 = 'S' and DADOS.VENDACONSUM = 'S' then DADOS.TIPOFJCONSUM else DADOS.TIPOFJCLIENTE end);
       :new.CODMUNICIPIO := NVL(VENDERECOENTREGAPEDIDO.CODCIDADE,
                                                                  NVL(:new.CODMUNICIPIO, case when DADOS.CODCLI_123 = 'S' and DADOS.VENDACONSUM = 'S' then DADOS.CODCIDADECONSUM else DADOS.CODCIDADECLIENTE end));
       :new.TELEFONE     := NVL(VENDERECOENTREGAPEDIDO.TELEFONE, NVL(:new.TELEFONE,
                                GET_VALORCLIENTE(DADOS.CODCLI,
                                                 DADOS.CLIENTE_CONSUMIDOR,
                                                 DADOS.VENDACONSUM,
                                                 DADOS.TELEFONECONSUM,
                                                 DADOS.TELEFONECLI,
                                                 DADOS.TELEFONEFIL)));
       :new.EMAILDEST    := NVL(:new.EMAILDEST,
                                GET_VALORCLIENTE(DADOS.CODCLI,
                                                 DADOS.CLIENTE_CONSUMIDOR,
                                                 DADOS.VENDACONSUM,
                                                 DADOS.EMAILCONSUM,
                                                 DADOS.EMAILCLI,
                                                 DADOS.EMAILFIL));
       :new.NUMENDERECO  := NVL(VENDERECOENTREGAPEDIDO.NUMERO, NVL(:new.NUMENDERECO,
                                GET_VALORCLIENTE(DADOS.CODCLI,
                                                 DADOS.CLIENTE_CONSUMIDOR,
                                                 DADOS.VENDACONSUM,
                                                 DADOS.NUMEROCONSUM,
                                                 DADOS.NUMEROCLI,
                                                 DADOS.NUMEROFIL)));
       :new.AGREGASTVLMERC := PARAMFILIAL.OBTERCOMOVARCHAR2('AGREGASTVLMERC',
                                                              VCODFILIAL);
       :new.SIMPLESNACIONAL := DADOS.SIMPLESNACIONAL;

       -- ATRIBUINDO CODIBGE
       begin         
         if (((DADOS.CODCLI_123 = 'S') AND (DADOS.NOME_CLIENTE = 'CONSUMIDOR FINAL')) and 
              DADOS.VENDACONSUM = 'N')
         then
           :new.CODIBGE := DADOS.CODIBGEFILIAL;

           --------------------------------------
           select max(NVL(:new.CODMUNICIPIO, CODCIDADE))
             into :new.CODMUNICIPIO
             from PCCIDADE
            where CODIBGE = DADOS.CODIBGEFILIAL;
         else
           select NVL(:new.CODIBGE, CODIBGE)
             into :new.CODIBGE
             from PCCIDADE
            where CODCIDADE = :new.CODMUNICIPIO;
         end if;
       exception
         when others then
           null;
       end;

       :new.CONSUMIDORFINAL   := NVL(:new.CONSUMIDORFINAL, DADOS.CONSUMIDORFINAL);
       :new.CLIENTEFONTEST    := NVL(:new.CLIENTEFONTEST, DADOS.CLIENTEFONTEST);
       :new.SULFRAMA          := NVL(:new.SULFRAMA, DADOS.SULFRAMA);
       :new.ORGAOPUB          := NVL(:new.ORGAOPUB, DADOS.ORGAOPUB);
       :new.ORGAOPUBFEDERAL   := NVL(:new.ORGAOPUBFEDERAL, DADOS.ORGAOPUBFEDERAL);
       :new.ORGAOPUBMUNICIPAL := NVL(:new.ORGAOPUBMUNICIPAL, DADOS.ORGAOPUBMUNICIPAL);
       :new.TIPOEMPRESA       := NVL(:new.TIPOEMPRESA, DADOS.TIPOEMPRESA);
       :new.CONTRIBUINTE      := NVL(:new.CONTRIBUINTE, DADOS.CONTRIBUINTE);
       :new.TRANSPORTADORA    := NVL(:new.TRANSPORTADORA, DADOS.TRANSPORTADORA);
       :new.CGCFRETE          := NVL(:new.CGCFRETE, DADOS.CGCFRETE);
       :new.IEFRETE           := NVL(:new.IEFRETE, DADOS.IEFRETE);
       :new.UFFRETE           := NVL(:new.UFFRETE, DADOS.UFFRETE);
       :new.CODATV1           := NVL(:new.CODATV1, DADOS.CODATV1);
       :new.ATACADISTA        := NVL(:new.ATACADISTA, DADOS.ATACADISTA);
       :new.AGREGASTVLMERC    := PARAMFILIAL.OBTERCOMOVARCHAR2('AGREGASTVLMERC', VCODFILIAL);
       -- tratamento para o país do cliente -------------------------------------------
       begin
         :new.CODPAIS := NVL(:new.CODPAIS,
                             NVL(TO_NUMBER(DADOS.CODPAIS_CLIENTE),
                                 DADOS.CODPAIS));

         select DESCRICAO
           into :new.DESCPAIS
           from PCPAIS
          where CODPAIS = :new.CODPAIS;
       exception
         when others then
           :new.CODPAIS  := NVL(:new.CODPAIS, DADOS.CODPAIS);
           :new.DESCPAIS := NVL(:new.DESCPAIS, DADOS.DESCPAIS);
       end;
       --------------------------------------------------------------------------------
       :new.CGCFILIAL             := NVL(:new.CGCFILIAL, DADOS.CGCFILIAL);
       :new.IEFILIAL              := NVL(:new.IEFILIAL, DADOS.IEFILIAL);
       :new.UFFILIAL              := NVL(:new.UFFILIAL, DADOS.UFFILIAL);
       :new.CODCLIFILIAL          := NVL(:new.CODCLIFILIAL, DADOS.CODCLIFILIAL);
       :new.CODCONTCLI            := NVL(:new.CODCONTCLI, VCODCONTCLI);
       :new.AGREGARSTPRODSINTEGRA := NVL(:new.AGREGARSTPRODSINTEGRA, VAGREGARSTPRODSINTEGRA);
       :new.TIPOALIQOUTRASDESP    := NVL(:new.TIPOALIQOUTRASDESP, VTIPOALIQOUTRASDESP);
       :new.IESUBSTTRIBUT         := NVL(:new.IESUBSTTRIBUT, DADOS.IESUBSTTRIBUT);
       :new.PLACAVEIC             := NVL(:new.PLACAVEIC, DADOS.PLACA);
       :new.UFPLACAVEIC           := NVL(:new.UFPLACAVEIC, DADOS.UFPLACA        );
       :new.UFCODIGO              := NVL(:new.UFCODIGO, DADOS.UFCODIGO);
       :new.VLPAUTAFRETE          := NVL(:new.VLPAUTAFRETE, DADOS.VLPAUTAFRETE);
       :new.COBRANCA              := SUBSTR(NVL(:new.COBRANCA, DADOS.COBRANCA), 1, 30);
       :new.VLPIS                 := NVL(:new.VLPIS, VVLPIS);
       :new.VLCOFINS              := NVL(:new.VLCOFINS, VVLCOFINS);
       :new.CODFISCALNF           := VCODFISCALNF;
       :new.SITUACAONFE           := NVL(:new.SITUACAONFE, 0);
       IF :NEW.TIPOVENDA <> 'DF' THEN
          :new.GERARBCRNFE := VGERARBCRNFE;
       END IF;

       begin
         :new.AMBIENTENFE := PARAMFILIAL.OBTERCOMOVARCHAR2('AMBIENTENFE', VCODFILIAL);
       exception
         when others then
         begin
           :new.AMBIENTENFE := -1;
           GERAR_LOG(sqlerrm, 'Erro na trigger T_PCNFSAID_HISTORICO');
         end;  
       end;
       
       begin
         :new.AMBIENTECTE := PARAMFILIAL.OBTERCOMOVARCHAR2('AMBIENTECTE', VCODFILIAL);
       exception
         when others then
         begin
           :new.AMBIENTECTE := -1;
           GERAR_LOG(sqlerrm, 'Erro na trigger T_PCNFSAID_HISTORICO');
         end;  
       end;

       :new.HISTORICO := 'S';
     end loop;

     -- INFORMAÇÕES DE TRIBUTAÇÃO DE FRETE E DESP.ACESSORIA
     -------------------------------------------------------------------------------------------------------
     --  ATUALIZAR_TRIBUTACOES();
     -------------------------------------------------------------------------------------------------------
     :new.CODFISCALFRETE      := NVL(:new.CODFISCALFRETE, VCFOPFRETE);
     :new.CODFISCALOUTRASDESP := NVL(:new.CODFISCALOUTRASDESP, VCFOPDESPESA);
     :new.PERCICMFRETE        := NVL(:new.PERCICMFRETE, VALIQICMSFRETE);
     :new.ALIQICMOUTRASDESP   := NVL(:new.ALIQICMOUTRASDESP, VALIQICMSDESPESA);
     -------------------------------------------------------------------------------------------------------     
     :new.DEDUZIRICMSBASEPISCOFINS := NVL(:new.DEDUZIRICMSBASEPISCOFINS, PARAMFILIAL.OBTERCOMOVARCHAR2('EXCLUIRICMSBASEPISCOFINS', VCODFILIAL));
     
     :new.TIPOIMPRESSAO := NVL(:new.TIPOIMPRESSAO, VTIPODANFE);
  END IF;
   -------------------------------------------------------------------------------------
   -- GRAVANDO NA TABELA PCMOVCOMPLE
   -------------------------------------------------------------------------------------
   IF (:NEW.SITUACAONFE > 0) AND (:NEW.SITUACAONFE not in (101,102)) AND (:NEW.SITUACAONFE <> :OLD.SITUACAONFE) THEN
     
   IF (UPDATING AND :NEW.DATACONSOLIDACAOPREFAT IS NULL) THEN
     
      FOR CR_PCMOV IN (SELECT PCMOV.NUMTRANSITEM,
                              PCMOV.NUMTRANSVENDA,
                              PCMOV.CODPROD,
                              PCMOV.NUMSEQ,
                              PCMOV.NUMNOTA,
                              PCMOVCOMPLE.ORIGMERCTRIB ORIGMERCTRIB_MOV,
                              NVL(PCPRODFILIAL.ORIGMERCTRIB, DECODE(PCMOV.IMPORTADO, 'S', '2', DECODE(PCMOV.IMPORTADO, 'D', '1', '0'))) ORIGMERCTRIB
                      FROM PCMOV,
                           PCMOVCOMPLE,
                           PCPRODFILIAL
                      WHERE PCMOV.NUMTRANSVENDA = :OLD.NUMTRANSVENDA
                        AND PCMOV.NUMNOTA = :OLD.NUMNOTA
                          AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                          AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCPRODFILIAL.CODFILIAL(+)
                          AND PCMOV.CODPROD = PCPRODFILIAL.CODPROD(+)
                      ) LOOP
         IF (CR_PCMOV.ORIGMERCTRIB_MOV IS NULL) AND (:NEW.SITUACAONFE > 0) AND (:NEW.SITUACAONFE not in (101,102)) AND (:NEW.SITUACAONFE <> :OLD.SITUACAONFE)
         THEN
            IF (NVL(CR_PCMOV.NUMTRANSITEM, 0) > 0)
            THEN
               UPDATE PCMOVCOMPLE SET
                      PCMOVCOMPLE.ORIGMERCTRIB = CR_PCMOV.ORIGMERCTRIB
               WHERE PCMOVCOMPLE.NUMTRANSITEM = CR_PCMOV.NUMTRANSITEM
                 AND PCMOVCOMPLE.ORIGMERCTRIB IS NULL;
            END IF;

            IF (NVL(CR_PCMOV.NUMTRANSITEM, 0) = 0)
            THEN
               SELECT DFSEQ_PCMOVCOMPLE.NEXTVAL
               INTO VNUMTRANSITEM
               FROM DUAL;

               IF VNUMTRANSITEM > 0
               THEN
                  INSERT INTO PCMOVCOMPLE (ORIGMERCTRIB, NUMTRANSITEM)
                                   VALUES (CR_PCMOV.ORIGMERCTRIB, VNUMTRANSITEM);

                  UPDATE PCMOV SET NUMTRANSITEM = VNUMTRANSITEM
                  WHERE NUMTRANSVENDA = CR_PCMOV.NUMTRANSVENDA
                    AND NUMNOTA = CR_PCMOV.NUMNOTA
                    AND CODPROD = CR_PCMOV.CODPROD
                    AND NUMSEQ = CR_PCMOV.NUMSEQ;
               END IF;
            END IF;
         END IF;
      END LOOP;
      
       --------------------------------------------------------------------------------
       --bloco abaixo serve para atualizar o cfop no cabeçalho da nota, também quando editado
       --0.149304.2016 - Eddy - 05/01/2016
       begin
         select min(CODFISCAL) CODFISCALNF
           into VCODFISCALNF
           from PCMOV
          where NUMTRANSVENDA = :new.NUMTRANSVENDA
            and DTCANCEL is null
            and QTCONT > 0;
       exception
         when others then
           begin
             begin
               select max(CODFISCAL)
                 into VCODFISCALNF
                 from PCNFBASE
                where NUMTRANSVENDA = :new.NUMTRANSVENDA;
             exception
               when others then
                 null;
             end;
           end;
       end;
         
       :new.CODFISCALNF := VCODFISCALNF;
      --------------------------------------------------------------------------------
      
    END IF; --IF UPDATE
  END IF;
exception
  when VERRO_TRIBUTACAO then
    begin
      GERAR_LOG(VMENSAGEM_ERRO,null);
    end;
  when others then
    begin
      GERAR_LOG(sqlerrm, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      exception
       when others then
       begin
         GERAR_LOG(sqlerrm, 'Erro na trigger T_PCNFSAID_HISTORICO');
       end;
    end;
end;