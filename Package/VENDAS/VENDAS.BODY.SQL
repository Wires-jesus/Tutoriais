CREATE OR REPLACE PACKAGE BODY VENDAS IS
  -- HISTÓRICO DE MODIFICAÇÕES
  -- Nome               Data      Comentários
  -- --------------   ----------  ------------------------------------------
  -- LUCIANO LIMA     24/09/2013  CRIAÇÃO DA PKG
  -- Rafael Braga     14/03/2014  Comentando recurso da função ESTOQUE_CB para obrigar o uso do parâmetro de código do produto e filial, melhorando a performance.
  -- --------------   ----------  ------------------------------------------

  PROCEDURE prc_desdobrar_ped_tv8(pnumped_tv7 IN NUMBER,
                                  pncodfunc   IN NUMBER,
                                  pmsg        OUT VARCHAR2)
  /******************************************************************************************
     ->Nome da PROCEDURE : PRC_DESDOBRAR_PED_TV8
     ->Objetivo          : Gerar novos pedidos TV8 para venda Assistida
     ->Versao            : Pacote

     -------------------------------- Historico ------------------------------------------------------------------
     Data          Responsavel  Tarefa      Comentarios
     ------------  ------------ ----------  -----------------------------------------------------------------------------
     16/07/2008    Diego\Pablo  63254       Criação do procedimento, conforme projeto de venda assistida 1.4
     05/09/2008    Pablo        68602       Alteração para passar a gravar PCPEDC.NumPedOrigem para o novo Pedido TV8
                                            gerado.
     22/09/2008    Pablo        69450       Alteração para gravar o Pedido de VEnda TV8 como Montado, caso no mesmo só exista
                                            Itens com REtira Posterior
     23/09/2008    Pablo                    Correção da solicitação anterior.
     06/10/2008    Pablo        70245       Alteração para retirar os itens PCPEDI.TipoEntrega = 'RI', conforme última alteração
                                            do Projeto Venda Assistida.
     21/10/2008    Pablo        71340       Alteração para gerar os novos Pedido TV8 'EN' e 'RP' para a nova filial
                                            conforme PCPEDI.CODFILIALRETIRA
     29/10/2008    Rogério      71340       Ajustar processo de geração de Pedido TV8 por Filial Retira e Tipo Entrega
     01/11/2008    Rogério      71340       Ajustar processo de geração de Pedido TV8 por Filial Retira e Tipo Entrega
     03/11/2008    Rogério      71340       Deletar cabeçalho de Pedido quando tds os itens forem Tipo Entrega "RI"
     05/11/2008    Andrea                   Alteracao para gravar coddistrib = null quando o tipo entregar for EN
    ******************************************************************************************/
   IS
    vicontador                 NUMBER;
    vicontador_tv7             NUMBER;
    vnproxnumped               pcusuari.proxnumped%TYPE;
    vncodusur                  pcpedc.codusur%TYPE;
    vnnumped_tv8               pcpedc.numped%TYPE;
    vnnumcar                   pcpedc.numcar%TYPE;
    vsorigemped                pcpedc.origemped%TYPE;
    vsposicao                  pcpedc.posicao%TYPE;
    vscodfilial                pcpedc.codfilial%TYPE;
    vsutilizavendaporembalagem pcfilial.utilizavendaporembalagem%TYPE;
    vnpercvenda                pcpedc.percvenda%TYPE;
    vnvltotal                  pcpedc.vltotal%TYPE;
    vnnumitens                 pcpedc.numitens%TYPE;
    vntotpeso                  pcpedc.totpeso%TYPE;
    vntotvolume                pcpedc.totvolume%TYPE;
    vicontadorpcpedi           NUMBER;
    vicontador_en              NUMBER;
    vicontador_rp              NUMBER;
    vicountped                 NUMBER;
    vicountped_gerado          NUMBER;
  BEGIN
    vicontador        := 0;
    vicountped        := 0;
    vicountped_gerado := 0;
    vicontador_tv7    := 0;

    SELECT numped, codfilial
      INTO vnnumped_tv8, vscodfilial
      FROM pcpedc
     WHERE pcpedc.numpedentfut = pnumped_tv7
       AND ROWNUM = 1;

    -- Tarefa 70245
    -- Retirando os itens 'Retira Imediata do Pedido TV7
    BEGIN
      SELECT COUNT(*)
        INTO vicontador
        FROM pcpedi
       WHERE numped = pnumped_tv7
         AND tipoentrega = 'RI';

      IF vicontador > 0 THEN
        INSERT INTO pccortevendaassistida
          (pccortevendaassistida.numped,
           pccortevendaassistida.codprod,
           pccortevendaassistida.numseq,
           pccortevendaassistida.qt,
           pccortevendaassistida.DATA,
           pccortevendaassistida.codfunc,
           pccortevendaassistida.pvenda,
           pccortevendaassistida.dtpedido,
           pccortevendaassistida.codfilial,
           pccortevendaassistida.codcli,
           pccortevendaassistida.codusur)
          (SELECT pcpedi.numped,
                  pcpedi.codprod,
                  pcpedi.numseq,
                  pcpedi.qt,
                  TRUNC(SYSDATE),
                  pncodfunc,
                  pcpedi.pvenda,
                  pcpedi.DATA,
                  vscodfilial,
                  pcpedi.codcli,
                  pcpedi.codusur
             FROM pcpedi
            WHERE pcpedi.numped = pnumped_tv7
              AND pcpedi.tipoentrega = 'RI');

        DELETE FROM pcpedi
         WHERE pcpedi.numped = pnumped_tv7
           AND pcpedi.tipoentrega = 'RI';

        -- Totalizando Pedido TV7
        SELECT SUM((NVL(pcpedi.qt, 0) + NVL(pcpedi.qtfalta, 0)) *
                   NVL(pcpedi.pvenda, 0)) vltotal,
               COUNT(*) numitens,
               SUM(NVL(pcpedi.qt, 0) * pcprodut.pesobruto ) totpeso,
               SUM(NVL(pcpedi.qt, 0) * pcprodut.volume ) totvolum
          INTO vnvltotal, vnnumitens, vntotpeso, vntotvolume
          FROM pcpedi, pcpedc, pcprodut
         WHERE pcpedi.codprod = pcprodut.codprod
           AND pcpedi.numped = pcpedc.numped
           AND pcpedc.numped = pnumped_tv7;

        UPDATE pcpedc
           SET vltotal     = vnvltotal,
               vlatend     = 0,
               totpeso     = vntotpeso,
               totvolume   = vntotvolume,
               numitens    = vnnumitens,
               vltabela    = 0,
               vlcustoreal = 0,
               vlcustocont = 0,
               vlcustorep  = 0,
               vlcustofin  = 0
         WHERE numped = pnumped_tv7;

        DELETE FROM pcpedi
         WHERE pcpedi.numped = vnnumped_tv8
           AND pcpedi.tipoentrega = 'RI';

        -- Totalizando Pedido TV7
        SELECT SUM((NVL(pcpedi.qt, 0) + NVL(pcpedi.qtfalta, 0)) *
                   NVL(pcpedi.pvenda, 0)) vltotal,
               COUNT(*) numitens,
               SUM(NVL(pcpedi.qt, 0) * pcprodut.pesobruto ) totpeso,
               SUM(NVL(pcpedi.qt, 0) * pcprodut.volume ) totvolum
          INTO vnvltotal, vnnumitens, vntotpeso, vntotvolume
          FROM pcpedi, pcpedc, pcprodut
         WHERE pcpedi.codprod = pcprodut.codprod
           AND pcpedi.numped = pcpedc.numped
           AND pcpedc.numped = vnnumped_tv8;

        UPDATE pcpedc
           SET vltotal     = vnvltotal,
               vlatend     = 0,
               totpeso     = vntotpeso,
               totvolume   = vntotvolume,
               numitens    = vnnumitens,
               vltabela    = 0,
               vlcustoreal = 0,
               vlcustocont = 0,
               vlcustorep  = 0,
               vlcustofin  = 0
         WHERE numped = vnnumped_tv8;

        --Deletar cabeçalho qdo não tiver mais itens no Pedido
        SELECT COUNT(*)
          INTO vicontador_tv7
          FROM pcpedi
         WHERE numped = pnumped_tv7;

        IF vicontador_tv7 = 0 THEN
          DELETE FROM pcpedc WHERE pcpedc.numped = pnumped_tv7;

          pmsg := 'N_PEDTV7';
        END IF;
      END IF; -- IF VICONTADOR > 0
    EXCEPTION
      WHEN OTHERS THEN
        pmsg := SQLCODE || ' - ' || SQLERRM ||
                ' -2- Erro ao gerar pedido tipo 8. '|| ' - '|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
        RAISE;
    END;

    -- Fim Tarefa 70245
    SELECT NVL(pcfilial.utilizavendaporembalagem,
               (SELECT NVL(pcconsum.utilizavendaporembalagem, 'N')
                  FROM pcconsum
                 WHERE ROWNUM = 1))
      INTO vsutilizavendaporembalagem
      FROM pcfilial
     WHERE codigo = vscodfilial;

    SELECT SUM(COUNT(*))
      INTO vicountped
      FROM pcpedi, pcpedc
     WHERE pcpedi.numped = pcpedc.numped
       AND pcpedc.numped = vnnumped_tv8
     GROUP BY NVL(pcpedi.codfilialretira, pcpedc.codfilial),
              pcpedi.tipoentrega;

    vicountped := vicountped - 1;

    IF vicountped >= 1 THEN
      FOR registros IN (SELECT NVL(pcpedi.codfilialretira, pcpedc.codfilial) codfilialretira,
                               pcpedi.tipoentrega
                          FROM pcpedi, pcpedc
                         WHERE pcpedi.numped = pcpedc.numped
                           AND pcpedc.numped = vnnumped_tv8
                         GROUP BY NVL(pcpedi.codfilialretira,
                                      pcpedc.codfilial),
                                  pcpedi.tipoentrega) LOOP
        vnnumcar := 0;

        IF vicontador > 0 THEN
          IF registros.tipoentrega = 'EN' THEN
            vsposicao   := 'L';
            vsorigemped := 'T';
            vnpercvenda := 100;

            SELECT COUNT(*)
              INTO vicontadorpcpedi
              FROM pcpedi
             WHERE numped = vnnumped_tv8
               AND tipoentrega = 'EN';

            --AND NVL(CODFILIALRETIRA, VSCODFILIAL) <> VSCODFILIAL;
            IF vicontadorpcpedi > 0 THEN
              FOR registros_en IN (SELECT NVL(pcpedi.codfilialretira,
                                              pcpedc.codfilial) codfilialretira,
                                          pcpedi.tipoentrega
                                     FROM pcpedi, pcpedc
                                    WHERE pcpedi.numped = pcpedc.numped
                                      AND pcpedc.numped = vnnumped_tv8
                                      AND NVL(pcpedi.tipoentrega, '  ') = 'EN'
                                   --AND NVL(PCPEDI.CODFILIALRETIRA, VSCODFILIAL) <> VSCODFILIAL
                                    GROUP BY NVL(pcpedi.codfilialretira,
                                                 pcpedc.codfilial),
                                             pcpedi.tipoentrega) LOOP
                IF vicountped > vicountped_gerado THEN
                  BEGIN
                    SELECT pcpedc.codusur
                      INTO vncodusur
                      FROM pcpedc
                     WHERE pcpedc.numped = vnnumped_tv8;

                    --Gerando número para o próximo pedido TV8
                    vnproxnumped := ferramentas.F_PROX_NUMPED(vncodusur);

                    vicountped_gerado := vicountped_gerado + 1;
                  EXCEPTION
                    WHEN OTHERS THEN
                      pmsg := SQLCODE || ' - ' || SQLERRM ||
                              ' -1- Erro ao buscar o próximo número de pedido. '|| ' - '|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                      RAISE;
                  END;

                  BEGIN
                    INSERT INTO pcpedc
                      (numped,
                       DATA,
                       codusur,
                       codcli,
                       numitens,
                       vlatend,
                       codpraca,
                       posicao,
                       numcar,
                       codsupervisor,
                       codfilial,
                       vltotal,
                       vltabela,
                       vlcustoreal,
                       vlcustofin,
                       totpeso,
                       totvolume,
                       codemitente,
                       operacao,
                       tipovenda,
                       obs,
                       codcob,
                       hora,
                       minuto,
                       codplpag,
                       numpedcli,
                       percvenda,
                       perdesc,
                       vldesconto,
                       vlfrete,
                       vloutrasdesp,
                       obs1,
                       obs2,
                       condvenda,
                       dtentrega,
                       numpedrca,
                       fretedespacho,
                       freteredespacho,
                       codfornecfrete,
                       codfornecredespacho,
                       tipocarga,
                       prazo1,
                       prazo2,
                       prazo3,
                       prazo4,
                       prazo5,
                       prazo6,
                       prazo7,
                       prazo8,
                       prazo9,
                       prazo10,
                       prazo11,
                       prazo12,
                       prazomedio,
                       obsentrega1,
                       obsentrega2,
                       obsentrega3,
                       tipoembalagem,
                       codepto,
                       campanha,
                       coddistrib,
                       vlcustocont,
                       vlcustorep,
                       numnotamanif,
                       seriemanif,
                       origemped,
                       especiemanif,
                       numpedentfut,
                       codfilialnf, --69
                       numcarmanif,
                       numorca,
                       codcontrato,
                       datapedcli,
                       numpedbnf,
                       broker,
                       codestabelecimento,
                       numtabela,
                       motivoposicao,
                       dtagendaentrega,
                       tipooper,
                       codmotbloqueio,
                       serieecf,
                       numcupom,
                       codclirecebedor,
                       conciliaimportacao,
                       numregiao,
                       numnota,
                       perdescfin,
                       restricaotransp,
                       geracp,
                       usaintegracaowms,
                       vendaassistida,
                       codgerente,
                       tipocontacorrente)
                      (SELECT vnproxnumped, --NUM DO PEDIDO
                              DATA,
                              codusur,
                              codcli,
                              numitens,
                              0, -- VLATEND
                              codpraca,
                              vsposicao,
                              --POSIÇÃO
                              0,
                              codsupervisor,
                              registros_en.codfilialretira,
                              vltotal,
                              0, -- VLTABELA
                              0, -- VLCUSTOREAL
                              0, -- VLCUSTOFIN
                              totpeso,
                              totvolume,
                              codemitente,
                              operacao,
                              tipovenda,
                              obs,
                              codcob,
                              hora,
                              minuto,
                              codplpag,
                              numpedcli,
                              vnpercvenda, --PERCVENDA
                              perdesc,
                              vldesconto,
                              vlfrete,
                              vloutrasdesp,
                              obs1,
                              obs2,
                              8, --TIPO DE VENDA
                              dtentrega,
                              numpedrca,
                              fretedespacho,
                              freteredespacho,
                              codfornecfrete,
                              codfornecredespacho,
                              tipocarga,
                              prazo1,
                              prazo2,
                              prazo3,
                              prazo4,
                              prazo5,
                              prazo6,
                              prazo7,
                              prazo8,
                              prazo9,
                              prazo10,
                              prazo11,
                              prazo12,
                              prazomedio,
                              obsentrega1,
                              obsentrega2,
                              obsentrega3,
                              tipoembalagem,
                              codepto,
                              campanha,
                              NULL, --CODDISTRIB,
                              0, -- VLCUSTOCONT
                              0, -- VLCUSTOREP
                              numnotamanif,
                              seriemanif,
                              vsorigemped, --ORIGEMPED
                              especiemanif,
                              pnumped_tv7, --NUM DO PEDIDO TIPO 7
                              registros_en.codfilialretira,

                              --Tarefa 72313
                              numcarmanif,
                              numorca,
                              codcontrato,
                              datapedcli,
                              numpedbnf,
                              broker,
                              codestabelecimento,
                              numtabela,
                              motivoposicao,
                              dtagendaentrega,
                              tipooper,
                              codmotbloqueio,
                              serieecf,
                              numcupom,
                              codclirecebedor,
                              conciliaimportacao,
                              numregiao,
                              numnota,
                              perdescfin,
                              restricaotransp,
                              geracp,
                              usaintegracaowms,
                              vendaassistida,
                              codgerente,
                              nvl(tipocontacorrente,'R')
                         FROM pcpedc
                        WHERE numped = vnnumped_tv8);
                  EXCEPTION
                    WHEN OTHERS THEN
                      pmsg := SQLCODE || ' - ' || SQLERRM ||
                              ' -2- Erro ao gerar pedido tipo 8. '|| ' - '|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                      RAISE;
                  END;

                  BEGIN
                    INSERT INTO pcpedi
                      (codprod,
                       qt,
                       pvenda,
                       numped,
                       DATA,
                       codcli,
                       codusur,
                       numcar,
                       posicao,
                       st,
                       vlcustoreal,
                       vlcustofin,
                       ptabela,
                       percom,
                       perdesc,
                       qtfalta,
                       numseq,
                       vldesccustocmv,
                       vlcustocont,
                       vlcustorep,
                       vldescsuframa,
                       codst,
                       vldescfin,
                       pvendabase,
                       vlipi,
                       percipi,
                       poriginal,
                       iva,
                       pauta,
                       aliqicms1,
                       aliqicms2,
                       stclientegnre,
                       percbasered,
                       percbaseredst,
                       percbaseredstfonte,
                       perfretecmv,
                       custofinest,
                       perciss,
                       vliss,
                       complemento,
                       pbaserca,
                       vlverbacmv,
                       numverbarebcmv,
                       brinde,
                       baseicst,
                       qtcx,
                       qtpecas,
                       letracomiss,
                       codauxiliar,
                       txvenda,
                       codicmtab,
                       perdesccusto,
                       codfilialretira,
                       eancodprod,
                       vldescicmisencao,
                       perdescisentoicms,
                       vlverbacmvcli,
                       pvenda1,
                       tipoentrega)
                      (SELECT codprod,
                              qt,
                              pvenda,
                              vnproxnumped,

                              --NUM DO PEDIDO
                              DATA,
                              codcli,
                              codusur,
                              0, --NUMCAR
                              vsposicao,

                              --POSICAO
                              st,
                              vlcustoreal,
                              vlcustofin,
                              ptabela,
                              percom,
                              perdesc,
                              qtfalta,
                              numseq,
                              vldesccustocmv,
                              vlcustocont,
                              vlcustorep,
                              vldescsuframa,
                              codst,
                              vldescfin,
                              pvendabase,
                              vlipi,
                              percipi,
                              poriginal,
                              iva,
                              pauta,
                              aliqicms1,
                              aliqicms2,
                              stclientegnre,
                              percbasered,
                              percbaseredst,
                              percbaseredstfonte,
                              perfretecmv,
                              custofinest,
                              perciss,
                              vliss,
                              complemento,
                              pbaserca,
                              vlverbacmv,
                              numverbarebcmv,
                              brinde,
                              baseicst,
                              qtcx,
                              qtpecas,
                              letracomiss,
                              codauxiliar,
                              txvenda,
                              codicmtab,
                              perdesccusto,
                              codfilialretira,
                              eancodprod,
                              vldescicmisencao,
                              perdescisentoicms,
                              vlverbacmvcli,
                              pvenda1,
                              tipoentrega
                         FROM pcpedi
                        WHERE pcpedi.numped = vnnumped_tv8
                          AND NVL(pcpedi.codfilialretira, vscodfilial) =
                              registros_en.codfilialretira
                          AND pcpedi.tipoentrega = registros_en.tipoentrega);
                  EXCEPTION
                    WHEN OTHERS THEN
                      pmsg := SQLCODE || ' - ' || SQLERRM ||
                              ' -3- Erro ao gerar os itens do pedido tipo 8. '|| ' - '|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                      RAISE;
                  END;

                  --Excluindo itens do pedido TV8 original que foram lançando no novo pedido TV8
                  DELETE FROM pcpedi
                   WHERE numped = vnnumped_tv8
                     AND codfilialretira = registros_en.codfilialretira
                     AND tipoentrega = registros_en.tipoentrega;

                  -- Totalizando Pedido TV8 EN gerado
                  SELECT SUM((NVL(pcpedi.qt, 0) + NVL(pcpedi.qtfalta, 0)) *
                             NVL(pcpedi.pvenda, 0)) vltotal,
                         COUNT(*) numitens,
                         SUM(NVL(pcpedi.qt, 0) * pcprodut.pesobruto ) totpeso,
                         SUM(NVL(pcpedi.qt, 0) * pcprodut.volume ) totvolum
                    INTO vnvltotal, vnnumitens, vntotpeso, vntotvolume
                    FROM pcpedi, pcpedc, pcprodut
                   WHERE pcpedi.codprod = pcprodut.codprod
                     AND pcpedi.numped = pcpedc.numped
                     AND pcpedc.numped = vnproxnumped;

                  UPDATE pcpedc
                     SET vltotal     = vnvltotal,
                         vlatend     = 0,
                         totpeso     = vntotpeso,
                         totvolume   = vntotvolume,
                         numitens    = vnnumitens,
                         vltabela    = 0,
                         vlcustoreal = 0,
                         vlcustocont = 0,
                         vlcustorep  = 0,
                         vlcustofin  = 0
                   WHERE numped = vnproxnumped;
                END IF;
              END LOOP; -- REGISTROS_EN

              -- Totalizando Pedido TV8 Original
              SELECT SUM((NVL(pcpedi.qt, 0) + NVL(pcpedi.qtfalta, 0)) *
                         NVL(pcpedi.pvenda, 0)) vltotal,
                     COUNT(*) numitens,
                     SUM(NVL(pcpedi.qt, 0) * pcprodut.pesobruto ) totpeso,
                     SUM(NVL(pcpedi.qt, 0) * pcprodut.volume ) totvolum
                INTO vnvltotal, vnnumitens, vntotpeso, vntotvolume
                FROM pcpedi, pcpedc, pcprodut
               WHERE pcpedi.codprod = pcprodut.codprod
                 AND pcpedi.numped = pcpedc.numped
                 AND pcpedc.numped = vnnumped_tv8;

              UPDATE pcpedc
                 SET vltotal     = vnvltotal,
                     vlatend     = 0,
                     totpeso     = vntotpeso,
                     totvolume   = vntotvolume,
                     numitens    = vnnumitens,
                     vltabela    = 0,
                     vlcustoreal = 0,
                     vlcustocont = 0,
                     vlcustorep  = 0,
                     vlcustofin  = 0
               WHERE numped = vnnumped_tv8;
            END IF; -- IF VICONTADORPCPEDI > 0
          ELSE
            --SE REGISTROS.TIPOENTREGA <> 'EN' ENTÃO VAI SER RP
            BEGIN
              vsposicao   := 'M';
              vsorigemped := 'R';
              vnpercvenda := 100;

              /*SELECT NVL(pcconsum.proxnumcar, 1)
                INTO vnnumcar
                FROM pcconsum
                 FOR UPDATE;

              UPDATE pcconsum SET proxnumcar = NVL(proxnumcar, 1) + 1;

              COMMIT;*/

              vnnumcar := FERRAMENTAS.F_PROX_NUMCAR;

            EXCEPTION
              WHEN OTHERS THEN
                pmsg := SQLCODE || ' - ' || SQLERRM ||
                        ' -1- Erro ao buscar o próximo número do carregamento. '|| ' - '|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                RAISE;
            END;

            FOR registros_rp IN (SELECT NVL(pcpedi.codfilialretira,
                                            pcpedc.codfilial) codfilialretira,
                                        pcpedi.tipoentrega
                                   FROM pcpedi, pcpedc
                                  WHERE pcpedi.numped = pcpedc.numped
                                    AND pcpedc.numped = vnnumped_tv8
                                    AND NVL(pcpedi.tipoentrega, '  ') = 'RP'
                                 --AND NVL(PCPEDI.CODFILIALRETIRA, VSCODFILIAL) <> VSCODFILIAL
                                  GROUP BY NVL(pcpedi.codfilialretira,
                                               pcpedc.codfilial),
                                           pcpedi.tipoentrega) LOOP
              IF vicountped > vicountped_gerado THEN
                BEGIN
                  SELECT pcpedc.codusur
                    INTO vncodusur
                    FROM pcpedc
                   WHERE pcpedc.numped = vnnumped_tv8;

                  --Gerando número para o próximo pedido TV8

                  vnproxnumped := ferramentas.F_PROX_NUMPED(vncodusur);

                  vicountped_gerado := vicountped_gerado + 1;
                EXCEPTION
                  WHEN OTHERS THEN
                    pmsg := SQLCODE || ' - ' || SQLERRM ||
                            ' -1- Erro ao buscar o próximo número de pedido. '|| ' - '|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                    RAISE;
                END;

                BEGIN
                  INSERT INTO pcpedc
                    (numped,
                     DATA,
                     codusur,
                     codcli,
                     numitens,
                     vlatend,
                     codpraca,
                     posicao,
                     numcar,
                     codsupervisor,
                     codfilial,
                     vltotal,
                     vltabela,
                     vlcustoreal,
                     vlcustofin,
                     totpeso,
                     totvolume,
                     codemitente,
                     operacao,
                     tipovenda,
                     obs,
                     codcob,
                     hora,
                     minuto,
                     codplpag,
                     numpedcli,
                     percvenda,
                     perdesc,
                     vldesconto,
                     vlfrete,
                     vloutrasdesp,
                     obs1,
                     obs2,
                     condvenda,
                     dtentrega,
                     numpedrca,
                     fretedespacho,
                     freteredespacho,
                     codfornecfrete,
                     codfornecredespacho,
                     tipocarga,
                     prazo1,
                     prazo2,
                     prazo3,
                     prazo4,
                     prazo5,
                     prazo6,
                     prazo7,
                     prazo8,
                     prazo9,
                     prazo10,
                     prazo11,
                     prazo12,
                     prazomedio,
                     obsentrega1,
                     obsentrega2,
                     obsentrega3,
                     tipoembalagem,
                     codepto,
                     campanha,
                     coddistrib,
                     vlcustocont,
                     vlcustorep,
                     numnotamanif,
                     seriemanif,
                     origemped,
                     especiemanif,
                     numpedentfut,
                     codfilialnf,
                     numcarmanif,
                     numorca,
                     codcontrato,
                     datapedcli,
                     numpedbnf,
                     broker,
                     codestabelecimento,
                     numtabela,
                     motivoposicao,
                     dtagendaentrega,
                     tipooper,
                     codmotbloqueio,
                     serieecf,
                     numcupom,
                     codclirecebedor,
                     conciliaimportacao,
                     numregiao,
                     numnota,
                     perdescfin,
                     restricaotransp,
                     geracp,
                     usaintegracaowms,
                     vendaassistida,
                     codgerente,
                     tipocontacorrente)
                    (SELECT vnproxnumped, --NUM DO PEDIDO
                            DATA,
                            codusur,
                            codcli,
                            numitens,
                            0, -- VLATEND
                            codpraca,
                            vsposicao,

                            --POSIÇÃO
                            vnnumcar,
                            codsupervisor,
                            registros_rp.codfilialretira,
                            vltotal,
                            0, -- VLTABELA
                            0, -- VLCUSTOREAL
                            0, -- VLCUSTOFIN
                            totpeso,
                            totvolume,
                            codemitente,
                            operacao,
                            tipovenda,
                            obs,
                            codcob,
                            hora,
                            minuto,
                            codplpag,
                            numpedcli,
                            vnpercvenda, --PERCVENDA
                            perdesc,
                            vldesconto,
                            vlfrete,
                            vloutrasdesp,
                            obs1,
                            obs2,
                            8,
                            dtentrega,
                            numpedrca,
                            fretedespacho,
                            freteredespacho,
                            codfornecfrete,
                            codfornecredespacho,
                            tipocarga,
                            prazo1,
                            prazo2,
                            prazo3,
                            prazo4,
                            prazo5,
                            prazo6,
                            prazo7,
                            prazo8,
                            prazo9,
                            prazo10,
                            prazo11,
                            prazo12,
                            prazomedio,
                            obsentrega1,
                            obsentrega2,
                            obsentrega3,
                            tipoembalagem,
                            codepto,
                            campanha,
                            coddistrib,
                            0, -- VLCUSTOCONT
                            0, -- VLCUSTOREP
                            numnotamanif,
                            seriemanif,
                            vsorigemped, --ORIGEMPED
                            especiemanif,
                            pnumped_tv7, --NUM DO PEDIDO TIPO 7
                            registros_rp.codfilialretira,
                            numcarmanif,
                            numorca,
                            codcontrato,
                            datapedcli,
                            numpedbnf,
                            broker,
                            codestabelecimento,
                            numtabela,
                            motivoposicao,
                            dtagendaentrega,
                            tipooper,
                            codmotbloqueio,
                            serieecf,
                            numcupom,
                            codclirecebedor,
                            conciliaimportacao,
                            numregiao,
                            numnota,
                            perdescfin,
                            restricaotransp,
                            geracp,
                            usaintegracaowms,
                            vendaassistida,
                            codgerente,
                            nvl(tipocontacorrente,'R')
                       FROM pcpedc
                      WHERE numped = vnnumped_tv8);
                EXCEPTION
                  WHEN OTHERS THEN
                    pmsg := SQLCODE || ' - ' || SQLERRM ||
                            ' -2- Erro ao gerar pedido tipo 8. '|| ' - '|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                    RAISE;
                END;

                BEGIN
                  INSERT INTO pcpedi
                    (codprod,
                     qt,
                     pvenda,
                     numped,
                     DATA,
                     codcli,
                     codusur,
                     numcar,
                     posicao,
                     st,
                     vlcustoreal,
                     vlcustofin,
                     ptabela,
                     percom,
                     perdesc,
                     qtfalta,
                     numseq,
                     vldesccustocmv,
                     vlcustocont,
                     vlcustorep,
                     vldescsuframa,
                     codst,
                     vldescfin,
                     pvendabase,
                     vlipi,
                     percipi,
                     poriginal,
                     iva,
                     pauta,
                     aliqicms1,
                     aliqicms2,
                     stclientegnre,
                     percbasered,
                     percbaseredst,
                     percbaseredstfonte,
                     perfretecmv,
                     custofinest,
                     perciss,
                     vliss,
                     complemento,
                     pbaserca,
                     vlverbacmv,
                     numverbarebcmv,
                     brinde,
                     baseicst,
                     qtcx,
                     qtpecas,
                     letracomiss,
                     codauxiliar,
                     txvenda,
                     codicmtab,
                     perdesccusto,
                     codfilialretira,
                     eancodprod,
                     vldescicmisencao,
                     perdescisentoicms,
                     vlverbacmvcli,
                     pvenda1,
                     tipoentrega)
                    (SELECT codprod,
                            qt,
                            pvenda,
                            vnproxnumped,
                            DATA,
                            codcli,
                            codusur,
                            vnnumcar,
                            vsposicao, --POSICAO
                            st,
                            vlcustoreal,
                            vlcustofin,
                            ptabela,
                            percom,
                            perdesc,
                            qtfalta,
                            numseq,
                            vldesccustocmv,
                            vlcustocont,
                            vlcustorep,
                            vldescsuframa,
                            codst,
                            vldescfin,
                            pvendabase,
                            vlipi,
                            percipi,
                            poriginal,
                            iva,
                            pauta,
                            aliqicms1,
                            aliqicms2,
                            stclientegnre,
                            percbasered,
                            percbaseredst,
                            percbaseredstfonte,
                            perfretecmv,
                            custofinest,
                            perciss,
                            vliss,
                            complemento,
                            pbaserca,
                            vlverbacmv,
                            numverbarebcmv,
                            brinde,
                            baseicst,
                            qtcx,
                            qtpecas,
                            letracomiss,
                            codauxiliar,
                            txvenda,
                            codicmtab,
                            perdesccusto,
                            codfilialretira,
                            eancodprod,
                            vldescicmisencao,
                            perdescisentoicms,
                            vlverbacmvcli,
                            pvenda1,
                            tipoentrega
                       FROM pcpedi
                      WHERE pcpedi.numped = vnnumped_tv8
                        AND NVL(pcpedi.codfilialretira, vscodfilial) =
                            registros_rp.codfilialretira
                        AND pcpedi.tipoentrega = registros_rp.tipoentrega);
                EXCEPTION
                  WHEN OTHERS THEN
                    pmsg := SQLCODE || ' - ' || SQLERRM ||
                            ' -3- Erro ao gerar os itens do pedido tipo 8. '|| ' - '|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                    RAISE;
                END;

                --Excluindo itens do pedido TV8 original que foram lançando no novo pedido TV8
                DELETE FROM pcpedi
                 WHERE numped = vnnumped_tv8
                   AND codfilialretira = registros_rp.codfilialretira
                   AND tipoentrega = registros_rp.tipoentrega;

                -- Totalizando Pedido TV8 EN gerado
                SELECT SUM((NVL(pcpedi.qt, 0) + NVL(pcpedi.qtfalta, 0)) *
                           NVL(pcpedi.pvenda, 0)) vltotal,
                       COUNT(*) numitens,
                       SUM(NVL(pcpedi.qt, 0) * pcprodut.pesobruto ) totpeso,
                       SUM(NVL(pcpedi.qt, 0) * pcprodut.volume ) totvolum
                  INTO vnvltotal, vnnumitens, vntotpeso, vntotvolume
                  FROM pcpedi, pcpedc, pcprodut
                 WHERE pcpedi.codprod = pcprodut.codprod
                   AND pcpedi.numped = pcpedc.numped
                   AND pcpedc.numped = vnproxnumped;

                UPDATE pcpedc
                   SET vltotal     = vnvltotal,
                       vlatend     = 0,
                       totpeso     = vntotpeso,
                       totvolume   = vntotvolume,
                       numitens    = vnnumitens,
                       vltabela    = 0,
                       vlcustoreal = 0,
                       vlcustocont = 0,
                       vlcustorep  = 0,
                       vlcustofin  = 0,
                       numcar      = vnnumcar
                 WHERE numped = vnproxnumped;
              END IF;
            END LOOP; -- REGISTROS_RP

            IF vnnumcar > 0 THEN
              INSERT INTO pccarreg
                (numcar,
                 dtsaida,
                 totpeso,
                 totvolume,
                 vltotal,
                 destino,
                 datamon,
                 codveiculo,
                 codfuncmon)
              VALUES
                (vnnumcar,
                 TRUNC(SYSDATE),
                 vntotpeso,
                 vntotvolume,
                 vnvltotal,
                 'VENDA BALCAO',
                 TRUNC(SYSDATE),
                 0,
                 pncodfunc);
            END IF;
          END IF; --IF REGISTROS.TIPOENTREGA = 'EN'
        END IF; --IF CONTADOR > 0

        vicontador := vicontador + 1;
      END LOOP; -- REGISTROS
    END IF; --IF VICOUNTPED > 1

    SELECT COUNT(*)
      INTO vicontador_rp
      FROM pcpedi
     WHERE numped = vnnumped_tv8
       AND NVL(tipoentrega, '  ') = 'RP';

    SELECT COUNT(*)
      INTO vicontador_en
      FROM pcpedi
     WHERE numped = vnnumped_tv8
       AND NVL(tipoentrega, '  ') = 'EN';

    IF (vicontador_rp > 0) AND (vicontador_en = 0) THEN
      UPDATE pcpedc
         SET posicao     = 'M',
             numcar      = NVL(vnnumcar, 0),
             origemped   = 'R',
             codfilial   = NVL((SELECT i.codfilialretira
                                 FROM pcpedi i
                                WHERE i.numped = vnnumped_tv8
                                  AND NVL(i.tipoentrega, '  ') = 'RP'
                                  AND ROWNUM = 1),
                               pcpedc.codfilial),
             codfilialnf = NVL((SELECT i.codfilialretira
                                 FROM pcpedi i
                                WHERE i.numped = vnnumped_tv8
                                  AND NVL(i.tipoentrega, '  ') = 'RP'
                                  AND ROWNUM = 1),
                               pcpedc.codfilial)
       WHERE numped = vnnumped_tv8;

      UPDATE pcpedi
         SET posicao = 'M', numcar = NVL(vnnumcar, 0)
       WHERE numped = vnnumped_tv8;
    END IF;

    IF (vicontador_rp = 0) AND (vicontador_en > 0) THEN
      UPDATE pcpedc
         SET codfilial   = NVL((SELECT i.codfilialretira
                                 FROM pcpedi i
                                WHERE i.numped = vnnumped_tv8
                                  AND NVL(i.tipoentrega, '  ') = 'EN'
                                  AND ROWNUM = 1),
                               pcpedc.codfilial),
             codfilialnf = NVL((SELECT i.codfilialretira
                                 FROM pcpedi i
                                WHERE i.numped = vnnumped_tv8
                                  AND NVL(i.tipoentrega, '  ') = 'EN'
                                  AND ROWNUM = 1),
                               pcpedc.codfilial),
             coddistrib  = NULL
       WHERE numped = vnnumped_tv8;
    END IF;

    -- Totalizando o Pedido TV8 após o desdobramento
    SELECT SUM((NVL(pcpedi.qt, 0) + NVL(pcpedi.qtfalta, 0)) *
               NVL(pcpedi.pvenda, 0)) vltotal,
           COUNT(*) numitens,
           SUM(NVL(pcpedi.qt, 0) * pcprodut.pesobruto ) totpeso,
           SUM(NVL(pcpedi.qt, 0) * pcprodut.volume ) totvolum
      INTO vnvltotal, vnnumitens, vntotpeso, vntotvolume
      FROM pcpedi, pcpedc, pcprodut
     WHERE pcpedi.codprod = pcprodut.codprod
       AND pcpedi.numped = pcpedc.numped
       AND pcpedc.numped = vnnumped_tv8;

    UPDATE pcpedc
       SET vltotal     = vnvltotal,
           vlatend     = 0,
           totpeso     = vntotpeso,
           totvolume   = vntotvolume,
           numitens    = vnnumitens,
           vltabela    = 0,
           vlcustoreal = 0,
           vlcustocont = 0,
           vlcustorep  = 0,
           vlcustofin  = 0
     WHERE numped = vnnumped_tv8;
  EXCEPTION
    WHEN OTHERS THEN
      pmsg := 'Não foi possível desdobrar Pedido TV8 de Venda Assistida.' ||
              CHR(13) || 'Erro : ' || pmsg || CHR(13) || SQLCODE || '-' ||
              SQLERRM || ' - '|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

  END prc_desdobrar_ped_tv8;

  PROCEDURE buscardadoscliente(pcodcli                  IN pcclient.codcli%TYPE,
                               vncodigopraca            IN OUT pcclient.codpraca%TYPE,
                               vnprazoadicional         IN OUT pcclient.prazoadicional%TYPE,
                               vnperdescfin             IN OUT pcclient.perdescfin%TYPE,
                               vnperdescisentoicms      IN OUT pcclient.perdescisentoicms%TYPE,
                               vsisentotxboleto         IN OUT pcclient.isentotxboleto%TYPE,
                               vddtvencprazoadicional   IN OUT pcclient.dtvencprazoadicional%TYPE,
                               vsusacreclifat           IN OUT pcclient.usacreclifat%TYPE,
                               vsatualizasaldoccdescfin IN OUT pcclient.atualizasaldoccdescfin%TYPE,
                               psgeratitulost           IN OUT pcclient.geratitulost%TYPE,
                               piprazovencst            IN OUT pcclient.prazovencst%TYPE,
                               psagregarvalorstdescfin  IN OUT pcclient.agregarvalorstdescfin%TYPE,
                               pstipotratamentodescfin  IN OUT pcclient.tipotratamentodescfin%TYPE,
                               pnqtddiasaplicdescfin    IN OUT pcclient.qtddiasaplicdescfin%TYPE,
                               vnvlminimost             IN OUT pcclient.vlminimost%TYPE,
                               psutilizapedclinfe       IN OUT pcclient.utilizapedclinfe%TYPE,
                               pssulframa               IN OUT pcclient.sulframa%TYPE,
                               psusadescontoicms        IN OUT pcclient.usadescontoicms%TYPE,
                               pncodcidade              IN OUT pcclient.codcidade%TYPE,
                               pmensagem                IN OUT VARCHAR)
  /******************************************************************************************
     -> PROGRAMA UTILIZADO PELA PROCEDURE DE FATURAMENTO
     -> Versao : Pacote
    *************************************************************************************************************
     Data          Autor   Tarefa   Obs.
    *************************************************************************************************************
     25/01/2006    Pablo   24439    Procedure alterada para acrescentar o parâmetro de entrada pnumped,
                                    para buscar os dados da UF do PCVENDACONSUM caso o cliente seja 1 ou 2
     07/02/2006    Pablo   24836    Procedure alterada para acrescentar o parâmetro pcclient.dtvencprazoadicional
     26/01/2008    Sabrina 57253    Buscar ivafonte diferenciado por cliente
     22/01/2009    Pablo   72711    Alteração para passar a retornar o novo campo do cliente (PCClient.AtualizaSaldoCCDescFin)
     08/05/2009    Pablo   78867    Alteração para retornar o parametro PCClient.UsaCreCliFat
     26/06/2009    Pablo   87935    Alteração para a validar o parâmetro PCClient.ParticipaFuncep
     17/11/2009    Pablo   96898    Alteração para validar o parâmetro  (PCClient.AtualizaSaldoCCDescFin) com NVL para 'N' para manter compatibilidade
     24/05/2011    Pablo   131731   Alteração para retorar os campos tipotratamentodescfin, qtddiasaplicdescfin
     06/06/2011    Pablo   132501   Alteração para retornar o campo PCClient.VlMinimoST
    *************************************************************************************************************/
   IS
    --vicontador NUMBER;
    --vsestent   pcvendaconsum.estent%TYPE;
  BEGIN
    SELECT codpraca,
           NVL(prazoadicional, 0),
           NVL(perdescfin, 0),
           NVL(perdescisentoicms, 0),
           isentotxboleto,
           dtvencprazoadicional,
           NVL(usacreclifat, 'S'),
           NVL(atualizasaldoccdescfin, 'N'),
           NVL(geratitulost, 'N'),
           pcclient.agregarvalorstdescfin,
           NVL(tipotratamentodescfin, 'DV'),
           NVL(qtddiasaplicdescfin, 0),
           vlminimost,
           NVL(pcclient.prazovencst, 0),
           NVL(pcclient.utilizapedclinfe, 'N'),
           pcclient.sulframa,
           NVL(pcclient.usadescontoicms, 'N'),
           pcclient.codcidade
      INTO vncodigopraca,
           vnprazoadicional,
           vnperdescfin,
           vnperdescisentoicms,
           vsisentotxboleto,
           vddtvencprazoadicional,
           vsusacreclifat,
           vsatualizasaldoccdescfin,
           psgeratitulost,
           psagregarvalorstdescfin,
           pstipotratamentodescfin,
           pnqtddiasaplicdescfin,
           vnvlminimost,
           piprazovencst,
           psutilizapedclinfe,
           pssulframa,
           psusadescontoicms,
           pncodcidade
      FROM pcclient
     WHERE codcli = pcodcli;
  EXCEPTION
    WHEN OTHERS THEN
      pmensagem := SQLCODE || ' - ' || SQLERRM ||
                   ' -5- Erro ao buscar dados do cliente '|| ' - '|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
  END buscardadoscliente;

  PROCEDURE buscardadosclientenf(pcodcli                   IN pcclient.codcli%TYPE,
                                 pnumped                   IN pcpedc.numped%TYPE,
                                 vc2uf_cliente             IN OUT pcclient.estent%TYPE,
                                 vc2tipopessoa             IN OUT pcclient.tipofj%TYPE,
                                 vc2codigosuframa          IN OUT pcclient.sulframa%TYPE,
                                 vc2isentoicms             IN OUT pcclient.isentoicms%TYPE,
                                 vc2codigocacex            IN OUT pcclient.cacex%TYPE,
                                 vsieent                   IN OUT pcclient.ieent%TYPE,
                                 vscalculast               IN OUT pcclient.calculast%TYPE,
                                 vsclientefontest          IN OUT pcclient.clientefontest%TYPE,
                                 vsutilizaiesimplificada   IN OUT pcclient.utilizaiesimplificada%TYPE,
                                 vsconsumidorfinal         IN OUT pcclient.consumidorfinal%TYPE,
                                 vstipoempresa             IN OUT pcclient.tipoempresa%TYPE,
                                 vsorgaopub                IN OUT pcclient.orgaopub%TYPE,
                                 vscontribuinte            IN OUT pcclient.contribuinte%TYPE,
                                 vsusaivafontediferenciado IN OUT pcclient.usaivafontediferenciado%TYPE,
                                 vnivafonte                IN OUT pcclient.ivafonte%TYPE,
                                 vsorgaopubfederal         IN OUT pcclient.orgaopubfederal%TYPE,
                                 vsparticipafuncep         IN OUT pcclient.participafuncep%TYPE,
                                 vnnumregiao               IN OUT pcpraca.numregiao%TYPE,
                                 pncodcidade               IN OUT pcclient.codcidade%TYPE,
                                 psorgaopubmunicipal       IN OUT pcclient.orgaopubmunicipal%TYPE,
                                 pmensagem                 IN OUT VARCHAR)
  /******************************************************************************************
     -> PROGRAMA UTILIZADO PELA PROCEDURE DE FATURAMENTO
     -> Versao : Pacote
     *************************************************************************************************************
     Data         Autor     Tarefa       Descrição
    *************************************************************************************************************
     09/07/2009   Pablo     88523        Procedimento criado apartir de BuscarDadosCliente para retornar as informações do Cliente NF (PCPedC.CodCliNF)
     21/07/2009   Pablo     89301        Alteração para retornar NumRegião do Cliente NF
     27/11/2009   Pablo     97498        Alteração para retornar PCClient.IsentoICMS corretamente.
    *************************************************************************************************************/
   IS
    vicontador NUMBER;
    vsestent   pcvendaconsum.estent%TYPE;
  BEGIN
    SELECT UPPER(LTRIM(RTRIM(estent))),
           tipofj,
           sulframa,
           NVL(isentoicms, 'N'),
           cacex,
           TRIM(UPPER(ieent)),
           calculast,
           NVL(clientefontest, 'N'),
           NVL(utilizaiesimplificada, 'N'),
           NVL(consumidorfinal, 'N'),
           NVL(tipoempresa, 'O'),
           NVL(orgaopub, 'N'),
           NVL(contribuinte, 'N'),
           NVL(usaivafontediferenciado, 'N'),
           NVL(ivafonte, 0),
           NVL(orgaopubfederal, 'N'),
           NVL(participafuncep, 'N'),
           (SELECT numregiao FROM pcpraca WHERE codpraca = pcclient.codpraca),
           codcidade,
           PCCLIENT.ORGAOPUBMUNICIPAL
      INTO vc2uf_cliente,
           vc2tipopessoa,
           vc2codigosuframa,
           vc2isentoicms,
           vc2codigocacex,
           vsieent,
           vscalculast,
           vsclientefontest,
           vsutilizaiesimplificada,
           vsconsumidorfinal,
           vstipoempresa,
           vsorgaopub,
           vscontribuinte,
           vsusaivafontediferenciado,
           vnivafonte,
           vsorgaopubfederal,
           vsparticipafuncep,
           vnnumregiao,
           pncodcidade,
           psorgaopubmunicipal
      FROM pcclient
     WHERE codcli = pcodcli;

    IF pcodcli IN (1, 2) THEN
      SELECT COUNT(*)
        INTO vicontador
        FROM pcvendaconsum
       WHERE numped = pnumped;

      IF vicontador = 1 THEN
        SELECT UPPER(LTRIM(RTRIM(estent))) --Tarefa: 178613
          INTO vsestent
          FROM pcvendaconsum
         WHERE numped = pnumped;

        IF NVL(TRIM(vsestent), ' ') <> ' ' THEN
          vc2uf_cliente := vsestent;
        END IF;
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      pmensagem := SQLCODE || ' - ' || SQLERRM ||
                   ' -5- Erro ao buscar dados do cliente '|| ' - '|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
  END buscardadosclientenf;

  PROCEDURE buscartributacao(pcodprod                       IN NUMBER,
                             pnumregiao                     IN NUMBER,
                             pcodfilialnf                   IN VARCHAR2,
                             pufcliente                     IN VARCHAR2,
                             pusatributacaoporuf            IN pcconsum.usatributacaoporuf%TYPE,
                             pnumnotaconsig                 IN pcpedc.numnotaconsig%TYPE,
                             vncodicmtab                    IN OUT pctribut.codicmtab%TYPE,
                             vssittribut                    IN OUT VARCHAR,
                             vssittributpf                  IN OUT VARCHAR,
                             vncodicm                       IN OUT pctribut.codicm%TYPE,
                             vnpercbasered                  IN OUT pctribut.percbasered%TYPE,
                             vnpercbaseredst                IN OUT pctribut.percbaseredst%TYPE,
                             vnpercbaseredstfonte           IN OUT pctribut.percbaseredstfonte%TYPE,
                             vnpercbaseredconsumidor        IN OUT pctribut.percbaseredconsumidor%TYPE,
                             vnperbaserednrpa               IN OUT pctribut.perbaserednrpa%TYPE,
                             vsutilizapercbaseredpf_trib    IN OUT pctribut.utilizapercbaseredpf%TYPE,
                             vnpauta                        IN OUT pctribut.pauta%TYPE,
                             vniva                          IN OUT pctribut.iva%TYPE,
                             vnivafonte                     IN OUT pctribut.ivafonte%TYPE,
                             vscalcbcicmsnf                 IN OUT pctribut.calcbcicmsnf%TYPE,
                             vncfoest                       IN OUT pctribut.codfiscal%TYPE,
                             vncfointer                     IN OUT pctribut.codfiscalinter%TYPE,
                             vncfoestpf                     IN OUT pctribut.codfiscalpf%TYPE,
                             vncfointerpf                   IN OUT pctribut.codfiscalinterpf%TYPE,
                             vncfobonific                   IN OUT pctribut.codfiscalbonific%TYPE,
                             vncfobonificinter              IN OUT pctribut.codfiscalbonificinter%TYPE,
                             vncfotransf                    IN OUT pctribut.codfiscaltransf%TYPE,
                             vncfotransfinter               IN OUT pctribut.codfiscaltransfinter%TYPE,
                             vncfointernasc                 IN OUT pctribut.codfiscalinternasc%TYPE,
                             vncfointernascpf               IN OUT pctribut.codfiscalinternascpf%TYPE,
                             vncfodevcliinternasc           IN OUT pctribut.codfiscaldevcliinternasc%TYPE,
                             vncfotransfinternasc           IN OUT pctribut.codfiscaltransfinternasc%TYPE,
                             vncfobonificinternasc          IN OUT pctribut.codfiscalbonificinternasc%TYPE,
                             vncfodevcliboninternasc        IN OUT pctribut.codfiscaldevcliboninternasc%TYPE,
                             vncfodevcliproentinternasc     IN OUT pctribut.codfiscaldevcliproentinternasc%TYPE,
                             vncfoprontaentinternasc        IN OUT pctribut.codfiscalprontaentinternasc%TYPE,
                             vncodst                        IN OUT pctribut.codst%TYPE,
                             vncodicmpf                     IN OUT pctribut.codicmpf%TYPE,
                             vncfoprontaent                 IN OUT pctribut.codfiscalprontaent%TYPE,
                             vncfoprontaentinter            IN OUT pctribut.codfiscalprontaentinter%TYPE,
                             vncfovendaconsig               IN OUT pctribut.codfiscalvendaconsig%TYPE,
                             vncfovendaconsiginter          IN OUT pctribut.codfiscalvendaconsiginter%TYPE,
                             vncfovendaconsiginternasc      IN OUT pctribut.codfiscalvendaconsiginternasc%TYPE,
                             vncfovendaentfut               IN OUT pctribut.codfiscalvendaentfut%TYPE,
                             vncfovendaentfutinter          IN OUT pctribut.codfiscalvendaentfutinter%TYPE,
                             vncfosimpentfut                IN OUT pctribut.codfiscalsimpentfut%TYPE,
                             vncfosimpentfutinter           IN OUT pctribut.codfiscalsimpentfutinter%TYPE,
                             vncfomercadoriaconsig          IN OUT pctribut.codfiscalmercconsig%TYPE,
                             vncfomercadoriaconsiginter     IN OUT pctribut.codfiscalmercconsiginter%TYPE,
                             vncfomercadoriaconsiginternasc IN OUT pctribut.codfiscalmercconsiginternasc%TYPE,
                             vncfovendaprontaent            IN OUT pctribut.codfiscalvendaprontaent%TYPE,
                             vncfovendaprontaentinter       IN OUT pctribut.codfiscalprontaentinter%TYPE,
                             vnpercacrescbasepfest          IN OUT pctribut.percacrescbasepfest%TYPE,
                             vstipocalculognre              IN OUT pctribut.tipocalculognre%TYPE,
                             vncodfiscalisentost            IN OUT pctribut.codfiscalisentost%TYPE,
                             vncodfiscalisentostinter       IN OUT pctribut.codfiscalisentostinter%TYPE,
                             vncodfiscalisentostinternasc   IN OUT pctribut.codfiscalisentostinternasc%TYPE,
                             vssittributisentost            IN OUT pctribut.sittributisentost%TYPE,
                             vncodfiscaltroca               IN OUT pctribut.codfiscaltroca%TYPE,
                             vncodfiscaltrocainter          IN OUT pctribut.codfiscaltrocainter%TYPE,
                             vncodfiscaltrocainternasc      IN OUT pctribut.codfiscaltrocainternasc%TYPE,
                             vnaliqstsaida                  IN OUT pctribut.aliqstsaida%TYPE,
                             vnaliqstsaidapf                IN OUT pctribut.aliqstsaidapf%TYPE,
                             vssittributnrpa                IN OUT pctribut.sittributnrpa%TYPE,
                             vnpercivamex                   IN OUT pctribut.percivamex%TYPE,
                             vnaliqicms1transf              IN OUT pctribut.aliqicms1transf%TYPE,
                             vnaliqicms2transf              IN OUT pctribut.aliqicms2transf%TYPE,
                             vnivatransf                    IN OUT pctribut.ivatransf%TYPE,
                             vnpautatransf                  IN OUT pctribut.pautatransf%TYPE,
                             vnpercbaseredsttransf          IN OUT pctribut.percbaseredsttransf%TYPE,
                             vncodicmtransf                 IN OUT pctribut.codicmtransf%TYPE,
                             vssittributtransf              IN OUT pctribut.sittributtransf%TYPE,
                             vncodicmprodrural              IN OUT pctribut.codicmprodrural%TYPE,
                             vnperpautaicms                 IN OUT pctribut.perpautaicms%TYPE,
                             vnperpautaicmsinter            IN OUT pctribut.perpautaicmsinter%TYPE,
                             vnpercbaseredadicional         IN OUT pctribut.percbaseredadicional%TYPE,
                             vnpercbaseredadicionalinter    IN OUT pctribut.percbaseredadicionalinter%TYPE,
                             vsdescicmsreduzbaseicms        IN OUT pctribut.descicmsreduzbaseicms%TYPE,
                             vnaliqicms1fonte               IN OUT pctribut.aliqicms1fonte%TYPE,
                             vnaliqicms2fonte               IN OUT pctribut.aliqicms2fonte%TYPE,
                             vsusacfopbnfparabrinde         IN OUT pctribut.usacfopbnfparabrinde%TYPE,
                             vscalcularicmssittribut060     IN OUT pctribut.calcularicmssittribut060%TYPE,
                             vscodfiscaltv9                 IN OUT pctribut.codfiscaltv9%TYPE,
                             vscodfiscalintertv9            IN OUT pctribut.codfiscalintertv9%TYPE,
                             vscodfiscalinternasctv9        IN OUT pctribut.codfiscalinternasctv9%TYPE,
                             vnperacrescimocusto            IN OUT pctribut.peracrescimocusto%TYPE,
                             vnperacrescimofuncep           IN OUT pctribut.peracrescimofuncep%TYPE,
                             vnpercbaseredtranfsaid         IN OUT pctribut.percbaseredtranfsaid%TYPE,
                             vncodfiscalconsig              IN OUT pctribut.codfiscalconsig%TYPE,
                             vncodfiscalconsiginter         IN OUT pctribut.codfiscalconsiginter%TYPE,
                             vncodfiscalconsiginternac      IN OUT pctribut.codfiscalconsiginternac%TYPE,
                             vnpercacrescbasepfint          IN OUT pctribut.percacrescbasepfint%TYPE,
                             vspagtonomedoremetente         IN OUT pctribut.pagtonomedoremetente%TYPE,
                             vncodfiscaltriangular          IN OUT pctribut.codfiscaltriangular%TYPE,
                             vncodfiscaltriangularinter     IN OUT pctribut.codfiscaltriangularinter%TYPE,
                             vncodfiscaltriangularinternasc IN OUT pctribut.codfiscaltriangularinternasc%TYPE,
                             vncfoptriangularpf             IN OUT pctribut.codfiscaltriangularpf%TYPE,
                             vncfoptriangularinterpf        IN OUT pctribut.codfiscaltriangularinterpf%TYPE,
                             vncfoptriangularinternascpf    IN OUT pctribut.codfiscaltriangularinternascpf%TYPE,
                             vnperdifereimentoicms          IN OUT pctribut.perdifereimentoicms%TYPE,
                             vncfopcontaordem               IN OUT pctribut.codfiscalcontaordem%TYPE,
                             vncfopcontaordeminter          IN OUT pctribut.codfiscalcontaordeminter%TYPE,
                             vncfopcontaordemsimpent        IN OUT pctribut.codfiscalcontaordemsimpent%TYPE,
                             vncfopcontaordemsimpentinte    IN OUT pctribut.codfiscalcontaordemsimpentinte%TYPE,
                             vszerarbaseicmsorgpubsuframa   IN OUT pctribut.zerarbaseicmsorgpubsuframa%TYPE,
                             --Tarefa 126672
                             vspagtonomedesttransf         IN OUT pctribut.pagtonomedesttransf%TYPE,
                             vspagtonomeremettransf        IN OUT pctribut.pagtonomeremettransf%TYPE,
                             vstipocalculognretransf       IN OUT pctribut.tipocalculognretransf%TYPE,
                             vspagtonomedocliente          IN OUT pctribut.pagtonomedocliente%TYPE,
                             psreduzbaseicmdecretomaranhao IN OUT pctribut.reduzbaseicmdecretomaranhao%TYPE,
                             pssittributtv7                IN OUT pctribut.sittributtv7%TYPE,
                             --Tarefa 134475
                             psutilizaparcadicfecp IN OUT pctribut.utilizaparcadicfecp%TYPE,
                             --Tarefa 141140
                             pnaliqicmsfecp IN OUT pctribut.aliqicmsfecp%TYPE,
                             --Tarefa 141140
                             psisentaicmsbonific     IN OUT pctribut.isentaicmsbonific%TYPE,
                             pssittributbonific      IN OUT pctribut.sittributbonific%TYPE,
                             pssittributtv8          IN OUT pctribut.sittributtv8%TYPE,
                             pncodfiscalsuframa      IN OUT pctribut.codfiscalsuframa%TYPE,
                             pssittributsuframa      IN OUT pctribut.sittributsuframa%TYPE,
                             pncodfiscalsuframainter IN OUT pctribut.codfiscalsuframainter%TYPE,
                             psusaisencaoicmsvp      IN OUT pctribut.usaisencaoicmsvp%TYPE,
                             pdaliqicmstv9           IN OUT pctribut.aliqicmstv9%TYPE,
                             paplicaredicmssemipiba  IN OUT pctribut.aplicaredicmssemipiba%TYPE, --Tarefa: 168659
                             psittributpautaicms     IN OUT pctribut.sittributpautaicms%TYPE,
                             pvlpautaicmsinterest    IN OUT pctribut.vlpautaicmsinterest%TYPE,
                             psittributpautaicmspf   IN OUT pctribut.sittributpautaicmspf%TYPE, --Tarefa: 181175
                             vncodicmsimplesnac      IN OUT pctribut.CODICMSIMPLESNAC%TYPE, --tarefa 192644
                             vnperbaseredsimplesnac  IN OUT pctribut.PERBASEREDSIMPLESNAC%type, --tarefa 192644
                             vnperctributos          IN OUT pctribut.perctributos%type,
                             vncodprodgnre           IN OUT pctribut.codprodgnre%TYPE,
                             pssittributorgaopub     IN OUT PCTRIBUT.SITTRIBUTORGAOPUB%TYPE,
                             psusavlultentmediobasest IN OUT PCTRIBUT.USAVLULTENTMEDIOBASEST%TYPE,
                             pnvlultentmes           IN OUT PCTABPR.vlultentmes%TYPE,
                             vssittribsimplesnac     IN OUT PCTRIBUT.SITTRIBUTSIMPLESNAC%TYPE,--HIS.00875.2013
                             pmensagem               IN OUT VARCHAR,
                             ppessoafisica           IN OUT BOOLEAN,
                             pnpercacresicmspf_pi    IN OUT NUMBER,
                             --HIS.04000.2014
                             pssittribstfontepf      IN OUT VARCHAR,
                             pssittribstfontepj      IN OUT VARCHAR,
                             pncodfiscalstfonteest   IN OUT NUMBER,
                             pncodfiscalstfonteinterest IN OUT NUMBER,
                             pncodfiscalstfonteinternac IN OUT NUMBER,
                             -- HIS.02114.2015
                             pncodfiscalsimplesnacest      IN OUT NUMBER,
                             pncodfiscalsimplesnacinterest in OUT NUMBER,
                             ------------------
                             pnperdiferimentoicmstransf   IN OUT NUMBER,
                             --HIS.02571.2015
                             psBNFNAOCALCULAICMS          IN OUT PCTRIBUT.BNFNAOCALCULAICMS%TYPE,
                             psSITTRIBUTBNFTV1            IN OUT PCTRIBUT.SITTRIBUTBNFTV1%TYPE,
                             pngeraricmslivrofiscal       IN OUT PCTRIBUT.Geraricmslivrofiscal%TYPE, --HIS.03545.2015
                             pscodcest                    IN OUT PCTRIBUT.CODCEST%TYPE, --HIS.03419.2015
                             -- HIS.02754.2015
                             psUsaValorultEntbaseICMS      IN OUT PCTRIBUT.USAVALORULTENTBASEICMS%TYPE,
                             psUsaValorultEntbaseICMSTONTE IN OUT PCTRIBUT.USAVALORULTENTBASEICMSFONTE%TYPE,
                             pssittributtv9                IN OUT PCTRIBUT.SITTRIBUTTV9%TYPE,
                             pPERCPISRETORGPUB             IN OUT PCTRIBUT.PERCPISRETORGPUB%TYPE,
                             pPERCCOFINSRETORGPUB          IN OUT PCTRIBUT.PERCCOFINSRETORGPUB%TYPE,
                             pPERCIRPJRETORGPUB            IN OUT PCTRIBUT.PERCIRPJRETORGPUB%TYPE,
                             pPERCCSLLRETORGPUB            IN OUT PCTRIBUT.PERCCSLLRETORGPUB%TYPE,
                             pPERCPISRETORGPUBEST          IN OUT PCTRIBUT.PERCPISRETORGPUB%TYPE,
                             pPERCCOFINSRETORGPUBEST       IN OUT PCTRIBUT.PERCCOFINSRETORGPUB%TYPE,
                             pPERCIRPJRETORGPUBEST         IN OUT PCTRIBUT.PERCIRPJRETORGPUB%TYPE,
                             pPERCCSLLRETORGPUBEST         IN OUT PCTRIBUT.PERCCSLLRETORGPUB%TYPE,
                             pPERCPISRETORGPUBMUN          IN OUT PCTRIBUT.PERCPISRETORGPUB%TYPE,
                             pPERCCOFINSRETORGPUBMUN       IN OUT PCTRIBUT.PERCCOFINSRETORGPUB%TYPE,
                             pPERCIRPJRETORGPUBMUN         IN OUT PCTRIBUT.PERCIRPJRETORGPUB%TYPE,
                             pPERCCSLLRETORGPUBMUN         IN OUT PCTRIBUT.PERCCSLLRETORGPUB%TYPE,
                              --HIS.03465.2015
                             pSITTRIBUTTRIANG               IN OUT PCTRIBUT.SITTRIBUTTRIANG%TYPE,
                             pAPLICAACRESPFJURIDICA         IN OUT PCTRIBUT.APLICAACRESPFJURIDICA%TYPE,
                             pCalculaFECPCLIMEI             IN OUT PCTRIBUT.CALCULAFECPCLIMEI%TYPE,
                             pagregadescst1                 IN OUT PCTRIBUT.agregadescst1%TYPE,
                             pcodfiscalisentostramo         IN OUT PCTRIBUT.codfiscalisentostramo%TYPE,
                             pcodfiscalisentostramointer    IN OUT PCTRIBUT.codfiscalisentostramointer%TYPE,
                             psittributisentostramo         IN OUT PCTRIBUT.sittributisentostramo%TYPE,
                             psVendaTriangular              IN     PCPEDC.VENDATRIANGULAR%TYPE,
                             psCalcBaseicmsMediaEnt         IN OUT PCTRIBUT.CalcBaseicmsMediaEnt%TYPE,
                             psCalcularFECPISENTOie         IN OUT PCTRIBUT.CalcularFECPISENTOie%TYPE,
                             psCalcularFUNCEPISENTOie       IN OUT PCTRIBUT.CalcularFUNCEPISENTOie%TYPE,
                             psMEINAOCALCDIF                IN OUT PCTRIBUT.MEINAOCALCDIF%TYPE,
                             pssittributmei                 IN OUT PCTRIBUT.sittributmei%TYPE,
                             pnCODFISCALISENTOSTCONT        IN OUT PCTRIBUT.CODFISCALISENTOSTCONT%TYPE,
                             pnCODFISCALISENTOSTCONTINTER   IN OUT PCTRIBUT.CODFISCALISENTOSTCONTINTER%TYPE,
                             pnCODFISCALISENSTCONTINTERNASC IN OUT PCTRIBUT.CODFISCALISENTOSTCONTINTERNASC%TYPE,
                             pnCODFISCALCONSUFINAL          IN OUT PCTRIBUT.CODFISCALCONSUFINAL%TYPE,
                             pnCODFISCALCONSUFINALINTER     IN OUT PCTRIBUT.CODFISCALCONSUFINALINTER%TYPE,
                             pnCODFISCALCONSUFINALINTERNASC IN OUT PCTRIBUT.CODFISCALCONSUFINALINTERNASC%TYPE,
                             psAplicaMVABaseIcms            IN OUT PCTRIBUT.APLICAMVABASEICMS%TYPE,
                             psUTILIZAMOTORCALCULO          IN OUT PCTRIBUT.UTILIZAMOTORCALCULO%TYPE,
							 psNAOPERSISTEIVAPCMOV			IN OUT PCTRIBUT.NAOPERSISTEIVAPCMOV%TYPE,
                             psisentaicmssittribut041       IN OUT pctribut.isentaicmssittribut041%TYPE)


  /******************************************************************************************
    ->Nome da PROCEDURE : BUSCARTRIBUTACAO
    ->Objetivo          : Faturar pedidos nao faturados.
    ->Versao            : Pacote

    -------------------------------- Historico ------------------------------------------------------------------
    Data        Responsavel     Tarefa    Comentarios
    -----------------------------------------------------------------------------------------------------------
    06/10/2005  Sabrina         21879     Nao trazer sittribut com mais de 2 digitos
    01/02/2007  Pablo           37229     Retonas as novas informações: pctribut.codfiscaltroca,
                                          pctribut.codfiscaltrocainter, pctribut.codfiscaltrocainternasc
    15/02/2007  Pablo           39171     Alteração para retornar a seguintes informações
                                          PCTRIBUT.AliqStSaida e PCTRIBUT.AliqSTSaidaPF
    26/03/2007  Pablo           40720     Procedure alterada para retornar o campo PCTRIBUT.SitTributNRPA
    27/07/2007  Pablo           46966     Procedure alterada para retornar a tributação de transferência
                                          (pctribut.aliqicms1transf, pctribut.aliqicms2transf, pctribut.ivatransf,
                                           pctribut.pautatransf, pctribut.percbaseredsttransf, pctribut.codicmtransf,
                                           pctribut.sittributtransf)
    08/07/2007  Pablo           50778     Procedure alterada para retornar a informação 'Cod ICMS Produtor Rural'
                                          pctribut.CodICMProdRural
    12/11/2007  Pablo           53746     Alteração para retornar os seguintes campos:
                                          - PCTRIBUT.PerPautaICMS
                                          - PCTRIBUT.PerPautaICMSInter
                                          - PCTRIBUT.PercBaseRedAdicional
                                          - PCTRIBUT.PercBaseRedAdicionalInter
    20/11/2007  Pablo           50778     Alteração para retornar o novo parâmetro pctribut.DescICMSReduzBaseICMS
    26/01/2008  Sabrina         57253     Tratar st fonte diferenciado por cliente e nova forma de validacao
                                          de incidencia de st fonte
    02/05/2008  Pablo           60930     Alteração para passar a retornar o campo PCTRIBUT.UsaCFOPBNFParaBrinde.
    31/07/2008  Pablo           66502     Alteração para desfazar a customização da tarefa 60930
    29/06/2009  Pablo           87935     Alteração para passar a validar o parâmetro PCTribut.PerAcrescimoFuncep
    06/07/2009  Pablo           83967     Alteração para passar a retornar o campo PCTRIBUT.PercBaseRedTranfSaid.
    08/01/2010  Pablo           98115     Alteração para passar a retornar o campo PCTribut.pagtonomedoremetente
    28/07/2010  Pablo          112209     Alteração para retirar o NVL para zero do campo pctribut.percbaseredconsumidor
    01/10/2010  Pablo          115229     Alteração para retornar o SitTribut com 3 posições
    18/10/2010  Pablo          114702     Alteração para retornar o CFOP de Venda Triangular para Pessoa Física.
    27/10/2010  Pablo             --      Retornar % de ICMS diferimento com NVL
    13/12/2010  Pablo          117780     Alteração para retornar CFOP para venda TV7, TV8 Conta e Ordem
    03/03/2010  Thiago Melo 126672
    08/09/2011  Pablo          142521    Alteração para utilizar a tributação do pedido, caso contrário será retornado a tributação atual.
    31/07/2012  Rodrigo Santos 168659    Alteração para buscar também o campo APLICAREDICMSSEMIPIBA.
    29/08/2012  Rodrigo Santos 171966    Alterada a procedure para buscar os dados de PAUTA de ICMS.
    20/03/2013  Marcos Garcia  192644    Inclusão do campo vncodicmsimplesnac e vnperbaseredsimplesnac
    08/04/2014  Lucas Lima     00875     Alteração para trazer o campo PCTRIBUT.SITTRIBUTSIMPLESNAC
    08/09/2014  Guilherme Freitas HIS.02459.2014  Inclusão do campo percacresicmspf_pi na consulta e no retorno.
    23/06/2015  Guilherme Freitas HIS.02114.2015  Incluso para buscar o CFOP para Clientes Simples Nacional.
    30/06/2015  Guilherme Freitas HIS.02219.2015  Incluso campo de % de diferimento para transferências.
    29/09/2015  Rafael Soares  HIS.03545.2015 alteração para obter o campo PCTRIBUT.GERARICMSLIVROFISCAL
    08/10/2015  Rafael Soares  HIS.03419.2015 Alteração para obter o campo o campo PCTRIBUT.CODCEST

    -----------------------------------------------------------------------------------------------------------*/
   IS
     vnCodFigVendaTriang    PCTRIBUT.CODFIGVENDATRIANGULAR%TYPE;
  BEGIN
    IF NVL(vncodst,0) = 0 THEN
      IF pusatributacaoporuf = 'S' THEN
        SELECT codst
          INTO vncodst
          FROM pctabtrib
         WHERE codprod = pcodprod
           AND ufdestino = pufcliente
           AND codfilialnf = pcodfilialnf;
      ELSE
        SELECT codst
          INTO vncodst
          FROM pctabpr
         WHERE codprod = pcodprod
           AND numregiao = pnumregiao;
      END IF; -- IF pusatributacaoporuf = 'S'
    END IF; -- IF vncodst = 0


    IF psVendaTriangular = 'S' THEN
      SELECT NVL(CODFIGVENDATRIANGULAR, 0)
        INTO vnCodFigVendaTriang
        FROM PCTRIBUT
       WHERE CODST = VNCODST;

      IF vnCodFigVendaTriang > 0 THEN
        vnCodSt := vnCodFigVendaTriang;
      END IF;

    END IF;

/*
VEN-9038 - Caso tivesse 'codclinf' no pedido e nao tivesse tabela de preco para o produto,
estava ocorrendo 'No Data Found'. Porem, esta validacao ja existe na Ferramentas
e na Package de Tributacao. Por isso, foi retirada daqui, pois a variável não é mais usada.

    SELECT NVL(vlultentmes, 0)
      INTO pnvlultentmes
      FROM pctabpr
     WHERE numregiao = pnumregiao
       AND codprod = pcodprod;
*/
    SELECT NVL(tri.codicmtab, 0),
           NVL(tri.sittribut, '000'),
           NVL(tri.sittributpf, NVL(sittribut, '000')),
           DECODE(pnumnotaconsig, NULL, NVL(tri.codicm, 0), 0),
           NVL(tri.percbasered, 0),
           NVL(tri.percbaseredst, 0),
           NVL(tri.percbaseredstfonte, 0),
           tri.percbaseredconsumidor,
           NVL(tri.perbaserednrpa, 0),
           tri.utilizapercbaseredpf,
           NVL(tri.pauta, 0),
           NVL(tri.iva, 0),
           NVL(tri.ivafonte, 0),
           tri.calcbcicmsnf,
           tri.codfiscal,
           tri.codfiscalinter,
           tri.codfiscalpf,
           tri.codfiscalinterpf,
           tri.codfiscalbonific,
           tri.codfiscalbonificinter,
           tri.codfiscaltransf,
           tri.codfiscaltransfinter,
           tri.codfiscalinternasc,
           tri.codfiscalinternascpf,
           tri.codfiscaldevcliinternasc,
           tri.codfiscaltransfinternasc,
           tri.codfiscalbonificinternasc,
           tri.codfiscaldevcliboninternasc,
           tri.codfiscaldevcliproentinternasc,
           tri.codfiscalprontaentinternasc,
           tri.codst,
           NVL(tri.codicmpf, 0),
           tri.codfiscalprontaent,
           tri.codfiscalprontaentinter,
           tri.codfiscalvendaconsig,
           tri.codfiscalvendaconsiginter,
           tri.codfiscalvendaconsiginternasc,
           tri.codfiscalvendaentfut,
           tri.codfiscalvendaentfutinter,
           tri.codfiscalsimpentfut,
           tri.codfiscalsimpentfutinter,
           tri.codfiscalmercconsig,
           tri.codfiscalmercconsiginter,
           tri.codfiscalmercconsiginternasc,
           tri.codfiscalvendaprontaent,
           tri.codfiscalvendaprontaentinter,
           tri.percacrescbasepfest,
           NVL(tri.tipocalculognre, 'P'),
           NVL(tri.codfiscalisentost, codfiscal),
           NVL(tri.codfiscalisentostinter, codfiscalinter),
           NVL(tri.codfiscalisentostinternasc, codfiscalinternasc),
           NVL(tri.sittributisentost, NVL(sittribut, '000')),
           NVL(tri.codfiscaltroca, tri.codfiscalbonific),
           NVL(tri.codfiscaltrocainter, tri.codfiscalbonificinter),
           NVL(tri.codfiscaltrocainternasc, tri.codfiscalbonificinternasc),
           tri.aliqstsaida,
           NVL(tri.aliqstsaidapf, tri.aliqstsaida),
           NVL(tri.sittributnrpa, NVL(sittribut, '000')),
           NVL(percivamex, 0),
           tri.aliqicms1transf,
           tri.aliqicms2transf,
           tri.ivatransf,
           tri.pautatransf,
           tri.percbaseredsttransf,
           tri.codicmtransf,
           tri.sittributtransf,
           tri.codicmprodrural,
           NVL(tri.perpautaicms, 0),
           NVL(tri.perpautaicmsinter, 0),
           NVL(tri.percbaseredadicional, 0),
           NVL(tri.percbaseredadicionalinter, 0),
           NVL(tri.descicmsreduzbaseicms, 'S'),
           NVL(tri.aliqicms1fonte, 0),
           NVL(tri.aliqicms2fonte, 0),
           'N',
           --nvl(tri.usacfopbnfparabrinde, 'S') -- Tarefa 66502
           NVL(tri.calcularicmssittribut060, 'S') calcularicmssittribut060,
           NVL(tri.codfiscaltv9, tri.codfiscalbonific),
           NVL(tri.codfiscalintertv9, tri.codfiscalbonificinter),
           NVL(tri.codfiscalinternasctv9, tri.codfiscalbonificinternasc),
           NVL(tri.peracrescimocusto, 0),
           NVL(tri.peracrescimofuncep, 0),
           NVL(tri.percbaseredtranfsaid, 100),
           tri.codfiscalconsig,
           tri.codfiscalconsiginter,
           tri.codfiscalconsiginternac,
           tri.percacrescbasepfint,
           NVL(tri.pagtonomedoremetente, 'N'),
           tri.codfiscaltriangular,
           tri.codfiscaltriangularinter,
           tri.codfiscaltriangularinternasc,
           NVL(tri.codfiscaltriangularpf, tri.codfiscaltriangular),
           NVL(tri.codfiscaltriangularinterpf, tri.codfiscaltriangularinter),
           NVL(tri.codfiscaltriangularinternascpf,
               tri.codfiscaltriangularinternasc),
           NVL(tri.perdifereimentoicms, 0),
           NVL(tri.codfiscalcontaordem, tri.codfiscalvendaentfut),
           NVL(tri.codfiscalcontaordeminter, tri.codfiscalvendaentfutinter),
           NVL(tri.codfiscalcontaordemsimpent, tri.codfiscalsimpentfut),
           NVL(tri.codfiscalcontaordemsimpentinte,
               tri.codfiscalsimpentfutinter),
           NVL(tri.zerarbaseicmsorgpubsuframa, 'N'),
           --Tarefa 126672
           tri.pagtonomedesttransf,
           tri.pagtonomeremettransf,
           tri.tipocalculognretransf,
           tri.pagtonomedocliente,
           NVL(tri.reduzbaseicmdecretomaranhao, 'N'),
           tri.sittributtv7,
           NVL(tri.utilizaparcadicfecp, 'N'),
           NVL(tri.aliqicmsfecp, 0),
           NVL(tri.isentaicmsbonific, 'N'),
           NVL(tri.sittributbonific, tri.sittribut),
           tri.sittributtv8,
           tri.codfiscalsuframa,
           tri.sittributsuframa,
           tri.codfiscalsuframainter,
           NVL(tri.usaisencaoicmsvp, 'S') usaisencaoicmsvp,
           NVL(tri.aliqicmstv9, NVL(tri.codicm, tri.codicmpf)) percicmstv9,
           NVL(tri.aplicaredicmssemipiba, 'N') aplicaredicmssemipiba,
           tri.sittributpautaicms,
           tri.sittributpautaicmspf, --Tarefa: 181175
           NVL(tri.vlpautaicmsinterest, 0),
           tri.codicmsimplesnac, --192644
           NVL(tri.perbaseredsimplesnac, 0), --192644
           NVL(tri.perctributos, 0),
           tri.codprodgnre, -- tarefa 206549
           TRI.SITTRIBUTORGAOPUB,
           NVL(tri.usavlultentmediobasest, 'N'),
           tri.Sittributsimplesnac, --HIS.00875.2013
           tri.percacresicmspf_pi,
           --HIS.04000.2014
           tri.sittribstfontepf,
           tri.sittribstfontepj,
           tri.codfiscalstfonteest,
           tri.codfiscalstfonteinterest,
           tri.codfiscalstfonteinternac,
           -- HIS.02114.2015
           tri.codfiscalsimplesnacest,
           tri.codfiscalsimplesnacnac,
           ------------------------
           --HIS.02571.2015
           NVL(tri.BNFNAOCALCULAICMS,'N'),
           NVL(tri.SITTRIBUTBNFTV1, NVL(sittribut, '000')),
           NVL(tri.geraricmslivrofiscal,'S'), --HIS.03545.2015
           tri.codcest, --HIS.03419.2015
           --HIS.02754.2015
           tri.usavalorultentbaseicms,
           tri.usavalorultentbaseicmsfonte,
           tri.sittributtv9,
           PERCPISRETORGPUB,
           PERCCOFINSRETORGPUB,
           PERCIRPJRETORGPUB,
           PERCCSLLRETORGPUB,
           PERCPISRETORGPUBEST,
           PERCCOFINSRETORGPUBEST,
           PERCIRPJRETORGPUBEST,
           PERCCSLLRETORGPUBEST,
           PERCPISRETORGPUBMUN,
           PERCCOFINSRETORGPUBMUN,
           PERCIRPJRETORGPUBMUN,
           PERCCSLLRETORGPUBMUN,
           SITTRIBUTTRIANG,
           NVL(PERDIFERIMENTOCMSTRANSF,0),
           NVL(tri.APLICAACRESPFJURIDICA, 'N'),
           NVL(TRI.CALCULAFECPCLIMEI, 'N'),
           nvl(agregadescst1, 'N'),
           tri.codfiscalisentostramo,
           tri.codfiscalisentostramointer,
           tri.sittributisentostramo,
           CalcBaseicmsMediaEnt,
           CalcularFECPISENTOie,
           CalcularFUNCEPISENTOie,
           MEINAOCALCDIF,
           sittributmei,
           CODFISCALISENTOSTCONT,
           CODFISCALISENTOSTCONTINTER,
           CODFISCALISENTOSTCONTINTERNASC,
           CODFISCALCONSUFINAL,
           CODFISCALCONSUFINALINTER,
           CODFISCALCONSUFINALINTERNASC,
           NVL(TRI.APLICAMVABASEICMS, 'N'),
           NVL(TRI.UTILIZAMOTORCALCULO, 'N'),
		   NVL(TRI.NAOPERSISTEIVAPCMOV,'N'),
           NVL(TRI.isentaicmssittribut041, 'N')
      INTO vncodicmtab,
           vssittribut,
           vssittributpf,
           vncodicm,
           vnpercbasered,
           vnpercbaseredst,
           vnpercbaseredstfonte,
           vnpercbaseredconsumidor,
           vnperbaserednrpa,
           vsutilizapercbaseredpf_trib,
           vnpauta,
           vniva,
           vnivafonte,
           vscalcbcicmsnf,
           vncfoest,
           vncfointer,
           vncfoestpf,
           vncfointerpf,
           vncfobonific,
           vncfobonificinter,
           vncfotransf,
           vncfotransfinter,
           vncfointernasc,
           vncfointernascpf,
           vncfodevcliinternasc,
           vncfotransfinternasc,
           vncfobonificinternasc,
           vncfodevcliboninternasc,
           vncfodevcliproentinternasc,
           vncfoprontaentinternasc,
           vncodst,
           vncodicmpf,
           vncfoprontaent,
           vncfoprontaentinter,
           vncfovendaconsig,
           vncfovendaconsiginter,
           vncfovendaconsiginternasc,
           vncfovendaentfut,
           vncfovendaentfutinter,
           vncfosimpentfut,
           vncfosimpentfutinter,
           vncfomercadoriaconsig,
           vncfomercadoriaconsiginter,
           vncfomercadoriaconsiginternasc,
           vncfovendaprontaent,
           vncfovendaprontaentinter,
           vnpercacrescbasepfest,
           vstipocalculognre,
           vncodfiscalisentost,
           vncodfiscalisentostinter,
           vncodfiscalisentostinternasc,
           vssittributisentost,
           vncodfiscaltroca,
           vncodfiscaltrocainter,
           vncodfiscaltrocainternasc,
           vnaliqstsaida,
           vnaliqstsaidapf,
           vssittributnrpa,
           vnpercivamex,
           vnaliqicms1transf,
           vnaliqicms2transf,
           vnivatransf,
           vnpautatransf,
           vnpercbaseredsttransf,
           vncodicmtransf,
           vssittributtransf,
           vncodicmprodrural,
           vnperpautaicms,
           vnperpautaicmsinter,
           vnpercbaseredadicional,
           vnpercbaseredadicionalinter,
           vsdescicmsreduzbaseicms,
           vnaliqicms1fonte,
           vnaliqicms2fonte,
           vsusacfopbnfparabrinde,
           vscalcularicmssittribut060,
           vscodfiscaltv9,
           vscodfiscalintertv9,
           vscodfiscalinternasctv9,
           vnperacrescimocusto,
           vnperacrescimofuncep,
           vnpercbaseredtranfsaid,
           vncodfiscalconsig,
           vncodfiscalconsiginter,
           vncodfiscalconsiginternac,
           vnpercacrescbasepfint,
           vspagtonomedoremetente,
           vncodfiscaltriangular,
           vncodfiscaltriangularinter,
           vncodfiscaltriangularinternasc,
           vncfoptriangularpf,
           vncfoptriangularinterpf,
           vncfoptriangularinternascpf,
           vnperdifereimentoicms,
           vncfopcontaordem,
           vncfopcontaordeminter,
           vncfopcontaordemsimpent,
           vncfopcontaordemsimpentinte,
           vszerarbaseicmsorgpubsuframa,
           vspagtonomedesttransf,
           vspagtonomeremettransf,
           vstipocalculognretransf,
           vspagtonomedocliente,
           psreduzbaseicmdecretomaranhao,
           pssittributtv7,
           psutilizaparcadicfecp,
           pnaliqicmsfecp,
           psisentaicmsbonific,
           pssittributbonific,
           pssittributtv8,
           pncodfiscalsuframa,
           pssittributsuframa,
           pncodfiscalsuframainter,
           psusaisencaoicmsvp,
           pdaliqicmstv9,
           paplicaredicmssemipiba,
           psittributpautaicms,
           psittributpautaicmspf, --Tarefa: 181175
           pvlpautaicmsinterest,
           vncodicmsimplesnac,
           vnperbaseredsimplesnac,
           vnperctributos,
           vncodprodgnre,
           pssittributorgaopub,
           psusavlultentmediobasest,
           vssittribsimplesnac, --HIS.00875.2013
           pnpercacresicmspf_pi,
           --HIS.04000.2014
           pssittribstfontepf,
           pssittribstfontepj,
           pncodfiscalstfonteest,
           pncodfiscalstfonteinterest,
           pncodfiscalstfonteinternac,
           --HIS.02114.2015
           pncodfiscalsimplesnacest,
           pncodfiscalsimplesnacinterest,
           -------
           psBNFNAOCALCULAICMS,
           psSITTRIBUTBNFTV1,
           pngeraricmslivrofiscal, --HIS.03545.2015
           pscodcest, --HIS.03419.2015
           --HIS.02754.2015
           psUsaValorultEntbaseICMS,
           psUsaValorultEntbaseICMSTONTE,
           pssittributtv9,
           pPERCPISRETORGPUB,
           pPERCCOFINSRETORGPUB,
           pPERCIRPJRETORGPUB,
           pPERCCSLLRETORGPUB,
           pPERCPISRETORGPUBEST,
           pPERCCOFINSRETORGPUBEST,
           pPERCIRPJRETORGPUBEST,
           pPERCCSLLRETORGPUBEST,
           pPERCPISRETORGPUBMUN,
           pPERCCOFINSRETORGPUBMUN,
           pPERCIRPJRETORGPUBMUN,
           pPERCCSLLRETORGPUBMUN,
           pSITTRIBUTTRIANG,
           pnperdiferimentoicmstransf,
           pAPLICAACRESPFJURIDICA,
           pCalculaFECPCLIMEI,
           pagregadescst1,
           pcodfiscalisentostramo,
           pcodfiscalisentostramointer,
           psittributisentostramo,
           psCalcBaseicmsMediaEnt,
           psCalcularFECPISENTOie,
           PsCalcularFUNCEPISENTOie,
           psMEINAOCALCDIF,
           pssittributmei,
           pnCODFISCALISENTOSTCONT,
           pnCODFISCALISENTOSTCONTINTER,
           pnCODFISCALISENSTCONTINTERNASC,
           pnCODFISCALCONSUFINAL,
           pnCODFISCALCONSUFINALINTER,
           pnCODFISCALCONSUFINALINTERNASC,
           psAplicaMVABaseIcms,
           psUTILIZAMOTORCALCULO,
		   psNAOPERSISTEIVAPCMOV,
           psisentaicmssittribut041
      FROM pctribut tri
     WHERE tri.codst = vncodst;

      ----- CASO O CLIENTE SEJA PESSOA FÍSICA SEGUE A CONTINGÊNCIA
      ----- Tarefa: 4570.073264.2014 - Luciano Lima
      IF (ppessoafisica) THEN
          SELECT NVL(tri.sittributisentost, NVL(sittributpf, '000')),
                 NVL(tri.sittributnrpa, NVL(sittributpf, '000')),
                 NVL(tri.sittributbonific, tri.sittributpf)
            INTO vssittributisentost,
                 vssittributnrpa,
                 pssittributbonific
            FROM pctribut tri
           WHERE tri.codst = vncodst;
      END IF;
      ---------------------------------------------------

    IF vstipocalculognre <> 'C' THEN
      vspagtonomedoremetente := 'N';
    END IF;

  EXCEPTION
    WHEN OTHERS THEN

      pmensagem := SQLCODE || '-' || SQLERRM ||
                   ' -12- Selecao da tributacao do produto: ' || pcodprod || ' - '|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

  END buscartributacao;

  PROCEDURE buscardadospcprodut(pncodprod                      IN pcprodut.codprod%TYPE,
                                pscodfilialnf                  IN pcpedc.codfilialnf%TYPE,
                                pssulframa_client              IN pcclient.sulframa%TYPE,
                                vncodepto                      IN OUT pcprodut.codepto%TYPE,
                                vncodsec                       IN OUT pcprodut.codsec%TYPE,
                                vc2descricao                   IN OUT pcprodut.descricao%TYPE,
                                vc2classe                      IN OUT pcprodut.classe%TYPE,
                                vnpesobruto                    IN OUT pcprodut.pesobruto%TYPE,
                                vnpesoliq                      IN OUT pcprodut.pesoliq%TYPE,
                                vnvolume                       IN OUT pcprodut.volume%TYPE,
                                vncodfornecedor                IN OUT pcprodut.codfornec%TYPE,
                                vnperpis                       IN OUT pcprodut.perpis%TYPE,
                                vstipomerc_prod                IN OUT pcprodut.tipomerc%TYPE,
                                vscoddistrib_prod              IN OUT pcfornec.coddistrib%TYPE,
                                vsconfaz                       IN OUT pcprodut.confaz%TYPE,
                                vstipoestoque                  IN OUT pcprodut.tipoestoque%TYPE,
                                vnpercofins                    IN OUT pcprodut.percofins%TYPE,
                                vsgeraicmslivrofiscal          IN OUT pcprodfilial.geraicmslivrofiscal%TYPE,
                                vncustofornec                  IN OUT pcprodut.custofornec%TYPE,
                                vscompraconsignado             IN OUT pcprodut.compraconsignado%TYPE,
                                vnpesoembalagem                IN OUT pcprodut.pesoembalagem%TYPE,
                                vnpisretido                    IN OUT pcprodut.pisretido%TYPE,
                                vncofinsretido                 IN OUT pcprodut.cofinsretido%TYPE,
                                vnirretido                     IN OUT pcprodut.irretido%TYPE,
                                vncsllretido                   IN OUT pcprodut.csllretido%TYPE,
                                vsextipi                       IN OUT pcprodut.extipi%TYPE,
                                vnvalorpislitragem_produt      IN OUT pcprodut.valorpislitragem%TYPE,
                                vnvalorcofinslitragem_produt   IN OUT pcprodut.valorcofinslitragem%TYPE,
                                vnbasepiscofinslitragem_produt IN OUT pcprodut.basepiscofinslitragem%TYPE,
                                vsimportado_produt             IN OUT pcprodut.importado%TYPE,
                                picondvenda                    IN OUT pcpedc.condvenda%TYPE,
                                VSCONTROLANUMSERIE             IN OUT pcprodfilial.controlanumserie%TYPE,--211613
                                VSPERCCARGEFETIV               IN OUT pcprodfilial.perccargefetiv%TYPE, --HIS.01889.2015
                                vnPercAcrecimoBaseIPI          IN OUT pcprodfilial.PERACRESBASEIPI%TYPE, --HIS.02641.2017
                                vsembalagem                    IN OUT PCPRODUT.EMBALAGEM%TYPE, --HIS.04349.2015
                                vnDV                           IN OUT PCPRODUT.DV%TYPE,        --HIS.04349.2015
                                psBONIFIC                      IN PCPEDI.BONIFIC%TYPE, --HIS.02571.2015
                                pmensagem                      IN OUT VARCHAR)
  /******************************************************************************************
    -> PROGRAMA UTILIZADO PELA PROCEDURE DE FATURAMENTO
    -> Versao : Pacote
    *************************************************************************************************************
     Data         Autor    Tarefa    Descricao
    *************************************************************************************************************
    24/11/2006    Pablo    35671     Bloco colocado em Procedure para resolver problema "Program too large"
    19/04/2007    pABLO    41644     Procedure passa a retornar PCPRODUT.TipoEstoque
    17/02/2009    Pablo    77496     Alteração para retornar os percentuais de PIS\Confins
    15/05/2009    Pablo    84520      pcprodfilial.geraicmslivrofiscal
    10/06/2009    Pablo    84296     Alteração para retornar o PCPRODUT.CustoFornec
    10/06/2009    Pablo    86115     Alteração para passar a validar o parâmetro PCConsum.UsaPISConfinsPorFilial
    03/08/2009    Pablo    89811     Alteração para validar o parâmetro PCProdFilial.geraicmslivrofiscal independente de
                                     PCConsum.UsaPISConfinsPorFilial
    18/03/2010    Pablo   103332     Alteração para tratar o campo PCProdut.pesoembalagem com NVL para pcprodut.pesobruto
                                     para não gerar erro na totalização
    27/07/2010    Pablo   111491     Alteração para retornar PCProdut.ExTipi
    18/10/2010    Pablo   118215     Alteração para retornar informações numéricas com NVL
    13/12/2010    Pablo   122177     Alteração para não destacar os % de PIS e COFINS caso o produto seja importado e o cliente suframado
    26/01/2011    Pablo   125552     Alteração para passar a validar o parâmetro PCParamFilial.Nome = 'USAPISCOFINSPORFILIAL'
    12/08/2011    Thiago  136100     Alterada procedimento para validação do retorno do parâmetro "vsgeraicmslivrofiscal"
    23/05/2014    Guilherme 211613   Incluido a busca se ele utiliza ou controle por numero de série.
    *************************************************************************************************************/
   IS
    vicontador              NUMBER;
    vsusapiscofinsporfilial VARCHAR2(1);
  BEGIN
    SELECT p.codepto,
           p.codsec,
           p.descricao,
           p.classe,
           NVL(p.pesobruto, 0),
           NVL(p.pesoliq, 0),
           NVL(p.volume, 0),
           p.codfornec,
           NVL(p.perpis, 0),
           NVL(p.tipomerc, ' '),
           NVL(f.coddistrib, ' '),
           NVL(p.confaz, 'N'),
           NVL(p.tipoestoque, 'PA'),
           NVL(p.custofornec, 0),
           NVL(p.compraconsignado, 'N'),
           NVL(p.pesoembalagem, p.pesobruto),
           NVL(p.pisretido, 0),
           NVL(p.cofinsretido, 0),
           NVL(p.irretido, 0),
           NVL(p.csllretido, 0),
           p.extipi,
           NVL(valorpislitragem, 0),
           NVL(valorcofinslitragem, 0),
           NVL(basepiscofinslitragem, 0),
           NVL(importado, 'N'),
           P.EMBALAGEM,
           P.DV
      INTO vncodepto,
           vncodsec,
           vc2descricao,
           vc2classe,
           vnpesobruto,
           vnpesoliq,
           vnvolume,
           vncodfornecedor,
           vnperpis,
           vstipomerc_prod,
           vscoddistrib_prod,
           vsconfaz,
           vstipoestoque,
           vncustofornec,
           vscompraconsignado,
           vnpesoembalagem,
           vnpisretido,
           vncofinsretido,
           vnirretido,
           vncsllretido,
           vsextipi,
           vnvalorpislitragem_produt,
           vnvalorcofinslitragem_produt,
           vnbasepiscofinslitragem_produt,
           vsimportado_produt,
           vsembalagem,
           vnDV
      FROM pcprodut p, pcfornec f
     WHERE p.codprod = pncodprod
       AND p.codfornec = f.codfornec(+)
       AND ROWNUM = 1;


     SELECT NVL(PCPRODFILIAL.CONTROLANUMSERIE, 'N'), PCPRODFILIAL.PERCCARGEFETIV, PCPRODFILIAL.Peracresbaseipi
      INTO VSCONTROLANUMSERIE, VSPERCCARGEFETIV, vnPercAcrecimoBaseIPI
      FROM PCPRODFILIAL
     WHERE PCPRODFILIAL.CODPROD = PNCODPROD
       AND PCPRODFILIAL.CODFILIAL = pscodfilialnf;

    vsusapiscofinsporfilial := FERRAMENTAS.PARAMETROS.getVALORALFA('CON_USAPISCOFINSPORFILIAL',
                                                                   pscodfilialnf);

    IF (vsusapiscofinsporfilial IS NULL) THEN

      vsusapiscofinsporfilial := FERRAMENTAS.PARAMETROS.getVALORALFA('CON_USAPISCOFINSPORFILIAL',
                                                                     '99');

    END IF;

    -- Tarefa 125552
    IF vsusapiscofinsporfilial = 'N' THEN
      SELECT NVL(perpis, 0), NVL(percofins, 0)
        INTO vnperpis, vnpercofins
        FROM pcprodut
       WHERE codprod = pncodprod;
    ELSE
      SELECT COUNT(*)
        INTO vicontador
        FROM pcprodfilial
       WHERE codprod = pncodprod
         AND codfilial = pscodfilialnf;

      IF vicontador > 0 THEN
        SELECT NVL(perpis, 0), NVL(percofins, 0)
          INTO vnperpis, vnpercofins
          FROM pcprodfilial
         WHERE codprod = pncodprod
           AND codfilial = pscodfilialnf;
      END IF;
    END IF; -- IF vsUsaPISCofinsPorFilial = 'N'

    -- Tarefa 122177
    IF (pssulframa_client IS NOT NULL) AND
       (vsimportado_produt IN ('S', 'D'))
       OR (psBONIFIC <> 'N') --HIS.02571.2015
    THEN
      vnperpis                       := 0;
      vnpercofins                    := 0;
      vnvalorpislitragem_produt      := 0;
      vnvalorcofinslitragem_produt   := 0;
      vnbasepiscofinslitragem_produt := 0;
    END IF;

    --Tarefa 136100
    SELECT COUNT(*)
      INTO vicontador
      FROM pcgeraicmslivrofiscalsaida
     WHERE codprod = pncodprod
       AND codfilial = pscodfilialnf
       AND condvenda = picondvenda;

    IF vicontador > 0 THEN
      SELECT pcgeraicmslivrofiscalsaida.geraicmslivrofiscal
        INTO vsgeraicmslivrofiscal
        FROM pcgeraicmslivrofiscalsaida
       WHERE codprod = pncodprod
         AND codfilial = pscodfilialnf
         AND condvenda = picondvenda;
    ELSE
      -- Fim tarefa 122177
      SELECT COUNT(*)
        INTO vicontador
        FROM pcprodfilial
       WHERE codprod = pncodprod
         AND codfilial = pscodfilialnf;

      IF vicontador = 0 THEN
        vsgeraicmslivrofiscal := 'S';
      ELSE
        SELECT NVL(geraicmslivrofiscal, 'S')
          INTO vsgeraicmslivrofiscal
          FROM pcprodfilial
         WHERE codprod = pncodprod
           AND codfilial = pscodfilialnf;
      END IF;
    END IF; --vicontador pcgeraicmslivrofiscalsaida
    --Fim tarefa 136100
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      pmensagem := '-9.0- Verifique se existe registro do Produto de código:' || pncodprod || 'para a Filial:' ||
                    pscodfilialnf || '(Rotina: 238, Tabela: PCPRODFILIAL). '|| ' - '|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    WHEN OTHERS THEN
      pmensagem := SQLCODE || ' - ' || SQLERRM ||
                   ' -9.1- Selecao dos dados do produto. '|| ' - '|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
  END buscardadospcprodut;

  PROCEDURE validarinserircobranca(pscodcob   IN pccob.codcob%TYPE,
                                   psmensagem IN OUT VARCHAR2)
   IS
    vicontador NUMBER;
  BEGIN
    vicontador := 0;

    SELECT COUNT(*) INTO vicontador FROM pccob WHERE codcob = pscodcob;

    IF vicontador = 0 THEN
      INSERT INTO pccob
        (codcob, cobranca, pagcomissao)
      VALUES
        (pscodcob,
         DECODE(pscodcob,
                'CH',
                'CHEQUE',
                'SENT',
                'COBRANCA DE ENVIO',
                'BNF',
                'BONIFICACAO',
                'BNFT',
                'BONIFICACAO DE TROCA',
                'CRED',
                'CREDITO',
                'DH',
                'DINHEIRO EM TRANSITO'),
         'N');
    END IF;

    PSMENSAGEM := 'OK';

  EXCEPTION
    WHEN OTHERS THEN
      psmensagem := 'Não foi possível gerar registro na tabela de cobrança.' ||
                    'Erro: ' || SQLCODE || '-' || SQLERRM || ' - '|| DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
  END validarinserircobranca;

  PROCEDURE ATUALIZARCUSTOFINANCEIRO(VALOR IN NUMBER) IS
  BEGIN
    BEGIN
      UPDATE PCEST SET CUSTOFIN = Nvl(CUSTOFIN, 0) * nvl(valor, 0);
      UPDATE PCCONSUM SET DTPROXATU = NVL(DTPROXATU, TRUNC(SYSDATE)) + NUMDIASATU;
      COMMIT;
      --MENSAGEM := 'Custo Financeiro Atualizado com Sucesso';
    EXCEPTION
      WHEN others THEN
        --MENSAGEM := 'Erro ao Atualizar Custo Financeiro:' || SQLCODE || '-' || SQLERRM;
        RAISE_APPLICATION_ERROR(20000,'Erro ao atualizar custo financeiro');
        ROLLBACK;
    END;
  END;

  FUNCTION retorna_prazomedido_plpagfixo(pcodplpag IN pcplpag.codplpag%TYPE)
    RETURN NUMBER IS
    vidatavenc          INT;
    pcarencia           pcplpag.diascarencia%TYPE;
    diafixo             pcplpag.diafixo%TYPE;
    pnumparcelas        pcplpag.numeroparcelasdiafixo%TYPE;
    vddata_vencimento   DATE;
    vddata_venc_inicial DATE;
    vb_diavalido        BOOLEAN;
    vnteste_diafixo     NUMBER(1);
  BEGIN
    BEGIN
      SELECT NVL(pcplpag.diascarencia, 0),
             NVL(pcplpag.diafixo, 1),
             NVL(pcplpag.numeroparcelasdiafixo, 1)
        INTO pcarencia, diafixo, pnumparcelas
        FROM pcplpag
       WHERE pcplpag.codplpag = pcodplpag;
       EXCEPTION
      WHEN others THEN
        RETURN 0;
    END;

    vidatavenc := 0;

    FOR vi IN 1 .. pnumparcelas LOOP
      vnteste_diafixo := 0;
      vb_diavalido := FALSE;
      WHILE (NOT vb_diavalido) LOOP
        <<TESTE_DATA>>
        WHILE vnteste_diafixo = 0 LOOP
          BEGIN
            SELECT TO_DATE(TO_CHAR(diafixo) || '/' ||
                         TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE), vidatavenc),
                                 'MM/YYYY'),
                         'DD/MM/YYYY')
            INTO vddata_vencimento
            FROM DUAL;

            IF vi = 1 THEN
              IF (TRUNC(SYSDATE) + pcarencia) >= vddata_vencimento THEN
                vddata_vencimento := ADD_MONTHS(vddata_vencimento, 1);

                IF (TRUNC(SYSDATE) + pcarencia) >= vddata_vencimento THEN
                  -- Tarefa 150594
                  vddata_vencimento := ADD_MONTHS(vddata_vencimento, 1);
                END IF;

                vidatavenc := vidatavenc + 2;
              ELSE
                vidatavenc := vidatavenc + 1;
              END IF;
            ELSE
              vidatavenc := vidatavenc + 1;
            END IF;
            IF vi = 1 THEN
              vddata_venc_inicial := vddata_vencimento;
            END IF;
            vb_diavalido := TRUE;
            vnteste_diafixo := 1;
          EXCEPTION
            WHEN OTHERS THEN
            diafixo := diafixo - 1;
            GOTO TESTE_DATA;
           END;

          END LOOP;

      END LOOP;

    END LOOP;
    RETURN TRUNC((vddata_vencimento - TRUNC(SYSDATE)) / pnumparcelas);
  END;


PROCEDURE CALCULARGIRODIA(DATA1                IN DATE,
                          DATA2                IN DATE,
                          MENSAGEM             OUT VARCHAR2,
                          PCODPROD             IN NUMBER DEFAULT 0,
                          PFILIAL              IN VARCHAR2 DEFAULT '-1',
                          PTIPOCALCULODIAS     IN NUMBER) IS

    vTIPOCALCGIRODIA       PCCONSUM.TIPOCALCGIRODIA%TYPE;
    vTIPOPERIODOGIRODIA    PCCONSUM.TIPOPERIODOGIRODIA%TYPE;
    vTIPOVALORGIRODIA      PCCONSUM.TIPOVALORGIRODIA%TYPE;
    vNUMDIASUTEISTRIMESTRE PCCONSUM.NUMDIASUTEISTRIMESTRE%TYPE;
    vNUMDIASUTEISSEMANA    PCCONSUM.NUMDIASUTEISSEMANA%TYPE;
    vNUMDIASTRI            NUMBER;
    vnDtPrimCompra         DATE;
    vnNumDiasTri           NUMBER;
    vnNumDiasMesAtual      NUMBER;
    vDATA                  DATE;
    vDIA                   NUMBER;
    vnQtDias               NUMBER;
    vQTDIASSEMEST          NUMBER;
    vnDiasGiro             NUMBER;
    vnQtGiroDia            NUMBER;
    vLock                  NUMBER;
    vDATA1                 DATE;
    vDATA2                 DATE;
	
	CURSOR BLOQUEIA_ESTOQUE_GIRO
    IS SELECT CODPROD
         FROM PCEST
        WHERE PCEST.CODPROD = DECODE(nvl(PCODPROD,0), 0, PCEST.CODPROD, PCODPROD)
         AND (PCEST.CODFILIAL = DECODE(NVL(PFILIAL,'-1'), '-1', PCEST.CODFILIAL, PFILIAL)
              or '99' = NVL(PFILIAL,'-1'))
          FOR UPDATE;

  BEGIN
    if (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('MODELOCALCULOGIRODIA', '99','P') = 'P') then

      SELECT NVL(TIPOCALCGIRODIA, 'M'),
             TIPOPERIODOGIRODIA,
             TIPOVALORGIRODIA,
             NVL(NUMDIASUTEISTRIMESTRE, 1),
             NVL(NUMDIASUTEISSEMANA, 1)

        INTO vTIPOCALCGIRODIA,
             vTIPOPERIODOGIRODIA,
             vTIPOVALORGIRODIA,
             vNUMDIASUTEISTRIMESTRE,
             vNUMDIASUTEISSEMANA
        FROM PCCONSUM;

      delete from pclogrecalcgirodia where trunc(data) = trunc(sysdate)
	    and (pclogrecalcgirodia.CODFILIAL = DECODE(NVL(PFILIAL,'-1'), '-1', pclogrecalcgirodia.CODFILIAL, PFILIAL)
                or '99' = NVL(PFILIAL,'-1')); -- Limpa Logs de erros de processamentos realizados no dia / filial atual

      IF vTipoCalcGiroDia = 'E' THEN
	    OPEN BLOQUEIA_ESTOQUE_GIRO;
		
        UPDATE PCEST
           SET QTGIRODIA  = 0
         WHERE PCEST.CODPROD = DECODE(nvl(PCODPROD,0), 0, PCEST.CODPROD, PCODPROD)
           AND (PCEST.CODFILIAL = DECODE(NVL(PFILIAL,'-1'), '-1', PCEST.CODFILIAL, PFILIAL)
                or '99' = NVL(PFILIAL,'-1')
           ) AND QTGIRODIA  > 0 ;
		   
		CLOSE BLOQUEIA_ESTOQUE_GIRO;
		COMMIT;

        FOR registro IN (SELECT PCEST.CODPROD, PCEST.CODFILIAL, ROWID
                           FROM PCEST
                          WHERE PCEST.CODPROD   = DECODE(nvl(PCODPROD,0), 0, PCEST.CODPROD, PCODPROD)
                            AND (PCEST.CODFILIAL = DECODE(NVL(PFILIAL,'-1'), '-1', PCEST.CODFILIAL, PFILIAL)
                            or '99' = NVL(PFILIAL,'-1')
                                )  AND (QTVENDMES > 0 or QTVENDMES1 > 0 or QTVENDMES2 > 0 or QTVENDMES3 > 0)
                          ORDER BY PCEST.CODPROD, PCEST.CODFILIAL) LOOP
          BEGIN
            -- Buscar dias de estoque no período
            vDATA2 := TRUNC(SYSDATE, 'MONTH')-1;

            IF UPPER(vTIPOPERIODOGIRODIA) = 'B' THEN
               vDATA1 := trunc(add_months(sysdate,-2), 'MONTH');
            ELSIF UPPER(vTIPOPERIODOGIRODIA) = 'T' THEN
               vDATA1 := trunc(add_months(sysdate,-3), 'MONTH');
            ELSIF UPPER(vTIPOPERIODOGIRODIA) = 'Q' THEN
               vDATA1 := trunc(add_months(sysdate,-4), 'MONTH');
            ELSIF UPPER(vTIPOPERIODOGIRODIA) = 'S' THEN
               vDATA1 := trunc(add_months(sysdate,-6), 'MONTH');
            ELSIF UPPER(vTIPOPERIODOGIRODIA) = 'A' THEN
               vDATA1 := trunc(add_months(sysdate,-12), 'MONTH');
            END IF;

            /*
               Autor: Deyvid Costa
               Solicitação: 1812.098640.2015
               Data: 10/09/2015
               Descrição: Ajustado para observar o cadastro de DIAS UTEIS e o parâmetro "FIL_USADIAUTILFILIAL".
                          Modificação foi feita para melhorar a performance do select que antes utilizava a cláusula TO_CHAR, assim,
                          o índice não era executado completamente gerando lentidão excessiva.
            */

            IF (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_USADIAUTILFILIAL', registro.CODFILIAL,'N') = 'S') THEN
              SELECT COUNT(DISTINCT(H.DATA))    -- PCDIASUTEIS - ROTINA 589
                INTO vNUMDIASTRI
                FROM PCHISTEST H, PCDIASUTEIS D
               WHERE H.DATA BETWEEN vDATA1 AND vDATA2
                 AND H.CODPROD = registro.CODPROD
                 AND H.CODFILIAL = registro.CODFILIAL
                 AND H.DATA      = D.DATA
                 AND H.CODFILIAL = D.CODFILIAL
                 AND NVL(H.QTESTGER, 0) > 0
                 AND D.DIAVENDAS = 'S';
              --AND TO_CHAR(DATA, 'D') NOT IN (1, 7);
            ELSE
              SELECT COUNT(DISTINCT(H.DATA))      -- PCDATAS - ROTINA 309
                INTO vNUMDIASTRI
                FROM PCHISTEST H, PCDATAS D
               WHERE H.DATA BETWEEN vDATA1 AND vDATA2
                 AND H.CODPROD = registro.CODPROD
                 AND H.CODFILIAL = registro.CODFILIAL
                 AND H.DATA = D.DATA
                 AND NVL(H.QTESTGER, 0) > 0
                 AND D.DIAUTIL = 'S';
              --AND TO_CHAR(DATA, 'D') NOT IN (1, 7);
            END IF;

            -- Se número de dias de estoque do trimestre for zero -> mover 1
            IF vNUMDIASTRI = 0 THEN
              vnNumDiasTri := 1;
            ELSE
              vnNumDiasTri := vNUMDIASTRI;
            END IF;

            -- Cálculo do percentual de evolução - conforme opção M

              -- Lock do registro atual
              SELECT 1 INTO vLock FROM PCEST WHERE ROWID = registro.rowid FOR UPDATE;

              UPDATE PCEST
                 SET QTGIRODIA         = (CASE WHEN vTIPOVALORGIRODIA = 'A' THEN ROUND(((NVL(QTVENDMES1, 0) + NVL(QTVENDMES2, 0) + NVL(QTVENDMES3, 0)) / (vnNumDiasTri))) WHEN vTIPOVALORGIRODIA = 'T' THEN TRUNC(((NVL(QTVENDMES1, 0) + NVL(QTVENDMES2, 0) + NVL(QTVENDMES3, 0)) / (vnNumDiasTri))) ELSE((NVL(QTVENDMES1, 0) + NVL(QTVENDMES2, 0) + NVL(QTVENDMES3, 0)) / (vnNumDiasTri)) END),
                     PERCEVOLUCAOVENDA = DECODE(NVL(QTVENDMES2, 0),
                                                0,
                                                100,
                                                (((NVL(QTVENDMES1, 0) /
                                                NVL(QTVENDMES2, 0)) - 1) * 100))
               WHERE CODPROD = registro.CODPROD
                 AND CODFILIAL = registro.CODFILIAL;
          EXCEPTION
            WHEN others THEN

              MENSAGEM := 'Erro ao atualizar giro semanal através do número de dias de estoque:' ||
                          SQLCODE || '-' || SQLERRM;

              INSERT INTO PCLOGRECALCGIRODIA (CODFILIAL, CODPROD, DATA, OBSERVACAO)
                                      VALUES (registro.codfilial
                                             ,registro.codprod
                                             ,SYSDATE
                                             ,MENSAGEM);
          END;

          COMMIT;

        END LOOP;
      ELSIF vTipoCalcGiroDia = 'M' THEN

         OPEN BLOQUEIA_ESTOQUE_GIRO;
		 
		 UPDATE PCEST
            SET QTGIRODIA  = 0
          WHERE PCEST.CODPROD = DECODE(nvl(PCODPROD,0), 0, PCEST.CODPROD, PCODPROD)
            AND (PCEST.CODFILIAL = DECODE(NVL(PFILIAL,'-1'), '-1', PCEST.CODFILIAL, PFILIAL)
                 or '99' = NVL(PFILIAL,'-1')
            ) AND QTGIRODIA  > 0 ;
			
		CLOSE BLOQUEIA_ESTOQUE_GIRO;
		COMMIT;

        FOR registro IN (SELECT PCEST.CODPROD, PCEST.CODFILIAL, ROWID
                           FROM PCEST
                          WHERE PCEST.CODPROD = DECODE(nvl(PCODPROD,0), 0, PCEST.CODPROD, PCODPROD)
                            AND (PCEST.CODFILIAL = DECODE(NVL(PFILIAL,'-1'), '-1', PCEST.CODFILIAL, PFILIAL)
                                  or '99' = NVL(PFILIAL,'-1')
                                 )   AND (QTVENDMES > 0 or QTVENDMES1 > 0 or QTVENDMES2 > 0 or QTVENDMES3 > 0)

                            ) LOOP

          BEGIN
            -- Lock do registro atual
            SELECT 1 INTO vLock FROM PCEST WHERE ROWID = registro.rowid FOR UPDATE;

            UPDATE PCEST
               SET QTGIRODIA         = (CASE WHEN vTIPOVALORGIRODIA = 'A' THEN ROUND(((NVL(QTVENDMES1, 0) + NVL(QTVENDMES2, 0) + NVL(QTVENDMES3, 0)) / vNUMDIASUTEISTRIMESTRE)) WHEN vTIPOVALORGIRODIA = 'T' THEN TRUNC(((NVL(QTVENDMES1, 0) + NVL(QTVENDMES2, 0) + NVL(QTVENDMES3, 0)) / vNUMDIASUTEISTRIMESTRE)) ELSE((NVL(QTVENDMES1, 0) + NVL(QTVENDMES2, 0) + NVL(QTVENDMES3, 0)) / vNUMDIASUTEISTRIMESTRE) END),
                   PERCEVOLUCAOVENDA = DECODE(NVL(QTVENDMES2, 0),
                                              0,
                                              100,
                                              (((NVL(QTVENDMES1, 0) /
                                              NVL(QTVENDMES2, 0)) - 1) * 100))
             WHERE ROWID = registro.ROWID;
          EXCEPTION
            WHEN others THEN

              MENSAGEM := 'Erro ao atualizar giro semanal por dias úteis do mês:' ||
                          SQLCODE || '-' || SQLERRM;

              INSERT INTO PCLOGRECALCGIRODIA (CODFILIAL, CODPROD, DATA, OBSERVACAO)
                                      VALUES (registro.codfilial
                                             ,registro.codprod
                                             ,SYSDATE
                                             ,MENSAGEM);
          END;

          COMMIT;

        END LOOP;
      ELSIF vTipoCalcGiroDia = 'A' THEN
        FOR registro IN (SELECT PCEST.CODPROD, PCEST.CODFILIAL, ROWID
                           FROM PCEST
                          WHERE PCEST.CODPROD   = DECODE(nvl(PCODPROD,0), 0, PCEST.CODPROD, PCODPROD)
                            AND (PCEST.CODFILIAL = DECODE(NVL(PFILIAL,'-1'), '-1', PCEST.CODFILIAL, PFILIAL)
                                 or '99' = NVL(PFILIAL,'-1')
                                 )
                            ) LOOP

          BEGIN
            -- Lock do registro atual
            SELECT 1 INTO vLock FROM PCEST WHERE ROWID = registro.rowid FOR UPDATE;

            UPDATE PCEST
               SET QTGIRODIA = (CASE WHEN vTIPOVALORGIRODIA = 'A' THEN ROUND(((((NVL(QTVENDMES1, 0) + NVL(QTVENDMES2, 0) + NVL(QTVENDMES3, 0)) / vNUMDIASUTEISTRIMESTRE) + ((NVL(QTVENDSEMANA1, 0) / vNUMDIASUTEISSEMANA + NVL(QTVENDSEMANA2, 0) / vNUMDIASUTEISSEMANA + NVL(QTVENDSEMANA3, 0) / vNUMDIASUTEISSEMANA)/3))) / 2) WHEN vTIPOVALORGIRODIA = 'T' THEN TRUNC(((((NVL(QTVENDMES1, 0) + NVL(QTVENDMES2, 0) + NVL(QTVENDMES3, 0)) / vNUMDIASUTEISTRIMESTRE) + ((NVL(QTVENDSEMANA1, 0) / vNUMDIASUTEISSEMANA + NVL(QTVENDSEMANA2, 0) / vNUMDIASUTEISSEMANA + NVL(QTVENDSEMANA3, 0) / vNUMDIASUTEISSEMANA)/3))) / 2) ELSE(((NVL(QTVENDMES1, 0) + NVL(QTVENDMES2, 0) + NVL(QTVENDMES3, 0)) / vNUMDIASUTEISTRIMESTRE) + ((NVL(QTVENDSEMANA1, 0) / vNUMDIASUTEISSEMANA + NVL(QTVENDSEMANA2, 0) / vNUMDIASUTEISSEMANA + NVL(QTVENDSEMANA3, 0) / vNUMDIASUTEISSEMANA)/3)) / 2 END)
             WHERE ROWID = registro.ROWID;
          EXCEPTION
            WHEN others THEN

              MENSAGEM := 'Erro ao atualizar giro semanal por dias úteis do mês e da semana:' ||
                          SQLCODE || '-' || SQLERRM;

              INSERT INTO PCLOGRECALCGIRODIA (CODFILIAL, CODPROD, DATA, OBSERVACAO)
                                      VALUES (registro.codfilial
                                             ,registro.codprod
                                             ,SYSDATE
                                             ,MENSAGEM);
          END;

          BEGIN
            UPDATE PCEST
               SET PERCEVOLUCAOVENDA = (((NVL(QTVENDSEMANA1, 0) /
                                       vNUMDIASUTEISSEMANA)) /
                                       (NVL(QTVENDMES1, 0) +
                                       NVL(QTVENDMES2, 0) +
                                       NVL(QTVENDMES3, 0) /
                                       vNUMDIASUTEISTRIMESTRE) - 1) * 100
             WHERE ROWID = registro.ROWID
               AND NVL((NVL(QTVENDMES1, 0) + NVL(QTVENDMES2, 0) +
                       NVL(QTVENDMES3, 0)),
                       0) > 0;
          EXCEPTION
            WHEN others THEN

              MENSAGEM := 'Erro ao atualizar giro semanal por dias úteis do mês e da semana:' ||
                          SQLCODE || '-' || SQLERRM;

              INSERT INTO PCLOGRECALCGIRODIA (CODFILIAL, CODPROD, DATA, OBSERVACAO)
                                      VALUES (registro.codfilial
                                             ,registro.codprod
                                             ,SYSDATE
                                             ,MENSAGEM);
          END;

          COMMIT;

        END LOOP;
      ELSIF vTipoCalcGiroDia = 'S' THEN
        FOR registro IN (SELECT PCEST.CODPROD, PCEST.CODFILIAL, ROWID
                           FROM PCEST
                          WHERE PCEST.CODPROD = DECODE(nvl(PCODPROD,0), 0, PCEST.CODPROD, PCODPROD)
                            AND (PCEST.CODFILIAL = DECODE(NVL(PFILIAL,'-1'), '-1', PCEST.CODFILIAL, PFILIAL)
                                 or '99' = NVL(PFILIAL,'-1')
                                 )
                            ) LOOP

          BEGIN
            -- Lock do registro atual
            SELECT 1 INTO vLock FROM PCEST WHERE ROWID = registro.rowid FOR UPDATE;

            UPDATE PCEST
               SET QTGIRODIA         = (CASE WHEN vTIPOVALORGIRODIA = 'A' THEN ROUND((NVL(QTVENDSEMANA1, 0) + NVL(QTVENDSEMANA2, 0) + NVL(QTVENDSEMANA3, 0)) / (vNUMDIASUTEISSEMANA * 3)) WHEN vTIPOVALORGIRODIA = 'T' THEN TRUNC((NVL(QTVENDSEMANA1, 0) + NVL(QTVENDSEMANA2, 0) + NVL(QTVENDSEMANA3, 0)) / (vNUMDIASUTEISSEMANA * 3)) ELSE((NVL(QTVENDSEMANA1, 0) + NVL(QTVENDSEMANA2, 0) + NVL(QTVENDSEMANA3, 0)) / (vNUMDIASUTEISSEMANA * 3)) END),
                   PERCEVOLUCAOVENDA = DECODE(NVL(QTVENDSEMANA2, 0),
                                              0,
                                              100,
                                              (((NVL(QTVENDSEMANA1, 0) /
                                              NVL(QTVENDSEMANA2, 0)) - 1) * 100))
             WHERE ROWID = registro.ROWID;
          EXCEPTION
            WHEN others THEN

              MENSAGEM := 'Erro ao atualizar giro semanal por dias úteis da semana:' ||
                          SQLCODE || '-' || SQLERRM;

              INSERT INTO PCLOGRECALCGIRODIA (CODFILIAL, CODPROD, DATA, OBSERVACAO)
                                      VALUES (registro.codfilial
                                             ,registro.codprod
                                             ,SYSDATE
                                             ,MENSAGEM);
          END;

          COMMIT;

        END LOOP;
      ELSIF vTipoCalcGiroDia = 'D' then
        SELECT TRUNC(SYSDATE), TO_NUMBER(TO_CHAR(SYSDATE, 'DD'))
          INTO vDATA, vDIA
          FROM DUAL;

        vnNumDiasMesAtual := (vDIA - 1);

        FOR reg_lock in (SELECT CODPROD, ROWID
                           FROM PCEST
                          WHERE 1 = 1 --CODFILIAL <> '99'
                            AND PCEST.CODPROD =
                                DECODE(nvl(PCODPROD, 0),
                                       0,
                                       PCEST.CODPROD,
                                       PCODPROD)
                            AND (PCEST.CODFILIAL =
                                DECODE(NVL(PFILIAL, '-1'),
                                        '-1',
                                        PCEST.CODFILIAL,
                                        PFILIAL) or
                                '99' = NVL(PFILIAL, '-1'))
                            AND QTGIRODIA > 0
                            AND (QTVENDMES = 0 and QTVENDMES1 = 0 and QTVENDMES2 = 0 and QTVENDMES3 = 0)
                          ORDER BY CODPROD) LOOP
          BEGIN

            SELECT 1
              INTO vLock
              FROM PCEST
             WHERE ROWID = reg_lock.rowid
               FOR UPDATE;

            UPDATE PCEST SET QTGIRODIA = 0 WHERE ROWID = reg_lock.ROWID;
          EXCEPTION
            WHEN others THEN

              MENSAGEM := 'Erro ao zerar giro semanal(TipoCalc  = D): ' ||
                          SQLCODE || '-' || SQLERRM;

          END;
          COMMIT;
        END LOOP;

        FOR registro in (SELECT CODPROD,
                                NVL(QTVENDMES, 0) QTVENDMES,
                                NVL(QTVENDMES1, 0) QTVENDMES1,
                                NVL(QTVENDMES2, 0) QTVENDMES2,
                                NVL(QTVENDMES3, 0) QTVENDMES3,
                                DTULTENT,
                                CODFILIAL,
                                DTPRIMCOMPRA,
                                ROWID
                           FROM PCEST
                          WHERE 1=1 --CODFILIAL <> '99'
                            AND PCEST.CODPROD = DECODE(nvl(PCODPROD,0), 0, PCEST.CODPROD, PCODPROD)
                            AND (PCEST.CODFILIAL = DECODE(NVL(PFILIAL,'-1'), '-1', PCEST.CODFILIAL, PFILIAL)
                                 or '99' = NVL(PFILIAL,'-1')
                                )
                            AND (QTVENDMES > 0 or QTVENDMES1 > 0 or QTVENDMES2 > 0 or QTVENDMES3 > 0)
                          ORDER BY CODPROD) LOOP
        BEGIN
          IF registro.DTPRIMCOMPRA is null then
          begin
            SELECT MIN(DTMOV)
              INTO vnDtPrimCompra
              FROM PCMOV
             WHERE CODPROD = registro.CODPROD
               AND CODOPER IN ('E', 'EB','ET','EP')
               AND CODFILIAL = registro.CODFILIAL;
          EXCEPTION
             WHEN others THEN
                  vnDtPrimCompra := nvl(registro.DTPRIMCOMPRA,vdata);
           end;
          ELSE
            vnDtPrimCompra := registro.DTPRIMCOMPRA;
          END IF;

          vnDtPrimCompra := nvl(vnDtPrimCompra,vdata);

          vnQtDias := FLOOR(vDATA - vnDtPrimCompra);

          IF vnQtDias > (90 + vnNumDiasMesAtual) THEN
            vnQtDias := 90 + vnNumDiasMesAtual;
          END IF;


        SELECT COUNT(1)
          INTO vnDiasGiro
          FROM (SELECT DATA
                   FROM PCHISTEST
                  WHERE CODPROD = REGISTRO.CODPROD
                    AND DATA >= TRUNC(SYSDATE) - VNQTDIAS
                    AND DATA <= TRUNC(SYSDATE)
                    AND CODFILIAL = REGISTRO.CODFILIAL
                    AND (CASE NVL(PTIPOCALCULODIAS, 0) WHEN 0 THEN
                         NVL(PCHISTEST.QTESTGER, 0) WHEN 1
                         THEN(NVL(PCHISTEST.QTESTGER, 0) - NVL(PCHISTEST.QTRESERV, 0) -
                              NVL(PCHISTEST.QTINDENIZ, 0)) END > 0)
                 UNION
                 SELECT DATA
                   FROM PCHISTESTFILA PCHISTEST
                  WHERE CODPROD = REGISTRO.CODPROD
                    AND DATA >= TRUNC(SYSDATE) - VNQTDIAS
                    AND DATA <= TRUNC(SYSDATE)
                    AND CODFILIAL = REGISTRO.CODFILIAL
                    AND (CASE NVL(PTIPOCALCULODIAS, 0) WHEN 0 THEN
                         NVL(PCHISTEST.QTESTGER, 0) WHEN 1
                         THEN(NVL(PCHISTEST.QTESTGER, 0) - NVL(PCHISTEST.QTRESERV, 0) -
                              NVL(PCHISTEST.QTINDENIZ, 0)) END > 0));

          IF vnDiasGiro < 0 THEN
            vnDiasGiro := 1;
          END IF;

          IF vnDiasGiro <> 0 then
            vnQtGiroDia := (registro.QTVENDMES + registro.QTVENDMES1 +
                           registro.QTVENDMES2 + registro.QTVENDMES3) /
                           vnDiasGiro;
          ELSE
            vnQtGiroDia := 0;
          END IF;
            -- Lock do registro atual
            SELECT 1 INTO vLock FROM PCEST WHERE ROWID = registro.rowid FOR UPDATE;

            UPDATE PCEST
               SET QTGIRODIA         = (CASE WHEN vTIPOVALORGIRODIA = 'A' THEN Round(vnQtGiroDia) WHEN vTIPOVALORGIRODIA = 'T' THEN Trunc(vnQtGiroDia) ELSE vnQtGiroDia END),
                   DTPRIMCOMPRA      = vnDtPrimCompra,
                   PERCEVOLUCAOVENDA = DECODE(NVL(QTVENDMES2, 0),
                                              0,
                                              100,
                                              (((NVL(QTVENDMES1, 0) /
                                              NVL(QTVENDMES2, 0)) - 1) * 100))
             WHERE ROWID = registro.rowid;
          EXCEPTION
            WHEN others THEN

              MENSAGEM := 'Erro ao atualizar giro semanal por dias úteis da semana:' ||
                          SQLCODE || '-' || SQLERRM;

              INSERT INTO PCLOGRECALCGIRODIA (CODFILIAL, CODPROD, DATA, OBSERVACAO)
                                      VALUES (registro.codfilial
                                             ,registro.codprod
                                             ,SYSDATE
                                             ,MENSAGEM);
          END;

          COMMIT;

        END LOOP;
      ELSIF vTipoCalcGiroDia = 'U' then
        SELECT TRUNC(SYSDATE), TO_NUMBER(TO_CHAR(SYSDATE, 'DD'))
          INTO vDATA, vDIA
          FROM DUAL;

        vnNumDiasMesAtual := (vDIA - 1);

        FOR registro in (SELECT CODPROD,
                                QTVENDMES,
                                QTVENDMES1,
                                QTVENDMES2,
                                QTVENDMES3,
                                DTULTENT,
                                CODFILIAL,
                                DTPRIMCOMPRA,
                                ROWID
                           FROM PCEST
                          WHERE 1=1 --CODFILIAL <> '99'
                            AND PCEST.CODPROD = DECODE(nvl(PCODPROD,0), 0, PCEST.CODPROD, PCODPROD)
                            AND (PCEST.CODFILIAL = DECODE(NVL(PFILIAL,'-1'), '-1', PCEST.CODFILIAL, PFILIAL)
                                or '99' = NVL(PFILIAL,'-1')
                                )
                          ORDER BY CODPROD) LOOP
        BEGIN
          IF registro.DTPRIMCOMPRA is null then
          begin
            SELECT MIN(DTMOV)
              INTO vnDtPrimCompra
              FROM PCMOV
             WHERE CODPROD = registro.CODPROD
               AND CODOPER IN ('E', 'EB','ET')
               AND CODFILIAL = registro.CODFILIAL;
          EXCEPTION
             WHEN others THEN
                  vnDtPrimCompra := nvl(registro.DTPRIMCOMPRA,vdata);
           end;
          ELSE
            vnDtPrimCompra := registro.DTPRIMCOMPRA;
          END IF;

          vnDtPrimCompra := nvl(vnDtPrimCompra,vdata);

          vnQtDias := FLOOR(vDATA - vnDtPrimCompra);

          IF vnQtDias > (90 + vnNumDiasMesAtual) THEN
            vnQtDias := 90 + vnNumDiasMesAtual;
          END IF;

          vnDiasGiro := vnQtDias;

          IF vnDiasGiro < 0 THEN
            vnDiasGiro := 1;
          END IF;

          IF vnDiasGiro <> 0 then
            vnQtGiroDia := (registro.QTVENDMES + registro.QTVENDMES1 +
                           registro.QTVENDMES2 + registro.QTVENDMES3) /
                           vnDiasGiro;
          ELSE
            vnQtGiroDia := 0;
          END IF;
            -- Lock do registro atual
            SELECT 1 INTO vLock FROM PCEST WHERE ROWID = registro.rowid FOR UPDATE;

            UPDATE PCEST
               SET QTGIRODIA         = (CASE WHEN vTIPOVALORGIRODIA = 'A' THEN Round(vnQtGiroDia) WHEN vTIPOVALORGIRODIA = 'T' THEN Trunc(vnQtGiroDia) ELSE vnQtGiroDia END),
                   DTPRIMCOMPRA      = vnDtPrimCompra,
                   PERCEVOLUCAOVENDA = DECODE(NVL(QTVENDMES2, 0),
                                              0,
                                              100,
                                              (((NVL(QTVENDMES1, 0) /
                                              NVL(QTVENDMES2, 0)) - 1) * 100))
             WHERE ROWID = registro.rowid;
          EXCEPTION
            WHEN others THEN

              MENSAGEM := 'Erro ao atualizar giro semanal por dias da semana:' ||
                          SQLCODE || '-' || SQLERRM;

              INSERT INTO PCLOGRECALCGIRODIA (CODFILIAL, CODPROD, DATA, OBSERVACAO)
                                      VALUES (registro.codfilial
                                             ,registro.codprod
                                             ,SYSDATE
                                             ,MENSAGEM);
          END;

          COMMIT;

        END LOOP;
      END IF;
      IF MENSAGEM IS NULL THEN
         MENSAGEM := 'Executado com sucesso';
      END IF;
      COMMIT;
    END IF;
	
	IF (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('UTILIZAREPOSICAOLOJA', '99', 'S')) = 'S'
      THEN
        FOR DADOS IN
               (SELECT DISTINCT PCPRODFILIAL.CODFILIAL
                               ,PCPRODFILIAL.TIPOESTOQUEMINIMO
                               ,PCPRODFILIAL.TIPOESTOQUEMAXIMO
                               ,PCPRODFILIAL.CODPROD
                               ,CASE
                                  WHEN (SELECT COUNT(1)
                                          FROM PCRECOMPOSICAOESTOQUE
                                         WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'SB'
                                           AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                               TO_CHAR(PCPRODUT.CODSUBCATEGORIA)
                                           AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                               PCPRODFILIAL.CODFILIAL) = 1 THEN
                                   (SELECT PCRECOMPOSICAOESTOQUE.DIASESTOQUEMIN
                                      FROM PCRECOMPOSICAOESTOQUE
                                     WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'SB'
                                       AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                           TO_CHAR(PCPRODUT.CODSUBCATEGORIA)
                                       AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                           PCPRODFILIAL.CODFILIAL)
                                  ELSE
                                   CASE
                                     WHEN (SELECT COUNT(1)
                                             FROM PCRECOMPOSICAOESTOQUE
                                            WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'CA'
                                              AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                                  TO_CHAR(PCPRODUT.CODCATEGORIA)
                                              AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                                  PCPRODFILIAL.CODFILIAL) = 1 THEN
                                      (SELECT PCRECOMPOSICAOESTOQUE.DIASESTOQUEMIN
                                         FROM PCRECOMPOSICAOESTOQUE
                                        WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'CA'
                                          AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                              TO_CHAR(PCPRODUT.CODCATEGORIA)
                                          AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                              PCPRODFILIAL.CODFILIAL)
                                     ELSE
                                      CASE
                                        WHEN (SELECT COUNT(1)
                                                FROM PCRECOMPOSICAOESTOQUE
                                               WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'SE'
                                                 AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                                     TO_CHAR(PCPRODUT.CODSEC)
                                                 AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                                     PCPRODFILIAL.CODFILIAL) = 1 THEN
                                         (SELECT PCRECOMPOSICAOESTOQUE.DIASESTOQUEMIN
                                            FROM PCRECOMPOSICAOESTOQUE
                                           WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'SE'
                                             AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                                 TO_CHAR(PCPRODUT.CODSEC)
                                             AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                                 PCPRODFILIAL.CODFILIAL)
                                        ELSE
                                         CASE
                                           WHEN (SELECT COUNT(1)
                                                   FROM PCRECOMPOSICAOESTOQUE
                                                  WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'DE'
                                                    AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                                        TO_CHAR(PCPRODUT.CODEPTO)
                                                    AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                                        PCPRODFILIAL.CODFILIAL) = 1 THEN
                                            (SELECT PCRECOMPOSICAOESTOQUE.DIASESTOQUEMIN
                                               FROM PCRECOMPOSICAOESTOQUE
                                              WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'DE'
                                                AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                                    TO_CHAR(PCPRODUT.CODEPTO)
                                                AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                                    PCPRODFILIAL.CODFILIAL)
                                           ELSE
                                            CASE
                                              WHEN (SELECT COUNT(1)
                                                      FROM PCRECOMPOSICAOESTOQUE
                                                     WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'SC'
                                                       AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                                           PCPRODFILIAL.SUBCLASSE
                                                       AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                                           PCPRODFILIAL.CODFILIAL) = 1 THEN
                                               (SELECT PCRECOMPOSICAOESTOQUE.DIASESTOQUEMIN
                                                  FROM PCRECOMPOSICAOESTOQUE
                                                 WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'SC'
                                                   AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                                       PCPRODFILIAL.SUBCLASSE
                                                   AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                                       PCPRODFILIAL.CODFILIAL)
                                              ELSE
                                               CASE
                                                 WHEN (SELECT COUNT(1)
                                                         FROM PCRECOMPOSICAOESTOQUE
                                                        WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'C'
                                                          AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                                              PCPRODFILIAL.CLASSEVENDA
                                                          AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                                              PCPRODFILIAL.CODFILIAL) = 1 THEN
                                                  (SELECT PCRECOMPOSICAOESTOQUE.DIASESTOQUEMIN
                                                     FROM PCRECOMPOSICAOESTOQUE
                                                    WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'C'
                                                      AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                                          PCPRODFILIAL.CLASSEVENDA
                                                      AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                                          PCPRODFILIAL.CODFILIAL)
                                               END
                                            END
                                         END
                                      END
                                   END
                                END AS DIASESTOQUEMIN
                               ,CASE
                                  WHEN (SELECT COUNT(1)
                                          FROM PCRECOMPOSICAOESTOQUE
                                         WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'SB'
                                           AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                               TO_CHAR(PCPRODUT.CODSUBCATEGORIA)
                                           AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                               PCPRODFILIAL.CODFILIAL) = 1 THEN
                                   (SELECT PCRECOMPOSICAOESTOQUE.DIASESTOQUEMAX
                                      FROM PCRECOMPOSICAOESTOQUE
                                     WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'SB'
                                       AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                           TO_CHAR(PCPRODUT.CODSUBCATEGORIA)
                                       AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                           PCPRODFILIAL.CODFILIAL)
                                  ELSE
                                   CASE
                                     WHEN (SELECT COUNT(1)
                                             FROM PCRECOMPOSICAOESTOQUE
                                            WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'CA'
                                              AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                                  TO_CHAR(PCPRODUT.CODCATEGORIA)
                                              AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                                  PCPRODFILIAL.CODFILIAL) = 1 THEN
                                      (SELECT PCRECOMPOSICAOESTOQUE.DIASESTOQUEMAX
                                         FROM PCRECOMPOSICAOESTOQUE
                                        WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'CA'
                                          AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                              TO_CHAR(PCPRODUT.CODCATEGORIA)
                                          AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                              PCPRODFILIAL.CODFILIAL)
                                     ELSE
                                      CASE
                                        WHEN (SELECT COUNT(1)
                                                FROM PCRECOMPOSICAOESTOQUE
                                               WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'SE'
                                                 AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                                     TO_CHAR(PCPRODUT.CODSEC)
                                                 AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                                     PCPRODFILIAL.CODFILIAL) = 1 THEN
                                         (SELECT PCRECOMPOSICAOESTOQUE.DIASESTOQUEMAX
                                            FROM PCRECOMPOSICAOESTOQUE
                                           WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'SE'
                                             AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                                 TO_CHAR(PCPRODUT.CODSEC)
                                             AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                                 PCPRODFILIAL.CODFILIAL)
                                        ELSE
                                         CASE
                                           WHEN (SELECT COUNT(1)
                                                   FROM PCRECOMPOSICAOESTOQUE
                                                  WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'DE'
                                                    AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                                        TO_CHAR(PCPRODUT.CODEPTO)
                                                    AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                                        PCPRODFILIAL.CODFILIAL) = 1 THEN
                                            (SELECT PCRECOMPOSICAOESTOQUE.DIASESTOQUEMAX
                                               FROM PCRECOMPOSICAOESTOQUE
                                              WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'DE'
                                                AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                                    TO_CHAR(PCPRODUT.CODEPTO)
                                                AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                                    PCPRODFILIAL.CODFILIAL)

                                           ELSE
                                            CASE
                                              WHEN (SELECT COUNT(1)
                                                      FROM PCRECOMPOSICAOESTOQUE
                                                     WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'SC'
                                                       AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                                           PCPRODFILIAL.SUBCLASSE
                                                       AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                                           PCPRODFILIAL.CODFILIAL) = 1 THEN
                                               (SELECT PCRECOMPOSICAOESTOQUE.DIASESTOQUEMAX
                                                  FROM PCRECOMPOSICAOESTOQUE
                                                 WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'SC'
                                                   AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                                       PCPRODFILIAL.SUBCLASSE
                                                   AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                                       PCPRODFILIAL.CODFILIAL)
                                              ELSE
                                               CASE
                                                 WHEN (SELECT COUNT(1)
                                                         FROM PCRECOMPOSICAOESTOQUE
                                                        WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'C'
                                                          AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                                              PCPRODFILIAL.CLASSEVENDA
                                                          AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                                              PCPRODFILIAL.CODFILIAL) = 1 THEN
                                                  (SELECT PCRECOMPOSICAOESTOQUE.DIASESTOQUEMAX
                                                     FROM PCRECOMPOSICAOESTOQUE
                                                    WHERE PCRECOMPOSICAOESTOQUE.TIPOEVENTO = 'C'
                                                      AND PCRECOMPOSICAOESTOQUE.CODEVENTO =
                                                          PCPRODFILIAL.CLASSEVENDA
                                                      AND PCRECOMPOSICAOESTOQUE.CODFILIAL =
                                                          PCPRODFILIAL.CODFILIAL)
                                               END
                                            END
                                         END
                                      END
                                   END
                                END AS DIASESTOQUEMAX,
                                    PCPRODFILIAL.ROWID
                      FROM PCPRODFILIAL, PCPRODUT
                     WHERE (NVL(PCPRODFILIAL.TIPOESTOQUEMINIMO, 'M') = 'A' OR
                           NVL(PCPRODFILIAL.TIPOESTOQUEMAXIMO, 'M') = 'A')
                       AND PCPRODUT.CODPROD = PCPRODFILIAL.CODPROD
					   AND (PCPRODFILIAL.CODFILIAL = DECODE(NVL(PFILIAL,'-1'), '-1', PCPRODFILIAL.CODFILIAL, PFILIAL)
                              or '99' = NVL(PFILIAL,'-1'))
					   ) LOOP

        begin
          SELECT 1
            INTO vLock
            FROM PCPRODFILIAL
           WHERE PCPRODFILIAL.ROWID = DADOS.ROWID
             and PCPRODFILIAL.CODPROD = DADOS.CODPROD
             AND PCPRODFILIAL.CODFILIAL = DADOS.CODFILIAL
             FOR UPDATE;
          IF DADOS.TIPOESTOQUEMINIMO = 'A' THEN
            UPDATE PCPRODFILIAL
               SET ESTOQUEMIN = DADOS.DIASESTOQUEMIN *
                                (SELECT PCEST.QTGIRODIA
                                   FROM PCEST
                                  WHERE PCEST.CODPROD = PCPRODFILIAL.CODPROD
                                    AND PCEST.CODFILIAL =
                                        PCPRODFILIAL.CODFILIAL)
             WHERE PCPRODFILIAL.ROWID = DADOS.ROWID
               and PCPRODFILIAL.CODPROD = DADOS.CODPROD
               AND PCPRODFILIAL.CODFILIAL = DADOS.CODFILIAL;
          END IF;

          IF DADOS.TIPOESTOQUEMAXIMO = 'A' THEN
            UPDATE PCPRODFILIAL
               SET ESTOQUEMAX = DADOS.DIASESTOQUEMAX *
                                (SELECT PCEST.QTGIRODIA
                                   FROM PCEST
                                  WHERE PCEST.CODPROD = PCPRODFILIAL.CODPROD
                                    AND PCEST.CODFILIAL =
                                        PCPRODFILIAL.CODFILIAL)
             WHERE PCPRODFILIAL.ROWID = DADOS.ROWID
               and PCPRODFILIAL.CODPROD = DADOS.CODPROD
               AND PCPRODFILIAL.CODFILIAL = DADOS.CODFILIAL;
          END IF;
		  
		  COMMIT;
        
        EXCEPTION
          WHEN others THEN

            MENSAGEM := 'Erro ao atualizar ESTOQUEMAX: ' || SQLCODE || '-' ||
                        SQLERRM;
			INSERT INTO PCLOGRECALCGIRODIA (CODFILIAL, CODPROD, DATA, OBSERVACAO)
                                    VALUES (DADOS.codfilial
                                           ,DADOS.codprod
                                           ,SYSDATE
                                           ,MENSAGEM);
          
        END;
      END LOOP;
    END IF;

    IF MENSAGEM IS NULL THEN
       MENSAGEM := 'Executado com sucesso';
    END IF;
    COMMIT;
  END;

  ------------------------------------------------------------------------------------

  FUNCTION CALCULARGIROSEMANA RETURN VARCHAR2 IS
  BEGIN
    --
    UPDATE PCEST
       SET QTVENDSEMANA3 = NVL(QTVENDSEMANA2, 0),
           QTVENDSEMANA2 = NVL(QTVENDSEMANA1, 0),
           QTVENDSEMANA1 = NVL(QTVENDSEMANA, 0);

    UPDATE PCEST SET QTVENDSEMANA = 0;
    --
    COMMIT;
    return 'Semana inicializada com sucesso.';
  EXCEPTION
    WHEN others THEN
      RAISE_APPLICATION_ERROR(20004, 'Erro ao inicializar a semana.');
      ROLLBACK;
  END;

  FUNCTION TIPO_TRANSFERENCIA (PFILIALVENDA  VARCHAR2,
                               PFILIALRETIRA VARCHAR2,
                               PFILIALNF     VARCHAR2)
    RETURN VARCHAR2
  /*************************************************************************************
  -------------------------- Alterações ------------------------------------------------
  Data           Autor             Solicitação       Descrição
  --------------------------------------------------------------------------------------
  28/01/2014     Rodrigo Santos    HIS.01198.2013    Implementação desta função para ajudar a definir o tipo
                                                     de transferência a ser realizada para o item.
  *************************************************************************************/
  IS
  BEGIN

    CASE
      --Todas as filiais iguais => NENHUMA TRANSFERÊNCIA
      WHEN PFILIALVENDA = NVL(PFILIALNF, PFILIALVENDA)
       AND PFILIALVENDA = NVL(PFILIALRETIRA, PFILIALVENDA)
      THEN
        RETURN 'N';
      --Somente a filial retira é diferente => TRANSFERÊNCIA DE FILIAL RETIRA
      WHEN NVL(PFILIALRETIRA, PFILIALVENDA) <> PFILIALVENDA
       AND NVL(PFILIALRETIRA, PFILIALVENDA) <> NVL(PFILIALNF, PFILIALVENDA)
       AND PFILIALVENDA = NVL(PFILIALNF, PFILIALVENDA)
      THEN
        RETURN 'R';
      --Somente a filial contábil é diferente => TRANSFERÊNCIA DE FILIAL VIRTUAL
      WHEN NVL(PFILIALNF, PFILIALVENDA) <> PFILIALVENDA
       AND NVL(PFILIALNF, PFILIALVENDA) <> NVL(PFILIALRETIRA, PFILIALVENDA)
       AND PFILIALVENDA = NVL(PFILIALRETIRA, PFILIALVENDA)
      THEN
        RETURN 'V';
      --Somente a filial de venda é diferente => NENHUMA TRANSFERÊNCIA
      WHEN PFILIALVENDA <> NVL(PFILIALNF, PFILIALVENDA)
       AND PFILIALVENDA <> NVL(PFILIALRETIRA, PFILIALVENDA)
       AND NVL(PFILIALNF, PFILIALVENDA) = NVL(PFILIALRETIRA, PFILIALVENDA)
      THEN
        RETURN 'N';
      --Todas as filiais são diferentes entre si => TRANSFERÊNCIA DE FILIAL VIRTUAL E RETIRA
      WHEN PFILIALVENDA <> NVL(PFILIALNF, PFILIALVENDA)
       AND PFILIALVENDA <> NVL(PFILIALRETIRA, PFILIALVENDA)
       AND NVL(PFILIALNF, PFILIALVENDA) <> NVL(PFILIALRETIRA, PFILIALVENDA)
      THEN
        RETURN 'VR';
      --Casos não identificados
      ELSE
        RETURN 'N';
    END CASE;

  END TIPO_TRANSFERENCIA;

  FUNCTION USA_CFAT(PNUMCAR IN NUMBER,
                    PNUMPED IN NUMBER)
    RETURN VARCHAR2 IS
    ----------------------------------------
    vbExisteTransfProcessoCfat    BOOLEAN;
    vbExisteRetiraProcessoAntigo  BOOLEAN;
    vbExisteVirtualProcessoAntigo BOOLEAN;
    -----------FUNÇÕES AUXILIARES ----------
    FUNCTION parametroUtilizaCFAT
      RETURN BOOLEAN IS
    BEGIN
      RETURN (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('UTILIZACENTRALFATURAMENTO','99','N') = 'S');
    EXCEPTION
      WHEN OTHERS THEN
        RETURN FALSE;
    END parametroUtilizaCFAT;
    ----------------------------------------
    FUNCTION existeTransfProcessoCfat
      RETURN BOOLEAN IS

      vnQTUSA1420 NUMBER;
    BEGIN

      IF PNUMCAR = -1 THEN        
        SELECT COUNT(1) QT INTO vnQTUSA1420
          FROM PCMOVTRANSF
         WHERE (NUMPED = PNUMPED);
      ELSE
        SELECT COUNT(1) QT INTO vnQTUSA1420
          FROM PCMOVTRANSF
         WHERE (NUMCAR = PNUMCAR);
      END IF;

      RETURN (vnQTUSA1420 > 0);

    EXCEPTION
      WHEN OTHERS THEN
        RETURN FALSE;
    END existeTransfProcessoCfat;
    ----------------------------------------
    FUNCTION existeRetiraProcessoAntigo
      RETURN BOOLEAN IS

      vnQT NUMBER;
    BEGIN

      IF PNUMCAR = -1 THEN        
        SELECT COUNT(1)
          INTO vnQT
          FROM PCTRANSFDEP R,
               PCNFSAID S,
               PCNFSAID ST
         WHERE R.NUMTRANSVENDA = S.NUMTRANSVENDA
           AND R.NUMTRANSTRANSFSAIDA = ST.NUMTRANSVENDA(+)
           AND ST.DTCANCEL IS NULL
           AND (S.NUMPED = PNUMPED);
      ELSE
        SELECT COUNT(1)
          INTO vnQT
          FROM PCTRANSFDEP R,
               PCNFSAID S,
               PCNFSAID ST
         WHERE R.NUMTRANSVENDA = S.NUMTRANSVENDA
           AND R.NUMTRANSTRANSFSAIDA = ST.NUMTRANSVENDA(+)
           AND ST.DTCANCEL IS NULL
           AND (S.NUMCAR = PNUMCAR);
      END IF;

      RETURN (vnQT > 0);
    EXCEPTION
      WHEN OTHERS THEN
        RETURN FALSE;
    END existeRetiraProcessoAntigo;
    ----------------------------------------
    FUNCTION existeVirtualProcessoAntigo
      RETURN BOOLEAN IS

      vnQT NUMBER;
    BEGIN

      IF PNUMCAR = -1 THEN        
        SELECT COUNT(1)
          INTO vnQT
          FROM PCTRANSFVIRT V
         WHERE V.DTCANCEL IS NULL
           AND (V.NUMPED = PNUMPED);
      ELSE
        SELECT COUNT(1)
          INTO vnQT
          FROM PCTRANSFVIRT V
         WHERE V.DTCANCEL IS NULL
           AND (V.NUMCAR = PNUMCAR);
      END IF;

      RETURN (vnQT > 0);
    EXCEPTION
      WHEN OTHERS THEN
        RETURN FALSE;
    END existeVirtualProcessoAntigo;
    ----------------------------------------
  BEGIN

    IF parametroUtilizaCFAT THEN
      vbExisteRetiraProcessoAntigo  := existeRetiraProcessoAntigo;
      vbExisteVirtualProcessoAntigo := existeVirtualProcessoAntigo;

      IF (vbExisteRetiraProcessoAntigo OR
          vbExisteVirtualProcessoAntigo) THEN
        RETURN 'N';
      ELSE
        RETURN 'S';
      END IF;
    ELSE
      vbExisteTransfProcessoCfat    := existeTransfProcessoCfat;
      IF (vbExisteTransfProcessoCfat) THEN
        RETURN 'S';
      ELSE
        RETURN 'N';
      END IF;
    END IF;

  END USA_CFAT;
/*************************************************************************************
  -------------------------- Alterações ------------------------------------------------
  Data           Autor             Solicitação         Descrição
  --------------------------------------------------------------------------------------
  11/08/2014  Marcos Garcia      0.085796.2014        Ajustada a procedure para chamar ou sub proceure a resolver o problema de performance onde estava demorando muito o sql
  *************************************************************************************/
  PROCEDURE PROCESSA_MOVESTOQUE( psOPERACAO              VARCHAR2,
                                 pnNUMTRANSACAO          NUMBER,
                                 pnCODPROD               NUMBER,
                                 psCODOPER               VARCHAR2,
                                 psSTATUS                VARCHAR2,
                                 pnNUMTRANSENT           NUMBER,
                                 pnNUMTRANSVENDA         NUMBER,
                                 psOrigemTransf          VARCHAR2,
                                 psOrigemTransfOrigem    VARCHAR2,
                                 psTIPOITEM              VARCHAR2,
                                 pnCONDVENDA             INTEGER,
                                 psBROKER                VARCHAR2,
                                 psSerieNotaOrigem       VARCHAR2,
                                 pnNumTtransacaoOrigem   NUMBER,
                                 psOrigTransfOrigem      VARCHAR2,
                                 pnNumNotaConsig         NUMBER,
                                 psDevolucaoSimbolica    VARCHAR2,
                                 ROWID_PCMOV             VARCHAR2,
                                 psVersaoRegistro        VARCHAR2
                               )
  IS
    vsMOVESTOQUEGERENCIAL     VARCHAR2(1);
    vsMOVESTOQUECONTABIL      VARCHAR2(1);
    vnNUMTRANSVENDA           NUMBER;
    vnCONDVENDA               NUMBER;
    vsTIPODESCARGA            VARCHAR2(1);
    vnCOUNTNF                 NUMBER;
    vbEXISTECUPOM             BOOLEAN;
    vbEHNFCOMPLEMENTAR        BOOLEAN;
  BEGIN
    --VERIFICAR SE É NF PROVENIENTE DE CUPOM
    BEGIN
      SELECT COUNT(*)
        INTO vnCOUNTNF
        FROM PCNFSAID
       WHERE NUMTRANSVENDA = NVL(pnNUMTRANSACAO,0)
         AND TIPOVENDA = 'V4'
         AND NVL(NUMCUPOM,0) <> 0;

      vbEXISTECUPOM := (vnCOUNTNF > 0);

    EXCEPTION
      WHEN OTHERS THEN
        vbEXISTECUPOM := FALSE;
    END;
    --VERIFICAR SE É NF COMPLEMENTAR
    BEGIN
      SELECT COUNT(*)
        INTO vnCOUNTNF
        FROM PCNFSAID
       WHERE NUMTRANSVENDA = NVL(pnNUMTRANSACAO,0)
         AND FINALIDADENFE IN ('A','C');

      vbEHNFCOMPLEMENTAR := (vnCOUNTNF > 0);

    EXCEPTION
      WHEN OTHERS THEN
        vbEHNFCOMPLEMENTAR := FALSE;
    END;
    ---------------------------------------

    IF INSTR(psSTATUS,'A') > 0 THEN
      vsMOVESTOQUECONTABIL := 'S';
    ELSE
      vsMOVESTOQUECONTABIL := 'N';
    END IF;

    IF INSTR(psSTATUS,'B') > 0 THEN
      vsMOVESTOQUEGERENCIAL := 'S';
    ELSE
      vsMOVESTOQUEGERENCIAL := 'N';
    END IF;

    IF (psOPERACAO = 'S' AND pnNUMTRANSACAO > 0)  AND (psCODOPER NOT IN ('SD','ST','SP')) THEN

      CASE pnCONDVENDA
        WHEN 1 THEN --> Tipo de Venda 1
          CASE psSTATUS
            WHEN 'A' THEN
              vsMOVESTOQUEGERENCIAL := 'N';
              vsMOVESTOQUECONTABIL  := 'S';
            WHEN 'AB' THEN
              vsMOVESTOQUEGERENCIAL := 'S';
              vsMOVESTOQUECONTABIL  := 'S';
            WHEN 'B' THEN
              vsMOVESTOQUEGERENCIAL := 'S';
              vsMOVESTOQUECONTABIL  := 'N';
            ELSE
              vsMOVESTOQUEGERENCIAL := 'N';
              vsMOVESTOQUECONTABIL  := 'N';
          END CASE;
          --TV1 proveniente de consignação(T20)
          IF pnNumNotaConsig > 0 THEN
            vsMOVESTOQUEGERENCIAL := 'N';
            vsMOVESTOQUECONTABIL  := 'N';
          END IF;
        WHEN 4 THEN --> Tipo de Venda 4
          IF vbEXISTECUPOM THEN
            vsMOVESTOQUEGERENCIAL := 'N';
            vsMOVESTOQUECONTABIL  := 'N';
          ELSIF vbEHNFCOMPLEMENTAR THEN
            vsMOVESTOQUEGERENCIAL := 'N';
            vsMOVESTOQUECONTABIL  := 'N';
          ELSE
            vsMOVESTOQUEGERENCIAL := 'N';
            vsMOVESTOQUECONTABIL  := 'S';
          END IF;
        WHEN 5 THEN --> Tipo de Venda 5
          CASE psSTATUS
            WHEN 'A' THEN
              vsMOVESTOQUEGERENCIAL := 'N';
              vsMOVESTOQUECONTABIL  := 'S';
            WHEN 'AB' THEN
              vsMOVESTOQUEGERENCIAL := 'S';
              vsMOVESTOQUECONTABIL  := 'S';
            WHEN 'B' THEN
              vsMOVESTOQUEGERENCIAL := 'S';
              vsMOVESTOQUECONTABIL  := 'N';
            ELSE
              vsMOVESTOQUEGERENCIAL := 'N';
              vsMOVESTOQUECONTABIL  := 'N';
          END CASE;
        WHEN 7 THEN --> Tipo de Venda 7
          vsMOVESTOQUEGERENCIAL := 'N';
          vsMOVESTOQUECONTABIL  := 'N';
        WHEN 8 THEN --> Tipo de Venda 8
          CASE psSTATUS
            WHEN 'A' THEN
              vsMOVESTOQUEGERENCIAL := 'N';
              vsMOVESTOQUECONTABIL  := 'S';
            WHEN 'AB' THEN
              vsMOVESTOQUEGERENCIAL := 'S';
              vsMOVESTOQUECONTABIL  := 'S';
            WHEN 'B' THEN
              vsMOVESTOQUEGERENCIAL := 'S';
              vsMOVESTOQUECONTABIL  := 'N';
            ELSE
              vsMOVESTOQUEGERENCIAL := 'N';
              vsMOVESTOQUECONTABIL  := 'N';
          END CASE;
        WHEN 9 THEN --> Tipo de Venda 9
          CASE psSTATUS
            WHEN 'A' THEN
              vsMOVESTOQUEGERENCIAL := 'N';
              vsMOVESTOQUECONTABIL  := 'S';
            WHEN 'AB' THEN
              vsMOVESTOQUEGERENCIAL := 'S';
              vsMOVESTOQUECONTABIL  := 'S';
            WHEN 'B' THEN
              vsMOVESTOQUEGERENCIAL := 'S';
              vsMOVESTOQUECONTABIL  := 'N';
            ELSE
              vsMOVESTOQUEGERENCIAL := 'N';
              vsMOVESTOQUECONTABIL  := 'N';
          END CASE;
        WHEN 10 THEN --> Tipo de Venda 10
          CASE psSTATUS
            WHEN 'A' THEN
              vsMOVESTOQUEGERENCIAL := 'N';
              vsMOVESTOQUECONTABIL  := 'S';
            WHEN 'AB' THEN
              vsMOVESTOQUEGERENCIAL := 'S';
              vsMOVESTOQUECONTABIL  := 'S';
            WHEN 'B' THEN
              vsMOVESTOQUEGERENCIAL := 'S';
              vsMOVESTOQUECONTABIL  := 'N';
            ELSE
              vsMOVESTOQUEGERENCIAL := 'N';
              vsMOVESTOQUECONTABIL  := 'N';
          END CASE;
        WHEN 11 THEN --> Tipo de Venda 11
          CASE psSTATUS
            WHEN 'A' THEN
              vsMOVESTOQUEGERENCIAL := 'N';
              vsMOVESTOQUECONTABIL  := 'S';
            WHEN 'AB' THEN
              vsMOVESTOQUEGERENCIAL := 'S';
              vsMOVESTOQUECONTABIL  := 'S';
            WHEN 'B' THEN
              vsMOVESTOQUEGERENCIAL := 'S';
              vsMOVESTOQUECONTABIL  := 'N';
            ELSE
              vsMOVESTOQUEGERENCIAL := 'N';
              vsMOVESTOQUECONTABIL  := 'N';
          END CASE;
        WHEN 13 THEN --> Tipo de Venda 13
          CASE psSTATUS
            WHEN 'A' THEN
              vsMOVESTOQUEGERENCIAL := 'N';
              vsMOVESTOQUECONTABIL  := 'S';
            WHEN 'AB' THEN
              vsMOVESTOQUEGERENCIAL := 'S';
              vsMOVESTOQUECONTABIL  := 'S';
            WHEN 'B' THEN
              vsMOVESTOQUEGERENCIAL := 'S';
              vsMOVESTOQUECONTABIL  := 'N';
            ELSE
              vsMOVESTOQUEGERENCIAL := 'N';
              vsMOVESTOQUECONTABIL  := 'N';
          END CASE;
        WHEN 14 THEN --> Tipo de Venda 14
          vsMOVESTOQUEGERENCIAL := 'N';
          vsMOVESTOQUECONTABIL  := 'N';
        WHEN 20 THEN --> Tipo de Venda 20
          CASE psSTATUS
            WHEN 'A' THEN
              vsMOVESTOQUEGERENCIAL := 'N';
              vsMOVESTOQUECONTABIL  := 'S';
            WHEN 'AB' THEN
              vsMOVESTOQUEGERENCIAL := 'S';
              vsMOVESTOQUECONTABIL  := 'S';
            WHEN 'B' THEN
              vsMOVESTOQUEGERENCIAL := 'S';
              vsMOVESTOQUECONTABIL  := 'N';
            ELSE
              vsMOVESTOQUEGERENCIAL := 'N';
              vsMOVESTOQUECONTABIL  := 'N';
          END CASE;
        ELSE
          NULL;
      END CASE;
    END IF;


     /*
     Solicitação : 0.064683.2014
     Data: 16/06/2014
     Autor: Marcos Garcia
     Descrição : realizando os ajustes após a refatoração
    */
    IF psSerieNotaOrigem = 'CF' THEN
      IF psOrigTransfOrigem = 'RETIRA' THEN
        vsMOVESTOQUECONTABIL  := 'S';
        vsMOVESTOQUEGERENCIAL := 'N';
      END IF;
    END IF;

    IF psCODOPER = 'ED' THEN

      vnNUMTRANSVENDA := 0;
      BEGIN
        SELECT NVL(PCESTCOM.NUMTRANSVENDA,0)
          INTO vnNUMTRANSVENDA
          FROM PCESTCOM
        WHERE PCESTCOM.NUMTRANSENT = pnNUMTRANSENT;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnNUMTRANSVENDA := 0;
      END;
      vnCONDVENDA := 0;
      BEGIN
        SELECT NVL(PCNFSAID.CONDVENDA,0)
          INTO vnCONDVENDA
          FROM PCNFSAID
        WHERE PCNFSAID.NUMTRANSVENDA = vnNUMTRANSVENDA;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnCONDVENDA := 0;
      END;


      IF vnNUMTRANSVENDA > 0 THEN

        IF vnCONDVENDA = 7 THEN
          vsMOVESTOQUEGERENCIAL := 'N';
          vsMOVESTOQUECONTABIL  := 'N';
        END IF;
        IF vnCONDVENDA = 8 THEN
          vsMOVESTOQUEGERENCIAL := 'S';
          vsMOVESTOQUECONTABIL  := 'S';
        END IF;
        IF ((psBROKER = 'S') and (vnCONDVENDA = 4)) THEN
          vsMOVESTOQUEGERENCIAL := 'N';
          vsMOVESTOQUECONTABIL  := 'S';
        END IF;

      ELSE
        vsTIPODESCARGA := 'X';
        BEGIN
          SELECT PCNFENT.TIPODESCARGA
            INTO vsTIPODESCARGA
            FROM PCNFENT
          WHERE PCNFENT.NUMTRANSENT = pnNUMTRANSENT;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vsTIPODESCARGA := 'X';
        END;
        /*IF vsTIPODESCARGA = '6' THEN
          vsMOVESTOQUEGERENCIAL := 'S';
          vsMOVESTOQUECONTABIL  := 'S';
        END IF;*/
        IF vsTIPODESCARGA = '7' THEN
          vsMOVESTOQUEGERENCIAL := 'S';
          vsMOVESTOQUECONTABIL  := 'N';
        END IF;
        IF vsTIPODESCARGA = '8' THEN
          vsMOVESTOQUEGERENCIAL := 'N';
          vsMOVESTOQUECONTABIL  := 'S';
        END IF;
        IF vsTIPODESCARGA = 'X' THEN
          IF INSTR(psSTATUS,'A') > 0 THEN
            vsMOVESTOQUECONTABIL := 'S';
          ELSE
            vsMOVESTOQUECONTABIL := 'N';
          END IF;

          IF INSTR(psSTATUS,'B') > 0 THEN
            vsMOVESTOQUEGERENCIAL := 'S';
          ELSE
            vsMOVESTOQUEGERENCIAL := 'N';
          END IF;
        END IF;

      END IF;

    END IF;

    IF psCODOPER = 'EN' THEN
      IF psDevolucaoSimbolica = 'S' THEN
        vsMOVESTOQUEGERENCIAL := 'N';
        vsMOVESTOQUECONTABIL  := 'N';
      ELSE
        vsMOVESTOQUEGERENCIAL := 'S';
        vsMOVESTOQUECONTABIL  := 'S';
      END IF;
    ELSIF psCODOPER = 'SV' THEN
      vsMOVESTOQUEGERENCIAL := 'S';
      vsMOVESTOQUECONTABIL  := 'N';
    END IF;

    -- DEFININDO MOVIMENTAÇÃO CONTÁBIL E GERENCIAL NA PCMOVN
    UPDATE PCMOV
       SET PCMOV.MOVESTOQUECONTABIL = vsMOVESTOQUECONTABIL,
           PCMOV.MOVESTOQUEGERENCIAL = vsMOVESTOQUEGERENCIAL
     WHERE ROWID = ROWID_PCMOV;

  END;
  /*************************************************************************************
  -------------------------- Alterações ------------------------------------------------
  Data           Autor             Solicitação         Descrição
  --------------------------------------------------------------------------------------
  16/06/2014  Marcos Garcia      0.064683.2014        Verficando se a nota orifinal foi de origem CF  e filial retira
                                                      pois quando e nessa situação e movimentada os estoque contabil de venda.
  29/07/2014  Marcos Garcia      0.080450.2014        Ajustado a gravação dos campos MOVESTOQUEGERENCIAL E MOVESTOQURCONTABIL para respeitar o status do campo
                                                      pois toda movimentação de estoque contabil ou gerencial deve ter uma justificativa na PCMOV.
  11/08/2014  Marcos Garcia      0.085796.2014        Ajustada a procedure para chamar ou sub proceure a resolver o problema de performance onde estava demorando muito o sql.
  *************************************************************************************/
  PROCEDURE DEFINIR_MOVESTOQUE (PNUMTRANSACAO IN NUMBER,
                                POPERACAO     IN VARCHAR2)
  IS
    vsMOVESTOQUEGERENCIAL     VARCHAR2(1);
    vsMOVESTOQUECONTABIL      VARCHAR2(1);
    vnNUMTRANSVENDA           NUMBER;
    viCONDVENDA               INTEGER;
    vsTIPODESCARGA            VARCHAR2(1);
    vsBROKER                  VARCHAR2(1);
    vsSerieNotaOrigem         VARCHAR2(3);
    vnNumTransacaoOrigem      NUMBER;
    vsOrigTransfOrigem        VARCHAR2(30);
    vnNumNotaConsig           NUMBER;
    vsDevolucaoSimbolica      VARCHAR2(3);
  BEGIN

    --Verificação da nota original se e de cupom fiscal
    BEGIN

      IF (POPERACAO) = 'S' THEN
        SELECT S.SERIE, TD.NUMTRANSVENDA
          INTO vsSerieNotaOrigem,vnNumTransacaoOrigem
          FROM PCTRANSFDEP TD, PCNFSAID S
         WHERE S.NUMTRANSVENDA = TD.NUMTRANSVENDA(+)
           AND TD.NUMTRANSTRANSFSAIDA = PNUMTRANSACAO
           AND ROWNUM = 1;
      END IF;

      IF (POPERACAO) = 'E' THEN
        SELECT S.SERIE, TD.NUMTRANSVENDA
          INTO vsSerieNotaOrigem,vnNumTransacaoOrigem
          FROM PCTRANSFDEP TD, PCNFSAID S
         WHERE S.NUMTRANSVENDA = TD.NUMTRANSVENDA(+)
           AND TD.NUMTRANSTRANSFENT = PNUMTRANSACAO
           AND ROWNUM = 1;
      END IF;

    EXCEPTION
       WHEN NO_DATA_FOUND THEN
          vsSerieNotaOrigem := '';
          vnNumTransacaoOrigem := 0;
    END;

    BEGIN
      SELECT S.CONDVENDA, NVL(S.BROKER,'N'), NVL(P.NUMNOTACONSIG,0)
        INTO viCONDVENDA, vsBROKER, vnNumNotaConsig
       FROM PCNFSAID S
       LEFT JOIN PCPEDC P ON
         P.NUMPED = S.NUMPED
      WHERE S.NUMTRANSVENDA = PNUMTRANSACAO;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        viCONDVENDA := 0;
        vsBROKER := '';
        vnNumNotaConsig := 0;
    END;

    IF POPERACAO = 'E' THEN
      BEGIN
        SELECT pcnfent.devsimbolica
          INTO vsDevolucaoSimbolica
          FROM PCNFENT
         WHERE PCNFENT.NUMTRANSENT = PNUMTRANSACAO;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vsDevolucaoSimbolica := 'N';
      END;
    END IF;

    IF POPERACAO = 'S' THEN

      FOR ITENS IN (SELECT PCMOV.CODPROD,
                           PCMOV.CODOPER,
                           PCMOV.STATUS,
                           PCMOV.NUMTRANSENT,
                           PCMOV.NUMTRANSVENDA,
                           VENDAS.ORIGEM_TRANSFERENCIA(PNUMTRANSACAO) ORIG_TRANSF,
                           PCMOV.TIPOITEM,
                           PCMOV.ROWID ROWID_PCMOV,
                           NVL(PCMOVCOMPLE.VERSAOREGISTRO,'0') VERSAOREGISTRO
                      FROM PCMOV,PCMOVCOMPLE
                     WHERE PCMOV.NUMTRANSVENDA = PNUMTRANSACAO
                       AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+))
      LOOP

        /*
         Solicitação : 0.064683.2014
         Data: 16/06/2014
         Autor: Marcos Garcia
         Descrição : realizando os ajustes após a refatoração
        */
        IF vsSerieNotaOrigem = 'CF' THEN

          BEGIN
            SELECT VENDAS.ORIGEM_TRANSFERENCIA(PNUMTRANSACAO) ORIG_TRANSF
              INTO vsOrigTransfOrigem
              FROM PCMOV
             WHERE PCMOV.NUMTRANSVENDA = vnNumTransacaoOrigem
               AND PCMOV.CODPROD = ITENS.CODPROD
               AND ROWNUM = 1;


          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vsOrigTransfOrigem := '';
          END;
        END IF;

        PROCESSA_MOVESTOQUE(POPERACAO,
                            PNUMTRANSACAO,
                            ITENS.CODPROD,
                            ITENS.CODOPER,
                            ITENS.STATUS,
                            ITENS.NUMTRANSENT,
                            ITENS.NUMTRANSVENDA,
                            ITENS.ORIG_TRANSF,
                            vsOrigTransfOrigem,
                            ITENS.TIPOITEM,
                            viCONDVENDA,
                            vsBROKER,
                            vsSerieNotaOrigem,
                            vnNumTransacaoOrigem,
                            vsOrigTransfOrigem,
                            vnNumNotaConsig,
                            vsDevolucaoSimbolica,
                            ITENS.ROWID_PCMOV,
                            ITENS.VERSAOREGISTRO);

      END LOOP;
    ELSE
     FOR ITENS IN (SELECT PCMOV.CODPROD,
                           PCMOV.CODOPER,
                           PCMOV.STATUS,
                           PCMOV.NUMTRANSENT,
                           PCMOV.NUMTRANSVENDA,
                           VENDAS.ORIGEM_TRANSFERENCIA(PNUMTRANSACAO) ORIG_TRANSF,
                           PCMOV.TIPOITEM,
                           PCMOV.ROWID ROWID_PCMOV,
                           NVL(PCMOVCOMPLE.VERSAOREGISTRO,'0') VERSAOREGISTRO
                      FROM PCMOV,PCMOVCOMPLE
                     WHERE PCMOV.NUMTRANSENT = PNUMTRANSACAO
                       AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+))
      LOOP

        /*
         sOLICITACAO : 0.064683.2014
         Data: 16/06/2014
         Autor: Marcos Garcia
         Descrição : realizando os ajustes após a refatoração
        */
        IF vsSerieNotaOrigem = 'CF' THEN

          BEGIN
            SELECT VENDAS.ORIGEM_TRANSFERENCIA(PNUMTRANSACAO) ORIG_TRANSF
              INTO vsOrigTransfOrigem
              FROM PCMOV
             WHERE PCMOV.NUMTRANSENT = vnNumTransacaoOrigem
               AND PCMOV.CODPROD = ITENS.CODPROD
               AND ROWNUM = 1;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vsOrigTransfOrigem := '';
          END;
        END IF;

        PROCESSA_MOVESTOQUE(POPERACAO,
                            PNUMTRANSACAO,
                            ITENS.CODPROD,
                            ITENS.CODOPER,
                            ITENS.STATUS,
                            ITENS.NUMTRANSENT,
                            ITENS.NUMTRANSVENDA,
                            ITENS.ORIG_TRANSF,
                            vsOrigTransfOrigem,
                            ITENS.TIPOITEM,
                            viCONDVENDA,
                            vsBROKER,
                            vsSerieNotaOrigem,
                            vnNumTransacaoOrigem,
                            vsOrigTransfOrigem,
                            vnNumNotaConsig,
                            vsDevolucaoSimbolica,
                            ITENS.ROWID_PCMOV,
                            ITENS.VERSAOREGISTRO);

      END LOOP;
    END IF;

  END DEFINIR_MOVESTOQUE;

  FUNCTION ORIGEM_TRANSFERENCIA(PNUMTRANSTRANSF IN NUMBER)
    RETURN VARCHAR2
  IS
    vnREGTRANSFDEP        NUMBER(10);
    vnREGTRANSFDEPDEVOL   NUMBER(10);
    vnNUMPEDTV10          PCPEDC.NUMPED%TYPE;
    vsCODOPER             PCMOV.CODOPER%TYPE;
    ------------------
    vsRETORNO             VARCHAR2(30);
  BEGIN

    -- 1 -> TESTAR SE A NF É DE TRANSFERENCIA DE FILIAL RETIRA (1436 OU 1470)
    BEGIN

      SELECT COUNT(*)
        INTO vnREGTRANSFDEP
        FROM PCTRANSFDEP
       WHERE PCTRANSFDEP.NUMTRANSTRANSFSAIDA = PNUMTRANSTRANSF;

      SELECT COUNT(*)
        INTO vnREGTRANSFDEPDEVOL
        FROM PCTRANSFDEPDEVOL
       WHERE PCTRANSFDEPDEVOL.NUMTRANSTRANSFSAIDA = PNUMTRANSTRANSF;

    EXCEPTION
      WHEN OTHERS THEN
        vnREGTRANSFDEP      := 0;
        vnREGTRANSFDEPDEVOL := 0;
    END;

    IF (vnREGTRANSFDEP > 0) OR
       (vnREGTRANSFDEPDEVOL > 0)
    THEN
      vsRETORNO := 'RETIRA';
    END IF;
    ------------------------------------------------------------------------

    -- 2 -> TESTAR SE A NF É DE TRANSFERENCIA TV10 (316)
    BEGIN
      SELECT NVL(NUMPED,0)
        INTO vnNUMPEDTV10
        FROM PCNFSAID
       WHERE NUMTRANSVENDA = PNUMTRANSTRANSF
         AND CONDVENDA = 10;
    EXCEPTION
      WHEN OTHERS THEN
        vnNUMPEDTV10 := 0;
    END;

    IF (vnREGTRANSFDEP = 0) AND
       (vnREGTRANSFDEPDEVOL = 0) AND
       (vnNUMPEDTV10 <> 0)
    THEN
      vsRETORNO := 'TV10';
    END IF;
    ------------------------------------------------------------------------

    -- 3 -> TESTAR SE A NF É DE TRANSFERENCIA DE FILIAL VIRTUAL (1419 OU 1423)

    /*
    Autor       : Rafael Braga
    Solicitação : 0.060534.2014
    Data        : 04/06/2014
    Descrição   : Ajustado para verificar se a transação que é passada como argumento
                  realmente é uma transferência. A procedure tratava todas as
                  transações como se já fossem transferências.
    */
    /* início 0.060534.2014 */
    BEGIN
      SELECT CODOPER
        INTO vsCODOPER
        FROM PCMOV
       WHERE NUMTRANSVENDA = PNUMTRANSTRANSF
       AND ROWNUM = 1 ;
    EXCEPTION
      WHEN OTHERS THEN
        vsCODOPER := 'X';
    END;
    /* fim 0.060534.2014 */

    IF (vnREGTRANSFDEP = 0) AND
       (vnREGTRANSFDEPDEVOL = 0) AND
       (vnNUMPEDTV10 = 0) AND
       ((vsCODOPER = 'ET') OR (vsCODOPER = 'ST')) --0.060534.2014
    THEN
      vsRETORNO := 'VIRTUAL';
    END IF;

    ------------------------------------------------------------------------

    IF NVL(vsRETORNO,'X') = 'X' THEN
      vsRETORNO := 'NÃO É TRANSFERÊNCIA';
    END IF;

    RETURN vsRETORNO;

  END ORIGEM_TRANSFERENCIA;

  FUNCTION CLIENTES_DO_RCA(PCODUSUR IN NUMBER)
    RETURN TB_CLIENTES
    PIPELINED
  IS
    DADOS_SAIDA T_CLI;
  BEGIN

    FOR CLIENTES IN
    (SELECT CODCLI,
            CLIENTE
       FROM PCCLIENT
      WHERE (CODUSUR1 = PCODUSUR)
         OR (CODUSUR2 = PCODUSUR)
         OR (CODUSUR3 = PCODUSUR)
         OR (CODCLI IN (SELECT CODCLI FROM PCUSURCLI WHERE CODUSUR = PCODUSUR)))
    LOOP

      DADOS_SAIDA.CODCLI  := CLIENTES.CODCLI;
      DADOS_SAIDA.CLIENTE := CLIENTES.CLIENTE;
      PIPE ROW(DADOS_SAIDA);

    END LOOP;

    RETURN;

  END CLIENTES_DO_RCA;

  FUNCTION RCAS_DO_CLIENTE (PCODCLI IN NUMBER)
    RETURN TB_RCAS
    PIPELINED
  IS
    DADOS_SAIDA T_RCA;
  BEGIN

    FOR RCAS IN
    (SELECT PCUSUARI.CODUSUR,
            PCUSUARI.NOME
       FROM PCCLIENT, PCUSUARI
      WHERE PCCLIENT.CODUSUR1 = PCUSUARI.CODUSUR
        AND PCCLIENT.CODCLI = PCODCLI
     UNION
     SELECT PCUSUARI.CODUSUR,
            PCUSUARI.NOME
       FROM PCCLIENT, PCUSUARI
      WHERE PCCLIENT.CODUSUR2 = PCUSUARI.CODUSUR
        AND PCCLIENT.CODCLI = PCODCLI
      UNION
     SELECT PCUSUARI.CODUSUR,
            PCUSUARI.NOME
       FROM PCCLIENT, PCUSUARI
      WHERE PCCLIENT.CODUSUR3 = PCUSUARI.CODUSUR
        AND PCCLIENT.CODCLI = PCODCLI
     UNION
     SELECT PCUSUARI.CODUSUR,
            PCUSUARI.NOME
       FROM PCUSURCLI, PCUSUARI
      WHERE PCUSURCLI.CODUSUR = PCUSUARI.CODUSUR
        AND PCUSURCLI.CODCLI = PCODCLI)
    LOOP

      IF RCAS.CODUSUR IS NOT NULL THEN
        DADOS_SAIDA.CODRCA := RCAS.CODUSUR;
        DADOS_SAIDA.NOME   := RCAS.NOME;
        PIPE ROW(DADOS_SAIDA);
      END IF;

    END LOOP;

    RETURN;

  END RCAS_DO_CLIENTE;

  FUNCTION ESTOQUE_CB (PCODPROD   		 IN NUMBER   DEFAULT 0,
                       PCODFILIAL 		 IN VARCHAR2 DEFAULT '99',
					   P_CAMPO_CALCULADO IN VARCHAR2 DEFAULT 'N')
    RETURN TB_ESTOQUE
    PIPELINED
  IS
    MSG_RETORNO VARCHAR2(1000);
    DADOS_SAIDA                 T_ESTOQUE;

  BEGIN
     SELECT CODFILIAL
          ,CODPROD
          ,QTEST
          ,QTESTGER
          ,QTDISP
          ,QTDISP_CONT
          ,MSG_RETORNO
      INTO DADOS_SAIDA.CODFILIAL
          ,DADOS_SAIDA.CODPROD
          ,DADOS_SAIDA.QTEST
          ,DADOS_SAIDA.QTESTGER
          ,DADOS_SAIDA.QTDISP
          ,DADOS_SAIDA.QTDISP_CONT
          ,MSG_RETORNO
      FROM TABLE(PKG_ESTOQUE.ESTOQUE_DISPONIVEL_CB(PCODPROD, PCODFILIAL));

    IF (MSG_RETORNO <> 'OK') AND (P_CAMPO_CALCULADO = 'N')
    THEN
      RAISE_APPLICATION_ERROR(-20000, MSG_RETORNO);
    END IF;
    PIPE ROW(DADOS_SAIDA);

    RETURN;

  END ESTOQUE_CB;
------------------------------------------------------------------------------------

PROCEDURE MONTAR_CB(PCODPROD         IN     NUMBER   DEFAULT 0,
                    PCODFILIAL       IN     VARCHAR2 DEFAULT '99',
                    PQT              IN     NUMBER   DEFAULT 0,
                    PMSG             IN OUT VARCHAR,
                    PCODFILIALRETIRA IN     VARCHAR2 DEFAULT '99',
                    PCODFILIALNF     IN     VARCHAR2 DEFAULT '99',
                    PORIGEMPED       IN     VARCHAR2 DEFAULT '') IS

    vicont                      NUMBER;
    vnproxnumtransvenda         pcconsum.proxnumtransvenda%TYPE;
    vnproxnumtransent           pcconsum.proxnumtransent%TYPE;
    vsatualizaent1122           pcconsum.atualizaent1122%TYPE;
    vnqtde_produzida            NUMBER;
    vnqt_saida                  NUMBER;
    vncustorep_ant              pcest.custorep%TYPE;
    vncustofin_ant              pcest.custofin%TYPE;
    vncustoreal_ant             pcest.custoreal%TYPE;
    vncustoultent_ant           pcest.custoultent%TYPE;
    vnvalorultent_ant           pcest.valorultent%TYPE;
    vnqtestger_ant              pcest.qtestger%TYPE;
    vnqtest_ant                 pcest.qtest%TYPE;
    vnqtreserv_ant              pcest.qtreserv%TYPE;
    vnqtbloqueada_ant           pcest.qtbloqueada%TYPE;
    vsmensagem                  VARCHAR2(1000);
    vncodepto                   pcprodut.codepto%TYPE;
    vncodsec                    pcprodut.codsec%TYPE;
    vncodfornec                 pcprodut.codfornec%TYPE;
    vsmontarkitautomaticamente  pcfilial.montarkitautomaticamente%TYPE;
    vncustofin_entrada          pcest.custofin%TYPE;
    vncustoreal_entrada         pcest.custoreal%TYPE;
    vncustorep_entrada          pcest.custorep%TYPE;
    vnvalorultent_entrada       pcest.valorultent%TYPE;
    vncustoultent_entrada       pcest.custoultent%TYPE;
    vsconsideramontagemgiromerc pcfilial.consideramontagemgiromerc%TYPE;
    vndif                       NUMBER;
    vnReturn                    NUMBER;
    vnqtdisp                    NUMBER;
    vsBLOQUEIAVENDAESTPENDENTE  VARCHAR2(1);
    erro_estoque EXCEPTION;
    iTentativa                  NUMBER;

  BEGIN

     INSERT INTO PCLOGALTERACAODADOS
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
       OBSERVACOES2,
       PCLOGALTERACAODADOS.VALORNUMANT,
       PCLOGALTERACAODADOS.VALORNUM
       )
    VALUES
      (SYSDATE,
       'PCMOV',
       'PRODUZ_CESTA',
       'N',
       'PRODUZ_CESTA automatica de cesta',
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       'CODPROD CESTA ' || TO_CHAR(NVL(PCODPROD, 0)),
       ' CODFILIAL: ' || PCODFILIAL || ' QT: ' || TO_CHAR(PQT) || ' PCODFILIALRETIRA: ' || PCODFILIALRETIRA || ' PORIGEMPED: ' || PORIGEMPED,
       NVL(PCODPROD, 0),
       NVL(PCODPROD, 0)
       );

    SELECT NVL(pcfilial.montarkitautomaticamente, 'S')
      INTO vsmontarkitautomaticamente
      FROM pcfilial
     WHERE codigo = pcodfilial;

    vsBLOQUEIAVENDAESTPENDENTE := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_BLOQUEIAVENDAESTPENDENTE','99','N');

    IF vsmontarkitautomaticamente = 'N' THEN
      RETURN;
    END IF;

    vnproxnumtransvenda := ferramentas.F_PROX_NUMTRANSVENDA;

    iTentativa := 0;
    while iTentativa < 50 and vnproxnumtransvenda = 0
    loop
         vnproxnumtransvenda := ferramentas.F_PROX_NUMTRANSVENDA;
         if vnproxnumtransvenda > 0 then
           exit;
         end if;
        iTentativa := iTentativa+1;
    end loop;

    vnproxnumtransent   := ferramentas.F_PROX_NUMTRANSENT;
    iTentativa := 0;
    while iTentativa < 50 and vnproxnumtransent = 0
    loop
         vnproxnumtransent   := ferramentas.F_PROX_NUMTRANSENT;
         if vnproxnumtransent > 0 then
           exit;
         end if;
        iTentativa := iTentativa+1;
    end loop;


    FOR reg IN (SELECT PCODPROD,
                       PQT,
                       GREATEST(GREATEST(NVL(pcest.qtestger, 0), 0) -
                                GREATEST(NVL(qtreserv, 0), 0) -
                                GREATEST(NVL(qtbloqueada, 0), 0),
                                0) qtdisp,
                       NVL(PCODFILIALRETIRA, PCODFILIAL) codfilialretira
                  FROM pcprodut, pcest
                 WHERE NVL(pcprodut.tipomerc, 'X') = 'CB'
                   AND NVL(PQT, 0) > 0
                   AND NVL(PQT, 0) >
                       GREATEST(GREATEST(NVL(pcest.qtestger, 0), 0) -
                                GREATEST(NVL(qtreserv, 0), 0) -
                                GREATEST(NVL(qtbloqueada, 0), 0) -
                                DECODE(vsBLOQUEIAVENDAESTPENDENTE,'S',NVL(PCEST.QTPENDENTE,0),0),
                                0)
                   AND pcest.codfilial =  NVL(PCODFILIALRETIRA, PCODFILIAL)
                   AND PCODPROD = pcest.codprod
                   AND PCODPROD = pcprodut.codprod) LOOP

      vndif := 0;
      BEGIN
        if reg.qtdisp >= PQT then
            PMSG := 'OK';
            RETURN;
        end if;
        IF NVL(PORIGEMPED, 'T') <> 'A' THEN
          SELECT MAX((SELECT GREATEST(GREATEST(NVL(pcest.qtestger, 0), 0) -
                                      GREATEST(NVL(qtreserv, 0), 0) -
                                      GREATEST(NVL(qtbloqueada, 0), 0) -
                                      DECODE(vsBLOQUEIAVENDAESTPENDENTE,'S',NVL(PCEST.QTPENDENTE,0),0),
                                      0)
                        FROM pcest
                       WHERE pcest.codprod = pcformprod.codprodmp
                         AND pcest.codfilial =  NVL(PCODFILIALRETIRA, PCODFILIAL)) - (PQT * pcformprod.qtprodmp))
            INTO vndif
            FROM pcprodut, pcformprod
           WHERE pcprodut.codprod = PCODPROD
             AND pcformprod.codprodacab = PCODPROD
             AND (PQT * pcformprod.qtprodmp) >
                 (SELECT GREATEST(GREATEST(NVL(pcest.qtestger, 0), 0) -
                                  GREATEST(NVL(qtreserv, 0), 0) -
                                  GREATEST(NVL(qtbloqueada, 0), 0) -
                                  DECODE(vsBLOQUEIAVENDAESTPENDENTE,'S',NVL(PCEST.QTPENDENTE,0),0),
                                  0)
                    FROM pcest
                   WHERE pcest.codprod = pcformprod.codprodmp
                     AND pcest.codfilial = reg.codfilialretira)
             AND NVL(pcprodut.tipomerc, 'X') = 'CB';
        ELSE
          SELECT (NVL(pcest.qtestger, 0) - NVL(qtreserv, 0) - NVL(qtbloqueada, 0) -
                   DECODE(vsBLOQUEIAVENDAESTPENDENTE,'S',NVL(PCEST.QTPENDENTE,0),0)) -  PQT
           INTO vndif
            FROM pcprodut, pcest
          WHERE pcprodut.codprod = pcest.codprod
            and pcest.codfilial = reg.codfilialretira
            AND pcprodut.codprod = PCODPROD
            AND NVL(pcprodut.tipomerc, 'X') = 'CB';
        END IF;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
         vndif :=0;
      END;


      --Ajustado procedimento para atender o kit cesta parcialmente.
      IF (NVL(vndif, 0) / PQT) <> trunc((NVL(vndif, 0) / PQT)) THEN
        vndif := vndif + 1;
      END IF;

      -- não pode ser negativo
      vndif := greatest(vndif, 0);

      vnqtde_produzida := GREATEST(PQT -
                                   (reg.qtdisp +
                                   trunc((NVL(vndif, 0) / PQT))),
                                   0);
      ----------------********* SAIDA DE PRODUCAO ****************----------------
      BEGIN
        PMSG := 'OK';
        FOR reg_itens IN (SELECT pcformprod.codprodmp, pcformprod.qtprodmp
                            FROM pcformprod
                           WHERE pcformprod.codprodacab = PCODPROD) LOOP

          vnqt_saida := vnqtde_produzida * reg_itens.qtprodmp;

          SELECT codepto, codsec, codfornec
            INTO vncodepto, vncodsec, vncodfornec
            FROM pcprodut
           WHERE codprod = reg_itens.codprodmp;

          SELECT NVL(custorep, 0),
                 NVL(custofin, 0),
                 NVL(custoreal, 0),
                 NVL(custoultent, 0),
                 NVL(valorultent, 0),
                 NVL(qtestger, 0),
                 NVL(qtest, 0),
                 NVL(qtreserv, 0),
                 NVL(qtbloqueada, 0)
            INTO vncustorep_ant,
                 vncustofin_ant,
                 vncustoreal_ant,
                 vncustoultent_ant,
                 vnvalorultent_ant,
                 vnqtestger_ant,
                 vnqtest_ant,
                 vnqtreserv_ant,
                 vnqtbloqueada_ant
            FROM pcest
           WHERE codprod = reg_itens.codprodmp
             AND codfilial =  NVL(PCODFILIALRETIRA, PCODFILIAL);


        -----------------------------------------------------------
         --Autor:Rafael Soares
         --Solicitação: 3077.032401.2016
         --Data: 23/03/2016
         --Descrição: A baixa de estoque referente a montagem da cesta não pode utilizar a package de brinde, pois esta baixa o estoque reservado
         -- e a montade de Kits não pode apresentar esta comportamento
         -----------------------------------------------------------
         IF ((NVL(vnqt_saida, 0) >
               GREATEST(GREATEST(vnqtestger_ant, 0) -
                        GREATEST(vnqtreserv_ant, 0) -
                        GREATEST(vnqtbloqueada_ant, 0),
                        0)) or NVL(vnqt_saida,0) =0) AND
            (NVL(PORIGEMPED, 'X') <> 'A') THEN


           PMSG := 'PRODUTOS QUE COMPÕEM O KIT CESTA NÃO TEM ESTOQUE.';
           RETURN;
         end if;

         IF (vnproxnumtransvenda = 0) THEN
          PMSG := 'Não foi possível obter proxímo número de transação de venda, verifique se a tabela PCCONSUM está em uso.';
          RETURN;
         end if;

         IF (vnproxnumtransent = 0) THEN
           PMSG := 'Não foi possível obter proxímo número de transação de entrada, verifique se a tabela PCCONSUM está em uso.';
           RETURN;
         end if;

          -- GERACAO DE PCMOV
          INSERT INTO pcmov
            (dtmov, --1
             codprod, --2
             numnota, --3
             codoper, --4
             qt, --5
             punit, --6
             codfilial, --7
             status, --8
             codcli, --9
             codusur, --10
             custofin, --11
             numcar, --12
             numped, --13
             ptabela, --14
             numregiao, --15
             custocont, --16
             qtcont, --17
             punitcont,--18
             custoreal, --19
             codepto, --20
             codsec, --21
             custocontant, --22
             custorealant, --23
             custofinant,--24
             numtransent, --25
             numtransvenda, --26
             codfornec, --27
             codplpag, --28
             percvenda, --29
             qtestgerant, --30
             qtestant, --31
             custoultentant, --32
             MOVESTOQUEGERENCIAL, --33
             CODFILIALRETIRA, -- 34
             CODFILIALNF -- 35

             )
          VALUES
            (TRUNC(SYSDATE), --1
             reg_itens.codprodmp,
             --2
             0,
             --3
             'SP', --4
             vnqt_saida, --5
             vncustorep_ant, --6
             NVL(PCODFILIALRETIRA, PCODFILIAL) , --7
             'B', --8
             8888, --9
             0, --10
             vncustofin_ant, --11
             0, --12
             0, --13
             0, --14
             0, --15
             0, --16
             0, --17
             0, --18
             vncustoreal_ant, --19
             vncodepto, --20
             vncodsec, --21
             0, --22
             vncustoreal_ant, --23
             vncustofin_ant, --24
             vnproxnumtransent, --25
             vnproxnumtransvenda,--26
             vncodfornec, --27
             0,--28
             0, --29
             vnqtestger_ant, --30
             vnqtest_ant, --31
             vncustoultent_ant, --32
             'S', --33
             NVL(PCODFILIALRETIRA, PCODFILIAL),
             NVL(PCODFILIALRETIRA, PCODFILIAL)
             );

        --vnReturn := PKG_ESTOQUE.VENDAS_SAIDA(vnproxnumtransvenda, 'N',vsmensagem);

        END LOOP;
      EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK;
          IF vsmensagem IS NULL THEN
            vsmensagem := 'ERRO AO SELECIONAR ITENS DA CESTA.' || chr(13) ||
                          SQLCODE || ' ' || SQLERRM;
          END IF;
          RAISE;
      END;

      ---------------********* ENTRADA DE PRODUCAO *************----------------------

      --ATUALIZACAO DOS CUSTOS
      SELECT SUM(NVL(pcformprod.qtprodmp, 0) * NVL(pcest.custofin, 0)) custofin_entrada,
             SUM(NVL(pcformprod.qtprodmp, 0) * NVL(pcest.custoreal, 0)) custoreal_entrada,
             SUM(NVL(pcformprod.qtprodmp, 0) * NVL(pcest.custorep, 0)) custorep_entrada,
             SUM(NVL(pcformprod.qtprodmp, 0) * NVL(pcest.valorultent, 0)),
             SUM(NVL(pcformprod.qtprodmp, 0) * NVL(pcest.custoultent, 0))
        INTO vncustofin_entrada,
             vncustoreal_entrada,
             vncustorep_entrada,
             vnvalorultent_entrada,
             vncustoultent_entrada
        FROM pcformprod, pcest
       WHERE pcformprod.codprodacab = PCODPROD
         AND pcest.codfilial =  NVL(PCODFILIALRETIRA, PCODFILIAL)
         AND pcformprod.codprodmp = pcest.codprod;

      SELECT custofin, custoreal, custorep, custoultent, valorultent
        INTO vncustofin_ant,
             vncustoreal_ant,
             vncustorep_ant,
             vncustoultent_ant,
             vnvalorultent_ant
        FROM pcest
       WHERE codprod = PCODPROD
         AND codfilial =  NVL(PCODFILIALRETIRA, PCODFILIAL);

      INSERT INTO PCLOGALTERACAODADOS
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
       OBSERVACOES2,
       PCLOGALTERACAODADOS.VALORNUMANT,
       PCLOGALTERACAODADOS.VALORNUM
       )
    VALUES
      (SYSDATE,
       'PCMOV',
       'PRODUZ_CESTA',
       'N',
       'PRODUZ_CESTA automatica de cesta INSERT',
       SYS_CONTEXT('USERENV', 'TERMINAL'),
       SYS_CONTEXT('USERENV', 'HOST'),
       SYS_CONTEXT('USERENV', 'MODULE'),
       SYS_CONTEXT('USERENV', 'OS_USER'),
       'CODPROD CESTA ' || TO_CHAR(NVL(PCODPROD, 0)),
       ' reg.qtdisp: ' || reg.qtdisp || ' QT_PROD: ' || TO_CHAR(vnqtde_produzida) || ' vndif: ' || vndif || ' PQT: ' || PQT,
       NVL(PCODPROD, 0),
       NVL(PCODPROD, 0)
       );

      --GERACAO DE PCMOV CODOPER = 'EP'
      INSERT INTO pcmov
        (dtmov, --1
         codprod, --2
         numnota, --3
         codoper, --4
         qt, --5
         punit, --6
         codfilial, --7
         status, --8
         codcli, --9
         codusur, --10
         custofin, --11
         numcar, --12
         numped, --13
         ptabela, --14
         numregiao, --15
         custocont, --16
         qtcont, --17
         punitcont, --18
         custoreal, --19
         codepto, --20
         codsec, --21
         custocontant, --22
         custorealant, --23
         custofinant, --24
         numtransent, --25
         numtransvenda, --26
         codfornec, --27
         codplpag, --28
         percvenda,--29
         qtestgerant, --30
         qtestant, --31
         custoultentant, --32
         MOVESTOQUEGERENCIAL, --33
         CODFILIALRETIRA,
         CODFILIALNF
         )
      VALUES
        (TRUNC(SYSDATE), --1
         PCODPROD, --2
         0, --3
         'EP', --4
         vnqtde_produzida, --5
         vncustorep_entrada, --6
         NVL(PCODFILIALRETIRA, PCODFILIAL), --7
         'B', --8
         8888, --9
         0, --10
         vncustofin_entrada, --11
         0, --12
         0, --13
         0, --14
         0, --15
         0, --16
         0, --17
         0, --18
         vncustoreal_entrada, --19
         vncodepto, --20
         vncodsec, --21
         0, --22
         vncustoreal_ant, --23
         vncustofin_ant, --24
         vnproxnumtransent, --25
         null,--vnproxnumtransvenda, --26
         vncodfornec, --27
         0, --28
         0, --29
         vnqtestger_ant, --30
         vnqtest_ant, --31
         vncustoultent_ant, --32
         'S', --33
         NVL(PCODFILIALRETIRA, PCODFILIAL),
         NVL(PCODFILIALRETIRA, PCODFILIAL));

         --vnReturn := PKG_ESTOQUE.VENDAS_ENTRADA(vnproxnumtransent, 'N', vsmensagem);

    END LOOP;
    vnReturn := PKG_ESTOQUE.VENDAS_SAIDA(vnproxnumtransvenda, 'N',vsmensagem);
    vnReturn := PKG_ESTOQUE.VENDAS_ENTRADA(vnproxnumtransent, 'N', vsmensagem);


   -- voltando o codfilial
   update pcmov
      set codfilial = PCODFILIAL
        , CODFILIALNF = NVL(PCODFILIALNF, PCODFILIAL)
    where --numtransent   = vnproxnumtransent or
       numtransvenda = vnproxnumtransvenda;

    select GREATEST(GREATEST(NVL(pcest.qtestger, 0), 0) -
                    GREATEST(NVL(qtreserv, 0), 0) -
                    GREATEST(NVL(qtbloqueada, 0), 0) -
                    DECODE(vsBLOQUEIAVENDAESTPENDENTE,
                           'S',
                           NVL(PCEST.QTPENDENTE, 0),
                           0),
                    0) qtdisp
      into vnQtdisp
      from PCEST
     WHERE pcest.codfilial = NVL(PCODFILIALRETIRA, PCODFILIAL)
       AND PCODPROD = pcest.codprod;

     if vnQtdisp >= PQT then
       PMSG := 'OK';
     end if;

  END MONTAR_CB;


------------------------------------------------------------------------------------

  FUNCTION F_BUSCARPARAMETRO_ALFA(PNOMEPARAM   IN VARCHAR2,
                                  PCODFILIAL   IN VARCHAR2,
                                  PVALORSENULO IN VARCHAR2) RETURN VARCHAR2 IS
    vsVALORTEMP VARCHAR2(100);
  BEGIN

    SELECT NVL(VALOR, PVALORSENULO)
      INTO vsVALORTEMP
      FROM PCPARAMFILIAL
     WHERE UPPER(NOME) LIKE UPPER(PNOMEPARAM)
       AND CODFILIAL = PCODFILIAL;

    RETURN vsVALORTEMP;

  EXCEPTION
    WHEN OTHERS THEN

      RETURN PVALORSENULO;

  END F_BUSCARPARAMETRO_ALFA;

  ------------------------------------------------------------------------------------

  FUNCTION F_BUSCARPARAMETRO_NUM(PNOMEPARAM   IN VARCHAR2,
                                 PCODFILIAL   IN VARCHAR2,
                                 PVALORSENULO IN NUMBER) RETURN NUMBER IS
    vnVALORTEMP NUMBER;
  BEGIN

    SELECT NVL(TO_NUMBER(VALOR), PVALORSENULO)
      INTO vnVALORTEMP
      FROM PCPARAMFILIAL
     WHERE UPPER(NOME) LIKE UPPER(PNOMEPARAM)
       AND CODFILIAL = PCODFILIAL;

    RETURN vnVALORTEMP;

  EXCEPTION
    WHEN INVALID_NUMBER THEN

      RAISE_APPLICATION_ERROR(-20000,
                              'NÚMERO INVÁLIDO ATRIBUÍDO AO PARÂMETRO: "' ||
                              PNOMEPARAM ||
                              '". VERIFIQUE O SEPARADOR DECIMAL');

    WHEN OTHERS THEN

      RETURN PVALORSENULO;

  END F_BUSCARPARAMETRO_NUM;

  ------------------------------------------------------------------------------------

FUNCTION BUSCAR_ENDERECO_ENTREGA(pCodEndEnt IN number)
    RETURN T_ENDERECO_ENTREGA IS
    R_ENDERECO_ENTREGA T_ENDERECO_ENTREGA;
  BEGIN
    IF pCodEndEnt <= 0 THEN
      RETURN R_ENDERECO_ENTREGA;
    END IF;

    BEGIN
      SELECT A.CODENDENTCLI, NVL(A.NUMREGIAO, 0), A.ESTENT
        INTO R_ENDERECO_ENTREGA.CODENDENT,
             R_ENDERECO_ENTREGA.NUMREGIAO,
             R_ENDERECO_ENTREGA.ESTENT
        FROM PCCLIENTENDENT A
       WHERE A.CODENDENTCLI = pCodEndEnt;
    EXCEPTION
      WHEN OTHERS THEN
        R_ENDERECO_ENTREGA.CODENDENT := NULL;
        R_ENDERECO_ENTREGA.NUMREGIAO := NULL;
        R_ENDERECO_ENTREGA.ESTENT    := NULL;
    END;

    RETURN R_ENDERECO_ENTREGA;

  END;

FUNCTION BUSCAR_RAMO_ATIVIDADE(pCodAtivi IN NUMBER) RETURN T_RAMO_ATIVIDADE IS
    R_RAMO_ATIVIDADE T_RAMO_ATIVIDADE;
  BEGIN
    BEGIN
      SELECT NVL(PCATIVI.PERCREDALIQIPI, 0), NVL(PCATIVI.CALCULAST, 'S')
        INTO R_RAMO_ATIVIDADE.PercRedAliqIpi, R_RAMO_ATIVIDADE.CALCULAST
        FROM PCATIVI
       WHERE PCATIVI.CODATIV = pCodAtivi;
    EXCEPTION
      WHEN OTHERS THEN
        R_RAMO_ATIVIDADE.PercRedAliqIpi := 0;
        R_RAMO_ATIVIDADE.CALCULAST      := 'S';
    END;

    RETURN R_RAMO_ATIVIDADE;
  END;

  FUNCTION BUSCAR_CLIENTE(pCodCli             IN NUMBER,
                          pCODFILIALNF        IN VARCHAR2,
                          pCodEnderecoEntrega in number default 0,
                          pCodFilial          in varchar2 default null) RETURN T_CLIENTE IS
    R_CLIENTE          T_CLIENTE;
    R_ENDERECO_ENTREGA T_ENDERECO_ENTREGA;
  BEGIN
    SELECT PCCLIENT.CODCLI,
           NVL(PCCLIENT.CODCLIPRINC, PCCLIENT.CODCLI) CODCLIPRINC,
           NVL(PCCLIENT.CLASSEVENDA, 'X') CLASSEVENDA,
           NVL(PCCLIENT.TIPOFJ, 'F') TIPOFJ,
           NVL(PCCLIENT.CODREDE, -1) CODREDE,
           PCCLIENT.SIMPLESNACIONAL,
           NVL(PCCLIENT.CODATV1, -1) CODATV1,
           NVL(PCCLIENT.CODPRACA, -1) CODPRACA,
           NVL(PCCLIENT.Codcnae, -1) Codcnae,
           PCCLIENT.estent,
           NVL(PCCLIENT.calculast, 'N'),
           NVL(PCCLIENT.Clientefontest, 'N'),
           PCCLIENT.Usaivafontediferenciado,
           PCCLIENT.Ivafonte,
           PCCLIENT.ieent,
           PCCLIENT.utilizaiesimplificada,
           PCCLIENT.isentoipi,
           PCCLIENT.Isentoicms,
           PCCLIENT.sulframa,
           PCCLIENT.ISENCAOSUFRAMA,
           PCCLIENT.contribuinte,
           PCCLIENT.consumidorfinal,
           PCCLIENT.UTILIZACALCULOSTMT,
           PCCLIENT.TIPOEMPRESA,
           PCCLIENT.TIPODESCISENCAO,
           NVL(PCCLIENT.PERDESCISENTOICMS, 0),
           NVL(PCCLIENT.ORGAOPUB, 'N'),
           NVL(PCCLIENT.ORGAOPUBFEDERAL, 'N'),
           NVL(PCCLIENT.USADESCONTOICMS, 'N'),
           FERRAMENTAS.VERIFICAR_FJ(PCCLIENT.CODCLI),
           NVL((CASE
                 WHEN pCODFILIALNF IS NOT NULL THEN
                  (SELECT NUMREGIAO
                     FROM PCTABPRCLI
                    WHERE CODCLI = pCODCLI
                      AND CODFILIALNF = pCODFILIALNF)
                 ELSE
                  PCREGIAO.NUMREGIAO
               END),
               PCREGIAO.NUMREGIAO) AS NUMREGIAO,
           PCCLIENT.ORIGEMPRECO,
           PCCLIENT.VALIDARMULTIPLOVENDA,
           NVL(PCATIVI.PERCDESC, 0) PERDESCATIV,
           PCREGIAO.REGIAOZFM,
           PCCLIENT.REPASSE,
           PCCLIENT.TIPOCUSTOTRANSF,
           NVL(PCCLIENT.PERACRESTRANSF, 0) PERACRESTRANSF,
           PCCLIENT.codfilialnf,
           NVL(PCCLIENT.TIPOCUSTOMANIF, 'P') TIPOCUSTOMANIF
      INTO R_CLIENTE.CodCli,
           R_CLIENTE.CodCliPrinc,
           R_CLIENTE.ClasseVenda,
           R_CLIENTE.TipoPessoa,
           R_CLIENTE.CodRede,
           R_CLIENTE.SimplesNacional,
           R_CLIENTE.CodAtiv1,
           R_CLIENTE.CodPraca,
           R_CLIENTE.CodCnae,
           R_CLIENTE.EstEnt,
           R_CLIENTE.CalculaSt,
           R_CLIENTE.CalculaStFonte,
           R_CLIENTE.UsaivaFonteDiferenciado,
           R_CLIENTE.IvaFonte,
           R_CLIENTE.IEEnt,
           R_CLIENTE.Utilizaiesimplificada,
           R_CLIENTE.Isentoipi,
           R_CLIENTE.Isentoicms,
           R_CLIENTE.Sulframa,
           R_CLIENTE.IsencaoSuframa,
           R_CLIENTE.Contribuinte,
           R_CLIENTE.ConsumidorFinal,
           R_CLIENTE.UtilizaCalculoSTMT,
           R_CLIENTE.TipoEmpresa,
           R_CLIENTE.TipoDescIsencao,
           R_CLIENTE.PerDescIsentoICMS,
           R_CLIENTE.OrgaoPub,
           R_CLIENTE.OrgaoPubFederal,
           R_CLIENTE.UsaDescontoICMS,
           R_CLIENTE.PessoaFisicaJuridica,
           R_CLIENTE.NumRegiao,
           R_CLIENTE.OrigemPreco,
           R_CLIENTE.ValidarMultiploVenda,
           R_CLIENTE.perdescativ,
           R_CLIENTE.regiaozfm,
           R_CLIENTE.repasse,
           R_CLIENTE.TipoCustoTransf,
           R_CLIENTE.PerAcrescTransf,
           R_CLIENTE.CodFilialNf,
           R_CLIENTE.TIPOCUSTOMANIF
      FROM PCCLIENT, PCPRACA, PCREGIAO, PCATIVI
     WHERE CODCLI = pCodCli
       AND PCCLIENT.CODPRACA = PCPRACA.CODPRACA
       AND PCPRACA.NUMREGIAO = PCREGIAO.NUMREGIAO
       AND PCATIVI.CODATIV = PCCLIENT.CODATV1;

    R_CLIENTE.RamoAtividade := BUSCAR_RAMO_ATIVIDADE(R_CLIENTE.CodAtiv1);

    if (F_BUSCARPARAMETRO_ALFA('UTILIZATRIBENDENT', pCodFilial, 'N') = 'S') and (pCodEnderecoEntrega > 0) then
      R_ENDERECO_ENTREGA := BUSCAR_ENDERECO_ENTREGA(pCodEnderecoEntrega);
      if R_ENDERECO_ENTREGA.NUMREGIAO > 0 then
        R_CLIENTE.NumRegiao := R_ENDERECO_ENTREGA.NUMREGIAO;
      end if;
    end if;

    RETURN R_CLIENTE;
  END BUSCAR_CLIENTE;


------------------------------------------------------------------------------------
  FUNCTION BUSCAR_PLANO_PAGTO(pCodPlPag IN NUMBER) RETURN T_PLANO_PAGAMENTO IS
      R_PLANO_PAGAMENTO T_PLANO_PAGAMENTO;
    BEGIN
      SELECT PCPLPAG.CODPLPAG,
             PCPLPAG.DESCRICAO,
             NVL(PCPLPAG.NUMPR, 1) NUMPR,
             PCPLPAG.NUMDIAS,
             NVL(PCPLPAG.PERTXFIM, 0) PERTXFIM
        INTO R_PLANO_PAGAMENTO.CodPlPag,
             R_PLANO_PAGAMENTO.Descricao,
             R_PLANO_PAGAMENTO.NumPR,
             R_PLANO_PAGAMENTO.NumDias,
             R_PLANO_PAGAMENTO.PerTXFim
        FROM PCPLPAG
       WHERE CODPLPAG = pCodPlPag;
      RETURN R_PLANO_PAGAMENTO;
    END;

------------------------------------------------------------------------------------

  FUNCTION BUSCAR_PRODUTO (pCodProd IN NUMBER) RETURN T_PRODUTO
  IS
    R_PRODUTO T_PRODUTO;
    vnCodSec NUMBER;
  BEGIN
    SELECT
      PCPRODUT.CODPROD,
      PCPRODUT.DESCRICAO,
      NVL(PCPRODUT.CODPRODPRINC,PCPRODUT.CODPROD),
      NVL(PCPRODUT.CODCATEGORIA, -1) CODCATEGORIA,
      NVL(PCPRODUT.CODSUBCATEGORIA, -1) CODSUBCATEGORIA,
      NVL(PCPRODUT.CODFORNEC, -1) CODFORNEC,
      NVL(PCPRODUT.CODMARCA, -1) CODMARCA,
      NVL(PCPRODUT.CODSEC, -1) CODSEC,
      NVL(PCPRODUT.CODEPTO, -1) CODEPTO,
      NVL(PCPRODUT.CLASSE, 'A') CLASSE
    INTO
      R_PRODUTO.CodProd,
      R_PRODUTO.Descricao,
      R_PRODUTO.CodProdPrinc,
      R_PRODUTO.CodCategoria,
      R_PRODUTO.CodSubCategoria,
      R_PRODUTO.CodFornec,
      R_PRODUTO.CodMarca,
      R_PRODUTO.CodSec,
      R_PRODUTO.Codepto,
      R_PRODUTO.Classe
    FROM
      PCPRODUT
    WHERE
      CODPROD = pCodProd;

    RETURN R_PRODUTO;
  END;

------------------------------------------------------------------------------------

  FUNCTION BUSCAR_RCA (pCodUsur IN NUMBER) RETURN T_RCAS
  IS
    R_RCA T_RCAS;
  BEGIN
    SELECT
      PCUSUARI.CODUSUR,
      PCUSUARI.NOME,
      NVL(PCUSUARI.CODSUPERVISOR, -1) CODSUPERVISOR,
      NVL(PCUSUARI.AREAATUACAO, 'X') AREAATUACAO,
      NVL(PCUSUARI.VALIDARACRESCDESCPRECOFIXO, 'N')
    INTO
      R_RCA.CodUsur,
      R_RCA.Nome,
      R_RCA.CodSupervisor,
      R_RCA.AreaAtuacao,
      R_RCA.ValidarAcrescDescPrecoFixo
    FROM
      PCUSUARI
    WHERE
      CODUSUR = pCodUsur;
    RETURN R_RCA;
  END;
-------------------------------------------------------------------------------------
FUNCTION DESCONTO_CAB_VENDA_SIMUL(pCodCli      NUMBER,
                                  pCodPlPag    NUMBER,
                                  pCodUsur     NUMBER,
                                  pNumPed      NUMBER,
                                  pOrigemPed   VARCHAR2,
                                  pTipoCarga   VARCHAR2,
                                  pCodFilial   VARCHAR2,
                                  pCodFilialNF VARCHAR2,
                                  pDataPedido  DATE
                                                 )
    RETURN TD_DESCONTO_SIMUL
    PIPELINED
  IS

  R_DADOS  TR_DESC_SIMUL  := TR_DESC_SIMUL(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

  TYPE  R_DESC_SIMUL IS RECORD(
           PERCDESC         NUMBER,
           CODDESCONTO      NUMBER,
           CODEPTO          NUMBER,
           CODCATEGORIA     NUMBER,
           CODSUBCATEGORIA  NUMBER,
           CODSEC           NUMBER,
           CODFORNEC        NUMBER,
           CODMARCA         NUMBER,
           CODPRODPRINC     NUMBER,
           CODAUXILIAR      NUMBER,
           CLASSEPROD       VARCHAR2(2),
           DTINICIO         DATE,
           DTFIM            DATE,
           VLRMINIMO        NUMBER,
           VLRMAXIMO        NUMBER,
           PRODATEND        VARCHAR2(4000));

  TYPE T_DESCONTO_SIMUL IS TABLE OF R_DESC_SIMUL;

  DADOS_DESC   T_DESCONTO_SIMUL := T_DESCONTO_SIMUL();
  viCont       INTEGER          := 0;
  vnVltotalPed number(18,6);
  vbExiste     BOOLEAN          := FALSE;

BEGIN

  BEGIN
    SELECT SUM(NVL(I.QT,0) * NVL(I.PTABELA,0))
      INTO vnVltotalPed
      FROM PCPEDI I
     WHERE I.NUMPED = pNumPed
       AND NVL(I.BONIFIC, 'N') = 'N';
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;

  FOR DADOS IN (SELECT I.CODPROD
                      ,C.CODEPTO
                      ,C.CODCATEGORIA
                      ,C.CODSUBCATEGORIA
                      ,C.CODFORNEC
                      ,C.CODMARCA
                      ,C.CODPRODPRINC
                      ,C.CLASSE
                      ,I.CODAUXILIAR
                      ,I.QT
                  FROM PCPEDI   I
                      ,PCPRODUT C
                 WHERE I.NUMPED = pNumPed
                   AND I.CODPROD = C.CODPROD
                   AND NVL(I.BONIFIC, 'N') = 'N')
  LOOP

    FOR DESCONTO IN (SELECT C.CODEPTO,
                            C.CODCATEGORIA,
                            C.SUBCATEGORIA,
                            C.CODFORNEC,
                            C.CODMARCA,
                            C.CODPRODPRINC,
                            C.CLASSEPROD,
                            C.CODAUXILIAR,
                            C.PERCDESC,
                            C.CODDESCONTO,
                            C.DTINICIO,
                            C.DTFIM,
                            C.VLRMINIMO,
                            C.VLRMAXIMO,
                            C.CODSEC
                      FROM PCDESCONTO C, table(desconto_item_venda(pCodCli,
                                                                   DADOS.CODPROD,
                                                                   pCodPlPag,
                                                                   pCodUsur,
                                                                   0,
                                                                   vnVltotalPed,
                                                                   vnVltotalPed,
                                                                   1,
                                                                   pOrigemPed,
                                                                   pTipoCarga,
                                                                   pCodFilial,
                                                                   pDataPedido,
                                                                   'N',
                                                                   'N',
                                                                   vnVltotalPed,
                                                                   0,
                                                                   pCodFilialNF,
                                                                   '',
                                                                   0,
                                                                   DADOS.CODAUXILIAR,
                                                                   'S')) D
                     WHERE C.CODDESCONTO = D.CODESCONTO)
    LOOP
      vbExiste := FALSE;
      FOR viCont IN 1..DADOS_DESC.COUNT LOOP
        IF (NVL(DADOS_DESC(viCont).CODEPTO, -1)         = NVL(DESCONTO.CODEPTO, -1))      AND
           (NVL(DADOS_DESC(viCont).CODCATEGORIA, -1)    = NVL(DESCONTO.CODCATEGORIA, -1)) AND
           (NVL(DADOS_DESC(viCont).CODSUBCATEGORIA, -1) = NVL(DESCONTO.SUBCATEGORIA, -1)) AND
           (NVL(DADOS_DESC(viCont).CODFORNEC, -1)       = NVL(DESCONTO.CODFORNEC, -1))    AND
           (NVL(DADOS_DESC(viCont).CODMARCA, -1)        = NVL(DESCONTO.CODMARCA, -1))     AND
           (NVL(DADOS_DESC(viCont).CODPRODPRINC, -1)    = NVL(DESCONTO.CODPRODPRINC, -1)) AND
           (NVL(DADOS_DESC(viCont).CLASSEPROD, '+')     = NVL(DESCONTO.CLASSEPROD, '+'))  AND
           (NVL(DADOS_DESC(viCont).CODAUXILIAR, -1)     = NVL(DESCONTO.CODAUXILIAR, -1))  AND
           (NVL(DADOS_DESC(viCont).CODSEC, -1)          = NVL(DESCONTO.CODSEC, -1))
        THEN
          vbExiste := TRUE;
          DADOS_DESC(viCont).PRODATEND       := DADOS_DESC(viCont).PRODATEND || '-' || TO_CHAR(DADOS.CODPROD) || '-' ;
        END IF;
      END LOOP;

      IF NOT vbExiste THEN
        viCont := DADOS_DESC.COUNT + 1;
        DADOS_DESC.EXTEND;
        DADOS_DESC(viCont).CODEPTO         := DESCONTO.CODEPTO;
        DADOS_DESC(viCont).CODCATEGORIA    := DESCONTO.CODCATEGORIA;
        DADOS_DESC(viCont).CODSUBCATEGORIA := DESCONTO.SUBCATEGORIA;
        DADOS_DESC(viCont).CODFORNEC       := DESCONTO.CODFORNEC;
        DADOS_DESC(viCont).CODMARCA        := DESCONTO.CODMARCA;
        DADOS_DESC(viCont).CODPRODPRINC    := DESCONTO.CODPRODPRINC;
        DADOS_DESC(viCont).CLASSEPROD      := DESCONTO.CLASSEPROD;
        DADOS_DESC(viCont).CODAUXILIAR     := DESCONTO.CODAUXILIAR;
        DADOS_DESC(viCont).PERCDESC        := DESCONTO.PERCDESC;
        DADOS_DESC(viCont).CODDESCONTO     := DESCONTO.CODDESCONTO;
        DADOS_DESC(viCont).DTINICIO        := DESCONTO.DTINICIO;
        DADOS_DESC(viCont).DTFIM           := DESCONTO.DTFIM;
        DADOS_DESC(viCont).VLRMINIMO       := DESCONTO.VLRMINIMO;
        DADOS_DESC(viCont).VLRMAXIMO       := DESCONTO.VLRMAXIMO;
        DADOS_DESC(viCont).CODSEC          := DESCONTO.CODSEC;
        DADOS_DESC(viCont).PRODATEND       := '-'|| TO_CHAR(DADOS.CODPROD) || '-';

      END IF;
    END LOOP;
  END LOOP;

  FOR viCont IN 1..DADOS_DESC.COUNT LOOP
    R_DADOS.PERCATING       := 100; --campanhas que atingiram total
    R_DADOS.PERCDESC        := DADOS_DESC(viCont).PERCDESC;
    R_DADOS.CODDESCONTO     := DADOS_DESC(viCont).CODDESCONTO;
    R_DADOS.DTINICIO        := DADOS_DESC(viCont).DTINICIO;
    R_DADOS.DTFIM           := DADOS_DESC(viCont).DTFIM;
    R_DADOS.VLRMINIMO       := DADOS_DESC(viCont).VLRMINIMO;
    R_DADOS.VLRMAXIMO       := DADOS_DESC(viCont).VLRMAXIMO;
    R_DADOS.CODEPTO         := DADOS_DESC(viCont).CODEPTO;
    R_DADOS.CODCATEGORIA    := DADOS_DESC(viCont).CODCATEGORIA;
    R_DADOS.SUBCATEGORIA    := DADOS_DESC(viCont).CODSUBCATEGORIA;
    R_DADOS.CODFORNEC       := DADOS_DESC(viCont).CODFORNEC;
    R_DADOS.CODMARCA        := DADOS_DESC(viCont).CODMARCA;
    R_DADOS.CODPRODPRINC    := DADOS_DESC(viCont).CODPRODPRINC;
    R_DADOS.CLASSEPROD      := DADOS_DESC(viCont).CLASSEPROD;
    R_DADOS.PRODATEND       := DADOS_DESC(viCont).PRODATEND;
    R_DADOS.CODSEC          := DADOS_DESC(viCont).CODSEC;
    -- SALVANDO AS QUE ATENDERAM... EU ACHO..
    PIPE ROW(R_DADOS);
  END LOOP;

  R_DADOS.PRODATEND         := NULL;

  FOR NAO_ATENDIDO IN (SELECT C.CODEPTO,
                              C.CODCATEGORIA,
                              C.SUBCATEGORIA,
                              C.CODFORNEC,
                              C.CODMARCA,
                              C.CODPRODPRINC,
                              C.CLASSEPROD,
                              C.CODAUXILIAR,
                              C.PERCDESC,
                              C.CODDESCONTO,
                              C.DTINICIO,
                              C.DTFIM,
                              C.VLRMINIMO,
                              C.VLRMAXIMO,
                              C.CODSEC
                         FROM PCDESCONTO C
                        WHERE pDataPedido BETWEEN C.DTINICIO AND C.DTFIM
                          AND NVL(C.TIPO, 'C') = 'S'
                          AND C.VLRMINIMO > vnVltotalPed
                          AND ((C.CODFILIAL = pCodFilial) OR (C.CODFILIAL IS NULL)))
  LOOP
	FOR viCont IN 1..DADOS_DESC.COUNT LOOP

		IF (NVL(DADOS_DESC(viCont).CODEPTO, -1)         = NVL(NAO_ATENDIDO.CODEPTO, -1))      AND
             (NVL(DADOS_DESC(viCont).CODCATEGORIA, -1)    = NVL(NAO_ATENDIDO.CODCATEGORIA, -1)) AND
             (NVL(DADOS_DESC(viCont).CODSUBCATEGORIA, -1) = NVL(NAO_ATENDIDO.SUBCATEGORIA, -1)) AND
             (NVL(DADOS_DESC(viCont).CODFORNEC, -1)       = NVL(NAO_ATENDIDO.CODFORNEC, -1))    AND
             (NVL(DADOS_DESC(viCont).CODMARCA, -1)        = NVL(NAO_ATENDIDO.CODMARCA, -1))     AND
             (NVL(DADOS_DESC(viCont).CODPRODPRINC, -1)    = NVL(NAO_ATENDIDO.CODPRODPRINC, -1)) AND
             (NVL(DADOS_DESC(viCont).CLASSEPROD, '+')     = NVL(NAO_ATENDIDO.CLASSEPROD, '+'))  AND
             (NVL(DADOS_DESC(viCont).CODAUXILIAR, -1)     = NVL(NAO_ATENDIDO.CODAUXILIAR, -1))  AND
             (NVL(DADOS_DESC(viCont).CODSEC, -1)          = NVL(NAO_ATENDIDO.CODSEC, -1))
		THEN
			R_DADOS.PERCATING       := ROUND((vnVltotalPed/NAO_ATENDIDO.VLRMINIMO) * 100, 2); --campanhas que NÃO atingiram total
			R_DADOS.PERCDESC        := NAO_ATENDIDO.PERCDESC;
			R_DADOS.CODDESCONTO     := NAO_ATENDIDO.CODDESCONTO;
			R_DADOS.DTINICIO        := NAO_ATENDIDO.DTINICIO;
			R_DADOS.DTFIM           := NAO_ATENDIDO.DTFIM;
			R_DADOS.VLRMINIMO       := NAO_ATENDIDO.VLRMINIMO;
			R_DADOS.VLRMAXIMO       := NAO_ATENDIDO.VLRMAXIMO;
			R_DADOS.CODEPTO         := NAO_ATENDIDO.CODEPTO;
			R_DADOS.CODCATEGORIA    := NAO_ATENDIDO.CODCATEGORIA;
			R_DADOS.SUBCATEGORIA    := NAO_ATENDIDO.SUBCATEGORIA;
			R_DADOS.CODFORNEC       := NAO_ATENDIDO.CODFORNEC;
			R_DADOS.CODMARCA        := NAO_ATENDIDO.CODMARCA;
			R_DADOS.CODPRODPRINC    := NAO_ATENDIDO.CODPRODPRINC;
			R_DADOS.CLASSEPROD      := NAO_ATENDIDO.CLASSEPROD;
			R_DADOS.CODAUXILIAR     := NAO_ATENDIDO.CODAUXILIAR;
			R_DADOS.CODSEC          := NAO_ATENDIDO.CODSEC;
			-- SALVANDO AS QUE NÃO ATENDERAM... EU ACHO..
			PIPE ROW(R_DADOS);
		END IF;
	END LOOP;
  END LOOP;

  RETURN;


END DESCONTO_CAB_VENDA_SIMUL;

/*****************************************************************************************************************************************************
 *   RESPONSÁVEL          SOLICITAÇÃO      DATA            DESCRIÇÃO                                                                                 *
 *   Marcos Garcia        211232           26/06/2014      Inclusão do parêmeto pPVenda para tratar o desconto por faixa de valor                    *
 *   Rafael Braga         HIS.01775.2014   18/07/2014      Inclusão de parâmetros extras para cálculo do PBASERCA nessa melhoria de ST.              *
 *   Rafael Braga         3285.101879.2014 19/09/2014      Refatoração - remoção de funções de busca desnecessárias e ajuste para validar PCTABPRCLI.*
 *   Rafael Braga         2522.119155.2014 19/09/2014      Ajuste para não aplicar desconto no pbaserca quando CON_ACEITADESCPRECOFIXO = 'N'.        *
 *   Rafael Braga         1020.070835.2015 29/06/2014      Ajuste para calcular o preço de venda baseado no percentual enviado, para validar política*
                                                           por faixa de valor.                                                                       *
 *   Rafael Soares        5407.099950.2015 03/09/2015      Ajuste para que a rotina valide o parametro 1278 - Usar % desconto por quantidade         *
                                                           (CON_USADESCPORQUANT), o que faz a package não considerar politicas de desconto por qtd   *
                                                           quando este esta igual a 'N'
 *****************************************************************************************************************************************************/

FUNCTION DESCONTO_ITEM_VENDA(pCODCLI            NUMBER,
                             pCODPROD           NUMBER,
                             pCODPLPAG          NUMBER,
                             pCODUSUR           NUMBER,
                             pPERCDESCINFORMADO NUMBER,
                             pPTABELA           NUMBER,
                             pPTABELAAVISTA     NUMBER,
                             pQTITEM            NUMBER,
                             pORIGEMPED         VARCHAR2,
                             pTIPOCARGA         VARCHAR2,
                             pCODFILIAL         VARCHAR2,
                             pDATAPEDIDO        DATE,
                             pSomenteDescAut in VARCHAR2 default 'N',
                             pPrecoFixo      IN VARCHAR2 DEFAULT 'N',
                             pPVenda            NUMBER DEFAULT 0,
                             pDescontoPautado   NUMBER DEFAULT 0,
                             pCODFILIALNF       varchar2 default '',
                             pTipoDesc          varchar2 default '',
                             pCodDesconto       number default 0,
                             pCODAUXILIAR       PCEMBALAGEM.CODAUXILIAR%TYPE DEFAULT 0,
                             PSOMENTESIMULADOR  VARCHAR2 DEFAULT 'N',
                             pDIFESTOQUEMOVIMENTADO NUMBER DEFAULT 0,
                             pNUMPED                NUMBER DEFAULT 0,
                             pNUMSEQ                NUMBER DEFAULT 0,
                             psTipoOperacao         VARCHAR2 DEFAULT 'I',
                             pnNumeroOrcamento      NUMBER DEFAULT 0,
                             psTipoEntrega          VARCHAR2 DEFAULT '',
                             psTipoDesconto         VARCHAR2 DEFAULT '',
                             pnMatriculaFuncionario NUMBER DEFAULT 0,
                             pnCondvenda            PCPEDC.CONDVENDA%TYPE DEFAULT '',
                             psCalculaPrecoRCA      VARCHAR2 DEFAULT 'S')
    RETURN TD_DESCONTO_VENDA
    PIPELINED
  IS
    R_DADOS       TR_DESCONTO_VENDA := TR_DESCONTO_VENDA(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
    R_DESCONTO_VENDA_AUT PCDESCONTO%ROWTYPE;
    R_DESCONTO_VENDA_FLEX PCDESCONTO%ROWTYPE;
    R_DESCONTO_BASE  PCDESCONTO%ROWTYPE;
	vnPrecoMinimoAVista NUMBER;
    veERRO_BUSCAR_DESCONTO EXCEPTION;
    veERRO_DESC_N_PERMITIDO EXCEPTION;
    p_USADESCPORQUANT VARCHAR2(1);
	R_PCDESCONTOCONF PCDESCONTOCONF%ROWTYPE;
	
    PROCEDURE BUSCA_PCDESCONTOCONF IS
    BEGIN
      SELECT * INTO R_PCDESCONTOCONF FROM (SELECT * FROM PCDESCONTOCONF) WHERE ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        R_PCDESCONTOCONF.OBR_CODCLI := 'N';
        R_PCDESCONTOCONF.OBR_CODPROD := 'N';
        R_PCDESCONTOCONF.OBR_CODFILIAL := 'N';
        R_PCDESCONTOCONF.USA_CODCLI := 'S';
        R_PCDESCONTOCONF.USA_CODEPTO := 'S';
        R_PCDESCONTOCONF.USA_CODSEC := 'S';
        R_PCDESCONTOCONF.USA_CODCATEGORIA := 'S';
        R_PCDESCONTOCONF.USA_CODPROD := 'S';
        R_PCDESCONTOCONF.USA_CODUSUR := 'S';
        R_PCDESCONTOCONF.USA_CODPLPAG := 'S';
        R_PCDESCONTOCONF.USA_CODFORNEC := 'S';
        R_PCDESCONTOCONF.USA_CODSUPERVISOR := 'S';
        R_PCDESCONTOCONF.USA_NUMREGIAO := 'S';
        R_PCDESCONTOCONF.USA_CODATIV := 'S';
        R_PCDESCONTOCONF.USA_ORIGEMPED := 'S';
        R_PCDESCONTOCONF.USA_CODPRACA := 'S';
        R_PCDESCONTOCONF.USA_CODPRODPRINC := 'S';
        R_PCDESCONTOCONF.USA_CLASSEVENDA := 'S';
        R_PCDESCONTOCONF.USA_TIPOCARGA := 'S';
        R_PCDESCONTOCONF.USA_CODPRODCB := 'S';
        R_PCDESCONTOCONF.USA_AREAATUACAO := 'S';
        R_PCDESCONTOCONF.USA_CODFILIAL := 'S';
        R_PCDESCONTOCONF.USA_CODGRUPOPROD := 'S';
        R_PCDESCONTOCONF.USA_CODMARCA := 'S';
        R_PCDESCONTOCONF.USA_CODREDE := 'S';
        R_PCDESCONTOCONF.USA_CODCONDICAOVENDA := 'S';
        R_PCDESCONTOCONF.USA_TIPOFJ := 'S';
        R_PCDESCONTOCONF.USA_SUBCATEGORIA := 'S';
        R_PCDESCONTOCONF.USA_QTINIFIM := 'S';
        R_PCDESCONTOCONF.USA_CODGRUPOREST := 'S';
        R_PCDESCONTOCONF.USA_TIPOGRUPOREST := 'S';
        R_PCDESCONTOCONF.USA_VLRMINIMOMAXIMO := 'S';
        R_PCDESCONTOCONF.USA_CODAUXILIAR := 'S';
        R_PCDESCONTOCONF.USA_CLASSEPROD := 'S';
        R_PCDESCONTOCONF.USA_TIPOENTREGA := 'S';
        R_PCDESCONTOCONF.USA_APLICADESCSIMPLESNACIONAL := 'S';
        R_PCDESCONTOCONF.USA_TIPOAPLICDESCONTOCB := 'S';
        R_PCDESCONTOCONF.USA_QTDAPLICACOESDESC := 'S';
        R_PCDESCONTOCONF.USA_QTMINESTPARADESC := 'S';
        R_PCDESCONTOCONF.USA_NUMORCA := 'S';
      WHEN OTHERS THEN
        R_DADOS.MSG := 'Ocorreu erro ao buscar configuração do desconto no sistema.' ||chr(13)|| 'Erro original: '|| SQLERRM;
    END BUSCA_PCDESCONTOCONF;	

    FUNCTION SELECT_DESCONTO (p_DESCONTO IN OUT PCDESCONTO%ROWTYPE,
                              p_Somente_Base VARCHAR2,
                              p_somente_Prioritaria VARCHAR2 DEFAULT 'N',
                              P_SOMENTE_SIMULADOR VARCHAR2 DEFAULT 'N',
                              P_NumeroOrcamento NUMBER DEFAULT 0,
                              P_TipoEntrega VARCHAR2 DEFAULT '',
                              P_TipoDesconto VARCHAR2 DEFAULT '',
                              p_Condvenda PCPEDC.CONDVENDA%TYPE DEFAULT '') RETURN BOOLEAN
    IS
      vnSQL_DESCONTO VARCHAR2(8000);
    BEGIN
      --5407.099950.2015
      p_USADESCPORQUANT := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_USADESCPORQUANT','99','N');

      IF NOT(NVL(P_CONDVENDA, 1) = 10 AND Desconto.Cliente.TipoCustoTransf <> 'P') THEN

        IF pCodDesconto > 0 THEN
          vnSQL_DESCONTO := 'SELECT * FROM (SELECT * FROM PCDESCONTO WHERE CODDESCONTO = '|| pCodDesconto ||')';
        ELSE
          vnSQL_DESCONTO := 'SELECT * FROM (SELECT * FROM PCDESCONTO WHERE TO_DATE('''|| TO_CHAR(Desconto.Pedido.DataPedido, 'DD/MM/YYYY') ||''', ''DD/MM/YYYY'') BETWEEN DTINICIO AND DTFIM ';

          IF (R_PCDESCONTOCONF.USA_CODCLI = 'S') THEN
            IF (R_PCDESCONTOCONF.OBR_CODCLI = 'S') THEN
              vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND CODCLI = '|| Desconto.Cliente.CodCli;
            ELSE
              vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND ((CODCLI = DECODE(NVL(UTILIZADESCREDE, ''N''), ''N'', '|| Desconto.Cliente.CodCli ||','|| Desconto.Cliente.CodCliPrinc ||')) OR (CODCLI IS NULL))';
            END IF;
          END IF;

          IF (R_PCDESCONTOCONF.USA_CODEPTO = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND NVL(CODEPTO, '|| Desconto.Produto.CoDepto ||') = '|| Desconto.Produto.CoDepto;
          END IF;

          IF (R_PCDESCONTOCONF.USA_CODSEC = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND NVL(CODSEC, '|| Desconto.Produto.CodSec ||') = '|| Desconto.Produto.CodSec;
          END IF;

          IF (R_PCDESCONTOCONF.USA_CODCATEGORIA = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND NVL(CODCATEGORIA, '|| Desconto.Produto.CodCategoria ||') = '|| Desconto.Produto.CodCategoria;
          END IF;

          IF (R_PCDESCONTOCONF.USA_CODPROD = 'S') THEN
            IF (R_PCDESCONTOCONF.OBR_CODPROD = 'S') THEN
              vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND CODPROD = '|| Desconto.Produto.CodProd;
            ELSE
              vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND NVL(CODPROD, '|| Desconto.Produto.CodProd ||') = '|| Desconto.Produto.CodProd;
            END IF;
          END IF;

          IF (R_PCDESCONTOCONF.USA_CODUSUR = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND NVL(CODUSUR, '|| Desconto.RCA.CodUsur ||') = '|| Desconto.RCA.CodUsur;
          END IF;

          IF (R_PCDESCONTOCONF.USA_CODFORNEC = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND NVL(CODFORNEC, '|| Desconto.Produto.CodFornec ||') = '|| Desconto.Produto.CodFornec;
          END IF;

          IF (R_PCDESCONTOCONF.USA_CODSUPERVISOR = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND NVL(CODSUPERVISOR, '|| Desconto.RCA.CODSUPERVISOR ||') = '|| Desconto.RCA.CODSUPERVISOR;
          END IF;

          IF (R_PCDESCONTOCONF.USA_NUMREGIAO = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND NVL(NUMREGIAO, '|| Desconto.Cliente.NumRegiao ||') = '|| Desconto.Cliente.NumRegiao;
          END IF;

          IF (R_PCDESCONTOCONF.USA_CODATIV = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND NVL(CODATIV, '|| Desconto.Cliente.CodAtiv1 ||') = '|| Desconto.Cliente.CodAtiv1;
          END IF;

          IF (R_PCDESCONTOCONF.USA_ORIGEMPED = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND ((ORIGEMPED = '''|| Desconto.Pedido.OrigemPed ||''') OR (NVL(ORIGEMPED, ''O'') = ''O''))';
          END IF;

          IF (R_PCDESCONTOCONF.USA_CODPRACA = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND NVL(CODPRACA, '|| Desconto.Cliente.CodPraca ||') = '|| Desconto.Cliente.CodPraca;
          END IF;

          IF (R_PCDESCONTOCONF.USA_CODPRODPRINC = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND NVL(CODPRODPRINC, '|| Desconto.Produto.CodProdPrinc ||') = '|| Desconto.Produto.CodProdPrinc;
          END IF;

          IF (R_PCDESCONTOCONF.USA_CLASSEVENDA = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND NVL(CLASSEVENDA, '''|| Desconto.Cliente.ClasseVenda ||''') = '''|| Desconto.Cliente.ClasseVenda ||'''';
          END IF;

          IF (R_PCDESCONTOCONF.USA_TIPOCARGA = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND NVL(TIPOCARGA, '''|| Desconto.Pedido.TipoCarga ||''') = '''|| Desconto.Pedido.TipoCarga ||'''';
          END IF;

          IF (R_PCDESCONTOCONF.USA_CODPRODCB = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND NVL(CODPRODCB, '|| Desconto.Produto.CodProd ||') = '|| Desconto.Produto.CodProd;
          END IF;

          IF (R_PCDESCONTOCONF.USA_AREAATUACAO = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND NVL(AREAATUACAO, '''|| Desconto.RCA.AreaAtuacao ||''') = '''|| Desconto.RCA.AreaAtuacao ||'''';
          END IF;

          IF (R_PCDESCONTOCONF.USA_CODFILIAL = 'S') THEN
            IF (R_PCDESCONTOCONF.OBR_CODFILIAL = 'S') THEN
              vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND CODFILIAL = '|| Desconto.Pedido.CodFilial;
            ELSE
              vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND NVL(CODFILIAL, '|| Desconto.Pedido.CodFilial ||') = '|| Desconto.Pedido.CodFilial;
            END IF;
          END IF;

          IF (R_PCDESCONTOCONF.USA_CODMARCA = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||'  AND NVL(CODMARCA, '|| Desconto.Produto.CodMarca ||') = '|| Desconto.Produto.CodMarca;
          END IF;

          IF (R_PCDESCONTOCONF.USA_CODREDE = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||'  AND NVL(CODREDE, '|| Desconto.Cliente.CodRede ||') = '|| Desconto.Cliente.CodRede;
          END IF;

          IF (R_PCDESCONTOCONF.USA_TIPOFJ = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND ((TIPOFJ = '''|| Desconto.Cliente.TipoPessoa ||''') OR (NVL(TIPOFJ, ''A'') = ''A''))';
          END IF;

          IF (R_PCDESCONTOCONF.USA_SUBCATEGORIA = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND NVL(SUBCATEGORIA, '|| Desconto.Produto.CodSubCategoria ||') = '|| Desconto.Produto.CodSubCategoria;
          END IF;

          IF (R_PCDESCONTOCONF.USA_CODAUXILIAR = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||'  AND NVL(CODAUXILIAR, '|| NVL(pCODAUXILIAR, 0) ||') = '|| NVL(pCODAUXILIAR, 0);
          END IF;

          IF (R_PCDESCONTOCONF.USA_CLASSEPROD = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND NVL(CLASSEPROD, '''|| Desconto.Produto.Classe ||''') = '''|| Desconto.Produto.Classe ||'''';
          END IF;

          IF (R_PCDESCONTOCONF.USA_TIPOENTREGA = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||'   AND ((PCDESCONTO.TIPOENTREGA = '''|| P_TipoEntrega ||''') OR (PCDESCONTO.TIPOENTREGA IS NULL) OR (PCDESCONTO.TIPOENTREGA = ''T''))';
          END IF;

          IF (R_PCDESCONTOCONF.USA_CODPLPAG = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||
              '   AND (((NVL(APENASPLPAGMAX, ''S'') = ''N'') AND
                       ((SELECT PCPLPAG.NUMDIAS
                           FROM PCPLPAG
                          WHERE CODPLPAG = NVL(PCDESCONTO.CODPLPAG, '|| Desconto.PlanoPagamento.CodPlPag ||')) >= '|| Desconto.PlanoPagamento.NumDias ||'))
                    OR ((NVL(APENASPLPAGMAX, ''S'') = ''S'') AND
                       ((NVL(CODPLPAG, '|| Desconto.PlanoPagamento.CodPlPag ||') = '|| Desconto.PlanoPagamento.CodPlPag ||'))))';
          END IF;

          IF (R_PCDESCONTOCONF.USA_VLRMINIMOMAXIMO = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||
              '   AND DECODE(NVL(PCDESCONTO.VLRMINIMO, 0), 0, 0, PCDESCONTO.VLRMINIMO) <= '|| Desconto.Pedido.PVenda ||
              '   AND DECODE(NVL(PCDESCONTO.VLRMAXIMO, 0), 0, 9999999999, PCDESCONTO.VLRMAXIMO) >= '|| Desconto.Pedido.PVenda;
          END IF;

          IF (R_PCDESCONTOCONF.USA_APLICADESCSIMPLESNACIONAL = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||
              '   AND (((APLICADESCSIMPLESNACIONAL IS NULL) OR (APLICADESCSIMPLESNACIONAL = ''T'')) OR
                       ((APLICADESCSIMPLESNACIONAL = ''S'') AND ('''|| Desconto.Cliente.SimplesNacional ||''' = ''S'')) OR
                       ((APLICADESCSIMPLESNACIONAL = ''N'') AND ('''|| Desconto.Cliente.SimplesNacional ||''' <> ''S'')))';

          END IF;

          IF (R_PCDESCONTOCONF.USA_QTINIFIM = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||
              '   AND (('''|| p_USADESCPORQUANT ||''' = ''N'' AND ((NVL(PCDESCONTO.QTINI, 0) <= 0) AND (NVL(PCDESCONTO.QTFIM, 0) <= 0))) OR
                       ('''|| p_USADESCPORQUANT ||''' = ''S'' AND (
                         ((NVL(PCDESCONTO.QTINI, 0) <= '|| Desconto.Pedido.QtdeItem ||' AND
                           DECODE(NVL(PCDESCONTO.QTFIM, 0), 0, 9999999999, PCDESCONTO.QTFIM) >= '|| Desconto.Pedido.QtdeItem ||')) OR
                         ('''|| pTipoDesc ||''' = ''Q'' and '|| Desconto.Pedido.QtdeItem ||' = 0 AND NVL(PCDESCONTO.QTINI, 0) > 0 AND NVL(PCDESCONTO.QTFIM, 0) > 0)
                       ) AND CASE WHEN '''|| p_Somente_Base ||''' = ''S'' AND ALTERAPTABELA = ''S'' THEN ''N'' ELSE ''S'' END = ''S''))';
          END IF;

          IF (R_PCDESCONTOCONF.USA_CODGRUPOREST = 'S') OR (R_PCDESCONTOCONF.USA_TIPOGRUPOREST = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||
              '   AND (((CODGRUPOREST IS NULL) OR (TIPOGRUPOREST IS NULL)) OR
                       ((CODGRUPOREST = CASE WHEN(TIPOGRUPOREST = ''GR'') OR (TIPOGRUPOREST = ''CL'')
                                          THEN (SELECT PCGRUPOSCAMPANHAI.CODGRUPO
                                                  FROM PCGRUPOSCAMPANHAI
                                                 WHERE PCGRUPOSCAMPANHAI.DTEXCLUSAO IS NULL
                                                   AND PCGRUPOSCAMPANHAI.CODGRUPO = PCDESCONTO.CODGRUPOREST
                                                   AND PCGRUPOSCAMPANHAI.CODITEM = DECODE(PCDESCONTO.TIPOGRUPOREST,
                                                                                     ''CL'', '|| Desconto.cliente.CodCli ||',
                                                                                     ''GR'', '|| Desconto.RCA.CodUsur ||')
                                                   AND ROWNUM = 1)
                                          ELSE 0 END)))';
          END IF;

          IF (R_PCDESCONTOCONF.USA_CODGRUPOPROD = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||
              '   AND ((EXISTS (SELECT PCDESCONTOITEM.CODDESCONTO
                                  FROM PCDESCONTOITEM
                                 WHERE PCDESCONTOITEM.TIPO = ''GP''
                                   AND PCDESCONTOITEM.CODDESCONTO = PCDESCONTO.CODDESCONTO
                                   AND PCDESCONTOITEM.VALOR_NUM IN (SELECT PCGRUPOSCAMPANHAI.CODGRUPO
                                                                      FROM PCGRUPOSCAMPANHAI
                                                                     WHERE PCGRUPOSCAMPANHAI.CODITEM = '|| Desconto.Produto.CodProd ||'))
                       ) OR (NOT EXISTS (SELECT PCDESCONTOITEM.CODDESCONTO
                                           FROM PCDESCONTOITEM
                                          WHERE PCDESCONTOITEM.TIPO = ''GP''
                                            AND PCDESCONTOITEM.CODDESCONTO = PCDESCONTO.CODDESCONTO)))';
          END IF;

          IF (R_PCDESCONTOCONF.USA_QTDAPLICACOESDESC = 'S') THEN --HIS.03478.2016
            vnSQL_DESCONTO := vnSQL_DESCONTO ||
              '   AND (NVL(QTDAPLICACOESDESC,0) = 0 OR (CODPROD IS NOT NULL AND
                      (NVL(QTDAPLICACOESDESC,0) > 0 AND
                       NVL(QTDAPLICACOESDESC,0) >= NVl((SELECT SUM(QT)
                                                          FROM PCPEDI
                                                         WHERE CODPROD = PCDESCONTO.CODPROD
                                                           AND PCPEDI.POSICAO <> ''C''
                                                           AND PCPEDI.CODDESCONTO = PCDESCONTO.CODDESCONTO
                                                           AND PCPEDI.DATA BETWEEN PCDESCONTO.DTINICIO AND PCDESCONTO.DTFIM), 0) + '|| Desconto.Pedido.QtdeItem ||'
                                                 - NVL((SELECT qt
                                                          FROM PCPEDI
                                                         WHERE CODPROD = PCDESCONTO.CODPROD
                                                           AND NUMPED = '|| PNUMPED ||'
                                                           AND NUMSEQ = '|| PNUMSEQ ||'
                                                           AND CODDESCONTO = PCDESCONTO.CODDESCONTO), 0))))';
          END IF;

          IF (R_PCDESCONTOCONF.USA_QTMINESTPARADESC = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||
              '   AND (NVL(QTMINESTPARADESC,0) = 0 OR (CODPROD IS NOT NULL AND
                       NVL(QTMINESTPARADESC,0) > 0 AND
                       NVL(QTMINESTPARADESC,0) <= (SELECT QTDISP
                                                     FROM TABLE(VENDAS.ESTOQUE_DISPONIVEL(PCDESCONTO.CODPROD, '|| Desconto.Pedido.CodFilial ||', ''N''))) - '|| pDIFESTOQUEMOVIMENTADO ||'))';
          END IF;

          IF (R_PCDESCONTOCONF.USA_NUMORCA = 'S') THEN
            vnSQL_DESCONTO := vnSQL_DESCONTO ||
              '   AND ((CASE WHEN '|| P_NumeroOrcamento ||' > 0 THEN PCDESCONTO.NUMORCA ELSE 1 END =
                        CASE WHEN '|| P_NumeroOrcamento ||' > 0 THEN '|| P_NumeroOrcamento ||' ELSE 1 END) OR (PCDESCONTO.NUMORCA IS NULL))';
          END IF;

          --HIS.05126.2014
          vnSQL_DESCONTO := vnSQL_DESCONTO ||
            '   AND (((NVL('''|| P_SOMENTE_SIMULADOR ||''', ''N'') = ''S'') AND (NVL(TIPO, ''C'') = ''S'')) OR
                     ((NVL('''|| P_SOMENTE_SIMULADOR ||''', ''N'') = ''N'') AND (NVL(TIPO, ''C'') = ''C'')))

                AND CASE WHEN '''|| p_Somente_Base ||''' = ''N'' THEN NVL(PCDESCONTO.APLICADESCONTO, ''N'') ELSE ''1'' END =
                    CASE WHEN '''|| p_Somente_Base ||''' = ''N'' THEN '''|| Desconto.Pedido.SomenteDescAut ||''' ELSE ''1'' END

                --SE TIVER ENCONTRADO ALGUMA PRIORITARIA ANTES, DEVE BUSCAR APENAS PRIORITÁRIAS NA HORA DE BUSCAR PARA O PBASE.
                AND (('''|| p_somente_Prioritaria ||''' = ''S'' AND
                      CASE WHEN '''|| p_somente_Prioritaria ||''' = ''S'' THEN NVL(PCDESCONTO.PRIORITARIA,''N'') ELSE ''1'' END =
                      CASE WHEN '''|| p_somente_Prioritaria ||''' = ''S'' THEN ''S'' ELSE ''1'' END AND
                      CASE WHEN '''|| p_Somente_Base ||''' = ''S'' THEN NVL(PCDESCONTO.BASECREDDEBRCA,''N'') ELSE ''1'' END =
                      CASE WHEN '''|| p_Somente_Base ||''' = ''S'' THEN ''S'' ELSE ''1'' END)
                  OR ('''|| p_somente_Prioritaria ||''' = ''N'' AND
                      CASE WHEN '''|| p_Somente_Base ||''' = ''S'' THEN NVL(PCDESCONTO.BASECREDDEBRCA,''N'') ELSE ''1'' END =
                      CASE WHEN '''|| p_Somente_Base ||''' = ''S'' THEN ''S'' ELSE ''1'' END))

                AND (( '''|| p_Somente_Base ||''' = ''S'' and PERCDESC > 0) or '''|| p_Somente_Base ||''' = ''N'')

                AND (CASE WHEN '''|| P_TipoDesconto ||''' <> ''1'' THEN NVL(PCDESCONTO.TIPODESCONTO, ''O'') ELSE ''1'' END =
                     CASE WHEN '''|| P_TipoDesconto ||''' <> ''1'' THEN '''|| P_TipoDesconto ||''' ELSE ''1'' END)

                AND ((CODFUNC = '''|| Desconto.Funcionario.Matricula ||''') OR (CODFUNC IS NULL))

                AND PCDESCONTO.PERCDESC IS NOT NULL

              ORDER BY NVL(PCDESCONTO.PRIORITARIAGERAL, ''N'') DESC,
                       NVL(PCDESCONTO.PRIORITARIA, ''N'') DESC,
                       NVL(PCDESCONTO.PERCDESC, 0) DESC,
                       NVL(PCDESCONTO.ALTERAPTABELA, ''N'') DESC
          ) WHERE ROWNUM = 1';
        END IF;

        EXECUTE IMMEDIATE vnSQL_DESCONTO
           INTO p_DESCONTO;
      END IF;

      RETURN TRUE;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN TRUE;
      WHEN OTHERS THEN
        R_DADOS.MSG := 'Ocorreu erro ao buscar desconto no sistema.' ||chr(13)|| 'Erro original: '|| SQLERRM;
      RETURN FALSE;
    END SELECT_DESCONTO;

  BEGIN
    BUSCA_PCDESCONTOCONF;
  
    Desconto.Parametros132.NumCasasDecimais         := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_NUMCASASDECVENDA','99',2);
    Desconto.Cliente                                := BUSCAR_CLIENTE(pCODCLI, pCODFILIALNF);
    Desconto.PlanoPagamento                         := BUSCAR_PLANO_PAGTO(pCODPLPAG);
    IF pCODPROD > 0 THEN
      Desconto.Produto                              := BUSCAR_PRODUTO(pCODPROD);
    ELSE
      Desconto.Produto.CodProd                      := 0;
      Desconto.Produto.CodProdPrinc                 := 0;
      Desconto.Produto.CodCategoria                 := 0;
      Desconto.Produto.CodSubCategoria              := 0;
      Desconto.Produto.CodFornec                    := 0;
      Desconto.Produto.CodMarca                     := 0;
      Desconto.Produto.CodSec                       := 0;
      Desconto.Produto.Codepto                      := 0;
      Desconto.Produto.Classe                       := 'A';
    END IF;
    Desconto.RCA                                    := BUSCAR_RCA(pCODUSUR);
    Desconto.Precificacao.PrecoTabela               := pPTABELA;
    Desconto.Precificacao.PrecoTabelaAVista         := pPTABELAAVISTA;
    Desconto.Pedido.QtdeItem                        := pQTITEM;
    Desconto.Pedido.OrigemPed                       := NVL(pORIGEMPED, 'T');
    Desconto.Pedido.TipoCarga                       := NVL(pTIPOCARGA, 'X');
    Desconto.Pedido.CodFilial                       := NVL(pCODFILIAL, '-1');
    Desconto.Pedido.DataPedido                      := pDATAPEDIDO;
    Desconto.Pedido.PercDescInformado               := pPERCDESCINFORMADO;
    Desconto.Pedido.PVenda                          := Round((pPTABELA * (1 - (pPERCDESCINFORMADO/100))  * pQTITEM ), Desconto.Parametros132.NumCasasDecimais);
    Desconto.Parametros132.TratarRestricaoAcrescimo := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_TRATARRESTRICAOACRESCIMO','99','N');
    Desconto.Parametros132.NumCasasDecimais         := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_NUMCASASDECIMAIS','99',0);
    Desconto.Parametros132.AceitaDescontoPrecoFixo  := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_ACEITADESCPRECOFIXO','99',0);
    R_DADOS.PTABELADESC := Desconto.Precificacao.PrecoTabela;
    IF pnMatriculaFuncionario > 0 THEN
      Desconto.Funcionario.Matricula := pnMatriculaFuncionario;
    END IF;

    /* Buscando o desconto automático */
    Desconto.Pedido.SomenteDescAut                  := 'S';
    IF NOT (SELECT_DESCONTO(R_DESCONTO_VENDA_AUT, 'N', 'N', PSOMENTESIMULADOR, pnNumeroOrcamento, psTipoEntrega, psTipoDesconto, pnCondvenda)) THEN
      RAISE veERRO_BUSCAR_DESCONTO;
    END IF;
    /*Fim Buscando o desconto automático */

    /* Buscando o desconto flexivel */
    Desconto.Pedido.SomenteDescAut := pSomenteDescAut;
    if (Desconto.Pedido.SomenteDescAut = 'N') then
      IF NOT (SELECT_DESCONTO(R_DESCONTO_VENDA_FLEX, 'N', 'N', PSOMENTESIMULADOR, pnNumeroOrcamento, psTipoEntrega, psTipoDesconto, pnCondvenda)) THEN
        RAISE veERRO_BUSCAR_DESCONTO;
      END IF;
   end if;
    /* Fim Buscando o desconto flexivel */

    /* Definindo quais politica será utilizada (Prioritaria e Prioritaria Geral) */
    IF (R_DESCONTO_VENDA_AUT.PRIORITARIAGERAL = 'S') AND
       (R_DESCONTO_VENDA_FLEX.PRIORITARIAGERAL = 'S') THEN
      IF (NVL(R_DESCONTO_VENDA_AUT.PERCDESC, 0) >= NVL(R_DESCONTO_VENDA_FLEX.PERCDESC, 0)) THEN
        R_DESCONTO_VENDA_FLEX := NULL;
        R_DADOS.FORCARUTILIZACAO := NVL(R_DESCONTO_VENDA_AUT.PRIORITARIAGERAL, 'N');
      ELSE
        R_DESCONTO_VENDA_AUT := NULL;
        R_DADOS.FORCARUTILIZACAO := NVL(R_DESCONTO_VENDA_FLEX.PRIORITARIAGERAL, 'N');
      END IF;
    ELSIF (R_DESCONTO_VENDA_AUT.PRIORITARIAGERAL = 'S') OR
       (R_DESCONTO_VENDA_FLEX.PRIORITARIAGERAL = 'S') THEN
      IF (R_DESCONTO_VENDA_AUT.PRIORITARIAGERAL = 'S') AND
         (NVL(R_DESCONTO_VENDA_AUT.PERCDESC, 0) > 0) THEN
        R_DESCONTO_VENDA_FLEX := NULL;
        R_DADOS.FORCARUTILIZACAO := NVL(R_DESCONTO_VENDA_AUT.PRIORITARIAGERAL, 'N');
      END IF;

      IF (R_DESCONTO_VENDA_FLEX.PRIORITARIAGERAL = 'S') AND
         (NVL(R_DESCONTO_VENDA_FLEX.PERCDESC, 0) > 0) THEN
        R_DESCONTO_VENDA_AUT := NULL;
        R_DADOS.FORCARUTILIZACAO := NVL(R_DESCONTO_VENDA_FLEX.PRIORITARIAGERAL, 'N');
      END IF;
    ELSIF (R_DESCONTO_VENDA_AUT.PRIORITARIA = 'S') AND
          (R_DESCONTO_VENDA_FLEX.PRIORITARIA = 'S') THEN
      IF (NVL(R_DESCONTO_VENDA_AUT.PERCDESC, 0) >= NVL(R_DESCONTO_VENDA_FLEX.PERCDESC, 0)) THEN
        R_DESCONTO_VENDA_FLEX := NULL;
      ELSE
        R_DESCONTO_VENDA_AUT := NULL;
      END IF;
     ELSIF (R_DESCONTO_VENDA_AUT.PRIORITARIA = 'S') OR
       (R_DESCONTO_VENDA_FLEX.PRIORITARIA = 'S') THEN
      IF (R_DESCONTO_VENDA_AUT.PRIORITARIA = 'S') AND
         (NVL(R_DESCONTO_VENDA_AUT.PERCDESC, 0) > 0) THEN
        R_DESCONTO_VENDA_FLEX := NULL;
      END IF;

      IF (R_DESCONTO_VENDA_FLEX.PRIORITARIA = 'S') AND
         (NVL(R_DESCONTO_VENDA_FLEX.PERCDESC, 0) > 0) THEN
        R_DESCONTO_VENDA_AUT := NULL;
      END IF;
    END IF;
    /* Fim Definindo quais politica será utilizada (Prioritaria e Prioritaria Geral) */


    /*Definindo os dados do desconto e percentuais aplicados */
    IF (R_DESCONTO_VENDA_AUT.APLICADESCONTO = 'S') THEN
      IF DESCONTO.PLANOPAGAMENTO.NUMPR = 1 AND NVL(R_DESCONTO_VENDA_AUT.PERCDESCMAX,0) > 0 THEN
        R_DADOS.PERCDESCAUT   := R_DESCONTO_VENDA_AUT.PERCDESCMAX;
      ELSE
         R_DADOS.PERCDESCAUT   := R_DESCONTO_VENDA_AUT.PERCDESC;
      END IF;
    ELSE
      R_DADOS.PERCDESCAUT := 0;
    END IF;
    R_DADOS.ALTERAPTABELA := NVL(R_DESCONTO_VENDA_AUT.ALTERAPTABELA,'N');

    IF (DESCONTO.Pedido.PercDescInformado > NVL(R_DESCONTO_VENDA_FLEX.PERCDESC,0)) and
       (DESCONTO.Pedido.PercDescInformado > NVL(R_DADOS.PERCDESCAUT,0)) THEN
      R_DADOS.MSG          := 'O Desconto informado é maior que o permitido no sistema!'||chr(13)||
                              'Máximo desconto: ' || R_DESCONTO_VENDA_FLEX.PERCDESC ||'.';
    END IF;

    IF (R_DESCONTO_VENDA_AUT.ALTERAPTABELA = 'S') THEN
	
	   IF psTipoOperacao = 'I' THEN
		IF DESCONTO.PLANOPAGAMENTO.NUMPR = 1 AND NVL(R_DESCONTO_VENDA_AUT.PERCDESCMAX,0) > 0 THEN
           R_DADOS.PTABELADESC        := (DESCONTO.PRECIFICACAO.PRECOTABELA * (1 - (R_DESCONTO_VENDA_AUT.PERCDESCMAX/100)));
          ELSE
           R_DADOS.PTABELADESC        := (DESCONTO.PRECIFICACAO.PRECOTABELA * (1 - (R_DESCONTO_VENDA_AUT.PERCDESC/100)));
        END IF;
       ELSE
         R_DADOS.PTABELADESC        := Desconto.Precificacao.PrecoTabela;
       END IF;
      R_DADOS.CODESCONTO         := R_DESCONTO_VENDA_AUT.CODDESCONTO;
      R_DADOS.CODESCONTOPTABELA  := R_DESCONTO_VENDA_AUT.CODDESCONTO;
      R_DADOS.DATAINICIO         := R_DESCONTO_VENDA_AUT.Dtinicio;
      R_DADOS.DATAFINAL          := R_DESCONTO_VENDA_AUT.DTFIM;
      R_DADOS.QTINI              := R_DESCONTO_VENDA_AUT.QTINI;
      R_DADOS.QTFIM              := R_DESCONTO_VENDA_AUT.QTFIM;
      R_DADOS.VLRMINIMO          := R_DESCONTO_VENDA_AUT.VLRMINIMO;
      R_DADOS.VLRMAXIMO          := R_DESCONTO_VENDA_AUT.VLRMAXIMO;
      R_DADOS.QUESTIONAUSO       := R_DESCONTO_VENDA_AUT.QUESTIONAUSOPRIORITARIA;
      R_DADOS.PERCDESC           := 0;
      IF (NVL(R_DESCONTO_VENDA_FLEX.PERCDESC,0) > 0) THEN
        IF (NVL(DESCONTO.Pedido.PercDescInformado, 0) <= NVL(R_DESCONTO_VENDA_FLEX.PERCDESC,0) - (CASE R_DADOS.ALTERAPTABELA WHEN 'S' THEN  0 ELSE R_DADOS.PERCDESCAUT END)) THEN
          R_DADOS.PERCDESC     := NVL(DESCONTO.Pedido.PercDescInformado,0);
        ELSE
           R_DADOS.PERCDESC    := NVL(R_DESCONTO_VENDA_FLEX.PERCDESC,0)- (CASE R_DADOS.ALTERAPTABELA WHEN 'S' THEN  0 ELSE R_DADOS.PERCDESCAUT END);
        END IF;
        R_DADOS.CODESCONTO   := R_DESCONTO_VENDA_FLEX.CODDESCONTO;
        R_DADOS.DATAFINAL    := R_DESCONTO_VENDA_FLEX.DTFIM;
        R_DADOS.DATAINICIO   := R_DESCONTO_VENDA_FLEX.DTINICIO;
        IF R_DESCONTO_VENDA_AUT.QTINI IS NULL THEN
          R_DADOS.QTINI        := R_DESCONTO_VENDA_FLEX.QTINI;
        END IF;
        IF R_DESCONTO_VENDA_AUT.QTFIM IS NULL THEN
          R_DADOS.QTFIM        := R_DESCONTO_VENDA_FLEX.QTFIM;
        END IF;
        R_DADOS.VLRMINIMO    := R_DESCONTO_VENDA_FLEX.VLRMINIMO;
        R_DADOS.VLRMAXIMO    := R_DESCONTO_VENDA_FLEX.VLRMAXIMO;
        IF DESCONTO.PLANOPAGAMENTO.NUMPR = 1 THEN
         R_DADOS.PERCDESCMAX  := R_DESCONTO_VENDA_AUT.PERCDESCMAX;
        ELSE
         R_DADOS.PERCDESCMAX  := R_DESCONTO_VENDA_FLEX.PERCDESC; --ORIGEM DO PREÇO
        END IF;
        R_DADOS.QUESTIONAUSO := R_DESCONTO_VENDA_FLEX.QUESTIONAUSOPRIORITARIA;
      END IF;
	  
	  IF((DESCONTO.PLANOPAGAMENTO.NUMPR = 1) AND (NVL(R_DESCONTO_VENDA_AUT.PERCDESCMAX,0) > 0 ))THEN
         R_DADOS.PERCDESCMAX  := R_DESCONTO_VENDA_AUT.PERCDESCMAX;
        ELSE
         R_DADOS.PERCDESCMAX  := R_DESCONTO_VENDA_FLEX.PERCDESC; --ORIGEM DO PREÇO
      END IF;
	  
    ELSIF (NVL(R_DESCONTO_VENDA_FLEX.PERCDESC,0) > NVL(R_DESCONTO_VENDA_AUT.PERCDESC,0)) THEN
      IF (NVL(DESCONTO.Pedido.PercDescInformado,0) <= NVL(R_DESCONTO_VENDA_FLEX.PERCDESC,0)- (CASE R_DADOS.ALTERAPTABELA WHEN 'S' THEN  0 ELSE R_DADOS.PERCDESCAUT END)) AND
         (R_DESCONTO_VENDA_FLEX.APLICADESCONTO = 'N') THEN
        R_DADOS.PERCDESC     := NVL(DESCONTO.Pedido.PercDescInformado,0);
      ELSE
        IF (NVL(DESCONTO.Pedido.PercDescInformado,0) <= NVL(R_DESCONTO_VENDA_FLEX.PERCDESC,0)- (CASE R_DADOS.ALTERAPTABELA WHEN 'S' THEN  0 ELSE R_DADOS.PERCDESCAUT END)) THEN
          R_DADOS.PERCDESC     := NVL(DESCONTO.Pedido.PercDescInformado,0);
        ELSE
          R_DADOS.PERCDESC    := NVL(R_DESCONTO_VENDA_FLEX.PERCDESC,0)- (CASE R_DADOS.ALTERAPTABELA WHEN 'S' THEN  0 ELSE R_DADOS.PERCDESCAUT END);
        END IF;
      END IF;
      R_DADOS.CODESCONTO   := R_DESCONTO_VENDA_FLEX.CODDESCONTO;
      R_DADOS.DATAFINAL    := R_DESCONTO_VENDA_FLEX.DTFIM;
      R_DADOS.DATAINICIO   := R_DESCONTO_VENDA_FLEX.DTINICIO;
      R_DADOS.QTINI        := R_DESCONTO_VENDA_FLEX.QTINI;
      R_DADOS.PERCDESCMAX  := R_DESCONTO_VENDA_FLEX.PERCDESC; --origem do preço
      R_DADOS.QTFIM        := R_DESCONTO_VENDA_FLEX.QTFIM;
      R_DADOS.VLRMINIMO    := R_DESCONTO_VENDA_AUT.VLRMINIMO;
      R_DADOS.VLRMAXIMO    := R_DESCONTO_VENDA_AUT.VLRMAXIMO;
      R_DADOS.QUESTIONAUSO := R_DESCONTO_VENDA_FLEX.QUESTIONAUSOPRIORITARIA;
    ELSE
      R_DADOS.PERCDESC           := 0;
      R_DADOS.CODESCONTO         := R_DESCONTO_VENDA_AUT.CODDESCONTO;
      R_DADOS.CODESCONTOPTABELA  := R_DESCONTO_VENDA_AUT.CODDESCONTO;
      R_DADOS.DATAFINAL          := R_DESCONTO_VENDA_AUT.DTFIM;
      R_DADOS.DATAINICIO         := R_DESCONTO_VENDA_AUT.Dtinicio;
      R_DADOS.QUESTIONAUSO       := R_DESCONTO_VENDA_AUT.QUESTIONAUSOPRIORITARIA;
      R_DADOS.QTINI              := R_DESCONTO_VENDA_AUT.QTINI;
      R_DADOS.QTFIM              := R_DESCONTO_VENDA_AUT.QTFIM;
    END IF;

   /* Definindo máximo desconto no preço a vista */
   IF R_DESCONTO_VENDA_AUT.PERCDESCMAX > 0 OR R_DESCONTO_VENDA_FLEX.PERCDESCMAX > 0 THEN
     Desconto.Precificacao.PrecoTabela := R_DADOS.PTABELADESC;
     if R_DESCONTO_VENDA_AUT.ALTERAPTABELA = 'S' then
       Desconto.Precificacao.PrecoTabelaAVista := R_DADOS.PTABELADESC;
     end if;
   END IF;
   /*Caso seja acréscimo, não alterar novamente o PTABELADESC pois isso
   faz o pbaserca ficar incorreto - 4648.088849.2016 */
   IF (R_DADOS.PERCDESC > 0) and (NVL(R_DESCONTO_VENDA_AUT.Percdesc,0) >= 0) THEN
      R_DADOS.PTABELADESC := (R_DADOS.PTABELADESC * (1 - (R_DADOS.PERCDESC/100)));
    END IF;
    /*Definindo os dados do desconto e percentuais aplicados */

   /* Definindo máximo desconto no preço a vista */
   IF NVL(R_DESCONTO_VENDA_AUT.PERCDESCMAX,0) > 0 OR NVL(R_DESCONTO_VENDA_FLEX.PERCDESCMAX,0) > 0 THEN
     IF NVL(R_DESCONTO_VENDA_AUT.PERCDESCMAX,0) > NVL(R_DESCONTO_VENDA_FLEX.PERCDESCMAX,0) THEN
        vnPrecoMinimoAVista := (Desconto.Precificacao.PrecoTabelaAVista -
                               (Desconto.Precificacao.PrecoTabelaAVista *
                               (R_DESCONTO_VENDA_AUT.PERCDESCMAX / 100)));
     ELSE
        vnPrecoMinimoAVista := (Desconto.Precificacao.PrecoTabelaAVista -
                               (Desconto.Precificacao.PrecoTabelaAVista *
                               (R_DESCONTO_VENDA_FLEX.PERCDESCMAX / 100)));
     END IF;
   END IF;

    if (Desconto.Precificacao.PrecoTabela = Desconto.Precificacao.PrecoTabelaAVista)
    then
      if (Desconto.Precificacao.PrecoTabelaAVista) <= (vnPrecoMinimoAVista)
      then
        R_DADOS.PTABELADESC := Desconto.Precificacao.PrecoTabelaAVista;
      elsif (R_DADOS.PTABELADESC) < (vnPrecoMinimoAVista)
      then
        R_DADOS.PTABELADESC := vnPrecoMinimoAVista;
        IF NVL(R_DESCONTO_VENDA_AUT.PERCDESCMAX,0) > NVL(R_DESCONTO_VENDA_FLEX.PERCDESCMAX,0) THEN
          R_DADOS.PERCDESC    := NVL(R_DESCONTO_VENDA_AUT.PERCDESCMAX,0);
        ELSE
          R_DADOS.PERCDESC    := NVL(R_DESCONTO_VENDA_FLEX.PERCDESCMAX,0);
          R_DADOS.PERCDESCMAX := NVL(R_DESCONTO_VENDA_FLEX.PERCDESCMAX,0);
        END IF;
        R_DESCONTO_VENDA_AUT.PERCDESC := 0;
      end if;
    else
      if (Desconto.Precificacao.PrecoTabela) <= (vnPrecoMinimoAVista)
      then
        R_DADOS.PTABELADESC := Desconto.Precificacao.PrecoTabela;
      elsif (R_DADOS.PTABELADESC) < (vnPrecoMinimoAVista)
      then
        R_DADOS.PTABELADESC := (vnPrecoMinimoAVista);
        IF R_DESCONTO_VENDA_AUT.PERCDESCMAX > R_DESCONTO_VENDA_FLEX.PERCDESCMAX THEN
          R_DADOS.PERCDESC    := NVL(R_DESCONTO_VENDA_AUT.PERCDESCMAX,0);
        ELSE
          R_DADOS.PERCDESC    := NVL(R_DESCONTO_VENDA_FLEX.PERCDESCMAX,0);
          R_DADOS.PERCDESCMAX := NVL(R_DESCONTO_VENDA_FLEX.PERCDESCMAX,0);
        END IF;
        R_DESCONTO_VENDA_AUT.PERCDESC := 0;
      end if;
    end if;
   /*Fim: Definindo máximo desconto no preço a vista */

   /* Início do cálculo para preço de tabela e venda */
    IF R_DESCONTO_VENDA_AUT.ALTERAPTABELA = 'S' THEN
      R_DADOS.PVENDADESC  := R_DADOS.PTABELADESC;

      IF (vnPrecoMinimoAVista > 0) THEN
        R_DADOS.PTABELADESC := Desconto.Precificacao.PrecoTabela;
      ELSIF (R_DESCONTO_VENDA_AUT.PERCDESC > 0) THEN
         IF psTipoOperacao = 'I' THEN
            R_DADOS.PTABELADESC := (Desconto.Precificacao.PrecoTabela * (1 - (R_DESCONTO_VENDA_AUT.PERCDESC/100)));
         ELSE
            R_DADOS.PTABELADESC := Desconto.Precificacao.PrecoTabela;
          END IF;
      ELSE
        R_DADOS.PVENDADESC  := R_DADOS.PTABELADESC;
      END IF;
    ELSE
      R_DADOS.PTABELADESC := Desconto.Precificacao.PrecoTabela;
      R_DADOS.PVENDADESC  := R_DADOS.PTABELADESC;
      R_DADOS.PVENDADESC  := (R_DADOS.PVENDADESC * (1 - ((CASE WHEN R_DADOS.PERCDESCAUT > 0 THEN R_DADOS.PERCDESCAUT ELSE 0 END)
                                                       +(CASE WHEN R_DADOS.PERCDESC > 0 THEN R_DADOS.PERCDESC ELSE 0 END))  /100));
    END IF;
   /* Fim do cálculo para preço de tabela e venda */

   IF psCalculaPrecoRCA = 'S' THEN
       /* Inicia o cálculo para o pbaserca */
        IF NOT (SELECT_DESCONTO(R_DESCONTO_BASE, 'S', CASE
                                                        WHEN R_DESCONTO_VENDA_AUT.PERCDESCMAX > R_DESCONTO_VENDA_FLEX.PERCDESCMAX THEN
                                                          NVL(R_DESCONTO_VENDA_AUT.PRIORITARIA,'N')
                                                        ELSE
                                                          NVL(R_DESCONTO_VENDA_FLEX.PRIORITARIA,'N')
                                                        END, 'N', pnNumeroOrcamento, psTipoEntrega, psTipoDesconto, pnCondvenda)) THEN
          RAISE veERRO_BUSCAR_DESCONTO;
        END IF;


    /*inicio 2522.119155.2014*/
    IF ((Desconto.Parametros132.AceitaDescontoPrecoFixo = 'N') OR (Desconto.RCA.ValidarAcrescDescPrecoFixo = 'N'))
       AND (pPrecoFixo = 'S')then
        R_DESCONTO_BASE.PERCDESC := 0;
        R_DESCONTO_BASE.BASECREDDEBRCA := 'N';
        R_DESCONTO_BASE.CREDITASOBREPOLITICA := 'N';
    END IF;
    /*fim 2522.119155.2014*/

      IF pDescontoPautado > 0 THEN
         R_DADOS.PBASERCA := Desconto.Precificacao.PrecoTabela
                          - (Desconto.Precificacao.PrecoTabela * (pDescontoPautado/100));

      ELSIF (R_DESCONTO_BASE.PERCDESC > 0) THEN

        /* Retornando dados da política que movimentou o pbaserca HIS.01775.2014 */
        R_DADOS.CODESCONTOBASE := R_DESCONTO_BASE.CODDESCONTO;
        R_DADOS.PERCDESCBASE   := R_DESCONTO_BASE.PERCDESC;
        R_DADOS.POLITICABASECREDITA := R_DESCONTO_BASE.CREDITASOBREPOLITICA;
        R_DADOS.POLITICABASEDEBITA := R_DESCONTO_BASE.BASECREDDEBRCA;
        /* Retornando dados da política que movimentou o pbaserca HIS.01775.2014 */
        if (R_DESCONTO_BASE.BASECREDDEBRCA = 'S') and (NVL(R_DESCONTO_BASE.CREDITASOBREPOLITICA,'N') = 'N') then
          if (NVL(R_DESCONTO_BASE.ALTERAPTABELA, 'N') = 'S') then
            if (NVL(R_DESCONTO_VENDA_AUT.ALTERAPTABELA, 'N') = 'S') and
               (NVL(DESCONTO.Pedido.PercDescInformado,0) = 0) OR
              ((NVL(R_DESCONTO_VENDA_FLEX.PERCDESC, 0) = 0) and
               (NVL(R_DESCONTO_VENDA_FLEX.Basecreddebrca, 'N') = 'N')) then
              R_DADOS.PBASERCA := R_DADOS.PTABELADESC;
            elsif (R_DADOS.PVENDADESC > (Desconto.Precificacao.PrecoTabela * (1 - (R_DESCONTO_BASE.PERCDESC/ 100)))) OR
                  ((NVL(R_DESCONTO_VENDA_FLEX.BASECREDDEBRCA, 'N') = 'S') and
                   (NVL(R_DESCONTO_VENDA_FLEX.Creditasobrepolitica, 'N') = 'N') and
                    NVL(DESCONTO.Pedido.PercDescInformado,0) > 0) then
              R_DADOS.PBASERCA := R_DADOS.PVENDADESC;
            else
              R_DADOS.PBASERCA := Desconto.Precificacao.PrecoTabela * (1 - ((R_DESCONTO_BASE.PERCDESC)/100));
            end if;
          else
            if (NVL(DESCONTO.Pedido.PercDescInformado,0)) < (R_DESCONTO_BASE.PERCDESC) then
              if (NVL(DESCONTO.Pedido.PercDescInformado,0) < 0) then
                R_DADOS.PBASERCA  := R_DADOS.PTABELADESC;
              else
                R_DADOS.PBASERCA  := (R_DADOS.PTABELADESC * (1 - (NVL(DESCONTO.Pedido.PercDescInformado,0)/100)));
              end if;
            else
              R_DADOS.PBASERCA  := (R_DADOS.PTABELADESC * (1 - (NVL(R_DESCONTO_BASE.PERCDESC,0)/100)));
            end if;
          end if;
        elsif (NVL(R_DESCONTO_BASE.BASECREDDEBRCA, 'N') = 'S') and
              (NVL(R_DESCONTO_BASE.CREDITASOBREPOLITICA, 'N') = 'S') and
              (NVL(R_DESCONTO_BASE.ALTERAPTABELA, 'N') = 'N')
        then
          R_DADOS.PBASERCA  := (R_DADOS.PTABELADESC * (1 - (NVL(R_DESCONTO_BASE.PERCDESC,0)/100)));
        else
          R_DADOS.PBASERCA := R_DADOS.PTABELADESC;
        end if;

        if R_DESCONTO_BASE.Basecreddebrca = 'N' then
          if R_DADOS.PTABELADESC = R_DADOS.PVENDADESC then
            R_DADOS.PBASERCA := R_DADOS.PVENDADESC;
          end if;
         end if;
      ELSIF pPrecoFixo = 'S' THEN
        IF (R_DESCONTO_VENDA_AUT.ALTERAPTABELA = 'S') THEN
          R_DADOS.PBASERCA := R_DADOS.PTABELADESC;
        ELSE
          R_DADOS.PBASERCA := Desconto.Precificacao.PrecoTabela;
        end if;
      ELSE
        R_DADOS.PBASERCA := R_DADOS.PTABELADESC;
      END IF;
   END IF;
    /* Fim do cálculo para o pbaserca */

   if NVL(DESCONTO.Pedido.PercDescInformado,0) < 0 then
      R_DADOS.PERCDESC    := DESCONTO.Pedido.PercDescInformado;
    end if;

    PIPE ROW(R_DADOS);
    RETURN;
  EXCEPTION
    WHEN veERRO_BUSCAR_DESCONTO THEN
      R_DADOS.MSG          := 'Ocorreu erro ao buscar o select do desconto.'||chr(13)||
                              'Erro original: '|| SQLERRM;
      R_DADOS.CODESCONTO   := NULL;
      R_DADOS.DATAFINAL    := NULL;
      R_DADOS.PERCDESC     := NULL;
      R_DADOS.PTABELADESC  := NULL;
      R_DADOS.PVENDADESC   := NULL;
      R_DADOS.PBASERCA     := NULL;
      PIPE ROW(R_DADOS);
      RETURN;
    WHEN veERRO_DESC_N_PERMITIDO THEN
      R_DADOS.MSG          := 'O Desconto informado é maior que o permitido no sistema!'||chr(13)||
                              'Máximo desconto: ' || R_DESCONTO_VENDA_FLEX.PERCDESC ||'.';
      R_DADOS.CODESCONTO   := 0;
      R_DADOS.DATAFINAL    := NULL;
      R_DADOS.PERCDESC     := 0;
      R_DADOS.PERCDESCAUT  := 0;
      R_DADOS.PTABELADESC  := 0;
      R_DADOS.PVENDADESC   := 0;
      R_DADOS.PBASERCA     := 0;
      PIPE ROW(R_DADOS);
      RETURN;
    WHEN OTHERS THEN
      R_DADOS.MSG          := 'Ocorreram erros na busca dos descontos.'||chr(13)||
                              'Erro original: '|| SQLERRM;
      R_DADOS.CODESCONTO   := NULL;
      R_DADOS.DATAFINAL    := NULL;
      R_DADOS.PERCDESC     := NULL;
      R_DADOS.PTABELADESC  := NULL;
      R_DADOS.PVENDADESC   := NULL;
      R_DADOS.PBASERCA     := NULL;
      PIPE ROW(R_DADOS);
      RETURN;
  END DESCONTO_ITEM_VENDA;

-----------------------------------------------------------------------------------------------------------------------------
/**********************************************************************************************************************************
 *   RESPONSÁVEL          SOLICITAÇÃO    DATA           DESCRIÇÃO                                                                 *
 *   Guilherme.Freitas    206246         28/04/2014     Alteração para ler o parâmetro BLOQUEIAVENDAESTLOJA e caso o mesmo        *
 *                                                      esteja marcado como 'S', não deverá incluir o mesmo na soma do            *
 *                                                      estoque disponível.                                                       *
 *   Guilherme Freitas    0.076348.2015  08/07/2015     Ajustado novamente para considerar o parametrâmetro BLOQUEIAVENDAESTLOJA  *
 *                                                      no cálculo do disponível.                                                 *
 **********************************************************************************************************************************/

  FUNCTION ESTOQUE_DISPONIVEL (PCODPROD     IN NUMBER,
                               PCODFILIAL   IN VARCHAR2,
                               PUSAGREATEST IN VARCHAR2 DEFAULT 'S')
    RETURN TB_ESTOQUE
    PIPELINED
  IS

    DADOS_SAIDA                  T_ESTOQUE;
    BLOQUEIAVENDAESTPENDENTE     VARCHAR2(1);
    CALCESTDISPCOMQTMINAUTOSERV  VARCHAR2(1);
    BLOQUEIAVENDAESTLOJA         VARCHAR2(1);
    vnQTMINAUTOSERV              PCPRODFILIAL.QTMINAUTOSERV%TYPE;

  BEGIN

    CALCESTDISPCOMQTMINAUTOSERV := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_CALCESTDISPCOMQTMINAUTOSERV',PCODFILIAL,'N');
    --BLOQUEIAVENDAESTPENDENTE    := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_BLOQUEIAVENDAESTPENDENTE','99','N');

    BLOQUEIAVENDAESTPENDENTE    := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('BLOQUEIAVENDAESTPENDENTE',
                                                                      PCODFILIAL,
                                                                      FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_BLOQUEIAVENDAESTPENDENTE',
                                                                                                         '99',
                                                                                                         'N'));

    BLOQUEIAVENDAESTLOJA        := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('BLOQUEIAVENDAESTLOJA', PCODFILIAL, 'N');
    --Limpando campos
    DADOS_SAIDA.QTDISP      := 0;
    DADOS_SAIDA.QTDISP_CONT := 0;
    DADOS_SAIDA.QTEST       := 0;
    DADOS_SAIDA.QTESTGER    := 0;
    DADOS_SAIDA.CODFILIAL   := PCODFILIAL;

    DADOS_SAIDA.CODPROD  := PCODPROD;

    SELECT NVL(QTESTGER,0),
           NVL(QTEST,0),
           pkg_estoque.ESTOQUE_DISPONIVEL(PCEST.CODPROD, PCEST.CODFILIAL, 'VA'),  -- VEN-10013: Alterado de '' para 'VA'
           --------------------------------------------------------------------------------------------
            DECODE(PUSAGREATEST,
                          'S',
                          GREATEST((NVL(QTEST, 0) - NVL(QTBLOQUEADA, 0) -
                                   NVL(QTRESERV, 0) - DECODE(BLOQUEIAVENDAESTPENDENTE,
                                                              'S',
                                                              NVL(QTPENDENTE, 0),
                                                              0) -
                                                       DECODE(BLOQUEIAVENDAESTLOJA,
                                                              'S',
                                                              NVL(QTLOJA, 0),
                                                              0)),
                                   0),
                          (NVL(QTEST, 0) - NVL(QTBLOQUEADA, 0) - NVL(QTRESERV, 0) -
                          DECODE(BLOQUEIAVENDAESTPENDENTE, 'S', NVL(QTPENDENTE, 0), 0) -
                          DECODE(BLOQUEIAVENDAESTLOJA,
                                 'S',
                                 NVL(QTLOJA, 0),
                                 0))) ESTOQUE_DISPONIVEL_CONT
           --------------------------------------------------------------------------------------------
      INTO DADOS_SAIDA.QTESTGER,
           DADOS_SAIDA.QTEST,
           DADOS_SAIDA.QTDISP,
           DADOS_SAIDA.QTDISP_CONT
      FROM PCEST
     WHERE CODFILIAL = DADOS_SAIDA.CODFILIAL
       AND CODPROD = DADOS_SAIDA.CODPROD;

    IF CALCESTDISPCOMQTMINAUTOSERV = 'S' THEN
      BEGIN
        SELECT QTMINAUTOSERV
          INTO vnQTMINAUTOSERV
          FROM PCPRODFILIAL
         WHERE CODFILIAL = DADOS_SAIDA.CODFILIAL
           AND CODPROD = DADOS_SAIDA.CODPROD;
      EXCEPTION
        WHEN OTHERS THEN
          vnQTMINAUTOSERV := 0;
      END;
    ELSE
      vnQTMINAUTOSERV := 0;
    END IF;

    DADOS_SAIDA.QTDISP := DADOS_SAIDA.QTDISP - vnQTMINAUTOSERV;

    PIPE ROW (DADOS_SAIDA);

    RETURN;

  END ESTOQUE_DISPONIVEL;

/**************************************************************************************************************************************
 *   RESPONSÁVEL          SOLICITAÇÃO  DATA           DESCRIÇÃO                                                                       *
 *   Marcos.Garcia        213200       09/06/2014     Inclusão da funções onde retorna os produtos que estão com o estoque divergente *
 *                                                    entre o contábil e gerencial (Processo filial retira,  filial virtual )         *
 *                                                                                                                                    *
 *************************************************************************************************************************************/

  FUNCTION ESTOQUE_DIVERGENTE (PCODFILIAL   IN VARCHAR2,
                               PCODPROD     IN NUMBER)
    RETURN TB_ESTOQUE_DIVERGENTE
    PIPELINED
  IS

    DADOS_SAIDA      T_ESTOQUE_DIVERGENTE;
    vsCodFilial      VARCHAR2(2);
    vnCodProd        NUMBER(6);
    vsMovimenta      VARCHAR(1);
    vnNumtransVenda  NUMBER(10);
    vnNumtransEnt    NUMBER(10);
    vnCont           NUMBER;
  BEGIN

    --Limpando campos
    DADOS_SAIDA.CODFILIAL       := PCODFILIAL;
    DADOS_SAIDA.CODPROD         := PCODPROD;
    DADOS_SAIDA.MOVIMENTA       := 'S';
    DADOS_SAIDA.NUMTRANSVENDA  := 0;
    DADOS_SAIDA.NUMTRANSENT    := 0;


    BEGIN
     vnCont := 0;

      ----VERIFICA SE HÁ DIVERGENCIA DE FILIAL RETIRA
     FOR DADOS IN ( SELECT
        PCTRANSFDEP.CODPROD,
        PCTRANSFDEP.CODFILIALDESTINO,
        PCTRANSFDEP.NUMTRANSVENDA,
        PCTRANSFDEP.NUMTRANSENT
       FROM PCTRANSFDEP
      WHERE PCTRANSFDEP.CODFILIALDESTINO = PCODFILIAL
       AND PCTRANSFDEP.CODPROD = PCODPROD
       AND (PCTRANSFDEP.NUMTRANSTRANSFENT IS NULL OR PCTRANSFDEP.NUMTRANSTRANSFSAIDA IS NULL) )
     LOOP
       vnCont := vnCont + 1;
       DADOS_SAIDA.CODPROD        := DADOS.CODPROD;
       DADOS_SAIDA.CODFILIAL      := DADOS.CODFILIALDESTINO;
       DADOS_SAIDA.MOVIMENTA      := 'N';
       DADOS_SAIDA.NUMTRANSVENDA  := DADOS.NUMTRANSVENDA;
       DADOS_SAIDA.NUMTRANSENT    := DADOS.NUMTRANSENT;

       PIPE ROW (DADOS_SAIDA);
     END LOOP;

      ----VERIFICA SE HÁ DIVERGENCIA DE FILIAL RETIRA
     FOR DADOS IN ( SELECT
        PCTRANSFDEPDEVOL.CODPROD,
        PCTRANSFDEPDEVOL.CODFILIALORIGEM,
        PCTRANSFDEPDEVOL.NUMTRANSVENDA,
        PCTRANSFDEPDEVOL.NUMTRANSENT
       FROM PCTRANSFDEPDEVOL
      WHERE PCTRANSFDEPDEVOL.CODFILIALORIGEM = PCODFILIAL
       AND PCTRANSFDEPDEVOL.CODPROD = PCODPROD
       AND (PCTRANSFDEPDEVOL.NUMTRANSTRANSFENT IS NULL OR PCTRANSFDEPDEVOL.NUMTRANSTRANSFSAIDA IS NULL) )
     LOOP
       vnCont := vnCont + 1;
       DADOS_SAIDA.CODPROD        := DADOS.CODPROD;
       DADOS_SAIDA.CODFILIAL      := DADOS.CODFILIALORIGEM;
       DADOS_SAIDA.MOVIMENTA      := 'N';
       DADOS_SAIDA.NUMTRANSVENDA  := DADOS.NUMTRANSVENDA;
       DADOS_SAIDA.NUMTRANSENT    := DADOS.NUMTRANSENT;

       PIPE ROW (DADOS_SAIDA);
     END LOOP;
    END;

    IF vnCont = 0 THEN
      PIPE ROW (DADOS_SAIDA);
    END IF;




    RETURN;

  END ESTOQUE_DIVERGENTE;


FUNCTION CAMPANHA_COMBO(pDATAPEDIDO     IN DATE,
                        pCodFilial      IN VARCHAR2,
                        pCodRegiao      IN NUMBER,
                        pCodRamo        IN NUMBER,
                        pCodSupervisor  IN NUMBER,
                        pCodRca         IN NUMBER,
                        pCodCli         IN NUMBER,
                        pCodDistrib     IN VARCHAR2,
                        pCodPlPag       IN NUMBER DEFAULT 0
                        )
    RETURN TB_CAMPANHA_COMBO
    PIPELINED
  IS
    DADOS_SAIDA        T_CAMPANHA_COMBO;
    vsVendaEmbalagem   VARCHAR2(3);
    vnCodRedeCliente   NUMBER(4);

  BEGIN
    --Limpando campos
    DADOS_SAIDA.CODIGO          := 0;

    vsVendaEmbalagem            := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_UTILIZAVENDAPOREMBALAGEM',
                                                                      pCodFilial,
                                                                      FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_UTILIZAVENDAPOREMBALAGEM',
                                                                                                         '99',
                                                                                                         'N'));


    BEGIN
      SELECT C.CODREDE
        INTO VNCODREDECLIENTE
        FROM PCCLIENT C
       WHERE C.CODCLI = PCODCLI;
    EXCEPTION
      WHEN OTHERS THEN
        VNCODREDECLIENTE := 0;
    END;

    BEGIN


        ----VERIFICA SE HÁ DIVERGENCIA DE FILIAL RETIRA
       FOR DADOS IN (  SELECT D.CODIGO
                       FROM PCDESCONTOC D
                       WHERE pDATAPEDIDO BETWEEN DTINICIO AND DTFIM AND
                            (EXISTS (SELECT 1 FROM PCDESCONTORESTRICAO DR WHERE DR.TIPO = 1 AND DECODE(pCodFilial,'',pCodFilial, DR.CODIGOA)   = pCodFilial AND DR.CODIGO = D.CODIGO) OR (SELECT COUNT(*) FROM PCDESCONTORESTRICAO DR WHERE DR.TIPO = 1 AND DR.CODIGO = D.CODIGO ) = 0 ) AND
                            (EXISTS (SELECT 1 FROM PCDESCONTORESTRICAO DR WHERE DR.TIPO = 2 AND DECODE(pCodRegiao,0,pCodRegiao, DR.CODIGON)   = pCodRegiao  AND DR.CODIGO = D.CODIGO) OR (SELECT COUNT(*) FROM PCDESCONTORESTRICAO DR WHERE DR.TIPO = 2 AND DR.CODIGO = D.CODIGO ) = 0 ) AND
                            (EXISTS (SELECT 1 FROM PCDESCONTORESTRICAO DR WHERE DR.TIPO = 3 AND DECODE(pCodRamo,0,pCodRamo, DR.CODIGON)   = pCodRamo AND DR.CODIGO = D.CODIGO) OR (SELECT COUNT(*) FROM PCDESCONTORESTRICAO DR WHERE DR.TIPO = 3 AND DR.CODIGO = D.CODIGO ) = 0 ) AND
                            (EXISTS (SELECT 1 FROM PCDESCONTORESTRICAO DR WHERE DR.TIPO = 4 AND DECODE(pCodSupervisor,0,pCodSupervisor, DR.CODIGON)  = pCodSupervisor AND DR.CODIGO = D.CODIGO) OR (SELECT COUNT(*) FROM PCDESCONTORESTRICAO DR WHERE DR.TIPO = 4 AND DR.CODIGO = D.CODIGO  ) = 0 ) AND
                            (EXISTS (SELECT 1 FROM PCDESCONTORESTRICAO DR WHERE DR.TIPO = 5 AND DECODE(pCodRca,0,pCodRca, DR.CODIGON)  = pCodRca AND DR.CODIGO = D.CODIGO) OR (SELECT COUNT(*) FROM PCDESCONTORESTRICAO DR WHERE DR.TIPO = 5 AND DR.CODIGO = D.CODIGO  ) = 0 ) AND
                            (EXISTS (SELECT 1 FROM PCDESCONTORESTRICAO DR WHERE DR.TIPO = 6 AND DECODE(pCodCli,0,pCodCli, DR.CODIGON)  IN (CASE WHEN D.UTILIZACODCLIPRINC = 'S' THEN (SELECT C.CODCLI
                                                                                                                                                            FROM PCREDECLIENTE RC
                                                                                                                                                            INNER JOIN PCCLIENT C ON
                                                                                                                                                              C.CODREDE = RC.CODREDE
                                                                                                                                                            WHERE C.CODCLI = pCodCli UNION  SELECT pCodCli FROM DUAL )  ELSE pCodCli END) AND DR.CODIGO = D.CODIGO) OR (SELECT COUNT(*) FROM PCDESCONTORESTRICAO DR WHERE DR.TIPO = 6 AND DR.CODIGO = D.CODIGO  ) = 0 ) AND
                            (EXISTS (SELECT 1 FROM PCDESCONTORESTRICAO DR WHERE DR.TIPO = 7 AND DECODE(pCodDistrib,'',NVL(pCodDistrib,'X'), DR.CODIGOA) = NVL(pCodDistrib,'X') AND DR.CODIGO = D.CODIGO) OR (SELECT COUNT(*) FROM PCDESCONTORESTRICAO DR WHERE DR.TIPO = 7 AND DR.CODIGO = D.CODIGO  ) = 0 ) AND
                            (EXISTS (SELECT 1 FROM PCDESCONTORESTRICAO DR WHERE DR.TIPO = 8 AND DECODE(pCodPlPag,0,pCodPlPag, DR.CODIGON)   = pCodPlPag  AND DR.CODIGO = D.CODIGO) OR (SELECT COUNT(*) FROM PCDESCONTORESTRICAO DR WHERE DR.TIPO = 8 AND DR.CODIGO = D.CODIGO ) = 0 )AND
                            (EXISTS (SELECT 1 FROM PCDESCONTORESTRICAO DR WHERE DR.TIPO = 9 AND DECODE(VNCODREDECLIENTE,0,VNCODREDECLIENTE, DR.CODIGON) = VNCODREDECLIENTE AND DR.CODIGO = D.CODIGO) OR (SELECT COUNT(1) FROM PCDESCONTORESTRICAO DR WHERE DR.TIPO = 9 AND DR.CODIGO = D.CODIGO ) = 0 )
                         AND (((vsVendaEmbalagem = 'S') AND (D.CODFILIAL IS NOT NULL)) OR
                               ((vsVendaEmbalagem = 'N') AND ((D.CODFILIAL = pCodFilial) OR (D.CODFILIAL IS NULL)))
                                )

                         GROUP BY D.CODIGO )
       LOOP

         DADOS_SAIDA.CODIGO       := DADOS.CODIGO;

         PIPE ROW (DADOS_SAIDA);
       END LOOP;
    END;

    RETURN;

  END CAMPANHA_COMBO;

  PROCEDURE ESTORNAR_AUTORIZACAOVENDA(pnCODCLI IN NUMBER,
                                      pnNUMPED IN NUMBER)
  IS
  BEGIN

    FOR AUTORI_PRECO IN
    (SELECT PCAUTORI.NRAUTORIZACAO, PCAUTORI.DATAAUTORIZACAO,
            PCAUTORI.PERCDESCAUTOR, PCAUTORI.PVENDAATUAL,
            NVL(PCAUTORI.BASECREDDEBRCA,'N') BASECREDDEBRCA,
            PCAUTORI.AFETAPERDESC
       FROM PCAUTORI
      WHERE PCAUTORI.NUMPED = pnNUMPED
        AND PCAUTORI.CODCLI = pnCODCLI
        AND PCAUTORI.STATUSUTILIZ = 'S')
    LOOP

      UPDATE PCAUTORI
        SET  DATA_UTILIZACAO = NULL,
             CODFUNCUTILIZ = NULL,
             STATUSUTILIZ = 'N',
             NUMPED = NULL,
             PVENDIDO = NULL
       WHERE NRAUTORIZACAO = AUTORI_PRECO.NRAUTORIZACAO;

    END LOOP;

  END ESTORNAR_AUTORIZACAOVENDA;

  PROCEDURE PROCESSAR_ABATIMENTO(PNUMPED IN NUMBER,
                                 PVALOR  IN NUMBER,
                                 PMSG    OUT VARCHAR2)
  IS
    TYPE T_PCPEDI_OLD IS RECORD
    (PVENDA   NUMBER(18,6),
     PTABELA  NUMBER(18,6),
     PBASERCA NUMBER(18,6));

    vbRESULT       BOOLEAN;
    vbAplicado     BOOLEAN;
    vnNUMCASASDECVENDA  NUMBER;
    vnTAXAABATIMENTO    NUMBER;
    vrPCPEDC       PCPEDC%ROWTYPE;
    vrPCPEDI       PCPEDI%ROWTYPE;
    vrPCPEDI_OLD   T_PCPEDI_OLD;
    vnNOVOVLABAT_C NUMBER;
    vnNOVOVLABAT_I NUMBER;
    vnPERCPARTICIP NUMBER;
    vnVALORSEMIMPOSTO   NUMBER;
    vsTIPOCALCULOGNRE VARCHAR2(1);

    EXPT_ERRO_CCRCA     EXCEPTION;
    EXPT_ERRO_CALCULO   EXCEPTION;
    EXPT_ERRO_CALCULOGNRE   EXCEPTION;
  BEGIN
    PMSG := 'OK';
    vbRESULT := TRUE;
    vbAplicado := FALSE;
    vnNUMCASASDECVENDA:= FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_NUMCASASDECVENDA','99',6);

    BEGIN
      SELECT *
        INTO vrPCPEDC
        FROM PCPEDC
       WHERE numped = PNUMPED;
    EXCEPTION
      WHEN no_data_found THEN
        PMSG := 'Pedido inexistente!';
        vbRESULT := FALSE;
    END;

    IF (vbRESULT)
    THEN

      ESTORNAR_AUTORIZACAOVENDA(vrPCPEDC.CODCLI,
                                vrPCPEDC.NUMPED);


      --Se o valor for maior que 0 aplica o abatimento
      IF(PVALOR > 0)THEN
       vnTAXAABATIMENTO := ROUND(((ROUND(PVALOR,2) / vrPCPEDC.VLATEND) * 100),6);
       vnNOVOVLABAT_C := ROUND(PVALOR,2);
      ELSE--Se o valor for menor que 0 desfaz o abatimento dos itens
       vnTAXAABATIMENTO := 0;
       vnNOVOVLABAT_C := 0;
      END IF;

      FOR ITEM IN
      (SELECT NUMSEQ, CODPROD
         FROM PCPEDI
        WHERE NUMPED = PNUMPED
          AND NVL(BONIFIC,'N') = 'N')
      LOOP
        BEGIN
          --BUSCAR DADOS DO ITEM
          SELECT *
            INTO vrPCPEDI
            FROM PCPEDI
           WHERE NUMPED = PNUMPED
             AND NUMSEQ = ITEM.NUMSEQ
             AND CODPROD = ITEM.CODPROD;
          ----------------------

          --RATEIO DO VALOR DE ABATIMENTO
          BEGIN
            vnNOVOVLABAT_I := (ROUND(PVALOR,2)/(vrPCPEDC.VLATEND)*(vrPCPEDI.PVENDA));
           IF(
              (vrPCPEDI.PERCDESCABATIMENTO IS NULL)OR
              ((ROUND(PVALOR,2) < 0) AND (vrPCPEDI.PERCDESCABATIMENTO > 0))OR
              ((ROUND(PVALOR,2) > 0 AND (vrPCPEDI.PERCDESCABATIMENTO = 0)))
             )
           THEN
             vrPCPEDI.PVENDA := ROUND((vrPCPEDI.PVENDA - vnNOVOVLABAT_I),vnNUMCASASDECVENDA);
             vrPCPEDI.PERCDESCABATIMENTO := vnTAXAABATIMENTO;
             vrPCPEDI.VLDESCABATIMENTO := (vnNOVOVLABAT_C/(vrPCPEDC.VLATEND -vnNOVOVLABAT_C)*(vrPCPEDI.PVENDA));
             vbAplicado := TRUE;
             IF FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('ABATIMENTODEBITARCCRCA',vrPCPEDC.CODFILIAL,'N') = 'N' THEN
              vrPCPEDI.PBASERCA := ROUND((vrPCPEDI.PBASERCA - vnNOVOVLABAT_I),vnNUMCASASDECVENDA);
             END IF;
           ELSE
             vrPCPEDI.PERCDESCABATIMENTO := 0;
             vrPCPEDI.VLDESCABATIMENTO := 0;
           END IF;
           vrPCPEDI.PERDESC := (((vrPCPEDI.PTABELA - vrPCPEDI.PVENDA) * 100) /vrPCPEDI.PTABELA);

          EXCEPTION
            WHEN OTHERS THEN
              RAISE EXPT_ERRO_CALCULO;
          END;
          ----------------------
          --RECALCULAR IMPOSTOS
          SELECT VALORSEMIMPOSTO
            INTO vnVALORSEMIMPOSTO
            FROM TABLE(PKG_TRIBUTACAO.CALCULAR_PVENDA_SEM_IMPOSTO(vrPCPEDC.CODFILIAL,
                                                                  vrPCPEDC.CODFILIALNF,
                                                                  vrPCPEDI.CODFILIALRETIRA,
                                                                  vrPCPEDC.CODCLI,
                                                                  vrPCPEDC.CODPLPAG,
                                                                  vrPCPEDI.CODPROD,
                                                                  vrPCPEDI.CODAUXILIAR,
                                                                  vrPCPEDC.CONDVENDA,
                                                                  vrPCPEDC.VENDAEXPORTACAO,
                                                                  vrPCPEDI.ST,
                                                                  0,
                                                                  vrPCPEDI.PVENDA,
                                                                  'S',
                                                                  'S',
                                                                  'N'));

          SELECT VALORIPI
            INTO vrPCPEDI.VLIPI
            FROM TABLE(PKG_TRIBUTACAO.CALCULAR_IPI(vrPCPEDC.CODFILIAL,
                                                   vrPCPEDC.CODFILIALNF,
                                                   vrPCPEDI.CODFILIALRETIRA,
                                                   vrPCPEDC.CODCLI,
                                                   vrPCPEDI.CODPROD,
                                                   vrPCPEDI.CODAUXILIAR,
                                                   vrPCPEDC.CONDVENDA,
                                                   vrPCPEDC.VENDAEXPORTACAO,
                                                   vnVALORSEMIMPOSTO,
                                                   'N',
                                                   0,
                                                   'N',
                                                   'N'));

          SELECT BASEST, ST
            INTO vrPCPEDI.BASEICST, vrPCPEDI.ST
            FROM TABLE(PKG_TRIBUTACAO.CALCULAR_ST(vrPCPEDC.CODFILIAL,
                                                  vrPCPEDC.CODFILIALNF,
                                                  vrPCPEDI.CODFILIALRETIRA,
                                                  vrPCPEDC.CODCLI,
                                                  vrPCPEDC.CODPLPAG,
                                                  vrPCPEDI.CODPROD,
                                                  vrPCPEDI.CODAUXILIAR,
                                                  vrPCPEDC.CONDVENDA,
                                                  vrPCPEDC.VENDAEXPORTACAO,
                                                  vnVALORSEMIMPOSTO,
                                                  0,
                                                  'N',
                                                  0,
                                                  0));
          ----------------------
          --Valida tipo calculo do stGNRE.
          BEGIN
            Select TIPOCALCULOGNRE into vsTIPOCALCULOGNRE from pctribut where codst = vrPCPEDI.codst;
            IF(vSTIPOCALCULOGNRE = 'C')THEN
              vrPCPEDI.StCLIENTEGNRE := vrPCPEDI.st;
              vrPCPEDI.st := 0;
            END IF;
          EXCEPTION
          WHEN OTHERS THEN
            RAISE EXPT_ERRO_CALCULOGNRE;
          END;

          --APLICAR VALORES CALCULADOS NA PCPEDI
          SELECT pvenda, ptabela, pbaserca
            INTO vrPCPEDI_OLD.PVENDA, vrPCPEDI_OLD.PTABELA, vrPCPEDI_OLD.PBASERCA
            FROM pcpedi
           WHERE numped = PNUMPED
             AND codprod = vrPCPEDI.CODPROD
             AND numseq = vrPCPEDI.NUMSEQ;

          UPDATE PCPEDI
             SET PVENDA = vrPCPEDI.PVENDA,
                 PBASERCA = vrPCPEDI.PBASERCA,
                 ST = vrPCPEDI.ST,
                 Stclientegnre = vrPCPEDI.Stclientegnre,
                 BASEICST = vrPCPEDI.BASEICST,
                 VLIPI = vrPCPEDI.VLIPI,
                 VLDESCABATIMENTO = vrPCPEDI.VLDESCABATIMENTO,
                 PERCDESCABATIMENTO = vrPCPEDI.PERCDESCABATIMENTO,
                 PERDESC = vrPCPEDI.PERDESC
           WHERE NUMPED = PNUMPED
             AND CODPROD = vrPCPEDI.CODPROD
             AND NUMSEQ = vrPCPEDI.NUMSEQ;


          IF (NOT pc_pkg_controlarsaldorca.ccrca_alterar_preco(vrPCPEDI.CODUSUR, --VER
                                                               vrPCPEDI.ROTINALANC, --VER
                                                               vrPCPEDI.CODUSUR,
                                                               vrPCPEDI.NUMPED,
                                                               vrPCPEDI.CODPROD,
                                                               vrPCPEDI.NUMSEQ,
                                                               vrPCPEDI.QT,
                                                               vrPCPEDI_OLD.PVENDA,
                                                               vrPCPEDI_OLD.PBASERCA,
                                                               vrPCPEDI_OLD.PTABELA))
          THEN
            RAISE EXPT_ERRO_CCRCA;
          END IF;
          ----------------------
        EXCEPTION
          WHEN EXPT_ERRO_CALCULO THEN
            PMSG := 'Ocorreu um erro ao tentar calcular o rateio de abatimento para o item:'||chr(13)||
                    'Produto: ' || vrPCPEDI.CODPROD || ' Numseq: ' || vrPCPEDI.NUMSEQ;
            vbRESULT := FALSE;

          WHEN EXPT_ERRO_CCRCA THEN
            PMSG := 'Não foi possível efetuar ajuste no C/C RCA decorrente de abatimento.';
            vbRESULT := FALSE;

         WHEN EXPT_ERRO_CALCULOGNRE THEN
            PMSG := 'Ocorreu um erro ao tentar calcular stGNRE no abatimento para o item:'||chr(13)||
                    'Produto: ' || vrPCPEDI.CODPROD || ' Numseq: ' || vrPCPEDI.NUMSEQ;
            vbRESULT := FALSE;

          WHEN OTHERS THEN
            PMSG := 'Erro ao processar abatimento: '|| SQLERRM;
            vbRESULT := FALSE;
        END;

      END LOOP;
      IF(ROUND(PVALOR,2) > 0)THEN
       vrPCPEDC.VLDESCABATIMENTO := ROUND(PVALOR,2);
       vnNOVOVLABAT_C := ROUND(PVALOR,2);
      ELSIF(vbAplicado)THEN
       vnNOVOVLABAT_C := ROUND(PVALOR,2);
      END IF;

      IF vbRESULT THEN
        UPDATE pcpedc
           SET VLDESCABATIMENTO = vrPCPEDC.VLDESCABATIMENTO,
               VLATEND = ROUND((NVL(VLATEND,0) - vnNOVOVLABAT_C),2)
         WHERE NUMPED = PNUMPED;
      ELSE
        ROLLBACK;
      END IF;

    END IF;

  END PROCESSAR_ABATIMENTO;

  FUNCTION VLLIMITECNAE(PNCODCLI  IN NUMBER)
   RETURN NUMBER
  IS
    vnVALORVENDAMESCORRENTE NUMBER;
    vnLIMITEFATMEDIOCNAE    NUMBER;
  BEGIN

    SELECT (FATMEDIOMENSAL * (DECODE(NVL(PERCFATMES,0),0,100,PERCFATMES)/100)) VALOR
      INTO vnLIMITEFATMEDIOCNAE
      FROM PCCNAE
     WHERE CODCNAE = (SELECT PCCLIENT.CODCNAE FROM PCCLIENT WHERE CODCLI = PNCODCLI);

    SELECT SUM(VALOR)
      INTO vnVALORVENDAMESCORRENTE
      FROM (
    --Pedidos
    SELECT SUM(NVL(VLATEND,0)) VALOR
      FROM PCPEDC
     WHERE CODCLI = PNCODCLI
       AND DTCANCEL IS NULL
       AND POSICAO IN ('L','M')
       AND DATA >= TRUNC(TRUNC(SYSDATE),'MON')
    UNION ALL
    --Faturamento
    SELECT SUM(NVL(PCNFSAID.VLTOTAL,0)) VALOR
      FROM PCNFSAID, PCMOV
     WHERE PCNFSAID.CODCLI = PNCODCLI
       AND PCNFSAID.DTCANCEL IS NULL
       AND PCNFSAID.NUMTRANSVENDA = PCMOV.NUMTRANSVENDA
       AND PCMOV.CODOPER = 'S'
       AND PCNFSAID.DTSAIDA >= TRUNC(TRUNC(SYSDATE),'MON')
    UNION ALL
    --Devoluções
    SELECT SUM(NVL(N.VLTOTAL,0) * (-1)) VALOR
      FROM PCNFENT N, PCMOV M
     WHERE N.CODFORNEC = PNCODCLI
       AND N.TIPODESCARGA IN ('6','7','8','T')
       AND N.DTCANCEL IS NULL
       AND N.NUMTRANSENT = M.NUMTRANSENT
       AND M.CODOPER = 'ED'
       AND N.DTENT >= TRUNC(TRUNC(SYSDATE),'MON')
    );

    RETURN NVL((vnLIMITEFATMEDIOCNAE - GREATEST(NVL(vnVALORVENDAMESCORRENTE,0),0)),0);

  END VLLIMITECNAE;

  function getORIGEMPEDIDO(pNUMPED IN NUMBER, pbisOrcamento boolean default false)
    return varchar2 is
    Result      varchar2(1);
    vsOrigemPed varchar2(1);
    vsTipoOper  varchar2(1);
    vsSQL       varchar2(1000);
  begin
    vsSQL := 'select origemped, nvl(tipooper, ''X'') tipooper into :OrigemPed, :TipoOper';

    if pbisOrcamento then
      vsSQL := vsSQL || chr(13) || 'from pcorcavendac';
      vsSQL := vsSQL || chr(13) || 'where numorca = :numped';
    else
      vsSQL := vsSQL || chr(13) || 'from pcpedc';
      vsSQL := vsSQL || chr(13) || 'where numped = :numped';
    end if;

    execute immediate vsSQL
      into vsOrigemPed, vsTipoOper
      using pNUMPED;

    case vsTipoOper
      when 'A' then
        result := 'T';
      when 'P' then
        result := 'T';
      when 'T' then
        result := 'T';
      when 'B' then
        result := 'B';
      when 'R' then
        result := 'R';
      else
        result := vsOrigemPed;
    end case;

    return(Result);
  exception
    when others then
      result := 'X';
      return(Result);
  end getORIGEMPEDIDO;

  /*************************************************
   * Função Criada para retornar se o valor das    *
   * vendas para clientes TIPOEMPRESA = 'MEI'      *
   * ultrapassou o valor máximo de vendas/mes      *
   * definido na rotina 132 (VLRMAXIMOVENDACLIMEI) *
   *************************************************/
  FUNCTION VALIDA_VLR_LIM_VENDA_MEI(pnCodCli            in NUMBER,
                                    pnValorPedDigitacao in NUMBER,
                                    pnNumped            in NUMBER default 0) RETURN VARCHAR2
  IS
    VNVALORMAXIMOVENDACLIMEI NUMBER(18, 6);
    VNVALORVENDAS            NUMBER(18, 6) := 0;
    VNVALORDEV               NUMBER(18, 6) := 0;
    vsMsgRetorno             VARCHAR2(500);
    vsClienteMei             VARCHAR2(2);
    VNVALORPED               NUMBER(18, 6) := 0;
  BEGIN
    VNVALORMAXIMOVENDACLIMEI := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('VLRMAXIMOVENDACLIMEI',
                                                                  '99',
                                                                  0);

    BEGIN
      SELECT CASE WHEN COUNT(1) > 0 THEN
               'S'
             ELSE
               'N'
             END
        INTO vsClienteMei
        FROM PCCLIENT
       WHERE PCCLIENT.CODCLI = pnCodCli
         AND PCCLIENT.TIPOEMPRESA = 'MEI';
    EXCEPTION
      WHEN OTHERS THEN
        vsClienteMei := 'N';
    END;

    IF (VNVALORMAXIMOVENDACLIMEI > 0) THEN
      SELECT NVL(SUM(NVL(N.VLTOTAL, 0)), 0) VALOR
        INTO VNVALORVENDAS
        FROM PCNFSAID N
            ,PCCLIENT C
       WHERE N.DTCANCEL IS NULL
         AND C.CODCLI = N.CODCLI
         AND C.CODCLI = pnCodCli
         AND C.TIPOEMPRESA = 'MEI'
         AND N.DTSAIDA >= TRUNC(SYSDATE, 'MON')
         AND EXISTS (SELECT pCMOV.numtransvenda from pCMOV where pCMOV.numtransvenda = N.numtransvenda and PCMOV.CODOPER = 'S' );

      SELECT NVL(SUM(NVL(N.VLATEND, 0)), 0) VALOR
        INTO VNVALORPED
        FROM PCPEDC    N
            ,PCCLIENT  C
       WHERE N.DTCANCEL IS NULL
         AND N.POSICAO <>  'F'
         AND C.CODCLI = N.CODCLI
         AND C.CODCLI = pnCodCli
         AND N.NUMPED <> pnNumped
         AND C.TIPOEMPRESA = 'MEI'
         AND N.DATA >= TRUNC(SYSDATE, 'MON');

      SELECT NVL(SUM(NVL(N.VLTOTAL, 0)), 0) VALOR
        INTO VNVALORDEV
        FROM PCNFENT  N
            ,PCCLIENT C
       WHERE C.CODCLI = N.CODFORNEC
         AND C.CODCLI = pnCodCli
         AND C.TIPOEMPRESA = 'MEI'
         AND N.DTENT >= TRUNC(SYSDATE, 'MON')
         AND EXISTS (SELECT pCMOV.NUMTRANSENT from pCMOV where pCMOV.NUMTRANSENT = N.NUMTRANSENT and PCMOV.CODOPER = 'ED' );
    END IF;

    IF (((VNVALORPED + VNVALORVENDAS - VNVALORDEV) + pnValorPedDigitacao)  > VNVALORMAXIMOVENDACLIMEI) AND
       (VNVALORMAXIMOVENDACLIMEI > 0) AND
       (vsClienteMei = 'S')
    THEN
      vsMsgRetorno := 'Cliente cadastrado como MEI(MICROEMPREENDEDOR). ' || chr(13) ||
                      'O Valor do pedido R$' || trim(To_Char(pnValorPedDigitacao,  '9999990.99')) ||
                      ', mais o valor das vendas feitas no mês R$' || trim(To_Char(VNVALORPED + VNVALORVENDAS - VNVALORDEV, '9999990.99')) || chr(13) ||
                      'ultrapassa o limite mensal de R$' || trim(To_Char(VNVALORMAXIMOVENDACLIMEI, '9999990.99'));

    ELSE
      vsMsgRetorno := 'OK';
    END IF;

    RETURN vsMsgRetorno;
  END;

  ------------------------------------------------------------------------------------
  --------------------------PREÇO DE TABELA COMEÇA AQUI-------------------------------
  ------------------------------------------------------------------------------------

  function gerarRetorno(vsMensagem in varchar2) return varchar2 is
   retorno pljson;
  begin
      retorno := pljson();
      retorno.put('mensagemRetorno', vsMensagem);
      return retorno.to_char();
  end;

  function OBTER_PRECO_CONTRATO(pCodprod           in number,
                                pContrato          in number,
                                DADOS_PRECO_TABELA in out T_DADOS_PRODUTO)
    RETURN BOOLEAN is
    vnPrecoContrato number;
    vbResultado     boolean;
  begin
    BEGIN
      SELECT NVL(PTABELA, 0)
        INTO vnPrecoContrato
        FROM PCCONTRATOI
       WHERE CODCONTRATO = pCONTRATO
         AND CODPROD = pCODPROD;
    EXCEPTION
      WHEN OTHERS THEN
        vbResultado := false;
    END;

    if vnPrecoContrato <> 0 then
      vbResultado                := true;
      DADOS_PRECO_TABELA.PTABELA := vnPrecoContrato;
    else
      vbResultado := false;
    end if;

    RETURN vbResultado;

  end OBTER_PRECO_CONTRATO;

  FUNCTION RETORNA_CODIGO_TRIBUTACAO(pCliente          IN T_CLIENTE,
                                     pCodProd          IN NUMBER,
                                     psCodFilial       VARCHAR2,
                                     pnNumRegiao       IN NUMBER DEFAULT 0,
                                     psVendaTriangular IN VARCHAR2 DEFAULT 'N',
                                     pCondVenda        IN NUMBER DEFAULT 0,
                                     pCodEndEnt        IN NUMBER DEFAULT 0)
    RETURN NUMBER IS

    vnnumregiao          pcclient.numregiaocli%TYPE;
    vncodst              pctribut.codst%TYPE;
    vnCodStVendaTriang   PCTRIBUT.CODFIGVENDATRIANGULAR%TYPE;
    vbUsaTributacaoPorUF boolean;
    vsUtilizaTribEndEnt  varchar2(1);
    enderecoEntrega      T_ENDERECO_ENTREGA;
  BEGIN
    vbUsaTributacaoPorUF := F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF',
                                                   '99',
                                                   'N') = 'S';

    vsUtilizaTribEndEnt := F_BUSCARPARAMETRO_ALFA('UTILIZATRIBENDENT',
                                                  psCodFilial,
                                                  'N');

    enderecoEntrega := BUSCAR_ENDERECO_ENTREGA(pCodEndEnt);

    vnNumRegiao := pnNumRegiao;
    IF vnnumregiao = 0 THEN
      vnnumregiao := pCliente.NumRegiao;
    END IF;

    IF vbUsaTributacaoPorUF THEN
      SELECT pctabtrib.codst
        INTO vncodst
        FROM pctabtrib
       WHERE pctabtrib.codprod = pCodProd
         AND pctabtrib.ufdestino = CASE
               WHEN (vsUtilizaTribEndEnt = 'S') AND (enderecoEntrega.EstEnt IS NOT NULL) and
                    (pCondVenda in (1, 5)) THEN
                enderecoEntrega.EstEnt

               ELSE
                pCliente.estent
             END
         AND pctabtrib.codfilialnf = psCodFilial;

    ELSE
      SELECT pctabpr.codst
        INTO vncodst
        FROM pctabpr
       WHERE pctabpr.codprod = pCodProd
         AND pctabpr.numregiao = vnnumregiao;
    END IF;

    IF psVendaTriangular = 'S' THEN
      BEGIN
        SELECT CODFIGVENDATRIANGULAR
          INTO vnCodStVendaTriang
          FROM PCTRIBUT
         WHERE CODST = vncodst;
      EXCEPTION
        WHEN OTHERS THEN
          vnCodStVendaTriang := 0;
      END;

      IF NVL(vnCodStVendaTriang, 0) > 0 THEN
        RETURN vnCodStVendaTriang;
      END IF;
    END IF;

    RETURN vncodst;
  END RETORNA_CODIGO_TRIBUTACAO;

  FUNCTION DADOS_PRODUTO(pCodProd    IN NUMBER,
                         pCodFilial  in varchar,
                         pCodST      in number,
                         pNumRegiao  in number,
                         pAbateFrete in varchar,
                         pPerFrete   in number) RETURN SYS_REFCURSOR IS
    type T_cursor is ref cursor;
    vCursor       T_cursor;
    Parametros132 T_PARAMETROS_132;
  BEGIN

    Parametros132.NumCasasDecimais   := F_BUSCARPARAMETRO_NUM('CON_NUMCASASDECVENDA',
                                                              '99',
                                                              2);
    Parametros132.usaTributacaoPorUF := F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF',
                                                               '99',
                                                               'N');

    OPEN vCursor FOR
      SELECT 0 PTABELA1,
             0 PTABELA2,
             0 PTABELA3,
             0 PTABELA4,
             0 PTABELA5,
             0 PTABELA6,
             0 PTABELA7,
             0 PUNIT,
             0 PUNIT1,
             0 PUNIT2,
             0 PUNIT3,
             0 PUNIT4,
             0 PUNIT5,
             0 PUNIT6,
             0 PUNIT7,
             0 PTABELA_SEMDESCONTOS,
             0 PTABELA_NUMPR1,
             0 STCALCULADO,
             null DATAFIMPRECOFIXO,
             0 PERCOMTABELA,
             0 BASEST,
             0 VLIPI,
             0 VALORDIFALIQUOTAS,
             null vsMSG,
             0 CODESCONTO,
             0 CODESCONTOBASE,
             null POLITICABASECREDITA,
             null POLITICABASEDEBITA,
             0 PERCDESCBASE,
             null DATAFINAL,
             0 PERCDESC,
             0 PERCDESCAUT,
             0 PTABELADESC,
             0 PVENDADESC,
             0 PBASERCA,
             null QUESTIONAUSO,
             null ALTERAPTABELA,
             0 FORCARUTILIZACAO,
             0 PERCDESCMAX,
             null DATAINICIO,
             null QTINI,
             0 QTFIM,
             0 VLRMINIMO_DESCONTO,
             0 VLRMAXIMO_DESCONTO,
             PCPRODUT.CODPROD,
             PCTABPR.VLST,
             PCPRODUT.CODFORNEC,
             PCTRIBUT.PERCDIFALIQUOTAS,
             NVL(PCTRIBUT.PERDESCCUSTOTRANSF, 0) PERDESCCUSTOTRANSF,
             NVL(PCTRIBUT.MOSTRARPVENDASEMST, 'N') MOSTRARPVENDASEMST,
             NVL(PCTABPR.PERDESCFOB, 0) PERDESCFOB,
             NVL(PCPRODUT.CUSTOREPZFM, PCPRODUT.CUSTOREP) AS PTABELAFABRICAZFM,
             PCPRODUT.CUSTOREP AS PTABELAFABRICA,
             PCTABPR.PVENDA,
             PCPRODUT.QTUNIT,
             PCPRODUT.CODAUXILIAR,
             0 FATORPRECO,
             ROUND(DECODE(pAbateFrete,
                          'F',
                          (PCTABPR.PVENDA1 -
                          (PCTABPR.PVENDA1 * (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                          'P',
                          DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                 'N',
                                 (PCTABPR.PVENDA1 /
                                 (1 +
                                 ((pPerFrete / 100) +
                                 (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                 PCTABPR.PVENDA1),
                          PCTABPR.PVENDA1) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDA1,
             ROUND(DECODE(pAbateFrete,
                          'F',
                          (PCTABPR.PVENDA2 -
                          (PCTABPR.PVENDA2 * (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                          'P',
                          DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                 'N',
                                 (PCTABPR.PVENDA2 /
                                 (1 +
                                 ((pPerFrete / 100) +
                                 (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                 PCTABPR.PVENDA2),
                          PCTABPR.PVENDA2) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDA2,
             ROUND(DECODE(pAbateFrete,
                          'F',
                          (PCTABPR.PVENDA3 -
                          (PCTABPR.PVENDA3 * (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                          'P',
                          DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                 'N',
                                 (PCTABPR.PVENDA3 /
                                 (1 +
                                 ((pPerFrete / 100) +
                                 (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                 PCTABPR.PVENDA3),
                          PCTABPR.PVENDA3) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDA3,
             ROUND(DECODE(pAbateFrete,
                          'F',
                          (PCTABPR.PVENDA4 -
                          (PCTABPR.PVENDA4 * (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                          'P',
                          DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                 'N',
                                 (PCTABPR.PVENDA4 /
                                 (1 +
                                 ((pPerFrete / 100) +
                                 (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                 PCTABPR.PVENDA4),
                          PCTABPR.PVENDA4) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDA4,
             ROUND(DECODE(pAbateFrete,
                          'F',
                          (PCTABPR.PVENDA5 -
                          (PCTABPR.PVENDA5 * (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                          'P',
                          DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                 'N',
                                 (PCTABPR.PVENDA5 /
                                 (1 +
                                 ((pPerFrete / 100) +
                                 (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                 PCTABPR.PVENDA5),
                          PCTABPR.PVENDA5) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDA5,
             ROUND(DECODE(pAbateFrete,
                          'F',
                          (PCTABPR.PVENDA6 -
                          (PCTABPR.PVENDA6 * (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                          'P',
                          DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                 'N',
                                 (PCTABPR.PVENDA6 /
                                 (1 +
                                 ((pPerFrete / 100) +
                                 (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                 PCTABPR.PVENDA6),
                          PCTABPR.PVENDA6) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDA6,
             ROUND(DECODE(pAbateFrete,
                          'F',
                          (PCTABPR.PVENDA7 -
                          (PCTABPR.PVENDA7 * (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                          'P',
                          DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                 'N',
                                 (PCTABPR.PVENDA7 /
                                 (1 +
                                 ((pPerFrete / 100) +
                                 (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                 PCTABPR.PVENDA7),
                          PCTABPR.PVENDA7) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDA7,
             0 PVENDAATAC,
             ROUND(DECODE(pAbateFrete,
                          'F',
                          (PCTABPR.PVENDAATAC1 /
                          (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                          'P',
                          DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                 'N',
                                 (PCTABPR.PVENDAATAC1 /
                                 (1 +
                                 ((pPerFrete / 100) +
                                 (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                 PCTABPR.PVENDAATAC1),
                          PCTABPR.PVENDAATAC1) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDAATAC1,
             ROUND(DECODE(pAbateFrete,
                          'F',
                          (PCTABPR.PVENDAATAC2 /
                          (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                          'P',
                          DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                 'N',
                                 (PCTABPR.PVENDAATAC2 /
                                 (1 +
                                 ((pPerFrete / 100) +
                                 (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                 PCTABPR.PVENDAATAC2),
                          PCTABPR.PVENDAATAC2) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDAATAC2,
             ROUND(DECODE(pAbateFrete,
                          'F',
                          (PCTABPR.PVENDAATAC3 /
                          (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                          'P',
                          DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                 'N',
                                 (PCTABPR.PVENDAATAC3 /
                                 (1 +
                                 ((pPerFrete / 100) +
                                 (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                 PCTABPR.PVENDAATAC3),
                          PCTABPR.PVENDAATAC3) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDAATAC3,
             ROUND(DECODE(pAbateFrete,
                          'F',
                          (PCTABPR.PVENDAATAC4 /
                          (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                          'P',
                          DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                 'N',
                                 (PCTABPR.PVENDAATAC4 /
                                 (1 +
                                 ((pPerFrete / 100) +
                                 (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                 PCTABPR.PVENDAATAC4),
                          PCTABPR.PVENDAATAC4) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDAATAC4,
             ROUND(DECODE(pAbateFrete,
                          'F',
                          (PCTABPR.PVENDAATAC5 /
                          (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                          'P',
                          DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                 'N',
                                 (PCTABPR.PVENDAATAC5 /
                                 (1 +
                                 ((pPerFrete / 100) +
                                 (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                 PCTABPR.PVENDAATAC5),
                          PCTABPR.PVENDAATAC5) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDAATAC5,
             ROUND(DECODE(pAbateFrete,
                          'F',
                          (PCTABPR.PVENDAATAC6 /
                          (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                          'P',
                          DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                 'N',
                                 (PCTABPR.PVENDAATAC6 /
                                 (1 +
                                 ((pPerFrete / 100) +
                                 (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                 PCTABPR.PVENDAATAC6),
                          PCTABPR.PVENDAATAC6) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDAATAC6,
             ROUND(DECODE(pAbateFrete,
                          'F',
                          (PCTABPR.PVENDAATAC7 /
                          (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                          'P',
                          DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                 'N',
                                 (PCTABPR.PVENDAATAC7 /
                                 (1 +
                                 ((pPerFrete / 100) +
                                 (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                 PCTABPR.PVENDAATAC7),
                          PCTABPR.PVENDAATAC7) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDAATAC7,
             0 POFERTA,
             TRUNC(SYSDATE) DTOFERTAINI,
             TRUNC(SYSDATE) DTOFERTAFIM,
             0 POFERTAATAC,
             TRUNC(SYSDATE) DTOFERTAATACINI,
             TRUNC(SYSDATE) DTOFERTAATACFIM,
             0 QTMULTIPLA,
             DECODE((SELECT COUNT(*)
                      FROM PCPRODFILIAL
                     WHERE CODPROD = PCPRODUT.CODPROD
                       AND CODFILIAL = PCEST.CODFILIAL),
                    0,
                    NVL(PCPRODUT.QTMINIMAATACADO, 0),
                    NVL((SELECT QTMINIMAATACADO
                          FROM PCPRODFILIAL
                         WHERE CODPROD = PCPRODUT.CODPROD
                           AND CODFILIAL = PCEST.CODFILIAL),
                        NVL(PCPRODUT.QTMINIMAATACADO, 0))) QTMINIMAATACADO,
             PCTRIBUT.CODST,
             PCPRODUT.PERCBONIFICVENDA,
             NVL(PCTRIBUT.PERACRESCISMOPF, 0) PERACRESCISMOPF,
             PCPRODUT.PRECOFIXO,
             PCPRODUT.CODLINHAPROD,
             DECODE((SELECT COUNT(*)
                      FROM PCPRODFILIAL
                     WHERE CODPROD = PCPRODUT.CODPROD
                       AND CODFILIAL = PCEST.CODFILIAL),
                    0,
                    DECODE(NVL(PCPRODUT.MULTIPLO, 0),
                           0,
                           DECODE(NVL(PCPRODUT.ACEITAVENDAFRACAO, 'N'),
                                  'N',
                                  1,
                                  (SELECT 1 / CASE NVL(NUMCASASDECESTOQUE, 1)
                                            WHEN 1 THEN
                                             10
                                            WHEN 2 THEN
                                             100
                                            WHEN 3 THEN
                                             1000
                                            WHEN 4 THEN
                                             10000
                                            WHEN 5 THEN
                                             100000
                                            WHEN 6 THEN
                                             1000000
                                          END
                                     FROM PCCONSUM
                                    WHERE ROWNUM = 1)),
                           PCPRODUT.MULTIPLO),
                    NVL(DECODE((SELECT MULTIPLO
                                 FROM PCPRODFILIAL
                                WHERE CODPROD = PCPRODUT.CODPROD
                                  AND CODFILIAL = PCEST.CODFILIAL),
                               0,
                               DECODE(NVL(PCPRODUT.ACEITAVENDAFRACAO, 'N'),
                                      'N',
                                      1,
                                      (SELECT 1 / CASE NVL(NUMCASASDECESTOQUE, 1)
                                                WHEN 1 THEN
                                                 10
                                                WHEN 2 THEN
                                                 100
                                                WHEN 3 THEN
                                                 1000
                                                WHEN 4 THEN
                                                 10000
                                                WHEN 5 THEN
                                                 100000
                                                WHEN 6 THEN
                                                 1000000
                                              END
                                         FROM PCCONSUM
                                        WHERE ROWNUM = 1)),
                               (SELECT MULTIPLO
                                  FROM PCPRODFILIAL
                                 WHERE CODPROD = PCPRODUT.CODPROD
                                   AND CODFILIAL = PCEST.CODFILIAL)),
                        DECODE(NVL(PCPRODUT.MULTIPLO, 0),
                               0,
                               DECODE(NVL(PCPRODUT.ACEITAVENDAFRACAO, 'N'),
                                      'N',
                                      1,
                                      (SELECT 1 / CASE NVL(NUMCASASDECESTOQUE, 1)
                                                WHEN 1 THEN
                                                 10
                                                WHEN 2 THEN
                                                 100
                                                WHEN 3 THEN
                                                 1000
                                                WHEN 4 THEN
                                                 10000
                                                WHEN 5 THEN
                                                 100000
                                                WHEN 6 THEN
                                                 1000000
                                              END
                                         FROM PCCONSUM
                                        WHERE ROWNUM = 1)),
                               PCPRODUT.MULTIPLO))) MULTIPLO,
             NVL(PCPRODUT.TIPOMERC, 'OT') TIPOMERC,
             NVL(PCPRODUT.CODPRODPRINC, PCPRODUT.CODPROD) CODPRODPRINC,
             NVL(PCTRIBUT.APLICAACRESCPJISENTA, 'S') APLICAACRESCPJISENTA,
             NVL(PCPRODUT.CHECARMULTIPLOVENDABNF, 'S') CHECARMULTIPLOVENDABNF,
             PCTABPR.PTABELA,
             PCTRIBUT.PERCREDPVENDASIMPLESNAC,
             PCTABPR.PERCDESCSIMPLESNAC,
             NVL(PCPRODUT.TIPOCUSTOTRANSF, 'P') TIPOCUSTOTRANSF,
             NVL(PCTRIBUT.BNFNAOCALCULAICMS, 'N') BNFNAOCALCULAICMS,
             PCTRIBUT.PERACRESCISMOSIMPNAC,
             0 VALOR_DESCONTO_ICMS,
             0 CODIGOPRECOFIXO,
             'N' USANDOPOFERTA,
             0 PERCENTUAL_REDUCAO_IPI
        FROM PCTABPR, PCPRODUT, PCTRIBUT, PCEST, PCFORNEC
       WHERE PCTABPR.CODPROD = PCPRODUT.CODPROD
         AND PCTRIBUT.CODST = DECODE(Parametros132.usaTributacaoPorUF,
                                     'S',
                                     pCodST,
                                     PCTRIBUT.CODST)
         AND PCTABPR.CODST =
             DECODE(Parametros132.usaTributacaoPorUF, 'N', PCTRIBUT.CODST(+))
         AND (PCPRODUT.CODFORNEC = PCFORNEC.CODFORNEC)
         AND (PCPRODUT.CODPROD = PCEST.CODPROD)
         AND (RTRIM(LTRIM(PCEST.CODFILIAL)) = pCodFilial)
         AND (PCTABPR.NUMREGIAO = pNumRegiao)
         AND (NVL(PCPRODUT.CODFILIAL, '99') IN (pCodFilial, '99'))
         AND (PCPRODUT.CODPROD = pCodProd)
       ORDER BY EMBALAGEM;

    RETURN vCursor;
  END;
  ------------------------------------------------------------------------------------
  FUNCTION DADOS_PRODUTO_EMBALAGEM(pCodProd     IN NUMBER,
                                   pCodFilial   in varchar,
                                   pCodST       in number,
                                   pNumRegiao   in number,
                                   pAbateFrete  in varchar,
                                   pPerFrete    in number,
                                   pCodAuxiliar in number default 0,
                                   pOrigemPed   IN VARCHAR)
    RETURN SYS_REFCURSOR IS
    type T_cursor is ref cursor;
    vCursor       T_cursor;
    Parametros132 T_PARAMETROS_132;
  BEGIN

    Parametros132.NumCasasDecimais   := F_BUSCARPARAMETRO_NUM('CON_NUMCASASDECVENDA',
                                                              '99',
                                                              2);
    Parametros132.usaTributacaoPorUF := F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF',
                                                               '99',
                                                               'N');

    OPEN vCursor FOR
      SELECT 0 PTABELA1,
             0 PTABELA2,
             0 PTABELA3,
             0 PTABELA4,
             0 PTABELA5,
             0 PTABELA6,
             0 PTABELA7,
             0 PUNIT,
             0 PUNIT1,
             0 PUNIT2,
             0 PUNIT3,
             0 PUNIT4,
             0 PUNIT5,
             0 PUNIT6,
             0 PUNIT7,
             0 PTABELA_SEMDESCONTOS,
             0 PTABELA_NUMPR1,
             0 STCALCULADO,
             null DATAFIMPRECOFIXO,
             0 PERCOMTABELA,
             0 BASEST,
             0 VLIPI,
             0 VALORDIFALIQUOTAS,
             null vsMSG,
             0 CODESCONTO,
             0 CODESCONTOBASE,
             null POLITICABASECREDITA,
             null POLITICABASEDEBITA,
             0 PERCDESCBASE,
             null DATAFINAL,
             0 PERCDESC,
             0 PERCDESCAUT,
             0 PTABELADESC,
             0 PVENDADESC,
             0 PBASERCA,
             null QUESTIONAUSO,
             null ALTERAPTABELA,
             0 FORCARUTILIZACAO,
             0 PERCDESCMAX,
             null DATAINICIO,
             null QTINI,
             0 QTFIM,
             0 VLRMINIMO_DESCONTO,
             0 VLRMAXIMO_DESCONTO,
             PCPRODUT.CODPROD,
             PCTABPR.VLST,
             PCPRODUT.CODFORNEC,
             PCTRIBUT.PERCDIFALIQUOTAS,
             NVL(PCTRIBUT.PERDESCCUSTOTRANSF, 0) PERDESCCUSTOTRANSF,
             NVL(PCTRIBUT.MOSTRARPVENDASEMST,
                 (SELECT NVL(MOSTRARPVENDASEMST, 'N') FROM PCCONSUM)) MOSTRARPVENDASEMST,
             NVL(PCTABPR.PERDESCFOB, 0) PERDESCFOB,
             NVL(PCPRODUT.CUSTOREPZFM, PCPRODUT.CUSTOREP) AS PTABELAFABRICAZFM,
             PCPRODUT.CUSTOREP AS PTABELAFABRICA,
             PCEMBALAGEM.PVENDA,
             DECODE(NVL(PCEMBALAGEM.QTUNIT, 1),
                    0,
                    1,
                    NVL(PCEMBALAGEM.QTUNIT, 1)) QTUNIT,
             PCEMBALAGEM.CODAUXILIAR,
             DECODE(NVL(PCEMBALAGEM.FATORPRECO, 0),
                    0,
                    1,
                    PCEMBALAGEM.FATORPRECO) FATORPRECO,
             ROUND(((DECODE(pAbateFrete,
                            'F',
                            (PCTABPR.PVENDA1 /
                            (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                            'P',
                            DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                   'N',
                                   (PCTABPR.PVENDA1 /
                                   (1 +
                                   ((pPerFrete / 100) +
                                   (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                   PCTABPR.PVENDA1),
                            PCTABPR.PVENDA1) * NVL(PCEMBALAGEM.QTUNIT, 1)) *
                   DECODE(NVL(PCEMBALAGEM.FATORPRECO, 0),
                           0,
                           1,
                           PCEMBALAGEM.FATORPRECO)) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDA1,
             ROUND(((DECODE(pAbateFrete,
                            'F',
                            (PCTABPR.PVENDA2 /
                            (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                            'P',
                            DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                   'N',
                                   (PCTABPR.PVENDA2 /
                                   (1 +
                                   ((pPerFrete / 100) +
                                   (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                   PCTABPR.PVENDA2),
                            PCTABPR.PVENDA2) * NVL(PCEMBALAGEM.QTUNIT, 1)) *
                   DECODE(NVL(PCEMBALAGEM.FATORPRECO, 0),
                           0,
                           1,
                           PCEMBALAGEM.FATORPRECO)) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDA2,
             ROUND(((DECODE(pAbateFrete,
                            'F',
                            (PCTABPR.PVENDA3 /
                            (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                            'P',
                            DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                   'N',
                                   (PCTABPR.PVENDA3 /
                                   (1 +
                                   ((pPerFrete / 100) +
                                   (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                   PCTABPR.PVENDA3),
                            PCTABPR.PVENDA3) * NVL(PCEMBALAGEM.QTUNIT, 1)) *
                   DECODE(NVL(PCEMBALAGEM.FATORPRECO, 0),
                           0,
                           1,
                           PCEMBALAGEM.FATORPRECO)) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDA3,
             ROUND(((DECODE(pAbateFrete,
                            'F',
                            (PCTABPR.PVENDA4 /
                            (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                            'P',
                            DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                   'N',
                                   (PCTABPR.PVENDA4 /
                                   (1 +
                                   ((pPerFrete / 100) +
                                   (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                   PCTABPR.PVENDA4),
                            PCTABPR.PVENDA4) * NVL(PCEMBALAGEM.QTUNIT, 1)) *
                   DECODE(NVL(PCEMBALAGEM.FATORPRECO, 0),
                           0,
                           1,
                           PCEMBALAGEM.FATORPRECO)) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDA4,
             ROUND(((DECODE(pAbateFrete,
                            'F',
                            (PCTABPR.PVENDA5 /
                            (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                            'P',
                            DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                   'N',
                                   (PCTABPR.PVENDA5 /
                                   (1 +
                                   ((pPerFrete / 100) +
                                   (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                   PCTABPR.PVENDA5),
                            PCTABPR.PVENDA5) * NVL(PCEMBALAGEM.QTUNIT, 1)) *
                   DECODE(NVL(PCEMBALAGEM.FATORPRECO, 0),
                           0,
                           1,
                           PCEMBALAGEM.FATORPRECO)) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDA5,
             ROUND(((DECODE(pAbateFrete,
                            'F',
                            (PCTABPR.PVENDA6 /
                            (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                            'P',
                            DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                   'N',
                                   (PCTABPR.PVENDA6 /
                                   (1 +
                                   ((pPerFrete / 100) +
                                   (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                   PCTABPR.PVENDA6),
                            PCTABPR.PVENDA6) * NVL(PCEMBALAGEM.QTUNIT, 1)) *
                   DECODE(NVL(PCEMBALAGEM.FATORPRECO, 0),
                           0,
                           1,
                           PCEMBALAGEM.FATORPRECO)) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDA6,
             ROUND(((DECODE(pAbateFrete,
                            'F',
                            (PCTABPR.PVENDA7 /
                            (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                            'P',
                            DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                   'N',
                                   (PCTABPR.PVENDA7 /
                                   (1 +
                                   ((pPerFrete / 100) +
                                   (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                   PCTABPR.PVENDA7),
                            PCTABPR.PVENDA7) * NVL(PCEMBALAGEM.QTUNIT, 1)) *
                   DECODE(NVL(PCEMBALAGEM.FATORPRECO, 0),
                           0,
                           1,
                           PCEMBALAGEM.FATORPRECO)) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDA7,
             0 PVENDAATAC,
             ROUND(((DECODE(pAbateFrete,
                            'F',
                            (PCTABPR.PVENDAATAC1 /
                            (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                            'P',
                            DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                   'N',
                                   (PCTABPR.PVENDAATAC1 /
                                   (1 +
                                   ((pPerFrete / 100) +
                                   (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                   PCTABPR.PVENDAATAC1),
                            PCTABPR.PVENDAATAC1) *
                   NVL(PCEMBALAGEM.QTUNIT, 1)) *
                   DECODE(NVL(PCEMBALAGEM.FATORPRECO, 0),
                           0,
                           1,
                           PCEMBALAGEM.FATORPRECO)) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDAATAC1,
             ROUND(((DECODE(pAbateFrete,
                            'F',
                            (PCTABPR.PVENDAATAC2 /
                            (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                            'P',
                            DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                   'N',
                                   (PCTABPR.PVENDAATAC2 /
                                   (1 +
                                   ((pPerFrete / 100) +
                                   (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                   PCTABPR.PVENDAATAC2),
                            PCTABPR.PVENDAATAC2) *
                   NVL(PCEMBALAGEM.QTUNIT, 1)) *
                   DECODE(NVL(PCEMBALAGEM.FATORPRECO, 0),
                           0,
                           1,
                           PCEMBALAGEM.FATORPRECO)) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDAATAC2,
             ROUND(((DECODE(pAbateFrete,
                            'F',
                            (PCTABPR.PVENDAATAC3 /
                            (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                            'P',
                            DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                   'N',
                                   (PCTABPR.PVENDAATAC3 /
                                   (1 +
                                   ((pPerFrete / 100) +
                                   (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                   PCTABPR.PVENDAATAC3),
                            PCTABPR.PVENDAATAC3) *
                   NVL(PCEMBALAGEM.QTUNIT, 1)) *
                   DECODE(NVL(PCEMBALAGEM.FATORPRECO, 0),
                           0,
                           1,
                           PCEMBALAGEM.FATORPRECO)) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDAATAC3,
             ROUND(((DECODE(pAbateFrete,
                            'F',
                            (PCTABPR.PVENDAATAC4 /
                            (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                            'P',
                            DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                   'N',
                                   (PCTABPR.PVENDAATAC4 /
                                   (1 +
                                   ((pPerFrete / 100) +
                                   (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                   PCTABPR.PVENDAATAC4),
                            PCTABPR.PVENDAATAC4) *
                   NVL(PCEMBALAGEM.QTUNIT, 1)) *
                   DECODE(NVL(PCEMBALAGEM.FATORPRECO, 0),
                           0,
                           1,
                           PCEMBALAGEM.FATORPRECO)) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDAATAC4,
             ROUND(((DECODE(pAbateFrete,
                            'F',
                            (PCTABPR.PVENDAATAC5 /
                            (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                            'P',
                            DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                   'N',
                                   (PCTABPR.PVENDAATAC5 /
                                   (1 +
                                   ((pPerFrete / 100) +
                                   (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                   PCTABPR.PVENDAATAC5),
                            PCTABPR.PVENDAATAC5) *
                   NVL(PCEMBALAGEM.QTUNIT, 1)) *
                   DECODE(NVL(PCEMBALAGEM.FATORPRECO, 0),
                           0,
                           1,
                           PCEMBALAGEM.FATORPRECO)) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDAATAC5,
             ROUND(((DECODE(pAbateFrete,
                            'F',
                            (PCTABPR.PVENDAATAC6 /
                            (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                            'P',
                            DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                   'N',
                                   (PCTABPR.PVENDAATAC6 /
                                   (1 +
                                   ((pPerFrete / 100) +
                                   (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                   PCTABPR.PVENDAATAC6),
                            PCTABPR.PVENDAATAC6) *
                   NVL(PCEMBALAGEM.QTUNIT, 1)) *
                   DECODE(NVL(PCEMBALAGEM.FATORPRECO, 0),
                           0,
                           1,
                           PCEMBALAGEM.FATORPRECO)) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDAATAC6,
             ROUND(((DECODE(pAbateFrete,
                            'F',
                            (PCTABPR.PVENDAATAC7 /
                            (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100) +
                            NVL(PCTABPR.PERCACRESCIMOFRETE, 0)),
                            'P',
                            DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                   'N',
                                   (PCTABPR.PVENDAATAC7 /
                                   (1 +
                                   ((pPerFrete / 100) +
                                   (NVL(PCTABPR.PERCACRESCIMOFRETE, 0) / 100)))),
                                   PCTABPR.PVENDAATAC7),
                            PCTABPR.PVENDAATAC7) *
                   NVL(PCEMBALAGEM.QTUNIT, 1)) *
                   DECODE(NVL(PCEMBALAGEM.FATORPRECO, 0),
                           0,
                           1,
                           PCEMBALAGEM.FATORPRECO)) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDAATAC7,
             0 POFERTA,
             TRUNC(SYSDATE) DTOFERTAINI,
             TRUNC(SYSDATE) DTOFERTAFIM,
             0 POFERTAATAC,
             TRUNC(SYSDATE) DTOFERTAATACINI,
             TRUNC(SYSDATE) DTOFERTAATACFIM,
             0 QTMULTIPLA,
             DECODE((SELECT COUNT(*)
                      FROM PCPRODFILIAL
                     WHERE CODPROD = PCPRODUT.CODPROD
                       AND CODFILIAL = PCEST.CODFILIAL),
                    0,
                    NVL(PCPRODUT.QTMINIMAATACADO, 0),
                    NVL((SELECT QTMINIMAATACADO
                          FROM PCPRODFILIAL
                         WHERE CODPROD = PCPRODUT.CODPROD
                           AND CODFILIAL = PCEST.CODFILIAL),
                        NVL(PCPRODUT.QTMINIMAATACADO, 0))) QTMINIMAATACADO,
             PCTRIBUT.CODST,
             PCPRODUT.PERCBONIFICVENDA,
             NVL(PCTRIBUT.PERACRESCISMOPF, 0) PERACRESCISMOPF,
             PCPRODUT.PRECOFIXO,
             PCPRODUT.CODLINHAPROD,
             DECODE((SELECT COUNT(*)
                      FROM PCPRODFILIAL
                     WHERE CODPROD = PCPRODUT.CODPROD
                       AND CODFILIAL = PCEST.CODFILIAL),
                    0,
                    DECODE(NVL(PCPRODUT.MULTIPLO, 0),
                           0,
                           DECODE(NVL(PCPRODUT.ACEITAVENDAFRACAO, 'N'),
                                  'N',
                                  1,
                                  (SELECT 1 / CASE NVL(NUMCASASDECESTOQUE, 1)
                                            WHEN 1 THEN
                                             10
                                            WHEN 2 THEN
                                             100
                                            WHEN 3 THEN
                                             1000
                                            WHEN 4 THEN
                                             10000
                                            WHEN 5 THEN
                                             100000
                                            WHEN 6 THEN
                                             1000000
                                          END
                                     FROM PCCONSUM
                                    WHERE ROWNUM = 1)),
                           PCPRODUT.MULTIPLO),
                    NVL(DECODE((SELECT MULTIPLO
                                 FROM PCPRODFILIAL
                                WHERE CODPROD = PCPRODUT.CODPROD
                                  AND CODFILIAL = PCEST.CODFILIAL),
                               0,
                               DECODE(NVL(PCPRODUT.ACEITAVENDAFRACAO, 'N'),
                                      'N',
                                      1,
                                      (SELECT 1 / CASE NVL(NUMCASASDECESTOQUE, 1)
                                                WHEN 1 THEN
                                                 10
                                                WHEN 2 THEN
                                                 100
                                                WHEN 3 THEN
                                                 1000
                                                WHEN 4 THEN
                                                 10000
                                                WHEN 5 THEN
                                                 100000
                                                WHEN 6 THEN
                                                 1000000
                                              END
                                         FROM PCCONSUM
                                        WHERE ROWNUM = 1)),
                               (SELECT MULTIPLO
                                  FROM PCPRODFILIAL
                                 WHERE CODPROD = PCPRODUT.CODPROD
                                   AND CODFILIAL = PCEST.CODFILIAL)),
                        DECODE(NVL(PCPRODUT.MULTIPLO, 0),
                               0,
                               DECODE(NVL(PCPRODUT.ACEITAVENDAFRACAO, 'N'),
                                      'N',
                                      1,
                                      (SELECT 1 / CASE NVL(NUMCASASDECESTOQUE, 1)
                                                WHEN 1 THEN
                                                 10
                                                WHEN 2 THEN
                                                 100
                                                WHEN 3 THEN
                                                 1000
                                                WHEN 4 THEN
                                                 10000
                                                WHEN 5 THEN
                                                 100000
                                                WHEN 6 THEN
                                                 1000000
                                              END
                                         FROM PCCONSUM
                                        WHERE ROWNUM = 1)),
                               PCPRODUT.MULTIPLO))) MULTIPLO,
             NVL(PCPRODUT.TIPOMERC, 'OT') TIPOMERC,
             NVL(PCPRODUT.CODPRODPRINC, PCPRODUT.CODPROD) CODPRODPRINC,
             NVL(PCTRIBUT.APLICAACRESCPJISENTA, 'S') APLICAACRESCPJISENTA,
             NVL(PCPRODUT.CHECARMULTIPLOVENDABNF, 'S') CHECARMULTIPLOVENDABNF,
             PCTABPR.PTABELA,
             PCTRIBUT.PERCREDPVENDASIMPLESNAC,
             PCTABPR.PERCDESCSIMPLESNAC,
             NVL(PCPRODUT.TIPOCUSTOTRANSF, 'P') TIPOCUSTOTRANSF,
             NVL(PCTRIBUT.BNFNAOCALCULAICMS, 'N') BNFNAOCALCULAICMS,
             PCTRIBUT.PERACRESCISMOSIMPNAC,
             0 VALOR_DESCONTO_ICMS,
             0 CODIGOPRECOFIXO,
             'N' USANDOPOFERTA,
             0 PERCENTUAL_REDUCAO_IPI
        FROM PCTABPR, PCEMBALAGEM, PCPRODUT, PCTRIBUT, PCEST, PCFORNEC
       WHERE PCTABPR.CODPROD = PCPRODUT.CODPROD
         AND PCEMBALAGEM.CODPROD = PCPRODUT.CODPROD
         AND PCEMBALAGEM.CODFILIAL = pCodFilial
         AND (PCEMBALAGEM.CODFUNCINATIVO IS NULL OR
             PCEMBALAGEM.DTINATIVO IS NULL)

         AND PCTRIBUT.CODST = DECODE(Parametros132.usaTributacaoPorUF,
                                     'S',
                                     pCodST,
                                     PCTRIBUT.CODST)
         AND PCTABPR.CODST =
             DECODE(Parametros132.usaTributacaoPorUF, 'N', PCTRIBUT.CODST(+))

         AND (PCPRODUT.CODFORNEC = PCFORNEC.CODFORNEC)
         AND (PCPRODUT.CODPROD = PCEST.CODPROD)
         AND (RTRIM(LTRIM(PCEST.CODFILIAL)) = pCodFilial)
         AND (PCTABPR.NUMREGIAO = pNumRegiao)
         AND (NVL(PCPRODUT.CODFILIAL, '99') IN (pCodFilial, '99'))
         AND (PCPRODUT.CODPROD = pCodProd)
         AND ((pCodAuxiliar = 0) or PCEMBALAGEM.CODAUXILIAR in (pCodAuxiliar))
         AND DECODE(pOrigemPed,
                    'B',
                    PCEMBALAGEM.PERMITEVENDAATACADO,
                    'R',
                    PCEMBALAGEM.PERMITEVENDAATACADO,
                    'T',
                    NVL(PCEMBALAGEM.ENVIATELEMARKETING,
                        PCEMBALAGEM.PERMITEVENDAATACADO),
                    1) = DECODE(pOrigemPed, 'B', 'S', 'R', 'S', 'T', 'S', 1)
       ORDER BY PCEMBALAGEM.EMBALAGEM;

    RETURN vCursor;
  END;
  ------------------------------------------------------------------------------------

  ------------------------------------------------------------------------------------
  FUNCTION DADOS_PRODUTO_PRECO_EMBALAGEM(pCodProd     IN NUMBER,
                                         pCodFilial   in varchar,
                                         pCodST       in number,
                                         pNumRegiao   in number,
                                         pAbateFrete  in varchar,
                                         pPerFrete    in number,
                                         pCodAuxiliar in number default 0,
                                         pOrigemPed   IN VARCHAR)
    RETURN SYS_REFCURSOR

   IS
    type T_cursor is ref cursor;
    vCursor       T_cursor;
    Parametros132 T_PARAMETROS_132;
  BEGIN

    Parametros132.NumCasasDecimais   := F_BUSCARPARAMETRO_NUM('CON_NUMCASASDECVENDA',
                                                              '99',
                                                              2);
    Parametros132.usaTributacaoPorUF := F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF',
                                                               '99',
                                                               'N');

    OPEN vCursor FOR
      SELECT 0 PTABELA1,
             0 PTABELA2,
             0 PTABELA3,
             0 PTABELA4,
             0 PTABELA5,
             0 PTABELA6,
             0 PTABELA7,
             0 PUNIT,
             0 PUNIT1,
             0 PUNIT2,
             0 PUNIT3,
             0 PUNIT4,
             0 PUNIT5,
             0 PUNIT6,
             0 PUNIT7,
             0 PTABELA_SEMDESCONTOS,
             0 PTABELA_NUMPR1,
             0 STCALCULADO,
             null DATAFIMPRECOFIXO,
             0 PERCOMTABELA,
             0 BASEST,
             0 VLIPI,
             0 VALORDIFALIQUOTAS,
             null vsMSG,
             0 CODESCONTO,
             0 CODESCONTOBASE,
             null POLITICABASECREDITA,
             null POLITICABASEDEBITA,
             0 PERCDESCBASE,
             null DATAFINAL,
             0 PERCDESC,
             0 PERCDESCAUT,
             0 PTABELADESC,
             0 PVENDADESC,
             0 PBASERCA,
             null QUESTIONAUSO,
             null ALTERAPTABELA,
             0 FORCARUTILIZACAO,
             0 PERCDESCMAX,
             null DATAINICIO,
             null QTINI,
             0 QTFIM,
             0 VLRMINIMO_DESCONTO,
             0 VLRMAXIMO_DESCONTO,
             PCPRODUT.CodProd,
             PCTABPR.VLST,
             PCPRODUT.CODFORNEC,
             pctribut.PERCDIFALIQUOTAS,
             NVL(PCTRIBUT.PERDESCCUSTOTRANSF, 0) PERDESCCUSTOTRANSF,
             NVL(PCTRIBUT.MOSTRARPVENDASEMST,
                 (SELECT NVL(MOSTRARPVENDASEMST, 'N') FROM PCCONSUM)) MOSTRARPVENDASEMST,
             NVL(PCTABPR.PERDESCFOB, 0) PERDESCFOB,
             NVL(PCPRODUT.CUSTOREPZFM, PCPRODUT.CUSTOREP) AS PTABELAFABRICAZFM,
             PCPRODUT.CUSTOREP AS PTABELAFABRICA,
             PCEMBALAGEM.PVENDA,
             DECODE(NVL(PCEMBALAGEM.QTUNIT, 1),
                    0,
                    1,
                    NVL(PCEMBALAGEM.QTUNIT, 1)) QTUNIT,
             PCEMBALAGEM.CODAUXILIAR,
             DECODE(NVL(PCEMBALAGEM.FATORPRECO, 0),
                    0,
                    1,
                    PCEMBALAGEM.FATORPRECO) FATORPRECO,
             ROUND((DECODE(pAbateFrete,
                           'F',
                           (PCEMBALAGEM.PVENDA /
                           (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                           'P',
                           DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                  'N',
                                  (PCEMBALAGEM.PVENDA /
                                  (1 +
                                  ((pPerFrete / 100) +
                                  (nvl(pctabpr.percacrescimofrete, 0) / 100)))),
                                  PCEMBALAGEM.PVENDA),
                           PCEMBALAGEM.PVENDA)) * 1,
                   Parametros132.NumCasasDecimais) PVENDA1,
             ROUND((DECODE(pAbateFrete,
                           'F',
                           (PCEMBALAGEM.PVENDA /
                           (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                           'P',
                           DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                  'N',
                                  (PCEMBALAGEM.PVENDA /
                                  (1 +
                                  ((pPerFrete / 100) +
                                  (nvl(pctabpr.percacrescimofrete, 0) / 100)))),
                                  PCEMBALAGEM.PVENDA),
                           PCEMBALAGEM.PVENDA)) * 1,
                   Parametros132.NumCasasDecimais) PVENDA2,
             ROUND((DECODE(pAbateFrete,
                           'F',
                           (PCEMBALAGEM.PVENDA /
                           (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                           'P',
                           DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                  'N',
                                  (PCEMBALAGEM.PVENDA /
                                  (1 +
                                  ((pPerFrete / 100) +
                                  (nvl(pctabpr.percacrescimofrete, 0) / 100)))),
                                  PCEMBALAGEM.PVENDA),
                           PCEMBALAGEM.PVENDA)) * 1,
                   Parametros132.NumCasasDecimais) PVENDA3,
             ROUND((DECODE(pAbateFrete,
                           'F',
                           (PCEMBALAGEM.PVENDA /
                           (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                           'P',
                           DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                  'N',
                                  (PCEMBALAGEM.PVENDA /
                                  (1 +
                                  ((pPerFrete / 100) +
                                  (nvl(pctabpr.percacrescimofrete, 0) / 100)))),
                                  PCEMBALAGEM.PVENDA),
                           PCEMBALAGEM.PVENDA)) * 1,
                   Parametros132.NumCasasDecimais) PVENDA4,
             ROUND((DECODE(pAbateFrete,
                           'F',
                           (PCEMBALAGEM.PVENDA /
                           (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                           'P',
                           DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                  'N',
                                  (PCEMBALAGEM.PVENDA /
                                  (1 +
                                  ((pPerFrete / 100) +
                                  (nvl(pctabpr.percacrescimofrete, 0) / 100)))),
                                  PCEMBALAGEM.PVENDA),
                           PCEMBALAGEM.PVENDA)) * 1,
                   Parametros132.NumCasasDecimais) PVENDA5,
             ROUND((DECODE(pAbateFrete,
                           'F',
                           (PCEMBALAGEM.PVENDA /
                           (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                           'P',
                           DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                  'N',
                                  (PCEMBALAGEM.PVENDA /
                                  (1 +
                                  ((pPerFrete / 100) +
                                  (nvl(pctabpr.percacrescimofrete, 0) / 100)))),
                                  PCEMBALAGEM.PVENDA),
                           PCEMBALAGEM.PVENDA)) * 1,
                   Parametros132.NumCasasDecimais) PVENDA6,
             ROUND((DECODE(pAbateFrete,
                           'F',
                           (PCEMBALAGEM.PVENDA /
                           (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                           'P',
                           DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                  'N',
                                  (PCEMBALAGEM.PVENDA /
                                  (1 +
                                  ((pPerFrete / 100) +
                                  (nvl(pctabpr.percacrescimofrete, 0) / 100)))),
                                  PCEMBALAGEM.PVENDA),
                           PCEMBALAGEM.PVENDA)) * 1,
                   Parametros132.NumCasasDecimais) PVENDA7,
             ROUND((DECODE(pAbateFrete,
                           'F',
                           (PCEMBALAGEM.PVENDAATAC /
                           (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                           'P',
                           DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                  'N',
                                  (PCEMBALAGEM.PVENDAATAC /
                                  (1 +
                                  ((pPerFrete / 100) +
                                  (nvl(pctabpr.percacrescimofrete, 0) / 100)))),
                                  PCEMBALAGEM.PVENDAATAC),
                           PCEMBALAGEM.PVENDAATAC)) * 1,
                   Parametros132.NumCasasDecimais) AS PVENDAATAC,
             ROUND((DECODE(pAbateFrete,
                           'F',
                           (PCEMBALAGEM.PVENDAATAC /
                           (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                           'P',
                           DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                  'N',
                                  (PCEMBALAGEM.PVENDAATAC /
                                  (1 +
                                  ((pPerFrete / 100) +
                                  (nvl(pctabpr.percacrescimofrete, 0) / 100)))),
                                  PCEMBALAGEM.PVENDAATAC),
                           PCEMBALAGEM.PVENDAATAC)) * 1,
                   Parametros132.NumCasasDecimais) PVENDAATAC1,
             ROUND((DECODE(pAbateFrete,
                           'F',
                           (PCEMBALAGEM.PVENDAATAC /
                           (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                           'P',
                           DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                  'N',
                                  (PCEMBALAGEM.PVENDAATAC /
                                  (1 +
                                  ((pPerFrete / 100) +
                                  (nvl(pctabpr.percacrescimofrete, 0) / 100)))),
                                  PCEMBALAGEM.PVENDAATAC),
                           PCEMBALAGEM.PVENDAATAC)) * 1,
                   Parametros132.NumCasasDecimais) PVENDAATAC2,
             ROUND((DECODE(pAbateFrete,
                           'F',
                           (PCEMBALAGEM.PVENDAATAC /
                           (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                           'P',
                           DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                  'N',
                                  (PCEMBALAGEM.PVENDAATAC /
                                  (1 +
                                  ((pPerFrete / 100) +
                                  (nvl(pctabpr.percacrescimofrete, 0) / 100)))),
                                  PCEMBALAGEM.PVENDAATAC),
                           PCEMBALAGEM.PVENDAATAC)) * 1,
                   Parametros132.NumCasasDecimais) PVENDAATAC3,
             ROUND((DECODE(pAbateFrete,
                           'F',
                           (PCEMBALAGEM.PVENDAATAC /
                           (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                           'P',
                           DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                  'N',
                                  (PCEMBALAGEM.PVENDAATAC /
                                  (1 +
                                  ((pPerFrete / 100) +
                                  (nvl(pctabpr.percacrescimofrete, 0) / 100)))),
                                  PCEMBALAGEM.PVENDAATAC),
                           PCEMBALAGEM.PVENDAATAC)) * 1,
                   Parametros132.NumCasasDecimais) PVENDAATAC4,
             ROUND((DECODE(pAbateFrete,
                           'F',
                           (PCEMBALAGEM.PVENDAATAC /
                           (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                           'P',
                           DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                  'N',
                                  (PCEMBALAGEM.PVENDAATAC /
                                  (1 +
                                  ((pPerFrete / 100) +
                                  (nvl(pctabpr.percacrescimofrete, 0) / 100)))),
                                  PCEMBALAGEM.PVENDAATAC),
                           PCEMBALAGEM.PVENDAATAC)) * 1,
                   Parametros132.NumCasasDecimais) PVENDAATAC5,
             ROUND((DECODE(pAbateFrete,
                           'F',
                           (PCEMBALAGEM.PVENDAATAC /
                           (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                           'P',
                           DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                  'N',
                                  (PCEMBALAGEM.PVENDAATAC /
                                  (1 +
                                  ((pPerFrete / 100) +
                                  (nvl(pctabpr.percacrescimofrete, 0) / 100)))),
                                  PCEMBALAGEM.PVENDAATAC),
                           PCEMBALAGEM.PVENDAATAC)) * 1,
                   Parametros132.NumCasasDecimais) PVENDAATAC6,
             ROUND((DECODE(pAbateFrete,
                           'F',
                           (PCEMBALAGEM.PVENDAATAC /
                           (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                           'P',
                           DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                  'N',
                                  (PCEMBALAGEM.PVENDAATAC /
                                  (1 +
                                  ((pPerFrete / 100) +
                                  (nvl(pctabpr.percacrescimofrete, 0) / 100)))),
                                  PCEMBALAGEM.PVENDAATAC),
                           PCEMBALAGEM.PVENDAATAC)) * 1,
                   Parametros132.NumCasasDecimais) PVENDAATAC7,
             ROUND((DECODE(pAbateFrete,
                           'F',
                           (PCEMBALAGEM.POFERTA /
                           (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                           'P',
                           DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                  'N',
                                  (PCEMBALAGEM.POFERTA /
                                  (1 +
                                  ((pPerFrete / 100) +
                                  (nvl(pctabpr.percacrescimofrete, 0) / 100)))),
                                  PCEMBALAGEM.POFERTA),
                           PCEMBALAGEM.POFERTA)),
                   Parametros132.NumCasasDecimais) AS POFERTA,
             PCEMBALAGEM.DTOFERTAINI,
             PCEMBALAGEM.DTOFERTAFIM,
             ROUND((DECODE(pAbateFrete,
                           'F',
                           (PCEMBALAGEM.POFERTAATAC /
                           (1 + (NVL(PCTABPR.PERDESCFOB, 0)) / 100)),
                           'P',
                           DECODE(NVL(PCTABPR.DESCONTAFRETE, 'N'),
                                  'N',
                                  (PCEMBALAGEM.POFERTAATAC /
                                  (1 +
                                  ((pPerFrete / 100) +
                                  (nvl(pctabpr.percacrescimofrete, 0) / 100)))),
                                  PCEMBALAGEM.POFERTAATAC),
                           PCEMBALAGEM.POFERTAATAC)),
                   Parametros132.NumCasasDecimais) AS POFERTAATAC,
             PCEMBALAGEM.DTOFERTAATACINI,
             PCEMBALAGEM.DTOFERTAATACFIM,
             PCEMBALAGEM.QTMULTIPLA,
             NVL(PCEMBALAGEM.QTMINIMAATACADO, 0) QTMINIMAATACADO,
             PCTRIBUT.CODST,
             PCPRODUT.PERCBONIFICVENDA,
             NVL(PCTRIBUT.PERACRESCISMOPF, 0) PERACRESCISMOPF,
             PCPRODUT.PRECOFIXO,
             PCPRODUT.CODLINHAPROD,
             DECODE((SELECT COUNT(*)
                      FROM pcprodfilial
                     WHERE CodProd = PCPRODUT.CodProd
                       AND codfilial = PCEST.CODFILIAL),
                    0,
                    DECODE(NVL(PCPRODUT.MULTIPLO, 0),
                           0,
                           DECODE(NVL(PCPRODUT.ACEITAVENDAFRACAO, 'N'),
                                  'N',
                                  1,
                                  (SELECT 1 / CASE NVL(numcasasdecestoque, 1)
                                            WHEN 1 THEN
                                             10
                                            WHEN 2 THEN
                                             100
                                            WHEN 3 THEN
                                             1000
                                            WHEN 4 THEN
                                             10000
                                            WHEN 5 THEN
                                             100000
                                            WHEN 6 THEN
                                             1000000
                                          END
                                     FROM pcconsum
                                    WHERE ROWNUM = 1)),
                           PCPRODUT.MULTIPLO),
                    NVL(DECODE((SELECT MULTIPLO
                                 FROM pcprodfilial
                                WHERE CodProd = PCPRODUT.CodProd
                                  AND codfilial = PCEST.CODFILIAL),
                               0,
                               DECODE(NVL(PCPRODUT.ACEITAVENDAFRACAO, 'N'),
                                      'N',
                                      1,
                                      (SELECT 1 / CASE NVL(numcasasdecestoque, 1)
                                                WHEN 1 THEN
                                                 10
                                                WHEN 2 THEN
                                                 100
                                                WHEN 3 THEN
                                                 1000
                                                WHEN 4 THEN
                                                 10000
                                                WHEN 5 THEN
                                                 100000
                                                WHEN 6 THEN
                                                 1000000
                                              END
                                         FROM pcconsum
                                        WHERE ROWNUM = 1)),
                               (SELECT MULTIPLO
                                  FROM pcprodfilial
                                 WHERE CodProd = PCPRODUT.CodProd
                                   AND codfilial = PCEST.CODFILIAL)),
                        DECODE(NVL(PCPRODUT.MULTIPLO, 0),
                               0,
                               DECODE(NVL(PCPRODUT.ACEITAVENDAFRACAO, 'N'),
                                      'N',
                                      1,
                                      (SELECT 1 / CASE NVL(numcasasdecestoque, 1)
                                                WHEN 1 THEN
                                                 10
                                                WHEN 2 THEN
                                                 100
                                                WHEN 3 THEN
                                                 1000
                                                WHEN 4 THEN
                                                 10000
                                                WHEN 5 THEN
                                                 100000
                                                WHEN 6 THEN
                                                 1000000
                                              END
                                         FROM pcconsum
                                        WHERE ROWNUM = 1)),
                               PCPRODUT.MULTIPLO))) MULTIPLO,
             NVL(PCPRODUT.TIPOMERC, 'OT') TIPOMERC,
             NVL(PCPRODUT.CodProdPRINC, PCPRODUT.CodProd) CodProdPRINC,
             NVL(PCTRIBUT.APLICAACRESCPJISENTA, 'S') APLICAACRESCPJISENTA,
             NVL(PCPRODUT.ChecarMultiploVendaBNF, 'S') ChecarMultiploVendaBNF,
             pctabpr.ptabela,
             PCTRIBUT.PERCREDPVENDASIMPLESNAC,
             pctabpr.percdescsimplesnac,
             NVL(PCPRODUT.TIPOCUSTOTRANSF, 'P') TIPOCUSTOTRANSF,
             NVL(PCTRIBUT.BNFNAOCALCULAICMS, 'N') BNFNAOCALCULAICMS,
             PCTRIBUT.PERACRESCISMOSIMPNAC,
             0 VALOR_DESCONTO_ICMS,
             0 CODIGOPRECOFIXO,
             'N' USANDOPOFERTA,
             0 PERCENTUAL_REDUCAO_IPI
        FROM PCTABPR, PCEMBALAGEM, PCPRODUT, PCTRIBUT, PCEST, PCFORNEC
       WHERE PCTABPR.CodProd = PCPRODUT.CodProd
         AND PCEMBALAGEM.CodProd = PCPRODUT.CodProd
         AND PCEMBALAGEM.CODFILIAL = pCodFilial
         AND (PCEMBALAGEM.CODFUNCINATIVO IS NULL OR
             PCEMBALAGEM.DTINATIVO IS NULL)

         AND PCTRIBUT.CODST = DECODE(Parametros132.usaTributacaoPorUF,
                                     'S',
                                     pCodST,
                                     PCTRIBUT.CODST)
         AND PCTABPR.CODST =
             DECODE(Parametros132.usaTributacaoPorUF, 'N', PCTRIBUT.CODST(+))

         AND (PCPRODUT.CODFORNEC = PCFORNEC.CODFORNEC)
         AND (PCPRODUT.CodProd = PCEST.CodProd)
         AND (RTRIM(LTRIM(PCEST.CODFILIAL)) = pCodFilial)
         AND (PCTABPR.NUMREGIAO = pNumRegiao)
         AND (NVL(PCPRODUT.CODFILIAL, '99') IN (pCodFilial, '99'))
         AND (PCPRODUT.CodProd = pCodProd)
         AND ((pCodAuxiliar = 0) or PCEMBALAGEM.CODAUXILIAR in (pCodAuxiliar))
         AND DECODE(pOrigemPed,
                    'B',
                    PCEMBALAGEM.PERMITEVENDAATACADO,
                    'R',
                    PCEMBALAGEM.PERMITEVENDAATACADO,
                    'T',
                    NVL(PCEMBALAGEM.ENVIATELEMARKETING,
                        PCEMBALAGEM.PERMITEVENDAATACADO),
                    1) = DECODE(pOrigemPed, 'B', 'S', 'R', 'S', 'T', 'S', 1)

       ORDER BY PCEMBALAGEM.EMBALAGEM;

    RETURN vCursor;
  END;
  ------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------

  FUNCTION BUSCAR_DADOS_PRODUTO(pCodProd            IN NUMBER,
                                pCodFilial          in varchar,
                                pNumRegiao          in number,
                                pCodUsur            in number,
                                pAbateFrete         in varchar,
                                pPerFrete           in number,
                                pCodCli             in number,
                                pCodContrato        in number,
                                pOrigemPed          in varchar,
                                pCodAuxiliar        in number,
                                pVendaTriangular    in varchar2,
                                pCodEnderecoEntrega in number,
                                pCondVenda          in number)
    RETURN T_DADOS_PRODUTO IS
    DADOS_SAIDA              T_DADOS_PRODUTO;
    vCursor                  SYS_REFCURSOR;
    Parametros132            T_PARAMETROS_132;
    DADOS_CLIENTE            T_CLIENTE;
    vnCodST                  integer;
    vnContPCUSURFORNEC       number;
    vnContador               number;
    vbProdutoValido          boolean;
    vnContadorPCRESTRICLIFOR number;
    vnContadorRESTRICLIFOR   number;
    vnContadorPCCONTRATO     number;
    vnContadorCONTRATO       number;
  BEGIN
    Parametros132.usaTributacaoPorUF          := F_BUSCARPARAMETRO_ALFA('CON_USATRIBUTACAOPORUF',
                                                                        '99',
                                                                        'N');
    Parametros132.UtilizaPCUSURFORNEC         := F_BUSCARPARAMETRO_ALFA('CON_UTILIZAPCUSURFORNEC',
                                                                        '99',
                                                                        'N');
    Parametros132.ValidaRestricoesVendaPorRCA := F_BUSCARPARAMETRO_ALFA('CON_VALIDARESTRICOESVENDAPORRCA',
                                                                        '99',
                                                                        'N');

    Parametros132.UtilizaVendaPorEmbalagem := 'N';
    if ((F_BUSCARPARAMETRO_ALFA('CON_UTILIZAVENDAPOREMBALAGEM', '99', 'N') = 'S') OR
       (F_BUSCARPARAMETRO_ALFA('FIL_UTILIZAVENDAPOREMBALAGEM',
                                pCodFilial,
                                'N') = 'S')) THEN
      Parametros132.UtilizaVendaPorEmbalagem := 'S';
    END IF;

    Parametros132.PrecoPorEmbalagem := 'N';
    if ((F_BUSCARPARAMETRO_ALFA('CON_PRECOPOREMBALAGEM', '99', 'N') = 'S') OR
       (F_BUSCARPARAMETRO_ALFA('FIL_PRECOPOREMBALAGEM', pCodFilial, 'N') = 'S')) THEN
      Parametros132.PrecoPorEmbalagem := 'S';
    END IF;

    DADOS_CLIENTE := BUSCAR_CLIENTE(pCodCli,
                                    NULL,
                                    pCodEnderecoEntrega,
                                    pCodFilial);

    vnCodST := RETORNA_CODIGO_TRIBUTACAO(DADOS_CLIENTE,
                                         pCodProd,
                                         pCodFilial,
                                         0,
                                         pVendaTriangular,
                                         pCondVenda,
                                         pCodEnderecoEntrega);

    ------------------------------------ Contadores de verificação de restrição -------------------------------------------

    SELECT COUNT(1)
      into vnContPCUSURFORNEC
      FROM PCUSURFORNEC
     WHERE CODUSUR = pCodUsur;

    select count(1)
      into vnContadorPCRESTRICLIFOR
      from PCRESTRICLIFOR
     where codcli = pCodCli;

    select count(1)
      into vnContadorPCCONTRATO
      from PCCONTRATO
     where numcontrato = pCodContrato;
    -----------------------------------------------------------------------------------------------------------------------

    IF (Parametros132.UtilizaVendaPorEmbalagem = 'S') THEN
      IF (Parametros132.PrecoPorEmbalagem = 'S') THEN
        vCursor := DADOS_PRODUTO_PRECO_EMBALAGEM(pCodProd,
                                                 pCodFilial,
                                                 vnCodST,
                                                 pNumRegiao,
                                                 pAbateFrete,
                                                 pPerFrete,
                                                 pCodAuxiliar,
                                                 pOrigemPed);
      ELSE
        vCursor := DADOS_PRODUTO_EMBALAGEM(pCodProd,
                                           pCodFilial,
                                           vnCodST,
                                           pNumRegiao,
                                           pAbateFrete,
                                           pPerFrete,
                                           pCodAuxiliar,
                                           pOrigemPed);
      END IF;
    ELSE
      vCursor := DADOS_PRODUTO(pCodProd,
                               pCodFilial,
                               vnCodST,
                               pNumRegiao,
                               pAbateFrete,
                               pPerFrete);
    END IF;

    --loop

    vbProdutoValido := True;
    FETCH vCursoR
      INTO DADOS_SAIDA;

    if vCursor%found then

      -------------------------------------- Verifica restrição de fornecedores por RCA --------------------------------------
      IF (Parametros132.UtilizaPCUSURFORNEC = 'S') THEN
        IF (Parametros132.ValidaRestricoesVendaPorRCA = 'N') OR
           ((Parametros132.ValidaRestricoesVendaPorRCA = 'S') AND
           (vnContPCUSURFORNEC > 0)) THEN
          select count(1)
            into vnContador
            FROM PCUSURFORNEC
           WHERE PCUSURFORNEC.CODFORNEC = DADOS_SAIDA.CODFORNEC
             AND PCUSURFORNEC.CODUSUR = pCodUsur;
          if vnContador = 0 then
            vbProdutoValido := False;
          END IF;
        END IF;
      END IF;
      -----------------------------------------------------------------------------------------------------------------------

      -------------------------------------- Verifica restrição de clientes por fornecedores --------------------------------
      IF (vnContadorPCRESTRICLIFOR > 0) THEN
        select count(1)
          into vnContadorRESTRICLIFOR
          FROM PCRESTRICLIFOR
         WHERE PCRESTRICLIFOR.CODFORNEC = DADOS_SAIDA.CODFORNEC
           AND PCRESTRICLIFOR.CODCLI = pCodCli;

        if vnContadorRESTRICLIFOR = 0 then
          vbProdutoValido := False;
        END IF;

      END IF;
      -----------------------------------------------------------------------------------------------------------------------

      -------------------------------------- Validação de Contratos ---------------------------------------------------------
      IF (vnContadorPCCONTRATO > 0) THEN
        select count(1)
          into vnContadorCONTRATO
          FROM PCCONTRATOI
         WHERE PCCONTRATOI.CODPROD = DADOS_SAIDA.CODPROD
           AND PCCONTRATOI.CODCONTRATO = pCodContrato;
        if vnContadorCONTRATO = 0 then
          vbProdutoValido := False;
        END IF;
      END IF;
      -----------------------------------------------------------------------------------------------------------------------

    end if;

    if vbProdutoValido then
      RETURN DADOS_SAIDA;
    END IF;

    --end loop;

  END BUSCAR_DADOS_PRODUTO;

  FUNCTION APLICA_PERCENTUAL(base in number, percentual in number)
    return number is
  begin
    return base *(1 + (percentual / 100));
  end;

  FUNCTION APLICA_ACRESCIMO_PF(DADOS_CLIENTE        IN T_CLIENTE,
                               APLICAACRESCPJISENTA IN varchar,
                               pTipoDocumento       IN varchar,
                               pCondVenda           in number,
                               pCodFilial           in varchar2,
                               percAcrescimoSN      in number,
                               percAcrescimoPF      in number)
    RETURN T_ACRESCIMOS_PF_SN IS
    acrescimoParaPfComIe        boolean;
    acrescimoCupom              boolean;
    usaMedicamentos             boolean;
    aplicaAcrescimoPjConsumidor boolean;
    resultado                   T_ACRESCIMOS_PF_SN;

  BEGIN
    acrescimoParaPfComIe := F_BUSCARPARAMETRO_ALFA('CON_ACRESCIMOPFCOMIE',
                                                   '99',
                                                   'N') = 'S';
    acrescimoCupom       := F_BUSCARPARAMETRO_ALFA('PERCACRESCVENDACUPOM',
                                                   pCodFilial,
                                                   'N') = 'S';
    usaMedicamentos      := F_BUSCARPARAMETRO_ALFA('UTILIZACONTROLEMEDICAMENTOS',
                                                   pCodFilial,
                                                   'N') = 'S';

    aplicaAcrescimoPjConsumidor := (DADOS_CLIENTE.TipoPessoa = 'J') and
                                   (DADOS_CLIENTE.Contribuinte = 'N') and
                                   (DADOS_CLIENTE.ConsumidorFinal = 'S') and
                                   (APLICAACRESCPJISENTA = 'S');

    resultado.aplicaAcrescimo := false;

    if (not pCondVenda in (8, 10, 14)) and (not aplicaAcrescimoPjConsumidor) or
       (((not usaMedicamentos) or
       (usaMedicamentos and DADOS_CLIENTE.OrigemPreco <> 'F'))) then

      if acrescimoParaPfComIe then

        if ((((APLICAACRESCPJISENTA = 'S') and
           ((DADOS_CLIENTE.IEENT = 'ISENTA') or
           (DADOS_CLIENTE.IEENT = 'ISENTO'))) or
           ((DADOS_CLIENTE.TIPOPESSOA = 'F') or
           (DADOS_CLIENTE.CONSUMIDORFINAL = 'S'))) and
           (DADOS_CLIENTE.Contribuinte = 'N')) or
           ((pTipoDocumento = 'C') and (acrescimoParaPfComIe)) then

          resultado.aplicaAcrescimo := true;
        end if;

      elsif ((((APLICAACRESCPJISENTA = 'S') and
            ((DADOS_CLIENTE.IEENT = 'ISENTA') or
            (DADOS_CLIENTE.IEENT = 'ISENTO'))) or
            (((DADOS_CLIENTE.TipoPessoa = 'F') or
            (DADOS_CLIENTE.CONSUMIDORFINAL = 'S')) and
            (Trim(DADOS_CLIENTE.IEENT) is null))) and
            (DADOS_CLIENTE.Contribuinte = 'N')) or
            ((pTipoDocumento = 'C') and (acrescimoCupom)) then

        resultado.aplicaAcrescimo := true;

      else
        resultado.aplicaAcrescimo := false;

      end if;

    end if;

    if resultado.aplicaAcrescimo then
      resultado.percAcrescimoPF := percAcrescimoPF;
    end if;

    if (DADOS_CLIENTE.TipoEmpresa = 'SN') and (percAcrescimoSN > 0) then
      resultado.aplicaAcrescimo := true;
      resultado.percAcrescimoPF := percAcrescimoSN;
    end if;

    return resultado;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN null;

  END APLICA_ACRESCIMO_PF;

  FUNCTION DEFINIRCODFISCAL(PCODFILIAL             IN VARCHAR2,
                            PCODFILIALNF           IN VARCHAR2,
                            PCONDVENDA             IN NUMBER,
                            PCODCOB                IN VARCHAR2,
                            PCODCLI                IN NUMBER,
                            PVENDAEXPORTACAO       IN VARCHAR2,
                            PVENDALOCALESTRANGEIRO IN VARCHAR2,
                            PITEMBNFTV1            IN VARCHAR2,
                            PVENDA                 IN VARCHAR2,
                            DADOS_PRODUTO          T_DADOS_PRODUTO)
    return T_CODFISCAL is
    T_CAB   PCPEDC%ROWTYPE;
    T_ITEM  PCPEDI %ROWTYPE;
    retorno T_CODFISCAL;
  begin

    T_CAB.CODFILIALNF       := pCODFILIALNF;
    T_CAB.CODFILIAL         := pCODFILIAL;
    T_CAB.CONDVENDA         := pCONDVENDA;
    T_CAB.CODCOB            := pCODCOB;
    T_CAB.CODCLI            := pCODCLI;
    T_CAB.VENDAEXPORTACAO   := pVENDAEXPORTACAO;
    T_CAB.VENDALOCESTRANG   := pVendaLocalEstrangeiro;
    T_CAB.NUMPED            := 0;
    T_ITEM.CODPROD          := DADOS_PRODUTO.CODPROD;
    T_ITEM.CODCLI           := pCODCLI;
    T_ITEM.CODST            := DADOS_PRODUTO.CODST;
    T_ITEM.BONIFIC          := pItemBNFTV1;
    T_ITEM.VLDESCSUFRAMA    := DADOS_PRODUTO.VALOR_DESCONTO_ICMS;
    T_ITEM.VLDESCICMISENCAO := DADOS_PRODUTO.VALOR_DESCONTO_ICMS;
    T_ITEM.PVENDA           := pVenda;

    FERRAMENTAS.DEFINIRCODFISCAL(T_CAB,
                                 T_ITEM,
                                 retorno.CODFISCAL,
                                 retorno.SITTRIBUT,
                                 retorno.MSG);

    return retorno;

  end;

  FUNCTION BUSCAR_DADOS_PRECO_FIXO(codigoPrecoFixo in number)
    return T_PRECO_FIXO is
    dados T_PRECO_FIXO;
  begin

    begin
      select NVL(consideraprecosemimposto, 'N') consideraprecosemimposto,
             nvl(precofixo, 0)
        into dados.ConsideraPrecoSemImposto, dados.precoFixo
        from pcprecoprom
       where codprecoprom = codigoPrecoFixo;
    exception
      when others then
        dados.ConsideraPrecoSemImposto := 'N';
        dados.precoFixo                := 0;
    end;

    return dados;

  end;

  FUNCTION BUSCAR_CUSTOS_ESTOQUE(pCodprod   in number,
                                 pCodFilial in varchar2,
                                 pTipoCusto in varchar) RETURN NUMBER IS
    vnCUSTO     number;
    vsTIPOCUSTO varchar2(1);
  BEGIN

    vsTIPOCUSTO := pTipoCusto;

    case vsTIPOCUSTO --tipos 'A', 'I' e 'O' não são da PCEST.
      when 'A' then
        begin
          SELECT MAX(DECODE(PUNIT, 0, PUNITCONT, PUNIT))
            INTO vnCUSTO
            FROM PCMOV
           WHERE PCMOV.DTCANCEL IS NULL
             AND PCMOV.CODOPER LIKE 'E%'
             AND NUMTRANSVENDA IS NULL
             AND PCMOV.CODPROD = pCODPROD
             AND PCMOV.CODFILIAL = pCODFILIAL;
        exception
          when others then
            vsTIPOCUSTO := 'U';
        end;
      when 'I' then
        begin
          SELECT (NVL(PCEST.VALORULTENT, 0) - NVL(PCMOV.VLIPI, 0))
            INTO vnCUSTO
            FROM PCMOV, PCEST
           WHERE PCMOV.DTCANCEL IS NULL
             AND PCMOV.CODOPER LIKE 'E%'
             AND PCMOV.NUMTRANSENT = NVL(PCEST.NUMTRANSENTULTENT, 0)
             AND PCMOV.CODFILIAL = PCEST.CODFILIAL
             AND PCMOV.CODPROD = PCEST.CODPROD
             AND PCMOV.NUMTRANSVENDA IS NULL
             AND PCMOV.CODPROD = pCODPROD
             AND PCEST.CODFILIAL = pCODFILIAL;
        exception
          when others then
            vsTIPOCUSTO := 'U';
        end;

      when 'O' then
        begin
          select PCPRODUT.CUSTOFORNEC
            into vnCUSTO
            from PCPRODUT
           where codprod = pCodProd;
        exception
          when others then
            vsTIPOCUSTO := 'U';
        end;

      else
        --demais tipos são da PCEST
        begin
          select case vsTIPOCUSTO
                   when 'E' then
                    CUSTOREP
                   when 'R' then
                    CUSTOREAL
                   when 'C' then
                    CUSTOCONT
                   when 'F' then
                    CUSTOFIN
                   when 'U' then
                    CUSTOULTENT
                   when 'S' then
                    CUSTOREALSEMST
                   when 'T' then
                    VLULTENTCONTSEMST
                   when 'V' then
                    VALORULTENT
                 end case
            into vnCUSTO
            from pcest
           where codprod = pCODPROD
             and codfilial = pCODFILIAL;
        exception
          when others then
            vnCUSTO := 0;
        end;

    end case;

    --contingência dos tipos 'A', 'I', 'O'
    if vnCUSTO = 0 and vsTIPOCUSTO = 'U' then
      begin
        select CUSTOULTENT
          into vnCUSTO
          from PCEST
         where codprod = pCODPROD
           and codfilial = pCODFILIAL;
      exception
        when others then
          vnCUSTO := 0;
      end;
    end if;

    RETURN vnCUSTO;

  END BUSCAR_CUSTOS_ESTOQUE;

  PROCEDURE RETORNAR_DADOS_PCPLPAGI(PCODPLPAG     IN NUMBER,
                                    PCODLINHAPROD IN NUMBER,
                                    VNPERBONIFIC  IN OUT NUMBER,
                                    VNPERDESCCOM  IN OUT NUMBER) IS
  BEGIN
    SELECT PERCBONIFIC, PERCDESCCOM
      INTO VNPERBONIFIC, VNPERDESCCOM
      FROM PCPLPAGI
     WHERE CODPLPAG = PCODPLPAG
       AND CODLINHAPROD = PCODLINHAPROD;

  EXCEPTION
    WHEN OTHERS THEN
      vnPERBONIFIC := 0;
      vnPERDESCCOM := 0;

  END RETORNAR_DADOS_PCPLPAGI;

  FUNCTION VERIFICAR_PERMISSAO_ROTINA(pCodRotina   in NUMBER,
                                      pCodControle in NUMBER,
                                      pCodUsuario  in NUMBER) return boolean IS
    vsPermissao varchar2(1);
  BEGIN

    begin
      SELECT NVL(PCCONTROI.ACESSO, 'N') ACESSO
        INTO vsPermissao
        FROM PCCONTROI
       WHERE PCCONTROI.CODROTINA = pCODROTINA
         AND PCCONTROI.CODCONTROLE = pCODCONTROLE
         AND PCCONTROI.CODUSUARIO = pCODUSUARIO;
    exception
      when others then
        vsPermissao := 'N';
    end;

    return vsPermissao = 'S';

  END VERIFICAR_PERMISSAO_ROTINA;

  FUNCTION BUSCARPRECOTV7(pNumPedTV7 in number,
                          pCodProd   in number,
                          pMsg       out varchar2) return number is
    vnPrecoProduto number;
  begin

    begin
      select pvenda
        into vnPrecoProduto
        from pcpedi
       where numped = pNumPedTV7
         and pCodProd = pCodProd
         and posicao <> 'C';
    exception
      when no_data_found then
        pMsg := 'Produto não localizado no pedido TV7 informado';
    end;

    return vnPrecoProduto;

  end buscarPrecoTV7;

  procedure DEFINIR_PRECO_TABELA(pOferta               in varchar,
                                 pOfertaAtac           in varchar,
                                 pQtde                 in number,
                                 DADOS_PLANO_PAGAMENTO in T_PLANO_PAGAMENTO,
                                 DADOS_PRODUTO         in out T_DADOS_PRODUTO,
                                 Parametros132         in T_PARAMETROS_132) is
  begin

    if pOferta = 'S' or pOfertaAtac = 'S' then

      if pOferta = 'S' then
        DADOS_PRODUTO.PTABELA       := DADOS_PRODUTO.POFERTA;
        DADOS_PRODUTO.USANDOPOFERTA := 'S';
      end if;

      if pOfertaAtac = 'S' then
        DADOS_PRODUTO.PTABELA       := DADOS_PRODUTO.POFERTAATAC;
        DADOS_PRODUTO.USANDOPOFERTA := 'S';
      end if;

    else

      DADOS_PRODUTO.USANDOPOFERTA := 'N';

      DADOS_PRODUTO.PTABELA_NUMPR1 := DADOS_PRODUTO.PVENDA1;

      if Parametros132.UtilizaVendaPorEmbalagem = 'N' then
        case Parametros132.TipoPrecificacao
          when 'P' then
            -- Por default o Preço de Venda é o de Varejo.
            DADOS_PRODUTO.PTABELA1 := DADOS_PRODUTO.PVENDA1;
            DADOS_PRODUTO.PTABELA2 := DADOS_PRODUTO.PVENDA2;
            DADOS_PRODUTO.PTABELA3 := DADOS_PRODUTO.PVENDA3;
            DADOS_PRODUTO.PTABELA4 := DADOS_PRODUTO.PVENDA4;
            DADOS_PRODUTO.PTABELA5 := DADOS_PRODUTO.PVENDA5;
            DADOS_PRODUTO.PTABELA6 := DADOS_PRODUTO.PVENDA6;
            DADOS_PRODUTO.PTABELA7 := DADOS_PRODUTO.PVENDA7;
          when 'V' then
            if (pQtde >= DADOS_PRODUTO.QTMINIMAATACADO) and
               (DADOS_PRODUTO.QTMINIMAATACADO > 0) then
              -- Por default o Preço de Venda é o de Varejo.
              DADOS_PRODUTO.PTABELA1 := DADOS_PRODUTO.PVENDAATAC1;
              DADOS_PRODUTO.PTABELA2 := DADOS_PRODUTO.PVENDAATAC2;
              DADOS_PRODUTO.PTABELA3 := DADOS_PRODUTO.PVENDAATAC3;
              DADOS_PRODUTO.PTABELA4 := DADOS_PRODUTO.PVENDAATAC4;
              DADOS_PRODUTO.PTABELA5 := DADOS_PRODUTO.PVENDAATAC5;
              DADOS_PRODUTO.PTABELA6 := DADOS_PRODUTO.PVENDAATAC6;
              DADOS_PRODUTO.PTABELA7 := DADOS_PRODUTO.PVENDAATAC7;
            else
              --if (pQtde >= DADOS_PRODUTO.QTMINIMAATACADO) and (DADOS_PRODUTO.QTMINIMAATACADO > 0)
              -- Por default o Preço de Venda é o de Varejo.
              DADOS_PRODUTO.PTABELA1 := DADOS_PRODUTO.PVENDA1;
              DADOS_PRODUTO.PTABELA2 := DADOS_PRODUTO.PVENDA2;
              DADOS_PRODUTO.PTABELA3 := DADOS_PRODUTO.PVENDA3;
              DADOS_PRODUTO.PTABELA4 := DADOS_PRODUTO.PVENDA4;
              DADOS_PRODUTO.PTABELA5 := DADOS_PRODUTO.PVENDA5;
              DADOS_PRODUTO.PTABELA6 := DADOS_PRODUTO.PVENDA6;
              DADOS_PRODUTO.PTABELA7 := DADOS_PRODUTO.PVENDA7;
            end if;

          when 'A' then
            if (pQtde < DADOS_PRODUTO.QTMINIMAATACADO) and
               (DADOS_PRODUTO.QTMINIMAATACADO > 0) then
              -- Por default o Preço de Venda é o de Varejo.
              DADOS_PRODUTO.PTABELA1 := DADOS_PRODUTO.PVENDAATAC1;
              DADOS_PRODUTO.PTABELA2 := DADOS_PRODUTO.PVENDAATAC2;
              DADOS_PRODUTO.PTABELA3 := DADOS_PRODUTO.PVENDAATAC3;
              DADOS_PRODUTO.PTABELA4 := DADOS_PRODUTO.PVENDAATAC4;
              DADOS_PRODUTO.PTABELA5 := DADOS_PRODUTO.PVENDAATAC5;
              DADOS_PRODUTO.PTABELA6 := DADOS_PRODUTO.PVENDAATAC6;
              DADOS_PRODUTO.PTABELA7 := DADOS_PRODUTO.PVENDAATAC7;
            else
              -- Por default o Preço de Venda é o de Varejo.
              DADOS_PRODUTO.PTABELA1 := DADOS_PRODUTO.PVENDA1;
              DADOS_PRODUTO.PTABELA2 := DADOS_PRODUTO.PVENDA2;
              DADOS_PRODUTO.PTABELA3 := DADOS_PRODUTO.PVENDA3;
              DADOS_PRODUTO.PTABELA4 := DADOS_PRODUTO.PVENDA4;
              DADOS_PRODUTO.PTABELA5 := DADOS_PRODUTO.PVENDA5;
              DADOS_PRODUTO.PTABELA6 := DADOS_PRODUTO.PVENDA6;
              DADOS_PRODUTO.PTABELA7 := DADOS_PRODUTO.PVENDA7;
            end if;
        end case; -- case TipoPrecificacao
      else
        -- if UTILIZAVENDAPOREMBALAGEM = 'N'
        if Parametros132.PrecoPorEmbalagem = 'S' then
          -- Por default o Preço de Venda é o de Varejo.
          if (pQtde >= DADOS_PRODUTO.QTMINIMAATACADO) and
             (DADOS_PRODUTO.QTMINIMAATACADO > 0) then
            -- Por default o Preço de Venda é o de Varejo.
            if (not VERIFICAR_PERMISSAO_ROTINA(316, 46, 1)) then
              --ajustar para demais rotinas
              DADOS_PRODUTO.PTABELA1 := DADOS_PRODUTO.PVENDAATAC1;
              DADOS_PRODUTO.PTABELA2 := DADOS_PRODUTO.PVENDAATAC2;
              DADOS_PRODUTO.PTABELA3 := DADOS_PRODUTO.PVENDAATAC3;
              DADOS_PRODUTO.PTABELA4 := DADOS_PRODUTO.PVENDAATAC4;
              DADOS_PRODUTO.PTABELA5 := DADOS_PRODUTO.PVENDAATAC5;
              DADOS_PRODUTO.PTABELA6 := DADOS_PRODUTO.PVENDAATAC6;
              DADOS_PRODUTO.PTABELA7 := DADOS_PRODUTO.PVENDAATAC7;
            end if;
            if DADOS_PRODUTO.PTABELA <= 0 then
              DADOS_PRODUTO.PTABELA1 := DADOS_PRODUTO.PVENDA1;
              DADOS_PRODUTO.PTABELA2 := DADOS_PRODUTO.PVENDA2;
              DADOS_PRODUTO.PTABELA3 := DADOS_PRODUTO.PVENDA3;
              DADOS_PRODUTO.PTABELA4 := DADOS_PRODUTO.PVENDA4;
              DADOS_PRODUTO.PTABELA5 := DADOS_PRODUTO.PVENDA5;
              DADOS_PRODUTO.PTABELA6 := DADOS_PRODUTO.PVENDA6;
              DADOS_PRODUTO.PTABELA7 := DADOS_PRODUTO.PVENDA7;
            end if;
          else
            -- Por default o Preço de Venda é o de Varejo.
            DADOS_PRODUTO.PTABELA1 := DADOS_PRODUTO.PVENDA1;
            DADOS_PRODUTO.PTABELA2 := DADOS_PRODUTO.PVENDA2;
            DADOS_PRODUTO.PTABELA3 := DADOS_PRODUTO.PVENDA3;
            DADOS_PRODUTO.PTABELA4 := DADOS_PRODUTO.PVENDA4;
            DADOS_PRODUTO.PTABELA5 := DADOS_PRODUTO.PVENDA5;
            DADOS_PRODUTO.PTABELA6 := DADOS_PRODUTO.PVENDA6;
            DADOS_PRODUTO.PTABELA7 := DADOS_PRODUTO.PVENDA7;
          end if;
        else
          case Parametros132.TipoPrecificacao
            when 'P' then
              -- Por default o Preço de Venda é o de Varejo.
              DADOS_PRODUTO.PTABELA1 := DADOS_PRODUTO.PVENDA1;
              DADOS_PRODUTO.PTABELA2 := DADOS_PRODUTO.PVENDA2;
              DADOS_PRODUTO.PTABELA3 := DADOS_PRODUTO.PVENDA3;
              DADOS_PRODUTO.PTABELA4 := DADOS_PRODUTO.PVENDA4;
              DADOS_PRODUTO.PTABELA5 := DADOS_PRODUTO.PVENDA5;
              DADOS_PRODUTO.PTABELA6 := DADOS_PRODUTO.PVENDA6;
              DADOS_PRODUTO.PTABELA7 := DADOS_PRODUTO.PVENDA7;
            when 'V' then
              if (pQtde >= DADOS_PRODUTO.QTMINIMAATACADO) and
                 (DADOS_PRODUTO.QTMINIMAATACADO > 0) then
                -- Por default o Preço de Venda é o de Varejo.
                DADOS_PRODUTO.PTABELA1 := DADOS_PRODUTO.PVENDAATAC1;
                DADOS_PRODUTO.PTABELA2 := DADOS_PRODUTO.PVENDAATAC2;
                DADOS_PRODUTO.PTABELA3 := DADOS_PRODUTO.PVENDAATAC3;
                DADOS_PRODUTO.PTABELA4 := DADOS_PRODUTO.PVENDAATAC4;
                DADOS_PRODUTO.PTABELA5 := DADOS_PRODUTO.PVENDAATAC5;
                DADOS_PRODUTO.PTABELA6 := DADOS_PRODUTO.PVENDAATAC6;
                DADOS_PRODUTO.PTABELA7 := DADOS_PRODUTO.PVENDAATAC7;
              else
                -- Por default o Preço de Venda é o de Varejo.
                DADOS_PRODUTO.PTABELA1 := DADOS_PRODUTO.PVENDA1;
                DADOS_PRODUTO.PTABELA2 := DADOS_PRODUTO.PVENDA2;
                DADOS_PRODUTO.PTABELA3 := DADOS_PRODUTO.PVENDA3;
                DADOS_PRODUTO.PTABELA4 := DADOS_PRODUTO.PVENDA4;
                DADOS_PRODUTO.PTABELA5 := DADOS_PRODUTO.PVENDA5;
                DADOS_PRODUTO.PTABELA6 := DADOS_PRODUTO.PVENDA6;
                DADOS_PRODUTO.PTABELA7 := DADOS_PRODUTO.PVENDA7;
              end if; --aqui

            when 'A' then
              if (pQtde < DADOS_PRODUTO.QTMINIMAATACADO) and
                 (DADOS_PRODUTO.QTMINIMAATACADO > 0) then
                -- Por default o Preço de Venda é o de Varejo.
                DADOS_PRODUTO.PTABELA1 := DADOS_PRODUTO.PVENDAATAC1;
                DADOS_PRODUTO.PTABELA2 := DADOS_PRODUTO.PVENDAATAC2;
                DADOS_PRODUTO.PTABELA3 := DADOS_PRODUTO.PVENDAATAC3;
                DADOS_PRODUTO.PTABELA4 := DADOS_PRODUTO.PVENDAATAC4;
                DADOS_PRODUTO.PTABELA5 := DADOS_PRODUTO.PVENDAATAC5;
                DADOS_PRODUTO.PTABELA6 := DADOS_PRODUTO.PVENDAATAC6;
                DADOS_PRODUTO.PTABELA7 := DADOS_PRODUTO.PVENDAATAC7;
              else
                -- Por default o Preço de Venda é o de Varejo.
                DADOS_PRODUTO.PTABELA1 := DADOS_PRODUTO.PVENDA1;
                DADOS_PRODUTO.PTABELA2 := DADOS_PRODUTO.PVENDA2;
                DADOS_PRODUTO.PTABELA3 := DADOS_PRODUTO.PVENDA3;
                DADOS_PRODUTO.PTABELA4 := DADOS_PRODUTO.PVENDA4;
                DADOS_PRODUTO.PTABELA5 := DADOS_PRODUTO.PVENDA5;
                DADOS_PRODUTO.PTABELA6 := DADOS_PRODUTO.PVENDA6;
                DADOS_PRODUTO.PTABELA7 := DADOS_PRODUTO.PVENDA7;
              end if;
          end case; -- case TipoPrecificacao
        end if;
      end if;

      case DADOS_PLANO_PAGAMENTO.NumPR
        when 1 then
          DADOS_PRODUTO.PTABELA := DADOS_PRODUTO.PVENDA1;
        when 2 then
          DADOS_PRODUTO.PTABELA := DADOS_PRODUTO.PVENDA2;
        when 3 then
          DADOS_PRODUTO.PTABELA := DADOS_PRODUTO.PVENDA3;
        when 4 then
          DADOS_PRODUTO.PTABELA := DADOS_PRODUTO.PVENDA4;
        when 5 then
          DADOS_PRODUTO.PTABELA := DADOS_PRODUTO.PVENDA5;
        when 6 then
          DADOS_PRODUTO.PTABELA := DADOS_PRODUTO.PVENDA6;
        when 7 then
          DADOS_PRODUTO.PTABELA := DADOS_PRODUTO.PVENDA7;

      end case;

    end if; --pOferta?
  end DEFINIR_PRECO_TABELA;

  PROCEDURE CALCULAR_PRECO_TABELA(pCodFilial              IN varchar,
                                  pCodFilialNF            IN varchar,
                                  pCodFilialRetira        IN varchar,
                                  pQtde                   IN number,
                                  pDescPlanoCustomizado   IN number,
                                  pCodAuxiliar            IN number,
                                  pCondVenda              IN number,
                                  pVendaExportacao        IN varchar,
                                  pOrigemped              IN varchar,
                                  pUsarPVendaNoTV10       IN varchar,
                                  pItemBNFTV1             IN varchar,
                                  pTipoDocumento          IN varchar,
                                  pCodPrecoFixo           IN number,
                                  pAPLICASIMPLESPRECOFIXO IN VARCHAR2,
                                  pUsaDescontos           in boolean,
                                  pContrato               IN boolean,
                                  DADOS_CLIENTE           IN T_CLIENTE,
                                  DADOS_PRODUTO           IN OUT T_DADOS_PRODUTO,
                                  DADOS_RCA               IN T_RCAS,
                                  DADOS_PLANO_PAGAMENTO   IN T_PLANO_PAGAMENTO,
                                  Parametros132           IN T_PARAMETROS_132,
                                  pCodCombo               IN number,
                                  pCodCob                 IN varchar2,
                                  vsMsg                   out varchar2,
                                  pNumPedTV7              IN NUMBER default 0,
                                  pVendaTriangular        in varchar2 default 'N',
                                  pNumEmpenho             IN number default 0,
                                  pPrazoMedio             in number default 0,
                                  pCodEnderecoEntrega     in number default 0,
                                  pTransferencia          in varchar2 default 'N',
                                  pTransferenciaVirtual   in varchar2 default 'N')

   IS
    ----variáveis locais
    vnVLREDSIMPLESNAC       number;
    vnNOVOPRECOSIMPLESNAC   number;
    vnPERDESCCOM            number;
    vnPERBONIFIC            number;
    vnVLPERDESCCOM          number;
    vnVLPERBONIFIC          number;
    vsTIPOCUSTOTRANSF       varchar2(1);
    vsFlagPrecoFixo         varchar2(1);
    vnPtabelaCalculo        number;
    vsUtilizaCustoVendaTV10 varchar2(1);
    dadosCodFiscal          T_CODFISCAL;
    /* ICMS PARTILHA */
    tICMSPARTILHA         tipo_icms_partilha;
    vsMSGPartilha         varchar2(1000);
    vnCodMSGPartilha      number;
    DADOS_PRECO_FIXO      T_PRECO_FIXO;
    DADOS_ACRESCIMOS_PFSN T_ACRESCIMOS_PF_SN;
    erro_calculo_partilha exception;
  BEGIN
    vnPtabelaCalculo := DADOS_PRODUTO.PTABELA;
    --plano de pagamento customizado
    vnPtabelaCalculo := vnPtabelaCalculo * (1 + pDescPlanoCustomizado / 100);

    --plano de pagamento tradicional
    if Parametros132.UtilizaControleMedicamentos = 'S' then
      if DADOS_CLIENTE.OrigemPreco <> 'F' then

        vnPtabelaCalculo := vnPtabelaCalculo *
                            (1 + DADOS_PLANO_PAGAMENTO.PERTXFIM / 100);
      end if;
    else
      if (pCodPrecoFixo = 0) and (not pContrato) or
         (pCodPrecoFixo > 0 and Parametros132.UtilizaPercFinPrecoProm = 'S') then

        vnPtabelaCalculo := vnPtabelaCalculo *
                            (1 + DADOS_PLANO_PAGAMENTO.PERTXFIM / 100);
      end if;
    end if;

    ---------------------------------Ramo de atividade------------------------------------
    if Parametros132.UtilizaControleMedicamentos = 'S' and
       ((pCodPrecoFixo = 0) and (not pContrato)) then
      if DADOS_CLIENTE.OrigemPreco <> 'F' then
        vnPtabelaCalculo := vnPtabelaCalculo *
                            (1 + DADOS_CLIENTE.PerDescAtiv / 100);
      end if;
    else
      if (pCodPrecoFixo = 0) and (not pContrato) then
        vnPtabelaCalculo := vnPtabelaCalculo *
                            (1 + DADOS_CLIENTE.PerDescAtiv / 100);
      end if;
    end if;

    ---------------------------------TV7/TV8----------------------------------------------
    if (Parametros132.ValidarPrecoVendaTV8 = 'S') and (pCondVenda = 8) then
      vnPtabelaCalculo := buscarPrecoTV7(pNumPedTV7,
                                         DADOS_PRODUTO.CODPROD,
                                         DADOS_PRODUTO.vsMSG);
    end if;

    --------------------Descontos relativos à origem do pedido----------------------------

    if pOrigemPed = 'T' and ((pCodPrecoFixo = 0) and (not pContrato)) then
      vnPtabelaCalculo := vnPtabelaCalculo *
                          (1 + Parametros132.PercAcrescimoTelemarketing / 100);
    end if;

    if pOrigemped in ('B', 'R') and ((pCodPrecoFixo = 0) and (not pContrato)) then
      vnPtabelaCalculo := vnPtabelaCalculo *
                          (1 + Parametros132.PercAcrescimoBalcao / 100);
    end if;

    --------------------------------------------------------------------------------------

    ----------------------Aplicação e valores exlusivo a medicamentos--------------------

    if Parametros132.UtilizaControleMedicamentos = 'S' and
       not ((pCodPrecoFixo = 0) and (not pContrato)) then

      vnPERDESCCOM := 0;
      vnPERBONIFIC := 0;

      if DADOS_PRODUTO.TIPOMERC IN ('M', 'MA', 'L') then
        if DADOS_CLIENTE.OrigemPreco = 'F' then
          vnPtabelaCalculo := DADOS_PRODUTO.PTABELAFABRICA;

          if Parametros132.UsaDescPorLinhaProd = 'S' then
            RETORNAR_DADOS_PCPLPAGI(DADOS_PLANO_PAGAMENTO.CodPlPag,
                                    DADOS_PRODUTO.CODLINHAPROD,
                                    vnPERBONIFIC,
                                    vnPERDESCCOM);
          end if;

          if vnPERBONIFIC = 0 then
            vnPERBONIFIC := DADOS_PRODUTO.PERCBONIFICVENDA;
          end if;

          --desconto comercial
          vnVLPERDESCCOM   := vnPtabelaCalculo * (vnPERDESCCOM / 100);
          vnVLPERBONIFIC   := vnPtabelaCalculo * (vnPERBONIFIC / 100);
          vnPtabelaCalculo := vnPtabelaCalculo - vnVLPERDESCCOM;
          --desconto bonificacao
          vnPtabelaCalculo := vnPtabelaCalculo - vnVLPERBONIFIC;

        end if;

        if DADOS_CLIENTE.RegiaoZFM = 'S' then
          vnPtabelaCalculo := DADOS_PRODUTO.PTABELAFABRICAZFM;
        end if;

        if DADOS_CLIENTE.REPASSE = 'S' then
          vnPtabelaCalculo := (vnPtabelaCalculo + vnVLPERBONIFIC +
                              vnVLPERDESCCOM) *
                              (1 + DADOS_CLIENTE.Repasse / 100);
        end if;
      end if; --DADOS_PRODUTO.TIPOMERC IN ('M', 'MA', 'L')
    end if; --Parametros132.UtilizaControleMedicamentos = 'S'

    ---------------------------Preços para TV10-------------------------------------------

    if pCondVenda = 10 and pUsarPVendaNoTV10 = 'N' then

      if DADOS_CLIENTE.Tv10usacustoproduto = 'S' then
        vsTIPOCUSTOTRANSF := DADOS_PRODUTO.TIPOCUSTOTRANSF;
      else
        vsTIPOCUSTOTRANSF := DADOS_CLIENTE.TIPOCUSTOTRANSF;
      end if;

      vnPtabelaCalculo := BUSCAR_CUSTOS_ESTOQUE(DADOS_PRODUTO.CODPROD,
                                                pCodFilial,
                                                vsTIPOCUSTOTRANSF);

      if Parametros132.UsarTribTransfVenda10 = 'S' then
        vnPtabelaCalculo := vnPtabelaCalculo *
                            (1 - (DADOS_PRODUTO.PERDESCCUSTOTRANSF / 100));
      end if;

      if (Parametros132.UtilizaControleMedicamentos = 'N') or
         (Parametros132.UtilizaControleMedicamentos = 'S' and
         DADOS_CLIENTE.OrigemPreco = 'F') then
        vnPtabelaCalculo := vnPtabelaCalculo *
                            (1 + (DADOS_CLIENTE.PerAcrescTransf / 100));
      end if;

    end if;

    ---------------------------Preços para TV13-------------------------------------------

    if pCondvenda = 13 then
      vsTIPOCUSTOTRANSF := DADOS_CLIENTE.TIPOCUSTOMANIF;

      vnPtabelaCalculo := BUSCAR_CUSTOS_ESTOQUE(DADOS_PRODUTO.CODPROD,
                                                pCodFilial,
                                                vsTIPOCUSTOTRANSF);

    end if;

    --------------------------------------------------------------------------------------

    DADOS_PRODUTO.PTABELA_SEMDESCONTOS := DADOS_PRODUTO.PTABELA;

    vnPtabelaCalculo := Round(vnPtabelaCalculo,
                              Parametros132.NumCasasDecimais);

    ----------RETIRAR IMPOSTOS, CALCULAR ST e CALCULAR IPI(CalcularST_VLIPI_Item)--------------------------------

    if (pCodPrecoFixo > 0) then
      DADOS_PRECO_FIXO := BUSCAR_DADOS_PRECO_FIXO(pCodPrecoFixo);

      if (DADOS_PRECO_FIXO.ConsideraPrecoSemImposto = 'S') then
        vnPtabelaCalculo := DADOS_PRECO_FIXO.precoFixo;
      end if;

      if Parametros132.UtilizaVendaPorEmbalagem = 'S' then
        vnPtabelaCalculo := vnPtabelaCalculo * DADOS_PRODUTO.QTUNIT;
      end if;

    end if;

    if (not pContrato) then

      if pCondVenda = 10 and pUsarPVendaNoTV10 = 'N' and
         vsTIPOCUSTOTRANSF <> 'P' then
        vsUtilizaCustoVendaTV10 := 'N';
      else
        vsUtilizaCustoVendaTV10 := 'S';
      end if;

      if ((pCodPrecoFixo = 0) or
         ((pCodPrecoFixo > 0) and
         (DADOS_PRECO_FIXO.ConsideraPrecoSemImposto = 'N'))) then
        SELECT VALORSEMIMPOSTO
          INTO vnPtabelaCalculo
          FROM TABLE(PKG_TRIBUTACAO.CALCULAR_PVENDA_SEM_IMPOSTO(pCodFilial,
                                                                pCodFilialNF,
                                                                NVL(pCodFilialRetira,
                                                                    pCodFilial),
                                                                DADOS_CLIENTE.CodCli,
                                                                DADOS_PLANO_PAGAMENTO.CodPlPag,
                                                                DADOS_PRODUTO.CODPROD,
                                                                pCodAuxiliar,
                                                                pCondVenda,
                                                                pVendaExportacao,
                                                                1,
                                                                0,
                                                                vnPtabelaCalculo,
                                                                vsUtilizaCustoVendaTV10,
                                                                'S',
                                                                pItemBNFTV1));

      end if;

      vnPtabelaCalculo := Round(vnPtabelaCalculo,
                                Parametros132.NumCasasDecimais);

      -----------------------------SIMPLES NACIONAL-----------------------------------------

      if DADOS_CLIENTE.SimplesNacional = 'S' and
         (((pCodPrecoFixo = 0) and (not pContrato)) or
         (pCodPrecoFixo > 0 and pAPLICASIMPLESPRECOFIXO = 'S')) then
        if Parametros132.UsaDescSimplesNac = 'S' then
          vnVLREDSIMPLESNAC := vnPtabelaCalculo *
                               (DADOS_PRODUTO.PERCDESCSIMPLESNAC / 100);
        else
          select VALOR_REDUCAO_SIMPLES_NACIONAL, NOVO_PRECO_SIMPLES_NACIONAL
            into vnVLREDSIMPLESNAC, vnNOVOPRECOSIMPLESNAC
            from table(PKG_TRIBUTACAO.CALCULAR_RED_SIMPLES_NACIONAL(pCodFilial,
                                                                    pCodFilialNF,
                                                                    NVL(pCodFilialRetira,
                                                                        pCodFilial),
                                                                    DADOS_CLIENTE.CODCLI,
                                                                    DADOS_PLANO_PAGAMENTO.CodPlPag,
                                                                    DADOS_PRODUTO.CODPROD,
                                                                    pCodAuxiliar,
                                                                    pCondVenda,
                                                                    pVendaExportacao,
                                                                    vnPtabelaCalculo,
                                                                    vnPtabelaCalculo));
        end if;

        if vnNOVOPRECOSIMPLESNAC = 0 then
          vnPtabelaCalculo := vnPtabelaCalculo - vnVLREDSIMPLESNAC;
        else
          vnPtabelaCalculo := vnNOVOPRECOSIMPLESNAC;
        end if;
      end if;
      ----------------------------Redução ICMS, PIS, Cofins--------------------------------

      SELECT VALOR_DESCONTO_ICMS
        into DADOS_PRODUTO.VALOR_DESCONTO_ICMS
        FROM TABLE(PKG_TRIBUTACAO.CALCULAR_DESC_PIS_COFINS_ICMS(pCodFilial,
                                                                pCodFilialNf,
                                                                pCodFilialRetira,
                                                                DADOS_CLIENTE.CodCli,
                                                                DADOS_PRODUTO.CODPROD,
                                                                vnPtabelaCalculo,
                                                                pNumEmpenho,
                                                                pPrazoMedio,
                                                                pVendaTriangular));

      ----------------------------Definir codfiscal para partilha--------------------------

      if pCondvenda in (1, 4, 5, 9, 8, 14) then

        dadosCodFiscal := DEFINIRCODFISCAL(PCODFILIAL,
                                           PCODFILIALNF,
                                           PCONDVENDA,
                                           PCODCOB,
                                           DADOS_CLIENTE.CodCli,
                                           PVENDAEXPORTACAO,
                                           pVendaExportacao,
                                           PITEMBNFTV1,
                                           vnPtabelaCalculo,
                                           DADOS_PRODUTO);

        pkg_fwpc_fiscal.icmspartilha_calcular_1_4(nvl(pcodfilialnf,
                                                      pcodfilial),
                                                  DADOS_CLIENTE.CodCli,
                                                  '',
                                                  '',
                                                  trunc(sysdate),
                                                  vnPtabelaCalculo,
                                                  DADOS_PRODUTO.codst,
                                                  DADOS_PRODUTO.codprod,
                                                  dadosCodFiscal.codfiscal,
                                                  dadosCodFiscal.sittribut,
                                                  tICMSPARTILHA,
                                                  vnCodMSGPartilha,
                                                  vsMSGPartilha);

        if vnCodMSGPartilha in (0, 4, 5, 11) then
          vnPtabelaCalculo := vnPtabelaCalculo + tICMSPARTILHA.VLICMSPART;
        else
          raise erro_calculo_partilha;
        end if;

      else
        tICMSPARTILHA.VLICMSPART := 0;
      end if;

      --------------------------------------------------------------------------------------
      SELECT VALORIPI, PERCENTUAL_REDUCAO
        INTO DADOS_PRODUTO.VLIPI, DADOS_PRODUTO.PERCENTUAL_REDUCAO_IPI
        FROM TABLE(PKG_TRIBUTACAO.CALCULAR_IPI(pCodFilial,
                                               pCodFilialNF,
                                               NVL(pCodFilialRetira,
                                                   pCodFilial),
                                               DADOS_CLIENTE.CodCli,
                                               DADOS_PRODUTO.CODPROD,
                                               pCodAuxiliar,
                                               pCondvenda,
                                               pVendaExportacao,
                                               vnPtabelaCalculo,
                                               pVendaTriangular,
                                               pCodEnderecoEntrega,
                                               pTransferencia,
                                               pTransferenciaVirtual));

      DADOS_PRODUTO.VALORDIFALIQUOTAS := 0;
      if DADOS_PRODUTO.PERCDIFALIQUOTAS > 0 then
        DADOS_PRODUTO.VALORDIFALIQUOTAS := Round(vnPtabelaCalculo *
                                                 (DADOS_PRODUTO.PERCDIFALIQUOTAS / 100),
                                                 Parametros132.NumCasasDecimais);

      end if;

      SELECT BASEST, ST
        INTO DADOS_PRODUTO.BASEST, DADOS_PRODUTO.VLST
        FROM TABLE(PKG_TRIBUTACAO.CALCULAR_ST(pCodFilial,
                                              pCodFilialNF,
                                              NVL(pCodFilialRetira, pCodFilial),
                                              DADOS_CLIENTE.CodCli,
                                              DADOS_PLANO_PAGAMENTO.CodPlPag,
                                              DADOS_PRODUTO.CODPROD,
                                              pCodAuxiliar,
                                              pCondvenda,
                                              pVendaExportacao,
                                              vnPtabelaCalculo,
                                              0,
                                              pItemBNFTV1));

      if DADOS_PRODUTO.MOSTRARPVENDASEMST = 'S' then
        vnPtabelaCalculo := vnPtabelaCalculo + DADOS_PRODUTO.VLIPI;
      else
        vnPtabelaCalculo := vnPtabelaCalculo + DADOS_PRODUTO.VLIPI +
                            DADOS_PRODUTO.VLST;
      end if;

      vnPtabelaCalculo := vnPtabelaCalculo + DADOS_PRODUTO.VALORDIFALIQUOTAS;

    end if; --not vbPrecoFixo

    --------------------------------------------------------------------------------------

    ----------------------------Acréscimos de Pessoa Fìsica-------------------------------

    DADOS_ACRESCIMOS_PFSN := APLICA_ACRESCIMO_PF(DADOS_CLIENTE,
                                                 DADOS_PRODUTO.APLICAACRESCPJISENTA,
                                                 pTipoDocumento,
                                                 pCondVenda,
                                                 pCodFilial,
                                                 DADOS_PRODUTO.PERACRESCISMOSIMPNAC,
                                                 DADOS_PRODUTO.PERACRESCISMOPF);

    if DADOS_ACRESCIMOS_PFSN.aplicaAcrescimo then
      vnPtabelaCalculo             := APLICA_PERCENTUAL(vnPtabelaCalculo,
                                                        DADOS_ACRESCIMOS_PFSN.percAcrescimoPF);
      DADOS_PRODUTO.PBASERCA       := APLICA_PERCENTUAL(DADOS_PRODUTO.PBASERCA,
                                                        DADOS_ACRESCIMOS_PFSN.percAcrescimoPF);
      tICMSPARTILHA.VLBASEPARTDEST := APLICA_PERCENTUAL(tICMSPARTILHA.VLBASEPARTDEST,
                                                        DADOS_ACRESCIMOS_PFSN.percAcrescimoPF);
      tICMSPARTILHA.VLFCPPART      := APLICA_PERCENTUAL(tICMSPARTILHA.VLFCPPART,
                                                        DADOS_ACRESCIMOS_PFSN.percAcrescimoPF);
      tICMSPARTILHA.VLICMSPARTDEST := APLICA_PERCENTUAL(tICMSPARTILHA.VLICMSPARTDEST,
                                                        DADOS_ACRESCIMOS_PFSN.percAcrescimoPF);
      tICMSPARTILHA.VLICMSPART     := APLICA_PERCENTUAL(tICMSPARTILHA.VLICMSPART,
                                                        DADOS_ACRESCIMOS_PFSN.percAcrescimoPF);
      tICMSPARTILHA.VLICMSDIFALIQ  := APLICA_PERCENTUAL(tICMSPARTILHA.VLICMSDIFALIQ,
                                                        DADOS_ACRESCIMOS_PFSN.percAcrescimoPF);
      tICMSPARTILHA.VLICMSPARTREM  := APLICA_PERCENTUAL(tICMSPARTILHA.VLICMSPARTREM,
                                                        DADOS_ACRESCIMOS_PFSN.percAcrescimoPF);

    end if;

    vnPtabelaCalculo := Round(vnPtabelaCalculo,
                              Parametros132.NumCasasDecimais);

    ----------------------------------------------------------------------------------------
    DADOS_PRODUTO.PTABELA := vnPtabelaCalculo;
    ------------------------------Preço de tabela zerado?-----------------------------------

    if vnPtabelaCalculo <= 0 and DADOS_PRODUTO.TIPOMERC <> 'CB' then
      DADOS_PRODUTO.vsMSG := 'Tipo de precificação: ' ||
                             Parametros132.TipoPrecificacao || ' ';

      if pCondVenda = 10 then
        DADOS_PRODUTO.vsMSG := DADOS_PRODUTO.vsMSG || CHR(13) ||
                               'Tipo de custo: ' || vsTIPOCUSTOTRANSF;
      end if;

      if DADOS_PRODUTO.PERDESCFOB >= 100 then
        DADOS_PRODUTO.vsMSG := DADOS_PRODUTO.vsMSG ||
                               cMSG_ERR_SEM_PRECO_TABELA || CHR(13) ||
                               'Percentual de frete FOB (na rotina 201) maior ou igual a 100. Produto: ' ||
                               to_char(DADOS_PRODUTO.CODPROD);
      else
        DADOS_PRODUTO.vsMSG := DADOS_PRODUTO.vsMSG ||
                               cMSG_ERR_SEM_PRECO_TABELA || CHR(13) ||
                               'Produto: ' || to_char(DADOS_PRODUTO.CODPROD);
      end if;

      RETURN; --saia do método

    end if;

    --------------------------------------------------------------------------------------

    DADOS_PRODUTO.PTABELA_SEMDESCONTOS := DADOS_PRODUTO.PTABELA; --valor de tabela sem desconto automático

    --------------------------------------------------------------------------------------

    ----------------------------Calcular Descontos----------------------------------------

    if pCodPrecoFixo > 0 then
      vsFlagPrecoFixo := 'S';
    else
      vsFlagPrecoFixo := 'N';
    end if;

    begin
      select msg,
             codesconto,
             codescontobase,
             politicabasecredita,
             politicabasedebita,
             percdescbase,
             datafinal,
             percdesc,
             percdescaut,
             ptabeladesc,
             pvendadesc,
             pbaserca,
             questionauso,
             alteraptabela,
             forcarutilizacao,
             percdescmax,
             datainicio,
             qtini,
             qtfim,
             vlrminimo,
             vlrmaximo
        into DADOS_PRODUTO.vsMSG,
             DADOS_PRODUTO.CODESCONTO,
             DADOS_PRODUTO.CODESCONTOBASE,
             DADOS_PRODUTO.POLITICABASECREDITA,
             DADOS_PRODUTO.POLITICABASEDEBITA,
             DADOS_PRODUTO.PERCDESCBASE,
             DADOS_PRODUTO.DATAFINAL,
             DADOS_PRODUTO.PERCDESC,
             DADOS_PRODUTO.PERCDESCAUT,
             DADOS_PRODUTO.PTABELADESC,
             DADOS_PRODUTO.PVENDADESC,
             DADOS_PRODUTO.PBASERCA,
             DADOS_PRODUTO.QUESTIONAUSO,
             DADOS_PRODUTO.ALTERAPTABELA,
             DADOS_PRODUTO.FORCARUTILIZACAO,
             DADOS_PRODUTO.PERCDESCMAX,
             DADOS_PRODUTO.DATAINICIO,
             DADOS_PRODUTO.QTINI,
             DADOS_PRODUTO.QTFIM,
             DADOS_PRODUTO.VLRMINIMO_DESCONTO,
             DADOS_PRODUTO.VLRMAXIMO_DESCONTO
        from table(vendas.DESCONTO_ITEM_VENDA(DADOS_CLIENTE.CodCli,
                                              DADOS_PRODUTO.CODPROD,
                                              DADOS_PLANO_PAGAMENTO.CodPlPag,
                                              DADOS_RCA.CodUsur,
                                              0,
                                              DADOS_PRODUTO.PTABELA,
                                              DADOS_PRODUTO.PTABELA,
                                              pQtde,
                                              pOrigemped,
                                              '', --tipocarga
                                              pCodFilial,
                                              trunc(sysdate),
                                              'S', --somente trazer descontos automáticos
                                              vsFlagPrecoFixo,
                                              0, --pPVenda
                                              0, --pDescontoPautado
                                              pCodFilialNF));
    exception
      when others then
        DADOS_PRODUTO.vsMSG := 'ERRO AO BUSCAR DESCONTOS';
    end;

    --2550.137463.2014 e 1836.117282.2014
    if not pUsaDescontos or
       ((Parametros132.AceitaDescPrecoFixo = 'N' or
       DADOS_RCA.ValidarAcrescDescPrecoFixo = 'N') and pCodPrecoFixo > 0) or
       (pCodCombo <> 0) then
      DADOS_PRODUTO.PERCDESC     := 0;
      DADOS_PRODUTO.PERCDESCBASE := 0;
      DADOS_PRODUTO.PERCDESCAUT  := 0;
      DADOS_PRODUTO.PERCDESCMAX  := 0;
    end if;

    ----------Aplicação dos descontos automáticos que alteram preço de tabela-------------

    if DADOS_PRODUTO.ALTERAPTABELA = 'S' then
      DADOS_PRODUTO.PTABELA := DADOS_PRODUTO.PTABELA *
                               (1 - (DADOS_PRODUTO.PERCDESCAUT / 100));

      DADOS_PRODUTO.PTABELA_NUMPR1 := DADOS_PRODUTO.PTABELA_NUMPR1 *
                                      (1 - (DADOS_PRODUTO.PERCDESCAUT / 100));

    end if;
    /*alterar para ter só 1 punit*/
    DADOS_PRODUTO.PUNIT := DADOS_PRODUTO.PTABELA1 / (CASE
                             WHEN DADOS_PRODUTO.QTUNIT > 0 THEN
                              DADOS_PRODUTO.QTUNIT
                             ELSE
                              1
                           END);

  EXCEPTION

    when erro_calculo_partilha then
      vsMsg := DADOS_PRODUTO.vsMSG || ' Tributação: ' || DADOS_PRODUTO.CODST ||
               '. Código mensagem partilha: ' || vnCodMSGPartilha ||
               '. Mensagem: ' || vsMSGPartilha;
      raise;

  END CALCULAR_PRECO_TABELA;

    FUNCTION BUSCAR_PRECO_TABELA(codigoFilial            IN varchar,
                                 CodFilialNF          IN varchar,
                                 CodFilialRetira      IN varchar,
                                 Oferta               IN varchar,
                                 OfertaAtac           IN varchar,
                                 Qtde                 IN number,
                                 Codprod              IN number,
                                 NumRegiao            IN number,
                                 CodUsur              IN number,
                                 AbateFrete           IN varchar,
                                 PerFrete             IN number,
                                 Codcli               IN number,
                                 CodContrato          IN number,
                                 CodPlPag             IN number,
                                 CodCob               IN varchar2,
                                 DescPlanoCustomizado IN number,
                                 CodAuxiliar          IN number,
                                 CondVenda            IN number,
                                 VendaExportacao      IN varchar,
                                 Origemped            IN varchar,
                                 ItemBNFTV1           IN varchar,
                                 TipoDocumento        IN varchar,
                                 CodCombo             IN number,
                                 NumPedTV7            IN number default 0,
                                 VendaTriangular      in varchar2 default 'N',
                                 NumEmpenho           IN number default 0,
                                 PrazoMedio           in number default 0,
                                 CodEnderecoEntrega   in number default 0,
                                 Transferencia        in varchar2 default 'N',
                                 TransferenciaVirtual in varchar2 default 'N')
    RETURN varchar2

   IS

    ----types
    dadosPreco            pljson;
    DADOS_PRODUTO         T_DADOS_PRODUTO;
    DADOS_PRODUTO_CESTA   T_DADOS_PRODUTO;
    DADOS_CLIENTE         T_CLIENTE;
    DADOS_RCA             T_RCAS;
    DADOS_PLANO_PAGAMENTO T_PLANO_PAGAMENTO;
    Parametros132         T_PARAMETROS_132;

    vnQtde                   number;
    vbUsaDescontos           boolean;
    vbPrecoFixo              boolean;
    vbContrato               boolean;
    vnCodPrecoFixo           number;
    vnNumDias                number;
    vsmsg                    varchar2(4000);
    vnPRECOFIXO              number;
    vsAPLICASIMPLESPRECOFIXO varchar2(1);
    viCount                  integer;
    viCodPrecoCesta          integer;
    viCodST                  integer;
    vnValorTabelaCesta       number;
    vnPrecoFixoCesta         number;
    vsUsarPVendaNoTV10       varchar2(1);
    vsMsgCalculo             varchar2(4000);
    ----exceptions
    erro_dados_preco_fixo exception;
    erro_desconto         exception;

  BEGIN

    --------------------------Parâmetros da 132-------------------------------------------

    Parametros132.UtilizaVendaPorEmbalagem := 'N';
    IF ((F_BUSCARPARAMETRO_ALFA('CON_UTILIZAVENDAPOREMBALAGEM', '99', 'N') = 'S') OR
       (F_BUSCARPARAMETRO_ALFA('FIL_UTILIZAVENDAPOREMBALAGEM',
                                codigoFilial,
                                'N') = 'S')) THEN

      Parametros132.UtilizaVendaPorEmbalagem := 'S';
    END IF;

    Parametros132.PrecoPorEmbalagem := 'N';
    if ((F_BUSCARPARAMETRO_ALFA('CON_PRECOPOREMBALAGEM', '99', 'N') = 'S') OR
       (F_BUSCARPARAMETRO_ALFA('FIL_PRECOPOREMBALAGEM', codigoFilial, 'N') = 'S')) THEN
      Parametros132.PrecoPorEmbalagem := 'S';
    END IF;

    Parametros132.TipoPrecificacao := F_BUSCARPARAMETRO_ALFA('FIL_TIPOPRECIFICACAO',
                                                             codigoFilial,
                                                             'P');

    Parametros132.UtilizaControleMedicamentos := F_BUSCARPARAMETRO_ALFA('UTILIZACONTROLEMEDICAMENTOS',
                                                                        codigoFilial,
                                                                        'N');

    Parametros132.UsaDescSimplesNac := F_BUSCARPARAMETRO_ALFA('USADESCSIMPLESNAC',
                                                              codigoFilial,
                                                              'N');

    Parametros132.PercAcrescimoBalcao := F_BUSCARPARAMETRO_NUM('CON_PERCACRESCIMOBALCAO',
                                                               '99',
                                                               0);

    Parametros132.PercAcrescimoTelemarketing := F_BUSCARPARAMETRO_NUM('PERCACRESCIMOTELEMARKETING',
                                                                      codigoFilial,
                                                                      0);

    Parametros132.UsaDescPorLinhaProd := F_BUSCARPARAMETRO_ALFA('CON_USADESCPORLINHAPROD',
                                                                '99',
                                                                'N');

    Parametros132.ValidaPvendaBonific     := F_BUSCARPARAMETRO_ALFA('CON_VALIDAPVENDABONIFIC',
                                                                    '99',
                                                                    'N');
    Parametros132.UtilizaPercFinPrecoProm := F_BUSCARPARAMETRO_ALFA('CON_UTILIZAPERCFINPRECOPROM',
                                                                    '99',
                                                                    'N');

    Parametros132.ValidarPrecoVendaTV20 := F_BUSCARPARAMETRO_ALFA('FIL_VALIDARPRECOVENDATV20',
                                                                  codigoFilial,
                                                                  'N');

    Parametros132.UsarTribTransfVenda10 := F_BUSCARPARAMETRO_ALFA('USARTRIBTRANSFVENDA10',
                                                                  codigoFilial,
                                                                  'N');

    Parametros132.NumCasasDecimais := F_BUSCARPARAMETRO_NUM('CON_NUMCASASDECVENDA',
                                                            '99',
                                                            0);

    Parametros132.RetiraIpiPedidoTV8 := F_BUSCARPARAMETRO_ALFA('RETIRAIPIPEDIDOTV8',
                                                               '99',
                                                               'N');

    Parametros132.AceitaDescPrecoFixo := F_BUSCARPARAMETRO_ALFA('CON_ACEITADESCPRECOFIXO',
                                                                '99',
                                                                'N');

    Parametros132.AceitaDescPrecoFixo  := F_BUSCARPARAMETRO_ALFA('FIL_VALIDARPRECOVENDATV8',
                                                                 codigoFilial,
                                                                 'N');
    Parametros132.AcrescePartilhaPreco := F_BUSCARPARAMETRO_ALFA('ACRESCICMSPARTILHAPRECO',
                                                                 codigoFilial,
                                                                 'N');
    begin
      select nvl(pcfilial.usapvendatransf, 'N')
        into vsUsarPVendaNoTV10
        from pcfilial
       where codigo = codigoFilial;
     exception
      when no_data_found then
        vsUsarPVendaNoTV10 := 'N';
     end;


    --------------------------------------------------------------------------------------

    ----------------------Variáveis de Controle ------------------------------------------

    vbUsaDescontos := true;
    vbContrato     := false;

    if DADOS_CLIENTE.OrigemPreco = 'F' and
       Parametros132.UtilizaControleMedicamentos = 'S' then
      vbUsaDescontos := false;
    end if;

    --------------------------------------------------------------------------------------

    -------------------Buscar dados do produto--------------------------------------------

    DADOS_PRODUTO := BUSCAR_DADOS_PRODUTO(Codprod,
                                          codigoFilial,
                                          NumRegiao,
                                          CodUsur,
                                          AbateFrete,
                                          PerFrete,
                                          Codcli,
                                          CodContrato,
                                          OrigemPed,
                                          CodAuxiliar,
                                          VendaTriangular,
                                          CodEnderecoEntrega,
                                          CondVenda);

    -------------------BUSCAR DADOS DO CLIENTE--------------------------------------------

    DADOS_CLIENTE := BUSCAR_CLIENTE(Codcli,
                                    CodFilialNF,
                                    CodEnderecoEntrega,
                                    codigoFilial);

    -------------------BUSCAR DADOS DO RCA------------------------------------------------

    DADOS_RCA := BUSCAR_RCA(CodUsur);

    -------------------BUSCAR DADOS DO PLANO DE PAGAMENTO---------------------------------

    DADOS_PLANO_PAGAMENTO := BUSCAR_PLANO_PAGTO(CodPlPag);

    -----------------------------DEFINIÇÃO DO PREÇO DE TABELA-----------------------------

    viCodST := RETORNA_CODIGO_TRIBUTACAO(DADOS_CLIENTE,
                                         DADOS_PRODUTO.codprod,
                                         codigoFilial,
                                         0,
                                         VendaTriangular,
                                         CondVenda,
                                         CodEnderecoEntrega);

    vnQtde := Qtde;

    if vnQtde = 0 then
      vnQtde := 1;

      if DADOS_CLIENTE.VALIDARMULTIPLOVENDA = 'S' or
         (Condvenda in (5, 11) and
         DADOS_PRODUTO.CHECARMULTIPLOVENDABNF = 'S') then
        vnQtde := DADOS_PRODUTO.MULTIPLO;

      end if;

    end if;

    --validação de preço fixo

    /*
    Autor       : Rafael Braga
    Solicitação : Criação
    Data        : 04/03/2015
    Descrição   : Vamos validar o preço fixo primeiro; caso não tenha preço fixo
                  validaremos o restante. Isso é feito para não ter que refazer
                  todos os cálculos novamente (simples nacional e outros).
    */

    vbPrecoFixo := funcoesvendas.validarpoliticaprecofixo(codprod,
                                                          trunc(sysdate),
                                                          dados_cliente.numregiao,
                                                          codcli,
                                                          condvenda,
                                                          codplpag,
                                                          DADOS_PRODUTO.ptabela,
                                                          parametros132.validapvendabonific,
                                                          parametros132.utilizapercfinprecoprom,
                                                          0, --desconto do plano de pagamento é aplicado abaixo
                                                          vnnumdias,
                                                          dados_cliente.codcliprinc,
                                                          dados_produto.codprodprinc,
                                                          dados_cliente.codpraca,
                                                          DADOS_RCA.CodUsur,
                                                          DADOS_RCA.CodSupervisor,
                                                          null, --numlote
                                                          origemped,
                                                          dados_cliente.codativ1,
                                                          DADOS_PRODUTO.datafimprecofixo,
                                                          vsMSG,
                                                          vnprecofixo,
                                                          codigoFilial,
                                                          parametros132.validarprecovendatv20,
                                                          case
                                                            when OrigemPed = 'K' then
                                                             'S'
                                                            else
                                                             'N'
                                                          end,
                                                          parametros132.utilizavendaporembalagem,
                                                          parametros132.precoporembalagem,
                                                          DADOS_PRODUTO.codauxiliar);

    if vbPrecoFixo then
      DADOS_PRODUTO.PTABELA         := vnprecofixo;
      vnCodPrecoFixo                := to_number(vsMSG);
      DADOS_PRODUTO.CODIGOPRECOFIXO := vnCodPrecoFixo;

    end if;

    --fim validações preço fixo

    if CodContrato <> 0 then
      vbContrato := OBTER_PRECO_CONTRATO(Codprod,
                                         CodContrato,
                                         DADOS_PRODUTO);
    end if;

    if (not vbPrecoFixo) and (not vbContrato) then
      DEFINIR_PRECO_TABELA(Oferta,
                           OfertaAtac,
                           vnQtde,
                           DADOS_PLANO_PAGAMENTO,
                           DADOS_PRODUTO,
                           Parametros132);

    end if;

    if DADOS_PRODUTO.TIPOMERC <> 'CB' then
      CALCULAR_PRECO_TABELA(codigoFilial,
                            CodFilialNF,
                            CodFilialRetira,
                            Qtde,
                            DescPlanoCustomizado,
                            CodAuxiliar,
                            CondVenda,
                            VendaExportacao,
                            Origemped,
                            vsUsarPVendaNoTV10,
                            ItemBNFTV1,
                            TipoDocumento,
                            nvl(vnCodPrecoFixo, 0),
                            vsAPLICASIMPLESPRECOFIXO,
                            vbUsaDescontos,
                            vbContrato,
                            DADOS_CLIENTE,
                            DADOS_PRODUTO,
                            DADOS_RCA,
                            DADOS_PLANO_PAGAMENTO,
                            Parametros132,
                            CodCombo,
                            CodCob,
                            vsMsgCalculo,
                            NumPedTV7,
                            VendaTriangular,
                            NumEmpenho,
                            PrazoMedio,
                            CodEnderecoEntrega,
                            Transferencia,
                            TransferenciaVirtual);
    END IF;

    --------------------------------------------------------------------------------------
    -------------------CALCULAR PREÇO PARA CESTA-----------------------------------------
    if DADOS_PRODUTO.TIPOMERC = 'CB' then

      viCount            := 0;
      viCodPrecoCesta    := 0;
      viCodST            := 0;
      vnValorTabelaCesta := 0;
      vnPrecoFixoCesta   := 0;
      ---------------------------------Validar cadastro de embalagem------------------------
      for reg in (select codprodmp, codauxiliarmp
                    from pcformprod
                   where codprodacab = DADOS_PRODUTO.CODPROD) loop

        if Parametros132.UtilizaVendaPorEmbalagem = 'S' then
          select count(1)
            into viCount
            from pcformprod, pcembalagem
           where pcformprod.codprodmp = reg.codprodmp
             and pcformprod.codauxiliarmp = pcembalagem.codauxiliar
             and pcembalagem.codfilial = codigoFilial;
        else
          select count(1)
            into viCount
            from pcprodut, pcembalagem
           where pcprodut.codauxiliar = pcembalagem.codauxiliar
             and pcprodut.codprod = pcembalagem.codprod
             and pcprodut.codprod = reg.codprodmp
             and pcembalagem.codfilial = codigoFilial;
        end if;

        if viCount = 0 then
          vsMSG := 'PRODUTO ' || to_char(reg.codprodmp) ||
                   ' SEM EMBALAGEM CADASTRADA NA FILIAL ' || codigoFilial;
        end if;

      end loop;
      --------------------------------------------------------------------------------------

      ---------------------------Buscar preço fixo da cesta---------------------------------

      begin
        SELECT codprecocesta
          INTO viCodPrecoCesta
          FROM pcprecocestac
         WHERE pcprecocestac.codprodacab = DADOS_PRODUTO.CODPROD
           AND dtexclusao IS NULL
           AND TRUNC(SYSDATE) BETWEEN NVL(dtinicio, TRUNC(SYSDATE)) AND
               NVL(pcprecocestac.dtfim, TRUNC(SYSDATE))
           AND NVL(codfilial, '99') IN (codigoFilial, '99')
           AND numregiao = DADOS_CLIENTE.NUMREGIAO
           AND NVL(codplpag, DADOS_PLANO_PAGAMENTO.CodPlPag) =
               DADOS_PLANO_PAGAMENTO.CodPlPag
           AND DECODE(NVL(codcli, 0),
                      0,
                      DADOS_CLIENTE.CODCLI,
                      DECODE(NVL(utilizaprecofixorede, 'N'),
                             'N',
                             DADOS_CLIENTE.CODCLI,
                             DADOS_CLIENTE.CODCLIPRINC)) =
               NVL(pcprecocestac.codcli, DADOS_CLIENTE.CODCLI);
      exception
        when others then
          viCodPrecoCesta := 0;
      end;

      --------------------------------------------------------------------------------------

      ------------------------Buscando tributação dos itens cesta---------------------------

      for reg in (SELECT pcformprod.codprodmp,
                         pcformprod.qtprodmp,
                         pcformprod.codauxiliarmp
                    FROM pcformprod
                   WHERE pcformprod.codprodacab = DADOS_PRODUTO.CODPROD) loop

        viCodST := RETORNA_CODIGO_TRIBUTACAO(DADOS_CLIENTE,
                                             reg.codprodmp,
                                             codigoFilial,
                                             0,
                                             VendaTriangular,
                                             CondVenda,
                                             CodEnderecoEntrega);

        DADOS_PRODUTO_CESTA := BUSCAR_DADOS_PRODUTO(reg.codprodmp,
                                                    codigoFilial,
                                                    DADOS_CLIENTE.NumRegiao,
                                                    DADOS_RCA.CodUsur,
                                                    AbateFrete,
                                                    PerFrete,
                                                    DADOS_CLIENTE.CodCli,
                                                    CodContrato,
                                                    OrigemPed,
                                                    reg.codauxiliarmp,
                                                    VendaTriangular,
                                                    CodEnderecoEntrega,
                                                    CondVenda);

        ----------------------------Validar preço fixo dos itens cesta-----------------------

        if viCodPrecoCesta > 0 then
          begin
            SELECT ROUND(pcprecocestai.precofixo,
                         Parametros132.NumCasasDecimais) precofixo
              INTO vnPrecoFixoCesta
              FROM pcprecocestai
             WHERE codprecocesta = viCodPrecoCesta
               AND codprodacab = DADOS_PRODUTO.CODPROD
               AND codprodmp = reg.codprodmp;
          exception
            when others then
              vnPrecoFixoCesta := 0;
          end;

          DADOS_PRODUTO.PTABELA := vnPrecoFixoCesta;

          CALCULAR_PRECO_TABELA(codigoFilial,
                                CodFilialNF,
                                CodFilialRetira,
                                Qtde,
                                DescPlanoCustomizado,
                                CodAuxiliar,
                                CondVenda,
                                VendaExportacao,
                                Origemped,
                                vsUsarPVendaNoTV10,
                                ItemBNFTV1,
                                TipoDocumento,
                                nvl(vnCodPrecoFixo, 0),
                                vsAPLICASIMPLESPRECOFIXO,
                                vbUsaDescontos,
                                vbContrato,
                                DADOS_CLIENTE,
                                DADOS_PRODUTO_CESTA,
                                DADOS_RCA,
                                DADOS_PLANO_PAGAMENTO,
                                Parametros132,
                                CodCombo,
                                CodCob,
                                vsMsgCalculo,
                                NumPedTV7,
                                VendaTriangular,
                                NumEmpenho,
                                PrazoMedio,
                                CodEnderecoEntrega,
                                Transferencia,
                                TransferenciaVirtual);

          vnValorTabelaCesta := vnValorTabelaCesta +
                                (vnPrecoFixoCesta * reg.qtprodmp);

          --------------------------------------------------------------------------------------
        else
          DEFINIR_PRECO_TABELA(Oferta,
                               OfertaAtac,
                               vnQtde,
                               DADOS_PLANO_PAGAMENTO,
                               DADOS_PRODUTO_CESTA,
                               Parametros132);

          CALCULAR_PRECO_TABELA(codigoFilial,
                                CodFilialNF,
                                CodFilialRetira,
                                Qtde,
                                DescPlanoCustomizado,
                                CodAuxiliar,
                                CondVenda,
                                VendaExportacao,
                                Origemped,
                                vsUsarPVendaNoTV10,
                                ItemBNFTV1,
                                TipoDocumento,
                                nvl(vnCodPrecoFixo, 0),
                                vsAPLICASIMPLESPRECOFIXO,
                                vbUsaDescontos,
                                vbContrato,
                                DADOS_CLIENTE,
                                DADOS_PRODUTO_CESTA,
                                DADOS_RCA,
                                DADOS_PLANO_PAGAMENTO,
                                Parametros132,
                                CodCombo,
                                CodCob,
                                vsMsgCalculo,
                                NumPedTV7,
                                VendaTriangular,
                                NumEmpenho,
                                PrazoMedio,
                                CodEnderecoEntrega,
                                Transferencia,
                                TransferenciaVirtual);

          vnValorTabelaCesta := vnValorTabelaCesta +
                                (DADOS_PRODUTO_CESTA.PTABELA * reg.qtprodmp);
        end if;

      end loop; --percorrendo produtos que compõe a cesta

      if (Parametros132.UtilizaVendaPorEmbalagem = 'S') and
         (DADOS_PRODUTO.QTUNIT > 0) then
        vnValorTabelaCesta := vnValorTabelaCesta * DADOS_PRODUTO.QTUNIT;
      end if;

      DADOS_PRODUTO.PTABELA := vnValorTabelaCesta;

      -----------------------------------------------------------------------------------

    end if;

    --------------------------------------------------------------------------------------
    dadosPreco := pljson();
    dadosPreco.put('precoTabela', DADOS_PRODUTO.PTABELA);
    dadosPreco.put('substituicaoTributaria', DADOS_PRODUTO.VLST);
    dadosPreco.put('ipi', DADOS_PRODUTO.VLIPI);
    dadosPreco.put('percentualReducaoIpi', DADOS_PRODUTO.PERCENTUAL_REDUCAO_IPI);
    dadosPreco.put('codigoFiguraTributaria', DADOS_PRODUTO.CODST);
    dadosPreco.put('precoSemDescontos', DADOS_PRODUTO.PTABELA_SEMDESCONTOS);
    dadosPreco.put('precoBaseRca', DADOS_PRODUTO.PBASERCA);
    dadosPreco.put('codigoDesconto', DADOS_PRODUTO.CODESCONTO);
    dadosPreco.put('codigoDescontoPrecoRca', DADOS_PRODUTO.CODESCONTOBASE);
    dadosPreco.put('percentualDescontoFlexivel', DADOS_PRODUTO.PERCDESC);
    dadosPreco.put('percentualDescontoAutomatico', DADOS_PRODUTO.PERCDESCAUT);
    dadosPreco.put('percentualDescontoMaximo', DADOS_PRODUTO.PERCDESCMAX);
    dadosPreco.put('percentualAcrescimoPessoaFisica', DADOS_PRODUTO.PERACRESCISMOPF);
    dadosPreco.put('codigoPrecoFixo', DADOS_PRODUTO.CODIGOPRECOFIXO);
    dadosPreco.put('usaPrecoOferta', DADOS_PRODUTO.USANDOPOFERTA);
    dadosPreco.put('mensagemRetorno', DADOS_PRODUTO.vsMSG);

    RETURN dadosPreco.to_char();

  EXCEPTION

    when erro_dados_preco_fixo then
      DADOS_PRODUTO.vsMSG := DADOS_PRODUTO.vsMSG || 'ERRO AO BUSCAR DADOS ADICIONAIS DE PREÇO FIXO';
      return gerarRetorno(DADOS_PRODUTO.vsMSG);

    when erro_desconto then
      DADOS_PRODUTO.vsMSG := DADOS_PRODUTO.vsMSG || ' ' || 'ERRO AO CALCULAR DESCONTO';
      return gerarRetorno(DADOS_PRODUTO.vsMSG);

    when others then
      DADOS_PRODUTO.vsMSG := DADOS_PRODUTO.vsMSG || ' ' || 'Erro ao calcular preço de tabela: ' ||
                             DADOS_PRODUTO.vsMSG || ' ' ||
                             DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
      return gerarRetorno(DADOS_PRODUTO.vsMSG);

  END BUSCAR_PRECO_TABELA;

  PROCEDURE APLICAR_VERBACAMPANHA(pNUMPED       IN PCPEDI.NUMPED%TYPE,
                                  pCODPROD      IN PCPEDI.CODPROD%TYPE,
                                  pNUMSEQ       IN PCPEDI.NUMSEQ%TYPE,
                                  pCODFILIAL IN PCPEDC.CODFILIAL%TYPE DEFAULT NULL) IS
    TYPE T_REGDESC IS RECORD(
    codigo    NUMBER(8),
    numverba  NUMBER(8),
    perdesc   NUMBER(12,4),
    perccustfornec NUMBER(12,4),
    vlcustfornec NUMBER(18,6)
    );

    vt301       T_REGDESC;
    vt357       T_REGDESC;
    vt561       T_REGDESC;
    vt3306      T_REGDESC;
    vt3307      T_REGDESC;
    vt3320      T_REGDESC;
    vt561_AUTO  T_REGDESC;
    vt3306_AUTO T_REGDESC;
    vt3306_SQP  T_REGDESC;
  
    vnNUMVERBACAMPANHA NUMBER(8);
    vnPERCCUSTFORNEC   NUMBER(12, 4);
    vnPTABELA          PCPEDI.PTABELA%TYPE;
  
    reg_pcpedc       PCPEDC%ROWTYPE;
    reg_pcpedi       PCPEDI%ROWTYPE;
    reg_pcpedi_bnf   PCPEDI%ROWTYPE;
    vbEXISTEREGISTRO BOOLEAN;
    V_CODPROD        PCPEDI.CODPROD%TYPE;
    V_TIPOVALOR      PCDESCONTOCATEGORIA.TIPOVALOR%TYPE;
    V_TIPO           PCDESCONTOCATEGORIA.TIPO%TYPE;
    VNPERDESC        NUMBER;
    VLDESCAPLIC      NUMBER;
  
    FUNCTION APLICAVEL(vNUMVERBA IN NUMBER,
                       vCODPROD IN PCPEDI.CODPROD%TYPE) RETURN BOOLEAN IS
      vReturn         BOOLEAN;
      vExisteRegistro integer;
    BEGIN
      vReturn := false;
    
      SELECT count(1)
        INTO vExisteRegistro
        FROM PCPRODUT, PCVERBA
       WHERE PCPRODUT.CODFORNEC = PCVERBA.CODFORNEC
         AND PCPRODUT.CODPROD = vCODPROD
         AND PCVERBA.NUMVERBA = vNUMVERBA
         AND PCVERBA.DTAPURACAO IS NULL;
    
      IF (vExisteRegistro > 0) THEN
        vReturn := true;
      END IF;
    
      RETURN vReturn;
    
    END APLICAVEL;
  
    FUNCTION PRODUTO_SQP(VNTIPOVALOR IN NUMBER,
                         VSTIPO      IN PCDESCONTOCATEGORIA.TIPO%TYPE,
                         VNNUMPED    IN PCPEDI.NUMPED%TYPE,
                         VNCODIGO    IN PCPEDI.CODCOMBO%TYPE,
                         VSCODFILIAL IN PCPEDC.CODFILIAL%TYPE DEFAULT NULL)
      RETURN NUMBER IS
      vReturn     NUMBER;
      VNCODPROD   NUMBER;
      P_CODFILIAL PCPEDC.CODFILIAL%TYPE;
    
    BEGIN
      vReturn := 0;
    
      BEGIN
        SELECT NVL(VSCODFILIAL, CODFILIALVENDA)
          INTO P_CODFILIAL
          FROM (SELECT NVL(CODFILIALNF, CODFILIAL) CODFILIALVENDA
                  FROM PCPEDC
                 WHERE NUMPED = VNNUMPED);
      EXCEPTION
        WHEN OTHERS THEN
          P_CODFILIAL := VSCODFILIAL;
      END;
    
      BEGIN
        SELECT CODPROD
          INTO VNCODPROD
          FROM (SELECT I.CODPROD
                  FROM PCPEDI I
                 WHERE I.CODPROD = VNTIPOVALOR
                   AND 'P - Produto' = VSTIPO
                   AND I.CODCOMBO = VNCODIGO
                   AND I.NUMPED = VNNUMPED
                UNION ALL
                SELECT I.CODPROD
                  FROM PCPEDI I
                 INNER JOIN PCPRODUT P
                    ON P.CODPROD = I.CODPROD
                 WHERE P.Codfornec = VNTIPOVALOR
                   AND 'F - Fornecedor' = VSTIPO
                   AND I.CODCOMBO = VNCODIGO
                   AND I.NUMPED = VNNUMPED
                UNION ALL
                SELECT I.CODPROD
                  FROM PCPEDI I
                 INNER JOIN PCPRODUT P
                    ON P.CODPROD = I.CODPROD
                 WHERE P.CODEPTO = VNTIPOVALOR
                   AND 'D - Departamento' = VSTIPO
                   AND I.CODCOMBO = VNCODIGO
                   AND I.NUMPED = VNNUMPED
                UNION ALL
                SELECT I.CODPROD
                  FROM PCPEDI I
                 INNER JOIN PCPRODUT P
                    ON P.CODPROD = I.CODPROD
                 WHERE P.CODSEC = VNTIPOVALOR
                   AND 'S - Seção' = VSTIPO
                   AND I.CODCOMBO = VNCODIGO
                   AND I.NUMPED = VNNUMPED
                UNION ALL
                SELECT I.CODPROD
                  FROM PCPEDI I
                 INNER JOIN PCPRODUT P
                    ON P.CODPROD = I.CODPROD
                 WHERE P.CODCATEGORIA = VNTIPOVALOR
                   AND 'C - Categoria' = VSTIPO
                   AND I.CODCOMBO = VNCODIGO
                   AND I.NUMPED = VNNUMPED
                UNION ALL
                SELECT I.CODPROD
                  FROM PCPEDI I
                 INNER JOIN PCPRODUT P
                    ON P.CODPROD = I.CODPROD
                 WHERE P.CODSUBCATEGORIA = VNTIPOVALOR
                   AND 'SC - Sub-Categoria' = VSTIPO
                   AND I.CODCOMBO = VNCODIGO
                   AND I.NUMPED = VNNUMPED
                UNION ALL
                SELECT I.CODPROD
                  FROM PCPEDI I
                 INNER JOIN PCPRODUT P
                    ON P.CODPROD = I.CODPROD
                 WHERE P.CODLINHAPROD = VNTIPOVALOR
                   AND 'LP - Linha de Produtos' = VSTIPO
                   AND I.CODCOMBO = VNCODIGO
                   AND I.NUMPED = VNNUMPED
                UNION ALL
                SELECT I.CODPROD
                  FROM PCPEDI I
                 INNER JOIN PCPRODUT P
                    ON P.CODPROD = I.CODPROD
                 WHERE 'GP - Grupo de Produtos' = VSTIPO
                   AND I.CODCOMBO = VNCODIGO
                   AND I.NUMPED = VNNUMPED
                   AND EXISTS
                 (SELECT 1
                          FROM PCGRUPOSCAMPANHAC GC, PCGRUPOSCAMPANHAI GI
                         WHERE GC.CODGRUPO = GI.CODGRUPO
                           AND GC.TIPO = 'GP'
                           AND GI.CODITEM = P.CODPROD
                           AND GI.DTEXCLUSAO IS NULL
                           AND GC.CODFILIAL =
                               NVL(P_CODFILIAL, I.CODFILIALRETIRA)));
      EXCEPTION
        WHEN OTHERS THEN
          VNCODPROD := 0;
      END;
    
      IF (VNCODPROD > 0) THEN
        vReturn := VNCODPROD;
      END IF;
    
      RETURN vReturn;
    
    END PRODUTO_SQP;
  
  BEGIN

    BEGIN
      SELECT *
        INTO reg_pcpedi
        FROM PCPEDI
       WHERE numped = pNUMPED
         AND codprod = pCODPROD
         AND numseq = pNUMSEQ;

      SELECT *
        INTO reg_pcpedc
        FROM PCPEDC
       WHERE numped = reg_pcpedi.NUMPED;

      vbEXISTEREGISTRO := TRUE;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
         vbEXISTEREGISTRO := FALSE;
    END;
  
    IF (vbEXISTEREGISTRO) THEN
    
      BEGIN
        --301
        SELECT NRAUTORIZACAO,
               NUMVERBA,
               NVL(PERCCUSTFORNEC, 0),
               NVL(PERCDESCAUTOR, 0)
          INTO vt301.codigo,
               vt301.numverba,
               vt301.perccustfornec,
               vt301.perdesc
          FROM pcautori
         WHERE numped = reg_pcpedi.numped
           AND nvl(statusutiliz, 'N') = 'S'
           AND codprod = reg_pcpedi.codprod
           AND numverba > 0
		   AND ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vt301.codigo         := NULL;
          vt301.numverba       := NULL;
          vt301.perccustfornec := 0;
          vt301.perdesc        := 0;
      END;
    
      BEGIN
        SELECT PCDESCONTO.CODDESCONTO,
               PCDESCONTO.NUMVERBA,
               nvl(PCDESCONTO.PERCCUSTFORNEC, 0),
               NVL(PCDESCONTO.PERCDESC, 0)
          INTO vt561_AUTO.codigo,
               vt561_AUTO.numverba,
               vt561_AUTO.perccustfornec,
               vt561_AUTO.perdesc
          FROM PCDESCONTO, PCORIGEMPRECO
         WHERE PCDESCONTO.CODDESCONTO = PCORIGEMPRECO.CODDESCPTABELA
           AND PCORIGEMPRECO.NUMPED = pNUMPED
           AND PCORIGEMPRECO.CODPROD = pCODPROD
           AND PCORIGEMPRECO.NUMSEQ = pNUMSEQ
           AND PCORIGEMPRECO.PERCDESCPTABELA > 0
           AND NVL(PCDESCONTO.numverba, 0) > 0
           AND NVL(PCDESCONTO.ALTERAPTABELA, 'N') = 'S'
		   AND ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vt561_AUTO.codigo         := NULL;
          vt561_AUTO.numverba       := NULL;
          vt561_AUTO.perccustfornec := 0;
          vt561_AUTO.perdesc        := 0;
      END;
    
      IF (nvl(reg_pcpedi.coddesconto, 0) <> 0) THEN
        --561
        BEGIN
          SELECT CODDESCONTO,
                 NUMVERBA,
                 nvl(PERCCUSTFORNEC, 0),
                 NVL(PERCDESC, 0)
            INTO vt561.codigo,
                 vt561.numverba,
                 vt561.perccustfornec,
                 vt561.perdesc
            FROM PCDESCONTO
           WHERE CODDESCONTO = reg_pcpedi.coddesconto
             AND NVL(numverba, 0) > 0
			 AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vt561.codigo         := NULL;
            vt561.numverba       := NULL;
            vt561.perccustfornec := 0;
            vt561.perdesc        := 0;
        END;
      ELSE
        vt561.codigo         := NULL;
        vt561.numverba       := NULL;
        vt561.perccustfornec := 0;
        vt561.perdesc        := 0;
      END IF;
    
      IF (nvl(reg_pcpedi.codcombo, 0) <> 0) THEN --3306    
        
        BEGIN
          SELECT TIPOVALOR, TIPO
            INTO V_TIPOVALOR, V_TIPO
            FROM (SELECT TIPOVALOR, TIPO
                    FROM PCDESCONTOCATEGORIA A
                   WHERE A.CODIGO = reg_pcpedi.Codcombo
                   ORDER BY NVL(A.PERCDESC, 0) DESC) 
           WHERE ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            V_TIPOVALOR := 0;
            V_TIPO      := '';
        END;
      
        IF (V_TIPOVALOR <> 0) THEN
        
          V_CODPROD := 0;
        
          V_CODPROD := PRODUTO_SQP(V_TIPOVALOR,
                                   V_TIPO,
                                   reg_pcpedi.numped,
                                   reg_pcpedi.Codcombo,
                                   pCODFILIAL);
          BEGIN
            SELECT CODIGO, NUMVERBA, PERCCUSTFORNEC, PERDESC
              INTO VT3306_SQP.CODIGO,
                   vt3306_SQP.NUMVERBA,
                   vt3306_SQP.PERCCUSTFORNEC,
                   vt3306_SQP.PERDESC
              FROM (SELECT C.CODIGO,
                           C.NUMVERBA,
                           NVL(C.PERCCUSTFORNEC, 0) PERCCUSTFORNEC,
                           NVL(I.PERCDESC, 0) PERDESC
                      FROM PCDESCONTOCATEGORIA I
                     INNER JOIN PCDESCONTOC C
                        ON C.CODIGO = I.CODIGO
                     WHERE C.CODIGO = REG_PCPEDI.CODCOMBO
                       AND ((V_CODPROD = REG_PCPEDI.CODPROD AND
                           NVL(C.UTILIZACODPRODPRINC, 'N') = 'N') OR
                           (V_CODPROD =
                           (SELECT PCPRODUT.CODPRODPRINC
                                FROM PCPRODUT
                               WHERE CODPROD = REG_PCPEDI.CODPROD) AND
                           NVL(C.UTILIZACODPRODPRINC, 'N') = 'S'))
                       AND I.TIPOVALOR = V_TIPOVALOR
                       AND I.TIPO      = V_TIPO
                     ORDER BY NVL(I.PERCDESC, 0) DESC)
             WHERE ROWNUM = 1;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              VT3306_SQP.codigo         := NULL;
              VT3306_SQP.numverba       := NULL;
              VT3306_SQP.perccustfornec := 0;
              VT3306_SQP.perdesc        := 0;
          END;
        ELSE
          VT3306_SQP.codigo         := NULL;
          VT3306_SQP.numverba       := NULL;
          VT3306_SQP.perccustfornec := 0;
          VT3306_SQP.perdesc        := 0;
        END IF;
      
        BEGIN
          SELECT CODIGO, NUMVERBA, PERCCUSTFORNEC, PERDESC
            INTO vt3306_AUTO.CODIGO,
                 vt3306_AUTO.NUMVERBA,
                 vt3306_AUTO.PERCCUSTFORNEC,
                 vt3306_AUTO.PERDESC
            FROM (SELECT C.CODIGO,
                         C.NUMVERBA,
                         NVL(C.PERCCUSTFORNEC, 0) PERCCUSTFORNEC,
                         NVL(I.PERDESC, 0) PERDESC
                    FROM PCDESCONTOC C, PCDESCONTOI I, PCORIGEMPRECO O
                   WHERE C.CODIGO = I.CODIGO
                     AND C.CODIGO = O.CODDESCFLEX
                     AND I.CODIGO = O.CODDESCFLEX
                     AND I.CODPROD = O.CODPROD
                     AND O.NUMPED = REG_PCPEDI.NUMPED
                     AND C.CODIGO = REG_PCPEDI.CODCOMBO
                     AND O.NUMSEQ = REG_PCPEDI.NUMSEQ
                     AND ((I.CODPROD = REG_PCPEDI.CODPROD AND
                         NVL(C.UTILIZACODPRODPRINC, 'N') = 'N') OR
                         (I.CODPROD =
                         (SELECT PCPRODUT.CODPRODPRINC
                              FROM PCPRODUT
                             WHERE CODPROD = REG_PCPEDI.CODPROD) AND
                         NVL(C.UTILIZACODPRODPRINC, 'N') = 'S'))
                     AND NVL(C.ALTERARPTABELA, 'N') = 'S'
                   ORDER BY NVL(I.PERDESC, 0) DESC)
           WHERE ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vt3306_AUTO.codigo         := NULL;
            vt3306_AUTO.numverba       := NULL;
            vt3306_AUTO.perccustfornec := 0;
            vt3306_AUTO.perdesc        := 0;
        END;
      
        BEGIN
          SELECT CODIGO, NUMVERBA, PERCCUSTFORNEC, PERDESC
            INTO VT3306.CODIGO,
                 VT3306.NUMVERBA,
                 VT3306.PERCCUSTFORNEC,
                 VT3306.PERDESC
            FROM (SELECT C.CODIGO,
                         C.NUMVERBA,
                         NVL(C.PERCCUSTFORNEC, 0) PERCCUSTFORNEC,
                         NVL(I.PERDESC, 0) PERDESC
                    FROM PCDESCONTOC C, PCDESCONTOI I
                   WHERE C.CODIGO = I.CODIGO
                     AND C.CODIGO = REG_PCPEDI.CODCOMBO
                     AND ((I.CODPROD = REG_PCPEDI.CODPROD AND
                         NVL(C.UTILIZACODPRODPRINC, 'N') = 'N') OR
                         (I.CODPROD =
                         (SELECT PCPRODUT.CODPRODPRINC
                              FROM PCPRODUT
                             WHERE CODPROD = REG_PCPEDI.CODPROD) AND
                         NVL(C.UTILIZACODPRODPRINC, 'N') = 'S'))
                   ORDER BY NVL(I.PERDESC, 0) DESC)
           WHERE ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vt3306.codigo         := NULL;
            vt3306.numverba       := NULL;
            vt3306.perccustfornec := 0;
            vt3306.perdesc        := 0;
        END;
      ELSE
        vt3306.codigo              := NULL;
        vt3306.numverba            := NULL;
        vt3306.perccustfornec      := 0;
        vt3306.perdesc             := 0;
        vt3306_AUTO.codigo         := NULL;
        vt3306_AUTO.numverba       := NULL;
        vt3306_AUTO.perccustfornec := 0;
        vt3306_AUTO.perdesc        := 0;
        vt3306_SQP.codigo          := NULL;
        vt3306_SQP.numverba        := NULL;
        vt3306_SQP.perccustfornec  := 0;
        vt3306_SQP.perdesc         := 0;
      END IF;
    
      IF (nvl(reg_pcpedi.codigobrinde, 0) <> 0) THEN
        --3320
        BEGIN
          SELECT B.CODBREX,
                 B.NUMVERBA,
                 NVL(B.PERCCUSTFORNEC, 0),
                 NVL(reg_pcpedi.pbonific, 0)
            INTO vt3320.codigo,
                 vt3320.numverba,
                 vt3320.perccustfornec,
                 vt3320.vlcustfornec
            FROM PCBRINDEEX B, PCBRINDEEXPREMIO P
           WHERE B.CODBREX = P.CODBREX
             AND p.codprod = reg_pcpedi.codprod
             AND B.CODBREX = reg_pcpedi.codigobrinde
             AND NVL(B.numverba, 0) > 0
             AND p.Gruporegra = reg_pcpedi.grpregrabrinde
             AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vt3320.codigo         := NULL;
            vt3320.numverba       := NULL;
            vt3320.perccustfornec := 0;
            vt3320.perdesc        := 0;
        END;
      ELSE
        vt3320.codigo         := NULL;
        vt3320.numverba       := NULL;
        vt3320.perccustfornec := 0;
        vt3320.perdesc        := 0;
      END IF;
    
      IF (nvl(reg_pcpedi.codprecofixo, 0) <> 0) THEN
        --357
        BEGIN
          SELECT CODPRECOPROM,
                 NUMVERBA,
                 NVL(PERCCUSTFORNEC, 0),
                 NVL(ROUND(((reg_pcpedi.pvenda / reg_pcpedi.ptabela) * 100) - 100,
                           6),
                     0)
            INTO vt357.codigo,
                 vt357.numverba,
                 vt357.perccustfornec,
                 vt357.perdesc
            FROM PCPRECOPROM
           WHERE CODPRECOPROM = reg_pcpedi.codprecofixo
             AND NVL(numverba, 0) > 0
			 AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vt357.codigo         := NULL;
            vt357.numverba       := NULL;
            vt357.perccustfornec := 0;
            vt357.perdesc        := 0;
        END;
      ELSE
        vt357.codigo         := NULL;
        vt357.numverba       := NULL;
        vt357.perccustfornec := 0;
        vt357.perdesc        := 0;
      END IF;
    
      IF (nvl(reg_pcpedi.codprecocesta, 0) <> 0) THEN
        --3307
        BEGIN
          SELECT CODPRECOCESTA,
                 NUMVERBA,
                 NVL(PERCCUSTFORNEC, 0),
                 NVL(ROUND(((reg_pcpedi.pvenda / reg_pcpedi.ptabela) * 100) - 100,
                           6),
                     0)
            INTO vt3307.codigo,
                 vt3307.numverba,
                 vt3307.perccustfornec,
                 vt3307.perdesc
            FROM PCPRECOCESTAC
           WHERE CODPRECOCESTA = reg_pcpedi.codprecocesta
             AND NVL(numverba, 0) > 0
			 AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vt3307.codigo         := NULL;
            vt3307.numverba       := NULL;
            vt3307.perccustfornec := 0;
            vt3307.perdesc        := 0;
        END;
      ELSE
        vt3307.codigo         := NULL;
        vt3307.numverba       := NULL;
        vt3307.perccustfornec := 0;
        vt3307.perdesc        := 0;
      END IF;
    
      IF NVL(vt301.perdesc, 0) > NVL(vt357.perdesc, 0) AND
         NVL(vt301.perdesc, 0) > NVL(vt561_AUTO.perdesc, 0) AND
         NVL(vt301.perdesc, 0) > NVL(vt561.perdesc, 0) AND
         NVL(vt301.perdesc, 0) > NVL(vt3306.perdesc, 0) AND
         NVL(vt301.perdesc, 0) > NVL(vt3306_AUTO.perdesc, 0) AND
         NVL(vt301.perdesc, 0) > NVL(vt3306_SQP.perdesc, 0) THEN
        --301 maior desconto
        vnNUMVERBACAMPANHA := vt301.numverba;
        vnPERCCUSTFORNEC   := vt301.perccustfornec;
        VNPERDESC          := NVL(vt301.perdesc, 0);
      
      ELSIF NVL(vt561.perdesc, 0) > NVL(vt301.perdesc, 0) AND
            NVL(vt561.perdesc, 0) > NVL(vt357.perdesc, 0) AND
            NVL(vt561.perdesc, 0) > NVL(vt561_AUTO.perdesc, 0) AND
            NVL(vt561.perdesc, 0) > NVL(vt3306.perdesc, 0) AND
            NVL(vt561.perdesc, 0) > NVL(vt3306_AUTO.perdesc, 0) AND
            NVL(vt561.perdesc, 0) > NVL(vt3306_SQP.perdesc, 0) THEN
        --561 maior desconto
        vnNUMVERBACAMPANHA := vt561.numverba;
        vnPERCCUSTFORNEC   := vt561.perccustfornec;
        VNPERDESC          := NVL(vt561.perdesc, 0);
      ELSIF NVL(vt561_AUTO.perdesc, 0) > NVL(vt301.perdesc, 0) AND
            NVL(vt561_AUTO.perdesc, 0) > NVL(vt357.perdesc, 0) AND
            NVL(vt561_AUTO.perdesc, 0) > NVL(vt561.perdesc, 0) AND
            NVL(vt561_AUTO.perdesc, 0) > NVL(vt3306.perdesc, 0) AND
            NVL(vt561_AUTO.perdesc, 0) > NVL(vt3306_AUTO.perdesc, 0) AND
            NVL(vt561_AUTO.perdesc, 0) > NVL(vt3306_SQP.perdesc, 0) THEN
        --561 maior desconto
        vnNUMVERBACAMPANHA := vt561_AUTO.numverba;
        vnPERCCUSTFORNEC   := vt561_AUTO.perccustfornec;
        VNPERDESC          := NVL(vt561_AUTO.perdesc, 0);
      ELSIF NVL(vt3306.perdesc, 0) > NVL(vt301.perdesc, 0) AND
            NVL(vt3306.perdesc, 0) > NVL(vt357.perdesc, 0) AND
            NVL(vt3306.perdesc, 0) > NVL(vt561.perdesc, 0) AND
            NVL(vt3306.perdesc, 0) > NVL(vt561_AUTO.perdesc, 0) AND
            NVL(vt3306.perdesc, 0) > NVL(vt3306_AUTO.perdesc, 0) AND
            NVL(vt3306.perdesc, 0) > NVL(vt3306_SQP.perdesc, 0) THEN
        --3306 Normal
        vnNUMVERBACAMPANHA := vt3306.numverba;
        vnPERCCUSTFORNEC   := vt3306.perccustfornec;
        VNPERDESC          := NVL(vt3306.perdesc, 0);
      ELSIF NVL(vt3306_AUTO.perdesc, 0) > NVL(vt301.perdesc, 0) AND
            NVL(vt3306_AUTO.perdesc, 0) > NVL(vt561.perdesc, 0) AND
            NVL(vt3306_AUTO.perdesc, 0) > NVL(vt561_AUTO.perdesc, 0) AND
            NVL(vt3306_AUTO.perdesc, 0) > NVL(vt357.perdesc, 0) AND
            NVL(vt3306_AUTO.perdesc, 0) > NVL(vt3306.perdesc, 0) AND
            NVL(vt3306_AUTO.perdesc, 0) > NVL(vt3306_SQP.perdesc, 0) THEN
        --3306 (Config.Alterar Preço de Tabela)
        vnNUMVERBACAMPANHA := vt3306_AUTO.numverba;
        vnPERCCUSTFORNEC   := vt3306_AUTO.perccustfornec;
        VNPERDESC          := NVL(vt3306_AUTO.perdesc, 0);
      ELSIF NVL(vt3306_SQP.perdesc, 0) > NVL(vt301.perdesc, 0) AND
            NVL(vt3306_SQP.perdesc, 0) > NVL(vt561.perdesc, 0) AND
            NVL(vt3306_SQP.perdesc, 0) > NVL(vt561_AUTO.perdesc, 0) AND
            NVL(vt3306_SQP.perdesc, 0) > NVL(vt357.perdesc, 0) AND
            NVL(vt3306_SQP.perdesc, 0) > NVL(vt3306.perdesc, 0) AND
            NVL(vt3306_SQP.perdesc, 0) > NVL(vt3306_AUTO.perdesc, 0) THEN
        --3306 Campanha SQP
        vnNUMVERBACAMPANHA := vt3306_SQP.numverba;
        vnPERCCUSTFORNEC   := vt3306_SQP.perccustfornec;
        VNPERDESC          := NVL(vt3306_SQP.perdesc, 0);
      ELSIF nvl(vt357.codigo, 0) <> 0 THEN
        --357
        vnNUMVERBACAMPANHA := vt357.numverba;
        vnPERCCUSTFORNEC   := vt357.perccustfornec;
      
      ELSIF nvl(vt3307.codigo, 0) <> 0 THEN
        --3307
        vnNUMVERBACAMPANHA := vt3307.numverba;
        vnPERCCUSTFORNEC   := vt3307.perccustfornec;
      
      ELSIF nvl(vt3320.codigo, 0) <> 0 THEN
        --3320
        vnNUMVERBACAMPANHA := vt3320.numverba;
        vnPERCCUSTFORNEC   := vt3320.perccustfornec;
      
      ELSIF nvl(vt561_AUTO.codigo, 0) <> 0 THEN
        --561 auto
        vnNUMVERBACAMPANHA := vt561_AUTO.numverba;
        vnPERCCUSTFORNEC   := vt561_AUTO.perccustfornec;
      
      ELSIF nvl(vt3306_AUTO.codigo, 0) <> 0 THEN
        --3306 auto
        vnNUMVERBACAMPANHA := vt3306_AUTO.numverba;
        vnPERCCUSTFORNEC   := vt3306_AUTO.perccustfornec;
      
      ELSE
        vnNUMVERBACAMPANHA := NULL;
        vnPERCCUSTFORNEC   := NULL;
      END IF;
    
       IF ((vnNUMVERBACAMPANHA IS NOT NULL) AND
         (APLICAVEL(vnNUMVERBACAMPANHA, reg_pcpedi.codprod)))
          THEN
      
        IF NVL(vt3320.perccustfornec, 0) > 0 AND
           vt3320.numverba IS NOT NULL THEN
          reg_pcpedi.vlverbacmv  := GREATEST(ROUND(nvl(reg_pcpedi.pbonific,
                                                       reg_pcpedi.ptabela) *
                                                   (vt3320.perccustfornec / 100),
                                                   6),
                                             0);
          reg_pcpedi.vlcustofin  := reg_pcpedi.vlcustofin -
                                    ROUND(reg_pcpedi.vlcustofin *
                                          (vt3320.perccustfornec / 100),
                                          6);
          reg_pcpedi.vlcustoreal := reg_pcpedi.vlcustoreal -
                                    ROUND(reg_pcpedi.vlcustoreal *
                                          (vt3320.perccustfornec / 100),
                                          6);
          ------------------
          UPDATE pcpedi
             SET NUMVERBACAMPANHA = vnNUMVERBACAMPANHA,
                 PERCCUSTFORNEC   = vnPERCCUSTFORNEC,
                 vlcustofin       = reg_pcpedi.vlcustofin + nvl(vlverbacmv,0),
                 vlcustoreal      = reg_pcpedi.vlcustoreal + nvl(vlverbacmv,0),
                 vlverbacmv       = reg_pcpedi.vlverbacmv
           WHERE numped = reg_pcpedi.numped
             AND codprod = reg_pcpedi.codprod
             AND numseq = reg_pcpedi.numseq;
        
        ELSIF NVL(vt561_AUTO.perccustfornec, 0) > 0 AND
              vt561_AUTO.numverba IS NOT NULL THEN
          reg_pcpedi.vlcustofin  := reg_pcpedi.vlcustofin -
                                    ROUND(((reg_pcpedi.ptabela /
                                          (1 - vt561_AUTO.perdesc / 100)) -
                                          reg_pcpedi.ptabela) *
                                          (vnPERCCUSTFORNEC / 100),
                                          6);
          reg_pcpedi.vlcustoreal := reg_pcpedi.vlcustoreal -
                                    ROUND(((reg_pcpedi.ptabela /
                                          (1 - vt561_AUTO.perdesc / 100)) -
                                          reg_pcpedi.ptabela) *
                                          (vnPERCCUSTFORNEC / 100),
                                          6);
          reg_pcpedi.vlverbacmv  := GREATEST(ROUND(((reg_pcpedi.ptabela / (1 -
                                                   vt561_AUTO.perdesc / 100)) -
                                                   reg_pcpedi.ptabela) *
                                                   (vnPERCCUSTFORNEC / 100),
                                                   6),
                                             0);
          ------------------
          UPDATE pcpedi
             SET NUMVERBACAMPANHA = vnNUMVERBACAMPANHA,
                 PERCCUSTFORNEC   = vnPERCCUSTFORNEC,
                 vlcustofin       = reg_pcpedi.vlcustofin + nvl(vlverbacmv,0),
                 vlcustoreal      = reg_pcpedi.vlcustoreal + nvl(vlverbacmv,0),
                 vlverbacmv       = reg_pcpedi.vlverbacmv
           WHERE numped = reg_pcpedi.numped
             AND codprod = reg_pcpedi.codprod
             AND numseq = reg_pcpedi.numseq;
        
        ELSIF NVL(vt357.perccustfornec, 0) > 0 AND
              vt357.numverba IS NOT NULL THEN
          reg_pcpedi.vlcustofin  := reg_pcpedi.vlcustofin -
                                    ROUND((NVL(reg_pcpedi.pvendabase,
                                               reg_pcpedi.ptabela) -
                                          reg_pcpedi.pvenda) *
                                          (vnPERCCUSTFORNEC / 100),
                                          6);
          reg_pcpedi.vlcustoreal := reg_pcpedi.vlcustoreal -
                                    ROUND((NVL(reg_pcpedi.pvendabase,
                                               reg_pcpedi.ptabela) -
                                          reg_pcpedi.pvenda) *
                                          (vnPERCCUSTFORNEC / 100),
                                          6);
          reg_pcpedi.vlverbacmv  := GREATEST(ROUND((NVL(reg_pcpedi.pvenda1,
                                                        reg_pcpedi.ptabela) -
                                                   reg_pcpedi.pvenda) *
                                                   (vnPERCCUSTFORNEC / 100),
                                                   6),
                                             0);
          ------------------
          UPDATE pcpedi
             SET NUMVERBACAMPANHA = vnNUMVERBACAMPANHA,
                 PERCCUSTFORNEC   = vnPERCCUSTFORNEC,
                 vlcustofin       = reg_pcpedi.vlcustofin + nvl(vlverbacmv,0),
                 vlcustoreal      = reg_pcpedi.vlcustoreal + nvl(vlverbacmv,0),
                 vlverbacmv       = reg_pcpedi.vlverbacmv
           WHERE numped = reg_pcpedi.numped
             AND codprod = reg_pcpedi.codprod
             AND numseq = reg_pcpedi.numseq;
        
        ELSIF NVL(vt3306_AUTO.perccustfornec, 0) > 0 AND
              vt3306_AUTO.numverba IS NOT NULL THEN
          reg_pcpedi.vlcustofin  := reg_pcpedi.vlcustofin -
                                    ROUND(((reg_pcpedi.ptabela /
                                          (1 - vt3306_AUTO.perdesc / 100)) -
                                          reg_pcpedi.ptabela) *
                                          (vnPERCCUSTFORNEC / 100),
                                          6);
          reg_pcpedi.vlcustoreal := reg_pcpedi.vlcustoreal -
                                    ROUND(((reg_pcpedi.ptabela /
                                          (1 - vt3306_AUTO.perdesc / 100)) -
                                          reg_pcpedi.ptabela) *
                                          (vnPERCCUSTFORNEC / 100),
                                          6);
          reg_pcpedi.vlverbacmv  := GREATEST(ROUND(((reg_pcpedi.ptabela / (1 -
                                                   vt3306_AUTO.perdesc / 100)) -
                                                   reg_pcpedi.ptabela) *
                                                   (vnPERCCUSTFORNEC / 100),
                                                   6),
                                             0);
          ------------------
          UPDATE pcpedi
             SET NUMVERBACAMPANHA = vnNUMVERBACAMPANHA,
                 PERCCUSTFORNEC   = vnPERCCUSTFORNEC,
                 vlcustofin       = reg_pcpedi.vlcustofin + nvl(vlverbacmv,0),
                 vlcustoreal      = reg_pcpedi.vlcustoreal + nvl(vlverbacmv,0),
                 vlverbacmv       = reg_pcpedi.vlverbacmv
           WHERE numped = reg_pcpedi.numped
             AND codprod = reg_pcpedi.codprod
             AND numseq = reg_pcpedi.numseq;
        
        ELSE
          --Rebaixando o CMV
          --Rebaixa o custofin e custoreal com o valor encontrado na diferença
          --do pvenda e ptabela, ou seja, o valor integral do desconto concedido.

          if (round(reg_pcpedi.ptabela*VNPERDESC/100,6) < (reg_pcpedi.ptabela -
                                          reg_pcpedi.pvenda)) then
            VLDESCAPLIC := round(reg_pcpedi.ptabela*VNPERDESC/100,6);
          else
            VLDESCAPLIC := (reg_pcpedi.ptabela - reg_pcpedi.pvenda);
          end if;


          reg_pcpedi.vlcustofin  := reg_pcpedi.vlcustofin -
                                    ROUND((VLDESCAPLIC) *
                                          (vnPERCCUSTFORNEC / 100),
                                          6);
          reg_pcpedi.vlcustoreal := reg_pcpedi.vlcustoreal -
                                    ROUND((VLDESCAPLIC) *
                                          (vnPERCCUSTFORNEC / 100),
                                          6);
          reg_pcpedi.vlverbacmv  := GREATEST(ROUND((VLDESCAPLIC) *
                                                   (vnPERCCUSTFORNEC / 100),
                                                   6),
                                             0);
          ------------------
          UPDATE pcpedi
             SET NUMVERBACAMPANHA = VNNUMVERBACAMPANHA,
                 PERCCUSTFORNEC   = vnPERCCUSTFORNEC,
                 vlcustofin       = reg_pcpedi.vlcustofin + nvl(vlverbacmv,0),
                 vlcustoreal      = reg_pcpedi.vlcustoreal + nvl(vlverbacmv,0),
                 vlverbacmv       = reg_pcpedi.vlverbacmv
           WHERE numped = reg_pcpedi.numped
             AND codprod = reg_pcpedi.codprod
             AND numseq = reg_pcpedi.numseq;
        END IF;
      END IF;

    END IF;

  END APLICAR_VERBACAMPANHA;


PROCEDURE CALCULAR_ICMS_EFETIVO(pNUMTRANSITEM in NUMBER) is
  vsCONTRIBUINTE       PCCLIENT.CONTRIBUINTE%TYPE;
  vsCONSUMIDORFINAL    PCCLIENT.CONSUMIDORFINAL%TYPE;
  vnCODPROD            PCMOV.CODPROD%TYPE;
  vnCODFILIAL          PCMOV.CODFILIAL%TYPE;
  vnCODST              PCMOV.CODST%TYPE;
  vnALIQICMS1          PCEST.ALIQICMS1%TYPE;
  vnPUNITCONT          PCMOV.PUNITCONT%TYPE;
  vnVLBASEEFET         PCMOVCOMPLE.VLBASEEFET%TYPE;
  vnVLICMSEFET         PCMOVCOMPLE.VLICMSEFET %TYPE;
  vnPERCREDICMSEFETIVO PCTRIBUT.PERCREDICMSEFETIVO%TYPE;
  vnALIQICMSEFETIVO    PCTRIBUT.ALIQICMSEFETIVO%TYPE;
  vnVLBCFCPSTRET       PCEST.VLBCFCPSTRET%TYPE;
  vnVLFCPSTRET         PCEST.VLFCPSTRET%TYPE;
  vnPERFCPSTRET        PCEST.PERFCPSTRET%TYPE;
  vnNUMTRANSULTENTST   PCEST.NUMTRANSULTENTST%TYPE;
BEGIN
  REPLICAR_ICMS_SUBSTITUTO(pNUMTRANSITEM);
  SELECT t.CONSUMIDORFINAL,
         t.CONTRIBUINTE,
         m.CODPROD,
         NVL(m.CODFILIALNF,m.CODFILIAL) CODFILIAL,
         m.CODST,
         m.PUNITCONT
    INTO vsCONSUMIDORFINAL,
         vsCONTRIBUINTE,
         vnCODPROD,
         vnCODFILIAL,
         vnCODST,
         vnPUNITCONT
    FROM PCMOVCOMPLEPREFAT c, PCMOVPREFAT m, PCCLIENT T
   WHERE m.NUMTRANSITEM = c.NUMTRANSITEM
     AND t.CODCLI = m.CODCLI
     AND c.NUMTRANSITEM = pNUMTRANSITEM;


    --RETIDO
  SELECT e.ALIQICMS1,
         e.VLBCFCPSTRET,
         e.VLFCPSTRET,
         e.PERFCPSTRET,
         NVL(e.NUMTRANSULTENTST, 0)
    INTO vnALIQICMS1,
         vnVLBCFCPSTRET,
         vnVLFCPSTRET,
         vnPERFCPSTRET,
         vnNUMTRANSULTENTST
    FROM PCEST e
   WHERE e.CODPROD = vnCODPROD
     AND e.CODFILIAL = vnCODFILIAL;

  UPDATE PCMOVCOMPLEPREFAT c
     set c.ALIQICMS1RET = NVL(vnALIQICMS1, 0),
         c.VLBCFCPSTRET = NVL(vnVLBCFCPSTRET, 0),
         c.VLFCPSTRET   = NVL(vnVLFCPSTRET, 0),
         c.PERFCPSTRET  = NVL(vnPERFCPSTRET, 0),
         c.NUMTRANSULTENTSTANT = vnNUMTRANSULTENTST
   where c.NUMTRANSITEM = pNUMTRANSITEM;

  IF (vsCONSUMIDORFINAL = 'S') and (vsCONTRIBUINTE = 'N') THEN
    --EFETIVO
    BEGIN
      select NVL(t.ALIQICMSEFETIVO, 0), NVL(t.PERCREDICMSEFETIVO, 0)
        into vnALIQICMSEFETIVO, vnPERCREDICMSEFETIVO
        from PCTRIBUT t
       where CODST = vnCODST;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnALIQICMSEFETIVO    := 0;
        vnPERCREDICMSEFETIVO := 0;
    END;
    --Realizar procedimentos somente se a aliquota estiver preenchida
    if vnALIQICMSEFETIVO > 0 then
      if (vnPERCREDICMSEFETIVO > 0) then
        vnVLBASEEFET := vnPUNITCONT * (vnPERCREDICMSEFETIVO/100);
      ELSE
        vnVLBASEEFET := vnPUNITCONT;
      END IF;
      --5
      vnVLICMSEFET := vnVLBASEEFET * vnALIQICMSEFETIVO/100;
      update PCMOVCOMPLEPREFAT c
         set c.PERCICMSEFET        = vnALIQICMSEFETIVO,
             c.PERCREDBASEEFET     = vnPERCREDICMSEFETIVO,
             c.VLBASEEFET          = vnVLBASEEFET,
             c.VLICMSEFET       	 = vnVLICMSEFET
       where c.NUMTRANSITEM = pNUMTRANSITEM;
    END IF;
  END IF;
END;
PROCEDURE REPLICAR_ICMS_SUBSTITUTO(pNUMTRANSITEM in NUMBER) is
  vnCODOPER   PCMOV.CODOPER%TYPE;
  vnVLICMSBCR PCEST.VLICMSBCR%TYPE;
  vnCODPROD   PCEST.CODPROD%TYPE;
  vsCODFILIAL PCEST.CODFILIAL%TYPE;
  vsQUALTABELA varchar2(15);
BEGIN
  vsQUALTABELA := 'XX';
  BEGIN
    select NVL(MOV.CODOPER, 'XX'), codprod,  NVL(NVL(MOV.CODFILIALNF, MOV.CODFILIAL), MOV.CODFILIALRETIRA)
      into vnCODOPER, vnCODPROD, vsCODFILIAL
      from PCMOV MOV
     where NUMTRANSITEM = pNUMTRANSITEM;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      vnCODOPER := '';
  END;
  IF nvl(vnCODOPER, 'XX') <> 'XX' THEN
    vsQUALTABELA := 'PCMOV';
  END IF;

  IF nvl(vnCODOPER, 'XX') = 'XX' THEN
    BEGIN
      select PCMOVPREFAT.CODOPER, codprod,  NVL(NVL(PCMOVPREFAT.CODFILIALNF, PCMOVPREFAT.CODFILIAL), PCMOVPREFAT.CODFILIALRETIRA)
        into vnCODOPER, vnCODPROD, vsCODFILIAL
        from PCMOVPREFAT
       where NUMTRANSITEM = pNUMTRANSITEM;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnCODOPER := 'XX';
    END;
  END IF;

  IF NVL(vsQUALTABELA,'XX') = 'XX' THEN
    vsQUALTABELA := 'PCMOVPREFAT';
  END IF;

  IF vnCODOPER <> 'XX' THEN
    FOR ITENS IN (select EST.CODPROD, EST.BASEICMSBCR, EST.VLICMSBCR
                    from  PCEST EST
                   where 1=1
                     and EST.CODPROD = vnCODPROD
                     and EST.CODFILIAL = vscodfilial
                     and NVL(EST.VLICMSBCR, 0) <> 0) LOOP

    IF vsQUALTABELA = 'PCMOV' THEN
      update PCMOV
         set VLICMSBCR = ITENS.VLICMSBCR, BASEICMSBCR = ITENS.BASEICMSBCR
       WHERE PCMOV.NUMTRANSITEM = pNUMTRANSITEM;
    END if;

    IF vsQUALTABELA = 'PCMOVPREFAT' THEN
      update PCMOVPREFAT
         set VLICMSBCR = ITENS.VLICMSBCR, BASEICMSBCR = ITENS.BASEICMSBCR
       WHERE PCMOVPREFAT.NUMTRANSITEM = pNUMTRANSITEM;
    END IF;

    END LOOP;
  END IF;
END;

FUNCTION CALCULAR_QTVASILHAME_MOTORISTA(pNumcar IN NUMBER,
                                        vsMsg   IN OUT VARCHAR2)
  RETURN VARCHAR2 IS

  VNQTVASILHAMES NUMBER(8);

BEGIN
  vsMsg := '';

  IF FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CONTROLEVASILHAMEMOTORISTA',
                                        '99',
                                        'N') = 'S' THEN

    BEGIN
      IF (pNumcar > 0) THEN

        VNQTVASILHAMES := 0;

        SELECT NVL(SUM(QTVASILHAMES), 0)
          INTO VNQTVASILHAMES
          FROM (SELECT ceil(SUM(I.QT /
                                DECODE(NVL(V.QTUNITCX, 0), 0, 1, V.QTUNITCX))) QTVASILHAMES
                  FROM PCPEDI            I,
                       PCPEDC            C,
                       PCPRODUTVASILHAME PV,
                       PCVASILHAME       V
                 WHERE I.CODPROD = PV.CODPROD
                   AND I.NUMCAR = pNumCar
                   AND I.NUMPED = C.NUMPED
                   AND C.ORIGEMPED NOT IN ('R', 'B')
                   AND C.POSICAO NOT IN ('C')
                   AND PV.CODVASILHAME = V.CODVASILHAME
                 GROUP BY I.QT, V.QTUNITCX, I.POSICAO); -- Favor não retirar o Group By

        IF VNQTVASILHAMES > 0 THEN

          FOR VASILHAME IN (SELECT I.NUMCAR,
                                   I.CODPROD,
                                   PV.CODVASILHAME,
                                   PV.PRECO, -- I.NUMSEQ,
                                   ceil(SUM(I.QT / DECODE(NVL(V.QTUNITCX, 0),
                                                          0,
                                                          1,
                                                          V.QTUNITCX))) QTVASILHAMES
                              FROM PCPEDI            I,
                                   PCPEDC            C,
                                   PCPRODUTVASILHAME PV,
                                   PCVASILHAME       V
                             WHERE I.CODPROD = PV.CODPROD
                               AND I.NUMCAR = pNumcar
                               AND I.NUMPED = C.NUMPED
                               AND C.ORIGEMPED NOT IN ('R', 'B')
                               AND PV.CODVASILHAME = V.CODVASILHAME
                             GROUP BY I.NUMCAR,
                                      I.CODPROD,
                                      PV.CODVASILHAME,
                                      PV.PRECO)

           LOOP

            UPDATE PCMOVVASILHAME
               SET PCMOVVASILHAME.QT = VASILHAME.QTVASILHAMES
             WHERE NUMPED = VASILHAME.NUMCAR
               AND CODPROD = VASILHAME.CODPROD
               AND CODVASILHAME = VASILHAME.CODVASILHAME;

            IF SQL%ROWCOUNT = 0 THEN

              INSERT INTO PCMOVVASILHAME
                (NUMPED,
                 NUMTRANSVENDA,
                 CODPROD,
                 NUMSEQ,
                 CODVASILHAME,
                 QT,
                 PUNIT)
              VALUES
                (VASILHAME.NUMCAR,
                 0,
                 VASILHAME.CODPROD,
                 --VASILHAME.NUMSEQ,
                 0,
                 VASILHAME.CODVASILHAME,
                 VASILHAME.QTVASILHAMES,
                 VASILHAME.PRECO);

            END IF;

          END LOOP;

        ELSE
          BEGIN
            FOR VASILHAME IN (SELECT I.NUMCAR, I.CODPROD, PV.CODVASILHAME
                                FROM PCMOV             I,
                                     PCNFSAID          C,
                                     PCPRODUTVASILHAME PV,
                                     PCVASILHAME       V,
                                     PCPEDC            CC
                               WHERE I.CODPROD = PV.CODPROD
                                 AND I.NUMCAR = pNumCar
                                 AND I.NUMPED = C.NUMPED
                                 AND CC.NUMPED = C.NUMPED
                                 AND CC.NUMPED = I.NUMPED
                                 AND CC.ORIGEMPED NOT IN ('R', 'B')

                                 AND PV.CODVASILHAME = V.CODVASILHAME
                               GROUP BY I.NUMCAR,
                                        I.CODPROD,
                                        PV.CODVASILHAME,
                                        PV.PRECO
                              UNION
                              SELECT I.NUMCAR, I.CODPROD, PV.CODVASILHAME
                                FROM PCMOVPREFAT       I,
                                     PCNFSAIDPREFAT    C,
                                     PCPRODUTVASILHAME PV,
                                     PCVASILHAME       V,
                                     PCPEDC            CC
                               WHERE I.CODPROD = PV.CODPROD
                                 AND I.NUMCAR = pNumCar
                                 AND I.NUMPED = C.NUMPED
                                 AND CC.NUMPED = C.NUMPED
                                 AND CC.NUMPED = I.NUMPED
                                 AND CC.ORIGEMPED NOT IN ('R', 'B')
                                 AND PV.CODVASILHAME = V.CODVASILHAME
                               GROUP BY I.NUMCAR,
                                        I.CODPROD,
                                        PV.CODVASILHAME,
                                        PV.PRECO)

             LOOP

              UPDATE PCMOVVASILHAME
                 SET PCMOVVASILHAME.QT = 0
               WHERE NUMPED = VASILHAME.NUMCAR
                 AND CODPROD = VASILHAME.CODPROD
                 AND CODVASILHAME = VASILHAME.CODVASILHAME;

            END LOOP;
          END;

        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        vsMsg := 'Erro ao tentar efetuar a atualização dos vasilhames do carregamento: ' || pNumCar || CHR(13) ||
                 'Erro: ' || SQLCODE || '-' || SQLERRM;

    END;
  END IF;
  RETURN vsMsg;

END;

/************************************************************************************************************************
  ------------------------------------------------------ Alterações -------------------------------------------------------
  Data           Autor             Solicitação         Descrição
  -------------------------------------------------------------------------------------------------------------------------
  09/10/2019     Fernando Carmo                        Criado a função para localizar o estoque da filial retira que irá
                                                       atender o pedido, conforme regras de ordem de prioridade
  ************************************************************************************************************************/
PROCEDURE PROCURAR_ESTOQUE( psCODFILIAL IN PCPEDC.CODFILIAL%TYPE --Código filial venda
                          , pnNUMPED    IN PCPEDI.NUMPED%TYPE
                          , pnCODPROD   IN PCPEDI.CODPROD%TYPE
                          , pnNUMSEQ    IN PCPEDI.NUMSEQ%TYPE)
iS
  vnSALDO PCPEDI.QT%TYPE;
  voLINHAPCPEDI PCPEDI%ROWTYPE;
  vnQTUNITEMBALAGEM PCEMBALAGEM.QTUNIT%TYPE;
  vnESTOQUEDISPONIVEL PCEST.QTESTGER%TYPE;

  Function ProximoNumSeq(pnNumpedido NUMBER)
    RETURN NUMBER
  IS
    vnProximo PCPEDI.NUMSEQ%TYPE;
  BEGIN
    BEGIN
      SELECT MAX(PCPEDI.NUMSEQ)
        INTO vnProximo
        FROM PCPEDI
       WHERE PCPEDI.NUMPED = pnNumpedido;
    exception
    WHEN NO_DATA_FOUND THEN
      vnProximo := 0;
    END;

    vnProximo := vnProximo + 1;

    return vnProximo;
  END;

BEGIN
  FOR REGISTROS IN (SELECT A.*
                         , CASE WHEN (A.TIPOESTOQUE = 'FR') AND (A.UTILIZAFRIOSEMBALAGEM = 'S')
                                THEN CASE WHEN A.UNIDADEMASTER = A.UNIDADEVENDA
                                          THEN 'M' --Unidade master
                                          WHEN A.UNIDADEVENDA = 'PC'
                                          THEN 'P' --Peças
                                          ELSE 'N' --Normal
                                     END
                                ELSE 'N' --Normal
                            END CONFIGURACAO_ESTOQUE
                      FROM (SELECT PCPEDI.NUMPED
                                 , psCODFILIAL as CODFILIAL
                                 , PCPEDI.CODPROD
                                 , NVL(PCPEDI.CODAUXILIAR, PCPRODUT.CODAUXILIAR) CODAUXILIAR
                                 , PCPEDI.NUMSEQ
                                 , PCPEDI.QT
                                 , NVL(PCPEDI.CODFILIALRETIRA, psCODFILIAL) CODFILIALRETIRA
                                 --
                                 , UPPER(TRIM(PCPEDI.UNIDADE)) UNIDADEVENDA
                                 , UPPER(TRIM(PCPRODUT.UNIDADEMASTER)) UNIDADEMASTER
                                 , DECODE(NVL(PCPRODFILIAL.PESOBRUTOMASTER,0), 0, NVL(PCPRODUT.PESOBRUTOMASTER,1), PCPRODFILIAL.PESOBRUTOMASTER) PESOBRUTOMASTER
                                 , DECODE(NVL(PCPRODFILIAL.PESOPECA,0), 0, NVL(PCPRODUT.PESOPECA,1), PCPRODFILIAL.PESOPECA) PESOPECA
                                 , FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_UTILIZAFRIOSEMBALAGEM', PCFILIAL.CODIGO, 'N') UTILIZAFRIOSEMBALAGEM
                                 , FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FIL_UTILIZAVENDAPOREMBALAGEM', psCODFILIAL, 'N') UTILIZAVENDAPOREMBALAGEM
                                 , NVL(PCPRODUT.TIPOESTOQUE,'X') TIPOESTOQUE

                              FROM PCPEDI
                                 , PCPRODUT
                                 , PCFILIAL
                                 , PCPRODFILIAL
                             WHERE PCPEDI.CODPROD  = PCPRODUT.CODPROD
                               AND PCPEDI.NUMPED   = pnNUMPED
                               AND PCPEDI.CODPROD  = pnCODPROD
                               AND PCPEDI.NUMSEQ   = pnNUMSEQ
                               AND NVL(PCPEDI.CODFILIALRETIRA, psCODFILIAL) = PCFILIAL.CODIGO
                               AND PCPEDI.CODPROD  = PCPRODFILIAL.CODPROD
                               AND PCFILIAL.CODIGO = PCPRODFILIAL.CODFILIAL
                           ) A
                    )
  LOOP
    --Saldo do produto a ser analisado
    vnSALDO := REGISTROS.QT;

    --Retornado o dados do estoque que tem saldo
    FOR ESTOQUES IN (SELECT B.*
                       FROM (SELECT A.CODFILIAL
                                  , A.CODPROD
                                  , A.PRIORIDADE
                                  , A.PESOPECA
                                  , A.PESOBRUTOMASTER
                                  , CASE WHEN REGISTROS.CONFIGURACAO_ESTOQUE IN ('M', 'P')
                    								     THEN TRUNC(A.QTDISP)
                										 ELSE A.QTDISP
                								    END
                                  --Retira o saldo já usado no pedido, caso o Item já esteja inserido
                                  - NVL((SELECT SUM(PCPEDI.QT)
                                           FROM PCPEDI
                                          WHERE PCPEDI.NUMPED          = REGISTROS.NUMPED
                                            AND PCPEDI.CODPROD         = REGISTROS.CODPROD
                                            AND PCPEDI.CODFILIALRETIRA = A.CODFILIAL
                                            AND PCPEDI.NUMSEQ         <> REGISTROS.NUMSEQ),0) QTDISP
                               FROM TABLE(pkg_estoque.ESTOQUE_DISPONIVEL_RETIRA( REGISTROS.CODPROD
                                                                               , REGISTROS.CODAUXILIAR
                                                                               , REGISTROS.CODFILIAL)
                            ) A
                         ) B
                     WHERE B.QTDISP > 0
                    )
    LOOP
      vnQTUNITEMBALAGEM := 1;
      IF (REGISTROS.TIPOESTOQUE = 'FR' AND REGISTROS.UTILIZAFRIOSEMBALAGEM = 'S') THEN
        vnQTUNITEMBALAGEM := CASE WHEN REGISTROS.CONFIGURACAO_ESTOQUE = 'M' THEN ESTOQUES.PESOBRUTOMASTER
                                  WHEN REGISTROS.CONFIGURACAO_ESTOQUE = 'P' THEN ESTOQUES.PESOPECA
                             ELSE 1 END;
      ELSE
        IF REGISTROS.UTILIZAVENDAPOREMBALAGEM = 'S' THEN
          SELECT QTUNIT
            INTO vnQTUNITEMBALAGEM
            FROM PCEMBALAGEM
           WHERE PCEMBALAGEM.CODFILIAL = ESTOQUES.CODFILIAL
             AND PCEMBALAGEM.CODPROD = ESTOQUES.CODPROD
             AND PCEMBALAGEM.CODAUXILIAR = REGISTROS.CODAUXILIAR;
        END IF;
      END IF;

      --Se o estoque atender a necessidade
      IF ESTOQUES.QTDISP >= vnSALDO THEN
         --Altera a filial retira caso não seja a mesma
         IF ESTOQUES.CODFILIAL <> REGISTROS.CODFILIALRETIRA THEN
            UPDATE PCPEDI
               SET PCPEDI.CODFILIALRETIRA = ESTOQUES.CODFILIAL
                 , PCPEDI.QT              = vnSALDO
             WHERE PCPEDI.CODPROD         = REGISTROS.CODPROD
               AND PCPEDI.NUMSEQ          = REGISTROS.NUMSEQ
               AND PCPEDI.NUMPED          = REGISTROS.NUMPED;
         END IF;
         vnSaldo := 0;
      ELSE
        vnESTOQUEDISPONIVEL := TRUNC(ESTOQUES.QTDISP / vnQTUNITEMBALAGEM) * vnQTUNITEMBALAGEM;
        vnSaldo := vnSaldo - vnESTOQUEDISPONIVEL;

        --Clonar a linha para desdobrar o pedido
        SELECT *
          INTO voLINHAPCPEDI
          FROM PCPEDI
         WHERE PCPEDI.NUMPED  = REGISTROS.NUMPED
           AND PCPEDI.CODPROD = REGISTROS.CODPROD
           AND PCPEDI.NUMSEQ  = REGISTROS.NUMSEQ;

        --Ajustando o registro do novo lançamento
        voLINHAPCPEDI.QT              := vnESTOQUEDISPONIVEL;
        voLINHAPCPEDI.QTORIG          := vnESTOQUEDISPONIVEL;
        voLINHAPCPEDI.CODFILIALRETIRA := ESTOQUES.CODFILIAL;
        voLINHAPCPEDI.NUMSEQ          := PROXIMONUMSEQ(REGISTROS.NUMPED);

        --Inserindo um novo item no pedido
        INSERT INTO PCPEDI
             VALUES voLINHAPCPEDI;

        --Atualizar o saldo do item original
        UPDATE PCPEDI
           SET PCPEDI.QT      = GREATEST(PCPEDI.QT - vnESTOQUEDISPONIVEL,0)
         WHERE PCPEDI.CODPROD = REGISTROS.CODPROD
           AND PCPEDI.NUMSEQ  = REGISTROS.NUMSEQ
           AND PCPEDI.NUMPED  = REGISTROS.NUMPED;

        --Sair quando a prioridade não está pcfilialretira
        EXIT WHEN (ESTOQUES.PRIORIDADE < 0);
      END IF;

      --Saldo zerado para a execução
      IF vnSALDO = 0 THEN
         EXIT;
      END IF;

    END LOOP;

    SELECT PCPEDI.QT
      INTO vnSALDO
      FROM PCPEDI
     WHERE PCPEDI.NUMPED  = pnNUMPED
       AND PCPEDI.CODPROD = pnCODPROD
       AND PCPEDI.NUMSEQ  = pnNUMSEQ;

     --Excluir o registro se o mesmo ficar zerado
     DELETE PCPEDI
      WHERE PCPEDI.CODPROD = REGISTROS.CODPROD
        AND PCPEDI.NUMPED  = REGISTROS.NUMPED
        AND PCPEDI.QT      = 0;

    IF vnSALDO <= 0 THEN

       UPDATE PCPEDI
          SET NUMSEQ = pnNUMSEQ
        WHERE PCPEDI.NUMPED  = pnNUMPED
          AND PCPEDI.CODPROD = pnCODPROD
          AND PCPEDI.NUMSEQ = voLINHAPCPEDI.NUMSEQ;

    END IF;

  END LOOP;
END;

PROCEDURE buscarserienf(pscodfilialnf                IN pcpedc.codfilialnf%TYPE,
                          pncondvenda                  IN pcpedc.condvenda%TYPE,
                          pnpercvenda                  IN pcpedc.percvenda%TYPE,
                          psorigemped                  IN pcpedc.origemped%TYPE,
                          psgeranftipo8                IN pcconsum.geranftipo8%TYPE,
                          vc2uf_filial                 IN OUT pcfilial.uf%TYPE,
                          vsnumidf                     IN OUT pcfilial.numidf%TYPE,
                          vncoddocnf                   IN OUT pcfilial.coddocnf%TYPE,
                          vsindustria                  IN OUT pcfilial.industria%TYPE,
                          vnvltarifa                   IN OUT pcfilial.vltarifa%TYPE,
                          vnvlmintarifabanc            IN OUT pcfilial.vlmintarifabanc%TYPE,
                          vnvlmaxtarifabanc            IN OUT pcfilial.vlmaxtarifabanc%TYPE,
                          vssomatarifabancduplic       IN OUT pcfilial.somatarifabancduplic%TYPE,
                          vstipobroker                 IN OUT pcfilial.tipobroker%TYPE,
                          psmsg                        IN OUT VARCHAR2,
                          vc2serie                     IN OUT PCNFSAIDPREFAT.serie%TYPE,
                          vsutipercbaseredoutrasdesppf IN OUT pcfilial.utilizapercbaseredoutrasdesppf%TYPE,
                          vsbloqdesdemitentedif        IN OUT pcfilial.bloqdesdemitentedif%TYPE,
                          vncodcontavendaentregafut    IN OUT pcfilial.codcontavendaentregafut%TYPE,
                          vsusaintegracaowms           IN OUT pcfilial.usaintegracaowms%TYPE)
  /*******************************************************************************
                                      Historico
    --------------------------------------------------------------------------------
      Data        Responsavel      Tarefa Alteracao
      ----------  ---------------  ------ ------------------------------------------
      09/10/2006  Sabrina          33212  Ajuste para reduzir tamanho do programa
      04/11/2020  Marcello          -     Movida para reduzir Diana Nodes na 1400.
    *******************************************************************************