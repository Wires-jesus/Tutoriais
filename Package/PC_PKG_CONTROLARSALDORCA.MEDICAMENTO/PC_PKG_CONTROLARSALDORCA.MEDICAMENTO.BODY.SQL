CREATE OR REPLACE PACKAGE BODY PC_PKG_CONTROLARSALDORCA IS
  /*
   Package criada para controlar conta corrente de RCA

  ***********************************Histórico ***************************************
  Data         Responsável       Tarefa      Comentário
  19/05/2009   Andréa            73271       Projeto 71133
  01/07/2009   Andréa/Sabrina                Ajustes
  06/07/2009   Sabrina                       ccrca_alterar_rca e ccrca_retorna_saldo_item_pedido sao publicas
  08/07/2009   Sabrina                       Gravacao de historico de pclogrca e tratar pcusuari.usadebcredrca nulo
  09/07/2009   Sabrina                       A package não deve barrar a movimentacao do saldo, os programas eh que fazem isso
                                             Ajuste na função de troca de RCA
  10/07/2009   Sabrina                       Correcao na inicializacao das variaveis booleanas
  16/07/2009   Sabrina                       Incluido novo procedimento ccrca_alterar_preco
  21/08/2009   Andréa                        Correção no saldo do item caso seja pedido bonificado
  03/09/2009   Andréa           89939        Projeto 85387 Conta Corrente RCa e Roteirização
  17/11/2009   Andréa           95731        Projeto 90992 Melhoria no desconto financeiro e saldo de conta corrente de rca
  30/11/2009   Andréa                        Correção no projeto para gravar dtfechaccrca na PCNFSAIDPREFAT
  03/12/2009   Andréa                        Corrigir para na ccfincrca_fatura_pedido para verificar 'FF' e 'VV'
  08/12/2009   Sabrina                       Correcao na declaracao das procedures:
                                             ccfinrca_lanca_movimento_carga e ccrca_lancar_movimento_carga
                                             que tambem sao publicas assim como:
                                             ccfinrca_lanca_movimento_caixa e ccrca_lancar_movimento_caixa
                                             Correcao na funcao ccrca_verificar_fechamento que estava sem valor de retorno
  09/12/2009   Andréa                        Correção na ccfincrca_excluir_item_pedido
  10/12/2009   Sabrina                       Correcao na ccfinrca_alterar_preco_qt
  11/12/2009   Sabrina                       Correcao na ccfinrca_devolve_notafiscal
                                             Correcao na ccfinrca_cancela_devolucao
  15/12/2009   Andréa           98438        Correção na ccrca_saldo_item ( acrescentado nvl no parâmetro usadebcredrca)
  16/12/2009   Andréa           98514        Correção para evitar erro de divisor zero  e selects retornando mais de um registro
  16/12/2009   Andréa           98514        Correção no calculo do valor ccfincrca_devolve_notafiscal
  16/12/2009   Andréa                        Alterar  ccfinrca_fatura_pedido para retornar TRUE quando for tipo 'VA'
  17/12/2009   Pablo                         Alterada  ccfinrca_fatura_pedido para retornar TRUE quando for tipo 'VA' e 'VF'
                                             como tinha sido customizado
  22/12/2009   Andréa           98953        Alteração em function ccfinrca_cancela_notafiscal
  23/12/2009   Pablo            98963        Alteração em ccfinrca_cancela_notafiscal para o tipo VA
  11/01/2010   Thiago           99461        Caso o Numtransent seja menor que zero não realizar a chamada da função ccrca_retornar_saldo_item_dev
  11/01/2010   Andréa           99600        Ajuste na function ccfinrca_cancela_notafiscal, para verificar o saldo antes de lançar o débito
  20/01/2010   Pablo            99976        Alteração para não retornar valor FALSE nas funções que validam Des. Financ. quando a venda for
                                             TV4, TV5 , TV8, TV11, TV13 ou TV20
  23/02/2010   Pablo           102070        Caso o desconto financeiro seja gravado por valor  pcfilial.gravarvalordescfin = 'S' na
                                             1) inclusão de itens individuais ccfinrca_incluir_item_pedido,
                                             2) alteração de preco\qt         ccfinrca_alterar_preco_qt
                                             3) exclusão de item              ccfinrca_excluir_item_pedido
                                             não será realizado lancamento (o mesmo já foi realizado na digitação do pedido)
  16/03/2010  Pablo            103974        Alteração para tratar venda TV5 na função ccrca_incluir_item_nf
  19/03/2010  Pablo            100601        Alteração na função ccrca_saldo_item para validar na venda TV5 se o brinde vai mov D/C do RCA.
  06/04/2010  Pablo            105173        Correção da função ccfinrca_excluir_item_pedido
  07/04/2010  Pablo            105260        Alteração para criar as funções ccrca_retorna_saldo_anterior e ccrca_saldo_item com variação
                                             da chamada conforme o nr. de parametros
  13/04/2010 Thiago            105225        Erros homologação Fernandes
  16/04/2010 Thiago            105946        Erros homologação Fernandes
  19/04/2010 Thiago            105946        Erros homologação Fernandes  15.0.3.11
  19/04/2010 Thiago            105946        Erros homologação Fernandes  15.0.3.12
  28/04/2010 Thiago            106838        Alteração na função ccfinrca_cancela_notafiscal caso não exista percentual de desconto financeiro
                                             retorna true para a função para permitir o cancelamento via rotina 1409 v.15.0.3.13
  12/05/2010 Thiago            107825        Correção da função ccrca_excluir_item_dev
  07/06/2010 Thiago            109141        Incluído o condvenda 20 na função ccrca_incluir_iten_nf para consideração do campo punitcont conforem solicitado
  07/06/2010 Andréa            107526        Incluir verificação de combo (movimentacontacorrenterca)
                                             Foi incluida novas procedures com novo parâmetro : ccrc_saldo_item,ccrca_retorna_saldo_anterior
  09/08/2010 Thiago            113031        Alterada a chamada do procedimento "ccrca_validar_acerto_nf" para deduzir a quantidade devolvida
  03/09/2010 Pablo             114710        Tratar a função ccrca_incluir_item_nf para venda TV11 que não possui PCMOVPREFAT.PUNIT somente PCMOVPREFAT.PunitCont
  15/04/2011 Thiago            128693        Alterada package para no ato de alguma devolução ou cancelamento não estornar o saldo caso o mesmo não tenho sido
                                             movimentado para itens do tipo combo através do campo "movimentacontacorrenterca"
  18/08/2011 Thiago            139770       Corrigido o erro apresentado na função ccrca_incluir_item_nf para tipo de movimentação "FF" para a venda tipo 7 e 8

   -------------------------------- Específico -----------------------------------------------------------------------------
   16/09/2011 Pablo             143071        Alteração para controlar o saldo do RCA sem considerar o ST do preço de venda e preço base
                                              (PCPEDI.ST, PCPEDI.STPBASERCA)
   28/11/2015 Anderson Silva                  Log dos Preços utilizados na Movimentação
   25/03/2015 Anderson Silva   HIS.00632.2016 C/C RCA Televendas; STPBASERCA da Devolução pesquisar na PCPEDI
   05/05/2016 Anderson Silva   2956.050067.2016 - Merge Pacote função CONTROLASALDORCA
   05/05/2016 Anderson Silva   HIS.01108.2016 - Crédito do Conta Corrente por Liquidez
   24/08/2016 Anderson Silva                  Merge: Rateio C/C RCA com o Supervisor
   24/08/2016 Anderson Silva                  Rateio C/C RCA com o Supervisor - Liquidez
   28/09/2016 Anderson Silva                  Limite Crédito Flexível
   13/10/2016 Anderson Silva   HIS.02933.2016 Rateio C/C RCA com a Empresa
   05/01/2016 Anderson Silva   4954.001502.2017 - Cancelamentos Limite por Liquidez
   20/01/2016 Anderson Silva                  Merge: Transferido o Rateio para o Faturamento por causa dos Locks
   06/02/2016 Anderson Silva                  Correção Condição LL no Faturamento
   06/09/2017 Anderson Silva   HIS.00052.2017   Movimentação Faturamento por Pedido
   23/05/2018 Anderson Silva   HIS.00065.2018   Regra Específica para usar o saldo c/c somente no Peiddo e não acumular no RCA
   23/05/2018 Anderson Silva   Merge CC_ITEMBNF Item Bonificado em TV1
   01/07/2018 Anderson Silva   Mergem Regra Específica TIPOSALDORESERVADOPEDIDOFAT
   05/09/2018 Anderson Silva   Tratamento C/C Televendas com TIPOSALDORESERVADOPEDIDOFAT
   19/09/2018 Anderson Silva   Tratamento PREFAT
   23/04/2018 Anderson Silva   WT2300-157 - CC Televendas Call Center
   04/02/2019 Anderson Silva   MED-2073 - Compatibilidade com INTEGRADORA pacote
   22/03/2019 Anderson Silva   MED-2359 - Alteração Fechamento Carregamento para atender a PREFAT
   02/07/2019 Anderson Silva   DDMEDICA-146 - Cancelamento NF sem Prefat
   31/01/2020 Marcos Levi      DDMEDICA-2019 Não movimentar Saldo conta corrente ao cancelar Venda
   22/01/2020 Anderson Silva   DDMEDICA-5403 - Usar o PBASERCA com o parâmetro USAPBASERCACOMOBASE   
   14/04/2023 Anderson Silva   DDVENDAS-41579 - Correção opção movimentar saldo rca brinde
   *************************************************************************************************************************                                                                                          */

  ------------------------------------------------------------------------------
  -- Função para buscar versão
  ------------------------------------------------------------------------------
  FUNCTION buscarversao RETURN NUMBER IS
  BEGIN
    RETURN(3);
  END; --buscarversao

  ------------------------------------------------------------------------------
  -- Procedimento para Obter o Parâmetro da Filial NUMBER
  ------------------------------------------------------------------------------
  PROCEDURE POBTEM_PARAMFILIAL_NUMBER(pi_vCodFilial IN  VARCHAR2,
                                      pi_vNomeCampo IN  VARCHAR2,
                                      po_nValor     OUT NUMBER,
                                      po_vErro      OUT VARCHAR2,
                                      po_vMsgErro   OUT VARCHAR2) IS

    vvValorString PCPARAMFILIAL.VALOR%TYPE;

  BEGIN
    -- Inicializa Retornos
    po_nValor   := 0;
    po_vErro    := 'N';
    po_vMsgErro := NULL;

    -- Pesquisa Parametro
    BEGIN
      SELECT PCPARAMFILIAL.VALOR
        INTO vvValorString
        FROM PCPARAMFILIAL
       WHERE (PCPARAMFILIAL.CODFILIAL = pi_vCodFilial)
         AND (PCPARAMFILIAL.NOME      = pi_vNomeCampo);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        po_vErro      := 'S';
        po_vMsgErro   := 'Não foi encontrado o parâmetro "' || pi_vNomeCampo || '" na filial ' || pi_vCodFilial;
        vvValorString := NULL;
    END;

    -- Se não ocorreu erro ao pesquisar o parâmetro
    IF (po_vErro = 'N') THEN

      -- Tira Espaços em Branco do Valor
      vvValorString := TRIM(vvValorString);
      IF (vvValorString IS NULL) THEN
        vvValorString := '0';
      END IF;

      -- Converte String para Number
      BEGIN
        po_nValor := TO_NUMBER(vvValorString);
      EXCEPTION
        WHEN OTHERS THEN
          po_vErro      := 'S';
          po_vMsgErro   := 'Erro ao converter em numérico o texto "' || vvValorString || '" do parâmetro "' || pi_vNomeCampo || '" na filial ' || pi_vCodFilial;
          po_nValor     := 0;
      END;

    END IF; -- Fim Condição Se não ocorreu erro ao pesquisar o parâmetro

  END POBTEM_PARAMFILIAL_NUMBER;

  ------------------------------------------------------------------------------
  -- Função para Verificar se Usa Regra Específica de Medicamentos --
  -- HIS.00052.2017
  -------------------------------------------------------------------
  FUNCTION FUSA_REGRA_MEDICAMENTOS(pi_vCodFilial IN VARCHAR2,
                                   pi_vNome      IN VARCHAR2)
  RETURN VARCHAR2 IS
    vvRetUsaRegraMedicamentos VARCHAR2(240);
  BEGIN
    -- Verifica se usa regra
    BEGIN
      EXECUTE IMMEDIATE ' SELECT VALOR FROM PCREGRASEXCECAOMED WHERE NOME = ' || '''' || pi_vNome || '''' || ' AND CODFILIAL = ' || '''' || pi_vCodFilial || ''''
                   INTO vvRetUsaRegraMedicamentos;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvRetUsaRegraMedicamentos := 'N';
      WHEN OTHERS THEN
        vvRetUsaRegraMedicamentos := 'N';
    END;
    -- Retorno
    RETURN vvRetUsaRegraMedicamentos;
  END FUSA_REGRA_MEDICAMENTOS;

  ------------------------------------------------------------------------------
  -- Função para ler parâmetros
  ------------------------------------------------------------------------------
  PROCEDURE proc_lerparametros(vsmensagem OUT VARCHAR2) IS
  BEGIN
    vsmensagem := NULL;

    SELECT NVL(pcconsum.usacredrca, 'N') usacredrca,
           NVL(pcconsum.bonificaltdebcredrca, 'S') bonificaltdebcredrca,
           NVL(pcconsum.trocaaltdebcredrca, 'S') trocaaltdebcredrca,
           NVL(pcconsum.brokeraltdebcredrca, 'S') brokeraltdebcredrca,
           NVL(pcconsum.crmaltdebcredrca, 'S') crmaltdebcredrca,
           NVL(pcconsum.tipomovccrca, 'VV') tipomovccrca,
           pcconsum.usasaldocontacorrentedescfin
      INTO gregpcconsum
      FROM pcconsum;
  EXCEPTION
    WHEN OTHERS THEN
      vsmensagem := 'Erro ao ler parametros#;' || SQLCODE || '-' || SQLERRM;
  END; --proc_lerparametros;

  ------------------------------------------------------------------------------
  -- Função para retornar se usa o saldo rca somente no próprio pedido
  -- HIS.00065.2018
  ------------------------------------------------------------------------------
  FUNCTION F_USARSALDORCASOMENTENOPEDIDO RETURN BOOLEAN IS
    -- Retorno
    vbUsarSaldoRcaSomenteNoPedido  BOOLEAN;
  BEGIN
    -- Inicializa Retorno
    vbUsarSaldoRcaSomenteNoPedido := FALSE;

    -- Regra Específica
    IF (FUSA_REGRA_MEDICAMENTOS('99','USARSALDORCASOMENTENOPEDIDO') = 'S') THEN
      vbUsarSaldoRcaSomenteNoPedido := TRUE;
    END IF;

    -- Retorno
    RETURN vbUsarSaldoRcaSomenteNoPedido;
  END; --F_USARSALDORCASOMENTENOPEDIDO

  ------------------------------------------------------------------------------
  -- Função para retornar se movimenta Conta-Corrente no Faturamento por Pedido
  -- HIS.00052.2017
  ------------------------------------------------------------------------------
  FUNCTION F_MOVSALDORCAPORPEDIDOFAT RETURN BOOLEAN IS
    -- Parâmetro
    nPERCRATEIOCREDRCASUPERVISOR NUMBER;
    -- Identificação de Erros ao Pesquisar Parâmetros
    vvErroPesqParam              VARCHAR2(1);
    vvMsgErroPesqParam           VARCHAR2(2000);
    -- Retorno
    vbMovSaldoRcaPorPedidoFat    BOOLEAN;
  BEGIN
    -- Inicializa Retorno
    vbMovSaldoRcaPorPedidoFat := FALSE;

    -- Regra Específica
    IF (FUSA_REGRA_MEDICAMENTOS('99','MOVSALDORCAPORPEDIDOFAT') = 'S') THEN
      vbMovSaldoRcaPorPedidoFat := TRUE;
    END IF;

    -- Retorno
    RETURN vbMovSaldoRcaPorPedidoFat;
  END; --F_MOVSALDORCAPORPEDIDOFAT

  ------------------------------------------------------------------------------
  -- Função para retornar se o Rateio de C/C RCA está ativado na Empresa
  ------------------------------------------------------------------------------
  FUNCTION F_RATEIOCREDRCASUPERV_ATIVO RETURN BOOLEAN IS
    -- Parâmetro
    nPERCRATEIOCREDRCASUPERVISOR NUMBER;
    -- Identificação de Erros ao Pesquisar Parâmetros
    vvErroPesqParam              VARCHAR2(1);
    vvMsgErroPesqParam           VARCHAR2(2000);
    -- Retorno
    vbRetAtivo                   BOOLEAN;
  BEGIN
    -- Inicializa Retorno
    vbRetAtivo := FALSE;

    -- Parâmetro
    POBTEM_PARAMFILIAL_NUMBER('99',
                              'PERCRATEIOCREDRCASUPERVISOR',
                              nPERCRATEIOCREDRCASUPERVISOR, --> Valor do Parâmetro
                              vvErroPesqParam,
                              vvMsgErroPesqParam);

    -- Se informou algum valor em que o RCA não fique com 100% do Crédito
    IF (NVL(nPERCRATEIOCREDRCASUPERVISOR,0) > 0)   AND
       (NVL(nPERCRATEIOCREDRCASUPERVISOR,0) < 100) THEN
      vbRetAtivo := TRUE;
    END IF;

    -- Retorno
    RETURN vbRetAtivo;
  END; --F_RATEIOCREDRCASUPERV_ATIVO

  ------------------------------------------------------------------------------
  -- Função para ler % Rateio Crédito C/C RCA
  ------------------------------------------------------------------------------
  FUNCTION F_PERCRATEIOCREDRCASUPERVISOR RETURN NUMBER IS
    -- Identificação de Erros ao Pesquisar Parâmetros
    vvErroPesqParam              VARCHAR2(1);
    vvMsgErroPesqParam           VARCHAR2(2000);
    -- Retorno
    nPERCRATEIOCREDRCASUPERVISOR NUMBER;
  BEGIN

    -- Parâmetro Perc. Taxa Prazo CMV
    POBTEM_PARAMFILIAL_NUMBER('99',
                              'PERCRATEIOCREDRCASUPERVISOR',
                              nPERCRATEIOCREDRCASUPERVISOR, --> Valor do Parâmetro
                              vvErroPesqParam,
                              vvMsgErroPesqParam);
    IF (NVL(nPERCRATEIOCREDRCASUPERVISOR,0) <= 0)  OR
       (NVL(nPERCRATEIOCREDRCASUPERVISOR,0) > 100) THEN
      nPERCRATEIOCREDRCASUPERVISOR := 100; --// Garante 100% se não tiver parâmetro informado ou valor informado incorretamente
    END IF;
    -- Retorno
    RETURN nPERCRATEIOCREDRCASUPERVISOR;
  END; --F_PERCRATEIOCREDRCASUPERVISOR

  ------------------------------------------------------------------------------
  -- Função para Verificar se usa Rateio Crédito C/C RCA
  ------------------------------------------------------------------------------
  FUNCTION F_USARATEIOCREDRCASUPERVISOR(pi_nCodUsur                    IN NUMBER,
                                        p_nPercRateioCredRcaSupervisor IN NUMBER,
                                        p_nValorLanc                   IN NUMBER) RETURN BOOLEAN IS
    -- Dados Supervisor
    vncodsupervisor             PCUSUARI.CODSUPERVISOR%TYPE;
    vncod_cadrca_supervisor     PCSUPERV.COD_CADRCA%TYPE;
    -- Retorno
    bUSARATEIOCREDRCASUPERVISOR BOOLEAN;
  BEGIN
    bUSARATEIOCREDRCASUPERVISOR := FALSE;

    -- Pesquisa Supervisor do RCA
    BEGIN
      SELECT PCUSUARI.CODSUPERVISOR
        INTO vncodsupervisor
        FROM PCUSUARI
       WHERE (PCUSUARI.CODUSUR = pi_nCodUsur);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vncodsupervisor := NULL;
    END;
    -- Pesquisa o RCA vinculado ao Supervisor
    BEGIN
      SELECT PCUSUARI.CODUSUR
        INTO vncod_cadrca_supervisor
        FROM PCSUPERV
           , PCUSUARI
       WHERE (PCSUPERV.CODSUPERVISOR = vncodsupervisor)
         AND (PCUSUARI.CODUSUR       = PCSUPERV.COD_CADRCA);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vncod_cadrca_supervisor := NULL;
    END;

    -- Se o RCA está vinculado a um Supervisor que movimenta C/C
    IF (NVL(vncod_cadrca_supervisor,0) > 0) THEN

      -- Se Crédito
      IF (NVL(p_nValorLanc,0) > 0) THEN
        -- Se não tiver % para Rateio
        IF (NVL(p_nPercRateioCredRcaSupervisor,0) <= 0)   OR
           (NVL(p_nPercRateioCredRcaSupervisor,0)  > 100) THEN
          bUSARATEIOCREDRCASUPERVISOR := FALSE;
        -- Se tiver % para Rateio
        ELSE
          bUSARATEIOCREDRCASUPERVISOR := TRUE;
        END IF;
      END IF;

    END IF;

    -- Retorno
    RETURN bUSARATEIOCREDRCASUPERVISOR;
  END; --F_USARATEIOCREDRCASUPERVISOR

  ------------------------------------------------------------------------------
  -- Função para ler % Rateio Crédito C/C Supervisor Empresa
  ------------------------------------------------------------------------------
  FUNCTION F_PERCRATEIOCREDSUPERVEMPRESA RETURN NUMBER IS
    -- Identificação de Erros ao Pesquisar Parâmetros
    vvErroPesqParam              VARCHAR2(1);
    vvMsgErroPesqParam           VARCHAR2(2000);
    -- Retorno
    nPERCRATEIOCREDSUPERVEMPRESA NUMBER;
  BEGIN

    -- Parâmetro Perc. Taxa Prazo CMV
    POBTEM_PARAMFILIAL_NUMBER('99',
                              'PERCRATEIOCREDSUPERVEMPRESA',
                              nPERCRATEIOCREDSUPERVEMPRESA, --> Valor do Parâmetro
                              vvErroPesqParam,
                              vvMsgErroPesqParam);
    IF    (NVL(nPERCRATEIOCREDSUPERVEMPRESA,0) <= 0) THEN
      nPERCRATEIOCREDSUPERVEMPRESA := 0; --// Garante 0% se informado valor negativo
    ELSIF (NVL(nPERCRATEIOCREDSUPERVEMPRESA,0) > 100) THEN
      nPERCRATEIOCREDSUPERVEMPRESA := 100; --// Garante 100% se valor informado superior a 100%
    END IF;
    -- Retorno
    RETURN nPERCRATEIOCREDSUPERVEMPRESA;
  END; --F_PERCRATEIOCREDSUPERVEMPRESA

  -----------------------------------------
  -- Função para Obter o Código RCA Empresa
  -----------------------------------------
  FUNCTION F_OBTER_RCA_EMPRESA RETURN NUMBER IS
    -- Dados Empresa
    vvcod_cadrca_empresa  PCPARAMFILIAL.VALOR%TYPE;
    vncod_cadrca_empresa  NUMBER;
    -- Dados RCA
    vnCodUsurEmpresa      PCUSUARI.CODUSUR%TYPE;
  BEGIN

    -- Pesquisa o RCA vinculado a Empresa
    BEGIN
      SELECT PCPARAMFILIAL.VALOR
        INTO vvcod_cadrca_empresa
        FROM PCPARAMFILIAL
       WHERE (PCPARAMFILIAL.NOME      = 'CODRCAEMPRESAMED')
         AND (PCPARAMFILIAL.CODFILIAL = '99');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvcod_cadrca_empresa := NULL;
    END;

    BEGIN
      vncod_cadrca_empresa := TO_NUMBER(NVL(vvcod_cadrca_empresa,'0'));
    EXCEPTION
      WHEN OTHERS THEN
        vncod_cadrca_empresa := NULL;
    END;

    BEGIN
      SELECT CODUSUR
        INTO vnCodUsurEmpresa
        FROM PCUSUARI
       WHERE CODUSUR = vncod_cadrca_empresa;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnCodUsurEmpresa := 0;
    END;

    -- Retorno
    RETURN vnCodUsurEmpresa;

  END F_OBTER_RCA_EMPRESA;

  ------------------------------------------------------------------------------
  -- Função para Verificar se usa Rateio Crédito C/C Supervisor Empresa
  ------------------------------------------------------------------------------
  FUNCTION F_USARATEIOCREDSUPERVEMPRESA(pi_nCodRcaEmpresa              IN NUMBER,
                                        p_nPercRateioCredSupervEmpresa IN NUMBER,
                                        p_nValorLanc                   IN NUMBER) RETURN BOOLEAN IS
    -- Retorno
    bUSARATEIOCREDSUPERVEMPRESA BOOLEAN;
  BEGIN
    bUSARATEIOCREDSUPERVEMPRESA := FALSE;

    -- Se o RCA Empresa existe
    IF (NVL(pi_nCodRcaEmpresa,0) > 0) THEN

      -- Se Crédito
      IF (NVL(p_nValorLanc,0) > 0) THEN
        -- Se não tiver % para Rateio
        IF (NVL(p_nPercRateioCredSupervEmpresa,0) <= 0)   OR
           (NVL(p_nPercRateioCredSupervEmpresa,0)  > 100) THEN
          bUSARATEIOCREDSUPERVEMPRESA := FALSE;
        -- Se tiver % para Rateio
        ELSE
          bUSARATEIOCREDSUPERVEMPRESA := TRUE;
        END IF;
      END IF;

    END IF;

    -- Retorno
    RETURN bUSARATEIOCREDSUPERVEMPRESA;
  END; --F_USARATEIOCREDSUPERVEMPRESA

  ------------------------------------------------------------------------------
  -- Função para retornar se movimenta Conta-Corrente no Faturamento por Pedido
  -- Regra Específica para validar o Saldo pelo Total do Pedido e não pelo Item
  ------------------------------------------------------------------------------
  FUNCTION F_TIPOSALDORESERVADOPEDIDOFAT RETURN VARCHAR2 IS
    -- Parâmetro
    nPERCRATEIOCREDRCASUPERVISOR  NUMBER;
    nPERCRATEIOCREDSUPERVEMPRESA  NUMBER;
    -- Identificação de Erros ao Pesquisar Parâmetros
    vvErroPesqParam               VARCHAR2(1);
    vvMsgErroPesqParam            VARCHAR2(2000);
    -- Retorno
    vvTIPOSALDORESERVADOPEDIDOFAT VARCHAR2(1);
  BEGIN
    -- Regra Específica
    vvTIPOSALDORESERVADOPEDIDOFAT := NVL(FUSA_REGRA_MEDICAMENTOS('99','TIPOSALDORESERVADOPEDIDOFAT'),'0');

    -- Retorno
    RETURN vvTIPOSALDORESERVADOPEDIDOFAT;
  END; --F_TIPOSALDORESERVADOPEDIDOFAT
 /*******************************************************************************
  2956.050067.2016 - Merge Pacote função CONTROLASALDORCA
  *******************************************************************************/
  FUNCTION CONTROLASALDORCA(pnumped IN NUMBER,
                            vmsg    OUT VARCHAR2,
                            pcodprod in number default 0,
                            pnumseq in number default 0)
    RETURN VARCHAR2 IS
    RESULT                     VARCHAR2(1);
    vspcconsumusacredrca       VARCHAR2(1);
    vsusadebcredrca            VARCHAR2(1);
    vsbrinde                   VARCHAR2(1);
    vsbonificaltdebcredrca     VARCHAR2(1);
    vstrocaaltdebcredrca       VARCHAR2(1);
    vsbroker                   VARCHAR2(1);
    vsbrokeraltdebcredrca      VARCHAR2(1);
    vsorigemped                VARCHAR2(1);
    vscrmaltdebcredrca         VARCHAR2(1);
    vsclient_consusadebcredrca VARCHAR2(1);
    vncondvenda                NUMBER;
    vbCondVendaValido          boolean;
    vbPedidoNaoBrinde          boolean;
    vbValidaCondVenda5         boolean;
    vbValidadeCondVenda11      boolean;
    vbUsaCredRCA               boolean;
    vbValidaCallCenter         boolean;
    vbValidaBroker             boolean;
    vnVersaoIntegradora        NUMBER(6);
    vbValidaWebIntegradora29   boolean;
  BEGIN

    BEGIN
      SELECT pcpedc.usadebcredrca,
             pcpedc.brinde,
             pcpedc.bonificaltdebcredrca,
             pcpedc.trocaaltdebcredrca,
             pcpedc.broker,
             pcpedc.brokeraltdebcredrca,
             pcpedc.origemped,
             pcpedc.crmaltdebcredrca,
             pcclient.usadebcredrca,
             pcpedc.condvenda,
             PCPEDC.INTEGRADORA
        INTO vsusadebcredrca,
             vsbrinde,
             vsbonificaltdebcredrca,
             vstrocaaltdebcredrca,
             vsbroker,
             vsbrokeraltdebcredrca,
             vsorigemped,
             vscrmaltdebcredrca,
             vsclient_consusadebcredrca,
             vncondvenda,
             vnVersaoIntegradora
        FROM pcpedc,
             pcclient
       WHERE pcpedc.codcli = pcclient.codcli
             AND numped = pnumped;
    EXCEPTION
      WHEN no_data_found THEN
        vmsg   := 'Pedido ou cliente não localizado';
        RESULT := 'N';
        RETURN(RESULT);
      WHEN OTHERS THEN
        vmsg   := 'Erro ao verificar se pedido usa ou não conta corrente. Erro original: ' ||
                  SQLCODE || ' ' || SQLERRM;
        RESULT := 'N';
        RETURN(RESULT);
    END;

    vspcconsumusacredrca := FERRAMENTAS.f_buscarparametro_alfa('CON_USACREDRCA', '99', 'S');

    vbUsaCredRCA := (vspcconsumusacredrca = 'S') and (vsusadebcredrca = 'S') and (vsclient_consusadebcredrca = 'S');

    if vnCondvenda not in (4, 8, 10, 13, 16, 20) then
       vbCondVendaValido := true;
    end if;


    vbPedidoNaoBrinde := (vsbrinde = 'N');
    vbValidaCondVenda5 := (vnCondvenda = 5) and (vsbonificaltdebcredrca = 'S');
    vbValidadeCondVenda11 := (vnCondvenda = 11) and (vstrocaaltdebcredrca = 'S');
    vbValidaBroker := (vsbroker = 'S') and (vsbrokeraltdebcredrca = 'S');
    vbValidaCallCenter := (vsorigemped = 'C') and (vscrmaltdebcredrca = 'S');
    vbValidaWebIntegradora29 := (vsorigemped = 'W') and (vnVersaoIntegradora = 29);

    if not vbUsaCredRCA then
      Result := 'N';
    elsif not vbCondVendaValido then
      Result := 'N';
    elsif not vbPedidoNaoBrinde then
      Result := 'N';
    elsif (vnCondvenda = 5) and (not vbValidaCondVenda5) then
      Result := 'N';
    elsif (vnCondvenda = 11) and (not vbValidadeCondVenda11) then
      Result := 'N';
    elsif (vsbroker = 'S') and (not vbValidaBroker) then
      Result := 'N';
    elsif (vsorigemped = 'C') and (not vbValidaCallCenter) then
      Result := 'N';
    elsif(vbValidaWebIntegradora29)then
      Result := 'N';
    else
      Result := 'S';
    end if;


    RETURN(RESULT);
  END CONTROLASALDORCA;
  
  FUNCTION CONTROLASALDORCA(psUsaCredRCAPCCONSUM      IN VARCHAR2,
                            psUsaDebCredRCA           IN VARCHAR2,
                            psBrinde                  IN VARCHAR2,
                            psBonificaAltDebCredRCA   IN VARCHAR2,
                            psTrocaAltDebCredRCA      IN VARCHAR2,
                            psBroker                  IN VARCHAR2,
                            psBrokerAltDebCredRCA     IN VARCHAR2,
                            psOrigemPed               IN VARCHAR2,
                            psCRMAltDebCredRCA        IN VARCHAR2,
                            psUsaDebCredRCACliente    IN VARCHAR2,
                            piCondVenda               IN NUMBER,
                            psBonificacaoMovimentaCC  IN VARCHAR2,
                            piVersaoIntegradora       IN NUMBER   DEFAULT 0)
  RETURN VARCHAR2 IS

    RESULT                     VARCHAR2(1);
    vbCondVendaValido          boolean;
    vbPedidoNaoBrinde          boolean;
    vbValidaCondVenda5         boolean;
    vbValidadeCondVenda11      boolean;
    vbUsaCredRCA               boolean;
    vbValidaCallCenter         boolean;
    vbValidaBroker             boolean;
    vbValidaWebIntegradora29   boolean;

  BEGIN

    vbUsaCredRCA := (psUsaCredRCAPCCONSUM = 'S') and (psUsaDebCredRCA = 'S') and (psUsaDebCredRCACliente = 'S');
    vbCondVendaValido := false;

    if piCondVenda not in (4, 8, 10, 13, 16, 20) then
      vbCondVendaValido := true;
    end if;


    vbPedidoNaoBrinde        := (psBrinde = 'N');
    vbValidaCondVenda5       := (piCondVenda = 5) and (psBonificaAltDebCredRCA = 'S') and (psBonificacaoMovimentaCC = 'S');
    vbValidadeCondVenda11    := (piCondVenda = 11) and (psTrocaAltDebCredRCA = 'S');
    vbValidaBroker           := (psbroker = 'S') and (psBrokerAltDebCredRCA = 'S');
    vbValidaCallCenter       := (psOrigemPed = 'C') and (psCRMAltDebCredRCA = 'S');
    vbValidaWebIntegradora29 := (psOrigemPed = 'W') and (piVersaoIntegradora = 29);

    if not vbUsaCredRCA then
      Result := 'N';
    elsif not vbCondVendaValido then
      Result := 'N';
    elsif (piCondVenda <> 5) and (not vbPedidoNaoBrinde) then
      Result := 'N';
    elsif (piCondVenda = 5) and (not vbValidaCondVenda5) then
      Result := 'N';
    elsif (piCondVenda = 11) and (not vbValidadeCondVenda11) then
      Result := 'N';
    elsif (psBroker = 'S') and (not vbValidaBroker) then
      Result := 'N';
    elsif (psOrigemPed = 'C') and (not vbValidaCallCenter) then
      Result := 'N';
    elsif vbValidaWebIntegradora29 then
      Result := 'N';
    else
      Result := 'S';
    end if;


    RETURN(RESULT);


  END CONTROLASALDORCA;  


 /*******************************************************************************
  HIS.00632.2016 -- Objetivo: Função para Retornar o RCA do Conta-Corrente
  *******************************************************************************/
  FUNCTION ObterRcaContaCorrente(pi_nCodUsur  IN NUMBER,
                                 pi_nNumPed   IN NUMBER)
  RETURN NUMBER IS
    vnRetCodUsur            PCUSUARI.CODUSUR%TYPE;
    vBLOQDEBCREDRCATELEVMED PCPARAMFILIAL.VALOR%TYPE;
    vnCodEmitente           PCEMPR.MATRICULA%TYPE;
    vnCodUsurEmitente       PCUSUARI.CODUSUR%TYPE;
    vvOrigemPed             PCPEDC.ORIGEMPED%TYPE;
  BEGIN
    -- Pesquisa Parâmetro da 132
    BEGIN
      SELECT VALOR
        INTO vBLOQDEBCREDRCATELEVMED
        FROM PCPARAMFILIAL
       WHERE (CODFILIAL = '99')
         AND (NOME      = 'BLOQDEBCREDRCATELEVMED');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vBLOQDEBCREDRCATELEVMED := 'N';
    END;

    -- Se o Televendas tem movimentação de Conta-Corrente própria
    IF (NVL(vBLOQDEBCREDRCATELEVMED,'N') = 'P') THEN

      -- Pesquisa Emitente do Pedido
      BEGIN
        SELECT CODEMITENTE
             , ORIGEMPED
          INTO vnCodEmitente
             , vvOrigemPed
          FROM PCPEDC
         WHERE (PCPEDC.NUMPED = pi_nNumPed);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnCodEmitente := NULL;
          vvOrigemPed   := NULL;
      END;
      -- Pesquisa RCA do Emitente
      BEGIN
        SELECT CODUSUR
          INTO vnCodUsurEmitente
          FROM PCEMPR
         WHERE (MATRICULA = vnCodEmitente);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnCodUsurEmitente := NULL;
      END;

      -- Se Televendas e se o Emitente tiver Código de RCA e esse Código não for o RCA1 do Pedido passado no parâmetro - Teremos um Televendas que terá um Conta-Corrente próprio
      IF (NVL(vvOrigemPed,' ') IN ('T','C')) AND -- WT2300-157 - Incluido Call Center
         (NVL(vnCodUsurEmitente,0) > 0) AND
         (NVL(vnCodUsurEmitente,0) <> NVL(pi_nCodUsur,0)) THEN
        vnRetCodUsur := vnCodUsurEmitente;
      -- Senão mantém o RCA enviado no parâmetro
      ELSE
        vnRetCodUsur := pi_nCodUsur;
      END IF;

    -- Senão mantém o RCA enviado no parâmetro
    ELSE
      vnRetCodUsur := pi_nCodUsur;
    END IF;

    -- Retorno
    RETURN vnRetCodUsur;

  END ObterRcaContaCorrente;

 /*******************************************************************************
  HIS.00052.2017 -- Obter Saldo RCA dos Pedidos não Faturados
  pi_vTipoChamada = 'OD' - Outros Pedidos diferentes do Pedido do Parâmetro,
                           somente Débitos
                    'PD' - Saldo Total do Pedido
  *******************************************************************************/
  FUNCTION ObterSaldoRcaPedidosNaoFat(pi_vTipoChamada IN VARCHAR2,
                                      pi_nCodUsur     IN NUMBER,
                                      pi_nNumPed      IN NUMBER)
  RETURN NUMBER IS
    vnRetSaldoNaoFat          NUMBER;
    vvTipoMovRca              PCCONSUM.TIPOMOVCCRCA%TYPE;
    vnPercRateioRcaSupervisor NUMBER;
    vBLOQDEBCREDRCATELEVMED   PCPARAMFILIAL.VALOR%TYPE;
  BEGIN
    -- Inicializa Saldo
    vnRetSaldoNaoFat := 0;

    -- Pesquisa Percentual de Rateio
    vnPercRateioRcaSupervisor := F_PERCRATEIOCREDRCASUPERVISOR;

    -- Se Movimenta Saldo por Pedido no Faturamento
    IF (F_MOVSALDORCAPORPEDIDOFAT) THEN

      -- Pesquisa Parâmetro
      BEGIN
        SELECT PCCONSUM.TIPOMOVCCRCA
          INTO vvTipoMovRca
          FROM PCCONSUM;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvTipoMovRca := NULL;
      END;

      -- Pesquisa Parâmetro da 132
      BEGIN
        SELECT VALOR
          INTO vBLOQDEBCREDRCATELEVMED
          FROM PCPARAMFILIAL
         WHERE (CODFILIAL = '99')
           AND (NOME      = 'BLOQDEBCREDRCATELEVMED');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vBLOQDEBCREDRCATELEVMED := 'N';
      END;


      -- Se Credita e Debita no Faturamento
      IF (vvTipoMovRca = 'FF') THEN

        --------------------------------------------------------------------
        -- Outros Pedidos diferentes do Passado no Parâmetro, SOMENTE Débito
        --------------------------------------------------------------------
        IF (pi_vTipoChamada = 'OD') THEN

         /*
          SELECT SUM(DEBCRED)
            INTO vnRetSaldoNaoFat
            FROM (SELECT PCPEDI.CODPROD
                       , PCPEDI.NUMSEQ
                       , CASE WHEN (NVL(PCPEDC.TIPOMOVCCRCA,' ') = 'FF') THEN -->> SOMENTE DÉBITO E CRÉDITO NO FATURAMENTO
                           CASE WHEN PCPEDC.CONDVENDA IN (5,11) THEN
                             -- BONIFICAÇÃO --------------------------
                             CASE WHEN (NVL(PCPEDC.USADEBCREDRCA,'N') = 'S') AND (NVL(PCPEDC.BONIFICALTDEBCREDRCA,'N') = 'S') THEN
                               CASE WHEN ((((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) > 0) THEN -- SE CREDITO
                                          (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) * (NVL(vnPercRateioRcaSupervisor,0) / 100)
                                    ELSE
                                         (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                    END
                             ELSE
                               0
                             END
                           ELSE
                             -- VENDA --------------------------------
                             CASE WHEN (NVL(BONIFIC,'N') = 'F') THEN -- SE ITEM BONIFICADO
                               CASE WHEN (NVL(PCPEDC.USADEBCREDRCA,'N') = 'S') AND (NVL(PCPEDC.BONIFICALTDEBCREDRCA,'N') = 'S') THEN
                                  CASE WHEN ((((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) > 0) THEN -- SE CREDITO
                                             (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) * (NVL(vnPercRateioRcaSupervisor,0) / 100)
                                       ELSE
                                            (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                       END
                                ELSE
                                  0
                                END
                             ELSE -- ITEM NORMAL
                               CASE WHEN (NVL(PCPEDC.USADEBCREDRCA,'N') = 'S') THEN
                                 CASE WHEN (((((PVENDA-NVL(ST,0)) - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) > 0) THEN -- SE CREDITO
                                            ((((PVENDA-NVL(ST,0)) - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) * (NVL(vnPercRateioRcaSupervisor,0) / 100)
                                       ELSE
                                            ((((PVENDA-NVL(ST,0)) - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                       END
                                 ELSE
                                   0
                                 END
                             END
                           END
                         ELSE
                           0
                         END DEBCRED
                    FROM PCPEDI
                       , PCPEDC
                   WHERE (PCPEDC.NUMPED   = PCPEDI.NUMPED)
                     AND (PCPEDC.CODUSUR  = pi_nCodUsur)
                     AND (PCPEDC.POSICAO IN ('P','B','L','M'))
                     AND (PCPEDC.NUMPED  <> pi_nNumPed)
                 );
          */

        /************************************************
         -- SE MOVIMENTA CONTA-CORRENTE NO TELEVENDAS
         ************************************************/
         IF (NVL(vBLOQDEBCREDRCATELEVMED,'N') = 'P') THEN

            -------------------------------------------------------------------------
            -- RESERVA DO SALDO TOTAL DO PEDIDO UTILIZADO SEM RATEIO COM O SUPERVISOR
            -- (SOMENTE PEDIDOS COM SALDO TOTAL NEGATIVO)
            -------------------------------------------------------------------------
            IF    (F_TIPOSALDORESERVADOPEDIDOFAT = '3') THEN

              SELECT SUM(DEBCRED)
                INTO vnRetSaldoNaoFat
                FROM
              (
              SELECT CODRCA_CONTACORRENTE, NUMPED, SUM(DEBCRED) DEBCRED
                FROM (SELECT PC_PKG_CONTROLARSALDORCA.ObterRcaContaCorrente(PCPEDC.CODUSUR,
                                                                            PCPEDI.NUMPED) CODRCA_CONTACORRENTE
                           , PCPEDI.NUMPED
                           , PCPEDI.CODPROD
                           , PCPEDI.NUMSEQ
                           , CASE WHEN (NVL(PCPEDC.TIPOMOVCCRCA,' ') = 'FF') THEN -->> SOMENTE DÉBITO E CRÉDITO NO FATURAMENTO
                               CASE WHEN PCPEDC.CONDVENDA IN (5,11) THEN
                                 -- BONIFICAÇÃO --------------------------
                                 CASE WHEN (NVL(PCPEDC.USADEBCREDRCA,'N') = 'S') AND (NVL(PCPEDC.BONIFICALTDEBCREDRCA,'N') = 'S') THEN
                                   CASE WHEN ((((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) > 0) THEN -- SE CREDITO
                                             (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                        ELSE
                                             (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                        END
                                 ELSE
                                   0
                                 END
                               ELSE
                                 -- VENDA --------------------------------
                                 CASE WHEN (NVL(BONIFIC,'N') = 'F') THEN -- SE ITEM BONIFICADO
                                   CASE WHEN (NVL(PCPEDC.USADEBCREDRCA,'N') = 'S') AND (NVL(PCPEDC.BONIFICALTDEBCREDRCA,'N') = 'S') THEN
                                      CASE WHEN ((((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) > 0) THEN -- SE CREDITO
                                                (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                           ELSE
                                                (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                           END
                                    ELSE
                                      0
                                    END
                                 ELSE -- ITEM NORMAL
                                   CASE WHEN (NVL(PCPEDC.USADEBCREDRCA,'N') = 'S') THEN
                                     CASE WHEN (((((PVENDA-NVL(ST,0)) - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) > 0) THEN -- SE CREDITO
                                               ((((PVENDA-NVL(ST,0)) - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                           ELSE
                                               ((((PVENDA-NVL(ST,0)) - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                           END
                                     ELSE
                                       0
                                     END
                                 END
                               END
                             ELSE
                               0
                             END DEBCRED
                        FROM PCPEDI
                           , PCPEDC
                       WHERE (PCPEDC.NUMPED   = PCPEDI.NUMPED)
                         AND (PCPEDC.POSICAO IN ('P','B','L','M'))
                         AND (PCPEDC.NUMPED  <> pi_nNumPed)
                     ) GROUP BY CODRCA_CONTACORRENTE, NUMPED
                         HAVING (SUM(DEBCRED) < 0)
                            AND (CODRCA_CONTACORRENTE = pi_nCodUsur)); -->> Somente se o Saldo Final do Pedido gerar Crédito

            --------------------------------------------------------------------------------------------
            -- RESERVA DO SALDO TOTAL DO PEDIDO UTILIZADO COM RATEIO COM O SUPERVISOR
            -- (SALDO DO PEDIDO NEGATIVO)
            --------------------------------------------------------------------------------------------
            ELSIF (F_TIPOSALDORESERVADOPEDIDOFAT = '2') THEN

              SELECT SUM(DEBCRED)
                INTO vnRetSaldoNaoFat
                FROM
              (
              SELECT CODRCA_CONTACORRENTE, NUMPED, SUM(DEBCRED) DEBCRED
                FROM (SELECT PC_PKG_CONTROLARSALDORCA.ObterRcaContaCorrente(PCPEDC.CODUSUR,
                                                                            PCPEDI.NUMPED) CODRCA_CONTACORRENTE
                           , PCPEDI.NUMPED
                           , PCPEDI.CODPROD
                           , PCPEDI.NUMSEQ
                           , CASE WHEN (NVL(PCPEDC.TIPOMOVCCRCA,' ') = 'FF') THEN -->> SOMENTE DÉBITO E CRÉDITO NO FATURAMENTO
                               CASE WHEN PCPEDC.CONDVENDA IN (5,11) THEN
                                 -- BONIFICAÇÃO --------------------------
                                 CASE WHEN (NVL(PCPEDC.USADEBCREDRCA,'N') = 'S') AND (NVL(PCPEDC.BONIFICALTDEBCREDRCA,'N') = 'S') THEN
                                   CASE WHEN ((((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) > 0) THEN -- SE CREDITO
                                              (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) * (NVL(vnPercRateioRcaSupervisor,0) / 100)
                                        ELSE
                                             (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                        END
                                 ELSE
                                   0
                                 END
                               ELSE
                                 -- VENDA --------------------------------
                                 CASE WHEN (NVL(BONIFIC,'N') = 'F') THEN -- SE ITEM BONIFICADO
                                   CASE WHEN (NVL(PCPEDC.USADEBCREDRCA,'N') = 'S') AND (NVL(PCPEDC.BONIFICALTDEBCREDRCA,'N') = 'S') THEN
                                      CASE WHEN ((((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) > 0) THEN -- SE CREDITO
                                                 (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) * (NVL(vnPercRateioRcaSupervisor,0) / 100)
                                           ELSE
                                                (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                           END
                                    ELSE
                                      0
                                    END
                                 ELSE -- ITEM NORMAL
                                   CASE WHEN (NVL(PCPEDC.USADEBCREDRCA,'N') = 'S') THEN
                                     CASE WHEN (((((PVENDA-NVL(ST,0)) - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) > 0) THEN -- SE CREDITO
                                                ((((PVENDA-NVL(ST,0)) - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) * (NVL(vnPercRateioRcaSupervisor,0) / 100)
                                           ELSE
                                                ((((PVENDA-NVL(ST,0)) - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                           END
                                     ELSE
                                       0
                                     END
                                 END
                               END
                             ELSE
                               0
                             END DEBCRED
                        FROM PCPEDI
                           , PCPEDC
                       WHERE (PCPEDC.NUMPED   = PCPEDI.NUMPED)
                         AND (PCPEDC.POSICAO IN ('P','B','L','M'))
                         AND (PCPEDC.NUMPED  <> pi_nNumPed)
                     ) GROUP BY CODRCA_CONTACORRENTE, NUMPED
                         HAVING (SUM(DEBCRED) < 0)
                            AND (CODRCA_CONTACORRENTE = pi_nCodUsur)); -->> Somente se o Saldo Final do Pedido gerar Crédito

           ------------------------------------------------------------------
            -- RESERVA DOS VALORES UTILIZADOS NOS ITENS DO PEDIDO
            -- SOMENTE SALDO DO ITEM NEGATIVO (CREDITOS DOS ITENS NÃO ENTRAM)
            -----------------------------------------------------------------
            ELSE

              SELECT SUM(DEBCRED)
                INTO vnRetSaldoNaoFat
                FROM
              (
              SELECT CODRCA_CONTACORRENTE, NUMPED, SUM(DEBCRED) DEBCRED
                FROM (SELECT PC_PKG_CONTROLARSALDORCA.ObterRcaContaCorrente(PCPEDC.CODUSUR,
                                                                            PCPEDI.NUMPED) CODRCA_CONTACORRENTE
                           , PCPEDI.NUMPED
                           , PCPEDI.CODPROD
                           , PCPEDI.NUMSEQ
                           , CASE WHEN (NVL(PCPEDC.TIPOMOVCCRCA,' ') = 'FF') THEN -->> SOMENTE DÉBITO E CRÉDITO NO FATURAMENTO
                               CASE WHEN PCPEDC.CONDVENDA IN (5,11) THEN
                                 -- BONIFICAÇÃO --------------------------
                                 CASE WHEN (NVL(PCPEDC.USADEBCREDRCA,'N') = 'S') AND (NVL(PCPEDC.BONIFICALTDEBCREDRCA,'N') = 'S') THEN
                                   CASE WHEN ((((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) > 0) THEN -- SE CREDITO
                                             0 -- CREDITO NÃO ENTRA
                                        ELSE
                                             (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                        END
                                 ELSE
                                   0
                                 END
                               ELSE
                                 -- VENDA --------------------------------
                                 CASE WHEN (NVL(BONIFIC,'N') = 'F') THEN -- SE ITEM BONIFICADO
                                   CASE WHEN (NVL(PCPEDC.USADEBCREDRCA,'N') = 'S') AND (NVL(PCPEDC.BONIFICALTDEBCREDRCA,'N') = 'S') THEN
                                      CASE WHEN ((((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) > 0) THEN -- SE CREDITO
                                                0 -- CREDITO NÃO ENTRA
                                           ELSE
                                                (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                           END
                                    ELSE
                                      0
                                    END
                                 ELSE -- ITEM NORMAL
                                   CASE WHEN (NVL(PCPEDC.USADEBCREDRCA,'N') = 'S') THEN
                                     CASE WHEN (((((PVENDA-NVL(ST,0)) - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) > 0) THEN -- SE CREDITO
                                               0 -- CREDITO NÃO ENTRA
                                           ELSE
                                               ((((PVENDA-NVL(ST,0)) - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                           END
                                     ELSE
                                       0
                                     END
                                 END
                               END
                             ELSE
                               0
                             END DEBCRED
                        FROM PCPEDI
                           , PCPEDC
                       WHERE (PCPEDC.NUMPED   = PCPEDI.NUMPED)
                         AND (PCPEDC.CODUSUR  = pi_nCodUsur)
                         AND (PCPEDC.POSICAO IN ('P','B','L','M'))
                         AND (PCPEDC.NUMPED  <> pi_nNumPed)
                     ) GROUP BY CODRCA_CONTACORRENTE, NUMPED
                         HAVING (CODRCA_CONTACORRENTE = pi_nCodUsur)); -->> Somente se o Saldo Final do Pedido gerar Crédito

            END IF;

        /************************************************
         -- SE NÃO MOVIMENTA CONTA-CORRENTE NO TELEVENDAS
         ************************************************/
         ELSE

            -------------------------------------------------------------------------
            -- RESERVA DO SALDO TOTAL DO PEDIDO UTILIZADO SEM RATEIO COM O SUPERVISOR
            -- (SOMENTE PEDIDOS COM SALDO TOTAL NEGATIVO)
            -------------------------------------------------------------------------
            IF    (F_TIPOSALDORESERVADOPEDIDOFAT = '3') THEN

              SELECT SUM(DEBCRED)
                INTO vnRetSaldoNaoFat
                FROM
              (
              SELECT NUMPED, SUM(DEBCRED) DEBCRED
                FROM (SELECT PCPEDI.NUMPED
                           , PCPEDI.CODPROD
                           , PCPEDI.NUMSEQ
                           , CASE WHEN (NVL(PCPEDC.TIPOMOVCCRCA,' ') = 'FF') THEN -->> SOMENTE DÉBITO E CRÉDITO NO FATURAMENTO
                               CASE WHEN PCPEDC.CONDVENDA IN (5,11) THEN
                                 -- BONIFICAÇÃO --------------------------
                                 CASE WHEN (NVL(PCPEDC.USADEBCREDRCA,'N') = 'S') AND (NVL(PCPEDC.BONIFICALTDEBCREDRCA,'N') = 'S') THEN
                                   CASE WHEN ((((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) > 0) THEN -- SE CREDITO
                                             (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                        ELSE
                                             (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                        END
                                 ELSE
                                   0
                                 END
                               ELSE
                                 -- VENDA --------------------------------
                                 CASE WHEN (NVL(BONIFIC,'N') = 'F') THEN -- SE ITEM BONIFICADO
                                   CASE WHEN (NVL(PCPEDC.USADEBCREDRCA,'N') = 'S') AND (NVL(PCPEDC.BONIFICALTDEBCREDRCA,'N') = 'S') THEN
                                      CASE WHEN ((((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) > 0) THEN -- SE CREDITO
                                                (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                           ELSE
                                                (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                           END
                                    ELSE
                                      0
                                    END
                                 ELSE -- ITEM NORMAL
                                   CASE WHEN (NVL(PCPEDC.USADEBCREDRCA,'N') = 'S') THEN
                                     CASE WHEN (((((PVENDA-NVL(ST,0)) - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) > 0) THEN -- SE CREDITO
                                               ((((PVENDA-NVL(ST,0)) - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                           ELSE
                                               ((((PVENDA-NVL(ST,0)) - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                           END
                                     ELSE
                                       0
                                     END
                                 END
                               END
                             ELSE
                               0
                             END DEBCRED
                        FROM PCPEDI
                           , PCPEDC
                       WHERE (PCPEDC.NUMPED   = PCPEDI.NUMPED)
                         AND (PCPEDC.CODUSUR  = pi_nCodUsur)
                         AND (PCPEDC.POSICAO IN ('P','B','L','M'))
                         AND (PCPEDC.NUMPED  <> pi_nNumPed)
                     ) GROUP BY NUMPED HAVING SUM(DEBCRED) < 0); -->> Somente se o Saldo Final do Pedido gerar Crédito

            --------------------------------------------------------------------------------------------
            -- RESERVA DO SALDO TOTAL DO PEDIDO UTILIZADO COM RATEIO COM O SUPERVISOR
            -- (SALDO DO PEDIDO NEGATIVO)
            --------------------------------------------------------------------------------------------
            ELSIF (F_TIPOSALDORESERVADOPEDIDOFAT = '2') THEN

              SELECT SUM(DEBCRED)
                INTO vnRetSaldoNaoFat
                FROM
              (
              SELECT NUMPED, SUM(DEBCRED) DEBCRED
                FROM (SELECT PCPEDI.NUMPED
                           , PCPEDI.CODPROD
                           , PCPEDI.NUMSEQ
                           , CASE WHEN (NVL(PCPEDC.TIPOMOVCCRCA,' ') = 'FF') THEN -->> SOMENTE DÉBITO E CRÉDITO NO FATURAMENTO
                               CASE WHEN PCPEDC.CONDVENDA IN (5,11) THEN
                                 -- BONIFICAÇÃO --------------------------
                                 CASE WHEN (NVL(PCPEDC.USADEBCREDRCA,'N') = 'S') AND (NVL(PCPEDC.BONIFICALTDEBCREDRCA,'N') = 'S') THEN
                                   CASE WHEN ((((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) > 0) THEN -- SE CREDITO
                                              (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) * (NVL(vnPercRateioRcaSupervisor,0) / 100)
                                        ELSE
                                             (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                        END
                                 ELSE
                                   0
                                 END
                               ELSE
                                 -- VENDA --------------------------------
                                 CASE WHEN (NVL(BONIFIC,'N') = 'F') THEN -- SE ITEM BONIFICADO
                                   CASE WHEN (NVL(PCPEDC.USADEBCREDRCA,'N') = 'S') AND (NVL(PCPEDC.BONIFICALTDEBCREDRCA,'N') = 'S') THEN
                                      CASE WHEN ((((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) > 0) THEN -- SE CREDITO
                                                 (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) * (NVL(vnPercRateioRcaSupervisor,0) / 100)
                                           ELSE
                                                (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                           END
                                    ELSE
                                      0
                                    END
                                 ELSE -- ITEM NORMAL
                                   CASE WHEN (NVL(PCPEDC.USADEBCREDRCA,'N') = 'S') THEN
                                     CASE WHEN (((((PVENDA-NVL(ST,0)) - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) > 0) THEN -- SE CREDITO
                                                ((((PVENDA-NVL(ST,0)) - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) * (NVL(vnPercRateioRcaSupervisor,0) / 100)
                                           ELSE
                                                ((((PVENDA-NVL(ST,0)) - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                           END
                                     ELSE
                                       0
                                     END
                                 END
                               END
                             ELSE
                               0
                             END DEBCRED
                        FROM PCPEDI
                           , PCPEDC
                       WHERE (PCPEDC.NUMPED   = PCPEDI.NUMPED)
                         AND (PCPEDC.CODUSUR  = pi_nCodUsur)
                         AND (PCPEDC.POSICAO IN ('P','B','L','M'))
                         AND (PCPEDC.NUMPED  <> pi_nNumPed)
                     ) GROUP BY NUMPED HAVING SUM(DEBCRED) < 0); -->> Somente se o Saldo Final do Pedido gerar Crédito

           ------------------------------------------------------------------
            -- RESERVA DOS VALORES UTILIZADOS NOS ITENS DO PEDIDO
            -- SOMENTE SALDO DO ITEM NEGATIVO (CREDITOS DOS ITENS NÃO ENTRAM)
            -----------------------------------------------------------------
            ELSE

              SELECT SUM(DEBCRED)
                INTO vnRetSaldoNaoFat
                FROM (SELECT PCPEDI.CODPROD
                           , PCPEDI.NUMSEQ
                           , CASE WHEN (NVL(PCPEDC.TIPOMOVCCRCA,' ') = 'FF') THEN -->> SOMENTE DÉBITO E CRÉDITO NO FATURAMENTO
                               CASE WHEN PCPEDC.CONDVENDA IN (5,11) THEN
                                 -- BONIFICAÇÃO --------------------------
                                 CASE WHEN (NVL(PCPEDC.USADEBCREDRCA,'N') = 'S') AND (NVL(PCPEDC.BONIFICALTDEBCREDRCA,'N') = 'S') THEN
                                   CASE WHEN ((((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) > 0) THEN -- SE CREDITO
                                             0 -- CREDITO NÃO ENTRA
                                        ELSE
                                             (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                        END
                                 ELSE
                                   0
                                 END
                               ELSE
                                 -- VENDA --------------------------------
                                 CASE WHEN (NVL(BONIFIC,'N') = 'F') THEN -- SE ITEM BONIFICADO
                                   CASE WHEN (NVL(PCPEDC.USADEBCREDRCA,'N') = 'S') AND (NVL(PCPEDC.BONIFICALTDEBCREDRCA,'N') = 'S') THEN
                                      CASE WHEN ((((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) > 0) THEN -- SE CREDITO
                                                0 -- CREDITO NÃO ENTRA
                                           ELSE
                                                (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                           END
                                    ELSE
                                      0
                                    END
                                 ELSE -- ITEM NORMAL
                                   CASE WHEN (NVL(PCPEDC.USADEBCREDRCA,'N') = 'S') THEN
                                     CASE WHEN (((((PVENDA-NVL(ST,0)) - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT)) > 0) THEN -- SE CREDITO
                                               0 -- CREDITO NÃO ENTRA
                                           ELSE
                                               ((((PVENDA-NVL(ST,0)) - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                                           END
                                     ELSE
                                       0
                                     END
                                 END
                               END
                             ELSE
                               0
                             END DEBCRED
                        FROM PCPEDI
                           , PCPEDC
                       WHERE (PCPEDC.NUMPED   = PCPEDI.NUMPED)
                         AND (PCPEDC.CODUSUR  = pi_nCodUsur)
                         AND (PCPEDC.POSICAO IN ('P','B','L','M'))
                         AND (PCPEDC.NUMPED  <> pi_nNumPed)
                     );

            END IF;

          END IF; -- FIM CONDIÇÃO: SE MOVIMENTA CONTA-CORRENTE NO TELEVENDAS

        END IF;

      END IF;

    END IF;

    -- Retorno
    RETURN NVL(vnRetSaldoNaoFat,0);
  END ObterSaldoRcaPedidosNaoFat;

  FUNCTION ccfinrca_saldorcamenosdescfin(pcodusur   IN NUMBER,
                                         pcodfilial IN VARCHAR2)
    RETURN NUMBER IS
    /*******************************************************************************
     Objetivo: Pesquisar os descontos financeiros dos pedidos do RCA, e abater
      este valor do Saldo do RCA. O retorno da função é o resultado desta subtração:
      Saldo RCA - Desconto Financeiro dos Pedidos
             Historico de Alteracoes
    --------------------------------------------------------------------------------
      Data               Responsavel            Descricao
      ----------------   ---------------------  ------------------------------------
      13/08/2007         Carolina              Criacao da função
      14/08/2007         Pablo                  Alteração para não retornar Valor negativo
      15/08/2007         Pablo                  Alteração para corrigir o Cálculo do Valor do Desconto Financeiro concedido
                                                            foi acrescentado  (Nvl(Pcpedc.Perdescfin, 0) / 100) pois estava somente  Nvl(Pcpedc.Perdescfin, 0)
      14/09/2007         Pablo                  Tarefa 51188 Caso não exista registro em PCSALDORCA será gerado um registro com Saldo zerado.
      04/11/2009         Pablo                  Tarefa 95730 (Customização do Projeto 90992 Melhoria Desconto Financeiro e Saldo Conta-Corrente).
    *******************************************************************************/
    -- Declaracao de Variaveis
    vncontador  NUMBER(3);
    vvalordesc  NUMBER(14, 2);
    vvalorsaldo NUMBER(14, 2);
    vnresultado NUMBER(14, 2);
  BEGIN
    vvalordesc  := 0;
    vvalorsaldo := 0;

    SELECT SUM(NVL(pcpedc.vlatend, 0) * (NVL(pcpedc.perdescfin, 0) / 100))
      INTO vvalordesc
      FROM pcpedc
     WHERE posicao IN ('L', 'M', 'B', 'P') -- Tarefa 95730
       AND NVL(bloqueiosaldoccdescfin, 'N') = 'N' -- Tarefa 95730
       AND NVL(tipomovccrca, 'VV') IN ('VV', 'FF') -- Tarefa 95730
       AND codusur = pcodusur
       AND codfilial = pcodfilial
       AND DATA BETWEEN (TRUNC(SYSDATE) - 120) AND TRUNC(SYSDATE);

    SELECT COUNT(*)
      INTO vncontador
      FROM pcsaldorca
     WHERE codusur = pcodusur;

    IF vncontador = 0 THEN
      INSERT INTO pcsaldorca
        (codusur, vlsaldo, vlsaldoant)
      VALUES
        (pcodusur, 0, 0);

      vvalorsaldo := 0;
    ELSE
      SELECT NVL(vlsaldo, 0)
        INTO vvalorsaldo
        FROM pcsaldorca
       WHERE codusur = pcodusur;
    END IF;

    vnresultado := NVL(vvalorsaldo, 0) - NVL(vvalordesc, 0);

    IF vnresultado < 0 THEN
      vnresultado := 0;
    END IF;

    RETURN(vnresultado);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END; --ccfinrca_saldorcamenosdescfin

  FUNCTION ccrca_verificar_fechamento(p_numtransvenda IN PCNFSAIDPREFAT.numtransvenda%TYPE)
    RETURN BOOLEAN IS
    vnnumcar  pccarreg.numcar%TYPE;
    vddtfecha pccarreg.dtfecha%TYPE;
    vbvalido  BOOLEAN;
    vicont    NUMBER;
  BEGIN
    -- MED-2359     
    SELECT COUNT(*)
      INTO vicont
      FROM PCNFSAIDPREFAT
     WHERE numtransvenda = p_numtransvenda;

    -- MED-2359 
    IF nvl(vicont,0) > 0 THEN
  
    SELECT numcar, dtfecha
      INTO vnnumcar, vddtfecha
      FROM PCNFSAIDPREFAT
     WHERE numtransvenda = p_numtransvenda;

    /*MED-2277*/
    ELSE
    
      SELECT numcar, dtfecha
        INTO vnnumcar, vddtfecha
        FROM PCNFSAID
       WHERE numtransvenda = p_numtransvenda;
       
    END IF;

    IF NVL(vnnumcar, 0) <> 0 THEN
      --Tarefa 105946
      /*SELECT pccarreg.dtfecha
       INTO vddtfecha
       FROM pccarreg
      WHERE numcar = vnnumcar;*/

      IF vddtfecha IS NOT NULL THEN
        vbvalido := TRUE;
      ELSE
        vbvalido := FALSE;
      END IF;
    ELSE
      SELECT COUNT(*)
        INTO vicont
        FROM PCPRESTPREFAT
       WHERE numtransvenda = p_numtransvenda;

      IF vicont = 0 THEN
        vbvalido := TRUE;
      ELSE
        SELECT COUNT(*)
          INTO vicont
          FROM PCPRESTPREFAT
         WHERE numtransvenda = p_numtransvenda
           AND dtfecha IS NOT NULL;

        IF vicont <> 0 THEN
          vbvalido := TRUE;
        ELSE
          vbvalido := FALSE;
        END IF;
      END IF;
    END IF;

    RETURN vbvalido;
  END;

  -- RNG01
  FUNCTION ccrca_checar_saldo_atual(p_codusur IN pcpedc.codusur%TYPE)
    RETURN NUMBER IS
    vnvlcorrente pcusuari.vlcorrente%TYPE;
    vnDebitosPedidosParaFaturar NUMBER; -- HIS.00052.2017
  BEGIN
    BEGIN
      SELECT NVL(pcusuari.vlcorrente, 0)
        INTO vnvlcorrente
        FROM pcusuari
       WHERE codusur = p_codusur;
    EXCEPTION
      WHEN OTHERS THEN
        vnvlcorrente := 0;
    END;

    -- HIS.00052.2017 - Se Usar Regra Específica que Movimenta Saldo por Pedido no Faturamento,
    -- precisa abater as movimentações de Débito do RCA dos Pedidos Liberados, Bloqueados e Pendentes
    IF (F_MOVSALDORCAPORPEDIDOFAT) THEN
      vnDebitosPedidosParaFaturar := ObterSaldoRcaPedidosNaoFat('OD',
                                                                p_codusur,
                                                                0); -->> Tem que passar Zero
      -- Deve "somar" porque os débitos retorna negativo na função
      vnvlcorrente := vnvlcorrente + NVL(vnDebitosPedidosParaFaturar,0);
    END IF;

    RETURN vnvlcorrente;
  END; --ccrca_checar_saldo_atual

  --RNG26
  FUNCTION ccrca_checar_limite_credito(p_codusur pcusuari.codusur%TYPE)
    RETURN NUMBER IS
    vnvllimcred pcusuari.vllimcred%TYPE;
  BEGIN
    SELECT NVL(pcusuari.vllimcred, 0)
      INTO vnvllimcred
      FROM pcusuari
     WHERE codusur = p_codusur;

    RETURN(vnvllimcred);
  END; --ccrca_checar_limite_credito

  -- RNG02
  FUNCTION ccrca_checar_disponivel_atual(p_codusur IN pcpedc.codusur%TYPE)
    RETURN NUMBER IS
    vnvldisponivel NUMBER;
  BEGIN
    vnvldisponivel := 0;
    vnvldisponivel := NVL(ccrca_checar_limite_credito(p_codusur), 0) +
                      NVL(ccrca_checar_saldo_atual(p_codusur), 0);

    RETURN vnvldisponivel;
  END; -- ccrca_checar_disponivel_atual

  -- RNG06 (rng03, rng04, rng05)
  FUNCTION ccrca_saldo_item( -- 17 parametros
                            p_usacredrca           IN pcpedc.usacredrca%TYPE,
                            p_usadebcredrca        IN pcpedc.usadebcredrca%TYPE,
                            p_broker               IN pcpedc.broker%TYPE,
                            p_origemped            IN pcpedc.origemped%TYPE,
                            p_bonificaltdebcredrca IN pcpedc.bonificaltdebcredrca%TYPE,
                            p_trocaaltdebcredrca   IN pcpedc.trocaaltdebcredrca%TYPE,
                            p_crmaltdebcredrca     IN pcpedc.crmaltdebcredrca%TYPE,
                            p_brokeraltdebcredrca  IN pcpedc.brokeraltdebcredrca%TYPE,
                            p_tipomovccrca         IN pcpedc.tipomovccrca%TYPE,
                            p_condvenda            IN pcpedc.condvenda%TYPE,
                            p_brinde               IN pcpedc.brinde%TYPE,
                            p_codusur              IN pcpedc.codusur%TYPE,
                            p_tipo                 IN VARCHAR2,
                            --tipo de processo V - Venda, F - Faturamento, C - Cancelamento, D - devolucao, A - Acerto
                            p_pvenda   IN pcpedi.pvenda%TYPE,
                            p_ptabela  IN pcpedi.ptabela%TYPE,
                            p_pbaserca IN pcpedi.pbaserca%TYPE,
                            p_qt       IN pcpedi.qt%TYPE) RETURN NUMBER IS
    vnvlsaldoitem NUMBER;
    vsmsg         VARCHAR2(400);
  BEGIN
    --RNG03
    SELECT (DECODE(p_condvenda, 5, 0, NVL(p_pvenda, 0)) -
           NVL(p_pbaserca, NVL(p_ptabela, 0))) * NVL(p_qt, 0)
      INTO vnvlsaldoitem
      FROM DUAL;

    proc_lerparametros(vsmsg);

    --RNG06
    IF NVL(p_usacredrca, gregpcconsum.usacredrca) = 'S' THEN
      IF nvl(p_usadebcredrca, NVL(p_usacredrca, gregpcconsum.usacredrca)) = 'S' THEN
        IF p_condvenda IN (4, 8, 10, 13, 16, 20) THEN
          vnvlsaldoitem := 0;
        ELSE
          IF (NVL(p_brinde, 'N') = 'S') THEN
            vnvlsaldoitem := 0;
          ELSE
            IF p_condvenda = 5 THEN
              IF (NVL(p_bonificaltdebcredrca,
                      gregpcconsum.bonificaltdebcredrca) = 'N') THEN
                vnvlsaldoitem := 0;
              END IF;
            ELSIF p_condvenda = 11 THEN
              IF NVL(p_trocaaltdebcredrca, gregpcconsum.trocaaltdebcredrca) = 'N' THEN
                vnvlsaldoitem := 0;
              END IF;
            ELSE
              IF NVL(p_broker, 'N') = 'S' THEN
                --Broker
                IF NVL(p_brokeraltdebcredrca,
                       gregpcconsum.brokeraltdebcredrca) = 'N' THEN
                  vnvlsaldoitem := 0;
                END IF;
              ELSIF p_origemped = 'C' THEN
                --Callcenter
                IF NVL(p_crmaltdebcredrca, gregpcconsum.crmaltdebcredrca) = 'N' THEN
                  vnvlsaldoitem := 0;
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;

        -- Se não for cancelamento/devolução
        IF p_tipo NOT IN ('C', 'D') THEN
          --RNG04
          IF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'VV' THEN
            --Débito/crédito na venda
            -- Se não for venda
            IF p_tipo <> 'V' THEN
              vnvlsaldoitem := 0;
            END IF;
          ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'FF' THEN
            --Débito /crédito no faturamento
            -- Se não for faturamento
            IF p_tipo <> 'F' THEN
              vnvlsaldoitem := 0;
            END IF;
          ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'VF' THEN
            --Débito venda /crédito no faturamento
            IF vnvlsaldoitem > 0 THEN
              -- Se não for faturamento
              IF p_tipo <> 'F' THEN
                vnvlsaldoitem := 0;
              END IF;
            ELSE
              -- Se não for venda
              IF p_tipo <> 'V' THEN
                vnvlsaldoitem := 0;
              END IF;
            END IF;
          ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'VA' THEN
            --Débito Venda /crédito no Acerto
            IF vnvlsaldoitem < 0 THEN
              -- Se não for venda
              IF p_tipo <> 'V' THEN
                vnvlsaldoitem := 0;
              END IF;
            ELSE
              --se não for acerto
              IF p_tipo <> 'A' THEN
                vnvlsaldoitem := 0;
              END IF;
            END IF;
          -- HIS.01108.2016 - Crédito do Conta Corrente por Liquidez
          ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'LL' THEN
            --Débito /crédito na Liquidez
            -- Se não for liquidez
            IF p_tipo <> 'L' THEN
              vnvlsaldoitem := 0;
            END IF;
          -- HIS.01108.2016 - Crédito do Conta Corrente por Liquidez
          ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'VL' THEN
            --Débito venda /crédito na Liquidez
            IF vnvlsaldoitem > 0 THEN
              -- Se não for Liquidez
              IF p_tipo <> 'L' THEN
                vnvlsaldoitem := 0;
              END IF;
            ELSE
              -- Se não for venda
              IF p_tipo <> 'V' THEN
                vnvlsaldoitem := 0;
              END IF;
            END IF;
          END IF;
        END IF;
      ELSIF nvl(p_usadebcredrca, NVL(p_usacredrca, gregpcconsum.usacredrca)) = 'N' THEN
        vnvlsaldoitem := 0;
      END IF;
    ELSE
      --p_usacredrca = 'N'
      vnvlsaldoitem := 0;
    END IF;

    RETURN vnvlsaldoitem;
  END; -- ccrca_saldo_item

  -- RNG06 (rng03, rng04, rng05)
  FUNCTION ccrca_saldo_item( -- 18 Parametros
                            p_usacredrca           IN pcpedc.usacredrca%TYPE,
                            p_usadebcredrca        IN pcpedc.usadebcredrca%TYPE,
                            p_broker               IN pcpedc.broker%TYPE,
                            p_origemped            IN pcpedc.origemped%TYPE,
                            p_bonificaltdebcredrca IN pcpedc.bonificaltdebcredrca%TYPE,
                            p_trocaaltdebcredrca   IN pcpedc.trocaaltdebcredrca%TYPE,
                            p_crmaltdebcredrca     IN pcpedc.crmaltdebcredrca%TYPE,
                            p_brokeraltdebcredrca  IN pcpedc.brokeraltdebcredrca%TYPE,
                            p_tipomovccrca         IN pcpedc.tipomovccrca%TYPE,
                            p_condvenda            IN pcpedc.condvenda%TYPE,
                            p_brinde               IN pcpedc.brinde%TYPE,
                            p_codusur              IN pcpedc.codusur%TYPE,
                            p_tipo                 IN VARCHAR2,
                            --tipo de processo V - Venda, F - Faturamento, C - Cancelamento, D - devolucao, A - Acerto
                            p_pvenda             IN pcpedi.pvenda%TYPE,
                            p_ptabela            IN pcpedi.ptabela%TYPE,
                            p_pbaserca           IN pcpedi.pbaserca%TYPE,
                            p_qt                 IN pcpedi.qt%TYPE,
                            p_usaDebCredRCABrind IN pcpedi.usadebcredrcabrind%TYPE -- Tarefa 100601
                            ) RETURN NUMBER IS
    vnvlsaldoitem NUMBER;
    vsmsg         VARCHAR2(400);
  BEGIN
    --RNG03
    SELECT (DECODE(p_condvenda, 5, 0, NVL(p_pvenda, 0)) -
           NVL(p_pbaserca, NVL(p_ptabela, 0))) * NVL(p_qt, 0)
      INTO vnvlsaldoitem
      FROM DUAL;

    proc_lerparametros(vsmsg);

    --RNG06
    IF NVL(p_usacredrca, gregpcconsum.usacredrca) = 'S' THEN
      IF nvl(p_usadebcredrca, NVL(p_usacredrca, gregpcconsum.usacredrca)) = 'S' THEN
        IF p_condvenda IN (4, 8, 10, 13, 16, 20) THEN
          vnvlsaldoitem := 0;
        ELSE
          IF (NVL(p_brinde, 'N') = 'S') THEN
            IF (p_usaDebCredRCABrind = 'N') -- Tarefa 100601
             THEN
              vnvlsaldoitem := 0;
            END IF;
          ELSE
            IF p_condvenda = 5 THEN
              IF (NVL(p_bonificaltdebcredrca,
                      gregpcconsum.bonificaltdebcredrca) = 'N') THEN
                vnvlsaldoitem := 0;
              END IF;
            ELSIF p_condvenda = 11 THEN
              IF NVL(p_trocaaltdebcredrca, gregpcconsum.trocaaltdebcredrca) = 'N' THEN
                vnvlsaldoitem := 0;
              END IF;
            ELSE
              IF NVL(p_broker, 'N') = 'S' THEN
                --Broker
                IF NVL(p_brokeraltdebcredrca,
                       gregpcconsum.brokeraltdebcredrca) = 'N' THEN
                  vnvlsaldoitem := 0;
                END IF;
              ELSIF p_origemped = 'C' THEN
                --Callcenter
                IF NVL(p_crmaltdebcredrca, gregpcconsum.crmaltdebcredrca) = 'N' THEN
                  vnvlsaldoitem := 0;
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;

        -- Se não for cancelamento/devolução
        IF p_tipo NOT IN ('C', 'D') THEN
          --RNG04
          IF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'VV' THEN
            --Débito/crédito na venda
            -- Se não for venda
            IF p_tipo <> 'V' THEN
              vnvlsaldoitem := 0;
            END IF;
          ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'FF' THEN
            --Débito /crédito no faturamento
            -- Se não for faturamento
            IF p_tipo <> 'F' THEN
              vnvlsaldoitem := 0;
            END IF;
          ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'VF' THEN
            --Débito venda /crédito no faturamento
            IF vnvlsaldoitem > 0 THEN
              -- Se não for faturamento
              IF p_tipo <> 'F' THEN
                vnvlsaldoitem := 0;
              END IF;
            ELSE
              -- Se não for venda
              IF p_tipo <> 'V' THEN
                vnvlsaldoitem := 0;
              END IF;
            END IF;
          ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'VA' THEN
            --Débito Venda /crédito no Acerto
            IF vnvlsaldoitem < 0 THEN
              -- Se não for venda
              IF p_tipo <> 'V' THEN
                vnvlsaldoitem := 0;
              END IF;
            ELSE
              --se não for acerto
              IF p_tipo <> 'A' THEN
                vnvlsaldoitem := 0;
              END IF;
            END IF;
          -- HIS.01108.2016 - Crédito do Conta Corrente por Liquidez
          ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'LL' THEN
            --Débito /crédito na Liquidez
            -- Se não for liquidez
            IF p_tipo <> 'L' THEN
              vnvlsaldoitem := 0;
            END IF;
          -- HIS.01108.2016 - Crédito do Conta Corrente por Liquidez
          ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'VL' THEN
            --Débito venda /crédito na Liquidez
            IF vnvlsaldoitem > 0 THEN
              -- Se não for Liquidez
              IF p_tipo <> 'L' THEN
                vnvlsaldoitem := 0;
              END IF;
            ELSE
              -- Se não for venda
              IF p_tipo <> 'V' THEN
                vnvlsaldoitem := 0;
              END IF;
            END IF;
          END IF;
        END IF;
      ELSIF nvl(p_usadebcredrca, NVL(p_usacredrca, gregpcconsum.usacredrca)) = 'N' THEN
        vnvlsaldoitem := 0;
      END IF;
    ELSE
      --p_usacredrca = 'N'
      vnvlsaldoitem := 0;
    END IF;

    RETURN vnvlsaldoitem;
  END; -- ccrca_saldo_item

  -- RNG06 (rng03, rng04, rng05)
  FUNCTION ccrca_saldo_item( -- 19 Parametros
                            p_usacredrca           IN pcpedc.usacredrca%TYPE,
                            p_usadebcredrca        IN pcpedc.usadebcredrca%TYPE,
                            p_broker               IN pcpedc.broker%TYPE,
                            p_origemped            IN pcpedc.origemped%TYPE,
                            p_bonificaltdebcredrca IN pcpedc.bonificaltdebcredrca%TYPE,
                            p_trocaaltdebcredrca   IN pcpedc.trocaaltdebcredrca%TYPE,
                            p_crmaltdebcredrca     IN pcpedc.crmaltdebcredrca%TYPE,
                            p_brokeraltdebcredrca  IN pcpedc.brokeraltdebcredrca%TYPE,
                            p_tipomovccrca         IN pcpedc.tipomovccrca%TYPE,
                            p_condvenda            IN pcpedc.condvenda%TYPE,
                            p_brinde               IN pcpedc.brinde%TYPE,
                            p_codusur              IN pcpedc.codusur%TYPE,
                            p_tipo                 IN VARCHAR2,
                            --tipo de processo V - Venda, F - Faturamento, C - Cancelamento, D - devolucao, A - Acerto
                            p_pvenda                    IN pcpedi.pvenda%TYPE,
                            p_ptabela                   IN pcpedi.ptabela%TYPE,
                            p_pbaserca                  IN pcpedi.pbaserca%TYPE,
                            p_qt                        IN pcpedi.qt%TYPE,
                            p_usaDebCredRCABrind        IN pcpedi.usadebcredrcabrind%TYPE, -- Tarefa 100601
                            p_movimentacontacorrenterca IN pcpedi.movimentacontacorrenterca%type,
                            p_prodBonific               IN pcpedi.BONIFIC%TYPE DEFAULT 'N' -- MED-2073
                            ) RETURN NUMBER IS
    vnvlsaldoitem NUMBER;
    vsmsg         VARCHAR2(400);

  BEGIN
    --RNG03
    SELECT (DECODE(p_condvenda, 5, 0, NVL(p_pvenda, 0)) -
           NVL(p_pbaserca, NVL(p_ptabela, 0))) * NVL(p_qt, 0)
      INTO vnvlsaldoitem
      FROM DUAL;

    proc_lerparametros(vsmsg);

    if p_movimentacontacorrenterca = 'N' then

      vnvlsaldoitem := 0;

    else

      --RNG06
      IF NVL(p_usacredrca, gregpcconsum.usacredrca) = 'S' THEN
        IF nvl(p_usadebcredrca, NVL(p_usacredrca, gregpcconsum.usacredrca)) = 'S' THEN
          IF p_condvenda IN (4, 8, 10, 13, 16, 20) THEN
            vnvlsaldoitem := 0;
          ELSE
            IF (NVL(p_brinde, 'N') = 'S') THEN
              IF (p_usaDebCredRCABrind = 'N') -- Tarefa 100601
               THEN
                vnvlsaldoitem := 0;
              END IF;
            ELSE
              IF p_condvenda = 5 THEN
                IF (NVL(p_bonificaltdebcredrca,
                        gregpcconsum.bonificaltdebcredrca) = 'N') THEN
                  vnvlsaldoitem := 0;
                END IF;
              ELSIF p_condvenda = 11 THEN
                IF NVL(p_trocaaltdebcredrca,
                       gregpcconsum.trocaaltdebcredrca) = 'N' THEN
                  vnvlsaldoitem := 0;
                END IF;
              ELSE
                IF NVL(p_broker, 'N') = 'S' THEN
                  --Broker
                  IF NVL(p_brokeraltdebcredrca,
                         gregpcconsum.brokeraltdebcredrca) = 'N' THEN
                    vnvlsaldoitem := 0;
                  END IF;
                ELSIF p_origemped = 'C' THEN
                  --Callcenter
                  IF NVL(p_crmaltdebcredrca, gregpcconsum.crmaltdebcredrca) = 'N' THEN
                    vnvlsaldoitem := 0;
                  END IF;
                END IF;
              END IF;
            END IF;
          END IF;

          -- Se não for cancelamento/devolução
          IF p_tipo NOT IN ('C', 'D') THEN
            --RNG04
            IF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'VV' THEN
              --Débito/crédito na venda
              -- Se não for venda
              IF p_tipo <> 'V' THEN
                vnvlsaldoitem := 0;
              END IF;
            ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'FF' THEN
              --Débito /crédito no faturamento
              -- Se não for faturamento
              IF p_tipo <> 'F' THEN
                vnvlsaldoitem := 0;
              END IF;
            ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'VF' THEN
              --Débito venda /crédito no faturamento
              IF vnvlsaldoitem > 0 THEN
                -- Se não for faturamento
                IF p_tipo <> 'F' THEN
                  vnvlsaldoitem := 0;
                END IF;
              ELSE
                -- Se não for venda
                IF p_tipo <> 'V' THEN
                  vnvlsaldoitem := 0;
                END IF;
              END IF;
            ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'VA' THEN
              --Débito Venda /crédito no Acerto
              IF vnvlsaldoitem < 0 THEN
                -- Se não for venda
                IF p_tipo <> 'V' THEN
                  vnvlsaldoitem := 0;
                END IF;
              ELSE
                --se não for acerto
                IF p_tipo <> 'A' THEN
                  vnvlsaldoitem := 0;
                END IF;
              END IF;
            -- HIS.01108.2016 - Crédito do Conta Corrente por Liquidez
            ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'LL' THEN
              --Débito /crédito na Liquidez
              -- Se não for liquidez
              IF p_tipo <> 'L' THEN
                vnvlsaldoitem := 0;
              END IF;
            -- HIS.01108.2016 - Crédito do Conta Corrente por Liquidez
            ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'VL' THEN
              --Débito venda /crédito na Liquidez
              IF vnvlsaldoitem > 0 THEN
                -- Se não for Liquidez
                IF p_tipo <> 'L' THEN
                  vnvlsaldoitem := 0;
                END IF;
              ELSE
                -- Se não for venda
                IF p_tipo <> 'V' THEN
                  vnvlsaldoitem := 0;
                END IF;
              END IF;
            END IF;
          END IF;
        ELSIF nvl(p_usadebcredrca,
                  NVL(p_usacredrca, gregpcconsum.usacredrca)) = 'N' THEN
          vnvlsaldoitem := 0;
        END IF;
      ELSE
        --p_usacredrca = 'N'
        vnvlsaldoitem := 0;
      END IF;
    end if;

    RETURN vnvlsaldoitem;
  END; -- ccrca_saldo_item

  FUNCTION ccrca_saldo_item( -- 22 Parametros
                            p_usacredrca           IN pcpedc.usacredrca%TYPE,
                            p_usadebcredrca        IN pcpedc.usadebcredrca%TYPE,
                            p_broker               IN pcpedc.broker%TYPE,
                            p_origemped            IN pcpedc.origemped%TYPE,
                            p_bonificaltdebcredrca IN pcpedc.bonificaltdebcredrca%TYPE,
                            p_trocaaltdebcredrca   IN pcpedc.trocaaltdebcredrca%TYPE,
                            p_crmaltdebcredrca     IN pcpedc.crmaltdebcredrca%TYPE,
                            p_brokeraltdebcredrca  IN pcpedc.brokeraltdebcredrca%TYPE,
                            p_tipomovccrca         IN pcpedc.tipomovccrca%TYPE,
                            p_condvenda            IN pcpedc.condvenda%TYPE,
                            p_brinde               IN pcpedc.brinde%TYPE,
                            p_codusur              IN pcpedc.codusur%TYPE,
                            p_tipo                 IN VARCHAR2,
                            --tipo de processo V - Venda, F - Faturamento, C - Cancelamento, D - devolucao, A - Acerto
                            p_pvenda                    IN pcpedi.pvenda%TYPE,
                            p_ptabela                   IN pcpedi.ptabela%TYPE,
                            p_pbaserca                  IN pcpedi.pbaserca%TYPE,
                            p_qt                        IN pcpedi.qt%TYPE,
                            p_usaDebCredRCABrind        IN pcpedi.usadebcredrcabrind%TYPE, -- Tarefa 100601
                            p_movimentacontacorrenterca IN pcpedi.movimentacontacorrenterca%type,
                            p_stpvenda                  IN pcpedi.st%TYPE,
                            p_stptabela                 IN pcpedi.stptabela%TYPE,
                            p_stpbaserca                IN pcpedi.stpbaserca%TYPE,
                            p_prodBonific               IN pcpedi.BONIFIC%TYPE DEFAULT 'N' -- CC_ITEMBNF
                            ) RETURN NUMBER IS
    vnvlsaldoitem NUMBER;
    vsmsg         VARCHAR2(400);
    vsusapbasercacomobase VARCHAR2(1);

  BEGIN
    --RNG03
    SELECT (DECODE(p_condvenda, 5, 0, NVL(p_pvenda, 0) - NVL(p_stpvenda,0)) -
            DECODE(p_pbaserca,0, NVL(p_ptabela, 0) - NVL(p_stptabela,0),p_pbaserca - NVL(p_stpbaserca,0))) * NVL(p_qt, 0)
      INTO vnvlsaldoitem
      FROM DUAL;

    vsusapbasercacomobase := 'N';

    -- Pesquisa Parametro "USAPBASERCACOMOBASE"
    BEGIN
      SELECT PCPARAMFILIAL.VALOR
        INTO vsusapbasercacomobase
        FROM PCPARAMFILIAL
       WHERE (PCPARAMFILIAL.CODFILIAL = '99')
         AND (PCPARAMFILIAL.NOME      = 'USAPBASERCACOMOBASE');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vsusapbasercacomobase := 'N';
    END;

    proc_lerparametros(vsmsg);

    if p_movimentacontacorrenterca = 'N' then

      vnvlsaldoitem := 0;

    else

      --RNG06
      IF NVL(p_usacredrca, gregpcconsum.usacredrca) = 'S' THEN
        IF nvl(p_usadebcredrca, NVL(p_usacredrca, gregpcconsum.usacredrca)) = 'S' THEN
          IF p_condvenda IN (4, 8, 10, 13, 16, 20) THEN
            vnvlsaldoitem := 0;
          ELSE
            IF (NVL(p_brinde, 'N') = 'S') THEN
              IF (NVL(p_usaDebCredRCABrind,'N') = 'N') THEN -- Tarefa 100601
                vnvlsaldoitem := 0;
              ELSIF (p_condvenda = 1) AND (NVL(p_prodbonific,'N') = 'F') THEN -- DDVENDAS-41579
                IF (NVL(p_bonificaltdebcredrca,
                        gregpcconsum.bonificaltdebcredrca) = 'N') THEN
                  vnvlsaldoitem := 0;
                ELSE
                  IF vsusapbasercacomobase = 'S' THEN
                    IF (NVL(p_pbaserca,0) = 0) THEN
                      vnvlsaldoitem := ((NVL(p_ptabela, 0) - NVL(p_stptabela,0)) * NVL(p_qt, 0)) * (-1); -->> SEM ST
                    ELSE
                      vnvlsaldoitem := ((NVL(p_pbaserca, 0) - NVL(p_stpbaserca,0)) * NVL(p_qt, 0)) * (-1); -->> SEM ST
                    END IF;  
                  ELSE
                    vnvlsaldoitem := ((NVL(p_pvenda, 0) - NVL(p_stpvenda,0)) * NVL(p_qt, 0)) * (-1); -->> SEM ST
                  END IF;
                END IF;                
              END IF;
            ELSE
              IF (p_condvenda = 1) AND
                 (NVL(p_prodbonific,'N') = 'F') THEN -- CC_ITEMBNF
                IF (NVL(p_bonificaltdebcredrca,
                        gregpcconsum.bonificaltdebcredrca) = 'N') THEN
                  vnvlsaldoitem := 0;
                ELSE
                  IF vsusapbasercacomobase = 'S' THEN --
                    -- DDMEDICA-5403 - Usar o PBASERCA com o parâmetro USAPBASERCACOMOBASE
                    IF (NVL(p_pbaserca,0) = 0) THEN
                      vnvlsaldoitem := ((NVL(p_ptabela, 0) - NVL(p_stptabela,0)) * NVL(p_qt, 0)) * (-1); -->> SEM ST
                    ELSE
                      vnvlsaldoitem := ((NVL(p_pbaserca, 0) - NVL(p_stpbaserca,0)) * NVL(p_qt, 0)) * (-1); -->> SEM ST
                    END IF;  
                  ELSE
                    vnvlsaldoitem := ((NVL(p_pvenda, 0) - NVL(p_stpvenda,0)) * NVL(p_qt, 0)) * (-1); -->> SEM ST
                  END IF;
                END IF;
              ELSIF p_condvenda = 5 THEN
                IF (NVL(p_bonificaltdebcredrca,
                        gregpcconsum.bonificaltdebcredrca) = 'N') THEN
                  vnvlsaldoitem := 0;
                END IF;
              ELSIF p_condvenda = 11 THEN
                IF NVL(p_trocaaltdebcredrca,
                       gregpcconsum.trocaaltdebcredrca) = 'N' THEN
                  vnvlsaldoitem := 0;
                END IF;
              ELSE
                IF NVL(p_broker, 'N') = 'S' THEN
                  --Broker
                  IF NVL(p_brokeraltdebcredrca,
                         gregpcconsum.brokeraltdebcredrca) = 'N' THEN
                    vnvlsaldoitem := 0;
                  END IF;
                ELSIF p_origemped = 'C' THEN
                  --Callcenter
                  IF NVL(p_crmaltdebcredrca, gregpcconsum.crmaltdebcredrca) = 'N' THEN
                    vnvlsaldoitem := 0;
                  END IF;
                END IF;
              END IF;
            END IF;
          END IF;

          -- Se não for cancelamento/devolução
          IF p_tipo NOT IN ('C', 'D') THEN
            --RNG04
            IF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'VV' THEN
              --Débito/crédito na venda
              -- Se não for venda
              IF p_tipo <> 'V' THEN
                vnvlsaldoitem := 0;
              END IF;
            ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'FF' THEN
              --Débito /crédito no faturamento
              -- Se não for faturamento
              IF p_tipo <> 'F' THEN
                vnvlsaldoitem := 0;
              END IF;
            ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'VF' THEN
              --Débito venda /crédito no faturamento
              IF vnvlsaldoitem > 0 THEN
                -- Se não for faturamento
                IF p_tipo <> 'F' THEN
                  vnvlsaldoitem := 0;
                END IF;
              ELSE
                -- Se não for venda
                IF p_tipo <> 'V' THEN
                  vnvlsaldoitem := 0;
                END IF;
              END IF;
            ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'VA' THEN
              --Débito Venda /crédito no Acerto
              IF vnvlsaldoitem < 0 THEN
                -- Se não for venda
                IF p_tipo <> 'V' THEN
                  vnvlsaldoitem := 0;
                END IF;
              ELSE
                --se não for acerto
                IF p_tipo <> 'A' THEN
                  vnvlsaldoitem := 0;
                END IF;
              END IF;
            -- HIS.01108.2016 - Crédito do Conta Corrente por Liquidez
            ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'LL' THEN
              --Débito /crédito na Liquidez
              -- Se não for liquidez
              IF p_tipo <> 'L' THEN
                vnvlsaldoitem := 0;
              END IF;
            -- HIS.01108.2016 - Crédito do Conta Corrente por Liquidez
            ELSIF NVL(p_tipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) = 'VL' THEN
              --Débito venda /crédito na Liquidez
              IF vnvlsaldoitem > 0 THEN
                -- Se não for Liquidez
                IF p_tipo <> 'L' THEN
                  vnvlsaldoitem := 0;
                END IF;
              ELSE
                -- Se não for venda
                IF p_tipo <> 'V' THEN
                  vnvlsaldoitem := 0;
                END IF;
              END IF;
            END IF;
          END IF;
        ELSIF nvl(p_usadebcredrca,
                  NVL(p_usacredrca, gregpcconsum.usacredrca)) = 'N' THEN
          vnvlsaldoitem := 0;
        END IF;
      ELSE
        --p_usacredrca = 'N'
        vnvlsaldoitem := 0;
      END IF;
    end if;

    RETURN vnvlsaldoitem;
  END; -- ccrca_saldo_item

  --RNG07
  FUNCTION ccrca_retorna_saldo_itempedido(p_numped  IN pcpedc.numped%TYPE,
                                          p_codusur IN pcpedc.codusur%TYPE,
                                          p_codprod IN pcpedi.codprod%TYPE,
                                          p_numseq  IN pcpedi.numseq%TYPE,
                                          p_qt      IN pcpedi.qt%TYPE,
                                          p_tipo    IN VARCHAR,
                                          -- Sabrina: tipo de operação I - Inclusao e E - Exclusao
                                          p_rotina                      IN pclogrca.rotina%TYPE DEFAULT 0,
                                          p_percrateiocredrcasupervisor IN pclogrca.percrateiocredrcasupervisor%TYPE DEFAULT 0
                                          ) RETURN NUMBER IS
    vsusacredrca                pcpedc.usacredrca%TYPE;
    vsbonificaltdebcredrca      pcpedc.bonificaltdebcredrca%TYPE;
    vstrocaaltdebcredrca        pcpedc.trocaaltdebcredrca%TYPE;
    vsbrokeraltdebcredrca       pcpedc.brokeraltdebcredrca%TYPE;
    vscrmaltdebcredrca          pcpedc.crmaltdebcredrca%TYPE;
    vstipomovccrca              pcpedc.tipomovccrca%TYPE;
    vsusadebcredrca             pcpedc.usadebcredrca%TYPE;
    vsorigemped                 pcpedc.origemped%TYPE;
    vsbrinde                    pcpedc.brinde%TYPE;
    vncondvenda                 pcpedc.condvenda%TYPE;
    vsbroker                    pcpedc.broker%TYPE;
    vnpvenda                    pcpedi.pvenda%TYPE;
    vnptabela                   pcpedi.ptabela%TYPE;
    vnpbaserca                  pcpedi.pbaserca%TYPE;
    vnstpvenda                  pcpedi.st%TYPE;
    vnstptabela                 pcpedi.stptabela%TYPE;
    vnstpbaserca                pcpedi.stpbaserca%TYPE;
    vnlanc                      NUMBER;
    vsusadebcredrcabrind        pcpedi.usadebcredrcabrind%TYPE;
    vsmsg                       VARCHAR2(400);
    vsmovimentacontacorrenterca pcpedi.movimentacontacorrenterca%type;
    -- HIS.00632.2016
    vncodusur                   pcpedc.codusur%type;
    -- LIMITE_FLEX
    vnVlUnitLimCredRcaUtiliz    NUMBER;
    -- CC_ITEMBNF
    vsbonific                   pcpedi.bonific%TYPE;
    -- DDVENDAS-41579
    vsItemBrinde                pcpedi.brinde%TYPE;
  BEGIN
    proc_lerparametros(vsmsg);

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(p_codusur,
                                       p_numped);

    SELECT p.usacredrca,
           p.bonificaltdebcredrca,
           p.trocaaltdebcredrca,
           p.brokeraltdebcredrca,
           p.crmaltdebcredrca,
           p.tipomovccrca,
           DECODE(p.usadebcredrca,
                  NULL,
                  (SELECT NVL(pcusuari.usadebcredrca, gregpcconsum.usacredrca)
                     FROM pcusuari
                    WHERE codusur = vncodusur -- HIS.00632.2016 -- p.codusur
                      AND ROWNUM = 1),
                  p.usadebcredrca),
           p.origemped,
           NVL(p.brinde, 'N'),
           p.condvenda,
           NVL(p.broker, 'N')
      INTO vsusacredrca,
           vsbonificaltdebcredrca,
           vstrocaaltdebcredrca,
           vsbrokeraltdebcredrca,
           vscrmaltdebcredrca,
           vstipomovccrca,
           vsusadebcredrca,
           vsorigemped,
           vsbrinde,
           vncondvenda,
           vsbroker
      FROM pcpedc p
     WHERE p.numped = p_numped;

    SELECT pvenda,
           ptabela,
           pbaserca,
           NVL(usadebcredrcabrind, 'N'),
           nvl(pcpedi.movimentacontacorrenterca, 'S'),
           NVL(st,0),
           NVL(stptabela,0),
           NVL(stpbaserca,0),
           NVL(vlunitlimcredrcautilizmed,0), -- LIMITE_FLEX
           nvl(pcpedi.BONIFIC, 'N') BONIFIC, -- CC_ITEMBNF
           pcpedi.brinde -- DDVENDAS-41579
      INTO vnpvenda,
           vnptabela,
           vnpbaserca,
           vsusadebcredrcabrind,
           vsmovimentacontacorrenterca,
           vnstpvenda,
           vnstptabela,
           vnstpbaserca,
           vnVlUnitLimCredRcaUtiliz, -- LIMITE_FLEX
           vsbonific, -- CC_ITEMBNF
           vsItemBrinde -- DDVENDAS-41579
      FROM pcpedi
     WHERE numped = p_numped
       AND codprod = p_codprod
       AND numseq = p_numseq;
     
    -- DDVENDAS-41579
    IF (vsItemBrinde = 'S') THEN
      vsbrinde := 'S';
    END IF;

    IF p_qt > 0 THEN
      -- LIMITE_FLEX
      IF (NVL(vstipomovccrca,' ') = 'LL') THEN
        vnlanc := ROUND((vnVlUnitLimCredRcaUtiliz * p_qt), 2);
      ELSE
        vnlanc := ccrca_saldo_item(NVL(vsusacredrca, gregpcconsum.usacredrca),
                                   vsusadebcredrca,
                                   vsbroker,
                                   vsorigemped,
                                   NVL(vsbonificaltdebcredrca,
                                       gregpcconsum.bonificaltdebcredrca),
                                   NVL(vstrocaaltdebcredrca,
                                       gregpcconsum.trocaaltdebcredrca),
                                   NVL(vscrmaltdebcredrca,
                                       gregpcconsum.crmaltdebcredrca),
                                   NVL(vsbrokeraltdebcredrca,
                                       gregpcconsum.brokeraltdebcredrca),
                                   NVL(vstipomovccrca,
                                       NVL(gregpcconsum.tipomovccrca, 'VV')),
                                   vncondvenda,
                                   vsbrinde,
                                   vncodusur, -- HIS.00632.2016 -- p_codusur,
                                   'V',
                                   vnpvenda,
                                   vnptabela,
                                   NVL(vnpbaserca, vnptabela),
                                   p_qt,
                                   vsusadebcredrcabrind,
                                   vsmovimentacontacorrenterca,
                                   vnstpvenda,
                                   vnstptabela,
                                   vnstpbaserca,
                                   vsbonific -- CC_ITEMBNF
                                   );
      END IF;
    ELSE
      vnlanc := 0; --(recebimentos em trocas)
    END IF;

    -----------------------------------------------------
    -- Se houver Rateio de Crédito de C/C RCA
    -- E << NÃO >> estiver chamando da Inclusão do Pedido
    -----------------------------------------------------
    IF (F_USARATEIOCREDRCASUPERVISOR(vncodusur,
                                     NVL(p_percrateiocredrcasupervisor,0),
                                     NVL(vnlanc,0))) AND
       (p_rotina NOT IN (2316,8888,2513)) THEN
      -- Valor do Lançamento - Diferença do % que ficará com o RCA
      vnlanc := ROUND(NVL(vnlanc,0) * (NVL(p_percrateiocredrcasupervisor,0) / 100),2);
    END IF;

    RETURN vnlanc;
  END; --ccrca_retornar_saldo_item_pedido

  --RNG07 / PARA ALTERACAO DE PRECO
  FUNCTION ccrca_retorna_saldo_anterior( -- 09 parametros
                                        p_numped   IN pcpedc.numped%TYPE,
                                        p_codusur  IN pcpedc.codusur%TYPE,
                                        p_codprod  IN pcpedi.codprod%TYPE,
                                        p_numseq   IN pcpedi.numseq%TYPE,
                                        p_qt       IN pcpedi.qt%TYPE,
                                        p_pvenda   IN pcpedi.pvenda%TYPE,
                                        p_pbaserca IN pcpedi.pbaserca%TYPE,
                                        p_ptabela  IN pcpedi.ptabela%TYPE,
                                        p_tipo     IN VARCHAR
                                        -- Sabrina: tipo de operação I - Inclusao e E - Exclusao
                                        ) RETURN NUMBER IS
    vsusacredrca                pcpedc.usacredrca%TYPE;
    vsbonificaltdebcredrca      pcpedc.bonificaltdebcredrca%TYPE;
    vstrocaaltdebcredrca        pcpedc.trocaaltdebcredrca%TYPE;
    vsbrokeraltdebcredrca       pcpedc.brokeraltdebcredrca%TYPE;
    vscrmaltdebcredrca          pcpedc.crmaltdebcredrca%TYPE;
    vstipomovccrca              pcpedc.tipomovccrca%TYPE;
    vsusadebcredrca             pcpedc.usadebcredrca%TYPE;
    vsorigemped                 pcpedc.origemped%TYPE;
    vsbrinde                    pcpedc.brinde%TYPE;
    vncondvenda                 pcpedc.condvenda%TYPE;
    vsbroker                    pcpedc.broker%TYPE;
    vnlanc                      NUMBER;
    vsmsg                       VARCHAR2(400);
    vsusadebcredrcabrind        pcpedi.usadebcredrcabrind%type;
    vsmovimentacontacorrenterca pcpedi.movimentacontacorrenterca%type;
    -- HIS.00632.2016
    vncodusur                   pcpedc.codusur%type;
    -- MED-2073
    vvBONIFIC                   pcpedi.BONIFIC%TYPE;
    -- DDVENDAS-41579
    vsItemBrinde                pcpedi.brinde%TYPE;
  BEGIN
    proc_lerparametros(vsmsg);

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(p_codusur,
                                       p_numped);

    SELECT p.usacredrca,
           p.bonificaltdebcredrca,
           p.trocaaltdebcredrca,
           p.brokeraltdebcredrca,
           p.crmaltdebcredrca,
           p.tipomovccrca,
           DECODE(p.usadebcredrca,
                  NULL,
                  (SELECT NVL(pcusuari.usadebcredrca, gregpcconsum.usacredrca)
                     FROM pcusuari
                    WHERE codusur = vncodusur -- HIS.00632.2016 -- p.codusur
                      AND ROWNUM = 1),
                  p.usadebcredrca),
           p.origemped,
           NVL(p.brinde, 'N'),
           p.condvenda,
           NVL(p.broker, 'N'),
           i.usadebcredrcabrind,
           nvl(i.movimentacontacorrenterca, 'S'),
           NVL(i.BONIFIC,'N'), -- MED-2073
           i.brinde -- DDVENDAS-41579
      INTO vsusacredrca,
           vsbonificaltdebcredrca,
           vstrocaaltdebcredrca,
           vsbrokeraltdebcredrca,
           vscrmaltdebcredrca,
           vstipomovccrca,
           vsusadebcredrca,
           vsorigemped,
           vsbrinde,
           vncondvenda,
           vsbroker,
           vsusadebcredrcabrind,
           vsmovimentacontacorrenterca,
           vvBONIFIC, -- MED-2073
           vsItemBrinde
      FROM pcpedc p, pcpedi i
     WHERE p.numped = p_numped
       and p.numped = i.numped;

    -- DDVENDAS-41579
    IF (vsItemBrinde = 'S') THEN
      vsbrinde := 'S';
    END IF;

    IF p_qt > 0 THEN
      vnlanc := ccrca_saldo_item(NVL(vsusacredrca, gregpcconsum.usacredrca),
                                 vsusadebcredrca,
                                 vsbroker,
                                 vsorigemped,
                                 NVL(vsbonificaltdebcredrca,
                                     gregpcconsum.bonificaltdebcredrca),
                                 NVL(vstrocaaltdebcredrca,
                                     gregpcconsum.trocaaltdebcredrca),
                                 NVL(vscrmaltdebcredrca,
                                     gregpcconsum.crmaltdebcredrca),
                                 NVL(vsbrokeraltdebcredrca,
                                     gregpcconsum.brokeraltdebcredrca),
                                 NVL(vstipomovccrca,
                                     NVL(gregpcconsum.tipomovccrca, 'VV')),
                                 vncondvenda,
                                 vsbrinde,
                                 vncodusur, -- HIS.00632.2016 -- p_codusur,
                                 'V',
                                 p_pvenda,
                                 p_ptabela,
                                 NVL(p_pbaserca, p_ptabela),
                                 p_qt,
                                 vsusadebcredrcabrind,
                                 vsmovimentacontacorrenterca,
                                 vvBONIFIC); -- MED-2073
    ELSE
      vnlanc := 0; --(recebimentos em trocas)
    END IF;

    RETURN vnlanc;
  END; --ccrca_retornar_saldo_anterior

  ---------------------------------------------------------------------
  -- Procedimento: ccrca_retornar_saldo_itepedfat
  -- Descrição...: Por causa dos Locks do Rateio, tive que transferir
  --               a parte final para o Faturamento.
  --               Com isso precisei pegar o Saldo como busca no Pedido
  --               para usar no Faturamento
  ---------------------------------------------------------------------
  FUNCTION ccrca_retornar_saldo_itepedfat(p_numped  IN pcpedc.numped%TYPE,
                                          p_codusur IN pcpedc.codusur%TYPE,
                                          p_codprod IN pcpedi.codprod%TYPE,
                                          p_numseq  IN pcpedi.numseq%TYPE,
                                          p_qt      IN pcpedi.qt%TYPE,
                                          p_tipo    IN VARCHAR,
                                          -- Sabrina: tipo de operação I - Inclusao e E - Exclusao
                                          p_rotina                      IN pclogrca.rotina%TYPE DEFAULT 0,
                                          p_percrateiocredrcasupervisor IN pclogrca.percrateiocredrcasupervisor%TYPE DEFAULT 0
                                          ) RETURN NUMBER IS
    vsusacredrca                pcpedc.usacredrca%TYPE;
    vsbonificaltdebcredrca      pcpedc.bonificaltdebcredrca%TYPE;
    vstrocaaltdebcredrca        pcpedc.trocaaltdebcredrca%TYPE;
    vsbrokeraltdebcredrca       pcpedc.brokeraltdebcredrca%TYPE;
    vscrmaltdebcredrca          pcpedc.crmaltdebcredrca%TYPE;
    vstipomovccrca              pcpedc.tipomovccrca%TYPE;
    vsusadebcredrca             pcpedc.usadebcredrca%TYPE;
    vsorigemped                 pcpedc.origemped%TYPE;
    vsbrinde                    pcpedc.brinde%TYPE;
    vncondvenda                 pcpedc.condvenda%TYPE;
    vsbroker                    pcpedc.broker%TYPE;
    vnpvenda                    pcpedi.pvenda%TYPE;
    vnptabela                   pcpedi.ptabela%TYPE;
    vnpbaserca                  pcpedi.pbaserca%TYPE;
    vnstpvenda                  pcpedi.st%TYPE;
    vnstptabela                 pcpedi.stptabela%TYPE;
    vnstpbaserca                pcpedi.stpbaserca%TYPE;
    vnlanc                      NUMBER;
    vsusadebcredrcabrind        pcpedi.usadebcredrcabrind%TYPE;
    vsmsg                       VARCHAR2(400);
    vsmovimentacontacorrenterca pcpedi.movimentacontacorrenterca%type;
    -- HIS.00632.2016
    vncodusur                   pcpedc.codusur%type;
    -- LIMITE_FLEX
    vnVlUnitLimCredRcaUtiliz    NUMBER;
    -- CC_ITEMBNF
    vsbonific                   pcpedi.bonific%TYPE;
    -- DDVENDAS-41579
    vsItemBrinde                pcpedi.brinde%TYPE;    
  BEGIN
    proc_lerparametros(vsmsg);

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(p_codusur,
                                       p_numped);

    SELECT p.usacredrca,
           p.bonificaltdebcredrca,
           p.trocaaltdebcredrca,
           p.brokeraltdebcredrca,
           p.crmaltdebcredrca,
           p.tipomovccrca,
           DECODE(p.usadebcredrca,
                  NULL,
                  (SELECT NVL(pcusuari.usadebcredrca, gregpcconsum.usacredrca)
                     FROM pcusuari
                    WHERE codusur = vncodusur -- HIS.00632.2016 -- p.codusur
                      AND ROWNUM = 1),
                  p.usadebcredrca),
           p.origemped,
           NVL(p.brinde, 'N'),
           p.condvenda,
           NVL(p.broker, 'N')
      INTO vsusacredrca,
           vsbonificaltdebcredrca,
           vstrocaaltdebcredrca,
           vsbrokeraltdebcredrca,
           vscrmaltdebcredrca,
           vstipomovccrca,
           vsusadebcredrca,
           vsorigemped,
           vsbrinde,
           vncondvenda,
           vsbroker
      FROM pcpedc p
     WHERE p.numped = p_numped;

    SELECT pvenda,
           ptabela,
           pbaserca,
           NVL(usadebcredrcabrind, 'N'),
           nvl(pcpedi.movimentacontacorrenterca, 'S'),
           NVL(st,0),
           NVL(stptabela,0),
           NVL(stpbaserca,0),
           NVL(vlunitlimcredrcautilizmed,0), -- LIMITE_FLEX
           nvl(pcpedi.BONIFIC, 'N') BONIFIC, -- CC_ITEMBNF
           pcpedi.brinde -- DDVENDAS-41579
      INTO vnpvenda,
           vnptabela,
           vnpbaserca,
           vsusadebcredrcabrind,
           vsmovimentacontacorrenterca,
           vnstpvenda,
           vnstptabela,
           vnstpbaserca,
           vnVlUnitLimCredRcaUtiliz, -- LIMITE_FLEX
           vsbonific, -- CC_ITEMBNF
           vsItemBrinde -- DDVENDAS-41579
      FROM pcpedi
     WHERE numped = p_numped
       AND codprod = p_codprod
       AND numseq = p_numseq;

    -- DDVENDAS-41579
    IF (vsItemBrinde = 'S') THEN
      vsbrinde := 'S';
    END IF;

    IF p_qt > 0 THEN
      -- LIMITE_FLEX
      IF (NVL(vstipomovccrca,' ') = 'LL') THEN
        vnlanc := ROUND((vnVlUnitLimCredRcaUtiliz * p_qt), 2);
      ELSE
        vnlanc := ccrca_saldo_item(NVL(vsusacredrca, gregpcconsum.usacredrca),
                                   vsusadebcredrca,
                                   vsbroker,
                                   vsorigemped,
                                   NVL(vsbonificaltdebcredrca,
                                       gregpcconsum.bonificaltdebcredrca),
                                   NVL(vstrocaaltdebcredrca,
                                       gregpcconsum.trocaaltdebcredrca),
                                   NVL(vscrmaltdebcredrca,
                                       gregpcconsum.crmaltdebcredrca),
                                   NVL(vsbrokeraltdebcredrca,
                                       gregpcconsum.brokeraltdebcredrca),
                                   NVL(vstipomovccrca,
                                       NVL(gregpcconsum.tipomovccrca, 'VV')),
                                   vncondvenda,
                                   vsbrinde,
                                   vncodusur, -- HIS.00632.2016 -- p_codusur,
                                   'V',
                                   vnpvenda,
                                   vnptabela,
                                   NVL(vnpbaserca, vnptabela),
                                   p_qt,
                                   vsusadebcredrcabrind,
                                   vsmovimentacontacorrenterca,
                                   vnstpvenda,
                                   vnstptabela,
                                   vnstpbaserca,
                                   vsbonific -- CC_ITEMBNF
                                   );
      END IF;
    ELSE
      vnlanc := 0; --(recebimentos em trocas)
    END IF;

    --***
    -- NESTE PROCESSO ccrca_retornar_saldo_itepedfat PRECISO DO VALOR INTEGRAL
    -- PRA FAZER AS CONTAS NA PROCEDURE CHAMADORA, para fazer a compensação do Rateio no Faturamento
    --***
    -----------------------------------------------------
    -- Se houver Rateio de Crédito de C/C RCA
    -- E << NÃO >> estiver chamando da Inclusão do Pedido
    -----------------------------------------------------
    --IF (F_USARATEIOCREDRCASUPERVISOR(vncodusur,
    --                                 NVL(p_percrateiocredrcasupervisor,0),
    --                                 NVL(vnlanc,0))) AND
    --   (p_rotina NOT IN (2316,8888,2513)) THEN
    --  -- Valor do Lançamento - Diferença do % que ficará com o RCA
    --  vnlanc := ROUND(NVL(vnlanc,0) * (NVL(p_percrateiocredrcasupervisor,0) / 100),2);
    --END IF;

    RETURN vnlanc;
  END; --ccrca_retornar_saldo_itepedfat

  --RNG07 / PARA ALTERACAO DE PRECO
  FUNCTION ccrca_retorna_saldo_anterior( -- 10 parametros
                                        p_numped             IN pcpedc.numped%TYPE,
                                        p_codusur            IN pcpedc.codusur%TYPE,
                                        p_codprod            IN pcpedi.codprod%TYPE,
                                        p_numseq             IN pcpedi.numseq%TYPE,
                                        p_qt                 IN pcpedi.qt%TYPE,
                                        p_pvenda             IN pcpedi.pvenda%TYPE,
                                        p_pbaserca           IN pcpedi.pbaserca%TYPE,
                                        p_ptabela            IN pcpedi.ptabela%TYPE,
                                        p_tipo               IN VARCHAR,
                                        p_usadebcredrcabrind IN pcpedi.usadebcredrcabrind%TYPE
                                        -- Sabrina: tipo de operação I - Inclusao e E - Exclusao
                                        ) RETURN NUMBER IS
    vsusacredrca           pcpedc.usacredrca%TYPE;
    vsbonificaltdebcredrca pcpedc.bonificaltdebcredrca%TYPE;
    vstrocaaltdebcredrca   pcpedc.trocaaltdebcredrca%TYPE;
    vsbrokeraltdebcredrca  pcpedc.brokeraltdebcredrca%TYPE;
    vscrmaltdebcredrca     pcpedc.crmaltdebcredrca%TYPE;
    vstipomovccrca         pcpedc.tipomovccrca%TYPE;
    vsusadebcredrca        pcpedc.usadebcredrca%TYPE;
    vsorigemped            pcpedc.origemped%TYPE;
    vsbrinde               pcpedc.brinde%TYPE;
    vncondvenda            pcpedc.condvenda%TYPE;
    vsbroker               pcpedc.broker%TYPE;
    vnlanc                 NUMBER;
    vsmsg                  VARCHAR2(400);
    -- HIS.00632.2016
    vncodusur              pcpedc.codusur%type;
  BEGIN
    proc_lerparametros(vsmsg);

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(p_codusur,
                                       p_numped);

    SELECT p.usacredrca,
           p.bonificaltdebcredrca,
           p.trocaaltdebcredrca,
           p.brokeraltdebcredrca,
           p.crmaltdebcredrca,
           p.tipomovccrca,
           DECODE(p.usadebcredrca,
                  NULL,
                  (SELECT NVL(pcusuari.usadebcredrca, gregpcconsum.usacredrca)
                     FROM pcusuari
                    WHERE codusur = vncodusur -- HIS.00632.2016 -- p.codusur
                      AND ROWNUM = 1),
                  p.usadebcredrca),
           p.origemped,
           NVL(p.brinde, 'N'),
           p.condvenda,
           NVL(p.broker, 'N')
      INTO vsusacredrca,
           vsbonificaltdebcredrca,
           vstrocaaltdebcredrca,
           vsbrokeraltdebcredrca,
           vscrmaltdebcredrca,
           vstipomovccrca,
           vsusadebcredrca,
           vsorigemped,
           vsbrinde,
           vncondvenda,
           vsbroker
      FROM pcpedc p
     WHERE p.numped = p_numped;
       
    IF p_qt > 0 THEN
      vnlanc := ccrca_saldo_item(NVL(vsusacredrca, gregpcconsum.usacredrca),
                                 vsusadebcredrca,
                                 vsbroker,
                                 vsorigemped,
                                 NVL(vsbonificaltdebcredrca,
                                     gregpcconsum.bonificaltdebcredrca),
                                 NVL(vstrocaaltdebcredrca,
                                     gregpcconsum.trocaaltdebcredrca),
                                 NVL(vscrmaltdebcredrca,
                                     gregpcconsum.crmaltdebcredrca),
                                 NVL(vsbrokeraltdebcredrca,
                                     gregpcconsum.brokeraltdebcredrca),
                                 NVL(vstipomovccrca,
                                     NVL(gregpcconsum.tipomovccrca, 'VV')),
                                 vncondvenda,
                                 vsbrinde,
                                 vncodusur, -- HIS.00632.2016 -- p_codusur,
                                 'V',
                                 p_pvenda,
                                 p_ptabela,
                                 NVL(p_pbaserca, p_ptabela),
                                 p_qt,
                                 p_usadebcredrcabrind);
    ELSE
      vnlanc := 0; --(recebimentos em trocas)
    END IF;

    RETURN vnlanc;
  END; --ccrca_retornar_saldo_anterior

  --RNG08
  FUNCTION ccrca_estorna_item_pedido(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                     p_rotinalanc  IN pclogrca.rotina%TYPE,
                                     p_codusur     IN pcpedc.codusur%TYPE,
                                     p_numped      IN pcpedc.numped%TYPE,
                                     p_codprod     IN pcpedi.codprod%TYPE,
                                     p_numseq      IN pcpedi.numseq%TYPE,
                                     p_qt          IN pcpedi.qt%TYPE)
    RETURN BOOLEAN IS
    vnvalorlanc        NUMBER;
    vnvlcorrente_ant   pcusuari.vlcorrente%TYPE;
    vsusadebcredrca    pcusuari.usadebcredrca%TYPE;
    vnvllimcred        pcusuari.vllimcred%TYPE;
    vnvlcorrente_atual pcusuari.vlcorrente%TYPE;
    vddata             pcpedc.DATA%TYPE;
    vnnumtransvenda    pcpedc.numtransvenda%TYPE;
    vsposicao          pcpedc.posicao%TYPE;
    vbvalido           BOOLEAN;
    -- Log
    TYPE TRecItem                   IS RECORD(
         nPVENDA                    PCLOGRCA.PVENDA%TYPE,
         nST                        PCLOGRCA.ST%TYPE,
         nPBASERCA                  PCLOGRCA.PBASERCA%TYPE,
         nSTPBASERCA                PCLOGRCA.STPBASERCA%TYPE,
         nPTABELA                   PCLOGRCA.PTABELA%TYPE,
         nSTPTABELA                 PCLOGRCA.STPTABELA%TYPE,
         nBONIFIC                   PCLOGRCA.BONIFIC%TYPE,
         nQT                        PCLOGRCA.QT%TYPE,
         vUSADEBCREDRCABRIND        PCLOGRCA.USADEBCREDRCABRIND%TYPE,
         vMOVIMENTACONTACORRENTERCA PCLOGRCA.MOVIMENTACONTACORRENTERCA%TYPE,
         nCODPROMOCAOMED            PCLOGRCA.CODPROMOCAOMED%TYPE,
         nVLUNITLIMCREDRCAUTILIZMED PCPEDI.VLUNITLIMCREDRCAUTILIZMED%TYPE); -- 4954.001502.2017
    vrItem                          TRecItem;
    -- HIS.00632.2016
    vncodusur                       pcpedc.codusur%type;
    -- Variáveis para Rateio Crédito C/C RCA
    nPERCRATEIOCREDRCASUPERVISOR    NUMBER;
    vncodsupervisor                 pcusuari.codsupervisor%type;
    vncod_cadrca_supervisor         PCSUPERV.COD_CADRCA%TYPE;
    vnValorTransf                   NUMBER(15,2);
    -- LIMITE_FLEX
    vvtipomovccrca                  pcpedc.tipomovccrca%type;
    vnvllimcred_atual               pcusuari.vllimcred%type;
  BEGIN
    vbvalido := TRUE;

    -------------------------------------------------------------------------------------------------
    -- HIS.00065.2018 - Se usar o saldo C/C somente no próprio pedido, não acumula o Saldo C/C no RCA
    -------------------------------------------------------------------------------------------------
    IF (F_USARSALDORCASOMENTENOPEDIDO) THEN
      RETURN TRUE;
    END IF;

    -- Obter % Rateio de Crédito de C/C RCA
    nPERCRATEIOCREDRCASUPERVISOR := F_PERCRATEIOCREDRCASUPERVISOR;

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(p_codusur,
                                       p_numped);

    SELECT pcpedc.DATA, pcpedc.numtransvenda, pcpedc.posicao, pcpedc.tipomovccrca
      INTO vddata, vnnumtransvenda, vsposicao, vvtipomovccrca
      FROM pcpedc
     WHERE numped = p_numped;

    ---------------------------------------------------------------------------------
    -- HIS.00052.2017 - Força encerrar o processo se Débito e Crédito no Faturamento,
    -- movimentando o conta corrente do RCA por Pedido no Faturamento
    ---------------------------------------------------------------------------------
    IF (vvtipomovccrca = 'FF') AND
       (F_MOVSALDORCAPORPEDIDOFAT) THEN
      RETURN(TRUE);
    END IF;
    ---------------------------------------------------------------------------------

    SELECT pcusuari.usadebcredrca, pcusuari.vlcorrente, pcusuari.vllimcred, pcusuari.codsupervisor
      INTO vsusadebcredrca, vnvlcorrente_ant, vnvllimcred, vncodsupervisor
      FROM pcusuari
     WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;

    BEGIN
      SELECT PVENDA
           , ST
           , PBASERCA
           , STPBASERCA
           , PTABELA
           , STPTABELA
           , BONIFIC
           , QT
           , USADEBCREDRCABRIND
           , MOVIMENTACONTACORRENTERCA
           , CODPROMOCAOMED
           , VLUNITLIMCREDRCAUTILIZMED -- 4954.001502.2017
        INTO vrItem.nPVENDA
           , vrItem.nST
           , vrItem.nPBASERCA
           , vrItem.nSTPBASERCA
           , vrItem.nPTABELA
           , vrItem.nSTPTABELA
           , vrItem.nBONIFIC
           , vrItem.nQT
           , vrItem.vUSADEBCREDRCABRIND
           , vrItem.vMOVIMENTACONTACORRENTERCA
           , vrItem.nCODPROMOCAOMED
           , vrItem.nVLUNITLIMCREDRCAUTILIZMED -- 4954.001502.2017
        FROM PCPEDI
       WHERE (NUMPED  = p_numped)
         AND (CODPROD = p_codprod)
         AND (NUMSEQ  = p_numseq);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vrItem.nPVENDA                    := NULL;
        vrItem.nST                        := NULL;
        vrItem.nPBASERCA                  := NULL;
        vrItem.nSTPBASERCA                := NULL;
        vrItem.nPTABELA                   := NULL;
        vrItem.nSTPTABELA                 := NULL;
        vrItem.nBONIFIC                   := 'N';
        vrItem.nQT                        := NULL;
        vrItem.vUSADEBCREDRCABRIND        := NULL;
        vrItem.vMOVIMENTACONTACORRENTERCA := NULL;
        vrItem.nCODPROMOCAOMED            := NULL;
        vrItem.nVLUNITLIMCREDRCAUTILIZMED := NULL; -- 4954.001502.2017
    END;

    vnvalorlanc := ccrca_retorna_saldo_itempedido(p_numped,
                                                  vncodusur, -- HIS.00632.2016 -- p_codusur,
                                                  p_codprod,
                                                  p_numseq,
                                                  p_qt,
                                                  'E',
                                                  p_rotinalanc,
                                                  nPERCRATEIOCREDRCASUPERVISOR);

    -- LIMITE_FLEX
    IF (NVL(vvtipomovccrca,' ') = 'LL') THEN

      -- Se Usou Limite
      IF (NVL(vrItem.nVLUNITLIMCREDRCAUTILIZMED,0) <> 0) THEN -- 4954.001502.2017

        -- Valor Utilizado do Limite de Crédito - 4954.001502.2017
        vnvalorlanc := NVL(vrItem.nVLUNITLIMCREDRCAUTILIZMED,0) * NVL(p_qt,0);

        -- ( E - Estorno)
        vnvllimcred_atual := NVL(vnvllimcred, 0) + NVL(vnvalorlanc, 0);

        UPDATE pcusuari
           SET vllimcred = vnvllimcred_atual
         WHERE codusur = vncodusur;

        INSERT INTO pcloglimitecredrcamed
          (numped,
           posicao,
           numtransvenda,
           DATA,
           codfunc,
           codusur,
           rotina,
           vlcorrente,
           vllimcred,
           vlcorrenteant,
           vllimcredant,
           codprod,
           numseq,
           historico,
           PVENDA,
           ST,
           PBASERCA,
           STPBASERCA,
           PTABELA,
           STPTABELA,
           BONIFIC,
           QT,
           USADEBCREDRCABRIND,
           MOVIMENTACONTACORRENTERCA,
           CODPROMOCAOMED,
           PERCRATEIOCREDRCASUPERVISOR)
        VALUES
          (p_numped,
           vsposicao,
           vnnumtransvenda,
           SYSDATE,
           p_codfunclanc,
           vncodusur, -- HIS.00632.2016 -- p_codusur,
           p_rotinalanc,
           vnvlcorrente_ant,
           vnvllimcred_atual,
           vnvlcorrente_ant,
           vnvllimcred,
           p_codprod,
           p_numseq,
           SUBSTR('CTRLCCRCA: ESTORNO DE SALDO DE ITEM PEDIDO', 1, 60),
           vrItem.nPVENDA,
           vrItem.nST,
           vrItem.nPBASERCA,
           vrItem.nSTPBASERCA,
           vrItem.nPTABELA,
           vrItem.nSTPTABELA,
           vrItem.nBONIFIC,
           vrItem.nQT,
           vrItem.vUSADEBCREDRCABRIND,
           vrItem.vMOVIMENTACONTACORRENTERCA,
           vrItem.nCODPROMOCAOMED,
           nPERCRATEIOCREDRCASUPERVISOR);

      END IF; -- Fim: Se Usou Limite

    ELSE

      -- incluído por sabrina ( E - Estorno)
      vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) - NVL(vnvalorlanc, 0);

      -- a package não deve barrar a movimentacao do saldo, os programas eh que fazem isso
      --IF vnvlcorrente_atual >= 0 THEN
      UPDATE pcusuari
         SET vlcorrente = vnvlcorrente_atual
       WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;

      INSERT INTO pclogrca
        (numped,
         posicao,
         numtransvenda,
         DATA,
         codfunc,
         codusur,
         rotina,
         vlcorrente,
         vllimcred,
         vlcorrenteant,
         vllimcredant,
         codprod,
         numseq,
         historico,
         PVENDA,
         ST,
         PBASERCA,
         STPBASERCA,
         PTABELA,
         STPTABELA,
         BONIFIC,
         QT,
         USADEBCREDRCABRIND,
         MOVIMENTACONTACORRENTERCA,
         CODPROMOCAOMED,
         PERCRATEIOCREDRCASUPERVISOR)
      VALUES
        (p_numped,
         vsposicao,
         vnnumtransvenda,
         SYSDATE,
         p_codfunclanc,
         vncodusur, -- HIS.00632.2016 -- p_codusur,
         p_rotinalanc,
         vnvlcorrente_atual,
         vnvllimcred,
         vnvlcorrente_ant,
         vnvllimcred,
         p_codprod,
         p_numseq,
         SUBSTR('CTRLCCRCA: ESTORNO DE SALDO DE ITEM PEDIDO', 1, 60),
         vrItem.nPVENDA,
         vrItem.nST,
         vrItem.nPBASERCA,
         vrItem.nSTPBASERCA,
         vrItem.nPTABELA,
         vrItem.nSTPTABELA,
         vrItem.nBONIFIC,
         vrItem.nQT,
         vrItem.vUSADEBCREDRCABRIND,
         vrItem.vMOVIMENTACONTACORRENTERCA,
         vrItem.nCODPROMOCAOMED,
         nPERCRATEIOCREDRCASUPERVISOR);

    END IF; -- FIM: LIMITE_FLEX

    --ELSE
    -- vbvalido := FALSE;
    --END IF;
    RETURN(vbvalido);
  END; --ccrca_estorna_item_pedido

  --RNG09
  FUNCTION ccrca_incluir_item_pedido(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                     p_rotinalanc  IN pclogrca.rotina%TYPE,
                                     p_codusur     IN pcpedc.codusur%TYPE,
                                     p_numped      IN pcpedc.numped%TYPE,
                                     p_codprod     IN pcpedi.codprod%TYPE,
                                     p_numseq      IN pcpedi.numseq%TYPE)
    RETURN BOOLEAN IS
    vnvalorlanc        NUMBER;
    vnvlcorrente_ant   pcusuari.vlcorrente%TYPE;
    vsusadebcredrca    pcusuari.usadebcredrca%TYPE;
    vnvllimcred        pcusuari.vllimcred%TYPE;
    vnvlcorrente_atual pcusuari.vlcorrente%TYPE;
    vddata             pcpedc.DATA%TYPE;
    vnnumtransvenda    pcpedc.numtransvenda%TYPE;
    vsposicao          pcpedc.posicao%TYPE;
    vnqt               pcpedi.qt%TYPE;
    vbvalido           BOOLEAN;
    -- Log
    TYPE TRecItem                   IS RECORD(
         nPVENDA                    PCLOGRCA.PVENDA%TYPE,
         nST                        PCLOGRCA.ST%TYPE,
         nPBASERCA                  PCLOGRCA.PBASERCA%TYPE,
         nSTPBASERCA                PCLOGRCA.STPBASERCA%TYPE,
         nPTABELA                   PCLOGRCA.PTABELA%TYPE,
         nSTPTABELA                 PCLOGRCA.STPTABELA%TYPE,
         nBONIFIC                   PCLOGRCA.BONIFIC%TYPE,
         nQT                        PCLOGRCA.QT%TYPE,
         vUSADEBCREDRCABRIND        PCLOGRCA.USADEBCREDRCABRIND%TYPE,
         vMOVIMENTACONTACORRENTERCA PCLOGRCA.MOVIMENTACONTACORRENTERCA%TYPE,
         nCODPROMOCAOMED            PCLOGRCA.CODPROMOCAOMED%TYPE,
         nVLUNITLIMCREDRCAUTILIZMED PCPEDI.VLUNITLIMCREDRCAUTILIZMED%TYPE); -- 4954.001502.2017
    vrItem                          TRecItem;
    -- HIS.00632.2016
    vncodusur                       pcpedc.codusur%type;
    -- Variáveis para Rateio Crédito C/C RCA
    nPERCRATEIOCREDRCASUPERVISOR    NUMBER;
    nPERCRATEIOCREDSUPERVEMPRESA    NUMBER;
    vncodsupervisor                 pcusuari.codsupervisor%type;
    vncod_cadrca_supervisor         PCSUPERV.COD_CADRCA%TYPE;
    vncod_cadrca_empresa            PCUSUARI.CODUSUR%TYPE;
    vnValorTransf                   NUMBER(15,2);
    vnValorTransfSupervisor         NUMBER(15,2);
    vnValorTransfEmpresa            NUMBER(15,2);
    -- LIMITE_FLEX
    vvtipomovccrca                  pcpedc.tipomovccrca%type;
    vnvllimcred_atual               pcusuari.vllimcred%type;
    vncondvenda                     pcpedc.condvenda%type;
    vnSaldoPedido                   NUMBER(20,2);
    vnVlLimCredRcaUtiliz            NUMBER(20,2);
    vnVlAbaterLimCredRca            NUMBER(20,2);
  BEGIN
    vbvalido := TRUE;

    -------------------------------------------------------------------------------------------------
    -- HIS.00065.2018 - Se usar o saldo C/C somente no próprio pedido, não acumula o Saldo C/C no RCA
    -------------------------------------------------------------------------------------------------
    IF (F_USARSALDORCASOMENTENOPEDIDO) THEN
      RETURN TRUE;
    END IF;

    -- Obter % Rateio de Crédito de C/C RCA
    nPERCRATEIOCREDRCASUPERVISOR := F_PERCRATEIOCREDRCASUPERVISOR;

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(p_codusur,
                                       p_numped);

    SELECT pcpedc.DATA, pcpedc.numtransvenda, pcpedc.posicao, pcpedc.tipomovccrca, pcpedc.condvenda
      INTO vddata, vnnumtransvenda, vsposicao, vvtipomovccrca, vncondvenda
      FROM pcpedc
     WHERE numped = p_numped;

    ---------------------------------------------------------------------------------
    -- HIS.00052.2017 - Força encerrar o processo se Débito e Crédito no Faturamento,
    -- movimentando o conta corrente do RCA por Pedido no Faturamento
    ---------------------------------------------------------------------------------
    IF (vvtipomovccrca = 'FF') AND
       (F_MOVSALDORCAPORPEDIDOFAT) THEN
      RETURN(TRUE);
    END IF;
    ---------------------------------------------------------------------------------

    SELECT qt
      INTO vnqt
      FROM pcpedi
     WHERE numped = p_numped
       AND codprod = p_codprod
       AND numseq = p_numseq;

    SELECT pcusuari.usadebcredrca, pcusuari.vlcorrente, pcusuari.vllimcred, pcusuari.codsupervisor
      INTO vsusadebcredrca, vnvlcorrente_ant, vnvllimcred, vncodsupervisor
      FROM pcusuari
     WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;

    BEGIN
      SELECT PVENDA
           , ST
           , PBASERCA
           , STPBASERCA
           , PTABELA
           , STPTABELA
           , BONIFIC
           , QT
           , USADEBCREDRCABRIND
           , MOVIMENTACONTACORRENTERCA
           , CODPROMOCAOMED
           , VLUNITLIMCREDRCAUTILIZMED -- 4954.001502.2017
        INTO vrItem.nPVENDA
           , vrItem.nST
           , vrItem.nPBASERCA
           , vrItem.nSTPBASERCA
           , vrItem.nPTABELA
           , vrItem.nSTPTABELA
           , vrItem.nBONIFIC
           , vrItem.nQT
           , vrItem.vUSADEBCREDRCABRIND
           , vrItem.vMOVIMENTACONTACORRENTERCA
           , vrItem.nCODPROMOCAOMED
           , vrItem.nVLUNITLIMCREDRCAUTILIZMED -- 4954.001502.2017
        FROM PCPEDI
       WHERE (NUMPED  = p_numped)
         AND (CODPROD = p_codprod)
         AND (NUMSEQ  = p_numseq);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vrItem.nPVENDA                    := NULL;
        vrItem.nST                        := NULL;
        vrItem.nPBASERCA                  := NULL;
        vrItem.nSTPBASERCA                := NULL;
        vrItem.nPTABELA                   := NULL;
        vrItem.nSTPTABELA                 := NULL;
        vrItem.nBONIFIC                   := 'N';
        vrItem.nQT                        := NULL;
        vrItem.vUSADEBCREDRCABRIND        := NULL;
        vrItem.vMOVIMENTACONTACORRENTERCA := NULL;
        vrItem.nCODPROMOCAOMED            := NULL;
        vrItem.nVLUNITLIMCREDRCAUTILIZMED := NULL; -- 4954.001502.2017
    END;

    -- LIMITE_FLEX
    IF (NVL(vvtipomovccrca,' ') = 'LL') THEN

      -- SE ESTORNO NA LIBERAÇÃO DO PEDIDO
      IF (NVL(p_rotinalanc,0) IN (336,2336)) THEN

        -- Valor Utilizado do Limite de Crédito - 4954.001502.2017
        vnvalorlanc := NVL(vrItem.nVLUNITLIMCREDRCAUTILIZMED,0) * NVL(vnqt,0);

      -- SE DIGITAÇÃO DO PEDIDO - 2316
      ELSE

        -- Calcula o Total de Saldo do Pedido, Valor Saldo do Item
        -- e o quanto já foi utilizado de Limite de Crédito do RCA no Pedido
        SELECT SUM(CASE WHEN (NVL(BONIFIC,'N') = 'F') OR
                             (vncondvenda =  5) THEN
                     (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                   ELSE
                     ((((PVENDA-NVL(ST,0)) - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                   END)
             , SUM(CASE WHEN ((CODPROD = p_codprod) AND (NUMSEQ = p_numseq)) THEN
                     CASE WHEN (NVL(BONIFIC,'N') = 'F') OR
                               (vncondvenda =  5) THEN
                       (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                     ELSE
                       ((((PVENDA-NVL(ST,0)) - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                     END
                   ELSE
                     0
                   END)
             , SUM(VLUNITLIMCREDRCAUTILIZMED * QT)
          INTO vnSaldoPedido
             , vnvalorlanc
             , vnVlLimCredRcaUtiliz
          FROM PCPEDI
         WHERE (NUMPED = p_numped);

        -- Se o Pedido ficou com Saldo Negativo e o Item tiver Saldo Negativo
        IF (NVL(vnSaldoPedido,0) < 0) AND
           (NVL(vnvalorlanc,0)   < 0) THEN
          -- Transforma os Valores de Débito em valores positivos para ficarem mais claras as operações
          vnvalorlanc          := ABS(vnvalorlanc);
          vnSaldoPedido        := ABS(vnSaldoPedido);
          -- O que precisa abater do Limite do RCA é o Valor de Débito do Pedido
          -- menos o quanto já foi abatido no Limite do RCA nos itens anteriores
          vnVlAbaterLimCredRca := (NVL(vnSaldoPedido,0) - NVL(vnVlLimCredRcaUtiliz,0));
          -- Se ainda existem Débitos do Pedido para Abater do Limite do RCA
          IF (NVL(vnVlAbaterLimCredRca,0) > 0) THEN
            -- Limita o valor do item ao saldo restante a abater do Limite do RCA
            IF (NVL(vnvalorlanc,0) > NVL(vnVlAbaterLimCredRca,0)) THEN
              vnvalorlanc := NVL(vnVlAbaterLimCredRca,0);
            END IF;
          ELSE
            vnvalorlanc := 0;
          END IF;
        ELSE
          vnvalorlanc := 0;
        END IF;

      END IF; -- Fim Condição LIBERAÇÃO/DIGITAÇÃO do Pedido

      -- Se tem valor a Abater do Limite do RCA
      IF (vnvalorlanc > 0) THEN

        -- (I - Inclusao)
        vnvllimcred_atual := NVL(vnvllimcred, 0) - NVL(vnvalorlanc, 0);

        UPDATE pcusuari
           SET vllimcred = vnvllimcred_atual
         WHERE codusur = vncodusur;

        -- SE NÃO FOR ESTORNO NA LIBERAÇÃO DO PEDIDO
        IF (NVL(p_rotinalanc,0) NOT IN (336,2336)) THEN
          -- Grava Valor Unitário Utilizado do Limite de Crédito
          UPDATE PCPEDI
             SET VLUNITLIMCREDRCAUTILIZMED = DECODE(NVL(vrItem.nQT,0),0,0,vnvalorlanc / vrItem.nQT)
           WHERE numped = p_numped
             AND codprod = p_codprod
             AND numseq = p_numseq;
        END IF;

        INSERT INTO pcloglimitecredrcamed
          (numped,
           posicao,
           numtransvenda,
           DATA,
           codfunc,
           codusur,
           rotina,
           vlcorrente,
           vllimcred,
           vlcorrenteant,
           vllimcredant,
           codprod,
           numseq,
           historico,
           PVENDA,
           ST,
           PBASERCA,
           STPBASERCA,
           PTABELA,
           STPTABELA,
           BONIFIC,
           QT,
           USADEBCREDRCABRIND,
           MOVIMENTACONTACORRENTERCA,
           CODPROMOCAOMED,
           PERCRATEIOCREDRCASUPERVISOR,
           QTLIMCREDRCAUTILIZ,
           VLLIMCREDRCAUTILIZ)
        VALUES
          (p_numped,
           vsposicao,
           vnnumtransvenda,
           SYSDATE,
           p_codfunclanc,
           vncodusur,
           p_rotinalanc,
           vnvlcorrente_ant,
           vnvllimcred_atual,
           vnvlcorrente_ant,
           vnvllimcred,
           p_codprod,
           p_numseq,
           SUBSTR('CTRLCCRCA:LANCAMENTO SALDO ITEM PEDIDO', 1, 60),
           vrItem.nPVENDA,
           vrItem.nST,
           vrItem.nPBASERCA,
           vrItem.nSTPBASERCA,
           vrItem.nPTABELA,
           vrItem.nSTPTABELA,
           vrItem.nBONIFIC,
           vrItem.nQT,
           vrItem.vUSADEBCREDRCABRIND,
           vrItem.vMOVIMENTACONTACORRENTERCA,
           vrItem.nCODPROMOCAOMED,
           nPERCRATEIOCREDRCASUPERVISOR,
           vrItem.nQT,
           vnvalorlanc);

      END IF; -- Fim: Se precisou usar Limite

    ELSE

      vnvalorlanc := ccrca_retorna_saldo_itempedido(p_numped,
                                                    vncodusur, -- HIS.00632.2016 -- p_codusur,
                                                    p_codprod,
                                                    p_numseq,
                                                    vnqt,
                                                    'I',
                                                    p_rotinalanc,
                                                    nPERCRATEIOCREDRCASUPERVISOR);

      --incluído por Sabrina (I - Inclusao)
      vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) + NVL(vnvalorlanc, 0);

      -- a package não deve barrar a movimentacao do saldo, os programas eh que fazem isso
      -- IF vnvlcorrente_atual >= 0 THEN
      UPDATE pcusuari
         SET vlcorrente = vnvlcorrente_atual
       WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;

      INSERT INTO pclogrca
        (numped,
         posicao,
         numtransvenda,
         DATA,
         codfunc,
         codusur,
         rotina,
         vlcorrente,
         vllimcred,
         vlcorrenteant,
         vllimcredant,
         codprod,
         numseq,
         historico,
         PVENDA,
         ST,
         PBASERCA,
         STPBASERCA,
         PTABELA,
         STPTABELA,
         BONIFIC,
         QT,
         USADEBCREDRCABRIND,
         MOVIMENTACONTACORRENTERCA,
         CODPROMOCAOMED,
         PERCRATEIOCREDRCASUPERVISOR)
      VALUES
        (p_numped,
         vsposicao,
         vnnumtransvenda,
         SYSDATE,
         p_codfunclanc,
         vncodusur, -- HIS.00632.2016 -- p_codusur,
         p_rotinalanc,
         vnvlcorrente_atual,
         vnvllimcred,
         vnvlcorrente_ant,
         vnvllimcred,
         p_codprod,
         p_numseq,
         SUBSTR('CTRLCCRCA:LANCAMENTO SALDO ITEM PEDIDO', 1, 60),
         vrItem.nPVENDA,
         vrItem.nST,
         vrItem.nPBASERCA,
         vrItem.nSTPBASERCA,
         vrItem.nPTABELA,
         vrItem.nSTPTABELA,
         vrItem.nBONIFIC,
         vrItem.nQT,
         vrItem.vUSADEBCREDRCABRIND,
         vrItem.vMOVIMENTACONTACORRENTERCA,
         vrItem.nCODPROMOCAOMED,
         nPERCRATEIOCREDRCASUPERVISOR);

      -------------------------------------------
      -- Se houver Rateio de Crédito de C/C RCA
      -- E estiver chamando da Inclusão do Pedido
      -------------------------------------------
      IF (F_USARATEIOCREDRCASUPERVISOR(vncodusur,
                                       NVL(nPERCRATEIOCREDRCASUPERVISOR,0),
                                       NVL(vnvalorlanc,0))) AND
         (p_rotinalanc IN (2316,8888,2513)) THEN

        -- Pesquisa os RCA vinculado ao Supervisor
        BEGIN
          SELECT PCUSUARI.CODUSUR
            INTO vncod_cadrca_supervisor
            FROM PCSUPERV
               , PCUSUARI
           WHERE (PCSUPERV.CODSUPERVISOR = vncodsupervisor)
             AND (PCUSUARI.CODUSUR       = PCSUPERV.COD_CADRCA);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vncod_cadrca_supervisor := NULL;
        END;

        -- Pesquisa o RCA vinculado a Empresa
        vncod_cadrca_empresa := F_OBTER_RCA_EMPRESA;

        -- Se o Supervisor movimenta C/C
        IF (NVL(vncod_cadrca_supervisor,0) > 0) THEN

          -- Valor da Transferência - Diferença do % que ficará com o RCA
          vnValorTransf := ROUND(NVL(vnvalorlanc,0) * (1 - (NVL(nPERCRATEIOCREDRCASUPERVISOR,0) / 100)),2);

          -- DEBITANDO RCA --------------------------------------------------------------------------
          IF (NVL(vnValorTransf,0) > 0) THEN

            SELECT pcusuari.usadebcredrca, pcusuari.vlcorrente, pcusuari.vllimcred
              INTO vsusadebcredrca, vnvlcorrente_ant, vnvllimcred
              FROM pcusuari
             WHERE codusur = vncodusur; -- RCA

            vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) - NVL(vnValorTransf, 0); -- DEDUZINDO VALOR TRANSF.

            UPDATE pcusuari
               SET vlcorrente = vnvlcorrente_atual
             WHERE codusur = vncodusur; -- RCA

            INSERT INTO pclogrca
              (numped,
               posicao,
               numtransvenda,
               DATA,
               codfunc,
               codusur,
               rotina,
               vlcorrente,
               vllimcred,
               vlcorrenteant,
               vllimcredant,
               codprod,
               numseq,
               historico,
               PVENDA,
               ST,
               PBASERCA,
               STPBASERCA,
               PTABELA,
               STPTABELA,
               BONIFIC,
               QT,
               USADEBCREDRCABRIND,
               MOVIMENTACONTACORRENTERCA,
               CODPROMOCAOMED,
               PERCRATEIOCREDRCASUPERVISOR)
            VALUES
              (p_numped,
               vsposicao,
               vnnumtransvenda,
               SYSDATE,
               p_codfunclanc,
               vncodusur, -- RCA
               p_rotinalanc,
               vnvlcorrente_atual,
               vnvllimcred,
               vnvlcorrente_ant,
               vnvllimcred,
               p_codprod,
               p_numseq,
               SUBSTR('CTRLCCRCA:LANCAMENTO RATEIO RCA ITEM PEDIDO', 1, 60),
               vrItem.nPVENDA,
               vrItem.nST,
               vrItem.nPBASERCA,
               vrItem.nSTPBASERCA,
               vrItem.nPTABELA,
               vrItem.nSTPTABELA,
               vrItem.nBONIFIC,
               vrItem.nQT,
               vrItem.vUSADEBCREDRCABRIND,
               vrItem.vMOVIMENTACONTACORRENTERCA,
               vrItem.nCODPROMOCAOMED,
               nPERCRATEIOCREDRCASUPERVISOR);

            -- RATEIO ENTRE SUPERVISOR E EMPRESA ------------------------------------------------------
           /*********************************************
            PASSOU PARA O FATURAMENTO POR CAUSA DOS LOCKS
            *********************************************

            -- Obter % Rateio de Crédito de C/C Supervisor e Empresa
            nPERCRATEIOCREDSUPERVEMPRESA := F_PERCRATEIOCREDSUPERVEMPRESA;

            ------------------------------------------------------------
            -- Se houver Rateio de Crédito de C/C Supervisor com Empresa
            ------------------------------------------------------------
            IF (F_USARATEIOCREDSUPERVEMPRESA(vncod_cadrca_empresa,
                                             nPERCRATEIOCREDSUPERVEMPRESA,
                                             vnValorTransf)) THEN
              -- Calcula a parte do Supervisor
              vnValorTransfSupervisor := ROUND(vnValorTransf * (NVL(nPERCRATEIOCREDSUPERVEMPRESA,0) / 100),2);
              -- Calcula a parte da Empresa
              vnValorTransfEmpresa    := (NVL(vnValorTransf,0) - NVL(vnValorTransfSupervisor,0));
            ELSE
              -- Somente tem a parte do Supervisor
              vnValorTransfSupervisor := vnValorTransf;
              -- Não tem a parte da Empresa
              vnValorTransfEmpresa    := 0;
            END IF;

            -- CREDITANDO SUPERVISOR ------------------------------------------------------------------
            IF (NVL(vnValorTransfSupervisor,0) > 0) THEN

              SELECT pcusuari.usadebcredrca, pcusuari.vlcorrente, pcusuari.vllimcred
                INTO vsusadebcredrca, vnvlcorrente_ant, vnvllimcred
                FROM pcusuari
               WHERE codusur = vncod_cadrca_supervisor; -- SUPERVISOR

              vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) + NVL(vnValorTransfSupervisor, 0); -- INCREMENTANDO VALOR TRANSF.

              UPDATE pcusuari
                 SET vlcorrente = vnvlcorrente_atual
               WHERE codusur = vncod_cadrca_supervisor; -- SUPERVISOR

              INSERT INTO pclogrca
                (numped,
                 posicao,
                 numtransvenda,
                 DATA,
                 codfunc,
                 codusur,
                 rotina,
                 vlcorrente,
                 vllimcred,
                 vlcorrenteant,
                 vllimcredant,
                 codprod,
                 numseq,
                 historico,
                 PVENDA,
                 ST,
                 PBASERCA,
                 STPBASERCA,
                 PTABELA,
                 STPTABELA,
                 BONIFIC,
                 QT,
                 USADEBCREDRCABRIND,
                 MOVIMENTACONTACORRENTERCA,
                 CODPROMOCAOMED,
                 PERCRATEIOCREDRCASUPERVISOR)
              VALUES
                (p_numped,
                 vsposicao,
                 vnnumtransvenda,
                 SYSDATE,
                 p_codfunclanc,
                 vncod_cadrca_supervisor, -- SUPERVISOR
                 p_rotinalanc,
                 vnvlcorrente_atual,
                 vnvllimcred,
                 vnvlcorrente_ant,
                 vnvllimcred,
                 p_codprod,
                 p_numseq,
                 SUBSTR('CTRLCCRCA:LANCAMENTO RATEIO SUPERVISOR ITEM PEDIDO', 1, 60),
                 vrItem.nPVENDA,
                 vrItem.nST,
                 vrItem.nPBASERCA,
                 vrItem.nSTPBASERCA,
                 vrItem.nPTABELA,
                 vrItem.nSTPTABELA,
                 vrItem.nBONIFIC,
                 vrItem.nQT,
                 vrItem.vUSADEBCREDRCABRIND,
                 vrItem.vMOVIMENTACONTACORRENTERCA,
                 vrItem.nCODPROMOCAOMED,
                 nPERCRATEIOCREDRCASUPERVISOR);

            END IF; -- Fim Condição CREDITANDO SUPERVISOR

            -- CREDITANDO EMPRESA ---------------------------------------------------------------------
            IF (NVL(vncod_cadrca_empresa,0) > 0) AND
               (NVL(vnValorTransfEmpresa,0) > 0) THEN

              SELECT pcusuari.usadebcredrca, pcusuari.vlcorrente, pcusuari.vllimcred
                INTO vsusadebcredrca, vnvlcorrente_ant, vnvllimcred
                FROM pcusuari
               WHERE codusur = vncod_cadrca_empresa; -- EMPRESA

              vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) + NVL(vnValorTransfEmpresa, 0); -- INCREMENTANDO VALOR TRANSF.

              UPDATE pcusuari
                 SET vlcorrente = vnvlcorrente_atual
               WHERE codusur = vncod_cadrca_empresa; -- EMPRESA

              INSERT INTO pclogrca
                (numped,
                 posicao,
                 numtransvenda,
                 DATA,
                 codfunc,
                 codusur,
                 rotina,
                 vlcorrente,
                 vllimcred,
                 vlcorrenteant,
                 vllimcredant,
                 codprod,
                 numseq,
                 historico,
                 PVENDA,
                 ST,
                 PBASERCA,
                 STPBASERCA,
                 PTABELA,
                 STPTABELA,
                 BONIFIC,
                 QT,
                 USADEBCREDRCABRIND,
                 MOVIMENTACONTACORRENTERCA,
                 CODPROMOCAOMED,
                 PERCRATEIOCREDRCASUPERVISOR)
              VALUES
                (p_numped,
                 vsposicao,
                 vnnumtransvenda,
                 SYSDATE,
                 p_codfunclanc,
                 vncod_cadrca_empresa, -- EMPRESA
                 p_rotinalanc,
                 vnvlcorrente_atual,
                 vnvllimcred,
                 vnvlcorrente_ant,
                 vnvllimcred,
                 p_codprod,
                 p_numseq,
                 SUBSTR('CTRLCCRCA:LANCAMENTO RATEIO EMPRESA ITEM PEDIDO', 1, 60),
                 vrItem.nPVENDA,
                 vrItem.nST,
                 vrItem.nPBASERCA,
                 vrItem.nSTPBASERCA,
                 vrItem.nPTABELA,
                 vrItem.nSTPTABELA,
                 vrItem.nBONIFIC,
                 vrItem.nQT,
                 vrItem.vUSADEBCREDRCABRIND,
                 vrItem.vMOVIMENTACONTACORRENTERCA,
                 vrItem.nCODPROMOCAOMED,
                 nPERCRATEIOCREDSUPERVEMPRESA);

            END IF; -- Fim Condição CREDITANDO EMPRESA
            *************************/

          END IF; -- Fim Condição DEBITANDO RCA

        END IF; -- Fim Condição Se o Supervisor movimenta C/C

      END IF; -- Fim Condição Rateio Saldo C/C

    END IF; -- FIM: LIMITE_FLEX

    --ELSE
    --vbvalido := FALSE;
    --END IF;
    RETURN(vbvalido);

  END; -- ccrca_incluir_item_pedido

  --Projeto 90992 RBD4
  -- inclui itens ou todo pedido
  FUNCTION ccfinrca_incluir_item_pedido(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                        p_rotinalanc  IN pclogrca.rotina%TYPE,
                                        p_codusur     IN pcpedc.codusur%TYPE,
                                        p_numped      IN pcpedc.numped%TYPE,
                                        p_codprod     IN pcpedi.codprod%TYPE,
                                        p_numseq      IN pcpedi.numseq%TYPE,
                                        p_mensagem    OUT VARCHAR2)
    RETURN BOOLEAN IS
    vsusasaldocontacorrentedescfin pcpedc.usasaldocontacorrentedescfin%TYPE;
    vsatualizasaldoccdescfin       pcclient.atualizasaldoccdescfin%TYPE;
    vscodfilial                    pcpedc.codfilial%TYPE;
    vnperdescfin                   pcpedc.perdescfin%TYPE;
    vncondvenda                    pcpedc.condvenda%TYPE;
    vncodusur                      pcpedc.codusur%TYPE;
    vstipomovccrca                 pcpedc.tipomovccrca%TYPE;
    vsgravarvalordescfin           VARCHAR2(1);
    vnvlsaldo                      NUMBER;
    vnvltotalitens                 NUMBER;
    vnvalordescfin                 NUMBER;
    vbvalido                       BOOLEAN;
    vsmensagem                     VARCHAR2(300);
    vicontador                     NUMBER;
  BEGIN
    vsmensagem := 'OK';
    proc_lerparametros(vsmensagem);

    SELECT p.usasaldocontacorrentedescfin,
           pcclient.atualizasaldoccdescfin,
           p.codfilial,
           p.perdescfin,
           p.condvenda,
           p.codusur,
           p.tipomovccrca,
           NVL((SELECT NVL(valor, 'N')
                 FROM pcparamfilial
                WHERE pcparamfilial.codfilial = p.codfilial
                  AND pcparamfilial.nome = 'GRAVARVALORDESCFIN'),
               'N')
      INTO vsusasaldocontacorrentedescfin,
           vsatualizasaldoccdescfin,
           vscodfilial,
           vnperdescfin,
           vncondvenda,
           vncodusur,
           vstipomovccrca,
           vsgravarvalordescfin
      FROM pcpedc p, pcclient
     WHERE p.numped = p_numped
       AND p.codcli = pcclient.codcli;

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(vncodusur, -- RCA que já estava buscando no Pedido
                                       p_numped);

    -- Tarefa 102070 (Caso o valor do Desc. seja fixo por valor não será alterado com o novo item inserido)
    IF (vsgravarvalordescfin = 'S') AND (p_codprod IS NOT NULL) AND
       (p_numseq IS NOT NULL) THEN
      vnperdescfin := 0;
    END IF;
    -- Fim tarefa 102070

    -- Tarefa 99976
    IF (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       (NVL(vsusasaldocontacorrentedescfin, 'N') = 'S') THEN
      vbvalido := TRUE;
    END IF;
    -- Fim tarefa 99976

    IF gregpcconsum.usasaldocontacorrentedescfin = 'S' AND
       NVL(vsatualizasaldoccdescfin, 'N') = 'N' THEN
      vnvlsaldo := ccfinrca_saldorcamenosdescfin(vncodusur, -- HIS.00632.2016 -- p_codusur,
                                                 vscodfilial);

      SELECT (SUM(pcpedi.pvenda * pcpedi.qt))
        INTO vnvltotalitens
        FROM pcpedi
       WHERE pcpedi.numped = p_numped
         AND pcpedi.qt > 0
         AND codprod = NVL(p_codprod, codprod)
         AND numseq = NVL(p_numseq, numseq);

      vnvalordescfin := (NVL(vnvltotalitens, 0)) *
                        (NVL(vnperdescfin, 0) / 100);

      IF NVL(vnvlsaldo, 0) < NVL(vnvalordescfin, 0) THEN
        vbvalido   := FALSE;
        vsmensagem := 'RCA sem saldo para liberar pedido com desconto financeiro';
      ELSE
        IF NOT (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
           ((NVL(vsusasaldocontacorrentedescfin, 'N')) = 'S') AND
           (NVL(vstipomovccrca, 'VV') NOT IN ('FF', 'VV')) THEN
          --RBD11
          SELECT COUNT(*)
            INTO vicontador
            FROM pcsaldorca
           WHERE codusur = vncodusur;

          IF vicontador = 0 THEN
            INSERT INTO pcsaldorca
              (codusur, vlsaldo, vlsaldoant)
            VALUES
              (vncodusur, 0, 0);
          END IF;

          IF NVL(vnperdescfin, 0) > 0 THEN
            SELECT NVL(vlsaldo, 0)
              INTO vnvlsaldo
              FROM pcsaldorca
             WHERE codusur = vncodusur
               FOR UPDATE;

            IF (vnvalordescfin) > 0 THEN
              vnvalordescfin := vnvalordescfin * (-1);
            END IF;

            INSERT INTO pcmovsaldorca
              (DATA,
               codfunc,
               codusur,
               rotina,
               tipo,
               valor,
               vlsaldoant,
               vlsaldo,
               historico,
               numped)
            VALUES
              (SYSDATE,
               p_codfunclanc,
               vncodusur,
               p_rotinalanc,
               'D',
               vnvalordescfin,
               vnvlsaldo,
               (vnvlsaldo + (vnvalordescfin)),
               'PEDIDO DE VENDA',
               p_numped);

            UPDATE pcsaldorca
               SET vlsaldoant = vnvlsaldo,
                   vlsaldo    = (vnvlsaldo + (vnvalordescfin))
             WHERE codusur = vncodusur;

            vbvalido := TRUE;
          ELSE
            vbvalido := TRUE;
          END IF;
        END IF;
      END IF;
    ELSE
      vbvalido := TRUE;
    END IF;

    p_mensagem := vsmensagem;
    RETURN(vbvalido);
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao incluir item pedido : ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END; --ccfinrca_incluir_item_pedido

  --Projeto 90992 RBD7
  --Cancela itens ou todo o pedido
  FUNCTION ccfinrca_excluir_item_pedido(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                        p_rotinalanc  IN pclogrca.rotina%TYPE,
                                        p_codusur     IN pcpedc.codusur%TYPE,
                                        p_numped      IN pcpedc.numped%TYPE,
                                        p_codprod     IN pcpedi.codprod%TYPE,
                                        p_numseq      IN pcpedi.numseq%TYPE,
                                        p_qtnova      IN pcpedi.qt%TYPE,
                                        --caso seja alteração de preço, enviar qt novo
                                        p_preconovo IN pcpedi.pvenda%TYPE,
                                        --caso seja alteração de quantidade, enviar pvenda novo
                                        p_mensagem OUT VARCHAR2)
    RETURN BOOLEAN IS
    vnperdescfin                   pcpedc.perdescfin%TYPE;
    vnqtanterior                   pcpedi.qt%TYPE;
    vnpvendaanterior               pcpedi.pvenda%TYPE;
    vncondvenda                    pcpedc.condvenda%TYPE;
    vsusasaldocontacorrentedescfin pcpedc.usasaldocontacorrentedescfin%TYPE;
    vstipomovccrca                 pcpedc.tipomovccrca%TYPE;
    vncodusur                      pcpedc.codusur%TYPE;
    vsgravarvalordescfin           VARCHAR2(1);
    vicontador                     NUMBER;
    vnvlsaldo                      NUMBER;
    vnvltotalitens                 NUMBER;
    vnvalorcredito                 NUMBER;
    vbvalido                       BOOLEAN;
    vsmensagem                     VARCHAR2(300);
  BEGIN
    vbvalido   := FALSE;
    vsmensagem := 'OK';

    SELECT pcpedc.perdescfin,
           pcpedc.condvenda,
           pcpedc.usasaldocontacorrentedescfin,
           pcpedc.tipomovccrca,
           pcpedc.codusur,
           NVL((SELECT NVL(valor, 'N')
                 FROM pcparamfilial
                WHERE pcparamfilial.codfilial = pcpedc.codfilial
                  AND pcparamfilial.nome = 'GRAVARVALORDESCFIN'),
               'N')
      INTO vnperdescfin,
           vncondvenda,
           vsusasaldocontacorrentedescfin,
           vstipomovccrca,
           vncodusur,
           vsgravarvalordescfin
      FROM pcpedc
     WHERE pcpedc.numped = p_numped;

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(vncodusur, -- RCA que já estava buscando no Pedido
                                       p_numped);

    -- Tarefa 102070 (Caso o valor do Desc. seja fixo por valor, não será alterado com o novo item excluído)
    IF (vsgravarvalordescfin = 'S') AND (p_codprod IS NOT NULL) -- Tarefa 105173
     THEN
      vnperdescfin := 0;
    END IF;
    -- Fim tarefa 102070

    -- Tarefa 99976
    IF (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       (NVL(vsusasaldocontacorrentedescfin, 'N') = 'S') THEN
      vbvalido := TRUE;
    END IF;
    -- Fim tarefa 99976

    IF NOT (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       ((NVL(vsusasaldocontacorrentedescfin, 'N')) = 'S') AND
       (NVL(vstipomovccrca, 'VV') NOT IN ('FF', 'VV')) THEN
      SELECT COUNT(*)
        INTO vicontador
        FROM pcsaldorca
       WHERE codusur = vncodusur;

      IF vicontador = 0 THEN
        INSERT INTO pcsaldorca
          (codusur, vlsaldo, vlsaldoant)
        VALUES
          (vncodusur, 0, 0);
      END IF;

      IF NVL(vnperdescfin, 0) > 0 THEN
        SELECT NVL(vlsaldo, 0)
          INTO vnvlsaldo
          FROM pcsaldorca
         WHERE codusur = vncodusur
           FOR UPDATE;

        --cancelamento de todo o pedido
        IF p_codprod IS NULL THEN
          SELECT SUM(pcpedi.pvenda * pcpedi.qt)
            INTO vnvltotalitens
            FROM pcpedi
           WHERE pcpedi.numped = p_numped
             AND pcpedi.qt > 0;
        ELSE
          SELECT pcpedi.qt, pcpedi.pvenda
            INTO vnqtanterior, vnpvendaanterior
            FROM pcpedi
           WHERE pcpedi.numped = p_numped
             AND pcpedi.codprod = p_codprod
             AND pcpedi.numseq = NVL(p_numseq, pcpedi.numseq);

          -- cancelamento ou alteração de item
          IF vnqtanterior <> p_qtnova THEN
            SELECT (pcpedi.pvenda * (vnqtanterior - p_qtnova))
              INTO vnvltotalitens
              FROM pcpedi
             WHERE pcpedi.numped = p_numped
               AND pcpedi.codprod = p_codprod
               AND pcpedi.numseq = p_numseq
               AND pcpedi.qt > 0;
          END IF;

          IF vnpvendaanterior <> p_preconovo THEN
            SELECT (pcpedi.qt * (vnpvendaanterior - p_preconovo))
              INTO vnvltotalitens
              FROM pcpedi
             WHERE pcpedi.numped = p_numped
               AND pcpedi.codprod = p_codprod
               AND pcpedi.numseq = p_numseq
               AND pcpedi.qt > 0;
          END IF;
        END IF;

        vnvalorcredito := (vnvltotalitens) * (vnperdescfin / 100);

        INSERT INTO pcmovsaldorca
          (DATA,
           codfunc,
           codusur,
           rotina,
           tipo,
           valor,
           vlsaldoant,
           vlsaldo,
           historico,
           numped)
        VALUES
          (SYSDATE,
           p_codfunclanc,
           vncodusur,
           p_rotinalanc,
           'C',
           vnvalorcredito,
           vnvlsaldo,
           (vnvlsaldo + vnvalorcredito),
           'PEDIDO DE VENDA',
           p_numped);

        UPDATE pcsaldorca
           SET vlsaldoant = vnvlsaldo,
               vlsaldo    = (vnvlsaldo + vnvalorcredito)
         WHERE codusur = vncodusur;

        vbvalido := TRUE;
      END IF;
    END IF;

    p_mensagem := vsmensagem;
    RETURN(vbvalido);
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao excluir item pedido : ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END; --ccfinrca_excluir_item_pedido

  --Projeto 90992 RBD4
  FUNCTION ccfinrca_alterar_preco_qt(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                     p_rotinalanc  IN pclogrca.rotina%TYPE,
                                     p_codusur     IN pcpedc.codusur%TYPE,
                                     p_numped      IN pcpedc.numped%TYPE,
                                     p_codprod     IN pcpedi.codprod%TYPE,
                                     p_numseq      IN pcpedi.numseq%TYPE,
                                     p_qtnova      IN pcpedi.qt%TYPE,
                                     --caso seja alteração de preço, enviar qt atual
                                     p_pvendanovo IN pcpedi.pvenda%TYPE,
                                     --caso seja alteração de quantidade, enviar o pvenda atual
                                     p_mensagem OUT VARCHAR2) RETURN BOOLEAN IS
    vnqtatual                      pcpedi.qt%TYPE;
    vnpvendaatual                  pcpedi.pvenda%TYPE;
    vscodfilial                    pcpedc.codfilial%TYPE;
    vncodusur                      pcpedc.codusur%TYPE;
    vnperdescfin                   pcpedc.perdescfin%TYPE;
    vsgravarvalordescfin           VARCHAR2(1);
    vnvlsaldorca                   NUMBER;
    vnvltotalitens                 NUMBER;
    vnvalordescfin                 NUMBER;
    vbvalido                       BOOLEAN;
    vsmensagem                     VARCHAR2(300);
    vncondvenda                    pcpedc.condvenda%TYPE;
    vsusasaldocontacorrentedescfin pcpedc.usasaldocontacorrentedescfin%TYPE;
    vstipomovccrca                 pcpedc.tipomovccrca%TYPE;
    vicontador                     NUMBER;
    vnvlsaldo                      NUMBER;
  BEGIN
    vbvalido   := FALSE;
    vsmensagem := 'OK';


    SELECT pcpedi.qt,
           pcpedc.codfilial,
           pcpedc.codusur,
           pcpedc.condvenda,
           pcpedc.usasaldocontacorrentedescfin,
           pcpedc.tipomovccrca,
           pcpedc.perdescfin,
           pcpedi.pvenda,
           NVL((SELECT NVL(valor, 'N')
                 FROM pcparamfilial
                WHERE pcparamfilial.codfilial = pcpedc.codfilial
                  AND pcparamfilial.nome = 'GRAVARVALORDESCFIN'),
               'N')
      INTO vnqtatual,
           vscodfilial,
           vncodusur,
           vncondvenda,
           vsusasaldocontacorrentedescfin,
           vstipomovccrca,
           vnperdescfin,
           vnpvendaatual,
           vsgravarvalordescfin
      FROM pcpedi, pcpedc
     WHERE pcpedc.numped = p_numped
       AND pcpedc.numped = pcpedi.numped
       AND codprod = p_codprod
       AND numseq = p_numseq;

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(vncodusur, -- RCA que já estava buscando no Pedido
                                       p_numped);

    -- Tarefa 102070 (Caso o valor do Desc. seja fixo por valor não será alterado com o novo item inserido)
    IF vsgravarvalordescfin = 'S' THEN
      vnperdescfin := 0;
    END IF;
    -- Fim tarefa 102070

    -- Tarefa 99976
    IF (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       (NVL(vsusasaldocontacorrentedescfin, 'N') = 'S') THEN
      vbvalido := TRUE;
    END IF;
    -- Fim tarefa 99976

    IF NOT (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       ((NVL(vsusasaldocontacorrentedescfin, 'N')) = 'S') AND
       (NVL(vstipomovccrca, 'VV') NOT IN ('FF', 'VV')) THEN
      IF (p_qtnova > 0) AND (p_qtnova <> vnqtatual) THEN
        IF p_qtnova > vnqtatual THEN
          vnvlsaldorca := ccfinrca_saldorcamenosdescfin(vncodusur,
                                                        vscodfilial);

          SELECT (pcpedi.pvenda * (p_qtnova - pcpedi.qt))
            INTO vnvltotalitens
            FROM pcpedi
           WHERE pcpedi.numped = p_numped
             AND pcpedi.codprod = p_codprod
             AND pcpedi.numseq = p_numseq
             AND pcpedi.qt > 0;

          vnvalordescfin := (vnvltotalitens) * (vnperdescfin / 100);

          IF (vnvlsaldorca < vnvalordescfin) THEN
            vbvalido   := FALSE;
            vsmensagem := 'RCA sem saldo para alterar qt do item';
          ELSE
            --RBD11
            SELECT COUNT(*)
              INTO vicontador
              FROM pcsaldorca
             WHERE codusur = vncodusur;

            IF vicontador = 0 THEN
              INSERT INTO pcsaldorca
                (codusur, vlsaldo, vlsaldoant)
              VALUES
                (vncodusur, 0, 0);
            END IF;

            IF NVL(vnperdescfin, 0) > 0 THEN
              SELECT NVL(vlsaldo, 0)
                INTO vnvlsaldo
                FROM pcsaldorca
               WHERE codusur = vncodusur
                 FOR UPDATE;

              IF (vnvalordescfin) > 0 THEN
                vnvalordescfin := vnvalordescfin * (-1);
              END IF;

              INSERT INTO pcmovsaldorca
                (DATA,
                 codfunc,
                 codusur,
                 rotina,
                 tipo,
                 valor,
                 vlsaldoant,
                 vlsaldo,
                 historico,
                 numped)
              VALUES
                (SYSDATE,
                 p_codfunclanc,
                 vncodusur,
                 p_rotinalanc,
                 'D',
                 vnvalordescfin,
                 vnvlsaldo,
                 (vnvlsaldo + (vnvalordescfin)),
                 'PEDIDO DE VENDA',
                 p_numped);

              UPDATE pcsaldorca
                 SET vlsaldoant = vnvlsaldo,
                     vlsaldo    = (vnvlsaldo + (vnvalordescfin))
               WHERE codusur = vncodusur;

              vbvalido := TRUE;
            END IF;
          END IF;
        ELSE
          --p_qtnova < vnqtautal
          --Creditar na CC do RCA o desconto financeiro proporcional a quantidade retirada do pedido, ou seja creditar apenas a diferença entre a quantidade anterior e a nova quantidade: o processo de crédito é semelhante ao processo descrito na [RBD7] Cancelar Item do Pedido de Venda e o Saldo de Conta Corrente do RCA.
          vbvalido := ccfinrca_excluir_item_pedido(p_codfunclanc,
                                                   p_rotinalanc,
                                                   vncodusur,
                                                   p_numped,
                                                   p_codprod,
                                                   p_numseq,
                                                   p_qtnova,
                                                   p_pvendanovo,
                                                   vsmensagem);
        END IF;
      END IF;

      --verifica alteração de preço
      IF (p_pvendanovo > 0) AND (p_pvendanovo <> vnpvendaatual) THEN
        IF (p_pvendanovo > vnpvendaatual) THEN
          vnvlsaldorca := ccfinrca_saldorcamenosdescfin(vncodusur,
                                                        vscodfilial);

          SELECT ((p_pvendanovo - pcpedi.pvenda) * pcpedi.qt)
            INTO vnvltotalitens
            FROM pcpedi
           WHERE pcpedi.numped = p_numped
             AND pcpedi.codprod = p_codprod
             AND pcpedi.numseq = p_numseq
             AND pcpedi.qt > 0;

          vnvalordescfin := (vnvltotalitens) * (vnperdescfin / 100);

          IF vnvlsaldorca < vnvalordescfin THEN
            vbvalido   := FALSE;
            vsmensagem := 'RCA sem saldo para alterar qt do item';
          ELSE
            --RBD11
            SELECT COUNT(*)
              INTO vicontador
              FROM pcsaldorca
             WHERE codusur = vncodusur;

            IF vicontador = 0 THEN
              INSERT INTO pcsaldorca
                (codusur, vlsaldo, vlsaldoant)
              VALUES
                (vncodusur, 0, 0);
            END IF;

            IF NVL(vnperdescfin, 0) > 0 THEN
              SELECT NVL(vlsaldo, 0)
                INTO vnvlsaldo
                FROM pcsaldorca
               WHERE codusur = vncodusur
                 FOR UPDATE;

              IF (vnvalordescfin) > 0 THEN
                vnvalordescfin := vnvalordescfin * (-1);
              END IF;

              INSERT INTO pcmovsaldorca
                (DATA,
                 codfunc,
                 codusur,
                 rotina,
                 tipo,
                 valor,
                 vlsaldoant,
                 vlsaldo,
                 historico,
                 numped)
              VALUES
                (SYSDATE,
                 p_codfunclanc,
                 vncodusur,
                 p_rotinalanc,
                 'D',
                 vnvalordescfin,
                 vnvlsaldo,
                 (vnvlsaldo + (vnvalordescfin)),
                 'PEDIDO DE VENDA',
                 p_numped);

              UPDATE pcsaldorca
                 SET vlsaldoant = vnvlsaldo,
                     vlsaldo    = (vnvlsaldo + (vnvalordescfin))
               WHERE codusur = vncodusur;

              vbvalido := TRUE;
            END IF;
          END IF;
        ELSE
          --p_pvendanovo < vnpvendatual
          vbvalido := ccfinrca_excluir_item_pedido(p_codfunclanc,
                                                   p_rotinalanc,
                                                   vncodusur,
                                                   p_numped,
                                                   p_codprod,
                                                   p_numseq,
                                                   p_qtnova,
                                                   p_pvendanovo,
                                                   vsmensagem);
        END IF;
      END IF; -- p_pvendanovo > 0
    END IF;

    p_mensagem := vsmensagem;
    RETURN vbvalido;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao alterar preço ou quantidade : ' || SQLCODE || ' ' ||
                    SQLERRM;
      RETURN FALSE;
  END; --ccfinrca_alterar_preco_qt

  --Projeto 90992 RBD6
  FUNCTION ccfinrca_altera_descfin_pedido(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                          p_rotinalanc  IN pclogrca.rotina%TYPE,
                                          p_codusur     IN pcpedc.codusur%TYPE,
                                          p_numped      IN pcpedc.numped%TYPE,
                                          p_novodescfin IN NUMBER,
                                          p_mensagem    OUT VARCHAR2)
    RETURN BOOLEAN IS
    vbvalido                       BOOLEAN;
    vncodusur                      pcpedc.codusur%TYPE;
    vncondvenda                    pcpedc.condvenda%TYPE;
    vsusasaldocontacorrentedescfin pcpedc.usasaldocontacorrentedescfin%TYPE;
    vstipomovccrca                 pcpedc.tipomovccrca%TYPE;
    vnperdescfin                   pcpedc.perdescfin%TYPE;
    vscodfilial                    pcpedc.codfilial%TYPE;
    vicontador                     NUMBER;
    vnvldifdescfin                 NUMBER;
    vnvlsaldo                      NUMBER;
    vnvltotalitens                 NUMBER;
    vnvalor                        NUMBER;
    vnvlsaldorca                   NUMBER;
    vstipo                         VARCHAR2(1);
    vsmensagem                     VARCHAR2(300);
  BEGIN
    vbvalido   := FALSE;
    vsmensagem := 'OK';

    SELECT pcpedc.codusur,
           pcpedc.condvenda,
           pcpedc.usasaldocontacorrentedescfin,
           pcpedc.tipomovccrca,
           pcpedc.perdescfin,
           pcpedc.codfilial
      INTO vncodusur,
           vncondvenda,
           vsusasaldocontacorrentedescfin,
           vstipomovccrca,
           vnperdescfin,
           vscodfilial
      FROM pcpedc
     WHERE pcpedc.numped = p_numped;

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(vncodusur, -- RCA que já estava buscando no Pedido
                                       p_numped);

    -- Tarefa 99976
    IF (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       (NVL(vsusasaldocontacorrentedescfin, 'N') = 'S') THEN
      vbvalido := TRUE;
    END IF;
    -- Fim tarefa 99976

    IF NOT (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       ((NVL(vsusasaldocontacorrentedescfin, 'N')) = 'S') AND
       (NVL(vstipomovccrca, 'VV') NOT IN ('FF', 'VV')) THEN
      vbvalido := TRUE; -- Tarefa 103882

      SELECT COUNT(*)
        INTO vicontador
        FROM pcsaldorca
       WHERE codusur = vncodusur;

      IF vicontador = 0 THEN
        INSERT INTO pcsaldorca
          (codusur, vlsaldo, vlsaldoant)
        VALUES
          (vncodusur, 0, 0);
      END IF;

      vnvldifdescfin := NVL(vnperdescfin, 0) - NVL(p_novodescfin, 0);

      SELECT NVL(vlsaldo, 0)
        INTO vnvlsaldo
        FROM pcsaldorca
       WHERE codusur = vncodusur
         FOR UPDATE;

      SELECT (SUM(pcpedi.pvenda * pcpedi.qt))
        INTO vnvltotalitens
        FROM pcpedi
       WHERE pcpedi.numped = p_numped
         AND pcpedi.qt > 0;

      vnvalor := NVL(vnvltotalitens, 0) * (NVL(vnvldifdescfin, 0) / 100);

      IF vnvalor > 0 THEN
        vstipo := 'C';
      ELSE
        vstipo := 'D';
      END IF;

      IF (vstipo = 'D') THEN
        vnvlsaldorca := ccfinrca_saldorcamenosdescfin(vncodusur,
                                                      vscodfilial);

        IF (vnvlsaldorca < vnvalor * (-1)) --correção sabrina
         THEN
          vbvalido   := FALSE;
          vsmensagem := 'Rca não tem saldo para alterar desconto financeiro.';
        END IF;
      END IF;

      IF vbvalido = TRUE
        -- correção sabrina (esta alteração soh deve ser feita se houver saldo)
         AND NVL(vstipomovccrca, 'VV') NOT IN ('FF', 'VV') THEN
        INSERT INTO pcmovsaldorca
          (DATA,
           codfunc,
           codusur,
           rotina,
           tipo,
           valor,
           vlsaldoant,
           vlsaldo,
           historico,
           numped)
        VALUES
          (SYSDATE,
           p_codfunclanc,
           vncodusur,
           p_rotinalanc,
           vstipo,
           vnvalor,
           vnvlsaldo,
           (vnvlsaldo + vnvalor),
           'PEDIDO DE VENDA',
           p_numped);

        UPDATE pcsaldorca
           SET vlsaldoant = vnvlsaldo, vlsaldo = (vnvlsaldo + vnvalor)
         WHERE codusur = vncodusur;

        vbvalido := TRUE;
      END IF;
    END IF;

    p_mensagem := vsmensagem;
    RETURN(vbvalido);
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao alterar descotno financeiro : ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END; --ccfinrca_altera_descfin_pedido

  --Projeto 90992 RBD8
  FUNCTION ccfinrca_fatura_pedido(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                  p_rotinalanc  IN pclogrca.rotina%TYPE,
                                  p_codusur     IN pcpedc.codusur%TYPE,
                                  p_numped      IN pcpedc.numped%TYPE,
                                  p_mensagem    OUT VARCHAR2)
  /******************************************************
    Data        Autor   Tarefa     Obs.
    08/12/2009  Pablo   95754      Inicializando as variáveis vncondvenda,
                                   vnperdescfin
    16/12/2009  Pablo                   Alteração para não realizar divisão por zero
    *****************************************************/
   RETURN BOOLEAN IS
    vbvalido                       BOOLEAN;
    vncodusur                      pcpedc.codusur%TYPE;
    vncondvenda                    pcpedc.condvenda%TYPE;
    vsusasaldocontacorrentedescfin pcpedc.usasaldocontacorrentedescfin%TYPE;
    vstipomovccrca                 pcpedc.tipomovccrca%TYPE;
    vnperdescfin                   pcpedc.perdescfin%TYPE;
    vscodfilial                    pcpedc.codfilial%TYPE;
    vnnumtransvenda                pcpedc.numtransvenda%TYPE;
    vicontador                     NUMBER;
    vnvlsaldo                      NUMBER;
    vnvltotalitens                 NUMBER;
    vnvlsaldorca                   NUMBER;
    vsmensagem                     VARCHAR2(300);
    vndescmax                      NUMBER;
    vnfixo                         NUMBER;
    vncreditosaldorca              NUMBER;
    vnvalordebito                  NUMBER;

  BEGIN
    vbvalido   := FALSE;
    vsmensagem := 'OK';

    SELECT p.codusur,
           p.codfilial,
           p.tipomovccrca,
           p.usasaldocontacorrentedescfin,
           p.condvenda,
           p.perdescfin
      INTO vncodusur,
           vscodfilial,
           vstipomovccrca,
           vsusasaldocontacorrentedescfin,
           vncondvenda,
           vnperdescfin
      FROM pcpedc p
     WHERE p.numped = p_numped;

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(vncodusur, -- RCA que já estava buscando no Pedido
                                       p_numped);

    -- MED-2359
    BEGIN
      SELECT numtransvenda
        INTO vnnumtransvenda
        FROM PCNFSAIDPREFAT
       WHERE numped = p_numped
         AND ROWNUM = 1;
    EXCEPTION
      -- MED-2359
      WHEN NO_DATA_FOUND THEN
        vnnumtransvenda := 0;
    END;     

    /*MED-2277*/
    IF NVL(vnnumtransvenda,0) = 0 THEN
      SELECT numtransvenda
        INTO vnnumtransvenda
        FROM PCNFSAID
       WHERE numped = p_numped
         AND ROWNUM = 1;
    END IF;

    -- Tarefa 99976
    IF (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       (NVL(vsusasaldocontacorrentedescfin, 'N') = 'S') THEN
      vbvalido := TRUE;
    END IF;
    -- Fim tarefa 99976

    IF NOT (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       ((NVL(vsusasaldocontacorrentedescfin, 'N')) = 'S') THEN
      SELECT COUNT(*)
        INTO vicontador
        FROM pcsaldorca
       WHERE codusur = vncodusur;

      IF vicontador = 0 THEN
        INSERT INTO pcsaldorca
          (codusur, vlsaldo, vlsaldoant)
        VALUES
          (vncodusur, 0, 0);
      END IF;

      SELECT NVL(vlsaldo, 0)
        INTO vnvlsaldo
        FROM pcsaldorca
       WHERE codusur = vncodusur
         FOR UPDATE;

      --VF
      IF (NVL(vstipomovccrca, 'VV') = 'VF') THEN
        --RBD10
        SELECT NVL(descmax, 0), NVL(fixo, 0)
          INTO vndescmax, vnfixo
          FROM pcparamsaldo
         WHERE ROWNUM = 1;

        vncreditosaldorca := 0;

        --alteração feita para evitar erro de divisor 0
        begin

          SELECT SUM(((((vndescmax - pcpedi.perdesc) / vnfixo -
                     tab.percacresc) / 100) * pcpedi.pvenda) -- Pablo 16/12/2009
                     * pcpedi.qt)
            INTO vncreditosaldorca
            FROM pcpedi,
                 (SELECT pcfaixadesc.percacresc,
                         pcfaixadesc.percinicio,
                         pcfaixadesc.percfim
                    FROM pcfaixadesc) tab
           WHERE pcpedi.numped = p_numped
             AND pcpedi.qt > 0
             AND pcpedi.perdesc BETWEEN tab.percinicio AND tab.percfim;
        exception
          when others then
            vncreditosaldorca := 0;

        end;

        IF NVL(vncreditosaldorca, 0) < 0 THEN
          vncreditosaldorca := 0;
        END IF;

        INSERT INTO pcmovsaldorca
          (DATA,
           codfunc,
           codusur,
           rotina,
           tipo,
           valor,
           vlsaldoant,
           vlsaldo,
           historico,
           numtransvenda)
        VALUES
          (SYSDATE,
           p_codfunclanc,
           vncodusur,
           p_rotinalanc,
           'C',
           NVL(vncreditosaldorca, 0),
           vnvlsaldo,
           (vnvlsaldo + NVL(vncreditosaldorca, 0)),
           'FATURAMENTO DE PEDIDO',
           vnnumtransvenda);

        UPDATE pcsaldorca
           SET vlsaldoant = vnvlsaldo,
               vlsaldo    = (vnvlsaldo + NVL(vncreditosaldorca, 0))
         WHERE codusur = vncodusur;

        vbvalido := TRUE;
        --FF
      ELSIF (NVL(vstipomovccrca, 'VV') IN ('VV', 'FF')) THEN
        --RBD11 débito
        IF NVL(vnperdescfin, 0) > 0 THEN
          SELECT (SUM(pcpedi.pvenda * pcpedi.qt))
            INTO vnvltotalitens
            FROM pcpedi
           WHERE pcpedi.numped = p_numped
             AND pcpedi.qt > 0;

          vnvalordebito := vnvltotalitens * (vnperdescfin / 100);

          IF vnvalordebito > 0 THEN
            vnvalordebito := vnvalordebito * (-1);
          END IF;

          INSERT INTO pcmovsaldorca
            (DATA,
             codfunc,
             codusur,
             rotina,
             tipo,
             valor,
             vlsaldoant,
             vlsaldo,
             historico,
             numped)
          VALUES
            (SYSDATE,
             p_codfunclanc,
             vncodusur,
             p_rotinalanc,
             'D',
             vnvalordebito,
             vnvlsaldo,
             (vnvlsaldo + (vnvalordebito)),
             'PEDIDO DE VENDA',
             p_numped);

          UPDATE pcsaldorca
             SET vlsaldoant = vnvlsaldo,
                 vlsaldo    = (vnvlsaldo + (vnvalordebito))
           WHERE codusur = vncodusur;
        END IF;
        --RBD10 crédito
        SELECT NVL(vlsaldo, 0)
          INTO vnvlsaldo
          FROM pcsaldorca
         WHERE codusur = vncodusur
           FOR UPDATE;

        SELECT NVL(descmax, 0), NVL(fixo, 0)
          INTO vndescmax, vnfixo
          FROM pcparamsaldo
         WHERE ROWNUM = 1;

        vncreditosaldorca := 0;

        --alteração feita para evitar erro de divisor 0

        begin

          SELECT SUM(((((vndescmax - pcpedi.perdesc) / vnfixo -
                     tab.percacresc) / 100) * pcpedi.pvenda) -- Pablo 16/12/2009
                     * pcpedi.qt)
            INTO vncreditosaldorca
            FROM pcpedi,
                 (SELECT pcfaixadesc.percacresc,
                         pcfaixadesc.percinicio,
                         pcfaixadesc.percfim
                    FROM pcfaixadesc) tab
           WHERE pcpedi.numped = p_numped
             AND pcpedi.qt > 0
             AND pcpedi.perdesc BETWEEN tab.percinicio AND tab.percfim;

        exception
          when others then
            vncreditosaldorca := 0;

        end;

        IF NVL(vncreditosaldorca, 0) < 0 THEN
          vncreditosaldorca := 0;
        END IF;

        INSERT INTO pcmovsaldorca
          (DATA,
           codfunc,
           codusur,
           rotina,
           tipo,
           valor,
           vlsaldoant,
           vlsaldo,
           historico,
           numtransvenda,
           numped)
        VALUES
          (SYSDATE,
           p_codfunclanc,
           vncodusur,
           p_rotinalanc,
           'C',
           NVL(vncreditosaldorca, 0),
           vnvlsaldo,
           (vnvlsaldo + NVL(vncreditosaldorca, 0)),
           'FATURAMENTO DE PEDIDO',
           vnnumtransvenda,
           p_numped);

        UPDATE pcsaldorca
           SET vlsaldoant = vnvlsaldo,
               vlsaldo    = (vnvlsaldo + NVL(vncreditosaldorca, 0))
         WHERE codusur = vncodusur;

        vbvalido := TRUE;
      elsif (NVL(vstipomovccrca, 'VV') = 'VA') then
        vbvalido := TRUE;
      END IF;
      -- END IF;
    END IF;

    p_mensagem := vsmensagem;
    RETURN(vbvalido);
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao faturar pedido : ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN vbvalido;
  END; --ccfinrca_Fatura_pedido

  --Projeto 90992 - RBD12
  FUNCTION ccfinrca_cancela_notafiscal(p_codfunclanc   IN pclogrca.codfunc%TYPE,
                                       p_rotinalanc    IN pclogrca.rotina%TYPE,
                                       p_codusur       IN pcpedc.codusur%TYPE,
                                       p_numtransvenda IN PCNFSAIDPREFAT.numtransvenda%TYPE,
                                       p_cancelapedido IN VARCHAR2,
                                       p_mensagem      OUT VARCHAR2)
    RETURN BOOLEAN IS
    vbvalido                       BOOLEAN;
    vncodusur                      PCNFSAIDPREFAT.codusur%TYPE;
    vncondvenda                    pcpedc.condvenda%TYPE;
    vsusasaldocontacorrentedescfin pcpedc.usasaldocontacorrentedescfin%TYPE;
    vstipomovccrca                 pcpedc.tipomovccrca%TYPE;
    vnperdescfin                   pcpedc.perdescfin%TYPE;
    vscodfilial                    pcpedc.codfilial%TYPE;
    vnnumped                       pcpedc.numped%TYPE;
    vicontador                     NUMBER;
    vnvlsaldo                      NUMBER;
    vndescmax                      NUMBER;
    vnfixo                         NUMBER;
    vndebitosaldorca               NUMBER;
    vncreditosaldorca              NUMBER;
    vsmensagem                     VARCHAR2(300);
    vnvltotalitens                 NUMBER;

  BEGIN
    vbvalido   := FALSE;
    vsmensagem := 'OK';

    -- MED-2359
    BEGIN
      SELECT PCNFSAIDPREFAT.codusur,
             pcpedc.condvenda,
             pcpedc.usasaldocontacorrentedescfin,
             pcpedc.tipomovccrca,
             pcpedc.perdescfin,
             pcpedc.codfilial,
             pcpedc.numped
        INTO vncodusur,
             vncondvenda,
             vsusasaldocontacorrentedescfin,
             vstipomovccrca,
             vnperdescfin,
             vscodfilial,
             vnnumped
        FROM pcpedc, PCNFSAIDPREFAT
       WHERE pcpedc.numped = PCNFSAIDPREFAT.numped
         AND PCNFSAIDPREFAT.numtransvenda = p_numtransvenda;
    EXCEPTION
      -- MED-2359
      WHEN NO_DATA_FOUND THEN
        vncodusur := 0;
    END;         

    IF NVL(vncodusur,0) = 0 THEN

      /*MED-2277*/
      SELECT PCNFSAID.codusur,
             pcpedc.condvenda,
             pcpedc.usasaldocontacorrentedescfin,
             pcpedc.tipomovccrca,
             pcpedc.perdescfin,
             pcpedc.codfilial,
             pcpedc.numped
        INTO vncodusur,
             vncondvenda,
             vsusasaldocontacorrentedescfin,
             vstipomovccrca,
             vnperdescfin,
             vscodfilial,
             vnnumped
        FROM pcpedc, PCNFSAID
       WHERE pcpedc.numped = PCNFSAID.numped
         AND PCNFSAID.numtransvenda = p_numtransvenda;

    END IF;

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(vncodusur, -- RCA que já estava buscando no Pedido
                                       vnnumped);

    -- Tarefa 99976
    IF (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       (NVL(vsusasaldocontacorrentedescfin, 'N') = 'S') THEN
      vbvalido := TRUE;
    END IF;
    -- Fim tarefa 99976

    IF NOT (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       ((NVL(vsusasaldocontacorrentedescfin, 'N')) = 'S') THEN
      SELECT COUNT(*)
        INTO vicontador
        FROM pcsaldorca
       WHERE codusur = vncodusur;

      IF vicontador = 0 THEN
        INSERT INTO pcsaldorca
          (codusur, vlsaldo, vlsaldoant)
        VALUES
          (vncodusur, 0, 0);
      END IF;

      SELECT NVL(vlsaldo, 0)
        INTO vnvlsaldo
        FROM pcsaldorca
       WHERE codusur = vncodusur
         FOR UPDATE;

      --VF
      IF (NVL(vstipomovccrca, 'VV') = 'VF') THEN
        --RBD10
        SELECT NVL(descmax, 0), NVL(fixo, 0)
          INTO vndescmax, vnfixo
          FROM pcparamsaldo
         WHERE ROWNUM = 1;

        vndebitosaldorca := 0;

        --alteração feita para evitar erro de divisor 0
        begin

          SELECT SUM(((((vndescmax - pcpedi.perdesc) / vnfixo -
                     tab.percacresc) / 100) * pcpedi.pvenda) -- Pablo 16/12/2009
                     * pcpedi.qt)
            INTO vndebitosaldorca
            FROM pcpedi,
                 (SELECT pcfaixadesc.percacresc,
                         pcfaixadesc.percinicio,
                         pcfaixadesc.percfim
                    FROM pcfaixadesc) tab
           WHERE pcpedi.numped = vnnumped
             AND pcpedi.qt > 0
             AND pcpedi.perdesc BETWEEN tab.percinicio AND tab.percfim;

        exception
          when others then
            vndebitosaldorca := 0;

        end;

        IF NVL(vndebitosaldorca, 0) < 0 THEN
          vndebitosaldorca := 0;
        END IF;

        INSERT INTO pcmovsaldorca
          (DATA,
           codfunc,
           codusur,
           rotina,
           tipo,
           valor,
           vlsaldoant,
           vlsaldo,
           historico,
           numtransvenda)
        VALUES
          (SYSDATE,
           p_codfunclanc,
           vncodusur,
           p_rotinalanc,
           'D',
           NVL(vndebitosaldorca, 0) * (-1),
           vnvlsaldo,
           (vnvlsaldo - NVL(vndebitosaldorca, 0)),
           'FATURAMENTO DE PEDIDO',
           p_numtransvenda);

        UPDATE pcsaldorca
           SET vlsaldoant = vnvlsaldo,
               vlsaldo    = (vnvlsaldo - NVL(vndebitosaldorca, 0))
         WHERE codusur = vncodusur;

        vbvalido := TRUE;

        IF p_cancelapedido = 'S' THEN
          SELECT NVL(vlsaldo, 0)
            INTO vnvlsaldo
            FROM pcsaldorca
           WHERE codusur = vncodusur
             FOR UPDATE;

          --RBD11
          IF NVL(vnperdescfin, 0) > 0 THEN
            SELECT (SUM(pcpedi.pvenda * pcpedi.qt))
              INTO vnvltotalitens
              FROM pcpedi
             WHERE pcpedi.numped = vnnumped
               AND pcpedi.qt > 0;

            vncreditosaldorca := vnvltotalitens * (vnperdescfin / 100);

            IF vncreditosaldorca < 0 THEN
              vncreditosaldorca := vncreditosaldorca * (-1);
            END IF;

            INSERT INTO pcmovsaldorca
              (DATA,
               codfunc,
               codusur,
               rotina,
               tipo,
               valor,
               vlsaldoant,
               vlsaldo,
               historico,
               numped)
            VALUES
              (SYSDATE,
               p_codfunclanc,
               vncodusur,
               p_rotinalanc,
               'C',
               vncreditosaldorca,
               vnvlsaldo,
               (vnvlsaldo + (vncreditosaldorca)),
               'PEDIDO DE VENDA',
               vnnumped);

            UPDATE pcsaldorca
               SET vlsaldoant = vnvlsaldo,
                   vlsaldo    = (vnvlsaldo + (vncreditosaldorca))
             WHERE codusur = vncodusur;

            vbvalido := TRUE;
          END IF;
        END IF;
        --VA
      ELSIF (NVL(vstipomovccrca, 'VV') = 'VA') THEN
        IF p_cancelapedido = 'S' THEN
          --RBD11
          IF NVL(vnperdescfin, 0) > 0 THEN
            SELECT (SUM(pcpedi.pvenda * pcpedi.qt))
              INTO vnvltotalitens
              FROM pcpedi
             WHERE pcpedi.numped = vnnumped
               AND pcpedi.qt > 0;

            vncreditosaldorca := vnvltotalitens * (vnperdescfin / 100);

            IF vncreditosaldorca < 0 THEN
              vncreditosaldorca := vncreditosaldorca * (-1);
            END IF;

            INSERT INTO pcmovsaldorca
              (DATA,
               codfunc,
               codusur,
               rotina,
               tipo,
               valor,
               vlsaldoant,
               vlsaldo,
               historico,
               numped)
            VALUES
              (SYSDATE,
               p_codfunclanc,
               vncodusur,
               p_rotinalanc,
               'C',
               vncreditosaldorca,
               vnvlsaldo,
               (vnvlsaldo + (vncreditosaldorca)),
               'PEDIDO DE VENDA',
               vnnumped);

            UPDATE pcsaldorca
               SET vlsaldoant = vnvlsaldo,
                   vlsaldo    = (vnvlsaldo + (vncreditosaldorca))
             WHERE codusur = vncodusur;

            vbvalido := TRUE;
          ELSE
            --Tarefa 106838
            vbvalido := TRUE;
          END IF;
        END IF;

        SELECT count(*)
          into vicontador
          FROM PCPRESTPREFAT
         WHERE NUMTRANSVENDA = p_numtransvenda
           AND DTFECHA IS NOT NULL
           AND NVL(VALOR, 0) > 0
           AND CODCOB <> 'DESD';

        if vicontador > 0 then

          --RBD10
          SELECT NVL(descmax, 0), NVL(fixo, 0)
            INTO vndescmax, vnfixo
            FROM pcparamsaldo
           WHERE ROWNUM = 1;

          vndebitosaldorca := 0;

          --alteração feita para evitar erro de divisor 0
          begin

            SELECT SUM(((((vndescmax - pcpedi.perdesc) / vnfixo -
                       tab.percacresc) / 100) * pcpedi.pvenda) -- Pablo 16/12/2009
                       * pcpedi.qt)
              INTO vndebitosaldorca
              FROM pcpedi,
                   (SELECT pcfaixadesc.percacresc,
                           pcfaixadesc.percinicio,
                           pcfaixadesc.percfim
                      FROM pcfaixadesc) tab
             WHERE pcpedi.numped = vnnumped
               AND pcpedi.qt > 0
               AND pcpedi.perdesc BETWEEN tab.percinicio AND tab.percfim;

          exception
            when others then
              vndebitosaldorca := 0;

          end;

          IF NVL(vndebitosaldorca, 0) < 0 THEN
            vndebitosaldorca := 0;
          END IF;

          -- tarefa 99600
          SELECT NVL(vlsaldo, 0)
            INTO vnvlsaldo
            FROM pcsaldorca
           WHERE codusur = vncodusur
             FOR UPDATE;

          INSERT INTO pcmovsaldorca
            (DATA,
             codfunc,
             codusur,
             rotina,
             tipo,
             valor,
             vlsaldoant,
             vlsaldo,
             historico,
             numtransvenda)
          VALUES
            (SYSDATE,
             p_codfunclanc,
             vncodusur,
             p_rotinalanc,
             'D',
             NVL(vndebitosaldorca, 0) * (-1),
             vnvlsaldo,
             (vnvlsaldo - NVL(vndebitosaldorca, 0)),
             'FATURAMENTO DE PEDIDO',
             p_numtransvenda);

          UPDATE pcsaldorca
             SET vlsaldoant = vnvlsaldo,
                 vlsaldo    = (vnvlsaldo - NVL(vndebitosaldorca, 0))
           WHERE codusur = vncodusur;

          vbvalido := TRUE;

        end if;

        --FF
      ELSIF (NVL(vstipomovccrca, 'VV') in ('VV', 'FF')) THEN
        --RBD11
        --  IF NVL (vnperdescfin, 0) > 0
        -- THEN
        SELECT (SUM(pcpedi.pvenda * pcpedi.qt))
          INTO vnvltotalitens
          FROM pcpedi
         WHERE pcpedi.numped = vnnumped
           AND pcpedi.qt > 0;

        vncreditosaldorca := vnvltotalitens * (vnperdescfin / 100);

        IF vncreditosaldorca < 0 THEN
          vncreditosaldorca := vncreditosaldorca * (-1);
        END IF;

        INSERT INTO pcmovsaldorca
          (DATA,
           codfunc,
           codusur,
           rotina,
           tipo,
           valor,
           vlsaldoant,
           vlsaldo,
           historico,
           numped)
        VALUES
          (SYSDATE,
           p_codfunclanc,
           vncodusur,
           p_rotinalanc,
           'C',
           vncreditosaldorca,
           vnvlsaldo,
           (vnvlsaldo + (vncreditosaldorca)),
           'PEDIDO DE VENDA',
           vnnumped);

        UPDATE pcsaldorca
           SET vlsaldoant = vnvlsaldo,
               vlsaldo    = (vnvlsaldo + (vncreditosaldorca))
         WHERE codusur = vncodusur;

        vbvalido := TRUE;

        --RBD10
        SELECT NVL(vlsaldo, 0)
          INTO vnvlsaldo
          FROM pcsaldorca
         WHERE codusur = vncodusur
           FOR UPDATE;

        SELECT NVL(descmax, 0), NVL(fixo, 0)
          INTO vndescmax, vnfixo
          FROM pcparamsaldo
         WHERE ROWNUM = 1;

        vndebitosaldorca := 0;

        --alteração feita para evitar erro de divisor 0

        begin

          SELECT SUM(((((vndescmax - pcpedi.perdesc) / vnfixo -
                     tab.percacresc) / 100) * pcpedi.pvenda) -- Pablo 16/12/2009
                     * pcpedi.qt)
            INTO vndebitosaldorca
            FROM pcpedi,
                 (SELECT pcfaixadesc.percacresc,
                         pcfaixadesc.percinicio,
                         pcfaixadesc.percfim
                    FROM pcfaixadesc) tab
           WHERE pcpedi.numped = vnnumped
             AND pcpedi.qt > 0
             AND pcpedi.perdesc BETWEEN tab.percinicio AND tab.percfim;

        exception
          when others then
            vndebitosaldorca := 0;

        end;

        IF NVL(vndebitosaldorca, 0) < 0 THEN
          vndebitosaldorca := 0;
        END IF;

        INSERT INTO pcmovsaldorca
          (DATA,
           codfunc,
           codusur,
           rotina,
           tipo,
           valor,
           vlsaldoant,
           vlsaldo,
           historico,
           numtransvenda)
        VALUES
          (SYSDATE,
           p_codfunclanc,
           vncodusur,
           p_rotinalanc,
           'D',
           NVL(vndebitosaldorca, 0) * (-1),
           vnvlsaldo,
           (vnvlsaldo - NVL(vndebitosaldorca, 0)),
           'FATURAMENTO DE PEDIDO',
           p_numtransvenda);

        UPDATE pcsaldorca
           SET vlsaldoant = vnvlsaldo,
               vlsaldo    = (vnvlsaldo - NVL(vndebitosaldorca, 0))
         WHERE codusur = vncodusur;

        vbvalido := TRUE;
        --  END IF;
      END IF;
    END IF;

    p_mensagem := vsmensagem;
    RETURN vbvalido;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao cancelar nota fiscal : ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN vbvalido;
  END; -- ccfinrca_cancela_notafiscal

  PROCEDURE ccfinrca_lanca_movimento_carga(p_codfunclanc         IN pclogrca.codfunc%TYPE,
                                           p_rotinalanc          IN pclogrca.rotina%TYPE,
                                           p_numcar              IN PCNFSAIDPREFAT.numcar%TYPE,
                                           p_dataemissao_inicial IN DATE,
                                           p_dataemissao_final   IN DATE,
                                           p_mensagem            OUT VARCHAR2) IS
    vbvalido                       BOOLEAN;
    vsmensagem                     VARCHAR2(300);
    vncodusur                      pcpedc.codusur%TYPE;
    vncondvenda                    pcpedc.condvenda%TYPE;
    vsusasaldocontacorrentedescfin pcpedc.usasaldocontacorrentedescfin%TYPE;
    vstipomovccrca                 pcpedc.tipomovccrca%TYPE;
    vnperdescfin                   pcpedc.perdescfin%TYPE;
    vscodfilial                    pcpedc.codfilial%TYPE;
    vnnumped                       pcpedc.numped%TYPE;
    vicontador                     NUMBER;
    vnvlsaldo                      NUMBER;
    vndescmax                      NUMBER;
    vnfixo                         NUMBER;
    vncreditosaldorca              NUMBER;

  BEGIN
    vsmensagem := 'OK';

    IF NVL(p_numcar, 0) = 0 THEN
      FOR reg IN (SELECT numtransvenda, dtfechaccrca
                    FROM PCNFSAIDPREFAT
                   WHERE numcar = NVL(p_numcar, 0)
                        --Tarefa 105946
                     AND PCNFSAIDPREFAT.dtcancel is null
                     AND dtsaida BETWEEN p_dataemissao_inicial AND
                         p_dataemissao_final
                  /*MED-2277*/
                  union
                  SELECT numtransvenda, dtfechaccrca
                    FROM PCNFSAID
                   WHERE numcar = NVL(p_numcar, 0)
                        --Tarefa 105946
                     AND PCNFSAID.dtcancel is null
                     AND dtsaida BETWEEN p_dataemissao_inicial AND
                         p_dataemissao_final) LOOP
        vbvalido := ccrca_verificar_fechamento(reg.numtransvenda);

        IF vbvalido = TRUE THEN
          IF reg.dtfechaccrca IS NULL THEN
            SELECT PCNFSAIDPREFAT.codusur,
                   pcpedc.condvenda,
                   pcpedc.usasaldocontacorrentedescfin,
                   pcpedc.tipomovccrca,
                   pcpedc.perdescfin,
                   pcpedc.codfilial,
                   pcpedc.numped
              INTO vncodusur,
                   vncondvenda,
                   vsusasaldocontacorrentedescfin,
                   vstipomovccrca,
                   vnperdescfin,
                   vscodfilial,
                   vnnumped
              FROM pcpedc, PCNFSAIDPREFAT
             WHERE pcpedc.numped = PCNFSAIDPREFAT.numped
                  --Tarefa 105946
               AND PCNFSAIDPREFAT.dtcancel is null
               AND PCNFSAIDPREFAT.numtransvenda = reg.numtransvenda;

            /*MED-2277*/
            IF NVL(vncodusur,0) = 0 THEN

              SELECT PCNFSAID.codusur,
                     pcpedc.condvenda,
                     pcpedc.usasaldocontacorrentedescfin,
                     pcpedc.tipomovccrca,
                     pcpedc.perdescfin,
                     pcpedc.codfilial,
                     pcpedc.numped
                INTO vncodusur,
                     vncondvenda,
                     vsusasaldocontacorrentedescfin,
                     vstipomovccrca,
                     vnperdescfin,
                     vscodfilial,
                     vnnumped
                FROM pcpedc, PCNFSAID
               WHERE pcpedc.numped = PCNFSAID.numped
                    --Tarefa 105946
                 AND PCNFSAID.dtcancel is null
                 AND PCNFSAID.numtransvenda = reg.numtransvenda;

            END IF;

            -- HIS.00632.2016
            vncodusur := ObterRcaContaCorrente(vncodusur, -- RCA que já estava buscando no Pedido
                                               vnnumped);

            -- Tarefa 99976
            IF (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
               (NVL(vsusasaldocontacorrentedescfin, 'N') = 'S') THEN
              vbvalido := TRUE;
            END IF;
            -- Fim tarefa 99976

            IF NOT (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
               ((NVL(vsusasaldocontacorrentedescfin, 'N')) = 'S') THEN
              SELECT COUNT(*)
                INTO vicontador
                FROM pcsaldorca
               WHERE codusur = vncodusur;

              IF vicontador = 0 THEN
                INSERT INTO pcsaldorca
                  (codusur, vlsaldo, vlsaldoant)
                VALUES
                  (vncodusur, 0, 0);
              END IF;

              SELECT NVL(vlsaldo, 0)
                INTO vnvlsaldo
                FROM pcsaldorca
               WHERE codusur = vncodusur
                 FOR UPDATE;

              --RBD10
              SELECT NVL(descmax, 0), NVL(fixo, 0)
                INTO vndescmax, vnfixo
                FROM pcparamsaldo
               WHERE ROWNUM = 1;

              vncreditosaldorca := 0;

              --alteração feita para evitar erro de divisor 0
              begin

                SELECT SUM(((((vndescmax - pcpedi.perdesc) / vnfixo -
                           tab.percacresc) / 100) * pcpedi.pvenda) -- Pablo 16/12/2009
                           * pcpedi.qt)
                  INTO vncreditosaldorca
                  FROM pcpedi,
                       (SELECT pcfaixadesc.percacresc,
                               pcfaixadesc.percinicio,
                               pcfaixadesc.percfim
                          FROM pcfaixadesc) tab
                 WHERE pcpedi.numped = vnnumped
                   AND pcpedi.qt > 0
                   AND pcpedi.perdesc BETWEEN tab.percinicio AND
                       tab.percfim;

              exception
                when others then
                  vncreditosaldorca := 0;

              end;

              IF NVL(vncreditosaldorca, 0) < 0 THEN
                vncreditosaldorca := 0;
              END IF;

              INSERT INTO pcmovsaldorca
                (DATA,
                 codfunc,
                 codusur,
                 rotina,
                 tipo,
                 valor,
                 vlsaldoant,
                 vlsaldo,
                 historico,
                 numtransvenda)
              VALUES
                (SYSDATE,
                 p_codfunclanc,
                 vncodusur,
                 p_rotinalanc,
                 'C',
                 NVL(vncreditosaldorca, 0),
                 vnvlsaldo,
                 (vnvlsaldo + NVL(vncreditosaldorca, 0)),
                 'MOVIMENTO CARGA',
                 reg.numtransvenda);

              UPDATE pcsaldorca
                 SET vlsaldoant = vnvlsaldo,
                     vlsaldo    = (vnvlsaldo + NVL(vncreditosaldorca, 0))
               WHERE codusur = vncodusur;

              /*MED-2277*/
              BEGIN
                UPDATE PCNFSAIDPREFAT
                   SET dtfechaccrca = SYSDATE
                 WHERE numtransvenda = reg.numtransvenda;
              exception
                when others then
                    UPDATE PCNFSAID
                       SET dtfechaccrca = SYSDATE
                     WHERE numtransvenda = reg.numtransvenda;
              END;

              vbvalido := TRUE;
            END IF;
          END IF;
        END IF;
      END LOOP;
    ELSE
      FOR reg IN (SELECT numtransvenda, dtfechaccrca
                    FROM PCNFSAIDPREFAT
                   WHERE PCNFSAIDPREFAT.numcar = p_numcar
                        --Tarefa 105946
                     AND PCNFSAIDPREFAT.dtcancel is null
                     AND EXISTS (select pcpedc.numtransvenda
                            from pcpedc
                           where pcpedc.numtransvenda =
                                 PCNFSAIDPREFAT.numtransvenda)
                 /*MED-2277*/
                 union
                  SELECT numtransvenda, dtfechaccrca
                    FROM PCNFSAID
                   WHERE PCNFSAID.numcar = p_numcar
                        --Tarefa 105946
                     AND PCNFSAID.dtcancel is null
                     AND EXISTS (select pcpedc.numtransvenda
                            from pcpedc
                           where pcpedc.numtransvenda =
                                 PCNFSAID.numtransvenda)
                 ) LOOP
        vbvalido := ccrca_verificar_fechamento(reg.numtransvenda);

        IF vbvalido = TRUE THEN
          IF reg.dtfechaccrca IS NULL THEN
            SELECT PCNFSAIDPREFAT.codusur,
                   pcpedc.condvenda,
                   pcpedc.usasaldocontacorrentedescfin,
                   pcpedc.tipomovccrca,
                   pcpedc.perdescfin,
                   pcpedc.codfilial,
                   pcpedc.numped
              INTO vncodusur,
                   vncondvenda,
                   vsusasaldocontacorrentedescfin,
                   vstipomovccrca,
                   vnperdescfin,
                   vscodfilial,
                   vnnumped
              FROM pcpedc, PCNFSAIDPREFAT
             WHERE pcpedc.numped = PCNFSAIDPREFAT.numped
               AND PCNFSAIDPREFAT.numtransvenda = reg.numtransvenda;

            /*MED-2277*/
            IF NVL(vncodusur,0) = 0 THEN
              SELECT PCNFSAID.codusur,
                     pcpedc.condvenda,
                     pcpedc.usasaldocontacorrentedescfin,
                     pcpedc.tipomovccrca,
                     pcpedc.perdescfin,
                     pcpedc.codfilial,
                     pcpedc.numped
                INTO vncodusur,
                     vncondvenda,
                     vsusasaldocontacorrentedescfin,
                     vstipomovccrca,
                     vnperdescfin,
                     vscodfilial,
                     vnnumped
                FROM pcpedc, PCNFSAID
               WHERE pcpedc.numped = PCNFSAID.numped
                 AND PCNFSAID.numtransvenda = reg.numtransvenda;

            END IF;

            IF NOT (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
               ((NVL(vsusasaldocontacorrentedescfin, 'N')) = 'S') THEN
              SELECT COUNT(*)
                INTO vicontador
                FROM pcsaldorca
               WHERE codusur = vncodusur;

              IF vicontador = 0 THEN
                INSERT INTO pcsaldorca
                  (codusur, vlsaldo, vlsaldoant)
                VALUES
                  (vncodusur, 0, 0);
              END IF;

              SELECT NVL(vlsaldo, 0)
                INTO vnvlsaldo
                FROM pcsaldorca
               WHERE codusur = vncodusur
                 FOR UPDATE;

              --RBD10
              SELECT NVL(descmax, 0), NVL(fixo, 0)
                INTO vndescmax, vnfixo
                FROM pcparamsaldo
               WHERE ROWNUM = 1;

              vncreditosaldorca := 0;

              --alteração feita para evitar erro de divisor 0
              begin

                SELECT SUM(((((vndescmax - pcpedi.perdesc) / vnfixo -
                           tab.percacresc) / 100) * pcpedi.pvenda) -- Pablo 16/12/2009
                           * pcpedi.qt)
                  INTO vncreditosaldorca
                  FROM pcpedi,
                       (SELECT pcfaixadesc.percacresc,
                               pcfaixadesc.percinicio,
                               pcfaixadesc.percfim
                          FROM pcfaixadesc) tab
                 WHERE pcpedi.numped = vnnumped
                   AND pcpedi.qt > 0
                   AND pcpedi.perdesc BETWEEN tab.percinicio AND
                       tab.percfim;
              exception
                when others then
                  vncreditosaldorca := 0;

              end;

              IF NVL(vncreditosaldorca, 0) < 0 THEN
                vncreditosaldorca := 0;
              END IF;

              INSERT INTO pcmovsaldorca
                (DATA,
                 codfunc,
                 codusur,
                 rotina,
                 tipo,
                 valor,
                 vlsaldoant,
                 vlsaldo,
                 historico,
                 numtransvenda)
              VALUES
                (SYSDATE,
                 p_codfunclanc,
                 vncodusur,
                 p_rotinalanc,
                 'C',
                 NVL(vncreditosaldorca, 0),
                 vnvlsaldo,
                 (vnvlsaldo + NVL(vncreditosaldorca, 0)),
                 'MOVIMENTO CARGA',
                 reg.numtransvenda);

              UPDATE pcsaldorca
                 SET vlsaldoant = vnvlsaldo,
                     vlsaldo    = (vnvlsaldo + NVL(vncreditosaldorca, 0))
               WHERE codusur = vncodusur;

              /*MED-2277*/
              BEGIN
                UPDATE PCNFSAIDPREFAT
                   SET dtfechaccrca = SYSDATE
                 WHERE numtransvenda = reg.numtransvenda;
              exception
                when others then
                  UPDATE PCNFSAID
                     SET dtfechaccrca = SYSDATE
                   WHERE numtransvenda = reg.numtransvenda;
              END;

              vbvalido := TRUE;
            END IF;
          END IF;
        END IF;
      END LOOP;
    END IF;

    p_mensagem := vsmensagem;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao lancar movimento carga.' || SQLCODE || ' ' ||
                    SQLERRM;
  END; --ccfinrca_lanca_movimento_Carga

  PROCEDURE ccfinrca_lanca_movimento_caixa(p_codfunclanc     IN pclogrca.codfunc%TYPE,
                                           p_rotinalanc      IN pclogrca.rotina%TYPE,
                                           p_numcheckout     IN pcpedc.numcaixa%TYPE,
                                           p_codfunccheckout IN PCNFSAIDPREFAT.codfunclanc%TYPE,
                                           p_dataemissao     IN DATE,
                                           p_mensagem        OUT VARCHAR2) IS
    vbvalido                       BOOLEAN;
    vsmensagem                     VARCHAR2(300);
    vncodusur                      pcpedc.codusur%TYPE;
    vncondvenda                    pcpedc.condvenda%TYPE;
    vsusasaldocontacorrentedescfin pcpedc.usasaldocontacorrentedescfin%TYPE;
    vstipomovccrca                 pcpedc.tipomovccrca%TYPE;
    vnperdescfin                   pcpedc.perdescfin%TYPE;
    vscodfilial                    pcpedc.codfilial%TYPE;
    vnnumped                       pcpedc.numped%TYPE;
    vicontador                     NUMBER;
    vnvlsaldo                      NUMBER;
    vndescmax                      NUMBER;
    vnfixo                         NUMBER;
    vncreditosaldorca              NUMBER;

  BEGIN
    vsmensagem := 'OK';

    FOR reg IN (SELECT numtransvenda, dtfechaccrca
                  FROM PCNFSAIDPREFAT
                 WHERE caixa = p_numcheckout
                   AND codemitente = p_codfunccheckout
                   AND dtsaida = p_dataemissao
                      --Tarefa 105946
                   AND EXISTS
                 (select pcpedc.numtransvenda
                          from pcpedc
                         where pcpedc.numtransvenda = PCNFSAIDPREFAT.numtransvenda)
                   AND PCNFSAIDPREFAT.dtcancel is null
                /*MED-2277*/
                UNION
                SELECT numtransvenda, dtfechaccrca
                  FROM PCNFSAID
                 WHERE caixa = p_numcheckout
                   AND codemitente = p_codfunccheckout
                   AND dtsaida = p_dataemissao
                      --Tarefa 105946
                   AND EXISTS
                 (select pcpedc.numtransvenda
                          from pcpedc
                         where pcpedc.numtransvenda = PCNFSAID.numtransvenda)
                   AND PCNFSAID.dtcancel is null
                ) LOOP
      vbvalido := ccrca_verificar_fechamento(reg.numtransvenda);

      IF vbvalido = TRUE THEN
        IF reg.dtfechaccrca IS NULL THEN
          SELECT PCNFSAIDPREFAT.codusur,
                 pcpedc.condvenda,
                 pcpedc.usasaldocontacorrentedescfin,
                 pcpedc.tipomovccrca,
                 pcpedc.perdescfin,
                 pcpedc.codfilial,
                 pcpedc.numped
            INTO vncodusur,
                 vncondvenda,
                 vsusasaldocontacorrentedescfin,
                 vstipomovccrca,
                 vnperdescfin,
                 vscodfilial,
                 vnnumped
            FROM pcpedc, PCNFSAIDPREFAT
           WHERE pcpedc.numped = PCNFSAIDPREFAT.numped
             AND PCNFSAIDPREFAT.numtransvenda = reg.numtransvenda;

          /*MED-2277*/
          IF NVL(vncodusur,0) = 0 THEN
            SELECT PCNFSAID.codusur,
                   pcpedc.condvenda,
                   pcpedc.usasaldocontacorrentedescfin,
                   pcpedc.tipomovccrca,
                   pcpedc.perdescfin,
                   pcpedc.codfilial,
                   pcpedc.numped
              INTO vncodusur,
                   vncondvenda,
                   vsusasaldocontacorrentedescfin,
                   vstipomovccrca,
                   vnperdescfin,
                   vscodfilial,
                   vnnumped
              FROM pcpedc, PCNFSAID
             WHERE pcpedc.numped = PCNFSAID.numped
               AND PCNFSAID.numtransvenda = reg.numtransvenda;
          END IF;

          -- HIS.00632.2016
          vncodusur := ObterRcaContaCorrente(vncodusur, -- RCA que já estava buscando no Pedido
                                             vnnumped);

          -- Tarefa 99976
          IF (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
             (NVL(vsusasaldocontacorrentedescfin, 'N') = 'S') THEN
            vbvalido := TRUE;
          END IF;
          -- Fim tarefa 99976

          IF NOT (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
             ((NVL(vsusasaldocontacorrentedescfin, 'N')) = 'S') THEN
            SELECT COUNT(*)
              INTO vicontador
              FROM pcsaldorca
             WHERE codusur = vncodusur;

            IF vicontador = 0 THEN
              INSERT INTO pcsaldorca
                (codusur, vlsaldo, vlsaldoant)
              VALUES
                (vncodusur, 0, 0);
            END IF;

            SELECT NVL(vlsaldo, 0)
              INTO vnvlsaldo
              FROM pcsaldorca
             WHERE codusur = vncodusur
               FOR UPDATE;

            --RBD10
            SELECT NVL(descmax, 0), NVL(fixo, 0)
              INTO vndescmax, vnfixo
              FROM pcparamsaldo
             WHERE ROWNUM = 1;

            vncreditosaldorca := 0;

            --alteração feita para evitar erro de divisor 0
            begin

              SELECT SUM(((((vndescmax - pcpedi.perdesc) / vnfixo -
                         tab.percacresc) / 100) * pcpedi.pvenda) -- Pablo 16/12/2009
                         * pcpedi.qt)
                INTO vncreditosaldorca
                FROM pcpedi,
                     (SELECT pcfaixadesc.percacresc,
                             pcfaixadesc.percinicio,
                             pcfaixadesc.percfim
                        FROM pcfaixadesc) tab
               WHERE pcpedi.numped = vnnumped
                 AND pcpedi.qt > 0
                 AND pcpedi.perdesc BETWEEN tab.percinicio AND tab.percfim;

            exception
              when others then
                vncreditosaldorca := 0;

            end;

            IF NVL(vncreditosaldorca, 0) < 0 THEN
              vncreditosaldorca := 0;
            END IF;

            INSERT INTO pcmovsaldorca
              (DATA,
               codfunc,
               codusur,
               rotina,
               tipo,
               valor,
               vlsaldoant,
               vlsaldo,
               historico,
               numtransvenda)
            VALUES
              (SYSDATE,
               p_codfunclanc,
               vncodusur,
               p_rotinalanc,
               'C',
               NVL(vncreditosaldorca, 0),
               vnvlsaldo,
               (vnvlsaldo + NVL(vncreditosaldorca, 0)),
               'MOVIMENTO CARGA',
               reg.numtransvenda);

            UPDATE pcsaldorca
               SET vlsaldoant = vnvlsaldo,
                   vlsaldo    = (vnvlsaldo + NVL(vncreditosaldorca, 0))
             WHERE codusur = vncodusur;

            /*MED-2277*/
            BEGIN
              UPDATE PCNFSAIDPREFAT
                 SET dtfechaccrca = SYSDATE
               WHERE numtransvenda = reg.numtransvenda;
            exception
              when others then
                UPDATE PCNFSAID
                   SET dtfechaccrca = SYSDATE
                 WHERE numtransvenda = reg.numtransvenda;
            END;

            vbvalido := TRUE;
          END IF;
        END IF;
      END IF;
    END LOOP;

    p_mensagem := vsmensagem;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao lancar movimento caixa.' || SQLCODE || ' ' ||
                    SQLERRM;
  END; --ccfinrca_lanca_movimento_caixa

  --Projeto 90992 - RBD15
  FUNCTION ccfinrca_devolve_notafiscal(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                       p_rotinalanc  IN pclogrca.rotina%TYPE,
                                       p_codusur     IN pcnfent.codusurdevol%TYPE,
                                       p_numtransent IN pcnfent.numtransent%TYPE,
                                       p_mensagem    OUT VARCHAR2)
    RETURN BOOLEAN IS
    vsmanterdebitodescfin          pctabdev.manterdebitodescfin%TYPE;
    vsmantercredito                pctabdev.mantercredito%TYPE;
    vnnumped                       pcpedc.numped%TYPE;
    vstipomovccrca                 pcpedc.tipomovccrca%TYPE;
    vncondvenda                    pcpedc.condvenda%TYPE;
    vsusasaldocontacorrentedescfin pcpedc.usasaldocontacorrentedescfin%TYPE;
    vnperdescfin                   pcpedc.perdescfin%TYPE;
    vncodusur                      pcpedc.codusur%TYPE;
    vnnumtransvenda                pcpedc.numtransvenda%TYPE;
    vicontador                     NUMBER;
    vnvlsaldo                      NUMBER;
    vncreditosaldorca              NUMBER;
    vndebitosaldorca               NUMBER;
    vbvalido                       BOOLEAN;
    vsmensagem                     VARCHAR2(300);
    vbnotaacertada                 BOOLEAN;
    vndescmax                      NUMBER;
    vnfixo                         NUMBER;
  BEGIN
    vbvalido   := FALSE;
    vsmensagem := 'OK';

    SELECT NVL(manterdebitodescfin, 'N'), NVL(mantercredito, 'N')
      INTO vsmanterdebitodescfin, vsmantercredito
      FROM pctabdev, pcnfent
     WHERE pctabdev.coddevol = pcnfent.coddevol
       AND pcnfent.numtransent = p_numtransent;

    SELECT pcpedc.numped,
           pcpedc.tipomovccrca,
           pcpedc.condvenda,
           pcpedc.usasaldocontacorrentedescfin,
           pcpedc.perdescfin,
           pcpedc.codusur,
           pcnfsaid.numtransvenda
      INTO vnnumped,
           vstipomovccrca,
           vncondvenda,
           vsusasaldocontacorrentedescfin,
           vnperdescfin,
           vncodusur,
           vnnumtransvenda
      FROM pcpedc, pcnfsaid, pcnfent, pcestcom
     WHERE pcestcom.numtransent = p_numtransent
       AND pcestcom.numtransent = pcnfent.numtransent --Correcao em 11/12/2009
       AND pcestcom.numtransvenda = pcnfsaid.numtransvenda
       AND pcnfsaid.numped = pcpedc.numped;

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(vncodusur, -- RCA que já estava buscando no Pedido
                                       vnnumped);

    -- Tarefa 99976
    IF (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
       (NVL(vsusasaldocontacorrentedescfin, 'N') = 'S') THEN
      vbvalido := TRUE;
    END IF;
    -- Fim tarefa 99976

    IF vsmanterdebitodescfin = 'N' THEN
      IF NOT (vncondvenda IN (4, 5, 8, 11, 13, 20)) AND
         (NVL(vsusasaldocontacorrentedescfin, 'N') = 'S') THEN
        IF NVL(vnperdescfin, 0) > 0 THEN
          --RBD11
          SELECT COUNT(*)
            INTO vicontador
            FROM pcsaldorca
           WHERE codusur = vncodusur;

          IF vicontador = 0 THEN
            INSERT INTO pcsaldorca
              (codusur, vlsaldo, vlsaldoant)
            VALUES
              (vncodusur, 0, 0);
          END IF;

          SELECT NVL(vlsaldo, 0)
            INTO vnvlsaldo
            FROM pcsaldorca
           WHERE codusur = vncodusur
             FOR UPDATE;

          vncreditosaldorca := 0;

          SELECT (SUM(NVL(pcmov.punit, 0) * NVL(pcmov.qt, 0))) *
                 (vnperdescfin) / 100
            INTO vncreditosaldorca
            FROM pcmov
           WHERE numtransent = p_numtransent
             AND NVL(qt, 0) > 0;

          IF NVL(vncreditosaldorca, 0) < 0 THEN
            vncreditosaldorca := 0;
          END IF;

          INSERT INTO pcmovsaldorca
            (DATA,
             codfunc,
             codusur,
             rotina,
             tipo,
             valor,
             vlsaldoant,
             vlsaldo,
             historico,
             numtransent,
             numped)
          VALUES
            (SYSDATE,
             p_codfunclanc,
             vncodusur,
             p_rotinalanc,
             'C',
             NVL(vncreditosaldorca, 0),
             vnvlsaldo,
             (vnvlsaldo + NVL(vncreditosaldorca, 0)),
             'DEVOLUCAO CLIENTE',
             p_numtransent,
             vnnumped);

          UPDATE pcsaldorca
             SET vlsaldoant = vnvlsaldo,
                 vlsaldo    = (vnvlsaldo + NVL(vncreditosaldorca, 0))
           WHERE codusur = vncodusur;

          vbvalido := TRUE;
        END IF;
      END IF;
    END IF;

    IF vsmantercredito = 'N' THEN
      IF (NVL(vstipomovccrca, 'VV') = 'VA') THEN
        vbnotaacertada := ccrca_verificar_fechamento(vnnumtransvenda);
      END IF;

      IF vbnotaacertada = TRUE OR (NVL(vstipomovccrca, 'VV') <> 'VA') THEN
        --RBD10
        SELECT COUNT(*)
          INTO vicontador
          FROM pcsaldorca
         WHERE codusur = vncodusur;

        IF vicontador = 0 THEN
          INSERT INTO pcsaldorca
            (codusur, vlsaldo, vlsaldoant)
          VALUES
            (vncodusur, 0, 0);
        END IF;

        SELECT NVL(vlsaldo, 0)
          INTO vnvlsaldo
          FROM pcsaldorca
         WHERE codusur = vncodusur
           FOR UPDATE;

        SELECT NVL(descmax, 0), NVL(fixo, 0)
          INTO vndescmax, vnfixo
          FROM pcparamsaldo
         WHERE ROWNUM = 1;

        vndebitosaldorca := 0;

        --alteração feita para evitar erro de divisor 0
        begin

          SELECT SUM(((((vndescmax - pcmov.percdesc) / vnfixo -
                     tab.percacresc) / 100) * pcmov.punit) -- Pablo 16/12/2009
                     * pcmov.qt)
            INTO vndebitosaldorca
            FROM pcmov,
                 (SELECT pcfaixadesc.percacresc,
                         pcfaixadesc.percinicio,
                         pcfaixadesc.percfim
                    FROM pcfaixadesc) tab
           WHERE pcmov.numtransent = p_numtransent
             AND pcmov.qt > 0
             AND pcmov.percdesc BETWEEN tab.percinicio AND tab.percfim;

        exception
          when others then
            vndebitosaldorca := 0;

        end;

        IF NVL(vndebitosaldorca, 0) < 0 THEN
          vndebitosaldorca := 0;
        END IF;

        INSERT INTO pcmovsaldorca
          (DATA,
           codfunc,
           codusur,
           rotina,
           tipo,
           valor,
           vlsaldoant,
           vlsaldo,
           historico,
           numtransent)
        VALUES
          (SYSDATE,
           p_codfunclanc,
           vncodusur,
           p_rotinalanc,
           'D',
           NVL(vndebitosaldorca, 0) * (-1),
           vnvlsaldo,
           (vnvlsaldo - NVL(vndebitosaldorca, 0)),
           'DEVOLUCAO CLIENTE',
           p_numtransent);

        UPDATE pcsaldorca
           SET vlsaldoant = vnvlsaldo,
               vlsaldo    = (vnvlsaldo - NVL(vndebitosaldorca, 0))
         WHERE codusur = vncodusur;

        vbvalido := TRUE;
      END IF;
    END IF;

    p_mensagem := vsmensagem;
    RETURN vbvalido;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao devolver Nota Fiscal : ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END; --ccfinrca_devolve_notafiscal

  --Projeto 90992 - RBD16
  FUNCTION ccfinrca_cancela_devolucao(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                      p_rotinalanc  IN pclogrca.rotina%TYPE,
                                      p_codusur     IN pcnfent.codusurdevol%TYPE,
                                      p_numtransent IN pcnfent.numtransent%TYPE,
                                      p_mensagem    OUT VARCHAR2)
    RETURN BOOLEAN IS
    vbvalido                       BOOLEAN;
    vsmensagem                     VARCHAR2(300);
    vnnumped                       pcpedc.numped%TYPE;
    vstipomovccrca                 pcpedc.tipomovccrca%TYPE;
    vncondvenda                    pcpedc.condvenda%TYPE;
    vsusasaldocontacorrentedescfin pcpedc.usasaldocontacorrentedescfin%TYPE;
    vnperdescfin                   pcpedc.perdescfin%TYPE;
    vncodusur                      pcpedc.codusur%TYPE;
    vnnumtransvenda                pcnfsaid.numtransvenda%TYPE;
    vicontador                     NUMBER;
    vnvalor                        NUMBER;
    vnvlsaldo                      NUMBER;
    vnvalordebito                  NUMBER;
    vnvalorcredito                 NUMBER;
  BEGIN
    vbvalido   := TRUE;
    vsmensagem := 'OK';

    SELECT pcpedc.numped,
           pcpedc.tipomovccrca,
           pcpedc.condvenda,
           pcpedc.usasaldocontacorrentedescfin,
           pcpedc.perdescfin,
           pcpedc.codusur,
           pcnfsaid.numtransvenda
      INTO vnnumped,
           vstipomovccrca,
           vncondvenda,
           vsusasaldocontacorrentedescfin,
           vnperdescfin,
           vncodusur,
           vnnumtransvenda
      FROM pcpedc, pcnfsaid, pcnfent, pcestcom
     WHERE pcestcom.numtransent = p_numtransent
       AND pcestcom.numtransent = pcnfent.numtransent
       AND pcestcom.numtransvenda = pcnfsaid.numtransvenda
       AND pcnfsaid.numped = pcpedc.numped;

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(vncodusur, -- RCA que já estava buscando no Pedido
                                       vnnumped);

    SELECT COUNT(*)
      INTO vicontador
      FROM pcmovsaldorca
     WHERE numtransent = p_numtransent
       AND tipo = 'C';

    IF vicontador <> 0 THEN
      SELECT valor
        INTO vnvalor
        FROM pcmovsaldorca
       WHERE numtransent = p_numtransent
         AND tipo = 'C';

      SELECT COUNT(*)
        INTO vicontador
        FROM pcsaldorca
       WHERE codusur = vncodusur;

      IF vicontador = 0 THEN
        INSERT INTO pcsaldorca
          (codusur, vlsaldo, vlsaldoant)
        VALUES
          (vncodusur, 0, 0);
      END IF;

      SELECT NVL(vlsaldo, 0)
        INTO vnvlsaldo
        FROM pcsaldorca
       WHERE codusur = vncodusur
         FOR UPDATE;

      vnvalordebito := vnvalor * (-1);

      INSERT INTO pcmovsaldorca
        (DATA,
         codfunc,
         codusur,
         rotina,
         tipo,
         valor,
         vlsaldoant,
         vlsaldo,
         historico,
         numtransent)
      VALUES
        (SYSDATE,
         p_codfunclanc,
         vncodusur,
         p_rotinalanc,
         'D',
         vnvalordebito,
         vnvlsaldo,
         (vnvlsaldo + (vnvalordebito)),
         'CANCELAMENTO DEV. CLIENTE',
         p_numtransent);

      UPDATE pcsaldorca
         SET vlsaldoant = vnvlsaldo,
             vlsaldo    = (vnvlsaldo + (vnvalordebito))
       WHERE codusur = vncodusur;
    END IF;

    SELECT COUNT(*)
      INTO vicontador
      FROM pcmovsaldorca
     WHERE numtransent = p_numtransent
       AND tipo = 'D'
       and rotina <> p_rotinalanc;

    IF vicontador <> 0 THEN
      SELECT valor
        INTO vnvalor
        FROM pcmovsaldorca
       WHERE numtransent = p_numtransent
         AND tipo = 'D'
         and rotina <> p_rotinalanc;

      SELECT NVL(vlsaldo, 0)
        INTO vnvlsaldo
        FROM pcsaldorca
       WHERE codusur = vncodusur
         FOR UPDATE;

      vnvalordebito := vnvalor * (-1);

      INSERT INTO pcmovsaldorca
        (DATA,
         codfunc,
         codusur,
         rotina,
         tipo,
         valor,
         vlsaldoant,
         vlsaldo,
         historico,
         numtransent)
      VALUES
        (SYSDATE,
         p_codfunclanc,
         vncodusur,
         p_rotinalanc,
         'C',
         vnvalordebito,
         vnvlsaldo,
         (vnvlsaldo + (vnvalordebito)),
         'CANCELAMENTO DEV. CLIENTE',
         p_numtransent);

      UPDATE pcsaldorca
         SET vlsaldoant = vnvlsaldo,
             vlsaldo    = (vnvlsaldo + (vnvalordebito))
       WHERE codusur = vncodusur;
    END IF;

    p_mensagem := vsmensagem;
    RETURN vbvalido;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao cancelar devolucao : ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END; -- ccfinrca_cancela_devolucao

  --RNG10
  FUNCTION ccrca_excluir_item_pedido(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                     p_rotinalanc  IN pclogrca.rotina%TYPE,
                                     p_codusur     IN pcpedc.codusur%TYPE,
                                     p_numped      IN pcpedc.numped%TYPE,
                                     p_codprod     IN pcpedi.codprod%TYPE,
                                     p_numseq      IN pcpedi.numseq%TYPE,
                                     p_qtanterior  IN NUMBER) RETURN BOOLEAN IS
    vbvalido BOOLEAN;
  BEGIN
    vbvalido := FALSE;
    vbvalido := ccrca_estorna_item_pedido(p_codfunclanc,
                                          p_rotinalanc,
                                          p_codusur,
                                          p_numped,
                                          p_codprod,
                                          p_numseq,
                                          p_qtanterior);
    RETURN(vbvalido);
  END; --ccrca_excluir_item_pedido

  --RNG11
  FUNCTION ccrca_alterar_preco_qt(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                  p_rotinalanc  IN pclogrca.rotina%TYPE,
                                  p_codusur     IN pcpedc.codusur%TYPE,
                                  p_numped      IN pcpedc.numped%TYPE,
                                  p_codprod     IN pcpedi.codprod%TYPE,
                                  p_numseq      IN pcpedi.numseq%TYPE,
                                  p_qtanterior  IN NUMBER) RETURN BOOLEAN IS
    vnqt     pcpedi.qt%TYPE;
    vbvalido BOOLEAN;
  BEGIN
    vbvalido := FALSE;

    SELECT qt
      INTO vnqt
      FROM pcpedi
     WHERE numped = p_numped
       AND codprod = p_codprod
       AND numseq = p_numseq;

    IF vnqt > 0 THEN
      if p_rotinalanc <> 1401 then
        vbvalido := ccrca_estorna_item_pedido(p_codfunclanc,
                                              p_rotinalanc,
                                              p_codusur,
                                              p_numped,
                                              p_codprod,
                                              p_numseq,
                                              p_qtanterior);
      end if;
      vbvalido := ccrca_incluir_item_pedido(p_codfunclanc,
                                            p_rotinalanc,
                                            p_codusur,
                                            p_numped,
                                            p_codprod,
                                            p_numseq);
    END IF;

    IF vnqt = 0 THEN
      vbvalido := ccrca_excluir_item_pedido(p_codfunclanc,
                                            p_rotinalanc,
                                            p_codusur,
                                            p_numped,
                                            p_codprod,
                                            p_numseq,
                                            p_qtanterior);
    END IF;

    RETURN(vbvalido);
  END; --ccrca_alterar_preco_qt

  FUNCTION ccrca_alterar_preco(p_codfunclanc      IN pclogrca.codfunc%TYPE,
                               p_rotinalanc       IN pclogrca.rotina%TYPE,
                               p_codusur          IN pcpedc.codusur%TYPE,
                               p_numped           IN pcpedc.numped%TYPE,
                               p_codprod          IN pcpedi.codprod%TYPE,
                               p_numseq           IN pcpedi.numseq%TYPE,
                               p_qtanterior       IN NUMBER,
                               p_pvendaanterior   IN NUMBER,
                               p_pbasercaanterior IN NUMBER,
                               p_ptabelaanterior  IN NUMBER) RETURN BOOLEAN IS
    vnqt                 pcpedi.qt%TYPE;
    vsusadebcredrcabrind pcpedi.usadebcredrcabrind%TYPE;
    vbvalido             BOOLEAN;
    vnvalorlanc          NUMBER;
    vnvlcorrente_ant     pcusuari.vlcorrente%TYPE;
    vsusadebcredrca      pcusuari.usadebcredrca%TYPE;
    vnvllimcred          pcusuari.vllimcred%TYPE;
    vnvlcorrente_atual   pcusuari.vlcorrente%TYPE;
    vddata               pcpedc.DATA%TYPE;
    vnnumtransvenda      pcpedc.numtransvenda%TYPE;
    vsposicao            pcpedc.posicao%TYPE;
    -- Log
    TYPE TRecItem                   IS RECORD(
         nPVENDA                    PCLOGRCA.PVENDA%TYPE,
         nST                        PCLOGRCA.ST%TYPE,
         nPBASERCA                  PCLOGRCA.PBASERCA%TYPE,
         nSTPBASERCA                PCLOGRCA.STPBASERCA%TYPE,
         nPTABELA                   PCLOGRCA.PTABELA%TYPE,
         nSTPTABELA                 PCLOGRCA.STPTABELA%TYPE,
         nBONIFIC                   PCLOGRCA.BONIFIC%TYPE,
         nQT                        PCLOGRCA.QT%TYPE,
         vUSADEBCREDRCABRIND        PCLOGRCA.USADEBCREDRCABRIND%TYPE,
         vMOVIMENTACONTACORRENTERCA PCLOGRCA.MOVIMENTACONTACORRENTERCA%TYPE,
         nCODPROMOCAOMED            PCLOGRCA.CODPROMOCAOMED%TYPE,
         nVLUNITLIMCREDRCAUTILIZMED PCPEDI.VLUNITLIMCREDRCAUTILIZMED%TYPE); -- 4954.001502.2017;
    vrItem                          TRecItem;
    -- HIS.00632.2016
    vncodusur                       pcpedc.codusur%type;
    -- LIMITE_FLEX
    vvtipomovccrca                  pcpedc.tipomovccrca%type;
    vnvllimcred_atual               pcusuari.vllimcred%type;
  BEGIN
    vbvalido := FALSE;

    -------------------------------------------------------------------------------------------------
    -- HIS.00065.2018 - Se usar o saldo C/C somente no próprio pedido, não acumula o Saldo C/C no RCA
    -------------------------------------------------------------------------------------------------
    IF (F_USARSALDORCASOMENTENOPEDIDO) THEN
      RETURN TRUE;
    END IF;

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(p_codusur,
                                       p_numped);

    SELECT qt, NVL(usadebcredrcabrind, 'N')
      INTO vnqt, vsusadebcredrcabrind
      FROM pcpedi
     WHERE numped = p_numped
       AND codprod = p_codprod
       AND numseq = p_numseq;

    IF vnqt > 0 THEN

      SELECT pcpedc.DATA, pcpedc.numtransvenda, pcpedc.posicao, pcpedc.tipomovccrca
        INTO vddata, vnnumtransvenda, vsposicao, vvtipomovccrca
        FROM pcpedc
       WHERE numped = p_numped;

      ---------------------------------------------------------------------------------
      -- HIS.00052.2017 - Força encerrar o processo se Débito e Crédito no Faturamento,
      -- movimentando o conta corrente do RCA por Pedido no Faturamento
      ---------------------------------------------------------------------------------
      IF (vvtipomovccrca = 'FF') AND
         (F_MOVSALDORCAPORPEDIDOFAT) THEN
        RETURN(TRUE);
      END IF;
      ---------------------------------------------------------------------------------

      SELECT pcusuari.usadebcredrca,
             pcusuari.vlcorrente,
             pcusuari.vllimcred
        INTO vsusadebcredrca, vnvlcorrente_ant, vnvllimcred
        FROM pcusuari
       WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;

      BEGIN
        SELECT PVENDA
             , ST
             , PBASERCA
             , STPBASERCA
             , PTABELA
             , STPTABELA
             , BONIFIC
             , QT
             , USADEBCREDRCABRIND
             , MOVIMENTACONTACORRENTERCA
             , CODPROMOCAOMED
             , VLUNITLIMCREDRCAUTILIZMED -- 4954.001502.2017
          INTO vrItem.nPVENDA
             , vrItem.nST
             , vrItem.nPBASERCA
             , vrItem.nSTPBASERCA
             , vrItem.nPTABELA
             , vrItem.nSTPTABELA
             , vrItem.nBONIFIC
             , vrItem.nQT
             , vrItem.vUSADEBCREDRCABRIND
             , vrItem.vMOVIMENTACONTACORRENTERCA
             , vrItem.nCODPROMOCAOMED
             , vrItem.nVLUNITLIMCREDRCAUTILIZMED -- 4954.001502.2017
          FROM PCPEDI
         WHERE (NUMPED  = p_numped)
           AND (CODPROD = p_codprod)
           AND (NUMSEQ  = p_numseq);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vrItem.nPVENDA                    := NULL;
          vrItem.nST                        := NULL;
          vrItem.nPBASERCA                  := NULL;
          vrItem.nSTPBASERCA                := NULL;
          vrItem.nPTABELA                   := NULL;
          vrItem.nSTPTABELA                 := NULL;
          vrItem.nBONIFIC                   := 'N';
          vrItem.nQT                        := NULL;
          vrItem.vUSADEBCREDRCABRIND        := NULL;
          vrItem.vMOVIMENTACONTACORRENTERCA := NULL;
          vrItem.nCODPROMOCAOMED            := NULL;
          vrItem.nVLUNITLIMCREDRCAUTILIZMED := NULL; -- 4954.001502.2017
      END;

      vnvalorlanc := ccrca_retorna_saldo_anterior(p_numped,
                                                  vncodusur, -- HIS.00632.2016 -- p_codusur,
                                                  p_codprod,
                                                  p_numseq,
                                                  p_qtanterior,
                                                  p_pvendaanterior,
                                                  p_pbasercaanterior,
                                                  p_ptabelaanterior,
                                                  'E',
                                                  vsusadebcredrcabrind);

      -- LIMITE_FLEX
      IF (NVL(vvtipomovccrca,' ') = 'LL') THEN

        -- Se Usou Limite
        IF (NVL(vrItem.nVLUNITLIMCREDRCAUTILIZMED,0) <> 0) THEN -- 4954.001502.2017

          -- Valor Utilizado do Limite de Crédito - 4954.001502.2017
          vnvalorlanc := NVL(vrItem.nVLUNITLIMCREDRCAUTILIZMED,0) * NVL(p_qtanterior,0);

          -- ( E - Estorno)
          vnvllimcred_atual := NVL(vnvllimcred, 0) + NVL(vnvalorlanc, 0);

          UPDATE pcusuari
             SET vllimcred = vnvllimcred_atual
           WHERE codusur = vncodusur;

          INSERT INTO pcloglimitecredrcamed
            (numped,
             posicao,
             numtransvenda,
             DATA,
             codfunc,
             codusur,
             rotina,
             vlcorrente,
             vllimcred,
             vlcorrenteant,
             vllimcredant,
             codprod,
             numseq,
             historico,
             PVENDA,
             ST,
             PBASERCA,
             STPBASERCA,
             PTABELA,
             STPTABELA,
             BONIFIC,
             QT,
             USADEBCREDRCABRIND,
             MOVIMENTACONTACORRENTERCA,
             CODPROMOCAOMED)
          VALUES
            (p_numped,
             vsposicao,
             vnnumtransvenda,
             SYSDATE,
             p_codfunclanc,
             vncodusur,
             p_rotinalanc,
             vnvlcorrente_ant,
             vnvllimcred_atual,
             vnvlcorrente_ant,
             vnvllimcred,
             p_codprod,
             p_numseq,
             SUBSTR('CTRLCCRCA AP.: ESTORNO DE SALDO DE ITEM PEDIDO', 1, 60),
             vrItem.nPVENDA,
             vrItem.nST,
             vrItem.nPBASERCA,
             vrItem.nSTPBASERCA,
             vrItem.nPTABELA,
             vrItem.nSTPTABELA,
             vrItem.nBONIFIC,
             vrItem.nQT,
             vrItem.vUSADEBCREDRCABRIND,
             vrItem.vMOVIMENTACONTACORRENTERCA,
             vrItem.nCODPROMOCAOMED);

        END IF; -- Fim: Se Usou Limite

      ELSE

        -- incluído por sabrina ( E - Estorno)
        vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) - NVL(vnvalorlanc, 0);

        -- a package não deve barrar a movimentacao do saldo, os programas eh que fazem isso
        --IF vnvlcorrente_atual >= 0 THEN
        UPDATE pcusuari
           SET vlcorrente = vnvlcorrente_atual
         WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;

        INSERT INTO pclogrca
          (numped,
           posicao,
           numtransvenda,
           DATA,
           codfunc,
           codusur,
           rotina,
           vlcorrente,
           vllimcred,
           vlcorrenteant,
           vllimcredant,
           codprod,
           numseq,
           historico,
           PVENDA,
           ST,
           PBASERCA,
           STPBASERCA,
           PTABELA,
           STPTABELA,
           BONIFIC,
           QT,
           USADEBCREDRCABRIND,
           MOVIMENTACONTACORRENTERCA,
           CODPROMOCAOMED)
        VALUES
          (p_numped,
           vsposicao,
           vnnumtransvenda,
           SYSDATE,
           p_codfunclanc,
           vncodusur, -- HIS.00632.2016 -- p_codusur,
           p_rotinalanc,
           vnvlcorrente_atual,
           vnvllimcred,
           vnvlcorrente_ant,
           vnvllimcred,
           p_codprod,
           p_numseq,
           SUBSTR('CTRLCCRCA AP.: ESTORNO DE SALDO DE ITEM PEDIDO', 1, 60),
           vrItem.nPVENDA,
           vrItem.nST,
           vrItem.nPBASERCA,
           vrItem.nSTPBASERCA,
           vrItem.nPTABELA,
           vrItem.nSTPTABELA,
           vrItem.nBONIFIC,
           vrItem.nQT,
           vrItem.vUSADEBCREDRCABRIND,
           vrItem.vMOVIMENTACONTACORRENTERCA,
           vrItem.nCODPROMOCAOMED);

        vbvalido := ccrca_incluir_item_pedido(p_codfunclanc,
                                              p_rotinalanc,
                                              vncodusur, -- HIS.00632.2016 -- p_codusur,
                                              p_numped,
                                              p_codprod,
                                              p_numseq);
      END IF;  -- FIM: LIMITE_FLEX

    END IF; -- (vnqt > 0)

    IF vnqt = 0 THEN
      vbvalido := ccrca_excluir_item_pedido(p_codfunclanc,
                                            p_rotinalanc,
                                            vncodusur, -- HIS.00632.2016 -- p_codusur,
                                            p_numped,
                                            p_codprod,
                                            p_numseq,
                                            p_qtanterior);
    END IF;

    RETURN(vbvalido);

  END; --ccrca_alterar_preco

  --RNG12
  FUNCTION ccrca_retornar_saldo_item_nf(p_numtransvenda IN PCMOVPREFAT.numtransvenda%TYPE,
                                        p_codprod       IN PCMOVPREFAT.codprod%TYPE,
                                        p_numseq        IN PCMOVPREFAT.numseq%TYPE,
                                        p_qt            IN NUMBER,
                                        p_tipo          IN VARCHAR, -- Sabrina : tipo de operação I - Inclusao e E - Exclusao
                                                                    -- Anderson: tipo de operação L - Liquidez (HIS.01108.2016 - Crédito do Conta Corrente por Liquidez)
                                        p_rotina                      IN pclogrca.rotina%TYPE DEFAULT 0,
                                        p_percrateiocredrcasupervisor IN pclogrca.percrateiocredrcasupervisor%TYPE DEFAULT 0)

   RETURN NUMBER IS
    vnvalorlanc                 NUMBER;
    vstipo                      VARCHAR2(1);
    vnnumped                    pcpedc.numped%TYPE;
    vncodusur                   pcpedc.codusur%TYPE;
    vsusacredrca                pcpedc.usacredrca%TYPE;
    vsbonificaltdebcredrca      pcpedc.bonificaltdebcredrca%TYPE;
    vstrocaaltdebcredrca        pcpedc.trocaaltdebcredrca%TYPE;
    vsbrokeraltdebcredrca       pcpedc.brokeraltdebcredrca%TYPE;
    vscrmaltdebcredrca          pcpedc.crmaltdebcredrca%TYPE;
    vstipomovccrca              pcpedc.tipomovccrca%TYPE;
    vsusadebcredrca             pcpedc.usadebcredrca%TYPE;
    vsorigemped                 pcpedc.origemped%TYPE;
    vsbrinde                    pcpedc.brinde%TYPE;
    vncondvenda                 pcpedc.condvenda%TYPE;
    vsbroker                    pcpedc.broker%TYPE;
    vsusadebcredrca_rca         pcusuari.usadebcredrca%TYPE;
    vnpunit                     PCMOVPREFAT.punit%TYPE;
    vnptabela                   PCMOVPREFAT.ptabela%TYPE;
    vnpbaserca                  PCMOVPREFAT.pbaserca%TYPE;
    vsusadebcredrcabrind        PCMOVPREFAT.usadebcredrcabrind%TYPE;
    vnstpvenda                  PCMOVPREFAT.st%TYPE;
    vnstptabela                 PCMOVCOMPLEPREFAT.stptabela%TYPE;
    vnstpbaserca                PCMOVCOMPLEPREFAT.stpbaserca%TYPE;
    vsmsg                       VARCHAR2(400);
    vbfechado                   BOOLEAN;
    vsmovimentacontacorrenterca PCMOVPREFAT.movimentacontacorrenterca%type;
    -- CC_ITEMBNF
    vsbonific                   PCMOVCOMPLEPREFAT.BONIFIC%TYPE;
    -- DDVENDAS-41579
    vsItemBrinde                pcpedi.brinde%TYPE;    
  BEGIN
    proc_lerparametros(vsmsg);
 
    -- MED-2359
    BEGIN 
      SELECT DISTINCT numped
        INTO vnnumped
        FROM PCNFSAIDPREFAT
       WHERE numtransvenda = p_numtransvenda;
    EXCEPTION
      -- MED-2359
      WHEN NO_DATA_FOUND THEN
        vnnumped := 0;      
    END;       

   /*MED-2277*/
   IF NVL(vnnumped,0) = 0 THEN
     SELECT DISTINCT numped
       INTO vnnumped
       FROM PCNFSAID
      WHERE numtransvenda = p_numtransvenda;
   END IF;

    SELECT p.usacredrca,
           p.bonificaltdebcredrca,
           p.trocaaltdebcredrca,
           p.brokeraltdebcredrca,
           p.crmaltdebcredrca,
           p.tipomovccrca,
           DECODE(p.usadebcredrca,
                  NULL,
                  (SELECT NVL(pcusuari.usadebcredrca, gregpcconsum.usacredrca)
                     FROM pcusuari
                    WHERE codusur = p.codusur
                      AND ROWNUM = 1),
                  p.usadebcredrca),
           p.origemped,
           p.brinde,
           p.condvenda,
           p.broker,
           p.codusur
      INTO vsusacredrca,
           vsbonificaltdebcredrca,
           vstrocaaltdebcredrca,
           vsbrokeraltdebcredrca,
           vscrmaltdebcredrca,
           vstipomovccrca,
           vsusadebcredrca,
           vsorigemped,
           vsbrinde,
           vncondvenda,
           vsbroker,
           vncodusur
      FROM pcpedc p
     WHERE p.numped = vnnumped;

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(vncodusur, -- RCA que já estava buscando no Pedido
                                       vnnumped);

    SELECT pcusuari.usadebcredrca
      INTO vsusadebcredrca_rca
      FROM pcusuari
     WHERE codusur = vncodusur;

    -- MED-2347 - Tratamento para Transferências de RCA do Pedido
    BEGIN
      SELECT decode(nvl(PCMOVCOMPLEPREFAT.bonific, 'N'),'F',PCMOVPREFAT.punitcont,PCMOVPREFAT.punit),
             PCMOVPREFAT.pbaserca,
             PCMOVPREFAT.ptabela,
             NVL(PCMOVPREFAT.usadebcredrcabrind, 'N'),
             nvl(PCMOVPREFAT.movimentacontacorrenterca,'S'),
             NVL(PCMOVPREFAT.st,0),
             NVL(PCMOVCOMPLEPREFAT.stptabela,0),
             NVL(PCMOVCOMPLEPREFAT.stpbaserca,0),
             nvl(PCMOVCOMPLEPREFAT.bonific, 'N') bonific -- CC_ITEMBNF
        INTO vnpunit,
             vnpbaserca,
             vnptabela,
             vsusadebcredrcabrind,
             vsmovimentacontacorrenterca,
             vnstpvenda,
             vnstptabela,
             vnstpbaserca,
             vsbonific -- CC_ITEMBNF
        FROM PCMOVPREFAT, PCMOVCOMPLEPREFAT
       WHERE PCMOVPREFAT.numtransvenda = p_numtransvenda
         AND PCMOVPREFAT.codprod = p_codprod
         AND PCMOVPREFAT.numseq = p_numseq
         AND PCMOVPREFAT.qt > 0
         and PCMOVPREFAT.numtransitem = PCMOVCOMPLEPREFAT.numtransitem(+);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        SELECT decode(nvl(PCMOVCOMPLE.bonific,'N'),'F',PCMOV.punitcont,PCMOV.punit),
               PCMOV.pbaserca,
               PCMOV.ptabela,
               NVL(PCMOV.usadebcredrcabrind, 'N'),
               nvl(PCMOV.movimentacontacorrenterca,'S'),
               NVL(PCMOV.st,0),
               NVL(PCMOVCOMPLE.stptabela,0),
               NVL(PCMOVCOMPLE.stpbaserca,0),
               nvl(PCMOVCOMPLE.bonific, 'N') bonific -- CC_ITEMBNF
          INTO vnpunit,
               vnpbaserca,
               vnptabela,
               vsusadebcredrcabrind,
               vsmovimentacontacorrenterca,
               vnstpvenda,
               vnstptabela,
               vnstpbaserca,
               vsbonific -- CC_ITEMBNF
          FROM PCMOV, PCMOVCOMPLE
         WHERE PCMOV.numtransvenda = p_numtransvenda
           AND PCMOV.codprod = p_codprod
           AND PCMOV.numseq = p_numseq
           AND PCMOV.qt > 0
           and PCMOV.numtransitem = PCMOVCOMPLE.numtransitem(+);
    END;           

    -- DDVENDAS-41579
    IF (vsbonific IN ('S','F')) THEN
      BEGIN
        SELECT pcpedi.brinde -- DDVENDAS-41579
             , pcpedi.usadebcredrcabrind
          INTO vsItemBrinde
             , vsusadebcredrcabrind
          FROM pcpedi
         WHERE numped = vnnumped
           AND codprod = p_codprod
           AND numseq = p_numseq;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vsItemBrinde := 'N';
      END;		   

      IF (vsItemBrinde = 'S') THEN
        vsbrinde := 'S';
      END IF;
    END IF;
    
    -- Se a Operação for de Liquidez - HIS.01108.2016 - Crédito do Conta Corrente por Liquidez
    IF p_tipo = 'L' THEN

      -- Liquidez
      vstipo    := 'L';

      -- Não pode chamar ccrca_verificar_fechamento porque ela faz um Count(*) na PCPRESTPREFAT, dá conflito com a Trigger da PCPRESTPREFAT de Liquidez
      vbfechado := TRUE; -->> Forçar entrar na primeira Condição

    -- Se a Operação for de Liquidez - HIS.01108.2016 - Crédito do Conta Corrente por Liquidez
    ELSE

      vbfechado := ccrca_verificar_fechamento(p_numtransvenda);

      -- Teste de tipo de processo incluído por sabrina
      vstipo := 'F';

      -- Se a operação for de E - Exclusão
      IF p_tipo = 'E' THEN
        vstipo := 'C';
      END IF;

    END IF;

    IF vbfechado = TRUE OR vstipomovccrca <> 'VA' THEN
      vnvalorlanc := ccrca_saldo_item(NVL(vsusacredrca,
                                          gregpcconsum.usacredrca),
                                      NVL(vsusadebcredrca,
                                          vsusadebcredrca_rca),
                                      vsbroker,
                                      vsorigemped,
                                      NVL(vsbonificaltdebcredrca,
                                          gregpcconsum.bonificaltdebcredrca),
                                      NVL(vstrocaaltdebcredrca,
                                          gregpcconsum.trocaaltdebcredrca),
                                      NVL(vscrmaltdebcredrca,
                                          gregpcconsum.crmaltdebcredrca),
                                      NVL(vsbrokeraltdebcredrca,
                                          gregpcconsum.brokeraltdebcredrca),
                                      NVL(vstipomovccrca,
                                          NVL(gregpcconsum.tipomovccrca, 'VV')),
                                      vncondvenda,
                                      vsbrinde,
                                      vncodusur,
                                      vstipo, --incluido por sabrina
                                      vnpunit,
                                      vnptabela,
                                      NVL(vnpbaserca, NVL(vnptabela, 0)),
                                      p_qt,
                                      vsusadebcredrcabrind,
                                      vsmovimentacontacorrenterca,
                                      vnstpvenda,
                                      vnstptabela,
                                      vnstpbaserca,
                                      vsbonific -- CC_ITEMBNF
                                      ); --TESTE THIAGO
    ELSE
      vnvalorlanc := ccrca_saldo_item(NVL(vsusacredrca,
                                          gregpcconsum.usacredrca),
                                      NVL(vsusadebcredrca,
                                          vsusadebcredrca_rca),
                                      vsbroker,
                                      vsorigemped,
                                      NVL(vsbonificaltdebcredrca,
                                          gregpcconsum.bonificaltdebcredrca),
                                      NVL(vstrocaaltdebcredrca,
                                          gregpcconsum.trocaaltdebcredrca),
                                      NVL(vscrmaltdebcredrca,
                                          gregpcconsum.crmaltdebcredrca),
                                      NVL(vsbrokeraltdebcredrca,
                                          gregpcconsum.brokeraltdebcredrca),
                                      NVL(vstipomovccrca,
                                          NVL(gregpcconsum.tipomovccrca, 'VV')),
                                      vncondvenda,
                                      vsbrinde,
                                      vncodusur,
                                      'V', --incluido por sabrina
                                      vnpunit,
                                      vnptabela,
                                      NVL(vnpbaserca, NVL(vnptabela, 0)),
                                      p_qt,
                                      vsusadebcredrcabrind,
                                      vsmovimentacontacorrenterca,
                                      vnstpvenda,
                                      vnstptabela,
                                      vnstpbaserca,
                                      vsbonific -- CC_ITEMBNF
                                      );
    END IF;

    ----------------------------------------------------------
    -- Se houver Rateio de Crédito de C/C RCA
    -- E << NÃO >> estiver chamando da Inclusão da Nota Fiscal
    ----------------------------------------------------------
    IF (F_USARATEIOCREDRCASUPERVISOR(vncodusur,
                                     NVL(p_percrateiocredrcasupervisor,0),
                                     NVL(vnvalorlanc,0))) AND
       (p_rotina NOT IN (1400)) THEN
      -- Valor do Lançamento - Diferença do % que ficará com o RCA
      vnvalorlanc := ROUND(NVL(vnvalorlanc,0) * (NVL(p_percrateiocredrcasupervisor,0) / 100),2);
  END IF;

    RETURN(vnvalorlanc);
  END; --ccrca_retornar_saldo_item_nf

  --RNG13
  FUNCTION ccrca_estornar_ccrca_item_nf(p_codfunclanc   IN pclogrca.codfunc%TYPE,
                                        p_rotinalanc    IN pclogrca.rotina%TYPE,
                                        p_codusur       IN pcpedc.codusur%TYPE,
                                        p_numtransvenda IN pcpedc.numtransvenda%TYPE,
                                        p_codprod       IN pcpedi.codprod%TYPE,
                                        p_numseq        IN pcpedi.numseq%TYPE,
                                        p_qt            IN NUMBER)
    RETURN BOOLEAN IS
    vnvalorlanc        NUMBER;
    vnnumped           pcpedc.numped%TYPE;
    vddata             pcpedc.DATA%TYPE;
    vsposicao          pcpedc.posicao%TYPE;
    vnvlcorrente_ant   pcusuari.vlcorrente%TYPE;
    vnvllimcred        pcusuari.vllimcred%TYPE;
    vnvlcorrente_atual pcusuari.vlcorrente%TYPE;
    vbvalido           BOOLEAN;
    -- Log
    TYPE TRecItem                   IS RECORD(
         nPVENDA                    PCLOGRCA.PVENDA%TYPE,
         nST                        PCLOGRCA.ST%TYPE,
         nPBASERCA                  PCLOGRCA.PBASERCA%TYPE,
         nSTPBASERCA                PCLOGRCA.STPBASERCA%TYPE,
         nPTABELA                   PCLOGRCA.PTABELA%TYPE,
         nSTPTABELA                 PCLOGRCA.STPTABELA%TYPE,
         nBONIFIC                   PCLOGRCA.BONIFIC%TYPE,
         nQT                        PCLOGRCA.QT%TYPE,
         vUSADEBCREDRCABRIND        PCLOGRCA.USADEBCREDRCABRIND%TYPE,
         vMOVIMENTACONTACORRENTERCA PCLOGRCA.MOVIMENTACONTACORRENTERCA%TYPE,
         nCODPROMOCAOMED            PCLOGRCA.CODPROMOCAOMED%TYPE,
         nVLUNITLIMCREDRCAUTILIZMED PCPEDI.VLUNITLIMCREDRCAUTILIZMED%TYPE); -- 4954.001502.2017);
    vrItem                          TRecItem;
    -- HIS.00632.2016
    vncodusur          pcpedc.codusur%type;
    -- Variáveis para Rateio Crédito C/C RCA
    nPERCRATEIOCREDRCASUPERVISOR    NUMBER;
    -- LIMITE_FLEX
    vvtipomovccrca                  pcpedc.tipomovccrca%type;
    vnvllimcred_atual               pcusuari.vllimcred%type;
    -- Variáveis para Rateio Crédito C/C RCA - HIS.00052.2017
    nPERCRATEIOCREDSUPERVEMPRESA    NUMBER;
    vncodsupervisor                 pcusuari.codsupervisor%type;
    vncod_cadrca_supervisor         PCSUPERV.COD_CADRCA%TYPE;
    vncod_cadrca_empresa            PCUSUARI.CODUSUR%TYPE;
    vnValorTransf                   NUMBER(15,2);
    vnValorTransfSupervisor         NUMBER(15,2);
    vnValorTransfEmpresa            NUMBER(15,2);
    -- Regra específica - HIS.00052.2017
    bMOVSALDORCAPORPEDIDOFAT        BOOLEAN;
    vvGravouTabAux                  VARCHAR2(1);
    vnValorLancProduto              NUMBER;
    vnValorTransfProduto            NUMBER;
    vnValorTransfSupervisorProd     NUMBER(15,2);
    vnValorTransfEmpresaProd        NUMBER(15,2);
    -- Exceção Desvio
    vvTabelaNotaFiscal              VARCHAR2(30); -- DDMEDICA-146

  BEGIN
    vbvalido := TRUE; -- correcao sabrina

    -------------------------------------------------------------------------------------------------
    -- HIS.00065.2018 - Se usar o saldo C/C somente no próprio pedido, não acumula o Saldo C/C no RCA
    -------------------------------------------------------------------------------------------------
    IF (F_USARSALDORCASOMENTENOPEDIDO) THEN
      RETURN TRUE;
    END IF;

    -- Obter % Rateio de Crédito de C/C RCA
    nPERCRATEIOCREDRCASUPERVISOR := F_PERCRATEIOCREDRCASUPERVISOR;

    -- Obter Regra Específica que indica se movimentará o Conta Corrente do RCA Faturamento por PedidO - HIS.00052.2017
    bMOVSALDORCAPORPEDIDOFAT     := F_MOVSALDORCAPORPEDIDOFAT;

    BEGIN
      SELECT DISTINCT numped
        INTO vnnumped
        FROM PCNFSAIDPREFAT
       WHERE numtransvenda = p_numtransvenda;
      vvTabelaNotaFiscal := 'PCNFSAIDPREFAT'; -- DDMEDICA-146
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    /*MED-2277*/
    IF vbvalido = FALSE THEN
      BEGIN
        SELECT DISTINCT numped
          INTO vnnumped
          FROM PCNFSAID
         WHERE numtransvenda = p_numtransvenda;
         vbvalido := TRUE;
        vvTabelaNotaFiscal := 'PCNFSAID'; -- DDMEDICA-146
      EXCEPTION
        WHEN OTHERS THEN
          vbvalido := FALSE;
      END;
    END IF;

    BEGIN
      SELECT p.DATA, p.posicao, p.tipomovccrca -- 4954.001502.2017
        INTO vddata, vsposicao, vvtipomovccrca -- 4954.001502.2017
        FROM pcpedc p
       WHERE p.numped = vnnumped;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(p_codusur,
                                       vnnumped);

    ---------------------------------------------------------------------------------------------
    -- Específico - HIS.00052.2017 - Se Movimenta Conta-Corrente do RCA no Faturamento por Pedido
    ---------------------------------------------------------------------------------------------
    IF (bMOVSALDORCAPORPEDIDOFAT) AND
       (NVL(vvtipomovccrca,' ') = 'FF') THEN

      -- Pesquisa Supervisor do RCA
      BEGIN
        SELECT p.codsupervisor
          INTO vncodsupervisor
          FROM pcusuari p
         WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;
      EXCEPTION
        WHEN OTHERS THEN
          vncodsupervisor := NULL;
      END;

      -- Verifica se já gravou a Tabela Auxiliar
      BEGIN
        SELECT 'S'
          INTO vvGravouTabAux
          FROM pclogrcaprodmed
         WHERE (numtransvenda = p_numtransvenda)
           AND (rotina        = p_rotinalanc)
           AND (rownum        = 1);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvGravouTabAux := 'N';
      END;

      -- Se ainda não gravou a Tabela Auxiliar
      IF (vvGravouTabAux = 'N') THEN

        -- Inicializa o Valor Total do Lançamento e Transferência
        vnvalorlanc   := 0;
        vnValorTransf := 0;

        -- Processamento dos Itens da Nota Fiscal (Igual está na Proc. de Cancelamento)
        FOR vc_ItensNotaFiscal IN (SELECT PCMOVPREFAT.codprod
                                        , PCMOVPREFAT.numseq
                                        , PCMOVPREFAT.qt
                                     FROM PCMOVPREFAT
                                    WHERE numtransvenda = p_numtransvenda
                                      AND qt > 0
                                      AND PCMOVPREFAT.numseq > 0
                                      AND vvTabelaNotaFiscal = 'PCNFSAIDPREFAT' -- DDMEDICA-146
                                    UNION
                                   SELECT PCMOV.codprod
                                        , PCMOV.numseq
                                        , PCMOV.qt
                                     FROM PCMOV
                                    WHERE numtransvenda = p_numtransvenda
                                      AND qt > 0
                                      AND PCMOV.numseq > 0
                                      AND vvTabelaNotaFiscal = 'PCNFSAID' -- DDMEDICA-146
                                  ) LOOP

          -- Valor do Lançamento DO PRODUTO
          vnValorLancProduto := ccrca_retornar_saldo_item_nf(p_numtransvenda,
                                                             vc_ItensNotaFiscal.codprod, -->> CODPROD DO LAÇO
                                                             vc_ItensNotaFiscal.numseq,  -->> NUMSEQ DO LAÇO
                                                             vc_ItensNotaFiscal.qt,      -->> QTDE DO LAÇO
                                                             'I', -- incluido por sabrina
                                                             1400, -->> IMPORTANTE: PASSAR A ROTINA 1400 PARA PEGAR O VALOR CHEIO
                                                             nPERCRATEIOCREDRCASUPERVISOR);

          -- Busca informações na PCMOVCOMPLEPREFAT
          IF    (vvTabelaNotaFiscal = 'PCNFSAIDPREFAT') THEN
            BEGIN
              SELECT PCMOVPREFAT.punit
                   , PCMOVPREFAT.st
                   , PCMOVPREFAT.pbaserca
                   , PCMOVCOMPLEPREFAT.stpbaserca
                   , PCMOVPREFAT.ptabela
                   , PCMOVCOMPLEPREFAT.stptabela
                   , PCMOVCOMPLEPREFAT.bonific
                   , vc_ItensNotaFiscal.qt -- Quantidade definida nesta Proc. -->> QTDE DO LAÇO
                   , PCMOVPREFAT.usadebcredrcabrind
                   , PCMOVPREFAT.movimentacontacorrenterca
                   , PCMOVCOMPLEPREFAT.codpromocaomed
                INTO vrItem.nPVENDA
                   , vrItem.nST
                   , vrItem.nPBASERCA
                   , vrItem.nSTPBASERCA
                   , vrItem.nPTABELA
                   , vrItem.nSTPTABELA
                   , vrItem.nBONIFIC
                   , vrItem.nQT
                   , vrItem.vUSADEBCREDRCABRIND
                   , vrItem.vMOVIMENTACONTACORRENTERCA
                   , vrItem.nCODPROMOCAOMED
                FROM PCMOVPREFAT,
                     PCMOVCOMPLEPREFAT
               WHERE (PCMOVPREFAT.numtransvenda = p_numtransvenda)
                 AND (PCMOVPREFAT.codprod       = vc_ItensNotaFiscal.codprod) -->> CODPROD DO LAÇO
                 AND (PCMOVPREFAT.numseq        = vc_ItensNotaFiscal.numseq)  -->> NUMSEQ DO LAÇO
                 AND (PCMOVPREFAT.qt            > 0)
                 AND (PCMOVPREFAT.numtransitem  = PCMOVCOMPLEPREFAT.numtransitem(+));
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vrItem.nPVENDA                    := NULL;
                vrItem.nST                        := NULL;
                vrItem.nPBASERCA                  := NULL;
                vrItem.nSTPBASERCA                := NULL;
                vrItem.nPTABELA                   := NULL;
                vrItem.nSTPTABELA                 := NULL;
                vrItem.nBONIFIC                   := 'N';
                vrItem.nQT                        := NULL;
                vrItem.vUSADEBCREDRCABRIND        := NULL;
                vrItem.vMOVIMENTACONTACORRENTERCA := NULL;
                vrItem.nCODPROMOCAOMED            := NULL;
            END;
          -- Busca informações na PCMOV - DDMEDICA-146
          ELSIF (vvTabelaNotaFiscal = 'PCNFSAID') THEN
            BEGIN
              SELECT PCMOV.punit
                   , PCMOV.st
                   , PCMOV.pbaserca
                   , PCMOVCOMPLE.stpbaserca
                   , PCMOV.ptabela
                   , PCMOVCOMPLE.stptabela
                   , PCMOVCOMPLE.bonific
                   , vc_ItensNotaFiscal.qt -- Quantidade definida nesta Proc. -->> QTDE DO LAÇO
                   , PCMOV.usadebcredrcabrind
                   , PCMOV.movimentacontacorrenterca
                   , PCMOVCOMPLE.codpromocaomed
                INTO vrItem.nPVENDA
                   , vrItem.nST
                   , vrItem.nPBASERCA
                   , vrItem.nSTPBASERCA
                   , vrItem.nPTABELA
                   , vrItem.nSTPTABELA
                   , vrItem.nBONIFIC
                   , vrItem.nQT
                   , vrItem.vUSADEBCREDRCABRIND
                   , vrItem.vMOVIMENTACONTACORRENTERCA
                   , vrItem.nCODPROMOCAOMED
                FROM PCMOV,
                     PCMOVCOMPLE
               WHERE (PCMOV.numtransvenda = p_numtransvenda)
                 AND (PCMOV.codprod       = vc_ItensNotaFiscal.codprod) -->> CODPROD DO LAÇO
                 AND (PCMOV.numseq        = vc_ItensNotaFiscal.numseq)  -->> NUMSEQ DO LAÇO
                 AND (PCMOV.qt            > 0)
                 AND (PCMOV.numtransitem  = PCMOVCOMPLE.numtransitem(+));
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vrItem.nPVENDA                    := NULL;
                vrItem.nST                        := NULL;
                vrItem.nPBASERCA                  := NULL;
                vrItem.nSTPBASERCA                := NULL;
                vrItem.nPTABELA                   := NULL;
                vrItem.nSTPTABELA                 := NULL;
                vrItem.nBONIFIC                   := 'N';
                vrItem.nQT                        := NULL;
                vrItem.vUSADEBCREDRCABRIND        := NULL;
                vrItem.vMOVIMENTACONTACORRENTERCA := NULL;
                vrItem.nCODPROMOCAOMED            := NULL;
            END;
          END IF;
          
          -- Insere em Tabela Auxiliar o que não será mais gravado por Produto na PCLOGRCA
          INSERT INTO pclogrcaprodmed
            (numped,
             posicao,
             numtransvenda,
             DATA,
             codfunc,
             codusur,
             rotina,
             vlsaldorca,
             codprod,
             numseq,
             historico,
             PVENDA,
             ST,
             PBASERCA,
             STPBASERCA,
             PTABELA,
             STPTABELA,
             BONIFIC,
             QT,
             USADEBCREDRCABRIND,
             MOVIMENTACONTACORRENTERCA,
             CODPROMOCAOMED,
             PERCRATEIOCREDRCASUPERVISOR)
          VALUES
            (vnnumped,
             vsposicao,
             p_numtransvenda,
             SYSDATE,
             p_codfunclanc,
             vncodusur, -- HIS.00632.2016 -- p_codusur,
             p_rotinalanc,
             (vnValorLancProduto * (-1)), -->> VALOR DO LANÇAMENTO DO PRODUTO (MULTIPLICA POR -1 POR SER ESTORNO)
             vc_ItensNotaFiscal.codprod,  -->> CODPROD DO LAÇO
             vc_ItensNotaFiscal.numseq,   -->> NUMSEQ DO LAÇO
             SUBSTR('CTRLCCRCA: ESTORNO SALDO ITEM TRANS. VENDA', 1, 60),
             vrItem.nPVENDA,
             vrItem.nST,
             vrItem.nPBASERCA,
             vrItem.nSTPBASERCA,
             vrItem.nPTABELA,
             vrItem.nSTPTABELA,
             vrItem.nBONIFIC,
             vrItem.nQT,
             vrItem.vUSADEBCREDRCABRIND,
             vrItem.vMOVIMENTACONTACORRENTERCA,
             vrItem.nCODPROMOCAOMED,
             nPERCRATEIOCREDRCASUPERVISOR);

          -- Acumula o Valor do Lançamento
          vnvalorlanc := NVL(vnvalorlanc,0) + NVL(vnValorLancProduto,0);

          ----------------------------------------------------
          -- Se houver Rateio de Crédito de C/C RCA
          -- E estiver chamando do Cancelamento da Nota Fiscal
          ----------------------------------------------------
          IF (F_USARATEIOCREDRCASUPERVISOR(vncodusur,
                                           NVL(nPERCRATEIOCREDRCASUPERVISOR,0),
                                           NVL(vnValorLancProduto,0))) AND
             (p_rotinalanc IN (1409)) THEN

            -- Pesquisa o RCA vinculado ao Supervisor
            BEGIN
              SELECT PCUSUARI.CODUSUR
                INTO vncod_cadrca_supervisor
                FROM PCSUPERV
                   , PCUSUARI
               WHERE (PCSUPERV.CODSUPERVISOR = vncodsupervisor)
                 AND (PCUSUARI.CODUSUR       = PCSUPERV.COD_CADRCA);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vncod_cadrca_supervisor := NULL;
            END;

            -- Pesquisa o RCA vinculado a Empresa
            vncod_cadrca_empresa := F_OBTER_RCA_EMPRESA;

            -- Se o Supervisor movimenta C/C
            IF (NVL(vncod_cadrca_supervisor,0) > 0) THEN

              -- Valor da Transferência - Diferença do % que ficará com o RCA
              vnValorTransfProduto := ROUND(NVL(vnValorLancProduto,0) * (1 - (NVL(nPERCRATEIOCREDRCASUPERVISOR,0) / 100)),2);

              -- Insere em Tabela Auxiliar o que não será mais gravado por Produto na PCLOGRCA
              INSERT INTO pclogrcaprodmed
                  (numped,
                   posicao,
                   numtransvenda,
                   DATA,
                   codfunc,
                   codusur,
                   rotina,
                   vlsaldorca,
                   codprod,
                   numseq,
                   historico,
                   PVENDA,
                   ST,
                   PBASERCA,
                   STPBASERCA,
                   PTABELA,
                   STPTABELA,
                   BONIFIC,
                   QT,
                   USADEBCREDRCABRIND,
                   MOVIMENTACONTACORRENTERCA,
                   CODPROMOCAOMED,
                   PERCRATEIOCREDRCASUPERVISOR)
                VALUES
                  (vnnumped,
                   vsposicao,
                   p_numtransvenda,
                   SYSDATE,
                   p_codfunclanc,
                   vncodusur, -- HIS.00632.2016 -- p_codusur,
                   p_rotinalanc,
                   vnValorTransfProduto,       -->> VALOR DA TRANSFERÊNCIA DO PRODUTO POSITIVO PORQUE SERÁ ESTORNO DO DÉBITO DO RCA
                   vc_ItensNotaFiscal.codprod, -->> CODPROD DO LAÇO
                   vc_ItensNotaFiscal.numseq,  -->> NUMSEQ DO LAÇO
                   SUBSTR('CTRLCCRCA: ESTORNO RATEIO RCA ITEM TRANS. VENDA', 1, 60),
                   vrItem.nPVENDA,
                   vrItem.nST,
                   vrItem.nPBASERCA,
                   vrItem.nSTPBASERCA,
                   vrItem.nPTABELA,
                   vrItem.nSTPTABELA,
                   vrItem.nBONIFIC,
                   vrItem.nQT,
                   vrItem.vUSADEBCREDRCABRIND,
                   vrItem.vMOVIMENTACONTACORRENTERCA,
                   vrItem.nCODPROMOCAOMED,
                   nPERCRATEIOCREDRCASUPERVISOR);

              -- Acumula o Valor do Lançamento
              vnValorTransf := NVL(vnValorTransf,0) + NVL(vnValorTransfProduto,0);

             /*******************************
              A PARTE DO SUPERVISOR E EMPRESA
                 SERÁ SEMPRE NO FATURAMENTO
                  (Executa sem Restrições)
              *******************************/

              -- RATEIO ENTRE SUPERVISOR E EMPRESA ------------------------------------------------------

              -- Obter % Rateio de Crédito de C/C Supervisor e Empresa
              nPERCRATEIOCREDSUPERVEMPRESA := F_PERCRATEIOCREDSUPERVEMPRESA;

              ------------------------------------------------------------
              -- Se houver Rateio de Crédito de C/C Supervisor com Empresa
              ------------------------------------------------------------
              IF (F_USARATEIOCREDSUPERVEMPRESA(vncod_cadrca_empresa,
                                               nPERCRATEIOCREDSUPERVEMPRESA,
                                               vnValorTransfProduto)) THEN
                -- Calcula a parte do Supervisor
                vnValorTransfSupervisorProd := ROUND(vnValorTransfProduto * (NVL(nPERCRATEIOCREDSUPERVEMPRESA,0) / 100),2);
                -- Calcula a parte da Empresa
                vnValorTransfEmpresaProd    := (NVL(vnValorTransfProduto,0) - NVL(vnValorTransfSupervisorProd,0));
              ELSE
                -- Somente tem a parte do Supervisor
                vnValorTransfSupervisorProd := vnValorTransfProduto;
                -- Não tem a parte da Empresa
                vnValorTransfEmpresaProd    := 0;
              END IF;

              -- CREDITANDO SUPERVISOR ------------------------------------------------------------------
              IF (NVL(vnValorTransfSupervisorProd,0) > 0) THEN

                INSERT INTO pclogrcaprodmed
                  (numped,
                   posicao,
                   numtransvenda,
                   DATA,
                   codfunc,
                   codusur,
                   rotina,
                   vlsaldorca,
                   codprod,
                   numseq,
                   historico,
                   PERCRATEIOCREDRCASUPERVISOR)
                VALUES
                  (vnnumped,
                   vsposicao,
                   p_numtransvenda,
                   SYSDATE,
                   p_codfunclanc,
                   vncod_cadrca_supervisor, -- SUPERVISOR
                   p_rotinalanc,
                   vnValorTransfSupervisorProd * (-1), -->> VALOR ESTORNO DA TRANSFERÊNCIA DO PRODUTO PARA O SUPERVISOR
                   vc_ItensNotaFiscal.codprod,         -->> CODPROD DO LAÇO
                   vc_ItensNotaFiscal.numseq,          -->> NUMSEQ DO LAÇO
                   SUBSTR('CTRLCCRCA: ESTORNO RATEIO SUPERV. ITEM TRANS. VENDA', 1, 60), -->> LANÇAMENTO RATEIO TOTAL DA TRANSAÇÃO
                   nPERCRATEIOCREDRCASUPERVISOR);

              END IF; -- Fim Condição: CREDITANDO SUPERVISOR

              -- CREDITANDO EMPRESA ---------------------------------------------------------------------
              IF (NVL(vncod_cadrca_empresa,0) > 0)     AND
                 (NVL(vnValorTransfEmpresaProd,0) > 0) THEN

                INSERT INTO pclogrcaprodmed
                  (numped,
                   posicao,
                   numtransvenda,
                   DATA,
                   codfunc,
                   codusur,
                   rotina,
                   vlsaldorca,
                   codprod,
                   numseq,
                   historico,
                   PERCRATEIOCREDRCASUPERVISOR)
                VALUES
                  (vnnumped,
                   vsposicao,
                   p_numtransvenda,
                   SYSDATE,
                   p_codfunclanc,
                   vncod_cadrca_empresa, -- EMPRESA
                   p_rotinalanc,
                   vnValorTransfEmpresaProd * (-1), -->> VALOR DO ESTORNO DA TRANSFERÊNCIA DO PRODUTO PARA A EMPRESA
                   vc_ItensNotaFiscal.codprod,      -->> CODPROD DO LAÇO
                   vc_ItensNotaFiscal.numseq,       -->> NUMSEQ DO LAÇO
                   SUBSTR('CTRLCCRCA: ESTORNO RATEIO EMPRESA ITEM TRANS. VENDA', 1, 60), -->> LANÇAMENTO RATEIO TOTAL DA TRANSAÇÃO
                   nPERCRATEIOCREDSUPERVEMPRESA);

              END IF; -- Fim Condição: CREDITANDO EMPRESA

            END IF; -- Se o Supervisor movimenta C/C

          END IF; -- Fim Condição: Rateio

        END LOOP; -- FIM: Processamento dos Itens da Nota Fiscal

        -- Pesquisa Saldo do RCA
        BEGIN
          SELECT p.vlcorrente, p.vllimcred
            INTO vnvlcorrente_ant, vnvllimcred
            FROM pcusuari p
           WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;
        EXCEPTION
          WHEN OTHERS THEN
            vbvalido := FALSE;
        END;

        IF vbvalido = TRUE THEN

          vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) - NVL(vnvalorlanc, 0);

          -- a package não deve barrar a movimentacao do saldo, os programas eh que fazem isso
          --IF vnvlcorrente_atual >= 0 THEN
          UPDATE pcusuari
             SET vlcorrente = vnvlcorrente_atual
           WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;

          INSERT INTO pclogrca
            (numped,
             posicao,
             numtransvenda,
             DATA,
             codfunc,
             codusur,
             rotina,
             vlcorrente,
             vllimcred,
             vlcorrenteant,
             vllimcredant,
             codprod,
             numseq,
             historico,
             PERCRATEIOCREDRCASUPERVISOR)
          VALUES
            (vnnumped,
             vsposicao,
             p_numtransvenda,
             SYSDATE,
             p_codfunclanc,
             vncodusur, -- HIS.00632.2016 -- p_codusur,
             p_rotinalanc,
             vnvlcorrente_atual,
             vnvllimcred,
             vnvlcorrente_ant,
             vnvllimcred,
             0, -->> SEM CODPROD
             0, -->> SEM NUMSEQ
             SUBSTR('CTRLCCRCA: ESTORNO SALDO TRANS. VENDA', 1, 60), -->> LANÇAMENTO TOTAL DA TRANSAÇÃO
             nPERCRATEIOCREDRCASUPERVISOR);
          --ELSE
          --vbvalido := FALSE;
          --END IF;

          ------------------------------------------------
          -- Se houver Rateio de Crédito de C/C RCA
          -- JÁ ESTÁ ACUMULADO NA VARIÁVEL vnValorTransf
          ------------------------------------------------
          IF (NVL(vnValorTransf,0) > 0) THEN

            -- Pesquisa o RCA vinculado ao Supervisor
            BEGIN
              SELECT PCUSUARI.CODUSUR
                INTO vncod_cadrca_supervisor
                FROM PCSUPERV
                   , PCUSUARI
               WHERE (PCSUPERV.CODSUPERVISOR = vncodsupervisor)
                 AND (PCUSUARI.CODUSUR       = PCSUPERV.COD_CADRCA);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vncod_cadrca_supervisor := NULL;
            END;

            -- Pesquisa o RCA vinculado a Empresa
            vncod_cadrca_empresa := F_OBTER_RCA_EMPRESA;

            -- Se o Supervisor movimenta C/C
            IF (NVL(vncod_cadrca_supervisor,0) > 0) THEN

              -- Valor da Transferência - Diferença do % que ficará com o RCA
              -- JÁ ESTÁ ACUMULADO NA VARIÁVEL vnValorTransf

              -- DEBITANDO RCA --------------------------------------------------------------------------
              IF (NVL(vnValorTransf,0) > 0) THEN

                SELECT pcusuari.vlcorrente, pcusuari.vllimcred
                  INTO vnvlcorrente_ant, vnvllimcred
                  FROM pcusuari
                 WHERE codusur = vncodusur; -- RCA

                vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) + NVL(vnValorTransf, 0); -- ESTORNO DEDUZINDO VALOR TRANSF.

                UPDATE pcusuari
                   SET vlcorrente = vnvlcorrente_atual
                 WHERE codusur = vncodusur; -- RCA

                INSERT INTO pclogrca
                  (numped,
                   posicao,
                   numtransvenda,
                   DATA,
                   codfunc,
                   codusur,
                   rotina,
                   vlcorrente,
                   vllimcred,
                   vlcorrenteant,
                   vllimcredant,
                   codprod,
                   numseq,
                   historico,
                   PERCRATEIOCREDRCASUPERVISOR)
                VALUES
                  (vnnumped,
                   vsposicao,
                   p_numtransvenda,
                   SYSDATE,
                   p_codfunclanc,
                   vncodusur, -- RCA
                   p_rotinalanc,
                   vnvlcorrente_atual,
                   vnvllimcred,
                   vnvlcorrente_ant,
                   vnvllimcred,
                   0, -->> SEM CODPROD
                   0, -->> SEM NUMSEQ
                   SUBSTR('CTRLCCRCA: ESTORNO RATEIO RCA TRANS. VENDA', 1, 60), -->> LANÇAMENTO RATEIO TOTAL DA TRANSAÇÃO
                   nPERCRATEIOCREDRCASUPERVISOR);

               /*******************************
                A PARTE DO SUPERVISOR E EMPRESA
                   SERÁ SEMPRE NO FATURAMENTO
                    (Executa sem Restrições)
                *******************************/

                -- RATEIO ENTRE SUPERVISOR E EMPRESA ------------------------------------------------------

                -- Obter % Rateio de Crédito de C/C Supervisor e Empresa
                nPERCRATEIOCREDSUPERVEMPRESA := F_PERCRATEIOCREDSUPERVEMPRESA;

                ------------------------------------------------------------
                -- Se houver Rateio de Crédito de C/C Supervisor com Empresa
                ------------------------------------------------------------
                IF (F_USARATEIOCREDSUPERVEMPRESA(vncod_cadrca_empresa,
                                                 nPERCRATEIOCREDSUPERVEMPRESA,
                                                 vnValorTransf)) THEN
                  -- Calcula a parte do Supervisor
                  vnValorTransfSupervisor := ROUND(vnValorTransf * (NVL(nPERCRATEIOCREDSUPERVEMPRESA,0) / 100),2);
                  -- Calcula a parte da Empresa
                  vnValorTransfEmpresa    := (NVL(vnValorTransf,0) - NVL(vnValorTransfSupervisor,0));
                ELSE
                  -- Somente tem a parte do Supervisor
                  vnValorTransfSupervisor := vnValorTransf;
                  -- Não tem a parte da Empresa
                  vnValorTransfEmpresa    := 0;
                END IF;

                -- CREDITANDO SUPERVISOR ------------------------------------------------------------------
                IF (NVL(vnValorTransfSupervisor,0) > 0) THEN

                  SELECT pcusuari.vlcorrente, pcusuari.vllimcred
                    INTO vnvlcorrente_ant, vnvllimcred
                    FROM pcusuari
                   WHERE codusur = vncod_cadrca_supervisor; -- SUPERVISOR

                  vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) - NVL(vnValorTransfSupervisor, 0); -- ESTORNO INCREMENTANDO VALOR TRANSF.

                  UPDATE pcusuari
                     SET vlcorrente = vnvlcorrente_atual
                   WHERE codusur = vncod_cadrca_supervisor; -- SUPERVISOR

                  INSERT INTO pclogrca
                    (numped,
                     posicao,
                     numtransvenda,
                     DATA,
                     codfunc,
                     codusur,
                     rotina,
                     vlcorrente,
                     vllimcred,
                     vlcorrenteant,
                     vllimcredant,
                     codprod,
                     numseq,
                     historico,
                     PERCRATEIOCREDRCASUPERVISOR)
                  VALUES
                    (vnnumped,
                     vsposicao,
                     p_numtransvenda,
                     SYSDATE,
                     p_codfunclanc,
                     vncod_cadrca_supervisor, -- SUPERVISOR
                     p_rotinalanc,
                     vnvlcorrente_atual,
                     vnvllimcred,
                     vnvlcorrente_ant,
                     vnvllimcred,
                     0, -->> SEM CODPROD
                     0, -->> SEM NUMSEQ
                     SUBSTR('CTRLCCRCA: ESTORNO RATEIO SUPERV. TRANS. VENDA', 1, 60), -->> LANÇAMENTO RATEIO TOTAL DA TRANSAÇÃO
                     nPERCRATEIOCREDRCASUPERVISOR);

                END IF; -- Fim Condição: CREDITANDO SUPERVISOR

                -- CREDITANDO EMPRESA ---------------------------------------------------------------------
                IF (NVL(vncod_cadrca_empresa,0) > 0) AND
                   (NVL(vnValorTransfEmpresa,0) > 0) THEN

                  SELECT pcusuari.vlcorrente, pcusuari.vllimcred
                    INTO vnvlcorrente_ant, vnvllimcred
                    FROM pcusuari
                   WHERE codusur = vncod_cadrca_empresa; -- EMPRESA

                  vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) - NVL(vnValorTransfEmpresa, 0); -- ESTORNO INCREMENTANDO VALOR TRANSF.

                  UPDATE pcusuari
                     SET vlcorrente = vnvlcorrente_atual
                   WHERE codusur = vncod_cadrca_empresa; -- EMPRESA

                  INSERT INTO pclogrca
                    (numped,
                     posicao,
                     numtransvenda,
                     DATA,
                     codfunc,
                     codusur,
                     rotina,
                     vlcorrente,
                     vllimcred,
                     vlcorrenteant,
                     vllimcredant,
                     codprod,
                     numseq,
                     historico,
                     PERCRATEIOCREDRCASUPERVISOR)
                  VALUES
                    (vnnumped,
                     vsposicao,
                     p_numtransvenda,
                     SYSDATE,
                     p_codfunclanc,
                     vncod_cadrca_empresa, -- EMPRESA
                     p_rotinalanc,
                     vnvlcorrente_atual,
                     vnvllimcred,
                     vnvlcorrente_ant,
                     vnvllimcred,
                     0, -->> SEM CODPROD
                     0, -->> SEM NUMSEQ
                     SUBSTR('CTRLCCRCA: ESTORNO RATEIO EMPRESA TRANS. VENDA', 1, 60), -->> LANÇAMENTO RATEIO TOTAL DA TRANSAÇÃO
                     nPERCRATEIOCREDSUPERVEMPRESA);

                END IF; -- Fim Condição: CREDITANDO EMPRESA

              END IF; -- Fim Condição: DEBITANDO RCA

            END IF; -- Fim Condição Se o Supervisor movimenta C/C
          END IF; -- Fim Condição Rateio Saldo C/C

        END IF; -- Fim Condição: vbvalido = TRUE

      END IF; -- Fim: Se ainda não gravou a Tabela Auxiliar

    ---------------------------------------------------------------------------------------------
    -- Padrão Pacote
    ---------------------------------------------------------------------------------------------
    ELSE

      BEGIN
        SELECT p.vlcorrente, p.vllimcred
          INTO vnvlcorrente_ant, vnvllimcred
          FROM pcusuari p
         WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;
      EXCEPTION
        WHEN OTHERS THEN
          vbvalido := FALSE;
      END;

      IF vbvalido = TRUE THEN

        -- Busca informações na PCMOVCOMPLEPREFAT
        IF    (vvTabelaNotaFiscal = 'PCNFSAIDPREFAT') THEN
          BEGIN
            SELECT PCMOVPREFAT.punit
                 , PCMOVPREFAT.st
                 , PCMOVPREFAT.pbaserca
                 , PCMOVCOMPLEPREFAT.stpbaserca
                 , PCMOVPREFAT.ptabela
                 , PCMOVCOMPLEPREFAT.stptabela
                 , PCMOVCOMPLEPREFAT.bonific
                 , p_qt -- Quantidade do Parâmetro
                 , PCMOVPREFAT.usadebcredrcabrind
                 , PCMOVPREFAT.movimentacontacorrenterca
                 , PCMOVCOMPLEPREFAT.codpromocaomed
              INTO vrItem.nPVENDA
                 , vrItem.nST
                 , vrItem.nPBASERCA
                 , vrItem.nSTPBASERCA
                 , vrItem.nPTABELA
                 , vrItem.nSTPTABELA
                 , vrItem.nBONIFIC
                 , vrItem.nQT
                 , vrItem.vUSADEBCREDRCABRIND
                 , vrItem.vMOVIMENTACONTACORRENTERCA
                 , vrItem.nCODPROMOCAOMED
              FROM PCMOVPREFAT,
                   PCMOVCOMPLEPREFAT
             WHERE (PCMOVPREFAT.numtransvenda = p_numtransvenda)
               AND (PCMOVPREFAT.codprod       = p_codprod)
               AND (PCMOVPREFAT.numseq        = p_numseq)
               AND (PCMOVPREFAT.qt            > 0)
               AND (PCMOVPREFAT.numtransitem  = PCMOVCOMPLEPREFAT.numtransitem(+));
  
            -- 4954.001502.2017 - LIMITE_FLEX
            IF (NVL(vvtipomovccrca,' ') = 'LL') THEN
              BEGIN
                SELECT VLUNITLIMCREDRCAUTILIZMED
                  INTO vrItem.nVLUNITLIMCREDRCAUTILIZMED
                  FROM PCMOVPREFAT,
                       PCMOVCOMPLEPREFAT,
                       pcpedi
                 WHERE (PCMOVPREFAT.numtransvenda = p_numtransvenda)
                   AND (PCMOVPREFAT.codprod       = p_codprod)
                   AND (PCMOVPREFAT.numseq        = p_numseq)
                   AND (PCMOVPREFAT.qt            > 0)
                   AND (PCMOVPREFAT.numtransitem  = PCMOVCOMPLEPREFAT.numtransitem(+))
                   AND (pcpedi.numped       = PCMOVPREFAT.numped)
                   AND (pcpedi.codprod      = PCMOVPREFAT.codprod)
                   AND (pcpedi.numseq       = PCMOVPREFAT.numseq);
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  vrItem.nVLUNITLIMCREDRCAUTILIZMED := NULL;
              END;
            END IF;
  
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vrItem.nPVENDA                    := NULL;
              vrItem.nST                        := NULL;
              vrItem.nPBASERCA                  := NULL;
              vrItem.nSTPBASERCA                := NULL;
              vrItem.nPTABELA                   := NULL;
              vrItem.nSTPTABELA                 := NULL;
              vrItem.nBONIFIC                   := 'N';
              vrItem.nQT                        := NULL;
              vrItem.vUSADEBCREDRCABRIND        := NULL;
              vrItem.vMOVIMENTACONTACORRENTERCA := NULL;
              vrItem.nCODPROMOCAOMED            := NULL;
          END;
        -- Busca informações na PCMOV - DDMEDICA-146
        ELSIF (vvTabelaNotaFiscal = 'PCNFSAID') THEN
          BEGIN
            SELECT PCMOV.punit
                 , PCMOV.st
                 , PCMOV.pbaserca
                 , PCMOVCOMPLE.stpbaserca
                 , PCMOV.ptabela
                 , PCMOVCOMPLE.stptabela
                 , PCMOVCOMPLE.bonific
                 , p_qt -- Quantidade do Parâmetro
                 , PCMOV.usadebcredrcabrind
                 , PCMOV.movimentacontacorrenterca
                 , PCMOVCOMPLE.codpromocaomed
              INTO vrItem.nPVENDA
                 , vrItem.nST
                 , vrItem.nPBASERCA
                 , vrItem.nSTPBASERCA
                 , vrItem.nPTABELA
                 , vrItem.nSTPTABELA
                 , vrItem.nBONIFIC
                 , vrItem.nQT
                 , vrItem.vUSADEBCREDRCABRIND
                 , vrItem.vMOVIMENTACONTACORRENTERCA
                 , vrItem.nCODPROMOCAOMED
              FROM PCMOV,
                   PCMOVCOMPLE
             WHERE (PCMOV.numtransvenda = p_numtransvenda)
               AND (PCMOV.codprod       = p_codprod)
               AND (PCMOV.numseq        = p_numseq)
               AND (PCMOV.qt            > 0)
               AND (PCMOV.numtransitem  = PCMOVCOMPLE.numtransitem(+));
  
            -- 4954.001502.2017 - LIMITE_FLEX
            IF (NVL(vvtipomovccrca,' ') = 'LL') THEN
              BEGIN
                SELECT VLUNITLIMCREDRCAUTILIZMED
                  INTO vrItem.nVLUNITLIMCREDRCAUTILIZMED
                  FROM PCMOV,
                       PCMOVCOMPLE,
                       pcpedi
                 WHERE (PCMOV.numtransvenda = p_numtransvenda)
                   AND (PCMOV.codprod       = p_codprod)
                   AND (PCMOV.numseq        = p_numseq)
                   AND (PCMOV.qt            > 0)
                   AND (PCMOV.numtransitem  = PCMOVCOMPLE.numtransitem(+))
                   AND (pcpedi.numped       = PCMOV.numped)
                   AND (pcpedi.codprod      = PCMOV.codprod)
                   AND (pcpedi.numseq       = PCMOV.numseq);
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  vrItem.nVLUNITLIMCREDRCAUTILIZMED := NULL;
              END;
            END IF;
  
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vrItem.nPVENDA                    := NULL;
              vrItem.nST                        := NULL;
              vrItem.nPBASERCA                  := NULL;
              vrItem.nSTPBASERCA                := NULL;
              vrItem.nPTABELA                   := NULL;
              vrItem.nSTPTABELA                 := NULL;
              vrItem.nBONIFIC                   := 'N';
              vrItem.nQT                        := NULL;
              vrItem.vUSADEBCREDRCABRIND        := NULL;
              vrItem.vMOVIMENTACONTACORRENTERCA := NULL;
              vrItem.nCODPROMOCAOMED            := NULL;
          END;
        END IF;

        vnvalorlanc        := ccrca_retornar_saldo_item_nf(p_numtransvenda,
                                                           p_codprod,
                                                           p_numseq,
                                                           p_qt,
                                                           'E', --incluido por sabrina
                                                           p_rotinalanc,
                                                           nPERCRATEIOCREDRCASUPERVISOR);

        -- LIMITE_FLEX
        IF (NVL(vvtipomovccrca,' ') = 'LL') THEN

          -- Se Usou Limite
          IF (NVL(vrItem.nVLUNITLIMCREDRCAUTILIZMED,0) <> 0) THEN -- 4954.001502.2017

            -- Valor Utilizado do Limite de Crédito - 4954.001502.2017
            vnvalorlanc := NVL(vrItem.nVLUNITLIMCREDRCAUTILIZMED,0) * NVL(p_qt,0);

            -- ( E - Estorno)
            vnvllimcred_atual := NVL(vnvllimcred, 0) + NVL(vnvalorlanc, 0);

            UPDATE pcusuari
               SET vllimcred = vnvllimcred_atual
             WHERE codusur = vncodusur;

            INSERT INTO pcloglimitecredrcamed
              (numped,
               posicao,
               numtransvenda,
               DATA,
               codfunc,
               codusur,
               rotina,
               vlcorrente,
               vllimcred,
               vlcorrenteant,
               vllimcredant,
               codprod,
               numseq,
               historico,
               PVENDA,
               ST,
               PBASERCA,
               STPBASERCA,
               PTABELA,
               STPTABELA,
               BONIFIC,
               QT,
               USADEBCREDRCABRIND,
               MOVIMENTACONTACORRENTERCA,
               CODPROMOCAOMED,
               PERCRATEIOCREDRCASUPERVISOR)
            VALUES
              (vnnumped,
               vsposicao,
               p_numtransvenda,
               SYSDATE,
               p_codfunclanc,
               vncodusur, -- HIS.00632.2016 -- p_codusur,
               p_rotinalanc,
               vnvlcorrente_ant,
               vnvllimcred_atual,
               vnvlcorrente_ant,
               vnvllimcred,
               p_codprod,
               p_numseq,
               SUBSTR('CTRLCCRCA: ESTORNO SALDO ITEM TRANS. VENDA', 1, 60),
               vrItem.nPVENDA,
               vrItem.nST,
               vrItem.nPBASERCA,
               vrItem.nSTPBASERCA,
               vrItem.nPTABELA,
               vrItem.nSTPTABELA,
               vrItem.nBONIFIC,
               vrItem.nQT,
               vrItem.vUSADEBCREDRCABRIND,
               vrItem.vMOVIMENTACONTACORRENTERCA,
               vrItem.nCODPROMOCAOMED,
               nPERCRATEIOCREDRCASUPERVISOR);

          END IF; -- Fim: Se Usou Limite

        ELSE

          vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) - NVL(vnvalorlanc, 0);

          -- a package não deve barrar a movimentacao do saldo, os programas eh que fazem isso
          --IF vnvlcorrente_atual >= 0 THEN
          UPDATE pcusuari
             SET vlcorrente = vnvlcorrente_atual
           WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;

          INSERT INTO pclogrca
            (numped,
             posicao,
             numtransvenda,
             DATA,
             codfunc,
             codusur,
             rotina,
             vlcorrente,
             vllimcred,
             vlcorrenteant,
             vllimcredant,
             codprod,
             numseq,
             historico,
             PVENDA,
             ST,
             PBASERCA,
             STPBASERCA,
             PTABELA,
             STPTABELA,
             BONIFIC,
             QT,
             USADEBCREDRCABRIND,
             MOVIMENTACONTACORRENTERCA,
             CODPROMOCAOMED,
             PERCRATEIOCREDRCASUPERVISOR)
          VALUES
            (vnnumped,
             vsposicao,
             p_numtransvenda,
             SYSDATE,
             p_codfunclanc,
             vncodusur, -- HIS.00632.2016 -- p_codusur,
             p_rotinalanc,
             vnvlcorrente_atual,
             vnvllimcred,
             vnvlcorrente_ant,
             vnvllimcred,
             p_codprod,
             p_numseq,
             SUBSTR('CTRLCCRCA: ESTORNO SALDO ITEM TRANS. VENDA', 1, 60),
             vrItem.nPVENDA,
             vrItem.nST,
             vrItem.nPBASERCA,
             vrItem.nSTPBASERCA,
             vrItem.nPTABELA,
             vrItem.nSTPTABELA,
             vrItem.nBONIFIC,
             vrItem.nQT,
             vrItem.vUSADEBCREDRCABRIND,
             vrItem.vMOVIMENTACONTACORRENTERCA,
             vrItem.nCODPROMOCAOMED,
             nPERCRATEIOCREDRCASUPERVISOR);
          --ELSE
          --vbvalido := FALSE;
          --END IF;

        END IF; -- FIM: LIMITE_FLEX

      END IF;

    END IF; -- FIM: (bMOVSALDORCAPORPEDIDOFAT) -- HIS.00052.2017

    RETURN vbvalido;

  END; --ccrca_estornar_ccrca_item_nf

  --RNG14
  FUNCTION ccrca_incluir_item_nf(p_codfunclanc   IN pclogrca.codfunc%TYPE,
                                 p_rotinalanc    IN pclogrca.rotina%TYPE,
                                 p_codusur       IN pcpedc.codusur%TYPE,
                                 p_numtransvenda IN pcpedc.numtransvenda%TYPE,
                                 p_codprod       IN pcpedi.codprod%TYPE,
                                 p_numseq        IN pcpedi.numseq%TYPE)
    RETURN BOOLEAN IS
    vnvalorlanc        NUMBER;
    vnnumped           pcpedc.numped%TYPE;
    vnvlcorrente_ant   pcusuari.vlcorrente%TYPE;
    vnvllimcred        pcusuari.vllimcred%TYPE;
    vnvlcorrente_atual pcusuari.vlcorrente%TYPE;
    vnqt               pcpedi.qt%TYPE;
    vddata             pcpedc.DATA%TYPE;
    vsposicao          pcpedc.posicao%TYPE;
    vbvalido           BOOLEAN;
    -- Log
    TYPE TRecItem                   IS RECORD(
         nPVENDA                    PCLOGRCA.PVENDA%TYPE,
         nST                        PCLOGRCA.ST%TYPE,
         nPBASERCA                  PCLOGRCA.PBASERCA%TYPE,
         nSTPBASERCA                PCLOGRCA.STPBASERCA%TYPE,
         nPTABELA                   PCLOGRCA.PTABELA%TYPE,
         nSTPTABELA                 PCLOGRCA.STPTABELA%TYPE,
         nBONIFIC                   PCLOGRCA.BONIFIC%TYPE,
         nQT                        PCLOGRCA.QT%TYPE,
         vUSADEBCREDRCABRIND        PCLOGRCA.USADEBCREDRCABRIND%TYPE,
         vMOVIMENTACONTACORRENTERCA PCLOGRCA.MOVIMENTACONTACORRENTERCA%TYPE,
         nCODPROMOCAOMED            PCLOGRCA.CODPROMOCAOMED%TYPE);
    vrItem                          TRecItem;
    -- HIS.00632.2016
    vncodusur                       pcpedc.codusur%type;
    -- LIMITE_FLEX
    --vvtipomovccrca                  pcpedc.tipomovccrca%type;
    -- Variáveis para Rateio Crédito C/C RCA
    nPERCRATEIOCREDRCASUPERVISOR    NUMBER;
    nPERCRATEIOCREDSUPERVEMPRESA    NUMBER;
    vncodsupervisor                 pcusuari.codsupervisor%type;
    vncod_cadrca_supervisor         PCSUPERV.COD_CADRCA%TYPE;
    vncod_cadrca_empresa            PCUSUARI.CODUSUR%TYPE;
    vnValorTransf                   NUMBER(15,2);
    vnValorTransfSupervisor         NUMBER(15,2);
    vnValorTransfEmpresa            NUMBER(15,2);
    -- Conclusão do Rateio ficar no Faturamento
    vstipomovccrca                  pcpedc.tipomovccrca%TYPE;
    -- Regra específica - HIS.00052.2017
    bMOVSALDORCAPORPEDIDOFAT        BOOLEAN;
    vvGravouTabAux                  VARCHAR2(1);
    vnValorLancProduto              NUMBER;
    vnValorTransfProduto            NUMBER;
    vnValorTransfSupervisorProd     NUMBER(15,2);
    vnValorTransfEmpresaProd        NUMBER(15,2);

  BEGIN
    vbvalido := TRUE; --correcao sabrina

    -------------------------------------------------------------------------------------------------
    -- HIS.00065.2018 - Se usar o saldo C/C somente no próprio pedido, não acumula o Saldo C/C no RCA
    -------------------------------------------------------------------------------------------------
    IF (F_USARSALDORCASOMENTENOPEDIDO) THEN
      RETURN TRUE;
    END IF;

    -- Obter % Rateio de Crédito de C/C RCA
    nPERCRATEIOCREDRCASUPERVISOR := F_PERCRATEIOCREDRCASUPERVISOR;

    -- Obter Regra Específica que indica se movimentará o Conta Corrente do RCA Faturamento por PedidO - HIS.00052.2017
    bMOVSALDORCAPORPEDIDOFAT     := F_MOVSALDORCAPORPEDIDOFAT;

    BEGIN
      SELECT numped
        INTO vnnumped
        FROM PCNFSAIDPREFAT
       WHERE numtransvenda = p_numtransvenda;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    /*MED-2277*/
    IF vbvalido = FALSE THEN
      BEGIN
        SELECT numped
          INTO vnnumped
          FROM PCNFSAID
         WHERE numtransvenda = p_numtransvenda;

         vbvalido := TRUE;
      EXCEPTION
        WHEN OTHERS THEN
          vbvalido := FALSE;
      END;
    END IF;

    BEGIN
      SELECT DATA, posicao, tipomovccrca
        INTO vddata, vsposicao, vstipomovccrca
        FROM pcpedc
       WHERE numped = vnnumped;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(p_codusur,
                                       vnnumped);

    ---------------------------------------------------------------------------------------------
    -- Específico - HIS.00052.2017 - Se Movimenta Conta-Corrente do RCA no Faturamento por Pedido
    ---------------------------------------------------------------------------------------------
    IF (bMOVSALDORCAPORPEDIDOFAT)       AND
       (NVL(vstipomovccrca,' ') = 'FF') THEN

      -- Pesquisa Supervisor do RCA
      BEGIN
        SELECT p.codsupervisor
          INTO vncodsupervisor
          FROM pcusuari p
         WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;
      EXCEPTION
        WHEN OTHERS THEN
          vncodsupervisor := NULL;
      END;

      -- Verifica se já gravou a Tabela Auxiliar
      BEGIN
        SELECT 'S'
          INTO vvGravouTabAux
          FROM pclogrcaprodmed
         WHERE (numtransvenda = p_numtransvenda)
           AND (rotina        = p_rotinalanc)
           AND (rownum        = 1);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvGravouTabAux := 'N';
      END;

      -- Se ainda não gravou a Tabela Auxiliar
      IF (vvGravouTabAux = 'N') THEN

        -- Inicializa o Valor Total do Lançamento e Transferência
        vnvalorlanc   := 0;
        vnValorTransf := 0;

        -- Processamento dos Itens da Nota Fiscal
        FOR vc_ItensNotaFiscal IN (SELECT PCMOVPREFAT.codprod, PCMOVPREFAT.numseq, PCMOVPREFAT.qt
                                      FROM PCMOVPREFAT, PCNFSAIDPREFAT, PCMOVCOMPLEPREFAT
                                    WHERE PCMOVPREFAT.numtransvenda = p_numtransvenda
                                      AND PCMOVPREFAT.numtransvenda = PCNFSAIDPREFAT.numtransvenda
                                       AND PCMOVPREFAT.NUMTRANSITEM = PCMOVCOMPLEPREFAT.NUMTRANSITEM(+)
                                      AND NVL(PCMOVPREFAT.qt, 0) > 0
                                         -- Tarefa 103974 Tarefa 109141 Incluído o condvenda 20 para consideração do campo punitcont conforem solicitado
                                       AND decode(nvl(PCMOVCOMPLEPREFAT.bonific, 'N'),
                                                  'F',
                                                  PCMOVPREFAT.punitcont,
                                                  DECODE(PCNFSAIDPREFAT.condvenda,
                                                 5,
                                                 NVL(PCMOVPREFAT.punitcont, 0),
                                                 8,
                                                 NVL(PCMOVPREFAT.punitcont, 0),
                                                 11,
                                                 NVL(PCMOVPREFAT.punitcont, 0), -- Tarefa 114710
                                                 13,
                                                 NVL(PCMOVPREFAT.punitcont, 0),
                                                 20,
                                                 NVL(PCMOVPREFAT.punitcont, 0),
                                                         NVL(PCMOVPREFAT.punit, 0))) > 0 -- sabrina (teste de item gerencial)

                                   /*MED-2277*/
                                   UNION
                                        SELECT PCMOV.codprod, PCMOV.numseq, PCMOV.qt
                                          FROM PCMOV, PCNFSAID, PCMOVCOMPLE
                                    WHERE PCMOV.numtransvenda = p_numtransvenda
                                      AND PCMOV.numtransvenda = PCNFSAID.numtransvenda
                                           AND PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM(+)
                                      AND NVL(PCMOV.qt, 0) > 0
                                         -- Tarefa 103974 Tarefa 109141 Incluído o condvenda 20 para consideração do campo punitcont conforem solicitado
                                           AND decode(nvl(PCMOVCOMPLE.bonific, 'N'),
                                                      'F',
                                                      PCMOV.punitcont,
                                                      DECODE(PCNFSAID.condvenda,
                                                 5,
                                                 NVL(PCMOV.punitcont, 0),
                                                 8,
                                                 NVL(PCMOV.punitcont, 0),
                                                 11,
                                                 NVL(PCMOV.punitcont, 0), -- Tarefa 114710
                                                 13,
                                                 NVL(PCMOV.punitcont, 0),
                                                 20,
                                                 NVL(PCMOV.punitcont, 0),
                                                      NVL(PCMOV.punit, 0))) > 0 -- sabrina (teste de item gerencial)
                                  ) LOOP

          -- Valor do Lançamento DO PRODUTO
          vnValorLancProduto := ccrca_retornar_saldo_item_nf(p_numtransvenda,
                                                             vc_ItensNotaFiscal.codprod, -->> CODPROD DO LAÇO
                                                             vc_ItensNotaFiscal.numseq,  -->> NUMSEQ DO LAÇO
                                                             vc_ItensNotaFiscal.qt,      -->> QTDE DO LAÇO
                                                             'I', -- incluido por sabrina
                                                             p_rotinalanc,
                                                             nPERCRATEIOCREDRCASUPERVISOR);

          -- Busca informações na PCMOVCOMPLEPREFAT
          BEGIN
            SELECT PCMOVPREFAT.punit
                 , PCMOVPREFAT.st
                 , PCMOVPREFAT.pbaserca
                 , PCMOVCOMPLEPREFAT.stpbaserca
                 , PCMOVPREFAT.ptabela
                 , PCMOVCOMPLEPREFAT.stptabela
                 , PCMOVCOMPLEPREFAT.bonific
                 , vc_ItensNotaFiscal.qt -- Quantidade definida nesta Proc. -->> QTDE DO LAÇO
                 , PCMOVPREFAT.usadebcredrcabrind
                 , PCMOVPREFAT.movimentacontacorrenterca
                 , PCMOVCOMPLEPREFAT.codpromocaomed
              INTO vrItem.nPVENDA
                 , vrItem.nST
                 , vrItem.nPBASERCA
                 , vrItem.nSTPBASERCA
                 , vrItem.nPTABELA
                 , vrItem.nSTPTABELA
                 , vrItem.nBONIFIC
                 , vrItem.nQT
                 , vrItem.vUSADEBCREDRCABRIND
                 , vrItem.vMOVIMENTACONTACORRENTERCA
                 , vrItem.nCODPROMOCAOMED
              FROM PCMOVPREFAT,
                   PCMOVCOMPLEPREFAT
             WHERE (PCMOVPREFAT.numtransvenda = p_numtransvenda)
               AND (PCMOVPREFAT.codprod       = vc_ItensNotaFiscal.codprod) -->> CODPROD DO LAÇO
               AND (PCMOVPREFAT.numseq        = vc_ItensNotaFiscal.numseq)  -->> NUMSEQ DO LAÇO
               AND (PCMOVPREFAT.qt            > 0)
               AND (PCMOVPREFAT.numtransitem  = PCMOVCOMPLEPREFAT.numtransitem(+));
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vrItem.nPVENDA                    := NULL;
              vrItem.nST                        := NULL;
              vrItem.nPBASERCA                  := NULL;
              vrItem.nSTPBASERCA                := NULL;
              vrItem.nPTABELA                   := NULL;
              vrItem.nSTPTABELA                 := NULL;
              vrItem.nBONIFIC                   := 'N';
              vrItem.nQT                        := NULL;
              vrItem.vUSADEBCREDRCABRIND        := NULL;
              vrItem.vMOVIMENTACONTACORRENTERCA := NULL;
              vrItem.nCODPROMOCAOMED            := NULL;
          END;

          -- Insere em Tabela Auxiliar o que não será mais gravado por Produto na PCLOGRCA
          INSERT INTO pclogrcaprodmed
              (numped,
               posicao,
               numtransvenda,
               DATA,
               codfunc,
               codusur,
               rotina,
               vlsaldorca,
               codprod,
               numseq,
               historico,
               PVENDA,
               ST,
               PBASERCA,
               STPBASERCA,
               PTABELA,
               STPTABELA,
               BONIFIC,
               QT,
               USADEBCREDRCABRIND,
               MOVIMENTACONTACORRENTERCA,
               CODPROMOCAOMED,
               PERCRATEIOCREDRCASUPERVISOR)
            VALUES
              (vnnumped,
               vsposicao,
               p_numtransvenda,
               SYSDATE,
               p_codfunclanc,
               vncodusur, -- HIS.00632.2016 -- p_codusur,
               p_rotinalanc,
               vnValorLancProduto,         -->> VALOR DO LANÇAMENTO DO PRODUTO
               vc_ItensNotaFiscal.codprod, -->> CODPROD DO LAÇO
               vc_ItensNotaFiscal.numseq,  -->> NUMSEQ DO LAÇO
               SUBSTR('CTRLCCRCA: LANCAMENTO SALDO ITEM TRANS. VENDA', 1, 60),
               vrItem.nPVENDA,
               vrItem.nST,
               vrItem.nPBASERCA,
               vrItem.nSTPBASERCA,
               vrItem.nPTABELA,
               vrItem.nSTPTABELA,
               vrItem.nBONIFIC,
               vrItem.nQT,
               vrItem.vUSADEBCREDRCABRIND,
               vrItem.vMOVIMENTACONTACORRENTERCA,
               vrItem.nCODPROMOCAOMED,
               nPERCRATEIOCREDRCASUPERVISOR);

          -- Acumula o Valor do Lançamento
          vnvalorlanc := NVL(vnvalorlanc,0) + NVL(vnValorLancProduto,0);

          ------------------------------------------------
          -- Se houver Rateio de Crédito de C/C RCA
          -- E estiver chamando da Inclusão da Nota Fiscal
          ------------------------------------------------
          IF (F_USARATEIOCREDRCASUPERVISOR(vncodusur,
                                           NVL(nPERCRATEIOCREDRCASUPERVISOR,0),
                                           NVL(vnValorLancProduto,0))) AND
             (p_rotinalanc IN (1400)) THEN

            -- Pesquisa o RCA vinculado ao Supervisor
            BEGIN
              SELECT PCUSUARI.CODUSUR
                INTO vncod_cadrca_supervisor
                FROM PCSUPERV
                   , PCUSUARI
               WHERE (PCSUPERV.CODSUPERVISOR = vncodsupervisor)
                 AND (PCUSUARI.CODUSUR       = PCSUPERV.COD_CADRCA);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vncod_cadrca_supervisor := NULL;
            END;

            -- Pesquisa o RCA vinculado a Empresa
            vncod_cadrca_empresa := F_OBTER_RCA_EMPRESA;

            -- Se o Supervisor movimenta C/C
            IF (NVL(vncod_cadrca_supervisor,0) > 0) THEN

              -- Valor da Transferência - Diferença do % que ficará com o RCA
              vnValorTransfProduto := ROUND(NVL(vnValorLancProduto,0) * (1 - (NVL(nPERCRATEIOCREDRCASUPERVISOR,0) / 100)),2);

              -- DEBITANDO RCA ---------------------------------------------------------------
              IF (NVL(vnValorTransfProduto,0) > 0) THEN

                -- Insere em Tabela Auxiliar o que não será mais gravado por Produto na PCLOGRCA
                INSERT INTO pclogrcaprodmed
                    (numped,
                     posicao,
                     numtransvenda,
                     DATA,
                     codfunc,
                     codusur,
                     rotina,
                     vlsaldorca,
                     codprod,
                     numseq,
                     historico,
                     PVENDA,
                     ST,
                     PBASERCA,
                     STPBASERCA,
                     PTABELA,
                     STPTABELA,
                     BONIFIC,
                     QT,
                     USADEBCREDRCABRIND,
                     MOVIMENTACONTACORRENTERCA,
                     CODPROMOCAOMED,
                     PERCRATEIOCREDRCASUPERVISOR)
                  VALUES
                    (vnnumped,
                     vsposicao,
                     p_numtransvenda,
                     SYSDATE,
                     p_codfunclanc,
                     vncodusur, -- HIS.00632.2016 -- p_codusur,
                     p_rotinalanc,
                     vnValorTransfProduto * (-1), -->> VALOR DA TRANSFERÊNCIA DO PRODUTO NEGATIVO PORQUE SERÁ DÉBITO DO RCA
                     vc_ItensNotaFiscal.codprod,  -->> CODPROD DO LAÇO
                     vc_ItensNotaFiscal.numseq,   -->> NUMSEQ DO LAÇO
                     SUBSTR('CTRLCCRCA: LANCAMENTO RATEIO RCA ITEM TRANS. VENDA', 1, 60),
                     vrItem.nPVENDA,
                     vrItem.nST,
                     vrItem.nPBASERCA,
                     vrItem.nSTPBASERCA,
                     vrItem.nPTABELA,
                     vrItem.nSTPTABELA,
                     vrItem.nBONIFIC,
                     vrItem.nQT,
                     vrItem.vUSADEBCREDRCABRIND,
                     vrItem.vMOVIMENTACONTACORRENTERCA,
                     vrItem.nCODPROMOCAOMED,
                     nPERCRATEIOCREDRCASUPERVISOR);

                -- Acumula o Valor do Lançamento
                vnValorTransf := NVL(vnValorTransf,0) + NVL(vnValorTransfProduto,0);

              END IF; -- Fim Condição: DEBITANDO RCA

             /*******************************
              A PARTE DO SUPERVISOR E EMPRESA
                 SERÁ SEMPRE NO FATURAMENTO
                  (Executa sem Restrições)
              *******************************/

              -- RATEIO ENTRE SUPERVISOR E EMPRESA ------------------------------------------------------

              -- Obter % Rateio de Crédito de C/C Supervisor e Empresa
              nPERCRATEIOCREDSUPERVEMPRESA := F_PERCRATEIOCREDSUPERVEMPRESA;

              ------------------------------------------------------------
              -- Se houver Rateio de Crédito de C/C Supervisor com Empresa
              ------------------------------------------------------------
              IF (F_USARATEIOCREDSUPERVEMPRESA(vncod_cadrca_empresa,
                                               nPERCRATEIOCREDSUPERVEMPRESA,
                                               vnValorTransfProduto)) THEN
                -- Calcula a parte do Supervisor
                vnValorTransfSupervisorProd := ROUND(vnValorTransfProduto * (NVL(nPERCRATEIOCREDSUPERVEMPRESA,0) / 100),2);
                -- Calcula a parte da Empresa
                vnValorTransfEmpresaProd    := (NVL(vnValorTransfProduto,0) - NVL(vnValorTransfSupervisorProd,0));
              ELSE
                -- Somente tem a parte do Supervisor
                vnValorTransfSupervisorProd := vnValorTransfProduto;
                -- Não tem a parte da Empresa
                vnValorTransfEmpresaProd    := 0;
              END IF;

              -- CREDITANDO SUPERVISOR ------------------------------------------------------------------
              IF (NVL(vnValorTransfSupervisorProd,0) > 0) THEN

                INSERT INTO pclogrcaprodmed
                  (numped,
                   posicao,
                   numtransvenda,
                   DATA,
                   codfunc,
                   codusur,
                   rotina,
                   vlsaldorca,
                   codprod,
                   numseq,
                   historico,
                   PERCRATEIOCREDRCASUPERVISOR)
                VALUES
                  (vnnumped,
                   vsposicao,
                   p_numtransvenda,
                   SYSDATE,
                   p_codfunclanc,
                   vncod_cadrca_supervisor, -- SUPERVISOR
                   p_rotinalanc,
                   vnValorTransfSupervisorProd, -->> VALOR DA TRANSFERÊNCIA DO PRODUTO PARA O SUPERVISOR
                   vc_ItensNotaFiscal.codprod,  -->> CODPROD DO LAÇO
                   vc_ItensNotaFiscal.numseq,   -->> NUMSEQ DO LAÇO
                   SUBSTR('CTRLCCRCA: LANCAMENTO RATEIO SUPERV. ITEM TRANS. VENDA', 1, 60), -->> LANÇAMENTO RATEIO TOTAL DA TRANSAÇÃO
                   nPERCRATEIOCREDRCASUPERVISOR);

              END IF; -- Fim Condição: CREDITANDO SUPERVISOR

              -- CREDITANDO EMPRESA ---------------------------------------------------------------------
              IF (NVL(vncod_cadrca_empresa,0) > 0)     AND
                 (NVL(vnValorTransfEmpresaProd,0) > 0) THEN

                INSERT INTO pclogrcaprodmed
                  (numped,
                   posicao,
                   numtransvenda,
                   DATA,
                   codfunc,
                   codusur,
                   rotina,
                   vlsaldorca,
                   codprod,
                   numseq,
                   historico,
                   PERCRATEIOCREDRCASUPERVISOR)
                VALUES
                  (vnnumped,
                   vsposicao,
                   p_numtransvenda,
                   SYSDATE,
                   p_codfunclanc,
                   vncod_cadrca_empresa, -- EMPRESA
                   p_rotinalanc,
                   vnValorTransfEmpresaProd,    -->> VALOR DA TRANSFERÊNCIA DO PRODUTO PARA A EMPRESA
                   vc_ItensNotaFiscal.codprod,  -->> CODPROD DO LAÇO
                   vc_ItensNotaFiscal.numseq,   -->> NUMSEQ DO LAÇO
                   SUBSTR('CTRLCCRCA: LANCAMENTO RATEIO EMPRESA ITEM TRANS. VENDA', 1, 60), -->> LANÇAMENTO RATEIO TOTAL DA TRANSAÇÃO
                   nPERCRATEIOCREDSUPERVEMPRESA);

              END IF; -- Fim Condição: CREDITANDO EMPRESA

            END IF; -- Se o Supervisor movimenta C/C

          END IF; -- Fim Condição: Rateio

        END LOOP; -- FIM: Processamento dos Itens da Nota Fiscal




       /********************************************************************
        SE O RATEIO OCORRE PELO CREDITO DE SALDO DO PEDIDO E NÃO PELOS ITENS
                             < PROCESSO ESPECÍFICO >
        ********************************************************************/
        IF (F_TIPOSALDORESERVADOPEDIDOFAT = '3') THEN

          -- Valor da Transferência - Diferença do % que ficará com o RCA
          vnValorTransf := ROUND(NVL(vnvalorlanc,0) * (1 - (NVL(nPERCRATEIOCREDRCASUPERVISOR,0) / 100)),2);

        END IF;




        -- Pesquisa Saldo do RCA
        BEGIN
          SELECT p.vlcorrente, p.vllimcred, p.codsupervisor
            INTO vnvlcorrente_ant, vnvllimcred, vncodsupervisor
            FROM pcusuari p
           WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;
        EXCEPTION
          WHEN OTHERS THEN
            vbvalido := FALSE;
        END;

        IF vbvalido = TRUE THEN

          vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) + NVL(vnvalorlanc, 0);

          -- a package não deve barrar a movimentacao do saldo, os programas eh que fazem isso
          --IF vnvlcorrente_atual >= 0 THEN
          UPDATE pcusuari
             SET vlcorrente = vnvlcorrente_atual
           WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;

          INSERT INTO pclogrca
            (numped,
             posicao,
             numtransvenda,
             DATA,
             codfunc,
             codusur,
             rotina,
             vlcorrente,
             vllimcred,
             vlcorrenteant,
             vllimcredant,
             codprod,
             numseq,
             historico,
             PERCRATEIOCREDRCASUPERVISOR)
          VALUES
            (vnnumped,
             vsposicao,
             p_numtransvenda,
             SYSDATE,
             p_codfunclanc,
             vncodusur, -- HIS.00632.2016 -- p_codusur,
             p_rotinalanc,
             vnvlcorrente_atual,
             vnvllimcred,
             vnvlcorrente_ant,
             vnvllimcred,
             0, -->> SEM CODPROD
             0, -->> SEM NUMSEQ
             SUBSTR('CTRLCCRCA: LANCAMENTO SALDO TRANS. VENDA', 1, 60), -->> LANÇAMENTO TOTAL DA TRANSAÇÃO
             nPERCRATEIOCREDRCASUPERVISOR);

          ------------------------------------------------
          -- Se houver Rateio de Crédito de C/C RCA
          -- JÁ ESTÁ ACUMULADO NA VARIÁVEL vnValorTransf
          ------------------------------------------------
          IF (NVL(vnValorTransf,0) > 0) THEN

            -- Pesquisa o RCA vinculado ao Supervisor
            BEGIN
              SELECT PCUSUARI.CODUSUR
                INTO vncod_cadrca_supervisor
                FROM PCSUPERV
                   , PCUSUARI
               WHERE (PCSUPERV.CODSUPERVISOR = vncodsupervisor)
                 AND (PCUSUARI.CODUSUR       = PCSUPERV.COD_CADRCA);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vncod_cadrca_supervisor := NULL;
            END;

            -- Pesquisa o RCA vinculado a Empresa
            vncod_cadrca_empresa := F_OBTER_RCA_EMPRESA;

            -- Se o Supervisor movimenta C/C
            IF (NVL(vncod_cadrca_supervisor,0) > 0) THEN

              -- Valor da Transferência - Diferença do % que ficará com o RCA
              -- JÁ ESTÁ ACUMULADO NA VARIÁVEL vnValorTransf

              -- DEBITANDO RCA --------------------------------------------------------------------------
              IF (NVL(vnValorTransf,0) > 0) THEN

                SELECT pcusuari.vlcorrente, pcusuari.vllimcred
                  INTO vnvlcorrente_ant, vnvllimcred
                  FROM pcusuari
                 WHERE codusur = vncodusur; -- RCA

                vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) - NVL(vnValorTransf, 0); -- DEDUZINDO VALOR TRANSF.

                UPDATE pcusuari
                   SET vlcorrente = vnvlcorrente_atual
                 WHERE codusur = vncodusur; -- RCA

                INSERT INTO pclogrca
                  (numped,
                   posicao,
                   numtransvenda,
                   DATA,
                   codfunc,
                   codusur,
                   rotina,
                   vlcorrente,
                   vllimcred,
                   vlcorrenteant,
                   vllimcredant,
                   codprod,
                   numseq,
                   historico,
                   PERCRATEIOCREDRCASUPERVISOR)
                VALUES
                  (vnnumped,
                   vsposicao,
                   p_numtransvenda,
                   SYSDATE,
                   p_codfunclanc,
                   vncodusur, -- RCA
                   p_rotinalanc,
                   vnvlcorrente_atual,
                   vnvllimcred,
                   vnvlcorrente_ant,
                   vnvllimcred,
                   0, -->> SEM CODPROD
                   0, -->> SEM NUMSEQ
                   SUBSTR('CTRLCCRCA: LANCAMENTO RATEIO RCA TRANS. VENDA', 1, 60), -->> LANÇAMENTO RATEIO TOTAL DA TRANSAÇÃO
                   nPERCRATEIOCREDRCASUPERVISOR);

               /*******************************
                A PARTE DO SUPERVISOR E EMPRESA
                   SERÁ SEMPRE NO FATURAMENTO
                    (Executa sem Restrições)
                *******************************/

                -- RATEIO ENTRE SUPERVISOR E EMPRESA ------------------------------------------------------

                -- Obter % Rateio de Crédito de C/C Supervisor e Empresa
                nPERCRATEIOCREDSUPERVEMPRESA := F_PERCRATEIOCREDSUPERVEMPRESA;

                ------------------------------------------------------------
                -- Se houver Rateio de Crédito de C/C Supervisor com Empresa
                ------------------------------------------------------------
                IF (F_USARATEIOCREDSUPERVEMPRESA(vncod_cadrca_empresa,
                                                 nPERCRATEIOCREDSUPERVEMPRESA,
                                                 vnValorTransf)) THEN
                  -- Calcula a parte do Supervisor
                  vnValorTransfSupervisor := ROUND(vnValorTransf * (NVL(nPERCRATEIOCREDSUPERVEMPRESA,0) / 100),2);
                  -- Calcula a parte da Empresa
                  vnValorTransfEmpresa    := (NVL(vnValorTransf,0) - NVL(vnValorTransfSupervisor,0));
                ELSE
                  -- Somente tem a parte do Supervisor
                  vnValorTransfSupervisor := vnValorTransf;
                  -- Não tem a parte da Empresa
                  vnValorTransfEmpresa    := 0;
                END IF;

                -- CREDITANDO SUPERVISOR ------------------------------------------------------------------
                IF (NVL(vnValorTransfSupervisor,0) > 0) THEN

                  SELECT pcusuari.vlcorrente, pcusuari.vllimcred
                    INTO vnvlcorrente_ant, vnvllimcred
                    FROM pcusuari
                   WHERE codusur = vncod_cadrca_supervisor; -- SUPERVISOR

                  vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) + NVL(vnValorTransfSupervisor, 0); -- INCREMENTANDO VALOR TRANSF.

                  UPDATE pcusuari
                     SET vlcorrente = vnvlcorrente_atual
                   WHERE codusur = vncod_cadrca_supervisor; -- SUPERVISOR

                  INSERT INTO pclogrca
                    (numped,
                     posicao,
                     numtransvenda,
                     DATA,
                     codfunc,
                     codusur,
                     rotina,
                     vlcorrente,
                     vllimcred,
                     vlcorrenteant,
                     vllimcredant,
                     codprod,
                     numseq,
                     historico,
                     PERCRATEIOCREDRCASUPERVISOR)
                  VALUES
                    (vnnumped,
                     vsposicao,
                     p_numtransvenda,
                     SYSDATE,
                     p_codfunclanc,
                     vncod_cadrca_supervisor, -- SUPERVISOR
                     p_rotinalanc,
                     vnvlcorrente_atual,
                     vnvllimcred,
                     vnvlcorrente_ant,
                     vnvllimcred,
                     0, -->> SEM CODPROD
                     0, -->> SEM NUMSEQ
                     SUBSTR('CTRLCCRCA: LANCAMENTO RATEIO SUPERV. TRANS. VENDA', 1, 60), -->> LANÇAMENTO RATEIO TOTAL DA TRANSAÇÃO
                     nPERCRATEIOCREDRCASUPERVISOR);

                END IF; -- Fim Condição: CREDITANDO SUPERVISOR

                -- CREDITANDO EMPRESA ---------------------------------------------------------------------
                IF (NVL(vncod_cadrca_empresa,0) > 0) AND
                   (NVL(vnValorTransfEmpresa,0) > 0) THEN

                  SELECT pcusuari.vlcorrente, pcusuari.vllimcred
                    INTO vnvlcorrente_ant, vnvllimcred
                    FROM pcusuari
                   WHERE codusur = vncod_cadrca_empresa; -- EMPRESA

                  vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) + NVL(vnValorTransfEmpresa, 0); -- INCREMENTANDO VALOR TRANSF.

                  UPDATE pcusuari
                     SET vlcorrente = vnvlcorrente_atual
                   WHERE codusur = vncod_cadrca_empresa; -- EMPRESA

                  INSERT INTO pclogrca
                    (numped,
                     posicao,
                     numtransvenda,
                     DATA,
                     codfunc,
                     codusur,
                     rotina,
                     vlcorrente,
                     vllimcred,
                     vlcorrenteant,
                     vllimcredant,
                     codprod,
                     numseq,
                     historico,
                     PERCRATEIOCREDRCASUPERVISOR)
                  VALUES
                    (vnnumped,
                     vsposicao,
                     p_numtransvenda,
                     SYSDATE,
                     p_codfunclanc,
                     vncod_cadrca_empresa, -- EMPRESA
                     p_rotinalanc,
                     vnvlcorrente_atual,
                     vnvllimcred,
                     vnvlcorrente_ant,
                     vnvllimcred,
                     0, -->> SEM CODPROD
                     0, -->> SEM NUMSEQ
                     SUBSTR('CTRLCCRCA: LANCAMENTO RATEIO EMPRESA TRANS. VENDA', 1, 60), -->> LANÇAMENTO RATEIO TOTAL DA TRANSAÇÃO
                     nPERCRATEIOCREDSUPERVEMPRESA);

                END IF; -- Fim Condição: CREDITANDO EMPRESA

              END IF; -- Fim Condição: DEBITANDO RCA

            END IF; -- Fim Condição Se o Supervisor movimenta C/C
          END IF; -- Fim Condição Rateio Saldo C/C

        END IF; -- Fim Condição: vbvalido = TRUE

      END IF; -- Fim: Se ainda não gravou a Tabela Auxiliar

    ---------------------------------------------------------------------------------------------
    -- Padrão Pacote
    ---------------------------------------------------------------------------------------------
    ELSE

      -- alterado por sabrina (quantidade do item de nf vem do PCMOVPREFAT)
      BEGIN
        SELECT PCMOVPREFAT.qt
          INTO vnqt
          FROM PCMOVPREFAT, PCNFSAIDPREFAT, PCMOVCOMPLEPREFAT
         WHERE PCMOVPREFAT.numtransvenda = p_numtransvenda
           AND PCMOVPREFAT.numtransvenda = PCNFSAIDPREFAT.numtransvenda
           AND PCMOVPREFAT.numtransitem = PCMOVCOMPLEPREFAT.numtransitem (+) -- DDVENDAS-41579
           AND PCMOVPREFAT.codprod = p_codprod
           AND PCMOVPREFAT.numseq = p_numseq
           AND NVL(PCMOVPREFAT.qt, 0) > 0
              -- Tarefa 103974 Tarefa 109141 Incluído o condvenda 20 para consideração do campo punitcont conforem solicitado
           AND DECODE(nvl(PCMOVCOMPLEPREFAT.bonific, 'N'),
                                                     'F',
                                                     PCMOVPREFAT.punitcont, DECODE( -- DDVENDAS-41579
                      PCNFSAIDPREFAT.condvenda,
                      5,
                      NVL(PCMOVPREFAT.punitcont, 0),
                      8,
                      NVL(PCMOVPREFAT.punitcont, 0),
                      11,
                      NVL(PCMOVPREFAT.punitcont, 0), -- Tarefa 114710
                      13,
                      NVL(PCMOVPREFAT.punitcont, 0),
                      20,
                      NVL(PCMOVPREFAT.punitcont, 0),
                      NVL(PCMOVPREFAT.punit, 0)
                      ) -- DDVENDAS-41579

                      ) > 0; -- sabrina (teste de item gerencial)
      EXCEPTION
        WHEN OTHERS THEN
          vbvalido := FALSE;
      END;

      /*MED-2277*/
      IF vbvalido = FALSE THEN
        BEGIN
          SELECT PCMOV.qt
            INTO vnqt
            FROM PCMOV, PCNFSAID, PCMOVCOMPLE
           WHERE PCMOV.numtransvenda = p_numtransvenda
             AND PCMOV.numtransvenda = PCNFSAID.numtransvenda
             AND PCMOV.numtransitem = PCMOVCOMPLE.numtransitem (+) -- DDVENDAS-41579
             AND PCMOV.codprod = p_codprod
             AND PCMOV.numseq = p_numseq
             AND NVL(PCMOV.qt, 0) > 0
                -- Tarefa 103974 Tarefa 109141 Incluído o condvenda 20 para consideração do campo punitcont conforem solicitado
             AND DECODE(nvl(PCMOVCOMPLE.bonific, 'N'),
                                           'F',
                                           PCMOV.punitcont, DECODE ( -- DDVENDAS-41579
                        PCNFSAID.condvenda,
                        5,
                        NVL(PCMOV.punitcont, 0),
                        8,
                        NVL(PCMOV.punitcont, 0),
                        11,
                        NVL(PCMOV.punitcont, 0), -- Tarefa 114710
                        13,
                        NVL(PCMOV.punitcont, 0),
                        20,
                        NVL(PCMOV.punitcont, 0),
                        NVL(PCMOV.punit, 0)
                        ) -- DDVENDAS-41579
                        ) > 0; -- sabrina (teste de item gerencial)

          vbvalido := TRUE;
        EXCEPTION
          WHEN OTHERS THEN
            vbvalido := FALSE;
        END;
      END IF;

      BEGIN
        SELECT p.vlcorrente, p.vllimcred, p.codsupervisor
          INTO vnvlcorrente_ant, vnvllimcred, vncodsupervisor
          FROM pcusuari p
         WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;
      EXCEPTION
        WHEN OTHERS THEN
          vbvalido := FALSE;
      END;

      IF vbvalido = TRUE THEN

        BEGIN
          SELECT PCMOVPREFAT.punit
               , PCMOVPREFAT.st
               , PCMOVPREFAT.pbaserca
               , PCMOVCOMPLEPREFAT.stpbaserca
               , PCMOVPREFAT.ptabela
               , PCMOVCOMPLEPREFAT.stptabela
               , PCMOVCOMPLEPREFAT.bonific
               , vnqt -- Quantidade definida nesta Proc.
               , PCMOVPREFAT.usadebcredrcabrind
               , PCMOVPREFAT.movimentacontacorrenterca
               , PCMOVCOMPLEPREFAT.codpromocaomed
            INTO vrItem.nPVENDA
               , vrItem.nST
               , vrItem.nPBASERCA
               , vrItem.nSTPBASERCA
               , vrItem.nPTABELA
               , vrItem.nSTPTABELA
               , vrItem.nBONIFIC
               , vrItem.nQT
               , vrItem.vUSADEBCREDRCABRIND
               , vrItem.vMOVIMENTACONTACORRENTERCA
               , vrItem.nCODPROMOCAOMED
            FROM PCMOVPREFAT,
                 PCMOVCOMPLEPREFAT
           WHERE (PCMOVPREFAT.numtransvenda = p_numtransvenda)
             AND (PCMOVPREFAT.codprod       = p_codprod)
             AND (PCMOVPREFAT.numseq        = p_numseq)
             AND (PCMOVPREFAT.qt            > 0)
             AND (PCMOVPREFAT.numtransitem  = PCMOVCOMPLEPREFAT.numtransitem(+));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vrItem.nPVENDA                    := NULL;
            vrItem.nST                        := NULL;
            vrItem.nPBASERCA                  := NULL;
            vrItem.nSTPBASERCA                := NULL;
            vrItem.nPTABELA                   := NULL;
            vrItem.nSTPTABELA                 := NULL;
            vrItem.nBONIFIC                   := 'N';
            vrItem.nQT                        := NULL;
            vrItem.vUSADEBCREDRCABRIND        := NULL;
            vrItem.vMOVIMENTACONTACORRENTERCA := NULL;
            vrItem.nCODPROMOCAOMED            := NULL;
        END;

        vnvalorlanc        := ccrca_retornar_saldo_item_nf(p_numtransvenda,
                                                           p_codprod,
                                                           p_numseq,
                                                           vnqt,
                                                           'I', -- incluido por sabrina
                                                           p_rotinalanc,
                                                           nPERCRATEIOCREDRCASUPERVISOR);

        -- SOMENTE SE NÃO FOR LIQUIDEZ
        IF (NVL(vstipomovccrca,' ') <> 'LL') THEN

          -- Como o Rateio força a chamar no Faturamento este procedimento SEMPRE,
          -- precisei isolar a parte que já foi feita na Inclusão do Pedido
          IF ((vstipomovccrca = 'VF') OR (vstipomovccrca = 'FF')) THEN

            vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) + NVL(vnvalorlanc, 0);

            -- a package não deve barrar a movimentacao do saldo, os programas eh que fazem isso
            --IF vnvlcorrente_atual >= 0 THEN
            UPDATE pcusuari
               SET vlcorrente = vnvlcorrente_atual
             WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;

            INSERT INTO pclogrca
              (numped,
               posicao,
               numtransvenda,
               DATA,
               codfunc,
               codusur,
               rotina,
               vlcorrente,
               vllimcred,
               vlcorrenteant,
               vllimcredant,
               codprod,
               numseq,
               historico,
               PVENDA,
               ST,
               PBASERCA,
               STPBASERCA,
               PTABELA,
               STPTABELA,
               BONIFIC,
               QT,
               USADEBCREDRCABRIND,
               MOVIMENTACONTACORRENTERCA,
               CODPROMOCAOMED,
               PERCRATEIOCREDRCASUPERVISOR)
            VALUES
              (vnnumped,
               vsposicao,
               p_numtransvenda,
               SYSDATE,
               p_codfunclanc,
               vncodusur, -- HIS.00632.2016 -- p_codusur,
               p_rotinalanc,
               vnvlcorrente_atual,
               vnvllimcred,
               vnvlcorrente_ant,
               vnvllimcred,
               p_codprod,
               p_numseq,
               SUBSTR('CTRLCCRCA: LANCAMENTO SALDO ITEM TRANS. VENDA', 1, 60),
               vrItem.nPVENDA,
               vrItem.nST,
               vrItem.nPBASERCA,
               vrItem.nSTPBASERCA,
               vrItem.nPTABELA,
               vrItem.nSTPTABELA,
               vrItem.nBONIFIC,
               vrItem.nQT,
               vrItem.vUSADEBCREDRCABRIND,
               vrItem.vMOVIMENTACONTACORRENTERCA,
               vrItem.nCODPROMOCAOMED,
               nPERCRATEIOCREDRCASUPERVISOR);
            --ELSE
            --vbvalido := FALSE;
            --END IF;

          END IF; -- Fim: ((vstipomovccrca = 'VF') OR (vstipomovccrca = 'FF'))

          -- Se não ocorreu Débito/Crédito no Faturamento,
          -- calcula o valor do Lançamento do Pedido,
          -- para poder finalizar o resto do rateio no Faturamento,
          -- que foi retirado do Pedido por causa dos Locks
          IF (F_RATEIOCREDRCASUPERV_ATIVO) THEN
            IF (NVL(vnvalorlanc,0) = 0) THEN
                vnvalorlanc := ccrca_retornar_saldo_itepedfat(vnnumped,
                                                              vncodusur, -- HIS.00632.2016 -- p_codusur,
                                                              p_codprod,
                                                              p_numseq,
                                                              vnqt,
                                                              'I',
                                                              p_rotinalanc,
                                                              nPERCRATEIOCREDRCASUPERVISOR);
            END IF;
          END IF;

          ------------------------------------------------
          -- Se houver Rateio de Crédito de C/C RCA
          -- E estiver chamando da Inclusão da Nota Fiscal
          ------------------------------------------------
          IF (F_USARATEIOCREDRCASUPERVISOR(vncodusur,
                                           NVL(nPERCRATEIOCREDRCASUPERVISOR,0),
                                           NVL(vnvalorlanc,0))) AND
             (p_rotinalanc IN (1400)) THEN

            -- Pesquisa o RCA vinculado ao Supervisor
            BEGIN
              SELECT PCUSUARI.CODUSUR
                INTO vncod_cadrca_supervisor
                FROM PCSUPERV
                   , PCUSUARI
               WHERE (PCSUPERV.CODSUPERVISOR = vncodsupervisor)
                 AND (PCUSUARI.CODUSUR       = PCSUPERV.COD_CADRCA);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vncod_cadrca_supervisor := NULL;
            END;

            -- Pesquisa o RCA vinculado a Empresa
            vncod_cadrca_empresa := F_OBTER_RCA_EMPRESA;

            -- Se o Supervisor movimenta C/C
            IF (NVL(vncod_cadrca_supervisor,0) > 0) THEN

              -- Valor da Transferência - Diferença do % que ficará com o RCA
              vnValorTransf := ROUND(NVL(vnvalorlanc,0) * (1 - (NVL(nPERCRATEIOCREDRCASUPERVISOR,0) / 100)),2);

              -- DEBITANDO RCA --------------------------------------------------------------------------
              IF (NVL(vnValorTransf,0) > 0) THEN

                -- Como o Rateio força a chamar no Faturamento este procedimento SEMPRE,
                -- precisei isolar para não fazer novamente a parte que já foi feita na Inclusão do Pedido
                -- (SOMENTE EXECUTAR A PARTE DO RCA SE CREDITO OU DEBITO NO FATURAMENTO)
                IF ((vstipomovccrca = 'VF') OR (vstipomovccrca = 'FF')) THEN

                  SELECT pcusuari.vlcorrente, pcusuari.vllimcred
                    INTO vnvlcorrente_ant, vnvllimcred
                    FROM pcusuari
                   WHERE codusur = vncodusur; -- RCA

                  vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) - NVL(vnValorTransf, 0); -- DEDUZINDO VALOR TRANSF.

                  UPDATE pcusuari
                     SET vlcorrente = vnvlcorrente_atual
                   WHERE codusur = vncodusur; -- RCA

                  INSERT INTO pclogrca
                    (numped,
                     posicao,
                     numtransvenda,
                     DATA,
                     codfunc,
                     codusur,
                     rotina,
                     vlcorrente,
                     vllimcred,
                     vlcorrenteant,
                     vllimcredant,
                     codprod,
                     numseq,
                     historico,
                     PVENDA,
                     ST,
                     PBASERCA,
                     STPBASERCA,
                     PTABELA,
                     STPTABELA,
                     BONIFIC,
                     QT,
                     USADEBCREDRCABRIND,
                     MOVIMENTACONTACORRENTERCA,
                     CODPROMOCAOMED,
                     PERCRATEIOCREDRCASUPERVISOR)
                  VALUES
                    (vnnumped,
                     vsposicao,
                     p_numtransvenda,
                     SYSDATE,
                     p_codfunclanc,
                     vncodusur, -- RCA
                     p_rotinalanc,
                     vnvlcorrente_atual,
                     vnvllimcred,
                     vnvlcorrente_ant,
                     vnvllimcred,
                     p_codprod,
                     p_numseq,
                     SUBSTR('CTRLCCRCA: LANCAMENTO RATEIO RCA ITEM TRANS. VENDA', 1, 60),
                     vrItem.nPVENDA,
                     vrItem.nST,
                     vrItem.nPBASERCA,
                     vrItem.nSTPBASERCA,
                     vrItem.nPTABELA,
                     vrItem.nSTPTABELA,
                     vrItem.nBONIFIC,
                     vrItem.nQT,
                     vrItem.vUSADEBCREDRCABRIND,
                     vrItem.vMOVIMENTACONTACORRENTERCA,
                     vrItem.nCODPROMOCAOMED,
                     nPERCRATEIOCREDRCASUPERVISOR);

                END IF; -- Fim: ((vstipomovccrca = 'VF') OR (vstipomovccrca = 'FF'))

               /*******************************
                A PARTE DO SUPERVISOR E EMPRESA
                   SERÁ SEMPRE NO FATURAMENTO
                    (Executa sem Restrições)
                *******************************/

                -- RATEIO ENTRE SUPERVISOR E EMPRESA ------------------------------------------------------

                -- Obter % Rateio de Crédito de C/C Supervisor e Empresa
                nPERCRATEIOCREDSUPERVEMPRESA := F_PERCRATEIOCREDSUPERVEMPRESA;

                ------------------------------------------------------------
                -- Se houver Rateio de Crédito de C/C Supervisor com Empresa
                ------------------------------------------------------------
                IF (F_USARATEIOCREDSUPERVEMPRESA(vncod_cadrca_empresa,
                                                 nPERCRATEIOCREDSUPERVEMPRESA,
                                                 vnValorTransf)) THEN
                  -- Calcula a parte do Supervisor
                  vnValorTransfSupervisor := ROUND(vnValorTransf * (NVL(nPERCRATEIOCREDSUPERVEMPRESA,0) / 100),2);
                  -- Calcula a parte da Empresa
                  vnValorTransfEmpresa    := (NVL(vnValorTransf,0) - NVL(vnValorTransfSupervisor,0));
                ELSE
                  -- Somente tem a parte do Supervisor
                  vnValorTransfSupervisor := vnValorTransf;
                  -- Não tem a parte da Empresa
                  vnValorTransfEmpresa    := 0;
                END IF;

                -- CREDITANDO SUPERVISOR ------------------------------------------------------------------
                IF (NVL(vnValorTransfSupervisor,0) > 0) THEN

                  SELECT pcusuari.vlcorrente, pcusuari.vllimcred
                    INTO vnvlcorrente_ant, vnvllimcred
                    FROM pcusuari
                   WHERE codusur = vncod_cadrca_supervisor; -- SUPERVISOR

                  vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) + NVL(vnValorTransfSupervisor, 0); -- INCREMENTANDO VALOR TRANSF.

                  UPDATE pcusuari
                     SET vlcorrente = vnvlcorrente_atual
                   WHERE codusur = vncod_cadrca_supervisor; -- SUPERVISOR

                  INSERT INTO pclogrca
                    (numped,
                     posicao,
                     numtransvenda,
                     DATA,
                     codfunc,
                     codusur,
                     rotina,
                     vlcorrente,
                     vllimcred,
                     vlcorrenteant,
                     vllimcredant,
                     codprod,
                     numseq,
                     historico,
                     PVENDA,
                     ST,
                     PBASERCA,
                     STPBASERCA,
                     PTABELA,
                     STPTABELA,
                     BONIFIC,
                     QT,
                     USADEBCREDRCABRIND,
                     MOVIMENTACONTACORRENTERCA,
                     CODPROMOCAOMED,
                     PERCRATEIOCREDRCASUPERVISOR)
                  VALUES
                    (vnnumped,
                     vsposicao,
                     p_numtransvenda,
                     SYSDATE,
                     p_codfunclanc,
                     vncod_cadrca_supervisor, -- SUPERVISOR
                     p_rotinalanc,
                     vnvlcorrente_atual,
                     vnvllimcred,
                     vnvlcorrente_ant,
                     vnvllimcred,
                     p_codprod,
                     p_numseq,
                     SUBSTR('CTRLCCRCA: LANCAMENTO RATEIO SUPERV. ITEM TRANS. VENDA', 1, 60),
                     vrItem.nPVENDA,
                     vrItem.nST,
                     vrItem.nPBASERCA,
                     vrItem.nSTPBASERCA,
                     vrItem.nPTABELA,
                     vrItem.nSTPTABELA,
                     vrItem.nBONIFIC,
                     vrItem.nQT,
                     vrItem.vUSADEBCREDRCABRIND,
                     vrItem.vMOVIMENTACONTACORRENTERCA,
                     vrItem.nCODPROMOCAOMED,
                     nPERCRATEIOCREDRCASUPERVISOR);

                END IF; -- Fim Condição: CREDITANDO SUPERVISOR

                -- CREDITANDO EMPRESA ---------------------------------------------------------------------
                IF (NVL(vncod_cadrca_empresa,0) > 0) AND
                   (NVL(vnValorTransfEmpresa,0) > 0) THEN

                  SELECT pcusuari.vlcorrente, pcusuari.vllimcred
                    INTO vnvlcorrente_ant, vnvllimcred
                    FROM pcusuari
                   WHERE codusur = vncod_cadrca_empresa; -- EMPRESA

                  vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) + NVL(vnValorTransfEmpresa, 0); -- INCREMENTANDO VALOR TRANSF.

                  UPDATE pcusuari
                     SET vlcorrente = vnvlcorrente_atual
                   WHERE codusur = vncod_cadrca_empresa; -- EMPRESA

                  INSERT INTO pclogrca
                    (numped,
                     posicao,
                     numtransvenda,
                     DATA,
                     codfunc,
                     codusur,
                     rotina,
                     vlcorrente,
                     vllimcred,
                     vlcorrenteant,
                     vllimcredant,
                     codprod,
                     numseq,
                     historico,
                     PVENDA,
                     ST,
                     PBASERCA,
                     STPBASERCA,
                     PTABELA,
                     STPTABELA,
                     BONIFIC,
                     QT,
                     USADEBCREDRCABRIND,
                     MOVIMENTACONTACORRENTERCA,
                     CODPROMOCAOMED,
                     PERCRATEIOCREDRCASUPERVISOR)
                  VALUES
                    (vnnumped,
                     vsposicao,
                     p_numtransvenda,
                     SYSDATE,
                     p_codfunclanc,
                     vncod_cadrca_empresa, -- EMPRESA
                     p_rotinalanc,
                     vnvlcorrente_atual,
                     vnvllimcred,
                     vnvlcorrente_ant,
                     vnvllimcred,
                     p_codprod,
                     p_numseq,
                     SUBSTR('CTRLCCRCA: LANCAMENTO RATEIO EMPRESA ITEM TRANS. VENDA', 1, 60),
                     vrItem.nPVENDA,
                     vrItem.nST,
                     vrItem.nPBASERCA,
                     vrItem.nSTPBASERCA,
                     vrItem.nPTABELA,
                     vrItem.nSTPTABELA,
                     vrItem.nBONIFIC,
                     vrItem.nQT,
                     vrItem.vUSADEBCREDRCABRIND,
                     vrItem.vMOVIMENTACONTACORRENTERCA,
                     vrItem.nCODPROMOCAOMED,
                     nPERCRATEIOCREDSUPERVEMPRESA);

                END IF; -- Fim Condição: CREDITANDO EMPRESA

              END IF; -- Fim Condição: DEBITANDO RCA

            END IF; -- Fim Condição Se o Supervisor movimenta C/C
          END IF; -- Fim Condição Rateio Saldo C/C

        END IF; -- FIM CONDIÇÃO: SE NÃO FOR LIQUIDEZ

      END IF; -- Fim Condição: vbvalido = TRUE

    END IF; -- FIM: (bMOVSALDORCAPORPEDIDOFAT) -- HIS.00052.2017

    RETURN vbvalido;

  END; -- ccrca_incluir_item_nf

  --RNG15
  FUNCTION ccrca_excluir_item_nf(p_codfunclanc   IN pclogrca.codfunc%TYPE,
                                 p_rotinalanc    IN pclogrca.rotina%TYPE,
                                 p_codusur       IN pcpedc.codusur%TYPE,
                                 p_numtransvenda IN pcpedc.numtransvenda%TYPE,
                                 p_codprod       IN pcpedi.codprod%TYPE,
                                 p_numseq        IN pcpedi.numseq%TYPE,
                                 p_qtanterior    IN NUMBER) RETURN BOOLEAN IS
    vbvalido BOOLEAN;
  BEGIN
    vbvalido := ccrca_estornar_ccrca_item_nf(p_codfunclanc,
                                             p_rotinalanc,
                                             p_codusur,
                                             p_numtransvenda,
                                             p_codprod,
                                             p_numseq,
                                             p_qtanterior);
    RETURN vbvalido;
  END; --ccrca_excluir_item_nf

  --RNG16
  FUNCTION ccrca_retornar_saldo_item_dev(p_numtransent PCMOVPREFAT.numtransent%TYPE,
                                         p_codprod     PCMOVPREFAT.codprod%TYPE,
                                         p_numseq      PCMOVPREFAT.numseq%TYPE,
                                         p_tipo        VARCHAR) -- Sabrina: tipo de operação I - Inclusao e E - Exclusao
   RETURN NUMBER IS
    vnvalorlanc                 NUMBER;
    vbvalido                    BOOLEAN;
    vnnumtransvenda             pcestcom.numtransvenda%TYPE;
    vnpunit                     PCMOVPREFAT.punit%TYPE;
    vnptabela                   PCMOVPREFAT.ptabela%TYPE;
    vnpbaserca                  PCMOVPREFAT.pbaserca%TYPE;
    vnqt                        PCMOVPREFAT.qt%TYPE;
    vsusadebcredrcabrind        PCMOVPREFAT.usadebcredrcabrind%TYPE;
    vncondvenda                 pcpedc.condvenda%TYPE;
    vnnumped                    pcpedc.numped%TYPE;
    vsbrinde                    pcpedc.brinde%TYPE;
    vsorigemped                 pcpedc.origemped%TYPE;
    vncodusur                   pcpedc.codusur%TYPE;
    vsbroker                    pcpedc.broker%TYPE;
    vsusacredrca                pcpedc.usacredrca%TYPE;
    vsbonificaltdebcredrca      pcpedc.bonificaltdebcredrca%TYPE;
    vstrocaaltdebcredrca        pcpedc.trocaaltdebcredrca%TYPE;
    vsbrokeraltdebcredrca       pcpedc.brokeraltdebcredrca%TYPE;
    vscrmaltdebcredrca          pcpedc.crmaltdebcredrca%TYPE;
    vstipomovccrca              pcpedc.tipomovccrca%TYPE;
    vsusadebcredrca             pcpedc.usadebcredrca%TYPE;
    vbfechado                   BOOLEAN;
    vsmsg                       VARCHAR2(400);
    vsmovimentacontacorrenterca PCMOVPREFAT.movimentacontacorrenterca%type;
    vnstpvenda                  PCMOVPREFAT.st%TYPE;
    vnstptabela                 PCMOVCOMPLEPREFAT.stptabela%TYPE;
    vnstpbaserca                PCMOVCOMPLEPREFAT.stpbaserca%TYPE;
    -- CC_ITEMBNF
    vsbonific                   PCMOVCOMPLEPREFAT.bonific%TYPE;
    -- DDVENDAS-41579
    vsItemBrinde                pcpedi.brinde%TYPE;    
  BEGIN
    proc_lerparametros(vsmsg);
    vbvalido := TRUE;

    BEGIN
      SELECT DISTINCT pcestcom.numtransvenda
        INTO vnnumtransvenda
        FROM pcestcom
       WHERE numtransent = p_numtransent;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    BEGIN
      SELECT DISTINCT condvenda, numped
        INTO vncondvenda, vnnumped
        FROM PCNFSAIDPREFAT
       WHERE numtransvenda = vnnumtransvenda;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    /*MED-2277*/
    IF vbvalido = FALSE THEN
      BEGIN
        vbvalido := TRUE;

        SELECT DISTINCT condvenda, numped
          INTO vncondvenda, vnnumped
          FROM PCNFSAID
         WHERE numtransvenda = vnnumtransvenda;
      EXCEPTION
        WHEN OTHERS THEN
          vbvalido := FALSE;
      END;
    END IF;

    BEGIN
      SELECT decode(nvl(PCMOVCOMPLE.bonific,'N'),'F',PCMOV.punitcont,PCMOV.punit),
             pcmov.ptabela,
             pcmov.pbaserca,
             pcmov.qt,
             NVL(pcmov.usadebcredrcabrind, NVL(pcpedi.usadebcredrcabrind,'N')), -- DDVENDAS-41579
             nvl(NVL(pcmov.movimentacontacorrenterca,
                     PCPEDI.MOVIMENTACONTACORRENTERCA),
                 'S'),
             NVL(pcmov.st, 0),
             NVL(pcmovcomple.stptabela,0),
             -- HIS.00632.2016 -- NVL(pcmovcomple.stpbaserca,0),
             NVL(PCPEDI.stpbaserca,0), -- HIS.00632.2016
             nvl(pcmovcomple.bonific, 'N') BONIFIC, -- CC_ITEMBNF
             pcpedi.brinde -- DDVENDAS-41579
        INTO vnpunit,
             vnptabela,
             vnpbaserca,
             vnqt,
             vsusadebcredrcabrind,
             vsmovimentacontacorrenterca,
             vnstpvenda,
             vnstptabela,
             vnstpbaserca,
             vsbonific, -- CC_ITEMBNF
             vsItemBrinde -- DDVENDAS-41579
        FROM pcmov, PCPEDI, pcmovcomple
       WHERE pcmov.numtransent  = p_numtransent
         AND pcmov.codprod      = p_codprod
         AND pcmov.numseq       = p_numseq
         AND pcmov.CODPROD(+)   = PCPEDI.CODPROD
         AND pcmov.NUMPED(+)    = PCPEDI.NUMPED
         AND pcmov.NUMSEQ(+)    = PCPEDI.NUMSEQ
         AND pcmov.numtransitem = pcmovcomple.numtransitem(+);
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;
    
    -- HIS.00632.2016
    IF (NVL(vnstpvenda,0)   > 0) AND
       (NVL(vnstpbaserca,0) = 0) THEN
      BEGIN
        SELECT NVL(PCPEDI.stpbaserca,0)
          INTO vnstpbaserca
          FROM PCPEDI
         WHERE (NUMPED  = vnnumped)
           AND (CODPROD = p_codprod)
           AND (ST      = vnstpvenda)
           AND (ROWNUM  = 1);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnstpbaserca := 0;
      END;
    END IF;

    -- HIS.00632.2016
    BEGIN
      SELECT p.codusur
        INTO vncodusur
        FROM pcpedc p
       WHERE p.numped = vnnumped;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(vncodusur, -- RCA que já estava buscando no Pedido
                                       vnnumped);

    BEGIN
      SELECT p.usacredrca,
             p.bonificaltdebcredrca,
             p.trocaaltdebcredrca,
             p.brokeraltdebcredrca,
             p.crmaltdebcredrca,
             p.tipomovccrca,
             DECODE(p.usadebcredrca,
                    NULL,
                    (SELECT NVL(pcusuari.usadebcredrca,
                                gregpcconsum.usacredrca)
                       FROM pcusuari
                      WHERE codusur = vncodusur -- HIS.00632.2016 -- p.codusur
                        AND ROWNUM = 1),
                    p.usadebcredrca),
             p.origemped,
             p.brinde,
             p.condvenda,
             p.broker
             -- HIS.00632.2016 -- p.codusur
        INTO vsusacredrca,
             vsbonificaltdebcredrca,
             vstrocaaltdebcredrca,
             vsbrokeraltdebcredrca,
             vscrmaltdebcredrca,
             vstipomovccrca,
             vsusadebcredrca,
             vsorigemped,
             vsbrinde,
             vncondvenda,
             vsbroker
             -- HIS.00632.2016 -- vncodusur
        FROM pcpedc p
       WHERE p.numped = vnnumped;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    -- DDVENDAS-41579
    IF (vsItemBrinde = 'S') THEN
      vsbrinde := 'S';
    END IF;    

    vbfechado := ccrca_verificar_fechamento(vnnumtransvenda);

    IF vbvalido = TRUE THEN
      IF vbfechado = TRUE OR vstipomovccrca <> 'VA' THEN
        vnvalorlanc := ccrca_saldo_item(NVL(vsusacredrca,
                                            gregpcconsum.usacredrca),
                                        vsusadebcredrca,
                                        vsbroker,
                                        vsorigemped,
                                        NVL(vsbonificaltdebcredrca,
                                            gregpcconsum.bonificaltdebcredrca),
                                        NVL(vstrocaaltdebcredrca,
                                            gregpcconsum.trocaaltdebcredrca),
                                        NVL(vscrmaltdebcredrca,
                                            gregpcconsum.crmaltdebcredrca),
                                        NVL(vsbrokeraltdebcredrca,
                                            gregpcconsum.brokeraltdebcredrca),
                                        NVL(vstipomovccrca,
                                            NVL(gregpcconsum.tipomovccrca,
                                                'VV')),
                                        vncondvenda,
                                        vsbrinde,
                                        vncodusur,
                                        'D',
                                        vnpunit,
                                        vnptabela,
                                        NVL(vnpbaserca, vnptabela),
                                        vnqt,
                                        vsusadebcredrcabrind,
                                        vsmovimentacontacorrenterca,
                                        vnstpvenda,
                                        vnstptabela,
                                        vnstpbaserca,
                                        vsbonific -- CC_ITEMBNF
                                        );
      ELSE
        vnvalorlanc := ccrca_saldo_item(NVL(vsusacredrca,
                                            gregpcconsum.usacredrca),
                                        vsusadebcredrca,
                                        vsbroker,
                                        vsorigemped,
                                        NVL(vsbonificaltdebcredrca,
                                            gregpcconsum.bonificaltdebcredrca),
                                        NVL(vstrocaaltdebcredrca,
                                            gregpcconsum.trocaaltdebcredrca),
                                        NVL(vscrmaltdebcredrca,
                                            gregpcconsum.crmaltdebcredrca),
                                        NVL(vsbrokeraltdebcredrca,
                                            gregpcconsum.brokeraltdebcredrca),
                                        NVL(vstipomovccrca,
                                            NVL(gregpcconsum.tipomovccrca,
                                                'VV')),
                                        vncondvenda,
                                        vsbrinde,
                                        vncodusur,
                                        'V',
                                        vnpunit,
                                        vnptabela,
                                        NVL(vnpbaserca, vnptabela),
                                        vnqt,
                                        vsusadebcredrcabrind,
                                        vsmovimentacontacorrenterca,
                                        vnstpvenda,
                                        vnstptabela,
                                        vnstpbaserca,
                                        vsbonific -- CC_ITEMBNF
                                        );
      END IF;
    END IF;

    vnvalorlanc := vnvalorlanc * (-1);
    RETURN vnvalorlanc;
  END; --ccrca_retornar_saldo_item_dev

  --RNG17
  FUNCTION ccrca_estornar_ccrca_item_dev(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                         p_rotinalanc  IN pclogrca.rotina%TYPE,
                                         p_numtransent IN pcnfent.numtransent%TYPE,
                                         p_codusur     IN pcpedc.codusur%TYPE,
                                         p_codprod     IN pcpedi.codprod%TYPE,
                                         p_numseq      IN pcpedi.numseq%TYPE)
    RETURN BOOLEAN IS
    vnnumtransvenda        pcestcom.numtransvenda%TYPE;
    vncondvenda            pcpedc.condvenda%TYPE;
    vnnumped               pcpedc.numped%TYPE;
    vsbrinde               pcpedc.brinde%TYPE;
    vsorigemped            pcpedc.origemped%TYPE;
    vddata                 pcpedc.DATA%TYPE;
    vsposicao              pcpedc.posicao%TYPE;
    vsusacredrca           pcpedc.usacredrca%TYPE;
    vsusadebcredrca        pcpedc.bonificaltdebcredrca%TYPE;
    vsbonificaltdebcredrca pcpedc.bonificaltdebcredrca%TYPE;
    vstrocaaltdebcredrca   pcpedc.trocaaltdebcredrca%TYPE;
    vsbrokeraltdebcredrca  pcpedc.brokeraltdebcredrca%TYPE;
    vscrmaltdebcredrca     pcpedc.crmaltdebcredrca%TYPE;
    vstipomovccrca         pcpedc.tipomovccrca%TYPE;
    vsusadebcredrca_rca    pcusuari.usadebcredrca%TYPE;
    vnvlcorrente_ant       pcusuari.vlcorrente%TYPE;
    vnvllimcred            pcusuari.vllimcred%TYPE;
    vnvlcorrente_atual     pcusuari.vlcorrente%TYPE;
    vnvalorlanc            NUMBER;
    vbvalido               BOOLEAN;
    -- Log
    TYPE TRecItem                   IS RECORD(
         nPVENDA                    PCLOGRCA.PVENDA%TYPE,
         nST                        PCLOGRCA.ST%TYPE,
         nPBASERCA                  PCLOGRCA.PBASERCA%TYPE,
         nSTPBASERCA                PCLOGRCA.STPBASERCA%TYPE,
         nPTABELA                   PCLOGRCA.PTABELA%TYPE,
         nSTPTABELA                 PCLOGRCA.STPTABELA%TYPE,
         nBONIFIC                   PCLOGRCA.BONIFIC%TYPE,
         nQT                        PCLOGRCA.QT%TYPE,
         vUSADEBCREDRCABRIND        PCLOGRCA.USADEBCREDRCABRIND%TYPE,
         vMOVIMENTACONTACORRENTERCA PCLOGRCA.MOVIMENTACONTACORRENTERCA%TYPE,
         nCODPROMOCAOMED            PCLOGRCA.CODPROMOCAOMED%TYPE,
         nVLUNITLIMCREDRCAUTILIZMED PCPEDI.VLUNITLIMCREDRCAUTILIZMED%TYPE); -- 4954.001502.2017
    vrItem                          TRecItem;
    -- HIS.00632.2016
    vncodusur                       pcpedc.codusur%type;
    -- LIMITE_FLEX
    vvtipomovccrca                  pcpedc.tipomovccrca%type;
    vnvllimcred_atual               pcusuari.vllimcred%type;
    -- Regra específica - HIS.00052.2017
    bMOVSALDORCAPORPEDIDOFAT        BOOLEAN;
    vvGravouTabAux                  VARCHAR2(1);
    vnValorLancProduto              NUMBER;
  BEGIN
    vbvalido := TRUE;

    -------------------------------------------------------------------------------------------------
    -- HIS.00065.2018 - Se usar o saldo C/C somente no próprio pedido, não acumula o Saldo C/C no RCA
    -------------------------------------------------------------------------------------------------
    IF (F_USARSALDORCASOMENTENOPEDIDO) THEN
      RETURN TRUE;
    END IF;

    -- Obter Regra Específica que indica se movimentará o Conta Corrente do RCA Faturamento por PedidO - HIS.00052.2017
    bMOVSALDORCAPORPEDIDOFAT     := F_MOVSALDORCAPORPEDIDOFAT;

    BEGIN
      SELECT pcestcom.numtransvenda
        INTO vnnumtransvenda
        FROM pcestcom
       WHERE numtransent = p_numtransent;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    BEGIN
      SELECT condvenda, numped
        INTO vncondvenda, vnnumped
        FROM PCNFSAIDPREFAT
       WHERE numtransvenda = vnnumtransvenda;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    /*MED-2277*/
    IF vbvalido = FALSE THEN
      BEGIN
        vbvalido := TRUE;

        SELECT condvenda, numped
          INTO vncondvenda, vnnumped
          FROM PCNFSAID
         WHERE numtransvenda = vnnumtransvenda;
      EXCEPTION
        WHEN OTHERS THEN
          vbvalido := FALSE;
      END;
    END IF;

    BEGIN
      SELECT DATA, posicao, tipomovccrca
        INTO vddata, vsposicao, vvtipomovccrca
        FROM pcpedc
       WHERE numped = vnnumped;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(p_codusur,
                                       vnnumped);

    ---------------------------------------------------------------------------------------------
    -- Específico - HIS.00052.2017 - Se Movimenta Conta-Corrente do RCA no Faturamento por Pedido
    ---------------------------------------------------------------------------------------------
    IF (bMOVSALDORCAPORPEDIDOFAT) AND
       (NVL(vvtipomovccrca,' ') = 'FF') THEN

      -- Verifica se já gravou a Tabela Auxiliar
      BEGIN
        SELECT 'S'
          INTO vvGravouTabAux
          FROM pclogrcaprodmed
         WHERE (numtransent = p_numtransent)
           AND (rotina      = p_rotinalanc)
           AND (rownum      = 1);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvGravouTabAux := 'N';
      END;

      -- Se ainda não gravou a Tabela Auxiliar
      IF (vvGravouTabAux = 'N') THEN

        -- Inicializa o Valor Total do Lançamento
        vnvalorlanc := 0;

        -- Processamento dos Itens da Nota Fiscal (Igual está na Proc. de Cancelamento)
        FOR vc_ItensNotaFiscal IN (SELECT pcmov.codprod
                                        , pcmov.numseq
                                        , pcmov.qt
                                     FROM pcmov
                                    WHERE numtransent = p_numtransent
                                      AND qt > 0
                                      AND pcmov.numseq > 0
                                  ) LOOP

          -- Busca informações na pcmovcomple
          BEGIN
            SELECT pcmov.punit
                 , pcmov.st
                 , pcmov.pbaserca
                 -- HIS.00632.2016 --, pcmovcomple.stpbaserca
                 , NVL(PCPEDI.stpbaserca,0) -- HIS.00632.2016
                 , pcmov.ptabela
                 , pcmovcomple.stptabela
                 , pcmovcomple.bonific
                 , pcmov.qt
                 , pcmov.usadebcredrcabrind
                 , pcmov.movimentacontacorrenterca
                 , pcmovcomple.codpromocaomed
                 , pcpedi.vlunitlimcredrcautilizmed
              INTO vrItem.nPVENDA
                 , vrItem.nST
                 , vrItem.nPBASERCA
                 , vrItem.nSTPBASERCA
                 , vrItem.nPTABELA
                 , vrItem.nSTPTABELA
                 , vrItem.nBONIFIC
                 , vrItem.nQT
                 , vrItem.vUSADEBCREDRCABRIND
                 , vrItem.vMOVIMENTACONTACORRENTERCA
                 , vrItem.nCODPROMOCAOMED
                 , vrItem.nVLUNITLIMCREDRCAUTILIZMED -- 4954.001502.2017
              FROM pcmov,
                   PCPEDI,
                   pcmovcomple
             WHERE (pcmov.numtransent  = p_numtransent)
               AND (pcmov.codprod      = vc_ItensNotaFiscal.codprod) -->> CODPROD DO LAÇO
               AND (pcmov.numseq       = vc_ItensNotaFiscal.numseq)  -->> NUMSEQ DO LAÇO
               AND (pcmov.CODPROD(+)   = PCPEDI.CODPROD)
               AND (pcmov.NUMPED(+)    = PCPEDI.NUMPED)
               AND (pcmov.NUMSEQ(+)    = PCPEDI.NUMSEQ)
               AND (pcmov.numtransitem = pcmovcomple.numtransitem(+));
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vrItem.nPVENDA                    := NULL;
              vrItem.nST                        := NULL;
              vrItem.nPBASERCA                  := NULL;
              vrItem.nSTPBASERCA                := NULL;
              vrItem.nPTABELA                   := NULL;
              vrItem.nSTPTABELA                 := NULL;
              vrItem.nBONIFIC                   := 'N';
              vrItem.nQT                        := NULL;
              vrItem.vUSADEBCREDRCABRIND        := NULL;
              vrItem.vMOVIMENTACONTACORRENTERCA := NULL;
              vrItem.nCODPROMOCAOMED            := NULL;
              vrItem.nVLUNITLIMCREDRCAUTILIZMED := NULL; -- 4954.001502.2017
          END;

          -- HIS.00632.2016
          IF (NVL(vrItem.nST,0)         > 0) AND
             (NVL(vrItem.nSTPBASERCA,0) = 0) THEN
            BEGIN
              SELECT NVL(PCPEDI.stpbaserca,0)
                INTO vrItem.nSTPBASERCA
                FROM PCPEDI
               WHERE (NUMPED  = vnnumped)
                 AND (CODPROD = vc_ItensNotaFiscal.codprod) -->> CODPROD DO LAÇO
                 AND (ST      = vrItem.nST)
                 AND (ROWNUM  = 1);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vrItem.nSTPBASERCA := 0;
            END;
          END IF;

          -- Valor do Lançamento DO PRODUTO
          vnValorLancProduto := ccrca_retornar_saldo_item_dev(p_numtransent,
                                                              vc_ItensNotaFiscal.codprod, -->> CODPROD DO LAÇO
                                                              vc_ItensNotaFiscal.numseq,  -->> NUMSEQ DO LAÇO
                                                              'E'); -- incluido por sabrina


          -- Insere em Tabela Auxiliar o que não será mais gravado por Produto na PCLOGRCA
          INSERT INTO pclogrcaprodmed
            (numped,
             posicao,
             numtransvenda,
             numtransent,
             DATA,
             codfunc,
             codusur,
             rotina,
             vlsaldorca,
             codprod,
             numseq,
             historico)
          VALUES
            (vnnumped,
             vsposicao,
             vnnumtransvenda,
             p_numtransent,
             SYSDATE,
             p_codfunclanc,
             vncodusur, -- HIS.00632.2016 -- p_codusur,
             p_rotinalanc,
             (vnValorLancProduto * (-1)),  -->> VALOR DO LANÇAMENTO DO PRODUTO (MULTIPLICA POR -1 POR SER ESTORNO)
             vc_ItensNotaFiscal.codprod, -->> CODPROD DO LAÇO
             vc_ItensNotaFiscal.numseq,  -->> NUMSEQ DO LAÇO
             SUBSTR('CTRLCCRCA: ESTORNO SALDO ITEM DEVOLUCAO', 1, 60));

          -- Acumula o Valor do Lançamento
          vnvalorlanc := NVL(vnvalorlanc,0) + NVL(vnValorLancProduto,0);

        END LOOP; -- FIM: Processamento dos Itens da Nota Fiscal

        -- Pesquisa Saldo do RCA
        BEGIN
          SELECT p.vlcorrente, p.vllimcred
            INTO vnvlcorrente_ant, vnvllimcred
            FROM pcusuari p
           WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;
        EXCEPTION
          WHEN OTHERS THEN
            vbvalido := FALSE;
        END;

        IF vbvalido = TRUE THEN






          vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) - NVL(vnvalorlanc, 0);

          -- a package não deve barrar a movimentacao do saldo, os programas eh que fazem isso
          --IF vnvlcorrente_atual >= 0 THEN
          UPDATE pcusuari
             SET vlcorrente = vnvlcorrente_atual
           WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;

          INSERT INTO pclogrca
            (numped,
             posicao,
             numtransvenda,
             numtransent,
             DATA,
             codfunc,
             codusur,
             rotina,
             vlcorrente,
             vllimcred,
             vlcorrenteant,
             vllimcredant,
             codprod,
             numseq,
             historico)
          VALUES
            (vnnumped,
             vsposicao,
             vnnumtransvenda,
             p_numtransent,
             SYSDATE,
             p_codfunclanc,
             vncodusur, -- HIS.00632.2016 -- p_codusur,
             p_rotinalanc,
             vnvlcorrente_atual,
             vnvllimcred,
             vnvlcorrente_ant,
             vnvllimcred,
             0, -->> SEM CODPROD
             0, -->> SEM NUMSEQ
             SUBSTR('CTRLCCRCA: ESTORNO SALDO DEVOLUCAO', 1, 60)); -->> LANÇAMENTO TOTAL DA TRANSAÇÃO

        END IF; -- Fim Condição: vbvalido = TRUE

      END IF; -- Fim: Se ainda não gravou a Tabela Auxiliar

    ---------------------------------------------------------------------------------------------
    -- Padrão Pacote
    ---------------------------------------------------------------------------------------------
    ELSE

      BEGIN
        SELECT p.vlcorrente, p.vllimcred
          INTO vnvlcorrente_ant, vnvllimcred
          FROM pcusuari p
         WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;
      EXCEPTION
        WHEN OTHERS THEN
          vbvalido := FALSE;
      END;

      IF vbvalido = TRUE THEN

        BEGIN
          SELECT pcmov.punit
               , pcmov.st
               , pcmov.pbaserca
               -- HIS.00632.2016 --, pcmovcomple.stpbaserca
               , NVL(PCPEDI.stpbaserca,0) -- HIS.00632.2016
               , pcmov.ptabela
               , pcmovcomple.stptabela
               , pcmovcomple.bonific
               , pcmov.qt
               , pcmov.usadebcredrcabrind
               , pcmov.movimentacontacorrenterca
               , pcmovcomple.codpromocaomed
               , pcpedi.vlunitlimcredrcautilizmed
            INTO vrItem.nPVENDA
               , vrItem.nST
               , vrItem.nPBASERCA
               , vrItem.nSTPBASERCA
               , vrItem.nPTABELA
               , vrItem.nSTPTABELA
               , vrItem.nBONIFIC
               , vrItem.nQT
               , vrItem.vUSADEBCREDRCABRIND
               , vrItem.vMOVIMENTACONTACORRENTERCA
               , vrItem.nCODPROMOCAOMED
               , vrItem.nVLUNITLIMCREDRCAUTILIZMED -- 4954.001502.2017
            FROM pcmov,
                 PCPEDI,
                 pcmovcomple
           WHERE (pcmov.numtransent  = p_numtransent)
             AND (pcmov.codprod      = p_codprod)
             AND (pcmov.numseq       = p_numseq)
             AND (pcmov.CODPROD(+)   = PCPEDI.CODPROD)
             AND (pcmov.NUMPED(+)    = PCPEDI.NUMPED)
             AND (pcmov.NUMSEQ(+)    = PCPEDI.NUMSEQ)
             AND (pcmov.numtransitem = pcmovcomple.numtransitem(+));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vrItem.nPVENDA                    := NULL;
            vrItem.nST                        := NULL;
            vrItem.nPBASERCA                  := NULL;
            vrItem.nSTPBASERCA                := NULL;
            vrItem.nPTABELA                   := NULL;
            vrItem.nSTPTABELA                 := NULL;
            vrItem.nBONIFIC                   := 'N';
            vrItem.nQT                        := NULL;
            vrItem.vUSADEBCREDRCABRIND        := NULL;
            vrItem.vMOVIMENTACONTACORRENTERCA := NULL;
            vrItem.nCODPROMOCAOMED            := NULL;
            vrItem.nVLUNITLIMCREDRCAUTILIZMED := NULL; -- 4954.001502.2017
        END;

        -- HIS.00632.2016
        IF (NVL(vrItem.nST,0)         > 0) AND
           (NVL(vrItem.nSTPBASERCA,0) = 0) THEN
          BEGIN
            SELECT NVL(PCPEDI.stpbaserca,0)
              INTO vrItem.nSTPBASERCA
              FROM PCPEDI
             WHERE (NUMPED  = vnnumped)
               AND (CODPROD = p_codprod)
               AND (ST      = vrItem.nST)
               AND (ROWNUM  = 1);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vrItem.nSTPBASERCA := 0;
          END;
        END IF;

        vnvalorlanc        := ccrca_retornar_saldo_item_dev(p_numtransent,
                                                            p_codprod,
                                                            p_numseq,
                                                            'E'); -- incluido por sabrina

        -- LIMITE_FLEX
        IF (NVL(vvtipomovccrca,' ') = 'LL') THEN

          -- Se Usou Limite
          IF (NVL(vrItem.nVLUNITLIMCREDRCAUTILIZMED,0) <> 0) THEN -- 4954.001502.2017

            -- Valor Utilizado do Limite de Crédito - 4954.001502.2017
            vnvalorlanc := NVL(vrItem.nVLUNITLIMCREDRCAUTILIZMED,0) * NVL(vrItem.nQT,0);

            vnvllimcred_atual := NVL(vnvllimcred, 0) - NVL(vnvalorlanc, 0);

            UPDATE pcusuari
               SET vllimcred = vnvllimcred_atual
             WHERE codusur = vncodusur;

            INSERT INTO pcloglimitecredrcamed
              (numped,
               posicao,
               numtransvenda,
               DATA,
               codfunc,
               codusur,
               rotina,
               vlcorrente,
               vllimcred,
               vlcorrenteant,
               vllimcredant,
               codprod,
               numseq,
               historico,
               PVENDA,
               ST,
               PBASERCA,
               STPBASERCA,
               PTABELA,
               STPTABELA,
               BONIFIC,
               QT,
               USADEBCREDRCABRIND,
               MOVIMENTACONTACORRENTERCA,
               CODPROMOCAOMED)
            VALUES
              (vnnumped,
               vsposicao,
               vnnumtransvenda,
               SYSDATE,
               p_codfunclanc,
               vncodusur,
               p_rotinalanc,
               vnvlcorrente_ant,
               vnvllimcred_atual,
               vnvlcorrente_ant,
               vnvllimcred,
               p_codprod,
               p_numseq,
               SUBSTR('CTRLCCRCA: ESTORNO SALDO ITEM DEVOLUCAO', 1, 60),
               vrItem.nPVENDA,
               vrItem.nST,
               vrItem.nPBASERCA,
               vrItem.nSTPBASERCA,
               vrItem.nPTABELA,
               vrItem.nSTPTABELA,
               vrItem.nBONIFIC,
               vrItem.nQT,
               vrItem.vUSADEBCREDRCABRIND,
               vrItem.vMOVIMENTACONTACORRENTERCA,
               vrItem.nCODPROMOCAOMED);

          END IF; -- Fim: Se Usou Limite

        ELSE

          vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) - NVL(vnvalorlanc, 0);

          -- a package não deve barrar a movimentacao do saldo, os programas eh que fazem isso
          --IF vnvlcorrente_atual >= 0 THEN
          UPDATE pcusuari
             SET vlcorrente = vnvlcorrente_atual
           WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;

          INSERT INTO pclogrca
            (numped,
             posicao,
             numtransvenda,
             DATA,
             codfunc,
             codusur,
             rotina,
             vlcorrente,
             vllimcred,
             vlcorrenteant,
             vllimcredant,
             codprod,
             numseq,
             historico,
             PVENDA,
             ST,
             PBASERCA,
             STPBASERCA,
             PTABELA,
             STPTABELA,
             BONIFIC,
             QT,
             USADEBCREDRCABRIND,
             MOVIMENTACONTACORRENTERCA,
             CODPROMOCAOMED)
          VALUES
            (vnnumped,
             vsposicao,
             vnnumtransvenda,
             SYSDATE,
             p_codfunclanc,
             vncodusur, -- HIS.00632.2016 -- p_codusur,
             p_rotinalanc,
             vnvlcorrente_atual,
             vnvllimcred,
             vnvlcorrente_ant,
             vnvllimcred,
             p_codprod,
             p_numseq,
             SUBSTR('CTRLCCRCA: ESTORNO SALDO ITEM DEVOLUCAO', 1, 60),
             vrItem.nPVENDA,
             vrItem.nST,
             vrItem.nPBASERCA,
             vrItem.nSTPBASERCA,
             vrItem.nPTABELA,
             vrItem.nSTPTABELA,
             vrItem.nBONIFIC,
             vrItem.nQT,
             vrItem.vUSADEBCREDRCABRIND,
             vrItem.vMOVIMENTACONTACORRENTERCA,
             vrItem.nCODPROMOCAOMED);
          --ELSE
          --vbvalido := FALSE;
          --END IF;

        END IF; -- FIM: LIMITE_FLEX

      END IF;

    END IF; -- FIM: (bMOVSALDORCAPORPEDIDOFAT) -- HIS.00052.2017

    RETURN(vbvalido);

  END; --ccrca_estornar_ccrca_item_dev

  --RNG18
  FUNCTION ccrca_incluir_item_dev(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                  p_rotinalanc  IN pclogrca.rotina%TYPE,
                                  p_numtransent IN pcnfent.numtransent%TYPE,
                                  p_codusur     IN pcpedc.codusur%TYPE,
                                  p_codprod     IN pcpedi.codprod%TYPE,
                                  p_numseq      IN pcpedi.numseq%TYPE)
    RETURN BOOLEAN IS
    vbvalido           BOOLEAN;
    vnnumped           pcpedc.numped%TYPE;
    vncondvenda        pcpedc.condvenda%TYPE;
    vnnumtransvenda    pcestcom.numtransvenda%TYPE;
    vsposicao          pcpedc.posicao%TYPE;
    vddata             pcpedc.DATA%TYPE;
    vnvlcorrente_ant   pcusuari.vlcorrente%TYPE;
    vnvlcorrente_atual pcusuari.vlcorrente%TYPE;
    vnvllimcred        pcusuari.vllimcred%TYPE;
    vnvalorlanc        NUMBER;
    -- Log
    TYPE TRecItem                   IS RECORD(
         nPVENDA                    PCLOGRCA.PVENDA%TYPE,
         nST                        PCLOGRCA.ST%TYPE,
         nPBASERCA                  PCLOGRCA.PBASERCA%TYPE,
         nSTPBASERCA                PCLOGRCA.STPBASERCA%TYPE,
         nPTABELA                   PCLOGRCA.PTABELA%TYPE,
         nSTPTABELA                 PCLOGRCA.STPTABELA%TYPE,
         nBONIFIC                   PCLOGRCA.BONIFIC%TYPE,
         nQT                        PCLOGRCA.QT%TYPE,
         vUSADEBCREDRCABRIND        PCLOGRCA.USADEBCREDRCABRIND%TYPE,
         vMOVIMENTACONTACORRENTERCA PCLOGRCA.MOVIMENTACONTACORRENTERCA%TYPE,
         nCODPROMOCAOMED            PCLOGRCA.CODPROMOCAOMED%TYPE,
         nVLUNITLIMCREDRCAUTILIZMED PCPEDI.VLUNITLIMCREDRCAUTILIZMED%TYPE); -- 4954.001502.2017
    vrItem                          TRecItem;
    -- HIS.00632.2016
    vncodusur                       pcpedc.codusur%type;
    -- LIMITE_FLEX
    vvtipomovccrca                  pcpedc.tipomovccrca%type;
    vnvllimcred_atual               pcusuari.vllimcred%type;
    -- Regra específica - HIS.00052.2017
    bMOVSALDORCAPORPEDIDOFAT        BOOLEAN;
    vvGravouTabAux                  VARCHAR2(1);
    vnValorLancProduto              NUMBER;
  BEGIN
    vbvalido := TRUE;

    -------------------------------------------------------------------------------------------------
    -- HIS.00065.2018 - Se usar o saldo C/C somente no próprio pedido, não acumula o Saldo C/C no RCA
    -------------------------------------------------------------------------------------------------
    IF (F_USARSALDORCASOMENTENOPEDIDO) THEN
      RETURN TRUE;
    END IF;

    -- Obter Regra Específica que indica se movimentará o Conta Corrente do RCA Faturamento por PedidO - HIS.00052.2017
    bMOVSALDORCAPORPEDIDOFAT     := F_MOVSALDORCAPORPEDIDOFAT;

    BEGIN
      SELECT DISTINCT pcestcom.numtransvenda
        INTO vnnumtransvenda
        FROM pcestcom
       WHERE numtransent = p_numtransent;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    BEGIN
      SELECT DISTINCT condvenda, numped
        INTO vncondvenda, vnnumped
        FROM PCNFSAIDPREFAT
       WHERE numtransvenda = vnnumtransvenda;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    /*MED-2277*/
    IF vbvalido = FALSE THEN
      BEGIN
        vbvalido := TRUE;
        SELECT DISTINCT condvenda, numped
          INTO vncondvenda, vnnumped
          FROM PCNFSAID
         WHERE numtransvenda = vnnumtransvenda;
      EXCEPTION
        WHEN OTHERS THEN
          vbvalido := FALSE;
      END;
    END IF;

    BEGIN
      SELECT DATA, posicao, pcpedc.tipomovccrca
        INTO vddata, vsposicao, vvtipomovccrca
        FROM pcpedc
       WHERE numped = vnnumped;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(p_codusur,
                                       vnnumped);

    ---------------------------------------------------------------------------------------------
    -- Específico - HIS.00052.2017 - Se Movimenta Conta-Corrente do RCA no Faturamento por Pedido
    ---------------------------------------------------------------------------------------------
    IF (bMOVSALDORCAPORPEDIDOFAT) AND
       (NVL(vvtipomovccrca,' ') = 'FF') THEN

      -- Verifica se já gravou a Tabela Auxiliar
      BEGIN
        SELECT 'S'
          INTO vvGravouTabAux
          FROM pclogrcaprodmed
         WHERE (numtransent = p_numtransent)
           AND (rotina      = p_rotinalanc)
           AND (rownum      = 1);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvGravouTabAux := 'N';
      END;

      -- Se ainda não gravou a Tabela Auxiliar
      IF (vvGravouTabAux = 'N') THEN

        -- Inicializa o Valor Total do Lançamento
        vnvalorlanc := 0;

        -- Processamento dos Itens da Nota Fiscal (Igual está na Proc. de Cancelamento)
        FOR vc_ItensNotaFiscal IN (SELECT pcmov.codprod
                                        , pcmov.numseq
                                        , pcmov.qt
                                     FROM pcmov
                                    WHERE numtransent = p_numtransent
                                      AND qt > 0
                                      AND pcmov.numseq > 0
                                  ) LOOP

          -- Busca informações na pcmovcomple
          BEGIN
            SELECT pcmov.punit
                 , pcmov.st
                 , pcmov.pbaserca
                 , pcmovcomple.stpbaserca
                 , pcmov.ptabela
                 , pcmovcomple.stptabela
                 , pcmovcomple.bonific
                 , pcmov.qt
                 , pcmov.usadebcredrcabrind
                 , pcmov.movimentacontacorrenterca
                 , pcmovcomple.codpromocaomed
                 , pcpedi.vlunitlimcredrcautilizmed -- 4954.001502.2017
              INTO vrItem.nPVENDA
                 , vrItem.nST
                 , vrItem.nPBASERCA
                 , vrItem.nSTPBASERCA
                 , vrItem.nPTABELA
                 , vrItem.nSTPTABELA
                 , vrItem.nBONIFIC
                 , vrItem.nQT
                 , vrItem.vUSADEBCREDRCABRIND
                 , vrItem.vMOVIMENTACONTACORRENTERCA
                 , vrItem.nCODPROMOCAOMED
                 , vrItem.nVLUNITLIMCREDRCAUTILIZMED -- 4954.001502.2017
              FROM pcmov,
                   PCPEDI,
                   pcmovcomple
             WHERE (pcmov.numtransent  = p_numtransent)
               AND (pcmov.codprod      = vc_ItensNotaFiscal.codprod) -->> CODPROD DO LAÇO
               AND (pcmov.numseq       = vc_ItensNotaFiscal.numseq)  -->> NUMSEQ DO LAÇO
               AND (pcmov.CODPROD(+)   = PCPEDI.CODPROD)
               AND (pcmov.NUMPED(+)    = PCPEDI.NUMPED)
               AND (pcmov.NUMSEQ(+)    = PCPEDI.NUMSEQ)
               AND (pcmov.numtransitem = pcmovcomple.numtransitem(+));
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vrItem.nPVENDA                    := NULL;
              vrItem.nST                        := NULL;
              vrItem.nPBASERCA                  := NULL;
              vrItem.nSTPBASERCA                := NULL;
              vrItem.nPTABELA                   := NULL;
              vrItem.nSTPTABELA                 := NULL;
              vrItem.nBONIFIC                   := 'N';
              vrItem.nQT                        := NULL;
              vrItem.vUSADEBCREDRCABRIND        := NULL;
              vrItem.vMOVIMENTACONTACORRENTERCA := NULL;
              vrItem.nCODPROMOCAOMED            := NULL;
              vrItem.nVLUNITLIMCREDRCAUTILIZMED := NULL; -- 4954.001502.2017
          END;

          -- Valor do Lançamento DO PRODUTO
          vnValorLancProduto := ccrca_retornar_saldo_item_dev(p_numtransent,
                                                              vc_ItensNotaFiscal.codprod, -->> CODPROD DO LAÇO
                                                              vc_ItensNotaFiscal.numseq,  -->> NUMSEQ DO LAÇO
                                                              'I'); -- incluido por sabrina

          -- Insere em Tabela Auxiliar o que não será mais gravado por Produto na PCLOGRCA
          INSERT INTO pclogrcaprodmed
            (numped,
             posicao,
             numtransvenda,
             numtransent,
             DATA,
             codfunc,
             codusur,
             rotina,
             vlsaldorca,
             codprod,
             numseq,
             historico,
             PVENDA,
             ST,
             PBASERCA,
             STPBASERCA,
             PTABELA,
             STPTABELA,
             BONIFIC,
             QT,
             USADEBCREDRCABRIND,
             MOVIMENTACONTACORRENTERCA,
             CODPROMOCAOMED)
          VALUES
            (vnnumped,
             vsposicao,
             vnnumtransvenda,
             p_numtransent,
             SYSDATE,
             p_codfunclanc,
             vncodusur, -- HIS.00632.2016 -- p_codusur,
             p_rotinalanc,
             vnValorLancProduto,
             vc_ItensNotaFiscal.codprod, -->> CODPROD DO LAÇO
             vc_ItensNotaFiscal.numseq,  -->> NUMSEQ DO LAÇO
             SUBSTR('CTRLCCRCA: LANCAMENTO SALDO ITEM DEVOLUCAO', 1, 60),
             vrItem.nPVENDA,
             vrItem.nST,
             vrItem.nPBASERCA,
             vrItem.nSTPBASERCA,
             vrItem.nPTABELA,
             vrItem.nSTPTABELA,
             vrItem.nBONIFIC,
             vrItem.nQT,
             vrItem.vUSADEBCREDRCABRIND,
             vrItem.vMOVIMENTACONTACORRENTERCA,
             vrItem.nCODPROMOCAOMED);

          -- Acumula o Valor do Lançamento
          vnvalorlanc := NVL(vnvalorlanc,0) + NVL(vnValorLancProduto,0);

        END LOOP; -- FIM: Processamento dos Itens da Nota Fiscal

        -- Pesquisa Saldo do RCA
        BEGIN
          SELECT p.vlcorrente, p.vllimcred
            INTO vnvlcorrente_ant, vnvllimcred
            FROM pcusuari p
           WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;
        EXCEPTION
          WHEN OTHERS THEN
            vbvalido := FALSE;
        END;

        IF vbvalido = TRUE THEN

          vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) + NVL(vnvalorlanc, 0);

          -- a package não deve barrar a movimentacao do saldo, os programas eh que fazem isso
          --IF vnvlcorrente_atual >= 0 THEN
          UPDATE pcusuari
             SET vlcorrente = vnvlcorrente_atual
           WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;

          INSERT INTO pclogrca
            (numped,
             posicao,
             numtransvenda,
             numtransent,
             DATA,
             codfunc,
             codusur,
             rotina,
             vlcorrente,
             vllimcred,
             vlcorrenteant,
             vllimcredant,
             codprod,
             numseq,
             historico)
          VALUES
            (vnnumped,
             vsposicao,
             vnnumtransvenda,
             p_numtransent,
             SYSDATE,
             p_codfunclanc,
             vncodusur, -- HIS.00632.2016 -- p_codusur,
             p_rotinalanc,
             vnvlcorrente_atual,
             vnvllimcred,
             vnvlcorrente_ant,
             vnvllimcred,
             0, -->> SEM CODPROD
             0, -->> SEM NUMSEQ
             SUBSTR('CTRLCCRCA: LANCAMENTO SALDO DEVOLUCAO', 1, 60)); -->> LANÇAMENTO TOTAL DA TRANSAÇÃO

        END IF; -- Fim Condição: vbvalido = TRUE

      END IF; -- Fim: Se ainda não gravou a Tabela Auxiliar

    ---------------------------------------------------------------------------------------------
    -- Padrão Pacote
    ---------------------------------------------------------------------------------------------
    ELSE

      BEGIN
        SELECT p.vlcorrente, p.vllimcred
          INTO vnvlcorrente_ant, vnvllimcred
          FROM pcusuari p
         WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;
      EXCEPTION
        WHEN OTHERS THEN
          vbvalido := FALSE;
      END;

      IF vbvalido = TRUE THEN

        BEGIN
          SELECT pcmov.punit
               , pcmov.st
               , pcmov.pbaserca
               , pcmovcomple.stpbaserca
               , pcmov.ptabela
               , pcmovcomple.stptabela
               , pcmovcomple.bonific
               , pcmov.qt
               , pcmov.usadebcredrcabrind
               , pcmov.movimentacontacorrenterca
               , pcmovcomple.codpromocaomed
               , pcpedi.vlunitlimcredrcautilizmed -- 4954.001502.2017
            INTO vrItem.nPVENDA
               , vrItem.nST
               , vrItem.nPBASERCA
               , vrItem.nSTPBASERCA
               , vrItem.nPTABELA
               , vrItem.nSTPTABELA
               , vrItem.nBONIFIC
               , vrItem.nQT
               , vrItem.vUSADEBCREDRCABRIND
               , vrItem.vMOVIMENTACONTACORRENTERCA
               , vrItem.nCODPROMOCAOMED
               , vrItem.nVLUNITLIMCREDRCAUTILIZMED -- 4954.001502.2017
            FROM pcmov,
                 PCPEDI,
                 pcmovcomple
           WHERE (pcmov.numtransent  = p_numtransent)
             AND (pcmov.codprod      = p_codprod)
             AND (pcmov.numseq       = p_numseq)
             AND (pcmov.CODPROD(+)   = PCPEDI.CODPROD)
             AND (pcmov.NUMPED(+)    = PCPEDI.NUMPED)
             AND (pcmov.NUMSEQ(+)    = PCPEDI.NUMSEQ)
             AND (pcmov.numtransitem = pcmovcomple.numtransitem(+));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vrItem.nPVENDA                    := NULL;
            vrItem.nST                        := NULL;
            vrItem.nPBASERCA                  := NULL;
            vrItem.nSTPBASERCA                := NULL;
            vrItem.nPTABELA                   := NULL;
            vrItem.nSTPTABELA                 := NULL;
            vrItem.nBONIFIC                   := 'N';
            vrItem.nQT                        := NULL;
            vrItem.vUSADEBCREDRCABRIND        := NULL;
            vrItem.vMOVIMENTACONTACORRENTERCA := NULL;
            vrItem.nCODPROMOCAOMED            := NULL;
            vrItem.nVLUNITLIMCREDRCAUTILIZMED := NULL; -- 4954.001502.2017
        END;

        vnvalorlanc        := ccrca_retornar_saldo_item_dev(p_numtransent,
                                                            p_codprod,
                                                            p_numseq,
                                                            'I'); -- incluido por sabrina

        -- LIMITE_FLEX
        IF (NVL(vvtipomovccrca,' ') = 'LL') THEN

          -- Se Usou Limite
          IF (NVL(vrItem.nVLUNITLIMCREDRCAUTILIZMED,0) <> 0) THEN -- 4954.001502.2017

            -- Valor Utilizado do Limite de Crédito - 4954.001502.2017
            vnvalorlanc := NVL(vrItem.nVLUNITLIMCREDRCAUTILIZMED,0) * NVL(vrItem.nQT,0);

            vnvllimcred_atual := NVL(vnvllimcred, 0) + NVL(vnvalorlanc, 0);

            UPDATE pcusuari
               SET vllimcred = vnvllimcred_atual
             WHERE codusur = vncodusur;

            INSERT INTO pcloglimitecredrcamed
              (numped,
               posicao,
               numtransvenda,
               DATA,
               codfunc,
               codusur,
               rotina,
               vlcorrente,
               vllimcred,
               vlcorrenteant,
               vllimcredant,
               codprod,
               numseq,
               historico,
               PVENDA,
               ST,
               PBASERCA,
               STPBASERCA,
               PTABELA,
               STPTABELA,
               BONIFIC,
               QT,
               USADEBCREDRCABRIND,
               MOVIMENTACONTACORRENTERCA,
               CODPROMOCAOMED)
            VALUES
              (vnnumped,
               vsposicao,
               vnnumtransvenda,
               SYSDATE,
               p_codfunclanc,
               vncodusur,
               p_rotinalanc,
               vnvlcorrente_ant,
               vnvllimcred_atual,
               vnvlcorrente_ant,
               vnvllimcred,
               p_codprod,
               p_numseq,
               SUBSTR('CTRLCCRCA: LANCAMENTO SALDO ITEM DEVOLUCAO', 1, 60),
               vrItem.nPVENDA,
               vrItem.nST,
               vrItem.nPBASERCA,
               vrItem.nSTPBASERCA,
               vrItem.nPTABELA,
               vrItem.nSTPTABELA,
               vrItem.nBONIFIC,
               vrItem.nQT,
               vrItem.vUSADEBCREDRCABRIND,
               vrItem.vMOVIMENTACONTACORRENTERCA,
               vrItem.nCODPROMOCAOMED);

          END IF; -- Fim: Se Usou Limite

        ELSE

          vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) + NVL(vnvalorlanc, 0);

          -- a package não deve barrar a movimentacao do saldo, os programas eh que fazem isso
          --IF vnvlcorrente_atual >= 0 THEN
          UPDATE pcusuari
             SET vlcorrente = vnvlcorrente_atual
           WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;

          INSERT INTO pclogrca
            (numped,
             posicao,
             numtransvenda,
             DATA,
             codfunc,
             codusur,
             rotina,
             vlcorrente,
             vllimcred,
             vlcorrenteant,
             vllimcredant,
             codprod,
             numseq,
             historico,
             PVENDA,
             ST,
             PBASERCA,
             STPBASERCA,
             PTABELA,
             STPTABELA,
             BONIFIC,
             QT,
             USADEBCREDRCABRIND,
             MOVIMENTACONTACORRENTERCA,
             CODPROMOCAOMED)
          VALUES
            (vnnumped,
             vsposicao,
             vnnumtransvenda,
             SYSDATE,
             p_codfunclanc,
             vncodusur, -- HIS.00632.2016 -- p_codusur,
             p_rotinalanc,
             vnvlcorrente_atual,
             vnvllimcred,
             vnvlcorrente_ant,
             vnvllimcred,
             p_codprod,
             p_numseq,
             SUBSTR('CTRLCCRCA: LANCAMENTO SALDO ITEM DEVOLUCAO', 1, 60),
             vrItem.nPVENDA,
             vrItem.nST,
             vrItem.nPBASERCA,
             vrItem.nSTPBASERCA,
             vrItem.nPTABELA,
             vrItem.nSTPTABELA,
             vrItem.nBONIFIC,
             vrItem.nQT,
             vrItem.vUSADEBCREDRCABRIND,
             vrItem.vMOVIMENTACONTACORRENTERCA,
             vrItem.nCODPROMOCAOMED);
          --ELSE
          --vbvalido := FALSE;
          --END IF;

        END IF; -- FIM: LIMITE_FLEX

      END IF; -- (vbvalido = TRUE)

    END IF; -- FIM: (bMOVSALDORCAPORPEDIDOFAT) -- HIS.00052.2017

    RETURN vbvalido;

  END; --ccrca_incluir_item_dev

  --RNG19
  FUNCTION ccrca_excluir_item_dev(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                  p_rotinalanc  IN pclogrca.rotina%TYPE,
                                  p_numtransent IN pcnfent.numtransent%TYPE,
                                  p_codusur     IN pcpedc.codusur%TYPE,
                                  p_codprod     IN pcpedi.codprod%TYPE,
                                  p_numseq      IN pcpedi.numseq%TYPE)
    RETURN BOOLEAN IS
    vbvalido        BOOLEAN;
    vnnumtransvenda PCNFSAIDPREFAT.numtransvenda%TYPE;
  BEGIN
    vbvalido := FALSE;

    vbvalido := ccrca_estornar_ccrca_item_dev(p_codfunclanc,
                                              p_rotinalanc,
                                              p_numtransent,
                                              p_codusur,
                                              p_codprod,
                                              p_numseq);
    RETURN vbvalido;
  END; --ccrca_excluir_item_dev

  --RNG24
  FUNCTION ccrca_buscar_saldo_venda(p_numped  IN pcpedc.numped%TYPE,
                                    p_codusur IN pcpedc.codusur%TYPE)
    RETURN NUMBER IS
    vvvlsaldopedido    NUMBER;
    vstipomovccrca     pcpedc.tipomovccrca%TYPE;
    vnnumtransvenda    pcpedc.numtransvenda%TYPE;
    vnvlsaldopedido    NUMBER;
    vnvlsaldonf        NUMBER;
    vnvlsaldodevolucao NUMBER;
    vnvlsaldovenda     NUMBER;
    vbvalido           BOOLEAN;
    vsmsg              VARCHAR2(400);
    -- HIS.00632.2016
    vncodusur          pcpedc.codusur%type;
    -- Variáveis para Rateio Crédito C/C RCA
    nPERCRATEIOCREDRCASUPERVISOR NUMBER;
  BEGIN
    proc_lerparametros(vsmsg);
    vbvalido           := TRUE;
    vnvlsaldopedido    := 0;
    vnvlsaldonf        := 0;
    vnvlsaldodevolucao := 0;
    vnvlsaldovenda     := 0;

    -- Obter % Rateio de Crédito de C/C RCA
    nPERCRATEIOCREDRCASUPERVISOR := F_PERCRATEIOCREDRCASUPERVISOR;

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(p_codusur,
                                       p_numped);

    BEGIN
      SELECT p.tipomovccrca, p.numtransvenda
        INTO vstipomovccrca, vnnumtransvenda
        FROM pcpedc p
       WHERE numped = p_numped;
    EXCEPTION
      WHEN OTHERS THEN
        vbvalido := FALSE;
    END;

    IF vbvalido = TRUE THEN
      IF NVL(vstipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) IN
         ('VV', 'VF') THEN
        vnvlsaldopedido := 0;

        FOR reg IN (SELECT codprod, numseq, qt
                      FROM pcpedi
                     WHERE numped = p_numped) LOOP
          vnvlsaldopedido := NVL(vnvlsaldopedido, 0) +
                             NVL(ccrca_retorna_saldo_itempedido(p_numped,
                                                                vncodusur, -- HIS.00632.2016 -- p_codusur,
                                                                reg.codprod,
                                                                reg.numseq,
                                                                reg.qt,
                                                                'I',
                                                                0,
                                                                nPERCRATEIOCREDRCASUPERVISOR),
                                 0); -- incluído por sabrina I - Inclusao
        END LOOP;
      END IF;

      IF NVL(vstipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) IN
         ('FF', 'VF') THEN
        vnvlsaldonf := 0;

        FOR reg IN (SELECT codprod, numseq, qt
                      FROM PCMOVPREFAT
                     WHERE numtransvenda = vnnumtransvenda) LOOP
          vnvlsaldonf := NVL(vnvlsaldonf, 0) + NVL(ccrca_retornar_saldo_item_nf(vnnumtransvenda,
                                                                                reg.codprod,
                                                                                reg.numseq,
                                                                                reg.qt,
                                                                                'I',
                                                                                0,
                                                                                nPERCRATEIOCREDRCASUPERVISOR),
                                                   0); -- incluido por sabrina I - Inclusao
        END LOOP;
      END IF;

      vnvlsaldodevolucao := 0;

      FOR reg IN (SELECT numtransent
                    FROM pcestcom
                   WHERE numtransvenda = vnnumtransvenda) LOOP
        FOR reg_itens IN (SELECT codprod, numseq, qt
                            FROM PCMOVPREFAT
                           WHERE numtransent = reg.numtransent) LOOP
          --Tarefa 99461
          if reg.numtransent > 0 then
            vnvlsaldodevolucao := NVL(vnvlsaldodevolucao, 0) +
                                  NVL(ccrca_retornar_saldo_item_dev(reg.numtransent,
                                                                    reg_itens.codprod,
                                                                    reg_itens.numseq,
                                                                    'I'),
                                      0); -- incluido por sabrina I - Inclusao
          END IF;
        END LOOP;
      END LOOP;

      vnvlsaldovenda := NVL(vnvlsaldopedido, 0) + NVL(vnvlsaldonf, 0) +
                        NVL(vnvlsaldodevolucao, 0);
    END IF;

    RETURN(vnvlsaldovenda);
  END; --ccrca_buscar_saldo_venda

  --RNG25
  FUNCTION ccrca_checar_alterar_rca(p_codusurorig    pcusuari.codusur%TYPE,
                                    p_codusurdestino pcusuari.codusur%TYPE,
                                    p_codfunclanc    pclogrca.codfunc%TYPE,
                                    p_rotinalanc     pclogrca.rotina%TYPE,
                                    p_numped         pcpedc.numped%TYPE)
    RETURN BOOLEAN IS
    vbtroca                  BOOLEAN;
    vbvalido                 BOOLEAN;
    vnsaldo_disp_rca_origem  NUMBER;
    vnsaldo_venda_origem     NUMBER;
    vnsaldo_venda_destino    NUMBER;
    vnsaldo_disp_rca_destino NUMBER;
    -- HIS.00632.2016
    vncodusur                pcpedc.codusur%type;
  BEGIN
    vbtroca                 := FALSE;
    vbvalido                := FALSE;

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(p_codusurorig,
                                       p_numped);

    -- HIS.00632.2016 - Se o RCA de Origem do Pedido que movimentou o C/C e não o Televendas
    IF (vncodusur = p_codusurorig) THEN

      vnsaldo_venda_origem    := ccrca_buscar_saldo_venda(p_numped,
                                                          p_codusurorig);
      vnsaldo_disp_rca_origem := ccrca_checar_disponivel_atual(p_codusurorig);

      IF NVL(vnsaldo_disp_rca_origem, 0) - NVL(vnsaldo_venda_origem, 0) < 0 THEN
        vbtroca := FALSE;
        -- rca de origem não pode "perder" o saldo desta venda sem ficar negativo
      ELSE
        vbtroca := TRUE;
      END IF;

      IF vbtroca = TRUE THEN
        vnsaldo_venda_destino    := ccrca_buscar_saldo_venda(p_numped,
                                                             p_codusurdestino);
        vnsaldo_disp_rca_destino := ccrca_checar_disponivel_atual(p_codusurdestino);

        IF NVL(vnsaldo_disp_rca_destino, 0) + NVL(vnsaldo_venda_destino, 0) < 0 THEN
          vbvalido := FALSE;
          -- rca de destino não pode "receber" o saldo desta venda sem ficar negativo
        ELSE
          vbvalido := TRUE;
        END IF;
      END IF;

    -- HIS.00632.2016 - Se foi o Televendas que movimentou o C/C do Pedido, pode transferir sem criticar o Saldo
    ELSE
      vbtroca := TRUE;
    END IF;

    RETURN vbvalido;
  END; --ccrca_checar_alterar_rca

  --RNG20
  FUNCTION ccrca_alterar_rca(p_codusurorig    pcusuari.codusur%TYPE,
                             p_codusurdestino pcusuari.codusur%TYPE,
                             p_codfunclanc    pclogrca.codfunc%TYPE,
                             p_rotinalanc     pclogrca.rotina%TYPE,
                             p_numped         pcpedc.numped%TYPE)
    RETURN BOOLEAN IS
    vstipomovccrca  pcpedc.tipomovccrca%TYPE;
    vsposicao       pcpedc.posicao%TYPE;
    vsusadebcredrca pcusuari.usadebcredrca%TYPE;
    vnnumtransvenda pcpedc.numtransvenda%TYPE;
    vbvalido        BOOLEAN;
    vsmsg           VARCHAR2(400);
    -- HIS.00632.2016
    vncodusur       pcpedc.codusur%type;
  BEGIN
    proc_lerparametros(vsmsg);
    vbvalido := TRUE; --correcao sabrina

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(p_codusurorig,
                                       p_numped);

    -- HIS.00632.2016 - Se o RCA de Origem do Pedido que movimentou o C/C e não o Televendas
    IF (vncodusur = p_codusurorig) THEN

      BEGIN
        SELECT pcpedc.tipomovccrca, posicao
          INTO vstipomovccrca, vsposicao
          FROM pcpedc
         WHERE numped = p_numped;
      EXCEPTION
        WHEN OTHERS THEN
          vbvalido := FALSE;
      END;

      -- soh buscar transacao se pedido estiver faturado
      IF vsposicao = 'F' THEN
        BEGIN
          SELECT PCNFSAIDPREFAT.numtransvenda
            INTO vnnumtransvenda
            FROM PCNFSAIDPREFAT
           WHERE numped = p_numped;
        EXCEPTION
          WHEN OTHERS THEN
            vbvalido := FALSE;
        END;

        /*MED-2277*/
        IF vbvalido = FALSE THEN
          BEGIN
            vbvalido := TRUE;
            SELECT PCNFSAID.numtransvenda
              INTO vnnumtransvenda
              FROM PCNFSAID
             WHERE numped = p_numped;
          EXCEPTION
            WHEN OTHERS THEN
              vbvalido := FALSE;
          END;
        END IF;
      END IF;

      BEGIN
        SELECT pcusuari.usadebcredrca
          INTO vsusadebcredrca
          FROM pcusuari
         WHERE codusur = p_codusurdestino;
      EXCEPTION
        WHEN OTHERS THEN
          vbvalido := FALSE;
      END;

      IF vbvalido THEN
        FOR reg IN (SELECT codprod, numseq, qt
                      FROM pcpedi
                     WHERE numped = p_numped) LOOP
          vbvalido := ccrca_estorna_item_pedido(p_codfunclanc,
                                                p_rotinalanc,
                                                p_codusurorig,
                                                p_numped,
                                                reg.codprod,
                                                reg.numseq,
                                                reg.qt);

          IF NVL(vstipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) IN
             ('FF', 'VF') THEN
            IF vsposicao = 'F' THEN
              vbvalido := ccrca_estornar_ccrca_item_nf(p_codfunclanc,
                                                       p_rotinalanc,
                                                       p_codusurorig,
                                                       vnnumtransvenda,
                                                       reg.codprod,
                                                       reg.numseq,
                                                       reg.qt);
            END IF;
          END IF;
        END LOOP;

        UPDATE pcpedc
           SET usadebcredrca = vsusadebcredrca
         WHERE numped = p_numped;

        FOR reg IN (SELECT codprod, numseq FROM pcpedi WHERE numped = p_numped) LOOP
          vbvalido := ccrca_incluir_item_pedido(p_codfunclanc,
                                                p_rotinalanc,
                                                p_codusurdestino,
                                                p_numped,
                                                reg.codprod,
                                                reg.numseq);

          IF NVL(vstipomovccrca, NVL(gregpcconsum.tipomovccrca, 'VV')) IN
             ('FF', 'VF') THEN
            IF vsposicao = 'F' THEN
              vbvalido := ccrca_incluir_item_nf(p_codfunclanc,
                                                p_rotinalanc,
                                                p_codusurdestino,
                                                vnnumtransvenda,
                                                reg.codprod,
                                                reg.numseq);
            END IF;
          END IF;
        END LOOP;

        IF vsposicao = 'F' THEN
          FOR reg IN (SELECT DISTINCT pcnfent.numtransent
                        FROM pcnfsaid, pcestcom, pcnfent
                       WHERE pcnfsaid.numped = p_numped
                         AND pcestcom.numtransvenda = pcnfsaid.numtransvenda
                         AND NVL(pcnfent.obs, 'X') <> 'NF CANCELADA'
                            -- acrescentada por sabrina
                         AND pcestcom.numtransent = pcnfent.numtransent) LOOP
            FOR reg_itens IN (SELECT codprod, numseq
                                FROM pcmov
                               WHERE numtransent = reg.numtransent) LOOP
              IF ccrca_estornar_ccrca_item_dev(p_codfunclanc,
                                               p_rotinalanc,
                                               reg.numtransent,
                                               p_codusurorig,
                                               reg_itens.codprod,
                                               reg_itens.numseq) THEN
                vbvalido := ccrca_incluir_item_dev(p_codfunclanc,
                                                   p_rotinalanc,
                                                   reg.numtransent,
                                                   p_codusurdestino,
                                                   reg_itens.codprod,
                                                   reg_itens.numseq);
              END IF;
            END LOOP;
          END LOOP;
        END IF;
      END IF;

    END IF; -- FIM: -- HIS.00632.2016 - Se o RCA de Origem do Pedido que movimentou o C/C e não o Televendas

    RETURN vbvalido;
  END; --ccrca_alterar_rca

  PROCEDURE ccrca_validar_acerto_nf(p_codfunclanc   IN pclogrca.codfunc%TYPE,
                                    p_rotinalanc    IN pclogrca.rotina%TYPE,
                                    p_numtransvenda IN PCNFSAIDPREFAT.numtransvenda%TYPE) IS
    vsusacredrca           pcpedc.usacredrca%TYPE;
    vsusadebcredrca        pcpedc.usadebcredrca%TYPE;
    vsbroker               pcpedc.broker%TYPE;
    vsorigemped            pcpedc.origemped%TYPE;
    vsbonificaltdebcredrca pcpedc.bonificaltdebcredrca%TYPE;
    vstrocaaltdebcredrca   pcpedc.trocaaltdebcredrca%TYPE;
    vscrmaltdebcredrca     pcpedc.crmaltdebcredrca%TYPE;
    vsbrokeraltdebcredrca  pcpedc.brokeraltdebcredrca%TYPE;
    vstipomovccrca         pcpedc.tipomovccrca%TYPE;
    vncondvenda            pcpedc.condvenda%TYPE;
    vsbrinde               pcpedc.brinde%TYPE;
    vncodusur              pcpedc.codusur%TYPE;
    vnnumped               pcpedc.numped%TYPE;
    vsposicao              pcpedc.posicao%TYPE;
    vnsaldoitem            NUMBER;
    vnvlcorrente_ant       pcusuari.vlcorrente%TYPE;
    vnvlcorrente_atual     pcusuari.vlcorrente%TYPE;
    vnvllimcred            pcusuari.vllimcred%TYPE;
    -- Log
    TYPE TRecItem                   IS RECORD(
         nPVENDA                    PCLOGRCA.PVENDA%TYPE,
         nST                        PCLOGRCA.ST%TYPE,
         nPBASERCA                  PCLOGRCA.PBASERCA%TYPE,
         nSTPBASERCA                PCLOGRCA.STPBASERCA%TYPE,
         nPTABELA                   PCLOGRCA.PTABELA%TYPE,
         nSTPTABELA                 PCLOGRCA.STPTABELA%TYPE,
         nBONIFIC                   PCLOGRCA.BONIFIC%TYPE,
         nQT                        PCLOGRCA.QT%TYPE,
         vUSADEBCREDRCABRIND        PCLOGRCA.USADEBCREDRCABRIND%TYPE,
         vMOVIMENTACONTACORRENTERCA PCLOGRCA.MOVIMENTACONTACORRENTERCA%TYPE,
         nCODPROMOCAOMED            PCLOGRCA.CODPROMOCAOMED%TYPE);
    vrItem                          TRecItem;
    -- HIS.00632.2016
    vncodusurItem        pcpedc.codusur%type;
  BEGIN
    FOR reg IN (SELECT PCMOVPREFAT.numseq,
                       PCMOVPREFAT.codprod,
                       decode(nvl(PCMOVCOMPLEPREFAT.bonific, 'N'),'F',PCMOVPREFAT.punitcont,PCMOVPREFAT.punit) punit,
                       PCMOVPREFAT.ptabela,
                       PCMOVPREFAT.pbaserca,
                       --Tarefa 113031
                       --No acerto da carga considerar somente a quantidade real, ou seja
                       --desconsiderar a quantidade devolvida
                       nvl(PCMOVPREFAT.qt, 0) - nvl(PCMOVPREFAT.qtdevol, 0) qt,
                       NVL(PCMOVPREFAT.usadebcredrcabrind, 'N') usadebcredrcabrind,
                       nvl(NVL(PCMOVPREFAT.movimentacontacorrenterca,
                               PCPEDI.movimentacontacorrenterca),
                           'S') movimentacontacorrenterca,
                       NVL(PCMOVPREFAT.st    ,0) stpvenda,
                       NVL(PCMOVCOMPLEPREFAT.stptabela,0) stptabela,
                       NVL(PCMOVCOMPLEPREFAT.stpbaserca,0) stpbaserca,
                       PCMOVCOMPLEPREFAT.codpromocaomed,
                       nvl(PCMOVCOMPLEPREFAT.BONIFIC, 'N') bonific, -- CC_ITEMBNF
                       pcpedi.brinde -- DDVENDAS-41579
                  FROM PCMOVPREFAT, PCPEDI, PCMOVCOMPLEPREFAT
                 WHERE PCMOVPREFAT.numtransvenda = p_numtransvenda
                   AND PCMOVPREFAT.CODPROD(+) = PCPEDI.CODPROD
                   AND PCMOVPREFAT.NUMSEQ(+) = PCPEDI.NUMSEQ
                   AND PCMOVPREFAT.NUMPED(+) = PCPEDI.NUMPED
                   AND PCMOVPREFAT.numtransitem = PCMOVCOMPLEPREFAT.numtransitem(+)) LOOP

      SELECT p.usacredrca,
             p.usadebcredrca,
             p.broker,
             p.origemped,
             p.bonificaltdebcredrca,
             p.trocaaltdebcredrca,
             p.crmaltdebcredrca,
             p.brokeraltdebcredrca,
             p.tipomovccrca,
             p.condvenda,
             p.brinde,
             p.codusur,
             p.numped,
             p.posicao
        INTO vsusacredrca,
             vsusadebcredrca,
             vsbroker,
             vsorigemped,
             vsbonificaltdebcredrca,
             vstrocaaltdebcredrca,
             vscrmaltdebcredrca,
             vsbrokeraltdebcredrca,
             vstipomovccrca,
             vncondvenda,
             vsbrinde,
             vncodusur,
             vnnumped,
             vsposicao
        FROM pcpedc p
       WHERE numtransvenda = p_numtransvenda;
       
      -- DDVENDAS-41579
      IF (reg.brinde = 'S') THEN
        vsbrinde := 'S';
      END IF;       

      -- HIS.00632.2016
      vncodusurItem := ObterRcaContaCorrente(vncodusur, -- RCA que já estava buscando no Pedido
                                             vnnumped);

      vnsaldoitem := ccrca_saldo_item(vsusacredrca,
                                      vsusadebcredrca,
                                      vsbroker,
                                      vsorigemped,
                                      vsbonificaltdebcredrca,
                                      vstrocaaltdebcredrca,
                                      vscrmaltdebcredrca,
                                      vsbrokeraltdebcredrca,
                                      vstipomovccrca,
                                      vncondvenda,
                                      vsbrinde,
                                      vncodusurItem, -- HIS.00632.2016 -- vncodusur,
                                      'A',
                                      reg.punit,
                                      reg.ptabela,
                                      reg.pbaserca,
                                      reg.qt,
                                      reg.usadebcredrcabrind,
                                      reg.movimentacontacorrenterca,
                                      reg.stpvenda,
                                      reg.stptabela,
                                      reg.stpbaserca,
                                      reg.bonific -- CC_ITEMBNF
                                      );

      SELECT vlcorrente, vllimcred
        INTO vnvlcorrente_ant, vnvllimcred
        FROM pcusuari
       WHERE codusur = vncodusur;

      -- Log
      vrItem.nPVENDA                    := reg.punit;
      vrItem.nST                        := reg.stpvenda;
      vrItem.nPBASERCA                  := reg.pbaserca;
      vrItem.nSTPBASERCA                := reg.stpbaserca;
      vrItem.nPTABELA                   := reg.ptabela;
      vrItem.nSTPTABELA                 := reg.stptabela;
      vrItem.nBONIFIC                   := 'N';
      vrItem.nQT                        := reg.qt;
      vrItem.vUSADEBCREDRCABRIND        := reg.usadebcredrcabrind;
      vrItem.vMOVIMENTACONTACORRENTERCA := reg.movimentacontacorrenterca;
      vrItem.nCODPROMOCAOMED            := reg.codpromocaomed;
      -- Log

      vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) + NVL(vnsaldoitem, 0);

      UPDATE pcusuari
         SET vlcorrente = vnvlcorrente_atual
       WHERE codusur = vncodusur;

      INSERT INTO pclogrca
        (numped,
         posicao,
         numtransvenda,
         DATA,
         codfunc,
         codusur,
         rotina,
         vlcorrente,
         vllimcred,
         vlcorrenteant,
         vllimcredant,
         codprod,
         numseq,
         historico,
         PVENDA,
         ST,
         PBASERCA,
         STPBASERCA,
         PTABELA,
         STPTABELA,
         BONIFIC,
         QT,
         USADEBCREDRCABRIND,
         MOVIMENTACONTACORRENTERCA,
         CODPROMOCAOMED)
      VALUES
        (vnnumped,
         vsposicao,
         p_numtransvenda,
         SYSDATE,
         p_codfunclanc,
         vncodusur,
         p_rotinalanc,
         vnvlcorrente_atual,
         vnvllimcred,
         vnvlcorrente_ant,
         vnvllimcred,
         reg.codprod,
         reg.numseq,
         SUBSTR('CTRLCCRCA: ACERTO NF', 1, 60),
         vrItem.nPVENDA,
         vrItem.nST,
         vrItem.nPBASERCA,
         vrItem.nSTPBASERCA,
         vrItem.nPTABELA,
         vrItem.nSTPTABELA,
         vrItem.nBONIFIC,
         vrItem.nQT,
         vrItem.vUSADEBCREDRCABRIND,
         vrItem.vMOVIMENTACONTACORRENTERCA,
         vrItem.nCODPROMOCAOMED);
    END LOOP;

    /*MED-2277*/
    BEGIN
      UPDATE PCNFSAIDPREFAT
         SET dtfechaccrca = SYSDATE
       WHERE numtransvenda = p_numtransvenda;
    exception
      when others then
        UPDATE PCNFSAID
           SET dtfechaccrca = SYSDATE
         WHERE numtransvenda = p_numtransvenda;
    END;
  END; --ccrca_validar_acerto_nf

  PROCEDURE ccrca_lancar_movimento_carga(p_codfunclanc         IN pclogrca.codfunc%TYPE,
                                         p_rotinalanc          IN pclogrca.rotina%TYPE,
                                         p_numcar              IN PCNFSAIDPREFAT.numcar%TYPE,
                                         p_dataemissao_inicial IN DATE,
                                         p_dataemissao_final   IN DATE,
                                         p_mensagem            OUT VARCHAR2) IS
    vbvalido   BOOLEAN;
    vsmensagem VARCHAR2(300);
  BEGIN
    vsmensagem := 'OK';

    IF NVL(p_numcar, 0) = 0 THEN
      FOR reg IN (SELECT numtransvenda, dtfechaccrca
                    FROM PCNFSAIDPREFAT
                   WHERE numcar = NVL(p_numcar, 0)
                        --Tarefa 105946
                     AND PCNFSAIDPREFAT.dtcancel is null
                     AND EXISTS (select pcpedc.numtransvenda
                            from pcpedc
                           where pcpedc.numtransvenda =
                                 PCNFSAIDPREFAT.numtransvenda)
                     AND dtsaida BETWEEN p_dataemissao_inicial AND
                         p_dataemissao_final

                 /*MED-2277*/
                 UNION
                   SELECT numtransvenda, dtfechaccrca
                      FROM PCNFSAID
                     WHERE numcar = NVL(p_numcar, 0)
                          --Tarefa 105946
                       AND PCNFSAID.dtcancel is null
                       AND EXISTS (select pcpedc.numtransvenda
                              from pcpedc
                             where pcpedc.numtransvenda =
                                   PCNFSAID.numtransvenda)
                       AND dtsaida BETWEEN p_dataemissao_inicial AND
                           p_dataemissao_final
                 ) LOOP
        vbvalido := ccrca_verificar_fechamento(reg.numtransvenda);

        IF vbvalido = TRUE THEN
          IF reg.dtfechaccrca IS NULL THEN
            ccrca_validar_acerto_nf(p_codfunclanc,
                                    p_rotinalanc,
                                    reg.numtransvenda);
          END IF;
        END IF;
      END LOOP;
    ELSE
      FOR reg IN (SELECT numtransvenda, dtfechaccrca
                    FROM PCNFSAIDPREFAT
                   WHERE numcar = p_numcar
                        --Tarefa 105946
                     AND EXISTS (select pcpedc.numtransvenda
                            from pcpedc
                           where pcpedc.numtransvenda =
                                 PCNFSAIDPREFAT.numtransvenda)
                     AND PCNFSAIDPREFAT.dtcancel is null

                 /*MED-2277*/
                 UNION
                   SELECT numtransvenda, dtfechaccrca
                      FROM PCNFSAID
                     WHERE numcar = p_numcar
                          --Tarefa 105946
                       AND EXISTS (select pcpedc.numtransvenda
                              from pcpedc
                             where pcpedc.numtransvenda =
                                   PCNFSAID.numtransvenda)
                       AND PCNFSAID.dtcancel is null
                 ) LOOP
        vbvalido := ccrca_verificar_fechamento(reg.numtransvenda);

        IF vbvalido = TRUE THEN
          IF reg.dtfechaccrca IS NULL THEN
            ccrca_validar_acerto_nf(p_codfunclanc,
                                    p_rotinalanc,
                                    reg.numtransvenda);
          END IF;
        END IF;
      END LOOP;
    END IF;

    p_mensagem := vsmensagem;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao lancar movimento carga.' || SQLCODE || ' ' ||
                    SQLERRM;
  END; --ccrca_lancar_movimento_Carga

  PROCEDURE ccrca_lancar_movimento_caixa(p_codfunclanc     IN pclogrca.codfunc%TYPE,
                                         p_rotinalanc      IN pclogrca.rotina%TYPE,
                                         p_numcheckout     IN pcpedc.numcaixa%TYPE,
                                         p_codfunccheckout IN PCNFSAIDPREFAT.codfunclanc%TYPE,
                                         p_dataemissao     IN DATE,
                                         p_mensagem        OUT VARCHAR2) IS
    vbvalido   BOOLEAN;
    vsmensagem VARCHAR2(300);
  BEGIN
    vsmensagem := 'OK';

    FOR reg IN (SELECT numtransvenda, dtfechaccrca
                  FROM PCNFSAIDPREFAT
                 WHERE caixa = p_numcheckout
                   AND codemitente = p_codfunccheckout
                   AND dtsaida = p_dataemissao
                      --Tarefa 105946
                   AND EXISTS
                 (select pcpedc.numtransvenda
                          from pcpedc
                         where pcpedc.numtransvenda = PCNFSAIDPREFAT.numtransvenda)
                   AND PCNFSAIDPREFAT.dtcancel is null

                /*MED-2277*/
                UNION
                  SELECT numtransvenda, dtfechaccrca
                    FROM PCNFSAID
                   WHERE caixa = p_numcheckout
                     AND codemitente = p_codfunccheckout
                     AND dtsaida = p_dataemissao
                        --Tarefa 105946
                     AND EXISTS
                   (select pcpedc.numtransvenda
                            from pcpedc
                           where pcpedc.numtransvenda = PCNFSAID.numtransvenda)
                     AND PCNFSAID.dtcancel is null
                ) LOOP
      vbvalido := ccrca_verificar_fechamento(reg.numtransvenda);

      IF vbvalido = TRUE THEN
        IF reg.dtfechaccrca IS NULL THEN
          ccrca_validar_acerto_nf(p_codfunclanc,
                                  p_rotinalanc,
                                  reg.numtransvenda);
        END IF;
      END IF;
    END LOOP;

    p_mensagem := vsmensagem;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao lancar movimento caiga.' || SQLCODE || ' ' ||
                    SQLERRM;
  END; --ccrca_lancar_movimento_caixa

  --RNG07 / PARA ALTERACAO DE PRECO
  FUNCTION ccrca_retorna_saldo_anterior( -- 11 parametros
                                        p_numped                    IN pcpedc.numped%TYPE,
                                        p_codusur                   IN pcpedc.codusur%TYPE,
                                        p_codprod                   IN pcpedi.codprod%TYPE,
                                        p_numseq                    IN pcpedi.numseq%TYPE,
                                        p_qt                        IN pcpedi.qt%TYPE,
                                        p_pvenda                    IN pcpedi.pvenda%TYPE,
                                        p_pbaserca                  IN pcpedi.pbaserca%TYPE,
                                        p_ptabela                   IN pcpedi.ptabela%TYPE,
                                        p_tipo                      IN VARCHAR,
                                        p_usadebcredrcabrind        IN pcpedi.usadebcredrcabrind%TYPE,
                                        p_movimentacontacorrenterca IN pcpedi.movimentacontacorrenterca%type
                                        -- Sabrina: tipo de operação I - Inclusao e E - Exclusao
                                        ) RETURN NUMBER IS
    vsusacredrca           pcpedc.usacredrca%TYPE;
    vsbonificaltdebcredrca pcpedc.bonificaltdebcredrca%TYPE;
    vstrocaaltdebcredrca   pcpedc.trocaaltdebcredrca%TYPE;
    vsbrokeraltdebcredrca  pcpedc.brokeraltdebcredrca%TYPE;
    vscrmaltdebcredrca     pcpedc.crmaltdebcredrca%TYPE;
    vstipomovccrca         pcpedc.tipomovccrca%TYPE;
    vsusadebcredrca        pcpedc.usadebcredrca%TYPE;
    vsorigemped            pcpedc.origemped%TYPE;
    vsbrinde               pcpedc.brinde%TYPE;
    vncondvenda            pcpedc.condvenda%TYPE;
    vsbroker               pcpedc.broker%TYPE;
    vnlanc                 NUMBER;
    vsmsg                  VARCHAR2(400);
    -- HIS.00632.2016
    vncodusur              pcpedc.codusur%type;
  BEGIN
    proc_lerparametros(vsmsg);

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(p_codusur,
                                       p_numped);

    SELECT p.usacredrca,
           p.bonificaltdebcredrca,
           p.trocaaltdebcredrca,
           p.brokeraltdebcredrca,
           p.crmaltdebcredrca,
           p.tipomovccrca,
           DECODE(p.usadebcredrca,
                  NULL,
                  (SELECT NVL(pcusuari.usadebcredrca, gregpcconsum.usacredrca)
                     FROM pcusuari
                    WHERE codusur = vncodusur -- HIS.00632.2016 -- p.codusur
                      AND ROWNUM = 1),
                  p.usadebcredrca),
           p.origemped,
           NVL(p.brinde, 'N'),
           p.condvenda,
           NVL(p.broker, 'N')
      INTO vsusacredrca,
           vsbonificaltdebcredrca,
           vstrocaaltdebcredrca,
           vsbrokeraltdebcredrca,
           vscrmaltdebcredrca,
           vstipomovccrca,
           vsusadebcredrca,
           vsorigemped,
           vsbrinde,
           vncondvenda,
           vsbroker
      FROM pcpedc p
     WHERE p.numped = p_numped;

    IF p_qt > 0 THEN
      vnlanc := ccrca_saldo_item(NVL(vsusacredrca, gregpcconsum.usacredrca),
                                 vsusadebcredrca,
                                 vsbroker,
                                 vsorigemped,
                                 NVL(vsbonificaltdebcredrca,
                                     gregpcconsum.bonificaltdebcredrca),
                                 NVL(vstrocaaltdebcredrca,
                                     gregpcconsum.trocaaltdebcredrca),
                                 NVL(vscrmaltdebcredrca,
                                     gregpcconsum.crmaltdebcredrca),
                                 NVL(vsbrokeraltdebcredrca,
                                     gregpcconsum.brokeraltdebcredrca),
                                 NVL(vstipomovccrca,
                                     NVL(gregpcconsum.tipomovccrca, 'VV')),
                                 vncondvenda,
                                 vsbrinde,
                                 vncodusur, -- HIS.00632.2016 -- p_codusur,
                                 'V',
                                 p_pvenda,
                                 p_ptabela,
                                 NVL(p_pbaserca, p_ptabela),
                                 p_qt,
                                 p_usadebcredrcabrind,
                                 p_movimentacontacorrenterca,
                                 'N'); -- MED-2073
    ELSE
      vnlanc := 0; --(recebimentos em trocas)
    END IF;

    RETURN vnlanc;
  END; --ccrca_retornar_saldo_anterior

  FUNCTION ccrca_retorna_saldo_anterior( -- 14 parametros
                                        p_numped                    IN pcpedc.numped%TYPE,
                                        p_codusur                   IN pcpedc.codusur%TYPE,
                                        p_codprod                   IN pcpedi.codprod%TYPE,
                                        p_numseq                    IN pcpedi.numseq%TYPE,
                                        p_qt                        IN pcpedi.qt%TYPE,
                                        p_pvenda                    IN pcpedi.pvenda%TYPE,
                                        p_pbaserca                  IN pcpedi.pbaserca%TYPE,
                                        p_ptabela                   IN pcpedi.ptabela%TYPE,
                                        -- Sabrina: tipo de operação I - Inclusao e E - Exclusao
                                        p_tipo                      IN VARCHAR,
                                        p_usadebcredrcabrind        IN pcpedi.usadebcredrcabrind%TYPE,
                                        p_movimentacontacorrenterca IN pcpedi.movimentacontacorrenterca%type,
                                        p_stpvenda                  IN pcpedi.st%TYPE,
                                        p_stptabela                 IN pcpedi.stptabela%TYPE,
                                        p_stpbaserca                IN pcpedi.stpbaserca%TYPE
                                        ) RETURN NUMBER IS
    vsusacredrca           pcpedc.usacredrca%TYPE;
    vsbonificaltdebcredrca pcpedc.bonificaltdebcredrca%TYPE;
    vstrocaaltdebcredrca   pcpedc.trocaaltdebcredrca%TYPE;
    vsbrokeraltdebcredrca  pcpedc.brokeraltdebcredrca%TYPE;
    vscrmaltdebcredrca     pcpedc.crmaltdebcredrca%TYPE;
    vstipomovccrca         pcpedc.tipomovccrca%TYPE;
    vsusadebcredrca        pcpedc.usadebcredrca%TYPE;
    vsorigemped            pcpedc.origemped%TYPE;
    vsbrinde               pcpedc.brinde%TYPE;
    vncondvenda            pcpedc.condvenda%TYPE;
    vsbroker               pcpedc.broker%TYPE;
    vnlanc                 NUMBER;
    vsmsg                  VARCHAR2(400);
    -- HIS.00632.2016
    vncodusur              pcpedc.codusur%type;
    -- CC_ITEMBNF
    vsbonific              pcpedi.BONIFIC%TYPE;
    -- DDVENDAS-41579
    vsItemBrinde           pcpedi.brinde%TYPE;
  BEGIN
    proc_lerparametros(vsmsg);

    -- HIS.00632.2016
    vncodusur := ObterRcaContaCorrente(p_codusur,
                                       p_numped);

    SELECT p.usacredrca,
           p.bonificaltdebcredrca,
           p.trocaaltdebcredrca,
           p.brokeraltdebcredrca,
           p.crmaltdebcredrca,
           p.tipomovccrca,
           DECODE(p.usadebcredrca,
                  NULL,
                  (SELECT NVL(pcusuari.usadebcredrca, gregpcconsum.usacredrca)
                     FROM pcusuari
                    WHERE codusur = vncodusur -- HIS.00632.2016 -- p.codusur
                      AND ROWNUM = 1),
                  p.usadebcredrca),
           p.origemped,
           NVL(p.brinde, 'N'),
           p.condvenda,
           NVL(p.broker, 'N')
      INTO vsusacredrca,
           vsbonificaltdebcredrca,
           vstrocaaltdebcredrca,
           vsbrokeraltdebcredrca,
           vscrmaltdebcredrca,
           vstipomovccrca,
           vsusadebcredrca,
           vsorigemped,
           vsbrinde,
           vncondvenda,
           vsbroker
      FROM pcpedc p
     WHERE p.numped = p_numped;

    -- CC_ITEMBNF
    BEGIN
      SELECT NVL(PCPEDI.BONIFIC, 'N') BONIFIC,
             pcpedi.brinde -- DDVENDAS-41579
        INTO vsbonific,
             vsItemBrinde -- DDVENDAS-41579
        FROM PCPEDI
       WHERE PCPEDI.NUMPED = P_NUMPED
         AND PCPEDI.CODPROD = P_CODPROD
         AND PCPEDI.NUMSEQ = P_NUMSEQ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vsbonific := 'N';
        vsItemBrinde := 'N'; -- DDVENDAS-41579
    END;

    -- DDVENDAS-41579
    IF (vsItemBrinde = 'S') THEN
      vsbrinde := 'S';
    END IF;
    
    IF p_qt > 0 THEN
      vnlanc := ccrca_saldo_item(NVL(vsusacredrca, gregpcconsum.usacredrca),
                                 vsusadebcredrca,
                                 vsbroker,
                                 vsorigemped,
                                 NVL(vsbonificaltdebcredrca,
                                     gregpcconsum.bonificaltdebcredrca),
                                 NVL(vstrocaaltdebcredrca,
                                     gregpcconsum.trocaaltdebcredrca),
                                 NVL(vscrmaltdebcredrca,
                                     gregpcconsum.crmaltdebcredrca),
                                 NVL(vsbrokeraltdebcredrca,
                                     gregpcconsum.brokeraltdebcredrca),
                                 NVL(vstipomovccrca,
                                     NVL(gregpcconsum.tipomovccrca, 'VV')),
                                 vncondvenda,
                                 vsbrinde,
                                 vncodusur, -- HIS.00632.2016 -- p_codusur,
                                 'V',
                                 p_pvenda,
                                 p_ptabela,
                                 NVL(p_pbaserca, p_ptabela),
                                 p_qt,
                                 p_usadebcredrcabrind,
                                 p_movimentacontacorrenterca,
                                 p_stpvenda,
                                 p_stptabela,
                                 p_stpbaserca,
                                 vsbonific -- CC_ITEMBNF
                                 );
    ELSE
      vnlanc := 0; --(recebimentos em trocas)
    END IF;

    RETURN vnlanc;
  END; --ccrca_retornar_saldo_anterior

  -- HIS.01108.2016 - Crédito do Conta Corrente por Liquidez
  FUNCTION ccrca_incluir_titulo(p_numped        pcpedc.numped%TYPE,
                                p_numtransvenda PCPRESTPREFAT.numtransvenda%TYPE,
                                p_prest         PCPRESTPREFAT.prest%TYPE,
                                p_valorprest    PCPRESTPREFAT.valor%TYPE,
                                p_codfunclanc   pclogrca.codfunc%TYPE,
                                p_rotinalanc    pclogrca.rotina%TYPE)
    RETURN VARCHAR2 IS
    vstipomovccrca    pcpedc.tipomovccrca%TYPE;
    vncodusur         pcpedc.codusur%TYPE;
    vsposicao         pcpedc.posicao%TYPE;
    vsusadebcredrca   pcusuari.usadebcredrca%TYPE;
    vnvltotal_nf      PCNFSAIDPREFAT.vltotal%TYPE;
    vvalido           VARCHAR2(1);
    vsmsg             VARCHAR2(400);
    vnpercrateio      number;
    vvtipomovccrca    pcpedc.tipomovccrca%TYPE;
    vncondvenda       pcpedc.condvenda%TYPE;
    vnvlcorrente_ant  pcusuari.vlcorrente%TYPE;
    vnvllimcred       pcusuari.vllimcred%TYPE;
    vnvllimcred_atual pcusuari.vllimcred%TYPE;
    vnvalorlanc       pclogrca.vlcorrente%TYPE;
    -- Variáveis para Rateio Crédito C/C RCA
    nPERCRATEIOCREDRCASUPERVISOR    NUMBER;
    nPERCRATEIOCREDSUPERVEMPRESA    NUMBER;
    vncodsupervisor                 pcusuari.codsupervisor%type;
    vncod_cadrca_supervisor         PCSUPERV.COD_CADRCA%TYPE;
    vncod_cadrca_empresa            PCUSUARI.CODUSUR%TYPE;
    vnValorTransf                   NUMBER(15,2);
    vnValorTransfSupervisor         NUMBER(15,2);
    vnValorTransfEmpresa            NUMBER(15,2);
  BEGIN
    proc_lerparametros(vsmsg);
    vvalido := 'S';

    -- Obter % Rateio de Crédito de C/C RCA
    nPERCRATEIOCREDRCASUPERVISOR := F_PERCRATEIOCREDRCASUPERVISOR;

    BEGIN
      SELECT pcpedc.tipomovccrca
           , pcpedc.codusur
           , pcpedc.tipomovccrca
           , pcpedc.condvenda
        INTO vstipomovccrca
           , vncodusur
           , vvtipomovccrca
           , vncondvenda
        FROM pcpedc
       WHERE numped = p_numped;
    EXCEPTION
      WHEN OTHERS THEN
        vvalido := 'A';
    END;

    -- LIMITE_FLEX
    IF (vvtipomovccrca = 'LL') THEN

      BEGIN
        SELECT PCNFSAIDPREFAT.vltotal
          INTO vnvltotal_nf
          FROM PCNFSAIDPREFAT
         WHERE numtransvenda = p_numtransvenda;
      EXCEPTION
        WHEN OTHERS THEN
          vvalido := 'B';
      END;

      /*MED-2277*/
      IF vvalido = 'B' THEN
        BEGIN
          vvalido := 'S';
          SELECT PCNFSAID.vltotal
            INTO vnvltotal_nf
            FROM PCNFSAID
           WHERE numtransvenda = p_numtransvenda;
        EXCEPTION
          WHEN OTHERS THEN
            vvalido := 'B';
        END;
      END IF;

      -- HIS.00632.2016
      vncodusur := ObterRcaContaCorrente(vncodusur,
                                         p_numped);

      BEGIN
        SELECT pcusuari.usadebcredrca
             , pcusuari.vlcorrente
             , pcusuari.vllimcred
             , pcusuari.codsupervisor
          INTO vsusadebcredrca
             , vnvlcorrente_ant
             , vnvllimcred
             , vncodsupervisor
          FROM pcusuari
         WHERE codusur = vncodusur;
      EXCEPTION
        WHEN OTHERS THEN
          vvalido := 'D';
      END;

      -- Se Válido
      IF vvalido = 'S' THEN

        -- Pesquisa o valor do rateio (percentual do valor do título sobre o valor total da NF)
        IF (NVL(vnvltotal_nf,0) > 0) THEN
          vnpercrateio := NVL(p_valorprest,0) / NVL(vnvltotal_nf,0);
        ELSE
          vnpercrateio := 0;
        END IF;

        -- Pesquisa o Valor Saldo do Item
        BEGIN
          SELECT SUM(CASE WHEN (NVL(BONIFIC,'N') = 'F') OR
                               (vncondvenda =  5) THEN
                       (((0 - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                     ELSE
                       ((((PVENDA-NVL(ST,0)) - NVL((PBASERCA-NVL(STPBASERCA,0)), (PTABELA-NVL(ST,0)))) * QT))
                     END)
            INTO vnvalorlanc
            FROM PCPEDI
           WHERE (NUMPED  = p_numped);
        EXCEPTION
          WHEN OTHERS THEN
            vvalido := 'G';
        END;

        -- Se Válido e houve Saldo de Crédito no Pedido
        IF (vvalido = 'S') AND
           (vnvalorlanc > 0) THEN

          -- Aplica o Rateio da Liquidez
          vnvalorlanc       := (vnvalorlanc * vnpercrateio);

          vnvllimcred_atual := NVL(vnvllimcred, 0) + NVL(vnvalorlanc, 0);

          UPDATE pcusuari
             SET vllimcred = vnvllimcred_atual
           WHERE codusur = vncodusur;

          INSERT INTO pcloglimitecredrcamed
            (numped,
             posicao,
             numtransvenda,
             DATA,
             codfunc,
             codusur,
             rotina,
             vlcorrente,
             vllimcred,
             vlcorrenteant,
             vllimcredant,
             codprod,
             numseq,
             historico,
             PREST,
             PERCRATEIOLIQUIDEZMED,
             PERCRATEIOCREDRCASUPERVISOR)
          VALUES
            (p_numped,
             vsposicao,
             p_numtransvenda,
             SYSDATE,
             p_codfunclanc,
             vncodusur,
             p_rotinalanc,
             vnvlcorrente_ant,
             vnvllimcred_atual,
             vnvlcorrente_ant,
             vnvllimcred,
             0, -->> Sem código do Produto
             0, -->> Sem NUMSEQ
             SUBSTR('CTRLCCRCA: LANCAMENTO SALDO LIQUIDEZ', 1, 60),
             p_prest,
             (vnpercrateio * 100), -- Percentual de Rateio do Título
             nPERCRATEIOCREDRCASUPERVISOR);

          ------------------------------------------------
          -- Se houver Rateio de Crédito de C/C RCA
          -- E estiver chamando da Inclusão da Nota Fiscal
          ------------------------------------------------
          IF (F_USARATEIOCREDRCASUPERVISOR(vncodusur,
                                           NVL(nPERCRATEIOCREDRCASUPERVISOR,0),
                                           NVL(vnvalorlanc,0))) THEN

            -- Pesquisa o RCA vinculado ao Supervisor
            BEGIN
              SELECT PCUSUARI.CODUSUR
                INTO vncod_cadrca_supervisor
                FROM PCSUPERV
                   , PCUSUARI
               WHERE (PCSUPERV.CODSUPERVISOR = vncodsupervisor)
                 AND (PCUSUARI.CODUSUR       = PCSUPERV.COD_CADRCA);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vncod_cadrca_supervisor := NULL;
            END;

            -- Pesquisa o RCA vinculado a Empresa
            vncod_cadrca_empresa := F_OBTER_RCA_EMPRESA;

            -- Se o Supervisor movimenta C/C
            IF (NVL(vncod_cadrca_supervisor,0) > 0) THEN

              -- Valor da Transferência - Diferença do % que ficará com o RCA
              vnValorTransf := ROUND(NVL(vnvalorlanc,0) * (1 - (NVL(nPERCRATEIOCREDRCASUPERVISOR,0) / 100)),2);

              -- DEBITANDO RCA --------------------------------------------------------------------------
              IF (NVL(vnValorTransf,0) > 0) THEN

                SELECT pcusuari.vlcorrente, pcusuari.vllimcred
                  INTO vnvlcorrente_ant, vnvllimcred
                  FROM pcusuari
                 WHERE codusur = vncodusur; -- RCA

                vnvllimcred_atual := NVL(vnvllimcred, 0) - NVL(vnValorTransf, 0);

                UPDATE pcusuari
                   SET vllimcred = vnvllimcred_atual
                 WHERE codusur = vncodusur; -- RCA

                INSERT INTO pcloglimitecredrcamed
                  (numped,
                   posicao,
                   numtransvenda,
                   DATA,
                   codfunc,
                   codusur,
                   rotina,
                   vlcorrente,
                   vllimcred,
                   vlcorrenteant,
                   vllimcredant,
                   codprod,
                   numseq,
                   historico,
                   PREST,
                   PERCRATEIOLIQUIDEZMED,
                   PERCRATEIOCREDRCASUPERVISOR)
                VALUES
                  (p_numped,
                   vsposicao,
                   p_numtransvenda,
                   SYSDATE,
                   p_codfunclanc,
                   vncodusur, -- RCA
                   p_rotinalanc,
                   vnvlcorrente_ant,
                   vnvllimcred_atual,
                   vnvlcorrente_ant,
                   vnvllimcred,
                   0, -->> Sem código do Produto
                   0, -->> Sem NUMSEQ
                   SUBSTR('CTRLCCRCA: LANCAMENTO RATEIO RCA LIQUIDEZ', 1, 60),
                   p_prest,
                   (vnpercrateio * 100), -- Percentual de Rateio do Título
                   nPERCRATEIOCREDRCASUPERVISOR);

                -- RATEIO ENTRE SUPERVISOR E EMPRESA ------------------------------------------------------

                -- Obter % Rateio de Crédito de C/C Supervisor e Empresa
                nPERCRATEIOCREDSUPERVEMPRESA := F_PERCRATEIOCREDSUPERVEMPRESA;

                ------------------------------------------------------------
                -- Se houver Rateio de Crédito de C/C Supervisor com Empresa
                ------------------------------------------------------------
                IF (F_USARATEIOCREDSUPERVEMPRESA(vncod_cadrca_empresa,
                                                 nPERCRATEIOCREDSUPERVEMPRESA,
                                                 vnValorTransf)) THEN
                  -- Calcula a parte do Supervisor
                  vnValorTransfSupervisor := ROUND(vnValorTransf * (NVL(nPERCRATEIOCREDSUPERVEMPRESA,0) / 100),2);
                  -- Calcula a parte da Empresa
                  vnValorTransfEmpresa    := (NVL(vnValorTransf,0) - NVL(vnValorTransfSupervisor,0));
                ELSE
                  -- Somente tem a parte do Supervisor
                  vnValorTransfSupervisor := vnValorTransf;
                  -- Não tem a parte da Empresa
                  vnValorTransfEmpresa    := 0;
                END IF;

                -- CREDITANDO SUPERVISOR ------------------------------------------------------------------
                IF (NVL(vnValorTransfSupervisor,0) > 0) THEN

                  SELECT pcusuari.vlcorrente, pcusuari.vllimcred
                    INTO vnvlcorrente_ant, vnvllimcred
                    FROM pcusuari
                   WHERE codusur = vncod_cadrca_supervisor; -- SUPERVISOR

                  vnvllimcred_atual := NVL(vnvllimcred, 0) + NVL(vnValorTransfSupervisor, 0);

                  UPDATE pcusuari
                     SET vllimcred = vnvllimcred_atual
                   WHERE codusur = vncod_cadrca_supervisor; -- SUPERVISOR

                  INSERT INTO pcloglimitecredrcamed
                    (numped,
                     posicao,
                     numtransvenda,
                     DATA,
                     codfunc,
                     codusur,
                     rotina,
                     vlcorrente,
                     vllimcred,
                     vlcorrenteant,
                     vllimcredant,
                     codprod,
                     numseq,
                     historico,
                     PREST,
                     PERCRATEIOLIQUIDEZMED,
                     PERCRATEIOCREDRCASUPERVISOR)
                  VALUES
                    (p_numped,
                     vsposicao,
                     p_numtransvenda,
                     SYSDATE,
                     p_codfunclanc,
                     vncod_cadrca_supervisor, -- SUPERVISOR
                     p_rotinalanc,
                     vnvlcorrente_ant,
                     vnvllimcred_atual,
                     vnvlcorrente_ant,
                     vnvllimcred,
                     0, -->> Sem código do Produto
                     0, -->> Sem NUMSEQ
                     SUBSTR('CTRLCCRCA: LANCAMENTO RATEIO SUPERV LIQUIDEZ', 1, 60),
                     p_prest,
                     (vnpercrateio * 100), -- Percentual de Rateio do Título
                     nPERCRATEIOCREDRCASUPERVISOR);

                END IF; -- Fim Condição: CREDITANDO SUPERVISOR

                -- CREDITANDO EMPRESA ---------------------------------------------------------------------
                IF (NVL(vncod_cadrca_empresa,0) > 0) AND
                   (NVL(vnValorTransfEmpresa,0) > 0) THEN

                  SELECT pcusuari.vlcorrente, pcusuari.vllimcred
                    INTO vnvlcorrente_ant, vnvllimcred
                    FROM pcusuari
                   WHERE codusur = vncod_cadrca_empresa; -- EMPRESA

                  vnvllimcred_atual := NVL(vnvllimcred, 0) + NVL(vnValorTransfEmpresa, 0); -- INCREMENTANDO VALOR TRANSF.

                  UPDATE pcusuari
                     SET vllimcred = vnvllimcred_atual
                   WHERE codusur = vncod_cadrca_empresa; -- EMPRESA

                  INSERT INTO pcloglimitecredrcamed
                    (numped,
                     posicao,
                     numtransvenda,
                     DATA,
                     codfunc,
                     codusur,
                     rotina,
                     vlcorrente,
                     vllimcred,
                     vlcorrenteant,
                     vllimcredant,
                     codprod,
                     numseq,
                     historico,
                     PREST,
                     PERCRATEIOLIQUIDEZMED,
                     PERCRATEIOCREDRCASUPERVISOR)
                  VALUES
                    (p_numped,
                     vsposicao,
                     p_numtransvenda,
                     SYSDATE,
                     p_codfunclanc,
                     vncod_cadrca_empresa, -- EMPRESA
                     p_rotinalanc,
                     vnvlcorrente_ant,
                     vnvllimcred_atual,
                     vnvlcorrente_ant,
                     vnvllimcred,
                     0, -->> Sem código do Produto
                     0, -->> Sem NUMSEQ
                     SUBSTR('CTRLCCRCA: LANCAMENTO RATEIO EMPRESA LIQUIDEZ', 1, 60),
                     p_prest,
                     (vnpercrateio * 100), -- Percentual de Rateio do Título
                     nPERCRATEIOCREDSUPERVEMPRESA);

                END IF; -- Fim Condição: CREDITANDO EMPRESA

              END IF; -- Fim Condição: DEBITANDO RCA

            END IF; -- Fim Condição Se o Supervisor movimenta C/C
          END IF; -- Fim Condição Rateio Saldo C/C


        END IF; -- Sim Condição: -- Se Válido e houve Saldo de Crédito no Pedido

      END IF; -- Fim Condição: Se Válido

    END IF; -- LIMITE_FLEX

    RETURN vvalido;

  END; -- ccrca_incluir_titulo

  procedure ccrca_estorna_item_pedidomed(p_codfunclanc IN pclogrca.codfunc%TYPE,
                                         p_rotinalanc  IN pclogrca.rotina%TYPE,
                                         p_codusur     IN pcpedc.codusur%TYPE,
                                         p_numped      IN pcpedc.numped%TYPE,
                                         p_codprod     IN pcpedi.codprod%TYPE,
                                         p_numseq      IN pcpedi.numseq%TYPE,
                                         p_vlrsaldo    IN number) IS
  /*******************************************************************************
   Nome         : ccrca_estorna_item_pedidomed
   Descricão    : Estorno C/C Edição da Promoção
  ********************************************************************************/
      vnvalorlanc        NUMBER;
      vnvlcorrente_ant   pcusuari.vlcorrente%TYPE;
      vsusadebcredrca    pcusuari.usadebcredrca%TYPE;
      vnvllimcred        pcusuari.vllimcred%TYPE;
      vnvlcorrente_atual pcusuari.vlcorrente%TYPE;
      vddata             pcpedc.DATA%TYPE;
      vnnumtransvenda    pcpedc.numtransvenda%TYPE;
      vsposicao          pcpedc.posicao%TYPE;
      vbvalido           BOOLEAN;
      -- Log
      TYPE TRecItem                   IS RECORD(
           nPVENDA                    pclogrca.PVENDA%TYPE,
           nST                        pclogrca.ST%TYPE,
           nPBASERCA                  pclogrca.PBASERCA%TYPE,
           nSTPBASERCA                pclogrca.STPBASERCA%TYPE,
           nPTABELA                   pclogrca.PTABELA%TYPE,
           nSTPTABELA                 pclogrca.STPTABELA%TYPE,
           nBONIFIC                   pclogrca.BONIFIC%TYPE,
           nQT                        pclogrca.QT%TYPE,
           vUSADEBCREDRCABRIND        pclogrca.USADEBCREDRCABRIND%TYPE,
           vMOVIMENTACONTACORRENTERCA pclogrca.MOVIMENTACONTACORRENTERCA%TYPE,
           nCODPROMOCAOMED            pclogrca.CODPROMOCAOMED%TYPE);
      vrItem                          TRecItem;

      vncodusur                       pcpedc.codusur%type;

      -- LIMITE_FLEX
      vvtipomovccrca                  pcpedc.tipomovccrca%type;
      vnvllimcred_atual               pcusuari.vllimcred%type;

  BEGIN

    vbvalido := TRUE;

    -------------------------------------------------------------------------------------------------
    -- HIS.00065.2018 - Se usar o saldo C/C somente no próprio pedido, não acumula o Saldo C/C no RCA
    -------------------------------------------------------------------------------------------------
    IF (F_USARSALDORCASOMENTENOPEDIDO) THEN

      vbvalido := TRUE;

    -----------------------------------------------------------------------------------------
    -- Processo Padrão
    -----------------------------------------------------------------------------------------
    ELSE

      vncodusur := ObterRcaContaCorrente(p_codusur,
                                         p_numped);

      -- Pesquisa o último Lançamento
      FOR vc_Log IN (SELECT pclogrca.DATA,
                            pclogrca.PVENDA,
                            pclogrca.ST,
                            pclogrca.PBASERCA,
                            pclogrca.STPBASERCA,
                            pclogrca.PTABELA,
                            pclogrca.STPTABELA,
                            pclogrca.BONIFIC,
                            pclogrca.QT,
                            pclogrca.USADEBCREDRCABRIND,
                            pclogrca.MOVIMENTACONTACORRENTERCA,
                            pclogrca.CODPROMOCAOMED
                       FROM pclogrca
                      WHERE (pclogrca.NUMPED  = p_numped)
                        AND (pclogrca.CODPROD = p_codprod)
                        AND (pclogrca.NUMSEQ  = p_numseq)
                      ORDER BY pclogrca.DATA) LOOP -->> Ordenado da menor data mais antiga para a data mais recente

        -- Último Histórico é o que será replicado
        vrItem.nPVENDA                    := vc_Log.PVENDA;
        vrItem.nST                        := vc_Log.ST;
        vrItem.nPBASERCA                  := vc_Log.PBASERCA;
        vrItem.nSTPBASERCA                := vc_Log.STPBASERCA;
        vrItem.nPTABELA                   := vc_Log.PTABELA;
        vrItem.nSTPTABELA                 := vc_Log.STPTABELA;
        vrItem.nBONIFIC                   := vc_Log.BONIFIC;
        vrItem.nQT                        := vc_Log.QT;
        vrItem.vUSADEBCREDRCABRIND        := vc_Log.USADEBCREDRCABRIND;
        vrItem.vMOVIMENTACONTACORRENTERCA := vc_Log.MOVIMENTACONTACORRENTERCA;
        vrItem.nCODPROMOCAOMED            := vc_Log.CODPROMOCAOMED;

      END LOOP;

      SELECT pcpedc.DATA, pcpedc.numtransvenda, pcpedc.posicao, pcpedc.tipomovccrca
        INTO vddata, vnnumtransvenda, vsposicao, vvtipomovccrca
        FROM pcpedc
       WHERE numped = p_numped;

      SELECT pcusuari.usadebcredrca, pcusuari.vlcorrente, pcusuari.vllimcred
        INTO vsusadebcredrca, vnvlcorrente_ant, vnvllimcred
        FROM pcusuari
       WHERE codusur = vncodusur;

      vnvalorlanc := p_vlrsaldo;

      -- LIMITE_FLEX
      IF (NVL(vvtipomovccrca,' ') = 'LL') THEN

        -- Se Usou Limite
        IF (vnvalorlanc <> 0) THEN

          -- ( E - Estorno)
          vnvllimcred_atual := NVL(vnvllimcred, 0) + NVL(vnvalorlanc, 0);

          UPDATE pcusuari
             SET vllimcred = vnvllimcred_atual
           WHERE codusur = vncodusur;

          INSERT INTO pcloglimitecredrcamed
            (numped,
             posicao,
             numtransvenda,
             DATA,
             codfunc,
             codusur,
             rotina,
             vlcorrente,
             vllimcred,
             vlcorrenteant,
             vllimcredant,
             codprod,
             numseq,
             historico,
             PVENDA,
             ST,
             PBASERCA,
             STPBASERCA,
             PTABELA,
             STPTABELA,
             BONIFIC,
             QT,
             USADEBCREDRCABRIND,
             MOVIMENTACONTACORRENTERCA,
             CODPROMOCAOMED)
          VALUES
            (p_numped,
             vsposicao,
             vnnumtransvenda,
             SYSDATE,
             p_codfunclanc,
             vncodusur,
             p_rotinalanc,
             vnvlcorrente_ant,
             vnvllimcred_atual,
             vnvlcorrente_ant,
             vnvllimcred,
             p_codprod,
             p_numseq,
             SUBSTR('CTRLCCRCA: ESTORNO DE SALDO DE ITEM PEDIDO MED', 1, 60),
             vrItem.nPVENDA,
             vrItem.nST,
             vrItem.nPBASERCA,
             vrItem.nSTPBASERCA,
             vrItem.nPTABELA,
             vrItem.nSTPTABELA,
             vrItem.nBONIFIC,
             vrItem.nQT,
             vrItem.vUSADEBCREDRCABRIND,
             vrItem.vMOVIMENTACONTACORRENTERCA,
             vrItem.nCODPROMOCAOMED);

        END IF; -- Fim: Se Usou Limite

      ELSE

        -- incluído por sabrina ( E - Estorno)
        vnvlcorrente_atual := NVL(vnvlcorrente_ant, 0) - NVL(vnvalorlanc, 0);

        -- a package não deve barrar a movimentacao do saldo, os programas eh que fazem isso
        --IF vnvlcorrente_atual >= 0 THEN
        UPDATE pcusuari
           SET vlcorrente = vnvlcorrente_atual
         WHERE codusur = vncodusur; -- HIS.00632.2016 -- p_codusur;

        INSERT INTO pclogrca
          (numped,
           posicao,
           numtransvenda,
           DATA,
           codfunc,
           codusur,
           rotina,
           vlcorrente,
           vllimcred,
           vlcorrenteant,
           vllimcredant,
           codprod,
           numseq,
           historico,
           PVENDA,
           ST,
           PBASERCA,
           STPBASERCA,
           PTABELA,
           STPTABELA,
           BONIFIC,
           QT,
           USADEBCREDRCABRIND,
           MOVIMENTACONTACORRENTERCA,
           CODPROMOCAOMED)
        VALUES
          (p_numped,
           vsposicao,
           vnnumtransvenda,
           SYSDATE,
           p_codfunclanc,
           vncodusur,
           p_rotinalanc,
           vnvlcorrente_atual,
           vnvllimcred,
           vnvlcorrente_ant,
           vnvllimcred,
           p_codprod,
           p_numseq,
           SUBSTR('CTRLCCRCA: ESTORNO DE SALDO DE ITEM PEDIDO MED', 1, 60),
           vrItem.nPVENDA,
           vrItem.nST,
           vrItem.nPBASERCA,
           vrItem.nSTPBASERCA,
           vrItem.nPTABELA,
           vrItem.nSTPTABELA,
           vrItem.nBONIFIC,
           vrItem.nQT,
           vrItem.vUSADEBCREDRCABRIND,
           vrItem.vMOVIMENTACONTACORRENTERCA,
           vrItem.nCODPROMOCAOMED);

      END IF; -- LIMITE_FLEX

    END IF; -- Fim Condição: Se usar o saldo C/C somente no próprio pedido, não acumula o Saldo C/C no RCA

  END; --ccrca_estorna_item_pedidomed

  -- Procedimento para Controlar a Edição do Pedido (INICIO)
  PROCEDURE ccrca_inicio_edicao_pedido(p_numped      pcpedc.numped%TYPE,
                                       p_codfunclanc pclogrca.codfunc%TYPE,
                                       p_rotinalanc  pclogrca.rotina%TYPE)
  IS
    vvtipomovccrca           pcpedc.tipomovccrca%type;
    vnVlUnitLimCredRcaUtiliz NUMBER;
  BEGIN

    SELECT pcpedc.tipomovccrca
      INTO vvtipomovccrca
      FROM pcpedc
     WHERE numped = p_numped;

    -- Se permite Controle de Edição do Pedido
    IF (vvtipomovccrca = 'LL') THEN

      -- Limpa Tabela Temporária
      DELETE FROM PCMED_EDICAOPEDIDO;

      -- Carrega Tabela Temporária
      INSERT INTO PCMED_EDICAOPEDIDO
                ( NUMPED
                , CODPROD
                , NUMSEQ
                , QT
                , PTABELA
                , PERDESC
                , PVENDA
                , ST
                , PBASERCA
                , STPBASERCA
                , PERCDESCBASERCA
                , CODDESCONTO
                , CODPROMOCAOMED
                , PERCOM
                , TIPOCOMISSAOMED
                , VLUNITLIMCREDRCAUTILIZMED
                , VLLIMCREDRCAUTILIZ )
           SELECT NUMPED
                , CODPROD
                , NUMSEQ
                , QT
                , PTABELA
                , PERDESC
                , PVENDA
                , ST
                , PBASERCA
                , STPBASERCA
                , PERCDESCBASERCA
                , CODDESCONTO
                , CODPROMOCAOMED
                , PERCOM
                , TIPOCOMISSAOMED
                , VLUNITLIMCREDRCAUTILIZMED
                , ROUND((VLUNITLIMCREDRCAUTILIZMED * QT),2)
             FROM PCPEDI
            WHERE (NUMPED = p_numped);

      -- Limpa Controle de Utilização do Limite do RCA
      UPDATE PCPEDI
         SET VLUNITLIMCREDRCAUTILIZMED = NULL
       WHERE (NUMPED = p_numped);

    END IF; -- Fim Condição Se permite Controle de Edição do Pedido

  END ccrca_inicio_edicao_pedido;

  -- Procedimento para Controlar a Edição do Pedido (FIM)
  PROCEDURE ccrca_fim_edicao_pedido(p_numped      pcpedc.numped%TYPE,
                                    p_codfunclanc pclogrca.codfunc%TYPE,
                                    p_rotinalanc  pclogrca.rotina%TYPE)
  IS
    vvtipomovccrca           pcpedc.tipomovccrca%type;
    vncodusur                pcpedc.codusur%type;
    vnVlUnitLimCredRcaUtiliz NUMBER;
    vnValorSaldoAnterior     NUMBER;
    vnQtAnterior             NUMBER;
    vnPBaseAnterior          NUMBER;
    vnPVendaAnterior         NUMBER;
    vnNovaQt                 NUMBER;
    vnNovoPBase              NUMBER;
    vnNovoPVenda             NUMBER;
    vbvalido                 BOOLEAN;
  BEGIN

    SELECT pcpedc.tipomovccrca
         , pcpedc.codusur
      INTO vvtipomovccrca
         , vncodusur
      FROM pcpedc
     WHERE numped = p_numped;

    -- Se permite Controle de Edição do Pedido
    IF (vvtipomovccrca = 'LL') THEN

      -- Laço de Itens - Antes e Depois
      FOR vc_Itens IN (SELECT CODPROD
                            , NUMSEQ
                            , COUNT(*)  QTREG
                            , MIN(TIPO) TIPO
                         FROM
                         (
                         SELECT 'A' TIPO
                              , CODPROD
                              , NUMSEQ
                           FROM PCMED_EDICAOPEDIDO
                          WHERE (NUMPED = p_numped)
                         UNION
                         SELECT 'D' TIPO
                              , CODPROD
                              , NUMSEQ
                           FROM PCPEDI
                          WHERE (NUMPED = p_numped)
                         ) TAB
                         GROUP BY CODPROD
                                , NUMSEQ) LOOP

        -- Se somente existia Antes - EXCLUSÃO DE ITEM
        IF    (vc_Itens.QTREG = 1)   AND
              (vc_Itens.TIPO  = 'A') THEN
          -- Pesquisa valor anterior
          SELECT VLLIMCREDRCAUTILIZ
            INTO vnValorSaldoAnterior
            FROM PCMED_EDICAOPEDIDO
           WHERE (NUMPED  = p_numped)
             AND (CODPROD = vc_Itens.CODPROD)
             AND (NUMSEQ  = vc_Itens.NUMSEQ);
          -- Estorna Valor tendo em vista que o Item não está mais na PCPEDI
          ccrca_estorna_item_pedidomed(p_codfunclanc,
                                       p_rotinalanc,
                                       vncodusur,
                                       p_numped,
                                       vc_Itens.CODPROD,
                                       vc_Itens.NUMSEQ,
                                       vnValorSaldoAnterior);
        -- Se somente existe Depois - INCLUSÃO DE ITEM
        ELSIF (vc_Itens.QTREG = 1)   AND
              (vc_Itens.TIPO  = 'D') THEN
          -- Insere item
          vbvalido := ccrca_incluir_item_pedido(p_codfunclanc,
                                                p_rotinalanc,
                                                vncodusur,
                                                p_numped,
                                                vc_Itens.CODPROD,
                                                vc_Itens.NUMSEQ);
        -- Se manteve o Produto
        ELSIF (vc_Itens.QTREG = 2) THEN
          -- Pesquisa Preço Anterior
          SELECT QT
               , PBASERCA
               , PVENDA
               , VLLIMCREDRCAUTILIZ
            INTO vnQtAnterior
               , vnPBaseAnterior
               , vnPVendaAnterior
               , vnValorSaldoAnterior
            FROM PCMED_EDICAOPEDIDO
           WHERE (NUMPED  = p_numped)
             AND (CODPROD = vc_Itens.CODPROD)
             AND (NUMSEQ  = vc_Itens.NUMSEQ);
          -- Pesquisa Preço Atual
          SELECT QT
               , PBASERCA
               , PVENDA
            INTO vnNovaQt
               , vnNovoPBase
               , vnNovoPVenda
            FROM PCPEDI
           WHERE (NUMPED  = p_numped)
             AND (CODPROD = vc_Itens.CODPROD)
             AND (NUMSEQ  = vc_Itens.NUMSEQ);
          -- Se houve mudança de Preço ou Qtde
          --IF (NVL(vnQtAnterior,0)     <> NVL(vnNovaQt,0))     OR
          --   (NVL(vnPBaseAnterior,0)  <> NVL(vnNovoPBase,0))  OR
          --   (NVL(vnPVendaAnterior,0) <> NVL(vnNovoPVenda,0)) THEN
            -- Estorna Valor tendo em vista que o Item não está mais igual estava PCPEDI
            ccrca_estorna_item_pedidomed(p_codfunclanc,
                                         p_rotinalanc,
                                         vncodusur,
                                         p_numped,
                                         vc_Itens.CODPROD,
                                         vc_Itens.NUMSEQ,
                                         vnValorSaldoAnterior);
            -- Insere item
            vbvalido := ccrca_incluir_item_pedido(p_codfunclanc,
                                                  p_rotinalanc,
                                                  vncodusur,
                                                  p_numped,
                                                  vc_Itens.CODPROD,
                                                  vc_Itens.NUMSEQ);
          --END IF;
        END IF;
      END LOOP;

    END IF; -- Fim Condição Se permite Controle de Edição do Pedido

  END ccrca_fim_edicao_pedido;

  -- INICIO: MED-2073 ----------
  FUNCTION ccger_checar_saldo_atual(p_codgerente IN pcgerente.codgerente%TYPE)
    RETURN NUMBER IS
    vnvlcorrente pcgerente.vlcorrente%TYPE;
  BEGIN
    BEGIN
      SELECT NVL(pcgerente.vlcorrente, 0)
        INTO vnvlcorrente
        FROM pcgerente
       WHERE codgerente = p_codgerente;
    EXCEPTION
      WHEN OTHERS THEN
        vnvlcorrente := 0;
    END;

    RETURN vnvlcorrente;
  END; --ccger_checar_saldo_atual

  FUNCTION ccsup_checar_saldo_atual(p_codsupervisor IN pcsuperv.codsupervisor%TYPE)
    RETURN NUMBER IS
    vnvlcorrente pcsuperv.vlcorrente%TYPE;
  BEGIN
    BEGIN
      SELECT NVL(pcsuperv.vlcorrente, 0)
        INTO vnvlcorrente
        FROM pcsuperv
       WHERE codsupervisor = p_codsupervisor;
    EXCEPTION
      WHEN OTHERS THEN
        vnvlcorrente := 0;
    END;

    RETURN vnvlcorrente;
  END; --ccsup_checar_saldo_atual

  FUNCTION ccger_checar_limite_credito(p_codgerente pcgerente.codgerente%TYPE)
    RETURN NUMBER IS
    vnvllimcred pcgerente.vllimcred%TYPE;
  BEGIN
   begin
    SELECT NVL(pcgerente.vllimcred, 0)
      INTO vnvllimcred
      FROM pcgerente
     WHERE codgerente = p_codgerente;
    EXCEPTION
      WHEN OTHERS THEN
        vnvllimcred := 0;
    END;

    RETURN(vnvllimcred);
  END; --ccger_checar_limite_credito

  FUNCTION ccsup_checar_limite_credito(p_codsupervisor pcsuperv.codsupervisor%TYPE)
    RETURN NUMBER IS
    vnvllimcred pcsuperv.vllimcred%TYPE;
  BEGIN
    BEGIN
      SELECT NVL(pcsuperv.vllimcred, 0)
        INTO vnvllimcred
        FROM pcsuperv
       WHERE codsupervisor = p_codsupervisor;
    EXCEPTION
      WHEN OTHERS THEN
        vnvllimcred := 0;
    END;

    RETURN(vnvllimcred);
  END; --ccsup_checar_limite_credito

  FUNCTION ccger_checar_disponivel_atual(p_codgerente IN pcgerente.codgerente%TYPE)
    RETURN NUMBER IS
    vnvldisponivel NUMBER;
  BEGIN
    vnvldisponivel := 0;
    vnvldisponivel := NVL(ccger_checar_limite_credito(p_codgerente), 0) +
                      NVL(ccger_checar_saldo_atual(p_codgerente), 0);
    RETURN vnvldisponivel;
  END; -- ccger_checar_disponivel_atual

  FUNCTION ccsup_checar_disponivel_atual(p_codsupervisor IN pcsuperv.codsupervisor%TYPE)
    RETURN NUMBER IS
    vnvldisponivel NUMBER;
  BEGIN
    vnvldisponivel := 0;
    vnvldisponivel := NVL(ccsup_checar_limite_credito(p_codsupervisor), 0) +
                      NVL(ccsup_checar_saldo_atual(p_codsupervisor), 0);
    RETURN vnvldisponivel;
  END; -- ccsup_checar_disponivel_atual
  -- FIM: MED-2073 ----------

  -- Para Compatibilidade com a Integradora Pacote
  PROCEDURE ccrca_bloquear_registro_rca(p_codusur IN PCUSUARI.CODUSUR%TYPE) IS
  BEGIN
    NULL;
  END;

END; --PC_PKG_CONTROLARSALDORCA