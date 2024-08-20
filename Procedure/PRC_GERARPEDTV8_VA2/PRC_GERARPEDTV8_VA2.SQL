CREATE OR REPLACE PROCEDURE PRC_GERARPEDTV8_VA2(
   pnumped         IN       NUMBER
  ,pRotina         IN       NUMBER
  ,pmsg            OUT      VARCHAR2
  ,pnumpedgerado   OUT      NUMBER
  ,pmotivo         OUT      NUMBER
  ,pcommit         IN       VARCHAR2 DEFAULT 'S'
)
IS
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

    02/06/2010   Marden 109277   entrega futura, novo tipo criado para tipo de entrega EF = Entrega Futura
    02/06/2010   Marden 109277   entrega futura adicionado registros.TIPOENTREGA = 'EF' AND
                                 PCPEDI.POSICAO = 'P' para registrar o item como qtpendente ao inves de
                                 qtreserv.
    10/06/2010   Marden 109480   bloqueiavendaestpendente = S não bloquear quando PCPEDI.TIPOENTREGA = EF procurar tarefa 109480
    12/06/2012   Marden 162710   ajustado procedure para enviar o campo RP_IMEDIATA do pedido TV7 para o pedido TV8
    21/12/2012   Darlan 181419   gerar tabela pcitemrolo para o pedido TV8
    24/01/2013   Darlan 186760   verificar variável vbrotina4139 para geração da numeração do pedido tv8
    11/03/2013   Diego  191737   alterei para gravar o campo turnoentrega na pcpedc
    25/04/2013   Diego           Gravar campo serieecf = null
    29/07/2013   Darlan 205443   Gravar os campos unidade e refcor na pcpedi
    12/08/2013 Marden            Ajustado procedure para gravar log no campo assinatura para que este possa ser gravado
                                 tabela pclogestoque - ASSINATURA = 'FATURAMENTO_VA-LOCAL: 11111-V.20'||
                                                                '-NumPed:'||TO_CHAR(CAB.NUMPED)||
                                                                '-TipoEntrega:'||ITEM.TIPOENTREGA||
                                                                '-Qtde Pedido:'||TO_CHAR(ITEM.QT)||
                                                                '-vnqtloja:'||TO_CHAR(vnqtloja)||
                                                                '-vnqtgirog:'||TO_CHAR(vnqtgirog)||
                                                                '-serieecf:'||cab.serieecf||
                                                                '-Posicao Item:'||ITEM.POSICAO||
                                                                '-Posicao Cabec:'||CAB.POSICAO
    23/10/2013  Darlan           Gravar o campo pcpedi.codendent para endereço de entrega do pedido tv8
    15/10/2013  Darlan           tarefa do sprint 213712 - Gravar o campo pcpedi.ambiente no pedido tv8
    24/07/2014  Darlan           Gravar o campo pcpedc.codendentcli
    15/10/2014  Darlan / Marden  Ajustado procedure para não validar mais a variavel vsposicao estava gerando erro
                                 nos pedidos de venda assistida reservando o estoque quando deveria reservar a quantidade
                                 pendente
    07/11/2014  Darlan/Marden    Ajustado procedure para nao reservar pedido mais, somente mais gerar o tv8 mesmo...
    27/11/2014  Diego            gerar pecpedicesta para tv8
    07/07/2015  Darlan           solicitação HIS.01877.2015 gravar o campo pcpedi.numitemped
    10/11/2015 Marden   HIS.03653.2015 Ajuste Tintometrico para prodizir e vender a tinta produzida sem passar pelo tintometrico
    23/12/2015 Darlan           Ajustada procedure para gravação dos campo de cálculo do ICMS Partilha HIS.04555.2015
    06/01/2016 Marden            Novo campo ICMS Partilha ALIQINTERORIGPART
    07/04/2016 Darlan            Gravar o campo pcpedc.tipoprioridadeentrega
    09/05/2016 Darlan            solicitação 6187.050315.2016 Gravar o campo pcpedc.codclinf
    08/09/2016 Darlan            solicitação HIS.01411.2016 Gravar o campo pcpedi.numlote
    04/01/2017 Darlan            Gravar o campo pcpedi.codsupervisor para projeto divisão de pastas rca's
    23/01/2017 Darlan            Gravar os campos pcpedc.motoristaveiculo, pcpedc.ufveiculo e pcpedc.placaveiculo para sair as informações no DANFE
    07/11/2017 Darlan            solicitação HIS.03862.2016 gravar o campo pcpedc.vlentrada
    27/03/2018 Marden            Mat-573 pcpedi.campo para determinar se baixa estoque loja ou não
    19/07/2018 Darlan            MAT-1309 gravar os campos VLBASEFCPST ALIQICMSFECP VLFECP para NFE 4.0
    17/08/2018 Darlan            MAT-1372 gravar o campo PCPEDI.VLICMSPARTPTABELA para o cálculo do partilha
    31/01/2019 Darlan            MAT-2062 gravar o campo pcpedc.tipodocumento
*********************************************************************************************************************************/
   --Variáveis para Tabela
   vncodusur                     pcpedc.codusur%TYPE;
   vnpercvenda                   pcpedc.percvenda%TYPE;
   vnproxnumped                  pcusuari.proxnumped%TYPE;
   vncondvenda                   pcpedc.condvenda%TYPE;
   vsvendasemestoque             pcconsum.aceitavendasemest%TYPE;
   vsbloqueiavendaestpendente    pcconsum.bloqueiavendaestpendente%TYPE;
   vsvendaassistida              pcpedc.vendaassistida%TYPE;
   vsrcabloqueado                pcusuari.bloqueio%TYPE;
   vsclientebloqueado            pcclient.bloqueio%TYPE;
   vsposicao                     pcpedc.posicao%TYPE;
   vfqtestoque                   pcest.qtest%TYPE;
   vbpassou                      BOOLEAN;
   --vbrotina4139                  BOOLEAN; usar paramento IN pRotina
   --Variáveis Estáticas
   vntotalitens                  INT;
   erro_condvenda                EXCEPTION;
   vbsaldorca                   boolean;
   vncodemitente                number;
   vPCPEDI                      PCPEDI%ROWTYPE;
   VPCPEDC                      PCPEDC%ROWTYPE; 

  FUNCTION F_PROX_NUMORCA RETURN NUMBER
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    VRETURN  PCUSUARI.PROXNUMPED%TYPE;
  BEGIN
    SELECT NVL( PROXNUMORC,1 )
      INTO VRETURN
      FROM PCCONSUM
    FOR UPDATE;

    UPDATE PCCONSUM
       SET PROXNUMORC = NVL( PROXNUMORC, 1 ) + 1;

    COMMIT;

    RETURN VRETURN;
  END F_PROX_NUMORCA;
  
BEGIN
   pmsg := '';
   vbpassou := TRUE;
   pmotivo := 0;
   pnumpedgerado := 0;

   SELECT condvenda
         ,NVL( vendaassistida, 'N' )
         ,percvenda
         ,codemitente
     INTO vncondvenda
         ,vsvendaassistida
         ,vnpercvenda
         ,vncodemitente
     FROM pcpedc
    WHERE numped = pnumped;

   IF     ( vncondvenda <> 7 )
      AND ( vsvendaassistida <> 'S' )
      AND ( vnpercvenda <> 100 ) THEN
      RAISE erro_condvenda;
   END IF;

   SELECT COUNT( 1 )
     INTO vntotalitens
     FROM pcpedi
    WHERE numped = pnumped;

/*
   SELECT NVL( pcconsum.aceitavendasemest, 'N' )
         ,NVL( pcconsum.bloqueiavendaestpendente, 'N' )
     INTO vsvendasemestoque
         ,vsbloqueiavendaestpendente
     FROM pcconsum;

   vbrotina4139 := FALSE;
   FOR registros IN ( SELECT pcpedi.codprod, pcpedi.numped
                            ,pcpedi.qt
                            ,pcpedi.tipoentrega
                            ,pcpedi.posicao
                            ,NVL( pcpedi.codfilialretira, pcpedc.codfilial )
                                                                    codfilial
                            ,NVL( pcpedi.rotinalanc, '4139' ) rotinalanc
                       FROM pcpedc, pcpedi
                      WHERE pcpedc.numped = pcpedi.numped
                        AND pcpedc.numped = pnumped ) LOOP
      IF vsbloqueiavendaestpendente = 'N' THEN
         SELECT (
                   NVL( pcest.qtestger, 0 )
                 - NVL( pcest.qtreserv, 0 )
                 - NVL( pcest.qtbloqueada, 0 )
                )
           INTO vfqtestoque
           FROM pcest
          WHERE codprod = registros.codprod
            AND codfilial = registros.codfilial;
      ELSE
         SELECT (
                   NVL( pcest.qtestger, 0 )
                 - NVL( pcest.qtreserv, 0 )
                 - NVL( pcest.qtbloqueada, 0 )
                 - NVL( pcest.qtpendente, 0 )
                )
           INTO vfqtestoque
           FROM pcest
          WHERE codprod = registros.codprod
            AND codfilial = registros.codfilial;

         IF     ( vfqtestoque < registros.qt )             --tarefa 109480
            AND ( vsvendasemestoque = 'N' ) and (registros.TIPOENTREGA <> 'EF') THEN
            vbpassou := FALSE;
         END IF;
      END IF;

      IF (registros.rotinalanc = '4139') THEN
        vbrotina4139 := TRUE;
      END IF;

   END LOOP;

   IF ( NOT(    ( vbpassou )
            OR ( vsvendasemestoque = 'S' ) ) ) THEN
      pmotivo := 1;
      pmsg :=
         'Existem Produtos neste pedido que não existe estoque, e está parametrizado para não permitir venda sem estoque';
   ELSE
   */
      IF vntotalitens > 0 THEN
         BEGIN
            SELECT pcpedc.codusur
                  ,NVL( pcclient.bloqueio, 'N' ) bloqueio
                  ,pcpedc.posicao
              INTO vncodusur
                  ,vsclientebloqueado
                  ,vsposicao
              FROM pcpedc, pcclient
             WHERE pcpedc.numped = pnumped
               AND pcpedc.codcli = pcclient.codcli;

            --IF vbrotina4139 = FALSE THEN
            IF pRotina <> 4139 THEN
			  vnproxnumped := FERRAMENTAS.F_PROX_NUMPED(vncodusur);
/*			
              SELECT     NVL( pcusuari.proxnumped, 1 )
                        ,NVL( pcusuari.bloqueio, 'N' )
                    INTO vnproxnumped
                        ,vsrcabloqueado
                    FROM pcusuari
                   WHERE codusur = vncodusur
              FOR UPDATE;

              UPDATE pcusuari
                 SET proxnumped =   NVL( proxnumped, 1 ) + 1
               WHERE codusur = vncodusur;
*/
            ELSE
              vnproxnumped := F_PROX_NUMORCA;
/*
              SELECT NVL( proxnumorc,1 )
                INTO vnproxnumped
                FROM pcconsum
              FOR UPDATE;

              UPDATE pcconsum
                 SET proxnumorc = NVL( proxnumorc, 1 ) + 1;
*/
            END IF;

--            COMMIT;
         EXCEPTION
            WHEN OTHERS THEN
               pmsg :=
                     SQLCODE
                  || ' - '
                  || SQLERRM
                  || ' -1- Erro ao buscar o próximo número de pedido';
               RAISE;
         END;
      END IF;

      BEGIN
         pnumpedgerado := vnproxnumped;


/*
         BEGIN
            FOR e IN
               ( SELECT    codprod
                      FROM pcest
                     WHERE ( codprod, codfilial ) IN(
                              SELECT pcpedi.codprod
                                    ,NVL(
                                        pcpedi.codfilialretira
                                       ,pcpedc.codfilial
                                     ) codfilial
                                FROM pcpedc, pcpedi
                               WHERE pcpedc.numped = pcpedi.numped
                                 AND pcpedc.numped = pnumped )
                FOR UPDATE ) LOOP
               EXIT;
            END LOOP;

            FOR registros IN ( SELECT pcpedi.codprod, pcpedi.numped
                                     ,pcpedi.qt
                                     ,PCPEDI.TIPOENTREGA
                                     ,PCPEDI.POSICAO
                                     ,NVL(
                                         pcpedi.codfilialretira
                                        ,pcpedc.codfilial
                                      ) codfilial
                                FROM pcpedc, pcpedi
                               WHERE pcpedc.numped = pcpedi.numped
                                 AND pcpedc.numped = pnumped ) LOOP
               IF (vsposicao IN( 'P', 'B' ) ) or
                  ((registros.TIPOENTREGA = 'EF' ) and (registros.POSICAO = 'P' )) THEN
                  UPDATE pcest
                     SET qtpendente =
                                    NVL( qtpendente, 0 )
                                  + NVL( registros.qt, 0 ),
                         PCEST.ASSINATURA = 'PRC_GERARPEDTV8_VA-LOCAL: 11111-V.22'||
                                             '-NumPed:'||TO_CHAR(registros.NUMPED)||
                                             '-TipoEntrega:'||registros.TIPOENTREGA||
                                             '-Qtde Pedido:'||TO_CHAR(registros.QT)||
                                             '-Posicao Item:'||registros.POSICAO

                   WHERE codprod = registros.codprod
                     AND codfilial = registros.codfilial;
               ELSE
                  IF vsposicao = 'L' THEN
                     UPDATE pcest
                        SET qtreserv =
                                      NVL( qtreserv, 0 )
                                    + NVL( registros.qt, 0 ),
                         PCEST.ASSINATURA = 'PRC_GERARPEDTV8_VA-LOCAL: 22222-V.22'||
                                             '-NumPed:'||TO_CHAR(registros.NUMPED)||
                                             '-TipoEntrega:'||registros.TIPOENTREGA||
                                             '-Qtde Pedido:'||TO_CHAR(registros.QT)||
                                             '-Posicao Item:'||registros.POSICAO

                      WHERE codprod = registros.codprod
                        AND codfilial = registros.codfilial;
                  END IF;
               END IF;
            END LOOP;

            COMMIT;
         EXCEPTION
            WHEN OTHERS THEN
               pmsg :=
                     SQLCODE
                  || ' - '
                  || SQLERRM
                  || ' -1- Nao foi possivel atualizar o estoque dos itens';
               RAISE;
         END;

*/
         -- Fim tarefa 70737
		 
		 SELECT * INTO VPCPEDC FROM PCPEDC WHERE NUMPED = pnumped;
		 
		 VPCPEDC.NUMPED       	  := vnproxnumped; 
		 VPCPEDC.CODCLI           := NVL(VPCPEDC.CODCLITV8, VPCPEDC.CODCLI);		 
		 VPCPEDC.CONDVENDA 	  	  := 8;
		 VPCPEDC.NUMPEDENTFUT 	  := pnumped;
		 VPCPEDC.VLATEND      	  := 0;
		 VPCPEDC.VLTABELA     	  := 0;
		 VPCPEDC.VLCUSTOREAL  	  := 0;
		 VPCPEDC.VLCUSTOFIN   	  := 0;
		 VPCPEDC.VLCUSTOCONT  	  := 0;
		 VPCPEDC.VLCUSTOREP   	  := 0;
		 VPCPEDC.OBSFRETENF3  	  := NULL;
		 VPCPEDC.EANENTREGA   	  := 0;
		 VPCPEDC.EANCOBRANCA  	  := 0;
		 VPCPEDC.CODFUNCCALCFRETE := 0;
		 VPCPEDC.DTCALCFRETE      := NULL;
		 VPCPEDC.NUMFICHA         := NULL;
		 
		 INSERT INTO PCPEDC VALUES VPCPEDC;        


         -- Tarefa 79111
         INSERT INTO pcvendaconsum
                     (
                       numped
                      ,cliente
                      ,cgcent
                      ,enderent
                      ,bairroent
                      ,telent
                      ,municent
                      ,estent
                      ,cepent
                      ,ieent
                      ,nomecontato
                      ,telefonecontato
                      ,obscontato
                      ,email
                      ,codcidade
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
                  ,nomecontato
                  ,telefonecontato
                  ,obscontato
                  ,email
                  ,codcidade
              FROM pcvendaconsum
             WHERE numped = pnumped;
      -- Fim tarefa 79111
      EXCEPTION
         WHEN OTHERS THEN
            pmsg :=
                  SQLCODE
               || ' - '
               || SQLERRM
               || ' -2- Erro ao gerar pedido tipo 8';
            RAISE;
      END;

      BEGIN
	  
		FOR ITENS IN ( SELECT PCPEDI.*, ROWID ID_PCPEDI FROM PCPEDI WHERE numped = pnumped )
		LOOP
			SELECT * INTO VPCPEDI FROM PCPEDI WHERE ROWID = ITENS.ID_PCPEDI;
			
			VPCPEDI.NUMPED 				      := vnproxnumped;
			VPCPEDI.CODPROMOCAO 		    := NULL;
			VPCPEDI.TRUNCARITEM 		    := NULL;
			VPCPEDI.VLDIFALIQUOTAS 		  := 0;
			VPCPEDI.BASEDIFALIQUOTAS 	  := 0;
			VPCPEDI.PERCDIFALIQUOTAS 	  := 0;
			VPCPEDI.QTRESERVANT 		    := 0;
			VPCPEDI.POLITICAPRIORITARIA := NULL;
			VPCPEDI.PERCDESCPIS 		    := 0;
			VPCPEDI.PERCDESCCOFINS 		  := 0;
			VPCPEDI.VLDESCREDUCAOPIS 	  := 0;
			VPCPEDI.VLDESCREDUCAOCOFINS := 0;
			
			INSERT INTO PCPEDI VALUES VPCPEDI;
			
		END LOOP;
		
		EXCEPTION
         WHEN OTHERS THEN
            pmsg :=
                  SQLCODE
               || ' - '
               || SQLERRM
               || ' -3- Erro ao gerar os itens do pedido tipo 8';
            RAISE;
		END;
         
      

      --27/11/2014 gerar pecpedicesta para tv8
      BEGIN
         INSERT INTO PCPEDICESTA
                    (NUMPED
                    ,CODPROD
                    ,NUMSEQ
                    ,CODAUXILIAR
                    ,CODPRODMP
                    ,QTMP
                    ,PVENDA
                    ,PTABELA
                    ,PBASERCA
                    ,BASEICST
                    ,ST
                    ,STCLIENTEGNRE
                    ,PERCIPI
                    ,VLIPI
                    ,PERCISS
                    ,VLISS
                    ,VLDESCSUFRAMA
                    ,VLCUSTOFIN
                    ,VLCUSTOREAL
                    ,VLCUSTOREP
                    ,VLCUSTOCONT
                    ,VLDESCCUSTOCMV
                    ,CODST
                    ,PERCOM
                    ,PERDESCTAB
                    ,IVA
                    ,ALIQICMS1
                    ,ALIQICMS2
                    ,PAUTA
                    ,PERCBASERED
                    ,CUSTOFINEST
                    ,PERCBASEREDSTFONTE
                    ,PERCBASEREDST
                    ,PERDESCCUSTO
                    ,CODICMTAB
                    ,TXVENDA
                    ,PERFRETECMV
                    ,VLDESCRODAPE
                    ,VLACRESCRODAPE
                    ,CODECF
                    ,PVENDAANTERIOR
                    ,PERDESCPOLITICA
                    ,VLDIFALIQUOTAS
                    ,BASEDIFALIQUOTAS
                    ,PERCDIFALIQUOTAS
                    ,VLFRETE_RATEIO
                    ,VLOUTRAS_RATEIO
                    ,BASEICST_ANT_RATEIO
                    ,ST_ANT_RATEIO
                    ,ST_DIF_RATEIO
                    ,QTUNITEMB
                    ,PERCOM2
                    ,PERCOM3
                    ,PERCOM4
                    ,VLITEMTRIBUTOS
                    ,PERCTRIBUTOS
                    ,CODPRODTINTA
                    ,VLBASEPARTDEST -- partilha
                    ,ALIQFCP
                    ,PERCBASEREDPART
                    ,VLFCPPART
                    ,VLICMSPART
                    ,PERCPROVPART
                    ,VLICMSDIFALIQPART
                    ,ALIQINTERNADEST
                    ,VLICMSPARTDEST
                    ,VLICMSPARTREM -- fim partilha
                    ,ALIQINTERORIGPART
                    ,UTILIZOUMOTORCALCULO
                    )
            (SELECT vnproxnumped
                    ,CODPROD
                    ,NUMSEQ
                    ,CODAUXILIAR
                    ,CODPRODMP
                    ,QTMP
                    ,PVENDA
                    ,PTABELA
                    ,PBASERCA
                    ,BASEICST
                    ,ST
                    ,STCLIENTEGNRE
                    ,PERCIPI
                    ,VLIPI
                    ,PERCISS
                    ,VLISS
                    ,VLDESCSUFRAMA
                    ,VLCUSTOFIN
                    ,VLCUSTOREAL
                    ,VLCUSTOREP
                    ,VLCUSTOCONT
                    ,VLDESCCUSTOCMV
                    ,CODST
                    ,PERCOM
                    ,PERDESCTAB
                    ,IVA
                    ,ALIQICMS1
                    ,ALIQICMS2
                    ,PAUTA
                    ,PERCBASERED
                    ,CUSTOFINEST
                    ,PERCBASEREDSTFONTE
                    ,PERCBASEREDST
                    ,PERDESCCUSTO
                    ,CODICMTAB
                    ,TXVENDA
                    ,PERFRETECMV
                    ,VLDESCRODAPE
                    ,VLACRESCRODAPE
                    ,CODECF
                    ,PVENDAANTERIOR
                    ,PERDESCPOLITICA
                    ,VLDIFALIQUOTAS
                    ,BASEDIFALIQUOTAS
                    ,PERCDIFALIQUOTAS
                    ,VLFRETE_RATEIO
                    ,VLOUTRAS_RATEIO
                    ,BASEICST_ANT_RATEIO
                    ,ST_ANT_RATEIO
                    ,ST_DIF_RATEIO
                    ,QTUNITEMB
                    ,PERCOM2
                    ,PERCOM3
                    ,PERCOM4
                    ,VLITEMTRIBUTOS
                    ,PERCTRIBUTOS
                    ,CODPRODTINTA
                    ,VLBASEPARTDEST -- partilha
                    ,ALIQFCP
                    ,PERCBASEREDPART
                    ,VLFCPPART
                    ,VLICMSPART
                    ,PERCPROVPART
                    ,VLICMSDIFALIQPART
                    ,ALIQINTERNADEST
                    ,VLICMSPARTDEST
                    ,VLICMSPARTREM -- fim partilha
                    ,ALIQINTERORIGPART
                    ,UTILIZOUMOTORCALCULO
                    FROM pcpedicesta
                    WHERE numped = pnumped);


      EXCEPTION
         WHEN OTHERS THEN
            pmsg :=
                  SQLCODE
               || ' - '
               || SQLERRM
               || ' -3.1- Erro ao gerar os itens do pcpedicesta tipo 8';
            RAISE;
      END;


      -- tarefa 181419 gerar pcitemrolo
      BEGIN
         INSERT INTO pcitemrolo
                     ( codfilial,
                       numped,
                       numrolo,
                       codprod,
                       qt,
                       numorca,
                       numseq,
                       numlote,
                       dtvenc,
                       codcor )
            ( SELECT codfilial,
                     vnproxnumped,
                     numrolo,
                     codprod,
                     qt,
                     numorca,
                     numseq,
                     numlote,
                     dtvenc,
                     codcor
               FROM pcitemrolo
              WHERE numped = pnumped );
      EXCEPTION
         WHEN OTHERS THEN
            pmsg :=
                  SQLCODE
               || ' - '
               || SQLERRM
               || ' -3- Erro ao gerar os itens do pcitemrolo tipo 8';
            RAISE;
      END;
      -- fim tarefa 181419

             --tarefa 85855
                for reg_itens in ( SELECT PCPEDI.CODPROD,
                                 PCPEDI.CODUSUR,
                                 PCPEDI.NUMSEQ
                          FROM   PCPEDI
                          WHERE  PCPEDI.NUMPED = vnproxnumped
                                 ) loop




            vbsaldorca := pc_pkg_controlarsaldorca.ccrca_incluir_item_pedido (
                                    vncodemitente,
                                    300,
                                    reg_itens.codusur,
                                    VNPROXNUMPED,
                                    reg_itens.codprod,
                                    reg_itens.numseq);


          end loop;

          IF pcommit <> 'N' THEN
            COMMIT;
          END IF;

   --END IF;

EXCEPTION
   WHEN erro_condvenda THEN
      pmsg :=
            'Atenção'
         || '^M'
         || 'Procedimento somente só pode ser executado para venda TV7 com Venda Assisitda';
         ROLLBACK;
   WHEN OTHERS THEN
      pmsg :=
            'Erro ao gerar pedido TV8.'
         || '^M'
         || 'Erro: '
         || SQLCODE
         || '-'
         || SQLERRM;
         ROLLBACK;
END PRC_GERARPEDTV8_VA2;