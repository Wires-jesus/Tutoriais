CREATE OR REPLACE PROCEDURE PRC_GERARPEDIDOITEMCOMST (
   pnumped                    IN       NUMBER
  ,pnumpedst                  OUT      NUMBER
  ,pmsg                       OUT      VARCHAR2
  ,p_num_pedido               IN       NUMBER DEFAULT NULL
)
IS
   /**************************************************************************************
    Proposito: Esta procedure gera pedidos com produtos que tenha ST

                          Historico de Alteracoes
    --------------------------------------------------------------------------------------
    Data        Responsavel     Descricao
    ----------  --------------  ----------------------------------------------------------
    
   *******************************************************************************/
   -- DECLARACAO DE VARIAVEIS
   vicontadorsim                 NUMBER;
   vicontadornao                 NUMBER;
   vntxvenda                     pcconsum.txvenda%TYPE;
   vnnumcar01                    pcconsum.proxnumcar%TYPE;
   vnnumcar                      pcpedc.numcar%TYPE;
   vncodusur                     pcpedc.codusur%TYPE;
   vscodfilial                   pcpedc.codfilial%TYPE;
   vnproxnumped                  pcusuari.proxnumped%TYPE;
   vnnumitens                    pcpedc.numitens%TYPE;
   vnvlcustofin                  pcpedc.vlcustofin%TYPE;
   vnvlverbacmv                  pcpedc.vlverbacmv%TYPE;
   vnvlverbacmvcli               pcpedc.vlverbacmvcli%TYPE;
   vnvlcustoreal                 pcpedc.vlcustoreal%TYPE;
   vnvlcustocont                 pcpedc.vlcustocont%TYPE;
   vnvlcustorep                  pcpedc.vlcustorep%TYPE;
   vnvltabela                    pcpedc.vltabela%TYPE;
   vnvlatend                     pcpedc.vlatend%TYPE;
   vnvltotal                     pcpedc.vltotal%TYPE;
   vntotpeso                     pcpedc.totpeso%TYPE;
   vntotvolume                   pcpedc.totvolume%TYPE;
   vsorigemped                   pcpedc.origemped%TYPE;
   -- vbvalido BOOLEAN;
   vncodemitente                 pcpedc.codemitente%TYPE;
   vbsaldorca                    BOOLEAN;
BEGIN
   pmsg                       := '';

   BEGIN
      SELECT txvenda
        INTO vntxvenda
        FROM pcconsum;
   EXCEPTION
      WHEN OTHERS
      THEN
         pmsg                       :=
               SQLCODE
            || ' - '
            || SQLERRM
            || ' -0- Erro ao buscar parametros do sistema';
         RAISE;
   END;

   -- Verificar se o pedido é Balcão Reserva para gerar nr. de carregamento diferente
   SELECT origemped
         ,numcar
         ,codemitente
     INTO vsorigemped
         ,vnnumcar
         ,vncodemitente
     FROM pcpedc
    WHERE pcpedc.numped = pnumped;

   -- Itens com ST maior que zero
   SELECT COUNT(*)
     INTO vicontadorsim
    FROM (
   SELECT CODPROD,
    ferramentas.VERIFICAR_ISENTOST(pcpedi.CODCLI,pcpedi.CODPROD,pcpedi.CODST) ISENTOST,
     pcpedi.st,
     PCPEDI.BASEICST
     FROM pcpedi
    WHERE pcpedi.numped = pnumped)
    WHERE ((ST > 0)
       OR (ST = 0 AND ISENTOST = 'N'))
       AND (BASEICST > 0)     ;

   -- Itens com ST igual a zero
   SELECT COUNT(*)
   INTO vicontadornao
   FROM (
   SELECT CODPROD,
    ferramentas.VERIFICAR_ISENTOST(pcpedi.CODCLI,pcpedi.CODPROD,pcpedi.CODST) ISENTOST,
     pcpedi.st,
     PCPEDI.BASEICST
     FROM pcpedi
    WHERE pcpedi.numped = pnumped)
   WHERE (ST = 0)
       AND ((ISENTOST = 'S')
       OR (BASEICST = 0 ))   ;

   -- Verificar se vai gerar novo pedido
   IF    (vicontadorsim > 0)
      and (vicontadornao > 0)
   THEN
      BEGIN
         -- Buscar novo numero do pedido para produtos com ST
          SELECT codusur
                ,codfilial
            INTO vncodusur
                ,vscodfilial
            FROM pcpedc
           WHERE numped = pnumped;

          IF NVL(p_num_pedido, 0) <= 0 then
            vnproxnumped := ferramentas.F_PROX_NUMPED(vncodusur);
          else
            vnproxnumped := p_num_pedido;
          end if ;

          -- Tarefa 79698
          IF vsorigemped = 'R'
          THEN
             SELECT     NVL (pcconsum.proxnumcar, 1)
                   INTO vnnumcar01
                   FROM pcconsum
                  WHERE ROWNUM = 1
             FOR UPDATE;

             UPDATE pcconsum
                SET proxnumcar = NVL (proxnumcar, 1) + 1
              WHERE ROWNUM = 1;
          END IF;


        --COMMIT;
         pnumpedst                := vnproxnumped;
      EXCEPTION
         WHEN OTHERS
         THEN
            pmsg                       :=
                  SQLCODE
               || ' - '
               || SQLERRM
               || ' -1- Erro ao buscar numeracao de pedido';
            ROLLBACK;
      END;

      BEGIN
         -- Gerando pedido com ST
         IF (vnproxnumped > 0)
         THEN
            -- gerando itens para o novo pedido quando pcpedi.st > 0
            INSERT INTO pcpedi
                        (codprod
                        ,qt
                        ,pvenda
                        ,numped
                        ,DATA
                        ,codcli
                        ,codusur
                        ,numcar
                        ,posicao
                        ,st
                        ,vlcustoreal
                        ,vlcustofin
                        ,ptabela
                        ,percom
                        ,perdesc
                        ,qtfalta
                        ,numseq
                        ,vldesccustocmv
                        ,vlcustocont
                        ,vlcustorep
                        ,vldescsuframa
                        ,codst
                        ,vldescfin
                        ,pvendabase
                        ,vlipi
                        ,percipi
                        ,poriginal
                        ,iva
                        ,pauta
                        ,aliqicms1
                        ,aliqicms2
                        ,stclientegnre
                        ,percbasered
                        ,percbaseredst
                        ,percbaseredstfonte
                        ,perfretecmv
                        ,custofinest
                        ,perciss
                        ,vliss
                        ,complemento
                        ,pbaserca
                        ,vlverbacmv
                        ,numverbarebcmv
                        ,brinde
                        ,baseicst
                        ,qtcx
                        ,qtpecas
                        ,letracomiss
                        ,codauxiliar
                        ,txvenda
                        ,codicmtab
                        ,perdesccusto
                        ,codfilialretira
                        ,eancodprod
                        ,vldescicmisencao
                        ,perdescisentoicms
                        ,vlverbacmvcli
                        ,pvenda1
                        ,tipoentrega
                        ,geragnre_cnpjcliente
                        ,percdifaliquotas
                        ,basedifaliquotas
                        ,vldifaliquotas
                        ,perdescpolitica
                        ,pvendaanterior
                        ,proddescricaocontrato
                        ,politicaprioritaria
                        ,truncaritem
                        ,qtunitemb
                        ,percom2
                        ,percom3
                        ,percom4
                        ,precofvbruto
                        ,rotinalanc
                        ,qtunitcx
                        ,percdescpis
                        ,vldescreducaopis
                        ,percdesccofins
                        ,vldescreducaocofins
                        ,coddesconto
                        ,vldescpissuframa
                        ,vlredpvendasimplesna
                        ,vlredcmvsimplesnac
                        ,ALIQICMSFECP
                        ,VLBASEFCPST
                        ,VLFECP
                        ,UTILIZOUMOTORCALCULO
                        ,NUMPEDCLI
                        )
               SELECT pcpedi.codprod
                     ,pcpedi.qt
                     ,pcpedi.pvenda
                     ,vnproxnumped
                     ,pcpedi.DATA
                     ,pcpedi.codcli
                     ,pcpedi.codusur
                     ,DECODE (vsorigemped
                             ,'R', vnnumcar01
                             ,pcpedi.numcar
                             )
                     ,pcpedi.posicao
                     ,pcpedi.st
                     ,pcpedi.vlcustoreal
                     ,pcpedi.vlcustofin
                     ,pcpedi.ptabela
                     ,pcpedi.percom
                     ,pcpedi.perdesc
                     ,pcpedi.qtfalta
                     ,pcpedi.numseq
                     ,pcpedi.vldesccustocmv
                     ,pcpedi.vlcustocont
                     ,pcpedi.vlcustorep
                     ,pcpedi.vldescsuframa
                     ,pcpedi.codst
                     ,pcpedi.vldescfin
                     ,pcpedi.pvendabase
                     ,pcpedi.vlipi
                     ,pcpedi.percipi
                     ,pcpedi.poriginal
                     ,pcpedi.iva
                     ,pcpedi.pauta
                     ,pcpedi.aliqicms1
                     ,pcpedi.aliqicms2
                     ,pcpedi.stclientegnre
                     ,pcpedi.percbasered
                     ,pcpedi.percbaseredst
                     ,pcpedi.percbaseredstfonte
                     ,pcpedi.perfretecmv
                     ,pcpedi.custofinest
                     ,pcpedi.perciss
                     ,pcpedi.vliss
                     ,pcpedi.complemento
                     ,pcpedi.pbaserca
                     ,pcpedi.vlverbacmv
                     ,pcpedi.numverbarebcmv
                     ,pcpedi.brinde
                     ,pcpedi.baseicst
                     ,pcpedi.qtcx
                     ,pcpedi.qtpecas
                     ,pcpedi.letracomiss
                     ,pcpedi.codauxiliar
                     ,pcpedi.txvenda
                     ,pcpedi.codicmtab
                     ,pcpedi.perdesccusto
                     ,pcpedi.codfilialretira
                     ,pcpedi.eancodprod
                     ,pcpedi.vldescicmisencao
                     ,pcpedi.perdescisentoicms
                     ,pcpedi.vlverbacmvcli
                     ,pcpedi.pvenda1
                     ,pcpedi.tipoentrega
                     ,pcpedi.geragnre_cnpjcliente
                     ,pcpedi.percdifaliquotas
                     ,pcpedi.basedifaliquotas
                     ,pcpedi.vldifaliquotas
                     ,pcpedi.perdescpolitica
                     ,pcpedi.pvendaanterior
                     ,pcpedi.proddescricaocontrato
                     ,pcpedi.politicaprioritaria
                     ,pcpedi.truncaritem
                     ,pcpedi.qtunitemb
                     ,pcpedi.percom2
                     ,pcpedi.percom3
                     ,pcpedi.percom4
                     ,pcpedi.precofvbruto
                     ,pcpedi.rotinalanc
                     ,pcpedi.qtunitcx
                     ,pcpedi.percdescpis
                     ,pcpedi.vldescreducaopis
                     ,pcpedi.percdesccofins
                     ,pcpedi.vldescreducaocofins
                     ,pcpedi.coddesconto
                     ,pcpedi.vldescpissuframa
                     ,pcpedi.vlredpvendasimplesna
                     ,pcpedi.vlredcmvsimplesnac
                     ,pcpedi.ALIQICMSFECP
                     ,pcpedi.VLBASEFCPST
                     ,pcpedi.VLFECP
                     ,pcpedi.UTILIZOUMOTORCALCULO
                     ,pcpedi.NUMPEDCLI
                 FROM pcpedi
                WHERE (PCPEDI.NUMPED,PCPEDI.CODPROD,PCPEDI.NUMSEQ) IN (
                       SELECT  NUMPED,
                         CODPROD,
                         NUMSEQ
                        FROM (
                       SELECT
                         NUMPED,
                         CODPROD,
                         NUMSEQ,
                        ferramentas.VERIFICAR_ISENTOST(pcpedi.CODCLI,pcpedi.CODPROD,pcpedi.CODST) ISENTOST,
                         pcpedi.st,
                         PCPEDI.BASEICST
                         FROM pcpedi
                        WHERE pcpedi.numped = pnumped)
                        WHERE ((ST > 0)
                           OR (ST = 0 AND ISENTOST = 'N'))
                           AND (BASEICST > 0)) ;



            UPDATE pcpedicesta
               SET numped = vnproxnumped
             WHERE (numped, codprod, numseq) IN (
                      SELECT pnumped                          -- pedido anterior
                            ,pcpedi.codprod
                            ,pcpedi.numseq
                        FROM pcpedi, pcprodut
                       WHERE pcpedi.numped = vnproxnumped
                         -- novo pedido que acabou de se criado
                         AND pcpedi.codprod = pcprodut.codprod);

            -- Correção da atualiza do PCORIGEMPRECO
            UPDATE pcorigempreco
               SET numped = vnproxnumped
             WHERE (numped, codprod, numseq) IN (
                      SELECT pnumped                          -- pedido anterior
                            ,pcpedi.codprod
                            ,pcpedi.numseq
                        FROM pcpedi, pcprodut
                       WHERE pcpedi.numped = vnproxnumped
                         -- novo pedido que acabou de se criado
                         AND pcpedi.codprod = pcprodut.codprod );

            -- Fim Pablo (11/09/2008)

            /*        Alteração : Comentado código abaixo
                    Motivo : Desvazendo o  vlcustofin com rebaixa feito na 316
                    Tarefa : 173078
                    Cliente : Irmãos Avelino
                    Cenário : Criar dois itens com rebaixa de CMV e com restrição de transporte


            -- Atualizando CVM para o novo pedido quando pcprodut.restricaotransp = 'S'
            UPDATE pcpedi
               SET vlcustofin =
                      (SELECT NVL (pcest.custofin, 0)
                         FROM pcest
                        WHERE pcest.codprod = pcpedi.codprod
                          AND pcest.codfilial = vscodfilial)
                  ,vlcustoreal =
                      (SELECT NVL (pcest.custoreal, 0)
                         FROM pcest
                        WHERE pcest.codprod = pcpedi.codprod
                          AND pcest.codfilial = vscodfilial)
             WHERE numped = vnproxnumped
               AND EXISTS (SELECT codst
                             FROM pctribut
                            WHERE codst = pcpedi.codst);

            UPDATE pcpedi
               SET vlcustofin =
                      (SELECT   NVL (pcpedi.vlcustofin, 0)
                              - (  NVL (pcpedi.vlcustofin, 0)
                                 * (NVL (perdesccusto, 0) / 100)
                                )
                         FROM pctribut
                        WHERE pctribut.codst = pcpedi.codst)
                  ,vlcustoreal =
                      (SELECT   NVL (pcpedi.vlcustoreal, 0)
                              - (  NVL (pcpedi.vlcustoreal, 0)
                                 * (NVL (perdesccusto, 0) / 100)
                                )
                         FROM pctribut
                        WHERE pctribut.codst = pcpedi.codst)
             WHERE numped = vnproxnumped
               AND EXISTS (SELECT codst
                             FROM pctribut
                            WHERE codst = pcpedi.codst);

            UPDATE pcpedi
               SET vlcustofin =
                      (SELECT   pcpedi.vlcustofin
                              + NVL (pcpedi.st, 0)
                              + NVL (pcpedi.vlipi, 0)
                              + (  NVL (pcpedi.pvenda, 0)
                                 * (NVL (vntxvenda, 0) / 100)
                                )
                              + (  NVL (pcpedi.pvenda, 0)
                                 * (NVL (pcpedi.percom, 0) / 100)
                                )
                              + (  (  NVL (pcpedi.pvenda, 0)
                                    - NVL (pcpedi.st, 0)
                                    - NVL (pcpedi.vlipi, 0)
                                   )
                                 * (NVL (pctribut.codicmtab, 0) / 100)
                                )
                         FROM pctribut
                        WHERE codst = pcpedi.codst)
                  ,vlcustoreal =
                      (SELECT   pcpedi.vlcustoreal
                              + NVL (pcpedi.st, 0)
                              + NVL (pcpedi.vlipi, 0)
                              + (  NVL (pcpedi.pvenda, 0)
                                 * (NVL (vntxvenda, 0) / 100)
                                )
                              + (  NVL (pcpedi.pvenda, 0)
                                 * (NVL (pcpedi.percom, 0) / 100)
                                )
                              + (  (  NVL (pcpedi.pvenda, 0)
                                    - NVL (pcpedi.st, 0)
                                    - NVL (pcpedi.vlipi, 0)
                                   )
                                 * (NVL (pctribut.codicmtab, 0) / 100)
                                )
                         FROM pctribut
                        WHERE codst = pcpedi.codst)
             WHERE numped = vnproxnumped
               AND EXISTS (SELECT codst
                             FROM pctribut
                            WHERE codst = pcpedi.codst);

            -- FIM RECALCULO DO CMV
            */

            -- Totalizando pedido quando pcpedi.st  > 0
            SELECT COUNT (*) qt
                  ,SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.vlcustofin, 0))  vlcustofin
                  ,SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.vlcustoreal, 0)) vlcustoreal
                  ,SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.vlcustocont, 0)) vlcustocont
                  ,SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.vlcustorep, 0))  vlcustorep
                  ,SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.ptabela, 0))     vltabela
                  ,SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.pvenda, 0))      vlatend
                  ,SUM (  (NVL (pcpedi.qt, 0) + NVL (pcpedi.qtfalta, 0))
                        * NVL (pcpedi.pvenda, 0)) vltotal
                  ,SUM (NVL (pcpedi.qt, 0) * NVL (pcprodut.pesobruto, 0)) totpeso
                  ,SUM (NVL (pcpedi.qt, 0) * NVL (pcprodut.volume, 0))    totvolume
                  ,SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.vlverbacmv, 0))
                                                                      vlverbacmv
                  ,SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.vlverbacmvcli, 0))
                                                                      vlverbacmvcli
              INTO vnnumitens
                  ,vnvlcustofin
                  ,vnvlcustoreal
                  ,vnvlcustocont
                  ,vnvlcustorep
                  ,vnvltabela
                  ,vnvlatend
                  ,vnvltotal
                  ,vntotpeso
                  ,vntotvolume
                  ,vnvlverbacmv
                  ,vnvlverbacmvcli
              FROM pcpedi, pcprodut
             WHERE pcpedi.codprod = pcprodut.codprod
               AND pcpedi.numped = vnproxnumped
               AND pcpedi.qt > 0;

            INSERT INTO pcpedc
                        (numped
                        ,DATA
                        ,codusur
                        ,codcli
                        ,numitens
                        ,vlatend
                        ,codpraca
                        ,posicao
                        ,numcar
                        ,codsupervisor
                        ,codfilial
                        ,vltotal
                        ,vltabela
                        ,vlcustoreal
                        ,vlcustofin
                        ,totpeso
                        ,totvolume
                        ,codemitente
                        ,operacao
                        ,tipovenda
                        ,obs
                        ,codcob
                        ,hora
                        ,minuto
                        ,codplpag
                        ,numpedcli
                        ,percvenda
                        ,perdesc
                        ,vldesconto
                        ,vlfrete
                        ,vloutrasdesp
                        ,obs1
                        ,obs2
                        ,condvenda
                        ,dtentrega
                        ,numpedrca
                        ,fretedespacho
                        ,freteredespacho
                        ,codfornecfrete
                        ,codfornecredespacho
                        ,tipocarga
                        ,prazo1
                        ,prazo2
                        ,prazo3
                        ,prazo4
                        ,prazo5
                        ,prazo6
                        ,prazo7
                        ,prazo8
                        ,prazo9
                        ,prazo10
                        ,prazo11
                        ,prazo12
                        ,prazomedio
                        ,obsentrega1
                        ,obsentrega2
                        ,obsentrega3
                        ,tipoembalagem
                        ,codepto
                        ,campanha
                        ,coddistrib
                        ,vlcustocont
                        ,vlcustorep
                        ,numnotamanif
                        ,seriemanif
                        ,origemped
                        ,especiemanif
                        ,numpedentfut
                        ,codfilialnf
                        ,numcarmanif
                        ,numorca
                        ,codcontrato
                        ,datapedcli
                        ,numpedbnf
                        ,broker
                        ,codestabelecimento
                        ,numtabela
                        ,motivoposicao
                        ,dtagendaentrega
                        ,tipooper
                        ,codmotbloqueio
                        ,serieecf
                        ,numcupom
                        ,codclirecebedor
                        ,conciliaimportacao
                        ,numregiao
                        ,numnota
                        ,perdescfin
                        ,restricaotransp
                        ,geracp
                        ,usaintegracaowms
                        ,vendaassistida
                        ,codmotivo
                        ,LOG
                        ,dtcalcfrete
                        ,codfunccalcfrete
                        ,eancobranca
                        ,eanentrega
                        ,usacfopvendanatv10
                        ,tipoprioridadeentrega
                        ,codusur2
                        ,codusur3
                        ,codusur4
                        ,codclinf
                        ,numpedtv1
                        ,usadebcredrca
                        ,brinde
                        ,bonificaltdebcredrca
                        ,trocaaltdebcredrca
                        ,brokeraltdebcredrca
                        ,crmaltdebcredrca
                        ,tipomovccrca
                        ,usacredrca
                        ,gerardadosnfpaulista
                        ,usasaldocontacorrentedescfin
                        ,valordescfin
                        ,codvisita
                        ,codatendimento
                        ,vendatriangular
                        ,vlentrada
                        ,ufdesembaraco
                        ,localdesembaraco
                        ,custobonificacao
                        ,codfornecbonific
                        ,codbnf
                        ,tipodocumento
                        ,cfopbnfdegusta
                        ,contaordem
                        ,dtaberturapedpalm
                        ,vlverbacmv
                        ,vlverbacmvcli
                        ,descintermediador
                        ,cnpjintermediador)
               SELECT vnproxnumped
                     ,DATA
                     ,codusur
                     ,codcli
                     ,vnnumitens
                     ,vnvlatend
                     ,codpraca
                     ,posicao
                     ,DECODE (vsorigemped
                             ,'R', vnnumcar01
                             ,numcar
                             )
                     ,codsupervisor
                     ,codfilial
                     ,vnvltotal
                     ,vnvltabela
                     ,vnvlcustoreal
                     ,vnvlcustofin
                     ,vntotpeso
                     ,vntotvolume
                     ,codemitente
                     ,operacao
                     ,tipovenda
                     ,obs
                     ,codcob
                     ,hora
                     ,minuto
                     ,codplpag
                     ,numpedcli
                     ,percvenda
                     ,perdesc
                     ,vldesconto
                     ,vlfrete
                     ,vloutrasdesp
                     ,obs1
                     ,obs2
                     ,condvenda
                     ,dtentrega
                     ,numpedrca
                     ,fretedespacho
                     ,freteredespacho
                     ,codfornecfrete
                     ,codfornecredespacho
                     ,tipocarga
                     ,prazo1
                     ,prazo2
                     ,prazo3
                     ,prazo4
                     ,prazo5
                     ,prazo6
                     ,prazo7
                     ,prazo8
                     ,prazo9
                     ,prazo10
                     ,prazo11
                     ,prazo12
                     ,prazomedio
                     ,obsentrega1
                     ,obsentrega2
                     ,obsentrega3
                     ,tipoembalagem
                     ,codepto
                     ,campanha
                     ,coddistrib
                     ,vnvlcustocont
                     ,vnvlcustorep
                     ,numnotamanif
                     ,seriemanif
                     ,origemped
                     ,especiemanif
                     ,numpedentfut
                     ,codfilialnf
                     ,numcarmanif
                     ,numorca
                     ,codcontrato
                     ,datapedcli
                     ,numpedbnf
                     ,broker
                     ,codestabelecimento
                     ,numtabela
                     ,motivoposicao
                     ,dtagendaentrega
                     ,tipooper
                     ,codmotbloqueio
                     ,serieecf
                     ,numcupom
                     ,codclirecebedor
                     ,conciliaimportacao
                     ,numregiao
                     ,numnota
                     ,perdescfin
                     ,restricaotransp
                     ,geracp
                     ,usaintegracaowms
                     ,vendaassistida
                     ,codmotivo
                     ,LOG
                     ,dtcalcfrete
                     ,codfunccalcfrete
                     ,eancobranca
                     ,eanentrega
                     ,usacfopvendanatv10
                     ,tipoprioridadeentrega
                     ,codusur2
                     ,codusur3
                     ,codusur4
                     ,codclinf
                     ,numpedtv1
                     ,usadebcredrca
                     ,brinde
                     ,bonificaltdebcredrca
                     ,trocaaltdebcredrca
                     ,brokeraltdebcredrca
                     ,crmaltdebcredrca
                     ,tipomovccrca
                     ,usacredrca
                     ,gerardadosnfpaulista
                     ,usasaldocontacorrentedescfin
                     ,valordescfin
                     ,codvisita
                     ,codatendimento
                     ,vendatriangular
                     ,vlentrada
                     ,ufdesembaraco
                     ,localdesembaraco
                     ,custobonificacao
                     ,codfornecbonific
                     ,codbnf
                     ,tipodocumento
                     ,cfopbnfdegusta
                     ,contaordem
                     ,dtaberturapedpalm
                     ,vnvlverbacmv
                     ,vnvlverbacmvcli
                     ,descintermediador
                     ,cnpjintermediador
                 FROM pcpedc
                WHERE pcpedc.numped = pnumped;

            --tarefa 85855
            FOR reg_itens IN (SELECT pcpedi.codprod
                                    ,pcpedi.codusur
                                    ,pcpedi.numseq
                                FROM pcpedi, pcprodut
                               WHERE (PCPEDI.NUMPED,PCPEDI.CODPROD,PCPEDI.NUMSEQ) IN (
                                           SELECT  NUMPED,
                                             CODPROD,
                                             NUMSEQ
                                            FROM (
                                           SELECT
                                             NUMPED,
                                             CODPROD,
                                             NUMSEQ,
                                            ferramentas.VERIFICAR_ISENTOST(pcpedi.CODCLI,pcpedi.CODPROD,pcpedi.CODST) ISENTOST,
                                             pcpedi.st,
                                             PCPEDI.BASEICST
                                             FROM pcpedi
                                            WHERE pcpedi.numped = pnumped)
                                            WHERE ((ST > 0)
                                               OR (ST = 0 AND ISENTOST = 'N'))
                                               AND (BASEICST > 0))
                                   AND pcpedi.codprod = pcprodut.codprod
                                 )
            LOOP
               vbsaldorca                 :=
                  pc_pkg_controlarsaldorca.ccrca_incluir_item_pedido
                                                            (vncodemitente
                                                            ,300
                                                            ,reg_itens.codusur
                                                            ,vnproxnumped
                                                            ,reg_itens.codprod
                                                            ,reg_itens.numseq
                                                            );
            END LOOP;

            IF vsorigemped = 'R'
            THEN
               INSERT INTO pccarreg
                           (numcar
                           ,dtsaida
                           ,totpeso
                           ,totvolume
                           ,vltotal
                           ,destino
                           ,datamon
                           ,codveiculo
                           ,codfuncmon
                           ,dtfecha
                           ,horamon
                           ,minutomon
                           )
                  SELECT vnnumcar01
                        ,dtsaida
                        ,vntotpeso
                        ,vntotvolume
                        ,vnvltotal
                        ,destino
                        ,datamon
                        ,codveiculo
                        ,codfuncmon
                        ,dtfecha
                        ,horamon
                        ,minutomon
                    FROM pccarreg
                   WHERE numcar = vnnumcar;
            END IF;

            -- Tarefa 79111
            INSERT INTO pcvendaconsum
                        (numped
                        ,cliente
                        ,cgcent
                        ,enderent
                        ,bairroent
                        ,telent
                        ,municent
                        ,estent
                        ,cepent
                        ,ieent
                        )
               SELECT vnproxnumped
                     ,cliente
                     ,cgcent
                     ,enderent
                     ,bairroent
                     ,telent
                     ,municent
                     ,estent
                     ,cepent
                     ,ieent
                 FROM pcvendaconsum
                WHERE numped = pnumped;

            -- Fim tarefa 79111

            --tarefa 85855
            FOR reg IN (SELECT pcpedi.codprod
                              ,pcpedi.codusur
                              ,pcpedi.numseq
                              ,pcpedi.qt
                          FROM pcpedi, pcprodut
                        WHERE (PCPEDI.NUMPED,PCPEDI.CODPROD,PCPEDI.NUMSEQ) IN (
                           SELECT  NUMPED,
                             CODPROD,
                             NUMSEQ
                            FROM (
                           SELECT
                             NUMPED,
                             CODPROD,
                             NUMSEQ,
                            ferramentas.VERIFICAR_ISENTOST(pcpedi.CODCLI,pcpedi.CODPROD,pcpedi.CODST) ISENTOST,
                             pcpedi.st,
                             PCPEDI.BASEICST
                             FROM pcpedi
                            WHERE pcpedi.numped = pnumped)
                            WHERE ((ST > 0)
                               OR (ST = 0 AND ISENTOST = 'N'))
                               AND (BASEICST > 0)  )
                           AND pcprodut.codprod = pcpedi.codprod)
            LOOP
               -- Exclusao dos Itens quando pcprodut.restricaotransp  = 'S'
               vbsaldorca                 :=
                  pc_pkg_controlarsaldorca.ccrca_excluir_item_pedido
                                                                (vncodemitente
                                                                ,300
                                                                ,reg.codusur
                                                                ,pnumped
                                                                ,reg.codprod
                                                                ,reg.numseq
                                                                ,reg.qt
                                                                );

               DELETE FROM pcpedi
               WHERE       numped = pnumped
                       AND codprod = reg.codprod
                       AND numseq = reg.numseq;
            END LOOP;
         END IF;                -- IF (vicontadorsim > 0) AND (vnproxnumped > 0)

         -- Totalizando o pedido original após a exclusão dos itens
         SELECT COUNT (*) qt
               ,SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.vlcustofin, 0))
                                                                     vlcustofin
               ,SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.vlcustoreal, 0))
                                                                    vlcustoreal
               ,SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.vlcustocont, 0))
                                                                    vlcustocont
               ,SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.vlcustorep, 0))
                                                                     vlcustorep
               ,SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.ptabela, 0)) vltabela
               ,SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.pvenda, 0)) vlatend
               ,SUM (  (NVL (pcpedi.qt, 0) + NVL (pcpedi.qtfalta, 0))
                     * NVL (pcpedi.pvenda, 0)) vltotal
               ,SUM (NVL (pcpedi.qt, 0) * NVL (pcprodut.pesobruto, 0)) totpeso
               ,SUM (NVL (pcpedi.qt, 0) * NVL (pcprodut.volume, 0)) totvolume
               ,SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.vlverbacmv, 0))vlverbacmv
               ,SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.vlverbacmvcli, 0))vlverbacmvcli
           INTO vnnumitens
               ,vnvlcustofin
               ,vnvlcustoreal
               ,vnvlcustocont
               ,vnvlcustorep
               ,vnvltabela
               ,vnvlatend
               ,vnvltotal
               ,vntotpeso
               ,vntotvolume
               ,vnvlverbacmv
               ,vnvlverbacmvcli
           FROM pcpedi, pcprodut
          WHERE pcpedi.codprod = pcprodut.codprod
            AND pcpedi.numped = pnumped
            AND pcpedi.qt > 0;

         UPDATE pcpedc
            SET numitens = vnnumitens
               ,vlcustofin = vnvlcustofin
               ,vlcustoreal = vnvlcustoreal
               ,vlcustocont = vnvlcustocont
               ,vlcustorep = vnvlcustorep
               ,vltabela = vnvltabela
               ,vlatend = vnvlatend
               ,vltotal = vnvltotal
               ,totpeso = vntotpeso
               ,totvolume = vntotvolume
               ,vlverbacmv =  vnvlverbacmv
               ,vlverbacmvcli = vnvlverbacmvcli
          WHERE numped = pnumped;

         IF vsorigemped = 'R'
         THEN
            UPDATE pccarreg
               SET totpeso = vntotpeso
                  ,totvolume = vntotvolume
                  ,vltotal = vnvltotal
             WHERE numcar = vnnumcar;
         END IF;

         pnumpedst                := vnproxnumped;

         COMMIT;
         pmsg                       :=
               'Atenção! '
            || CHR (13)
            || CHR (13)
            || 'Pedido '
            || CHR (13)
            || TO_CHAR (vnproxnumped)
            || CHR (13)
            || CHR (13)
            || 'com item que possui ST gerado com sucesso.';
      EXCEPTION
         WHEN OTHERS
         THEN
            pmsg                       :=
                  SQLCODE
               || ' - '
               || SQLERRM
               || ' -2- Erro ao gerar pedido com ST';
            RAISE;
      END;
   END IF;                  --   (vicontadorsim > 0)   and (vicontadornao > 0)


EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      pmsg                       :=
            SQLCODE
         || ' - '
         || SQLERRM
         || ' ERRO NA GERACAO DE PEDIDO COM ST';
END PRC_GERARPEDIDOITEMCOMST;
/
