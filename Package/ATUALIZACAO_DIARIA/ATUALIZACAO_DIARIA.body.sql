create or replace package body ATUALIZACAO_DIARIA is

  function FC_RETORNA_VERSAO return varchar2 is
    VERSAO varchar2(20) := '';
  begin
    select VSVERSAOPACKAGE
    into   VERSAO
    from   DUAL;
    return VERSAO;
  end;

  /*********************************************************************************
  ---------------------------------- Historico -------------------------------------
      Data        Responsavel    Comentarios
  ------------  ---------------  ---------------------------------------------------
   24/08/2020   Fernandes Brito  Criada a procedure para gerar log da gravação do estoque
                                 Na tabela de transição PCHISTESTFILA
  Informações:
  'IP' - Iniciou o programa
  'IL' - Iniciou uma lista de dados
  'FL' - Fechou uma lista de dados
  'FP' - Fechou o programa
  *********************************************************************************/
  PROCEDURE GRAVARLOG (psCODFILIAL      IN VARCHAR2
                      ,psMODULO         IN VARCHAR2
                      ,psFUNCAO         IN VARCHAR2
                      ,psTIPO_LOG       IN VARCHAR2
                      ,psDS_JOB         IN VARCHAR2
                      ,psPARAMETROS     IN VARCHAR2)
  IS-- Variáveis internas
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    -- Inserindo log da função
    INSERT INTO PCLOGJOB
      (MODULO
      ,FUNCAO
      ,TIPO_LOG
      ,DATA_LOG
      ,DS_JOB
      ,PARAMETROS)
    VALUES
      (psMODULO
      ,psFUNCAO
      ,psTIPO_LOG
      ,SYSDATE
      ,psDS_JOB || psCODFILIAL
      ,psPARAMETROS);
    COMMIT;
  -- Procedure
  END GRAVARLOG;

  --Recálculo do %Venda para Pessoa Física  (P_PC_RECALCPERCENTVENDAPF)
  procedure P_PC_RECALCPERCENTVENDAPF(PCODFILIAL IN VARCHAR2,
                                      -- Parametro de saida
                                      PVC2MENSSAGEN out varchar2) is
    /*********************************************************************************
    Opção 11 - Recálculo do %Venda para Pessoa Física
    ---------------------------------- Historico -------------------------------------
        Data        Responsavel    Comentarios
    ------------  ---------------  ---------------------------------------------------
     22/07/2008    Max Faria        Transcrição para PLSQL da opção 11 da rotina 504
     09/07/2009    Rogério Mendes   Implementar tratamento de NVL conforme anexo da Tarefa 88349
     02/12/2009    Pablo               Tratamento nos campos com NVL para tratar valore nulo.
    *********************************************************************************/
    VCONSIDERAISENTOSCOMOPF PCCONSUM.CONSIDERAISENTOSCOMOPF%type;
    VSQL                    varchar2(2000);
    VVLRPEDIDOSMES          PCPEDC.VLATEND%type;
    VTOTVLRPEDIDOSMES       PCPEDC.VLATEND%type;
    VVLRNFMES               PCNFSAID.VLTOTAL%type;
    VTOTVLRNFMES            PCNFSAID.VLTOTAL%type;
    VVLRDEVMES              PCNFENT.VLTOTAL%type;
    VTOTVLRDEVMES           PCNFENT.VLTOTAL%type;
    VVLRPEDIDOSMESPF        PCPEDC.VLATEND%type;
    VTOTVLRPEDIDOSMESPF     PCPEDC.VLATEND%type;
    VVLRNFMESPF             PCNFSAID.VLTOTAL%type;
    VTOTVLRNFMESPF          PCNFSAID.VLTOTAL%type;
    VVLRDEVMESPF            PCNFENT.VLTOTAL%type;
    VTOTVLRDEVMESPF         PCNFENT.VLTOTAL%type;
    VPERCVENDAPF            number(18, 4);
  begin
    select NVL(CONSIDERAISENTOSCOMOPF, 'S')
    into   VCONSIDERAISENTOSCOMOPF
    from   PCCONSUM;
    VTOTVLRPEDIDOSMES   := 0;
    VTOTVLRNFMES        := 0;
    VTOTVLRDEVMES       := 0;
    VTOTVLRPEDIDOSMESPF := 0;
    VTOTVLRNFMESPF      := 0;
    VTOTVLRDEVMESPF     := 0;
    VPERCVENDAPF        := 0;
    insert into PCLOGJOB
      (MODULO,
       FUNCAO,
       TIPO_LOG,
       DATA_LOG,
       DS_JOB)
    values
      ('RECALCPERCENTVENDPF',
       'pcfilial',
       'IN',
       sysdate,
       'Inicio Recálculo do %Venda para Pessoa Física');
    commit;
    for REGISTRO in (select CODIGO,
                            UF
                     from   PCFILIAL
                     where  CODIGO <> '99'
                      AND (DECODE(PCODFILIAL,'99',NULL,PCODFILIAL) IS NULL OR PCFILIAL.CODIGO = PCODFILIAL))
    loop
      VVLRPEDIDOSMES   := 0;
      VVLRNFMES        := 0;
      VVLRDEVMES       := 0;
      VVLRPEDIDOSMESPF := 0;
      VVLRNFMESPF      := 0;
      VVLRDEVMESPF     := 0;
      -- Valor dos Pedidos ainda não faturados mas liberados
      select NVL(sum(NVL(PCPEDC.VLATEND, 0) *
                     (NVL(PCPEDC.PERCVENDA, 100) / 100)),
                 0)
      into   VVLRPEDIDOSMES
      from   PCPEDC
      where  PCPEDC.DATA >= TO_DATE('01/' || TO_CHAR(TRUNC(sysdate), 'MM/YYYY'), 'DD/MM/YYYY')
      and    PCPEDC.CODFILIAL = REGISTRO.CODIGO
      and    PCPEDC.CONDVENDA not in (3, 6, 12)
      and    PCPEDC.POSICAO in ('L', 'M')
      and    PCPEDC.DTCANCEL is null;
      VTOTVLRPEDIDOSMES := NVL(VTOTVLRPEDIDOSMES, 0) + NVL(VVLRPEDIDOSMES, 0);
      -- Valor da NFs do cliente no mês
      select NVL(sum(NVL(PCNFSAID.VLTOTAL, 0)), 0)
      into   VVLRNFMES
      from   PCNFSAID
      where  PCNFSAID.DTSAIDA >= TO_DATE('01/' || TO_CHAR(TRUNC(sysdate), 'MM/YYYY'), 'DD/MM/YYYY')
      and    PCNFSAID.CODFILIAL = REGISTRO.CODIGO
      and    PCNFSAID.CODFISCAL not in (522, 622, 722, 532, 632, 732)
      and    PCNFSAID.CONDVENDA not in (3, 6, 12)
      and    PCNFSAID.DTCANCEL is null;
      VTOTVLRNFMES := NVL(VTOTVLRNFMES, 0) + NVL(VVLRNFMES, 0);
      -- Buscar valor das devoluçÃµes no mês
      select NVL(sum(NVL(PCNFENT.VLTOTAL, 0)), 0)
      into   VVLRDEVMES
      from   PCNFSAID,
             PCESTCOM,
             PCNFENT
      where  PCNFSAID.DTSAIDA >= TO_DATE('01/' || TO_CHAR(TRUNC(sysdate), 'MM/YYYY'), 'DD/MM/YYYY')
      and    PCNFSAID.CODFILIAL = REGISTRO.CODIGO
      and    PCNFSAID.CODFISCAL not in (522, 622, 722, 532, 632, 732)
      and    PCNFSAID.DTCANCEL is null
      and    PCNFENT.TIPODESCARGA in ('6')
      and    PCNFSAID.NUMTRANSVENDA = PCESTCOM.NUMTRANSVENDA
      and    PCESTCOM.NUMTRANSENT = PCNFENT.NUMTRANSENT;
      VTOTVLRDEVMES := NVL(VTOTVLRDEVMES, 0) + NVL(VVLRDEVMES, 0);
      -- Valor dos Pedidos ainda não faturados mas liberados
      VSQL := 'SELECT NVL(SUM(NVL(PCPEDC.VLATEND,0)*(NVL(PCPEDC.PERCVENDA,100)/100)),0) VLATENDPEDIDOS
                 FROM PCPEDC, PCCLIENT, PCPRACA, PCREGIAO
                WHERE PCPEDC.DATA >= TO_DATE(''01/''||TO_CHAR(TRUNC(SYSDATE),''MM/YYYY''),''DD/MM/YYYY'')
                  AND PCPEDC.CODFILIAL = :CODFILIAL
                  AND PCPEDC.CONDVENDA NOT IN (3, 6, 12)
                  AND PCPEDC.POSICAO IN (''L'',''M'')
                  AND PCPEDC.DTCANCEL IS NULL
                  AND PCPEDC.CODPRACA = PCPRACA.CODPRACA
                  AND PCPRACA.NUMREGIAO = PCREGIAO.NUMREGIAO
                  AND PCREGIAO.TAREPF = ''S''
                  AND UPPER(PCCLIENT.ESTENT) = :UF
                  AND NVL(PCCLIENT.VALIDAMAXVENDAPF,''S'') = ''S''
                  AND ((PCCLIENT.TIPOFJ = ''F''
                        AND NVL(PCCLIENT.CONTRIBUINTE,''N'') <> ''S'')
                        OR (NVL(PCCLIENT.CONSUMIDORFINAL,''N'') = ''S'')';
      if VCONSIDERAISENTOSCOMOPF = 'S'
      then
        VSQL := VSQL ||
                'OR (PCCLIENT.IEENT IS NULL)
                          OR (UPPER(PCCLIENT.IEENT) = ''ISENTO'')
                          OR (UPPER(PCCLIENT.IEENT) = ''ISENTA'')';
      end if;
      VSQL := VSQL || ' ) AND PCPEDC.CODCLI = PCCLIENT.CODCLI';
      execute immediate VSQL
        into VVLRPEDIDOSMESPF
        using REGISTRO.CODIGO, REGISTRO.UF;
      VTOTVLRPEDIDOSMESPF := NVL(VTOTVLRPEDIDOSMESPF, 0) +
                             NVL(VVLRPEDIDOSMESPF, 0);
      -- Valor da NFs do cliente no mês
      VSQL := 'SELECT NVL(SUM(NVL(PCNFSAID.VLTOTAL,0)),0) VLTOTALNF
                 FROM PCNFSAID, PCCLIENT, PCPRACA, PCREGIAO
                WHERE PCNFSAID.DTSAIDA >= TO_DATE(''01/''||TO_CHAR(TRUNC(SYSDATE),''MM/YYYY''),''DD/MM/YYYY'')
                  AND PCNFSAID.CODFILIAL = :CODFILIAL
                  AND PCNFSAID.CODFISCAL NOT IN (522, 622, 722, 532, 632, 732)
                  AND PCNFSAID.CONDVENDA NOT IN (3, 6, 12)
                  AND PCNFSAID.DTCANCEL IS NULL
                  AND PCNFSAID.CODCLI = PCCLIENT.CODCLI
                  AND PCCLIENT.CODPRACA = PCPRACA.CODPRACA
                  AND PCPRACA.NUMREGIAO = PCREGIAO.NUMREGIAO
                  AND PCREGIAO.TAREPF = ''S''
                  AND UPPER(PCCLIENT.ESTENT) = :UF
                  AND NVL(PCCLIENT.VALIDAMAXVENDAPF,''S'') = ''S''
                  AND ((PCCLIENT.TIPOFJ = ''F''
                  AND NVL(PCCLIENT.CONTRIBUINTE,''N'') <> ''S'' )
                   OR (NVL(PCCLIENT.CONSUMIDORFINAL,''N'') = ''S'')';
      if VCONSIDERAISENTOSCOMOPF = 'S'
      then
        VSQL := VSQL ||
                'OR (PCCLIENT.IEENT IS NULL)
                          OR (UPPER(PCCLIENT.IEENT) = ''ISENTO'')
                          OR (UPPER(PCCLIENT.IEENT) = ''ISENTA'')';
      end if;
      VSQL := VSQL || ' )';
      execute immediate VSQL
        into VVLRNFMESPF
        using REGISTRO.CODIGO, REGISTRO.UF;
      VTOTVLRNFMESPF := NVL(VTOTVLRNFMESPF, 0) + NVL(VVLRNFMESPF, 0);
      -- Buscar valor das devoluções no mês
      VSQL := 'SELECT NVL(SUM (NVL (PCNFENT.VLTOTAL, 0)),0) VLTOTALDEV
                 FROM PCNFSAID, PCESTCOM, PCNFENT, PCCLIENT, PCPRACA, PCREGIAO
                WHERE PCNFSAID.DTSAIDA >= TO_DATE(''01/''||TO_CHAR (TRUNC (SYSDATE), ''MM/YYYY''),''DD/MM/YYYY'')
                  AND PCNFSAID.CODFILIAL = :CODFILIAL
                  AND PCNFSAID.CODFISCAL NOT IN (522, 622, 722, 532, 632, 732)
                  AND PCNFSAID.DTCANCEL IS NULL
                  AND PCNFENT.TIPODESCARGA IN (''6'')
                  AND PCNFSAID.CODCLI = PCCLIENT.CODCLI
                  AND PCCLIENT.CODPRACA = PCPRACA.CODPRACA
                  AND PCPRACA.NUMREGIAO = PCREGIAO.NUMREGIAO
                  AND PCREGIAO.TAREPF = ''S''
                  AND UPPER(PCCLIENT.ESTENT) = :UF
                  AND NVL(PCCLIENT.VALIDAMAXVENDAPF,''S'') = ''S''
                  AND ((PCCLIENT.TIPOFJ = ''F''
                        AND NVL(PCCLIENT.CONTRIBUINTE,''N'') <> ''S'')
                         OR (NVL(PCCLIENT.CONSUMIDORFINAL,''N'') = ''S'')';
      if VCONSIDERAISENTOSCOMOPF = 'S'
      then
        VSQL := VSQL ||
                'OR (PCCLIENT.IEENT IS NULL)
                          OR (UPPER(PCCLIENT.IEENT) = ''ISENTO'')
                          OR (UPPER(PCCLIENT.IEENT) = ''ISENTA'')';
      end if;
      VSQL := VSQL ||
              ' ) AND    PCNFSAID.NUMTRANSVENDA = PCESTCOM.NUMTRANSVENDA
                          AND    PCESTCOM.NUMTRANSENT = PCNFENT.NUMTRANSENT';
      execute immediate VSQL
        into VVLRDEVMESPF
        using REGISTRO.CODIGO, REGISTRO.UF;
      VTOTVLRDEVMESPF := NVL(VTOTVLRDEVMESPF, 0) + NVL(VVLRDEVMESPF, 0);
      begin
        VPERCVENDAPF := ((((NVL(VVLRPEDIDOSMESPF, 0) + NVL(VVLRNFMESPF, 0)) -
                        NVL(VVLRDEVMESPF, 0)) /
                        ((NVL(VVLRPEDIDOSMES, 0) + NVL(VVLRNFMES, 0)) -
                        NVL(VVLRDEVMES, 0))) * 100);
      exception
        when ZERO_DIVIDE then
          VPERCVENDAPF := 0;
        when others then
          VPERCVENDAPF := 0;
      end;
      update PCFILIAL
      set    PERVENDAPF = NVL(VPERCVENDAPF, 0)
      where  CODIGO = REGISTRO.CODIGO;
    update PCPARAMFILIAL
      set    VALOR = TO_CHAR(NVL(VPERCVENDAPF, 0))
      where  NOME = 'FIL_PERVENDAPF'
      and    CODFILIAL = REGISTRO.CODIGO;
      begin
        VPERCVENDAPF := ((((NVL(VTOTVLRPEDIDOSMESPF, 0) +
                        NVL(VTOTVLRNFMESPF, 0)) - NVL(VTOTVLRDEVMESPF, 0)) /
                        ((NVL(VTOTVLRPEDIDOSMES, 0) + NVL(VTOTVLRNFMES, 0)) -
                        NVL(VTOTVLRDEVMES, 0))) * 100);
      exception
        when ZERO_DIVIDE then
          VPERCVENDAPF := 0;
        when others then
          VPERCVENDAPF := 0;
      end;
      update PCCONSUM
      set    PERVENDAPF = NVL(VPERCVENDAPF, 0);
    end loop;
    insert into PCLOGJOB
      (MODULO,
       FUNCAO,
       TIPO_LOG,
       DATA_LOG,
       DS_JOB)
    values
      ('RECALCPERCENTVENDPF',
       'pcfilial',
       'FI',
       sysdate,
       'Final Recálculo do %Venda para Pessoa Física');
    commit;
  end;

--Bloqueia Clientes Inativos a mais de X Dias  (P_PC_BLOQUEACLIENTEINATIVO)
  procedure P_PC_BLOQUEACLIENTEINATIVO(USUARIO IN NUMBER,
                                      OPCAO IN NUMBER,
                                      pCODIGOROTINA IN NUMBER DEFAULT 504,
                                       -- Parametro de saida
                                       PVC2MENSSAGEN out varchar2) is
    /*********************************************************************************
    Opção 10 - Bloqueia Clientes Inativos a mais de X Dias
    ---------------------------------- Historico -------------------------------------
        Data        Responsavel    Comentarios
    ------------  ---------------  ---------------------------------------------------
     22/07/2008    Max Faria        Transcrição para PLSQL da opção 10 da rotina 504
     25/07/2011    Tatiane Mota     Gravar na tabela pcloglc as modificações de bloqueio
     05/08/2011    Tatiane Mota     verificar o parametro VBLOQDESBLOQCLIFORNEC para bloquear ou não o cliente fornecedor.
     24/02/2011    Tatiane Mota     Colocado NVL no campo LIMCRED cliente para gravar zero caso seja nulo
    *********************************************************************************/
    VNUMDIASCLIINATIV              PCCONSUM.NUMDIASCLIINATIV%type;
    VBLOQDESBLOQCLIFORNEC          VARCHAR2(1);
    VZERALIMCREDBLOQAUTOMATIC      PCCONSUM.ZERALIMCREDBLOQAUTOMATIC%type;
    VCODPLPAGINICIAL               PCCONSUM.CODPLPAGINICIAL%type;
    VCODCOBINICIAL                 PCCONSUM.CODCOBINICIAL%type;
    VLIMCREDINICIALPF              PCCONSUM.LIMCREDINICIALPF%type;
    VLIMCREDINICIAL                PCCONSUM.LIMCREDINICIAL%type;
    VUSADTDESBLOQUEIOBLOQCLIINATIV PCCONSUM.USADTDESBLOQUEIOBLOQCLIINATIV%type;
    VSQL                           varchar2(15000);
    VSQL2                          varchar2(5000);
    VSQL3                          varchar2(800);
    VDESCRICAOOPCAO                varchar2(90);
    VPARAMETROS                    varchar2(400);
    vPosicaoExec                   varchar2(400);
    VGERARLOGCLIBLOQ               VARCHAR2(1);
  begin
    vPosicaoExec := 'Início';
    if OPCAO = 23 then
        VDESCRICAOOPCAO := 'Zera Limite e altera cobrança para D para Clientes Inativos a mais de X Dias';
    else
        VDESCRICAOOPCAO := 'Bloqueia Clientes Inativos a mais de X Dias';
    end if;

    insert into PCLOGJOB
      (MODULO,
       FUNCAO,
       TIPO_LOG,
       DATA_LOG,
       DS_JOB,
       PARAMETROS)
    values
      ('BLOQUEACLIINATIVO',
       'PCCLIENT',
       'IN',
       sysdate,
       'Inicio ' || VDESCRICAOOPCAO,
       OPCAO);

    commit;
    vPosicaoExec := 'Obter parâmetros';

    select NVL(NUMDIASCLIINATIV, 0) NUMDIASCLIINATIV,
           NVL(ZERALIMCREDBLOQAUTOMATIC, 'S'),
           NVL(CODPLPAGINICIAL, 0) CODPLPAGINICIAL,
           NVL(CODCOBINICIAL, '0') CODCOBINICIAL,
           NVL(LIMCREDINICIALPF,0),
           NVL(LIMCREDINICIAL,0),
           NVL(USADTDESBLOQUEIOBLOQCLIINATIV, 'N') USADTDESBLOQUEIOBLOQCLIINATIV
    into   VNUMDIASCLIINATIV,
           VZERALIMCREDBLOQAUTOMATIC,
           VCODPLPAGINICIAL,
           VCODCOBINICIAL,
           VLIMCREDINICIALPF,
           VLIMCREDINICIAL,
           VUSADTDESBLOQUEIOBLOQCLIINATIV
    from   PCCONSUM;

    SELECT NVL(PCPARAMFILIAL.VALOR,'N')
      INTO VBLOQDESBLOQCLIFORNEC
      FROM PCPARAMFILIAL
     WHERE PCPARAMFILIAL.NOME = 'BLOQDESBLOQCLIFORNEC';

    SELECT NVL(PCPARAMFILIAL.VALOR,'S')
      INTO VGERARLOGCLIBLOQ
      FROM PCPARAMFILIAL
     WHERE PCPARAMFILIAL.NOME = 'CON_GERLOGCLIBLOQ';

    if VNUMDIASCLIINATIV = 0
    then
      VNUMDIASCLIINATIV := 60;
    end if;

    -- GRAVANDO PARAMETROS
    VPARAMETROS := 'OPCAO=' || OPCAO;
    VPARAMETROS := VPARAMETROS || ',NUMDIASCLIINATIV='||VNUMDIASCLIINATIV;
    VPARAMETROS := VPARAMETROS || ',ZERALIMCREDBLOQAUTOMATIC='||VZERALIMCREDBLOQAUTOMATIC;
    VPARAMETROS := VPARAMETROS || ',CODPLPAGINICIAL='||VCODPLPAGINICIAL;
    VPARAMETROS := VPARAMETROS || ',CODCOBINICIAL='||VCODCOBINICIAL;
    VPARAMETROS := VPARAMETROS || ',LIMCREDINICIALPF='||VLIMCREDINICIALPF;
    VPARAMETROS := VPARAMETROS || ',LIMCREDINICIAL='||VLIMCREDINICIAL;
    VPARAMETROS := VPARAMETROS || ',USADTDESBLOQUEIOBLOQCLIINATIV='||VUSADTDESBLOQUEIOBLOQCLIINATIV;
    VPARAMETROS := VPARAMETROS || ',BLOQDESBLOQCLIFORNEC='||VBLOQDESBLOQCLIFORNEC;

    insert into PCLOGJOB
      (MODULO,
       FUNCAO,
       TIPO_LOG,
       DATA_LOG,
       DS_JOB,
       PARAMETROS)
    values
      ('BLOQUEACLIINATIVO',
       'PCCLIENT',
       'AN',
       sysdate,
       'Inicio ' || VDESCRICAOOPCAO,
       SUBSTR(VPARAMETROS, 1, 200));
    vPosicaoExec := 'Montar VSQL2';

    --BLOQUEANDO CLIENTES INATIVOS.
    VSQL2 :=           'INSERT INTO PCLOGLC(  CODCLI,
                                             CODEMITE,
                                             LIMCREDANT,
                                             LIMCRED,
                                             CODPLPAGANT,
                                             CODPLPAG,
                                             CODCOBANT,
                                             CODCOB,
                                             DATA,
                                              OBS1,
                                              PROGRAMA,
                                              BLOQUEIOANT,
                                              BLOQUEIO,
                                              DTREGLIMANT,
                                              DTVENCLIMCRED,
                                              DTVENCLIMANT,
                                              OBSANT,
                                              OBS,
                                              PRAZO,
                                              PRAZOANT,
                                              OBS2,
                                              OBS3,
                                              DTULTCOMP,
                                              DTULTCOMPANT,
                                              OBSALT)
                       SELECT
                          PCCLIENT.CODCLI
                         ,'||USUARIO||'
                         , NVL(PCCLIENT.LIMCRED,0)';
  IF (VZERALIMCREDBLOQAUTOMATIC = 'S') OR (VZERALIMCREDBLOQAUTOMATIC = 'P') THEN
      VSQL2 := VSQL2 || '   ,0
                            ,PCCLIENT.CODPLPAG
                            ,PCCLIENT.CODPLPAG
                            ,PCCLIENT.CODCOB';
     if OPCAO = 23 then
        VSQL2 := VSQL2 || ', ''D''';
    else
        VSQL2 := VSQL2 || '   ,PCCLIENT.CODCOB';
   end if;
   END IF;
   IF VZERALIMCREDBLOQAUTOMATIC = 'I' THEN
       VSQL2 := VSQL2 ||  ' ,DECODE (TIPOFJ, ''F'',
                        '|| VLIMCREDINICIALPF || ',
                        '|| VLIMCREDINICIAL || ')
                            ,PCCLIENT.CODPLPAG
                        ,'|| VCODPLPAGINICIAL || '
                            ,PCCLIENT.CODCOB';
     if OPCAO = 23 then
        VSQL2 := VSQL2 || ', ''D''';
    else
        VSQL2 := VSQL2 || '  ,'''|| VCODCOBINICIAL||'''';
    end if;

   END IF;
   IF VZERALIMCREDBLOQAUTOMATIC = 'N' THEN
      VSQL2 := VSQL2 || ' ,PCCLIENT.LIMCRED
                          ,PCCLIENT.CODPLPAG
                          ,PCCLIENT.CODPLPAG
                          ,PCCLIENT.CODCOB';
     if OPCAO = 23 then
        VSQL2 := VSQL2 || ', ''D''';
    else
        VSQL2 := VSQL2 || ' ,PCCLIENT.CODCOB ';
   end if;
   END IF;
      VSQL2 := VSQL2 || '    ,SYSDATE,                ';


   if OPCAO = 23 then
     VSQL2 := VSQL2 || '''LIMITE ZERADO POR INATIVIDADE'',';
   else
     IF VUSADTDESBLOQUEIOBLOQCLIINATIV = 'N' THEN
       VSQL2 := VSQL2 || '''BLOQ. AUT. POR ' || VNUMDIASCLIINATIV || ' DIAS INATIVO'',';
     ELSE
       VSQL2 := VSQL2 || '''BLOQ. AUT. POR ' || VNUMDIASCLIINATIV || ' DIAS INATIVO (DATA DESBLOQUEIO)'',';
     END IF;
   end if;

   VSQL2 := VSQL2 || pCODIGOROTINA || ', NVL(PCCLIENT.BLOQUEIO,''N''), ';

   if OPCAO = 23 then
    VSQL2 := VSQL2  ||  'NVL(PCCLIENT.BLOQUEIO,''N''),';
   ELSE
    VSQL2 := VSQL2  ||  '''S'',                       ';
   END IF;

      VSQL2 := VSQL2 || 'NVL(PCCLIENT.DTREGLIM,TRUNC(SYSDATE)),          '||
                        'NVL(PCCLIENT.DTVENCLIMCRED,TRUNC(SYSDATE)),     '||
                        'NVL(PCCLIENT.DTREGLIM,TRUNC(SYSDATE)),          '||
                        '''NULO'',                      '||
                        '''NULO'',                      '||
                        'NVL(PCCLIENT.PRAZOADICIONAL,1),' ||
                        'NVL(PCCLIENT.PRAZOADICIONAL,1),    ';

    IF VUSADTDESBLOQUEIOBLOQCLIINATIV = 'N' THEN
      VSQL2 := VSQL2 || 'DECODE(NVL(DTULTCOMP, ''''), '''', ''NUNCA COMPROU'', TRUNC(SYSDATE) - DTULTCOMP || '' DIAS EM INATIVIDADE'') , ';
    ELSE
      VSQL2 := VSQL2 || 'TRUNC (SYSDATE) - (GREATEST(NVL(DTULTCOMP, TO_DATE(''01/01/1900'',''dd/mm/yyyy'')), NVL(DTDESBLOQUEIO,DTULTCOMP))) || ''DIAS EM INATIVIDADE'',';
    END IF;

    VSQL2 := VSQL2 || ' ''DATA ULT. COMPRA: '' || TO_CHAR(DTULTCOMP, ''DD/MM/YYYY'') || ''; DATA DESBLOQUEIO: '' ||  TO_CHAR(DTDESBLOQUEIO, ''DD/MM/YYYY'')  ';
    VSQL2 := VSQL2 || '    , DTULTCOMP, DTULTCOMP ';
    VSQL2 := VSQL2 || '    , ' || '''' || VPARAMETROS || '''';
    VSQL2 := VSQL2 || '    FROM PCCLIENT';
    VSQL2 := VSQL2 || ' WHERE DTCADASTRO<((TRUNC(SYSDATE))-(' || VNUMDIASCLIINATIV || '))';
    VSQL2 := VSQL2 || ' AND CODCLI NOT IN (1,2,3) ';
    if VUSADTDESBLOQUEIOBLOQCLIINATIV = 'N'
    then
      VSQL2 := VSQL2 || ' AND (DTULTCOMP IS NULL OR DTULTCOMP<((TRUNC(SYSDATE))-(' || VNUMDIASCLIINATIV || ')) )';
    else
      VSQL2 := VSQL2 || ' AND (((DTULTCOMP IS NULL) AND (DTDESBLOQUEIO IS NULL))';
      VSQL2 := VSQL2 || '  OR ( GREATEST(NVL(DTULTCOMP, TO_DATE(''01/01/1900'',''dd/mm/yyyy'')), ';
      VSQL2 := VSQL2 || '                 NVL(DTDESBLOQUEIO,DTULTCOMP)) ';
      VSQL2 := VSQL2 || '       < ((TRUNC(SYSDATE) - (' || VNUMDIASCLIINATIV ||'))) ) )';
    end if;

    --Alterado a pedido de Bruno.Martins e Luciano.Morais (3848.142051.2016)
    if NVL(VGERARLOGCLIBLOQ, 'S')  = 'N' then
       VSQL2 := VSQL2 || ' AND NVL(BLOQUEIO,''N'')=''N'' ';
    end if;
    VSQL2 := VSQL2 || ' AND NVL(BLOQUEIODEFINITIVO,''N'') <> ''S'' ';
    --5577.005065.2017 - parâmetro por Cliente que define se ele pode ser bloqueado por inatividade
    VSQL2 := VSQL2 || ' AND NVL(BLOQUEIOINATIVIDADE,''S'') = ''S'' ';
    --Incluído por Rondinelli.Borges para evitar que o cliente fosse bloqueado mais de uma vez por inatividade (2752.008338.2017)
    if OPCAO = 23 then
      VSQL2 := VSQL2 || ' AND (OBS IS NULL OR OBS NOT LIKE ''LIMITE ZERADO POR INATIVIDADE'')';
    else
      VSQL2 := VSQL2 || ' AND (OBS IS NULL OR OBS NOT LIKE ''BLOQ. AUT. POR % DIAS INATIVO'')';
    end if;

--    IF VBLOQDESBLOQCLIFORNEC = 'N' THEN
        VSQL2 := VSQL2 || ' AND   NOT EXISTS
                                  (SELECT PCFORNEC.CODCLI
                                         FROM   PCFORNEC
                                         WHERE  PCFORNEC.CODCLI = PCCLIENT.CODCLI
                                         AND    PCFORNEC.REVENDA = ''S'')';
--    END IF;

--  VERIFICA SE LIMCRED <> 0 PARA NAO COLOCAR LIMCRED=0 ONDE JA E
    VSQL2 := VSQL2 || ' AND LIMCRED <> 0';

    execute immediate VSQL2;
    commit;


    vPosicaoExec := 'Montar VSQL';
    VSQL := 'UPDATE PCCLIENT SET ';

    IF (VZERALIMCREDBLOQAUTOMATIC = 'S') OR  (VZERALIMCREDBLOQAUTOMATIC = 'P') THEN
      VSQL := VSQL || ' LIMCRED = 0,';
    end if;

    if VZERALIMCREDBLOQAUTOMATIC = 'I' then
      VSQL := VSQL || ' CODPLPAG = ' || '''' || VCODPLPAGINICIAL || '''' || ',';

      if OPCAO = 23 then
         VSQL := VSQL || ' CODCOB = ''D'',';
      else
         VSQL := VSQL || ' CODCOB = ' || '''' || VCODCOBINICIAL || '''' || ',';
      end if;
         VSQL := VSQL || ' LIMCRED = DECODE (TIPOFJ, ''F'',' || VLIMCREDINICIALPF || ',' || VLIMCREDINICIAL || '),';
    else
      if OPCAO = 23 then
         VSQL := VSQL || ' CODCOB = ''D'',';
      end if;
    end if;

    if OPCAO <> 23 then
       VSQL := VSQL || ' BLOQUEIO = ''S'' ,';
       VSQL := VSQL || ' DTBLOQ = TRUNC(SYSDATE),';
       VSQL := VSQL || ' OBS = ''BLOQ. AUT. POR '|| VNUMDIASCLIINATIV || ' DIAS INATIVO''';
    else
       VSQL := VSQL || ' OBS = ''SOMENTE VENDAS EM DINHEIRO''';
    end if;

    --GRANDO O CODIGO DO USUARIO DO WINTHOR QUE REALIZOU A ALTERAÇÃO NO REGISTRO DO CLIENTE
    VSQL := VSQL || ', CODFUNCULTALTER = '|| USUARIO;
    --GRAVANDO A ROTINA QUE FEZ A ULTIMA ALTERACAO NO CLIENTE
    VSQL := VSQL || ', CODROTINAALT = ' || pCODIGOROTINA;

    VSQL := VSQL || ' WHERE DTCADASTRO<((TRUNC(SYSDATE))-(' ||
            VNUMDIASCLIINATIV || '))';

    VSQL := VSQL || ' AND CODCLI NOT IN (1,2,3) ';

    if VUSADTDESBLOQUEIOBLOQCLIINATIV = 'N'
    then
      VSQL := VSQL || ' AND (DTULTCOMP IS NULL OR DTULTCOMP<((TRUNC(SYSDATE))-(' || VNUMDIASCLIINATIV || ')) )';
    else
      VSQL := VSQL || ' AND (((DTULTCOMP IS NULL) AND (DTDESBLOQUEIO IS NULL))';
      VSQL := VSQL ||
              '   OR ( GREATEST(NVL(DTULTCOMP, TO_DATE(''01/01/1900'',''dd/mm/yyyy'')), ';
      VSQL := VSQL || '                 NVL(DTDESBLOQUEIO,DTULTCOMP)) ';
      VSQL := VSQL || '       < ((TRUNC(SYSDATE) - (' || VNUMDIASCLIINATIV ||
              '))) ) )';
    end if;

    --Alterado a pedido de Bruno.Martins e Luciano.Morais (3848.142051.2016)
    if NVL(VGERARLOGCLIBLOQ, 'S')  = 'N' then
       VSQL := VSQL || ' AND NVL(BLOQUEIO,''N'')=''N'' ';
    end if;
    VSQL := VSQL || ' AND NVL(BLOQUEIODEFINITIVO,''N'') <> ''S'' ';
    --5577.005065.2017 - parâmetro por Cliente que define se ele pode ser bloqueado por inatividade
    VSQL := VSQL || ' AND NVL(BLOQUEIOINATIVIDADE,''S'') = ''S'' ';
    --Incluído por Rondinelli.Borges para evitar que o cliente fosse bloqueado mais de uma vez por inatividade (2752.008338.2017)
    if OPCAO = 23 then
      VSQL := VSQL || ' AND (OBS IS NULL OR OBS NOT LIKE ''LIMITE ZERADO POR INATIVIDADE'')';
    else
      VSQL := VSQL || ' AND (OBS IS NULL OR OBS NOT LIKE ''BLOQ. AUT. POR % DIAS INATIVO'')';
    end if;

--    IF VBLOQDESBLOQCLIFORNEC = 'N' THEN
       VSQL := VSQL || ' AND   NOT EXISTS
                                  (SELECT PCFORNEC.CODCLI
                                         FROM   PCFORNEC
                                         WHERE  PCFORNEC.CODCLI = PCCLIENT.CODCLI
                                         AND    PCFORNEC.REVENDA = ''S'')';
--    END IF;

--  VERIFICA SE LIMCRED <> 0 PARA NAO COLOCAR LIMCRED=0 ONDE JA E
    VSQL2 := VSQL2 || ' AND LIMCRED <> 0';

    --if OPCAO <> 23 then
     -- P_PC_GRAVARLOGBLOQAUTOM(TO_CHAR(REGISTRO.CODCLI), PUSUARIO, '504', 'BLOQ.AUTOMATICO CADASTRO');
    --end if;

    execute immediate VSQL;

    vPosicaoExec := 'Fim';
    commit;
    insert into PCLOGJOB
      (MODULO,
       FUNCAO,
       TIPO_LOG,
       DATA_LOG,
       DS_JOB,
       PARAMETROS)
    values
      ('BLOQUEACLIINATIVO',
       'PCCLIENT',
       'FI',
       sysdate,
       'Final ' || VDESCRICAOOPCAO,
       OPCAO);
    commit;

    EXCEPTION

      WHEN OTHERS THEN
        raise_application_error(-20001,'Ocorreu uma falha ao executar P_PC_BLOQUEACLIENTEINATIVO - '||SQLCODE||' -ERROR- '||SQLERRM || '. Posição: ' ||vPosicaoExec);
  end;

--Bloqueia/Desbloqueia Clientes Automaticamente  (P_PC_BLOQUEARCLIENTES)
  procedure P_PC_BLOQUEARCLIENTES(PUSUARIO IN VARCHAR2 DEFAULT '',
                                  -- Parametro de saida
                                  PVC2MENSSAGEN out varchar2) is
    /**********************************************************************************
     Opção 7 - Bloqueia/Desbloqueia Clientes Automaticamente
    ----------------------------------- Historico -------------------------------------
        Data        Responsavel    Comentarios
    ------------  ---------------  ----------------------------------------------------
     22/07/2008    Max Faria        Transcrição para PLSQL da opção 7 da rotina 504.
                                    Para que esta procedure rode corretamente e preciso
                                    criar os indices PCCLIENT_IDX15 e PCCLIENT_IDX16.
     11/12/2008    Carolina         Parãmetro de número de dias para desbloqueo autómatico
                                    de CHD1 e CHD3. O valor que anteriormente era fixo ¿7¿
                                    passa a ser configurável (parâmetros da presidência).
     03/11/2008   Hoê               Incluído bloqueio de cliente por excesso de devoluções,
                                    conforme tarefa 92.018, projeto 84.175, cliente 2138 - Serramais
     18/01/2009   Hoê               Bloqueio de Clientes da Rede (PCCLIENT.CODCLPRINC) - Tarefa 89.414
     01/07/2010  Tatiane          Foi incluido a clausula para que seja desbloqueados os clientes que nao
                                    estejam com  a DTVALIDASEFAZ preenchida. Essa validação foi feito para o bloq
                                    automatico e para o desbloq de CHD1 e CHD3
     12/11/2010  Tatiane          Rotina alterada para quando parâmetro que permite bloq/desbloq automaticamente
                                    clientes de fornecedores com titulos atrasados estiver marcado permitir que clientes
                                    que são fornecedores e estiverem com titulos atrasados sejam bloq ou desbloq.
     13/01/2011  Tatiane          Procedure alterada para que seja verificado na pcparamfilial o parametro NUMDIASCLIATRASO
                                    Caso este valor esteja abaixo do valor que o cliente está em atraso o cliente ficará bloqueado
                                    definitivo e poderá apenas ser desbloqueado manualemnte.
     24/02/2011 Eduardo Mendonça  Alterado teste de dias vencidos do título para considerar os dias úteis por filial
     28/02/2011 Eduardo Mendonça  Alterado procedure para validar o parâmetro 1270 da PCConsum
     18/07/2011 Watson Willian    Alterado procedure para utilizar nova procedure de bloqueio por codigo de cliente;
     19/02/2014 Bruno Martins - Incluido o parâmetro de PUSUARIO para que seja gravado no LOG
 **********************************************************************************/

  /*  VCONTADOR    number := 0;
    VVLVENDA     number := 0;
    VVLDEVOLUCAO number := 0;
    VAL          VARCHAR2(1);
    VS_SQL       VARCHAR2(2000);
    QTDIAS       number := 0;
    BLOQDEF      number := 0;*/
    VS_ZERALIMCREDAUTOMATICO VARCHAR2(1);
/*    VMUDACOBCLIENTE      PCCONSUM.MUDACOBCLIENTE%type;
    VMUDACOBCLIENTEDIAS  PCCONSUM.MUDACOBCLIENTEDIAS%type;
    VBLOQCLIENTEEXCDEVOL PCCONSUM.BLOQCLIENTEEXCDEVOL%type;
    VPERCEXCESSODEVOL    PCCONSUM.PERCEXCESSODEVOL%type;
    VDIASANALISEDEVOL    PCCONSUM.DIASANALISEDEVOL%type;
    VBLOQCODCLIPRINC     PCCONSUM.BLOQCODCLIPRINC%type;*/
  begin
    SELECT VALOR
    INTO VS_ZERALIMCREDAUTOMATICO
    FROM PCPARAMFILIAL
    WHERE NOME = 'CON_ZERALIMCREDBLOQAUTOMATIC';

    -- DESBLOQUEANDO CLIENTES BLOQUEADOS AUTOMATICO.
    insert into PCLOGJOB
      (MODULO,
       FUNCAO,
       TIPO_LOG,
       DATA_LOG,
       DS_JOB)
    values
      ('BLOQUEARCLIENTES',
       'PCCLIENT',
       'IN',
       sysdate,
       'Inicio Bloqueia/Desbloqueia Clientes Automaticamente');
    commit;


    p_pc_BloqueioClientePorCodigo(0,PVC2MENSSAGEN, PUSUARIO);

    insert into PCLOGJOB
      (MODULO,
       FUNCAO,
       TIPO_LOG,
       DATA_LOG,
       DS_JOB)
    values
      ('BLOQUEARCLIENTES',
       'PCCLIENT',
       'FI',
       sysdate,
       'Final Bloqueia/Desbloqueia Clientes Automaticamente');
    commit;
  end;

  --Armazenar Saldos Estoque de Lote  (P_PC_ARMAZENASALDOESTOQUELOTE)
procedure P_PC_ARMAZENASALDOESTOQUELOTE(
                                                          -- Parametros de entrada
                                                          PDTPROCESSAMENTO in date,
                                                          PCODFILIAL IN VARCHAR2,
                                                          -- Parametro de saida
                                                          PVC2MENSSAGEN out varchar2) is
  /*********************************************************************************
  Opção 4.1 - Armazenar Saldos Estoque de Lote
  ---------------------------------- Historico -------------------------------------
      Data        Responsavel    Comentarios
  ------------  ---------------  ---------------------------------------------------
   22/07/2008    Max Faria        Transcrição para PLSQL da opção 4.1 da rotina 504
  *********************************************************************************/
  VCONTADOR    number := 0;
  ERROINSERCAO VARCHAR2(500);
begin
  insert into PCLOGJOB
    (MODULO, FUNCAO, TIPO_LOG, DATA_LOG, DS_JOB)
  values
    ('ARMAZENASALDESTLOTE',
     'pchistestlote',
     'IN',
     sysdate,
     'Inicio Armazenar Saldos Estoque de Lote');
  commit;

  IF PCODFILIAL IS NULL THEN
      select count(1)
        into VCONTADOR
        from PCHISTESTLOTE
       where DATA = PDTPROCESSAMENTO
         and ROWNUM = 1;
  ELSE
      select count(1)
        into VCONTADOR
        from PCHISTESTLOTE
       where DATA = PDTPROCESSAMENTO
         and CODFILIAL = PCODFILIAL
         and ROWNUM = 1;
  END IF;

  if VCONTADOR = 0 then
   for REGISTRO in (select PCLOTE.CODFILIAL,
                           PCLOTE.CODPROD,
                           PCLOTE.QT,
                           PCLOTE.QTEST,
                           PCLOTE.QTRESERV,
                           PCLOTE.QTBLOQUEADA,
                           PCLOTE.QTINDENIZ,
                           PCLOTE.NUMLOTE
                      from PCLOTE
                     where PCLOTE.CODFILIAL <> '99'
                       AND (DECODE(PCODFILIAL,'99',NULL,PCODFILIAL) IS NULL OR PCLOTE.CODFILIAL = PCODFILIAL))
   loop
      BEGIN
        insert into PCHISTESTLOTE
          (CODFILIAL,
           CODPROD,
           DATA,
           QT,
           QTEST,
           QTRESERV,
           QTBLOQUEADA,
           QTINDENIZ,
           DTGERACAO,
           NUMLOTE)
        values
          (REGISTRO.CODFILIAL,
           REGISTRO.CODPROD,
           PDTPROCESSAMENTO,
           REGISTRO.QT,
           REGISTRO.QTEST,
           REGISTRO.QTRESERV,
           REGISTRO.QTBLOQUEADA,
           REGISTRO.QTINDENIZ,
           sysdate,
           REGISTRO.NUMLOTE);
      EXCEPTION
        WHEN OTHERS THEN
          BEGIN
            ERROINSERCAO := SQLCODE || SQLERRM;
            INSERT INTO PCLOGALTERACAODADOS
              (DATA, CODROTINA, TABELA, OBSERVACOES, OBSERVACOES2)
            VALUES
              (SYSDATE,
               '504',
               'PCHISTESTLOTE',
               'Erro ao inserir registro codprod: ' || REGISTRO.codPROD ||' filial: ' || REGISTRO.CODFILIAL || ' NUMLOTE ' ||REGISTRO.NUMLOTE,
               'erro sql: ' || ERROINSERCAO);

          END;
      END;

    end loop;
  end if;
  commit;
  insert into PCLOGJOB
    (MODULO, FUNCAO, TIPO_LOG, DATA_LOG, DS_JOB)
  values
    ('ARMAZENASALDESTLOTE',
     'pchistestlote',
     'FI',
     sysdate,
     'Final Armazenar Saldos Estoque de Lote');
  commit;
end;

PROCEDURE P_PC_ARMAZENARSALDOSESTOQUE(PDTPROCESSAMENTO IN DATE
                                       ,PCODFILIAL IN VARCHAR2
                                       ,PVC2MENSSAGEN    OUT VARCHAR2)
  IS
    /*********************************************************************************
    Opção 4 - Armazenar Saldos Estoque
    ---------------------------------- Historico -------------------------------------
        Data        Responsavel    Comentarios
    ------------  ---------------  ---------------------------------------------------
     22/07/2008    Max Faria        Transcrição para PLSQL da opção 4 da rotina 504
     22/08/2008    Max Faria        Incluido o campo gerarhistest
     15/01/2010    Hoê              Atualizar e comitar saldos por Filial (Tarefa 89.699)
     12/08/2010   Tatiane           Gravar na PCHISTESTTRANSITO as informações da PCESTTRANSITO e também
                                    gravar as informações do campo QTTRANSITO da PCEST na PCHISTEST ( Projeto 93520) Tarefa 110932
     29/07/2011   Tatiane           alterado o select da pcest para nao trazer estoque zerado e nem com data da ultima entrada nula
     04/10/2011   Tatiane           Alterada procedure para testar existência de valores antes de incluir na tabela PCHISTESTTRANSITO
     10/10/2011   Tatiane           Alterado para verificar parâmetro GERARPCHISTESTPARA, caso esteja marcado 'E' gerar pchistest somente para produtos com estoque.
                                    Senão para todos.
     25/10/2011   Tatiane           Rotina alterada pra gravar SITTRIBUT.
     27/10/2011   Tatiane           alteração da gravação de dados da pchistest
     12/12/2014   PAULO GONCALVES - MUDANDO O SQL DE INSERCAO NA PCHISTEST, POIS AGORA FARÁ UM LOOP NA PCPRODUT E DEPOIS PARA CADA PRODUTO A CONSULTA NA PCEST. PARA EVITAR FULL SCAN NAS DUAS TABELAS.
     26/12/2016   IAGO SOUSA      - Criado log de erro ao inserir na pchistest
     15/03/2017   Rafael Braga/Diego Cardoso    - Baseado na estrutura reescrita por Diego Cardoso, adaptado algumas regras
     17/12/2018   Fernandes Brito   Ajustado o select que alimenta o cursor principal para não obrigar a existencia da PCPRODFILIAL.
    *********************************************************************************/
    /* Declaração do cursor usado na gravação do PCHISTEST */
    CURSOR V_CURSOR_PRODUTOS(V_FILIAL             VARCHAR2
                            ,VPROCESSAMENTO       DATE
                            ,V_GERARPCHISTESTPARA VARCHAR2
                            ,V_USATRIBUTACAOPORUF VARCHAR2)
    IS
      /* Select para listar os estoque da filial */
      SELECT CODFILIAL,
             CODPROD,
             NBM,
             DESCRICAO,
             CLASSIFICFISCAL,
             UNIDADE,
             DATA,
             QTEST,
             QTESTGER,
             QTRESERV,
             QTBLOQUEADA,
             QTPENDENTE,
             QTULTENT,
             QTINDENIZ,
             CUSTOCONT,
             CUSTOREAL,
             CUSTOFIN,
             CUSTOREP,
             CUSTOULTENT,
             VALORULTENT,
             CUSTODOLAR,
             CUSTOREALSEMST,
             CUSTOULTENTMED,
             CUSTOULTPEDCOMPRA,
             CUSTOFORNEC,
             VALORULTENTMED,
             DTGERACAO,
             QTTRANSITO,
             QTFRENTELOJA,
             CUSTOFINSEMST,
             CUSTOULTENTFINSEMST,
             CUSTOULTENTSEMST,
             CUSTOFORNECSEMST,
             CUSTONFSEMSTGUIAULTENT,
             CUSTONFSEMST,
             CUSTONFSEMSTGUIAULTENTTAB,
             CUSTONFSEMSTTAB,
             CUSTOPROXIMACOMPRA,
             CUSTOPROXIMACOMPRASEMST,
             CUSTOREALLIQ,
             CUSTOULTENTANT,
             CUSTOULTENTCONT,
             CUSTOULTENTFIN,
             CUSTOULTENTLIQ,
             DTULTENT,
             VLCUSTODIAFIN,
             VLCUSTODIAREAL,
             VLCUSTOMESFIN,
             VLCUSTOMESFINANT,
             VLCUSTOMESREAL,
             VLCUSTOMESREALANT,
             VLFRETECONHECULTENT,
             VLFRETECONHECULTENTTAB,
             VLIMPORTACAOFCI,
             VLPARCELAIMPFCI,
             VLSTGUIAULTENT,
             VLSTGUIAULTENTTAB,
             VLSTULTENT,
             VLSTULTENTTAB,
             VLULTENTCONTSEMST,
             VLULTPCOMPRA,
             BASEBCR,
             STBCR,
             VLIPIULTENT,
             BASEIPIULTENT,
             PERCIPIULTENT,
             QTTRANSITOTV13,
             DV,
             CODAUXILIAR,
             CODPRODSINTEGRA,
             EMBALAGEM,
             DTEXCLUSAOPROD,
             TIPOMERC,
             TIPOMERCDEPTO,
             CODGENEROFISCAL,
             PERCST,
             PISCOFINSRETIDO,
             PERPIS,
             PERCOFINS,
             CODINTERNO,
             ALIQICMS1,
             SITTRIBUT,
             CODICM,
             CODCEST,
             QTESTOQUEEMTERCEIRO,
             QTESTOQUEDETERCEIRO,
             QTTRANSITOTV10
        FROM (SELECT E.CODFILIAL,
                     E.CODPROD,
                     PA.NBM,
                     PA.DESCRICAO,
                     NVL(PA.CLASSIFICFISCAL, V_FILIAL) CLASSIFICFISCAL,
                     PA.UNIDADE,
                     TRUNC(VPROCESSAMENTO) DATA,
                     NVL(E.QTEST, 0) QTEST,
                     NVL(E.QTESTGER, 0) QTESTGER,
                     NVL(E.QTRESERV, 0) QTRESERV,
                     NVL(E.QTBLOQUEADA, 0) QTBLOQUEADA,
                     NVL(E.QTPENDENTE, 0) QTPENDENTE,
                     NVL(E.QTULTENT, 0) QTULTENT,
                     NVL(E.QTINDENIZ, 0) QTINDENIZ,
                     NVL(E.CUSTOCONT, 0) CUSTOCONT,
                     NVL(E.CUSTOREAL, 0) CUSTOREAL,
                     NVL(E.CUSTOFIN, 0) CUSTOFIN,
                     NVL(E.CUSTOREP, 0) CUSTOREP,
                     NVL(E.CUSTOULTENT, 0) CUSTOULTENT,
                     NVL(E.VALORULTENT, 0) VALORULTENT,
                     NVL(E.CUSTODOLAR, 0) CUSTODOLAR,
                     NVL(E.CUSTOREALSEMST, 0) CUSTOREALSEMST,
                     NVL(E.CUSTOULTENTMED, 0) CUSTOULTENTMED,
                     NVL(E.CUSTOULTPEDCOMPRA, 0) CUSTOULTPEDCOMPRA,
                     CASE
                       WHEN NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('USAPOLITICACOMERCIALPRODFILIAL','99'),'P') = 'P' THEN
                        PA.CUSTOFORNEC
                     ELSE
                        E.CUSTOFORNEC
                     END CUSTOFORNEC,
                     NVL(E.VALORULTENTMED, 0) VALORULTENTMED,
                     SYSDATE DTGERACAO,
                     NVL(E.QTTRANSITO, 0) QTTRANSITO,
                     NVL(E.QTFRENTELOJA, 0) QTFRENTELOJA,
                     NVL(E.CUSTOFINSEMST, 0) CUSTOFINSEMST,
                     NVL(E.CUSTOULTENTFINSEMST, 0) CUSTOULTENTFINSEMST,
                     NVL(E.CUSTOULTENTSEMST, 0) CUSTOULTENTSEMST,
                     NVL(E.CUSTOFORNECSEMST, 0) CUSTOFORNECSEMST,
                     NVL(E.CUSTONFSEMSTGUIAULTENT, 0) CUSTONFSEMSTGUIAULTENT,
                     NVL(E.CUSTONFSEMST, 0) CUSTONFSEMST,
                     NVL(E.CUSTONFSEMSTGUIAULTENTTAB, 0) CUSTONFSEMSTGUIAULTENTTAB,
                     NVL(E.CUSTONFSEMSTTAB, 0) CUSTONFSEMSTTAB,
                     NVL(E.CUSTOPROXIMACOMPRA, 0) CUSTOPROXIMACOMPRA,
                     NVL(E.CUSTOPROXIMACOMPRASEMST, 0) CUSTOPROXIMACOMPRASEMST,
                     NVL(E.CUSTOREALLIQ, 0) CUSTOREALLIQ,
                     NVL(E.CUSTOULTENTANT, 0) CUSTOULTENTANT,
                     NVL(E.CUSTOULTENTCONT, 0) CUSTOULTENTCONT,
                     NVL(E.CUSTOULTENTFIN, 0) CUSTOULTENTFIN,
                     NVL(E.CUSTOULTENTLIQ, 0) CUSTOULTENTLIQ,
                     E.DTULTENT DTULTENT,
                     NVL(E.VLCUSTODIAFIN, 0) VLCUSTODIAFIN,
                     NVL(E.VLCUSTODIAREAL, 0) VLCUSTODIAREAL,
                     NVL(E.VLCUSTOMESFIN, 0) VLCUSTOMESFIN,
                     NVL(E.VLCUSTOMESFINANT, 0) VLCUSTOMESFINANT,
                     NVL(E.VLCUSTOMESREAL, 0) VLCUSTOMESREAL,
                     NVL(E.VLCUSTOMESREALANT, 0) VLCUSTOMESREALANT,
                     NVL(E.VLFRETECONHECULTENT, 0) VLFRETECONHECULTENT,
                     NVL(E.VLFRETECONHECULTENTTAB, 0) VLFRETECONHECULTENTTAB,
                     NVL(E.VLIMPORTACAOFCI, 0) VLIMPORTACAOFCI,
                     NVL(E.VLPARCELAIMPFCI, 0) VLPARCELAIMPFCI,
                     NVL(E.VLSTGUIAULTENT, 0) VLSTGUIAULTENT,
                     NVL(E.VLSTGUIAULTENTTAB, 0) VLSTGUIAULTENTTAB,
                     NVL(E.VLSTULTENT, 0) VLSTULTENT,
                     NVL(E.VLSTULTENTTAB, 0) VLSTULTENTTAB,
                     NVL(E.VLULTENTCONTSEMST, 0) VLULTENTCONTSEMST,
                     NVL(E.VLULTPCOMPRA, 0) VLULTPCOMPRA,
                     NVL(E.BASEBCR, 0) BASEBCR,
                     NVL(E.STBCR, 0) STBCR,
                     NVL(E.VLIPIULTENT, 0) VLIPIULTENT,
                     NVL(E.BASEIPIULTENT, 0) BASEIPIULTENT,
                     NVL(E.PERCIPIULTENT, 0) PERCIPIULTENT,
                     NVL(E.QTTRANSITOTV13, 0) QTTRANSITOTV13,
                     PA.DV DV,
                     PA.CODAUXILIAR CODAUXILIAR,
                     PA.CODPRODSINTEGRA CODPRODSINTEGRA,
                     PA.EMBALAGEM EMBALAGEM,
                     PA.DTEXCLUSAO DTEXCLUSAOPROD,
                     PA.TIPOMERC TIPOMERC,
                     D.TIPOMERC TIPOMERCDEPTO,
                     PA.CODGENEROFISCAL CODGENEROFISCAL,
                     PA.PERCST PERCST,
                     DECODE(PF.CODPROD,
                            NULL,
                            PA.PISCOFINSRETIDO,
                            PF.PISCOFINSRETIDO) PISCOFINSRETIDO,
                     DECODE(PF.CODPROD, NULL, PA.PERPIS, PF.PERPIS) PERPIS,
                     DECODE(PF.CODPROD, NULL, PA.PERCOFINS, PF.PERCOFINS) PERCOFINS,
                     PA.CODINTERNO CODINTERNO,
                     CASE
                       WHEN V_USATRIBUTACAOPORUF = 'N' THEN
                        (SELECT T.ALIQICMS1
                           FROM PCTABPR P, PCTRIBUT T, PCFILIAL F
                          WHERE P.CODST = T.CODST
                            AND P.CODPROD = PA.CODPROD
                            AND F.CODIGO = V_FILIAL
                            AND P.NUMREGIAO = F.NUMREGIAOPADRAO
                            AND ROWNUM = 1)
                       WHEN V_USATRIBUTACAOPORUF = 'S' THEN
                        (SELECT T.ALIQICMS1
                           FROM PCTABTRIB P, PCTRIBUT T, PCFILIAL F
                          WHERE P.CODST = T.CODST
                            AND P.CODPROD = PA.CODPROD
                            AND F.CODIGO = V_FILIAL
                            AND P.UFDESTINO = F.UF
                            AND ROWNUM = 1)
                       ELSE
                        0
                     END AS ALIQICMS1,
                     CASE
                       WHEN V_USATRIBUTACAOPORUF = 'N' THEN
                        (SELECT T.SITTRIBUT
                           FROM PCTABPR P, PCTRIBUT T, PCFILIAL F
                          WHERE P.CODST = T.CODST
                            AND P.CODPROD = PA.CODPROD
                            AND F.CODIGO = V_FILIAL
                            AND P.NUMREGIAO = F.NUMREGIAOPADRAO
                            AND ROWNUM = 1)
                       WHEN V_USATRIBUTACAOPORUF = 'S' THEN
                        (SELECT T.SITTRIBUT
                           FROM PCTABTRIB P, PCTRIBUT T, PCFILIAL F
                          WHERE P.CODST = T.CODST
                            AND P.CODPROD = PA.CODPROD
                            AND F.CODIGO = V_FILIAL
                            AND P.UFDESTINO = F.UF
                            AND ROWNUM = 1)
                       ELSE
                        '0'
                     END AS SITTRIBUT,
                     CASE
                       WHEN V_USATRIBUTACAOPORUF = 'N' THEN
                        (SELECT T.CODICM
                           FROM PCTABPR P, PCTRIBUT T, PCFILIAL F
                          WHERE P.CODST = T.CODST
                            AND P.CODPROD = PA.CODPROD
                            AND F.CODIGO = V_FILIAL
                            AND P.NUMREGIAO = F.NUMREGIAOPADRAO
                            AND ROWNUM = 1)
                       WHEN V_USATRIBUTACAOPORUF = 'S' THEN
                        (SELECT T.CODICM
                           FROM PCTABTRIB P, PCTRIBUT T, PCFILIAL F
                          WHERE P.CODST = T.CODST
                            AND P.CODPROD = PA.CODPROD
                            AND F.CODIGO = V_FILIAL
                            AND P.UFDESTINO = F.UF
                            AND ROWNUM = 1)
                       ELSE
                        0
                     END AS CODICM,
                     E.CODCEST,
                     E.QTESTOQUEEMTERCEIRO,
                     E.QTESTOQUEDETERCEIRO,
                     E.QTTRANSITOTV10
                FROM PCEST E,
                     PCPRODUT PA,
                     PCDEPTO D,
                     (SELECT CODPROD,
                             PISCOFINSRETIDO,
                             PERPIS,
                             PERCOFINS,
                             CODFILIAL,
                             GERARPCHISTEST
                        FROM PCPRODFILIAL
                       WHERE CODFILIAL = V_FILIAL) PF
               WHERE E.CODPROD  = PA.CODPROD
                 AND PA.CODEPTO = D.CODEPTO(+)
                 AND PA.CODPROD = PF.CODPROD(+)
                 AND E.CODPROD  >= (SELECT MIN(CODPROD) FROM PCEST WHERE CODFILIAL = V_FILIAL)
                 AND E.CODFILIAL = V_FILIAL
                 AND ((V_GERARPCHISTESTPARA = 'T') OR
                     (NVL(E.QTEST, 0) <> 0) OR
                     (NVL(E.QTESTGER, 0) <> 0) OR
                     (NVL(E.QTTRANSITO, 0) <> 0) OR
                     (NVL(E.QTTRANSITOTV13, 0) <> 0)));

    /* Variáveis internas */
    TYPE tpCODFILIAL IS TABLE OF PCHISTESTFILA.CODFILIAL%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCODPROD IS TABLE OF PCHISTESTFILA.CODPROD%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpNBM IS TABLE OF PCHISTESTFILA.NBM%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpDESCRICAO IS TABLE OF PCHISTESTFILA.DESCRICAO%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCLASSIFICFISCAL IS TABLE OF PCHISTESTFILA.CLASSIFICFISCAL%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpUNIDADE IS TABLE OF PCHISTESTFILA.UNIDADE%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpDATA IS TABLE OF PCHISTESTFILA.DATA%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpQTEST IS TABLE OF PCHISTESTFILA.QTEST%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpQTESTGER IS TABLE OF PCHISTESTFILA.QTESTGER%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpQTRESERV IS TABLE OF PCHISTESTFILA.QTRESERV%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpQTBLOQUEADA IS TABLE OF PCHISTESTFILA.QTBLOQUEADA%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpQTPENDENTE IS TABLE OF PCHISTESTFILA.QTPENDENTE%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpQTULTENT IS TABLE OF PCHISTESTFILA.QTULTENT%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpQTINDENIZ IS TABLE OF PCHISTESTFILA.QTINDENIZ%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTOCONT IS TABLE OF PCHISTESTFILA.CUSTOCONT%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTOREAL IS TABLE OF PCHISTESTFILA.CUSTOREAL%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTOFIN IS TABLE OF PCHISTESTFILA.CUSTOFIN%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTOREP IS TABLE OF PCHISTESTFILA.CUSTOREP%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTOULTENT IS TABLE OF PCHISTESTFILA.CUSTOULTENT%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpVALORULTENT IS TABLE OF PCHISTESTFILA.VALORULTENT%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTODOLAR IS TABLE OF PCHISTESTFILA.CUSTODOLAR%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTOREALSEMST IS TABLE OF PCHISTESTFILA.CUSTOREALSEMST%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTOULTENTMED IS TABLE OF PCHISTESTFILA.CUSTOULTENTMED%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTOULTPEDCOMPRA IS TABLE OF PCHISTESTFILA.CUSTOULTPEDCOMPRA%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTOFORNEC IS TABLE OF PCHISTESTFILA.CUSTOFORNEC%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpVALORULTENTMED IS TABLE OF PCHISTESTFILA.VALORULTENTMED%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpDTGERACAO IS TABLE OF PCHISTESTFILA.DTGERACAO%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpQTTRANSITO IS TABLE OF PCHISTESTFILA.QTTRANSITO%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpQTFRENTELOJA IS TABLE OF PCHISTESTFILA.QTFRENTELOJA%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTOFINSEMST IS TABLE OF PCHISTESTFILA.CUSTOFINSEMST%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTOULTENTFINSEMST IS TABLE OF PCHISTESTFILA.CUSTOULTENTFINSEMST%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTOULTENTSEMST IS TABLE OF PCHISTESTFILA.CUSTOULTENTSEMST%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTOFORNECSEMST IS TABLE OF PCHISTESTFILA.CUSTOFORNECSEMST%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTONFSEMSTGUIAULTENT IS TABLE OF PCHISTESTFILA.CUSTONFSEMSTGUIAULTENT%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTONFSEMST IS TABLE OF PCHISTESTFILA.CUSTONFSEMST%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTONFSEMSTGUIAULTENTTAB IS TABLE OF PCHISTESTFILA.CUSTONFSEMSTGUIAULTENTTAB%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTONFSEMSTTAB IS TABLE OF PCHISTESTFILA.CUSTONFSEMSTTAB%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTOPROXIMACOMPRA IS TABLE OF PCHISTESTFILA.CUSTOPROXIMACOMPRA%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTOPROXIMACOMPRASEMST IS TABLE OF PCHISTESTFILA.CUSTOPROXIMACOMPRASEMST%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTOREALLIQ IS TABLE OF PCHISTESTFILA.CUSTOREALLIQ%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTOULTENTANT IS TABLE OF PCHISTESTFILA.CUSTOULTENTANT%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTOULTENTCONT IS TABLE OF PCHISTESTFILA.CUSTOULTENTCONT%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTOULTENTFIN IS TABLE OF PCHISTESTFILA.CUSTOULTENTFIN%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCUSTOULTENTLIQ IS TABLE OF PCHISTESTFILA.CUSTOULTENTLIQ%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpDTULTENT IS TABLE OF PCHISTESTFILA.DTULTENT%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpVLCUSTODIAFIN IS TABLE OF PCHISTESTFILA.VLCUSTODIAFIN%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpVLCUSTODIAREAL IS TABLE OF PCHISTESTFILA.VLCUSTODIAREAL%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpVLCUSTOMESFIN IS TABLE OF PCHISTESTFILA.VLCUSTOMESFIN%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpVLCUSTOMESFINANT IS TABLE OF PCHISTESTFILA.VLCUSTOMESFINANT%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpVLCUSTOMESREAL IS TABLE OF PCHISTESTFILA.VLCUSTOMESREAL%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpVLCUSTOMESREALANT IS TABLE OF PCHISTESTFILA.VLCUSTOMESREALANT%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpVLFRETECONHECULTENT IS TABLE OF PCHISTESTFILA.VLFRETECONHECULTENT%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpVLFRETECONHECULTENTTAB IS TABLE OF PCHISTESTFILA.VLFRETECONHECULTENTTAB%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpVLIMPORTACAOFCI IS TABLE OF PCHISTESTFILA.VLIMPORTACAOFCI%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpVLPARCELAIMPFCI IS TABLE OF PCHISTESTFILA.VLPARCELAIMPFCI%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpVLSTGUIAULTENT IS TABLE OF PCHISTESTFILA.VLSTGUIAULTENT%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpVLSTGUIAULTENTTAB IS TABLE OF PCHISTESTFILA.VLSTGUIAULTENTTAB%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpVLSTULTENT IS TABLE OF PCHISTESTFILA.VLSTULTENT%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpVLSTULTENTTAB IS TABLE OF PCHISTESTFILA.VLSTULTENTTAB%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpVLULTENTCONTSEMST IS TABLE OF PCHISTESTFILA.VLULTENTCONTSEMST%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpVLULTPCOMPRA IS TABLE OF PCHISTESTFILA.VLULTPCOMPRA%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpBASEBCR IS TABLE OF PCHISTESTFILA.BASEBCR%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpSTBCR IS TABLE OF PCHISTESTFILA.STBCR%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpVLIPIULTENT IS TABLE OF PCHISTESTFILA.VLIPIULTENT%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpBASEIPIULTENT IS TABLE OF PCHISTESTFILA.BASEIPIULTENT%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpPERCIPIULTENT IS TABLE OF PCHISTESTFILA.PERCIPIULTENT%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpQTTRANSITOTV13 IS TABLE OF PCHISTESTFILA.QTTRANSITOTV13%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpDV IS TABLE OF PCHISTESTFILA.DV%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCODAUXILIAR IS TABLE OF PCHISTESTFILA.CODAUXILIAR%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCODPRODSINTEGRA IS TABLE OF PCHISTESTFILA.CODPRODSINTEGRA%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpEMBALAGEM IS TABLE OF PCHISTESTFILA.EMBALAGEM%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpDTEXCLUSAOPROD IS TABLE OF PCHISTESTFILA.DTEXCLUSAOPROD%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpTIPOMERC IS TABLE OF PCHISTESTFILA.TIPOMERC%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpTIPOMERCDEPTO IS TABLE OF PCHISTESTFILA.TIPOMERCDEPTO%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCODGENEROFISCAL IS TABLE OF PCHISTESTFILA.CODGENEROFISCAL%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpPERCST IS TABLE OF PCHISTESTFILA.PERCST%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpPISCOFINSRETIDO IS TABLE OF PCHISTESTFILA.PISCOFINSRETIDO%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpPERPIS IS TABLE OF PCHISTESTFILA.PERPIS%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpPERCOFINS IS TABLE OF PCHISTESTFILA.PERCOFINS%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCODINTERNO IS TABLE OF PCHISTESTFILA.CODINTERNO%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpALIQICMSVIGENTE IS TABLE OF PCHISTESTFILA.ALIQICMSVIGENTE%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpSITTRIBUT IS TABLE OF PCHISTESTFILA.SITTRIBUT%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCODICM IS TABLE OF PCHISTESTFILA.CODICM%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpCODCEST IS TABLE OF PCHISTESTFILA.CODCEST%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpQTESTOQUEEMTERCEIRO IS TABLE OF PCHISTESTFILA.QTESTOQUEEMTERCEIRO%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpQTESTOQUEDETERCEIRO IS TABLE OF PCHISTESTFILA.QTESTOQUEDETERCEIRO%TYPE INDEX BY BINARY_INTEGER;
    TYPE tpQTTRANSITOTV10 IS TABLE OF PCHISTESTFILA.QTTRANSITOTV10%TYPE INDEX BY BINARY_INTEGER;

    vtCODFILIAL                      tpCODFILIAL;
    vtCODPROD                        tpCODPROD;
    vtNBM                            tpNBM;
    vtDESCRICAO                      tpDESCRICAO;
    vtCLASSIFICFISCAL                tpCLASSIFICFISCAL;
    vtUNIDADE                        tpUNIDADE;
    vtDATA                           tpDATA;
    vtQTEST                          tpQTEST;
    vtQTESTGER                       tpQTESTGER;
    vtQTRESERV                       tpQTRESERV;
    vtQTBLOQUEADA                    tpQTBLOQUEADA;
    vtQTPENDENTE                     tpQTPENDENTE;
    vtQTULTENT                       tpQTULTENT;
    vtQTINDENIZ                      tpQTINDENIZ;
    vtCUSTOCONT                      tpCUSTOCONT;
    vtCUSTOREAL                      tpCUSTOREAL;
    vtCUSTOFIN                       tpCUSTOFIN;
    vtCUSTOREP                       tpCUSTOREP;
    vtCUSTOULTENT                    tpCUSTOULTENT;
    vtVALORULTENT                    tpVALORULTENT;
    vtCUSTODOLAR                     tpCUSTODOLAR;
    vtCUSTOREALSEMST                 tpCUSTOREALSEMST;
    vtCUSTOULTENTMED                 tpCUSTOULTENTMED;
    vtCUSTOULTPEDCOMPRA              tpCUSTOULTPEDCOMPRA;
    vtCUSTOFORNEC                    tpCUSTOFORNEC;
    vtVALORULTENTMED                 tpVALORULTENTMED;
    vtDTGERACAO                      tpDTGERACAO;
    vtQTTRANSITO                     tpQTTRANSITO;
    vtQTFRENTELOJA                   tpQTFRENTELOJA;
    vtCUSTOFINSEMST                  tpCUSTOFINSEMST;
    vtCUSTOULTENTFINSEMST            tpCUSTOULTENTFINSEMST;
    vtCUSTOULTENTSEMST               tpCUSTOULTENTSEMST;
    vtCUSTOFORNECSEMST               tpCUSTOFORNECSEMST;
    vtCUSTONFSEMSTGUIAULTENT         tpCUSTONFSEMSTGUIAULTENT;
    vtCUSTONFSEMST                   tpCUSTONFSEMST;
    vtCUSTONFSEMSTGUIAULTENTTAB      tpCUSTONFSEMSTGUIAULTENTTAB;
    vtCUSTONFSEMSTTAB                tpCUSTONFSEMSTTAB;
    vtCUSTOPROXIMACOMPRA             tpCUSTOPROXIMACOMPRA;
    vtCUSTOPROXIMACOMPRASEMST        tpCUSTOPROXIMACOMPRASEMST;
    vtCUSTOREALLIQ                   tpCUSTOREALLIQ;
    vtCUSTOULTENTANT                 tpCUSTOULTENTANT;
    vtCUSTOULTENTCONT                tpCUSTOULTENTCONT;
    vtCUSTOULTENTFIN                 tpCUSTOULTENTFIN;
    vtCUSTOULTENTLIQ                 tpCUSTOULTENTLIQ;
    vtDTULTENT                       tpDTULTENT;
    vtVLCUSTODIAFIN                  tpVLCUSTODIAFIN;
    vtVLCUSTODIAREAL                 tpVLCUSTODIAREAL;
    vtVLCUSTOMESFIN                  tpVLCUSTOMESFIN;
    vtVLCUSTOMESFINANT               tpVLCUSTOMESFINANT;
    vtVLCUSTOMESREAL                 tpVLCUSTOMESREAL;
    vtVLCUSTOMESREALANT              tpVLCUSTOMESREALANT;
    vtVLFRETECONHECULTENT            tpVLFRETECONHECULTENT;
    vtVLFRETECONHECULTENTTAB         tpVLFRETECONHECULTENTTAB;
    vtVLIMPORTACAOFCI                tpVLIMPORTACAOFCI;
    vtVLPARCELAIMPFCI                tpVLPARCELAIMPFCI;
    vtVLSTGUIAULTENT                 tpVLSTGUIAULTENT;
    vtVLSTGUIAULTENTTAB              tpVLSTGUIAULTENTTAB;
    vtVLSTULTENT                     tpVLSTULTENT;
    vtVLSTULTENTTAB                  tpVLSTULTENTTAB;
    vtVLULTENTCONTSEMST              tpVLULTENTCONTSEMST;
    vtVLULTPCOMPRA                   tpVLULTPCOMPRA;
    vtBASEBCR                        tpBASEBCR;
    vtSTBCR                          tpSTBCR;
    vtVLIPIULTENT                    tpVLIPIULTENT;
    vtBASEIPIULTENT                  tpBASEIPIULTENT;
    vtPERCIPIULTENT                  tpPERCIPIULTENT;
    vtQTTRANSITOTV13                 tpQTTRANSITOTV13;
    vtDV                             tpDV;
    vtCODAUXILIAR                    tpCODAUXILIAR;
    vtCODPRODSINTEGRA                tpCODPRODSINTEGRA;
    vtEMBALAGEM                      tpEMBALAGEM;
    vtDTEXCLUSAOPROD                 tpDTEXCLUSAOPROD;
    vtTIPOMERC                       tpTIPOMERC;
    vtTIPOMERCDEPTO                  tpTIPOMERCDEPTO;
    vtCODGENEROFISCAL                tpCODGENEROFISCAL;
    vtPERCST                         tpPERCST;
    vtPISCOFINSRETIDO                tpPISCOFINSRETIDO;
    vtPERPIS                         tpPERPIS;
    vtPERCOFINS                      tpPERCOFINS;
    vtCODINTERNO                     tpCODINTERNO;
    vtALIQICMSVIGENTE                tpALIQICMSVIGENTE;
    vtSITTRIBUT                      tpSITTRIBUT;
    vtCODICM                         tpCODICM;
    vtCODCEST                        tpCODCEST;
    vtQTESTOQUEEMTERCEIRO            tpQTESTOQUEEMTERCEIRO;
    vtQTESTOQUEDETERCEIRO            tpQTESTOQUEDETERCEIRO;
    vtQTTRANSITOTV10                 tpQTTRANSITOTV10;

    V_CONTADOR         NUMBER(10);
    vSQLBLOQUEARPCEST  VARCHAR2(1000);

  BEGIN
    -- Inserindo log
    BEGIN
      GRAVARLOG( NULL
                ,'ARMAZENARSALDOSEST'
                ,'PCHISTEST'
                ,'IP'
                ,'INICIO PROGRAMA DE ARMAZENAGEM DO ESTOQUE '
                ,PDTPROCESSAMENTO);
    EXCEPTION
      WHEN OTHERS THEN
        PVC2MENSSAGEN := 'Mensagem 1: - Erro ao gravar log.';
    END;
    /* Lista de filiais */
    FOR FILIAL IN (SELECT CODIGO
                        ,(SELECT USATRIBUTACAOPORUF FROM PCCONSUM) USATRIBUTACAOPORUF
                         ,NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('GERARPCHISTESTPARA',PCFILIAL.CODIGO),'E') GERARPCHISTESTPARA
                     FROM PCFILIAL
                    WHERE PCFILIAL.GERARPCHISTEST = 'S'
                      AND (DECODE(PCODFILIAL,'99',NULL,PCODFILIAL) IS NULL OR PCFILIAL.CODIGO = PCODFILIAL)
                      AND PCFILIAL.CODIGO <> '99'
                    ORDER BY CODIGO)
    LOOP
      -- Inserindo log
      BEGIN
        GRAVARLOG( FILIAL.CODIGO
                  ,'ARMAZENARSALDOSEST'
                  ,'PCHISTEST'
                  ,'IL'
                  ,'INICIO ARMAZENAR SALDOS ESTOQUE FILIAL: '
                  ,PDTPROCESSAMENTO);
      EXCEPTION
        WHEN OTHERS THEN
          PVC2MENSSAGEN := 'Mensagem 2: - Erro ao gravar log.';
      END;
      /* Bloquear registros */
      vSQLBLOQUEARPCEST := 'SELECT CODFILIAL
                              FROM PCEST
                             WHERE CODFILIAL = '||CHR(39)||FILIAL.CODIGO||CHR(39)||
                              'FOR UPDATE';

      EXECUTE IMMEDIATE vSQLBLOQUEARPCEST;
      /* Certificar que não existem registros antigos */
      DELETE FROM PCHISTESTFILA
       WHERE DATA = PDTPROCESSAMENTO
         AND CODFILIAL = FILIAL.CODIGO;
      /* Abrindo curso para a filial */
      OPEN V_CURSOR_PRODUTOS(FILIAL.CODIGO,
                             PDTPROCESSAMENTO,
                             FILIAL.GERARPCHISTESTPARA,
                             FILIAL.USATRIBUTACAOPORUF);
      LOOP
        /* Buscando as próximas 1000 linhas */
        FETCH V_CURSOR_PRODUTOS BULK COLLECT
          INTO vtCODFILIAL
              ,vtCODPROD
              ,vtNBM
              ,vtDESCRICAO
              ,vtCLASSIFICFISCAL
              ,vtUNIDADE
              ,vtDATA
              ,vtQTEST
              ,vtQTESTGER
              ,vtQTRESERV
              ,vtQTBLOQUEADA
              ,vtQTPENDENTE
              ,vtQTULTENT
              ,vtQTINDENIZ
              ,vtCUSTOCONT
              ,vtCUSTOREAL
              ,vtCUSTOFIN
              ,vtCUSTOREP
              ,vtCUSTOULTENT
              ,vtVALORULTENT
              ,vtCUSTODOLAR
              ,vtCUSTOREALSEMST
              ,vtCUSTOULTENTMED
              ,vtCUSTOULTPEDCOMPRA
              ,vtCUSTOFORNEC
              ,vtVALORULTENTMED
              ,vtDTGERACAO
              ,vtQTTRANSITO
              ,vtQTFRENTELOJA
              ,vtCUSTOFINSEMST
              ,vtCUSTOULTENTFINSEMST
              ,vtCUSTOULTENTSEMST
              ,vtCUSTOFORNECSEMST
              ,vtCUSTONFSEMSTGUIAULTENT
              ,vtCUSTONFSEMST
              ,vtCUSTONFSEMSTGUIAULTENTTAB
              ,vtCUSTONFSEMSTTAB
              ,vtCUSTOPROXIMACOMPRA
              ,vtCUSTOPROXIMACOMPRASEMST
              ,vtCUSTOREALLIQ
              ,vtCUSTOULTENTANT
              ,vtCUSTOULTENTCONT
              ,vtCUSTOULTENTFIN
              ,vtCUSTOULTENTLIQ
              ,vtDTULTENT
              ,vtVLCUSTODIAFIN
              ,vtVLCUSTODIAREAL
              ,vtVLCUSTOMESFIN
              ,vtVLCUSTOMESFINANT
              ,vtVLCUSTOMESREAL
              ,vtVLCUSTOMESREALANT
              ,vtVLFRETECONHECULTENT
              ,vtVLFRETECONHECULTENTTAB
              ,vtVLIMPORTACAOFCI
              ,vtVLPARCELAIMPFCI
              ,vtVLSTGUIAULTENT
              ,vtVLSTGUIAULTENTTAB
              ,vtVLSTULTENT
              ,vtVLSTULTENTTAB
              ,vtVLULTENTCONTSEMST
              ,vtVLULTPCOMPRA
              ,vtBASEBCR
              ,vtSTBCR
              ,vtVLIPIULTENT
              ,vtBASEIPIULTENT
              ,vtPERCIPIULTENT
              ,vtQTTRANSITOTV13
              ,vtDV
              ,vtCODAUXILIAR
              ,vtCODPRODSINTEGRA
              ,vtEMBALAGEM
              ,vtDTEXCLUSAOPROD
              ,vtTIPOMERC
              ,vtTIPOMERCDEPTO
              ,vtCODGENEROFISCAL
              ,vtPERCST
              ,vtPISCOFINSRETIDO
              ,vtPERPIS
              ,vtPERCOFINS
              ,vtCODINTERNO
              ,vtALIQICMSVIGENTE
              ,vtSITTRIBUT
              ,vtCODICM
              ,vtCODCEST
              ,vtQTESTOQUEEMTERCEIRO
              ,vtQTESTOQUEDETERCEIRO
              ,vtQTTRANSITOTV10
         LIMIT 1000;
        /* Vá até o fim do cursor */
        EXIT WHEN vtCODPROD.COUNT = 0;
        /* Insira os dados do cursor na PCHISTEST */
        FORALL NX IN 1 .. vtCODPROD.COUNT
        -- Inserir
          INSERT INTO PCHISTESTFILA
            (CODFILIAL,
             CODPROD,
             NBM,
             DESCRICAO,
             CLASSIFICFISCAL,
             UNIDADE,
             DATA,
             QTEST,
             QTESTGER,
             QTRESERV,
             QTBLOQUEADA,
             QTPENDENTE,
             QTULTENT,
             QTINDENIZ,
             CUSTOCONT,
             CUSTOREAL,
             CUSTOFIN,
             CUSTOREP,
             CUSTOULTENT,
             VALORULTENT,
             CUSTODOLAR,
             CUSTOREALSEMST,
             CUSTOULTENTMED,
             CUSTOULTPEDCOMPRA,
             CUSTOFORNEC,
             VALORULTENTMED,
             DTGERACAO,
             QTTRANSITO,
             QTFRENTELOJA,
             CUSTOFINSEMST,
             CUSTOULTENTFINSEMST,
             CUSTOULTENTSEMST,
             CUSTOFORNECSEMST,
             CUSTONFSEMSTGUIAULTENT,
             CUSTONFSEMST,
             CUSTONFSEMSTGUIAULTENTTAB,
             CUSTONFSEMSTTAB,
             CUSTOPROXIMACOMPRA,
             CUSTOPROXIMACOMPRASEMST,
             CUSTOREALLIQ,
             CUSTOULTENTANT,
             CUSTOULTENTCONT,
             CUSTOULTENTFIN,
             CUSTOULTENTLIQ,
             DTULTENT,
             VLCUSTODIAFIN,
             VLCUSTODIAREAL,
             VLCUSTOMESFIN,
             VLCUSTOMESFINANT,
             VLCUSTOMESREAL,
             VLCUSTOMESREALANT,
             VLFRETECONHECULTENT,
             VLFRETECONHECULTENTTAB,
             VLIMPORTACAOFCI,
             VLPARCELAIMPFCI,
             VLSTGUIAULTENT,
             VLSTGUIAULTENTTAB,
             VLSTULTENT,
             VLSTULTENTTAB,
             VLULTENTCONTSEMST,
             VLULTPCOMPRA,
             BASEBCR,
             STBCR,
             VLIPIULTENT,
             BASEIPIULTENT,
             PERCIPIULTENT,
             QTTRANSITOTV13,
             DV,
             CODAUXILIAR,
             CODPRODSINTEGRA,
             EMBALAGEM,
             DTEXCLUSAOPROD,
             TIPOMERC,
             TIPOMERCDEPTO,
             CODGENEROFISCAL,
             PERCST,
             PISCOFINSRETIDO,
             PERPIS,
             PERCOFINS,
             CODINTERNO,
             ALIQICMSVIGENTE,
             SITTRIBUT,
             CODICM,
             CODCEST,
             QTESTOQUEEMTERCEIRO,
             QTESTOQUEDETERCEIRO,
             QTTRANSITOTV10)
          VALUES
            (vtCODFILIAL(NX)
            ,vtCODPROD(NX)
            ,vtNBM(NX)
            ,vtDESCRICAO(NX)
            ,vtCLASSIFICFISCAL(NX)
            ,vtUNIDADE(NX)
            ,vtDATA(NX)
            ,vtQTEST(NX)
            ,vtQTESTGER(NX)
            ,vtQTRESERV(NX)
            ,vtQTBLOQUEADA(NX)
            ,vtQTPENDENTE(NX)
            ,vtQTULTENT(NX)
            ,vtQTINDENIZ(NX)
            ,vtCUSTOCONT(NX)
            ,vtCUSTOREAL(NX)
            ,vtCUSTOFIN(NX)
            ,vtCUSTOREP(NX)
            ,vtCUSTOULTENT(NX)
            ,vtVALORULTENT(NX)
            ,vtCUSTODOLAR(NX)
            ,vtCUSTOREALSEMST(NX)
            ,vtCUSTOULTENTMED(NX)
            ,vtCUSTOULTPEDCOMPRA(NX)
            ,vtCUSTOFORNEC(NX)
            ,vtVALORULTENTMED(NX)
            ,vtDTGERACAO(NX)
            ,vtQTTRANSITO(NX)
            ,vtQTFRENTELOJA(NX)
            ,vtCUSTOFINSEMST(NX)
            ,vtCUSTOULTENTFINSEMST(NX)
            ,vtCUSTOULTENTSEMST(NX)
            ,vtCUSTOFORNECSEMST(NX)
            ,vtCUSTONFSEMSTGUIAULTENT(NX)
            ,vtCUSTONFSEMST(NX)
            ,vtCUSTONFSEMSTGUIAULTENTTAB(NX)
            ,vtCUSTONFSEMSTTAB(NX)
            ,vtCUSTOPROXIMACOMPRA(NX)
            ,vtCUSTOPROXIMACOMPRASEMST(NX)
            ,vtCUSTOREALLIQ(NX)
            ,vtCUSTOULTENTANT(NX)
            ,vtCUSTOULTENTCONT(NX)
            ,vtCUSTOULTENTFIN(NX)
            ,vtCUSTOULTENTLIQ(NX)
            ,vtDTULTENT(NX)
            ,vtVLCUSTODIAFIN(NX)
            ,vtVLCUSTODIAREAL(NX)
            ,vtVLCUSTOMESFIN(NX)
            ,vtVLCUSTOMESFINANT(NX)
            ,vtVLCUSTOMESREAL(NX)
            ,vtVLCUSTOMESREALANT(NX)
            ,vtVLFRETECONHECULTENT(NX)
            ,vtVLFRETECONHECULTENTTAB(NX)
            ,vtVLIMPORTACAOFCI(NX)
            ,vtVLPARCELAIMPFCI(NX)
            ,vtVLSTGUIAULTENT(NX)
            ,vtVLSTGUIAULTENTTAB(NX)
            ,vtVLSTULTENT(NX)
            ,vtVLSTULTENTTAB(NX)
            ,vtVLULTENTCONTSEMST(NX)
            ,vtVLULTPCOMPRA(NX)
            ,vtBASEBCR(NX)
            ,vtSTBCR(NX)
            ,vtVLIPIULTENT(NX)
            ,vtBASEIPIULTENT(NX)
            ,vtPERCIPIULTENT(NX)
            ,vtQTTRANSITOTV13(NX)
            ,vtDV(NX)
            ,vtCODAUXILIAR(NX)
            ,vtCODPRODSINTEGRA(NX)
            ,vtEMBALAGEM(NX)
            ,vtDTEXCLUSAOPROD(NX)
            ,vtTIPOMERC(NX)
            ,vtTIPOMERCDEPTO(NX)
            ,vtCODGENEROFISCAL(NX)
            ,vtPERCST(NX)
            ,vtPISCOFINSRETIDO(NX)
            ,vtPERPIS(NX)
            ,vtPERCOFINS(NX)
            ,vtCODINTERNO(NX)
            ,vtALIQICMSVIGENTE(NX)
            ,vtSITTRIBUT(NX)
            ,vtCODICM(NX)
            ,vtCODCEST(NX)
            ,vtQTESTOQUEEMTERCEIRO(NX)
            ,vtQTESTOQUEDETERCEIRO(NX)
            ,vtQTTRANSITOTV10(NX)
);
          -- Confirmando os registros
          COMMIT WORK;
      /* Fim do cursor */
      END LOOP;

      CLOSE V_CURSOR_PRODUTOS;

      -- Inserindo log
      BEGIN
        GRAVARLOG(FILIAL.CODIGO
                 ,'ARMAZENARSALDOSEST'
                 ,'PCHISTEST'
                 ,'FL'
                 ,'FINAL ARMAZENAR SALDOS ESTOQUE FILIAL: '
                 ,PDTPROCESSAMENTO);
      EXCEPTION
        WHEN OTHERS THEN
          PVC2MENSSAGEN := 'Mensagem 4: - Erro ao gravar log.';
      END;

      COMMIT;
    /* Fim da lista de filiais */
    END LOOP;
    -- Inserindo log
    BEGIN
      GRAVARLOG(NULL
               ,'ARMAZENARSALDOSEST'
               ,'PCHISTEST'
               ,'IL'
               ,'INICIO ARMAZENAR SALDOS ESTOQUE EM TRANSITO'
               ,PDTPROCESSAMENTO);
    EXCEPTION
      WHEN OTHERS THEN
        PVC2MENSSAGEN := 'Mensagem 5: - Erro ao gravar log.';
    END;
    /* Lista de produtos em transito */
    FOR REGISTRO IN (SELECT T.CODFILIAL,
                            T.CODPROD,
                            T.POSSECODFORNEC,
                            T.QTTRANSITO
                       FROM PCESTTRANSITO T
                           ,PCFILIAL
                      WHERE T.CODFILIAL = PCFILIAL.CODIGO
                        AND PCFILIAL.GERARPCHISTEST = 'S'
                        AND (DECODE(PCODFILIAL,'99',NULL,PCODFILIAL) IS NULL OR PCFILIAL.CODIGO = PCODFILIAL)
                        AND PCFILIAL.CODIGO <> '99')
    LOOP
      /* Zerando variavel */
      V_CONTADOR := 0;
      /* Verificando se já existe o registro */
      SELECT COUNT(1)
        INTO V_CONTADOR
        FROM PCHISTESTTRANSITO
       WHERE CODFILIAL = REGISTRO.CODFILIAL
         AND CODPROD = REGISTRO.CODPROD
         AND POSSECODFORNEC = REGISTRO.POSSECODFORNEC
         AND DATA = PDTPROCESSAMENTO;
      /* Caso não exista o registro */
      IF V_CONTADOR = 0 THEN
        /* Inserindo os registros na PCHISTESTTRANSITO */
        INSERT INTO PCHISTESTTRANSITO
          (CODFILIAL, CODPROD, POSSECODFORNEC, QTTRANSITO, DATA)
        VALUES
          (REGISTRO.CODFILIAL,
           REGISTRO.CODPROD,
           REGISTRO.POSSECODFORNEC,
           REGISTRO.QTTRANSITO,
           PDTPROCESSAMENTO);
        /* Confirmando registros */
        COMMIT WORK;
      /* Fim da inserção do registro */
      END IF;
    /* Fim da lista de produtos em transito */
    END LOOP;
    -- Inserindo log
    BEGIN
      GRAVARLOG(NULL
               ,'ARMAZENARSALDOSEST'
               ,'PCHISTEST'
               ,'FP'
               ,'FINALIZOU A PROCEDURE DE ARMAZENAR SALDOS ESTOQUE'
               ,PDTPROCESSAMENTO);
    EXCEPTION
      WHEN OTHERS THEN
        PVC2MENSSAGEN := 'Mensagem 5: - Erro ao gravar log.';
    END;
    /* Confirmando registros */
    COMMIT;
  /* Fim da procedure */
  END P_PC_ARMAZENARSALDOSESTOQUE;

  procedure P_PC_ARMAZENASALDOCAIXABANCO(
                                         -- Parametros de entrada
                                         PDTPROCESSAMENTO in date,
                                         -- Parametro de saida
                                         PVC2MENSSAGEN out varchar2) is
    /*********************************************************************************
    Opção 3 - Armazenar Saldos Caixa Banco
    ---------------------------------- Historico -------------------------------------
        Data        Responsavel    Comentarios
    ------------  ---------------  ---------------------------------------------------
     22/07/2008    Max Faria        Transcrição para PLSQL da opção 3 da rotina 504
    *********************************************************************************/
    VCONTADOR number := 0;
  begin
    insert into PCLOGJOB
      (MODULO,
       FUNCAO,
       TIPO_LOG,
       DATA_LOG,
       DS_JOB)
    values
      ('armazenasldcaixabco',
       'pcsaldocr',
       'IN',
       sysdate,
       'Inicio Armazenar Saldos Caixa Banco');
    commit;
    for REGISTRO in (select CODBANCO,
                            CODCOB,
                            NVL(VALOR, 0) VALOR,
                            NVL(VALORSALDOTOTALCONCIL, 0) VALORSALDOTOTALCONCIL,
                            NVL(VALORSALDOTOTALCOMP, 0) VALORSALDOTOTALCOMP,
                            NVL(VALORCONCILIADO, 0) VALORCONCILIADO,
                            NVL(VALORCOMPENSADO, 0) VALORCOMPENSADO,
                            TRUNC(DTULTCONCILIA) DTULTCONCILIA,
                            TRUNC(DTULTCOMPENSACAO) DTULTCOMPENSACAO
                       from PCESTCR)
    loop
      VCONTADOR := 0;
      select count(1)
      into   VCONTADOR
      from   PCSALDOCR
      where  CODBANCO = REGISTRO.CODBANCO
      and    CODCOB = REGISTRO.CODCOB
      and    DATA = PDTPROCESSAMENTO
      and    ROWNUM = 1;
      if VCONTADOR = 0 then
        INSERT INTO PCSALDOCR
          (CODBANCO,
           CODCOB,
           DATA,
           VLSALDOINICIAL,
           VLSALDOINICIALCONCIL,
           VLSALDOINICIALCOMP,
           VLSALDOCONCILID,
           VLSALDOCOMPENSADO,
           DTULTCONCILIA,
           DTULTCOMPENSACAO,
           DTREFERENCIA,
           DTGERACAO)
        VALUES
          (REGISTRO.CODBANCO,
           REGISTRO.CODCOB,
           PDTPROCESSAMENTO,
           NVL(REGISTRO.VALOR, 0),
           NVL(REGISTRO.VALORSALDOTOTALCONCIL, 0),
           NVL(REGISTRO.VALORSALDOTOTALCOMP, 0),
           NVL(REGISTRO.VALORCONCILIADO, 0),
           NVL(REGISTRO.VALORCOMPENSADO, 0),
           REGISTRO.DTULTCONCILIA,
           REGISTRO.DTULTCOMPENSACAO,
           PDTPROCESSAMENTO,
           SYSDATE);
      end if;
    end loop;
    commit;
    insert into PCLOGJOB
      (MODULO,
       FUNCAO,
       TIPO_LOG,
       DATA_LOG,
       DS_JOB)
    values
      ('armazenasldcaixabco',
       'pcsaldocr',
       'FI',
       sysdate,
       'Final Armazenar Saldos Caixa Banco');
    commit;
  end;

  procedure P_PC_ZERARACUMVENDADIA(PCODFILIAL IN  VARCHAR2,
                                   -- Parametro de saida
                                   PVC2MENSSAGEN out varchar2) is
    /*********************************************************************************
    Opção 2 - Zerar Acumuladores Venda do Dia
    ---------------------------------- Historico -------------------------------------
        Data        Responsavel    Comentarios
    ------------  ---------------  ---------------------------------------------------
     22/07/2008    Max Faria        Transcrição para PLSQL da opção 2 da rotina 504
     16/04/2014    Deyvid Costa     Retirado a cláusula NOT da consulta que retorna as filiais não excluídas
    *********************************************************************************/
  vnQtPedSemCabecalho number;
  V_RID               VARCHAR2(1000);
  V_COUNT             INTEGER;
  vbLocked            BOOLEAN := FALSE;
  begin
    insert into PCLOGJOB
      (MODULO,
       FUNCAO,
       TIPO_LOG,
       DATA_LOG,
       DS_JOB)
    values
      ('zeraracumvendadia',
       'pcest',
       'IN',
       sysdate,
       'Inicio Zerar Acumuladores Venda do Dia');
    commit;
    FOR FILIAIS in (SELECT CODIGO FROM PCFILIAL WHERE CODIGO <> '99' AND DTEXCLUSAO IS NULL AND (DECODE(PCODFILIAL,'99',NULL,PCODFILIAL) IS NULL OR PCFILIAL.CODIGO = PCODFILIAL))
    LOOP
        FOR DADOS_ACUMULADORES IN (SELECT CODPROD
                                     FROM PCEST
                                     WHERE CODFILIAL = FILIAIS.CODIGO
                                       AND (NVL(QTPERDADIA, 0) +
                                           NVL(QTVENDDIA, 0) +
                                           NVL(VLVENDDIA, 0) +
                                           NVL(VLCUSTODIAREAL, 0) +
                                           NVL(VLCUSTODIAFIN, 0) +
                                           NVL(QTENTDIA, 0) +
                                           NVL(VLVENDDIAREAL, 0)) <> 0)
    
       LOOP
      
        V_COUNT := 0;
      
        WHILE V_COUNT >= 0 AND V_COUNT < 100 LOOP
          
          vbLocked := TRUE;
          
          BEGIN
            SELECT ROWID
              INTO V_RID
              FROM PCEST
             WHERE CODPROD = DADOS_ACUMULADORES.CODPROD
               AND CODFILIAL = FILIAIS.CODIGO
               FOR UPDATE NOWAIT;
          EXCEPTION
            WHEN OTHERS THEN
              V_COUNT := V_COUNT + 1;
              vbLocked := FALSE;
        
              IF V_COUNT = 99 THEN
                PVC2MENSSAGEN := 'Erro em LOCK da tabela PCEST para os acumuladores de venda: ' ||
                                 SQLERRM;
                RAISE;
              END IF;
          END;
        
          IF (vbLocked) THEN
            EXIT;
          END IF;
        
        END LOOP;
      
        UPDATE PCEST
           SET QTPERDADIA     = 0,
               QTVENDDIA      = 0,
               VLVENDDIA      = 0,
               VLCUSTODIAREAL = 0,
               VLCUSTODIAFIN  = 0,
               QTENTDIA       = 0,
               VLVENDDIAREAL  = 0
         WHERE CODPROD = DADOS_ACUMULADORES.CODPROD
           AND CODFILIAL = FILIAIS.CODIGO
           AND ROWID = V_RID;
      
        commit;      
      END LOOP;
    END LOOP;

    insert into PCLOGJOB
      (MODULO,
       FUNCAO,
       TIPO_LOG,
       DATA_LOG,
       DS_JOB)
    values
      ('zeraracumvendadia',
       'pcest',
       'FI',
       sysdate,
       'Final Zerar Acumuladores Venda do Dia');
    commit;

    begin
      select count(1)
        into vnQtPedSemCabecalho
        from pcpedi
       where numped not in
             (select numped from pcpedc where pcpedc.numped = pcpedi.numped and pcpedc.data between trunc(sysdate) - 1 and trunc(sysdate))
         and pcpedi.data between trunc(sysdate) - 1 and trunc(sysdate);
    exception
      when others then
        vnQtPedSemCabecalho := 0;
    end;

    if vnQtPedSemCabecalho > 0 then
      insert into PCLOGJOB
        (MODULO, FUNCAO, TIPO_LOG, DATA_LOG, DS_JOB)
      values
        ('zeraracumvendadia',
         'pcpedi',
         'IN',
         sysdate,
         'Removendo ' || vnQtPedSemCabecalho || ' pedidos sem cabeçalho');
      commit;

      delete from pcpedi
       where numped not in
             (select numped from pcpedc where pcpedc.numped = pcpedi.numped)
         and pcpedi.data between trunc(sysdate) - 1 and trunc(sysdate);
      commit;

      insert into PCLOGJOB
        (MODULO, FUNCAO, TIPO_LOG, DATA_LOG, DS_JOB)
      values
        ('zeraracumvendadia',
         'pcpedi',
         'FI',
         sysdate,
         vnQtPedSemCabecalho || ' removidos com sucesso.');

      commit;

    end if;
  end;

  --Bloquear Produto FL sem Estoque  (P_PC_BLOQPRODFLSEMESTOQUE)
  procedure P_PC_BLOQPRODFLSEMESTOQUE(
                                      -- Parametros de entrada
                                      PDTPROCESSAMENTO in date,
                                      -- Parametro de saida
                                      PVC2MENSSAGEN out varchar2) is
    /*********************************************************************************
    Opção 1 - Bloquear Produto FL sem Estoque
    ---------------------------------- Historico -------------------------------------
        Data        Responsavel    Comentarios
    ------------  ---------------  ---------------------------------------------------
     22/07/2008    Max Faria        Transcrição para PLSQL da opção 1 da rotina 504
    *********************************************************************************/
  begin
    insert into PCLOGJOB
      (MODULO,
       FUNCAO,
       TIPO_LOG,
       DATA_LOG,
       DS_JOB)
    values
      ('BLOQPRODFLSEMEST',
       'pcprodut',
       'IN',
       sysdate,
       'Inicio Bloquear Produto FL sem Estoque');
    commit;
    for REGISTRO in (SELECT PCEST.CODPROD
                       FROM PCEST
                   GROUP BY PCEST.CODPROD
                     HAVING SUM(GREATEST(NVL(PCEST.QTEST, 0), 0) 
                              + GREATEST(NVL(PCEST.QTESTGER, 0), 0)) = 0)
    loop
      update PCPRODUT
      set    DTEXCLUSAO = PDTPROCESSAMENTO
      where  CODPROD = REGISTRO.CODPROD
      and    OBS2 = 'FL'
      and    DTEXCLUSAO is null;
    end loop;
    commit;
    insert into PCLOGJOB
      (MODULO,
       FUNCAO,
       TIPO_LOG,
       DATA_LOG,
       DS_JOB)
    values
      ('BLOQPRODFLSEMEST',
       'pcprodut',
       'FI',
       sysdate,
       'Final Bloquear Produto FL sem Estoque');
    commit;
  end;

  PROCEDURE P_PC_ORDENAR_SEQUENCIA_ROTACLI( P_DTPROXVISITA IN PCROTACLI.DTPROXVISITA%TYPE
                                          , P_CODUSUR IN PCROTACLI.CODUSUR%TYPE DEFAULT 0
                                          , P_ROWID IN VARCHAR2 DEFAULT ''
                                          )
  IS
    V_MENOR_SEQUENCIA NUMBER;
    V_MAIOR_SEQUENCIA NUMBER;
    V_QTD_REGISTRO_MESMO_SEQ NUMBER;
    V_SEQUENCIA NUMBER; 
    V_REGISTROS_MESMA_SEQ NUMBER;
    /***************************************************************************************
    Propósito: Atualização da sequencia das rotas da próxima visita do RCA.
    Rotina: Pacote
    Utilizada por: PCSIS328, PCSIS354 e PCSIS504
    ----------------------------------------------------------------------------------------
    Data        Responsável            Descrição
    ----------  ---------------------  -----------------------------------------------------
    10/06/2021  Marcelo Hakenhoar      DDLEGFIN-1709: Fazer a atualização do campo SEQUENCIA
                                       da tabela PCROTACLI, ao atualizar a data da próxima
                                       visita da roterização do RCA, ordenando os registros.
    01/09/2022
    ***************************************************************************************/
  BEGIN
    BEGIN
      INSERT INTO PCLOGJOB ( MODULO
                           , FUNCAO
                           , TIPO_LOG
                           , DATA_LOG
                           , DS_JOB
                           )
      VALUES ( 'ORDERNARSEQROTACLI'
             , 'PCROTACLI'
             , 'FI'
             , SYSDATE
             , 'INÍCIO ATUALIZAÇÃO DO NOVO SEQUENCIA DA PRÓX. DT. VISITA'
             );

      COMMIT;

      FOR REG_USUR IN ( SELECT CODUSUR
                          FROM PCROTACLI RC
                         WHERE DTPROXVISITA = P_DTPROXVISITA
                           AND (RC.CODUSUR = P_CODUSUR OR P_CODUSUR = 0)
                         GROUP BY CODUSUR
                         ORDER BY CODUSUR
                      )
      LOOP
         UPDATE PCROTACLI
          SET    SEQUENCIA = 1
          WHERE  CODUSUR = REG_USUR.CODUSUR
          AND    DTPROXVISITA = P_DTPROXVISITA
          AND    nvl(SEQUENCIA,0) = 0 ;

        SELECT MIN(NVL(SEQUENCIA,1)) AS MENOR_SEQUENCIA
             , MAX(NVL(SEQUENCIA,1)) AS MAIOR_SEQUENCIA
          INTO V_MENOR_SEQUENCIA
             , V_MAIOR_SEQUENCIA
          FROM PCROTACLI
         WHERE CODUSUR = REG_USUR.CODUSUR
           AND DTPROXVISITA = P_DTPROXVISITA;

          IF V_MENOR_SEQUENCIA > 1 THEN
            V_SEQUENCIA := 1;
          ELSE
            V_SEQUENCIA := V_MENOR_SEQUENCIA;
          END IF;

          WHILE V_SEQUENCIA < (V_MAIOR_SEQUENCIA + 1)
          LOOP
            SELECT COUNT(*)
            INTO   V_QTD_REGISTRO_MESMO_SEQ
            FROM   PCROTACLI
            WHERE  CODUSUR = REG_USUR.CODUSUR
            AND    DTPROXVISITA = P_DTPROXVISITA
            AND    SEQUENCIA = V_SEQUENCIA;

            IF V_QTD_REGISTRO_MESMO_SEQ > 1 THEN
              BEGIN
                UPDATE PCROTACLI
                SET    SEQUENCIA = SEQUENCIA + (V_QTD_REGISTRO_MESMO_SEQ - 1)
                WHERE  CODUSUR = REG_USUR.CODUSUR
                AND    DTPROXVISITA = P_DTPROXVISITA
                AND    SEQUENCIA > V_SEQUENCIA;

                V_MAIOR_SEQUENCIA := V_MAIOR_SEQUENCIA + (V_QTD_REGISTRO_MESMO_SEQ - 1);
              EXCEPTION
                WHEN OTHERS THEN
                  RAISE_APPLICATION_ERROR(SQLCODE, 'ERRO AO ORDERNAR A SEQUENCIA DA ROTA: ' || SQLERRM);
              END;

              FOR REG_DADOS IN ( SELECT RC.ROWID,RC.SEQUENCIA
                                 FROM   PCROTACLI RC
                                      , PCROTACLIPARAM P
                                      , PCCLIENT C
                                 WHERE  RC.PERIODICIDADE = P.PERIODICIDADE(+)
                                 AND    RC.CODCLI = C.CODCLI
                                 AND    RC.DTPROXVISITA = P_DTPROXVISITA
                                 AND    RC.CODUSUR = REG_USUR.CODUSUR
                                 AND    RC.SEQUENCIA = V_SEQUENCIA
                                
                                 ORDER
                                 BY     RC.SEQUENCIA
                                      , P.PRIORIDADE
                                      , C.DTCADASTRO
                                      , RC.CODCLI DESC )
              LOOP
                BEGIN
                  
                  IF (NVL(P_ROWID,'0') = '0' )THEN
                    UPDATE PCROTACLI
                    SET    SEQUENCIA = V_SEQUENCIA
                    WHERE  ROWID = REG_DADOS.ROWID;
                   V_SEQUENCIA := V_SEQUENCIA + 1; 
                  ELSIF (NVL(P_ROWID,'0') <> REG_DADOS.ROWID) THEN   
                    BEGIN 
                        SELECT COUNT(*) INTO V_REGISTROS_MESMA_SEQ  
                        FROM PCROTACLI RC
                        WHERE RC.DTPROXVISITA = P_DTPROXVISITA
                        AND    RC.CODUSUR = REG_USUR.CODUSUR
                        AND    RC.SEQUENCIA = REG_DADOS.SEQUENCIA;
                      EXCEPTION
                        WHEN OTHERS THEN
                          V_REGISTROS_MESMA_SEQ := 1;
                      END;
                      
                      IF (V_REGISTROS_MESMA_SEQ > 1) THEN
                       V_SEQUENCIA := V_SEQUENCIA + 1;                     
                       
                        UPDATE PCROTACLI
                        SET    SEQUENCIA = V_SEQUENCIA
                        WHERE  ROWID = REG_DADOS.ROWID;   
                      END IF; 
                                        
                  END IF;
                EXCEPTION
                  WHEN OTHERS THEN
                    RAISE_APPLICATION_ERROR(SQLCODE, 'ERRO AO ORDERNAR A SEQUENCIA DA ROTA: ' || SQLERRM);
                END;
               
              END LOOP;
            ELSE
              IF V_QTD_REGISTRO_MESMO_SEQ = 0 THEN
                BEGIN
                IF (NVL(P_ROWID,'0') = '0') THEN
                  UPDATE PCROTACLI
                  SET    SEQUENCIA = SEQUENCIA - 1
                  WHERE  CODUSUR = REG_USUR.CODUSUR
                  AND    DTPROXVISITA = P_DTPROXVISITA
                  AND    SEQUENCIA > V_SEQUENCIA;
                 ELSE
                  UPDATE PCROTACLI
                  SET    SEQUENCIA = SEQUENCIA - 1
                  WHERE  CODUSUR = REG_USUR.CODUSUR
                  AND    DTPROXVISITA = P_DTPROXVISITA
                  AND    ROWID <> P_ROWID
                  AND    SEQUENCIA > V_SEQUENCIA;
                 END IF;

                  V_MAIOR_SEQUENCIA := V_MAIOR_SEQUENCIA - 1;
                EXCEPTION
                  WHEN OTHERS THEN
                    RAISE_APPLICATION_ERROR(SQLCODE, 'ERRO AO ORDERNAR A SEQUENCIA DA ROTA: ' || SQLERRM);
                END;
              ELSE
                V_SEQUENCIA := V_SEQUENCIA + 1;
              END IF;
            END IF;
        END LOOP;
      END LOOP;

      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(sqlcode, 'ERRO: ' || SQLERRM);
    END;

    INSERT INTO PCLOGJOB ( MODULO
                         , FUNCAO
                         , TIPO_LOG
                         , DATA_LOG
                         , DS_JOB
                         )
    VALUES ( 'ORDERNARSEQROTACLI'
           , 'PCROTACLI'
           , 'FI'
           , SYSDATE
           , 'FINAL ATUALIZAÇÃO DO NOVO SEQUENCIA DA PRÓX. DT. VISITA'
           );

    COMMIT;
  END P_PC_ORDENAR_SEQUENCIA_ROTACLI;

  procedure P_PC_GERAROTACLI(PI_DTPROCESSAMENTO in date) is
    V_CONTADOR number := 0;
    V_PARAM_PRIORIDADEVISITARCA VARCHAR(1);
    /*******************************************************************************
     Proposito: Atualização de Dt. Próx. Visita (Roteirização de Clientes), através da atualização do PCROTACLI
     Rotina: Pacote
     Utilizada por: PCSIS504
     -------------------------------------------------------------------------------
     Data        Responsavel     Descricao
     ----------   --------------  ---------------------------------------------------
     25/04/07  Hoê               Tarefa 44.279: Fazer roteirização através de procedure no banco, para melhorar a performance.
    *******************************************************************************/
  begin
    begin
      insert into PCLOGJOB
        (MODULO,
         FUNCAO,
         TIPO_LOG,
         DATA_LOG,
         DS_JOB)
      values
        ('gerarotacli',
         'pcrotacli',
         'IN',
         sysdate,
         'Inicio Atualização de Dt. Próx. Visita');
      commit;
      <<INICIO>> -- LABEL PARA UTILIZAR COM GOTO
      select count(1) CONTADOR
      into   V_CONTADOR
      from   PCROTACLI R
      where  R.CODUSUR > 0
      and    R.DTPROXVISITA <= PI_DTPROCESSAMENTO
      and    R.PERIODICIDADE in ('1', '7', '14', '15', '21', '30', '45')
      and    ROWNUM = 1;
      if V_CONTADOR > 0
      then
        begin
          update PCROTACLI
          set    PCROTACLI.DTPROXVISITA = DECODE(TO_CHAR(PCROTACLI.DTPROXVISITA +
                                                         TO_NUMBER(PCROTACLI.PERIODICIDADE),
                                                         'D'),
                                                 '1',
                                                 DECODE(PCROTACLI.DIASEMANA,
                                                        'SEGUNDA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 1,
                                                        'TERCA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 2,
                                                        'QUARTA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 3,
                                                        'QUINTA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 4,
                                                        'SEXTA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 5,
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 1),
                                                 '2',
                                                 DECODE(PCROTACLI.DIASEMANA,
                                                        'SEGUNDA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE),
                                                        'TERCA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 1,
                                                        'QUARTA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 2,
                                                        'QUINTA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 3,
                                                        'SEXTA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 4,
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE)),
                                                 '3',
                                                 DECODE(PCROTACLI.DIASEMANA,
                                                        'SEGUNDA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 6,
                                                        'TERCA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE),
                                                        'QUARTA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 1,
                                                        'QUINTA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 2,
                                                        'SEXTA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 3,
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE)),
                                                 '4',
                                                 DECODE(PCROTACLI.DIASEMANA,
                                                        'SEGUNDA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 5,
                                                        'TERCA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 6,
                                                        'QUARTA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE),
                                                        'QUINTA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 1,
                                                        'SEXTA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 2,
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE)),
                                                 '5',
                                                 DECODE(PCROTACLI.DIASEMANA,
                                                        'SEGUNDA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 4,
                                                        'TERCA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 5,
                                                        'QUARTA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 6,
                                                        'QUINTA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE),
                                                        'SEXTA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 1,
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE)),
                                                 '6',
                                                 DECODE(PCROTACLI.DIASEMANA,
                                                        'SEGUNDA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 3,
                                                        'TERCA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 4,
                                                        'QUARTA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 5,
                                                        'QUINTA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 6,
                                                        'SEXTA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE),
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE)),
                                                 '7',
                                                 DECODE(PCROTACLI.DIASEMANA,
                                                        'SEGUNDA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 2,
                                                        'TERCA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 3,
                                                        'QUARTA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 4,
                                                        'QUINTA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 5,
                                                        'SEXTA',
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE) + 6,
                                                        PCROTACLI.DTPROXVISITA +
                                                        TO_NUMBER(PCROTACLI.PERIODICIDADE)),
                                                 PCROTACLI.DTPROXVISITA +
                                                 TO_NUMBER(PCROTACLI.PERIODICIDADE))
          where  PCROTACLI.CODUSUR > 0
          and    PCROTACLI.DTPROXVISITA <= PI_DTPROCESSAMENTO
          and    PCROTACLI.DTPROXVISITA is not null
          and    PCROTACLI.PERIODICIDADE in ('1', '7', '14', '15', '21', '30', '45');
        exception
          when others then
            RAISE_APPLICATION_ERROR(sqlcode, 'ERRO AO GERAR ROTA: ' || sqlerrm);
        end;
        goto INICIO;
        -- VOLTA AO INICIO PARA VERIFICAR SE AINDA TEM ALGUMA ROTA SEM AGENDAMENTO
      end if;
      commit;
    exception
      when others then
        RAISE_APPLICATION_ERROR(sqlcode, 'ERRO: ' || sqlerrm);
    end;
    insert into PCLOGJOB
      (MODULO,
       FUNCAO,
       TIPO_LOG,
       DATA_LOG,
       DS_JOB)
    values
      ('gerarotacli',
       'pcrotacli',
       'FI',
       sysdate,
       'Final Atualização de Dt. Próx. Visita');
    commit;

    BEGIN
      SELECT VALOR
        INTO V_PARAM_PRIORIDADEVISITARCA
        FROM PCPARAMFILIAL
       WHERE NOME = 'PRIORIDADEVISITARCA';
    EXCEPTION
      WHEN OTHERS THEN
        V_PARAM_PRIORIDADEVISITARCA := 'N';
    END;

    IF V_PARAM_PRIORIDADEVISITARCA = 'S' THEN
      P_PC_ORDENAR_SEQUENCIA_ROTACLI(TRUNC(SYSDATE));
    END IF;
  end P_PC_GERAROTACLI;

PROCEDURE PC_CONSOLIDA_PLANOVOO(PDTINICIO    IN DATE,
                                PDTTERMINO   IN DATE,
                                POPCAO       IN VARCHAR2,
                                PMENSAGEM    OUT VARCHAR2,
                                PLISTACODIGO IN VARCHAR2 DEFAULT NULL,
                                PCODFILIAL   IN VARCHAR2 DEFAULT NULL)
  /*-- OBJETIVOS : Consolidacao de dados para o PLANO DE VOO
     Autor     : FABIO AFONSO DE OLIVEIRA - 02/2001
     ALTERACOES:
     ATUALIZACAO : 23/03/2001
         Data  :  08/03/2001               Autor: FABIO
         Resumo:  A CHAMADA DE APLICATIVO DELPHI ESTAVA SENDO FEITA COM ALGUMA TRANSACAO ABERTA, O QUE
                  GERAVA UM ERRO ORACLE. COLOCADO ROLLBACK NO INICIO DA PROCEDURE
     PARAMETROS:
     pDtInicio  => DATA DE INICIO DO PERIODO A SER RECUPERADO NO PCMOV
     pDtTermino => DATA DE TERMINO DO PERIODO A SER RECUPERADO NO PCMOV
     pOpcao     => Quais dados serao consolidados ( P=Produto,T=Cli/Rca )
     pMensagem  => Variavel de retorno de mensagem interna da procedure
    *******************************HISTORICO DE ALTERACOES*********************************
       Data       Responsável         Descrição
    ----------  -------------------  ------------------------------------------------------
    23/05/2003    Sabrina             Incluídos Custo Rep. e Vl. Custo Rep.
    04/07/2003    Jozeni              Passar do PCEST para o PCHISTEST os dados referente a
                                      Qtde e Custo.
    05/08/2003    Sabrina             Gravar Qt. Devol. Cliente, Vl. Devol. Cliente
    04/11/2003    Juliana             Acrescentado tabela PCNFSAID no sql do PCDTPROD para
                                      evitar divergencia nos relatórios PCINF111 e PCINF124
                                      - Tarefa Nº4417;
    12/03/2004    Juliana             Alterada o sql do pcmov para considerar em caso de ven-
                                      das bonificadas a quantidade para calculo dos custos,
                                      retirado o trunc destes campos;
    19/08/2004    L.Eduardo Estevao   Atualizacao da Quantidade de Perda e acrescentar no
                                      CMV do produto (PCDTPROD.VLCUSTOFIN, PCDTPROD.VLCUSTOREAL,
                                                      PCDTPROD.VLCUSTOREP)
    11/09/2004    L.Eduardo Estevao   Na atualizacao da perda do produto quando nao houver registro
                                      no PCDTPROD sera inserido um novo registro
    29/10/2004    Juliana             Considerando punitcont e qtcont para as vendas tipo 7 onde
                                      qt e punit não são gravados;
    24/01/2005    Sabrina             Tarefa 14419: Tratar tipo de saída SM como venda normal
    23/09/2005    Sabrina             Tarefa 21082: Ajuste p/ melhoria de performance
                                      - colocado NVL
    06/10/2005    Sabrina             Tarefa 21838: Ajuste p/ melhoria de performance
                                      - colocado "+ rule"
    16/01/2006    Juliana             Tarefa 24120: Gravação das informações referente as entradas
                                      e devoluções de mercadorias;
    27/06/2006    Sabrina             Tarefa 28666: Ajuste na consolidacao de plano de voo para nao
                                      considerar vendas tipo 16
    25/01/2007    Carolina            Tarefa 37364 : Alteração nas quantidades de vendas para considerar
                                             as saidas por bonificação('SB') (PCDTPROD.QTVENDA).
    07/01/2010    Hoe                 Tarefa 99341 : Na seleção das Vendas, para geração do PCDTPROD,
                                             ligar PCNFSAID ao PCPEDC através de NUMTRANSVENDA e NUMPED,
                                             conforme já é feito nas rotina do módulo 1.
    29/04/2011   Eduardo Mendonça     Ajustado para Comitar a cada 1000 registros processados
    18/10/2011   Tatiane Mota         Alterado para gravar o valor do custo fin de devolução.
    27/01/2012   Eduardo Mendonça     Incrementado no select dos cálculos o TRUNC para evitar que traga valores maiores que os campos
    20/07/2012   Tatiane Mota         Alterado para passar o produto como opção de escolha para consolidar planovoo.
    02/08/2012   Tatiane Mota        Alterar o valor de devolução para buscar da view de devolução.
    31/oct/2012   Tatiane Mota     Rotina atualizada pois o select de gravação da pcdtprod estava validando bonificação para quantidade
    06/MAR/2013 Tatiane Mota     Rotina atualizada para buscar vendas de view
    ---------------------------------------------------------------------------------------
     */
   IS
    /*-- Cursor para consolidacao de PRODUTOS
    -- ALTERADO EM 30.05.20O1 POR FABIO
    -- O PROPRIO DECODE JA GARANTE QUE SOMENTE SERAO SOMADOS PRODUTOS COM
    -- CODIGO DA OPERACAO E ( ENTRADA ) OU S ( SAIDA )*/

    CURSOR_MOVIMENTACAO SYS_REFCURSOR;

    --MOVIMENTAÇÃO DE COMPRAS
    TYPE CONSULTA IS RECORD(
      CODFILIAL   PCMOV.CODFILIAL%TYPE,
      CODPROD     PCMOV.CODPROD%TYPE,
      DTMOV       PCMOV.DTMOV%TYPE,
      VLVENDA     PCMOV.PUNIT%TYPE,
      VLCUSTOFIN  PCMOV.CUSTOFIN%TYPE,
      VLCUSTOREAL PCMOV.CUSTOREAL%TYPE,
      VLCUSTOREP  PCMOV.CUSTOREP%TYPE,
      VLCUSTOCONT PCMOV.CUSTOCONT%TYPE,
      QTVENDA     PCMOV.QT%TYPE,
      QTNOTA      PCMOV.QT%TYPE,
      VLENT       PCMOV.PUNIT%TYPE,
      QTENT       PCMOV.QT%TYPE,
      VLDEVOLCLI  PCMOV.PUNIT%TYPE,
      QTBONIFIC   NUMBER(22, 6),
      VLBONIFIC   NUMBER(22, 6),
      QTDEVOLCLI  PCMOV.QT%TYPE,
      ST          PCMOV.ST%TYPE,
      VLIPI       PCMOV.VLIPI%TYPE,
      VLREPASSE   PCMOV.VLREPASSE%TYPE,
     VLCUSTOFINBONIF NUMBER(22, 6),
     STBONIFICACAO    PCMOV.ST%TYPE,
     VLIPIBONIFICACAO PCMOV.VLIPI%TYPE
     --FIN-2983
     ,VLVERBACMV       PCMOV.VLVERBACMV%TYPE
     ,VLVERBACMVCLI    PCMOV.VLVERBACMVCLI%TYPE
     ,VLVERBACMVAVULSO PCMOV.VLVERBACMVCLI%TYPE
     );
    ITENS_PCMOV CONSULTA;

    --ITENS SEM VENDA
    TYPE CONSULTA_ITENS_SEM_VENDA IS RECORD(
      CODPROD      PCPRODUT.CODPROD%TYPE,
      CODFILIAL    PCHISTEST.CODFILIAL%TYPE,
      QTESTGER     PCHISTEST.QTESTGER%TYPE,
      CUSTOFIN     PCHISTEST.CUSTOFIN%TYPE,
      CUSTOREAL    PCHISTEST.CUSTOREAL%TYPE,
      CUSTOREP     PCHISTEST.CUSTOREP%TYPE,
      CUSTOCONT    PCHISTEST.CUSTOCONT%TYPE,
      DATA         PCHISTEST.DATA%TYPE,
      CODFORNEC    PCPRODUT.CODFORNEC%TYPE,
      CODEPTO      PCPRODUT.CODEPTO%TYPE,
      CODSEC       PCPRODUT.CODSEC%TYPE,
      CODPRODPRINC PCPRODUT.CODPRODPRINC%TYPE,
      CLASSE       PCPRODUT.CLASSE%TYPE);

    ITENS_SEM_VENDA CONSULTA_ITENS_SEM_VENDA;

    --ITENS DE PERDA
    TYPE CONSULTA_ITENS_PERDA IS RECORD(
      CODPROD     PCMOV.CODPROD%TYPE,
      CODFILIAL   PCMOV.CODFILIAL%TYPE,
      DTMOV       PCMOV.DTMOV%TYPE,
      QTPERDA     PCMOV.QT%TYPE,
      VLCUSTOFIN  PCMOV.CUSTOFIN%TYPE,
      VLCUSTOREAL PCMOV.CUSTOREAL%TYPE,
      VLCUSTOREP  PCMOV.CUSTOREP%TYPE);

    ITENS_PERDA CONSULTA_ITENS_PERDA;

    --ENTRADAS DE MERCADORIAS
    TYPE CONSULTA_ENTRADA_MERCADORIA IS RECORD(
      CODPROD   PCMOV.CODPROD%TYPE,
      CODFILIAL PCMOV.CODFILIAL%TYPE,
      DTMOV     PCMOV.DTMOV%TYPE,
      QTENT     PCMOV.QT%TYPE,
      VLENT     PCMOV.PUNIT%TYPE);

    ITENS_ENTRADA_MERCADORIA CONSULTA_ENTRADA_MERCADORIA;

    --DEVOLUÇÃO DE MERCADORIAS
    TYPE CONSULTA_DEVOLUCAO_MERCADORIA IS RECORD(
      CODPROD            PCMOV.CODPROD%TYPE,
      CODFILIAL          PCMOV.CODFILIAL%TYPE,
      DTMOV              PCMOV.DTMOV%TYPE,
      VLDEVOLCLI         NUMBER(22, 6),
      QTDEVOLCLI         NUMBER(22, 6),
      VLCUSTOFINDEVOLCLI NUMBER(22, 6),
      STDEVOLUCAO        NUMBER(22, 6),
      VLIPIDEVOLUCAO     PCMOV.VLIPI%TYPE,
      VLREPASSEDEVOLUCAO PCMOV.VLREPASSE%TYPE,
      VLCMVDEVOLBONIF    NUMBER(18, 6),
      STBONIFDEVOL        NUMBER(22, 6),
      VLIPIBONIFDEVOL    NUMBER(22, 6));

    ITENS_DEVOLUCAO_MERCADORIA CONSULTA_DEVOLUCAO_MERCADORIA;

    /*-- LINHA ANTERIOR EXISTENTE DENTRO DA CLAUSULA WHERE DO SELECT ACIMA
    -- POREM DESNECESSARIA
    -- ( (CODOPER = 'S')  OR (CODOPER = 'E') ) AND*/
    VQTDECOMMIT    NUMBER(10) := 0; -- Contador para efetuar COMMIT
    VFUNCAO        VARCHAR2(20); -- Usada no LOG de erros
    VCOUNT         NUMBER(10); -- Variavel de trabalho para funcao COUNT
    VCODFORNEC     NUMBER(6); -- Temporaria para recuperar codigo de fornecedor
    VCODEPTO       NUMBER(6); -- Temporaria para recuperar codigo do departamento
    VCODSEC        NUMBER(6); -- Temporaria para recuperar codigo da Secao
    VCODPRODPRINC  NUMBER(6);
    VCLASSE        VARCHAR2(1);
    VQTESTGER      NUMBER;
    VCUSTOFIN      NUMBER;
    VCUSTOREAL     NUMBER;
    VCUSTOREP      NUMBER;
    VCUSTOCONT     NUMBER;
    VICONTADOR     NUMBER;
    VNCODEPTO      NUMBER;
    VNCODSEC       NUMBER;
    VNCODFORNEC    NUMBER;
    VSCLASSE       VARCHAR2(1);
    VNCODPRODPRINC NUMBER;
    VPARAMCODCLIPC NUMBER := 0;

    V_SQL    VARCHAR2(10000);
    V_SQLAUX VARCHAR2(10000);

    --PROCEDURE DE LOG
    PROCEDURE GRAVALOGJOB(P_MODULO     IN VARCHAR2,
                          P_FUNCAO     IN VARCHAR2,
                          P_TIPOLOG    IN VARCHAR2,
                          P_DATA       IN DATE,
                          P_DSJOB      IN VARCHAR2,
                          P_PARAMETROS IN VARCHAR2) IS
    BEGIN
      BEGIN
        INSERT INTO PCLOGJOB
          (MODULO, FUNCAO, TIPO_LOG, DATA_LOG, DS_JOB, PARAMETROS)
        VALUES
          (P_MODULO, P_FUNCAO, P_TIPOLOG, P_DATA, P_DSJOB, P_PARAMETROS);

        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END;
  BEGIN
    V_SQL := 'SELECT
            VENDAS.CODFILIAL,
            VENDAS.CODPROD,
            VENDAS.DTSAIDA DTMOV,
            SUM(VENDAS.VLVENDA) VLVENDA,
            SUM(VENDAS.VLCUSTOFINB) VLCUSTOFIN,
            SUM(VENDAS.VLCUSTOREAL) VLCUSTOREAL,
            SUM(VENDAS.VLCUSTOREP) VLCUSTOREP,
            SUM(VENDAS.VLCUSTOCONT) VLCUSTOCONT,
            SUM(VENDAS.QTVENDA) QTVENDA,
            COUNT(DISTINCT(DECODE(VENDAS.CODOPER,
                                  ''S'',
                                  VENDAS.NUMNOTA,
                                  ''SM'',
                                  VENDAS.NUMNOTA,
                                  0))) QTNOTA,
            SUM(VENDAS.QTENT) QTENT,
            SUM(VENDAS.VLENT) VLENT,
            SUM(VENDAS.VLDEVOLCLI) VLDEVOLCLI,
            SUM(VENDAS.QTBONIFIC) QTBONIFIC,
            SUM(VENDAS.VLBONIFIC) VLBONIFIC,
            SUM(VENDAS.QTDEVOLCLI) QTDEVOLCLI,
            SUM(NVL(VENDAS.ICMSRETIDO,0)) ST,
            SUM(NVL(VENDAS.VLIPI,0)) VLIPI,
            SUM(NVL(VENDAS.VLREPASSE,0)) VLREPASSE,
            SUM(VENDAS.VLCUSTOFINBONIF) VLCUSTOFINBONIF,
            SUM(VENDAS.ICMSRETIDOBONIFIC) STBONIFICACAO,
            SUM(VENDAS.VLIPIBONIFIC) VLIPIBONIFICACAO
            --FIN-2983
            , SUM(VENDAS.VLVERBACMV) AS VLVERBACMV
            , SUM(VENDAS.VLVERBACMVCLI) AS VLVERBACMVCLI
            , SUM((SELECT NVL(SUM(NVL(PCAPLICVERBAPEDI.VLVERBACMV,0)* NVL(I.QT, 0)) , 0)
                   FROM PCAPLICVERBAPEDI, PCPEDI I
                   WHERE PCAPLICVERBAPEDI.NUMPED = VENDAS.NUMPED
                   AND PCAPLICVERBAPEDI.NUMPED = I.NUMPED
                   AND PCAPLICVERBAPEDI.CODPROD = I.CODPROD
                   AND PCAPLICVERBAPEDI.CODPROD = VENDAS.CODPROD)) AS VLVERBACMVAVULSO
       FROM (VIEW_VENDAS_RESUMO_FATURAMENTO) VENDAS, PCFILIAL
      WHERE VENDAS.CODFILIAL = PCFILIAL.CODIGO
        AND VENDAS.DTSAIDA BETWEEN :P_PDTINICIO AND :P_PDTTERMINO
        AND NVL(VENDAS.CONDVENDA, -1) IN (1, 5, -1, 7, 9, 11, 14)
        AND VENDAS.CODFISCAL NOT IN (522, 622, 722, 532, 632, 732)
        AND PCFILIAL.CONSOLIDADADOS504 = ''S'' ';

    IF (PLISTACODIGO IS NOT NULL) THEN
      V_SQL := V_SQL || ' AND VENDAS.CODPROD IN (' || PLISTACODIGO || ')';
    END IF;

    IF (PCODFILIAL IS NOT NULL) THEN
      V_SQL := V_SQL || ' AND VENDAS.CODFILIAL = ''' || PCODFILIAL || '''';
    END IF;

    V_SQL := V_SQL ||
             ' GROUP BY VENDAS.CODFILIAL, VENDAS.CODPROD, VENDAS.DTSAIDA';

    GRAVALOGJOB('CONSOLIDACAODADOS',
                NULL,
                NULL,
                SYSDATE,
                'INICIO CONSOLIDACAO',
                TO_CHAR(PDTINICIO, 'DD/MM/YYYY') || ' / ' ||
                TO_CHAR(PDTTERMINO, 'DD/MM/YYYY') || ' / ' || POPCAO ||
                ' / ' || PCODFILIAL);

    -- GARANTE ALGUM TRANSACTION ABERTO ANTERIORMENTE pelo aplicativo
    ROLLBACK;

    BEGIN
      V_SQLAUX := 'SELECT COUNT(1)
                 FROM PCDTPROD
                 WHERE DTMOV BETWEEN :PDTINICIO AND :PDTTERMINO ';

      IF (PLISTACODIGO IS NOT NULL) THEN
        V_SQLAUX := V_SQLAUX || ' AND CODPROD IN ( ' || PLISTACODIGO || ')';
      END IF;

      IF (PCODFILIAL IS NOT NULL) THEN
        V_SQLAUX := V_SQLAUX || ' AND CODFILIAL = ''' || PCODFILIAL || '''';
      END IF;

      V_SQLAUX := V_SQLAUX || ' AND ROWNUM = 1';

      EXECUTE IMMEDIATE V_SQLAUX
        INTO VCOUNT
        USING PDTINICIO, PDTTERMINO;

      --SE A QUANTIDADE ENCONTRADA FOR MAIOR QUE ZERO, APAGA OS DADOS
      IF VCOUNT > 0 THEN
        V_SQLAUX := 'DELETE FROM PCDTPROD
                   WHERE DTMOV BETWEEN :PDTINICIO AND :PDTTERMINO ';

        IF (PLISTACODIGO IS NOT NULL) THEN
          V_SQLAUX := V_SQLAUX || ' AND CODPROD IN (' || PLISTACODIGO || ')';
        END IF;

        IF (PCODFILIAL IS NOT NULL) THEN
          V_SQLAUX := V_SQLAUX || ' AND CODFILIAL = ''' || PCODFILIAL || '''';
        END IF;

        EXECUTE IMMEDIATE V_SQLAUX
          USING PDTINICIO, PDTTERMINO;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20000,
                                'Ocorreu erro ao executar o SQL de dados.' ||
                                CHR(13) || SQLERRM);
    END;

    VFUNCAO := 'Produtos';

    -- Gera log da execucao da consolidacao
    GRAVALOGJOB('CONSOLIDACAODADOS',
                VFUNCAO,
                'PI',
                SYSDATE,
                'INICIO CONSOLIDACAO',
                TO_CHAR(PDTINICIO, 'DD/MM/YYYY') || ' / ' ||
                TO_CHAR(PDTTERMINO, 'DD/MM/YYYY') || ' / ' || POPCAO||
                ' / ' || PCODFILIAL);

    OPEN CURSOR_MOVIMENTACAO FOR V_SQL
      USING PDTINICIO, PDTTERMINO;
    LOOP
      FETCH CURSOR_MOVIMENTACAO
        INTO ITENS_PCMOV;
      EXIT WHEN CURSOR_MOVIMENTACAO%NOTFOUND;

      VCODFORNEC    := 0;
      VCODEPTO      := 0;
      VCODSEC       := 0;
      VCODPRODPRINC := 0;
      VQTESTGER     := 0;
      VCUSTOFIN     := 0;
      VCUSTOREAL    := 0;
      VCUSTOREP     := 0;
      VCUSTOCONT    := 0;

      --PRIMEIRO PROCURA OS REGISTROS NA TABELA PCHISTESTFILA E CASO NÃO EXISTA PEGA DA PCHISTEST
      BEGIN
        SELECT PCPRODUT.CODFORNEC,
               PCPRODUT.CODEPTO,
               DECODE(NVL(PCPRODUT.CODPRODPRINC, 0),
                      0,
                      PCPRODUT.CODPROD,
                      PCPRODUT.CODPRODPRINC),
               PCPRODUT.CLASSE,
               PCPRODUT.CODSEC,
               PCHISTESTFILA.QTESTGER,
               PCHISTESTFILA.CUSTOFIN,
               PCHISTESTFILA.CUSTOREAL,
               PCHISTESTFILA.CUSTOREP,
               PCHISTESTFILA.CUSTOCONT
        INTO VCODFORNEC,
             VCODEPTO,
             VCODPRODPRINC,
             VCLASSE,
             VCODSEC,
             VQTESTGER,
             VCUSTOFIN,
             VCUSTOREAL,
             VCUSTOREP,
             VCUSTOCONT
        FROM PCHISTESTFILA, PCPRODUT
        WHERE PCHISTESTFILA.CODPROD = PCPRODUT.CODPROD
        AND PCHISTESTFILA.CODFILIAL = ITENS_PCMOV.CODFILIAL
        AND PCHISTESTFILA.CODPROD = ITENS_PCMOV.CODPROD
        AND PCHISTESTFILA.DATA = ITENS_PCMOV.DTMOV;
      EXCEPTION
        WHEN OTHERS THEN
          BEGIN
            SELECT PCPRODUT.CODFORNEC,
                   PCPRODUT.CODEPTO,
                   DECODE(NVL(PCPRODUT.CODPRODPRINC, 0),
                          0,
                          PCPRODUT.CODPROD,
                          PCPRODUT.CODPRODPRINC),
                   PCPRODUT.CLASSE,
                   PCPRODUT.CODSEC,
                   PCHISTEST.QTESTGER,
                   PCHISTEST.CUSTOFIN,
                   PCHISTEST.CUSTOREAL,
                   PCHISTEST.CUSTOREP,
                   PCHISTEST.CUSTOCONT
            INTO VCODFORNEC,
                 VCODEPTO,
                 VCODPRODPRINC,
                 VCLASSE,
                 VCODSEC,
                 VQTESTGER,
                 VCUSTOFIN,
                 VCUSTOREAL,
                 VCUSTOREP,
                 VCUSTOCONT
            FROM PCHISTEST, PCPRODUT
            WHERE PCHISTEST.CODPROD = PCPRODUT.CODPROD
            AND PCHISTEST.CODFILIAL = ITENS_PCMOV.CODFILIAL
            AND PCHISTEST.CODPROD = ITENS_PCMOV.CODPROD
            AND PCHISTEST.DATA = ITENS_PCMOV.DTMOV;
          EXCEPTION
            WHEN OTHERS THEN
              NULL;
        END;
      END;

      INSERT INTO PCDTPROD
        (CODFILIAL,
         CODPROD,
         DTMOV,
         CODEPTO,
         CODFORNEC,
         VLVENDA,
         VLCUSTOFIN,
         VLCUSTOREAL,
         VLCUSTOREP,
         VLCUSTOCONT,
         QTVENDA,
         QTNOTA,
         VLENT,
         QTENT,
         QTDEVOLCLI,
         VLDEVOLCLI,
         QTBONIFIC,
         VLBONIFIC,
         CODPRODPRINC,
         CLASSE,
         CODSEC,
         QTESTGER,
         CUSTOFIN,
         CUSTOREAL,
         CUSTOREP,
         CUSTOCONT,
         ST,
         VLIPI,
         VLREPASSE,
         VLCUSTOFINBONIF,
         STBONIFICACAO,
         VLIPIBONIFICACAO
         --FIN-2983
         ,VLVERBACMV
         ,VLVERBACMVCLI
         ,VLVERBACMVAVULSO
         )
      VALUES
        (ITENS_PCMOV.CODFILIAL,
         ITENS_PCMOV.CODPROD,
         ITENS_PCMOV.DTMOV,
         VCODEPTO,
         VCODFORNEC,
         ITENS_PCMOV.VLVENDA,
         ITENS_PCMOV.VLCUSTOFIN,
         ITENS_PCMOV.VLCUSTOREAL,
         ITENS_PCMOV.VLCUSTOREP,
         ITENS_PCMOV.VLCUSTOCONT,
         ITENS_PCMOV.QTVENDA,
         ITENS_PCMOV.QTNOTA,
         ITENS_PCMOV.VLENT,
         ITENS_PCMOV.QTENT,
         ITENS_PCMOV.QTDEVOLCLI,
         ITENS_PCMOV.VLDEVOLCLI,
         ITENS_PCMOV.QTBONIFIC,
         ITENS_PCMOV.VLBONIFIC,
         VCODPRODPRINC,
         VCLASSE,
         VCODSEC,
         VQTESTGER,
         VCUSTOFIN,
         VCUSTOREAL,
         VCUSTOREP,
         VCUSTOCONT,
         ITENS_PCMOV.ST,
         ITENS_PCMOV.VLIPI,
         ITENS_PCMOV.VLREPASSE,
         ITENS_PCMOV.VLCUSTOFINBONIF ,
         ITENS_PCMOV.STBONIFICACAO,
         ITENS_PCMOV.VLIPIBONIFICACAO
         --FIN-2983
         ,ITENS_PCMOV.VLVERBACMV
         ,ITENS_PCMOV.VLVERBACMVCLI
         ,ITENS_PCMOV.VLVERBACMVAVULSO
         );

      VQTDECOMMIT := VQTDECOMMIT + 1;

      IF VQTDECOMMIT > 1000 THEN
        COMMIT;
        VQTDECOMMIT := 0;
      END IF;
    END LOOP;
    ---------------------------------------------------------------------------------------------

    COMMIT;

    VQTDECOMMIT := 0;

    -- Gera log da execucao da consolidacao
    GRAVALOGJOB('CONSOLIDACAODADOS',
                VFUNCAO,
                'PV',
                SYSDATE,
                'TERMINO CONSOLIDACAO',
                PCODFILIAL);

    --GRAVAÇÃO DE ESTOQUE - CASO NÃO TENHA VENDA DO PRODUTO
    --PRIMEIRO GRAVA PEGANDO REGISTRO DA TABELA PCHISTESTFILA
    V_SQL := 'INSERT INTO PCDTPROD
                (CODFILIAL,
                 CODPROD,
                 DTMOV,
                 CODEPTO,
                 CODFORNEC,
                 VLVENDA,
                 VLCUSTOFIN,
                 VLCUSTOREAL,
                 VLCUSTOREP,
                 VLCUSTOCONT,
                 QTVENDA,
                 QTNOTA,
                 VLENT,
                 QTENT,
                 QTDEVOLCLI,
                 VLDEVOLCLI,
                 CODPRODPRINC,
                 CLASSE,
                 CODSEC,
                 QTESTGER,
                 CUSTOFIN,
                 CUSTOREAL,
                 CUSTOREP,
                 CUSTOCONT)
              SELECT PCHISTESTFILA.CODFILIAL,
                     PCPRODUT.CODPROD,
                     PCHISTESTFILA.DATA,
                     PCPRODUT.CODEPTO,
                     PCPRODUT.CODFORNEC,
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
                     PCPRODUT.CODPRODPRINC,
                     PCPRODUT.CLASSE,
                     PCPRODUT.CODSEC,
                     PCHISTESTFILA.QTESTGER,
                     PCHISTESTFILA.CUSTOFIN,
                     PCHISTESTFILA.CUSTOREAL,
                     PCHISTESTFILA.CUSTOREP,
                     PCHISTESTFILA.CUSTOCONT
              FROM   PCFILIAL,
                     PCHISTESTFILA,
                     PCPRODUT
              WHERE  PCFILIAL.CONSOLIDADADOS504 = ''S''
              AND    PCHISTESTFILA.CODFILIAL = PCFILIAL.CODIGO
              AND    PCHISTESTFILA.CODPROD = PCPRODUT.CODPROD
              AND    PCHISTESTFILA.DATA = :PDTTERMINO
              AND NOT EXISTS( SELECT 1
                              FROM PCDTPROD
                              WHERE DTMOV = PCHISTESTFILA.DATA
                              AND CODFILIAL = PCHISTESTFILA.CODFILIAL
                              AND CODPROD = PCPRODUT.CODPROD)';

    IF (PLISTACODIGO IS NOT NULL) THEN
      V_SQL := V_SQL || ' AND PCHISTESTFILA.CODPROD IN ( ' || PLISTACODIGO || ')';
    END IF;

    IF (PCODFILIAL IS NOT NULL) THEN
      V_SQL := V_SQL || ' AND PCHISTESTFILA.CODFILIAL = ''' || PCODFILIAL || '''';
    END IF;

    EXECUTE immediate V_SQL USING PDTTERMINO;

    COMMIT;

    --CASO NÃO TENHA REGISTROS NA TABELA PCHISTESTFILA PEGA OS REGISTROS DA TABELA PCHISTEST
    V_SQL := 'INSERT INTO PCDTPROD
                (CODFILIAL,
                 CODPROD,
                 DTMOV,
                 CODEPTO,
                 CODFORNEC,
                 VLVENDA,
                 VLCUSTOFIN,
                 VLCUSTOREAL,
                 VLCUSTOREP,
                 VLCUSTOCONT,
                 QTVENDA,
                 QTNOTA,
                 VLENT,
                 QTENT,
                 QTDEVOLCLI,
                 VLDEVOLCLI,
                 CODPRODPRINC,
                 CLASSE,
                 CODSEC,
                 QTESTGER,
                 CUSTOFIN,
                 CUSTOREAL,
                 CUSTOREP,
                 CUSTOCONT)
              SELECT PCHISTEST.CODFILIAL,
                     PCPRODUT.CODPROD,
                     PCHISTEST.DATA,
                     PCPRODUT.CODEPTO,
                     PCPRODUT.CODFORNEC,
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
                     PCPRODUT.CODPRODPRINC,
                     PCPRODUT.CLASSE,
                     PCPRODUT.CODSEC,
                     PCHISTEST.QTESTGER,
                     PCHISTEST.CUSTOFIN,
                     PCHISTEST.CUSTOREAL,
                     PCHISTEST.CUSTOREP,
                     PCHISTEST.CUSTOCONT
              FROM   PCFILIAL,
                     PCHISTEST,
                     PCPRODUT
              WHERE  PCFILIAL.CONSOLIDADADOS504 = ''S''
              AND    PCHISTEST.CODFILIAL = PCFILIAL.CODIGO
              AND    PCHISTEST.CODPROD = PCPRODUT.CODPROD
              AND    PCHISTEST.DATA = :PDTTERMINO
              AND NOT EXISTS( SELECT 1
                              FROM PCDTPROD
                              WHERE DTMOV = PCHISTEST.DATA
                              AND CODFILIAL = PCHISTEST.CODFILIAL
                              AND CODPROD = PCPRODUT.CODPROD)';

    IF (PLISTACODIGO IS NOT NULL) THEN
      V_SQL := V_SQL || ' AND PCHISTEST.CODPROD IN ( ' || PLISTACODIGO || ')';
    END IF;

    IF (PCODFILIAL IS NOT NULL) THEN
      V_SQL := V_SQL || ' AND PCHISTEST.CODFILIAL = ''' || PCODFILIAL || '''';
    END IF;

    EXECUTE immediate V_SQL USING PDTTERMINO;

    COMMIT;
    ---------------------------------------------------------------------------------------------

    -- Gera log da execucao da consolidacao
    GRAVALOGJOB('CONSOLIDACAODADOS',
                VFUNCAO,
                'PE',
                SYSDATE,
                'PERDA DE ESTOQUE',
                PCODFILIAL);

    --GRAVAÇÃO DA QUANTIDADE DE PERDA DE ESTOQUE
    V_SQL := 'SELECT PCMOV.CODPROD,
                   PCMOV.CODFILIAL,
                   PCMOV.DTMOV,
                   SUM(DECODE(PCMOV.CODOPER,
                              ''SL'',
                              NVL(QT, 0),
                              ''EL'',
                              (NVL(QT, 0) * (-1)))) QTPERDA,
                   SUM((NVL(PCMOV.CUSTOFIN, 0) *
                       DECODE(PCMOV.CODOPER,
                               ''SL'',
                               NVL(QT, 0),
                               ''EL'',
                               (NVL(QT, 0) * (-1))))) VLCUSTOFIN,
                   SUM((NVL(PCMOV.CUSTOREAL, 0) *
                       DECODE(PCMOV.CODOPER,
                               ''SL'',
                               NVL(QT, 0),
                               ''EL'',
                               (NVL(QT, 0) * (-1))))) VLCUSTOREAL,
                   SUM((NVL(PCMOV.CUSTOREP, 0) *
                       DECODE(PCMOV.CODOPER,
                               ''SL'',
                               NVL(QT, 0),
                               ''EL'',
                               (NVL(QT, 0) * (-1))))) VLCUSTOREP
            FROM PCMOV, PCFILIAL
            WHERE PCMOV.DTMOV BETWEEN :PDTINICIO AND :PDTTERMINO
            AND NVL(PCMOV.CODOPER, ''X'') IN (''SL'', ''EL'')
            AND PCFILIAL.CODIGO = PCMOV.CODFILIAL
            AND PCFILIAL.CONSOLIDADADOS504 = ''S''';

    IF (PLISTACODIGO IS NOT NULL) THEN
      V_SQL := V_SQL || ' AND PCMOV.CODPROD IN (' || PLISTACODIGO || ')';
    END IF;

    IF (PCODFILIAL IS NOT NULL) THEN
      V_SQL := V_SQL || ' AND PCMOV.CODFILIAL = ''' || PCODFILIAL || '''';
    END IF;

    V_SQL := V_SQL ||
             'GROUP BY PCMOV.CODPROD, PCMOV.CODFILIAL, PCMOV.DTMOV';

    OPEN CURSOR_MOVIMENTACAO FOR V_SQL
      USING PDTINICIO, PDTTERMINO;
    LOOP
      FETCH CURSOR_MOVIMENTACAO
        INTO ITENS_PERDA;
      EXIT WHEN CURSOR_MOVIMENTACAO%NOTFOUND;

      BEGIN
        UPDATE PCDTPROD
        SET QTPERDA     = ITENS_PERDA.QTPERDA,
            VLCUSTOFIN  = NVL(VLCUSTOFIN, 0) + ITENS_PERDA.VLCUSTOFIN,
            VLCUSTOREAL = NVL(VLCUSTOREAL, 0) + ITENS_PERDA.VLCUSTOREAL,
            VLCUSTOREP  = NVL(VLCUSTOREP, 0) + ITENS_PERDA.VLCUSTOREP
        WHERE PCDTPROD.CODPROD = ITENS_PERDA.CODPROD
        AND PCDTPROD.CODFILIAL = ITENS_PERDA.CODFILIAL
        AND PCDTPROD.DTMOV = ITENS_PERDA.DTMOV;

        IF SQL%ROWCOUNT = 0 THEN
          SELECT CODEPTO, CODSEC, CODFORNEC, CLASSE, CODPRODPRINC
          INTO VNCODEPTO, VNCODSEC, VNCODFORNEC, VSCLASSE, VNCODPRODPRINC
          FROM PCPRODUT
          WHERE PCPRODUT.CODPROD = ITENS_PERDA.CODPROD;

          INSERT INTO PCDTPROD
            (CODFILIAL,
             CODPROD,
             DTMOV,
             CODEPTO,
             CODFORNEC,
             VLVENDA,
             VLCUSTOFIN,
             VLCUSTOREAL,
             VLCUSTOREP,
             VLCUSTOCONT,
             QTVENDA,
             QTNOTA,
             VLENT,
             QTENT,
             QTDEVOLCLI,
             VLDEVOLCLI,
             CODPRODPRINC,
             CLASSE,
             CODSEC,
             QTESTGER,
             CUSTOFIN,
             CUSTOREAL,
             CUSTOREP,
             CUSTOCONT,
             QTPERDA)
          VALUES
            (ITENS_PERDA.CODFILIAL,
             ITENS_PERDA.CODPROD,
             ITENS_PERDA.DTMOV,
             VNCODEPTO,
             VNCODFORNEC,
             0,
             ITENS_PERDA.VLCUSTOFIN,
             ITENS_PERDA.VLCUSTOREAL,
             ITENS_PERDA.VLCUSTOREP,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             VNCODPRODPRINC,
             VSCLASSE,
             VNCODSEC,
             0,
             0,
             0,
             0,
             0,
             ITENS_PERDA.QTPERDA);
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;

      VQTDECOMMIT := VQTDECOMMIT + 1;

      IF VQTDECOMMIT > 1000 THEN
        COMMIT;
        VQTDECOMMIT := 0;
      END IF;
    END LOOP;
    ---------------------------------------------------------------------------------------------

    -- Gera log da execucao da consolidacao
    GRAVALOGJOB('CONSOLIDACAODADOS',
                VFUNCAO,
                'EM',
                SYSDATE,
                'ENTRADA DE MERCADORIA',
              PCODFILIAL);

    --GRAVAÇÃO DAS ENTRADAS DE MERCADORIAS
    V_SQL := 'SELECT PCMOV.CODPROD,
                   PCMOV.CODFILIAL,
                   PCMOV.DTMOV,
                   SUM(DECODE(PCMOV.CODOPER, ''E'', NVL(QT, 0), ''EB'', (NVL(QT, 0)), ''ET'', NVL(QT, 0) )) QTENT,
                   SUM((NVL(PCMOV.PUNIT, 0) * DECODE(PCMOV.CODOPER, ''E'', NVL(QT, 0), ''EB'', (NVL(QT, 0)), ''ET'', NVL(QT, 0)  ))) VLENT
            FROM PCMOV, PCFILIAL
            WHERE PCMOV.DTMOV BETWEEN :PDTINICIO AND :PDTTERMINO
            AND NVL(PCMOV.CODOPER, ''X'') IN (''E'', ''EB'', ''ET'')
            AND PCMOV.DTCANCEL IS NULL
            AND PCFILIAL.CODIGO = PCMOV.CODFILIAL
            AND PCFILIAL.CONSOLIDADADOS504 = ''S''';

    IF (PLISTACODIGO IS NOT NULL) THEN
      V_SQL := V_SQL || ' AND PCMOV.CODPROD IN ( ' || PLISTACODIGO || ')';
    END IF;

    IF (PCODFILIAL IS NOT NULL) THEN
      V_SQL := V_SQL || ' AND PCMOV.CODFILIAL = ''' || PCODFILIAL || '''';
    END IF;

    V_SQL := V_SQL ||
             'GROUP BY PCMOV.CODPROD, PCMOV.CODFILIAL, PCMOV.DTMOV';

    OPEN CURSOR_MOVIMENTACAO FOR V_SQL
      USING PDTINICIO, PDTTERMINO;
    LOOP
      FETCH CURSOR_MOVIMENTACAO
        INTO ITENS_ENTRADA_MERCADORIA;
      EXIT WHEN CURSOR_MOVIMENTACAO%NOTFOUND;
      BEGIN
        UPDATE PCDTPROD
        SET QTENT = ITENS_ENTRADA_MERCADORIA.QTENT,
            VLENT = NVL(VLENT, 0) + ITENS_ENTRADA_MERCADORIA.VLENT
        WHERE PCDTPROD.CODPROD = ITENS_ENTRADA_MERCADORIA.CODPROD
        AND PCDTPROD.CODFILIAL = ITENS_ENTRADA_MERCADORIA.CODFILIAL
        AND PCDTPROD.DTMOV = ITENS_ENTRADA_MERCADORIA.DTMOV;

        IF SQL%ROWCOUNT = 0 THEN
          SELECT CODEPTO, CODSEC, CODFORNEC, CLASSE, CODPRODPRINC
          INTO VNCODEPTO, VNCODSEC, VNCODFORNEC, VSCLASSE, VNCODPRODPRINC
          FROM PCPRODUT
          WHERE PCPRODUT.CODPROD = ITENS_ENTRADA_MERCADORIA.CODPROD;

          INSERT INTO PCDTPROD
            (CODFILIAL,
             CODPROD,
             DTMOV,
             CODEPTO,
             CODFORNEC,
             VLVENDA,
             VLCUSTOFIN,
             VLCUSTOREAL,
             VLCUSTOREP,
             VLCUSTOCONT,
             QTVENDA,
             QTNOTA,
             VLENT,
             QTENT,
             QTDEVOLCLI,
             VLDEVOLCLI,
             CODPRODPRINC,
             CLASSE,
             CODSEC,
             QTESTGER,
             CUSTOFIN,
             CUSTOREAL,
             CUSTOREP,
             CUSTOCONT,
             QTPERDA)
          VALUES
            (ITENS_ENTRADA_MERCADORIA.CODFILIAL,
             ITENS_ENTRADA_MERCADORIA.CODPROD,
             ITENS_ENTRADA_MERCADORIA.DTMOV,
             VNCODEPTO,
             VNCODFORNEC,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             ITENS_ENTRADA_MERCADORIA.VLENT,
             ITENS_ENTRADA_MERCADORIA.QTENT,
             0,
             0,
             VNCODPRODPRINC,
             VSCLASSE,
             VNCODSEC,
             0,
             0,
             0,
             0,
             0,
             0);
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;

      VQTDECOMMIT := VQTDECOMMIT + 1;

      IF VQTDECOMMIT > 1000 THEN
        COMMIT;
        VQTDECOMMIT := 0;
      END IF;
    END LOOP;
    ---------------------------------------------------------------------------------------------

    -- Gera log da execucao da consolidacao
    GRAVALOGJOB('CONSOLIDACAODADOS',
                VFUNCAO,
                'DV',
                SYSDATE,
                'DEVOLUÇÃO DE MERCADORIA',
               PCODFILIAL);

    VQTDECOMMIT := 0;

    --GRAVAÇÃO DAS DEVOLUÇÕES DE MERCADORIAS
    V_SQL := 'SELECT TOTAL.CODPROD,
                   TOTAL.CODFILIAL,
                   TOTAL.DTENT DTMOV,
                   (SUM(TOTAL.TOTALDEVOL) + SUM(TOTAL.TOTALDEVOL2)) VLDEVOLCLI,
                   (SUM(TOTAL.QTDEVOLCLI) + SUM(TOTAL.QTDEVOLCLI2)) QTDEVOLCLI,
                   (SUM(TOTAL.VLCUSTOFIN) + SUM(TOTAL.VLCUSTOFIN2)) VLCUSTOFINDEVOLCLI,
                   (SUM(TOTAL.VLST)) STDEVOLUCAO,
                   (SUM(TOTAL.VLIPI)) VLIPIDEVOLUCAO,
                   (SUM(TOTAL.VLREPASSE)) VLREPASSEDEVOLUCAO,
                   (SUM(TOTAL.VLCMVDEVOLBONIF)) VLCMVDEVOLBONIF,
                   NVL((SUM(TOTAL.STBONIFDEVOL)),0) STBONIFDEVOL,
                   NVL((SUM(TOTAL.VLIPIBONIFDEVOL)),0) VLIPIBONIFDEVOL
            FROM (SELECT DEVOL.CODPROD,
                         DEVOL.CODFILIAL,
                         DEVOL.DTENT,
                         SUM(DEVOL.VLDEVOLUCAO) TOTALDEVOL,
                         SUM(NVL(DEVOL.QT,0) - NVL(DEVOL.QTBONIFIC,0)) QTDEVOLCLI,
                         SUM(NVL(DEVOL.VLCMVDEVOL, 0) + NVL(DEVOL.VLCMVDEVOLBONIF,0)) VLCUSTOFIN,
                         0 TOTALDEVOL2,
                         0 QTDEVOLCLI2,
                         0 VLCUSTOFIN2,
                         SUM(NVL(DEVOL.VLST,0)) VLST,
                         SUM(NVL(DEVOL.VLIPI,0)) VLIPI,
                         SUM(NVL(DEVOL.VLREPASSE,0)) VLREPASSE,
                         SUM(NVL(DEVOL.VLCMVDEVOLBONIF, 0)) VLCMVDEVOLBONIF,
                         SUM(NVL(DEVOL.ICMSRETIDO_BONIF, 0)) STBONIFDEVOL,
                         SUM(NVL(DEVOL.VLIPI_BONIF, 0)) VLIPIBONIFDEVOL
                  FROM VIEW_DEVOL_RESUMO_FATURAMENTO DEVOL
                  WHERE DEVOL.CONDVENDA NOT IN (4, 8, 10, 13, 20, 98, 99)
                  AND DEVOL.DTENT BETWEEN :PDTINICIO AND :PDTTERMINO
                  GROUP BY DEVOL.CODPROD, DEVOL.CODFILIAL, DEVOL.DTENT
                  UNION ALL
                  SELECT DEVOL2.CODPROD,
                         DEVOL2.CODFILIAL,
                         DEVOL2.DTENT,
                         0 TOTALDEVOL,
                         0 QTDEVOLCLI,
                         0 VLCUSTOFIN,
                         SUM(DEVOL2.VLDEVOLUCAO) TOTALDEVOL2,
                         SUM(DEVOL2.QT) QTDEVOLCLI2,
                         SUM(NVL(DEVOL2.VLDEVCMVAVULSAI, 0)) VLCUSTOFIN2,
                         SUM(DEVOL2.VLST) VLST,
                         SUM(DEVOL2.VLIPI) VLIPI,
                         SUM(DEVOL2.VLREPASSE) VLREPASSE,
                         0 VLCMVDEVOLBONIF,
                         0 STBONIFDEVOL,
                         0 VLIPIBONIFDEVOL
                  FROM VIEW_DEVOL_RESUMO_FATURAVULSA DEVOL2
                  WHERE DEVOL2.DTENT BETWEEN :PDTINICIO AND :PDTTERMINO
                  GROUP BY DEVOL2.CODPROD, DEVOL2.CODFILIAL, DEVOL2.DTENT) TOTAL,
                 PCFILIAL
            WHERE PCFILIAL.CODIGO = TOTAL.CODFILIAL
            AND PCFILIAL.CONSOLIDADADOS504 = ''S'' ';

    IF (PLISTACODIGO IS NOT NULL) THEN
      V_SQL := V_SQL || ' AND TOTAL.CODPROD IN ( ' || PLISTACODIGO || ')';
    END IF;

    IF (PCODFILIAL IS NOT NULL) THEN
      V_SQL := V_SQL || ' AND PCFILIAL.CODIGO = ''' || PCODFILIAL || '''';
    END IF;

    V_SQL := V_SQL ||
             ' GROUP BY TOTAL.CODPROD,TOTAL.CODFILIAL,TOTAL.DTENT
                      ORDER BY TOTAL.CODPROD,TOTAL.CODFILIAL';

    OPEN CURSOR_MOVIMENTACAO FOR V_SQL
      USING PDTINICIO, PDTTERMINO, PDTINICIO, PDTTERMINO;
    LOOP
      FETCH CURSOR_MOVIMENTACAO
        INTO ITENS_DEVOLUCAO_MERCADORIA;
      EXIT WHEN CURSOR_MOVIMENTACAO%NOTFOUND;

      BEGIN
        UPDATE PCDTPROD
        SET QTDEVOLCLI                  = NVL(QTDEVOLCLI ,0) + ITENS_DEVOLUCAO_MERCADORIA.QTDEVOLCLI,
            VLDEVOLCLI                  = NVL(VLDEVOLCLI ,0) + ITENS_DEVOLUCAO_MERCADORIA.VLDEVOLCLI,
            VLCUSTOFINDEVOLCLI          = NVL(VLCUSTOFINDEVOLCLI,0) + ITENS_DEVOLUCAO_MERCADORIA.VLCUSTOFINDEVOLCLI,
            STDEVOLUCAO                 = NVL(STDEVOLUCAO ,0) + ITENS_DEVOLUCAO_MERCADORIA.STDEVOLUCAO,
            PCDTPROD.VLIPIDEVOLUCAO     = NVL(PCDTPROD.VLIPIDEVOLUCAO ,0) + ITENS_DEVOLUCAO_MERCADORIA.VLIPIDEVOLUCAO,
            PCDTPROD.VLREPASSEDEVOLUCAO = NVL(PCDTPROD.VLREPASSEDEVOLUCAO ,0) + ITENS_DEVOLUCAO_MERCADORIA.VLREPASSEDEVOLUCAO,
            PCDTPROD.VLCUSTOFINDEVBONIF = NVL(PCDTPROD.VLCUSTOFINDEVBONIF, 0) + ITENS_DEVOLUCAO_MERCADORIA.VLCMVDEVOLBONIF,
            PCDTPROD.STBONIFDEVOL        = NVL(PCDTPROD.STBONIFDEVOL, 0) + ITENS_DEVOLUCAO_MERCADORIA.STBONIFDEVOL,
            PCDTPROD.VLIPIBONIFDEVOL    = NVL(PCDTPROD.VLIPIBONIFDEVOL, 0) + ITENS_DEVOLUCAO_MERCADORIA.VLIPIBONIFDEVOL
        WHERE PCDTPROD.CODPROD = ITENS_DEVOLUCAO_MERCADORIA.CODPROD
        AND PCDTPROD.CODFILIAL     = ITENS_DEVOLUCAO_MERCADORIA.CODFILIAL
        AND PCDTPROD.DTMOV           = ITENS_DEVOLUCAO_MERCADORIA.DTMOV;

        IF SQL%ROWCOUNT = 0 THEN
          SELECT CODEPTO, CODSEC, CODFORNEC, CLASSE, CODPRODPRINC
          INTO VNCODEPTO, VNCODSEC, VNCODFORNEC, VSCLASSE, VNCODPRODPRINC
          FROM PCPRODUT
          WHERE PCPRODUT.CODPROD = ITENS_DEVOLUCAO_MERCADORIA.CODPROD;

          INSERT INTO PCDTPROD
            (CODFILIAL,
             CODPROD,
             DTMOV,
             CODEPTO,
             CODFORNEC,
             VLVENDA,
             VLCUSTOFIN,
             VLCUSTOREAL,
             VLCUSTOREP,
             VLCUSTOCONT,
             QTVENDA,
             QTNOTA,
             VLENT,
             QTENT,
             QTDEVOLCLI,
             VLDEVOLCLI,
             VLCUSTOFINDEVOLCLI,
             CODPRODPRINC,
             CLASSE,
             CODSEC,
             QTESTGER,
             CUSTOFIN,
             CUSTOREAL,
             CUSTOREP,
             CUSTOCONT,
             QTPERDA,
             STDEVOLUCAO,
             VLIPIDEVOLUCAO,
             VLREPASSEDEVOLUCAO,
             VLCUSTOFINDEVBONIF,
             STBONIFDEVOL,
             VLIPIBONIFDEVOL)
          VALUES
            (ITENS_DEVOLUCAO_MERCADORIA.CODFILIAL,
             ITENS_DEVOLUCAO_MERCADORIA.CODPROD,
             ITENS_DEVOLUCAO_MERCADORIA.DTMOV,
             VNCODEPTO,
             VNCODFORNEC,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             ITENS_DEVOLUCAO_MERCADORIA.QTDEVOLCLI,
             ITENS_DEVOLUCAO_MERCADORIA.VLDEVOLCLI,
             ITENS_DEVOLUCAO_MERCADORIA.VLCUSTOFINDEVOLCLI,
             VNCODPRODPRINC,
             VSCLASSE,
             VNCODSEC,
             0,
             0,
             0,
             0,
             0,
             0,
             ITENS_DEVOLUCAO_MERCADORIA.STDEVOLUCAO,
             ITENS_DEVOLUCAO_MERCADORIA.VLIPIDEVOLUCAO,
             ITENS_DEVOLUCAO_MERCADORIA.VLREPASSEDEVOLUCAO,
             ITENS_DEVOLUCAO_MERCADORIA.VLCMVDEVOLBONIF,
             ITENS_DEVOLUCAO_MERCADORIA.STBONIFDEVOL,
             ITENS_DEVOLUCAO_MERCADORIA.VLIPIBONIFDEVOL);
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;

      VQTDECOMMIT := VQTDECOMMIT + 1;

      IF VQTDECOMMIT > 1000 THEN
        COMMIT;
        VQTDECOMMIT := 0;
      END IF;
    END LOOP;
    ---------------------------------------------------------------------------------------------

    COMMIT;

    BEGIN
    SELECT PCPARAMFILIAL.VALOR
      INTO VPARAMCODCLIPC
      FROM PCPARAMFILIAL
     WHERE PCPARAMFILIAL.NOME = 'CODCLIPC';
    EXCEPTION
        WHEN OTHERS THEN
          VPARAMCODCLIPC := 0;
    END;


    IF VPARAMCODCLIPC = 3630  THEN
      IF PCODFILIAL IS NOT NULL THEN

      FOR DADOS IN (SELECT DISTINCT R.NUMTRANSVENDA, R.DTRECALCULO, R.TIPOREGISTRO
                      FROM PCRECALCULOPROD R
                     WHERE R.DTRECALCULO >= TRUNC(SYSDATE-7)
                       AND R.ATUALIZADO507 = 'N'
                       AND R.NUMTRANSVENDA > 0) LOOP

        P_RECALCULA_PCDTPROD_PORNOTA(DADOS.NUMTRANSVENDA,
                                     DADOS.DTRECALCULO,
                                     DADOS.TIPOREGISTRO);

      END LOOP;

      ELSE

        UPDATE PCRECALCULOPROD R
           SET R.ATUALIZADO507 = 'S'
         WHERE R.DTRECALCULO BETWEEN PDTINICIO AND PDTTERMINO;

      END IF;

    END IF;

    -- Gera log da execucao da consolidacao
    GRAVALOGJOB('CONSOLIDACAODADOS',
                VFUNCAO,
                'FC',
                SYSDATE,
                'FINAL CONSOLIDACAO',
                TO_CHAR(PDTINICIO, 'DD/MM/YYYY') || ' / ' ||
                TO_CHAR(PDTTERMINO, 'DD/MM/YYYY') || ' / ' || POPCAO||
                ' / ' || PCODFILIAL);
    -- Fim Gravacao do Estoque
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      VFUNCAO   := 'PRODUTOS';
      PMENSAGEM := SUBSTR(SQLERRM, 1, 500);
      INSERT INTO PCLOGERRO
        (MODULO, FUNCAO, DATA_ERRO, DS_ERRO)
      VALUES
        ('CONSOLIDACAODADOS', VFUNCAO, SYSDATE, PMENSAGEM);
      COMMIT;
  END;

PROCEDURE P_PC_BLOQUEIOCLIENTEPORCODIGO(PCODCLI NUMBER,
                                                                                     PVC2MENSSAGEN OUT VARCHAR2,
                                                                                     PUSUARIO IN VARCHAR2 DEFAULT '')
IS
BEGIN
   P_PC_BLOQUEARCLIENTE(CASE
                            WHEN PCODCLI = 0 THEN -1
                            ELSE PCODCLI
                        END,
                        PVC2MENSSAGEN,
                        PUSUARIO);
END P_PC_BLOQUEIOCLIENTEPORCODIGO;

PROCEDURE P_PC_BLOQUEARCLIENTE(PCODCLI       IN NUMBER
                              ,PVC2MENSSAGEN OUT VARCHAR2
                              ,PUSUARIO IN VARCHAR2 DEFAULT '') IS

  /*Parametros 132*/
  VNUMDIASCLIATRASO        NUMBER := 0;
  VS_ZERALIMCREDAUTOMATICO PCCONSUM.ZERALIMCREDBLOQAUTOMATIC%TYPE;
  VMUDACOBCLIENTE          PCCONSUM.MUDACOBCLIENTE%TYPE;
  VMUDACOBCLIENTEDIAS      PCCONSUM.MUDACOBCLIENTEDIAS%TYPE;
  VBLOQCLIENTEEXCDEVOL     PCCONSUM.BLOQCLIENTEEXCDEVOL%TYPE;
  VPERCEXCESSODEVOL        PCCONSUM.PERCEXCESSODEVOL%TYPE;
  VDIASANALISEDEVOL        PCCONSUM.DIASANALISEDEVOL%TYPE;
  VBLOQCODCLIPRINC         PCCONSUM.BLOQCODCLIPRINC%TYPE;
  VBLOQDESBLOQCLIFORNEC    VARCHAR2(1);
  VLIMCREDINICIALPF        PCCONSUM.LIMCREDINICIALPF%type;
  VLIMCREDINICIAL          PCCONSUM.LIMCREDINICIAL%type;
  VCODPLPAGINICIAL         PCCONSUM.CODPLPAGINICIAL%type;
  VCODCOBINICIAL           PCCONSUM.CODCOBINICIAL%type;
  VNUMDIASDESBLOQCHD1      PCCONSUM.NUMDIASDESBLOQCHD1%type;
  VBLOQTODOSCLIREDE        VARCHAR2(1);


  /*Variaveis locais*/
  VVLVENDA                 NUMBER := 0;
  VVLDEVOLUCAO             NUMBER := 0;
  QTDIAS                   NUMBER := 0;
  VATUALIZAR               BOOLEAN;
  VICLIENTECOMATRASO       NUMBER := 0;
  VBLOQUEIO                VARCHAR2(1);
  VSCRIPT                  VARCHAR(10000);
  VSCRIPT_C                VARCHAR(10000);
  VCONTROLEMOTIVO          NUMBER;
  V_MOTIVOBLOQUEIO         CLOB;
/*
1 - Desbloqueio SEFAZ
2 - BLOQ. AUTOMATICO TIT. ATRASADOS
3 - BLOQ. AUTOMATICO DEVOLUCAO
4 - BLOQ. AUTOMATICO DEFINITIVO
*/
BEGIN
  /*Parametro PCODCLI = -1 a procedure interpreta que e para processar todos os clientes*/
  /*Carregando Parâmetros 132*/
  VS_ZERALIMCREDAUTOMATICO := NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CON_ZERALIMCREDBLOQAUTOMATIC'), 'N');
  VBLOQDESBLOQCLIFORNEC    := NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('BLOQDESBLOQCLIFORNEC'), 'N');
  VBLOQCLIENTEEXCDEVOL     := NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CON_BLOQCLIENTEEXCDEVOL'), 'N');
  VPERCEXCESSODEVOL        := NVL(PARAMFILIAL.OBTERCOMONUMBER('CON_PERCEXCESSODEVOL'), 0);
  VDIASANALISEDEVOL        := NVL(PARAMFILIAL.OBTERCOMONUMBER('CON_DIASANALISEDEVOL'), 9999);
  VBLOQCODCLIPRINC         := NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('COM_BLOQCODCLIPRINC'), 'N');
  VNUMDIASCLIATRASO        := NVL(PARAMFILIAL.OBTERCOMONUMBER('NUMDIASCLIATRASO'), 0);
  VMUDACOBCLIENTE          := NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CON_MUDACOBCLIENTE'), 'N');
  VMUDACOBCLIENTEDIAS      := NVL(PARAMFILIAL.OBTERCOMONUMBER('CON_MUDACOBCLIENTEDIAS'), 0);
  VLIMCREDINICIALPF        := NVL(PARAMFILIAL.OBTERCOMONUMBER('CON_LIMCREDINICIALPF'), 0);
  VLIMCREDINICIAL          := NVL(PARAMFILIAL.OBTERCOMONUMBER('CON_LIMCREDINICIAL'), 0);
  VCODPLPAGINICIAL         := NVL(PARAMFILIAL.OBTERCOMONUMBER('CON_CODPLPAGINICIAL'), 0);
  VCODCOBINICIAL           := NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('CON_CODCOBINICIAL'), '');
  VNUMDIASDESBLOQCHD1      := NVL(PARAMFILIAL.OBTERCOMONUMBER('CON_NUMDIASDESBLOQCHD1'), 0);
  VBLOQTODOSCLIREDE        := NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('BLOQTODOSCLIREDE'), 'N');

  IF PCODCLI IS NOT NULL THEN
    /*Validando Bloqueio SEFAZ*/
    FOR REGISTRO IN (SELECT PCCLIENT.CODCLI
                           ,NVL(PCCLIENT.BLOQUEIOSEFAZPED,'N') BLOQUEIOSEFAZPED
                           ,PCCLIENT.OBS
                           ,NVL(PCCLIENT.BLOQUEIO, 'N') BLOQUEIO
                           ,DECODE(NVL(PCCLIENT.CODCLIPRINC, 0), 0, PCCLIENT.CODCLI, PCCLIENT.CODCLIPRINC) CODCLIPRINC
                           /*Armazenando Limite de Crédito Atual*/
                           , NVL(PCCLIENT.BLOQUEIOSEFAZPED,'N') BLOQUEIOSEFAZPEDANT
                           , PCCLIENT.LIMCRED VLIMCREDANT
                           , PCCLIENT.BLOQUEIO VBLOQUEIOANT
                           , PCCLIENT.DTREGLIM VDTREGLIMANT
                           , PCCLIENT.DTVENCLIMCRED VDTVENCLIMANT
                           , SUBSTR(PCCLIENT.OBS, 1, 20) VOBSANT
                           , PCCLIENT.PRAZOADICIONAL VPRAZOANT
                           , CODCOB VCODCOBANT
                           , PCCLIENT.CODPLPAG VCODPLPAGANT
                           , PCCLIENT.DTBLOQ
                       FROM PCCLIENT
                           ,PCCONSUM
                      WHERE /*Desconsiderar cliente com bloqueio definitivo para o processo */
                            NVL(PCCLIENT.BLOQUEIODEFINITIVO, 'N') = 'N'
                            /*Deconsiderar cliente 1 para o processo*/
                        AND PCCLIENT.CODCLI <> 1
                           /*De acordo com o parametro exibir clientes que tem vinculo com fornecedores*/
                        AND (
                             (VBLOQDESBLOQCLIFORNEC = 'S') OR
                             (NOT EXISTS (SELECT 1
                                            FROM PCFORNEC
                                           WHERE PCFORNEC.CODCLI = PCCLIENT.CODCLI
                                             AND PCFORNEC.REVENDA = 'S'))
                             )
                           /*O valor que e assumido para todos os clientes = -1*/
                        AND PCODCLI IN (-1, PCCLIENT.CODCLI)
                      )
     LOOP
       /*Armazenando variavel de Bloqueio*/
       VBLOQUEIO := REGISTRO.BLOQUEIO;

       /*Verificando se o cleinte possui títulos em atraso*/
       VICLIENTECOMATRASO := SYS.DIUTIL.BOOL_TO_INT(F_PCPREST_VENCIDA_BLOQUEIO(REGISTRO.CODCLI));

       /*So Passa pelo processo de desbloqueio caso o cleinte esteja bloqueado*/
       IF (VBLOQUEIO = 'S') THEN
         /*Iniciando variavel de controloe*/
         VATUALIZAR := FALSE;

         /*Debloqueia cliente com bloqueio sefaz*/
         IF (REGISTRO.BLOQUEIOSEFAZPED = 'N') AND
            (TRIM(REGISTRO.OBS) = 'BLOQ. SEFAZ') THEN
           VATUALIZAR      := TRUE;
           VCONTROLEMOTIVO := 1;
           V_MOTIVOBLOQUEIO := 'Desbloqueia o cliente que teve o CNPJ desbloqueado no Sefaz e atualizado na rotina 1075.';
         END IF;

         /*Debloqueia clientes com bloqueio por títulos atrasados*/
         IF (VICLIENTECOMATRASO = 0) THEN
           IF (TRIM(REGISTRO.OBS) IN ('BLOQ. AUTOMATICO', 'BLOQ. AUTOMATICO TIT. ATRASADOS', 'BLOQ. AUTOMATICO TIT. VENCIDOS')) THEN
              VATUALIZAR      := TRUE;
              VCONTROLEMOTIVO := 2;
              V_MOTIVOBLOQUEIO := 'Cliente estava bloqueado por possui títulos em atraso, devido a esses títulos terem sido quitados, até o dia ' || SYSDATE || ', foi desbloqueado pela atualização diária(504/820).';
           ELSIF (TRIM(REGISTRO.OBS) IN ('BLOQ.CHD1','BLOQ.CHD3', 'BLQ. CHEQUES DEVOLVIDOS')) AND ((TRUNC(SYSDATE) - TRUNC(REGISTRO.DTBLOQ) > VNUMDIASDESBLOQCHD1)) THEN
              VATUALIZAR      := TRUE;
              VCONTROLEMOTIVO := 2;
              V_MOTIVOBLOQUEIO := 'Cliente estava bloqueado por ter títulos nas cobranças CHD1/CHD3 atrasados, como no dia ' || SYSDATE || ' não existia mais nenhum título em atraso (conforme parâmetro 2190) a rotina(504/820) fez o desbloqueio automático';
           END IF;
         END IF;

         /*Desbloqueando os clientes */
         IF VATUALIZAR THEN
           UPDATE PCCLIENT
              SET BLOQUEIO      = 'N'
                 ,DTBLOQ        = NULL
                 ,OBS           = NULL
                 ,BLOQUEIOSEFAZ = 'N'
                 ,MOTIVOBLOQ    = V_MOTIVOBLOQUEIO
            WHERE CODCLI = REGISTRO.CODCLI;

           VBLOQUEIO := 'N';

           P_PC_GRAVARLOGBLOQAUTOM( TO_CHAR(REGISTRO.CODCLI)
                                  , PUSUARIO
                                  , '504'
                                  , CASE WHEN VCONTROLEMOTIVO = 1 THEN 'BLOQ. SEFAZ'
                                         WHEN VCONTROLEMOTIVO = 2 THEN 'BLOQ. AUTOMATICO TIT. ATRASADOS'
                                    END
                                  , REGISTRO.VLIMCREDANT
                                  , REGISTRO.VBLOQUEIOANT
                                  , REGISTRO.VDTREGLIMANT
                                  , REGISTRO.VDTVENCLIMANT
                                  , REGISTRO.VOBSANT
                                  , REGISTRO.VPRAZOANT
                                  , REGISTRO.VCODCOBANT
                                  , REGISTRO.VCODPLPAGANT
                                  );
         END IF;
       /*Fim IF (REGISTRO.BLOQUEIO = 'S') THEN */
       END IF;


       /*Iniciando variavel de controle*/
       VATUALIZAR := FALSE;
       VSCRIPT    := '';
       VSCRIPT_C  := '';

       /*Bloqueio definitivo*/
       IF (VICLIENTECOMATRASO = 1) AND (NVL(VNUMDIASCLIATRASO, 0) > 0) THEN
         SELECT MAX(TRUNC(SYSDATE) - (CASE
                                     WHEN TO_CHAR(PCPREST.DTVENC, 'D') = 1 THEN
                                    PCPREST.DTVENC + 1
                                   WHEN TO_CHAR(PCPREST.DTVENC, 'D') = 7 THEN
                                    PCPREST.DTVENC + 2
                                   ELSE
                                    PCPREST.DTVENC
                                 END))
           INTO QTDIAS
           FROM PCPREST
               ,PCCOB
          WHERE PCPREST.CODCLI = REGISTRO.CODCLI
            AND PCPREST.DTPAG IS NULL
            AND PCCOB.CODCOB = PCPREST.CODCOB
            AND PCCOB.BLOQAUTOMATICO = 'S'
            AND F_QTDIASVENCIDOS(PCPREST.DTVENC,
                                 TRUNC(SYSDATE),
                                 PCPREST.CODCOB,
                                 PCPREST.CODFILIAL,
                                 PARAMFILIAL.OBTERCOMOVARCHAR2('FIL_USADIAUTILFILIAL', PCPREST.CODFILIAL)
                                 ) >= DECODE(NVL(PCCOB.NUMDIASBLOQAUTOMATIC, 0),
                                             0,
                                             1,
                                             PCCOB.NUMDIASBLOQAUTOMATIC);

         IF (QTDIAS >= VNUMDIASCLIATRASO) THEN
           VATUALIZAR      := TRUE;
           VSCRIPT_C       := '     , OBS      = ''BLOQ. AUTOMATICO DEFINITIVO'''||
                              '     , BLOQUEIODEFINITIVO = ''S''';
           VCONTROLEMOTIVO := 4;
           V_MOTIVOBLOQUEIO := ' Cliente bloqueado definitivo, pois existia pelo menos um título em atraso,
                                ou seja a data de vencimento somado ao parâmetro 2469(rotina 132) era maior que data do
                                processamento da 504/820(Data do processamento' || SYSDATE || ').';
           /*Zera Limite Crédito*/
           IF (VS_ZERALIMCREDAUTOMATICO = 'S') THEN
             VSCRIPT_C := VSCRIPT_C || '     , LIMCRED = 0';
           END IF;
           /*Volta Limite Crédito Inicial*/
           IF (VS_ZERALIMCREDAUTOMATICO = 'I') THEN
             VSCRIPT_C := VSCRIPT_C || '     , LIMCRED = DECODE (TIPOFJ, ''F'', '|| VLIMCREDINICIALPF || ', '|| VLIMCREDINICIAL || ')';
           END IF;
         END IF;

       /*Fim IF NVL(VNUMDIASCLIATRASO, 0) > 0 THEN */
       END IF;

       /*Inicio processo de bloqueio de cliente*/
       IF VBLOQUEIO = 'N' THEN

         /*Bloqueando cleinte por atraso*/
         IF NOT VATUALIZAR AND (VICLIENTECOMATRASO = 1) THEN
           VATUALIZAR      := TRUE;
           VSCRIPT_C       := '     , OBS = ''BLOQ. AUTOMATICO TIT. ATRASADOS''';
           VCONTROLEMOTIVO := 2;
           V_MOTIVOBLOQUEIO := ' Cliente bloqueado, pois existia pelo menos um título em atraso, ou seja a
                                data de vencimento era maior que data do processamento da 504/820(Data do processamento ' || SYSDATE ||').';

           /*Zera Limite Crédito*/
           IF (VS_ZERALIMCREDAUTOMATICO = 'S') THEN
             VSCRIPT_C := VSCRIPT_C || '     , LIMCRED = 0';
           END IF;
           /*Volta Limite Crédito Inicial*/
           IF (VS_ZERALIMCREDAUTOMATICO = 'I') THEN
             VSCRIPT_C := VSCRIPT_C || '     , LIMCRED = DECODE (TIPOFJ, ''F'', '|| VLIMCREDINICIALPF || ', '|| VLIMCREDINICIAL || ')';
           END IF;
         END IF;

         /*Bloquear cliente SEFAZ*/
         IF NOT VATUALIZAR AND (REGISTRO.BLOQUEIOSEFAZPED = 'S') THEN
           VATUALIZAR := TRUE;
           VSCRIPT_C  := '     , OBS = ''BLOQ. SEFAZ'''||
                         '     , BLOQUEIOSEFAZ = ''S''';
           VCONTROLEMOTIVO := 1;
           V_MOTIVOBLOQUEIO := 'Cliente foi bloqueado pelo Sefaz na rotina 1075, portanto a 504/820 no dia ' || SYSDATE || ' fez o bloqueio normal.';
         END IF;

         /*Bloqueio de cliente por execesso de devolução*/
         IF NOT VATUALIZAR AND (VBLOQCLIENTEEXCDEVOL = 'S') AND (VPERCEXCESSODEVOL > 0) THEN

           /*Obtendo o valor da venda para realizar proporção*/
           SELECT NVL(SUM(NVL(PCNFSAID.VLTOTGER, 0)), 0)
             INTO VVLVENDA
             FROM PCNFSAID
                 ,PCPEDC
            WHERE PCNFSAID.DTCANCEL IS NULL
              AND PCNFSAID.CONDVENDA NOT IN (2, 3, 6, 12)
              AND FLOOR(TRUNC(SYSDATE) - TRUNC(PCNFSAID.DTSAIDA)) <= VDIASANALISEDEVOL
              AND PCPEDC.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA
              AND PCPEDC.NUMPED = PCNFSAID.NUMPED
              AND PCNFSAID.CODCLI = REGISTRO.CODCLI;

           /*So Executar estre trecho se o anterior retorna valor ja que sempre tem que ter venda*/
           IF VVLVENDA > 0 THEN
             /*Obtendo o valor de Devoluções para realizar proporção*/
             SELECT NVL(SUM(NVL(PCESTCOM.VLDEVOLUCAO, 0)), 0)
               INTO VVLDEVOLUCAO
               FROM PCNFENT
                   ,PCESTCOM
                   ,PCNFSAID
              WHERE PCNFSAID.CODCLI = REGISTRO.CODCLI
                AND NVL(PCESTCOM.NUMTRANSVENDA, 0) <> 0
                AND PCNFENT.TIPODESCARGA IN ('6', '7')
                AND NVL(PCNFENT.OBS, 'X') <> 'NF CANCELADA'
                AND FLOOR(TRUNC(SYSDATE) - TRUNC(PCNFENT.DTENT)) <= VDIASANALISEDEVOL
                AND PCNFENT.CODDEVOL IN (SELECT CODDEVOL
                                           FROM PCTABDEV
                                          WHERE NVL(PCTABDEV.BLOQUEIACLIENTE, 'N') = 'S')
                AND PCNFENT.NUMTRANSENT = PCESTCOM.NUMTRANSENT
                AND PCESTCOM.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA;
           END IF;

           /*Realizando calculo da proporção de devolução*/
           IF (VVLDEVOLUCAO > 0) AND (VVLVENDA > 0) AND
              (((100 * VVLDEVOLUCAO) / VVLVENDA) >= VPERCEXCESSODEVOL) THEN
             VATUALIZAR := TRUE;
             VSCRIPT_C  := '     , OBS      = ''BLOQ. AUTOMATICO DEVOLUCAO''';
             VCONTROLEMOTIVO := 3;
             V_MOTIVOBLOQUEIO := ' Cliente foi bloqueado devido ao parâmetro, 2301 - Bloquear cliente com excesso de devoluções,
                                  está marcado como "Sim" e o percentual máximo de devolução sobre a venda, parâmetro
                                  2302 - % sobre as vendas que determina o bloqueio do cliente, ter sido ultrapassado, nos '||VDIASANALISEDEVOL||' dias
                                  definidos para analise, parâmetro 2303 - Dias para analisar as vendas e devoluções ';
           END IF;

         /*Fim IF NOT VATUALIZAR AND (VBLOQCLIENTEEXCDEVOL = 'S') THEN */
         END IF;

       /*Fim IF vbloqueio = 'N' THEN*/
       END IF;

       /*Atualizando Clientes*/
       IF VATUALIZAR THEN
         VSCRIPT := 'UPDATE PCCLIENT'                      ||
                    '   SET DTBLOQ   = TRUNC(SYSDATE)'     ||
                    '     , BLOQUEIO = ''S''        '      ||
                    VSCRIPT_C                              ||
                    '     , MOTIVOBLOQ = ''' || V_MOTIVOBLOQUEIO ||
                    ''' WHERE CODCLI = :CODCLI '             ||
                    '   AND NVL(BLOQUEIODEFINITIVO, ''N'') = ''N''';

         EXECUTE IMMEDIATE VSCRIPT
                     USING REGISTRO.CODCLI;

         /*Gravando Log de Bloqueio acordo com a variavel de controle obtem porque o bloqueio foi realizado*/
         P_PC_GRAVARLOGBLOQAUTOM( TO_CHAR(REGISTRO.CODCLI), PUSUARIO
                                , '504'
                                , CASE WHEN VCONTROLEMOTIVO = 1 THEN 'BLOQ. SEFAZ'
                                       WHEN VCONTROLEMOTIVO = 2 THEN 'BLOQ. AUTOMATICO TIT. ATRASADOS'
                                       WHEN VCONTROLEMOTIVO = 3 THEN 'BLOQ. AUTOMATICO DEVOLUCAO'
                                       WHEN VCONTROLEMOTIVO = 4 THEN 'BLOQ. AUTOMATICO DEFINITIVO'
                                  END
                                , REGISTRO.VLIMCREDANT
                                , REGISTRO.VBLOQUEIOANT
                                , REGISTRO.VDTREGLIMANT
                                , REGISTRO.VDTVENCLIMANT
                                , REGISTRO.VOBSANT
                                , REGISTRO.VPRAZOANT
                                , REGISTRO.VCODCOBANT
                                , REGISTRO.VCODPLPAGANT
                                );
       END IF;

    /*Fim Processo de Loop*/
    END LOOP;

    IF (VBLOQCODCLIPRINC = 'S') THEN
    /*Bloqueando clientes da Familia*/
        FOR REGISTRO IN (SELECT PCCLIENT.CODCLI
                               ,NVL(PCCLIENT.BLOQUEIOSEFAZPED,'N') BLOQUEIOSEFAZPED
                               ,PCCLIENT.OBS
                               ,PCCLIENT.LIMCRED
                               ,NVL(PCCLIENT.BLOQUEIO, 'N') BLOQUEIO
                               ,NVL(PCCLIENT.BLOQUEIODEFINITIVO, 'N') BLOQUEIODEFINITIVO
                               ,DECODE(NVL(PCCLIENT.CODCLIPRINC, 0), 0, PCCLIENT.CODCLI, PCCLIENT.CODCLIPRINC) CODCLIPRINC
                           FROM PCCLIENT
                               ,PCCONSUM
                          WHERE /*Deconsiderar cliente 1 para o processo*/
                               PCCLIENT.CODCLI <> 1
                                /*De acordo com o parametro exibir clientes que tem vinculo com fornecedores*/
                           AND PCCLIENT.BLOQUEIOSEFAZ = 'N'
                           AND (
                                    (VBLOQDESBLOQCLIFORNEC = 'S') OR
                                    (NOT EXISTS (SELECT 1
                                                   FROM PCFORNEC
                                                  WHERE PCFORNEC.CODCLI = PCCLIENT.CODCLI
                                                    AND PCFORNEC.REVENDA = 'S'))
                                   )
                           /*Buscar todos os clientes principais*/
                           AND EXISTS (SELECT 1
                                             FROM PCCLIENT CF
                                            WHERE CF.CODCLIPRINC = PCCLIENT.CODCLI
                                              AND CF.CODCLI <> PCCLIENT.CODCLI
                               )
                           /*Não replicar bloqueio por inatividade*/
                           AND (PCCLIENT.OBS IS NULL OR PCCLIENT.OBS NOT LIKE 'BLOQ. AUT. POR % DIAS INATIVO')
                      )
     LOOP
       IF (REGISTRO.BLOQUEIO = 'S') THEN
           V_MOTIVOBLOQUEIO := ' Cliente foi bloqueado pois o parâmetro 2845 - Bloquear clientes vinculados ao cliente principal, estava marcado como "Sim",
                                com isso como o cliente principal(código :'||REGISTRO.CODCLI||') foi bloqueado por, ' || REGISTRO.OBS || ', portanto todos os vinculados foram bloqueados. ';
           VSCRIPT := 'UPDATE PCCLIENT                                ' ||
                      '   SET DTBLOQ   = TRUNC(SYSDATE)               ' ||
                      '     , BLOQUEIO = ''S''                        ' ||
                      '     , MOTIVOBLOQ = '''|| V_MOTIVOBLOQUEIO||
                      '''     , OBS = ''' || REGISTRO.OBS || '''        ';

           IF (REGISTRO.BLOQUEIODEFINITIVO = 'S') THEN
             VSCRIPT := VSCRIPT || '     , BLOQUEIODEFINITIVO = ''S'' ';
           END IF;

           IF (REGISTRO.BLOQUEIOSEFAZPED = 'S') THEN
             VSCRIPT := VSCRIPT || '     , BLOQUEIOSEFAZ = ''S'' ';
           END IF;

           /*Zera Limite Crédito*/
           IF (VS_ZERALIMCREDAUTOMATICO = 'S') THEN
             VSCRIPT := VSCRIPT || '     , LIMCRED = 0';
           END IF;
           /*Volta Limite Crédito Inicial*/
           IF (VS_ZERALIMCREDAUTOMATICO = 'I') THEN
             VSCRIPT := VSCRIPT || '     , LIMCRED = DECODE (TIPOFJ, ''F'', '|| VLIMCREDINICIALPF || ', '|| VLIMCREDINICIAL || ')';
           END IF;

           VSCRIPT := VSCRIPT ||
                      ' WHERE CODCLI = :CODCLI                      ' ||
                      '   AND NVL(BLOQUEIODEFINITIVO, ''N'') = ''N''';

         /*Faz loop para gravar log para os clientes da família*/
         FOR FAMILIA IN (SELECT PCCLIENT.CODCLI
                               ,NVL(PCCLIENT.BLOQUEIOSEFAZPED,'N') BLOQUEIOSEFAZPED
                               ,PCCLIENT.OBS
                               ,NVL(PCCLIENT.BLOQUEIO, 'N') BLOQUEIO
                               ,DECODE(NVL(PCCLIENT.CODCLIPRINC, 0), 0, PCCLIENT.CODCLI, PCCLIENT.CODCLIPRINC) CODCLIPRINC
                               /*Armazenando Limite de Crédito Atual*/
                               , NVL(PCCLIENT.BLOQUEIOSEFAZPED,'N') BLOQUEIOSEFAZPEDANT
                               , PCCLIENT.LIMCRED VLIMCREDANT
                               , PCCLIENT.BLOQUEIO VBLOQUEIOANT
                               , PCCLIENT.DTREGLIM VDTREGLIMANT
                               , PCCLIENT.DTVENCLIMCRED VDTVENCLIMANT
                               , SUBSTR(PCCLIENT.OBS, 1, 20) VOBSANT
                               , PCCLIENT.PRAZOADICIONAL VPRAZOANT
                               , CODCOB VCODCOBANT
                               , PCCLIENT.CODPLPAG VCODPLPAGANT
                           FROM PCCLIENT
                               ,PCCONSUM
                          WHERE /*Deconsiderar cliente 1 para o processo*/
                               PCCLIENT.CODCLI <> 1
                                /*De acordo com o parametro exibir clientes que tem vinculo com fornecedores*/
                               AND (
                                    (VBLOQDESBLOQCLIFORNEC = 'S') OR
                                    (NOT EXISTS (SELECT 1
                                                   FROM PCFORNEC
                                                  WHERE PCFORNEC.CODCLI = PCCLIENT.CODCLI
                                                    AND PCFORNEC.REVENDA = 'S'))
                                   )
                               /*Buscar todos os clientes filhos*/
                               AND PCCLIENT.CODCLIPRINC = REGISTRO.CODCLI
                               AND PCCLIENT.CODCLIPRINC <> PCCLIENT.CODCLI
                      )
         LOOP
           EXECUTE IMMEDIATE VSCRIPT
             USING FAMILIA.CODCLI;

            P_PC_GRAVARLOGBLOQAUTOM( TO_CHAR(FAMILIA.CODCLI)
                                  , PUSUARIO
                                  , '504'
                                  , SUBSTR('BLOQ. AUTOMATICO FAMILIA - REF CODCLIPRINC: ' || REGISTRO.CODCLIPRINC, 1, 60)
                                  , FAMILIA.VLIMCREDANT
                                  , FAMILIA.VBLOQUEIOANT
                                  , FAMILIA.VDTREGLIMANT
                                  , FAMILIA.VDTVENCLIMANT
                                  , FAMILIA.VOBSANT
                                  , FAMILIA.VPRAZOANT
                                  , FAMILIA.VCODCOBANT
                                  , FAMILIA.VCODPLPAGANT
                                  );
         END LOOP; /*Fim do Processo de loop dos clientes vinculados ao cliente principal */
       END IF; /*Fim do processo REGISTRO.BLOQUEIO = 'S' */
     END LOOP;/*Fim Processo de loop Bloqueando clientes da Familia */
     END IF; /*Fim do processo VBLOQCODCLIPRINC = 'S' */


     IF (VBLOQTODOSCLIREDE = 'S') THEN
    /*Bloqueando clientes da Familia*/
        FOR REGISTRO IN (SELECT PCCLIENT.CODCLI
                               ,NVL(PCCLIENT.BLOQUEIOSEFAZPED,'N') BLOQUEIOSEFAZPED
                               ,PCCLIENT.OBS
                               ,PCCLIENT.LIMCRED
                               ,NVL(PCCLIENT.BLOQUEIO, 'N') BLOQUEIO
                               ,NVL(PCCLIENT.BLOQUEIODEFINITIVO, 'N') BLOQUEIODEFINITIVO
                               ,DECODE(NVL(PCCLIENT.CODCLIPRINC, 0), 0, PCCLIENT.CODCLI, PCCLIENT.CODCLIPRINC) CODCLIPRINC
                           FROM PCCLIENT
                               ,PCCONSUM
                          WHERE /*Deconsiderar cliente 1 para o processo*/
                               PCCLIENT.CODCLI <> 1
                                /*De acordo com o parametro exibir clientes que tem vinculo com fornecedores*/
                           AND PCCLIENT.BLOQUEIOSEFAZ = 'N'
                           AND (
                                    (VBLOQDESBLOQCLIFORNEC = 'S') OR
                                    (NOT EXISTS (SELECT 1
                                                   FROM PCFORNEC
                                                  WHERE PCFORNEC.CODCLI = PCCLIENT.CODCLI
                                                    AND PCFORNEC.REVENDA = 'S'))
                                   )
                           /*Verifica se existe REDE pelo Cliente Principal*/
                           AND EXISTS (SELECT 1
                                         FROM PCCLIENT CF
                                        WHERE CF.CODCLIPRINC = DECODE(NVL(PCCLIENT.CODCLIPRINC, 0), 0, PCCLIENT.CODCLI, PCCLIENT.CODCLIPRINC)
                               )
                          /*Não replicar bloqueio por inatividade*/
                          AND (PCCLIENT.OBS IS NULL OR PCCLIENT.OBS NOT LIKE 'BLOQ. AUT. POR % DIAS INATIVO')
                      )
     LOOP
       IF (REGISTRO.BLOQUEIO = 'S') THEN

           VSCRIPT := 'UPDATE PCCLIENT                                ' ||
                      '   SET DTBLOQ   = TRUNC(SYSDATE)               ' ||
                      '     , BLOQUEIO = ''S''                        ' ||
                      '     , OBS = ''' || REGISTRO.OBS || '''        ';

           IF (REGISTRO.BLOQUEIODEFINITIVO = 'S') THEN
             VSCRIPT := VSCRIPT || '     , BLOQUEIODEFINITIVO = ''S'' ';
           END IF;

           IF (REGISTRO.BLOQUEIOSEFAZPED = 'S') THEN
             VSCRIPT := VSCRIPT || '     , BLOQUEIOSEFAZ = ''S'' ';
           END IF;

           /*Zera Limite Crédito*/
           IF (VS_ZERALIMCREDAUTOMATICO = 'S') THEN
             VSCRIPT := VSCRIPT || '     , LIMCRED = 0';
           END IF;
           /*Volta Limite Crédito Inicial*/
           IF (VS_ZERALIMCREDAUTOMATICO = 'I') THEN
             VSCRIPT := VSCRIPT || '     , LIMCRED = DECODE (TIPOFJ, ''F'', '|| VLIMCREDINICIALPF || ', '|| VLIMCREDINICIAL || ')';
           END IF;

           VSCRIPT := VSCRIPT ||
                      ' WHERE CODCLI = :CODCLI                      ' ||
                      '   AND NVL(BLOQUEIODEFINITIVO, ''N'') = ''N''';

         /*Faz loop para gravar log para os clientes da família*/
         FOR FAMILIA IN (SELECT PCCLIENT.CODCLI
                               ,NVL(PCCLIENT.BLOQUEIOSEFAZPED,'N') BLOQUEIOSEFAZPED
                               ,PCCLIENT.OBS
                               ,NVL(PCCLIENT.BLOQUEIO, 'N') BLOQUEIO
                               ,DECODE(NVL(PCCLIENT.CODCLIPRINC, 0), 0, PCCLIENT.CODCLI, PCCLIENT.CODCLIPRINC) CODCLIPRINC
                               /*Armazenando Limite de Crédito Atual*/
                               , NVL(PCCLIENT.BLOQUEIOSEFAZPED,'N') BLOQUEIOSEFAZPEDANT
                               , PCCLIENT.LIMCRED VLIMCREDANT
                               , PCCLIENT.BLOQUEIO VBLOQUEIOANT
                               , PCCLIENT.DTREGLIM VDTREGLIMANT
                               , PCCLIENT.DTVENCLIMCRED VDTVENCLIMANT
                               , SUBSTR(PCCLIENT.OBS, 1, 20) VOBSANT
                               , PCCLIENT.PRAZOADICIONAL VPRAZOANT
                               , CODCOB VCODCOBANT
                               , PCCLIENT.CODPLPAG VCODPLPAGANT
                           FROM PCCLIENT
                               ,PCCONSUM
                          WHERE /*Deconsiderar cliente 1 para o processo*/
                               PCCLIENT.CODCLI <> 1
                                /*De acordo com o parametro exibir clientes que tem vinculo com fornecedores*/
                               AND (
                                    (VBLOQDESBLOQCLIFORNEC = 'S') OR
                                    (NOT EXISTS (SELECT 1
                                                   FROM PCFORNEC
                                                  WHERE PCFORNEC.CODCLI = PCCLIENT.CODCLI
                                                    AND PCFORNEC.REVENDA = 'S'))
                                   )
                               /*Buscar todos os clientes filhos*/
                               AND PCCLIENT.CODCLIPRINC = REGISTRO.CODCLIPRINC
                               AND PCCLIENT.CODCLI <> REGISTRO.CODCLI
                      )
         LOOP
           EXECUTE IMMEDIATE VSCRIPT
             USING FAMILIA.CODCLI;

            P_PC_GRAVARLOGBLOQAUTOM( TO_CHAR(FAMILIA.CODCLI)
                                  , PUSUARIO
                                  , '504'
                                  , SUBSTR('BLOQ. ORIGINADO CLIENTE ' || REGISTRO.CODCLI || ' (CODCLIPRINC=' || REGISTRO.CODCLIPRINC || ')', 1, 60)
                                  , FAMILIA.VLIMCREDANT
                                  , FAMILIA.VBLOQUEIOANT
                                  , FAMILIA.VDTREGLIMANT
                                  , FAMILIA.VDTVENCLIMANT
                                  , FAMILIA.VOBSANT
                                  , FAMILIA.VPRAZOANT
                                  , FAMILIA.VCODCOBANT
                                  , FAMILIA.VCODPLPAGANT
                                  );
         END LOOP; /*Fim do Processo de loop dos clientes vinculados ao cliente principal */
       END IF; /*Fim do processo REGISTRO.BLOQUEIO = 'S' */
     END LOOP;/*Fim Processo de loop Bloqueando clientes da Familia Independente se é ou não o Cliente Principal*/
     END IF; /*Fim do processo VBLOQTODOSCLIREDE = 'S' */


    /*Alterando Cobrança do cliente em atraso*/
    IF (VMUDACOBCLIENTE = 'S') AND (VMUDACOBCLIENTEDIAS > 0) THEN
      /*Faz loop para gerar mensagem, alterar cobrança e gerar log de alteração*/
       FOR CLIENTE IN (SELECT PCCLIENT.CODCLI
                            , PCCLIENT.CLIENTE
                            , PCCLIENT.CODUSUR1
                            , NVL(PCCLIENT.BLOQUEIOSEFAZPED,'N') BLOQUEIOSEFAZPED
                            , PCCLIENT.OBS
                            , NVL(PCCLIENT.BLOQUEIO, 'N') BLOQUEIO
                            , DECODE(NVL(PCCLIENT.CODCLIPRINC, 0), 0, PCCLIENT.CODCLI, PCCLIENT.CODCLIPRINC) CODCLIPRINC
                            /*Armazenando Limite de Crédito Atual*/
                            , NVL(PCCLIENT.BLOQUEIOSEFAZPED,'N') BLOQUEIOSEFAZPEDANT
                            , PCCLIENT.LIMCRED VLIMCREDANT
                            , PCCLIENT.BLOQUEIO VBLOQUEIOANT
                            , PCCLIENT.DTREGLIM VDTREGLIMANT
                            , PCCLIENT.DTVENCLIMCRED VDTVENCLIMANT
                            , SUBSTR(PCCLIENT.OBS, 1, 20) VOBSANT
                            , PCCLIENT.PRAZOADICIONAL VPRAZOANT
                            , CODCOB VCODCOBANT
                            , PCCLIENT.CODPLPAG VCODPLPAGANT
                         FROM PCCLIENT
                        WHERE PCCLIENT.CODCOB = 'BK'
                          AND PCCLIENT.CODUSUR1 IS NOT NULL
                          AND PCCLIENT.CODCLI IN (SELECT CODCLI
                                                    FROM PCPREST
                                                        ,PCCOB
                                                   WHERE DTPAG IS NULL
                                                     AND PCCOB.CODCOB = PCPREST.CODCOB
                                                     AND (TRUNC(SYSDATE) - TRUNC(DTVENC) + NVL(PCCOB.DIASCARENCIA, 0)) > VMUDACOBCLIENTEDIAS)
                        )
      LOOP
        /*Gerando PCMENS*/
        INSERT INTO PCMENS (CODUSUR
                          , DATA
                          , MENS1
                          , MENS2
                          , MENS3
                          , MENS4
                          , ENVIADO)
                    VALUES (
                           CLIENTE.CODUSUR1
                         , TRUNC(SYSDATE)
                         , 'TRANSFERIDO DE BK P/ CH'
                         , SUBSTR(TO_CHAR(CLIENTE.CODCLI) || '-' || CLIENTE.CLIENTE, 1, 60)
                         , ' '
                         , ' '
                         , 'N');

        /*Aplicando Update*/
        UPDATE PCCLIENT
           SET CODCOB = 'CH'
         WHERE CODCOB = 'BK'
           AND CODCLI = CLIENTE.CODCLI;

        P_PC_GRAVARLOGBLOQAUTOM( TO_CHAR(CLIENTE.CODCLI)
                               , PUSUARIO
                               , '504'
                               , 'TRANSFERIDO DE BK P/ CH'
                               , CLIENTE.VLIMCREDANT
                               , CLIENTE.VBLOQUEIOANT
                               , CLIENTE.VDTREGLIMANT
                               , CLIENTE.VDTVENCLIMANT
                               , CLIENTE.VOBSANT
                               , CLIENTE.VPRAZOANT
                               , CLIENTE.VCODCOBANT
                               , CLIENTE.VCODPLPAGANT
                               , 'TRANSFERIDO DE BK P/ CH'
                               );

      /*(FIM) LOOP CLIENTE*/
      END LOOP;
    /*(FIM)  IF VMUDACOBCLIENTE = 'S' THEN*/
    END IF;

    /*Gerando Log de Termino*/
    INSERT INTO PCLOGJOB(MODULO
                        ,FUNCAO
                        ,TIPO_LOG
                        ,DATA_LOG
                        ,DS_JOB)
         VALUES ('BLOQUEARCLIENTES'
                ,'PCCLIENT'
                ,'FI'
                ,SYSDATE
                ,'Final Bloqueia/Desbloqueia Clientes Automaticamente');
    /*Confirmando a Transação*/
    COMMIT;

  /*Fim    IF PCODCLI IS NOT NULL THEN */
  END IF;
END P_PC_BLOQUEARCLIENTE;

PROCEDURE P_PC_GRAVARLOGBLOQAUTOM(PCODCLI IN VARCHAR2,
                                  PUSUARIO IN VARCHAR2,
                                  PROTINA IN VARCHAR2,
                                  POBS1 IN VARCHAR2,
                  PLIMCREDANT IN NUMBER DEFAULT NUll,
                                  PBLOQUEIOANT IN VARCHAR2 DEFAULT NUll,
                                  PDTREGLIMANT IN DATE DEFAULT NUll,
                                  PDTVENCLIMANT IN DATE DEFAULT NUll,
                                  POBSANT IN VARCHAR2 DEFAULT NUll,
                                  PPRAZOANT IN NUMBER DEFAULT NUll,
                                  PCODCOBANT IN VARCHAR2 DEFAULT NUll,
                                  PCODPLPAGANT IN VARCHAR2 DEFAULT NUll,
                                  PDESCRICAO IN VARCHAR2 DEFAULT NULL)
IS

VUSUARIO VARCHAR2(60);
VDESCRICAO VARCHAR2(60);

BEGIN
   /* Description: Procedure criada para gravar o log dos clientes que estão sendo bloqueados
   Date       : 19/02/2014
   Author     : Bruno Lima Martins
   History    : 182510
   Version    : 23
   */

   IF (TRIM(PUSUARIO) = '') OR (PUSUARIO IS NULL) THEN
      VUSUARIO := '0';
   ELSE
      VUSUARIO := PUSUARIO;
   END IF;

   IF (TRIM(PDESCRICAO) = '') OR (PDESCRICAO IS NULL) THEN
      VDESCRICAO := '0';
   ELSE
      VDESCRICAO := PDESCRICAO;
   END IF;

   INSERT INTO PCLOGLC(CODCLI,
      DATA,
      CODEMITE,
      PROGRAMA,
      BLOQUEIO,
      BLOQUEIOANT,
      LIMCRED,
      LIMCREDANT,
      DTREGLIMANT,
      DTVENCLIMCRED,
      DTVENCLIMANT,
      OBS,
      OBSANT,
      PRAZO,
      PRAZOANT,
      CODCOB,
      CODCOBANT,
      OBS1,
      OBS2,
      OBS3,
      OBS4,
      CODPLPAG,
      CODPLPAGANT,
      DTULTCOMP,
      DTULTCOMPANT)
  SELECT PCCLIENT.CODCLI,
         SYSDATE AS DATA,
         TO_NUMBER(VUSUARIO) AS CODEMITE,
         PROTINA AS PROGRAMA,
         BLOQUEIO,
         NVL(PBLOQUEIOANT,DECODE(PCCLIENT.BLOQUEIO, 'N', 'S', 'N')) AS BLOQUEIOANT,
         PCCLIENT.LIMCRED,
         NVL(PLIMCREDANT, NVL(PCCLIENT.LIMCRED,0)) AS LIMCREDANT,
         NVL(PDTREGLIMANT, NVL(PCCLIENT.DTREGLIM, TRUNC(SYSDATE))) AS DTREGLIMANT,
         NVL(PCCLIENT.DTVENCLIMCRED, TRUNC(SYSDATE)) AS DTVENCLIMCRED,
         NVL(PDTVENCLIMANT, NVL(PCCLIENT.DTREGLIM, TRUNC(SYSDATE))) AS DTVENCLIMANT,
         'LOG BLOQ. AUTOMATICO' AS OBS,
         NVL(POBSANT, 'LOG BLOQ. AUTOMATICO') AS OBSANT,
         NVL(PCCLIENT.PRAZOADICIONAL, 1) AS PRAZO,
         NVL(PPRAZOANT, NVL(PCCLIENT.PRAZOADICIONAL, 1)) AS PRAZOANT,
         PCCLIENT.CODCOB,
         NVL(PCODCOBANT, PCCLIENT.CODCOB) AS CODCOBANT,
         POBS1 AS OBS1,
         '' AS OBS2,
         '' AS OBS3,
         '' AS OBS4,
         PCCLIENT.CODPLPAG AS CODPLPAG,
         NVL(PCCLIENT.CODPLPAG, PCODPLPAGANT) AS CODPLPAGANT,
         PCCLIENT.DTULTCOMP,
         PCCLIENT.DTULTCOMP
    FROM PCCLIENT
   WHERE PCCLIENT.CODCLI IN (PCODCLI);

END P_PC_GRAVARLOGBLOQAUTOM;


PROCEDURE GERAR_PCFINANC(PCODFILIAL VARCHAR2, PCODROTINA NUMBER, PCODFUNC NUMBER, PDATAPROCESSADA  DATE) IS
VSALDOCPMANUAL NUMBER(20, 4);
V_COUNT  NUMBER(5);
VCOUNT NUMBER(10);
VDATATESTADA DATE;
BEGIN
  IF PCODROTINA <> 117 THEN  
      BEGIN
        SELECT NVL(COUNT(DISTINCT F.DATA),0), TRUNC(NVL(F.DTGERACAO,SYSDATE))
        INTO VCOUNT, VDATATESTADA
        FROM PCFINANC F
        WHERE F.DTGERACAO >= TRUNC(SYSDATE)
        AND F.CODFILIAL = PCODFILIAL
        GROUP BY TRUNC(NVL(F.DTGERACAO,SYSDATE));
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        VCOUNT := 0;
        VDATATESTADA := SYSDATE;
      END;  
  
    IF VCOUNT > 7 THEN
      raise_application_error(-20001,'Foram gerados registros de '||to_char(VCOUNT)||' dias, apartir da data '||to_char(TRUNC(VDATATESTADA))||'.');
    END IF;
  
  END IF;

  /*Apagando registros gerados pela rotina 117*/
  DELETE PCFINANC
   WHERE PCFINANC.CODFILIAL IN (PCODFILIAL)
    AND PCFINANC.CODROTINA = 117;

  SELECT COUNT(1)
    INTO V_COUNT
    FROM PCFINANC
   WHERE PCFINANC.DATA = PDATAPROCESSADA
     AND PCFINANC.CODFILIAL = PCODFILIAL;

  /*Incluindo registro Zerado*/
  IF V_COUNT <= 0 THEN
    --INSERINDO UMA LINHA PARA O PROCESSO NORMAL
    INSERT INTO PCFINANC( DATA,            CODFILIAL,  SALDOEMPRESTATIVO, SALDOCX, SALDOINVESTATIVO, SALDOCRFOR, SALDOCTRANS, SALDOCP, SALDOEMPRESTPASSIVO, SALDOBCO, SALDOINVESTPASSIVO, SALDOCREDCLI, SALDOVALE, SALDOESTREAL, SALDOCR, CODROTINA,  CODFUNC, DTGERACAO, SALDOESTFIN, SALDOADIANTFOR, LISTAFILIAISBANCOCAIXA, PARMULTIFILIALCAIXABANCO3882)
         VALUES         ( PDATAPROCESSADA, PCODFILIAL, 0,                 0,       0,                0,          0,           0,       0,                   0,        0,                  0,            0,         0,            0,       PCODROTINA, PCODFUNC, SYSDATE,  0,           0, PCODFILIAL, 'N');

    --HIS.02205.2016 - INSERINDO UMA LINHA PARA O NOVO PROCESSO DE BANCOS/CAIXAS COM MULTIPLAS FILIAIS
    INSERT INTO PCFINANC(DATA, CODFILIAL, SALDOEMPRESTATIVO, SALDOCX, SALDOINVESTATIVO, SALDOCRFOR, SALDOCTRANS, SALDOCP, SALDOEMPRESTPASSIVO, SALDOBCO, SALDOINVESTPASSIVO, SALDOCREDCLI, SALDOVALE, SALDOESTREAL, SALDOCR, CODROTINA,  CODFUNC, DTGERACAO, SALDOESTFIN, SALDOADIANTFOR, LISTAFILIAISBANCOCAIXA, PARMULTIFILIALCAIXABANCO3882)
    SELECT DISTINCT DATA, CODFILIAL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, PCODROTINA, PCODFUNC, SYSDATE, 0, 0, NVL(LISTAFILIAISBANCOCAIXA,CODFILIAL), 'S'
    FROM PCFINANC2
    WHERE PCFINANC2.DATA    = PDATAPROCESSADA
    AND PCFINANC2.CODFILIAL = PCODFILIAL
    AND NVL(PCFINANC2.PARMULTIFILIALCAIXABANCO3882,'N') = 'S';
  END IF;

  /*Atualizando registro*/
  FOR FINANC2 IN (SELECT SUM(NVL(PCFINANC2.VALOR, 0)) VALOR
                       , PCFINANC2.DATA
                       , PCFINANC2.CODFILIAL
                       , PCFINANC2.TIPODADO
                       --HIS.02205.2016 (TRATAMENTO PARA NOVO PROCESSO DE BANCOS/CAIXAS COM MULTIPLAS FILIAIS)
                       , NVL(PCFINANC2.LISTAFILIAISBANCOCAIXA,'VAZIO') AS LISTAFILIAISBANCOCAIXA
                       , NVL(PCFINANC2.PARMULTIFILIALCAIXABANCO3882, 'N') AS PARMULTIFILIALCAIXABANCO3882
                    FROM PCFINANC2
                   WHERE PCFINANC2.DATA = PDATAPROCESSADA
                     AND PCFINANC2.CODFILIAL = PCODFILIAL
                GROUP BY PCFINANC2.DATA
                       , PCFINANC2.CODFILIAL
                       , PCFINANC2.TIPODADO
                       , PCFINANC2.LISTAFILIAISBANCOCAIXA
                       , PCFINANC2.PARMULTIFILIALCAIXABANCO3882)
  LOOP
    /*Atualizando saldos da PCFINANC*/
    UPDATE PCFINANC
       SET PCFINANC.SALDOEMPRESTATIVO   = DECODE (Trim(FINANC2.TIPODADO), 'EMPRESTA' , FINANC2.VALOR, PCFINANC.SALDOEMPRESTATIVO)
          ,PCFINANC.SALDOCX             = DECODE (Trim(FINANC2.TIPODADO), 'CAIXA'    , FINANC2.VALOR, PCFINANC.SALDOCX)
          ,PCFINANC.SALDOINVESTATIVO    = DECODE (Trim(FINANC2.TIPODADO), 'INVEST'   , FINANC2.VALOR, PCFINANC.SALDOINVESTATIVO)
          ,PCFINANC.SALDOCRFOR          = DECODE (Trim(FINANC2.TIPODADO), 'CRFORNEC' , FINANC2.VALOR, PCFINANC.Saldocrfor)
          ,PCFINANC.SALDOCTRANS         = DECODE (Trim(FINANC2.TIPODADO), 'CTRANS'   , FINANC2.VALOR, PCFINANC.SALDOCTRANS)
          ,PCFINANC.SALDOCP             = DECODE (Trim(FINANC2.TIPODADO), 'CPAGAR'   , FINANC2.VALOR, PCFINANC.SALDOCP)
          --,PCFINANC.SALDOEMPRESTPASSIVO = DECODE (Trim(FINANC2.TIPODADO), 'EMPRESTP' , FINANC2.VALOR, pcfinanc.saldoemprestpassivo)
          ,PCFINANC.SALDOEMPRESTPASSIVO = PCFINANC.SALDOEMPRESTPASSIVO +  DECODE (Trim(FINANC2.TIPODADO),
                                                                                       'EMPRESTP' ,
                                                                                        FINANC2.VALOR,
                                                                                       'FINIMP'   ,
                                                                                       FINANC2.VALOR, 0)
          ,PCFINANC.SALDOBCO            = DECODE (Trim(FINANC2.TIPODADO), 'BANCO'    , FINANC2.VALOR, PCFINANC.SALDOBCO)
          ,PCFINANC.SALDOINVESTPASSIVO  = DECODE (Trim(FINANC2.TIPODADO), 'INVESTP'  , FINANC2.VALOR, PCFINANC.SALDOINVESTPASSIVO)
          ,PCFINANC.SALDOCREDCLI        = DECODE (Trim(FINANC2.TIPODADO), 'CREDCLI'  , FINANC2.VALOR, PCFINANC.SALDOCREDCLI)
          ,PCFINANC.SALDOVALE           = DECODE (Trim(FINANC2.TIPODADO), 'VALE'     , FINANC2.VALOR, PCFINANC.SALDOVALE)
          ,PCFINANC.SALDOESTREAL        = DECODE (Trim(FINANC2.TIPODADO), 'ESTOQUE'  , FINANC2.VALOR, PCFINANC.SALDOESTREAL)
          ,PCFINANC.SALDOCR             = DECODE (Trim(FINANC2.TIPODADO), 'CRECEBER' , FINANC2.VALOR, PCFINANC.SALDOCR)
          ,PCFINANC.SALDOADIANTFOR      = DECODE (Trim(FINANC2.TIPODADO), 'ADFORNEC' , FINANC2.VALOR, PCFINANC.SALDOADIANTFOR)
          ,PCFINANC.SALDOESTFIN         = DECODE (Trim(FINANC2.TIPODADO), 'ESTOQUE'  , FINANC2.VALOR, PCFINANC.SALDOESTFIN)
          ,PCFINANC.SALDOTITULOVENDOR   = DECODE (Trim(FINANC2.TIPODADO), 'VENDOR'   , FINANC2.VALOR, PCFINANC.SALDOTITULOVENDOR)
          ,PCFINANC.SALDOCPOUTROS       = DECODE (Trim(FINANC2.TIPODADO), 'CPOUTROS' , FINANC2.VALOR, PCFINANC.SALDOCPOUTROS)
          ,PCFINANC.SALDOESTOQUECONSUMOINTERNO  = DECODE (Trim(FINANC2.TIPODADO), 'ESTOQUECI' , FINANC2.VALOR, PCFINANC.SALDOESTOQUECONSUMOINTERNO)
     WHERE PCFINANC.DATA                = FINANC2.DATA
       AND PCFINANC.CODFILIAL           = FINANC2.CODFILIAL
       --HIS.02205.2016 (TRATAMENTO PARA NOVO PROCESSO DE BANCOS/CAIXAS COM MULTIPLAS FILIAIS)
       AND NVL(PCFINANC.LISTAFILIAISBANCOCAIXA,'VAZIO') = NVL(FINANC2.LISTAFILIAISBANCOCAIXA,'VAZIO')
       AND NVL(PCFINANC.PARMULTIFILIALCAIXABANCO3882,'N') = NVL(FINANC2.PARMULTIFILIALCAIXABANCO3882,'N');
  END LOOP;

  SELECT NVL(SUM(NVL(PCLANC.VALOR,0) -
                 NVL(PCLANC.DESCONTOFIN,0) +
                 NVL(PCLANC.TXPERM,0) -
                 NVL(PCLANC.VALORDEV,0)),0) SALDOCPMANUAL
   INTO VSALDOCPMANUAL
   FROM PCLANC
      , PCCONSUM
  WHERE PCLANC.DTPAGTO is null
    AND PCLANC.CODCONTA <> PCCONSUM.CODCONTAJUSTEEST
    AND PCLANC.CODCONTA <> PCCONSUM.CODCONTRECJUR
    AND PCLANC.CODCONTA <> PCCONSUM.CODCONTPAGJUR
    AND PCLANC.CODCONTA <> PCCONSUM.CODCONTANTPAG
    AND PCLANC.CODFILIAL IN (PCODFILIAL);

  /*Atualizando colunas de acumuladores*/
  UPDATE PCFINANC
     SET PCFINANC.SALDOREAL     = PCFINANC.SALDOCX               /*Caixa*/
                                + PCFINANC.SALDOBCO              /*Banco*/
                                + PCFINANC.SALDOVALE             /*Vales*/
                                + PCFINANC.SALDOEMPRESTATIVO     /*Emprest. Ativo*/
                                + PCFINANC.SALDOCTRANS           /*Contas Transitorias*/
                                + PCFINANC.SALDOCR               /*Contas a Receber*/
                                + PCFINANC.SALDOCRFOR            /*Contas a Receber de Fornecedor*/
                                + PCFINANC.SALDOESTFIN           /*Vl. Estoque*/
                                + PCFINANC.SALDOINVESTATIVO      /*Invest. Ativo*/
                                + PCFINANC.SALDOADIANTFOR        /*Adiant. de Fornec.*/
                                - PCFINANC.SALDOCP               /*Contas a Pagar*/
                                - PCFINANC.SALDOEMPRESTPASSIVO   /*Emp. Passivo*/
                                - PCFINANC.SALDOCREDCLI          /*Credito de Cliente*/
                                - PCFINANC.SALDOINVESTPASSIVO    /*Invest. Passivo*/
                                - PCFINANC.SALDOTITULOVENDOR     /*Títulos Descontador/Vendor*/
                                - PCFINANC.SALDOCPOUTROS         /*Contas a pagar outros fornecedores*/

       , PCFINANC.SALDOFIN      = PCFINANC.SALDOCX               /*Caixa*/
                                + PCFINANC.SALDOBCO              /*Banco*/
                                + PCFINANC.SALDOVALE             /*Vales*/
                                + PCFINANC.SALDOEMPRESTATIVO     /*Emprest. Ativo*/
                                + PCFINANC.SALDOCTRANS           /*Contas Transitorias*/
                                + PCFINANC.SALDOCR               /*Contas a Receber*/
                                + PCFINANC.SALDOCRFOR            /*Contas a Receber de Fornecedor*/
                                + PCFINANC.SALDOESTFIN           /*Vl. Estoque*/
                                + PCFINANC.SALDOINVESTATIVO      /*Invest. Ativo*/
                                + PCFINANC.SALDOADIANTFOR        /*Adiant. de Fornec.*/
                                - PCFINANC.SALDOCP               /*Contas a Pagar*/
                                - PCFINANC.SALDOEMPRESTPASSIVO   /*Emp. Passivo*/
                                - PCFINANC.SALDOCREDCLI          /*Credito de Cliente*/
                                - PCFINANC.SALDOINVESTPASSIVO    /*Invest. Passivo*/
                                - PCFINANC.SALDOTITULOVENDOR     /*Títulos Descontador/Vendor*/
                                - PCFINANC.SALDOCPOUTROS         /*Contas a pagar outros fornecedores*/

       , PCFINANC.SALDOCPMANUAL = VSALDOCPMANUAL - PCFINANC.SALDOCP
   WHERE PCFINANC.DATA          = PDATAPROCESSADA
     AND PCFINANC.CODFILIAL     = PCODFILIAL;

END GERAR_PCFINANC;

PROCEDURE GERAR_PCFINANC2(PCODFILIAL VARCHAR2, PCODROTINA NUMBER, PCODFUNC NUMBER, PDATAPROCESSADA  DATE) IS
VEXIBIRSALDOBRUTOFORNEC VARCHAR2(1);
VCOUNT NUMBER(10);
VDATATESTADA DATE;
BEGIN
  
  IF PCODROTINA <> 117 THEN  
    BEGIN
      SELECT COUNT(DISTINCT F.DATA), TRUNC(F.DTGERACAO)
      INTO VCOUNT, VDATATESTADA
      FROM PCFINANC2 F
      WHERE F.DTGERACAO >= TRUNC(SYSDATE)
      AND F.CODFILIAL = PCODFILIAL
      GROUP BY TRUNC(F.DTGERACAO);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
         VCOUNT := 0;
         VDATATESTADA := SYSDATE;
    END;


    IF VCOUNT > 7 THEN
      raise_application_error(-20001,'Foram gerados registros de '||to_char(VCOUNT)||' dias, apartir da data '||to_char(TRUNC(VDATATESTADA))||'.');
    END IF;
  
  END IF;
  
  VCOUNT := 0;
  VEXIBIRSALDOBRUTOFORNEC := PARAMFILIAL.OBTERCOMOVARCHAR2('EXIBIRSALDOBRUTOFORNEC');
  --Chamada da procedure para deleção dos registros da PCFINANC2 e PCFINANC3
  P_DELETAR_PCFINANC2E3(PCODFILIAL, PCODROTINA);

  /*ADIANTAMENTO FORNECEDOR ANALITICO*/
  FOR ADIANTAMENTO_FORNECEDOR IN (SELECT CODFORNEC
                                        ,SUM(VALOR) VLRTOTAL
                                        ,CODFILIAL
                                    FROM (SELECT PCLANC.CODFORNEC
                                                ,NVL(SUM(NVL(PCLANC.VALOR, 0)), 0) VALOR
                                                ,PCLANC.CODFILIAL
                                                ,PCLANC.RECNUM
                                    FROM PCLANC
                                   WHERE PCLANC.CODCONTA <> 0
                                     AND NVL(PCLANC.NUMTRANSADIANTFOR, 0) = 0
                   AND EXISTS
                     (SELECT 1
                          FROM PCCONSUM
                         WHERE (PCLANC.CODCONTA = PCCONSUM.CODCONTAADIANTFOR OR
                             PCLANC.CODCONTA = PCCONSUM.CODCONTAADIANTFOROUTROS))
                                     AND PCLANC.CODFILIAL = PCODFILIAL
                                     AND PCLANC.CODROTINABAIXA <> 737
                                     AND NVL(PCLANC.NUMTRANSADIANTFOR, 0) = 0
                                     AND (NVL(PCLANC.VALOR, 0) + (NVL(PCLANC.VLVARIACAOCAMBIAL, 0)) -
                                         NVL(PCLANC.VLRUTILIZADOADIANTFORNEC, 0)) > 0.0099
                                     AND PCLANC.DTPAGTO IS NOT NULL
                                     AND PCLANC.DTESTORNOBAIXA IS NULL
                                     AND PCLANC.DTCANCEL IS NULL
                                           GROUP BY PCLANC.CODFORNEC
                                                   ,PCLANC.CODFILIAL
                                                   ,PCLANC.RECNUM
                                          UNION ALL
                                          SELECT CODFORNEC
                                                ,SUM(VALOR) VALOR
                                                ,CODFILIAL
                                                ,RECNUM
                                            FROM (SELECT PCLANC.CODFORNEC
                                                        ,PCLANC.RECNUM
                                                        ,NVL(SUM(NVL(PCLANC.VALOR, 0)) -
                                                             SUM(NVL(PCLANC.VLRUTILIZADOADIANTFORNEC, 0)) +
                                                             SUM(NVL(PCLANC.VLVARIACAOCAMBIAL, 0))
                                                            ,0) VALOR
                                                        ,PCLANC.CODFILIAL
                                                    FROM PCLANC


                                                   WHERE EXISTS
                               (SELECT 1
                                    FROM PCCONSUM
                                   WHERE (PCLANC.CODCONTA = PCCONSUM.CODCONTAADIANTFOR OR
                                       PCLANC.CODCONTA = PCCONSUM.CODCONTAADIANTFOROUTROS))
                                                     AND PCLANC.CODCONTA <> 0
                                                     AND PCLANC.DTPAGTO IS NOT NULL
                                                     AND PCLANC.DTESTORNOBAIXA IS NULL
                                                     AND PCLANC.DTCANCEL IS NULL
                                                     AND PCLANC.CODROTINABAIXA <> 737
                                                     AND NVL(PCLANC.NUMTRANSADIANTFOR, 0) <> 0
                                                     AND PCLANC.CODFILIAL = PCODFILIAL
                                GROUP BY PCLANC.CODFORNEC
                                                           ,PCLANC.RECNUM
                                                           ,PCLANC.CODFILIAL
                                           )
                                           GROUP BY CODFORNEC
                                                   ,CODFILIAL
                                                   ,RECNUM)
                                   GROUP BY CODFORNEC
                                           ,CODFILIAL)
  LOOP
    /*INSERIR PCFINANC2*/
    PCFINANC2_GRAVAR( PDATAPROCESSADA                     --PDATA
                    , ADIANTAMENTO_FORNECEDOR.CODFILIAL   --PCODFILIAL
                    , 'ADFORNEC'                          --PTIPODADO
                    , ADIANTAMENTO_FORNECEDOR.CODFORNEC   --PCODIGON
                    , '0'                                 --PCODIGOA
                    , ADIANTAMENTO_FORNECEDOR.VLRTOTAL    --PVALOR
                    , SYSDATE                             --PDTGERACAO
                    , PCODROTINA                          --PCODROTINA
                    , PCODFUNC                            --PCODFUNC
                    , 0);                                 --PVALOR2
  END LOOP;

  ----------------------------------------------------------------------------------------------------------------
  /*1. PARA CADA CAIXA, GERAR LINHAS PARA PROCESSO ANTIGO E TAMBÉM PARA NOVO PROCESSO "BANCO/CAIXAS COM MULTIPLAS FILIAIS"*/
  /*1.1 CAIXA ANALITICO --  ATIVO */
  FOR CAIXAS IN ( SELECT PCESTCR.CODBANCO
                     , SUM( PCESTCR.VALOR ) VLRTOTAL
                     , PCBANCO.NOME
                     , SUM(PCESTCR.VALORCONCILIADO) VLRTOTAL2
                     , PCESTCR.CODCOB
                     , NVL(PCBANCO.CODFILIAL, '99') CODFILIAL
                  FROM PCESTCR
                     , PCBANCO
                 WHERE PCESTCR.CODBANCO = PCBANCO.CODBANCO
                   AND (PCBANCO.TIPOCXBCO = 'C')
                   AND (PCESTCR.CODCOB = 'D')
                   AND PCBANCO.CODFILIAL = PCODFILIAL
              GROUP BY PCESTCR.CODBANCO
                     , PCBANCO.NOME
                     , PCESTCR.CODCOB
                     , NVL(PCBANCO.CODFILIAL, '99')
              ORDER BY SUM( PCESTCR.VALOR ) DESC)
  LOOP
    /*INSERIR PCFINANC2*/
    PCFINANC2_GRAVAR( PDATAPROCESSADA          --PDATA
                    , CAIXAS.CODFILIAL         --PCODFILIAL
                    , 'CAIXA'                  --PTIPODADO
                    , CAIXAS.CODBANCO          --PCODIGON
                    , CAIXAS.CODCOB            --PCODIGOA
                    , CAIXAS.VLRTOTAL          --PVALOR
                    , SYSDATE                  --PDTGERACAO
                    , PCODROTINA               --PCODROTINA
                    , PCODFUNC                 --PCODFUNC
                    , CAIXAS.VLRTOTAL2);       --PVALOR2
  END LOOP;

  /*1.2 CAIXA ANALITICO - ATIVO - HIS.02205.2016(NOVO PROCESSO DE BANCOS/CAIXAS COM MULTIPLAS FILIAIS)*/
  FOR CAIXAS IN ( SELECT PCESTCR.CODBANCO
                       , SUM( PCESTCR.VALOR ) VLRTOTAL
                       , PCBANCO.NOME
                       , SUM(PCESTCR.VALORCONCILIADO) VLRTOTAL2
                       , PCESTCR.CODCOB
                       , VW_PCBANCOFILIAIS.CODFILIAL
                       , DECODE(VW_PCBANCOFILIAIS.CODFILIAL, '99', VW_PCBANCOFILIAIS.FILIAISVINCULADAS, NULL) AS FILIAISVINCULADAS
                  FROM PCESTCR, PCBANCO, VW_PCBANCOFILIAIS
                  WHERE PCESTCR.CODBANCO = PCBANCO.CODBANCO
                  --AND (PCESTCR.VALOR <> 0)
                  AND (PCBANCO.TIPOCXBCO = 'C')
                  AND (PCESTCR.CODCOB = 'D')
                  AND VW_PCBANCOFILIAIS.CODBANCO = PCBANCO.CODBANCO
                  AND VW_PCBANCOFILIAIS.CODFILIAL = PCODFILIAL
                  --AND (NVL(PCESTCR.VALOR, 0) + NVL(PCESTCR.VALORCONCILIADO, 0)) <> 0
                  GROUP BY PCESTCR.CODBANCO
                         , PCBANCO.NOME
                         , PCESTCR.CODCOB
                         , VW_PCBANCOFILIAIS.CODFILIAL
                         , VW_PCBANCOFILIAIS.FILIAISVINCULADAS
                  ORDER BY SUM( PCESTCR.VALOR ) DESC)
  LOOP
    /*INSERIR PCFINANC2*/
    PCFINANC2_GRAVAR( PDATAPROCESSADA           --PDATA
                    , CAIXAS.CODFILIAL          --PCODFILIAL
                    , 'CAIXA'                   --PTIPODADO
                    , CAIXAS.CODBANCO           --PCODIGON
                    , CAIXAS.CODCOB             --PCODIGOA
                    , CAIXAS.VLRTOTAL           --PVALOR
                    , SYSDATE                   --PDTGERACAO
                    , PCODROTINA                --PCODROTINA
                    , PCODFUNC                  --PCODFUNC
                    , CAIXAS.VLRTOTAL2          --PVALOR2
                    , 'S'                       --PPARMULTIFILIALCAIXABANCO3882
                    , CAIXAS.FILIAISVINCULADAS);--PLISTAFILIAIS. GRAVA LISTA QUANDO A FILIAL INFORMADA FOR "99".
  END LOOP;

  ----------------------------------------------------------------------------------------------------------------
  /*2. PARA CADA BANCO, GERAR LINHAS PARA PROCESSO ANTIGO E TAMBÉM PARA NOVO PROCESSO "BANCO/CAIXAS COM MULTIPLAS FILIAIS"*/
  /*2.1 BANCO ANALITICO --  ATIVO*/
  FOR BANCOS IN ( SELECT PCESTCR.CODBANCO
                       , PCESTCR.CODCOB
                       , PCESTCR.VALOR VLRTOTAL
                       , PCESTCR.VALORCONCILIADO  VLRTOTAL2
                       , NVL(PCBANCO.CODFILIAL, '99') CODFILIAL
                    FROM PCESTCR
                       , PCMOEDA
                       , PCBANCO
                   WHERE PCESTCR.CODBANCO = PCBANCO.CODBANCO
                     AND PCESTCR.CODCOB = PCMOEDA.CODMOEDA
                     AND PCBANCO.TIPOCXBCO = 'B'
                     AND PCESTCR.CODCOB IN ('D', 'DAPL', 'APLI')
                     AND PCBANCO.CODFILIAL = PCODFILIAL
                ORDER BY PCESTCR.VALOR DESC)
  LOOP
    /*INSERIR PCFINANC2*/
    PCFINANC2_GRAVAR( PDATAPROCESSADA       --PDATA
                    , BANCOS.CODFILIAL      --PCODFILIAL
                    , 'BANCO'               --PTIPODADO
                    , BANCOS.CODBANCO       --PCODIGON
                    , BANCOS.CODCOB         --PCODIGOA
                    , BANCOS.VLRTOTAL       --PVALOR
                    , SYSDATE               --PDTGERACAO
                    , PCODROTINA            --PCODROTINA
                    , PCODFUNC              --PCODFUNC
                    , BANCOS.VLRTOTAL2);    --PVALOR2
  END LOOP;

  /*2.2 BANCO ANALITICO - ATIVO - HIS.02205.2016(NOVO PROCESSO DE BANCOS/CAIXAS COM MULTIPLAS FILIAIS)*/
  FOR BANCOS IN ( SELECT PCESTCR.CODBANCO
                       , PCESTCR.CODCOB
                       , PCESTCR.VALOR VLRTOTAL
                       , PCESTCR.VALORCONCILIADO  VLRTOTAL2
                       , VW_PCBANCOFILIAIS.CODFILIAL
                       , DECODE(VW_PCBANCOFILIAIS.CODFILIAL, '99', VW_PCBANCOFILIAIS.FILIAISVINCULADAS, NULL) AS FILIAISVINCULADAS
                    FROM PCESTCR, PCMOEDA, PCBANCO, VW_PCBANCOFILIAIS
                   WHERE PCESTCR.CODBANCO = PCBANCO.CODBANCO
                     AND PCESTCR.CODCOB = PCMOEDA.CODMOEDA
                     AND PCBANCO.TIPOCXBCO = 'B'
                     AND PCESTCR.CODCOB IN ('D', 'DAPL', 'APLI')
                     AND VW_PCBANCOFILIAIS.CODBANCO = PCBANCO.CODBANCO
                     AND VW_PCBANCOFILIAIS.CODFILIAL = PCODFILIAL
                ORDER BY PCESTCR.VALOR DESC)
  LOOP
    /*INSERIR PCFINANC2*/
    PCFINANC2_GRAVAR( PDATAPROCESSADA           --PDATA
                    , BANCOS.CODFILIAL          --PCODFILIAL
                    , 'BANCO'                   --PTIPODADO
                    , BANCOS.CODBANCO           --PCODIGON
                    , BANCOS.CODCOB             --PCODIGOA
                    , BANCOS.VLRTOTAL           --PVALOR
                    , SYSDATE                   --PDTGERACAO
                    , PCODROTINA                --PCODROTINA
                    , PCODFUNC                  --PCODFUNC
                    , BANCOS.VLRTOTAL2          --PVALOR2
                    , 'S'                       --PPARMULTIFILIALCAIXABANCO3882
                    , BANCOS.FILIAISVINCULADAS);--PLISTAFILIAIS. GRAVA LISTA QUANDO A FILIAL INFORMADA FOR "99".
  END LOOP;

  ----------------------------------------------------------------------------------------------------------------
  /*3. PARA CADA VALE, GERAR LINHAS PARA PROCESSO ANTIGO E TAMBÉM PARA NOVO PROCESSO "BANCO/CAIXAS COM MULTIPLAS FILIAIS"*/
  /*3.1 VALES - ATIVO*/
  FOR VALES IN ( SELECT PCESTCR.CODBANCO
                      , SUM(PCESTCR.VALORCONCILIADO) VLRTOTAL2
                      , SUM(PCESTCR.VALOR) VLRTOTAL
                      , PCESTCR.CODCOB
                      , PCBANCO.CODFILIAL
                   FROM PCESTCR
                      , PCBANCO
                  WHERE PCESTCR.CODBANCO = PCBANCO.CODBANCO
                    AND PCESTCR.CODCOB = 'VALE'
                    AND PCBANCO.CODFILIAL IN( PCODFILIAL)
               GROUP BY PCESTCR.CODBANCO
                      , PCESTCR.CODCOB
                      , PCBANCO.CODFILIAL
              )
  LOOP
    /*INSERIR PCFINANC2*/
    PCFINANC2_GRAVAR( PDATAPROCESSADA    --PDATA
                    , VALES.CODFILIAL    --PCODFILIAL
                    , 'VALE'             --PTIPODADO
                    , VALES.CODBANCO     --PCODIGON
                    , VALES.CODCOB       --PCODIGOA
                    , VALES.VLRTOTAL     --PVALOR
                    , SYSDATE            --PDTGERACAO
                    , PCODROTINA         --PCODROTINA
                    , PCODFUNC           --PCODFUNC
                    , VALES.VLRTOTAL2);  --PVALOR2
  END LOOP;

  /*3.2 VALES - ATIVO - HIS.02205.2016(NOVO PROCESSO DE BANCOS/CAIXAS COM MULTIPLAS FILIAIS)*/
  FOR VALES IN ( SELECT PCESTCR.CODBANCO
                      , SUM(PCESTCR.VALORCONCILIADO) VLRTOTAL2
                      , SUM(PCESTCR.VALOR) VLRTOTAL
                      , PCESTCR.CODCOB
                      , VW_PCBANCOFILIAIS.CODFILIAL
                      , DECODE(VW_PCBANCOFILIAIS.CODFILIAL, '99', VW_PCBANCOFILIAIS.FILIAISVINCULADAS, NULL) AS FILIAISVINCULADAS
                   FROM PCESTCR, PCBANCO, VW_PCBANCOFILIAIS
                  WHERE PCESTCR.CODBANCO = PCBANCO.CODBANCO
                    AND PCESTCR.CODCOB = 'VALE'
                    AND VW_PCBANCOFILIAIS.CODBANCO = PCBANCO.CODBANCO
                    AND VW_PCBANCOFILIAIS.CODFILIAL = PCODFILIAL
               GROUP BY PCESTCR.CODBANCO
                      , PCESTCR.CODCOB
                      , VW_PCBANCOFILIAIS.CODFILIAL
                      , VW_PCBANCOFILIAIS.FILIAISVINCULADAS
           )
  LOOP
    /*INSERIR PCFINANC2*/
    PCFINANC2_GRAVAR( PDATAPROCESSADA          --PDATA
                    , VALES.CODFILIAL          --PCODFILIAL
                    , 'VALE'                   --PTIPODADO
                    , VALES.CODBANCO           --PCODIGON
                    , VALES.CODCOB             --PCODIGOA
                    , VALES.VLRTOTAL           --PVALOR
                    , SYSDATE                  --PDTGERACAO
                    , PCODROTINA               --PCODROTINA
                    , PCODFUNC                 --PCODFUNC
                    , VALES.VLRTOTAL2          --PVALOR2
                    , 'S'                      --PPARMULTIFILIALCAIXABANCO3882
                    , VALES.FILIAISVINCULADAS);--PLISTAFILIAIS. GRAVA LISTA QUANDO A FILIAL INFORMADA FOR "99".
  END LOOP;

  ----------------------------------------------------------------------------------------------------------------
  /*4. PARA CADA CONTA TRANSITÓRIA, GERAR LINHAS PARA PROCESSO ANTIGO E TAMBÉM PARA NOVO PROCESSO "BANCO/CAIXAS COM MULTIPLAS FILIAIS"*/
  /*4.1. CONTAS TRANSITÓRIAS -- ATIVO*/
  FOR CONTAS_TRANSITORIA IN ( SELECT PCESTCR.CODBANCO
                                   , PCBANCO.NOME
                                   , PCESTCR.CODCOB
                                   , PCMOEDA.MOEDA
                                   , PCESTCR.VALOR    VLRTOTAL
                                   , PCESTCR.VALORCONCILIADO  VLRTOTAL2
                                   , PCBANCO.CODFILIAL
                                FROM PCESTCR
                                   , PCBANCO
                                   , PCMOEDA
                               WHERE PCESTCR.CODBANCO = PCBANCO.CODBANCO(+)
                                 AND PCESTCR.CODCOB = PCMOEDA.CODMOEDA(+)
                                 AND PCESTCR.CODCOB NOT IN ('D','DAPL','APLI','VALE')
                                 AND PCBANCO.TIPOCXBCO <> 'E'
                                 AND PCBANCO.CODFILIAL IN ( PCODFILIAL )
                             )
  LOOP
    /*INSERIR PCFINANC2*/
    PCFINANC2_GRAVAR( PDATAPROCESSADA                  --PDATA
                    , CONTAS_TRANSITORIA.CODFILIAL     --PCODFILIAL
                    , 'CTRANS'                         --PTIPODADO
                    , CONTAS_TRANSITORIA.CODBANCO      --PCODIGON
                    , CONTAS_TRANSITORIA.CODCOB        --PCODIGOA
                    , CONTAS_TRANSITORIA.VLRTOTAL      --PVALOR
                    , SYSDATE                          --PDTGERACAO
                    , PCODROTINA                       --PCODROTINA
                    , PCODFUNC                         --PCODFUNC
                    , CONTAS_TRANSITORIA.VLRTOTAL2);   --PVALOR2
  END LOOP;

  /*4.2 CONTAS TRANSITÓRIAS - ATIVO - HIS.02205.2016(NOVO PROCESSO DE BANCOS/CAIXAS COM MULTIPLAS FILIAIS)*/
  FOR CONTAS_TRANSITORIA IN (SELECT PCESTCR.CODBANCO
                                   , PCBANCO.NOME
                                   , PCESTCR.CODCOB
                                   , PCMOEDA.MOEDA
                                   , PCESTCR.VALOR    VLRTOTAL
                                   , PCESTCR.VALORCONCILIADO  VLRTOTAL2
                                   , VW_PCBANCOFILIAIS.CODFILIAL
                                   , DECODE(VW_PCBANCOFILIAIS.CODFILIAL, '99', VW_PCBANCOFILIAIS.FILIAISVINCULADAS, NULL) AS FILIAISVINCULADAS
                                FROM PCESTCR, PCBANCO, PCMOEDA, VW_PCBANCOFILIAIS
                               WHERE PCESTCR.CODBANCO = PCBANCO.CODBANCO(+)
                                 AND PCESTCR.CODCOB = PCMOEDA.CODMOEDA(+)
                                 AND PCESTCR.CODCOB NOT IN ('D','DAPL','APLI','VALE')
                                 AND PCBANCO.TIPOCXBCO <> 'E'
                                 AND VW_PCBANCOFILIAIS.CODBANCO = PCBANCO.CODBANCO
                                 AND VW_PCBANCOFILIAIS.CODFILIAL = PCODFILIAL
                               )
  LOOP
    /*INSERIR PCFINANC2*/
    PCFINANC2_GRAVAR( PDATAPROCESSADA                       --PDATA
                    , CONTAS_TRANSITORIA.CODFILIAL          --PCODFILIAL
                    , 'CTRANS'                              --PTIPODADO
                    , CONTAS_TRANSITORIA.CODBANCO           --PCODIGON
                    , CONTAS_TRANSITORIA.CODCOB             --PCODIGOA
                    , CONTAS_TRANSITORIA.VLRTOTAL           --PVALOR
                    , SYSDATE                               --PDTGERACAO
                    , PCODROTINA                            --PCODROTINA
                    , PCODFUNC                              --PCODFUNC
                    , CONTAS_TRANSITORIA.VLRTOTAL2          --PVALOR2
                    , 'S'                                   --PPARMULTIFILIALCAIXABANCO3882
                    , CONTAS_TRANSITORIA.FILIAISVINCULADAS);--PLISTAFILIAIS. GRAVA LISTA QUANDO A FILIAL INFORMADA FOR "99".
  END LOOP;

  ----------------------------------------------------------------------------------------------------------------
  --CONTAS A RECEBER ANALÍTICO --  ATIVO
  P_CALC_SALDO_CONTASRECEBER(PCODFILIAL,
                             PCODROTINA,
                             PCODFUNC,
                             PDATAPROCESSADA);
  --Contas Receber Fornecedor analitico - Ativo
  P_CALC_SALDO_VERBAS(PCODFILIAL,
                      PCODROTINA,
                      PCODFUNC,
                      PDATAPROCESSADA);

  /*ESTOQUE ANALITICO*/
  FOR ESTOQUE IN (SELECT PCPRODUT.CODEPTO
                       , SUM(NVL(PCEST.QTESTGER,0) * NVL(PCEST.CUSTOREP,0)) VLRTOTAL
                       , PCEST.CODFILIAL
                    FROM PCEST
                       , PCPRODUT
                       , PCDEPTO
                       , PCFORNEC
                   WHERE PCEST.CODPROD = PCPRODUT.CODPROD
                     AND PCPRODUT.CODEPTO = PCDEPTO.CODEPTO
                     AND PCPRODUT.CODFORNEC = PCFORNEC.CODFORNEC
                     AND NVL(PCDEPTO.TIPOMERC, 'XX') NOT IN ('IM','CI')
                     -- AND PCPRODUT.DTEXCLUSAO IS NULL 0.088416.2015. Será considerado também os produtos excluídos que tem estoque.
                     AND PCEST.CODFILIAL = PCODFILIAL
                GROUP BY PCPRODUT.CODEPTO
                       , PCEST.CODFILIAL
         )
  LOOP
    /*INSERIR PCFINANC2*/
    PCFINANC2_GRAVAR(PDATAPROCESSADA         --PDATA
                    , ESTOQUE.CODFILIAL      --PCODFILIAL
                    , 'ESTOQUE'              --PTIPODADO
                    , ESTOQUE.CODEPTO        --PCODIGON
                    , '0'                    --PCODIGOA
                    , ESTOQUE.VLRTOTAL       --PVALOR
                    , SYSDATE                --PDTGERACAO
                    , PCODROTINA             --PCODROTINA
                    , PCODFUNC               --PCODFUNC
                    , 0);                    --PVALOR2
  END LOOP;

  --CONTAS A PAGAR - OUTROS FORNECEDORES
  P_CALC_SALDO_CONTASPAGAROUTROS(PCODFILIAL,
                                 PCODROTINA,
                                 PCODFUNC,
                                 PDATAPROCESSADA,
                                 VEXIBIRSALDOBRUTOFORNEC);

  --CONTAS A PAGAR A FORNECEDORES (CADASTRADOS E NÃO CADASTRADOS) ANALÍTICO
  P_CALC_SALDO_CONTASPAGARFORNEC(PCODFILIAL,
                                 PCODROTINA,
                                 PCODFUNC,
                                 PDATAPROCESSADA,
                                 VEXIBIRSALDOBRUTOFORNEC);

  ----------------------------------------------------------------------------------------------------------------
  /*5. PARA CADA EMPRESTIMO ATIVO, GERAR LINHAS PARA PROCESSO ANTIGO E TAMBÉM PARA NOVO PROCESSO "BANCO/CAIXAS COM MULTIPLAS FILIAIS"*/
  /*5.1. EMPRESTIMO ATIVO ANALITICO -- ATIVO*/
  FOR EMPRESTIMO_ATIVO IN ( SELECT PCESTCR.CODBANCO
                                 , PCBANCO.NOME
                                 , PCESTCR.VALOR VLRTOTAL
                                 , PCESTCR.CODCOB
                                 , PCMOEDA.MOEDA
                                 , PCBANCO.CODFILIAL
                              FROM PCESTCR
                                 , PCBANCO
                                 , PCMOEDA
                             WHERE PCESTCR.CODBANCO = PCBANCO.CODBANCO
                               AND PCESTCR.CODCOB = PCMOEDA.CODMOEDA
                               AND PCBANCO.TIPOCXBCO = 'E'
                               AND PCESTCR.VALOR > 0
                               AND PCBANCO.CODFILIAL IN(PCODFILIAL)
                          ORDER BY PCESTCR.VALOR DESC)
  LOOP
    /*INSERIR PCFINANC2*/
    PCFINANC2_GRAVAR( PDATAPROCESSADA              --PDATA
                    , EMPRESTIMO_ATIVO.CODFILIAL   --PCODFILIAL
                    , 'EMPRESTA'                   --PTIPODADO
                    , EMPRESTIMO_ATIVO.CODBANCO    --PCODIGON
                    , EMPRESTIMO_ATIVO.CODCOB      --PCODIGOA
                    , EMPRESTIMO_ATIVO.VLRTOTAL       --PVALOR
                    , SYSDATE                      --PDTGERACAO
                    , PCODROTINA                   --PCODROTINA
                    , PCODFUNC                     --PCODFUNC
                    , 0);                          --PVALOR2
  END LOOP;

  /*5.2 EMPRESTIMO ATIVO - HIS.02205.2016(NOVO PROCESSO DE BANCOS/CAIXAS COM MULTIPLAS FILIAIS)*/
  FOR EMPRESTIMO_ATIVO IN ( SELECT PCESTCR.CODBANCO
                                 , PCBANCO.NOME
                                 , PCESTCR.VALOR VLRTOTAL
                                 , PCESTCR.CODCOB
                                 , PCMOEDA.MOEDA
                                 , VW_PCBANCOFILIAIS.CODFILIAL
                                 , DECODE(VW_PCBANCOFILIAIS.CODFILIAL, '99', VW_PCBANCOFILIAIS.FILIAISVINCULADAS, NULL) AS FILIAISVINCULADAS
                              FROM PCESTCR, PCBANCO, PCMOEDA, VW_PCBANCOFILIAIS
                             WHERE PCESTCR.CODBANCO = PCBANCO.CODBANCO
                               AND PCESTCR.CODCOB = PCMOEDA.CODMOEDA
                               AND PCBANCO.TIPOCXBCO = 'E'
                               AND PCESTCR.VALOR > 0
                               AND VW_PCBANCOFILIAIS.CODBANCO = PCBANCO.CODBANCO
                               AND VW_PCBANCOFILIAIS.CODFILIAL = PCODFILIAL
                          ORDER BY PCESTCR.VALOR DESC)
  LOOP
    /*INSERIR PCFINANC2*/
    PCFINANC2_GRAVAR( PDATAPROCESSADA                     --PDATA
                    , EMPRESTIMO_ATIVO.CODFILIAL          --PCODFILIAL
                    , 'EMPRESTA'                          --PTIPODADO
                    , EMPRESTIMO_ATIVO.CODBANCO           --PCODIGON
                    , EMPRESTIMO_ATIVO.CODCOB             --PCODIGOA
                    , EMPRESTIMO_ATIVO.VLRTOTAL           --PVALOR
                    , SYSDATE                             --PDTGERACAO
                    , PCODROTINA                          --PCODROTINA
                    , PCODFUNC                            --PCODFUNC
                    , 0                                   --PVALOR2
                    , 'S'                                 --PPARMULTIFILIALCAIXABANCO3882
                    , EMPRESTIMO_ATIVO.FILIAISVINCULADAS);--PLISTAFILIAIS. GRAVA LISTA QUANDO A FILIAL INFORMADA FOR "99".
  END LOOP;

  ----------------------------------------------------------------------------------------------------------------
  /*6. PARA CADA EMPRESTIMO PASSIVO, GERAR LINHAS PARA PROCESSO ANTIGO E TAMBÉM PARA NOVO PROCESSO "BANCO/CAIXAS COM MULTIPLAS FILIAIS"*/
  /*6.1. EMPRESTIMO PASSIVO ANALITICO -- PASSIVO*/
  FOR EMPRESTIMO_PASSIVO IN (SELECT PCESTCR.CODBANCO
                                  , PCBANCO.NOME
                                  , (PCESTCR.VALOR * (-1)) VLRTOTAL
                                  , PCESTCR.CODCOB, PCMOEDA.MOEDA
                                  , PCBANCO.CODFILIAL
                               FROM PCESTCR
                                  , PCBANCO
                                  , PCMOEDA
                              WHERE PCESTCR.CODBANCO = PCBANCO.CODBANCO
                                AND PCESTCR.CODCOB = PCMOEDA.CODMOEDA
                                AND PCBANCO.TIPOCXBCO = 'E'
                                AND PCESTCR.VALOR < 0
                                AND PCBANCO.CODFILIAL IN (PCODFILIAL)
                           ORDER BY PCESTCR.VALOR DESC)
  LOOP
    /*INSERIR PCFINANC2*/
    PCFINANC2_GRAVAR( PDATAPROCESSADA                   --PDATA
                    , EMPRESTIMO_PASSIVO.CODFILIAL      --PCODFILIAL
                    , 'EMPRESTP'                        --PTIPODADO
                    , EMPRESTIMO_PASSIVO.CODBANCO       --PCODIGON
                    , EMPRESTIMO_PASSIVO.CODCOB         --PCODIGOA
                    , EMPRESTIMO_PASSIVO.VLRTOTAL       --PVALOR
                    , SYSDATE                           --PDTGERACAO
                    , PCODROTINA                        --PCODROTINA
                    , PCODFUNC                          --PCODFUNC
                    , 0);                               --PVALOR2
  END LOOP;

  /*6.2 CONTAS TRANSITÓRIAS - ATIVO - HIS.02205.2016(NOVO PROCESSO DE BANCOS/CAIXAS COM MULTIPLAS FILIAIS)*/
  FOR EMPRESTIMO_PASSIVO IN (SELECT PCESTCR.CODBANCO
                                  , PCBANCO.NOME
                                  , (PCESTCR.VALOR * (-1)) VLRTOTAL
                                  , PCESTCR.CODCOB
                                  , PCMOEDA.MOEDA
                                 , VW_PCBANCOFILIAIS.CODFILIAL
                                 , DECODE(VW_PCBANCOFILIAIS.CODFILIAL, '99', VW_PCBANCOFILIAIS.FILIAISVINCULADAS, NULL) AS FILIAISVINCULADAS
                               FROM PCESTCR, PCBANCO, PCMOEDA, VW_PCBANCOFILIAIS
                              WHERE PCESTCR.CODBANCO = PCBANCO.CODBANCO
                                AND PCESTCR.CODCOB = PCMOEDA.CODMOEDA
                                AND PCBANCO.TIPOCXBCO = 'E'
                                AND PCESTCR.VALOR < 0
                                AND VW_PCBANCOFILIAIS.CODBANCO = PCBANCO.CODBANCO
                                AND VW_PCBANCOFILIAIS.CODFILIAL = PCODFILIAL
                           ORDER BY PCESTCR.VALOR DESC)
  LOOP
    /*INSERIR PCFINANC2*/
    PCFINANC2_GRAVAR( PDATAPROCESSADA                       --PDATA
                    , EMPRESTIMO_PASSIVO.CODFILIAL          --PCODFILIAL
                    , 'EMPRESTP'                            --PTIPODADO
                    , EMPRESTIMO_PASSIVO.CODBANCO           --PCODIGON
                    , EMPRESTIMO_PASSIVO.CODCOB             --PCODIGOA
                    , EMPRESTIMO_PASSIVO.VLRTOTAL           --PVALOR
                    , SYSDATE                               --PDTGERACAO
                    , PCODROTINA                            --PCODROTINA
                    , PCODFUNC                              --PCODFUNC
                    , 0                                     --PVALOR2
                    , 'S'                                   --PPARMULTIFILIALCAIXABANCO3882
                    , EMPRESTIMO_PASSIVO.FILIAISVINCULADAS);--PLISTAFILIAIS. GRAVA LISTA QUANDO A FILIAL INFORMADA FOR "99".
  END LOOP;

  ----------------------------------------------------------------------------------------------------------------

  /*EMPRESTIMOS FINIMP*/
  FOR EMPRESTIMO_FINIMP IN (
    SELECT F.CODFORNEC,
           NVL(LANCAMENTOS.VALOR, 0) AS VALOR
      FROM PCFORNEC F,
           (SELECT PCPRODUT.CODFORNEC,
                   SUM(NVL(PCEST.QTESTGER, 0) * NVL(PCEST.CUSTOREP, 0)) VLESTOQUE
              FROM PCPRODUT, PCEST, PCDEPTO
             WHERE (PCPRODUT.CODPROD = PCEST.CODPROD)
               AND (PCPRODUT.CODEPTO = PCDEPTO.CODEPTO)
               AND (PCDEPTO.TIPOMERC NOT IN ('IM', 'CI'))
               AND (NVL(PCEST.QTESTGER, 0) <> 0)
               AND PCEST.CODFILIAL IN(PCODFILIAL)
          GROUP BY PCPRODUT.CODFORNEC) ESTOQUE,

           (SELECT PCLANC.CODFORNEC,
                   DECODE(VEXIBIRSALDOBRUTOFORNEC, 'S', SUM(NVL(PCLANC.VALOR, 0)),
                                                        NVL(SUM(NVL(PCLANC.VALOR, 0) -
                                                                NVL(PCLANC.DESCONTOFIN, 0) +
                                                                NVL(PCLANC.TXPERM, 0) -
                                                                NVL(PCLANC.VALORDEV, 0)
                                                               ),
                                                           0)
                         ) VALOR
              FROM PCLANC
             WHERE PCLANC.CODCONTA IN (SELECT VALOR
                                         FROM PCPARAMFILIAL
                                        WHERE NOME IN ('CON_CODCONTEMPREST', 'CODCONTAEMPRESTIMONACIONAL',
                                                       'CODCONTAEMPRESTIMOESTRANGEIRO'))
               AND (PCLANC.DTPAGTO IS NULL)
               AND (PCLANC.VPAGO IS NULL)
               AND (PCLANC.VPAGOBORDERO IS NULL)
               AND PCLANC.CODFILIAL IN(PCODFILIAL)
               AND PCLANC.TIPOLANC = 'C'
          GROUP BY PCLANC.CODFORNEC) LANCAMENTOS

     WHERE F.CODFORNEC = ESTOQUE.CODFORNEC(+)
       AND F.CODFORNEC = LANCAMENTOS.CODFORNEC(+)
  )
  LOOP
    /*INSERIR PCFINANC2*/
    PCFINANC2_GRAVAR( PDATAPROCESSADA                   --PDATA
                    , PCODFILIAL                        --PCODFILIAL
                    , 'FINIMP'                          --PTIPODADO
                    , EMPRESTIMO_FINIMP.CODFORNEC       --PCODIGON
                    , '0'                               --PCODIGOA
                    , EMPRESTIMO_FINIMP.VALOR           --PVALOR
                    , SYSDATE                           --PDTGERACAO
                    , PCODROTINA                        --PCODROTINA
                    , PCODFUNC                          --PCODFUNC
                    , 0);                               --PVALOR2
  END LOOP;

  /*CREDITO DO CLIENTE ANALÍTICO*/
  FOR CREDITO_CLIENTE IN (SELECT PCCRECLI.CODCLI
                               , SUM(PCCRECLI.VALOR) AS VLRTOTAL
                               , PCCRECLI.CODFILIAL
                            FROM PCCRECLI
                               , PCCLIENT
                           WHERE PCCRECLI.CODCLI = PCCLIENT.CODCLI
                             AND PCCRECLI.DTDESCONTO IS NULL
                             AND PCCRECLI.DTESTORNO IS NULL
                             AND PCCRECLI.CODFILIAL IN (PCODFILIAL)
                        GROUP BY PCCRECLI.CODCLI
                               , PCCRECLI.CODFILIAL)
  LOOP
    /*INSERIR PCFINANC2*/
    PCFINANC2_GRAVAR( PDATAPROCESSADA                --PDATA
                    , CREDITO_CLIENTE.CODFILIAL      --PCODFILIAL
                    , 'CREDCLI'                      --PTIPODADO
                    , CREDITO_CLIENTE.CODCLI         --PCODIGON
                    , '0'                            --PCODIGOA
                    , CREDITO_CLIENTE.VLRTOTAL       --PVALOR
                    , SYSDATE                        --PDTGERACAO
                    , PCODROTINA                     --PCODROTINA
                    , PCODFUNC                       --PCODFUNC
                    , 0);                            --PVALOR2
  END LOOP;

  /*INVESTIMENTO ANALITICO*/
  FOR INVESTIMENTOS IN (SELECT PCLANC.CODCONTA
                             , SUM(VALOR) VLRTOTAL_ATIVO
                             , SUM(DECODE(PCLANC.DTPAGTO,NULL,VALOR,0)) VLRTOTAL_PASSIVO
                             , PCLANC.CODFILIAL
                          FROM PCLANC
                             , PCCONTA
                             , PCGRUPO
                         WHERE PCLANC.CODCONTA = PCCONTA.CODCONTA
                           AND PCCONTA.GRUPOCONTA = PCGRUPO.CODGRUPO
                           AND PCCONTA.INVESTIMENTO = 'S'
                           AND PCLANC.CODFILIAL IN (PCODFILIAL)
                      GROUP BY PCLANC.CODCONTA
                             , PCLANC.CODFILIAL
                       )
  LOOP
    /*INSERIR PCFINANC2*/
    PCFINANC2_GRAVAR( PDATAPROCESSADA              --PDATA
                    , INVESTIMENTOS.CODFILIAL      --PCODFILIAL
                    , 'INVEST'                     --PTIPODADO
                    , INVESTIMENTOS.CODCONTA       --PCODIGON
                    , '0'                          --PCODIGOA
                    , INVESTIMENTOS.VLRTOTAL_ATIVO --PVALOR
                    , SYSDATE                      --PDTGERACAO
                    , PCODROTINA                   --PCODROTINA
                    , PCODFUNC                     --PCODFUNC
                    , 0);

    /*INSERIR PCFINANC2*/
    PCFINANC2_GRAVAR( PDATAPROCESSADA                 --PDATA
                    , PCODFILIAL                      --PCODFILIAL
                    , 'INVESTP'                       --PTIPODADO
                    , INVESTIMENTOS.CODCONTA          --PCODIGON
                    , '0'                             --PCODIGOA
                    , INVESTIMENTOS.VLRTOTAL_PASSIVO  --PVALOR
                    , SYSDATE                         --PDTGERACAO
                    , PCODROTINA                      --PCODROTINA
                    , PCODFUNC                        --PCODFUNC
                    , 0);
  END LOOP;

  /*Titulos descontados vendor*/
  FOR TITULO_VENDOR IN (SELECT PCPREST.CODCOB
                             , SUM(PCPREST.VALOR) VLRTOTAL
                             , PCPREST.CODFILIAL
                          FROM PCPREST
                         WHERE PCPREST.DTPAG IS NULL
                           AND PCPREST.NUMTRANSVENDOR IS NOT NULL
                           AND PCPREST.DTFECHAVENDOR IS NOT NULL
                           AND PCPREST.CODFILIAL IN (PCODFILIAL)
                      GROUP BY PCPREST.CODCOB
                             , PCPREST.CODFILIAL
                       )
  LOOP
    PCFINANC2_GRAVAR(PDATAPROCESSADA                --PDATA
                    , TITULO_VENDOR.CODFILIAL       --PCODFILIAL
                    , 'VENDOR'                      --PTIPODADO
                    , 0                             --PCODIGON
                    , TITULO_VENDOR.CODCOB          --PCODIGOA
                    , TITULO_VENDOR.VLRTOTAL        --PVALOR
                    , SYSDATE                       --PDTGERACAO
                    , PCODROTINA                    --PCODROTINA
                    , PCODFUNC                      --PCODFUNC
                    , 0);                           --PVALOR2
  END LOOP;
  
    /*Titulos descontados vendor*/
  FOR TITULO_ANTECIPADO IN (SELECT PCPREST.CODCOB
                             , SUM(PCPREST.VALOR) VLRTOTAL
                             , PCPREST.CODFILIAL
                          FROM PCPREST
                         WHERE PCPREST.DTPAG IS NOT NULL
                           AND PCPREST.CODCOB IN ('TECH', 'SUPP') 
                           AND PCPREST.CODFILIAL IN (PCODFILIAL)
                      GROUP BY PCPREST.CODCOB
                             , PCPREST.CODFILIAL
                       )
  LOOP
    PCFINANC2_GRAVAR(PDATAPROCESSADA                --PDATA
                    , TITULO_ANTECIPADO.CODFILIAL       --PCODFILIAL
                    , 'VENDOR'                      --PTIPODADO
                    , 0                             --PCODIGON
                    , TITULO_ANTECIPADO.CODCOB          --PCODIGOA
                    , TITULO_ANTECIPADO.VLRTOTAL        --PVALOR
                    , SYSDATE                       --PDTGERACAO
                    , PCODROTINA                    --PCODROTINA
                    , PCODFUNC                      --PCODFUNC
                    , 0);                           --PVALOR2
  END LOOP;

    /*ESTOQUE CONSUMO INTERNO*/
  FOR ESTOQUECI IN (  SELECT (NVL(PCESTCIAP.QTESTGER, 0) * NVL(PCESTCIAP.VLCUSTOFINANCEIRO, 0)) VALOR, 
                           TO_CHAR(PCESTCIAP.CODPROD) CODIGO,
                           (SELECT SUBSTR(PCPRODCIAP.DESCRICAO,1,60) FROM PCPRODCIAP WHERE PCPRODCIAP.CODPROD = PCESTCIAP.CODPROD AND ROWNUM = 1)AS DESCRICAO,
                           PCESTCIAP.VLCUSTOFINANCEIRO VALORUNITARIO,
                           PCESTCIAP.QTESTGER QTDE,
                           PCESTCIAP.CODFILIAL
                        FROM PCESTCIAP
                        WHERE PCESTCIAP.CODFILIAL IN( PCODFILIAL )
                         AND EXISTS (SELECT 1
                                FROM PCMOVCIAP, PCLANC
                            WHERE (PCESTCIAP.CODPROD = PCMOVCIAP.CODPROD)
                                AND (PCMOVCIAP.TIPOMERC = 'CI')
                                AND (PCMOVCIAP.ROTINALANC IN ('3422', '3427'))
                                AND (PCLANC.CODCONTA =
                                    (SELECT VALOR
                                        FROM PCPARAMFILIAL
                                        WHERE NOME = 'CON_CODCLICONSUMIDOR'))
                                AND (PCMOVCIAP.NUMTRANSENT = PCLANC.NUMTRANSENT))
                         ORDER BY VALOR DESC)
  LOOP
    /*INSERIR PCFINANC2*/
    PCFINANC2_GRAVAR(PDATAPROCESSADA         --PDATA
                    , ESTOQUECI.CODFILIAL      --PCODFILIAL
                    , 'ESTOQUECI'              --PTIPODADO
                    , ESTOQUECI.CODIGO        --PCODIGON
                    , '0'                    --PCODIGOA
                    , ESTOQUECI.VALOR       --PVALOR
                    , SYSDATE                --PDTGERACAO
                    , PCODROTINA             --PCODROTINA
                    , PCODFUNC               --PCODFUNC
                    , 0);                    --PVALOR2
  END LOOP;

END GERAR_PCFINANC2;


procedure PCFINANC2_GRAVAR( PDATA DATE
                          , PCODFILIAL VARCHAR2
                          , PTIPODADO VARCHAR2
                          , PCODIGON NUMBER
                          , PCODIGOA VARCHAR2
                          , PVALOR NUMBER
                          , PDTGERACAO DATE
                          , PCODROTINA NUMBER
                          , PCODFUNC NUMBER
                          , PVALOR2 NUMBER
                          , PPARMULTIFILIALCAIXABANCO3882 VARCHAR2 DEFAULT 'N'
                          , PLISTAFILIAIS VARCHAR2 DEFAULT NULL) IS
begin
  INSERT INTO PCFINANC2( DATA
                       , CODFILIAL
                       , TIPODADO
                       , CODIGON
                       , CODIGOA
                       , VALOR
                       , DTGERACAO
                       , CODROTINA
                       , CODFUNC
                       , VALOR2
                       , PARMULTIFILIALCAIXABANCO3882
                       , LISTAFILIAISBANCOCAIXA) --HIS.02205.2016. PARA BANCO/BAIXA NA FILIAL 99, DEVERÁ GRAVAR AS FILIAIS VINCULADAS AOS MESMOS.
       VALUES( PDATA
             , PCODFILIAL
             , PTIPODADO
             , PCODIGON
             , PCODIGOA
             , PVALOR
             , PDTGERACAO
             , PCODROTINA
             , PCODFUNC
             , PVALOR2
             , PPARMULTIFILIALCAIXABANCO3882
             , NVL(PLISTAFILIAIS,PCODFILIAL));
end PCFINANC2_GRAVAR;


PROCEDURE ATUALIZARSALDOSFINANCEIROS (
  PCODFILIAL                VARCHAR2,
  PCODROTINA                NUMBER,
  PCODFUNC                  NUMBER,
  PDATAPROCESSADA           DATE,
  PATUALIZARDTPROCESSAMENTO VARCHAR2
) IS

  VCODFILIAL      VARCHAR2(4000);
  VCOUNT          NUMBER(10);
  VDATAPROCESSADA DATE;

  PROCEDURE UPDATES_FILIAIS (
    VCODFILIAL                VARCHAR2,
    VCOUNT                    OUT NUMBER,
    VDATAPROCESSADA           OUT DATE,
    PCODROTINA                NUMBER,
    PCODFUNC                  NUMBER,
    PDATAPROCESSADA           DATE,
    PATUALIZARDTPROCESSAMENTO VARCHAR2
  ) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN

      /*Cursor com filiais para execução*/
      FOR FILIAIS IN (
          SELECT
              CODIGO
          FROM
              PCFILIAL
          WHERE
              PCFILIAL.CODIGO IN (
                  SELECT
                      TRIM(REGEXP_SUBSTR(VCODFILIAL, '[^,|^''''|^, ''''|^,'''']+', 1, LEVEL))
                  FROM
                      DUAL
                  CONNECT BY
                      TRIM(REGEXP_SUBSTR(VCODFILIAL, '[^,|^''''|^, ''''|^,'''']+', 1, LEVEL)) IS NOT NULL
              )
              OR ( PCFILIAL.CODIGO IN ( DECODE(VCODFILIAL, '99', PCFILIAL.CODIGO, VCODFILIAL) ) )
      ) LOOP /*Inicio loop Filiais*/

          /*Não deve executar caso ja exista*/
          SELECT
              COUNT(1)
          INTO VCOUNT
          FROM
              PCFINANC2
          WHERE
                  DATA = TRUNC(PDATAPROCESSADA)
              AND CODROTINA IN ( 504, 820 )
              AND CODFILIAL = FILIAIS.CODIGO
              AND ROWNUM = 1;

          /*Obtendo data para atualização PCCONSUM, PCPARAMFILIAL*/
          IF PATUALIZARDTPROCESSAMENTO = 'S' THEN
            SELECT
              TRUNC(DTPROCESSAMENTO + 1)
            INTO VDATAPROCESSADA
            FROM
              PCCONSUM;

          END IF;

          IF VCOUNT <= 0 THEN
            /*Atualizando titulos*/
            UPDATE PCPREST
            SET
              CODCOB = NVL(CODCOBORIG, CODCOB)
            WHERE
                  CODCOB = 'DESD'
              AND DTPAG IS NULL
              AND VPAGO IS NULL
              AND PCPREST.CODFILIAL IN ( FILIAIS.CODIGO );

              /*Inicio feração dados PCFINANC2*/
              GERAR_PCFINANC2(FILIAIS.CODIGO, PCODROTINA, PCODFUNC, PDATAPROCESSADA);

              /*final feração dados PCFINANC2*/
              GERAR_PCFINANC(FILIAIS.CODIGO, PCODROTINA, PCODFUNC, PDATAPROCESSADA);

          END IF;

          /*Incluindo no log a execução*/
          IF (
                ( VCOUNT <= 0 )
            AND ( PATUALIZARDTPROCESSAMENTO = 'S' )
          ) THEN
              INSERT INTO PCLOGFINANC (
                CODFILIAL,
                DATA,
                DTGERACAO,
                CODFUNC,
                CODROTINA,
                DATAHORA
              ) VALUES (
                FILIAIS.CODIGO,
                VDATAPROCESSADA - 1,
                TRUNC(SYSDATE),
                PCODFUNC,
                PCODROTINA,
                SYSDATE
              );

          END IF;

          COMMIT;-- AUTONOMOUS_TRANSACTION

      END LOOP;

  END UPDATES_FILIAIS;

BEGIN

    /*Caso filial seja vazia ou 99 realizar para todas filiais */
    VCODFILIAL := ( CASE
        WHEN TRIM(PCODFILIAL) IS NULL THEN
            '99'
        ELSE PCODFILIAL
    END );

    UPDATES_FILIAIS(
        VCODFILIAL
      , VCOUNT
      , VDATAPROCESSADA
      , PCODROTINA
      , PCODFUNC
      , PDATAPROCESSADA
      , PATUALIZARDTPROCESSAMENTO
    );

    /*Somente atualizar caso execute o processo*/
    IF PATUALIZARDTPROCESSAMENTO = 'S' THEN
        UPDATE PCCONSUM
        SET
          DTPROCESSAMENTO = VDATAPROCESSADA;
        UPDATE PCPARAMFILIAL
        SET
          PCPARAMFILIAL.VALOR = TO_CHAR(VDATAPROCESSADA, 'DD/MM/YYYY')
        WHERE
          NOME = 'CON_DTPROCESSAMENTO';

    END IF;

END ATUALIZARSALDOSFINANCEIROS;

/*Chamadas sem código filial para compatibilidade com 504 e outros processos que não usam 820*/
PROCEDURE P_PC_ZERARACUMVENDADIA(-- Parametro de saida
                                 PVC2MENSSAGEN OUT VARCHAR2) is
BEGIN
  P_PC_ZERARACUMVENDADIA(
    '99',
    PVC2MENSSAGEN);
END P_PC_ZERARACUMVENDADIA;


--Armazenar Saldos Estoque  (P_PC_ARMAZENARSALDOSESTOQUE)
PROCEDURE P_PC_ARMAZENARSALDOSESTOQUE(-- Parametros de entrada
                                      PDTPROCESSAMENTO IN DATE,
                                      -- Parametro de saida
                                      PVC2MENSSAGEN OUT VARCHAR2) is
BEGIN
    P_PC_ARMAZENARSALDOSESTOQUE(
    PDTPROCESSAMENTO,
    '99',
    PVC2MENSSAGEN);
END P_PC_ARMAZENARSALDOSESTOQUE;

--Armazenar Saldos Estoque de Lote  (P_PC_ARMAZENASALDOESTOQUELOTE)
PROCEDURE P_PC_ARMAZENASALDOESTOQUELOTE(-- Parametros de entrada
                                        PDTPROCESSAMENTO IN DATE,
                                        -- Parametro de saida
                                        PVC2MENSSAGEN OUT VARCHAR2) is
BEGIN
  P_PC_ARMAZENASALDOESTOQUELOTE(
    PDTPROCESSAMENTO,
    '99',
    PVC2MENSSAGEN);
END P_PC_ARMAZENASALDOESTOQUELOTE;

--Recálculo do %Venda para Pessoa Física  (P_PC_RECALCPERCENTVENDAPF)
PROCEDURE P_PC_RECALCPERCENTVENDAPF(-- Parametro de saida
                                    PVC2MENSSAGEN OUT VARCHAR2) is
BEGIN
  P_PC_RECALCPERCENTVENDAPF(
    '99',
    PVC2MENSSAGEN);
END P_PC_RECALCPERCENTVENDAPF;

PROCEDURE P_CALC_SALDO_CONTASRECEBER(PSCODFILIAL VARCHAR2,
                                     PNCODROTINA NUMBER,
                                     PNCODFUNC NUMBER,
                                     PDDATAPROCESSADA  DATE) IS
    VS_SQL_INSERT_PCFINANC2  VARCHAR2(10000);
    VS_SQL_PCFINANC2         VARCHAR2(10000);
    VS_SQL_INSERT_PCFINANC3  VARCHAR2(10000);
    VS_SQL_PCFINANC3         VARCHAR2(10000);
    VS_SQL_CORPO             VARCHAR2(10000);
    VCOUNT                   NUMBER(10);
    VDATATESTADA             DATE;
BEGIN  
    BEGIN  
        SELECT COUNT(DISTINCT F.DATAREFERENCIA), TRUNC(F.DATAGERACAO)
        INTO VCOUNT, VDATATESTADA
        FROM PCFINANC3PREST F
        WHERE F.DATAGERACAO >= TRUNC(SYSDATE)
        AND F.CODFILIAL = PSCODFILIAL
        GROUP BY TRUNC(F.DATAGERACAO);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN      
         VCOUNT := 0;
         VDATATESTADA := SYSDATE;
    END;

    IF VCOUNT > 7 THEN
      raise_application_error(-20001,'Foram gerados registros de '||to_char(VCOUNT)||' dias, apartir da data '||to_char(TRUNC(VDATATESTADA))||'.');
    END IF;
    
    VS_SQL_INSERT_PCFINANC2 := F_CABECALHO_INSERT_PCFINANC2;

    VS_SQL_INSERT_PCFINANC3 := 'INSERT INTO PCFINANC3PREST
                                    (DATAREFERENCIA,
                                     DATAGERACAO,
                                     CODROTINAGERACAO,
                                     TIPODADO,
                                     CODROTINA,
                                     CODFILIAL,
                                     NUMTRANSVENDA,
                                     DUPLIC,
                                     PREST,
                                     VALOR,
                                     CODCOB,
                                     DTVENC,
                                     DTPAG,
                                     VPAGO,
                                     TXPERM,
                                     DTEMISSAO,
                                     VALORDESC,
                                     DTDESD,
                                     DTBAIXA,
                                     DTCANCEL,
                                     DTFECHA,
                                     NUMTRANS,
                                     DTDEVOL,
                                     VLDEVOL,
                                     DTESTORNO,
                                     VALORMULTA) ';

    VS_SQL_CORPO := ' FROM PCPREST,
                          PCCOB
                    WHERE PCPREST.CODCOB = PCCOB.CODCOB(+)
                      AND PCPREST.CODFILIAL IN (''' || PSCODFILIAL || ''')
                      AND PCPREST.DTPAG IS NULL ';

    VS_SQL_PCFINANC2 := 'SELECT '''|| PDDATAPROCESSADA ||''' DATA,
                                PCPREST.CODFILIAL,
                                ''CRECEBER'' TIPODADO,
                                0 CODIGON,
                                PCPREST.CODCOB CODIGOA,
                                SUM(VALOR) VALOR,
                                SYSDATE DTGERACAO, '
                                || PNCODROTINA ||' CODROTINA, '
                                || PNCODFUNC ||' CODFUNC,
                                0 VALOR2,
                                ''N'' PARMULTIFILIALCAIXABANCO3882,
                                PCPREST.CODFILIAL LISTAFILIAISBANCOCAIXA'
                                || VS_SQL_CORPO ||
                        ' GROUP BY PCPREST.CODCOB,
                                   PCCOB.COBRANCA,
                                   PCPREST.CODFILIAL' ;

    VS_SQL_PCFINANC3 := 'SELECT DISTINCT /*+ORDERED*/ '''
                                || PDDATAPROCESSADA || ''' DATAREFERENCIA,
                                SYSDATE DATAGERACAO, '
                                || PNCODROTINA || ' CODROTINAGERACAO,
                                ''CRECEBER'' TIPODADO,
                                PCPREST.ROTINALANC CODROTINA,
                                PCPREST.CODFILIAL,
                                PCPREST.NUMTRANSVENDA,
                                PCPREST.DUPLIC,
                                PCPREST.PREST,
                                PCPREST.VALOR,
                                PCPREST.CODCOB,
                                PCPREST.DTVENC,
                                PCPREST.DTPAG,
                                PCPREST.VPAGO,
                                PCPREST.TXPERM,
                                PCPREST.DTEMISSAO,
                                PCPREST.VALORDESC,
                                PCPREST.DTDESD,
                                PCPREST.DTBAIXA,
                                PCPREST.DTCANCEL,
                                PCPREST.DTFECHA,
                                PCPREST.NUMTRANS,
                                PCPREST.DTDEVOL,
                                PCPREST.VLDEVOL,
                                PCPREST.DTESTORNO,
                                PCPREST.VALORMULTA ' ||
                                VS_SQL_CORPO;

    /*CONTAS A RECEBER ANALÍTICO --  ATIVO*/
    EXECUTE IMMEDIATE VS_SQL_INSERT_PCFINANC2 || ' ' || VS_SQL_PCFINANC2;
    IF (PNCODROTINA <> 117) AND (VCOUNT = 0) THEN
      EXECUTE IMMEDIATE VS_SQL_INSERT_PCFINANC3 || ' ' || VS_SQL_PCFINANC3;
    END IF;
END P_CALC_SALDO_CONTASRECEBER;

PROCEDURE P_CALC_SALDO_VERBAS(PSCODFILIAL VARCHAR2,
                              PNCODROTINA NUMBER,
                              PNCODFUNC NUMBER,
                              PDDATAPROCESSADA  DATE) IS
    VS_SQL_INSERT_PCFINANC2  VARCHAR2(10000);
    VS_SQL_PCFINANC2         VARCHAR2(10000);
    VS_SQL_INSERT_PCFINANC3  VARCHAR2(10000);
    VS_SQL_PCFINANC3         VARCHAR2(10000);
    VS_SQL_CORPO             VARCHAR2(10000);
    VCOUNT                   NUMBER(10);
    VDATATESTADA             DATE;
BEGIN
    BEGIN
      SELECT COUNT(DISTINCT F.DATAREFERENCIA), TRUNC(F.DATAGERACAO)
      INTO VCOUNT, VDATATESTADA
      FROM PCFINANC3VERBAS F
      WHERE F.DATAGERACAO >= TRUNC(SYSDATE)
      AND F.CODFILIAL = PSCODFILIAL
      GROUP BY TRUNC(F.DATAGERACAO);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN      
         VCOUNT := 0;
         VDATATESTADA := SYSDATE;
    END;
    
    
    IF VCOUNT > 7 THEN
      raise_application_error(-20001,'Foram gerados registros de '||to_char(VCOUNT)||' dias, apartir da data '||to_char(TRUNC(VDATATESTADA))||'.');
    END IF;
    
    VCOUNT := 0;
    
    VS_SQL_INSERT_PCFINANC2 := F_CABECALHO_INSERT_PCFINANC2;

    VS_SQL_INSERT_PCFINANC3 := 'INSERT INTO PCFINANC3VERBAS
                                  (DATAREFERENCIA,
                                   DATAGERACAO,
                                   CODROTINAGERACAO,
                                   CODFILIAL,
                                   TIPODADO,
                                   CODFORNEC,
                                   CODFORNECPRINC,
                                   DTEMISSAO,
                                   DTVENC,
                                   TIPO,
                                   VALOR,
                                   NUMVERBA,
                                   CODROTINA,
                                   NUMTRANSENT,
                                   NUMTRANSCRFOR) ';

    VS_SQL_CORPO := ' FROM PCFILIAL,
                          (SELECT NVL(PCFORNEC.CODFORNECPRINC, 0) CODFORNECPRINC,
                                  DECODE(NVL(PCFORNEC.CODFORNECPRINC, 0),
                                         0,
                                         PCFORNEC.CODFORNEC,
                                         PCFORNEC.CODFORNECPRINC) CODFORNEC,
                                  NVL(PCMOVCRFOR.NUMVERBA, 0) NUMVERBA,
                                  NVL(PCVERBA.DTEMISSAO, PCMOVCRFOR.DATA) DTEMISSAO,
                                  PCVERBA.DTVENC,
                                  PCVERBA.REFERENCIA,
                                  PCVERBA.REFERENCIA1,
                                  PCMOVCRFOR.TIPO,
                                  (SELECT F.FORNECEDOR
                                     FROM PCFORNEC F
                                    WHERE F.CODFORNEC = PCFORNEC.CODFORNECPRINC) FORNECEDOR,
                                  (DECODE(PCMOVCRFOR.TIPO,
                                          ''D'',
                                          NVL(PCMOVCRFOR.VALOR, 0),
                                          0) -
                                   DECODE(PCMOVCRFOR.TIPO,
                                          ''C'',
                                          NVL(PCMOVCRFOR.VALOR, 0),
                                          0)) VALOR,
                                   PCMOVCRFOR.ROTINALANC,
                                   PCMOVCRFOR.NUMTRANSENT,
                                   PCMOVCRFOR.NUMTRANSCRFOR
                              FROM PCMOVCRFOR,
                                   PCVERBA,
                                   PCFORNEC
                             WHERE PCMOVCRFOR.NUMVERBA = PCVERBA.NUMVERBA(+)
                               AND PCMOVCRFOR.CODFORNEC = PCFORNEC.CODFORNEC
                               AND PCFORNEC.CODFORNECPRINC IS NOT NULL
                               AND PCMOVCRFOR.CODFILIAL IN (''' || PSCODFILIAL || ''')
                             UNION ALL
                            SELECT NVL(PCFORNEC.CODFORNECPRINC, 0) CODFORNECPRINC,
                                   PCFORNEC.CODFORNEC CODFORNEC,
                                   NVL(PCMOVCRFOR.NUMVERBA, 0) NUMVERBA,
                                   NVL(PCVERBA.DTEMISSAO, PCMOVCRFOR.DATA) DTEMISSAO,
                                   PCVERBA.DTVENC,
                                   PCVERBA.REFERENCIA,
                                   PCVERBA.REFERENCIA1,
                                   PCMOVCRFOR.TIPO,
                                   (SELECT F.FORNECEDOR
                                      FROM PCFORNEC F
                                     WHERE F.CODFORNEC = PCFORNEC.CODFORNEC) FORNECEDOR,
                                   (DECODE(PCMOVCRFOR.TIPO,
                                           ''D'',
                                           NVL(PCMOVCRFOR.VALOR, 0),
                                           0) -
                                    DECODE(PCMOVCRFOR.TIPO,
                                           ''C'',
                                           NVL(PCMOVCRFOR.VALOR, 0),
                                           0)) VALOR,
                                    PCMOVCRFOR.ROTINALANC,
                                    PCMOVCRFOR.NUMTRANSENT,
                                    PCMOVCRFOR.NUMTRANSCRFOR
                               FROM PCMOVCRFOR,
                                    PCVERBA,
                                    PCFORNEC
                              WHERE PCMOVCRFOR.NUMVERBA = PCVERBA.NUMVERBA(+)
                                AND PCMOVCRFOR.CODFORNEC = PCFORNEC.CODFORNEC
                                AND PCFORNEC.CODFORNECPRINC IS NULL
                                AND PCMOVCRFOR.CODFILIAL IN (''' || PSCODFILIAL || ''')
                              ORDER BY CODFORNEC,
                                       DTEMISSAO,
                                       VALOR DESC) FORNECEDORES
                    WHERE PCFILIAL.CODIGO = ''' || PSCODFILIAL || ''' ';

    VS_SQL_PCFINANC2 := ' SELECT ''' || PDDATAPROCESSADA || ''' DATA,
                                PCFILIAL.CODIGO CODFILIAL,
                                ''CRFORNEC'' TIPODADO,
                                FORNECEDORES.CODFORNEC CODDIGON,
                                ''0'',
                                SUM(ROUND(FORNECEDORES.VALOR, 2)) VALOR,
                                SYSDATE DTGERACAO, '
                                || PNCODROTINA || ' CODROTINA, '
                                || PNCODFUNC || ' CODFUNC,
                                0 VALOR2,
                                ''N'' PARMULTIFILIALCAIXABANCO3882,
                                PCFILIAL.CODIGO LISTAFILIAISBANCOCAIXA '
                                || VS_SQL_CORPO ||
                        ' GROUP BY FORNECEDORES.CODFORNEC,
                                   PCFILIAL.CODIGO
                          ORDER BY PCFILIAL.CODIGO,
                                   FORNECEDORES.CODFORNEC ' ;

    VS_SQL_PCFINANC3 := ' SELECT ''' || PDDATAPROCESSADA || ''' DATAREFERENCIA,
                                SYSDATE DATAGERACAO, '
                                || PNCODROTINA || ' CODROTINAGERACAO,
                                PCFILIAL.CODIGO CODFILIAL,
                                ''CRFORNEC'' TIPODADO,
                                FORNECEDORES.CODFORNEC,
                                FORNECEDORES.CODFORNECPRINC,
                                FORNECEDORES.DTEMISSAO,
                                FORNECEDORES.DTVENC,
                                FORNECEDORES.TIPO,
                                FORNECEDORES.VALOR,
                                FORNECEDORES.NUMVERBA,
                                FORNECEDORES.ROTINALANC CODROTINA,
                                FORNECEDORES.NUMTRANSENT,
                                FORNECEDORES.NUMTRANSCRFOR '
                                || VS_SQL_CORPO ||
                        ' ORDER BY PCFILIAL.CODIGO,
                                   FORNECEDORES.CODFORNEC ';

    /*CONTAS A RECEBER ANALÍTICO --  ATIVO*/
    EXECUTE IMMEDIATE VS_SQL_INSERT_PCFINANC2 || ' ' || VS_SQL_PCFINANC2;

    IF (PNCODROTINA <> 117) AND (VCOUNT = 0) THEN
      EXECUTE IMMEDIATE VS_SQL_INSERT_PCFINANC3 || ' ' || VS_SQL_PCFINANC3;
    END IF;
END P_CALC_SALDO_VERBAS;

PROCEDURE P_CALC_SALDO_CONTASPAGARFORNEC(PSCODFILIAL VARCHAR2,
                                         PNCODROTINA NUMBER,
                                         PNCODFUNC NUMBER,
                                         PDDATAPROCESSADA  DATE,
                                         PSEXIBIRSALDOBRUTOFORNEC VARCHAR2) IS
    VS_SQL_INSERT_PCFINANC2  VARCHAR2(10000);
    VS_SQL_PCFINANC2         VARCHAR2(10000);
    VS_SQL_INSERT_PCFINANC3  VARCHAR2(10000);
    VS_SQL_PCFINANC3         VARCHAR2(10000);
    VS_SQL_CORPO             VARCHAR2(10000);
    VCOUNT                   NUMBER(10);
    VDATATESTADA             DATE;
BEGIN
    BEGIN
        SELECT COUNT(DISTINCT F.DATAREFERENCIA), TRUNC(F.DATAGERACAO)
        INTO VCOUNT, VDATATESTADA
        FROM PCFINANC3LANCFORNEC F
        WHERE F.DATAGERACAO >= TRUNC(SYSDATE)
        AND F.CODFILIAL = PSCODFILIAL
        GROUP BY TRUNC(F.DATAGERACAO);
        EXCEPTION
    WHEN NO_DATA_FOUND THEN  
         VCOUNT := 0;
         VDATATESTADA := SYSDATE;
    END;

    IF VCOUNT > 7 THEN
       raise_application_error(-20001,'Foram gerados registros de '||to_char(VCOUNT)||' dias, apartir da data '||to_char(TRUNC(VDATATESTADA))||'.');
    END IF;

    VS_SQL_INSERT_PCFINANC2 := F_CABECALHO_INSERT_PCFINANC2;

    VS_SQL_INSERT_PCFINANC3 := 'INSERT INTO PCFINANC3LANCFORNEC
                                  (DATAREFERENCIA,
                                   DATAGERACAO,
                                   CODROTINAGERACAO,
                                   CODFILIAL,
                                   TIPODADO,
                                   RECNUM,
                                   RECNUMPRINC,
                                   DTLANC,
                                   CODGRUPO,
                                   CODCONTA,
                                   CODFORNEC,
                                   NUMNOTA,
                                   DUPLIC,
                                   VALOR,
                                   DTVENC,
                                   VPAGO,
                                   DTPAGTO,
                                   TIPOPARCEIRO,
                                   DTDESD,
                                   VALORDEV,
                                   TXPERM,
                                   DESCONTOFIN,
                                   NUMBORDERO,
                                   VPAGOBORDERO,
                                   CADASTRADO,
                                   CODROTINA) ';

    VS_SQL_CORPO := ' FROM (SELECT ''' || PDDATAPROCESSADA || ''' DATAREFERENCIA,
                                  SYSDATE DATAGERACAO, '
                                  || PNCODROTINA || ' CODROTINAGERACAO,
                                  PCEST.CODFILIAL,
                                  ''CPAGAR'' TIPODADO,
                                  0 RECNUM,
                                  0 RECNUMPRINC,
                                  TRUNC(SYSDATE) DTLANC,
                                  0 CODGRUPO,
                                  0 CODCONTA,
                                  PCPRODUT.CODFORNEC,
                                  0 NUMNOTA,
                                  ''0'' DUPLIC,
                                  0 VALOR,
                                  NULL DTVENC,
                                  0 VPAGO,
                                  NULL DTPAGTO,
                                  ''X'' TIPOPARCEIRO,
                                  NULL DTDESD,
                                  0 VALORDEV,
                                  0 TXPERM,
                                  0 DESCONTOFIN,
                                  0 NUMBORDERO,
                                  0 VPAGOBORDERO,
                                  (NVL(PCEST.QTESTGER, 0) * NVL(PCEST.CUSTOREP, 0)) VLESTOQUE,
                                  ''S'' CADASTRADO,
                                  NULL CODROTINACAD
                             FROM PCPRODUT,
                                  PCEST,
                                  PCDEPTO
                            WHERE (PCPRODUT.CODPROD = PCEST.CODPROD)
                              AND (PCPRODUT.CODEPTO = PCDEPTO.CODEPTO)
                              AND (NVL(PCDEPTO.TIPOMERC, ''XX'') NOT IN (''IM'', ''CI''))
                              AND (NVL(PCEST.QTESTGER, 0) <> 0)
                              AND PCEST.CODFILIAL IN (''' || PSCODFILIAL || ''')
                            UNION ALL
                           SELECT ''' || PDDATAPROCESSADA || ''' DATAREFERENCIA,
                                  SYSDATE DATAGERACAO, '
                                  || PNCODROTINA || ' CODROTINAGERACAO,
                                  PCLANC.CODFILIAL,
                                  ''CPAGAR'' TIPODADO,
                                  PCLANC.RECNUM,
                                  PCLANC.RECNUMPRINC,
                                  PCLANC.DTLANC,
                                  PCCONTA.GRUPOCONTA CODGRUPO,
                                  PCLANC.CODCONTA,
                                  PCLANC.CODFORNEC,
                                  PCLANC.NUMNOTA,
                                  SUBSTR(PCLANC.DUPLIC, 1, 1) DUPLIC,
                                  DECODE(''' || PSEXIBIRSALDOBRUTOFORNEC || ''',
                                         ''S'',
                                         NVL(PCLANC.VALOR, 0),
                                         NVL((NVL(PCLANC.VALOR, 0) - NVL(PCLANC.DESCONTOFIN, 0) +
                                         NVL(PCLANC.TXPERM, 0) - NVL(PCLANC.VALORDEV, 0)), 0)) VALOR,
                                  PCLANC.DTVENC,
                                  PCLANC.VPAGO,
                                  PCLANC.DTPAGTO,
                                  PCLANC.TIPOPARCEIRO,
                                  PCLANC.DTDESD,
                                  PCLANC.VALORDEV,
                                  PCLANC.TXPERM,
                                  PCLANC.DESCONTOFIN,
                                  PCLANC.NUMBORDERO,
                                  PCLANC.VPAGOBORDERO,
                                  0 VLESTOQUE,
                                  ''S'' CADASTRADO,
                                  PCLANC.CODROTINACAD
                             FROM PCLANC,
                                  PCCONTA
                            WHERE PCLANC.CODCONTA = PCCONTA.CODCONTA
                              AND EXISTS (SELECT 1
                                            FROM PCCONSUM
                                           WHERE ((PCLANC.CODCONTA = PCCONSUM.CODCONTFOR)
                                              OR (PCLANC.CODCONTA = PCCONSUM.CODCONTFRE)
                                              OR (PCLANC.CODCONTA = PCCONSUM.CODCONTOUT)))
                              AND PCLANC.DTPAGTO IS NULL
                              AND PCLANC.CODFILIAL IN (''' || PSCODFILIAL || ''')
                            UNION ALL
                           SELECT ''' || PDDATAPROCESSADA || ''' DATAREFERENCIA,
                                  SYSDATE DATAGERACAO, '
                                  || PNCODROTINA || ' CODROTINAGERACAO,
                                  PCLANC.CODFILIAL,
                                  ''CPAGAR'' TIPODADO,
                                  PCLANC.RECNUM,
                                  PCLANC.RECNUMPRINC,
                                  PCLANC.DTLANC,
                                  PCCONTA.GRUPOCONTA CODGRUPO,
                                  PCLANC.CODCONTA,
                                  TO_NUMBER(-1) CODFORNEC,
                                  PCLANC.NUMNOTA,
                                  SUBSTR(PCLANC.DUPLIC, 1, 1) DUPLIC,
                                  DECODE(''' || PSEXIBIRSALDOBRUTOFORNEC || ''',
                                         ''S'',
                                         NVL(PCLANC.VALOR, 0),
                                         NVL((NVL(PCLANC.VALOR, 0) - NVL(PCLANC.DESCONTOFIN, 0) +
                                         NVL(PCLANC.TXPERM, 0) - NVL(PCLANC.VALORDEV, 0)), 0)) VALOR,
                                  PCLANC.DTVENC,
                                  PCLANC.VPAGO,
                                  PCLANC.DTPAGTO,
                                  PCLANC.TIPOPARCEIRO,
                                  PCLANC.DTDESD,
                                  PCLANC.VALORDEV,
                                  PCLANC.TXPERM,
                                  PCLANC.DESCONTOFIN,
                                  PCLANC.NUMBORDERO,
                                  PCLANC.VPAGOBORDERO,
                                  0 VLESTOQUE,
                                  ''N'' CADASTRADO,
                                  PCLANC.CODROTINACAD
                             FROM PCLANC,
                                  PCCONTA,
                                  PCFORNEC
                            WHERE EXISTS (SELECT 1
                                            FROM PCCONSUM
                                           WHERE ((PCLANC.CODCONTA = PCCONSUM.CODCONTFOR)
                                              OR (PCLANC.CODCONTA = PCCONSUM.CODCONTFRE)
                                              OR (PCLANC.CODCONTA = PCCONSUM.CODCONTOUT)))
                              AND PCLANC.DTPAGTO IS NULL
                              AND PCLANC.CODFORNEC = PCFORNEC.CODFORNEC(+)
                              AND PCLANC.CODCONTA = PCCONTA.CODCONTA
                              AND PCFORNEC.CODFORNEC IS NULL
                              AND PCLANC.CODFILIAL IN (''' || PSCODFILIAL || ''')) CONTAS ';

    VS_SQL_PCFINANC2 := ' SELECT ''' || PDDATAPROCESSADA || ''' DATA,
                                CONTAS.CODFILIAL,
                                ''CPAGAR'' TIPODADO,
                                CONTAS.CODFORNEC,
                                ''0'' CODIGOA,
                                SUM(CONTAS.VALOR) VALOR,
                                SYSDATE DTGERACAO, '
                                || PNCODROTINA || ' CODROTINA, '
                                || PNCODFUNC || ' CODFUNC,
                                0 VALOR2,
                                ''N'' PARMULTIFILIALCAIXABANCO3882,
                                CONTAS.CODFILIAL LISTAFILIAISBANCOCAIXA '
                                || VS_SQL_CORPO ||
                         ' JOIN PCFORNEC F
                             ON F.CODFORNEC = CONTAS.CODFORNEC
                          GROUP BY CONTAS.CODFILIAL,
                                   CONTAS.CODFORNEC
                         --HAVING SUM(NVL(CONTAS.VALOR, 0)) <> 0
                          ORDER BY VALOR DESC ' ;

    VS_SQL_PCFINANC3 := ' SELECT DISTINCT CONTAS.DATAREFERENCIA,
                                          CONTAS.DATAGERACAO,
                                          CONTAS.CODROTINAGERACAO,
                                          CONTAS.CODFILIAL,
                                          CONTAS.TIPODADO,
                                          CONTAS.RECNUM,
                                          CONTAS.RECNUMPRINC,
                                          CONTAS.DTLANC,
                                          CONTAS.CODGRUPO,
                                          CONTAS.CODCONTA,
                                          CONTAS.CODFORNEC,
                                          CONTAS.NUMNOTA,
                                          CONTAS.DUPLIC,
                                          CONTAS.VALOR,
                                          CONTAS.DTVENC,
                                          CONTAS.VPAGO,
                                          CONTAS.DTPAGTO,
                                          CONTAS.TIPOPARCEIRO,
                                          CONTAS.DTDESD,
                                          CONTAS.VALORDEV,
                                          CONTAS.TXPERM,
                                          CONTAS.DESCONTOFIN,
                                          CONTAS.NUMBORDERO,
                                          CONTAS.VPAGOBORDERO,
                                          CONTAS.CADASTRADO,
                                          CONTAS.CODROTINACAD '
                                || VS_SQL_CORPO ||
                          ' JOIN PCFORNEC F
                              ON F.CODFORNEC = CONTAS.CODFORNEC
                           --WHERE CONTAS.VALOR <> 0
                           ORDER BY VALOR DESC';

    /*CONTAS A RECEBER ANALÍTICO --  ATIVO*/
    EXECUTE IMMEDIATE VS_SQL_INSERT_PCFINANC2 || ' ' || VS_SQL_PCFINANC2;

    IF (PNCODROTINA <> 117) AND (VCOUNT = 0) THEN
      EXECUTE IMMEDIATE VS_SQL_INSERT_PCFINANC3 || ' ' || VS_SQL_PCFINANC3;
    END IF;
END P_CALC_SALDO_CONTASPAGARFORNEC;

PROCEDURE P_CALC_SALDO_CONTASPAGAROUTROS(PSCODFILIAL VARCHAR2,
                                         PNCODROTINA NUMBER,
                                         PNCODFUNC NUMBER,
                                         PDDATAPROCESSADA  DATE,
                                         PSEXIBIRSALDOBRUTOFORNEC VARCHAR2) IS
    VS_SQL_INSERT_PCFINANC2  VARCHAR2(10000);
    VS_SQL_PCFINANC2         VARCHAR2(10000);
    VS_SQL_INSERT_PCFINANC3  VARCHAR2(10000);
    VS_SQL_PCFINANC3         VARCHAR2(10000);
    VS_SQL_CORPO             VARCHAR2(10000);
    VCOUNT                   NUMBER(10);
    VDATATESTADA             DATE;
BEGIN
        BEGIN
            SELECT COUNT(DISTINCT F.DATAREFERENCIA), TRUNC(F.DATAGERACAO)
            INTO VCOUNT, VDATATESTADA
            FROM PCFINANC3LANCOUTROS F
            WHERE F.DATAGERACAO >= TRUNC(SYSDATE)
            AND F.CODFILIAL = PSCODFILIAL
            GROUP BY TRUNC(F.DATAGERACAO);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN      
         VCOUNT := 0;
         VDATATESTADA := SYSDATE;
    END;

    IF VCOUNT > 7 THEN
      raise_application_error(-20001,'Foram gerados registros de '||to_char(VCOUNT)||' dias, apartir da data '||to_char(TRUNC(VDATATESTADA))||'.');
    END IF;  
    
    VS_SQL_INSERT_PCFINANC2 := F_CABECALHO_INSERT_PCFINANC2;

    VS_SQL_INSERT_PCFINANC3 := 'INSERT INTO PCFINANC3LANCOUTROS
                                  (DATAREFERENCIA,
                                   DATAGERACAO,
                                   CODROTINAGERACAO,
                                   CODFILIAL,
                                   TIPODADO,
                                   RECNUM,
                                   RECNUMPRINC,
                                   DTLANC,
                                   CODGRUPO,
                                   CODCONTA,
                                   CODFORNEC,
                                   NUMNOTA,
                                   DUPLIC,
                                   VALOR,
                                   DTVENC,
                                   VPAGO,
                                   DTPAGTO,
                                   TIPOPARCEIRO,
                                   DTDESD,
                                   VALORDEV,
                                   TXPERM,
                                   DESCONTOFIN,
                                   NUMBORDERO,
                                   VPAGOBORDERO,
                                   INVESTIMENTO) ';

    VS_SQL_CORPO := ' FROM PCLANC,
                           PCCONTA
                     WHERE PCLANC.TIPOPARCEIRO = ''F''
                       AND PCLANC.TIPOLANC = ''C''
                       AND PCLANC.CODCONTA = PCCONTA.CODCONTA
                       AND PCLANC.DTPAGTO IS NULL
                       AND PCLANC.VPAGOBORDERO IS NULL
                       AND NVL(PCCONTA.INVESTIMENTO, ''N'') <> ''S''
                       AND PCLANC.CODFILIAL IN (''' || PSCODFILIAL || ''')
                       AND PCLANC.CODCONTA NOT IN
                          (SELECT NVL(P.VALOR, 0)
                             FROM PCPARAMFILIAL P
                            WHERE P.NOME IN (''CON_CODCONTFOR'',
                                             ''CON_CODCONTFRE'',
                                             ''CON_CODCONTOUT'',
                                             ''CON_CODCONTAADIANTFOR'',
                                             ''CON_CODCONTAADIANTFOROUTROS'',
                                             ''CON_CODCONTAVERBAFORNEC'',
                                             ''CON_CODCONTAVERBACMV'',
                                             ''CON_CODCONTEMPREST'',
                                             ''CODCONTAEMPRESTIMONACIONAL'',
                                             ''CODCONTAEMPRESTIMOESTRANGEIRO''))
                      /*AND PCLANC.VALOR <> 0 */';

    VS_SQL_PCFINANC2 := ' SELECT '''|| PDDATAPROCESSADA ||''' DATA,
                                PCLANC.CODFILIAL,
                                ''CPOUTROS'' TIPODADO,
                                PCLANC.CODFORNEC,
                                ''0'',
                                DECODE(''' || PSEXIBIRSALDOBRUTOFORNEC || ''',
                                       ''S'',
                                       SUM(NVL(PCLANC.VALOR, 0)),
                                       NVL(SUM(NVL(PCLANC.VALOR, 0) - NVL(PCLANC.DESCONTOFIN, 0) +
                                               NVL(PCLANC.TXPERM, 0) - NVL(PCLANC.VALORDEV, 0)),0)
                                       ) VALOR,
                                SYSDATE DTGERACAO, '
                                || PNCODROTINA || ' CODROTINA, '
                                || PNCODFUNC || ' CODFUNC,
                                0 VALOR2,
                                ''N'' PARMULTIFILIALCAIXABANCO3882,
                                PCLANC.CODFILIAL LISTAFILIAISBANCOCAIXA '
                                || VS_SQL_CORPO ||
                        ' GROUP BY PCLANC.CODFILIAL,
                                   PCLANC.CODFORNEC ' ;

    VS_SQL_PCFINANC3 := ' SELECT ''' || PDDATAPROCESSADA || ''' DATAREFERENCIA,
                                SYSDATE DATAGERACAO, '
                                || PNCODROTINA || ' CODROTINAGERACAO,
                                PCLANC.CODFILIAL,
                                ''CPOUTROS'' TIPODADO,
                                PCLANC.RECNUM,
                                PCLANC.RECNUMPRINC,
                                PCLANC.DTLANC,
                                PCCONTA.GRUPOCONTA CODGRUPO,
                                PCLANC.CODCONTA,
                                PCLANC.CODFORNEC,
                                PCLANC.NUMNOTA,
                                SUBSTR(PCLANC.DUPLIC, 1, 1) DUPLIC,
                                DECODE(''' || PSEXIBIRSALDOBRUTOFORNEC || ''',
                                       ''S'',
                                       NVL(PCLANC.VALOR, 0),
                                       NVL(NVL(PCLANC.VALOR, 0) - NVL(PCLANC.DESCONTOFIN, 0) +
                                           NVL(PCLANC.TXPERM, 0) - NVL(PCLANC.VALORDEV, 0), 0)
                                       ) VALOR,
                                PCLANC.DTVENC,
                                PCLANC.VPAGO,
                                PCLANC.DTPAGTO,
                                PCLANC.TIPOPARCEIRO,
                                PCLANC.DTDESD,
                                PCLANC.VALORDEV,
                                PCLANC.TXPERM,
                                PCLANC.DESCONTOFIN,
                                PCLANC.NUMBORDERO,
                                PCLANC.VPAGOBORDERO,
                                NVL(PCCONTA.INVESTIMENTO, ''N'') INVESTIMENTO '
                                || VS_SQL_CORPO;

    /*CONTAS A RECEBER ANALÍTICO --  ATIVO*/
    EXECUTE IMMEDIATE VS_SQL_INSERT_PCFINANC2 || ' ' || VS_SQL_PCFINANC2;

    IF (PNCODROTINA <> 117) AND (VCOUNT = 0) THEN
      EXECUTE IMMEDIATE VS_SQL_INSERT_PCFINANC3 || ' ' || VS_SQL_PCFINANC3;
    END IF;
END P_CALC_SALDO_CONTASPAGAROUTROS;

PROCEDURE P_DELETAR_PCFINANC2E3(PSCODFILIAL VARCHAR2, PNCODROTINA NUMBER) IS
BEGIN
    /*Apagando registros das PCFINANC3 gerados pela rotina 117*/
    --Apagando registros de crédito de cliente
   IF PNCODROTINA <> 117 THEN
    DELETE PCFINANC3CREDCLI F
     WHERE F.DATAGERACAO >= TRUNC(SYSDATE) - 7
       AND F.CODFILIAL IN (PSCODFILIAL)
       AND F.CODROTINAGERACAO = 117;

    --Apagando registros de adiantamento de fornecedor
    DELETE PCFINANC3LANCADIANT F
     WHERE F.DATAGERACAO >= TRUNC(SYSDATE) - 7
       AND F.CODFILIAL IN (PSCODFILIAL)
       AND F.CODROTINAGERACAO = 117;

    --Apagando registros de importação
    DELETE PCFINANC3LANCFINIMP F
     WHERE F.DATAGERACAO >= TRUNC(SYSDATE) - 7
       AND F.CODFILIAL IN (PSCODFILIAL)
       AND F.CODROTINAGERACAO = 117;

    --Apagando registros de contas a pagar de fornecedor
    DELETE PCFINANC3LANCFORNEC F
     WHERE F.DATAGERACAO >= TRUNC(SYSDATE) - 7
       AND F.CODFILIAL IN (PSCODFILIAL)
       AND F.CODROTINAGERACAO = 117;

    --Apagando registros de lançamentos de investimentos
    DELETE PCFINANC3LANCINVEST F
     WHERE F.DATAGERACAO >= TRUNC(SYSDATE) - 7
       AND F.CODFILIAL IN (PSCODFILIAL)
       AND F.CODROTINAGERACAO = 117;

    --Apagando registros de contas a pagar de outros fornecedores
    DELETE PCFINANC3LANCOUTROS F
     WHERE F.DATAGERACAO >= TRUNC(SYSDATE) - 7
       AND F.CODFILIAL IN (PSCODFILIAL)
       AND F.CODROTINAGERACAO = 117;

    --Apagando registros de contas a receber
    DELETE PCFINANC3PREST F
     WHERE F.DATAGERACAO >= TRUNC(SYSDATE) - 7
       AND F.CODFILIAL IN (PSCODFILIAL)
       AND F.CODROTINAGERACAO = 117;

    --Apagando registros de contas a receber de vendor
    DELETE PCFINANC3PRESTVENDOR F
     WHERE F.DATAGERACAO >= TRUNC(SYSDATE) - 7
       AND F.CODFILIAL IN (PSCODFILIAL)
       AND F.CODROTINAGERACAO = 117;

    --Apagando registros de verba
    DELETE PCFINANC3VERBAS F
     WHERE F.DATAGERACAO >= TRUNC(SYSDATE) - 7
       AND F.CODFILIAL IN (PSCODFILIAL)
       AND F.CODROTINAGERACAO = 117;
    END IF;
    /*Apagando registros da PCFINANC2 gerados pela rotina 117*/
    DELETE PCFINANC2
     WHERE PCFINANC2.CODFILIAL IN (PSCODFILIAL)
       AND PCFINANC2.CODROTINA = 117;
END P_DELETAR_PCFINANC2E3;


FUNCTION F_CABECALHO_INSERT_PCFINANC2 RETURN VARCHAR2 IS
    VS_SQL VARCHAR2(10000) := '';
BEGIN
    VS_SQL := 'INSERT INTO PCFINANC2
                  (DATA,
                   CODFILIAL,
                   TIPODADO,
                   CODIGON,
                   CODIGOA,
                   VALOR,
                   DTGERACAO,
                   CODROTINA,
                   CODFUNC,
                   VALOR2,
                   PARMULTIFILIALCAIXABANCO3882,
                   LISTAFILIAISBANCOCAIXA) ';
    RETURN VS_SQL;
END;

FUNCTION TEM_DADOS_RETROATIVOS(pnCODFILIAL IN VARCHAR DEFAULT NULL)
    RETURN TB_VALIDAR_PERIODO PIPELINED IS
    PORCENTAGEMQTDE   NUMBER;
    QTDE              NUMBER;
    vrVALIDAR_PERIODO VALIDAR_PERIODO;
BEGIN
    vrVALIDAR_PERIODO.CODFILIAL := NULL;
    vrVALIDAR_PERIODO.DATA      := NULL;
    -- CONTAGEM 10
    FOR FILIAIS IN (SELECT F.CODIGO
                          ,F.RAZAOSOCIAL
                          ,COUNT(1) QTDEPCEST
                      FROM PCFILIAL F,
                           PCEST E,
                           PCPRODFILIAL PF
                     WHERE F.CODIGO = E.CODFILIAL
                       AND E.CODPROD = PF.CODPROD(+)
                       AND E.CODFILIAL = PF.CODFILIAL(+)
                       AND E.CODPROD  >= (SELECT MIN(CODPROD) FROM PCEST WHERE CODFILIAL = E.CODFILIAL)
                       AND F.CODIGO <> '99'
                       AND (NVL(pnCODFILIAL, 0) = 0 OR F.CODIGO = pnCODFILIAL)
                       AND FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_GERARPCHISTEST',F.CODIGO,'N') = 'S'
                       AND ((FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('GERARPCHISTESTPARA',F.CODIGO,'E') = 'T') OR
                            (NVL(E.QTEST, 0) <> 0) OR
                            (NVL(E.QTESTGER, 0) <> 0) OR
                            (NVL(E.QTTRANSITO, 0) <> 0) OR
                            (NVL(E.QTTRANSITOTV13, 0) <> 0) OR
                            (NVL(PF.GERARPCHISTEST,'S') = 'S'))
                  GROUP BY F.CODIGO
                          ,F.RAZAOSOCIAL)
    LOOP
      SELECT (
        (SELECT COUNT(PCHISTESTFILA.CODPROD)
          FROM PCHISTESTFILA
           WHERE PCHISTESTFILA.CODFILIAL = FILIAIS.CODIGO
           AND PCHISTESTFILA.DATA = (TRUNC(SYSDATE)-1))
         +
        (SELECT COUNT(PCHISTEST.CODPROD)
          FROM PCHISTEST
         WHERE PCHISTEST.CODFILIAL = FILIAIS.CODIGO
           AND PCHISTEST.DATA = TRUNC(SYSDATE) - 1))
        INTO QTDE
        FROM DUAL;

      PORCENTAGEMQTDE := ((FILIAIS.QTDEPCEST - QTDE) / FILIAIS.QTDEPCEST) * 100;

      IF PORCENTAGEMQTDE > PORCENTAGEM THEN

        vrVALIDAR_PERIODO.CODFILIAL := FILIAIS.CODIGO;
        vrVALIDAR_PERIODO.DATA      := TRUNC(SYSDATE - 1);
        vrVALIDAR_PERIODO.RAZAOSOCIAL := FILIAIS.RAZAOSOCIAL;

        FOR DIAS IN 2..7 LOOP
          SELECT (
            (SELECT COUNT(PCHISTESTFILA.CODPROD)
              FROM PCHISTESTFILA
               WHERE PCHISTESTFILA.CODFILIAL = FILIAIS.CODIGO
               AND PCHISTESTFILA.DATA = (TRUNC(SYSDATE - DIAS)))
             +
            (SELECT COUNT(PCHISTEST.CODPROD)
              FROM PCHISTEST
             WHERE PCHISTEST.CODFILIAL = FILIAIS.CODIGO
               AND PCHISTEST.DATA = TRUNC(SYSDATE - DIAS)))
            INTO QTDE
            FROM DUAL;

            PORCENTAGEMQTDE := ((FILIAIS.QTDEPCEST - QTDE) / FILIAIS.QTDEPCEST) * 100;

            IF PORCENTAGEMQTDE > PORCENTAGEM THEN
              vrVALIDAR_PERIODO.CODFILIAL := FILIAIS.CODIGO;
              vrVALIDAR_PERIODO.DATA      := TRUNC(SYSDATE - DIAS);
              vrVALIDAR_PERIODO.RAZAOSOCIAL := FILIAIS.RAZAOSOCIAL;
            ELSE
              EXIT;
            END IF;
         END LOOP;
        PIPE ROW (vrVALIDAR_PERIODO);
       END IF;
     END LOOP;
     RETURN;
END;

PROCEDURE PRC_EXECUTAR_DADOS_RETROATIVOS(psCODFILIAL IN PCMOV.CODFILIAL%TYPE
                                        ,pdDATA_PROCESSAMENTO IN DATE
                                        ,psMSG_RETORNO OUT VARCHAR2) IS
BEGIN
    FOR DATAS IN ( SELECT (pdDATA_PROCESSAMENTO + ROWNUM - 1) DATA_PROCESSAMENTO
                     FROM DUAL
                  CONNECT BY LEVEL <= TRUNC(SYSDATE) - pdDATA_PROCESSAMENTO
            GROUP BY (pdDATA_PROCESSAMENTO + ROWNUM - 1))
    LOOP
    P_PC_ARMAZENASALDOESTOQUELOTE(DATAS.DATA_PROCESSAMENTO, psCODFILIAL, psMSG_RETORNO);
    psMSG_RETORNO := 'OK';
    P_PC_ARMAZENARSALDOSESTOQUE(DATAS.DATA_PROCESSAMENTO, psCODFILIAL, psMSG_RETORNO);
      IF (psMSG_RETORNO <> 'OK') THEN
        EXIT;
      END IF;
    END LOOP;
    IF (psMSG_RETORNO = 'OK') OR (psMSG_RETORNO is null) THEN
      UPDATE PCCONSUM
         SET DTPROCESSAMENTO = TRUNC(SYSDATE);
      UPDATE PCPARAMFILIAL
         SET VALOR = TO_CHAR(TRUNC(SYSDATE), 'DD/MM/YYYY')
       WHERE CODFILIAL = psCODFILIAL
         AND NOME LIKE '%DTPROCESSAMENTOFILIAL%';
    END IF;
END;

END;