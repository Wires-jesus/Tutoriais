CREATE OR REPLACE PROCEDURE PRC_MONTAGEMKIT(p_validaestoque IN VARCHAR2,
                                            p_matricula     IN NUMBER,
                                            p_codfilial     IN VARCHAR2,
                                            p_numped        IN NUMBER,
                                            p_mensagem      OUT VARCHAR2,
                                            p_codprod        in number default null,
                                            p_numseq        in number default null ) IS
  /*******************************************************************************
  Procedure: PROCEDURE PRC_MONTAGEMKIT
  Autora: Andrea Bandeira
  ------------------------------------------- Manutenção -----------------------------------------------------------
  Data               Tarefa       Resp.         Descrição
  16/05/2008         60988        Pablo          Na validação do estoque disponível foi acrescentado o NVL nas quantidade
                                                 para evitar erro quando algum dos valores estiver nullo.
  15/09/2008         68475        Aracelia       Checagem do parametro PCFILIAL.CONSIDERAMONTAGEMGIROMERC, para movimentar o giro do produto
  25/09/2008         69557        Carlos Costa   Alterado o Select para validar o produto tipo CB mas que não esteja gravado na tabela PCFORMPROD
                                                 para evitar a geração de movimentação de entrada na PCMOV.
  21/10/2008         71122        Rogério        Ajustar mensagem de retorno em caso de exception na seleção de itens da cesta.
  30/10/2008         71534        Pablo          Alteração para gerar o Kit conforme a disponibilidade da matéria-prima
  24/11/2008         73119        Pablo          Correção da atualização do PCEST de divisão por zero.
  11/12/2008         73448        Pablo          Alteração para somente montar o kit caso o novo parâmetro PCFILIAL.MontarKitAutomaticamente
                                                 esteja habilitado
  24/11/2011        149782        Pablo          Alteração para gerar o Kit na Filial retira do item do pedido.
  23/12/2011        152451        Thiago Melo    Alterado procedimento para atender ki cesta parcial
  30/03/2012        159876        Thiago Melo    Alterado procedimento para atender ki cesta quando não existe estoque
  04/04/2012        159876        Thiago Melo    Ajuste nas mensagens de retorno do procedimento.
  02/10/2012        176272        Marcos Garcia  Inclusão dos parametros de codprod e numseq para não refazer um item que ja foi processado
  26/09/2013        212051        Rafael Braga   Parâmetros codprod e numseq sendo validados na montagem da cesta básica (select VNDIF).
  *******************************************************************************/
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
  erro_estoque                EXCEPTION;
  vnReturn                    NUMBER;
  vbVendaPorEmbalagem         BOOLEAN := FALSE;
BEGIN
  vsmensagem := 'OK';

  SELECT NVL(pcfilial.montarkitautomaticamente, 'S')
    INTO vsmontarkitautomaticamente
    FROM pcfilial
   WHERE codigo = p_codfilial;

  IF vsmontarkitautomaticamente = 'N' THEN
    vsmensagem := 'FILIAL NÃO MONTA KIT\CESTA-BÁSICA AUTOMATICAMENTE.';
  END IF;

  vsatualizaent1122   := ferramentas.F_BUSCARPARAMETRO_ALFA('CON_ATUALIZAENT1122', '99', 'N');
  vbVendaPorEmbalagem := ferramentas.F_BUSCARPARAMETRO_ALFA('FIL_UTILIZAVENDAPOREMBALAGEM', p_codfilial, 'N') = 'S';

  IF vsmontarkitautomaticamente = 'S' THEN
    SELECT COUNT(*)
      INTO VICONT
      FROM PCPEDI
          ,PCPRODUT
     WHERE PCPEDI.NUMPED = P_NUMPED
       AND NVL(PCPRODUT.TIPOMERC, 'X') = 'CB'
       AND NVL(PCPEDI.QT, 0) > 0
       AND NVL(PCPEDI.QT, 0) > PKG_ESTOQUE.ESTOQUE_DISPONIVEL(PCPEDI.CODPROD,
                                                              COALESCE(PCPEDI.CODFILIALRETIRA,
                                                                       P_CODFILIAL),
                                                              '')
       AND PCPEDI.CODPROD = PCPRODUT.CODPROD;

    IF vicont > 0 THEN
      ----------------********* BUSCAR SEQUENCIA DE ENTRADA E DE SAIDA *******--------------
      BEGIN
        FOR reg IN (SELECT PCPEDI.CODPROD CODPRODACAB
                          ,PCPEDI.QT
                          ,PKG_ESTOQUE.ESTOQUE_DISPONIVEL(PCPEDI.CODPROD,
                                                          COALESCE(PCPEDI.CODFILIALRETIRA,
                                                                   P_CODFILIAL),
                                                          '') QTDISP
                          ,NVL(PCPEDI.CODFILIALRETIRA, P_CODFILIAL) CODFILIALRETIRA -- Tarefa 149782
                      FROM PCPEDI
                          ,PCPRODUT
                     WHERE PCPEDI.NUMPED = P_NUMPED
                       AND NVL(PCPRODUT.TIPOMERC, 'X') = 'CB'
                       AND NVL(PCPEDI.QT, 0) > 0
                       AND PCPEDI.CODPROD = PCPRODUT.CODPROD
                       AND PCPEDI.CODPROD = DECODE(P_CODPROD, NULL, PCPEDI.CODPROD, P_CODPROD)
                       AND PCPEDI.NUMSEQ = DECODE(P_NUMSEQ, NULL, PCPEDI.NUMSEQ, P_NUMSEQ))
        LOOP
          -- Tarefa 71354
          vndif := 0;

          --Ajustado procedimento para atender o kit cesta parcialmente.
          IF (NVL(vndif, 0) / reg.qt) <> trunc((NVL(vndif, 0) / reg.qt)) THEN
            vndif := vndif + 1;
          END IF;

          vnqtde_produzida := GREATEST(reg.qt -
                                       (reg.qtdisp +
                                       trunc((NVL(vndif, 0) / reg.qt))),
                                       0);

          -- Tarefa 71534
          IF vnqtde_produzida = 0 THEN
            vsmensagem := 'NÃO EXISTE ESTOQUE PARA MONTAGEM DO KIT.';
          ELSE
            ----------------********* SAIDA DE PRODUCAO ****************----------------
            vnproxnumtransvenda := FERRAMENTAS.F_PROX_NUMTRANSVENDA;
            vnproxnumtransent   := FERRAMENTAS.F_PROX_NUMTRANSENT;

            BEGIN
              FOR REG_ITENS IN (SELECT PCFORMPROD.CODPRODMP,
                                       PCFORMPROD.QTPRODMP,
                                       COALESCE(PCEMBALAGEM.QTUNIT, 0) QTUNIT_EMB
                                  FROM PCFORMPROD, PCEMBALAGEM
                                 WHERE PCFORMPROD.CODPRODACAB = REG.CODPRODACAB
                                   AND PCEMBALAGEM.CODFILIAL(+) = REG.CODFILIALRETIRA
                                   AND PCEMBALAGEM.CODPROD(+) = PCFORMPROD.CODPRODMP
                                   AND PCEMBALAGEM.CODAUXILIAR(+) = PCFORMPROD.CODAUXILIARMP) LOOP

                --VERIFICAR SE EXISTE ESTOQUE GERENCIAL DISPONÍVEL DAS MATERIAS-PRIMAS
                vnqt_saida := vnqtde_produzida * reg_itens.qtprodmp * CASE WHEN vbVendaPorEmbalagem THEN
                                                                        reg_itens.QTUNIT_EMB
                                                                      ELSE
                                                                        1
                                                                      END;

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
                   AND codfilial = reg.codfilialretira;

                IF NVL(p_validaestoque, 'N') = 'S' AND
                   NVL(vnqt_saida, 0) >
                   PKG_ESTOQUE.ESTOQUE_DISPONIVEL(REG_ITENS.CODPRODMP,
                                                  REG.CODFILIALRETIRA,
                                                  '')
				THEN
                  vsmensagem := 'PRODUTOS QUE COMPÕEM O KIT CESTA NÃO TEM ESTOQUE.';
                  RAISE erro_estoque;
                ELSE
                  -- DAR BAIXA NO ESTOQUE GERENCIAL
                  -- existia uma alteração da quantidade gerencial - VNQT_SAIDA

                  --Tarefa 68475
                  SELECT NVL(CONSIDERAMONTAGEMGIROMERC, 'N')
                    INTO VSCONSIDERAMONTAGEMGIROMERC
                    FROM PCFILIAL
                   WHERE CODIGO = REG.CODFILIALRETIRA;

                  IF VSCONSIDERAMONTAGEMGIROMERC = 'S'
                  THEN
                    UPDATE PCEST
                       SET QTVENDMES =
                           (NVL(PCEST.QTVENDMES, 0) + VNQT_SAIDA)
                     WHERE CODPROD = REG_ITENS.CODPRODMP
                       AND CODFILIAL = REG.CODFILIALRETIRA;
                  END IF;

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
                     percvenda, --29
                     qtestgerant, --30
                     qtestant, --31
                     custoultentant,  --32
                     MOVESTOQUEGERENCIAL) --33
                  VALUES
                    (TRUNC(SYSDATE), --1
                     reg_itens.codprodmp,
                     --2
                     0,
                     --3
                     'SP', --4
                     vnqt_saida, --5
                     vncustorep_ant, --6
                     reg.codfilialretira, --7
                     'B', --8
                     p_matricula, --9
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
                     vnproxnumtransvenda,
                     --26
                     vncodfornec, --27
                     0,
                     --28
                     0, --29
                     vnqtestger_ant, --30
                     vnqtest_ant, --31
                     vncustoultent_ant,  --32
                     'S'); --33
                END IF;
              END LOOP;
            EXCEPTION
              WHEN OTHERS THEN
                IF vsmensagem IS NULL THEN
                  vsmensagem := 'ERRO AO SELECIONAR ITENS DA CESTA.' ||
                                chr(13) || SQLCODE || ' ' || SQLERRM;
                END IF;
                RAISE;
            END;

            ---------------********* ENTRADA DE PRODUCAO *************----------------------

            --ATUALIZACAO DOS CUSTOS
            SELECT SUM(NVL(pcformprod.qtprodmp, 0) * NVL(pcest.custofin, 0)) custofin_entrada,
                   SUM(NVL(pcformprod.qtprodmp, 0) *
                       NVL(pcest.custoreal, 0)) custoreal_entrada,
                   SUM(NVL(pcformprod.qtprodmp, 0) * NVL(pcest.custorep, 0)) custorep_entrada,
                   SUM(NVL(pcformprod.qtprodmp, 0) *
                       NVL(pcest.valorultent, 0)),
                   SUM(NVL(pcformprod.qtprodmp, 0) *
                       NVL(pcest.custoultent, 0))
              INTO vncustofin_entrada,
                   vncustoreal_entrada,
                   vncustorep_entrada,
                   vnvalorultent_entrada,
                   vncustoultent_entrada
              FROM pcformprod, pcest
             WHERE pcformprod.codprodacab = reg.codprodacab
               AND pcest.codfilial = reg.codfilialretira
               AND pcformprod.codprodmp = pcest.codprod;

            SELECT custofin, custoreal, custorep, custoultent, valorultent
              INTO vncustofin_ant,
                   vncustoreal_ant,
                   vncustorep_ant,
                   vncustoultent_ant,
                   vnvalorultent_ant
              FROM pcest
             WHERE codprod = reg.codprodacab
               AND codfilial = reg.codfilialretira;

            IF NVL(vsatualizaent1122, 'N') = 'S' THEN
              UPDATE pcest
                 SET custofin  = ((vncustofin_ant * qtestger) +
                                 (vncustofin_entrada * vnqtde_produzida)) /
                                 DECODE((qtestger + vnqtde_produzida),
                                        0,
                                        1,
                                        (qtestger + vnqtde_produzida)),
                     custoreal = ((vncustoreal_ant * qtestger) +
                                 (vncustoreal_entrada * vnqtde_produzida)) /
                                 DECODE((qtestger + vnqtde_produzida),
                                        0,
                                        1,
                                        (qtestger + vnqtde_produzida)),
                     custorep  = ((vncustorep_ant * qtestger) +
                                 (vncustorep_entrada * vnqtde_produzida)) /
                                 DECODE((qtestger + vnqtde_produzida),
                                        0,
                                        1,
                                        (qtestger + vnqtde_produzida)),
                     -- ALIMENTAR ESTOQUE GERENCIAL
                     -- existia uma alteração da quantidade gerencial + vnqtde_produzida,
                     custoultent = ((vncustoultent_ant * qtestger) +
                                   (vncustoultent_entrada *
                                   vnqtde_produzida)) /
                                   DECODE((qtestger + vnqtde_produzida),
                                          0,
                                          1,
                                          (qtestger + vnqtde_produzida)),
                     valorultent = ((vnvalorultent_ant * qtestger) +
                                   (vnvalorultent_entrada *
                                   vnqtde_produzida)) /
                                   DECODE((qtestger + vnqtde_produzida),
                                          0,
                                          1,
                                          (qtestger + vnqtde_produzida)),
                     dtultent    = TRUNC(SYSDATE)
               WHERE codprod = reg.codprodacab
                 AND codfilial = reg.codfilialretira;
            ELSE
              UPDATE pcest
                 SET custofin  = ((vncustofin_ant * qtestger) +
                                 (vncustofin_entrada * vnqtde_produzida)) /
                                 DECODE((qtestger + vnqtde_produzida),
                                        0,
                                        1,
                                        (qtestger + vnqtde_produzida)),
                     custoreal = ((vncustoreal_ant * qtestger) +
                                 (vncustoreal_entrada * vnqtde_produzida)) /
                                 DECODE((qtestger + vnqtde_produzida),
                                        0,
                                        1,
                                        (qtestger + vnqtde_produzida)),
                     custorep  = ((vncustorep_ant * qtestger) +
                                 (vncustorep_entrada * vnqtde_produzida)) /
                                 DECODE((qtestger + vnqtde_produzida),
                                        0,
                                        1,
                                        (qtestger + vnqtde_produzida))
                     -- ALIMENTAR ESTOQUE GERENCIAL
                     -- existia uma alteração da quantidade gerencial + vnqtde_produzida
               WHERE codprod = reg.codprodacab
                 AND codfilial = reg.codfilialretira;
            END IF;

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
               percvenda, --29
               qtestgerant, --30
               qtestant, --31
               custoultentant, --32
               MOVESTOQUEGERENCIAL)  --33
            VALUES
              (TRUNC(SYSDATE), --1
               reg.codprodacab, --2
               0, --3
               'EP', --4
               vnqtde_produzida, --5
               vncustorep_entrada, --6
               reg.codfilialretira, --7
               'B', --8
               p_matricula, --9
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
               null, --vnproxnumtransvenda, --26 package de estoque localiza transação.
               vncodfornec, --27
               0, --28
               0, --29
               vnqtestger_ant, --30
               vnqtest_ant, --31
               vncustoultent_ant,  --32
               'S');  --33

            vnReturn := PKG_ESTOQUE.VENDAS_SAIDA(vnproxnumtransvenda, 'N',vsmensagem);
            vnReturn := PKG_ESTOQUE.VENDAS_ENTRADA(vnproxnumtransent, 'N',vsmensagem);
          END IF;

        END LOOP;

      EXCEPTION
        WHEN OTHERS THEN
            IF vsmensagem IS NULL THEN
              vsmensagem := 'ERRO AO SELECIONAR DADOS DA CESTA.' || chr(13) ||
                            SQLCODE || ' - ' || SQLERRM;
            END IF;
          RAISE;
      END;
    END IF;
  END IF; -- IF vsMontarKitAutomaticamente = 'S'

  p_mensagem := vsmensagem;
EXCEPTION
  WHEN erro_estoque THEN
    p_mensagem := vsmensagem;
  WHEN OTHERS THEN
    p_mensagem := vsmensagem;
END prc_montagemkit;
