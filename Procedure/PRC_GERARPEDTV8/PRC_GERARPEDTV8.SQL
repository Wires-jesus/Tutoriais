CREATE OR REPLACE PROCEDURE PRC_GERARPEDTV8(PNUMPED        IN NUMBER
                                           ,PMSG           OUT VARCHAR2
                                           ,PNUMPEDGERADO  OUT NUMBER
                                           ,PPOSICAOGERADO OUT VARCHAR2
                                           ,PMOTIVO        OUT NUMBER) IS
  /*  ---------------------------------------------------------------------------------------------------------------
      DATA    RESPONSÁVEL       OBS.
  ---------------------------------------------------------------------------------------------------------------
   17/06/2008   DIEGO MARTINS   CRIAÇÃO DO PROGRAMA
   22/08/2008   DIEGO MARTINS   O PEDIDO TV8 TERÁ NO CAMPO NUMPEDORIGEM O SEU NÚMERO DE PEDIDO - TAREFA 67702
   29/08/2008   DIEGO MARTINS   Correção na ordem de geração
   05/09/2008   PABLO           Alteração para não gravar PCPEDC.NumPedOrigem, conforme alteração do projeto
                                v.1.8
   11/10/2008   PABLO           Dependendo da posição do Pedido o estoque está sendo movimentado para
                                Reservado ou Pendente
   26/12/2008   Pablo  75411    Caso o pedido original tenha sido gravado como bloqueado, o pedido TV8
                                tbm será gerado como bloqueado.
   04/02/2009   Pablo  78094    Alteração para passar a gravar PCPEDI.RotinaLanc
   26/02/2009   Pablo  79111    Tarefa  Alteração para replicar a informação de PCVendaConsum para o novo pedido gerado
   20/04/2009   Pablo  82932    Alteração para customizar o Projeto 67764 - Comissao de Profissional
   02/06/2009   Pablo  85842    Alteração para não alterar a posição para bloqueado\quando o cliente estiver bloqueado, uma vez que o pedido
                                pode ser gravado como Liberado, quando a cobrança for 'D' e o Plano a v
   24/07/2009   Andréa 85855    Implmentar projeto 71133 - Reformulação Controle de Saldo rca

   02/06/2010   Marden          Tarefa  entrega futura, novo tipo criado para tipo de entrega EF = Entrega Futura
   02/06/2010   Marden          Tarefa  entrega futura adicionado registros.TIPOENTREGA = 'EF' AND
                                PCPEDI.POSICAO = 'P' para registrar o item como qtpendente ao inves de
                                qtreserv....
   20/06/2011  Thiago Alves     Tarefa 118089 Gravar o campo pcpedc.reservarestoquetv7
   24/06/2011  Pablo            Alteração para acrescentar Commit e Rollback caso ocorra erro.
   13/07/2011  Thiago Alves     Não gerar st e ipi na venda tipo 8 quando o condvenda for 7 e for processo conta e ordem
   08/08/2011  Thiago Alves     Alterado procedimento para gravação do campo codclitv8
   12/09/2011  Thiago Alves     Alterada rotina para gravação do campo contaordem no pedido tipo 8
   21/12/2011  Thiago Alves     Alterada procedure para gravação dos itens da cesta
   03/04/2012  Marcos Garcia    Ajustada rotina para validar o parametro RETIRAIPIPEDIDOTV8
   16/05/2012  Thiago Melo      Tarefa - 163268 Alterada rotina para buscar a praça do cliente tipo 8 caso tenha sido inofrmado
   25/05/2012  Thiago Melo      Tarefa 163899
   01/06/2012  Rodrigo Santos   Tarefa 164445
   07/05/2013  Thiago Melo      Tarefa 196606 Alterado o ponto de validação da linha 148 que estava assim : "IF (NOT ((vbpassou) OR (vsvendasemestoque = 'S'))) THEN"
                                e foi alterado para "IF (NOT ((vbpassou) OR (vsvendasemestoque = 'N'))) THEN", ou seja somente a variavél
                                "vsvendasemestoque".
   10/12/2013  Rafael Braga     Solicitação 2769.014333.2013, ajustado para sempre gravar o CODCOB do TV8 como "SENT", pois esta é a regra correta, conforme a 316 já faz.
   07/05/2014  Rafael Braga     Solicitação 4276.049238.2014, ajustado para replicar tabela PCPEDCVCTO.
   26/01/2015  Rafael Braga     Solicitação 3621.139700.2014, ajustado para replicar o campo PCPEDC.CODCLITV8 na PCPEDC e PCPEDI, pois os itens estavam ficando sem a informação correta.
   22/07/2015  Leandro Bastos   Solicitação 5050.082603.2015, Alterado o ponto de validação da linha 148 que estava assim : "IF (NOT ((vbpassou) OR (vsvendasemestoque = 'N'))) THEN"
                                e foi alterado para "IF (((NOT vbpassou) OR (vsvendasemestoque = 'S'))) THEN".
  */
  --Variáveis para Tabela
  VNCODUSUR                  PCPEDC.CODUSUR%TYPE;
  VNPERCVENDA                PCPEDC.PERCVENDA%TYPE;
  VNPROXNUMPED               PCUSUARI.PROXNUMPED%TYPE;
  VNCONDVENDA                PCPEDC.CONDVENDA%TYPE;
  VSVENDASEMESTOQUE          PCCONSUM.ACEITAVENDASEMEST%TYPE;
  VSVENDAASSISTIDA           PCPEDC.VENDAASSISTIDA%TYPE;
  VSRCABLOQUEADO             PCUSUARI.BLOQUEIO%TYPE;
  VSCLIENTEBLOQUEADO         PCCLIENT.BLOQUEIO%TYPE;
  VSPOSICAO                  PCPEDC.POSICAO%TYPE;
  VSMOTIVOPOSICAO            PCPEDC.MOTIVOPOSICAO%TYPE;
  VFQTESTOQUE                PCEST.QTEST%TYPE;
  VBPASSOU                   BOOLEAN;
  VNCODPRACA                 PCPEDC.CODPRACA%TYPE;
  --Variáveis Estáticas
  VNTOTALITENS               INT;
  ERRO_CONDVENDA             EXCEPTION;
  ERRO_PROXNUMPEDZERADO      EXCEPTION;
  ERRO_ICMSPARTILHA          EXCEPTION;
  EX_MOVEST                  EXCEPTION;
  VBSALDORCA                 BOOLEAN;
  VNCODEMITENTE              NUMBER;
  VSRESERVARESTOQUETV7       VARCHAR2(1);
  VSCONTAORDEM               PCPEDC.CONTAORDEM%TYPE;
  VSNAOGERAIMPOSTOTV8        VARCHAR2(1);
  VSRETIRAIPIPEDIDOTV8       VARCHAR2(1);
  VNCODCLITV8                PCPEDC.CODCLITV8%TYPE;
  VS_MOVEST                  VARCHAR2(4000);
  MSGEST                     VARCHAR2(4000);
  vsFATTV8ANTESTV7CONTAORDEM VARCHAR2(2);
  vnCFOP                     NUMBER;
  VSSITTRIBUT                VARCHAR(4);
  VSACEITAVENDASEMESTFV      VARCHAR2(2);
  VSORIGEMPED                PCPEDC.ORIGEMPED%TYPE;
  VSNUMPEDRCA                PCPEDC.NUMPEDRCA%TYPE;
  VNCODPROD                  PCPEDI.CODPROD%TYPE;
  ERRO_ESTOQUE_TV8           EXCEPTION;
  vnCodMSGPartilha           NUMBER;
  vsMSGPartilha              VARCHAR2(4000);
  vsATUALIZARTV8             VARCHAR(1);
  ITENTATIVA NUMBER(2);
  VNQT                      PCPEDI.QT%TYPE;
  VNCOUNTPRODSEMESTOQUEDISP NUMBER := 0;
  VBRAISE_ERRO_ESTOQUE_TV8  BOOLEAN := FALSE;
  VSLISTAPRODRETORNOESTOQUE VARCHAR2(4000);
  VSTIPOENTREGA               VARCHAR2(2);
BEGIN
  PMSG           := '';
  VBPASSOU       := TRUE;
  PMOTIVO        := 0;
  PNUMPEDGERADO  := 0;
  PPOSICAOGERADO := '';

  SELECT CONDVENDA
        ,NVL(VENDAASSISTIDA, 'N')
        ,PERCVENDA
        ,CODEMITENTE
        ,CONTAORDEM
        ,NVL(CODCLITV8, 0)
        ,FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('FATTV8ANTESTV7CONTAORDEM',
                                            PCPEDC.CODFILIAL,
                                            'N')
		    ,ORIGEMPED
        ,NUMPEDRCA
    INTO VNCONDVENDA
        ,VSVENDAASSISTIDA
        ,VNPERCVENDA
        ,VNCODEMITENTE
        ,VSCONTAORDEM
        ,VNCODCLITV8
        ,vsFATTV8ANTESTV7CONTAORDEM
        ,VSORIGEMPED
        ,VSNUMPEDRCA
    FROM PCPEDC
   WHERE NUMPED = PNUMPED;

  IF ((VNCONDVENDA = 5) AND (VNCONDVENDA = 4)) OR
     ((VNCONDVENDA = 7) AND (VSCONTAORDEM = 'S'))
  THEN
    VSNAOGERAIMPOSTOTV8 := 'S';
  ELSE
    VSNAOGERAIMPOSTOTV8 := 'N';
  END IF;

  IF (VNCONDVENDA <> 7) AND (VSVENDAASSISTIDA <> 'S') AND
     (VNPERCVENDA <> 100)
  THEN
    RAISE ERRO_CONDVENDA;
  END IF;

  SELECT COUNT(1)
    INTO VNTOTALITENS
    FROM PCPEDI
   WHERE NUMPED = PNUMPED;

  SELECT NVL(PCCONSUM.ACEITAVENDASEMEST, 'N')
    INTO VSVENDASEMESTOQUE
    FROM PCCONSUM;

  SELECT VALOR
    INTO VSRETIRAIPIPEDIDOTV8
    FROM PCPARAMFILIAL
   WHERE NOME = 'RETIRAIPIPEDIDOTV8'
     AND CODFILIAL = 99;

  --Tarefa 118089
  SELECT NVL(PCPARAMFILIAL.VALOR, 'N')
    INTO VSRESERVARESTOQUETV7
    FROM PCPARAMFILIAL
   WHERE PCPARAMFILIAL.CODFILIAL =
         (SELECT PCPEDC.CODFILIAL
            FROM PCPEDC
           WHERE PCPEDC.NUMPED = PNUMPED
             AND ROWNUM = 1)
     AND PCPARAMFILIAL.NOME = 'RESERVARESTOQUETV7';

  SELECT NVL(PCPARAMFILIAL.VALOR, 'N')
    INTO VSACEITAVENDASEMESTFV
    FROM PCPARAMFILIAL
   WHERE PCPARAMFILIAL.CODFILIAL =
         (SELECT PCPEDC.CODFILIAL
            FROM PCPEDC
           WHERE PCPEDC.NUMPED = PNUMPED
             AND ROWNUM = 1)
     AND PCPARAMFILIAL.NOME ='ACEITAVENDASEMESTFV';

  FOR REGISTROS IN (SELECT PCPEDI.CODPROD
                          ,PCPEDI.TIPOENTREGA
                          ,PCPEDI.POSICAO
                          ,NVL(PCPEDI.CODFILIALRETIRA, PCPEDC.CODFILIAL) CODFILIAL
                          ,SUM(PCPEDI.QT) QT
                      FROM PCPEDC, PCPEDI
                     WHERE PCPEDC.NUMPED = PCPEDI.NUMPED
                       AND PCPEDC.NUMPED = PNUMPED
                     GROUP BY PCPEDI.CODPROD
                             ,PCPEDI.TIPOENTREGA
                             ,PCPEDI.POSICAO
                             ,NVL(PCPEDI.CODFILIALRETIRA, PCPEDC.CODFILIAL)
                             ORDER BY PCPEDI.CODPROD)
  LOOP
    VSTIPOENTREGA := REGISTROS.TIPOENTREGA;
    SELECT NVL(QTDISP, 0), REGISTROS.CODPROD, REGISTROS.QT
        INTO VFQTESTOQUE, VNCODPROD, VNQT
        FROM TABLE(VENDAS.ESTOQUE_DISPONIVEL(REGISTROS.CODPROD,
                                          REGISTROS.CODFILIAL));

    IF (VFQTESTOQUE < REGISTROS.QT) AND
       ((VSVENDASEMESTOQUE = 'N') OR (VSRESERVARESTOQUETV7 = 'S') OR
       (vsFATTV8ANTESTV7CONTAORDEM = 'S' AND VSCONTAORDEM = 'S')) THEN
      VBPASSOU                  := FALSE;
      VNCOUNTPRODSEMESTOQUEDISP := VNCOUNTPRODSEMESTOQUEDISP + 1;

      IF VNCOUNTPRODSEMESTOQUEDISP = 1 THEN
        VSLISTAPRODRETORNOESTOQUE := 'Produto: ' || VNCODPROD ||
                                     ' | Qt.Pedido: ' || VNQT || ' | Qt.Disp.: ' ||
                                     VFQTESTOQUE;
      ELSE
        VSLISTAPRODRETORNOESTOQUE := VSLISTAPRODRETORNOESTOQUE || CHR(13) ||
                                     'Produto: ' || VNCODPROD ||
                                     ' | Qt.Pedido: ' || VNQT || ' | Qt.Disp.: ' ||
                                     VFQTESTOQUE;
      END IF;
      VSLISTAPRODRETORNOESTOQUE := SUBSTR(VSLISTAPRODRETORNOESTOQUE,
                                          1,
                                          4000);
    END IF;
  END LOOP;

  IF VNCOUNTPRODSEMESTOQUEDISP > 0 AND VSTIPOENTREGA <> 'EF' AND
     (((NOT VBPASSOU) AND
     ((VSVENDASEMESTOQUE <> 'S') AND (VSORIGEMPED <> 'F'))) OR
     ((NOT VBPASSOU) AND (VSACEITAVENDASEMESTFV <> 'S') AND
     (VSNUMPEDRCA IS NOT NULL) AND (VNCODEMITENTE = 8888))) THEN

    PMOTIVO                  := 1;
    VBRAISE_ERRO_ESTOQUE_TV8 := TRUE;
  END IF;

  IF VBRAISE_ERRO_ESTOQUE_TV8 THEN

    RAISE ERRO_ESTOQUE_TV8;

  ELSE
    IF VNTOTALITENS > 0
    THEN
      BEGIN
        SELECT PCPEDC.CODUSUR
              ,NVL(PCCLIENT.BLOQUEIO, 'N') BLOQUEIO
              ,PCPEDC.POSICAO
          INTO VNCODUSUR, VSCLIENTEBLOQUEADO, VSPOSICAO
          FROM PCPEDC, PCCLIENT
         WHERE PCPEDC.NUMPED = PNUMPED
           AND PCPEDC.CODCLI = PCCLIENT.CODCLI;

        SELECT NVL(PCUSUARI.BLOQUEIO, 'N')
          INTO VSRCABLOQUEADO
          FROM PCUSUARI
         WHERE CODUSUR = VNCODUSUR;

        BEGIN
          BEGIN --DDVENDAS-21600
            SELECT PCPEDC.NUMPED
                 , 'S'
              INTO VNPROXNUMPED
                 , vsATUALIZARTV8
              FROM PCPEDC
                 , PCPEDC TV7
             WHERE PCPEDC.CONDVENDA = 8
               AND PCPEDC.NUMPEDENTFUT = TV7.NUMPED
               AND PCPEDC.NUMPEDRCA = TV7.NUMPEDRCA
               AND TV7.VENDAASSISTIDA = 'S'
               AND TV7.DTCANCEL IS NULL
               AND TV7.NUMPED = PNUMPED
               AND ROWNUM = 1;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            VNPROXNUMPED := 0;
            vsATUALIZARTV8 := 'N';
          END;

          IF vsATUALIZARTV8 = 'N' THEN
            ITENTATIVA := 0;
            WHILE ITENTATIVA < 50 AND VNPROXNUMPED = 0
            LOOP
              VNPROXNUMPED := FERRAMENTAS.F_PROX_NUMPED(VNCODUSUR);
              IF VNPROXNUMPED > 0
              THEN
                EXIT;
              END IF;
              ITENTATIVA := ITENTATIVA + 1;
            END LOOP;
          END IF;
        EXCEPTION
          WHEN OTHERS THEN

            IF PMOTIVO IS NULL
            THEN
              PMOTIVO := 'Erro ao buscar numero pedido TV8. -' || SQLCODE ||
                         ' - ' || SQLERRM || CHR(13);
            ELSE
              PMOTIVO := PMOTIVO || CHR(13) ||
                         'Erro ao buscar numero pedido TV8. - ' || SQLCODE ||
                         ' - ' || SQLERRM || CHR(13);
            END IF;
        END;

        IF (VNPROXNUMPED <= 0)
        THEN
          RAISE ERRO_PROXNUMPEDZERADO;
        END IF;

      EXCEPTION
        WHEN OTHERS THEN
          PMSG := SQLCODE || ' - ' || SQLERRM ||
                  ' -1- Erro ao buscar o próximo número de pedido';
          RAISE;
      END;
    END IF;

    BEGIN
      PNUMPEDGERADO := VNPROXNUMPED;

      IF VSPOSICAO <> 'B'
      THEN
        IF (NOT VBPASSOU)
        THEN
          VSPOSICAO := 'P';
        ELSE
          VSPOSICAO := 'L';
        END IF;
      END IF;

      -- Fim tarefa 70737
      --UPDATE pcpedc SET posicao = vsposicao WHERE numped = pnumped;
      --Comentado o trecho acima pela tarefa de nº 118089

      --Encontrar a praça do cliente tv8
      BEGIN

        SELECT PCCLIENT.CODPRACA
          INTO VNCODPRACA
          FROM PCCLIENT, PCPEDC
         WHERE PCCLIENT.CODCLI = PCPEDC.CODCLITV8
           AND PCPEDC.NUMPED = PNUMPED;

      EXCEPTION
        WHEN OTHERS THEN
          VNCODPRACA := NULL;
      END;

      PPOSICAOGERADO := VSPOSICAO;

      IF vsATUALIZARTV8 = 'N' THEN
        FOR DADOS IN (SELECT PCPEDC.* FROM PCPEDC WHERE NUMPED = PNUMPED) LOOP

          DADOS.NUMPED            := VNPROXNUMPED;
          DADOS.CODCLI            := NVL(DADOS.CODCLITV8, DADOS.CODCLI);
          DADOS.VLATEND           := 0;
          DADOS.NUMPEDENTFUT      := PNUMPED;
          DADOS.CONDVENDA         := 8;
          DADOS.CODCOB            := 'SENT';
          DADOS.VLTABELA          := 0;
          DADOS.VLCUSTOREAL       := 0;
          DADOS.VLCUSTOFIN        := 0;
          DADOS.VLCUSTOCONT       := 0;
          DADOS.VLCUSTOREP        := 0;
          DADOS.CODCLIRECEBEDOR   := NVL(DADOS.CODCLITV8,
                                         DADOS.CODCLIRECEBEDOR);
          DADOS.RESERVAESTOQUETV7 := CASE WHEN NVL(VSVENDAASSISTIDA, 'N') = 'N'
                                       THEN VSRESERVARESTOQUETV7
                                         ELSE ''
                                           END;
          DADOS.CODPRACA          := NVL(VNCODPRACA, DADOS.CODPRACA);
          DADOS.POSICAO           := VSPOSICAO;

          INSERT INTO PCPEDC VALUES DADOS;
        END LOOP;

        FOR DADOS IN (SELECT PCPEDCVCTO.* FROM PCPEDCVCTO WHERE NUMPED = PNUMPED) LOOP
          DADOS.NUMPED            := VNPROXNUMPED;
          INSERT INTO PCPEDCVCTO VALUES DADOS;
        END LOOP;

        FOR DADOS IN (SELECT PCVENDACONSUM.*
                        FROM PCVENDACONSUM
                       WHERE NUMPED = PNUMPED) LOOP

          DADOS.NUMPED := VNPROXNUMPED;

          INSERT INTO PCVENDACONSUM VALUES DADOS;
        END LOOP;
      ELSE
        FOR DADOS IN (SELECT PCPEDC.VLTOTAL
                           , PCPEDC.NUMITENS
                           , PCPEDC.TOTPESO
                           , PCPEDC.TOTVOLUME
                        FROM PCPEDC
                       WHERE PCPEDC.NUMPED = PNUMPED)
        LOOP --Atualizando os dados conforme o pedido original
          UPDATE PCPEDC
             SET PCPEDC.VLTOTAL    = DADOS.VLTOTAL
               , PCPEDC.NUMITENS   = DADOS.NUMITENS
               , PCPEDC.TOTPESO    = DADOS.TOTPESO
               , PCPEDC.TOTVOLUME  = DADOS.TOTVOLUME
           WHERE PCPEDC.NUMPED     = VNPROXNUMPED;
        END LOOP;
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        PMSG := SQLCODE || ' - ' || SQLERRM ||
                ' -2- Erro ao gerar pedido tipo 8';
        RAISE;
    END;

    BEGIN
      FOR DADOS IN (SELECT PCPEDI.* 
                      FROM PCPEDI 
                     WHERE NUMPED = PNUMPED
                       AND NOT EXISTS (SELECT 1 --DDVENDAS-21600
                                         FROM PCPEDI TV8
                                        WHERE TV8.NUMPED = VNPROXNUMPED
                                          AND TV8.CODPROD = PCPEDI.CODPROD
                                          AND TV8.NUMSEQ = PCPEDI.NUMSEQ)  ) LOOP
        DADOS.NUMPED := VNPROXNUMPED;
        DADOS.PVENDA := DADOS.PVENDA - CASE WHEN VSRETIRAIPIPEDIDOTV8 = 'S' THEN DADOS.VLIPI ELSE 0 END;

        DADOS.CODCLI  := CASE WHEN VNCODCLITV8 = 0 THEN DADOS.CODCLI ELSE VNCODCLITV8 END;
        DADOS.POSICAO := VSPOSICAO;
        DADOS.ST      := CASE WHEN VSNAOGERAIMPOSTOTV8 = 'S' THEN 0 ELSE DADOS.ST END;
        DADOS.VLIPI   := CASE WHEN(VSRETIRAIPIPEDIDOTV8 = 'S' OR VSNAOGERAIMPOSTOTV8 = 'S') THEN 0 ELSE DADOS.VLIPI END;
        DADOS.PERCIPI := CASE WHEN(VSRETIRAIPIPEDIDOTV8 = 'S' OR VSNAOGERAIMPOSTOTV8 = 'S') THEN 0 ELSE DADOS.PERCIPI END;

        INSERT INTO PCPEDI VALUES DADOS;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        PMSG := SQLCODE || ' - ' || SQLERRM ||
                ' -3- Erro ao gerar os itens do pedido tipo 8';
        RAISE;
    END;

    BEGIN
      FOR DADOS IN (SELECT PCPEDICESTA.*
                      FROM PCPEDICESTA
                     WHERE NUMPED = PNUMPED
                       AND NOT EXISTS (SELECT 1 --DDVENDAS-21600
                                         FROM PCPEDICESTA TV8
                                        WHERE TV8.NUMPED  = VNPROXNUMPED
                                          AND TV8.CODPROD = PCPEDICESTA.CODPROD
                                          AND TV8.NUMSEQ  = PCPEDICESTA.NUMSEQ)) LOOP

        DADOS.NUMPED := VNPROXNUMPED;
        DADOS.PVENDA := DADOS.PVENDA - CASE WHEN VSRETIRAIPIPEDIDOTV8 = 'S' THEN DADOS.VLIPI ELSE 0 END;

        DADOS.ST      := CASE WHEN VSNAOGERAIMPOSTOTV8 = 'S' THEN 0 ELSE DADOS.ST END;
        DADOS.VLIPI   := CASE WHEN(VSRETIRAIPIPEDIDOTV8 = 'S' OR VSNAOGERAIMPOSTOTV8 = 'S') THEN 0 ELSE DADOS.VLIPI END;
        DADOS.PERCIPI := CASE WHEN(VSRETIRAIPIPEDIDOTV8 = 'S' OR VSNAOGERAIMPOSTOTV8 = 'S') THEN 0 ELSE DADOS.PERCIPI END;

        INSERT INTO PCPEDICESTA VALUES DADOS;
      END LOOP;

    EXCEPTION
      WHEN OTHERS THEN
        PMSG := SQLCODE || ' - ' || SQLERRM ||
                ' -3.1- Erro ao gerar os itens da cesta do pedido tipo 8';
        RAISE;
    END;

    --Fim tarefa 152211

     DECLARE
        T_PCPEDC                      PCPEDC%ROWTYPE;
        T_PCPEDI                      PCPEDI%ROWTYPE;
        VNCODFISCALRET                NUMBER;
        VSSITTRIBUTRET                VARCHAR2(3);
        MSGCFOP                       VARCHAR2(300);
        VSAPLICADESCONTOSIMPLES       VARCHAR2(3) := 'S';
        VSSIMPLESNACIONAL             VARCHAR2(3);
        vtPartilhaPtabela_SemImpostos PCPEDI.PTABELA%TYPE;
        vtPartilhaVlredsimpnac_Pvenda PCPEDI.VLREDPVENDASIMPLESNA%TYPE;
        tICMSPARTILHA                 tipo_icms_partilha;
        vsMSGPartilha                 varchar2(1000);
        vnCodMSGPartilha              number;
        vsufEnt                       PCCLIENT.ESTENT%TYPE;

      BEGIN

        SELECT C.* INTO T_PCPEDC FROM PCPEDC C WHERE NUMPED = VNPROXNUMPED;

        BEGIN
          SELECT SIMPLESNACIONAL
            INTO VSSIMPLESNACIONAL
            FROM PCCLIENT
           WHERE CODCLI = T_PCPEDC.CODCLI;
        EXCEPTION
          WHEN OTHERS THEN
            VSSIMPLESNACIONAL := 'N';
        END;

        BEGIN
          BEGIN
            SELECT ESTENT
              INTO VSUFENT
              FROM PCCLIENTENDENT
             WHERE CODCLI = T_PCPEDC.CODCLI
               AND CODENDENTCLI =
                   NVL(T_PCPEDC.CODENDENTCLI, T_PCPEDC.CODENDENT);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              SELECT ESTENT
                INTO VSUFENT
                FROM PCCLIENT
               WHERE CODCLI = T_PCPEDC.CODCLI;
          END;
        EXCEPTION
          WHEN OTHERS THEN
            VSUFENT := '';
        END;

        FOR ITEM IN (SELECT DISTINCT PCPEDI.CODPROD,
                                     PCPEDI.NUMSEQ,
                                     'PCPEDI' as TIPO_DADO
                       FROM pcpedi, pcprodut, pcclient cli
                      WHERE pcpedi.numped = VNPROXNUMPED
                        AND pcpedi.codprod = pcprodut.codprod
                        and pcpedi.codcli = cli.codcli
                        AND pcpedi.qt > 0
                     UNION
                     SELECT pcpedicesta.codprodmp AS codprod,
                            pcpedicesta.numseq,
                            'PCPEDICESTA' as TIPO_DADO
                       FROM pcpedi i, pcpedc c, pcpedicesta
                      WHERE i.numped = pcpedicesta.numped
                        AND i.codprod = pcpedicesta.codprod
                        AND pcpedicesta.numseq = i.numseq
                        AND i.numped = VNPROXNUMPED
                        AND c.numped = VNPROXNUMPED
                        AND i.qt > 0
                        AND pcpedicesta.codprod <> 999999 --Código de produto reservado ao processo tintométrico
                      ORDER BY numseq) LOOP

          IF ITEM.TIPO_DADO = 'PCPEDICESTA' THEN
            SELECT C.CODST,
                   C.CODPRODMP,
                   NVL(I.BONIFIC, 'N'),
                   C.VLDESCSUFRAMA,
                   C.PVENDA,
                   0
              INTO T_PCPEDI.CODST,
                   T_PCPEDI.CODPROD,
                   T_PCPEDI.BONIFIC,
                   T_PCPEDI.VLDESCSUFRAMA,
                   T_PCPEDI.PVENDA,
                   T_PCPEDI.VLDESCICMISENCAO
              FROM PCPEDICESTA C, PCPEDI I
             WHERE I.NUMPED = VNPROXNUMPED
               AND I.NUMSEQ = ITEM.NUMSEQ
               AND I.CODPROD = C.CODPROD
               AND I.NUMPED = C.NUMPED
               AND C.CODPRODMP = ITEM.CODPROD
               AND C.NUMSEQ = ITEM.NUMSEQ;
          ELSE
            SELECT I.*
              INTO T_PCPEDI
              FROM PCPEDI I
             WHERE NUMPED = VNPROXNUMPED
               AND I.CODPROD = ITEM.CODPROD
               AND I.NUMSEQ = ITEM.NUMSEQ;
          END IF;

          FERRAMENTAS.DEFINIRCODFISCAL(T_PCPEDC,
                                       T_PCPEDI,
                                       VNCODFISCALRET,
                                       VSSITTRIBUTRET,
                                       MSGCFOP);

          IF MSGCFOP <> '' THEN
            RAISE_APPLICATION_ERROR(-20000,
                                    'Erro ao encontrar CFOP/SITTRIBUT.' ||
                                    CHR(13) || 'Msg. Original: ' || MSGCFOP);
          END IF;

          vnCFOP      := VNCODFISCALRET;
          vssittribut := VSSITTRIBUTRET;

          UPDATE PCPEDI
             SET CODFISCAL = vnCFOP, SITTRIBUT = vssittribut
           WHERE NUMPED = VNPROXNUMPED
             AND CODPROD = ITEM.CODPROD
             AND NUMSEQ = ITEM.NUMSEQ;

          IF NVL(T_PCPEDI.codprecofixo, 0) > 0 THEN
            BEGIN
              SELECT NVL(APLICADESCONTOSIMPLES, 'S')
                INTO VSAPLICADESCONTOSIMPLES
                FROM PCPRECOPROM
               WHERE CODPRECOPROM = T_PCPEDI.codprecofixo;
            EXCEPTION
              WHEN OTHERS THEN
                VSAPLICADESCONTOSIMPLES := 'S';
            END;
          END IF;

          SELECT VALORSEMIMPOSTO
            INTO vtPartilhaPtabela_SemImpostos
            FROM TABLE(PKG_TRIBUTACAO.CALCULAR_PVENDA_SEM_IMPOSTO(T_PCPEDC.codfilial,
                                                                  T_PCPEDC.codfilialnf,
                                                                  T_PCPEDI.codfilialretira,
                                                                  T_PCPEDC.codcli,
                                                                  T_PCPEDC.codplpag,
                                                                  T_PCPEDI.codprod,
                                                                  T_PCPEDI.codauxiliar,
                                                                  T_PCPEDC.condvenda,
                                                                  'N',
                                                                  T_PCPEDI.st, --1,
                                                                  0,
                                                                  T_PCPEDI.ptabela,
                                                                  'S',
                                                                  'S',
                                                                  T_PCPEDI.bonific,
                                                                  T_PCPEDI.codprecofixo, --0,
                                                                  NULL,
                                                                  'N',
                                                                  'N',
                                                                  'N',
                                                                  'N',
                                                                  0,
                                                                  T_PCPEDC.VendaTriangular,
                                                                  'I',
                                                                  T_PCPEDC.codbnf,
                                                                  T_PCPEDC.codendentcli,
                                                                  T_PCPEDC.tipodocumento));

          IF (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('USADESCSIMPLESNAC',
                                                 T_PCPEDC.codfilial,
                                                 'N') = 'S') AND
             (nvl(VSSIMPLESNACIONAL, 'N') = 'S') AND
             NOT (NVL(T_PCPEDI.codprecofixo, 0) > 0 and
              VSAPLICADESCONTOSIMPLES = 'N') THEN
            --PVENDA
            SELECT VALOR_REDUCAO_SIMPLES_NACIONAL
              INTO vtPartilhaVlredsimpnac_Pvenda
              FROM TABLE(PKG_TRIBUTACAO.CALCULAR_RED_SIMPLES_NACIONAL(T_PCPEDC.codfilial,
                                                                      T_PCPEDC.codfilialnf,
                                                                      T_PCPEDI.codfilialretira,
                                                                      T_PCPEDC.codcli,
                                                                      T_PCPEDC.codplpag,
                                                                      T_PCPEDI.codprod,
                                                                      T_PCPEDI.codauxiliar,
                                                                      T_PCPEDC.condvenda,
                                                                      'N',
                                                                      vtPartilhaPtabela_SemImpostos,
                                                                      vtPartilhaPtabela_SemImpostos));

            vtPartilhaPtabela_SemImpostos := vtPartilhaPtabela_SemImpostos -
                                             vtPartilhaVlredsimpnac_Pvenda;

          END IF;

          pkg_fwpc_fiscal.icmspartilha_calcular_1_4(nvl(T_PCPEDC.codfilialnf,
                                                        T_PCPEDC.codfilial),
                                                    nvl(T_PCPEDC.codclinf,
                                                        T_PCPEDC.codcli),
                                                    '',
                                                    vsufEnt,
                                                    T_PCPEDC.data,
                                                    vtPartilhaPtabela_SemImpostos,
                                                    T_PCPEDI.codst,
                                                    T_PCPEDI.codprod,
                                                    vnCFOP,
                                                    VSSITTRIBUT,
                                                    tICMSPARTILHA,
                                                    vnCodMSGPartilha,
                                                    vsMSGPartilha);

          IF vnCodMSGPartilha not in (0, 4, 5, 11) then
            RAISE ERRO_ICMSPARTILHA;
          END IF;

          UPDATE PCPEDI
             SET ALIQFCP           = TICMSPARTILHA.ALIQFCP,
                 ALIQINTERNADEST   = TICMSPARTILHA.ALIQINTERNADEST,
                 VLFCPPART         = TICMSPARTILHA.VLFCPPART,
                 VLICMSPARTDEST    = TICMSPARTILHA.VLICMSPARTDEST,
                 VLICMSPART        = TICMSPARTILHA.VLICMSPART,
                 PERCPROVPART      = TICMSPARTILHA.PERCPROVPART,
                 VLICMSDIFALIQPART = TICMSPARTILHA.VLICMSDIFALIQ,
                 PERCBASEREDPART   = TICMSPARTILHA.PERCBASERED,
                 VLICMSPARTREM     = TICMSPARTILHA.VLICMSPARTREM,
                 ALIQINTERORIGPART = TICMSPARTILHA.ALIQINTERESTADUAL,
                 VLBASEPARTDEST    = TICMSPARTILHA.VLBASEPARTDEST
           WHERE NUMPED = VNPROXNUMPED
             AND CODPROD = ITEM.CODPROD
             AND NVL(NUMSEQ, 0) = ITEM.NUMSEQ;

        END LOOP;

     EXCEPTION
      WHEN ERRO_ICMSPARTILHA THEN
        ROLLBACK;
        PMSG := 'Erro ao calcular partilha de ICMS para o pedido TV8. Código: ' ||
                        to_char(vnCodMSGPartilha) || ' - ' || vsMSGPartilha || CHR(13) ||
                        'Produto: ' || T_PCPEDI.codprod || CHR(13) ||
                        'Figura Tributária: ' || T_PCPEDI.codst || CHR(13) ||
                        'UF Destino: ' || VSUFENT;

      WHEN OTHERS THEN
        ROLLBACK;
        PMSG := 'Erro ao validar CFOP/SITTRIBUT para o pedido TV8.' || CHR(13) ||
                'Erro: ' || SQLCODE || '-' || SQLERRM;

     END;
	 BEGIN
        FOR E IN (SELECT CODPROD
                    FROM PCEST
                   WHERE (CODPROD, CODFILIAL) IN
                         (SELECT PCPEDI.CODPROD
                                ,NVL(PCPEDI.CODFILIALRETIRA,
                                     PCPEDC.CODFILIAL) CODFILIAL
                            FROM PCPEDC, PCPEDI
                           WHERE PCPEDC.NUMPED = PCPEDI.NUMPED
                             AND PCPEDC.NUMPED =  VNPROXNUMPED)

                     FOR UPDATE)
        LOOP
          EXIT;
        END LOOP;

        FOR REGISTROS IN (SELECT PCPEDI.CODPROD
                                ,PCPEDI.TIPOENTREGA
                                ,PCPEDI.POSICAO
                                ,NVL(PCPEDI.CODFILIALRETIRA,
                                     PCPEDC.CODFILIAL) CODFILIAL
                                ,SUM(PCPEDI.QT) QT
                                ,PCPEDC.NUMPED
                                ,PCPEDI.NUMSEQ
                            FROM PCPEDC, PCPEDI
                           WHERE PCPEDC.NUMPED = PCPEDI.NUMPED
                             AND PCPEDC.NUMPED =  VNPROXNUMPED

                           GROUP BY PCPEDC.NUMPED
                                   ,PCPEDI.CODPROD
                                   ,PCPEDI.NUMSEQ
                                   ,PCPEDI.TIPOENTREGA
                                   ,PCPEDI.POSICAO
                                   ,NVL(PCPEDI.CODFILIALRETIRA,
                                        PCPEDC.CODFILIAL))
        LOOP
          IF (VSPOSICAO IN ('P', 'B')) OR
             ((REGISTROS.TIPOENTREGA = 'EF') AND (REGISTROS.POSICAO = 'P'))
          THEN
            VS_MOVEST       := PKG_ESTOQUE.PENDENTE_INCLUIR(REGISTROS.NUMPED,
                                                            REGISTROS.CODPROD,
                                                            REGISTROS.NUMSEQ,
                                                            TRUE,
                                                            NULL,
                                                            MSGEST);
            VSMOTIVOPOSICAO := 'PRODUTO SEM ESTOQUE';
          ELSE
            IF VSPOSICAO IN('L','M')
            THEN
              VS_MOVEST := PKG_ESTOQUE.RESERVA_INCLUIR(REGISTROS.NUMPED,
                                                       REGISTROS.CODPROD,
                                                       REGISTROS.NUMSEQ,
                                                       TRUE,
                                                       NULL,
                                                       MSGEST);
            END IF;
          END IF;

          IF VS_MOVEST = 'N'
          THEN
            RAISE EX_MOVEST;
          END IF;

        END LOOP;

     EXCEPTION
        WHEN OTHERS THEN
          PMSG := SQLCODE || ' - ' || SQLERRM ||
                  ' -1- Erro: Nao foi possivel atualizar o estoque dos itens';
          RAISE;
     END;
    --tarefa 85855
    FOR REG_ITENS IN (SELECT PCPEDI.CODPROD, PCPEDI.CODUSUR, PCPEDI.NUMSEQ
                        FROM PCPEDI
                       WHERE PCPEDI.NUMPED = VNPROXNUMPED)
    LOOP

      VBSALDORCA := PC_PKG_CONTROLARSALDORCA.CCRCA_INCLUIR_ITEM_PEDIDO(VNCODEMITENTE,
                                                                       300,
                                                                       REG_ITENS.CODUSUR,
                                                                       VNPROXNUMPED,
                                                                       REG_ITENS.CODPROD,
                                                                       REG_ITENS.NUMSEQ);

    END LOOP;
  END IF;
EXCEPTION
  WHEN ERRO_CONDVENDA THEN
    ROLLBACK;
    PMSG := 'Erro: Procedimento somente só pode ser executado para venda TV7 com Venda Assisitda';

  WHEN EX_MOVEST THEN
    ROLLBACK;
    PMSG := 'Erro: Não foi possível movimentar o estoque. Menssagem PKG_ESTOQUE: "' || CHR(13) || MSGEST;

  WHEN ERRO_PROXNUMPEDZERADO THEN
    ROLLBACK;
    PMSG := 'Erro: Não foi possível obter número de pedido para geração do pedido TV8.';

  WHEN ERRO_ESTOQUE_TV8 THEN
    ROLLBACK;
    PMSG :=  'Erro ao gerar pedido TV8: Existem Produtos neste pedido que não tem estoque disponivel e está parametrizado para não permitir venda sem estoque.' ||
             CHR(13) || 'Qt. prod. sem estoque: ' || VNCOUNTPRODSEMESTOQUEDISP || CHR(13) || VSLISTAPRODRETORNOESTOQUE;

  WHEN OTHERS THEN
    ROLLBACK;
    PMSG := 'Erro ao gerar pedido TV8.' || '^M' || 'Erro: ' || SQLCODE || '-' || SQLERRM;
END PRC_GERARPEDTV8;
