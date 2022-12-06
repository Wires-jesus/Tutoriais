CREATE OR REPLACE PACKAGE BODY IMPORTARPRONTAENTREGA IS

	/*
      Package de Importação de Pedidos de Pronta Entrega (venda manifesto) com Sistemas de Forca de Vendas

      ----------------     Historico     ----------------
      Data        Responsável    Tarefa     Comentario
      16/08/2012  Andréa         169666     Primeira Versao - (alteracoes iniciais)
      23/08/2012  Andréa         166355     Gravar na pcpedcfvmanif :numped,retorno e posicao_atual. Na pcpedifvmanif : percipi e vlipi
      29/08/2012  Andrea         171941     Gravar campo sugestao na pcpedi, buscando da pcpedifv para venda normal e pcpedifv para venda pronta entrega
      11/09/2012  Andréa         173573     Incluir processo de combo para pedido de venda manifesto
      12/09/2012  Andréa         173634     Incluir gravação do turno de entrega no pedido
      20/09/2012  Andréa         174865     Incluir parâmetros codusur (para todos os registros que tenha codusur na tabela) e
                                                numpedrca ( apenas para os pedidos de venda normal) para disparar a package
      11/10/2012  Andréa         177348     Validar data de emissão de pedido que gera NFE
      30/10/2012  Andréa         177937     Incluir validação de saldo de rca. Caso n"ao tenha saldo suficiente, rejeitar todo o pedido.
                                            Validar parâmetro bonificaltdebcredrca para vendas bonificadas (cobrança e plano bonificados) .
      13/11/2012  Andréa         180104     Gravar numtransvendatv13 no pedido Tv14
      13/11/2012  Andréa         180106     Incrementar proxnumpedforca
      14/11/2012  Andréa         180110     Ler novos campos na pcpedcfvmanif e gravar na pcpedc.
      23/11/2012  Andréa                    Alterar forma de incluir pedido de venda manifesto com cobrança e plano bonificado
      15/01/2013  Andrea         187030     Atualizacao no processo de preco por embalagem
      24/01/2013  Andréa         180108     Implementar processo de troca
      08/02/2013  Andréa         189481     Retirar validação de cobrança bonidicada com plano de pagamento bonificado
      01/03/2013  Andréa         191255     Caso o produto a tributação do item e o cliente seja stfonte, somar o valor de st enviado ao preço de tabela
      06/03/2013  Andréa         191680     Corrigir gravação do codicmtab para pessoa fisica
      20/03/2013  Andréa         193022     Gravar campos para geração de nfe em contigencia
      20/03/2013  Andréa         193035     Para pedido bonificados validar se é obrigatório o envio da informação de qual é o pedido que gerou a bonificação
      21/03/2013  Andréa         188740     Incluir validação de cotas de clientes e rcas (pcprodusur)
      05/04/2013  Andréa         194424     Alterar para lançar os créditos antes dos débitos na conta corrente do rca. Este procedimento já é feito para verificar saldo disponível, precisou ser feito
                                               no lançamento também, por caus de uma constraint no cliente que não deixa atualizar o vlcorrente negativo.
      08/04/2013  Andréa         194518    Incluir chamada da procedure PRC_GERARPEDIDOITEMCOMST para separar pedido com item que tenha st
      11/04/2013  Andréa         195140    Alterar para considerar um pedido bonificado quando a cobrança for BNFT e não BNF
      15/04/2013  Andrea         195140    Considerar BNF e BNFT cobranças válidas como bonificadas
      18/04/2013  Andréa         195889    Para troca considerar apenas BNFT
      18/04/2013  Andréa         195951    Retirar gravação do codigo do combo no campo codpromocao
      16/05/2013  Andréa         199256    Acrescentar mais um bloqueio para evitar gravação de pedido duplicado em caso de sessões paralelas
      05/06/2013  Andréa                   Acrescentar nvl para trunc(sysdate) quando passar parametro para executar a package de faturamento
      11/06/2013  Andréa         201354    Retirar leitura e gravacao de campo protocolo e gravacao dos campos  justificativacontigencia  e dtahoraentradacontigencia
      18/06/2013  Andréa         195136    Quando utilizar preço por embalagem, se o preço a ser utilizado for o de atacado e este estiver nulo ou zero, utilizar o preço de varejo
      24/06/2013  Andréa         196064    Acrescentar validação do percentual maximo de acrescimo para fv
      25/06/2013  Andréa         185261    Gravar campo utilizavendaporembalagem na pcpedc
      07/08/2013  Andréa         206837    Incluir procedure que faz a verificação dos parametros da pcparamfilial
      09/08/2013  Andréa         207010    Incluir validação da nova coluna  usadebredrca da pcclient
      09/08/2013  Andréa         207032    Gravar utilizavendaporembalagem na pcpedc
      16/08/2013  Andréa         207039    Obrigar o envio do numero da nota e serie, caso esteja em modo contingencia .
                                           Gravar campo consumiunumnfe na pcpedc em modo contigencia para que  não gere nova numeração de nota.
      16/08/2013  Andréa         207714    Acrescentar parametro na chamada da procedure de preço Fixo da funcoesvendas
      23/08/2013  Andrea         179985    Incluir restricao por plano de pagamento na validação de combo
                                           Incluir validação do codauxiliar no preço fixo, caso esteja parametrizado precoporembalagem
      20/09/2013  Andréa         211577    Corrigir para aplicar o percentual de desconto quando tiver 2 politicas automáticas na 561, sendo uma de acrescimo e outra de desconto
      08/10/2013  Andréa         213286    Corrigir validação de comissão nula
      18/10/2013  Andréa         213971    Correções em obrigatoriedade de colunas em modo de contingencia
      19/11/2013  Andréa         HIS.00204.2013    Incluir a opção de utilizar o parâmetro numpedrca para importar o pedido de pronta entrega, quando enviar o parametro p_tiporeg = 9
      13/02/2014  Andréa         HIS.00141.2014    Incluir a opção de gerar boleto após o faturamento do pedido
      13/01/2014  Andréa         HIS.00224.2014    Atualizar campo PROXNUMNFESCANTV14 na tabela PCROTAEXP para pedidos em contingência
      18/03/2014  Unilson        0.031405.2014     Corrigir validação dos campos NUMNOTA e SERIE nulos quando o parametro MODEMISSAONFETV14 = 'B'
                                                   Alterar nome do campo GERARBOLETOAUTO para GERARBOLETOAUTOVENDAMANIF da tabela PCPEDCFVMANIF
      09/04/2014  Unilson        HIS.01145.2014    Inclusão de validação dos parâmetros ROTAUTILIZADAVENDATIPO14 da 132 e CONTROLENFEPORSERIE e CONTROLENFEPORROTA da PCFILIAL
      05/06/2014  Unilson                          Inclusão de validação do vinculo do RCA com a Rota, bem como se foram definidos PROXNUMNFESCANTV14 e SERIENFETV14 na PCROTAEXP,
                                                    para emissão de NFe, criando a proc valida_vinculo_nfe
      01/06/2014  Luciano Lima                     Tratamento dos campos de numero de formulario e selo da nfs por formulário
      17/10/2014  Luciano Lima   1198.104538.2014  Correção de erro de compilação

  */

  G_FORCA_ESPECIE_TP BOOLEAN                         := FALSE;

  FUNCTION PROXNUM(P_TABELA   IN VARCHAR2,
                   P_COLUNA   IN VARCHAR2,
                   P_FILTRO   IN VARCHAR2,
                   P_VLFILTRO IN VARCHAR2) RETURN NUMBER IS
  CR_AUX     SYS_REFCURSOR;
  VN_PROXNUM NUMBER;
  BEGIN

  OPEN CR_AUX FOR ('SELECT NVL('|| P_COLUNA ||',0)'  ||
                   '  FROM '    || P_TABELA ||
                   ' WHERE '    || P_FILTRO || ' = ' || P_VLFILTRO);

  FETCH CR_AUX INTO VN_PROXNUM;

  EXECUTE IMMEDIATE 'UPDATE '|| P_TABELA ||
                    '   SET '|| P_COLUNA || ' = ' ||P_COLUNA|| ' + 1 ' ||
                    ' WHERE '|| P_FILTRO || ' = ' ||P_VLFILTRO;

  CLOSE CR_AUX;

  COMMIT;
  RETURN VN_PROXNUM;

  EXCEPTION WHEN OTHERS THEN
    ROLLBACK;
    return 0;
  END PROXNUM;

PROCEDURE LOCK_PCMOV(P_NUMPED IN PCPEDC.NUMPED%TYPE) IS
  I NUMBER;
BEGIN
  FOR REG IN (SELECT NUMPED, CODPROD, NUMSEQ, PREFAT
                FROM (SELECT NUMPED, CODPROD, NUMSEQ, 'S' PREFAT
                        FROM PCMOVPREFAT
                       WHERE NUMPED = P_NUMPED
                      UNION
                      SELECT NUMPED, CODPROD, NUMSEQ, 'N' PREFAT
                        FROM PCMOV
                       WHERE NUMPED = P_NUMPED)) LOOP

    IF (REG.PREFAT = 'S') THEN
      SELECT NUMPED
        INTO I
        FROM PCMOV
       WHERE NUMPED = REG.NUMPED
         AND CODPROD = REG.CODPROD
         AND NUMSEQ = REG.NUMSEQ
         FOR UPDATE;
    ELSE
      SELECT NUMPED
        INTO I
        FROM PCMOVPREFAT
       WHERE NUMPED = REG.NUMPED
         AND CODPROD = REG.CODPROD
         AND NUMSEQ = REG.NUMSEQ
         FOR UPDATE;
    END IF;

  END LOOP;

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;

END LOCK_PCMOV;

	PROCEDURE PROC_REGISTRALOG(P_NUMPED        IN PCPEDC.NUMPED%TYPE,
														 P_NUMPEDRCA     IN PCPEDC.NUMPEDRCA%TYPE,
														 P_CODPROD       IN PCPRODUT.CODPROD%TYPE,
														 P_CODAUXILIAR   IN PCPEDI.CODAUXILIAR%TYPE,
														 P_CGCENT        IN PCCLIENT.CGCENT%TYPE,
														 P_CODIGOCOTACAO IN PCCOTA.CODCOTACAO%TYPE,
														 P_NUMRECADOFV   IN PCRECFUNC.NUMRECADOFV%TYPE,
														 P_NUMCONTAGEM   IN PCGONDOLAC.NUMCONTAGEM%TYPE,
														 P_CODUSUR       IN PCPEDC.CODUSUR%TYPE,
														 P_DATA          IN DATE,
														 P_CANCELADA     IN VARCHAR2,
														 P_TIPOREG       IN VARCHAR2,
														 -- 1 = generico / -1 = Clientes /2 = cabecalho / 3 = itens /4 = Contatos
														 P_ERRO     IN VARCHAR2,
														 P_LINHAREG IN NUMBER) IS
	BEGIN
		VNGCONTADOR := VNGCONTADOR + 1;
		GVETREGISTRALOG(VNGCONTADOR).NUMPED := P_NUMPED;
		GVETREGISTRALOG(VNGCONTADOR).NUMPEDRCA := P_NUMPEDRCA;
		GVETREGISTRALOG(VNGCONTADOR).CODPROD := P_CODPROD;
		GVETREGISTRALOG(VNGCONTADOR).CODAUXILIAR := P_CODAUXILIAR;
		GVETREGISTRALOG(VNGCONTADOR).CGCENT := P_CGCENT;
		GVETREGISTRALOG(VNGCONTADOR).CODIGOCOTACAO := P_CODIGOCOTACAO;
		GVETREGISTRALOG(VNGCONTADOR).NUMRECADOFV := P_NUMRECADOFV;
		GVETREGISTRALOG(VNGCONTADOR).NUMCONTAGEM := P_NUMCONTAGEM;
		GVETREGISTRALOG(VNGCONTADOR).CODUSUR := P_CODUSUR;
		GVETREGISTRALOG(VNGCONTADOR).DATA := P_DATA;
		GVETREGISTRALOG(VNGCONTADOR).CANCELADA := P_CANCELADA;
		GVETREGISTRALOG(VNGCONTADOR).TIPOREG := P_TIPOREG;
		GVETREGISTRALOG(VNGCONTADOR).ERRO := P_ERRO;
		GVETREGISTRALOG(VNGCONTADOR).LINHAREG := P_LINHAREG;

	END PROC_REGISTRALOG;

	PROCEDURE PROC_LERPARAMETROS(P_EXISTERRO IN OUT BOOLEAN) IS
		VSDIRIMPORTACAOFV PCCONSUM.DIRIMPORTACAOFV%TYPE;
	BEGIN
		SELECT * INTO GREGPCCONSUM FROM PCCONSUM;
		GREGPCCONSUM.CODFILIALFV      := NVL(GREGPCCONSUM.CODFILIALFV, '1');
		GREGPCCONSUM.NUMCASASDECVENDA := NVL(GREGPCCONSUM.NUMCASASDECVENDA, 2);

	EXCEPTION
		WHEN OTHERS THEN
			P_EXISTERRO := TRUE;
			PROC_REGISTRALOG(NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 '1',
											 'Erro ao ler parametros#;' || SQLCODE || '-' ||
											 SQLERRM || ';',
											 NULL);
	END PROC_LERPARAMETROS;

FUNCTION func_lockpedido(P_NUMPEDRCA IN NUMBER
                          ,P_CODUSUR IN NUMBER
                          ,P_DATA IN DATE
                          ,P_CGCCLI IN VARCHAR
                          ,P_TIPOLEITURA IN NUMBER)
  RETURN BOOLEAN IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  VNBLOQUEADO NUMBER := 0;

  BEGIN

    -- Lock do registro para evitar que dois processamentos capturem o pedido
    SELECT 1 INTO VNBLOQUEADO
      FROM PCPEDCFVMANIF
     WHERE NUMPEDRCA         = P_NUMPEDRCA
       AND CODUSUR           = P_CODUSUR
       --AND DTABERTURAPEDPALM = P_DATA
       AND CGCENT            = P_CGCCLI
       AND IMPORTADO         = P_TIPOLEITURA
    FOR UPDATE;

    IF VNBLOQUEADO > 0 THEN -- BLOQUEIA O REGISTRO AUTORIZANDO A IMPORTAÇÃO
      UPDATE PCPEDCFVMANIF
         SET IMPORTADO         = 4
       WHERE NUMPEDRCA         = P_NUMPEDRCA
         AND CODUSUR           = P_CODUSUR
         --AND DTABERTURAPEDPALM = P_DATA
         AND CGCENT            = P_CGCCLI;

      COMMIT;
      RETURN TRUE;
    END IF;

    -- PEDIDO JÁ ESTÁ EM PROCESSAMENTO, REJEITA A IMPORTAÇÃO
    ROLLBACK;
    RETURN FALSE;

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RETURN FALSE;
  END func_lockpedido;


  procedure func_retiralockpedido(P_NUMPEDRCA IN NUMBER
                          ,P_CODUSUR IN NUMBER
                          )
  --RETURN BOOLEAN
  IS  PRAGMA AUTONOMOUS_TRANSACTION;
  VNBLOQUEADO NUMBER := 0;

  BEGIN

      UPDATE PCPEDCFVMANIF
         SET IMPORTADO     = 3,
             OBSERVACAO_PC = 'REJEIÇÃO DE PROCESSAMENTO - IMPORTADO = 4'
       WHERE NUMPEDRCA = P_NUMPEDRCA
         AND CODUSUR = P_CODUSUR
         and IMPORTADO = 4;

      COMMIT;
      --RETURN TRUE;


  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
     -- RETURN FALSE;
  END func_retiralockpedido;

  PROCEDURE proc_atualizarpcautorc
  (
    p_numped     IN pcpedc.numped%TYPE,
    p_codusur    IN pcpedc.codusur%TYPE,
    p_codcli     IN pcpedc.codcli%TYPE,
    p_vlpendente IN NUMBER,
    p_limcred    IN NUMBER
  ) IS

    vnnumpedido pcautorc.numpedido%TYPE;

  BEGIN


    SELECT numpedido
      INTO vnnumpedido
      FROM pcautorc
     WHERE codusur = p_codusur
       AND codcli = p_codcli
       AND codfuncutilizacao IS NULL
       AND dtutilizacao IS NULL
       AND rownum = 1
     ORDER BY data;


    FOR reg IN (SELECT *
                  FROM pcautorc
                 WHERE numpedido = vnnumpedido
                   AND codusur = p_codusur
                   AND codcli = p_codcli
                   FOR UPDATE)
    LOOP

      EXIT;
    END LOOP;

    UPDATE pcautorc
       SET limcred           = p_limcred,
           vlpendente        = p_vlpendente,
           dtutilizacao      = trunc(SYSDATE),
           codfuncutilizacao = 8888,
           numpedutilizacao  = p_numped
     WHERE numpedido = vnnumpedido
       AND codusur = p_codusur
       AND codcli = p_codcli
       AND codfuncutilizacao IS NULL
       AND dtutilizacao IS NULL;


  END proc_atualizarpcautorc;

  FUNCTION func_validaautorizacaopcautorc
  (
    p_regcliente IN t_clientepedido,
    p_codusur    IN pcpedc.codusur%TYPE,
    p_regfilial  IN t_filial,
    p_vldisp     IN NUMBER,
    p_vlatend    IN NUMBER
  ) RETURN NUMBER IS

    vnvlliberado NUMBER;

  BEGIN

    BEGIN

      SELECT SUM(pcautorc.vlliberado)
        INTO vnvlliberado
        FROM pcautorc,
             pcempr
       WHERE ((pcautorc.codcli = p_regcliente.codcli) OR
             (p_regfilial.somacreditocliprincipal = 'S' AND (pcautorc.codcli IN (SELECT pcclient.codcli
                                                                                    FROM pcclient
                                                                                   WHERE codcliprinc = p_regcliente.codcliprinc))))
         AND pcautorc.codusur = p_codusur
         AND pcautorc.codfunc = pcempr.matricula
         AND pcautorc.liberalimcred = 'S'
         AND pcautorc.dtutilizacao IS NULL
         AND pcautorc.codfuncutilizacao IS NULL
         AND (p_vldisp + nvl(pcautorc.vlliberado,
                             0)) >= p_vlatend
         AND rownum = 1
       ORDER BY data;
    EXCEPTION
      WHEN OTHERS THEN

        vnvlliberado := 0;

    END;

    RETURN vnvlliberado;

  END func_validaautorizacaopcautorc;

  FUNCTION func_existelimitecliente
  (
    p_regpedido       IN T_NOTA,
    p_regcliente      IN T_CLIENTEPEDIDO,
    p_regfilial       IN T_FILIAL,
    p_vltotped        IN NUMBER,
    p_saldodisponivel OUT NUMBER
  ) RETURN BOOLEAN IS

    vncontasareceberemaberto NUMBER;
    vnvalorpedidospendentes  NUMBER;
    vnvllimcredtot           NUMBER;
    vnvltotped               NUMBER;

    vnVLBONIFIC              NUMBER;

  BEGIN

    p_saldodisponivel := 0;
    vnVLBONIFIC       := 0;
    vnvltotped        := p_vltotped;

    IF p_Regfilial.usabnflimitecredito = 'N' THEN

       select Sum((nvl(i.pvenda,0) - nvl(i.pbonific,0)) * i.qt)
         into vnvltotped
         from pcpedi i
        where i.numped = p_regpedido.numped;

    END IF;

    IF p_regfilial.somacreditocliprincipal = 'N'
    THEN

      IF p_Regfilial.usabnflimitecredito = 'S'
      THEN

        -- Pendencias no contas a receber do cliente
        SELECT SUM(NVL(pcprest.valor,
                       0))
          INTO vncontasareceberemaberto
          FROM pcprest
         WHERE pcprest.codcli = p_regcliente.codcli
           AND pcprest.dtpag IS NULL;

        SELECT SUM(NVL(vlatend,
                       0))
          INTO vnvalorpedidospendentes
          FROM pcpedc
         WHERE codcli = p_regcliente.codcli
           AND dtcancel IS NULL
           AND ((posicao IN ('L', 'M') and gregpcconsum.aceitavendabloq = 'S')
                or (posicao IN ('L', 'M', 'B') and gregpcconsum.aceitavendabloq = 'N'))
           AND pcpedc.numped <> p_regpedido.numped;

        SELECT SUM(qt * nvl(pbonific,0))
          INTO vnVLBONIFIC
          FROM pcpedi
         WHERE codcli = p_regcliente.codcli
           AND ((posicao IN ('L', 'M') and gregpcconsum.aceitavendabloq = 'S')
                or (posicao IN ('L', 'M', 'B') and gregpcconsum.aceitavendabloq = 'N'))
           AND nvl(bonific,'N') <> 'N'
           AND numped <> p_regpedido.numped;

        vnvalorpedidospendentes := nvl(vnvalorpedidospendentes,0) + nvl(vnVLBONIFIC,0);

      ELSE
        -- Pendencias no contas a receber do cliente
        SELECT SUM(NVL(pcprest.valor,
                       0))
          INTO vncontasareceberemaberto
          FROM pcprest
         WHERE pcprest.codcli = p_regcliente.codcli
           AND pcprest.dtpag IS NULL
           AND PCPREST.CODCOB NOT IN ('BNF', 'BNFT', 'BNTR', 'BNFR', 'BNRP');


        SELECT SUM(NVL(pcpedi.qt * (nvl(pcpedi.pvenda,0) - nvl(pcpedi.pbonific,0)),
                       0))
          INTO vnvalorpedidospendentes
          FROM pcpedc, pcpedi
         WHERE pcpedc.codcli = p_regcliente.codcli
           AND pcpedc.numped = pcpedi.numped
           AND pcpedc.data   = pcpedi.data
           AND pcpedc.dtcancel IS NULL
           AND ((pcpedc.posicao IN ('L', 'M') and gregpcconsum.aceitavendabloq = 'S')
                or (pcpedc.posicao IN ('L', 'M', 'B') and gregpcconsum.aceitavendabloq = 'N'))
           AND pcpedc.CODCOB NOT IN ('BNF', 'BNFT', 'BNTR', 'BNFR', 'BNRP')
           AND nvl(pcpedi.bonific,'N') = 'N'
           AND pcpedc.numped <> p_regpedido.numped;

      END IF;


      p_saldodisponivel := ((nvl(p_regcliente.limcred,
                                 0) * (1 + (NVL(gregpcconsum.perexcedelimcred,
                                                  0) / 100))) -
                           (NVL(vncontasareceberemaberto,
                                 0) + NVL(vnvalorpedidospendentes,
                                            0))) +
                            BuscarLimCredSazonal(p_regcliente.codcli,
                                                 p_regpedido.codusur,
                                                 p_regfilial.somacreditocliprincipal);

      p_saldodisponivel := ROUND(p_saldodisponivel,
                                 gregpcconsum.numcasasdecvenda);

      --Calcula o valor disponivel de credito para o cliente
      IF (vnvltotped > p_saldodisponivel) AND
         (p_regcliente.codcli not in (1,2,3)) and
         (p_regpedido.condvenda not in (4,5,8,11,20)) and
          not(((p_regpedido.CODCOB = 'D') or
              (p_regpedido.CODCOB = 'DH') or
              (p_regpedido.CODCOB = 'CAR') or
              (isCobrancaCartao(p_regpedido.CODCOB))) and
            (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_VERIFICALIMCREDCODCOBD',99,'N') = 'N'))
      THEN

        IF p_saldodisponivel + func_validaautorizacaopcautorc(p_regcliente,
                                                              p_regpedido.codusur,
                                                              p_regfilial,
                                                              p_saldodisponivel,
                                                              vnvltotped) >= vnvltotped
        THEN


          proc_atualizarpcautorc(p_regpedido.numped,
                                 p_regpedido.codusur,
                                 p_regpedido.codcli,
                                 (NVL(vncontasareceberemaberto,
                                      0) + NVL(vnvalorpedidospendentes,
                                                0)),
                                 p_regcliente.limcred);


          RETURN TRUE;

        ELSE
          RETURN FALSE;
        END IF;
      ELSE
        RETURN TRUE;
      END IF;

    ELSE

      IF p_Regfilial.usabnflimitecredito = 'S'
      THEN

        -- Pendencias no contas a receber do cliente
        SELECT SUM(NVL(pcprest.valor,
                       0))
          INTO vncontasareceberemaberto
          FROM pcprest
         WHERE (pcprest.codcli IN (SELECT pcclient.codcli
                                     FROM pcclient
                                    WHERE pcclient.codcliprinc = p_regcliente.codcliprinc) OR pcprest.codcli = p_regpedido.codcli)
           AND pcprest.dtpag IS NULL;

        -- Pedidos pendentes do cliente
        SELECT SUM(NVL(vlatend,
                       0))
          INTO vnvalorpedidospendentes
          FROM pcpedc
         WHERE (codcli IN (SELECT pcclient.codcli
                             FROM pcclient
                            WHERE pcclient.codcliprinc = p_regcliente.codcliprinc) OR codcli = p_regpedido.codcli)
           AND dtcancel IS NULL
           AND ((posicao IN ('L', 'M') and gregpcconsum.aceitavendabloq = 'S')
                or (posicao IN ('L', 'M', 'B') and gregpcconsum.aceitavendabloq = 'N'))
           AND pcpedc.numped <> p_regpedido.numped;

        SELECT SUM(qt * nvl(pbonific, 0))
          INTO vnVLBONIFIC
          FROM pcpedi, pcclient
         where pcpedi.codcli = pcclient.codcli
           and (pcclient.codcli = p_regpedido.codcli or
               pcclient.codcliprinc = p_regcliente.codcliprinc)
           AND ((posicao IN ('L', 'M') and gregpcconsum.aceitavendabloq = 'S')
                or (posicao IN ('L', 'M', 'B') and gregpcconsum.aceitavendabloq = 'N'))
           AND nvl(bonific, 'N') <> 'N'
           AND numped <> p_regpedido.numped;

        vnvalorpedidospendentes := vnvalorpedidospendentes + vnVLBONIFIC;

      ELSE

        -- Pendencias no contas a receber do cliente
        SELECT SUM(NVL(pcprest.valor,
                       0))
          INTO vncontasareceberemaberto
          FROM pcprest
         WHERE (pcprest.codcli IN (SELECT pcclient.codcli
                                     FROM pcclient
                                    WHERE pcclient.codcliprinc = p_regcliente.codcliprinc) OR pcprest.codcli = p_regpedido.codcli)
           AND pcprest.dtpag IS NULL
           AND PCPREST.CODCOB NOT IN ('BNF', 'BNFT', 'BNTR', 'BNFR', 'BNRP');

        -- Pedidos pendentes do cliente
        SELECT SUM(NVL(pcpedi.qt * (nvl(pcpedi.pvenda,0) - nvl(pcpedi.pbonific,0)),
                       0))
          INTO vnvalorpedidospendentes
          FROM pcpedc, pcpedi
         WHERE (pcpedc.codcli IN (SELECT pcclient.codcli
                                    FROM pcclient
                                   WHERE pcclient.codcliprinc = p_regcliente.codcliprinc) OR pcpedi.codcli = p_regpedido.codcli)
           AND pcpedc.numped = pcpedi.numped
           AND pcpedc.data   = pcpedi.data
           AND pcpedc.dtcancel IS NULL
           AND ((pcpedc.posicao IN ('L', 'M') and gregpcconsum.aceitavendabloq = 'S')
                or (pcpedc.posicao IN ('L', 'M', 'B') and gregpcconsum.aceitavendabloq = 'N'))
           AND pcpedc.CODCOB NOT IN ('BNF', 'BNFT', 'BNTR', 'BNFR', 'BNRP')
           AND nvl(pcpedi.bonific,'N') = 'N'
           AND pcpedc.numped <> p_regpedido.numped;

      END IF;



      SELECT SUM(pcclient.limcred)
        INTO vnvllimcredtot
        FROM pcclient
       WHERE (pcclient.codcliprinc = p_regcliente.codcliprinc OR pcclient.codcli = p_regpedido.codcli);

      p_saldodisponivel := ((nvl(vnvllimcredtot,
                                 0) * (1 + (NVL(gregpcconsum.perexcedelimcred,
                                                  0) / 100))) -
                           (NVL(vncontasareceberemaberto,
                                 0) + NVL(vnvalorpedidospendentes,
                                            0))) +
                            BuscarLimCredSazonal(p_regcliente.codcli,
                                                 p_regpedido.codusur,
                                                 p_regfilial.somacreditocliprincipal);

      p_saldodisponivel := ROUND(p_saldodisponivel,
                                 gregpcconsum.numcasasdecvenda);

      --Calcula o valor disponivel de credito para o cliente
      IF (vnvltotped > p_saldodisponivel) AND
         (p_regcliente.codcli not in (1,2,3)) and
         (p_regpedido.condvenda not in (4,5,8,11,20)) and
          not(((p_regpedido.CODCOB = 'D') or
              (p_regpedido.CODCOB = 'DH') or
              (p_regpedido.CODCOB = 'CAR') or
              (isCobrancaCartao(p_regpedido.CODCOB))) and
            (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CON_VERIFICALIMCREDCODCOBD',99,'N') = 'N'))
      THEN

        IF p_saldodisponivel + func_validaautorizacaopcautorc(p_regcliente,
                                                              p_regpedido.codusur,
                                                              p_regfilial,
                                                              p_saldodisponivel,
                                                              vnvltotped) >= vnvltotped
        THEN

          proc_atualizarpcautorc(p_regpedido.numped,
                                 p_regpedido.codusur,
                                 p_regpedido.codcli,
                                 (NVL(vncontasareceberemaberto,
                                      0) + NVL(vnvalorpedidospendentes,
                                                0)),
                                 p_regcliente.limcred);


          RETURN TRUE;

        ELSE
          RETURN FALSE;
        END IF;
      ELSE
        RETURN TRUE;
      END IF;

    END IF;

  EXCEPTION
    WHEN OTHERS THEN

      RETURN FALSE;

  END func_existelimitecliente;

 PROCEDURE PROC_PROCESSARLEITURA(P_EXISTERRO   IN OUT BOOLEAN,
																	P_TIPOLEITURA IN NUMBER,
																	P_DATAINICIAL IN DATE,
																	P_DATAFINAL   IN DATE,
																	P_CODFILIAL   IN VARCHAR2,
																	P_TIPOREG     IN NUMBER,
																	P_CODUSUR     IN NUMBER,
																	P_NUMPEDRCA   IN NUMBER) IS
		VBLERNOTAOK       BOOLEAN;
		VBLERITEMNOTAOK   BOOLEAN;
		VNCONTORIGEMPRECO INTEGER;
		VNCONTNOTA        INTEGER;
		VNCONTITEMNOTA    INTEGER;

		VDDATAINICIAL DATE;
		VDDATAFINAL   DATE;

	BEGIN
		/*
       Campo IMPORTADO:
       Valor 0 = registro bloqueado.
       Valor 1 = registro liberado para leitura.
       Valor 2 = registro lido.
       Valor 3 = registro liberado para leitura novamente (rejeitado anteriormente).
    */

		-- Ajusta a faixa de datas conforme parametro.
		IF P_TIPOLEITURA = 1 THEN
			VDDATAINICIAL := TRUNC(SYSDATE) - 365;
			VDDATAFINAL   := TRUNC(SYSDATE);
		ELSE
			VDDATAINICIAL := P_DATAINICIAL;
			VDDATAFINAL   := P_DATAFINAL;
		END IF;

		VNCONTORIGEMPRECO := 0;
		VNCONTNOTA        := 0;
    VNCONTITEMNOTA    := 0;

		VNGDATAINICIO := VDDATAINICIAL;
		VNGDATAFIM    := VDDATAFINAL;

		--Pronta Entrega ( Venda manifesto)
		IF P_TIPOREG IS NULL OR P_TIPOREG = 9 THEN

			FOR CR_NOTA IN (SELECT CGCENT,
														 CODUSUR,
														 NUMPEDRCA,
														 OBSERVACAO,
														 CLIENTE,
														 ENDERECO,
														 BAIRRO,
														 MUNICIPIO,
														 CEP,
														 TELEFONE,
														 IEENT,
														 CODCOB,
														 CODPLPAG,
														 CODFILIAL,
														 NUMNOTA,
														 SERIE,
														 ESTADO,
														 NUMCARMANIF,
														 NVL(CANCELADA, 'N') CANCELADA,
														 NVL(DATA, TRUNC(SYSDATE)) DATA_EMISSAO,
														 CODCLI,
														 GERARNFE,
														 TURNOENTREGA,
														 DTABERTURAPEDPALM,
														 DTFECHAMENTOPEDPALM,
														 TIPOEMISSAO,
														 CONTINGENCIATV14,
														 CHAVENFE,
														 NUMPEDTV14,
														 JUSTIFICATIVACONTIGENCIA,
														 DTAHORAENTRADACONTIGENCIA,
														 GERARBOLETOAUTOVENDAMANIF,
														 --
														 NUMFORMULARIO,
														 NUMSELO,
														 --
                             --HIS.05228.2014
                             CODBANCOCM,
                             ----------------
                             VLOUTROS,
                             ASSINATURA,
                             UIDREGISTRO,
                             IDPARCEIRO,
                             NUMPED,
														 ROWNUM AS LINHA
												FROM PCPEDCFVMANIF
											 WHERE IMPORTADO = P_TIPOLEITURA
												 AND (NVL(TRUNC(DTINCLUSAO), TRUNC(SYSDATE)) BETWEEN
														 VDDATAINICIAL AND VDDATAFINAL)
												 AND ((NVL(CODFILIAL, '99') = NVL(P_CODFILIAL, '99') OR
														 NVL(CODFILIAL, '99') = '99') OR
														 (P_CODFILIAL = '99'))
												 AND (CODUSUR = P_CODUSUR OR P_CODUSUR IS NULL)
												 AND (NUMPEDRCA = P_NUMPEDRCA OR P_NUMPEDRCA IS NULL)
											 ORDER BY DTINCLUSAO) LOOP

				BEGIN
					VBLERNOTAOK        := FALSE;
					GREGNOTA.NUMPEDTV5 := NULL;


          GREGNOTA.ASSINATURA                := CR_NOTA.ASSINATURA;
          GREGNOTA.UIDREGISTRO               := CR_NOTA.UIDREGISTRO;
          GREGNOTA.IDPARCEIRO                := CR_NOTA.IDPARCEIRO;

					GREGNOTA.CODUSUR                   := CR_NOTA.CODUSUR;
					GREGNOTA.NUMPEDRCA                 := CR_NOTA.NUMPEDRCA;
					GREGNOTA.CONDVENDA                 := 14;
					GREGNOTA.POSICAO                   := 'L';
					GREGNOTA.OBS1                      := SUBSTR(CR_NOTA.OBSERVACAO,
																											 1,
																											 50);
					GREGNOTA.OBS2                      := SUBSTR(CR_NOTA.OBSERVACAO,
																											 51,
																											 50);
					GREGNOTA.DATA                      := CR_NOTA.DATA_EMISSAO;
					GREGNOTA.DTENTREGA                 := CR_NOTA.DATA_EMISSAO;
					GREGNOTA.RAZAOSOCIAL               := CR_NOTA.CLIENTE;
					GREGNOTA.ENDERECO                  := CR_NOTA.ENDERECO;
					GREGNOTA.BAIRRO                    := CR_NOTA.BAIRRO;
					GREGNOTA.CIDADE                    := CR_NOTA.MUNICIPIO;
					GREGNOTA.UF                        := CR_NOTA.ESTADO;
					GREGNOTA.CEP                       := CR_NOTA.CEP;
					GREGNOTA.TELEFONE                  := CR_NOTA.TELEFONE;
					GREGNOTA.INSCESTADUAL              := CR_NOTA.IEENT;
					GREGNOTA.CNPJ                      := CR_NOTA.CGCENT;
					GREGNOTA.NUMNOTAMANIF              := CR_NOTA.NUMNOTA;
					GREGNOTA.SERIEMANIF                := CR_NOTA.SERIE;
					GREGNOTA.CODFILIAL                 := CR_NOTA.CODFILIAL;
					GREGNOTA.CODCOB                    := CR_NOTA.CODCOB;
					GREGNOTA.CODPLPAG                  := CR_NOTA.CODPLPAG;
					GREGNOTA.NUMCARMANIF               := CR_NOTA.NUMCARMANIF;
					GREGNOTA.CANCELADA                 := CR_NOTA.CANCELADA;
					GREGNOTA.CODCLI                    := CR_NOTA.CODCLI;
					GREGNOTA.CODFILIALNF               := CR_NOTA.CODFILIAL;
					GREGNOTA.GERARNFE                  := CR_NOTA.GERARNFE;
					GREGNOTA.TURNOENTREGA              := CR_NOTA.TURNOENTREGA;
					GREGNOTA.DTABERTURAPEDPALM         := CR_NOTA.DTABERTURAPEDPALM;
					GREGNOTA.DTFECHAMENTOPEDPALM       := CR_NOTA.DTFECHAMENTOPEDPALM;
					GREGNOTA.ORIGEMPED                 := 'R';
					GREGNOTA.TIPOEMISSAO               := CR_NOTA.TIPOEMISSAO;
					GREGNOTA.CONTINGENCIATV14          := CR_NOTA.CONTINGENCIATV14;
					GREGNOTA.CHAVENFE                  := CR_NOTA.CHAVENFE;
					GREGNOTA.NUMPEDTV14                := CR_NOTA.NUMPEDTV14;
					GREGNOTA.JUSTIFICATIVACONTIGENCIA  := CR_NOTA.JUSTIFICATIVACONTIGENCIA;
					GREGNOTA.DTAHORAENTRADACONTIGENCIA := CR_NOTA.DTAHORAENTRADACONTIGENCIA;
					GREGNOTA.GERARBOLETOAUTO           := NVL(CR_NOTA.GERARBOLETOAUTOVENDAMANIF,
																										'N');
					GREGNOTA.NUMFORMULARIO             := CR_NOTA.NUMFORMULARIO;
					GREGNOTA.NUMSELO                   := CR_NOTA.NUMSELO;
					GREGNOTA.VLOUTROS                  := CR_NOTA.VLOUTROS;
          --HIS.05228.2014
          IF NVL(CR_NOTA.CODBANCOCM,0) <> 0 THEN

            BEGIN
              SELECT CODBANCO
                INTO GREGNOTA.CODBANCOCM
                FROM PCBANCO
               WHERE CODBANCO = CR_NOTA.CODBANCOCM;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                GREGNOTA.CODBANCOCM := NULL;
            END;

          ELSE
            GREGNOTA.CODBANCOCM := NULL;
          END IF;
          ----------------

					VBLERNOTAOK := TRUE;

          /**************************************************************************
          *BLOQUEIA O PEDIDO PRA NÃO SER PROCESSADO POR OUTRA CHAMADA DA INTEGRADORA*
          **************************************************************************/
          VBLERNOTAOK := func_lockpedido(CR_NOTA.numpedrca, CR_NOTA.codusur, CR_NOTA.dtaberturapedpalm, CR_NOTA.CGCENT, P_TIPOLEITURA);
          ---------------------------------------------------------------------------

					IF VBLERNOTAOK = TRUE THEN
						VNCONTNOTA := VNCONTNOTA + 1;
						GVET_REGNOTA(VNCONTNOTA) := GREGNOTA;
					END IF;

					IF VBLERNOTAOK = TRUE THEN
						FOR CR_ITENSNOTA IN (SELECT NUMPEDRCA,
																				CODPROD,
																				QT,
																				PVENDA,
																				BASECALCST,
																				ST,
																				PERCICM,
																				PERCBASERED,
																				BASEICMS,
																				NVL(CANCELADO, 'N') CANCELADA,
																				CODAUXILIAR,
																				PERCIPI,
																				VLIPI,
																				SUGESTAO,
																				CODCOMBO,
																				DTABERTURAPEDPALM,
																				CGCENT,
																				CODUSUR,
																				CODPRODTROCA,
																				QTTROCA,
																				DTVALPROD,
																				DTVALPRODTROCA,
																				CODINDENIZ,
																				AVARIA,
                                        VLOUTROS,
                                        NVL(BONIFIC, 'N') BONIFIC,
																				ROWNUM AS LINHA,
                                        ALIQICMSFECP,
                                        VLFECP
																	 FROM PCPEDIFVMANIF
																	WHERE NUMPEDRCA = CR_NOTA.NUMPEDRCA
                                    AND CODUSUR   = CR_NOTA.CODUSUR
																		AND NVL(CANCELADO, 'N') =
																				CR_NOTA.CANCELADA) LOOP

							BEGIN

								VBLERITEMNOTAOK                := FALSE;
								GREGITEMNOTA.NUMPEDRCA         := CR_ITENSNOTA.NUMPEDRCA;
								GREGITEMNOTA.CODPROD           := NVL(CR_ITENSNOTA.CODPROD,
																											0);
								GREGITEMNOTA.QT                := NVL(CR_ITENSNOTA.QT, 0);
								GREGITEMNOTA.PVENDA            := CR_ITENSNOTA.PVENDA;
								GREGITEMNOTA.BASEICMS          := CR_ITENSNOTA.BASEICMS;
								GREGITEMNOTA.BASEICST          := CR_ITENSNOTA.BASECALCST;
								GREGITEMNOTA.ST                := NVL(CR_ITENSNOTA.ST, 0);
								GREGITEMNOTA.PERCICM           := CR_ITENSNOTA.PERCICM;
								GREGITEMNOTA.PERCBASERED       := CR_ITENSNOTA.PERCBASERED;
								GREGITEMNOTA.CANCELADA         := CR_ITENSNOTA.CANCELADA;
								GREGITEMNOTA.CODAUXILIAR       := CR_ITENSNOTA.CODAUXILIAR;
								GREGITEMNOTA.PERCIPI           := CR_ITENSNOTA.PERCIPI;
								GREGITEMNOTA.VLIPI             := CR_ITENSNOTA.VLIPI;
								GREGITEMNOTA.SUGESTAO          := CR_ITENSNOTA.SUGESTAO;
								GREGITEMNOTA.CODCOMBO          := CR_ITENSNOTA.CODCOMBO;
								GREGITEMNOTA.DTABERTURAPEDPALM := CR_ITENSNOTA.DTABERTURAPEDPALM;
								GREGITEMNOTA.CGCENT            := CR_ITENSNOTA.CGCENT;
								GREGITEMNOTA.CODUSUR           := CR_ITENSNOTA.CODUSUR;
								GREGITEMNOTA.CODPRODTROCA      := NVL(CR_ITENSNOTA.CODPRODTROCA,
																											0);
								GREGITEMNOTA.QTTROCA           := NVL(CR_ITENSNOTA.QTTROCA,
																											0);
								GREGITEMNOTA.DTVALPROD         := CR_ITENSNOTA.DTVALPROD;
								GREGITEMNOTA.DTVALPRODTROCA    := CR_ITENSNOTA.DTVALPRODTROCA;
								GREGITEMNOTA.CODINDENIZ        := CR_ITENSNOTA.CODINDENIZ;
								GREGITEMNOTA.AVARIA            := NVL(CR_ITENSNOTA.AVARIA,
																											'N');
								GREGITEMNOTA.VLOUTROS          := CR_ITENSNOTA.VLOUTROS;
                GREGITEMNOTA.BONIFIC           := CR_ITENSNOTA.BONIFIC;
                GREGITEMNOTA.ALIQFECP          := NVL(CR_ITENSNOTA.ALIQICMSFECP, 0);
                GREGITEMNOTA.VLFECP            := NVL(CR_ITENSNOTA.VLFECP,0);
                GREGITEMNOTA.STPTABELA         := 0;
                GREGITEMNOTA.VLIPIPTABELA      := 0;

								VBLERITEMNOTAOK := TRUE;

								IF VBLERITEMNOTAOK = TRUE THEN
									VNCONTITEMNOTA := VNCONTITEMNOTA + 1;
									GVET_REGITEMNOTA(VNCONTITEMNOTA) := GREGITEMNOTA;
									-- incrementar contador de itens do pedido atual
									GVET_REGNOTA(VNCONTNOTA).NUMITENS := NVL(GVET_REGNOTA(VNCONTNOTA)
																													 .NUMITENS,
																													 0) + 1;
								END IF;
							EXCEPTION
								WHEN OTHERS THEN
									PROC_REGISTRALOG(NULL,
																	 CR_ITENSNOTA.NUMPEDRCA,
																	 CR_ITENSNOTA.CODPROD,
																	 CR_ITENSNOTA.CODAUXILIAR,
																	 NULL,
																	 NULL,
																	 NULL,
																	 NULL,
																	 CR_ITENSNOTA.CODUSUR,
																	 NULL,
																	 CR_ITENSNOTA.CANCELADA,
																	 '12',
																	 'Erro ao ler Item da Nota#;' || SQLCODE || '-' ||
																	 SQLERRM || ';',
																	 CR_ITENSNOTA.LINHA);
							END;
						END LOOP;
					END IF;
				EXCEPTION
					WHEN OTHERS THEN
						PROC_REGISTRALOG(NULL,
														 CR_NOTA.NUMPEDRCA,
														 NULL,
														 NULL,
														 NULL,
														 NULL,
														 NULL,
														 NULL,
														 CR_NOTA.CODUSUR,
														 NULL,
														 CR_NOTA.CANCELADA,
														 '11',
														 'Erro ao ler Nota#;' || SQLCODE || '-' ||
														 SQLERRM || ';',
														 CR_NOTA.LINHA);
				END;
			END LOOP;

		END IF;
		--Fim Pronta Entrega ( Venda MAnifesto)

	EXCEPTION
		WHEN OTHERS THEN
			P_EXISTERRO := TRUE;
			PROC_REGISTRALOG(NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 '1',
											 'ERRO AO LER PEDIDOS;' || SQLCODE || '-' || SQLERRM || ';',
											 NULL);
	END PROC_PROCESSARLEITURA;

	PROCEDURE PROC_CANCELAMENTO IS

		VSMENSAGEM      VARCHAR2(300);
		VSMENSAGEMAUX   VARCHAR2(200);
		VNNUMCAR        PCPEDC.NUMCAR%TYPE;
		VICONT          NUMBER := 0;
		VNNUMTRANSVENDA NUMBER;
		VSPOSICAO       PCPEDC.POSICAO%TYPE;
		VNCONTNOTAS     NUMBER;
		VNNUMPED        PCPEDC.NUMPED%TYPE;
		VSNOMEGUERRA    PCEMPR.NOME_GUERRA%TYPE;

	BEGIN

		VNCONTNOTAS   := GVET_REGNOTA.COUNT;
		VSNOMEGUERRA  := NULL;
		VSMENSAGEMAUX := NULL;

		BEGIN
			SELECT NOME_GUERRA
				INTO VSNOMEGUERRA
				FROM PCEMPR
			 WHERE MATRICULA = 8888;
		EXCEPTION
			WHEN OTHERS THEN

				PROC_REGISTRALOG(NULL,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 '1',
												 'Erro ao buscar nome do emitente 8888#;' ||
												 SQLCODE || '-' || SQLERRM || ';',
												 NULL);

		END;

		FOR I IN 1 .. VNCONTNOTAS LOOP

			IF GVET_REGNOTA(I).CANCELADA = 'S' THEN

				IF GVET_REGNOTA(I).GERARNFE = 'S' THEN

					UPDATE PCPEDCFVMANIF
						 SET IMPORTADO     = 3,
								 RETORNO       = 2,
								 NUMPED        = NULL,
								 POSICAO_ATUAL = 'R',
								 OBSERVACAO_PC = 'O CANCELAMENTO NAO PODE SER FEITO EM NOTAS COM GERARNFE = S'
					 WHERE NUMPEDRCA = GVET_REGNOTA(I)
					.NUMPEDRCA
             AND CODUSUR     = GVET_REGNOTA(I).CODUSUR
						 AND NUMCARMANIF = GVET_REGNOTA(I)
					.NUMCARMANIF
						 AND NVL(CANCELADA, 'N') = 'S';

					COMMIT;

				ELSE

					VNNUMTRANSVENDA := 0;
					VNNUMPED        := NULL;
					VSPOSICAO       := NULL;

					BEGIN

						SELECT PCPEDC.NUMPED, POSICAO
							INTO VNNUMPED, VSPOSICAO
							FROM PCPEDC
						 WHERE NUMPEDRCA = GVET_REGNOTA(I)
						.NUMPEDRCA
							 AND NUMCARMANIF = GVET_REGNOTA(I)
						.NUMCARMANIF
							 AND CONDVENDA = 14
							 AND CODUSUR = GVET_REGNOTA(I).CODUSUR;
					EXCEPTION
						WHEN NO_DATA_FOUND THEN
							VNNUMPED  := NULL;
							VSPOSICAO := NULL;

					END;

					BEGIN
						SELECT DISTINCT NUMTRANSVENDA
							INTO VNNUMTRANSVENDA
							FROM PCNFSAID
						 WHERE NUMPED = VNNUMPED;
					EXCEPTION
						WHEN NO_DATA_FOUND THEN
							VNNUMTRANSVENDA := 0;
					END;

					--verifica se existe nota que não foi importada e está sendo cancelada
					SELECT COUNT(*)
						INTO VICONT
						FROM PCPEDCFVMANIF
					 WHERE NUMPEDRCA = GVET_REGNOTA(I)
					.NUMPEDRCA
						 AND NUMCARMANIF = GVET_REGNOTA(I).NUMCARMANIF
             AND CODUSUR     = GVET_REGNOTA(I).CODUSUR
						 AND NVL(CANCELADA, 'N') = 'N'
						 AND IMPORTADO <> 2;

					IF VICONT > 0 THEN

						BEGIN
							UPDATE PCPEDCFVMANIF
								 SET IMPORTADO     = 2,
										 OBSERVACAO_PC = SUBSTR(OBSERVACAO_PC || ' ' ||
																						'-Nota cancelada no palm',
																						1,
																						300)
							 WHERE NUMPEDRCA = GVET_REGNOTA(I)
							.NUMPEDRCA
                 AND CODUSUR     = GVET_REGNOTA(I).CODUSUR
								 AND NUMCARMANIF = GVET_REGNOTA(I)
							.NUMCARMANIF
								 AND NVL(CANCELADA, 'N') = 'N';

							COMMIT;
						EXCEPTION
							WHEN OTHERS THEN
								ROLLBACK;
								VSMENSAGEMAUX := SQLCODE || ' ' || SQLERRM;

						END;

					ELSE

						IF VNNUMPED IS NOT NULL THEN

							IF (VSPOSICAO IN ('L', 'M')) OR (VNNUMTRANSVENDA = 0) THEN
								BEGIN
									IF VSPOSICAO = 'M' THEN
										--verificar se existe apenas este pedido no carregamento
										BEGIN
											SELECT NUMCAR
												INTO VNNUMCAR
												FROM PCPEDC
											 WHERE NUMPED = VNNUMPED;
										EXCEPTION
											WHEN NO_DATA_FOUND THEN
												VNNUMCAR := 0;
										END;

										IF VNNUMCAR <> 0 THEN
											SELECT COUNT(*)
												INTO VICONT
												FROM PCPEDC
											 WHERE NUMCAR = VNNUMCAR
												 AND DTCANCEL IS NULL;

											IF VICONT = 1 THEN

												INSERT INTO PCNFCAN
													(NUMTRANSENT,
													 NUMTRANSVENDA,
													 CODFUNCEMITE,
													 DATAEMISSAO,
													 CODFUNCCANC,
													 DATACANC,
													 VLTOTAL,
													 CODCLI,
													 CODFORNEC,
													 MOTIVO,
													 NUMPED,
													 NUMCAR,
													 NUMPEDCOMPRA,
													 CODROTINA,
													 DESCRICAO,
													 CODUSUR)
													SELECT NULL,
																 NULL,
																 8888,
																 TRUNC(SYSDATE),
																 8888,
																 TRUNC(SYSDATE),
																 VLTOTAL,
																 NULL,
																 NULL,
																 'PEDIDO PALM CANCELADO.RCA' ||
																 GVET_REGNOTA(I) .CODUSUR,
																 NULL,
																 NUMCAR,
																 NULL,
																 2596,
																 'Carregamento : ' || VNNUMCAR,
																 NULL
														FROM PCCARREG
													 WHERE NUMCAR = VNNUMCAR;

												UPDATE PCCARREG
													 SET PCCARREG.DT_CANCEL = TRUNC(SYSDATE),
															 CODFUNCCANCEL      = 8888,
															 TOTPESO            = 0,
															 TOTVOLUME          = 0,
															 VLTOTAL            = 0,
															 DESTINO            = NULL,
															 CODVEICULO         = 0,
															 OBSFATUR           = 'PEDIDO PALM CANCELADO.RCA' ||
																										GVET_REGNOTA(I).CODUSUR
												 WHERE NUMCAR = VNNUMCAR;
											END IF;
										END IF;
									END IF;

									INSERT INTO PCNFCAN
										(NUMTRANSENT,
										 NUMTRANSVENDA,
										 CODFUNCEMITE,
										 DATAEMISSAO,
										 CODFUNCCANC,
										 DATACANC,
										 VLTOTAL,
										 CODCLI,
										 CODFORNEC,
										 MOTIVO,
										 NUMPED,
										 NUMCAR,
										 NUMPEDCOMPRA,
										 CODROTINA,
										 DESCRICAO,
										 CODUSUR)
										SELECT NULL,
													 NULL,
													 8888,
													 TRUNC(SYSDATE),
													 8888,
													 TRUNC(SYSDATE),
													 VLTOTAL,
													 CODCLI,
													 NULL,
													 'CANC.NOTA ' || NUMNOTAMANIF,
													 NUMPED,
													 NUMCAR,
													 NULL,
													 2596,
													 'Cliente ' || GVET_REGNOTA(I) .CODCLI || '-' || ' CANC.NOTA ' || GVET_REGNOTA(I).NUMNOTAMANIF,
													 CODUSUR
											FROM PCPEDC
										 WHERE NUMPED = VNNUMPED;

									INSERT INTO PCNFCANITEM
										(NUMTRANSENT,
										 NUMTRANSVENDA,
										 CODFUNCEMITE,
										 DATAEMISSAO,
										 CODFUNCCANC,
										 DATACANC,
										 CODPROD,
										 QT,
										 PVENDA,
										 PTABELA,
										 NUMSEQ,
										 CODCLI,
										 CODFORNEC,
										 MOTIVO,
										 NUMPED,
										 NUMCAR,
										 NUMPEDCOMPRA,
										 CODROTINA,
										 DESCRICAO,
										 CODUSUR)
										SELECT NULL,
													 NULL,
													 8888,
													 TRUNC(SYSDATE),
													 8888,
													 TRUNC(SYSDATE),
													 CODPROD,
													 QT,
													 PVENDA,
													 PTABELA,
													 NUMSEQ,
													 CODCLI,
													 NULL,
													 'CANC.NOTA ' || GVET_REGNOTA(I) .NUMNOTAMANIF,
													 NUMPED,
													 NUMCAR,
													 NULL,
													 2596,
													 'Cliente ' || GVET_REGNOTA(I) .CODCLI || '-' || ' CANC.NOTA ' || GVET_REGNOTA(I).NUMNOTAMANIF,
													 CODUSUR
											FROM PCPEDI
										 WHERE NUMPED = VNNUMPED;

									UPDATE PCPEDC
										 SET POSICAO = 'C', DTCANCEL = TRUNC(SYSDATE)
									 WHERE NUMPED = VNNUMPED;

									UPDATE PCPEDI SET POSICAO = 'C' WHERE NUMPED = VNNUMPED;

									DELETE FROM PCFALTA WHERE NUMPED = VNNUMPED;

									UPDATE PCPEDCFVMANIF
										 SET IMPORTADO = 2, POSICAO_ATUAL = 'C', RETORNO = 2
									 WHERE NUMPEDRCA = GVET_REGNOTA(I)
									.NUMPEDRCA
                     AND CODUSUR     = GVET_REGNOTA(I).CODUSUR
										 AND NUMCARMANIF = GVET_REGNOTA(I)
									.NUMCARMANIF
										 AND NVL(CANCELADA, 'N') = 'S';

									COMMIT;
								EXCEPTION
									WHEN OTHERS THEN
										ROLLBACK;

										VSMENSAGEMAUX := SQLCODE || ' ' || SQLERRM;

								END;

							ELSIF VSPOSICAO = 'F' AND VNNUMTRANSVENDA <> 0 THEN
								VSMENSAGEM := '';
								P_PC_CACELA_NF(VSNOMEGUERRA,
															 VNNUMTRANSVENDA,
															 'CANC.NOTA ' || GVET_REGNOTA(I).NUMNOTAMANIF,
															 VSMENSAGEM);

								IF VSMENSAGEM = 'OK' THEN
									BEGIN
										UPDATE PCPEDCFVMANIF
											 SET IMPORTADO = 2, RETORNO = 2, POSICAO_ATUAL = 'C'
										 WHERE NUMPEDRCA = GVET_REGNOTA(I)
										.NUMPEDRCA
                       AND CODUSUR     = GVET_REGNOTA(I).CODUSUR
											 AND NUMCARMANIF = GVET_REGNOTA(I)
										.NUMCARMANIF
											 AND NVL(CANCELADA, 'N') = 'S';

										COMMIT;
									EXCEPTION
										WHEN OTHERS THEN
											ROLLBACK;
											VSMENSAGEMAUX := SQLCODE || ' ' || SQLERRM;

									END;
								ELSE
									BEGIN

										UPDATE PCPEDCFVMANIF
											 SET IMPORTADO     = 3,
													 RETORNO       = 2,
													 OBSERVACAO_PC = SUBSTR('Erro ao executar p_pc_cacela_nf : ' ||
																									VSMENSAGEM,
																									1,
																									300)
										 WHERE NUMPEDRCA = GVET_REGNOTA(I)
										.NUMPEDRCA
                       AND CODUSUR     = GVET_REGNOTA(I).CODUSUR
											 AND NUMCARMANIF = GVET_REGNOTA(I)
										.NUMCARMANIF
											 AND NVL(CANCELADA, 'N') = 'S';

										COMMIT;
									EXCEPTION
										WHEN OTHERS THEN
											ROLLBACK;

											VSMENSAGEMAUX := SUBSTR('Erro p_pc_cacela_nf : ' ||
																							VSMENSAGEM,
																							1,
																							100);

											COMMIT;
									END;
								END IF;
							END IF;

						END IF;

					END IF;

					IF TRIM(VSMENSAGEMAUX) IS NOT NULL THEN

						PROC_REGISTRALOG(VNNUMPED,
														 GVET_REGNOTA(I).NUMPEDRCA,
														 NULL,
														 NULL,
														 NULL,
														 NULL,
														 NULL,
														 NULL,
														 GVET_REGNOTA(I).CODUSUR,
														 NULL,
														 GVET_REGNOTA(I).CANCELADA,
														 '11',
														 VSMENSAGEMAUX || ';',
														 NULL);

					END IF;

				END IF;

			END IF;

		END LOOP;

	EXCEPTION
		WHEN OTHERS THEN
			ROLLBACK;
	END PROC_CANCELAMENTO;

	PROCEDURE PROC_VALIDA_RECEBIMENTO IS

		VSMENSAGEM       VARCHAR2(2000);
		VBVALIDO         BOOLEAN;
		VICONT           NUMBER;
		VSBOLETO         PCCOB.BOLETO%TYPE;
		VNNUMTRANSVENDA  PCPEDC.NUMTRANSVENDA%TYPE;
		VSREALIZARECEBFV VARCHAR2(1);

	BEGIN

		VBVALIDO        := TRUE;
		VSMENSAGEM      := NULL;
		VNNUMTRANSVENDA := NULL;

		--validar recebimento
		FOR REG_RECEB IN (SELECT P.CODCOB,
														 P.CODBARRA,
														 NUMBANCO,
														 NUMAGENCIA,
														 NUMCHEQUE,
														 NUMCONTACORRENTE,
														 DVAGENCIA,
														 DVCHEQUE,
														 DVCONTA,
														 CGCCPFCH,
														 P.NOSSONUMBANCO,
														 P.NUMPEDRCA,
														 P.CODUSUR,
														 P.CODFILIAL,
														 P.PREST,
														 P.NUMRECEBIMENTO
												FROM PCRECEBIMENTOFV P
											 WHERE NVL(P.VERIFICADO, 1) = VNGTIPOLEITURA) LOOP

			VBVALIDO        := TRUE;
			VSMENSAGEM      := NULL;
			VNNUMTRANSVENDA := NULL;

			BEGIN
				SELECT NVL(P.VALOR, 'N')
					INTO VSREALIZARECEBFV
					FROM PCPARAMFILIAL P
				 WHERE (P.CODFILIAL = REG_RECEB.CODFILIAL OR P.CODFILIAL = '99')
					 AND P.NOME = 'REALIZARECEBFV';
			EXCEPTION
				WHEN OTHERS THEN
					VSREALIZARECEBFV := 'N';

			END;

			IF VSREALIZARECEBFV = 'S' THEN

				SELECT COUNT(*)
					INTO VICONT
					FROM PCCOB
				 WHERE CODCOB = REG_RECEB.CODCOB;

				IF VICONT = 0 THEN

					VSMENSAGEM := 'Informação CODCOB invalida ou nula :' ||
												REG_RECEB.CODCOB;
					VBVALIDO   := FALSE;

				ELSE

					BEGIN
						SELECT NVL(BOLETO, 'N')
							INTO VSBOLETO
							FROM PCCOB
						 WHERE CODCOB = REG_RECEB.CODCOB;
						VSBOLETO := 'N';
					END;

					IF REG_RECEB.CODCOB = 'CH' THEN

						IF TRIM(REG_RECEB.CODBARRA) IS NULL THEN

							IF TRIM(REG_RECEB.NUMBANCO) IS NULL THEN

								IF VSMENSAGEM IS NULL THEN
									VSMENSAGEM := 'Informação NUMBANCO obrigatoria para cobrança do tipo :' ||
																REG_RECEB.CODCOB;
								ELSE
									VSMENSAGEM := VSMENSAGEM || CHR(13) ||
																'Informação NUMBANCO obrigatoria para cobrança do tipo :' ||
																REG_RECEB.CODCOB;
								END IF;
								VBVALIDO := FALSE;
							END IF;

							IF TRIM(REG_RECEB.NUMAGENCIA) IS NULL THEN
								IF VSMENSAGEM IS NULL THEN
									VSMENSAGEM := 'Informação NUMAGENCIA obrigatoria para cobrança do tipo :' ||
																REG_RECEB.CODCOB;
								ELSE
									VSMENSAGEM := VSMENSAGEM || CHR(13) ||
																'Informação NUMAGENCIA obrigatoria para cobrança do tipo :' ||
																REG_RECEB.CODCOB;
								END IF;
								VBVALIDO := FALSE;

							END IF;

							IF TRIM(REG_RECEB.NUMCHEQUE) IS NULL THEN
								IF VSMENSAGEM IS NULL THEN
									VSMENSAGEM := 'Informação NUMCHQUE obrigatoria para cobrança do tipo :' ||
																REG_RECEB.CODCOB;
								ELSE
									VSMENSAGEM := VSMENSAGEM || CHR(13) ||
																'Informação NUMCHQUE obrigatoria para cobrança do tipo :' ||
																REG_RECEB.CODCOB;
								END IF;

								VBVALIDO := FALSE;
							END IF;

							IF TRIM(REG_RECEB.NUMCONTACORRENTE) IS NULL THEN
								IF VSMENSAGEM IS NULL THEN
									VSMENSAGEM := 'Informação NUMCONTACORRENTE obrigatoria para cobrança do tipo :' ||
																REG_RECEB.CODCOB;
								ELSE
									VSMENSAGEM := VSMENSAGEM || CHR(13) ||
																'Informação NUMCONTACORRENTE obrigatoria para cobrança do tipo :' ||
																REG_RECEB.CODCOB;
								END IF;
								VBVALIDO := FALSE;

							END IF;

							IF TRIM(REG_RECEB.DVAGENCIA) IS NULL THEN
								IF VSMENSAGEM IS NULL THEN
									VSMENSAGEM := 'Informação DVAGENCIA obrigatoria para cobrança do tipo :' ||
																REG_RECEB.CODCOB;
								ELSE
									VSMENSAGEM := VSMENSAGEM || CHR(13) ||
																'Informação DVAGENCIA obrigatoria para cobrança do tipo :' ||
																REG_RECEB.CODCOB;
								END IF;
								VBVALIDO := FALSE;

							END IF;

							IF TRIM(REG_RECEB.DVCHEQUE) IS NULL THEN
								IF VSMENSAGEM IS NULL THEN
									VSMENSAGEM := 'Informação DVCHEQUE obrigatoria para cobrança do tipo :' ||
																REG_RECEB.CODCOB;
								ELSE
									VSMENSAGEM := VSMENSAGEM || CHR(13) ||
																'Informação DVCHEQUE obrigatoria para cobrança do tipo :' ||
																REG_RECEB.CODCOB;
								END IF;

								VBVALIDO := FALSE;

							END IF;

							IF TRIM(REG_RECEB.DVCONTA) IS NULL THEN
								IF VSMENSAGEM IS NULL THEN
									VSMENSAGEM := 'Informação DVCONTA obrigatoria para cobrança do tipo :' ||
																REG_RECEB.CODCOB;
								ELSE
									VSMENSAGEM := VSMENSAGEM || CHR(13) ||
																'Informação DVCONTA obrigatoria para cobrança do tipo :' ||
																REG_RECEB.CODCOB;
								END IF;
								VBVALIDO := FALSE;

							END IF;

							IF TRIM(REG_RECEB.CGCCPFCH) IS NULL THEN
								IF VSMENSAGEM IS NULL THEN
									VSMENSAGEM := 'Informação CGCCPFCH obrigatoria para cobrança do tipo :' ||
																REG_RECEB.CODCOB;
								ELSE
									VSMENSAGEM := VSMENSAGEM || CHR(13) ||
																'Informação CGCCPFCH obrigatoria para cobrança do tipo :' ||
																REG_RECEB.CODCOB;
								END IF;
								VBVALIDO := FALSE;

							END IF;

							IF VBVALIDO = FALSE THEN
								IF VSMENSAGEM IS NULL THEN
									VSMENSAGEM := 'Obrigatório o envio das informaçõees do cheque ou o CODBARRA para cobrança do tipo :' ||
																REG_RECEB.CODCOB;
								ELSE
									VSMENSAGEM := VSMENSAGEM || CHR(13) ||
																'Obrigatório o envio das informaçõees do cheque ou o CODBARRA para cobrança do tipo :' ||
																REG_RECEB.CODCOB;
								END IF;
								VBVALIDO := FALSE;
							END IF;

						END IF;

					ELSIF REG_RECEB.CODCOB = 'BK' OR VSBOLETO = 'S' THEN

						IF TRIM(REG_RECEB.NOSSONUMBANCO) IS NULL THEN
							IF VSMENSAGEM IS NULL THEN
								VSMENSAGEM := 'Informação NOSSONUMBANCO obrigatoria para cobrança do tipo :' ||
															REG_RECEB.CODCOB;
							ELSE
								VSMENSAGEM := VSMENSAGEM || CHR(13) ||
															'Informação NOSSONUMBANCO obrigatoria para cobrança do tipo :' ||
															REG_RECEB.CODCOB;
							END IF;
							VBVALIDO := FALSE;

						END IF;

					END IF;

					IF VBVALIDO = TRUE THEN

						SELECT COUNT(*)
							INTO VICONT
							FROM PCPEDC
						 WHERE NUMPEDRCA = REG_RECEB.NUMPEDRCA
							 AND CODUSUR = REG_RECEB.CODUSUR
							 AND CONDVENDA = 14;

						--tem o pedido
						IF VICONT = 1 THEN

							SELECT NUMTRANSVENDA
								INTO VNNUMTRANSVENDA
								FROM PCPEDC
							 WHERE NUMPEDRCA = REG_RECEB.NUMPEDRCA
								 AND CODUSUR = REG_RECEB.CODUSUR
								 AND CONDVENDA = 14;

							IF VNNUMTRANSVENDA IS NOT NULL THEN

								--se estiver valido
								UPDATE PCRECEBIMENTOFV P
									 SET P.NUMTRANSVENDA = VNNUMTRANSVENDA,
											 VERIFICADO      = 2,
											 OBSERVACAO_PC   = 'RECEBIMENTO VALIDADO COM SUCESSO'
								 WHERE P.NUMPEDRCA = REG_RECEB.NUMPEDRCA
									 AND P.CODUSUR = REG_RECEB.CODUSUR
									 AND P.VERIFICADO = VNGTIPOLEITURA
									 AND P.PREST = REG_RECEB.PREST
									 AND P.NUMRECEBIMENTO = REG_RECEB.NUMRECEBIMENTO;

							END IF;

						END IF;

					ELSE
						--se estiver invalido
						UPDATE PCRECEBIMENTOFV P
							 SET VERIFICADO = 3, OBSERVACAO_PC = VSMENSAGEM
						 WHERE P.NUMPEDRCA = REG_RECEB.NUMPEDRCA
							 AND P.CODUSUR = REG_RECEB.CODUSUR
							 AND P.VERIFICADO = VNGTIPOLEITURA
							 AND P.PREST = REG_RECEB.PREST
							 AND P.NUMRECEBIMENTO = REG_RECEB.NUMRECEBIMENTO;

					END IF;

				END IF;

				COMMIT;

			END IF;

		END LOOP;

	END PROC_VALIDA_RECEBIMENTO;

	PROCEDURE PROC_VALIDA_VINCULO_NFE(P_REGNOTA_CODUSUR IN NUMBER,
																		P_RESULT          OUT BOOLEAN,
																		P_MENSAGEM        OUT VARCHAR2) IS

		P_CODROTA_PCUSUARI  PCUSUARI.CODROTA%TYPE;
		P_NUMNOTA_PCROTAEXP PCROTAEXP.PROXNUMNFETV14%TYPE;
		P_SERIE_PCROTAEXP   PCROTAEXP.SERIENFETV14%TYPE;

	BEGIN

		SELECT CODROTA
			INTO P_CODROTA_PCUSUARI
			FROM PCUSUARI
		 WHERE CODUSUR = P_REGNOTA_CODUSUR;

		IF P_CODROTA_PCUSUARI IS NULL THEN

			P_MENSAGEM := 'Cadastro do RCA não foi vinculado à uma Rota !';
			P_RESULT   := FALSE;

		ELSE

			BEGIN

				SELECT PROXNUMNFETV14, SERIENFETV14
					INTO P_NUMNOTA_PCROTAEXP, P_SERIE_PCROTAEXP
					FROM PCROTAEXP
				 WHERE CODROTA = P_CODROTA_PCUSUARI;

				IF P_NUMNOTA_PCROTAEXP IS NULL AND P_SERIE_PCROTAEXP IS NULL THEN

					P_MENSAGEM := P_MENSAGEM ||
                        'Numeração de nota e série não definida na rota ' ||
                        CHR(13) || P_CODROTA_PCUSUARI || ', do RCA ' ||
                        P_REGNOTA_CODUSUR || '!';
					P_RESULT   := FALSE;

				ELSIF NVL(P_NUMNOTA_PCROTAEXP,0) = 0 THEN

					P_MENSAGEM := P_MENSAGEM ||
												'Numeração de nota não definida ou zerada na rota ' ||
                        CHR(13) || P_CODROTA_PCUSUARI || ', do RCA ' ||
                        P_REGNOTA_CODUSUR || '!';
					P_RESULT   := FALSE;

				ELSIF P_SERIE_PCROTAEXP IS NULL THEN

					P_MENSAGEM := P_MENSAGEM ||
												'Numero de série da nota não definida na rota ' ||
                        CHR(13) || P_CODROTA_PCUSUARI || ', do RCA ' ||
                        P_REGNOTA_CODUSUR || '!';
					P_RESULT   := FALSE;

				END IF;

			END;

		END IF;

		IF P_RESULT IS NULL THEN

			P_RESULT := TRUE;

		END IF;

	END PROC_VALIDA_VINCULO_NFE;

	PROCEDURE PROC_VALIDARNOTANFE(P_REGNOTA   IN OUT T_NOTA,
																P_REGFILIAL IN T_FILIAL) IS

		VICONTADOR NUMBER;
		VSMENSAGEM VARCHAR2(1000);
		VSRESULT   BOOLEAN;

	BEGIN

		VSMENSAGEM := NULL;

		IF P_REGNOTA.CONTINGENCIATV14 = 'S' THEN

			PROC_VALIDA_VINCULO_NFE(P_REGNOTA.CODUSUR, VSRESULT, VSMENSAGEM);

			IF VSRESULT = FALSE THEN

				P_REGNOTA.VALIDO := FALSE;

			END IF;

			IF P_REGFILIAL.PERMITEIMPORTARDANFECONTINGEN = 'N' THEN

				VSMENSAGEM       := VSMENSAGEM ||
														'Esta filial não permite importar em modo contingência.;';
				P_REGNOTA.VALIDO := FALSE;

			ELSE

				P_REGNOTA.CONSUMIUNUMNFE := 'S';

				--INICIO HIS.01145.2014

				IF NVL(P_REGFILIAL.CONTROLENFEPORSERIE, 'N') = 'N' AND
					 NVL(P_REGFILIAL.CONTROLENFEPORROTA, 'N') = 'N' THEN

					VSMENSAGEM       := VSMENSAGEM ||
															'Em modo contingência é obrigatório que os parâmetros de controle de NF por série da rotina 535 sejam marcados.';
					P_REGNOTA.VALIDO := FALSE;

				END IF;

				IF TRIM(P_REGFILIAL.ROTAUTILIZADAVENDATIPO14) = 'RP' THEN

					VSMENSAGEM       := VSMENSAGEM ||
															'Em modo contingência é obrigatório que o parâmetro 2964 da rotina 132 seja (RV).';
					P_REGNOTA.VALIDO := FALSE;

				END IF;

				-- FIM HIS.01145.2014
				IF TRIM(P_REGNOTA.NUMNOTAMANIF) IS NULL OR
					 P_REGNOTA.NUMNOTAMANIF = 0 THEN

					VSMENSAGEM       := VSMENSAGEM ||
															'Em modo contingência é obrigatório o envio do número da Nota Fiscal;';
					P_REGNOTA.VALIDO := FALSE;

				END IF;

				IF TRIM(P_REGNOTA.SERIEMANIF) IS NULL THEN

					VSMENSAGEM       := VSMENSAGEM ||
															'Em modo contingência é obrigatório o envio da série da Nota Fiscal;';
					P_REGNOTA.VALIDO := FALSE;

				END IF;

				IF TRIM(P_REGNOTA.TIPOEMISSAO) IS NULL THEN

					VSMENSAGEM       := VSMENSAGEM ||
															'Em modo contingência é obrigatório o envio do Tipo de Emissao;';
					P_REGNOTA.VALIDO := FALSE;

				END IF;

				IF TRIM(P_REGNOTA.CHAVENFE) IS NULL THEN

					VSMENSAGEM       := VSMENSAGEM ||
															'Em modo contingência é obrigatório o envio da Chave;';
					P_REGNOTA.VALIDO := FALSE;

				END IF;

				IF TRIM(P_REGNOTA.JUSTIFICATIVACONTIGENCIA) IS NULL THEN

					VSMENSAGEM       := VSMENSAGEM ||
															'Em modo contingência é obrigatório o envio da Justificativa;';
					P_REGNOTA.VALIDO := FALSE;

				END IF;

				IF TRIM(P_REGNOTA.DTAHORAENTRADACONTIGENCIA) IS NULL THEN

					VSMENSAGEM       := VSMENSAGEM ||
															'Em modo contingência é obrigatório o envio da Data de entrada da Contingencia;';
					P_REGNOTA.VALIDO := FALSE;

				END IF;

			END IF;

			IF P_REGFILIAL.MODEMISSAONFETV14 NOT IN ('NB', 'NC') THEN

				P_REGNOTA.VALIDO := FALSE;
				VSMENSAGEM       := VSMENSAGEM ||
														'Para importar em contigência o parametro MODEMISSAONFETV14 deve ser NB ou NC !';

			ELSE

				P_REGNOTA.ESPECIEMANIF := 'NF';

			END IF;

			IF P_REGNOTA.VALIDO = TRUE THEN

				P_REGNOTA.DATA := TRUNC(P_REGNOTA.DTAHORAENTRADACONTIGENCIA);

			END IF;

		ELSE

			P_REGNOTA.TIPOEMISSAO               := NULL;
			P_REGNOTA.CHAVENFE                  := NULL;
			P_REGNOTA.JUSTIFICATIVACONTIGENCIA  := NULL;
			P_REGNOTA.CONTINGENCIATV14          := NULL;
			P_REGNOTA.DTAHORAENTRADACONTIGENCIA := NULL;
			P_REGNOTA.CONSUMIUNUMNFE            := NULL;

			IF NVL(P_REGFILIAL.CONTROLENFEPORSERIE, 'N') = 'S' AND
				 NVL(P_REGFILIAL.CONTROLENFEPORROTA, 'N') = 'S' THEN

				PROC_VALIDA_VINCULO_NFE(P_REGNOTA.CODUSUR, VSRESULT, VSMENSAGEM);

				IF VSRESULT = FALSE THEN

          VSMENSAGEM       := VSMENSAGEM ||
                              'Com os parâmetros de controle de NF por série da rotina 535 marcados como "Sim", é obrigatório o vinculo.';
          P_REGNOTA.VALIDO := FALSE;


				END IF;


			END IF;

			IF P_REGFILIAL.MODEMISSAONFETV14 IN ('N', 'NC') THEN
				--N -> Nota Fiscal Eletronica, NC -> Nota Fiscal Scan

				IF P_REGNOTA.GERARNFE = 'S' THEN

					IF P_REGNOTA.NUMNOTAMANIF IS NOT NULL THEN

						P_REGNOTA.VALIDO := FALSE;

						VSMENSAGEM := VSMENSAGEM ||
													'Com campo GERARNFE = S, não é permitido enviar numero da nota !';

					ELSE
						P_REGNOTA.ESPECIEMANIF := 'NE';

					END IF;

				ELSE

					P_REGNOTA.VALIDO := FALSE;

					VSMENSAGEM := VSMENSAGEM ||
												'Com parametro MODEMISSAONFETV14 = N ou NC, é obrigatorio gravar campo GERARNFE = S !';

				END IF;

			ELSIF P_REGFILIAL.MODEMISSAONFETV14 = 'NB' THEN
				--Bloco e NFE

				IF P_REGNOTA.GERARNFE = 'S' THEN

					IF P_REGNOTA.NUMNOTAMANIF IS NOT NULL THEN

						P_REGNOTA.VALIDO := FALSE;

						VSMENSAGEM := VSMENSAGEM ||
													'Com campo GERARNFE = S, não é permitido enviar numero da nota !';

					ELSE
						P_REGNOTA.ESPECIEMANIF := 'NE';

					END IF;
				ELSE

					IF P_REGNOTA.NUMNOTAMANIF IS NULL THEN
						P_REGNOTA.VALIDO := FALSE;

						VSMENSAGEM := VSMENSAGEM ||
													'Com parametro MODEMISSAONFETV14 = NB e GERARNFE = N ou nulo, é obrigatório informar NUMNOTA e SERIE!';
					ELSE

						P_REGNOTA.ESPECIEMANIF := 'NF';
					END IF;

				END IF;

			ELSIF P_REGFILIAL.MODEMISSAONFETV14 = 'B' THEN
				--Bloco

				IF P_REGNOTA.GERARNFE = 'S' THEN

					P_REGNOTA.VALIDO := FALSE;
					VSMENSAGEM       := VSMENSAGEM ||
															'Com parametro MODEMISSAONFETV14 = B, não é permitido enviar o parametro GERARNFE = S !';

				ELSIF NVL(P_REGNOTA.GERARNFE, 'N') = 'N' AND
							P_REGNOTA.NUMNOTAMANIF IS NULL THEN

					P_REGNOTA.VALIDO := FALSE;
					VSMENSAGEM       := VSMENSAGEM ||
															'Com parametro MODEMISSAONFETV14 = B, é obrigatório informar NUMNOTA e SERIE !';

				ELSE
					P_REGNOTA.ESPECIEMANIF := 'NF';

				END IF;

			ELSE

				P_REGNOTA.VALIDO := FALSE;
				VSMENSAGEM       := VSMENSAGEM ||
														'Valor não reconhecido para parâmetro MODEMISSAOTV14 : ' ||
														P_REGFILIAL.MODEMISSAONFETV14;

			END IF;

		END IF;

		IF VSMENSAGEM IS NOT NULL THEN

			PROC_REGISTRALOG(P_REGNOTA.NUMPED,
											 P_REGNOTA.NUMPEDRCA,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 P_REGNOTA.CODUSUR,
											 NULL,
											 P_REGNOTA.CANCELADA,
											 '11',
											 VSMENSAGEM,
											 NULL);

		END IF;

		IF P_REGNOTA.VALIDO = TRUE AND P_REGNOTA.ESPECIEMANIF = 'NE' THEN

			IF P_REGNOTA.DATA < TRUNC(SYSDATE) THEN

				P_REGNOTA.VALIDO := FALSE;

				PROC_REGISTRALOG(P_REGNOTA.NUMPED,
												 P_REGNOTA.NUMPEDRCA,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 P_REGNOTA.CODUSUR,
												 NULL,
												 P_REGNOTA.CANCELADA,
												 '11',
												 'Não e permitido pela SEFAZ, emissão de NFe com data retroativa ;',
												 NULL);

			END IF;

		END IF;

	END PROC_VALIDARNOTANFE;

	PROCEDURE PROC_PCPARAMFILIAL(P_CODFILIAL IN PCFILIAL.CODIGO%TYPE,
															 P_NOME      IN PCPARAMFILIAL.NOME%TYPE,
															 P_PADRAO    IN PCPARAMFILIAL.VALOR%TYPE,
															 P_VALOR     OUT PCPARAMFILIAL.VALOR%TYPE) IS

		VSNOME PCPARAMFILIAL.NOME%TYPE;

	BEGIN

		VSNOME := UPPER(TRIM(P_NOME));

		BEGIN
			SELECT NVL(P.VALOR, P_PADRAO)
				INTO P_VALOR
				FROM PCPARAMFILIAL P
			 WHERE UPPER(TRIM(P.NOME)) = VSNOME
				 AND P.CODFILIAL = P_CODFILIAL;
		EXCEPTION

			WHEN NO_DATA_FOUND THEN

				BEGIN

					SELECT NVL(P.VALOR, P_PADRAO)
						INTO P_VALOR
						FROM PCPARAMFILIAL P
					 WHERE UPPER(TRIM(P.NOME)) = VSNOME
						 AND P.CODFILIAL = '99';
				EXCEPTION
					WHEN NO_DATA_FOUND THEN

						P_VALOR := P_PADRAO;

				END;

			WHEN OTHERS THEN
				P_VALOR := P_PADRAO;

		END;

	END PROC_PCPARAMFILIAL;

	PROCEDURE PROC_PARAMETROS(P_REGNOTA   IN T_NOTA,
														P_REGFILIAL IN OUT T_FILIAL) IS

	BEGIN

		SELECT CODIGO,
					 UF,
					 PERMITIRVENDAINTERESTADUALPF,
					 PERMITIRVENDAESTADUALPFCOMIE,
					 PERMITIRVENDAESTADUALPFSEMIE,
					 NVL(PCFILIAL.CALCESTDISPCOMQTMINAUTOSERV, 'N'),
					 NVL(PCFILIAL.USAINTEGRACAOWMS, 'N'),
					 ' ',
					 PCFILIAL.CALCULARIPIVENDA,
					 'N',
					 'N',
					 'N',
					 'N',
					 'P',
					 'N',
					 'N',
					 'N',
					 PCFILIAL.ORIGEMCUSTOFILIALRETIRA,
					 'N',
					 'N',
					 'N',
					 NVL(PCFILIAL.TIPOAVALIACAOCOMISSAO, 1),
					 PCFILIAL.CONSIDERARCOMISSAOZERO,
					 'N',
					 'RI',
					 'N',
					 'S',
					 'N',
					 'N',
					 'N',
					 0,
					 'N',
					 0,
					 'N',
					 'S',
					 'N',
					 0,
					 'N',
					 'N',
					 'S',
					 0,
					 'S',
					 0,
					 'B',
					 'N',
					 'N',
					 'N',
					 PCFILIAL.CONTROLENFEPORROTA,
					 PCFILIAL.CONTROLENFEPORSERIE,
					 'RP',
           'N',
           'N',
           0
			INTO P_REGFILIAL
			FROM PCFILIAL
		 WHERE CODIGO = P_REGNOTA.CODFILIAL;

		--tarefa 131429
		PROC_PCPARAMFILIAL(P_REGNOTA.CODFILIAL,
											 'FIL_UTILIZAVENDAPOREMBALAGEM',
											 'N',
											 P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM);

		PROC_PCPARAMFILIAL(P_REGNOTA.CODFILIAL,
											 'FIL_PRECOPOREMBALAGEM',
											 'N',
											 P_REGFILIAL.PRECOPOREMBALAGEM);

		PROC_PCPARAMFILIAL(P_REGNOTA.CODFILIAL,
											 'FIL_TIPOPRECIFICACAO',
											 'P',
											 P_REGFILIAL.TIPOPRECIFICACAO);

		--165829

		PROC_PCPARAMFILIAL(P_REGNOTA.CODFILIAL,
											 'MODEMISSAONFETV14',
											 'B',
											 P_REGFILIAL.MODEMISSAONFETV14);

		--185251

		PROC_PCPARAMFILIAL(P_REGNOTA.CODFILIAL,
											 'PERMITEIMPORTARDANFECONTINGEN',
											 'N',
											 P_REGFILIAL.PERMITEIMPORTARDANFECONTINGEN);

		PROC_PCPARAMFILIAL(P_REGNOTA.CODFILIAL,
											 'OBRIGATORIOVINCULARTV5COMTV1',
											 'N',
											 P_REGFILIAL.OBRIGATORIOVINCULARTV5COMTV1);

		PROC_PCPARAMFILIAL(P_REGNOTA.CODFILIAL,
											 'SEPARARPRODCOMST',
											 'N',
											 P_REGFILIAL.SEPARARPRODCOMST);

		PROC_PCPARAMFILIAL(P_REGNOTA.CODFILIAL,
											 'GERARBOLETOAUTOVENDAMANIF',
											 'N',
											 P_REGFILIAL.GERARBOLETOAUTOVENDAMANIF);

		--HIS.01145.2014
		PROC_PCPARAMFILIAL(P_REGNOTA.CODFILIAL,
											 'ROTAUTILIZADAVENDATIPO14',
											 'RP',
											 P_REGFILIAL.ROTAUTILIZADAVENDATIPO14);

   --HIS.02651.2015
    PROC_PCPARAMFILIAL(P_REGNOTA.CODFILIAL,
                       'VALIDARALVARAVENDA',
                       'N',
                       P_REGFILIAL.VALIDARALVARAVENDA);


    PROC_PCPARAMFILIAL(P_REGNOTA.CODFILIAL,
                       'PERMITEITEMBNFTV14',
                       'N',
                       P_REGFILIAL.PERMITEITEMBNFTV14);

    PROC_PCPARAMFILIAL(P_REGNOTA.CODFILIAL,
                       'VLBNFMAXTV14',
                       0,
                       P_REGFILIAL.VLBNFMAXTV14);

    PROC_PCPARAMFILIAL(P_REGNOTA.CODFILIAL,
                       'VLMAXVENDABONIFICMES',
                       '0',
                       P_REGFILIAL.VLMAXVENDABONIFICMES);

    PROC_PCPARAMFILIAL(P_REGNOTA.CODFILIAL,
                       'SOMACREDITOCLIPRINCIPAL',
                       'N',
                       P_REGFILIAL.SOMACREDITOCLIPRINCIPAL);

    PROC_PCPARAMFILIAL(P_REGNOTA.CODFILIAL,
                       'USABNFLIMITECREDITO',
                       'S',
                       P_REGFILIAL.USABNFLIMITECREDITO);


	END PROC_PARAMETROS;

	PROCEDURE PROC_VALIDARNOTA(P_REGNOTA    IN OUT T_NOTA,
														 P_REGCLIENTE OUT T_CLIENTEPEDIDO,
														 P_REGRCA     OUT T_RCA,
														 P_REGREGIAO  OUT T_REGIAOCLIENTE,
														 P_REGPLPAG   OUT T_PLANODEPAGAMENTO,
														 P_REGFILIAL  OUT T_FILIAL) IS
		VICONTADOR       NUMBER;
		VSMENSAGEM       VARCHAR2(32767);
		VSCHAR           VARCHAR2(1) DEFAULT '#';
		VNNIVELVENDACLI  PCCOB.NIVELVENDA%TYPE;
		VNPROXNUMPED     PCUSUARI.PROXNUMPED%TYPE;
		VSBOLETO         VARCHAR2(1);
		VNNUMNOTABLOCO1  PCUSUARI.NUMNOTABLOCO1%TYPE;
		VSCGCENT         VARCHAR2(30);
		VDDATATV13       DATE;
		VSNUMREGIAO      PCREGIAO.NUMREGIAO%TYPE;
		VSTIPOPRAZO      PCPLPAG.TIPOPRAZO%TYPE;
		VNCODROTA        PCROTAEXP.CODROTA%TYPE;
		VNPROXNUMNFETV14 PCROTAEXP.PROXNUMNFETV14%TYPE; --HIS.01145.2014
    VSPODECOMPRAR    VARCHAR2(1); --HIS.02651.2015
    VSMSGTEMP        VARCHAR2(4000);
    VNQTDTEMP        NUMBER(14,6);
    vnvlpedido       NUMBER;
    VNSALDODISPONIVEL NUMBER;
    vbexistepcplpagrestricao   BOOLEAN;
    vsmensagempcplpagrestricao VARCHAR2(1000);
    VNTOTALPEDIDO              NUMBER(18,6);
    VICONT_BNF_INVALIDO         NUMBER;
    VNPROXNUMNFESCANTV14 PCROTAEXP.PROXNUMNFESCANTV14%TYPE;
    VBPODEATUALIZARPROXNUMNFE_ROTA BOOLEAN;
    VN_MINPROXNUMNOTA              NUMBER;
    VN_MAXPROXNUMNOTA              NUMBER;
    VCCAMPONULO                    VARCHAR2(30);
    VNCOUNT_EXISTENFGERADA         NUMBER;
    VBPODEPROCESSARNFE_ROTA        BOOLEAN;

	BEGIN
		P_REGNOTA.VALIDO := TRUE;
		VSMENSAGEM       := NULL;
		VNPROXNUMPED     := 0;
    VBPODEATUALIZARPROXNUMNFE_ROTA := FALSE;
    VCCAMPONULO      := '';
    VNCOUNT_EXISTENFGERADA         := 0;
    VBPODEPROCESSARNFE_ROTA        := FALSE;

		SELECT COUNT(*)
			INTO VICONTADOR
			FROM PCFILIAL P
		 WHERE CODIGO = P_REGNOTA.CODFILIAL;

		IF VICONTADOR = 1 THEN

			PROC_PARAMETROS(P_REGNOTA, P_REGFILIAL);

		ELSE

			IF VSMENSAGEM IS NOT NULL THEN
				VSCHAR := '#';
			ELSE
				VSCHAR := NULL;
			END IF;

			VSMENSAGEM       := VSMENSAGEM || VSCHAR || 'Filial invalida.';
			P_REGNOTA.VALIDO := FALSE;

		END IF;

		-- valida se pedido TV13 existe
		SELECT COUNT(*)
			INTO VICONTADOR
			FROM PCPEDC P
		 WHERE/* P.CODUSUR = P_REGNOTA.CODUSUR
			 AND */P.NUMCAR = P_REGNOTA.NUMCARMANIF
			 AND P.CONDVENDA = 13;

		IF VICONTADOR = 0 THEN

			IF VSMENSAGEM IS NOT NULL THEN
				VSCHAR := '#';
			ELSE
				VSCHAR := NULL;
			END IF;

			VSMENSAGEM       := VSMENSAGEM || VSCHAR ||
													'NAO ENCONTRADO PEDIDO TV13 PARA O CARREGAMENTO : ' ||
													P_REGNOTA.NUMCARMANIF || ';';
			P_REGNOTA.VALIDO := FALSE;

		END IF;

		P_REGNOTA.PERCVENDA := 100;

		VSCGCENT := TRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(P_REGNOTA.CNPJ,
																																		 ' ',
																																		 ''),
																														 '.',
																														 ''),
																										 ',',
																										 ''),
																						 '-',
																						 ''),
																		 '/',
																		 ''),
														 '\',
														 ''));

		-- verifica se cliente esta cadastrado
		SELECT COUNT(*)
			INTO VICONTADOR
			FROM PCCLIENT, PCPRACA
		 WHERE PCCLIENT.CODPRACA = PCPRACA.CODPRACA
			 AND TRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CGCENT,
																																' ',
																																''),
																												'.',
																												''),
																								',',
																								''),
																				'-',
																				''),
																'/',
																''),
												'\',
												'')) = VSCGCENT
			 AND PCCLIENT.DTEXCLUSAO IS NULL;

		IF VICONTADOR = 0 THEN
			IF VSMENSAGEM IS NOT NULL THEN
				VSCHAR := '#';
			ELSE
				VSCHAR := NULL;
			END IF;

			VSMENSAGEM       := VSMENSAGEM || VSCHAR ||
													'CLIENTE NAO CADASTRADO OU EXCLUIDO;';
			P_REGNOTA.VALIDO := FALSE;

		ELSIF VICONTADOR = 1 THEN

			SELECT NVL(PCCLIENT.BLOQUEIO, 'N') BLOQUEIO,
						 NVL(PCCLIENT.CALCULAST, 'S'),
						 PCCLIENT.CLIENTE,
						 PCCLIENT.CODCLI,
						 PCCLIENT.CODCLIPRINC,
						 PCCLIENT.CODCOB,
						 PCCLIENT.CODFILIALNF,
						 PCCLIENT.CODPLPAG,
						 PCCLIENT.CODPRACA,
						 PCCLIENT.CONDVENDA1,
						 PCCLIENT.CONDVENDA2,
						 PCCLIENT.CONDVENDA3,
						 PCCLIENT.CONDVENDA4,
						 PCCLIENT.CONDVENDA5,
						 PCCLIENT.CONDVENDA6,
						 PCCLIENT.CONDVENDA10,
						 NVL(PCCLIENT.DESCPRODUTO, 'N') DESCPRODUTO,
						 PCCLIENT.ESTENT,
						 UPPER(PCCLIENT.IEENT) IEENT,
						 NVL(PCCLIENT.LIMCRED, 0) LIMCRED,
						 NVL(PCPLPAG.NUMDIAS, 0) NUMDIAS,
						 PCCLIENT.PERCOMCLI,
						 NVL(PCCLIENT.PERDESC, 0) PERDESC,
						 NVL(PCCLIENT.PRAZOADICIONAL, 0) PRAZOADICIONAL,
						 PCCLIENT.TIPOFJ,
						 PCPRACA.NUMREGIAO,
						 PCCLIENT.CODATV1,
						 PCCLIENT.VALIDAMAXVENDAPF,
						 PCCLIENT.CONSUMIDORFINAL,
						 NVL(PCCLIENT.CLIENTEFONTEST, 'N'),
						 NVL(PCCLIENT.ISENTOICMS, 'N'),
						 NVL(PCCLIENT.UTILIZAIESIMPLIFICADA, 'N'),
						 TIPOEMPRESA,
						 NVL(PCCLIENT.CONTRIBUINTE, 'S'),
						 PCCLIENT.CLASSEVENDA,
						 NVL(PCCLIENT.ISENTOIPI, 'N'),
						 PCCLIENT.SULFRAMA,
						 NVL(PCCLIENT.TIPODESCISENCAO, 'N'),
						 NVL(PERDESCISENTOICMS, 0),
						 NVL(PCCLIENT.USAIVAFONTEDIFERENCIADO, 'N'),
						 NVL(IVAFONTE, 0),
						 NVL(PCCLIENT.ORGAOPUB, 'N'),
						 NVL(PCCLIENT.ORGAOPUBFEDERAL, 'N'),
						 PCCLIENT.CEPENT,
						 PCCLIENT.MUNICENT,
						 PCCLIENT.ENDERENT,
						 PCCLIENT.CGCENT,
						 PCCLIENT.ORIGEMPRECO,
						 PCCLIENT.REPASSE,
						 PCCLIENT.DTVENCALVARA,
						 PCCLIENT.DTVENCALVARAFUNC,
						 PCCLIENT.DTVENCALVARAANVISA,
						 PCCLIENT.DTVENCCRF,
						 NVL(PCCLIENT.SIMPLESNACIONAL, 'N'),
						 PCCLIENT.VALIDARMULTIPLOVENDA,
						 PCCLIENT.CLIENTEMONITORADO,
						 PCCLIENT.CODREDE,
						 PCCLIENT.VALIDARCAMPANHABRINDE,
						 PCCLIENT.UTILIZAPLPAGMEDICAMENTO,
						 PCCLIENT.CODPLPAGETICO,
						 PCCLIENT.CODPLPAGGENERICO,
						 PCCLIENT.BLOQUEIOSEFAZ,
						 NVL(PCCLIENT.TIPOCUSTOTRANSF, 'R'),
						 NVL(PCCLIENT.PERACRESTRANSF, 0),
						 PCCLIENT.REGISTROIBAMA,
						 PCCLIENT.DTVALIDADEIBAMA,
						 NVL(PCCLIENT.ISENCAOSUFRAMA, 'T'),
						 TURNOENTREGA,
						 PCCLIENT.USADEBCREDRCA,
             NVL(PCCLIENT.FRETEDESPACHO, 'C') FRETEDESPACHO
				INTO P_REGCLIENTE
				FROM PCCLIENT, PCPRACA, PCPLPAG
			 WHERE PCCLIENT.CODPRACA = PCPRACA.CODPRACA
				 AND PCCLIENT.CODPLPAG = PCPLPAG.CODPLPAG(+)
				 AND TRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CGCENT,
																																	' ',
																																	''),
																													'.',
																													''),
																									',',
																									''),
																					'-',
																					''),
																	'/',
																	''),
													'\',
													'')) = VSCGCENT
				 AND PCCLIENT.DTEXCLUSAO IS NULL;

			P_REGNOTA.CODCLI := P_REGCLIENTE.CODCLI;

		ELSE

			IF P_REGNOTA.CODCLI IS NULL THEN

				IF VSMENSAGEM IS NOT NULL THEN
					VSCHAR := '#';
				ELSE
					VSCHAR := NULL;
				END IF;
				VSMENSAGEM       := VSMENSAGEM || VSCHAR ||
														'ENCONTRADO MAIS DE UM CLIENTE PARA ESTE CNPJ/CPF;';
				P_REGNOTA.VALIDO := FALSE;

			ELSE

				BEGIN
					SELECT NVL(PCCLIENT.BLOQUEIO, 'N') BLOQUEIO,
								 NVL(PCCLIENT.CALCULAST, 'S'),
								 PCCLIENT.CLIENTE,
								 PCCLIENT.CODCLI,
								 PCCLIENT.CODCLIPRINC,
								 PCCLIENT.CODCOB,
								 PCCLIENT.CODFILIALNF,
								 PCCLIENT.CODPLPAG,
								 PCCLIENT.CODPRACA,
								 PCCLIENT.CONDVENDA1,
								 PCCLIENT.CONDVENDA2,
								 PCCLIENT.CONDVENDA3,
								 PCCLIENT.CONDVENDA4,
								 PCCLIENT.CONDVENDA5,
								 PCCLIENT.CONDVENDA6,
								 PCCLIENT.CONDVENDA10,
								 NVL(PCCLIENT.DESCPRODUTO, 'N') DESCPRODUTO,
								 PCCLIENT.ESTENT,
								 UPPER(PCCLIENT.IEENT) IEENT,
								 NVL(PCCLIENT.LIMCRED, 0) LIMCRED,
								 NVL(PCPLPAG.NUMDIAS, 0) NUMDIAS,
								 PCCLIENT.PERCOMCLI,
								 NVL(PCCLIENT.PERDESC, 0) PERDESC,
								 NVL(PCCLIENT.PRAZOADICIONAL, 0) PRAZOADICIONAL,
								 PCCLIENT.TIPOFJ,
								 PCPRACA.NUMREGIAO,
								 PCCLIENT.CODATV1,
								 PCCLIENT.VALIDAMAXVENDAPF,
								 PCCLIENT.CONSUMIDORFINAL,
								 NVL(PCCLIENT.CLIENTEFONTEST, 'N'),
								 NVL(PCCLIENT.ISENTOICMS, 'N'),
								 NVL(PCCLIENT.UTILIZAIESIMPLIFICADA, 'N'),
								 TIPOEMPRESA,
								 NVL(PCCLIENT.CONTRIBUINTE, 'S'),
								 PCCLIENT.CLASSEVENDA,
								 NVL(PCCLIENT.ISENTOIPI, 'N'),
								 PCCLIENT.SULFRAMA,
								 NVL(PCCLIENT.TIPODESCISENCAO, 'N'),
								 NVL(PERDESCISENTOICMS, 0),
								 NVL(PCCLIENT.USAIVAFONTEDIFERENCIADO, 'N'),
								 NVL(IVAFONTE, 0),
								 NVL(PCCLIENT.ORGAOPUB, 'N'),
								 NVL(PCCLIENT.ORGAOPUBFEDERAL, 'N'),
								 PCCLIENT.CEPENT,
								 PCCLIENT.MUNICENT,
								 PCCLIENT.ENDERENT,
								 PCCLIENT.CGCENT,
								 PCCLIENT.ORIGEMPRECO,
								 PCCLIENT.REPASSE,
								 PCCLIENT.DTVENCALVARA,
								 PCCLIENT.DTVENCALVARAFUNC,
								 PCCLIENT.DTVENCALVARAANVISA,
								 PCCLIENT.DTVENCCRF,
								 NVL(PCCLIENT.SIMPLESNACIONAL, 'N'),
								 PCCLIENT.VALIDARMULTIPLOVENDA,
								 PCCLIENT.CLIENTEMONITORADO,
								 PCCLIENT.CODREDE,
								 PCCLIENT.VALIDARCAMPANHABRINDE,
								 PCCLIENT.UTILIZAPLPAGMEDICAMENTO,
								 PCCLIENT.CODPLPAGETICO,
								 PCCLIENT.CODPLPAGGENERICO,
								 PCCLIENT.BLOQUEIOSEFAZ,
								 NVL(PCCLIENT.TIPOCUSTOTRANSF, 'R'),
								 NVL(PCCLIENT.PERACRESTRANSF, 0),
								 PCCLIENT.REGISTROIBAMA,
								 PCCLIENT.DTVALIDADEIBAMA,
								 NVL(PCCLIENT.ISENCAOSUFRAMA, 'T'),
								 TURNOENTREGA,
								 PCCLIENT.USADEBCREDRCA,
                 NVL(PCCLIENT.FRETEDESPACHO, 'C') FRETEDESPACHO
						INTO P_REGCLIENTE
						FROM PCCLIENT, PCPRACA, PCPLPAG
					 WHERE PCCLIENT.CODPRACA = PCPRACA.CODPRACA
						 AND PCCLIENT.CODPLPAG = PCPLPAG.CODPLPAG(+)
						 AND TRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CGCENT,
																																			' ',
																																			''),
																															'.',
																															''),
																											',',
																											''),
																							'-',
																							''),
																			'/',
																			''),
															'\',
															'')) = VSCGCENT
						 AND PCCLIENT.CODCLI = P_REGNOTA.CODCLI
						 AND PCCLIENT.DTEXCLUSAO IS NULL;
				EXCEPTION
					WHEN OTHERS THEN

						IF VSMENSAGEM IS NOT NULL THEN
							VSCHAR := '#';
						ELSE
							VSCHAR := NULL;
						END IF;
						VSMENSAGEM       := VSMENSAGEM || VSCHAR ||
																'ERRO AO BUSCAR CLIENTE DO PEDIDO;';
						P_REGNOTA.VALIDO := FALSE;

				END;

			END IF;

		END IF;

    --HIS.02651.2015
    IF (P_REGNOTA.VALIDO) AND
       (p_REGFILIAL.VALIDARALVARAVENDA = 'S')
    THEN
      BEGIN
        PRC_MED_VALIDA_CONTROLE_VENDA('P',
                                      P_REGNOTA.CODCLI,
                                      P_REGCLIENTE.TIPOFJ,
                                      0,
                                      0,
                                      P_REGNOTA.NUMPED,
                                      0,
                                      VSPODECOMPRAR,
                                      VSMSGTEMP,
                                      VNQTDTEMP);

        IF VSPODECOMPRAR = 'N' THEN
          VSMENSAGEM  := VSMENSAGEM || VSCHAR || 'CLIENTE COM CONTROLE DE VENDA' ||
                         VSCHAR || VSMSGTEMP;
          P_REGNOTA.VALIDO := FALSE;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          VSMENSAGEM  := VSMENSAGEM || VSCHAR || 'ERRO AO VALIDAR CONTROLE DE VENDA!' ||
          SQLCODE || '-' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ';';
          P_REGNOTA.VALIDO := FALSE;
      END;
    END IF;
    -- FIM HIS.02651.2015

		--185252
		IF P_REGNOTA.CODCOB = 'BNF' THEN

			IF P_REGFILIAL.OBRIGATORIOVINCULARTV5COMTV1 = 'S' THEN

				IF TRIM(P_REGNOTA.NUMPEDTV14) IS NULL THEN

					IF VSMENSAGEM IS NOT NULL THEN
						VSCHAR := '#';
					ELSE
						VSCHAR := NULL;
					END IF;
					VSMENSAGEM       := VSMENSAGEM || VSCHAR ||
															'COM PARAMETRO OBRIGATORIOVINCULARTV5COMTV1 MARCADO É OBRIGATORIO O ENVIO DO NUMPEDTV14 PARA PEDIDO BONIFICADO;';
					P_REGNOTA.VALIDO := FALSE;

				ELSE

					SELECT COUNT(*)
						INTO VICONTADOR
						FROM PCPEDC
					 WHERE NUMPED = P_REGNOTA.NUMPEDTV14
						 AND CONDVENDA = 14
						 AND CODCLI = P_REGNOTA.CODCLI
						 AND CONTAORDEM IS NULL;

					IF VICONTADOR = 0 THEN

						IF VSMENSAGEM IS NOT NULL THEN
							VSCHAR := '#';
						ELSE
							VSCHAR := NULL;
						END IF;
						VSMENSAGEM       := VSMENSAGEM || VSCHAR ||
																'COM PARAMETRO OBRIGATORIOVINCULARTV5COMTV1 MARCADO É OBRIGATORIO O ENVIO DO NUMPEDTV14 VALIDO;';
						P_REGNOTA.VALIDO := FALSE;

					END IF;

				END IF;

			END IF;

		END IF;

		-- 173634
		IF P_REGNOTA.TURNOENTREGA IS NULL THEN
			P_REGNOTA.TURNOENTREGA := P_REGCLIENTE.TURNOENTREGA;

		ELSE
			IF P_REGNOTA.TURNOENTREGA NOT IN ('MT', 'MN', 'TN', 'M', 'N', 'T') THEN

				IF VSMENSAGEM IS NOT NULL THEN
					VSCHAR := '#';
				ELSE
					VSCHAR := NULL;
				END IF;

				VSMENSAGEM := VSMENSAGEM || VSCHAR ||
											'TURNO DE ENTREGA INVALIDO. SERA GRAVADO O TURNO CADASTRADO PARA O CLIENTE;';

				P_REGNOTA.TURNOENTREGA := P_REGCLIENTE.TURNOENTREGA;

			END IF;

		END IF;

		BEGIN
			SELECT NUMREGIAO
				INTO VSNUMREGIAO
				FROM PCTABPRCLI
			 WHERE CODCLI = P_REGNOTA.CODCLI
				 AND CODFILIALNF = P_REGNOTA.CODFILIALNF;
		EXCEPTION
			WHEN OTHERS THEN
				VSNUMREGIAO := NULL;

		END;

		-- 06 Verifica se cliente tem acesso a várias tabelas de preço
		IF VSNUMREGIAO IS NOT NULL THEN
			P_REGCLIENTE.NUMREGIAO := VSNUMREGIAO;
		END IF;

		--03. Verificar se o Representante esta cadastrado
		SELECT COUNT(*)
			INTO VICONTADOR
			FROM PCUSUARI
		 WHERE CODUSUR = P_REGNOTA.CODUSUR;

		IF VICONTADOR = 0 THEN
			IF VSMENSAGEM IS NOT NULL THEN
				VSCHAR := '#';
			ELSE
				VSCHAR := NULL;
			END IF;

			VSMENSAGEM       := VSMENSAGEM || VSCHAR || 'Rca nao Cadastrado.';
			P_REGNOTA.VALIDO := FALSE;

		ELSE
			SELECT NVL(PCUSUARI.BLOQUEIO, 'N') BLOQUEIO,
						 PCUSUARI.CODDISTRIB,
						 PCUSUARI.CODSUPERVISOR,
						 PCUSUARI.CODUSUR,
						 PCUSUARI.NOME,
						 PCUSUARI.PERCENT2,
						 PCUSUARI.PERCENT,
						 PCUSUARI.PROXNUMPED,
						 NVL(PCUSUARI.TIPOVEND, 'R') TIPOVEND,
						 PERMAXVENDA,
						 USADEBCREDRCA,
						 NVL(PCUSUARI.VLVENDAMINPED, 0),
						 PCUSUARI.PERCACRESFV,
						 PCUSUARI.CODROTA
				INTO P_REGRCA
				FROM PCUSUARI, PCSUPERV
			 WHERE PCUSUARI.CODUSUR = P_REGNOTA.CODUSUR
				 AND PCUSUARI.CODSUPERVISOR = PCSUPERV.CODSUPERVISOR;

		END IF;

		--tarefa 207010
		IF NVL(P_REGRCA.USADEBCREDRCA, 'S') = 'N' OR
			 NVL(P_REGCLIENTE.USADEBCREDRCA, 'S') = 'N' THEN

			P_REGNOTA.USADEBCREDRCA := 'N';

		END IF;

		SELECT COUNT(*)
			INTO VICONTADOR
			FROM PCPEDIFVMANIF
		 WHERE NUMPEDRCA = P_REGNOTA.NUMPEDRCA
       AND CODUSUR   = P_REGNOTA.CODUSUR
			 AND NVL(CANCELADO, 'N') = P_REGNOTA.CANCELADA
			 AND QT > 0;

		IF VICONTADOR > 0 THEN

			PROC_VALIDARNOTANFE(P_REGNOTA, P_REGFILIAL);

		END IF;

		IF P_REGNOTA.VALIDO = TRUE THEN

			IF NVL(P_REGNOTA.CONTINGENCIATV14, 'N') = 'S' THEN

				IF NVL(P_REGRCA.CODROTA, 0) > 0 THEN
					-- INICIO HIS.01145.2014
					BEGIN
						SELECT CODROTA, PROXNUMNFETV14, PROXNUMNFESCANTV14
							INTO VNCODROTA, VNPROXNUMNFETV14, VNPROXNUMNFESCANTV14
							FROM PCROTAEXP P
						 WHERE P.CODROTA = P_REGRCA.CODROTA
							 FOR UPDATE;

					EXCEPTION
						WHEN OTHERS THEN
							VNCODROTA := NULL;
					END;

          /*
           Caso o número da NF enviada pelo Força de Vendas em modo Contingência(P_REGNOTA.NUMNOTAMANIF),
           utilizado pela rotina 520(Por Rota) seja menor que o menor próximo número da sequência
           (VNPROXNUMNFETV14 ou VNPROXNUMNFESCANTV14), o pedido será rejeitado para que o responsável possa
           ajustar a sequência correta de acordo com o último número de nota gerada para este RCA, que pode ser
           consultada na tabela PCNFSAID. VNPROXNUMNFETV14 e VNPROXNUMNFESCANTV14 podem estar divergentes no
           controle do cliente, cabendo a ele ajustar estes dados na rotina 520 para um valor acima do último
           número de nota gerada para este RCA, Série, Condvenda e Filial e correto na sequência, a ponto de
           evitar rejeições por Duplicidade de NF-e.

           Regras:
           1) O menor valor dos números de nota(Scan e NF-e) deve ser maior que zero,
           2) O número da NF após atualizado deve ser maior que o maior dos dois números de nota,
           3) O número da NF precisa ser maior ou igual ao menor próximo número de nota,
           E...
           4) ProxNumNFe normal precisa ser menor ou igual ao número da NF
           ou
           5) ProxNumNFeScan precisa ser menor ou igual ao número da NF.

          */

          VN_MINPROXNUMNOTA := LEAST(VNPROXNUMNFETV14, VNPROXNUMNFESCANTV14);
          VN_MAXPROXNUMNOTA := GREATEST(VNPROXNUMNFETV14,
                                        VNPROXNUMNFESCANTV14);

          IF NVL(VN_MINPROXNUMNOTA, 0) = 0 THEN
            VCCAMPONULO := CASE
                             WHEN NVL(VNPROXNUMNFESCANTV14, 0) = 0 THEN
                              'Prox. Numero de NFe Scan'
                             WHEN NVL(VNPROXNUMNFETV14, 0) = 0 THEN
                              'Prox. Numero de NFe'
                             ELSE
                              'Prox. Numero de NFe e NFe Scan'
                           END;
          END IF;

          VBPODEATUALIZARPROXNUMNFE_ROTA := (VN_MINPROXNUMNOTA > 0 AND
                                            ((P_REGNOTA.NUMNOTAMANIF + 1) > VN_MAXPROXNUMNOTA) AND
                                            (P_REGNOTA.NUMNOTAMANIF >= VN_MINPROXNUMNOTA) AND
                                            ((VNPROXNUMNFETV14 < P_REGNOTA.NUMNOTAMANIF OR
                                            VNPROXNUMNFETV14 = P_REGNOTA.NUMNOTAMANIF)
                                            OR
                                            (VNPROXNUMNFESCANTV14 < P_REGNOTA.NUMNOTAMANIF) OR
                                            (VNPROXNUMNFESCANTV14 = P_REGNOTA.NUMNOTAMANIF)));

					IF VNCODROTA IS NOT NULL AND VBPODEATUALIZARPROXNUMNFE_ROTA THEN

            UPDATE PCROTAEXP P
               SET PROXNUMNFETV14     = P_REGNOTA.NUMNOTAMANIF + 1,
                   PROXNUMNFESCANTV14 = P_REGNOTA.NUMNOTAMANIF + 1
             WHERE P.CODROTA = P_REGRCA.CODROTA;

          ELSIF (NOT VBPODEATUALIZARPROXNUMNFE_ROTA) AND
                (P_REGNOTA.NUMNOTAMANIF < VNPROXNUMNFESCANTV14) AND
                (P_REGNOTA.NUMNOTAMANIF BETWEEN
                GREATEST((VNPROXNUMNFESCANTV14 - 100), 0) AND
                (VNPROXNUMNFESCANTV14 + 100)) THEN

            BEGIN
              SELECT SUM(A.CONTADOR)
                INTO VNCOUNT_EXISTENFGERADA
                FROM (SELECT COUNT(*) CONTADOR
                        FROM PCPEDC
                       WHERE CODUSUR = P_REGNOTA.CODUSUR
                         AND NUMNOTAMANIF = P_REGNOTA.NUMNOTAMANIF
                         AND SERIEMANIF = P_REGNOTA.SERIEMANIF
                         AND POSICAO <> 'C'
                         AND CHAVENFE IS NOT NULL
                      UNION
                      SELECT COUNT(*) CONTADOR
                        FROM PCNFSAIDPREFAT
                       WHERE CODUSUR = P_REGNOTA.CODUSUR
                         AND NUMNOTA = P_REGNOTA.NUMNOTAMANIF
                         AND SERIE = P_REGNOTA.SERIEMANIF
                         AND DTCANCEL IS NULL
                         AND CHAVENFE IS NOT NULL
                      UNION
                      SELECT COUNT(*) CONTADOR
                        FROM PCNFSAID
                       WHERE CODUSUR = P_REGNOTA.CODUSUR
                         AND NUMNOTA = P_REGNOTA.NUMNOTAMANIF
                         AND SERIE = P_REGNOTA.SERIEMANIF
                         AND DTCANCEL IS NULL
                         AND CHAVENFE IS NOT NULL) A;
            EXCEPTION
              WHEN OTHERS THEN
                VNCOUNT_EXISTENFGERADA := 0;
            END;

            VBPODEPROCESSARNFE_ROTA := VNCOUNT_EXISTENFGERADA <= 0;

            IF VBPODEPROCESSARNFE_ROTA THEN
              NULL;
            ELSE
              IF VSMENSAGEM IS NOT NULL THEN

                VSCHAR := '#';

              ELSE

                VSCHAR := NULL;

              END IF;

              IF VCCAMPONULO IS NOT NULL THEN
                VSMENSAGEM := VSMENSAGEM || VSCHAR ||
                              'Nao foi possivel atualizar o PRONUMNFETV14/PROXNUMNFESCANTV14(Número da nota já utilizada no intervalo). ' ||
                              CHR(13) || 'CodUsur: ' || P_REGNOTA.CODUSUR ||
                              ' / Rota: ' || P_REGRCA.CODROTA || CHR(13) ||
                              'PROXNUMNFETV14: ' ||
                              nvl(VNPROXNUMNFETV14, 0) || CHR(13) ||
                              'PROXNUMNFESCANTV14: ' ||
                              nvl(VNPROXNUMNFESCANTV14, 0) || CHR(13) ||
                              'Num.Nota Manif.: ' || P_REGNOTA.NUMNOTAMANIF ||
                              CHR(13) ||
                              'Favor ajustar na rotina 520 o campo ' ||
                              VCCAMPONULO || ', que está nulo ou zerado.';
              ELSE
                VSMENSAGEM := VSMENSAGEM || VSCHAR ||
                              'Nao foi possivel atualizar o PRONUMNFETV14/PROXNUMNFESCANTV14(Número da nota já utilizada no intervalo). ' ||
                              CHR(13) || 'CodUsur: ' || P_REGNOTA.CODUSUR ||
                              ' / Rota: ' || P_REGRCA.CODROTA || CHR(13) ||
                              'PROXNUMNFETV14: ' ||
                              nvl(VNPROXNUMNFETV14, 0) || CHR(13) ||
                              'PROXNUMNFESCANTV14: ' ||
                              nvl(VNPROXNUMNFESCANTV14, 0) || CHR(13) ||
                              'Num.Nota Manif.: ' || P_REGNOTA.NUMNOTAMANIF ||
                              CHR(13);
              END IF;

              P_REGNOTA.VALIDO := FALSE;

            END IF;

          ELSE
            IF VSMENSAGEM IS NOT NULL THEN

              VSCHAR := '#';

            ELSE

              VSCHAR := NULL;

            END IF;

            IF VCCAMPONULO IS NOT NULL THEN
              VSMENSAGEM := VSMENSAGEM || VSCHAR ||
                            'Nao foi possivel atualizar o PRONUMNFETV14/PROXNUMNFESCANTV14. ' ||
                            CHR(13) || 'CodUsur: ' || P_REGNOTA.CODUSUR ||
                            ' / Rota: ' || P_REGRCA.CODROTA || CHR(13) ||
                            'PROXNUMNFETV14: ' || nvl(VNPROXNUMNFETV14, 0) ||
                            CHR(13) || 'PROXNUMNFESCANTV14: ' ||
                            nvl(VNPROXNUMNFESCANTV14, 0) || CHR(13) ||
                            'Num.Nota Manif.: ' || P_REGNOTA.NUMNOTAMANIF ||
                            CHR(13) ||
                            'Favor ajustar na rotina 520 o campo ' ||
                            VCCAMPONULO || ', que está nulo ou zerado.';
            ELSE
              VSMENSAGEM := VSMENSAGEM || VSCHAR ||
                            'Nao foi possivel atualizar o PRONUMNFETV14/PROXNUMNFESCANTV14. ' ||
                            CHR(13) || 'CodUsur: ' || P_REGNOTA.CODUSUR ||
                            ' / Rota: ' || P_REGRCA.CODROTA || CHR(13) ||
                            'PROXNUMNFETV14: ' || nvl(VNPROXNUMNFETV14, 0) ||
                            CHR(13) || 'PROXNUMNFESCANTV14: ' ||
                            nvl(VNPROXNUMNFESCANTV14, 0) || CHR(13) ||
                            'Num.Nota Manif.: ' || P_REGNOTA.NUMNOTAMANIF ||
                            CHR(13);
            END IF;

            P_REGNOTA.VALIDO := FALSE;

          END IF;

        END IF;

      END IF;

			IF NVL(P_REGNOTA.GERARNFE, 'N') = 'N' THEN

				-- verifica se pedido ja existe (1)
        select count(*) -- verifica se pedido ja existe (1)
        into vicontador
        from pcpedc
        where numpedrca = p_regnota.numpedrca
          and nvl(numnotamanif, -1) = nvl(p_regnota.numnotamanif, -2)
          and nvl(seriemanif, -1) = nvl(p_regnota.seriemanif,-2)
          and dtcancel is null;
        -- and codusur = p_regnota.codusur; --1198.071641.2014

				IF VICONTADOR > 0 THEN

					IF VSMENSAGEM IS NOT NULL THEN

						VSCHAR := '#';

					ELSE

						VSCHAR := NULL;

					END IF;

					VSMENSAGEM       := VSMENSAGEM || VSCHAR || 'Pedido: ' ||
															P_REGNOTA.NUMPEDRCA || ' ou Nota Fiscal: ' ||
															P_REGNOTA.NUMNOTAMANIF || '-' ||
															P_REGNOTA.SERIEMANIF ||
															' ja existente para o RCA: ' ||
															P_REGNOTA.CODUSUR;
					P_REGNOTA.VALIDO := FALSE;

				END IF;

			ELSE
				-- verifica se pedido ja existe (2)
        select count(*) -- verifica se pedido ja existe (2)
        into vicontador
        from pcpedc
        where numpedrca = p_regnota.numpedrca
          and nvl(numnotamanif, -1) = nvl(p_regnota.numnotamanif, -2)
          and nvl(seriemanif, -1) = nvl(p_regnota.seriemanif,-2)
          and dtcancel is null;
        -- and codusur = p_regnota.codusur; --1198.071641.2014

				--
				IF VICONTADOR > 0 THEN

					IF VSMENSAGEM IS NOT NULL THEN

						VSCHAR := '#';

					ELSE

						VSCHAR := NULL;

					END IF;

					VSMENSAGEM       := VSMENSAGEM || VSCHAR || 'Pedido: ' ||
															P_REGNOTA.NUMPEDRCA ||
															' ja existente para o RCA: ' ||
															P_REGNOTA.CODUSUR;
					P_REGNOTA.VALIDO := FALSE;

				END IF;
				--
			END IF;

			IF NVL(P_REGNOTA.CONTINGENCIATV14, 'N') = 'S' THEN

				-- verifica se pedido ja existe (3)
				SELECT COUNT(*)
					INTO VICONTADOR
					FROM PCPEDC
				 WHERE CODUSUR = P_REGNOTA.CODUSUR
					 and nvl(numnotamanif, -1) = nvl(p_regnota.numnotamanif, -2)
           and nvl(seriemanif, -1) = nvl(p_regnota.seriemanif,-2)
           and dtcancel is null
           and chavenfe is not null;

				IF VICONTADOR > 0 THEN

					IF VSMENSAGEM IS NOT NULL THEN

						VSCHAR := '#';

					ELSE

						VSCHAR := NULL;

					END IF;

					VSMENSAGEM       := VSMENSAGEM || VSCHAR || 'Nota Fiscal: ' ||
															P_REGNOTA.NUMNOTAMANIF || '-' ||
															P_REGNOTA.SERIEMANIF ||
															' ja existente para o RCA: ' ||
															P_REGNOTA.CODUSUR;
					P_REGNOTA.VALIDO := FALSE;

				END IF;

			END IF;

		END IF;
		-- FIM HIS.01145.2014

		P_REGNOTA.CODFORNECFRETE := NULL;

		-- verifica codigo do fornecedor de frete do pedido TV13
		BEGIN
			SELECT PCPEDC.CODFORNECFRETE, PCPEDC.NUMTRANSVENDA, PCPEDC.FRETEDESPACHO
				INTO P_REGNOTA.CODFORNECFRETE, P_REGNOTA.NUMTRANSVENDATV13, P_REGNOTA.FRETEDESPACHO
				FROM PCPEDC
			 WHERE CODUSUR = P_REGNOTA.CODUSUR
				 AND NUMCAR = P_REGNOTA.NUMCARMANIF
				 AND CONDVENDA = 13
				 AND ROWNUM = 1;
		EXCEPTION
			WHEN OTHERS THEN

				P_REGNOTA.CODFORNECFRETE    := NULL;
				P_REGNOTA.NUMTRANSVENDATV13 := NULL;
        P_REGNOTA.FRETEDESPACHO     := NULL;
		END;

    IF NVL(P_REGNOTA.FRETEDESPACHO, 'N') = 'N'
      THEN
        P_REGNOTA.FRETEDESPACHO := P_REGCLIENTE.FRETEDESPACHO;
    END IF;

		--Numeracao do Pedido
		IF P_REGNOTA.VALIDO = TRUE THEN

      VNPROXNUMPED    := PROXNUM('pcusuari', 'PROXNUMPEDFORCA', 'CODUSUR', P_REGNOTA.CODUSUR); -- Não usamos o PROXNUMPEDFORCA, mas precisamos incrementar.
      VNPROXNUMPED    := PROXNUM('pcusuari', 'PROXNUMPED', 'CODUSUR', P_REGNOTA.CODUSUR);
      VNNUMNOTABLOCO1 := PROXNUM('pcusuari', 'NUMNOTABLOCO1', 'CODUSUR', P_REGNOTA.CODUSUR);

      P_REGNOTA.NUMPED := VNPROXNUMPED;

      if vnproxnumped = 0 then
        VSMENSAGEM       := 'Erro ao buscar o número do pedido';
					P_REGNOTA.VALIDO := FALSE;
      end if;

		END IF;

		-- verifica se pedido ja existe (2)
		SELECT COUNT(*)
			INTO VICONTADOR
			FROM PCPEDC
		 WHERE NUMPED = P_REGNOTA.NUMPED
       AND POSICAO <> 'C';

		IF VICONTADOR > 0 THEN
			IF VSMENSAGEM IS NOT NULL THEN
				VSCHAR := '#';
			ELSE
				VSCHAR := NULL;
			END IF;

			VSMENSAGEM       := VSMENSAGEM || VSCHAR ||
													'Número de pedido:' || P_REGNOTA.NUMPED || ' já utilizado, verificar sequencial do pedido na 517;';

			P_REGNOTA.VALIDO := FALSE;
		END IF;

		-- HIS.01574.2014
		-- Verifica se o nro do formulario e selo ja foi utilizado.
		SELECT COUNT(*)
			INTO VICONTADOR
			FROM PCPEDC
		 WHERE CODUSUR = P_REGNOTA.CODUSUR
			 AND NUMFORMULARIO = P_REGNOTA.NUMFORMULARIO
			 AND NUMSELO = P_REGNOTA.NUMSELO;

		IF VICONTADOR > 0 THEN

			IF VSMENSAGEM IS NOT NULL THEN

				VSCHAR := '#';

			ELSE

				VSCHAR := NULL;

			END IF;

			VSMENSAGEM       := VSMENSAGEM || VSCHAR || 'Formulario - Selo: ' ||
													P_REGNOTA.NUMFORMULARIO || '-' ||
													P_REGNOTA.NUMSELO || ' ja existente para o RCA: ' ||
													P_REGNOTA.CODUSUR;
			P_REGNOTA.VALIDO := FALSE;

		END IF;
		--
		-- Verifica se o nro do formulario e selo esta dentro do range permitido
		SELECT COUNT(*)
			INTO VICONTADOR
			FROM PCUSUARI
		 WHERE CODUSUR = P_REGNOTA.CODUSUR
			 AND (PCUSUARI.NUMFORMINICIAL >= P_REGNOTA.NUMFORMULARIO OR
					 PCUSUARI.NUMFORMFINAL <= P_REGNOTA.NUMFORMULARIO)
			 AND (PCUSUARI.NUMSELOINICIAL >= P_REGNOTA.NUMSELO OR
					 PCUSUARI.NUMSELOFINAL <= P_REGNOTA.NUMSELO);

		IF VICONTADOR > 0 THEN

			IF VSMENSAGEM IS NOT NULL THEN

				VSCHAR := '#';

			ELSE

				VSCHAR := NULL;

			END IF;

			VSMENSAGEM       := VSMENSAGEM || VSCHAR || 'Formulario - Selo: ' ||
													P_REGNOTA.NUMFORMULARIO || '-' ||
													P_REGNOTA.NUMSELO ||
													' fora do range  (inicial/final) permitido para o RCA: ' ||
													P_REGNOTA.CODUSUR;
			P_REGNOTA.VALIDO := FALSE;

		END IF;
		--
		-- Verifica se o nro do formulario e selo esta dentro do range permitido
		SELECT COUNT(*)
			INTO VICONTADOR
			FROM PCCARREG
		 WHERE NUMCAR = P_REGNOTA.NUMCARMANIF
			 AND NUMCARMANIFCONCLUIDOFV = 'S';

		IF VICONTADOR > 0 THEN

			IF VSMENSAGEM IS NOT NULL THEN

				VSCHAR := '#';

			ELSE

				VSCHAR := NULL;

			END IF;

			VSMENSAGEM       := VSMENSAGEM || VSCHAR || 'Carregamento: ' ||
													P_REGNOTA.NUMCAR || '-' ||
													' ainda não foi concluído pelo RCA.';
			P_REGNOTA.VALIDO := FALSE;

		END IF;
		-- fim HIS.01574.2014

		-- verificar se a regiao do cliente esta cadastrada
		SELECT COUNT(*)
			INTO VICONTADOR
			FROM PCREGIAO
		 WHERE PCREGIAO.NUMREGIAO = P_REGCLIENTE.NUMREGIAO
			 AND PCREGIAO.STATUS = 'A';

		IF VICONTADOR = 0 THEN
			IF VSMENSAGEM IS NOT NULL THEN
				VSCHAR := '#';
			ELSE
				VSCHAR := NULL;
			END IF;

			VSMENSAGEM       := VSMENSAGEM || VSCHAR || 'Regiao ' ||
													P_REGCLIENTE.NUMREGIAO || ' nao cadastrada;';
			P_REGNOTA.VALIDO := FALSE;
		ELSE
			SELECT PCREGIAO.NUMREGIAO,
						 PCREGIAO.PERFRETE,
						 NVL(PCREGIAO.PERFRETEESPECIAL, 0),
						 NVL(PCREGIAO.PERFRETETERCEIROS, 0),
						 NVL(PCREGIAO.REGIAOZFM, 'N')
				INTO P_REGREGIAO
				FROM PCREGIAO
			 WHERE PCREGIAO.NUMREGIAO = P_REGCLIENTE.NUMREGIAO
				 AND PCREGIAO.STATUS = 'A';
		END IF;

		IF P_REGNOTA.VALIDO = TRUE THEN
			-- plano de pagamento do pedido
			SELECT COUNT(*)
				INTO VICONTADOR
				FROM PCPLPAG
			 WHERE CODPLPAG = P_REGNOTA.CODPLPAG;

			IF VICONTADOR = 0 THEN
				IF VSMENSAGEM IS NOT NULL THEN
					VSCHAR := '#';
				ELSE
					VSCHAR := NULL;
				END IF;

				VSMENSAGEM       := VSMENSAGEM || VSCHAR || 'Plano de Pagamento ' ||
														P_REGNOTA.CODPLPAG || ' nao cadastrado;';
				P_REGNOTA.VALIDO := FALSE;
			ELSE
				SELECT CODPLPAG,
							 NUMDIAS,
							 NVL(NUMITENSMINIMO, 0),
							 NVL(NUMPR, 1) NUMPR,
							 OBS,
							 NVL(PERTXFIM, 0),
							 PRAZO1,
							 PRAZO2,
							 PRAZO3,
							 PRAZO4,
							 PRAZO5,
							 PRAZO6,
							 PRAZO7,
							 PRAZO8,
							 PRAZO9,
							 PRAZO10,
							 PRAZO11,
							 PRAZO12,
							 NVL(TIPOPRAZO, 'N'),
							 TIPOVENDA,
							 NVL(VLMINPEDIDO, 0),
							 NVL(PCPLPAG.VENDABK, 'N'),
							 NVL(TIPORESTRICAO, 'NR'),
							 CODRESTRICAO,
							 TRIM(CODFILIAL),
							 PCPLPAG.FORMAPARCELAMENTO,
							 NVL(PCPLPAG.USAMULTIFILIAL, 'N'),
							 NVL(PCPLPAG.DIASMINPARCELA, 0),
							 NVL(PCPLPAG.DIASMAXPARCELA, 0),
							 NVL(PCPLPAG.VLMINPARCELA, 0),
							 PCPLPAG.NUMPARCELAS
					INTO P_REGPLPAG
					FROM PCPLPAG
				 WHERE CODPLPAG = P_REGNOTA.CODPLPAG;
			END IF;

		END IF;

    -- verifica o plano de pagamento
    vbexistepcplpagrestricao := funcoesvendas.validarPCPLPAGRESTRICAO(P_REGNOTA.CODPLPAG,
                                                                      NULL,
                                                                      P_REGNOTA.codcli,
                                                                      P_REGCLIENTE.CODATV1,
                                                                      NULL,
                                                                      NULL,
                                                                      P_REGNOTA.ORIGEMPED,
                                                                      NULL,
                                                                      P_REGNOTA.CODFILIAL,
                                                                      P_REGREGIAO.NUMREGIAO,
                                                                      P_REGNOTA.CONDVENDA,
                                                                      vsmensagempcplpagrestricao,
                                                                      NULL,
                                                                      NULL);

    IF vbexistepcplpagrestricao = TRUE THEN
      IF VSMENSAGEM IS NOT NULL THEN
				VSCHAR := '#';
			ELSE
				VSCHAR := NULL;
			END IF;

			VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Plano de Pagamento com restricao ' || VSCHAR ||
        vsmensagempcplpagrestricao ||';';

			P_REGNOTA.VALIDO := FALSE;
    END IF;

		-- verificar tipo de cobranca do pedido
		SELECT COUNT(*)
			INTO VICONTADOR
			FROM PCCOB
		 WHERE UPPER(TRIM(CODCOB)) = P_REGNOTA.CODCOB;

		IF VICONTADOR = 0 THEN
			IF VSMENSAGEM IS NOT NULL THEN
				VSCHAR := '#';
			ELSE
				VSCHAR := NULL;
			END IF;

			VSMENSAGEM := VSMENSAGEM || VSCHAR || 'Cobranca ' || P_REGNOTA.CODCOB ||
										' nao cadastrada;';

			P_REGNOTA.VALIDO := FALSE;

		END IF;

		P_REGNOTA.USACREDRCA := GREGPCCONSUM.USACREDRCA;

		P_REGNOTA.BONIFICALTDEBCREDRCA := GREGPCCONSUM.BONIFICALTDEBCREDRCA;
		P_REGNOTA.TROCAALTDEBCREDRCA   := GREGPCCONSUM.TROCAALTDEBCREDRCA;
		P_REGNOTA.CRMALTDEBCREDRCA     := GREGPCCONSUM.CRMALTDEBCREDRCA;
		P_REGNOTA.BROKERALTDEBCREDRCA  := GREGPCCONSUM.BROKERALTDEBCREDRCA;
		P_REGNOTA.TIPOMOVCCRCA         := GREGPCCONSUM.TIPOMOVCCRCA;

    --VEN-817
    SELECT COUNT(*) QT, SUM(PCPEDIFVMANIF.QT * PCPEDIFVMANIF.PVENDA) PVENDA
      INTO VICONTADOR, VNTOTALPEDIDO
      FROM PCPEDIFVMANIF
     WHERE NUMPEDRCA = P_REGNOTA.NUMPEDRCA
       AND CODUSUR   = P_REGNOTA.CODUSUR
       AND NVL(BONIFIC, 'N') = 'F';

    IF (vicontador > 0) AND (P_REGFILIAL.PERMITEITEMBNFTV14 = 'N') THEN
      IF VSMENSAGEM IS NOT NULL THEN
        VSCHAR := '#';
      ELSE
        VSCHAR := NULL;
      END IF;

      VSMENSAGEM := VSMENSAGEM || VSCHAR ||
        'PEDIDO COM ITENS BONIFICADOS, E SISTEMA ESTÁ PARAMETRIZADO PARA NÃO ACEITAR ITENS BONIFCADOS NO PEDIDO TV14;';
      P_REGNOTA.VALIDO := FALSE;
    END IF;

    SELECT COUNT(*) QT
      INTO VICONT_BNF_INVALIDO
      FROM PCPEDIFVMANIF
     WHERE NUMPEDRCA = P_REGNOTA.NUMPEDRCA
       AND CODUSUR   = P_REGNOTA.CODUSUR
       AND NVL(BONIFIC, 'N') <> 'N'
       AND NVL(BONIFIC, 'N') NOT IN('F', 'S');

    IF (VICONT_BNF_INVALIDO > 0)
    THEN
      IF VSMENSAGEM IS NOT NULL THEN
        VSCHAR := '#';
      ELSE
        VSCHAR := NULL;
      END IF;

      VSMENSAGEM := VSMENSAGEM || VSCHAR ||
        'ITEM BONIFICADO COM DADO INVÁLIDO(BONIFIC); ';

      P_REGNOTA.VALIDO := FALSE;
    END IF;

    --VEN-817

		IF P_REGNOTA.CODCOB = 'BNF' THEN

			IF P_REGNOTA.BONIFICALTDEBCREDRCA = 'S' THEN

				P_REGNOTA.BRINDE := 'S';
			ELSE
				P_REGNOTA.BRINDE := 'N';
			END IF;

			-- end if;

		END IF;

		-- registra log
		IF (VSMENSAGEM IS NOT NULL) THEN
			PROC_REGISTRALOG(P_REGNOTA.NUMPED,
											 P_REGNOTA.NUMPEDRCA,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 P_REGNOTA.CODUSUR,
											 NULL,
											 P_REGNOTA.CANCELADA,
											 '11',
											 VSMENSAGEM,
											 NULL);
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			P_REGNOTA.VALIDO := FALSE;
			PROC_REGISTRALOG(P_REGNOTA.NUMPED,
											 P_REGNOTA.NUMPEDRCA,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 P_REGNOTA.CODUSUR,
											 NULL,
											 P_REGNOTA.CANCELADA,
											 '11',
											 SQLCODE || '-' || SQLERRM,
											 NULL);
	END PROC_VALIDARNOTA;

	PROCEDURE PROC_VALIDARITEMNOTA(P_REGITEMNOTA IN OUT T_ITEMNOTA,
																 P_REGNOTA     IN OUT T_NOTA,
																 P_REGCLIENTE  IN T_CLIENTEPEDIDO,
																 P_REGRCA      IN T_RCA,
																 P_REGREGIAO   IN T_REGIAOCLIENTE,
																 P_REGPLPAG    IN T_PLANODEPAGAMENTO,
																 P_REGPRODUTO  OUT T_PRODUTO,
																 P_REGPRECOS   OUT T_PRECOSETRIBUTACAO,
																 P_REGFILIAL   IN T_FILIAL,
																 VSCODDISTRIB  IN PCPRODUT.CODDISTRIB%TYPE) IS

		VICONTADOR              NUMBER;
		VSMENSAGEM              VARCHAR2(32767);
		VSMENSAGEMPOLITICA      VARCHAR2(32767);
		VSCHAR                  VARCHAR2(1) DEFAULT '#';
		VNPERMAXDESC            NUMBER;
		VNPVENDAMIN             NUMBER;
		VNPVENDAMAX             NUMBER;
		VBEXISTEPOLITICA        BOOLEAN;
		VNPERCDESCQUANT         PCDESCQUANT.PERCDESC%TYPE;
		VNPERCDESCPOLITICA      PCDESCONTO.PERCDESC%TYPE;
		VSBASECREDDEBRCA        PCDESCONTO.BASECREDDEBRCA%TYPE;
		VNDESCONTO              NUMBER;
		VNNRAUTORIZACAO         PCAUTORI.NRAUTORIZACAO%TYPE;
		VNPERCDESCAUTOR         PCAUTORI.PERCDESCAUTOR%TYPE;
		VNPVENDAATUAL           PCAUTORI.PVENDAATUAL%TYPE;
		VNPVENDA_AUTORI         NUMBER;
		VBVALIDOPRECOFIXO       BOOLEAN := TRUE;
		VNPRECOFIXO             NUMBER;
		VNPERDESCATIV           NUMBER;
		VNPTABELA_ANT           NUMBER;
		VNPPOLITICA             NUMBER;
		VNPTABELADESCQUANT      NUMBER;
		VSMENSAGEMDESCQUANT     VARCHAR2(32767);
		VDDTFIM                 DATE;
		VBVALIDODESCQUANT       BOOLEAN := FALSE;
		VSMENSAGEMPRECOFIXO     VARCHAR2(32767);
		VSBASECREDDEBRCA_AUTORI PCAUTORI.BASECREDDEBRCA%TYPE;

		VNPERMAXVENDA                NUMBER;
		VSMENSAGEMPOLITICA_ACRES     VARCHAR2(32767);
		VBEXISTEPOLITICA_ACRES       BOOLEAN;
		VNPERCDESCPOLITICA_ACRES     PCDESCONTO.PERCDESC%TYPE;
		VSCREDITASOBREPTABELA        PCDESCQUANT.CREDITASOBREPTABELA%TYPE;
		VNPERCAUX                    NUMBER;
		VNPERCQUANTFLEX              NUMBER;
		VSCREDITASOBREPOLITICA       PCDESCONTO.CREDITASOBREPOLITICA%TYPE;
		VNPERCDESCPOLITICA_ACRES_AUX NUMBER;

		VNCODST PCTRIBUT.CODST%TYPE;

		VSBASECREDDEBRCA_QUANT     PCDESCQUANT.BASECREDDEBRCA%TYPE;
		VNPTABELAAUX               PCPEDI.PTABELA%TYPE;
		VNPERCBASERCA_QUANT        PCDESCQUANT.PERCDESC%TYPE;
		VSPRIORITARIA_AUX          PCDESCQUANT.PRIORITARIA%TYPE;
		VSQUESTIONAPRIORITARIA_AUX PCDESCQUANT.QUESTIONAUSOPRIORITARIA%TYPE;
		VSALTERAPTABELA            PCDESCONTO.ALTERAPTABELA%TYPE;
		VNPERCPBASERCA             PCDESCONTO.PERCDESC%TYPE;

		VNQTVENDTV13 NUMBER(18, 6);
		VNQTVENDTV14 NUMBER(18, 6);
    VNQTDEVTV13  NUMBER(18, 6);

		VSTIPOPRAZO       PCPLPAG.TIPOPRAZO%TYPE;
		VICOTARCA         NUMBER;
		VICOTACLI         NUMBER;
		VBVALIDOCOTARCA   BOOLEAN;
		VBVALIDOCOTACLI   BOOLEAN;
		VSMENSAGEMCOTARCA VARCHAR2(1000);
		VSMENSAGEMCOTACLI VARCHAR2(1000);
    VNPERDESCCOM      PCPEDI.PERDESCCOM%TYPE;
    VSPODECOMPRAR     VARCHAR2(1);
    VSMSGTEMP         VARCHAR2(4000);
    VNQTDTEMP         NUMBER(14,4);
    VNUMPEDTV13       NUMBER(10);
    VENCONTROUSERIE   BOOLEAN := FALSE;
    p_regdesconto     t_descontos;
    VnCodfilialretira NUMBER(3);
    PVENDA_TEMP       NUMBER(18, 6);
    vsItemTV1BNF      VARCHAR2(2);
    VNVLPVENDASEMIMPOSTO NUMBER(18, 6);
    vFatorPrecoMinimo NUMBER := 1;
    vsValidaPrecoMinimo            VARCHAR2(3);
    vsAceitaDescontoBalcaoReserva  VARCHAR2(3);
    vsAceitaDescAcimaFlexFv        VARCHAR2(3);
    vsRetiraImposto201             VARCHAR2(1);
    vConsideraPrecoSemImposto      VARCHAR2(1);
    VSAPLICADESCONTOSIMPLES        VARCHAR2(1);
    VNCODPRECOFIXO                 VARCHAR2(32767);
    vnvlredsimplesnac_ptabela      PCPEDI.VLREDPVENDASIMPLESNA%TYPE;
    vnptabela_semimpostos          PCPEDI.PTABELA%TYPE;
    vnvlipi_ptabela                PCPEDI.VLIPI%TYPE;
    vnvlst_ptabela                 PCPEDI.ST%TYPE;
    vnvlfecp_ptabela               PCPEDI.VLFECP%TYPE;
    vnpbaserca_semimpostos         PCPEDI.PBASERCA%TYPE;
    VSUTILIZACODPRODPRINC          VARCHAR2(1);
    vbvalido_autori                BOOLEAN;
    vnPercomAutori               pcautori.percom%type;
    vsmensagemautori             VARCHAR2(1000);
    vnCODEMITENTE                PCPEDC.CODEMITENTE%TYPE;

	BEGIN
		P_REGITEMNOTA.VALIDO := TRUE;
		VSMENSAGEM           := NULL;

		VNQTVENDTV13 := 0;
		VNQTVENDTV14 := 0;
    VNQTDEVTV13  := 0;

        -- HIS.02043.2016 -----
    --Buscar o número do pedido
    FOR PEDIDOS IN (
    SELECT NUMPED
        --INTO VNUMPEDTV13
    FROM PCPEDC
    WHERE NUMCAR = P_REGNOTA.NUMCARMANIF
        AND CONDVENDA = 13)
    LOOP

        --Verificar se o produto tem numero de série informado no TV13
    SELECT COUNT(*)
    INTO VICONTADOR
    FROM PCCONTROLENUMSERIE
        WHERE NUMPED = PEDIDOS.NUMPED

    AND CODPROD = P_REGITEMNOTA.CODPROD;


    IF VICONTADOR > 0 THEN
       -- Buscar todos os numeros de série do TV14
       FOR ITENS IN (
           SELECT NUMSERIE
           FROM PCNUMEROSERIEFV
           WHERE CODPROD = P_REGITEMNOTA.CODPROD
           AND NUMPEDRCA = P_REGNOTA.NUMPEDRCA
           AND CODUSUR = P_REGITEMNOTA.CODUSUR)
       LOOP
           --Verifica se o numero de série do TV14 existe no TV13
           VENCONTROUSERIE := TRUE;
           SELECT COUNT(*)
           INTO VICONTADOR
           FROM PCCONTROLENUMSERIE
           WHERE CODPROD = P_REGITEMNOTA.CODPROD
           AND NUMPED = PEDIDOS.NUMPED
           AND NUMSERIE = ITENS.NUMSERIE;


           IF VICONTADOR = 0 THEN
     			    IF VSMENSAGEM IS NOT NULL THEN
				         VSCHAR := '#';
			        ELSE
				         VSCHAR := NULL;

			        END IF;


              VSMENSAGEM := VSMENSAGEM || VSCHAR ||	'Número de Série '||ITENS.NUMSERIE ||' não encontrado para o produto: '|| P_REGITEMNOTA.CODPROD ||' ;';
			        P_REGNOTA.VALIDO := FALSE;

              EXIT;
           END IF;

       END LOOP;


       IF NOT VENCONTROUSERIE THEN
          IF VSMENSAGEM IS NOT NULL THEN
				     VSCHAR := '#';
			    ELSE
				     VSCHAR := NULL;

			    END IF;


            VSMENSAGEM := VSMENSAGEM || VSCHAR ||	'Série(s) não encontrada(s) no TV14;';
			    P_REGNOTA.VALIDO := FALSE;
       END IF;

    END IF;

   END LOOP;
    ----------FIM HIS.02043.2016-------------



	IF P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM = 'S' THEN
		--verifica se item existe no carregamento
		SELECT COUNT(*)
			INTO VICONTADOR
			FROM PCPEDC P, PCPEDI I
		 WHERE /*P.CODUSUR = P_REGNOTA.CODUSUR
			 AND */P.NUMCAR = P_REGNOTA.NUMCARMANIF
			 AND P.CONDVENDA = 13
			 AND P.NUMPED = I.NUMPED
			 AND I.CODPROD = P_REGITEMNOTA.CODPROD
			 AND ((I.CODAUXILIAR = NVL(P_REGITEMNOTA.CODAUXILIAR, I.CODAUXILIAR)) OR
					 (I.CODAUXILIAR IS NULL));
    ELSE
    	SELECT COUNT(*)
			INTO VICONTADOR
			FROM PCPEDC P, PCPEDI I
		 WHERE /*P.CODUSUR = P_REGNOTA.CODUSUR
			 AND */P.NUMCAR = P_REGNOTA.NUMCARMANIF
			 AND P.CONDVENDA = 13
			 AND P.NUMPED = I.NUMPED
			 AND I.CODPROD = P_REGITEMNOTA.CODPROD;
    END IF;

		IF VICONTADOR = 0 THEN
			IF VSMENSAGEM IS NOT NULL THEN
				VSCHAR := '#';
			ELSE
				VSCHAR := NULL;
			END IF;

			VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
															'Produto nao encontrado no carregamento;';
			P_REGITEMNOTA.VALIDO := FALSE;

		ELSE

			SELECT SUM(QT)
				INTO VNQTVENDTV13
				FROM PCPEDC P, PCPEDI I
			 WHERE /*P.CODUSUR = P_REGNOTA.CODUSUR
				 AND */P.NUMCAR = P_REGNOTA.NUMCARMANIF
				 AND P.CONDVENDA = 13
				 AND P.NUMPED = I.NUMPED
				 AND I.CODPROD = P_REGITEMNOTA.CODPROD
				 AND P.POSICAO <> 'C';


      -- deduzindo a qtde. já devolvida na 1332.
      SELECT NVL(SUM (PCMOV.QT),0) QTDEVOL
        INTO VNQTDEVTV13
        FROM PCPEDC C, PCNFSAID, PCESTCOM, PCMOV
       WHERE C.NUMCAR = P_REGNOTA.NUMCARMANIF
         AND C.NUMPED = PCNFSAID.NUMPED
         AND C.CONDVENDA = 13
         AND PCNFSAID.NUMTRANSVENDA = PCESTCOM.NUMTRANSVENDA
         AND PCESTCOM.NUMTRANSENT = PCMOV.NUMTRANSENT
         AND PCMOV.CODPROD = P_REGITEMNOTA.CODPROD;

      VNQTVENDTV13 := VNQTVENDTV13 - VNQTDEVTV13;

			--verifica se já tem algum outro pedido tv14 com este produto
			BEGIN

				SELECT SUM(QT)
					INTO VNQTVENDTV14
					FROM PCPEDC P, PCPEDI I
				 WHERE /*P.CODUSUR = P_REGNOTA.CODUSUR
					 AND */P.NUMCARMANIF = P_REGNOTA.NUMCARMANIF
					 AND P.CONDVENDA = 14
					 AND P.NUMPED = I.NUMPED
					 AND I.CODPROD = P_REGITEMNOTA.CODPROD
					 AND P.POSICAO <> 'C';

			EXCEPTION
				WHEN OTHERS THEN
					VNQTVENDTV14 := 0;
			END;

		END IF;

		IF NVL(P_REGNOTA.CANCELADA, 'N') = 'N' THEN
			--tarefa 159152
			IF NVL(VNQTVENDTV14, 0) + NVL(P_REGITEMNOTA.QT, 0) >
				 NVL(VNQTVENDTV13, 0) THEN

				IF VSMENSAGEM IS NOT NULL THEN
					VSCHAR := '#';
				ELSE
					VSCHAR := NULL;
				END IF;

				VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
																' QUANTIDADE SOLICITADA ULTRAPASSA A QUANTIDADE EXISTENTE NO CARREGAMENTO; ' ||
																' QUANTIDADE TV13 : ' ||   to_char(NVL(VNQTVENDTV13,0) + NVL(VNQTDEVTV13,0)) ||
                                ' QUANTIDADE DEVOL TV13: ' || to_char(NVL(VNQTDEVTV13,0)) ||
                                ' QUANTIDADE TV14 + QT DO PEDIDO: ' || to_char(NVL(VNQTVENDTV14, 0) + NVL(P_REGITEMNOTA.QT, 0)) ||
                                ' QUANTIDADE DISPONIVEL( TV13 - DEVOL - TV14): ' || to_char(NVL(VNQTVENDTV13, 0)  - NVL(VNQTVENDTV14, 0));
				P_REGITEMNOTA.VALIDO := FALSE;

			END IF;

		END IF;

		IF NVL(P_REGITEMNOTA.PVENDA, 0) <= 0 THEN

			IF VSMENSAGEM IS NOT NULL THEN
				VSCHAR := '#';
			ELSE
				VSCHAR := NULL;
			END IF;
			VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
															'PRODUTO COM PRECO DE VENDA INVALIDO;';
			P_REGITEMNOTA.VALIDO := FALSE;

		END IF;

    --HIS.02651.2015
    IF (P_REGNOTA.VALIDO) AND
       (p_REGFILIAL.VALIDARALVARAVENDA = 'S')
    THEN
      BEGIN
        PRC_MED_VALIDA_CONTROLE_VENDA('I',
                                      P_REGNOTA.CODCLI,
                                      P_REGCLIENTE.TIPOFJ,
                                      P_REGITEMNOTA.CODPROD,
                                      P_REGITEMNOTA.QT,
                                      P_REGNOTA.NUMPED,
                                      P_REGITEMNOTA.NUMSEQ,
                                      VSPODECOMPRAR,
                                      VSMSGTEMP,
                                      VNQTDTEMP);

        IF VSPODECOMPRAR = 'N' THEN
          VSMENSAGEM  := VSMENSAGEM || VSCHAR || 'PRODUTO COM CONTROLE DE VENDA' ||
                         VSCHAR || VSMSGTEMP;
          P_REGNOTA.VALIDO := FALSE;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          VSMENSAGEM  := VSMENSAGEM || VSCHAR || 'ERRO AO VALIDAR CONTROLE DE VENDA!' ||
          SQLCODE || '-' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ';';
          P_REGNOTA.VALIDO := FALSE;
      END;
    END IF;
    -- FIM HIS.02651.2015

		-- verificar se o produto esta cadastrado
		SELECT COUNT(*)
			INTO VICONTADOR
			FROM PCPRODUT
		 WHERE CODPROD = P_REGITEMNOTA.CODPROD;

		IF VICONTADOR = 0 THEN
			IF VSMENSAGEM IS NOT NULL THEN
				VSCHAR := '#';
			ELSE
				VSCHAR := NULL;
			END IF;

			VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
															'Produto nao cadastrado;';
			P_REGITEMNOTA.VALIDO := FALSE;
		ELSE
			SELECT CODCATEGORIA,
						 CODEPTO,
						 PCPRODUT.CODFORNEC,
						 CODPROD,
						 CODSEC,
						 DESCRICAO,
						 EMBALAGEM,
						 PCPRODUT.OBS,
						 PCPRODUT.OBS2,
						 PCOMEXT1,
						 PCOMINT1,
						 PCOMREP1,
						 NVL(PESOBRUTO, 0),
						 0,
						 QTUNIT,
						 NVL(VOLUME, 0),
						 CODPRODPRINC,
						 PCPRODUT.PERINDENIZ,
						 CODLINHAPROD,
						 NVL(PCPRODUT.CODDISTRIB, NVL(PCFORNEC.CODDISTRIB, '')) CODDISTRIB,
						 PCPRODUT.FRETEESPECIAL,
						 PCPRODUT.CLASSE,
						 PCPRODUT.PERCIPIVENDA,
						 NVL(PCPRODUT.PRAZOMEDIOVENDA, 0),
						 PCPRODUT.IMPORTADO,
						 NVL(PCPRODUT.PERCIPIVENDATAB, 0),
						 NVL(PCPRODUT.VLPAUTAIPIVENDA, 0),
						 NVL(PCPRODUT.VLPAUTAIPIVENDATAB, 0),
						 NVL(PCPRODUT.VLIPIPORKGVENDA, 0),
						 NVL(PCPRODUT.VLIPIPORKGVENDATAB, 0),
						 PCPRODUT.PRAZOMAXINDENIZACAO,
						 PCPRODUT.PESOBRUTOMASTER,
						 PCPRODUT.PESOPECA,
						 PCPRODUT.TIPOESTOQUE,
						 PCPRODUT.TIPOMERC,
						 NVL(PCPRODUT.CUSTOREP, 0),
						 NVL(PCPRODUT.CUSTOREPZFM, 0),
						 PCPRODUT.PSICOTROPICO,
						 NVL(PCPRODUT.PERCBONIFICVENDA, 0),
						 PCPRODUT.UTILIZAPRECOMAXCONSUMIDOR,
						 NVL(PCPRODUT.PRECOMAXCONSUM, 0),
						 PCPRODUT.UNIDADEMASTER,
						 NVL(PCPRODUT.MULTIPLO, 0),
						 PCPRODUT.CHECARMULTIPLOVENDABNF,
						 PCPRODUT.CODFILIALRETIRA,
						 PCPRODUT.TIPOCOMISSAO,
						 NVL(PCPRODUT.GRUPOFATURAMENTO, 'N'),
						 PCPRODUT.CODSUBCATEGORIA,
						 NVL(PCPRODUT.CONTROLADOIBAMA, 'N')
				INTO P_REGPRODUTO
				FROM PCPRODUT, PCFORNEC
			 WHERE CODPROD = P_REGITEMNOTA.CODPROD
				 AND PCPRODUT.CODFORNEC = PCFORNEC.CODFORNEC;
		END IF;

		-- 188740
		SELECT COUNT(*)
			INTO VICOTARCA
			FROM PCPRODUSUR P
		 WHERE P.DATAINICIO <= TRUNC(SYSDATE)
			 AND P.DATAFIM >= TRUNC(SYSDATE)
			 AND P.CODPROD = P_REGITEMNOTA.CODPROD
			 AND (P.NUMREGIAO = P_REGREGIAO.NUMREGIAO OR P.NUMREGIAO IS NULL)
			 AND P.CODUSUR = P_REGNOTA.CODUSUR
			 AND P.TIPOCOTA = 'U';

		IF VICOTARCA > 0 THEN

			VBVALIDOCOTARCA := FUNCOESVENDAS.VERIFICARCOTARCA(P_REGITEMNOTA.CODPROD,
																												P_REGNOTA.CODUSUR,
																												P_REGITEMNOTA.QT,
																												P_REGREGIAO.NUMREGIAO,
																												VSMENSAGEMCOTARCA);

			IF VBVALIDOCOTARCA = FALSE THEN
				IF VSMENSAGEM IS NOT NULL THEN
					VSCHAR := '#';
				ELSE
					VSCHAR := NULL;
				END IF;

				VSMENSAGEM           := VSMENSAGEM || VSCHAR || VSMENSAGEMCOTARCA;
				P_REGITEMNOTA.VALIDO := FALSE;
			END IF;

		END IF;

		SELECT COUNT(*)
			INTO VICOTACLI
			FROM PCPRODUSUR P
		 WHERE P.DATAINICIO <= TRUNC(SYSDATE)
			 AND P.DATAFIM >= TRUNC(SYSDATE)
			 AND P.CODPROD = P_REGITEMNOTA.CODPROD
			 AND (P.NUMREGIAO = P_REGREGIAO.NUMREGIAO OR P.NUMREGIAO IS NULL)
			 AND P.CODUSUR IS NULL
			 AND P.CODCLI = P_REGNOTA.CODCLI
			 AND P.TIPOCOTA = 'C';

		IF VICOTACLI > 0 THEN

			VBVALIDOCOTACLI := FUNCOESVENDAS.VERIFICARCOTACLIENTE(P_REGITEMNOTA.CODPROD,
																														P_REGNOTA.CODCLI,
																														P_REGITEMNOTA.QT,
																														P_REGREGIAO.NUMREGIAO,
																														VSMENSAGEMCOTACLI);

			IF VBVALIDOCOTACLI = FALSE THEN
				IF VSMENSAGEM IS NOT NULL THEN
					VSCHAR := '#';
				ELSE
					VSCHAR := NULL;
				END IF;

				VSMENSAGEM           := VSMENSAGEM || VSCHAR || VSMENSAGEMCOTACLI;
				P_REGITEMNOTA.VALIDO := FALSE;
			END IF;

		END IF;

		-- busca as informacoes da tabela de preco.

		IF P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM = 'S' THEN

			IF P_REGITEMNOTA.CODAUXILIAR = 0 OR P_REGITEMNOTA.CODAUXILIAR IS NULL THEN

				IF VSMENSAGEM IS NOT NULL THEN
					VSCHAR := '#';
				ELSE
					VSCHAR := NULL;
				END IF;

				VSMENSAGEM := VSMENSAGEM || VSCHAR || 'CODAUXILIAR INVALIDO' || ';';

				P_REGITEMNOTA.VALIDO := FALSE;

			ELSE

				SELECT COUNT(*)
					INTO VICONTADOR
					FROM PCEMBALAGEM P
				 WHERE CODPROD = P_REGITEMNOTA.CODPROD
					 AND CODFILIAL = P_REGNOTA.CODFILIAL
					 AND CODAUXILIAR = P_REGITEMNOTA.CODAUXILIAR;

				IF VICONTADOR = 0 THEN

					IF VSMENSAGEM IS NOT NULL THEN
						VSCHAR := '#';
					ELSE
						VSCHAR := NULL;
					END IF;

					VSMENSAGEM := VSMENSAGEM || VSCHAR ||
												'PRODUTO NAO ENCONTRADO COM ESTE CODAUXILIAR' || ';';

					P_REGITEMNOTA.VALIDO := FALSE;

				END IF;

			END IF;

		END IF;

		IF P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM = 'S' THEN -- Primeira validação dos dados de ST.

			--tributacao por estado
			IF NVL(GREGPCCONSUM.USATRIBUTACAOPORUF, 'N') = 'S' THEN

				SELECT COUNT(*)
					INTO VICONTADOR
					FROM PCTABTRIB P
				 WHERE P.CODPROD = P_REGITEMNOTA.CODPROD
					 AND P.CODFILIALNF = P_REGNOTA.CODFILIALNF
					 AND P.UFDESTINO = P_REGCLIENTE.ESTENT;

				IF VICONTADOR = 0 THEN
					IF VSMENSAGEM IS NOT NULL THEN
						VSCHAR := '#';
					ELSE
						VSCHAR := NULL;
					END IF;
					VSMENSAGEM := VSMENSAGEM || VSCHAR ||
												'NÃO ENCONTRADA TRIBUTAÇÃO POR ESTADO;';

					P_REGITEMNOTA.VALIDO := FALSE;

				ELSE

					SELECT P.CODST
						INTO VNCODST
						FROM PCTABTRIB P
					 WHERE P.CODPROD = P_REGITEMNOTA.CODPROD
						 AND P.CODFILIALNF = P_REGNOTA.CODFILIALNF
						 AND P.UFDESTINO = P_REGCLIENTE.ESTENT
						 AND ROWNUM = 1;

					-- busca as informacoes da tabela de preco.

					BEGIN
						SELECT NVL(PCTRIBUT.ALIQICMS1, 0),
									 NVL(PCTRIBUT.ALIQICMS2, 0),
									 NVL(PCTRIBUT.CODICMTAB, 0),
									 PCTRIBUT.CODST,
									 NVL(PCEST.CUSTOCONT, 0),
									 NVL(PCEST.CUSTOFIN, 0),
									 NVL(PCEST.CUSTOREAL, 0),
									 NVL(PCEST.CUSTOREP, 0),
									 NVL(PCEST.CUSTOULTENT, 0),
									 NVL(PCTABPR.EXCLUIDO, 'N'),
									 NVL(PCTRIBUT.IVA, 0),
									 NVL(PCTRIBUT.PAUTA, 0),
									 NVL(PCTRIBUT.PERACRESCISMOPF, 0),
									 NVL(PCTABPR.PERDESCAUTOR, 0),
									 NVL(PCTRIBUT.PERDESCCUSTO, 0),
									 NVL(PCTABPR.PERDESCMAX, 0),
									 NVL(PCTABPR.PERDESCMAXESP, 0),
									 PCTRIBUT.PERDESTAB,
									 NVL(PCTABPR.PRECOMINIMOVENDA, 0),
									 (NVL(PCTABPR.PVENDA, 0) *
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													 0,
													 1,
													 NVL(PCEMBALAGEM.FATORPRECO, 1))),
									 (NVL(PCTABPR.PVENDA1, 0) *
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													 0,
													 1,
													 NVL(PCEMBALAGEM.FATORPRECO, 1))),
									 (NVL(PCTABPR.PVENDA2, 0) *
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													 0,
													 1,
													 NVL(PCEMBALAGEM.FATORPRECO, 1))),
									 (NVL(PCTABPR.PVENDA3, 0) *
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													 0,
													 1,
													 NVL(PCEMBALAGEM.FATORPRECO, 1))),
									 (NVL(PCTABPR.PVENDA4, 0) *
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													 0,
													 1,
													 NVL(PCEMBALAGEM.FATORPRECO, 1))),
									 (NVL(PCTABPR.PVENDA5, 0) *
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													 0,
													 1,
													 NVL(PCEMBALAGEM.FATORPRECO, 1))),
									 (NVL(PCTABPR.PVENDA6, 0) *
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													 0,
													 1,
													 NVL(PCEMBALAGEM.FATORPRECO, 1))),
									 (NVL(PCTABPR.PVENDA7, 0) *
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													 0,
													 1,
													 NVL(PCEMBALAGEM.FATORPRECO, 1))),
									 NVL(PCTABPR.QTDESCAUTOR, 0),
									 NVL(PCTRIBUT.APLICAACRESCPJISENTA, 'N'),
									 NVL(PCTRIBUT.PERCBASEREDST, 0),
									 NVL(PCTRIBUT.TIPOCALCULOGNRE, 'P'),
									 NVL(PCTRIBUT.IVAFONTE, 0),
									 NVL(PCTRIBUT.ALIQICMS1FONTE, 0),
									 NVL(PCTRIBUT.ALIQICMS2FONTE, 0),
									 NVL(PCTRIBUT.PERCBASEREDSTFONTE, 0),
									 NVL(PCTRIBUT.PERCBASERED, 0),
									 NVL(PCTRIBUT.PERBASEREDNRPA, 0),
									 NVL(PCTRIBUT.PERCBASEREDCONSUMIDOR, 0),
									 NVL(UTILIZAPERCBASEREDPF, 'N'),
									 NVL(PCEST.VALORULTENT, 0),
									 NVL(PCTRIBUT.USAVALORULTENTBASEST, 'N'),
									 NVL(PCTRIBUT.USAVALORULTENTBASEST2, 'N'),
									 NVL(PCTRIBUT.CODICMTABPF, 0),
									 NVL(PCTRIBUT.PERDESCSUFRAMA, 0),
									 NVL(PCTRIBUT.PERDESCICMISENCAO, 0),
									 PCTABPR.DESCONTAFRETE,
									 NVL(PCTRIBUT.PERCDESCPIS, 0),
									 NVL(PCTRIBUT.PERCDESCCOFINS, 0),
									 NVL(PCTRIBUT.PERDESCREPASSE, 0),
									 NVL(PCTABPR.PRECOMAXCONSUM, 0),
									 NVL(PCEMBALAGEM.QTUNIT, 1),
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													0,
													1,
													NVL(PCEMBALAGEM.FATORPRECO, 1)),
									 NVL(PCEMBALAGEM.QTMINIMAATACADO, 0),
									 (DECODE(NVL(PCEMBALAGEM.PVENDAATAC, 0),
													 0,
													 NVL(PCEMBALAGEM.PVENDA, 0),
													 NVL(PCEMBALAGEM.PVENDAATAC, 0)) *
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													 0,
													 1,
													 NVL(PCEMBALAGEM.FATORPRECO, 1))),
									 (NVL(PCEMBALAGEM.PVENDA, 0) *
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													 0,
													 1,
													 NVL(PCEMBALAGEM.FATORPRECO, 1))),
									 (NVL(PCEMBALAGEM.POFERTA, 0) *
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													 0,
													 1,
													 NVL(PCEMBALAGEM.FATORPRECO, 1))),
									 NVL(PCTABPR.PVENDAATAC1, 0),
									 NVL(PCTABPR.PVENDAATAC2, 0),
									 NVL(PCTABPR.PVENDAATAC3, 0),
									 NVL(PCTABPR.PVENDAATAC4, 0),
									 NVL(PCTABPR.PVENDAATAC5, 0),
									 NVL(PCTABPR.PVENDAATAC6, 0),
									 NVL(PCTABPR.PVENDAATAC7, 0),
									 PCEMBALAGEM.DTOFERTAINI,
									 PCEMBALAGEM.DTOFERTAFIM,
									 PCEMBALAGEM.DTOFERTAATACINI,
									 PCEMBALAGEM.DTOFERTAATACFIM,
									 NVL(PCEMBALAGEM.POFERTAATAC, 0),
									 NVL(PCTRIBUT.MOSTRARPVENDASEMST,
											 GREGPCCONSUM.MOSTRARPVENDASEMST),
									 NVL(PCTRIBUT.USAPMCBASEST, 'N'),
									 NVL(PCEST.CUSTONFSEMST, NVL(PCEST.VALORULTENT, 0)),
									 NVL(PCTRIBUT.PERCREDPVENDASIMPLESNAC, 0),
									 NVL(PCEST.VLSTULTENT, 0),
									 NVL(PCTRIBUT.PERCDIFALIQUOTAS, 0),
									 NVL(PCEST.CUSTONFSEMSTGUIAULTENT, 0),
									 NVL(PCEST.IVAULTENT, 0),
									 NVL(PCEST.ALIQICMS1ULTENT, 0),
									 NVL(PCEST.ALIQICMS2ULTENT, 0),
									 NVL(PCEST.REDBASEIVAULTENT, 100),
									 NVL(PCEST.PERCICMSFRETEFOBSTULTENT, 0),
									 NVL(PCEST.VLFRETECONHECULTENT, 0),
									 NVL(PCEST.PERCALIQEXTGUIAULTENT, 0),
									 NVL(PCEST.BASEICMSULTENT, 0),
									 NVL(PCEST.VLSTGUIAULTENT, 0),
									 NVL(PCTRIBUT.USAISENCAOICMSVP, 'S'),
									 PCTRIBUT.PAGTONOMEDOCLIENTE,
									 NVL(PCTABPR.PERDESCMAXBALCAO, 0),
                   NVL(PCTABPR.VLST,0)
							INTO P_REGPRECOS
							FROM PCTABPR, PCTRIBUT, PCEST, PCEMBALAGEM
						 WHERE PCTRIBUT.CODST = VNCODST
							 AND PCTABPR.CODPROD = P_REGITEMNOTA.CODPROD
							 AND PCEST.CODPROD = P_REGITEMNOTA.CODPROD
							 AND PCTABPR.NUMREGIAO = P_REGREGIAO.NUMREGIAO
							 AND PCEST.CODFILIAL = P_REGNOTA.CODFILIAL
							 AND PCEMBALAGEM.CODPROD = P_REGITEMNOTA.CODPROD
							 AND PCEMBALAGEM.CODAUXILIAR = P_REGITEMNOTA.CODAUXILIAR
							 AND PCEMBALAGEM.CODFILIAL = P_REGNOTA.CODFILIAL;
					EXCEPTION
						WHEN OTHERS THEN
							IF VSMENSAGEM IS NOT NULL THEN
								VSCHAR := '#';
							ELSE
								VSCHAR := NULL;
							END IF;
							VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
																			'ERRO AO BUSCAR PRECO DO PRODUTO#;' ||
																			SQLCODE || '-' || SQLERRM || ';';
							P_REGITEMNOTA.VALIDO := FALSE;

					END;

					P_REGITEMNOTA.PVENDA := ROUND(P_REGITEMNOTA.PVENDA /
																				P_REGPRECOS.QTUNIT,
																				GREGPCCONSUM.NUMCASASDECVENDA);

					P_REGITEMNOTA.QT := P_REGITEMNOTA.QT * P_REGPRECOS.QTUNIT;

          BEGIN
          SELECT I.CODFILIALRETIRA
          INTO VnCodfilialretira
          FROM PCPEDC C, PCPEDI I
          WHERE C.NUMPED = I.NUMPED
          AND C.NUMCAR   = I.NUMCAR
          AND C.NUMCAR   = P_REGNOTA.NUMCARMANIF
          AND I.CODPROD  = P_REGITEMNOTA.CODPROD
          AND C.NUMPED   = (SELECT NUMPED FROM PCPEDC WHERE NUMCAR = P_REGNOTA.NUMCARMANIF AND CONDVENDA = 13 AND NUMPED = I.NUMPED)
          AND ROWNUM = 1;

          EXCEPTION
		      	WHEN NO_DATA_FOUND THEN
				    VnCodfilialretira := P_REGNOTA.CODFILIAL;
           END;

      IF P_REGITEMNOTA.ST > 0 THEN

         PVENDA_TEMP := P_REGITEMNOTA.PVENDA - P_REGITEMNOTA.ST - P_REGITEMNOTA.VLFECP;

         BEGIN
          SELECT ALIQICMS1, ALIQICMS2, PAUTA, REDUCAO, IVA, DECODE(STGNRE,'P', ST, 0), ALIQFECP
          INTO P_REGITEMNOTA.ALIQICMS1 , P_REGITEMNOTA.ALIQICMS2, P_REGITEMNOTA.PAUTA, P_REGITEMNOTA.PERCBASEREDST
              ,P_REGITEMNOTA.IVA, P_REGITEMNOTA.STGNRE, P_REGITEMNOTA.ALIQFECP
          FROM TABLE (
          pkg_tributacao.calcular_st(P_REGNOTA.CODFILIAL,
                                     P_REGNOTA.CODFILIALNF,
                                     VnCodfilialretira,
                                     P_REGNOTA.CODCLI,
                                     P_REGNOTA.CODPLPAG,
                                     P_REGITEMNOTA.CODPROD,
                                     P_REGITEMNOTA.CODAUXILIAR,
                                     P_REGNOTA.CONDVENDA,
                                     'N',
                                     PVENDA_TEMP,
                                     0));

           EXCEPTION
						WHEN OTHERS THEN
							IF VSMENSAGEM IS NOT NULL THEN
								VSCHAR := '#';
							ELSE
								VSCHAR := NULL;
							END IF;
							VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
																			'ERRO AO BUSCAR DADOS FISCAIS DO PRODUTO;' || P_REGITEMNOTA.CODPROD ||
																			SQLCODE || '-' || SQLERRM || ';';
							P_REGITEMNOTA.VALIDO := FALSE;

					END;

				 END IF;
				END IF;

				--não usa tributação por estado
			ELSE
				-- busca as informacoes da tabela de preco.
				BEGIN
					SELECT NVL(PCTRIBUT.ALIQICMS1, 0),
								 NVL(PCTRIBUT.ALIQICMS2, 0),
								 NVL(PCTRIBUT.CODICMTAB, 0),
								 PCTABPR.CODST,
								 NVL(PCEST.CUSTOCONT, 0),
								 NVL(PCEST.CUSTOFIN, 0),
								 NVL(PCEST.CUSTOREAL, 0),
								 NVL(PCEST.CUSTOREP, 0),
								 NVL(PCEST.CUSTOULTENT, 0),
								 NVL(PCTABPR.EXCLUIDO, 'N'),
								 NVL(PCTRIBUT.IVA, 0),
								 NVL(PCTRIBUT.PAUTA, 0),
								 NVL(PCTRIBUT.PERACRESCISMOPF, 0),
								 NVL(PCTABPR.PERDESCAUTOR, 0),
								 NVL(PCTRIBUT.PERDESCCUSTO, 0),
								 NVL(PCTABPR.PERDESCMAX, 0),
								 NVL(PCTABPR.PERDESCMAXESP, 0),
								 PCTRIBUT.PERDESTAB,
								 NVL(PCTABPR.PRECOMINIMOVENDA, 0),
								 (NVL(PCTABPR.PVENDA, 0) *
								 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
												 0,
												 1,
												 NVL(PCEMBALAGEM.FATORPRECO, 1))),
								 (NVL(PCTABPR.PVENDA1, 0) *
								 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
												 0,
												 1,
												 NVL(PCEMBALAGEM.FATORPRECO, 1))),
								 (NVL(PCTABPR.PVENDA2, 0) *
								 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
												 0,
												 1,
												 NVL(PCEMBALAGEM.FATORPRECO, 1))),
								 (NVL(PCTABPR.PVENDA3, 0) *
								 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
												 0,
												 1,
												 NVL(PCEMBALAGEM.FATORPRECO, 1))),
								 (NVL(PCTABPR.PVENDA4, 0) *
								 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
												 0,
												 1,
												 NVL(PCEMBALAGEM.FATORPRECO, 1))),
								 (NVL(PCTABPR.PVENDA5, 0) *
								 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
												 0,
												 1,
												 NVL(PCEMBALAGEM.FATORPRECO, 1))),
								 (NVL(PCTABPR.PVENDA6, 0) *
								 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
												 0,
												 1,
												 NVL(PCEMBALAGEM.FATORPRECO, 1))),
								 (NVL(PCTABPR.PVENDA7, 0) *
								 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
												 0,
												 1,
												 NVL(PCEMBALAGEM.FATORPRECO, 1))),
								 NVL(PCTABPR.QTDESCAUTOR, 0),
								 NVL(PCTRIBUT.APLICAACRESCPJISENTA, 'N'),
								 NVL(PERCBASEREDST, 0),
								 NVL(PCTRIBUT.TIPOCALCULOGNRE, 'P'),
								 NVL(PCTRIBUT.IVAFONTE, 0),
								 NVL(PCTRIBUT.ALIQICMS1FONTE, 0),
								 NVL(PCTRIBUT.ALIQICMS2FONTE, 0),
								 NVL(PCTRIBUT.PERCBASEREDSTFONTE, 0),
								 NVL(PCTRIBUT.PERCBASERED, 0),
								 NVL(PCTRIBUT.PERBASEREDNRPA, 0),
								 NVL(PCTRIBUT.PERCBASEREDCONSUMIDOR, 0),
								 NVL(UTILIZAPERCBASEREDPF, 'N'),
								 NVL(PCEST.VALORULTENT, 0),
								 NVL(PCTRIBUT.USAVALORULTENTBASEST, 'N'),
								 NVL(PCTRIBUT.USAVALORULTENTBASEST2, 'N'),
								 NVL(PCTRIBUT.CODICMTABPF, 0),
								 NVL(PCTRIBUT.PERDESCSUFRAMA, 0),
								 NVL(PCTRIBUT.PERDESCICMISENCAO, 0),
								 PCTABPR.DESCONTAFRETE,
								 NVL(PCTRIBUT.PERCDESCPIS, 0),
								 NVL(PCTRIBUT.PERCDESCCOFINS, 0),
								 NVL(PCTRIBUT.PERDESCREPASSE, 0),
								 NVL(PCTABPR.PRECOMAXCONSUM, 0),
								 NVL(PCEMBALAGEM.QTUNIT, 1),
								 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
												0,
												1,
												NVL(PCEMBALAGEM.FATORPRECO, 1)),
								 NVL(PCEMBALAGEM.QTMINIMAATACADO, 0),
								 (DECODE(NVL(PCEMBALAGEM.PVENDAATAC, 0),
												 0,
												 NVL(PCEMBALAGEM.PVENDA, 0),
												 NVL(PCEMBALAGEM.PVENDAATAC, 0)) *
								 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
												 0,
												 1,
												 NVL(PCEMBALAGEM.FATORPRECO, 1))),
								 (NVL(PCEMBALAGEM.PVENDA, 0) *
								 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
												 0,
												 1,
												 NVL(PCEMBALAGEM.FATORPRECO, 1))),
								 (NVL(PCEMBALAGEM.POFERTA, 0) *
								 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
												 0,
												 1,
												 NVL(PCEMBALAGEM.FATORPRECO, 1))),
								 NVL(PCTABPR.PVENDAATAC1, 0),
								 NVL(PCTABPR.PVENDAATAC2, 0),
								 NVL(PCTABPR.PVENDAATAC3, 0),
								 NVL(PCTABPR.PVENDAATAC4, 0),
								 NVL(PCTABPR.PVENDAATAC5, 0),
								 NVL(PCTABPR.PVENDAATAC6, 0),
								 NVL(PCTABPR.PVENDAATAC7, 0),
								 PCEMBALAGEM.DTOFERTAINI,
								 PCEMBALAGEM.DTOFERTAFIM,
								 PCEMBALAGEM.DTOFERTAATACINI,
								 PCEMBALAGEM.DTOFERTAATACFIM,
								 NVL(PCEMBALAGEM.POFERTAATAC, 0),
								 NVL(PCTRIBUT.MOSTRARPVENDASEMST,
										 GREGPCCONSUM.MOSTRARPVENDASEMST),
								 NVL(PCTRIBUT.USAPMCBASEST, 'N'),
								 NVL(PCEST.CUSTONFSEMST, NVL(PCEST.VALORULTENT, 0)),
								 NVL(PCTRIBUT.PERCREDPVENDASIMPLESNAC, 0),
								 NVL(PCEST.VLSTULTENT, 0),
								 NVL(PCTRIBUT.PERCDIFALIQUOTAS, 0),
								 NVL(PCEST.CUSTONFSEMSTGUIAULTENT, 0),
								 NVL(PCEST.IVAULTENT, 0),
								 NVL(PCEST.ALIQICMS1ULTENT, 0),
								 NVL(PCEST.ALIQICMS2ULTENT, 0),
								 NVL(PCEST.REDBASEIVAULTENT, 100),
								 NVL(PCEST.PERCICMSFRETEFOBSTULTENT, 0),
								 NVL(PCEST.VLFRETECONHECULTENT, 0),
								 NVL(PCEST.PERCALIQEXTGUIAULTENT, 0),
								 NVL(PCEST.BASEICMSULTENT, 0),
								 NVL(PCEST.VLSTGUIAULTENT, 0),
								 NVL(PCTRIBUT.USAISENCAOICMSVP, 'S'),
								 PCTRIBUT.PAGTONOMEDOCLIENTE,
								 NVL(PCTABPR.PERDESCMAXBALCAO, 0),
                 NVL(PCTABPR.VLST,0)
						INTO P_REGPRECOS
						FROM PCTABPR, PCTRIBUT, PCEST, PCEMBALAGEM
					 WHERE PCTABPR.CODST = PCTRIBUT.CODST
						 AND PCTABPR.CODPROD = P_REGITEMNOTA.CODPROD
						 AND PCEST.CODPROD = P_REGITEMNOTA.CODPROD
						 AND PCTABPR.NUMREGIAO = P_REGREGIAO.NUMREGIAO
						 AND PCEST.CODFILIAL = P_REGNOTA.CODFILIAL
						 AND PCEMBALAGEM.CODPROD = P_REGITEMNOTA.CODPROD
						 AND PCEMBALAGEM.CODAUXILIAR = P_REGITEMNOTA.CODAUXILIAR
						 AND PCEMBALAGEM.CODFILIAL = P_REGNOTA.CODFILIAL;

				EXCEPTION
					WHEN OTHERS THEN
						IF VSMENSAGEM IS NOT NULL THEN
							VSCHAR := '#';
						ELSE
							VSCHAR := NULL;
						END IF;
						VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
																		'ERRO AO BUSCAR PRECO DO PRODUTO#;' ||
																		SQLCODE || '-' || SQLERRM || ';';
						P_REGITEMNOTA.VALIDO := FALSE;

				END;

				P_REGITEMNOTA.PVENDA := ROUND(P_REGITEMNOTA.PVENDA /
																			P_REGPRECOS.QTUNIT,
																			GREGPCCONSUM.NUMCASASDECVENDA);

				P_REGITEMNOTA.QT := P_REGITEMNOTA.QT * P_REGPRECOS.QTUNIT;

         BEGIN
          SELECT I.CODFILIALRETIRA
          INTO VnCodfilialretira
          FROM PCPEDC C, PCPEDI I
          WHERE C.NUMPED = I.NUMPED
          AND C.NUMCAR   = I.NUMCAR
          AND C.NUMCAR   = P_REGNOTA.NUMCARMANIF
          AND I.CODPROD  = P_REGITEMNOTA.CODPROD
          AND C.NUMPED   = (SELECT NUMPED FROM PCPEDC WHERE NUMCAR = P_REGNOTA.NUMCARMANIF AND CONDVENDA = 13 AND NUMPED = I.NUMPED)
          AND ROWNUM = 1;

          EXCEPTION
		      	WHEN NO_DATA_FOUND THEN
				    VnCodfilialretira := P_REGNOTA.CODFILIAL;
           END;


      IF P_REGITEMNOTA.ST > 0 THEN

         PVENDA_TEMP := P_REGITEMNOTA.PVENDA - P_REGITEMNOTA.ST - P_REGITEMNOTA.VLFECP;

         BEGIN
          SELECT ALIQICMS1, ALIQICMS2, PAUTA, REDUCAO, IVA, DECODE(STGNRE,'P', ST, 0), ALIQFECP
          INTO P_REGITEMNOTA.ALIQICMS1 , P_REGITEMNOTA.ALIQICMS2, P_REGITEMNOTA.PAUTA, P_REGITEMNOTA.PERCBASEREDST
              ,P_REGITEMNOTA.IVA, P_REGITEMNOTA.STGNRE, P_REGITEMNOTA.ALIQFECP
          FROM TABLE (
          pkg_tributacao.calcular_st(P_REGNOTA.CODFILIAL,
                                     P_REGNOTA.CODFILIALNF,
                                     VnCodfilialretira,
                                     P_REGNOTA.CODCLI,
                                     P_REGNOTA.CODPLPAG,
                                     P_REGITEMNOTA.CODPROD,
                                     P_REGITEMNOTA.CODAUXILIAR,
                                     P_REGNOTA.CONDVENDA,
                                     'N',
                                     PVENDA_TEMP,
                                     0));

           EXCEPTION
						WHEN OTHERS THEN
							IF VSMENSAGEM IS NOT NULL THEN
								VSCHAR := '#';
							ELSE
								VSCHAR := NULL;
							END IF;
							VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
																			'ERRO AO BUSCAR DADOS FISCAIS DO PRODUTO;' || P_REGITEMNOTA.CODPROD ||
																			SQLCODE || '-' || SQLERRM || ';';
							P_REGITEMNOTA.VALIDO := FALSE;

					END;

				END IF;

			END IF;

			--não usa venda por embalagem
		ELSE

			--tributacao por estado
			IF NVL(GREGPCCONSUM.USATRIBUTACAOPORUF, 'N') = 'S' THEN

				SELECT COUNT(*)
					INTO VICONTADOR
					FROM PCTABTRIB P
				 WHERE P.CODPROD = P_REGITEMNOTA.CODPROD
					 AND P.CODFILIALNF = P_REGNOTA.CODFILIALNF
					 AND P.UFDESTINO = P_REGCLIENTE.ESTENT;

				IF VICONTADOR = 0 THEN
					IF VSMENSAGEM IS NOT NULL THEN
						VSCHAR := '#';
					ELSE
						VSCHAR := NULL;
					END IF;
					VSMENSAGEM := VSMENSAGEM || VSCHAR ||
												'NÃO ENCONTRADA TRIBUTAÇÃO POR ESTADO;';

					P_REGITEMNOTA.VALIDO := FALSE;

				ELSE

					SELECT P.CODST
						INTO VNCODST
						FROM PCTABTRIB P
					 WHERE P.CODPROD = P_REGITEMNOTA.CODPROD
						 AND P.CODFILIALNF = P_REGNOTA.CODFILIALNF
						 AND P.UFDESTINO = P_REGCLIENTE.ESTENT
						 AND ROWNUM = 1;

					-- busca as informacoes da tabela de preco.

					BEGIN
						SELECT NVL(PCTRIBUT.ALIQICMS1, 0),
									 NVL(PCTRIBUT.ALIQICMS2, 0),
									 NVL(PCTRIBUT.CODICMTAB, 0),
									 PCTRIBUT.CODST,
									 NVL(PCEST.CUSTOCONT, 0),
									 NVL(PCEST.CUSTOFIN, 0),
									 NVL(PCEST.CUSTOREAL, 0),
									 NVL(PCEST.CUSTOREP, 0),
									 NVL(PCEST.CUSTOULTENT, 0),
									 NVL(PCTABPR.EXCLUIDO, 'N'),
									 NVL(PCTRIBUT.IVA, 0),
									 NVL(PCTRIBUT.PAUTA, 0),
									 NVL(PCTRIBUT.PERACRESCISMOPF, 0),
									 NVL(PCTABPR.PERDESCAUTOR, 0),
									 NVL(PCTRIBUT.PERDESCCUSTO, 0),
									 NVL(PCTABPR.PERDESCMAX, 0),
									 NVL(PCTABPR.PERDESCMAXESP, 0),
									 PCTRIBUT.PERDESTAB,
									 NVL(PCTABPR.PRECOMINIMOVENDA, 0),
									 NVL(PCTABPR.PVENDA, 0),
									 NVL(PCTABPR.PVENDA1, 0),
									 NVL(PCTABPR.PVENDA2, 0),
									 NVL(PCTABPR.PVENDA3, 0),
									 NVL(PCTABPR.PVENDA4, 0),
									 NVL(PCTABPR.PVENDA5, 0),
									 NVL(PCTABPR.PVENDA6, 0),
									 NVL(PCTABPR.PVENDA7, 0),
									 NVL(PCTABPR.QTDESCAUTOR, 0),
									 NVL(PCTRIBUT.APLICAACRESCPJISENTA, 'N'),
									 NVL(PCTRIBUT.PERCBASEREDST, 0),
									 NVL(PCTRIBUT.TIPOCALCULOGNRE, 'P'),
									 NVL(PCTRIBUT.IVAFONTE, 0),
									 NVL(PCTRIBUT.ALIQICMS1FONTE, 0),
									 NVL(PCTRIBUT.ALIQICMS2FONTE, 0),
									 NVL(PCTRIBUT.PERCBASEREDSTFONTE, 0),
									 NVL(PCTRIBUT.PERCBASERED, 0),
									 NVL(PCTRIBUT.PERBASEREDNRPA, 0),
									 NVL(PCTRIBUT.PERCBASEREDCONSUMIDOR, 0),
									 NVL(UTILIZAPERCBASEREDPF, 'N'),
									 NVL(PCEST.VALORULTENT, 0),
									 NVL(PCTRIBUT.USAVALORULTENTBASEST, 'N'),
									 NVL(PCTRIBUT.USAVALORULTENTBASEST2, 'N'),
									 NVL(PCTRIBUT.CODICMTABPF, 0),
									 NVL(PCTRIBUT.PERDESCSUFRAMA, 0),
									 NVL(PCTRIBUT.PERDESCICMISENCAO, 0),
									 PCTABPR.DESCONTAFRETE,
									 NVL(PCTRIBUT.PERCDESCPIS, 0),
									 NVL(PCTRIBUT.PERCDESCCOFINS, 0),
									 NVL(PCTRIBUT.PERDESCREPASSE, 0),
									 NVL(PCTABPR.PRECOMAXCONSUM, 0),
									 1,
									 1,
									 0,
									 0,
									 0,
									 0,
									 0,
									 0,
									 0,
									 0,
									 0,
									 0,
									 0,
									 NULL,
									 NULL,
									 NULL,
									 NULL,
									 0,
									 NVL(PCTRIBUT.MOSTRARPVENDASEMST,
											 GREGPCCONSUM.MOSTRARPVENDASEMST),
									 NVL(PCTRIBUT.USAPMCBASEST, 'N'),
									 NVL(PCEST.CUSTONFSEMST, NVL(PCEST.VALORULTENT, 0)),
									 NVL(PCTRIBUT.PERCREDPVENDASIMPLESNAC, 0),
									 NVL(PCEST.VLSTULTENT, 0),
									 NVL(PCTRIBUT.PERCDIFALIQUOTAS, 0),
									 NVL(PCEST.CUSTONFSEMSTGUIAULTENT, 0),
									 NVL(PCEST.IVAULTENT, 0),
									 NVL(PCEST.ALIQICMS1ULTENT, 0),
									 NVL(PCEST.ALIQICMS2ULTENT, 0),
									 NVL(PCEST.REDBASEIVAULTENT, 100),
									 NVL(PCEST.PERCICMSFRETEFOBSTULTENT, 0),
									 NVL(PCEST.VLFRETECONHECULTENT, 0),
									 NVL(PCEST.PERCALIQEXTGUIAULTENT, 0),
									 NVL(PCEST.BASEICMSULTENT, 0),
									 NVL(PCEST.VLSTGUIAULTENT, 0),
									 NVL(PCTRIBUT.USAISENCAOICMSVP, 'S'),
									 PCTRIBUT.PAGTONOMEDOCLIENTE,
									 NVL(PCTABPR.PERDESCMAXBALCAO, 0),
                   NVL(PCTABPR.VLST,0)
							INTO P_REGPRECOS
							FROM PCTABPR, PCTRIBUT, PCEST
						 WHERE PCTRIBUT.CODST = VNCODST
							 AND PCTABPR.CODPROD = P_REGITEMNOTA.CODPROD
							 AND PCEST.CODPROD = P_REGITEMNOTA.CODPROD
							 AND PCTABPR.NUMREGIAO = P_REGREGIAO.NUMREGIAO
							 AND PCEST.CODFILIAL = P_REGNOTA.CODFILIAL;
					EXCEPTION
						WHEN OTHERS THEN
							IF VSMENSAGEM IS NOT NULL THEN
								VSCHAR := '#';
							ELSE
								VSCHAR := NULL;
							END IF;
							VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
																			'ERRO AO BUSCAR PRECO DO PRODUTO#;' ||
																			SQLCODE || '-' || SQLERRM || ';';
							P_REGITEMNOTA.VALIDO := FALSE;

					END;

          BEGIN
           SELECT I.CODFILIALRETIRA
          INTO VnCodfilialretira
          FROM PCPEDC C, PCPEDI I
          WHERE C.NUMPED = I.NUMPED
          AND C.NUMCAR   = I.NUMCAR
          AND C.NUMCAR   = P_REGNOTA.NUMCARMANIF
          AND I.CODPROD  = P_REGITEMNOTA.CODPROD
          AND C.NUMPED   = (SELECT NUMPED FROM PCPEDC WHERE NUMCAR = P_REGNOTA.NUMCARMANIF AND CONDVENDA = 13 AND NUMPED = I.NUMPED)
          AND ROWNUM = 1;

          EXCEPTION
		      	WHEN NO_DATA_FOUND THEN
				    VnCodfilialretira := P_REGNOTA.CODFILIAL;
           END;


      IF P_REGITEMNOTA.ST > 0 THEN

         PVENDA_TEMP := P_REGITEMNOTA.PVENDA - P_REGITEMNOTA.ST - P_REGITEMNOTA.VLFECP;

         BEGIN
          SELECT ALIQICMS1, ALIQICMS2, PAUTA, REDUCAO, IVA, DECODE(STGNRE,'P', ST, 0), ALIQFECP
          INTO P_REGITEMNOTA.ALIQICMS1 , P_REGITEMNOTA.ALIQICMS2, P_REGITEMNOTA.PAUTA, P_REGITEMNOTA.PERCBASEREDST
              ,P_REGITEMNOTA.IVA, P_REGITEMNOTA.STGNRE, P_REGITEMNOTA.ALIQFECP
          FROM TABLE (
          pkg_tributacao.calcular_st(P_REGNOTA.CODFILIAL,
                                     P_REGNOTA.CODFILIALNF,
                                     VnCodfilialretira,
                                     P_REGNOTA.CODCLI,
                                     P_REGNOTA.CODPLPAG,
                                     P_REGITEMNOTA.CODPROD,
                                     P_REGITEMNOTA.CODAUXILIAR,
                                     P_REGNOTA.CONDVENDA,
                                     'N',
                                     PVENDA_TEMP,
                                     0));

           EXCEPTION
						WHEN OTHERS THEN
							IF VSMENSAGEM IS NOT NULL THEN
								VSCHAR := '#';
							ELSE
								VSCHAR := NULL;
							END IF;
							VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
																			'ERRO AO BUSCAR DADOS FISCAIS DO PRODUTO;' || P_REGITEMNOTA.CODPROD ||
																			SQLCODE || '-' || SQLERRM || ';';
							P_REGITEMNOTA.VALIDO := FALSE;

					END;

			  	END IF;

		 END IF;

				--não usa tributação por estado
			ELSE
				-- busca as informacoes da tabela de preco.
				BEGIN
					SELECT NVL(PCTRIBUT.ALIQICMS1, 0),
								 NVL(PCTRIBUT.ALIQICMS2, 0),
								 NVL(PCTRIBUT.CODICMTAB, 0),
								 PCTABPR.CODST,
								 NVL(PCEST.CUSTOCONT, 0),
								 NVL(PCEST.CUSTOFIN, 0),
								 NVL(PCEST.CUSTOREAL, 0),
								 NVL(PCEST.CUSTOREP, 0),
								 NVL(PCEST.CUSTOULTENT, 0),
								 NVL(PCTABPR.EXCLUIDO, 'N'),
								 NVL(PCTRIBUT.IVA, 0),
								 NVL(PCTRIBUT.PAUTA, 0),
								 NVL(PCTRIBUT.PERACRESCISMOPF, 0),
								 NVL(PCTABPR.PERDESCAUTOR, 0),
								 NVL(PCTRIBUT.PERDESCCUSTO, 0),
								 NVL(PCTABPR.PERDESCMAX, 0),
								 NVL(PCTABPR.PERDESCMAXESP, 0),
								 PCTRIBUT.PERDESTAB,
								 NVL(PCTABPR.PRECOMINIMOVENDA, 0),
								 NVL(PCTABPR.PVENDA, 0),
								 NVL(PCTABPR.PVENDA1, 0),
								 NVL(PCTABPR.PVENDA2, 0),
								 NVL(PCTABPR.PVENDA3, 0),
								 NVL(PCTABPR.PVENDA4, 0),
								 NVL(PCTABPR.PVENDA5, 0),
								 NVL(PCTABPR.PVENDA6, 0),
								 NVL(PCTABPR.PVENDA7, 0),
								 NVL(PCTABPR.QTDESCAUTOR, 0),
								 NVL(PCTRIBUT.APLICAACRESCPJISENTA, 'N'),
								 NVL(PERCBASEREDST, 0),
								 NVL(PCTRIBUT.TIPOCALCULOGNRE, 'P'),
								 NVL(PCTRIBUT.IVAFONTE, 0),
								 NVL(PCTRIBUT.ALIQICMS1FONTE, 0),
								 NVL(PCTRIBUT.ALIQICMS2FONTE, 0),
								 NVL(PCTRIBUT.PERCBASEREDSTFONTE, 0),
								 NVL(PCTRIBUT.PERCBASERED, 0),
								 NVL(PCTRIBUT.PERBASEREDNRPA, 0),
								 NVL(PCTRIBUT.PERCBASEREDCONSUMIDOR, 0),
								 NVL(UTILIZAPERCBASEREDPF, 'N'),
								 NVL(PCEST.VALORULTENT, 0),
								 NVL(PCTRIBUT.USAVALORULTENTBASEST, 'N'),
								 NVL(PCTRIBUT.USAVALORULTENTBASEST2, 'N'),
								 NVL(PCTRIBUT.CODICMTABPF, 0),
								 NVL(PCTRIBUT.PERDESCSUFRAMA, 0),
								 NVL(PCTRIBUT.PERDESCICMISENCAO, 0),
								 PCTABPR.DESCONTAFRETE,
								 NVL(PCTRIBUT.PERCDESCPIS, 0),
								 NVL(PCTRIBUT.PERCDESCCOFINS, 0),
								 NVL(PCTRIBUT.PERDESCREPASSE, 0),
								 NVL(PCTABPR.PRECOMAXCONSUM, 0),
								 1,
								 1,
								 0,
								 0,
								 0,
								 0,
								 0,
								 0,
								 0,
								 0,
								 0,
								 0,
								 0,
								 NULL,
								 NULL,
								 NULL,
								 NULL,
								 0,
								 NVL(PCTRIBUT.MOSTRARPVENDASEMST,
										 GREGPCCONSUM.MOSTRARPVENDASEMST),
								 NVL(PCTRIBUT.USAPMCBASEST, 'N'),
								 NVL(PCEST.CUSTONFSEMST, NVL(PCEST.VALORULTENT, 0)),
								 NVL(PCTRIBUT.PERCREDPVENDASIMPLESNAC, 0),
								 NVL(PCEST.VLSTULTENT, 0),
								 NVL(PCTRIBUT.PERCDIFALIQUOTAS, 0),
								 NVL(PCEST.CUSTONFSEMSTGUIAULTENT, 0),
								 NVL(PCEST.IVAULTENT, 0),
								 NVL(PCEST.ALIQICMS1ULTENT, 0),
								 NVL(PCEST.ALIQICMS2ULTENT, 0),
								 NVL(PCEST.REDBASEIVAULTENT, 100),
								 NVL(PCEST.PERCICMSFRETEFOBSTULTENT, 0),
								 NVL(PCEST.VLFRETECONHECULTENT, 0),
								 NVL(PCEST.PERCALIQEXTGUIAULTENT, 0),
								 NVL(PCEST.BASEICMSULTENT, 0),
								 NVL(PCEST.VLSTGUIAULTENT, 0),
								 NVL(PCTRIBUT.USAISENCAOICMSVP, 'S'),
								 PCTRIBUT.PAGTONOMEDOCLIENTE,
								 NVL(PCTABPR.PERDESCMAXBALCAO, 0),
                 NVL(PCTABPR.VLST,0)
						INTO P_REGPRECOS
						FROM PCTABPR, PCTRIBUT, PCEST
					 WHERE PCTABPR.CODST = PCTRIBUT.CODST
						 AND PCTABPR.CODPROD = P_REGITEMNOTA.CODPROD
						 AND PCEST.CODPROD = P_REGITEMNOTA.CODPROD
						 AND PCTABPR.NUMREGIAO = P_REGREGIAO.NUMREGIAO
						 AND PCEST.CODFILIAL = P_REGNOTA.CODFILIAL;
				EXCEPTION
					WHEN OTHERS THEN
						IF VSMENSAGEM IS NOT NULL THEN
							VSCHAR := '#';
						ELSE
							VSCHAR := NULL;
						END IF;
						VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
																		'ERRO AO BUSCAR PRECO DO PRODUTO#;' ||
																		SQLCODE || '-' || SQLERRM || ';';
						P_REGITEMNOTA.VALIDO := FALSE;

				END;

			END IF;

       BEGIN
          SELECT I.CODFILIALRETIRA
          INTO VnCodfilialretira
          FROM PCPEDC C, PCPEDI I
          WHERE C.NUMPED = I.NUMPED
          AND C.NUMCAR   = I.NUMCAR
          AND C.NUMCAR   = P_REGNOTA.NUMCARMANIF
          AND I.CODPROD  = P_REGITEMNOTA.CODPROD
          AND C.NUMPED   = (SELECT NUMPED FROM PCPEDC WHERE NUMCAR = P_REGNOTA.NUMCARMANIF AND CONDVENDA = 13 AND NUMPED = I.NUMPED)
          AND ROWNUM = 1;

       EXCEPTION
		    	WHEN OTHERS THEN
				    VnCodfilialretira := P_REGNOTA.CODFILIAL;
      END;

      IF P_REGITEMNOTA.ST > 0 THEN

         PVENDA_TEMP := P_REGITEMNOTA.PVENDA - P_REGITEMNOTA.ST - P_REGITEMNOTA.VLFECP;

         BEGIN
          SELECT ALIQICMS1, ALIQICMS2, PAUTA, REDUCAO, IVA, DECODE(STGNRE,'P', ST, 0), ALIQFECP
          INTO P_REGITEMNOTA.ALIQICMS1 , P_REGITEMNOTA.ALIQICMS2, P_REGITEMNOTA.PAUTA, P_REGITEMNOTA.PERCBASEREDST
              ,P_REGITEMNOTA.IVA, P_REGITEMNOTA.STGNRE, P_REGITEMNOTA.ALIQFECP
          FROM TABLE (
          pkg_tributacao.calcular_st(P_REGNOTA.CODFILIAL,
                                     P_REGNOTA.CODFILIALNF,
                                     VnCodfilialretira,
                                     P_REGNOTA.CODCLI,
                                     P_REGNOTA.CODPLPAG,
                                     P_REGITEMNOTA.CODPROD,
                                     P_REGITEMNOTA.CODAUXILIAR,
                                     P_REGNOTA.CONDVENDA,
                                     'N',
                                     PVENDA_TEMP,
                                     0));

           EXCEPTION
						WHEN OTHERS THEN
							IF VSMENSAGEM IS NOT NULL THEN
								VSCHAR := '#';
							ELSE
								VSCHAR := NULL;
							END IF;
							VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
																			'ERRO AO BUSCAR DADOS FISCAIS DO PRODUTO;' || P_REGITEMNOTA.CODPROD ||
																			SQLCODE || '-' || SQLERRM || ';';
							P_REGITEMNOTA.VALIDO := FALSE;

					END;

				END IF;

		END IF;

		IF P_REGFILIAL.PRECOPOREMBALAGEM = 'S' AND
			 P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM = 'S' THEN

			--Varejo
			IF P_REGFILIAL.TIPOPRECIFICACAO <> 'A' THEN
				IF P_REGPRECOS.QTMINIMAATACADO > 1 THEN
					IF P_REGITEMNOTA.QT >= P_REGPRECOS.QTMINIMAATACADO THEN
						P_REGPRODUTO.PTABELA := P_REGPRECOS.PVENDAATAC /
																		P_REGPRECOS.QTUNIT;
					ELSE
						P_REGPRODUTO.PTABELA := P_REGPRECOS.PVENDAEMB /
																		P_REGPRECOS.QTUNIT;
					END IF;
				ELSE
					P_REGPRODUTO.PTABELA := P_REGPRECOS.PVENDAEMB /
																	P_REGPRECOS.QTUNIT;
				END IF;
				--Atacado
			ELSE
				P_REGPRODUTO.PTABELA := P_REGPRECOS.PVENDAATAC / P_REGPRECOS.QTUNIT;

			END IF;

			--tarefa 70944 verificar poferta como preco minimo
			IF (P_REGPRECOS.POFERTA > 0) AND
				 TRUNC(SYSDATE) BETWEEN P_REGPRECOS.DTOFERTAINI AND
				 P_REGPRECOS.DTOFERTAFIM THEN

				IF P_REGITEMNOTA.QT < P_REGPRECOS.QTMINIMAATACADO THEN
					P_REGPRODUTO.PTABELA := P_REGPRECOS.POFERTA / P_REGPRECOS.QTUNIT;
				END IF;
			END IF;

			IF P_REGFILIAL.TIPOPRECIFICACAO <> 'A' THEN
				IF (P_REGPRECOS.POFERTA > 0) AND
					 (TRUNC(SYSDATE) BETWEEN P_REGPRECOS.DTOFERTAINI AND
					 P_REGPRECOS.DTOFERTAFIM) THEN
					IF P_REGITEMNOTA.QT < P_REGPRECOS.QTMINIMAATACADO THEN

						P_REGPRODUTO.PTABELA := P_REGPRECOS.POFERTA /
																		P_REGPRECOS.QTUNIT;
					END IF;
				END IF;
			ELSE
				IF (P_REGPRECOS.POFERTAATAC > 0) AND
					 (TRUNC(SYSDATE) BETWEEN P_REGPRECOS.DTOFERTAATACINI AND
					 P_REGPRECOS.DTOFERTAATACFIM) THEN
					IF P_REGITEMNOTA.QT >= P_REGPRECOS.QTMINIMAATACADO THEN
						P_REGPRODUTO.PTABELA := P_REGPRECOS.POFERTAATAC /
																		P_REGPRECOS.QTUNIT;
					END IF;
				END IF;
			END IF;

		END IF;

		P_REGITEMNOTA.GERAGNRE_CNPJCLIENTE := NULL;

		-- 160801
		IF P_REGPRECOS.TIPOCALCULOGNRE = 'P' AND
			 P_REGPRECOS.PAGTONOMEDOCLIENTE = 'S' THEN

			P_REGITEMNOTA.GERAGNRE_CNPJCLIENTE := 'S';

		END IF;

		-- produto sem custo financeiro
		IF P_REGPRECOS.CUSTOFIN = 0 THEN
			IF VSMENSAGEM IS NOT NULL THEN
				VSCHAR := '#';
			ELSE
				VSCHAR := NULL;
			END IF;

			VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
															'Produto sem custo financeiro;';
			P_REGITEMNOTA.VALIDO := FALSE;
		END IF;

		-- produto sem custo real
		IF P_REGPRECOS.CUSTOREAL = 0 THEN
			IF VSMENSAGEM IS NOT NULL THEN
				VSCHAR := '#';
			ELSE
				VSCHAR := NULL;
			END IF;

			VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
															'Produto sem custo real;';
			P_REGITEMNOTA.VALIDO := FALSE;
		END IF;

		-- produto sem custo real + crédito de icm
		IF P_REGPRECOS.CUSTOREP = 0 THEN
			IF VSMENSAGEM IS NOT NULL THEN
				VSCHAR := '#';
			ELSE
				VSCHAR := NULL;
			END IF;

			VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
															'Produto sem custo reposicao;';
			P_REGITEMNOTA.VALIDO := FALSE;
		END IF;

		-- verifica produto com preco 0 (zero)
		IF P_REGFILIAL.PRECOPOREMBALAGEM = 'N' OR
       P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM = 'N' THEN
			IF (P_REGPRECOS.PVENDA <= 0) OR (P_REGPRECOS.PVENDA1 <= 0) OR
				 (P_REGPRECOS.PVENDA2 <= 0) OR (P_REGPRECOS.PVENDA3 <= 0) OR
				 (P_REGPRECOS.PVENDA4 <= 0) OR (P_REGPRECOS.PVENDA5 <= 0) OR
				 (P_REGPRECOS.PVENDA6 <= 0) OR (P_REGPRECOS.PVENDA7 <= 0) THEN
				IF VSMENSAGEM IS NOT NULL THEN
					VSCHAR := '#';
				ELSE
					VSCHAR := NULL;
				END IF;

				VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
																'Preco de tabela zerado;';
				P_REGITEMNOTA.VALIDO := FALSE;
			END IF;

			IF P_REGPLPAG.NUMPR = 1 THEN
				P_REGPRODUTO.PTABELA := P_REGPRECOS.PVENDA1;
			ELSIF P_REGPLPAG.NUMPR = 2 THEN
				P_REGPRODUTO.PTABELA := P_REGPRECOS.PVENDA2;
			ELSIF P_REGPLPAG.NUMPR = 3 THEN
				P_REGPRODUTO.PTABELA := P_REGPRECOS.PVENDA3;
			ELSIF P_REGPLPAG.NUMPR = 4 THEN
				P_REGPRODUTO.PTABELA := P_REGPRECOS.PVENDA4;
			ELSIF P_REGPLPAG.NUMPR = 5 THEN
				P_REGPRODUTO.PTABELA := P_REGPRECOS.PVENDA5;
			ELSIF P_REGPLPAG.NUMPR = 6 THEN
				P_REGPRODUTO.PTABELA := P_REGPRECOS.PVENDA6;
			ELSIF P_REGPLPAG.NUMPR = 7 THEN
				P_REGPRODUTO.PTABELA := P_REGPRECOS.PVENDA7;
			END IF;

		END IF;

		-- tratamento com relacao ao preco e descontos
		IF P_REGITEMNOTA.VALIDO = TRUE THEN

      /*****************************
        USO DA PACKAGE DE DESCONTOS
      ******************************/
      -- aplica taxa financeira do plano de pagamento
			P_REGPRODUTO.PTABELA := P_REGPRODUTO.PTABELA *
															(1 + (P_REGPLPAG.PERTXFIM / 100));

			-- aplica politica acrescimo PF
			IF GREGPCCONSUM.ACRESCIMOPFCOMIE = 'S' THEN
				IF ((((P_REGPRECOS.APLICAACRESCPJISENTA = 'S') AND
					 ((P_REGCLIENTE.IEENT = 'ISENTA') OR
					 (P_REGCLIENTE.IEENT = 'ISENTO'))) OR
					 ((P_REGCLIENTE.TIPOFJ = 'F') OR
					 (P_REGCLIENTE.CONSUMIDORFINAL = 'S'))) AND
					 (P_REGCLIENTE.CONTRIBUINTE = 'N')) THEN

					P_REGPRODUTO.PTABELA := (P_REGPRODUTO.PTABELA +
																	(P_REGPRODUTO.PTABELA *
																	P_REGPRECOS.PERACRESCISMOPF / 100));

				END IF;
			ELSE
				IF ((((P_REGPRECOS.APLICAACRESCPJISENTA = 'S') AND
					 ((P_REGCLIENTE.IEENT = 'ISENTA') OR
					 (P_REGCLIENTE.IEENT = 'ISENTO'))) OR
					 (((P_REGCLIENTE.TIPOFJ = 'F') OR
					 (P_REGCLIENTE.CONSUMIDORFINAL = 'S')) AND
					 (TRIM(P_REGCLIENTE.IEENT) = ''))) AND
					 (P_REGCLIENTE.CONTRIBUINTE = 'N')) THEN

					P_REGPRODUTO.PTABELA := (P_REGPRODUTO.PTABELA +
																	(P_REGPRODUTO.PTABELA *
																	P_REGPRECOS.PERACRESCISMOPF / 100));

				END IF;
			END IF;

			--Desconto por Atividade
			BEGIN
				SELECT NVL(PCATIVI.PERCDESC, 0)
					INTO VNPERDESCATIV
					FROM PCATIVI, PCCLIENT
				 WHERE PCCLIENT.CODCLI = P_REGCLIENTE.CODCLI
					 AND PCCLIENT.CODATV1 = PCATIVI.CODATIV;
			EXCEPTION
				WHEN OTHERS THEN
					VNPERDESCATIV := 0;
			END;

			IF VNPERDESCATIV <> 0 THEN
				P_REGPRODUTO.PTABELA := (P_REGPRODUTO.PTABELA +
																(P_REGPRODUTO.PTABELA * VNPERDESCATIV / 100));
			END IF;

			P_REGITEMNOTA.PVENDABASE := P_REGPRODUTO.PTABELA;

      IF (P_REGNOTA.CODCOB = 'BNF') OR (P_REGITEMNOTA.BONIFIC IN('F', 'S')) THEN
        vsItemTV1BNF := 'F';
      ELSE
        vsItemTV1BNF := 'N';
      END IF;

      VSMENSAGEMPRECOFIXO := NULL;

      VBVALIDOPRECOFIXO := FUNCOESVENDAS.VALIDARPOLITICAPRECOFIXO(P_REGITEMNOTA.CODPROD,
                                                                  P_REGNOTA.DATA,
                                                                  P_REGCLIENTE.NUMREGIAO,
                                                                  P_REGNOTA.CODCLI,
                                                                  P_REGNOTA.CONDVENDA,
                                                                  P_REGNOTA.CODPLPAG,
                                                                  P_REGPRODUTO.PTABELA,
                                                                  GREGPCCONSUM.VALIDAPVENDABONIFIC,
                                                                  GREGPCCONSUM.UTILIZAPERCFINPRECOPROM,
                                                                  P_REGPLPAG.PERTXFIM,
                                                                  P_REGPLPAG.NUMDIAS,
                                                                  P_REGCLIENTE.CODCLIPRINC,
                                                                  P_REGPRODUTO.CODPRODPRINC,
                                                                  P_REGCLIENTE.CODPRACA,
                                                                  P_REGNOTA.CODUSUR,
                                                                  P_REGRCA.CODSUPERVISOR,
                                                                  NULL,
                                                                  P_REGNOTA.ORIGEMPED,
                                                                  P_REGCLIENTE.CODATV1,
                                                                  VDDTFIM,
                                                                  VSMENSAGEMPRECOFIXO,
                                                                  VNPRECOFIXO,
                                                                  P_REGNOTA.CODFILIAL,
                                                                  'S',
                                                                  P_REGFILIAL.BROKER,
                                                                  P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM,
                                                                  P_REGFILIAL.PRECOPOREMBALAGEM,
                                                                  P_REGNOTA.CODPLPAG,
                                                                  vConsideraPrecoSemImposto);

      IF VBVALIDOPRECOFIXO = TRUE THEN

        VNCODPRECOFIXO         := VSMENSAGEMPRECOFIXO;
        P_REGPRODUTO.PTABELA   := VNPRECOFIXO;
        P_REGITEMNOTA.PBASERCA := VNPRECOFIXO;

        IF NVL(GREGPCCONSUM.ACEITADESCPRECOFIXO, 'N') = 'N' THEN
          VNPERMAXDESC := 0;
        END IF;

        IF NVL(GREGPCCONSUM.ACEITAACRESCIMOPRECOFIXO, 'N') = 'N' THEN
          VNPERMAXVENDA := 0;
        END IF;

        IF NVL(VNCODPRECOFIXO,0) > 0 THEN
              BEGIN
               SELECT NVL(APLICADESCONTOSIMPLES, 'S')
                 INTO VSAPLICADESCONTOSIMPLES
                 FROM PCPRECOPROM
                WHERE CODPRECOPROM = VNCODPRECOFIXO;
              EXCEPTION
               WHEN OTHERS THEN
                VSAPLICADESCONTOSIMPLES    := 'S';
              END;
            END IF;

      ELSE

        IF VSMENSAGEMPRECOFIXO IS NOT NULL AND
           SUBSTR(VSMENSAGEMPRECOFIXO, 1, 1) = 'E' THEN

          VSMENSAGEM := VSMENSAGEM || VSCHAR || VSMENSAGEMPRECOFIXO;

        END IF;
      END IF;

      if (vsmensagemprecofixo is NULL) then
         vConsideraPrecoSemImposto := NVL(vConsideraPrecoSemImposto, 'N');
       else
         vConsideraPrecoSemImposto := NVL(vConsideraPrecoSemImposto, 'S');
      end if;

      -- verifica se é stfonte e o acrescenta aos preços de tabela e pbaserca
      -- Ponto alterado para validar corretamente o desconto e a política, caso possua.

      vsRetiraImposto201 := case VBVALIDOPRECOFIXO
                               when TRUE then vConsideraPrecoSemImposto
                               else 'S' END;

      IF (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('USADESCSIMPLESNAC',
                                             P_REGNOTA.codfilial,
                                               'N') = 'N') AND
           (nvl(p_regcliente.simplesnacional,'N') = 'S') AND
           (nvl(p_regprecos.percredpvendasimplesnac, 0) > 0)
      THEN
          vsRetiraImposto201 := 'S';
      END IF;

     /* IF ((P_REGCLIENTE.CLIENTEFONTEST = 'S') AND
         ((P_REGPRECOS.ALIQICMS1FONTE > 0) OR
         (P_REGPRECOS.ALIQICMS2FONTE > 0)) AND
         ((P_REGPRECOS.ALIQICMS1 = 0) OR (P_REGPRECOS.ALIQICMS2 = 0)))
         AND P_REGPRECOS.VLST = 0 THEN    */

        SELECT VALORSEMIMPOSTO
          INTO vnptabela_semimpostos
        FROM TABLE(PKG_TRIBUTACAO.CALCULAR_PVENDA_SEM_IMPOSTO(P_REGNOTA.codfilial,
                                                              P_REGNOTA.codfilialnf,
                                                              P_REGNOTA.codfilial,
                                                              P_REGNOTA.codcli,
                                                              P_REGNOTA.codplpag,
                                                              P_REGITEMNOTA.codprod,
                                                              P_REGITEMNOTA.codauxiliar,
                                                              14,
                                                              'N',
                                                              P_REGPRECOS.VLST, --1,
                                                              0,
                                                              P_REGPRODUTO.PTABELA,
                                                              vsRetiraImposto201,
                                                              'S',
                                                              vsItemTV1BNF,
                                                              vsmensagemprecofixo, --0,
                                                              'B',
                                                              'N',
                                                              'N',
                                                              'N',
                                                              'N',
                                                              P_REGPRODUTO.PTABELA,
                                                              'N',
                                                              'I',
                                                              '',
                                                              0));

        IF (FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('USADESCSIMPLESNAC',P_REGNOTA.codfilial,'N') = 'S')
          AND (nvl(p_regcliente.simplesnacional,'N') = 'S')
          AND NOT(VBVALIDOPRECOFIXO and VSAPLICADESCONTOSIMPLES = 'N')
        THEN
          --PTABELA
          SELECT nvl(VALOR_REDUCAO_SIMPLES_NACIONAL,0)
           INTO  vnvlredsimplesnac_ptabela
          FROM TABLE(PKG_TRIBUTACAO.CALCULAR_RED_SIMPLES_NACIONAL(P_REGNOTA.CODFILIAL,
                                                                  P_REGNOTA.CODFILIALNF,
                                                                  P_REGNOTA.CODFILIAL,
                                                                  P_REGNOTA.codcli,
                                                                  P_REGNOTA.codplpag,
                                                                  P_REGITEMNOTA.codprod,
                                                                  P_REGITEMNOTA.codauxiliar,
                                                                  14,
                                                                  'N',
                                                                  vnptabela_semimpostos,
                                                                  vnptabela_semimpostos));

          vnptabela_semimpostos := vnptabela_semimpostos - nvl(vnvlredsimplesnac_ptabela,0);
        END IF;

        SELECT nvl(VALORIPI,0)
            INTO vnvlipi_ptabela
            FROM TABLE(PKG_TRIBUTACAO.CALCULAR_IPI(P_REGNOTA.CODFILIAL,
                                                   P_REGNOTA.CODFILIALNF,
                                                   P_REGNOTA.CODFILIAL,
                                                   P_REGNOTA.CODCLI,
                                                   P_REGITEMNOTA.CODPROD,
                                                   P_REGITEMNOTA.CODAUXILIAR,
                                                   P_REGNOTA.CONDVENDA,
                                                   'N',
                                                   vnptabela_semimpostos,
                                                   'N',
                                                   0,
                                                   'N', --transferencia
                                                   'N', --transferenciaVirtual
                                                   'N',
                                                   'F',
                                                   0,
                                                   'I',
                                                    0,
                                                   'S',
                                                   'N'));
        SELECT nvl(ST,0), nvl(VLRFECP,0)
          INTO vnvlst_ptabela, vnVLFECP_ptabela
        FROM TABLE(PKG_TRIBUTACAO.CALCULAR_ST(P_REGNOTA.CODFILIAL,
                                               P_REGNOTA.codfilialnf,
                                               P_REGNOTA.codfilial,
                                               P_REGNOTA.codcli,
                                               P_REGNOTA.codplpag,
                                               P_REGITEMNOTA.codprod,
                                               P_REGITEMNOTA.codauxiliar,
                                               14,
                                               'N',
                                               vnptabela_semimpostos,
                                               0,
                                              vsItemTV1BNF,
                                              0,
                                              0,
                                              0,
                                              NULL,
                                              'S',
                                              'N',
                                              'T',
                                              'N',
                                              0,
                                              'N',
                                              0,
                                              'N',
                                              'I',
                                              '',
                                              '',
                                              'S',
                                              'N', --VEN-1315
                                              'N',
                                              'N',
                                              0
                                              ));

        IF P_REGPRECOS.TIPOCALCULOGNRE <> 'C' THEN

          vnptabela_semimpostos  := vnptabela_semimpostos + vnvlipi_ptabela + vnvlst_ptabela + vnVLFECP_ptabela;
          vnpbaserca_semimpostos := vnptabela_semimpostos;
        ELSE
          vnptabela_semimpostos  := vnptabela_semimpostos + vnvlipi_ptabela;
          vnpbaserca_semimpostos := vnptabela_semimpostos;
        END IF;

        P_REGPRODUTO.PTABELA   := ROUND((vnptabela_semimpostos),
                                        GREGPCCONSUM.NUMCASASDECVENDA);
        P_REGITEMNOTA.PBASERCA := ROUND((vnpbaserca_semimpostos),
                                        GREGPCCONSUM.NUMCASASDECVENDA);

      -- END IF;

			-- Desconto/Acrescimo por quantidade
      VNPERDESCCOM := ((P_REGPRODUTO.ptabela - P_REGITEMNOTA.pvenda) /P_REGPRODUTO.ptabela) * 100;

      IF NVL(P_REGITEMNOTA.CODCOMBO,0) = 0
        THEN

          select msg,
                 codesconto,
                 codescontobase,
                 datafinal,
                 percdesc,
                 percdescaut,
                 ptabeladesc,
                 pvendadesc,
                 pbaserca,
                 questionauso,
                 alteraptabela,
                 'N'
           into p_regdesconto
           from table (vendas.DESCONTO_ITEM_VENDA(P_REGCLIENTE.codcli,
                                                  P_REGITEMNOTA.codprod,
                                                  P_REGNOTA.codplpag,
                                                  P_REGNOTA.codusur,
                                                  VNPERDESCCOM,
                                                  P_REGPRODUTO.ptabela,
                                                  P_REGITEMNOTA.pvenda,
                                                  P_REGITEMNOTA.qt,
                                                  P_REGNOTA.origemped,
                                                '', --tipocarga
                                                P_REGNOTA.codfilial,
                                                P_REGNOTA.data,
                                                'N',  --pSomenteDescAut
                                                ferramentas.F_BUSCARPARAMETRO_ALFA('CON_ACEITADESCPRECOFIXO',P_REGNOTA.codfilial, 'N'),--psPrecoFixo /* 2522.119155.2014 VERIFICAR SE ACEITA DESCONTO NO PRECO FIXO */
                                                P_REGPRODUTO.ptabela,
                                                0, --pdDescontoPautado
                                                P_REGNOTA.codfilial));

           if NVL(P_REGDESCONTO.CODESCONTO,0) > 0
            AND NVL(P_REGDESCONTO.PERCDESCAUT,0) <> NVL(P_REGDESCONTO.PERCDESC,0)
             AND NVL(P_REGDESCONTO.PERCDESCAUT,0) > 0 THEN
              P_REGDESCONTO.PERCDESC := GREATEST(P_REGDESCONTO.PERCDESCAUT, P_REGDESCONTO.PERCDESC);
           end if;

          VSMENSAGEMDESCQUANT := 'N'; --p_regitem.prioritaria;

          VBVALIDODESCQUANT := FUNCOESVENDAS.VALIDARDESCONTOQUANTIDADE(0,
                                                                       P_REGITEMNOTA.CODPROD,
                                                                       P_REGITEMNOTA.QT,
                                                                       P_REGREGIAO.NUMREGIAO,
                                                                       P_REGPRODUTO.PTABELA,
                                                                       P_REGPRECOS.PVENDA1,
                                                                       P_REGCLIENTE.CODPRACA,
                                                                       GREGPCCONSUM.NUMCASASDECVENDA,
                                                                       P_REGPLPAG.NUMDIAS,
                                                                       'A',
                                                                       P_REGPRODUTO.CODPRODPRINC,
                                                                       P_REGNOTA.CODCLI,
                                                                       P_REGNOTA.CODUSUR,
                                                                       VDDTFIM,
                                                                       VSMENSAGEMDESCQUANT,
                                                                       VNPTABELADESCQUANT,
                                                                       VSCREDITASOBREPTABELA,
                                                                       VNPERCAUX,
                                                                       VSBASECREDDEBRCA_QUANT,
                                                                       VNPERCBASERCA_QUANT,
                                                                       VSPRIORITARIA_AUX,
                                                                       VSQUESTIONAPRIORITARIA_AUX,
                                                                       P_REGNOTA.CODFILIAL);

      END IF;

			IF p_regdesconto.percdesc > 0 THEN
      --IF VBVALIDODESCQUANT = TRUE THEN -- Alterado para usar a package de descontos

				IF P_REGCLIENTE.BLOQUEIO = 'S' AND
					 P_REGFILIAL.VALIDARPOLITICASDESCCLIBLOQ = 'S' AND
					 P_REGITEMNOTA.PVENDA < P_REGPRODUTO.PTABELA THEN

					IF VSMENSAGEM IS NOT NULL THEN
						VSCHAR := '#';
					ELSE
						VSCHAR := NULL;
					END IF;
					VSMENSAGEM := VSMENSAGEM || VSCHAR ||
												'NAO PERMITIDO APLICAR POLITICAS DE DESC. EM VENDAS DE CLIENTE BLOQUEADO;';

				ELSE

          BEGIN
            SELECT P.BASECREDDEBRCA,P.CREDITASOBREPOLITICA
              INTO VSBASECREDDEBRCA_QUANT, VSCREDITASOBREPTABELA
              FROM PCDESCONTO P
             WHERE P.CODDESCONTO = P_REGDESCONTO.CODESCONTO;
            EXCEPTION WHEN OTHERS THEN
              P_REGDESCONTO.PERCDESC := NULL;
              P_REGDESCONTO.PRIORITARIAGERAL := 'N';
          END;

					VNPTABELAAUX := P_REGPRODUTO.PTABELA;

          P_REGITEMNOTA.PBASERCA := P_REGDESCONTO.pbaserca;

					P_REGPRODUTO.PTABELA := ROUND(VNPTABELADESCQUANT,
																				GREGPCCONSUM.NUMCASASDECVENDA);

          P_REGITEMNOTA.CODDESCONTO := P_REGDESCONTO.CODESCONTO;

				END IF;

			ELSE

        IF P_REGDESCONTO.MSG IS NOT NULL AND UPPER(SUBSTR(P_REGDESCONTO.MSG,1,10)) <> 'O DESCONTO'  THEN
        -- Alterado para usar a package de descontos
					IF VSMENSAGEM IS NOT NULL THEN
						VSCHAR := '#';
					ELSE
						VSCHAR := NULL;
					END IF;
					VSMENSAGEM := VSMENSAGEM || VSCHAR || P_REGDESCONTO.MSG;--VSMENSAGEMDESCQUANT;
				END IF;

				P_REGITEMNOTA.PBASERCA := NVL(P_REGDESCONTO.pbaserca, P_REGPRODUTO.PTABELA);

			END IF;

      IF nvl(p_regdesconto.alteraptabela, 'N') = 'S' THEN
        P_REGPRODUTO.PTABELA := P_REGDESCONTO.ptabeladesc;
      END IF;

			-- *****Validação de descontos flexiveis
			VNPERMAXDESC := 0;
      if NVL(p_regdesconto.alteraptabela,'N') = 'N' then
        vnpermaxdesc := p_regdesconto.percdesc;
      end if;

			-- escolha do maior desconto - comparacao com desconto da tabela de preços
			IF P_REGPRECOS.PERDESCMAX > VNPERMAXDESC THEN

				VNPERMAXDESC := P_REGPRECOS.PERDESCMAX;

			END IF;

			-- escolha do maior desconto - comparacao com desconto do cliente
			IF P_REGCLIENTE.PERDESC > VNPERMAXDESC THEN

				VNPERMAXDESC := P_REGCLIENTE.PERDESC;

			END IF;

			IF NVL(GREGPCCONSUM.TRATARRESTRICAOACRESCIMO, 'N') = 'S' THEN

				VNPERMAXVENDA := NVL(GREGPCCONSUM.PERMAXVENDA, 0);

				IF VNPERMAXVENDA <
					 NVL(NVL(P_REGRCA.PERCACRESFV, P_REGRCA.PERMAXVENDA), 0) THEN

					VNPERMAXVENDA := NVL(NVL(P_REGRCA.PERCACRESFV,
																	 P_REGRCA.PERMAXVENDA),
															 100);
				END IF;

				IF NVL(VNPERCDESCPOLITICA_ACRES, 0) > VNPERMAXVENDA THEN
					VNPERMAXVENDA := VNPERCDESCPOLITICA_ACRES;
				END IF;

			ELSE

				VNPERMAXVENDA := NVL(GREGPCCONSUM.PERMAXVENDA, 100);

				IF NVL(NVL(P_REGRCA.PERCACRESFV, P_REGRCA.PERMAXVENDA), 0) > 0 THEN

					VNPERMAXVENDA := NVL(NVL(P_REGRCA.PERCACRESFV,
																	 P_REGRCA.PERMAXVENDA),
															 0);
				END IF;

			END IF;

			-- calculo preco minimo
			VNPVENDAMIN := (ROUND(P_REGPRODUTO.PTABELA,
														GREGPCCONSUM.NUMCASASDECVENDA)) *
										 (1 - (VNPERMAXDESC / 100));
			VNPVENDAMIN := ROUND(VNPVENDAMIN, GREGPCCONSUM.NUMCASASDECVENDA);

			-- calculo preco maximo
			VNPVENDAMAX := (ROUND(P_REGPRODUTO.PTABELA,
														GREGPCCONSUM.NUMCASASDECVENDA)) *
										 (1 + VNPERMAXVENDA / 100);
			VNPVENDAMAX := ROUND(VNPVENDAMAX, GREGPCCONSUM.NUMCASASDECVENDA);

			VNPTABELA_ANT := P_REGPRODUTO.PTABELA;

      IF GREGPCCONSUM.NUMCASASDECVENDA <= 3 then
         vFatorPrecoMinimo := (1/(power(10, GREGPCCONSUM.NUMCASASDECVENDA)));
      ELSE
         vFatorPrecoMinimo := (3/(power(10, GREGPCCONSUM.NUMCASASDECVENDA)));
      END IF;
      BEGIN
        SELECT MATRICULA
          INTO vnCODEMITENTE
        FROM PCEMPR
        WHERE CODUSUR = P_REGNOTA.CODUSUR;
          EXCEPTION WHEN OTHERS THEN
          vnCODEMITENTE := 8888;
      END;
      vsAceitaDescAcimaFlexFv           := ferramentas.F_BUSCARPARAMETRO_ALFA('ACEITADESCTMKFV', NVL(P_REGNOTA.CODFILIALNF, P_REGNOTA.CODFILIAL), 'N');
      vsAceitaDescontoBalcaoReserva     := ferramentas.F_BUSCARPARAMETRO_ALFA('CON_ACEITADESCBALCAORESERVA', '99', 'N');
      vsValidaPrecoMinimo               := ferramentas.F_BUSCARPARAMETRO_ALFA('CON_VALIDAPRECOMINIMO', '99', 'N');
      vbvalido_autori                   := funcoesvendas.validarautorizacaovenda(P_REGNOTA.numped,
                                                                         P_REGNOTA.codcli,
                                                                         coalesce(P_REGITEMNOTA.codusur, P_REGNOTA.CODUSUR),
                                                                         P_REGNOTA.codplpag,
                                                                         NVL(vnCODEMITENTE,8888),
                                                                         P_REGITEMNOTA.codprod,
                                                                         round((VNPTABELA_ANT ),GREGPCCONSUM.NUMCASASDECVENDA),
                                                                         round(P_REGPRODUTO.ptabela,GREGPCCONSUM.NUMCASASDECVENDA),
                                                                         round((P_REGITEMNOTA.pvenda),GREGPCCONSUM.NUMCASASDECVENDA),
                                                                         P_REGITEMNOTA.codauxiliar,
                                                                         VNPERDESCCOM,
                                                                         GREGPCCONSUM.NUMCASASDECVENDA,
                                                                         p_regfilial.utilizavendaporembalagem,
                                                                         P_REGITEMNOTA.PBASERCA,
                                                                         vnpvendamin,
                                                                         vnPercomAutori,
                                                                         vsmensagemautori);
      IF NVL(P_REGITEMNOTA.CODCOMBO,0) = 0
        AND NOT vbvalido_autori
       THEN

        IF (round(P_REGITEMNOTA.PVENDA,GREGPCCONSUM.NUMCASASDECVENDA) < round(P_REGPRECOS.PRECOMINIMOVENDA, GREGPCCONSUM.NUMCASASDECVENDA))
         AND vsValidaPrecoMinimo = 'S' THEN

           IF vsmensagem IS NOT NULL
            THEN
             vschar := '#';
            ELSE
             vschar := NULL;
           END IF;

            vsmensagem := vsmensagem || vschar || 'PRECO ABAIXO DO PRECO MINIMO DA ROTINA 201(Validar parâmetro 1296) :';
            vsmensagem := vsmensagem || ' PRECO DE VENDA : ' || round(P_REGITEMNOTA.PVENDA,GREGPCCONSUM.NUMCASASDECVENDA) || ';';
            vsmensagem := vsmensagem || ' PRECO TABELA  : ' || round(P_REGPRODUTO.PTABELA,GREGPCCONSUM.NUMCASASDECVENDA) || ';';
            vsmensagem := vsmensagem || ' PRECO MINIMO  : ' || round(P_REGPRECOS.PRECOMINIMOVENDA, GREGPCCONSUM.NUMCASASDECVENDA) || ';';

            P_REGNOTA.VALIDO := FALSE;

        END IF;

        IF round(P_REGITEMNOTA.PVENDA,GREGPCCONSUM.NUMCASASDECVENDA) + vFatorPrecoMinimo < VNPVENDAMIN
         THEN

         IF vsAceitaDescAcimaFlexFv = 'S' AND vsAceitaDescontoBalcaoReserva = 'S'
           THEN
            vsmensagem := vsmensagem || vschar || 'ITEM COM DESCONTO ACIMA DO PERMITIDO(Parametro 2551 = S):';
            vsmensagem := vsmensagem || ' PRECO DE VENDA : ' || round(P_REGITEMNOTA.PVENDA,GREGPCCONSUM.NUMCASASDECVENDA) || ';';
            vsmensagem := vsmensagem || ' PRECO TABELA  : ' || round(P_REGPRODUTO.PTABELA,GREGPCCONSUM.NUMCASASDECVENDA) || ';';
            vsmensagem := vsmensagem || ' DESCONTO MÁXIMO  : ' || VNPERMAXDESC || ';';
            vsmensagem := vsmensagem || ' PRECO MINIMO  : ' || VNPVENDAMIN || '.';
         END IF;

         IF vsAceitaDescAcimaFlexFv <> 'S' THEN

             IF vsmensagem IS NOT NULL
              THEN
               vschar := '#';
              ELSE
               vschar := NULL;
             END IF;

              vsmensagem := vsmensagem || vschar || 'PRECO ABAIXO DO MINIMO PERMITIDO:';
              vsmensagem := vsmensagem || ' PRECO DE VENDA : ' || round(P_REGITEMNOTA.PVENDA,GREGPCCONSUM.NUMCASASDECVENDA) || ';';
              vsmensagem := vsmensagem || ' PRECO TABELA  : ' || round(P_REGPRODUTO.PTABELA,GREGPCCONSUM.NUMCASASDECVENDA) || ';';
              vsmensagem := vsmensagem || ' DESCONTO MÁXIMO  : ' || VNPERMAXDESC || ';';
              vsmensagem := vsmensagem || ' PRECO MINIMO  : ' || VNPVENDAMIN || '.';

              P_REGNOTA.VALIDO := FALSE;

         END IF;

        END IF;
      END IF;

    IF P_REGITEMNOTA.ST > 0 THEN

    BEGIN
      SELECT VALORSEMIMPOSTO
        INTO VNVLPVENDASEMIMPOSTO
        FROM TABLE(PKG_TRIBUTACAO.CALCULAR_PVENDA_SEM_IMPOSTO(P_REGNOTA.CODFILIAL,
                                                              P_REGNOTA.CODFILIALNF,
                                                              VnCodfilialretira,
                                                              P_REGNOTA.CODCLI,
                                                              P_REGNOTA.CODPLPAG,
                                                              P_REGITEMNOTA.CODPROD,
                                                              P_REGITEMNOTA.CODAUXILIAR,
                                                              P_REGNOTA.CONDVENDA,
                                                              'N',
                                                              P_REGITEMNOTA.ST,
                                                              0,
                                                              P_REGPRODUTO.PTABELA,
                                                              'N',
                                                              'S',
                                                              vsItemTV1BNF,
                                                              VSMENSAGEMPRECOFIXO,
                                                              'F',
                                                              'N',
                                                              'N',
                                                              'N',
                                                              'N',
                                                              0,
                                                              'N',
                                                              'I',
                                                              0,
                                                              0,
                                                              'N',
                                                              'N',
                                                              'N',
                                                              0));
    EXCEPTION
      WHEN OTHERS THEN
        IF VSMENSAGEM IS NOT NULL THEN
          VSCHAR := '#';
        ELSE
          VSCHAR := NULL;
        END IF;
        VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
                                'ERRO AO BUSCAR VALOR SEM IMPOSTO PTABELA DO PRODUTO;' ||
                                P_REGITEMNOTA.CODPROD || SQLCODE || '-' ||
                                SQLERRM || ';';
        P_REGITEMNOTA.VALIDO := FALSE;
        END;

        BEGIN
          SELECT VALORIPI
            INTO P_REGITEMNOTA.VLIPIPTABELA
            FROM TABLE(PKG_TRIBUTACAO.CALCULAR_IPI(P_REGNOTA.CODFILIAL,
                                                   P_REGNOTA.CODFILIALNF,
                                                   VnCodfilialretira,
                                                   P_REGNOTA.CODCLI,
                                                   P_REGITEMNOTA.CODPROD,
                                                   P_REGITEMNOTA.CODAUXILIAR,
                                                   P_REGNOTA.CONDVENDA,
                                                   'N',
                                                   VNVLPVENDASEMIMPOSTO,
                                                   'N',
                                                   0,
                                                   'N', --transferencia
                                                   'N', --transferenciaVirtual
                                                   'N',
                                                   'F',
                                                   0,
                                                   'I',
                                                    0,
                                                   'S',
                                                   'N'));
        EXCEPTION
          WHEN OTHERS THEN
            IF VSMENSAGEM IS NOT NULL THEN
              VSCHAR := '#';
            ELSE
              VSCHAR := NULL;
            END IF;
            VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
                                    'ERRO AO BUSCAR VALOR IPI PTABELA DO PRODUTO;' ||
                                    P_REGITEMNOTA.CODPROD || SQLCODE || '-' ||
                                    SQLERRM || ';';
            P_REGITEMNOTA.VALIDO := FALSE;

        END;

        BEGIN
          SELECT ST
            INTO P_REGITEMNOTA.STPTABELA
            FROM TABLE(pkg_tributacao.calcular_st(P_REGNOTA.CODFILIAL,
                                                  P_REGNOTA.CODFILIALNF,
                                                  VnCodfilialretira,
                                                  P_REGNOTA.CODCLI,
                                                  P_REGNOTA.CODPLPAG,
                                                  P_REGITEMNOTA.CODPROD,
                                                  P_REGITEMNOTA.CODAUXILIAR,
                                                  P_REGNOTA.CONDVENDA,
                                                  'N',
                                                  VNVLPVENDASEMIMPOSTO,
                                                  0,
                                                  vsItemTV1BNF,
                                                  0,
                                                  0,
                                                  0,
                                                  NULL,
                                                  'S',
                                                  'N',
                                                  'F',
                                                  'N',
                                                  VSMENSAGEMPRECOFIXO,
                                                  'N',
                                                  0,
                                                  'N',
                                                  'I',
                                                  0,
                                                  0,
                                                  'N',
                                                  'N',
                                                  'N',
                                                  'N',
                                                  0));
        EXCEPTION
          WHEN OTHERS THEN
            IF VSMENSAGEM IS NOT NULL THEN
              VSCHAR := '#';
            ELSE
              VSCHAR := NULL;
            END IF;
            VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
                                    'ERRO AO BUSCAR VALOR ST TABELA DO PRODUTO;' ||
                                    P_REGITEMNOTA.CODPROD || SQLCODE || '-' ||
                                    SQLERRM || ';';
            P_REGITEMNOTA.VALIDO := FALSE;

        END;

      END IF;

			--tarefa 177937
			IF (P_REGNOTA.CODCOB = 'BNF') OR (P_REGITEMNOTA.BONIFIC IN('F', 'S')) THEN

				/*  select tipoprazo
        into vstipoprazo
        from pcplpag p
        where p.codplpag = p_regnota.codplpag;

        if vstipoprazo = 'B' then*/

				IF P_REGNOTA.BONIFICALTDEBCREDRCA = 'N' THEN

					P_REGITEMNOTA.PBASERCA := P_REGITEMNOTA.PVENDA;
				END IF;

				-- end if;

			ELSIF P_REGNOTA.CODCOB = 'BNFT' THEN
				P_REGITEMNOTA.PBASERCA := P_REGITEMNOTA.PVENDA;

			END IF;

		END IF;

		-- registra log
		IF (VSMENSAGEM IS NOT NULL) THEN
			PROC_REGISTRALOG(P_REGNOTA.NUMPED,
											 P_REGNOTA.NUMPEDRCA,
											 P_REGITEMNOTA.CODPROD,
											 P_REGITEMNOTA.CODAUXILIAR,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 P_REGITEMNOTA.CODUSUR,
											 NULL,
											 P_REGITEMNOTA.CANCELADA,
											 '12',
											 VSMENSAGEM,
											 NULL);
		END IF;

  P_REGITEMNOTA.PBASERCA := round(P_REGITEMNOTA.PBASERCA,GREGPCCONSUM.NUMCASASDECVENDA);
		--   commit;
	EXCEPTION
		WHEN OTHERS THEN
			P_REGITEMNOTA.VALIDO := FALSE;
			PROC_REGISTRALOG(P_REGNOTA.NUMPED,
											 P_REGNOTA.NUMPEDRCA,
											 P_REGITEMNOTA.CODPROD,
											 P_REGITEMNOTA.CODAUXILIAR,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 P_REGITEMNOTA.CODUSUR,
											 NULL,
											 P_REGITEMNOTA.CANCELADA,
											 '12',
											 SQLCODE || '-' || SQLERRM,
											 NULL);
	END PROC_VALIDARITEMNOTA;

	PROCEDURE PROC_VALIDARITEMNOTATROCA(P_REGITEMNOTA   IN OUT T_ITEMNOTA,
																			P_REGNOTA       IN OUT T_NOTA,
																			P_REGCLIENTE    IN T_CLIENTEPEDIDO,
																			P_REGRCA        IN T_RCA,
																			P_REGREGIAO     IN T_REGIAOCLIENTE,
																			P_REGPLPAG      IN T_PLANODEPAGAMENTO,
																			P_REGFILIAL     IN T_FILIAL,
																			P_REGPRECOTROCA OUT T_PRECOTROCA,
																			VSCODDISTRIB    IN PCPRODUT.CODDISTRIB%TYPE) IS

		VICONTADOR              NUMBER;
		VSMENSAGEM              VARCHAR2(32767);
		VSMENSAGEMPOLITICA      VARCHAR2(32767);
		VSCHAR                  VARCHAR2(1) DEFAULT '#';
		VNPERMAXDESC            NUMBER;
		VNPVENDAMIN             NUMBER;
		VNPVENDAMAX             NUMBER;
		VBEXISTEPOLITICA        BOOLEAN;
		VNPERCDESCQUANT         PCDESCQUANT.PERCDESC%TYPE;
		VNPERCDESCPOLITICA      PCDESCONTO.PERCDESC%TYPE;
		VSBASECREDDEBRCA        PCDESCONTO.BASECREDDEBRCA%TYPE;
		VNDESCONTO              NUMBER;
		VNNRAUTORIZACAO         PCAUTORI.NRAUTORIZACAO%TYPE;
		VNPERCDESCAUTOR         PCAUTORI.PERCDESCAUTOR%TYPE;
		VNPVENDAATUAL           PCAUTORI.PVENDAATUAL%TYPE;
		VNPVENDA_AUTORI         NUMBER;
		VBVALIDOPRECOFIXO       BOOLEAN := TRUE;
		VNPRECOFIXO             NUMBER;
		VNPERDESCATIV           NUMBER;
		VNPTABELA_ANT           NUMBER;
		VNPPOLITICA             NUMBER;
		VNPTABELADESCQUANT      NUMBER;
		VSMENSAGEMDESCQUANT     VARCHAR2(32767);
		VDDTFIM                 DATE;
		VBVALIDODESCQUANT       BOOLEAN := FALSE;
		VSMENSAGEMPRECOFIXO     VARCHAR2(32767);
		VSBASECREDDEBRCA_AUTORI PCAUTORI.BASECREDDEBRCA%TYPE;

		VNPERMAXVENDA                NUMBER;
		VSMENSAGEMPOLITICA_ACRES     VARCHAR2(32767);
		VBEXISTEPOLITICA_ACRES       BOOLEAN;
		VNPERCDESCPOLITICA_ACRES     PCDESCONTO.PERCDESC%TYPE;
		VSCREDITASOBREPTABELA        PCDESCQUANT.CREDITASOBREPTABELA%TYPE;
		VNPERCAUX                    NUMBER;
		VNPERCQUANTFLEX              NUMBER;
		VSCREDITASOBREPOLITICA       PCDESCONTO.CREDITASOBREPOLITICA%TYPE;
		VNPERCDESCPOLITICA_ACRES_AUX NUMBER;

		VNCODST PCTRIBUT.CODST%TYPE;

		VSBASECREDDEBRCA_QUANT     PCDESCQUANT.BASECREDDEBRCA%TYPE;
		VNPTABELAAUX               PCPEDI.PTABELA%TYPE;
		VNPERCBASERCA_QUANT        PCDESCQUANT.PERCDESC%TYPE;
		VSPRIORITARIA_AUX          PCDESCQUANT.PRIORITARIA%TYPE;
		VSQUESTIONAPRIORITARIA_AUX PCDESCQUANT.QUESTIONAUSOPRIORITARIA%TYPE;
		VSALTERAPTABELA            PCDESCONTO.ALTERAPTABELA%TYPE;
		VNPERCPBASERCA             PCDESCONTO.PERCDESC%TYPE;

    VSPODECOMPRAR              VARCHAR2(1);
    VSMSGTEMP                  VARCHAR2(4000);
    VNQTDTEMP                  NUMBER(14,4);

		VNQTVENDTV13 NUMBER(18, 6);
		VNQTVENDTV14 NUMBER(18, 6);

		VSTIPOPRAZO PCPLPAG.TIPOPRAZO%TYPE;
		VNQTINDENIZ NUMBER;
		VSIMPORTADO PCINDCFV.IMPORTADO%TYPE;
		VNNUMPEDRCA PCINDCFV.NUMPEDRCA%TYPE;

	BEGIN

		VSMENSAGEM := NULL;

		IF (P_REGITEMNOTA.CODPROD <> P_REGITEMNOTA.CODPRODTROCA) OR
			 (P_REGITEMNOTA.DTVALPRODTROCA < TRUNC(SYSDATE)) OR
			 (P_REGITEMNOTA.AVARIA = 'S') THEN

			--troca por produtos diferentes, o pedido precisa ser bonificado
			IF P_REGNOTA.CODCOB <> 'BNFT' --or p_regplpag.tipoprazo <> 'B'
			 THEN

				IF VSMENSAGEM IS NOT NULL THEN
					VSCHAR := '#';
				ELSE
					VSCHAR := NULL;
				END IF;

				VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
																'Troca por produtos diferentes,avariado ou vencido, precisa ser em um pedido bonificado;';
				P_REGITEMNOTA.VALIDO := FALSE;

			ELSE
				--buscar numero da indenizacao

				IF P_REGNOTA.NUMPEDTV5 IS NULL THEN

					P_REGNOTA.NUMPEDTV5 := P_REGNOTA.NUMPED;

				END IF;

				SELECT COUNT(*)
					INTO VICONTADOR
					FROM PCINDCFV
				 WHERE CODINDENIZ = P_REGITEMNOTA.CODINDENIZ;

				IF VICONTADOR = 0 THEN

					IF VSMENSAGEM IS NOT NULL THEN
						VSCHAR := '#';
					ELSE
						VSCHAR := NULL;
					END IF;

					VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
																	'Não encontrada indenização com o codindeniz: ' ||
																	P_REGITEMNOTA.CODINDENIZ || ';';
					P_REGITEMNOTA.VALIDO := FALSE;

				ELSE

					BEGIN
						SELECT NUMINDENIZ, IMPORTADO, NUMPEDRCA
							INTO P_REGITEMNOTA.NUMINDENIZ, VSIMPORTADO, VNNUMPEDRCA
							FROM PCINDCFV
						 WHERE CODINDENIZ = P_REGITEMNOTA.CODINDENIZ
							 AND ROWNUM = 1;
					EXCEPTION
						WHEN OTHERS THEN

							P_REGITEMNOTA.NUMINDENIZ := NULL;

							IF VSMENSAGEM IS NOT NULL THEN
								VSCHAR := '#';
							ELSE
								VSCHAR := NULL;
							END IF;

							VSMENSAGEM := VSMENSAGEM || VSCHAR ||
														'Erro ao selecionar indenização com o codindeniz: ' ||
														P_REGITEMNOTA.CODINDENIZ || ';';
							-- p_regitemnota.valido := false;

					END;

					IF VNNUMPEDRCA <> P_REGNOTA.NUMPEDRCA THEN

						IF VSMENSAGEM IS NOT NULL THEN
							VSCHAR := '#';
						ELSE
							VSCHAR := NULL;
						END IF;

						VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
																		'Indenizacao esta relacionada a outro pedido ;';
						P_REGITEMNOTA.VALIDO := FALSE;

					ELSE

						IF P_REGITEMNOTA.NUMINDENIZ IS NOT NULL THEN

							SELECT COUNT(*)
								INTO VICONTADOR
								FROM PCINDIFV I
							 WHERE I.CODINDENIZ = P_REGITEMNOTA.NUMINDENIZ
								 AND I.CODPROD = P_REGITEMNOTA.CODPRODTROCA;

							IF VICONTADOR = 0 THEN

								IF VSMENSAGEM IS NOT NULL THEN
									VSCHAR := '#';
								ELSE
									VSCHAR := NULL;
								END IF;

								VSMENSAGEM := VSMENSAGEM || VSCHAR ||
															'Não encontrado produtos na indenização com o codindeniz: ' ||
															P_REGITEMNOTA.CODINDENIZ || ';';
								-- p_regitemnota.valido := false;

							ELSE

								IF NVL(VSIMPORTADO, 1) = 1 THEN

									IF VSMENSAGEM IS NOT NULL THEN
										VSCHAR := '#';
									ELSE
										VSCHAR := NULL;
									END IF;

									VSMENSAGEM := VSMENSAGEM || VSCHAR ||
																'Indenizacao ainda não foi importada ! ;';

								ELSIF NVL(VSIMPORTADO, 1) = 3 THEN

									IF VSMENSAGEM IS NOT NULL THEN
										VSCHAR := '#';
									ELSE
										VSCHAR := NULL;
									END IF;

									VSMENSAGEM := VSMENSAGEM || VSCHAR ||
																'Indenizacao foi rejeitada ! ;';

								ELSIF NVL(VSIMPORTADO, 1) = 2 THEN

									SELECT I.QT
										INTO VNQTINDENIZ
										FROM PCINDIFV I
									 WHERE I.CODINDENIZ = P_REGITEMNOTA.NUMINDENIZ
										 AND I.CODPROD = P_REGITEMNOTA.CODPRODTROCA;

									IF VNQTINDENIZ < P_REGITEMNOTA.QTTROCA THEN

										IF VSMENSAGEM IS NOT NULL THEN
											VSCHAR := '#';
										ELSE
											VSCHAR := NULL;
										END IF;

										VSMENSAGEM := VSMENSAGEM || VSCHAR ||
																	'Quantidade indenizada é menor que quantidade de troca ;';
										--p_regitemnota.valido := false;

									END IF;

								END IF;

							END IF;
						END IF;

					END IF;

				END IF;

			END IF;

		END IF;

		-- verificar se o produto esta cadastrado
		SELECT COUNT(*)
			INTO VICONTADOR
			FROM PCPRODUT
		 WHERE CODPROD = P_REGITEMNOTA.CODPRODTROCA;

		IF VICONTADOR = 0 THEN
			IF VSMENSAGEM IS NOT NULL THEN
				VSCHAR := '#';
			ELSE
				VSCHAR := NULL;
			END IF;

			VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
															'Produto de Troca nao cadastrado;';
			P_REGITEMNOTA.VALIDO := FALSE;
		END IF;

		-- Se produto recolhido tiver avaria ou estiver vencido, ele não precisa estar no carregamento

		IF P_REGITEMNOTA.DTVALPRODTROCA >= TRUNC(SYSDATE) AND
			 P_REGITEMNOTA.AVARIA = 'N' THEN

			--verifica se item existe no carregamento
			SELECT COUNT(*)
				INTO VICONTADOR
				FROM PCPEDC P, PCPEDI I
			 WHERE /*P.CODUSUR = P_REGNOTA.CODUSUR
				 AND */P.NUMCAR = P_REGNOTA.NUMCARMANIF
				 AND P.CONDVENDA = 13
				 AND P.NUMPED = I.NUMPED
				 AND I.CODPROD = P_REGITEMNOTA.CODPRODTROCA
				 AND ((I.CODAUXILIAR =
						 NVL(P_REGITEMNOTA.CODAUXILIARTROCA, I.CODAUXILIAR)) OR
						 (I.CODAUXILIAR IS NULL));

			IF VICONTADOR = 0 THEN
				IF VSMENSAGEM IS NOT NULL THEN
					VSCHAR := '#';
				ELSE
					VSCHAR := NULL;
				END IF;

				VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
																'Produto Troca  nao encontrado no carregamento;';
				P_REGITEMNOTA.VALIDO := FALSE;

			ELSE

				SELECT SUM(QT)
					INTO VNQTVENDTV13
					FROM PCPEDC P, PCPEDI I
				 WHERE /*P.CODUSUR = P_REGNOTA.CODUSUR
					 AND */P.NUMCAR = P_REGNOTA.NUMCARMANIF
					 AND P.CONDVENDA = 13
					 AND P.NUMPED = I.NUMPED
					 AND I.CODPROD = P_REGITEMNOTA.CODPRODTROCA
					 AND ((I.CODAUXILIAR =
							 NVL(P_REGITEMNOTA.CODAUXILIARTROCA, I.CODAUXILIAR)) OR
							 (I.CODAUXILIAR IS NULL))
					 AND P.POSICAO <> 'C';

				--verifica se já tem algum outro pedido tv14 com este produto
				BEGIN

					SELECT SUM(QT)
						INTO VNQTVENDTV14
						FROM PCPEDC P, PCPEDI I
					 WHERE /*P.CODUSUR = P_REGNOTA.CODUSUR
						 AND */P.NUMCAR = P_REGNOTA.NUMCARMANIF
						 AND P.CONDVENDA = 14
						 AND P.NUMPED = I.NUMPED
						 AND I.CODPROD = P_REGITEMNOTA.CODPRODTROCA
						 AND ((I.CODAUXILIAR =
								 NVL(P_REGITEMNOTA.CODAUXILIARTROCA, I.CODAUXILIAR)) OR
								 (I.CODAUXILIAR IS NULL))
						 AND P.POSICAO <> 'C';

				EXCEPTION
					WHEN OTHERS THEN
						VNQTVENDTV14 := 0;
				END;

			END IF;

			IF NVL(P_REGNOTA.CANCELADA, 'N') = 'N' THEN
				--tarefa 159152
				IF NVL(VNQTVENDTV14, 0) + NVL(P_REGITEMNOTA.QTTROCA, 0) +
					 NVL(P_REGITEMNOTA.QT, 0) > NVL(VNQTVENDTV13, 0) THEN

					IF VSMENSAGEM IS NOT NULL THEN
						VSCHAR := '#';
					ELSE
						VSCHAR := NULL;
					END IF;
					VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
																	'QUANTIDADE SOLICITADA DE TROCA ULTRAPASSA A QUANTIDADE EXISTENTE NO CARREGAMENTO;' ||
																	'QUANTIDADE ATENDIDA : ' ||
																	NVL(VNQTVENDTV13, 0);
					P_REGITEMNOTA.VALIDO := FALSE;

				END IF;

			END IF;

		END IF;

    --HIS.02651.2015
    IF (P_REGNOTA.VALIDO) AND
       (p_REGFILIAL.VALIDARALVARAVENDA = 'S')
    THEN
      BEGIN
        PRC_MED_VALIDA_CONTROLE_VENDA('I',
                                      P_REGNOTA.CODCLI,
                                      P_REGCLIENTE.TIPOFJ,
                                      P_REGITEMNOTA.CODPROD,
                                      P_REGITEMNOTA.QT,
                                      P_REGNOTA.NUMPED,
                                      P_REGITEMNOTA.NUMSEQ,
                                      VSPODECOMPRAR,
                                      VSMSGTEMP,
                                      VNQTDTEMP);

        IF VSPODECOMPRAR = 'N' THEN
          VSMENSAGEM  := VSMENSAGEM || VSCHAR || 'PRODUTO COM CONTROLE DE VENDA' ||
                         VSCHAR || VSMSGTEMP;
          P_REGNOTA.VALIDO := FALSE;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          VSMENSAGEM  := VSMENSAGEM || VSCHAR || 'ERRO AO VALIDAR CONTROLE DE VENDA!' ||
          SQLCODE || '-' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ';';
          P_REGNOTA.VALIDO := FALSE;
      END;
    END IF;
    -- FIM HIS.02651.2015

		IF P_REGITEMNOTA.VALIDO = TRUE THEN

			-- busca as informacoes da tabela de preco.

			IF P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM = 'S' THEN

				IF P_REGITEMNOTA.CODAUXILIARTROCA = 0 OR
					 P_REGITEMNOTA.CODAUXILIARTROCA IS NULL THEN

					IF VSMENSAGEM IS NOT NULL THEN
						VSCHAR := '#';
					ELSE
						VSCHAR := NULL;
					END IF;

					VSMENSAGEM := VSMENSAGEM || VSCHAR ||
												'CODAUXILIAR TROCA INVALIDO' || ';';

					P_REGITEMNOTA.VALIDO := FALSE;

				ELSE

					SELECT COUNT(*)
						INTO VICONTADOR
						FROM PCEMBALAGEM P
					 WHERE CODPROD = P_REGITEMNOTA.CODPRODTROCA
						 AND CODFILIAL = P_REGNOTA.CODFILIAL
						 AND CODAUXILIAR = P_REGITEMNOTA.CODAUXILIARTROCA;

					IF VICONTADOR = 0 THEN

						IF VSMENSAGEM IS NOT NULL THEN
							VSCHAR := '#';
						ELSE
							VSCHAR := NULL;
						END IF;

						VSMENSAGEM := VSMENSAGEM || VSCHAR ||
													'PRODUTO TROCA NAO ENCONTRADO COM ESTE CODAUXILIAR' || ';';

						P_REGITEMNOTA.VALIDO := FALSE;

					END IF;

				END IF;

			END IF;

			IF P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM = 'S' THEN  --Primeira validação

				--tributacao por estado
				IF NVL(GREGPCCONSUM.USATRIBUTACAOPORUF, 'N') = 'S' THEN

					SELECT COUNT(*)
						INTO VICONTADOR
						FROM PCTABTRIB P
					 WHERE P.CODPROD = P_REGITEMNOTA.CODPRODTROCA
						 AND P.CODFILIALNF = P_REGNOTA.CODFILIALNF
						 AND P.UFDESTINO = P_REGCLIENTE.ESTENT;

					IF VICONTADOR = 0 THEN
						IF VSMENSAGEM IS NOT NULL THEN
							VSCHAR := '#';
						ELSE
							VSCHAR := NULL;
						END IF;
						VSMENSAGEM := VSMENSAGEM || VSCHAR ||
													'NÃO ENCONTRADA TRIBUTAÇÃO POR ESTADO;';

						P_REGITEMNOTA.VALIDO := FALSE;

					ELSE

						SELECT P.CODST
							INTO VNCODST
							FROM PCTABTRIB P
						 WHERE P.CODPROD = P_REGITEMNOTA.CODPRODTROCA
							 AND P.CODFILIALNF = P_REGNOTA.CODFILIALNF
							 AND P.UFDESTINO = P_REGCLIENTE.ESTENT
							 AND ROWNUM = 1;

						-- busca as informacoes da tabela de preco.

						BEGIN
							SELECT (NVL(PCTABPR.PVENDA, 0) *
										 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
														 0,
														 1,
														 NVL(PCEMBALAGEM.FATORPRECO, 1))),
										 (NVL(PCTABPR.PVENDA1, 0) *
										 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
														 0,
														 1,
														 NVL(PCEMBALAGEM.FATORPRECO, 1))),
										 (NVL(PCTABPR.PVENDA2, 0) *
										 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
														 0,
														 1,
														 NVL(PCEMBALAGEM.FATORPRECO, 1))),
										 (NVL(PCTABPR.PVENDA3, 0) *
										 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
														 0,
														 1,
														 NVL(PCEMBALAGEM.FATORPRECO, 1))),
										 (NVL(PCTABPR.PVENDA4, 0) *
										 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
														 0,
														 1,
														 NVL(PCEMBALAGEM.FATORPRECO, 1))),
										 (NVL(PCTABPR.PVENDA5, 0) *
										 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
														 0,
														 1,
														 NVL(PCEMBALAGEM.FATORPRECO, 1))),
										 (NVL(PCTABPR.PVENDA6, 0) *
										 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
														 0,
														 1,
														 NVL(PCEMBALAGEM.FATORPRECO, 1))),
										 (NVL(PCTABPR.PVENDA7, 0) *
										 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
														 0,
														 1,
														 NVL(PCEMBALAGEM.FATORPRECO, 1))),
										 NVL(PCEMBALAGEM.QTUNIT, 1),
										 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
														0,
														1,
														NVL(PCEMBALAGEM.FATORPRECO, 1)),
										 NVL(PCEMBALAGEM.QTMINIMAATACADO, 0),
										 (NVL(PCEMBALAGEM.PVENDAATAC, 0) *
										 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
														 0,
														 1,
														 NVL(PCEMBALAGEM.FATORPRECO, 1))),
										 (NVL(PCEMBALAGEM.PVENDA, 0) *
										 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
														 0,
														 1,
														 NVL(PCEMBALAGEM.FATORPRECO, 1))),
										 (NVL(PCEMBALAGEM.POFERTA, 0) *
										 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
														 0,
														 1,
														 NVL(PCEMBALAGEM.FATORPRECO, 1))),
										 PCEMBALAGEM.DTOFERTAINI,
										 PCEMBALAGEM.DTOFERTAFIM,
										 PCEMBALAGEM.DTOFERTAATACINI,
										 PCEMBALAGEM.DTOFERTAATACFIM,
										 NVL(PCEMBALAGEM.POFERTAATAC, 0)
								INTO P_REGPRECOTROCA
								FROM PCTABPR, PCTRIBUT, PCEST, PCEMBALAGEM
							 WHERE PCTRIBUT.CODST = VNCODST
								 AND PCTABPR.CODPROD = P_REGITEMNOTA.CODPRODTROCA
								 AND PCEST.CODPROD = P_REGITEMNOTA.CODPRODTROCA
								 AND PCTABPR.NUMREGIAO = P_REGREGIAO.NUMREGIAO
								 AND PCEST.CODFILIAL = P_REGNOTA.CODFILIAL
								 AND PCEMBALAGEM.CODPROD = P_REGITEMNOTA.CODPRODTROCA
								 AND PCEMBALAGEM.CODAUXILIAR =
										 P_REGITEMNOTA.CODAUXILIARTROCA
								 AND PCEMBALAGEM.CODFILIAL = P_REGNOTA.CODFILIAL;
						EXCEPTION
							WHEN OTHERS THEN
								IF VSMENSAGEM IS NOT NULL THEN
									VSCHAR := '#';
								ELSE
									VSCHAR := NULL;
								END IF;
								VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
																				'ERRO AO BUSCAR PRECO DO PRODUTO TROCA#;' ||
																				SQLCODE || '-' || SQLERRM || ';';
								P_REGITEMNOTA.VALIDO := FALSE;

						END;

						--                              p_regitemnota.pvendatroca := round(p_regitemnota.pvendatroca / p_regprecos.qtunit, gregpcconsum.numcasasdecvenda);

						P_REGITEMNOTA.QTTROCA := P_REGITEMNOTA.QTTROCA *
																		 P_REGPRECOTROCA.QTUNIT;

					END IF;

					--não usa tributação por estado
				ELSE
					-- busca as informacoes da tabela de preco.
					BEGIN
						SELECT (NVL(PCTABPR.PVENDA, 0) *
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													 0,
													 1,
													 NVL(PCEMBALAGEM.FATORPRECO, 1))),
									 (NVL(PCTABPR.PVENDA1, 0) *
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													 0,
													 1,
													 NVL(PCEMBALAGEM.FATORPRECO, 1))),
									 (NVL(PCTABPR.PVENDA2, 0) *
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													 0,
													 1,
													 NVL(PCEMBALAGEM.FATORPRECO, 1))),
									 (NVL(PCTABPR.PVENDA3, 0) *
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													 0,
													 1,
													 NVL(PCEMBALAGEM.FATORPRECO, 1))),
									 (NVL(PCTABPR.PVENDA4, 0) *
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													 0,
													 1,
													 NVL(PCEMBALAGEM.FATORPRECO, 1))),
									 (NVL(PCTABPR.PVENDA5, 0) *
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													 0,
													 1,
													 NVL(PCEMBALAGEM.FATORPRECO, 1))),
									 (NVL(PCTABPR.PVENDA6, 0) *
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													 0,
													 1,
													 NVL(PCEMBALAGEM.FATORPRECO, 1))),
									 (NVL(PCTABPR.PVENDA7, 0) *
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													 0,
													 1,
													 NVL(PCEMBALAGEM.FATORPRECO, 1))),
									 NVL(PCEMBALAGEM.QTUNIT, 1),
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													0,
													1,
													NVL(PCEMBALAGEM.FATORPRECO, 1)),
									 NVL(PCEMBALAGEM.QTMINIMAATACADO, 0),
									 (NVL(PCEMBALAGEM.PVENDAATAC, 0) *
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													 0,
													 1,
													 NVL(PCEMBALAGEM.FATORPRECO, 1))),
									 (NVL(PCEMBALAGEM.PVENDA, 0) *
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													 0,
													 1,
													 NVL(PCEMBALAGEM.FATORPRECO, 1))),
									 (NVL(PCEMBALAGEM.POFERTA, 0) *
									 DECODE(NVL(PCEMBALAGEM.FATORPRECO, 1),
													 0,
													 1,
													 NVL(PCEMBALAGEM.FATORPRECO, 1))),
									 PCEMBALAGEM.DTOFERTAINI,
									 PCEMBALAGEM.DTOFERTAFIM,
									 PCEMBALAGEM.DTOFERTAATACINI,
									 PCEMBALAGEM.DTOFERTAATACFIM,
									 NVL(PCEMBALAGEM.POFERTAATAC, 0)
							INTO P_REGPRECOTROCA
							FROM PCTABPR, PCTRIBUT, PCEST, PCEMBALAGEM
						 WHERE PCTABPR.CODST = PCTRIBUT.CODST
							 AND PCTABPR.CODPROD = P_REGITEMNOTA.CODPRODTROCA
							 AND PCEST.CODPROD = P_REGITEMNOTA.CODPRODTROCA
							 AND PCTABPR.NUMREGIAO = P_REGREGIAO.NUMREGIAO
							 AND PCEST.CODFILIAL = P_REGNOTA.CODFILIAL
							 AND PCEMBALAGEM.CODPROD = P_REGITEMNOTA.CODPRODTROCA
							 AND PCEMBALAGEM.CODAUXILIAR = P_REGITEMNOTA.CODAUXILIARTROCA
							 AND PCEMBALAGEM.CODFILIAL = P_REGNOTA.CODFILIAL;

					EXCEPTION
						WHEN OTHERS THEN
							IF VSMENSAGEM IS NOT NULL THEN
								VSCHAR := '#';
							ELSE
								VSCHAR := NULL;
							END IF;
							VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
																			'ERRO AO BUSCAR PRECO DO PRODUTO TROCA#;' ||
																			SQLCODE || '-' || SQLERRM || ';';
							P_REGITEMNOTA.VALIDO := FALSE;

					END;

					--                            p_regitemnota.pvendatroca := round(p_regitemnota.pvendatroca / p_regprecos.qtunit, gregpcconsum.numcasasdecvenda);

					P_REGITEMNOTA.QTTROCA := P_REGITEMNOTA.QTTROCA *
																	 P_REGPRECOTROCA.QTUNIT;

				END IF;

				--não usa venda por embalagem
			ELSE

				--tributacao por estado
				IF NVL(GREGPCCONSUM.USATRIBUTACAOPORUF, 'N') = 'S' THEN

					SELECT COUNT(*)
						INTO VICONTADOR
						FROM PCTABTRIB P
					 WHERE P.CODPROD = P_REGITEMNOTA.CODPRODTROCA
						 AND P.CODFILIALNF = P_REGNOTA.CODFILIALNF
						 AND P.UFDESTINO = P_REGCLIENTE.ESTENT;

					IF VICONTADOR = 0 THEN
						IF VSMENSAGEM IS NOT NULL THEN
							VSCHAR := '#';
						ELSE
							VSCHAR := NULL;
						END IF;
						VSMENSAGEM := VSMENSAGEM || VSCHAR ||
													'NÃO ENCONTRADA TRIBUTAÇÃO POR ESTADO;';

						P_REGITEMNOTA.VALIDO := FALSE;

					ELSE

						SELECT P.CODST
							INTO VNCODST
							FROM PCTABTRIB P
						 WHERE P.CODPROD = P_REGITEMNOTA.CODPRODTROCA
							 AND P.CODFILIALNF = P_REGNOTA.CODFILIALNF
							 AND P.UFDESTINO = P_REGCLIENTE.ESTENT
							 AND ROWNUM = 1;

						-- busca as informacoes da tabela de preco.

						BEGIN
							SELECT NVL(PCTABPR.PVENDA, 0),
										 NVL(PCTABPR.PVENDA1, 0),
										 NVL(PCTABPR.PVENDA2, 0),
										 NVL(PCTABPR.PVENDA3, 0),
										 NVL(PCTABPR.PVENDA4, 0),
										 NVL(PCTABPR.PVENDA5, 0),
										 NVL(PCTABPR.PVENDA6, 0),
										 NVL(PCTABPR.PVENDA7, 0),
										 1,
										 1,
										 0,
										 0,
										 0,
										 0,
										 NULL,
										 NULL,
										 NULL,
										 NULL,
										 0
								INTO P_REGPRECOTROCA
								FROM PCTABPR, PCTRIBUT, PCEST
							 WHERE PCTRIBUT.CODST = VNCODST
								 AND PCTABPR.CODPROD = P_REGITEMNOTA.CODPRODTROCA
								 AND PCEST.CODPROD = P_REGITEMNOTA.CODPRODTROCA
								 AND PCTABPR.NUMREGIAO = P_REGREGIAO.NUMREGIAO
								 AND PCEST.CODFILIAL = P_REGNOTA.CODFILIAL;
						EXCEPTION
							WHEN OTHERS THEN
								IF VSMENSAGEM IS NOT NULL THEN
									VSCHAR := '#';
								ELSE
									VSCHAR := NULL;
								END IF;
								VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
																				'ERRO AO BUSCAR PRECO DO PRODUTO TROCA#;' ||
																				SQLCODE || '-' || SQLERRM || ';';
								P_REGITEMNOTA.VALIDO := FALSE;

						END;

					END IF;

					--não usa tributação por estado
				ELSE
					-- busca as informacoes da tabela de preco.
					BEGIN
						SELECT NVL(PCTABPR.PVENDA, 0),
									 NVL(PCTABPR.PVENDA1, 0),
									 NVL(PCTABPR.PVENDA2, 0),
									 NVL(PCTABPR.PVENDA3, 0),
									 NVL(PCTABPR.PVENDA4, 0),
									 NVL(PCTABPR.PVENDA5, 0),
									 NVL(PCTABPR.PVENDA6, 0),
									 NVL(PCTABPR.PVENDA7, 0),
									 1,
									 1,
									 0,
									 0,
									 0,
									 0,
									 NULL,
									 NULL,
									 NULL,
									 NULL,
									 0
							INTO P_REGPRECOTROCA
							FROM PCTABPR, PCTRIBUT, PCEST
						 WHERE PCTABPR.CODST = PCTRIBUT.CODST
							 AND PCTABPR.CODPROD = P_REGITEMNOTA.CODPRODTROCA
							 AND PCEST.CODPROD = P_REGITEMNOTA.CODPRODTROCA
							 AND PCTABPR.NUMREGIAO = P_REGREGIAO.NUMREGIAO
							 AND PCEST.CODFILIAL = P_REGNOTA.CODFILIAL;
					EXCEPTION
						WHEN OTHERS THEN
							IF VSMENSAGEM IS NOT NULL THEN
								VSCHAR := '#';
							ELSE
								VSCHAR := NULL;
							END IF;
							VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
																			'ERRO AO BUSCAR PRECO DO PRODUTO TROCA#;' ||
																			SQLCODE || '-' || SQLERRM || ';';
							P_REGITEMNOTA.VALIDO := FALSE;

					END;

				END IF;

			END IF;

			IF P_REGFILIAL.PRECOPOREMBALAGEM = 'S' AND
				 P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM = 'S' THEN

				--Varejo
				IF P_REGFILIAL.TIPOPRECIFICACAO <> 'A' THEN
					IF P_REGPRECOTROCA.QTMINIMAATACADO > 1 THEN
						IF P_REGITEMNOTA.QTTROCA >= P_REGPRECOTROCA.QTMINIMAATACADO THEN
							P_REGITEMNOTA.PTABELATROCA := P_REGPRECOTROCA.PVENDAATAC /
																						P_REGPRECOTROCA.QTUNIT;
						ELSE
							P_REGITEMNOTA.PTABELATROCA := P_REGPRECOTROCA.PVENDAEMB /
																						P_REGPRECOTROCA.QTUNIT;
						END IF;
					ELSE
						P_REGITEMNOTA.PTABELATROCA := P_REGPRECOTROCA.PVENDAEMB /
																					P_REGPRECOTROCA.QTUNIT;
					END IF;
					--Atacado
				ELSE
					P_REGITEMNOTA.PTABELATROCA := P_REGPRECOTROCA.PVENDAATAC /
																				P_REGPRECOTROCA.QTUNIT;

				END IF;

				--tarefa 70944 verificar poferta como preco minimo
				IF (P_REGPRECOTROCA.POFERTA > 0) AND
					 TRUNC(SYSDATE) BETWEEN P_REGPRECOTROCA.DTOFERTAINI AND
					 P_REGPRECOTROCA.DTOFERTAFIM THEN

					IF P_REGITEMNOTA.QTTROCA < P_REGPRECOTROCA.QTMINIMAATACADO THEN
						P_REGITEMNOTA.PTABELATROCA := P_REGPRECOTROCA.POFERTA /
																					P_REGPRECOTROCA.QTUNIT;
					END IF;
				END IF;

				IF P_REGFILIAL.TIPOPRECIFICACAO <> 'A' THEN
					IF (P_REGPRECOTROCA.POFERTA > 0) AND
						 (TRUNC(SYSDATE) BETWEEN P_REGPRECOTROCA.DTOFERTAINI AND
						 P_REGPRECOTROCA.DTOFERTAFIM) THEN
						IF P_REGITEMNOTA.QTTROCA < P_REGPRECOTROCA.QTMINIMAATACADO THEN

							P_REGITEMNOTA.PTABELATROCA := P_REGPRECOTROCA.POFERTA /
																						P_REGPRECOTROCA.QTUNIT;
						END IF;
					END IF;
				ELSE
					IF (P_REGPRECOTROCA.POFERTAATAC > 0) AND
						 (TRUNC(SYSDATE) BETWEEN P_REGPRECOTROCA.DTOFERTAATACINI AND
						 P_REGPRECOTROCA.DTOFERTAATACFIM) THEN
						IF P_REGITEMNOTA.QTTROCA >= P_REGPRECOTROCA.QTMINIMAATACADO THEN
							P_REGITEMNOTA.PTABELATROCA := P_REGPRECOTROCA.POFERTAATAC /
																						P_REGPRECOTROCA.QTUNIT;
						END IF;
					END IF;
				END IF;

			END IF;

			-- verifica produto com preco 0 (zero)
			IF (P_REGPRECOTROCA.PVENDA <= 0) OR (P_REGPRECOTROCA.PVENDA1 <= 0) OR
				 (P_REGPRECOTROCA.PVENDA2 <= 0) OR (P_REGPRECOTROCA.PVENDA3 <= 0) OR
				 (P_REGPRECOTROCA.PVENDA4 <= 0) OR (P_REGPRECOTROCA.PVENDA5 <= 0) OR
				 (P_REGPRECOTROCA.PVENDA6 <= 0) OR (P_REGPRECOTROCA.PVENDA7 <= 0) THEN
				IF VSMENSAGEM IS NOT NULL THEN
					VSCHAR := '#';
				ELSE
					VSCHAR := NULL;
				END IF;

				VSMENSAGEM           := VSMENSAGEM || VSCHAR ||
																'Preco de tabela zerado produto Troca;';
				P_REGITEMNOTA.VALIDO := FALSE;
			END IF;

			-- tratamento com relacao ao preco e descontos
			IF P_REGITEMNOTA.VALIDO = TRUE THEN
				IF P_REGPLPAG.NUMPR = 1 THEN
					P_REGITEMNOTA.PTABELATROCA := P_REGPRECOTROCA.PVENDA1;
				ELSIF P_REGPLPAG.NUMPR = 2 THEN
					P_REGITEMNOTA.PTABELATROCA := P_REGPRECOTROCA.PVENDA2;
				ELSIF P_REGPLPAG.NUMPR = 3 THEN
					P_REGITEMNOTA.PTABELATROCA := P_REGPRECOTROCA.PVENDA3;
				ELSIF P_REGPLPAG.NUMPR = 4 THEN
					P_REGITEMNOTA.PTABELATROCA := P_REGPRECOTROCA.PVENDA4;
				ELSIF P_REGPLPAG.NUMPR = 5 THEN
					P_REGITEMNOTA.PTABELATROCA := P_REGPRECOTROCA.PVENDA5;
				ELSIF P_REGPLPAG.NUMPR = 6 THEN
					P_REGITEMNOTA.PTABELATROCA := P_REGPRECOTROCA.PVENDA6;
				ELSIF P_REGPLPAG.NUMPR = 7 THEN
					P_REGITEMNOTA.PTABELATROCA := P_REGPRECOTROCA.PVENDA7;
				END IF;

			END IF;
		END IF;

		-- registra log
		IF (VSMENSAGEM IS NOT NULL) THEN
			PROC_REGISTRALOG(P_REGNOTA.NUMPED,
											 P_REGNOTA.NUMPEDRCA,
											 P_REGITEMNOTA.CODPROD,
											 P_REGITEMNOTA.CODAUXILIAR,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 P_REGITEMNOTA.CODUSUR,
											 NULL,
											 P_REGITEMNOTA.CANCELADA,
											 '12',
											 VSMENSAGEM,
											 NULL);
		END IF;
		--   commit;
	EXCEPTION
		WHEN OTHERS THEN
			P_REGITEMNOTA.VALIDO := FALSE;
			PROC_REGISTRALOG(P_REGNOTA.NUMPED,
											 P_REGNOTA.NUMPEDRCA,
											 P_REGITEMNOTA.CODPROD,
											 P_REGITEMNOTA.CODAUXILIAR,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 P_REGITEMNOTA.CODUSUR,
											 NULL,
											 P_REGITEMNOTA.CANCELADA,
											 '12',
											 SQLCODE || '-' || SQLERRM,
											 NULL);
	END PROC_VALIDARITEMNOTATROCA;

	FUNCTION FUNC_CALCULARPERDESCITEM(P_PTABELA IN PCPEDI.PTABELA%TYPE,
																		P_PVENDA  IN PCPEDI.PVENDA%TYPE)
		RETURN NUMBER IS
		VNPERDESC NUMBER;
	BEGIN

		VNPERDESC := ((P_PTABELA - P_PVENDA) / P_PTABELA) * 100;
		VNPERDESC := ROUND(VNPERDESC, GREGPCCONSUM.NUMCASASDECVENDA);

		RETURN VNPERDESC;
	EXCEPTION
		WHEN OTHERS THEN
			RETURN 0;
	END FUNC_CALCULARPERDESCITEM;

	FUNCTION FUNC_INSERIRNOTA(P_REGNOTA          IN OUT T_NOTA,
														P_REGPLPAG         IN T_PLANODEPAGAMENTO,
														P_REGRCA           IN T_RCA,
														P_REGCLIENTE       IN T_CLIENTEPEDIDO,
														P_REGREGIAO        IN T_REGIAOCLIENTE,
														P_CONTITENSVALIDOS IN NUMBER,
														P_VLTOTPED         IN NUMBER,
														P_VLTOTTAB         IN NUMBER,
														P_TOTPESOPED       IN NUMBER,
														P_TOTVOLUMEPED     IN NUMBER,
														P_VLCUSTOCONTPED   IN NUMBER,
														P_VLCUSTOFINPED    IN NUMBER,
														P_VLCUSTOREALPED   IN NUMBER,
														P_VLCUSTOREPPED    IN NUMBER,
                            P_VLBONIFIC        IN NUMBER,
														P_CODDISTRIB       IN PCPRODUT.CODDISTRIB%TYPE,
														P_REGFILIAL        IN T_FILIAL) RETURN BOOLEAN IS
		VNPERDESCPED NUMBER;
		VICONTADOR   NUMBER;

	BEGIN
		IF P_VLTOTTAB <> 0 THEN
			VNPERDESCPED := ROUND((((P_VLTOTTAB - P_VLTOTPED) / P_VLTOTTAB) * 100),
														GREGPCCONSUM.NUMCASASDECVENDA);
		ELSE
			VNPERDESCPED := 0;
		END IF;

		IF NVL(P_REGNOTA.GERARNFE, 'N') = 'N' THEN

			-- verifica se pedido ja existe (1)
			SELECT COUNT(*)
				INTO VICONTADOR
				FROM PCPEDC
			 WHERE NUMPEDRCA = P_REGNOTA.NUMPEDRCA
				 AND CODUSUR = P_REGNOTA.CODUSUR
				 and nvl(numnotamanif, -1) = nvl(p_regnota.numnotamanif, -2)
         and nvl(seriemanif, -1) = nvl(p_regnota.seriemanif,-2)
         AND POSICAO <> 'C';

			IF VICONTADOR > 0 THEN
				PROC_REGISTRALOG(P_REGNOTA.NUMPED,
												 P_REGNOTA.NUMPEDRCA,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 P_REGNOTA.CODUSUR,
												 NULL,
												 P_REGNOTA.CANCELADA,
												 '11',
												 'Nota Fiscal ja existente 02;',
												 NULL);

				P_REGNOTA.VALIDO := FALSE;

			END IF;
		ELSE

			-- verifica se pedido ja existe (1)
			SELECT COUNT(*)
				INTO VICONTADOR
				FROM PCPEDC
			 WHERE NUMPEDRCA         = P_REGNOTA.NUMPEDRCA
				 AND CODUSUR           = P_REGNOTA.CODUSUR
         AND DTABERTURAPEDPALM = P_REGNOTA.DTABERTURAPEDPALM
         AND POSICAO <> 'C';

			IF VICONTADOR > 0 THEN
				PROC_REGISTRALOG(P_REGNOTA.NUMPED,
												 P_REGNOTA.NUMPEDRCA,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 P_REGNOTA.CODUSUR,
												 NULL,
												 P_REGNOTA.CANCELADA,
												 '11',
												 'Nota Fiscal ja existente 03;',
												 NULL);

				P_REGNOTA.VALIDO := FALSE;

			END IF;
		END IF;

		IF P_REGNOTA.VALIDO = TRUE THEN

			INSERT INTO PCPEDC
				(CODCLI, --1
				 CODCOB, --2
				 CODDISTRIB, --3
				 CODEMITENTE, --4
				 CODFILIAL, --5
				 CODFILIALNF, --6
				 CODPLPAG, --7
				 CODPRACA, --8
				 CODSUPERVISOR, --9
				 CODUSUR, --10
				 CONDVENDA, --11
				 DATA, --12
				 DTENTREGA, --13
				 HORA, --14
				 MINUTO, --15
				 NUMCAR, --16
				 NUMITENS, --17
				 NUMPED, --18
				 NUMPEDCLI, --19
				 NUMPEDRCA, --20
				 OBS1, --21
				 OBS2, --22
				 OBSENTREGA1, --23
				 OBSENTREGA2, --24
				 OPERACAO, --25
				 ORIGEMPED, --26
				 PERCVENDA, --27
				 PERDESC, --28
				 POSICAO, --29
				 PRAZO1, --30
				 PRAZO2, --31
				 PRAZO3, --32
				 PRAZO4, --33
				 PRAZO5, --34
				 PRAZO6, --35
				 PRAZO7, --36
				 PRAZO8, --37
				 PRAZO9, --38
				 PRAZO10, --39
				 PRAZO11, --40
				 PRAZO12, --41
				 PRAZOMEDIO, --42
				 TIPOVENDA, --43
				 TOTPESO, --44
				 TOTVOLUME, --45
				 VLATEND, --46
				 VLCUSTOCONT, --47
				 VLCUSTOFIN, --48
				 VLCUSTOREAL, --49
				 VLCUSTOREP, --50
				 VLTABELA, --51
				 VLTOTAL, --52
				 NUMNOTAMANIF, --53
				 ESPECIEMANIF, --54
				 SERIEMANIF, --55
				 NUMCARMANIF, --56
				 CODFORNECFRETE, --57
				 NUMREGIAO, --58
				 USACREDRCA, --59
				 USADEBCREDRCA, --60
				 BONIFICALTDEBCREDRCA, --61
				 TROCAALTDEBCREDRCA, --62
				 CRMALTDEBCREDRCA, --63
				 BROKERALTDEBCREDRCA, --64
				 TIPOMOVCCRCA, --65
				 TURNOENTREGA, --66
				 NUMTRANSVENDATV13, --67
				 DTABERTURAPEDPALM, --68
				 DTFECHAMENTOPEDPALM, --69
				 BRINDE, --70
				 TIPOEMISSAO, --71
				 CONTINGENCIATV14, --72
				 CHAVENFE, --73
				 NUMPEDTV14, --74
				 JUSTIFICATIVACONTIGENCIA, --75
				 DTAHORAENTRADACONTIGENCIA, --76
				 UTILIZAVENDAPOREMBALAGEM, --77
				 CONSUMIUNUMNFE, --78
				 NUMFORMULARIO, --79
				 NUMSELO, --80
         --HIS.05228.2014
         CODBANCOCM --81
         ----------------
         --,PCPEDC.VLOUTRASDESP --82
         ,ASSINATURA
         ,UIDREGISTRO
         ,IDPARCEIRO
         ,VLBONIFIC   --86
				 ,FRETEDESPACHO -- 87
         )
			VALUES
				(P_REGNOTA.CODCLI, --1
				 P_REGNOTA.CODCOB, --2
				 P_CODDISTRIB, --3
				 8888, --4
				 P_REGNOTA.CODFILIAL, --5
				 P_REGNOTA.CODFILIALNF, --6
				 P_REGNOTA.CODPLPAG, --7
				 P_REGCLIENTE.CODPRACA, --8
				 P_REGRCA.CODSUPERVISOR, --9
				 P_REGRCA.CODUSUR, --10
				 P_REGNOTA.CONDVENDA, --11
				 NVL(P_REGNOTA.DATA, TRUNC(SYSDATE)), --12
				 GREATEST(P_REGNOTA.DATA, TRUNC(SYSDATE)), --13
				 TO_NUMBER(TO_CHAR(SYSDATE, 'HH24')), --14
				 TO_NUMBER(TO_CHAR(SYSDATE, 'MI')), --15
				 P_REGNOTA.NUMCARMANIF, --16
				 P_CONTITENSVALIDOS, --17
				 P_REGNOTA.NUMPED, --18
				 P_REGNOTA.NUMPEDCLI, --19
				 P_REGNOTA.NUMPEDRCA, --20
				 P_REGNOTA.OBS1, --21
				 P_REGNOTA.OBS2, --22
				 P_REGNOTA.OBSENTREGA1, --23
				 P_REGNOTA.OBSENTREGA2, --24
				 'N', --25
				 'R', --26
				 P_REGNOTA.PERCVENDA, --27
				 VNPERDESCPED, --28
				 P_REGNOTA.POSICAO, --29
				 P_REGPLPAG.PRAZO1, --30
				 P_REGPLPAG.PRAZO2, --31
				 P_REGPLPAG.PRAZO3, --32
				 P_REGPLPAG.PRAZO4, --33
				 P_REGPLPAG.PRAZO5, --34
				 P_REGPLPAG.PRAZO6, --35
				 P_REGPLPAG.PRAZO7, --36
				 P_REGPLPAG.PRAZO8, --37
				 P_REGPLPAG.PRAZO9, --38
				 P_REGPLPAG.PRAZO10, --39
				 P_REGPLPAG.PRAZO11, --40
				 P_REGPLPAG.PRAZO12, --41
				 P_REGPLPAG.NUMDIAS, --42
				 P_REGPLPAG.TIPOVENDA, --43
				 P_TOTPESOPED, --44
				 P_TOTVOLUMEPED, --45
				 P_VLTOTPED - P_VLBONIFIC, --46
				 P_VLCUSTOCONTPED, --47
				 P_VLCUSTOFINPED, --48
				 P_VLCUSTOREALPED, --49
				 P_VLCUSTOREPPED, --50
				 P_VLTOTTAB, --51
				 P_VLTOTPED, --52
				 P_REGNOTA.NUMNOTAMANIF, --53
				 P_REGNOTA.ESPECIEMANIF, --54
				 P_REGNOTA.SERIEMANIF, --55
				 P_REGNOTA.NUMCARMANIF, --56
				 P_REGNOTA.CODFORNECFRETE, --57
				 P_REGREGIAO.NUMREGIAO, --58
				 P_REGNOTA.USACREDRCA, --59
				 P_REGNOTA.USADEBCREDRCA, --60
				 P_REGNOTA.BONIFICALTDEBCREDRCA, --61
				 P_REGNOTA.TROCAALTDEBCREDRCA, --62
				 P_REGNOTA.CRMALTDEBCREDRCA, --63
				 P_REGNOTA.BROKERALTDEBCREDRCA, --64
				 P_REGNOTA.TIPOMOVCCRCA, --65
				 P_REGNOTA.TURNOENTREGA, --66
				 P_REGNOTA.NUMTRANSVENDATV13, --67
				 P_REGNOTA.DTABERTURAPEDPALM, --68
				 P_REGNOTA.DTFECHAMENTOPEDPALM, --69
				 P_REGNOTA.BRINDE, --70
				 P_REGNOTA.TIPOEMISSAO, --71
				 P_REGNOTA.CONTINGENCIATV14, --72
				 P_REGNOTA.CHAVENFE, --73
				 P_REGNOTA.NUMPEDTV14, --74
				 P_REGNOTA.JUSTIFICATIVACONTIGENCIA, --75
				 P_REGNOTA.DTAHORAENTRADACONTIGENCIA, --76
				 P_REGFILIAL.UTILIZAVENDAPOREMBALAGEM, --77
				 P_REGNOTA.CONSUMIUNUMNFE, --78
				 P_REGNOTA.NUMFORMULARIO, --79
				 P_REGNOTA.NUMSELO, --80
         --HIS.05228.2014
         P_REGNOTA.CODBANCOCM  --81
         --,P_REGNOTA.VLOUTROS -- 82
         ---------------
         ,P_REGNOTA.ASSINATURA
         ,P_REGNOTA.UIDREGISTRO
         ,P_REGNOTA.IDPARCEIRO
         ,P_VLBONIFIC  --86
				 ,P_REGNOTA.FRETEDESPACHO --87
         );

			INSERT INTO PCVENDACONSUM
				(NUMPED,
				 CLIENTE,
				 CGCENT,
				 ENDERENT,
				 MUNICENT,
				 ESTENT,
				 CEPENT,
				 IEENT,
         bairroent,
         codcidade)
			VALUES
				(P_REGNOTA.NUMPED,
				 P_REGNOTA.RAZAOSOCIAL,
				 P_REGNOTA.CNPJ,
				 P_REGNOTA.ENDERECO,
				 P_REGNOTA.CIDADE,
				 P_REGNOTA.UF,
				 P_REGNOTA.CEP,
				 P_REGNOTA.INSCESTADUAL,
         P_REGNOTA.BAIRRO,
         (select CODCIDADECOM
           from pcclient
          where codcli = P_REGNOTA.CODCLI));


			--tarefa 160801
			UPDATE PCCLIENT P
				 SET P.DTULTCOMP = TRUNC(SYSDATE)
			 WHERE CODCLI = P_REGNOTA.CODCLI;

			-- HIS.01574.2014
			VICONTADOR := PROXNUM('pcusuari', 'PROXNUMFORM', 'CODUSUR', P_REGNOTA.CODUSUR);
      VICONTADOR := PROXNUM('pcusuari', 'PROXNUMSELO', 'CODUSUR', P_REGNOTA.CODUSUR);

      -- Substituido pelas linhas acima
			/*UPDATE PCUSUARI U
				 SET U.PROXNUMFORM = U.PROXNUMFORM + 1,
						 U.PROXNUMSELO = U.PROXNUMSELO + 1
			 WHERE U.CODUSUR = P_REGNOTA.CODUSUR;*/

			RETURN TRUE;

		ELSE

			RETURN FALSE;

		END IF;

	EXCEPTION
		WHEN OTHERS THEN
			PROC_REGISTRALOG(P_REGNOTA.NUMPED,
											 P_REGNOTA.NUMPEDRCA,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 P_REGNOTA.CODUSUR,
											 NULL,
											 P_REGNOTA.CANCELADA,
											 '11',
											 SQLCODE || '-' || SQLERRM || ';',
											 NULL);
			RETURN FALSE;
	END FUNC_INSERIRNOTA;

	FUNCTION FUNC_INSERIRITEMNOTA(P_REGNOTA     IN T_NOTA,
																P_REGITEMNOTA IN T_ITEMNOTA,
																P_REGPRECOS   IN T_PRECOSETRIBUTACAO,
																P_REGPRODUTO  IN T_PRODUTO) RETURN BOOLEAN IS

    VNPBONIFIC PCPEDI.PBONIFIC%TYPE;

	BEGIN

        CASE WHEN NVL(P_REGITEMNOTA.BONIFIC, 'N') IN ('F', 'S')
          OR (P_REGNOTA.CODCOB = 'BNF') THEN
          VNPBONIFIC := P_REGITEMNOTA.PVENDA;
        ELSE
          VNPBONIFIC := 0;
         END CASE;

		IF P_REGITEMNOTA.QT > 0 THEN

			INSERT INTO PCPEDI
				(CODCLI,
				 CODICMTAB,
				 CODPROD,
				 CODST,
				 CODUSUR,
				 DATA,
				 NUMPED,
				 NUMSEQ,
				 PERCOM,
				 PERDESC,
				 POSICAO,
				 PTABELA,
				 PVENDA,
				 QT,
				 QTFALTA,
				 ST,
				 VLCUSTOCONT,
				 VLCUSTOFIN,
				 VLCUSTOREAL,
				 VLCUSTOREP,
				 PVENDABASE,
				 PBASERCA,
				 VLIPI,
				 PERCIPI,
				 PERCBASERED,
				 BASEICST,
				 PERCICM,
				 PORIGINAL,
				 CODAUXILIAR,
				 ROTINALANC,
				 NUMCAR,
				 GERAGNRE_CNPJCLIENTE,
				 SUGESTAO,
				 CODCOMBO,
				 MOVIMENTACONTACORRENTERCA,
				 USADEBCREDRCABRIND,
         VLOUTROS,
         ORIGEMST,
         USAUNIDADEMASTER,
         BONIFIC,
         PBONIFIC,
         CODDESCONTO,
         ALIQICMS1,
         ALIQICMS2,
         PAUTA,
         PERCBASEREDST,
         IVA,
         STCLIENTEGNRE,
         ALIQFCP,
         VLFECP,
         STPTABELA,
         VLIPIPTABELA,
         CODFILIALRETIRA,
         VLBONIFIC)
			VALUES
				(P_REGNOTA.CODCLI,
				 P_REGITEMNOTA.CODICMTAB,
				 P_REGITEMNOTA.CODPROD,
				 P_REGPRECOS.CODST,
				 P_REGNOTA.CODUSUR,
				 TRUNC(SYSDATE),
				 P_REGNOTA.NUMPED,
				 P_REGITEMNOTA.NUMSEQ,
				 P_REGITEMNOTA.PERCOM,
				 P_REGITEMNOTA.PERDESC,
				 P_REGNOTA.POSICAO,
				 P_REGPRODUTO.PTABELA,
				 P_REGITEMNOTA.PVENDA,
				 P_REGITEMNOTA.QT,
				 0,
				 P_REGITEMNOTA.ST,
				 P_REGPRECOS.CUSTOCONT,
				 P_REGITEMNOTA.VLCUSTOFIN,
				 P_REGITEMNOTA.VLCUSTOREAL,
				 P_REGITEMNOTA.VLCUSTOREP,
				 P_REGITEMNOTA.PVENDABASE,
				 P_REGITEMNOTA.PBASERCA,
				 P_REGITEMNOTA.VLIPI,
				 P_REGITEMNOTA.PERCIPI,
				 P_REGITEMNOTA.PERCBASERED,
				 P_REGITEMNOTA.BASEICST,
				 P_REGITEMNOTA.PERCICM,
				 P_REGITEMNOTA.BASEICMS,
				 P_REGITEMNOTA.CODAUXILIAR,
				 2596,
				 P_REGNOTA.NUMCARMANIF,
				 P_REGITEMNOTA.GERAGNRE_CNPJCLIENTE,
				 P_REGITEMNOTA.SUGESTAO,
				 P_REGITEMNOTA.CODCOMBO,
				 DECODE(P_REGNOTA.CODCOB, 'BNF', 'S', DECODE(P_REGITEMNOTA.CODCOMBO, NULL, 'S', 'N')),
				 P_REGNOTA.BRINDE,
         P_REGITEMNOTA.VLOUTROS,
         P_REGITEMNOTA.ORIGEMST,
         NVL(P_REGITEMNOTA.USAUNIDADEMASTER, 'N'),
         DECODE(P_REGNOTA.CODCOB, 'BNF', 'S', NVL(P_REGITEMNOTA.BONIFIC,'N')),
         VNPBONIFIC,
         P_REGITEMNOTA.CODDESCONTO,
         P_REGITEMNOTA.ALIQICMS1,
         P_REGITEMNOTA.ALIQICMS2,
         P_REGITEMNOTA.PAUTA,
         P_REGITEMNOTA.PERCBASEREDST,
         P_REGITEMNOTA.IVA,
         P_REGITEMNOTA.STGNRE,
         P_REGITEMNOTA.ALIQFECP,
         P_REGITEMNOTA.VLFECP,
         P_REGITEMNOTA.STPTABELA,
         P_REGITEMNOTA.VLIPIPTABELA,
         P_REGNOTA.CODFILIAL,
         VNPBONIFIC);
		END IF;

		IF P_REGITEMNOTA.QTTROCA > 0 THEN

			INSERT INTO PCTROCAFVMANIF
				(NUMPEDRCA,
				 NUMPEDTV5,
				 NUMPEDFAT,
				 CODCLI,
				 CODUSUR,
				 CODPROD,
				 QT,
				 PTABELA,
				 DTVALPROD,
				 CODPRODTROCA,
				 QTTROCA,
				 PTABELATROCA,
				 DTVALPRODTROCA,
				 AVARIA,
				 NUMINDENIZ,
				 DTDEVOL,
				 MOTIVO,
				 CODAUXILIAR,
				 CODAUXILIARTROCA)
			VALUES
				(P_REGNOTA.NUMPEDRCA,
				 P_REGNOTA.NUMPEDTV5,
				 NULL, --p_regnota.numpedfat,
				 P_REGNOTA.CODCLI,
				 P_REGNOTA.CODUSUR,
				 DECODE(P_REGITEMNOTA.QT, 0, NULL, P_REGITEMNOTA.CODPROD),
				 P_REGITEMNOTA.QT,
				 P_REGPRODUTO.PTABELA,
				 P_REGITEMNOTA.DTVALPROD,
				 P_REGITEMNOTA.CODPRODTROCA,
				 P_REGITEMNOTA.QTTROCA,
				 P_REGITEMNOTA.PTABELATROCA,
				 P_REGITEMNOTA.DTVALPRODTROCA,
				 P_REGITEMNOTA.AVARIA,
				 P_REGITEMNOTA.NUMINDENIZ,
				 NULL, --dtdevol,
				 NULL, --motivo,
				 P_REGITEMNOTA.CODAUXILIAR,
				 P_REGITEMNOTA.CODAUXILIARTROCA);

		END IF;

		RETURN TRUE;
	EXCEPTION
		WHEN OTHERS THEN
			PROC_REGISTRALOG(P_REGNOTA.NUMPED,
											 P_REGNOTA.NUMPEDRCA,
											 P_REGITEMNOTA.CODPROD,
											 P_REGITEMNOTA.CODAUXILIAR,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 P_REGITEMNOTA.CODUSUR,
											 NULL,
											 P_REGITEMNOTA.CANCELADA,
											 '12',
											 SQLCODE || '-' || SQLERRM || ';',
											 NULL);
			RETURN FALSE;
	END FUNC_INSERIRITEMNOTA;

	/*    PROCEDURE gerarcarregbalcaoreserva
          Gerar registro de carregamento e atualiza pedido e itens do pedido
  */
	PROCEDURE GERARCARREGBALCAORESERVA(P_NUMPED            IN PCPEDC.NUMPED%TYPE,
																		 P_NUMPEDRCA         IN PCPEDC.NUMPEDRCA%TYPE,
																		 P_CODUSUR           IN PCPEDC.CODUSUR%TYPE,
																		 P_CGCCLI            IN PCCLIENT.CGCENT%TYPE,
																		 P_DTABERTURAPEDPALM IN PCPEDC.DTABERTURAPEDPALM%TYPE,
																		 P_CANCELADA         IN VARCHAR2,
																		 P_NUMCAR            OUT PCPEDC.NUMCAR%TYPE) IS

		PNCAREGAMENTO  NUMBER;
		VNVLATENDPED   PCPEDC.VLATEND%TYPE;
		VNTOTPESOPED   PCPEDC.TOTPESO%TYPE;
		VNTOTVOLUMEPED PCPEDC.TOTVOLUME%TYPE;
		VNNUMNOTAS     PCCARREG.NUMNOTAS%TYPE;
    iTentativa     INTEGER;
	BEGIN
		BEGIN

			/*SELECT PROXNUMCAR INTO PNCAREGAMENTO FROM PCCONSUM FOR UPDATE;

			UPDATE PCCONSUM SET PROXNUMCAR = NVL(PROXNUMCAR, 0) + 1;*/

      PNCAREGAMENTO := FERRAMENTAS.F_PROX_NUMCAR;
      iTentativa := 0;

      while iTentativa < 50 or PNCAREGAMENTO = 0
      loop
        PNCAREGAMENTO := FERRAMENTAS.F_PROX_NUMCAR;
         if PNCAREGAMENTO > 0 then
           exit;
         end if;
        iTentativa := iTentativa+1;
      end loop;

			UPDATE PCPEDI
				 SET NUMCAR = PNCAREGAMENTO, POSICAO = 'M'
			 WHERE NUMPED IN (SELECT NUMPED
													FROM PCPEDC
												 WHERE NUMPEDRCA = P_NUMPEDRCA
													 AND NVL(PCPEDC.RESTRICAOTRANSP, 'N') = 'N'
													 AND CODUSUR = P_CODUSUR
													 AND (DTABERTURAPEDPALM = P_DTABERTURAPEDPALM OR
															 DTABERTURAPEDPALM IS NULL)
													 AND POSICAO = 'L');

			UPDATE PCPEDC
				 SET NUMCAR = PNCAREGAMENTO, POSICAO = 'M', TIPOCARGA = 'R'
			 WHERE NUMPED IN (SELECT NUMPED
													FROM PCPEDC
												 WHERE NUMPEDRCA = P_NUMPEDRCA
													 AND NVL(PCPEDC.RESTRICAOTRANSP, 'N') = 'N'
													 AND CODUSUR = P_CODUSUR
													 AND (DTABERTURAPEDPALM = P_DTABERTURAPEDPALM OR
															 DTABERTURAPEDPALM IS NULL)
													 AND POSICAO = 'L');

			SELECT SUM(PCPEDI.QT * PCPEDI.PVENDA),
						 SUM(NVL(PCPEDI.QT, 0) * NVL(PCPRODUT.PESOBRUTO, 0)) TOTPESO,
						 SUM(NVL(PCPEDI.QT, 0) * NVL(PCPRODUT.VOLUME, 0)) TOTVOLUME
				INTO VNVLATENDPED, VNTOTPESOPED, VNTOTVOLUMEPED
				FROM PCPEDI, PCPRODUT
			 WHERE PCPEDI.CODPROD = PCPRODUT.CODPROD
				 AND NUMPED IN (SELECT NUMPED
													FROM PCPEDC
												 WHERE NUMPEDRCA = P_NUMPEDRCA
													 AND NVL(PCPEDC.RESTRICAOTRANSP, 'N') = 'N'
													 AND CODUSUR = P_CODUSUR
													 AND (DTABERTURAPEDPALM = P_DTABERTURAPEDPALM OR
															 DTABERTURAPEDPALM IS NULL)
													 AND POSICAO = 'M');

			INSERT INTO PCCARREG
				(NUMCAR,
				 DTSAIDA,
				 TOTPESO,
				 TOTVOLUME,
				 VLTOTAL,
				 DESTINO,
				 DATAMON,
				 CODVEICULO,
				 CODFUNCMON,
				 DTFECHA,
				 NUMNOTAS)
			VALUES
				(PNCAREGAMENTO,
				 TRUNC(SYSDATE),
				 VNTOTPESOPED,
				 VNTOTVOLUMEPED,
				 VNVLATENDPED,
				 'VENDA BALCAO',
				 TRUNC(SYSDATE),
				 0,
				 0,
				 TRUNC(SYSDATE),
				 1);

			COMMIT;

			PROC_REGISTRALOG(P_NUMPED,
											 P_NUMPEDRCA,
											 NULL,
											 NULL,
											 P_CGCCLI,
											 NULL,
											 NULL,
											 NULL,
											 P_CODUSUR,
											 P_DTABERTURAPEDPALM,
											 P_CANCELADA,
											 '2',
											 'CARREGAMENTO CRIADO PARA PEDIDO BALCAO RESERVA. NUMCAR = ' ||
											 TO_CHAR(PNCAREGAMENTO, '000000') || ';',
											 NULL);

			P_NUMCAR := PNCAREGAMENTO;

		EXCEPTION
			WHEN OTHERS THEN
				PROC_REGISTRALOG(P_NUMPED,
												 P_NUMPEDRCA,
												 NULL,
												 NULL,
												 P_CGCCLI,
												 NULL,
												 NULL,
												 NULL,
												 P_CODUSUR,
												 P_DTABERTURAPEDPALM,
												 P_CANCELADA,
												 '2',
												 'ERRO: NAO GEROU/ATUALIZOU CARREGAMENTO. NUMCAR = ' ||
												 TO_CHAR(PNCAREGAMENTO, '000000') || ';',
												 NULL);
				ROLLBACK;
		END;
	END GERARCARREGBALCAORESERVA;

	PROCEDURE PROC_CANCELANF(P_REGNOTA IN OUT T_NOTA)

	 IS

		VSMENSAGEM      VARCHAR2(300);
		VSMENSAGEMAUX   VARCHAR2(200);
		VNNUMCAR        PCPEDC.NUMCAR%TYPE;
		VICONT          NUMBER := 0;
		VNNUMTRANSVENDA NUMBER;
		VSPOSICAO       PCPEDC.POSICAO%TYPE;
		VNCONTNOTAS     NUMBER;
		VNNUMPED        PCPEDC.NUMPED%TYPE;
		VSNOMEGUERRA    PCEMPR.NOME_GUERRA%TYPE;

	BEGIN

		VSNOMEGUERRA  := NULL;
		VSMENSAGEMAUX := NULL;

		BEGIN
			SELECT NOME_GUERRA
				INTO VSNOMEGUERRA
				FROM PCEMPR
			 WHERE MATRICULA = 8888;
		EXCEPTION
			WHEN OTHERS THEN

				PROC_REGISTRALOG(NULL,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 NULL,
												 '1',
												 'Erro ao buscar nome do emitente 8888#;' ||
												 SQLCODE || '-' || SQLERRM || ';',
												 NULL);

		END;

		VNNUMTRANSVENDA := 0;
		VNNUMPED        := NULL;
		VSPOSICAO       := NULL;

		BEGIN

			SELECT PCPEDC.NUMPED, POSICAO
				INTO VNNUMPED, VSPOSICAO
				FROM PCPEDC
			 WHERE NUMPEDRCA = P_REGNOTA.NUMPEDRCA
				 AND NUMCARMANIF = P_REGNOTA.NUMCARMANIF
				 AND CONDVENDA = 14
				 AND CODUSUR = P_REGNOTA.CODUSUR;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				VNNUMPED  := NULL;
				VSPOSICAO := NULL;

		END;

		BEGIN
			SELECT DISTINCT NUMTRANSVENDA
				INTO VNNUMTRANSVENDA
				FROM PCNFSAID
			 WHERE NUMPED = VNNUMPED;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				VNNUMTRANSVENDA := 0;
		END;

		IF VNNUMPED IS NOT NULL THEN

			IF (VSPOSICAO IN ('L', 'M')) OR (VNNUMTRANSVENDA = 0) THEN
				BEGIN
					IF VSPOSICAO = 'M' THEN
						--verificar se existe apenas este pedido no carregamento
						BEGIN
							SELECT NUMCAR
								INTO VNNUMCAR
								FROM PCPEDC
							 WHERE NUMPED = VNNUMPED;
						EXCEPTION
							WHEN NO_DATA_FOUND THEN
								VNNUMCAR := 0;
						END;

						IF VNNUMCAR <> 0 THEN
							SELECT COUNT(*)
								INTO VICONT
								FROM PCPEDC
							 WHERE NUMCAR = VNNUMCAR
								 AND DTCANCEL IS NULL;

							IF VICONT = 1 THEN
								INSERT INTO PCNFCAN
									(NUMTRANSENT,
									 NUMTRANSVENDA,
									 CODFUNCEMITE,
									 DATAEMISSAO,
									 CODFUNCCANC,
									 DATACANC,
									 VLTOTAL,
									 CODCLI,
									 CODFORNEC,
									 MOTIVO,
									 NUMPED,
									 NUMCAR,
									 NUMPEDCOMPRA,
									 CODROTINA,
									 DESCRICAO,
									 CODUSUR)
									SELECT NULL,
												 NULL,
												 8888,
												 TRUNC(SYSDATE),
												 8888,
												 TRUNC(SYSDATE),
												 VLTOTAL,
												 NULL,
												 NULL,
												 'PEDIDO PALM CANCELADO.RCA' || P_REGNOTA.CODUSUR,
												 NULL,
												 NUMCAR,
												 NULL,
												 2596,
												 'Carregamento : ' || VNNUMCAR,
												 NULL
										FROM PCCARREG
									 WHERE NUMCAR = VNNUMCAR;

								UPDATE PCCARREG
									 SET PCCARREG.DT_CANCEL = TRUNC(SYSDATE),
											 CODFUNCCANCEL      = 8888,
											 TOTPESO            = 0,
											 TOTVOLUME          = 0,
											 VLTOTAL            = 0,
											 DESTINO            = NULL,
											 CODVEICULO         = 0,
											 OBSFATUR           = 'PEDIDO PALM CANCELADO.RCA' ||
																						P_REGNOTA.CODUSUR
								 WHERE NUMCAR = VNNUMCAR;
							END IF;
						END IF;
					END IF;

					INSERT INTO PCNFCAN
						(NUMTRANSENT,
						 NUMTRANSVENDA,
						 CODFUNCEMITE,
						 DATAEMISSAO,
						 CODFUNCCANC,
						 DATACANC,
						 VLTOTAL,
						 CODCLI,
						 CODFORNEC,
						 MOTIVO,
						 NUMPED,
						 NUMCAR,
						 NUMPEDCOMPRA,
						 CODROTINA,
						 DESCRICAO,
						 CODUSUR)
						SELECT NULL,
									 NULL,
									 8888,
									 TRUNC(SYSDATE),
									 8888,
									 TRUNC(SYSDATE),
									 VLTOTAL,
									 CODCLI,
									 NULL,
									 'CANC.NOTA ' || NUMNOTAMANIF,
									 NUMPED,
									 NUMCAR,
									 NULL,
									 2596,
									 'Cliente ' || P_REGNOTA.CODCLI || '-' || ' CANC.NOTA ' ||
									 P_REGNOTA.NUMNOTAMANIF,
									 CODUSUR
							FROM PCPEDC
						 WHERE NUMPED = VNNUMPED;

					INSERT INTO PCNFCANITEM
						(NUMTRANSENT,
						 NUMTRANSVENDA,
						 CODFUNCEMITE,
						 DATAEMISSAO,
						 CODFUNCCANC,
						 DATACANC,
						 CODPROD,
						 QT,
						 PVENDA,
						 PTABELA,
						 NUMSEQ,
						 CODCLI,
						 CODFORNEC,
						 MOTIVO,
						 NUMPED,
						 NUMCAR,
						 NUMPEDCOMPRA,
						 CODROTINA,
						 DESCRICAO,
						 CODUSUR)
						SELECT NULL,
									 NULL,
									 8888,
									 TRUNC(SYSDATE),
									 8888,
									 TRUNC(SYSDATE),
									 CODPROD,
									 QT,
									 PVENDA,
									 PTABELA,
									 NUMSEQ,
									 CODCLI,
									 NULL,
									 'CANC.NOTA ' || P_REGNOTA.NUMNOTAMANIF,
									 NUMPED,
									 NUMCAR,
									 NULL,
									 2596,
									 'Cliente ' || P_REGNOTA.CODCLI || '-' || ' CANC.NOTA ' ||
									 P_REGNOTA.NUMNOTAMANIF,
									 CODUSUR
							FROM PCPEDI
						 WHERE NUMPED = VNNUMPED;

					UPDATE PCPEDC
						 SET POSICAO = 'C', DTCANCEL = TRUNC(SYSDATE)
					 WHERE NUMPED = VNNUMPED;

					UPDATE PCPEDI SET POSICAO = 'C' WHERE NUMPED = VNNUMPED;

					DELETE FROM PCFALTA WHERE NUMPED = VNNUMPED;

					P_REGNOTA.POSICAO := 'C';

					UPDATE PCPEDCFVMANIF
						 SET IMPORTADO = 2, RETORNO = 2, POSICAO_ATUAL = 'C'
					 WHERE NUMPEDRCA = P_REGNOTA.NUMPEDRCA
             AND CODUSUR     = P_REGNOTA.CODUSUR
						 AND NUMCARMANIF = P_REGNOTA.NUMCARMANIF
						 AND NVL(CANCELADA, 'N') = 'S';

					/* UPDATE pcpedifvmanif
          SET importado = 2
           WHERE numpedrca = p_regnota.numpedrca
            --and  numcarmanif   = p_regnota.numcarmanif
            and  nvl(cancelado,'N') = 'S';*/

					COMMIT;
				EXCEPTION
					WHEN OTHERS THEN
						ROLLBACK;

						VSMENSAGEMAUX := SQLCODE || ' ' || SQLERRM;

				END;

			ELSIF VSPOSICAO = 'F' AND VNNUMTRANSVENDA <> 0 THEN
				VSMENSAGEM := '';
				P_PC_CACELA_NF(VSNOMEGUERRA,
											 VNNUMTRANSVENDA,
											 'CANC.NOTA ' || P_REGNOTA.NUMNOTAMANIF,
											 VSMENSAGEM);

				IF VSMENSAGEM = 'OK' THEN
					BEGIN
						UPDATE PCPEDCFVMANIF
							 SET IMPORTADO = 2, RETORNO = 2, POSICAO_ATUAL = 'C'
						 WHERE NUMPEDRCA = P_REGNOTA.NUMPEDRCA
               AND CODUSUR   = P_REGNOTA.CODUSUR
							 AND NUMCARMANIF = P_REGNOTA.NUMCARMANIF
							 AND NVL(CANCELADA, 'N') = 'S';

						P_REGNOTA.POSICAO := 'C';

						COMMIT;
					EXCEPTION
						WHEN OTHERS THEN
							ROLLBACK;
							VSMENSAGEMAUX := SQLCODE || ' ' || SQLERRM;

					END;
				ELSE
					BEGIN

						UPDATE PCPEDCFVMANIF
							 SET IMPORTADO     = 3,
									 RETORNO       = 2,
									 OBSERVACAO_PC = SUBSTR('Erro ao executar p_pc_cacela_nf : ' ||
																					VSMENSAGEM,
																					1,
																					300)
						 WHERE NUMPEDRCA = P_REGNOTA.NUMPEDRCA
               AND CODUSUR   = P_REGNOTA.CODUSUR
							 AND NUMCARMANIF = P_REGNOTA.NUMCARMANIF
							 AND NVL(CANCELADA, 'N') = 'S';

						COMMIT;
					EXCEPTION
						WHEN OTHERS THEN
							ROLLBACK;

							VSMENSAGEMAUX := SUBSTR('Erro p_pc_cacela_nf : ' ||
																			VSMENSAGEM,
																			1,
																			100);

							COMMIT;
					END;
				END IF;
			END IF;

		END IF;

		IF TRIM(VSMENSAGEMAUX) IS NOT NULL THEN

			PROC_REGISTRALOG(VNNUMPED,
											 P_REGNOTA.NUMPEDRCA,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 NULL,
											 P_REGNOTA.CANCELADA,
											 '11',
											 VSMENSAGEMAUX || ';',
											 NULL);

		END IF;

	EXCEPTION
		WHEN OTHERS THEN
			ROLLBACK;
	END PROC_CANCELANF;

  FUNCTION FUNC_VALIDAR_MULTIPLOS_PLANOS(PNUMPEDRCA IN NUMBER
                                        ,PCODUSUR   IN NUMBER
                                         ---       ,PDTINCLUSAO IN DATE
                                        ,PNUMPEDIDO IN NUMBER
                                        ,PSMSG      IN OUT VARCHAR2)
    RETURN BOOLEAN IS
    VSMSG               VARCHAR2(1000) := '';
    VBRETORNO           BOOLEAN := TRUE;
    VNPRAZOMEDIOPED     NUMBER;
    VNTOTALPEDIDO       NUMBER;
    VNCONTPARCELAS      NUMBER;
    VNSOMAPRAZOMEDIO    NUMBER;
    VNSOMACOBRANCAS     NUMBER;
    VNSOMACOBNAODINHERO NUMBER := 0;
    VNTOTALST           NUMBER := 0;
    VSCLIGERATITULOST   VARCHAR2(1);
    VNCLIVALORMINST     NUMBER;
    VSCODCOBST          VARCHAR2(5);

  BEGIN
    SELECT COUNT(1)
      INTO VNCONTPARCELAS
      FROM PCFORMAPGTOPEDIDOFVMANIF FP
     WHERE FP.NUMPEDRCA = PNUMPEDRCA
       AND FP.CODUSUR = PCODUSUR;
    --    AND FP.DTINCLUSAO = PDTINCLUSAO

    IF VNCONTPARCELAS <= 0
    THEN
      RETURN TRUE;
    END IF;

    VSCODCOBST := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CODCOBST', '99', '');
    BEGIN
      SELECT C.VLTOTAL, C.PRAZOMEDIO, CL.GERATITULOST, CL.VLMINIMOST
        INTO VNTOTALPEDIDO
            ,VNPRAZOMEDIOPED
            ,VSCLIGERATITULOST
            ,VNCLIVALORMINST
        FROM PCPEDC C, PCCLIENT CL
       WHERE C.NUMPED = PNUMPEDIDO
         AND C.CODCLI = CL.CODCLI;

      SELECT SUM(I.ST * I.QT) TOTAL_ST
        INTO VNTOTALST
        FROM PCPEDI I
       WHERE I.NUMPED = PNUMPEDIDO;
    EXCEPTION
      WHEN OTHERS THEN
        PSMSG := 'Não foi possível localizar o pedido para verificação dos multiplos planos de pagamento';
        RETURN FALSE;
    END;

    VNSOMACOBRANCAS  := 0;
    VNSOMAPRAZOMEDIO := 0;
    VNCONTPARCELAS   := 0;

    FOR PAGTOS IN (SELECT COUNT(1) QT
                         ,FP.CODCOB
                         ,FP.CODPLPAG
                         ,FP.VALOR
                         ,FP.DTVENC
                         ,FP.NUMAUTORIZACAO
                         ,NVL(FP.VLENTRADA, 0) VLENTRADA
                         ,NVL(FP.VLRTROCO, 0) VLRTROCO
                         ,C.BANDEIRACARTAO
                         ,C.CARTAO
                         ,P.NUMDIAS
                         ,P.FORMAPARCELAMENTO
                         ,P.TIPOENTRADA
                         ,REGEXP_REPLACE(OP.CGCENT, '[./\-]', '') CGC_OPERADORA
                     FROM PCFORMAPGTOPEDIDOFVMANIF FP
                         ,PCCOB                    C
                         ,PCPLPAG                  P
                         ,PCCLIENT                 OP
                    WHERE FP.NUMPEDRCA = PNUMPEDRCA
                      AND FP.CODUSUR = PCODUSUR
                         --    AND FP.DTINCLUSAO = PDTINCLUSAO
                      AND FP.CODCOB = C.CODCOB
                      AND FP.CODPLPAG = P.CODPLPAG
                      AND C.CODCLICC = OP.CODCLI(+)
                    GROUP BY FP.CODCOB
                            ,FP.CODPLPAG
                            ,FP.VALOR
                            ,FP.DTVENC
                            ,FP.NUMAUTORIZACAO
                            ,NVL(FP.VLENTRADA, 0)
                            ,NVL(FP.VLRTROCO, 0)
                            ,C.BANDEIRACARTAO
                            ,P.NUMDIAS
                            ,C.CARTAO
                            ,P.FORMAPARCELAMENTO
                            ,P.TIPOENTRADA
                            ,REGEXP_REPLACE(OP.CGCENT, '[./\-]', ''))
    LOOP
      IF PAGTOS.FORMAPARCELAMENTO = 'T'
      THEN
        VNSOMAPRAZOMEDIO := VNSOMAPRAZOMEDIO +
                            FATURAMENTO.RETORNA_PRAZOMEDIDO_PLPAGFIXO(PAGTOS.CODPLPAG);
      ELSE
        VNSOMAPRAZOMEDIO := VNSOMAPRAZOMEDIO + PAGTOS.NUMDIAS;
      END IF;

      VNCONTPARCELAS := VNCONTPARCELAS + 1;

      IF (PAGTOS.QT > 1) AND (PAGTOS.FORMAPARCELAMENTO <> 'V')
      THEN
        VBRETORNO := FALSE;
        VSMSG     := VSMSG ||
                     ' - Foi encontrada mais de uma linha para a cobrança ' ||
                     PAGTOS.CODCOB || CHR(13);
      END IF;

      IF (TRUNC(PAGTOS.DTVENC) < TRUNC(SYSDATE))
      THEN
        VBRETORNO := FALSE;
        VSMSG     := VSMSG ||
                     ' - Data de vencimento não pode ser menor do que a data atual. Cobrança: ' ||
                     PAGTOS.CODCOB || CHR(13);
      END IF;

      IF ((PAGTOS.VALOR - PAGTOS.VLRTROCO) > VNTOTALPEDIDO)
      THEN
        VBRETORNO := FALSE;
        VSMSG     := VSMSG ||
                     ' - Valor da parcela não pode ser maior ao valor do pedido. Cobrança: ' ||
                     PAGTOS.CODCOB || CHR(13);
      END IF;

      IF (PAGTOS.CARTAO = 'S') AND (PAGTOS.NUMAUTORIZACAO IS NULL)
      THEN
        VBRETORNO := FALSE;
        VSMSG     := VSMSG || ' - Cobrança: ' || PAGTOS.CODCOB ||
                     ' definida como cartão. Favor informar o número da autorização.' ||
                     CHR(13);
      END IF;

      IF (PAGTOS.TIPOENTRADA = 3) AND (PAGTOS.VLENTRADA <= 0)
      THEN
        VBRETORNO := FALSE;
        VSMSG     := VSMSG ||
                     ' - Valor da entrada não informada para o plano de pagamento. Cobrança: ' ||
                     PAGTOS.CODCOB || '; Plano. de Pagto: ' ||
                     PAGTOS.CODPLPAG || CHR(13);
      END IF;

      IF ((VNTOTALST > 0) AND (VSCODCOBST <> '') AND
         (VSCLIGERATITULOST = 'S') AND (VNCLIVALORMINST > VNTOTALST)) AND
         ((PAGTOS.CODCOB = VSCODCOBST) AND (PAGTOS.VALOR <> VNTOTALST))
      THEN
        VBRETORNO := FALSE;
        VSMSG     := VSMSG ||
                     ' - Valor para cobrança de ST informado, diverge do valor do ST do pedido. Cobrança: ' ||
                     PAGTOS.CODCOB || CHR(13);
      END IF;

      VNSOMACOBRANCAS := VNSOMACOBRANCAS + (PAGTOS.VALOR - PAGTOS.VLRTROCO);
    END LOOP;

    IF VNSOMACOBRANCAS <> VNTOTALPEDIDO
    THEN
      VBRETORNO := FALSE;
      VSMSG     := VSMSG ||
                   ' - O somatório das cobranças informadas está divergente ao valor total do pedido.. Cobrança: ' ||
                   CHR(13);
    END IF;

    IF (VNSOMAPRAZOMEDIO / VNCONTPARCELAS) > VNPRAZOMEDIOPED
    THEN
      VBRETORNO := FALSE;
      VSMSG     := VSMSG ||
                   ' - Prazo médio das cobranças informadas maior que o prazo médio do pedido.' ||
                   CHR(13);
    END IF;

    IF VBRETORNO
    THEN
      FOR PAGTOS IN (SELECT COUNT(1) QT
                           ,FP.CODCOB
                           ,FP.CODPLPAG
                           ,FP.VALOR
                           ,FP.DTVENC
                           ,FP.NUMAUTORIZACAO
                           ,NVL(FP.VLENTRADA, 0) VLENTRADA
                           ,NVL(FP.VLRTROCO, 0) VLRTROCO
                           ,C.BANDEIRACARTAO
                           ,C.CARTAO
                           ,P.NUMDIAS
                           ,P.FORMAPARCELAMENTO
                           ,P.TIPOENTRADA
                           ,REGEXP_REPLACE(OP.CGCENT, '[./\-]', '') CGC_OPERADORA
                       FROM PCFORMAPGTOPEDIDOFVMANIF FP
                           ,PCCOB                    C
                           ,PCPLPAG                  P
                           ,PCCLIENT                 OP
                      WHERE FP.NUMPEDRCA = PNUMPEDRCA
                        AND FP.CODUSUR = PCODUSUR
                           --    AND FP.DTINCLUSAO = PDTINCLUSAO
                        AND FP.CODCOB = C.CODCOB
                        AND FP.CODPLPAG = P.CODPLPAG
                        AND C.CODCLICC = OP.CODCLI(+)
                      GROUP BY FP.CODCOB
                              ,FP.CODPLPAG
                              ,FP.VALOR
                              ,FP.DTVENC
                              ,FP.NUMAUTORIZACAO
                              ,NVL(FP.VLENTRADA, 0)
                              ,NVL(FP.VLRTROCO, 0)
                              ,C.BANDEIRACARTAO
                              ,P.NUMDIAS
                              ,C.CARTAO
                              ,P.FORMAPARCELAMENTO
                              ,P.TIPOENTRADA
                              ,REGEXP_REPLACE(OP.CGCENT, '[./\-]', ''))
      LOOP
        INSERT INTO PCFORMAPGTOPEDIDO
          (NUMPED
          ,CODCOB
          ,CODPLPAG
          ,DTVENC
          ,VALOR
          ,TIPOINTEGRACAO
          ,CNPJCREDCARTAO
          ,NUMAUTORIZACAO
          ,VLRTROCO
          ,CODBANDEIRACARTAO
          ,VLENTRADA)
        VALUES
          (PNUMPEDIDO
          ,PAGTOS.CODCOB
          ,PAGTOS.CODPLPAG
          ,PAGTOS.DTVENC
          ,PAGTOS.VALOR
          ,DECODE(PAGTOS.CARTAO, 'S', 2, NULL)
          ,PAGTOS.CGC_OPERADORA
          ,PAGTOS.NUMAUTORIZACAO
          ,PAGTOS.VLRTROCO
          ,PAGTOS.BANDEIRACARTAO
          ,PAGTOS.VLENTRADA);

      END LOOP;
    END IF;

    PSMSG := VSMSG;
    RETURN VBRETORNO;
  END FUNC_VALIDAR_MULTIPLOS_PLANOS;

	PROCEDURE PROC_PROCESSARNOTAS(P_EXISTERRO IN OUT BOOLEAN) IS

		REGCLIENTE         T_CLIENTEPEDIDO;
		REGRCA             T_RCA;
		REGREGIAO          T_REGIAOCLIENTE;
		REGPLPAG           T_PLANODEPAGAMENTO;
		REGPRODUTO         T_PRODUTO;
		REGPRECOS          T_PRECOSETRIBUTACAO;
		REGPRECOTROCA      T_PRECOTROCA;
		REGFILIAL          T_FILIAL;
		VNCONTNOTA         NUMBER;
		VNCONTITEM         NUMBER;
		VNCONTITENSVALIDOS NUMBER;
		VNVLTOTNOTA        NUMBER;
		VNVLTOTTAB         NUMBER;
		VNVLTOTBASERCA     NUMBER;
		VNTOTPESOPED       NUMBER;
		VNTOTVOLUMEPED     NUMBER;
		VNVLCUSTOCONTPED   NUMBER;
		VNVLCUSTOFINPED    NUMBER;
		VNVLCUSTOREALPED   NUMBER;
		VNVLCUSTOREPPED    NUMBER;
		VBCABVALIDO        BOOLEAN;
		VNCONTITEMATUAL    NUMBER;
		VNNUMSEQ           NUMBER;
		VSMENSAGEM_COMISS  VARCHAR2(1000);
		VSMENSAGEM_ST      VARCHAR2(1000);
		VBCALCULASTVALIDO  BOOLEAN := FALSE;
		VSCODDISTRIB       PCPRODUT.CODDISTRIB%TYPE;
		VSEMITENTE         PCEMPR.NOME%TYPE;
		VSMENSAGEM_FATU    VARCHAR2(1000);
		VNNUMTRANSVENDA    PCNFSAID.NUMTRANSVENDA%TYPE;
		VNNUMPAG           PCREGCOBC.NUMPAG%TYPE;
		VNNUMCAR           PCCARREG.NUMCAR%TYPE;
		VBCODICMTABPF      BOOLEAN;
		VNPERLUC           NUMBER;
		VICONTADOR         NUMBER;
		VSMENSAGEM_RECEB   VARCHAR2(300);
		VICONT             NUMBER;
		VSREALIZARECEBFV   VARCHAR2(1);

		VNVLDISPONIVEL NUMBER;
		VNVLSALDOPED   NUMBER := 0;
		VBSALDORCA     BOOLEAN;

		VBVALIDODESCONTOCOMBO   BOOLEAN;
		VSMENSAGEMDESCONTOCOMBO VARCHAR2(1000);
		VNCONTITENSTROCA        NUMBER;

		VSMENSAGEMRESTST VARCHAR2(1000);
		VNPEDIDORESTST   PCPEDC.NUMPED%TYPE;
		VSBOLETO         PCCOB.BOLETO%TYPE;
		VNCODBANCO       PCBANCO.CODBANCO%TYPE;
		vnNumdiasProtesto            number;
    vnCodFilialRetira            PCPEDI.CODFILIALRETIRA%TYPE;
    vsTIPOST            VARCHAR2(20);

    VSPODECOMPRAR    VARCHAR2(1);
    VSMSGTEMP        VARCHAR2(4000);
    VNQTDTEMP        NUMBER(14,4);
    VNUMPEDTV13      NUMBER(10);
    VSMENSAGEM_SERIE VARCHAR2(100);
    VSOUTRASDESPSAID           PCNFSAID.VLOUTRASDESP%TYPE;
    TOTVENDABONIFICMES         NUMBER(18,6);
    VLTOTALBNF                 NUMBER(18,6);
    vsValidaValorMinVendaBalcao VARCHAR2(3);
    VNVLATEND                  NUMBER(18,6);
    vnsaldodisponivel          NUMBER(18,6);
    vsRetiraImposto201             VARCHAR2(1);
    vConsideraPrecoSemImposto      VARCHAR2(1);
    VSAPLICADESCONTOSIMPLES        VARCHAR2(1);
    VNCODPRECOFIXO                 VARCHAR2(32767);
    vnvlredsimplesnac_ptabela      PCPEDI.VLREDPVENDASIMPLESNA%TYPE;
    VSUTILIZACODPRODPRINC          VARCHAR2(1);
    VNQTTOTAL                      NUMBER(18,6);
    P_VSNAODEBITACCRCA             VARCHAR2(1);
    P_VSCREDITACCRCA               VARCHAR2(1);
    p_vsAlterarPtabela             VARCHAR2(1);
    p_TipoCampanhaCombo            VARCHAR2(4);
    P_VDPERCDESCPOLITICA           PCPEDI.PERDESC%TYPE;

	BEGIN
		VNCONTNOTA := GVET_REGNOTA.COUNT;

		IF VNCONTNOTA > 0 THEN
			FOR I IN 1 .. VNCONTNOTA LOOP

				VSCODDISTRIB := NULL;

				BEGIN
					PROC_VALIDARNOTA(GVET_REGNOTA(I),
													 REGCLIENTE,
													 REGRCA,
													 REGREGIAO,
													 REGPLPAG,
													 REGFILIAL);

					IF GVET_REGNOTA(I).VALIDO = TRUE THEN
						VNCONTITEM         := GVET_REGITEMNOTA.COUNT;
						VNCONTITEMATUAL    := 0;
						VNNUMSEQ           := 0;
						VNCONTITENSVALIDOS := 0;
						VNVLTOTNOTA        := 0;
						VNVLTOTTAB         := 0;
						VNVLTOTBASERCA     := 0;
						VNTOTPESOPED       := 0;
						VNTOTVOLUMEPED     := 0;
						VNVLCUSTOCONTPED   := 0;
						VNVLCUSTOFINPED    := 0;
						VNVLCUSTOREALPED   := 0;
						VNVLCUSTOREPPED    := 0;

						FOR J IN 1 .. VNCONTITEM LOOP
							BEGIN
								IF (GVET_REGNOTA(I).NUMPEDRCA = GVET_REGITEMNOTA(J)
									 .NUMPEDRCA)
               AND (GVET_REGNOTA(I).CODUSUR = GVET_REGITEMNOTA(J)
									 .CODUSUR)
								--and (gvet_regnota(i).numcarmanif = gvet_regitemnota(j).numcarmanif)
								 THEN

									IF GVET_REGITEMNOTA(J)
									.CODPRODTROCA > 0 AND GVET_REGITEMNOTA(J).CODPROD = 0 THEN

										GVET_REGITEMNOTA(J).VALIDO := FALSE;
										PROC_REGISTRALOG(GVET_REGNOTA(I).NUMPED,
																		 GVET_REGNOTA(I).NUMPEDRCA,
																		 GVET_REGITEMNOTA(J).CODPROD,
																		 GVET_REGITEMNOTA(J).CODAUXILIAR,
																		 NULL,
																		 NULL,
																		 NULL,
																		 NULL,
																		 GVET_REGNOTA(I).CODUSUR,
																		 NULL,
																		 GVET_REGITEMNOTA(J).CANCELADA,
																		 '12',
																		 'É necessário informar um Codigo de Produto válido quando informa o codigo de produto de troca.',
																		 NULL);

									ELSE

										IF GVET_REGITEMNOTA(J).QT = 0 AND GVET_REGITEMNOTA(J)
										.QTTROCA = 0 THEN

											GVET_REGITEMNOTA(J).VALIDO := FALSE;
											PROC_REGISTRALOG(GVET_REGNOTA(I).NUMPED,
																			 GVET_REGNOTA(I).NUMPEDRCA,
																			 GVET_REGITEMNOTA(J).CODPROD,
																			 GVET_REGITEMNOTA(J).CODAUXILIAR,
																			 NULL,
																			 NULL,
																			 NULL,
																			 NULL,
																			 GVET_REGITEMNOTA(J).CODUSUR,
																			 NULL,
																			 GVET_REGITEMNOTA(J).CANCELADA,
																			 '12',
																			 'Item sem quantidade de venda e troca.',
																			 NULL);

										ELSE
											IF GVET_REGITEMNOTA(J).QT > 0 THEN

												PROC_VALIDARITEMNOTA(GVET_REGITEMNOTA(J),
																						 GVET_REGNOTA(I),
																						 REGCLIENTE,
																						 REGRCA,
																						 REGREGIAO,
																						 REGPLPAG,
																						 REGPRODUTO,
																						 REGPRECOS,
																						 REGFILIAL,
																						 VSCODDISTRIB);
											ELSE
												GVET_REGITEMNOTA(J).VALIDO := TRUE;

											END IF;

											IF GVET_REGITEMNOTA(J).QTTROCA > 0 THEN

												PROC_VALIDARITEMNOTATROCA(GVET_REGITEMNOTA(J),
																									GVET_REGNOTA(I),
																									REGCLIENTE,
																									REGRCA,
																									REGREGIAO,
																									REGPLPAG,
																									REGFILIAL,
																									REGPRECOTROCA,
																									VSCODDISTRIB);

											END IF;

										END IF;
									END IF;

									IF GVET_REGITEMNOTA(J).VALIDO = TRUE THEN

										IF GVET_REGITEMNOTA(J).QT > 0 THEN

											IF VSCODDISTRIB IS NULL THEN
												VSCODDISTRIB := REGPRODUTO.CODDISTRIB;
											END IF;

											VNCONTITEMATUAL := VNCONTITEMATUAL + 1;

											-- calcula o percentual de desconto
											GVET_REGITEMNOTA(J).PERDESC := FUNC_CALCULARPERDESCITEM(REGPRODUTO.PTABELA,
																																							GVET_REGITEMNOTA(J)
																																							.PVENDA);

											VNPERLUC := ((GVET_REGITEMNOTA(J)
																	.PVENDA - GVET_REGITEMNOTA(J).VLCUSTOFIN) /
																	GVET_REGITEMNOTA(J).PVENDA) * 100;

											-- busca percentual de comissao
											VSMENSAGEM_COMISS := NULL;
											GVET_REGITEMNOTA(J).PERCOM := FUNCOESVENDAS.BUSCAPERCOMISSAO(REGRCA.TIPOVEND,
																																									 REGPRODUTO.PCOMINT1,
																																									 REGPRODUTO.PCOMEXT1,
																																									 REGPRODUTO.PCOMREP1,
																																									 GREGPCCONSUM.USACOMISSAOPORCLIENTE,
																																									 REGCLIENTE.PERCOMCLI,
																																									 GREGPCCONSUM.USACOMISSAOPORRCA,
																																									 GREGPCCONSUM.COMISSAORCATIPOVENDA,
																																									 REGPLPAG.TIPOVENDA,
																																									 REGRCA.PERCENT,
																																									 REGRCA.PERCENT2,
																																									 GREGPCCONSUM.USACOMISSAOPORLINHAPROD,
																																									 REGPLPAG.CODPLPAG,
																																									 REGPRODUTO.CODLINHAPROD,
																																									 GVET_REGITEMNOTA(J)
																																									 .PERDESC,
																																									 GVET_REGNOTA(I)
																																									 .CODUSUR,
																																									 REGCLIENTE.NUMREGIAO,
																																									 REGPRODUTO.CODSEC,
																																									 REGPRODUTO.CODEPTO,
																																									 GVET_REGITEMNOTA(J)
																																									 .CODPROD,
																																									 VNPERLUC,
																																									 GREGPCCONSUM.ORDEMAVALIACAOCOMISSAORCA,
																																									 GVET_REGITEMNOTA(J)
																																									 .LETRACOMISS,
																																									 VSMENSAGEM_COMISS);

											IF VSMENSAGEM_COMISS IS NOT NULL THEN
												PROC_REGISTRALOG(GVET_REGNOTA(I).NUMPED,
																				 GVET_REGNOTA(I).NUMPEDRCA,
																				 GVET_REGITEMNOTA(J).CODPROD,
																				 GVET_REGITEMNOTA(J).CODAUXILIAR,
																				 NULL,
																				 NULL,
																				 NULL,
																				 NULL,
																				 GVET_REGITEMNOTA(J).CODUSUR,
																				 NULL,
																				 GVET_REGITEMNOTA(J).CANCELADA,
																				 '12',
																				 VSMENSAGEM_COMISS,
																				 NULL);
											END IF;

											IF REGPRECOS.CODICMTABPF IS NULL THEN
												VBCODICMTABPF := TRUE;
											ELSE
												VBCODICMTABPF := FALSE;
											END IF;

											-- calculo dos custos
											FUNCOESVENDAS.CALCULARCMV(GREGPCCONSUM.ABATERIMPOSTOSCOMISSAORCA,
																								GREGPCCONSUM.APLICARINDICECMV,
																								GREGPCCONSUM.INCLUIRCOMISSAOSUGPVENDACMV,
																								NVL(GREGPCCONSUM.TXVENDA, 0),
																								REGCLIENTE.TIPOFJ,
																								REGCLIENTE.UTILIZAIESIMPLIFICADA,
																								REGCLIENTE.IEENT,
																								REGPRODUTO.FRETEESPECIAL,
																								REGREGIAO.PERFRETETERCEIROS,
																								REGREGIAO.PERFRETEESPECIAL,
																								REGPRECOS.CUSTOFIN,
																								REGPRECOS.CUSTOREAL,
																								REGPRECOS.PERDESCCUSTO,
																								REGPRECOS.CODICMTAB,
																								VBCODICMTABPF,
																								REGPRECOS.CODICMTABPF,
																								GVET_REGNOTA(I).PERCVENDA,
																								GVET_REGITEMNOTA(J).PVENDA,
																								GVET_REGITEMNOTA(J).PERCOM,
																								GVET_REGITEMNOTA(J).ST,
																								0,
																								0,
																								REGCLIENTE.CONTRIBUINTE,
																								0,
																								0 --nvl(gvet_Regitem(j).VLREDPVENDASIMPLESNA,0)
																							 ,
																								REGCLIENTE.CONSUMIDORFINAL,
																								NVL(GREGPCCONSUM.CONSIDERAISENTOSCOMOPF,
																										'N'),
																								GVET_REGITEMNOTA(J)
																								.PERFRETECMV,
																								GVET_REGITEMNOTA(J)
																								.CUSTOFINEST,
																								GVET_REGITEMNOTA(J).TXVENDA,
																								GVET_REGITEMNOTA(J)
																								.PERDESCCUSTO,
																								GVET_REGITEMNOTA(J)
																								.CODICMTAB,
																								GVET_REGITEMNOTA(J)
																								.VLCUSTOREAL,
																								GVET_REGITEMNOTA(J)
																								.VLCUSTOFIN,
																								GVET_REGITEMNOTA(J)
																								.VLDESCCUSTOCMV,
                                                GVET_REGNOTA(I).CODCLI);

										END IF;

										IF GVET_REGITEMNOTA(J).VALIDO = TRUE THEN

                      vsTIPOST := UPPER(FERRAMENTAS.VERIFICAR_TIPOST(regcliente.codcli,
                                                                   regprecos.codst));

                      IF (vsTIPOST = 'ST FONTE') THEN
                         GVET_REGITEMNOTA(J).origemst := 'F';
                      ELSIF (vsTIPOST = 'ST NORMAL') THEN
                         GVET_REGITEMNOTA(J).origemst := 'N';
                      END IF;

											-- insere item do pedido
											VNNUMSEQ := VNNUMSEQ + 1;
											GVET_REGITEMNOTA(J).NUMSEQ := VNNUMSEQ;
											VNTOTPESOPED := VNTOTPESOPED +
																			(REGPRODUTO.PESOBRUTO *
																			GVET_REGITEMNOTA(J).QT);
											VNTOTVOLUMEPED := VNTOTVOLUMEPED +
																				(REGPRODUTO.VOLUME *
																				GVET_REGITEMNOTA(J).QT);
											GVET_REGITEMNOTA(J).VALIDO := FUNC_INSERIRITEMNOTA(GVET_REGNOTA(I),
																																				 GVET_REGITEMNOTA(J),
																																				 REGPRECOS,
																																				 REGPRODUTO);
										END IF;
									END IF;
								END IF;
								-- IF gvet_regpedido (i).numpedrca = gvet_regitem (j).numpedrca
							EXCEPTION
								WHEN OTHERS THEN
									GVET_REGNOTA(I).VALIDO := FALSE;
									PROC_REGISTRALOG(GVET_REGNOTA(I).NUMPED,
																	 GVET_REGNOTA(I).NUMPEDRCA,
																	 GVET_REGITEMNOTA(J).CODPROD,
																	 GVET_REGITEMNOTA(J).CODAUXILIAR,
																	 NULL,
																	 NULL,
																	 NULL,
																	 NULL,
																	 GVET_REGITEMNOTA(J).CODUSUR,
																	 NULL,
																	 GVET_REGITEMNOTA(J).CANCELADA,
																	 '12',
																	 SQLCODE || '-' || SQLERRM || ';',
																	 NULL);
									EXIT;
							END;
						END LOOP; -- FOR j IN 1 .. vncontitem

						FOR REG_COMBOS IN (SELECT DISTINCT PCPEDI.CODCOMBO,
                                               PCPEDI.CODPROD,
                                               PCPEDI.PVENDA,
                                               PCPEDI.PTABELA,
                                               PCPEDI.PBASERCA,
                                               PCPEDI.PERDESC,
                                               PCPEDI.QT,
                                               PCPEDI.NUMSEQ,
                                               PCPEDI.CODAUXILIAR
                                 FROM PCPEDI
                                WHERE NUMPED = GVET_REGNOTA(I).NUMPED
                                  AND CODCOMBO IS NOT NULL) LOOP

              IF NVL(REG_COMBOS.CODCOMBO,0) > 0 THEN

                PKG_CAMPANHACOMBO.INSERIRCOMBOCLI(GVET_REGNOTA(I).codfilial,
                                                  GVET_REGNOTA(I).numped,
                                                  REG_COMBOS.codprod,
                                                  GVET_REGNOTA(I).codcli,
                                                  REG_COMBOS.PERDESC,
                                                  REG_COMBOS.codcombo,
                                                  NULL,
                                                  REG_COMBOS.numseq,
                                                  REG_COMBOS.qt,
                                                  REG_COMBOS.CODAUXILIAR);
              END IF;

              VBVALIDODESCONTOCOMBO := FUNCOESVENDAS.VERIFICACAMPANHASDESCONTO(GVET_REGNOTA           (I)
                                                                               .NUMPED,
                                                                               GVET_REGNOTA           (I)
                                                                               .CODFILIAL,
                                                                               REGREGIAO.NUMREGIAO,
                                                                               GVET_REGNOTA           (I)
                                                                               .CODCLI,
                                                                               REGCLIENTE.CODATV1,
                                                                               REGCLIENTE.CODCLIPRINC,
                                                                               GVET_REGNOTA           (I)
                                                                               .CODUSUR,
                                                                               REGRCA.CODSUPERVISOR,
                                                                               REGRCA.CODDISTRIB,
                                                                               REGPLPAG.PERTXFIM,
                                                                               REG_COMBOS.CODCOMBO,
                                                                               VSMENSAGEMDESCONTOCOMBO,
                                                                               GVET_REGNOTA           (I)
                                                                               .CODPLPAG);

              IF VBVALIDODESCONTOCOMBO = TRUE
                THEN
                BEGIN
                  SELECT NVL(UTILIZACODPRODPRINC, 'N')
                    INTO VSUTILIZACODPRODPRINC
                    FROM PCDESCONTOC
                   WHERE CODIGO = REG_COMBOS.CODCOMBO;
                EXCEPTION
                  WHEN OTHERS THEN
                    VSUTILIZACODPRODPRINC := 'N';
                END;

                IF VSUTILIZACODPRODPRINC = 'S' THEN

                  FOR DADOS IN (SELECT PCDESCONTOI.CODPROD
                                  FROM PCDESCONTOI
                                 WHERE PCDESCONTOI.CODIGO =
                                       REG_COMBOS.CODCOMBO) LOOP
                    SELECT SUM(NVL(QT, 0))
                      INTO VNQTTOTAL
                      FROM PCPEDIFVMANIF
                     WHERE NUMPEDRCA = GVET_REGNOTA(I).NUMPEDRCA
                       AND CODUSUR = GVET_REGNOTA(I).CODUSUR
                       AND DTABERTURAPEDPALM = GVET_REGNOTA(I)
                          .DTABERTURAPEDPALM
                       AND CODPROD IN
                           (SELECT CODPROD
                              FROM PCPRODUT
                             WHERE PCPRODUT.CODPRODPRINC =
                                   REG_COMBOS.CODPROD);
                    IF VNQTTOTAL > 0 THEN
                      EXIT;
                    END IF;
                  END LOOP;
                ELSE
                  SELECT SUM(NVL(QT, 0))
                    INTO VNQTTOTAL
                    FROM PCPEDIFVMANIF
                   WHERE NUMPEDRCA = GVET_REGNOTA(I).NUMPEDRCA
                     AND CODUSUR = GVET_REGNOTA(I).CODUSUR
                     AND DTABERTURAPEDPALM = GVET_REGNOTA(I)
                        .DTABERTURAPEDPALM
                     AND CODPROD = REG_COMBOS.CODPROD;
                END IF;

                BEGIN -- Campanha MIQ e MQT
                  SELECT NAODEBITCCRCA,
                         CREDITAPOLITICA,
                         Alterarptabela,
                         PERDESC
                    INTO P_VSNAODEBITACCRCA,
                         P_VSCREDITACCRCA,
                         p_vsAlterarPtabela,
                         P_VDPERCDESCPOLITICA
                    FROM (SELECT NVL(C.NAODEBITCCRCA, 'S') NAODEBITCCRCA,
                                 NVL(C.CREDITAPOLITICA, 'N') CREDITAPOLITICA,
                                 NVL(C.Alterarptabela, 'N') Alterarptabela,
                                 NVL(I.PERDESC, 0) PERDESC
                            FROM PCDESCONTOC C, PCDESCONTOI I
                           WHERE C.CODIGO = I.CODIGO
                             AND C.CODIGO = REG_COMBOS.CODCOMBO
                             AND ((I.CODPROD = REG_COMBOS.CODPROD AND
                                 NVL(C.UTILIZACODPRODPRINC, 'N') = 'N') OR

                                 (I.CODPROD =
                                 (SELECT PCPRODUT.CODPRODPRINC
                                      FROM PCPRODUT
                                     WHERE CODPROD = REG_COMBOS.CODPROD) AND
                                 NVL(C.UTILIZACODPRODPRINC, 'N') = 'S'))
                             AND CASE C.TIPOCAMPANHA
                                   WHEN 'MIQ' THEN
                                    DECODE(VNQTTOTAL,
                                           0,
                                           REG_COMBOS.QT,
                                           VNQTTOTAL)
                                   ELSE
                                    999999
                                 END BETWEEN I.QTMINIMA AND
                                 DECODE(NVL(I.QTMAXIMA, 0),
                                        0,
                                        999999,
                                        I.QTMAXIMA)
                           ORDER BY NVL(I.PERDESC, 0) DESC)
                   WHERE ROWNUM = 1;

                EXCEPTION
                  WHEN OTHERS THEN -- Campanha SQP
                    begin
                      SELECT NVL(C.NAODEBITCCRCA, 'S'),
                             NVL(C.CREDITAPOLITICA, 'N'),
                             NVL(C.ALTERARPTABELA, 'N'),
                             C.TIPOCAMPANHA
                          INTO P_VSNAODEBITACCRCA,
                               P_VSCREDITACCRCA,
                               p_vsAlterarPtabela,
                               p_TipoCampanhaCombo
                          FROM PCDESCONTOC C
                          WHERE C.CODIGO = REG_COMBOS.CODCOMBO;

                    EXCEPTION
                      WHEN OTHERS THEN
                        P_VSNAODEBITACCRCA   := 'S';
                        P_VSCREDITACCRCA     := 'N';
                        p_vsAlterarPtabela   := 'N';
                        P_VDPERCDESCPOLITICA := 0;
                    end;
                END;

                P_VDPERCDESCPOLITICA :=   PKG_CAMPANHACOMBO.BUSCADESCONTO(GVET_REGNOTA(I).CODFILIAL,
                                                   REG_COMBOS.CODPROD,
                                                   GVET_REGNOTA(I).CODCLI,
                                                   GVET_REGNOTA(I).NUMPED,
                                                   0,
                                                   'N',
                                                   REG_COMBOS.CODCOMBO);

                IF p_vsAlterarPtabela = 'S'
                  OR ((p_vsAlterarPtabela) = 'S' and (p_TipoCampanhaCombo = 'SQP'))THEN
                  REG_COMBOS.PTABELA  := REG_COMBOS.PVENDA;
                  REG_COMBOS.PBASERCA := REG_COMBOS.PTABELA;
                ELSIF (P_VSNAODEBITACCRCA = 'S') AND
                      (P_VSCREDITACCRCA = 'S') THEN
                  REG_COMBOS.PBASERCA := REG_COMBOS.PTABELA *
                                         (1 - (P_VDPERCDESCPOLITICA / 100));
                ELSIF (P_VSNAODEBITACCRCA = 'S') THEN
                  IF (REG_COMBOS.PERDESC < 0) THEN
                    REG_COMBOS.PBASERCA := REG_COMBOS.PTABELA;
                  ELSIF (REG_COMBOS.PERDESC > 0) THEN
                    REG_COMBOS.PBASERCA := REG_COMBOS.PVENDA;
                  END IF;
                ELSE
                  REG_COMBOS.PBASERCA := REG_COMBOS.PTABELA;
                END IF;

                UPDATE PCPEDI
                   SET PTABELA  = REG_COMBOS.PTABELA,
                       PBASERCA = REG_COMBOS.PBASERCA
                 WHERE NUMPED = GVET_REGNOTA(I).NUMPED
                   AND CODCOMBO = REG_COMBOS.CODCOMBO
                   AND CODPROD = REG_COMBOS.CODPROD
                   AND NUMSEQ  = REG_COMBOS.NUMSEQ;

              ELSE

                GVET_REGNOTA(I).VALIDO := FALSE;

                FOR REG IN (SELECT CODPROD, QT
                              FROM PCPEDI
                             WHERE NUMPED = GVET_REGNOTA(I).NUMPED
                               AND CODCOMBO = REG_COMBOS.CODCOMBO) LOOP

                  DELETE FROM PCPEDI
                   WHERE NUMPED = GVET_REGNOTA(I).NUMPED

                     AND CODCOMBO = REG_COMBOS.CODCOMBO
                     AND CODPROD = REG.CODPROD;

                  PROC_REGISTRALOG(GVET_REGNOTA(I).NUMPED,
                                   GVET_REGNOTA(I).NUMPEDRCA,
                                   REG.CODPROD,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   GVET_REGNOTA(I).CODUSUR,
                                   NULL,
                                   GVET_REGNOTA(I).CANCELADA,
                                   '12',
                                   'Prod: ' || REG.CODPROD ||
                                   ' cortado por fazer parte do combo : ' ||
                                   REG_COMBOS.CODCOMBO ||
                                   ' que foi rejeitado.' || ';',
                                   NULL);
                END LOOP;

                PROC_REGISTRALOG(GVET_REGNOTA(I).NUMPED,
                                 GVET_REGNOTA(I).NUMPEDRCA,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 GVET_REGNOTA(I).CODUSUR,
                                 NULL,
                                 GVET_REGNOTA(I).CANCELADA,
                                 '11',
                                 VSMENSAGEMDESCONTOCOMBO || ';',
                                 NULL);

              END IF;

            END LOOP;

						-- verifica se ha itens no pedido
						SELECT COUNT(*),
									 SUM(PCPEDI.QT * PCPEDI.PVENDA),
									 SUM(PCPEDI.QT * PCPEDI.PTABELA),
									 SUM(PCPEDI.QT * PCPEDI.PBASERCA),
									 SUM(PCPEDI.QT * PCPEDI.VLCUSTOCONT),
									 SUM(PCPEDI.QT * PCPEDI.VLCUSTOFIN),
									 SUM(PCPEDI.QT * PCPEDI.VLCUSTOREAL),
									 SUM(PCPEDI.QT * PCPEDI.VLCUSTOREP),
                   SUM(DECODE(NVL(PCPEDI.BONIFIC,'N'), 'N', 0, PCPEDI.QT) * PCPEDI.PVENDA),
                   SUM(PCPEDI.QT * PCPEDI.PVENDA) -
                   NVL(SUM(DECODE(NVL(PCPEDI.BONIFIC,'N'), 'N', 0, PCPEDI.QT) * PCPEDI.PVENDA),0)
							INTO VNCONTITENSVALIDOS,
									 VNVLTOTNOTA,
									 VNVLTOTTAB,
									 VNVLTOTBASERCA,
									 VNVLCUSTOCONTPED,
									 VNVLCUSTOFINPED,
									 VNVLCUSTOREALPED,
									 VNVLCUSTOREPPED,
                   VLTOTALBNF,
                   VNVLATEND
							FROM PCPEDI
						 WHERE PCPEDI.NUMPED = GVET_REGNOTA(I).NUMPED;

            vsValidaValorMinVendaBalcao := ferramentas.F_BUSCARPARAMETRO_ALFA('VALIDAVLMINVENDABALCAO', GVET_REGNOTA(I).CODFILIAL, 'N');

            IF vsValidaValorMinVendaBalcao = 'S'
                THEN

              IF VNVLATEND < ferramentas.F_BUSCARPARAMETRO_NUM('VLMINVENDAFV',GVET_REGNOTA(I).CODFILIAL, 0)
                  THEN
                      GVET_REGNOTA(I).VALIDO := FALSE;
                      PROC_REGISTRALOG(GVET_REGNOTA(I).NUMPED,
                                       GVET_REGNOTA(I).NUMPEDRCA,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       GVET_REGNOTA(I).CODUSUR,
                                       NULL,
                                       GVET_REGNOTA(I).CANCELADA,
                                       '11',
                                       'Valor do pedido menor do que o permitido para a filial(Parâmetros 1546/2326) : '
                                       || ' Valor do Pedido: ' || VNVLATEND || ' Valor mínimo permitido(Parâmetro 2833): ' || ferramentas.F_BUSCARPARAMETRO_NUM('VLMINVENDAFV',GVET_REGNOTA(I).CODFILIAL, 0) ||';',
                                       NULL);
              END IF;
            END IF;

						IF VNCONTITENSVALIDOS = 0 THEN

							SELECT COUNT(*)
								INTO VNCONTITENSTROCA
								FROM PCTROCAFVMANIF P
							 WHERE P.NUMPEDRCA = GVET_REGNOTA(I).NUMPEDRCA
								 AND P.CODCLI = GVET_REGNOTA(I).CODCLI
								 AND P.CODUSUR = GVET_REGNOTA(I).CODUSUR;

							IF VNCONTITENSTROCA = 0 THEN

								GVET_REGNOTA(I).VALIDO := FALSE;
								PROC_REGISTRALOG(GVET_REGNOTA(I).NUMPED,
																 GVET_REGNOTA(I).NUMPEDRCA,
																 NULL,
																 NULL,
																 NULL,
																 NULL,
																 NULL,
																 NULL,
																 GVET_REGNOTA(I).CODUSUR,
																 NULL,
																 GVET_REGNOTA(I).CANCELADA,
																 '11',
																 'Nenhum item gravado;',
																 NULL);
							END IF;
						END IF;

            -- Validação Saldo RCA ---------------------------------------------------------------------------
            VNVLDISPONIVEL := PC_PKG_CONTROLARSALDORCA.CCRCA_CHECAR_DISPONIVEL_ATUAL(GVET_REGNOTA(I).CODUSUR);
            VNVLSALDOPED := 0; -- 1091.018517.2016

            SELECT SUM(
                   PC_PKG_CONTROLARSALDORCA.CCRCA_SALDO_ITEM(GREGPCCONSUM.USACREDRCA,
                                                             GVET_REGNOTA(I)
                                                             .USADEBCREDRCA,
                                                             'N',
                                                             GVET_REGNOTA(I)
                                                             .ORIGEMPED,
                                                             GREGPCCONSUM.BONIFICALTDEBCREDRCA,
                                                             GREGPCCONSUM.TROCAALTDEBCREDRCA,
                                                             GREGPCCONSUM.CRMALTDEBCREDRCA,
                                                             GREGPCCONSUM.BROKERALTDEBCREDRCA,
                                                             GREGPCCONSUM.TIPOMOVCCRCA,
                                                             14,
                                                             GVET_REGNOTA(I)
                                                             .BRINDE,
                                                             GVET_REGNOTA(I)
                                                             .CODUSUR,
                                                             'V',
                                                             PCPEDI.PVENDA,
                                                             PCPEDI.PTABELA,
                                                             PCPEDI.PBASERCA,
                                                             (PCPEDI.QT -
                                                             DECODE(GVET_REGNOTA(I)
                                                                     .POSICAO,
                                                                     'B',
                                                                     0,
                                                                     NVL(PCPEDI.QTFALTA,
                                                                         0))),
                                                             GVET_REGNOTA(I)
                                                             .BRINDE,
                                                             PCPEDI.MOVIMENTACONTACORRENTERCA)) SALDO
              INTO VNVLSALDOPED
              FROM PCPEDI
             WHERE NUMPED = GVET_REGNOTA(I).NUMPED;

            IF (VNVLDISPONIVEL + VNVLSALDOPED) < 0 THEN

								PROC_REGISTRALOG(GVET_REGNOTA(I).NUMPED,
																 GVET_REGNOTA(I).NUMPEDRCA,
																 NULL,
																 NULL,
																 NULL,
																 NULL,
																 NULL,
																 NULL,
																 GVET_REGNOTA(I).CODUSUR,
																 NULL,
																 GVET_REGNOTA(I).CANCELADA,
																 '11',
																 'Rca sem credito disponivel. Todo o pedido será rejeitado' || ';',
																 NULL);

								GVET_REGNOTA(I).VALIDO := FALSE;

            END IF;
            -- Fim validação Saldo RCA ------------------------------------------------------------

						-- verifica se ha itens no pedido
						SELECT COUNT(*),
									 SUM(PCPEDI.QT * PCPEDI.PVENDA),
									 SUM(PCPEDI.QT * PCPEDI.PTABELA),
									 SUM(PCPEDI.QT * PCPEDI.PBASERCA),
									 SUM(PCPEDI.QT * PCPEDI.VLCUSTOCONT),
									 SUM(PCPEDI.QT * PCPEDI.VLCUSTOFIN),
									 SUM(PCPEDI.QT * PCPEDI.VLCUSTOREAL),
									 SUM(PCPEDI.QT * PCPEDI.VLCUSTOREP),
                   NVL(SUM(DECODE(NVL(PCPEDI.BONIFIC,'N'), 'N', 0, PCPEDI.QT) * PCPEDI.PVENDA),0)
							INTO VNCONTITENSVALIDOS,
									 VNVLTOTNOTA,
									 VNVLTOTTAB,
									 VNVLTOTBASERCA,
									 VNVLCUSTOCONTPED,
									 VNVLCUSTOFINPED,
									 VNVLCUSTOREALPED,
									 VNVLCUSTOREPPED,
                   VLTOTALBNF
							FROM PCPEDI
						 WHERE PCPEDI.NUMPED = GVET_REGNOTA(I).NUMPED;

						IF VNCONTITENSVALIDOS = 0 THEN

							SELECT COUNT(*)
								INTO VNCONTITENSTROCA
								FROM PCTROCAFVMANIF P
							 WHERE P.NUMPEDRCA = GVET_REGNOTA(I).NUMPEDRCA
								 AND P.CODCLI = GVET_REGNOTA(I).CODCLI
								 AND P.CODUSUR = GVET_REGNOTA(I).CODUSUR;

							IF VNCONTITENSTROCA = 0 THEN

								GVET_REGNOTA(I).VALIDO := FALSE;
								PROC_REGISTRALOG(GVET_REGNOTA(I).NUMPED,
																 GVET_REGNOTA(I).NUMPEDRCA,
																 NULL,
																 NULL,
																 NULL,
																 NULL,
																 NULL,
																 NULL,
																 GVET_REGNOTA(I).CODUSUR,
																 NULL,
																 GVET_REGNOTA(I).CANCELADA,
																 '11',
																 'Nenhum item gravado;',
																 NULL);
							ELSE

								PROC_REGISTRALOG(GVET_REGNOTA(I).NUMPED,
																 GVET_REGNOTA(I).NUMPEDRCA,
																 NULL,
																 NULL,
																 NULL,
																 NULL,
																 NULL,
																 NULL,
																 GVET_REGNOTA(I).CODUSUR,
																 NULL,
																 GVET_REGNOTA(I).CANCELADA,
																 '11',
																 'Gravada apenas Troca;',
																 NULL);

							END IF;
						END IF;

            --HIS.02651.2015
            BEGIN
              FOR DADOS IN (SELECT I.NUMPED,
                                   I.CODPROD,
                                   I.NUMSEQ,
                                   I.QT
                              FROM PCPEDI I
                             WHERE I.NUMPED = GVET_REGNOTA(I).NUMPED)
              LOOP
                PRC_MED_VALIDA_CONTROLE_VENDA('G',
                                              GVET_REGNOTA(I).CODCLI,
                                              REGCLIENTE.TIPOFJ,
                                              DADOS.CODPROD,
                                              DADOS.QT,
                                              DADOS.NUMPED,
                                              DADOS.NUMSEQ,
                                              VSPODECOMPRAR,
                                              VSMSGTEMP,
                                              VNQTDTEMP);

                IF VSPODECOMPRAR = 'N' THEN
                  GVET_REGNOTA(I).VALIDO := FALSE;
                  PROC_REGISTRALOG(GVET_REGNOTA(I).NUMPED,
                                   GVET_REGNOTA(I).NUMPEDRCA,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   GVET_REGNOTA(I).CODUSUR,
                                   NULL,
                                   GVET_REGNOTA(I).CANCELADA,
                                   '11',
                                   'Existe controle de venda ' || CHR(13) || VSMSGTEMP,
                                   NULL);
                  EXIT;
                END IF;
              END LOOP;
            EXCEPTION
              WHEN OTHERS THEN
                PROC_REGISTRALOG(GVET_REGNOTA(I).NUMPED,
                                 GVET_REGNOTA(I).NUMPEDRCA,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 GVET_REGNOTA(I).CODUSUR,
                                 NULL,
                                 GVET_REGNOTA(I).CANCELADA,
                                 '11',
                                 'Erro ao validar controle de venda ;' || SQLCODE || '-' ||
                                 SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ';',
                                 NULL);
               GVET_REGNOTA(I).VALIDO      := FALSE;
            END;
            -- FIM HIS.02651.2015

            --VEN-817
            SELECT SUM(ROUND(NVL(PCPEDI.QT, 0) * NVL(PCPEDI.PVENDA, 0), 2))
              INTO TOTVENDABONIFICMES
              FROM PCPEDI, PCPEDC
             WHERE PCPEDC.NUMPED = PCPEDI.NUMPED
               AND PCPEDC.DTCANCEL IS NULL
               AND TO_CHAR(PCPEDC.DATA,'MM/YYYY') = TO_CHAR(TRUNC(SYSDATE),'MM/YYYY')
               AND PCPEDC.CODFILIAL = GVET_REGNOTA(I).CODFILIAL
               AND PCPEDC.CONDVENDA IN (1, 5, 11, 14)
               AND DECODE(PCPEDC.CONDVENDA, 1, NVL(PCPEDI.BONIFIC,'N'), 14, NVL(PCPEDI.BONIFIC,'N'), 'F') <> 'N'
               AND PCPEDC.NUMPED <> GVET_REGNOTA(I).NUMPED;

            IF (regfilial.VLMAXVENDABONIFICMES > 0) AND
               (regfilial.VLMAXVENDABONIFICMES < (TOTVENDABONIFICMES + VLTOTALBNF)) THEN
              PROC_REGISTRALOG(GVET_REGNOTA(I).NUMPED,
                               GVET_REGNOTA(I).NUMPEDRCA,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               GVET_REGNOTA(I).CODUSUR,
                               NULL,
                               GVET_REGNOTA(I).CANCELADA,
                               '11',
                               'SOMA DOS PEDIDOS BONIFICADOS COM PEDIDO ATUAL, ULTRAPASSA O VALOR PARAMETRIZADO DE VENDAS BONIFICADAS NO MÊS',
                               NULL);
               GVET_REGNOTA(I).VALIDO      := FALSE;
            END IF;

            --fim VEN-817
						IF GVET_REGNOTA(I).VALIDO = TRUE THEN

							IF VNCONTITENSVALIDOS > 0 THEN

								GVET_REGNOTA(I).NUMITENS := VNCONTITENSVALIDOS;
								GVET_REGNOTA(I).VALIDO := FUNC_INSERIRNOTA(GVET_REGNOTA(I),
																													 REGPLPAG,
																													 REGRCA,
																													 REGCLIENTE,
																													 REGREGIAO,
																													 VNCONTITENSVALIDOS,
																													 VNVLTOTNOTA,
																													 VNVLTOTTAB,
																													 VNTOTPESOPED,
																													 VNTOTVOLUMEPED,
																													 VNVLCUSTOCONTPED,
																													 VNVLCUSTOFINPED,
																													 VNVLCUSTOREALPED,
																													 VNVLCUSTOREPPED,
                                                           VLTOTALBNF,
																													 VSCODDISTRIB,
																													 REGFILIAL);

                IF FUNC_VALIDAR_MULTIPLOS_PLANOS(GVET_REGNOTA(I).NUMPEDRCA
                                                ,GVET_REGNOTA(I).CODUSUR
                                                ,GVET_REGNOTA(I).NUMPED
                                                ,VSMSGTEMP) = FALSE
                THEN
                  PROC_REGISTRALOG(GVET_REGNOTA(I).NUMPED,
                                 GVET_REGNOTA(I).NUMPEDRCA,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 GVET_REGNOTA(I).CODUSUR,
                                 NULL,
                                 GVET_REGNOTA(I).CANCELADA,
                                 '11',
                                 VSMSGTEMP,
                                 NULL);
                  GVET_REGNOTA(I).VALIDO      := FALSE;
                END IF;

              IF (
                 (nvl(gregpcconsum.verificalimcredcodcobd, 'S') = 'S' AND ((GVET_REGNOTA(I).codcob IN ('D', 'DH', 'CAR'))
                 OR (isCobrancaCartao(GVET_REGNOTA(I).codcob))))
                 OR ((GVET_REGNOTA(I).codcob NOT IN ('D', 'DH', 'CAR')) OR NOT(isCobrancaCartao(GVET_REGNOTA(I).codcob)))
                 )
                 AND
                 ferramentas.F_BUSCARPARAMETRO_ALFA('VALIDALIMCREDTV14FV', '99', 'N') = 'S'
              THEN

                SELECT SUM(I.QT * I.PVENDA) into VNVLATEND
                  FROM PCPEDI I
                 WHERE I.NUMPED = GVET_REGNOTA(I).numped;

                -- Caso ultrapasse o limite de cred, grava o pedido como bloqueado.
                IF NOT func_existelimitecliente(GVET_REGNOTA(I),
                                                REGCLIENTE,
                                                REGFILIAL,
                                                VNVLATEND,
                                                vnsaldodisponivel)
                THEN

                    GVET_REGNOTA(I).VALIDO := FALSE;
                        PROC_REGISTRALOG(GVET_REGNOTA(I).NUMPED,
                                         GVET_REGNOTA(I).NUMPEDRCA,
                                         NULL,
                                         NULL,
                                         NULL,
                                         NULL,
                                         NULL,
                                         NULL,
                                         GVET_REGNOTA(I).CODUSUR,
                                         NULL,
                                         GVET_REGNOTA(I).CANCELADA,
                                         '11',
                                         'Pedido ultrapassa credito disponivel do cliente.'
                                         || ' Valor Atendido do Pedido: ' || VNVLATEND || 'Credito disponivel: ' || vnsaldodisponivel || ';',
                                         NULL);

                END IF;

              END IF;

								IF GVET_REGNOTA(I).VALIDO = TRUE THEN

									FOR REG_ITENS IN (SELECT CODPROD,
																					 NUMSEQ,
																					 QT,
																					 PC_PKG_CONTROLARSALDORCA.CCRCA_SALDO_ITEM(GREGPCCONSUM.USACREDRCA,
																																										 GVET_REGNOTA(I)
																																										 .USADEBCREDRCA,
																																										 'N',
																																										 GVET_REGNOTA(I)
																																										 .ORIGEMPED,
																																										 GREGPCCONSUM.BONIFICALTDEBCREDRCA,
																																										 GREGPCCONSUM.TROCAALTDEBCREDRCA,
																																										 GREGPCCONSUM.CRMALTDEBCREDRCA,
																																										 GREGPCCONSUM.BROKERALTDEBCREDRCA,
																																										 GREGPCCONSUM.TIPOMOVCCRCA,
																																										 14,
																																										 GVET_REGNOTA(I)
																																										 .BRINDE,
																																										 GVET_REGNOTA(I)
																																										 .CODUSUR,
																																										 'V',
																																										 PCPEDI.PVENDA,
																																										 PCPEDI.PTABELA,
																																										 PCPEDI.PBASERCA,
																																										 (PCPEDI.QT -
																																										 DECODE(GVET_REGNOTA(I)
																																														 .POSICAO,
																																														 'B',
																																														 0,
																																														 NVL(PCPEDI.QTFALTA,
																																																 0))),
																																										 GVET_REGNOTA(I)
																																										 .BRINDE,
																																										 PCPEDI.MOVIMENTACONTACORRENTERCA) SALDO
																			FROM PCPEDI
																		 WHERE NUMPED = GVET_REGNOTA(I).NUMPED
																		 ORDER BY SALDO DESC) LOOP

										VBSALDORCA := PC_PKG_CONTROLARSALDORCA.CCRCA_INCLUIR_ITEM_PEDIDO(8888,
																																										 2596,
																																										 GVET_REGNOTA(I)
																																										 .CODUSUR,
																																										 GVET_REGNOTA(I)
																																										 .NUMPED,
																																										 REG_ITENS.CODPROD,
																																										 REG_ITENS.NUMSEQ);
									END LOOP;

									COMMIT;

									--tarefa 194518

									IF REGFILIAL.SEPARARPRODCOMST = 'S' THEN

										FOR REG IN (SELECT NUMPED
																	FROM PCPEDC P
																 WHERE P.NUMPEDRCA = GVET_REGNOTA(I)
																.NUMPEDRCA
																	 AND P.DTABERTURAPEDPALM = GVET_REGNOTA(I)
																.DTABERTURAPEDPALM
																	 AND P.CODUSUR = GVET_REGNOTA(I)
																.CODUSUR
																	 AND P.CODCLI = GVET_REGNOTA(I)
																.CODCLI) LOOP

											PRC_GERARPEDIDOITEMCOMST(REG.NUMPED,
																							 VNPEDIDORESTST,
																							 VSMENSAGEMRESTST);

											IF VSMENSAGEMRESTST IS NOT NULL THEN

												PROC_REGISTRALOG(GVET_REGNOTA(I).NUMPED,
																				 GVET_REGNOTA(I).NUMPEDRCA,
																				 NULL,
																				 NULL,
																				 NULL,
																				 NULL,
																				 NULL,
																				 NULL,
																				 GVET_REGNOTA(I).CODUSUR,
																				 NULL,
																				 GVET_REGNOTA(I).CANCELADA,
																				 '11',
																				 VSMENSAGEMRESTST || ';',
																				 NULL);
											END IF;

										END LOOP;

										COMMIT;

									END IF;

									GERARCARREGBALCAORESERVA(GVET_REGNOTA(I).NUMPED,
																					 GVET_REGNOTA(I).NUMPEDRCA,
																					 GVET_REGNOTA(I).CODUSUR,
																					 GVET_REGNOTA(I).CNPJ,
																					 GVET_REGNOTA(I)
																					 .DTABERTURAPEDPALM,
																					 GVET_REGNOTA(I).CANCELADA,
																					 VNNUMCAR);

									IF VNNUMCAR > 0 THEN

										GVET_REGNOTA(I).POSICAO := 'M';
									END IF;

									COMMIT;

									BEGIN

										SELECT PCEMPR.NOME_GUERRA
											INTO VSEMITENTE
											FROM PCEMPR
										 WHERE PCEMPR.MATRICULA = '8888';
									EXCEPTION
										WHEN OTHERS THEN
											VSEMITENTE := NULL;
									END;

                  commit;

                  ------------------HIS.02043.2016--------------------------
                  FOR PEDIDOS IN (
                  SELECT NUMPED
                      --INTO VNUMPEDTV13
                  FROM PCPEDC
                  WHERE NUMCAR = GVET_REGNOTA(I).NUMCARMANIF
                      AND CONDVENDA = 13)
                  LOOP

                	SELECT COUNT(*)
                  INTO VICONTADOR
                  FROM PCCONTROLENUMSERIE
                      WHERE NUMPED = PEDIDOS.NUMPED;



                  IF VICONTADOR > 0 THEN

                    FOR ITENS IN ( SELECT NUMSERIE,NUMSEQ
                                   FROM PCNUMEROSERIEFV
                                     WHERE CODPROD = GVET_REGITEMNOTA(I).CODPROD
                                     AND NUMPEDRCA = GVET_REGNOTA(I).NUMPEDRCA
                                     AND CODUSUR = GVET_REGNOTA(I).CODUSUR )
                    LOOP

                        CONTROLANUMEROSERIE.TRANSFERIR_NUMERO_SERIE(GVET_REGNOTA(I).NUMPED,
                                                                  ITENS.NUMSEQ,
                                                                    PEDIDOS.NUMPED,
                                                                  ITENS.NUMSEQ,
                                                                  GVET_REGITEMNOTA(I).CODPROD,
                                                                  ITENS.NUMSERIE,
                                                                  VSMENSAGEM_SERIE
                                                                  );
                    END LOOP;

                  END IF;

                  END LOOP;

                  ---------------HIS.02043.2016---------------------------

                  G_FORCA_ESPECIE_TP := TRUE;

									P_PC_FATU_FATURA_PEDIDO(NVL(GVET_REGNOTA(I).DATA,
																							TRUNC(SYSDATE)),
																					VSEMITENTE,
																					VNNUMCAR,
																					GVET_REGNOTA(I).CODCOB,
																					NVL(GVET_REGNOTA(I).DATA,
																							TRUNC(SYSDATE)),
																					NVL(GVET_REGNOTA(I).DATA,
																							TRUNC(SYSDATE)),
																					0,
																					0,
																					GVET_REGNOTA(I).CODFILIAL,
																					0,
																					0,
																					VSMENSAGEM_FATU);

                  G_FORCA_ESPECIE_TP := FALSE;

									IF UPPER(TRIM(VSMENSAGEM_FATU)) = 'OK' THEN

                    LOCK_PCMOV(GVET_REGNOTA(I).NUMPED);

										GVET_REGNOTA(I).POSICAO := 'F';

										 SELECT NUMTRANSVENDA
                      INTO VNNUMTRANSVENDA
                      FROM (SELECT NUMTRANSVENDA
                              FROM PCNFSAIDPREFAT
                             WHERE NUMPED = GVET_REGNOTA(I).NUMPED
                            UNION
                            SELECT NUMTRANSVENDA
                              FROM PCNFSAID
                             WHERE NUMPED = GVET_REGNOTA(I).NUMPED);

										IF VNNUMTRANSVENDA IS NOT NULL THEN

											FOR REG_ITEM IN (SELECT CODPROD,
																							PORIGINAL,
																							BASEICST,
																							ST,
																							PERCICM,
																							PERCBASERED,
                                              VLOUTROS
																				 FROM PCPEDI
																				WHERE NUMPED = GVET_REGNOTA(I).NUMPED) LOOP

											  SELECT NVL(VLOUTRASDESP, 0)
                          INTO VSOUTRASDESPSAID
                          FROM (SELECT VLOUTRASDESP
                                  FROM PCNFSAIDPREFAT
                                 WHERE NUMPED = GVET_REGNOTA(I).NUMPED
                                UNION
                                SELECT VLOUTRASDESP
                                  FROM PCNFSAID
                                 WHERE NUMPED = GVET_REGNOTA(I).NUMPED);


												UPDATE PCMOVPREFAT PCMOV
													 SET PCMOV.BASEICMS    = REG_ITEM.PORIGINAL,
															 PCMOV.BASEICST    = REG_ITEM.BASEICST,
															 PCMOV.ST          = REG_ITEM.ST,
															 PCMOV.PERCICM     = REG_ITEM.PERCICM,
															 PCMOV.PERCBASERED = DECODE(NVL(REG_ITEM.PERCBASERED, 0), 0, 100, NVL(REG_ITEM.PERCBASERED, 0)),
															 PCMOV.VLOUTROS    = DECODE(VSOUTRASDESPSAID,0,0, DECODE(REG_ITEM.VLOUTROS,0, PCMOV.VLOUTROS, REG_ITEM.VLOUTROS))
												 WHERE NUMTRANSVENDA = VNNUMTRANSVENDA
													 AND CODPROD = REG_ITEM.CODPROD;

                         UPDATE PCMOV
													 SET PCMOV.BASEICMS    = REG_ITEM.PORIGINAL,
															 PCMOV.BASEICST    = REG_ITEM.BASEICST,
															 PCMOV.ST          = REG_ITEM.ST,
															 PCMOV.PERCICM     = REG_ITEM.PERCICM,
															 PCMOV.PERCBASERED = DECODE(NVL(REG_ITEM.PERCBASERED, 0), 0, 100, NVL(REG_ITEM.PERCBASERED, 0)),
															 PCMOV.VLOUTROS    = DECODE(VSOUTRASDESPSAID,0,0, DECODE(REG_ITEM.VLOUTROS,0, PCMOV.VLOUTROS, REG_ITEM.VLOUTROS))
												 WHERE NUMTRANSVENDA = VNNUMTRANSVENDA
													 AND CODPROD = REG_ITEM.CODPROD;


											END LOOP;

                      --VEN-2207
                      FOR PEDIDO IN (SELECT N.CHAVENFE
                                       FROM PCNFSAID N
                                      WHERE N.NUMCAR = (SELECT C.NUMCAR
                                                          FROM PCNFSAIDPREFAT C
                                                         WHERE C.NUMTRANSVENDA = VNNUMTRANSVENDA
                                                          UNION ALL
                                                        SELECT C.NUMCAR
                                                          FROM PCNFSAID C
                                                         WHERE C.NUMTRANSVENDA = VNNUMTRANSVENDA)
                                        AND N.CHAVENFE is not null
                                        AND N.DTCANCEL is null
                                        AND N.CONDVENDA = 13)
                      LOOP
                        INSERT INTO PCDOCREFERENCIADO
                                    (CODIGO
                                    ,NUMTRANSACAO
                                    ,TIPO
                                    ,CHAVENFEREF)
                                  VALUES
                                    (DFSEQ_PCDOCREFERENCIADO.NEXTVAL
                                    ,VNNUMTRANSVENDA
                                    ,'S'
                                    ,PEDIDO.CHAVENFE);
                      END LOOP;
                      --VEN-2207

                      UPDATE PCNFSAIDPREFAT
                         SET ESPECIE = 'NE'
                       WHERE numtransvenda = VNNUMTRANSVENDA;

											COMMIT;

											SELECT BOLETO, CODBANCO
												INTO VSBOLETO, VNCODBANCO
												FROM PCCOB P
											 WHERE P.CODCOB = GVET_REGNOTA(I).CODCOB;

											IF VSBOLETO = 'S' AND
												 NVL(GVET_REGNOTA(I).GERARBOLETOAUTO, 'N') = 'S' AND
												 REGFILIAL.GERARBOLETOAUTOVENDAMANIF = 'S' THEN

                        IF nvl(GVET_REGNOTA(I).CODBANCOCM,0) <> 0 THEN
                          VNCODBANCO := GVET_REGNOTA(I).CODBANCOCM;
                        END IF;

												SELECT COUNT(*)
													INTO VICONTADOR
													FROM PCBANCO P
												 WHERE P.CODBANCO = VNCODBANCO;

                        Begin
                          select numdiasprotesto
                            into vnNumdiasProtesto
                           from pcbanco
                           where codbanco = vncodbanco;
                        EXCEPTION
                          WHEN OTHERS THEN
                            vnNumdiasProtesto := 0;
                        END;

												IF VICONTADOR > 0 THEN

													FOR REG IN (SELECT PREST, CODBANCO
																				FROM PCPREST P
																			 WHERE P.NUMTRANSVENDA =
																						 VNNUMTRANSVENDA) LOOP

														BEGIN
															--gera boleto
															PKG_DADOSBANCARIOS.P_GERADADOSBANCARIOS(GVET_REGNOTA(I).CODFILIAL,
																																			GVET_REGNOTA(I).CODCOB,
																																			NVL(REG.CODBANCO,VNCODBANCO),
																																			VNNUMTRANSVENDA,
                                                                      vnNumdiasProtesto,
																																			REG.PREST,
																																			'N', --PS_FILIALVIRTUAL     IN VARCHAR2 DEFAULT 'N',
																																			'N', --PS_UTILIZAVALORBRUTO IN VARCHAR2 DEFAULT 'N',
																																			'S' --PS_PRIMEIRAIMPRESSAO IN VARCHAR2 DEFAULT 'S'
																																			);
														EXCEPTION
															WHEN OTHERS THEN

																PROC_REGISTRALOG(GVET_REGNOTA(I).NUMPED,
																								 GVET_REGNOTA(I).NUMPEDRCA,
																								 NULL,
																								 NULL,
																								 NULL,
																								 NULL,
																								 NULL,
																								 NULL,
																								 GVET_REGNOTA(I).CODUSUR,
																								 NULL,
																								 GVET_REGNOTA(I).CANCELADA,
																								 '11',
																								 'Erro ao gerar boleto :' ||
																								 SQLCODE || ' - ' ||
																								 SQLERRM || ';',
																								 NULL);

														END;

													END LOOP;

												END IF;
											END IF;
										END IF;

									ELSE
										PROC_REGISTRALOG(GVET_REGNOTA(I).NUMPED,
																		 GVET_REGNOTA(I).NUMPEDRCA,
																		 NULL,
																		 NULL,
																		 NULL,
																		 NULL,
																		 NULL,
																		 NULL,
																		 GVET_REGNOTA(I).CODUSUR,
																		 NULL,
																		 GVET_REGNOTA(I).CANCELADA,
																		 '11',
																		 NVL(TRIM(VSMENSAGEM_FATU), 'ERRO AO FATURAR PEDIDO. INF. TEC.: VSMENSAGEM_FATU IS NULL') || ';',
																		 NULL);
									END IF;

									IF GVET_REGNOTA(I).CANCELADA = 'S' THEN

										PROC_CANCELANF(GVET_REGNOTA(I));
									END IF;

								ELSE
									ROLLBACK;

									DELETE FROM PCPEDI
									 WHERE PCPEDI.NUMPED = GVET_REGNOTA(I).NUMPED;

									DELETE FROM PCPEDC
									 WHERE PCPEDC.NUMPED = GVET_REGNOTA(I).NUMPED;

									COMMIT;
								END IF;
							END IF;

						ELSE
							-- rejeitado na validacao final do cabecalho
							ROLLBACK;

							DELETE FROM PCPEDI
							 WHERE PCPEDI.NUMPED = GVET_REGNOTA(I).NUMPED;

							COMMIT;
						END IF;

					END IF; -- pedido valido (gvet_regpedido (i).valido)
				EXCEPTION
					WHEN OTHERS THEN
						GVET_REGNOTA(I).VALIDO := FALSE;
						PROC_REGISTRALOG(GVET_REGNOTA(I).NUMPED,
														 GVET_REGNOTA(I).NUMPEDRCA,
														 NULL,
														 NULL,
														 NULL,
														 NULL,
														 NULL,
														 NULL,
														 GVET_REGNOTA(I).CODUSUR,
														 NULL,
														 GVET_REGNOTA(I).CANCELADA,
														 '11',
														 SQLCODE || '-' || SQLERRM || ';',
														 NULL);
						ROLLBACK;

						p_pc_cacela_nf(VSEMITENTE,
                           VNNUMTRANSVENDA,
                           'CANCELAMENTO AUTOMÁTICO IMPORTARPRONTAENTREGA',
                           VSMENSAGEM_FATU);

            IF VSMENSAGEM_FATU <> 'OK' THEN

              PROC_REGISTRALOG(GVET_REGNOTA(I).NUMPED,
                               GVET_REGNOTA(I).NUMPEDRCA,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               GVET_REGNOTA(I).CODUSUR,
                               NULL,
                               GVET_REGNOTA(I).CANCELADA,
                               '11',
                               'ERRO AO CANCELAR NF AUTOMATICAMENTE - ' || VSMENSAGEM_FATU,
                               NULL);

              DELETE FROM PCPEDI
               WHERE PCPEDI.NUMPED = GVET_REGNOTA(I).NUMPED;

              DELETE FROM PCPEDC
               WHERE PCPEDC.NUMPED = GVET_REGNOTA(I).NUMPED;

            END IF;

						COMMIT;
						EXIT;
				END;
			END LOOP; -- FOR i IN 1 .. vncontped
		END IF; -- vncontped > 0

		SELECT COUNT(*)
			INTO VICONT
			FROM PCRECEBIMENTOFV P
		 WHERE NVL(P.VERIFICADO, 1) = VNGTIPOLEITURA;

		IF VICONT <> 0 THEN

			VSREALIZARECEBFV := 'N';

			FOR REG IN (SELECT DISTINCT CODFILIAL
										FROM PCRECEBIMENTOFV P
									 WHERE NVL(P.VERIFICADO, 1) = VNGTIPOLEITURA) LOOP

				IF VSREALIZARECEBFV = 'N' THEN
					BEGIN
						SELECT NVL(P.VALOR, 'N')
							INTO VSREALIZARECEBFV
							FROM PCPARAMFILIAL P
						 WHERE P.CODFILIAL = REG.CODFILIAL
							 AND P.NOME = 'REALIZARECEBFV';
					EXCEPTION
						WHEN NO_DATA_FOUND THEN

							SELECT NVL(P.VALOR, 'N')
								INTO VSREALIZARECEBFV
								FROM PCPARAMFILIAL P
							 WHERE P.CODFILIAL = '99'
								 AND P.NOME = 'REALIZARECEBFV';

						WHEN OTHERS THEN
							VSREALIZARECEBFV := 'N';

					END;
				END IF;
			END LOOP;

			IF VSREALIZARECEBFV = 'S' THEN
				--tem pelo menos uma filial na taela de recebimentos que realiza o recebimento via FV
				--valida recebimento
				PROC_VALIDA_RECEBIMENTO;
			END IF;

		END IF;

	END PROC_PROCESSARNOTAS;

	PROCEDURE PROC_PROCESSARETORNOTAB(P_EXISTERRO IN BOOLEAN) IS

		VNCONTLOG            NUMBER;
		VICONTADOR           NUMBER;
		VNCONTNOTA           NUMBER;
		VNCONTITEMNOTA       NUMBER;
		VNQTATEND            PCPEDI.QT%TYPE;
		VSOBSERVACAOITEMNOTA VARCHAR2(32767) := NULL;
		VSOBSERVACAONOTA     VARCHAR2(32767) := NULL;

		VNNUMPED         PCPEDC.NUMPED%TYPE;
		VNNUMPEDRCA      PCPEDC.NUMPEDRCA%TYPE;
		VNCODCLI         PCPEDC.CODCLI%TYPE;
		VSCLIENTE        PCCLIENT.CLIENTE%TYPE;
		VNVLTOTAL        NUMBER;
		VNVLATEND        NUMBER;
		VNQTATENDPED     NUMBER;
		VNQTPEDIDA       NUMBER;
		VSOBSFINALPEDIDO VARCHAR2(1000);
		VSATENDIDO       PCPEDCFV.ATENDIDO%TYPE;
		VIEXISTECORTE    NUMBER;
		VNQTATENDTOTPED  NUMBER;
		VSCORTE          VARCHAR2(1);
		VICONTADORTROCA  NUMBER;

	BEGIN
		-- Retorna erros genericos tiporeg = 1
		IF P_EXISTERRO = TRUE THEN
			VNCONTLOG := GVETREGISTRALOG.COUNT;

			FOR I IN 1 .. VNCONTLOG LOOP
				IF GVETREGISTRALOG(I).TIPOREG = 1 THEN
					-- Gravar log de processamento de pedidos
					BEGIN
						INSERT INTO PCLOGFV
							(ARQUIVO,
							 CODCLI,
							 DATA,
							 MOTIVO,
							 NUMPED,
							 NUMPEDCLI,
							 NUMPEDRCA,
							 STATUS)
						VALUES
							('PCPEDCFVMANIF/PCPEDIFVMANIF',
							 NULL,
							 SYSDATE,
							 SUBSTR(REPLACE(REPLACE(GVETREGISTRALOG(I).ERRO, '#', ' '),
															';',
															CHR(13)),
											1,
											100),
							 NULL,
							 NULL,
							 NULL,
							 'N');

						COMMIT;
					EXCEPTION
						WHEN OTHERS THEN
							ROLLBACK;
					END;
				END IF;
			END LOOP;
		END IF;

		----------------- INICIO PRONTA ENTREGA --------------------------

		-- Retorna notas gravados com sucesso
		VNCONTNOTA := GVET_REGNOTA.COUNT;

		FOR I IN 1 .. VNCONTNOTA LOOP
			IF GVET_REGNOTA(I).VALIDO = TRUE THEN
				-- recupera critica do cabecalho.
				VNCONTLOG        := GVETREGISTRALOG.COUNT;
				VSOBSERVACAONOTA := '';

				FOR J IN 1 .. VNCONTLOG LOOP
					IF (GVETREGISTRALOG(J).TIPOREG = 11) AND
						 (GVETREGISTRALOG(J).NUMPED = GVET_REGNOTA(I).NUMPED) AND
						 (GVETREGISTRALOG(J).NUMPEDRCA = GVET_REGNOTA(I).NUMPEDRCA) AND
						 (GVETREGISTRALOG(J).CANCELADA = GVET_REGNOTA(I).CANCELADA) THEN
						VSOBSERVACAONOTA := VSOBSERVACAONOTA ||
																REPLACE(GVETREGISTRALOG(J).ERRO, '#', ' ');
					END IF;
				END LOOP;

				BEGIN

					--para o caso de erro no faturamento e ter que voltar o campo importado para 1
					SELECT COUNT(*)
						INTO VICONTADOR
						FROM PCPEDC
					 WHERE NUMPED = GVET_REGNOTA(I).NUMPED;

					SELECT COUNT(*)
						INTO VICONTADORTROCA
						FROM PCTROCAFVMANIF P
					 WHERE P.NUMPEDRCA = GVET_REGNOTA(I)
					.NUMPEDRCA
						 AND P.CODCLI = GVET_REGNOTA(I)
					.CODCLI
						 AND P.CODUSUR = GVET_REGNOTA(I).CODUSUR;

					IF VICONTADOR = 0 AND VICONTADORTROCA = 0 THEN

						--- atualiza cabecalho do pedido.
						UPDATE PCPEDCFVMANIF
							 SET IMPORTADO     = 1,
									 OBSERVACAO_PC = SUBSTR(VSOBSERVACAONOTA, 1, 300)
						 WHERE NUMPEDRCA = GVET_REGNOTA(I)
						.NUMPEDRCA
							 AND CODUSUR = GVET_REGNOTA(I)
						.CODUSUR
							 AND NVL(CANCELADA, 'N') = GVET_REGNOTA(I).CANCELADA;

					ELSE
						--- atualiza cabecalho do pedido.
						UPDATE PCPEDCFVMANIF
							 SET IMPORTADO     = 2,
									 NUMPED        = DECODE(VICONTADOR,
																					0,
																					NULL,
																					GVET_REGNOTA(I).NUMPED),
									 RETORNO       = 2,
									 POSICAO_ATUAL = GVET_REGNOTA(I).POSICAO,
									 OBSERVACAO_PC = 'NOTA IMPORTADA COM SUCESSO' || ' ' ||
																	 SUBSTR(VSOBSERVACAONOTA, 1, 300)
						 WHERE NUMPEDRCA = GVET_REGNOTA(I)
						.NUMPEDRCA
							 AND CODUSUR = GVET_REGNOTA(I)
						.CODUSUR
							 AND NVL(CANCELADA, 'N') = GVET_REGNOTA(I).CANCELADA;

					END IF;

					COMMIT;
				EXCEPTION
					WHEN OTHERS THEN
						ROLLBACK;
				END;

				-- Gravar log de processamento de pedidos
				BEGIN
					INSERT INTO PCLOGFV
						(ARQUIVO,
						 CODCLI,
						 DATA,
						 MOTIVO,
						 NUMPED,
						 NUMPEDCLI,
						 NUMPEDRCA,
						 STATUS)
					VALUES
						('PCPEDCFVMANIF/PCPEDIFVMANIF',
						 GVET_REGNOTA(I).CODCLI,
						 SYSDATE,
						 SUBSTR(VSOBSERVACAONOTA, 1, 100),
						 GVET_REGNOTA(I).NUMPED,
						 GVET_REGNOTA(I).NUMPEDCLI,
						 GVET_REGNOTA(I).NUMPEDRCA,
						 GVET_REGNOTA(I).POSICAO);

					COMMIT;
				EXCEPTION
					WHEN OTHERS THEN
						ROLLBACK;
				END;

				FOR CR_NOTAITEM IN (SELECT I.CODPROD,
																	 NVL(CANCELADO, 'N') CANCELADO,
																	 NVL(I.CODAUXILIAR, PCPRODUT.CODAUXILIAR) CODAUXILIAR,
																	 I.CODPRODTROCA,
																	 I.QTTROCA
															FROM PCPEDIFVMANIF I, PCPRODUT
														 WHERE NUMPEDRCA = GVET_REGNOTA(I)
														.NUMPEDRCA
                               AND CODUSUR   = GVET_REGNOTA(I).CODUSUR
															 AND NVL(CANCELADO, 'N') = GVET_REGNOTA(I)
														.CANCELADA
															 AND I.CODPROD = PCPRODUT.CODPROD) LOOP
					-- recupera critica do item
					VNCONTLOG            := GVETREGISTRALOG.COUNT;
					VSOBSERVACAOITEMNOTA := '';

					FOR J IN 1 .. VNCONTLOG LOOP
						IF (GVETREGISTRALOG(J).TIPOREG = 12) AND
							 ((GVETREGISTRALOG(J).NUMPED = GVET_REGNOTA(I).NUMPED) OR
							 (GVETREGISTRALOG(J).NUMPED IS NULL)) AND
							 (GVETREGISTRALOG(J).NUMPEDRCA = GVET_REGNOTA(I).NUMPEDRCA) AND
               (GVETREGISTRALOG(J).CODUSUR = GVET_REGNOTA(I).CODUSUR) AND
							 (GVETREGISTRALOG(J).CODPROD = CR_NOTAITEM.CODPROD) AND
							 (GVETREGISTRALOG(J).CANCELADA = CR_NOTAITEM.CANCELADO) AND
							 (GVETREGISTRALOG(J)
							 .CODAUXILIAR = CR_NOTAITEM.CODAUXILIAR OR GVETREGISTRALOG(J)
							 .CODAUXILIAR IS NULL)

						 THEN
							IF TRIM(GVETREGISTRALOG(J).ERRO) <> ';' THEN
								VSOBSERVACAOITEMNOTA := VSOBSERVACAOITEMNOTA ||
																				REPLACE(GVETREGISTRALOG(J).ERRO,
																								'#',
																								' ');
							END IF;
						END IF;
					END LOOP;

					VNQTATEND := 0;

					SELECT COUNT(*)
						INTO VICONTADOR
						FROM PCPEDI
					 WHERE PCPEDI.NUMPED = GVET_REGNOTA(I)
					.NUMPED
						 AND PCPEDI.CODPROD = CR_NOTAITEM.CODPROD
						 AND (CODAUXILIAR = CR_NOTAITEM.CODAUXILIAR OR
								 CODAUXILIAR IS NULL);

					IF VICONTADOR > 0 THEN
						SELECT QT
							INTO VNQTATEND
							FROM PCPEDI
						 WHERE PCPEDI.NUMPED = GVET_REGNOTA(I)
						.NUMPED
							 AND PCPEDI.CODPROD = CR_NOTAITEM.CODPROD
							 AND (CODAUXILIAR = CR_NOTAITEM.CODAUXILIAR OR
									 CODAUXILIAR IS NULL)
							 AND ROWNUM = 1;
					END IF;

					BEGIN
						UPDATE PCPEDIFVMANIF
							 SET OBSERVACAO_PC = SUBSTR(VSOBSERVACAOITEMNOTA, 1, 300)
						 WHERE NUMPEDRCA = GVET_REGNOTA(I)
						.NUMPEDRCA
               AND CODUSUR = GVET_REGNOTA(I).CODUSUR
							 AND CODPROD = CR_NOTAITEM.CODPROD
							 AND NVL(CANCELADO, 'N') = GVET_REGNOTA(I)
						.CANCELADA
							 AND (CODAUXILIAR = CR_NOTAITEM.CODAUXILIAR OR
									 CODAUXILIAR IS NULL);

						COMMIT;
					EXCEPTION
						WHEN OTHERS THEN
							ROLLBACK;
					END;
				END LOOP;
			END IF;
		END LOOP;

		-- Retorna Notas nao gravadas
		VNCONTNOTA := GVET_REGNOTA.COUNT;

		FOR I IN 1 .. VNCONTNOTA LOOP
			IF GVET_REGNOTA(I).VALIDO = FALSE THEN
				-- recupera critica do cabecalho.
				VNCONTLOG        := GVETREGISTRALOG.COUNT;
				VSOBSERVACAONOTA := '';

				FOR J IN 1 .. VNCONTLOG LOOP
					IF (GVETREGISTRALOG(J).TIPOREG = 11) AND
						 ((GVETREGISTRALOG(J).NUMPED = GVET_REGNOTA(I).NUMPED) OR
						 (GVETREGISTRALOG(J).NUMPED IS NULL)) AND
						 (GVETREGISTRALOG(J).NUMPEDRCA = GVET_REGNOTA(I).NUMPEDRCA) AND
             (GVETREGISTRALOG(J).CODUSUR = GVET_REGNOTA(I).CODUSUR) AND
						 (GVETREGISTRALOG(J).CANCELADA = GVET_REGNOTA(I).CANCELADA) THEN
						IF TRIM(GVETREGISTRALOG(J).ERRO) <> ';' THEN
							VSOBSERVACAONOTA := VSOBSERVACAONOTA ||
																	REPLACE(GVETREGISTRALOG(J).ERRO, '#', ' ');
						END IF;
					END IF;
				END LOOP;

				BEGIN
					--- atualiza cabecalho do pedido.
					UPDATE PCPEDCFVMANIF
						 SET IMPORTADO     = 3,
								 NUMPED        = NULL,
								 RETORNO       = 2,
								 POSICAO_ATUAL = 'R',
								 OBSERVACAO_PC = SUBSTR(VSOBSERVACAONOTA, 1, 300)
					 WHERE NUMPEDRCA = GVET_REGNOTA(I)
					.NUMPEDRCA
             AND CODUSUR   = GVET_REGNOTA(I).CODUSUR
						 AND NVL(CANCELADA, 'N') = GVET_REGNOTA(I)
					.CANCELADA
						 AND NUMCARMANIF = GVET_REGNOTA(I).NUMCARMANIF;

					COMMIT;
				EXCEPTION
					WHEN OTHERS THEN
						ROLLBACK;
				END;

				-- Gravar log de processamento de pedidos
				BEGIN
					INSERT INTO PCLOGFV
						(ARQUIVO,
						 CODCLI,
						 DATA,
						 MOTIVO,
						 NUMPED,
						 NUMPEDCLI,
						 NUMPEDRCA,
						 STATUS)
					VALUES
						('PCPEDCFVMANIF/PCPEDIFVMANIF',
						 GVET_REGNOTA(I).CODCLI,
						 SYSDATE,
						 SUBSTR(VSOBSERVACAONOTA, 1, 100),
						 GVET_REGNOTA(I).NUMPED,
						 GVET_REGNOTA(I).NUMPEDCLI,
						 GVET_REGNOTA(I).NUMPEDRCA,
						 'R');

					COMMIT;
				EXCEPTION
					WHEN OTHERS THEN
						ROLLBACK;
				END;

				FOR CR_NOTAITEM IN (SELECT I.CODPROD,
																	 NVL(CANCELADO, 'N') CANCELADO,
																	 NVL(I.CODAUXILIAR, PCPRODUT.CODAUXILIAR) CODAUXILIAR
															FROM PCPEDIFVMANIF I, PCPRODUT
														 WHERE NUMPEDRCA = GVET_REGNOTA(I)
														.NUMPEDRCA
                               AND CODUSUR   = GVET_REGNOTA(I).CODUSUR
															 AND NVL(CANCELADO, 'N') = GVET_REGNOTA(I)
														.CANCELADA
															 AND I.CODPROD = PCPRODUT.CODPROD) LOOP
					-- recupera critica do item
					VNCONTLOG            := GVETREGISTRALOG.COUNT;
					VSOBSERVACAOITEMNOTA := '';

					FOR J IN 1 .. VNCONTLOG LOOP
						IF (GVETREGISTRALOG(J).TIPOREG = 12) AND
							 ((GVETREGISTRALOG(J).NUMPED = GVET_REGNOTA(I).NUMPED) OR
							 (GVETREGISTRALOG(J).NUMPED IS NULL)) AND
							 (GVETREGISTRALOG(J).NUMPEDRCA = GVET_REGNOTA(I).NUMPEDRCA) AND
               (GVETREGISTRALOG(J).CODUSUR = GVET_REGNOTA(I).CODUSUR) AND
							 (GVETREGISTRALOG(J).CODPROD = CR_NOTAITEM.CODPROD) AND
							 (GVETREGISTRALOG(J).CANCELADA = CR_NOTAITEM.CANCELADO) AND
							 (GVETREGISTRALOG(J)
							 .CODAUXILIAR = CR_NOTAITEM.CODAUXILIAR OR GVETREGISTRALOG(J)
							 .CODAUXILIAR IS NULL)

						 THEN
							IF TRIM(GVETREGISTRALOG(J).ERRO) <> ';' THEN
								VSOBSERVACAOITEMNOTA := VSOBSERVACAOITEMNOTA ||
																				REPLACE(GVETREGISTRALOG(J).ERRO,
																								'#',
																								' ');
							END IF;
						END IF;
					END LOOP;

					BEGIN
						UPDATE PCPEDIFVMANIF
							 SET OBSERVACAO_PC = SUBSTR(VSOBSERVACAOITEMNOTA, 1, 300)
						 WHERE NUMPEDRCA = GVET_REGNOTA(I)
						.NUMPEDRCA
               AND CODUSUR = GVET_REGNOTA(I).CODUSUR
							 AND CODPROD = CR_NOTAITEM.CODPROD
							 AND NVL(CANCELADO, 'N') = CR_NOTAITEM.CANCELADO
							 AND (CODAUXILIAR = CR_NOTAITEM.CODAUXILIAR OR
									 CODAUXILIAR IS NULL);

						COMMIT;
					EXCEPTION
						WHEN OTHERS THEN
							ROLLBACK;
					END;
				END LOOP;
			END IF;
		END LOOP;

		-- Retorna notas rejeitadas durante a leitura
		VNCONTLOG := GVETREGISTRALOG.COUNT;

		FOR I IN 1 .. VNCONTLOG LOOP
			IF (GVETREGISTRALOG(I).TIPOREG = 11) AND
				 (GVETREGISTRALOG(I).LINHAREG IS NOT NULL) THEN
				BEGIN
					--- atualiza cabecalho do pedido.
					UPDATE PCPEDCFVMANIF
						 SET IMPORTADO     = 3,
								 NUMPED        = NULL,
								 RETORNO       = 2,
								 POSICAO_ATUAL = 'R',
								 OBSERVACAO_PC = SUBSTR(REPLACE(GVETREGISTRALOG(I).ERRO,
																								'#',
																								' '),
																				1,
																				300)
					 WHERE NUMPEDRCA = GVETREGISTRALOG(I)
					.NUMPEDRCA
             AND CODUSUR             = GVETREGISTRALOG(I).CODUSUR
						 AND NVL(CANCELADA, 'N') = GVETREGISTRALOG(I).CANCELADA;

					COMMIT;
				EXCEPTION
					WHEN OTHERS THEN
						ROLLBACK;
				END;

				-- Gravar log de processamento de pedidos
				BEGIN
					INSERT INTO PCLOGFV
						(ARQUIVO,
						 CODCLI,
						 DATA,
						 MOTIVO,
						 NUMPED,
						 NUMPEDCLI,
						 NUMPEDRCA,
						 STATUS)
					VALUES
						('PCPEDCFVMANIF/PCPEDIFVMANIF',
						 GVET_REGNOTA(I).CODCLI,
						 SYSDATE,
						 SUBSTR(REPLACE(GVETREGISTRALOG(I).ERRO, '#', ' '), 1, 100),
						 GVETREGISTRALOG(I).NUMPED,
						 NULL,
						 GVETREGISTRALOG(I).NUMPEDRCA,
						 'N');

					COMMIT;
				EXCEPTION
					WHEN OTHERS THEN
						ROLLBACK;
				END;
			END IF;
		END LOOP;

		------------------FIM PRONTA ENTREGA ----------------------------

	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END PROC_PROCESSARETORNOTAB;

	PROCEDURE IMPORTARPEDIDO(P_TIPOLEITURA IN NUMBER DEFAULT 1,
													 P_DATAINICIAL IN DATE DEFAULT TRUNC(SYSDATE),
													 P_DATAFINAL   IN DATE DEFAULT TRUNC(SYSDATE),
													 P_CODFILIAL   IN VARCHAR2 DEFAULT '99',
													 P_TIPOREG     IN NUMBER DEFAULT NULL,
													 P_CODUSUR     IN NUMBER DEFAULT NULL,
													 P_NUMPEDRCA   IN NUMBER DEFAULT NULL) IS
		VBEXISTERRO     BOOLEAN;
		VDDATAFINAL     DATE;
		VDDATAINICIAL   DATE;
		VICONTCANCELADA NUMBER;
		VSCODFILIAL     PCFILIAL.CODIGO%TYPE;

	BEGIN

      -- Remove todos os elementos das tabelas.
      GVETREGISTRALOG.DELETE;
      GVET_REGNOTA.DELETE;
      GVET_REGITEMNOTA.DELETE;

      VSCODFILIAL := NVL(P_CODFILIAL, '99');

      VNGCONTADOR := 0;

      VNGTIPOLEITURA := P_TIPOLEITURA;
      VNGTIPOREG     := P_TIPOREG;

      VBEXISTERRO := FALSE;

      -- leitura dos parametros do sistema (PCCONSUM).
      IF NOT VBEXISTERRO THEN
        PROC_LERPARAMETROS(VBEXISTERRO);
      END IF;

      -- leitura dos pedidos
      IF NOT VBEXISTERRO THEN
        -- leitura de tabelas contendo os pedidos.
        PROC_PROCESSARLEITURA(VBEXISTERRO,
                              P_TIPOLEITURA,
                              P_DATAINICIAL,
                              P_DATAFINAL,
                              VSCODFILIAL,
                              P_TIPOREG,
                              P_CODUSUR,
                              P_NUMPEDRCA);
      END IF;

      IF P_TIPOLEITURA = 1 THEN
        VDDATAINICIAL := TRUNC(SYSDATE) - 365;
        VDDATAFINAL   := TRUNC(SYSDATE);
      ELSE
        VDDATAINICIAL := P_DATAINICIAL;
        VDDATAFINAL   := P_DATAFINAL;
      END IF;

      SELECT COUNT(*)
        INTO VICONTCANCELADA
        FROM PCPEDCFVMANIF
       WHERE IMPORTADO = P_TIPOLEITURA
         AND (NVL(TRUNC(DTINCLUSAO), TRUNC(SYSDATE)) BETWEEN VDDATAINICIAL AND
             VDDATAFINAL)
         AND NVL(CANCELADA, 'N') = 'S'
         AND ((NVL(CODFILIAL, '99') = NVL(VSCODFILIAL, '99')) OR
             (VSCODFILIAL = '99'))
         AND (CODUSUR = P_CODUSUR OR P_CODUSUR IS NULL);

      IF NOT VBEXISTERRO AND VICONTCANCELADA > 0 THEN

        PROC_CANCELAMENTO;

        -- zerar para o caso de cancelamento de nota ainda não importada
        GVETREGISTRALOG.DELETE;
        GVET_REGNOTA.DELETE;
        GVET_REGITEMNOTA.DELETE;

        VNGCONTADOR := 0;
        VBEXISTERRO := FALSE;

        -- leitura dos pedidos
        IF NOT VBEXISTERRO THEN
          -- leitura do conteudo do arquivo de entrada (p_arquivo).
          PROC_PROCESSARLEITURA(VBEXISTERRO,
                                P_TIPOLEITURA,
                                P_DATAINICIAL,
                                P_DATAFINAL,
                                VSCODFILIAL,
                                P_TIPOREG,
                                P_CODUSUR,
                                P_NUMPEDRCA);
        END IF;

      END IF;

      IF NOT VBEXISTERRO THEN
        -- processamento das notas.
        PROC_PROCESSARNOTAS(VBEXISTERRO);
      END IF;

      -- processamento do retorno.
      PROC_PROCESSARETORNOTAB(VBEXISTERRO);
      -- Remove todos os elementos das tabelas.

      func_retiralockpedido(P_NUMPEDRCA,P_CODUSUR);

      GVETREGISTRALOG.DELETE;
      GVETREGISTRALOG.DELETE;
      GVET_REGNOTA.DELETE;
      GVET_REGITEMNOTA.DELETE;

	END IMPORTARPEDIDO;

  PROCEDURE SET_FORCA_ESPECIE_TP(VALOR BOOLEAN) IS
  BEGIN
    G_FORCA_ESPECIE_TP := VALOR;
  END;

  FUNCTION GET_FORCA_ESPECIE_TP RETURN BOOLEAN IS
  BEGIN
    RETURN G_FORCA_ESPECIE_TP;
  END;

  FUNCTION isCobrancaCartao(pCodCob in varchar) return boolean is
    vsCartao varchar2(1);
  BEGIN

    BEGIN
      select nvl(cartao, 'N')
        into vsCartao
        from pccob
       where codcob = pCodCob;
    EXCEPTION
      when others then
        vsCartao := 'N';
    END;

    return(vsCartao = 'S');

  END;

  FUNCTION BuscarLimCredSazonal(p_codcli  NUMBER,
                                P_codusur NUMBER,
                                p2553_132 VARCHAR2) RETURN NUMBER IS

    vlimcredtemp NUMBER := 0;
    vpercaumento NUMBER := 0;

  BEGIN

    if (p2553_132 = 'N') Then
      select sum(limcred)
        into vlimcredtemp
        from pcclient
       where codcli = p_codcli;
    else
      select sum(limcred)
        into vlimcredtemp
        from pcclient
       where NVL(codcliprinc, codcli) =
             (select NVL(codcliprinc, codcli)
                from pcclient
               where codcli = p_codcli);
    end if;

    BEGIN
      SELECT percaumento
        into vpercaumento
        FROM pclimcred
       WHERE pclimcred.coddcli = p_codcli
         AND TRUNC(SYSDATE) BETWEEN pclimcred.dtinicio AND pclimcred.dtfim
         AND ((pclimcred.codusur IS NULL) OR
             (pclimcred.codusur = P_codusur));
    EXCEPTION
      WHEN OTHERS THEN
        vpercaumento := 0;
    END;

    Return vlimcredtemp *(nvl(vpercaumento, 0) / 100);

  END;

END; --importarprontaentrega
