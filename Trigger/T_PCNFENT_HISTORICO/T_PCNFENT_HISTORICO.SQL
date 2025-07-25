CREATE OR REPLACE TRIGGER T_PCNFENT_HISTORICO BEFORE INSERT OR UPDATE
       ON PCNFENT REFERENCING NEW AS NEW FOR EACH ROW
declare
  /************************************************************************************************
  Proposito: Trigger para gravação dos dados de cadastro (historico de movimentação)

  Rotina: Pacote

  Utilizada por: rotinas que fazem inclusão na PCNFENT
  ------------------------------------------------------------------------------------------------
  Data        Responsavel     Descricao
  ----------  --------------  --------------------------------------------------------------------*
  17/11/2008  Ricardo         Criação da trigger
  03/09/2010  Natanael        Trigger alterada para gravar o AmbienteNFE no qual a nota foi aprovada.
  ************************************************************************************************/

  VTIPOALIQOUTRASDESP          varchar2(1);
  VAGREGARSTPRODSINTEGRA       varchar2(1);
  VCODCONTFOR                  number(10);
  VCODCONTFRE                  number(10);
  VPERCICMFRETE                number(4, 2);
  VPERCICMINTERFRETE           number(4, 2);
  VALIQICMOUTRASDESP           number(4, 2);
  VALIQICMINTEROUTRASDESP      number(4, 2);
  VCODFISCALFRETE              number(4);
  VCODFISCALINTERFRETE         number(4);
  VCODFISCALDEVOUTRASDESP      number(4);
  VCODFISCALINTERDEVOUTRASDESP number(4);
  VUFFILIAL                    varchar2(2);
  VCODFILIAL                   varchar2(2);
  VCFOPFRETE                   number(4);
  VCFOPDESPESA                 number(4);
  VALIQICMSFRETE               number(4, 2);
  VALIQICMSDESPESA             number(4, 2);
  VVLPIS                       number(22, 2);
  VVLCOFINS                    number(22, 2);
  v_GERARBCRNFE                VARCHAR2(1);
  VERRO_TRIBUTACAO             exception;
  VMENSAGEM_ERRO               varchar2(200);
  VNUMTRANSITEM                NUMBER;
  VTIPODANFE                   PCFILIAL.TIPODANFE%type;  
  ------------------------------------------------------------------------------------------------
  -- FUNÇÕES GERAR LOG SE OCORRER UM ERRO
  ------------------------------------------------------------------------------------------------
  procedure GERAR_LOG(PMENSAGEM_ERRO in varchar2) is
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
       'PCNFENT',
       'INDEFINIDA',
       'A',
       'ERRO NA INCLUSÃO DO REGISTRO',
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       'ERRO TRIGGER HISTORICO: NUMTRANSENT: ' ||
       TO_CHAR(NVL(:new.NUMTRANSENT, 0)) || ' NUMNOTA: ' ||
       TO_CHAR(NVL(:new.NUMNOTA, 0)),
       'ERRO ORIGINAL: ' || PMENSAGEM_ERRO);
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
  -- FUNÇÕES PARA RESUPERAR INFORMAÇÕES SOBRE A TRIBUTAÇÃO DE FRETE E DESPESAS ACESSORRIAS
  ------------------------------------------------------------------------------------------------
  procedure ATUALIZAR_TRIBUTACOES is
  begin
    if VTIPOALIQOUTRASDESP <> 'T'
    then
      VCFOPFRETE       := case when VUFFILIAL = :new.UF then VCODFISCALFRETE else VCODFISCALINTERFRETE end;
      VCFOPDESPESA     := case when VUFFILIAL = :new.UF then VCODFISCALDEVOUTRASDESP else VCODFISCALINTERDEVOUTRASDESP end;
      VALIQICMSFRETE   := case when VUFFILIAL = :new.UF then VPERCICMFRETE else VPERCICMINTERFRETE end;
      VALIQICMSDESPESA := case when VUFFILIAL = :new.UF then VALIQICMOUTRASDESP else VALIQICMINTEROUTRASDESP end;
    else
      begin
        select DECODE(:new.TIPODESCARGA,
                      '6',
                      NVL(CODFISCALFRETEDEVCLI, CODFISCALFRETEENT),
                      '8',
                      NVL(CODFISCALFRETEDEVCLI, CODFISCALFRETEENT),
                      'T',
                      NVL(CODFISCALFRETEDEVCLI, CODFISCALFRETEENT),
                      CODFISCALFRETEENT),
               CODFISCALOUTRASDESPENT,
               DECODE(:new.TIPODESCARGA,
                      '6',
                      NVL(ALIQICMFRETEDEVCLI, ALIQICMFRETEENT),
                      '8',
                      NVL(ALIQICMFRETEDEVCLI, ALIQICMFRETEENT),
                      'T',
                      NVL(ALIQICMFRETEDEVCLI, ALIQICMFRETEENT),
                      ALIQICMFRETEENT),
               ALIQICMOUTRASDESPENT
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
  IF INSERTING THEN
      -- BUSCAR PARAMETROS
      ----------------------------------------------------------------------------------
      select TIPOALIQOUTRASDESP,
            AGREGARSTPRODSINTEGRA,
            CODCONTFOR,
            CODCONTFRE,
            PERCICMFRETEENT,
            PERCICMINTERFRETEENT,
            CODFISCALFRETEENT,
            CODFISCALINTERFRETEENT,
            ALIQICMOUTRASDESP,
            ALIQICMINTEROUTRASDESP,
            CODFISCALDEVOUTRASDESP,
            CODFISCALINTERDEVOUTRASDESP
       into VTIPOALIQOUTRASDESP,
            VAGREGARSTPRODSINTEGRA,
            VCODCONTFOR,
            VCODCONTFRE,
            VPERCICMFRETE,
            VPERCICMINTERFRETE,
            VCODFISCALFRETE,
            VCODFISCALINTERFRETE,
            VALIQICMOUTRASDESP,
            VALIQICMINTEROUTRASDESP,
            VCODFISCALDEVOUTRASDESP,
            VCODFISCALINTERDEVOUTRASDESP
       from PCCONSUM;
      ----------------------------------------------------------------------------------
      -- BUSCAR PARAMETROS POR FILIAL
      ----------------------------------------------------------------------------------
      select CODIGO, UF, TIPODANFE
      into VCODFILIAL, VUFFILIAL, VTIPODANFE
      from PCFILIAL
      where CODIGO = NVL(:new.CODFILIALNF, :new.CODFILIAL);
      ----------------------------------------------------------------------------------
      if VTIPOALIQOUTRASDESP = 'F'
      then
       select ALIQICMOUTRASDESP,
              ALIQICMINTEROUTRASDESP,
              CODFISCALDEVOUTRASDESP,
              CODFISCALINTERDEVOUTRASDESP
       into VALIQICMOUTRASDESP,
            VALIQICMINTEROUTRASDESP,
            VCODFISCALDEVOUTRASDESP,
            VCODFISCALINTERDEVOUTRASDESP
       from PCFILIAL
       where CODIGO = VCODFILIAL;
      end if;
      ----------------------------------------------------------------------------------
      -- BUSCAR PARAMETROS DE TRIBUTAÇÃO ICMS BCR NFE POR FILIAL
      ----------------------------------------------------------------------------------
      begin
        select DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('GERARBCRNFE',  NVL(:new.CODFILIALNF, :new.CODFILIAL)), 'N'),
                                                       'S', 'S',  'N')
        into V_GERARBCRNFE
        from DUAL;
        ----------------------------------------------------------------------------------
        exception
        when others then
        V_GERARBCRNFE       := 'N';
      end;
      ----------------------------------------------------------------------------------------
      -- ENTRADAS DE NOTAS DUPLICADAS
      ----------------------------------------------------------------------------------------
     if NVL(:new.NOTADUPLIQUESVC,'N') = 'S' then
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
                             C.CODCIDADE CODCIDADECLIENTE,
                             C.CEPENT CEPCLIENTE,
                             C.ESTENT UFCLIENTE,
                             C.TIPOFJ TIPOFJCLIENTE,
                             C.CONSUMIDORFINAL,
                             C.EMAIL EMAILCLI,
                             C.TELENT TELEFONECLI,
                             C.NUMEROENT NUMEROCLI,
                             NVL((select ATACADISTA from PCATIVI where CODATIV = C.CODATV1), 'S') ATACADISTA,
                             case
                               when DECODE(NVL(:new.CODFORNECNF, 0),
                                           0,
                                           :new.CODFORNEC,
                                           :new.CODFORNECNF) in (1, 2, 3) then
                                'S'
                               else
                                'N'
                             end CODCLI_123,
                             case
                               when ((select NUMTRANSENT
                                        from PCDEVCONSUM
                                       where NUMTRANSENT = INU.NUMTRANSACAO) > 0) and
                                    (DECODE(NVL(:new.CODFORNECNF, 0),
                                            0,
                                            :new.CODFORNEC,
                                            :new.CODFORNECNF) in (1, 2, 3)) then
                                'S'
                               else
                                'N'
                             end DEVCONSUM,
                             (select CLIENTE from PCDEVCONSUM where NUMTRANSENT = INU.NUMTRANSACAO) CONSUMIDOR,
                             (select CGC from PCDEVCONSUM where NUMTRANSENT = INU.NUMTRANSACAO) CGCCONSUM,
                             (select IE from PCDEVCONSUM where NUMTRANSENT = INU.NUMTRANSACAO) IECONSUM,
                             (select ENDERECO
                                from PCDEVCONSUM
                               where NUMTRANSENT = INU.NUMTRANSACAO) ENDERCONSUM,
                             (select BAIRRO from PCDEVCONSUM where NUMTRANSENT = INU.NUMTRANSACAO) BAIRROCONSUM,
                             (select CIDADE from PCDEVCONSUM where NUMTRANSENT = INU.NUMTRANSACAO) CIDADECONSUM,
                             (select CODCIDADE
                                from PCDEVCONSUM
                               where NUMTRANSENT = INU.NUMTRANSACAO) CODCIDADECONSUM,
                             (select CEP from PCDEVCONSUM where NUMTRANSENT = INU.NUMTRANSACAO) CEPCONSUM,
                             (select UF from PCDEVCONSUM where NUMTRANSENT = INU.NUMTRANSACAO) UFCONSUM,
                             'F' TIPOFJCONSUM,
                             C.PAISENT CODPAIS_CLIENTE,
                             (select CODPAIS from PCPAIS where CODPAIS = E.CODPAIS) CODPAIS,
                             (select DESCRICAO from PCPAIS where CODPAIS = E.CODPAIS) DESCPAIS,
                             (select EMAIL from PCDEVCONSUM where NUMTRANSENT = INU.NUMTRANSACAO) EMAILCONSUM,
                             (select TELEFONE
                                from PCDEVCONSUM
                               where NUMTRANSENT = INU.NUMTRANSACAO) TELEFONECONSUM,
                             FL.CIDADE CIDADEFILIAL,
                             FL.BAIRRO BAIRROFILIAL,
                             FL.ENDERECO ENDERFILIAL,
                             FL.CODMUN CODIBGEFILIAL,
                             FL.CEP CEPFILIAL,
                             FL.CGC CGCFILIAL,
                             FL.IE IEFILIAL,
                             FL.UF UFFILIAL,
                             FL.CODFORNEC CODFORFILIAL,
                             FL.EMAIL EMAILFILIAL,
                             FL.TELEFONE TELEFONEFILIAL,
                             TO_CHAR(FL.NUMERO) NUMEROFILIAL,
                             (select ST.IESUBSTTRIBUT
                        from PCINSCRICAOST ST
                       where ST.CODFILIAL = FL.CODIGO
                         and ST.UF = C.ESTENT) IESUBSTTRIBUT,
                     E.CODIGO UFCODIGO,
                     C.CONTRIBUINTE,
                     INU.NUMTRANSACAO TRANSANTIGO
                from PCCLIENT        C,
                     PCFILIAL        FL,
                     PCESTADO        E,
                     PCINUTILIZARNFE INU
               where INU.NUMTRANSACAONOVA = :new.Numtransent
                 and C.CODCLI = DECODE(NVL(:new.CODFORNECNF, 0),
                                           0,
                                           :new.CODFORNEC,
                                           :new.CODFORNECNF)
                 and C.UFRG = E.UF(+)
                 and FL.CODIGO(+) = VCODFILIAL )
        loop

          --------------------------------------------------------------------------------
         begin
           select sum(QTCONT * NVL(VLCREDPIS, 0)) VLPIS,
                  sum(QTCONT * NVL(VLCREDCOFINS, 0)) VLCOFINS
             into VVLPIS, VVLCOFINS
             from PCMOV
            where NUMTRANSENT = DADOS.TRANSANTIGO
              and DTCANCEL is null
              and QTCONT > 0;
         exception
           when others then
             begin
               VVLPIS    := 0;
               VVLCOFINS := 0;
             end;
         end;
         --------------------------------------------------------------------------------
         :new.FORNECEDOR      := NVL(:new.FORNECEDOR, case when DADOS.DEVCONSUM = 'S' then DADOS.CONSUMIDOR else DADOS.CLIENTE end);
         :new.CGC             := NVL(:new.CGC, case when DADOS.DEVCONSUM = 'S' then DADOS.CGCCONSUM else DADOS.CGCCLIENTE end);
         :new.IE              := NVL(:new.IE, case when DADOS.DEVCONSUM = 'S' then DADOS.IECONSUM else DADOS.IECLIENTE end);
         :new.ENDERECO        := NVL(:new.ENDERECO,
                                     GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.DEVCONSUM,
                                                      DADOS.ENDERCONSUM,
                                                      DADOS.ENDERCLIENTE,
                                                      DADOS.ENDERFILIAL));
         :new.BAIRRO          := NVL(:new.BAIRRO,
                                     GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.DEVCONSUM,
                                                      DADOS.BAIRROCONSUM,
                                                      DADOS.BAIRROCLIENTE,
                                                      DADOS.BAIRROFILIAL));
         :new.MUNICIPIO       := NVL(:new.MUNICIPIO,
                                     GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.DEVCONSUM,
                                                      DADOS.CIDADECONSUM,
                                                      DADOS.CIDADECLIENTE,
                                                      DADOS.CIDADEFILIAL));
         :new.CEP             := NVL(:new.CEP,
                                     GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.DEVCONSUM,
                                                      DADOS.CEPCONSUM,
                                                      DADOS.CEPCLIENTE,
                                                      DADOS.CEPFILIAL));
         :new.UF              := NVL(:new.UF,
                                     GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.DEVCONSUM,
                                                      DADOS.UFCONSUM,
                                                      DADOS.UFCLIENTE,
                                                      DADOS.UFFILIAL));
         :new.TIPOFJ          := NVL(:new.TIPOFJ, case when DADOS.CODCLI_123 = 'S' and DADOS.DEVCONSUM = 'S' then DADOS.TIPOFJCONSUM else DADOS.TIPOFJCLIENTE end);
         :new.CODMUNICIPIO    := NVL(:new.CODMUNICIPIO, case when DADOS.CODCLI_123 = 'S' and DADOS.DEVCONSUM = 'S' then DADOS.CODCIDADECONSUM else DADOS.CODCIDADECLIENTE end);
         :new.CONSUMIDORFINAL := NVL(:new.CONSUMIDORFINAL,
                                     DADOS.CONSUMIDORFINAL);
         :NEW.CONTRIBUINTE    := NVL(:new.CONTRIBUINTE, DADOS.CONTRIBUINTE);               
         :new.EMAILDEST       := NVL(:new.EMAILDEST,
                                     GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.DEVCONSUM,
                                                      DADOS.EMAILCONSUM,
                                                      DADOS.EMAILCLI,
                                                      DADOS.EMAILFILIAL));
         :new.TELEFONE        := NVL(:new.TELEFONE,
                                     GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.DEVCONSUM,
                                                      DADOS.TELEFONECONSUM,
                                                      DADOS.TELEFONECLI,
                                                      DADOS.TELEFONEFILIAL));
         :new.NUMEROEND       := NVL(:new.NUMEROEND,
                                     GET_VALORCLIENTE(DADOS.CODCLI,
                                                      'N',
                                                      DADOS.DEVCONSUM,
                                                      '',
                                                      DADOS.NUMEROCLI,
                                                      DADOS.NUMEROFILIAL));
         :new.AGREGASTVLMERC  := PARAMFILIAL.OBTERCOMOVARCHAR2('AGREGASTVLMERC',
                                                               VCODFILIAL);
         --------------------------------------------------------------------------------
         -- ATRIBUINDO CODIBGE
         begin
           if DADOS.CODCLI_123 = 'S' and DADOS.DEVCONSUM = 'N'
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
         --------------------------------------------------------------------------------
         :new.ATACADISTA := NVL(:new.ATACADISTA, DADOS.ATACADISTA);

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
         :new.CODCONTFOR            := NVL(:new.CODCONTFOR, VCODCONTFOR);
         :new.CODCONTFRE            := NVL(:new.CODCONTFRE, VCODCONTFRE);
         :new.AGREGARSTPRODSINTEGRA := NVL(:new.AGREGARSTPRODSINTEGRA,
                                           VAGREGARSTPRODSINTEGRA);
         :new.TIPOALIQOUTRASDESP    := NVL(:new.TIPOALIQOUTRASDESP,
                                           VTIPOALIQOUTRASDESP);
         :new.IESUBSTTRIBUT         := NVL(:new.IESUBSTTRIBUT,
                                           DADOS.IESUBSTTRIBUT);
         :new.UFCODIGO              := NVL(:new.UFCODIGO, DADOS.UFCODIGO);
         :new.VLCREDPIS             := VVLPIS;
         :new.VLCREDCOFINS          := VVLCOFINS;
         :new.GERARBCRNFE           := V_GERARBCRNFE;
         begin           
           if (NVL(:new.ESPECIE, '') = 'CO' OR NVL(:new.ESPECIE, '') = 'CE') then
             :new.AMBIENTENFE := PARAMFILIAL.OBTERCOMOVARCHAR2('AMBIENTECTE', VCODFILIAL);
           else 
             :new.AMBIENTENFE := PARAMFILIAL.OBTERCOMOVARCHAR2('AMBIENTENFE', VCODFILIAL);
           end if;
         exception
           when others then
             :new.AMBIENTENFE := null;
         end;

         :new.HISTORICO := 'S';
         
        end loop;
      ----------------------------------------------------------------------------------------
      -- DADOS DE ENTRADAS NORMAIS
      ----------------------------------------------------------------------------------


      elsif :new.TIPODESCARGA not in ('6','7','8','C','T') then
       for DADOS in (select F.FORNECEDOR,
                            F.CGC CGCFORNEC,
                            F.IE IEFORNEC,
                            F.ENDER,
                            F.BAIRRO,
                            F.CIDADE,
                            F.CODCIDADE,
                            F.CEP,
                            F.ESTADO UFFORNEC,
                            F.TIPOFRETECIFFOB,
                            F.TIPOFORNEC,
                            F.REVENDA,
                            F.INDUSTRIALOCAL,
                            F.PERCPISRED,
                            F.TELREP,
                            F.EMAIL,
                            F.NUMEROEND,
                            NVL(F.CODPAIS, E.CODPAIS) CODPAIS,
                            (select DESCRICAO
                               from PCPAIS
                              where CODPAIS = NVL(F.CODPAIS, E.CODPAIS)) DESCPAIS,
                            FL.CGC CGCFILIAL,
                            FL.IE IEFILIAL,
                            FL.UF UFFILIAL,
                            FL.CODFORNEC CODFORFILIAL,
                            F.CODCONTAB,
                            (select ST.IESUBSTTRIBUT
                               from PCINSCRICAOST ST
                              where ST.CODFILIAL = FL.CODIGO
                                and ST.UF = F.ESTADO) IESUBSTTRIBUT,
                            E.CODIGO UFCODIGO,
                            F.CONSUMIDORFINAL,
              F.CONTRIBUINTEICMS AS CONTRIBUINTE
                       from PCFORNEC F, PCFILIAL FL, PCESTADO E
                      where F.CODFORNEC = NVL(:new.CODFORNECNF, :new.CODFORNEC)
                        and F.ESTADO = E.UF(+)
                        and FL.CODIGO(+) = VCODFILIAL)
       loop
         :new.FORNECEDOR   := NVL(:new.FORNECEDOR, DADOS.FORNECEDOR);
         :new.CGC          := NVL(:new.CGC, DADOS.CGCFORNEC);
         :new.IE           := NVL(:new.IE, DADOS.IEFORNEC);
         :new.ENDERECO     := NVL(:new.ENDERECO, DADOS.ENDER);
         :new.BAIRRO       := NVL(:new.BAIRRO, DADOS.BAIRRO);
         :new.MUNICIPIO    := NVL(:new.MUNICIPIO, DADOS.CIDADE);
         :new.CODMUNICIPIO := NVL(:new.CODMUNICIPIO, DADOS.CODCIDADE);
         -- ATRIBUINDO CODIBGE
         begin
           select NVL(:new.CODIBGE, CODIBGE)
             into :new.CODIBGE
             from PCCIDADE
            where CODCIDADE = :new.CODMUNICIPIO;
           exception
           when others then
             null;
         end;
         :new.CEP                   := NVL(:new.CEP, DADOS.CEP);
         :new.UF                    := NVL(:new.UF, DADOS.UFFORNEC);
         :new.TIPOFJ                := NVL(:new.TIPOFJ, 'J');
         :new.TIPOFRETECIFFOB       := NVL(:new.TIPOFRETECIFFOB,
                                           DADOS.TIPOFRETECIFFOB);
         :new.TIPOFORNEC            := NVL(:new.TIPOFORNEC, DADOS.TIPOFORNEC);
         :new.REVENDA               := NVL(:new.REVENDA, DADOS.REVENDA);
         :new.INDUSTRIALOCAL        := NVL(:new.INDUSTRIALOCAL,
                                           DADOS.INDUSTRIALOCAL);
         :new.PERCPISRED            := NVL(:new.PERCPISRED, DADOS.PERCPISRED);
         :new.CODPAIS               := NVL(:new.CODPAIS, DADOS.CODPAIS);
         :new.DESCPAIS              := NVL(:new.DESCPAIS, DADOS.DESCPAIS);
         :new.CGCFILIAL             := NVL(:new.CGCFILIAL, DADOS.CGCFILIAL);
         :new.IEFILIAL              := NVL(:new.IEFILIAL, DADOS.IEFILIAL);
         :new.UFFILIAL              := NVL(:new.UFFILIAL, DADOS.UFFILIAL);
         :new.CODFORFILIAL          := NVL(:new.CODFORFILIAL,
                                           DADOS.CODFORFILIAL);
         :new.CODCONTABFORNEC       := NVL(:new.CODCONTABFORNEC,
                                           DADOS.CODCONTAB);
         :new.CODCONTFOR            := NVL(:new.CODCONTFOR, VCODCONTFOR);
         :new.CODCONTFRE            := NVL(:new.CODCONTFRE, VCODCONTFRE);
         :new.IESUBSTTRIBUT         := NVL(:new.IESUBSTTRIBUT,
                                           DADOS.IESUBSTTRIBUT);
         :new.AGREGARSTPRODSINTEGRA := NVL(:new.AGREGARSTPRODSINTEGRA,
                                           VAGREGARSTPRODSINTEGRA);
         :new.TIPOALIQOUTRASDESP    := NVL(:new.TIPOALIQOUTRASDESP,
                                           VTIPOALIQOUTRASDESP);
         :new.UFCODIGO              := NVL(:new.UFCODIGO, DADOS.UFCODIGO);
         :new.EMAILDEST             := NVL(:new.EMAILDEST, DADOS.EMAIL);
         :new.TELEFONE              := NVL(:new.TELEFONE, DADOS.TELREP);
         :new.NUMEROEND             := NVL(:new.NUMEROEND, DADOS.NUMEROEND);
         :new.AGREGASTVLMERC        := PARAMFILIAL.OBTERCOMOVARCHAR2('AGREGASTVLMERC',
                                                                      VCODFILIAL);
         :new.CONSUMIDORFINAL       := NVL(:new.CONSUMIDORFINAL, DADOS.CONSUMIDORFINAL);  
         :NEW.CONTRIBUINTE          := NVL(:new.CONTRIBUINTE, DADOS.CONTRIBUINTE);
     
         begin
           if (NVL(:new.ESPECIE, '') = 'CO' OR NVL(:new.ESPECIE, '') = 'CE') then
             :new.AMBIENTENFE := PARAMFILIAL.OBTERCOMOVARCHAR2('AMBIENTECTE', VCODFILIAL);
           else 
             :new.AMBIENTENFE := PARAMFILIAL.OBTERCOMOVARCHAR2('AMBIENTENFE', VCODFILIAL);
           end if;
           exception
           when others then
             begin
               :new.AMBIENTENFE := -1;
               GERAR_LOG(sqlerrm);
             end;  
         end;

         :new.HISTORICO := 'S';
       end loop;
      else
       -- DADOS DE DEVOLUÇÕES DE CLIENTE
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
                            C.CODCIDADE CODCIDADECLIENTE,
                            C.CEPENT CEPCLIENTE,
                            C.ESTENT UFCLIENTE,
                            C.TIPOFJ TIPOFJCLIENTE,
                            C.CONSUMIDORFINAL,
                            C.EMAIL EMAILCLI,
                            C.TELENT TELEFONECLI,
                            C.NUMEROENT NUMEROCLI,
                            NVL((select ATACADISTA
                                  from PCATIVI
                                 where CODATIV = C.CODATV1),
                                'S') ATACADISTA,
                            case
                              when DECODE(NVL(:new.CODFORNECNF, 0),
                                          0,
                                          :new.CODFORNEC,
                                          :new.CODFORNECNF) in (1, 2, 3) then
                               'S'
                              else
                               'N'
                            end CODCLI_123,
                            case
                              when ((select NUMTRANSENT
                                       from PCDEVCONSUM
                                      where NUMTRANSENT = :new.NUMTRANSENT) > 0) and
                                   (DECODE(NVL(:new.CODFORNECNF, 0),
                                           0,
                                           :new.CODFORNEC,
                                           :new.CODFORNECNF) in (1, 2, 3)) then
                               'S'
                              else
                               'N'
                            end DEVCONSUM,
                            (select CLIENTE
                               from PCDEVCONSUM
                              where NUMTRANSENT = :new.NUMTRANSENT) CONSUMIDOR,
                            (select CGC
                               from PCDEVCONSUM
                              where NUMTRANSENT = :new.NUMTRANSENT) CGCCONSUM,
                            (select IE
                               from PCDEVCONSUM
                              where NUMTRANSENT = :new.NUMTRANSENT) IECONSUM,
                            (select ENDERECO
                               from PCDEVCONSUM
                              where NUMTRANSENT = :new.NUMTRANSENT) ENDERCONSUM,
                            (select BAIRRO
                               from PCDEVCONSUM
                              where NUMTRANSENT = :new.NUMTRANSENT) BAIRROCONSUM,
                            (select CIDADE
                               from PCDEVCONSUM
                              where NUMTRANSENT = :new.NUMTRANSENT) CIDADECONSUM,
                            (select CODCIDADE
                               from PCDEVCONSUM
                              where NUMTRANSENT = :new.NUMTRANSENT) CODCIDADECONSUM,
                            (select CEP
                               from PCDEVCONSUM
                              where NUMTRANSENT = :new.NUMTRANSENT) CEPCONSUM,
                            (select UF
                               from PCDEVCONSUM
                              where NUMTRANSENT = :new.NUMTRANSENT) UFCONSUM,
                            'F' TIPOFJCONSUM,
                            C.PAISENT CODPAIS_CLIENTE,
                            (select CODPAIS
                               from PCPAIS
                              where CODPAIS = E.CODPAIS) CODPAIS,
                            (select DESCRICAO
                               from PCPAIS
                              where CODPAIS = E.CODPAIS) DESCPAIS,
                            (select EMAIL
                               from PCDEVCONSUM
                              where NUMTRANSENT = :new.NUMTRANSENT) EMAILCONSUM,
                            (select TELEFONE
                               from PCDEVCONSUM
                              where NUMTRANSENT = :new.NUMTRANSENT) TELEFONECONSUM,
                            FL.CIDADE CIDADEFILIAL,
                            FL.BAIRRO BAIRROFILIAL,
                            FL.ENDERECO ENDERFILIAL,
                            FL.CODMUN CODIBGEFILIAL,
                            FL.CEP CEPFILIAL,
                            FL.CGC CGCFILIAL,
                            FL.IE IEFILIAL,
                            FL.UF UFFILIAL,
                            FL.CODFORNEC CODFORFILIAL,
                            FL.EMAIL EMAILFILIAL,
                            FL.TELEFONE TELEFONEFILIAL,
                            TO_CHAR(FL.NUMERO) NUMEROFILIAL,
                            (select ST.IESUBSTTRIBUT
                               from PCINSCRICAOST ST
                              where ST.CODFILIAL = FL.CODIGO
                                and ST.UF = C.ESTENT) IESUBSTTRIBUT,
                            E.CODIGO UFCODIGO,
              C.CONTRIBUINTE
                       from PCCLIENT C, PCFILIAL FL, PCESTADO E
                      where C.CODCLI = DECODE(NVL(:new.CODFORNECNF, 0),
                                              0,
                                              :new.CODFORNEC,
                                              :new.CODFORNECNF)
                        and C.ESTENT = E.UF(+)
                        and FL.CODIGO(+) = VCODFILIAL)
       loop
         --------------------------------------------------------------------------------
         begin
           select sum(QTCONT * NVL(VLCREDPIS, 0)) VLPIS,
                  sum(QTCONT * NVL(VLCREDCOFINS, 0)) VLCOFINS
             into VVLPIS, VVLCOFINS
             from PCMOV
            where NUMTRANSENT = :new.NUMTRANSENT
              and DTCANCEL is null
              and QTCONT > 0;
         exception
           when others then
             begin
               VVLPIS    := 0;
               VVLCOFINS := 0;
             end;
         end;
         --------------------------------------------------------------------------------
         :new.FORNECEDOR      := NVL(:new.FORNECEDOR, case when DADOS.DEVCONSUM = 'S' then DADOS.CONSUMIDOR else DADOS.CLIENTE end);
         :new.CGC             := NVL(:new.CGC, case when DADOS.DEVCONSUM = 'S' then DADOS.CGCCONSUM else DADOS.CGCCLIENTE end);
         :new.IE              := NVL(:new.IE, case when DADOS.DEVCONSUM = 'S' then DADOS.IECONSUM else DADOS.IECLIENTE end);
         :new.ENDERECO        := NVL(:new.ENDERECO,
                                     GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.DEVCONSUM,
                                                      DADOS.ENDERCONSUM,
                                                      DADOS.ENDERCLIENTE,
                                                      DADOS.ENDERFILIAL));
         :new.BAIRRO          := NVL(:new.BAIRRO,
                                     GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.DEVCONSUM,
                                                      DADOS.BAIRROCONSUM,
                                                      DADOS.BAIRROCLIENTE,
                                                      DADOS.BAIRROFILIAL));
         :new.MUNICIPIO       := NVL(:new.MUNICIPIO,
                                     GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.DEVCONSUM,
                                                      DADOS.CIDADECONSUM,
                                                      DADOS.CIDADECLIENTE,
                                                      DADOS.CIDADEFILIAL));
         :new.CEP             := NVL(:new.CEP,
                                     GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.DEVCONSUM,
                                                      DADOS.CEPCONSUM,
                                                      DADOS.CEPCLIENTE,
                                                      DADOS.CEPFILIAL));
         :new.UF              := NVL(:new.UF,
                                     GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.DEVCONSUM,
                                                      DADOS.UFCONSUM,
                                                      DADOS.UFCLIENTE,
                                                      DADOS.UFFILIAL));
         :new.TIPOFJ          := NVL(:new.TIPOFJ, case when DADOS.CODCLI_123 = 'S' and DADOS.DEVCONSUM = 'S' then DADOS.TIPOFJCONSUM else DADOS.TIPOFJCLIENTE end);
         :new.CODMUNICIPIO    := NVL(:new.CODMUNICIPIO, case when DADOS.CODCLI_123 = 'S' and DADOS.DEVCONSUM = 'S' then DADOS.CODCIDADECONSUM else DADOS.CODCIDADECLIENTE end);
         :new.CONSUMIDORFINAL := NVL(:new.CONSUMIDORFINAL,
                                     DADOS.CONSUMIDORFINAL);
         :NEW.CONTRIBUINTE    := NVL(:new.CONTRIBUINTE, DADOS.CONTRIBUINTE);               
         :new.EMAILDEST       := NVL(:new.EMAILDEST,
                                     GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.DEVCONSUM,
                                                      DADOS.EMAILCONSUM,
                                                      DADOS.EMAILCLI,
                                                      DADOS.EMAILFILIAL));
         :new.TELEFONE        := NVL(:new.TELEFONE,
                                     GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.DEVCONSUM,
                                                      DADOS.TELEFONECONSUM,
                                                      DADOS.TELEFONECLI,
                                                      DADOS.TELEFONEFILIAL));
         :new.NUMEROEND       := NVL(:new.NUMEROEND,
                                     GET_VALORCLIENTE(DADOS.CODCLI,
                                                      'N',
                                                      DADOS.DEVCONSUM,
                                                      '',
                                                      DADOS.NUMEROCLI,
                                                      DADOS.NUMEROFILIAL));
         :new.AGREGASTVLMERC  := PARAMFILIAL.OBTERCOMOVARCHAR2('AGREGASTVLMERC',
                                                               VCODFILIAL);
         --------------------------------------------------------------------------------
         -- ATRIBUINDO CODIBGE
         begin
           if DADOS.CODCLI_123 = 'S' and DADOS.DEVCONSUM = 'N'
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
         --------------------------------------------------------------------------------
         :new.ATACADISTA := NVL(:new.ATACADISTA, DADOS.ATACADISTA);

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
         :new.CODCONTFOR            := NVL(:new.CODCONTFOR, VCODCONTFOR);
         :new.CODCONTFRE            := NVL(:new.CODCONTFRE, VCODCONTFRE);
         :new.AGREGARSTPRODSINTEGRA := NVL(:new.AGREGARSTPRODSINTEGRA,
                                           VAGREGARSTPRODSINTEGRA);
         :new.TIPOALIQOUTRASDESP    := NVL(:new.TIPOALIQOUTRASDESP,
                                           VTIPOALIQOUTRASDESP);
         :new.IESUBSTTRIBUT         := NVL(:new.IESUBSTTRIBUT,
                                           DADOS.IESUBSTTRIBUT);
         :new.UFCODIGO              := NVL(:new.UFCODIGO, DADOS.UFCODIGO);
         :new.VLCREDPIS             := VVLPIS;
         :new.VLCREDCOFINS          := VVLCOFINS;
         :new.GERARBCRNFE           := V_GERARBCRNFE;
         begin
           if (NVL(:new.ESPECIE, '') = 'CO' OR NVL(:new.ESPECIE, '') = 'CE') then
             :new.AMBIENTENFE := PARAMFILIAL.OBTERCOMOVARCHAR2('AMBIENTECTE', VCODFILIAL);
           else 
             :new.AMBIENTENFE := PARAMFILIAL.OBTERCOMOVARCHAR2('AMBIENTENFE', VCODFILIAL);
           end if;
         exception
           when others then
             :new.AMBIENTENFE := null;
         end;

         :new.HISTORICO := 'S';
       end loop;
      end if;
      -- INFORMAÇÕES DE TRIBUTAÇÃO DE FRETE E DESP.ACESSORIA
      -------------------------------------------------------------------------------------------------------
      --  ATUALIZAR_TRIBUTACOES;
      -------------------------------------------------------------------------------------------------------
      :new.CODFISCALFRETE      := NVL(:new.CODFISCALFRETE, VCFOPFRETE);
      :new.CODFISCALOUTRASDESP := NVL(:new.CODFISCALOUTRASDESP, VCFOPDESPESA);
      :new.PERCICMFRETE        := NVL(:new.PERCICMFRETE, VALIQICMSFRETE);
      :new.ALIQICMOUTRASDESP   := NVL(:new.ALIQICMOUTRASDESP, VALIQICMSDESPESA);
      :new.SITUACAONFE         := NVL(:new.SITUACAONFE, 0);
      
      :new.TIPOIMPRESSAO := NVL(:new.TIPOIMPRESSAO, VTIPODANFE);
      
  END IF;

  -------------------------------------------------------------------------------------
  -- GRAVANDO NA TABELA PCMOVCOMPLE
  -------------------------------------------------------------------------------------
  IF UPDATING THEN
  
      IF :new.TIPOIMPRESSAO IS NULL THEN
         begin
           select TIPODANFE
             into VTIPODANFE
             from PCFILIAL
            where CODIGO = NVL(:new.CODFILIALNF, :new.CODFILIAL);
         exception
           when others then
             null;
         end;

         :new.TIPOIMPRESSAO := NVL(:new.TIPOIMPRESSAO, VTIPODANFE);
     END IF;  
  
     IF (((:NEW.SITUACAONFE > 0) AND (:NEW.SITUACAONFE <> :OLD.SITUACAONFE)) OR
         (NVL(:OLD.GERANFDEVCLI, 'N') = 'N' AND NVL(:OLD.GERANFVENDA, 'N') = 'N')) THEN
       FOR CR_PCMOV IN (SELECT PCMOV.NUMTRANSITEM,
                               PCMOV.NUMTRANSENT,
                               PCMOV.CODPROD,
                               PCMOV.NUMSEQ,
                               PCMOV.NUMNOTA,
                               PCMOVCOMPLE.ORIGMERCTRIB ORIGMERCTRIB_MOV,
                               NVL(PCPRODFILIAL.ORIGMERCTRIB, DECODE(PCMOV.IMPORTADO, 'S', '2', DECODE(PCMOV.IMPORTADO, 'D', '1', '0'))) ORIGMERCTRIB
                       FROM PCMOV,
                            PCMOVCOMPLE,
                            PCPRODFILIAL
                       WHERE PCMOV.NUMTRANSENT = :OLD.NUMTRANSENT
                          AND PCMOV.NUMNOTA = :OLD.NUMNOTA
                          AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                          AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCPRODFILIAL.CODFILIAL(+)
                          AND PCMOV.CODPROD = PCPRODFILIAL.CODPROD(+)
       ) LOOP
          IF (CR_PCMOV.ORIGMERCTRIB_MOV IS NULL) THEN
            IF (NVL(CR_PCMOV.NUMTRANSITEM, 0) > 0) THEN
               UPDATE PCMOVCOMPLE SET
                      PCMOVCOMPLE.ORIGMERCTRIB = CR_PCMOV.ORIGMERCTRIB
               WHERE PCMOVCOMPLE.NUMTRANSITEM = CR_PCMOV.NUMTRANSITEM
                 AND PCMOVCOMPLE.ORIGMERCTRIB IS NULL;
            ELSE
              SELECT DFSEQ_PCMOVCOMPLE.NEXTVAL
              INTO VNUMTRANSITEM
              FROM DUAL;

              IF VNUMTRANSITEM > 0 THEN
                 UPDATE PCMOV SET NUMTRANSITEM = VNUMTRANSITEM
                 WHERE NUMTRANSENT = CR_PCMOV.NUMTRANSENT
                    AND NUMNOTA = CR_PCMOV.NUMNOTA
                    AND CODPROD = CR_PCMOV.CODPROD;
                
                 INSERT INTO PCMOVCOMPLE (ORIGMERCTRIB, NUMTRANSITEM)
                                  VALUES (CR_PCMOV.ORIGMERCTRIB, VNUMTRANSITEM);
 
              END IF;
            END IF;
          END IF;
       END LOOP;
     END IF;
  END IF;

exception
  when VERRO_TRIBUTACAO then
    begin
      GERAR_LOG(VMENSAGEM_ERRO);
    end;
  when NO_DATA_FOUND then
    begin
      GERAR_LOG('FORNECEDOR/CLIENTE INEXISTENTE: ' ||
                TO_CHAR(:new.CODFORNEC));
    end;
  when others then
    begin
      GERAR_LOG(sqlerrm);
    end;

end;
