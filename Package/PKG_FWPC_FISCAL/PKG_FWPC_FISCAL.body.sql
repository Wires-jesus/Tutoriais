create or replace package body PKG_FWPC_FISCAL is

   V_VALORPRODUTO_ACRESCIDO NUMBER;

     CURSOR CONSULTA_DADOS_PARTILHA(P_NUMTRANSACAO  NUMBER,
                                    P_TIPOMOV VARCHAR2 ) IS
                     (SELECT NVL(N.CODFILIALNF, N.CODFILIAL) CODFILIAL,
                             NVL(N.CONSUMIDORFINAL,'N') CONSUMIDORFINAL,
                             NVL(N.CONTRIBUINTE,'N') CONTRIBUINTE,
                             CASE
                               WHEN NVL(N.CODCLINF, N.CODCLI) IN (1, 2, 3) THEN
                                0
                               ELSE
                                NVL(N.CODCLINF, N.CODCLI)
                             END AS CODCLI,
                             N.UF,
                             UPPER(NVL(ENT.ESTENT, CIDADE_ENT.UF)) AS UFENTREGA,
                             N.DTSAIDA as DATAOPER,
                             M.CODPROD,
                             NVL(M.PUNITCONT, 0)  - NVL(MC.VLFECP, 0) -
                             NVL(M.ST, 0)  +  (CASE
                                               WHEN PARAMFILIAL.OBTERCOMOVARCHAR2('RECALCICMSPARTFATURAMENTO',
                                                                                  NVL(N.CODFILIALNF, N.CODFILIAL)) = 'S' THEN
                                                NVL(M.VLFRETE, 0)
                                               ELSE
                                                0
                                             END) + NVL(M.VLOUTROS, 0) as VLPRODUTO,
                             DECODE(NVL(M.CODST, 0),
                                    0,
                                    case
                                      when PARAMFILIAL.OBTERCOMOVARCHAR2('CON_USATRIBUTACAOPORUF') = 'S' then
                                       (select PCTABTRIB.CODST
                                          from PCTABTRIB
                                         where PCTABTRIB.CODPROD = M.CODPROD
                                           and PCTABTRIB.CODFILIALNF = NVL(N.CODFILIALNF, N.CODFILIAL)
                                           and PCTABTRIB.UFDESTINO = N.UF
                                           and ROWNUM = 1)
                                      else
                                       (select PCTABPR.CODST
                                          from PCTABPR, PCCLIENT, PCPRACA
                                         where PCTABPR.CODPROD = M.CODPROD
                                           and PCCLIENT.CODCLI(+) = NVL(N.CODCLINF, N.CODCLI)
                                           and PCPRACA.CODPRACA(+) = PCCLIENT.CODPRACA
                                           and PCTABPR.NUMREGIAO = PCPRACA.NUMREGIAO
                                           and ROWNUM = 1)
                                    end,
                                    M.CODST) as CODST,
                             M.SITTRIBUT AS CST,
                             M.NUMTRANSITEM,
                             M.ROWID as IDPCMOV,
                             MC.VLBASEPARTDEST,
                             MC.ALIQINTERORIGPART,
                             M.CODFISCAL,
                             (NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0)) AS BASEICMS,
                             DECODE(TO_NUMBER(NVL(PD.CONDVENDA, N.CONDVENDA))
                                  , 7, DECODE(NVL(PD.CONTAORDEM, N.CONTAORDEM), 'N', 'NAO', 'S', 'SIM')
                                  , 8, DECODE(NVL(PD.CONTAORDEM, N.CONTAORDEM), 'N', 'SIM', 'S', 'NAO')
                                  , 13, DECODE(FI.DESTACARIMPOSTOSVENDATV13, 'N', 'NAO', 'SIM')
                                  , 14, DECODE(FI.DESTACARIMPOSTOSVENDATV14, 'N', 'NAO', 'SIM')
                                  , 'SIM') AS CALCULAPARTILHA,
                             'N' PREFATURAMENTO,
                             N.NUMTRANSVENDA NUMTRANS
                        from PCNFSAID       N,
                             PCMOV          M,
                             PCMOVCOMPLE    MC,
                             PCPRODUT       P,
                             PCCLIENTENDENT ENT,
                             PCCIDADE       CIDADE_ENT,
                             PCPEDC         PD,
                             PCCLIENT       CLIENTE,
                             PCFILIAL       FI
                       where N.NUMTRANSVENDA = P_NUMTRANSACAO
                         and N.NUMTRANSVENDA = M.NUMTRANSVENDA
                         and PD.NUMTRANSVENDA(+) = N.NUMTRANSVENDA
                         and ENT.CODENDENTCLI(+) = NVL(PD.CODENDENTCLI, PD.CODENDENT)
                         and ENT.CODCLI(+) = PD.CODCLI
                         and P.CODPROD = M.CODPROD
                         and N.NUMNOTA = M.NUMNOTA
                         and M.CODOPER <> 'SD'
                         and NVL(N.FINALIDADENFE, 'X') <> 'C'
                         and MC.NUMTRANSITEM(+) = M.NUMTRANSITEM
                         and CIDADE_ENT.CODCIDADE(+) = CLIENTE.CODCIDADECOM
                         and CLIENTE.CODCLI(+) = NVL(N.CODCLINF, N.CODCLI)
                         and FI.CODIGO(+) = NVL(N.CODFILIALNF, N.CODFILIAL)
                         and P_TIPOMOV = 'S'
                         and M.DTCANCEL is null
                         and M.QTCONT > 0
                      -------------------------------------------------------------------------------------------------------
                      union all
                      -------------------------------------------------------------------------------------------------------
                      select NVL(N.CODFILIALNF, N.CODFILIAL) CODFILIAL,
                             NVL(N.CONSUMIDORFINAL,'N') CONSUMIDORFINAL,
                             NVL(N.CONTRIBUINTE,'N') CONTRIBUINTE,
                             CASE
                               WHEN NVL(N.CODCLINF, N.CODCLI) IN (1, 2, 3) THEN
                                0
                               ELSE
                                NVL(N.CODCLINF, N.CODCLI)
                             END AS CODCLI,
                             N.UF,
                             UPPER(NVL(ENT.ESTENT, CIDADE_ENT.UF)) AS UFENTREGA,
                             N.DTSAIDA as DATAOPER,
                             M.CODPROD,
                             NVL(M.PUNITCONT, 0) - NVL(MC.VLFECP, 0) -
                             NVL(M.ST, 0) +  (CASE
                                                       WHEN PARAMFILIAL.OBTERCOMOVARCHAR2('RECALCICMSPARTFATURAMENTO',
                                                         NVL(N.CODFILIALNF, N.CODFILIAL)) = 'S' THEN
                                                       NVL(M.VLFRETE, 0)
                                                       ELSE
                                                       0
                                                       END) + NVL(M.VLOUTROS, 0) as VLPRODUTO,
                             DECODE(NVL(M.CODST, 0),
                                    0,
                                    case
                                      when PARAMFILIAL.OBTERCOMOVARCHAR2('CON_USATRIBUTACAOPORUF') = 'S' then
                                       (select PCTABTRIB.CODST
                                          from PCTABTRIB
                                         where PCTABTRIB.CODPROD = M.CODPROD
                                           and PCTABTRIB.CODFILIALNF = NVL(N.CODFILIALNF, N.CODFILIAL)
                                           and PCTABTRIB.UFDESTINO = N.UF
                                           and ROWNUM = 1)
                                      else
                                       (select PCTABPR.CODST
                                          from PCTABPR, PCCLIENT, PCPRACA
                                         where PCTABPR.CODPROD = M.CODPROD
                                           and PCCLIENT.CODCLI(+) = NVL(N.CODCLINF, N.CODCLI)
                                           and PCPRACA.CODPRACA(+) = PCCLIENT.CODPRACA
                                           and PCTABPR.NUMREGIAO = PCPRACA.NUMREGIAO
                                           and ROWNUM = 1)
                                    end,
                                    M.CODST) as CODST,
                             M.SITTRIBUT AS CST,
                             M.NUMTRANSITEM,
                             M.ROWID as IDPCMOV,
                             MC.VLBASEPARTDEST,
                             MC.ALIQINTERORIGPART,
                             M.CODFISCAL,
                             (NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0)) AS BASEICMS,
                             DECODE(TO_NUMBER(NVL(PD.CONDVENDA, N.CONDVENDA))
                                  , 7, DECODE(NVL(PD.CONTAORDEM, N.CONTAORDEM), 'N', 'NAO', 'S', 'SIM')
                                  , 8, DECODE(NVL(PD.CONTAORDEM, N.CONTAORDEM), 'N', 'SIM', 'S', 'NAO')
                                  , 13, DECODE(FI.DESTACARIMPOSTOSVENDATV13, 'N', 'NAO', 'SIM')
                                  , 14, DECODE(FI.DESTACARIMPOSTOSVENDATV14, 'N', 'NAO', 'SIM')
                                  , 'SIM') AS CALCULAPARTILHA,
                             'S' PREFATURAMENTO,
                             N.NUMTRANSVENDA NUMTRANS
                        from PCNFSAIDPREFAT    N,
                             PCMOVPREFAT       M,
                             PCMOVCOMPLEPREFAT MC,
                             PCPRODUT          P,
                             PCCLIENTENDENT    ENT,
                             PCCIDADE          CIDADE_ENT,
                             PCPEDC            PD,
                             PCCLIENT          CLIENTE,
                             PCFILIAL          FI
                       where N.NUMTRANSVENDA = P_NUMTRANSACAO
                         and N.NUMTRANSVENDA = M.NUMTRANSVENDA
                         and PD.NUMTRANSVENDA(+) = N.NUMTRANSVENDA
                         and ENT.CODENDENTCLI(+) = NVL(PD.CODENDENTCLI, PD.CODENDENT)
                         and ENT.CODCLI(+) = PD.CODCLI
                         and P.CODPROD = M.CODPROD
                         and N.NUMNOTA = M.NUMNOTA
                         and MC.NUMTRANSITEM(+) = M.NUMTRANSITEM
                         and CIDADE_ENT.CODCIDADE(+) = CLIENTE.CODCIDADECOM
                         and CLIENTE.CODCLI(+) = NVL(N.CODCLINF, N.CODCLI)
                         and FI.CODIGO(+) = NVL(N.CODFILIALNF, N.CODFILIAL)
                         and P_TIPOMOV = 'S'
                         and M.DTCANCEL is null
                         and N.DATACONSOLIDACAOPREFAT is null
                         and M.QTCONT > 0
                       -------------------------------------------------------------------------------------------------------
                       union all
                       -------------------------------------------------------------------------------------------------------
                       select N.CODFILIAL,
                             NVL(N.CONSUMIDORFINAL,'N') CONSUMIDORFINAL,
                             NVL(N.CONTRIBUINTE,'N') CONTRIBUINTE,
                             NVL(N.CODFORNECNF, N.CODFORNEC) as CODCLI,
                             N.UF,
                             null AS UFENTREGA,
                             N.DTEMISSAO as DATAOPER,
                             M.CODPROD,
                             NVL(M.PUNITCONT, 0) - NVL(MC.VLICMSPART, 0) - NVL(MC.VLFECP, 0) -
                             NVL(M.ST, 0) + (CASE
                                               WHEN PARAMFILIAL.OBTERCOMOVARCHAR2('RECALCICMSPARTFATURAMENTO',
                                                                                  NVL(N.CODFILIALNF, N.CODFILIAL)) = 'S' THEN
                                                NVL(M.VLFRETE, 0)
                                               ELSE
                                                0
                                             END) + NVL(M.VLOUTROS, 0) as VLPRODUTO,
                             DECODE(NVL(M.CODST, 0),
                                    0,
                                    case
                                      when PARAMFILIAL.OBTERCOMOVARCHAR2('CON_USATRIBUTACAOPORUF') = 'S' then
                                       (select PCTABTRIB.CODST
                                          from PCTABTRIB
                                         where PCTABTRIB.CODPROD = M.CODPROD
                                           and PCTABTRIB.CODFILIALNF = NVL(N.CODFILIALNF, N.CODFILIAL)
                                           and PCTABTRIB.UFDESTINO = N.UF
                                           and ROWNUM = 1)
                                      else
                                       (select PCTABPR.CODST
                                          from PCTABPR, PCCLIENT, PCPRACA
                                         where PCTABPR.CODPROD = M.CODPROD
                                           and PCCLIENT.CODCLI(+) = NVL(N.CODFORNECNF, N.CODFORNEC)
                                           and PCPRACA.CODPRACA(+) = PCCLIENT.CODPRACA
                                           and PCTABPR.NUMREGIAO = PCPRACA.NUMREGIAO
                                           and ROWNUM = 1)
                                    end,
                                    M.CODST) as CODST,
                             M.SITTRIBUT AS CST,
                             M.NUMTRANSITEM,
                             M.ROWID as IDPCMOV,
                             MC.VLBASEPARTDEST,
                             MC.ALIQINTERORIGPART,
                             M.CODFISCAL,
                             (NVL(M.BASEICMS, 0) + NVL(MC.VLBASEFRETE, 0) + NVL(MC.VLBASEOUTROS, 0)) AS BASEICMS,
                             'SIM' AS CALCULAPARTILHA,
                             'N' PREFATURAMENTO,
                             N.NUMTRANSENT NUMTRANS
                        from PCNFENT N, PCMOV M, PCMOVCOMPLE MC, PCPRODUT P
                       where N.NUMTRANSENT = P_NUMTRANSACAO
                         and N.NUMTRANSENT = M.NUMTRANSENT
                         AND P.CODPROD = M.CODPROD
                         and N.NUMNOTA = M.NUMNOTA
                         and MC.NUMTRANSITEM(+) = M.NUMTRANSITEM
                         and N.TIPODESCARGA in ('6', '8', 'T')
                         and P_TIPOMOV = 'E'
                         and M.DTCANCEL is null
                         and M.QTCONT > 0
          );


   function PREPARAR_XML_RETORNO(P_XML in varchar2) return TIPO_ICMS_PARTILHA is
      V_XML     XMLTYPE;
      V_RETORNO TIPO_ICMS_PARTILHA;
   begin
      V_RETORNO := TIPO_ICMS_PARTILHA(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'N', 'N', null);
      V_XML     := XMLTYPE.CREATEXML(P_XML);

      select TO_NUMBER(V_XML.EXTRACT('retorno/aliqinterestadual/text()')
                      ,'FM9999999999999999D999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/aliqinternadest/text()')
                      ,'FM9999999999999999D999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/aliqfcp/text()')
                      ,'FM9999999999999999D999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/vlicmspartrem/text()')
                      ,'FM9999999999999999D999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/vlbasepartdest/text()')
                      ,'FM9999999999999999D999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/vlfcppart/text()')
                      ,'FM9999999999999999D999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/vlicmspartdest/text()')
                      ,'FM9999999999999999D999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/percprovpart/text()')
                      ,'FM9999999999999999D999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/percbasered/text()')
                      ,'FM9999999999999999D999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/vlicmsdifaliq/text()')
                      ,'FM9999999999999999D999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/vlicmspart/text()')
                      ,'FM9999999999999999D999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/percbasereddest/text()')
                      ,'FM9999999999999999D999999'
                      ,'nls_numeric_characters=,.')
            ,V_XML.EXTRACT('retorno/acrescaliqdesticmspart/text()').GETSTRINGVAL()
            ,V_XML.EXTRACT('retorno/considerarcontribicmspart/text()').GETSTRINGVAL()
        into V_RETORNO.ALIQINTERESTADUAL
            ,V_RETORNO.ALIQINTERNADEST
            ,V_RETORNO.ALIQFCP
            ,V_RETORNO.VLICMSPARTREM
            ,V_RETORNO.VLBASEPARTDEST
            ,V_RETORNO.VLFCPPART
            ,V_RETORNO.VLICMSPARTDEST
            ,V_RETORNO.PERCPROVPART
            ,V_RETORNO.PERCBASERED
            ,V_RETORNO.VLICMSDIFALIQ
            ,V_RETORNO.VLICMSPART
            ,V_RETORNO.PERCBASEREDDEST
            ,V_RETORNO.ACRESCALIQDESTICMSPART
            ,V_RETORNO.CONSIDERARCONTRIBICMSPART
        from DUAL;

      return V_RETORNO;
   end;

   function PREPARAR_XML_RETORNO_2(P_XML in varchar2) return T_ICMS_PARTILHA_FISCAL is
      V_XML     XMLTYPE;
      V_RETORNO T_ICMS_PARTILHA_FISCAL;
    begin
      V_RETORNO := T_ICMS_PARTILHA_FISCAL(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'N', 'N', null);
      V_XML     := XMLTYPE.CREATEXML(P_XML);

      select TO_NUMBER(V_XML.EXTRACT('retorno/aliqinterestadual/text()')
                      ,'FM9999999999999999D999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/aliqinternadest/text()')
                      ,'FM9999999999999999D999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/aliqfcp/text()')
                      ,'FM9999999999999999D999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/vlicmspartrem/text()')
                      ,'FM9999999999999999D9999999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/vlbasepartdest/text()')
                      ,'FM9999999999999999D9999999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/vlfcppart/text()')
                      ,'FM9999999999999999D9999999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/vlicmspartdest/text()')
                      ,'FM9999999999999999D9999999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/percprovpart/text()')
                      ,'FM9999999999999999D999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/percbasered/text()')
                      ,'FM9999999999999999D999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/vlicmsdifaliq/text()')
                      ,'FM9999999999999999D9999999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/vlicmspart/text()')
                      ,'FM9999999999999999D9999999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/percbasereddest/text()')
                      ,'FM9999999999999999D9999999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/percbaseredpart/text()')
                      ,'FM9999999999999999D999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/vlicmsdifaliqpart/text()')
                      ,'FM9999999999999999D9999999999'
                      ,'nls_numeric_characters=,.')
            ,TO_NUMBER(V_XML.EXTRACT('retorno/aliqinterorigpart/text()')
                      ,'FM9999999999999999D999999'
                      ,'nls_numeric_characters=,.')
            ,V_XML.EXTRACT('retorno/acrescaliqdesticmspart/text()').GETSTRINGVAL()
            ,V_XML.EXTRACT('retorno/considerarcontribicmspart/text()').GETSTRINGVAL()
        into V_RETORNO.ALIQINTERESTADUAL
            ,V_RETORNO.ALIQINTERNADEST
            ,V_RETORNO.ALIQFCP
            ,V_RETORNO.VLICMSPARTREM
            ,V_RETORNO.VLBASEPARTDEST
            ,V_RETORNO.VLFCPPART
            ,V_RETORNO.VLICMSPARTDEST
            ,V_RETORNO.PERCPROVPART
            ,V_RETORNO.PERCBASERED
            ,V_RETORNO.VLICMSDIFALIQ
            ,V_RETORNO.VLICMSPART
            ,V_RETORNO.PERCBASEREDDEST
            ,V_RETORNO.PERCBASEREDPART
            ,V_RETORNO.VLICMSDIFALIQPART
            ,V_RETORNO.ALIQINTERORIGPART
            ,V_RETORNO.ACRESCALIQDESTICMSPART
            ,V_RETORNO.CONSIDERARCONTRIBICMSPART
        from DUAL;

      return V_RETORNO;
   end;

   function PREPARAR_XML_ENTRADASORIGMERC(P_XML in varchar2) return TIPO_ENTRADASPEPSTAB is
      INDTRANSACAO number;

      P_LISTA TIPO_ENTRADASPEPSTAB;
   begin
      P_LISTA := TIPO_ENTRADASPEPSTAB();

      INDTRANSACAO := 1;
      for REG in (select TO_NUMBER(EXTRACTVALUE(COLUMN_VALUE, '/entrada/numtransent')
                                  ,'FM9999999999999999D999999'
                                  ,'nls_numeric_characters=,.') NUMTRANSENT
                        ,TO_NUMBER(EXTRACTVALUE(COLUMN_VALUE, '/entrada/origmerctrib')
                                  ,'FM9999999999999999D999999'
                                  ,'nls_numeric_characters=,.') ORIGMERCTRIB
                        ,TO_NUMBER(EXTRACTVALUE(COLUMN_VALUE, '/entrada/percicm')
                                  ,'FM9999999999999999D999999'
                                  ,'nls_numeric_characters=,.') PERCICM
                        ,EXTRACTVALUE(COLUMN_VALUE, '/entrada/importado') IMPORTADO
                        ,TO_NUMBER(EXTRACTVALUE(COLUMN_VALUE, '/entrada/saldo')
                                  ,'FM9999999999999999D999999'
                                  ,'nls_numeric_characters=,.') SALDO
                    from table(XMLSEQUENCE(XMLTYPE(P_XML).EXTRACT('/entradas/entrada'))) T)
      loop

         P_LISTA.EXTEND(1);
         P_LISTA(INDTRANSACAO) := TIPO_ENTRADASPEPS(REG.NUMTRANSENT
                                                   ,REG.SALDO
                                                   ,REG.ORIGMERCTRIB
                                                   ,REG.PERCICM
                                                   ,REG.IMPORTADO);
         INDTRANSACAO := INDTRANSACAO + 1;
      end loop;
      return P_LISTA;
   end;

   procedure ICMSPARTILHA_CALCULAR_1_0(P_CODFILIAL    in varchar2
                                      ,P_CODCLI       in number
                                      ,P_UFOPERCONSUM in varchar2
                                      ,P_DATAOPER     in date
                                      ,P_VLPRODUTO    in number
                                      ,P_CODTRIBUT    in number
                                      ,P_RETORNO      out tipo_icms_partilha
                                      ,P_CODMSG       out number
                                      ,P_MSG          out varchar2) is
      V_SCRIPT  long;
      V_RETORNO varchar2(4000);
   begin
      begin
         select SCRIPT
           into V_SCRIPT
           from PCFWREPOSITORIO R
          where R.SERVICO = 'winthor.fiscal.icmspartilha.calcular'
            and R.VERSAO = '1.0'
            and ROWNUM = 1;

         execute immediate DBMS_LOB.SUBSTR(V_SCRIPT, 32765, 1)
            using P_CODFILIAL, P_CODCLI, P_UFOPERCONSUM, P_DATAOPER, P_VLPRODUTO, P_CODTRIBUT, out V_RETORNO, out P_CODMSG, out P_MSG;

         if P_CODMSG = 0
         then
            P_RETORNO := PREPARAR_XML_RETORNO(V_RETORNO);
         end if;

      exception
         when NO_DATA_FOUND then
            RAISE_APPLICATION_ERROR(-20000, 'O serviço solicitado é inexistente!');
      end;
   end;

   procedure ICMSPARTILHA_CALCULAR_1_1(P_CODFILIAL    in varchar2
                                      ,P_CODCLI       in number
                                      ,P_UFOPERCONSUM in varchar2
                                      ,P_DATAOPER     in date
                                      ,P_VLPRODUTO    in number
                                      ,P_CODTRIBUT    in number
                                      ,P_CODPROD      in number
                                      ,P_RETORNO      out tipo_icms_partilha
                                      ,P_CODMSG       out number
                                      ,P_MSG          out varchar2) is
      V_SCRIPT  long;
      V_RETORNO varchar2(4000);
   begin
      begin
         select SCRIPT
           into V_SCRIPT
           from PCFWREPOSITORIO R
          where R.SERVICO = 'winthor.fiscal.icmspartilha.calcular'
            and R.VERSAO = '1.1'
            and ROWNUM = 1;

         execute immediate DBMS_LOB.SUBSTR(V_SCRIPT, 32765, 1)
            using P_CODFILIAL, P_CODCLI, P_UFOPERCONSUM, P_DATAOPER, P_VLPRODUTO, P_CODTRIBUT, P_CODPROD, out V_RETORNO, out P_CODMSG, out P_MSG;

         if P_CODMSG = 0
         then
            P_RETORNO := PREPARAR_XML_RETORNO(V_RETORNO);
         end if;

      exception
         when NO_DATA_FOUND then
            RAISE_APPLICATION_ERROR(-20000, 'O serviço solicitado é inexistente!');
      end;
   end;

   procedure ICMSPARTILHA_CALCULAR_1_2(P_CODFILIAL    in varchar2
                                      ,P_CODCLI       in number
                                      ,P_UFOPERCONSUM in varchar2
                                      ,P_UFENTREGA    in varchar2
                                      ,P_DATAOPER     in date
                                      ,P_VLPRODUTO    in number
                                      ,P_CODTRIBUT    in number
                                      ,P_CODPROD      in number
                                      ,P_RETORNO      out tipo_icms_partilha
                                      ,P_CODMSG       out number
                                      ,P_MSG          out varchar2) is
      V_SCRIPT  long;
      V_RETORNO varchar2(4000);
   begin
      begin
         select SCRIPT
           into V_SCRIPT
           from PCFWREPOSITORIO R
          where R.SERVICO = 'winthor.fiscal.icmspartilha.calcular'
            and R.VERSAO = '1.2'
            and ROWNUM = 1;

         execute immediate DBMS_LOB.SUBSTR(V_SCRIPT, 32765, 1)
            using P_CODFILIAL, P_CODCLI, P_UFOPERCONSUM, P_UFENTREGA, P_DATAOPER, P_VLPRODUTO, P_CODTRIBUT, P_CODPROD, out V_RETORNO, out P_CODMSG, out P_MSG;

         if P_CODMSG = 0
         then
            P_RETORNO := PREPARAR_XML_RETORNO(V_RETORNO);
         end if;

      exception
         when NO_DATA_FOUND then
            RAISE_APPLICATION_ERROR(-20000, 'O serviço solicitado é inexistente!');
      end;
   end;

   procedure ICMSPARTILHA_CALCULAR_1_3(P_CODFILIAL    in varchar2
                                      ,P_CODCLI       in number
                                      ,P_UFOPERCONSUM in varchar2
                                      ,P_UFENTREGA    in varchar2
                                      ,P_DATAOPER     in date
                                      ,P_VLPRODUTO    in number
                                      ,P_CODTRIBUT    in number
                                      ,P_CODPROD      in number
                                      ,P_RETORNO      out tipo_icms_partilha
                                      ,P_CODMSG       out number
                                      ,P_MSG          out varchar2) is
      V_SCRIPT  long;
      V_RETORNO varchar2(4000);
   begin
      begin
         select SCRIPT
           into V_SCRIPT
           from PCFWREPOSITORIO R
          where R.SERVICO = 'winthor.fiscal.icmspartilha.calcular'
            and R.VERSAO = '1.3'
            and ROWNUM = 1;

         execute immediate DBMS_LOB.SUBSTR(V_SCRIPT, 32765, 1)
            using P_CODFILIAL, P_CODCLI, P_UFOPERCONSUM, P_UFENTREGA, P_DATAOPER, P_VLPRODUTO, P_CODTRIBUT, P_CODPROD, out V_RETORNO, out P_CODMSG, out P_MSG;

         if P_CODMSG = 0
         then
            P_RETORNO := PREPARAR_XML_RETORNO(V_RETORNO);
         end if;

      exception
         when NO_DATA_FOUND then
            RAISE_APPLICATION_ERROR(-20000, 'O serviço solicitado é inexistente!');
      end;
   end;

   procedure ICMSPARTILHA_CALCULAR_1_4(P_CODFILIAL    in varchar2
                                      ,P_CODCLI       in number
                                      ,P_UFOPERCONSUM in varchar2
                                      ,P_UFENTREGA    in varchar2
                                      ,P_DATAOPER     in date
                                      ,P_VLPRODUTO    in number
                                      ,P_CODTRIBUT    in number
                                      ,P_CODPROD      in number
                                      ,P_CFOP         in number
                                      ,P_CST          in varchar2
                                      ,P_RETORNO      out tipo_icms_partilha
                                      ,P_CODMSG       out number
                                      ,P_MSG          out varchar2) is
      V_SCRIPT  long;
      V_VERSAO  varchar2(10);
      V_RETORNO varchar2(4000);
   begin
      begin
         select SCRIPT
               ,VERSAO || '.' || TO_CHAR(PATCH) as VERSAO
           into V_SCRIPT
               ,V_VERSAO
           from PCFWREPOSITORIO R
          where R.SERVICO = 'winthor.fiscal.icmspartilha.calcular'
            and R.VERSAO = '1.4'
            and ROWNUM = 1;

         execute immediate DBMS_LOB.SUBSTR(V_SCRIPT, 32765, 1)
            using P_CODFILIAL, P_CODCLI, P_UFOPERCONSUM, P_UFENTREGA, P_DATAOPER, P_VLPRODUTO, P_CODTRIBUT, P_CODPROD, P_CFOP, P_CST, out V_RETORNO, out P_CODMSG, out P_MSG;

         P_RETORNO := TIPO_ICMS_PARTILHA(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'N', 'N', null);
         if P_CODMSG = 0
         then
            P_RETORNO               := PREPARAR_XML_RETORNO(V_RETORNO);
         end if;
         P_RETORNO.VERSAOSERVICO := V_VERSAO;

      exception
         when NO_DATA_FOUND then
            RAISE_APPLICATION_ERROR(-20000, 'O serviço solicitado é inexistente!');
      end;
   end;

   function CEST_OBTERCODIGO_1_0(P_CODPROD      in number
                                ,P_CSTICMS      in varchar2
                                ,P_TIPOMOV      in varchar2
                                ,P_TIPOOPERACAO in varchar2
                                ,P_CODOPER      in varchar2
                                ,P_CFOP         in number
                                ,P_CODPART      in number
                                ,P_VLST         in number
                                ,P_CODCEST      out varchar2
                                ,P_CODMSG       out number
                                ,P_MSG          out varchar2) return varchar2 is
      V_SCRIPT long;
   begin
      begin
         select SCRIPT
           into V_SCRIPT
           from PCFWREPOSITORIO R
          where R.SERVICO = 'winthor.fiscal.cest.obtercodigo'
            and R.VERSAO = '1.0'
            and ROWNUM = 1;

         execute immediate DBMS_LOB.SUBSTR(V_SCRIPT, 32765, 1)
            using P_CODPROD, P_CSTICMS, P_TIPOMOV, P_TIPOOPERACAO, P_CODOPER, P_CFOP, P_CODPART, P_VLST, out P_CODCEST, out P_CODMSG, out P_MSG;

         if P_CODMSG in (0, 4)
         then
            return 'S';
         else
            return 'N';
         end if;
      exception
         when NO_DATA_FOUND then
            RAISE_APPLICATION_ERROR(-20000, 'O serviço solicitado é inexistente!');
      end;
   end;

   function CEST_OBTERCODIGO_1_1(P_CODPROD      in number
                                ,P_CSTICMS      in varchar2
                                ,P_TIPOMOV      in varchar2
                                ,P_TIPOOPERACAO in varchar2
                                ,P_CODOPER      in varchar2
                                ,P_CFOP         in number
                                ,P_CODPART      in number
                                ,P_VLST         in number
                                ,P_CODFILIAL    in varchar2
                                ,P_CODCEST      out varchar2
                                ,P_CODMSG       out number
                                ,P_MSG          out varchar2) return varchar2 is
      V_SCRIPT long;
   begin
      begin
         select SCRIPT
           into V_SCRIPT
           from PCFWREPOSITORIO R
          where R.SERVICO = 'winthor.fiscal.cest.obtercodigo'
            and R.VERSAO = '1.1'
            and ROWNUM = 1;

         execute immediate DBMS_LOB.SUBSTR(V_SCRIPT, 32765, 1)
            using P_CODPROD, P_CSTICMS, P_TIPOMOV, P_TIPOOPERACAO, P_CODOPER, P_CFOP, P_CODPART, P_VLST, P_CODFILIAL, out P_CODCEST, out P_CODMSG, out P_MSG;

         if P_CODMSG in (0, 4, 7)
         then
            return 'S';
         else
            return 'N';
         end if;
      exception
         when NO_DATA_FOUND then
            RAISE_APPLICATION_ERROR(-20000, 'O serviço solicitado é inexistente!');
      end;
   end;

   procedure PEPS_OBTERORIGEMMERC_1_0(P_CODPROD          in number
                                     ,P_CODFILIAL        in varchar2
                                     ,P_QUANTIDADE       in number
                                     ,P_DATA             in date
                                     ,P_ENTRADASORIGMERC out TIPO_ENTRADASPEPSTAB
                                     ,P_CODMSG           out number
                                     ,P_MSG              out varchar2) is
      V_SCRIPT  long;
      V_RETORNO varchar2(4000);
   begin
      begin
         select SCRIPT
           into V_SCRIPT
           from PCFWREPOSITORIO R
          where R.SERVICO = 'winthor.fiscal.peps.obterorigemmerc'
            and R.VERSAO = '1.0'
            and ROWNUM = 1;

         execute immediate DBMS_LOB.SUBSTR(V_SCRIPT, 32765, 1)
            using P_CODPROD, P_CODFILIAL, P_QUANTIDADE, P_DATA, out V_RETORNO, out P_CODMSG, out P_MSG;

         if P_CODMSG = 0
         then
            P_ENTRADASORIGMERC := PREPARAR_XML_ENTRADASORIGMERC(V_RETORNO);
         end if;

      exception
         when NO_DATA_FOUND then
            RAISE_APPLICATION_ERROR(-20000, 'O serviço solicitado é inexistente!');
      end;
   end;

   ---------------------------
   PROCEDURE CEST_OBTERCODIGO_1_3(P_CODPROD      in number
                                 ,P_CSTICMS      in varchar2
                                 ,P_TIPOMOV      in varchar2
                                 ,P_TIPOOPERACAO in varchar2
                                 ,P_CODOPER      in varchar2
                                 ,P_CFOP         in number
                                 ,P_CODPART      in number
                                 ,P_VLST         in number
                                 ,P_CODFILIAL    in varchar2
                                 ,P_CODCEST      out varchar2
                                 ,P_CODMSG       out number
                                 ,P_MSG          out varchar2) IS
   --variaveis output

   procedure F14_OBTEREXCECAO(P_CODSEQCEST     in number
                             ,P_TIPOMOV        in varchar2
                             ,P_TIPOOPERACAO   in varchar2
                             ,P_CODOPER        in varchar2
                             ,P_CFOP           in number
                             ,P_CODPART        in number
                             ,P_CODPROD        in number
                             ,P_CODSEQCESTNOVO out number) is
   begin
      begin
         select E.CODSEQCESTNOVO
           into P_CODSEQCESTNOVO
           from (select E.CODSEQCESTNOVO
                   from PCCESTEXCECAO E
                  where E.CODSEQCEST = P_CODSEQCEST
                    and trim(E.VALOR1) = trim(DECODE(E.TIPO1
                                                    ,'TM'
                                                    ,P_TIPOMOV
                                                    ,'TO'
                                                    ,P_TIPOOPERACAO
                                                    ,'CO'
                                                    ,P_CODOPER
                                                    ,'CF'
                                                    ,TO_CHAR(P_CFOP)
                                                    ,'CP'
                                                    ,TO_CHAR(P_CODPART)
                                                    ,'PR'
                                                    ,TO_CHAR(P_CODPROD)))
                    and (trim(E.VALOR2) is null or
                        trim(E.VALOR2) = trim(DECODE(E.TIPO2
                                                     ,'TM'
                                                     ,P_TIPOMOV
                                                     ,'TO'
                                                     ,P_TIPOOPERACAO
                                                     ,'CO'
                                                     ,P_CODOPER
                                                     ,'CF'
                                                     ,TO_CHAR(P_CFOP)
                                                     ,'CP'
                                                     ,TO_CHAR(P_CODPART)
                                                     ,'PR'
                                                     ,TO_CHAR(P_CODPROD))))
                    and (trim(E.VALOR3) is null or
                        trim(E.VALOR3) = trim(DECODE(E.TIPO3
                                                     ,'TM'
                                                     ,P_TIPOMOV
                                                     ,'TO'
                                                     ,P_TIPOOPERACAO
                                                     ,'CO'
                                                     ,P_CODOPER
                                                     ,'CF'
                                                     ,TO_CHAR(P_CFOP)
                                                     ,'CP'
                                                     ,TO_CHAR(P_CODPART)
                                                     ,'PR'
                                                     ,TO_CHAR(P_CODPROD))))
                  order by E.CODCESTEXCEXAO) E
          where ROWNUM = 1;
      exception
         when NO_DATA_FOUND then
            P_CODSEQCESTNOVO := P_CODSEQCEST;
      end;

   end;

   function F14_CSTEXCECAO(PCST in varchar2) return boolean is
      QT number(2);
   begin
      QT := 0;
      if trim(PCST) is not null
      then
         select count(1)
           into QT
           from PCEXCECAOITEM I
           join PCEXCECAOTIPO T on I.CODTIPOEXCECAO = T.CODIGO
           join PCEXCECAODOCFISCAL D on I.CODEXCECAO = D.CODIGO
           join PCEXCECAOCATEGORIZACAO C on C.CODIGO = D.CODCATEGORIA
          where T.DESCRICAO = 'CESTCST'
            and I.VALOR = PCST
            and C.ACAO = 'D';
      end if;

      return QT > 0;
   end;

   procedure F14_OBTERCODIGOCEST(P_CODPROD      in number
                                ,P_CSTICMS      in varchar2
                                ,P_TIPOMOV      in varchar2
                                ,P_TIPOOPERACAO in varchar2
                                ,P_CODOPER      in varchar2
                                ,P_CFOP         in number
                                ,P_CODPART      in number
                                ,P_VLST         in number
                                ,P_CODFILIAL    in varchar2
                                ,P_CODCEST      out varchar2
                                ,P_CODMSG       out number
                                ,P_MSG          out varchar2) is

      K_MSG_SUCESSO constant varchar2(40) := 'Serviço processado com sucesso';
      K_MSG7        constant varchar2(36) := 'Produto definido como isento de CEST';
      K_MSG5        constant varchar2(67) := 'Não foi localizado registro CEST para o produto';
      K_MSG6        constant varchar2(50) := 'O código CEST obtido está nulo';
      K_MSG4        constant varchar2(80) := 'Foi definida uma exceção para deixar de gerar CEST para o CST informado';
      K_MSG3        constant varchar2(47) := 'O CST de ICMS não informado';
      K_MSG2        constant varchar2(68) := 'Código do produto não informado ou inexistente no cadastro';
      K_MSG1        constant varchar2(84) := 'O TIPOMOV informado é invalido (valores válidos: E, EP, S ou SP)';

      V_EXCECAO    boolean;
      V_NCM        PCPRODUT.NBM%type;
      V_CODSEQCEST PCCESTPRODUTO.CODSEQCEST%type;
      V_VALIDACEST boolean := false;
      V_DESCCEST   PCPRODFILIAL.DESCONSIDERARCEST%type;
   begin
      PKG_DEBUGGING_FWPC.LOG_MSG('VALIDANDO PARAMETROS DE EXIGENCIA');
      begin
         V_VALIDACEST := PARAMFILIAL.OBTERCOMOVARCHAR2('GERARINFOCESTNFE') = 'S';
      exception
         when others then
            V_VALIDACEST := false;
      end;

      if not V_VALIDACEST
      then
         begin
            V_VALIDACEST := PARAMFILIAL.OBTERCOMOVARCHAR2('GERARINFOCESTNFEFIL', P_CODFILIAL) = 'S';
         exception
            when others then
               V_VALIDACEST := false;
         end;
      end if;

      if not V_VALIDACEST
      then
         P_CODMSG := 0;
         P_MSG    := K_MSG_SUCESSO;
         PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
         return;
      end if;

      PKG_DEBUGGING_FWPC.LOG_MSG('VALIDANDO PARAMETROS DE ENTRADA');
      if P_TIPOMOV not in ('E', 'S', 'EP', 'SP')
      then
         P_CODMSG := 1;
         P_MSG    := K_MSG1;
         PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
         return;
      end if;

      begin
         select P.NCM
           into V_NCM
           from (select 'N' TIPOPROD
                       ,P.CODPROD
                       ,P.NBM as NCM
                   from PCPRODUT P
                 union all
                 select 'P' TIPOPROD
                       ,P.CODPROD
                       ,P.CODNCM as NCM
                   from PCPRODCIAP P) P
          where (P_TIPOMOV not like '%P' and P.TIPOPROD = 'N' or
                P_TIPOMOV like '%P' and P.TIPOPROD = 'P')
            and P.CODPROD = P_CODPROD;
      exception
         when NO_DATA_FOUND then
            P_CODMSG := 2;
            P_MSG    := K_MSG2;
            PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
            return;
      end;

      --4.b.
      if P_TIPOMOV in ('E', 'S')
      then
     select DESCONSIDERARCEST
           into V_DESCCEST
           from PCPRODFILIAL
          where CODPROD = P_CODPROD
            and CODFILIAL = P_CODFILIAL;

         if (V_DESCCEST = 'S')
         then
            P_CODMSG := 7;
            P_MSG    := K_MSG7;
            PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
            return;
         end if;
      end if;

      if trim(P_CSTICMS) is null
      then
         P_CODMSG := 3;
         P_MSG    := K_MSG3;
         PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
         return;
      end if;

    V_EXCECAO := F14_CSTEXCECAO(P_CSTICMS);
      if V_EXCECAO
      then
        P_CODMSG := 4;
        P_MSG    := K_MSG4;
        PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
        return;
      end if;

      PKG_DEBUGGING_FWPC.LOG_MSG('OBTENDO REGISTRO CEST DO PRODUTO');
      begin

         --4.a.
         SELECT P.CODSEQCEST
           into V_CODSEQCEST
          FROM PCCESTPRODUTO P
             , PCPRODUT
         WHERE P.CODPROD  = PCPRODUT.CODPROD
           AND P.CODPROD  = P_CODPROD
           AND P.TIPOPROD = DECODE(SUBSTR(P_TIPOMOV, 2, 1), 'P', 'P', 'N')
           AND EXISTS(SELECT 1
                        FROM PCCEST
                       WHERE REPLACE(PCPRODUT.NBM, '.', '') LIKE REPLACE(PCCEST.NCM, '.', '') || '%'
                         AND PCCEST.CODIGO = NVL(P.CODSEQCEST, 0))
         AND ROWNUM = 1;

         if (NVL(V_CODSEQCEST, 0) = 0)
         then
            P_CODMSG := 6;
            P_MSG    := K_MSG6;
            PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
            return;
         end if;
      exception
         when NO_DATA_FOUND then
            P_CODMSG := 5;
            P_MSG    := K_MSG5;
            PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
            return;
      end;

      PKG_DEBUGGING_FWPC.LOG_MSG('OBTENDO REGISTRO EXCEÇÕES DA CEST');
      F14_OBTEREXCECAO(V_CODSEQCEST
                      ,P_TIPOMOV
                      ,P_TIPOOPERACAO
                      ,P_CODOPER
                      ,P_CFOP
                      ,P_CODPART
                      ,P_CODPROD
                      ,V_CODSEQCEST);

      begin
         select CODCEST into P_CODCEST from PCCEST where CODIGO = V_CODSEQCEST;
      exception
         when NO_DATA_FOUND then
            P_CODCEST := null;
      end;

      if trim(P_CODCEST) is null
      then
         P_CODMSG := 6;
         P_MSG    := K_MSG6;
         PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
         return;
      end if;

      P_CODMSG := 0;
      P_MSG    := K_MSG_SUCESSO;
   end;

 begin
    F14_OBTERCODIGOCEST(P_CODPROD,P_CSTICMS,P_TIPOMOV,P_TIPOOPERACAO,P_CODOPER,P_CFOP,P_CODPART,P_VLST,P_CODFILIAL,P_CODCEST,P_CODMSG,P_MSG);
 end;
 ---------------------------
 PROCEDURE ICMSPARTILHA_CALCULAR_1_5(P_CODFILIAL    in varchar2
                                    ,P_CODCLI       in number
                                    ,P_UFOPERCONSUM in varchar2
                                    ,P_UFENTREGA    in varchar2
                                    ,P_DATAOPER     in date
                                    ,P_VLPRODUTO    in number
                                    ,P_CODTRIBUT    in number
                                    ,P_CODPROD      in number
                                    ,P_CFOP         in number
                                    ,P_CST          in varchar2
                                    ,P_RETORNO      out varchar2
                                    ,P_CODMSG       out number
                                    ,P_MSG          out varchar2) is
  --variaveis output

     function F10_ANPCALCULAR(PCODPROD in number) return boolean is
        QT number(2);
     begin
        select count(1)
          into QT
          from PCPRODUT
         where CODPROD = PCODPROD
           and (ANP is null or ANP in (select I.VALOR
                                         from PCEXCECAOITEM I
                                         join PCEXCECAOTIPO T on I.CODTIPOEXCECAO = T.CODIGO
                                         join PCEXCECAODOCFISCAL D on I.CODEXCECAO = D.CODIGO
                                         join PCEXCECAOCATEGORIZACAO C on C.CODIGO = D.CODCATEGORIA
                                        where T.DESCRICAO = 'ANP'
                                          and C.ACAO = 'C'));
        return QT > 0;
     end;

     function F10_CFOPEXCECAO(PCFOP in number) return boolean is
        QT number(2);
     begin
        QT := 0;
        if PCFOP > 0
        then
           select count(1)
             into QT
             from PCEXCECAOITEM I
             join PCEXCECAOTIPO T on I.CODTIPOEXCECAO = T.CODIGO
             join PCEXCECAODOCFISCAL D on I.CODEXCECAO = D.CODIGO
             join PCEXCECAOCATEGORIZACAO C on C.CODIGO = D.CODCATEGORIA
            where T.DESCRICAO = 'CFOP'
              and I.VALOR = TO_CHAR(PCFOP)
              and C.ACAO = 'D';
        end if;

        return QT > 0;
     end;

     function F10_CSTEXCECAO(PCST in varchar2) return boolean is
        QT number(2);
     begin
        QT := 0;
        if trim(PCST) is not null
        then
           select count(1)
             into QT
             from PCEXCECAOITEM I
             join PCEXCECAOTIPO T on I.CODTIPOEXCECAO = T.CODIGO
             join PCEXCECAODOCFISCAL D on I.CODEXCECAO = D.CODIGO
             join PCEXCECAOCATEGORIZACAO C on C.CODIGO = D.CODCATEGORIA
            where T.DESCRICAO = 'CST'
              and I.VALOR = PCST
              and C.ACAO = 'D';
        end if;

        return QT > 0;
     end;

     function F10_CALCULAR_BASEPART(P_VLPRODUTO              in number
                                   ,P_ALIQINTERESTADUAL      in number
                                   ,P_ALIQINTERNADEST        in number
                                   ,P_ALIQFCP                in number
                                   ,P_AGREGARVLOPER          in boolean
                                   ,P_ACRESCALIQDESTICMSPART in boolean
                                   ,P_CONTRIBUINTE           in boolean) return number is
     begin
        if nvl(P_ALIQINTERNADEST, 0) > 0  then
           if  P_AGREGARVLOPER
               or P_ACRESCALIQDESTICMSPART
           then
               return(P_VLPRODUTO / case
                         when (not P_ACRESCALIQDESTICMSPART)
                              or (P_CONTRIBUINTE) then
                          (1 + P_ALIQINTERESTADUAL / 100)
                         else
                          1
                      end / ((100 - P_ALIQINTERNADEST - P_ALIQFCP) / 100));
            else
               return P_VLPRODUTO;
            end if;
        else
            return 0;
        end if;
     end;

     procedure F10_CALCULAR_VALORES(P_CODFILIAL              in varchar2
                                   ,P_VLPRODUTO              in number
                                   ,P_DATAOPER               in date
                                   ,P_CLIENTEISENTO          in varchar2
                                   ,P_ALIQOPERACAO           in out number
                                   ,P_ALIQINTERESTADUAL      in number
                                   ,P_ALIQINTERNADEST        in out number
                                   ,P_ALIQFCP                in out number
                                   ,P_PERCBASERED            in out number
                                   ,P_PERCBASEREDDEST        in out number
                                   ,P_ACRESCALIQDESTICMSPART in varchar2
                                   ,P_CONSIDCONTRIB          in varchar2
                                   ,P_CONTRIBUINTE           in varchar2
                                   ,P_ISENTAICMSUFDEST       in varchar2
                                   ,P_ISENTAICMSPARTUFDESTORGAOPUB in varchar2
                                   ,P_ORGAOPUB               in varchar2
                                   ,P_RETORNO                out varchar2) is
        V_VLICMSPARTREM   number(22, 6);
        V_VLBASEPARTDEST  number(22, 6);
        V_VLFCPPART       number(22, 6);
        V_VLICMSPARTDEST  number(22, 6);
        V_PERCPROVPART    number(22, 6);
        V_VLICMSDIFALIQ   number(22, 10);
        V_VLICMSPART      number(22, 6);
        V_ANOOPER         number(4);
        V_XMLRETORNO      XMLTYPE;
        V_AGREGARVLOPER   boolean;
        V_REDUZIRBASEDEST boolean;

        V_VLBASEPARTORIG number(22, 6);

     begin
        PKG_DEBUGGING_FWPC.LOG_MSG('CALCULANDO PARTILHA DE ICMS');
        V_AGREGARVLOPER := NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('ACRESCICMSPARTILHAPRECO', P_CODFILIAL)
                              ,'N') = 'S';

        V_VLICMSPART     := 0;
        V_VLBASEPARTDEST := F10_CALCULAR_BASEPART(P_VLPRODUTO
                                                 ,P_ALIQINTERESTADUAL
                                                 ,P_ALIQINTERNADEST
                                                 ,P_ALIQFCP
                                                 ,V_AGREGARVLOPER
                                                 ,P_ACRESCALIQDESTICMSPART = 'S'
                                                 ,P_CONTRIBUINTE = 'S');

        if V_AGREGARVLOPER
        then
           V_VLICMSPART := GREATEST(V_VLBASEPARTDEST - P_VLPRODUTO, 0);
        end if;

        V_VLBASEPARTORIG := V_VLBASEPARTDEST;

        -- A ALIQUOTA DE ICMS É ZERADA SE O CLIENTE FOR ISENTO
        if P_CLIENTEISENTO = 'S'
        then
           P_ALIQOPERACAO := 0;
           P_PERCBASERED  := 0;
        end if;

        -- VALIDAR SE DEVERÁ REDUZIR A BASE DE CALCULO DE ORIGEM
        begin
           V_REDUZIRBASEDEST := not
                                 PARAMFILIAL.OBTERCOMOVARCHAR2('DESCONSREDBASEPARTDEST', P_CODFILIAL) = 'S';
        exception
           when others then
              V_REDUZIRBASEDEST := true;
        end;

        if not V_REDUZIRBASEDEST
        then
           P_PERCBASEREDDEST := 0;
        end if;

        if P_PERCBASEREDDEST > 0
        then
           V_VLBASEPARTDEST := V_VLBASEPARTDEST * P_PERCBASEREDDEST / 100;
           /*Trecho comentado pra resolução do chamado FIS-6501, pois a base de origem estava sendo calculado com o percentual
           de redução de base de destino*/
           --P_PERCBASERED := P_PERCBASEREDDEST;
        end if;

        if P_PERCBASERED > 0
        then
           V_VLBASEPARTORIG := V_VLBASEPARTORIG * P_PERCBASERED / 100;
        end if;

        -- Se figura destino for isento de ICMS, zera valores do destino
        -- Foi tirar o zeramento das variaveis de aliquota e valor de ICMS destino, conforme mudança
        --      da NT 2015.003 (vigente para 01/07/2017)
        -- Não gera grupo partilha se PCTRIBUT.ISENTAICMSPARTUFDESTORGAOPUB = S e orgão Publico = 'S'
        if (P_ISENTAICMSUFDEST = 'S') OR ((P_ISENTAICMSPARTUFDESTORGAOPUB = 'S') AND (P_ORGAOPUB = 'S'))
        then
           V_VLBASEPARTDEST  := 0;
           V_VLBASEPARTORIG  := 0;
           P_ALIQINTERNADEST := 0;
           P_ALIQFCP         := 0;
           V_VLICMSPART      := 0;
        end if;

        V_VLFCPPART      := V_VLBASEPARTDEST * P_ALIQFCP / 100;
        V_VLICMSPARTDEST := V_VLBASEPARTDEST * P_ALIQINTERNADEST / 100;
        V_VLICMSPARTREM  := V_VLBASEPARTORIG * P_ALIQINTERESTADUAL / 100;
        V_ANOOPER        := EXTRACT(year from P_DATAOPER);
        V_PERCPROVPART := case
                             when V_ANOOPER = 2016 then
                              40
                             when V_ANOOPER = 2017 then
                              60
                             when V_ANOOPER = 2018 then
                              80
                             when V_ANOOPER >= 2019 then
                              100
                             else
                              0
                          end;

        IF V_ANOOPER >= 2019 THEN
          V_VLICMSDIFALIQ  := (V_VLBASEPARTDEST * (P_ALIQINTERNADEST - P_ALIQINTERESTADUAL)) / 100;
        ELSE
          V_VLICMSDIFALIQ  := GREATEST(V_VLICMSPARTDEST - V_VLICMSPARTREM, 0);
        END IF;

        V_VLICMSPARTDEST := V_VLICMSDIFALIQ * V_PERCPROVPART / 100;
        V_VLICMSPARTREM  := V_VLICMSDIFALIQ - V_VLICMSPARTDEST;

        if NVL(P_ALIQOPERACAO, 0) <= 0
        then
           V_VLICMSPARTREM := 0;
        end if;

        select XMLELEMENT("retorno"
                          ,XMLELEMENT("aliqinterestadual"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(P_ALIQINTERESTADUAL
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("aliqinternadest"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(P_ALIQINTERNADEST
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("aliqfcp"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(P_ALIQFCP
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("percbasered"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(P_PERCBASERED
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("vlbasepartdest"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(V_VLBASEPARTDEST
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("vlicmspartrem"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(V_VLICMSPARTREM
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("vlfcppart"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(V_VLFCPPART
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("vlicmspartdest"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(V_VLICMSPARTDEST
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("percprovpart"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(V_PERCPROVPART
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("vlicmsdifaliq"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(V_VLICMSDIFALIQ
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("vlicmspart"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(V_VLICMSPART
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("percbasereddest"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(P_PERCBASEREDDEST
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("acrescaliqdesticmspart", P_ACRESCALIQDESTICMSPART)
                          ,XMLELEMENT("considerarcontribicmspart", P_CONSIDCONTRIB))

          into V_XMLRETORNO
          from DUAL;

        P_RETORNO := V_XMLRETORNO.GETSTRINGVAL();

     end;

     procedure F10_OBTER_PARTILHA_ICMS(P_CODFILIAL    in varchar2
                                      ,P_CODCLI       in number
                                      ,P_UFOPERCONSUM in varchar2
                                      ,P_UFENTREGA    in varchar2
                                      ,P_DATAOPER     in date
                                      ,P_VLPRODUTO    in number
                                      ,P_CODTRIBUT    in number
                                      ,P_CODPROD      in number
                                      ,P_CFOP         in number
                                      ,P_CST          in varchar2
                                      ,P_RETORNO      out varchar2
                                      ,P_CODMSG       out number
                                      ,P_MSG          out varchar2) is

        V_VLPRODUTO number;
        MSG_SUCESSO constant varchar2(30) := 'Partilha calculada com sucesso';
        MSG1        constant varchar2(55) := 'A filial da operação não foi informada ou é inexistente';
        MSG2        constant varchar2(33) := 'O cliente informado é inexistente';
        MSG3        constant varchar2(47) := 'A UF da operação a consumidor não foi informada';
        MSG4        constant varchar2(44) := 'A operação com o cliente não é interestadual';
        MSG5        constant varchar2(68) := 'O cliente informado não é consumidor final ou é contribuinte do ICMS';
        MSG6        constant varchar2(36) := 'A data da operação não foi informada';
        MSG7        constant varchar2(42) := 'O valor do produto deve ser maior que zero';
        MSG8        constant varchar2(47) := 'A tributação não foi informada ou é inexistente';
        MSG9        constant varchar2(67) := 'Não foi vinculada uma tributação para partilha de ICMS (rotina 514)';
        MSG10       constant varchar2(51) := 'O código do produto não foi informado ou é inválido';
        MSG11       constant varchar2(64) := 'A filial está definida como Simples Nacional e não partilha ICMS';
        MSG12       constant varchar2(67) := 'O cliente que representa a filial não foi definido ou é inexistente';
        MSG13       constant varchar2(35) := 'Cliente sem UF cadastrada';
        MSG14       constant varchar2(40) := 'CFOP do item não informado';
        MSG15       constant varchar2(40) := 'CST de ICMS do item não informado';
        MSG16       constant varchar2(60) := 'Produto não localizado na rotina 238(PCPRODFILIAL)';

        V_TRIBUT_NAO_LOCALIZADA       exception;
        V_TRIBPARTILHA_NAO_LOCALIZADA exception;

        V_CODCLIFILIAL      PCFILIAL.CODCLI%type;
        V_UFCLIENTE         PCCLIENT.ESTENT%type;
        V_CONSUMIDOR        PCCLIENT.CONSUMIDORFINAL%type;
        V_CONTRIBUINTE      PCCLIENT.CONTRIBUINTE%type;
        V_IECLIENTE         PCCLIENT.IEENT%type;
        V_UFFILIAL          PCFILIAL.UF%type;
        V_TIPOEMPRESA       PCCLIENT.TIPOEMPRESA%type;
        V_CLIENTEISENTOICMS PCCLIENT.ISENTOICMS%type;
        V_PESSOAFISICA      PCCLIENT.TIPOFJ%type;
        V_PERCBASERED       PCTRIBUT.PERCBASERED%type;
        V_IMPORTADO         PCPRODUT.IMPORTADO%type;
        V_SIMPLESNACIONAL   PCCLIENT.SIMPLESNACIONAL%type;
        V_ORGAOPUB          PCCLIENT.ORGAOPUB%type;

        V_PERCBASEREDST          PCTRIBUT.PERCBASEREDST%type;
        V_CONSIDCONTRIB          PCTRIBUT.CONSIDERARCONTRIBICMSPART%type;
        V_ACRESCALIQDESTICMSPART PCTRIBUT.ACRESCALIQDESTICMSPART%type;

        V_CLIENTEFONTEST PCCLIENT.CLIENTEFONTEST%type;
        V_EXCECAO        boolean;

        -- VALORES DA PCPRODFILIAL
        V_ORIGMERCTRIB PCPRODFILIAL.ORIGMERCTRIB%type;

        -- VALORES DA PARTILHA
        V_ALIQINTERESTADUAL PCTRIBUT.CODICM%type;
        V_ALIQOPERACAO      PCTRIBUT.CODICM%type;
        V_ALIQINTERNADEST   PCTRIBUT.CODICM%type;
        V_ALIQFCP           PCTRIBUT.PERACRESCIMOFUNCEP%type;
        V_ISENTAICMSUFDEST  PCTRIBUT.ISENTAICMSUFDEST%type;
        V_ISENTAICMSPARTUFDESTORGAOPUB PCTRIBUT.ISENTAICMSPARTUFDESTORGAOPUB%type;

        procedure F10_BUSCAR_ALIQUOTAS(P_TIPOEMPRESACLI         in varchar2
                                      ,P_PESSOAFISICA           in varchar2
                                      ,P_CONSUMIDORFINAL        in varchar2
                                      ,P_UFCLIENTE              in varchar2
                                      ,P_UFFILIAL               in varchar2
                                      ,P_CODST                  in number
                                      ,P_PRODIMPORTADO          in varchar2
                                      ,P_ALIQOPERACAO           out number
                                      ,P_ALIQINTERESTADUAL      out number
                                      ,P_ALIQINTERNADEST        out number
                                      ,P_ALIQFCP                out number
                                      ,P_PERCBASERED            out number
                                      ,P_PERCBASEREDDEST        out number
                                      ,P_CONSIDCONTRIB          out varchar2
                                      ,P_ACRESCALIQDESTICMSPART out varchar2
                                      ,P_ISENTAICMSUFDEST       out varchar2
                                      ,P_ISENTAICMSPARTUFDESTORGAOPUB out varchar2
                                      ,P_ORIGMERCTRIB           in varchar2) is

           V_UTILIZAPERCBASEREDPF  PCTRIBUT.UTILIZAPERCBASEREDPF%type;
           V_PERCBASEREDCONSUMIDOR PCTRIBUT.PERCBASEREDCONSUMIDOR%type;
        begin
           PKG_DEBUGGING_FWPC.LOG_MSG('VALIDANDO OS DADOS DA TRIBUTAÇÃO');

           begin
              select DECODE(P_TIPOEMPRESACLI
                           ,'PR'
                           ,NVL(T.CODICMPRODRURAL, NVL(T.CODICMPF, NVL(T.CODICM, 0)))
                           ,DECODE(P_PESSOAFISICA
                                  ,'S'
                                  ,NVL(T.CODICMPF, NVL(T.CODICM, 0))
                                  ,NVL(T.CODICM, 0))) as ALIQICMS
                    ,NVL(T.PERCBASERED, 0) PERCBASERED
                    ,T.PERCBASEREDCONSUMIDOR PERCBASEREDCONSUMIDOR
                    ,T.UTILIZAPERCBASEREDPF
                    ,NVL(T.CONSIDERARCONTRIBICMSPART, 'N')
                    ,NVL(T.ACRESCALIQDESTICMSPART, 'N')
                into P_ALIQOPERACAO
                    ,P_PERCBASERED
                    ,V_PERCBASEREDCONSUMIDOR
                    ,V_UTILIZAPERCBASEREDPF
                    ,P_CONSIDCONTRIB
                    ,P_ACRESCALIQDESTICMSPART
                from PCTRIBUT T
               where T.CODST = P_CODST;
           exception
              when NO_DATA_FOUND then
                 raise V_TRIBUT_NAO_LOCALIZADA;
           end;

           P_ALIQOPERACAO      := NVL(P_ALIQOPERACAO, 0);
           P_ALIQINTERESTADUAL := P_ALIQOPERACAO;
           if P_ALIQINTERESTADUAL <= 0
           then
              begin
                 P_ALIQINTERESTADUAL := NVL(PARAMFILIAL.OBTERCOMONUMBER('ALIQINTERORIGPART'
                                                                       ,P_CODFILIAL)
                                           ,12);
                 if P_UFFILIAL in ('MG', 'RJ', 'SP', 'PR', 'RS', 'SC')
                    and P_UFCLIENTE in ('MG', 'RJ', 'SP', 'PR', 'RS', 'SC')
                    and P_ALIQINTERESTADUAL > 4
                 then
                    P_ALIQINTERESTADUAL := 12;
                 end if;
              exception
                 when others then
                    null;
              end;

              if P_PRODIMPORTADO in ('S', 'D') and
                 P_ORIGMERCTRIB in ('1','2','3','8')
              then
                 begin
                    P_ALIQINTERESTADUAL := NVL(PARAMFILIAL.OBTERCOMONUMBER('ALIQINTERORIGIMPPART'
                                                                          ,P_CODFILIAL)
                                              ,4);
                 exception
                    when others then
                       P_ALIQINTERESTADUAL := 4;
                 end;
              end if;
           end if;

           -- Validar qual percentual de redução será utilizada
           if (P_CONSUMIDORFINAL = 'S')
              and (V_PERCBASEREDCONSUMIDOR is not null)
           then
              if (P_PESSOAFISICA = 'S')
                 and (PARAMFILIAL.OBTERCOMOVARCHAR2('CON_UTILIZAPERCBASEREDPF') = 'S')
                 and (V_UTILIZAPERCBASEREDPF = 'S')
              then
                 P_PERCBASERED := V_PERCBASEREDCONSUMIDOR;
              elsif (not P_PESSOAFISICA = 'S')
              then
                 P_PERCBASERED := V_PERCBASEREDCONSUMIDOR;
              else
                 P_PERCBASERED := 0;
              end if;
           end if;

           PKG_DEBUGGING_FWPC.LOG_MSG('VALIDANDO OS DADOS DA TRIBUTAÇÃO PARTILHA');
           begin
              select NVL(T.CODICM, 0) as ALIQICMSINTERNADEST
                    ,NVL(T.PERACRESCIMOFUNCEP, 0) as ALIQFCP
                    ,T.ISENTAICMSUFDEST
                    ,NVL(T.PERCBASERED, 0) PERCBASERED
                    ,T.PERCBASEREDCONSUMIDOR
                    ,NVL(T.UTILIZAPERCBASEREDPF, 'N')
                    ,T.ISENTAICMSPARTUFDESTORGAOPUB
                into P_ALIQINTERNADEST
                    ,P_ALIQFCP
                    ,P_ISENTAICMSUFDEST
                    ,P_PERCBASEREDDEST
                    ,V_PERCBASEREDCONSUMIDOR
                    ,V_UTILIZAPERCBASEREDPF
                    ,P_ISENTAICMSPARTUFDESTORGAOPUB
                from PCTRIBUTPARTILHA P
                    ,PCTRIBUT         T
               where P.CODSTPARTILHA = T.CODST
                 and P.CODST = P_CODST
                 and P.UF = P_UFCLIENTE;
           exception
              when NO_DATA_FOUND then
                 raise V_TRIBPARTILHA_NAO_LOCALIZADA;
           end;

           P_ALIQINTERESTADUAL := NVL(P_ALIQINTERESTADUAL, 0);
           P_ALIQINTERNADEST   := NVL(P_ALIQINTERNADEST, 0);
           P_ALIQFCP           := NVL(P_ALIQFCP, 0);
           P_PERCBASEREDDEST   := NVL(P_PERCBASEREDDEST, 0);

           -- Validar qual percentual de redução PF será utilizada
           if (P_CONSUMIDORFINAL = 'S')
              and (V_PERCBASEREDCONSUMIDOR is not null)
           then
              if (P_PESSOAFISICA = 'S')
                 and (PARAMFILIAL.OBTERCOMOVARCHAR2('CON_UTILIZAPERCBASEREDPF') = 'S')
                 and (V_UTILIZAPERCBASEREDPF = 'S')
              then
                 P_PERCBASEREDDEST := V_PERCBASEREDCONSUMIDOR;
              elsif (not P_PESSOAFISICA = 'S')
              then
                 P_PERCBASEREDDEST := V_PERCBASEREDCONSUMIDOR;
              else
                 P_PERCBASEREDDEST := 0;
              end if;
           end if;

        end;

     begin
        V_VLPRODUTO := P_VLPRODUTO;
        PKG_DEBUGGING_FWPC.LOG_MSG('VALIDANDO PARAMETROS DE ENTRADA');
        begin
           select UF
                 ,CODCLI
             into V_UFFILIAL
                 ,V_CODCLIFILIAL
             from PCFILIAL
            where CODIGO = NVL(P_CODFILIAL, 'XXX');
        exception
           when NO_DATA_FOUND then
              P_CODMSG := 1;
              P_MSG    := MSG1;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              return;
        end;

        begin
           select SIMPLESNACIONAL into V_SIMPLESNACIONAL from PCCLIENT where CODCLI = V_CODCLIFILIAL;
           if V_SIMPLESNACIONAL = 'S'
           then
              P_CODMSG := 11;
              P_MSG    := MSG11;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              -- Se o cliente for Simples Nacional, deve efetuar o calculo e obter as aliquotas
              -- considerando o valor do produto como zero.
              V_VLPRODUTO := 0;
           end if;
        exception
           when NO_DATA_FOUND then
              P_CODMSG := 12;
              P_MSG    := MSG12;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              return;
        end;

        if P_CODCLI > 0
        then
           begin
              select C.ESTENT as UF
                    ,NVL(C.CONSUMIDORFINAL, 'N') as CONSUMIDORFINAL
                    ,NVL(C.CONTRIBUINTE, 'N') as CONTRIBUINTE
                    ,C.TIPOEMPRESA
                    ,C.ISENTOICMS
                    ,DECODE(FERRAMENTAS.VERIFICAR_FJ(C.CODCLI), 'PESSOA FISICA', 'S', 'N') as PF
                    ,GERA_HISTORICO.SOMENTE_NUMERO(C.IEENT) as IE
                    ,CLIENTEFONTEST
                    ,CASE
                       WHEN (NVL(C.ORGAOPUBMUNICIPAL, 'N') = 'S') OR
                            (NVL(C.ORGAOPUB, 'N') = 'S') OR
                            (NVL(C.ORGAOPUBFEDERAL, 'N') = 'S') THEN
                         'S'
                       ELSE
                         'N'
                     END CLI_ORGAO_PUBLICO
                into V_UFCLIENTE
                    ,V_CONSUMIDOR
                    ,V_CONTRIBUINTE
                    ,V_TIPOEMPRESA
                    ,V_CLIENTEISENTOICMS
                    ,V_PESSOAFISICA
                    ,V_IECLIENTE
                    ,V_CLIENTEFONTEST
                    ,V_ORGAOPUB
                from PCCLIENT C
               where CODCLI = P_CODCLI;

              if V_UFCLIENTE is null
              then
                 P_CODMSG := 13;
                 P_MSG    := MSG13;
                 PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
                 return;
              end if;

           exception
              when NO_DATA_FOUND then
                 P_CODMSG := 2;
                 P_MSG    := MSG2;
                 PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
                 return;
           end;
        else
           V_UFCLIENTE  := trim(P_UFOPERCONSUM);
           V_CONSUMIDOR := 'S';
           if V_UFCLIENTE is null
           then
              P_CODMSG := 3;
              P_MSG    := MSG3;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              return;
           end if;
        end if;

        begin
           select IMPORTADO into V_IMPORTADO from PCPRODUT P where P.CODPROD = P_CODPROD;
        exception
           when NO_DATA_FOUND then
              P_CODMSG := 10;
              P_MSG    := MSG10;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              return;
        end;

        begin
           select ORIGMERCTRIB into V_ORIGMERCTRIB from PCPRODFILIAL P where P.CODPROD = P_CODPROD and P.CODFILIAL = P_CODFILIAL;
        exception
           when NO_DATA_FOUND then
              P_CODMSG := 16;
              P_MSG    := MSG16;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              return;
        end;

        V_UFCLIENTE := NVL(trim(P_UFENTREGA), V_UFCLIENTE);

        if V_UFCLIENTE = V_UFFILIAL
           or V_UFCLIENTE = 'EX'
        then
           P_CODMSG := 4;
           P_MSG    := MSG4;
           PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
           return;
        end if;

        if P_DATAOPER is null
        then
           P_CODMSG := 6;
           P_MSG    := MSG6;
           PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
           return;
        end if;
        if NVL(P_VLPRODUTO, 0) <= 0
        then
           P_CODMSG := 7;
           P_MSG    := MSG7;
           PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
           return;
        end if;

        PKG_DEBUGGING_FWPC.LOG_MSG('VALIDANDO EXCECAO DE ANP');
        if (not F10_ANPCALCULAR(P_CODPROD))
           and (P_DATAOPER >= TO_DATE('01/01/2016', 'DD/MM/YYYY'))
        then
           PKG_DEBUGGING_FWPC.LOG_MSG('EXCECAO DE ANP DO PRODUTO ' || TO_CHAR(P_CODPROD) ||
                                      ' SATISFEITA');
           P_CODMSG := 0;
           P_MSG    := MSG_SUCESSO;
           return;
        end if;

        PKG_DEBUGGING_FWPC.LOG_MSG('VALIDANDO EXCECAO DE CFOP');
        if NVL(P_CFOP, 0) = 0
        then
           P_CODMSG := 14;
           P_MSG    := MSG14;
           PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
           return;
        end if;
        V_EXCECAO := F10_CFOPEXCECAO(P_CFOP);
        if V_EXCECAO
        then
           PKG_DEBUGGING_FWPC.LOG_MSG('EXCECAO DE CFOP ' || TO_CHAR(P_CFOP) || ' SATISFEITA');
           P_CODMSG := 0;
           P_MSG    := MSG_SUCESSO;
           return;
        end if;

        PKG_DEBUGGING_FWPC.LOG_MSG('VALIDANDO EXCECAO DE CST');
        if trim(P_CST) is null
        then
           P_CODMSG := 15;
           P_MSG    := MSG15;
           PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
           return;
        end if;
        V_EXCECAO := F10_CSTEXCECAO(P_CST);
        if V_EXCECAO
        then
           PKG_DEBUGGING_FWPC.LOG_MSG('EXCECAO DE CST ' || P_CST || ' SATISFEITA');
           P_CODMSG := 0;
           P_MSG    := MSG_SUCESSO;
           return;
        end if;

        begin
           F10_BUSCAR_ALIQUOTAS(V_TIPOEMPRESA
                               ,V_PESSOAFISICA
                               ,V_CONSUMIDOR
                               ,V_UFCLIENTE
                               ,V_UFFILIAL
                               ,P_CODTRIBUT
                               ,V_IMPORTADO
                               ,V_ALIQOPERACAO /*OUT*/
                               ,V_ALIQINTERESTADUAL /*OUT*/
                               ,V_ALIQINTERNADEST /*OUT*/
                               ,V_ALIQFCP /*OUT*/
                               ,V_PERCBASERED /*OUT*/
                               ,V_PERCBASEREDST /*OUT*/
                               ,V_CONSIDCONTRIB /*OUT*/
                               ,V_ACRESCALIQDESTICMSPART /*OUT*/
                               ,V_ISENTAICMSUFDEST /*OUT*/
                               ,V_ISENTAICMSPARTUFDESTORGAOPUB /*OUT*/
                               ,V_ORIGMERCTRIB);

        exception
           when V_TRIBUT_NAO_LOCALIZADA then
              P_CODMSG := 8;
              P_MSG    := MSG8;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              return;
           when V_TRIBPARTILHA_NAO_LOCALIZADA then
              if V_CONSUMIDOR = 'N'
                 or V_CONTRIBUINTE = 'S'
              then
                 P_CODMSG := 5;
                 P_MSG    := MSG5;
                 PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
                 return;
              end if;
              P_CODMSG := 9;
              P_MSG    := MSG9;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              return;
        end;

        if V_CONSUMIDOR = 'N'
           or (V_CONTRIBUINTE = 'S' and V_CONSIDCONTRIB = 'N')
        then
           P_CODMSG := 5;
           P_MSG    := MSG5;
           PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
           return;
        end if;

        F10_CALCULAR_VALORES(P_CODFILIAL
                            ,V_VLPRODUTO
                            ,P_DATAOPER
                            ,V_CLIENTEISENTOICMS
                            ,V_ALIQOPERACAO
                            ,V_ALIQINTERESTADUAL
                            ,V_ALIQINTERNADEST
                            ,V_ALIQFCP
                            ,V_PERCBASERED
                            ,V_PERCBASEREDST
                            ,V_ACRESCALIQDESTICMSPART
                            ,V_CONSIDCONTRIB
                            ,V_CONTRIBUINTE
                            ,V_ISENTAICMSUFDEST
                            ,V_ISENTAICMSPARTUFDESTORGAOPUB
                            ,V_ORGAOPUB
                            ,P_RETORNO);
        P_CODMSG := 0;
        P_MSG    := MSG_SUCESSO;
     end;


   begin
     ICMSPARTILHA_CALCULAR_1_6(P_CODFILIAL,P_CODCLI,P_UFOPERCONSUM,P_UFENTREGA,P_DATAOPER,P_VLPRODUTO,P_CODTRIBUT,P_CODPROD,P_CFOP,P_VLPRODUTO, P_CST, P_RETORNO,P_CODMSG,P_MSG);
   --F10_OBTER_PARTILHA_ICMS(P_CODFILIAL,P_CODCLI,P_UFOPERCONSUM,P_UFENTREGA,P_DATAOPER,P_VLPRODUTO,P_CODTRIBUT,P_CODPROD,P_CFOP,P_CST,P_RETORNO,P_CODMSG,P_MSG);
   end;
  ---------------------------

     function F10_CALCULAR_BASEPART_FORA(P_VLPRODUTO              in number
                                        ,P_ALIQINTERESTADUAL      in number
                                        ,P_ALIQINTERNADEST        in number
                                        ,P_ALIQFCP                in number
                                        ,P_AGREGARVLOPER          in boolean
                                        ,P_ACRESCALIQDESTICMSPART in boolean
                                        ,P_ROTINA                 in varchar2) return number is
     begin
      V_VALORPRODUTO_ACRESCIDO := P_VLPRODUTO;

      PKG_DEBUGGING_FWPC.LOG_MSG('F10_CALCULAR_BASEPART_FORA: '||P_VLPRODUTO||
                                                ' P_ALIQINTERESTADUAL: '||P_ALIQINTERESTADUAL||
                                                ' P_ALIQINTERNADEST: '||P_ALIQINTERNADEST||
                                                ' P_ALIQFCP: '||P_ALIQFCP||
                                                ' P_AGREGARVLOPER: '|| CASE P_AGREGARVLOPER
                                                                         WHEN TRUE THEN 'TRUE'
                                                                         WHEN FALSE THEN 'FALSE'
                                                                         ELSE 'NULL'
                                                                       END ||
                                                ' P_ACRESCALIQDESTICMSPART: '||CASE P_ACRESCALIQDESTICMSPART
                                                                                 WHEN TRUE THEN 'TRUE'
                                                                                 WHEN FALSE THEN 'FALSE'
                                                                                 ELSE 'NULL'
                                                                               END||
                                                ' P_ROTINA: '||P_ROTINA);


        if nvl(P_ALIQINTERNADEST, 0) > 0  then
           if  P_AGREGARVLOPER
               or P_ACRESCALIQDESTICMSPART
           then
             if P_ACRESCALIQDESTICMSPART and
               not P_AGREGARVLOPER then

               return(P_VLPRODUTO * (1 - P_ALIQINTERESTADUAL / 100)
                       / ((100 - P_ALIQINTERNADEST - P_ALIQFCP) / 100));
             elsif P_ACRESCALIQDESTICMSPART and
                   P_AGREGARVLOPER then

                -- QUANDO A CHAMADA VEM DO DOCFISCAL NÃO HÁ NECESSIDADE DE FAZER O ACRESCIMO DO VALOR A BASE
                -- POIS O ACRESCIMO JÁ FOI CALCULADO E ESTÁ NO PREÇO DO PRODUTO.
                -- O VALOR 'X' REPRESENTA AS OUTRAS ROTINAS QUE SÃO VÁRIAS QUE CHAMAM O SERVIÇO DO DIFAL
                if P_ROTINA = 'X' then
                  V_VALORPRODUTO_ACRESCIDO := (P_VLPRODUTO /
                                   (1 + P_ALIQINTERESTADUAL / 100) /
                                   ((100 - P_ALIQINTERNADEST - P_ALIQFCP) / 100));

                  return(V_VALORPRODUTO_ACRESCIDO * (1 - P_ALIQINTERESTADUAL / 100)
                         / ((100 - P_ALIQINTERNADEST - P_ALIQFCP) / 100));

                else
                  return(P_VLPRODUTO * (1 - P_ALIQINTERESTADUAL / 100)
                         / ((100 - P_ALIQINTERNADEST - P_ALIQFCP) / 100));
                end if;
             elsif not P_ACRESCALIQDESTICMSPART and
                   P_AGREGARVLOPER then

                if P_ROTINA = 'X' then
                   V_VALORPRODUTO_ACRESCIDO := (P_VLPRODUTO /
                                    (1 + P_ALIQINTERESTADUAL / 100) /
                                    ((100 - P_ALIQINTERNADEST - P_ALIQFCP) / 100));
                else
                   V_VALORPRODUTO_ACRESCIDO := P_VLPRODUTO;
                end if;

                return(V_VALORPRODUTO_ACRESCIDO);
             else
                return(P_VLPRODUTO);

             end if;
            else
               return P_VLPRODUTO;
            end if;
        else
            return 0;
        end if;
     end;

  ---------------------------


   PROCEDURE ICMSPARTILHA_CALCULAR_1_6(P_CODFILIAL    in varchar2
                                    ,P_CODCLI       in number
                                    ,P_UFOPERCONSUM in varchar2
                                    ,P_UFENTREGA    in varchar2
                                    ,P_DATAOPER     in date
                                    ,P_VLPRODUTO    in number
                                    ,P_CODTRIBUT    in number
                                    ,P_CODPROD      in number
                                    ,P_CFOP         in number
                                    ,P_BASEICMS     in number
                                    ,P_CST          in varchar2
                                    ,P_RETORNO      out varchar2
                                    ,P_CODMSG       out number
                                    ,P_MSG          out varchar2) is
  --variaveis output

     function F10_ANPCALCULAR(PCODPROD in number) return boolean is
        QT number(2);
     begin
        select count(1)
          into QT
          from PCPRODUT
         where CODPROD = PCODPROD
           and (ANP is null or ANP in (select I.VALOR
                                         from PCEXCECAOITEM I
                                         join PCEXCECAOTIPO T on I.CODTIPOEXCECAO = T.CODIGO
                                         join PCEXCECAODOCFISCAL D on I.CODEXCECAO = D.CODIGO
                                         join PCEXCECAOCATEGORIZACAO C on C.CODIGO = D.CODCATEGORIA
                                        where T.DESCRICAO = 'ANP'
                                          and C.ACAO = 'C'));
        return QT > 0;
     end;

     function F10_CFOPEXCECAO(PCFOP in number) return boolean is
        QT number(2);
     begin
        QT := 0;
        if PCFOP > 0
        then
           select count(1)
             into QT
             from PCEXCECAOITEM I
             join PCEXCECAOTIPO T on I.CODTIPOEXCECAO = T.CODIGO
             join PCEXCECAODOCFISCAL D on I.CODEXCECAO = D.CODIGO
             join PCEXCECAOCATEGORIZACAO C on C.CODIGO = D.CODCATEGORIA
            where T.DESCRICAO = 'CFOP'
              and I.VALOR = TO_CHAR(PCFOP)
              and C.ACAO = 'D';
        end if;

        return QT > 0;
     end;

     function F10_CSTEXCECAO(PCST in varchar2) return boolean is
        QT number(2);
     begin
        QT := 0;
        if trim(PCST) is not null
        then
           select count(1)
             into QT
             from PCEXCECAOITEM I
             join PCEXCECAOTIPO T on I.CODTIPOEXCECAO = T.CODIGO
             join PCEXCECAODOCFISCAL D on I.CODEXCECAO = D.CODIGO
             join PCEXCECAOCATEGORIZACAO C on C.CODIGO = D.CODCATEGORIA
            where T.DESCRICAO = 'CST'
              and I.VALOR = PCST
              and C.ACAO = 'D';
        end if;

        return QT > 0;
     end;

     procedure F10_CALCULAR_VALORES(P_CODFILIAL              in varchar2
                                   ,P_VLPRODUTO              in number
                                   ,P_DATAOPER               in date
                                   ,P_CLIENTEISENTO          in varchar2
                                   ,P_ALIQOPERACAO           in out number
                                   ,P_ALIQINTERESTADUAL      in number
                                   ,P_ALIQINTERNADEST        in out number
                                   ,P_ALIQFCP                in out number
                                   ,P_PERCBASERED            in out number
                                   ,P_PERCBASEREDDEST        in out number
                                   ,P_ACRESCALIQDESTICMSPART in varchar2
                                   ,P_CONSIDCONTRIB          in varchar2
                                   ,P_CONTRIBUINTE           in varchar2
                                   ,P_ISENTAICMSUFDEST       in varchar2
                                   ,P_ISENTAICMSPARTUFDESTORGAOPUB in varchar2
                                   ,P_ORGAOPUB               in varchar2
                                   ,P_BASEICMS               in number
                                   ,P_RETORNO                out varchar2) is
        V_VLICMSPARTREM   number(22, 10);
        V_VLBASEPARTDEST  number(22, 10);
        V_VLFCPPART       number(22, 10);
        V_VLICMSPARTDEST  number(22, 10);
        V_PERCPROVPART    number(22, 6);
        V_VLICMSDIFALIQ   number(22, 10);
        V_VLICMSPART      number(22, 10);
        V_ANOOPER         number(4);
        V_XMLRETORNO      XMLTYPE;
        V_AGREGARVLOPER   boolean;
        V_REDUZIRBASEDEST boolean;

        V_VLBASEPARTORIG number(22, 10);

     begin
        PKG_DEBUGGING_FWPC.LOG_MSG('CALCULANDO PARTILHA DE ICMS');
        V_AGREGARVLOPER := NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('ACRESCICMSPARTILHAPRECO', P_CODFILIAL)
                              ,'N') = 'S';

        V_VLICMSPART     := 0;
        V_VLBASEPARTDEST := F10_CALCULAR_BASEPART_FORA(P_VLPRODUTO
                                                      ,P_ALIQINTERESTADUAL
                                                      ,P_ALIQINTERNADEST
                                                      ,P_ALIQFCP
                                                      ,V_AGREGARVLOPER
                                                      ,P_ACRESCALIQDESTICMSPART = 'S'
                                                      ,'X');

        if V_AGREGARVLOPER
        then
           V_VLICMSPART := GREATEST(V_VALORPRODUTO_ACRESCIDO - P_VLPRODUTO, 0);
        end if;

        V_VLBASEPARTORIG := V_VLBASEPARTDEST;

        -- A ALIQUOTA DE ICMS É ZERADA SE O CLIENTE FOR ISENTO
        if P_CLIENTEISENTO = 'S'
        then
           P_ALIQOPERACAO := 0;
           P_PERCBASERED  := 0;
        end if;

        -- VALIDAR SE DEVERÁ REDUZIR A BASE DE CALCULO DE ORIGEM
        begin
           V_REDUZIRBASEDEST := not
                                 PARAMFILIAL.OBTERCOMOVARCHAR2('DESCONSREDBASEPARTDEST', P_CODFILIAL) = 'S';
        exception
           when others then
              V_REDUZIRBASEDEST := true;
        end;

        if not V_REDUZIRBASEDEST
        then
           P_PERCBASEREDDEST := 0;
        end if;

        if P_PERCBASEREDDEST > 0
        then
           V_VLBASEPARTDEST := V_VLBASEPARTDEST * P_PERCBASEREDDEST / 100;
           /*Trecho comentado pra resolução do chamado FIS-6501, pois a base de origem estava sendo calculado com o percentual
           de redução de base de destino*/
           --P_PERCBASERED := P_PERCBASEREDDEST;
        end if;

        if P_PERCBASERED > 0
        then
           V_VLBASEPARTORIG := V_VLBASEPARTORIG * P_PERCBASERED / 100;
        end if;

        -- Se figura destino for isento de ICMS, zera valores do destino
        -- Foi tirar o zeramento das variaveis de aliquota e valor de ICMS destino, conforme mudança
        --      da NT 2015.003 (vigente para 01/07/2017)
        -- Não gera grupo partilha se PCTRIBUT.ISENTAICMSPARTUFDESTORGAOPUB = S e orgão Publico = 'S'
        if (P_ISENTAICMSUFDEST = 'S') OR ((P_ISENTAICMSPARTUFDESTORGAOPUB = 'S') AND (P_ORGAOPUB = 'S'))
        then
           V_VLBASEPARTDEST  := 0;
           V_VLBASEPARTORIG  := 0;
           P_ALIQINTERNADEST := 0;
           P_ALIQFCP         := 0;
           V_VLICMSPART      := 0;
        end if;

        V_VLFCPPART      := V_VLBASEPARTDEST * P_ALIQFCP / 100;
        V_VLICMSPARTDEST := V_VLBASEPARTDEST * P_ALIQINTERNADEST / 100;
        V_VLICMSPARTREM  := V_VLBASEPARTORIG * P_ALIQINTERESTADUAL / 100;
        V_ANOOPER        := EXTRACT(year from P_DATAOPER);
        V_PERCPROVPART := case
                             when V_ANOOPER = 2016 then
                              40
                             when V_ANOOPER = 2017 then
                              60
                             when V_ANOOPER = 2018 then
                              80
                             when V_ANOOPER >= 2019 then
                              100
                             else
                              0
                          end;

        IF V_ANOOPER >= 2019 THEN
          IF (P_BASEICMS > 0) THEN
            IF (ROUND(P_BASEICMS,2) < ROUND(P_VLPRODUTO,2)) THEN
              --anterior
              V_VLICMSDIFALIQ  := (V_VLBASEPARTDEST * (P_ALIQINTERNADEST - P_ALIQINTERESTADUAL)) / 100;
            ELSE
              IF (V_VALORPRODUTO_ACRESCIDO <> P_VLPRODUTO) THEN
                 IF (P_BASEICMS <> V_VLBASEPARTDEST) AND (P_CST = '00') THEN
                     V_VLICMSDIFALIQ := ((V_VLBASEPARTDEST * P_ALIQINTERNADEST) - (P_ALIQINTERESTADUAL * P_BASEICMS)) / 100;
                 ELSE
                    V_VLICMSDIFALIQ := ((V_VLBASEPARTDEST * P_ALIQINTERNADEST) - (P_ALIQINTERESTADUAL * V_VALORPRODUTO_ACRESCIDO)) / 100;
                END IF;
              ELSE
                V_VLICMSDIFALIQ := ((V_VLBASEPARTDEST * P_ALIQINTERNADEST) - (P_ALIQINTERESTADUAL * P_BASEICMS)) / 100;
              END IF;
            END IF;
          ELSE
            --anterior
            V_VLICMSDIFALIQ  := (V_VLBASEPARTDEST * (P_ALIQINTERNADEST - P_ALIQINTERESTADUAL)) / 100;
          END IF;
        END IF;

        --Regra  NT 2020.005 - v1.20 - NA15-10 Rej. 815
        IF V_VLICMSDIFALIQ < 0 THEN
          V_VLICMSDIFALIQ := 0;
        END IF;


        V_VLICMSPARTDEST := V_VLICMSDIFALIQ * V_PERCPROVPART / 100;
        V_VLICMSPARTREM  := V_VLICMSDIFALIQ - V_VLICMSPARTDEST;

        if NVL(P_ALIQOPERACAO, 0) <= 0
        then
           V_VLICMSPARTREM := 0;
        end if;

        select XMLELEMENT("retorno"
                          ,XMLELEMENT("aliqinterestadual"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(P_ALIQINTERESTADUAL
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("aliqinternadest"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(P_ALIQINTERNADEST
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("aliqfcp"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(P_ALIQFCP
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("percbasered"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(P_PERCBASERED
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("vlbasepartdest"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(V_VLBASEPARTDEST
                                                              ,'FM999999999999D9999999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("vlicmspartrem"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(V_VLICMSPARTREM
                                                              ,'FM999999999999D9999999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("vlfcppart"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(V_VLFCPPART
                                                              ,'FM999999999999D9999999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("vlicmspartdest"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(V_VLICMSPARTDEST
                                                              ,'FM999999999999D9999999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("percprovpart"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(V_PERCPROVPART
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("vlicmsdifaliq"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(V_VLICMSDIFALIQ
                                                              ,'FM999999999999D9999999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("vlicmspart"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(V_VLICMSPART
                                                              ,'FM999999999999D9999999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("percbasereddest"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(P_PERCBASEREDDEST
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("acrescaliqdesticmspart", P_ACRESCALIQDESTICMSPART)
                          ,XMLELEMENT("considerarcontribicmspart", P_CONSIDCONTRIB))

          into V_XMLRETORNO
          from DUAL;

        P_RETORNO := V_XMLRETORNO.GETSTRINGVAL();

     end;

     procedure F10_OBTER_PARTILHA_ICMS(P_CODFILIAL    in varchar2
                                      ,P_CODCLI       in number
                                      ,P_UFOPERCONSUM in varchar2
                                      ,P_UFENTREGA    in varchar2
                                      ,P_DATAOPER     in date
                                      ,P_VLPRODUTO    in number
                                      ,P_CODTRIBUT    in number
                                      ,P_CODPROD      in number
                                      ,P_CFOP         in number
                                      ,P_BASEICMS     in number
                                      ,P_CST          in varchar2
                                      ,P_RETORNO      out varchar2
                                      ,P_CODMSG       out number
                                      ,P_MSG          out varchar2) is

        V_VLPRODUTO number;
        MSG_SUCESSO constant varchar2(30) := 'Partilha calculada com sucesso';
        MSG1        constant varchar2(55) := 'A filial da operação não foi informada ou é inexistente';
        MSG2        constant varchar2(33) := 'O cliente informado é inexistente';
        MSG3        constant varchar2(47) := 'A UF da operação a consumidor não foi informada';
        MSG4        constant varchar2(44) := 'A operação com o cliente não é interestadual';
        MSG5        constant varchar2(68) := 'O cliente informado não é consumidor final ou é contribuinte do ICMS';
        MSG6        constant varchar2(36) := 'A data da operação não foi informada';
        MSG7        constant varchar2(42) := 'O valor do produto deve ser maior que zero';
        MSG8        constant varchar2(47) := 'A tributação não foi informada ou é inexistente';
        MSG9        constant varchar2(67) := 'Não foi vinculada uma tributação para partilha de ICMS (rotina 514)';
        MSG10       constant varchar2(51) := 'O código do produto não foi informado ou é inválido';
        MSG11       constant varchar2(64) := 'A filial está definida como Simples Nacional e não partilha ICMS';
        MSG12       constant varchar2(67) := 'O cliente que representa a filial não foi definido ou é inexistente';
        MSG13       constant varchar2(35) := 'Cliente sem UF cadastrada';
        MSG14       constant varchar2(40) := 'CFOP do item não informado';
        MSG15       constant varchar2(40) := 'CST de ICMS do item não informado';
        MSG16       constant varchar2(60) := 'Produto não localizado na rotina 238(PCPRODFILIAL)';
        MSG17       constant varchar2(33) := 'Base ICMS não pode ser nulo';
        MSG18       constant varchar2(83) := 'Produto contém registro ANP, verifique se contém exceção cadastrada na rotina 4006';

        V_TRIBUT_NAO_LOCALIZADA       exception;
        V_TRIBPARTILHA_NAO_LOCALIZADA exception;

        V_CODCLIFILIAL      PCFILIAL.CODCLI%type;
        V_UFCLIENTE         PCCLIENT.ESTENT%type;
        V_CONSUMIDOR        PCCLIENT.CONSUMIDORFINAL%type;
        V_CONTRIBUINTE      PCCLIENT.CONTRIBUINTE%type;
        V_IECLIENTE         PCCLIENT.IEENT%type;
        V_UFFILIAL          PCFILIAL.UF%type;
        V_TIPOEMPRESA       PCCLIENT.TIPOEMPRESA%type;
        V_CLIENTEISENTOICMS PCCLIENT.ISENTOICMS%type;
        V_PESSOAFISICA      PCCLIENT.TIPOFJ%type;
        V_PERCBASERED       PCTRIBUT.PERCBASERED%type;
        V_IMPORTADO         PCPRODUT.IMPORTADO%type;
        V_SIMPLESNACIONAL   PCCLIENT.SIMPLESNACIONAL%type;
        V_ORGAOPUB          PCCLIENT.ORGAOPUB%type;

        V_PERCBASEREDST          PCTRIBUT.PERCBASEREDST%type;
        V_CONSIDCONTRIB          PCTRIBUT.CONSIDERARCONTRIBICMSPART%type;
        V_ACRESCALIQDESTICMSPART PCTRIBUT.ACRESCALIQDESTICMSPART%type;

        V_CLIENTEFONTEST PCCLIENT.CLIENTEFONTEST%type;
        V_EXCECAO        boolean;

        -- VALORES DA PCPRODFILIAL
        V_ORIGMERCTRIB PCPRODFILIAL.ORIGMERCTRIB%type;

        -- VALORES DA PARTILHA
        V_ALIQINTERESTADUAL PCTRIBUT.CODICM%type;
        V_ALIQOPERACAO      PCTRIBUT.CODICM%type;
        V_ALIQINTERNADEST   PCTRIBUT.CODICM%type;
        V_ALIQFCP           PCTRIBUT.PERACRESCIMOFUNCEP%type;
        V_ISENTAICMSUFDEST  PCTRIBUT.ISENTAICMSUFDEST%type;
        V_ISENTAICMSPARTUFDESTORGAOPUB PCTRIBUT.ISENTAICMSPARTUFDESTORGAOPUB%type;

        procedure F10_BUSCAR_ALIQUOTAS(P_TIPOEMPRESACLI         in varchar2
                                      ,P_PESSOAFISICA           in varchar2
                                      ,P_CONSUMIDORFINAL        in varchar2
                                      ,P_UFCLIENTE              in varchar2
                                      ,P_UFFILIAL               in varchar2
                                      ,P_CODST                  in number
                                      ,P_PRODIMPORTADO          in varchar2
                                      ,P_ALIQOPERACAO           out number
                                      ,P_ALIQINTERESTADUAL      out number
                                      ,P_ALIQINTERNADEST        out number
                                      ,P_ALIQFCP                out number
                                      ,P_PERCBASERED            out number
                                      ,P_PERCBASEREDDEST        out number
                                      ,P_CONSIDCONTRIB          out varchar2
                                      ,P_ACRESCALIQDESTICMSPART out varchar2
                                      ,P_ISENTAICMSUFDEST       out varchar2
                                      ,P_ISENTAICMSPARTUFDESTORGAOPUB out varchar2
                                      ,P_ORIGMERCTRIB           in varchar2) is

           V_UTILIZAPERCBASEREDPF  PCTRIBUT.UTILIZAPERCBASEREDPF%type;
           V_PERCBASEREDCONSUMIDOR PCTRIBUT.PERCBASEREDCONSUMIDOR%type;
        begin
           PKG_DEBUGGING_FWPC.LOG_MSG('VALIDANDO OS DADOS DA TRIBUTAÇÃO');

           begin
              select DECODE(P_TIPOEMPRESACLI
                           ,'PR'
                           ,NVL(T.CODICMPRODRURAL, NVL(T.CODICMPF, NVL(T.CODICM, 0)))
                           ,DECODE(P_PESSOAFISICA
                                  ,'S'
                                  ,NVL(T.CODICMPF, NVL(T.CODICM, 0))
                                  ,NVL(T.CODICM, 0))) as ALIQICMS
                    ,NVL(T.PERCBASERED, 0) PERCBASERED
                    ,T.PERCBASEREDCONSUMIDOR PERCBASEREDCONSUMIDOR
                    ,T.UTILIZAPERCBASEREDPF
                    ,NVL(T.CONSIDERARCONTRIBICMSPART, 'N')
                    ,NVL(T.ACRESCALIQDESTICMSPART, 'N')
                into P_ALIQOPERACAO
                    ,P_PERCBASERED
                    ,V_PERCBASEREDCONSUMIDOR
                    ,V_UTILIZAPERCBASEREDPF
                    ,P_CONSIDCONTRIB
                    ,P_ACRESCALIQDESTICMSPART
                from PCTRIBUT T
               where T.CODST = P_CODST;
           exception
              when NO_DATA_FOUND then
                 raise V_TRIBUT_NAO_LOCALIZADA;
           end;

           P_ALIQOPERACAO      := NVL(P_ALIQOPERACAO, 0);
           P_ALIQINTERESTADUAL := P_ALIQOPERACAO;
           if P_ALIQINTERESTADUAL <= 0
           then
              begin
                 P_ALIQINTERESTADUAL := NVL(PARAMFILIAL.OBTERCOMONUMBER('ALIQINTERORIGPART'
                                                                       ,P_CODFILIAL)
                                           ,12);
                 if P_UFFILIAL in ('MG', 'RJ', 'SP', 'PR', 'RS', 'SC')
                    and P_UFCLIENTE in ('MG', 'RJ', 'SP', 'PR', 'RS', 'SC')
                    and P_ALIQINTERESTADUAL > 4
                 then
                    P_ALIQINTERESTADUAL := 12;
                 end if;
              exception
                 when others then
                    null;
              end;

              if P_PRODIMPORTADO in ('S', 'D') and
                 P_ORIGMERCTRIB in ('1','2','3','8')
              then
                 begin
                    P_ALIQINTERESTADUAL := NVL(PARAMFILIAL.OBTERCOMONUMBER('ALIQINTERORIGIMPPART'
                                                                          ,P_CODFILIAL)
                                              ,4);
                 exception
                    when others then
                       P_ALIQINTERESTADUAL := 4;
                 end;
              end if;
           end if;

           -- Validar qual percentual de redução será utilizada
           if (P_CONSUMIDORFINAL = 'S')
              and (V_PERCBASEREDCONSUMIDOR is not null)
           then
              if (P_PESSOAFISICA = 'S')
                 and (PARAMFILIAL.OBTERCOMOVARCHAR2('CON_UTILIZAPERCBASEREDPF') = 'S')
                 and (V_UTILIZAPERCBASEREDPF = 'S')
              then
                 P_PERCBASERED := V_PERCBASEREDCONSUMIDOR;
              elsif (not P_PESSOAFISICA = 'S')
              then
                 P_PERCBASERED := V_PERCBASEREDCONSUMIDOR;
              else
                 P_PERCBASERED := 0;
              end if;
           end if;

           PKG_DEBUGGING_FWPC.LOG_MSG('VALIDANDO OS DADOS DA TRIBUTAÇÃO PARTILHA');
           begin
              select NVL(T.CODICM, 0) as ALIQICMSINTERNADEST
                    ,NVL(T.PERACRESCIMOFUNCEP, 0) as ALIQFCP
                    ,T.ISENTAICMSUFDEST
                    ,NVL(T.PERCBASERED, 0) PERCBASERED
                    ,T.PERCBASEREDCONSUMIDOR
                    ,NVL(T.UTILIZAPERCBASEREDPF, 'N')
                    ,T.ISENTAICMSPARTUFDESTORGAOPUB
                into P_ALIQINTERNADEST
                    ,P_ALIQFCP
                    ,P_ISENTAICMSUFDEST
                    ,P_PERCBASEREDDEST
                    ,V_PERCBASEREDCONSUMIDOR
                    ,V_UTILIZAPERCBASEREDPF
                    ,P_ISENTAICMSPARTUFDESTORGAOPUB
                from PCTRIBUTPARTILHA P
                    ,PCTRIBUT         T
               where P.CODSTPARTILHA = T.CODST
                 and P.CODST = P_CODST
                 and P.UF = P_UFCLIENTE;
           exception
              when NO_DATA_FOUND then
                 raise V_TRIBPARTILHA_NAO_LOCALIZADA;
           end;

           P_ALIQINTERESTADUAL := NVL(P_ALIQINTERESTADUAL, 0);
           P_ALIQINTERNADEST   := NVL(P_ALIQINTERNADEST, 0);
           P_ALIQFCP           := NVL(P_ALIQFCP, 0);
           P_PERCBASEREDDEST   := NVL(P_PERCBASEREDDEST, 0);

           -- Validar qual percentual de redução PF será utilizada
         /*  if (P_CONSUMIDORFINAL = 'S')
              and (V_PERCBASEREDCONSUMIDOR is not null)
           then
              if (P_PESSOAFISICA = 'S')
                 and (PARAMFILIAL.OBTERCOMOVARCHAR2('CON_UTILIZAPERCBASEREDPF') = 'S')
                 and (V_UTILIZAPERCBASEREDPF = 'S')
              then
                 P_PERCBASEREDDEST := V_PERCBASEREDCONSUMIDOR;
              elsif (not P_PESSOAFISICA = 'S')
              then
                 P_PERCBASEREDDEST := V_PERCBASEREDCONSUMIDOR;
              else
                 P_PERCBASEREDDEST := 0;
              end if;
           end if;*/

        end;

     begin
        V_VLPRODUTO := P_VLPRODUTO;
        PKG_DEBUGGING_FWPC.LOG_MSG('VALIDANDO PARAMETROS DE ENTRADA');
        begin
           select UF
                 ,CODCLI
             into V_UFFILIAL
                 ,V_CODCLIFILIAL
             from PCFILIAL
            where CODIGO = NVL(P_CODFILIAL, 'XXX');
        exception
           when NO_DATA_FOUND then
              P_CODMSG := 1;
              P_MSG    := MSG1;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              return;
        end;

        begin
           select SIMPLESNACIONAL into V_SIMPLESNACIONAL from PCCLIENT where CODCLI = V_CODCLIFILIAL;
           if V_SIMPLESNACIONAL = 'S'
           then
              P_CODMSG := 11;
              P_MSG    := MSG11;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              -- Se o cliente for Simples Nacional, deve efetuar o calculo e obter as aliquotas
              -- considerando o valor do produto como zero.
              V_VLPRODUTO := 0;
           end if;
        exception
           when NO_DATA_FOUND then
              P_CODMSG := 12;
              P_MSG    := MSG12;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              return;
        end;

        if P_CODCLI > 0
        then
           begin
              select C.ESTENT as UF
                    ,NVL(C.CONSUMIDORFINAL, 'N') as CONSUMIDORFINAL
                    ,NVL(C.CONTRIBUINTE, 'N') as CONTRIBUINTE
                    ,C.TIPOEMPRESA
                    ,C.ISENTOICMS
                    ,DECODE(FERRAMENTAS.VERIFICAR_FJ(C.CODCLI), 'PESSOA FISICA', 'S', 'N') as PF
                    ,GERA_HISTORICO.SOMENTE_NUMERO(C.IEENT) as IE
                    ,CLIENTEFONTEST
                    ,CASE
                       WHEN (NVL(C.ORGAOPUBMUNICIPAL, 'N') = 'S') OR
                            (NVL(C.ORGAOPUB, 'N') = 'S') OR
                            (NVL(C.ORGAOPUBFEDERAL, 'N') = 'S') THEN
                         'S'
                       ELSE
                         'N'
                     END CLI_ORGAO_PUBLICO
                into V_UFCLIENTE
                    ,V_CONSUMIDOR
                    ,V_CONTRIBUINTE
                    ,V_TIPOEMPRESA
                    ,V_CLIENTEISENTOICMS
                    ,V_PESSOAFISICA
                    ,V_IECLIENTE
                    ,V_CLIENTEFONTEST
                    ,V_ORGAOPUB
                from PCCLIENT C
               where CODCLI = P_CODCLI;

              if V_UFCLIENTE is null
              then
                 P_CODMSG := 13;
                 P_MSG    := MSG13;
                 PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
                 return;
              end if;

           exception
              when NO_DATA_FOUND then
                 P_CODMSG := 2;
                 P_MSG    := MSG2;
                 PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
                 return;
           end;
        else
           V_UFCLIENTE  := trim(P_UFOPERCONSUM);
           V_CONSUMIDOR := 'S';
           if V_UFCLIENTE is null
           then
              P_CODMSG := 3;
              P_MSG    := MSG3;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              return;
           end if;
        end if;

        begin
           select IMPORTADO into V_IMPORTADO from PCPRODUT P where P.CODPROD = P_CODPROD;
        exception
           when NO_DATA_FOUND then
              P_CODMSG := 10;
              P_MSG    := MSG10;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              return;
        end;

        begin
           select ORIGMERCTRIB into V_ORIGMERCTRIB from PCPRODFILIAL P where P.CODPROD = P_CODPROD and P.CODFILIAL = P_CODFILIAL;
        exception
           when NO_DATA_FOUND then
              P_CODMSG := 16;
              P_MSG    := MSG16;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              return;
        end;

        V_UFCLIENTE := NVL(trim(P_UFENTREGA), V_UFCLIENTE);

        if V_UFCLIENTE = V_UFFILIAL
           or V_UFCLIENTE = 'EX'
        then
           P_CODMSG := 4;
           P_MSG    := MSG4;
           PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
           return;
        end if;

        if P_DATAOPER is null
        then
           P_CODMSG := 6;
           P_MSG    := MSG6;
           PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
           return;
        end if;
        if NVL(P_VLPRODUTO, 0) <= 0
        then
           P_CODMSG := 7;
           P_MSG    := MSG7;
           PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
           return;
        end if;

        PKG_DEBUGGING_FWPC.LOG_MSG('VALIDANDO EXCECAO DE ANP');
        if (not F10_ANPCALCULAR(P_CODPROD))
           and (P_DATAOPER >= TO_DATE('01/01/2016', 'DD/MM/YYYY'))
        then
           PKG_DEBUGGING_FWPC.LOG_MSG('EXCECAO DE ANP DO PRODUTO ' || TO_CHAR(P_CODPROD) ||
                                      'NÃO SATISFEITA');
           P_CODMSG := 18;
           P_MSG    := MSG18;
           return;
        end if;

        PKG_DEBUGGING_FWPC.LOG_MSG('VALIDANDO EXCECAO DE CFOP');
        if NVL(P_CFOP, 0) = 0
        then
           P_CODMSG := 14;
           P_MSG    := MSG14;
           PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
           return;
        end if;
        V_EXCECAO := F10_CFOPEXCECAO(P_CFOP);
        if V_EXCECAO
        then
           PKG_DEBUGGING_FWPC.LOG_MSG('EXCECAO DE CFOP ' || TO_CHAR(P_CFOP) || ' SATISFEITA');
           P_CODMSG := 0;
           P_MSG    := MSG_SUCESSO;
           return;
        end if;

        PKG_DEBUGGING_FWPC.LOG_MSG('VALIDANDO EXCECAO DE CST');
        if trim(P_CST) is null
        then
           P_CODMSG := 15;
           P_MSG    := MSG15;
           PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
           return;
        end if;
        V_EXCECAO := F10_CSTEXCECAO(P_CST);
        if V_EXCECAO
        then
           PKG_DEBUGGING_FWPC.LOG_MSG('EXCECAO DE CST ' || P_CST || ' SATISFEITA');
           P_CODMSG := 0;
           P_MSG    := MSG_SUCESSO;
           return;
        end if;

        if P_BASEICMS is null
        then
           PKG_DEBUGGING_FWPC.LOG_MSG('Produto: ' || TO_CHAR(P_CODPROD) || ' sem Base de ICMS');
           P_CODMSG := 17;
           P_MSG    := MSG17;
           return;
        end if;

        begin
           F10_BUSCAR_ALIQUOTAS(V_TIPOEMPRESA
                               ,V_PESSOAFISICA
                               ,V_CONSUMIDOR
                               ,V_UFCLIENTE
                               ,V_UFFILIAL
                               ,P_CODTRIBUT
                               ,V_IMPORTADO
                               ,V_ALIQOPERACAO /*OUT*/
                               ,V_ALIQINTERESTADUAL /*OUT*/
                               ,V_ALIQINTERNADEST /*OUT*/
                               ,V_ALIQFCP /*OUT*/
                               ,V_PERCBASERED /*OUT*/
                               ,V_PERCBASEREDST /*OUT*/
                               ,V_CONSIDCONTRIB /*OUT*/
                               ,V_ACRESCALIQDESTICMSPART /*OUT*/
                               ,V_ISENTAICMSUFDEST /*OUT*/
                               ,V_ISENTAICMSPARTUFDESTORGAOPUB /*OUT*/
                               ,V_ORIGMERCTRIB);

        exception
           when V_TRIBUT_NAO_LOCALIZADA then
              P_CODMSG := 8;
              P_MSG    := MSG8;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              return;
           when V_TRIBPARTILHA_NAO_LOCALIZADA then
              if V_CONSUMIDOR = 'N'
                 or V_CONTRIBUINTE = 'S'
              then
                 P_CODMSG := 5;
                 P_MSG    := MSG5;
                 PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
                 return;
              end if;
              P_CODMSG := 9;
              P_MSG    := MSG9;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              return;
        end;

        if V_CONSUMIDOR = 'N'
           or (V_CONTRIBUINTE = 'S' and V_CONSIDCONTRIB = 'N')
        then
           P_CODMSG := 5;
           P_MSG    := MSG5;
           PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
           return;
        end if;

        F10_CALCULAR_VALORES(P_CODFILIAL
                            ,V_VLPRODUTO
                            ,P_DATAOPER
                            ,V_CLIENTEISENTOICMS
                            ,V_ALIQOPERACAO
                            ,V_ALIQINTERESTADUAL
                            ,V_ALIQINTERNADEST
                            ,V_ALIQFCP
                            ,V_PERCBASERED
                            ,V_PERCBASEREDST
                            ,V_ACRESCALIQDESTICMSPART
                            ,V_CONSIDCONTRIB
                            ,V_CONTRIBUINTE
                            ,V_ISENTAICMSUFDEST
                            ,V_ISENTAICMSPARTUFDESTORGAOPUB
                            ,V_ORGAOPUB
                            ,P_BASEICMS
                            ,P_RETORNO);
        P_CODMSG := 0;
        P_MSG    := MSG_SUCESSO;
     end;


   begin
     F10_OBTER_PARTILHA_ICMS(P_CODFILIAL,P_CODCLI,P_UFOPERCONSUM,P_UFENTREGA,P_DATAOPER,P_VLPRODUTO,P_CODTRIBUT,P_CODPROD,P_CFOP,P_BASEICMS,P_CST,P_RETORNO,P_CODMSG,P_MSG);
   end;
  ---------------------------


   PROCEDURE ICMSPARTILHA_CALCULAR_1_7(P_CODFILIAL    in varchar2
                                      ,P_CODCLI       in number
                                      ,P_UFOPERCONSUM in varchar2
                                      ,P_UFENTREGA    in varchar2
                                      ,P_DATAOPER     in date
                                      ,P_VLPRODUTO    in number
                                      ,P_CODTRIBUT    in number
                                      ,P_CODPROD      in number
                                      ,P_CFOP         in number
                                      ,P_BASEICMS     in number
                                      ,P_CST          in varchar2
                                      ,P_ROTINA       in varchar2  := 'X'
                                      ,P_RETORNO      out varchar2
                                      ,P_CODMSG       out number
                                      ,P_MSG          out varchar2) is
  --variaveis output

     function F10_ANPCALCULAR(PCODPROD in number) return boolean is
        QT number(2);
     begin
        select count(1)
          into QT
          from PCPRODUT
         where CODPROD = PCODPROD
           and (ANP is null or ANP in (select I.VALOR
                                         from PCEXCECAOITEM I
                                         join PCEXCECAOTIPO T on I.CODTIPOEXCECAO = T.CODIGO
                                         join PCEXCECAODOCFISCAL D on I.CODEXCECAO = D.CODIGO
                                         join PCEXCECAOCATEGORIZACAO C on C.CODIGO = D.CODCATEGORIA
                                        where T.DESCRICAO = 'ANP'
                                          and C.ACAO = 'C'));
        return QT > 0;
     end;

     function F10_CFOPEXCECAO(PCFOP in number) return boolean is
        QT number(2);
     begin
        QT := 0;
        if PCFOP > 0
        then
           select count(1)
             into QT
             from PCEXCECAOITEM I
             join PCEXCECAOTIPO T on I.CODTIPOEXCECAO = T.CODIGO
             join PCEXCECAODOCFISCAL D on I.CODEXCECAO = D.CODIGO
             join PCEXCECAOCATEGORIZACAO C on C.CODIGO = D.CODCATEGORIA
            where T.DESCRICAO = 'CFOP'
              and I.VALOR = TO_CHAR(PCFOP)
              and C.ACAO = 'D';
        end if;

        return QT > 0;
     end;

     function F10_CSTEXCECAO(PCST in varchar2) return boolean is
        QT number(2);
     begin
        QT := 0;
        if trim(PCST) is not null
        then
           select count(1)
             into QT
             from PCEXCECAOITEM I
             join PCEXCECAOTIPO T on I.CODTIPOEXCECAO = T.CODIGO
             join PCEXCECAODOCFISCAL D on I.CODEXCECAO = D.CODIGO
             join PCEXCECAOCATEGORIZACAO C on C.CODIGO = D.CODCATEGORIA
            where T.DESCRICAO = 'CST'
              and I.VALOR = PCST
              and C.ACAO = 'D';
        end if;

        return QT > 0;
     end;

     procedure F10_CALCULAR_VALORES(P_CODFILIAL              in varchar2
                                   ,P_VLPRODUTO              in number
                                   ,P_DATAOPER               in date
                                   ,P_CLIENTEISENTO          in varchar2
                                   ,P_ALIQOPERACAO           in out number
                                   ,P_ALIQINTERESTADUAL      in number
                                   ,P_ALIQINTERNADEST        in out number
                                   ,P_ALIQFCP                in out number
                                   ,P_PERCBASERED            in out number
                                   ,P_PERCBASEREDDEST        in out number
                                   ,P_ACRESCALIQDESTICMSPART in varchar2
                                   ,P_CONSIDCONTRIB          in varchar2
                                   ,P_CONTRIBUINTE           in varchar2
                                   ,P_ISENTAICMSUFDEST       in varchar2
                                   ,P_ISENTAICMSPARTUFDESTORGAOPUB in varchar2
                                   ,P_ORGAOPUB               in varchar2
                                   ,P_BASEICMS               in number
                                   ,P_RETORNO                out varchar2) is
        V_VLICMSPARTREM   number(22, 10);
        V_VLBASEPARTDEST  number(22, 10);
        V_VLFCPPART       number(22, 10);
        V_VLICMSPARTDEST  number(22, 10);
        V_PERCPROVPART    number(22, 6);
        V_VLICMSDIFALIQ   number(22, 10);
        V_VLICMSPART      number(22, 10);
        V_ANOOPER         number(4);
        V_XMLRETORNO      XMLTYPE;
        V_AGREGARVLOPER   boolean;
        V_REDUZIRBASEDEST boolean;
        v_CALCDIFALPELADIFERENCAICMS  boolean;

        V_VLBASEPARTORIG number(22, 10);
     begin
        PKG_DEBUGGING_FWPC.LOG_MSG('Função F10_CALCULAR_VALORES');

        V_AGREGARVLOPER := NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('ACRESCICMSPARTILHAPRECO', P_CODFILIAL),'N') = 'S';

        if PARAMFILIAL.ParametroExiste('CALCDIFALPELADIFERENCAICMS', P_CODFILIAL) then
          v_CALCDIFALPELADIFERENCAICMS := NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CALCDIFALPELADIFERENCAICMS', P_CODFILIAL),'N') = 'S';
        else
          v_CALCDIFALPELADIFERENCAICMS := False;
        end if;

        PKG_DEBUGGING_FWPC.LOG_MSG('Parametro ACRESCICMSPARTILHAPRECO: '||'S');

        V_VLICMSPART     := 0;
        V_VLBASEPARTDEST := F10_CALCULAR_BASEPART_FORA(P_VLPRODUTO
                                                      ,P_ALIQINTERESTADUAL
                                                      ,P_ALIQINTERNADEST
                                                      ,P_ALIQFCP
                                                      ,V_AGREGARVLOPER
                                                      ,P_ACRESCALIQDESTICMSPART = 'S'
                                                      ,P_ROTINA);

        PKG_DEBUGGING_FWPC.LOG_MSG('Retorno F10_CALCULAR_BASEPART_FORA V_VLBASEPARTDEST: '||V_VLBASEPARTDEST);

        if V_AGREGARVLOPER
        then
           V_VLICMSPART := GREATEST(V_VALORPRODUTO_ACRESCIDO - P_VLPRODUTO, 0);
        end if;

        PKG_DEBUGGING_FWPC.LOG_MSG('Retorno V_VLICMSPART: '||V_VLICMSPART);

        IF V_AGREGARVLOPER AND
           (P_ACRESCALIQDESTICMSPART = 'N') AND
           (P_ROTINA = 'DOCFISCAL') AND
           (P_CST = '00') THEN

          PKG_DEBUGGING_FWPC.LOG_MSG('Ajustando os valores V_VLBASEPARTDEST = '||P_BASEICMS ||' e V_VALORPRODUTO_ACRESCIDO: '||P_VLPRODUTO);
          V_VLBASEPARTDEST := P_BASEICMS;
          V_VALORPRODUTO_ACRESCIDO := P_VLPRODUTO;
        END IF;

        V_VLBASEPARTORIG := V_VLBASEPARTDEST;

        -- A ALIQUOTA DE ICMS É ZERADA SE O CLIENTE FOR ISENTO
        if P_CLIENTEISENTO = 'S'
        then
           P_ALIQOPERACAO := 0;
           P_PERCBASERED  := 0;

           PKG_DEBUGGING_FWPC.LOG_MSG('A ALIQUOTA DE ICMS É ZERADA SE O CLIENTE FOR ISENTO: '||P_CLIENTEISENTO);
        end if;

        -- VALIDAR SE DEVERÁ REDUZIR A BASE DE CALCULO DE ORIGEM
        begin
           V_REDUZIRBASEDEST := not
                                PARAMFILIAL.OBTERCOMOVARCHAR2('DESCONSREDBASEPARTDEST', P_CODFILIAL) = 'S';
        exception
           when others then
              V_REDUZIRBASEDEST := true;
        end;

        if not V_REDUZIRBASEDEST
        then
           PKG_DEBUGGING_FWPC.LOG_MSG('VALIDAR SE DEVERÁ REDUZIR A BASE DE CALCULO DE ORIGEM (DESCONSREDBASEPARTDEST): V_REDUZIRBASEDEST = FALSE');

           P_PERCBASEREDDEST := 0;
        end if;

        if P_PERCBASEREDDEST > 0
        then
           V_VLBASEPARTDEST := V_VLBASEPARTDEST * P_PERCBASEREDDEST / 100;

           PKG_DEBUGGING_FWPC.LOG_MSG('Valor V_VLBASEPARTDEST: '||V_VLBASEPARTDEST);
           /*Trecho comentado pra resolução do chamado FIS-6501, pois a base de origem estava sendo calculado com o percentual
           de redução de base de destino*/
           --P_PERCBASERED := P_PERCBASEREDDEST;
        end if;

        if P_PERCBASERED > 0
        then
           V_VLBASEPARTORIG := V_VLBASEPARTORIG * P_PERCBASERED / 100;
           PKG_DEBUGGING_FWPC.LOG_MSG('Valor V_VLBASEPARTORIG * P_PERCBASERED: ('||V_VLBASEPARTDEST||' * '||P_PERCBASERED||')');
        end if;

        -- Se figura destino for isento de ICMS, zera valores do destino
        -- Foi tirar o zeramento das variaveis de aliquota e valor de ICMS destino, conforme mudança
        --      da NT 2015.003 (vigente para 01/07/2017)
        -- Não gera grupo partilha se PCTRIBUT.ISENTAICMSPARTUFDESTORGAOPUB = S e orgão Publico = 'S'
        if (P_ISENTAICMSUFDEST = 'S') OR
           ((P_ISENTAICMSPARTUFDESTORGAOPUB = 'S') AND
            (P_ORGAOPUB = 'S'))
        then
           V_VLBASEPARTDEST  := 0;
           V_VLBASEPARTORIG  := 0;
           P_ALIQINTERNADEST := 0;
           P_ALIQFCP         := 0;
           V_VLICMSPART      := 0;

           PKG_DEBUGGING_FWPC.LOG_MSG('Zerou valores de Destino:  P_ISENTAICMSUFDEST '||P_ISENTAICMSUFDEST||
                                                                ' P_ISENTAICMSPARTUFDESTORGAOPUB: '||P_ISENTAICMSPARTUFDESTORGAOPUB||
                                                                ' P_ORGAOPUB: '||P_ORGAOPUB);
        end if;

        V_VLFCPPART      := V_VLBASEPARTDEST * P_ALIQFCP / 100;
        V_VLICMSPARTDEST := V_VLBASEPARTDEST * P_ALIQINTERNADEST / 100;
        V_VLICMSPARTREM  := V_VLBASEPARTORIG * P_ALIQINTERESTADUAL / 100;
        V_ANOOPER        := EXTRACT(year from P_DATAOPER);
        V_PERCPROVPART := case
                             when V_ANOOPER = 2016 then
                              40
                             when V_ANOOPER = 2017 then
                              60
                             when V_ANOOPER = 2018 then
                              80
                             when V_ANOOPER >= 2019 then
                              100
                             else
                              0
                          end;

        IF V_ANOOPER >= 2019 THEN
          IF (P_BASEICMS > 0) THEN
            IF (ROUND(P_BASEICMS,2) < ROUND(P_VLPRODUTO,2)) THEN --ANTERIOR
              PKG_DEBUGGING_FWPC.LOG_MSG('Base menor que o valor do produto');

              IF V_CALCDIFALPELADIFERENCAICMS THEN
                V_VLICMSDIFALIQ := ((V_VLBASEPARTDEST * P_ALIQINTERNADEST) - (P_ALIQINTERESTADUAL * P_BASEICMS)) / 100;
              ELSE
                V_VLICMSDIFALIQ  := (V_VLBASEPARTDEST * (P_ALIQINTERNADEST - P_ALIQINTERESTADUAL)) / 100;
              END IF;
            ELSE
              IF (V_VALORPRODUTO_ACRESCIDO <> P_VLPRODUTO) THEN
                 PKG_DEBUGGING_FWPC.LOG_MSG('Valor do produto Acrescido diferente do valor do produto V_VALORPRODUTO_ACRESCIDO e P_VLPRODUTO '||V_VALORPRODUTO_ACRESCIDO ||' e '|| P_VLPRODUTO);

                 IF (P_BASEICMS <> V_VLBASEPARTDEST) AND (P_CST = '00') THEN
                     V_VLICMSDIFALIQ := ((V_VLBASEPARTDEST * P_ALIQINTERNADEST) - (P_ALIQINTERESTADUAL * P_BASEICMS)) / 100;

                     PKG_DEBUGGING_FWPC.LOG_MSG('Base de icms diferente o valor Base Part Dest e CST = 00');
                     PKG_DEBUGGING_FWPC.LOG_MSG('(('||V_VLBASEPARTDEST||' * '||P_ALIQINTERNADEST||') - ('||P_ALIQINTERESTADUAL ||' * '|| P_BASEICMS||')) / 100 Resultado: '||V_VLICMSDIFALIQ );
                 ELSE
                    V_VLICMSDIFALIQ := ((V_VLBASEPARTDEST * P_ALIQINTERNADEST) - (P_ALIQINTERESTADUAL * V_VALORPRODUTO_ACRESCIDO)) / 100;

                    PKG_DEBUGGING_FWPC.LOG_MSG('Base de icms igual o valor Base Part Dest ou CST <> 00');
                    PKG_DEBUGGING_FWPC.LOG_MSG('(('||V_VLBASEPARTDEST||' * '||P_ALIQINTERNADEST||') - ('||P_ALIQINTERESTADUAL ||' * '|| V_VALORPRODUTO_ACRESCIDO||')) / 100' );
                END IF;
              ELSE
                V_VLICMSDIFALIQ := ((V_VLBASEPARTDEST * P_ALIQINTERNADEST) - (P_ALIQINTERESTADUAL * P_BASEICMS)) / 100;

                PKG_DEBUGGING_FWPC.LOG_MSG('Valor do produto acrescido igual ao valor do produto');
                PKG_DEBUGGING_FWPC.LOG_MSG('(('||V_VLBASEPARTDEST||' * '||P_ALIQINTERNADEST||') - ('||P_ALIQINTERESTADUAL ||' * '|| P_BASEICMS||')) / 100' );
              END IF;
            END IF;
          ELSE
            --anterior
            V_VLICMSDIFALIQ  := (V_VLBASEPARTDEST * (P_ALIQINTERNADEST - P_ALIQINTERESTADUAL)) / 100;

            PKG_DEBUGGING_FWPC.LOG_MSG('Cálculo Anterior de diferença de alíquota direta.');
          END IF;
        END IF;

        --Regra  NT 2020.005 - v1.20 - NA15-10 Rej. 815
        IF V_VLICMSDIFALIQ < 0 THEN
          V_VLICMSDIFALIQ := 0;
        END IF;


        V_VLICMSPARTDEST := V_VLICMSDIFALIQ * V_PERCPROVPART / 100;
        V_VLICMSPARTREM  := V_VLICMSDIFALIQ - V_VLICMSPARTDEST;

        PKG_DEBUGGING_FWPC.LOG_MSG('Cálculo V_VLICMSPARTDEST: '||V_VLICMSPARTDEST );
        PKG_DEBUGGING_FWPC.LOG_MSG('Cálculo V_VLICMSPARTREM: '||V_VLICMSPARTREM );


        if NVL(P_ALIQOPERACAO, 0) <= 0
        then
           V_VLICMSPARTREM := 0;
        end if;

        select XMLELEMENT("retorno"
                          ,XMLELEMENT("aliqinterestadual"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(P_ALIQINTERESTADUAL
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("aliqinternadest"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(P_ALIQINTERNADEST
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("aliqfcp"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(P_ALIQFCP
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("percbasered"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(P_PERCBASERED
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("vlbasepartdest"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(V_VLBASEPARTDEST
                                                              ,'FM999999999999D9999999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("vlicmspartrem"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(V_VLICMSPARTREM
                                                              ,'FM999999999999D9999999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("vlfcppart"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(V_VLFCPPART
                                                              ,'FM999999999999D9999999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("vlicmspartdest"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(V_VLICMSPARTDEST
                                                              ,'FM999999999999D9999999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("percprovpart"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(V_PERCPROVPART
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("vlicmsdifaliq"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(V_VLICMSDIFALIQ
                                                              ,'FM999999999999D9999999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("vlicmspart"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(V_VLICMSPART
                                                              ,'FM999999999999D9999999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("percbasereddest"
                                     ,RTRIM(RTRIM(LTRIM(TO_CHAR(P_PERCBASEREDDEST
                                                              ,'FM9999999999999999D999999'
                                                              ,'nls_numeric_characters=,.'))
                                                ,0)
                                          ,','))
                          ,XMLELEMENT("acrescaliqdesticmspart", P_ACRESCALIQDESTICMSPART)
                          ,XMLELEMENT("considerarcontribicmspart", P_CONSIDCONTRIB))

          into V_XMLRETORNO
          from DUAL;

        P_RETORNO := V_XMLRETORNO.GETSTRINGVAL();

     end;

     procedure F10_OBTER_PARTILHA_ICMS(P_CODFILIAL    in varchar2
                                      ,P_CODCLI       in number
                                      ,P_UFOPERCONSUM in varchar2
                                      ,P_UFENTREGA    in varchar2
                                      ,P_DATAOPER     in date
                                      ,P_VLPRODUTO    in number
                                      ,P_CODTRIBUT    in number
                                      ,P_CODPROD      in number
                                      ,P_CFOP         in number
                                      ,P_BASEICMS     in number
                                      ,P_CST          in varchar2
                                      ,P_RETORNO      out varchar2
                                      ,P_CODMSG       out number
                                      ,P_MSG          out varchar2) is

        V_VLPRODUTO number;
        MSG_SUCESSO constant varchar2(30) := 'Partilha calculada com sucesso';
        MSG1        constant varchar2(55) := 'A filial da operação não foi informada ou é inexistente';
        MSG2        constant varchar2(33) := 'O cliente informado é inexistente';
        MSG3        constant varchar2(47) := 'A UF da operação a consumidor não foi informada';
        MSG4        constant varchar2(44) := 'A operação com o cliente não é interestadual';
        MSG5        constant varchar2(68) := 'O cliente informado não é consumidor final ou é contribuinte do ICMS';
        MSG6        constant varchar2(36) := 'A data da operação não foi informada';
        MSG7        constant varchar2(42) := 'O valor do produto deve ser maior que zero';
        MSG8        constant varchar2(47) := 'A tributação não foi informada ou é inexistente';
        MSG9        constant varchar2(67) := 'Não foi vinculada uma tributação para partilha de ICMS (rotina 514)';
        MSG10       constant varchar2(51) := 'O código do produto não foi informado ou é inválido';
        MSG11       constant varchar2(64) := 'A filial está definida como Simples Nacional e não partilha ICMS';
        MSG12       constant varchar2(67) := 'O cliente que representa a filial não foi definido ou é inexistente';
        MSG13       constant varchar2(35) := 'Cliente sem UF cadastrada';
        MSG14       constant varchar2(40) := 'CFOP do item não informado';
        MSG15       constant varchar2(40) := 'CST de ICMS do item não informado';
        MSG16       constant varchar2(60) := 'Produto não localizado na rotina 238(PCPRODFILIAL)';
        MSG17       constant varchar2(33) := 'Base ICMS não pode ser nulo';
        MSG18       constant varchar2(83) := 'Produto contém registro ANP, verifique se contém exceção cadastrada na rotina 4006';
        MSG19       constant varchar2(100) := 'Produto contém registro de exceção por cfop cadastrada na rotina 4006';

        V_TRIBUT_NAO_LOCALIZADA       exception;
        V_TRIBPARTILHA_NAO_LOCALIZADA exception;

        V_CODCLIFILIAL      PCFILIAL.CODCLI%type;
        V_UFCLIENTE         PCCLIENT.ESTENT%type;
        V_CONSUMIDOR        PCCLIENT.CONSUMIDORFINAL%type;
        V_CONTRIBUINTE      PCCLIENT.CONTRIBUINTE%type;
        V_IECLIENTE         PCCLIENT.IEENT%type;
        V_UFFILIAL          PCFILIAL.UF%type;
        V_TIPOEMPRESA       PCCLIENT.TIPOEMPRESA%type;
        V_CLIENTEISENTOICMS PCCLIENT.ISENTOICMS%type;
        V_PESSOAFISICA      PCCLIENT.TIPOFJ%type;
        V_PERCBASERED       PCTRIBUT.PERCBASERED%type;
        V_IMPORTADO         PCPRODUT.IMPORTADO%type;
        V_SIMPLESNACIONAL   PCCLIENT.SIMPLESNACIONAL%type;
        V_ORGAOPUB          PCCLIENT.ORGAOPUB%type;

        V_PERCBASEREDST          PCTRIBUT.PERCBASEREDST%type;
        V_CONSIDCONTRIB          PCTRIBUT.CONSIDERARCONTRIBICMSPART%type;
        V_ACRESCALIQDESTICMSPART PCTRIBUT.ACRESCALIQDESTICMSPART%type;

        V_CLIENTEFONTEST PCCLIENT.CLIENTEFONTEST%type;
        V_EXCECAO        boolean;

        -- VALORES DA PCPRODFILIAL
        V_ORIGMERCTRIB PCPRODFILIAL.ORIGMERCTRIB%type;

        -- VALORES DA PARTILHA
        V_ALIQINTERESTADUAL PCTRIBUT.CODICM%type;
        V_ALIQOPERACAO      PCTRIBUT.CODICM%type;
        V_ALIQINTERNADEST   PCTRIBUT.CODICM%type;
        V_ALIQFCP           PCTRIBUT.PERACRESCIMOFUNCEP%type;
        V_ISENTAICMSUFDEST  PCTRIBUT.ISENTAICMSUFDEST%type;
        V_ISENTAICMSPARTUFDESTORGAOPUB PCTRIBUT.ISENTAICMSPARTUFDESTORGAOPUB%type;

        procedure F10_BUSCAR_ALIQUOTAS(P_TIPOEMPRESACLI         in varchar2
                                      ,P_PESSOAFISICA           in varchar2
                                      ,P_CONSUMIDORFINAL        in varchar2
                                      ,P_UFCLIENTE              in varchar2
                                      ,P_UFFILIAL               in varchar2
                                      ,P_CODST                  in number
                                      ,P_PRODIMPORTADO          in varchar2
                                      ,P_ALIQOPERACAO           out number
                                      ,P_ALIQINTERESTADUAL      out number
                                      ,P_ALIQINTERNADEST        out number
                                      ,P_ALIQFCP                out number
                                      ,P_PERCBASERED            out number
                                      ,P_PERCBASEREDDEST        out number
                                      ,P_CONSIDCONTRIB          out varchar2
                                      ,P_ACRESCALIQDESTICMSPART out varchar2
                                      ,P_ISENTAICMSUFDEST       out varchar2
                                      ,P_ISENTAICMSPARTUFDESTORGAOPUB out varchar2
                                      ,P_ORIGMERCTRIB           in varchar2) is

           V_UTILIZAPERCBASEREDPF  PCTRIBUT.UTILIZAPERCBASEREDPF%type;
           V_PERCBASEREDCONSUMIDOR PCTRIBUT.PERCBASEREDCONSUMIDOR%type;
        begin
           PKG_DEBUGGING_FWPC.LOG_MSG('BUSCANDO OS DADOS DA TRIBUTAÇÃO (PCTRIBUT) PARAMETROS: P_CODST '||P_CODST);

           begin
              select DECODE(P_TIPOEMPRESACLI
                           ,'PR'
                           ,NVL(T.CODICMPRODRURAL, NVL(T.CODICMPF, NVL(T.CODICM, 0)))
                           ,DECODE(P_PESSOAFISICA
                                  ,'S'
                                  ,NVL(T.CODICMPF, NVL(T.CODICM, 0))
                                  ,NVL(T.CODICM, 0))) as ALIQICMS
                    ,NVL(T.PERCBASERED, 0) PERCBASERED
                    ,T.PERCBASEREDCONSUMIDOR PERCBASEREDCONSUMIDOR
                    ,T.UTILIZAPERCBASEREDPF
                    ,NVL(T.CONSIDERARCONTRIBICMSPART, 'N')
                    ,NVL(T.ACRESCALIQDESTICMSPART, 'N')
                into P_ALIQOPERACAO
                    ,P_PERCBASERED
                    ,V_PERCBASEREDCONSUMIDOR
                    ,V_UTILIZAPERCBASEREDPF
                    ,P_CONSIDCONTRIB
                    ,P_ACRESCALIQDESTICMSPART
                from PCTRIBUT T
               where T.CODST = P_CODST;

                PKG_DEBUGGING_FWPC.LOG_MSG('Parametros de tributação: P_ALIQOPERACAO = '||P_ALIQOPERACAO||
                                                                     'P_PERCBASERED = '||P_PERCBASERED||
                                                                     'V_PERCBASEREDCONSUMIDOR = '||V_PERCBASEREDCONSUMIDOR||
                                                                     'V_UTILIZAPERCBASEREDPF = '||V_UTILIZAPERCBASEREDPF||
                                                                     'P_CONSIDCONTRIB = '||P_CONSIDCONTRIB||
                                                                     'P_ACRESCALIQDESTICMSPART = '||P_ACRESCALIQDESTICMSPART);
           exception
              when NO_DATA_FOUND then
              begin
                 PKG_DEBUGGING_FWPC.LOG_MSG('Não encontrado dados para a tributação pesquisada.');
                 raise V_TRIBUT_NAO_LOCALIZADA;
              end;
           end;

           P_ALIQOPERACAO      := NVL(P_ALIQOPERACAO, 0);
           P_ALIQINTERESTADUAL := P_ALIQOPERACAO;
           if P_ALIQINTERESTADUAL <= 0
           then
              begin
                 P_ALIQINTERESTADUAL := NVL(PARAMFILIAL.OBTERCOMONUMBER('ALIQINTERORIGPART'
                                                                       ,P_CODFILIAL)
                                           ,12);
                 if P_UFFILIAL in ('MG', 'RJ', 'SP', 'PR', 'RS', 'SC')
                    and P_UFCLIENTE in ('MG', 'RJ', 'SP', 'PR', 'RS', 'SC')
                    and P_ALIQINTERESTADUAL > 4
                 then
                    P_ALIQINTERESTADUAL := 12;
                 end if;
              exception
                 when others then
                    null;
              end;

              if P_PRODIMPORTADO in ('S', 'D') and
                 P_ORIGMERCTRIB in ('1','2','3','8')
              then
                 begin
                    P_ALIQINTERESTADUAL := NVL(PARAMFILIAL.OBTERCOMONUMBER('ALIQINTERORIGIMPPART'
                                                                          ,P_CODFILIAL)
                                              ,4);
                 exception
                    when others then
                       P_ALIQINTERESTADUAL := 4;
                 end;
              end if;
           end if;

           -- Validar qual percentual de redução será utilizada
           if (P_CONSUMIDORFINAL = 'S')
              and (V_PERCBASEREDCONSUMIDOR is not null)
           then
              if (P_PESSOAFISICA = 'S')
                 and (PARAMFILIAL.OBTERCOMOVARCHAR2('CON_UTILIZAPERCBASEREDPF') = 'S')
                 and (V_UTILIZAPERCBASEREDPF = 'S')
              then
                 P_PERCBASERED := V_PERCBASEREDCONSUMIDOR;
              elsif (not P_PESSOAFISICA = 'S')
              then
                 P_PERCBASERED := V_PERCBASEREDCONSUMIDOR;
              else
                 P_PERCBASERED := 0;
              end if;
           end if;

           PKG_DEBUGGING_FWPC.LOG_MSG('VALIDANDO OS DADOS DA TRIBUTAÇÃO PARTILHA');
           begin
              select NVL(T.CODICM, 0) as ALIQICMSINTERNADEST
                    ,NVL(T.PERACRESCIMOFUNCEP, 0) as ALIQFCP
                    ,T.ISENTAICMSUFDEST
                    ,NVL(T.PERCBASERED, 0) PERCBASERED
                    ,T.PERCBASEREDCONSUMIDOR
                    ,NVL(T.UTILIZAPERCBASEREDPF, 'N')
                    ,T.ISENTAICMSPARTUFDESTORGAOPUB
                into P_ALIQINTERNADEST
                    ,P_ALIQFCP
                    ,P_ISENTAICMSUFDEST
                    ,P_PERCBASEREDDEST
                    ,V_PERCBASEREDCONSUMIDOR
                    ,V_UTILIZAPERCBASEREDPF
                    ,P_ISENTAICMSPARTUFDESTORGAOPUB
                from PCTRIBUTPARTILHA P
                    ,PCTRIBUT         T
               where P.CODSTPARTILHA = T.CODST
                 and P.CODST = P_CODST
                 and P.UF = P_UFCLIENTE;

                 PKG_DEBUGGING_FWPC.LOG_MSG('Dados Tributação Partilha busca - P_CODST ='|| P_CODST ||
                                             ' - P_UFCLIENTE = '||P_UFCLIENTE );
           exception
              when NO_DATA_FOUND then
                 PKG_DEBUGGING_FWPC.LOG_MSG('ERRO NA BUSCA DA TRIBUTAÇÃO DE PARTILHA - ');
                 raise V_TRIBPARTILHA_NAO_LOCALIZADA;
           end;

           P_ALIQINTERESTADUAL := NVL(P_ALIQINTERESTADUAL, 0);
           P_ALIQINTERNADEST   := NVL(P_ALIQINTERNADEST, 0);
           P_ALIQFCP           := NVL(P_ALIQFCP, 0);
           P_PERCBASEREDDEST   := NVL(P_PERCBASEREDDEST, 0);

           -- Validar qual percentual de redução PF será utilizada
         /*  if (P_CONSUMIDORFINAL = 'S')
              and (V_PERCBASEREDCONSUMIDOR is not null)
           then
              if (P_PESSOAFISICA = 'S')
                 and (PARAMFILIAL.OBTERCOMOVARCHAR2('CON_UTILIZAPERCBASEREDPF') = 'S')
                 and (V_UTILIZAPERCBASEREDPF = 'S')
              then
                 P_PERCBASEREDDEST := V_PERCBASEREDCONSUMIDOR;
              elsif (not P_PESSOAFISICA = 'S')
              then
                 P_PERCBASEREDDEST := V_PERCBASEREDCONSUMIDOR;
              else
                 P_PERCBASEREDDEST := 0;
              end if;
           end if;*/

        end;

     begin
        V_VLPRODUTO := P_VLPRODUTO;
        PKG_DEBUGGING_FWPC.LOG_MSG('VALIDANDO PARAMETROS DE ENTRADA');
        begin
           select UF
                 ,CODCLI
             into V_UFFILIAL
                 ,V_CODCLIFILIAL
             from PCFILIAL
            where CODIGO = NVL(P_CODFILIAL, 'XXX');
        exception
           when NO_DATA_FOUND then
              P_CODMSG := 1;
              P_MSG    := MSG1;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              return;
        end;

        begin
           select SIMPLESNACIONAL into V_SIMPLESNACIONAL from PCCLIENT where CODCLI = V_CODCLIFILIAL;
           if V_SIMPLESNACIONAL = 'S'
           then
              P_CODMSG := 11;
              P_MSG    := MSG11;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              -- Se o cliente for Simples Nacional, deve efetuar o calculo e obter as aliquotas
              -- considerando o valor do produto como zero.
              V_VLPRODUTO := 0;
           end if;
        exception
           when NO_DATA_FOUND then
              P_CODMSG := 12;
              P_MSG    := MSG12;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              return;
        end;

        if P_CODCLI > 0
        then
           begin
              select C.ESTENT as UF
                    ,NVL(C.CONSUMIDORFINAL, 'N') as CONSUMIDORFINAL
                    ,NVL(C.CONTRIBUINTE, 'N') as CONTRIBUINTE
                    ,C.TIPOEMPRESA
                    ,C.ISENTOICMS
                    ,DECODE(FERRAMENTAS.VERIFICAR_FJ(C.CODCLI), 'PESSOA FISICA', 'S', 'N') as PF
                    ,GERA_HISTORICO.SOMENTE_NUMERO(C.IEENT) as IE
                    ,CLIENTEFONTEST
                    ,CASE
                       WHEN (NVL(C.ORGAOPUBMUNICIPAL, 'N') = 'S') OR
                            (NVL(C.ORGAOPUB, 'N') = 'S') OR
                            (NVL(C.ORGAOPUBFEDERAL, 'N') = 'S') THEN
                         'S'
                       ELSE
                         'N'
                     END CLI_ORGAO_PUBLICO
                into V_UFCLIENTE
                    ,V_CONSUMIDOR
                    ,V_CONTRIBUINTE
                    ,V_TIPOEMPRESA
                    ,V_CLIENTEISENTOICMS
                    ,V_PESSOAFISICA
                    ,V_IECLIENTE
                    ,V_CLIENTEFONTEST
                    ,V_ORGAOPUB
                from PCCLIENT C
               where CODCLI = P_CODCLI;

              if V_UFCLIENTE is null
              then
                 P_CODMSG := 13;
                 P_MSG    := MSG13;
                 PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
                 return;
              end if;

           exception
              when NO_DATA_FOUND then
                 P_CODMSG := 2;
                 P_MSG    := MSG2;
                 PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
                 return;
           end;
        else
           V_UFCLIENTE  := trim(P_UFOPERCONSUM);
           V_CONSUMIDOR := 'S';
           if V_UFCLIENTE is null
           then
              P_CODMSG := 3;
              P_MSG    := MSG3;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              return;
           end if;
        end if;

        begin
           select IMPORTADO into V_IMPORTADO from PCPRODUT P where P.CODPROD = P_CODPROD;
        exception
           when NO_DATA_FOUND then
              P_CODMSG := 10;
              P_MSG    := MSG10;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              return;
        end;

        begin
           select ORIGMERCTRIB into V_ORIGMERCTRIB from PCPRODFILIAL P where P.CODPROD = P_CODPROD and P.CODFILIAL = P_CODFILIAL;
        exception
           when NO_DATA_FOUND then
              P_CODMSG := 16;
              P_MSG    := MSG16;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              return;
        end;

        V_UFCLIENTE := NVL(trim(P_UFENTREGA), V_UFCLIENTE);

        if V_UFCLIENTE = V_UFFILIAL
           or V_UFCLIENTE = 'EX'
        then
           P_CODMSG := 4;
           P_MSG    := MSG4;
           PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
           return;
        end if;

        if P_DATAOPER is null
        then
           P_CODMSG := 6;
           P_MSG    := MSG6;
           PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
           return;
        end if;
        if NVL(P_VLPRODUTO, 0) <= 0
        then
           P_CODMSG := 7;
           P_MSG    := MSG7;
           PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
           return;
        end if;

        PKG_DEBUGGING_FWPC.LOG_MSG('VALIDANDO EXCECAO DE ANP');
        if (not F10_ANPCALCULAR(P_CODPROD))
           and (P_DATAOPER >= TO_DATE('01/01/2016', 'DD/MM/YYYY'))
        then
           PKG_DEBUGGING_FWPC.LOG_MSG('EXCECAO DE ANP DO PRODUTO ' || TO_CHAR(P_CODPROD) ||
                                      'NÃO SATISFEITA');
           P_CODMSG := 18;
           P_MSG    := MSG18;
           return;
        end if;

        PKG_DEBUGGING_FWPC.LOG_MSG('VALIDANDO EXCECAO DE CFOP');
        if NVL(P_CFOP, 0) = 0
        then
           P_CODMSG := 14;
           P_MSG    := MSG14;
           PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
           return;
        end if;

        V_EXCECAO := F10_CFOPEXCECAO(P_CFOP);
        if V_EXCECAO
        then
           PKG_DEBUGGING_FWPC.LOG_MSG('EXCECAO DE CFOP ' || TO_CHAR(P_CFOP) || ' SATISFEITA');
           P_CODMSG := 19;
           P_MSG    := MSG19;
           return;
        end if;

        PKG_DEBUGGING_FWPC.LOG_MSG('VALIDANDO EXCECAO DE CST');
        if trim(P_CST) is null
        then
           P_CODMSG := 15;
           P_MSG    := MSG15;
           PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
           return;
        end if;
        V_EXCECAO := F10_CSTEXCECAO(P_CST);
        if V_EXCECAO
        then
           PKG_DEBUGGING_FWPC.LOG_MSG('EXCECAO DE CST ' || P_CST || ' SATISFEITA');
           P_CODMSG := 0;
           P_MSG    := MSG_SUCESSO;
           return;
        end if;

        if P_BASEICMS is null
        then
           PKG_DEBUGGING_FWPC.LOG_MSG('Produto: ' || TO_CHAR(P_CODPROD) || ' sem Base de ICMS');
           P_CODMSG := 17;
           P_MSG    := MSG17;
           return;
        end if;

        begin
           F10_BUSCAR_ALIQUOTAS(V_TIPOEMPRESA
                               ,V_PESSOAFISICA
                               ,V_CONSUMIDOR
                               ,V_UFCLIENTE
                               ,V_UFFILIAL
                               ,P_CODTRIBUT
                               ,V_IMPORTADO
                               ,V_ALIQOPERACAO /*OUT*/
                               ,V_ALIQINTERESTADUAL /*OUT*/
                               ,V_ALIQINTERNADEST /*OUT*/
                               ,V_ALIQFCP /*OUT*/
                               ,V_PERCBASERED /*OUT*/
                               ,V_PERCBASEREDST /*OUT*/
                               ,V_CONSIDCONTRIB /*OUT*/
                               ,V_ACRESCALIQDESTICMSPART /*OUT*/
                               ,V_ISENTAICMSUFDEST /*OUT*/
                               ,V_ISENTAICMSPARTUFDESTORGAOPUB /*OUT*/
                               ,V_ORIGMERCTRIB);

        exception
           when V_TRIBUT_NAO_LOCALIZADA then
              P_CODMSG := 8;
              P_MSG    := MSG8;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              return;
           when V_TRIBPARTILHA_NAO_LOCALIZADA then
              if V_CONSUMIDOR = 'N'
                 or V_CONTRIBUINTE = 'S'
              then
                 P_CODMSG := 5;
                 P_MSG    := MSG5;
                 PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
                 return;
              end if;
              P_CODMSG := 9;
              P_MSG    := MSG9;
              PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
              return;
        end;

        if V_CONSUMIDOR = 'N'
           or (V_CONTRIBUINTE = 'S' and V_CONSIDCONTRIB = 'N')
        then
           P_CODMSG := 5;
           P_MSG    := MSG5;
           PKG_DEBUGGING_FWPC.LOG_RETORNO(P_CODMSG, P_MSG);
           return;
        end if;

        F10_CALCULAR_VALORES(P_CODFILIAL
                            ,V_VLPRODUTO
                            ,P_DATAOPER
                            ,V_CLIENTEISENTOICMS
                            ,V_ALIQOPERACAO
                            ,V_ALIQINTERESTADUAL
                            ,V_ALIQINTERNADEST
                            ,V_ALIQFCP
                            ,V_PERCBASERED
                            ,V_PERCBASEREDST
                            ,V_ACRESCALIQDESTICMSPART
                            ,V_CONSIDCONTRIB
                            ,V_CONTRIBUINTE
                            ,V_ISENTAICMSUFDEST
                            ,V_ISENTAICMSPARTUFDESTORGAOPUB
                            ,V_ORGAOPUB
                            ,P_BASEICMS
                            ,P_RETORNO);
        P_CODMSG := 0;
        P_MSG    := MSG_SUCESSO;
     end;

   begin
     F10_OBTER_PARTILHA_ICMS(P_CODFILIAL,P_CODCLI,P_UFOPERCONSUM,P_UFENTREGA,P_DATAOPER,P_VLPRODUTO,P_CODTRIBUT,P_CODPROD,P_CFOP,P_BASEICMS,P_CST,P_RETORNO,P_CODMSG,P_MSG);
   end;
  ---------------------------




  ---------------------------
  PROCEDURE ICMSPARTILHA_CALCULAR_1_8(P_NUMTRANSACAO in number
                                     ,P_TIPOMOV  varchar2
                                     ,P_ATIVARLOG varchar2 := 'N'
                                     ,P_MSG      out varchar2) is
    v_COD_MSG INTEGER;
  begin


    ICMSPARTILHA_CALCULAR_1_9(P_NUMTRANSACAO, P_TIPOMOV, P_ATIVARLOG, v_COD_MSG, P_MSG);
  end;


  PROCEDURE ICMSPARTILHA_CALCULAR_1_9(P_NUMTRANSACAO in number
                                     ,P_TIPOMOV  varchar2
                                     ,P_ATIVARLOG varchar2 := 'N'
                                     ,P_CODIGO_MSG    out varchar2
                                     ,P_MSG      out varchar2) is
  V_RETORNO  varchar2(4000);
  V_MSG      varchar2(4000);
  V_MSG_TEMP varchar2(4000);
  V_CODMSG   number;
  tICMSPartilha T_ICMS_PARTILHA_FISCAL;

  begin
    -- Buscando dados do documento pela transação.
    for DADOS_NF in CONSULTA_DADOS_PARTILHA(P_NUMTRANSACAO, P_TIPOMOV) loop

      if P_ATIVARLOG = 'S' then
        PKG_DEBUGGING_FWPC.ATIVARDEBUG('Cálculo Partilha P_ATIVARLOG = ''S''', '1.8');
      end if;


      if ((DADOS_NF.CODFISCAL between '6000' and '7999') or
          (DADOS_NF.CODFISCAL between '2000' and '2999')) then

        if DADOS_NF.CALCULAPARTILHA = 'SIM' then
            ICMSPARTILHA_CALCULAR_1_7(DADOS_NF.CODFILIAL,
                                      DADOS_NF.CODCLI,
                                      DADOS_NF.UF,
                                      DADOS_NF.UFENTREGA,
                                      DADOS_NF.DATAOPER,
                                      DADOS_NF.VLPRODUTO,
                                      DADOS_NF.CODST,
                                      DADOS_NF.CODPROD,
                                      DADOS_NF.CODFISCAL,
                                      DADOS_NF.BASEICMS,
                                      DADOS_NF.CST,
                                      'DOCFISCAL',
                                      V_RETORNO,
                                      V_CODMSG,
                                      V_MSG);

            -- Atualizando objeto com os dados do xml
            tICMSPartilha := PREPARAR_XML_RETORNO_2(V_RETORNO);

            -------------------------------------------------
            if V_MSG = 'Partilha calculada com sucesso' then

               if TRIM(V_MSG_TEMP) IS NULL then
                  V_MSG_TEMP := V_MSG;
               end if;

            else
               -- Atualizando mensagem com o codigo do produto
               V_MSG := V_MSG || ' - ' || 'Produto: '|| DADOS_NF.CODPROD
                              || ' - ' || 'Transacao : ' || DADOS_NF.NUMTRANS;
               --  HABILITANDO SERVIÇO LOG
               PKG_DEBUGGING_FWPC.ATIVARDEBUG('Cálculo Partilha', '1.8');
               -- GRAVANDO LOG
               PKG_DEBUGGING_FWPC.LOG(V_MSG, P_TIPOMOV);
               -- DESABILITANDO SERVIÇO LOG
               PKG_DEBUGGING_FWPC.DESATIVARDEBUG;
               -- ATUALIZANDO MENSAGEM DE RETORNO
               V_MSG_TEMP := 'Existem itens não calculados. Conferir Log(PCFWLOGDEBUG)';
            end if;
            -------------------------------------------------

           if (V_CODMSG in (0,4,5,7,19)) then
             if DADOS_NF.PREFATURAMENTO = 'N' then
                UPDATE PCMOVCOMPLE
                   SET VLFCPPART         = NVL(tICMSPartilha.VLFCPPART,0)
                      ,VLICMSPART        = NVL(tICMSPartilha.VLICMSPART,0)
                      ,VLBASEPARTDEST    = NVL(tICMSPartilha.VLBASEPARTDEST,0)
                      ,ALIQFCP           = NVL(tICMSPartilha.ALIQFCP,0)
                      ,ALIQINTERNADEST   = NVL(tICMSPartilha.ALIQINTERNADEST,0)
                      ,ALIQINTERORIGPART = NVL(tICMSPartilha.ALIQINTERESTADUAL,0)
                      ,VLICMSPARTDEST    = NVL(tICMSPartilha.VLICMSPARTDEST,0)
                      ,PERCPROVPART      = NVL(tICMSPartilha.PERCPROVPART,0)
                      ,VLICMSDIFALIQPART = NVL(tICMSPartilha.VLICMSDIFALIQ,0)
                      ,PERCBASEREDPART   = NVL(tICMSPartilha.PERCBASEREDPART,0)
                      ,VLICMSPARTREM     = NVL(tICMSPartilha.VLICMSPARTREM,0)
                 WHERE NUMTRANSITEM      = DADOS_NF.NUMTRANSITEM;

             else

               UPDATE PCMOVCOMPLEPREFAT
                  SET VLFCPPART         = NVL(tICMSPartilha.VLFCPPART,0)
                     ,VLICMSPART        = NVL(tICMSPartilha.VLICMSPART,0)
                     ,VLBASEPARTDEST    = NVL(tICMSPartilha.VLBASEPARTDEST,0)
                     ,ALIQFCP           = NVL(tICMSPartilha.ALIQFCP,0)
                     ,ALIQINTERNADEST   = NVL(tICMSPartilha.ALIQINTERNADEST,0)
                     ,ALIQINTERORIGPART = NVL(tICMSPartilha.ALIQINTERESTADUAL,0)
                     ,VLICMSPARTDEST    = NVL(tICMSPartilha.VLICMSPARTDEST,0)
                     ,PERCPROVPART      = NVL(tICMSPartilha.PERCPROVPART,0)
                     ,VLICMSDIFALIQPART = NVL(tICMSPartilha.VLICMSDIFALIQ,0)
                     ,PERCBASEREDPART   = NVL(tICMSPartilha.PERCBASEREDPART,0)
                     ,VLICMSPARTREM     = NVL(tICMSPartilha.VLICMSPARTREM,0)
                WHERE NUMTRANSITEM      = DADOS_NF.NUMTRANSITEM;
             end if;
          end if;
        else
          PKG_DEBUGGING_FWPC.LOG('DADOS_NF.CALCULAPARTILHA = ''NÃO'' ', P_TIPOMOV);

          V_MSG_TEMP := 'Partilha NÃO calculada pois não atendeu o critério do CondVenda(1, 7, 8, 13, 14)'||chr(13)||
                        'DECODE(TO_NUMBER(NVL(PD.CONDVENDA, N.CONDVENDA))
                              , 1, DECODE(NVL(PD.NUMNOTACONSIG, 0), 0, ''SIM'', ''NAO'')
                              , 7, DECODE(NVL(PD.CONTAORDEM, N.CONTAORDEM), ''N'', ''NAO'', ''S'', ''SIM'')
                              , 8, DECODE(NVL(PD.CONTAORDEM, N.CONTAORDEM), ''N'', ''SIM'', ''S'', ''NAO'')
                              , 13, DECODE(FI.DESTACARIMPOSTOSVENDATV13, ''N'', ''NAO'', ''SIM'')
                              , 14, DECODE(FI.DESTACARIMPOSTOSVENDATV14, ''N'', ''NAO'', ''SIM'')
                              , ''SIM'')';

          PKG_DEBUGGING_FWPC.LOG(V_MSG_TEMP, P_TIPOMOV);
        end if;
      else
        PKG_DEBUGGING_FWPC.LOG('Cliente não é consumidor final ou é contribuinte ou operação é estadual', P_TIPOMOV);
      end if;
    end loop;

    P_MSG := '';

    PKG_DEBUGGING_FWPC.DESATIVARDEBUG;
    commit;
  end;


  FUNCTION F_CALCULAR_PARTILHA_ICMS_1_9(P_NUMTRANSACAO in number
                                       ,P_TIPOMOV      varchar2
                                       ,P_ATIVARLOG    varchar2 := 'N'
                                       ,P_CODMSG   out varchar2
                                       ,P_MSG      out varchar2)
  RETURN VARCHAR2 is
  V_RETURN VARCHAR2(1);
  begin
     begin
        ICMSPARTILHA_CALCULAR_1_9(P_NUMTRANSACAO, P_TIPOMOV, P_ATIVARLOG, P_CODMSG, P_MSG);

        IF (P_MSG IS NULL) THEN
         V_RETURN := 'S';
        ELSE
         V_RETURN := 'N';
        END IF;
     exception
        when others then
          P_MSG     := 'Erro o calcular ICMS Partilha.' || CHR(13) ||
                       'Erro original: ' || sqlerrm;
          V_RETURN := 'N';
     end;
     RETURN(V_RETURN);
  end;


  ---------------------------

-- Alteração 30/10/2023 - Implementado "ICMSPARTILHA_CALCULAR_1_8"
-- Alteração 17/03/2023 ICMSPARTILHA_CALCULAR_1_6 e ICMSPARTILHA_CALCULAR_1_7
end PKG_FWPC_FISCAL;
