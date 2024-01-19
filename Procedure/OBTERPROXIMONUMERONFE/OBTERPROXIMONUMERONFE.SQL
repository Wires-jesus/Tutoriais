create or replace procedure OBTERPROXIMONUMERONFE(P_ROTAPRINCIPAL in varchar2 default '',
                                                  P_CODIGOFILIAL  in varchar2 default '',
                                                  P_MOVIMENTO     in varchar2 default '',
                                                  P_SEFAZORIGEM   in varchar2 default 'P',
                                                  P_TIPONUMERADOR in varchar2 default '',
                                                  P_CODFILIALDESTINO in varchar2 default '',--usado no processo de venda para deposito fechado
                                                  P_CODGRUPO_SEQ_PROD in number default null,--usado no processo de sequencia por produto
                                                  P_NUMERO        out number,
                                                  P_SERIE         out number,
                                                  P_RESULTADO     out number,
                                                  P_MENSAGEM      out varchar2) is
  SAIR_COM_ERRO exception;

  --PROCEDURE CRIADA PARA GERAR LOG NA PCLOGALTERACAODADOS QUANDO DER ERRO NO CONSUMO DO PROXNUMNOTA
  -- 04/04/2014 - EDDY
  procedure GERAR_LOG(PSITUACAO_ERRO in varchar2,
                      PMENSAGEM_ERRO in varchar2,
                      PLINHA_ERRO    in varchar2) is
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
       'INDEFINIDA',
       'INDEFINIDA',
       'A',
       'ERRO NA BUSCA NO PROXIMO NUMERO DE NOTA',
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       'ERRO FUNCTION OBTERPROXIMONUMERONFE' || PSITUACAO_ERRO,
       SUBSTR('ERRO ORIGINAL: ' || PMENSAGEM_ERRO, 1, 89) ||
       SUBSTR(PLINHA_ERRO, 1, 10));
  end;
  ----------------------

begin
  P_NUMERO    := 0;
  P_SERIE     := 0;
  P_RESULTADO := 0;
  P_MENSAGEM  := '';

  if P_MOVIMENTO = 'S' then
    if P_TIPONUMERADOR = 'P' then
      if P_SEFAZORIGEM = 'S' then
        --Nota ser? enviado para o SEFAZ de Origem do Contribuinte de ICMS
        begin
          select DECODE(NVL(PCFILIAL.PROXNUMNFE, 1),
                        0,
                        1,
                        NVL(PCFILIAL.PROXNUMNFE, 1)),
                 TO_NUMBER(DECODE(NVL(PCFILIAL.SERIENFE, 'U'),
                                  'U',
                                  '0',
                                  PCFILIAL.SERIENFE))
            into P_NUMERO, P_SERIE
            from PCFILIAL
           where CODIGO = P_CODIGOFILIAL
             for update;
        exception
          when NO_DATA_FOUND then
            P_RESULTADO := 1;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Não foi encontrado registro da filial "' ||
                           P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                           sqlerrm;

            raise SAIR_COM_ERRO;
          when others then
            P_RESULTADO := 2;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao buscar os dados da filial "' ||
                           P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                           sqlerrm;

            raise SAIR_COM_ERRO;
        end;

        /*
                 Atualiza na filial informada, o próximo número
        */
        begin
          update PCFILIAL
             set PCFILIAL.PROXNUMNFE = P_NUMERO + 1
           where CODIGO = P_CODIGOFILIAL;

          return;
        exception
          when others then
            P_RESULTADO := 3;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao atualizar os dados do próximo número de nota. ' ||
                           ' - Filial: ' || P_CODIGOFILIAL || ' - ' ||
                           sqlcode || ' - ' || sqlerrm;

            raise SAIR_COM_ERRO;
        end;
      else
        --Nota ser? enviado para o SCAN(Sistema de Contig?ncia Ambiente Nacional) SEFAZ de Origem Não est? recebendo as notas
        begin
          select DECODE(NVL(PCFILIAL.PROXNUMNFESCAN, 1),
                        0,
                        1,
                        NVL(PCFILIAL.PROXNUMNFESCAN, 1)),
                 TO_NUMBER(DECODE(NVL(PCFILIAL.SERIENFESCAN, 'U'),
                                  'U',
                                  '900',
                                  PCFILIAL.SERIENFESCAN))
            into P_NUMERO, P_SERIE
            from PCFILIAL
           where CODIGO = P_CODIGOFILIAL
             for update;
        exception
          when NO_DATA_FOUND then
            P_RESULTADO := 4;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Não foi encontrado registro da filial "' ||
                           P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                           sqlerrm;

            raise SAIR_COM_ERRO;
          when others then
            P_RESULTADO := 5;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao buscar os dados da filial "' ||
                           P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                           sqlerrm;

            raise SAIR_COM_ERRO;
        end;

        /*
                 Atualiza na filial informada, o próximo número
        */
        begin
          update PCFILIAL
             set PCFILIAL.PROXNUMNFESCAN = P_NUMERO + 1
           where CODIGO = P_CODIGOFILIAL;

          return;
        exception
          when others then
            P_RESULTADO := 6;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao atualizar os dados do próximo número de nota. ' ||
                           ' - Filial: ' || P_CODIGOFILIAL || ' - ' ||
                           sqlcode || ' - ' || sqlerrm;

            raise SAIR_COM_ERRO;
        end;
      end if;
    elsif P_TIPONUMERADOR = 'M' then
      if P_SEFAZORIGEM = 'S' then

        IF (NVL(PARAMFILIAL.ObterComoVarchar2('TIPONUMNOTAMANIF',P_CODIGOFILIAL), 'M') = 'M') THEN
          begin
            select DECODE(NVL(PCFILIAL.PROXNUMNFEREMMANISFESTO, 1),
                          0,
                          1,
                          NVL(PCFILIAL.PROXNUMNFEREMMANISFESTO, 1)),
                   TO_NUMBER(DECODE(NVL(PCFILIAL.SERIENFEREMMANISFESTO, 'U'),
                                    'U',
                                    '0',
                                    PCFILIAL.SERIENFEREMMANISFESTO))
              into P_NUMERO, P_SERIE
              from PCFILIAL
             where CODIGO = P_CODIGOFILIAL
               for update;
          exception
            when NO_DATA_FOUND then
              P_RESULTADO := 7;
              P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                             ' - Não foi encontrado registro da filial "' ||
                             P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                             sqlerrm;

              raise SAIR_COM_ERRO;
            when others then
              P_RESULTADO := 8;
              P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                             ' - Erro ao buscar os dados da filial "' ||
                             P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                             sqlerrm;

              raise SAIR_COM_ERRO;
          end;
          --         Atualiza na filial informada, o próximo número
          begin
            update PCFILIAL
               set PCFILIAL.PROXNUMNFEREMMANISFESTO = P_NUMERO + 1
             where CODIGO = P_CODIGOFILIAL;

            return;
          exception
            when others then
              P_RESULTADO := 9;
              P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                             ' - Erro ao atualizar os dados do próximo número de nota. ' ||
                             ' - Filial: ' || P_CODIGOFILIAL || ' - ' ||
                             sqlcode || ' - ' || sqlerrm;

              raise SAIR_COM_ERRO;
          end;
        ELSIF (NVL(PARAMFILIAL.ObterComoVarchar2('TIPONUMNOTAMANIF', P_CODIGOFILIAL), 'M') = 'U') THEN
          begin
            select DECODE(NVL(PCFILIAL.PROXNUMNFE, 1),
                          0,
                          1,
                          NVL(PCFILIAL.PROXNUMNFE, 1)),
                   TO_NUMBER(DECODE(NVL(PCFILIAL.SERIENFE, 'U'),
                                    'U',
                                    '0',
                                    PCFILIAL.SERIENFE))
              into P_NUMERO, P_SERIE
              from PCFILIAL
             where CODIGO = P_CODIGOFILIAL
               for update;
          exception
            when NO_DATA_FOUND then
              P_RESULTADO := 7;
              P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                             ' - Não foi encontrado registro da filial "' ||
                             P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                             sqlerrm;

              raise SAIR_COM_ERRO;
            when others then
              P_RESULTADO := 8;
              P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                             ' - Erro ao buscar os dados da filial "' ||
                             P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                             sqlerrm;

              raise SAIR_COM_ERRO;
          end;
          --         Atualiza na filial informada, o próximo número
          begin
            update PCFILIAL
               set PCFILIAL.PROXNUMNFE = P_NUMERO + 1
             where CODIGO = P_CODIGOFILIAL;

            return;
          exception
            when others then
              P_RESULTADO := 9;
              P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                             ' - Erro ao atualizar os dados do próximo número de nota. ' ||
                             ' - Filial: ' || P_CODIGOFILIAL || ' - ' ||
                             sqlcode || ' - ' || sqlerrm;

              raise SAIR_COM_ERRO;
          end;
        END IF;
      else
        begin
          select DECODE(NVL(PCFILIAL.PROXNUMNFEREMMANISFESTOSCAN, 1),
                        0,
                        1,
                        NVL(PCFILIAL.PROXNUMNFEREMMANISFESTOSCAN, 1)),
                 TO_NUMBER(DECODE(NVL(PCFILIAL.SERIENFEREMMANISFESTOSCAN,
                                      'U'),
                                  'U',
                                  '900',
                                  PCFILIAL.SERIENFEREMMANISFESTOSCAN))
            into P_NUMERO, P_SERIE
            from PCFILIAL
           where CODIGO = P_CODIGOFILIAL
             for update;
        exception
          when NO_DATA_FOUND then
            P_RESULTADO := 22;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Não foi encontrado registro da filial "' ||
                           P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                           sqlerrm;

            raise SAIR_COM_ERRO;
          when others then
            P_RESULTADO := 23;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao buscar os dados da filial "' ||
                           P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                           sqlerrm;

            raise SAIR_COM_ERRO;
        end;
        /*
                 Atualiza na filial informada, o próximo número
        */
        begin
          update PCFILIAL
             set PCFILIAL.PROXNUMNFEREMMANISFESTOSCAN = P_NUMERO + 1
           where CODIGO = P_CODIGOFILIAL;

          return;
        exception
          when others then
            P_RESULTADO := 24;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao atualizar os dados do próximo número de nota. ' ||
                           ' - Filial: ' || P_CODIGOFILIAL || ' - ' ||
                           sqlcode || ' - ' || sqlerrm;

            raise SAIR_COM_ERRO;
        end;
      end if;
      --FIM MANIFESTO POR FILIAL
      --MANIFESTO POR ROTA
    elsif P_TIPONUMERADOR = 'R' then
      if P_SEFAZORIGEM = 'S' then
        begin
          select DECODE(NVL(PCROTAEXP.PROXNUMNFETV14, 1),
                        0,
                        1,
                        NVL(PCROTAEXP.PROXNUMNFETV14, 1)),
                 TO_NUMBER(DECODE(NVL(PCROTAEXP.SERIENFETV14, '0'),
                                  '0',
                                  '0',
                                  PCROTAEXP.SERIENFETV14))
            into P_NUMERO, P_SERIE
            from PCROTAEXP
           where PCROTAEXP.CODROTA = TO_NUMBER(P_ROTAPRINCIPAL)
             for update;
        exception
          when NO_DATA_FOUND then
            P_RESULTADO := 7;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Não foi encontrado registro da rota "' ||
                           P_ROTAPRINCIPAL || '". ' || sqlcode || ' - ' ||
                           sqlerrm;

            raise SAIR_COM_ERRO;
          when others then
            P_RESULTADO := 8;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao buscar os dados da rota "' ||
                           P_ROTAPRINCIPAL || '". ' || sqlcode || ' - ' ||
                           sqlerrm;

            raise SAIR_COM_ERRO;
        end;
        --         Atualiza na filial informada, o próximo número
        begin
          update PCROTAEXP
             set PCROTAEXP.PROXNUMNFETV14 = P_NUMERO + 1
           where PCROTAEXP.CODROTA = TO_NUMBER(P_ROTAPRINCIPAL);

          return;
        exception
          when others then
            P_RESULTADO := 9;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao atualizar os dados do próximo número de nota. ' ||
                           ' - Rota: ' || P_ROTAPRINCIPAL || ' - ' ||
                           sqlcode || ' - ' || sqlerrm;

            raise SAIR_COM_ERRO;
        end;
      else
        --MANIFESTO POR ROTA SCAN
        begin
          select DECODE(NVL(PCROTAEXP.PROXNUMNFESCANTV14, 1),
                        0,
                        1,
                        NVL(PCROTAEXP.PROXNUMNFESCANTV14, 1)),
                 TO_NUMBER(DECODE(NVL(PCROTAEXP.SERIENFESCANTV14, '0'),
                                  '0',
                                  '900',
                                  PCROTAEXP.SERIENFESCANTV14))
            into P_NUMERO, P_SERIE
            from PCROTAEXP
           where PCROTAEXP.CODROTA = TO_NUMBER(P_ROTAPRINCIPAL)
             for update;
        exception
          when NO_DATA_FOUND then
            P_RESULTADO := 22;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Não foi encontrado registro da rota "' ||
                           P_ROTAPRINCIPAL || '". ' || sqlcode || ' - ' ||
                           sqlerrm;

            raise SAIR_COM_ERRO;
          when others then
            P_RESULTADO := 23;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao buscar os dados da rota "' ||
                           P_ROTAPRINCIPAL || '". ' || sqlcode || ' - ' ||
                           sqlerrm;

            raise SAIR_COM_ERRO;
        end;
        /*
                 Atualiza na filial informada, o próximo número
        */
        begin
          update PCROTAEXP
             set PCROTAEXP.PROXNUMNFESCANTV14 = P_NUMERO + 1
           where PCROTAEXP.CODROTA = TO_NUMBER(P_ROTAPRINCIPAL);

          return;
        exception
          when others then
            P_RESULTADO := 24;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao atualizar os dados do próximo número de nota. ' ||
                           ' - Rota: ' || P_ROTAPRINCIPAL || ' - ' ||
                           sqlcode || ' - ' || sqlerrm;

            raise SAIR_COM_ERRO;
        end;
      end if;
      -- FIM MANIFESTO POR ROTA
    --------------Melhoria para buscar numerador diferente para notas de transferencia para deposito fechado--------------
    --D = deposito
    elsif P_TIPONUMERADOR = 'D' then
        --Nota sera enviado para o SEFAZ de Origem do Contribuinte de ICMS
        begin
          select DECODE(NVL(PCFILIALSEQNFEREMDEP.NUMNOTA, 1),
                        0,
                        1,
                        NVL(PCFILIALSEQNFEREMDEP.NUMNOTA, 1)),
                 TO_NUMBER(DECODE(NVL(PCFILIALSEQNFEREMDEP.SERIE, 'U'),
                                  'U',
                                  '0',
                                  PCFILIALSEQNFEREMDEP.SERIE))
            into P_NUMERO, P_SERIE
            from PCFILIALSEQNFEREMDEP
           where CODFILIALEMI = P_CODIGOFILIAL
             and CODFILIALDEPOSITO = P_CODFILIALDESTINO
             for update;
        exception
          when NO_DATA_FOUND then
            P_RESULTADO := 25;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Não foi encontrado registro da filial de origem: "' || P_CODIGOFILIAL || '" e filial destino: ' || P_CODFILIALDESTINO || '. ' ||
                           sqlcode || ' - ' ||
                           sqlerrm;

            raise SAIR_COM_ERRO;
          when others then
            P_RESULTADO := 26;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao buscar os dados da filial "' ||
                           P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                           sqlerrm;

            raise SAIR_COM_ERRO;
        end;

        /*
                 Atualiza na filial informada, o próximo número
        */
        begin
          update PCFILIALSEQNFEREMDEP
             set PCFILIALSEQNFEREMDEP.NUMNOTA = P_NUMERO + 1
           where CODFILIALEMI = P_CODIGOFILIAL
             and CODFILIALDEPOSITO = P_CODFILIALDESTINO;

          return;
        exception
          when others then
            P_RESULTADO := 3;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao atualizar os dados do próximo número de nota para o processo de remessa para deposito fechado, para a filial de destino ' || P_CODFILIALDESTINO ||
                           ' - Filial origem: ' || P_CODIGOFILIAL || ' - ' ||
                           sqlcode || ' - ' || sqlerrm;

            raise SAIR_COM_ERRO;
        end;
    --------------fim melhoria-----------------------
    --------------Melhoria para buscar numerador diferente para notas de ajuste(SAIDA)--------------
    --A = Ajuste
    elsif P_TIPONUMERADOR = 'A' then
        --Nota sera enviado para o SEFAZ de Origem do Contribuinte de ICMS
        begin
          select DECODE(NVL(PCFILIAL.PROXNUMNOTAAJUSTE, 1),
                        0,
                        1,
                        NVL(PCFILIAL.PROXNUMNOTAAJUSTE, 1)),
                 TO_NUMBER(DECODE(NVL(PCFILIAL.SERIENFEAJUSTE, 'U'),
                                  'U',
                                  '0',
                                  PCFILIAL.SERIENFEAJUSTE))
            into P_NUMERO, P_SERIE
            from PCFILIAL
           where CODIGO = P_CODIGOFILIAL
             for update;
        exception
          when NO_DATA_FOUND then
            P_RESULTADO := 27;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Numerador para notas de ajuste não encontrou valor. ' ||
                           sqlcode || ' - ' ||
                           sqlerrm;

            raise SAIR_COM_ERRO;
          when others then
            P_RESULTADO := 28;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao obter numerador para notas de ajuste.  "' ||
                           P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                           sqlerrm;

            raise SAIR_COM_ERRO;
        end;

        /*
                 Atualiza na filial informada, o próximo número
        */
        begin
          update PCFILIAL
               set PCFILIAL.PROXNUMNOTAAJUSTE = P_NUMERO + 1
             where CODIGO = P_CODIGOFILIAL;

          return;
        exception
          when others then
            P_RESULTADO := 3;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao atualizar os dados do próximo número de nota para notas de ajuste. ' ||
                           sqlcode || ' - ' || sqlerrm;

            raise SAIR_COM_ERRO;
        end;
    --------------fim melhoria do ajuste-----------------------
    --------------Melhoria para buscar numerador diferente para serie por produto--------------
    --O = serie por produto
    elsif P_TIPONUMERADOR = 'O' then
        begin
          select PCFILIALSEQNFEPORPRODUTO.PROXNUMNOTA, PCFILIALSEQNFEPORPRODUTO.PROXNUMSERIE
            into P_NUMERO, P_SERIE
            from PCFILIALSEQNFEPORPRODUTO
           where PCFILIALSEQNFEPORPRODUTO.CODFILIAL = P_CODIGOFILIAL
             and PCFILIALSEQNFEPORPRODUTO.CODGRUPO = P_CODGRUPO_SEQ_PROD
             for update;
        exception
          when NO_DATA_FOUND then
            P_RESULTADO := 27;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Não foi encontrado registro de sequencia por produto para o grupo: "' || P_CODGRUPO_SEQ_PROD || '" e filial: ' || P_CODIGOFILIAL || '. ' ||
                           sqlcode || ' - ' ||
                           sqlerrm;

            raise SAIR_COM_ERRO;
          when others then
            P_RESULTADO := 28;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao buscar os dados da filial na sequencia por produto "' ||
                           P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                           sqlerrm;

            raise SAIR_COM_ERRO;
        end;

        /*
                 Atualiza na filial informada, o próximo número
        */
        begin
          update PCFILIALSEQNFEPORPRODUTO
             set PCFILIALSEQNFEPORPRODUTO.PROXNUMNOTA = P_NUMERO + 1
           where CODFILIAL = P_CODIGOFILIAL
             and CODGRUPO = P_CODGRUPO_SEQ_PROD;

          return;
        exception
          when others then
            P_RESULTADO := 3;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao atualizar os dados do próximo número de nota para o processo de sequência por produto na filial: ' || P_CODIGOFILIAL ||
                           ' - grupo: ' || P_CODGRUPO_SEQ_PROD || ' - ' ||
                           sqlcode || ' - ' || sqlerrm;

            raise SAIR_COM_ERRO;
        end;
    --------------fim melhoria serie por produto-----------------------
    end if;
  else
    --Movimenta??o de Entrada
    if P_SEFAZORIGEM = 'S' then
      if P_TIPONUMERADOR = 'P' then
        begin
          select DECODE(NVL(PCFILIAL.PROXNUMNFE, 1),
                        0,
                        1,
                        NVL(PCFILIAL.PROXNUMNFE, 1)),
                 TO_NUMBER(DECODE(NVL(PCFILIAL.SERIENFE, 'U'),
                                  'U',
                                  '0',
                                  PCFILIAL.SERIENFE))

            into P_NUMERO, P_SERIE
            from PCFILIAL
           where CODIGO = P_CODIGOFILIAL
             for update;
        exception
          when NO_DATA_FOUND then
            P_RESULTADO := 10;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Não foi encontrado registro da filial "' ||
                           P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                           sqlerrm;

          when others then
            P_RESULTADO := 11;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao buscar os dados da filial "' ||
                           P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                           sqlerrm;

        end;
        /*
                 Atualiza na filial informada, o próximo número
        */
        if P_RESULTADO = 0 then
          begin
            update PCFILIAL
               set PCFILIAL.PROXNUMNFE = P_NUMERO + 1
             where CODIGO = P_CODIGOFILIAL;

            return;
          exception
            when others then
              P_RESULTADO := 12;
              P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                             ' - Erro ao atualizar os dados do próximo número de nota. ' ||
                             ' - Filial: ' || P_CODIGOFILIAL || ' - ' ||
                             sqlcode || ' - ' || sqlerrm;

              return;
          end;
        else

          return;
        end if;
      elsif P_TIPONUMERADOR = 'I' then
          begin
            select DECODE(NVL(PCFILIAL.PROXNUMNFEIMPORTACAO, 1),
                          0,
                          1,
                          NVL(PCFILIAL.PROXNUMNFEIMPORTACAO, 1)),
                   TO_NUMBER(DECODE(NVL(PCFILIAL.SERIENFEIMPORTACAO, 'U'),
                                    'U',
                                    '0',
                                    PCFILIAL.SERIENFEIMPORTACAO))
              into P_NUMERO, P_SERIE
              from PCFILIAL
             where CODIGO = P_CODIGOFILIAL
               for update;
          exception
            when NO_DATA_FOUND then
              P_RESULTADO := 13;
              P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                             ' - Não foi encontrado registro da filial importacao "' ||
                             P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                             sqlerrm;

            when others then
              P_RESULTADO := 14;
              P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                             ' - Erro ao buscar os dados da filial importacao"' ||
                             P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                             sqlerrm;

          end;
          /*
                   Atualiza na filial informada, o próximo número
          */
          if P_RESULTADO = 0 then
            begin
              update PCFILIAL
                 set PCFILIAL.PROXNUMNFEIMPORTACAO = P_NUMERO + 1
               where CODIGO = P_CODIGOFILIAL;

              return;
            exception
              when others then
                P_RESULTADO := 15;
                P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                               ' - Erro ao atualizar os dados do próximo número de nota importacao. ' ||
                               ' - Filial: ' || P_CODIGOFILIAL || ' - ' ||
                               sqlcode || ' - ' || sqlerrm;

                return;
            end;
          else

            return;
          end if;
        elsif P_TIPONUMERADOR = 'E' then
            begin
              select DECODE(NVL(PCFILIAL.PROXNUMNFEENTRADA, 1),
                            0,
                            1,
                            NVL(PCFILIAL.PROXNUMNFEENTRADA, 1)),
                     TO_NUMBER(DECODE(NVL(PCFILIAL.SERIENFEENTRADA, 'U'),
                                      'U',
                                      '0',
                                      PCFILIAL.SERIENFEENTRADA))
                into P_NUMERO, P_SERIE
                from PCFILIAL
               where CODIGO = P_CODIGOFILIAL
                 for update;
            exception
              when NO_DATA_FOUND then
                P_RESULTADO := 13;
                P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                               ' - Não foi encontrado registro da filial "' ||
                               P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                               sqlerrm;

              when others then
                P_RESULTADO := 14;
                P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                               ' - Erro ao buscar os dados da filial "' ||
                               P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                               sqlerrm;

            end;
            /*
                     Atualiza na filial informada, o próximo número
            */
            if P_RESULTADO = 0 then
              begin
                update PCFILIAL
                   set PCFILIAL.PROXNUMNFEENTRADA = P_NUMERO + 1
                 where CODIGO = P_CODIGOFILIAL;

                return;
              exception
                when others then
                  P_RESULTADO := 15;
                  P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                                 ' - Erro ao atualizar os dados do próximo número de nota. ' ||
                                 ' - Filial: ' || P_CODIGOFILIAL || ' - ' ||
                                 sqlcode || ' - ' || sqlerrm;

                  return;
              end;
            else

              return;
            end if;
          ----------------------------------------------------------------------
          --D = deposito
          elsif P_TIPONUMERADOR = 'D' then
              --Nota sera enviado para o SEFAZ de Origem do Contribuinte de ICMS
              begin
                select DECODE(NVL(PCFILIALSEQNFEREMDEP.NUMNOTA, 1),
                              0,
                              1,
                              NVL(PCFILIALSEQNFEREMDEP.NUMNOTA, 1)),
                       TO_NUMBER(DECODE(NVL(PCFILIALSEQNFEREMDEP.SERIE, 'U'),
                                        'U',
                                        '0',
                                        PCFILIALSEQNFEREMDEP.SERIE))
                  into P_NUMERO, P_SERIE
                  from PCFILIALSEQNFEREMDEP
                 where CODFILIALEMI = P_CODIGOFILIAL
                   and CODFILIALDEPOSITO = P_CODFILIALDESTINO
                   for update;
              exception
                when NO_DATA_FOUND then
                  P_RESULTADO := 25;
                  P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                                  ' - Não foi encontrado registro da filial de origem: "' || P_CODIGOFILIAL || '" e filial destino: "' || P_CODFILIALDESTINO || '". ' ||
                                 sqlcode || ' - ' ||
                                 sqlerrm;

                  raise SAIR_COM_ERRO;
                when others then
                  P_RESULTADO := 26;
                  P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                                 ' - Erro ao buscar os dados da filial "' ||
                                 P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                                 sqlerrm;

                  raise SAIR_COM_ERRO;
              end;

              /*
                       Atualiza na filial informada, o próximo número
              */
              begin
               update PCFILIALSEQNFEREMDEP
                  set PCFILIALSEQNFEREMDEP.NUMNOTA = P_NUMERO + 1
                where CODFILIALEMI = P_CODIGOFILIAL
                  and CODFILIALDEPOSITO = P_CODFILIALDESTINO;

                return;
              exception
                when others then
                  P_RESULTADO := 3;
                  P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                                 ' - Erro ao atualizar os dados do próximo número de nota para o processo de remessa para deposito fechado, para a filial de destino ' || P_CODFILIALDESTINO ||
                                 ' - Filial origem: ' || P_CODIGOFILIAL || ' - ' ||
                                 sqlcode || ' - ' || sqlerrm;

                  raise SAIR_COM_ERRO;
               end;
            --------------fim melhoria-----------------------
            
            --------------Melhoria para buscar numerador diferente para notas de ajuste(ENTRADA)--------------
            --A = Ajuste
            elsif P_TIPONUMERADOR = 'A' then
                  --Nota sera enviado para o SEFAZ de Origem do Contribuinte de ICMS
                  begin
                    select DECODE(NVL(PCFILIAL.PROXNUMNOTAAJUSTE, 1),
                                  0,
                                  1,
                                  NVL(PCFILIAL.PROXNUMNOTAAJUSTE, 1)),
                           TO_NUMBER(DECODE(NVL(PCFILIAL.SERIENFEAJUSTE, 'U'),
                                            'U',
                                            '0',
                                            PCFILIAL.SERIENFEAJUSTE))
                      into P_NUMERO, P_SERIE
                      from PCFILIAL
                     where CODIGO = P_CODIGOFILIAL
                       for update;
                  exception
                    when NO_DATA_FOUND then
                      P_RESULTADO := 27;
                      P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                                     ' - Numerador para notas de ajuste não encontrou valor. ' ||
                                     sqlcode || ' - ' ||
                                     sqlerrm;

                      raise SAIR_COM_ERRO;
                    when others then
                      P_RESULTADO := 28;
                      P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                                     ' - Erro ao obter numerador para notas de ajuste.  "' ||
                                     P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                                     sqlerrm;

                      raise SAIR_COM_ERRO;
                  end;

                  /*
                           Atualiza na filial informada, o próximo número
                  */
                  begin
                    update PCFILIAL
                         set PCFILIAL.PROXNUMNOTAAJUSTE = P_NUMERO + 1
                       where CODIGO = P_CODIGOFILIAL;

                    return;
                  exception
                    when others then
                      P_RESULTADO := 3;
                      P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                                     ' - Erro ao atualizar os dados do próximo número de nota para notas de ajuste. ' ||
                                     sqlcode || ' - ' || sqlerrm;

                      raise SAIR_COM_ERRO;
                  end;
              --------------fim melhoria do ajuste-----------------------

              --------------Melhoria para buscar numerador diferente para serie por produto--------------
              --O = serie por produto
              elsif P_TIPONUMERADOR = 'O' then
                  begin
                    select PCFILIALSEQNFEPORPRODUTO.PROXNUMNOTA, PCFILIALSEQNFEPORPRODUTO.PROXNUMSERIE
                      into P_NUMERO, P_SERIE
                      from PCFILIALSEQNFEPORPRODUTO
                     where PCFILIALSEQNFEPORPRODUTO.CODFILIAL = P_CODIGOFILIAL
                       and PCFILIALSEQNFEPORPRODUTO.CODGRUPO = P_CODGRUPO_SEQ_PROD
                       for update;
                  exception
                    when NO_DATA_FOUND then
                      P_RESULTADO := 27;
                      P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                                     ' - Não foi encontrado registro de sequencia por produto para o grupo: "' || P_CODGRUPO_SEQ_PROD || '" e filial: ' || P_CODIGOFILIAL || '. ' ||
                                     sqlcode || ' - ' ||
                                     sqlerrm;

                      raise SAIR_COM_ERRO;
                    when others then
                      P_RESULTADO := 28;
                      P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                                     ' - Erro ao buscar os dados da filial na sequencia por produto "' ||
                                     P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                                     sqlerrm;

                      raise SAIR_COM_ERRO;
                  end;

                  /*
                           Atualiza na filial informada, o próximo número
                  */
                  begin
                    update PCFILIALSEQNFEPORPRODUTO
                       set PCFILIALSEQNFEPORPRODUTO.PROXNUMNOTA = P_NUMERO + 1
                     where CODFILIAL = P_CODIGOFILIAL
                       and CODGRUPO = P_CODGRUPO_SEQ_PROD;

                    return;
                  exception
                    when others then
                      P_RESULTADO := 3;
                      P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                                     ' - Erro ao atualizar os dados do próximo número de nota para o processo de sequência por produto na filial: ' || P_CODIGOFILIAL ||
                                     ' - grupo: ' || P_CODGRUPO_SEQ_PROD || ' - ' ||
                                     sqlcode || ' - ' || sqlerrm;

                      raise SAIR_COM_ERRO;
                  end;
              --------------fim melhoria serie por produto-----------------------

            ELSE
              -- Movimenta??o Manifesto
              IF (NVL(PARAMFILIAL.ObterComoVarchar2('TIPONUMNOTAMANIF', P_CODIGOFILIAL), 'M') = 'M') THEN
                begin
                  select DECODE(NVL(PCFILIAL.PROXNUMNFEDEVMANISFESTO, 1),
                                0,
                                1,
                                NVL(PCFILIAL.PROXNUMNFEDEVMANISFESTO, 1)),
                         TO_NUMBER(DECODE(NVL(PCFILIAL.SERIENFEDEVMANIFESTO,
                                              'U'),
                                          'U',
                                          '0',
                                          PCFILIAL.SERIENFEDEVMANIFESTO))
                    into P_NUMERO, P_SERIE
                    from PCFILIAL
                   where CODIGO = P_CODIGOFILIAL
                     for update;
                exception
                  when NO_DATA_FOUND then
                    P_RESULTADO := 16;
                    P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                                   ' - Não foi encontrado registro da filial "' ||
                                   P_CODIGOFILIAL || '". ' || sqlcode ||
                                   ' - ' || sqlerrm;

                  when others then
                    P_RESULTADO := 17;
                    P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                                   ' - Erro ao buscar os dados da filial "' ||
                                   P_CODIGOFILIAL || '". ' || sqlcode ||
                                   ' - ' || sqlerrm;

                end;
                /*
                         Atualiza na filial informada, o próximo número
                */
                if P_RESULTADO = 0 then
                  begin
                    update PCFILIAL
                         set PCFILIAL.PROXNUMNFEDEVMANISFESTO = P_NUMERO + 1
                     where CODIGO = P_CODIGOFILIAL;

                    return;
                  exception
                    when others then
                      P_RESULTADO := 18;
                        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                                       ' - Erro ao atualizar os dados do próximo número de nota. ' ||
                                       ' - Filial: ' || P_CODIGOFILIAL || ' - ' ||
                                       sqlcode || ' - ' || sqlerrm;

                      return;
                  end;
                else

                  return;

                end if;

              ELSIF (NVL(PARAMFILIAL.ObterComoVarchar2('TIPONUMNOTAMANIF', P_CODIGOFILIAL),
                       'M') = 'U') THEN
                begin
                  select DECODE(NVL(PCFILIAL.PROXNUMNFE, 1),
                                0,
                                1,
                                NVL(PCFILIAL.PROXNUMNFE, 1)),
                           TO_NUMBER(DECODE(NVL(PCFILIAL.SERIENFE, 'U'),
                                          'U',
                                          '0',
                                          PCFILIAL.SERIENFE))

                    into P_NUMERO, P_SERIE
                    from PCFILIAL
                   where CODIGO = P_CODIGOFILIAL
                     for update;
                exception
                  when NO_DATA_FOUND then
                    P_RESULTADO := 10;
                    P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                                     ' - Não foi encontrado registro da filial "' ||
                                     P_CODIGOFILIAL || '". ' || sqlcode ||
                                   ' - ' || sqlerrm;

                  when others then
                    P_RESULTADO := 11;
                    P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                                     ' - Erro ao buscar os dados da filial "' ||
                                     P_CODIGOFILIAL || '". ' || sqlcode ||
                                   ' - ' || sqlerrm;

                end;
                /*
                           Atualiza na filial informada, o próximo número
                */
                if P_RESULTADO = 0 then
                  begin
                    update PCFILIAL
                       set PCFILIAL.PROXNUMNFE = P_NUMERO + 1
                     where CODIGO = P_CODIGOFILIAL;

                    return;
                  exception
                    when others then
                      P_RESULTADO := 12;
                        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                                       ' - Erro ao atualizar os dados do próximo número de nota. ' ||
                                       ' - Filial: ' || P_CODIGOFILIAL || ' - ' ||
                                       sqlcode || ' - ' || sqlerrm;

                      return;
                  end;
                else

                  return;
                end if;
            end if;
          end if;
        
        --end if;
          --      end if;--
      --end if;
    -- end if;
    else

      -- SCAN
      if P_TIPONUMERADOR = 'P' then
        --Nota ser? enviado para o SCAN(Sistema de Contig?ncia Ambiente Nacional) SEFAZ de Origem Não est? recebendo as notas
        begin
          select DECODE(NVL(PCFILIAL.PROXNUMNFESCAN, 1),
                        0,
                        1,
                        NVL(PCFILIAL.PROXNUMNFESCAN, 1)),
                 TO_NUMBER(DECODE(NVL(PCFILIAL.SERIENFESCAN, 'U'),
                                  'U',
                                  '900',
                                  PCFILIAL.SERIENFESCAN))

            into P_NUMERO, P_SERIE
            from PCFILIAL
           where CODIGO = P_CODIGOFILIAL
             for update;
        exception
          when NO_DATA_FOUND then
            P_RESULTADO := 19;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Não foi encontrado registro da filial "' ||
                           P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                           sqlerrm;

          when others then
            P_RESULTADO := 20;
            P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                           ' - Erro ao buscar os dados da filial "' ||
                           P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                           sqlerrm;

        end;
        /*
                 Atualiza na filial informada, o próximo número
        */
        if P_RESULTADO = 0 then
          begin
            update PCFILIAL
               set PCFILIAL.PROXNUMNFESCAN = P_NUMERO + 1
             where CODIGO = P_CODIGOFILIAL;

            return;
          exception
            when others then
              P_RESULTADO := 21;
              P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                             ' - Erro ao atualizar os dados do próximo número de nota. ' ||
                             ' - Filial: ' || P_CODIGOFILIAL || ' - ' ||
                             sqlcode || ' - ' || sqlerrm;

              return;
          end;
        else

          return;
        end if;
      else
        if P_TIPONUMERADOR = 'I' then
          --Nota ser? enviado para o SCAN(Sistema de Contig?ncia Ambiente Nacional) SEFAZ de Origem Não est? recebendo as notas
          begin
            select DECODE(NVL(PCFILIAL.PROXNUMNFESCANIMPORTACAO, 1),
                          0,
                          1,
                          NVL(PCFILIAL.PROXNUMNFESCANIMPORTACAO, 1)),
                   TO_NUMBER(DECODE(NVL(PCFILIAL.SERIENFESCANIMPORTACAO,
                                        'U'),
                                    'U',
                                    '900',
                                    PCFILIAL.SERIENFESCANIMPORTACAO))

              into P_NUMERO, P_SERIE
              from PCFILIAL
             where CODIGO = P_CODIGOFILIAL
               for update;
          exception
            when NO_DATA_FOUND then
              P_RESULTADO := 19;
              P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                             ' - Não foi encontrado registro da filial importacao scan"' ||
                             P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                             sqlerrm;

            when others then
              P_RESULTADO := 20;
              P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                             ' - Erro ao buscar os dados da filial importacao scan"' ||
                             P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                             sqlerrm;

          end;
          /*
                   Atualiza na filial informada, o próximo número
          */
          if P_RESULTADO = 0 then
            begin
              update PCFILIAL
                 set PCFILIAL.PROXNUMNFESCANIMPORTACAO = P_NUMERO + 1
               where CODIGO = P_CODIGOFILIAL;

              return;
            exception
              when others then
                P_RESULTADO := 21;
                P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                               ' - Erro ao atualizar os dados do próximo número de nota importacao scan. ' ||
                               ' - Filial: ' || P_CODIGOFILIAL || ' - ' ||
                               sqlcode || ' - ' || sqlerrm;

                return;
            end;
          else

            return;
          end if;
        else
          if P_TIPONUMERADOR = 'E' then
            begin
              select DECODE(NVL(PCFILIAL.PROXNUMNFESCANENTRADA, 1),
                            0,
                            1,
                            NVL(PCFILIAL.PROXNUMNFESCANENTRADA, 1)),
                     TO_NUMBER(DECODE(NVL(PCFILIAL.SERIENFESCANENTRADA, 'U'),
                                      'U',
                                      '900',
                                      PCFILIAL.SERIENFESCANENTRADA))
                into P_NUMERO, P_SERIE
                from PCFILIAL
               where CODIGO = P_CODIGOFILIAL
                 for update;
            exception
              when NO_DATA_FOUND then
                P_RESULTADO := 22;
                P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                               ' - Não foi encontrado registro da filial "' ||
                               P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                               sqlerrm;

              when others then
                P_RESULTADO := 23;
                P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                               ' - Erro ao buscar os dados da filial "' ||
                               P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                               sqlerrm;

            end;
            /*
                     Atualiza na filial informada, o próximo número
            */
            if P_RESULTADO = 0 then
              begin
                update PCFILIAL
                   set PCFILIAL.PROXNUMNFESCANENTRADA = P_NUMERO + 1
                 where CODIGO = P_CODIGOFILIAL;

                return;
              exception
                when others then
                  P_RESULTADO := 24;
                  P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                                 ' - Erro ao atualizar os dados do próximo número de nota. ' ||
                                 ' - Filial: ' || P_CODIGOFILIAL || ' - ' ||
                                 sqlcode || ' - ' || sqlerrm;

                  return;
              end;
            else

              return;
            end if;

          else
            -- DEVOLU??O MANIFESTO SCAN
            begin
              select DECODE(NVL(PCFILIAL.PROXNUMNFEDEVMANISFESTOSCAN, 1),
                            0,
                            1,
                            NVL(PCFILIAL.PROXNUMNFEDEVMANISFESTOSCAN, 1)),
                     TO_NUMBER(DECODE(NVL(PCFILIAL.SERIENFEDEVMANIFESTOSCAN,
                                          'U'),
                                      'U',
                                      '900',
                                      PCFILIAL.SERIENFEDEVMANIFESTOSCAN))
                into P_NUMERO, P_SERIE
                from PCFILIAL
               where CODIGO = P_CODIGOFILIAL
                 for update;
            exception
              when NO_DATA_FOUND then
                P_RESULTADO := 22;
                P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                               ' - Não foi encontrado registro da filial "' ||
                               P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                               sqlerrm;

              when others then
                P_RESULTADO := 23;
                P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                               ' - Erro ao buscar os dados da filial "' ||
                               P_CODIGOFILIAL || '". ' || sqlcode || ' - ' ||
                               sqlerrm;

            end;
            /*
                     Atualiza na filial informada, o próximo número
            */
            if P_RESULTADO = 0 then
              begin
                update PCFILIAL
                   set PCFILIAL.PROXNUMNFEDEVMANISFESTOSCAN = P_NUMERO + 1
                 where CODIGO = P_CODIGOFILIAL;

                return;
              exception
                when others then
                  P_RESULTADO := 24;
                  P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                                 ' - Erro ao atualizar os dados do próximo número de nota. ' ||
                                 ' - Filial: ' || P_CODIGOFILIAL || ' - ' ||
                                 sqlcode || ' - ' || sqlerrm;

                  return;
              end;
            else

              return;
            end if;
          end if;
        end if;
        -- FIM DEVOLU??O MANIFESTO SCAN
      end if;

    end if;
  end if;

exception
  when SAIR_COM_ERRO then
    begin
      if P_RESULTADO = 0 then
        P_RESULTADO := 1000;
        P_MENSAGEM  := 'Erro desconhecido!';
        GERAR_LOG('SAIR_COM_ERRO',
                  sqlerrm,
                  DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);

      end if;
    end;

  when others then
    begin
      P_RESULTADO := 1000;
      P_MENSAGEM  := 'Ocorreu um erro ao obter próximo número de nota: ' ||
                     sqlcode || '-' || sqlerrm;
      GERAR_LOG('OUTROS', sqlerrm, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);

    end;

end OBTERPROXIMONUMERONFE;
--04/04/2014 - Eddy Pereira (última alteração: retidado controle de sessão)
--10/05/2016 - Eddy Pereira (Criada opção para buscar numerador nfe difenrete para notas de transferência para depósito fechado)
--14/09/2016 - Eddy Pereira (melhoria para passar a pegar a serie diferente quando nota de devolução de transferência para depósito fechado)
--18/05/2017 - Eddy Pereira (melhoria para passar a pegar a serie diferente quando nota de devolução de transferência para depósito fechado, por filial de destino)
--07/10/2019 - Eddy Pereira (Melhoria para buscar uma sequencia diferente para notas de ajuste, tanto de saida quanto de entrada)
