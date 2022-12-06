CREATE OR REPLACE PACKAGE BODY PC_PKG_CONTROLARSALDORCA IS
  /*
   Package criada para controlar conta corrente de RCA

  ***********************************Histórico ***************************************
  Data         Responsável       Tarefa      Comentário
  19/05/2009   Andréa            73271       Projeto 71133
  01/07/2009   Andréa/Sabrina                Ajustes
  06/07/2009   Sabrina                       ccrca_alterar_rca e ccrca_retorna_saldo_item_pedido sao publicas
  08/07/2009   Sabrina                       Gravacao de historico de pclogrca e tratar pcusuari.usadebcredrca nulo
  09/07/2009   Sabrina                       A package não deve barrar a movimentacao do saldo, os programas eh que fazem isso
                                             Ajuste na função de troca de RCA
  10/07/2009   Sabrina                       Correcao na inicializacao das variaveis booleanas
  16/07/2009   Sabrina                       Incluido novo procedimento ccrca_alterar_preco
  21/08/2009   Andréa                        Correção no saldo do item caso seja pedido bonificado
  03/09/2009   Andréa           89939        Projeto 85387 Conta Corrente RCa e Roteirização
  17/11/2009   Andréa           95731        Projeto 90992 Melhoria no desconto financeiro e saldo de conta corrente de rca
  30/11/2009   Andréa                        Correção no projeto para gravar dtfechaccrca na pcnfsaid
  03/12/2009   Andréa                        Corrigir para na ccfincrca_fatura_pedido para verificar 'FF' e 'VV'
  08/12/2009   Sabrina                       Correcao na declaracao das procedures:
                                             ccfinrca_lanca_movimento_carga e ccrca_lancar_movimento_carga
                                             que tambem sao publicas assim como:
                                             ccfinrca_lanca_movimento_caixa e ccrca_lancar_movimento_caixa
                                             Correcao na funcao ccrca_verificar_fechamento que estava sem valor de retorno
  09/12/2009   Andréa                        Correção na ccfincrca_excluir_item_pedido
  10/12/2009   Sabrina                       Correcao na ccfinrca_alterar_preco_qt
  11/12/2009   Sabrina                       Correcao na ccfinrca_devolve_notafiscal
                                             Correcao na ccfinrca_cancela_devolucao
  15/12/2009   Andréa           98438        Correção na ccrca_saldo_item ( acrescentado nvl no parâmetro usadebcredrca)
  16/12/2009   Andréa           98514        Correção para evitar erro de divisor zero  e selects retornando mais de um registro
  16/12/2009   Andréa           98514        Correção no calculo do valor ccfincrca_devolve_notafiscal
  16/12/2009   Andréa                        Alterar  ccfinrca_fatura_pedido para retornar TRUE quando for tipo 'VA'
  17/12/2009   Pablo                         Alterada  ccfinrca_fatura_pedido para retornar TRUE quando for tipo 'VA' e 'VF'
                                             como tinha sido customizado
  22/12/2009   Andréa           98953        Alteração em function ccfinrca_cancela_notafiscal
  23/12/2009   Pablo            98963        Alteração em ccfinrca_cancela_notafiscal para o tipo VA
  11/01/2010   Thiago           99461        Caso o Numtransent seja menor que zero não realizar a chamada da função ccrca_retornar_saldo_item_dev
  11/01/2010   Andréa           99600        Ajuste na function ccfinrca_cancela_notafiscal, para verificar o saldo antes de lançar o débito
  20/01/2010   Pablo            99976        Alteração para não retornar valor FALSE nas funções que validam Des. Financ. quando a venda for
                                             TV4, TV5 , TV8, TV11, TV13 ou TV20
  23/02/2010   Pablo           102070        Caso o desconto financeiro seja gravado por valor  pcfilial.gravarvalordescfin = 'S' na
                                             1) inclusão de itens individuais ccfinrca_incluir_item_pedido,
                                             2) alteração de preco\qt         ccfinrca_alterar_preco_qt
                                             3) exclusão de item              ccfinrca_excluir_item_pedido
                                             não será realizado lancamento (o mesmo já foi realizado na digitação do pedido)
  16/03/2010  Pablo            103974        Alteração para tratar venda TV5 na função ccrca_incluir_item_nf
  19/03/2010  Pablo            100601        Alteração na função ccrca_saldo_item para validar na venda TV5 se o brinde vai mov D/C do RCA.
  06/04/2010  Pablo            105173        Correção da função ccfinrca_excluir_item_pedido
  07/04/2010  Pablo            105260        Alteração para criar as funções ccrca_retorna_saldo_anterior e ccrca_saldo_item com variação
                                             da chamada conforme o nr. de parametros
  13/04/2010 Thiago            105225        Erros homologação Fernandes
  16/04/2010 Thiago            105946        Erros homologação Fernandes
  19/04/2010 Thiago            105946        Erros homologação Fernandes  15.0.3.11
  19/04/2010 Thiago            105946        Erros homologação Fernandes  15.0.3.12
  28/04/2010 Thiago            106838        Alteração na função ccfinrca_cancela_notafiscal caso não exista percentual de desconto financeiro
                                             retorna true para a função para permitir o cancelamento via rotina 1409 v.15.0.3.13
  12/05/2010 Thiago            107825        Correção da função ccrca_excluir_item_dev
  07/06/2010 Thiago            109141        Incluído o condvenda 20 na função ccrca_incluir_iten_nf para consideração do campo punitcont conforem solicitado
  07/06/2010 Andréa            107526        Incluir verificação de combo (movimentacontacorrenterca)
                                             Foi incluida novas procedures com novo parâmetro : ccrc_saldo_item,ccrca_retorna_saldo_anterior
  09/08/2010 Thiago            113031        Alterada a chamada do procedimento "ccrca_validar_acerto_nf" para deduzir a quantidade devolvida
  03/09/2010 Pablo             114710        Tratar a função ccrca_incluir_item_nf para venda TV11 que não possui PCMOV.PUNIT somente PCMOV.PunitCont
  15/04/2011 Thiago           128693 Alterada package para no ato de alguma devolução ou cancelamento não estornar o saldo caso o mesmo não tenho sido
  movimentado para itens do tipo combo através do campo "movimentacontacorrenterca"
  18/08/2011 Thiago            139770       Corrigido o erro apresentado na função ccrca_incluir_item_nf para tipo de movimentação "FF" para a venda tipo 7 e 8
  14/06/2012 Rodrigo Santos    164941        Alterados os métodos "ccrca_saldo_item" para zerar o PBASERCA quando o parâmetro "CON_TROCAALTDEBCREDRCA"
                                             estiver marcado como "Sim" e o pedido for TV11.
  23/08/2012 Fabrício Borges   171309        Ajustado o procedimento ccrca_incluir_item_nf no select da pcmov para o tipo venda 14
  11/09/2012 Rodrigo Santos    172790           Ajustada a procedure "ccrca_validar_acerto_nf" para prever exceção de mais de um registro no "select into".
  01/09/2014 Rodrigo Santos    HIS.03429.2014   Ajustada a package para considerar como bonificação as vendas TV14 onde no item estiver assinalado como brinde(PCPEDI.BRINDE = 'S').
  06/10/2014 Rafael Braga      1436.108867.2014 Adicionada procedure GravarLog para gravarmos mais informações no tratamento de erro.
                                                                                        */
  --------------------------------------------------------------------------------------
  PROCEDURE GRAVARLOG(PPARAMS IN OUT PCLOGERRORCA%ROWTYPE)
  /*************************************************************************************
  -------------------------- Alterações ------------------------------------------------
  Data           Autor             Tarefa            Descrição
  --------------------------------------------------------------------------------------
  06/10/2013     Rafael Braga      1436.108867.2014  Criação da procedure (baseada na GravarLog da PKG_FATURAMENTO)
  *************************************************************************************/
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN

      SELECT DFSEQ_PCLOGERRORCA.NEXTVAL
        INTO PPARAMS.SEQ
        FROM DUAL;

    INSERT INTO PCLOGERRORCA VALUES PPARAMS;

    COMMIT;

  END GRAVARLOG;
  --------------------------------------------------------------------------------------

  FUNCTION buscarversao RETURN NUMBER IS
  BEGIN
    RETURN(3);
  END; --buscarversao

  PROCEDURE proc_lerparametros(vsmensagem OUT VARCHAR2) IS
  BEGIN
    vsmensagem := NULL;

    SELECT NVL(pcconsum.usacredrca, 'N') usacredrca,
           NVL(pcconsum.bonificaltdebcredrca, 'S') bonificaltdebcredrca,
           NVL(pcconsum.trocaaltdebcredrca, 'S') trocaaltdebcredrca,
           NVL(pcconsum.brokeraltdebcredrca, 'S') brokeraltdebcredrca,
           NVL(pcconsum.crmaltdebcredrca, 'S') crmaltdebcredrca,
           NVL(pcconsum.tipomovccrca, 'VV') tipomovccrca,
           pcconsum.usasaldocontacorrentedescfin,
		   NVL(pcconsum.usaptabelacomobase, 'N') usaptabelacomobase,
           NVL(paramfilial.obtercomovarchar2('USACREDGERENTE'), 'S'),
           NVL(paramfilial.obtercomovarchar2('USACREDSUPERVISOR'), 'S'),           
           NVL(paramfilial.obtercomovarchar2('TIPOMOVCCGERENTE'), 'VV'),
           NVL(paramfilial.obtercomovarchar2('TIPOMOVCCSUPERVISOR'), 'VV')           
      INTO gregpcconsum
      FROM pcconsum;
    EXCEPTION
    WHEN OTHERS THEN
      vsmensagem := 'Erro ao ler parametros#;' || SQLCODE || '-' || SQLERRM;
  END; --proc_lerparametros;

  FUNCTION ccfinrca_saldorcamenosdescfin(pcodusur   IN NUMBER,
                                         pcodfilial IN VARCHAR2)
    RETURN NUMBER IS
    /*******************************************************************************
     Objetivo: Pesquisar os descontos financeiros dos pedidos do RCA, e abater
      este valor do Saldo do RCA. O retorno da função é o resultado desta subtração:
      Saldo RCA - Desconto Financeiro dos Pedidos
             Historico de Alteracoes
    --------------------------------------------------------------------------------
      Data               Responsavel            Descricao
      ----------------   ---------------------  ------------------------------------
      13/08/2007         Carolina              Criacao da função
      14/08/2007         Pablo                  Alteração para não retornar Valor negativo
      15/08/2007         Pablo                  Alteração para corrigir o Cálculo do Valor do Desconto Financeiro concedido
                                                            foi acrescentado  (Nvl(Pcpedc.Perdescfin, 0) / 100) pois estava somente  Nvl(Pcpedc.Perdescfin, 0)
      14/09/2007         Pablo                  Tarefa 51188 Caso não exista registro em PCSALDORCA será gerado um registro com Saldo zerado.
      04/11/2009         Pablo                  Tarefa 95730 (Customização do Projeto 90992 Melhoria Desconto Financeiro e Saldo Conta-Corrente).
    *******************************************************************************/
    -- Declaracao de Variaveis
    vncontador  NUMBER(3);
    vvalordesc  NUMBER(14, 2);
    vvalorsaldo NUMBER(14, 2);
    vnresultado NUMBER(14, 2);
  BEGIN
    vvalordesc  := 0;
    vvalorsaldo := 0;

    SELECT SUM(NVL(pcpedc.vlatend, 0) * (NVL(pcpedc.perdescfin, 0) / 100))
      INTO vvalordesc
      FROM pcpedc
     WHERE posicao IN ('L', 'M', 'B', 'P') -- Tarefa 95730
       AND NVL(bloqueiosaldoccdescfin, 'N') = 'N' -- Tarefa 95730
       AND NVL(tipomovccrca, 'VV') IN ('VV', 'FF') -- Tarefa 95730
       AND codusur = pcodusur
       AND codfilial = pcodfilial
       AND DATA BETWEEN (TRUNC(SYSDATE) - 120) AND TRUNC(SYSDATE);

    SELECT COUNT(*)
      INTO vncontador
      FROM pcsaldorca
     WHERE codusur = pcodusur;

    IF vncontador = 0 THEN
      INSERT INTO pcsaldorca
        (codusur, vlsaldo, vlsaldoant)
      VALUES
        (pcodusur, 0, 0);

      vvalorsaldo := 0;
    ELSE
      SELECT NVL(vlsaldo, 0)
        INTO vvalorsaldo
        FROM pcsaldorca
       WHERE codusur = pcodusur;
    END IF;

    vnresultado := NVL(vvalorsaldo, 0) - NVL(vvalordesc, 0);

    IF vnresultado < 0 THEN
      vnresultado := 0;
    END IF;

    RETURN(vnresultado);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END; --ccfinrca_saldorcamenosdescfin

  FUNCTION ccrca_verificar_fechamento(p_numtransvenda IN pcnfsaid.numtransvenda%TYPE)
    RETURN BOOLEAN IS
    vnnumcar  pccarreg.numcar%TYPE;
    vddtfecha pccarreg.dtfecha%TYPE;
    vbvalido  BOOLEAN;
    vicont    NUMBER;
  BEGIN
    SELECT NUMCAR, DTFECHA
      INTO VNNUMCAR, VDDTFECHA
      FROM (SELECT NUMCAR, DTFECHA, 1 A
              FROM PCNFSAID
             WHERE NUMTRANSVENDA = P_NUMTRANSVENDA
            UNION
            SELECT NUMCAR, DTFECHA, 2 A
              FROM PCNFSAIDPREFAT
             WHERE NUMTRANSVENDA = P_NUMTRANSVENDA)
      WHERE ROWNUM = 1
      ORDER BY A;
    /*
    SELECT numcar, dtfecha
      INTO vnnumcar, vddtfecha
      FROM pcnfsaid
     WHERE numtransvenda = p_numtransvenda;*/

    IF NVL(vnnumcar, 0) <> 0 THEN
      --Tarefa 105946
      /*SELECT pccarreg.dtfecha
       INTO vddtfecha
       FROM pccarreg
      WHERE numcar = vnnumcar;*/

      IF vddtfecha IS NOT NULL THEN
        vbvalido := TRUE;
      ELSE
        vbvalido := FALSE;
      END IF;
    ELSE
      SELECT SUM(QT)
        INTO vicont
        FROM (SELECT COUNT(1) QT
                FROM PCPREST
               WHERE NUMTRANSVENDA = p_numtransvenda
               UNION
              SELECT COUNT(1) QT
                FROM PCPRESTPREFAT
               WHERE NUMTRANSVENDA = p_numtransvenda);
      /*
      SELECT COUNT(*)
        INTO vicont
        FROM pcprest
       WHERE numtransvenda = p_numtransvenda;
       */
      IF vicont = 0 THEN
        vbvalido := TRUE;
      ELSE
        SELECT SUM(QT)
          INTO vicont
          FROM (SELECT COUNT(1) QT
                  FROM PCPREST
                 WHERE NUMTRANSVENDA = p_numtransvenda
                   AND dtfecha IS NOT NULL
                 UNION
                SELECT COUNT(1) QT
                  FROM PCPRESTPREFAT
                 WHERE NUMTRANSVENDA = p_numtransvenda
                   AND dtfecha IS NOT NULL);
                 /*
        SELECT COUNT(*)
          INTO vicont
          FROM pcprest
         WHERE numtransvenda = p_numtransvenda
           AND dtfecha IS NOT NULL;    */

        IF vicont <> 0 THEN
          vbvalido := TRUE;
        ELSE
          vbvalido := FALSE;
        END IF;
      END IF;
    END IF;

    RETURN vbvalido;
  END;

  -- RNG01
  FUNCTION ccrca_checar_saldo_atual(p_codusur IN pcpedc.codusur%TYPE)
    RETURN NUMBER IS
    vnvlcorrente pcusuari.vlcorrente%TYPE;
  BEGIN
    BEGIN
      SELECT NVL(pcusuari.vlcorrente, 0)
        INTO vnvlcorrente
        FROM pcusuari
       WHERE codusur = p_codusur;
    EXCEPTION
      WHEN OTHERS THEN
        vnvlcorrente := 0;
    END;

    RETURN vnvlcorrente;
  END; --ccrca_checar_saldo_atual

  FUNCTION ccger_checar_saldo_atual(p_codgerente IN pcgerente.codgerente%TYPE)
    RETURN NUMBER IS
    vnvlcorrente pcgerente.vlcorrente%TYPE;
  BEGIN
    BEGIN
      SELECT NVL(pcgerente.vlcorrente, 0)
        INTO vnvlcorrente
        FROM pcgerente
       WHERE codgerente = p_codgerente;
    EXCEPTION
      WHEN OTHERS THEN
        vnvlcorrente := 0;
    END;

    RETURN vnvlcorrente;
  END; --ccger_checar_saldo_atual

  FUNCTION ccsup_checar_saldo_atual(p_codsupervisor IN pcsuperv.codsupervisor%TYPE)
    RETURN NUMBER IS
    vnvlcorrente pcsuperv.vlcorrente%TYPE;
  BEGIN
    BEGIN
      SELECT NVL(pcsuperv.vlcorrente, 0)
        INTO vnvlcorrente
        FROM pcsuperv
       WHERE codsupervisor = p_codsupervisor;
    EXCEPTION
      WHEN OTHERS THEN
        vnvlcorrente := 0;
    END;

    RETURN vnvlcorrente;
  END; --ccsup_checar_saldo_atual

  --RNG26
  FUNCTION ccrca_checar_limite_credito(p_codusur pcusuari.codusur%TYPE)
    RETURN NUMBER IS
    vnvllimcred pcusuari.vllimcred%TYPE;
  BEGIN
    BEGIN
      SELECT NVL(pcusuari.vllimcred, 0)
        INTO vnvllimcred
        FROM pcusuari
       WHERE codusur = p_codusur;
    EXCEPTION
      WHEN OTHERS THEN
        vnvllimcred := 0;      
    END;
    RETURN(vnvllimcred);
  END; --ccrca_checar_limite_credito

  FUNCTION ccger_checar_limite_credito(p_codgerente pcgerente.codgerente%TYPE)
    RETURN NUMBER IS
    vnvllimcred pcgerente.vllimcred%TYPE;
  BEGIN
   begin
    SELECT NVL(pcgerente.vllimcred, 0)
      INTO vnvllimcred
      FROM pcgerente
     WHERE codgerente = p_codgerente;
    EXCEPTION
      WHEN OTHERS THEN
        vnvllimcred := 0;      
    END;

    RETURN(vnvllimcred);
  END; --ccger_checar_limite_credito

  FUNCTION ccsup_checar_limite_credito(p_codsupervisor pcsuperv.codsupervisor%TYPE)
    RETURN NUMBER IS
    vnvllimcred pcsuperv.vllimcred%TYPE;
  BEGIN
    BEGIN
      SELECT NVL(pcsuperv.vllimcred, 0)
        INTO vnvllimcred
        FROM pcsuperv
       WHERE codsupervisor = p_codsupervisor;
    EXCEPTION
      WHEN OTHERS THEN
        vnvllimcred := 0;      
    END;

    RETURN(vnvllimcred);
  END; --ccsup_checar_limite_credito

  -- RNG02
  FUNCTION ccrca_checar_disponivel_atual(p_codusur IN pcpedc.codusur%TYPE)
    RETURN NUMBER IS
    vnvldisponivel NUMBER;
  BEGIN
    vnvldisponivel := 0;
    vnvldisponivel := NVL(ccrca_checar_limite_credito(p_codusur), 0) +
                      NVL(ccrca_checar_saldo_atual(p_codusur), 0);
    RETURN vnvldisponivel;
  END; -- ccrca_checar_disponivel_atual

  FUNCTION ccger_checar_disponivel_atual(p_codgerente IN pcgerente.codgerente%TYPE)
    RETURN NUMBER IS
    vnvldisponivel NUMBER;
  BEGIN
    vnvldisponivel := 0;
    vnvldisponivel := NVL(ccger_checar_limite_credito(p_codgerente), 0) +
                      NVL(ccger_checar_saldo_atual(p_codgerente), 0);
    RETURN vnvldisponivel;
  END; -- ccger_checar_disponivel_atual

  FUNCTION ccsup_checar_disponivel_atual(p_codsupervisor IN pcsuperv.codsupervisor%TYPE)
    RETURN NUMBER IS
    vnvldisponivel NUMBER;
  BEGIN
    vnvldisponivel := 0;
    vnvldisponivel := NVL(ccsup_checar_limite_credito(p_codsupervisor), 0) +
                      NVL(ccsup_checar_saldo_atual(p_codsupervisor), 0);
    RETURN vnvldisponivel;
  END; -- ccsup_checar_disponivel_atual

  -- RNG06 (rng03, rng04, rng05)
  FUNCTION ccrca_saldo_item( -- 17 parametros
                            p_usacredrca           IN pcpedc.usacredrca%TYPE,
                            p_usadebcredrca        IN pcpedc.usadebcredrca%TYPE,
                            p_broker               IN pcpedc.broker%TYPE,
                            p_origemped            IN pcpedc.origemped%TYPE,
                            p_bonificaltdebcredrca IN pcpedc.bonificaltdebcredrca%TYPE,
                            p_trocaaltdebcredrca   IN pcpedc.trocaaltdebcredrca%TYPE,
                            p_crmaltdebcredrca     IN pcpedc.crmaltdebcredrca%TYPE,
                            p_brokeraltdebcredrca  IN pcpedc.brokeraltdebcredrca%TYPE,
                            p_tipomovccrca         IN pcpedc.tipomovccrca%TYPE,
                            p_condvenda            IN pcpedc.condvenda%TYPE,
                            p_brinde               IN pcpedc.brinde%TYPE,
                            p_codusur              IN pcpedc.codusur%TYPE,
                            p_tipo                 IN VARCHAR2,
                            --tipo de processo V - Venda, F - Faturamento, C - Cancelamento, D - devolucao, A - Acerto
                            p_pvenda   IN pcpedi.pvenda%TYPE,
                            p_ptabela  IN pcpedi.ptabela%TYPE,
                            p_pbaserca IN pcpedi.pbaserca%TYPE,
                            p_qt       IN pcpedi.qt%TYPE) RETURN NUMBER IS
    vnvlsaldoitem NUMBER;
  BEGIN

    vnvlsaldoitem := ccrca_saldo_item(p_usacredrca,
                                      p_usadebcredrca,
                                      p_broker,
                                      p_origemped,
                                      p_bonificaltdebcredrca,
                                      p_trocaaltdebcredrca,
                                      p_crmaltdebcredrca,
                                      p_brokeraltdebcredrca,
                                      p_tipomovccrca,
                                      p_condvenda,
                                      p_brinde,
                                      p_codusur,
                                      p_tipo,
                                      p_pvenda,
                                      p_ptabela,
                                      p_pbaserca,
                                      p_qt,
                                      'N' --p_usaDebCredRCABrind
                                     );

    RETURN ROUND(vnvlsaldoitem, 2);

  END; -- ccrca_saldo_item

  -- RNG06 (rng03, rng04, rng05)
  FUNCTION ccrca_saldo_item( -- 18 Parametros
                            p_usacredrca           IN pcpedc.usacredrca%TYPE,
                            p_usadebcredrca        IN pcpedc.usadebcredrca%TYPE,
                            p_broker               IN pcpedc.broker%TYPE,
                            p_origemped            IN pcpedc.origemped%TYPE,
                            p_bonificaltdebcredrca IN pcpedc.bonificaltdebcredrca%TYPE,
                            p_trocaaltdebcredrca   IN pcpedc.trocaaltdebcredrca%TYPE,
                            p_crmaltdebcredrca     IN pcpedc.crmaltdebcredrca%TYPE,
                            p_brokeraltdebcredrca  IN pcpedc.brokeraltdebcredrca%TYPE,
                            p_tipomovccrca         IN pcpedc.tipomovccrca%TYPE,
                            p_condvenda            IN pcpedc.condvenda%TYPE,
                            p_brinde               IN pcpedc.brinde%TYPE,
                            p_codusur              IN pcpedc.codusur%TYPE,
                            p_tipo                 IN VARCHAR2,
                            --tipo de processo V - Venda, F - Faturamento, C - Cancelamento, D - devolucao, A - Acerto
                            p_pvenda             IN pcpedi.pvenda%TYPE,
                            p_ptabela            IN pcpedi.ptabela%TYPE,
                            p_pbaserca           IN pcpedi.pbaserca%TYPE,
                            p_qt                 IN pcpedi.qt%TYPE,
                            p_usaDebCredRCABrind IN pcpedi.usadebcredrcabrind%TYPE -- Tarefa 100601
                            ) RETURN NUMBER IS
    vnvlsaldoitem NUMBER;
  BEGIN
        vnvlsaldoitem := ccrca_saldo_item(p_usacredrca,
                                          p_usadebcredrca,
                                          p_broker,
                                          p_origemped,
                                          p_bonificaltdebcredrca,
                                          p_trocaaltdebcredrca,
                                          p_crmaltdebcredrca,
                                          p_brokeraltdebcredrca,
                                          p_tipomovccrca,
                                          p_condvenda,
                                          p_brinde,
                                          p_codusur,
                                          p_tipo,
                                          p_pvenda,
                                          p_ptabela,
                                          p_pbaserca,
                                          p_qt,
                                          p_usaDebCredRCABrind,
                                          'S', --p_movimentacontacorrenterca
                                          'N');

    RETURN ROUND(vnvlsaldoitem, 2);

  END; -- ccrca_saldo_item

  -- RNG06 (rng03, rng04, rng05)
  FUNCTION ccrca_saldo_item(--20 Parametros
                            p_usacredrca           IN pcpedc.usacredrca%TYPE,
                            p_usadebcredrca        IN pcpedc.usadebcredrca%TYPE,
                            p_broker               IN pcpedc.broker%TYPE,
                            p_origemped            IN pcpedc.origemped%TYPE,
                            p_bonificaltdebcredrca IN pcpedc.bonificaltdebcredrca%TYPE,
                            p_trocaaltdebcredrca   IN pcpedc.trocaaltdebcredrca%TYPE,
                            p_crmaltdebcredrca     IN pcpedc.crmaltdebcredrca%TYPE,
                            p_brokeraltdebcredrca  IN pcpedc.brokeraltdebcredrca%TYPE,
                            p_tipomovccrca         IN pcpedc.tipomovccrca%TYPE,
                            p_condvenda            IN pcpedc.condvenda%TYPE,
                            p_brinde               IN pcpedc.brinde%TYPE,
                            p_codusur              IN pcpedc.codusur%TYPE,
                            p_tipo                 IN VARCHAR2,
                            --tipo de processo V - Venda, F - Faturamento, C - Cancelamento, D - devolucao, A - Acerto
                            p_pvenda                    IN pcpedi.pvenda%TYPE,
                            p_ptabela                   IN pcpedi.ptabela%TYPE,
                            p_pbaserca                  IN pcpedi.pbaserca%TYPE,
                            p_qt                        IN pcpedi.qt%TYPE,
                            p_usaDebCredRCABrind        IN pcpedi.usadebcredrcabrind%TYPE,-- Tarefa 100601
                            p_movimentacontacorrenterca IN pcpedi.movimentacontacorrenterca%TYPE,
                            p_prodBonific               IN pcpedi.BONIFIC%TYPE DEFAULT 'N'
                            ) RETURN NUMBER IS
    vnvlsaldoitem NUMBER;
    vsmsg         VARCHAR2(400);
    VNPERCCREDCCRCA number;
  BEGIN
    --RNG03

    --Tarefa: 164941
    IF nvl(paramfilial.ObterComoVarchar2('CON_TROCAALTDEBCREDRCA'),'N') = 'S'
      then
        SELECT (DECODE(p_condvenda, 5, 0, 11, 0, NVL(p_pvenda, 0)) -
               NVL(p_pbaserca, NVL(p_ptabela, 0))) * NVL(p_qt, 0)
          INTO vnvlsaldoitem
          FROM DUAL;
      else
        SELECT (DECODE(p_condvenda, 5, 0, NVL(p_pvenda, 0)) -
               NVL(p_pbaserca, NVL(p_ptabela, 0))) * NVL(p_qt, 0)
          INTO vnvlsaldoitem
          FROM DUAL;

    END IF;

    proc_lerparametros(vsmsg);

    if p_movimentacontacorrenterca = 'N' then

      vnvlsaldoitem := 0;

    else

      --RNG06
      IF NVL(p_usacredrca, gregpcconsum.usacredrca) = 'S' THEN
        IF nvl(p_usadebcredrca, NVL(p_usacredrca, gregpcconsum.usacredrca)) = 'S' THEN
          IF p_condvenda IN (4, 8, 10, 13, 16, 20) THEN
            vnvlsaldoitem := 0;
          ELSE
            IF (NVL(p_brinde, 'N') = 'S')
              AND (p_condvenda <> 14) --HIS.03429.2014
            THEN
              IF (p_usaDebCredRCABrind = 'N') -- Tarefa 100601
              THEN
                vnvlsaldoitem := 0;
              ELSE
                IF (p_condvenda = (1)) AND
                 (p_prodbonific = 'F')
                THEN
                  IF (NVL(p_bonificaltdebcredrca,
                          gregpcconsum.bonificaltdebcredrca) = 'N') THEN
                    vnvlsaldoitem := 0;
                  ELSE
                    vnvlsaldoitem := (NVL(p_pvenda, 0) * NVL(p_qt, 0)) * (-1);
                  END IF;
                END IF;
              END IF;
            ELSE
              IF (p_condvenda in (1, 14)) AND
                         (p_prodbonific = 'F')
                    THEN
                        IF (NVL(p_bonificaltdebcredrca,
                                    gregpcconsum.bonificaltdebcredrca) = 'N') THEN
                           vnvlsaldoitem := 0;
                        ELSE
                           IF gregpcconsum.usaptabelacomobase = 'S' THEN
                              vnvlsaldoitem := (NVL(p_ptabela, 0) * NVL(p_qt, 0)) * (-1);
                           ELSE                            
                               vnvlsaldoitem := (NVL(p_pvenda, 0) * NVL(p_qt, 0)) * (-1);
                           END IF;
                        END IF;
              ELSIF (p_condvenda = 5)
                OR (p_condvenda = 14 AND NVL(p_brinde, 'N') = 'S') --HIS.03429.2014: Considerar TV14 BRINDE='S' como bonificação
              THEN
                IF (NVL(p_bonificaltdebcredrca,
                        gregpcconsum.bonificaltdebcredrca) = 'N') THEN
                  vnvlsaldoitem := 0;
                ELSE
                  vnvlsaldoitem := (nvl(p_pbaserca, NVL(p_ptabela, NVL(p_pvenda, 0))) * NVL(p_qt, 0))  * (-1);--HIS.03429.2014: Recebe o saldo integral do item
                END IF;
              ELSIF p_condvenda = 11 THEN
                IF NVL(p_trocaaltdebcredrca,
                       gregpcconsum.trocaaltdebcredrca) = 'N' THEN
                  vnvlsaldoitem := 0;
                END IF;
              ELSE
                IF NVL(p_broker, 'N') = 'S' THEN
                  --Broker
                  IF NVL(p_brokeraltdebcredrca,
                         gregpcconsum.brokeraltdebcredrca) = 'N' THEN
                    vnvlsaldoitem := 0;
                  END IF;
                ELSIF p_origemped = 'C' THEN
                  --Callcenter
                  IF NVL(p_crmaltdebcredrca, gregpcconsum.crmaltdebcredrca) = 'N' THEN
                    vnvlsaldoitem := 0;
                  END IF;
                END IF;
              END IF;
            END IF;
          END IF;
          -- Se não for cancelamento/devolução
          IF p_tipo NOT IN ('C', 'D') THEN
            --RNG04
            IF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'VV' THEN
              --Débito/crédito na venda
              -- Se não for venda
              IF p_tipo <> 'V' THEN
                vnvlsaldoitem := 0;
              END IF;
            ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'FF' THEN
              --Débito /crédito no faturamento
              -- Se não for faturamento
              IF p_tipo <> 'F' THEN
                vnvlsaldoitem := 0;
              END IF;
            ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'VF' THEN
              --Débito venda /crédito no faturamento
              IF vnvlsaldoitem > 0 THEN
                -- Se não for faturamento
                IF p_tipo <> 'F' THEN
                  vnvlsaldoitem := 0;
                END IF;
              ELSE
                -- Se não for venda
                IF p_tipo <> 'V' THEN
                  vnvlsaldoitem := 0;
                END IF;
              END IF;
            ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'VA' THEN
              --Débito Venda /crédito no Acerto
              IF vnvlsaldoitem < 0 THEN
                -- Se não for venda
                IF p_tipo <> 'V' THEN
                  vnvlsaldoitem := 0;
                END IF;
              ELSE
                --se não for acerto
                IF p_tipo <> 'A' THEN
                  vnvlsaldoitem := 0;
                END IF;
              END IF;
            END IF;
          END IF;
        ELSIF nvl(p_usadebcredrca,
                  NVL(p_usacredrca, gregpcconsum.usacredrca)) = 'N' THEN
          vnvlsaldoitem := 0;
        END IF;
      ELSE
        --p_usacredrca = 'N'
        vnvlsaldoitem := 0;
      END IF;
    end if;

    /*Begin
      --Busca porcentagem que será creditada no parametro criado para o processo especifico
       SELECT PCPARAMFILIAL.VALOR
          INTO VNPERCCREDCCRCA
         FROM PCPARAMFILIAL
          WHERE PCPARAMFILIAL.NOME LIKE '%PERCCREDCCRCA%'
           AND PCPARAMFILIAL.CODFILIAL = '99';
      --Verifica se existe procentagem informada na 132
      IF(VNPERCCREDCCRCA > 0)and(p_condvenda <> 5)then
       vnvlsaldoitem := (NVL(vnvlsaldoitem, 0)) * (NVL(VNPERCCREDCCRCA, 0) / 100);
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
       --ROLLBACK;
       vrPARAMETROS.Data := sysdate;
       vrPARAMETROS.Rotina := '9999';
       vrPARAMETROS.Historico := SQLCODE || '-' || SQLERRM || CHR(13) || 'ERRO AO BUSCAR PARAMETRO 9801-(PERCCREDCCRCA)';
       vrPARAMETROS.Numped := '9999';
       vrPARAMETROS.Codprod := '9999';
       GravarLog(vrPARAMETROS);

    END; */


    RETURN  ROUND(vnvlsaldoitem, 2);
  END; -- ccrca_saldo_item

  --RNG07
  FUNCTION ccrca_retorna_saldo_itempedido(p_numped  IN pcpedc.numped%TYPE,
                                          p_codusur IN pcpedc.codusur%TYPE,
                                          p_codprod IN pcpedi.codprod%TYPE,
                                          p_numseq  IN pcpedi.numseq%TYPE,
                                          p_qt      IN pcpedi.qt%TYPE,
                                          p_tipo    IN VARCHAR
                                          -- Sabrina: tipo de operação I - Inclusao e E - Exclusao
                                          ) RETURN NUMBER IS
    vsusacredrca                pcpedc.usacredrca%TYPE;
    vsbonificaltdebcredrca      pcpedc.bonificaltdebcredrca%TYPE;
    vstrocaaltdebcredrca        pcpedc.trocaaltdebcredrca%TYPE;
    vsbrokeraltdebcredrca       pcpedc.brokeraltdebcredrca%TYPE;
    vscrmaltdebcredrca          pcpedc.crmaltdebcredrca%TYPE;
    vstipomovccrca              pcpedc.tipomovccrca%TYPE;
    vsusadebcredrca             pcpedc.usadebcredrca%TYPE;
    vsorigemped                 pcpedc.origemped%TYPE;
    vsbrinde                    pcpedc.brinde%TYPE;
    vncondvenda                 pcpedc.condvenda%TYPE;
    vsbroker                    pcpedc.broker%TYPE;
    vnpvenda                    pcpedi.pvenda%TYPE;
    vnptabela                   pcpedi.ptabela%TYPE;
    vnpbaserca                  pcpedi.pbaserca%TYPE;
    vnlanc                      NUMBER;
    vsusadebcredrcabrind        pcpedi.usadebcredrcabrind%TYPE;
    vsmsg                       VARCHAR2(400);
    vsmovimentacontacorrenterca pcpedi.movimentacontacorrenterca%type;
    vsbonific                   pcpedi.bonific%TYPE;
    vsbrinde_item               pcpedi.brinde%type;
    vstipocontacorrente pcpedc.tipocontacorrente%TYPE;
  BEGIN
    proc_lerparametros(vsmsg);

    SELECT p.usacredrca,
           p.bonificaltdebcredrca,
           p.trocaaltdebcredrca,
           p.brokeraltdebcredrca,
           p.crmaltdebcredrca,
           p.tipomovccrca,
           p.usadebcredrca,
/*           DECODE(p.usadebcredrca,
                  NULL,
                  (SELECT NVL(pcusuari.usadebcredrca, gregpcconsum.usacredrca)
                     FROM pcusuari
                    WHERE codusur = p.codusur
                      AND ROWNUM = 1),
                  p.usadebcredrca),*/
           p.origemped,
           NVL(p.brinde, 'N'),
           p.condvenda,
           NVL(p.broker, 'N'),
           nvl(p.tipocontacorrente, 'R')
      INTO vsusacredrca,
           vsbonificaltdebcredrca,
           vstrocaaltdebcredrca,
           vsbrokeraltdebcredrca,
           vscrmaltdebcredrca,
           vstipomovccrca,
           vsusadebcredrca,
           vsorigemped,
           vsbrinde,
           vncondvenda,
           vsbroker,
           vstipocontacorrente
      FROM pcpedc p
     WHERE p.numped = p_numped;

    IF vsusadebcredrca IS NULL THEN
    SELECT CASE WHEN vstipocontacorrente = 'S' 
                THEN NVL(PCSUPERV.USADEBCRED,gregpcconsum.usacredsupervisor)
                WHEN vstipocontacorrente = 'G' 
                THEN NVL(PCGERENTE.USADEBCRED,gregpcconsum.usacredgerente)                
                ELSE NVL(PCUSUARI.USADEBCREDRCA,gregpcconsum.usacredrca)
           END  USADEBCRED
      INTO vsusadebcredrca
      FROM PCPEDC
     INNER JOIN PCUSUARI ON (PCUSUARI.CODUSUR        = PCPEDC.CODUSUR)
     INNER JOIN PCSUPERV ON (PCSUPERV.CODSUPERVISOR  = NVL(PCPEDC.CODSUPERVISOR, PCUSUARI.CODSUPERVISOR))
      LEFT JOIN PCGERENTE ON (PCGERENTE.CODGERENTE   = NVL(PCPEDC.CODGERENTE, PCSUPERV.CODGERENTE))
     WHERE PCPEDC.NUMPED = p_numped;    
    END IF;

    SELECT pvenda,
           ptabela,
           pbaserca,
           NVL(usadebcredrcabrind, 'N'),
           nvl(pcpedi.movimentacontacorrenterca, 'S'),
           nvl(pcpedi.BONIFIC, 'N') BONIFIC,
           pcpedi.brinde
      INTO vnpvenda,
           vnptabela,
           vnpbaserca,
           vsusadebcredrcabrind,
           vsmovimentacontacorrenterca,
           vsbonific,
           vsbrinde_item
      FROM pcpedi
     WHERE numped = p_numped
       AND codprod = p_codprod
       AND numseq = p_numseq;

    IF p_qt > 0 THEN
      vnlanc := ccrca_saldo_item(NVL(vsusacredrca, gregpcconsum.usacredrca),
                                 vsusadebcredrca,
                                 vsbroker,
                                 vsorigemped,
                                 NVL(vsbonificaltdebcredrca,
                                     gregpcconsum.bonificaltdebcredrca),
                                 NVL(vstrocaaltdebcredrca,
                                     gregpcconsum.trocaaltdebcredrca),
                                 NVL(vscrmaltdebcredrca,
                                     gregpcconsum.crmaltdebcredrca),
                                 NVL(vsbrokeraltdebcredrca,
                                     gregpcconsum.brokeraltdebcredrca),
                                 NVL(vstipomovccrca,
                                     NVL(gregpcconsum.tipomovccrca, 'VV')),
                                 vncondvenda,
                                 nvl(vsbrinde_item, vsbrinde), /*2330.089655.2016*/
                                 p_codusur,
                                 'V',
                                 vnpvenda,
                                 vnptabela,
                                 NVL(vnpbaserca, vnptabela),
                                 p_qt,
                                 vsusadebcredrcabrind,
                                 vsmovimentacontacorrenterca,
                                 vsbonific);
    ELSE
      vnlanc := 0; --(recebimentos em trocas)
    END IF;

    RETURN vnlanc;
  END; --ccrca_retornar_saldo_item_pedido

  --RNG07 / PARA ALTERACAO DE PRECO
  FUNCTION ccrca_retorna_saldo_anterior( -- 09 parametros
                                        p_numped   IN pcpedc.numped%TYPE,
                                        p_codusur  IN pcpedc.codusur%TYPE,
                                        p_codprod  IN pcpedi.codprod%TYPE,
                                        p_numseq   IN pcpedi.numseq%TYPE,
                                        p_qt       IN pcpedi.qt%TYPE,
                                        p_pvenda   IN pcpedi.pvenda%TYPE,
                                        p_pbaserca IN pcpedi.pbaserca%TYPE,
                                        p_ptabela  IN pcpedi.ptabela%TYPE,
                                        p_tipo     IN VARCHAR
                                        -- Sabrina: tipo de operação I - Inclusao e E - Exclusao
                                        ) RETURN NUMBER IS
    vsusacredrca                pcpedc.usacredrca%TYPE;
    vsbonificaltdebcredrca      pcpedc.bonificaltdebcredrca%TYPE;
    vstrocaaltdebcredrca        pcpedc.trocaaltdebcredrca%TYPE;
    vsbrokeraltdebcredrca       pcpedc.brokeraltdebcredrca%TYPE;
    vscrmaltdebcredrca          pcpedc.crmaltdebcredrca%TYPE;
    vstipomovccrca              pcpedc.tipomovccrca%TYPE;
    vsusadebcredrca             pcpedc.usadebcredrca%TYPE;
    vsorigemped                 pcpedc.origemped%TYPE;
    vsbrinde                    pcpedc.brinde%TYPE;
    vncondvenda                 pcpedc.condvenda%TYPE;
    vsbroker                    pcpedc.broker%TYPE;
    vnlanc                      NUMBER;
    vsmsg                       VARCHAR2(400);
    vsusadebcredrcabrind        pcpedi.usadebcredrcabrind%type;
    vsmovimentacontacorrenterca pcpedi.movimentacontacorrenterca%type;
    vstipocontacorrente pcpedc.tipocontacorrente%TYPE;
  BEGIN
    proc_lerparametros(vsmsg);

    SELECT p.usacredrca,
           p.bonificaltdebcredrca,
           p.trocaaltdebcredrca,
           p.brokeraltdebcredrca,
           p.crmaltdebcredrca,
           p.tipomovccrca,
           p.usadebcredrca,
/*           DECODE(p.usadebcredrca,
                  NULL,
                  (SELECT NVL(pcusuari.usadebcredrca, gregpcconsum.usacredrca)
                     FROM pcusuari
                    WHERE codusur = p.codusur
                      AND ROWNUM = 1),
                  p.usadebcredrca),*/
           p.origemped,
           NVL(p.brinde, 'N'),
           p.condvenda,
           NVL(p.broker, 'N'),
           i.usadebcredrcabrind,
           nvl(i.movimentacontacorrenterca, 'S'),
           nvl(p.tipocontacorrente, 'R')
      INTO vsusacredrca,
           vsbonificaltdebcredrca,
           vstrocaaltdebcredrca,
           vsbrokeraltdebcredrca,
           vscrmaltdebcredrca,
           vstipomovccrca,
           vsusadebcredrca,
           vsorigemped,
           vsbrinde,
           vncondvenda,
           vsbroker,
           vsusadebcredrcabrind,
           vsmovimentacontacorrenterca,
           vstipocontacorrente
      FROM pcpedc p, pcpedi i
     WHERE p.numped = p_numped
       and p.numped = i.numped;

    IF vsusadebcredrca IS NULL THEN
    SELECT CASE WHEN vstipocontacorrente = 'S' 
                    THEN NVL(PCSUPERV.USADEBCRED,gregpcconsum.usacredsupervisor)
                    WHEN vstipocontacorrente = 'G' 
                    THEN NVL(PCGERENTE.USADEBCRED,gregpcconsum.usacredgerente)                
                    ELSE NVL(PCUSUARI.USADEBCREDRCA,gregpcconsum.usacredrca)
           END  USADEBCRED
      INTO vsusadebcredrca
      FROM PCPEDC
     INNER JOIN PCUSUARI ON (PCUSUARI.CODUSUR       = PCPEDC.CODUSUR)
     INNER JOIN PCSUPERV ON (PCSUPERV.CODSUPERVISOR = NVL(PCPEDC.CODSUPERVISOR, PCUSUARI.CODSUPERVISOR))
      LEFT JOIN PCGERENTE ON (PCGERENTE.CODGERENTE   = NVL(PCPEDC.CODGERENTE, PCSUPERV.CODGERENTE))
     WHERE PCPEDC.NUMPED = p_numped;    
    END IF; 
    
    IF p_qt > 0 THEN
      vnlanc := ccrca_saldo_item(NVL(vsusacredrca, gregpcconsum.usacredrca),
                                 vsusadebcredrca,
                                 vsbroker,
                                 vsorigemped,
                                 NVL(vsbonificaltdebcredrca,
                                     gregpcconsum.bonificaltdebcredrca),
                                 NVL(vstrocaaltdebcredrca,
                                     gregpcconsum.trocaaltdebcredrca),
                                 NVL(vscrmaltdebcredrca,
                                     gregpcconsum.crmaltdebcredrca),
                                 NVL(vsbrokeraltdebcredrca,
                                     gregpcconsum.brokeraltdebcredrca),
                                 NVL(vstipomovccrca,
                                     NVL(gregpcconsum.tipomovccrca, 'VV')),
                                 vncondvenda,
                                 vsbrinde,
                                 p_codusur,
                                 'V',
                                 p_pvenda,
                                 p_ptabela,
                                 NVL(p_pbaserca, p_ptabela),
                                 p_qt,
                                 vsusadebcredrcabrind,
                                 vsmovimentacontacorrenterca);
    ELSE
      vnlanc := 0; --(recebimentos em trocas)
    END IF;

    RETURN vnlanc;
  END; --ccrca_retornar_saldo_anterior

  --RNG07 / PARA ALTERACAO DE PRECO
  FUNCTION ccrca_retorna_saldo_anterior( -- 10 parametros
                                        p_numped             IN pcpedc.numped%TYPE,
                                        p_codusur            IN pcpedc.codusur%TYPE,
                                        p_codprod            IN pcpedi.codprod%TYPE,
                                        p_numseq             IN pcpedi.numseq%TYPE,
                                        p_qt                 IN pcpedi.qt%TYPE,
                                        p_pvenda             IN pcpedi.pvenda%TYPE,
                                        p_pbaserca           IN pcpedi.pbaserca%TYPE,
                                        p_ptabela            IN pcpedi.ptabela%TYPE,
                                        p_tipo               IN VARCHAR,
                                        p_usadebcredrcabrind IN pcpedi.usadebcredrcabrind%TYPE
                                        -- Sabrina: tipo de operação I - Inclusao e E - Exclusao
                                        ) RETURN NUMBER IS
    vsusacredrca           pcpedc.usacredrca%TYPE;
    vsbonificaltdebcredrca pcpedc.bonificaltdebcredrca%TYPE;
    vstrocaaltdebcredrca   pcpedc.trocaaltdebcredrca%TYPE;
    vsbrokeraltdebcredrca  pcpedc.brokeraltdebcredrca%TYPE;
    vscrmaltdebcredrca     pcpedc.crmaltdebcredrca%TYPE;
    vstipomovccrca         pcpedc.tipomovccrca%TYPE;
    vsusadebcredrca        pcpedc.usadebcredrca%TYPE;
    vsorigemped            pcpedc.origemped%TYPE;
    vsbrinde               pcpedc.brinde%TYPE;
    vncondvenda            pcpedc.condvenda%TYPE;
    vsbroker               pcpedc.broker%TYPE;
    vnlanc                 NUMBER;
    vsmsg                  VARCHAR2(400);
    vstipocontacorrente pcpedc.tipocontacorrente%TYPE;
  BEGIN
    proc_lerparametros(vsmsg);

    SELECT p.usacredrca,
           p.bonificaltdebcredrca,
           p.trocaaltdebcredrca,
           p.brokeraltdebcredrca,
           p.crmaltdebcredrca,
           p.tipomovccrca,
           p.usadebcredrca,
/*           DECODE(p.usadebcredrca,
                  NULL,
                  (SELECT NVL(pcusuari.usadebcredrca, gregpcconsum.usacredrca)
                     FROM pcusuari
                    WHERE codusur = p.codusur
                      AND ROWNUM = 1),
                  p.usadebcredrca),*/
           p.origemped,
           NVL(p.brinde, 'N'),
           p.condvenda,
           NVL(p.broker, 'N'),
           nvl(p.tipocontacorrente, 'R')
      INTO vsusacredrca,
           vsbonificaltdebcredrca,
           vstrocaaltdebcredrca,
           vsbrokeraltdebcredrca,
           vscrmaltdebcredrca,
           vstipomovccrca,
           vsusadebcredrca,
           vsorigemped,
           vsbrinde,
           vncondvenda,
           vsbroker,
           vstipocontacorrente
      FROM pcpedc p
     WHERE p.numped = p_numped;

     IF vsusadebcredrca IS NULL THEN
        SELECT CASE WHEN vstipocontacorrente = 'S' 
                    THEN NVL(PCSUPERV.USADEBCRED,gregpcconsum.usacredsupervisor)
                    WHEN vstipocontacorrente = 'G' 
                    THEN NVL(PCGERENTE.USADEBCRED,gregpcconsum.usacredgerente)                
                    ELSE NVL(PCUSUARI.USADEBCREDRCA,gregpcconsum.usacredrca)
                END USADEBCRED
          INTO vsusadebcredrca
          FROM PCPEDC
         INNER JOIN PCUSUARI ON (PCUSUARI.CODUSUR       = PCPEDC.CODUSUR)
         INNER JOIN PCSUPERV ON (PCSUPERV.CODSUPERVISOR = NVL(PCPEDC.CODSUPERVISOR, PCUSUARI.CODSUPERVISOR))
          LEFT JOIN PCGERENTE ON (PCGERENTE.CODGERENTE   = NVL(PCPEDC.CODGERENTE, PCSUPERV.CODGERENTE))
         WHERE PCPEDC.NUMPED = p_numped;    
     END IF;

    IF p_qt > 0 THEN
      vnlanc := ccrca_saldo_item(NVL(vsusacredrca, gregpcconsum.usacredrca),
                                 vsusadebcredrca,
                                 vsbroker,
                                 vsorigemped,
                                 NVL(vsbonificaltdebcredrca,
                                     gregpcconsum.bonificaltdebcredrca),
                                 NVL(vstrocaaltdebcredrca,
                                     gregpcconsum.trocaaltdebcredrca),
                                 NVL(vscrmaltdebcredrca,
                                     gregpcconsum.crmaltdebcredrca),
                                 NVL(vsbrokeraltdebcredrca,
                                     gregpcconsum.brokeraltdebcredrca),
                                 NVL(vstipomovccrca,
                                     NVL(gregpcconsum.tipomovccrca, 'VV')),
                                 vncondvenda,
                                 vsbrinde,
                                 p_codusur,
                                 'V',
                                 p_pvenda,
                                 p_ptabela,
                                 NVL(p_pbaserca, p_ptabela),
                                 p_qt,
                                 p_usadebcredrcabrind);
    ELSE
      vnlanc := 0; --(recebimentos em trocas)
    END IF;

    RETURN vnlanc;
  END; --ccrca_retornar_saldo_anterior

  --RNG08
  FUNCTION ccrca_estorna_item_pedido(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                     p_rotinalanc  IN pclogrca.rotina%TYPE,
                                     p_codusur     IN pcpedc.codusur%TYPE,
                                     p_numped      IN pcpedc.numped%TYPE,
                                     p_codprod     IN pcpedi.codprod%TYPE,
                                     p_numseq      IN pcpedi.numseq%TYPE,
                                     p_qt          IN pcpedi.qt%TYPE)
    RETURN BOOLEAN IS
    vnvalorlanc        NUMBER;
    vnvlcorrente_ant   pcgerente.vlcorrente%TYPE;
    vsusadebcredrca    pcusuari.usadebcredrca%TYPE;
    vnvllimcred        pcgerente.vllimcred%TYPE;
    vnvlcorrente_atual pcgerente.vlcorrente%TYPE;
    vddata             pcpedc.DATA%TYPE;
    vnnumtransvenda    pcpedc.numtransvenda%TYPE;
    vsposicao          pcpedc.posicao%TYPE;
    vbvalido           BOOLEAN;
    vstipocontacorrente pcpedc.tipocontacorrente%TYPE;
    vnCodigoGerente     pcgerente.codgerente%TYPE;
    vnCodigoSupervisor  pcsuperv.codsupervisor%TYPE;
  BEGIN
    vbvalido := TRUE;

    -- Verifica se pode movimentar conta corrente do RCA
    if (CONTROLASALDORCA(p_numped) = 'N') then
      return(FALSE);
    end if;

    SELECT pcpedc.DATA, pcpedc.numtransvenda, pcpedc.posicao, nvl(pcpedc.tipocontacorrente, 'R')
      INTO vddata, vnnumtransvenda, vsposicao, vstipocontacorrente
      FROM pcpedc
     WHERE numped = p_numped;

    ccrca_bloquear_registro_rca(p_codusur);

  --VEN-2604 - Inicio
    SELECT CASE WHEN vstipocontacorrente = 'S'
                THEN NVL(PCSUPERV.USADEBCRED,'S')
                WHEN vstipocontacorrente = 'G'
                THEN NVL(PCGERENTE.USADEBCRED,'S')
                ELSE NVL(PCUSUARI.USADEBCREDRCA,'S')
           END USADEBCRED
         , CASE WHEN vstipocontacorrente = 'S'
                THEN NVL(PCSUPERV.VLCORRENTE,0)
                WHEN vstipocontacorrente = 'G'
                THEN NVL(PCGERENTE.VLCORRENTE,0)
                ELSE NVL(PCUSUARI.VLCORRENTE,0)
           END VLCORRENTE
         , CASE WHEN vstipocontacorrente = 'S'
                THEN NVL(PCSUPERV.VLLIMCRED,0)
                WHEN vstipocontacorrente = 'G'
                THEN NVL(PCGERENTE.VLLIMCRED,0)
                ELSE NVL(PCUSUARI.VLLIMCRED,0)
           END VLLIMCRED
         , PCSUPERV.CODSUPERVISOR
         , PCGERENTE.CODGERENTE
      INTO vsusadebcredrca
         , vnvlcorrente_ant
         , vnvllimcred
         , vnCodigoSupervisor
         , vnCodigoGerente
      FROM PCPEDC
     INNER JOIN PCUSUARI ON (PCUSUARI.CODUSUR       = PCPEDC.CODUSUR)
     INNER JOIN PCSUPERV ON (PCSUPERV.CODSUPERVISOR = NVL(PCPEDC.CODSUPERVISOR, PCUSUARI.CODSUPERVISOR))
      LEFT JOIN PCGERENTE ON (PCGERENTE.CODGERENTE   = NVL(PCPEDC.CODGERENTE, PCSUPERV.CODGERENTE))
     WHERE PCPEDC.NUMPED = p_numped;

  --VEN-2604 - Fim

    vnvalorlanc := ccrca_retorna_saldo_itempedido(p_numped,
                                                  p_codusur,
                                                  p_codprod,
                                                  p_numseq,
                                                  p_qt,
                                                  'E');
    -- incluído por sabrina ( E - Estorno)
    vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) - NVL(vnvalorlanc, 0);

    -- a package não deve barrar a movimentacao do saldo, os programas eh que fazem isso
    --IF vnvlcorrente_atual >= 0 THEN
    if vstipocontacorrente = 'G' then
      UPDATE pcgerente
         SET vlcorrente = vnvlcorrente_atual
       WHERE codgerente = vnCodigoGerente;
    ELSIF vstipocontacorrente = 'S' then
      UPDATE pcsuperv
         SET vlcorrente = vnvlcorrente_atual
       WHERE codsupervisor = vnCodigoSupervisor;
    else
      UPDATE pcusuari
         SET vlcorrente = vnvlcorrente_atual
       WHERE codusur = p_codusur;
    end if;

      INSERT INTO pclogdebcred
        (numped,
         posicao,
         numtransvenda,
         tipocontacorrente,
         DATA,
         codfunc,
         codigo,
         rotina,
         vlcorrente,
         vllimcred,
         vlcorrenteant,
         vllimcredant,
         codprod,
         numseq,
         historico)
      VALUES
        (p_numped,
         vsposicao,
         vnnumtransvenda,
         vstipocontacorrente,
         SYSDATE,
         p_codfunclanc,
         decode(vstipocontacorrente, 'S', vnCodigoSupervisor, 'G', vnCodigoGerente, p_codusur),
         p_rotinalanc,
         vnvlcorrente_atual,
         vnvllimcred,
         vnvlcorrente_ant,
         vnvllimcred,
         p_codprod,
         p_numseq,
         SUBSTR('CTRLCCRCA: ESTORNO DE SALDO DE ITEM PEDIDO', 1, 60));

    if (vstipocontacorrente <> 'S') and (vstipocontacorrente <> 'G') then
      INSERT INTO pclogrca
       (numped,
         posicao,
         numtransvenda,
         DATA,
         codfunc,
         codusur,
         rotina,
         vlcorrente,
         vllimcred,
         vlcorrenteant,
         vllimcredant,
         codprod,
         numseq,
         historico,
         seqlogrca)
    VALUES
        (p_numped,
         vsposicao,
         vnnumtransvenda,
         SYSDATE,
         p_codfunclanc,
         p_codusur,
         p_rotinalanc,
         vnvlcorrente_atual,
         vnvllimcred,
         vnvlcorrente_ant,
         vnvllimcred,
         p_codprod,
         p_numseq,
         SUBSTR('CTRLCCRCA: ESTORNO DE SALDO DE ITEM PEDIDO', 1, 60),
		 DFSEQ_PCLOGRCA.NEXTVAL);
     end if;
    --ELSE
    -- vbvalido := FALSE;
    --END IF;
    RETURN(vbvalido);
    EXCEPTION
    WHEN OTHERS THEN
       --ROLLBACK;
       RETURN(FALSE);
  END; --ccrca_estorna_item_pedido

  --RNG09
  FUNCTION ccrca_incluir_item_pedido(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                     p_rotinalanc  IN pclogrca.rotina%TYPE,
                                     p_codusur     IN pcpedc.codusur%TYPE,
                                     p_numped      IN pcpedc.numped%TYPE,
                                     p_codprod     IN pcpedi.codprod%TYPE,
                                     p_numseq      IN pcpedi.numseq%TYPE)
    RETURN BOOLEAN IS
    vnvalorlanc        NUMBER;
    vnvlcorrente_ant   PCGERENTE.vlcorrente%TYPE;
    vsusadebcredrca    pcusuari.usadebcredrca%TYPE;
    vnvllimcred        PCGERENTE.vllimcred%TYPE;
    vnvlcorrente_atual PCGERENTE.vlcorrente%TYPE;
    vddata             pcpedc.DATA%TYPE;
    vnnumtransvenda    pcpedc.numtransvenda%TYPE;
    vsposicao          pcpedc.posicao%TYPE;
    vnqt               pcpedi.qt%TYPE;
    vstipocontacorrente pcpedc.tipocontacorrente%TYPE;
    vnCodigoGerente     pcgerente.codgerente%TYPE;
    vnCodigoSupervisor  pcsuperv.codsupervisor%TYPE;
    vbvalido           BOOLEAN;
    vnCODUSUR          NUMBER;
  BEGIN
    vbvalido := TRUE;

    -- Verifica se pode movimentar conta corrente do RCA
    if (CONTROLASALDORCA(p_numped) = 'N') then
      return(FALSE);
    end if;

    SELECT pcpedc.DATA, CODUSUR, pcpedc.numtransvenda, pcpedc.posicao, nvl(pcpedc.tipocontacorrente, 'R')
      INTO vddata, vnCODUSUR, vnnumtransvenda, vsposicao, vstipocontacorrente
      FROM pcpedc
     WHERE numped = p_numped;

    SELECT qt
      INTO vnqt
      FROM pcpedi
     WHERE numped = p_numped
       AND codprod = p_codprod
       AND numseq = p_numseq;

    ccrca_bloquear_registro_rca(p_codusur);

  --VEN-2604 - Inicio
    SELECT CASE WHEN vstipocontacorrente = 'S'
                THEN NVL(PCSUPERV.USADEBCRED,'S')
                WHEN vstipocontacorrente = 'G'
                THEN NVL(PCGERENTE.USADEBCRED,'S')
                ELSE NVL(PCUSUARI.USADEBCREDRCA,'S')
           END USADEBCRED
         , CASE WHEN vstipocontacorrente = 'S'
                THEN NVL(PCSUPERV.VLCORRENTE,0)
                WHEN vstipocontacorrente = 'G'
                THEN NVL(PCGERENTE.VLCORRENTE,0)
                ELSE NVL(PCUSUARI.VLCORRENTE,0)
           END VLCORRENTE
         , CASE WHEN vstipocontacorrente = 'S'
                THEN NVL(PCSUPERV.VLLIMCRED,0)
                WHEN vstipocontacorrente = 'G'
                THEN NVL(PCGERENTE.VLLIMCRED,0)
                ELSE NVL(PCUSUARI.VLLIMCRED,0)
           END VLLIMCRED
         , PCSUPERV.CODSUPERVISOR
         , PCGERENTE.CODGERENTE
      INTO vsusadebcredrca
         , vnvlcorrente_ant
         , vnvllimcred
         , vnCodigoSupervisor
         , vnCodigoGerente
      FROM PCPEDC
     INNER JOIN PCUSUARI ON (PCUSUARI.CODUSUR       = PCPEDC.CODUSUR)
     INNER JOIN PCSUPERV ON (PCSUPERV.CODSUPERVISOR = NVL(PCPEDC.CODSUPERVISOR, PCUSUARI.CODSUPERVISOR))
      LEFT JOIN PCGERENTE ON (PCGERENTE.CODGERENTE  = NVL(PCPEDC.CODGERENTE, PCSUPERV.CODGERENTE))
     WHERE PCPEDC.NUMPED = p_numped;


  --VEN-2604 - Fim

    vnvalorlanc := ccrca_retorna_saldo_itempedido(p_numped,
                                                  p_codusur,
                                                  p_codprod,
                                                  p_numseq,
                                                  vnqt,
                                                  'I');
    --incluído por Sabrina (I - Inclusao)
    vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) + NVL(vnvalorlanc, 0);

    -- a package não deve barrar a movimentacao do saldo, os programas eh que fazem isso
    -- IF vnvlcorrente_atual >= 0 THEN

    if vstipocontacorrente = 'G' then
      UPDATE pcgerente
         SET vlcorrente = vnvlcorrente_atual
       WHERE codgerente = vnCodigoGerente;
    ELSIF vstipocontacorrente = 'S' then
      UPDATE pcsuperv
         SET vlcorrente = vnvlcorrente_atual
       WHERE codsupervisor = vnCodigoSupervisor;
    else
      UPDATE pcusuari
         SET vlcorrente = vnvlcorrente_atual
       WHERE codusur = p_codusur;
    end if;

      INSERT INTO pclogdebcred
        (numped,
         posicao,
         numtransvenda,
         tipocontacorrente,
         DATA,
         codfunc,
         codigo,
         rotina,
         vlcorrente,
         vllimcred,
         vlcorrenteant,
         vllimcredant,
         codprod,
         numseq,
         historico)
      VALUES
        (p_numped,
         vsposicao,
         vnnumtransvenda,
         vstipocontacorrente,
         SYSDATE,
         p_codfunclanc,
         decode(vstipocontacorrente, 'S', vnCodigoSupervisor, 'G', vnCodigoGerente, p_codusur),
         p_rotinalanc,
         vnvlcorrente_atual,
         vnvllimcred,
         vnvlcorrente_ant,
         vnvllimcred,
         p_codprod,
         p_numseq,
         SUBSTR('CTRLCCRCA:LANCAMENTO SALDO ITEM PEDIDO', 1, 60));

    if (vstipocontacorrente <> 'S') and (vstipocontacorrente <> 'G') then
      INSERT INTO pclogrca
        (numped,
         posicao,
         numtransvenda,
         DATA,
         codfunc,
         codusur,
         rotina,
         vlcorrente,
         vllimcred,
         vlcorrenteant,
         vllimcredant,
         codprod,
         numseq,
         historico,
         seqlogrca)
      VALUES
        (p_numped,
         vsposicao,
         vnnumtransvenda,
         SYSDATE,
         p_codfunclanc,
         p_codusur,
         p_rotinalanc,
         vnvlcorrente_atual,
         vnvllimcred,
         vnvlcorrente_ant,
         vnvllimcred,
         p_codprod,
         p_numseq,
         SUBSTR('CTRLCCRCA:LANCAMENTO SALDO ITEM PEDIDO', 1, 60),
         DFSEQ_PCLOGRCA.NEXTVAL);
      end if;

    --ELSE
    --vbvalido := FALSE;
    --END IF;
    RETURN(vbvalido);
    EXCEPTION
    WHEN OTHERS THEN
       --ROLLBACK;
       vrPARAMETROS.Data := sysdate;
       vrPARAMETROS.Rotina := p_rotinalanc;
       vrPARAMETROS.Historico := SQLCODE || '-' || SQLERRM || CHR(13) || 'ERRO AO GRAVAR SALDO RCA (ccrca_incluir_item_pedido)';
       vrPARAMETROS.Numped := p_numped;
       vrPARAMETROS.Codprod := p_codprod;
       GravarLog(vrPARAMETROS);
       RETURN(FALSE);
  END; -- ccrca_incluir_item_pedido

  --Projeto 90992 RBD4
  -- inclui itens ou todo pedido
  FUNCTION ccfinrca_incluir_item_pedido(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                        p_rotinalanc  IN pclogrca.rotina%TYPE,
                                        p_codusur     IN pcpedc.codusur%TYPE,
                                        p_numped      IN pcpedc.numped%TYPE,
                                        p_codprod     IN pcpedi.codprod%TYPE,
                                        p_numseq      IN pcpedi.numseq%TYPE,
                                        p_mensagem    OUT VARCHAR2)
    RETURN BOOLEAN IS
    vsusasaldocontacorrentedescfin pcpedc.usasaldocontacorrentedescfin%TYPE;
    vsatualizasaldoccdescfin       pcclient.atualizasaldoccdescfin%TYPE;
    vscodfilial                    pcpedc.codfilial%TYPE;
    vnperdescfin                   pcpedc.perdescfin%TYPE;
    vncondvenda                    pcpedc.condvenda%TYPE;
    vncodusur                      pcpedc.codusur%TYPE;
    vstipomovccrca                 pcpedc.tipomovccrca%TYPE;
    vsgravarvalordescfin           VARCHAR2(1);
    vnvlsaldo                      NUMBER;
    vnvltotalitens                 NUMBER;
    vnvalordescfin                 NUMBER;
    vbvalido                       BOOLEAN;
    vsmensagem                     VARCHAR2(300);
    vicontador                     NUMBER;
  BEGIN
    vsmensagem := 'OK';
    proc_lerparametros(vsmensagem);

    SELECT p.usasaldocontacorrentedescfin,
           pcclient.atualizasaldoccdescfin,
           p.codfilial,
           p.perdescfin,
           p.condvenda,
           p.codusur,
           p.tipomovccrca,
           NVL((SELECT NVL(valor, 'N')
                 FROM pcparamfilial
                WHERE pcparamfilial.codfilial = p.codfilial
                  AND pcparamfilial.nome = 'GRAVARVALORDESCFIN'),
               'N')
      INTO vsusasaldocontacorrentedescfin,
           vsatualizasaldoccdescfin,
           vscodfilial,
           vnperdescfin,
           vncondvenda,
           vncodusur,
           vstipomovccrca,
           vsgravarvalordescfin
      FROM pcpedc p, pcclient
     WHERE p.numped = p_numped
       AND p.codcli = pcclient.codcli;

    -- Tarefa 102070 (Caso o valor do Desc. seja fixo por valor não será alterado com o novo item inserido)
    IF (vsgravarvalordescfin = 'S') AND (p_codprod IS NOT NULL) AND
       (p_numseq IS NOT NULL) THEN
      vnperdescfin := 0;
    END IF;
    -- Fim tarefa 102070

    -- Tarefa 99976
    IF (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       (NVL(vsusasaldocontacorrentedescfin, 'N') = 'S') THEN
      vbvalido := TRUE;
    END IF;
    -- Fim tarefa 99976

    IF gregpcconsum.usasaldocontacorrentedescfin = 'S' AND
       NVL(vsatualizasaldoccdescfin, 'N') = 'N' THEN
      vnvlsaldo := ccfinrca_saldorcamenosdescfin(p_codusur, vscodfilial);

      SELECT (SUM(pcpedi.pvenda * pcpedi.qt))
        INTO vnvltotalitens
        FROM pcpedi
       WHERE pcpedi.numped = p_numped
         AND pcpedi.qt > 0
         AND codprod = NVL(p_codprod, codprod)
         AND numseq = NVL(p_numseq, numseq);

      vnvalordescfin := (NVL(vnvltotalitens, 0)) *
                        (NVL(vnperdescfin, 0) / 100);

      IF NVL(vnvlsaldo, 0) < NVL(vnvalordescfin, 0) THEN
        vbvalido   := FALSE;
        vsmensagem := 'RCA sem saldo para liberar pedido com desconto financeiro';
      ELSE
        IF NOT (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
           ((NVL(vsusasaldocontacorrentedescfin, 'N')) = 'S') AND
           (NVL(vstipomovccrca, 'VV') NOT IN ('FF', 'VV')) THEN
          --RBD11
          SELECT COUNT(*)
            INTO vicontador
            FROM pcsaldorca
           WHERE codusur = vncodusur;

          IF vicontador = 0 THEN
            INSERT INTO pcsaldorca
              (codusur, vlsaldo, vlsaldoant)
            VALUES
              (vncodusur, 0, 0);
          END IF;

          IF NVL(vnperdescfin, 0) > 0 THEN
            SELECT NVL(vlsaldo, 0)
              INTO vnvlsaldo
              FROM pcsaldorca
             WHERE codusur = vncodusur
               FOR UPDATE;

            IF (vnvalordescfin) > 0 THEN
              vnvalordescfin := vnvalordescfin * (-1);
            END IF;

            INSERT INTO pcmovsaldorca
              (DATA,
               codfunc,
               codusur,
               rotina,
               tipo,
               valor,
               vlsaldoant,
               vlsaldo,
               historico,
               numped)
            VALUES
              (SYSDATE,
               p_codfunclanc,
               vncodusur,
               p_rotinalanc,
               'D',
               vnvalordescfin,
               vnvlsaldo,
               (vnvlsaldo + (vnvalordescfin)),
               'PEDIDO DE VENDA',
               p_numped);

            UPDATE pcsaldorca
               SET vlsaldoant = vnvlsaldo,
                   vlsaldo    = (vnvlsaldo + (vnvalordescfin))
             WHERE codusur = vncodusur;

            vbvalido := TRUE;
          ELSE
            vbvalido := TRUE;
          END IF;
        END IF;
      END IF;
    ELSE
      vbvalido := TRUE;
    END IF;

    p_mensagem := vsmensagem;
    RETURN(vbvalido);
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao incluir item pedido : ' || SQLCODE || '-' ||
                    SQLERRM;
      vrPARAMETROS.Data := sysdate;
      vrPARAMETROS.Rotina := p_rotinalanc;
      vrPARAMETROS.Historico := SQLCODE || '-' || SQLERRM || CHR(13) || 'ERRO AO GRAVAR SALDO RCA (ccfinrca_incluir_item_pedido)';
      vrPARAMETROS.Numped := p_numped;
      vrPARAMETROS.Codprod := p_codprod;
      GravarLog(vrPARAMETROS);
      RETURN FALSE;
  END; --ccfinrca_incluir_item_pedido

  --Projeto 90992 RBD7
  --Cancela itens ou todo o pedido
  FUNCTION ccfinrca_excluir_item_pedido(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                        p_rotinalanc  IN pclogrca.rotina%TYPE,
                                        p_codusur     IN pcpedc.codusur%TYPE,
                                        p_numped      IN pcpedc.numped%TYPE,
                                        p_codprod     IN pcpedi.codprod%TYPE,
                                        p_numseq      IN pcpedi.numseq%TYPE,
                                        p_qtnova      IN pcpedi.qt%TYPE,
                                        --caso seja alteração de preço, enviar qt novo
                                        p_preconovo IN pcpedi.pvenda%TYPE,
                                        --caso seja alteração de quantidade, enviar pvenda novo
                                        p_mensagem OUT VARCHAR2)
    RETURN BOOLEAN IS
    vnperdescfin                   pcpedc.perdescfin%TYPE;
    vnqtanterior                   pcpedi.qt%TYPE;
    vnpvendaanterior               pcpedi.pvenda%TYPE;
    vncondvenda                    pcpedc.condvenda%TYPE;
    vsusasaldocontacorrentedescfin pcpedc.usasaldocontacorrentedescfin%TYPE;
    vstipomovccrca                 pcpedc.tipomovccrca%TYPE;
    vncodusur                      pcpedc.codusur%TYPE;
    vsgravarvalordescfin           VARCHAR2(1);
    vicontador                     NUMBER;
    vnvlsaldo                      NUMBER;
    vnvltotalitens                 NUMBER;
    vnvalorcredito                 NUMBER;
    vbvalido                       BOOLEAN;
    vsmensagem                     VARCHAR2(300);
  BEGIN
    vbvalido   := FALSE;
    vsmensagem := 'OK';

    SELECT pcpedc.perdescfin,
           pcpedc.condvenda,
           pcpedc.usasaldocontacorrentedescfin,
           pcpedc.tipomovccrca,
           pcpedc.codusur,
           NVL((SELECT NVL(valor, 'N')
                 FROM pcparamfilial
                WHERE pcparamfilial.codfilial = pcpedc.codfilial
                  AND pcparamfilial.nome = 'GRAVARVALORDESCFIN'),
               'N')
      INTO vnperdescfin,
           vncondvenda,
           vsusasaldocontacorrentedescfin,
           vstipomovccrca,
           vncodusur,
           vsgravarvalordescfin
      FROM pcpedc
     WHERE pcpedc.numped = p_numped;

    -- Tarefa 102070 (Caso o valor do Desc. seja fixo por valor, não será alterado com o novo item excluído)
    IF (vsgravarvalordescfin = 'S') AND (p_codprod IS NOT NULL) -- Tarefa 105173
     THEN
      vnperdescfin := 0;
    END IF;
    -- Fim tarefa 102070

    -- Tarefa 99976
    IF (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       (NVL(vsusasaldocontacorrentedescfin, 'N') = 'S') THEN
      vbvalido := TRUE;
    END IF;
    -- Fim tarefa 99976

    IF NOT (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       ((NVL(vsusasaldocontacorrentedescfin, 'N')) = 'S') AND
       (NVL(vstipomovccrca, 'VV') NOT IN ('FF', 'VV')) THEN
      SELECT COUNT(*)
        INTO vicontador
        FROM pcsaldorca
       WHERE codusur = vncodusur;

      IF vicontador = 0 THEN
        INSERT INTO pcsaldorca
          (codusur, vlsaldo, vlsaldoant)
        VALUES
          (vncodusur, 0, 0);
      END IF;

      IF NVL(vnperdescfin, 0) > 0 THEN
        SELECT NVL(vlsaldo, 0)
          INTO vnvlsaldo
          FROM pcsaldorca
         WHERE codusur = vncodusur
           FOR UPDATE;

        --cancelamento de todo o pedido
        IF p_codprod IS NULL THEN
          SELECT SUM(pcpedi.pvenda * pcpedi.qt)
            INTO vnvltotalitens
            FROM pcpedi
           WHERE pcpedi.numped = p_numped
             AND pcpedi.qt > 0;
        ELSE
          SELECT pcpedi.qt, pcpedi.pvenda
            INTO vnqtanterior, vnpvendaanterior
            FROM pcpedi
           WHERE pcpedi.numped = p_numped
             AND pcpedi.codprod = p_codprod
             AND pcpedi.numseq = NVL(p_numseq, pcpedi.numseq);

          -- cancelamento ou alteração de item
          IF vnqtanterior <> p_qtnova THEN
            SELECT (pcpedi.pvenda * (vnqtanterior - p_qtnova))
              INTO vnvltotalitens
              FROM pcpedi
             WHERE pcpedi.numped = p_numped
               AND pcpedi.codprod = p_codprod
               AND pcpedi.numseq = p_numseq
               AND pcpedi.qt > 0;
          END IF;

          IF vnpvendaanterior <> p_preconovo THEN
            SELECT (pcpedi.qt * (vnpvendaanterior - p_preconovo))
              INTO vnvltotalitens
              FROM pcpedi
             WHERE pcpedi.numped = p_numped
               AND pcpedi.codprod = p_codprod
               AND pcpedi.numseq = p_numseq
               AND pcpedi.qt > 0;
          END IF;
        END IF;

        vnvalorcredito := (vnvltotalitens) * (vnperdescfin / 100);

        INSERT INTO pcmovsaldorca
          (DATA,
           codfunc,
           codusur,
           rotina,
           tipo,
           valor,
           vlsaldoant,
           vlsaldo,
           historico,
           numped)
        VALUES
          (SYSDATE,
           p_codfunclanc,
           vncodusur,
           p_rotinalanc,
           'C',
           vnvalorcredito,
           vnvlsaldo,
           (vnvlsaldo + vnvalorcredito),
           'PEDIDO DE VENDA',
           p_numped);

        UPDATE pcsaldorca
           SET vlsaldoant = vnvlsaldo,
               vlsaldo    = (vnvlsaldo + vnvalorcredito)
         WHERE codusur = vncodusur;

        vbvalido := TRUE;
      END IF;
    END IF;

    p_mensagem := vsmensagem;
    RETURN(vbvalido);
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao excluir item pedido : ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END; --ccfinrca_excluir_item_pedido

  --Projeto 90992 RBD4
  FUNCTION ccfinrca_alterar_preco_qt(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                     p_rotinalanc  IN pclogrca.rotina%TYPE,
                                     p_codusur     IN pcpedc.codusur%TYPE,
                                     p_numped      IN pcpedc.numped%TYPE,
                                     p_codprod     IN pcpedi.codprod%TYPE,
                                     p_numseq      IN pcpedi.numseq%TYPE,
                                     p_qtnova      IN pcpedi.qt%TYPE,
                                     --caso seja alteração de preço, enviar qt atual
                                     p_pvendanovo IN pcpedi.pvenda%TYPE,
                                     --caso seja alteração de quantidade, enviar o pvenda atual
                                     p_mensagem OUT VARCHAR2) RETURN BOOLEAN IS
    vnqtatual                      pcpedi.qt%TYPE;
    vnpvendaatual                  pcpedi.pvenda%TYPE;
    vscodfilial                    pcpedc.codfilial%TYPE;
    vncodusur                      pcpedc.codusur%TYPE;
    vnperdescfin                   pcpedc.perdescfin%TYPE;
    vsgravarvalordescfin           VARCHAR2(1);
    vnvlsaldorca                   NUMBER;
    vnvltotalitens                 NUMBER;
    vnvalordescfin                 NUMBER;
    vbvalido                       BOOLEAN;
    vsmensagem                     VARCHAR2(300);
    vncondvenda                    pcpedc.condvenda%TYPE;
    vsusasaldocontacorrentedescfin pcpedc.usasaldocontacorrentedescfin%TYPE;
    vstipomovccrca                 pcpedc.tipomovccrca%TYPE;
    vicontador                     NUMBER;
    vnvlsaldo                      NUMBER;
  BEGIN
    vbvalido   := FALSE;
    vsmensagem := 'OK';

    SELECT pcpedi.qt,
           pcpedc.codfilial,
           pcpedc.codusur,
           pcpedc.condvenda,
           pcpedc.usasaldocontacorrentedescfin,
           pcpedc.tipomovccrca,
           pcpedc.perdescfin,
           pcpedi.pvenda,
           NVL((SELECT NVL(valor, 'N')
                 FROM pcparamfilial
                WHERE pcparamfilial.codfilial = pcpedc.codfilial
                  AND pcparamfilial.nome = 'GRAVARVALORDESCFIN'),
               'N')
      INTO vnqtatual,
           vscodfilial,
           vncodusur,
           vncondvenda,
           vsusasaldocontacorrentedescfin,
           vstipomovccrca,
           vnperdescfin,
           vnpvendaatual,
           vsgravarvalordescfin
      FROM pcpedi, pcpedc
     WHERE pcpedc.numped = p_numped
       AND pcpedc.numped = pcpedi.numped
       AND codprod = p_codprod
       AND numseq = p_numseq;

    -- Tarefa 102070 (Caso o valor do Desc. seja fixo por valor não será alterado com o novo item inserido)
    IF vsgravarvalordescfin = 'S' THEN
      vnperdescfin := 0;
    END IF;
    -- Fim tarefa 102070

    -- Tarefa 99976
    IF (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       (NVL(vsusasaldocontacorrentedescfin, 'N') = 'S') THEN
      vbvalido := TRUE;
    END IF;
    -- Fim tarefa 99976

    IF NOT (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       ((NVL(vsusasaldocontacorrentedescfin, 'N')) = 'S') AND
       (NVL(vstipomovccrca, 'VV') NOT IN ('FF', 'VV')) THEN
      IF (p_qtnova > 0) AND (p_qtnova <> vnqtatual) THEN
        IF p_qtnova > vnqtatual THEN
          vnvlsaldorca := ccfinrca_saldorcamenosdescfin(vncodusur,
                                                        vscodfilial);

          SELECT (pcpedi.pvenda * (p_qtnova - pcpedi.qt))
            INTO vnvltotalitens
            FROM pcpedi
           WHERE pcpedi.numped = p_numped
             AND pcpedi.codprod = p_codprod
             AND pcpedi.numseq = p_numseq
             AND pcpedi.qt > 0;

          vnvalordescfin := (vnvltotalitens) * (vnperdescfin / 100);

          IF (vnvlsaldorca < vnvalordescfin) THEN
            vbvalido   := FALSE;
            vsmensagem := 'RCA sem saldo para alterar qt do item';
          ELSE
            --RBD11
            SELECT COUNT(*)
              INTO vicontador
              FROM pcsaldorca
             WHERE codusur = vncodusur;

            IF vicontador = 0 THEN
              INSERT INTO pcsaldorca
                (codusur, vlsaldo, vlsaldoant)
              VALUES
                (vncodusur, 0, 0);
            END IF;

            IF NVL(vnperdescfin, 0) > 0 THEN
              SELECT NVL(vlsaldo, 0)
                INTO vnvlsaldo
                FROM pcsaldorca
               WHERE codusur = vncodusur
                 FOR UPDATE;

              IF (vnvalordescfin) > 0 THEN
                vnvalordescfin := vnvalordescfin * (-1);
              END IF;

              INSERT INTO pcmovsaldorca
                (DATA,
                 codfunc,
                 codusur,
                 rotina,
                 tipo,
                 valor,
                 vlsaldoant,
                 vlsaldo,
                 historico,
                 numped)
              VALUES
                (SYSDATE,
                 p_codfunclanc,
                 vncodusur,
                 p_rotinalanc,
                 'D',
                 vnvalordescfin,
                 vnvlsaldo,
                 (vnvlsaldo + (vnvalordescfin)),
                 'PEDIDO DE VENDA',
                 p_numped);

              UPDATE pcsaldorca
                 SET vlsaldoant = vnvlsaldo,
                     vlsaldo    = (vnvlsaldo + (vnvalordescfin))
               WHERE codusur = vncodusur;

              vbvalido := TRUE;
            END IF;
          END IF;
        ELSE
          --p_qtnova < vnqtautal
          --Creditar na CC do RCA o desconto financeiro proporcional a quantidade retirada do pedido, ou seja creditar apenas a diferença entre a quantidade anterior e a nova quantidade: o processo de crédito é semelhante ao processo descrito na [RBD7] Cancelar Item do Pedido de Venda e o Saldo de Conta Corrente do RCA.
          vbvalido := ccfinrca_excluir_item_pedido(p_codfunclanc,
                                                   p_rotinalanc,
                                                   vncodusur,
                                                   p_numped,
                                                   p_codprod,
                                                   p_numseq,
                                                   p_qtnova,
                                                   p_pvendanovo,
                                                   vsmensagem);
        END IF;
      END IF;

      --verifica alteração de preço
      IF (p_pvendanovo > 0) AND (p_pvendanovo <> vnpvendaatual) THEN
        IF (p_pvendanovo > vnpvendaatual) THEN
          vnvlsaldorca := ccfinrca_saldorcamenosdescfin(vncodusur,
                                                        vscodfilial);

          SELECT ((p_pvendanovo - pcpedi.pvenda) * pcpedi.qt)
            INTO vnvltotalitens
            FROM pcpedi
           WHERE pcpedi.numped = p_numped
             AND pcpedi.codprod = p_codprod
             AND pcpedi.numseq = p_numseq
             AND pcpedi.qt > 0;

          vnvalordescfin := (vnvltotalitens) * (vnperdescfin / 100);

          IF vnvlsaldorca < vnvalordescfin THEN
            vbvalido   := FALSE;
            vsmensagem := 'RCA sem saldo para alterar qt do item';
          ELSE
            --RBD11
            SELECT COUNT(*)
              INTO vicontador
              FROM pcsaldorca
             WHERE codusur = vncodusur;

            IF vicontador = 0 THEN
              INSERT INTO pcsaldorca
                (codusur, vlsaldo, vlsaldoant)
              VALUES
                (vncodusur, 0, 0);
            END IF;

            IF NVL(vnperdescfin, 0) > 0 THEN
              SELECT NVL(vlsaldo, 0)
                INTO vnvlsaldo
                FROM pcsaldorca
               WHERE codusur = vncodusur
                 FOR UPDATE;

              IF (vnvalordescfin) > 0 THEN
                vnvalordescfin := vnvalordescfin * (-1);
              END IF;

              INSERT INTO pcmovsaldorca
                (DATA,
                 codfunc,
                 codusur,
                 rotina,
                 tipo,
                 valor,
                 vlsaldoant,
                 vlsaldo,
                 historico,
                 numped)
              VALUES
                (SYSDATE,
                 p_codfunclanc,
                 vncodusur,
                 p_rotinalanc,
                 'D',
                 vnvalordescfin,
                 vnvlsaldo,
                 (vnvlsaldo + (vnvalordescfin)),
                 'PEDIDO DE VENDA',
                 p_numped);

              UPDATE pcsaldorca
                 SET vlsaldoant = vnvlsaldo,
                     vlsaldo    = (vnvlsaldo + (vnvalordescfin))
               WHERE codusur = vncodusur;

              vbvalido := TRUE;
            END IF;
          END IF;
        ELSE
          --p_pvendanovo < vnpvendatual
          vbvalido := ccfinrca_excluir_item_pedido(p_codfunclanc,
                                                   p_rotinalanc,
                                                   vncodusur,
                                                   p_numped,
                                                   p_codprod,
                                                   p_numseq,
                                                   p_qtnova,
                                                   p_pvendanovo,
                                                   vsmensagem);
        END IF;
      END IF; -- p_pvendanovo > 0
    END IF;

    p_mensagem := vsmensagem;
    RETURN vbvalido;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao alterar preço ou quantidade : ' || SQLCODE || ' ' ||
                    SQLERRM;
      RETURN FALSE;
  END; --ccfinrca_alterar_preco_qt

  --Projeto 90992 RBD6
  FUNCTION ccfinrca_altera_descfin_pedido(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                          p_rotinalanc  IN pclogrca.rotina%TYPE,
                                          p_codusur     IN pcpedc.codusur%TYPE,
                                          p_numped      IN pcpedc.numped%TYPE,
                                          p_novodescfin IN NUMBER,
                                          p_mensagem    OUT VARCHAR2)
    RETURN BOOLEAN IS
    vbvalido                       BOOLEAN;
    vncodusur                      pcpedc.codusur%TYPE;
    vncondvenda                    pcpedc.condvenda%TYPE;
    vsusasaldocontacorrentedescfin pcpedc.usasaldocontacorrentedescfin%TYPE;
    vstipomovccrca                 pcpedc.tipomovccrca%TYPE;
    vnperdescfin                   pcpedc.perdescfin%TYPE;
    vscodfilial                    pcpedc.codfilial%TYPE;
    vicontador                     NUMBER;
    vnvldifdescfin                 NUMBER;
    vnvlsaldo                      NUMBER;
    vnvltotalitens                 NUMBER;
    vnvalor                        NUMBER;
    vnvlsaldorca                   NUMBER;
    vstipo                         VARCHAR2(1);
    vsmensagem                     VARCHAR2(300);
  BEGIN
    vbvalido   := FALSE;
    vsmensagem := 'OK';

    SELECT pcpedc.codusur,
           pcpedc.condvenda,
           pcpedc.usasaldocontacorrentedescfin,
           pcpedc.tipomovccrca,
           pcpedc.perdescfin,
           pcpedc.codfilial
      INTO vncodusur,
           vncondvenda,
           vsusasaldocontacorrentedescfin,
           vstipomovccrca,
           vnperdescfin,
           vscodfilial
      FROM pcpedc
     WHERE pcpedc.numped = p_numped;

    -- Tarefa 99976
    IF (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       (NVL(vsusasaldocontacorrentedescfin, 'N') = 'S') THEN
      vbvalido := TRUE;
    END IF;
    -- Fim tarefa 99976

    IF NOT (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       ((NVL(vsusasaldocontacorrentedescfin, 'N')) = 'S') AND
       (NVL(vstipomovccrca, 'VV') NOT IN ('FF', 'VV')) THEN
      vbvalido := TRUE; -- Tarefa 103882

      SELECT COUNT(*)
        INTO vicontador
        FROM pcsaldorca
       WHERE codusur = vncodusur;

      IF vicontador = 0 THEN
        INSERT INTO pcsaldorca
          (codusur, vlsaldo, vlsaldoant)
        VALUES
          (vncodusur, 0, 0);
      END IF;

      vnvldifdescfin := NVL(vnperdescfin, 0) - NVL(p_novodescfin, 0);

      SELECT NVL(vlsaldo, 0)
        INTO vnvlsaldo
        FROM pcsaldorca
       WHERE codusur = vncodusur
         FOR UPDATE;

      SELECT (SUM(pcpedi.pvenda * pcpedi.qt))
        INTO vnvltotalitens
        FROM pcpedi
       WHERE pcpedi.numped = p_numped
         AND pcpedi.qt > 0;

      vnvalor := NVL(vnvltotalitens, 0) * (NVL(vnvldifdescfin, 0) / 100);

      IF vnvalor > 0 THEN
        vstipo := 'C';
      ELSE
        vstipo := 'D';
      END IF;

      IF (vstipo = 'D') THEN
        vnvlsaldorca := ccfinrca_saldorcamenosdescfin(vncodusur,
                                                      vscodfilial);

        IF (vnvlsaldorca < vnvalor * (-1)) --correção sabrina
         THEN
          vbvalido   := FALSE;
          vsmensagem := 'Rca não tem saldo para alterar desconto financeiro.';
        END IF;
      END IF;

      IF vbvalido = TRUE
        -- correção sabrina (esta alteração soh deve ser feita se houver saldo)
         AND NVL(vstipomovccrca, 'VV') NOT IN ('FF', 'VV') THEN
        INSERT INTO pcmovsaldorca
          (DATA,
           codfunc,
           codusur,
           rotina,
           tipo,
           valor,
           vlsaldoant,
           vlsaldo,
           historico,
           numped)
        VALUES
          (SYSDATE,
           p_codfunclanc,
           vncodusur,
           p_rotinalanc,
           vstipo,
           vnvalor,
           vnvlsaldo,
           (vnvlsaldo + vnvalor),
           'PEDIDO DE VENDA',
           p_numped);

        UPDATE pcsaldorca
           SET vlsaldoant = vnvlsaldo, vlsaldo = (vnvlsaldo + vnvalor)
         WHERE codusur = vncodusur;

        vbvalido := TRUE;
      END IF;
    END IF;

    p_mensagem := vsmensagem;
    RETURN(vbvalido);
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao alterar descotno financeiro : ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END; --ccfinrca_altera_descfin_pedido

  --Projeto 90992 RBD8
  FUNCTION ccfinrca_fatura_pedido(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                  p_rotinalanc  IN pclogrca.rotina%TYPE,
                                  p_codusur     IN pcpedc.codusur%TYPE,
                                  p_numped      IN pcpedc.numped%TYPE,
                                  p_mensagem    OUT VARCHAR2)
  /******************************************************
    Data        Autor   Tarefa     Obs.
    08/12/2009  Pablo   95754      Inicializando as variáveis vncondvenda,
                                   vnperdescfin
    16/12/2009  Pablo                   Alteração para não realizar divisão por zero
    *****************************************************/
   RETURN BOOLEAN IS
    vbvalido                       BOOLEAN;
    vncodusur                      pcpedc.codusur%TYPE;
    vncondvenda                    pcpedc.condvenda%TYPE;
    vsusasaldocontacorrentedescfin pcpedc.usasaldocontacorrentedescfin%TYPE;
    vstipomovccrca                 pcpedc.tipomovccrca%TYPE;
    vnperdescfin                   pcpedc.perdescfin%TYPE;
    vscodfilial                    pcpedc.codfilial%TYPE;
    vnnumtransvenda                pcpedc.numtransvenda%TYPE;
    vicontador                     NUMBER;
    vnvlsaldo                      NUMBER;
    vnvltotalitens                 NUMBER;
    vnvlsaldorca                   NUMBER;
    vsmensagem                     VARCHAR2(300);
    vndescmax                      NUMBER;
    vnfixo                         NUMBER;
    vncreditosaldorca              NUMBER;
    vnvalordebito                  NUMBER;

  BEGIN
    vbvalido   := FALSE;
    vsmensagem := 'OK';

    SELECT p.codusur,
           p.codfilial,
           p.tipomovccrca,
           p.usasaldocontacorrentedescfin,
           p.condvenda,
           p.perdescfin
      INTO vncodusur,
           vscodfilial,
           vstipomovccrca,
           vsusasaldocontacorrentedescfin,
           vncondvenda,
           vnperdescfin
      FROM pcpedc p
     WHERE p.numped = p_numped;

    SELECT numtransvenda
      INTO vnnumtransvenda
      FROM (SELECT NUMTRANSVENDA, 1 A
              FROM pcnfsaid
             WHERE numped = p_numped
             UNION
            SELECT NUMTRANSVENDA, 2 A
              FROM pcnfsaidprefat
             WHERE numped = p_numped)
     WHERE ROWNUM = 1
     ORDER BY A;

    -- Tarefa 99976
    IF (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       (NVL(vsusasaldocontacorrentedescfin, 'N') = 'S') THEN
      vbvalido := TRUE;
    END IF;
    -- Fim tarefa 99976

    IF NOT (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       ((NVL(vsusasaldocontacorrentedescfin, 'N')) = 'S') THEN
      SELECT COUNT(*)
        INTO vicontador
        FROM pcsaldorca
       WHERE codusur = vncodusur;

      IF vicontador = 0 THEN
        INSERT INTO pcsaldorca
          (codusur, vlsaldo, vlsaldoant)
        VALUES
          (vncodusur, 0, 0);
      END IF;

      SELECT NVL(vlsaldo, 0)
        INTO vnvlsaldo
        FROM pcsaldorca
       WHERE codusur = vncodusur
         FOR UPDATE;

      --VF
      IF (NVL(vstipomovccrca, 'VV') = 'VF') THEN
        --RBD10
        SELECT NVL(descmax, 0), NVL(fixo, 0)
          INTO vndescmax, vnfixo
          FROM pcparamsaldo
         WHERE ROWNUM = 1;

        vncreditosaldorca := 0;

        --alteração feita para evitar erro de divisor 0
        begin

          SELECT SUM(((((vndescmax - pcpedi.perdesc) / vnfixo -
                     tab.percacresc) / 100) * pcpedi.pvenda) -- Pablo 16/12/2009
                     * pcpedi.qt)
            INTO vncreditosaldorca
            FROM pcpedi,
                 (SELECT pcfaixadesc.percacresc,
                         pcfaixadesc.percinicio,
                         pcfaixadesc.percfim
                    FROM pcfaixadesc) tab
           WHERE pcpedi.numped = p_numped
             AND pcpedi.qt > 0
             AND pcpedi.perdesc BETWEEN tab.percinicio AND tab.percfim;
        exception
          when others then
            vncreditosaldorca := 0;

        end;

        IF NVL(vncreditosaldorca, 0) < 0 THEN
          vncreditosaldorca := 0;
        END IF;

        INSERT INTO pcmovsaldorca
          (DATA,
           codfunc,
           codusur,
           rotina,
           tipo,
           valor,
           vlsaldoant,
           vlsaldo,
           historico,
           numtransvenda)
        VALUES
          (SYSDATE,
           p_codfunclanc,
           vncodusur,
           p_rotinalanc,
           'C',
           NVL(vncreditosaldorca, 0),
           vnvlsaldo,
           (vnvlsaldo + NVL(vncreditosaldorca, 0)),
           'FATURAMENTO DE PEDIDO',
           vnnumtransvenda);

        UPDATE pcsaldorca
           SET vlsaldoant = vnvlsaldo,
               vlsaldo    = (vnvlsaldo + NVL(vncreditosaldorca, 0))
         WHERE codusur = vncodusur;

        vbvalido := TRUE;
        --FF
      ELSIF (NVL(vstipomovccrca, 'VV') IN ('VV', 'FF')) THEN
        --RBD11 débito
        IF NVL(vnperdescfin, 0) > 0 THEN
          SELECT (SUM(pcpedi.pvenda * pcpedi.qt))
            INTO vnvltotalitens
            FROM pcpedi
           WHERE pcpedi.numped = p_numped
             AND pcpedi.qt > 0;

          vnvalordebito := vnvltotalitens * (vnperdescfin / 100);

          IF vnvalordebito > 0 THEN
            vnvalordebito := vnvalordebito * (-1);
          END IF;

          INSERT INTO pcmovsaldorca
            (DATA,
             codfunc,
             codusur,
             rotina,
             tipo,
             valor,
             vlsaldoant,
             vlsaldo,
             historico,
             numped)
          VALUES
            (SYSDATE,
             p_codfunclanc,
             vncodusur,
             p_rotinalanc,
             'D',
             vnvalordebito,
             vnvlsaldo,
             (vnvlsaldo + (vnvalordebito)),
             'PEDIDO DE VENDA',
             p_numped);

          UPDATE pcsaldorca
             SET vlsaldoant = vnvlsaldo,
                 vlsaldo    = (vnvlsaldo + (vnvalordebito))
           WHERE codusur = vncodusur;
        END IF;
        --RBD10 crédito
        SELECT NVL(vlsaldo, 0)
          INTO vnvlsaldo
          FROM pcsaldorca
         WHERE codusur = vncodusur
           FOR UPDATE;

        SELECT NVL(descmax, 0), NVL(fixo, 0)
          INTO vndescmax, vnfixo
          FROM pcparamsaldo
         WHERE ROWNUM = 1;

        vncreditosaldorca := 0;

        --alteração feita para evitar erro de divisor 0

        begin

          SELECT SUM(((((vndescmax - pcpedi.perdesc) / vnfixo -
                     tab.percacresc) / 100) * pcpedi.pvenda) -- Pablo 16/12/2009
                     * pcpedi.qt)
            INTO vncreditosaldorca
            FROM pcpedi,
                 (SELECT pcfaixadesc.percacresc,
                         pcfaixadesc.percinicio,
                         pcfaixadesc.percfim
                    FROM pcfaixadesc) tab
           WHERE pcpedi.numped = p_numped
             AND pcpedi.qt > 0
             AND pcpedi.perdesc BETWEEN tab.percinicio AND tab.percfim;

        exception
          when others then
            vncreditosaldorca := 0;

        end;

        IF NVL(vncreditosaldorca, 0) < 0 THEN
          vncreditosaldorca := 0;
        END IF;

        INSERT INTO pcmovsaldorca
          (DATA,
           codfunc,
           codusur,
           rotina,
           tipo,
           valor,
           vlsaldoant,
           vlsaldo,
           historico,
           numtransvenda,
           numped)
        VALUES
          (SYSDATE,
           p_codfunclanc,
           vncodusur,
           p_rotinalanc,
           'C',
           NVL(vncreditosaldorca, 0),
           vnvlsaldo,
           (vnvlsaldo + NVL(vncreditosaldorca, 0)),
           'FATURAMENTO DE PEDIDO',
           vnnumtransvenda,
           p_numped);

        UPDATE pcsaldorca
           SET vlsaldoant = vnvlsaldo,
               vlsaldo    = (vnvlsaldo + NVL(vncreditosaldorca, 0))
         WHERE codusur = vncodusur;

        vbvalido := TRUE;
      elsif (NVL(vstipomovccrca, 'VV') = 'VA') then
        vbvalido := TRUE;
      END IF;
      -- END IF;
    END IF;

    p_mensagem := vsmensagem;
    RETURN(vbvalido);
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao faturar pedido : ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN vbvalido;
  END; --ccfinrca_Fatura_pedido

  --Projeto 90992 - RBD12
  FUNCTION ccfinrca_cancela_notafiscal(p_codfunclanc   IN pclogrca.codfunc%TYPE,
                                       p_rotinalanc    IN pclogrca.rotina%TYPE,
                                       p_codusur       IN pcpedc.codusur%TYPE,
                                       p_numtransvenda IN pcnfsaid.numtransvenda%TYPE,
                                       p_cancelapedido IN VARCHAR2,
                                       p_mensagem      OUT VARCHAR2)
    RETURN BOOLEAN IS
    vbvalido                       BOOLEAN;
    vncodusur                      pcnfsaid.codusur%TYPE;
    vncondvenda                    pcpedc.condvenda%TYPE;
    vsusasaldocontacorrentedescfin pcpedc.usasaldocontacorrentedescfin%TYPE;
    vstipomovccrca                 pcpedc.tipomovccrca%TYPE;
    vnperdescfin                   pcpedc.perdescfin%TYPE;
    vscodfilial                    pcpedc.codfilial%TYPE;
    vnnumped                       pcpedc.numped%TYPE;
    vicontador                     NUMBER;
    vnvlsaldo                      NUMBER;
    vndescmax                      NUMBER;
    vnfixo                         NUMBER;
    vndebitosaldorca               NUMBER;
    vncreditosaldorca              NUMBER;
    vsmensagem                     VARCHAR2(300);
    vnvltotalitens                 NUMBER;

  BEGIN
    vbvalido   := FALSE;
    vsmensagem := 'OK';

    SELECT DADOS.CODUSUR,
           DADOS.CONDVENDA,
           DADOS.USASALDOCONTACORRENTEDESCFIN,
           DADOS.TIPOMOVCCRCA,
           DADOS.PERDESCFIN,
           DADOS.CODFILIAL,
           DADOS.NUMPED
      INTO VNCODUSUR,
           VNCONDVENDA,
           VSUSASALDOCONTACORRENTEDESCFIN,
           VSTIPOMOVCCRCA,
           VNPERDESCFIN,
           VSCODFILIAL,
           VNNUMPED
      FROM (SELECT PCNFSAID.CODUSUR,
                   PCPEDC.CONDVENDA,
                   PCPEDC.USASALDOCONTACORRENTEDESCFIN,
                   PCPEDC.TIPOMOVCCRCA,
                   PCPEDC.PERDESCFIN,
                   PCPEDC.CODFILIAL,
                   PCPEDC.NUMPED,
                   1 A
              FROM PCPEDC, PCNFSAID
             WHERE PCPEDC.NUMPED = PCNFSAID.NUMPED
               AND PCNFSAID.NUMTRANSVENDA = P_NUMTRANSVENDA
             UNION
            SELECT PCNFSAID.CODUSUR,
                   PCPEDC.CONDVENDA,
                   PCPEDC.USASALDOCONTACORRENTEDESCFIN,
                   PCPEDC.TIPOMOVCCRCA,
                   PCPEDC.PERDESCFIN,
                   PCPEDC.CODFILIAL,
                   PCPEDC.NUMPED,
                   2 A
              FROM PCPEDC, PCNFSAIDPREFAT PCNFSAID
             WHERE PCPEDC.NUMPED = PCNFSAID.NUMPED
               AND PCNFSAID.NUMTRANSVENDA = P_NUMTRANSVENDA) DADOS
       WHERE ROWNUM = 1
       ORDER BY A;

    /*
    SELECT pcnfsaid.codusur,
           pcpedc.condvenda,
           pcpedc.usasaldocontacorrentedescfin,
           pcpedc.tipomovccrca,
           pcpedc.perdescfin,
           pcpedc.codfilial,
           pcpedc.numped
      INTO vncodusur,
           vncondvenda,
           vsusasaldocontacorrentedescfin,
           vstipomovccrca,
           vnperdescfin,
           vscodfilial,
           vnnumped
      FROM pcpedc, pcnfsaid
     WHERE pcpedc.numped = pcnfsaid.numped
       AND pcnfsaid.numtransvenda = p_numtransvenda; */

    -- Tarefa 99976
    IF (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       (NVL(vsusasaldocontacorrentedescfin, 'N') = 'S') THEN
      vbvalido := TRUE;
    END IF;
    -- Fim tarefa 99976

    IF NOT (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       ((NVL(vsusasaldocontacorrentedescfin, 'N')) = 'S') THEN
      SELECT COUNT(*)
        INTO vicontador
        FROM pcsaldorca
       WHERE codusur = vncodusur;

      IF vicontador = 0 THEN
        INSERT INTO pcsaldorca
          (codusur, vlsaldo, vlsaldoant)
        VALUES
          (vncodusur, 0, 0);
      END IF;

      SELECT NVL(vlsaldo, 0)
        INTO vnvlsaldo
        FROM pcsaldorca
       WHERE codusur = vncodusur
         FOR UPDATE;

      --VF
      IF (NVL(vstipomovccrca, 'VV') = 'VF') THEN
        --RBD10
        SELECT NVL(descmax, 0), NVL(fixo, 0)
          INTO vndescmax, vnfixo
          FROM pcparamsaldo
         WHERE ROWNUM = 1;

        vndebitosaldorca := 0;

        --alteração feita para evitar erro de divisor 0
        begin

          SELECT SUM(((((vndescmax - pcpedi.perdesc) / vnfixo -
                     tab.percacresc) / 100) * pcpedi.pvenda) -- Pablo 16/12/2009
                     * pcpedi.qt)
            INTO vndebitosaldorca
            FROM pcpedi,
                 (SELECT pcfaixadesc.percacresc,
                         pcfaixadesc.percinicio,
                         pcfaixadesc.percfim
                    FROM pcfaixadesc) tab
           WHERE pcpedi.numped = vnnumped
             AND pcpedi.qt > 0
             AND pcpedi.perdesc BETWEEN tab.percinicio AND tab.percfim;

        exception
          when others then
            vndebitosaldorca := 0;

        end;

        IF NVL(vndebitosaldorca, 0) < 0 THEN
          vndebitosaldorca := 0;
        END IF;

        INSERT INTO pcmovsaldorca
          (DATA,
           codfunc,
           codusur,
           rotina,
           tipo,
           valor,
           vlsaldoant,
           vlsaldo,
           historico,
           numtransvenda)
        VALUES
          (SYSDATE,
           p_codfunclanc,
           vncodusur,
           p_rotinalanc,
           'D',
           NVL(vndebitosaldorca, 0) * (-1),
           vnvlsaldo,
           (vnvlsaldo - NVL(vndebitosaldorca, 0)),
           'FATURAMENTO DE PEDIDO',
           p_numtransvenda);

        UPDATE pcsaldorca
           SET vlsaldoant = vnvlsaldo,
               vlsaldo    = (vnvlsaldo - NVL(vndebitosaldorca, 0))
         WHERE codusur = vncodusur;

        vbvalido := TRUE;

        IF p_cancelapedido = 'S' THEN
          SELECT NVL(vlsaldo, 0)
            INTO vnvlsaldo
            FROM pcsaldorca
           WHERE codusur = vncodusur
             FOR UPDATE;

          --RBD11
          IF NVL(vnperdescfin, 0) > 0 THEN
            SELECT (SUM(pcpedi.pvenda * pcpedi.qt))
              INTO vnvltotalitens
              FROM pcpedi
             WHERE pcpedi.numped = vnnumped
               AND pcpedi.qt > 0;

            vncreditosaldorca := vnvltotalitens * (vnperdescfin / 100);

            IF vncreditosaldorca < 0 THEN
              vncreditosaldorca := vncreditosaldorca * (-1);
            END IF;

            INSERT INTO pcmovsaldorca
              (DATA,
               codfunc,
               codusur,
               rotina,
               tipo,
               valor,
               vlsaldoant,
               vlsaldo,
               historico,
               numped)
            VALUES
              (SYSDATE,
               p_codfunclanc,
               vncodusur,
               p_rotinalanc,
               'C',
               vncreditosaldorca,
               vnvlsaldo,
               (vnvlsaldo + (vncreditosaldorca)),
               'PEDIDO DE VENDA',
               vnnumped);

            UPDATE pcsaldorca
               SET vlsaldoant = vnvlsaldo,
                   vlsaldo    = (vnvlsaldo + (vncreditosaldorca))
             WHERE codusur = vncodusur;

            vbvalido := TRUE;
          END IF;
        END IF;
        --VA
      ELSIF (NVL(vstipomovccrca, 'VV') = 'VA') THEN
        IF p_cancelapedido = 'S' THEN
          --RBD11
          IF NVL(vnperdescfin, 0) > 0 THEN
            SELECT (SUM(pcpedi.pvenda * pcpedi.qt))
              INTO vnvltotalitens
              FROM pcpedi
             WHERE pcpedi.numped = vnnumped
               AND pcpedi.qt > 0;

            vncreditosaldorca := vnvltotalitens * (vnperdescfin / 100);

            IF vncreditosaldorca < 0 THEN
              vncreditosaldorca := vncreditosaldorca * (-1);
            END IF;

            INSERT INTO pcmovsaldorca
              (DATA,
               codfunc,
               codusur,
               rotina,
               tipo,
               valor,
               vlsaldoant,
               vlsaldo,
               historico,
               numped)
            VALUES
              (SYSDATE,
               p_codfunclanc,
               vncodusur,
               p_rotinalanc,
               'C',
               vncreditosaldorca,
               vnvlsaldo,
               (vnvlsaldo + (vncreditosaldorca)),
               'PEDIDO DE VENDA',
               vnnumped);

            UPDATE pcsaldorca
               SET vlsaldoant = vnvlsaldo,
                   vlsaldo    = (vnvlsaldo + (vncreditosaldorca))
             WHERE codusur = vncodusur;

            vbvalido := TRUE;
          ELSE
            --Tarefa 106838
            vbvalido := TRUE;
          END IF;
        END IF;

        SELECT count(1)
          into vicontador
          FROM (SELECT COUNT(1)
                  FROM PCPREST
                 WHERE NUMTRANSVENDA = p_numtransvenda
                   AND DTFECHA IS NOT NULL
                   AND NVL(VALOR, 0) > 0
                   AND CODCOB <> 'DESD'
                 UNION
                SELECT COUNT(1)
                  FROM PCPRESTPREFAT PCPREST
                 WHERE NUMTRANSVENDA = p_numtransvenda
                   AND DTFECHA IS NOT NULL
                   AND NVL(VALOR, 0) > 0
                   AND CODCOB <> 'DESD');

        if vicontador > 0 then

          --RBD10
          SELECT NVL(descmax, 0), NVL(fixo, 0)
            INTO vndescmax, vnfixo
            FROM pcparamsaldo
           WHERE ROWNUM = 1;

          vndebitosaldorca := 0;

          --alteração feita para evitar erro de divisor 0
          begin

            SELECT SUM(((((vndescmax - pcpedi.perdesc) / vnfixo -
                       tab.percacresc) / 100) * pcpedi.pvenda) -- Pablo 16/12/2009
                       * pcpedi.qt)
              INTO vndebitosaldorca
              FROM pcpedi,
                   (SELECT pcfaixadesc.percacresc,
                           pcfaixadesc.percinicio,
                           pcfaixadesc.percfim
                      FROM pcfaixadesc) tab
             WHERE pcpedi.numped = vnnumped
               AND pcpedi.qt > 0
               AND pcpedi.perdesc BETWEEN tab.percinicio AND tab.percfim;

          exception
            when others then
              vndebitosaldorca := 0;

          end;

          IF NVL(vndebitosaldorca, 0) < 0 THEN
            vndebitosaldorca := 0;
          END IF;

          -- tarefa 99600
          SELECT NVL(vlsaldo, 0)
            INTO vnvlsaldo
            FROM pcsaldorca
           WHERE codusur = vncodusur
             FOR UPDATE;

          INSERT INTO pcmovsaldorca
            (DATA,
             codfunc,
             codusur,
             rotina,
             tipo,
             valor,
             vlsaldoant,
             vlsaldo,
             historico,
             numtransvenda)
          VALUES
            (SYSDATE,
             p_codfunclanc,
             vncodusur,
             p_rotinalanc,
             'D',
             NVL(vndebitosaldorca, 0) * (-1),
             vnvlsaldo,
             (vnvlsaldo - NVL(vndebitosaldorca, 0)),
             'FATURAMENTO DE PEDIDO',
             p_numtransvenda);

          UPDATE pcsaldorca
             SET vlsaldoant = vnvlsaldo,
                 vlsaldo    = (vnvlsaldo - NVL(vndebitosaldorca, 0))
           WHERE codusur = vncodusur;

          vbvalido := TRUE;

        end if;

        --FF
      ELSIF (NVL(vstipomovccrca, 'VV') in ('VV', 'FF')) THEN
        --RBD11
        --  IF NVL (vnperdescfin, 0) > 0
        -- THEN
        SELECT (SUM(pcpedi.pvenda * pcpedi.qt))
          INTO vnvltotalitens
          FROM pcpedi
         WHERE pcpedi.numped = vnnumped
           AND pcpedi.qt > 0;

        vncreditosaldorca := vnvltotalitens * (vnperdescfin / 100);

        IF vncreditosaldorca < 0 THEN
          vncreditosaldorca := vncreditosaldorca * (-1);
        END IF;

        INSERT INTO pcmovsaldorca
          (DATA,
           codfunc,
           codusur,
           rotina,
           tipo,
           valor,
           vlsaldoant,
           vlsaldo,
           historico,
           numped)
        VALUES
          (SYSDATE,
           p_codfunclanc,
           vncodusur,
           p_rotinalanc,
           'C',
           vncreditosaldorca,
           vnvlsaldo,
           (vnvlsaldo + (vncreditosaldorca)),
           'PEDIDO DE VENDA',
           vnnumped);

        UPDATE pcsaldorca
           SET vlsaldoant = vnvlsaldo,
               vlsaldo    = (vnvlsaldo + (vncreditosaldorca))
         WHERE codusur = vncodusur;

        vbvalido := TRUE;

        --RBD10
        SELECT NVL(vlsaldo, 0)
          INTO vnvlsaldo
          FROM pcsaldorca
         WHERE codusur = vncodusur
           FOR UPDATE;

        SELECT NVL(descmax, 0), NVL(fixo, 0)
          INTO vndescmax, vnfixo
          FROM pcparamsaldo
         WHERE ROWNUM = 1;

        vndebitosaldorca := 0;

        --alteração feita para evitar erro de divisor 0

        begin

          SELECT SUM(((((vndescmax - pcpedi.perdesc) / vnfixo -
                     tab.percacresc) / 100) * pcpedi.pvenda) -- Pablo 16/12/2009
                     * pcpedi.qt)
            INTO vndebitosaldorca
            FROM pcpedi,
                 (SELECT pcfaixadesc.percacresc,
                         pcfaixadesc.percinicio,
                         pcfaixadesc.percfim
                    FROM pcfaixadesc) tab
           WHERE pcpedi.numped = vnnumped
             AND pcpedi.qt > 0
             AND pcpedi.perdesc BETWEEN tab.percinicio AND tab.percfim;

        exception
          when others then
            vndebitosaldorca := 0;

        end;

        IF NVL(vndebitosaldorca, 0) < 0 THEN
          vndebitosaldorca := 0;
        END IF;

        INSERT INTO pcmovsaldorca
          (DATA,
           codfunc,
           codusur,
           rotina,
           tipo,
           valor,
           vlsaldoant,
           vlsaldo,
           historico,
           numtransvenda)
        VALUES
          (SYSDATE,
           p_codfunclanc,
           vncodusur,
           p_rotinalanc,
           'D',
           NVL(vndebitosaldorca, 0) * (-1),
           vnvlsaldo,
           (vnvlsaldo - NVL(vndebitosaldorca, 0)),
           'FATURAMENTO DE PEDIDO',
           p_numtransvenda);

        UPDATE pcsaldorca
           SET vlsaldoant = vnvlsaldo,
               vlsaldo    = (vnvlsaldo - NVL(vndebitosaldorca, 0))
         WHERE codusur = vncodusur;

        vbvalido := TRUE;
        --  END IF;
      END IF;
    END IF;

    p_mensagem := vsmensagem;
    RETURN vbvalido;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao cancelar nota fiscal : ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN vbvalido;
  END; -- ccfinrca_cancela_notafiscal

  PROCEDURE ccfinrca_lanca_movimento_carga(p_codfunclanc         IN pclogrca.codfunc%TYPE,
                                           p_rotinalanc          IN pclogrca.rotina%TYPE,
                                           p_numcar              IN pcnfsaid.numcar%TYPE,
                                           p_dataemissao_inicial IN DATE,
                                           p_dataemissao_final   IN DATE,
                                           p_mensagem            OUT VARCHAR2) IS
    vbvalido                       BOOLEAN;
    vsmensagem                     VARCHAR2(300);
    vncodusur                      pcpedc.codusur%TYPE;
    vncondvenda                    pcpedc.condvenda%TYPE;
    vsusasaldocontacorrentedescfin pcpedc.usasaldocontacorrentedescfin%TYPE;
    vstipomovccrca                 pcpedc.tipomovccrca%TYPE;
    vnperdescfin                   pcpedc.perdescfin%TYPE;
    vscodfilial                    pcpedc.codfilial%TYPE;
    vnnumped                       pcpedc.numped%TYPE;
    vicontador                     NUMBER;
    vnvlsaldo                      NUMBER;
    vndescmax                      NUMBER;
    vnfixo                         NUMBER;
    vncreditosaldorca              NUMBER;

  BEGIN
    vsmensagem := 'OK';

    IF NVL(p_numcar, 0) = 0 THEN
      FOR reg IN (SELECT numtransvenda, dtfechaccrca
                    FROM pcnfsaid
                   WHERE numcar = NVL(p_numcar, 0)
                        --Tarefa 105946
                     AND pcnfsaid.dtcancel is null
                     AND dtsaida BETWEEN p_dataemissao_inicial AND
                         p_dataemissao_final) LOOP
        vbvalido := ccrca_verificar_fechamento(reg.numtransvenda);

        IF vbvalido = TRUE THEN
          IF reg.dtfechaccrca IS NULL THEN
            SELECT pcnfsaid.codusur,
                   pcpedc.condvenda,
                   pcpedc.usasaldocontacorrentedescfin,
                   pcpedc.tipomovccrca,
                   pcpedc.perdescfin,
                   pcpedc.codfilial,
                   pcpedc.numped
              INTO vncodusur,
                   vncondvenda,
                   vsusasaldocontacorrentedescfin,
                   vstipomovccrca,
                   vnperdescfin,
                   vscodfilial,
                   vnnumped
              FROM pcpedc, pcnfsaid
             WHERE pcpedc.numped = pcnfsaid.numped
                  --Tarefa 105946
               AND pcnfsaid.dtcancel is null
               AND pcnfsaid.numtransvenda = reg.numtransvenda;

            -- Tarefa 99976
            IF (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
               (NVL(vsusasaldocontacorrentedescfin, 'N') = 'S') THEN
              vbvalido := TRUE;
            END IF;
            -- Fim tarefa 99976

            IF NOT (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
               ((NVL(vsusasaldocontacorrentedescfin, 'N')) = 'S') THEN
              SELECT COUNT(*)
                INTO vicontador
                FROM pcsaldorca
               WHERE codusur = vncodusur;

              IF vicontador = 0 THEN
                INSERT INTO pcsaldorca
                  (codusur, vlsaldo, vlsaldoant)
                VALUES
                  (vncodusur, 0, 0);
              END IF;

              SELECT NVL(vlsaldo, 0)
                INTO vnvlsaldo
                FROM pcsaldorca
               WHERE codusur = vncodusur
                 FOR UPDATE;

              --RBD10
              SELECT NVL(descmax, 0), NVL(fixo, 0)
                INTO vndescmax, vnfixo
                FROM pcparamsaldo
               WHERE ROWNUM = 1;

              vncreditosaldorca := 0;

              --alteração feita para evitar erro de divisor 0
              begin

                SELECT SUM(((((vndescmax - pcpedi.perdesc) / vnfixo -
                           tab.percacresc) / 100) * pcpedi.pvenda) -- Pablo 16/12/2009
                           * pcpedi.qt)
                  INTO vncreditosaldorca
                  FROM pcpedi,
                       (SELECT pcfaixadesc.percacresc,
                               pcfaixadesc.percinicio,
                               pcfaixadesc.percfim
                          FROM pcfaixadesc) tab
                 WHERE pcpedi.numped = vnnumped
                   AND pcpedi.qt > 0
                   AND pcpedi.perdesc BETWEEN tab.percinicio AND
                       tab.percfim;

              exception
                when others then
                  vncreditosaldorca := 0;

              end;

              IF NVL(vncreditosaldorca, 0) < 0 THEN
                vncreditosaldorca := 0;
              END IF;

              INSERT INTO pcmovsaldorca
                (DATA,
                 codfunc,
                 codusur,
                 rotina,
                 tipo,
                 valor,
                 vlsaldoant,
                 vlsaldo,
                 historico,
                 numtransvenda)
              VALUES
                (SYSDATE,
                 p_codfunclanc,
                 vncodusur,
                 p_rotinalanc,
                 'C',
                 NVL(vncreditosaldorca, 0),
                 vnvlsaldo,
                 (vnvlsaldo + NVL(vncreditosaldorca, 0)),
                 'MOVIMENTO CARGA',
                 reg.numtransvenda);

              UPDATE pcsaldorca
                 SET vlsaldoant = vnvlsaldo,
                     vlsaldo    = (vnvlsaldo + NVL(vncreditosaldorca, 0))
               WHERE codusur = vncodusur;

              UPDATE pcnfsaid
                 SET dtfechaccrca = SYSDATE
               WHERE numtransvenda = reg.numtransvenda;

              vbvalido := TRUE;
            END IF;
          END IF;
        END IF;
      END LOOP;
    ELSE
      FOR reg IN (SELECT numtransvenda, dtfechaccrca
                    FROM pcnfsaid
                   WHERE pcnfsaid.numcar = p_numcar
                        --Tarefa 105946
                     AND pcnfsaid.dtcancel is null
                     AND EXISTS (select pcpedc.numtransvenda
                            from pcpedc
                           where pcpedc.numtransvenda =
                                 pcnfsaid.numtransvenda)) LOOP
        vbvalido := ccrca_verificar_fechamento(reg.numtransvenda);

        IF vbvalido = TRUE THEN
          IF reg.dtfechaccrca IS NULL THEN
            SELECT pcnfsaid.codusur,
                   pcpedc.condvenda,
                   pcpedc.usasaldocontacorrentedescfin,
                   pcpedc.tipomovccrca,
                   pcpedc.perdescfin,
                   pcpedc.codfilial,
                   pcpedc.numped
              INTO vncodusur,
                   vncondvenda,
                   vsusasaldocontacorrentedescfin,
                   vstipomovccrca,
                   vnperdescfin,
                   vscodfilial,
                   vnnumped
              FROM pcpedc, pcnfsaid
             WHERE pcpedc.numped = pcnfsaid.numped
               AND pcnfsaid.numtransvenda = reg.numtransvenda;

            IF NOT (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
               ((NVL(vsusasaldocontacorrentedescfin, 'N')) = 'S') THEN
              SELECT COUNT(*)
                INTO vicontador
                FROM pcsaldorca
               WHERE codusur = vncodusur;

              IF vicontador = 0 THEN
                INSERT INTO pcsaldorca
                  (codusur, vlsaldo, vlsaldoant)
                VALUES
                  (vncodusur, 0, 0);
              END IF;

              SELECT NVL(vlsaldo, 0)
                INTO vnvlsaldo
                FROM pcsaldorca
               WHERE codusur = vncodusur
                 FOR UPDATE;

              --RBD10
              SELECT NVL(descmax, 0), NVL(fixo, 0)
                INTO vndescmax, vnfixo
                FROM pcparamsaldo
               WHERE ROWNUM = 1;

              vncreditosaldorca := 0;

              --alteração feita para evitar erro de divisor 0
              begin

                SELECT SUM(((((vndescmax - pcpedi.perdesc) / vnfixo -
                           tab.percacresc) / 100) * pcpedi.pvenda) -- Pablo 16/12/2009
                           * pcpedi.qt)
                  INTO vncreditosaldorca
                  FROM pcpedi,
                       (SELECT pcfaixadesc.percacresc,
                               pcfaixadesc.percinicio,
                               pcfaixadesc.percfim
                          FROM pcfaixadesc) tab
                 WHERE pcpedi.numped = vnnumped
                   AND pcpedi.qt > 0
                   AND pcpedi.perdesc BETWEEN tab.percinicio AND
                       tab.percfim;
              exception
                when others then
                  vncreditosaldorca := 0;

              end;

              IF NVL(vncreditosaldorca, 0) < 0 THEN
                vncreditosaldorca := 0;
              END IF;

              INSERT INTO pcmovsaldorca
                (DATA,
                 codfunc,
                 codusur,
                 rotina,
                 tipo,
                 valor,
                 vlsaldoant,
                 vlsaldo,
                 historico,
                 numtransvenda)
              VALUES
                (SYSDATE,
                 p_codfunclanc,
                 vncodusur,
                 p_rotinalanc,
                 'C',
                 NVL(vncreditosaldorca, 0),
                 vnvlsaldo,
                 (vnvlsaldo + NVL(vncreditosaldorca, 0)),
                 'MOVIMENTO CARGA',
                 reg.numtransvenda);

              UPDATE pcsaldorca
                 SET vlsaldoant = vnvlsaldo,
                     vlsaldo    = (vnvlsaldo + NVL(vncreditosaldorca, 0))
               WHERE codusur = vncodusur;

              UPDATE pcnfsaid
                 SET dtfechaccrca = SYSDATE
               WHERE numtransvenda = reg.numtransvenda;

              vbvalido := TRUE;
            END IF;
          END IF;
        END IF;
      END LOOP;
    END IF;

    p_mensagem := vsmensagem;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao lancar movimento carga.' || SQLCODE || ' ' ||
                    SQLERRM;
  END; --ccfinrca_lanca_movimento_Carga

  PROCEDURE ccfinrca_lanca_movimento_caixa(p_codfunclanc     IN pclogrca.codfunc%TYPE,
                                           p_rotinalanc      IN pclogrca.rotina%TYPE,
                                           p_numcheckout     IN pcpedc.numcaixa%TYPE,
                                           p_codfunccheckout IN pcnfsaid.codfunclanc%TYPE,
                                           p_dataemissao     IN DATE,
                                           p_mensagem        OUT VARCHAR2) IS
    vbvalido                       BOOLEAN;
    vsmensagem                     VARCHAR2(300);
    vncodusur                      pcpedc.codusur%TYPE;
    vncondvenda                    pcpedc.condvenda%TYPE;
    vsusasaldocontacorrentedescfin pcpedc.usasaldocontacorrentedescfin%TYPE;
    vstipomovccrca                 pcpedc.tipomovccrca%TYPE;
    vnperdescfin                   pcpedc.perdescfin%TYPE;
    vscodfilial                    pcpedc.codfilial%TYPE;
    vnnumped                       pcpedc.numped%TYPE;
    vicontador                     NUMBER;
    vnvlsaldo                      NUMBER;
    vndescmax                      NUMBER;
    vnfixo                         NUMBER;
    vncreditosaldorca              NUMBER;

  BEGIN
    vsmensagem := 'OK';

    FOR reg IN (SELECT numtransvenda, dtfechaccrca
                  FROM pcnfsaid
                 WHERE caixa = p_numcheckout
                   AND codemitente = p_codfunccheckout
                   AND dtsaida = p_dataemissao
                      --Tarefa 105946
                   AND EXISTS
                 (select pcpedc.numtransvenda
                          from pcpedc
                         where pcpedc.numtransvenda = pcnfsaid.numtransvenda)
                   AND pcnfsaid.dtcancel is null) LOOP
      vbvalido := ccrca_verificar_fechamento(reg.numtransvenda);

      IF vbvalido = TRUE THEN
        IF reg.dtfechaccrca IS NULL THEN
          SELECT pcnfsaid.codusur,
                 pcpedc.condvenda,
                 pcpedc.usasaldocontacorrentedescfin,
                 pcpedc.tipomovccrca,
                 pcpedc.perdescfin,
                 pcpedc.codfilial,
                 pcpedc.numped
            INTO vncodusur,
                 vncondvenda,
                 vsusasaldocontacorrentedescfin,
                 vstipomovccrca,
                 vnperdescfin,
                 vscodfilial,
                 vnnumped
            FROM pcpedc, pcnfsaid
           WHERE pcpedc.numped = pcnfsaid.numped
             AND pcnfsaid.numtransvenda = reg.numtransvenda;

          -- Tarefa 99976
          IF (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
             (NVL(vsusasaldocontacorrentedescfin, 'N') = 'S') THEN
            vbvalido := TRUE;
          END IF;
          -- Fim tarefa 99976

          IF NOT (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
             ((NVL(vsusasaldocontacorrentedescfin, 'N')) = 'S') THEN
            SELECT COUNT(*)
              INTO vicontador
              FROM pcsaldorca
             WHERE codusur = vncodusur;

            IF vicontador = 0 THEN
              INSERT INTO pcsaldorca
                (codusur, vlsaldo, vlsaldoant)
              VALUES
                (vncodusur, 0, 0);
            END IF;

            SELECT NVL(vlsaldo, 0)
              INTO vnvlsaldo
              FROM pcsaldorca
             WHERE codusur = vncodusur
               FOR UPDATE;

            --RBD10
            SELECT NVL(descmax, 0), NVL(fixo, 0)
              INTO vndescmax, vnfixo
              FROM pcparamsaldo
             WHERE ROWNUM = 1;

            vncreditosaldorca := 0;

            --alteração feita para evitar erro de divisor 0
            begin

              SELECT SUM(((((vndescmax - pcpedi.perdesc) / vnfixo -
                         tab.percacresc) / 100) * pcpedi.pvenda) -- Pablo 16/12/2009
                         * pcpedi.qt)
                INTO vncreditosaldorca
                FROM pcpedi,
                     (SELECT pcfaixadesc.percacresc,
                             pcfaixadesc.percinicio,
                             pcfaixadesc.percfim
                        FROM pcfaixadesc) tab
               WHERE pcpedi.numped = vnnumped
                 AND pcpedi.qt > 0
                 AND pcpedi.perdesc BETWEEN tab.percinicio AND tab.percfim;

            exception
              when others then
                vncreditosaldorca := 0;

            end;

            IF NVL(vncreditosaldorca, 0) < 0 THEN
              vncreditosaldorca := 0;
            END IF;

            INSERT INTO pcmovsaldorca
              (DATA,
               codfunc,
               codusur,
               rotina,
               tipo,
               valor,
               vlsaldoant,
               vlsaldo,
               historico,
               numtransvenda)
            VALUES
              (SYSDATE,
               p_codfunclanc,
               vncodusur,
               p_rotinalanc,
               'C',
               NVL(vncreditosaldorca, 0),
               vnvlsaldo,
               (vnvlsaldo + NVL(vncreditosaldorca, 0)),
               'MOVIMENTO CARGA',
               reg.numtransvenda);

            UPDATE pcsaldorca
               SET vlsaldoant = vnvlsaldo,
                   vlsaldo    = (vnvlsaldo + NVL(vncreditosaldorca, 0))
             WHERE codusur = vncodusur;

            UPDATE pcnfsaid
               SET dtfechaccrca = SYSDATE
             WHERE numtransvenda = reg.numtransvenda;

            vbvalido := TRUE;
          END IF;
        END IF;
      END IF;
    END LOOP;

    p_mensagem := vsmensagem;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao lancar movimento caixa.' || SQLCODE || ' ' ||
                    SQLERRM;
  END; --ccfinrca_lanca_movimento_caixa

  --Projeto 90992 - RBD15
  FUNCTION ccfinrca_devolve_notafiscal(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                       p_rotinalanc  IN pclogrca.rotina%TYPE,
                                       p_codusur     IN pcnfent.codusurdevol%TYPE,
                                       p_numtransent IN pcnfent.numtransent%TYPE,
                                       p_mensagem    OUT VARCHAR2)
    RETURN BOOLEAN IS
    vsmanterdebitodescfin          pctabdev.manterdebitodescfin%TYPE;
    vsmantercredito                pctabdev.mantercredito%TYPE;
    vnnumped                       pcpedc.numped%TYPE;
    vstipomovccrca                 pcpedc.tipomovccrca%TYPE;
    vncondvenda                    pcpedc.condvenda%TYPE;
    vsusasaldocontacorrentedescfin pcpedc.usasaldocontacorrentedescfin%TYPE;
    vnperdescfin                   pcpedc.perdescfin%TYPE;
    vncodusur                      pcpedc.codusur%TYPE;
    vnnumtransvenda                pcpedc.numtransvenda%TYPE;
    vicontador                     NUMBER;
    vnvlsaldo                      NUMBER;
    vncreditosaldorca              NUMBER;
    vndebitosaldorca               NUMBER;
    vbvalido                       BOOLEAN;
    vsmensagem                     VARCHAR2(300);
    vbnotaacertada                 BOOLEAN;
    vndescmax                      NUMBER;
    vnfixo                         NUMBER;

  BEGIN
    vbvalido   := FALSE;
    vsmensagem := 'OK';

    SELECT NVL(manterdebitodescfin, 'N'), NVL(mantercredito, 'N')
      INTO vsmanterdebitodescfin, vsmantercredito
      FROM pctabdev, pcnfent
     WHERE pctabdev.coddevol = pcnfent.coddevol
       AND pcnfent.numtransent = p_numtransent;

    SELECT pcpedc.numped,
           pcpedc.tipomovccrca,
           pcpedc.condvenda,
           pcpedc.usasaldocontacorrentedescfin,
           pcpedc.perdescfin,
           pcpedc.codusur,
           pcnfsaid.numtransvenda
      INTO vnnumped,
           vstipomovccrca,
           vncondvenda,
           vsusasaldocontacorrentedescfin,
           vnperdescfin,
           vncodusur,
           vnnumtransvenda
      FROM pcpedc, pcnfsaid, pcnfent, pcestcom
     WHERE pcestcom.numtransent = p_numtransent
       AND pcestcom.numtransent = pcnfent.numtransent --Correcao em 11/12/2009
       AND pcestcom.numtransvenda = pcnfsaid.numtransvenda
       AND pcnfsaid.numped = pcpedc.numped;

    -- Tarefa 99976
    IF (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       (NVL(vsusasaldocontacorrentedescfin, 'N') = 'S') THEN
      vbvalido := TRUE;
    END IF;
    -- Fim tarefa 99976

    IF vsmanterdebitodescfin = 'N' THEN
      IF NOT (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
         (NVL(vsusasaldocontacorrentedescfin, 'N') = 'S') THEN
        IF NVL(vnperdescfin, 0) > 0 THEN
          --RBD11
          SELECT COUNT(*)
            INTO vicontador
            FROM pcsaldorca
           WHERE codusur = vncodusur;

          IF vicontador = 0 THEN
            INSERT INTO pcsaldorca
              (codusur, vlsaldo, vlsaldoant)
            VALUES
              (vncodusur, 0, 0);
          END IF;

          SELECT NVL(vlsaldo, 0)
            INTO vnvlsaldo
            FROM pcsaldorca
           WHERE codusur = vncodusur
             FOR UPDATE;

          vncreditosaldorca := 0;

          SELECT (SUM(NVL(pcmov.punit, 0) * NVL(pcmov.qt, 0))) *
                 (vnperdescfin) / 100
            INTO vncreditosaldorca
            FROM pcmov
           WHERE numtransent = p_numtransent
             AND NVL(qt, 0) > 0;

          IF NVL(vncreditosaldorca, 0) < 0 THEN
            vncreditosaldorca := 0;
          END IF;

          INSERT INTO pcmovsaldorca
            (DATA,
             codfunc,
             codusur,
             rotina,
             tipo,
             valor,
             vlsaldoant,
             vlsaldo,
             historico,
             numtransent,
             numped)
          VALUES
            (SYSDATE,
             p_codfunclanc,
             vncodusur,
             p_rotinalanc,
             'C',
             NVL(vncreditosaldorca, 0),
             vnvlsaldo,
             (vnvlsaldo + NVL(vncreditosaldorca, 0)),
             'DEVOLUCAO CLIENTE',
             p_numtransent,
             vnnumped);

          UPDATE pcsaldorca
             SET vlsaldoant = vnvlsaldo,
                 vlsaldo    = (vnvlsaldo + NVL(vncreditosaldorca, 0))
           WHERE codusur = vncodusur;

          vbvalido := TRUE;
        END IF;
      END IF;
    END IF;

    IF vsmantercredito = 'N' THEN
      IF (NVL(vstipomovccrca, 'VV') = 'VA') THEN
        vbnotaacertada := ccrca_verificar_fechamento(vnnumtransvenda);
      END IF;

      IF vbnotaacertada = TRUE OR (NVL(vstipomovccrca, 'VV') <> 'VA') THEN
        --RBD10
        SELECT COUNT(*)
          INTO vicontador
          FROM pcsaldorca
         WHERE codusur = vncodusur;

        IF vicontador = 0 THEN
          INSERT INTO pcsaldorca
            (codusur, vlsaldo, vlsaldoant)
          VALUES
            (vncodusur, 0, 0);
        END IF;

        SELECT NVL(vlsaldo, 0)
          INTO vnvlsaldo
          FROM pcsaldorca
         WHERE codusur = vncodusur
           FOR UPDATE;

        SELECT NVL(descmax, 0), NVL(fixo, 0)
          INTO vndescmax, vnfixo
          FROM pcparamsaldo
         WHERE ROWNUM = 1;

        vndebitosaldorca := 0;

        --alteração feita para evitar erro de divisor 0
        begin

          SELECT SUM(((((vndescmax - pcmov.percdesc) / vnfixo -
                     tab.percacresc) / 100) * pcmov.punit) -- Pablo 16/12/2009
                     * pcmov.qt)
            INTO vndebitosaldorca
            FROM pcmov,
                 (SELECT pcfaixadesc.percacresc,
                         pcfaixadesc.percinicio,
                         pcfaixadesc.percfim
                    FROM pcfaixadesc) tab
           WHERE pcmov.numtransent = p_numtransent
             AND pcmov.qt > 0
             AND pcmov.percdesc BETWEEN tab.percinicio AND tab.percfim;

        exception
          when others then
            vndebitosaldorca := 0;

        end;

        IF NVL(vndebitosaldorca, 0) < 0 THEN
          vndebitosaldorca := 0;
        END IF;

        INSERT INTO pcmovsaldorca
          (DATA,
           codfunc,
           codusur,
           rotina,
           tipo,
           valor,
           vlsaldoant,
           vlsaldo,
           historico,
           numtransent)
        VALUES
          (SYSDATE,
           p_codfunclanc,
           vncodusur,
           p_rotinalanc,
           'D',
           NVL(vndebitosaldorca, 0) * (-1),
           vnvlsaldo,
           (vnvlsaldo - NVL(vndebitosaldorca, 0)),
           'DEVOLUCAO CLIENTE',
           p_numtransent);

        UPDATE pcsaldorca
           SET vlsaldoant = vnvlsaldo,
               vlsaldo    = (vnvlsaldo - NVL(vndebitosaldorca, 0))
         WHERE codusur = vncodusur;

        vbvalido := TRUE;
      END IF;
    END IF;

    p_mensagem := vsmensagem;
    RETURN vbvalido;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao devolver Nota Fiscal : ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END; --ccfinrca_devolve_notafiscal

  --Projeto 90992 - RBD16
  FUNCTION ccfinrca_cancela_devolucao(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                      p_rotinalanc  IN pclogrca.rotina%TYPE,
                                      p_codusur     IN pcnfent.codusurdevol%TYPE,
                                      p_numtransent IN pcnfent.numtransent%TYPE,
                                      p_mensagem    OUT VARCHAR2)
    RETURN BOOLEAN IS
    vbvalido                       BOOLEAN;
    vsmensagem                     VARCHAR2(300);
    vnnumped                       pcpedc.numped%TYPE;
    vstipomovccrca                 pcpedc.tipomovccrca%TYPE;
    vncondvenda                    pcpedc.condvenda%TYPE;
    vsusasaldocontacorrentedescfin pcpedc.usasaldocontacorrentedescfin%TYPE;
    vnperdescfin                   pcpedc.perdescfin%TYPE;
    vncodusur                      pcpedc.codusur%TYPE;
    vnnumtransvenda                pcnfsaid.numtransvenda%TYPE;
    vicontador                     NUMBER;
    vnvalor                        NUMBER;
    vnvlsaldo                      NUMBER;
    vnvalordebito                  NUMBER;
    vnvalorcredito                 NUMBER;
  BEGIN
    vbvalido   := TRUE;
    vsmensagem := 'OK';

    SELECT pcpedc.numped,
           pcpedc.tipomovccrca,
           pcpedc.condvenda,
           pcpedc.usasaldocontacorrentedescfin,
           pcpedc.perdescfin,
           pcpedc.codusur,
           pcnfsaid.numtransvenda
      INTO vnnumped,
           vstipomovccrca,
           vncondvenda,
           vsusasaldocontacorrentedescfin,
           vnperdescfin,
           vncodusur,
           vnnumtransvenda
      FROM pcpedc, pcnfsaid, pcnfent, pcestcom
     WHERE pcestcom.numtransent = p_numtransent
       AND pcestcom.numtransent = pcnfent.numtransent
       AND pcestcom.numtransvenda = pcnfsaid.numtransvenda
       AND pcnfsaid.numped = pcpedc.numped;

    SELECT COUNT(*)
      INTO vicontador
      FROM pcmovsaldorca
     WHERE numtransent = p_numtransent
       AND tipo = 'C';

    IF vicontador <> 0 THEN
      SELECT valor
        INTO vnvalor
        FROM pcmovsaldorca
       WHERE numtransent = p_numtransent
         AND tipo = 'C';

      SELECT COUNT(*)
        INTO vicontador
        FROM pcsaldorca
       WHERE codusur = vncodusur;

      IF vicontador = 0 THEN
        INSERT INTO pcsaldorca
          (codusur, vlsaldo, vlsaldoant)
        VALUES
          (vncodusur, 0, 0);
      END IF;

      SELECT NVL(vlsaldo, 0)
        INTO vnvlsaldo
        FROM pcsaldorca
       WHERE codusur = vncodusur
         FOR UPDATE;

      vnvalordebito := vnvalor * (-1);

      INSERT INTO pcmovsaldorca
        (DATA,
         codfunc,
         codusur,
         rotina,
         tipo,
         valor,
         vlsaldoant,
         vlsaldo,
         historico,
         numtransent)
      VALUES
        (SYSDATE,
         p_codfunclanc,
         vncodusur,
         p_rotinalanc,
         'D',
         vnvalordebito,
         vnvlsaldo,
         (vnvlsaldo + (vnvalordebito)),
         'CANCELAMENTO DEV. CLIENTE',
         p_numtransent);

      UPDATE pcsaldorca
         SET vlsaldoant = vnvlsaldo,
             vlsaldo    = (vnvlsaldo + (vnvalordebito))
       WHERE codusur = vncodusur;
    END IF;

    SELECT COUNT(*)
      INTO vicontador
      FROM pcmovsaldorca
     WHERE numtransent = p_numtransent
       AND tipo = 'D'
       and rotina <> p_rotinalanc;

    IF vicontador <> 0 THEN
      SELECT valor
        INTO vnvalor
        FROM pcmovsaldorca
       WHERE numtransent = p_numtransent
         AND tipo = 'D'
         and rotina <> p_rotinalanc;

      SELECT NVL(vlsaldo, 0)
        INTO vnvlsaldo
        FROM pcsaldorca
       WHERE codusur = vncodusur
         FOR UPDATE;

      vnvalordebito := vnvalor * (-1);

      INSERT INTO pcmovsaldorca
        (DATA,
         codfunc,
         codusur,
         rotina,
         tipo,
         valor,
         vlsaldoant,
         vlsaldo,
         historico,
         numtransent)
      VALUES
        (SYSDATE,
         p_codfunclanc,
         vncodusur,
         p_rotinalanc,
         'C',
         vnvalordebito,
         vnvlsaldo,
         (vnvlsaldo + (vnvalordebito)),
         'CANCELAMENTO DEV. CLIENTE',
         p_numtransent);

      UPDATE pcsaldorca
         SET vlsaldoant = vnvlsaldo,
             vlsaldo    = (vnvlsaldo + (vnvalordebito))
       WHERE codusur = vncodusur;
    END IF;

    p_mensagem := vsmensagem;
    RETURN vbvalido;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao cancelar devolucao : ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END; -- ccfinrca_cancela_devolucao

  --RNG10
  FUNCTION ccrca_excluir_item_pedido(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                     p_rotinalanc  IN pclogrca.rotina%TYPE,
                                     p_codusur     IN pcpedc.codusur%TYPE,
                                     p_numped      IN pcpedc.numped%TYPE,
                                     p_codprod     IN pcpedi.codprod%TYPE,
                                     p_numseq      IN pcpedi.numseq%TYPE,
                                     p_qtanterior  IN NUMBER) RETURN BOOLEAN IS
    vbvalido BOOLEAN;
  BEGIN
    vbvalido := FALSE;
    vbvalido := ccrca_estorna_item_pedido(p_codfunclanc,
                                          p_rotinalanc,
                                          p_codusur,
                                          p_numped,
                                          p_codprod,
                                          p_numseq,
                                          p_qtanterior);
    RETURN(vbvalido);
  END; --ccrca_excluir_item_pedido

  --RNG11
  FUNCTION ccrca_alterar_preco_qt(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                  p_rotinalanc  IN pclogrca.rotina%TYPE,
                                  p_codusur     IN pcpedc.codusur%TYPE,
                                  p_numped      IN pcpedc.numped%TYPE,
                                  p_codprod     IN pcpedi.codprod%TYPE,
                                  p_numseq      IN pcpedi.numseq%TYPE,
                                  p_qtanterior  IN NUMBER) RETURN BOOLEAN IS
    vnqt     pcpedi.qt%TYPE;
    vbvalido BOOLEAN;
  BEGIN
    vbvalido := FALSE;

    -- Verifica se pode movimentar conta corrente do RCA
    if (CONTROLASALDORCA(p_numped) = 'N') then
      return(FALSE);
    end if;

    SELECT qt
      INTO vnqt
      FROM pcpedi
     WHERE numped = p_numped
       AND codprod = p_codprod
       AND numseq = p_numseq;

    IF vnqt > 0 THEN
      if p_rotinalanc <> 1401 then
        vbvalido := ccrca_estorna_item_pedido(p_codfunclanc,
                                              p_rotinalanc,
                                              p_codusur,
                                              p_numped,
                                              p_codprod,
                                              p_numseq,
                                              p_qtanterior);
      end if;
      vbvalido := ccrca_incluir_item_pedido(p_codfunclanc,
                                            p_rotinalanc,
                                            p_codusur,
                                            p_numped,
                                            p_codprod,
                                            p_numseq);
    END IF;

    IF vnqt = 0 THEN
      vbvalido := ccrca_excluir_item_pedido(p_codfunclanc,
                                            p_rotinalanc,
                                            p_codusur,
                                            p_numped,
                                            p_codprod,
                                            p_numseq,
                                            p_qtanterior);
    END IF;

    RETURN(vbvalido);
  END; --ccrca_alterar_preco_qt

  FUNCTION ccrca_alterar_preco(p_codfunclanc      IN pclogrca.codfunc%TYPE,
                               p_rotinalanc       IN pclogrca.rotina%TYPE,
                               p_codusur          IN pcpedc.codusur%TYPE,
                               p_numped           IN pcpedc.numped%TYPE,
                               p_codprod          IN pcpedi.codprod%TYPE,
                               p_numseq           IN pcpedi.numseq%TYPE,
                               p_qtanterior       IN NUMBER,
                               p_pvendaanterior   IN NUMBER,
                               p_pbasercaanterior IN NUMBER,
                               p_ptabelaanterior  IN NUMBER) RETURN BOOLEAN IS
    vnqt                 pcpedi.qt%TYPE;
    vsusadebcredrcabrind pcpedi.usadebcredrcabrind%TYPE;
    vbvalido             BOOLEAN;
    vnvalorlanc          NUMBER;
    vnvlcorrente_ant     PCGERENTE.vlcorrente%TYPE;
    vsusadebcredrca      pcusuari.usadebcredrca%TYPE;
    vnvllimcred          PCGERENTE.vllimcred%TYPE;
    vnvlcorrente_atual   PCGERENTE.vlcorrente%TYPE;
    vddata               pcpedc.DATA%TYPE;
    vnnumtransvenda      pcpedc.numtransvenda%TYPE;
    vsposicao            pcpedc.posicao%TYPE;
    vstipocontacorrente pcpedc.tipocontacorrente%TYPE;
    vnCodigoGerente     pcgerente.codgerente%TYPE;
    vnCodigoSupervisor  pcsuperv.codsupervisor%TYPE;
  BEGIN
    vbvalido := FALSE;

    -- Verifica se pode movimentar conta corrente do RCA
    if (CONTROLASALDORCA(p_numped) = 'N') then
      return(FALSE);
    end if;

    if p_pbasercaanterior is null then
       vrPARAMETROS.Data := sysdate;
       vrPARAMETROS.Rotina := p_rotinalanc;
       vrPARAMETROS.Historico := 'ERRO AO MOVIMENTAR SALDO RCA (ccrca_alterar_preco) o parâmetro "p_pbasercaanterior" está null ';
       vrPARAMETROS.Numped := p_numped;
       vrPARAMETROS.Codprod := p_codprod;
       GravarLog(vrPARAMETROS);
    end if;

    SELECT qt, NVL(usadebcredrcabrind, 'N')
      INTO vnqt, vsusadebcredrcabrind
      FROM pcpedi
     WHERE numped = p_numped
       AND codprod = p_codprod
       AND numseq = p_numseq;

    IF vnqt > 0 THEN
      SELECT pcpedc.DATA, pcpedc.numtransvenda, pcpedc.posicao, nvl(pcpedc.tipocontacorrente, 'R')
        INTO vddata, vnnumtransvenda, vsposicao, vstipocontacorrente
        FROM pcpedc
       WHERE numped = p_numped;

    ccrca_bloquear_registro_rca(p_codusur);

  --VEN-2604 - Inicio
    SELECT CASE WHEN vstipocontacorrente = 'S'
                THEN NVL(PCSUPERV.USADEBCRED,'S')
                WHEN vstipocontacorrente = 'G'
                THEN NVL(PCGERENTE.USADEBCRED,'S')
                ELSE NVL(PCUSUARI.USADEBCREDRCA,'S')
           END USADEBCRED
         , CASE WHEN vstipocontacorrente = 'S'
                THEN NVL(PCSUPERV.VLCORRENTE,0)
                WHEN vstipocontacorrente = 'G'
                THEN NVL(PCGERENTE.VLCORRENTE,0)
                ELSE NVL(PCUSUARI.VLCORRENTE,0)
           END VLCORRENTE
         , CASE WHEN vstipocontacorrente = 'S'
                THEN NVL(PCSUPERV.VLLIMCRED,0)
                WHEN vstipocontacorrente = 'G'
                THEN NVL(PCGERENTE.VLLIMCRED,0)
                ELSE NVL(PCUSUARI.VLLIMCRED,0)
           END VLLIMCRED
         , PCSUPERV.CODSUPERVISOR
         , PCGERENTE.CODGERENTE
      INTO vsusadebcredrca
         , vnvlcorrente_ant
         , vnvllimcred
         , vnCodigoSupervisor
         , vnCodigoGerente
      FROM PCPEDC
     INNER JOIN PCUSUARI ON (PCUSUARI.CODUSUR       = PCPEDC.CODUSUR)
     INNER JOIN PCSUPERV ON (PCSUPERV.CODSUPERVISOR = NVL(PCPEDC.CODSUPERVISOR, PCUSUARI.CODSUPERVISOR))
      LEFT JOIN PCGERENTE ON (PCGERENTE.CODGERENTE   = NVL(PCPEDC.CODGERENTE, PCSUPERV.CODGERENTE))
     WHERE PCPEDC.NUMPED = p_numped;

      vnvalorlanc := ccrca_retorna_saldo_anterior(p_numped,
                                                  p_codusur,
                                                  p_codprod,
                                                  p_numseq,
                                                  p_qtanterior,
                                                  p_pvendaanterior,
                                                  p_pbasercaanterior,
                                                  p_ptabelaanterior,
                                                  'E',
                                                  vsusadebcredrcabrind);
      -- incluído por sabrina ( E - Estorno)
      vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) - NVL(vnvalorlanc, 0);

      -- a package não deve barrar a movimentacao do saldo, os programas eh que fazem isso
      --IF vnvlcorrente_atual >= 0 THEN
  --IF vnvlcorrente_atual >= 0 THEN
    if vstipocontacorrente = 'G' then
      UPDATE pcgerente
         SET vlcorrente = vnvlcorrente_atual
       WHERE codgerente = vnCodigoGerente;
    ELSIF vstipocontacorrente = 'S' then
      UPDATE pcsuperv
         SET vlcorrente = vnvlcorrente_atual
       WHERE codsupervisor = vnCodigoSupervisor;
    else
      UPDATE pcusuari
         SET vlcorrente = vnvlcorrente_atual
       WHERE codusur = p_codusur;
    end if;

      INSERT INTO pclogdebcred
        (numped,
         posicao,
         numtransvenda,
         tipocontacorrente,
         DATA,
         codfunc,
         codigo,
         rotina,
         vlcorrente,
         vllimcred,
         vlcorrenteant,
         vllimcredant,
         codprod,
         numseq,
         historico)
      VALUES
        (p_numped,
         vsposicao,
         vnnumtransvenda,
         vstipocontacorrente,
         SYSDATE,
         p_codfunclanc,
         decode(vstipocontacorrente, 'S', vnCodigoSupervisor, 'G', vnCodigoGerente, p_codusur),
         p_rotinalanc,
         vnvlcorrente_atual,
         vnvllimcred,
         vnvlcorrente_ant,
         vnvllimcred,
         p_codprod,
         p_numseq,
         SUBSTR('CTRLCCRCA: ESTORNO DE SALDO DE ITEM PEDIDO (Alterar Preco)', 1, 60));

    if (vstipocontacorrente <> 'S') and (vstipocontacorrente <> 'G') then
    INSERT INTO pclogrca
        (numped,
         posicao,
         numtransvenda,
         DATA,
         codfunc,
         codusur,
         rotina,
         vlcorrente,
         vllimcred,
         vlcorrenteant,
         vllimcredant,
         codprod,
         numseq,
         historico,
         seqlogrca)
      VALUES
        (p_numped,
         vsposicao,
         vnnumtransvenda,
         SYSDATE,
         p_codfunclanc,
         p_codusur,
         p_rotinalanc,
         vnvlcorrente_atual,
         vnvllimcred,
         vnvlcorrente_ant,
         vnvllimcred,
         p_codprod,
         p_numseq,
         SUBSTR('CTRLCCRCA: ESTORNO DE SALDO DE ITEM PEDIDO (Alterar Preco)', 1, 60),
         DFSEQ_PCLOGRCA.NEXTVAL);
      END IF;

      vbvalido := ccrca_incluir_item_pedido(p_codfunclanc,
                                            p_rotinalanc,
                                            p_codusur,
                                            p_numped,
                                            p_codprod,
                                            p_numseq);
    END IF;

    IF vnqt = 0 THEN
      vbvalido := ccrca_excluir_item_pedido(p_codfunclanc,
                                            p_rotinalanc,
                                            p_codusur,
                                            p_numped,
                                            p_codprod,
                                            p_numseq,
                                            p_qtanterior);
    END IF;

    RETURN(vbvalido);
  END; --ccrca_alterar_preco_qt

  --RNG12
  FUNCTION ccrca_retornar_saldo_item_nf(p_numtransvenda IN pcmov.numtransvenda%TYPE,
                                        p_codprod       IN pcmov.codprod%TYPE,
                                        p_numseq        IN pcmov.numseq%TYPE,
                                        p_qt            IN NUMBER,
                                        p_tipo          IN VARCHAR) -- Sabrina: tipo de operação I - Inclusao e E - Exclusao
   RETURN NUMBER IS
    vnvalorlanc                 NUMBER;
    vstipo                      VARCHAR2(1);
    vnnumped                    pcpedc.numped%TYPE;
    vncodusur                   pcpedc.codusur%TYPE;
    vsusacredrca                pcpedc.usacredrca%TYPE;
    vsbonificaltdebcredrca      pcpedc.bonificaltdebcredrca%TYPE;
    vstrocaaltdebcredrca        pcpedc.trocaaltdebcredrca%TYPE;
    vsbrokeraltdebcredrca       pcpedc.brokeraltdebcredrca%TYPE;
    vscrmaltdebcredrca          pcpedc.crmaltdebcredrca%TYPE;
    vstipomovccrca              pcpedc.tipomovccrca%TYPE;
    vsusadebcredrca             pcpedc.usadebcredrca%TYPE;
    vsorigemped                 pcpedc.origemped%TYPE;
    vsbrinde                    pcpedc.brinde%TYPE;
    vncondvenda                 pcpedc.condvenda%TYPE;
    vsbroker                    pcpedc.broker%TYPE;
    vscodcob                    pcpedc.codcob%type; --HIS.03429.2014
    vsusadebcredrca_rca         pcusuari.usadebcredrca%TYPE;
    vnpunit                     pcmov.punit%TYPE;
    vnptabela                   pcmov.ptabela%TYPE;
    vnpbaserca                  pcmov.pbaserca%TYPE;
    vsusadebcredrcabrind        pcmov.usadebcredrcabrind%TYPE;
    vsmsg                       VARCHAR2(400);
    vbfechado                   BOOLEAN;
    vsmovimentacontacorrenterca pcmov.movimentacontacorrenterca%type;
    vsbonific                   PCMOVCOMPLE.BONIFIC%TYPE;
    vstipocontacorrente         pcnfsaid.tipocontacorrente%TYPE;
    A                           NUMBER;
	vbvalidoNota                BOOLEAN;
	vbvalidoPedido              BOOLEAN;
  BEGIN
    proc_lerparametros(vsmsg);
	vbvalidoNota   := TRUE;
	vbvalidoPedido := TRUE;

    BEGIN
      SELECT DISTINCT NUMPED, TIPOCONTACORRENTE, A
        INTO VNNUMPED, VSTIPOCONTACORRENTE, A
        FROM (SELECT DISTINCT NUMPED, NVL(PCNFSAID.TIPOCONTACORRENTE, 'R') TIPOCONTACORRENTE, 1 A
                FROM PCNFSAID
               WHERE NUMTRANSVENDA = P_NUMTRANSVENDA
              UNION
              SELECT DISTINCT NUMPED, NVL(PCNFSAID.TIPOCONTACORRENTE, 'R') TIPOCONTACORRENTE, 2 A
                FROM PCNFSAIDPREFAT PCNFSAID
               WHERE NUMTRANSVENDA = P_NUMTRANSVENDA)
       WHERE ROWNUM = 1
       ORDER BY A;

    EXCEPTION
      WHEN OTHERS THEN
        vbvalidoNota := FALSE;
    END;

    BEGIN
      SELECT p.usacredrca,
             p.bonificaltdebcredrca,
             p.trocaaltdebcredrca,
             p.brokeraltdebcredrca,
             p.crmaltdebcredrca,
             p.tipomovccrca,
             p.usadebcredrca,
  /*           DECODE(p.usadebcredrca,
                    NULL,
                    (SELECT NVL(pcusuari.usadebcredrca, gregpcconsum.usacredrca)
                       FROM pcusuari
                      WHERE codusur = p.codusur
                        AND ROWNUM = 1),
                    p.usadebcredrca),*/
             p.origemped,
             p.brinde,
             p.condvenda,
             p.broker,
             p.codusur,
             p.codcob
        INTO vsusacredrca,
             vsbonificaltdebcredrca,
             vstrocaaltdebcredrca,
             vsbrokeraltdebcredrca,
             vscrmaltdebcredrca,
             vstipomovccrca,
             vsusadebcredrca,
             vsorigemped,
             vsbrinde,
             vncondvenda,
             vsbroker,
             vncodusur,
             vscodcob
        FROM pcpedc p
       WHERE p.numped = vnnumped;    

       IF vsusadebcredrca IS NULL THEN
          SELECT CASE WHEN vstipocontacorrente = 'S' 
                      THEN NVL(PCSUPERV.USADEBCRED,gregpcconsum.usacredsupervisor)
                      WHEN vstipocontacorrente = 'G' 
                      THEN NVL(PCGERENTE.USADEBCRED,gregpcconsum.usacredgerente)                
                      ELSE NVL(PCUSUARI.USADEBCREDRCA,gregpcconsum.usacredrca)
                 END USADEBCRED
            INTO vsusadebcredrca
           FROM PCPEDC
          INNER JOIN PCUSUARI ON (PCUSUARI.CODUSUR       = PCPEDC.CODUSUR)
          INNER JOIN PCSUPERV ON (PCSUPERV.CODSUPERVISOR = NVL(PCPEDC.CODSUPERVISOR, PCUSUARI.CODSUPERVISOR))
           LEFT JOIN PCGERENTE ON (PCGERENTE.CODGERENTE   = NVL(PCPEDC.CODGERENTE, PCSUPERV.CODGERENTE))
           WHERE PCPEDC.NUMPED = vnnumped;    
       END IF;
	 EXCEPTION
      WHEN OTHERS THEN
        vbvalidoPedido := FALSE;
    END;

/*    SELECT pcusuari.usadebcredrca
      INTO vsusadebcredrca_rca
      FROM pcusuari
     WHERE codusur = vncodusur;*/

    --HIS.03429.2014
    IF (vsbonificaltdebcredrca = 'S')
      AND (INSTR(UPPER(vscodcob),'BNF') > 0)
      AND (vncondvenda = 14)
      AND (vsbrinde = 'S')
	  AND (vbvalidoNota = TRUE)
	  AND (vbvalidoPedido = TRUE)
    THEN
      SELECT DADOS.PUNITCONT,
             DADOS.pbaserca,
             DADOS.ptabela,
             DADOS.usadebcredrcabrind,
             DADOS.movimentacontacorrenterca,
             DADOS.bonific
        INTO vnpunit,
             vnpbaserca,
             vnptabela,
             vsusadebcredrcabrind,
             vsmovimentacontacorrenterca,
             vsbonific
        FROM (SELECT pcmov.PUNITCONT,
                     pcmov.pbaserca,
                     pcmov.ptabela,
                     NVL(pcmov.usadebcredrcabrind, 'N') usadebcredrcabrind,
                     nvl(nvl(pcmov.movimentacontacorrenterca,
                             (select pcpedi.movimentacontacorrenterca from pcpedi
                               where pcpedi.numped = pcmov.numped
                                 and pcmov.codprod = pcpedi.codprod
                                 and pcmov.numseq = pcpedi.numseq)),
                         'S') movimentacontacorrenterca,
                     nvl(pcmovcomple.bonific, 'N') bonific,
                     1 A
                FROM pcmov, pcmovcomple
               WHERE numtransvenda = p_numtransvenda
                 AND pcmov.codprod = p_codprod
                 AND NVL(pcmovcomple.numseqorig, pcmov.numseq) = p_numseq
                 AND pcmov.qt > 0
                 AND pcmov.numtransitem = pcmovcomple.numtransitem(+)
               UNION
              SELECT pcmov.PUNITCONT,
                     pcmov.pbaserca,
                     pcmov.ptabela,
                     NVL(pcmov.usadebcredrcabrind, 'N') usadebcredrcabrind,
                     nvl(nvl(pcmov.movimentacontacorrenterca,
                             (select pcpedi.movimentacontacorrenterca from pcpedi
                               where pcpedi.numped = pcmov.numped
                                 and pcmov.codprod = pcpedi.codprod
                                 and pcmov.numseq = pcpedi.numseq)),
                         'S') movimentacontacorrenterca,
                     nvl(pcmovcomple.bonific, 'N') bonific,
                     2 A
                FROM pcmovprefat pcmov, pcmovcompleprefat pcmovcomple
               WHERE numtransvenda = p_numtransvenda
                 AND pcmov.codprod = p_codprod
                 AND NVL(pcmovcomple.numseqorig, pcmov.numseq) = p_numseq
                 AND pcmov.qt > 0
                 AND pcmov.numtransitem = pcmovcomple.numtransitem(+)) DADOS
       WHERE ROWNUM = 1
       ORDER BY A;


    /*
    --HIS.03429.2014
      SELECT pcmov.PUNITCONT,
             pcmov.pbaserca,
             pcmov.ptabela,
             NVL(pcmov.usadebcredrcabrind, 'N'),
             nvl(nvl(pcmov.movimentacontacorrenterca,
                     (select pcpedi.movimentacontacorrenterca from pcpedi
                       where pcpedi.numped = pcmov.numped
                         and pcmov.codprod = pcpedi.codprod
                         and pcmov.numseq = pcpedi.numseq)),
                 'S'),
             nvl(pcmovcomple.bonific, 'N') bonific
        INTO vnpunit,
             vnpbaserca,
             vnptabela,
             vsusadebcredrcabrind,
             vsmovimentacontacorrenterca,
             vsbonific
        FROM pcmov, pcmovcomple
       WHERE numtransvenda = p_numtransvenda
         AND pcmov.codprod = p_codprod
         AND NVL(pcmovcomple.numseqorig, pcmov.numseq) = p_numseq
         AND pcmov.qt > 0
         AND pcmov.numtransitem = pcmovcomple.numtransitem(+); */
    ELSE
      SELECT DADOS.PUNIT
            ,DADOS.PBASERCA
            ,DADOS.PTABELA
            ,DADOS.USADEBCREDRCABRIND
            ,DADOS.MOVIMENTACONTACORRENTERCA
            ,DADOS.BONIFIC
        INTO VNPUNIT
            ,VNPBASERCA
            ,VNPTABELA
            ,VSUSADEBCREDRCABRIND
            ,VSMOVIMENTACONTACORRENTERCA
            ,VSBONIFIC
        FROM (SELECT DECODE(VNCONDVENDA,
                            5,
                            PCMOV.PUNITCONT,
                            11,
                            PCMOV.PUNITCONT,
                            1,
                            (DECODE(NVL(PCMOV.PBONIFIC, 0),
                                    0,
                                    PCMOV.PUNIT,
                                    PCMOV.PBONIFIC)),
                            PCMOV.PUNIT) PUNIT
                    ,PCMOV.PBASERCA
                    ,PCMOV.PTABELA
                    ,NVL(PCMOV.USADEBCREDRCABRIND, 'N') USADEBCREDRCABRIND
                    ,NVL(NVL(PCMOV.MOVIMENTACONTACORRENTERCA,
                             (SELECT PCPEDI.MOVIMENTACONTACORRENTERCA
                                FROM PCPEDI
                               WHERE PCPEDI.NUMPED = PCMOV.NUMPED
                                 AND PCMOV.CODPROD = PCPEDI.CODPROD
                                 AND PCMOV.NUMSEQ = PCPEDI.NUMSEQ)),
                         'S') MOVIMENTACONTACORRENTERCA
                    ,NVL(PCMOVCOMPLE.BONIFIC, 'N') BONIFIC
                    ,1 A
                FROM PCMOV, PCMOVCOMPLE
               WHERE NUMTRANSVENDA = P_NUMTRANSVENDA
                 AND PCMOV.CODPROD = P_CODPROD
                 AND NVL(PCMOVCOMPLE.NUMSEQORIG, PCMOV.NUMSEQ) = P_NUMSEQ
                 AND PCMOV.QT > 0
                 AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
              UNION
              SELECT DECODE(VNCONDVENDA,
                            5,
                            PCMOV.PUNITCONT,
                            11,
                            PCMOV.PUNITCONT,
                            1,
                            (DECODE(NVL(PCMOV.PBONIFIC, 0),
                                    0,
                                    PCMOV.PUNIT,
                                    PCMOV.PBONIFIC)),
                            PCMOV.PUNIT) PUNIT
                    ,PCMOV.PBASERCA
                    ,PCMOV.PTABELA
                    ,NVL(PCMOV.USADEBCREDRCABRIND, 'N') USADEBCREDRCABRIND
                    ,NVL(NVL(PCMOV.MOVIMENTACONTACORRENTERCA,
                             (SELECT PCPEDI.MOVIMENTACONTACORRENTERCA
                                FROM PCPEDI
                               WHERE PCPEDI.NUMPED = PCMOV.NUMPED
                                 AND PCMOV.CODPROD = PCPEDI.CODPROD
                                 AND PCMOV.NUMSEQ = PCPEDI.NUMSEQ)),
                         'S') MOVIMENTACONTACORRENTERCA
                    ,NVL(PCMOVCOMPLE.BONIFIC, 'N') BONIFIC
                    ,2 A
                FROM PCMOVPREFAT PCMOV, PCMOVCOMPLEPREFAT PCMOVCOMPLE
               WHERE NUMTRANSVENDA = P_NUMTRANSVENDA
                 AND PCMOV.CODPROD = P_CODPROD
                 AND NVL(PCMOVCOMPLE.NUMSEQORIG, PCMOV.NUMSEQ) = P_NUMSEQ
                 AND PCMOV.QT > 0
                 AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)) DADOS
       WHERE ROWNUM = 1
       ORDER BY A;


      /*
      SELECT DECODE(vncondvenda,
                    5,
                    pcmov.punitcont,
                    11,
                    pcmov.punitcont,
                    1,
                    (decode(nvl(pcmov.pbonific,0),
                    0,
                    pcmov.punit,
                    pcmov.pbonific)),
                    pcmov.punit) punit,
             pcmov.pbaserca,
             pcmov.ptabela,
             NVL(pcmov.usadebcredrcabrind, 'N'),
             nvl(nvl(pcmov.movimentacontacorrenterca,
                     (select pcpedi.movimentacontacorrenterca from pcpedi
                       where pcpedi.numped = pcmov.numped
                         and pcmov.codprod = pcpedi.codprod
                         and pcmov.numseq = pcpedi.numseq)),
                 'S'),
             nvl(pcmovcomple.bonific, 'N') bonific
        INTO vnpunit,
             vnpbaserca,
             vnptabela,
             vsusadebcredrcabrind,
             vsmovimentacontacorrenterca,
             vsbonific
        FROM pcmov, pcmovcomple
       WHERE numtransvenda = p_numtransvenda
         AND pcmov.codprod = p_codprod
         AND NVL(pcmovcomple.numseqorig, pcmov.numseq) = p_numseq
         AND pcmov.qt > 0
         AND pcmov.numtransitem = pcmovcomple.numtransitem(+);*/
    END IF;

    vbfechado := ccrca_verificar_fechamento(p_numtransvenda);
    -- Teste de tipo de processo incluído por sabrina
    vstipo := 'F';

    -- Se a operação for de E - Exclusão       -- GUILHERME FREITAS
    -- Deyvid Costa: Se o código abaixo for comentado, ao cancelar uma nota fiscal, o saldo não é estornado.
    IF p_tipo = 'E' THEN
      vstipo := 'C';
    END IF;

    IF vbfechado = TRUE OR vstipomovccrca <> 'VA' THEN
      vnvalorlanc := ccrca_saldo_item(NVL(vsusacredrca,
                                          gregpcconsum.usacredrca),
                                      NVL(vsusadebcredrca,
                                          vsusadebcredrca_rca),
                                      vsbroker,
                                      vsorigemped,
                                      NVL(vsbonificaltdebcredrca,
                                          gregpcconsum.bonificaltdebcredrca),
                                      NVL(vstrocaaltdebcredrca,
                                          gregpcconsum.trocaaltdebcredrca),
                                      NVL(vscrmaltdebcredrca,
                                          gregpcconsum.crmaltdebcredrca),
                                      NVL(vsbrokeraltdebcredrca,
                                          gregpcconsum.brokeraltdebcredrca),
                                      NVL(vstipomovccrca,
                                          NVL(gregpcconsum.tipomovccrca, 'VV')),
                                      vncondvenda,
                                      vsbrinde,
                                      vncodusur,
                                      vstipo, --incluido por sabrina
                                      vnpunit,
                                      vnptabela,
                                      NVL(vnpbaserca, NVL(vnptabela, 0)),
                                      p_qt,
                                      vsusadebcredrcabrind,
                                      vsmovimentacontacorrenterca, --TESTE THIAGO
                                      vsbonific);
    ELSE
      vnvalorlanc := ccrca_saldo_item(NVL(vsusacredrca,
                                          gregpcconsum.usacredrca),
                                      NVL(vsusadebcredrca,
                                          vsusadebcredrca_rca),
                                      vsbroker,
                                      vsorigemped,
                                      NVL(vsbonificaltdebcredrca,
                                          gregpcconsum.bonificaltdebcredrca),
                                      NVL(vstrocaaltdebcredrca,
                                          gregpcconsum.trocaaltdebcredrca),
                                      NVL(vscrmaltdebcredrca,
                                          gregpcconsum.crmaltdebcredrca),
                                      NVL(vsbrokeraltdebcredrca,
                                          gregpcconsum.brokeraltdebcredrca),
                                      NVL(vstipomovccrca,
                                          NVL(gregpcconsum.tipomovccrca, 'VV')),
                                      vncondvenda,
                                      vsbrinde,
                                      vncodusur,
                                      'V', --incluido por sabrina
                                      vnpunit,
                                      vnptabela,
                                      NVL(vnpbaserca, NVL(vnptabela, 0)),
                                      p_qt,
                                      vsusadebcredrcabrind,
                                      vsmovimentacontacorrenterca,
                                      vsbonific);
    END IF;

    RETURN(vnvalorlanc);
  END; --ccrca_retornar_saldo_item_nf

  --RNG13
  FUNCTION ccrca_estornar_ccrca_item_nf(p_codfunclanc   IN pclogrca.codfunc%TYPE,
                                        p_rotinalanc    IN pclogrca.rotina%TYPE,
                                        p_codusur       IN pcpedc.codusur%TYPE,
                                        p_numtransvenda IN pcpedc.numtransvenda%TYPE,
                                        p_codprod       IN pcpedi.codprod%TYPE,
                                        p_numseq        IN pcpedi.numseq%TYPE,
                                        p_qt            IN NUMBER)
    RETURN BOOLEAN IS
    vnvalorlanc        NUMBER;
    vnnumped           pcpedc.numped%TYPE;
    vddata             pcpedc.DATA%TYPE;
    vsposicao          pcpedc.posicao%TYPE;
    vnvlcorrente_ant   PCGERENTE.vlcorrente%TYPE;
    vnvllimcred        PCGERENTE.vllimcred%TYPE;
    vnvlcorrente_atual PCGERENTE.vlcorrente%TYPE;
    vstipocontacorrente pcnfsaid.tipocontacorrente%TYPE;
    vnCodigoGerente     pcgerente.codgerente%TYPE;
    vnCodigoSupervisor  pcsuperv.codsupervisor%TYPE;
    vbvalido           BOOLEAN;
    A                  NUMBER;
  BEGIN
    vbvalido := TRUE; -- correcao sabrina

    BEGIN
      SELECT DISTINCT numped, tipocontacorrente, A
        INTO vnnumped, vstipocontacorrente, A
        FROM( SELECT DISTINCT numped, nvl(pcnfsaid.tipocontacorrente, 'R') tipocontacorrente, 1 A
                FROM pcnfsaid
               WHERE numtransvenda = p_numtransvenda
               UNION
              SELECT DISTINCT numped, nvl(pcnfsaid.tipocontacorrente, 'R')tipocontacorrente, 2 A
                FROM pcnfsaidprefat pcnfsaid
               WHERE numtransvenda = p_numtransvenda)
       WHERE ROWNUM = 1
       ORDER BY A;
      /*
      SELECT DISTINCT numped, nvl(pcnfsaid.tipocontacorrente, 'R')
        INTO vnnumped, vstipocontacorrente
        FROM pcnfsaid
       WHERE numtransvenda = p_numtransvenda;
       */
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    -- Verifica se pode movimentar conta corrente do RCA
    if (CONTROLASALDORCA(vnnumped) = 'N') then
      return(FALSE);
    end if;

    BEGIN
      SELECT p.DATA, p.posicao
        INTO vddata, vsposicao
        FROM pcpedc p
       WHERE p.numped = vnnumped;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    BEGIN

    ccrca_bloquear_registro_rca(p_codusur);

--VEN-2604 - Inicio
    SELECT CASE WHEN vstipocontacorrente = 'S'
                THEN NVL(PCSUPERV.VLCORRENTE,0)
                WHEN vstipocontacorrente = 'G'
                THEN NVL(PCGERENTE.VLCORRENTE,0)
                ELSE NVL(PCUSUARI.VLCORRENTE,0)
           END VLCORRENTE
         , CASE WHEN vstipocontacorrente = 'S'
                THEN NVL(PCSUPERV.VLLIMCRED,0)
                WHEN vstipocontacorrente = 'G'
                THEN NVL(PCGERENTE.VLLIMCRED,0)
                ELSE NVL(PCUSUARI.VLLIMCRED,0)
           END VLLIMCRED
         , PCSUPERV.CODSUPERVISOR
         , PCGERENTE.CODGERENTE
      INTO vnvlcorrente_ant
         , vnvllimcred
         , vnCodigoSupervisor
         , vnCodigoGerente
      FROM PCPEDC
     INNER JOIN PCUSUARI ON (PCUSUARI.CODUSUR       = PCPEDC.CODUSUR)
     INNER JOIN PCSUPERV ON (PCSUPERV.CODSUPERVISOR = NVL(PCPEDC.CODSUPERVISOR, PCUSUARI.CODSUPERVISOR))
      LEFT JOIN PCGERENTE ON (PCGERENTE.CODGERENTE   = NVL(PCPEDC.CODGERENTE, PCSUPERV.CODGERENTE))
     WHERE PCPEDC.NUMPED = vnnumped;

    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

  --VEN-2604 - Fim


    IF vbvalido = TRUE THEN
      vnvalorlanc        := ccrca_retornar_saldo_item_nf(p_numtransvenda,
                                                         p_codprod,
                                                         p_numseq,
                                                         p_qt,
                                                         'E'); --incluido por sabrina
      vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) - NVL(vnvalorlanc, 0);

      -- a package não deve barrar a movimentacao do saldo, os programas eh que fazem isso
      --IF vnvlcorrente_atual >= 0 THEN
    if vstipocontacorrente = 'G' then
      UPDATE pcgerente
         SET vlcorrente = vnvlcorrente_atual
       WHERE codgerente = vnCodigoGerente;
    ELSIF vstipocontacorrente = 'S' then
      UPDATE pcsuperv
         SET vlcorrente = vnvlcorrente_atual
       WHERE codsupervisor = vnCodigoSupervisor;
    else
      UPDATE pcusuari
         SET vlcorrente = vnvlcorrente_atual
       WHERE codusur = p_codusur;
    end if;

      INSERT INTO pclogdebcred
        (numped,
         posicao,
         numtransvenda,
         tipocontacorrente,
         DATA,
         codfunc,
         codigo,
         rotina,
         vlcorrente,
         vllimcred,
         vlcorrenteant,
         vllimcredant,
         codprod,
         numseq,
         historico)
      VALUES
        (vnnumped,
         vsposicao,
         p_numtransvenda,
         vstipocontacorrente,
         SYSDATE,
         p_codfunclanc,
         decode(vstipocontacorrente, 'S', vnCodigoSupervisor, 'G', vnCodigoGerente, p_codusur),
         p_rotinalanc,
         vnvlcorrente_atual,
         vnvllimcred,
         vnvlcorrente_ant,
         vnvllimcred,
         p_codprod,
         p_numseq,
         SUBSTR('CTRLCCRCA: ESTORNO SALDO ITEM TRANS. VENDA', 1, 60));

    if (vstipocontacorrente <> 'S') and (vstipocontacorrente <> 'G') then
      INSERT INTO pclogrca
        (numped,
         posicao,
         numtransvenda,
         DATA,
         codfunc,
         codusur,
         rotina,
         vlcorrente,
         vllimcred,
         vlcorrenteant,
         vllimcredant,
         codprod,
         numseq,
         historico,
         seqlogrca)
      VALUES
        (vnnumped,
         vsposicao,
         p_numtransvenda,
         SYSDATE,
         p_codfunclanc,
         p_codusur,
         p_rotinalanc,
         vnvlcorrente_atual,
         vnvllimcred,
         vnvlcorrente_ant,
         vnvllimcred,
         p_codprod,
         p_numseq,
         SUBSTR('CTRLCCRCA: ESTORNO SALDO ITEM TRANS. VENDA', 1, 60),
         DFSEQ_PCLOGRCA.NEXTVAL);
      --ELSE
      --vbvalido := FALSE;
      END IF;
    END IF;

    RETURN vbvalido;
  END; --ccrca_estornar_ccrca_item_nf

  --RNG14
  FUNCTION ccrca_incluir_item_nf(p_codfunclanc   IN pclogrca.codfunc%TYPE,
                                 p_rotinalanc    IN pclogrca.rotina%TYPE,
                                 p_codusur       IN pcpedc.codusur%TYPE,
                                 p_numtransvenda IN pcpedc.numtransvenda%TYPE,
                                 p_codprod       IN pcpedi.codprod%TYPE,
                                 p_numseq        IN pcpedi.numseq%TYPE)
    RETURN BOOLEAN IS
    vnvalorlanc        NUMBER;
    vnnumped           pcpedc.numped%TYPE;
    vnvlcorrente_ant   PCGERENTE.vlcorrente%TYPE;
    vnvllimcred        PCGERENTE.vllimcred%TYPE;
    vnvlcorrente_atual PCGERENTE.vlcorrente%TYPE;
    vnqt               pcpedi.qt%TYPE;
    vddata             pcpedc.DATA%TYPE;
    vsposicao          pcpedc.posicao%TYPE;
    vstipocontacorrente pcnfsaid.tipocontacorrente%TYPE;
    vnCodigoGerente     pcgerente.codgerente%TYPE;
    vnCodigoSupervisor  pcsuperv.codsupervisor%TYPE;
    vbvalido           BOOLEAN;
    A                  NUMBER;
    vnCODUSUR          NUMBER;
  BEGIN
    vbvalido := TRUE; --correcao sabrina

    BEGIN
       SELECT DISTINCT numped, tipocontacorrente, A
         INTO vnnumped, vstipocontacorrente, A
         FROM (SELECT DISTINCT numped, nvl(pcnfsaid.tipocontacorrente, 'R')tipocontacorrente, 1 A
                 FROM pcnfsaid
                WHERE numtransvenda = p_numtransvenda
                UNION
               SELECT DISTINCT numped, nvl(pcnfsaid.tipocontacorrente, 'R') tipocontacorrente, 2 A
                 FROM pcnfsaidprefat pcnfsaid
                WHERE numtransvenda = p_numtransvenda)
        WHERE ROWNUM = 1
        ORDER BY A;

    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    -- Verifica se pode movimentar conta corrente do RCA
    if (CONTROLASALDORCA(vnnumped) = 'N') then
      return(FALSE);
    end if;

    vnCODUSUR := 0;
    BEGIN
      SELECT DATA, posicao, CODUSUR
        INTO vddata, vsposicao,  vnCODUSUR
        FROM pcpedc
       WHERE numped = vnnumped;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    -- alterado por sabrina (quantidade do item de nf vem do pcmov)
    BEGIN
      SELECT DADOS.QT
        INTO VNQT
        FROM (SELECT PCMOV.QT, 1 A
                FROM PCMOV, PCNFSAID, PCMOVCOMPLE
               WHERE PCMOV.NUMTRANSVENDA = P_NUMTRANSVENDA
                 AND PCMOV.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA
                 AND PCMOV.CODPROD = P_CODPROD
                 AND NVL(PCMOVCOMPLE.NUMSEQORIG, PCMOV.NUMSEQ) = P_NUMSEQ
                 AND NVL(PCMOV.QT, 0) > 0
                 AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                    -- Tarefa 103974 Tarefa 109141 Incluído o condvenda 20 para consideração do campo punitcont conforem solicitado
                 AND DECODE(PCNFSAID.CONDVENDA,
                            5,
                            NVL(PCMOV.PTABELA, 0), -- Tarefa 150203
                            8,
                            NVL(PCMOV.PUNITCONT, 0),
                            11,
                            NVL(PCMOV.PUNITCONT, 0), -- Tarefa 114710
                            13,
                            NVL(PCMOV.PUNITCONT, 0),
                            14,
                            NVL(PCMOV.PUNITCONT, 0),
                            20,
                            NVL(PCMOV.PUNITCONT, 0),
                            1,
                            DECODE(PCMOVCOMPLE.BONIFIC,
                                   'F',
                                   NVL(PCMOV.PBONIFIC, 0),
                                   'S',
                                   NVL(PCMOV.PBONIFIC, 0),
                                   NVL(PCMOV.PUNIT, 0)),
                            NVL(PCMOV.PUNIT, 0)) > 0
              UNION
              SELECT PCMOV.QT, 2 A
                FROM PCMOVPREFAT       PCMOV
                    ,PCNFSAIDPREFAT    PCNFSAID
                    ,PCMOVCOMPLEPREFAT PCMOVCOMPLE
               WHERE PCMOV.NUMTRANSVENDA = P_NUMTRANSVENDA
                 AND PCMOV.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA
                 AND PCMOV.CODPROD = P_CODPROD
                 AND NVL(PCMOVCOMPLE.NUMSEQORIG, PCMOV.NUMSEQ) = P_NUMSEQ
                 AND NVL(PCMOV.QT, 0) > 0
                 AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                    -- Tarefa 103974 Tarefa 109141 Incluído o condvenda 20 para consideração do campo punitcont conforem solicitado
                 AND DECODE(PCNFSAID.CONDVENDA,
                            5,
                            NVL(PCMOV.PTABELA, 0), -- Tarefa 150203
                            8,
                            NVL(PCMOV.PUNITCONT, 0),
                            11,
                            NVL(PCMOV.PUNITCONT, 0), -- Tarefa 114710
                            13,
                            NVL(PCMOV.PUNITCONT, 0),
                            14,
                            NVL(PCMOV.PUNITCONT, 0),
                            20,
                            NVL(PCMOV.PUNITCONT, 0),
                            1,
                            DECODE(PCMOVCOMPLE.BONIFIC,
                                   'F',
                                   NVL(PCMOV.PBONIFIC, 0),
                                   'S',
                                   NVL(PCMOV.PBONIFIC, 0),
                                   NVL(PCMOV.PUNIT, 0)),
                            NVL(PCMOV.PUNIT, 0)) > 0) DADOS -- sabrina (teste de item gerencial)
       WHERE ROWNUM = 1
       ORDER BY A;


      /*
      SELECT pcmov.qt
              INTO vnqt
              FROM pcmov, pcnfsaid, pcmovcomple
             WHERE pcmov.numtransvenda = p_numtransvenda
               AND pcmov.numtransvenda = pcnfsaid.numtransvenda
               AND pcmov.codprod = p_codprod
               AND nvl(pcmovcomple.numseqorig, pcmov.numseq) = p_numseq
               AND NVL(pcmov.qt, 0) > 0
               AND pcmov.numtransitem = pcmovcomple.numtransitem(+)
                  -- Tarefa 103974 Tarefa 109141 Incluído o condvenda 20 para consideração do campo punitcont conforem solicitado
               AND DECODE(pcnfsaid.condvenda,
                          5,
                          NVL(pcmov.ptabela, 0), -- Tarefa 150203
                          8,
                          NVL(pcmov.punitcont, 0),
                          11,
                          NVL(pcmov.punitcont, 0), -- Tarefa 114710
                          13,
                          NVL(pcmov.punitcont, 0),
                          14,
                          NVL(pcmov.punitcont, 0),
                          20,
                          NVL(pcmov.punitcont, 0),
                          1,
                          DECODE(pcmovcomple.bonific,
                                 'F',
                                 NVL(pcmov.pbonific, 0),
                                 'S',
                                 NVL(pcmov.pbonific, 0),
                                 NVL(pcmov.punit, 0)),
                          NVL(pcmov.punit, 0)
                          ) > 0; -- sabrina (teste de item gerencial)
             */
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    BEGIN

    ccrca_bloquear_registro_rca(p_codusur);

  --VEN-2604 - Inicio
    SELECT CASE WHEN vstipocontacorrente = 'S'
                THEN NVL(PCSUPERV.VLCORRENTE,0)
                WHEN vstipocontacorrente = 'G'
                THEN NVL(PCGERENTE.VLCORRENTE,0)
                ELSE NVL(PCUSUARI.VLCORRENTE,0)
           END VLCORRENTE
         , CASE WHEN vstipocontacorrente = 'S'
                THEN NVL(PCSUPERV.VLLIMCRED,0)
                WHEN vstipocontacorrente = 'G'
                THEN NVL(PCGERENTE.VLLIMCRED,0)
                ELSE NVL(PCUSUARI.VLLIMCRED,0)
           END VLLIMCRED
         , PCSUPERV.CODSUPERVISOR
         , PCGERENTE.CODGERENTE
      INTO vnvlcorrente_ant
         , vnvllimcred
         , vnCodigoSupervisor
         , vnCodigoGerente
      FROM PCPEDC
     INNER JOIN PCUSUARI ON (PCUSUARI.CODUSUR       = PCPEDC.CODUSUR)
     INNER JOIN PCSUPERV ON (PCSUPERV.CODSUPERVISOR = NVL(PCPEDC.CODSUPERVISOR, PCUSUARI.CODSUPERVISOR))
      LEFT JOIN PCGERENTE ON (PCGERENTE.CODGERENTE   = NVL(PCPEDC.CODGERENTE, PCSUPERV.CODGERENTE))
     WHERE PCPEDC.NUMPED = vnnumped;

    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;
    --CASO SEJA TRANSFERENCIA O P_CODUSUR ¿ diferente do rca do pedido
    --esse sql evitar¿ o erro de pegar um saldo totalmente errado na transf.
    --cagada que s¿ pensou que s¿ vem de pedido de venda
    --7435.021803.2019
    IF vnCODUSUR <> p_codusur THEN
    SELECT  NVL(pcusuari.vlcorrente,0), NVL(pcusuari.vllimcred,0)
      INTO  vnvlcorrente_ant, vnvllimcred
      FROM pcusuari
     WHERE codusur = p_codusur;
    END IF;

    IF vbvalido = TRUE THEN
      vnvalorlanc        := ccrca_retornar_saldo_item_nf(p_numtransvenda,
                                                         p_codprod,
                                                         p_numseq,
                                                         vnqt,
                                                         'I'); -- incluido por sabrina
      vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) + NVL(vnvalorlanc, 0);

      -- a package não deve barrar a movimentacao do saldo, os programas eh que fazem isso
      --IF vnvlcorrente_atual >= 0 THEN
    if vstipocontacorrente = 'G' then
      UPDATE pcgerente
         SET vlcorrente = vnvlcorrente_atual
       WHERE codgerente = vnCodigoGerente;
    ELSIF vstipocontacorrente = 'S' then
      UPDATE pcsuperv
         SET vlcorrente = vnvlcorrente_atual
       WHERE codsupervisor = vnCodigoSupervisor;
    else
      UPDATE pcusuari
         SET vlcorrente = vnvlcorrente_atual
       WHERE codusur = p_codusur;
    end if;

      INSERT INTO pclogdebcred
        (numped,
         posicao,
         numtransvenda,
         tipocontacorrente,
         DATA,
         codfunc,
         codigo,
         rotina,
         vlcorrente,
         vllimcred,
         vlcorrenteant,
         vllimcredant,
         codprod,
         numseq,
         historico)
      VALUES
        (vnnumped,
         vsposicao,
         p_numtransvenda,
         vstipocontacorrente,
         SYSDATE,
         p_codfunclanc,
         decode(vstipocontacorrente, 'S', vnCodigoSupervisor, 'G', vnCodigoGerente, p_codusur),
         p_rotinalanc,
         vnvlcorrente_atual,
         vnvllimcred,
         vnvlcorrente_ant,
         vnvllimcred,
         p_codprod,
         p_numseq,
         SUBSTR('CTRLCCRCA: LANCAMENTO SALDO ITEM TRANS. VENDA', 1, 60));

    if (vstipocontacorrente <> 'S') and (vstipocontacorrente <> 'G') then
      INSERT INTO pclogrca
        (numped,
         posicao,
         numtransvenda,
         DATA,
         codfunc,
         codusur,
         rotina,
         vlcorrente,
         vllimcred,
         vlcorrenteant,
         vllimcredant,
         codprod,
         numseq,
         historico,
         seqlogrca)
      VALUES
        (vnnumped,
         vsposicao,
         p_numtransvenda,
         SYSDATE,
         p_codfunclanc,
         p_codusur,
         p_rotinalanc,
         vnvlcorrente_atual,
         vnvllimcred,
         vnvlcorrente_ant,
         vnvllimcred,
         p_codprod,
         p_numseq,
         SUBSTR('CTRLCCRCA: LANCAMENTO SALDO ITEM TRANS. VENDA', 1, 60),
         DFSEQ_PCLOGRCA.NEXTVAL);
      --ELSE
      --vbvalido := FALSE;
      END IF;
    END IF;

    RETURN vbvalido;
  END; -- ccrca_incluir_item_nf

  --RNG15
  FUNCTION ccrca_excluir_item_nf(p_codfunclanc   IN pclogrca.codfunc%TYPE,
                                 p_rotinalanc    IN pclogrca.rotina%TYPE,
                                 p_codusur       IN pcpedc.codusur%TYPE,
                                 p_numtransvenda IN pcpedc.numtransvenda%TYPE,
                                 p_codprod       IN pcpedi.codprod%TYPE,
                                 p_numseq        IN pcpedi.numseq%TYPE,
                                 p_qtanterior    IN NUMBER) RETURN BOOLEAN IS
    vbvalido BOOLEAN;
  BEGIN
    vbvalido := ccrca_estornar_ccrca_item_nf(p_codfunclanc,
                                             p_rotinalanc,
                                             p_codusur,
                                             p_numtransvenda,
                                             p_codprod,
                                             p_numseq,
                                             p_qtanterior);
    RETURN vbvalido;
  END; --ccrca_excluir_item_nf

  --RNG16
  FUNCTION ccrca_retornar_saldo_item_dev(p_numtransent pcmov.numtransent%TYPE,
                                         p_codprod     pcmov.codprod%TYPE,
                                         p_numseq      pcmov.numseq%TYPE,
                                         p_tipo        VARCHAR) -- Sabrina: tipo de operação I - Inclusao e E - Exclusao
   RETURN NUMBER IS
    vnvalorlanc                 NUMBER;
    vbvalido                    BOOLEAN;
    vnnumtransvenda             pcestcom.numtransvenda%TYPE;
    vnpunit                     pcmov.punit%TYPE;
    vnptabela                   pcmov.ptabela%TYPE;
    vnpbaserca                  pcmov.pbaserca%TYPE;
    vnqt                        pcmov.qt%TYPE;
    vsusadebcredrcabrind        pcmov.usadebcredrcabrind%TYPE;
    vncondvenda                 pcpedc.condvenda%TYPE;
    vnnumped                    pcpedc.numped%TYPE;
    vsbrinde                    pcpedc.brinde%TYPE;
    vsorigemped                 pcpedc.origemped%TYPE;
    vncodusur                   pcpedc.codusur%TYPE;
    vsbroker                    pcpedc.broker%TYPE;
    vsusacredrca                pcpedc.usacredrca%TYPE;
    vsbonificaltdebcredrca      pcpedc.bonificaltdebcredrca%TYPE;
    vstrocaaltdebcredrca        pcpedc.trocaaltdebcredrca%TYPE;
    vsbrokeraltdebcredrca       pcpedc.brokeraltdebcredrca%TYPE;
    vscrmaltdebcredrca          pcpedc.crmaltdebcredrca%TYPE;
    vstipomovccrca              pcpedc.tipomovccrca%TYPE;
    vsusadebcredrca             pcpedc.usadebcredrca%TYPE;
    vscodcob                    pcpedc.codcob%type; --HIS.03429.2014
    vbfechado                   BOOLEAN;
    vsmsg                       VARCHAR2(400);
    vsmovimentacontacorrenterca pcmov.movimentacontacorrenterca%type;
    vsbonific                   pcmovcomple.bonific%TYPE;
    vstipocontacorrente pcnfsaid.tipocontacorrente%TYPE;
  BEGIN
    proc_lerparametros(vsmsg);
    vbvalido := TRUE;

    BEGIN
      SELECT DISTINCT pcestcom.numtransvenda
        INTO vnnumtransvenda
        FROM pcestcom
       WHERE numtransent = p_numtransent;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    BEGIN
      SELECT CONDVENDA, NUMPED, TIPOCONTACORRENTE
        INTO vncondvenda, vnnumped, vstipocontacorrente
        FROM (SELECT DISTINCT condvenda, numped, nvl(pcnfsaid.tipocontacorrente, 'R') TIPOCONTACORRENTE, 1 A
                FROM pcnfsaid
               WHERE numtransvenda = vnnumtransvenda
             UNION
              SELECT DISTINCT condvenda, numped, nvl(pcnfsaid.tipocontacorrente, 'R') TIPOCONTACORRENTE, 2 A
                FROM PCNFSAIDPREFAT pcnfsaid
               WHERE numtransvenda = vnnumtransvenda)
       WHERE ROWNUM = 1
       ORDER BY A;


    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    BEGIN
      SELECT p.usacredrca,
             p.bonificaltdebcredrca,
             p.trocaaltdebcredrca,
             p.brokeraltdebcredrca,
             p.crmaltdebcredrca,
             p.tipomovccrca,
             p.usadebcredrca,
/*             DECODE(p.usadebcredrca,
                    NULL,
                    (SELECT NVL(pcusuari.usadebcredrca,
                                gregpcconsum.usacredrca)
                       FROM pcusuari
                      WHERE codusur = p.codusur
                        AND ROWNUM = 1),
                    p.usadebcredrca),*/
             p.origemped,
             p.brinde,
             p.condvenda,
             p.broker,
             p.codusur,
             p.codcob
        INTO vsusacredrca,
             vsbonificaltdebcredrca,
             vstrocaaltdebcredrca,
             vsbrokeraltdebcredrca,
             vscrmaltdebcredrca,
             vstipomovccrca,
             vsusadebcredrca,
             vsorigemped,
             vsbrinde,
             vncondvenda,
             vsbroker,
             vncodusur,
             vscodcob
        FROM pcpedc p
       WHERE p.numped = vnnumped;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

     IF vsusadebcredrca IS NULL THEN
        SELECT CASE WHEN vstipocontacorrente = 'S' 
                    THEN NVL(PCSUPERV.USADEBCRED,gregpcconsum.usacredsupervisor)
                    WHEN vstipocontacorrente = 'G' 
                    THEN NVL(PCGERENTE.USADEBCRED,gregpcconsum.usacredgerente)                
                    ELSE NVL(PCUSUARI.USADEBCREDRCA,gregpcconsum.usacredrca)
               END USADEBCRED
          INTO vsusadebcredrca
          FROM PCPEDC
         INNER JOIN PCUSUARI ON (PCUSUARI.CODUSUR       = PCPEDC.CODUSUR)
         INNER JOIN PCSUPERV ON (PCSUPERV.CODSUPERVISOR = NVL(PCPEDC.CODSUPERVISOR, PCUSUARI.CODSUPERVISOR))
          LEFT JOIN PCGERENTE ON (PCGERENTE.CODGERENTE   = NVL(PCPEDC.CODGERENTE, PCSUPERV.CODGERENTE))
         WHERE PCPEDC.NUMPED = vnnumped;    
     END IF;


    BEGIN
      --HIS.03429.2014
      IF (vsbonificaltdebcredrca = 'S')
        AND (INSTR(UPPER(vscodcob),'BNF') > 0)
        AND (vncondvenda = 14)
        AND (vsbrinde = 'S')
      THEN
      --HIS.03429.2014
        SELECT pcmov.PUNITCONT,
               pcmov.ptabela,
               pcmov.pbaserca,
               pcmov.qt,
               NVL(pcmov.usadebcredrcabrind, 'N'),
               nvl(NVL(pcmov.movimentacontacorrenterca,
                       (select pcpedi.movimentacontacorrenterca from pcpedi
                       where pcpedi.numped = pcmov.numped
                         and pcmov.codprod = pcpedi.codprod
                         and pcmov.numseq = pcpedi.numseq)),
                   'S'),
               nvl(pcmovcomple.bonific, 'N') BONIFIC
          INTO vnpunit,
               vnptabela,
               vnpbaserca,
               vnqt,
               vsusadebcredrcabrind,
               vsmovimentacontacorrenterca,
               vsbonific
          FROM pcmov, pcmovcomple
         WHERE pcmov.numtransent = p_numtransent
           AND pcmov.codprod = p_codprod
           AND NVL(pcmovcomple.numseqorig, pcmov.numseq) = p_numseq
           AND pcmov.numtransitem = pcmovcomple.numtransitem(+);

      ELSE

        SELECT DECODE(pcmov.punit,0,PCMOV.PBONIFIC,PCMOV.PUNIT),
               pcmov.ptabela,
               pcmov.pbaserca,
               pcmov.qt,
               NVL(pcmov.usadebcredrcabrind, 'N'),
               nvl(NVL(pcmov.movimentacontacorrenterca,
                       (select pcpedi.movimentacontacorrenterca from pcpedi
                       where pcpedi.numped = pcmov.numped
                         and pcmov.codprod = pcpedi.codprod
                         and pcmov.numseq = pcpedi.numseq)),
                   'S'),
               nvl(pcmovcomple.bonific, 'N') bonific
          INTO vnpunit,
               vnptabela,
               vnpbaserca,
               vnqt,
               vsusadebcredrcabrind,
               vsmovimentacontacorrenterca,
               vsbonific
          FROM pcmov, pcmovcomple
         WHERE pcmov.numtransent = p_numtransent
           AND pcmov.codprod = p_codprod
           AND NVL(pcmovcomple.numseqorig, pcmov.numseq) = p_numseq
           AND pcmov.numtransitem = pcmovcomple.numtransitem(+);

      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    vbfechado := ccrca_verificar_fechamento(vnnumtransvenda);

    IF vbvalido = TRUE THEN
      IF vbfechado = TRUE OR vstipomovccrca <> 'VA' THEN
        vnvalorlanc := ccrca_saldo_item(NVL(vsusacredrca,
                                            gregpcconsum.usacredrca),
                                        vsusadebcredrca,
                                        vsbroker,
                                        vsorigemped,
                                        NVL(vsbonificaltdebcredrca,
                                            gregpcconsum.bonificaltdebcredrca),
                                        NVL(vstrocaaltdebcredrca,
                                            gregpcconsum.trocaaltdebcredrca),
                                        NVL(vscrmaltdebcredrca,
                                            gregpcconsum.crmaltdebcredrca),
                                        NVL(vsbrokeraltdebcredrca,
                                            gregpcconsum.brokeraltdebcredrca),
                                        NVL(vstipomovccrca,
                                            NVL(gregpcconsum.tipomovccrca,
                                                'VV')),
                                        vncondvenda,
                                        vsbrinde,
                                        vncodusur,
                                        'D',
                                        vnpunit,
                                        vnptabela,
                                        NVL(vnpbaserca, vnptabela),
                                        vnqt,
                                        vsusadebcredrcabrind,
                                        vsmovimentacontacorrenterca,
                                        vsbonific);
      ELSE
        vnvalorlanc := ccrca_saldo_item(NVL(vsusacredrca,
                                            gregpcconsum.usacredrca),
                                        vsusadebcredrca,
                                        vsbroker,
                                        vsorigemped,
                                        NVL(vsbonificaltdebcredrca,
                                            gregpcconsum.bonificaltdebcredrca),
                                        NVL(vstrocaaltdebcredrca,
                                            gregpcconsum.trocaaltdebcredrca),
                                        NVL(vscrmaltdebcredrca,
                                            gregpcconsum.crmaltdebcredrca),
                                        NVL(vsbrokeraltdebcredrca,
                                            gregpcconsum.brokeraltdebcredrca),
                                        NVL(vstipomovccrca,
                                            NVL(gregpcconsum.tipomovccrca,
                                                'VV')),
                                        vncondvenda,
                                        vsbrinde,
                                        vncodusur,
                                        'V',
                                        vnpunit,
                                        vnptabela,
                                        NVL(vnpbaserca, vnptabela),
                                        vnqt,
                                        vsusadebcredrcabrind,
                                        vsmovimentacontacorrenterca,
                                        vsbonific);
      END IF;
    END IF;

    vnvalorlanc := vnvalorlanc * (-1);
    RETURN vnvalorlanc;
  END; --ccrca_retornar_saldo_item_dev

  --RNG17
  FUNCTION ccrca_estornar_ccrca_item_dev(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                         p_rotinalanc  IN pclogrca.rotina%TYPE,
                                         p_numtransent IN pcnfent.numtransent%TYPE,
                                         p_codusur     IN pcpedc.codusur%TYPE,
                                         p_codprod     IN pcpedi.codprod%TYPE,
                                         p_numseq      IN pcpedi.numseq%TYPE)
    RETURN BOOLEAN IS
    vnnumtransvenda        pcestcom.numtransvenda%TYPE;
    vncondvenda            pcpedc.condvenda%TYPE;
    vnnumped               pcpedc.numped%TYPE;
    vsbrinde               pcpedc.brinde%TYPE;
    vsorigemped            pcpedc.origemped%TYPE;
    vddata                 pcpedc.DATA%TYPE;
    vsposicao              pcpedc.posicao%TYPE;
    vsusacredrca           pcpedc.usacredrca%TYPE;
    vsusadebcredrca        pcpedc.bonificaltdebcredrca%TYPE;
    vsbonificaltdebcredrca pcpedc.bonificaltdebcredrca%TYPE;
    vstrocaaltdebcredrca   pcpedc.trocaaltdebcredrca%TYPE;
    vsbrokeraltdebcredrca  pcpedc.brokeraltdebcredrca%TYPE;
    vscrmaltdebcredrca     pcpedc.crmaltdebcredrca%TYPE;
    vstipomovccrca         pcpedc.tipomovccrca%TYPE;
    vsusadebcredrca_rca    pcusuari.usadebcredrca%TYPE;
    vnvlcorrente_ant       PCGERENTE.vlcorrente%TYPE;
    vnvllimcred            PCGERENTE.vllimcred%TYPE;
    vnvlcorrente_atual     PCGERENTE.vlcorrente%TYPE;
    vnvalorlanc            NUMBER;
    vstipocontacorrente pcnfsaid.tipocontacorrente%TYPE;
    vnCodigoGerente     pcgerente.codgerente%TYPE;
    vnCodigoSupervisor  pcsuperv.codsupervisor%TYPE;
    vbvalido               BOOLEAN;
	vnCODUSUR          NUMBER;
  BEGIN
    vbvalido := TRUE;

    BEGIN
      SELECT pcestcom.numtransvenda
        INTO vnnumtransvenda
        FROM pcestcom
       WHERE numtransent = p_numtransent;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

	vnCODUSUR := 0;

    BEGIN
      SELECT condvenda, numped, nvl(pcnfsaid.tipocontacorrente, 'R'), codusur
        INTO vncondvenda, vnnumped, vstipocontacorrente, vnCODUSUR
        FROM pcnfsaid
       WHERE numtransvenda = vnnumtransvenda;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    -- Verifica se pode movimentar conta corrente do RCA
    if (CONTROLASALDORCA(vnnumped) = 'N') then
      return(FALSE);
    end if;

    BEGIN
      SELECT DATA, posicao
        INTO vddata, vsposicao
        FROM pcpedc
       WHERE numped = vnnumped;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    BEGIN

    ccrca_bloquear_registro_rca(p_codusur);

 --VEN-2604 - Inicio
    SELECT CASE WHEN vstipocontacorrente = 'S'
                THEN NVL(PCSUPERV.USADEBCRED,'S')
                WHEN vstipocontacorrente = 'G'
                THEN NVL(PCGERENTE.USADEBCRED,'S')
                ELSE NVL(PCUSUARI.USADEBCREDRCA,'S')
           END USADEBCRED
         , CASE WHEN vstipocontacorrente = 'S'
                THEN NVL(PCSUPERV.VLCORRENTE,0)
                WHEN vstipocontacorrente = 'G'
                THEN NVL(PCGERENTE.VLCORRENTE,0)
                ELSE NVL(PCUSUARI.VLCORRENTE,0)
           END VLCORRENTE
         , CASE WHEN vstipocontacorrente = 'S'
                THEN NVL(PCSUPERV.VLLIMCRED,0)
                WHEN vstipocontacorrente = 'G'
                THEN NVL(PCGERENTE.VLLIMCRED,0)
                ELSE NVL(PCUSUARI.VLLIMCRED,0)
           END VLLIMCRED
         , PCSUPERV.CODSUPERVISOR
         , PCGERENTE.CODGERENTE
      INTO vsusadebcredrca
         , vnvlcorrente_ant
         , vnvllimcred
         , vnCodigoSupervisor
         , vnCodigoGerente
      FROM PCPEDC
     INNER JOIN PCUSUARI ON (PCUSUARI.CODUSUR       = PCPEDC.CODUSUR)
     INNER JOIN PCSUPERV ON (PCSUPERV.CODSUPERVISOR = NVL(PCPEDC.CODSUPERVISOR, PCUSUARI.CODSUPERVISOR))
      LEFT JOIN PCGERENTE ON (PCGERENTE.CODGERENTE   = NVL(PCPEDC.CODGERENTE, PCSUPERV.CODGERENTE))
     WHERE PCPEDC.NUMPED = vnnumped;
     --CASO SEJA TRANSFERENCIA O P_CODUSUR é diferente do rca do pedido
    --esse sql evitará o erro de pegar um saldo totalmente errado na transf.
    --cagada que só pensou que só vem de pedido de venda
    --7435.021803.2019
      IF vnCODUSUR <> p_codusur THEN
      SELECT pcusuari.usadebcredrca, pcusuari.vlcorrente, pcusuari.vllimcred
        INTO vsusadebcredrca, vnvlcorrente_ant, vnvllimcred
        FROM pcusuari
       WHERE codusur = p_codusur;
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    IF vbvalido = TRUE THEN
      vnvalorlanc        := ccrca_retornar_saldo_item_dev(p_numtransent,
                                                          p_codprod,
                                                          p_numseq,
                                                          'E'); -- incluido por sabrina
      vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) - NVL(vnvalorlanc, 0);

      -- a package não deve barrar a movimentacao do saldo, os programas eh que fazem isso
      --IF vnvlcorrente_atual >= 0 THEN
   if vstipocontacorrente = 'G' then
      UPDATE pcgerente
         SET vlcorrente = vnvlcorrente_atual
       WHERE codgerente = vnCodigoGerente;
    ELSIF vstipocontacorrente = 'S' then
      UPDATE pcsuperv
         SET vlcorrente = vnvlcorrente_atual
       WHERE codsupervisor = vnCodigoSupervisor;
    else
      UPDATE pcusuari
         SET vlcorrente = vnvlcorrente_atual
       WHERE codusur = p_codusur;
    end if;

      INSERT INTO pclogdebcred
        (numped,
         posicao,
         numtransvenda,
         tipocontacorrente,
         DATA,
         codfunc,
         codigo,
         rotina,
         vlcorrente,
         vllimcred,
         vlcorrenteant,
         vllimcredant,
         codprod,
         numseq,
         historico)
      VALUES
        (vnnumped,
         vsposicao,
         vnnumtransvenda,
         vstipocontacorrente,
         SYSDATE,
         p_codfunclanc,
         decode(vstipocontacorrente, 'S', vnCodigoSupervisor, 'G', vnCodigoGerente, p_codusur),
         p_rotinalanc,
         vnvlcorrente_atual,
         vnvllimcred,
         vnvlcorrente_ant,
         vnvllimcred,
         p_codprod,
         p_numseq,
         SUBSTR('CTRLCCRCA: ESTORNO SALDO ITEM DEVOLUCAO', 1, 60));

    if (vstipocontacorrente <> 'S') and (vstipocontacorrente <> 'G') then
      INSERT INTO pclogrca
        (numped,
         posicao,
         numtransvenda,
         DATA,
         codfunc,
         codusur,
         rotina,
         vlcorrente,
         vllimcred,
         vlcorrenteant,
         vllimcredant,
         codprod,
         numseq,
         historico,
         seqlogrca)
      VALUES
        (vnnumped,
         vsposicao,
         vnnumtransvenda,
         SYSDATE,
         p_codfunclanc,
         p_codusur,
         p_rotinalanc,
         vnvlcorrente_atual,
         vnvllimcred,
         vnvlcorrente_ant,
         vnvllimcred,
         p_codprod,
         p_numseq,
         SUBSTR('CTRLCCRCA: ESTORNO SALDO ITEM DEVOLUCAO', 1, 60),
         DFSEQ_PCLOGRCA.NEXTVAL);
      --ELSE
      --vbvalido := FALSE;
      END IF;
    END IF;

    RETURN(vbvalido);
  END; --ccrca_estornar_ccrca_item_dev

  --RNG18
  FUNCTION ccrca_incluir_item_dev(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                  p_rotinalanc  IN pclogrca.rotina%TYPE,
                                  p_numtransent IN pcnfent.numtransent%TYPE,
                                  p_codusur     IN pcpedc.codusur%TYPE,
                                  p_codprod     IN pcpedi.codprod%TYPE,
                                  p_numseq      IN pcpedi.numseq%TYPE)
    RETURN BOOLEAN IS
    vbvalido           BOOLEAN;
    vnnumped           pcpedc.numped%TYPE;
    vncondvenda        pcpedc.condvenda%TYPE;
    vnnumtransvenda    pcestcom.numtransvenda%TYPE;
    vsposicao          pcpedc.posicao%TYPE;
    vddata             pcpedc.DATA%TYPE;
    vnvlcorrente_ant   PCGERENTE.vlcorrente%TYPE;
    vnvlcorrente_atual PCGERENTE.vlcorrente%TYPE;
    vnvllimcred        PCGERENTE.vllimcred%TYPE;
    vstipocontacorrente pcnfsaid.tipocontacorrente%TYPE;
    vnCodigoGerente     pcgerente.codgerente%TYPE;
    vnCodigoSupervisor  pcsuperv.codsupervisor%TYPE;
    vnvalorlanc        NUMBER;
    vnCODUSUR          NUMBER;
  BEGIN
    vbvalido := TRUE;
    vnCODUSUR := 0;

    BEGIN
      SELECT DISTINCT pcestcom.numtransvenda
        INTO vnnumtransvenda
        FROM pcestcom
       WHERE numtransent = p_numtransent;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    BEGIN
      SELECT DISTINCT condvenda, numped, nvl(pcnfsaid.tipocontacorrente, 'R')
        INTO vncondvenda, vnnumped, vstipocontacorrente
        FROM pcnfsaid
       WHERE numtransvenda = vnnumtransvenda;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    -- Verifica se pode movimentar conta corrente do RCA
    if (CONTROLASALDORCA(vnnumped) = 'N') then
      return(FALSE);
    end if;

    BEGIN
      SELECT DATA, posicao, CODUSUR
        INTO vddata, vsposicao, vnCODUSUR
        FROM pcpedc
       WHERE numped = vnnumped;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    BEGIN

  --VEN-2604 - Inicio
    SELECT CASE WHEN vstipocontacorrente = 'S'
                THEN NVL(PCSUPERV.VLCORRENTE,0)
                WHEN vstipocontacorrente = 'G'
                THEN NVL(PCGERENTE.VLCORRENTE,0)
                ELSE NVL(PCUSUARI.VLCORRENTE,0)
           END VLCORRENTE
         , CASE WHEN vstipocontacorrente = 'S'
                THEN NVL(PCSUPERV.VLLIMCRED,0)
                WHEN vstipocontacorrente = 'G'
                THEN NVL(PCGERENTE.VLLIMCRED,0)
                ELSE NVL(PCUSUARI.VLLIMCRED,0)
           END VLLIMCRED
         , PCSUPERV.CODSUPERVISOR
         , PCGERENTE.CODGERENTE
      INTO vnvlcorrente_ant
         , vnvllimcred
         , vnCodigoSupervisor
         , vnCodigoGerente
      FROM PCPEDC
     INNER JOIN PCUSUARI ON (PCUSUARI.CODUSUR       = PCPEDC.CODUSUR)
     INNER JOIN PCSUPERV ON (PCSUPERV.CODSUPERVISOR = NVL(PCPEDC.CODSUPERVISOR, PCUSUARI.CODSUPERVISOR))
      LEFT JOIN PCGERENTE ON (PCGERENTE.CODGERENTE   = NVL(PCPEDC.CODGERENTE, PCSUPERV.CODGERENTE))
     WHERE PCPEDC.NUMPED = vnnumped;

       IF vnCODUSUR <> p_codusur THEN
       SELECT pcusuari.vlcorrente, pcusuari.vllimcred
         INTO  vnvlcorrente_ant, vnvllimcred
         FROM pcusuari
        WHERE codusur = p_codusur;
       END IF;


    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
  --VEN-2604 - Fim
    END;

    IF vbvalido = TRUE THEN
      vnvalorlanc        := ccrca_retornar_saldo_item_dev(p_numtransent,
                                                          p_codprod,
                                                          p_numseq,
                                                          'I'); -- incluido por sabrina
      vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) + NVL(vnvalorlanc, 0);

      -- a package não deve barrar a movimentacao do saldo, os programas eh que fazem isso
      --IF vnvlcorrente_atual >= 0 THEN

    IF (vnvlcorrente_atual <> vnvlcorrente_ant) THEN

      ccrca_bloquear_registro_rca(p_codusur);

      if vstipocontacorrente = 'G' then
        UPDATE pcgerente
           SET vlcorrente = vnvlcorrente_atual
         WHERE codgerente = vnCodigoGerente;
      ELSIF vstipocontacorrente = 'S' then
        UPDATE pcsuperv
           SET vlcorrente = vnvlcorrente_atual
         WHERE codsupervisor = vnCodigoSupervisor;
      else
        UPDATE pcusuari
           SET vlcorrente = vnvlcorrente_atual
         WHERE codusur = p_codusur;
      end if;

    end if;

      INSERT INTO pclogdebcred
        (numped,
         posicao,
         numtransvenda,
         tipocontacorrente,
         DATA,
         codfunc,
         codigo,
         rotina,
         vlcorrente,
         vllimcred,
         vlcorrenteant,
         vllimcredant,
         codprod,
         numseq,
         historico)
      VALUES
        (vnnumped,
         vsposicao,
         vnnumtransvenda,
         vstipocontacorrente,
         SYSDATE,
         p_codfunclanc,
         decode(vstipocontacorrente, 'S', vnCodigoSupervisor, 'G', vnCodigoGerente, p_codusur),
         p_rotinalanc,
         vnvlcorrente_atual,
         vnvllimcred,
         vnvlcorrente_ant,
         vnvllimcred,
         p_codprod,
         p_numseq,
         SUBSTR('CTRLCCRCA: LANCAMENTO SALDO ITEM DEVOLUCAO', 1, 60));

    if (vstipocontacorrente <> 'S') and (vstipocontacorrente <> 'G') then
       INSERT INTO pclogrca
        (numped,
         posicao,
         numtransvenda,
         DATA,
         codfunc,
         codusur,
         rotina,
         vlcorrente,
         vllimcred,
         vlcorrenteant,
         vllimcredant,
         codprod,
         numseq,
         historico,
         seqlogrca)
      VALUES
        (vnnumped,
         vsposicao,
         vnnumtransvenda,
         SYSDATE,
         p_codfunclanc,
         p_codusur,
         p_rotinalanc,
         vnvlcorrente_atual,
         vnvllimcred,
         vnvlcorrente_ant,
         vnvllimcred,
         p_codprod,
         p_numseq,
         SUBSTR('CTRLCCRCA: LANCAMENTO SALDO ITEM DEVOLUCAO', 1, 60),
         DFSEQ_PCLOGRCA.NEXTVAL);
      --ELSE
      --vbvalido := FALSE;
      END IF;
    END IF;

    RETURN vbvalido;
  END; --ccrca_incluir_item_dev

  --RNG19
  FUNCTION ccrca_excluir_item_dev(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                  p_rotinalanc  IN pclogrca.rotina%TYPE,
                                  p_numtransent IN pcnfent.numtransent%TYPE,
                                  p_codusur     IN pcpedc.codusur%TYPE,
                                  p_codprod     IN pcpedi.codprod%TYPE,
                                  p_numseq      IN pcpedi.numseq%TYPE)
    RETURN BOOLEAN IS
    vbvalido        BOOLEAN;
    vnnumtransvenda pcnfsaid.numtransvenda%TYPE;
  BEGIN
    vbvalido := FALSE;

    vbvalido := ccrca_estornar_ccrca_item_dev(p_codfunclanc,
                                              p_rotinalanc,
                                              p_numtransent,
                                              p_codusur,
                                              p_codprod,
                                              p_numseq);
    RETURN vbvalido;
  END; --ccrca_excluir_item_dev

  --RNG24
  FUNCTION ccrca_buscar_saldo_venda(p_numped  IN pcpedc.numped%TYPE,
                                    p_codusur IN pcpedc.codusur%TYPE)
    RETURN NUMBER IS
    vvvlsaldopedido    NUMBER;
    vstipomovccrca     pcpedc.tipomovccrca%TYPE;
    vnnumtransvenda    pcpedc.numtransvenda%TYPE;
    vnvlsaldopedido    NUMBER;
    vnvlsaldonf        NUMBER;
    vnvlsaldodevolucao NUMBER;
    vnvlsaldovenda     NUMBER;
    vbvalido           BOOLEAN;
    vsmsg              VARCHAR2(400);
  BEGIN
    proc_lerparametros(vsmsg);
    vbvalido           := TRUE;
    vnvlsaldopedido    := 0;
    vnvlsaldonf        := 0;
    vnvlsaldodevolucao := 0;
    vnvlsaldovenda     := 0;

    BEGIN
      SELECT p.tipomovccrca, p.numtransvenda
        INTO vstipomovccrca, vnnumtransvenda
        FROM pcpedc p
       WHERE numped = p_numped;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    IF vbvalido = TRUE THEN
      IF NVL(vstipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) IN
         ('VV', 'VF') THEN
        vnvlsaldopedido := 0;

        FOR reg IN (SELECT codprod, numseq, qt
                      FROM pcpedi
                     WHERE numped = p_numped) LOOP
          vnvlsaldopedido := NVL(vnvlsaldopedido, 0) +
                             NVL(ccrca_retorna_saldo_itempedido(p_numped,
                                                                p_codusur,
                                                                reg.codprod,
                                                                reg.numseq,
                                                                reg.qt,
                                                                'I'),
                                 0); -- incluído por sabrina I - Inclusao
        END LOOP;
      END IF;

      IF NVL(vstipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) IN
         ('FF', 'VF') THEN
        vnvlsaldonf := 0;

        FOR reg IN (SELECT codprod,  nvl(pcmovcomple.numseqorig, pcmov.numseq) numseq, qt
                      FROM pcmov, pcmovcomple
                     WHERE numtransvenda = vnnumtransvenda
                       and pcmov.numtransitem =  pcmovcomple.numtransitem(+)
                       AND NVL(PCMOV.TIPOITEM, 'N') IN ('C', 'N')) LOOP
          vnvlsaldonf := NVL(vnvlsaldonf, 0) + NVL(ccrca_retornar_saldo_item_nf(vnnumtransvenda,
                                                                                reg.codprod,
                                                                                reg.numseq,
                                                                                reg.qt,
                                                                                'I'),
                                                   0); -- incluido por sabrina I - Inclusao
        END LOOP;
      END IF;

      vnvlsaldodevolucao := 0;

      FOR reg IN (SELECT numtransent
                    FROM pcestcom
                   WHERE numtransvenda = vnnumtransvenda) LOOP
        FOR reg_itens IN (SELECT codprod, numseq, qt
                            FROM pcmov
                           WHERE numtransent = reg.numtransent) LOOP
          --Tarefa 99461
          if reg.numtransent > 0 then
            vnvlsaldodevolucao := NVL(vnvlsaldodevolucao, 0) +
                                  NVL(ccrca_retornar_saldo_item_dev(reg.numtransent,
                                                                    reg_itens.codprod,
                                                                    reg_itens.numseq,
                                                                    'I'),
                                      0); -- incluido por sabrina I - Inclusao
          END IF;
        END LOOP;
      END LOOP;

      vnvlsaldovenda := NVL(vnvlsaldopedido, 0) + NVL(vnvlsaldonf, 0) +
                        NVL(vnvlsaldodevolucao, 0);
    END IF;

    RETURN(vnvlsaldovenda);
  END; --ccrca_buscar_saldo_venda

  --RNG25
  FUNCTION ccrca_checar_alterar_rca(p_codusurorig    pcusuari.codusur%TYPE,
                                    p_codusurdestino pcusuari.codusur%TYPE,
                                    p_codfunclanc    pclogrca.codfunc%TYPE,
                                    p_rotinalanc     pclogrca.rotina%TYPE,
                                    p_numped         pcpedc.numped%TYPE)
    RETURN BOOLEAN IS
    vbtroca                  BOOLEAN;
    vbvalido                 BOOLEAN;
    vnsaldo_disp_rca_origem  NUMBER;
    vnsaldo_venda_origem     NUMBER;
    vnsaldo_venda_destino    NUMBER;
    vnsaldo_disp_rca_destino NUMBER;
  BEGIN
    vbtroca                 := FALSE;
    vbvalido                := FALSE;
    vnsaldo_venda_origem    := ccrca_buscar_saldo_venda(p_numped,
                                                        p_codusurorig);
    vnsaldo_disp_rca_origem := ccrca_checar_disponivel_atual(p_codusurorig);

    IF NVL(vnsaldo_disp_rca_origem, 0) - NVL(vnsaldo_venda_origem, 0) < 0 THEN
      vbtroca := FALSE;
      -- rca de origem não pode "perder" o saldo desta venda sem ficar negativo
    ELSE
      vbtroca := TRUE;
    END IF;

    IF vbtroca = TRUE THEN
      vnsaldo_venda_destino    := ccrca_buscar_saldo_venda(p_numped,
                                                           p_codusurdestino);
      vnsaldo_disp_rca_destino := ccrca_checar_disponivel_atual(p_codusurdestino);

      IF NVL(vnsaldo_disp_rca_destino, 0) + NVL(vnsaldo_venda_destino, 0) < 0 THEN
        vbvalido := FALSE;
        -- rca de destino não pode "receber" o saldo desta venda sem ficar negativo
      ELSE
        vbvalido := TRUE;
      END IF;
    END IF;

    RETURN vbvalido;
  END; --ccrca_checar_alterar_rca

  --RNG20
  FUNCTION ccrca_alterar_rca(p_codusurorig    pcusuari.codusur%TYPE,
                             p_codusurdestino pcusuari.codusur%TYPE,
                             p_codfunclanc    pclogrca.codfunc%TYPE,
                             p_rotinalanc     pclogrca.rotina%TYPE,
                             p_numped         pcpedc.numped%TYPE)
    RETURN BOOLEAN IS
    vstipomovccrca  pcpedc.tipomovccrca%TYPE;
    vsposicao       pcpedc.posicao%TYPE;
    vsusadebcredrca pcusuari.usadebcredrca%TYPE;
    vnnumtransvenda pcpedc.numtransvenda%TYPE;
    vbvalido        BOOLEAN;
    vsmsg           VARCHAR2(400);
    vstipocontacorrente pcpedc.tipocontacorrente%TYPE;
    vcount_reg      number;
  BEGIN
    proc_lerparametros(vsmsg);
    vbvalido := TRUE; --correcao sabrina

    -- Verifica se pode movimentar conta corrente do RCA
    if (CONTROLASALDORCA(p_numped) = 'N') then
      return(FALSE);
    end if;

    BEGIN
      SELECT pcpedc.tipomovccrca, posicao, nvl(pcpedc.tipocontacorrente, 'R')
        INTO vstipomovccrca, vsposicao, vstipocontacorrente
        FROM pcpedc
       WHERE numped = p_numped;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    -- soh buscar transacao se pedido estiver faturado
    IF vsposicao = 'F' THEN
      BEGIN
        SELECT NUMTRANSVENDA, TIPOCONTACORRENTE
          INTO VNNUMTRANSVENDA, VSTIPOCONTACORRENTE
          FROM (SELECT PCNFSAID.NUMTRANSVENDA, NVL(PCNFSAID.TIPOCONTACORRENTE, 'R') TIPOCONTACORRENTE, 1 A
                  FROM PCNFSAID
                 WHERE NUMPED = P_NUMPED
                   AND DTCANCEL IS NULL
                UNION
                SELECT PCNFSAID.NUMTRANSVENDA, NVL(PCNFSAID.TIPOCONTACORRENTE, 'R') TIPOCONTACORRENTE, 2 A
                  FROM PCNFSAIDPREFAT PCNFSAID
                 WHERE NUMPED = P_NUMPED
                   AND DTCANCEL IS NULL) DADOS
         WHERE ROWNUM = 1
         ORDER BY A ;


        /*
        SELECT pcnfsaid.numtransvenda, nvl(pcnfsaid.tipocontacorrente, 'R')
          INTO vnnumtransvenda, vstipocontacorrente
          FROM pcnfsaid
         WHERE numped = p_numped
         and dtcancel is null;
         */
      EXCEPTION
        WHEN OTHERS THEN
          vbvalido := FALSE;
      END;

    /*BEGIN
      SELECT 1
        INTO vcount_reg
        FROM pcmovcomple
       WHERE rownum = 1 and numtransitem in
             (select numtransitem from pcmov where numped = p_numped);
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;  */
    END IF;

    BEGIN
        SELECT CASE WHEN vstipocontacorrente = 'S' 
                    THEN NVL(PCSUPERV.USADEBCRED, gregpcconsum.usacredsupervisor)
                    WHEN vstipocontacorrente = 'G' 
                    THEN NVL(PCGERENTE.USADEBCRED,gregpcconsum.usacredgerente)                
                    ELSE NVL(PCUSUARI.USADEBCREDRCA,gregpcconsum.usacredrca)
               END USADEBCRED
          INTO vsusadebcredrca
          FROM PCPEDC
         INNER JOIN PCUSUARI ON (PCUSUARI.CODUSUR       = PCPEDC.CODUSUR)
         INNER JOIN PCSUPERV ON (PCSUPERV.CODSUPERVISOR = NVL(PCPEDC.CODSUPERVISOR, PCUSUARI.CODSUPERVISOR))
          LEFT JOIN PCGERENTE ON (PCGERENTE.CODGERENTE   = NVL(PCPEDC.CODGERENTE, PCSUPERV.CODGERENTE))
         WHERE PCPEDC.NUMPED = p_numped;    

/*      SELECT pcusuari.usadebcredrca
        INTO vsusadebcredrca
        FROM pcusuari
       WHERE codusur = p_codusurdestino;*/
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    IF vbvalido THEN
      FOR reg IN (SELECT codprod, numseq, qt
                    FROM pcpedi
                   WHERE numped = p_numped) LOOP
        vbvalido := ccrca_estorna_item_pedido(p_codfunclanc,
                                              p_rotinalanc,
                                              p_codusurorig,
                                              p_numped,
                                              reg.codprod,
                                              reg.numseq,
                                              reg.qt);

        IF NVL(vstipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) IN
           ('FF', 'VF') THEN
          IF vsposicao = 'F' THEN
            vbvalido := ccrca_estornar_ccrca_item_nf(p_codfunclanc,
                                                     p_rotinalanc,
                                                     p_codusurorig,
                                                     vnnumtransvenda,
                                                     reg.codprod,
                                                     reg.numseq,
                                                     reg.qt);
          END IF;
        END IF;
      END LOOP;

      UPDATE pcpedc
         SET usadebcredrca = vsusadebcredrca
       WHERE numped = p_numped;

      FOR reg IN (SELECT codprod, numseq FROM pcpedi WHERE numped = p_numped) LOOP
        vbvalido := ccrca_incluir_item_pedido(p_codfunclanc,
                                              p_rotinalanc,
                                              p_codusurdestino,
                                              p_numped,
                                              reg.codprod,
                                              reg.numseq);

        IF NVL(vstipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) IN
           ('FF', 'VF') THEN
          IF vsposicao = 'F' THEN
            vbvalido := ccrca_incluir_item_nf(p_codfunclanc,
                                              p_rotinalanc,
                                              p_codusurdestino,
                                              vnnumtransvenda,
                                              reg.codprod,
                                              reg.numseq);
          END IF;
        END IF;
      END LOOP;

      IF vsposicao = 'F' THEN
        FOR reg IN (SELECT DISTINCT pcnfent.numtransent
                      FROM pcnfsaid, pcestcom, pcnfent
                     WHERE pcnfsaid.numped = p_numped
                       AND pcestcom.numtransvenda = pcnfsaid.numtransvenda
                       AND NVL(pcnfent.obs, 'X') <> 'NF CANCELADA'
                          -- acrescentada por sabrina
                       AND pcestcom.numtransent = pcnfent.numtransent) LOOP
          FOR reg_itens IN (SELECT codprod, numseq
                              FROM pcmov
                             WHERE numtransent = reg.numtransent) LOOP
            IF ccrca_estornar_ccrca_item_dev(p_codfunclanc,
                                             p_rotinalanc,
                                             reg.numtransent,
                                             p_codusurorig,
                                             reg_itens.codprod,
                                             reg_itens.numseq) THEN
              vbvalido := ccrca_incluir_item_dev(p_codfunclanc,
                                                 p_rotinalanc,
                                                 reg.numtransent,
                                                 p_codusurdestino,
                                                 reg_itens.codprod,
                                                 reg_itens.numseq);
            END IF;
          END LOOP;
        END LOOP;
      END IF;
    END IF;

    RETURN vbvalido;
  END; --ccrca_alterar_rca

  PROCEDURE ccrca_validar_acerto_nf(p_codfunclanc   IN pclogrca.codfunc%TYPE,
                                    p_rotinalanc    IN pclogrca.rotina%TYPE,
                                    p_numtransvenda IN pcnfsaid.numtransvenda%TYPE) IS
    vsusacredrca           pcpedc.usacredrca%TYPE;
    vsusadebcredrca        pcpedc.usadebcredrca%TYPE;
    vsbroker               pcpedc.broker%TYPE;
    vsorigemped            pcpedc.origemped%TYPE;
    vsbonificaltdebcredrca pcpedc.bonificaltdebcredrca%TYPE;
    vstrocaaltdebcredrca   pcpedc.trocaaltdebcredrca%TYPE;
    vscrmaltdebcredrca     pcpedc.crmaltdebcredrca%TYPE;
    vsbrokeraltdebcredrca  pcpedc.brokeraltdebcredrca%TYPE;
    vstipomovccrca         pcpedc.tipomovccrca%TYPE;
    vncondvenda            pcpedc.condvenda%TYPE;
    vsbrinde               pcpedc.brinde%TYPE;
    vncodusur              pcpedc.codusur%TYPE;
    vnnumped               pcpedc.numped%TYPE;
    vsposicao              pcpedc.posicao%TYPE;
    vnsaldoitem            NUMBER;
    vnvlcorrente_ant       PCGERENTE.vlcorrente%TYPE;
    vnvlcorrente_atual     PCGERENTE.vlcorrente%TYPE;
    vnvllimcred            PCGERENTE.vllimcred%TYPE;
    vstipocontacorrente pcpedc.tipocontacorrente%TYPE;
    vnCodigoGerente     pcgerente.codgerente%TYPE;
    vnCodigoSupervisor  pcsuperv.codsupervisor%TYPE;

  BEGIN
    FOR reg IN (/*Tarefa: 183663
                SELECT pcmov.numseq,
                       pcmov.codprod,
                       pcmov.punit,
                       pcmov.ptabela,
                       pcmov.pbaserca,
                       --Tarefa 113031
                       --No acerto da carga considerar somente a quantidade real, ou seja
                       --desconsiderar a quantidade devolvida
                       nvl(pcmov.qt, 0) - nvl(pcmov.qtdevol, 0) qt,
                       NVL(pcmov.usadebcredrcabrind, 'N') usadebcredrcabrind,
                       nvl(NVL(pcmov.movimentacontacorrenterca,
                               PCPEDI.movimentacontacorrenterca),
                           'S') movimentacontacorrenterca
                  FROM pcmov, PCPEDI
                 WHERE pcmov.numtransvenda = p_numtransvenda
                   AND PCMOV.CODPROD(+) = PCPEDI.CODPROD
                   AND PCMOV.NUMSEQ(+) = PCPEDI.NUMSEQ
                   AND PCMOV.NUMPED(+) = PCPEDI.NUMPED*/
                SELECT pcmov.numseq,
                       pcmov.codprod,
                       pcmov.punit,
                       pcmov.ptabela,
                       pcmov.pbaserca,
                       --Tarefa 113031
                       --No acerto da carga considerar somente a quantidade real, ou seja
                       --desconsiderar a quantidade devolvida
                       nvl(pcmov.qt, 0) - nvl(pcmov.qtdevol, 0) qt,
                       NVL(pcmov.usadebcredrcabrind, 'N') usadebcredrcabrind,
                       nvl(NVL(pcmov.movimentacontacorrenterca,
                               (select pcpedi.movimentacontacorrenterca from pcpedi
                                 where pcpedi.numped = pcmov.numped
                                   and pcmov.codprod = pcpedi.codprod
                                   and pcmov.numseq = pcpedi.numseq)),
                           'S') movimentacontacorrenterca,
                       nvl(pcmovcomple.BONIFIC, 'N') bonific
                  FROM pcmov, pcmovcomple
                 WHERE pcmov.numtransvenda = p_numtransvenda
                   AND pcmov.numtransitem = pcmovcomple.numtransitem(+)
                 --Fim Tarefa: 183663
                 ) LOOP

      SELECT p.usacredrca,
             p.usadebcredrca,
             p.broker,
             p.origemped,
             p.bonificaltdebcredrca,
             p.trocaaltdebcredrca,
             p.crmaltdebcredrca,
             p.brokeraltdebcredrca,
             p.tipomovccrca,
             p.condvenda,
             p.brinde,
             p.codusur,
             p.numped,
             p.posicao,
             nvl(p.tipocontacorrente, 'R')
        INTO vsusacredrca,
             vsusadebcredrca,
             vsbroker,
             vsorigemped,
             vsbonificaltdebcredrca,
             vstrocaaltdebcredrca,
             vscrmaltdebcredrca,
             vsbrokeraltdebcredrca,
             vstipomovccrca,
             vncondvenda,
             vsbrinde,
             vncodusur,
             vnnumped,
             vsposicao,
             vstipocontacorrente
        FROM pcpedc p
       WHERE numtransvenda = p_numtransvenda
         AND rownum = 1;  --Tarefa: 172790

      -- Verifica se pode movimentar conta corrente do RCA
      if (CONTROLASALDORCA(vnnumped) = 'S') then

        vnsaldoitem := ccrca_saldo_item(vsusacredrca,
                                        vsusadebcredrca,
                                        vsbroker,
                                        vsorigemped,
                                        vsbonificaltdebcredrca,
                                        vstrocaaltdebcredrca,
                                        vscrmaltdebcredrca,
                                        vsbrokeraltdebcredrca,
                                        vstipomovccrca,
                                        vncondvenda,
                                        vsbrinde,
                                        vncodusur,
                                        'A',
                                        reg.punit,
                                        reg.ptabela,
                                        reg.pbaserca,
                                        reg.qt,
                                        reg.usadebcredrcabrind,
                                        reg.movimentacontacorrenterca,
                                        reg.bonific);

    SELECT CASE WHEN vstipocontacorrente = 'S' 
                THEN NVL(PCSUPERV.VLCORRENTE,0)
                WHEN vstipocontacorrente = 'G' 
                THEN NVL(PCGERENTE.VLCORRENTE,0)                
                ELSE NVL(PCUSUARI.VLCORRENTE,0)
           END VLCORRENTE
         , CASE WHEN vstipocontacorrente = 'S' 
                THEN NVL(PCSUPERV.VLLIMCRED,0)
                WHEN vstipocontacorrente = 'G' 
                THEN NVL(PCGERENTE.VLLIMCRED,0)                
                ELSE NVL(PCUSUARI.VLLIMCRED,0)
           END VLLIMCRED
         , PCSUPERV.CODSUPERVISOR
         , PCGERENTE.CODGERENTE
      INTO vnvlcorrente_ant
         , vnvllimcred
         , vnCodigoSupervisor
         , vnCodigoGerente
      FROM PCPEDC
     INNER JOIN PCUSUARI ON (PCUSUARI.CODUSUR       = PCPEDC.CODUSUR)
     INNER JOIN PCSUPERV ON (PCSUPERV.CODSUPERVISOR = NVL(PCPEDC.CODSUPERVISOR, PCUSUARI.CODSUPERVISOR))
      LEFT JOIN PCGERENTE ON (PCGERENTE.CODGERENTE   = NVL(PCPEDC.CODGERENTE, PCSUPERV.CODGERENTE))
     WHERE PCPEDC.NUMPED = vnnumped;    
   


/*      SELECT vlcorrente, vllimcred
        INTO vnvlcorrente_ant, vnvllimcred
        FROM pcusuari
       WHERE codusur = vncodusur;*/

      vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) + NVL(vnsaldoitem, 0);

      if vstipocontacorrente = 'G' then
        UPDATE pcgerente
           SET vlcorrente = vnvlcorrente_atual
         WHERE codgerente = vnCodigoGerente;
      ELSIF vstipocontacorrente = 'S' then
        UPDATE pcsuperv
           SET vlcorrente = vnvlcorrente_atual
         WHERE codsupervisor = vnCodigoSupervisor;
      else
       ccrca_bloquear_registro_rca(vncodusur);

        UPDATE pcusuari
           SET vlcorrente = vnvlcorrente_atual
         WHERE codusur = vncodusur;
      end if;

      INSERT INTO pclogdebcred
        (numped,
         posicao,
         numtransvenda,
         tipocontacorrente,
         DATA,
         codfunc,
         codigo,
         rotina,
         vlcorrente,
         vllimcred,
         vlcorrenteant,
         vllimcredant,
         codprod,
         numseq,
         historico)
      VALUES
        (vnnumped,
         vsposicao,
         p_numtransvenda,
         vstipocontacorrente,
         SYSDATE,
         p_codfunclanc,
         decode(vstipocontacorrente, 'S', vnCodigoSupervisor, 'G', vnCodigoGerente, vncodusur),
         p_rotinalanc,
         vnvlcorrente_atual,
         vnvllimcred,
         vnvlcorrente_ant,
         vnvllimcred,
         reg.codprod,
         reg.numseq,
         SUBSTR('CTRLCCRCA: ACERTO NF', 1, 60));

      if (vstipocontacorrente <> 'S') and (vstipocontacorrente <> 'G') then
        INSERT INTO pclogrca
          (numped,
           posicao,
           numtransvenda,
           DATA,
           codfunc,
           codusur,
           rotina,
           vlcorrente,
           vllimcred,
           vlcorrenteant,
           vllimcredant,
           codprod,
           numseq,
           historico,
           seqlogrca)
        VALUES
          (vnnumped,
           vsposicao,
           p_numtransvenda,
           SYSDATE,
           p_codfunclanc,
           vncodusur,
           p_rotinalanc,
           vnvlcorrente_atual,
           vnvllimcred,
           vnvlcorrente_ant,
           vnvllimcred,
           reg.codprod,
           reg.numseq,
           SUBSTR('CTRLCCRCA: ACERTO NF', 1, 60),
           DFSEQ_PCLOGRCA.NEXTVAL);
       END IF;
     end if;
    END LOOP;

    UPDATE pcnfsaid
       SET dtfechaccrca = SYSDATE
     WHERE numtransvenda = p_numtransvenda;

  END; --ccrca_validar_acerto_nf

  PROCEDURE ccrca_lancar_movimento_carga(p_codfunclanc         IN pclogrca.codfunc%TYPE,
                                         p_rotinalanc          IN pclogrca.rotina%TYPE,
                                         p_numcar              IN pcnfsaid.numcar%TYPE,
                                         p_dataemissao_inicial IN DATE,
                                         p_dataemissao_final   IN DATE,
                                         p_mensagem            OUT VARCHAR2) IS
    vbvalido   BOOLEAN;
    vsmensagem VARCHAR2(300);
  BEGIN
    vsmensagem := 'OK';

    IF NVL(p_numcar, 0) = 0 THEN
      FOR reg IN (SELECT numtransvenda, dtfechaccrca
                    FROM pcnfsaid
                   WHERE numcar = NVL(p_numcar, 0)
                        --Tarefa 105946
                     AND pcnfsaid.dtcancel is null
                     AND EXISTS (select pcpedc.numtransvenda
                            from pcpedc
                           where pcpedc.numtransvenda =
                                 pcnfsaid.numtransvenda)
                     AND dtsaida BETWEEN p_dataemissao_inicial AND
                         p_dataemissao_final) LOOP
        vbvalido := ccrca_verificar_fechamento(reg.numtransvenda);

        IF vbvalido = TRUE THEN
          IF reg.dtfechaccrca IS NULL THEN
            ccrca_validar_acerto_nf(p_codfunclanc,
                                    p_rotinalanc,
                                    reg.numtransvenda);
          END IF;
        END IF;
      END LOOP;
    ELSE
      FOR reg IN (SELECT numtransvenda, dtfechaccrca
                    FROM pcnfsaid
                   WHERE numcar = p_numcar
                        --Tarefa 105946
                     AND EXISTS (select pcpedc.numtransvenda
                            from pcpedc
                           where pcpedc.numtransvenda =
                                 pcnfsaid.numtransvenda)
                     AND pcnfsaid.dtcancel is null) LOOP
        vbvalido := ccrca_verificar_fechamento(reg.numtransvenda);

        IF vbvalido = TRUE THEN
          IF reg.dtfechaccrca IS NULL THEN
            ccrca_validar_acerto_nf(p_codfunclanc,
                                    p_rotinalanc,
                                    reg.numtransvenda);
          END IF;
        END IF;
      END LOOP;
    END IF;

    p_mensagem := vsmensagem;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao lancar movimento carga.' || SQLCODE || ' ' ||
                    SQLERRM;
  END; --ccrca_lancar_movimento_Carga

  PROCEDURE ccrca_lancar_movimento_caixa(p_codfunclanc     IN pclogrca.codfunc%TYPE,
                                         p_rotinalanc      IN pclogrca.rotina%TYPE,
                                         p_numcheckout     IN pcpedc.numcaixa%TYPE,
                                         p_codfunccheckout IN pcnfsaid.codfunclanc%TYPE,
                                         p_dataemissao     IN DATE,
                                         p_mensagem        OUT VARCHAR2) IS
    vbvalido   BOOLEAN;
    vsmensagem VARCHAR2(300);
  BEGIN
    vsmensagem := 'OK';

    FOR reg IN (SELECT numtransvenda, dtfechaccrca
                  FROM pcnfsaid
                 WHERE caixa = p_numcheckout
                   AND codemitente = p_codfunccheckout
                   AND dtsaida = p_dataemissao
                      --Tarefa 105946
                   AND EXISTS
                 (select pcpedc.numtransvenda
                          from pcpedc
                         where pcpedc.numtransvenda = pcnfsaid.numtransvenda)
                   AND pcnfsaid.dtcancel is null) LOOP
      vbvalido := ccrca_verificar_fechamento(reg.numtransvenda);

      IF vbvalido = TRUE THEN
        IF reg.dtfechaccrca IS NULL THEN
          ccrca_validar_acerto_nf(p_codfunclanc,
                                  p_rotinalanc,
                                  reg.numtransvenda);
        END IF;
      END IF;
    END LOOP;

    p_mensagem := vsmensagem;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao lancar movimento caiga.' || SQLCODE || ' ' ||
                    SQLERRM;
  END; --ccrca_lancar_movimento_caixa

  --RNG07 / PARA ALTERACAO DE PRECO
  FUNCTION ccrca_retorna_saldo_anterior( -- 11 parametros
                                        p_numped                    IN pcpedc.numped%TYPE,
                                        p_codusur                   IN pcpedc.codusur%TYPE,
                                        p_codprod                   IN pcpedi.codprod%TYPE,
                                        p_numseq                    IN pcpedi.numseq%TYPE,
                                        p_qt                        IN pcpedi.qt%TYPE,
                                        p_pvenda                    IN pcpedi.pvenda%TYPE,
                                        p_pbaserca                  IN pcpedi.pbaserca%TYPE,
                                        p_ptabela                   IN pcpedi.ptabela%TYPE,
                                        p_tipo                      IN VARCHAR,
                                        p_usadebcredrcabrind        IN pcpedi.usadebcredrcabrind%TYPE,
                                        p_movimentacontacorrenterca IN pcpedi.movimentacontacorrenterca%type
                                        -- Sabrina: tipo de operação I - Inclusao e E - Exclusao
                                        ) RETURN NUMBER IS
    vsusacredrca           pcpedc.usacredrca%TYPE;
    vsbonificaltdebcredrca pcpedc.bonificaltdebcredrca%TYPE;
    vstrocaaltdebcredrca   pcpedc.trocaaltdebcredrca%TYPE;
    vsbrokeraltdebcredrca  pcpedc.brokeraltdebcredrca%TYPE;
    vscrmaltdebcredrca     pcpedc.crmaltdebcredrca%TYPE;
    vstipomovccrca         pcpedc.tipomovccrca%TYPE;
    vsusadebcredrca        pcpedc.usadebcredrca%TYPE;
    vsorigemped            pcpedc.origemped%TYPE;
    vsbrinde               pcpedc.brinde%TYPE;
    vncondvenda            pcpedc.condvenda%TYPE;
    vsbroker               pcpedc.broker%TYPE;
    vsbonific              pcpedi.BONIFIC%TYPE; --HIS.02580.2015
    vnlanc                 NUMBER;
    vsmsg                  VARCHAR2(400);
    vstipocontacorrente pcpedc.tipocontacorrente%TYPE;
  BEGIN
    proc_lerparametros(vsmsg);

    SELECT p.usacredrca,
           p.bonificaltdebcredrca,
           p.trocaaltdebcredrca,
           p.brokeraltdebcredrca,
           p.crmaltdebcredrca,
           p.tipomovccrca,
           p.usadebcredrca,
/*           DECODE(p.usadebcredrca,
                  NULL,
                  (SELECT NVL(pcusuari.usadebcredrca, gregpcconsum.usacredrca)
                     FROM pcusuari
                    WHERE codusur = p.codusur
                      AND ROWNUM = 1),
                  p.usadebcredrca),*/
           p.origemped,
           NVL(p.brinde, 'N'),
           p.condvenda,
           NVL(p.broker, 'N')
      INTO vsusacredrca,
           vsbonificaltdebcredrca,
           vstrocaaltdebcredrca,
           vsbrokeraltdebcredrca,
           vscrmaltdebcredrca,
           vstipomovccrca,
           vsusadebcredrca,
           vsorigemped,
           vsbrinde,
           vncondvenda,
           vsbroker
      FROM pcpedc p
     WHERE p.numped = p_numped;

     IF vsusadebcredrca IS NULL THEN
        SELECT CASE WHEN vstipocontacorrente = 'S' 
                    THEN NVL(PCSUPERV.USADEBCRED,gregpcconsum.usacredsupervisor)
                    WHEN vstipocontacorrente = 'G' 
                    THEN NVL(PCGERENTE.USADEBCRED,gregpcconsum.usacredgerente)                
                    ELSE NVL(PCUSUARI.USADEBCREDRCA,gregpcconsum.usacredrca)
               END USADEBCRED
          INTO vsusadebcredrca   
          FROM PCPEDC
         INNER JOIN PCUSUARI ON (PCUSUARI.CODUSUR       = PCPEDC.CODUSUR)
         INNER JOIN PCSUPERV ON (PCSUPERV.CODSUPERVISOR = NVL(PCPEDC.CODSUPERVISOR, PCUSUARI.CODSUPERVISOR))
          LEFT JOIN PCGERENTE ON (PCGERENTE.CODGERENTE   = NVL(PCPEDC.CODGERENTE, PCSUPERV.CODGERENTE))
         WHERE PCPEDC.NUMPED = p_numped;    
     END IF;

    SELECT NVL(PCPEDI.BONIFIC, 'N') BONIFIC
      INTO vsbonific
      FROM PCPEDI
     WHERE PCPEDI.NUMPED = P_NUMPED
       AND PCPEDI.CODPROD = P_CODPROD
       AND PCPEDI.NUMSEQ = P_NUMSEQ;

    IF p_qt > 0 THEN
      vnlanc := ccrca_saldo_item(NVL(vsusacredrca, gregpcconsum.usacredrca),
                                 vsusadebcredrca,
                                 vsbroker,
                                 vsorigemped,
                                 NVL(vsbonificaltdebcredrca,
                                     gregpcconsum.bonificaltdebcredrca),
                                 NVL(vstrocaaltdebcredrca,
                                     gregpcconsum.trocaaltdebcredrca),
                                 NVL(vscrmaltdebcredrca,
                                     gregpcconsum.crmaltdebcredrca),
                                 NVL(vsbrokeraltdebcredrca,
                                     gregpcconsum.brokeraltdebcredrca),
                                 NVL(vstipomovccrca,
                                     NVL(gregpcconsum.tipomovccrca, 'VV')),
                                 vncondvenda,
                                 vsbrinde,
                                 p_codusur,
                                 'V',
                                 p_pvenda,
                                 p_ptabela,
                                 NVL(p_pbaserca, p_ptabela),
                                 p_qt,
                                 p_usadebcredrcabrind,
                                 p_movimentacontacorrenterca,
                                 vsbonific);
    ELSE
      vnlanc := 0; --(recebimentos em trocas)
    END IF;

    RETURN vnlanc;
  END; --ccrca_retornar_saldo_anterior


  FUNCTION CONTROLASALDORCA(psUsaCredRCAPCCONSUM      IN VARCHAR2,
                            psUsaDebCredRCA           IN VARCHAR2,
                            psBrinde                  IN VARCHAR2,
                            psBonificaAltDebCredRCA   IN VARCHAR2,
                            psTrocaAltDebCredRCA      IN VARCHAR2,
                            psBroker                  IN VARCHAR2,
                            psBrokerAltDebCredRCA     IN VARCHAR2,
                            psOrigemPed               IN VARCHAR2,
                            psCRMAltDebCredRCA        IN VARCHAR2,
                            psUsaDebCredRCACliente    IN VARCHAR2,
                            piCondVenda               IN NUMBER,
                            psBonificacaoMovimentaCC  IN VARCHAR2,
                            piVersaoIntegradora       IN NUMBER   DEFAULT 0)
  RETURN VARCHAR2 IS

    RESULT                     VARCHAR2(1);
    vbCondVendaValido          boolean;
    vbPedidoNaoBrinde          boolean;
    vbValidaCondVenda5         boolean;
    vbValidadeCondVenda11      boolean;
    vbUsaCredRCA               boolean;
    vbValidaCallCenter         boolean;
    vbValidaBroker             boolean;
    vbValidaWebIntegradora29   boolean;

  BEGIN

    vbUsaCredRCA := (psUsaCredRCAPCCONSUM = 'S') and (psUsaDebCredRCA = 'S') and (psUsaDebCredRCACliente = 'S');
    vbCondVendaValido := false;

    if piCondVenda not in (4, 8, 10, 13, 16, 20) then
      vbCondVendaValido := true;
    end if;


    vbPedidoNaoBrinde        := (psBrinde = 'N');
    vbValidaCondVenda5       := (piCondVenda = 5) and (psBonificaAltDebCredRCA = 'S') and (psBonificacaoMovimentaCC = 'S');
    vbValidadeCondVenda11    := (piCondVenda = 11) and (psTrocaAltDebCredRCA = 'S');
    vbValidaBroker           := (psbroker = 'S') and (psBrokerAltDebCredRCA = 'S');
    vbValidaCallCenter       := (psOrigemPed = 'C') and (psCRMAltDebCredRCA = 'S');
    vbValidaWebIntegradora29 := (psOrigemPed = 'W') and (piVersaoIntegradora = 29);

    if not vbUsaCredRCA then
      Result := 'N';
    elsif not vbCondVendaValido then
      Result := 'N';
    elsif (piCondVenda <> 5) and (not vbPedidoNaoBrinde) then
      Result := 'N';
    elsif (piCondVenda = 5) and (not vbValidaCondVenda5) then
      Result := 'N';
    elsif (piCondVenda = 11) and (not vbValidadeCondVenda11) then
      Result := 'N';
    elsif (psBroker = 'S') and (not vbValidaBroker) then
      Result := 'N';
    elsif (psOrigemPed = 'C') and (not vbValidaCallCenter) then
      Result := 'N';
    elsif vbValidaWebIntegradora29 then
      Result := 'N';
    else
      Result := 'S';
    end if;


    RETURN(RESULT);


  END CONTROLASALDORCA;


  FUNCTION CONTROLASALDORCA(pnumped IN  NUMBER,
                            vmsg    OUT VARCHAR2,
                            pcodprod in number default 0,
                            pnumseq in number default 0)
    RETURN VARCHAR2 IS

    RESULT                     VARCHAR2(1);
    vspcconsumusacredrca       VARCHAR2(1);
    vsusadebcredrca            VARCHAR2(1);
    vsbrinde                   VARCHAR2(1);
    vsbonificaltdebcredrca     VARCHAR2(1);
    vstrocaaltdebcredrca       VARCHAR2(1);
    vsbroker                   VARCHAR2(1);
    vsbrokeraltdebcredrca      VARCHAR2(1);
    vsorigemped                VARCHAR2(1);
    vscrmaltdebcredrca         VARCHAR2(1);
    vsclient_consusadebcredrca VARCHAR2(1);
    vsBonificacaoMovimentaCC   VARCHAR2(1);
    vncondvenda                NUMBER;
    vncodbonific               NUMBER;
    vsBrindePCPEDi             VARCHAR2(1);
    vnVersaoIntegradora        NUMBER(6);
    vsUsadebcredrcabrind       VARCHAR2(1);
  BEGIN

    BEGIN
      SELECT pcpedc.usadebcredrca,
             pcpedc.brinde,
             pcpedc.bonificaltdebcredrca,
             pcpedc.trocaaltdebcredrca,
             pcpedc.broker,
             pcpedc.brokeraltdebcredrca,
             pcpedc.origemped,
             pcpedc.crmaltdebcredrca,
             pcclient.usadebcredrca,
             pcpedc.condvenda,
             pcpedc.CODBNF,
             PCPEDC.INTEGRADORA
        INTO vsusadebcredrca,
             vsbrinde,
             vsbonificaltdebcredrca,
             vstrocaaltdebcredrca,
             vsbroker,
             vsbrokeraltdebcredrca,
             vsorigemped,
             vscrmaltdebcredrca,
             vsclient_consusadebcredrca,
             vncondvenda,
             vncodbonific,
             vnVersaoIntegradora
        FROM pcpedc,
             pcclient
       WHERE pcpedc.codcli = pcclient.codcli
          AND numped = pnumped;
    EXCEPTION
      WHEN no_data_found THEN
        vmsg   := 'Pedido ou cliente não localizado';
        RESULT := 'N';
        RETURN(RESULT);
      WHEN OTHERS THEN
        vmsg   := 'Erro ao verificar se pedido usa ou não conta corrente. Erro original: ' ||
                  SQLCODE || ' ' || SQLERRM;
        RESULT := 'N';
        RETURN(RESULT);
    END;

    /*************  HIS.01363.2016 *****************/
    IF (VNCONDVENDA = 5) AND (NVL(VNCODBONIFIC, 0) > 0) THEN
      BEGIN
        SELECT NVL(A.MOVIMENTACCRCA,'S') MOVIMENTACCRCA
          INTO vsBonificacaoMovimentaCC
          FROM PCTIPOBONIFIC A
         WHERE A.CODBNF = VNCODBONIFIC;
      EXCEPTION
        WHEN no_data_found THEN
          vsBonificacaoMovimentaCC := 'N';
        WHEN OTHERS THEN
          vmsg   := 'Erro ao buscar dados do tipo de bonificação. Erro original: ' ||
                    SQLCODE || ' - ' || SQLERRM;
          RESULT := 'N';
          RETURN(RESULT);
      END;
    ELSE
         vsBonificacaoMovimentaCC := 'S';
    END IF;
    /*************  HIS.01363.2016 ***************/

    /*
    Autor      : Rafael Braga
    Solicitação: 2050.135853.2016
    Data       : 13/12/2016
    Descrição  : Validando se o item do pedido é brinde.
    */
    begin
    if (pnumseq > 0) and (pcodprod > 0) then
      select brinde,Usadebcredrcabrind
        into vsBrindePCPEDi,vsUsadebcredrcabrind
        from pcpedi
       where numped = pNumped
         and numseq = pnumseq
         and codprod = pcodprod;
    end if;
    exception
      when others then
        vsBrindePCPEDi := null;
    end;

    vspcconsumusacredrca :=  NVL(PARAMFILIAL.ObterComoBoolean('CON_USACREDRCA'),'S');
    vsbrinde := nvl(vsBrindePCPEDi, NVL(vsBrinde, 'N')); -- Ajustado para a variável de Brinde não retornar nula.
    vsbonificaltdebcredrca := NVL(vsUsadebcredrcabrind,vsbonificaltdebcredrca);

    -- 3285.143772.2016 - Ajustado para observar o parâmetro "CON_BONIFICALTDEBCREDRCA'
    IF (VNCONDVENDA = 14) AND (vsbrinde = 'S')   AND
       (NVL(PARAMFILIAL.ObterComoBoolean('CON_BONIFICALTDEBCREDRCA'),'N') = 'S') THEN
      vsbrinde := 'N';
    END IF;
    -- 3285.143772.2016


    RESULT := CONTROLASALDORCA(vspcconsumusacredrca,
                               vsusadebcredrca,
                               vsbrinde,
                               vsbonificaltdebcredrca,
                               vstrocaaltdebcredrca,
                               vsbroker,
                               vsbrokeraltdebcredrca,
                               vsorigemped,
                               vscrmaltdebcredrca,
                               vsclient_consusadebcredrca,
                               vncondvenda,
                               vsBonificacaoMovimentaCC,
                               vnVersaoIntegradora);

    RETURN (RESULT);

  END CONTROLASALDORCA;

  FUNCTION CONTROLASALDORCA(pnumped IN  NUMBER)
    RETURN VARCHAR2 IS
    RESULT                     VARCHAR2(1);
    vMsg                       VARCHAR2(500);
  BEGIN




    RESULT := CONTROLASALDORCA(pnumped,
                               vMsg);

    RETURN (RESULT);


  END CONTROLASALDORCA;

  PROCEDURE ccrca_bloquear_registro_rca(p_codusur IN PCUSUARI.CODUSUR%TYPE) IS
    VNCODUSUR NUMBER;
  BEGIN
    SELECT CODUSUR
      INTO VNCODUSUR
      FROM PCUSUARI
     WHERE CODUSUR = p_codusur
       FOR UPDATE;
  END ccrca_bloquear_registro_rca;




END; --PC_PKG_CONTROLARSALDORCA
