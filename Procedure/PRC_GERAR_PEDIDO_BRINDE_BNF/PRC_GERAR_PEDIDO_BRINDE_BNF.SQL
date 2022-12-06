CREATE OR REPLACE PROCEDURE PRC_GERAR_PEDIDO_BRINDE_BNF(pnumped     IN NUMBER,
                                                        pnumpedrest OUT NUMBER,
                                                        pmsg        OUT VARCHAR2,
                                                        pcodbnf     IN NUMBER DEFAULT 0) IS
  /*******************************************************************************
   Proposito: Gerar um novo pedido Bonificação apartir dos brindes do pedido
                         Historico de Alteracoes
   Rotina: Pacote
   Utilizada por: PCSIS316
   Versão: 21
   -------------------------------------------------------------------------------
   Data        Tarefa   Responsavel     Descricao
   ----------  -------  --------------  ---------------------------------------------------
   08/09/2006  31337    Pablo           O novo pedido com os Brindes será TV5 com PCPEDC.CODCOB = 'BNF'
   06/02/2007  38771    Pablo           Para pedidos origem TV2 e TV3 será gerando um pedido
                                        TV6
   08/08/2008  66388    Aracelia        Alteração para ao gerar o novo pedido como brinde, o mesmo não herdar
                                        o plano de pagto do pedido original e sim buscar o primeiro encontrado do pcplpag.tipoprazo = 'B'
   20/03/2009  80289    Pablo           Caso o pedido seja Balcão Reserva será gerado nr. de carregamento para o novo pedido
   06/07/2009  73279    Rogério         Projeto 71133 - Reformulação Controle Saldo RCA
   12/08/2009           Sabrina         Correcao programa estava gerando tv6 para original tipo 2
                                        programa nao estava gravando campo usaintergracaowms
   15/01/2010           Pablo           Alteração para replicar os dados de PCVendaConsum do pedido original para o novo pediod
   25/02/2010  102210   Pablo           Correção da gravação do PVENDA e PTABELA do novo pedido gerado,
                                        em correção a tarefa 100174
   04/03/2010  102647   Pablo           Alteração para passar a gravar PCPEDC.NumRegiao
   18/03/2010  100601   Pablo           Alteração para passar a gravar PCPedi.usadebcredrcabrind
   29/07/2010  112183   Pablo           Alteração para gerar o PCcarreg ao utilizar PCConsum.ProxNumCar
   16/08/2010  113603   Pablo           Alteração para passar a gravar os campos: PCPEDI.CodigoBrinde e PCPEDI.Brinde
   09/09/2010  115385 & 115155 Thiago   Alteração para passar a gravar os campos : PCPEDC.CODMOTIVO E PCPEDC.CODFORNECREDESPACHO
   06/10/2010  117470   Thiago Melo     Alterada procedure para gravação do campo pcpedi.pbonific conforme solicitado.
   14/10/2010  118042   Thiago Melo     Alterada procedure para gravação do campo pcpedi.baseicst conforme solicitado.
   17/11/2010  120258   Thiago Melo     Alterada procedure para gravação do campo pcpedi.codauxiliar
   25/01/2011  125555   Pablo           Passou a replicar o campo PCPEDI.CodFilialRetira
   01/02/2011  123087   Pablo           Alteração para passar a validar o novo parâmetro PCParamFilial.Nome = GERARTV5SEMPRECOMONF
                        caso o mesmo esteja habilitado o tipo de documento gravado será Nota Fiscal (PCPedC.TipoDocumento = 'N')
   05/08/2011  138506   Thiago Melo     Ajustado procedimento para geração do pedido tv5 ficar gravado no campo pcpedc.numpedtv1
                                        o pedido de origem conforme solicitação.
   28/10/2011  147991   Thiago Melo     Alterado procedimento para não gerar itens duplicados quando o parâmetro 1526 estiver habilitado
   08/03/2012  158130   Fabrício Borges Alterado o insert do pedido (Brinde) pra gravar a informação PCPEDI.QTUnitEmb, com base no cadastro do produto
   23/03/2012  157057   Thiago Melo     Incluído a gravação do campo rotinalancbrinde.
   09/04/2012  157057   Thiago Melo     Erros homologação Fernandes.
   08/05/2013  197395   Thiago Melo     Incluído a opção de gravação do campo
   24/05/2013  199596   Thiago Melo     Ajustado a gravação da posição dos itens de acordo com a posição do pedido.
   16/10/2013  213658   Rafael Braga    Tratamento para geração de brindes quando o cliente tem venda por embalagem e o produto não tem codauxiliar na PCPRODUT.
   ******************************************************************************************************************************************************************
   08/05/2014  2600.050062.2014   Rafael Braga    Tratamento para quando não houver preço na PCTABPR.
   05/06/2014  0                  Rodrigo Santos  Alterada a procedure para receber o código do tipo de bonificação (3329).
   15/09/2014  1264.096706.2014   Rafael Braga    Ajuste para gerar número de carregamento novo caso seja venda balcão reserva do callcenter.
   23/09/2014  650.100812.2014    Rafael Braga    Comentado trecho que aplica os preços de venda conforme a 201.
   29/08/2016  2550.107673.2016   Rafael Braga    Ajustado busca de numeração de pedido para evitar deadlock
  *******************************************************************************/

  /* DECLARACAO DE VARIAVEIS */
  VDQTDE_EXCLUSAO        NUMBER(20, 6);
  VDCODPROD_EXCLUSAO     NUMBER(6);
  vsusachavetriplapcpedi pcconsum.usachavetriplapcpedi%TYPE;
  vicontadorsim          NUMBER;
  vicontadornao          NUMBER;
  vicontplpag            NUMBER;
  vbvalido               BOOLEAN;
  vsmensagen             VARCHAR2(100);
  -- Tabela PCCONSUM
  vntxvenda              pcconsum.txvenda%TYPE;
  vsbonificaltdebcredrca pcconsum.bonificaltdebcredrca%TYPE;
  vsTipoContaCorrente    pcpedc.tipocontacorrente%type;
  vsusacredrca           pcconsum.usacredrca%TYPE;
  vstrocaaltdebcredrca   pcconsum.trocaaltdebcredrca%TYPE;
  vsbrokeraltdebcredrca  pcconsum.brokeraltdebcredrca%TYPE;
  vscrmaltdebcredrca     pcconsum.crmaltdebcredrca%TYPE;
  vstipomovccrca         pcconsum.tipomovccrca%TYPE;
  -- Tabela PCCarreg
  vddtsaida_carreg    pccarreg.dtsaida%TYPE;
  vsdestino_carreg    pccarreg.destino%TYPE;
  vddatamon_carreg    pccarreg.datamon%TYPE;
  vncodveiculo_carreg pccarreg.codveiculo%TYPE;
  vncodfuncmon_carreg pccarreg.codfuncmon%TYPE;
  vddtfecha_carreg    pccarreg.dtfecha%TYPE;
  vnhoramon_carreg    pccarreg.horamon%TYPE;
  vnminutomon_carreg  pccarreg.minutomon%TYPE;
  -- Tabela PCPEDC
  vncodusur     pcpedc.codusur%TYPE;
  vscodfilial   pcpedc.codfilial%TYPE;
  vnnumitens    pcpedc.numitens%TYPE;
  vnvlcustofin  pcpedc.vlcustofin%TYPE;
  vnvlcustoreal pcpedc.vlcustoreal%TYPE;
  vnvlcustocont pcpedc.vlcustocont%TYPE;
  vnvlcustorep  pcpedc.vlcustorep%TYPE;
  vnvltabela    pcpedc.vltabela%TYPE;
  vnvlatend     pcpedc.vlatend%TYPE;
  vnvltotal     pcpedc.vltotal%TYPE;
  vntotpeso     pcpedc.totpeso%TYPE;
  vntotvolume   pcpedc.totvolume%TYPE;
  vstipooper    pcpedc.tipooper%TYPE;
  vsusanovonumcar      varchar2(1);
  vsposicao            pcpedc.posicao%TYPE;
  vncodemitente        pcpedc.codemitente%TYPE;
  vncondvenda          pcpedc.condvenda%TYPE;
  vnpercvenda          pcpedc.percvenda%TYPE;
  vsorigemped          pcpedc.origemped%TYPE;
  vnnumcar             pcpedc.numcar%TYPE;
  vnnumcarorigem       pcpedc.numcar%TYPE;
  vnnumregiao          pcpedc.numregiao%TYPE;
  vstipodocumento_pedc pcpedc.tipodocumento%TYPE;
  -- Tabela PCUSUARI
  --vnvlcorrenteant pcusuari.vlcorrente%TYPE;
  vnproxnumped    pcusuari.proxnumped%TYPE;
  vsusadebcredrca pcusuari.usadebcredrca%TYPE;
  -- Tabela PLPAG
  vncodplpag    pcplpag.codplpag%TYPE;
  vnnumpr_plpag pcplpag.numpr%TYPE;
  -- Tabela PcParamFilial
  vsvalor_paramfilial pcparamfilial.valor%TYPE;
  error_pcparamfilial EXCEPTION;
  sem_preco_pctabpr EXCEPTION; --2600.050062.2014
  PRAGMA EXCEPTION_INIT(sem_preco_pctabpr, -01407); --2600.050062.2014

  vncodbnf pctipobonific.codbnf%TYPE;
  vnQtPadrao number(5,0);
  ITENTATIVA  NUMBER;
  viContCobPlPag_Validos NUMBER := 0;
  viContCobPlPag         NUMBER := 0;

  -- Procedure para retorar parãmetro por Filial
  PROCEDURE buscarparampcparamfilial(pscodfilial IN pcfilial.codigo%TYPE,
                                     psnomeparam IN pcparamfilial.nome%TYPE,
                                     psvalor     OUT pcparamfilial.valor%TYPE,
                                     psmensagem  OUT VARCHAR2) IS
    vicontador NUMBER;
  BEGIN
    psvalor := NULL;

    SELECT COUNT(1)
      INTO vicontador
      FROM pcparamfilial
     WHERE nome = psnomeparam
       AND codfilial = pscodfilial;

    IF vicontador > 0 THEN
      SELECT valor
        INTO psvalor
        FROM pcparamfilial
       WHERE nome = psnomeparam
         AND codfilial = pscodfilial;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      psmensagem := SQLCODE || ' - ' || SQLERRM ||
                    ' -2.1-Erro ao Retornar parâmetros por filial.';
      RAISE;
  END buscarparampcparamfilial;
BEGIN
  pmsg := '';

  BEGIN
    SELECT txvenda,
           NVL(bonificaltdebcredrca, 'N'),
           NVL(usacredrca, 'N'),
           NVL(trocaaltdebcredrca, 'N'),
           NVL(brokeraltdebcredrca, 'N'),
           NVL(crmaltdebcredrca, 'N'),
           tipomovccrca,
           nvl(pcconsum.usachavetriplapcpedi, 'S')
      INTO vntxvenda,
           vsbonificaltdebcredrca,
           vsusacredrca,
           vstrocaaltdebcredrca,
           vsbrokeraltdebcredrca,
           vscrmaltdebcredrca,
           vstipomovccrca,
           vsusachavetriplapcpedi
      FROM pcconsum;
  EXCEPTION
    WHEN OTHERS THEN
      pmsg := SQLCODE || ' - ' || SQLERRM ||
              ' -0- Erro ao buscar parametros do sistema';
      RAISE;
  END;

  IF (vsbonificaltdebcredrca = 'S') AND
     (pcodbnf <> 0)
  THEN
   vncodbnf := pcodbnf;
    SELECT pctipobonific.movimentaccrca
      INTO vsbonificaltdebcredrca
      FROM pctipobonific
     WHERE
     codbnf = pcodbnf;
  ELSE
    select count(*) into vnQtPadrao from pctipobonific where bonifpadrao = 'S';
    if vnQtPadrao > 0 then
        SELECT pctipobonific.codbnf into vncodbnf FROM pctipobonific
            WHERE pctipobonific.bonifpadrao = 'S';
    end if;
  END IF;

  SELECT COUNT(*)
    INTO vicontadorsim
    FROM pcpedi
   WHERE pcpedi.numped = pnumped
     AND (NVL(pcpedi.brinde, 'N') = 'S');

  SELECT COUNT(*)
    INTO vicontadornao
    FROM pcpedi
   WHERE pcpedi.numped = pnumped
     AND (NVL(pcpedi.brinde, 'N') = 'N');

  --Tarefa 66388
  SELECT COUNT(*)
    INTO viContCobPlPag_Validos
    FROM pccobplpag a, pcplpag b, pccob c
   WHERE a.codplpag = b.codplpag
     AND a.codcob = c.codcob
     AND b.tipoprazo = 'B';

  IF viContCobPlPag_Validos > 0 THEN
    SELECT COUNT(*)
      INTO viContCobPlPag
      FROM pccobplpag a, pcplpag b
     WHERE a.codplpag = b.codplpag
       AND b.tipoprazo = 'B'
       AND a.codcob = 'BNF';

    IF viContCobPlPag = 0 THEN
      viContCobPlPag := viContCobPlPag_Validos;
    END IF;

    IF viContCobPlPag > 0 THEN
      BEGIN
        SELECT a.codplpag
          INTO vncodplpag
          FROM pccobplpag a, pcplpag b
         WHERE a.codplpag = b.codplpag
           AND b.tipoprazo = 'B'
           AND a.codcob = 'BNF'
         ORDER BY b.codplpag;
      EXCEPTION
        WHEN OTHERS THEN
          BEGIN
            SELECT codplpag
              INTO vncodplpag
              FROM (SELECT a.codplpag
                      FROM pccobplpag a, pcplpag b
                     WHERE a.codplpag = b.codplpag
                       AND b.tipoprazo = 'B'
                     ORDER BY b.codplpag)
             WHERE ROWNUM = 1;
          EXCEPTION
            WHEN OTHERS THEN
              SELECT pcpedc.codplpag
                INTO vncodplpag
                FROM pcpedc, pccob
               WHERE pcpedc.numped = pnumped
                 AND pcpedc.codcob = pccob.codcob;
          END;
      END;
    END IF;
  ELSE

    SELECT COUNT(*)
      INTO vicontplpag
      FROM pcplpag
     WHERE pcplpag.tipoprazo = 'B';

    IF vicontplpag > 0 THEN
      SELECT codplpag
        INTO vnCodPlPag
        FROM (SELECT pcplpag.codplpag
                FROM pcplpag
               WHERE pcplpag.tipoprazo = 'B'
               ORDER BY pcplpag.codplpag)
       WHERE ROWNUM = 1;
    ELSE
      SELECT pcpedc.codplpag
        INTO vncodplpag
        FROM pcpedc, pccob
       WHERE pcpedc.numped = pnumped
         AND pcpedc.codcob = pccob.codcob;
    END IF;
  END IF;

  vsusanovonumcar := 'N'; --1264.096706.2014

  --Fim Tarefa 66388
  IF vicontadorsim > 0 THEN
    -- Verificar qual o tipo do pedido origem
    SELECT condvenda,
           percvenda,
           origemped,
           numcar,
           codemitente,
           tipodocumento,
           tipooper
      INTO vncondvenda,
           vnpercvenda,
           vsorigemped,
           vnnumcarorigem,
           vncodemitente,
           vstipodocumento_pedc,
           vstipooper
      FROM pcpedc
     WHERE numped = pnumped;

    BEGIN
      -- Tarefa 80289
     IF (vsorigemped = 'R') or (vsorigemped = 'C' and vstipooper = 'R') THEN --1264.096706.2014
       ITENTATIVA := 0;
       vnnumcar   := 0;
       WHILE ITENTATIVA < 50 AND vnnumcar = 0
       LOOP
         vnnumcar := FERRAMENTAS.F_PROX_NUMCAR;
         IF vnnumcar > 0
         THEN
           EXIT;
         END IF;
         ITENTATIVA := ITENTATIVA + 1;
       END LOOP;

       vsusanovonumcar := 'S';  --1264.096706.2014
       /* SELECT NVL(pcconsum.proxnumcar, 1)
          INTO vnnumcar
          FROM pcconsum
         WHERE ROWNUM = 1
           FOR UPDATE;



        UPDATE pcconsum
           SET proxnumcar = NVL(proxnumcar, 1) + 1
         WHERE ROWNUM = 1;                          */

        -- Tarefa 112183
        INSERT INTO pccarreg
          (numcar, dtsaida)
        VALUES
          (vnnumcar, TRUNC(SYSDATE));
        -- Fim tarefa 112183
      END IF; -- IF vsorigemped = 'R'
      -- Fim tarefa 80289
    EXCEPTION
      WHEN OTHERS THEN
        pmsg := SQLCODE || ' - ' || SQLERRM ||
                ' -0- Não foi possível gerar nr. de carregamento';
        RAISE;
        --ROLLBACK;
    END;

    -- 12-08-2009 Sabrina
    IF vncondvenda IN (3) THEN
      vncondvenda := 6;
      vnpercvenda := 0;
    ELSE
      vncondvenda := 5;
      vnpercvenda := 100;
    END IF;

   buscarparampcparamfilial('99',
                            'TIPOCONTACORRENTEBONIF',
                             vstipocontacorrente,
                             vsmensagen);

    if trim(vstipocontacorrente) = '' then
        vstipocontacorrente := 'R';
    end if;

    IF vicontadornao > 0 THEN
      /* BUSCAR NUMERO DO NOVO PEDIDO */
      BEGIN
        SELECT codusur, codfilial
          INTO vncodusur, vscodfilial
          FROM pcpedc
         WHERE numped = pnumped;

       SELECT /*NVL(pcusuari.proxnumped, 1),*/
               NVL(pcusuari.usadebcredrca, 'N')
          INTO /*vnproxnumped, */vsusadebcredrca
          FROM pcusuari
         WHERE codusur = vncodusur;

        PNUMPEDREST := 0;

        ITENTATIVA := 0;
        WHILE ITENTATIVA < 50 AND PNUMPEDREST = 0
        LOOP
          PNUMPEDREST := FERRAMENTAS.F_PROX_NUMPED(vncodusur);
          IF PNUMPEDREST > 0
          THEN
            EXIT;
          END IF;
          ITENTATIVA := ITENTATIVA + 1;
        END LOOP;
        vnproxnumped := pnumpedrest;
      EXCEPTION
        WHEN OTHERS THEN
          pmsg := SQLCODE || ' - ' || SQLERRM ||
                  ' -1- Erro ao buscar numeracao de pedido';
          RAISE;
          --ROLLBACK;
      END;

      vsmensagen := 'OK';
      buscarparampcparamfilial(vscodfilial,
                               'GERARTV5SEMPRECOMONF',
                               vsvalor_paramfilial,
                               vsmensagen);

      IF vsmensagen <> 'OK' THEN
        RAISE error_pcparamfilial;
      END IF;

      IF vsvalor_paramfilial = 'S' THEN
        vstipodocumento_pedc := 'N';
      END IF;

      /* BLOQUEAR PCUSUARI PARA CONTROLE SALDO RCA */
/*      BEGIN
        SELECT pcusuari.vlcorrente, pcusuari.vllimcred
          INTO vnvlcorrente, vnvllimcred
          FROM pcusuari
         WHERE pcusuari.codusur = vncodusur
           FOR UPDATE;
      EXCEPTION
        WHEN OTHERS THEN
          pmsg := SQLCODE || ' - ' || SQLERRM ||
                  ' -1.1- Erro ao bloquear PCUSUARI para controle Saldo RCA';
          --ROLLBACK;
      END;*/

        /*VERIFICAR SE TODOS OS CÓDIGOS AUXILARES DOS PRODUTOS ESTÃO PREENCHIDOS*/

       buscarparampcparamfilial(vscodfilial,
                           'FIL_UTILIZAVENDAPOREMBALAGEM',
                           vsvalor_paramfilial,
                           vsmensagen);

      IF vsmensagen <> 'OK' THEN
        RAISE error_pcparamfilial;
      END IF;

      IF vsvalor_paramfilial = 'S' THEN
      BEGIN
           FOR ITENS IN (SELECT CODAUXILIAR, CODPROD
                          FROM PCPEDI
                          WHERE PCPEDI.NUMPED = pnumped
                          AND PCPEDI.BRINDE = 'S')
          LOOP
               IF NVL(ITENS.CODAUXILIAR,0) = 0 THEN
                             raise_application_error(-20000,
                                      CHR(13) ||
                                      'Produto  ' ||
                                      TO_CHAR(ITENS.CODPROD) ||
                                      ' não possui código auxiliar na rotina 203.');
               END IF;
          END LOOP;

       END;
      END IF;

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
           usadebcredrcabrind,
           codigobrinde,
           brinde,
           pbonific,
           baseicst,
           codauxiliar,
           codfilialretira,
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
           qtcx,
           qtpecas,
           letracomiss,
           txvenda,
           codicmtab,
           perdesccusto,
           eancodprod,
           vldescicmisencao,
           perdescisentoicms,
           vlverbacmvcli,
           pvenda1,
           tipoentrega,
           geragnre_cnpjcliente,
           percdifaliquotas,
           basedifaliquotas,
           vldifaliquotas,
           perdescpolitica,
           pvendaanterior,
           proddescricaocontrato,
           politicaprioritaria,
           truncaritem,
           QTUnitEmb,
           codpromocao,
           Grpregrabrinde,
           numitemped,
           ALIQICMSFECP,
           VLBASEFCPST,
           VLFECP,
           UTILIZOUMOTORCALCULO,
           numverbacampanha, 
           perccustfornec,
           VLDESCREDUCAOPIS,
           VLDESCREDUCAOCOFINS,
           NUMPEDCLI,
           vlbonific
           )
          SELECT pcpedi.codprod,
                 pcpedi.qt,
                 pcpedi.pvenda,
                 vnproxnumped,
                 pcpedi.DATA,
                 pcpedi.codcli,
                 pcpedi.codusur,
                 DECODE(vsusanovonumcar, 'S', vnnumcar, pcpedi.numcar), --1264.096706.2014
                 pcpedi.posicao,
                 DECODE(vnpercvenda, 6, 0, pcpedi.st),
                 pcpedi.vlcustoreal,
                 pcpedi.vlcustofin,
                 pcpedi.ptabela,
                 0,
                 pcpedi.perdesc,
                 pcpedi.qtfalta,
                 pcpedi.numseq,
                 pcpedi.vldesccustocmv,
                 pcpedi.vlcustocont,
                 pcpedi.vlcustorep,
                 pcpedi.vldescsuframa,
                 pcpedi.codst,
                 pcpedi.vldescfin,
                 pcpedi.pvendabase,
                 DECODE(vnpercvenda, 6, 0, pcpedi.vlipi),
                 pcpedi.percipi,
                 pcpedi.poriginal,
                 pcpedi.iva,
                 pcpedi.pauta,
                 pcpedi.aliqicms1,
                 pcpedi.aliqicms2,
                 NVL(pcpedi.usadebcredrcabrind, 'N'),
                 codigobrinde,
                 brinde,
                 pcpedi.pbonific,
                 pcpedi.baseicst,
                 pcpedi.codauxiliar,
                 pcpedi.codfilialretira,
                 pcpedi.stclientegnre,
                 pcpedi.percbasered,
                 pcpedi.percbaseredst,
                 pcpedi.percbaseredstfonte,
                 pcpedi.perfretecmv,
                 pcpedi.custofinest,
                 pcpedi.perciss,
                 pcpedi.vliss,
                 pcpedi.complemento,
                 pcpedi.pbaserca,
                 pcpedi.vlverbacmv,
                 pcpedi.numverbarebcmv,
                 pcpedi.qtcx,
                 pcpedi.qtpecas,
                 pcpedi.letracomiss,
                 pcpedi.txvenda,
                 pcpedi.codicmtab,
                 pcpedi.perdesccusto,
                 pcpedi.eancodprod,
                 pcpedi.vldescicmisencao,
                 pcpedi.perdescisentoicms,
                 pcpedi.vlverbacmvcli,
                 pcpedi.pvenda1,
                 pcpedi.tipoentrega,
                 pcpedi.geragnre_cnpjcliente,
                 pcpedi.percdifaliquotas,
                 pcpedi.basedifaliquotas,
                 pcpedi.vldifaliquotas,
                 pcpedi.perdescpolitica,
                 pcpedi.pvendaanterior,
                 pcpedi.proddescricaocontrato,
                 pcpedi.politicaprioritaria,
                 pcpedi.truncaritem,
                 nvl(PCPEDI.QTUNITEMB,
                 (SELECT PCPRODUT.QTUNIT
                    FROM PCPRODUT
                   WHERE CODPROD = PCPEDI.CODPROD)),
                 pcpedi.codpromocao,
                 pcpedi.Grpregrabrinde,
                 pcpedi.numitemped,
                 pcpedi.ALIQICMSFECP,
                 pcpedi.VLBASEFCPST,
                 pcpedi.VLFECP,
                 pcpedi.UTILIZOUMOTORCALCULO,
                 pcpedi.numverbacampanha,
                 pcpedi.perccustfornec,
                 PCPEDI.VLDESCREDUCAOPIS,
                 PCPEDI.VLDESCREDUCAOCOFINS,
                 pcpedi.NUMPEDCLI,
                 pcpedi.vlbonific
            FROM pcpedi
           WHERE pcpedi.numped = pnumped
             AND (NVL(pcpedi.brinde, 'N') = 'S');

        FOR ORIGEM IN (SELECT O.ROWID RID
                         FROM PCPEDI I, PCORIGEMPRECO O
                        WHERE I.NUMPED = O.NUMPED
                          AND I.NUMSEQ = O.NUMSEQ
                          AND I.CODPROD = O.CODPROD
                          AND I.NUMPED = pnumped
                          AND NVL(I.BRINDE, 'N') = 'S')
        LOOP
          UPDATE PCORIGEMPRECO T
             SET T.NUMPED = vnproxnumped
           WHERE T.ROWID = ORIGEM.RID;

        END LOOP;
        --Tarefa 147991
        if vsusachavetriplapcpedi = 'N' then
          BEGIN
            VDCODPROD_EXCLUSAO := 0;

            FOR DADOS IN (SELECT PCPEDI.CODPROD,
                                 PCPEDI.NUMSEQ,
                                 PCPEDI.NUMPED
                            FROM PCPEDI
                           WHERE PCPEDI.NUMPED = vnproxnumped
                             AND (SELECT COUNT(1)
                                    FROM PCPEDI X
                                   WHERE X.NUMPED = PCPEDI.NUMPED
                                     AND PCPEDI.CODPROD = X.CODPROD) > 1
                           GROUP BY PCPEDI.CODPROD,
                                    PCPEDI.NUMSEQ,
                                    PCPEDI.NUMPED) LOOP

              IF DADOS.CODPROD <> VDCODPROD_EXCLUSAO THEN

                VDCODPROD_EXCLUSAO := DADOS.CODPROD;

                SELECT SUM(NVL(PCPEDI.QT, 0))
                  INTO VDQTDE_EXCLUSAO
                  FROM PCPEDI
                 WHERE PCPEDI.NUMPED = DADOS.NUMPED
                   AND PCPEDI.CODPROD = DADOS.CODPROD
                 GROUP BY PCPEDI.CODPROD;

                UPDATE PCPEDI
                   SET PCPEDI.QT = VDQTDE_EXCLUSAO
                 WHERE PCPEDI.NUMPED = DADOS.NUMPED
                   AND PCPEDI.NUMSEQ = DADOS.NUMSEQ
                   AND PCPEDI.CODPROD = DADOS.CODPROD;

                DELETE PCPEDI
                 WHERE PCPEDI.NUMPED = DADOS.NUMPED
                   AND PCPEDI.NUMSEQ <> DADOS.NUMSEQ
                   AND PCPEDI.CODPROD = DADOS.CODPROD;
              END IF;

            END LOOP;
          END;
        end if;
        --Fim tarefa 147991

        -- Tarefa 102210
        -- Retornar o Nr. da região do pedido
        SELECT NVL(numregiao, 0)
          INTO vnnumregiao
          FROM pcpedc
         WHERE numped = pnumped;

        -- Retornar o Nr. da coluna de preço
        SELECT DECODE(NVL(pcplpag.numpr, 0), 0, 1, pcplpag.numpr)
          INTO vnnumpr_plpag
          FROM pcplpag
         WHERE codplpag = vncodplpag;

        -- Se não existir no pedido a regiao, busca da praca do cliente
        IF vnnumregiao = 0 THEN
          SELECT pcpraca.numregiao
            INTO vnnumregiao
            FROM pcpedc, pcclient, pcpraca
           WHERE pcpedc.numped = pnumped
             AND pcclient.codcli = pcpedc.codcli
             AND pcpraca.codpraca = pcpedc.codpraca;
        END IF;

        -- Atualizar PVenda e PTabela não para gerar zerado
        /*
        Autor       : Rafael Braga
        Solicitação : 650.100812.2014
        Data        : 23/09/2014
        Descrição   : Trecho abaixo comentado por estar trocando os preços
                      calculados pela 316 por preços de tabela da 201 diretamente.
                      Caso o preço venha a ser gravado zerado, deve ser descoberta
                      a fonte do problema.
        */
/*        BEGIN
        UPDATE pcpedi
           SET pvenda   = (SELECT DECODE(vnnumpr_plpag,
                                         1,
                                         pctabpr.pvenda1,
                                         2,
                                         pctabpr.pvenda2,
                                         3,
                                         pctabpr.pvenda3,
                                         4,
                                         pctabpr.pvenda4,
                                         5,
                                         pctabpr.pvenda5,
                                         6,
                                         pctabpr.pvenda6,
                                         7,
                                         pctabpr.pvenda7,
                                         pctabpr.pvenda1)
                             FROM pctabpr
                            WHERE pctabpr.numregiao = vnnumregiao
                              AND pctabpr.codprod = pcpedi.codprod),
               pbaserca = DECODE(NVL(USADEBCREDRCABRIND, 'N'),
                                 'N',
                                 0,
                                 (SELECT DECODE(vnnumpr_plpag,
                                                1,
                                                pctabpr.pvenda1,
                                                2,
                                                pctabpr.pvenda2,
                                                3,
                                                pctabpr.pvenda3,
                                                4,
                                                pctabpr.pvenda4,
                                                5,
                                                pctabpr.pvenda5,
                                                6,
                                                pctabpr.pvenda6,
                                                7,
                                                pctabpr.pvenda7,
                                                pctabpr.pvenda1)
                                    FROM pctabpr
                                   WHERE pctabpr.numregiao = vnnumregiao
                                     AND pctabpr.codprod = pcpedi.codprod)),
               ptabela  = (SELECT DECODE(vnnumpr_plpag,
                                         1,
                                         pctabpr.pvenda1,
                                         2,
                                         pctabpr.pvenda2,
                                         3,
                                         pctabpr.pvenda3,
                                         4,
                                         pctabpr.pvenda4,
                                         5,
                                         pctabpr.pvenda5,
                                         6,
                                         pctabpr.pvenda6,
                                         7,
                                         pctabpr.pvenda7,
                                         pctabpr.pvenda1)
                             FROM pctabpr
                            WHERE pctabpr.numregiao = vnnumregiao
                              AND pctabpr.codprod = pcpedi.codprod)
         WHERE pcpedi.numped = vnproxnumped
           and pcpedi.codprod in
               (select pcprodut.codprod
                  from pcprodut
                 where nvl(PCPRODUT.TIPOMERC, 'X') <> 'CB');
        EXCEPTION
        WHEN sem_preco_pctabpr THEN --2600.050062.2014
          RAISE sem_preco_pctabpr;
        END;*/

        -- Fim tarefa 102210

        /* RECALCULO DO CMV */
        UPDATE pcpedi
           SET vlcustofin  = (SELECT NVL(pcest.custofin, 0)
                                FROM pcest
                               WHERE pcest.codprod = pcpedi.codprod
                                 AND pcest.codfilial = vscodfilial),
               vlcustoreal = (SELECT NVL(pcest.custoreal, 0)
                                FROM pcest
                               WHERE pcest.codprod = pcpedi.codprod
                                 AND pcest.codfilial = vscodfilial)
         WHERE (numped = vnproxnumped)
           AND (NVL(pcpedi.perccustfornec,0) = 0)
           AND EXISTS
         (SELECT codst FROM pctribut WHERE codst = pcpedi.codst);

        UPDATE pcpedi
           SET vlcustofin  = (SELECT NVL(pcpedi.vlcustofin, 0) -
                                     (NVL(pcpedi.vlcustofin, 0) *
                                      (NVL(perdesccusto, 0) / 100))
                                FROM pctribut
                               WHERE pctribut.codst = pcpedi.codst),
               vlcustoreal = (SELECT NVL(pcpedi.vlcustoreal, 0) -
                                     (NVL(pcpedi.vlcustoreal, 0) *
                                      (NVL(perdesccusto, 0) / 100))
                                FROM pctribut
                               WHERE pctribut.codst = pcpedi.codst)
         WHERE (numped = vnproxnumped)
           AND (NVL(pcpedi.perccustfornec,0) = 0)
           AND EXISTS
         (SELECT codst FROM pctribut WHERE codst = pcpedi.codst);

        UPDATE pcpedi
           SET vlcustofin  = (SELECT pcpedi.vlcustofin + NVL(pcpedi.st, 0) +
                                     NVL(pcpedi.vlipi, 0) +
                                     (NVL(pcpedi.pvenda, 0) *
                                     (NVL(vntxvenda, 0) / 100)) +
                                     (NVL(pcpedi.pvenda, 0) *
                                     (NVL(pcpedi.percom, 0) / 100)) +
                                     ((NVL(pcpedi.pvenda, 0) -
                                     NVL(pcpedi.st, 0) -
                                     NVL(pcpedi.vlipi, 0)) *
                                     (NVL(pctribut.codicmtab, 0) / 100))
                                FROM pctribut
                               WHERE codst = pcpedi.codst),
               vlcustoreal = (SELECT pcpedi.vlcustoreal + NVL(pcpedi.st, 0) +
                                     NVL(pcpedi.vlipi, 0) +
                                     (NVL(pcpedi.pvenda, 0) *
                                     (NVL(vntxvenda, 0) / 100)) +
                                     (NVL(pcpedi.pvenda, 0) *
                                     (NVL(pcpedi.percom, 0) / 100)) +
                                     ((NVL(pcpedi.pvenda, 0) -
                                     NVL(pcpedi.st, 0) -
                                     NVL(pcpedi.vlipi, 0)) *
                                     (NVL(pctribut.codicmtab, 0) / 100))
                                FROM pctribut
                               WHERE codst = pcpedi.codst)
         WHERE (numped = vnproxnumped)
           AND (NVL(pcpedi.perccustfornec,0) = 0)
           AND EXISTS
         (SELECT codst FROM pctribut WHERE codst = pcpedi.codst);

        /* FIM RECALCULO DO CMV */
        SELECT COUNT(*) qt,
               SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.vlcustofin, 0)) vlcustofin,
               SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.vlcustoreal, 0)) vlcustoreal,
               SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.vlcustocont, 0)) vlcustocont,
               SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.vlcustorep, 0)) vlcustorep,
               SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.ptabela, 0)) vltabela,
               SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.pvenda, 0)) vlatend,
               SUM((NVL(pcpedi.qt, 0) + NVL(pcpedi.qtfalta, 0)) *
                   NVL(pcpedi.pvenda, 0)) vltotal,
               SUM(NVL(pcpedi.qt, 0) * NVL(pcprodut.pesobruto, 0)) totpeso,
               SUM(NVL(pcpedi.qt, 0) * NVL(pcprodut.volume, 0)) totvolume
          INTO vnnumitens,
               vnvlcustofin,
               vnvlcustoreal,
               vnvlcustocont,
               vnvlcustorep,
               vnvltabela,
               vnvlatend,
               vnvltotal,
               vntotpeso,
               vntotvolume
          FROM pcpedi, pcprodut
         WHERE pcpedi.codprod = pcprodut.codprod
           AND pcpedi.numped = vnproxnumped
           AND pcpedi.qt > 0;

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
--           vlfrete,
--           vloutrasdesp,
           obs1,
           obs2,
           condvenda,
           dtentrega,
           numpedrca,
           fretedespacho,
           freteredespacho,
           codfornecfrete,
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
           codclinf,
           brinde,
           usaintegracaowms,
           numregiao -- Tarefa 102647
          ,
           codfornecredespacho --Tarefa 115385
          ,
           codmotivo --Tarefa 115155
          ,
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
           numnota,
           perdescfin,
           restricaotransp,
           geracp,
           vendaassistida,
           LOG,
           dtcalcfrete,
           codfunccalcfrete,
           eancobranca,
           eanentrega,
           usacfopvendanatv10,
           tipoprioridadeentrega,
           codusur2,
           codusur3,
           codusur4,
           numpedtv1,
           usadebcredrca,
           bonificaltdebcredrca,
           trocaaltdebcredrca,
           brokeraltdebcredrca,
           crmaltdebcredrca,
           tipomovccrca,
           usacredrca,
           gerardadosnfpaulista,
           usasaldocontacorrentedescfin,
           valordescfin,
           codvisita,
           codatendimento,
           vendatriangular,
           vlentrada,
           ufdesembaraco,
           localdesembaraco,
           custobonificacao,
           codfornecbonific,
           codbnf,
           tipodocumento,
           cfopbnfdegusta,
           contaordem,
           codgerente,
           tipocontacorrente,
		   codendentcli)
          SELECT vnproxnumped,
                 pcpedc.DATA,
                 pcpedc.codusur,
                 pcpedc.codcli,
                 vnnumitens,
                 0 -- por ser TV5
                ,
                 pcpedc.codpraca,
                 pcpedc.posicao,
                 DECODE(vsusanovonumcar, 'S', vnnumcar, pcpedc.numcar), --1264.096706.2014
                 pcpedc.codsupervisor,
                 pcpedc.codfilial,
                 vnvltotal,
                 vnvltabela,
                 vnvlcustoreal,
                 vnvlcustofin,
                 vntotpeso,
                 vntotvolume,
                 pcpedc.codemitente,
                 pcpedc.operacao,
                 pcpedc.tipovenda,
                 pcpedc.obs,
                 'BNF',
                 pcpedc.hora,
                 pcpedc.minuto,
                 vncodplpag,
                 pcpedc.numpedcli,
                 vnpercvenda,
                 pcpedc.perdesc,
                 pcpedc.vldesconto,
--                 pcpedc.vlfrete,
--                 pcpedc.vloutrasdesp,
                 pcpedc.obs1,
                 pcpedc.obs2,
                 vncondvenda,
                 pcpedc.dtentrega,
                 pcpedc.numpedrca,
                 pcpedc.fretedespacho,
                 pcpedc.freteredespacho,
                 pcpedc.codfornecfrete,
                 pcpedc.tipocarga,
                 pcpedc.prazo1,
                 pcpedc.prazo2,
                 pcpedc.prazo3,
                 pcpedc.prazo4,
                 pcpedc.prazo5,
                 pcpedc.prazo6,
                 pcpedc.prazo7,
                 pcpedc.prazo8,
                 pcpedc.prazo9,
                 pcpedc.prazo10,
                 pcpedc.prazo11,
                 pcpedc.prazo12,
                 pcpedc.prazomedio,
                 pcpedc.obsentrega1,
                 pcpedc.obsentrega2,
                 pcpedc.obsentrega3,
                 pcpedc.tipoembalagem,
                 pcpedc.codepto,
                 pcpedc.campanha,
                 pcpedc.coddistrib,
                 vnvlcustocont,
                 vnvlcustorep,
                 pcpedc.numnotamanif,
                 pcpedc.seriemanif,
                 pcpedc.origemped,
                 pcpedc.especiemanif,
                 pcpedc.numpedentfut,
                 pcpedc.codfilialnf,
                 pcpedc.numcarmanif,
                 pcpedc.numorca,
                 pcpedc.codclinf,
                 'S',
                 pcpedc.usaintegracaowms,
                 vnnumregiao -- tarefa 102647
                ,
                 codfornecredespacho --Tarefa 115385
                ,
                 codmotivo --Tarefa 115155
                ,
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
                 numnota,
                 perdescfin,
                 restricaotransp,
                 geracp,
                 vendaassistida,
                 LOG,
                 dtcalcfrete,
                 codfunccalcfrete,
                 eancobranca,
                 eanentrega,
                 usacfopvendanatv10,
                 tipoprioridadeentrega,
                 codusur2,
                 codusur3,
                 codusur4,
                 pnumped,
                 usadebcredrca,
                 vsbonificaltdebcredrca,
                 trocaaltdebcredrca,
                 brokeraltdebcredrca,
                 crmaltdebcredrca,
                 tipomovccrca,
                 usacredrca,
                 gerardadosnfpaulista,
                 usasaldocontacorrentedescfin,
                 valordescfin,
                 codvisita,
                 codatendimento,
                 vendatriangular,
                 vlentrada,
                 ufdesembaraco,
                 localdesembaraco,
                 custobonificacao,
                 codfornecbonific,
                 vncodbnf,
                 vstipodocumento_pedc,
                 cfopbnfdegusta,
                 contaordem,
                 codgerente,
                 vsTipoContaCorrente,
				 codendentcli
            FROM pcpedc, pccob
           WHERE pcpedc.numped = pnumped
             AND pcpedc.codcob = pccob.codcob;

           UPDATE PCORIGEMPRECO T
             SET T.COLUNAPRECO = vnnumpr_plpag
           WHERE  T.NUMPED = vnproxnumped;

        -- Tarefa 99666 (Gerar dados do consumidor final para a o novo pedido se exitir)
        INSERT INTO pcvendaconsum
          (numped,
           cliente,
           cgcent,
           ieent,
           enderent,
           bairroent,
           telent,
           municent,
           estent,
           cepent,
           nomecontato,
           telefonecontato,
           obscontato,
           codcidade,
           email)
          (SELECT vnproxnumped,
                  cliente,
                  cgcent,
                  ieent,
                  enderent,
                  bairroent,
                  telent,
                  municent,
                  estent,
                  cepent,
                  nomecontato,
                  telefonecontato,
                  obscontato,
                  codcidade,
                  email
             FROM pcvendaconsum
            WHERE numped = pnumped);

        IF vnnumcar > 0 THEN
          -- Tarefa 112183
          SELECT dtsaida,
                 destino,
                 datamon,
                 codveiculo,
                 codfuncmon,
                 dtfecha,
                 horamon,
                 minutomon
            INTO vddtsaida_carreg,
                 vsdestino_carreg,
                 vddatamon_carreg,
                 vncodveiculo_carreg,
                 vncodfuncmon_carreg,
                 vddtfecha_carreg,
                 vnhoramon_carreg,
                 vnminutomon_carreg
            FROM pccarreg
           WHERE numcar = vnnumcarorigem;

          UPDATE pccarreg
             SET dtsaida    = vddtsaida_carreg,
                 totpeso    = vntotpeso,
                 totvolume  = vntotvolume,
                 vltotal    = vnvltotal,
                 destino    = vsdestino_carreg,
                 datamon    = vddatamon_carreg,
                 codveiculo = vncodveiculo_carreg,
                 codfuncmon = vncodfuncmon_carreg,
                 dtfecha    = vddtfecha_carreg,
                 horamon    = vnhoramon_carreg,
                 minutomon  = vnminutomon_carreg
           WHERE numcar = vnnumcar;

          IF SQL%ROWCOUNT = 0 THEN
            INSERT INTO pccarreg
              (numcar,
               dtsaida,
               totpeso,
               totvolume,
               vltotal,
               destino,
               datamon,
               codveiculo,
               codfuncmon,
               dtfecha,
               horamon,
               minutomon)
              SELECT vnnumcar,
                     dtsaida,
                     vntotpeso,
                     vntotvolume,
                     vnvltotal,
                     destino,
                     datamon,
                     codveiculo,
                     codfuncmon,
                     dtfecha,
                     horamon,
                     minutomon
                FROM pccarreg
               WHERE numcar = vnnumcarorigem;
          END IF; -- IF SQL%ROWCOUNT = 0
          -- Tarefa 112183
        END IF;

        /* Registrar log de alteração do saldo da conta-corrente do RCA */
        vbvalido := false;

       FOR item IN (SELECT codprod, numseq, qt
                       FROM pcpedi
                      WHERE numped = vnproxnumped) LOOP
          BEGIN
          /*excluir do pedido original*/
           vbvalido := pc_pkg_controlarsaldorca.ccrca_excluir_item_pedido(vncodemitente,
                                                                  500,
                                                                  vncodusur,
                                                                 pnumped,
                                                                 item.codprod,
                                                                 item.numseq,
                                                                 item.qt);

            vbvalido := pc_pkg_controlarsaldorca.ccrca_incluir_item_pedido(vncodemitente,
                                                                    500,
                                                                    vncodusur,
                                                                  vnproxnumped,
                                                                  item.codprod,
                                                                    item.numseq);

          EXCEPTION
            WHEN OTHERS THEN
              pmsg := SQLCODE || ' - ' || SQLERRM ||
                      ' -1.2- Erro ao atualizar Saldo RCA. Verifique se a package "PC_PKG_CONTROLARSALDORCA" está válida ou utilize a Rotina 300 para atualizá-la';
              RAISE;
              --ROLLBACK;
          END;
        END LOOP;

        /* Gravar parametrização de controle de saldo de RCA no pedido de venda */
        IF vbvalido THEN
          UPDATE pcpedc
             SET pcpedc.usacredrca           = vsusacredrca,
                 pcpedc.bonificaltdebcredrca = vsbonificaltdebcredrca,
                 pcpedc.trocaaltdebcredrca   = vstrocaaltdebcredrca,
                 pcpedc.brokeraltdebcredrca  = vsbrokeraltdebcredrca,
                 pcpedc.crmaltdebcredrca     = vscrmaltdebcredrca,
                 pcpedc.tipomovccrca         = vstipomovccrca,
                 pcpedc.usadebcredrca        = vsusadebcredrca
           WHERE pcpedc.numped = vnproxnumped;
        END IF;

        SELECT PCPEDC.POSICAO
          into vsposicao
          FROM PCPEDC
         WHERE PCPEDC.NUMPED = vnproxnumped;

        UPDATE PCPEDI
            SET POSICAO = vsposicao
          WHERE PCPEDI.NUMPED = vnproxnumped;

        IF vsposicao = 'B' THEN
          PKG_MOTIVOBLOQUEIO.INSERTMOTIVO(vnproxnumped,20,'Pedido TV1 bloqueado: ' || pnumped,'C');
        END IF;

        /* Exclusao dos Itens Tipo 3 do Pedido Original */
        DELETE FROM pcpedi
         WHERE numped = pnumped
           AND (NVL(pcpedi.brinde, 'N') = 'S');

        SELECT COUNT(*) qt,
               SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.vlcustofin, 0)) vlcustofin,
               SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.vlcustoreal, 0)) vlcustoreal,
               SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.vlcustocont, 0)) vlcustocont,
               SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.vlcustorep, 0)) vlcustorep,
               SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.ptabela, 0)) vltabela,
               SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.pvenda, 0)) vlatend,
               SUM((NVL(pcpedi.qt, 0) + NVL(pcpedi.qtfalta, 0)) *
                   NVL(pcpedi.pvenda, 0)) vltotal,
               SUM(NVL(pcpedi.qt, 0) * NVL(pcprodut.pesobruto, 0)) totpeso,
               SUM(NVL(pcpedi.qt, 0) * NVL(pcprodut.volume, 0)) totvolume
          INTO vnnumitens,
               vnvlcustofin,
               vnvlcustoreal,
               vnvlcustocont,
               vnvlcustorep,
               vnvltabela,
               vnvlatend,
               vnvltotal,
               vntotpeso,
               vntotvolume
          FROM pcpedi, pcprodut
         WHERE pcpedi.codprod = pcprodut.codprod
           AND pcpedi.numped = pnumped
           AND pcpedi.qt > 0;

        UPDATE pcpedc
           SET numitens    = vnnumitens,
               vlcustofin  = vnvlcustofin,
               vlcustoreal = vnvlcustoreal,
               vlcustocont = vnvlcustocont,
               vlcustorep  = vnvlcustorep,
               vltabela    = vnvltabela,
               vlatend     = vnvlatend,
               vltotal     = vnvltotal,
               totpeso     = vntotpeso,
               totvolume   = vntotvolume
         WHERE numped = pnumped;

        --COMMIT;
        pmsg := 'OK. PEDIDO COM BRINDES ' || pnumpedrest ||
                ' GERADO COM SUCESSO';
      EXCEPTION
        WHEN OTHERS THEN
          pmsg := SQLCODE || ' - ' || SQLERRM ||
                  ' -2- Erro ao gerar pedido com os brindes';
          RAISE;
      END;
    ELSE
      BEGIN
        /* RECALCULO DO CMV */
        UPDATE pcpedi
           SET vlcustofin  = (SELECT NVL(pcest.custofin, 0)
                                FROM pcest
                               WHERE pcest.codprod = pcpedi.codprod
                                 AND pcest.codfilial =
                                     (SELECT codfilial
                                        FROM pcpedc
                                       WHERE numped = pcpedi.numped)),
               vlcustoreal = (SELECT NVL(pcest.custoreal, 0)
                                FROM pcest
                               WHERE pcest.codprod = pcpedi.codprod
                                 AND pcest.codfilial =
                                     (SELECT codfilial
                                        FROM pcpedc
                                       WHERE numped = pcpedi.numped))
         WHERE (numped = pnumped)
           AND (NVL(pcpedi.perccustfornec,0) = 0)
           AND EXISTS
         (SELECT codst FROM pctribut WHERE codst = pcpedi.codst);

        UPDATE pcpedi
           SET vlcustofin  = (SELECT NVL(pcpedi.vlcustofin, 0) -
                                     (NVL(pcpedi.vlcustofin, 0) *
                                      (NVL(perdesccusto, 0) / 100))
                                FROM pctribut
                               WHERE pctribut.codst = pcpedi.codst),
               vlcustoreal = (SELECT NVL(pcpedi.vlcustoreal, 0) -
                                     (NVL(pcpedi.vlcustoreal, 0) *
                                      (NVL(perdesccusto, 0) / 100))
                                FROM pctribut
                               WHERE pctribut.codst = pcpedi.codst)
         WHERE (numped = pnumped)
           AND (NVL(pcpedi.perccustfornec,0) = 0)
           AND EXISTS
         (SELECT codst FROM pctribut WHERE codst = pcpedi.codst);

        UPDATE pcpedi
           SET vlcustofin  = (SELECT pcpedi.vlcustofin + NVL(pcpedi.st, 0) +
                                     NVL(pcpedi.vlipi, 0) +
                                     (NVL(pcpedi.pvenda, 0) *
                                     (NVL(vntxvenda, 0) / 100)) +
                                     (NVL(pcpedi.pvenda, 0) *
                                     (NVL(pcpedi.percom, 0) / 100)) +
                                     ((NVL(pcpedi.pvenda, 0) -
                                     NVL(pcpedi.st, 0) -
                                     NVL(pcpedi.vlipi, 0)) *
                                     (NVL(pctribut.codicmtab, 0) / 100))
                                FROM pctribut
                               WHERE codst = pcpedi.codst),
               vlcustoreal = (SELECT pcpedi.vlcustoreal + NVL(pcpedi.st, 0) +
                                     NVL(pcpedi.vlipi, 0) +
                                     (NVL(pcpedi.pvenda, 0) *
                                     (NVL(vntxvenda, 0) / 100)) +
                                     (NVL(pcpedi.pvenda, 0) *
                                     (NVL(pcpedi.percom, 0) / 100)) +
                                     ((NVL(pcpedi.pvenda, 0) -
                                     NVL(pcpedi.st, 0) -
                                     NVL(pcpedi.vlipi, 0)) *
                                     (NVL(pctribut.codicmtab, 0) / 100))
                                FROM pctribut
                               WHERE codst = pcpedi.codst)
         WHERE (numped = pnumped)
           AND (NVL(pcpedi.perccustfornec,0) = 0)
           AND EXISTS
         (SELECT codst FROM pctribut WHERE codst = pcpedi.codst);

        /* FIM RECALCULO DO CMV */
        --COMMIT;
        pmsg := 'OK. PEDIDO ' || pnumped || ' ALTERADO COM SUCESSO';
      EXCEPTION
        WHEN OTHERS THEN
          pmsg := SQLCODE || ' - ' || SQLERRM ||
                  ' -3- Erro ao transformar pedido';
          RAISE;
      END;
    END IF; /* VICONTADORNAO > 0 */
  END IF; /* VICONTADORSIM > 0 */
EXCEPTION
  WHEN error_pcparamfilial THEN
    --ROLLBACK;
    pmsg := SQLCODE || ' - ' || SQLERRM || vsmensagen;

  WHEN sem_preco_pctabpr THEN
    --ROLLBACK;
    pmsg  := 'Produto não possui precificação na rotina 201 (PCTABPR). Favor precificar o produto.';

  WHEN OTHERS THEN
    --ROLLBACK;
    pmsg := 'Erro na geração de pedido com brindes. Erro original: ' || SQLCODE || ' - ' || SQLERRM ;
END prc_gerar_pedido_brinde_bnf;
