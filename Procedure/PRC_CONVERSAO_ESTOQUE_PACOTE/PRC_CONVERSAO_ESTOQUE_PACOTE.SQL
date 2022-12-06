CREATE OR REPLACE PROCEDURE PRC_CONVERSAO_ESTOQUE_PACOTE(p_CondVenda    IN NUMBER,
                                                         p_codfilial    IN VARCHAR2,
                                                         p_codprod      IN NUMBER,
                                                         p_qtsolicitada IN NUMBER,
                                                         p_mensagem     OUT VARCHAR2,
                                                         p_numped       IN NUMBER DEFAULT 0,
                                                         p_codfunc      IN NUMBER DEFAULT 0) IS

  /**************************************************************************************************************
   Proposito: Função de conversão de unidade de estoque
   Versao: 18 Pacote

                            HISTORICO DE MODIFICACOES
  ---------------------------------------------------------------------------------------------------------------
   Responsavel          Data        Tarefa               Comentarios
  ----------------     ---------- --------------------------------------------------------------------------------------
   Pablo               24/09/2007  48308  Procedure criada apartir de PRC_CONVERSAO_ESTOQUE
                                          que passa a validar o parâmetro (PCConsum.AtualizaEstContConvEmbalagem) e
                                          caso o Tipo de Venda não seja 3, 6 ou 12 (PCEst.QtEst) também será convertido
   Pablo               19/03/2008  57511  Alteração para validar o novo Parâmetro (PCConsum.SempreAtualizaQtEstConvEmb)
                                          caso o mesmo esteja habilitado será Convertido o QtEst para venda 3,6,12.
   Sabrina             20/03/2008  59458  Correcao para Biriba: para aparecer no livro de producao (PCSIS1070)
                                          ao transferir o contabil deve ser gravado status AB e QT > 0 no pcmov
   Rogério             06/05/2008  62152  No update para Custo Contábil acrescentado um GREATEST no campo QTEST da tabela PCEST
   Rogério             12/05/2008  62665  No update para Custo Rep. acrescentado um GREATEST no campo QTESTGER da tabela PCEST
   Marcos              19/11/2010  120566 Não estava verificando o lote na hora de gerar o PCMOV. Causando uma exceção.
   Thiago Alves        01/02/2010  125941 Validação do parametro USAWMS
   Rodrigo Santos      22/10/2012  178471 Implementadas validações da versão 17.
   Luciano Lima        14/02/2014  1348.015972.2014 Implementado o campo DESCRICAO1 no insert da PCMOV para guardar a qtd
	                                                  de produtos solicitados, para efeito de rastreamento.
   Marcos Garcia       05/08/2015 1169.073630.2015 Comentado o commit abaixo pois estava commitando metade da transação na 336 dando problemas sérios de estoque - Marcos Garcia
   Guilherme Freitas   20/12/2015 HIS.04273.2015 Criado processo para gravar tabela com mapeamento do processo de conversão de estoque Pai/Filho
  ***************************************************************************************************************/

  vbretorno                   BOOLEAN;
  vsmensagem                  VARCHAR2(1000);
  vicontador                  NUMBER;
  vsControlaEstCont           VARCHAR2(1);
  vbNaoConverteQtEstTV_3_6_12 BOOLEAN;
  -- Parametros do Sisgtema
  --vsusawms                       pcconsum.usawms%type;
  vsusawms                       pcfilial.usawms%type;
  vsAtualizaEstContConvEmbalagem pcconsum.AtualizaEstContConvEmbalagem%type;
  vsSempreAtualizaQtEstConvEmb   pcconsum.SempreAtualizaQtEstConvEmb%type;
  -- Dados do Produto
  vncodprodmaster pcprodut.codprodmaster%TYPE;
  vncodprodunit   pcprodut.codprod%TYPE;
  vnqtunitmin     pcprodut.qtunit%TYPE;
  vnqtunit        pcprodut.qtunit%TYPE;
  vnqtunitmaster  pcprodut.qtunit%TYPE;
  vstipoestoque   pcprodut.tipoestoque%TYPE;
  vsaceitavendafracao pcprodut.aceitavendafracao%TYPE;
  vnqt_unidades   NUMBER;
  vnqt_caixas     NUMBER;
  vnqt_resto      NUMBER;
  vnnumtransvenda pcmov.numtransvenda%TYPE;
  vnnumtransent   pcmov.numtransent%TYPE;  --Tarefa: 178471
  -- Dados do Estoque do Produto na menor unidade de venda do produto
  vncustofin_min       pcest.custofin%TYPE;
  vncustoreal_min      pcest.custoreal%TYPE;
  vncustorep_min       pcest.custorep%TYPE;
  vncustocont_min      pcest.custocont%TYPE;
  vnnewcustorep_min    pcest.custorep%TYPE;
  vnnewcustocont_min   pcest.custocont%TYPE;
  vnnewcustofin_min    pcest.custofin%TYPE;
  vnnewcustoreal_min   pcest.custoreal%TYPE;
  vncustoultent_min    pcest.custoultent%TYPE;
  vnvalorultent_min    pcest.valorultent%TYPE;
  vncustofinant_min    pcmov.custofinant%TYPE;
  vncustorealant_min   pcmov.custorealant%TYPE;
  vncustoultentant_min pcmov.custoultentant%TYPE;
  vncustorealsemst_min    pcest.custorealsemst%TYPE;
  vncustorealliq_min      pcest.custorealliq%TYPE;
  vncustofinsemst_min     pcest.custofinsemst%TYPE;
  vnnewcustorealsemst_min pcmov.custorealsemst%TYPE;
  vncustorealsemstant_min pcmov.custorealsemstant%TYPE;
  -- Dados do Estoque do Produto em Unidade de Venda
  vncustofin_un       pcest.custofin%TYPE;
  vncustoreal_un      pcest.custoreal%TYPE;
  vncustorep_un       pcest.custorep%TYPE;
  vncustocont_un      pcest.custocont%TYPE;
  vnnewcustorep_un    pcest.custorep%TYPE;
  vnnewcustocont_un   pcest.custocont%TYPE;
  vnnewcustofin_un    pcest.custofin%TYPE;
  vnnewcustoreal_un   pcest.custoreal%TYPE;
  vncustoultent_un    pcest.custoultent%TYPE;
  vnvalorultent_un    pcest.valorultent%TYPE;
  vncustofinant_un    pcmov.custofinant%TYPE;
  vncustorealant_un   pcmov.custorealant%TYPE;
  vncustoultentant_un pcmov.custoultentant%TYPE;
  vncustorealsemst_un    pcest.custorealsemst%TYPE;
  vncustorealliq_un      pcest.custorealliq%TYPE;
  vncustofinsemst_un     pcest.custofinsemst%TYPE;
  vnnewcustorealsemst_un pcmov.custorealsemst%TYPE;
  vncustorealsemstant_un pcmov.custorealsemstant%TYPE;
  vnnumlote           pcmov.numlote%type;
  -- Dados do Estoque do Produto em Caixa
  vnqtdisp            pcest.qtestger%TYPE;
  vnqtdisp_cont       pcest.qtestger%TYPE;
  vnqtestger          pcest.qtestger%TYPE;
  vnQtEst             pcest.qtest%TYPE;
  vnqtreserv          pcest.qtreserv%TYPE;
  vnqtbloqueada       pcest.qtbloqueada%TYPE;
  vncustofin_cx       pcest.custofin%TYPE;
  vncustoreal_cx      pcest.custoreal%TYPE;
  vncustorep_cx       pcest.custorep%TYPE;
  vncustocont_cx      pcest.custocont%TYPE;
  vncustoultent_cx    pcest.custoultent%TYPE;
  vnvalorultent_cx    pcest.valorultent%TYPE;
  vncustofinant_cx    pcmov.custofinant%TYPE;
  vncustorealant_cx   pcmov.custorealant%TYPE;
  vncustoultentant_cx pcmov.custoultentant%TYPE;
  vsestoqueporlote_cx pcprodut.estoqueporlote%type;
  vncustorealsemst_cx    pcest.custorealsemst%TYPE;
  vncustorealliq_cx      pcest.custorealliq%TYPE;
  vncustofinsemst_cx     pcest.custofinsemst%TYPE;
  vnnewcustorealsemst_cx pcmov.custorealsemst%TYPE;
  vncustorealsemstant_cx pcmov.custorealsemstant%TYPE;

  -- Dados de Cadastro do Produto em unidade de venda
  vncodepto_min   pcprodut.codepto%TYPE;
  vncodsec_min    pcprodut.codsec%TYPE;
  vncodfornec_min pcprodut.codfornec%TYPE;
  -- Dados de Cadastro do Produto em unidade de venda
  vncodepto_un        pcprodut.codepto%TYPE;
  vncodsec_un         pcprodut.codsec%TYPE;
  vncodfornec_un      pcprodut.codfornec%TYPE;
  vsestoqueporlote_un pcprodut.estoqueporlote%type;
  -- Dados de Cadastro do Produto em caixa
  vncodepto_cx   pcprodut.codepto%TYPE;
  vncodsec_cx    pcprodut.codsec%TYPE;
  vncodfornec_cx pcprodut.codfornec%TYPE;
  vstipoestoque_cx       pcprodut.tipoestoque%TYPE;
  vsaceitavendafracao_cx pcprodut.aceitavendafracao%TYPE;
  exc_dado_invalido EXCEPTION;
  exc_lote_filho    EXCEPTION;
  erro_numtransvenda EXCEPTION;
  erro_numtransent   EXCEPTION;
  vnReturn          NUMBER;
  v_Count           NUMBER := 0;

  PROCEDURE GRAVAR_PCPAIFILHO(pCODOPER       VARCHAR2,
                              pCODPROD       NUMBER,
                              pNUMTRANSENT   NUMBER,
                              pNUMTRANSVENDA NUMBER,
                              pNUMPED        NUMBER,
                              pQTDE          NUMBER)
  IS
  BEGIN
    INSERT INTO PCPAIFILHO(CODOPER
                          ,CODPROD
                          ,NUMTRANSENT
                          ,NUMTRANSVENDA
                          ,NUMPED
                          ,QT) VALUES
                          (pCODOPER
                          ,pCODPROD
                          ,pNUMTRANSENT
                          ,pNUMTRANSVENDA
                          ,pNUMPED
                          ,pQTDE);
  END GRAVAR_PCPAIFILHO;
BEGIN
  vbretorno  := TRUE;
  vsmensagem := '';
  vnnumlote  := NULL;

  BEGIN
    SELECT NVL(AtualizaEstContConvEmbalagem, 'N'),
           NVL(SempreAtualizaQtEstConvEmb, 'N')
      INTO vsAtualizaEstContConvEmbalagem,
           vsSempreAtualizaQtEstConvEmb
      FROM pcconsum
     WHERE rownum = 1;

     SELECT NVL(usawms, 'N')
       INTO vsusawms
      FROM pcfilial
     WHERE codigo = p_codfilial;

     if vsusawms = 'S' then
        select nvl(pcprodut.usawms,'N')
          into vsusawms
        from pcprodut where pcprodut.codprod = p_codprod;
     end if;


  EXCEPTION
    WHEN OTHERS THEN
      vbretorno  := FALSE;
      vsmensagem := 'PARAMETROS DO SISTEMA NAO ENCONTRADOS. ERRO: ' ||
                    SQLCODE || '-' || SQLERRM;
      RAISE;
  END;

  vbNaoConverteQtEstTV_3_6_12 := FALSE;

  vbNaoConverteQtEstTV_3_6_12 := (p_CondVenda IN (3, 6, 12));

  IF (vbNaoConverteQtEstTV_3_6_12) AND (vsSempreAtualizaQtEstConvEmb = 'S') THEN
    vbNaoConverteQtEstTV_3_6_12 := FALSE;
  END IF;

  vsControlaEstCont := 'N';
  IF (vsAtualizaEstContConvEmbalagem = 'S') AND
     (NOT vbNaoConverteQtEstTV_3_6_12) THEN
    vsControlaEstCont := 'S';
  END IF;

  --Tarefa: 178471
  /*IF vsusawms = 'S' THEN
    vbretorno  := FALSE;
    vsmensagem := 'SISTEMA ESTA USANDO WMS';
    RAISE exc_dado_invalido;
  END IF;*/
  --Fim Tarefa: 178471


  -- Verificar existencia do produto em caixa
  BEGIN
    SELECT pcprodut.codprodmaster,
           NVL(pcprodut.qtunit, 1),
           pcprodut.codepto,
           pcprodut.codsec,
           pcprodut.codfornec,
           NVL(pcprodut.estoqueporlote, 'N'),
           pcprodut.tipoestoque,
           pcprodut.aceitavendafracao
      INTO vncodprodmaster,
           vnqtunit,
           vncodepto_un,
           vncodsec_un,
           vncodfornec_un,
           vsestoqueporlote_un,
           vstipoestoque,
           vsaceitavendafracao
      FROM pcprodut
     WHERE codprod = p_codprod;

    SELECT NVL(qtunit, 0),
           pcprodut.codepto,
           pcprodut.codsec,
           pcprodut.codfornec,
           NVL(pcprodut.estoqueporlote, 'N'),
           pcprodut.tipoestoque,
           pcprodut.aceitavendafracao
      INTO vnqtunitmaster,
           vncodepto_cx,
           vncodsec_cx,
           vncodfornec_cx,
           vsestoqueporlote_cx,
           vstipoestoque_cx,
           vsaceitavendafracao_cx
      FROM pcprodut
     WHERE codprod = vncodprodmaster;
  EXCEPTION
    WHEN OTHERS THEN
      vbretorno  := FALSE;
      vsmensagem := 'PRODUTOS ORIGEM E DESTINO NAO ENCONTRADOS. ERRO: ' ||
                    SQLCODE || '-' || SQLERRM;
      RAISE;
  END;

  IF vnqtunitmaster = 0 THEN
    vbretorno  := FALSE;
    vsmensagem := 'QT. UNIT. DO PRODUTO EM CAIXA INVALIDO.';
    RAISE exc_dado_invalido;
  END IF;

  vnqt_resto := 0;

  IF (vstipoestoque = 'FR') AND (vsaceitavendafracao = 'S') and (vnqtunit = 1) and
     (vstipoestoque_cx = 'FR') and (vsaceitavendafracao_cx = 'S') and (vnqtunitmaster = 1) THEN
     vnqt_unidades := p_qtsolicitada;
     vnqt_caixas := vnqt_unidades / vnqtunitmaster;
  ELSE
    -- Calculo da quantidade necessaria do produto em unidades
    vnqt_unidades := p_qtsolicitada * vnqtunit;
    -- Calculo da quantidade necessaria em caixas
    vnqt_caixas := vnqt_unidades / vnqtunitmaster;

    IF vnqt_caixas <> TRUNC(vnqt_caixas) THEN
      if (vsaceitavendafracao <> 'S') or (vsaceitavendafracao_cx <> 'S') then
        vnqt_caixas   := TRUNC(vnqt_caixas) + 1;
      end if;
      vnqt_unidades := (vnqt_caixas * vnqtunitmaster) / vnqtunit;

      IF vnqt_unidades <> TRUNC(vnqt_unidades) THEN
        if (vsaceitavendafracao <> 'S') or (vsaceitavendafracao_cx <> 'S') then
           vnqt_unidades := CEIL(vnqt_unidades);
        end if;
        vnqt_resto    := (vnqt_caixas * vnqtunitmaster) -
                         (vnqt_unidades * vnqtunit);

        IF vnqt_resto > 0 THEN
          BEGIN
            SELECT pcprodut.codprod,
                   NVL(pcprodut.qtunit, 1),
                   pcprodut.codepto,
                   pcprodut.codsec,
                   pcprodut.codfornec
              INTO vncodprodunit,
                   vnqtunitmin,
                   vncodepto_min,
                   vncodsec_min,
                   vncodfornec_min
              FROM pcprodut
             WHERE codprodmaster = vncodprodmaster
               AND qtunit = 1;
          EXCEPTION
            WHEN OTHERS THEN
              vbretorno  := FALSE;
              vsmensagem := 'Não existe produto associado ao produto master, onde a qtde. unitária. seja igual a 01(um) .';
              RAISE;
          END;
        END IF;
      END IF;
    ELSE
      vnqt_unidades := vnqt_unidades / vnqtunit;
    END IF;
  END IF;

  -- Gerar numeracao de transacao
  BEGIN

   BEGIN
    v_Count := 0;

    WHILE (v_Count <= 50) and (nvl(vnnumtransvenda,0) = 0) LOOP
      v_Count := v_Count + 1;

      vnnumtransvenda := FERRAMENTAS.F_PROX_NUMTRANSVENDA; -- 1169.118737.2015

      if vnnumtransvenda <> 0 then
        exit;
      end if;

      if (vnnumtransvenda = 0) and (v_Count >= 10) then
        raise erro_numtransvenda;
      end if;

    END LOOP;
  END;

  BEGIN
     v_Count := 0;

     WHILE (v_Count <= 50) and (nvl(vnnumtransent,0) = 0) LOOP
       v_Count := v_Count + 1;

       vnnumtransent := FERRAMENTAS.F_PROX_NUMTRANSENT; -- 1169.118737.2015

       if vnnumtransent <> 0 then
         exit;
       end if;

       if (vnnumtransent = 0) and (v_Count >= 10) then
         raise erro_numtransent;
       end if;

     END LOOP;
   END;

  EXCEPTION
    WHEN erro_numtransvenda THEN
      vbretorno  := FALSE;
      vsmensagem := 'NAO FOI POSSIVEL GERAR NUMERO DE TRANSACAO(Numtransvenda). ERRO: Rotina retornou numtransvenda = 0.';
     --1169.073630.2015 Comentado o ROLLBACK abaixo pois estava commitando metade da transação na 336 dando problemas sérios de estoque - Marcos Garcia
     --ROLLBACK;
      RAISE;

   WHEN erro_numtransent THEN
     vbretorno  := FALSE;
      vsmensagem := 'NAO FOI POSSIVEL GERAR NUMERO DE TRANSACAO(Numtransent). ERRO: Rotina retornou Numtransent = 0. ';
     --1169.073630.2015 Comentado o ROLLBACK abaixo pois estava commitando metade da transação na 336 dando problemas sérios de estoque - Marcos Garcia
     --ROLLBACK;
      RAISE;

    WHEN OTHERS THEN
      vbretorno  := FALSE;
      vsmensagem := 'NAO FOI POSSIVEL GERAR NUMERO DE TRANSACAO. ERRO: ' ||
                    SQLCODE || '-' || SQLERRM;
     --1169.073630.2015 Comentado o ROLLBACK abaixo pois estava commitando metade da transação na 336 dando problemas sérios de estoque - Marcos Garcia
     --ROLLBACK;
      RAISE;
  END;

  -- Verificar se ha estoque suficiente do produto em caixa
  BEGIN
    SELECT NVL(pcest.qtestger, 0),
           NVL(pcest.QTEST, 0),
           NVL(pcest.qtreserv, 0),
           NVL(pcest.qtbloqueada, 0),
           NVL(pcest.custofin, 0),
           NVL(pcest.custoreal, 0),
           NVL(pcest.custorep, 0),
           NVL(pcest.custocont, 0),
           NVL(pcest.custoultent, 0),
           NVL(pcest.valorultent, 0),
           NVL(pcest.custorealsemst, 0),
           NVL(pcest.custorealliq, 0),
           NVL(pcest.custofinsemst, 0)
      INTO vnqtestger,
           vnQtEst,
           vnqtreserv,
           vnqtbloqueada,
           vncustofin_cx,
           vncustoreal_cx,
           vncustorep_cx,
           vncustocont_cx,
           vncustoultent_cx,
           vnvalorultent_cx,
           vncustorealsemst_cx,
           vncustorealliq_cx,
           vncustofinsemst_cx
      FROM pcest
     WHERE codprod = vncodprodmaster
       AND codfilial = p_codfilial
       FOR UPDATE;

    vncustofinant_cx    := vncustofin_cx;
    vncustorealant_cx   := vncustoreal_cx;
    vncustoultentant_cx := vncustoultent_cx;
    vncustorealsemstant_cx := vncustorealsemst_cx;

    -- Qtde. disponivel do produto em caixa
    vnqtdisp := vnqtestger - (vnqtreserv + vnqtbloqueada);

    IF vnqtdisp < 0 THEN
      vnqtdisp := 0;
    END IF;

    -- Qtde. Contábil disponivel do produto em caixa
    vnqtdisp_cont := vnQtEst - (vnqtreserv + vnqtbloqueada);

    IF vnqtdisp_cont < 0 THEN
      vnqtdisp_cont := 0;
    END IF;

    IF vsControlaEstCont = 'S' THEN
      IF vnqtdisp > vnqtdisp_cont THEN
        vnqtdisp := vnqtdisp_cont;
      END IF;
    END IF;

    -- Se a quantidade disponivel for menor ou igual a solicitada
    -- fazer a baixa do estoque do produto em caixa
    IF vnqtdisp >= vnqt_caixas THEN
      -- Gerar saida do estoque de caixa
      UPDATE pcest
        -- existia update da quantidade gerencial - vnqt_caixas,
         SET dtultdesdobra = TRUNC(SYSDATE)
       WHERE codprod = vncodprodmaster
         AND codfilial = p_codfilial;

      IF vsControlaEstCont = 'S' THEN
        UPDATE pcest
        -- existia update da quantidade gerencial - vnqt_caixas,
           SET dtultdesdobra = TRUNC(SYSDATE)
         WHERE codprod = vncodprodmaster
           AND codfilial = p_codfilial;
      END IF;

      --tarefa 120566
      IF vsestoqueporlote_cx = 'S' THEN

        SELECT COUNT(*)
          INTO VICONTADOR
          FROM pclote
         WHERE codprod = vncodprodmaster
           AND codfilial = p_codfilial
           AND (pclote.qt - NVL(pclote.qtreserv, 0) -
               NVL(pclote.qtbloqueada, 0)) >= vnqt_caixas;

        if vicontador = 0 then
          vsmensagem := 'PRODUTO MASTER: ' || TO_CHAR(vncodprodmaster) ||
                        ' É CONTROLADO POR LOTE.' || CHR(13) ||
                        'NÃO EXISTE ESTOQUE EM LOTE PARA CONVERSÃO!';
          RAISE exc_lote_filho;

        ELSE

          BEGIN
            SELECT pclote.numlote
              INTO vnnumlote
              FROM pclote
             WHERE codprod = vncodprodmaster
               AND codfilial = p_codfilial
               AND (pclote.qt - nvl(pclote.qtreserv, 0) -
                   nvl(pclote.qtbloqueada, 0)) >= vnqt_caixas
               AND DTEXCLUSAO IS NULL
               AND TRUNC(SYSDATE) <= TRUNC(DTVALIDADE)
               AND ROWNUM = 1;

            --Tarefa 144297 ja tem o tratamento na trigger na pcmov
            /*UPDATE pclote
               SET qt = qt - vnqt_caixas
             WHERE codprod = vncodprodmaster
               AND codfilial = p_codfilial
               AND numlote = vnnumlote;*/
           --fim Tarefa 144297

          EXCEPTION
            WHEN OTHERS THEN
              vbretorno  := FALSE;
              vsmensagem := '-0- NAO FOI POSSIVEL LOCALIZAR LOTE DO PRODUTO MASTER. ERRO: ' ||
                            SQLCODE || '-' || SQLERRM;
              --1169.073630.2015 Comentado o ROLLBACK abaixo pois estava commitando metade da transação na 336 dando problemas sérios de estoque - Marcos Garcia
              --ROLLBACK;
              RAISE;
          END;
        end if;
      END IF;
      --fim tarefa 120566

      -- Gerar entrada no estoque de unidade
      SELECT NVL(pcest.custofin, 0),
             NVL(pcest.custoreal, 0),
             NVL(pcest.custorep, 0),
             NVL(pcest.custocont, 0),
             NVL(pcest.custoultent, 0),
             NVL(pcest.valorultent, 0),
             NVL(pcest.custorealsemst, 0)
        INTO vncustofin_un,
             vncustoreal_un,
             vncustorep_un,
             vncustocont_un,
             vncustoultent_un,
             vnvalorultent_un,
             vncustorealsemst_un
        FROM pcest
       WHERE codprod = p_codprod
         AND codfilial = p_codfilial
         FOR UPDATE;

      vncustofinant_un    := vncustofin_un;
      vncustorealant_un   := vncustoreal_un;
      vncustoultentant_un := vncustoultent_un;
      -- Calculo do Custo Medio
      vnnewcustofin_un  := (vncustofin_cx / vnqtunitmaster) * vnqtunit;
      vnnewcustoreal_un := (vncustoreal_cx / vnqtunitmaster) * vnqtunit;
      vnnewcustorep_un  := (vncustorep_cx / vnqtunitmaster) * vnqtunit;
      vnnewcustocont_un := (vncustocont_cx / vnqtunitmaster) * vnqtunit;

      vncustoultent_un := (vncustoultent_cx / vnqtunitmaster) * vnqtunit;
      vnvalorultent_un := (vnvalorultent_cx / vnqtunitmaster) * vnqtunit;

      vncustorealliq_un      := (vncustorealliq_cx / vnqtunitmaster) * vnqtunit;
      vncustofinsemst_un     := (vncustofinsemst_cx / vnqtunitmaster) * vnqtunit;
      vnnewcustorealsemst_un := (vncustorealsemst_cx / vnqtunitmaster) * vnqtunit;


      UPDATE pcest
         -- existia uma alteração da quantidade gerencial + vnqt_unidades,
         SET dtultdesdobra = TRUNC(SYSDATE),
             custoultent   = vncustoultent_un,
             valorultent   = vnvalorultent_un,
             custoreal     = ((NVL(custoreal, 0) *
                             GREATEST(NVL(qtestger, 0), 0)) +
                             (vnnewcustoreal_un * vnqt_unidades)) /
                             (GREATEST(GREATEST(NVL(qtestger, 0), 0) +
                                       vnqt_unidades,
                                       0)),
             custofin      = ((NVL(custofin, 0) *
                             GREATEST(NVL(qtestger, 0), 0)) +
                             (vnnewcustofin_un * vnqt_unidades)) /
                             (GREATEST(GREATEST(NVL(qtestger, 0), 0) +
                                       vnqt_unidades,
                                       0)),
             custorep      = ((NVL(custorep, 0) *
                             GREATEST(NVL(qtestger, 0), 0)) +
                             (vnnewcustorep_un * vnqt_unidades)) /
                             (GREATEST(GREATEST(NVL(qtestger, 0), 0) +
                                       vnqt_unidades,
                                       0)),
             custorealsemst  = ((NVL(custorealsemst, 0) *
                               GREATEST(NVL(qtestger, 0), 0)) +
                               (vnnewcustorealsemst_un * vnqt_unidades)) /
                               (GREATEST(GREATEST(NVL(qtestger, 0), 0) +
                                         vnqt_unidades,
                                         0)),
             custorealliq    = ((NVL(custorealliq, 0) *
                               GREATEST(NVL(qtestger, 0), 0)) +
                               (vncustorealliq_un * vnqt_unidades)) /
                               (GREATEST(GREATEST(NVL(qtestger, 0), 0) +
                                         vnqt_unidades,
                                         0)),
             custofinsemst   = ((NVL(custofinsemst, 0) *
                               GREATEST(NVL(qtestger, 0), 0)) +
                               (vncustofinsemst_un * vnqt_unidades)) /
                               (GREATEST(GREATEST(NVL(qtestger, 0), 0) +
                                         vnqt_unidades,
                                         0))
       WHERE codprod = p_codprod
         AND codfilial = p_codfilial;

      IF vsControlaEstCont = 'S' THEN
        UPDATE pcest
           -- existia uma alteração da quantidade gerencial  + vnqt_unidades,
           SET dtultdesdobra = TRUNC(SYSDATE),
               custocont     = ((NVL(custocont, 0) *
                               GREATEST(NVL(qtest, 0), 0)) +
                               (vnnewcustocont_un * vnqt_unidades)) /
                               (GREATEST(GREATEST(NVL(qtest, 0), 0) +
                                         vnqt_unidades,
                                         0))

         WHERE codprod = p_codprod
           AND codfilial = p_codfilial;

      END IF; -- IF vsControlaEstCont

      -- Tarefa 120566
      IF vsestoqueporlote_un = 'S' THEN
        begin

          IF vnnumlote IS NULL THEN
            vsmensagem := 'PRODUTO PAI NÃO POSSUI CONTROLE POR LOTE';
            RAISE exc_lote_filho;
          END IF;

          --Tarefa 144297 ja tem o tratamento na trigger na pcmov
          SELECT COUNT(0)
            INTO vicontador
            FROM pclote
           WHERE codprod = p_codprod
             AND codfilial = p_codfilial
             and numlote = vnNumlote;

          IF vicontador = 0 THEN
            INSERT INTO pclote
              (codprod, numlote, codfilial)
            VALUES
              (p_codprod, vnNumlote, p_codfilial);
          END IF;
          --fim Tarefa 144297
        exception
          WHEN OTHERS THEN
            vbretorno  := FALSE;
            vsmensagem := '-1- NAO FOI POSSIVEL LOCALIZAR LOTE DO PRODUTO FILHO. ERRO: ' ||
                          SQLCODE || '-' || SQLERRM;
            --1169.073630.2015 Comentado o ROLLBACK abaixo pois estava commitando metade da transação na 336 dando problemas sérios de estoque - Marcos Garcia
            --ROLLBACK;

            RAISE;
        end;
      END IF;
      -- Fim tarefa 120566

      IF vnqt_resto > 0 THEN
        -- Gerar entrada no estoque de unidade
        SELECT NVL(pcest.custofin, 0),
               NVL(pcest.custoreal, 0),
               NVL(pcest.custorep, 0),
               NVL(pcest.custocont, 0),
               NVL(pcest.custoultent, 0),
               NVL(pcest.valorultent, 0),
               NVL(pcest.custorealsemst, 0),
               NVL(pcest.custorealliq, 0),
               NVL(pcest.custofinsemst, 0)
          INTO vncustofin_min,
               vncustoreal_min,
               vncustorep_min,
               vncustocont_min,
               vncustoultent_min,
               vnvalorultent_min,
               vncustorealsemst_min,
               vncustorealliq_min,
               vncustofinsemst_min
          FROM pcest
         WHERE codprod = vncodprodunit
           AND codfilial = p_codfilial
           FOR UPDATE;

        vncustofinant_min    := vncustofin_min;
        vncustorealant_min   := vncustoreal_min;
        vncustoultentant_min := vncustoultent_min;
        -- Calculo do Custo Medio
        vnnewcustofin_min  := (vncustofin_cx / vnqtunitmaster) *
                              vnqtunitmin;
        vnnewcustoreal_min := (vncustoreal_cx / vnqtunitmaster) *
                              vnqtunitmin;
        vnnewcustorep_min  := (vncustorep_cx / vnqtunitmaster) *
                              vnqtunitmin;
        vnnewcustocont_min := (vncustocont_cx / vnqtunitmaster) *
                              vnqtunitmin;
        vncustoultent_min  := (vncustoultent_cx / vnqtunitmaster) *
                              vnqtunitmin;
        vnvalorultent_min  := (vnvalorultent_cx / vnqtunitmaster) *
                              vnqtunitmin;
        vncustorealliq_min      := (vncustorealliq_cx / vnqtunitmaster) *
                                   vnqtunitmin;
        vncustofinsemst_min     := (vncustofinsemst_cx / vnqtunitmaster) *
                                   vnqtunitmin;
        vnnewcustorealsemst_min := (vnvalorultent_cx / vnqtunitmaster) *
                                   vnqtunitmin;


        UPDATE pcest
           -- existia uma alteração da quantidade gerencial  + vnqt_resto, 0),
           SET dtultdesdobra = TRUNC(SYSDATE),
               custoultent   = vncustoultent_min,
               valorultent   = vnvalorultent_min,
               custoreal     = ((NVL(custoreal, 0) *
                               GREATEST(NVL(qtestger, 0), 0)) +
                               (vnnewcustoreal_min * vnqt_resto)) /
                               (GREATEST(GREATEST(NVL(qtestger, 0), 0) +
                                         vnqt_resto,
                                         0)),
               custofin      = ((NVL(custofin, 0) *
                               GREATEST(NVL(qtestger, 0), 0)) +
                               (vnnewcustofin_min * vnqt_resto)) /
                               (GREATEST(GREATEST(NVL(qtestger, 0), 0) +
                                         vnqt_resto,
                                         0)),
               custorep      = ((NVL(custorep, 0) *
                               GREATEST(NVL(qtestger, 0), 0)) +
                               (vnnewcustorep_min * vnqt_resto)) /
                               (GREATEST(GREATEST(NVL(qtestger, 0), 0) +
                                         vnqt_resto,
                                         0)),
               custocont     = ((NVL(custocont, 0) *
                               GREATEST(NVL(qtestger, 0), 0)) +
                               (vnnewcustocont_min * vnqt_resto)) /
                               (GREATEST(GREATEST(NVL(qtestger, 0), 0) +
                                         vnqt_resto,
                                         0)),
               custorealsemst = ((NVL(custorealsemst, 0) *
                                GREATEST(NVL(qtestger, 0), 0)) +
                                (vnnewcustorealsemst_min * vnqt_resto)) /
                                (GREATEST(GREATEST(NVL(qtestger, 0), 0) +
                                          vnqt_resto,
                                          0)),
               custorealliq   = ((NVL(custorealliq, 0) *
                                GREATEST(NVL(qtestger, 0), 0)) +
                                (vncustorealliq_min * vnqt_resto)) /
                                (GREATEST(GREATEST(NVL(qtestger, 0), 0) +
                                          vnqt_resto,
                                          0)),
               custofinsemst  = ((NVL(custofinsemst, 0) *
                                GREATEST(NVL(qtestger, 0), 0)) +
                                (vncustofinsemst_min * vnqt_resto)) /
                                (GREATEST(GREATEST(NVL(qtestger, 0), 0) +
                                          vnqt_resto,
                                          0))

         WHERE codprod = vncodprodunit
           AND codfilial = p_codfilial;

        IF vsControlaEstCont = 'S' THEN
          UPDATE pcest
             -- existia uma alteração da quantidade contábil + vnqt_resto, 0),
             SET custocont = ((NVL(custocont, 0) *
                             GREATEST(NVL(qtest, 0), 0)) +
                             (vnnewcustocont_min * vnqt_resto)) /
                             (GREATEST(GREATEST(NVL(qtest, 0), 0) +
                                       vnqt_resto,
                                       0))

           WHERE codprod = vncodprodunit
             AND codfilial = p_codfilial;
        END IF; -- IF vbControlaEstCont
      END IF;
    ELSE
      vbretorno  := FALSE;
      vsmensagem := 'NAO HA ESTOQUE DISPONIVEL DO PRODUTO EM CAIXA.';
      RAISE exc_dado_invalido;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      vbretorno := FALSE;

      IF vsmensagem IS NULL THEN
        vsmensagem := 'NAO HA ESTOQUE SUFICIENTE DO PRODUTO EM CAIXA. ERRO: ' ||
                      SQLCODE || '-' || SQLERRM;
      END IF;

      RAISE;
  END;

  -- Gerar movimentacao de saida e entrada dos diferentes produtos
  BEGIN
    -- Buscar custos atuais do produto em caixa
    SELECT NVL(pcest.custofin, 0),
           NVL(pcest.custoreal, 0),
           NVL(pcest.custorep, 0),
           NVL(pcest.custocont, 0),
           NVL(pcest.custoultent, 0),
           NVL(pcest.valorultent, 0),
           NVL(pcest.custorealsemst, 0)
      INTO vncustofin_cx,
           vncustoreal_cx,
           vncustorep_cx,
           vncustocont_cx,
           vncustoultent_cx,
           vnvalorultent_cx,
           vncustorealsemst_cx
      FROM pcest
     WHERE codprod = vncodprodmaster
       AND codfilial = p_codfilial;

    -- Gerar movimentacao de saida do estoque do produto em caixa
    INSERT INTO pcmov
      (dtmov, --1
       codprod, --2
       numnota, --3
       codoper, --4
       qt, --5
       qtcont, --6
       punit, --7
       punitcont, --8
       status, --9
       ptabela, --10
       codfilial, --11
       codcli, --12
       codplpag, --13
       codusur, --14
       custofin, --15
       custoreal, --16
       custocont, --17
       numcar, --18
       numped, --19
       st, --20
       numregiao, --21
       sittribut, --22
       numtransvenda, --23
       codepto, --24
       codsec, --25
       percicm, --26
       percdesc, --27
       codfornec, --28
       vlbaseipi, --29
       percipi, --30
       vlipi, --31
       codfiscal, --32
       codst, --33
       percom, --34
       codfilialnf, --35
       vldesccustocmv, --36
       baseicms, --37
       baseicst, --38
       custorep, --39
       codcertific, --40
       numseq, --41
       numidf, --42
       vldescsuframa, --43
       vldescicmisencao, --44
       perpis, --45
       custofinant, --46
       custorealant, --47
       custoultentant, --48
       percvenda, -- 49
       NUMLOTE -- 50
			 ,DESCRICAO1 --51 --> VAI GRAVAR A QTD ORIGINAL SOLICITADA PARA RASTREAMENTO FUTURO.
      ,CODFUNCLANC, --52
      custorealsemst, --53
      custorealsemstant --54 --52
       )
    VALUES
      (TRUNC(SYSDATE), --1
       vncodprodmaster, --2
       0, --3
       'SP', --4
       vnqt_caixas, --5
       DECODE(vsControlaEstCont, 'S', vnqt_caixas, 0), --6
       0, --7
       0, --8
       DECODE(vsControlaEstCont, 'S', 'AB', 'B'), --9
       0, --10
       p_codfilial, --11
       0, --12
       0, --13
       0, --14
       vncustofin_cx, --15
       vncustoreal_cx, --16
       DECODE(vsControlaEstCont, 'S', vncustocont_cx, 0), --17
       0, --18
       0, --19
       0, --20
       0, --21
       0, --22
       vnnumtransvenda, --23
       vncodepto_cx, --24
       vncodsec_cx, --25
       0, --26
       0, --27
       vncodfornec_cx, --28
       0, --29
       0, --30
       0, --31
       0, --32
       0, --33
       0, --34
       p_codfilial, --35
       0, --36
       0, --37
       0, --38
       vncustorep_cx, --39
       0, --40
       0, --41
       0, --42
       0, --43
       0, --44
       0, --45
       vncustofinant_cx, --46
       vncustorealant_cx, --47
       vncustoultentant_cx, -- 48
       DECODE(vsControlaEstCont, 'S', 100, NULL), -- 49
       VNNUMLOTE -- 50
			 ,'Cod.Prod:'||p_codprod||' Qtd.Solicitada:'||p_qtsolicitada
       ,p_codfunc, --52
      vncustorealsemst_cx, --53
      vncustorealsemstant_cx --54
       );

    --HIS.04273.2015
    GRAVAR_PCPAIFILHO('SP'
                     ,vncodprodmaster
                     ,vnnumtransent
                     ,vnnumtransvenda
                     ,p_numped,
                     vnqt_caixas);


    --Buscar custos atuais do produto em unidade
    SELECT NVL(pcest.custofin, 0),
           NVL(pcest.custoreal, 0),
           NVL(pcest.custorep, 0),
           NVL(pcest.custocont, 0),
           NVL(pcest.custoultent, 0),
           NVL(pcest.valorultent, 0),
           NVL(pcest.custorealsemst, 0)
      INTO vncustofin_un,
           vncustoreal_un,
           vncustorep_un,
           vncustocont_un,
           vncustoultent_un,
           vnvalorultent_un,
           vncustorealsemst_un
      FROM pcest
     WHERE codprod = p_codprod
       AND codfilial = p_codfilial;

    -- Gerar movimentacao de entrada do estoque do produto em unidade
    INSERT INTO pcmov
      (dtmov, --1
       codprod, --2
       numnota, --3
       codoper, --4
       qt, --5
       qtcont, --6
       punit, --7
       punitcont, --8
       status, --9
       ptabela, --10
       codfilial, --11
       codcli, --12
       codplpag, --13
       codusur, --14
       custofin, --15
       custoreal, --16
       custocont, --17
       numcar, --18
       numped, --19
       st, --20
       numregiao, --21
       sittribut, --22
       numtransvenda, --23
       codepto, --24
       codsec, --25
       percicm, --26
       percdesc, --27
       codfornec, --28
       vlbaseipi, --29
       percipi, --30
       vlipi, --31
       codfiscal, --32
       codst, --33
       percom, --34
       codfilialnf, --35
       vldesccustocmv, --36
       baseicms, --37
       baseicst, --38
       custorep, --39
       codcertific, --40
       numseq, --41
       numidf, --42
       vldescsuframa, --43
       vldescicmisencao, --44
       perpis, --45
       custofinant, --46
       custorealant, --47
       custoultentant, --48
       percvenda, -- 49
       NUMLOTE, -- 50
       numtransent --51  --Tarefa: 178471
			 ,DESCRICAO1 --52 --> VAI GRAVAR A QTD ORIGINAL SOLICITADA PARA RASTREAMENTO FUTURO.
      ,CODFUNCLANC --53
      , CUSTOULTENT, --54
      custorealsemst, --55
      custorealsemstant --56
       )
    VALUES
      (TRUNC(SYSDATE), --1
       p_codprod, --2
       0, --3
       'EP', --4
       vnqt_unidades, --5
       DECODE(vsControlaEstCont, 'S', vnqt_unidades, 0), --6
       0, --7
       0, --8
       DECODE(vsControlaEstCont, 'S', 'AB', 'B'), --9
       0, --10
       p_codfilial, --11
       0, --12
       0, --13
       0, --14
       vncustofin_un, --15
       vncustoreal_un, --16
       DECODE(vsControlaEstCont, 'S', vncustocont_un, 0), --17
       0, --18
       0, --19
       0, --20
       0, --21
       0, --22
       vnnumtransvenda, --23
       vncodepto_un, --24
       vncodsec_un, --25
       0, --26
       0, --27
       vncodfornec_un, --28
       0, --29
       0, --30
       0, --31
       0, --32
       0, --33
       0, --34
       p_codfilial, --35
       0, --36
       0, --37
       0, --38
       vncustorep_un, --39
       0, --40
       0, --41
       0, --42
       0, --43
       0, --44
       0, --45
       vncustofinant_un, --46
       vncustorealant_un, --47
       vncustoultentant_un, --48
       DECODE(vsControlaEstCont, 'S', 100, NULL), -- 49
       VNNUMLOTE, -- 50
       vnnumtransent --51 --Tarefa: 178471
			 ,'Cod.Prod:'||p_codprod||' Qtd.Solicitada:'||p_qtsolicitada
      ,p_codfunc --53
      , vncustoultentant_un, --54
      vncustorealsemst_un, --55
      vncustorealsemstant_un --56
       );

    --HIS.04273.2015
    GRAVAR_PCPAIFILHO('EP'
                     ,p_codprod
                     ,vnnumtransent
                     ,vnnumtransvenda
                     ,p_numped
                     ,vnqt_unidades);

    vnReturn := PKG_ESTOQUE.VENDAS_SAIDA_PROD(vnnumtransvenda, vncodprodmaster, 'N',vsmensagem);
    vnReturn := PKG_ESTOQUE.VENDAS_ENTRADA_PROD(vnnumtransent, p_codprod, 'N', 'N', vsmensagem);

    IF vnqt_resto > 0 THEN

      --Tarefa: 178471
      -- Gerar numeracao de transacao
      BEGIN

        BEGIN
          v_Count := 0;

          WHILE (v_Count <= 50) and (nvl(vnnumtransent,0) = 0) LOOP
            v_Count := v_Count + 1;

            vnnumtransent := FERRAMENTAS.F_PROX_NUMTRANSENT; -- 1169.118737.2015

            if vnnumtransent <> 0 then
              exit;
            end if;

            if (vnnumtransent = 0) and (v_Count >= 10) then
              raise erro_numtransent;
            end if;

          END LOOP;
        END;

      EXCEPTION
        WHEN erro_numtransent THEN
          vbretorno  := FALSE;
          vsmensagem := 'NAO FOI POSSIVEL GERAR NUMERO DE TRANSACAO(Numtransent). ERRO: Rotina retornou Numtransent = 0(Bloco Resto). ';
          --1169.073630.2015 Comentado o ROLLBACK abaixo pois estava commitando metade da transação na 336 dando problemas sérios de estoque - Marcos Garcia
          --ROLLBACK;
          RAISE;

        WHEN OTHERS THEN
          vbretorno  := FALSE;
          vsmensagem := 'NAO FOI POSSIVEL GERAR NUMERO DE TRANSACAO. ERRO: ' ||
                        SQLCODE || '-' || SQLERRM;
          --1169.073630.2015 Comentado o ROLLBACK abaixo pois estava commitando metade da transação na 336 dando problemas sérios de estoque - Marcos Garcia
          --ROLLBACK;
          RAISE;
      END;
      --Fim Tarefa: 178471

      --Buscar custos atuais do produto em unidade
      SELECT NVL(pcest.custofin, 0),
             NVL(pcest.custoreal, 0),
             NVL(pcest.custorep, 0),
             NVL(pcest.custocont, 0),
             NVL(pcest.custoultent, 0),
             NVL(pcest.valorultent, 0),
             NVL(pcest.custorealsemst, 0)
        INTO vncustofin_min,
             vncustoreal_min,
             vncustorep_min,
             vncustocont_min,
             vncustoultent_min,
             vnvalorultent_min,
             vncustorealsemst_min
        FROM pcest
       WHERE codprod = vncodprodunit
         AND codfilial = p_codfilial;

      -- Gerar movimentacao de entrada do estoque do produto em unidade
      INSERT INTO pcmov
        (dtmov, --1
         codprod, --2
         numnota, --3
         codoper, --4
         qt, --5
         qtcont, --6
         punit, --7
         punitcont, --8
         status, --9
         ptabela, --10
         codfilial, --11
         codcli, --12
         codplpag, --13
         codusur, --14
         custofin, --15
         custoreal, --16
         custocont, --17
         numcar, --18
         numped, --19
         st, --20
         numregiao, --21
         sittribut, --22
         numtransvenda, --23
         codepto, --24
         codsec, --25
         percicm, --26
         percdesc, --27
         codfornec, --28
         vlbaseipi, --29
         percipi, --30
         vlipi, --31
         codfiscal, --32
         codst, --33
         percom, --34
         codfilialnf, --35
         vldesccustocmv, --36
         baseicms, --37
         baseicst, --38
         custorep, --39
         codcertific, --40
         numseq, --41
         numidf, --42
         vldescsuframa, --43
         vldescicmisencao, --44
         perpis, --45
         custofinant, --46
         custorealant, --47
         custoultentant, --48
         percvenda, -- 49
         numlote, -- 50
         numtransent --51  --Tarefa: 178471
			   ,DESCRICAO1 --52 --> VAI GRAVAR A QTD ORIGINAL SOLICITADA PARA RASTREAMENTO FUTURO.
        ,CODFUNCLANC, --53
        custorealsemst, --54
        custorealsemstant --55
         )
      VALUES
        (TRUNC(SYSDATE), --1
         vncodprodunit, --2
         0, --3
         'EP', --4
         vnqt_resto, --5
         DECODE(vsControlaEstCont, 'S', vnqt_resto, 0), --6
         0, --7
         0, --8
         DECODE(vsControlaEstCont, 'S', 'AB', 'B'), --9
         0, --10
         p_codfilial, --11
         0, --12
         0, --13
         0, --14
         vncustofin_min, --15
         vncustoreal_min, --16
         DECODE(vsControlaEstCont, 'S', vncustocont_min, 0), --17
         0, --18
         0, --19
         0, --20
         0, --21
         0, --22
         vnnumtransvenda, --23
         vncodepto_min, --24
         vncodsec_min, --25
         0, --26
         0, --27
         vncodfornec_min, --28
         0, --29
         0, --30
         0, --31
         0, --32
         0, --33
         0, --34
         p_codfilial, --35
         0, --36
         0, --37
         0, --38
         vncustorep_min, --39
         0, --40
         0, --41
         0, --42
         0, --43
         0, --44
         0, --45
         vncustofinant_min, --46
         vncustorealant_min, --47
         vncustoultentant_min, --48
         DECODE(vsControlaEstCont, 'S', 100, NULL), -- 49
         vnnumlote, -- 50
         vnnumtransent --51  --Tarefa: 178471
			   ,'Cod.Prod:'||p_codprod||' Qtd.Solicitada:'||p_qtsolicitada
        ,p_codfunc, --53
        vncustorealsemst_min, --54
        vncustorealsemstant_min --55
         );

      --HIS.04273.2015
      GRAVAR_PCPAIFILHO('EP'
                       ,p_codprod
                       ,vnnumtransent
                       ,vnnumtransvenda
                       ,p_numped
                       ,vnqt_resto);

      vnReturn := PKG_ESTOQUE.VENDAS_ENTRADA_PROD(vnnumtransent, p_codprod, 'N', 'N', vsmensagem);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      vbretorno  := FALSE;
      vsmensagem := 'ERRO AO GERAR MOVIMENTACAO ENTRE PRODUTOS. ERRO: ' ||
                    SQLCODE || '-' || SQLERRM;
      RAISE;
  END;
  --1169.073630.2015 Comentado o commit abaixo pois estava commitando metade da transação na 336 dando problemas sérios de estoque - Marcos Garcia
  --COMMIT;
  p_mensagem := 'CONVERSAO REALIZADA COM SUCESSO!!!';
EXCEPTION
  when exc_lote_filho then
     --1169.073630.2015 Comentado o ROLLBACK abaixo pois estava commitando metade da transação na 336 dando problemas sérios de estoque - Marcos Garcia
    --rollback;
    p_mensagem := VSMENSAGEM;
  WHEN exc_dado_invalido THEN
    --ROLLBACK;
    p_mensagem := vsmensagem;
  WHEN OTHERS THEN
    --ROLLBACK;
    p_mensagem := vsmensagem;
END PRC_CONVERSAO_ESTOQUE_PACOTE; -- Procedure
/
