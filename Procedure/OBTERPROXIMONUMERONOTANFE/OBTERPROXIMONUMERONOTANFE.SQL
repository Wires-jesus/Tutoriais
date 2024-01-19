create or replace procedure OBTERPROXIMONUMERONOTANFE(P_CODIGOFILIAL in varchar2 default '',
                                                      P_TRANSACAO    in number default 0,
                                                      P_MOVIMENTO    in varchar2 default '',
                                                      P_SEFAZORIGEM  in varchar2 default 'S',
                                                      P_NUMERO       out number,
                                                      P_SERIE        out number,
                                                      P_RESULTADO    out number,
                                                      P_MENSAGEM     out varchar2) is

  USANUMNFDEVCLI         PCFILIAL.USANUMNFDEVCLI%type;
  GERANFVENDA            PCNFENT.GERANFVENDA%type;
  TIPONUMNFENTRADA       PCFILIAL.TIPONUMNFENTRADA%type;
  TIPODESCARGA           PCNFENT.TIPODESCARGA%type;
  NUMNOTA_ATUAL          PCNFSAID.NUMNOTA%type;
  SERIE_ATUAL            PCNFSAID.SERIE%type;
  SERIE_ATUAL_SCAN       PCFILIAL.SERIENFESCAN%type;
  JA_UTILIZOUNUMNFE      PCNFSAID.CONSUMIUNUMNFE%type;
  NUMERO_PEDIDO_ATUAL    PCNFSAID.NUMPED%type;
  TIPO_EMISSAO           PCNFSAID.TIPOEMISSAO%type;
  CONTROLE_NFE_POR_SERIE PCFILIAL.CONTROLENFEPORSERIE%type;
  CONTROLE_NFE_POR_ROTA  PCFILIAL.CONTROLENFEPORROTA%type;
  UTILIZASEQNFENT        PCFILIAL.UTILIZASEQNFENT%TYPE;
  TIPO_VENDA             PCNFSAID.CONDVENDA%type;
  TIPONUMERADOR          varchar2(1);
  NUMTRANSACAOORIG       number(10);
  V_NUMCAR               PCNFSAID.NUMCAR%type;
  ROTA_PRINCIPAL         varchar2(4);
  ORIGEM_PED             varchar2(1);
  ID_REGISTRO_ATUAL      varchar2(50);
  EXISTE_REGISTRO        boolean;
  VOLTAR_COM_NUMERACAO_ATUAL exception;
  SAIR_COM_ERRO              exception;
  NUMERO_CARREGAMENTO_ZERO   exception;
  SITUACAO_NFE         PCNFSAID.SITUACAONFE%type;
  V_NUMTRANSORIGEM_DEP PCNFSAID.NUMTRANSVENDA%type;
  P_CODCONT            PCNFENT.CODCONT%TYPE;
  NUMTRANSACAO_VENDA   PCNFSAID.NUMTRANSVENDA%type;
  FINALIDADENFE        PCNFSAID.FINALIDADENFE%TYPE;
  NUMTRANSVENDAORIGEM  PCNFSAID.NUMTRANSVENDAORIGEM%TYPE;
  TIPOVENDA_NF         PCNFSAID.TIPOVENDA%TYPE;

  CONTROLE_NFE_DEP_FECHADO    PCFILIAL.CONTROLENFEPORSERIEDEPOFECHADO%type;
  GERAR_NUM_SERIE_DEP_FECHADO varchar2(1);

  V_CODFILIALDESTINO         PCFILIAL.CODIGO%TYPE;
  V_NUMTRANSACAO_VENDA_TRASF PCNFSAID.NUMTRANSVENDA%type;

  V_CONT_NOTA_SAIDA number(18, 0);
  NOTA_DUPLICADA_PREFAT exception;
  
  SERIE_POR_PRODUTO     VARCHAR2(1);
  V_CODGRUPO_SEQ_PROD   PCFILIALSEQNFEPORPRODUTO.CODGRUPO%TYPE;
  
  V_QTD_REGISTROS_TEMP  number(10);

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
       'ERRO FUNCTION OBTERPROXIMONUMERONOTANFE' || PSITUACAO_ERRO,
       SUBSTR('ERRO ORIGINAL: ' || PMENSAGEM_ERRO, 1, 89) ||
       SUBSTR(PLINHA_ERRO, 1, 10));
  end;
  ----------------------

begin
  P_NUMERO                   := 0;
  P_SERIE                    := 0;
  P_RESULTADO                := 0;
  NUMERO_PEDIDO_ATUAL        := 0;
  NUMTRANSACAOORIG           := 0;
  V_NUMCAR                   := 0;
  P_MENSAGEM                 := '';
  USANUMNFDEVCLI             := '';
  TIPONUMNFENTRADA           := '';
  TIPONUMERADOR              := 'P';
  ORIGEM_PED                 := '';
  V_CODFILIALDESTINO         := '';
  V_NUMTRANSACAO_VENDA_TRASF := 0;
  V_CONT_NOTA_SAIDA          := 0;
  TIPOVENDA_NF               := '';
  SERIE_POR_PRODUTO          := 'N';
  V_QTD_REGISTROS_TEMP       := 0;

  if UPPER(P_MOVIMENTO) = 'S' then
    --Movimento de Saída

    if (P_TRANSACAO = 0) then
      P_RESULTADO := 219;
      P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                     ' - Transação da nota fiscal de Saída inválida(transação com valor igual a zero).' ||
                     sqlcode || ' - ' || sqlerrm;
      raise SAIR_COM_ERRO;
    end if;

    begin
      for NOTA_SAIDA IN (select PCNFSAID.NUMNOTA,
                                PCNFSAID.SERIE,
                                PCFILIAL.SERIENFESCAN,
                                NVL(PCNFSAID.NUMTRANSENTORIGEM, 0) NUMTRANSENTORIGEM,
                                NVL(PCNFSAID.NUMPED, 0) NUMPED,
                                NVL(PCNFSAID.CONSUMIUNUMNFE, 'N') CONSUMIUNUMNFE,
                                NVL(PCNFSAID.TIPOEMISSAO, '1') TIPOEMISSAO,
                                NVL(PCFILIAL.CONTROLENFEPORSERIE, 'N') CONTROLENFEPORSERIE,
                                NVL(PCFILIAL.CONTROLENFEPORROTA, 'N') CONTROLENFEPORROTA,
                                NVL(PCNFSAID.CONDVENDA, 0) CONDVENDA,
                                PCPEDC.ORIGEMPED,
                                NVL(PCNFSAID.NUMCAR, 0) NUMCAR,
                                NVL(SITUACAONFE, 0) SITUACAONFE,
                                NVL(PCFILIAL.CONTROLENFEPORSERIEDEPOFECHADO,
                                    'N') CONTROLENFEPORSERIEDEPOFECHADO,
                                PCNFSAID.FINALIDADENFE,
                                PCNFSAID.NUMTRANSVENDAORIGEM,
                                'N' PREFATURAMENTO,
                                NVL(PCNFSAID.TIPOVENDA, 'X') TIPOVENDA
                           from PCNFSAID, PCFILIAL, PCPEDC
                          where NVL(PCNFSAID.CODFILIALNF, PCNFSAID.CODFILIAL) =
                                PCFILIAL.CODIGO
                            and PCNFSAID.NUMTRANSVENDA = P_TRANSACAO
                            and PCNFSAID.NUMTRANSVENDA =
                                PCPEDC.NUMTRANSVENDA(+)
                            and PCNFSAID.NUMPED = PCPEDC.NUMPED(+)
                         UNION ALL
                         select PCNFSAIDPREFAT.NUMNOTA,
                                PCNFSAIDPREFAT.SERIE,
                                PCFILIAL.SERIENFESCAN,
                                NVL(PCNFSAIDPREFAT.NUMTRANSENTORIGEM, 0) NUMTRANSENTORIGEM,
                                NVL(PCNFSAIDPREFAT.NUMPED, 0) NUMPED,
                                NVL(PCNFSAIDPREFAT.CONSUMIUNUMNFE, 'N') CONSUMIUNUMNFE,
                                NVL(PCNFSAIDPREFAT.TIPOEMISSAO, '1') TIPOEMISSAO,
                                NVL(PCFILIAL.CONTROLENFEPORSERIE, 'N') CONTROLENFEPORSERIE,
                                NVL(PCFILIAL.CONTROLENFEPORROTA, 'N') CONTROLENFEPORROTA,
                                NVL(PCNFSAIDPREFAT.CONDVENDA, 0) CONDVENDA,
                                PCPEDC.ORIGEMPED,
                                NVL(PCNFSAIDPREFAT.NUMCAR, 0) NUMCAR,
                                NVL(SITUACAONFE, 0) SITUACAONFE,
                                NVL(PCFILIAL.CONTROLENFEPORSERIEDEPOFECHADO,
                                    'N') CONTROLENFEPORSERIEDEPOFECHADO,
                                PCNFSAIDPREFAT.FINALIDADENFE,
                                PCNFSAIDPREFAT.NUMTRANSVENDAORIGEM,
                                'S' PREFATURAMENTO,
                                NVL(PCNFSAIDPREFAT.TIPOVENDA, 'X') TIPOVENDA
                           from PCNFSAIDPREFAT, PCFILIAL, PCPEDC
                          where NVL(PCNFSAIDPREFAT.CODFILIALNF,
                                    PCNFSAIDPREFAT.CODFILIAL) =
                                PCFILIAL.CODIGO
                            and PCNFSAIDPREFAT.NUMTRANSVENDA = P_TRANSACAO
                            and PCNFSAIDPREFAT.NUMTRANSVENDA =
                                PCPEDC.NUMTRANSVENDA(+)
                            and PCNFSAIDPREFAT.NUMPED = PCPEDC.NUMPED(+)
                            AND PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT IS NULL) loop
        V_CONT_NOTA_SAIDA        := V_CONT_NOTA_SAIDA + 1;
        NUMNOTA_ATUAL            := NOTA_SAIDA.NUMNOTA;
        SERIE_ATUAL              := NOTA_SAIDA.SERIE;
        SERIE_ATUAL_SCAN         := NOTA_SAIDA.SERIENFESCAN;
        NUMTRANSACAOORIG         := NOTA_SAIDA.NUMTRANSENTORIGEM;
        NUMERO_PEDIDO_ATUAL      := NOTA_SAIDA.NUMPED;
        JA_UTILIZOUNUMNFE        := NOTA_SAIDA.CONSUMIUNUMNFE;
        TIPO_EMISSAO             := NOTA_SAIDA.TIPOEMISSAO;
        CONTROLE_NFE_POR_SERIE   := NOTA_SAIDA.CONTROLENFEPORSERIE;
        CONTROLE_NFE_POR_ROTA    := NOTA_SAIDA.CONTROLENFEPORROTA;
        TIPO_VENDA               := NOTA_SAIDA.CONDVENDA;
        ORIGEM_PED               := NOTA_SAIDA.ORIGEMPED;
        V_NUMCAR                 := NOTA_SAIDA.NUMCAR;
        SITUACAO_NFE             := NOTA_SAIDA.SITUACAONFE;
        CONTROLE_NFE_DEP_FECHADO := NOTA_SAIDA.CONTROLENFEPORSERIEDEPOFECHADO;
        FINALIDADENFE            := NOTA_SAIDA.FINALIDADENFE;
        TIPOVENDA_NF             := NOTA_SAIDA.TIPOVENDA;
      end loop;

      if (V_CONT_NOTA_SAIDA <= 0) then
        raise NO_DATA_FOUND;
      end if;
      if (V_CONT_NOTA_SAIDA > 1) then
        raise NOTA_DUPLICADA_PREFAT;
      end if;
    exception
      when NO_DATA_FOUND then
        P_RESULTADO := 48;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Não foi encontrado registro na tabela PCNFSAID com este número de transação. ' ||
                       sqlcode || ' - ' || sqlerrm;
        raise SAIR_COM_ERRO;

      when NOTA_DUPLICADA_PREFAT then
        P_RESULTADO := 49;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Registro na tabela PCNFSAID com este número de transação está duplicado na PCNFSAIDPREFAT. ' ||
                       sqlcode || ' - ' || sqlerrm;
        raise SAIR_COM_ERRO;
      when others then
        P_RESULTADO := 49;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao buscar os dados na tabela PCNFSAID. ' ||
                       sqlcode || ' - ' || sqlerrm;
        raise SAIR_COM_ERRO;
    end;

    if SITUACAO_NFE = 100 then
      P_RESULTADO := 50;
      P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                     ' - Nota fiscal já aprovada! Não é possível obter próximo numero.';

      P_NUMERO := NUMNOTA_ATUAL;
      P_SERIE  := SERIE_ATUAL;
      raise SAIR_COM_ERRO;
    end if;

    if NVL(CONTROLE_NFE_POR_SERIE, 'N') = 'N' then
      if P_SEFAZORIGEM = 'N' then
        SERIE_ATUAL := SERIE_ATUAL_SCAN;
      end if;

      raise VOLTAR_COM_NUMERACAO_ATUAL;
    end if;
    
    --------------------------------------serie especifica por produto----------------------------------------------
    begin
      FOR PRODS IN (SELECT 'S' AS SERIE_POR_PRODUTO, PCFILIALSEQNFEPORPRODUTO.CODGRUPO
                      FROM PCMOV, 
                           PCPRODFILIAL, 
                           PCFILIALSEQNFEPORPRODUTO
                     WHERE 1 = 1
                       AND PCMOV.CODFILIAL = PCPRODFILIAL.CODFILIAL
                       AND PCMOV.CODPROD = PCPRODFILIAL.CODPROD      
                       AND PCPRODFILIAL.CODFILIAL = PCFILIALSEQNFEPORPRODUTO.CODFILIAL
                       AND PCPRODFILIAL.CODGRUPOSEQNFE = PCFILIALSEQNFEPORPRODUTO.CODGRUPO      
                       AND PCMOV.NUMTRANSVENDA = P_TRANSACAO 
                       
                       UNION
                       
                    SELECT 'S' AS SERIE_POR_PRODUTO, PCFILIALSEQNFEPORPRODUTO.CODGRUPO
                      FROM PCMOVPREFAT, 
                           PCPRODFILIAL, 
                           PCFILIALSEQNFEPORPRODUTO
                     WHERE 1 = 1
                       AND PCMOVPREFAT.CODFILIAL = PCPRODFILIAL.CODFILIAL
                       AND PCMOVPREFAT.CODPROD = PCPRODFILIAL.CODPROD      
                       AND PCPRODFILIAL.CODFILIAL = PCFILIALSEQNFEPORPRODUTO.CODFILIAL
                       AND PCPRODFILIAL.CODGRUPOSEQNFE = PCFILIALSEQNFEPORPRODUTO.CODGRUPO      
                       AND PCMOVPREFAT.NUMTRANSVENDA = P_TRANSACAO) LOOP
                       
           SERIE_POR_PRODUTO := PRODS.SERIE_POR_PRODUTO;
           V_CODGRUPO_SEQ_PROD := PRODS.CODGRUPO ;
      
         END LOOP;
    exception
      when others then
        SERIE_POR_PRODUTO := 'N';  
    end;
    --------------------------------------serie especifica por produto----------------------------------------------    

    if TIPO_VENDA = 14 then
      TIPONUMERADOR := 'M';

      if CONTROLE_NFE_POR_ROTA = 'S' then
        TIPONUMERADOR := 'R';

        begin
          if NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('ROTAUTILIZADAVENDATIPO14',
                                               99),
                 'RP') = 'RP' then
            if V_NUMCAR > 0 then

              select PCCARREG.CODROTAPRINC
                into ROTA_PRINCIPAL
                from PCCARREG
               where PCCARREG.NUMCAR = V_NUMCAR;
            else
              raise NUMERO_CARREGAMENTO_ZERO;
            end if;
          else
            V_CONT_NOTA_SAIDA := 0;
            for NOTA_ROTA IN (select PCUSUARI.CODROTA
                                from PCNFSAID, PCUSUARI
                               where PCUSUARI.CODUSUR = PCNFSAID.CODUSUR
                                 and PCNFSAID.NUMTRANSVENDA = P_TRANSACAO
                              UNION ALL
                              select PCUSUARI.CODROTA
                                from PCNFSAIDPREFAT, PCUSUARI
                               where PCUSUARI.CODUSUR =
                                     PCNFSAIDPREFAT.CODUSUR
                                 and PCNFSAIDPREFAT.NUMTRANSVENDA =
                                     P_TRANSACAO) loop
              V_CONT_NOTA_SAIDA := V_CONT_NOTA_SAIDA + 1;
              ROTA_PRINCIPAL    := NOTA_ROTA.CODROTA;
            end loop;
            if (V_CONT_NOTA_SAIDA <= 0) then
              raise NO_DATA_FOUND;
            end if;
            if (V_CONT_NOTA_SAIDA > 1) then
              raise NOTA_DUPLICADA_PREFAT;
            end if;
          end if;
        exception
          when NUMERO_CARREGAMENTO_ZERO then
            P_RESULTADO := 51;
            P_MENSAGEM  := 'Codigo: ' || P_RESULTADO ||
                           ' - Erro ao buscar rota principal o número do carregamento e igual a zero: ' ||
                           sqlcode || ' - ' || sqlerrm;
            raise SAIR_COM_ERRO;
          when NOTA_DUPLICADA_PREFAT then
            P_RESULTADO := 51;
            P_MENSAGEM  := 'Codigo: ' || P_RESULTADO ||
                           ' - Erro ao buscar rota principal, registro na tabela PCNFSAID com este número de transação está duplicado na PCNFSAIDPREFAT: ' ||
                           sqlcode || ' - ' || sqlerrm;
            raise SAIR_COM_ERRO;
          when others then
            P_RESULTADO := 51;
            P_MENSAGEM  := 'Codigo: ' || P_RESULTADO ||
                           ' - Erro ao buscar rota principal para obter proximo numero de nota: ' ||
                           sqlcode || ' - ' || sqlerrm;
            raise SAIR_COM_ERRO;
        end;

      end if;
    end if;

    --pega sequencia específica para notas de ajuste
    if ((NVL(PARAMFILIAL.ObterComoVarchar2('USANUMNOTASERIEAJUSTE',
                                           P_CODIGOFILIAL),
             'N') = 'S') and (FINALIDADENFE = 'A')) then
      TIPONUMERADOR := 'A';
    end if;

    ---Melhoria para passar a consumir uma serie e numeração difernetes para nota de transferencia de deposito fechado---
    ---HIS.01350.2016 - Eddy Pereira
    if (CONTROLE_NFE_DEP_FECHADO = 'S') then
      begin
        --Buscar dados da pcmov para identificar se nota é de transferencia para deposito fechado
        --PRIMEIRA VALIDAÇÃO
        BEGIN
          FOR A IN (SELECT DISTINCT PCMOV.CODFISCAL
                      FROM PCMOV
                     WHERE PCMOV.NUMTRANSVENDA = P_TRANSACAO
                       AND ROWNUM = 1
                    UNION ALL
                    SELECT DISTINCT PCMOVPREFAT.CODFISCAL
                      FROM PCMOVPREFAT
                     WHERE PCMOVPREFAT.NUMTRANSVENDA = P_TRANSACAO
                       AND PCMOVPREFAT.DATACONSOLIDACAOPREFAT IS NULL
                       AND ROWNUM = 1) LOOP
            IF A.CODFISCAL IN ('1905',
                               '1906',
                               '1907',
                               '1934',
                               '2905',
                               '2906',
                               '2907',
                               '2934',
                               '5905',
                               '5906',
                               '5907',
                               '5934',
                               '6905',
                               '6906',
                               '6907',
                               '6934') THEN
              GERAR_NUM_SERIE_DEP_FECHADO := 'S';
            ELSE
              GERAR_NUM_SERIE_DEP_FECHADO := 'N';
            END IF;
          END LOOP;
        EXCEPTION
          WHEN OTHERS THEN
            GERAR_NUM_SERIE_DEP_FECHADO := 'N';
        END;

        --SEGUNDA VALIDAÇÃO
        --CASO A VALIDAÇÃO ACIMA NÃO RETORNE VERDADEIRO, FAZER A FALIDAÇÃO ABAIXO
        IF GERAR_NUM_SERIE_DEP_FECHADO = 'N' THEN
          BEGIN
            FOR B IN (SELECT DISTINCT NVL(PCNFSAID.CODFILIAL,
                                          PCNFSAID.CODFILIALNF) AS CODFILIAL,
                                      NVL(PCNFSAID.CODFILIALNF,
                                          PCNFSAID.CODFILIAL) AS CODFILIALNF,
                                      PCMOV.CODFILIALRETIRA
                        FROM PCMOV, PCNFSAID
                       WHERE PCMOV.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA
                         AND PCNFSAID.NUMTRANSVENDA = P_TRANSACAO
                         AND ROWNUM = 1
                      UNION ALL
                      SELECT DISTINCT NVL(PCNFSAIDPREFAT.CODFILIAL,
                                          PCNFSAIDPREFAT.CODFILIALNF) AS CODFILIAL,
                                      NVL(PCNFSAIDPREFAT.CODFILIALNF,
                                          PCNFSAIDPREFAT.CODFILIAL) AS CODFILIALNF,
                                      PCMOVPREFAT.CODFILIALRETIRA
                        FROM PCMOVPREFAT, PCNFSAIDPREFAT
                       WHERE PCMOVPREFAT.NUMTRANSVENDA =
                             PCNFSAIDPREFAT.NUMTRANSVENDA
                         AND PCNFSAIDPREFAT.NUMTRANSVENDA = P_TRANSACAO
                         AND PCMOVPREFAT.DATACONSOLIDACAOPREFAT IS NULL
                         AND ROWNUM = 1) LOOP
              IF (VENDAS.TIPO_TRANSFERENCIA(B.CODFILIAL,
                                            B.CODFILIALRETIRA,
                                            B.CODFILIALNF) IN ('R', 'VR')) THEN
                GERAR_NUM_SERIE_DEP_FECHADO := 'S';
              ELSE
                GERAR_NUM_SERIE_DEP_FECHADO := 'N';
              END IF;
            END LOOP;
          EXCEPTION
            WHEN OTHERS THEN
              GERAR_NUM_SERIE_DEP_FECHADO := 'N';
          END;
        END IF;

        IF ((GERAR_NUM_SERIE_DEP_FECHADO = 'N') AND
           (NVL(FINALIDADENFE, 'X') = 'C')) AND
           (NVL(NUMTRANSVENDAORIGEM, 0) > 0) THEN
          BEGIN
            FOR B IN (SELECT DISTINCT NVL(PCNFSAID.CODFILIAL,
                                          PCNFSAID.CODFILIALNF) AS CODFILIAL,
                                      NVL(PCNFSAID.CODFILIALNF,
                                          PCNFSAID.CODFILIAL) AS CODFILIALNF,
                                      PCMOV.CODFILIALRETIRA
                        FROM PCMOV, PCNFSAID
                       WHERE PCMOV.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA
                         AND PCNFSAID.NUMTRANSVENDA = NUMTRANSVENDAORIGEM
                         AND ROWNUM = 1
                      UNION ALL
                      SELECT DISTINCT NVL(PCNFSAIDPREFAT.CODFILIAL,
                                          PCNFSAIDPREFAT.CODFILIALNF) AS CODFILIAL,
                                      NVL(PCNFSAIDPREFAT.CODFILIALNF,
                                          PCNFSAIDPREFAT.CODFILIAL) AS CODFILIALNF,
                                      PCMOVPREFAT.CODFILIALRETIRA
                        FROM PCMOVPREFAT, PCNFSAIDPREFAT
                       WHERE PCMOVPREFAT.NUMTRANSVENDA =
                             PCNFSAIDPREFAT.NUMTRANSVENDA
                         AND PCNFSAIDPREFAT.NUMTRANSVENDA =
                             NUMTRANSVENDAORIGEM
                         AND PCMOVPREFAT.DATACONSOLIDACAOPREFAT IS NULL
                         AND ROWNUM = 1) LOOP
              IF (VENDAS.TIPO_TRANSFERENCIA(B.CODFILIAL,
                                            B.CODFILIALRETIRA,
                                            B.CODFILIALNF) IN ('R', 'VR')) THEN
                FOR A IN (SELECT DISTINCT PCMOV.CODFISCAL
                            FROM PCMOV
                           WHERE PCMOV.NUMTRANSVENDA = NUMTRANSVENDAORIGEM
                             AND ROWNUM = 1
                          UNION ALL
                          SELECT DISTINCT PCMOVPREFAT.CODFISCAL
                            FROM PCMOVPREFAT
                           WHERE PCMOVPREFAT.NUMTRANSVENDA =
                                 NUMTRANSVENDAORIGEM
                             AND PCMOVPREFAT.DATACONSOLIDACAOPREFAT IS NULL
                             AND ROWNUM = 1) LOOP
                  IF A.CODFISCAL IN ('1905',
                                     '1906',
                                     '1907',
                                     '1934',
                                     '2905',
                                     '2906',
                                     '2907',
                                     '2934',
                                     '5905',
                                     '5906',
                                     '5907',
                                     '5934',
                                     '6905',
                                     '6906',
                                     '6907',
                                     '6934') THEN
                    GERAR_NUM_SERIE_DEP_FECHADO := 'S';
                  ELSE
                    GERAR_NUM_SERIE_DEP_FECHADO := 'N';
                  END IF;
                END LOOP;
              ELSE
                GERAR_NUM_SERIE_DEP_FECHADO := 'N';
              END IF;
            END LOOP;

          EXCEPTION
            WHEN OTHERS THEN
              GERAR_NUM_SERIE_DEP_FECHADO := 'N';
          END;
        END IF;

      exception
        when others then
          GERAR_NUM_SERIE_DEP_FECHADO := 'N';
      end;

    end if;

    if (JA_UTILIZOUNUMNFE = 'N') then

      IF ((CONTROLE_NFE_DEP_FECHADO = 'S') AND
         (GERAR_NUM_SERIE_DEP_FECHADO = 'S')) THEN
        TIPONUMERADOR := 'D';

        BEGIN
          --Para o vendas, a filial de origem, é de onde saiu a mercadoria
          --Para o fiscal, a origem é a de emissão da nota
          SELECT PCTRANSFDEP.CODFILIALORIGEM
            INTO V_CODFILIALDESTINO
            FROM PCTRANSFDEP
           WHERE NVL(PCTRANSFDEP.NUMTRANSTRANSFSAIDA, NUMTRANSVENDA) =
                 P_TRANSACAO
             AND ROWNUM = 1;

        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            SELECT PCFILIAL.CODIGO
              INTO V_CODFILIALDESTINO
              FROM PCFILIAL, PCPEDC
             WHERE PCPEDC.NUMTRANSVENDA = P_TRANSACAO
               AND PCPEDC.CODCLI = PCFILIAL.CODCLI
               AND ROWNUM = 1;

          WHEN OTHERS THEN
            V_CODFILIALDESTINO := '';
        END;

      END IF;
      
      if (SERIE_POR_PRODUTO = 'S') then
         TIPONUMERADOR := 'O';
      end if;  
      

      OBTERPROXIMONUMERONFE(ROTA_PRINCIPAL -- Rota principal
                           ,
                            P_CODIGOFILIAL --Código da Filial
                           ,
                            P_MOVIMENTO --S - Saída(PCNFSAID)| E - Entrada(PCNFENT
                           ,
                            P_SEFAZORIGEM -- S - SERAZ DE ORIGEM | N - SCAN
                           ,
                            TIPONUMERADOR -- Tipo de numeração de nota
                           ,
                            V_CODFILIALDESTINO -- in varchar2 default '' - usado no processo de venda para deposito fechado (TIPONUMERADOR=D)
                           ,
                           V_CODGRUPO_SEQ_PROD -- in number default null --usado no processo de sequencia por produto
                           ,
                            P_NUMERO -- Parâmetro de Saída(número da nota)
                           ,
                            P_SERIE -- Parâmetro de Saída(Série da nota)
                           ,
                            P_RESULTADO -- Parâmetro de Saída(Resultado da Operação )
                           ,
                            P_MENSAGEM); -- Parâmetro de Saída(Mensagem, em caso de erro)

      if P_RESULTADO > 0 then
        raise SAIR_COM_ERRO;
      end if;
    else
      if P_SEFAZORIGEM = 'S' then
        -- Se Sefaz origem e serie SCAN, então deve inutilizar para gerar outra numeração
        if SERIE_ATUAL > 899 then
          begin
            insert into PCINUTILIZARNFE
              (SERIE, NUMNOTA, TIPOMOV, NUMTRANSACAO, DTLANC)
            values
              (SERIE_ATUAL, NUMNOTA_ATUAL, 'S', P_TRANSACAO, sysdate);
          exception
            when others then
              P_RESULTADO := 52;
              P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                             ' - Erro ao inserir registro na tabela "PCINUTILIZARNFE" ' ||
                             sqlcode || ' - ' || sqlerrm;
              rollback;
              return;
          end;
          if P_RESULTADO = 0 then
            JA_UTILIZOUNUMNFE := 'N';
            OBTERPROXIMONUMERONFE(ROTA_PRINCIPAL -- Rota principal
                                 ,
                                  P_CODIGOFILIAL --Código da Filial
                                 ,
                                  P_MOVIMENTO --S - Saída(PCNFSAID)| E - Entrada(PCNFENT
                                 ,
                                  P_SEFAZORIGEM -- S - SERAZ DE ORIGEM | N - SCAN
                                 ,
                                  TIPONUMERADOR -- Contador Padrão
                                 ,
                                  V_CODFILIALDESTINO -- in varchar2 default '' - usado no processo de venda para deposito fechado (TIPONUMERADOR=D)
                                 ,
                                 V_CODGRUPO_SEQ_PROD -- in number default null --usado no processo de sequencia por produto
                                 ,
                                  P_NUMERO -- Parâmetro de Saída(número da nota)
                                 ,
                                  P_SERIE -- Parâmetro de Saída(Série da nota)
                                 ,
                                  P_RESULTADO -- Parâmetro de Saída(Resultado da Operação )
                                 ,
                                  P_MENSAGEM); -- Parâmetro de Saída(Mensagem, em caso de erro)
            if P_RESULTADO > 0 then
              raise SAIR_COM_ERRO;
            end if;

          end if;
        end if;
      else
        -- Se Não for Sefaz origem e serie normal, então deve inutilizar para gerar outra numeração
        if SERIE_ATUAL < 900 then
          begin
            insert into PCINUTILIZARNFE
              (SERIE, NUMNOTA, TIPOMOV, NUMTRANSACAO, DTLANC)
            values
              (SERIE_ATUAL, NUMNOTA_ATUAL, 'S', P_TRANSACAO, sysdate);
          exception
            when others then
              P_RESULTADO := 53;
              P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                             ' - Erro ao inserir registro na tabela "PCINUTILIZARNFE" ' ||
                             sqlcode || ' - ' || sqlerrm;
              rollback;
              return;
          end;
          JA_UTILIZOUNUMNFE := 'N';
          OBTERPROXIMONUMERONFE(ROTA_PRINCIPAL -- Rota principal
                               ,
                                P_CODIGOFILIAL --Código da Filial
                               ,
                                P_MOVIMENTO --S - Saída(PCNFSAID)| E - Entrada(PCNFENT
                               ,
                                P_SEFAZORIGEM -- S - SERAZ DE ORIGEM | N - SCAN
                               ,
                                TIPONUMERADOR -- Contador Padrão
                               ,
                                V_CODFILIALDESTINO -- in varchar2 default '' - usado no processo de venda para deposito fechado (TIPONUMERADOR=D)
                               ,
                               V_CODGRUPO_SEQ_PROD -- in number default null --usado no processo de sequencia por produto
                               ,
                                P_NUMERO -- Parâmetro de Saída(número da nota)
                               ,
                                P_SERIE -- Parâmetro de Saída(Série da nota)
                               ,
                                P_RESULTADO -- Parâmetro de Saída(Resultado da Operação )
                               ,
                                P_MENSAGEM); -- Parâmetro de Saída(Mensagem, em caso de erro)
          if P_RESULTADO > 0 then
            raise SAIR_COM_ERRO;
          end if;

        end if;
      end if;
    end if;

    if JA_UTILIZOUNUMNFE = 'S' then
      raise VOLTAR_COM_NUMERACAO_ATUAL;
    end if;

    /*
          Atualizar as tabelas que tem ligação com a numero de nota de Saída
    */

    begin
      -- 1. Atualizar PCNFSAID da nota fiscal de saida normal.
      V_CONT_NOTA_SAIDA := 0;
      for NOTA_SAIDA IN (select rowid ID_REGISTRO, 'N' PREFATURAMENTO
                           from PCNFSAID
                          where NUMTRANSVENDA = P_TRANSACAO
                         UNION ALL
                         select rowid ID_REGISTRO, 'S' PREFATURAMENTO
                           from PCNFSAIDPREFAT
                          where NUMTRANSVENDA = P_TRANSACAO
                            AND PCNFSAIDPREFAT.DATACONSOLIDACAOPREFAT IS NULL) loop
        V_CONT_NOTA_SAIDA := V_CONT_NOTA_SAIDA + 1;

        if (NOTA_SAIDA.PREFATURAMENTO = 'N') then
          update PCNFSAID
             set PCNFSAID.NUMNOTA        = P_NUMERO,
                 PCNFSAID.SERIE          = P_SERIE,
                 PCNFSAID.CONSUMIUNUMNFE = 'S'
           where PCNFSAID.rowid = NOTA_SAIDA.ID_REGISTRO;
        end if;

        if (NOTA_SAIDA.PREFATURAMENTO = 'S') then
          update PCNFSAIDPREFAT
             set PCNFSAIDPREFAT.NUMNOTA        = P_NUMERO,
                 PCNFSAIDPREFAT.SERIE          = P_SERIE,
                 PCNFSAIDPREFAT.CONSUMIUNUMNFE = 'S'
           where PCNFSAIDPREFAT.rowid = NOTA_SAIDA.ID_REGISTRO;
        end if;

      end loop;

      if (V_CONT_NOTA_SAIDA <= 0) then
        P_RESULTADO := 100;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCNFSAID". Não encontrado. ' ||
                       sqlcode || ' - ' || sqlerrm;
        raise SAIR_COM_ERRO;
      end if;

    exception
      when others then
        P_RESULTADO := 100;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCNFSAID". ' ||
                       sqlcode || ' - ' || sqlerrm;
        raise SAIR_COM_ERRO;
    end;

    /*
      2. Atualizar PCNFENT - TRANSFERENCIA 1124.
    */

      begin
        if NUMTRANSACAOORIG > 0 then
          ID_REGISTRO_ATUAL := null;
          EXISTE_REGISTRO   := FALSE;

          /*
          3. Atualiza - PCMOV TRANSFERENCIA 1124 (ENTRADA)
          */
          begin
            for DADOS in (select rowid
                            into ID_REGISTRO_ATUAL
                            from PCMOV
                           where NUMTRANSENT = NUMTRANSACAOORIG
                             and CODOPER in ('ET', 'ED', 'EC')) loop
              update PCMOV
                 set PCMOV.NUMNOTA = P_NUMERO
               where PCMOV.rowid = DADOS.rowid;

              EXISTE_REGISTRO := TRUE;
            end loop;

          exception
            when others then
              P_RESULTADO := 102;
              P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                             ' - Erro ao atualizar a tabela "PCMOV - TRANSF.1124". ' ||
                             sqlcode || ' - ' || sqlerrm;
              raise SAIR_COM_ERRO;
          end;

          /*
          4. Atualiza - PCMOVCIAP TRANSFERENCIA 3418 (ENTRADA)
          */
          IF TIPOVENDA_NF = 'TR' THEN
            begin
              for DADOS in (select rowid
                              into ID_REGISTRO_ATUAL
                              from PCMOVCIAP
                             where NUMTRANSENT = NUMTRANSACAOORIG) loop
                update PCMOVCIAP
                   set PCMOVCIAP.NUMNOTA = P_NUMERO
                 where PCMOVCIAP.rowid = DADOS.rowid;

                EXISTE_REGISTRO := TRUE;
              end loop;

            exception
              when others then
                P_RESULTADO := 222;
                P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                               ' - Erro ao atualizar a tabela "PCMOVCIAP - TRANSF.3418". ' ||
                               sqlcode || ' - ' || sqlerrm;
                raise SAIR_COM_ERRO;
            end;
          END IF;

          IF EXISTE_REGISTRO THEN
            select rowid
              into ID_REGISTRO_ATUAL
              from PCNFENT
             where NUMTRANSENT = NUMTRANSACAOORIG
               and ESPECIE IN ('NF', 'NE', 'TP')
               and rownum = 1;

            update PCNFENT
               set PCNFENT.NUMNOTA = P_NUMERO, PCNFENT.SERIE = P_SERIE
             where PCNFENT.rowid = ID_REGISTRO_ATUAL;

            /*
            3. Atualiza - PCLANC TRANSFERENCIA 1124 (ENTRADA)
            */
            begin
              for DADOS in (select rowid
                              into ID_REGISTRO_ATUAL
                              from PCLANC
                             where NUMTRANSENT = NUMTRANSACAOORIG) loop
                update PCLANC
                   set PCLANC.NUMNOTA    = P_NUMERO,
                       PCLANC.NUMNOTADEV = DECODE(PCLANC.NUMNOTADEV,
                                                  NULL,
                                                  NULL,
                                                  P_NUMERO)
                 where PCLANC.rowid = DADOS.rowid;
              end loop;

            exception
              when others then
                P_RESULTADO := 1020;
                P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                               ' - Erro ao atualizar a tabela "PCLANC - TRANSF.1124". ' ||
                               sqlcode || ' - ' || sqlerrm;
                raise SAIR_COM_ERRO;
            end;

            --transferência CFAT
            begin
              for DADOS in (select rowid ID_REGISTRO, 'N' PREFATURAMENTO
                              from PCLANC
                             where PCLANC.NUMTRANSVENDA = P_TRANSACAO
                            UNION ALL
                            select rowid ID_REGISTRO, 'S' PREFATURAMENTO
                              from PCLANCPREFAT
                             where PCLANCPREFAT.NUMTRANSVENDA = P_TRANSACAO) loop

                if (DADOS.PREFATURAMENTO = 'N') then
                  update PCLANC
                     set PCLANC.NUMNOTA = P_NUMERO
                   where PCLANC.rowid = DADOS.ID_REGISTRO;
                end if;

                if (DADOS.PREFATURAMENTO = 'S') then
                  update PCLANCPREFAT
                     set PCLANCPREFAT.NUMNOTA = P_NUMERO
                   where PCLANCPREFAT.rowid = DADOS.ID_REGISTRO;
                end if;

              end loop;

            exception
              when others then
                P_RESULTADO := 221;
                P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                               ' - Erro ao atualizar a tabela "PCLANC"(Processo CFAT). ' ||
                               sqlcode || ' - ' || sqlerrm;
                raise SAIR_COM_ERRO;
            end;
            -----
          end if;

          begin
            for DADOS in (select rowid
                            into ID_REGISTRO_ATUAL
                            from PCWMS
                           where NUMTRANSVENDA = P_TRANSACAO) loop
              update PCWMS
                 set PCWMS.NUMNOTA = P_NUMERO
               where PCWMS.rowid = DADOS.rowid;
            end loop;

          exception
            when others then
              P_RESULTADO := 115;
              P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                             ' - Erro ao atualizar a tabela "PCWMS". ' ||
                             sqlcode || ' - ' || sqlerrm;
              raise SAIR_COM_ERRO;
          end;

        end if;
      exception
        when NO_DATA_FOUND then
          null;
        when others then
          P_RESULTADO := 101;
          P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                         ' - Erro ao atualizar a tabela "PCNFENT - TRANSF.1124". ' ||
                         sqlcode || ' - ' || sqlerrm;

          raise SAIR_COM_ERRO;
      end;

    /*
    4. Atualiza - PCMOV Saida
    */
    begin

      V_CONT_NOTA_SAIDA := 0;
      for DADOS in (select rowid ID_REGISTRO, 'N' PREFATURAMENTO
                      from PCMOV
                     where PCMOV.NUMTRANSVENDA = P_TRANSACAO
                    UNION ALL
                    select rowid ID_REGISTRO, 'S' PREFATURAMENTO
                      from PCMOVPREFAT
                     where PCMOVPREFAT.NUMTRANSVENDA = P_TRANSACAO
                       and PCMOVPREFAT.DATACONSOLIDACAOPREFAT IS NULL) loop
        V_CONT_NOTA_SAIDA := V_CONT_NOTA_SAIDA + 1;

        if (DADOS.PREFATURAMENTO = 'N') then
          update PCMOV
             set PCMOV.NUMNOTA = P_NUMERO
           where PCMOV.rowid = DADOS.ID_REGISTRO;
        end if;

        if (DADOS.PREFATURAMENTO = 'S') then
          update PCMOVPREFAT
             set PCMOVPREFAT.NUMNOTA = P_NUMERO
           where PCMOVPREFAT.rowid = DADOS.ID_REGISTRO;
        end if;
      end loop;

    exception
      when others then
        P_RESULTADO := 103;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCMOV - SAIDA". ' ||
                       sqlcode || ' - ' || sqlerrm;
        raise SAIR_COM_ERRO;
    end;

    /*
    5. Atualiza - PCPREST Saida
    */
    begin

      V_CONT_NOTA_SAIDA := 0;
      for DADOS in (select rowid ID_REGISTRO, 'N' PREFATURAMENTO
                      from PCPREST
                     where ((NUMTRANSVENDA = P_TRANSACAO) or
                           (NUMTRANSVENDAST = P_TRANSACAO))
                    UNION ALL
                    select rowid ID_REGISTRO, 'S' PREFATURAMENTO
                      from PCPRESTPREFAT
                     where ((NUMTRANSVENDA = P_TRANSACAO) or
                           (NUMTRANSVENDAST = P_TRANSACAO))
                       and DATACONSOLIDACAOPREFAT IS NULL) loop

        V_CONT_NOTA_SAIDA := V_CONT_NOTA_SAIDA + 1;
        if (DADOS.PREFATURAMENTO = 'N') then
          update PCPREST
             set PCPREST.DUPLIC = P_NUMERO
           where PCPREST.rowid = DADOS.ID_REGISTRO;
        end if;

        if (DADOS.PREFATURAMENTO = 'S') then
          update PCPRESTPREFAT
             set PCPRESTPREFAT.DUPLIC = P_NUMERO
           where PCPRESTPREFAT.rowid = DADOS.ID_REGISTRO;
        end if;
      end loop;

    exception
      when others then
        P_RESULTADO := 104;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCPREST". ' ||
                       sqlcode || ' - ' || sqlerrm;
        raise SAIR_COM_ERRO;
    end;

    /*
    6. Atualiza - PCVERBA Saida
    */
    begin
      for DADOS in (SELECT rowid, NUMVERBA
                      FROM PCVERBA
                     WHERE NUMTRANSENTDEVFORNEC = P_TRANSACAO) loop
        update PCVERBA
           set PCVERBA.NUMNOTA = P_NUMERO
         where PCVERBA.rowid = DADOS.rowid;

        for PCVERBA_OBS in (SELECT rowid
                              FROM PCAPLICVERBA
                             WHERE NUMVERBA = DADOS.NUMVERBA) loop
          update PCAPLICVERBA
             set PCAPLICVERBA.OBS1 = 'DEVOLUCAO DE MERCADORIA, NF.: ' ||
                                     P_NUMERO
           where PCAPLICVERBA.rowid = PCVERBA_OBS.rowid;
        end loop;
      end loop;

    exception
      when others then
        P_RESULTADO := 104;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCVERBA". ' ||
                       sqlcode || ' - ' || sqlerrm;
        raise SAIR_COM_ERRO;
    end;

    begin

      ID_REGISTRO_ATUAL := null;
      for DADOS in (select rowid
                      into ID_REGISTRO_ATUAL
                      from PCCRECLI
                     where NUMTRANSVENDA = P_TRANSACAO) loop
        EXISTE_REGISTRO := true;
      end loop;

      if EXISTE_REGISTRO = true then
        update PCCRECLI
           set PCCRECLI.NUMNOTA = P_NUMERO, PCCRECLI.SERIE = P_SERIE
         where PCCRECLI.NUMTRANSVENDA = P_TRANSACAO;
      end if;

      EXISTE_REGISTRO := false;

    exception
      when others then
        P_RESULTADO := 105;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCCRECLI". ' ||
                       sqlcode || ' - ' || sqlerrm;
        raise SAIR_COM_ERRO;
    end;

    begin
      ID_REGISTRO_ATUAL := null;
      for DADOS in (select rowid
                      into ID_REGISTRO_ATUAL
                      from PCCRECLI
                     where NUMTRANSVENDADESC = P_TRANSACAO)

       loop
        EXISTE_REGISTRO := true;
      end loop;

      if EXISTE_REGISTRO = true then
        update PCCRECLI
           set PCCRECLI.NUMNOTADESC = P_NUMERO
         where PCCRECLI.NUMTRANSVENDADESC = P_TRANSACAO;
      end if;

      EXISTE_REGISTRO := false;
    exception
      when others then
        P_RESULTADO := 106;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCCRECLI". ' ||
                       sqlcode || ' - ' || sqlerrm;
        raise SAIR_COM_ERRO;
    end;

    begin
      ID_REGISTRO_ATUAL := null;
      for DADOS in (select rowid
                      into ID_REGISTRO_ATUAL
                      from PCMOVAVARIA
                     where PCMOVAVARIA.NUMTRANSVENDA = P_TRANSACAO) loop
        EXISTE_REGISTRO := true;
      end loop;

      if EXISTE_REGISTRO = true then
        update PCMOVAVARIA
           set PCMOVAVARIA.NUMNOTA = P_NUMERO
         where PCMOVAVARIA.NUMTRANSVENDA = P_TRANSACAO;
      end if;

      EXISTE_REGISTRO := false;

    exception
      when others then
        P_RESULTADO := 107;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCMOVAVARIA". ' ||
                       sqlcode || ' - ' || sqlerrm;
        raise SAIR_COM_ERRO;
    end;

    if TIPO_VENDA = 20 then
      begin
        ID_REGISTRO_ATUAL := null;
        for DADOS in (select rowid
                        into ID_REGISTRO_ATUAL
                        from PCMOVESTCLI
                       where PCMOVESTCLI.NUMTRANSVENDA = P_TRANSACAO) loop
          EXISTE_REGISTRO := true;
        end loop;

        if EXISTE_REGISTRO = true then
          update PCMOVESTCLI
             set PCMOVESTCLI.NUMNOTA = P_NUMERO
           where PCMOVESTCLI.NUMTRANSVENDA = P_TRANSACAO;
        end if;

        EXISTE_REGISTRO := false;

      exception
        when others then
          P_RESULTADO := 108;
          P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                         ' - Erro ao atualizar a tabela "PCMOVESTCLI". ' ||
                         sqlcode || ' - ' || sqlerrm;
          raise SAIR_COM_ERRO;
      end;
    end if;

    /*
    Atualiza - PCLANC Saida
    */
    begin
      for DADOS in (select rowid ID_REGISTRO, 'N' PREFATURAMENTO
                      from PCLANC
                     where PCLANC.NUMTRANSVENDA = P_TRANSACAO
                    UNION ALL
                    select rowid ID_REGISTRO, 'S' PREFATURAMENTO
                      from PCLANCPREFAT
                     where PCLANCPREFAT.NUMTRANSVENDA = P_TRANSACAO) loop
        if (DADOS.PREFATURAMENTO = 'N') then
          update PCLANC
             set PCLANC.NUMNOTA    = P_NUMERO,
                 PCLANC.NUMNOTADEV = DECODE(PCLANC.NUMNOTADEV,
                                            NULL,
                                            NULL,
                                            P_NUMERO)
           where PCLANC.rowid = DADOS.ID_REGISTRO;
        end if;

        if (DADOS.PREFATURAMENTO = 'S') then
          update PCLANCPREFAT
             set PCLANCPREFAT.NUMNOTA    = P_NUMERO,
                 PCLANCPREFAT.NUMNOTADEV = DECODE(PCLANCPREFAT.NUMNOTADEV,
                                                  NULL,
                                                  NULL,
                                                  P_NUMERO)
           where PCLANCPREFAT.rowid = DADOS.ID_REGISTRO;
        end if;

      end loop;

      EXISTE_REGISTRO := false;

    exception
      when others then
        P_RESULTADO := 109;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCLANC". ' ||
                       sqlcode || ' - ' || sqlerrm;
        raise SAIR_COM_ERRO;
    end;

    begin

      ID_REGISTRO_ATUAL := null;
      select rowid
        into ID_REGISTRO_ATUAL
        from PCORCAVENDAC
       where NUMTRANSVENDA = P_TRANSACAO;

      update PCORCAVENDAC
         set PCORCAVENDAC.NUMNOTA       = P_NUMERO,
             PCORCAVENDAC.NUMNOTATRANSF = P_NUMERO
       where PCORCAVENDAC.rowid = ID_REGISTRO_ATUAL;
    exception
      when NO_DATA_FOUND then
        null;
      when others then
        P_RESULTADO := 110;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCORCAVENDAC". ' ||
                       sqlcode || ' - ' || sqlerrm;
        raise SAIR_COM_ERRO;
    end;
    
    select count(*)
      into V_QTD_REGISTROS_TEMP
      from PCPEDC
     where NUMTRANSVENDA = P_TRANSACAO;
           
    if (V_QTD_REGISTROS_TEMP > 1) then
      P_RESULTADO := 111;
      P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                     ' - Erro ao atualizar a tabela "PCPEDC". Existe mais de um pedido com o mesmo NUMTRANSVENDA (' || P_TRANSACAO || ').';
      raise SAIR_COM_ERRO; 
    end if;
     
    begin  
      ID_REGISTRO_ATUAL := null;
      select rowid
        into ID_REGISTRO_ATUAL
        from PCPEDC
       where NUMTRANSVENDA = P_TRANSACAO;

      update PCPEDC
         set PCPEDC.NUMNOTA = P_NUMERO
       where PCPEDC.rowid = ID_REGISTRO_ATUAL;

    exception
      when NO_DATA_FOUND then
        null;
      when others then
        P_RESULTADO := 111;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCPEDC". ' ||
                       sqlcode || ' - ' || sqlerrm;
        raise SAIR_COM_ERRO;
    end;

    begin
      for DADOS in (select rowid
                      from PCCONTROLENUMSERIE
                     where NUMTRANSVENDA = P_TRANSACAO) loop
        update PCCONTROLENUMSERIE
           set PCCONTROLENUMSERIE.NUMNOTA = P_NUMERO
         where PCCONTROLENUMSERIE.rowid = dados.rowid;
      end loop;

    exception
      when NO_DATA_FOUND then
        null;
      when others then
        P_RESULTADO := 111;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCCONTROLENUMSERIE". ' ||
                       sqlcode || ' - ' || sqlerrm;
        raise SAIR_COM_ERRO;
    end;

    /*********** Alterado conforme Sr. Ricardo Solicitacao tarefa: 153023 ***********/
    begin

      for DADOS in (select PCLANC.rowid
                      from PCDEVFORNEC, PCLANC
                     where PCDEVFORNEC.NUMTRANSENT = PCLANC.NUMTRANSENT
                       and PCDEVFORNEC.NUMNOTADEV = PCLANC.NUMNOTADEV
                       and PCDEVFORNEC.NUMTRANSVENDA = P_TRANSACAO) loop
        update PCLANC
           set PCLANC.NUMNOTADEV = DECODE(PCLANC.NUMNOTADEV,
                                          NULL,
                                          NULL,
                                          P_NUMERO)
         where PCLANC.rowid = DADOS.rowid;
      end loop;

      update PCDEVFORNEC
         set PCDEVFORNEC.NUMNOTADEV = P_NUMERO
       where PCDEVFORNEC.NUMTRANSVENDA = P_TRANSACAO;

      update PCMOV
         set PCMOV.NUMNOTADEV = P_NUMERO
       where PCMOV.NUMTRANSVENDA = P_TRANSACAO
         and NVL(PCMOV.NUMNOTADEV, 0) > 0;

    exception
      when others then
        P_RESULTADO := 112;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCDEVFORNEC e PCLANC". ' ||
                       sqlcode || ' - ' || sqlerrm;
        raise SAIR_COM_ERRO;
    end;

    /*******************************************/

    begin
      if ORIGEM_PED = 'B' then
        ID_REGISTRO_ATUAL := null;
        for DADOS in (select rowid
                        into ID_REGISTRO_ATUAL
                        from PCWMS
                       where NUMTRANSVENDA = P_TRANSACAO) loop
          EXISTE_REGISTRO := true;
        end loop;

        if EXISTE_REGISTRO = true then
          update PCWMS
             set PCWMS.NUMNOTA = P_NUMERO
           where PCWMS.NUMTRANSVENDA = P_TRANSACAO;
        end if;

        EXISTE_REGISTRO := false;
      end if;
    exception
      when others then
        P_RESULTADO := 115;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCWMS". ' || sqlcode ||
                       ' - ' || sqlerrm;
        raise SAIR_COM_ERRO;
    end;

    begin
      ID_REGISTRO_ATUAL := null;
      for DADOS in (select rowid
                      into ID_REGISTRO_ATUAL
                      from PCMOVCIAP
                     where NUMTRANSVENDA = P_TRANSACAO)

       loop
        EXISTE_REGISTRO := true;
      end loop;

      if EXISTE_REGISTRO = true then
        update PCMOVCIAP
           set PCMOVCIAP.NUMNOTA = P_NUMERO
         where PCMOVCIAP.NUMTRANSVENDA = P_TRANSACAO;
      end if;

      EXISTE_REGISTRO := false;
    exception
      when NO_DATA_FOUND then
        null;
      when others then
        P_RESULTADO := 206;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCMOVCIAP". ' ||
                       sqlcode || ' - ' || sqlerrm;
        rollback;
        EXISTE_REGISTRO := false;
        return;
    end;

    begin
      ID_REGISTRO_ATUAL := null;
      for DADOS in (select rowid
                      into ID_REGISTRO_ATUAL
                      from PCBENSPATRIMONIAIS
                     where NUMTRANSVENDA = P_TRANSACAO)

       loop
        EXISTE_REGISTRO := true;
      end loop;

      if EXISTE_REGISTRO = true then
        update PCBENSPATRIMONIAIS
           set PCBENSPATRIMONIAIS.NUMNOTA = P_NUMERO
         where PCBENSPATRIMONIAIS.NUMTRANSVENDA = P_TRANSACAO;
      end if;

      EXISTE_REGISTRO := false;
    exception
      when NO_DATA_FOUND then
        null;
      when others then
        P_RESULTADO := 207;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCBENSPATRIMONIAIS". ' ||
                       sqlcode || ' - ' || sqlerrm;
        rollback;
        EXISTE_REGISTRO := false;
        return;
    end;

    IF TIPOVENDA_NF = 'TR' THEN
      --entrada de transferência de ciap
      begin
        ID_REGISTRO_ATUAL := null;
        for DADOS in (select rowid
                        into ID_REGISTRO_ATUAL
                        from PCBENSPATRIMONIAIS
                       where NUMTRANSACAO = NUMTRANSACAOORIG)

         loop
          EXISTE_REGISTRO := true;
        end loop;

        if EXISTE_REGISTRO = true then
          update PCBENSPATRIMONIAIS
             set PCBENSPATRIMONIAIS.NUMNOTA = P_NUMERO
           where PCBENSPATRIMONIAIS.NUMTRANSACAO = NUMTRANSACAOORIG;
        end if;

        EXISTE_REGISTRO := false;
      exception
        when NO_DATA_FOUND then
          null;
        when others then
          P_RESULTADO := 207;
          P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                         ' - Erro ao atualizar a tabela "PCBENSPATRIMONIAIS entrada de transferência". ' ||
                         sqlcode || ' - ' || sqlerrm;
          rollback;
          EXISTE_REGISTRO := false;
          return;
      end;
    END IF;

    begin
      ID_REGISTRO_ATUAL := null;
      for DADOS in (select rowid
                      into ID_REGISTRO_ATUAL
                      from PCPEDIVOLUME
                     where NUMTRANSVENDA = P_TRANSACAO)

       loop
        EXISTE_REGISTRO := true;
      end loop;

      if EXISTE_REGISTRO = true then
        update PCPEDIVOLUME
           set PCPEDIVOLUME.NUMNOTA = P_NUMERO
         where PCPEDIVOLUME.NUMTRANSVENDA = P_TRANSACAO;
      end if;

      EXISTE_REGISTRO := false;
    exception
      when NO_DATA_FOUND then
        null;
      when others then
        P_RESULTADO := 207;
        P_MENSAGEM  := 'C?digo: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCPEDIVOLUME". ' ||
                       sqlcode || ' - ' || sqlerrm;
        rollback;
        EXISTE_REGISTRO := false;
        return;
    end;

    commit;

  else
    -- Movimento de Entrada

    if (P_TRANSACAO = 0) then
      P_RESULTADO := 220;
      P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                     ' - Transação da nota fiscal de Entrada inválida(transação com valor igual a zero).' ||
                     sqlcode || ' - ' || sqlerrm;
      raise SAIR_COM_ERRO;
    end if;

    begin
      select NVL(PCFILIAL.USANUMNFDEVCLI, ''),
             NVL(PCFILIAL.TIPONUMNFENTRADA, ''),
             NVL(PCFILIAL.CONTROLENFEPORSERIE, 'N'),
             NVL(PCFILIAL.UTILIZASEQNFENT, 'N')
        into USANUMNFDEVCLI,
             TIPONUMNFENTRADA,
             CONTROLE_NFE_POR_SERIE,
             UTILIZASEQNFENT
        from PCFILIAL
       where CODIGO = P_CODIGOFILIAL;

      select PCNFENT.TIPODESCARGA,
             PCNFENT.NUMNOTA,
             PCNFENT.SERIE,
             PCFILIAL.SERIENFESCAN,
             NVL(PCNFENT.CONSUMIUNUMNFE, 'N'),
             NVL(PCNFENT.TIPOEMISSAO, '1'),
             NVL(PCNFENT.GERANFVENDA, 'N') as GERANOTAVENDA,
             NUMTRANSVENDAORIG,
             NVL(PCFILIAL.CONTROLENFEPORSERIEDEPOFECHADO, 'N'),
             PCNFENT.FINALIDADENFE
        into TIPODESCARGA,
             NUMNOTA_ATUAL,
             SERIE_ATUAL,
             SERIE_ATUAL_SCAN,
             JA_UTILIZOUNUMNFE,
             TIPO_EMISSAO,
             GERANFVENDA,
             NUMTRANSACAOORIG,
             CONTROLE_NFE_DEP_FECHADO,
             FINALIDADENFE
        from PCNFENT, PCFILIAL
       where NVL(PCNFENT.CODFILIALNF, PCNFENT.CODFILIAL) = PCFILIAL.CODIGO
         and PCNFENT.NUMTRANSENT = P_TRANSACAO
         and PCNFENT.ESPECIE in ('NE', 'NF')
         and (GERANFVENDA = 'S' or GERANFDEVCLI = 'S')
         and ROWNUM = 1;

    exception
      when NO_DATA_FOUND then
        P_RESULTADO := 54;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Não foi encontrado registro na tabela PCNFENT com este número de transação. ' ||
                       sqlcode || ' - ' || sqlerrm;
      when others then
        P_RESULTADO := 55;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao buscar os dados na tabela PCNFENT. ' ||
                       sqlcode || ' - ' || sqlerrm;
    end;

    begin

      --Manifesto
      TIPO_VENDA := 0;
      select NVL(PCNFSAID.CONDVENDA, 0)
        into TIPO_VENDA
        from PCNFENT, PCESTCOM, PCFILIAL, PCNFSAID
       where PCESTCOM.NUMTRANSENT = PCNFENT.NUMTRANSENT
         and PCNFENT.CODFILIALNF = PCFILIAL.CODIGO
         and PCNFSAID.NUMTRANSVENDA = PCESTCOM.NUMTRANSVENDA
         and PCESTCOM.VLDEVOLUCAO = 0
         and PCESTCOM.VLESTORNO = 0
         and PCESTCOM.CODUSUR = 0
         and PCESTCOM.VLESTORNOCMV = 0
         and PCNFSAID.CONDVENDA = 13
         and PCNFENT.ESPECIE in ('NE', 'NF')
         and (PCNFENT.GERANFVENDA = 'S' or PCNFENT.GERANFDEVCLI = 'S')
         and PCNFENT.NUMTRANSENT = P_TRANSACAO;

    exception
      when NO_DATA_FOUND then
        TIPO_VENDA := 0;
      when others then
        P_RESULTADO := 56;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao buscar os dados na tabela PCNFENT. ' ||
                       sqlcode || ' - ' || sqlerrm;
    end;

    --------------------------------------serie especifica por produto----------------------------------------------
    begin
      FOR PRODS IN (SELECT 'S' AS SERIE_POR_PRODUTO, PCFILIALSEQNFEPORPRODUTO.CODGRUPO
                      FROM PCMOV, 
                           PCPRODFILIAL, 
                           PCFILIALSEQNFEPORPRODUTO
                     WHERE 1 = 1
                       AND PCMOV.CODFILIAL = PCPRODFILIAL.CODFILIAL
                       AND PCMOV.CODPROD = PCPRODFILIAL.CODPROD      
                       AND PCPRODFILIAL.CODFILIAL = PCFILIALSEQNFEPORPRODUTO.CODFILIAL
                       AND PCPRODFILIAL.CODGRUPOSEQNFE = PCFILIALSEQNFEPORPRODUTO.CODGRUPO      
                       AND PCMOV.NUMTRANSENT = P_TRANSACAO) LOOP
                       
           SERIE_POR_PRODUTO := PRODS.SERIE_POR_PRODUTO;
           V_CODGRUPO_SEQ_PROD := PRODS.CODGRUPO ;
         
         END LOOP;
    exception
      when others then
        SERIE_POR_PRODUTO := 'N'; 
    end;
    --------------------------------------serie especifica por produto---------------------------------------------- 

    ---Melhoria para passar a consumir uma serie e numeração difernetes para nota devolução de transferencia de deposito fechado---
    ---HIS.02186.2016 - Eddy Pereira
    if ((CONTROLE_NFE_DEP_FECHADO = 'S') AND
       (TIPODESCARGA IN ('6', '7', '8', 'T'))) then
      begin
        --Buscar dados da pcmov para identificar se nota é de transferencia para deposito fechado
        --PRIMEIRA VALIDAÇÃO
        BEGIN
          FOR A IN (SELECT DISTINCT PCMOV.CODFISCAL
                      FROM PCMOV
                     WHERE PCMOV.NUMTRANSENT = P_TRANSACAO
                       AND ROWNUM = 1) LOOP
            IF A.CODFISCAL IN ('1905',
                               '1906',
                               '1907',
                               '1934',
                               '2905',
                               '2906',
                               '2907',
                               '2934',
                               '5905',
                               '5906',
                               '5907',
                               '5934',
                               '6905',
                               '6906',
                               '6907',
                               '6934') THEN
              GERAR_NUM_SERIE_DEP_FECHADO := 'S';
            ELSE
              GERAR_NUM_SERIE_DEP_FECHADO := 'N';
            END IF;
          END LOOP;
        EXCEPTION
          WHEN OTHERS THEN
            GERAR_NUM_SERIE_DEP_FECHADO := 'N';
        END;

        --SEGUNDA VALIDAÇÃO
        --CASO A VALIDAÇÃO ACIMA NÃO RETORNE VERDADEIRO, FAZER A FALIDAÇÃO ABAIXO
        IF GERAR_NUM_SERIE_DEP_FECHADO = 'N' THEN
          BEGIN
            begin
              --segundo o vendas, no processo de devolução de transferencia, deve ser validada a transação da nota de venda para saber se esta foi transaferencia
              SELECT PCESTCOM.NUMTRANSVENDA
                INTO V_NUMTRANSACAO_VENDA_TRASF
                FROM PCESTCOM
               WHERE PCESTCOM.NUMTRANSENT = P_TRANSACAO;
            exception
              when NO_DATA_FOUND then
                V_NUMTRANSACAO_VENDA_TRASF := 0;
              when others then
                V_NUMTRANSACAO_VENDA_TRASF := 0;
            end;

            FOR B IN (SELECT DISTINCT NVL(PCNFSAID.CODFILIAL,
                                          PCNFSAID.CODFILIALNF) AS CODFILIAL,
                                      NVL(PCNFSAID.CODFILIALNF,
                                          PCNFSAID.CODFILIAL) AS CODFILIALNF,
                                      PCMOV.CODFILIALRETIRA
                        FROM PCMOV, PCNFSAID
                       WHERE PCMOV.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA
                         AND PCNFSAID.NUMTRANSVENDA =
                             V_NUMTRANSACAO_VENDA_TRASF
                         AND ROWNUM = 1) LOOP
              IF (VENDAS.TIPO_TRANSFERENCIA(B.CODFILIAL,
                                            B.CODFILIALRETIRA,
                                            B.CODFILIALNF) IN ('R', 'VR')) THEN
                GERAR_NUM_SERIE_DEP_FECHADO := 'S';
              ELSE
                GERAR_NUM_SERIE_DEP_FECHADO := 'N';
              END IF;
            END LOOP;
          EXCEPTION
            WHEN OTHERS THEN
              GERAR_NUM_SERIE_DEP_FECHADO := 'N';
          END;
        END IF;
      exception
        when others then
          GERAR_NUM_SERIE_DEP_FECHADO := 'N';
      end;

    end if;

    ----

    if (P_RESULTADO = 0) then
      if CONTROLE_NFE_POR_SERIE = 'N' then
        if P_SEFAZORIGEM = 'N' then
          SERIE_ATUAL := SERIE_ATUAL_SCAN;
        end if;
        P_NUMERO    := NUMNOTA_ATUAL;
        P_SERIE     := SERIE_ATUAL;
        P_RESULTADO := 0;
        P_MENSAGEM  := '';
        rollback;
        return;
      end if;

      if (JA_UTILIZOUNUMNFE = 'N') then
        if TIPODESCARGA in ('6', '7', '8', 'T') then
          -- Devolução de cliente

          IF ((CONTROLE_NFE_DEP_FECHADO = 'S') AND
             (GERAR_NUM_SERIE_DEP_FECHADO = 'S')) THEN
            TIPONUMERADOR := 'D';

            BEGIN
              SELECT PCTRANSFDEP.CODFILIALORIGEM
                INTO V_CODFILIALDESTINO
                FROM PCTRANSFDEP
               WHERE PCTRANSFDEP.NUMTRANSVENDA = V_NUMTRANSACAO_VENDA_TRASF
                 AND ROWNUM = 1;
            EXCEPTION
              WHEN OTHERS THEN
                V_CODFILIALDESTINO := '';
            END;

          END IF;

          if TIPO_VENDA = 14 then
            TIPONUMERADOR := 'M';
            if CONTROLE_NFE_POR_ROTA = 'S' then
              TIPONUMERADOR := 'R';
            end if;
          end if;

          if USANUMNFDEVCLI = 'S' or TIPONUMNFENTRADA = 2 then
            TIPONUMERADOR := 'E';
          end if;
          
          if (SERIE_POR_PRODUTO = 'S') then
            TIPONUMERADOR := 'O';
          end if;  

          -- Utilizar contador específico para operações de entradas
          OBTERPROXIMONUMERONFE(0 -- Rota principal
                               ,
                                P_CODIGOFILIAL --Código da Filial
                               ,
                                P_MOVIMENTO --S - Saída(PCNFSAID)| E - Entrada(PCNFENT
                               ,
                                P_SEFAZORIGEM -- S - SERAZ DE ORIGEM | N - SCAN
                               ,
                                TIPONUMERADOR -- Contador Padrão
                               ,
                                V_CODFILIALDESTINO -- in varchar2 default '' - usado no processo de venda para deposito fechado (TIPONUMERADOR=D)
                               ,
                               V_CODGRUPO_SEQ_PROD -- in number default null --usado no processo de sequencia por produto
                               ,
                                P_NUMERO -- Parâmetro de Saída(número da nota)
                               ,
                                P_SERIE -- Parâmetro de Saída(Série da nota)
                               ,
                                P_RESULTADO -- Parâmetro de Saída(Resultado da Operação )
                               ,
                                P_MENSAGEM); -- Parâmetro de Saída(Mensagem, em caso de erro)
          --            END IF;
        else
          if (TIPODESCARGA not in ('N', 'F', 'P', 'R')) then

            if UTILIZASEQNFENT = 'S' then
              TIPONUMERADOR := 'E';
              if TIPO_VENDA = 14 then
                TIPONUMERADOR := 'M';
                if CONTROLE_NFE_POR_ROTA = 'S' then
                  TIPONUMERADOR := 'R';
                end if;
              end if;

              --pega sequencia específica para notas de ajuste
              if ((FINALIDADENFE = 'A') and
                 (NVL(PARAMFILIAL.ObterComoVarchar2('USANUMNOTASERIEAJUSTE',
                                                     P_CODIGOFILIAL),
                       'N') = 'S')) then
                TIPONUMERADOR := 'A';
              end if;

              if (SERIE_POR_PRODUTO = 'S') then
                TIPONUMERADOR := 'O';
              end if;

              OBTERPROXIMONUMERONFE(0 -- Rota principal
                                   ,
                                    P_CODIGOFILIAL --Código da Filial
                                   ,
                                    P_MOVIMENTO --S - Saída(PCNFSAID)| E - Entrada(PCNFENT
                                   ,
                                    P_SEFAZORIGEM -- S - SERAZ DE ORIGEM | N - SCAN
                                   ,
                                    TIPONUMERADOR -- Contador Padrão
                                   ,
                                    V_CODFILIALDESTINO -- in varchar2 default '' - usado no processo de venda para deposito fechado (TIPONUMERADOR=D)
                                   ,
                                   V_CODGRUPO_SEQ_PROD -- in number default null --usado no processo de sequencia por produto
                                   ,
                                    P_NUMERO -- Parâmetro de Saída(número da nota)
                                   ,
                                    P_SERIE -- Parâmetro de Saída(Série da nota)
                                   ,
                                    P_RESULTADO -- Parâmetro de Saída(Resultado da Operação )
                                   ,
                                    P_MENSAGEM); -- Parâmetro de Saída(Mensagem, em caso de erro)

            else

              TIPONUMERADOR := 'P';
              if TIPO_VENDA = 14 then
                TIPONUMERADOR := 'M';
                if CONTROLE_NFE_POR_ROTA = 'S' then
                  TIPONUMERADOR := 'R';
                end if;
              end if;
              
              --pega sequencia específica para notas de ajuste
              if ((FINALIDADENFE = 'A') and
                 (NVL(PARAMFILIAL.ObterComoVarchar2('USANUMNOTASERIEAJUSTE',
                                                     P_CODIGOFILIAL),
                       'N') = 'S')) then
                TIPONUMERADOR := 'A';
              end if;

              if (SERIE_POR_PRODUTO = 'S') then
                TIPONUMERADOR := 'O';
              end if;
              
              OBTERPROXIMONUMERONFE(0 -- Rota principal
                                   ,
                                    P_CODIGOFILIAL --Código da Filial
                                   ,
                                    P_MOVIMENTO --S - Saída(PCNFSAID)| E - Entrada(PCNFENT
                                   ,
                                    P_SEFAZORIGEM -- S - SERAZ DE ORIGEM | N - SCAN
                                   ,
                                    TIPONUMERADOR -- Contador Padrão
                                   ,
                                    V_CODFILIALDESTINO -- in varchar2 default '' - usado no processo de venda para deposito fechado (TIPONUMERADOR=D)
                                   ,
                                   V_CODGRUPO_SEQ_PROD -- in number default null --usado no processo de sequencia por produto
                                   ,
                                    P_NUMERO -- Parâmetro de Saída(número da nota)
                                   ,
                                    P_SERIE -- Parâmetro de Saída(Série da nota)
                                   ,
                                    P_RESULTADO -- Parâmetro de Saída(Resultado da Operação )
                                   ,
                                    P_MENSAGEM); -- Parâmetro de Saída(Mensagem, em caso de erro)

            end if;
          else
            if GERANFVENDA = 'S' then
              if ((TIPONUMNFENTRADA = 2) and
                 (TIPODESCARGA in ('N', 'F', 'P', 'I'))) then
                TIPONUMERADOR := 'I';


                OBTERPROXIMONUMERONFE(0 -- Rota principal
                                     ,
                                      P_CODIGOFILIAL --Código da Filial
                                     ,
                                      P_MOVIMENTO --S - Saída(PCNFSAID)| E - Entrada(PCNFENT | I - Importacao
                                     ,
                                      P_SEFAZORIGEM -- S - SERAZ DE ORIGEM | N - SCAN
                                     ,
                                      TIPONUMERADOR -- Contador Padrão
                                     ,
                                      V_CODFILIALDESTINO -- in varchar2 default '' - usado no processo de venda para deposito fechado (TIPONUMERADOR=D)
                                     ,
                                     V_CODGRUPO_SEQ_PROD -- in number default null --usado no processo de sequencia por produto
                                     ,
                                      P_NUMERO -- Parâmetro de Saída(número da nota)
                                     ,
                                      P_SERIE -- Parâmetro de Saída(Série da nota)
                                     ,
                                      P_RESULTADO -- Parâmetro de Saída(Resultado da Operação )
                                     ,
                                      P_MENSAGEM); -- Parâmetro de Saída(Mensagem, em caso de erro)

              elsif ((TIPONUMNFENTRADA = 2) and (TIPODESCARGA = 'R')) then
                --específico para notas tipodescarga = R
                TIPONUMERADOR := 'E';

                OBTERPROXIMONUMERONFE(0 -- Rota principal
                                     ,
                                      P_CODIGOFILIAL --Código da Filial
                                     ,
                                      P_MOVIMENTO --S - Saída(PCNFSAID)| E - Entrada(PCNFENT | I - Importacao
                                     ,
                                      P_SEFAZORIGEM -- S - SERAZ DE ORIGEM | N - SCAN
                                     ,
                                      TIPONUMERADOR -- Contador Padrão
                                     ,
                                      V_CODFILIALDESTINO -- in varchar2 default '' - usado no processo de venda para deposito fechado (TIPONUMERADOR=D)
                                     ,
                                     V_CODGRUPO_SEQ_PROD -- in number default null --usado no processo de sequencia por produto
                                     ,
                                      P_NUMERO -- Parâmetro de Saída(número da nota)
                                     ,
                                      P_SERIE -- Parâmetro de Saída(Série da nota)
                                     ,
                                      P_RESULTADO -- Parâmetro de Saída(Resultado da Operação )
                                     ,
                                      P_MENSAGEM); -- Parâmetro de Saída(Mensagem, em caso de erro)

              else

                OBTERPROXIMONUMERONFE(0 -- Rota principal
                                     ,
                                      P_CODIGOFILIAL --Código da Filial
                                     ,
                                      P_MOVIMENTO --S - Saída(PCNFSAID)| E - Entrada(PCNFENT | I - Importacao
                                     ,
                                      P_SEFAZORIGEM -- S - SERAZ DE ORIGEM | N - SCAN
                                     ,
                                      TIPONUMERADOR -- Contador Padrão
                                     ,
                                      V_CODFILIALDESTINO -- in varchar2 default '' - usado no processo de venda para deposito fechado (TIPONUMERADOR=D)
                                     ,
                                     V_CODGRUPO_SEQ_PROD -- in number default null --usado no processo de sequencia por produto
                                     ,
                                      P_NUMERO -- Parâmetro de Saída(número da nota)
                                     ,
                                      P_SERIE -- Parâmetro de Saída(Série da nota)
                                     ,
                                      P_RESULTADO -- Parâmetro de Saída(Resultado da Operação )
                                     ,
                                      P_MENSAGEM); -- Parâmetro de Saída(Mensagem, em caso de erro)
              end if;
            end if;
          end if;
        end if;
      else
        if P_SEFAZORIGEM = 'S' then
          if SERIE_ATUAL > 899 then
            begin
              insert into PCINUTILIZARNFE
                (SERIE, NUMNOTA, TIPOMOV, NUMTRANSACAO, DTLANC)
              values
                (SERIE_ATUAL, NUMNOTA_ATUAL, 'S', P_TRANSACAO, sysdate);
            exception
              when others then
                P_RESULTADO := 56;
                P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                               ' - Erro ao inserir registro na tabela "PCINUTILIZARNFE" ' ||
                               sqlcode || ' - ' || sqlerrm;
                rollback;
                return;
            end;
            if P_RESULTADO = 0 then
              JA_UTILIZOUNUMNFE := 'N';

              if TIPODESCARGA in ('6', '7', '8', 'T') then
                -- Devolução de cliente
                if USANUMNFDEVCLI = 'S' or TIPONUMNFENTRADA = 2 then
                  TIPONUMERADOR := 'E';

                  if TIPO_VENDA = 14 then
                    TIPONUMERADOR := 'M';
                    if CONTROLE_NFE_POR_ROTA = 'S' then
                      TIPONUMERADOR := 'R';
                    end if;
                  end if;
                  -- Utilizar contador específico para operações de entradas

                  OBTERPROXIMONUMERONFE(0 -- Rota principal
                                       ,
                                        P_CODIGOFILIAL --Código da Filial
                                       ,
                                        P_MOVIMENTO --S - Saída(PCNFSAID)| E - Entrada(PCNFENT
                                       ,
                                        P_SEFAZORIGEM -- S - SERAZ DE ORIGEM | N - SCAN
                                       ,
                                        TIPONUMERADOR -- Contador Padrão
                                       ,
                                        V_CODFILIALDESTINO -- in varchar2 default '' - usado no processo de venda para deposito fechado (TIPONUMERADOR=D)
                                       ,
                                       V_CODGRUPO_SEQ_PROD -- in number default null --usado no processo de sequencia por produto
                                       ,
                                        P_NUMERO -- Parâmetro de Saída(número da nota)
                                       ,
                                        P_SERIE -- Parâmetro de Saída(Série da nota)
                                       ,
                                        P_RESULTADO -- Parâmetro de Saída(Resultado da Operação )
                                       ,
                                        P_MENSAGEM); -- Parâmetro de Saída(Mensagem, em caso de erro)

                else
                  --Utilizar mesmo contador de Saída

                  OBTERPROXIMONUMERONFE(0 -- Rota principal
                                       ,
                                        P_CODIGOFILIAL --Código da Filial
                                       ,
                                        P_MOVIMENTO --S - Saída(PCNFSAID)| E - Entrada(PCNFENT
                                       ,
                                        P_SEFAZORIGEM -- S - SERAZ DE ORIGEM | N - SCAN
                                       ,
                                        TIPONUMERADOR -- Contador Padrão
                                       ,
                                        V_CODFILIALDESTINO -- in varchar2 default '' - usado no processo de venda para deposito fechado (TIPONUMERADOR=D)
                                       ,
                                       V_CODGRUPO_SEQ_PROD -- in number default null --usado no processo de sequencia por produto
                                       ,
                                        P_NUMERO -- Parâmetro de Saída(número da nota)
                                       ,
                                        P_SERIE -- Parâmetro de Saída(Série da nota)
                                       ,
                                        P_RESULTADO -- Parâmetro de Saída(Resultado da Operação )
                                       ,
                                        P_MENSAGEM); -- Parâmetro de Saída(Mensagem, em caso de erro)

                end if;
              end if;
            end if;
          end if;
        else
          if SERIE_ATUAL < 900 then
            begin
              insert into PCINUTILIZARNFE
                (SERIE, NUMNOTA, TIPOMOV, NUMTRANSACAO, DTLANC)
              values
                (SERIE_ATUAL, NUMNOTA_ATUAL, 'S', P_TRANSACAO, sysdate);
            exception
              when others then
                P_RESULTADO := 57;
                P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                               ' - Erro ao inserir registro na tabela "PCINUTILIZARNFE" ' ||
                               sqlcode || ' - ' || sqlerrm;
                rollback;
                return;
            end;
            if P_RESULTADO = 0 then
              JA_UTILIZOUNUMNFE := 'N';
              if TIPODESCARGA in ('6', '7', '8', 'T') then
                -- Devolução de cliente
                if USANUMNFDEVCLI = 'S' or TIPONUMNFENTRADA = 2 then
                  TIPONUMERADOR := 'E';

                  if (TIPO_VENDA = 14) then
                    TIPONUMERADOR := 'M';
                    if CONTROLE_NFE_POR_ROTA = 'S' then
                      TIPONUMERADOR := 'R';
                    end if;
                  end if;

                  -- Utilizar contador específico para operações de entradas
                  OBTERPROXIMONUMERONFE(0 -- Rota principal
                                       ,
                                        P_CODIGOFILIAL --Código da Filial
                                       ,
                                        P_MOVIMENTO --S - Saída(PCNFSAID)| E - Entrada(PCNFENT
                                       ,
                                        P_SEFAZORIGEM -- S - SERAZ DE ORIGEM | N - SCAN
                                       ,
                                        TIPONUMERADOR -- Contador Padrão
                                       ,
                                        V_CODFILIALDESTINO -- in varchar2 default '' - usado no processo de venda para deposito fechado (TIPONUMERADOR=D)
                                       ,
                                       V_CODGRUPO_SEQ_PROD -- in number default null --usado no processo de sequencia por produto
                                       ,
                                        P_NUMERO -- Parâmetro de Saída(número da nota)
                                       ,
                                        P_SERIE -- Parâmetro de Saída(Série da nota)
                                       ,
                                        P_RESULTADO -- Parâmetro de Saída(Resultado da Operação )
                                       ,
                                        P_MENSAGEM); -- Parâmetro de Saída(Mensagem, em caso de erro)

                else

                  TIPONUMERADOR := 'P';

                  if (SERIE_POR_PRODUTO = 'S') then
                    TIPONUMERADOR := 'O';
                  end if;                  
                  
                  --Utilizar mesmo contador de Saída
                  OBTERPROXIMONUMERONFE(0 -- Rota principal
                                       ,
                                        P_CODIGOFILIAL --Código da Filial
                                       ,
                                        P_MOVIMENTO --S - Saída(PCNFSAID)| E - Entrada(PCNFENT
                                       ,
                                        P_SEFAZORIGEM -- S - SERAZ DE ORIGEM | N - SCAN
                                       ,
                                        TIPONUMERADOR -- Contador Padrão
                                       ,
                                        V_CODFILIALDESTINO -- in varchar2 default '' - usado no processo de venda para deposito fechado (TIPONUMERADOR=D)
                                       ,
                                       V_CODGRUPO_SEQ_PROD -- in number default null --usado no processo de sequencia por produto
                                       ,
                                        P_NUMERO -- Parâmetro de Saída(número da nota)
                                       ,
                                        P_SERIE -- Parâmetro de Saída(Série da nota)
                                       ,
                                        P_RESULTADO -- Parâmetro de Saída(Resultado da Operação )
                                       ,
                                        P_MENSAGEM); -- Parâmetro de Saída(Mensagem, em caso de erro)

                end if;
              else
                if TIPODESCARGA not in ('N', 'F') then
                  if TIPONUMNFENTRADA = '1' then

                    TIPONUMERADOR := 'P';
                    OBTERPROXIMONUMERONFE(0 -- Rota principal
                                         ,
                                          P_CODIGOFILIAL --Código da Filial
                                         ,
                                          P_MOVIMENTO --S - Saída(PCNFSAID)| E - Entrada(PCNFENT
                                         ,
                                          P_SEFAZORIGEM -- S - SERAZ DE ORIGEM | N - SCAN
                                         ,
                                          TIPONUMERADOR -- Contador Padrão
                                         ,
                                          V_CODFILIALDESTINO -- in varchar2 default '' - usado no processo de venda para deposito fechado (TIPONUMERADOR=D)
                                         ,
                                         V_CODGRUPO_SEQ_PROD -- in number default null --usado no processo de sequencia por produto
                                         ,
                                          P_NUMERO -- Parâmetro de Saída(número da nota)
                                         ,
                                          P_SERIE -- Parâmetro de Saída(Série da nota)
                                         ,
                                          P_RESULTADO -- Parâmetro de Saída(Resultado da Operação )
                                         ,
                                          P_MENSAGEM); -- Parâmetro de Saída(Mensagem, em caso de erro)

                  else
                    TIPONUMERADOR := 'E';
                    OBTERPROXIMONUMERONFE(0 -- Rota principal
                                         ,
                                          P_CODIGOFILIAL --Código da Filial
                                         ,
                                          P_MOVIMENTO --S - Saída(PCNFSAID)| E - Entrada(PCNFENT
                                         ,
                                          P_SEFAZORIGEM -- S - SERAZ DE ORIGEM | N - SCAN
                                         ,
                                          TIPONUMERADOR -- Contador Padrão
                                         ,
                                          V_CODFILIALDESTINO -- in varchar2 default '' - usado no processo de venda para deposito fechado (TIPONUMERADOR=D)
                                         ,
                                         V_CODGRUPO_SEQ_PROD -- in number default null --usado no processo de sequencia por produto
                                         ,
                                          P_NUMERO -- Parâmetro de Saída(número da nota)
                                         ,
                                          P_SERIE -- Parâmetro de Saída(Série da nota)
                                         ,
                                          P_RESULTADO -- Parâmetro de Saída(Resultado da Operação )
                                         ,
                                          P_MENSAGEM); -- Parâmetro de Saída(Mensagem, em caso de erro)

                  end if;
                else
                  if GERANFVENDA = 'S' then
                    TIPONUMERADOR := 'I';
                  end if;
                  OBTERPROXIMONUMERONFE(0 -- Rota principal
                                       ,
                                        P_CODIGOFILIAL --Código da Filial
                                       ,
                                        P_MOVIMENTO --S - Saída(PCNFSAID)| E - Entrada(PCNFENT | I - Importacao
                                       ,
                                        P_SEFAZORIGEM -- S - SERAZ DE ORIGEM | N - SCAN
                                       ,
                                        TIPONUMERADOR -- Contador Padrão
                                       ,
                                        V_CODFILIALDESTINO -- in varchar2 default '' - usado no processo de venda para deposito fechado (TIPONUMERADOR=D)
                                       ,
                                       V_CODGRUPO_SEQ_PROD -- in number default null --usado no processo de sequencia por produto
                                       ,
                                        P_NUMERO -- Parâmetro de Saída(número da nota)
                                       ,
                                        P_SERIE -- Parâmetro de Saída(Série da nota)
                                       ,
                                        P_RESULTADO -- Parâmetro de Saída(Resultado da Operação )
                                       ,
                                        P_MENSAGEM); -- Parâmetro de Saída(Mensagem, em caso de erro)
                end if;
              end if;
            end if;
          end if;
        end if;
      end if;
    end if;
    /*
          Atualizar as tabelas que tem ligação com a nota de entrada
    */
    if P_RESULTADO <> 0 then
      rollback;
      return;
    end if;

    if JA_UTILIZOUNUMNFE = 'S' then
      P_NUMERO    := NUMNOTA_ATUAL;
      P_SERIE     := SERIE_ATUAL;
      P_RESULTADO := 0;
      P_MENSAGEM  := '';
      rollback;
      return;
    end if;

    begin

      ID_REGISTRO_ATUAL := null;
      SELECT ROWID, CODCONT
        INTO ID_REGISTRO_ATUAL, P_CODCONT
        FROM PCNFENT
       WHERE NUMTRANSENT = P_TRANSACAO
         AND ESPECIE IN ('NF', 'NE')
         AND ((NVL(GERANFVENDA, 'N') = 'S') OR
             (NVL(GERANFDEVCLI, 'N') = 'S'));

      update PCNFENT
         set PCNFENT.NUMNOTA        = P_NUMERO,
             PCNFENT.SERIE          = P_SERIE,
             PCNFENT.CONSUMIUNUMNFE = 'S'
       where PCNFENT.rowid = ID_REGISTRO_ATUAL;

    exception
      when others then
        P_RESULTADO := 200;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCNFENT". ' ||
                       sqlcode || ' - ' || sqlerrm;
        rollback;
        EXISTE_REGISTRO := false;
        return;
    end;

    begin

      for DADOS in (select rowid
                      into ID_REGISTRO_ATUAL
                      from PCMOV
                     where PCMOV.NUMTRANSENT = P_TRANSACAO) loop
        EXISTE_REGISTRO := true;
      end loop;

      if EXISTE_REGISTRO = true then
        update PCMOV
           set PCMOV.NUMNOTA = P_NUMERO, PCMOV.NUMNOTADEV = P_NUMERO
         where PCMOV.NUMTRANSENT = P_TRANSACAO;
      end if;

      EXISTE_REGISTRO := false;
    exception
      when others then
        P_RESULTADO := 201;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCMOV". ' || sqlcode ||
                       ' - ' || sqlerrm;
        rollback;
        EXISTE_REGISTRO := false;
        return;
    end;

    begin

      ID_REGISTRO_ATUAL := null;
      for DADOS in (select rowid
                      into ID_REGISTRO_ATUAL
                      from PCVERBA
                     where PCVERBA.NUMTRANSENT = P_TRANSACAO)

       loop
        EXISTE_REGISTRO := true;
      end loop;

      if EXISTE_REGISTRO = true then
        update PCVERBA
           set PCVERBA.NUMNOTA = P_NUMERO
         where PCVERBA.NUMTRANSENT = P_TRANSACAO;
      end if;

      EXISTE_REGISTRO := false;
    exception
      when NO_DATA_FOUND then
        null;
      when others then
        P_RESULTADO := 205;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCVERBA". ' ||
                       sqlcode || ' - ' || sqlerrm;
        rollback;
        EXISTE_REGISTRO := false;
        return;
    end;

    --Devolucao a fornecedor - PCVERBA
    begin

      ID_REGISTRO_ATUAL := null;
      for DADOS in (select rowid
                      into ID_REGISTRO_ATUAL
                      from PCVERBA
                     where PCVERBA.NUMTRANSENTDEVFORNEC = P_TRANSACAO)

       loop
        EXISTE_REGISTRO := true;
      end loop;

      if EXISTE_REGISTRO = true then
        update PCVERBA
           set PCVERBA.NUMNOTA = P_NUMERO
         where PCVERBA.NUMTRANSENTDEVFORNEC = P_TRANSACAO;
      end if;

      EXISTE_REGISTRO := false;
    exception
      when NO_DATA_FOUND then
        null;
      when others then
        P_RESULTADO := 205;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCVERBA". ' ||
                       sqlcode || ' - ' || sqlerrm;
        rollback;
        EXISTE_REGISTRO := false;
        return;
    end;

    begin

      ID_REGISTRO_ATUAL := null;
      for DADOS in (select rowid
                      into ID_REGISTRO_ATUAL
                      from PCMOVCIAP
                     where NUMTRANSENT = P_TRANSACAO)

       loop
        EXISTE_REGISTRO := true;
      end loop;

      if EXISTE_REGISTRO = true then
        update PCMOVCIAP
           set PCMOVCIAP.NUMNOTA = P_NUMERO
         where PCMOVCIAP.NUMTRANSENT = P_TRANSACAO;
      end if;

      EXISTE_REGISTRO := false;
    exception
      when NO_DATA_FOUND then
        null;
      when others then
        P_RESULTADO := 206;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCMOVCIAP". ' ||
                       sqlcode || ' - ' || sqlerrm;
        rollback;
        EXISTE_REGISTRO := false;
        return;
    end;

    begin

      ID_REGISTRO_ATUAL := null;
      for DADOS in (select rowid
                      into ID_REGISTRO_ATUAL
                      from PCDESDLANC
                     where NUMTRANSENT = P_TRANSACAO) loop
        EXISTE_REGISTRO := true;
      end loop;

      if EXISTE_REGISTRO = true then
        update PCDESDLANC
           set PCDESDLANC.NUMNOTA = P_NUMERO
         where PCDESDLANC.NUMTRANSENT = P_TRANSACAO;
      end if;
      EXISTE_REGISTRO := false;
    exception
      when NO_DATA_FOUND then
        null;
      when others then
        P_RESULTADO := 210;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCDESDLANC". ' ||
                       sqlcode || ' - ' || sqlerrm;
        rollback;
        EXISTE_REGISTRO := false;
        return;
    end;

    begin
      ID_REGISTRO_ATUAL := null;
      for DADOS in (SELECT PCLANC.ROWID
                      into ID_REGISTRO_ATUAL
                      FROM PCLANC, PCCONSUM
                     WHERE PCLANC.CODCONTA <> NVL(PCCONSUM.CODCONTFRE, 0)
                       AND PCLANC.CODCONTA <> NVL(PCCONSUM.CODCONTOUT, 0)
                       AND PCLANC.NUMTRANSENT = P_TRANSACAO) loop

        update PCLANC
           set PCLANC.NUMNOTA    = P_NUMERO,
               PCLANC.NUMNOTADEV = DECODE(PCLANC.NUMNOTADEV,
                                          NULL,
                                          NULL,
                                          P_NUMERO)
         where PCLANC.ROWID = DADOS.ROWID;

      end loop;

      EXISTE_REGISTRO := false;
    exception
      when NO_DATA_FOUND then
        null;
      when others then
        P_RESULTADO := 211;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCLANC". ' ||
                       sqlcode || ' - ' || sqlerrm;
        rollback;
        EXISTE_REGISTRO := false;
        return;
    end;

    begin
      ID_REGISTRO_ATUAL := null;
      for DADOS in (SELECT PCLANCNF.ROWID
                      into ID_REGISTRO_ATUAL
                      FROM PCLANCNF
                     WHERE PCLANCNF.NUMTRANSENT = P_TRANSACAO) loop
        update PCLANCNF
           set PCLANCNF.NUMNOTA = P_NUMERO
         where PCLANCNF.ROWID = DADOS.ROWID;
      end loop;

      EXISTE_REGISTRO := false;
    exception
      when NO_DATA_FOUND then
        null;
      when others then
        P_RESULTADO := 218;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCLANCNF". ' ||
                       sqlcode || ' - ' || sqlerrm;
        rollback;
        EXISTE_REGISTRO := false;
        return;
    end;

    begin
      ID_REGISTRO_ATUAL := null;
      for DADOS in (select rowid
                      into ID_REGISTRO_ATUAL
                      from PCCRECLI
                     where NUMTRANSENTDEVCLI = P_TRANSACAO)

       loop
        EXISTE_REGISTRO := true;
      end loop;

      if EXISTE_REGISTRO = true then
        update PCCRECLI
           set PCCRECLI.NUMNOTA = P_NUMERO
         where PCCRECLI.NUMTRANSENTDEVCLI = P_TRANSACAO;
      end if;

      EXISTE_REGISTRO := false;
    exception
      when NO_DATA_FOUND then
        null;
      when others then
        P_RESULTADO := 212;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCCRECLI". ' ||
                       sqlcode || ' - ' || sqlerrm;
        rollback;
        EXISTE_REGISTRO := false;
        return;
    end;

    begin
      for DADOS in (select rowid
                      from PCCONTROLENUMSERIE
                     where NUMTRANSENT = P_TRANSACAO)

       loop
        update PCCONTROLENUMSERIE
           set PCCONTROLENUMSERIE.NUMNOTA = P_NUMERO
         where PCCONTROLENUMSERIE.rowid = dados.rowid;
      end loop;

    exception
      when NO_DATA_FOUND then
        null;
      when others then
        P_RESULTADO := 213;
        P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                       ' - Erro ao atualizar a tabela "PCCONTROLENUMSERIE". ' ||
                       sqlcode || ' - ' || sqlerrm;
        rollback;
        EXISTE_REGISTRO := false;
        return;
    end;

    -- Atualizar a Saída de transferencia de deposito (entrada de emissão propria)
    begin
      select NUMTRANSVENDA
        into V_NUMTRANSORIGEM_DEP
        from PCNFSAID
       where NUMTRANSENTORIGEM = P_TRANSACAO;
      EXISTE_REGISTRO := true;
    exception
      when others then
        EXISTE_REGISTRO := false;
    end;

    if EXISTE_REGISTRO then
      begin
        for DADOS in (select rowid
                        from PCMOV
                       where NUMTRANSVENDA = V_NUMTRANSORIGEM_DEP
                         and CODOPER in ('ST', 'SD', 'SC')) loop
          update PCMOV
             set PCMOV.NUMNOTA = P_NUMERO
           where PCMOV.rowid = DADOS.rowid;
        end loop;

      exception
        when others then
          P_RESULTADO := 214;
          P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                         ' - Erro ao atualizar a tabela "PCMOV - TRANSF.1124 (Transferencia deposito)". ' ||
                         sqlcode || ' - ' || sqlerrm;
          rollback;
          raise SAIR_COM_ERRO;
      end;
      begin
        update PCNFSAID
           set PCNFSAID.NUMNOTA = P_NUMERO, PCNFSAID.SERIE = P_SERIE
         where PCNFSAID.NUMTRANSVENDA = V_NUMTRANSORIGEM_DEP;

      exception
        when others then
          P_RESULTADO := 215;
          P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                         ' - Erro ao atualizar a tabela "PCNFSAID" (Transferencia deposito). ' ||
                         sqlcode || ' - ' || sqlerrm;
          rollback;
          return;
      end;

      /*********** SOLICITAÇÃO : 1805.128747.2015 ***********/
      BEGIN
        BEGIN
          SELECT NVL(PCESTCOM.NUMTRANSVENDA, 0)
            INTO NUMTRANSACAO_VENDA
            FROM PCESTCOM
           WHERE PCESTCOM.NUMTRANSENT = P_TRANSACAO
             AND PCESTCOM.NUMTRANSVENDA IS NOT NULL;

        EXCEPTION
          WHEN OTHERS THEN
            NUMTRANSACAO_VENDA := 0;
        END;

        IF (NUMTRANSACAO_VENDA <> 0) THEN
          FOR DADOS IN (SELECT PCMOV.CODPROD, PCMOV.NUMSEQ
                          FROM PCMOV
                         WHERE PCMOV.NUMTRANSENT = P_TRANSACAO) LOOP
            UPDATE PCMOV
               SET PCMOV.NUMNOTADEV = P_NUMERO
             WHERE PCMOV.NUMTRANSVENDA = NUMTRANSACAO_VENDA
               AND PCMOV.CODPROD = DADOS.CODPROD
               AND PCMOV.NUMSEQ = DADOS.NUMSEQ;
          END LOOP;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          P_RESULTADO := 216;
          P_MENSAGEM  := 'Codigo: ' || P_RESULTADO ||
                         ' - Erro ao atualizar a tabela "PCMOV", campo "NUMNOTADEV" da nota de venda. ' ||
                         SQLCODE || ' - ' || SQLERRM;
          RAISE SAIR_COM_ERRO;
      END;
      /*******************************************/

      --ALTERAÇÃO PARA FINANCEIRO
      begin
        ID_REGISTRO_ATUAL := null;
        for DADOS in (select rowid
                        into ID_REGISTRO_ATUAL
                        from PCBENSPATRIMONIAIS
                       where NUMTRANSACAO = P_TRANSACAO)

         loop
          EXISTE_REGISTRO := true;
        end loop;

        if EXISTE_REGISTRO = true then
          update PCBENSPATRIMONIAIS
             set PCBENSPATRIMONIAIS.NUMNOTA = P_NUMERO
           where PCBENSPATRIMONIAIS.NUMTRANSACAO = P_TRANSACAO;
        end if;

        EXISTE_REGISTRO := false;
      exception
        when NO_DATA_FOUND then
          null;
        when others then
          P_RESULTADO := 217;
          P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                         ' - Erro ao atualizar a tabela "PCBENSPATRIMONIAIS". ' ||
                         sqlcode || ' - ' || sqlerrm;
          rollback;
          EXISTE_REGISTRO := false;

          return;
      end;

    end if;

    commit;

  end if;
exception
  when VOLTAR_COM_NUMERACAO_ATUAL then
    begin
      P_NUMERO    := NUMNOTA_ATUAL;
      P_SERIE     := SERIE_ATUAL;
      P_RESULTADO := 0;
      P_MENSAGEM  := '';
      rollback;
    end;

  when SAIR_COM_ERRO then
    begin
      if P_RESULTADO = 0 then
        P_RESULTADO := 1000;
        P_MENSAGEM  := 'Erro desconhecido!';
      end if;
      GERAR_LOG('SAIR_COM_ERRO',
                sqlerrm,
                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      rollback;
    end;

  when others then
    begin
      P_RESULTADO := 1000;
      P_MENSAGEM  := 'Código: ' || P_RESULTADO ||
                     ' - Ocorreu um erro ao tentar obter próximo número de nota fiscal: ' ||
                     sqlcode || ' - ' || sqlerrm;
      GERAR_LOG('OUTROS', sqlerrm, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      rollback;
    end;

end OBTERPROXIMONUMERONOTANFE;