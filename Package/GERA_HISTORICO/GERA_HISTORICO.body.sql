CREATE OR REPLACE package body GERA_HISTORICO is
  /****************************************************************************/
  procedure VERIFICAR_SE_NECESSARIO_COMMIT is
  begin
    VCONT_ATUALIZACAO := NVL(VCONT_ATUALIZACAO, 0) + 1;
    if VCONT_ATUALIZACAO >= 1000
    then
      VCONT_ATUALIZACAO := 0;
      commit;
    end if;
  end;

  function SOMENTE_NUMERO(P_STRING in varchar) return number is
  begin
    return replace(trim(TRANSLATE(P_STRING,
                                  NVL(TRANSLATE(P_STRING, '1234567890', ' '),'X'),
                                  ' ')),
                   ' ',
                   '');
  exception
    when others then
      return null;
  end;

  /****************************************************************************/
  function GET_VALORCLIENTE(PCODCLI        in NUMBER,
                            PCONSUMIDOR    in VARCHAR2,
                            PVENDACONSUM   in VARCHAR2,
                            PVALOR_CONSUM  in VARCHAR2,
                            PVALOR_CLIENTE in VARCHAR2,
                            PVALOR_FILIAL  in VARCHAR2) RETURN VARCHAR2 IS
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

  /****************************************************************************/
  procedure ATUALIZAR_TRIBUTACOES_ENTRADA(PCODFILIAL    varchar2,
                                          PUF           in varchar2,
                                          PTIPODESCARGA in varchar2) is
  begin
    ---------------------------------------------------------------------------------------------------
    -- FUNÇÕES PARA RESUPERAR INFORMAÇÕES SOBRE A TRIBUTAÇÃO DE FRETE E DESPESAS ACESSORRIAS - ENTRADAS
    ---------------------------------------------------------------------------------------------------
    if VTIPOALIQOUTRASDESP <> 'T'
    then
      VCFOPFRETE       := case when VUFFILIAL = PUF then VCODFISCALFRETEENT else VCODFISCALINTERFRETEENT end;
      VCFOPDESPESA     := case when VUFFILIAL = PUF then VCODFISCALDEVOUTRASDESP else VCODFISCALINTERDEVOUTRASDESP end;
      VALIQICMSFRETE   := case when VUFFILIAL = PUF then VPERCICMFRETEENT else VPERCICMINTERFRETEENT end;
      VALIQICMSDESPESA := case when VUFFILIAL = PUF then VALIQICMOUTRASDESP else VALIQICMINTEROUTRASDESP end;
    else
      VERRO := 'ENTRADA - TRIBUTAÇÃO POR ESTADO INEXISTENTE! FILIAL: ' ||
               PCODFILIAL || ' UF DESTINO: ' || PUF;
      ---------------------------------------------------------------------------------------------------
      select DECODE(PTIPODESCARGA,
                    '6',
                    NVL(CODFISCALFRETEDEVCLI, CODFISCALFRETEENT),
                    'T',
                    NVL(CODFISCALFRETEDEVCLI, CODFISCALFRETEENT),
                    '8',
                    NVL(CODFISCALFRETEDEVCLI, CODFISCALFRETEENT),
                    CODFISCALFRETEENT),
             CODFISCALOUTRASDESPENT,
             DECODE(PTIPODESCARGA,
                    '6',
                    NVL(ALIQICMFRETEDEVCLI, ALIQICMFRETEENT),
                    'T',
                    NVL(ALIQICMFRETEDEVCLI, ALIQICMFRETEENT),
                    '8',
                    NVL(ALIQICMFRETEDEVCLI, ALIQICMFRETEENT),
                    ALIQICMFRETEENT),
             ALIQICMOUTRASDESPENT
        into VCFOPFRETE, VCFOPDESPESA, VALIQICMSFRETE, VALIQICMSDESPESA
        from PCTRIBOUTROS
       where UFDESTINO = PUF
         and CODFILIALNF = PCODFILIAL;
    end if;
  end;

  /****************************************************************************/
  procedure ATUALIZAR_TRIBUTACOES_SAIDA(PCODFILIAL  in varchar2,
                                        PUF         in varchar2,
                                        PTIPOVENDA  in varchar2,
                                        PCONSUMIDOR in varchar2,
                                        PTIPOFJ     in varchar2) is
  begin
    ------------------------------------------------------------------------------------------------
    -- FUNÇÕES PARA RESUPERAR INFORMAÇÕES SOBRE A TRIBUTAÇÃO DE FRETE E DESPESAS ACESSORRIAS - SAIDA
    ------------------------------------------------------------------------------------------------
    if VTIPOALIQOUTRASDESP <> 'T'
    then
      VCFOPFRETE       := case when VUFFILIAL = PUF then VCODFISCALFRETE else VCODFISCALINTERFRETE end;
      VCFOPDESPESA     := case when VUFFILIAL = PUF then VCODFISCALOUTRASDESP else VCODFISCALINTEROUTRASDESP end;
      VALIQICMSFRETE   := case when VUFFILIAL = PUF then VPERCICMFRETE else VPERCICMINTERFRETE end;
      VALIQICMSDESPESA := case when VUFFILIAL = PUF then VALIQICMOUTRASDESP else VALIQICMINTEROUTRASDESP end;
    else
      VERRO := 'SAÍDA - TRIBUTAÇÃO POR ESTADO INEXISTENTE! FILIAL: ' ||
               PCODFILIAL || ' UF DESTINO: ' || PUF;
      ---------------------------------------------------------------------------------------------------
      select DECODE(PTIPOVENDA,
                    'DF',
                    NVL(CODFISCALFRETEDEVFORNEC, CODFISCALFRETE),
                    DECODE(NVL(PCONSUMIDOR, 'N') || PTIPOFJ,
                           'SF',
                           NVL(CODFISCALFRETEPF, CODFISCALFRETE),
                           CODFISCALFRETE)),
             DECODE(PTIPOVENDA,
                    'DF',
                    DECODE(NVL(PCONSUMIDOR, 'N') || PTIPOFJ,
                           'SF',
                           NVL(CODFISCALDEVOUTRASDESPPF,
                               CODFISCALDEVOUTRASDESP),
                           CODFISCALDEVOUTRASDESP),
                    DECODE(NVL(PCONSUMIDOR, 'N') || PTIPOFJ,
                           'SF',
                           CODFISCALOUTRASDESPPF,
                           CODFISCALOUTRASDESP)),
             DECODE(PTIPOVENDA,
                    'DF',
                    NVL(ALIQICMFRETEDEVFORNEC, PERCICMFRETE),
                    DECODE(NVL(PCONSUMIDOR, 'N') || PTIPOFJ,
                           'SF',

                           NVL(PERCICMFRETEPF, PERCICMFRETE),

                           PERCICMFRETE)),
             DECODE(NVL(PCONSUMIDOR, 'N') || PTIPOFJ,
                    'SF',
                    NVL(ALIQICMOUTRASDESPPF, ALIQICMOUTRASDESP),
                    ALIQICMOUTRASDESP)
        into VCFOPFRETE, VCFOPDESPESA, VALIQICMSFRETE, VALIQICMSDESPESA
        from PCTRIBOUTROS
       where UFDESTINO = PUF
         and CODFILIALNF = PCODFILIAL;
    end if;
  end;

  /****************************************************************************/
  procedure GERAR_CAB_ENTRADAS(PCODFILIAL   in varchar2,
                               PDATA1       in date,
                               PDATA2       in date,
                               PTRANSACAO   in number,
                               PCODFORNEC   in number,
                               PTIPOENTRADA in varchar2 /*T-TODAS, N-NORMAL, D-DEVOLUCAO*/) is
    VCODPAIS  number;
    VDESCPAIS PCPAIS.DESCRICAO%type;
  begin
    ----------------------------------------------------------------------------------
    -- GERAÇÃO DO HISTORICO DOS DADOS DE ENTRADAS
    ----------------------------------------------------------------------------------
    VERRO := 'Erro ao gerar histórico de entradas';
    for DADOS in (select N.rowid IDREGISTRO,
                         N.NUMTRANSENT TRANSACAO,
                         N.NUMNOTA,
                         N.TIPODESCARGA,
                         DECODE(N.TIPODESCARGA,
                                '6',
                                'S',
                                'T',
                                'S',
                                '8',
                                'S',
                                'C',
                                'S',
                                'N') DEVOLUCAO,
                         F.FORNECEDOR,
                         F.CGC CGCFORNEC,
                         F.IE IEFORNEC,
                         F.ENDER,
                         F.BAIRRO,
                         F.CIDADE,
                         F.CODCIDADE,
                         (select max(CODIBGE)
                          from PCCIDADE
                          where CODCIDADE = F.CODCIDADE) CODIBGE,
                         F.CEP,
                         F.ESTADO UFFORNEC,
                         'J' TIPOFJFORNEC,
                         F.TIPOFRETECIFFOB,
                         F.REVENDA,
                         F.INDUSTRIALOCAL,
                         F.PERCPISRED,
                         F.TIPOFORNEC,
                         F.EMAIL EMAILFOR,
                         F.TELREP TELEFONEFOR,
                         F.NUMEROEND NUMEROFOR,
                         C.CLIENTE,
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
                         C.TELENT TELEFONECLI,
                         C.EMAIL EMAILCLI,
                         C.NUMEROENT NUMEROCLI,
                         (select max(ATACADISTA)
                          from PCATIVI
                          where CODATIV = C.CODATV1) ATACADISTA,
                         case
                           when (N.TIPODESCARGA in ('6', 'T', '8')) and
                                (DC.NUMTRANSENT > 0) and
                                (DECODE(NVL(N.CODFORNECNF, 0),
                                        0,
                                        N.CODFORNEC,
                                        N.CODFORNECNF) in (1, 2, 3)) then
                            'S'
                           else
                            'N'
                         end DEVCONSUMIDOR,
                         case
                           when DECODE(NVL(N.CODFORNECNF, 0),
                                       0,
                                       N.CODFORNEC,
                                       N.CODFORNECNF) in (1, 2, 3) then
                            'S'
                           else
                            'N'
                         end CODCLI_123,
                         DC.CLIENTE CONSUMIDOR,
                         DC.CGC CGCCONSUM,
                         DC.IE IECONSUM,
                         DC.ENDERECO ENDERCONSUMIDOR,
                         DC.BAIRRO BAIRROCONSUMIDOR,
                         DC.CIDADE CIDADECONSUMIDOR,
                         DC.CODCIDADE CODCIDADECONSUMIDOR,
                         DC.CEP CEPCONSUMIDOR,
                         DC.EMAIL EMAILCONSUMIDOR,
                         DC.TELEFONE TELEFONECONSUMIDOR,
                         NVL(DC.UF, VUFFILIAL) UFCONSUM,
                         'F' TIPOFJCONSUM,
                         SOMENTE_NUMERO(C.PAISENT) CODPAIS_CLIENTE,
                         F.CODPAIS CODPAIS_FORNEC,
                         (select max(PCESTADO.CODPAIS)
                          from PCCIDADE, PCESTADO
                          where PCCIDADE.UF = PCESTADO.UF
                            and PCCIDADE.CODCIDADE =
                                DECODE(N.TIPODESCARGA,
                                       '6',
                                       C.CODCIDADE,
                                       'T',
                                       C.CODCIDADE,
                                       '8',
                                       C.CODCIDADE,
                                       'C',
                                       C.CODCIDADE,
                                       F.CODCIDADE)) CODPAIS,
                         (select max(PCPAIS.DESCRICAO)
                          from PCCIDADE, PCESTADO, PCPAIS
                          where PCCIDADE.UF = PCESTADO.UF
                            and PCPAIS.CODPAIS = PCESTADO.CODPAIS
                            and PCCIDADE.CODCIDADE =
                                DECODE(N.TIPODESCARGA,
                                       '6',
                                       C.CODCIDADE,
                                       'T',
                                       C.CODCIDADE,
                                       '8',
                                       C.CODCIDADE,
                                       'C',
                                       C.CODCIDADE,
                                       F.CODCIDADE)) DESCPAIS,
                         FL.CIDADE CIDADEFILIAL,
                         FL.BAIRRO BAIRROFILIAL,
                         FL.ENDERECO ENDERFILIAL,
                         FL.CODMUN CODIBGEFILIAL,
                         FL.CEP CEPFILIAL,
                         FL.CGC CGCFILIAL,
                         FL.IE IEFILIAL,
                         FL.UF UFFILIAL,
                         FL.CODFORNEC CODFORFILIAL,
                         SOMENTE_NUMERO(F.CODCONTAB) AS CODCONTAB,
                         F.SUFRAMA,
                         FL.EMAIL EMAILFILIAL,
                         FL.TELEFONE TELFILIAL,
                         TO_CHAR(FL.NUMERO) NUMFILIAL,
                         (select max(ST.IESUBSTTRIBUT)
                          from PCINSCRICAOST ST
                          where ST.CODFILIAL = FL.CODIGO
                            and ST.UF = DECODE(N.TIPODESCARGA,
                                               '6',
                                               C.ESTENT,
                                               'T',
                                               C.ESTENT,
                                               '8',
                                               C.ESTENT,
                                               'C',
                                               C.ESTENT,
                                               F.ESTADO)) IESUBSTTRIBUT,
                         (select max(CODIGO)
                          from PCESTADO
                          where UF = DECODE(N.TIPODESCARGA,
                                            '6',
                                            C.ESTENT,
                                            'T',
                                            C.ESTENT,
                                            '8',
                                            C.ESTENT,
                                            'C',
                                            C.ESTENT,
                                            F.ESTADO)) UFCODIGO,
                         F.SIMPLESNACIONAL,
             CASE WHEN (N.TIPODESCARGA in ('6', 'T', '8', 'C')) THEN
                NVL(C.CONSUMIDORFINAL, 'N')
             ELSE
                  NVL(F.CONSUMIDORFINAL, 'N')
             END AS CONSUMIDORFINAL,
             CASE WHEN (N.TIPODESCARGA in ('6', 'T', '8', 'C')) THEN
                NVL(C.CONTRIBUINTE, 'N')
             ELSE
                  NVL(F.CONTRIBUINTEICMS, 'N')
             END AS CONTRIBUINTE
                    from PCNFENT     N,
                         PCFORNEC    F,
                         PCCLIENT    C,
                         PCDEVCONSUM DC,
                         PCFILIAL    FL
                   where N.DTENT between PDATA1 and PDATA2
                     and NVL(N.CODFILIALNF, N.CODFILIAL) = PCODFILIAL
                     and (NVL(PCODFORNEC, 0) = 0 or N.CODFORNEC = PCODFORNEC)
                     and (NVL(PTRANSACAO, 0) = 0 or N.NUMTRANSENT = PTRANSACAO)
                     and F.CODFORNEC(+) = DECODE(NVL(N.CODFORNECNF, 0),
                                0,
                                N.CODFORNEC,
                                N.CODFORNECNF)
                     and (NVL(PCODFORNEC, 0) = 0 or N.CODFORNEC = PCODFORNEC)
                     and C.CODCLI(+) = DECODE(NVL(N.CODFORNECNF, 0),
                                              0,
                                              N.CODFORNEC,
                                              N.CODFORNECNF)
                     and (NVL(PTIPOENTRADA, 'T') = 'T' or
                         (PTIPOENTRADA = 'N' and
                         N.TIPODESCARGA not in ('6', 'T', '8', 'C')) or
                         (PTIPOENTRADA = 'D' and
                         N.TIPODESCARGA in ('6', 'T', '8', 'C')))
                     and N.NUMTRANSENT = DC.NUMTRANSENT(+)
                     and FL.CODIGO(+) = NVL(N.CODFILIALNF, N.CODFILIAL)
                     and (NVL(VREPROCESSAR, 'N') = 'S' or
                         NVL(N.HISTORICO, 'N') = 'N'))
    loop
      VNUMNOTA := DADOS.NUMNOTA;
      --------------------------------------------------------------------------------
/*      -- ATUALIZAR TRIBUTAÇÕES
      ATUALIZAR_TRIBUTACOES_ENTRADA(PCODFILIAL,
                                    case when DADOS.DEVCONSUMIDOR = 'S' then
                                    DADOS.UFCONSUM when
                                    DADOS.DEVOLUCAO = 'S' then
                                    DADOS.UFCLIENTE else DADOS.UFFORNEC end,
                                    DADOS.TIPODESCARGA);*/
      --- TRATAR DADOS PAIS ----------------------------------------------------------
      if DADOS.DEVOLUCAO = 'S'
      then
      VERRO := 'Erro ao obter código do país do cliente.';
        begin
          VCODPAIS := NVL(NVL(TO_NUMBER(DADOS.CODPAIS_CLIENTE), DADOS.CODPAIS),1058);

          select DESCRICAO
            into VDESCPAIS
            from PCPAIS
           where CODPAIS = VCODPAIS;
        exception
          when others then
            begin
              VCODPAIS  := DADOS.CODPAIS;
              VDESCPAIS := DADOS.DESCPAIS;
            exception
              when others then
                null;
            end;
        end;
      else
      VERRO := 'Erro ao obter código do país do fornecedor.';
        begin
          VCODPAIS := NVL(DADOS.CODPAIS_FORNEC, DADOS.CODPAIS);

          select DESCRICAO
            into VDESCPAIS
            from PCPAIS
           where CODPAIS = VCODPAIS;
        exception
          when others then
            VCODPAIS  := DADOS.CODPAIS;
            VDESCPAIS := DADOS.DESCPAIS;
        end;

      end if;
      --- RECALCULANDO CABEÇALHO -----------------------------------------------------
    VERRO := 'Erro ao gravar histórico de entradas';
      update PCNFENT
         set FORNECEDOR            = DECODE(DADOS.DEVCONSUMIDOR ||
                                            DADOS.CODCLI_123,
                                            'SS',
                                            DADOS.CONSUMIDOR,
                                            DECODE(DADOS.DEVOLUCAO,
                                                   'S',
                                                   DADOS.CLIENTE,
                                                   DADOS.FORNECEDOR)),
             CGC                   = DECODE(DADOS.DEVCONSUMIDOR ||
                                            DADOS.CODCLI_123,
                                            'SS',
                                            DADOS.CGCCONSUM,
                                            DECODE(DADOS.DEVOLUCAO,
                                                   'S',
                                                   DADOS.CGCCLIENTE,
                                                   DADOS.CGCFORNEC)),
             IE                    = DECODE(DADOS.DEVCONSUMIDOR ||
                                            DADOS.CODCLI_123,
                                            'SS',
                                            DADOS.IECONSUM,
                                            DECODE(DADOS.DEVOLUCAO,
                                                   'S',
                                                   DADOS.IECLIENTE,
                                                   DADOS.IEFORNEC)),
             ENDERECO              = DECODE(DADOS.DEVOLUCAO,
                                            'S',
                                            GET_VALORCLIENTE(DADOS.CODCLI,
                                                             DADOS.CLIENTE_CONSUMIDOR,
                                                             DADOS.DEVCONSUMIDOR,
                                                             DADOS.ENDERCONSUMIDOR,
                                                             DADOS.ENDERCLIENTE,
                                                             DADOS.ENDERFILIAL),
                                            DADOS.ENDER),
             BAIRRO                = DECODE(DADOS.DEVOLUCAO,
                                            'S',
                                            GET_VALORCLIENTE(DADOS.CODCLI,
                                                             DADOS.CLIENTE_CONSUMIDOR,
                                                             DADOS.DEVCONSUMIDOR,
                                                             DADOS.BAIRROCONSUMIDOR,
                                                             DADOS.BAIRROCLIENTE,
                                                             DADOS.BAIRROFILIAL),
                                            DADOS.BAIRRO),

             MUNICIPIO             = DECODE(DADOS.DEVOLUCAO,
                                            'S',
                                            GET_VALORCLIENTE(DADOS.CODCLI,
                                                             DADOS.CLIENTE_CONSUMIDOR,
                                                             DADOS.DEVCONSUMIDOR,
                                                             DADOS.CIDADECONSUMIDOR,
                                                             DADOS.CIDADECLIENTE,
                                                             DADOS.CIDADEFILIAL),
                                            DADOS.CIDADE),
             CODMUNICIPIO          = DECODE(DADOS.DEVOLUCAO,
                                            'S',
                                            GET_VALORCLIENTE(DADOS.CODCLI,
                                                             DADOS.CLIENTE_CONSUMIDOR,
                                                             DADOS.DEVCONSUMIDOR,
                                                             DADOS.CODCIDADECONSUMIDOR,
                                                             DADOS.CODCIDADECLIENTE,
                                                             (select max(CODCIDADE)
                                                              from PCCIDADE
                                                              where CODIBGE = DADOS.CODIBGEFILIAL)),
                                            DADOS.CODCIDADE),
                                            
                                            
             CODIBGE               = DECODE(DADOS.DEVOLUCAO,
                                            'S',
                                            GET_VALORCLIENTE(DADOS.CODCLI,
                                                             DADOS.CLIENTE_CONSUMIDOR,
                                                             DADOS.DEVCONSUMIDOR,
                                                             (select max(CODIBGE)
                                                              from PCCIDADE
                                                              where CODCIDADE = DADOS.CODCIDADECONSUMIDOR),
                                                             (select max(CODIBGE)
                                                              from PCCIDADE
                                                              where CODCIDADE = DADOS.CODCIDADECLIENTE),
                                                             DADOS.CODIBGEFILIAL),
                                            DADOS.CODIBGE),
                                            
                                            
             CEP                   = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DECODE(DADOS.DEVOLUCAO,
                                                                                                      'S',
                                                                                                      GET_VALORCLIENTE(DADOS.CODCLI,
                                                                                                                       DADOS.CLIENTE_CONSUMIDOR,
                                                                                                                       DADOS.DEVCONSUMIDOR,
                                                                                                                       DADOS.CEPCONSUMIDOR,
                                                                                                                       DADOS.CEPCLIENTE,
                                                                                                                       DADOS.CEPFILIAL),
                                                                                                      DADOS.CEP),
                                     '.',''),'-',''),'/',''),',',''),'(',''),')',''),' ',''),CHR(10),''),
             UF                    = DECODE(DADOS.DEVOLUCAO,
                                            'S',
                                            GET_VALORCLIENTE(DADOS.CODCLI,
                                                             DADOS.CLIENTE_CONSUMIDOR,
                                                             DADOS.DEVCONSUMIDOR,
                                                             DADOS.UFCONSUM,
                                                             DADOS.UFCLIENTE,
                                                             DADOS.UFFILIAL),
                                            DADOS.UFFORNEC),
             TIPOFJ                = DECODE(DADOS.DEVCONSUMIDOR,
                                            'S',
                                            DADOS.TIPOFJCONSUM,
                                            DECODE(DADOS.DEVOLUCAO,
                                                   'S',
                                                   DADOS.TIPOFJCLIENTE,
                                                   DADOS.TIPOFJFORNEC)),
             CONTRIBUINTE          = DADOS.CONTRIBUINTE,
             CONSUMIDORFINAL       = DADOS.CONSUMIDORFINAL,
             ATACADISTA            = DADOS.ATACADISTA,
             TIPOFORNEC            = DADOS.TIPOFORNEC,
             PERCPISRED            = DADOS.PERCPISRED,
             CODPAIS               = VCODPAIS,
             DESCPAIS              = VDESCPAIS,
             CGCFILIAL             = DADOS.CGCFILIAL,
             IEFILIAL              = DADOS.IEFILIAL,
             UFFILIAL              = DADOS.UFFILIAL,
             CODFORFILIAL          = DADOS.CODFORFILIAL,
             CODCONTABFORNEC       = DADOS.CODCONTAB,
             AGREGARSTPRODSINTEGRA = VAGREGARSTPRODSINTEGRA,
             TIPOALIQOUTRASDESP    = VTIPOALIQOUTRASDESP,
             CODCONTFOR            = VCODCONTFOR,
             CODCONTFRE            = VCODCONTFRE,
             TIPOFRETECIFFOB       = NVL(TIPOFRETECIFFOB, DADOS.TIPOFRETECIFFOB),
             REVENDA               = DADOS.REVENDA,
             INDUSTRIALOCAL        = DADOS.INDUSTRIALOCAL,
             IESUBSTTRIBUT         = DADOS.IESUBSTTRIBUT,
             UFCODIGO              = DADOS.UFCODIGO,
             CODFISCALFRETE        = VCFOPFRETE,
             CODFISCALOUTRASDESP   = VCFOPDESPESA,
             PERCICMFRETE          = VALIQICMSFRETE,
             ALIQICMOUTRASDESP     = VALIQICMSDESPESA,
             HISTORICO             = 'S',
             EMAILDEST             = DECODE(DADOS.DEVOLUCAO,
                                            'S',
                                            GET_VALORCLIENTE(DADOS.CODCLI,
                                                             DADOS.CLIENTE_CONSUMIDOR,
                                                             DADOS.DEVCONSUMIDOR,
                                                             DADOS.EMAILCONSUMIDOR,
                                                             DADOS.EMAILCLI,
                                                             DADOS.EMAILFILIAL),
                                            DADOS.EMAILFOR),
             TELEFONE              = DECODE(DADOS.DEVOLUCAO,
                                            'S',
                                            GET_VALORCLIENTE(DADOS.CODCLI,
                                                             DADOS.CLIENTE_CONSUMIDOR,
                                                             DADOS.DEVCONSUMIDOR,
                                                             DADOS.TELEFONECONSUMIDOR,
                                                             DADOS.TELEFONECLI,
                                                             DADOS.TELFILIAL),
                                            DADOS.TELEFONEFOR),
             NUMEROEND             = DECODE(DADOS.DEVOLUCAO,
                                            'S',
                                            GET_VALORCLIENTE(DADOS.CODCLI,
                                                             'N',
                                                             DADOS.DEVCONSUMIDOR,
                                                             '',
                                                             DADOS.NUMEROCLI,
                                                             DADOS.NUMFILIAL),
                                            DADOS.NUMEROFOR),
              GERARBCRNFE = v_GERARBCRNFE,
             AGREGASTVLMERC = NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('AGREGASTVLMERC', PCODFILIAL), 'S'),
             SIMPLESNACIONAL = DADOS.SIMPLESNACIONAL,
             DEDUZIRICMSBASEPISCOFINS = NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('DEDUZIRICMSBASEPISCOFINS', PCODFILIAL), 'N')
       where rowid = DADOS.IDREGISTRO;
      -----------------------------------------------------------
      VERIFICAR_SE_NECESSARIO_COMMIT();
    end loop;
  end;

  /****************************************************************************/
  procedure GERAR_CAB_SAIDAS(PCODFILIAL in varchar2,
                             PDATA1     in date,
                             PDATA2     in date,
                             PTRANSACAO in number,
                             PCODCLI    in number) is
    VCODPAIS  number;
    pAGREGASTVLMERC varchar(1); 
    pEXCLUIRICMSBASEPISCOFINS varchar(1); 
    VDESCPAIS PCPAIS.DESCRICAO%type;

  begin
    ----------------------------------------------------------------------------------
    -- GERAÇÃO DO HISTORICO DOS DADOS DE SAIDAS
    ----------------------------------------------------------------------------------
    select NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('AGREGASTVLMERC', PCODFILIAL), 'S')
      into pAGREGASTVLMERC
      from DUAL;
          
    select NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('EXCLUIRICMSBASEPISCOFINS', PCODFILIAL), 'N')
      into pEXCLUIRICMSBASEPISCOFINS
      from DUAL;

    VERRO := 'Erro ao gerar histórico de saídas';
    for DADOS in (select
                   N.rowid IDREGISTRO,
                   N.NUMTRANSVENDA TRANSACAO,
                   N.TIPOVENDA,
                   N.NUMNOTA,
                   C.CLIENTE,
                   C.CODCLI,
                   case
                     when trim(UPPER(C.CLIENTE)) like '%CONSUMIDOR%' then
                      'S'
                     else
                      'N'
                   end CLIENTE_CONSUMIDOR,
                   N.CONDVENDA,
                   C.CGCENT CGCCLIENTE,
                   C.IEENT IECLIENTE,
                   C.ENDERENT ENDERCLIENTE,
                   C.BAIRROENT BAIRROCLIENTE,
                   C.MUNICENT CIDADECLIENTE,
                   C.CODCIDADE CODCIDADEENT,
                   C.CEPENT CEPCLIENTE,
                   C.ESTENT UFCLIENTE,
                   C.TIPOFJ TIPOFJCLIENTE,
                   C.ORGAOPUB,
                   C.ORGAOPUBFEDERAL,
                   C.ORGAOPUBMUNICIPAL,
                   AT.ATACADISTA,
                   C.TIPOEMPRESA,
                   C.CONTRIBUINTE,
                   C.CODCIDADE CODCIDADECLIENTE,
                   C.EMAIL EMAILCLI,
                   C.TELENT TELEFONECLI,
                   C.NUMEROENT NUMEROCLI,
                   (select max(CODIBGE)
                      from PCCIDADE
                     where CODCIDADE = C.CODCIDADE) CODIBGE,
                   C.CONSUMIDORFINAL,
                   F.FORNECEDOR TRANSPORTADORA,
                   F.CGC CGCFRETE,
                   F.IE IEFRETE,
                   F.ESTADO UFFRETE,
                   C.CODATV1,
                   case
                     when (NVL(VC.NUMPED, 0) > 0) and
                          (DECODE(NVL(N.CODCLINF, 0), 0, N.CODCLI, N.CODCLINF) in
                          (1, 2, 3)) then
                      'S'
                     else
                      'N'
                   end VENDACONSUMIDOR,
                   case
                     when (DECODE(NVL(N.CODCLINF, 0), 0, N.CODCLI, N.CODCLINF) in
                          (1, 2, 3)) then
                      'S'
                     else
                      'N'
                   end CODCLI_123,
                   VC.CLIENTE CONSUMIDOR,
                   VC.CGCENT CGCCONSUM,
                   VC.IEENT IECONSUM,
                   VC.ENDERENT ENDERCONSUM,
                   VC.BAIRROENT BAIRROCONSUM,
                   VC.MUNICENT CIDADECONSUM,
                   VC.CODCIDADE CODCIDADECONSUM,
                   VC.CEPENT CEPCONSUM,
                   VC.EMAIL EMAILCONSUM,
                   VC.TELENT TELEFONECONSUM,
                   VC.NUMEROENT NUMEROCONSUM,
                   NVL(VC.ESTENT, VUFFILIAL) UFCONSUM,
                   'F' TIPOFJCONSUM,
                   SOMENTE_NUMERO(C.PAISENT) CODPAIS_CLIENTE,
                   P.CODPAIS,
                   P.DESCRICAO DESCPAIS,
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
                   FL.TELEFONE TELFILIAL,
                   TO_CHAR(FL.NUMERO) NUMEROFILIAL,
                   (select max(ST.IESUBSTTRIBUT)
                      from PCINSCRICAOST ST
                     where ST.CODFILIAL = FL.CODIGO
                       and ST.UF = C.ESTENT) IESUBSTTRIBUT,
                   V.PLACA,
                   E.CODIGO UFCODIGO,
                   PR.VLPAUTAFRETE,
                   C.CLIENTEFONTEST,
                   C.SULFRAMA,
                   CB.COBRANCA,
                   C.SIMPLESNACIONAL,
                   (select nvl(sum((S.QTCONT * nvl(s.vldesconto,0))),0)
                       from pcmov s
                     where s.numtransvenda = N.NUMTRANSVENDA
                         and s.dtcancel is null
                         AND NVL(S.CODFILIALNF,S.CODFILIAL) = NVL(N.CODFILIALNF,N.CODFILIAL)) VLDESCONTO,
                    'N' prefaturamento,
          N.NUMPED
                    from PCNFSAID      N,
                         PCCLIENT      C,
                         PCCARREG      CR,
                         PCVEICUL      V,
                         PCVENDACONSUM VC,
                         PCFILIAL      FL,
                         PCPAIS        P,
                         PCESTADO      E,
                         PCFORNEC      F,
                         PCPRACA       PR,
                         PCCOB         CB,
                         PCATIVI       AT,
                         PCPEDC PD,
                         PCCLIENTENDENT EN
                   where N.DTSAIDA between PDATA1 and PDATA2
                     and NVL(N.CODFILIALNF, N.CODFILIAL) = PCODFILIAL
                     and (NVL(PCODCLI, 0) = 0 or N.CODCLI = PCODCLI)
                     and (NVL(PTRANSACAO, 0) = 0 or N.NUMTRANSVENDA = PTRANSACAO)
                     and N.CODPRACA = PR.CODPRACA(+)
                     and C.CODATV1 = AT.CODATIV(+)
                     and C.CODCLI = DECODE(NVL(N.CODCLINF, 0), 0, N.CODCLI, N.CODCLINF)
                     and N.NUMCAR = CR.NUMCAR(+)
                     and CR.CODVEICULO = V.CODVEICULO(+)
                     and N.CODFORNECFRETE = F.CODFORNEC(+)
                     and N.NUMPED = VC.NUMPED(+)
                     and N.CODCOB = CB.CODCOB(+)
                     and E.CODPAIS = P.CODPAIS(+)
                     and FL.CODIGO(+) = NVL(N.CODFILIALNF, N.CODFILIAL)
                     and C.ESTENT = E.UF(+)
                     And N.Numped = PD.NUMPED(+)
                     AND PD.CODCLI = EN.CODCLI(+) AND PD.CODENDENTCLI = EN.CODENDENTCLI(+)
                     and (NVL(VREPROCESSAR, 'N') = 'S' or
                         NVL(N.HISTORICO, 'N') = 'N')
                   ------------------------------------------------------------------------------------------
                         union all
                   ------------------------------------------------------------------------------------------      
                 select
                   N.rowid IDREGISTRO,
                   N.NUMTRANSVENDA TRANSACAO,
                   N.TIPOVENDA,
                   N.NUMNOTA,
                   C.CLIENTE,
                   C.CODCLI,
                   case
                     when trim(UPPER(C.CLIENTE)) like '%CONSUMIDOR%' then
                      'S'
                     else
                      'N'
                   end CLIENTE_CONSUMIDOR,
                   N.CONDVENDA,
                   C.CGCENT CGCCLIENTE,
                   C.IEENT IECLIENTE,
                   C.ENDERENT ENDERCLIENTE,
                   C.BAIRROENT BAIRROCLIENTE,
                   C.MUNICENT CIDADECLIENTE,
                   C.CODCIDADE CODCIDADEENT,
                   C.CEPENT CEPCLIENTE,
                   C.ESTENT UFCLIENTE,
                   C.TIPOFJ TIPOFJCLIENTE,
                   C.ORGAOPUB,
                   C.ORGAOPUBFEDERAL,
                   C.ORGAOPUBMUNICIPAL,
                   AT.ATACADISTA,
                   C.TIPOEMPRESA,
                   C.CONTRIBUINTE,
                   C.CODCIDADE CODCIDADECLIENTE,
                   C.EMAIL EMAILCLI,
                   C.TELENT TELEFONECLI,
                   C.NUMEROENT NUMEROCLI,
                   (select max(CODIBGE)
                      from PCCIDADE
                     where CODCIDADE = C.CODCIDADE) CODIBGE,
                   C.CONSUMIDORFINAL,
                   F.FORNECEDOR TRANSPORTADORA,
                   F.CGC CGCFRETE,
                   F.IE IEFRETE,
                   F.ESTADO UFFRETE,
                   C.CODATV1,
                   case
                     when (NVL(VC.NUMPED, 0) > 0) and
                          (DECODE(NVL(N.CODCLINF, 0), 0, N.CODCLI, N.CODCLINF) in
                          (1, 2, 3)) then
                      'S'
                     else
                      'N'
                   end VENDACONSUMIDOR,
                   case
                     when (DECODE(NVL(N.CODCLINF, 0), 0, N.CODCLI, N.CODCLINF) in
                          (1, 2, 3)) then
                      'S'
                     else
                      'N'
                   end CODCLI_123,
                   VC.CLIENTE CONSUMIDOR,
                   VC.CGCENT CGCCONSUM,
                   VC.IEENT IECONSUM,
                   VC.ENDERENT ENDERCONSUM,
                   VC.BAIRROENT BAIRROCONSUM,
                   VC.MUNICENT CIDADECONSUM,
                   VC.CODCIDADE CODCIDADECONSUM,
                   VC.CEPENT CEPCONSUM,
                   VC.EMAIL EMAILCONSUM,
                   VC.TELENT TELEFONECONSUM,
                   VC.NUMEROENT NUMEROCONSUM,
                   NVL(VC.ESTENT, VUFFILIAL) UFCONSUM,
                   'F' TIPOFJCONSUM,
                   SOMENTE_NUMERO(C.PAISENT) CODPAIS_CLIENTE,
                   P.CODPAIS,
                   P.DESCRICAO DESCPAIS,
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
                   FL.TELEFONE TELFILIAL,
                   TO_CHAR(FL.NUMERO) NUMEROFILIAL,
                   (select max(ST.IESUBSTTRIBUT)
                      from PCINSCRICAOST ST
                     where ST.CODFILIAL = FL.CODIGO
                       and ST.UF = C.ESTENT) IESUBSTTRIBUT,
                   V.PLACA,
                   E.CODIGO UFCODIGO,
                   PR.VLPAUTAFRETE,
                   C.CLIENTEFONTEST,
                   C.SULFRAMA,
                   CB.COBRANCA,
                   C.SIMPLESNACIONAL,
                   (select nvl(sum((S.QTCONT * nvl(s.vldesconto,0))),0)
                       from pcmov s
                     where s.numtransvenda = N.NUMTRANSVENDA
                         and s.dtcancel is null
                         AND NVL(S.CODFILIALNF,S.CODFILIAL) = NVL(N.CODFILIALNF,N.CODFILIAL)) VLDESCONTO,
                    'S' prefaturamento,
          N.NUMPED
                    from PCNFSAIDprefat      N,
                         PCCLIENT      C,
                         PCCARREG      CR,
                         PCVEICUL      V,
                         PCVENDACONSUM VC,
                         PCFILIAL      FL,
                         PCPAIS        P,
                         PCESTADO      E,
                         PCFORNEC      F,
                         PCPRACA       PR,
                         PCCOB         CB,
                         PCATIVI       AT,
                         PCPEDC PD,
                         PCCLIENTENDENT EN
                   where N.DTSAIDA between PDATA1 and PDATA2
                     and NVL(N.CODFILIALNF, N.CODFILIAL) = PCODFILIAL
                     and (NVL(PCODCLI, 0) = 0 or N.CODCLI = PCODCLI)
                     and (NVL(PTRANSACAO, 0) = 0 or N.NUMTRANSVENDA = PTRANSACAO)
                     and N.CODPRACA = PR.CODPRACA(+)
                     and C.CODATV1 = AT.CODATIV(+)
                     and C.CODCLI = DECODE(NVL(N.CODCLINF, 0), 0, N.CODCLI, N.CODCLINF)
                     and N.NUMCAR = CR.NUMCAR(+)
                     and CR.CODVEICULO = V.CODVEICULO(+)
                     and N.CODFORNECFRETE = F.CODFORNEC(+)
                     and N.NUMPED = VC.NUMPED(+)
                     and N.CODCOB = CB.CODCOB(+)
                     and E.CODPAIS = P.CODPAIS(+)
                     and FL.CODIGO(+) = NVL(N.CODFILIALNF, N.CODFILIAL)
                     and C.ESTENT = E.UF(+)
                     And N.Numped = PD.NUMPED(+)---
                     AND PD.CODCLI = EN.CODCLI(+) AND PD.CODENDENTCLI = EN.CODENDENTCLI(+)
                     and (NVL(VREPROCESSAR, 'N') = 'S' or
                         NVL(N.HISTORICO, 'N') = 'N'))
    loop
      VNUMNOTA := DADOS.NUMNOTA;
      --------------------------------------------------------------------------------
/*      -- ATUALIZAR TRIBUTAÇÕES
      ATUALIZAR_TRIBUTACOES_SAIDA(PCODFILIAL,
                                  case when DADOS.VENDACONSUMIDOR = 'S' then
                                  DADOS.UFCONSUM else DADOS.UFCLIENTE end,
                                  DADOS.TIPOVENDA,
                                  DADOS.CONSUMIDORFINAL,
                                  DADOS.TIPOFJCLIENTE);*/
      --- TRATAR DADOS PAIS ----------------------------------------------------------
      begin
      VERRO := 'Erro ao obter código do país do cliente.';
        VCODPAIS := NVL(NVL(TO_NUMBER(DADOS.CODPAIS_CLIENTE), DADOS.CODPAIS),1058);

        select DESCRICAO
          into VDESCPAIS
          from PCPAIS
         where CODPAIS = VCODPAIS;
      exception
        when others then
          begin
            VCODPAIS  := DADOS.CODPAIS;
            VDESCPAIS := DADOS.DESCPAIS;
          exception
            when others then
              null;
          end;
      end;
      --- RECALCULANDO CABEÇALHO -----------------------------------------------------
      IF DADOS.PREFATURAMENTO = 'N' THEN

      begin
        select max(CODFISCAL) CODFISCALNF
          into VCODFISCALNF
          from PCMOV
         where NUMTRANSVENDA = DADOS.TRANSACAO
           and DTCANCEL is null
           and QTCONT > 0
           and STATUS IN ('A', 'AB')
           and (NVL(BRINDE, 'N') = 'N' or DADOS.CONDVENDA = 5);
      exception
        when others then
          begin
            begin
              select max(CODFISCAL)
                into VCODFISCALNF
                from PCNFBASE
               where NUMTRANSVENDA = DADOS.TRANSACAO;
            exception
              when others then
                null;
            end;
          end;
      end;
      --------------------------------------------------------------------------------
    VERRO := 'Erro ao gravar histórico de saídas';
      update PCNFSAID
         set CLIENTE               = DECODE(DADOS.VENDACONSUMIDOR,
                                            'S',
                                            DADOS.CONSUMIDOR,
                                            DADOS.CLIENTE),
             CGC                   = DECODE(DADOS.VENDACONSUMIDOR,
                                            'S',
                                            DADOS.CGCCONSUM,
                                            DADOS.CGCCLIENTE),
             IE                    = DECODE(DADOS.VENDACONSUMIDOR,
                                            'S',
                                            DADOS.IECONSUM,
                                            DADOS.IECLIENTE),

             ENDERECO              = GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.VENDACONSUMIDOR,
                                                      DADOS.ENDERCONSUM,
                                                      DADOS.ENDERCLIENTE,
                                                      DADOS.ENDERFILIAL),

             BAIRRO                = GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.VENDACONSUMIDOR,
                                                      DADOS.BAIRROCONSUM,
                                                      DADOS.BAIRROCLIENTE,
                                                      DADOS.BAIRROFILIAL),

             MUNICIPIO             = GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.VENDACONSUMIDOR,
                                                      DADOS.CIDADECONSUM,
                                                      DADOS.CIDADECLIENTE,
                                                      DADOS.CIDADEFILIAL),

             CODMUNICIPIO          = GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.VENDACONSUMIDOR,
                                                      NVL(DADOS.CODCIDADECONSUM, (select max(CODCIDADE)
                                                                                    from PCCIDADE
                                                                                   where CODIBGE = DADOS.CODIBGEFILIAL)),
                                                      DADOS.CODCIDADEENT,
                                                      (select max(CODCIDADE)
                                                       from PCCIDADE
                                                       where CODIBGE = DADOS.CODIBGEFILIAL)),

            CODIBGE               = GET_VALORCLIENTE(DADOS.CODCLI,
                                                     DADOS.CLIENTE_CONSUMIDOR,
                                                     DADOS.VENDACONSUMIDOR,
                                                     (select max(CODIBGE)
                                                      from PCCIDADE
                                                      where CODCIDADE = DADOS.CODCIDADECONSUM),
                                                      (select max(CODIBGE)
                                                       from PCCIDADE
                                                       where CODCIDADE = DADOS.CODCIDADECLIENTE),
                                                      DADOS.CODIBGEFILIAL),

             CEP                   = GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.VENDACONSUMIDOR,
                                                      DADOS.CEPCONSUM,
                                                      DADOS.CEPCLIENTE,
                                                      DADOS.CEPFILIAL),

             UF                    = GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.VENDACONSUMIDOR,
                                                      DADOS.UFCONSUM,
                                                      DADOS.UFCLIENTE,
                                                      DADOS.UFFILIAL),

             TIPOFJ                = DECODE(DADOS.VENDACONSUMIDOR,
                                            'S',
                                            DADOS.TIPOFJCONSUM,
                                            DADOS.TIPOFJCLIENTE),
             ORGAOPUB              = DECODE(DADOS.VENDACONSUMIDOR,
                                            'S',
                                            'N',
                                            DADOS.ORGAOPUB),
             ORGAOPUBFEDERAL        = DECODE(DADOS.VENDACONSUMIDOR,
                                            'S',
                                            'N',
                                            DADOS.ORGAOPUBFEDERAL),
             ORGAOPUBMUNICIPAL      = DECODE(DADOS.VENDACONSUMIDOR,
                                            'S',
                                            'N',
                                            DADOS.ORGAOPUBMUNICIPAL),
             ATACADISTA            = DADOS.ATACADISTA,
             TIPOEMPRESA           = DADOS.TIPOEMPRESA,
             CONTRIBUINTE          = DADOS.CONTRIBUINTE,
             CONSUMIDORFINAL       = DADOS.CONSUMIDORFINAL,
             TRANSPORTADORA        = DADOS.TRANSPORTADORA,
             CGCFRETE              = DADOS.CGCFRETE,
             IEFRETE               = DADOS.IEFRETE,
             UFFRETE               = DADOS.UFFRETE,
             CODATV1               = DADOS.CODATV1,
             CODPAIS               = VCODPAIS,
             DESCPAIS              = VDESCPAIS,
             CGCFILIAL             = DADOS.CGCFILIAL,
             IEFILIAL              = DADOS.IEFILIAL,
             UFFILIAL              = DADOS.UFFILIAL,
             CODCONTCLI            = VCODCONTCLI,
             AGREGARSTPRODSINTEGRA = VAGREGARSTPRODSINTEGRA,
             TIPOALIQOUTRASDESP    = VTIPOALIQOUTRASDESP,
             IESUBSTTRIBUT         = DADOS.IESUBSTTRIBUT,
             PLACAVEIC             = DADOS.PLACA,
             UFCODIGO              = DADOS.UFCODIGO,
             VLPAUTAFRETE          = DADOS.VLPAUTAFRETE,
             CLIENTEFONTEST        = DADOS.CLIENTEFONTEST,
             SULFRAMA              = DADOS.SULFRAMA,
             COBRANCA              = DADOS.COBRANCA,
             CODFISCALNF           = VCODFISCALNF,
             CODFISCALFRETE        = VCFOPFRETE,
             CODFISCALOUTRASDESP   = VCFOPDESPESA,
             PERCICMFRETE          = VALIQICMSFRETE,
             ALIQICMOUTRASDESP     = VALIQICMSDESPESA,
             HISTORICO             = 'S',
             EMAILDEST             = GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.VENDACONSUMIDOR,
                                                      DADOS.EMAILCONSUM,
                                                      DADOS.EMAILCLI,
                                                      DADOS.EMAILFILIAL),
             TELEFONE              = GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.VENDACONSUMIDOR,
                                                      DADOS.TELEFONECONSUM,
                                                      DADOS.TELEFONECLI,
                                                      DADOS.TELFILIAL),
             NUMENDERECO           = GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.VENDACONSUMIDOR,
                                                      DADOS.NUMEROCONSUM,
                                                      DADOS.NUMEROCLI,
                                                      DADOS.NUMEROFILIAL),
             AGREGASTVLMERC      = pAGREGASTVLMERC,
             SIMPLESNACIONAL     = DADOS.SIMPLESNACIONAL,
             VLDESCONTO          = DADOS.VLDESCONTO,
             GERARBCRNFE         = v_GERARBCRNFE,
             DEDUZIRICMSBASEPISCOFINS = pEXCLUIRICMSBASEPISCOFINS
       where rowid = DADOS.IDREGISTRO;

       ELSE
      begin
        select max(CODFISCAL) CODFISCALNF
          into VCODFISCALNF
          from PCMOVPREFAT
         where NUMTRANSVENDA = DADOS.TRANSACAO
           and DTCANCEL is null
           and QTCONT > 0
           and STATUS IN ('A', 'AB')
           and (NVL(BRINDE, 'N') = 'N' or DADOS.CONDVENDA = 5);
      exception
        when others then
          begin
            begin
              select max(CODFISCAL)
                into VCODFISCALNF
                from PCNFBASEPREFAT
               where NUMTRANSVENDA = DADOS.TRANSACAO;
            exception
              when others then
                null;
            end;
          end;
      end;

      --------------------------------------------------------------------------------
    VERRO := 'Erro ao gravar histórico de saídas';
      update PCNFSAIDPREFAT
         set CLIENTE               = DECODE(DADOS.VENDACONSUMIDOR,
                                            'S',
                                            DADOS.CONSUMIDOR,
                                            DADOS.CLIENTE),
             CGC                   = DECODE(DADOS.VENDACONSUMIDOR,
                                            'S',
                                            DADOS.CGCCONSUM,
                                            DADOS.CGCCLIENTE),
             IE                    = DECODE(DADOS.VENDACONSUMIDOR,
                                            'S',
                                            DADOS.IECONSUM,
                                            DADOS.IECLIENTE),
             IEENT                 = DECODE(DADOS.VENDACONSUMIDOR,
                                            'S',
                                            DADOS.IECONSUM,
                                            DADOS.IECLIENTE),

             --- Dados Endereco  Inicio

             ENDERECO              = GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.VENDACONSUMIDOR,
                                                      DADOS.ENDERCONSUM,
                                                      DADOS.ENDERCLIENTE,
                                                      DADOS.ENDERFILIAL),

             BAIRRO                = GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.VENDACONSUMIDOR,
                                                      DADOS.BAIRROCONSUM,
                                                      DADOS.BAIRROCLIENTE,
                                                      DADOS.BAIRROFILIAL),

             MUNICIPIO             = GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.VENDACONSUMIDOR,
                                                      DADOS.CIDADECONSUM,
                                                      DADOS.CIDADECLIENTE,
                                                      DADOS.CIDADEFILIAL),

             CODMUNICIPIO          = GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.VENDACONSUMIDOR,
                                                      NVL(DADOS.CODCIDADECONSUM, (select max(CODCIDADE)
                                                                                    from PCCIDADE
                                                                                   where CODIBGE = DADOS.CODIBGEFILIAL)),
                                                      DADOS.CODCIDADEENT,
                                                      (select max(CODCIDADE)
                                                       from PCCIDADE
                                                       where CODIBGE = DADOS.CODIBGEFILIAL)),

             CODIBGE               = GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.VENDACONSUMIDOR,
                                                      (select max(CODIBGE)
                                                       from PCCIDADE
                                                       where CODCIDADE = DADOS.CODCIDADECONSUM),
                                                      (select max(CODIBGE)
                                                       from PCCIDADE
                                                       where CODCIDADE = DADOS.CODCIDADECLIENTE),
                                                      DADOS.CODIBGEFILIAL),

             CEP                   = GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.VENDACONSUMIDOR,
                                                      DADOS.CEPCONSUM,
                                                      DADOS.CEPCLIENTE,
                                                      DADOS.CEPFILIAL),

             UF                    = GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.VENDACONSUMIDOR,
                                                      DADOS.UFCONSUM,
                                                      DADOS.UFCLIENTE,
                                                      DADOS.UFFILIAL),

             --- dados Endereco fim

             TIPOFJ                = DECODE(DADOS.VENDACONSUMIDOR,
                                            'S',
                                            DADOS.TIPOFJCONSUM,
                                            DADOS.TIPOFJCLIENTE),

             ORGAOPUB              = DECODE(DADOS.VENDACONSUMIDOR,
                                            'S',
                                            'N',
                                            DADOS.ORGAOPUB),
             ORGAOPUBFEDERAL        = DECODE(DADOS.VENDACONSUMIDOR,
                                            'S',
                                            'N',
                                            DADOS.ORGAOPUBFEDERAL),
             ORGAOPUBMUNICIPAL      = DECODE(DADOS.VENDACONSUMIDOR,
                                            'S',
                                            'N',
                                            DADOS.ORGAOPUBMUNICIPAL),
             ATACADISTA            = DADOS.ATACADISTA,
             TIPOEMPRESA           = DADOS.TIPOEMPRESA,
             CONTRIBUINTE          = DADOS.CONTRIBUINTE,
             CONSUMIDORFINAL       = DADOS.CONSUMIDORFINAL,
             TRANSPORTADORA        = DADOS.TRANSPORTADORA,
             CGCFRETE              = DADOS.CGCFRETE,
             IEFRETE               = DADOS.IEFRETE,
             UFFRETE               = DADOS.UFFRETE,
             CODATV1               = DADOS.CODATV1,
             CODPAIS               = VCODPAIS,
             DESCPAIS              = VDESCPAIS,
             CGCFILIAL             = DADOS.CGCFILIAL,
             IEFILIAL              = DADOS.IEFILIAL,
             UFFILIAL              = DADOS.UFFILIAL,
             CODCONTCLI            = VCODCONTCLI,
             AGREGARSTPRODSINTEGRA = VAGREGARSTPRODSINTEGRA,
             TIPOALIQOUTRASDESP    = VTIPOALIQOUTRASDESP,
             IESUBSTTRIBUT         = DADOS.IESUBSTTRIBUT,
             PLACAVEIC             = DADOS.PLACA,
             UFCODIGO              = DADOS.UFCODIGO,
             VLPAUTAFRETE          = DADOS.VLPAUTAFRETE,
             CLIENTEFONTEST        = DADOS.CLIENTEFONTEST,
             SULFRAMA              = DADOS.SULFRAMA,
             COBRANCA              = DADOS.COBRANCA,
             CODFISCALNF           = VCODFISCALNF,
             CODFISCALFRETE        = VCFOPFRETE,
             CODFISCALOUTRASDESP   = VCFOPDESPESA,
             PERCICMFRETE          = VALIQICMSFRETE,
             ALIQICMOUTRASDESP     = VALIQICMSDESPESA,
             HISTORICO             = 'S',
             EMAILDEST             = GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.VENDACONSUMIDOR,
                                                      DADOS.EMAILCONSUM,
                                                      DADOS.EMAILCLI,
                                                      DADOS.EMAILFILIAL),
             TELEFONE              = GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.VENDACONSUMIDOR,
                                                      DADOS.TELEFONECONSUM,
                                                      DADOS.TELEFONECLI,
                                                      DADOS.TELFILIAL),
             NUMENDERECO           = GET_VALORCLIENTE(DADOS.CODCLI,
                                                      DADOS.CLIENTE_CONSUMIDOR,
                                                      DADOS.VENDACONSUMIDOR,
                                                      DADOS.NUMEROCONSUM,
                                                      DADOS.NUMEROCLI,
                                                      DADOS.NUMEROFILIAL),
             AGREGASTVLMERC      = NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('AGREGASTVLMERC', PCODFILIAL), 'S'),
             SIMPLESNACIONAL     = DADOS.SIMPLESNACIONAL,
             VLDESCONTO          = DADOS.VLDESCONTO,
             GERARBCRNFE         = v_GERARBCRNFE
       where rowid = DADOS.IDREGISTRO;



       END IF;
      -----------------------------------------------------------
      VERIFICAR_SE_NECESSARIO_COMMIT();
    end loop;
  end;

  /****************************************************************************/
  function GRAVAR_DADOS_PCMOVCOMPLE(P_IDREGISTRO_PCMOV in varchar2,
                                    P_NUMTRANSITEM     in number,
                                    P_CODSITTRIBUIPI   in number,
                                    P_EXTIPI           in varchar2,
                                    P_SUBSTANCIA       in varchar2,
                                    P_QTLITRAGEM       in number,
                                    P_REGIMEESPECIAL IN VARCHAR2,
                                    P_ORIGMERCTRIB   IN VARCHAR2,
                                    P_CODCEST        IN VARCHAR2,
                                    P_PREFATURAMENTO IN VARCHAR2,
                                    P_CODMOTISENCAOANVISA IN VARCHAR2,
                                    P_PERMITECREDITOPRESUMIDO IN VARCHAR2,
                                    P_PERCMVAORIG_ENT IN NUMBER)
    return number is
    V_NUMTRANSITEM_TEMP number;
  begin
    V_NUMTRANSITEM_TEMP := P_NUMTRANSITEM;

    IF P_PREFATURAMENTO = 'S' THEN

    update PCMOVCOMPLEPREFAT
       set CODSITTRIBIPI = P_CODSITTRIBUIPI,
           EXTIPI        = P_EXTIPI,
           SUBSTANCIA    = P_SUBSTANCIA,
           QTLITRAGEM    = P_QTLITRAGEM,
           REGIMEESPECIAL = P_REGIMEESPECIAL,
           ORIGMERCTRIB = DECODE(NVL(ORIGMERCTRIB, 'X'), 'X', P_ORIGMERCTRIB, ORIGMERCTRIB),
           CODCEST        = P_CODCEST,
           CODMOTISENCAOANVISA = P_CODMOTISENCAOANVISA,
           PERCMVAORIG = P_PERCMVAORIG_ENT
     where NUMTRANSITEM = V_NUMTRANSITEM_TEMP;

    if sql%rowcount = 0
    then
      begin
        select DFSEQ_PCMOVCOMPLE.nextval
          into V_NUMTRANSITEM_TEMP
          from DUAL;

        update PCMOVPREFAT
           set NUMTRANSITEM = V_NUMTRANSITEM_TEMP
         where rowid = P_IDREGISTRO_PCMOV;

        insert into PCMOVCOMPLEPREFAT
          (NUMTRANSITEM, CODSITTRIBIPI, EXTIPI, SUBSTANCIA, QTLITRAGEM, REGIMEESPECIAL, ORIGMERCTRIB, CODCEST)
        values
          (V_NUMTRANSITEM_TEMP, P_CODSITTRIBUIPI, P_EXTIPI, P_SUBSTANCIA, P_QTLITRAGEM, P_REGIMEESPECIAL, P_ORIGMERCTRIB, P_CODCEST);

        return V_NUMTRANSITEM_TEMP;
      exception
        when others then
          return P_NUMTRANSITEM;
      end;
    else
      return V_NUMTRANSITEM_TEMP;
    end if;
    ELSE



    update PCMOVCOMPLE
       set CODSITTRIBIPI = P_CODSITTRIBUIPI,
           EXTIPI        = P_EXTIPI,
           SUBSTANCIA    = P_SUBSTANCIA,
           QTLITRAGEM    = P_QTLITRAGEM,
           REGIMEESPECIAL = P_REGIMEESPECIAL,
           ORIGMERCTRIB = DECODE(NVL(ORIGMERCTRIB, 'X'), 'X', P_ORIGMERCTRIB, ORIGMERCTRIB),
           CODCEST        = P_CODCEST,
           CODMOTISENCAOANVISA = P_CODMOTISENCAOANVISA,
           PERMITECREDITOPRESUMIDO = P_PERMITECREDITOPRESUMIDO,
           PERCMVAORIG = P_PERCMVAORIG_ENT
     where NUMTRANSITEM = V_NUMTRANSITEM_TEMP;

    if sql%rowcount = 0
    then
      begin
        select DFSEQ_PCMOVCOMPLE.nextval
          into V_NUMTRANSITEM_TEMP
          from DUAL;

        update PCMOV
           set NUMTRANSITEM = V_NUMTRANSITEM_TEMP
         where rowid = P_IDREGISTRO_PCMOV;

        insert into PCMOVCOMPLE
          (NUMTRANSITEM, CODSITTRIBIPI, EXTIPI, SUBSTANCIA, QTLITRAGEM, REGIMEESPECIAL, ORIGMERCTRIB, CODCEST, PERMITECREDITOPRESUMIDO)
        values
          (V_NUMTRANSITEM_TEMP, P_CODSITTRIBUIPI, P_EXTIPI, P_SUBSTANCIA, P_QTLITRAGEM, P_REGIMEESPECIAL, P_ORIGMERCTRIB, P_CODCEST, P_PERMITECREDITOPRESUMIDO);

        return V_NUMTRANSITEM_TEMP;
      exception
        when others then
          return P_NUMTRANSITEM;
      end;
    else
      return V_NUMTRANSITEM_TEMP;
    end if;
END IF;
  end;

  /****************************************************************************/


 function GRAVAR_DADOS_PCMOVHISTORICO(P_IDREGISTRO_PCMOV in varchar2,
                                    P_NUMTRANSHISTORICO    in number,
                                    P_CESTABASICALEGIS   in VARCHAR2,
                                    P_PREFATURAMENTO IN VARCHAR2)
    return number is
    V_NUMTRANSHISTORICO_TEMP number;
  begin
   V_NUMTRANSHISTORICO_TEMP := P_NUMTRANSHISTORICO;



    update PCMOVHISTORICO
       set CESTABASICALEGIS = P_CESTABASICALEGIS
     where NUMTRANSHISTORICO = P_NUMTRANSHISTORICO;

    if sql%rowcount = 0
    then
      begin
        select DFSEQ_PCMOVHISTORICO.nextval
          into V_NUMTRANSHISTORICO_TEMP
          from DUAL;

         IF P_PREFATURAMENTO = 'S' THEN
          update PCMOVPREFAT
           set NUMTRANSHISTORICO = V_NUMTRANSHISTORICO_TEMP
         where rowid = P_IDREGISTRO_PCMOV;
         ELSE
        update PCMOV
           set NUMTRANSHISTORICO = V_NUMTRANSHISTORICO_TEMP
         where rowid = P_IDREGISTRO_PCMOV;
END IF;
        insert into PCMOVHISTORICO
          (NUMTRANSHISTORICO, CESTABASICALEGIS)
        values
          (V_NUMTRANSHISTORICO_TEMP, P_CESTABASICALEGIS);

        return V_NUMTRANSHISTORICO_TEMP;
      exception
        when others then
          return V_NUMTRANSHISTORICO_TEMP;
      end;
    ELSE
      RETURN V_NUMTRANSHISTORICO_TEMP;
    END IF;
  END;




  /****************************************************************************/
  procedure GERAR_MOVIMENTACAO(PCODFILIAL in varchar2,
                               PDATA1     in date,
                               PDATA2     in date,
                               PTRANSACAO in number,
                               PTIPOMOV   in varchar2,
                               PCODPROD   in number) is
    VNUMTRANSITEM_NOVO number;
    VNUMTRANSHISTORICO number;
  begin
    ----------------------------------------------------------------------------------
    -- GERAÇÃO DO HISTORICO DOS DADOS DOS ITENS DAS NOTAS FISCAIS
    ----------------------------------------------------------------------------------
    VERRO := 'Erro ao gerar histórico dos itens de entrada/saída';
    for DADOS in (select M.rowid ID_REGISTRO,
                         M.NUMTRANSVENDA,
                         M.NUMTRANSENT,
                         M.CODCLI,
                         M.DTMOV,
                         M.NUMNOTA,
                         M.CODOPER,
                         M.CODPROD,
                         M.CODFISCAL,
                         P.PERICM,
                         M.PUNITCONT,
                         M.VLDESCONTO,
                         M.ST,
                         M.VLIPI,
                         M.VLOUTROS,
                         M.VLOUTRASDESP,
                         M.VLFRETE,
                         (select max(TB.ALIQICMS1)
                            from PCTABPR PR, PCTRIBUT TB
                           where PR.CODPROD = M.CODPROD
                             and PR.NUMREGIAO = FL.NUMREGIAOPADRAO
                             and TB.CODST = PR.CODST) ALIQVIGENTE,
                         P.UNIDADE,
                         P.DESCRICAO,
                         P.DESCRICAO1,
                         D.TIPOMERC TIPOMERCDEPTO,
                         P.TIPOMERC,
                         P.TIPOTRIBUTMEDIC,
                         P.PASSELIVRE,
                         P.CODPASSEFISCAL,
                         P.CODFORNEC,
                         F.TIPOFORNEC,
                         P.NBM,
                         P.CODNCMEX,
                         P.EXTIPI,
                         P.DV,
                         T.IVA,
                         P.CODPRODSINTEGRA,
                         P.CODGENEROFISCAL,
                         P.IMPORTADO,
                         P.EMBALAGEM,
                         P.CLASSIFICFISCAL,
                         P.CODAUXILIAR,
                         (select MAX(NVL(CAIXA,0))
                            from PCNFSAID
                           where NUMTRANSVENDA = M.NUMTRANSVENDA
                  and NVL(PCNFSAID.CODFILIALNF,PCNFSAID.CODFILIAL) = NVL(M.CODFILIALNF, M.CODFILIAL)
                              and PCNFSAID.CAIXA IS NOT NULL) NUMCAIXA,
                         T.CODECF,
                         P.PESOLIQ,
                         P.VOLUME,
                         P.QTUNIT,
                         P.QTUNITCX,
                         P.RUA,
                         F.ESTADO,
                         P.IVARESSARC,
                         P.ICMSRESSARC,
                         P.ALIQAVULSADARE,
                         P.PERCIVAICMANTECIP,
                         P.PERCALIQINTICMANTECIP,
                         P.PERCALIQEXTICMANTECIP,
                         P.TRIBFEDERAL,
                         (select max(nvl(TE.VLPAUTAICMSANTEC,0))
                            from PCNFENT NE, PCTABTRIBENT TE
                           where NE.NUMTRANSENT = M.NUMTRANSENT
                             and NE.ESPECIE = 'NF'
                             and TE.UFORIGEM = NE.UF
                             and TE.UFDESTINO = NE.UFFILIAL
                             and nvl(ne.codfilialnf,ne.codfilial) = nvl(M.codfilialnf,M.codfilial)
                             and TE.CODPROD = M.CODPROD) VLPAUTAICMSANTEC,
                         case
                           when (M.NUMTRANSENT > 0) and (M.CODFISCAL > 3000) then
                            'S'
                           else
                            'N'
                         end IMPORTACAO,
                         P.PERPISIMP,
                         P.PERCOFINSIMP,
                         P.CALCCREDIPI CALCCREDIPI_PROD,
                         P.PISCOFINSRETIDO PISCOFINSRETIDO_PROD,
                         P.PERPIS PERPIS_PROD,
                         P.PERCOFINS PERCOFINS_PROD,
                         PF.CALCCREDIPI CALCCREDIPI_FILIAL,
                         PF.PISCOFINSRETIDO PISCOFINSRETIDO_FILIAL,
                         PF.PERPIS PERPIS_FILIAL,
                         PF.PERCOFINS PERCOFINS_FILIAL,
                         P.CODPRODRELEV,
                         P.CODSITTRIBPISCOFINS CODSITTRIBPISCOFINS_PROD,
                         PF.CODSITTRIBPISCOFINS CODSITTRIBPISCOFINS_FILIAL,
                         P.CODPRODDNF,
                         P.CAPVOLDNF,
                         P.FATORCONVDNF,
                         P.FUNDAPIANO,
                         DECODE(NVL(TI.CODSITTRIBIPIENT,0),0, TIF.CODSITTRIBIPIENT,TI.CODSITTRIBIPIENT) CODSITTRIBIPIENT,
                         DECODE(NVL(TI.CODSITTRIBIPISAID,0),0, TIF.CODSITTRIBIPISAID,TI.CODSITTRIBIPISAID) CODSITTRIBIPISAID,
                         M.NUMTRANSITEM,
                         M.NUMTRANSHISTORICO,
                         P.SUBSTANCIA,
                         P.LITRAGEM,
                         PF.REGIMEESPECIAL,
                         (select MAX(TIPODESCARGA) from PCNFENT
                          WHERE PCNFENT.NUMTRANSENT = PTRANSACAO AND PTIPOMOV = 'E') TIPODESCARGA,
                         (select MAX(CONDVENDA) from PCNFSAID
                          WHERE NUMTRANSVENDA = PTRANSACAO  AND PTIPOMOV = 'S') TIPOVENDA,
                         P.CODINTERNO,
                         PF.ORIGMERCTRIB,
                         P.CESTABASICALEGIS,
                         (SELECT DISTINCT MAX(CODCEST) FROM PCCEST, PCCESTPRODUTO
                                                      WHERE PCCEST.Codigo = PCCESTPRODUTO.CODSEQCEST
                                                        AND PCCESTPRODUTO.CODPROD = M.CODPROD
                                                        AND PCCESTPRODUTO.TIPOPROD = 'N') CODCEST,
                         'N' PREFATURAMENTO,
                         P.CODMOTISENCAOANVISA,
                         PF.PERMITECREDITOPRESUMIDO,
                         P.PERCMVAORIG AS PERCMVAORIG_PROD,
                         --
                         M.CALCCREDIPI,
                         M.CODSITTRIBPISCOFINS,
                         M.PISCOFINSRETIDO,
                         -- Contador para Registro do Update
                         ( -- Totalizando campos se diferentes.
                         DECODE( P.PERICM,M.PERICM,0,1) +
                         DECODE( (select max(TB.ALIQICMS1)
                                        from PCTABPR PR, PCTRIBUT TB
                                       where PR.CODPROD = M.CODPROD
                                          and PR.NUMREGIAO = FL.NUMREGIAOPADRAO
                                          and TB.CODST = PR.CODST), M.ALIQICMSVIGENTE,0,1) +
                         DECODE(M.UNIDADE,P.UNIDADE,0,1) +
                         DECODE(M.DESCRICAO,P.DESCRICAO,0,1) +
                         DECODE(M.DESCRICAO1,P.DESCRICAO1,0,1) +
                         DECODE(M.TIPOMERCDEPTO, D.TIPOMERC,0,1) +
                         DECODE(M.TIPOMERC,P.TIPOMERC,0,1) +
                         DECODE(M.TIPOTRIBUTMEDIC,P.TIPOTRIBUTMEDIC,0,1) +
                         DECODE(M.TIPOFORNEC,F.TIPOFORNEC,0,1) +
                         DECODE(M.PASSELIVRE,P.PASSELIVRE,0,1) +
                         DECODE(M.CODPASSEFISCAL,P.CODPASSEFISCAL,0,1) +
                         DECODE(M.NBM,P.NBM,0,1) +
                         DECODE(M.DV,P.DV,0,1) +
                         DECODE(M.IVATRIBUT,T.IVA,0,1) +
                         DECODE(M.CODPRODSINTEGRA,P.CODPRODSINTEGRA,0,1) +
                         DECODE(M.CODGENEROFISCAL,P.CODGENEROFISCAL,0,1) +
                         DECODE(M.CODFORNECPROD,P.CODFORNEC,0,1) +
                         DECODE(M.IMPORTADO,P.IMPORTADO,0,1) +
                         DECODE(M.EMBALAGEM,P.EMBALAGEM,0,1) +
                         DECODE(M.CLASSIFICFISCAL,P.CLASSIFICFISCAL,0,1) +
                         DECODE(M.CODAUXILIAR, NVL(M.CODAUXILIAR, P.CODAUXILIAR) ,0,1) +
                         DECODE(M.PESOLIQ, P.PESOLIQ,0,1) +
                         DECODE(M.VOLUME, P.VOLUME,0,1) +
                         DECODE(M.QTUNIT, P.QTUNIT,0,1) +
                         DECODE(M.QTUNITCX, P.QTUNITCX,0,1) +
                         DECODE(M.RUA, P.RUA,0,1) +
                         DECODE(M.UFFORNEC, F.ESTADO,0,1) +
                         DECODE(M.IVARESSARC, P.IVARESSARC,0,1) +
                         DECODE(M.ICMSRESSARC, P.ICMSRESSARC,0,1) +
                         DECODE(M.ALIQAVULSADARE, P.ALIQAVULSADARE,0,1) +
                         DECODE(M.PERCIVAICMANTECIP, P.PERCIVAICMANTECIP,0,1) +
                         DECODE(M.PERCALIQINTICMANTECIP, P.PERCALIQINTICMANTECIP,0,1) +
                         DECODE(M.PERCALIQEXTICMANTECIP, P.PERCALIQEXTICMANTECIP,0,1) +
                         DECODE(M.TRIBFEDERAL, P.TRIBFEDERAL,0,1) +
                         DECODE(M.VLPAUTAICMSANTEC, (select max(nvl(TE.VLPAUTAICMSANTEC,0))
                                                      from PCNFENT NE, PCTABTRIBENT TE
                                                     where NE.NUMTRANSENT = M.NUMTRANSENT
                                                       and NE.ESPECIE = 'NF'
                                                       and TE.UFORIGEM = NE.UF
                                                       and TE.UFDESTINO = NE.UFFILIAL
                                                       and nvl(ne.codfilialnf,ne.codfilial) = nvl(M.codfilialnf,M.codfilial)
                                                       and TE.CODPROD = M.CODPROD),0,1) +
                         DECODE(M.CODPRODRELEV, P.CODPRODRELEV,0,1) +
                         DECODE(M.CODPRODDNF,P.CODPRODDNF,0,1) +
                         DECODE(M.CAPVOLDNF,P.CAPVOLDNF,0,1) +
                         DECODE(M.FATORCONVDNF, P.FATORCONVDNF,0,1) +
                         DECODE(M.FUNDAPIANO, P.FUNDAPIANO,0,1) +
                         DECODE(M.CODINTERNO, P.CODINTERNO,0,1) +
                         DECODE(MC.REGIMEESPECIAL, PF.REGIMEESPECIAL,0,1)+
                         DECODE(MC.CODSITTRIBIPI, DECODE(NVL(TI.CODSITTRIBIPISAID,0),0, TIF.CODSITTRIBIPISAID,TI.CODSITTRIBIPISAID),0,1) +
                         DECODE(MC.CODCEST,(SELECT DISTINCT MAX(PCCEST.CODCEST) FROM PCCEST, PCCESTPRODUTO
                                                      WHERE PCCEST.Codigo = PCCESTPRODUTO.CODSEQCEST
                                                        AND PCCESTPRODUTO.CODPROD = M.CODPROD
                                                        AND PCCESTPRODUTO.TIPOPROD = 'N'                                                     
                                                        ),0,1)) CONTADOR
                    from PCMOV M,
                         PCMOVCOMPLE MC,
                         PCPRODUT P,
                         PCFORNEC F,
                         PCTRIBUT T,
                         PCFILIAL FL,
                         PCDEPTO D,
                         PCTRIBIPI TI,
                         PCFIGURATRIBIPI TIF,
                         (select CODPROD,
                                 CALCCREDIPI,
                                 PISCOFINSRETIDO,
                                 PERPIS,
                                 PERCOFINS,
                                 CODSITTRIBPISCOFINS,
                                 REGIMEESPECIAL,
                                 ORIGMERCTRIB,
                                 PERMITECREDITOPRESUMIDO
                            from PCPRODFILIAL
                           where CODFILIAL = PCODFILIAL) PF
                   where  M.DTMOV between PDATA1 and PDATA2
                     and NVL(M.CODFILIALNF, M.CODFILIAL) = PCODFILIAL
                     AND P.CODPROD BETWEEN DECODE(NVL(PCODPROD,0),0,0,PCODPROD) AND
                                           DECODE(NVL(PCODPROD,0),0,9999999999,PCODPROD)
                     and M.CODPROD = P.CODPROD
                     and M.NUMTRANSITEM = MC.NUMTRANSITEM(+)
                     and M.CODPROD = TI.CODPROD(+)
                     and NVL(M.CODFILIALNF, M.CODFILIAL) = TI.CODFILIAL(+)
                     and TI.CODFIGURAIPI = TIF.CODFIGURAIPI(+)
                     and P.CODEPTO = D.CODEPTO(+)
                     and P.CODFORNEC = F.CODFORNEC(+)
                     and M.CODST = T.CODST(+)
                     and FL.CODIGO = NVL(M.CODFILIALNF, M.CODFILIAL)
                     and PF.CODPROD(+) = M.CODPROD
                     and M.STATUS IN ('A', 'AB')
                     and ((PTIPOMOV = 'T' and M.DTMOV between PDATA1 and
                         PDATA2) or
                         (PTIPOMOV = 'E' and M.NUMTRANSENT = PTRANSACAO) or
                         (PTIPOMOV = 'S' and M.NUMTRANSVENDA = PTRANSACAO))
                     and (NVL(VREPROCESSAR, 'N') = 'S' or
                         NVL(M.HISTORICO, 'N') = 'N')
                   --------------------------------------------------------------------------------------
                   UNION ALL
                   --------------------------------------------------------------------------------------
                   select M.rowid ID_REGISTRO,
                         M.NUMTRANSVENDA,
                         M.NUMTRANSENT,
                         M.CODCLI,
                         M.DTMOV,
                         M.NUMNOTA,
                         M.CODOPER,
                         M.CODPROD,
                         M.CODFISCAL,
                         P.PERICM,
                         M.PUNITCONT,
                         M.VLDESCONTO,
                         M.ST,
                         M.VLIPI,
                         M.VLOUTROS,
                         M.VLOUTRASDESP,
                         M.VLFRETE,
                         (select max(TB.ALIQICMS1)
                            from PCTABPR PR, PCTRIBUT TB
                           where PR.CODPROD = M.CODPROD
                             and PR.NUMREGIAO = FL.NUMREGIAOPADRAO
                             and TB.CODST = PR.CODST) ALIQVIGENTE,
                         P.UNIDADE,
                         P.DESCRICAO,
                         P.DESCRICAO1,
                         D.TIPOMERC TIPOMERCDEPTO,
                         P.TIPOMERC,
                         P.TIPOTRIBUTMEDIC,
                         P.PASSELIVRE,
                         P.CODPASSEFISCAL,
                         P.CODFORNEC,
                         F.TIPOFORNEC,
                         P.NBM,
                         P.CODNCMEX,
                         P.EXTIPI,
                         P.DV,
                         T.IVA,
                         P.CODPRODSINTEGRA,
                         P.CODGENEROFISCAL,
                         P.IMPORTADO,
                         P.EMBALAGEM,
                         P.CLASSIFICFISCAL,
                         P.CODAUXILIAR,
                         (select MAX(NVL(CAIXA,0))
                            from PCNFSAIDPREFAT
                           where PCNFSAIDPREFAT.NUMTRANSVENDA = M.NUMTRANSVENDA
                  and NVL(PCNFSAIDPREFAT.CODFILIALNF,PCNFSAIDPREFAT.CODFILIAL) = NVL(M.CODFILIALNF, M.CODFILIAL)
                              and PCNFSAIDPREFAT.CAIXA IS NOT NULL) NUMCAIXA,
                         T.CODECF,
                         P.PESOLIQ,
                         P.VOLUME,
                         P.QTUNIT,
                         P.QTUNITCX,
                         P.RUA,
                         F.ESTADO,
                         P.IVARESSARC,
                         P.ICMSRESSARC,
                         P.ALIQAVULSADARE,
                         P.PERCIVAICMANTECIP,
                         P.PERCALIQINTICMANTECIP,
                         P.PERCALIQEXTICMANTECIP,
                         P.TRIBFEDERAL,
                         (select max(nvl(TE.VLPAUTAICMSANTEC,0))
                            from PCNFENT NE, PCTABTRIBENT TE
                           where NE.NUMTRANSENT = M.NUMTRANSENT
                             and NE.ESPECIE = 'NF'
                             and TE.UFORIGEM = NE.UF
                             and TE.UFDESTINO = NE.UFFILIAL
                             and nvl(ne.codfilialnf,ne.codfilial) = nvl(M.codfilialnf,M.codfilial)
                             and TE.CODPROD = M.CODPROD) VLPAUTAICMSANTEC,
                         case
                           when (M.NUMTRANSENT > 0) and (M.CODFISCAL > 3000) then
                            'S'
                           else
                            'N'
                         end IMPORTACAO,
                         P.PERPISIMP,
                         P.PERCOFINSIMP,
                         P.CALCCREDIPI CALCCREDIPI_PROD,
                         P.PISCOFINSRETIDO PISCOFINSRETIDO_PROD,
                         P.PERPIS PERPIS_PROD,
                         P.PERCOFINS PERCOFINS_PROD,
                         PF.CALCCREDIPI CALCCREDIPI_FILIAL,
                         PF.PISCOFINSRETIDO PISCOFINSRETIDO_FILIAL,
                         PF.PERPIS PERPIS_FILIAL,
                         PF.PERCOFINS PERCOFINS_FILIAL,
                         P.CODPRODRELEV,
                         P.CODSITTRIBPISCOFINS CODSITTRIBPISCOFINS_PROD,
                         PF.CODSITTRIBPISCOFINS CODSITTRIBPISCOFINS_FILIAL,
                         P.CODPRODDNF,
                         P.CAPVOLDNF,
                         P.FATORCONVDNF,
                         P.FUNDAPIANO,
                         DECODE(NVL(TI.CODSITTRIBIPIENT,0),0, TIF.CODSITTRIBIPIENT,TI.CODSITTRIBIPIENT) CODSITTRIBIPIENT,
                         DECODE(NVL(TI.CODSITTRIBIPISAID,0),0, TIF.CODSITTRIBIPISAID,TI.CODSITTRIBIPISAID) CODSITTRIBIPISAID,
                         M.NUMTRANSITEM,
                         M.NUMTRANSHISTORICO,
                         P.SUBSTANCIA,
                         P.LITRAGEM,
                         PF.REGIMEESPECIAL,
                         (select MAX(TIPODESCARGA) from PCNFENT
                          WHERE PCNFENT.NUMTRANSENT = PTRANSACAO AND PTIPOMOV = 'E') TIPODESCARGA,
                         (select MAX(CONDVENDA) from PCNFSAIDPREFAT
                          WHERE NUMTRANSVENDA = PTRANSACAO  AND PTIPOMOV = 'S') TIPOVENDA,
                         P.CODINTERNO,
                         PF.ORIGMERCTRIB,
                         P.CESTABASICALEGIS,
                         (SELECT DISTINCT MAX(CODCEST) FROM PCCEST, PCCESTPRODUTO
                         WHERE PCCEST.Codigo = PCCESTPRODUTO.CODSEQCEST
                         AND PCCESTPRODUTO.CODPROD = M.CODPROD AND PCCESTPRODUTO.TIPOPROD = 'N') CODCEST,
                         'S' PREFATURAMENTO,
                         P.CODMOTISENCAOANVISA,
                         PF.PERMITECREDITOPRESUMIDO,
                         P.PERCMVAORIG AS PERCMVAORIG_PROD,
                         M.CALCCREDIPI,
                         M.CODSITTRIBPISCOFINS,
                         M.PISCOFINSRETIDO,
                         -- Contador para Registro do Update
                         ( -- Totalizando campos se diferentes.
                         DECODE( P.PERICM,M.PERICM,0,1) +
                         DECODE( (select max(TB.ALIQICMS1)
                                        from PCTABPR PR, PCTRIBUT TB
                                       where PR.CODPROD = M.CODPROD
                                          and PR.NUMREGIAO = FL.NUMREGIAOPADRAO
                                          and TB.CODST = PR.CODST), M.ALIQICMSVIGENTE,0,1) +
                         DECODE(M.UNIDADE,P.UNIDADE,0,1) +
                         DECODE(M.DESCRICAO,P.DESCRICAO,0,1) +
                         DECODE(M.DESCRICAO1,P.DESCRICAO1,0,1) +
                         DECODE(M.TIPOMERCDEPTO, D.TIPOMERC,0,1) +
                         DECODE(M.TIPOMERC,P.TIPOMERC,0,1) +
                         DECODE(M.TIPOTRIBUTMEDIC,P.TIPOTRIBUTMEDIC,0,1) +
                         DECODE(M.TIPOFORNEC,F.TIPOFORNEC,0,1) +
                         DECODE(M.PASSELIVRE,P.PASSELIVRE,0,1) +
                         DECODE(M.CODPASSEFISCAL,P.CODPASSEFISCAL,0,1) +
                         DECODE(M.NBM,P.NBM,0,1) +
                         DECODE(M.DV,P.DV,0,1) +
                         DECODE(M.IVATRIBUT,T.IVA,0,1) +
                         DECODE(M.CODPRODSINTEGRA,P.CODPRODSINTEGRA,0,1) +
                         DECODE(M.CODGENEROFISCAL,P.CODGENEROFISCAL,0,1) +
                         DECODE(M.CODFORNECPROD,P.CODFORNEC,0,1) +
                         DECODE(M.IMPORTADO,P.IMPORTADO,0,1) +
                         DECODE(M.EMBALAGEM,P.EMBALAGEM,0,1) +
                         DECODE(M.CLASSIFICFISCAL,P.CLASSIFICFISCAL,0,1) +
                         DECODE(M.CODAUXILIAR, NVL(M.CODAUXILIAR, P.CODAUXILIAR) ,0,1) +
                         DECODE(M.PESOLIQ, P.PESOLIQ,0,1) +
                         DECODE(M.VOLUME, P.VOLUME,0,1) +
                         DECODE(M.QTUNIT, P.QTUNIT,0,1) +
                         DECODE(M.QTUNITCX, P.QTUNITCX,0,1) +
                         DECODE(M.RUA, P.RUA,0,1) +
                         DECODE(M.UFFORNEC, F.ESTADO,0,1) +
                         DECODE(M.IVARESSARC, P.IVARESSARC,0,1) +
                         DECODE(M.ICMSRESSARC, P.ICMSRESSARC,0,1) +
                         DECODE(M.ALIQAVULSADARE, P.ALIQAVULSADARE,0,1) +
                         DECODE(M.PERCIVAICMANTECIP, P.PERCIVAICMANTECIP,0,1) +
                         DECODE(M.PERCALIQINTICMANTECIP, P.PERCALIQINTICMANTECIP,0,1) +
                         DECODE(M.PERCALIQEXTICMANTECIP, P.PERCALIQEXTICMANTECIP,0,1) +
                         DECODE(M.TRIBFEDERAL, P.TRIBFEDERAL,0,1) +
                         DECODE(MC.REGIMEESPECIAL, PF.REGIMEESPECIAL,0,1)+
                         DECODE(MC.CODSITTRIBIPI, DECODE(NVL(TI.CODSITTRIBIPISAID,0),0, TIF.CODSITTRIBIPISAID,TI.CODSITTRIBIPISAID),0,1) +
                         DECODE(M.VLPAUTAICMSANTEC, (select max(nvl(TE.VLPAUTAICMSANTEC,0))
                                                      from PCNFENT NE, PCTABTRIBENT TE
                                                     where NE.NUMTRANSENT = M.NUMTRANSENT
                                                       and NE.ESPECIE = 'NF'
                                                       and TE.UFORIGEM = NE.UF
                                                       and TE.UFDESTINO = NE.UFFILIAL
                                                       and nvl(ne.codfilialnf,ne.codfilial) = nvl(M.codfilialnf,M.codfilial)
                                                       and TE.CODPROD = M.CODPROD),0,1) +
                         DECODE(M.CODPRODRELEV, P.CODPRODRELEV,0,1) +
                         DECODE(M.CODPRODDNF,P.CODPRODDNF,0,1) +
                         DECODE(M.CAPVOLDNF,P.CAPVOLDNF,0,1) +
                         DECODE(M.FATORCONVDNF, P.FATORCONVDNF,0,1) +
                         DECODE(M.FUNDAPIANO, P.FUNDAPIANO,0,1) +
                         DECODE(M.CODINTERNO, P.CODINTERNO,0,1) + 
                         DECODE(MC.CODCEST,(SELECT DISTINCT MAX(PCCEST.CODCEST) FROM PCCEST, PCCESTPRODUTO
                                                      WHERE PCCEST.Codigo = PCCESTPRODUTO.CODSEQCEST
                                                        AND PCCESTPRODUTO.CODPROD = M.CODPROD
                                                        AND PCCESTPRODUTO.TIPOPROD = 'N'                                                     
                                                        ),0,1)) CONTADOR
                    from PCMOVPREFAT M,
                         PCMOVCOMPLEPREFAT MC,
                         PCPRODUT P,
                         PCFORNEC F,
                         PCTRIBUT T,
                         PCFILIAL FL,
                         PCDEPTO D,
                         PCTRIBIPI TI,
                         PCFIGURATRIBIPI TIF,
                         (select CODPROD,
                                 CALCCREDIPI,
                                 PISCOFINSRETIDO,
                                 PERPIS,
                                 PERCOFINS,
                                 CODSITTRIBPISCOFINS,
                                 REGIMEESPECIAL,
                                 ORIGMERCTRIB,
                                 PERMITECREDITOPRESUMIDO
                            from PCPRODFILIAL
                           where CODFILIAL = PCODFILIAL) PF
                   where  M.DTMOV between PDATA1 and PDATA2
                     and NVL(M.CODFILIALNF, M.CODFILIAL) = PCODFILIAL
--                     and (NVL(PCODPROD, 0) = 0 or P.CODPROD = PCODPROD)
                     and M.NUMTRANSITEM = MC.NUMTRANSITEM(+)
                     AND TO_NUMBER(P.CODPROD) BETWEEN DECODE(NVL(PCODPROD,0),0,0,PCODPROD) AND
                                                      DECODE(NVL(PCODPROD,0),0,9999999999,PCODPROD)
                     and M.CODPROD = P.CODPROD
                     and M.CODPROD = TI.CODPROD(+)
                     and NVL(M.CODFILIALNF, M.CODFILIAL) = TI.CODFILIAL(+)
                     and TI.CODFIGURAIPI = TIF.CODFIGURAIPI(+)
                     and P.CODEPTO = D.CODEPTO(+)
                     and P.CODFORNEC = F.CODFORNEC(+)
                     and M.CODST = T.CODST(+)
                     and FL.CODIGO = NVL(M.CODFILIALNF, M.CODFILIAL)
                     and PF.CODPROD(+) = M.CODPROD
                     and M.STATUS IN ('A', 'AB')
                     and ((PTIPOMOV = 'T' and M.DTMOV between PDATA1 and
                         PDATA2) or
                         (PTIPOMOV = 'E' and M.NUMTRANSENT = PTRANSACAO) or
                         (PTIPOMOV = 'S' and M.NUMTRANSVENDA = PTRANSACAO))
                     and (NVL(VREPROCESSAR, 'N') = 'S' or
                         NVL(M.HISTORICO, 'N') = 'N')
                   order by NUMTRANSENT, NUMTRANSVENDA)
    loop
      VNUMNOTA := DADOS.NUMNOTA;
      --------------------------------------------------------------------------------
      VCODSITTRIBPISCOFINS := DADOS.CODSITTRIBPISCOFINS_PROD;
      VCALCCREDIPI         := NVL(DADOS.CALCCREDIPI_FILIAL, NVL(DADOS.CALCCREDIPI_PROD, 'N'));
      VPISCOFINSRETIDO     := DADOS.PISCOFINSRETIDO_PROD;
      VPERCMVAORIG_ENT     := DADOS.PERCMVAORIG_PROD;
      --------------------------------------------------------------------------------
      -- Recuperando dados de IPI
      V_RETORNO_IPI := FISCAL.GET_DADOS_TRIBUTACAO_IPI(DADOS.CODCLI,
                                                       DADOS.CODPROD,
                                                       PCODFILIAL,
                                                       DADOS.DTMOV,
                                                       V_CSTIPI_ENTRADA,
                                                       V_CSTIPI_SAIDA,
                                                       V_GERABASEIPIALIQZERO,
                                                       V_MSG_IPI,
                                                       DADOS.CODFISCAL,
                                                       DADOS.TIPOVENDA,
                                                       DADOS.TIPODESCARGA,
                                                       DADOS.CODOPER);
      --------------------------------------------------------------------------------

      if DADOS.NUMTRANSVENDA > 0
      then
        --------------------------------------------------------------------------------
        if VULTIMA_TRANSACAO <> DADOS.NUMTRANSVENDA
        then
          /* Não atualizar o cabeçalho por aqui, será atualizado separadamente
          GERAR_CAB_SAIDAS(PCODFILIAL,
                           PDATA1,
                           PDATA2,
                           DADOS.NUMTRANSVENDA,
                           0);*/
          VULTIMA_TRANSACAO := DADOS.NUMTRANSVENDA;
        end if;
        --------------------------------------------------------------------------------
        -- BUSCANDO TRIBUTAÇÃO POR UF SE FOR O CASO
        if (VUSAPISCOFINSPORFILIAL = 'S')
        then
          VCODSITTRIBPISCOFINS := NVL(DADOS.CODSITTRIBPISCOFINS_FILIAL,
                                      DADOS.CODSITTRIBPISCOFINS_PROD);
          VPISCOFINSRETIDO     := NVL(DADOS.PISCOFINSRETIDO_FILIAL,
                                      NVL(DADOS.PISCOFINSRETIDO_PROD, 'N'));
        else
          VCODSITTRIBPISCOFINS := DADOS.CODSITTRIBPISCOFINS_PROD;
          VPISCOFINSRETIDO     := NVL(DADOS.PISCOFINSRETIDO_PROD, 'N');
        end if;
        --------------------------------------------------------------------------------
        VPISCOFINSRETIDO := NVL(VPISCOFINSRETIDO, 'N');
        --------------------------------------------------------------------------------
        begin
          select max(case
                       when USAINDICEECF = 'S' then
                        (select CODECF
                           from PCINDICEECF
                          where NUMCAIXA = DADOS.NUMCAIXA
                            and INDICE = DADOS.CODECF)
                       else
                        DADOS.CODECF
                     end)
            into VCODECF
            from PCCAIXA
           where NUMCAIXA = DADOS.NUMCAIXA;
          --------------------------------------------------------------------------------
        exception
          when others then
            VCODECF := DADOS.CODECF;
        end;
        --------------------------------------------------------------------------------
      -- Adicionando ao contador os campos processados em tempo de execução.
      if DADOS.CODECF <> NVL(DADOS.CODECF, VCODECF) then
         DADOS.CONTADOR := DADOS.CONTADOR + 1;
      end if;

      if DADOS.CODSITTRIBPISCOFINS <> NVL(DADOS.CODSITTRIBPISCOFINS,VCODSITTRIBPISCOFINS) then
         DADOS.CONTADOR := DADOS.CONTADOR + 1;
      end if;

      if DADOS.PISCOFINSRETIDO <> VPISCOFINSRETIDO then 
         DADOS.CONTADOR := DADOS.CONTADOR + 1;
      end if;  

      if DADOS.CALCCREDIPI <> VCALCCREDIPI theN 
          DADOS.CONTADOR := DADOS.CONTADOR + 1;
      end if; 
      --------------------------------------------------------------------------------
      if DADOS.CONTADOR > 0 then

        VNUMTRANSITEM_NOVO := GRAVAR_DADOS_PCMOVCOMPLE(DADOS.ID_REGISTRO,
                                                       DADOS.NUMTRANSITEM,
                                                       V_CSTIPI_SAIDA,
                                                       DADOS.EXTIPI,
                                                       DADOS.SUBSTANCIA,
                                                       DADOS.LITRAGEM,
                                                       DADOS.REGIMEESPECIAL,
                                                       DADOS.ORIGMERCTRIB,
                                                       DADOS.CODCEST,
                                                       DADOS.PREFATURAMENTO,
                                                       DADOS.CODMOTISENCAOANVISA,
                                                       DADOS.PERMITECREDITOPRESUMIDO,
                                                       DADOS.PERCMVAORIG_PROD);

         VNUMTRANSHISTORICO := GRAVAR_DADOS_PCMOVHISTORICO(DADOS.ID_REGISTRO,
                                                           DADOS.NUMTRANSHISTORICO,
                                                           DADOS.CESTABASICALEGIS,
                                                           DADOS.PREFATURAMENTO);
        --------------------------------------------------------------------------------

      IF DADOS.PREFATURAMENTO = 'S' THEN

        update PCMOVPREFAT
           set PERICM                = DADOS.PERICM,
               ALIQICMSVIGENTE       = DADOS.ALIQVIGENTE,
               UNIDADE               = DADOS.UNIDADE,
               DESCRICAO             = DADOS.DESCRICAO,
               DESCRICAO1            = DADOS.DESCRICAO1,
               TIPOMERCDEPTO         = DADOS.TIPOMERCDEPTO,
               TIPOMERC              = DADOS.TIPOMERC,
               TIPOTRIBUTMEDIC       = DADOS.TIPOTRIBUTMEDIC,
               TIPOFORNEC            = DADOS.TIPOFORNEC,
               PASSELIVRE            = DADOS.PASSELIVRE,
               CODPASSEFISCAL        = DADOS.CODPASSEFISCAL,
               NBM                   = DADOS.NBM,
               DV                    = DADOS.DV,
               IVATRIBUT             = DADOS.IVA,
               CODPRODSINTEGRA       = DADOS.CODPRODSINTEGRA,
               CODGENEROFISCAL       = DADOS.CODGENEROFISCAL,
               CODFORNECPROD         = DADOS.CODFORNEC,
               IMPORTADO             = DADOS.IMPORTADO,
               EMBALAGEM             = DADOS.EMBALAGEM,
               CLASSIFICFISCAL       = DADOS.CLASSIFICFISCAL,
               CODAUXILIAR           = NVL(CODAUXILIAR, DADOS.CODAUXILIAR),
               CODECF                = NVL(CODECF, VCODECF),
               PESOLIQ               = DADOS.PESOLIQ,
               VOLUME                = DADOS.VOLUME,
               QTUNIT                = DADOS.QTUNIT,
               QTUNITCX              = DADOS.QTUNITCX,
               RUA                   = DADOS.RUA,
               UFFORNEC              = DADOS.ESTADO,
               IVARESSARC            = DADOS.IVARESSARC,
               ICMSRESSARC           = DADOS.ICMSRESSARC,
               ALIQAVULSADARE        = DADOS.ALIQAVULSADARE,
               PERCIVAICMANTECIP     = DADOS.PERCIVAICMANTECIP,
               PERCALIQINTICMANTECIP = DADOS.PERCALIQINTICMANTECIP,
               PERCALIQEXTICMANTECIP = DADOS.PERCALIQEXTICMANTECIP,
               TRIBFEDERAL           = DADOS.TRIBFEDERAL,
               VLPAUTAICMSANTEC      = DADOS.VLPAUTAICMSANTEC,
               BCISS                 = DADOS.PUNITCONT - NVL(DADOS.VLIPI, 0) - NVL(DADOS.ST, 0),
               CODPRODRELEV          = DADOS.CODPRODRELEV,
               CALCCREDIPI           = VCALCCREDIPI,
               CODSITTRIBPISCOFINS   = NVL(CODSITTRIBPISCOFINS, VCODSITTRIBPISCOFINS),
               PISCOFINSRETIDO       = VPISCOFINSRETIDO,
               CODPRODDNF            = DADOS.CODPRODDNF,
               CAPVOLDNF             = DADOS.CAPVOLDNF,
               FATORCONVDNF          = DADOS.FATORCONVDNF,
               FUNDAPIANO            = DADOS.FUNDAPIANO,
               NUMTRANSITEM          = VNUMTRANSITEM_NOVO,
               NUMTRANSHISTORICO     = VNUMTRANSHISTORICO,
               HISTORICO             = 'S',
               CODINTERNO            = DADOS.CODINTERNO
         where rowid = DADOS.ID_REGISTRO;
      ELSE

        update PCMOV
           set PERICM                = DADOS.PERICM,
               ALIQICMSVIGENTE       = DADOS.ALIQVIGENTE,
               UNIDADE               = DADOS.UNIDADE,
               DESCRICAO             = DADOS.DESCRICAO,
               DESCRICAO1            = DADOS.DESCRICAO1,
               TIPOMERCDEPTO         = DADOS.TIPOMERCDEPTO,
               TIPOMERC              = DADOS.TIPOMERC,
               TIPOTRIBUTMEDIC       = DADOS.TIPOTRIBUTMEDIC,
               TIPOFORNEC            = DADOS.TIPOFORNEC,
               PASSELIVRE            = DADOS.PASSELIVRE,
               CODPASSEFISCAL        = DADOS.CODPASSEFISCAL,
               NBM                   = DADOS.NBM,
               DV                    = DADOS.DV,
               IVATRIBUT             = DADOS.IVA,
               CODPRODSINTEGRA       = DADOS.CODPRODSINTEGRA,
               CODGENEROFISCAL       = DADOS.CODGENEROFISCAL,
               CODFORNECPROD         = DADOS.CODFORNEC,
               IMPORTADO             = DADOS.IMPORTADO,
               EMBALAGEM             = DADOS.EMBALAGEM,
               CLASSIFICFISCAL       = DADOS.CLASSIFICFISCAL,
               CODAUXILIAR           = NVL(CODAUXILIAR, DADOS.CODAUXILIAR),
               CODECF                = NVL(CODECF, VCODECF),
               PESOLIQ               = DADOS.PESOLIQ,
               VOLUME                = DADOS.VOLUME,
               QTUNIT                = DADOS.QTUNIT,
               QTUNITCX              = DADOS.QTUNITCX,
               RUA                   = DADOS.RUA,
               UFFORNEC              = DADOS.ESTADO,
               IVARESSARC            = DADOS.IVARESSARC,
               ICMSRESSARC           = DADOS.ICMSRESSARC,
               ALIQAVULSADARE        = DADOS.ALIQAVULSADARE,
               PERCIVAICMANTECIP     = DADOS.PERCIVAICMANTECIP,
               PERCALIQINTICMANTECIP = DADOS.PERCALIQINTICMANTECIP,
               PERCALIQEXTICMANTECIP = DADOS.PERCALIQEXTICMANTECIP,
               TRIBFEDERAL           = DADOS.TRIBFEDERAL,
               VLPAUTAICMSANTEC      = DADOS.VLPAUTAICMSANTEC,
               BCISS                 = DADOS.PUNITCONT - NVL(DADOS.VLIPI, 0) - NVL(DADOS.ST, 0),
               CODPRODRELEV          = DADOS.CODPRODRELEV,
               CALCCREDIPI           = VCALCCREDIPI,
               CODSITTRIBPISCOFINS   = NVL(CODSITTRIBPISCOFINS, VCODSITTRIBPISCOFINS),
               PISCOFINSRETIDO       = VPISCOFINSRETIDO,
               CODPRODDNF            = DADOS.CODPRODDNF,
               CAPVOLDNF             = DADOS.CAPVOLDNF,
               FATORCONVDNF          = DADOS.FATORCONVDNF,
               FUNDAPIANO            = DADOS.FUNDAPIANO,
               NUMTRANSITEM          = VNUMTRANSITEM_NOVO,
               NUMTRANSHISTORICO     = VNUMTRANSHISTORICO,
               HISTORICO             = 'S',
               CODINTERNO            = DADOS.CODINTERNO
         where rowid = DADOS.ID_REGISTRO;

         END IF;
        end if;
        --------------------------------------------------------------------------------
      else
        --------------------------------------------------------------------------------
        if VULTIMA_TRANSACAO <> DADOS.NUMTRANSENT
        then
          /* Não atualizar o cabeçalho por aqui, será atualizado separadamente
          GERAR_CAB_ENTRADAS(PCODFILIAL,
                             PDATA1,
                             PDATA2,
                             DADOS.NUMTRANSENT,
                             0,
                             'T');*/
          VULTIMA_TRANSACAO := DADOS.NUMTRANSENT;
        end if;
        --------------------------------------------------------------------------------
        -- TRIBUTANDO PIS/COFINS
        if VUSAPISCOFINSPORFILIAL = 'S'
        then
          VCODSITTRIBPISCOFINS := NVL(DADOS.CODSITTRIBPISCOFINS_PROD, DADOS.CODSITTRIBPISCOFINS_FILIAL);
          VCALCCREDIPI         := NVL(DADOS.CALCCREDIPI_FILIAL, DADOS.CALCCREDIPI_PROD);
          VPISCOFINSRETIDO     := NVL(DADOS.PISCOFINSRETIDO_FILIAL, DADOS.PISCOFINSRETIDO_PROD);
        else
          if VUSATRIBENTPORUF = 'S'
          then
            for TRIB in (select T.CALCCREDIPI,
                                T.PISCOFINSRETIDO,
                                T.PERPIS,
                                T.PERCOFINS,
                                T.CODSITTRIBPISCOFINS,
                                T.PERCMVAORIG
                           from PCNFENT N, PCTABTRIBENT T
                          where N.NUMTRANSENT = DADOS.NUMTRANSENT
                            and N.NUMNOTA = DADOS.NUMNOTA
                            and T.CODPROD = DADOS.CODPROD
                            and T.UFORIGEM = N.UF
                            and T.UFDESTINO = VUFFILIAL)
            loop
              VCODSITTRIBPISCOFINS := NVL(TRIB.CODSITTRIBPISCOFINS, DADOS.CODSITTRIBPISCOFINS_PROD);

              VCALCCREDIPI     := NVL(TRIB.CALCCREDIPI, DADOS.CALCCREDIPI_PROD);
              VPISCOFINSRETIDO := NVL(TRIB.PISCOFINSRETIDO, DADOS.PISCOFINSRETIDO_PROD);
              VPERCMVAORIG_ENT :=  NVL(TRIB.PERCMVAORIG, DADOS.PERCMVAORIG_PROD);
            end loop;
          elsif trim(VUSATRIBENTPORUF) = 'F'
          then
            for TRIB in (select FPROD.CALCCREDIPI         CALCCREDIPI_PRODFIG,
                                FPROD.PISCOFINSRETIDO     PISCOFINSRETIDO_PRODFIG,
                                FPROD.PERPIS              PERPIS_PRODFIG,
                                FPROD.PERCOFINS           PERCOFINS_PRODFIG,
                                FPROD.CODSITTRIBPISCOFINS CODSITTRIBPISCOFINS_PRODFIG,
                                FPROD.PERCMVAORIG         PERCMVAORIG_PRODFIG,
                                F.CALCCREDIPI             CALCCREDIPI_FIG,
                                F.PISCOFINSRETIDO         PISCOFINSRETIDO_FIG,
                                F.PERPIS                  PERPIS_FIG,
                                F.PERCOFINS               PERCOFINS_FIG,
                                F.CODSITTRIBPISCOFINS     CODSITTRIBPISCOFINS_FIG,
                                F.PERCMVAORIG             PERCMVAORIG_FIG
                           from PCNFENT       N,
                                PCTRIBENTRADA T,
                                PCTRIBFIGURA  F,
                                PCPRODFILIAL  PF,
                                PCTRIBFIGURA  FPROD
                          where N.NUMTRANSENT = DADOS.NUMTRANSENT
                            and N.NUMNOTA = DADOS.NUMNOTA
                            and PF.CODPROD = DADOS.CODPROD
                            and PF.CODFILIAL = PCODFILIAL
                            and PF.CODFIGURA = FPROD.CODFIGURA(+)
                            and T.CODFIGURA = F.CODFIGURA
                            and T.UFORIGEM = N.UF
                            and T.CODFILIAL = PCODFILIAL
                            and T.TIPOFORNEC = N.TIPOFORNEC
                            and ((T.NCM = DADOS.NBM) OR (T.NCM = DADOS.CODNCMEX)))
            loop
              VCODSITTRIBPISCOFINS := NVL(TRIB.CODSITTRIBPISCOFINS_PRODFIG, NVL(TRIB.CODSITTRIBPISCOFINS_FIG, DADOS.CODSITTRIBPISCOFINS_PROD));
              VCALCCREDIPI         := NVL(TRIB.CALCCREDIPI_PRODFIG, NVL(TRIB.CALCCREDIPI_FIG, DADOS.CALCCREDIPI_PROD));
              VPISCOFINSRETIDO     := NVL(TRIB.PISCOFINSRETIDO_PRODFIG, NVL(TRIB.PISCOFINSRETIDO_FIG, DADOS.PISCOFINSRETIDO_PROD));
              VPERCMVAORIG_ENT     :=  NVL(TRIB.PERCMVAORIG_PRODFIG, NVL(TRIB.PERCMVAORIG_FIG, DADOS.PERCMVAORIG_PROD));
            end loop;
          elsif trim(VUSATRIBENTPORUF) = 'P'
          then
            for TRIB in (select FPROD.CALCCREDIPI         CALCCREDIPI_PRODFIG,
                                FPROD.PISCOFINSRETIDO     PISCOFINSRETIDO_PRODFIG,
                                FPROD.PERPIS              PERPIS_PRODFIG,
                                FPROD.PERCOFINS           PERCOFINS_PRODFIG,
                                FPROD.CODSITTRIBPISCOFINS CODSITTRIBPISCOFINS_PRODFIG,
                                FPROD.PERCMVAORIG         PERCMVAORIG_PRODFIG,
                                F.CALCCREDIPI             CALCCREDIPI_FIG,
                                F.PISCOFINSRETIDO         PISCOFINSRETIDO_FIG,
                                F.PERPIS                  PERPIS_FIG,
                                F.PERCOFINS               PERCOFINS_FIG,
                                F.CODSITTRIBPISCOFINS     CODSITTRIBPISCOFINS_FIG,
                                F.PERCMVAORIG             PERCMVAORIG_FIG
                           from PCNFENT       N,
                                PCTRIBENTPROD T,
                                PCTRIBFIGURA  F,
                                PCPRODFILIAL  PF,
                                PCTRIBFIGURA  FPROD
                          where N.NUMTRANSENT = DADOS.NUMTRANSENT
                            and N.NUMNOTA = DADOS.NUMNOTA
                            and PF.CODPROD = DADOS.CODPROD
                            and PF.CODFILIAL = PCODFILIAL
                            and PF.CODFIGURA = FPROD.CODFIGURA(+)
                            and T.CODFIGURA = F.CODFIGURA
                            and T.UFORIGEM = N.UF
                            and T.CODFILIAL = PCODFILIAL
                            and T.TIPOFORNEC = N.TIPOFORNEC
                            and T.CODPROD = DADOS.CODPROD)
            loop
              VCODSITTRIBPISCOFINS := NVL(TRIB.CODSITTRIBPISCOFINS_PRODFIG,
                                          NVL(TRIB.CODSITTRIBPISCOFINS_FIG,
                                              DADOS.CODSITTRIBPISCOFINS_PROD));
              VCALCCREDIPI         := NVL(TRIB.CALCCREDIPI_PRODFIG,
                                          NVL(TRIB.CALCCREDIPI_FIG,
                                              DADOS.CALCCREDIPI_PROD));
              VPISCOFINSRETIDO     := NVL(TRIB.PISCOFINSRETIDO_PRODFIG,
                                          NVL(TRIB.PISCOFINSRETIDO_FIG,
                                              DADOS.PISCOFINSRETIDO_PROD));
              VPERCMVAORIG_ENT     :=  NVL(TRIB.PERCMVAORIG_PRODFIG, NVL(TRIB.PERCMVAORIG_FIG, DADOS.PERCMVAORIG_PROD));
            end loop;
          end if;
        end if;
        --------------------------------------------------------------------------------
        VPISCOFINSRETIDO := NVL(VPISCOFINSRETIDO, 'N');
        --------------------------------------------------------------------------------
        VNUMTRANSITEM_NOVO := GRAVAR_DADOS_PCMOVCOMPLE(DADOS.ID_REGISTRO,
                                                       DADOS.NUMTRANSITEM,
                                                       V_CSTIPI_ENTRADA,
                                                       DADOS.EXTIPI,
                                                       DADOS.SUBSTANCIA,
                                                       DADOS.LITRAGEM,
                                                       DADOS.REGIMEESPECIAL,
                                                       DADOS.ORIGMERCTRIB,
                                                       DADOS.CODCEST,
                                                       'N',
                                                       DADOS.CODMOTISENCAOANVISA,
                                                       DADOS.PERMITECREDITOPRESUMIDO,
                                                       VPERCMVAORIG_ENT);

         VNUMTRANSHISTORICO := GRAVAR_DADOS_PCMOVHISTORICO(DADOS.ID_REGISTRO,
                                                           DADOS.NUMTRANSHISTORICO,
                                                           DADOS.CESTABASICALEGIS,
                                                           'N');
        --------------------------------------------------------------------------------
        update PCMOV
           set PERICM                = DADOS.PERICM,
               ALIQICMSVIGENTE       = DADOS.ALIQVIGENTE,
               UNIDADE               = DADOS.UNIDADE,
               DESCRICAO             = DADOS.DESCRICAO,
               DESCRICAO1            = DADOS.DESCRICAO1,
               TIPOMERCDEPTO         = DADOS.TIPOMERCDEPTO,
               TIPOMERC              = DADOS.TIPOMERC,
               TIPOTRIBUTMEDIC       = DADOS.TIPOTRIBUTMEDIC,
               TIPOFORNEC            = DADOS.TIPOFORNEC,
               PASSELIVRE            = DADOS.PASSELIVRE,
               CODPASSEFISCAL        = DADOS.CODPASSEFISCAL,
               NBM                   = DADOS.NBM,
               DV                    = DADOS.DV,
               IVATRIBUT             = DADOS.IVA,
               CODPRODSINTEGRA       = DADOS.CODPRODSINTEGRA,
               CODGENEROFISCAL       = DADOS.CODGENEROFISCAL,
               CODFORNECPROD         = DADOS.CODFORNEC,
               IMPORTADO             = DADOS.IMPORTADO,
               EMBALAGEM             = DADOS.EMBALAGEM,
               CLASSIFICFISCAL       = DADOS.CLASSIFICFISCAL,
               CODAUXILIAR           = NVL(CODAUXILIAR,DADOS.CODAUXILIAR),
               CODECF                = NVL(CODECF, DADOS.CODECF),
               PESOLIQ               = DADOS.PESOLIQ,
               VOLUME                = DADOS.VOLUME,
               QTUNIT                = DADOS.QTUNIT,
               QTUNITCX              = DADOS.QTUNITCX,
               RUA                   = DADOS.RUA,
               UFFORNEC              = DADOS.ESTADO,
               IVARESSARC            = DADOS.IVARESSARC,
               ICMSRESSARC           = DADOS.ICMSRESSARC,
               ALIQAVULSADARE        = DADOS.ALIQAVULSADARE,
               PERCIVAICMANTECIP     = DADOS.PERCIVAICMANTECIP,
               PERCALIQINTICMANTECIP = DADOS.PERCALIQINTICMANTECIP,
               PERCALIQEXTICMANTECIP = DADOS.PERCALIQEXTICMANTECIP,
               TRIBFEDERAL           = DADOS.TRIBFEDERAL,
               VLPAUTAICMSANTEC      = DADOS.VLPAUTAICMSANTEC,
               CODPRODRELEV          = DADOS.CODPRODRELEV,
               CODSITTRIBPISCOFINS   = NVL(CODSITTRIBPISCOFINS, VCODSITTRIBPISCOFINS),
               CALCCREDIPI           = VCALCCREDIPI,
               VLBASEPISCOFINS       = NVL(VLBASEPISCOFINS, VVLBASEPISCOFINS),
               PISCOFINSRETIDO       = VPISCOFINSRETIDO,
               CODPRODDNF            = DADOS.CODPRODDNF,
               CAPVOLDNF             = DADOS.CAPVOLDNF,
               FATORCONVDNF          = DADOS.FATORCONVDNF,
               FUNDAPIANO            = DADOS.FUNDAPIANO,
               NUMTRANSITEM          = VNUMTRANSITEM_NOVO,
               NUMTRANSHISTORICO     = VNUMTRANSHISTORICO,
               HISTORICO             = 'S',
               CODINTERNO            = DADOS.CODINTERNO
         where rowid = DADOS.ID_REGISTRO;
      end if;
      --------------------------------------------------------------------------------
      VERIFICAR_SE_NECESSARIO_COMMIT();
    end loop;
  end;

/****************************************************************************/
procedure GERAR_INVENTARIO(PCODFILIAL in varchar2,
                           PDATA1     in date,
                           PDATA2     in date,
                           PCODPROD   in number) is

   VNUMREGIAOPADRAO NUMBER;
   VPARAMETRO       VARCHAR2(1);
   VCODFORNEC       PCFORNEC.CODFORNEC%TYPE;
   VCODEXCECAO      NUMBER;
   VEXISTETRIGGER  VARCHAR2(1);
   VALTERAR             VARCHAR2(30000);

   FUNCTION OBTERNUMREGIAOPADRAO(PCODFILIAL IN VARCHAR2) RETURN VARCHAR2 IS
   BEGIN
      /* BUSCANDO A FILIAL PADRÃO DO SISTEMA */
      /*IF (PARAMFILIAL.OBTERCOMONUMBER('FIL_NUMREGIAOPADRAO', PCODFILIAL) <> 0) THEN
         RETURN PARAMFILIAL.OBTERCOMONUMBER('FIL_NUMREGIAOPADRAO', PCODFILIAL);
      ELSE
         RETURN PARAMFILIAL.OBTERCOMONUMBER('FIL_NUMREGIAOPADRAO');
      END IF;*/
      IF (PARAMFILIAL.OBTERCOMONUMBER('FIL_NUMREGIAOPADRAO', PCODFILIAL) <> 0) THEN
         RETURN PARAMFILIAL.OBTERCOMONUMBER('FIL_NUMREGIAOPADRAO', PCODFILIAL);
      ELSE
         IF (NVL(PARAMFILIAL.OBTERCOMONUMBER('FIL_NUMREGIAOPADRAO',PCODFILIAL),0) = 0) THEN
           RAISE V_FALTAREGIAOPADRAO;
         ELSE
           RETURN PARAMFILIAL.OBTERCOMONUMBER('FIL_NUMREGIAOPADRAO');
         END IF;
      END IF;
   END;

  begin
    ----------------------------------------------------------------------------------
    -- GERAÇÃO DO HISTORICO PARA OS DADOS DO INVENTÁRIO
    ----------------------------------------------------------------------------------
    -- Desabilitando trigger TRG_LOG_PCHISTEST
    BEGIN
      SELECT 'S'
        INTO VEXISTETRIGGER
        FROM USER_TRIGGERS
       WHERE trigger_name = 'TRG_LOG_PCHISTEST';
    EXCEPTION
         WHEN OTHERS THEN
       VEXISTETRIGGER := 'N';
    END;

    If VEXISTETRIGGER = 'S' then
      VALTERAR := 'ALTER TRIGGER TRG_LOG_PCHISTEST DISABLE';
      EXECUTE IMMEDIATE VALTERAR;
      COMMIT;
    end if;

    BEGIN
      SELECT CODFORNEC
        INTO VCODFORNEC
        FROM PCFILIAL
       WHERE CODIGO = PCODFILIAL;
    EXCEPTION
         WHEN OTHERS THEN
       VCODFORNEC := 0;
    END;
   ------------------------------------------------------------------------

    VERRO := 'Erro ao gerar histórico do inventário';
    for DADOS in (
                  select H.rowid IDREGISTRO,
                         H.DATA,
                         P.CODPROD,
                         P.PERICM,
                         P.UNIDADE,
                         P.DESCRICAO,
                         P.NBM,
                         P.DV,
                         P.CODAUXILIAR,
                         P.CODPRODSINTEGRA,
                         P.EMBALAGEM,
                         P.DTEXCLUSAO,
                         P.CLASSIFICFISCAL,
                         P.CODGENEROFISCAL,
                         P.TIPOMERC,
                         D.TIPOMERC TIPOMERCDEPTO,
                         T.ALIQICMS1,
                         NVL(P.SITTRIBUT, '90') SITTRIBUT,
                         P.PERCST,
                         T.CODICM,
                         -- PISCOFINSRETIDO
                         DECODE(VUSAPISCOFINSPORFILIAL,
                                'N',
                                P.PISCOFINSRETIDO,
                                --PF.PISCOFINSRETIDO
                                (SELECT PISCOFINSRETIDO FROM PCPRODFILIAL where CODFILIAL = PCODFILIAL AND CODPROD = P.CODPROD)
                                ) PISCOFINSRETIDO,
                                
                         -- PERPIS       
                         DECODE(VUSAPISCOFINSPORFILIAL,
                                'N',
                                NVL(P.PERPIS, 0),
                                --NVL(PF.PERPIS, 0)
                                NVL((SELECT PERPIS FROM PCPRODFILIAL where CODFILIAL = PCODFILIAL AND CODPROD = P.CODPROD),0)
                                ) PERPIS,
                         -- PERCOFINS       
                         DECODE(VUSAPISCOFINSPORFILIAL,
                                'N',
                                NVL(P.PERCOFINS, 0),
                                --NVL(PF.PERCOFINS, 0)
                                NVL((SELECT PERCOFINS FROM PCPRODFILIAL where CODFILIAL = PCODFILIAL AND CODPROD = P.CODPROD),0)
                                ) PERCOFINS,
                         P.FUNDAPIANO,
                         P.CODINTERNO,
                         CAD_CEST.CODCEST,
                         -- Campos atuais para analise nomomento do update.
                         P.PERICM as PERICM_ATUAL,
                         NVL(P.SITTRIBUT, '90') SITTRIBUT_ATUAL,
                         DECODE(VUSAPISCOFINSPORFILIAL, 'N', P.PISCOFINSRETIDO,'') PISCOFINSRETIDO_ATUAL,
                         DECODE(VUSAPISCOFINSPORFILIAL, 'N', NVL(P.PERPIS,0),0) PERPIS_ATUAL,
                         DECODE(VUSAPISCOFINSPORFILIAL, 'N', NVL(P.PERCOFINS,0),0) PERCOFINS_ATUAL,
                         -- Populando Contador para evitar Update.
                        (DECODE(H.CODICM,T.CODICM,0,1) +
                         DECODE(H.UNIDADE,P.UNIDADE,0,1) +
                         DECODE(H.DESCRICAO,P.DESCRICAO,0,1) +
                         DECODE(H.NBM,P.NBM,0,1) +
                         DECODE(H.DV,P.DV,0,1) +
                         DECODE(H.CODAUXILIAR, NVL(H.CODAUXILIAR,P.CODAUXILIAR),0,1) +
                         DECODE(H.CODPRODSINTEGRA,P.CODPRODSINTEGRA,0,1) +
                         DECODE(H.EMBALAGEM,P.EMBALAGEM,0,1) +
                         DECODE(H.DTEXCLUSAOPROD,P.DTEXCLUSAO,0,1)+
                         DECODE(H.CLASSIFICFISCAL,P.CLASSIFICFISCAL,0,1) +
                         DECODE(H.CODGENEROFISCAL,P.CODGENEROFISCAL,0,1) +
                         DECODE(H.TIPOMERC,P.TIPOMERC,0,1) +
                         DECODE(H.TIPOMERCDEPTO, D.TIPOMERC,0,1) +
                         DECODE(H.ALIQICMSVIGENTE,T.ALIQICMS1,0,1) +
                         DECODE(H.PERCST,P.PERCST,0,1) +
                         DECODE(H.FUNDAPIANO,P.FUNDAPIANO,0,1) +
                         DECODE(H.CODINTERNO,P.CODINTERNO,0,1) +
                         DECODE(H.CODCEST,CAD_CEST.CODCEST,0,1)) AS CONTADOR
                    from PCHISTEST H,
                         PCCONSUM  CS,
                         PCPRODUT P,
                         PCDEPTO D,
                         --- TABELA T
                         (select P.CODPROD,
                                 T.ALIQICMS1,
                                 T.CODICM,
                                 T.SITTRIBUT
                            from PCTABPR P, PCTRIBUT T, PCFILIAL F
                           where P.CODST = T.CODST
                             and F.CODIGO = PCODFILIAL
                             and P.NUMREGIAO = F.NUMREGIAOPADRAO) T,
                             
/*                        (select TR.CODPROD,
                                 T.ALIQICMS1,
                                 T.CODICM,
                                 T.SITTRIBUT
                            from PCTABTRIB TR, PCTRIBUT T, PCFILIAL F
                           where TR.CODST = T.CODST
                             and F.CODIGO = PCODFILIAL
                             and TR.CODFILIALNF = F.CODIGO
                            and TR.UFDESTINO = F.UF) TR,*/
                            
/*                         --- TABELA PF   
                         (select CODPROD, PISCOFINSRETIDO, PERPIS, PERCOFINS
                            from PCPRODFILIAL
                           where CODFILIAL = PCODFILIAL) PF,*/
                           
                         --- TABELA CAD_CEST   
                         (SELECT C.CODCEST,
                                 V.CODPROD
                              FROM PCCESTPRODUTO V,
                                   PCCEST C
                             WHERE TO_NUMBER(V.CODPROD) BETWEEN DECODE(NVL(PCODPROD,0),0,0,PCODPROD) AND
                                                                DECODE(NVL(PCODPROD,0),0,9999999999,PCODPROD)
                               AND V.CODSEQCEST = C.CODIGO
                               AND V.TIPOPROD = 'N') CAD_CEST
                               
                   where H.CODFILIAL = PCODFILIAL
                     and H.DATA between PDATA1 and PDATA2
                     and P.CODPROD = H.CODPROD
--                     and (NVL(PCODPROD, 0) = 0 or P.CODPROD = PCODPROD)
                     AND P.CODPROD BETWEEN DECODE(NVL(PCODPROD,0),0,0,PCODPROD) AND
                                           DECODE(NVL(PCODPROD,0),0,9999999999,PCODPROD)
                     and D.CODEPTO(+) = P.CODEPTO
                     and P.CODPROD = T.CODPROD(+)
                     --and P.CODPROD = TR.CODPROD(+)
                     --and P.CODPROD = PF.CODPROD(+)
                     AND P.CODPROD = CAD_CEST.CODPROD (+)
                     and (NVL(VREPROCESSAR, 'N') = 'S' or
                         NVL(H.HISTORICO, 'N') = 'N'))
    loop
     --PEGO OS PARAMETROS UMA UNICA VEZ
     VPARAMETRO       := PARAMFILIAL.OBTERCOMOVARCHAR2('CON_USATRIBENTPORUF');
     VNUMREGIAOPADRAO := OBTERNUMREGIAOPADRAO(PCODFILIAL);
     VCODEXCECAO := 0;

     ------TRIBUTACAO_ESTADO------------------------------------------------------------------------------------------------
     IF (VPARAMETRO = 'S') THEN
     begin
        SELECT PCTABTRIBENT.CODEXCECAOPISCOFINS,
               NVL(PCTABTRIBENT.PERPIS, NVL(PCPRODUT.PERPIS, 0)) AS PERPIS,
               NVL(PCTABTRIBENT.PERCOFINS, NVL(PCPRODUT.PERCOFINS, 0)) AS PERCOFINS,
               NVL(PCTABTRIBENT.PERCICM, 0) PERICM,
               NVL(PCTABTRIBENT.PISCOFINSRETIDO, NVL(PCPRODUT.PISCOFINSRETIDO, 0)) PISCOFINSRETIDO,
               NVL(PCTABTRIBENT.SITTRIBUT, '90') AS SITTRIBUT
          INTO VCODEXCECAO,
               DADOS.PERPIS,
               DADOS.PERCOFINS,
               DADOS.PERICM,
               DADOS.PISCOFINSRETIDO,
               DADOS.SITTRIBUT
          FROM PCTABTRIBENT
             , PCPRODUT
             , PCFILIAL
             , PCPRODFILIAL
             , PCFORNEC
             , PCEST
             , PCTABPR
         WHERE PCTABTRIBENT.CODPROD   = PCPRODUT.CODPROD
           AND PCTABTRIBENT.UFORIGEM  = PCFORNEC.ESTADO
           AND PCTABTRIBENT.UFDESTINO = PCFILIAL.UF
           AND PCTABTRIBENT.CODPROD   = PCPRODUT.CODPROD
           AND PCEST.CODPROD          = PCPRODUT.CODPROD
           AND PCEST.CODPROD          = PCTABPR.CODPROD
           AND PCTABPR.NUMREGIAO      = VNUMREGIAOPADRAO
           AND PCEST.CODPROD          = PCPRODFILIAL.CODPROD
           AND PCEST.CODFILIAL        = PCPRODFILIAL.CODFILIAL
           AND PCFORNEC.CODFORNEC     = VCODFORNEC
           AND PCFILIAL.CODIGO        = PCEST.CODFILIAL
           AND PCEST.CODPROD          = DADOS.CODPROD
           AND PCEST.CODFILIAL        = PCODFILIAL;
     EXCEPTION
          WHEN OTHERS THEN
        VCODEXCECAO := 0;
       END;

     if VCODEXCECAO > 0 then
     begin

        SELECT  NVL(I.PERPIS,0),
                NVL(I.PERCOFINS,0)
           INTO DADOS.PERPIS,
           DADOS.PERCOFINS
          FROM PCEXPISCOFINSITEM I
         WHERE I.CODEXCECAO = VCODEXCECAO
           AND I.TIPOMOVIMENTACAO IN ('1E','4E','1D')
           AND I.CODSITTRIBPISCOFINS = 50
           AND NVL(I.PERPIS, 0) > 0
           AND NVL(I.PERCOFINS, 0) > 0
           AND ROWNUM = 1;

      EXCEPTION
              WHEN OTHERS THEN
          NULL;
          END;
     end if;


     -----------------------------------------------------------------------------------------------------------------------
     ELSIF (VPARAMETRO = 'F') THEN
     ------TRIBUTACAO_FIGURA_X_NCM------------------------------------------------------------------------------------------

     BEGIN -- verificando exceção
      SELECT TRIBUTACAO.CODEXCECAOPISCOFINS,
             NVL(FIGURA_PELO_PRODFILIAL.PERPIS, NVL(PCTRIBFIGURA.PERPIS, NVL(PCPRODUT.PERPIS, 0))) AS PERPIS,
             NVL(FIGURA_PELO_PRODFILIAL.PERCOFINS, NVL(PCTRIBFIGURA.PERCOFINS, NVL(PCPRODUT.PERCOFINS, 0))) AS PERCOFINS,
             NVL(NVL(FIGURA_PELO_PRODFILIAL.PERCICM ,PCTRIBFIGURA.PERCICM), 0) PERICM,
             NVL(FIGURA_PELO_PRODFILIAL.PISCOFINSRETIDO, NVL(PCTRIBFIGURA.PISCOFINSRETIDO, 0)) PISCOFINSRETIDO,
             NVL(FIGURA_PELO_PRODFILIAL.SITTRIBUT,  NVL(PCTRIBFIGURA.SITTRIBUT, '90')) SITTRIBUT
        INTO VCODEXCECAO,
             DADOS.PERPIS,
             DADOS.PERCOFINS,
             DADOS.PERICM,
             DADOS.PISCOFINSRETIDO,
             DADOS.SITTRIBUT
        FROM PCTRIBFIGURA
           , PCTRIBFIGURA FIGURA_PELO_PRODFILIAL
           , PCTRIBENTRADA TRIBUTACAO
           , PCPRODUT
           , PCPRODFILIAL
           , PCFORNEC
           , PCEST
           , PCTABPR
       WHERE TRIBUTACAO.CODFIGURA  = PCTRIBFIGURA.CODFIGURA
         AND ((TRIBUTACAO.NCM = PCPRODUT.CODNCMEX) OR (TRIBUTACAO.NCM = PCPRODUT.NBM))
         AND TRIBUTACAO.CODFILIAL      = PCEST.CODFILIAL
         AND TRIBUTACAO.UFORIGEM       = PCFORNEC.ESTADO
         AND TRIBUTACAO.TIPOFORNEC     = PCFORNEC.TIPOFORNEC
         AND PCEST.CODPROD             = PCTABPR.CODPROD
         AND PCTABPR.NUMREGIAO         = VNUMREGIAOPADRAO
         AND PCFORNEC.CODFORNEC        = VCODFORNEC
         AND PCPRODUT.CODPROD          = PCEST.CODPROD
         AND PCPRODFILIAL.CODPROD      = PCPRODUT.CODPROD
         AND PCPRODFILIAL.CODFILIAL    = TRIBUTACAO.CODFILIAL
         AND PCPRODFILIAL.CODFIGURA    = FIGURA_PELO_PRODFILIAL.CODFIGURA(+)
         AND PCPRODUT.NBM              IS NOT NULL
         AND PCEST.CODPROD             = DADOS.CODPROD
         AND PCEST.CODFILIAL           = PCODFILIAL;
     EXCEPTION
        WHEN OTHERS THEN
     NULL;
     END;

     if VCODEXCECAO > 0 then
        BEGIN
        SELECT  NVL(I.PERPIS,0),
                NVL(I.PERCOFINS,0)
           INTO DADOS.PERPIS,
                DADOS.PERCOFINS
          FROM PCEXPISCOFINSITEM I
         WHERE I.CODEXCECAO = VCODEXCECAO
           AND I.TIPOMOVIMENTACAO IN ('1E','4E','1D')
           AND I.CODSITTRIBPISCOFINS = 50
           AND NVL(I.PERPIS, 0) > 0
           AND NVL(I.PERCOFINS, 0) > 0
           AND ROWNUM = 1;
          EXCEPTION
              WHEN OTHERS THEN
          NULL;
          END;
     end if;

     ------------------------------------------------------------------------------------------------------------------------
     ELSIF (VPARAMETRO = 'P') THEN
     ------TRIBUTACAO_FIGURA_X_PRODUTO---------------------------------------------------------------------------------------

     BEGIN -- CONSULTANDO EXCEÇÃO
      SELECT TRIBUTACAO.CODEXCECAOPISCOFINS,
             NVL(FIGURA_PELO_PRODFILIAL.PERPIS, NVL(PCTRIBFIGURA.PERPIS, NVL(PCPRODUT.PERPIS, 0))) AS PERPIS,
             NVL(FIGURA_PELO_PRODFILIAL.PERCOFINS, NVL(PCTRIBFIGURA.PERCOFINS, NVL(PCPRODUT.PERCOFINS, 0))) AS PERCOFINS,
             NVL(NVL(FIGURA_PELO_PRODFILIAL.PERCICM ,PCTRIBFIGURA.PERCICM), 0) PERICM,
             NVL(FIGURA_PELO_PRODFILIAL.PISCOFINSRETIDO, NVL(PCTRIBFIGURA.PISCOFINSRETIDO, 0)) PISCOFINSRETIDO,
             NVL(FIGURA_PELO_PRODFILIAL.SITTRIBUT, NVL(PCTRIBFIGURA.SITTRIBUT, '90')) AS SITTRIBUT
        INTO VCODEXCECAO,
             DADOS.PERPIS,
             DADOS.PERCOFINS,
             DADOS.PERICM,
             DADOS.PISCOFINSRETIDO,
             DADOS.SITTRIBUT
        FROM PCTRIBFIGURA
           , PCTRIBFIGURA FIGURA_PELO_PRODFILIAL
           , PCTRIBENTPROD TRIBUTACAO
           , PCPRODUT
           , PCPRODFILIAL
           , PCFORNEC
           , PCEST
           , PCTABPR
       WHERE TRIBUTACAO.CODFIGURA  = PCTRIBFIGURA.CODFIGURA
         AND TRIBUTACAO.CODPROD    = PCPRODUT.CODPROD
         AND TRIBUTACAO.CODFILIAL  = PCEST.CODFILIAL
         AND TRIBUTACAO.UFORIGEM   = PCFORNEC.ESTADO
         AND TRIBUTACAO.TIPOFORNEC = PCFORNEC.TIPOFORNEC
         AND PCEST.CODPROD             = PCTABPR.CODPROD
         AND PCTABPR.NUMREGIAO         = VNUMREGIAOPADRAO
         AND PCFORNEC.CODFORNEC        = VCODFORNEC
         AND PCPRODUT.CODPROD          = PCEST.CODPROD
         AND PCPRODFILIAL.CODPROD      = PCPRODUT.CODPROD
         AND PCPRODFILIAL.CODFILIAL    = TRIBUTACAO.CODFILIAL
         AND PCPRODFILIAL.CODFIGURA    = FIGURA_PELO_PRODFILIAL.CODFIGURA(+)
         AND PCEST.CODPROD   = DADOS.CODPROD
         AND PCEST.CODFILIAL = PCODFILIAL ;
     EXCEPTION
          WHEN OTHERS THEN
        VCODEXCECAO := 0;
       END;

     if VCODEXCECAO > 0 then
        BEGIN
        SELECT  NVL(I.PERPIS,0),
                NVL(I.PERCOFINS,0)
           INTO DADOS.PERPIS,
           DADOS.PERCOFINS
          FROM PCEXPISCOFINSITEM I
         WHERE I.CODEXCECAO = VCODEXCECAO
           AND I.TIPOMOVIMENTACAO IN ('1E','4E','1D')
           AND I.CODSITTRIBPISCOFINS = 50
           AND NVL(I.PERPIS, 0) > 0
           AND NVL(I.PERCOFINS, 0) > 0
           AND ROWNUM = 1;

        EXCEPTION
                WHEN OTHERS THEN
            NULL;
            END;
      end if;

     ------------------------------------------------------------------------------------------------------------------------
     END IF;

     -- Verificando se houve alteracao nos campos de tributação. Se sim, inserir contador.
     if ((DADOS.PERPIS_ATUAL    <> DADOS.PERPIS) or
         (DADOS.PERCOFINS_ATUAL <> DADOS.PERCOFINS) or
         (DADOS.PERICM_ATUAL    <> DADOS.PERICM) or
         (DADOS.PISCOFINSRETIDO_ATUAL <> DADOS.PISCOFINSRETIDO) or
         (DADOS.SITTRIBUT_ATUAL       <> DADOS.SITTRIBUT)) then
        DADOS.CONTADOR := DADOS.CONTADOR + 1;
       end if;

    if DADOS.CONTADOR > 0 then
      update PCHISTEST
         set PERICM          = DADOS.PERICM,
             CODICM          = DADOS.CODICM,
             UNIDADE         = DADOS.UNIDADE,
             DESCRICAO       = DADOS.DESCRICAO,
             NBM             = DADOS.NBM,
             DV              = DADOS.DV,
             CODAUXILIAR     = NVL(CODAUXILIAR,DADOS.CODAUXILIAR),
             CODPRODSINTEGRA = DADOS.CODPRODSINTEGRA,
             EMBALAGEM       = DADOS.EMBALAGEM,
             DTEXCLUSAOPROD  = DADOS.DTEXCLUSAO,
             CLASSIFICFISCAL = DADOS.CLASSIFICFISCAL,
             CODGENEROFISCAL = DADOS.CODGENEROFISCAL,
             TIPOMERC        = DADOS.TIPOMERC,
             TIPOMERCDEPTO   = DADOS.TIPOMERCDEPTO,
             ALIQICMSVIGENTE = DADOS.ALIQICMS1,
             SITTRIBUT       = DADOS.SITTRIBUT,
             PERCST          = DADOS.PERCST,
             PISCOFINSRETIDO = DADOS.PISCOFINSRETIDO,
             PERPIS          = DADOS.PERPIS,
             PERCOFINS       = DADOS.PERCOFINS,
             FUNDAPIANO      = DADOS.FUNDAPIANO,
             HISTORICO       = 'S',
             CODINTERNO      = DADOS.CODINTERNO,
             CODCEST         = DADOS.CODCEST
       where rowid = DADOS.IDREGISTRO;
      end if;
      -----------------------------------------------------------
      VERIFICAR_SE_NECESSARIO_COMMIT();

    end loop;

    If VEXISTETRIGGER = 'S' then
      VALTERAR := 'ALTER TRIGGER TRG_LOG_PCHISTEST ENABLE';
      EXECUTE IMMEDIATE VALTERAR;
      COMMIT;
    end if; 

  end;
/****************************************************************************/

  procedure GERAR_LOG(PCODFILIAL   in varchar2,
                      PDATA1       in date,
                      PDATA2       in date,
                      PCODPROD     in number,
                      PREPROCESSAR in varchar2) is
  begin
    insert into PCLOGHISTORICOMOV
      (CODLOG,
       CODFILIAL,
       DTINICIO,
       DTFIM,
       CODPROD,
       SOMENTENAOGERADOS,
       DATAGERACAO,
       TERMINAL,
       OS_USUARIO)
    values
      (DFSEQ_PCLOGHISTORICOMOV.nextval,
       PCODFILIAL,
       PDATA1,
       PDATA2,
       PCODPROD,
       DECODE(PREPROCESSAR, 'S', 'N', 'S'),
       sysdate,
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'OS_USER'));
  end;

  /****************************************************************************/
  procedure GERA_HISTORICO(PCODFILIAL     in varchar2,
                           PDTINICIAL     in date,
                           PDTFINAL       in date,
                           PTRANSACAO     in number,
                           PTIPOMOV       in varchar2,
                           PCODCLI_FORNEC in number,
                           PREPROCESSAR   in varchar2,
                           MSG            out varchar2) is
  begin
    VREPROCESSAR := PREPROCESSAR;
    ----------------------------------------------------------------------------------
    -- BUSCAR PARAMETROS GERAIS
    ----------------------------------------------------------------------------------
    select TIPOALIQOUTRASDESP,
           PERCICMFRETEENT,
           PERCICMINTERFRETEENT,
           CODFISCALFRETEENT,
           CODFISCALINTERFRETEENT,
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
           CODCONTCLI,
           CODCONTFOR,
           CODCONTFRE,
           USATRIBENTPORUF
      into VTIPOALIQOUTRASDESP,
           VPERCICMFRETEENT,
           VPERCICMINTERFRETEENT,
           VCODFISCALFRETEENT,
           VCODFISCALINTERFRETEENT,
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
           VCODCONTCLI,
           VCODCONTFOR,
           VCODCONTFRE,
           VUSATRIBENTPORUF
      from PCCONSUM;
    ----------------------------------------------------------------------------------
    -- BUSCAR PARAMETROS POR FILIAL
    ----------------------------------------------------------------------------------
    select UF into VUFFILIAL from PCFILIAL where CODIGO = PCODFILIAL;

    ----------------------------------------------------------------------------------
    -- BUSCAR PARAMETROS DE TRIBUTAÇÃO DE PIS/COFINS POR FILIAL
    ----------------------------------------------------------------------------------
    select DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('USAPISCOFINSPORFILIAL',
                                                    PCODFILIAL),
                      'S'),
                  'S',
                  (select NVL(USAPISCOFINSPORFILIAL, 'N') from PCCONSUM),
                  'N')
      into VUSAPISCOFINSPORFILIAL
      from DUAL;

    ----------------------------------------------------------------------------------
    if VTIPOALIQOUTRASDESP = 'F'
    then
      select ALIQICMOUTRASDESP,
             ALIQICMINTEROUTRASDESP,
             CODFISCALOUTRASDESP,
             CODFISCALINTEROUTRASDESP
        into VALIQICMOUTRASDESP,
             VALIQICMINTEROUTRASDESP,
             VCODFISCALOUTRASDESP,
             VCODFISCALINTEROUTRASDESP
        from PCFILIAL
       where CODIGO = PCODFILIAL;
    end if;
    -------------------------------------------------------
    VULTIMA_TRANSACAO := -1;
    -------------------------------------------------------
    -- verificar se houve filtragem de produtos
    select count(1) into VCONT_PRODUTOS from PCLISTAPROD_TMP;
    -------------------------------------------------------
    ----------------------------------------------------------------------------------
    -- BUSCAR PARAMETROS DE TRIBUTAÇÃO ICMS BCR NFE POR FILIAL
    ----------------------------------------------------------------------------------
    select DECODE(NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('GERARBCRNFE', PCODFILIAL), 'S'),
                                                    'S', 'S',  'N')
      into V_GERARBCRNFE
      from DUAL;
    ----------------------------------------------------------------------------------
    if PTRANSACAO > 0
    then
      GERAR_MOVIMENTACAO(PCODFILIAL,
                         PDTINICIAL,
                         PDTFINAL,
                         PTRANSACAO,
                         PTIPOMOV,
                         0);
      --Removido para geração do livro
      --FISCAL.GERA_CONTAS_CONTABEIS_SPED(PCODFILIAL, PDTINICIAL, PDTFINAL, PTRANSACAO, PTIPOMOV);

      if PTIPOMOV = 'E'
      then
        GERAR_CAB_ENTRADAS(PCODFILIAL,
                           PDTINICIAL,
                           PDTFINAL,
                           PTRANSACAO,
                           0,
                           'T');
      else
        GERAR_CAB_SAIDAS(PCODFILIAL, PDTINICIAL, PDTFINAL, PTRANSACAO, 0);
      end if;
      GERAR_LOG(PCODFILIAL, PDTINICIAL, PDTFINAL, 0, PREPROCESSAR);
    elsif PCODCLI_FORNEC > 0
    then
      if PTIPOMOV = 'E'
      then
        GERAR_CAB_ENTRADAS(PCODFILIAL,
                           PDTINICIAL,
                           PDTFINAL,
                           0,
                           PCODCLI_FORNEC,
                           'N');
      else
        GERAR_CAB_ENTRADAS(PCODFILIAL,
                           PDTINICIAL,
                           PDTFINAL,
                           0,
                           PCODCLI_FORNEC,
                           'D');
        GERAR_CAB_SAIDAS(PCODFILIAL,
                         PDTINICIAL,
                         PDTFINAL,
                         0,
                         PCODCLI_FORNEC);
      end if;
      GERAR_LOG(PCODFILIAL, PDTINICIAL, PDTFINAL, 0, PREPROCESSAR);
    elsif VCONT_PRODUTOS > 0
    then
      for DADOS in (select CODPROD from PCLISTAPROD_TMP)
      loop
        GERAR_MOVIMENTACAO(PCODFILIAL,
                           PDTINICIAL,
                           PDTFINAL,
                           0,
                           'T',
                           DADOS.CODPROD);
      BEGIN
        GERAR_INVENTARIO(PCODFILIAL, PDTINICIAL, PDTFINAL, DADOS.CODPROD);
         EXCEPTION
         WHEN V_FALTAREGIAOPADRAO THEN
           MSG := 'FALTA REGIAO PADRAO PARA A FILIAL '||TO_CHAR(PCODFILIAL)||', FAVOR INFORMAR O PARAMETRO FIL_NUMREGIAOPADRAO';
           RETURN;
      END;
        GERAR_LOG(PCODFILIAL,
                  PDTINICIAL,
                  PDTFINAL,
                  DADOS.CODPROD,
                  PREPROCESSAR);
      end loop;
    else

     BEGIN
      GERAR_INVENTARIO(PCODFILIAL, PDTINICIAL, PDTFINAL, 0);
     EXCEPTION
         WHEN V_FALTAREGIAOPADRAO THEN
          MSG := 'FALTA REGIAO PADRAO PARA A FILIAL '||TO_CHAR(PCODFILIAL)||', FAVOR INFORMAR O PARAMETRO FIL_NUMREGIAOPADRAO';
          RETURN;
     END;

      GERAR_CAB_ENTRADAS(PCODFILIAL, PDTINICIAL, PDTFINAL, 0, 0, 'T');
      GERAR_CAB_SAIDAS(PCODFILIAL, PDTINICIAL, PDTFINAL, 0, 0);
      GERAR_MOVIMENTACAO(PCODFILIAL, PDTINICIAL, PDTFINAL, 0, 'T', 0);
      GERAR_LOG(PCODFILIAL, PDTINICIAL, PDTFINAL, 0, PREPROCESSAR);
      --Removido para geração do livro
      --FISCAL.GERA_CONTAS_CONTABEIS_SPED(PCODFILIAL, PDTINICIAL, PDTFINAL, 0, 'T');
    end if;
    -------------------------------------------------------
    MSG := 'OK';
    commit;
  exception
    when others then
      begin
        rollback;
       MSG := 'ERRO AO GERAR HISTORICO: ' || CHR(13) || VERRO || CHR(13) ||
               'Núm.Nota: ' || TO_CHAR(NVL(VNUMNOTA, 0)) || CHR(13) ||
               sqlerrm;
      end;
  end;

  procedure GERA_DESCRICAO_PROD_NFE(PCODFILIAL     in varchar2,
                                    PDTINICIAL     in date,
                                    PDTFINAL       in date,
                                    PTRANSACAO     in number,
                                    PTIPOMOV       in varchar2) is
  begin
    ----------------------------------------------------------------------------------
    /* GERAÇÃO DESCRICAO DO PRODUTO CONFORME EMITIDO NA NFE  */
    ----------------------------------------------------------------------------------
    VERRO := 'Erro ao gerar histórico de entradas';

    for DADOS in (/* NOTAS PREFAT */
                  SELECT 'S' TIPO,
                         NFSP.NUMTRANSVENDA NUMTRANSACAO,
                         'S' PREFAT
                    FROM PCNFSAIDPREFAT NFSP
                   WHERE NVL(NFSP.CODFILIALNF, NFSP.CODFILIAL) = PCODFILIAL
                     AND NFSP.DTSAIDA BETWEEN PDTINICIAL AND PDTFINAL
                     AND NFSP.DTCANCEL IS NULL
                     AND (NVL(PTRANSACAO, 0) = 0 OR NFSP.NUMTRANSVENDA = PTRANSACAO)
                     AND NVL(PTIPOMOV, '') IN ('S', 'A')

                  UNION
                  /* NOTAS EMITIDAS */
                  SELECT B.TIPO,
                         B.NUMTRANSACAO,
                         'N' PREFAT
                    FROM (SELECT 'E' TIPO,
                                 NFE.NUMTRANSENT NUMTRANSACAO
                            FROM PCNFENT NFE
                           WHERE NVL(NFE.CODFILIALNF, NFE.CODFILIAL) = PCODFILIAL
                             AND NFE.DTENT BETWEEN PDTINICIAL AND PDTFINAL
                             AND NFE.DTCANCEL IS NULL
                             AND (NVL(PTRANSACAO, 0) = 0 OR NFE.NUMTRANSENT = PTRANSACAO)
                             AND NVL(PTIPOMOV, '') IN ('E', 'A')
                          UNION
                          SELECT 'S' TIPO,
                                 NFS.NUMTRANSVENDA NUMTRANSACAO
                            FROM PCNFSAID NFS
                           WHERE NVL(NFS.CODFILIALNF, NFS.CODFILIAL) = PCODFILIAL
                             AND NFS.DTSAIDA BETWEEN PDTINICIAL AND PDTFINAL
                             AND NFS.DTCANCEL IS NULL
                             AND (NVL(PTRANSACAO, 0) = 0 OR NFS.NUMTRANSVENDA = PTRANSACAO)
                             AND NVL(PTIPOMOV, '') IN ('S', 'A')) B)
    LOOP
      IF (DADOS.TIPO IN ('E', 'A')) THEN /* PARTE DAS ENTRADAS. */
        FOR PROD IN (SELECT PCMOV.NUMTRANSITEM,
                            (NVL(PCMOV.PRODDESCRICAOCONTRATO,
                                 NVL(PCMOV.DESCRICAO, PCMOV.COMPLEMENTO)) || ' ' ||
                                 DECODE(NVL(PCFILIAL.USADADOSEMBALAGEMNFE, 'N'),
                                        'S',
                                        DECODE(NVL(PCFILIAL.UTILIZAVENDAPOREMBALAGEM, 'N'),
                                               'N',
                                               PCMOV.EMBALAGEM,
                                               ('QTD. ' ||
                                               (PCMOV.QTCONT /
                                               DECODE(NVL(PCEMBALAGEM.QTUNIT, 0),
                                                      0,
                                                      1,
                                                      PCEMBALAGEM.QTUNIT)) || ' ' ||
                                               PCEMBALAGEM.UNIDADE || '')))) AS PRODUTO

                      FROM PCMOV,
                           PCFILIAL,
                           PCEMBALAGEM
                     WHERE PCMOV.NUMTRANSENT                       = DADOS.NUMTRANSACAO
                       AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCFILIAL.CODIGO
                       AND PCMOV.CODAUXILIAR                       = PCEMBALAGEM.CODAUXILIAR(+)
                       AND PCMOV.CODPROD                           = PCEMBALAGEM.CODPROD(+)
                       AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCEMBALAGEM.CODFILIAL(+))

        LOOP
          UPDATE PCMOVCOMPLE
             SET DESCRICAONFE = SUBSTR(PROD.PRODUTO, 1, 120)
           WHERE NUMTRANSITEM = PROD.NUMTRANSITEM;
          COMMIT;
        END LOOP;
      END IF;

      IF (DADOS.TIPO IN ('S', 'A')) THEN
        -- NOTAS PREFAT
        IF (DADOS.PREFAT = 'S') THEN
          FOR PROD IN (SELECT PCMOVPREFAT.NUMTRANSITEM,
                              (NVL(PCMOVPREFAT.PRODDESCRICAOCONTRATO, NVL(PCMOVPREFAT.COMPLEMENTO, PCMOVPREFAT.DESCRICAO)) || ' ' ||
                               CASE
                                 WHEN LENGTH(PCPRODUT.SUBSTANCIA) > 0 THEN
                                   '('||PCPRODUT.SUBSTANCIA||')'
                                 ELSE ''
                               END || DECODE(NVL(PCFILIAL.USADADOSEMBALAGEMNFE, 'N'),
                                             'S',
                                             DECODE(NVL(PCFILIAL.UTILIZAVENDAPOREMBALAGEM, 'N'),
                                                    'N',
                                                    PCMOVPREFAT.EMBALAGEM,
                                                    (PCEMBALAGEM.EMBALAGEM || ' QTD. ' ||
                                                     LTRIM(TO_CHAR((PCMOVPREFAT.QTCONT /
                                                     DECODE(NVL(PCEMBALAGEM.QTUNIT, 0),
                                                            0,
                                                            1,
                                                            PCEMBALAGEM.QTUNIT)),'999999999999999990.99')) || ' ' ||
                                                     PCEMBALAGEM.UNIDADE || ' ')))) AS PRODUTO

                       FROM PCMOVPREFAT,
                            PCPRODUT,
                            PCFILIAL,
                            PCEMBALAGEM
                       WHERE PCMOVPREFAT.NUMTRANSVENDA                           = DADOS.NUMTRANSACAO
                         AND PCMOVPREFAT.CODPROD                                 = PCPRODUT.CODPROD
                         AND NVL(PCMOVPREFAT.CODFILIALNF, PCMOVPREFAT.CODFILIAL) = PCFILIAL.CODIGO
                         AND PCMOVPREFAT.CODAUXILIAR                             = PCEMBALAGEM.CODAUXILIAR(+)
                         AND PCMOVPREFAT.CODPROD                                 = PCEMBALAGEM.CODPROD(+)
                         AND NVL(PCMOVPREFAT.CODFILIALNF, PCMOVPREFAT.CODFILIAL) = PCEMBALAGEM.CODFILIAL(+))
          LOOP
            UPDATE PCMOVCOMPLEPREFAT
               SET DESCRICAONFE = SUBSTR(PROD.PRODUTO, 1, 120)
             WHERE NUMTRANSITEM = PROD.NUMTRANSITEM;
            COMMIT;
          END LOOP;
        ELSE
          FOR PROD IN (SELECT PCMOV.NUMTRANSITEM,
                              (NVL(PCMOV.PRODDESCRICAOCONTRATO, NVL(PCMOV.COMPLEMENTO, PCMOV.DESCRICAO)) || ' ' ||
                               CASE
                                 WHEN LENGTH(PCPRODUT.SUBSTANCIA) > 0 THEN
                                   '('||PCPRODUT.SUBSTANCIA||')'
                                 ELSE ''
                               END || DECODE(NVL(PCFILIAL.USADADOSEMBALAGEMNFE, 'N'),
                                             'S',
                                             DECODE(NVL(PCMOVCOMPLE.USAUNIDADEMASTER, 'N'),
                                                    'S',
                                                    PCPRODUT.EMBALAGEMMASTER,
                                                    DECODE(NVL(PCFILIAL.UTILIZAVENDAPOREMBALAGEM, 'N'),
                                                           'N',
                                                           PCMOV.EMBALAGEM,
                                                           (PCEMBALAGEM.EMBALAGEM || ' QTD. ' || LTRIM(TO_CHAR((PCMOV.QTCONT /
                                                            DECODE(NVL(PCEMBALAGEM.QTUNIT, 0),
                                                                   0,
                                                                   1,
                                                                   PCEMBALAGEM.QTUNIT)),
                                                            '999999999999999990.99')) || ' ' ||
                                                            PCEMBALAGEM.UNIDADE || ' '))))) AS PRODUTO

                       FROM PCMOV,
                            PCPRODUT,
                            PCFILIAL,
                            PCMOVCOMPLE,
                            PCEMBALAGEM
                       WHERE PCMOV.NUMTRANSVENDA                     = DADOS.NUMTRANSACAO
                         AND PCMOV.CODPROD                           = PCPRODUT.CODPROD
                         AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCFILIAL.CODIGO
                         AND PCMOV.NUMTRANSITEM                      = PCMOVCOMPLE.NUMTRANSITEM(+)
                         AND PCMOV.CODAUXILIAR                       = PCEMBALAGEM.CODAUXILIAR(+)
                         AND PCMOV.CODPROD                           = PCEMBALAGEM.CODPROD(+)
                         AND NVL(PCMOV.CODFILIALNF, PCMOV.CODFILIAL) = PCEMBALAGEM.CODFILIAL(+))
          LOOP
            UPDATE PCMOVCOMPLE
               SET DESCRICAONFE = SUBSTR(PROD.PRODUTO, 1, 120)
             WHERE NUMTRANSITEM = PROD.NUMTRANSITEM;
            COMMIT;
          END LOOP;
        END IF;
      END IF;
    END LOOP;
  end;

end GERA_HISTORICO;
-- 24/11/2022 - Gleibe - Implementado ajuste de performance.
-- 24/11/2022 - Gleibe - inicio do processo de implementado de parametros de atualização do historico
