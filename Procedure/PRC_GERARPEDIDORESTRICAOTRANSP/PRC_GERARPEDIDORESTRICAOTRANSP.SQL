CREATE OR REPLACE PROCEDURE PRC_GERARPEDIDORESTRICAOTRANSP (
   pnumped                    IN       NUMBER
  ,pnumpedrest                OUT      NUMBER
  ,pmsg                       OUT      VARCHAR2
  ,p_num_pedido               IN       NUMBER DEFAULT NULL
  ,p_num_pedido_resf          IN       NUMBER DEFAULT NULL
)
IS
   /**************************************************************************************
    Propósito: Esta procedure gera pedidos com produtos que tenha restrição de transporte.
    Atenção:   Essa procedure não controla transações e não deve controlar.

                          Historico de Alteracoes
    --------------------------------------------------------------------------------------
    Data        Responsavel     Descricao
    ----------  --------------  ----------------------------------------------------------
    04/06/2008  Andréa          Criacao do Programa
    20/06/2008  Diego Martins   Inserindo no Insert os campos(USAINTEGRACAOWMS,VENDAASSISTIDA) da PCPEDC
    11/11/2008  Pablo           Alteração para gerar PCPediCesta e PCOrigemPreco para o novo pedido.
    24/12/2008  Pablo           Tarefa 75296 Alteração para gerar um pedido tipo de pedido com Restrição,
                                onde PCProdut.RestricaoTransp = R' (Produtos refrigerados).
    17/01/2009  Pablo           Tarefa 74588 Alteração para gravar todos os campos em PCPEDC e PCPEDI que são gravamos
                                na 316 e também para dividir em novos pedidos corretamente.
    26/02/2009  Pablo           Tarefa 79111 Alteração para replicar a informação de PCVendaConsum para o novo pedido gerado
    12/03/2009  Pablo           Tarefa 79698 Alteração para gerar novos num. de carregamento caso o pedido origem seja
                                Balcão Reserva
    16/03/2009  Pablo           Tarefa 80212 Alteração para apresentar todos o pedidos gerados
    14/04/2009  Pablo           Tarefa 82214 Alteração para não alterar o pedido de venda, caso não exista mesmo
                                produtos sem restrição de transporte
    20/04/2009  Pablo           Tarefa 82932 Alteração para customizar o Projeto 67764 - Comissão Profissional
    24/07/2009  Andréa          Tarefa 85855 Implementar projeto 71133 - Reformulação de controle de saldo de rca
    07/08/2009  Pablo           Tarefa 90497 Atualizar corretamente o campo PCPedc.RestricaoTransp
    10/08/2009  Pablo           Tarefa 90497 Ajuste geração pedido com restrição de transp. "Refrigerado"
    18/09/2009  Andréa          Tarefa 92658 Gravar campo precofvbruto na pcpedi
    13/11/2009  Pablo           Tarefa 96638 Alteração para atualizar a PCPEDC.restricaotransp conforme a restrição dos itens
    02/02/2011  Pablo           Alteração para passar a gravar todos os campos que são gravados pelas rotinas 316 nas tabelas PCPEDC e PCPEDI
    13/09/2012  Marcos          Tarefa 173078 ALterada procedure para não recalcular o custo dos itens já que no peidido calculo e inclusive teve rebaixa
    24/03/2014  Rafael Braga    3177.031594.2014: ajustado para gravar o campo codendentcli na pcpedc.
    16/04/2014  Rafael Braga    3099.042129.2014: ajustado para gravar a tabela PCPEDCVCTO para os pedidos de restrição de transporte.
    08/07/2016  Rafael Braga    Removido commits e rollbacks; ajustado a maneira de obter próximo número de pedido e carregamento para usar transaçao autônoma.
   *******************************************************************************/
   -- DECLARACAO DE VARIAVEIS
   vicontadorsim                 NUMBER;
   vicontadorref                 NUMBER;
   -- Variável para totalizar os itens refrigerados
   vicontadornao                   NUMBER;
   vntxvenda                       pcconsum.txvenda%TYPE;
   vnnumcar01                      pcconsum.proxnumcar%TYPE;
   vnnumcar02                      pcconsum.proxnumcar%TYPE;
   vnnumcar                        pcpedc.numcar%TYPE;
   vncodusur                       pcpedc.codusur%TYPE;
   vscodfilial                     pcpedc.codfilial%TYPE;
   vnproxnumped                    pcusuari.proxnumped%TYPE;
   vnproxnumpedref                 pcusuari.proxnumped%TYPE;
   vnnumitens                      pcpedc.numitens%TYPE;
   vnvlcustofin                    pcpedc.vlcustofin%TYPE;
   vnvlcustoreal                   pcpedc.vlcustoreal%TYPE;
   vnvlcustocont                   pcpedc.vlcustocont%TYPE;
   vnvlcustorep                    pcpedc.vlcustorep%TYPE;
   vnvltabela                      pcpedc.vltabela%TYPE;
   vnvlatend                       pcpedc.vlatend%TYPE;
   vnvltotal                       pcpedc.vltotal%TYPE;
   vntotpeso                       pcpedc.totpeso%TYPE;
   vntotvolume                     pcpedc.totvolume%TYPE;
   vsorigemped                     pcpedc.origemped%TYPE;
   -- vbvalido BOOLEAN;
   vncodemitente                   pcpedc.codemitente%TYPE;
   vbsaldorca                      BOOLEAN;
   vsgerarTv5                      VARCHAR2(1) := 'N';
   vntotbonific                    pcpedc.VLBONIFIC%TYPE;
   vnvlverbacmv                    pcpedc.vlverbacmv%TYPE;
   vnvlverbacmvcli                    pcpedc.vlverbacmvcli%TYPE;
   vnDescRestTranspBalc            VARCHAR2(1);
   vnDescRestTranspBalcReserva     VARCHAR2(1);
   ROWpcpedipcpedifv               pcpedipcpedifv%ROWTYPE;
   iTentativa                      number;
   vsUsaNumcarVendaBalcao          pcconsum.usanumcarvendabalcao%TYPE;
   vsFechaCarregAutVendaBalcao     pcconsum.fechacarregautvendabalcao%TYPE;
   vnCONDVENDA                     pcpedc.condvenda%TYPE;

   TYPE T_LISTA_PED IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;

   LISTA_PED T_LISTA_PED;

  FUNCTION EXTRAIR_PROX_NUMPED(LISTA IN OUT LISTA_PED%TYPE)
    RETURN NUMBER IS
    NUMPEDTEMP PCPEDI.NUMPED%TYPE;
  BEGIN
    IF LISTA.COUNT <= 0
    THEN
      RETURN 0;
    END IF;

    FOR I IN LISTA.FIRST .. LISTA.LAST
    LOOP
      IF LISTA(I) = 0 THEN
        LISTA.DELETE(I);
        RETURN 0;
      END IF;
      NUMPEDTEMP := LISTA(I);
      LISTA.DELETE(I);
      RETURN NUMPEDTEMP;
    END LOOP;
  END;
BEGIN
  pmsg := '';
  LISTA_PED(0) := p_num_pedido;
  LISTA_PED(1) := p_num_pedido_resf;

  BEGIN
     SELECT txvenda
       INTO vntxvenda
       FROM pcconsum;

     SELECT nvl(usanumcarvendabalcao,'N')
       INTO vsUsaNumcarVendaBalcao
       FROM pcconsum;

     SELECT nvl(fechacarregautvendabalcao,'S')
       INTO vsFechaCarregAutVendaBalcao
       FROM pcconsum;

     SELECT NVL(VALOR, 'N')
       INTO vnDescRestTranspBalc
       FROM PCPARAMFILIAL
      WHERE NOME = 'DESCONSIDERARESTRITRANSPBALCAO'
        AND CODFILIAL IN (SELECT CODFILIAL
                            FROM PCPEDC
                           WHERE NUMPED = pnumped);

     SELECT NVL(VALOR, 'N')
       INTO vnDescRestTranspBalcReserva
       FROM PCPARAMFILIAL
      WHERE NOME = 'DESCONSIDERARESTRITRANSBRESERVA'
        AND CODFILIAL IN (SELECT CODFILIAL
                            FROM PCPEDC
                           WHERE NUMPED = pnumped);
  EXCEPTION
     WHEN OTHERS THEN
        pmsg := SQLCODE || ' - ' || SQLERRM || ' -0- Erro ao buscar parametros do sistema';
     RAISE;
  END;

  -- Verificar se o pedido é Balcão Reserva para gerar nr. de carregamento diferente
  SELECT origemped,
         numcar,
         codemitente,
         condvenda
    INTO vsorigemped,
         vnnumcar,
         vncodemitente,
         vnCONDVENDA
    FROM pcpedc
   WHERE pcpedc.numped = pnumped;

   IF (vsorigemped = 'B') AND (vnDescRestTranspBalc = 'S') THEN
     pmsg := 'Sistema configurado para desconsiderar restrição de transporte parâmetro 4060';
     RETURN;
   END IF;

   IF (vsorigemped = 'R') AND (vnDescRestTranspBalcReserva = 'S') THEN
     pmsg := 'Sistema configurado para desconsiderar restrição de transporte parâmetro 4061';
     RETURN;
   END IF;

  -- Itens com restrição de transporte igual a 'S'
  SELECT COUNT (*)
    INTO vicontadorsim
    FROM pcpedi, pcprodut
   WHERE pcpedi.numped = pnumped
     AND pcpedi.codprod = pcprodut.codprod
     AND NVL (pcprodut.restricaotransp, 'N') = 'S';

  -- Itens com restrição de transporte igual a 'R'
  SELECT COUNT (*)
    INTO vicontadorref
    FROM pcpedi, pcprodut
   WHERE pcpedi.numped = pnumped
     AND pcpedi.codprod = pcprodut.codprod
     AND NVL (pcprodut.restricaotransp, 'N') = 'R';

  -- Itens sem restrição de transporte
  SELECT COUNT (*)
    INTO vicontadornao
    FROM pcpedi, pcprodut
   WHERE pcpedi.numped = pnumped
     AND pcpedi.codprod = pcprodut.codprod
     AND NVL (pcprodut.restricaotransp, 'N') = 'N';

  -- Verificar se vai gerar novo pedido
  IF (vicontadorsim > 0) OR (vicontadorref > 0) THEN
  BEGIN
    -- Buscar novo numero do pedido para produtos com restrição 'S'
    -- se exitir pedido sem restrição com restrição = 'N'
    IF (vicontadorsim > 0) AND (   (vicontadornao > 0) OR (vicontadorref > 0)) THEN
      SELECT codusur,
             codfilial
        INTO vncodusur,
             vscodfilial
        FROM pcpedc
       WHERE numped = pnumped;

      vnproxnumped := EXTRAIR_PROX_NUMPED(LISTA_PED);

        IF NVL(vnproxnumped, 0) <= 0 then
          iTentativa := 0;
          WHILE nvl(vnproxnumped, 0) = 0 LOOP
            vnproxnumped := ferramentas.F_PROX_NUMPED(vncodusur);
            IF vnproxnumped > 0 THEN
              EXIT;
            END IF;
            iTentativa := iTentativa + 1;
            IF iTentativa > 50 and nvl(vnproxnumped, 0) = 0 THEN
              pmsg := ' -0.1.- Tentativas excedidas ao gerar vnproxnumped. Erro ao gerar pedido com restricao de Transporte.';
              RETURN;
            END IF;
          END LOOP;
        END IF;

      -- Tarefa 79698
     IF vsorigemped = 'R' THEN
          iTentativa := 0;
          WHILE nvl(vnnumcar01, 0) = 0 LOOP
            vnnumcar01 := FERRAMENTAS.F_PROX_NUMCAR;
            IF vnnumcar01 > 0 THEN
              EXIT;
            END IF;
            iTentativa := iTentativa + 1;
            IF iTentativa > 50 and nvl(vnnumcar01, 0) = 0 THEN
              pmsg := ' -0.2.- Tentativas excedidas ao gerar numero de carregamento. Erro ao gerar pedido com restricao de Transporte.';
              RETURN;
            END IF;
          END LOOP;
          -- Fim tarefa 79698
        END IF;
      END IF;

    -- Buscar novo numero do pedido para produtos com restrição 'R'
    -- somente se existir itens sem restrição, caso contrário mantem no pedido original
      IF (vicontadorref > 0) AND (vicontadornao > 0) THEN
        SELECT codusur,
               codfilial
          INTO vncodusur,
               vscodfilial
          FROM pcpedc
         WHERE numped = pnumped;

        vnproxnumpedref := EXTRAIR_PROX_NUMPED(LISTA_PED);

        IF NVL(vnproxnumpedref, 0) <= 0 then
          iTentativa := 0;
          WHILE nvl(vnproxnumpedref, 0) = 0 LOOP
            vnproxnumpedref := ferramentas.F_PROX_NUMPED(vncodusur);
            IF vnproxnumpedref > 0 THEN
              EXIT;
            END IF;
            iTentativa := iTentativa + 1;
            IF iTentativa > 50 and nvl(vnproxnumpedref, 0) = 0 THEN
              pmsg := ' -0.3.- Tentativas excedidas ao gerar vnproxnumpedref. Erro ao gerar pedido com restricao de Transporte.';
              RETURN;
            END IF;
          END LOOP;
        END IF;

        -- Tarefa 79698
        IF vsorigemped = 'R' THEN
          iTentativa := 0;
          WHILE iTentativa < 50 and nvl(vnnumcar02, 0) = 0 LOOP
            vnnumcar02 := FERRAMENTAS.F_PROX_NUMCAR;
            IF vnnumcar02 > 0 THEN
              EXIT;
            END IF;
            iTentativa := iTentativa + 1;
            IF iTentativa > 50 and nvl(vnnumcar02, 0) = 0 THEN
              pmsg := ' -0.4.- Tentativas excedidas ao gerar numero de carregamento. Erro ao gerar pedido com restricao de Transporte.';
              RETURN;
            END IF;
          END LOOP;
          -- Fim tarefa 79698
      END IF;

     END IF;

    pnumpedrest := vnproxnumped;

  EXCEPTION
    WHEN OTHERS THEN
      pmsg := SQLCODE || ' - ' || SQLERRM || ' -1- Erro ao buscar numeracao de pedido';
  END;

  BEGIN
    -- Gerando pedido com restrição igual a 'S'
    IF (vnproxnumped > 0) THEN
      -- gerando itens para o novo pedido quando pcprodut.restricaotransp = 'S'

       FOR DADOS IN (SELECT PCPEDI.*
                  FROM PCPEDI
                 WHERE PCPEDI.NUMPED = PNUMPED
                   AND EXISTS
                 (SELECT CODPROD
                          FROM PCPRODUT
                         WHERE PCPRODUT.CODPROD = PCPEDI.CODPROD
                           AND NVL(PCPRODUT.RESTRICAOTRANSP, 'N') = 'S')) LOOP

        DADOS.NUMPED   := VNPROXNUMPED;
        DADOS.NUMCAR := CASE WHEN(VSORIGEMPED = 'R') THEN VNNUMCAR01 ELSE DADOS.NUMCAR END;

        INSERT INTO PCPEDI VALUES DADOS;

       END LOOP;


      -- Pablo (11/09/2008)
      -- Atualizando pcpedicesta quando pcprodut.restricaotransp = 'S'
      UPDATE pcpedicesta SET
        numped = vnproxnumped
      WHERE (numped, codprod, numseq) IN (SELECT pnumped, -- pedido anterior
                                                 pcpedi.codprod,
                                                 pcpedi.numseq
                                            FROM pcpedi,
                                                 pcprodut
                                           WHERE pcpedi.numped = vnproxnumped -- novo pedido que acabou de se criado
                                             AND pcpedi.codprod = pcprodut.codprod
                                             AND NVL (pcprodut.restricaotransp, 'N') = 'S');

      -- Correção da atualiza do PCORIGEMPRECO
      -- Atualizando pcorigempreco quando pcprodut.restricaotransp = 'S'
      UPDATE pcorigempreco SET
             numped = vnproxnumped
       WHERE (numped, codprod, numseq) IN (SELECT pnumped, -- pedido anterior
                                                  pcpedi.codprod,
                                                  pcpedi.numseq
                                             FROM pcpedi,
                                                  pcprodut
                                            WHERE pcpedi.numped = vnproxnumped -- novo pedido que acabou de se criado
                                              AND pcpedi.codprod = pcprodut.codprod
                                              AND NVL (pcprodut.restricaotransp, 'N') = 'S');

      -- Fim Pablo (11/09/2008)

      -- Totalizando pedido quando pcprodut.restricaotransp = 'S'
      SELECT COUNT (*) qt,
             SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.vlcustofin, 0)) vlcustofin,
             SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.vlcustoreal, 0)) vlcustoreal,
             SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.vlcustocont, 0)) vlcustocont,
             SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.vlcustorep, 0)) vlcustorep,
             SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.ptabela, 0)) vltabela,
             SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.pvenda, 0)) vlatend,
             SUM ( (NVL (pcpedi.qt, 0) + NVL (pcpedi.qtfalta, 0)) * NVL(pcpedi.pvenda, 0) ) vltotal,
             SUM (NVL (pcpedi.qt, 0) * NVL (pcprodut.pesobruto, 0)) totpeso,
             SUM (NVL (pcpedi.qt, 0) * NVL (pcprodut.volume, 0)) totvolume,
             SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.PBONIFIC, 0)) pbonific,
             SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.VLVERBACMV, 0)) VLVERBACMV,
             SUM (NVL (pcpedi.qt, 0) * NVL (pcpedi.VLVERBACMVCLI, 0)) VLVERBACMVCLI
        INTO vnnumitens,
             vnvlcustofin,
             vnvlcustoreal,
             vnvlcustocont,
             vnvlcustorep,
             vnvltabela,
             vnvlatend,
             vnvltotal,
             vntotpeso,
             vntotvolume,
             vntotbonific,
             vnvlverbacmv,
             vnvlverbacmvcli
        FROM pcpedi, pcprodut
       WHERE pcpedi.codprod = pcprodut.codprod
         AND pcpedi.numped = vnproxnumped
         AND pcpedi.qt > 0;

      IF (vntotbonific = vnvlatend) THEN
        vsgerarTv5 := 'S';
      ELSE
        vsgerarTv5 := 'N';
      END IF;

      FOR DADOS IN (SELECT PCPEDC.*
                  FROM PCPEDC
                 WHERE PCPEDC.NUMPED = PNUMPED) LOOP

        DADOS.NUMPED := VNPROXNUMPED;
        DADOS.NUMCAR := CASE WHEN(VSORIGEMPED = 'R') THEN VNNUMCAR01 ELSE DADOS.NUMCAR END;
        DADOS.NUMITENS := vnnumitens;
        IF vnCONDVENDA <> 8 THEN
          DADOS.VLATEND  := vnvlatend;
          DADOS.VLTABELA  := vnvltabela;
          DADOS.VLCUSTOREAL := vnvlcustoreal;
          DADOS.VLCUSTOFIN  := vnvlcustofin;
        END IF;
        DADOS.VLTOTAL := vnvltotal;
        DADOS.TOTPESO := vntotpeso;
        DADOS.TOTVOLUME  := vntotvolume;
        DADOS.CODCOB  := CASE WHEN(vsgerarTv5 = 'S') THEN 'BNF' ELSE DADOS.CODCOB END;
        DADOS.CONDVENDA  := CASE WHEN(vsgerarTv5 = 'S') THEN 5 ELSE DADOS.CONDVENDA END;

        INSERT INTO PCPEDC VALUES DADOS;

       END LOOP;

       FOR DADOS IN (SELECT *
                        FROM PCPEDCVCTO
                       WHERE NUMPED = PNUMPED) LOOP

        DADOS.NUMPED := VNPROXNUMPED;

        INSERT INTO PCPEDCVCTO VALUES DADOS;

       END LOOP;

      --tarefa 3099.042129.2014
      BEGIN
        PKG_MOTIVOBLOQUEIO.VALIDAMOTIVOSBLOQUEIO(vnproxnumped, vncodusur, 316, 0);
      EXCEPTION
        WHEN OTHERS THEN
          pmsg := SQLCODE || ' - ' || SQLERRM || ' -2- Erro validar motivos de bloqueios do novo pedido com restrição de transporte.';
          RAISE;
      END;

      --tarefa 85855
      FOR reg_itens IN (SELECT pcpedi.codprod,
                               pcpedi.codusur,
                               pcpedi.numseq
                          FROM pcpedi,
                               pcprodut
                         WHERE pcpedi.numped = pnumped
                           AND pcpedi.codprod = pcprodut.codprod
                           AND NVL (pcprodut.restricaotransp, 'N') = 'S')
      LOOP
        vbsaldorca := pc_pkg_controlarsaldorca.ccrca_incluir_item_pedido(vncodemitente,
                                                                         300,
                                                                         reg_itens.codusur,
                                                                         vnproxnumped,
                                                                         reg_itens.codprod,
                                                                         reg_itens.numseq);
      END LOOP;

        IF vsorigemped = 'R' THEN

          FOR DADOS_CARREG IN (SELECT * FROM PCCARREG WHERE NUMCAR = vnnumcar) LOOP

            FOR DADOS_PEDIDO IN (SELECT pcpedc.condvenda,
                                        SUM(pcpedi.qt * pcpedi.pvenda) AS VLTOTAL,
                                        SUM(NVL(pcpedi.qt, 0) *
                                            NVL(pcprodut.pesobruto, 0)) AS TOTPESO,
                                        SUM(NVL(pcpedi.qt, 0) *
                                            NVL(pcprodut.volume, 0)) AS TOTVOLUME
                                   FROM pcpedc, pcpedi, pcprodut
                                  WHERE pcpedi.codprod = pcprodut.codprod
                                    AND pcpedc.numped = pcpedi.numped
                                    AND pcpedc.numped = vnproxnumped
                                    group by pcpedc.condvenda) LOOP

              DADOS_CARREG.NUMCAR      := vnnumcar01;
              DADOS_CARREG.DTSAIDA     := TRUNC(SYSDATE);
              DADOS_CARREG.TOTPESO     := DADOS_PEDIDO.TOTPESO;
              DADOS_CARREG.TOTVOLUME   := DADOS_PEDIDO.TOTVOLUME;
              DADOS_CARREG.VLTOTAL     := DADOS_PEDIDO.VLTOTAL;
              DADOS_CARREG.DESTINO     := 'VENDA BALCAO';
              DADOS_CARREG.DATAMON     := TRUNC(SYSDATE);
              DADOS_CARREG.CODVEICULO  := 0;
              DADOS_CARREG.CODFUNCMON  := 0;
              DADOS_CARREG.DT_CANCEL   := '';
              DADOS_CARREG.DTFECHA     := CASE WHEN NOT(DADOS_PEDIDO.CONDVENDA = 13
                                               AND vsUsaNumcarVendaBalcao = 'S')
                                               AND vsFechaCarregAutVendaBalcao = 'S'
                                               THEN TRUNC(SYSDATE)
                                                 ELSE ''
                                                   END;
              DADOS_CARREG.HORAFECHA   := '';
              DADOS_CARREG.MINUTOFECHA := '';
              DADOS_CARREG.OBSFATUR    := '';
              DADOS_CARREG.NUMNOTAS    := 1;

              INSERT INTO PCCARREG VALUES DADOS_CARREG;

            END LOOP;
          END LOOP;
        END IF;

        FOR DADOS IN (SELECT *
                           FROM PCVENDACONSUM
                          WHERE NUMPED = pnumped) LOOP

           DADOS.NUMPED := vnproxnumped;

           INSERT INTO PCVENDACONSUM VALUES DADOS;

         END LOOP;

      --tarefa 85855
      FOR reg IN (SELECT pcpedi.codprod,
                         pcpedi.codusur,
                         pcpedi.numseq,
                         pcpedi.qt
                    FROM pcpedi,
                         pcprodut
                   WHERE numped = pnumped
                     AND pcprodut.codprod = pcpedi.codprod
                     AND NVL (restricaotransp, 'N') = 'S')
      LOOP
        -- Exclusao dos Itens quando pcprodut.restricaotransp  = 'S'
        vbsaldorca := pc_pkg_controlarsaldorca.ccrca_excluir_item_pedido(vncodemitente,
                                                                         300,
                                                                         reg.codusur,
                                                                         pnumped,
                                                                         reg.codprod,
                                                                         reg.numseq,
                                                                         reg.qt);

        begin
          select *
            into ROWpcpedipcpedifv
            from pcpedipcpedifv
          where pcpedipcpedifv.numped = pnumped and
                pcpedipcpedifv.codprod = reg.codprod and
                pcpedipcpedifv.numseq = reg.numseq;
        exception
          WHEN OTHERS THEN
            ROWpcpedipcpedifv := null ;
        END;

        DELETE FROM pcpedi
              WHERE numped = pnumped
                AND codprod = reg.codprod
                AND numseq = reg.numseq;

        begin

         if (nvl(ROWpcpedipcpedifv.numped, 0) > 0) then
            ROWpcpedipcpedifv.numped := vnproxnumped;
            insert into pcpedipcpedifv values ROWpcpedipcpedifv;
         end if;

        exception
          WHEN OTHERS THEN
            pmsg := SQLCODE || '-' || SQLERRM ;
        END;

      END LOOP;
   END IF;                -- IF (vicontadorsim > 0) AND (vnproxnumped > 0)

   -- Gerando pedido com restrição igual a 'R'
   IF (vnproxnumpedref > 0) THEN
     -- gerando itens para o novo pedido quando pcprodut.restricaotransp = 'S'


      FOR DADOS IN (SELECT PCPEDI.*
                      FROM PCPEDI
                     WHERE PCPEDI.NUMPED = PNUMPED
                           AND EXISTS
                           (SELECT CODPROD
                                    FROM PCPRODUT
                                   WHERE PCPRODUT.CODPROD = PCPEDI.CODPROD
                                     AND NVL(PCPRODUT.RESTRICAOTRANSP, 'N') = 'R')) LOOP

        DADOS.NUMPED   := vnproxnumpedref;
        DADOS.NUMCAR := CASE WHEN(VSORIGEMPED = 'R') THEN vnnumcar02 ELSE DADOS.NUMCAR END;

        INSERT INTO PCPEDI VALUES DADOS;

       END LOOP;

     -- Pablo (11/09/2008)
     -- Atualizando pcpedicesta quando pcprodut.restricaotransp = 'S'
     UPDATE pcpedicesta SET
       numped = vnproxnumpedref
      WHERE (numped, codprod, numseq) IN (SELECT pnumped, -- pedido anterior
                                                 pcpedi.codprod,
                                                 pcpedi.numseq
                                            FROM pcpedi,
                                                 pcprodut
                                           WHERE pcpedi.numped = vnproxnumpedref -- novo pedido que acabou de se criado
                                             AND pcpedi.codprod = pcprodut.codprod
                                             AND NVL (pcprodut.restricaotransp, 'N') = 'R');

     -- Correção da atualiza do PCORIGEMPRECO
     -- Atualizando pcorigempreco quando pcprodut.restricaotransp = 'S'
     UPDATE pcorigempreco SET
            numped = vnproxnumpedref
      WHERE (numped, codprod, numseq) IN (SELECT pnumped, -- pedido anterior
                                                 pcpedi.codprod,
                                                 pcpedi.numseq
                                            FROM pcpedi,
                                                 pcprodut
                                           WHERE pcpedi.numped = vnproxnumpedref -- novo pedido que acabou de se criado
                                             AND pcpedi.codprod = pcprodut.codprod
                                             AND NVL (pcprodut.restricaotransp, 'N') = 'R');
     -- Fim Pablo (11/09/2008)

     -- Atualizando CVM para o novo pedido quando pcprodut.restricaotransp = 'S'
     UPDATE pcpedi SET
            vlcustofin = (SELECT NVL (pcest.custofin, 0)
                            FROM pcest
                           WHERE pcest.codprod = pcpedi.codprod
                             AND pcest.codfilial = vscodfilial),
            vlcustoreal = (SELECT NVL (pcest.custoreal, 0)
                             FROM pcest
                            WHERE pcest.codprod = pcpedi.codprod
                              AND pcest.codfilial = vscodfilial)
      WHERE numped = vnproxnumpedref
        AND EXISTS (SELECT codst
                      FROM pctribut
                     WHERE codst = pcpedi.codst);

     UPDATE pcpedi SET
            vlcustofin =  (SELECT NVL(pcpedi.vlcustofin, 0) -
                                  (NVL (pcpedi.vlcustofin, 0) * (NVL (perdesccusto, 0) / 100))
                             FROM pctribut
                            WHERE pctribut.codst = pcpedi.codst),
            vlcustoreal = (SELECT NVL (pcpedi.vlcustoreal, 0) -
                                  (NVL (pcpedi.vlcustoreal, 0) * (NVL (perdesccusto, 0) / 100))
                             FROM pctribut
                            WHERE pctribut.codst = pcpedi.codst)
      WHERE numped = vnproxnumpedref
        AND EXISTS (SELECT codst
                      FROM pctribut
                     WHERE codst = pcpedi.codst);

     UPDATE pcpedi SET
            vlcustofin = (SELECT pcpedi.vlcustofin +
                                 NVL (pcpedi.st, 0) +
                                 NVL (pcpedi.vlipi, 0) +
                                 (
                                     NVL(pcpedi.pvenda, 0) *
                                    (NVL(vntxvenda, 0) / 100)
                                 ) +
                                 (
                                    NVL(pcpedi.pvenda, 0) *
                                    (NVL(pcpedi.percom, 0) / 100)
                                 ) +
                                 (
                                   (
                                      NVL(pcpedi.pvenda, 0) -
                                      NVL (pcpedi.st, 0) -
                                      NVL (pcpedi.vlipi, 0)
                                   ) *
                                   (NVL (pctribut.codicmtab, 0) / 100)
                                 )
                            FROM pctribut
                           WHERE codst = pcpedi.codst),
            vlcustoreal = (SELECT pcpedi.vlcustoreal +
                                  NVL(pcpedi.st, 0) +
                                  NVL(pcpedi.vlipi, 0) +
                                  (
                                     NVL(pcpedi.pvenda, 0) *
                                    (NVL (vntxvenda, 0) / 100)
                                  ) +
                                  (
                                     NVL (pcpedi.pvenda, 0) *
                                    (NVL (pcpedi.percom, 0) / 100)
                                  ) +
                                  (
                                    (
                                       NVL(pcpedi.pvenda, 0) -
                                       NVL(pcpedi.st, 0) -
                                       NVL(pcpedi.vlipi, 0)
                                    ) *
                                    (NVL (pctribut.codicmtab, 0) / 100)
                                  )
                             FROM pctribut
                            WHERE codst = pcpedi.codst)
      WHERE numped = vnproxnumpedref
        AND EXISTS (SELECT codst
                      FROM pctribut
                     WHERE codst = pcpedi.codst);
     -- FIM RECALCULO DO CMV

     -- Totalizando pedido quando pcprodut.restricaotransp = 'S'
     SELECT COUNT (*) qt,
            SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.vlcustofin, 0)) vlcustofin,
            SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.vlcustoreal, 0)) vlcustoreal,
            SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.vlcustocont, 0)) vlcustocont,
            SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.vlcustorep, 0)) vlcustorep,
            SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.ptabela, 0)) vltabela,
            SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.pvenda, 0)) vlatend,
            SUM(
                  (
                    NVL(pcpedi.qt, 0) +
                    NVL(pcpedi.qtfalta, 0)
                  ) * NVL (pcpedi.pvenda, 0)
                ) vltotal,
            SUM(NVL(pcpedi.qt, 0) * NVL(pcprodut.pesobruto, 0)) totpeso,
            SUM(NVL(pcpedi.qt, 0) * NVL(pcprodut.volume, 0)) totvolume,
            SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.PBONIFIC, 0)) pbonific
       INTO vnnumitens,
            vnvlcustofin,
            vnvlcustoreal,
            vnvlcustocont,
            vnvlcustorep,
            vnvltabela,
            vnvlatend,
            vnvltotal,
            vntotpeso,
            vntotvolume,
            vntotbonific
       FROM pcpedi,
            pcprodut
      WHERE pcpedi.codprod = pcprodut.codprod
        AND pcpedi.numped = vnproxnumpedref
        AND pcpedi.qt > 0;

     IF (vntotbonific = vnvlatend) THEN
       vsgerarTv5 := 'S';
     ELSE
       vsgerarTv5 := 'N';
     END IF;

     FOR DADOS IN (SELECT PCPEDC.*
                  FROM PCPEDC
                 WHERE PCPEDC.NUMPED = PNUMPED) LOOP

        DADOS.NUMPED := vnproxnumpedref;
        DADOS.NUMCAR := CASE WHEN(VSORIGEMPED = 'R') THEN vnnumcar02 ELSE DADOS.NUMCAR END;
        DADOS.NUMITENS := vnnumitens;
        IF vnCONDVENDA <> 8 THEN
          DADOS.VLATEND  := vnvlatend;
          DADOS.VLTABELA  := vnvltabela;
          DADOS.VLCUSTOREAL := vnvlcustoreal;
          DADOS.VLCUSTOFIN  := vnvlcustofin;
        END IF;
        DADOS.VLTOTAL := vnvltotal;
        DADOS.TOTPESO := vntotpeso;
        DADOS.TOTVOLUME  := vntotvolume;
        DADOS.CODCOB  := CASE WHEN(vsgerarTv5 = 'S') THEN 'BNF' ELSE DADOS.CODCOB END;
        DADOS.CONDVENDA  := CASE WHEN(vsgerarTv5 = 'S') THEN 5 ELSE DADOS.CONDVENDA END;

        INSERT INTO PCPEDC VALUES DADOS;

     END LOOP;

      FOR DADOS IN (SELECT *
                        FROM PCPEDCVCTO
                       WHERE NUMPED = PNUMPED) LOOP

        DADOS.NUMPED := vnproxnumpedref;

        INSERT INTO PCPEDCVCTO VALUES DADOS;

       END LOOP;

     BEGIN
       PKG_MOTIVOBLOQUEIO.VALIDAMOTIVOSBLOQUEIO(PNUMPED, vncodusur, 316, 0);
     EXCEPTION
       WHEN OTHERS THEN
         pmsg := SQLCODE || ' - ' || SQLERRM || ' -2- Erro validar motivos de bloqueios do novo pedido com restrição de transporte.';
       RAISE;
     END;

     --tarefa 85855
     FOR reg_itens IN (SELECT pcpedi.codprod,
                              pcpedi.codusur,
                              pcpedi.numseq
                         FROM pcpedi,
                              pcprodut
                        WHERE pcpedi.numped = pnumped
                          AND pcpedi.codprod = pcprodut.codprod
                          AND NVL(pcprodut.restricaotransp, 'N') = 'R')
     LOOP
       vbsaldorca := pc_pkg_controlarsaldorca.ccrca_incluir_item_pedido(vncodemitente,
                                                                        300,
                                                                        reg_itens.codusur,
                                                                        vnproxnumpedref,
                                                                        reg_itens.codprod,
                                                                        reg_itens.numseq);
     END LOOP;

       IF vsorigemped = 'R' THEN

          FOR DADOS_CARREG IN (SELECT * FROM PCCARREG WHERE NUMCAR = vnnumcar) LOOP

            FOR DADOS_PEDIDO IN (SELECT pcpedc.condvenda,
                                        SUM(pcpedi.qt * pcpedi.pvenda) AS VLTOTAL,
                                        SUM(NVL(pcpedi.qt, 0) *
                                            NVL(pcprodut.pesobruto, 0)) AS TOTPESO,
                                        SUM(NVL(pcpedi.qt, 0) *
                                            NVL(pcprodut.volume, 0)) AS TOTVOLUME
                                   FROM pcpedc, pcpedi, pcprodut
                                  WHERE pcpedi.codprod = pcprodut.codprod
                                    AND pcpedc.numped = pcpedi.numped
                                    AND pcpedc.numped = vnproxnumpedref
                                    group by pcpedc.condvenda) LOOP

              DADOS_CARREG.NUMCAR      := vnnumcar02;
              DADOS_CARREG.DTSAIDA     := TRUNC(SYSDATE);
              DADOS_CARREG.TOTPESO     := DADOS_PEDIDO.TOTPESO;
              DADOS_CARREG.TOTVOLUME   := DADOS_PEDIDO.TOTVOLUME;
              DADOS_CARREG.VLTOTAL     := DADOS_PEDIDO.VLTOTAL;
              DADOS_CARREG.DESTINO     := 'VENDA BALCAO';
              DADOS_CARREG.DATAMON     := TRUNC(SYSDATE);
              DADOS_CARREG.CODVEICULO  := 0;
              DADOS_CARREG.CODFUNCMON  := 0;
              DADOS_CARREG.DT_CANCEL   := '';
              DADOS_CARREG.DTFECHA     := CASE WHEN NOT(DADOS_PEDIDO.CONDVENDA = 13
                                               AND vsUsaNumcarVendaBalcao = 'S')
                                               AND vsFechaCarregAutVendaBalcao = 'S'
                                               THEN TRUNC(SYSDATE)
                                                 ELSE ''
                                                   END;
              DADOS_CARREG.HORAFECHA   := '';
              DADOS_CARREG.MINUTOFECHA := '';
              DADOS_CARREG.OBSFATUR    := '';
              DADOS_CARREG.NUMNOTAS    := 1;

              INSERT INTO PCCARREG VALUES DADOS_CARREG;

            END LOOP;
          END LOOP;
        END IF;

     FOR DADOS IN (SELECT *
                           FROM PCVENDACONSUM
                          WHERE NUMPED = pnumped) LOOP

           DADOS.NUMPED := vnproxnumpedref;

           INSERT INTO PCVENDACONSUM VALUES DADOS;

     END LOOP;

     -- Exclusao dos Itens quando pcprodut.restricaotransp  = 'R'
     --tarefa 85855
     FOR reg IN (SELECT pcpedi.codprod,
                        pcpedi.codusur,
                        pcpedi.numseq,
                        pcpedi.qt
                   FROM pcpedi,
                        pcprodut
                  WHERE numped = pnumped
                    AND pcprodut.codprod = pcpedi.codprod
                    AND NVL (restricaotransp, 'N') = 'R')
     LOOP
       vbsaldorca := pc_pkg_controlarsaldorca.ccrca_excluir_item_pedido(vncodemitente,
                                                                        300,
                                                                        reg.codusur,
                                                                        pnumped,
                                                                        reg.codprod,
                                                                        reg.numseq,
                                                                        reg.qt);

        begin
          select *
            into ROWpcpedipcpedifv
            from pcpedipcpedifv
          where pcpedipcpedifv.numped = pnumped and
                pcpedipcpedifv.codprod = reg.codprod and
                pcpedipcpedifv.numseq = reg.numseq;
        exception
          WHEN OTHERS THEN
            ROWpcpedipcpedifv := null ;
        END;


       -- Exclusao dos Itens quando pcprodut.restricaotransp  = 'S'
       DELETE FROM pcpedi
             WHERE numped = pnumped
               AND codprod = reg.codprod
               AND numseq = reg.numseq;


        begin

         if (nvl(ROWpcpedipcpedifv.numped, 0) > 0) then
            ROWpcpedipcpedifv.numped := vnproxnumpedref;
            insert into pcpedipcpedifv values ROWpcpedipcpedifv;
         end if;

        exception
          WHEN OTHERS THEN
            pmsg := SQLCODE || '-' || SQLERRM ;
        END;
     END LOOP;
   END IF;             -- IF (vicontadorref > 0) AND (vnproxnumpedref > 0)

   -- Totalizando o pedido original após a exclusão dos itens
   SELECT COUNT (*) qt,
          SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.vlcustofin, 0)) vlcustofin,
          SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.vlcustoreal, 0)) vlcustoreal,
          SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.vlcustocont, 0)) vlcustocont,
          SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.vlcustorep, 0)) vlcustorep,
          SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.ptabela, 0)) vltabela,
          SUM(NVL(pcpedi.qt, 0) * NVL(pcpedi.pvenda, 0)) vlatend,
          SUM(
               (  NVL(pcpedi.qt, 0) + NVL (pcpedi.qtfalta, 0)  ) *
               NVL (pcpedi.pvenda, 0)
             ) vltotal,
          SUM( NVL(pcpedi.qt, 0) * NVL(pcprodut.pesobruto, 0) ) totpeso,
          SUM( NVL(pcpedi.qt, 0) * NVL(pcprodut.volume, 0) ) totvolume,
          SUM( NVL(pcpedi.qt, 0) * NVL(pcpedi.PBONIFIC, 0) ) pbonific
     INTO vnnumitens,
          vnvlcustofin,
          vnvlcustoreal,
          vnvlcustocont,
          vnvlcustorep,
          vnvltabela,
          vnvlatend,
          vnvltotal,
          vntotpeso,
          vntotvolume,
          vntotbonific
     FROM pcpedi,
          pcprodut
    WHERE pcpedi.codprod = pcprodut.codprod
      AND pcpedi.numped = pnumped
      AND pcpedi.qt > 0;

   IF (vntotbonific = vnvlatend) THEN
     vsgerarTv5 := 'S';
   ELSE
     vsgerarTv5 := 'N';
   END IF;

  IF vnCONDVENDA = 8 THEN
    UPDATE pcpedc
       SET numitens  = vnnumitens,
           vltotal   = vnvltotal,
           totpeso   = vntotpeso,
           totvolume = vntotvolume,
           vlbonific = vntotbonific,
           condvenda = decode(vsgerarTv5, 'S', 5, condvenda),
           codcob    = decode(vsgerarTv5, 'S', 'BNF', codcob)
     WHERE numped = pnumped;
  ELSE
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
           totvolume   = vntotvolume,
           vlbonific   = vntotbonific,
           condvenda   = decode(vsgerarTv5, 'S', 5, condvenda),
           codcob      = decode(vsgerarTv5, 'S', 'BNF', codcob)
     WHERE numped = pnumped;
  END IF;

   IF vsorigemped = 'R' THEN
     UPDATE pccarreg SET
       totpeso = vntotpeso,
       totvolume = vntotvolume,
       vltotal = vnvltotal
     WHERE numcar = vnnumcar;
   END IF;

   pnumpedrest := vnproxnumped;

   IF vnproxnumpedref > 0 THEN
     pnumpedrest := vnproxnumpedref;
   END IF;

   pmsg := 'Atenção! ' || CHR (13) || CHR (13) ||
           'Pedido ' || CHR (13) ||
           TO_CHAR (vnproxnumped) || CHR (13) ||
           TO_CHAR (vnproxnumpedref) || CHR (13) || CHR (13) ||
           'com restrição de transporte gerado com sucesso.';
   EXCEPTION
     WHEN OTHERS THEN
       pmsg := SQLCODE || ' - ' || SQLERRM || ' -2- Erro ao gerar pedido com restricao de Transporte';
     RAISE;
   END;
   END IF; -- IF ( vicontadorsim > 0 ) OR ( vicontadorref > 0 )

   -- Atualizando o(s) pedido(s) conforme a restrição
   IF (vicontadornao > 0) THEN
     UPDATE pcpedc SET
       restricaotransp = 'N'
     WHERE numped = pnumped;
   END IF;

   IF vicontadorsim > 0 THEN
     IF vnproxnumped IS NOT NULL THEN -- Gerou novo pedido com restrição 'S'
       UPDATE pcpedc SET
         restricaotransp = 'S',
         numpedorigem = pnumped
       WHERE numped = vnproxnumped;
     ELSE
       UPDATE pcpedc SET
         restricaotransp = 'S'
       WHERE numped = pnumped;
     END IF;
   END IF;

   IF vicontadorref > 0 THEN
     IF vnproxnumpedref IS NOT NULL THEN -- Gerou novo pedido com restrição 'R'
       UPDATE pcpedc SET
         restricaotransp = 'R',
         numpedorigem = pnumped
        WHERE numped = vnproxnumpedref;
     ELSE
       UPDATE pcpedc SET
         restricaotransp = 'R'
        WHERE numped = pnumped;
     END IF;
   END IF;
EXCEPTION
   WHEN OTHERS THEN
     pmsg := SQLCODE || ' - ' || SQLERRM || ' ERRO NA GERACAO DE PEDIDO COM RESTRICAO DE TRANSPORTE';
END prc_gerarpedidorestricaotransp;

