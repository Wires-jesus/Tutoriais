create or replace procedure P_GERA_CONTACORR_ENTRADA_SAIDA(PCODFILIAL in varchar2,
                                                           PDTINICIAL in date,
                                                           PDTFINAL   in date,
                                                           PCODPROD   in number,
                                                           MSG        out varchar2) is

  -- PRAGMA AUTONOMOUS_TRANSACTION; --
  ------------------------------------------------------------------------
  -- Programa criado para manter um conta corrente das saidas com relação
  -- às entradas
  ------------------------------------------------------------------------
  -- Definição de cursor
  cursor C_ENTRADAS is
    select NUMTRANSENT,
           DATA,
           CODPROD,
           QTCONT,
           SALDO,
           NUMSEQ
    from   PCMOVENT
    where  CODFILIAL = PCODFILIAL
    and    SALDO > 0
    and    (NVL(PCODPROD, 0) = 0 or CODPROD = NVL(PCODPROD, 0))
    order  by CODPROD,
              DATA,
              NUMTRANSENT;
  ------------------------------------------------------------------------
  -- Definição das variáveis
  V_MAXDATA     date;
  V_SALDOQT     number;
  V_QTDIFERENCA number;
  V_CODPRODTEMP number;
  R_ENTRADAS    C_ENTRADAS%rowtype;
  V_QTREGISTROS number;
  V_QTSAIDA     number;
  ------------------------------------------------------------------------
  -- Insere registro de historico de entradas
  procedure DELETAR_DADOS is
  begin
    ------------------------------------------------------------------------
    -- Apaga os registros de entrada do período informado em diante
    delete from PCMOVENT
    where  DATA between PDTINICIAL and PDTFINAL
    and    (NVL(PCODPROD, 0) = 0 or CODPROD = NVL(PCODPROD, 0))
    and    CODFILIAL = PCODFILIAL;
    ------------------------------------------------------------------------
    -- Apaga os registros de historico do período informado em diante
    delete from PCHISTMOVENT
    where  DTSAIDA between PDTINICIAL and PDTFINAL
    and    (NVL(PCODPROD, 0) = 0 or CODPROD = NVL(PCODPROD, 0))
    and    CODFILIAL = PCODFILIAL;
    -- Apaga os registros de saída do período informado em diante
    delete from PCMOVSAID
    where  DATA between PDTINICIAL and PDTFINAL
    and    (NVL(PCODPROD, 0) = 0 or CODPROD = NVL(PCODPROD, 0))
    and    CODFILIAL = PCODFILIAL;
  end;

  ------------------------------------------------------------------------
  -- Insere registro de controle de saída
  procedure INSERIR_SAIDAS(P_NUMTRANSVENDA in number,
                           P_NUMTRANSENT   in number,
                           P_CODPROD       in number,
                           P_DATA          in date,
                           P_QTDE          in number,
                           P_NUMSEQENT     IN NUMBER) is
  begin
    insert into PCMOVSAID
      (CODFILIAL,
       NUMTRANSVENDA,
       NUMTRANSENT,
       CODPROD,
       DATA,
       QTCONT,
       NUMSEQENT)
    values
      (PCODFILIAL,
       P_NUMTRANSVENDA,
       P_NUMTRANSENT,
       P_CODPROD,
       P_DATA,
       P_QTDE,
       P_NUMSEQENT);
  end;

  ------------------------------------------------------------------------
  -- Atualiza saldo de controle de entrada
  procedure ATUALIZAR_ENTRADA(P_NUMTRANSENT in number,
                              P_CODPROD     in number,
                              P_SALDO       in number) as
  begin
    update PCMOVENT
    set    SALDO = NVL(P_SALDO, QTCONT)
    where  NUMTRANSENT = P_NUMTRANSENT
    and    CODPROD = P_CODPROD;
  end;

  ------------------------------------------------------------------------
  -- Insere registro de historico de entradas
  procedure INSERIR_HISTORICO(P_DATA        in date,
                              P_NUMTRANSENT in number,
                              P_NUMTRANSVENDA IN NUMBER,
                              P_CODPROD     in number,
                              P_QTCONT      in number,
                              P_SALDO       in number) is
  begin
    begin
      insert into PCHISTMOVENT
        (CODFILIAL,
         DTSAIDA,
         NUMTRANSENT,
         NUMTRANSVENDA,
         CODPROD,
         QTCONT,
         SALDO)
      values
        (PCODFILIAL,
         P_DATA,
         P_NUMTRANSENT,
         P_NUMTRANSVENDA,
         P_CODPROD,
         P_QTCONT,
         P_SALDO);
    exception
      when others then
        begin
          update PCHISTMOVENT
          set    SALDO = P_SALDO
          where  CODFILIAL = PCODFILIAL
          and    DTSAIDA = P_DATA
          and    NUMTRANSENT = P_NUMTRANSENT
          and    CODPROD = P_CODPROD;
        end;
    end;
  end;

  ------------------------------------------------------------------------
  -- Restaurar saldos a partir do historico
  procedure RESTAURAR_SALDOS_ANTERIORES is
    V_SALDOANT number;
  begin
    -- Busca as entrada anteriores ao período em questão, cujas saídas houveram
    -- após ou durante este período
    for SAIDAS in (select distinct MS.DATA,
                                   MS.NUMTRANSENT,
                                   MS.CODPROD
                   from   PCMOVSAID MS,
                          PCNFENT   NE
                   where  NE.NUMTRANSENT = MS.NUMTRANSENT
                   and    MS.CODFILIAL = PCODFILIAL
                   and    MS.DATA >= PDTINICIAL
                   and    NE.DTENT < PDTINICIAL
                   and    NE.ESPECIE = 'NF'
                   and    (NVL(PCODPROD, 0) = 0 or
                         MS.CODPROD = NVL(PCODPROD, 0))
                   order  by DATA,
                             NUMTRANSENT,
                             CODPROD)
    loop
      -- Busca ultimo saldo anterior ao período em questão
      begin
        select SALDO
        into   V_SALDOANT
        from   PCHISTMOVENT
        where  NUMTRANSENT = SAIDAS.NUMTRANSENT
        and    CODPROD = SAIDAS.CODPROD
        and    CODFILIAL = PCODFILIAL
        and    DTSAIDA = (select max(DTSAIDA)
                          from   PCHISTMOVENT
                          where  NUMTRANSENT = SAIDAS.NUMTRANSENT
                          and    CODPROD = SAIDAS.CODPROD
                          and    CODFILIAL = PCODFILIAL
                          and    DTSAIDA < PDTINICIAL);
      exception
        when others then
          V_SALDOANT := null;
      end;
      ------------------------------------------------------------------------
      ATUALIZAR_ENTRADA(SAIDAS.NUMTRANSENT, SAIDAS.CODPROD, V_SALDOANT);
    end loop;
  end;

  procedure ENTRADAS_SOBRE_ESTOQUE is
  begin
    -- Selecionar a ultima data do estoque anterior a data inicial
    select max(DATA)
    into   V_MAXDATA
    from   PCHISTEST
    where  CODFILIAL = PCODFILIAL
    and    (NVL(PCODPROD, 0) = 0 or CODPROD = NVL(PCODPROD, 0))
    and    DATA <= PDTINICIAL;
    ------------------------------------------------------------------------
    -- Gera entradas a partir do estoque
    for ESTOQUE in (select CODPROD,
                           QTEST
                    from   PCHISTEST
                    where  CODFILIAL = PCODFILIAL
                    and    QTEST > 0
                    and    (NVL(PCODPROD, 0) = 0 or CODPROD = NVL(PCODPROD, 0))
                    and    DATA = V_MAXDATA)
    loop
      V_SALDOQT := ESTOQUE.QTEST;
      ------------------------------------------------------------------------
      -- Relaciona entrada anteriores ao estoque encontrado
      for ENTRADAS in (select N.NUMTRANSENT,
                              M.CODPROD,
                              max(N.DTENT) DTMOV,
                              sum(M.QTCONT) QTCONT
                       from   PCNFENT N,
                              PCMOV   M,
                              PCMOVCOMPLE MC
                       where  NVL(N.CODFILIALNF, N.CODFILIAL) = PCODFILIAL
                       and    M.NUMTRANSENT = N.NUMTRANSENT
                       AND    M.NUMTRANSITEM = MC.NUMTRANSITEM
                       and    N.DTENT between PDTINICIAL - 700 and
                              PDTINICIAL - 1
                       and    M.CODPROD = ESTOQUE.CODPROD
                       and    N.ESPECIE = 'NF'
                       and    M.QTCONT > 0
                       and    N.TIPODESCARGA NOT IN ('F','P','G')
                       and    NVL(N.NFENTREGAFUTURA, 'N') = 'N'
                       and    M.STATUS in ('A', 'AB')
                       and    M.CODOPER in ('E', 'EB', 'ET', 'ED', 'ER', 'EI')
                       and    M.DTCANCEL is NULL
                       AND    CASE WHEN N.TIPODESCARGA IN ('J', 'H') THEN
                                 DECODE(NVL(MC.VLICMS,0),0,0,1) 
                              ELSE
                                 1
                              END = 1           
                       group  by N.NUMTRANSENT,
                                 M.CODPROD
                       order  by DTMOV desc)
      loop
        ------------------------------------------------------------------------
        V_SALDOQT := V_SALDOQT - ENTRADAS.QTCONT;
        ------------------------------------------------------------------------
        -- Insere entrada encontradas, até que a quantidade seja zerada
        insert into PCMOVENT
          (CODFILIAL,
           NUMTRANSENT,
           CODPROD,
           DATA,
           QTCONT,
           SALDO)
        values
          (PCODFILIAL,
           ENTRADAS.NUMTRANSENT,
           ENTRADAS.CODPROD,
           ENTRADAS.DTMOV,
           ENTRADAS.QTCONT,
           ENTRADAS.QTCONT);
        ------------------------------------------------------------------------
        -- Proximo produto quando o quantidade de estoque for zerada
        exit when V_SALDOQT <= 0;
      end loop;
    end loop;
  end;

begin
  /****************************** INICIO CORPO DA PROCEDURE ****************************/
  -- Verifica se há registros de movimentação de entrada
  -- Se houver, restaura saldos anteriores, senão inicializa com entradas
  -- a partir da quantidade de estoque da data inicial

  begin
    ------------------------------------------------------------------------
    select CODPROD
    into   V_CODPRODTEMP
    from   PCMOVENT
    where  DATA <= PDTINICIAL
    and    CODFILIAL = PCODFILIAL
    and    (NVL(PCODPROD, 0) = 0 or CODPROD = NVL(PCODPROD, 0))
    and    ROWNUM = 1;
    ------------------------------------------------------------------------
    -- Restaura saldos anteriores, quando já houver historico de entradas
    RESTAURAR_SALDOS_ANTERIORES;
    ------------------------------------------------------------------------
    DELETAR_DADOS;
    ------------------------------------------------------------------------
  exception
    when others then
      begin
        ------------------------------------------------------------------------
        DELETAR_DADOS;
        ------------------------------------------------------------------------
        -- Gera entradas a partir do estoque da data inicial, voltando até zerar
        ENTRADAS_SOBRE_ESTOQUE;
        ------------------------------------------------------------------------
      end;
  end;
  ------------------------------------------------------------------------
  -- Inserir entradas do período
  insert into PCMOVENT
    (CODFILIAL,
     NUMTRANSENT,
     CODPROD,
     DATA,
     QTCONT,
     SALDO,
     NUMSEQ)
    select PCODFILIAL,
           N.NUMTRANSENT,
           M.CODPROD,
           max(N.DTENT) DTENT,
           sum(M.QTCONT) QTCONT,
           sum(M.QTCONT) SALDO,
           MAX(NVL(NVL(MC.NUMSEQENT, M.NUMSEQ) ,0)) NUMSEQ
    from   PCNFENT N,
           PCMOV   M,
           PCMOVCOMPLE MC
    where  NVL(N.CODFILIALNF, N.CODFILIAL) = PCODFILIAL
    and    N.DTENT between PDTINICIAL and PDTFINAL
    and    N.ESPECIE = 'NF'
    and    N.NUMTRANSENT = M.NUMTRANSENT
    and    N.NUMNOTA     = M.NUMNOTA
    and    m.numtransitem = mc.numtransitem
    and    (NVL(PCODPROD, 0) = 0 or M.CODPROD = NVL(PCODPROD, 0))
    and    M.QTCONT > 0
    and    M.STATUS in ('A', 'AB')
    and    N.TIPODESCARGA NOT IN ('F','P','G')
    and    NVL(N.NFENTREGAFUTURA, 'N') = 'N'
    and    M.CODOPER in ('E', 'EB', 'ET', 'ED', 'ER', 'EI')
    and    M.DTCANCEL is NULL
    AND    CASE WHEN N.TIPODESCARGA IN ('J', 'H') THEN
               DECODE(NVL(MC.VLICMS,0),0,0,1) 
            ELSE
               1
           END = 1  
    and    not exists (select CODPROD
            from   PCMOVENT
            where  NUMTRANSENT = N.NUMTRANSENT
            and    CODFILIAL = PCODFILIAL
            and    CODPROD = M.CODPROD)
    group  by N.NUMTRANSENT,
              M.CODPROD;
  ------------------------------------------------------------------------
  -- Limpando tabela temporaria
  DELETE FROM PCDADOS1070_TEMP;

  -- Inserindo saidas do período.
  insert into PCDADOS1070_TEMP
              (NUMTRANSVENDA,
               DATA,
               CODPROD,
               QTCONT)
             select N.NUMTRANSVENDA,
                    N.DTSAIDA,
                    M.CODPROD,
                    sum(M.QTCONT) QTCONT
             from   PCNFSAID N,
                    PCMOV    M
             where  NVL(M.CODFILIALNF, M.CODFILIAL) = PCODFILIAL
             and    M.DTMOV between PDTINICIAL and PDTFINAL
             and    M.NUMTRANSVENDA = N.NUMTRANSVENDA
             and    N.ESPECIE = 'NF'
             and    M.QTCONT > 0
             and    M.STATUS in ('A', 'AB')
             and    M.CODOPER in ('S', 'SB', 'ST', 'SD', 'SP', 'SR', 'SI', 'SA','SM','SN','SV')
             and    NVL(M.CODFISCAL, 0) not in (5929, 6929)
             and    NVL(N.CONDVENDA, 0) not in (3, 6, 7, 12, 13)
             and    NVL(N.FINALIDADENFE, 'O') <> 'C'
             and    M.DTCANCEL is null
             and    N.DTCANCEL is null
             group  by N.NUMTRANSVENDA,
                       N.DTSAIDA,
                       M.CODPROD
             order  by DTSAIDA,
                       NUMTRANSVENDA;
  ------------------------------------------------------------------------

  V_QTREGISTROS := 0;
  ------------------------------------------------------------------------
  -- Lista entradas para controle das saídas (abrindo o cursor)
  open C_ENTRADAS;
  ------------------------------------------------------------------------
  -- Posiciona o registro no primeiro registro
  fetch C_ENTRADAS
    into R_ENTRADAS;
  ------------------------------------------------------------------------
  loop
    ------------------------------------------------------------------------
    -- Termina o laço se não mais houver entradas
    exit when C_ENTRADAS%notfound;
    ------------------------------------------------------------------------
    -- Inicialização das variaveis
    V_SALDOQT     := R_ENTRADAS.SALDO;
    V_CODPRODTEMP := R_ENTRADAS.CODPROD;
    ------------------------------------------------------------------------
    -- Relaciona as saídas para controle --
    -- Utilizando tabela temporaria.
    for SAIDAS in (select T.NUMTRANSVENDA,
                          T.DATA AS DTSAIDA,
                          T.CODPROD,
                          T.QTCONT
                     from PCDADOS1070_TEMP T
                    where T.DATA between PDTINICIAL and PDTFINAL
                      and T.CODPROD = R_ENTRADAS.CODPROD
                    order by T.DATA,
                             T.NUMTRANSVENDA
                             )
    loop
      ------------------------------------------------------------------------
      V_QTDIFERENCA := -1;
      V_QTSAIDA     := SAIDAS.QTCONT;
      ------------------------------------------------------------------------
      -- Este laço faz com que a saida atual sejá mantida quando o saldo de
      -- entrada não for suficiente, pegando a proxima entrada ate que a
      -- quantidade total da saída seja zerada
      while (V_QTDIFERENCA < 0) and
            (R_ENTRADAS.DATA <= SAIDAS.DTSAIDA)
      loop
        ------------------------------------------------------------------------
        -- Se o saldo for maior que a saída atual, armazena somente a quantidade de
        -- saída, caso contrário o saldo passa a ser o (zero) e a quantidade
        -- restante passa a ser dedizida na proxima entrada
        if V_SALDOQT > V_QTSAIDA
        then
          V_SALDOQT     := V_SALDOQT - V_QTSAIDA;
          V_QTDIFERENCA := 0;
        else
          V_QTDIFERENCA := V_SALDOQT - V_QTSAIDA;
          V_QTSAIDA     := V_SALDOQT;
          V_SALDOQT     := 0;
        end if;
        ------------------------------------------------------------------------
        INSERIR_SAIDAS(SAIDAS.NUMTRANSVENDA,
                       R_ENTRADAS.NUMTRANSENT,
                       SAIDAS.CODPROD,
                       SAIDAS.DTSAIDA,
                       V_QTSAIDA,
                       R_ENTRADAS.NUMSEQ);
        ------------------------------------------------------------------------
        INSERIR_HISTORICO(SAIDAS.DTSAIDA,
                          R_ENTRADAS.NUMTRANSENT,
                          SAIDAS.NUMTRANSVENDA,
                          R_ENTRADAS.CODPROD,
                          R_ENTRADAS.QTCONT,
                          V_SALDOQT);
        ------------------------------------------------------------------------
        if V_SALDOQT <= 0
        then
          ------------------------------------------------------------------------
          ATUALIZAR_ENTRADA(R_ENTRADAS.NUMTRANSENT,
                            R_ENTRADAS.CODPROD,
                            V_SALDOQT);
          -- Proxima entrada, se não há mais saldo
          fetch C_ENTRADAS
            into R_ENTRADAS;
          ------------------------------------------------------------------------
          -- Sair do laço quando o produto mudar
          exit when(V_CODPRODTEMP <> R_ENTRADAS.CODPROD) or(C_ENTRADAS%notfound);
          V_SALDOQT := R_ENTRADAS.SALDO;
        end if;
        ------------------------------------------------------------------------
        -- A quantidade restante da saída é a diferença quando > zero
        V_QTSAIDA := ABS(V_QTDIFERENCA);
        ------------------------------------------------------------------------
        -- Commitar os dados a cada 1000 registros
        if V_QTREGISTROS >= 1000
        then
          commit;
          V_QTREGISTROS := 0;
        end if;
        ------------------------------------------------------------------------
        -- Incrementa variavel para controle de registros para commit
        V_QTREGISTROS := V_QTREGISTROS + 1;
      end loop;
      ------------------------------------------------------------------------
      -- Sair do laço quando o produto mudar
      exit when(V_CODPRODTEMP <> R_ENTRADAS.CODPROD) or(C_ENTRADAS%notfound);
    end loop;
    ------------------------------------------------------------------------
    ATUALIZAR_ENTRADA(R_ENTRADAS.NUMTRANSENT, R_ENTRADAS.CODPROD, V_SALDOQT);
    ------------------------------------------------------------------------    
    while (V_CODPRODTEMP = R_ENTRADAS.CODPROD) and
    -- Sair do laço quando o produto mudar ou a lista de produtos terminar
          (not C_ENTRADAS%notfound)
    loop
      fetch C_ENTRADAS
        into R_ENTRADAS;
    end loop;
  end loop;
  ------------------------------------------------------------------------
  -- Elimina o cursor da memória
  close C_ENTRADAS;
  ------------------------------------------------------------------------
  MSG := 'OK';
  commit;
  /****************************** FIM CORPO DA PROCEDURE *****************************/
exception
  when others then
    begin
      rollback;
      MSG := 'ERRO AO GERAR CONTA CORRENTE: ' || CHR(13) || sqlcode || ' ' ||
             sqlerrm;
    end;
end;
-- Última alteração 01/02/2022 - Implementado insert das saídas na tabela temporária PCDADOS1070_TEMP.
-- Gerando nova versão
-- Migração para Azure 22/09/2025