CREATE OR REPLACE PROCEDURE PRC_MED_CLASSEVENDA_CLIENTE(po_vOcorreramErros OUT VARCHAR2,
                                                        po_vMsgErros       OUT VARCHAR2)
/*******************************************************************************
 Nome         : PRC_MED_CLASSEVENDA_CLIENTE
 Descricão    : Procedimento para calcular a nova Classe de Venda do Cliente
 Parâmetros   : SAIDA:
                po_vOcorreramErros = Se ocorreram Erros (S/N)
                po_vMsgErros       = Mensagem de Erros
 Alteracão    : Anderson Silva - 01/08/2017 - Criação da Procedure HIS.01556.2017
********************************************************************************/
IS

 /***********************
  Declaração de Variáveis
  ***********************/

  -- Array de Dados dos Clientes
  TYPE TRecDadosCli        IS RECORD(
       vnCodCli            PCCLIENT.CODCLI%TYPE,
       dDATA_ULTIMA_COMPRA DATE,
       nQTDE_DUPLICATAS    NUMBER,
       nPONTOS             NUMBER,
       vnFaixaInicial      PCCONFIGCLASSECLIMEDRANK.FAIXAINICIAL%TYPE,
       vnFaixaFinal        PCCONFIGCLASSECLIMEDRANK.FAIXAFINAL%TYPE,
       vnMediaVenda        NUMBER,
       vCLASSEVENDA        PCCLIENT.CLASSEVENDA%TYPE);
  vrDadosCli               TRecDadosCli;
  TYPE TTvClientes         IS TABLE OF TRecDadosCli INDEX BY BINARY_INTEGER;
  vtClientes               TTvClientes;

  -- Listas de Dados do Cliente
  TYPE TTListaCodCli       IS TABLE OF PCCLIENT.CODCLI%TYPE INDEX BY BINARY_INTEGER;
  vtListaCodCli            TTListaCodCli;
  TYPE TTListaClasseVenda  IS TABLE OF PCCLIENT.CLASSEVENDA%TYPE INDEX BY BINARY_INTEGER;
  vtListaClasseVenda       TTListaClasseVenda;

  -- Qtde Dias Ultima Compra
  vnQtdeDiasUltCompra      NUMBER;
  -- Qtde Dias Vencimento
  vnQtdeDiasVencimento     NUMBER;
  -- Classe Outros
  vvClasseVendaOutros      PCCLIENT.CLASSEVENDA%TYPE;

  -- Tipo de Juros
  vvTipoJuros              VARCHAR2(1);
  -- Pontos
  vnPontos                 NUMBER;
  -- Pontuação Média
  vnPontuacaoMedia         NUMBER;

  -- Classe de Venda
  vvClasseVenda            PCCLIENT.CLASSEVENDA%TYPE;

  -- VariÃ¡veis da tabela
  vvAbaterDevolucoes PCCONFIGCLASSECLIMED.ABATERDEVOLUCOES%TYPE;

  -- Data Inicial e Final
  vdDataInicial DATE;
  vdDataFinal   DATE;

 /***************************************
  ***************************************
  ** INICIO DO PROCESSAMENTO PRINCIPAL **
  ***************************************
  ***************************************/
BEGIN

 /*******************
  Inicializa Retornos
  *******************/
  po_vOcorreramErros := 'N';
  po_vMsgErros       := NULL;

 /*************************************
  Laço de Processamento da Configuração
  *************************************/
  FOR vc_Config IN (SELECT PCCONFIGCLASSECLIMED.CODCONFIG
                      FROM PCCONFIGCLASSECLIMED
                     WHERE (PCCONFIGCLASSECLIMED.SELECIONADA = 'S')) LOOP

   /***********************************************************************************************
    CONFIGURAÇÃO 1: PONTUAÇÃO DE CLIENTES REGRA POR ATRASO
    ******************************************************/
    IF (vc_Config.CODCONFIG = 1) THEN

      -----------------------
      -- Inicializa Variáveis
      -----------------------

      -- Qtde Dias Ultima Compra
      vnQtdeDiasUltCompra  := 180;

      -- Qtde Dias Vencimento
      vnQtdeDiasVencimento := 90;

      -- Classe Venda Outros
      vvClasseVendaOutros  := 'N';

     /**************************************
      Informação da Última Compra do Cliente
      **************************************/
      FOR vc_TotCliNF IN (SELECT PCCLIENT.CODCLI
                               , MAX(PCNFSAID.DTSAIDA) MAIOR_DTSAIDA
                            FROM PCCLIENT
                               , PCNFSAID
                           WHERE (PCCLIENT.CODCLI = PCNFSAID.CODCLI(+))
                           GROUP BY PCCLIENT.CODCLI) LOOP

        -- Código do Cliente
        vrDadosCli.vnCodCli            := vc_TotCliNF.CODCLI;
        -- Dados Última Compra
        vrDadosCli.dDATA_ULTIMA_COMPRA := vc_TotCliNF.MAIOR_DTSAIDA;
        -- Qtde Duplicatas
        vrDadosCli.nQTDE_DUPLICATAS    := 0;
        -- Pontos
        vrDadosCli.nPONTOS             := 0;
        -- Classe Venda
        vrDadosCli.vCLASSEVENDA        := NULL;

        -- Atualiza Array
        vtClientes(vc_TotCliNF.CODCLI) := vrDadosCli;

        -- Lista de Clientes inseridos no Array que é Indexado pelo Código do Cliente
        vtListaCodCli(NVL(vtListaCodCli.COUNT,0) + 1)           := vc_TotCliNF.CODCLI;
        -- Lista de Classe de Venda do Cliente
        vtListaClasseVenda(NVL(vtListaClasseVenda.COUNT,0) + 1) := NULL;

      END LOOP; -- Fim Laço Totalizadores

     /******************
      Laço de Duplicatas
      ******************/
      FOR vc_Duplicata IN (SELECT PCPREST.DUPLIC
                                , PCPREST.PREST
                                , PCPREST.DTEMISSAO
                                , PCPREST.DTVENC
                                , PCPREST.DTPAG
                                , PCPREST.CODCOB
                                , (TRUNC(SYSDATE) - PCPREST.DTEMISSAO) QTDE_DIAS_EMISSAO
                                , PCPREST.CODCLI
                                , (NVL(PCPREST.DTPAG,TRUNC(SYSDATE)) - PCPREST.DTVENC) DIAS_ATRASO
                                , TXPERMPREVISTO
                                , TXPERM
                             FROM PCPREST
                                , PCCOB
                                , PCNFSAID
                            WHERE (PCCOB.CODCOB = PCPREST.CODCOB)
                              AND (PCPREST.NUMTRANSVENDA = PCNFSAID.NUMTRANSVENDA(+))
                              AND (PCPREST.CODCOB NOT IN ('DEVP', 'DEVT', 'BNF', 'BNFT',
                                                          'BNFR', 'BNTR', 'BNRP', 'CRED','DESD',
                                                          'JUR'))
                              AND (PCPREST.DTCANCEL IS NULL)
                              AND (((PCPREST.DTPAG IS NULL) AND (PCPREST.DTVENC < TRUNC(SYSDATE))) OR  -->> Se ainda não pagou e já venceu OU
                                   ((PCPREST.DTPAG IS NOT NULL) AND (PCPREST.DTPAG > PCPREST.DTVENC))) -->> Se pagou depois do vencimento
                              AND (PCPREST.DTVENC >= (TRUNC(SYSDATE) - vnQtdeDiasVencimento))
                              ) LOOP

        -------------------------
        -- Define o Tipo de Juros
        -------------------------

        -- Se era Previsto Juros
        IF (NVL(vc_Duplicata.TXPERMPREVISTO,0) > 0) THEN
          -- Se pagou Juros a menor que o Previsto
          IF (NVL(vc_Duplicata.TXPERM,0) < NVL(vc_Duplicata.TXPERMPREVISTO,0)) THEN
            -- Com Juros a Menor
            vvTipoJuros := 'M';
          ELSE
            -- Com Juros
            vvTipoJuros := 'C';
          END IF;
        -- Se NÃO era Previsto Juros
        ELSE
          -- Se pagou Juros mesmo sem ser Previsto
          IF (NVL(vc_Duplicata.TXPERM,0) > 0) THEN
            -- Com Juros
            vvTipoJuros := 'C';
          ELSE
            -- Sem Juros
            vvTipoJuros := 'S';
          END IF;
        END IF;

        -----------------------
        -- Pesquisa a Pontuação
        -----------------------

        -- Inicializa Pontuação
        vnPontos := 0;

        -- Pesquisa primeiro para o Tipo Atendido pela Regra
        BEGIN
          SELECT PCCONFIGCLASSECLIMEDATRASO.PONTOS
            INTO vnPontos
            FROM PCCONFIGCLASSECLIMEDATRASO
           WHERE (PCCONFIGCLASSECLIMEDATRASO.CODCONFIG = vc_Config.CODCONFIG)
             AND (PCCONFIGCLASSECLIMEDATRASO.TIPOJUROS = vvTipoJuros)
             AND (vc_Duplicata.DIAS_ATRASO BETWEEN PCCONFIGCLASSECLIMEDATRASO.FAIXAINICIAL AND PCCONFIGCLASSECLIMEDATRASO.FAIXAFINAL)
             AND (ROWNUM = 1);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- Se não achar Pesquisa pelo Tipo "AMBOS"
            BEGIN
              SELECT PCCONFIGCLASSECLIMEDATRASO.PONTOS
                INTO vnPontos
                FROM PCCONFIGCLASSECLIMEDATRASO
               WHERE (PCCONFIGCLASSECLIMEDATRASO.CODCONFIG = vc_Config.CODCONFIG)
                 AND (PCCONFIGCLASSECLIMEDATRASO.TIPOJUROS = 'A') -->> AMBOS
                 AND (vc_Duplicata.DIAS_ATRASO BETWEEN PCCONFIGCLASSECLIMEDATRASO.FAIXAINICIAL AND PCCONFIGCLASSECLIMEDATRASO.FAIXAFINAL)
                 AND (ROWNUM = 1);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vnPontos := 0;
            END;
        END;

        -------------------------------
        -- Incrementa Pontos do Cliente
        -------------------------------

        -- Se Cliente Válido
        IF (vtClientes.EXISTS(vc_Duplicata.CODCLI)) THEN

          -- Incrementa Dados do Cliente
          vtClientes(vc_Duplicata.CODCLI).nQTDE_DUPLICATAS := NVL(vtClientes(vc_Duplicata.CODCLI).nQTDE_DUPLICATAS,0) + 1;
          vtClientes(vc_Duplicata.CODCLI).nPONTOS          := NVL(vtClientes(vc_Duplicata.CODCLI).nPONTOS,0)          + NVL(vnPontos,0);

        END IF;

      END LOOP; -- Fim: Laço de Duplicatas


      /********************************
      Definição da Classe dos Clientes
      ********************************/
      IF (vtListaCodCli.COUNT > 0) THEN
        FOR viIdxCli IN vtListaCodCli.FIRST..vtListaCodCli.LAST LOOP

          -- Pega Dados do Cliente do Array Indexado pelo Código do Cliente
          vrDadosCli := vtClientes(vtListaCodCli(viIdxCli));

          -- Se encontrou Duplicatas no Período
          IF (NVL(vrDadosCli.nQTDE_DUPLICATAS,0) > 0) THEN

            -- Calcula Pontuação Média
            vnPontuacaoMedia := TRUNC(NVL(vrDadosCli.nPONTOS,0) / NVL(vrDadosCli.nQTDE_DUPLICATAS,0));

            -- Pesquisa a Classe para a Pontuação Média
            BEGIN
              SELECT PCCONFIGCLASSECLIMEDRANK.CLASSEVENDA
                INTO vvClasseVenda
                FROM PCCONFIGCLASSECLIMEDRANK
               WHERE (PCCONFIGCLASSECLIMEDRANK.CODCONFIG = vc_Config.CODCONFIG)
                 AND (vnPontuacaoMedia BETWEEN PCCONFIGCLASSECLIMEDRANK.FAIXAINICIAL AND PCCONFIGCLASSECLIMEDRANK.FAIXAFINAL)
                 AND (ROWNUM = 1);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- Se não achar: Usar Classe OUTROS
                vvClasseVenda := vvClasseVendaOutros;
            END;

          -- Se não encontrou Duplicatas no Período
          ELSE

            -- Se Nunca Comprou OU
            -- Se Data Última Compra excedida
            IF ( (vrDadosCli.dDATA_ULTIMA_COMPRA IS NULL) OR
                 ((vrDadosCli.dDATA_ULTIMA_COMPRA IS NOT NULL) AND ((TRUNC(SYSDATE) - vrDadosCli.dDATA_ULTIMA_COMPRA) >= vnQtdeDiasUltCompra)) ) THEN

              -- Classe Pré-Definida
              vvClasseVenda := 'N';

            -- OUTROS
            ELSE

              -- Classe Venda OUTROS
              vvClasseVenda := vvClasseVendaOutros;

            END IF;

          END IF;

          -- Atualiza Array com a Classes de Venda do Cliente
          vtListaClasseVenda(viIdxCli) := vvClasseVenda;

        END LOOP;
      END IF; -- Fim: Definição da Classe dos Clientes

    /***********************************************************************************************
    CONFIGURAÇÃO 2: PONTUAÇÃO PELA MÉDIA DE VENDAS DOS ULTIMOS DOIS MESES
    ******************************************************/
    ELSIF (vc_Config.CODCONFIG = 2) THEN

      -- Busca se irÃ¡ fazer abatimento de devoluÃ§Ãµes nas vendas
      Select NVL(abaterdevolucoes, 'N')
        into vvAbaterDevolucoes
        from PCCONFIGCLASSECLIMED
       where codconfig = '2';

      IF vvAbaterDevolucoes = 'S' THEN

        FOR vc_VendasDevolCli IN (SELECT CODCLI, VL_VENDA, (SELECT CLASSEVENDA
                                    FROM PCCONFIGCLASSECLIMEDRANK
                                   WHERE CODCONFIG = '2'
                                   AND  VL_VENDA BETWEEN FAIXAINICIAL AND FAIXAFINAL) CLASSE_VENDA
                                   FROM (SELECT CODCLI,
                                         VL_MEDIA_VENDA -
                                         NVL((SELECT (SUM(DECODE(PCMOV.CODOPER,
                                                                'ED',
                                                                (NVL(PCMOV.PUNIT,
                                                                     0) -
                                                                NVL(PCMOV.VLREPASSE,
                                                                     0) -
                                                                NVL(PCMOV.ST,
                                                                     0) -
                                                                NVL(PCMOV.VLIPI,
                                                                     0)),
                                                                0) *
                                                         PCMOV.QT) / 2)
                                               FROM PCNFENT,
                                                    PCESTCOM,
                                                    PCEMPR,
                                                    PCNFSAID,
                                                    PCMOV,
                                                    PCPRODUT,
                                                    PCCLIENT,
                                                    PCFORNEC,
                                                    PCPRACA,
                                                    PCTABDEV,
                                                    PCTABDEV PCTABDEV2,
                                                    PCDEPTO,
                                                    PCSECAO,
                                                    PCUSUARI,
                                                    PCPLPAG,
                                                    PCSUPERV,
                                                    PCPEDC,
                                                    PCMARCA,
                                                    PCFILIAL
                                              WHERE PCNFENT.NUMTRANSENT =
                                                    PCESTCOM.NUMTRANSENT
                                                AND PCCLIENT.CODPRACA =
                                                    PCPRACA.CODPRACA
                                                AND PCESTCOM.NUMTRANSENT =
                                                    PCMOV.NUMTRANSENT
                                                AND PCFORNEC.CODFORNEC =
                                                    PCPRODUT.CODFORNEC
                                                AND PCNFSAID.NUMPED =
                                                    PCPEDC.NUMPED(+)
                                                AND PCNFENT.CODDEVOL =
                                                    PCTABDEV.CODDEVOL(+)
                                                AND PCMOV.CODDEVOL =
                                                    PCTABDEV2.CODDEVOL(+)
                                                AND PCPRODUT.CODEPTO =
                                                    PCDEPTO.CODEPTO(+)
                                                AND PCNFENT.CODUSURDEVOL =
                                                    PCUSUARI.CODUSUR(+)
                                                AND PCUSUARI.CODSUPERVISOR =
                                                    PCSUPERV.CODSUPERVISOR(+)
                                                AND PCPRODUT.CODSEC =
                                                    PCSECAO.CODSEC(+)
                                                AND PCPEDC.CODEMITENTE =
                                                    PCEMPR.MATRICULA(+)
                                                AND PCESTCOM.NUMTRANSVENDA =
                                                    PCNFSAID.NUMTRANSVENDA(+)
                                                AND PCNFSAID.CODPLPAG =
                                                    PCPLPAG.CODPLPAG(+)
                                                AND PCMOV.CODPROD =
                                                    PCPRODUT.CODPROD
                                                AND PCNFENT.CODFORNEC =
                                                    PCCLIENT.CODCLI
                                                AND PCPRODUT.CODMARCA =
                                                    PCMARCA.CODMARCA(+)
                                                AND PCNFENT.CODFILIAL =
                                                    PCFILIAL.CODIGO(+)
                                                AND PCESTCOM.NUMTRANSVENDA <> 0
                                                AND PCNFENT.TIPODESCARGA IN
                                                    ('6', '7')
                                                AND NVL(PCNFENT.CODFISCAL,
                                                        0) IN
                                                    (131, 132, 231, 232, 199, 299)
                                                AND PCMOV.DTCANCEL IS NULL
                                                AND PCMOV.CODOPER IN
                                                    ('ED', 'EN')
                                                AND NVL(PCNFENT.OBS, 'X') <>
                                                    'NF CANCELADA'
                                                AND PCCLIENT.CODCLI =
                                                    V.CODCLI

                                                AND PCNFENT.DTENT between
                                                    sysdate - 60 and
                                                    sysdate),
                                             0) VL_VENDA

                                    FROM (SELECT NVL(PCCLIENT.CODCLIPRINC,
                                                     PCCLIENT.CODCLI) CODCLI,
                                                 (SUM((NVL(DECODE(PCNFSAID.CONDVENDA,
                                                                  7,
                                                                  NVL(PCMOV.PUNITCONT,
                                                                      0),
                                                                  NVL(PCMOV.PUNIT,
                                                                      0)) -
                                                           NVL(PCMOV.VLREPASSE,
                                                               0) -
                                                           NVL(PCMOV.ST, 0) -
                                                           NVL(PCMOV.VLIPI,
                                                               0),
                                                           0)) *
                                                      (DECODE(PCMOV.CODOPER,
                                                              'S',
                                                              (NVL(DECODE(PCNFSAID.CONDVENDA,
                                                                          7,
                                                                          PCMOV.QTCONT,
                                                                          PCMOV.QT),
                                                                   0)),
                                                              'SM',
                                                              (NVL(DECODE(PCNFSAID.CONDVENDA,
                                                                          7,
                                                                          PCMOV.QTCONT,
                                                                          PCMOV.QT),
                                                                   0)),
                                                              'ST',
                                                              (NVL(DECODE(PCNFSAID.CONDVENDA,
                                                                          7,
                                                                          PCMOV.QTCONT,
                                                                          PCMOV.QT),
                                                                   0)),
                                                              'SB',
                                                              (NVL(DECODE(PCNFSAID.CONDVENDA,
                                                                          7,
                                                                          PCMOV.QTCONT,
                                                                          PCMOV.QT),
                                                                   0)),
                                                              0))) / 2) VL_MEDIA_VENDA

                                            FROM PCNFSAID,
                                                 PCUSUARI,
                                                 PCPLPAG,
                                                 PCCLIENT,
                                                 PCPEDC,
                                                 PCPRACA,
                                                 PCMOV,
                                                 PCFORNEC,
                                                 PCPRODUT,
                                                 PCEST,
                                                 PCMOVCOMPLE,
                                                 PCMARCA,
                                                 PCEMPR,
                                                 PCFILIAL
                                           WHERE PCNFSAID.CODUSUR =
                                                 PCUSUARI.CODUSUR
                                             AND PCNFSAID.CODPLPAG =
                                                 PCPLPAG.CODPLPAG
                                             AND PCNFSAID.NUMPED =
                                                 PCPEDC.NUMPED(+)
                                             AND PCNFSAID.NUMTRANSVENDA =
                                                 PCMOV.NUMTRANSVENDA
                                             AND PCNFSAID.CODUSUR =
                                                 PCUSUARI.CODUSUR
                                             AND PCMOV.CODPROD =
                                                 PCPRODUT.CODPROD
                                             AND PCPRODUT.CODFORNEC =
                                                 PCFORNEC.CODFORNEC -- Fornecedor do Produto
                                             AND PCMOV.CODPROD =
                                                 PCEST.CODPROD
                                             AND PCMOV.CODFILIAL =
                                                 PCEST.CODFILIAL
                                             AND PCMOV.CODFILIAL =
                                                 PCFILIAL.CODIGO(+)
                                             AND PCMOV.NUMTRANSITEM =
                                                 PCMOVCOMPLE.NUMTRANSITEM(+)
                                             AND PCPRODUT.CODMARCA =
                                                 PCMARCA.CODMARCA(+)
                                             AND PCCLIENT.CODPRACA =
                                                 PCPRACA.CODPRACA
                                             AND PCPEDC.CODEMITENTE =
                                                 PCEMPR.MATRICULA(+)
                                             AND PCNFSAID.CODCLI =
                                                 PCCLIENT.CODCLI
                                             AND PCNFSAID.DTCANCEL IS NULL
                                             AND PCNFSAID.DTSAIDA between
                                                 sysdate - 60 and
                                                 sysdate
                                           GROUP BY NVL(PCCLIENT.CODCLIPRINC,
                                                        PCCLIENT.CODCLI)) V) X) LOOP
           -- Código do Cliente
         vrDadosCli.vnCodCli            := vc_VendasDevolCli.CODCLI;
         -- Média de venda
         vrDadosCli.vnMediaVenda        := vc_VendasDevolCli.VL_VENDA;
         -- Faixa inicial
         vrDadosCli.vnFaixaInicial      := 0;
         -- Faixa final
         vrDadosCli.vnFaixaFinal        := 0;
         -- Classe Venda
         vrDadosCli.vCLASSEVENDA        := vc_VendasDevolCli.CLASSE_VENDA;
         -- Atualiza Array
         vtClientes(vc_VendasDevolCli.CODCLI) := vrDadosCli;

         -- Lista de Clientes inseridos no Array que é Indexado pelo Código do Cliente
         vtListaCodCli(NVL(vtListaCodCli.COUNT,0) + 1)           := vc_VendasDevolCli.CODCLI;
         -- Lista de Classe de Venda do Cliente
         vtListaClasseVenda(NVL(vtListaClasseVenda.COUNT,0) + 1) := vc_VendasDevolCli.CLASSE_VENDA;

       END LOOP;

      ELSE
        FOR vc_VendasCli IN (SELECT CODCLI, VL_MEDIA_VENDA,
                                 (SELECT CLASSEVENDA
                                    FROM PCCONFIGCLASSECLIMEDRANK
                                   WHERE CODCONFIG = '2'
                                     AND  VL_MEDIA_VENDA BETWEEN FAIXAINICIAL AND FAIXAFINAL) CLASSE_VENDA

                              FROM (SELECT NVL(PCCLIENT.CODCLIPRINC,
                                             PCCLIENT.CODCLI) CODCLI,
                                         (SUM((NVL(DECODE(PCNFSAID.CONDVENDA,
                                                          7,
                                                          NVL(PCMOV.PUNITCONT,
                                                              0),
                                                          NVL(PCMOV.PUNIT, 0)) -
                                                   NVL(PCMOV.VLREPASSE, 0) -
                                                   NVL(PCMOV.ST, 0) -
                                                   NVL(PCMOV.VLIPI, 0),
                                                   0)) *
                                              (DECODE(PCMOV.CODOPER,
                                                      'S',
                                                      (NVL(DECODE(PCNFSAID.CONDVENDA,
                                                                  7,
                                                                  PCMOV.QTCONT,
                                                                  PCMOV.QT),
                                                           0)),
                                                      'SM',
                                                      (NVL(DECODE(PCNFSAID.CONDVENDA,
                                                                  7,
                                                                  PCMOV.QTCONT,
                                                                  PCMOV.QT),
                                                           0)),
                                                      'ST',
                                                      (NVL(DECODE(PCNFSAID.CONDVENDA,
                                                                  7,
                                                                  PCMOV.QTCONT,
                                                                  PCMOV.QT),
                                                           0)),
                                                      'SB',
                                                      (NVL(DECODE(PCNFSAID.CONDVENDA,
                                                                  7,
                                                                  PCMOV.QTCONT,
                                                                  PCMOV.QT),
                                                           0)),
                                                      0))) / 2) VL_MEDIA_VENDA

                                    FROM PCNFSAID,
                                         PCUSUARI,
                                         PCPLPAG,
                                         PCCLIENT,
                                         PCPEDC,
                                         PCPRACA,
                                         PCMOV,
                                         PCFORNEC,
                                         PCPRODUT,
                                         PCEST,
                                         PCMOVCOMPLE,
                                         PCMARCA,
                                         PCEMPR,
                                         PCFILIAL
                                   WHERE PCNFSAID.CODUSUR =
                                         PCUSUARI.CODUSUR
                                     AND PCNFSAID.CODPLPAG =
                                         PCPLPAG.CODPLPAG
                                     AND PCNFSAID.NUMPED = PCPEDC.NUMPED(+)
                                     AND PCNFSAID.NUMTRANSVENDA =
                                         PCMOV.NUMTRANSVENDA
                                     AND PCNFSAID.CODUSUR =
                                         PCUSUARI.CODUSUR
                                     AND PCMOV.CODPROD = PCPRODUT.CODPROD
                                     AND PCPRODUT.CODFORNEC =
                                         PCFORNEC.CODFORNEC -- Fornecedor do Produto
                                     AND PCMOV.CODPROD = PCEST.CODPROD
                                     AND PCMOV.CODFILIAL = PCEST.CODFILIAL
                                     AND PCMOV.CODFILIAL =
                                         PCFILIAL.CODIGO(+)
                                     AND PCMOV.NUMTRANSITEM =
                                         PCMOVCOMPLE.NUMTRANSITEM(+)
                                     AND PCPRODUT.CODMARCA =
                                         PCMARCA.CODMARCA(+)
                                     AND PCCLIENT.CODPRACA =
                                         PCPRACA.CODPRACA
                                     AND PCPEDC.CODEMITENTE =
                                         PCEMPR.MATRICULA(+)
                                     AND PCNFSAID.CODCLI = PCCLIENT.CODCLI
                                     AND PCNFSAID.DTCANCEL IS NULL

                                     AND PCNFSAID.DTSAIDA between
                                         sysdate - 60 and sysdate

                                   GROUP BY NVL(PCCLIENT.CODCLIPRINC,
                                                PCCLIENT.CODCLI)) V) LOOP

           -- Código do Cliente
         vrDadosCli.vnCodCli            := vc_VendasCli.CODCLI;
         -- Média de venda
         vrDadosCli.vnMediaVenda        := vc_VendasCli.VL_MEDIA_VENDA;
         -- Faixa inicial
         vrDadosCli.vnFaixaInicial      := 0;
         -- Faixa final
         vrDadosCli.vnFaixaFinal        := 0;
         -- Classe Venda
         vrDadosCli.vClasseVenda        := vc_VendasCli.CLASSE_VENDA;

         -- Atualiza Array
         vtClientes(vc_VendasCli.CODCLI) := vrDadosCli;

         -- Lista de Clientes inseridos no Array que é Indexado pelo Código do Cliente
         vtListaCodCli(NVL(vtListaCodCli.COUNT,0) + 1)           := vc_VendasCli.CODCLI;
         -- Lista de Classe de Venda do Cliente
         vtListaClasseVenda(NVL(vtListaClasseVenda.COUNT,0) + 1) := vc_VendasCli.CLASSE_VENDA;

      END LOOP;

    END IF; -- FIM CONDIÇÃO: CONFIGURAÇÃO

  END IF;

   /************************
   Atualização dos Clientes
   ************************/
   IF (vtListaCodCli.COUNT > 0) THEN
     -- Laço de Atualização

     FORALL viIdxCli IN vtListaCodCli.FIRST..vtListaCodCli.LAST

     UPDATE PCCLIENT
        SET CLASSEVENDA = vtListaClasseVenda(viIdxCli)
      WHERE (CODCLI = vtListaCodCli(viIdxCli));

      -- Efetiva Transações
     COMMIT;

   END IF; -- Fim: Atualização dos Clientes

  END LOOP; -- Fim: Laço de Processamento da Configuração

EXCEPTION
  WHEN OTHERS THEN
    po_vOcorreramErros     := 'S';
    po_vMsgErros           := 'Erro Classe Venda Cliente: ' || SUBSTR('Erro: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM,1,200);
END PRC_MED_CLASSEVENDA_CLIENTE;

