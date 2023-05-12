CREATE OR REPLACE PROCEDURE wms_processacorte (
   pnumos        IN       NUMBER,
   pqtseparada   IN       NUMBER,
   pcodprod      IN       NUMBER,
   pmatricula    IN       NUMBER,
   pcodrotina    IN       NUMBER,
   pcodfilial    IN       STRING,
   pcodmotivo    IN       NUMBER,
   resultado     OUT      VARCHAR2
)
IS
/* LOG DE ALTERAÇÕES **************************************************************************************
 VERSAO 4.8 (06/08/2011) Marcio Morais - Tarefa 139313 - Adcionada sequencia de corte, respeitando PCPEDI.BONIFIC
 VERSAO 4.7 (30/06/2011) Marcio Morais - Tarefa 140730 - Adcionado NVL na consulta do NUMCAR
 VERSAO 4.6 (30/06/2011) Marcio Morais - Tarefa 135976 - PCEST.QTRESERV não fica menor que zero
 VERSAO 4.5 (17/05/2011) Marcio Morais - Tarefa 132713 - PCPEDI.MOTIVO passa a ser gravado.
 VERSAO 4.4 (12/04/2011) Marcio Morais - Tarefa 129066 - Adcionado log da tabela PCWMSCORTE.
 VERSAO 4.3 (17/02/2011) Marcio Morais - Tarefa 125255 - Realizado calculo de volume para tabelas que não possuirem um valor inforamdo.
 VERSAO 4.2 (25/01/2011) Marcio Morais - Tarefa 125444 - Adcionado corte na tabela PCCONFERENCIAWMS para conferência por corte.
 VERSAO 4.1 (02/09/2010) Fabricio Santos - Tarefa 115168 - Incluído NVL para considerar CODFILIALRETIRA ao invés de CODFILIALORIGEM.
 VERSAO 4.0 (21/25/2010) Anderson Pereira - Tarefa 106085. A procedure passa a utilizar a filial gestão para
                                            atualizar os dados no winthor gestão e a filial de estoque para
                                            atualizar o WMS.
 VERSAO 3.9 (26/04/2010) Fabricio Santos - Alterada a gravação do campo PCCORTE.QTSEPARADA
 VERSAO 3.8 (21/12/2009) Marcio Morais - Alterada a ordenação do cursor, tarefa 97251
 VERSAO 3.7 (03/11/2009) Marcio Morais - Alterada mensagem da PCMENS, tarefa 94356
 VERSAO 3.6 (09/10/2009) Marcio Morais - Adcionado FOR UPDATE para a atualização nas tabelas PCEST e PCESTENDERECO
 VERSAO 3.5 (07/10/2009) Marcio Morais - Alterada chamada da package de credito do RCA
 VERSAO 3.4 (02/10/2009) Marcio Morais - Adcionada gravação na tabela PCMENS
 VERSAO 3.3 (24/09/2009) Fabricio Santos - Retirado lançamentos na tabela PCLOGRCA
 VERSAO 3.2 (25/08/2009) Marcio Morais - Corrigido chamda da package pakage de RCA
 VERSAO 3.2 (24/07/2009) Cleber Junior - 73291, Substituido modificações em tabela PCUSUARI por execução de pakage
                         PC_PKG_CONTROLARSALDORCA.ccrca_alterar_preço_qt
 VERSAO 3.1 (21/05/2009) Anderson Pereira - 84915, A data a ser gravada na tabela PCLOGRCA será sempre SYSDATE
 VERSAO 3.0 (21/05/2009) Anderson Pereira - 84915, Caso o sistema estiver parametrizado para usar crédito de
                         RCA, a procedure irá realizar INSERT na tabela PCLOGRCA.
 VERSÃO 2.9 (09/10/2008) Anderson Pereira - 70166, Inclusão do CODCLI E CONDVENDA na PCCORTE e PCCORTEI
 VERSÃO 2.8 (19/08/2008) Igor Siqueira - Tarefa 65270, Inclusão do CodCli e CodFilial na PCCORTEI
 VERSÃO 2.7  (30/06/2008) Fabricio Santos - Tarefa 61723, Implementado Controle de Filial.
 Versão 2.6 (16/06/2008) Fabricio Santos - Tarefa 64184 Retirada Liberação de endereço.
 VERSÃO 2.5 (08/04/2008) Marcio Morais - Tarefa 60964, Adcionado tarefa referente ao novo calculo do RCA
 VERSAO 2.4 (14/12/2007 Marcio Morais - Adcionado rowid da pcmovendpend para fazer distinção qdo houver produtos
                                        duplicados na mesma OS)
 VERSAO 2.3 (22/10/2007 Marcio Morais - Adcionado liberação de endereço)
 VERSAO 2.3 (2/10/2007 Marcio Morais - Corrigido numvol para o tipo de OS 20)
 VERSAO 2.2 (20/09/2007 Fabricio Santos)
 VERSAO 2.2 (04/04/2007) - FOI RETIRADO A VALIDAÇÃO SE GERANDOMAPA=S NA ATUALIZAÇÃO DO ESTOQUE NO ENDEREÇO
 VERSAO 1.03 (20/12/2006 MARCOS LIMA 10:03)

***********************************************************************************************************/
   vdata                           DATE;
   vnumcar                         NUMBER;
   vnumped                         NUMBER;
   vcontador                       NUMBER;
   vqtos                           NUMBER;
   vtotpeso                        NUMBER;
   vtotvolume                      NUMBER;
   vvlatend                        NUMBER;
   vqtitens                        NUMBER;
   vvlcustocont                    NUMBER;
   vvlcustorep                     NUMBER;
   vvlcustofin                     NUMBER;
   vvlcustoreal                    NUMBER;
   vvltabela                       NUMBER;
   vqtped                          NUMBER;
   vqtcli                          NUMBER;
   vqtcid                          NUMBER;
   vnumnotas                       NUMBER;
   vnumtransvenda                  NUMBER;
   vnument                         NUMBER;
   vnumcid                         NUMBER;
   vqtcortetot                     NUMBER;
   vqtcortereg                     NUMBER;
   vcodprod                        NUMBER;
   vcodendereco                    NUMBER;
   vqtorig                         NUMBER (16, 8);
   vntipoos                        NUMBER;
   vnqtunitcx                      NUMBER;
   vntemp                          NUMBER;
   vnforupdate                     NUMBER;
   vnqtpediorig                    NUMBER;
   vusacredrca                     VARCHAR2 (1);
   vgerandomapa                    VARCHAR2 (1);
   vtipocorte                      VARCHAR2 (1);
   vutilizacheckout                VARCHAR2 (1);
   vposicao_os                     VARCHAR2 (1);
   vcodoper                        VARCHAR2 (1);
   vpickrotativo                   VARCHAR2 (1);
   vendvirtual                     VARCHAR2 (1);
   vtipoender                      VARCHAR2 (2);
   vusasaldocontacorrentedescfin   VARCHAR (1);
   vdtestorno                      DATE;
   vdtval                          DATE;
   vvlcorrente                     NUMBER (16, 8);
   vvlcorrenteant                  NUMBER (16, 8);
   vvllimcred                      NUMBER (16, 8);
   vvllimcredant                   NUMBER (16, 8);
   vpesopeca                       NUMBER (16, 8);
   vpesovariavel                   VARCHAR2(1);
   vretornocorte                   BOOLEAN;
   falha_no_corte                  EXCEPTION;

   CURSOR c_corte
   IS
      -- POR PEDIDO
      SELECT   c.DATA, a.numcar, a.numped, a.posicao, p.qtunitcx, m.qt,
                                                                 -- QT PEDIDO
               a.qt qtpedi, a.pvenda, a.ptabela, c.codusur, m.numtranswms, nvl(m.numpalete,0) numpalete,

               -- NVL(A.CODFILIALRETIRA,C.CODFILIAL) CODFILIAL,
               NVL (a.codfilialretira,
                    (SELECT w.codfilialorigem
                       FROM pcwms w
                      WHERE w.numped = a.numped
                        AND w.codprod = a.codprod
                        AND w.dtcancel IS NULL)
                   ) codfilial,
               c.codcli, c.condvenda,                                       --
                                     m.codendereco, m.numtransvenda,
               NVL (a.numseq, 0) numseq, m.tipoos, m.ROWID rowidpcmovendpend,
               a.pbaserca, m.qtseparada,
               (m.qt - NVL (m.qtseparada, 0)) qtfaltasep,
               (SELECT cliente
                  FROM pcclient
                 WHERE codcli = c.codcli) cliente,
               decode(nvl(a.bonific,'N'),'S',1,0) ordembonific
          FROM pcpedi a, pcpedc c, pcmovendpend m, pcprodut p
         WHERE c.numped = a.numped
           AND a.codprod = p.codprod
           AND m.codprod = a.codprod
           AND m.numos = pnumos
           AND vtipocorte = 'P'
           AND m.numped = c.numped
           AND a.codprod = pcodprod
           AND m.codfilial = pcodfilial
      UNION ALL
      -- POR CARREGAMENTO
      SELECT   c.DATA, a.numcar, a.numped, a.posicao, p.qtunitcx, a.qt,
                                                            -- QT CARREGAMENTO
               a.qt qtpedi, a.pvenda, a.ptabela, c.codusur, m.numtranswms, nvl(m.numpalete,0) numpalete,

               --NVL(A.CODFILIALRETIRA,C.CODFILIAL) CODFILIAL,
               NVL(A.CODFILIALRETIRA,(SELECT w.codfilialorigem
                  FROM pcwms w
                 WHERE w.numped = a.numped
                   AND w.codprod = a.codprod
                   AND w.dtcancel IS NULL)) codfilial,
               c.codcli, c.condvenda,                                        --
                                     m.codendereco, m.numtransvenda,
               NVL (a.numseq, 0) numseq, m.tipoos, m.ROWID rowidpcmovendpend,
               a.pbaserca, m.qtseparada,
               (m.qt - NVL (m.qtseparada, 0)) qtfaltasep,
               (SELECT cliente
                  FROM pcclient
                 WHERE codcli = c.codcli) cliente,
               decode(nvl(a.bonific,'N'),'S',1,0) ordembonific
          FROM pcpedi a, pcpedc c, pcmovendpend m, pcprodut p
         WHERE c.numped = a.numped
           AND a.codprod = p.codprod
           AND m.codprod = a.codprod
           AND m.numos = pnumos
           AND vtipocorte = 'C'                                 --CARREGAMENTO
           AND m.numcar = c.numcar
           AND a.codprod = pcodprod
           AND m.codfilial = pcodfilial
      ORDER BY ordembonific,qtfaltasep DESC;
BEGIN
   resultado := 'FALHA ';

   select nvl(pesovariavel,'N'),nvl(pesopeca,0) INTO vpesovariavel,vpesopeca from pcprodut where codprod = pcodprod;

-- AJUSTADA PARA BARRAR O CORTE PARA OS QUE JÁ TENHA NF EMITIDA
   SELECT   SUM (m.qt), MAX (m.numped), nvl(m.numcar,0),
            NVL (t.utilizacheckout, 'N'), m.posicao, m.dtestorno,
            c.usacredrca, NVL (m.numtransvenda, 0), c.gerandomapa, m.tipoos,
            NVL (c.usasaldocontacorrentedescfin, 'N')
       INTO vqtos, vnumped, vnumcar,
            vutilizacheckout, vposicao_os, vdtestorno,
            vusacredrca, vnumtransvenda, vgerandomapa, vntipoos,
            vusasaldocontacorrentedescfin
       FROM pcmovendpend m, pctipoos t, pcconsum c
      WHERE m.numos = pnumos AND m.codprod = pcodprod AND m.tipoos = t.codigo(+)
   GROUP BY NVL (t.utilizacheckout, 'N'),
            m.posicao,
            m.dtestorno,
            c.usacredrca,
            m.numcar,
            m.numtransvenda,
            c.gerandomapa,
            m.tipoos,
            c.usasaldocontacorrentedescfin;

   SELECT qtunitcx
     INTO vnqtunitcx
     FROM pcprodut
    WHERE codprod = pcodprod;

   IF vntipoos = 20
   THEN
      vntemp := (pqtseparada / vnqtunitcx) - TRUNC (pqtseparada / vnqtunitcx);

      IF vntemp <> 0
      THEN
         resultado :=
               'OS TIPO 20 - Quantidade separada tem de ser multipla da unidade de caixa: '
            || vnqtunitcx;
         RAISE falha_no_corte;
      END IF;
   END IF;

   IF vdtestorno IS NOT NULL
   THEN
      resultado := 'NUMERO DE O.S CANCELADA!! CORTE NAO PERMITIDO!!!';
      RAISE falha_no_corte;
   END IF;

   IF vposicao_os = 'C'
   THEN
      resultado := 'NUMERO DE O.S JÁ CONFIRMADA!! CORTE NAO PERMITIDO!!!';
      RAISE falha_no_corte;
   END IF;

   IF vnumtransvenda > 0
   THEN
      resultado := 'NF JÁ FOI EMITIDA!! CORTE NAO PERMITIDO!!!';
      RAISE falha_no_corte;
   END IF;

   IF vnumcar <> 0
   THEN
      vtipocorte := 'C';                                       --CARREGAMENTO
   END IF;

   IF vnumped <> 0
   THEN
      vtipocorte := 'P';                                             --PEDIDO
   END IF;

   vqtcortetot := vqtos - pqtseparada;

   FOR reg IN c_corte
   LOOP
      IF reg.qt >= vqtcortetot
      THEN
         vqtcortereg := vqtcortetot;
         vqtcortetot := 0;
      ELSE
         vqtcortereg := reg.qt;
         vqtcortetot := vqtcortetot - vqtcortereg;
      END IF;

      IF vqtcortereg <> 0 THEN
         insert into PCWMSCORTE( DATA
                                 ,CODFILIAL
                                 ,NUMTRANSWMS
                                 ,NUMCAR
                                 ,NUMPED
                                 ,NUMOS
                                 ,TIPOOS
                                 ,NUMPALETE
                                 ,CODENDERECO
                                 ,CODPROD
                                 ,QTCORTADA
                                 ,QT
                                 ,CODFUNCOS
                                 ,CODFUNCCORTE
                                 ,CODMOTIVO
                                 ,CODROTINA)
               values (          sysdate
                                ,pcodfilial
                                ,REG.NUMTRANSWMS
                                ,NVL(REG.NUMCAR,0)
                                ,REG.NUMPED
                                ,pnumos
                                ,REG.TIPOOS
                                ,REG.Numpalete
                                ,REG.CODENDERECO
                                ,pcodprod
                                ,vqtcortereg
                                ,REG.QT
                                ,(select max(codfuncos) from pcmovendpend where numos=pnumos)
                                ,pmatricula
                                ,pcodmotivo
                                ,pcodrotina
               );
      END IF;

      IF vqtcortereg <> 0
      THEN
         -- ARMAZENAR O SALDO DO RCA APOS A AXECUÇÃO DO UPDATE ACIMA
         IF vusacredrca = 'S'
         THEN
            SELECT NVL (u.vlcorrente, 0) vlcorrente,
                   NVL (u.vllimcred, 0) vllimcred
              INTO vvlcorrente,
                   vvllimcred
              FROM pcusuari u
             WHERE u.codusur = reg.codusur;
         END IF;

         -- ALIMENTA A TABELA DE CABECALHO DE CORTE
         SELECT COUNT (*)
           INTO vcontador
           FROM pccorte
          WHERE codprod = pcodprod AND numcar = vnumcar;

         IF vcontador > 0
         THEN
            UPDATE pccorte
               SET qtseparada = (qtseparada + reg.qt - vqtcortereg),
                   qtcortada = (qtcortada + vqtcortereg),
                   DATA = TRUNC (SYSDATE),
                   codfunc = pmatricula,
                   numped = reg.numped,
                   codrotina = pcodrotina,
                   codcli = reg.codcli,
                   condvenda = reg.condvenda
             WHERE codprod = pcodprod AND numcar = vnumcar;
         END IF;

         IF vcontador = 0
         THEN
            INSERT INTO pccorte
                        (codprod, qtseparada, qtcortada,
                         DATA, numcar, codfunc, numped,
                         codrotina, codcli, condvenda
                        )
                 VALUES (pcodprod, reg.qt - vqtcortereg, vqtcortereg,
                         TRUNC (SYSDATE), nvl(vnumcar,0), pmatricula, reg.numped,
                         pcodrotina, reg.codcli, reg.condvenda
                        );
         /*** 21/05/2009 TAREFA 84915 *************************************/
         END IF;

         -- ALIMENTA A TABELA DE ITENS DO CORTE
         SELECT COUNT (*)
           INTO vcontador
           FROM pccortei
          WHERE codprod = pcodprod
            AND numcar = vnumcar
            AND numped = reg.numped
            AND codfilial = reg.codfilial;

         IF vcontador = 0
         THEN
            INSERT INTO pccortei
                        (codprod, qtseparada, qtcortada,
                         DATA,
                         hora,
                         minuto, numcar,
                         codfunc, numped, pvenda, codfilial,
                         codrotina, codcli, condvenda,motivo
                        )
                 VALUES (pcodprod, reg.qt - vqtcortereg, vqtcortereg,
                         TRUNC (SYSDATE),
                         TO_NUMBER (TO_CHAR (SYSDATE, 'HH24')),
                         TO_NUMBER (TO_CHAR (SYSDATE, 'MI')), nvl(vnumcar,0),
                         pmatricula, reg.numped, reg.pvenda, reg.codfilial,
                         pcodrotina, reg.codcli, reg.condvenda,
                         pcodmotivo
                        );
         END IF;

         IF vcontador > 0
         THEN
            UPDATE pccortei
               SET qtseparada = (reg.qt - vqtcortereg),
                   qtcortada = (qtcortada + vqtcortereg),
                   DATA = TRUNC (SYSDATE),
                   hora = TO_NUMBER (TO_CHAR (SYSDATE, 'HH24')),
                   minuto = TO_NUMBER (TO_CHAR (SYSDATE, 'MI')),
                   codfunc = pmatricula,
                   numped = reg.numped,
                   codrotina = pcodrotina,
                   codcli = reg.codcli,
                   condvenda = reg.condvenda
             WHERE codprod = pcodprod
               AND numcar = vnumcar
               AND numped = reg.numped;

            UPDATE pccorte
               SET qtseparada =
                      (SELECT SUM (qtseparada)
                         FROM pccortei
                        WHERE codprod = pcodprod
                          AND numcar = vnumcar
                          AND numped = reg.numped)
             WHERE codprod = pcodprod
               AND numcar = vnumcar
               AND numped = reg.numped;
         END IF;

         -- RETIRAR A QUANTIDADE RESERVADA DOS PEDIDOS MONOTADOS OU LIBERADOS
         IF reg.posicao IN ('L', 'M')
         THEN
            SELECT COUNT (codprod)
              INTO vnforupdate
              FROM pcest
             WHERE codfilial = reg.codfilial AND codprod = pcodprod;

            IF vnforupdate > 0
            THEN
               SELECT     codprod
                     INTO vnforupdate
                     FROM pcest
                    WHERE codfilial = reg.codfilial AND codprod = pcodprod
               FOR UPDATE;
            END IF;

            UPDATE pcest
               SET qtreserv = greatest(0,NVL (qtreserv, 0) - (vqtcortereg))
             WHERE codfilial = reg.codfilial AND codprod = pcodprod;
         END IF;

         -- RETIRAR A QUANTIDADE PENDENTE DO ESTOQUE DE ENDERECOS
         SELECT COUNT (codprod)
           INTO vnforupdate
           FROM pcestendereco
          WHERE codendereco = reg.codendereco
            AND pcestendereco.codprod = pcodprod;

         IF vnforupdate > 0
         THEN
            SELECT     codprod
                  INTO vnforupdate
                  FROM pcestendereco
                 WHERE codendereco = reg.codendereco
                   AND pcestendereco.codprod = pcodprod
            FOR UPDATE;
         END IF;

         UPDATE pcestendereco
            SET qtpendsaida = GREATEST (NVL (qtpendsaida, 0) - vqtcortereg, 0)
          WHERE codendereco = reg.codendereco
            AND pcestendereco.codprod = pcodprod;

         vnqtpediorig := reg.qtpedi;

         SELECT COUNT (codprod)
           INTO vnforupdate
           FROM pcpedi
          WHERE codprod = pcodprod
            AND numped = reg.numped
            AND qtorig IS NULL
            AND numseq = reg.numseq;

         IF vnforupdate > 0
         THEN
            SELECT     codprod
                  INTO vnforupdate
                  FROM pcpedi
                 WHERE codprod = pcodprod
                   AND numped = reg.numped
                   AND qtorig IS NULL
                   AND numseq = reg.numseq
            FOR UPDATE;
         END IF;

         --ARMAZENAR QUANTIDADE ORIGINAL
         UPDATE pcpedi
            SET qtorig = qt
          WHERE codprod = pcodprod
            AND numped = reg.numped
            AND qtorig IS NULL
            AND numseq = reg.numseq;

         -- ATUALIZAR ITENS DO PEDIDO
         UPDATE pcpedi
            SET qt = qt - vqtcortereg
          WHERE codprod = pcodprod
            AND numped = reg.numped
            AND numseq = reg.numseq;

         -- VERIFICAR SE USA CREDITO RCA
         resultado := 'PC_PKG_CONTROLARSALDORCA ';
         vretornocorte :=
            pc_pkg_controlarsaldorca.ccrca_alterar_preco_qt (pmatricula,
                                                             pcodrotina,
                                                             reg.codusur,
                                                             reg.numped,
                                                             pcodprod,
                                                             reg.numseq,
                                                             vnqtpediorig
                                                            );
         resultado := 'PROCESSANDO CORTE ';

         -- ATUALIZAR A TABELA WMS
         UPDATE pcwms
            SET qt = qt - vqtcortereg
          WHERE codprod = pcodprod AND numped = reg.numped;

         -- ATUALIZAR A TABELA DE MOVIMENTACAO PENDENTE DOS ENDERECOS
         UPDATE pcmovendpend
            SET qt = NVL (qt, 0) - vqtcortereg, codmotivo = pcodmotivo,
                qtseparada = NVL (qt, 0) - vqtcortereg,
                numvol =
                   DECODE (tipoos,
                           20, TRUNC (  (NVL (qt, 0) - vqtcortereg)
                                      / reg.qtunitcx
                                     ),
                           numvol
                          )
          WHERE pcmovendpend.numos = pnumos
            AND pcmovendpend.codendereco = reg.codendereco
            AND pcmovendpend.codprod = pcodprod
            AND (   (pcmovendpend.numped = reg.numped AND vtipocorte = 'P')
                 OR (pcmovendpend.numcar = reg.numcar AND vtipocorte = 'C')
                )
            AND ROWID = reg.rowidpcmovendpend;

         -- EXCLUIR OS REGISTROS COM QUANTIDADE ZERO DA TABELA WMS
         DELETE FROM pcwms
               WHERE codprod = pcodprod
                 AND numped = reg.numped
                 AND NVL (qt, 0) = 0;

         -- EXCLUIR OS REGISTROS COM QUANTIDADE ZERO DA TABELA DE ITENS DO PEDIDO
         DELETE      pcpedi
               WHERE codprod = pcodprod
                 AND numped = reg.numped
                 AND NVL (qt, 0) <= 0
                 AND numseq = reg.numseq;

         -- EXCLUIR OS REGISTROS COM QUANTIDADE < QUE ZERO DA TABELA DE ITENS DO PEDIDO
         DELETE      pcpedi
               WHERE numped = reg.numped
                 AND NVL (qt, 0) < 0
                 AND (SELECT COUNT (codprod)
                        FROM pcpedi
                       WHERE numped = reg.numped AND NVL (qt, 0) > 0) <= 0;

         -- EXCLUIR OS REGISTROS COM QUANTIDADE ZERO DA TABELA DE MOVIMENTACAO PENDENTE DOS ENDERECOS
         DELETE FROM pcmovendpend
               WHERE pcmovendpend.numos = pnumos
                 AND pcmovendpend.codendereco = reg.codendereco
                 AND pcmovendpend.codprod = pcodprod
                 AND NVL (pcmovendpend.qt, 0) = 0
                 AND (   (pcmovendpend.numped = reg.numped
                          AND vtipocorte = 'P'
                         )
                      OR (pcmovendpend.numcar = reg.numcar
                          AND vtipocorte = 'C'
                         )
                     );

         --ATUALIZAR DADOS DO CABECALHO DO PEDIDO
         SELECT SUM (NVL (i.qt, 0) * NVL (p.pesobruto, 0)),
                SUM (NVL (i.qt, 0) * NVL (p.volume, 0)),
                SUM (NVL (i.qt, 0) * NVL (i.pvenda, 0)),
                COUNT (DISTINCT i.codprod),
                SUM (NVL (i.qt, 0) * NVL (i.vlcustocont, 0)),
                SUM (NVL (i.qt, 0) * NVL (i.vlcustorep, 0)),
                SUM (NVL (i.qt, 0) * NVL (i.vlcustofin, 0)),
                SUM (NVL (i.qt, 0) * NVL (i.vlcustoreal, 0)),
                SUM (NVL (i.qt, 0) * NVL (i.ptabela, 0))
           INTO vtotpeso,
                vtotvolume,
                vvlatend,
                vqtitens,
                vvlcustocont,
                vvlcustorep,
                vvlcustofin,
                vvlcustoreal,
                vvltabela
           FROM pcpedi i, pcprodut p
          WHERE i.codprod = p.codprod AND numped = reg.numped;

         -- EXCLUIR O PEDIDO CASO TODOS SEUS ITENS TENHAM SIDO DELETADOS
         IF vqtitens = 0
         THEN
            DELETE      pcpedc
                  WHERE numped = reg.numped;
         END IF;

         -- ATUALIZAR OS PEDIDOS COM QUANTIDADE MAIOR QUE ZERO
         IF vqtitens > 0
         THEN
            SELECT COUNT (numped)
              INTO vnforupdate
              FROM pcpedc
             WHERE numped = reg.numped;

            IF vnforupdate > 0
            THEN
               SELECT     numped
                     INTO vnforupdate
                     FROM pcpedc
                    WHERE numped = reg.numped
               FOR UPDATE;
            END IF;

            UPDATE pcpedc
               SET totpeso = vtotpeso,
                   totvolume = vtotvolume,
                   numitens = vqtitens,
                   vlatend = vvlatend,
                   vlcustocont = vvlcustocont,
                   vlcustorep = vvlcustorep,
                   vlcustofin = vvlcustofin,
                   vlcustoreal = vvlcustoreal,
                   vltabela = vvltabela
             WHERE numped = reg.numped;
         END IF;
      END IF;           -- FIM DO TESTE SE O PEDIDO DEVE SER ATUALIZADO OU NAO

      --Alimentar tabela de mensagem
      IF vqtcortereg > 0
      THEN
         INSERT INTO pcmens
                     (codusur, DATA,
                      mens1,
                      mens2,
                      enviado, datacompleta
                     )
              VALUES (reg.codusur, TRUNC (SYSDATE),
                      SUBSTR (('Cliente: ' || reg.codcli || '-' || reg.cliente
                              ),
                              0,
                              60
                             ),
                      SUBSTR (   'Corte de '
                              || (vqtcortereg * -1)
                              || ' und(s) do pedido '
                              || reg.numped
                              || ', Produto: '
                              || pcodprod
                              || '-'
                              || (SELECT descricao
                                    FROM pcprodut
                                   WHERE codprod = pcodprod),
                              0,
                              60
                             ),
                      'N', SYSDATE
                     );
      END IF;

      IF vqtcortereg < 0
      THEN
         INSERT INTO pcmens
                     (codusur, DATA,
                      mens1,
                      mens2,
                      enviado, datacompleta
                     )
              VALUES (reg.codusur, TRUNC (SYSDATE),
                      SUBSTR (('Cliente: ' || reg.codcli || '-' || reg.cliente
                              ),
                              0,
                              60
                             ),
                      SUBSTR (   'Adição de '
                              || (vqtcortereg * -1)
                              || ' und(s) do pedido '
                              || reg.numped
                              || ', Produto: '
                              || pcodprod
                              || '-'
                              || (SELECT descricao
                                    FROM pcprodut
                                   WHERE codprod = pcodprod),
                              0,
                              60
                             ),
                      'N', SYSDATE
                     );
      END IF;

      IF vqtcortetot = 0
      THEN
         EXIT;
      END IF;
   END LOOP;

   --ATUALIZAR DADOS DO CARREGAMENTO NO CASO DE CORTE POR CARREGAMENTO
   IF vnumcar <> 0
   THEN
      SELECT SUM (NVL (i.qt, 0) * NVL (p.pesobruto, 0)),
             SUM (NVL (i.qt, 0) * NVL (p.volume, 0)),
             SUM (NVL (i.qt, 0) * NVL (i.pvenda, 0)),
             COUNT (DISTINCT i.numped) qtped, COUNT (DISTINCT i.codcli),
             COUNT (DISTINCT c.codpraca)
        INTO vtotpeso,
             vtotvolume,
             vvlatend,
             vqtped, vqtcli,
             vqtcid
        FROM pcpedc c, pcpedi i, pcprodut p
       WHERE i.numped = c.numped
         AND i.codprod = p.codprod
         AND c.numcar = vnumcar;

      SELECT COUNT (numcar)
        INTO vnforupdate
        FROM pccarreg
       WHERE numcar = vnumcar;

      IF vnforupdate > 0
      THEN
         SELECT     numcar
               INTO vnforupdate
               FROM pccarreg
              WHERE numcar = vnumcar
         FOR UPDATE;
      END IF;

      UPDATE pccarreg
         SET vltotal = vvlatend,
             totpeso = vtotpeso,
             totvolume = vtotvolume,
             numnotas = vnumnotas,
             nument = vqtcli,
             numcid = vnumcid
       WHERE numcar = vnumcar;
   END IF;

   --recuperando o numero da carga quando a OS for por pedido
   if vnumcar = 0 then
      select max(numcar) into vnumcar from pcpedc where numped = numped;
   end if;

   --Atualizando conferencia por carregamento
   IF vnumcar > 0 THEN
      update pcconferenciawms conf set qt = nvl(
      (
         select sum(qt) from
         (
            select m.qt
               ,(select max(coddistrib) from pcwms where numcar=c.numcar and numtranswms=m.numtranswms and dtcancel is null) as coddistrib
            from pcmovendpend m, pcpedc c
            where m.numped = c.numped
                  and m.dtestorno is null
                  and c.numcar = vnumcar
                  and m.codprod = pcodprod
            union all
            select m.qt
                  ,(select max(coddistrib) from pcwms where numcar=c.numcar and numtranswms=m.numtranswms and dtcancel is null) as coddistrib
            from pcmovendpend m, pcpedc c
            where m.numcar = c.numcar
                  and m.dtestorno is null
                  and nvl(m.numped,0) = 0
                  and m.numcar = vnumcar
                  and m.codprod = pcodprod
          )
          where coalesce(coddistrib,' ') = coalesce(conf.coddistrib,coddistrib,' ')
      ),0)
      where numcar = vnumcar
            and tipoconferencia = 'CC'
            and codprod = pcodprod;
      update pcconferenciawms conf set qtconferida = least(qt,nvl(qtconferida,0))
             where numcar = vnumcar and tipoconferencia = 'CC' and codprod = pcodprod;
   END IF;

   if vpesovariavel = 'S' and vpesopeca>0 then
      update pcmovendpend set qtpecas = ceil(qt/vpesopeca)
      where codprod = pcodprod and numos = pnumos;
   end if;

   if vpesovariavel = 'S' and vpesopeca=0 then
      update pcmovendpend set qtpecas = 0
      where codprod = pcodprod and numos = pnumos;
   end if;

   COMMIT;
   resultado := 'OK';
EXCEPTION
   WHEN falha_no_corte
   THEN
      BEGIN
         resultado := 'FALHA NO CORTE: ' || resultado;
      END;
   WHEN OTHERS
   THEN
      BEGIN
         ROLLBACK;
         resultado := resultado || ' ' || SQLCODE || ' ' || SQLERRM;
      END;
END;

