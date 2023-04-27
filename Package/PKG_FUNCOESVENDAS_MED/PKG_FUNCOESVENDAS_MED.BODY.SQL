CREATE OR REPLACE PACKAGE BODY PKG_FUNCOESVENDAS_MED
/************************************************************************************************
  Package de Processos Específicos de Promoção Módulo de Medicamentos
  ----------------     Historico     ------------------------------------------------------------
  Data        Responsável        Tarefa          Comentario
  06/11/2019  Anderson Silva     DDMEDICA-1147   Primeira Versão
  04/12/2019  Anderson Silva     DDMEDICA-1495   Promoção por Lote
  10/01/2019  Anderson Silva     DDMEDICA-1769   Faltas e Avarias Integração WMS - Crossdocking
  22/01/20109 Anderson Silva     DDMEDICA-1888   Importação TV10
  24/01/2020  Anderson Silva     DDMEDICA-1953   Crossdocking
  24/01/2020  Anderson Silva     DDMEDICA-1969   Troca de Nota
  21/09/2020  Anderson Silva     DDMEDICA-4084   Tratamento para não ler Entradas OE
  02/10/2020  Anderson Silva     DDMEDICA-4244   Opção para somar ST do FECP na função para Obter ST Fonte 
  14/10/2020  Anderson Silva     DDMEDICA-4381   Correção Condição ST Avaria/Perda
  07/12/2020  Anderson Silva     DDMEDICA-4993   Merge ST PMPF
  08/03/2021  Anderson Silva     DDMEDICA-5841   Filtrar os Lotes pela Filial do Pedido em Pedido de Avaria
  30/09/2021  Anderson Silva     DDMEDICA-7697   ST Recolhido anteriormente
  15/02/2022  Anderson Silva     DDVENDAS-33636  Depósito por Filial
  25/04/2022  Anderson Silva     DDVENDAS-35125  Melhoria Referências Externas
  04/05/2022  Anderson Silva     DDVENDAS-35253  Limitar ST FECP a Clientes com ST Fonte
  23/05/2022  Anderson Silva     DDVENDAS-35576 - Flexibilização da Regra de Alterar Preço/Desconto 
  26/05/2022  Anderson Silva     DDVENDAS-35697 - Exceções da ABCFARMA/CMED
  31/05/2022  Anderson Silva     DDVENDAS-35778 - Parâmetro para Restrição de Venda conforme Regra de Alterar Preço/Desconto 
  28/09/2022  Anderson Silva     DDVENDAS-38075 - PMC não entra nas Exceções CMED
  30/01/2023  Anderson Silva     DDVENDAS-40111 - Consolidação do uso das cotas da promoção  
  28/02/2023  Anderson Silva     DDVENDAS-40446 - Performance cálculo Função PIS_COFINS_ICMS
  27/04/2023  Anderson Silva     DDVENDAS-41753 - Inclusão de prioriadade de exceção do Convênio Isenção ICMS
 ************************************************************************************************/
IS

 /*****************************************
  Controle de Versionamento
  -----------------------------------------
  Issue                 Versão
  DDVENDAS-35125        v@31.1.1
  DDVENDAS-35253        v@31.1.2
  DDVENDAS-35576        v@31.1.3
  DDVENDAS-35697        v@31.1.4
  DDVENDAS-35778        v@31.1.5
  DDVENDAS-38075        v@31.1.6
  DDVENDAS-40111        v@31.1.7
  DDVENDAS-40446        v@33.0.1
  DDVENDAS-41753        v@33.0.2
  *****************************************/
  FUNCTION F_OBTER_VERSIONAMENTO RETURN VARCHAR2 IS
    vvVersao VARCHAR2(10);
  BEGIN
  
    -->> *** A CADA ALTERAÇÃO INCREMENTAR AQUI A VERSÃO ***
    vvVersao := 'v@33.0.2';
  
    RETURN 'MED_' || vvVersao;
    
  END F_OBTER_VERSIONAMENTO;

 /*******************************************************************************
  Nome         : F_FORMATAR_NUMERO_PARA_TEXTO
  Descricão    : Função para Formatar um Número para Texto
  ********************************************************************************/   
  FUNCTION F_FORMATAR_NUMERO_PARA_TEXTO(pi_nNumero            IN NUMBER,
                                        pi_iQtdeCasasDecimais IN INTEGER) RETURN VARCHAR2 IS                                           
    vvTextoRetorno  VARCHAR2(200);
    vvMascara       VARCHAR2(200);
  BEGIN
  
    vvMascara :=  NULL;
    
    -- Monta a parte da Mascara com Casas Decimais
    IF (pi_iQtdeCasasDecimais > 0) THEN
      FOR viIdx IN 1..pi_iQtdeCasasDecimais LOOP
        IF (vvMascara = NULL) THEN
          vvMascara := '0';
        ELSE
          vvMascara := vvMascara || '0';
        END IF;
      END LOOP;
      vvMascara := '0.' || vvMascara;
    -- Monta a parte da Mascara sem Casas Decimais
    ELSE
      vvMascara := '0';
    END IF;
    
    -- Finaliza a Mascara da Parte Inteira
    vvMascara := '999,999,999,999,999,999,999,999,999,999,999,99' || vvMascara;

    -- Prepara Texto Retorno
    vvTextoRetorno := TO_CHAR(pi_nNumero,vvMascara);
    
    -- Troca Ponto por um caracter auxiliar
    vvTextoRetorno := REPLACE(vvTextoRetorno,'.','@');
    
    -- Troca Virgulas por ponto
    vvTextoRetorno := REPLACE(vvTextoRetorno,',','.');

    -- Troca caracter auxiliar por virgula
    vvTextoRetorno := REPLACE(vvTextoRetorno,'@',',');
    
    -- Elimina espaços em branco
    vvTextoRetorno := TRIM(vvTextoRetorno);
    
    -- Retorno
    RETURN vvTextoRetorno;
 
  END F_FORMATAR_NUMERO_PARA_TEXTO;                                                                              

 /***********************************************************************************************
  FUNÇÃO...: FFORMATAR_NUMERO_TEXTO_SQL
  DESCRIÇÃO: Função para Formatar um Número para Texto SQL (manter o ponto como separado de casas)
  ***********************************************************************************************/
  FUNCTION FFORMATAR_NUMERO_TEXTO_SQL(pi_nNumero IN NUMBER) RETURN VARCHAR2 IS
    vvTextoRetorno  VARCHAR2(200);
  BEGIN

    -- Prepara Texto Retorno
    vvTextoRetorno := TO_CHAR(pi_nNumero);

    -- Troca Virgulas por ponto
    vvTextoRetorno := REPLACE(vvTextoRetorno,',','.');

    -- Elimina espaços em branco
    vvTextoRetorno := TRIM(vvTextoRetorno);

    -- Retorno
    RETURN vvTextoRetorno;

  END FFORMATAR_NUMERO_TEXTO_SQL;

  ------------------------------------------------------------------------------
  -- Procedimento para Obter o Parâmetro da Filial STRING
  ------------------------------------------------------------------------------
  PROCEDURE POBTEM_PARAMFILIAL_STRING(pi_vCodFilial   IN VARCHAR2,
                                      pi_vNomeCampo   IN VARCHAR2,
                                      pi_vValorPadrao IN VARCHAR2,
                                      po_vValor     OUT VARCHAR2) IS
  BEGIN

    -- Inicializa Retorno
    po_vValor := NULL;

    -- Pesquisa Parametro
    BEGIN
      SELECT PCPARAMFILIAL.VALOR
        INTO po_vValor
        FROM PCPARAMFILIAL
       WHERE (PCPARAMFILIAL.CODFILIAL = pi_vCodFilial)
         AND (PCPARAMFILIAL.NOME      = pi_vNomeCampo);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        po_vValor := NULL;
    END;
    
    -- Valor Padrão se NULO
    po_vValor := NVL(po_vValor,pi_vValorPadrao);

  END POBTEM_PARAMFILIAL_STRING;

  ------------------------------------------------------------------------------
  -- Procedimento para Obter o Parâmetro da Filial NUMBER
  ------------------------------------------------------------------------------
  PROCEDURE POBTEM_PARAMFILIAL_NUMBER(pi_vCodFilial IN  VARCHAR2,
                                      pi_vNomeCampo IN  VARCHAR2,
                                      po_nValor     OUT NUMBER) IS

    vvValorString PCPARAMFILIAL.VALOR%TYPE;

  BEGIN
  
    -- Inicializa Retorno
    po_nValor   := 0;

    -- Pesquisa Parametro
    BEGIN
      SELECT PCPARAMFILIAL.VALOR
        INTO vvValorString
        FROM PCPARAMFILIAL
       WHERE (PCPARAMFILIAL.CODFILIAL = pi_vCodFilial)
         AND (PCPARAMFILIAL.NOME      = pi_vNomeCampo);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvValorString := NULL;
    END;


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
        po_nValor := 0;
    END;

  END POBTEM_PARAMFILIAL_NUMBER;

  ------------------------------------------------------------------------------
  -- Funcao para Verificar se Usa Regra Especifica de Medicamentos --
  -------------------------------------------------------------------
  FUNCTION FUSA_REGRA_MEDICAMENTOS(pi_vCodFilial IN VARCHAR2,
                                   pi_vNome      IN VARCHAR2)
  RETURN VARCHAR2 IS
    vvRetUsaRegraMedicamentos VARCHAR2(1);
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

 /*******************************************************************************
   Nome         : F_OBTER_DEPOSITO_WMS_DEVCLI
   Descricão    : Obter Depósito Padrão do Motivo de Devolução do Cliente
  *******************************************************************************/
  FUNCTION F_OBTER_DEPOSITO_WMS_DEVCLI(pi_nCodFilialPedido IN VARCHAR2,
                                       pi_nCodDevol        IN NUMBER) 
  RETURN NUMBER IS
    vnRetCodigoDepositoWms NUMBER;
    vvSqlSemFilial VARCHAR2(4000);
    vvSqlComFilial VARCHAR2(4000);                                  
  BEGIN
  
    vvSqlComFilial := 'SELECT D.CODIGODEPOSITOWMSMED 
                         FROM PCINT_RELACIONA_DEPOSITO_MOTIV D
                            , PCFILIAL F
                        WHERE (D.CODDEVOL = ' || NVL(pi_nCodDevol,0) || ')
                          AND (F.CODIGO = ' || '''' || pi_nCodFilialPedido || '''' || ')
                          AND (F.CODFILIALWMSDELAGE = D.CODFILIAL) 
                          AND (ROWNUM = 1)';

    vvSqlSemFilial := 'SELECT CODIGODEPOSITOWMSMED 
                         FROM PCTABDEV 
                        WHERE (CODDEVOL = ' || NVL(pi_nCodDevol,0) || ')
                          AND (ROWNUM = 1)';  
  
    -- Inicializa Retorno
    vnRetCodigoDepositoWms := NULL;
    
    -- Se tem Motivo de Dev. Cliente
    IF (NVL(pi_nCodDevol,0) > 0) THEN

      -- Pesquisa Valores
      BEGIN
        --  Primeiro procura por Filial
        EXECUTE IMMEDIATE vvSqlComFilial
                     INTO vnRetCodigoDepositoWms;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          BEGIN
            -- Se não achar procura sem Filial
            EXECUTE IMMEDIATE vvSqlSemFilial
                         INTO vnRetCodigoDepositoWms;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              NULL;
            WHEN  OTHERS THEN 
              NULL;
          END;
        WHEN OTHERS THEN
          BEGIN
            -- Se não achar procura sem Filial
            EXECUTE IMMEDIATE vvSqlSemFilial
                         INTO vnRetCodigoDepositoWms;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              NULL;
            WHEN  OTHERS THEN 
              NULL;
          END;
      END;              
      
    END IF;
    
    -- Retorna o Depósito Padrão
    RETURN vnRetCodigoDepositoWms;
    
  END F_OBTER_DEPOSITO_WMS_DEVCLI;                                         

 /*******************************************************************************
   Nome         : P_OBTER_DEPOSITO_WMS - DDVENDAS-33636
   Descricão    : Obter Depósito Padrão conforme campo passado por parâmetro
  *******************************************************************************/
  PROCEDURE P_OBTER_DEPOSITO_WMS(pi_nCodFilialPedido       IN VARCHAR2,
                                 pi_vCampo                 IN VARCHAR2,
                                 po_nCodigoDepositoWms    OUT NUMBER,
                                 po_vDescricaoDepositoWms OUT VARCHAR2) IS
    vvSqlSemFilial VARCHAR2(4000);
    vvSqlComFilial VARCHAR2(4000);                                  
  BEGIN
  
    vvSqlComFilial := 'SELECT R.CODIGODEPOSITOWMS
                            , SUBSTR(R.DESCRICAODEPOSITOWMS,1,40)
                         FROM PCINT_RELACIONA_DEPOSITO_ESTOQ R
                            , PCFILIAL F
                        WHERE (R.' || pi_vCampo || ' = ''S'')
                          AND (F.CODIGO = ' || '''' || pi_nCodFilialPedido || '''' || ')
                          AND (F.CODFILIALWMSDELAGE = R.CODFILIAL) 
                          AND (ROWNUM = 1)';

    vvSqlSemFilial := 'SELECT R.CODIGODEPOSITOWMS
                            , SUBSTR(R.DESCRICAODEPOSITOWMS,1,40)
                         FROM PCINT_RELACIONA_DEPOSITO_ESTOQ R
                        WHERE (R.' || pi_vCampo || ' = ''S'')
                          AND (ROWNUM = 1)';

    -- Pesquisa Valores
    BEGIN
      -- Primeiro procura por Filial
      EXECUTE IMMEDIATE vvSqlComFilial
                   INTO po_nCodigoDepositoWms
                      , po_vDescricaoDepositoWms;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        BEGIN
          -- Se não achar procura sem Filial
          EXECUTE IMMEDIATE vvSqlSemFilial
                       INTO po_nCodigoDepositoWms
                          , po_vDescricaoDepositoWms;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
          WHEN OTHERS THEN
            NULL;
        END;        
      WHEN OTHERS THEN
        BEGIN
          -- Se não achar procura sem Filial
          EXECUTE IMMEDIATE vvSqlSemFilial
                       INTO po_nCodigoDepositoWms
                          , po_vDescricaoDepositoWms;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
          WHEN OTHERS THEN
            NULL;
        END;        
    END;
                      
  END P_OBTER_DEPOSITO_WMS;                                         

 /*******************************************************************************
   Nome         : P_OBTER_DADOS_DEPOSITO_WMS - DDVENDAS-33636
   Descricão    : Obter Dados Depósito WMS conforme código passado por parâmetro
  *******************************************************************************/
  PROCEDURE P_OBTER_DADOS_DEPOSITO_WMS(pi_nCodFilialPedido        IN VARCHAR2,
                                       pi_nCodDepositoWms         IN NUMBER,
                                       pio_nCodigoDepositoWms    OUT NUMBER,
                                       pio_vDescricaoDepositoWms OUT VARCHAR2) IS
    vvSqlSemFilial VARCHAR2(4000);
    vvSqlComFilial VARCHAR2(4000);                                  
  BEGIN
  
    vvSqlComFilial := 'SELECT R.CODIGODEPOSITOWMS
                            , SUBSTR(R.DESCRICAODEPOSITOWMS,1,40)
                         FROM PCINT_RELACIONA_DEPOSITO_ESTOQ R
                            , PCFILIAL F
                        WHERE (R.CODIGODEPOSITOWMS = ' || NVL(pi_nCodDepositoWms,0) || ')
                          AND (F.CODIGO = ' || '''' || pi_nCodFilialPedido || '''' || ')
                          AND (F.CODFILIALWMSDELAGE = R.CODFILIAL) 
                          AND (ROWNUM = 1)';

    vvSqlSemFilial := 'SELECT R.CODIGODEPOSITOWMS
                            , SUBSTR(R.DESCRICAODEPOSITOWMS,1,40)
                         FROM PCINT_RELACIONA_DEPOSITO_ESTOQ R
                        WHERE (R.CODIGODEPOSITOWMS = ' || NVL(pi_nCodDepositoWms,0) || ')
                          AND (ROWNUM = 1)';

    -- Pesquisa Valores
    BEGIN
      -- Primeiro procura por Filial
      EXECUTE IMMEDIATE vvSqlComFilial
                   INTO pio_nCodigoDepositoWms
                      , pio_vDescricaoDepositoWms;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        BEGIN
          -- Se não achar procura sem Filial
          EXECUTE IMMEDIATE vvSqlSemFilial
                       INTO pio_nCodigoDepositoWms
                          , pio_vDescricaoDepositoWms;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
          WHEN OTHERS THEN
            NULL;
        END;        
      WHEN OTHERS THEN
        BEGIN
          -- Se não achar procura sem Filial
          EXECUTE IMMEDIATE vvSqlSemFilial
                       INTO pio_nCodigoDepositoWms
                          , pio_vDescricaoDepositoWms;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
          WHEN OTHERS THEN
            NULL;
        END;        
    END;
                      
  END P_OBTER_DADOS_DEPOSITO_WMS;                                                                                 
  
 /*******************************************************************************
  Nome         : F_OBTER_LOTES_PEDIDO
  Descricão    : Função para retornar Tabela com os Lotes para Seleção no Pedido
  Parâmetros   : pi_vTipoPedido     - Tipo de Pedido
                                      'PC' - Pedido de Crossdocking
                                      'PA' - Pedido de Avaria
                                      'PL' - Promoção por Lote
                                      'PT' - Pedido de Transferência
                                      'PN' - Pedido de Troca de Nota
                 pi_nOrigemChamada  - Origem da Chamada
                                      1 - Carregar todos os produtos da entrada para seleção
                                      2 - Validar Saldo ao confirmar o produto e o lote
                                      3 - Exibir os Lotes para Seleção
                                      4 - Carregar todos ops produtos do pedido com venda
                 pi_nOrigemChamada  - Origem da Chamada
                 pi_nNumTransEnt    - Número da Transação de Entrada
                 pi_nNumPed         - Número do Pedido Atual
                 pi_nCodProd        - Código do Produto Atual
                 pi_nNumSeq         - Sequência do Item do Produto Atual
                 pi_vNumLote        - Lote do Produto Atual
                 pi_nCodPromocaoMed -
  Alteracão    : Anderson Silva - 26/08/2019 - Criação da Função - DDMEDICA-641
  Alteração    : Anderson Silva - 03/12/2019 - Promoção por Lote - DDMEDICA-1495
  ********************************************************************************/                                       
  FUNCTION F_OBTER_LOTES_PEDIDO(pi_vTipoPedido     IN VARCHAR2,
                                pi_nOrigemChamada  IN NUMBER,
                                pi_nNumTransEnt    IN NUMBER,
                                pi_nNumPed         IN NUMBER   DEFAULT NULL,
                                pi_nCodProd        IN NUMBER   DEFAULT NULL,
                                pi_nNumSeq         IN NUMBER   DEFAULT NULL,
                                pi_vNumLote        IN VARCHAR2 DEFAULT NULL,
                                pi_vCodFilial      IN VARCHAR2 DEFAULT NULL,
                                pi_nCodPromocaoMed IN NUMBER   DEFAULT NULL)
  RETURN TABELA_MED_OBTER_LOTES_PEDIDO PARALLEL_ENABLE PIPELINED IS
  
    -- Dados da Entrada 
    vdDtEnt                        DATE;
    vvCodFilial                    PCFILIAL.CODIGO%TYPE;
    vnNumBonus                     NUMBER;
    vnCodDevol                     NUMBER;
    dDATAFECHACOMPLETA             DATE;
  
    -- Parâmetro
    vFIL_USAINTEGRACAOWMS          PCPARAMFILIAL.VALOR%TYPE;
    vFIL_INTEGRADORAWMS            PCPARAMFILIAL.VALOR%TYPE;
       
    -- Dados Produto
    vvEstoquePorLote               PCPRODUT.ESTOQUEPORLOTE%TYPE;
    
    -- Observação 
    vvRestricao                    VARCHAR2(1);
    vvObs                          VARCHAR2(50);
    vdDtValidade                   DATE;
    
    -- Produto em Promoção
    vvProdutoEmPromocao            VARCHAR2(1);
      
    -- Array de Valores
    TYPE TRecValores               IS RECORD( 
         nCODIGODEPOSITOWMS        NUMBER,
         vDESCRICAODEPOSITOWMS     VARCHAR2(200),
         nID                       NUMBER,
         nCODPROD                  PCPEDI.CODPROD%TYPE,
         vNUMLOTE                  PCPEDI.NUMLOTE%TYPE,
         dDTVALIDADE               PCLOTE.DTVALIDADE%TYPE,
         vDESCRICAO                PCPRODUT.DESCRICAO%TYPE,
         nQT                       PCPEDI.QT%TYPE,
         nCUSTOFIN                 PCPEDI.CUSTOFINEST%TYPE,
         vRESTRICAO                VARCHAR2(1),
         vOBS                      VARCHAR2(50));
    TYPE TTvValores                IS TABLE OF TRecValores INDEX BY BINARY_INTEGER;
    vtVendaGeral                   TTvValores;
    vtVendaPedido                  TTvValores;
    vtEntrada                      TTvValores;
    vtConferencia                  TTvValores;
    
    -- Record
    vrDadosEntrada                TRecValores;       
    vrDadosConferencia            TRecValores;       
  
    -- Contador Conferência
    viContaCONF                   INTEGER;
    
    -- Contador ID
    viContaID                     INTEGER;
    
    -- Verificar se aceita o produto
    vbAceitaPrduto                BOOLEAN;
  
    -- Qtde. Vendas
    vnQtVendaGeral                NUMBER;
    vnQtVendaPedido               NUMBER;
  
    -- Qtde Saldo
    vnQtSaldo                     NUMBER;
    
    -- Qtde Estorno
    vnQtEstorno                   NUMBER;
    
    -- Qtde Conferida
    viContaLotesConf              INTEGER;
    vnQtdeConferida               NUMBER;
  
    -- Controle de Aceite da Conferência
    vbAceiteConferencia           BOOLEAN;
    
    -- Integração de Lotes
    vvUsaLoteIntegracao           VARCHAR2(1);
    
    -- Depósito Padrão Avaria e Crossdocking e Transferência e Troca de Nota
    vnDepositoPadraoAvaria        NUMBER; 
    vvDescDepositoPadraoAvaria    VARCHAR2(200);
    vnDepositoPadraoCrossdock     NUMBER; 
    vvDescDepositoPadraoCrossdock VARCHAR2(200);
    vnDepositoPadraoTV10          NUMBER; 
    vvDescDepositoPadraoTV10      VARCHAR2(200);
    vnDepositoPadraoTrocaNota     NUMBER; 
    vvDescDepositoPadraoTrocaNota VARCHAR2(200);
    -- Depósito Padrão Dev. Cliente
    vnDepositoPadraoDevCli        NUMBER; 
    
    -- Falta/Avaria - DDMEDICA-1769
    vnQtFaltaAvaria               NUMBER;
    vnQtCrossDocking              NUMBER;
    
    -- Custo Financeiro TV10
    vnCustoFinTV10                NUMBER;
    vnQtTV10                      NUMBER;
    vnQtTrocaNota                 NUMBER;
    vnQtAvaria                    NUMBER;
          
    -- Tipo Objeto
    OUTROW TIPO_MED_OBTER_LOTES_PEDIDO := TIPO_MED_OBTER_LOTES_PEDIDO(NULL,  -- NUMTRANSENT
                                                                      NULL,  -- IDMOVIMENTACAO
                                                                      NULL,  -- CODPROD
                                                                      NULL,  -- NUMLOTE
                                                                      NULL,  -- DESCRICAO
                                                                      NULL,  -- CUSTOFIN
                                                                      NULL,  -- QTDEENTRADA
                                                                      NULL,  -- QTDESAIDA
                                                                      NULL,  -- QTDEPEDIDO
                                                                      NULL,  -- SALDO
                                                                      NULL,  -- RESTRICAO
                                                                      NULL,  -- OBS
                                                                      NULL,  -- DTVALIDADE
                                                                      NULL,  -- CODIGODEPOSITOWMS
                                                                      NULL); -- DESCRICAODEPOSITOWMS
      
    -------------------------------------------------------------------------------------------------                                                
    -- Procedimento para Somar Valores ao Array
    -------------------------------------------------------------------------------------------------                                                
    PROCEDURE P_SOMA_VALORES(pio_Array   IN OUT TTvValores,
                             pi_nCodProd IN NUMBER,
                             pi_vNumLote IN VARCHAR2,
                             pi_nQt      IN NUMBER)
    IS
      -- Posição no Array
      viPos          INTEGER;
    BEGIN
    
      -- Verifica se já inseriu o Produto  + Lote na Venda Geral
      viPos := 0;
      IF (pio_Array.COUNT > 0) THEN
        FOR viIdx IN pio_Array.FIRST..pio_Array.LAST LOOP    
          IF (pio_Array(viIdx).nCODPROD          = pi_nCodProd)          AND
             (NVL(pio_Array(viIdx).vNUMLOTE,' ') = NVL(pi_vNumLote,' ')) THEN
            viPos := viIdx;
          END IF;
        END LOOP;    
      END IF;
        
      -- Se ainda não inseriu gera posição
      IF (viPos = 0) THEN    
        viPos := NVL(pio_Array.COUNT,0) + 1;
        pio_Array(viPos).nCODPROD := pi_nCodProd;
        pio_Array(viPos).vNUMLOTE := pi_vNumLote;
        pio_Array(viPos).nQT      := 0;      
      END IF;
               
      -- Acumula Venda Geral
      pio_Array(viPos).nQT := NVL(pio_Array(viPos).nQT,0) + NVL(pi_nQt,0);                       
    
    END P_SOMA_VALORES;                           
  
    -------------------------------------------------------------------------------------------------                                                
    -- Função para Retornar a Venda do Produto e Lote
    -------------------------------------------------------------------------------------------------                                                
    FUNCTION F_RETORNA_VENDA(pio_Array   IN OUT TTvValores,
                             pi_nCodProd IN NUMBER,
                             pi_vNumLote IN VARCHAR2)
    RETURN NUMBER IS
      -- Retorno
      vnRetQtdeVenda NUMBER;
    BEGIN
    
      -- Inicializa Retorno
      vnRetQtdeVenda := 0;
    
      -- Pesquisa Produto e Lote no Arrray
      IF (pio_Array.COUNT > 0) THEN
        FOR viIdx IN pio_Array.FIRST..pio_Array.LAST LOOP    
          IF (pio_Array(viIdx).nCODPROD          = pi_nCodProd)          AND
             (NVL(pio_Array(viIdx).vNUMLOTE,' ') = NVL(pi_vNumLote,' ')) THEN
            vnRetQtdeVenda := NVL(pio_Array(viIdx).nQT,0);
          END IF;
        END LOOP;    
      END IF;
        
      -- Retorno
      RETURN vnRetQtdeVenda;
    
    END F_RETORNA_VENDA;                           
  
   /***********************
    INICIO DO PROCESSAMENTO                                                                                                    
    ***********************/
  BEGIN
  
    -- Pesquisa a Data da Entrada - Pedido de CrossDocking e Transferência e Troca de Nota
    IF (NVL(pi_vTipoPedido,'PC') IN ('PC','PT','PTB','PN')) THEN
      BEGIN
        SELECT PCNFENT.DTENT
             , PCNFENT.CODFILIAL
             , PCNFENT.NUMBONUS
             , PCNFENT.CODDEVOL
          INTO vdDtEnt
             , vvCodFilial
             , vnNumBonus
             , vnCodDevol
          FROM PCNFENT
         WHERE (NUMTRANSENT = pi_nNumTransEnt)
           AND (ESPECIE    <> 'OE'); -- DDMEDICA-4084
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vdDtEnt     := NULL;
          vvCodFilial := pi_vCodFilial; -->> Se não achar usa Filial do Parâmetro
          vnNumBonus  := NULL;
          vnCodDevol  := NULL;
      END;
    ELSE
      vdDtEnt     := NULL;
      vvCodFilial := pi_vCodFilial; -->> Usa Filial do Parâmetro
      vnNumBonus  := NULL;
      vnCodDevol  := NULL;
    END IF;
    
    -- Pesquisa Parâmetro
    BEGIN
      SELECT VALOR
        INTO vFIL_USAINTEGRACAOWMS
        FROM PCPARAMFILIAL
       WHERE (NOME = 'FIL_USAINTEGRACAOWMS')
         AND (CODFILIAL = vvCodFilial);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vFIL_USAINTEGRACAOWMS := 'N';
    END;
    
    BEGIN
      SELECT VALOR
        INTO vFIL_INTEGRADORAWMS
        FROM PCPARAMFILIAL
       WHERE (NOME = 'FIL_INTEGRADORAWMS')
         AND (CODFILIAL = vvCodFilial);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vFIL_INTEGRADORAWMS := NULL;
    END;    
   
   /******************************************************************************  
    Define Origem dos Dados
    ***********************/
  
    ------------------------------------------------------------------------------
    ------------------------------------------------------------------------------
    -->> Pedido de Crossdocking  
    ------------------------------------------------------------------------------
    ------------------------------------------------------------------------------
    IF    (pi_vTipoPedido = 'PC') THEN

      -- Inicializa o Contador de ID
      viContaID := 0;
        
      -- Laço de Movimentações
      FOR vc_Movimentacao IN (SELECT PCMOV.CODPROD
                                   , PCMOV.NUMLOTE
                                   , SUM(PCMOV.QTCONT) QTCONT
                                   , MAX(PCMOVCOMPLE.CUSTOULTENTCONT) CUSTOULTENTCONT
                                FROM PCMOV
                                   , PCMOVCOMPLE 
                               WHERE (PCMOV.NUMTRANSENT  = pi_nNumTransEnt)
                                 AND (PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM)
                               GROUP BY PCMOV.CODPROD
                                      , PCMOV.NUMLOTE
                               ORDER BY PCMOV.CODPROD,
                                        PCMOV.NUMLOTE) LOOP
  
        ----------------------------
        -- Pesquisa Dados do Produto
        ----------------------------
        BEGIN
          SELECT ESTOQUEPORLOTE
            INTO vvEstoquePorLote
            FROM PCPRODUT
           WHERE (CODPROD = vc_Movimentacao.CODPROD); 
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvEstoquePorLote := 'N';
        END;
                                        
        -------------------------------
        -- Verifica se aceita o Produto
        -------------------------------
        vbAceitaPrduto := FALSE;
        -- Se carrega todos os produtos da entrada/pedido
        IF    (pi_nOrigemChamada IN (1,4)) THEN
          vbAceitaPrduto := TRUE;
        -- Se Valida Saldo do Produto e Lote
        ELSIF (pi_nOrigemChamada = 2) THEN
          IF (vc_Movimentacao.CODPROD          = pi_nCodProd)          AND
             (NVL(vc_Movimentacao.NUMLOTE,' ') = NVL(pi_vNumLote,' ')) THEN
            vbAceitaPrduto := TRUE;
          END IF;
        -- Se Exibir Lotes para Seleção
        ELSIF (pi_nOrigemChamada = 3) THEN
          IF (vc_Movimentacao.CODPROD = pi_nCodProd) THEN
            vbAceitaPrduto := TRUE;
          END IF;
        END IF;                                      
        
        --------------
        -- Observações
        --------------
        vvRestricao  := NULL;
        vvObs        := NULL;
        vdDtValidade := NULL;
        -- Verifica se tem o Lote na PCLOTE
        IF (vvEstoquePorLote = 'S') THEN
          BEGIN
            SELECT NULL
                 , DTVALIDADE
              INTO vvObs
                 , vdDtValidade
              FROM PCLOTE
             WHERE (CODFILIAL = vvCodFilial)
               AND (CODPROD   = vc_Movimentacao.CODPROD)
               AND (NUMLOTE   = vc_Movimentacao.NUMLOTE);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vvObs        := 'Sem Estoque por Lote (PCLOTE)';
              vdDtValidade := NULL;
          END;
        END IF;
        -- Flag de Restrição
        IF (vvObs IS NOT NULL) THEN
          vvRestricao := '*';
        END IF;
    
        -----------------------
        -- Observações do Bonus
        -----------------------
        IF (NVL(vFIL_USAINTEGRACAOWMS,'N') = 'S') AND
           (NVL(vFIL_INTEGRADORAWMS,'0')   = '7') THEN
          IF (vvObs IS NULL) THEN
            -- Verifica Status do Bonus
            BEGIN
              SELECT PCBONUSC.DATAFECHACOMPLETA
                INTO dDATAFECHACOMPLETA
                FROM PCBONUSC
               WHERE (NUMBONUS = vnNumBonus);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                dDATAFECHACOMPLETA := NULL;
            END;
            IF (dDATAFECHACOMPLETA IS NULL) THEN
              vvObs       := 'Bônus não processado';
              vvRestricao := '*';
            END IF;
          END IF;
        END IF;
        
        -----------------------------------------
        -- Verifica se o Produto está na Promoção
        -----------------------------------------
        IF (pi_nOrigemChamada = 1) THEN -- Somente ao Carregar todos os produtos da entrada para seleção - DDMEDICA-1953
          IF (FUSA_REGRA_MEDICAMENTOS('99','IGNORARPRODFORAPROMOCROSSDOCK') = 'S') THEN
            BEGIN
              SELECT 'S'
                INTO vvProdutoEmPromocao
                FROM PCDESCONTO 
               WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                 AND (CODPROD        = vc_Movimentacao.CODPROD)
                 AND (ROWNUM         = 1);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vvProdutoEmPromocao := 'N';
            END;
            IF (vvProdutoEmPromocao = 'N') THEN
              -- Flag de Restrição
              IF (vvObs IS NULL) THEN
                vvObs       := 'Produto não está na promoção de crossdocking ' || pi_nCodPromocaoMed;
                vvRestricao := '*';
              END IF;
            END IF;
          END IF;
        END IF;

        ----------------------
        -- Se aceita o Produto
        ----------------------
        IF (vbAceitaPrduto) THEN
        
          -- Pesquisa o Depósito Padrão de Crossdocking          
          vnDepositoPadraoCrossdock := 0;
          IF (NVL(vFIL_USAINTEGRACAOWMS,'N') = 'S') AND
             (NVL(vFIL_INTEGRADORAWMS,'0')   = '7') THEN
            P_OBTER_DEPOSITO_WMS(vvCodFilial,
                                 'PADRAOCROSSDOCKSAIDA',
                                 vnDepositoPadraoCrossdock,
                                 vvDescDepositoPadraoCrossdock);
          END IF;        
          
          -- Pesquisa as Faltas e Avarias - DDMEDICA-1769
          vnQtFaltaAvaria := 0;
          IF (NVL(vFIL_USAINTEGRACAOWMS,'N') = 'S') AND
             (NVL(vFIL_INTEGRADORAWMS,'0')   = '7') THEN
            BEGIN
              IF (vvEstoquePorLote = 'S') THEN
                EXECUTE IMMEDIATE ' SELECT SUM(PCINT_CONTROLE_FALTA_AVARIA.QTCONT) '          || 
                                  '   FROM PCINT_CONTROLE_FALTA_AVARIA '                      ||
                                  '  WHERE NUMTRANSENT = ' || NVL(pi_nNumTransEnt,0)          || 
                                  '    AND CODPROD     = ' || NVL(vc_Movimentacao.CODPROD,0)  || 
                                  '    AND NUMLOTE     = ' || '''' || vc_Movimentacao.NUMLOTE || ''''
                             INTO vnQtFaltaAvaria;
              ELSE
                EXECUTE IMMEDIATE ' SELECT SUM(PCINT_CONTROLE_FALTA_AVARIA.QTCONT) '          || 
                                  '   FROM PCINT_CONTROLE_FALTA_AVARIA '                      ||
                                  '  WHERE NUMTRANSENT = ' || NVL(pi_nNumTransEnt,0)          || 
                                  '    AND CODPROD     = ' || NVL(vc_Movimentacao.CODPROD,0)
                             INTO vnQtFaltaAvaria;
              END IF;
            EXCEPTION
              WHEN OTHERS THEN
                vnQtFaltaAvaria := 0;
            END;
          END IF;

          -- Calcula a Quantidade do Crossdocking
          vnQtCrossDocking := (NVL(vc_Movimentacao.QTCONT,0) - NVL(vnQtFaltaAvaria,0));
          IF (NVL(vnQtCrossDocking,0) < 0) THEN
            vnQtCrossDocking := 0;
          END IF;
          
          -- Se tem Qtde. de Crossdocking - DDMEDICA-1769 
          IF (NVL(vnQtCrossDocking,0) > 0) THEN
               
            -- Incrementa o Contador de ID
            viContaID := NVL(viContaID,0) + 1;
            
            -- Insere Produto no Array da Entrada
            vtEntrada(viContaID).nCODIGODEPOSITOWMS    := vnDepositoPadraoCrossdock;
            vtEntrada(viContaID).vDESCRICAODEPOSITOWMS := vvDescDepositoPadraoCrossdock;
            vtEntrada(viContaID).nID                   := viContaID; 
            vtEntrada(viContaID).nCODPROD              := vc_Movimentacao.CODPROD; 
            vtEntrada(viContaID).vNUMLOTE              := vc_Movimentacao.NUMLOTE; 
            vtEntrada(viContaID).dDTVALIDADE           := vdDtValidade; 
            vtEntrada(viContaID).nQT                   := vnQtCrossDocking; -- DDMEDICA-1769 
            vtEntrada(viContaID).nCUSTOFIN             := vc_Movimentacao.CUSTOULTENTCONT; 
            vtEntrada(viContaID).vRESTRICAO            := vvRestricao;
            vtEntrada(viContaID).vOBS                  := vvObs;
            
          END IF;
              
        END IF; -- Fim Condição: Se aceita o Produto
                                  
      END LOOP; -- Fim Laço de Movimentações                               

    ------------------------------------------------------------------------------
    ------------------------------------------------------------------------------
    -->> Pedido de Transferência - Televendas (Não tem Lote) 
    ------------------------------------------------------------------------------
    ------------------------------------------------------------------------------
    ELSIF (pi_vTipoPedido = 'PT') THEN

      -- Inicializa o Contador de ID
      viContaID := 0;
        
      -- Laço de Movimentações
      FOR vc_Movimentacao IN (SELECT PCMOV.CODPROD
                                   , SUM(PCMOV.QT) QT
                                   , SUM(PCMOV.QTCONT) QTCONT
                                FROM PCMOV
                                   , PCMOVCOMPLE 
                               WHERE (PCMOV.NUMTRANSENT  = pi_nNumTransEnt)
                                 AND (PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM)
                               GROUP BY PCMOV.CODPROD
                               ORDER BY PCMOV.CODPROD) LOOP
                                          
        -------------------------------
        -- Verifica se aceita o Produto
        -------------------------------
        vbAceitaPrduto := TRUE;
        
        -------------------
        -- Custo Financeiro
        -------------------
        vvRestricao  := NULL;
        vvObs        := NULL;
        BEGIN
          SELECT CUSTOFIN
            INTO vnCustoFinTV10
            FROM PCEST
           WHERE (CODFILIAL = vvCodFilial)
             AND (CODPROD   = vc_Movimentacao.CODPROD);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnCustoFinTV10 := 0;
        END;
        IF (NVL(vnCustoFinTV10,0) = 0) THEN
          vvObs       := 'Sem Custo Financeiro (PCEST) na Filial ' || vvCodFilial;
          vvRestricao := '*';
        END IF;
                
        ----------------------
        -- Se aceita o Produto
        ----------------------
        IF (vbAceitaPrduto) THEN
        
          -- Pesquisa o Depósito Padrão da Transferência 
          vnDepositoPadraoCrossdock := 0;
          IF (NVL(vFIL_USAINTEGRACAOWMS,'N') = 'S') AND
             (NVL(vFIL_INTEGRADORAWMS,'0')   = '7') THEN
            
            -- Padrão Saída
            P_OBTER_DEPOSITO_WMS(vvCodFilial,
                                 'PADRAOSAIDA',
                                 vnDepositoPadraoTV10,
                                 vvDescDepositoPadraoTV10);
            
          END IF;        
        
          -- Calcula a Quantidade da Transferência
          vnQtTV10 := NVL(vc_Movimentacao.QT,0);
          IF (NVL(vnQtTV10,0) = 0) THEN
            vnQtTV10 := NVL(vc_Movimentacao.QTCONT,0);
          END IF;
        
          -- Se tem Qtde
          IF (NVL(vnQtTV10,0) > 0) THEN
               
            -- Incrementa o Contador de ID
            viContaID := NVL(viContaID,0) + 1;
            
            -- Insere Produto no Array da Entrada
            vtEntrada(viContaID).nCODIGODEPOSITOWMS    := vnDepositoPadraoTV10;
            vtEntrada(viContaID).vDESCRICAODEPOSITOWMS := vvDescDepositoPadraoTV10;
            vtEntrada(viContaID).nID                   := viContaID; 
            vtEntrada(viContaID).nCODPROD              := vc_Movimentacao.CODPROD; 
            vtEntrada(viContaID).vNUMLOTE              := NULL; 
            vtEntrada(viContaID).dDTVALIDADE           := NULL; 
            vtEntrada(viContaID).nQT                   := NVL(vnQtTV10,0);
            vtEntrada(viContaID).nCUSTOFIN             := NVL(vnCustoFinTV10,0); 
            vtEntrada(viContaID).vRESTRICAO            := vvRestricao;
            vtEntrada(viContaID).vOBS                  := vvObs;
            
          END IF;
              
        END IF; -- Fim Condição: Se aceita o Produto
                                  
      END LOOP; -- Fim Laço de Movimentações                               

    ------------------------------------------------------------------------------
    ------------------------------------------------------------------------------
    -->> Pedido de Transferência - Balcão (Tem Lote) 
    ------------------------------------------------------------------------------
    ------------------------------------------------------------------------------
    ELSIF (pi_vTipoPedido = 'PTB') THEN

      -- Inicializa o Contador de ID
      viContaID := 0;
        
      -- Laço de Movimentações
      FOR vc_Movimentacao IN (SELECT PCMOV.CODPROD
                                   , PCMOV.NUMLOTE
                                   , SUM(PCMOV.QT) QT
                                   , SUM(PCMOV.QTCONT) QTCONT
                                FROM PCMOV
                                   , PCMOVCOMPLE 
                               WHERE (PCMOV.NUMTRANSENT  = pi_nNumTransEnt)
                                 AND (PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM)
                               GROUP BY PCMOV.CODPROD
                                      , PCMOV.NUMLOTE
                               ORDER BY PCMOV.CODPROD,
                                        PCMOV.NUMLOTE) LOOP
  
        ----------------------------
        -- Pesquisa Dados do Produto
        ----------------------------
        BEGIN
          SELECT ESTOQUEPORLOTE
            INTO vvEstoquePorLote
            FROM PCPRODUT
           WHERE (CODPROD = vc_Movimentacao.CODPROD); 
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvEstoquePorLote := 'N';
        END;
                                        
        -------------------------------
        -- Verifica se aceita o Produto
        -------------------------------
        vbAceitaPrduto := TRUE;
        
        --------------
        -- Observações
        --------------
        vvRestricao  := NULL;
        vvObs        := NULL;
        vdDtValidade := NULL;
        -- Verifica se tem o Lote na PCLOTE
        IF (vvEstoquePorLote = 'S') THEN
          BEGIN
            SELECT NULL
                 , DTVALIDADE
              INTO vvObs
                 , vdDtValidade
              FROM PCLOTE
             WHERE (CODFILIAL = vvCodFilial)
               AND (CODPROD   = vc_Movimentacao.CODPROD)
               AND (NUMLOTE   = vc_Movimentacao.NUMLOTE);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vvObs        := 'Sem Estoque por Lote (PCLOTE)';
              vdDtValidade := NULL;
          END;
        END IF;
        -- Flag de Restrição
        IF (vvObs IS NOT NULL) THEN
          vvRestricao := '*';
        END IF;
        
        -------------------
        -- Custo Financeiro
        -------------------
        BEGIN
          SELECT CUSTOFIN
            INTO vnCustoFinTV10
            FROM PCEST
           WHERE (CODFILIAL = vvCodFilial)
             AND (CODPROD   = vc_Movimentacao.CODPROD);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnCustoFinTV10 := 0;
        END;
        IF (NVL(vnCustoFinTV10,0) = 0) THEN
          vvObs       := 'Sem Custo Financeiro (PCEST) na Filial ' || vvCodFilial;
          vvRestricao := '*';
        END IF;
        
        ----------------------
        -- Se aceita o Produto
        ----------------------
        IF (vbAceitaPrduto) THEN
         
          -- Pesquisa o Depósito Padrão da Transferência 
          vnDepositoPadraoCrossdock := 0;
          IF (NVL(vFIL_USAINTEGRACAOWMS,'N') = 'S') AND
             (NVL(vFIL_INTEGRADORAWMS,'0')   = '7') THEN
            
            -- Começa com o Padrão Saída
            P_OBTER_DEPOSITO_WMS(vvCodFilial,
                                 'PADRAOSAIDA',
                                 vnDepositoPadraoTV10,
                                 vvDescDepositoPadraoTV10);
            
            -- Substitui pelo Depósito Padrão do Motivo de Dev. Cliente se existir
            IF (NVL(vnCodDevol,0) > 0) THEN
              vnDepositoPadraoDevCli := F_OBTER_DEPOSITO_WMS_DEVCLI(vvCodFilial, vnCodDevol);
              IF (NVL(vnDepositoPadraoDevCli,0) > 0) THEN
                P_OBTER_DADOS_DEPOSITO_WMS(vvCodFilial,
                                           vnDepositoPadraoDevCli,
                                           vnDepositoPadraoTV10,
                                           vvDescDepositoPadraoTV10);
              END IF;                                           
            END IF;
                        
          END IF;        
         
          -- Calcula a Quantidade da Transferência
          vnQtTV10 := NVL(vc_Movimentacao.QT,0);
          IF (NVL(vnQtTV10,0) = 0) THEN
            vnQtTV10 := NVL(vc_Movimentacao.QTCONT,0);
          END IF;
        
          ----------
          -- Avarias
          ----------
          IF (NVL(vnNumBonus,0) > 0) THEN
            SELECT SUM(PCBONUSI.QTAVARIA)
              INTO vnQtAvaria
               FROM PCBONUSI
              WHERE (PCBONUSI.NUMBONUS = vnNumBonus)
                AND (PCBONUSI.CODPROD  = vc_Movimentacao.CODPROD)
                AND (PCBONUSI.NUMLOTE  = vc_Movimentacao.NUMLOTE);
            IF (NVL(vnQtAvaria,0) > 0) THEN
              vnQtTV10 := NVL(vnQtTV10,0) - NVL(vnQtAvaria,0);
            END IF;
          END IF;
        
          -- Se tem Qtde
          IF (NVL(vnQtTV10,0) > 0) THEN
               
            -- Incrementa o Contador de ID
            viContaID := NVL(viContaID,0) + 1;
            
            -- Insere Produto no Array da Entrada
            vtEntrada(viContaID).nCODIGODEPOSITOWMS    := vnDepositoPadraoTV10;
            vtEntrada(viContaID).vDESCRICAODEPOSITOWMS := vvDescDepositoPadraoTV10;
            vtEntrada(viContaID).nID                   := viContaID; 
            vtEntrada(viContaID).nCODPROD              := vc_Movimentacao.CODPROD; 
            vtEntrada(viContaID).vNUMLOTE              := vc_Movimentacao.NUMLOTE; 
            vtEntrada(viContaID).dDTVALIDADE           := vdDtValidade; 
            vtEntrada(viContaID).nQT                   := NVL(vnQtTV10,0);
            vtEntrada(viContaID).nCUSTOFIN             := NVL(vnCustoFinTV10,0); 
            vtEntrada(viContaID).vRESTRICAO            := vvRestricao;
            vtEntrada(viContaID).vOBS                  := vvObs;
            
          END IF;
              
        END IF; -- Fim Condição: Se aceita o Produto
                                  
      END LOOP; -- Fim Laço de Movimentações                               

    ------------------------------------------------------------------------------
    ------------------------------------------------------------------------------
    -->> Pedido Troca de Nota - (Tem Lote) - DDMEDICA-1969
    ------------------------------------------------------------------------------
    ------------------------------------------------------------------------------
    ELSIF (pi_vTipoPedido = 'PN') THEN

      -- Inicializa o Contador de ID
      viContaID := 0;
        
      -- Laço de Movimentações
      FOR vc_Movimentacao IN (SELECT PCMOV.CODPROD
                                   , PCMOV.NUMLOTE
                                   , SUM(PCMOV.QT) QT
                                   , SUM(PCMOV.QTAVARIA) QTAVARIA
                                   , MAX((NVL(PCMOV.PUNIT,0) - NVL(PCMOV.ST,0) - NVL(PCMOV.VLREPASSE,0) - NVL(PCMOVCOMPLE.VLFECP,0)) + NVL(PCMOV.VLDESCICMISENCAO,0)) PLIQ
                                FROM PCMOV
                                   , PCMOVCOMPLE 
                               WHERE (PCMOV.NUMTRANSENT  = pi_nNumTransEnt)
                                 AND (PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM)
                               GROUP BY PCMOV.CODPROD
                                      , PCMOV.NUMLOTE
                               ORDER BY PCMOV.CODPROD,
                                        PCMOV.NUMLOTE) LOOP
  
        ----------------------------
        -- Pesquisa Dados do Produto
        ----------------------------
        BEGIN
          SELECT ESTOQUEPORLOTE
            INTO vvEstoquePorLote
            FROM PCPRODUT
           WHERE (CODPROD = vc_Movimentacao.CODPROD); 
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvEstoquePorLote := 'N';
        END;
                                        
        -------------------------------
        -- Verifica se aceita o Produto
        -------------------------------
        vbAceitaPrduto := TRUE;
        
        --------------
        -- Observações
        --------------
        vvRestricao  := NULL;
        vvObs        := NULL;
        vdDtValidade := NULL;
        -- Verifica se tem o Lote na PCLOTE
        IF (vvEstoquePorLote = 'S') THEN
          BEGIN
            SELECT NULL
                 , DTVALIDADE
              INTO vvObs
                 , vdDtValidade
              FROM PCLOTE
             WHERE (CODFILIAL = vvCodFilial)
               AND (CODPROD   = vc_Movimentacao.CODPROD)
               AND (NUMLOTE   = vc_Movimentacao.NUMLOTE);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vvObs        := 'Sem Estoque por Lote (PCLOTE)';
              vdDtValidade := NULL;
          END;
        END IF;
        -- Flag de Restrição
        IF (vvObs IS NOT NULL) THEN
          vvRestricao := '*';
        END IF;
        
        -- Validação da Avaria
        vvRestricao  := NULL;
        vvObs        := NULL;
        IF (NVL(vc_Movimentacao.QTAVARIA,0) = 0) THEN
          vvObs       := 'Sem mercadoria avariada';
          vvRestricao := '*';
        END IF;

        -- Validação de Preço Líquido
        vvRestricao  := NULL;
        vvObs        := NULL;
        IF (NVL(vc_Movimentacao.PLIQ,0) <= 0) THEN
          vvObs       := 'Preço Líquido Inválido: ' || NVL(vc_Movimentacao.PLIQ,0);
          vvRestricao := '*';
        END IF;
        
        -- Obtém Depósito Padrão do Motivo de Dev. Cliente
        vnDepositoPadraoTrocaNota := 0;
        IF (NVL(vFIL_USAINTEGRACAOWMS,'N') = 'S') AND
           (NVL(vFIL_INTEGRADORAWMS,'0')   = '7') THEN
          IF (NVL(vnCodDevol,0) > 0) THEN
            vnDepositoPadraoDevCli := F_OBTER_DEPOSITO_WMS_DEVCLI(vvCodFilial, vnCodDevol);
            IF (NVL(vnDepositoPadraoDevCli,0) > 0) THEN
              vnDepositoPadraoTrocaNota     := NULL;
              vvDescDepositoPadraoTrocaNota := NULL;
              P_OBTER_DADOS_DEPOSITO_WMS(vvCodFilial,
                                         vnDepositoPadraoDevCli,
                                         vnDepositoPadraoTrocaNota,
                                         vvDescDepositoPadraoTrocaNota);
              IF (NVL(vnDepositoPadraoTrocaNota,0) = 0) THEN
                vvObs       := 'Sem depósito de troca de nota no motivo de devolução de cliente';
                vvRestricao := '*';
              END IF;
            END IF;
          ELSE
            vvObs       := 'Nota de Entrada sem motivo de devolução de cliente';
            vvRestricao := '*';
          END IF;
        END IF;
        
        ----------------------
        -- Se aceita o Produto
        ----------------------
        IF (vbAceitaPrduto) THEN
         
          -- Calcula a Quantidade da Troca de Nota
          vnQtTrocaNota := NVL(vc_Movimentacao.QTAVARIA,0);
        
          -- Se tem Qtde
          IF (NVL(vnQtTrocaNota,0) > 0) THEN
               
            -- Incrementa o Contador de ID
            viContaID := NVL(viContaID,0) + 1;
            
            -- Insere Produto no Array da Entrada
            vtEntrada(viContaID).nCODIGODEPOSITOWMS    := vnDepositoPadraoTrocaNota;
            vtEntrada(viContaID).vDESCRICAODEPOSITOWMS := vvDescDepositoPadraoTrocaNota;
            vtEntrada(viContaID).nID                   := viContaID; 
            vtEntrada(viContaID).nCODPROD              := vc_Movimentacao.CODPROD; 
            vtEntrada(viContaID).vNUMLOTE              := vc_Movimentacao.NUMLOTE; 
            vtEntrada(viContaID).dDTVALIDADE           := vdDtValidade; 
            vtEntrada(viContaID).nQT                   := NVL(vnQtTrocaNota,0);
            vtEntrada(viContaID).nCUSTOFIN             := NVL(vc_Movimentacao.PLIQ,0); 
            vtEntrada(viContaID).vRESTRICAO            := vvRestricao;
            vtEntrada(viContaID).vOBS                  := vvObs;
            
          END IF;
              
        END IF; -- Fim Condição: Se aceita o Produto
                                  
      END LOOP; -- Fim Laço de Movimentações                               

    ------------------------------------------------------------------------------
    ------------------------------------------------------------------------------
    -->> Promoção por Lote  
    ------------------------------------------------------------------------------
    ------------------------------------------------------------------------------
    ELSIF (pi_vTipoPedido = 'PL') THEN

      -- Inicializa o Contador de ID
      viContaID := 0;
        
      -- Laço dos Lotes da Promoção
      FOR vc_Promocao IN (-- Select da Chamada = 2
                          SELECT DISTINCT
                                 L.CODIGOINTEGRACAOWMS CODIGODEPOSITOWMS
                               , L.CODPROD
                               , L.NUMLOTE
                               , L.VALORCOTAMED QUANTIDADE
                               , CASE WHEN (L.CODIGOINTEGRACAOWMS IS NOT NULL) THEN
                                   (SELECT SUBSTR(R.DESCRICAODEPOSITOWMS,1,40) 
                                      FROM PCINT_RELACIONA_DEPOSITO_ESTOQ R 
                                     WHERE R.CODIGODEPOSITOWMS = L.CODIGOINTEGRACAOWMS)
                                 ELSE
                                   ''
                                 END DESCRICAODEPOSITOWMS 
                            FROM PCDESCONTO L
                           WHERE (pi_nOrigemChamada = 2)
                             AND (L.CODPROMOCAOMED  = pi_nCodPromocaoMed)
                             AND (L.CODPROD         = pi_nCodProd)
                          UNION 
                          -- Select da Chamada = 4
                          SELECT TO_CHAR(L.CODPROMOCAOMED) CODIGODEPOSITOWMS
                               , L.CODPROD
                               , L.NUMLOTE
                               , L.VALORCOTAMED QUANTIDADE
                               , SUBSTR(P.DESCRICAORESUMIDA,1,40) DESCRICAODEPOSITOWMS 
                            FROM PCDESCONTO    L
                               , PCPROMOCAOMED P
                           WHERE (pi_nOrigemChamada = 4)
                             AND (L.CODPROMOCAOMED  = P.CODPROMOCAOMED)
                             AND (P.TIPOPROMOCAO    = 'L')
                             AND (L.CODPROMOCAOMED IN (SELECT PCPEDI.CODPROMOCAOMED FROM PCPEDI WHERE PCPEDI.NUMPED = pi_nNumPed))                             
                             ) LOOP
                     
        ----------------------------
        -- Pesquisa Dados do Produto
        ----------------------------
        BEGIN
          SELECT ESTOQUEPORLOTE
            INTO vvEstoquePorLote
            FROM PCPRODUT
           WHERE (CODPROD = vc_Promocao.CODPROD); 
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvEstoquePorLote := 'N';
        END;
                                        
        -------------------------------
        -- Verifica se aceita o Produto
        -------------------------------
        vbAceitaPrduto := FALSE;
        -- Se carrega todos os produtos da entrada/pedido
        IF    (pi_nOrigemChamada IN (1,4)) THEN
          vbAceitaPrduto := TRUE;
        -- Se Valida Saldo do Produto e Lote
        ELSIF (pi_nOrigemChamada = 2) THEN
          IF (vc_Promocao.CODPROD          = pi_nCodProd)          AND
             (NVL(vc_Promocao.NUMLOTE,' ') = NVL(pi_vNumLote,' ')) THEN
            vbAceitaPrduto := TRUE;
          END IF;
        -- Se Exibir Lotes para Seleção
        ELSIF (pi_nOrigemChamada = 3) THEN
          IF (vc_Promocao.CODPROD = pi_nCodProd) THEN
            vbAceitaPrduto := TRUE;
          END IF;
        END IF;                                      
        
        --------------
        -- Observações
        --------------
        vvRestricao := NULL;
        vvObs       := NULL;
        -- Verifica se tem o Lote na PCLOTE
        IF (NVL(vvEstoquePorLote,'N') = 'S') THEN
          BEGIN
            SELECT NULL
                 , DTVALIDADE
              INTO vvObs
                 , vdDtValidade
              FROM PCLOTE
             WHERE (CODFILIAL = vvCodFilial)
               AND (CODPROD   = vc_Promocao.CODPROD)
               AND (NUMLOTE   = vc_Promocao.NUMLOTE);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vvObs        := 'Sem Estoque por Lote (PCLOTE)';
              vdDtValidade := NULL;
          END;
        ELSE
          vvObs        := 'Produto sem controle de lote';
          vdDtValidade := NULL;
        END IF;
        -- Flag de Restrição
        IF (vvObs IS NOT NULL) THEN
          vvRestricao := '*';
        END IF;
    
        ----------------------
        -- Se aceita o Produto
        ----------------------
        IF (vbAceitaPrduto) THEN
              
          -- Incrementa o Contador de ID
          viContaID := NVL(viContaID,0) + 1;
          
          -- Insere Produto no Array da Entrada
          vtEntrada(viContaID).nCODIGODEPOSITOWMS    := vc_Promocao.CODIGODEPOSITOWMS;
          vtEntrada(viContaID).vDESCRICAODEPOSITOWMS := vc_Promocao.DESCRICAODEPOSITOWMS;
          vtEntrada(viContaID).nID                   := viContaID; 
          vtEntrada(viContaID).nCODPROD              := vc_Promocao.CODPROD; 
          vtEntrada(viContaID).vNUMLOTE              := vc_Promocao.NUMLOTE; 
          vtEntrada(viContaID).dDTVALIDADE           := vdDtValidade; 
          vtEntrada(viContaID).nQT                   := vc_Promocao.QUANTIDADE; 
          vtEntrada(viContaID).vRESTRICAO            := vvRestricao;
          vtEntrada(viContaID).vOBS                  := vvObs;
              
        END IF; -- Fim Condição: Se aceita o Produto
                                  
      END LOOP; -- Fim Laço de Movimentações                               

    ------------------------------------------------------------------------------
    ------------------------------------------------------------------------------
    -->> Pedido de Avaria
    ------------------------------------------------------------------------------
    ------------------------------------------------------------------------------
    ELSIF (pi_vTipoPedido = 'PA') THEN
    
      -- Verifica se tem dados na tabela de Integração
      vvUsaLoteIntegracao := 'N';
      IF (NVL(vFIL_USAINTEGRACAOWMS,'N') = 'S') AND
         (NVL(vFIL_INTEGRADORAWMS,'0')   = '7') THEN
        BEGIN
          SELECT 'S'
            INTO vvUsaLoteIntegracao
            FROM PCINT_ESTOQUE_LOTE_DEPOSITO
           WHERE (ROWNUM = 1);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvUsaLoteIntegracao := 'N';
        END;
      END IF;      
    
      -- Integração WMS - Usa Tabela por Lote do WMS -----------------------------
      IF (NVL(vvUsaLoteIntegracao,'N') = 'S') THEN

        -- Inicializa o Contador de ID
        viContaID := 0;
          
        -- Laço de Movimentações
        FOR vc_Movimentacao IN (SELECT L.CODIGODEPOSITOWMS
                                     , L.CODPROD
                                     , L.NUMLOTE
                                     , L.DTVALIDADE
                                     , L.QUANTIDADE
                                     , SUBSTR(R.DESCRICAODEPOSITOWMS,1,40) DESCRICAODEPOSITOWMS
                                  FROM PCINT_ESTOQUE_LOTE_DEPOSITO    L
                                     , PCINT_RELACIONA_DEPOSITO_ESTOQ R
                                 WHERE (L.CODIGODEPOSITOWMS = R.CODIGODEPOSITOWMS)
                                   AND (R.TIPOESTOQUEERP    = 'I')
                                   AND (L.CODFILIAL         = vvCodFilial)
                                   AND (L.CODPROD           = pi_nCodProd)) LOOP -->> Depósitos de Estoque Indenizado (Avaria)
                       
          ----------------------------
          -- Pesquisa Dados do Produto
          ----------------------------
          BEGIN
            SELECT ESTOQUEPORLOTE
              INTO vvEstoquePorLote
              FROM PCPRODUT
             WHERE (CODPROD = vc_Movimentacao.CODPROD); 
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vvEstoquePorLote := 'N';
          END;
                                          
          -------------------------------
          -- Verifica se aceita o Produto
          -------------------------------
          vbAceitaPrduto := FALSE;
          -- Se carrega todos os produtos da entrada/pedido
          IF    (pi_nOrigemChamada IN (1,4)) THEN
            vbAceitaPrduto := TRUE;
          -- Se Valida Saldo do Produto e Lote
          ELSIF (pi_nOrigemChamada = 2) THEN
            IF (vc_Movimentacao.CODPROD          = pi_nCodProd)          AND
               (NVL(vc_Movimentacao.NUMLOTE,' ') = NVL(pi_vNumLote,' ')) THEN
              vbAceitaPrduto := TRUE;
            END IF;
          -- Se Exibir Lotes para Seleção
          ELSIF (pi_nOrigemChamada = 3) THEN
            IF (vc_Movimentacao.CODPROD = pi_nCodProd) THEN
              vbAceitaPrduto := TRUE;
            END IF;
          END IF;                                      
          
          --------------
          -- Observações
          --------------
          vvRestricao := NULL;
          vvObs       := NULL;
          -- Verifica se tem o Lote na PCLOTE
          IF (vvEstoquePorLote = 'S') THEN
            BEGIN
              SELECT NULL
                INTO vvObs
                FROM PCLOTE
               WHERE (CODFILIAL = vvCodFilial)
                 AND (CODPROD   = vc_Movimentacao.CODPROD)
                 AND (NUMLOTE   = vc_Movimentacao.NUMLOTE);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vvObs := 'Sem Estoque por Lote (PCLOTE)';
            END;
          END IF;
          -- Flag de Restrição
          IF (vvObs IS NOT NULL) THEN
            vvRestricao := '*';
          END IF;
      
          ----------------------
          -- Se aceita o Produto
          ----------------------
          IF (vbAceitaPrduto) THEN
                
            -- Incrementa o Contador de ID
            viContaID := NVL(viContaID,0) + 1;
            
            -- Insere Produto no Array da Entrada
            vtEntrada(viContaID).nCODIGODEPOSITOWMS    := vc_Movimentacao.CODIGODEPOSITOWMS;
            vtEntrada(viContaID).vDESCRICAODEPOSITOWMS := vc_Movimentacao.DESCRICAODEPOSITOWMS;
            vtEntrada(viContaID).nID                   := viContaID; 
            vtEntrada(viContaID).nCODPROD              := vc_Movimentacao.CODPROD; 
            vtEntrada(viContaID).vNUMLOTE              := vc_Movimentacao.NUMLOTE; 
            vtEntrada(viContaID).dDTVALIDADE           := vc_Movimentacao.DTVALIDADE; 
            vtEntrada(viContaID).nQT                   := vc_Movimentacao.QUANTIDADE; 
            vtEntrada(viContaID).vRESTRICAO            := vvRestricao;
            vtEntrada(viContaID).vOBS                  := vvObs;
                
          END IF; -- Fim Condição: Se aceita o Produto
                                    
        END LOOP; -- Fim Laço de Movimentações                               
      
      -- Sem Integração Específica WMS - Usa PCLOTE ------------------------------
      ELSE
      
        -- Inicializa o Contador de ID
        viContaID := 0;
          
        -- Laço de Lotes Indenizados
        FOR vc_Movimentacao IN (SELECT L.CODPROD
                                     , L.NUMLOTE
                                     , L.DTVALIDADE
                                     , L.QTINDENIZ QUANTIDADE
                                  FROM PCLOTE L
                                 WHERE (L.CODPROD   = pi_nCodProd)
                                   AND (L.CODFILIAL = vvCodFilial)
                                   AND (L.QTINDENIZ > 0)) LOOP
                       
          ----------------------------
          -- Pesquisa Dados do Produto
          ----------------------------
          BEGIN
            SELECT ESTOQUEPORLOTE
              INTO vvEstoquePorLote
              FROM PCPRODUT
             WHERE (CODPROD = vc_Movimentacao.CODPROD); 
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vvEstoquePorLote := 'N';
          END;
                                          
          -------------------------------
          -- Verifica se aceita o Produto
          -------------------------------
          vbAceitaPrduto := FALSE;
          -- Se carrega todos os produtos da entrada/pedido
          IF    (pi_nOrigemChamada IN (1,4)) THEN
            vbAceitaPrduto := TRUE;
          -- Se Valida Saldo do Produto e Lote
          ELSIF (pi_nOrigemChamada = 2) THEN
            IF (vc_Movimentacao.CODPROD          = pi_nCodProd)          AND
               (NVL(vc_Movimentacao.NUMLOTE,' ') = NVL(pi_vNumLote,' ')) THEN
              vbAceitaPrduto := TRUE;
            END IF;
          -- Se Exibir Lotes para Seleção
          ELSIF (pi_nOrigemChamada = 3) THEN
            IF (vc_Movimentacao.CODPROD = pi_nCodProd) THEN
              vbAceitaPrduto := TRUE;
            END IF;
          END IF;                                      
          
          --------------
          -- Observações
          --------------
          vvRestricao := NULL;
          vvObs       := NULL;
      
          ----------------------
          -- Se aceita o Produto
          ----------------------
          IF (vbAceitaPrduto) THEN
                
            -- Incrementa o Contador de ID
            viContaID := NVL(viContaID,0) + 1;
            
            -- Pesquisa o Depósito Padrão de Avaria          
            vnDepositoPadraoAvaria := 0;
            IF (NVL(vFIL_USAINTEGRACAOWMS,'N') = 'S') AND
               (NVL(vFIL_INTEGRADORAWMS,'0')   = '7') THEN
              P_OBTER_DEPOSITO_WMS(vvCodFilial,
                                   'PADRAOAVARIASAIDA',
                                   vnDepositoPadraoAvaria,
                                   vvDescDepositoPadraoAvaria);
            END IF;
            
            -- Insere Produto no Array da Entrada
            vtEntrada(viContaID).nCODIGODEPOSITOWMS    := vnDepositoPadraoAvaria;
            vtEntrada(viContaID).vDESCRICAODEPOSITOWMS := vvDescDepositoPadraoAvaria;
            vtEntrada(viContaID).nID                   := viContaID; 
            vtEntrada(viContaID).nCODPROD              := vc_Movimentacao.CODPROD; 
            vtEntrada(viContaID).vNUMLOTE              := vc_Movimentacao.NUMLOTE; 
            vtEntrada(viContaID).dDTVALIDADE           := vc_Movimentacao.DTVALIDADE; 
            vtEntrada(viContaID).nQT                   := vc_Movimentacao.QUANTIDADE; 
            vtEntrada(viContaID).vRESTRICAO            := vvRestricao;
            vtEntrada(viContaID).vOBS                  := vvObs;
                
          END IF; -- Fim Condição: Se aceita o Produto
                                    
        END LOOP; -- Fim Laço de Lotes Indenizados                              
      
      END IF;

    END IF;
      
   /******************************************************************************  
    Quantidade para estorno do Item Atual
    *************************************/  
    vnQtEstorno := 0;
    IF (pi_nOrigemChamada = 2) THEN
      BEGIN
        SELECT QT
          INTO vnQtEstorno
          FROM PCPEDI
         WHERE (NUMPED  = pi_nNumPed)
           AND (CODPROD = pi_nCodProd)
           AND (NUMSEQ  = pi_nNumSeq); 
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnQtEstorno := 0;
      END;
    END IF;
  
   /******************************************************************************  
    Vendas já realizadas para o Pedido diferente do atual
    Somente: Crossdocking e Promoção por Lote
    *****************************************************/  
    -->> Crossdocking
    IF (pi_vTipoPedido = 'PC') THEN
      FOR vc_Vendas IN (SELECT PCPEDC.NUMPED
                             , PCPEDI.CODPROD
                             , PCPEDI.NUMLOTE
                             , PCPEDI.QT
                          FROM PCPEDC
                             , PCPEDI
                         WHERE (PCPEDC.NUMPED               = PCPEDI.NUMPED)                      
                           AND (PCPEDC.DATA                >= vdDtEnt)    -->> Vendas superior à Data de Entrada para não fazer Full Table
                           AND (PCPEDC.NUMTRANSENTCROSSDOCK = pi_nNumTransEnt)
                           AND (PCPEDC.NUMPED              <> pi_nNumPed) -->> Desconsidera o Pedido Atual
                           AND (NVL(PCPEDC.POSICAO,' ')    <> 'C')
                           AND (NVL(PCPEDI.POSICAO,' ')    <> 'C')) LOOP
                           
        ----------------------
        -- ACUMULA VENDA GERAL                       
        ----------------------
        P_SOMA_VALORES(vtVendaGeral,
                       vc_Vendas.CODPROD,
                       vc_Vendas.NUMLOTE,
                       vc_Vendas.QT);
                                                 
      END LOOP;
    -->> Promoção por Lote
    ELSIF (pi_vTipoPedido = 'PL') THEN
      -- Se Valida Saldo do Produto e Lote
      IF    (pi_nOrigemChamada = 2) THEN
        -- Pesquisa a Data Inicial da promoção passada no parâmetro
        BEGIN
          SELECT LEAST(PCPROMOCAOMED.DATAINICIAL,PCPROMOCAOMED.DATALANC)
            INTO vdDtEnt
            FROM PCPROMOCAOMED
           WHERE (PCPROMOCAOMED.CODPROMOCAOMED = pi_nCodPromocaoMed);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vdDtEnt := NULL;
        END;      
        -- Laço de Venda do produto e promoção passado no parâmetro
        FOR vc_Vendas IN (SELECT PCPEDI.NUMPED
                               , PCPEDI.CODPROD
                               , NVL(PCPEDI.NUMLOTE,PCPEDI.NUMLOTEPROMOCAOMED) NUMLOTEINDUCAO
                               , PCPEDI.QT
                            FROM PCPEDI
                           WHERE (PCPEDI.DATA            >= vdDtEnt)
                             AND (PCPEDI.CODPROD          = pi_nCodProd)
                             AND (PCPEDI.CODPROMOCAOMED   = pi_nCodPromocaoMed)
                             AND (PCPEDI.NUMPED           <> pi_nNumPed) -->> Desconsidera o Pedido Atual
                             AND (NVL(PCPEDI.POSICAO,' ') <> 'C')) LOOP                 
          ----------------------
          -- ACUMULA VENDA GERAL                       
          ----------------------
          P_SOMA_VALORES(vtVendaGeral,
                         vc_Vendas.CODPROD,
                         vc_Vendas.NUMLOTEINDUCAO,
                         vc_Vendas.QT);
        END LOOP;
      -- Se carrega todos os produtos do pedido
      ELSIF (pi_nOrigemChamada = 4) THEN
        -- Pesquisa a menor Inicial da promoção por lote vendida no pedido
        SELECT MIN(LEAST(PCPROMOCAOMED.DATAINICIAL,PCPROMOCAOMED.DATALANC))
          INTO vdDtEnt
          FROM PCPROMOCAOMED
         WHERE (PCPROMOCAOMED.CODPROMOCAOMED IN (SELECT PCPEDI.CODPROMOCAOMED
                                                   FROM PCPEDI
                                                      , PCPROMOCAOMED
                                                  WHERE PCPEDI.CODPROMOCAOMED      = PCPROMOCAOMED.CODPROMOCAOMED
                                                    AND PCPROMOCAOMED.TIPOPROMOCAO = 'L'));                            
        -- Laço de Venda de todos os produtos com promoção por lote
        FOR vc_Vendas IN (SELECT PCPEDI.NUMPED
                               , PCPEDI.CODPROD
                               , NVL(PCPEDI.NUMLOTE,PCPEDI.NUMLOTEPROMOCAOMED) NUMLOTEINDUCAO
                               , PCPEDI.QT
                            FROM PCPEDI
                               , PCPROMOCAOMED
                           WHERE (PCPEDI.DATA               >= vdDtEnt)
                             AND (PCPEDI.CODPROMOCAOMED      = PCPROMOCAOMED.CODPROMOCAOMED)
                             AND (PCPROMOCAOMED.TIPOPROMOCAO = 'L')
                             AND (PCPEDI.NUMPED             <> pi_nNumPed) -->> Desconsidera o Pedido Atual
                             AND (NVL(PCPEDI.POSICAO,' ')   <> 'C')) LOOP                             
          ----------------------
          -- ACUMULA VENDA GERAL                       
          ----------------------
          P_SOMA_VALORES(vtVendaGeral,
                         vc_Vendas.CODPROD,
                         vc_Vendas.NUMLOTEINDUCAO,
                         vc_Vendas.QT);
        END LOOP;
      END IF;                                         
    END IF;
  
   /******************************************************************************  
    Vendas já realizadas para o Pedido Atual
    ****************************************/  
    FOR vc_Vendas IN (SELECT PCPEDI.NUMPED
                           , PCPEDI.CODPROD
                           , PCPEDI.NUMLOTE
                           , NVL(PCPEDI.NUMLOTE,PCPEDI.NUMLOTEPROMOCAOMED) NUMLOTEINDUCAO
                           , PCPEDI.QT
                        FROM PCPEDI
                       WHERE (PCPEDI.NUMPED            = pi_nNumPed) -->> Somente o Pedido Atual
                         AND (NVL(PCPEDI.POSICAO,' ') <> 'C')) LOOP
                         
      -----------------------------
      -- ACUMULA VENDA PEDIDO ATUAL                       
      -----------------------------
      IF (vc_Vendas.NUMPED = pi_nNumPed) THEN    
        -->> Promoção por Lote
        IF (NVL(pi_vTipoPedido,'PC') = 'PL') THEN
          P_SOMA_VALORES(vtVendaPedido,
                         vc_Vendas.CODPROD,
                         vc_Vendas.NUMLOTEINDUCAO,
                         vc_Vendas.QT);
        -->> Crossdocking/Avaria
        ELSE
          P_SOMA_VALORES(vtVendaPedido,
                         vc_Vendas.CODPROD,
                         vc_Vendas.NUMLOTE,
                         vc_Vendas.QT);
        END IF;
      END IF;
                                                
    END LOOP;                               
    
   /******************************************************************************  
    Processamento do Array com os Lotes
    ***********************************/    
    IF (vtEntrada.COUNT > 0) THEN
    
      ----------------------------------- 
      -- Laço de Movimentações de Entrada
      ----------------------------------- 
      FOR viIdxEnt IN vtEntrada.FIRST..vtEntrada.LAST LOOP
      
        ----------------------------------------------
        -- Pega dados do Array de Entrada
        ----------------------------------------------
        vrDadosEntrada := vtEntrada(viIdxEnt);       
  
        ----------------------------------------------
        -- Procura a Venda Geral para o Produto e Lote
        ----------------------------------------------
        vnQtVendaGeral := F_RETORNA_VENDA(vtVendaGeral,
                                          vrDadosEntrada.nCODPROD,
                                          vrDadosEntrada.vNUMLOTE);
      
        --------------------------------------------------
        -- Procura a Venda do Pedido para o Produto e Lote
        --------------------------------------------------
        vnQtVendaPedido := F_RETORNA_VENDA(vtVendaPedido,
                                           vrDadosEntrada.nCODPROD,
                                           vrDadosEntrada.vNUMLOTE);
                                 
        ------------------------------------------------------------------------
        -- Estorna a quantidade do item atual (qtde. depende do tipo de chamada)
        ------------------------------------------------------------------------
        vnQtVendaPedido := NVL(vnQtVendaPedido,0) - NVL(vnQtEstorno,0);
        IF (vnQtVendaPedido < 0) THEN
          vnQtVendaPedido := 0;
        END IF;
                                           
        ----------------
        -- Calcula Saldo
        ----------------
        vnQtSaldo := vrDadosEntrada.nQT - NVL(vnQtVendaGeral,0) - NVL(vnQtVendaPedido,0);
        IF (vnQtSaldo < 0)                AND
           (pi_nOrigemChamada NOT IN (4)) THEN -->> Chamadas que deve deixar ficar negativo
          vnQtSaldo := 0;
        END IF;                                  
  
        ---------------------
        -- Pesquisa Descrição
        ---------------------
        BEGIN
          SELECT DESCRICAO
            INTO vrDadosEntrada.vDESCRICAO
            FROM PCPRODUT
           WHERE (CODPROD = vrDadosEntrada.nCODPROD);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vrDadosEntrada.vDESCRICAO := NULL;
        END;
  
        ------------------------------------
        -- Verifica se Insere Dados na Table 
        ------------------------------------
        vbAceitaPrduto := FALSE;
        -- Se carrega todos os produtos da entrada
        IF (pi_nOrigemChamada = 1) THEN
          -- Somente se ainda tiver Saldo
          IF (vnQtSaldo > 0) THEN
            vbAceitaPrduto := TRUE;
          END IF;
        -- Se Valida Saldo do Produto e Lote
        ELSIF (pi_nOrigemChamada = 2) THEN
          -- Sempre aceita o produto (Já filtrou ignorou os demais ao carregar array de movimentação)
          vbAceitaPrduto  := TRUE;
        -- Se Exibir Lotes para Seleção
        ELSIF (pi_nOrigemChamada = 3) THEN
          -- Sempre aceita o produto (Já filtrou ignorou os demais ao carregar array de movimentação)
          vbAceitaPrduto  := TRUE;
        -- Se carrega todos os produtos do pedido
        ELSIF (pi_nOrigemChamada = 4) THEN
          -- Somente se ainda tiver venda no pedido
          IF (vnQtVendaPedido > 0) THEN
            vbAceitaPrduto := TRUE;
          END IF;
        END IF;                                      
  
        ------------------------
        -- Insere Dados na Table 
        ------------------------   
        IF (vbAceitaPrduto) THEN   
  
          OUTROW.NUMTRANSENT          := pi_nNumTransEnt;
          OUTROW.IDMOVIMENTACAO       := vrDadosEntrada.nID;
          OUTROW.CODPROD              := vrDadosEntrada.nCODPROD;
          OUTROW.NUMLOTE              := vrDadosEntrada.vNUMLOTE;
          OUTROW.DTVALIDADE           := vrDadosEntrada.dDTVALIDADE;
          OUTROW.DESCRICAO            := vrDadosEntrada.vDESCRICAO;
          OUTROW.CUSTOFIN             := vrDadosEntrada.nCUSTOFIN;
          OUTROW.QTDEENTRADA          := vrDadosEntrada.nQT;
          OUTROW.QTDESAIDA            := vnQtVendaGeral;
          OUTROW.QTDEPEDIDO           := vnQtVendaPedido;
          OUTROW.SALDO                := vnQtSaldo;      
          OUTROW.RESTRICAO            := vrDadosEntrada.vRESTRICAO;
          OUTROW.OBS                  := vrDadosEntrada.vOBS;
          OUTROW.CODIGODEPOSITOWMS    := vrDadosEntrada.nCODIGODEPOSITOWMS;
          OUTROW.DESCRICAODEPOSITOWMS := SUBSTR(vrDadosEntrada.vDESCRICAODEPOSITOWMS,1,40);
          PIPE ROW(OUTROW);
          
        END IF;
  
      END LOOP; -- Fim: Laço de Movimentações de Entrada    
    
    END IF; -- Fim Condição: Entrada tem Dados
  
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20000, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM);
  END F_OBTER_LOTES_PEDIDO;

  /*******************************************************************************
   Nome         : F_TIPOCOMISSGARANTIDA
   Descricão    : Função para retornar o Tipo de Comissão Garantida
   Parâmetros   : ENTRADA:
                  pi_vTipoComissGarantida      = Tipo de Comissão Garantida gravada na
                                                 Movimentação
                  pi_vEmpUtilizaComGarantida   = Se a Empresa utiliza a Comissão Garantida
                  pi_vPromoUtilizaComGarantida = Se a Promoção utiliza a Comissão Garantida
                  pi_vIgnoraRegraMovimentacao  = Se ignora a Regra gravada na Movimentação
                  pi_vIgnoraRegraPromocao      = Se ignora a Regra da Promoção utilizar
                                                 Comissão Garantida
                  pi_nCodProd                  = Código do Produto
                  pi_nCodCli                   = Código do Cliente
                  pi_nCodUsur                  = Código do RCA para pesquisa das Faixas
                  pi_nPercBonificVenda         = Percentual de Bonificação na Venda
                  pi_nPercDesc                 = Percentual de Desconto Comercial
                  pi_vTipoRetorno              = Tipo Retorno
                                                 - T - Tipo de Comissão Garantida
                                                 - C - Percentual Comissão Garantida
                                                 - F - Faixa de Desconto
                                                 - D - Desconto
   Alteracão    : Anderson Silva - 02/12/2014 - Criação da Função
   Alteracão    : Anderson Silva - 22/12/2014 - Ajuste Filtro Produto
   Alteração    : Anderson Silva - 30/11/2015 - Comissão Garantida por Faixa
   Alteração    : Anderson Silva - 04/12/2015 - Comissão Garantida por Faixa - Desconto Global
   Alteração    : Anderson Silva - 07/12/2015 - Comissão Garantida por Faixa - Desconto Global (Bonif+Comerc)
   Alteração    : Anderson Silva - 07/12/2015 - 5232.001575.2016 - Desconto não pode voltar vazio
  ********************************************************************************/
  FUNCTION F_TIPOCOMISSGARANTIDA(pi_vTipoComissGarantida      IN VARCHAR2,
                                 pi_vEmpUtilizaComGarantida   IN VARCHAR2,
                                 pi_vPromoUtilizaComGarantida IN VARCHAR2,
                                 pi_vIgnoraRegraMovimentacao  IN VARCHAR2,
                                 pi_vIgnoraRegraPromocao      IN VARCHAR2,
                                 pi_nCodProd                  IN NUMBER,
                                 pi_nCodCli                   IN NUMBER,
                                 pi_nCodUsur                  IN NUMBER,
                                 pi_nPercBonificVenda         IN NUMBER,
                                 pi_nPercDesc                 IN NUMBER,
                                 pi_vTipoRetorno              IN VARCHAR2)
  RETURN VARCHAR2
  IS
  
    -- Retorno
    vvRetTipoComissGarantida       VARCHAR2(40);
    
    -- Flag Achou Exceção
    vvAchouExcecao                 VARCHAR2(1);
    
    -- Variáveis para pesquisa da Faixa
    vnPerComGarantida              PCCOMISSGARANTIDAFAIXAS.PERCOMGARANTIDA%TYPE;
    vvFaixaDescGarantida           VARCHAR2(40);
    
    -- Desconto Global
    vnPercDescGlobal               NUMBER;
  
    -- Dados do Produto
    TYPE TRecProduto               IS RECORD(
         vnCodSubCategoria         PCPRODUT.CODSUBCATEGORIA%TYPE,
         vnCodCategoria            PCPRODUT.CODCATEGORIA%TYPE,
         vnCodSec                  PCPRODUT.CODSEC%TYPE,
         vnCodepto                 PCPRODUT.CODEPTO%TYPE,
         vnCodMarca                PCPRODUT.CODMARCA%TYPE,
         vnCodFornec               PCPRODUT.CODFORNEC%TYPE,
         vnCodLinhaProd            PCPRODUT.CODLINHAPROD%TYPE,
         vnCodProd                 PCPRODUT.CODPROD%TYPE,
         vnCodGrupoProdComissMed   PCPRODUT.CODGRUPOPRODCOMISSMED%TYPE);
    vrProduto                      TRecProduto;
  
    -- Dados do Cliente
    TYPE TRecCliente               IS RECORD(
         vnCodGrupoCliComissMed    PCCLIENT.CODGRUPOCLICOMISSMED%TYPE);
    vrCliente                      TRecCliente;
          
  BEGIN
    
   /***************************************
    EMPRESA TRABALHA COM COMISSAO GARANTIDA 
    ***************************************/
    IF (NVL(pi_vEmpUtilizaComGarantida,'N') = 'S') THEN
       
      -- Pega Tipo de Comissão Garantida da Movimentação
      vvRetTipoComissGarantida := pi_vTipoComissGarantida;
      
      -- Se ainda não tiver Tipo de Comissão Garantida na Movimentação OU Ignora Regra gravada na Movimentação
      IF ((vvRetTipoComissGarantida IS NULL) OR
          (NVL(pi_vIgnoraRegraMovimentacao,'N') = 'S')) THEN
      
        -- Se a Promoção tem Comissão Garantida OU Ignora Regra da Promoção
        IF ((NVL(pi_vPromoUtilizaComGarantida,'N') = 'S') OR
            (NVL(pi_vIgnoraRegraPromocao,'N')      = 'S')) THEN
            
          -- Pesquisa Dados do Produto
          BEGIN
            SELECT PCPRODUT.CODSUBCATEGORIA
                 , PCPRODUT.CODCATEGORIA
                 , PCPRODUT.CODSEC
                 , PCPRODUT.CODEPTO
                 , PCPRODUT.CODMARCA
                 , PCPRODUT.CODFORNEC
                 , PCPRODUT.CODLINHAPROD
                 , PCPRODUT.CODPROD
                 , PCPRODUT.CODGRUPOPRODCOMISSMED
              INTO vrProduto.vnCodSubCategoria
                 , vrProduto.vnCodCategoria
                 , vrProduto.vnCodSec
                 , vrProduto.vnCodepto
                 , vrProduto.vnCodMarca
                 , vrProduto.vnCodFornec
                 , vrProduto.vnCodLinhaProd
                 , vrProduto.vnCodProd
                 , vrProduto.vnCodGrupoProdComissMed
              FROM PCPRODUT
             WHERE (PCPRODUT.CODPROD = pi_nCodProd);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              NULL;
          END;   
          
          -- Pesquisa Grupo do Cliente        
          BEGIN
            SELECT PCCLIENT.CODGRUPOCLICOMISSMED
              INTO vrCliente.vnCodGrupoCliComissMed
              FROM PCCLIENT
             WHERE (PCCLIENT.CODCLI = pi_nCodCli);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              NULL;
          END;
          
          -- Pesquisa Exceção
          BEGIN
            SELECT 'S'
              INTO vvAchouExcecao
              FROM PCEXCECAOCOMISSGARANTIDA
             WHERE ( 
                    ((PCEXCECAOCOMISSGARANTIDA.TIPOEVENTO = 'GP') AND (PCEXCECAOCOMISSGARANTIDA.CODGRUPOPRODCOMISSMED = vrProduto.vnCodGrupoProdComissMed)) OR
                    ((PCEXCECAOCOMISSGARANTIDA.TIPOEVENTO = 'FE') AND (PCEXCECAOCOMISSGARANTIDA.CODFORNEC             = vrProduto.vnCodFornec))             OR
                    ((PCEXCECAOCOMISSGARANTIDA.TIPOEVENTO = 'MA') AND (PCEXCECAOCOMISSGARANTIDA.CODMARCA              = vrProduto.vnCodMarca))              OR
                    ((PCEXCECAOCOMISSGARANTIDA.TIPOEVENTO = 'LI') AND (PCEXCECAOCOMISSGARANTIDA.CODLINHAPROD          = vrProduto.vnCodLinhaProd))          OR
                    ((PCEXCECAOCOMISSGARANTIDA.TIPOEVENTO = 'PR') AND (PCEXCECAOCOMISSGARANTIDA.CODPROD               = vrProduto.vnCodProd))               OR
                    ((PCEXCECAOCOMISSGARANTIDA.TIPOEVENTO = 'SB') AND (PCEXCECAOCOMISSGARANTIDA.CODEPTO               = vrProduto.vnCodepto)
                                                                  AND (PCEXCECAOCOMISSGARANTIDA.CODSEC                = vrProduto.vnCodSec)
                                                                  AND (PCEXCECAOCOMISSGARANTIDA.CODCATEGORIA          = vrProduto.vnCodCategoria)
                                                                  AND (PCEXCECAOCOMISSGARANTIDA.CODSUBCATEGORIA       = vrProduto.vnCodSubCategoria))       OR
                    ((PCEXCECAOCOMISSGARANTIDA.TIPOEVENTO = 'CA') AND (PCEXCECAOCOMISSGARANTIDA.CODEPTO               = vrProduto.vnCodepto)
                                                                  AND (PCEXCECAOCOMISSGARANTIDA.CODSEC                = vrProduto.vnCodSec)
                                                                  AND (PCEXCECAOCOMISSGARANTIDA.CODCATEGORIA          = vrProduto.vnCodCategoria))          OR
                    ((PCEXCECAOCOMISSGARANTIDA.TIPOEVENTO = 'SE') AND (PCEXCECAOCOMISSGARANTIDA.CODEPTO               = vrProduto.vnCodepto)
                                                                  AND (PCEXCECAOCOMISSGARANTIDA.CODSEC                = vrProduto.vnCodSec))                OR
                    ((PCEXCECAOCOMISSGARANTIDA.TIPOEVENTO = 'DE') AND (PCEXCECAOCOMISSGARANTIDA.CODEPTO               = vrProduto.vnCodepto))               OR
                    ((PCEXCECAOCOMISSGARANTIDA.TIPOEVENTO = 'GC') AND (PCEXCECAOCOMISSGARANTIDA.CODGRUPOCLICOMISSMED  = vrCliente.vnCodGrupoCliComissMed))
                   )
               AND (ROWNUM = 1);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vvAchouExcecao := 'N';
          END;
          
          -- Se achou Exceção a Comissão será Normal
          IF (NVL(vvAchouExcecao,'N') = 'S') THEN
          
            vvRetTipoComissGarantida := 'N'; 
            
          -- Se NÃO achou Exceção a Comissão será Garantida
          ELSE
          
            vvRetTipoComissGarantida := 'G';
          
          END IF;
          
        -- SENÃO
        ELSE
        
          -- Comissão = Normal
          vvRetTipoComissGarantida := 'N';
        
        END IF; -- Fim Condição -- Se a Promoção tem Comissão Garantida OU Ignora Regra da Promoção
          
      END IF; -- Fim Condição Se ainda não tiver Tipo de Comissão Garantida na Movimentação
  
      ----------------------------    
      -- Calcula o Desconto Global
      ----------------------------
      vnPercDescGlobal := ROUND(100 - ((100*(1-(NVL(pi_nPercBonificVenda,0)/100))) * (1-(NVL(pi_nPercDesc,0)/100))),2);
      
      ---------------------------------------------
      -- RETORNA O PERCENTUAL DE COMISSÃO GARANTIDA
      ---------------------------------------------
      IF    (vvRetTipoComissGarantida = 'G') AND -->> Se tem Comissão Garantida
            (pi_vTipoRetorno          = 'C') THEN 
      
        -- Pesquisa o Percentual de Comissão conforme Desconto passado no parâmetro      
        BEGIN
          SELECT PCCOMISSGARANTIDAFAIXAS.PERCOMGARANTIDA
            INTO vnPerComGarantida
            FROM PCCOMISSGARANTIDAFAIXAS
           WHERE (PCCOMISSGARANTIDAFAIXAS.CODUSUR = pi_nCodUsur)
             AND (ROUND(NVL(vnPercDescGlobal,0),2) BETWEEN ROUND(NVL(PCCOMISSGARANTIDAFAIXAS.PERDESCINI,0),2) AND ROUND(NVL(PCCOMISSGARANTIDAFAIXAS.PERDESCFIM,0),2)) -->> Arredondar para duas casas
             AND (ROWNUM = 1);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnPerComGarantida := 0;
        END;
   
        -- Atualiza Retorno     
        vvRetTipoComissGarantida := TO_CHAR(vnPerComGarantida);
  
      ------------------------------
      -- RETORNA A FAIXA DE DESCONTO
      ------------------------------
      ELSIF (vvRetTipoComissGarantida = 'G') AND -->> Se tem Comissão Garantida
            (pi_vTipoRetorno          = 'F') THEN 
  
        -- Pesquisa o Percentual de Comissão conforme Desconto passado no parâmetro      
        BEGIN
          SELECT FERRAMENTAS_MED.FFORMATAR_NUMERO_PARA_TEXTO(NVL(PCCOMISSGARANTIDAFAIXAS.PERDESCINI,0),2) || '% a ' || FERRAMENTAS_MED.FFORMATAR_NUMERO_PARA_TEXTO(NVL(PCCOMISSGARANTIDAFAIXAS.PERDESCFIM,0),2) || '%'
            INTO vvFaixaDescGarantida
            FROM PCCOMISSGARANTIDAFAIXAS
           WHERE (PCCOMISSGARANTIDAFAIXAS.CODUSUR = pi_nCodUsur)
             AND (ROUND(NVL(vnPercDescGlobal,0),2) BETWEEN ROUND(NVL(PCCOMISSGARANTIDAFAIXAS.PERDESCINI,0),2) AND ROUND(NVL(PCCOMISSGARANTIDAFAIXAS.PERDESCFIM,0),2)) -->> Arredondar para duas casas
             AND (ROWNUM = 1);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvFaixaDescGarantida := ' - '; -->> Nunca retornar vazio
        END;
   
        -- Atualiza Retorno     
        vvRetTipoComissGarantida := vvFaixaDescGarantida;
        
      ---------------------
      -- RETORNA O DESCONTO
      ---------------------
      ELSIF (vvRetTipoComissGarantida = 'G') AND -->> Se tem Comissão Garantida
            (pi_vTipoRetorno          = 'D') THEN 
   
        -- Atualiza Retorno     
        vvRetTipoComissGarantida := TRIM(TO_CHAR(vnPercDescGlobal));
      
      --------------------------------
      -- SE NÃO TEM COMISSÃO GARANTIDA
      --------------------------------
      ELSE
      
        -- Atualiza Retorno quando chamado para retornar percentual de comissão garantida
        IF    (pi_vTipoRetorno = 'C') THEN
          vvRetTipoComissGarantida := '0'; -->> Nunca retornar vazio
        -- Atualiza Retorno quando chamado para retornar faixa de desconto
        ELSIF (pi_vTipoRetorno = 'F') THEN
          vvRetTipoComissGarantida := ' '; -->> Nunca retornar vazio
        -- Atualiza Retorno quando chamado para retornar o desconto
        ELSIF (pi_vTipoRetorno = 'D') THEN
          vvRetTipoComissGarantida := '0'; -->> Nunca retornar vazio
        END IF;
      
      END IF; -- FIM CONDIÇÃO TIPO RETORNO
        
   /*******************************************
    EMPRESA NÃO TRABALHA COM COMISSAO GARANTIDA 
    *******************************************/
    ELSE
    
      -->> Sem Comissão Garantida = Comissão Normal
      vvRetTipoComissGarantida := 'N'; 
          
  	-- Atualiza Retorno quando chamado para retornar percentual de comissão garantida
      IF    (pi_vTipoRetorno = 'C') THEN
        vvRetTipoComissGarantida := '0'; -->> Nunca retornar vazio
      -- Atualiza Retorno quando chamado para retornar faixa de desconto
      ELSIF (pi_vTipoRetorno = 'F') THEN
        vvRetTipoComissGarantida := ' '; -->> Nunca retornar vazio
      -- Atualiza Retorno quando chamado para retornar o desconto
      ELSIF (pi_vTipoRetorno = 'D') THEN
        vvRetTipoComissGarantida := '0'; -->> Nunca retornar vazio -- 5232.001575.2016
      END IF;
        
    END IF; -- Fim Condição EMPRESA TRABALHA COM COMISSAO GARANTIDA
      
    -- Retorno
    RETURN vvRetTipoComissGarantida;
  
  END F_TIPOCOMISSGARANTIDA;

 /*******************************************************************************
  Nome         : P_PROMOCAO_VALIDAR_COTA
  Descricão    : Procedimento para Validar as Cotas da Promoção - DDVENDAS-38166
  ********************************************************************************/                                       
  PROCEDURE P_VALIDAR_COTAS_PROMOCAO(pi_nNumPed                IN NUMBER,
                                     pi_nCodProd               IN NUMBER,
                                     pi_nNumSeq                IN NUMBER,
                                     pi_nCodPromocaoMed        IN NUMBER,
                                     pi_nCodCli                IN NUMBER,
                                     pi_nPTabela               IN NUMBER,
                                     pi_nPVenda                IN NUMBER,
                                     pi_nQt                    IN NUMBER,
                                     po_vRejeitarVenda        OUT VARCHAR2,
                                     po_vMsgVendaRejeitada    OUT VARCHAR2,
                                     po_nCotaUtilizadaGeral   OUT NUMBER,
                                     po_nCotaUtilizadaCliente OUT NUMBER) IS
    n_tipocotageral    PCPROMOCAOMED.TIPOCOTAGERAL%TYPE;
    n_valorcotageral   PCPROMOCAOMED.VALORCOTAGERAL%TYPE;
    n_tipocotacliente  PCPROMOCAOMED.TIPOCOTACLIENTE%TYPE;
    n_valorcotacliente PCPROMOCAOMED.VALORCOTACLIENTE%TYPE;
    d_datainicial      PCPROMOCAOMED.DATAINICIAL%TYPE;
    vdMenorDataInicial DATE;
    vnQtGeral          NUMBER;
    vnValorDescGeral   NUMBER;
    vnValorGeral       NUMBER;
    vnQtCliente        NUMBER;
    vnValorDescCliente NUMBER;
    vnValorCliente     NUMBER;
    vnValorDescItem    NUMBER;
    vnValorItem        NUMBER;
    --
    PROCEDURE P_ATU_MSGVENDAREJEITADA(pi_vTipoGeralCliente IN VARCHAR2,
                                      pi_nTipoCota         IN NUMBER,
                                      pi_nValorCota        IN NUMBER,
                                      pi_nValorUtilizado   IN NUMBER) IS
    BEGIN
    
      IF (NVL(pi_nValorUtilizado,0) > NVL(pi_nValorCota,0)) THEN
       
        po_vRejeitarVenda := 'S';
       
        IF (po_vMsgVendaRejeitada IS NOT NULL) THEN
          po_vMsgVendaRejeitada := po_vMsgVendaRejeitada || ' e a ';
        END IF;
        
        po_vMsgVendaRejeitada := po_vMsgVendaRejeitada || 'Cota ';
                
        IF    (pi_vTipoGeralCliente = 'G') THEN
          po_vMsgVendaRejeitada := po_vMsgVendaRejeitada || 'Geral ';
        ELSIF (pi_vTipoGeralCliente = 'C') THEN
          po_vMsgVendaRejeitada := po_vMsgVendaRejeitada || 'do Cliente ';
        END IF;
        
        IF    (pi_nTipoCota = 1) THEN
          po_vMsgVendaRejeitada := po_vMsgVendaRejeitada || 'por desconto ';
        ELSIF (pi_nTipoCota = 2) THEN
          po_vMsgVendaRejeitada := po_vMsgVendaRejeitada || 'por brindes ';
        END IF;
        
        po_vMsgVendaRejeitada := po_vMsgVendaRejeitada || 'foi excedida em ' || F_FORMATAR_NUMERO_PARA_TEXTO((NVL(pi_nValorUtilizado,0) - NVL(pi_nValorCota,0)), 2); 
      
      END IF;
              
    END P_ATU_MSGVENDAREJEITADA;
    --
  BEGIN
  
    po_vRejeitarVenda        := 'N';
    po_vMsgVendaRejeitada    := NULL;
    po_nCotaUtilizadaGeral   := 0;
    po_nCotaUtilizadaCliente := 0;
    
    IF (NVL(pi_nCodPromocaoMed,0) > 0) THEN
    
      BEGIN
        SELECT TIPOCOTAGERAL
             , VALORCOTAGERAL
             , TIPOCOTACLIENTE
             , VALORCOTACLIENTE
             , DATAINICIAL 
          INTO n_tipocotageral
             , n_valorcotageral
             , n_tipocotacliente
             , n_valorcotacliente 
             , d_datainicial
          FROM PCPROMOCAOMED
         WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          n_tipocotageral    := NULL;
          n_valorcotageral   := NULL;
          n_tipocotacliente  := NULL;
          n_valorcotacliente := NULL;
          d_datainicial      := NULL;
      END;
      
      IF ((NVL(n_tipocotageral,0) > 0) AND (NVL(n_valorcotageral,0) > 0)) OR
         ((NVL(n_tipocotacliente,0) > 0) AND (NVL(n_valorcotacliente,0) > 0)) THEN
         
        SELECT MIN(DATAINICIAL)
          INTO vdMenorDataInicial
          FROM PCLOGEDICAOPROMOCAOMED
         WHERE CODPROMOCAOMED = pi_nCodPromocaoMed;
         
         IF (vdMenorDataInicial IS NOT NULL) AND
            (vdMenorDataInicial < d_datainicial) THEN
           d_datainicial := vdMenorDataInicial; 
         END IF;
         
         SELECT SUM(CASE WHEN PCPEDC.POSICAO   = 'C'        THEN 0 
                         WHEN PCPEDC.CONDVENDA = 8          THEN 0 
                         WHEN PCPEDI.NUMPED = pi_nNumPed AND PCPEDI.CODPROD = pi_nCodProd AND PCPEDI.NUMSEQ = NVL(pi_nNumSeq,0) THEN 0
                         ELSE QT 
                     END) QT_GERAL
              , SUM(CASE WHEN PCPEDC.POSICAO   = 'C'        THEN 0 
                         WHEN PCPEDC.CONDVENDA = 8          THEN 0 
                         WHEN PCPEDI.NUMPED = pi_nNumPed AND PCPEDI.CODPROD = pi_nCodProd AND PCPEDI.NUMSEQ = NVL(pi_nNumSeq,0) THEN 0
                         ELSE ((NVL(PTABELA,0) - NVL(PVENDA,0)) * QT) 
                     END) VALORDESC_GERAL
              , SUM(CASE WHEN PCPEDC.POSICAO   = 'C'        THEN 0 
                         WHEN PCPEDC.CONDVENDA = 8          THEN 0 
                         WHEN PCPEDI.NUMPED = pi_nNumPed AND PCPEDI.CODPROD = pi_nCodProd AND PCPEDI.NUMSEQ = NVL(pi_nNumSeq,0) THEN 0
                         ELSE (NVL(PVENDA,0) * QT) 
                      END) VALOR_GERAL
             --        
              , SUM(CASE WHEN PCPEDC.CODCLI   <> pi_nCodCli THEN 0 
                         WHEN PCPEDC.POSICAO   = 'C'        THEN 0 
                         WHEN PCPEDC.CONDVENDA = 8          THEN 0 
                         WHEN PCPEDI.NUMPED = pi_nNumPed AND PCPEDI.CODPROD = pi_nCodProd AND PCPEDI.NUMSEQ = NVL(pi_nNumSeq,0) THEN 0
                         ELSE QT 
                     END) QT_CLIENTE
              , SUM(CASE WHEN PCPEDC.CODCLI   <> pi_nCodCli THEN 0 
                         WHEN PCPEDC.POSICAO   = 'C'        THEN 0 
                         WHEN PCPEDC.CONDVENDA = 8          THEN 0 
                         WHEN PCPEDI.NUMPED = pi_nNumPed AND PCPEDI.CODPROD = pi_nCodProd AND PCPEDI.NUMSEQ = NVL(pi_nNumSeq,0) THEN 0
                         ELSE ((NVL(PTABELA,0) - NVL(PVENDA,0)) * QT) 
                     END) VALORDESC_CLIENTE
              , SUM(CASE WHEN PCPEDC.CODCLI   <> pi_nCodCli THEN 0 
                         WHEN PCPEDC.POSICAO   = 'C'        THEN 0 
                         WHEN PCPEDC.CONDVENDA = 8          THEN 0 
                         WHEN PCPEDI.NUMPED = pi_nNumPed AND PCPEDI.CODPROD = pi_nCodProd AND PCPEDI.NUMSEQ = NVL(pi_nNumSeq,0) THEN 0
                         ELSE (NVL(PVENDA,0) * QT) 
                      END) VALOR_CLIENTE             
           INTO vnQtGeral
              , vnValorDescGeral
              , vnValorGeral
             --
              , vnQtCliente
              , vnValorDescCliente
              , vnValorCliente
           FROM PCPEDI
              , PCPEDC
          WHERE (PCPEDI.NUMPED          = PCPEDC.NUMPED)
            AND (PCPEDC.DATA           >= d_datainicial)
            AND (PCPEDI.DATA           >= d_datainicial)
            AND (PCPEDI.CODPROMOCAOMED  = pi_nCodPromocaoMed);
            
        vnValorDescItem := (NVL(pi_nPtabela,0) - NVL(pi_nPVenda,0)) * NVL(pi_nQt,0);
        vnValorItem     := (NVL(pi_nPVenda,0) * NVL(pi_nQt,0));

        -- Cotas Geral
                    
        IF    ((NVL(n_tipocotageral,0) = 1) AND (NVL(n_valorcotageral,0) > 0)) THEN
        
          po_nCotaUtilizadaGeral := NVL(vnValorDescGeral,0) + NVL(vnValorDescItem,0);
        
          P_ATU_MSGVENDAREJEITADA('G',
                                  n_tipocotageral,
                                  n_valorcotageral,
                                  po_nCotaUtilizadaGeral);
            
        ELSIF ((NVL(n_tipocotageral,0) = 2) AND (NVL(n_valorcotageral,0) > 0)) THEN
        
          po_nCotaUtilizadaGeral := NVL(vnValorGeral,0) + NVL(vnValorItem,0);

          P_ATU_MSGVENDAREJEITADA('G',
                                  n_tipocotageral,
                                  n_valorcotageral,
                                  po_nCotaUtilizadaGeral);
            
        END IF;    

        -- Cotas Cliente

        IF    ((NVL(n_tipocotacliente,0) = 1) AND (NVL(n_valorcotacliente,0) > 0)) THEN
                  
          po_nCotaUtilizadaCliente := NVL(vnValorDescCliente,0) + NVL(vnValorDescItem,0);
                  
          P_ATU_MSGVENDAREJEITADA('C',
                                  n_tipocotacliente,
                                  n_valorcotacliente,
                                  po_nCotaUtilizadaCliente);
            
        ELSIF ((NVL(n_tipocotacliente,0) = 2) AND (NVL(n_valorcotacliente,0) > 0)) THEN

          po_nCotaUtilizadaCliente := NVL(vnValorCliente,0) + NVL(vnValorItem,0);
        
          P_ATU_MSGVENDAREJEITADA('C',
                                  n_tipocotacliente,
                                  n_valorcotacliente,
                                  po_nCotaUtilizadaCliente);
            
        END IF;    
         
      END IF;
      
      IF (po_vRejeitarVenda = 'S') THEN
        po_vMsgVendaRejeitada := po_vMsgVendaRejeitada || ' (Promoção: ' || pi_nCodPromocaoMed || ')';
      END IF;
    
    END IF; -- pi_nCodPromocaoMed > 0
  
  END P_VALIDAR_COTAS_PROMOCAO; 
  
 /*******************************************************************************
  Nome         : F_CONSOLIDA_COTAS_PROMOCAO
  Descricão    : Função para Consolidação das Cotas da Promoção
  Parâmetros   : ENTRADA:
                 pi_nOpcaoVigencia   : 0 - Todas abertas
                                       1 - Todas abertas e canceladas
                                       2 - Somente vigentes
                 pi_nOpcaoAgrupamento: 0 - Geral
                                       1 - Pedido
                                       2 - Pedido/Produto
	               pi_vListaPromocoes  : Lista de Promoções separadas por vírgula           
  ********************************************************************************/                                        
  FUNCTION F_CONSOLIDA_COTAS_PROMOCAO(pi_nOpcaoVigencia    IN NUMBER DEFAULT 0, 
                                      pi_nOpcaoAgrupamento IN NUMBER DEFAULT 0,
                                      pi_vListaPromocoes   IN VARCHAR2 DEFAULT NULL) 
  RETURN TD_CONSOLIDA_COTA_PROMOCAO PARALLEL_ENABLE PIPELINED IS
    
    -- Tabelas para uso no BulkCollect -- Promoções
    TYPE TT_CODPROMOCAOMED     IS TABLE OF PCPROMOCAOMED.CODPROMOCAOMED%TYPE INDEX BY BINARY_INTEGER; 
    TYPE TT_DESCRICAORESUMIDA  IS TABLE OF PCPROMOCAOMED.DESCRICAORESUMIDA%TYPE INDEX BY BINARY_INTEGER; 
    TYPE TT_DESCRICAODETALHADA IS TABLE OF PCPROMOCAOMED.DESCRICAODETALHADA%TYPE INDEX BY BINARY_INTEGER; 
    TYPE TT_DATAINICIAL        IS TABLE OF PCPROMOCAOMED.DATAINICIAL%TYPE INDEX BY BINARY_INTEGER; 
    TYPE TT_DATAFINAL          IS TABLE OF PCPROMOCAOMED.DATAFINAL%TYPE INDEX BY BINARY_INTEGER; 
    TYPE TT_REGRARESTRICAO     IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;
    TYPE TT_CODCLI             IS TABLE OF PCCLIENT.CODCLI%TYPE INDEX BY BINARY_INTEGER; 
    TYPE TT_CLIENTE            IS TABLE OF PCCLIENT.CLIENTE%TYPE INDEX BY BINARY_INTEGER; 
    TYPE TT_FANTASIA           IS TABLE OF PCCLIENT.FANTASIA%TYPE INDEX BY BINARY_INTEGER; 
    TYPE TT_TIPOCOTA           IS TABLE OF PCPROMOCAOMED.TIPOCOTAGERAL%TYPE INDEX BY BINARY_INTEGER; 
    TYPE TT_VALORCOTA          IS TABLE OF NUMBER INDEX BY BINARY_INTEGER; 
    TYPE TT_NUMPED             IS TABLE OF PCPEDI.NUMPED%TYPE INDEX BY BINARY_INTEGER; 
    TYPE TT_CODPROD            IS TABLE OF PCPEDI.CODPROD%TYPE INDEX BY BINARY_INTEGER; 
    TYPE TT_QT                 IS TABLE OF NUMBER INDEX BY BINARY_INTEGER; 
    TYPE TT_VALORDESC          IS TABLE OF NUMBER INDEX BY BINARY_INTEGER; 
    TYPE TT_VALORTOTAL         IS TABLE OF NUMBER INDEX BY BINARY_INTEGER; 
    vtCODPROMOCAOMED           TT_CODPROMOCAOMED;
    vtCODPROMOCAOITEM          TT_CODPROMOCAOMED;
    vtDESCRICAORESUMIDA        TT_DESCRICAORESUMIDA;
    vtDESCRICAODETALHADA       TT_DESCRICAODETALHADA;
    vtDATAINICIAL              TT_DATAINICIAL;
    vtDATAFINAL                TT_DATAFINAL;
    vtREGRARESTRICAO           TT_REGRARESTRICAO;
    vtCODCLI                   TT_CODCLI;
    vtCLIENTE                  TT_CLIENTE;
    vtFANTASIA                 TT_FANTASIA;
    vtTIPOCOTA                 TT_TIPOCOTA;
    vtVALORCOTA                TT_VALORCOTA;
    vtNUMPED                   TT_NUMPED;
    vtCODPROD                  TT_CODPROD;
    vtQT                       TT_QT;
    vtVALORDESC                TT_VALORDESC;
    vtVALORTOTAL               TT_VALORTOTAL;
    -- Promoções processadas
    TYPE TRecPromoProc         IS TABLE OF VARCHAR2(255) INDEX BY BINARY_INTEGER;
    vtPromoProc                TRecPromoProc;
    
    -- SQL
    vvSql                      VARCHAR2(32000);
    vvWhereVigente             VARCHAR2(32000);
    vvWhereVigenteLog          VARCHAR2(32000);
    vvInPromocoes              VARCHAR2(32000);
    vvInPromocoesLog           VARCHAR2(32000);
    vvColunasAgrupamento       VARCHAR2(32000);
    vvGroupByAgrupamento       VARCHAR2(32000);
    vvColunaCliente            VARCHAR2(32000);
    vvGroupByCliente           VARCHAR2(32000);
    
    -- Dados Cliente
    vvCliente                  PCCLIENT.CLIENTE%TYPE;
    vvFantasia                 PCCLIENT.FANTASIA%TYPE;
    
    -- Tipo Objeto
    OUTROW TR_CONSOLIDA_COTA_PROMOCAO := TR_CONSOLIDA_COTA_PROMOCAO(NULL -- CODPROMOCAOMED
                                                                   ,NULL -- DESCRICAORESUMIDA
                                                                   ,NULL -- DESCRICAODETALHADA
                                                                   ,NULL -- DATAINICIAL
                                                                   ,NULL -- DATAFINAL
                                                                   ,NULL -- REGRARESTRICAO
                                                                   ,NULL -- CODCLI
                                                                   ,NULL -- CLIENTE
                                                                   ,NULL -- FANTASIA
                                                                   ,NULL -- TIPOCOTA
                                                                   ,NULL -- DESCRICAOTIPOCOTA
                                                                   ,NULL -- VALORCOTA
                                                                   ,NULL -- VALORUTILIZADO
                                                                   ,NULL -- NUMPED
                                                                   ,NULL -- CODPROD
                                                                   );                                                                 
    
    PROCEDURE P_LIMPA_ARRAYS IS
    BEGIN
      vtCODPROMOCAOITEM.DELETE;
      vtQT.DELETE;
      vtVALORDESC.DELETE;
      vtVALORTOTAL.DELETE;
    END;
    
    FUNCTION F_GET_DESC_TIPOCOTA(pi_nTipoCota IN NUMBER)
    RETURN VARCHAR2 IS
      vvRetDesc VARCHAR2(100);
    BEGIN
      IF    (pi_nTipoCota = 1) THEN        
        vvRetDesc := 'VALOR DO DESCONTO';
      ELSIF (pi_nTipoCota = 2) THEN
        vvRetDesc := 'VALOR LIQUIDO';
      END IF;    
      RETURN vvRetDesc;   
    END F_GET_DESC_TIPOCOTA;
        
  BEGIN
    
    -- Filtro Vigentes
    IF (pi_nOpcaoVigencia = 2) THEN
      vvWhereVigente    := ' AND (TRUNC(SYSDATE) BETWEEN PCPROMOCAOMED.DATAINICIAL AND PCPROMOCAOMED.DATAFINAL) ';
      vvWhereVigenteLog := ' AND (TRUNC(SYSDATE) BETWEEN PCLOGPROMOCAOMED.DATAINICIAL AND PCLOGPROMOCAOMED.DATAFINAL) ';
    END IF;
    
    -- Colunas Agrupamento
    IF    (pi_nOpcaoAgrupamento = 1) THEN
      vvColunasAgrupamento    := ', PCPEDI.NUMPED, TO_NUMBER(NULL) CODPROD ';
      vvGroupByAgrupamento    := ', PCPEDI.NUMPED ';
    ELSIF (pi_nOpcaoAgrupamento = 2) THEN
      vvColunasAgrupamento := ', PCPEDI.NUMPED, PCPEDI.CODPROD ';
      vvGroupByAgrupamento := ', PCPEDI.NUMPED, PCPEDI.CODPROD ';
    ELSE
      vvColunasAgrupamento := ', TO_NUMBER(NULL) NUMPED, TO_NUMBER(NULL) CODPROD ';
      vvGroupByAgrupamento := '';
    END IF;

    -- Filtro Promoções
    IF (pi_vListaPromocoes IS NOT NULL) THEN
      vvInPromocoes    := ' AND (PCPROMOCAOMED.CODPROMOCAOMED IN (' || pi_vListaPromocoes || ')) ';
      vvInPromocoesLog := ' AND (PCLOGPROMOCAOMED.CODPROMOCAOMED IN (' || pi_vListaPromocoes || ')) ';
    END IF;
          
    -- Promoções

    P_LIMPA_ARRAYS;
          
    vvSql := 
      ' SELECT PCPROMOCAOMED.CODPROMOCAOMED
             , PCPROMOCAOMED.DESCRICAORESUMIDA
             , PCPROMOCAOMED.DESCRICAODETALHADA
             , PCPROMOCAOMED.DATAINICIAL
             , PCPROMOCAOMED.DATAFINAL
             , ''G'' REGRARESTRICAO
             , PCPROMOCAOMED.TIPOCOTAGERAL TIPOCOTA
             , PCPROMOCAOMED.VALORCOTAGERAL VALORCOTA
          FROM PCPROMOCAOMED
         WHERE (PCPROMOCAOMED.TIPOCOTAGERAL IN (1,2)) ' || vvWhereVigente || ' ' || vvInPromocoes || '
         UNION
        SELECT PCPROMOCAOMED.CODPROMOCAOMED
             , PCPROMOCAOMED.DESCRICAORESUMIDA
             , PCPROMOCAOMED.DESCRICAODETALHADA
             , PCPROMOCAOMED.DATAINICIAL
             , PCPROMOCAOMED.DATAFINAL
             , ''C'' REGRARESTRICAO
             , PCPROMOCAOMED.TIPOCOTACLIENTE TIPOCOTA
             , PCPROMOCAOMED.VALORCOTACLIENTE VALORCOTA
          FROM PCPROMOCAOMED
         WHERE (PCPROMOCAOMED.TIPOCOTACLIENTE IN (1,2)) ' || vvWhereVigente || ' ' || vvInPromocoes;
    IF (pi_nOpcaoVigencia = 1) THEN
      vvSql := vvSql || 
      '  UNION
        SELECT PCLOGPROMOCAOMED.CODPROMOCAOMED
             , PCLOGPROMOCAOMED.DESCRICAORESUMIDA
             , PCLOGPROMOCAOMED.DESCRICAODETALHADA
             , PCLOGPROMOCAOMED.DATAINICIAL
             , PCLOGPROMOCAOMED.DATAFINAL
             , ''G'' REGRARESTRICAO
             , PCLOGPROMOCAOMED.TIPOCOTAGERAL TIPOCOTA
             , PCLOGPROMOCAOMED.VALORCOTAGERAL VALORCOTA
          FROM PCLOGPROMOCAOMED
         WHERE (PCLOGPROMOCAOMED.TIPOCOTAGERAL IN (1,2)) ' || vvWhereVigenteLog || ' ' || vvInPromocoesLog || '
         UNION
        SELECT PCLOGPROMOCAOMED.CODPROMOCAOMED
             , PCLOGPROMOCAOMED.DESCRICAORESUMIDA
             , PCLOGPROMOCAOMED.DESCRICAODETALHADA
             , PCLOGPROMOCAOMED.DATAINICIAL
             , PCLOGPROMOCAOMED.DATAFINAL
             , ''C'' REGRARESTRICAO
             , PCLOGPROMOCAOMED.TIPOCOTACLIENTE TIPOCOTA
             , PCLOGPROMOCAOMED.VALORCOTACLIENTE VALORCOTA
          FROM PCLOGPROMOCAOMED
         WHERE (PCLOGPROMOCAOMED.TIPOCOTACLIENTE IN (1,2)) ' || vvWhereVigenteLog || ' ' || vvInPromocoesLog;
           
    END IF;
             
    EXECUTE IMMEDIATE vvSql
       BULK COLLECT INTO vtCODPROMOCAOMED,
                         vtDESCRICAORESUMIDA,
                         vtDESCRICAODETALHADA,
                         vtDATAINICIAL,
                         vtDATAFINAL,
                         vtREGRARESTRICAO,
                         vtTIPOCOTA,
                         vtVALORCOTA;
            
    IF (vtCODPROMOCAOMED.COUNT > 0) THEN
      FOR viPromo IN vtCODPROMOCAOMED.FIRST..vtCODPROMOCAOMED.LAST LOOP
          
        -- Colunas Cliente
          
        IF (vtREGRARESTRICAO(viPromo) = 'C') THEN
          vvColunaCliente  := ', PCPEDI.CODCLI ';
          vvGroupByCliente := ', PCPEDI.CODCLI ';     
        ELSE
          vvColunaCliente  := ', TO_NUMBER(NULL) CODCLI ';
          vvGroupByCliente := '';            
        END IF;        
          
        -- Pesquisa Faturamenbtio
                      
        P_LIMPA_ARRAYS;
                
        vvSql := 
          ' SELECT PCPEDI.CODPROMOCAOMED ' || vvColunaCliente || ' ' || vvColunasAgrupamento || '
                 , SUM(CASE WHEN PCPEDC.POSICAO   = ''C''                THEN 0 
                            WHEN PCPEDC.CONDVENDA = 8                    THEN 0 
                            ELSE QT 
                        END) QT_GERAL
                 , SUM(CASE WHEN PCPEDC.POSICAO   = ''C''                THEN 0 
                            WHEN PCPEDC.CONDVENDA = 8                    THEN 0 
                            ELSE ((NVL(PTABELA,0) - NVL(PVENDA,0)) * QT) 
                        END) VALORDESC_GERAL
                 , SUM(CASE WHEN PCPEDC.POSICAO   = ''C''                THEN 0 
                            WHEN PCPEDC.CONDVENDA = 8                    THEN 0 
                            ELSE (NVL(PVENDA,0) * QT) 
                         END) VALOR_GERAL
              FROM PCPEDI
                 , PCPEDC
             WHERE (PCPEDI.NUMPED         = PCPEDC.NUMPED) 
               AND (PCPEDI.DATA          >= TO_DATE(' || '''' || TO_CHAR(vtDATAINICIAL(viPromo),'DD/MM/YYYY') || '''' || ',' || '''' || 'DD/MM/YYYY' || '''' || '))
               AND (PCPEDI.CODPROMOCAOMED = ' || vtCODPROMOCAOMED(viPromo) || ')
             GROUP BY PCPEDI.CODPROMOCAOMED ' || vvGroupByCliente || ' ' || vvGroupByAgrupamento;
                   
        EXECUTE IMMEDIATE vvSql
           BULK COLLECT INTO vtCODPROMOCAOITEM,
                             vtCODCLI,
                             vtNUMPED,
                             vtCODPROD,
                             vtQT,
                             vtVALORDESC,
                             vtVALORTOTAL;
                  
        -- Se achou venda para a promoção
        IF (vtCODPROMOCAOITEM.COUNT > 0) THEN
              
          FOR viItem IN vtCODPROMOCAOITEM.FIRST..vtCODPROMOCAOITEM.LAST LOOP

            IF (vtREGRARESTRICAO(viPromo) = 'C') THEN          
              BEGIN
                SELECT PCCLIENT.CLIENTE
                     , PCCLIENT.FANTASIA
                  INTO vvCliente
                     , vvFantasia
                  FROM PCCLIENT
                 WHERE (PCCLIENT.CODCLI = vtCODCLI(viItem));
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  vvCliente  := NULL;
                  vvFantasia := NULL;
              END;
              OUTROW.CODCLI           := vtCODCLI(viItem);
              OUTROW.CLIENTE          := vvCliente;
              OUTROW.FANTASIA         := vvFantasia;
            ELSE
              OUTROW.CODCLI           := NULL;
              OUTROW.CLIENTE          := NULL;
              OUTROW.FANTASIA         := NULL;
            END IF;
            OUTROW.CODPROMOCAOMED     := vtCODPROMOCAOMED(viPromo);
            OUTROW.DESCRICAORESUMIDA  := vtDESCRICAORESUMIDA(viPromo);
            OUTROW.DESCRICAODETALHADA := vtDESCRICAODETALHADA(viPromo);
            OUTROW.DATAINICIAL        := vtDATAINICIAL(viPromo);
            OUTROW.DATAFINAL          := vtDATAFINAL(viPromo);
            OUTROW.REGRARESTRICAO     := vtREGRARESTRICAO(viPromo);
            OUTROW.TIPOCOTA           := vtTIPOCOTA(viPromo);
            OUTROW.DESCRICAOTIPOCOTA  := F_GET_DESC_TIPOCOTA(vtTIPOCOTA(viPromo));
            IF (pi_nOpcaoAgrupamento = 0) THEN
              OUTROW.VALORCOTA        := vtVALORCOTA(viPromo);
            ELSE
              OUTROW.VALORCOTA        := NULL;
            END IF;
            OUTROW.NUMPED             := vtNUMPED(viItem);
            OUTROW.CODPROD            := vtCODPROD(viItem);
            IF    (vtTIPOCOTA(viPromo) = 1) THEN        
              OUTROW.VALORUTILIZADO   := vtVALORDESC(viItem);
            ELSIF (vtTIPOCOTA(viPromo) = 2) THEN
              OUTROW.VALORUTILIZADO   := vtVALORTOTAL(viItem);
            END IF;
            PIPE ROW(OUTROW);
                                
          END LOOP;
            
        -- Se NÃO achou venda para a promoção
        ELSE
            
          IF (pi_nOpcaoAgrupamento = 0) THEN
              
            OUTROW.CODCLI             := NULL;
            OUTROW.CLIENTE            := NULL;
            OUTROW.FANTASIA           := NULL;
            OUTROW.CODPROMOCAOMED     := vtCODPROMOCAOMED(viPromo);
            OUTROW.DESCRICAORESUMIDA  := vtDESCRICAORESUMIDA(viPromo);
            OUTROW.DESCRICAODETALHADA := vtDESCRICAODETALHADA(viPromo);
            OUTROW.DATAINICIAL        := vtDATAINICIAL(viPromo);
            OUTROW.DATAFINAL          := vtDATAFINAL(viPromo);
            OUTROW.REGRARESTRICAO     := vtREGRARESTRICAO(viPromo);
            OUTROW.TIPOCOTA           := vtTIPOCOTA(viPromo);
            OUTROW.DESCRICAOTIPOCOTA  := F_GET_DESC_TIPOCOTA(vtTIPOCOTA(viPromo));
            OUTROW.VALORCOTA          := vtVALORCOTA(viPromo);
            OUTROW.NUMPED             := NULL;
            OUTROW.CODPROD            := NULL;
            OUTROW.VALORUTILIZADO     := NULL;
            PIPE ROW(OUTROW);
              
          END IF;
            
        END IF;
          
      END LOOP;
    END IF;
      
  END F_CONSOLIDA_COTAS_PROMOCAO;    

 /*******************************************************************************
  Nome         : P_VALIDAR_OBTER_LOTES_PRODUTO
  Descricão    : Procedimento para Validar Lote do Produto para Seleção no Pedido
  ********************************************************************************/                                       
  PROCEDURE P_VALIDAR_OBTER_LOTES_PRODUTO(pi_vTipoPedido       IN VARCHAR2,
                                          pi_nOrigemChamada    IN NUMBER,
                                          pi_nNumTransEnt      IN NUMBER,
                                          pi_nNumPed           IN NUMBER,
                                          pi_nCodProd          IN NUMBER,
                                          pi_nNumSeq           IN NUMBER,
                                          pi_vNumLote          IN VARCHAR2,
                                          pi_vCodFilial        IN VARCHAR2,
                                          pi_nCodPromocaoMed   IN NUMBER,
                                          po_nSaldoDisponivel OUT NUMBER)
  IS
  BEGIN
    po_nSaldoDisponivel := 0;
    FOR vc_Cursor IN (SELECT TB.SALDO
                        FROM TABLE(F_OBTER_LOTES_PEDIDO(pi_vTipoPedido, 
                                                        pi_nOrigemChamada,
                                                        pi_nNumTransEnt,
                                                        pi_nNumPed,
                                                        pi_nCodProd,
                                                        pi_nNumSeq,
                                                        pi_vNumLote,
                                                        pi_vCodFilial,
                                                        pi_nCodPromocaoMed)) TB) LOOP
      po_nSaldoDisponivel := NVL(vc_Cursor.SALDO,0);
    END LOOP; 
  END P_VALIDAR_OBTER_LOTES_PRODUTO;
               
  /*******************************************************************************
   Nome         : PRC_MED_VALIDACAO_FINAL_PROD
   Descricão    : Procedimento para Validação Final do Produto
   Parâmetros   : ENTRADA:
                  pi_vOrigemChamada        = Origem da Chamada
                                             'I' - Integradora_Med
                                             'T' - Televendas
                                             'C' - Inclusão Combos
                  pi_vTipoChamada          = Tipo de Chamada
                                             'I' - Inclusão do Item no Pedido
                                             'G' - Gravação do Pedido
                                             'P' - Inicio da Digitação do Pedido
                  pi_vGravarTabTemp        = Gravar Tabela Temporária
                                             S - SIM
                                             N - Não
                  pi_vOrigemPed            = Origem do Pedido
                  pi_vTipoFv               = Tipo Fv
                  pi_nIntegradora          = Integradora
                  pi_vCodFilial            = Código da Filial
                  pi_vCodFilialNf          = Código da Filial NF
                  pi_vCodFilialRetira      = Código da Filial Retira
                  pi_nCodCli               = Código do Cliente
                  pi_nNumRegiao            = Região
                  pi_nCodUsur              = Código do RCA
                  pi_nCodPlPag             = Código do Plano de Pagamento
                  pi_nCodPromocaoMed       = Código da Promoção            
                  pi_nCodProd              = Código do Produto
                  pi_nQtdeVenda            = Qtde. Vendida
                  pi_nPercDesc             = Percentual de Desconto
                  pi_nPUnitario            = Preço Unitário sem ST e sem Repasse
                  pi_nNumPed               = Número Pedido
                  pi_nNumSeq               = Número da Sequência do Item
                  pi_nPrecoMaxConsum       = Preço Máximo do Consumidor
                  SAIDA:
                  po_vTipoRejeicaoProduto  = Tipo de Rejeição do Produto
                                             N - Não possui Rejeições
                                             B - Bloqueia Pedido
                                             R - Rejeita Produto (não deixa vender)
                                             E - Erro na Procedure
                  po_vMotivoNaoPodeComprar = Descrição do Motivo de não poder comprar
                  po_nQtdeLimite           = Quantidade Limite que pode comprar
   Alteracão    : Anderson Silva - 05/05/2016 - HIS.00365.2016 - Criação da Procedure
   Alteracão    : Anderson Silva - 08/06/2016 - Força de Vendas gravará como Bloqueado no caso de Rejeição dos Tetos
   Alteração    : Anderson Silva - 19/12/2016 - HIS.01765.2016 - Validação do Preço Máximo do Consumidor
   Alteração    : Anderson Silva - 07/03/2017  Anderson Silva  OLePE - PMC Liberados
   Alteração    : 15/02/2018 - MERGE PCNIL - Anderson Silva - 23/10/2017 - Limite Desconto com Promoção
   Alteração    : 01/06/2018 - MED-1238 - Truncar % Desconto 2 casas decimais
   Alteração    : 13/09/2018 - E-Commerce não pode travar nos Tetos
   Alteração    : 09/09/2019 - DDMEDICA-735 - Proibida Venda Controlados por Filial Retira
  ********************************************************************************/                                       
  PROCEDURE P_VALIDACAO_FINAL_PROD(pi_vOrigemChamada        IN  VARCHAR2,
                                   pi_vTipoChamada          IN  VARCHAR2,
                                   pi_vGravarTabTemp        IN  VARCHAR2,
                                   pi_vOrigemPed            IN  VARCHAR2,
                                   pi_vTipoFv               IN  VARCHAR2,
                                   pi_nIntegradora          IN  NUMBER,
                                   pi_vCodFilial            IN  VARCHAR2,
                                   pi_vCodFilialNf          IN  VARCHAR2,
                                   pi_vCodFilialRetira      IN  VARCHAR2,
                                   pi_nCodCli               IN  NUMBER,
                                   pi_nNumRegiao            IN  NUMBER,
                                   pi_nCodUsur              IN  NUMBER,
                                   pi_nCodPlPag             IN  NUMBER,
                                   pi_nCodPromocaoMed       IN  NUMBER,
                                   pi_nCodProd              IN  NUMBER,
                                   pi_nQtdeVenda            IN  NUMBER,   
                                   pi_nPercDesc             IN  NUMBER,
                                   pi_nPUnitario            IN  NUMBER,
                                   pi_nNumPed               IN  NUMBER,                                     
                                   pi_nNumSeq               IN  NUMBER,
                                   pi_nPrecoMaxConsum       IN  NUMBER,
                                   po_vTipoRejeicaoProduto  OUT VARCHAR2,
                                   po_vMotivoNaoPodeComprar OUT VARCHAR2,
                                   po_nQtdeLimite           OUT VARCHAR,
                                   pi_nCodDesconto          IN  NUMBER DEFAULT NULL,
                                   pi_vNumLote              IN  VARCHAR DEFAULT NULL,
                                   pi_vNumLotePromocaoMed   IN  VARCHAR DEFAULT NULL)
  IS  
        
  /*******************************************************************************
                     INICIO DO PROCESSAMENTO PRINCIPAL
   *******************************************************************************/  
  BEGIN
  
    P_VALIDACAO_FINAL_PROD_01(pi_vOrigemChamada,
                              pi_vTipoChamada,
                              pi_vGravarTabTemp,
                              pi_vOrigemPed,
                              pi_vTipoFv,
                              pi_nIntegradora,
                              pi_vCodFilial,
                              pi_vCodFilialNf,
                              pi_vCodFilialRetira,
                              pi_nCodCli,
                              pi_nNumRegiao,
                              pi_nCodUsur,
                              pi_nCodPlPag,
                              pi_nCodPromocaoMed,
                              pi_nCodProd,
                              pi_nQtdeVenda,
                              pi_nPercDesc,
                              pi_nPUnitario,
                              pi_nNumPed,
                              pi_nNumSeq,
                              pi_nPrecoMaxConsum,
                              po_vTipoRejeicaoProduto,
                              po_vMotivoNaoPodeComprar,
                              po_nQtdeLimite,
                              pi_nCodDesconto,
                              pi_vNumLote,
                              pi_vNumLotePromocaoMed,
                              NULL,  -- pi_nPTabela
                              NULL,  -- pi_nPTabelaMarkup
                              NULL); -- pi_nCustoFin
    
  END P_VALIDACAO_FINAL_PROD;

  /*******************************************************************************
   Nome         : PRC_MED_VALIDACAO_FINAL_PROD_01 - DDVENDAS-35576
   Descricão    : Procedimento para Validação Final do Produto
   Parâmetros   : ENTRADA:
                  pi_vOrigemChamada        = Origem da Chamada
                                             'I' - Integradora_Med
                                             'T' - Televendas
                                             'C' - Inclusão Combos
                  pi_vTipoChamada          = Tipo de Chamada
                                             'I' - Inclusão do Item no Pedido
                                             'G' - Gravação do Pedido
                                             'P' - Inicio da Digitação do Pedido
                  pi_vGravarTabTemp        = Gravar Tabela Temporária
                                             S - SIM
                                             N - Não
                  pi_vOrigemPed            = Origem do Pedido
                  pi_vTipoFv               = Tipo Fv
                  pi_nIntegradora          = Integradora
                  pi_vCodFilial            = Código da Filial
                  pi_vCodFilialNf          = Código da Filial NF
                  pi_vCodFilialRetira      = Código da Filial Retira
                  pi_nCodCli               = Código do Cliente
                  pi_nNumRegiao            = Região
                  pi_nCodUsur              = Código do RCA
                  pi_nCodPlPag             = Código do Plano de Pagamento
                  pi_nCodPromocaoMed       = Código da Promoção            
                  pi_nCodProd              = Código do Produto
                  pi_nQtdeVenda            = Qtde. Vendida
                  pi_nPercDesc             = Percentual de Desconto
                  pi_nPUnitario            = Preço Unitário sem ST e sem Repasse
                  pi_nNumPed               = Número Pedido
                  pi_nNumSeq               = Número da Sequência do Item
                  pi_nPrecoMaxConsum       = Preço Máximo do Consumidor
                  pi_nCodDesconto          = Código do Desconto da PCDESCONTO
                  pi_vNumLote              = Número do Lote
                  pi_vNumLotePromocaoMed   = Número do Lote da Promoção por Lote
                  pi_nPTabela              = Preço Tabela
                  pi_nPTabelaMarkup        = Preço Tabela para Cálculo do Markup (Não tem Taxa Financeira)
                  pi_nCustoFin             = Custo Financeiro
                  SAIDA:
                  po_vTipoRejeicaoProduto  = Tipo de Rejeição do Produto
                                             N - Não possui Rejeições
                                             B - Bloqueia Pedido
                                             R - Rejeita Produto (não deixa vender)
                                             E - Erro na Procedure
                  po_vMotivoNaoPodeComprar = Descrição do Motivo de não poder comprar
                  po_nQtdeLimite           = Quantidade Limite que pode comprar
  ********************************************************************************/                                       
  PROCEDURE P_VALIDACAO_FINAL_PROD_01(pi_vOrigemChamada        IN  VARCHAR2,
                                      pi_vTipoChamada          IN  VARCHAR2,
                                      pi_vGravarTabTemp        IN  VARCHAR2,
                                      pi_vOrigemPed            IN  VARCHAR2,
                                      pi_vTipoFv               IN  VARCHAR2,
                                      pi_nIntegradora          IN  NUMBER,
                                      pi_vCodFilial            IN  VARCHAR2,
                                      pi_vCodFilialNf          IN  VARCHAR2,
                                      pi_vCodFilialRetira      IN  VARCHAR2,
                                      pi_nCodCli               IN  NUMBER,
                                      pi_nNumRegiao            IN  NUMBER,
                                      pi_nCodUsur              IN  NUMBER,
                                      pi_nCodPlPag             IN  NUMBER,
                                      pi_nCodPromocaoMed       IN  NUMBER,
                                      pi_nCodProd              IN  NUMBER,
                                      pi_nQtdeVenda            IN  NUMBER,   
                                      pi_nPercDesc             IN  NUMBER,
                                      pi_nPUnitario            IN  NUMBER,
                                      pi_nNumPed               IN  NUMBER,                                     
                                      pi_nNumSeq               IN  NUMBER,
                                      pi_nPrecoMaxConsum       IN  NUMBER,
                                      po_vTipoRejeicaoProduto  OUT VARCHAR2,
                                      po_vMotivoNaoPodeComprar OUT VARCHAR2,
                                      po_nQtdeLimite           OUT VARCHAR,
                                      pi_nCodDesconto          IN  NUMBER,
                                      pi_vNumLote              IN  VARCHAR,
                                      pi_vNumLotePromocaoMed   IN  VARCHAR,
                                      pi_nPTabela              IN  NUMBER,
                                      pi_nPTabelaMarkup        IN  NUMBER,
                                      pi_nCustoFin             IN  NUMBER)
  IS
  
    -- Chave do Item do Pedido
    TYPE TRecChaveItemPedido           IS RECORD(
         nNUMPED                       PCPEDI.NUMPED%TYPE
       , nCODPROD                      PCPEDI.CODPROD%TYPE
       , nNUMSEQ                       PCPEDI.NUMSEQ%TYPE
         );
    vrChaveItemPedido                  TRecChaveItemPedido;
  
    -- Record com os Dados do Produto
    TYPE TRecProduto                   IS RECORD(
         nCODMARCA                     PCPRODUT.CODMARCA%TYPE
       , vUTILIZAPRECOMAXCONSUMIDOR    PCPRODUT.UTILIZAPRECOMAXCONSUMIDOR%TYPE
       , vPSICOTROPICO                 PCPRODUT.PSICOTROPICO%TYPE
       , vRETINOICO                    PCPRODUT.RETINOICO%TYPE
       , vCONTROLADO                   VARCHAR2(1)
       , vTIPOCONTROLADO               VARCHAR2(100)
       , vESTOQUEPORLOTE               PCPRODUT.ESTOQUEPORLOTE%TYPE
         );
    vrProduto                          TRecProduto;
  
    -- Record com os Dados do Cliente
    TYPE TRecCliente                   IS RECORD(
         vESTENT                       PCCLIENT.ESTENT%TYPE
         );
    vrCliente                          TRecCliente;
      
    -- Record com Parâmetros
    TYPE TRecParamFilial               IS RECORD(
         vUTILIZAPMCUF                 PCPARAMFILIAL.VALOR%TYPE,
         vUTILIZAPRECOFABRICAPORUF     PCPARAMFILIAL.VALOR%TYPE
         );
    vrParamFilial                      TRecParamFilial;
      
    -- Record com os Dados dos Limites de Acréscimo e/ou Desconto
    TYPE TRecLimiteAcrDescMed          IS RECORD(
         nNUMREGIAO                    PCLIMITEACRDESCMED.NUMREGIAO%TYPE
       , nCODMARCA                     PCLIMITEACRDESCMED.CODMARCA%TYPE
       , nCODPROD                      PCLIMITEACRDESCMED.CODPROD%TYPE
       , nCODUSUR                      PCLIMITEACRDESCMED.CODUSUR%TYPE
       , nPERCENTDESCMAX               PCLIMITEACRDESCMED.PERCENTDESCMAX%TYPE
       , nPERCENTACREMAX               PCLIMITEACRDESCMED.PERCENTACREMAX%TYPE
         );
    vrLimiteAcrDescMed                 TRecLimiteAcrDescMed;
    
    -- Flag achou Registro
    vvAchouRegistro                    VARCHAR2(1);
    
    -- Tipo Rejeição
    vvTipoRejeicao                     PCMED_VALIDACAO_GERAL_PRODUTO.TIPOREJEICAO%TYPE; 
    -- Observação da Rejeição
    vvObservacao                       PCMED_VALIDACAO_GERAL_PRODUTO.OBSERVACAO%TYPE;
  
    -- Regra Específica
    vUSAREGRAVALIDARPMC                PCREGRASEXCECAOMED.VALOR%TYPE;
    vIGNORABLOQUEIOVENDACONTR          PCREGRASEXCECAOMED.VALOR%TYPE;
    
    -- Desconto da Promoção
    vnPercDescPromocao                 PCDESCONTO.PERCDESC%TYPE;
    vnPrecoFixoPromocao                PCDESCONTO.PRECOFIXOPROMOCAOMED%TYPE;
    vnPercMarkupPromocao               PCDESCONTO.PERCMARKUPMED%TYPE;
    vnPrecoPromocional                 NUMBER;
    vnPrecoVendaMarkup                 NUMBER;
    vvRegraAlterarDesconto             PCDESCONTO.REGRAALTERARDESCONTO%TYPE;        
    vvMsgUsoPromocao                   VARCHAR2(250);
    vbPodeVender                       BOOLEAN;
    
    -- Controle de Filial
    vvFilialExistente                  VARCHAR2(1);
    
    -- Tipo de Promoção
    vvTipoPromocao                     PCPROMOCAOMED.TIPOPROMOCAO%TYPE;    
    -- Saldo Disponível da Promoção por Lote
    vnSaldoDispPromocaoLote            NUMBER;
    
    -- Opção da Promocao
    vvTipoPolitica                     PCPROMOCAOMED.TIPOPOLITICA%TYPE;
    vvAlteraDesconto                   PCPROMOCAOMED.ALTERADESCONTO%TYPE;
    
    -- Casas Decimais no Preço de Venda
    vnNumCasasDecVenda                 PCCONSUM.NUMCASASDECVENDA%TYPE;
    
    -- Diferença de Preço
    vnDifPreco                         NUMBER;
    
    -- Código do Motivo de Não Atendimento
    vnCodMotivoNaoAtend                NUMBER;
    
    -- Regras Farma Hospitalar
    vvRestrVendaRegraAltDscPrcPv       PCREGRASEXCECAOMED.VALOR%TYPE;
    vvRestrVendaRegraAltDscPrcFv       PCREGRASEXCECAOMED.VALOR%TYPE;
    vvRestrVendaRegraAltDscPrcEc       PCREGRASEXCECAOMED.VALOR%TYPE;
    
    -- Validação da Cota da Promoção - DDVENDAS-38166
    vvRejeitarVendaCota                VARCHAR2(1);
    vvMsgVendaRejeitadaCota            VARCHAR2(4000);
    vnCotaUtilizadaGeral               NUMBER;
    vnCotaUtilizadaCliente             NUMBER;
  
    ------------------------------------------------------------------------------
    -- Procedimento para Obter o Parâmetro da Filial STRING
    ------------------------------------------------------------------------------
    FUNCTION FOBTEM_PARAMFILIAL_STRING(pi_vCodFilial    IN  VARCHAR2,
                                       pi_vNomeCampo    IN  VARCHAR2,
                                       pi_vValorDefault IN VARCHAR2)
    RETURN VARCHAR2 IS
      -- Retorno
      vvRetValor PCPARAMFILIAL.VALOR%TYPE;                                     
    BEGIN
    
      -- Inicializa Retornos
      vvRetValor := NULL;
  
      -- Pesquisa Parametro
      BEGIN
        SELECT NVL(PCPARAMFILIAL.VALOR,pi_vValorDefault)
          INTO vvRetValor
          FROM PCPARAMFILIAL
         WHERE (PCPARAMFILIAL.CODFILIAL = pi_vCodFilial)
           AND (PCPARAMFILIAL.NOME      = pi_vNomeCampo);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvRetValor := pi_vValorDefault;
      END;
      
      -- Retorno
      RETURN vvRetValor;
  
    END FOBTEM_PARAMFILIAL_STRING;
        
  /*******************************************************************************
                     INICIO DO PROCESSAMENTO PRINCIPAL
   *******************************************************************************/  
  BEGIN
  
    -- Inicializa Retornos
    po_vTipoRejeicaoProduto   := 'N';
    po_vMotivoNaoPodeComprar  := NULL;
    po_nQtdeLimite            := NULL; -->> Começar com NULL
    
    -- Limpa Tabela Temporária
    IF (pi_vGravarTabTemp = 'S') THEN
      DELETE FROM PCMED_VALIDACAO_GERAL_PRODUTO;
    END IF;
    
    -- Define Chave do Item do Pedido
    IF (NVL(pi_nNumPed,0) > 0) THEN
      vrChaveItemPedido.nNUMPED := pi_nNumPed;
    ELSE
      vrChaveItemPedido.nNUMPED := NULL;
    END IF;
    --
    vrChaveItemPedido.nCODPROD := pi_nCodProd;
    --
    IF (NVL(pi_nNumSeq,0) > 0) THEN
      vrChaveItemPedido.nNUMSEQ := pi_nNumSeq;
    ELSE
      vrChaveItemPedido.nNUMSEQ := NULL;
    END IF;
  
   /*******************************************************************************
    PESQUISA DADOS CADASTRAIS
    *************************/  
    
    -- Pesquisa Dados do Produto
    BEGIN
      SELECT PCPRODUT.CODMARCA
           , PCPRODUT.UTILIZAPRECOMAXCONSUMIDOR         
           , PCPRODUT.PSICOTROPICO
           , PCPRODUT.RETINOICO
           , PCPRODUT.ESTOQUEPORLOTE
        INTO vrProduto.nCODMARCA
           , vrProduto.vUTILIZAPRECOMAXCONSUMIDOR
           , vrProduto.vPSICOTROPICO
           , vrProduto.vRETINOICO
           , vrProduto.vESTOQUEPORLOTE
        FROM PCPRODUT
       WHERE (PCPRODUT.CODPROD = pi_nCodProd);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vrProduto.nCODMARCA                  := NULL;
        vrProduto.vUTILIZAPRECOMAXCONSUMIDOR := NULL;
        vrProduto.vPSICOTROPICO              := NULL;
        vrProduto.vRETINOICO                 := NULL;
        vrProduto.vESTOQUEPORLOTE            := NULL;
    END;
  
    -- Define se Produto Controlado
    vrProduto.vCONTROLADO     := 'N';
    vrProduto.vTIPOCONTROLADO := NULL;
    IF    (NVL(vrProduto.vPSICOTROPICO,'N') = 'S') AND
          (NVL(vrProduto.vRETINOICO,'N')    = 'S') THEN
      vrProduto.vCONTROLADO     := 'S';
      vrProduto.vTIPOCONTROLADO := 'Psicotrópico e Retinóico';
    ELSIF (NVL(vrProduto.vPSICOTROPICO,'N') = 'S') THEN
      vrProduto.vCONTROLADO     := 'S';
      vrProduto.vTIPOCONTROLADO := 'Psicotrópico';
    ELSIF (NVL(vrProduto.vRETINOICO,'N') = 'S')    THEN
      vrProduto.vCONTROLADO     := 'S';
      vrProduto.vTIPOCONTROLADO := 'Retinóico';
    END IF;
    
    -- Pesquisa Dados do Cliente
    BEGIN
      SELECT PCCLIENT.ESTENT
        INTO vrCliente.vESTENT
        FROM PCCLIENT
       WHERE (PCCLIENT.CODCLI = pi_nCodCli);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vrCliente.vESTENT := NULL;
    END;
    
    -- Pesquisa o Cadastro da Promoção
    IF (pi_nCodPromocaoMed > 0) THEN
      BEGIN
        SELECT TIPOPROMOCAO
             , TIPOPOLITICA
             , ALTERADESCONTO
          INTO vvTipoPromocao
             , vvTipoPolitica
             , vvAlteraDesconto
          FROM PCPROMOCAOMED
         WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvTipoPromocao   := NULL;
          vvTipoPolitica   := NULL;
          vvAlteraDesconto := 'N';
      END;
    ELSE
      vvTipoPromocao   := NULL;
      vvTipoPolitica   := NULL;
      vvAlteraDesconto := 'N';
    END IF;

    -- Pesquisa Dados de Desconto e Preço da Promoção
    IF (pi_nCodPromocaoMed > 0) AND
       (pi_nCodDesconto    > 0) THEN
      BEGIN
        SELECT PCDESCONTO.PERCDESC  
             , PCDESCONTO.PRECOFIXOPROMOCAOMED 
             , PCDESCONTO.PERCMARKUPMED     
             , PCDESCONTO.REGRAALTERARDESCONTO  
          INTO vnPercDescPromocao
             , vnPrecoFixoPromocao
             , vnPercMarkupPromocao
             , vvRegraAlterarDesconto
          FROM PCDESCONTO
         WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
           AND (CODDESCONTO    = pi_nCodDesconto)
           AND (ROWNUM         = 1);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnPercDescPromocao     := 0;
          vnPrecoFixoPromocao    := 0;
          vnPercMarkupPromocao   := 0;
          vvRegraAlterarDesconto := 'N';
      END;
      IF (NVL(vvRegraAlterarDesconto,'N') = 'P') THEN
        vvRegraAlterarDesconto := vvAlteraDesconto;
      END IF;
    ELSE
      vnPercDescPromocao     := 0;
      vnPrecoFixoPromocao    := 0;
      vnPercMarkupPromocao   := 0;
      vvRegraAlterarDesconto := 'N';
    END IF;   
    
    -- Pesquisa as Casas Decimais no Preço de Venda
    BEGIN
      SELECT PCCONSUM.NUMCASASDECVENDA
        INTO vnNumCasasDecVenda
        FROM PCCONSUM;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnNumCasasDecVenda := 2;
    END;
  
   /*******************************************************************************
    VALIDAÇÃO DOS TETOS DE DESCONTO E/OU ACRÉSCIMO
    **********************************************/  
    
    vvAchouRegistro := 'N';
    
    -- Se não for OL/PE ou E-Commerce
    IF NOT ( (NVL(pi_vTipoFv,'FV') IN ('OL','PE')) OR
             (NVL(pi_vOrigemPed,'F') IN ('W')) )   THEN
     
     -- Se não for Combo
     IF (NVL(pi_vOrigemChamada,'X') NOT IN ('C')) THEN
             
      -- Verifica se existe algum Teto de Acréscimo
      IF     (NVL(pi_nPercDesc,0) < 0) THEN  
        BEGIN
          SELECT 'S' ACHOUREGISTRO
               , PCLIMITEACRDESCMED.NUMREGIAO
               , PCLIMITEACRDESCMED.CODMARCA
               , PCLIMITEACRDESCMED.CODPROD
               , PCLIMITEACRDESCMED.CODUSUR
               , PCLIMITEACRDESCMED.PERCENTDESCMAX
               , PCLIMITEACRDESCMED.PERCENTACREMAX
            INTO vvAchouRegistro
               , vrLimiteAcrDescMed.nNUMREGIAO
               , vrLimiteAcrDescMed.nCODMARCA
               , vrLimiteAcrDescMed.nCODPROD
               , vrLimiteAcrDescMed.nCODUSUR
               , vrLimiteAcrDescMed.nPERCENTDESCMAX
               , vrLimiteAcrDescMed.nPERCENTACREMAX
            FROM PCLIMITEACRDESCMED
           WHERE ((PCLIMITEACRDESCMED.NUMREGIAO             = pi_nNumRegiao)       OR (PCLIMITEACRDESCMED.NUMREGIAO      IS NULL))
             AND ((PCLIMITEACRDESCMED.CODMARCA              = vrProduto.nCODMARCA) OR (PCLIMITEACRDESCMED.CODMARCA       IS NULL))
             AND ((PCLIMITEACRDESCMED.CODPROD               = pi_nCodProd)         OR (PCLIMITEACRDESCMED.CODPROD        IS NULL))
             AND ((PCLIMITEACRDESCMED.CODUSUR               = pi_nCodUsur)         OR (PCLIMITEACRDESCMED.CODUSUR        IS NULL))
             AND ((PCLIMITEACRDESCMED.PERCENTACREMAX * -1) > TRUNC(NVL(pi_nPercDesc,0),2)) -->> Desconto Inferior ao Teto (Acréscimo = Desconto Negativo no Pedido)
             AND (ROWNUM = 1);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvAchouRegistro := 'N';
        END;
      -- Verifica se existe algum Teto de Desconto
      ELSIF (NVL(pi_nPercDesc,0) > 0) THEN
        BEGIN
          SELECT 'S' ACHOUREGISTRO
               , PCLIMITEACRDESCMED.NUMREGIAO
               , PCLIMITEACRDESCMED.CODMARCA
               , PCLIMITEACRDESCMED.CODPROD
               , PCLIMITEACRDESCMED.CODUSUR
               , PCLIMITEACRDESCMED.PERCENTDESCMAX
               , PCLIMITEACRDESCMED.PERCENTACREMAX
            INTO vvAchouRegistro
               , vrLimiteAcrDescMed.nNUMREGIAO
               , vrLimiteAcrDescMed.nCODMARCA
               , vrLimiteAcrDescMed.nCODPROD
               , vrLimiteAcrDescMed.nCODUSUR
               , vrLimiteAcrDescMed.nPERCENTDESCMAX
               , vrLimiteAcrDescMed.nPERCENTACREMAX
            FROM PCLIMITEACRDESCMED
           WHERE ((PCLIMITEACRDESCMED.NUMREGIAO     = pi_nNumRegiao)       OR (PCLIMITEACRDESCMED.NUMREGIAO      IS NULL))
             AND ((PCLIMITEACRDESCMED.CODMARCA      = vrProduto.nCODMARCA) OR (PCLIMITEACRDESCMED.CODMARCA       IS NULL))
             AND ((PCLIMITEACRDESCMED.CODPROD       = pi_nCodProd)         OR (PCLIMITEACRDESCMED.CODPROD        IS NULL))
             AND ((PCLIMITEACRDESCMED.CODUSUR       = pi_nCodUsur)         OR (PCLIMITEACRDESCMED.CODUSUR        IS NULL))
             AND (PCLIMITEACRDESCMED.PERCENTDESCMAX < TRUNC(NVL(pi_nPercDesc,0),2)) -->> Desconto Superior ao Teto -- MED-1238 - Truncar 2 casas decimais
             AND (ROWNUM = 1);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvAchouRegistro := 'N';
        END;
      END IF;
        
      -- Se encontrou algum Teto
      IF (vvAchouRegistro = 'S') THEN
      
        -- Inicializa Mensagem de Uso da Promoção
        vvMsgUsoPromocao := NULL;
        vbPodeVender     := FALSE;
        
        -- Verifica se selecionou uma Promoção
        IF (pi_nCodPromocaoMed > 0) AND
           (pi_nCodDesconto    > 0) THEN
          -- Pesquisa Percentual de Desconto
          BEGIN
            SELECT PCDESCONTO.PERCDESC          
              INTO vnPercDescPromocao
              FROM PCDESCONTO
             WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
               AND (CODDESCONTO    = pi_nCodDesconto)
               AND (ROWNUM         = 1);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vnPercDescPromocao := 0;
          END;
          -- Se achou um Desconto
          IF    (vnPercDescPromocao > 0) THEN
            -- Se desconto da promoção maior que o desconto máximo
            IF (NVL(vnPercDescPromocao,0) > NVL(vrLimiteAcrDescMed.nPERCENTDESCMAX,0)) THEN
              vrLimiteAcrDescMed.nPERCENTDESCMAX := vnPercDescPromocao;
              vvMsgUsoPromocao := ' Promoção: ' || NVL(pi_nCodPromocaoMed,0);
              -- Se não atingiu o Limite que agora é o Desconto da Promoção
              IF (TRUNC(pi_nPercDesc,2) <= vrLimiteAcrDescMed.nPERCENTDESCMAX) THEN
                vbPodeVender := TRUE;
              END IF;
            END IF;
          -- Se achou um Acréscimo
          ELSIF (vnPercDescPromocao < 0) THEN
            -- Se acréscimo da promoção (USAR ABS()) maior que o desconto máximo
            IF (ABS(NVL(vnPercDescPromocao,0)) > NVL(vrLimiteAcrDescMed.nPERCENTACREMAX,0)) THEN
              vrLimiteAcrDescMed.nPERCENTACREMAX := ABS(NVL(vnPercDescPromocao,0));
              vvMsgUsoPromocao := ' Promoção: ' || NVL(pi_nCodPromocaoMed,0);
              -- Se não atingiu o Limite que agora é o Acréscimo da Promoção
              IF (ABS(TRUNC(pi_nPercDesc,2)) <= vrLimiteAcrDescMed.nPERCENTACREMAX) THEN
                vbPodeVender := TRUE;
              END IF;
            END IF;          
          END IF;
        END IF;
      
        -- Se continua sem Poder Vender (Promoção não interferiu na Validação)
        IF (NOT vbPodeVender) THEN
      
          -- Observação da Rejeição
          vvObservacao := 'Limite:';
          IF (vrLimiteAcrDescMed.nNUMREGIAO IS NOT NULL) THEN
            vvObservacao := vvObservacao || ' Região: '  || vrLimiteAcrDescMed.nNUMREGIAO      || ' /';
          END IF;
          IF (vrLimiteAcrDescMed.nCODMARCA IS NOT NULL) THEN
            vvObservacao := vvObservacao || ' Marca: '   || vrLimiteAcrDescMed.nCODMARCA       || ' /';
          END IF;
          IF (vrLimiteAcrDescMed.nCODPROD IS NOT NULL) THEN
            vvObservacao := vvObservacao || ' Produto: ' || vrLimiteAcrDescMed.nCODPROD        || ' /';
          END IF;
          IF (vrLimiteAcrDescMed.nCODUSUR IS NOT NULL) THEN
            vvObservacao := vvObservacao || ' RCA: '     || vrLimiteAcrDescMed.nCODUSUR        || ' /';
          END IF;
          IF (vvMsgUsoPromocao IS NOT NULL) THEN
            vvObservacao := vvObservacao || vvMsgUsoPromocao                                   || ' /';
          END IF;
    
          -- Se Acréscimo
          IF     (TRUNC(NVL(pi_nPercDesc,0),2) < 0) THEN  
            IF (vrLimiteAcrDescMed.nPERCENTACREMAX IS NOT NULL) THEN
              vvObservacao := vvObservacao || ' % Acrésc. Máximo.: ' || vrLimiteAcrDescMed.nPERCENTACREMAX || ' /';
            END IF;    
          -- Se Desconto
          ELSIF (TRUNC(NVL(pi_nPercDesc,0),2) > 0) THEN
            IF (vrLimiteAcrDescMed.nPERCENTDESCMAX IS NOT NULL) THEN
              vvObservacao := vvObservacao || ' % Desc. Máximo: '    || vrLimiteAcrDescMed.nPERCENTDESCMAX || ' /';
            END IF;
          END IF;
    
          vvObservacao := vvObservacao || ' % Desc. Concedido: ' || TRUNC(NVL(pi_nPercDesc,0),2) || ' /';
    
          vvObservacao := SUBSTR(vvObservacao,1,LENGTH(vvObservacao)-1); -- Retira a última '/'
        
          -- Se Grava Tabela Temporária    
          IF (pi_vGravarTabTemp = 'S') THEN
          
            -- No Força de Vendas grava como Bloqueado
            IF (pi_vOrigemPed = 'F') AND
               (NVL(pi_vTipoFv,'FV') NOT IN ('OL','PE')) THEN
              vvTipoRejeicao := 'B';
            ELSE
              vvTipoRejeicao := 'R';
            END IF;
          
            INSERT INTO PCMED_VALIDACAO_GERAL_PRODUTO
                      ( NUMPED
                      , CODPROD
                      , NUMSEQ
                      , CODREJEICAO
                      , TIPOREJEICAO
                      , CODMOTIVONAOATEND
                      , DESCRICAOREJEICAO
                      , CODROTINA
                      , OBSERVACAO )
               VALUES ( vrChaveItemPedido.nNUMPED
                      , vrChaveItemPedido.nCODPROD
                      , vrChaveItemPedido.nNUMSEQ
                      , 1
                      , vvTipoRejeicao
                      , 26
                      , 'Limite de Acréscimo e Desconto'
                      , 2349
                      , vvObservacao ); 
          END IF;
          
          -- Motivo de Retorno = Rejeição
          po_vTipoRejeicaoProduto := 'R';
          
          -- Observação de Retorno
          IF (po_vMotivoNaoPodeComprar IS NOT NULL) THEN
            po_vMotivoNaoPodeComprar := po_vMotivoNaoPodeComprar || '; ';
          END IF;
          po_vMotivoNaoPodeComprar :=  po_vMotivoNaoPodeComprar || vvObservacao;
          
        END IF; -- Fim Condição: Promoção Permitiu Vender
      
      END IF; -- Fim Condição Se encontrou algum Teto
    
     END IF; -- Fim Condição: Se não for Combo
     
    END IF; -- Fim Condição para Validar Tetos
    
   /*******************************************************************************
    VALIDAÇÃO DO PRECO MÁXIMO DO CONSUMIDOR - HIS.01765.2016
    ********************************************************/
    
    -- Se Utiliza Preço Máximo do Consumidor
    IF (vrProduto.vUTILIZAPRECOMAXCONSUMIDOR = 'S') THEN
  
     -- Se não for Combo
     IF (NVL(pi_vOrigemChamada,'X') NOT IN ('C')) THEN
    
      -- Se não possui PMC
      IF (NVL(pi_nPrecoMaxConsum,0) <= 0) THEN
      
        -- Regra Específica
        BEGIN
          SELECT VALOR
            INTO vUSAREGRAVALIDARPMC                
            FROM PCREGRASEXCECAOMED
           WHERE (CODFILIAL = '99')         
             AND (NOME      = 'USAREGRAVALIDARPMC');
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vUSAREGRAVALIDARPMC := 'N';
        END;
       
       -- Se Usa Regra Específica Validar PMC
       IF (vUSAREGRAVALIDARPMC = 'S') THEN
      
          -- Pesquisa Parâmetros
          vrParamFilial.vUTILIZAPMCUF             := FOBTEM_PARAMFILIAL_STRING('99',
                                                                               'UTILIZAPMCUF',
                                                                               'N');
          vrParamFilial.vUTILIZAPRECOFABRICAPORUF := FOBTEM_PARAMFILIAL_STRING('99',
                                                                               'UTILIZAPRECOFABRICAPORUF',
                                                                               'N');
        
          -- Mensagem conforme parametrização
          IF (NVL(vrParamFilial.vUTILIZAPMCUF,'N')             = 'S') OR
             (NVL(vrParamFilial.vUTILIZAPRECOFABRICAPORUF,'N') = 'S') THEN
            vvObservacao := 'Produto sem PMC na UF do Cliente "' || NVL(vrCliente.vESTENT,' ') || '"';
          ELSE
            vvObservacao := 'Produto sem PMC no Produto';
          END IF;
        
          -- Se Grava Tabela Temporária    
          IF (pi_vGravarTabTemp = 'S') THEN
                
            INSERT INTO PCMED_VALIDACAO_GERAL_PRODUTO
                      ( NUMPED
                      , CODPROD
                      , NUMSEQ
                      , CODREJEICAO
                      , TIPOREJEICAO
                      , CODMOTIVONAOATEND
                      , DESCRICAOREJEICAO
                      , CODROTINA
                      , OBSERVACAO )
               VALUES ( vrChaveItemPedido.nNUMPED
                      , vrChaveItemPedido.nCODPROD
                      , vrChaveItemPedido.nNUMSEQ
                      , 2
                      , 'R' -->> Rejeição
                      , 21  -->> Produto sem Preço
                      , 'Preço Máximo Consumidor'
                      , 2301
                      , vvObservacao ); 
          END IF;
          
          -- Motivo de Retorno = Rejeição
          po_vTipoRejeicaoProduto := 'R';
          
          -- Observação de Retorno
          IF (po_vMotivoNaoPodeComprar IS NOT NULL) THEN
            po_vMotivoNaoPodeComprar := po_vMotivoNaoPodeComprar || '; ';
          END IF;
          po_vMotivoNaoPodeComprar :=  po_vMotivoNaoPodeComprar || vvObservacao;
          
        END IF; -- Fim Condição Usa Regra Específica Validar PMC
        
      END IF; -- Fim Condição Se não possui PMC
    
     END IF; -- Fim Condição: Se não for Combo
    
    END IF; -- Fim Condição: -- Se Utiliza Preço Máximo do Consumidor
    
   /*******************************************************************************
    VALIDAÇÃO FILIAL RETIRA x PRODUTOS CONTROLADOS - DDMEDICA-735
    *************************************************************/  
    IF (vrProduto.vCONTROLADO = 'S') THEN
    
      -- Verifica se Filial Retira Válida
      BEGIN
        SELECT 'S'
          INTO vvFilialExistente
          FROM PCFILIAL
         WHERE (CODIGO = pi_vCodFilialRetira);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvFilialExistente := 'N';
      END;
      
      --DDMEDICA-1345
      -- Regra Específica
      BEGIN
        SELECT VALOR
          INTO vIGNORABLOQUEIOVENDACONTR
          FROM PCREGRASEXCECAOMED
         WHERE (CODFILIAL = '99')
           AND (NOME      = 'IGNORABLOQUEIOVENDACONTR');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vIGNORABLOQUEIOVENDACONTR := 'N';
      END;
      
      -- Se Filial Retira Válida
      IF (vvFilialExistente = 'S') and (vIGNORABLOQUEIOVENDACONTR = 'N') THEN
      
        -- Verifica se a Filial Retira é diferente da Filial do Pedido
        IF (pi_vCodFilial <> pi_vCodFilialRetira) THEN
    
          vvObservacao := 'Produto ' || vrProduto.vTIPOCONTROLADO || '. Venda não permitida para Filial Retira.'; 
        
          -- Se Grava Tabela Temporária    
          IF (pi_vGravarTabTemp = 'S') THEN
        
            INSERT INTO PCMED_VALIDACAO_GERAL_PRODUTO
                      ( NUMPED
                      , CODPROD
                      , NUMSEQ
                      , CODREJEICAO
                      , TIPOREJEICAO
                      , CODMOTIVONAOATEND
                      , DESCRICAOREJEICAO
                      , CODROTINA
                      , OBSERVACAO )
               VALUES ( vrChaveItemPedido.nNUMPED
                      , vrChaveItemPedido.nCODPROD
                      , vrChaveItemPedido.nNUMSEQ
                      , 3
                      , 'R' -->> Rejeição
                      , 16  -->> Restrição Venda 
                      , 'Bloqueio Venda Controlados - Fil.Retira'
                      , 203
                      , vvObservacao ); 
          END IF;
          
          -- Motivo de Retorno = Rejeição
          po_vTipoRejeicaoProduto := 'R';
          
          -- Observação de Retorno
          IF (po_vMotivoNaoPodeComprar IS NOT NULL) THEN
            po_vMotivoNaoPodeComprar := po_vMotivoNaoPodeComprar || '; ';
          END IF;
          po_vMotivoNaoPodeComprar :=  po_vMotivoNaoPodeComprar || vvObservacao;
        
        END IF; -- Fim: Se a Filial Retira é diferente da Filial do Pedido
        
      END IF; -- Fim Condição: Se Filial Retira Válida
      
    END IF; -- FIM:  VALIDAÇÃO FILIAL RETIRA x PRODUTOS CONTROLADOS - DDMEDICA-735
  
   /*******************************************************************************
    VALIDAÇÃO FILIAL VIRTUAL x PRODUTOS CONTROLADOS - DDMEDICA-735
    **************************************************************/  
    IF (vrProduto.vCONTROLADO = 'S') THEN
    
      -- Verifica se Filial NF Válida
      BEGIN
        SELECT 'S'
          INTO vvFilialExistente
          FROM PCFILIAL
         WHERE (CODIGO = pi_vCodFilialNf);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvFilialExistente := 'N';
      END;
      
      --DDMEDICA-1345
      -- Regra Específica
      BEGIN
        SELECT VALOR
          INTO vIGNORABLOQUEIOVENDACONTR
          FROM PCREGRASEXCECAOMED
         WHERE (CODFILIAL = '99')
           AND (NOME      = 'IGNORABLOQUEIOVENDACONTR');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vIGNORABLOQUEIOVENDACONTR := 'N';
      END;
      
      -- Se Filial NF Válida
      IF (vvFilialExistente = 'S') and (vIGNORABLOQUEIOVENDACONTR = 'N') THEN
      
        -- Verifica se a Filial Virtual é diferente da Filial do Pedido
        IF (pi_vCodFilial <> pi_vCodFilialNf) THEN
    
          vvObservacao := 'Produto ' || vrProduto.vTIPOCONTROLADO || '. Venda não permitida para Filial Virtual.'; 
        
          -- Se Grava Tabela Temporária    
          IF (pi_vGravarTabTemp = 'S') THEN
        
            INSERT INTO PCMED_VALIDACAO_GERAL_PRODUTO
                      ( NUMPED
                      , CODPROD
                      , NUMSEQ
                      , CODREJEICAO
                      , TIPOREJEICAO
                      , CODMOTIVONAOATEND
                      , DESCRICAOREJEICAO
                      , CODROTINA
                      , OBSERVACAO )
               VALUES ( vrChaveItemPedido.nNUMPED
                      , vrChaveItemPedido.nCODPROD
                      , vrChaveItemPedido.nNUMSEQ
                      , 4
                      , 'R' -->> Rejeição
                      , 16  -->> Restrição Venda 
                      , 'Bloqueio Venda Controlados - Fil.Virtual'
                      , 203
                      , vvObservacao ); 
          END IF;
          
          -- Motivo de Retorno = Rejeição
          po_vTipoRejeicaoProduto := 'R';
          
          -- Observação de Retorno
          IF (po_vMotivoNaoPodeComprar IS NOT NULL) THEN
            po_vMotivoNaoPodeComprar := po_vMotivoNaoPodeComprar || '; ';
          END IF;
          po_vMotivoNaoPodeComprar :=  po_vMotivoNaoPodeComprar || vvObservacao;
        
        END IF; -- Fim: Se a Filial Virtual é diferente da Filial do Pedido
        
      END IF; -- Fim Condição: Se Filial Virtual Válida
      
    END IF; -- FIM:  VALIDAÇÃO FILIAL VIRTUAL x PRODUTOS CONTROLADOS - DDMEDICA-735
    
   /*******************************************************************************
    VALIDAÇÃO PROMOÇÃO POR LOTE - DDMEDICA-1495
    *******************************************/
    IF (NVL(pi_nCodPromocaoMed,0) > 0) THEN
      
      -- Se Promoção por Lote
      IF (vvTipoPromocao = 'L') THEN
 
        -- Inicializa Mensagem 
        vvObservacao := NULL;
        
        -- Se o Produto não controla estoque por lote
        IF (NVL(vrProduto.vESTOQUEPORLOTE,'N') <> 'S') THEN
        
          -- Mensagem 
          vvObservacao := 'Este produto não controla estoque por lote. Não pode ser vendido nesta promoção.';
        
        ELSE
        
          -- Busca Estoque por Lote
          BEGIN
            SELECT QT - GREATEST(NVL(QTRESERV,0),0) - GREATEST(NVL(QTBLOQUEADA,0),0)
              INTO vnSaldoDispPromocaoLote
              FROM PCLOTE
             WHERE (CODPROD   = pi_nCodProd)
               AND (CODFILIAL = NVL(pi_vCodFilialRetira,pi_vCodFilial))
               AND (NUMLOTE   = pi_vNumLotePromocaoMed);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vnSaldoDispPromocaoLote := 0;
          END;                        
                  
          -- Se Quantidade Vendida superior Estoque por Lote da Promoção
          IF (NVL(pi_nQtdeVenda,0) > NVL(vnSaldoDispPromocaoLote,0)) THEN
          
            -- Mensagem 
            vvObservacao := 'Quantidade vendida: ' || F_FORMATAR_NUMERO_PARA_TEXTO(pi_nQtdeVenda,0) ||
                            ' superior ao estoque do lote "' || pi_vNumLotePromocaoMed || '" disponível para venda: ' || F_FORMATAR_NUMERO_PARA_TEXTO(vnSaldoDispPromocaoLote,0);
          
          ELSE    
                         
            -- Busca Saldo Disponível da Cota da Promoção
            P_VALIDAR_OBTER_LOTES_PRODUTO('PL', -- Promoção por Lote
                                          2,    -- Validar Saldo ao confirmar o produto e o lote
                                          NULL, -- pi_nNumTransEnt
                                          pi_nNumPed,
                                          pi_nCodProd,
                                          pi_nNumSeq,
                                          pi_vNumLotePromocaoMed, -- Lote da Indução
                                          NVL(pi_vCodFilialRetira,pi_vCodFilial),
                                          pi_nCodPromocaoMed,
                                          vnSaldoDispPromocaoLote);  
                                 
            -- Se Quantidade Vendida superior à Cota da Promoção por Lote
            IF (NVL(pi_nQtdeVenda,0) > NVL(vnSaldoDispPromocaoLote,0)) THEN    
            
              -- Mensagem 
              vvObservacao := 'Quantidade vendida: ' || F_FORMATAR_NUMERO_PARA_TEXTO(pi_nQtdeVenda,0) ||
                              ' superior à cota do lote "' || pi_vNumLotePromocaoMed || '" disponível para venda: ' || F_FORMATAR_NUMERO_PARA_TEXTO(vnSaldoDispPromocaoLote,0);
                              
            END IF;
            
          END IF;
          
          -- Se Excedeu o Limite
          IF (vvObservacao IS NOT NULL) THEN
        
            -- Se Grava Tabela Temporária    
            IF (pi_vGravarTabTemp = 'S') THEN
                  
              INSERT INTO PCMED_VALIDACAO_GERAL_PRODUTO
                        ( NUMPED
                        , CODPROD
                        , NUMSEQ
                        , CODREJEICAO
                        , TIPOREJEICAO
                        , CODMOTIVONAOATEND
                        , DESCRICAOREJEICAO
                        , CODROTINA
                        , OBSERVACAO )
                 VALUES ( vrChaveItemPedido.nNUMPED
                        , vrChaveItemPedido.nCODPROD
                        , vrChaveItemPedido.nNUMSEQ
                        , 5
                        , 'R' -->> Rejeição
                        , 16  -->> Restrição de Venda
                        , 'Cota de Promoção por Lote'
                        , 2323
                        , vvObservacao ); 
            END IF;
            
            -- Motivo de Retorno = Rejeição
            po_vTipoRejeicaoProduto := 'R';
            
            -- Observação de Retorno
            IF (po_vMotivoNaoPodeComprar IS NOT NULL) THEN
              po_vMotivoNaoPodeComprar := po_vMotivoNaoPodeComprar || '; ';
            END IF;
            po_vMotivoNaoPodeComprar :=  po_vMotivoNaoPodeComprar || vvObservacao;
  
          END IF; -- Fim Condição: Se Excedeu o Limite
               
        END IF; -- Fim Condição: Se o Produto não controla estoque por lote
 
      END IF; -- Fim Condição: Se Promoção por Lote
      
    END IF; -- FIM:  VALIDAÇÃO PROMOÇÃO POR LOTE - DDMEDICA-1495

   /*******************************************************************************
    VALIDAÇÃO REGRA ALTERAÇÃO PREÇO/DESCONTO - DDVENDAS-35576
    *********************************************************/
    IF (NVL(pi_vTipoFv,'FV') NOT IN ('OL','PE')) AND
       (NVL(pi_nCodPromocaoMed,0) > 0)           AND
       (vvTipoPromocao NOT IN ('K','E','S','N','B')) AND
       (vvTipoPolitica IN ('D','Q','M','P','F')) AND
       (NVL(pi_nPTabela,0) > 0)                  THEN
    
      -- Regras Farma Hospitalar
      vvRestrVendaRegraAltDscPrcPv := FUSA_REGRA_MEDICAMENTOS('99','RESTRVENDAREGRAALTDSCPRCPV');
      vvRestrVendaRegraAltDscPrcFv := FUSA_REGRA_MEDICAMENTOS('99','RESTRVENDAREGRAALTDSCPRCFV');
      vvRestrVendaRegraAltDscPrcEc := FUSA_REGRA_MEDICAMENTOS('99','RESTRVENDAREGRAALTDSCPRCEC');
      
      -- Se a Origem do Pedido Restringe a Venda
      IF (NVL(pi_vOrigemPed,'T') NOT IN ('F','W')) AND (NVL(vvRestrVendaRegraAltDscPrcPv,'N') = 'S') OR
         (NVL(pi_vOrigemPed,'T') = 'F') AND (NVL(vvRestrVendaRegraAltDscPrcFv,'N') = 'S') OR
         (NVL(pi_vOrigemPed,'T') = 'W') AND (NVL(vvRestrVendaRegraAltDscPrcEc,'N') = 'S') THEN
    
        --- Markup
        IF (vvTipoPromocao = 'R') THEN
          IF (NVL(vnPercMarkupPromocao,0) = 0) THEN
            vnPercDescPromocao       := 0;
          ELSIF (NVL(pi_nPtabelaMarkup,0) = 0) THEN
            vnPercDescPromocao       := 0;
          ELSE
              IF (NVL(pi_nCustoFin,0) = 0) THEN
                vnPercDescPromocao   := 0;
              ELSE
                vnPrecoVendaMarkup   := pi_nCustoFin * (1+(NVL(vnPercMarkupPromocao,0) * 0.01));
                vnPercDescPromocao   := (1-(vnPrecoVendaMarkup/NVL(pi_nPTabelaMarkup,0)))*100;
              END IF;
          END IF;
        END IF;
        -- Markup com Preço Fixo
        IF (vvTipoPromocao = 'R') AND
           (vvTipoPolitica IN ('P','F')) THEN
          IF (NVL(vnPercDescPromocao,0) = 0) THEN
            vnPrecoFixoPromocao := NVL(pi_nPTabelaMarkup,0);
          ELSE                         
            vnPrecoFixoPromocao := NVL(vnPrecoVendaMarkup,0);
          END IF;
          -- Não tem desconto (já vai aplicado no Preço Fixo)
          vnPercDescPromocao := 0;
        END IF;
        
        -- Diferença de Preço                      
        vnDifPreco := 0;
        IF (vvTipoPolitica IN ('P','F')) THEN
          vnPrecoPromocional  := NVL(vnPrecoFixoPromocao,0);
          vnDifPreco          := ROUND((NVL(vnPrecoPromocional,0) - NVL(pi_nPUnitario,0)), 2);
          vnCodMotivoNaoAtend := 26;
        ELSE
          vnPrecoPromocional  := ROUND(NVL(pi_nPtabela,0) * (1 - (NVL(vnPercDescPromocao,0) / 100)), vnNumCasasDecVenda);
          vnDifPreco          := ROUND((NVL(vnPrecoPromocional,0) - NVL(pi_nPUnitario,0)), 2);
          vnCodMotivoNaoAtend := 27;
        END IF;
        
        vvObservacao := NULL;
        
        -- Regra não altera desconto/preço
        IF    (vvRegraAlterarDesconto = 'N') THEN
          IF    (ABS(vnDifPreco) > 0.01) THEN
            vvObservacao := 'Promoção "' || pi_nCodPromocaoMed || '" sem permissão para alteração de deconto/preço. Preço líquido permitido: ' || F_FORMATAR_NUMERO_PARA_TEXTO(vnPrecoPromocional,vnNumCasasDecVenda) ||
                            ' / Preço líquido concedido ' || F_FORMATAR_NUMERO_PARA_TEXTO(pi_nPUnitario,vnNumCasasDecVenda);
          END IF;      
        -- Regra altera desconto/preço para cima (preço líquido maior que o cadastrado)
        ELSIF (vvRegraAlterarDesconto = 'C') THEN
          IF    (vnDifPreco > 0.01) THEN
            vvObservacao := 'Promoção "' || pi_nCodPromocaoMed || '" somente com permissão para conceder preço líquido maior que o cadastrado. Preço líquido permitido: ' || F_FORMATAR_NUMERO_PARA_TEXTO(vnPrecoPromocional,vnNumCasasDecVenda) ||
                            ' / Preço líquido concedido ' || F_FORMATAR_NUMERO_PARA_TEXTO(pi_nPUnitario,vnNumCasasDecVenda);
          END IF;      
        -- Regra altera desconto/preço para baixo (preço líquido menor que o cadastrado)
        ELSIF (vvRegraAlterarDesconto = 'B') THEN
          IF    (vnDifPreco < -0.01) THEN
            vvObservacao := 'Promoção "' || pi_nCodPromocaoMed || '" somente com permissão para conceder preço líquido menor que o cadastrado. Preço líquido permitido: ' || F_FORMATAR_NUMERO_PARA_TEXTO(vnPrecoPromocional,vnNumCasasDecVenda) ||
                            ' / Preço líquido concedido ' || F_FORMATAR_NUMERO_PARA_TEXTO(pi_nPUnitario,vnNumCasasDecVenda);
          END IF;      
        END IF;
        
        -- Se ocorreram críticas 
        IF (vvObservacao IS NOT NULL) THEN
        
          -- Se Grava Tabela Temporária    
          IF (pi_vGravarTabTemp = 'S') THEN
          
            vvTipoRejeicao := 'R';
          
            INSERT INTO PCMED_VALIDACAO_GERAL_PRODUTO
                      ( NUMPED
                      , CODPROD
                      , NUMSEQ
                      , CODREJEICAO
                      , TIPOREJEICAO
                      , CODMOTIVONAOATEND
                      , DESCRICAOREJEICAO
                      , CODROTINA
                      , OBSERVACAO )
               VALUES ( vrChaveItemPedido.nNUMPED
                      , vrChaveItemPedido.nCODPROD
                      , vrChaveItemPedido.nNUMSEQ
                      , 6
                      , vvTipoRejeicao
                      , vnCodMotivoNaoAtend
                      , 'Regra de Alteração de Desconto/Preço'
                      , 2323
                      , vvObservacao ); 
          END IF;
          
          -- Motivo de Retorno = Rejeição
          po_vTipoRejeicaoProduto := 'R';
          
          -- Observação de Retorno
          IF (po_vMotivoNaoPodeComprar IS NOT NULL) THEN
            po_vMotivoNaoPodeComprar := po_vMotivoNaoPodeComprar || '; ';
          END IF;
          po_vMotivoNaoPodeComprar :=  po_vMotivoNaoPodeComprar || vvObservacao;
          
        END IF;
      
      END IF; -- Fim: Se Restringe Venda
      
    END IF; -- FIM: VALIDAÇÃO REGRA ALTERAÇÃO PREÇO/DESCONTO - DDVENDAS-35576

   /*******************************************************************************
    VALIDAÇÃO COTAS DA PROMOÇÃO - DDVENDAS-38166
    ********************************************/
    IF (NVL(pi_nCodPromocaoMed,0) > 0) THEN
    
      P_VALIDAR_COTAS_PROMOCAO(pi_nNumPed,
                               pi_nCodProd,
                               pi_nNumSeq,
                               pi_nCodPromocaoMed,
                               pi_nCodCli,
                               pi_nPTabela,
                               pi_nPUnitario,
                               pi_nQtdeVenda,
                               vvRejeitarVendaCota,
                               vvMsgVendaRejeitadaCota,
                               vnCotaUtilizadaGeral,
                               vnCotaUtilizadaCliente);    
    
      -- Se ocorreram críticas 
      IF (vvRejeitarVendaCota = 'S') THEN
      
        -- Se Grava Tabela Temporária    
        IF (pi_vGravarTabTemp = 'S') THEN
        
          vvTipoRejeicao      := 'R';
          vnCodMotivoNaoAtend := 16;
        
          INSERT INTO PCMED_VALIDACAO_GERAL_PRODUTO
                    ( NUMPED
                    , CODPROD
                    , NUMSEQ
                    , CODREJEICAO
                    , TIPOREJEICAO
                    , CODMOTIVONAOATEND
                    , DESCRICAOREJEICAO
                    , CODROTINA
                    , OBSERVACAO )
             VALUES ( vrChaveItemPedido.nNUMPED
                    , vrChaveItemPedido.nCODPROD
                    , vrChaveItemPedido.nNUMSEQ
                    , 7
                    , vvTipoRejeicao
                    , vnCodMotivoNaoAtend
                    , 'Cotas da Promoção'
                    , 2323
                    , SUBSTR(vvMsgVendaRejeitadaCota,1,200) ); 
        END IF;
        
        -- Motivo de Retorno = Rejeição
        po_vTipoRejeicaoProduto := 'R';
        
        -- Observação de Retorno
        IF (po_vMotivoNaoPodeComprar IS NOT NULL) THEN
          po_vMotivoNaoPodeComprar := po_vMotivoNaoPodeComprar || '; ';
        END IF;
        po_vMotivoNaoPodeComprar :=  po_vMotivoNaoPodeComprar || vvMsgVendaRejeitadaCota;
        
      END IF;
    
    END IF; -- VALIDAÇÃO COTAS DA PROMOÇÃO - DDVENDAS-38166
    
  EXCEPTION
    WHEN OTHERS THEN  
      po_vMotivoNaoPodeComprar := 'E';
      po_vMotivoNaoPodeComprar := 'Erro na validação final do produto: ' || SQLERRM;
  END P_VALIDACAO_FINAL_PROD_01;

  /*******************************************************************************
   Nome         : FCT_MED_OBTER_ESTOQUE_DISP
   Descricão    : Função para obter o Saldo de Estoque Disponivel
   Parâmetros   : ENTRADA:
                  pi_vCodProd                 = Código do Produto
                  pi_vCodFilial               = Código da Filial
                  pi_nOpcaoLimitarVendaEstMin = Opção de abater o Estoque Mínimo
                                                0 - Não Abater
                                                1 - Abater
   Alteracão    : Anderson Silva - 24/10/2017 - Criação da Função
   Alteracão    : Anderson Silva - 26/04/2019 - Alteração do Parâmetro da Filial
   Alteração    : Anderson Silva - 22/08/2021 - DDMEDICA-7391 - Limitar Venda do Estoque Mínimo 
  ********************************************************************************/
  FUNCTION F_OBTER_ESTOQUE_DISP(pi_vCodProd                 IN NUMBER,
                                pi_vCodFilial               IN VARCHAR2,
                                pi_nOpcaoLimitarVendaEstMin IN NUMBER DEFAULT 0)
  RETURN NUMBER
  IS
  
    -- Versão
    vvVersao       VARCHAR2(250);  
    
    -- Saldo Retorno
    vnSaldoRetorno NUMBER;
    
    -- Estoque Mínimo
    vnEstoqueMin   PCPRODFILIAL.ESTOQUEMIN%TYPE;
  
  BEGIN
  
    -- Inicializa Retorno
    vnSaldoRetorno := 0;
    
    -- Força a Recompilação da Package (Evita Erro de Objeto Descartado)
    BEGIN
      vvVersao := PKG_ESTOQUE.VERSAO;
    EXCEPTION
     WHEN OTHERS THEN
        BEGIN
          vvVersao := PKG_ESTOQUE.VERSAO;
        EXCEPTION
          WHEN OTHERS THEN
            vvVersao := PKG_ESTOQUE.VERSAO;
         END;
    END;  
    
    -- Obtém Estoque Disponível
    vnSaldoRetorno := PKG_ESTOQUE.ESTOQUE_DISPONIVEL (pi_vCodProd
                                                     ,pi_vCodFilial
                                                     ,'V'); -->> Venda
  
    -- Opção de Abater o Estoque Mínimo - DDMEDICA-7391
    IF (pi_nOpcaoLimitarVendaEstMin = 1) THEN
      BEGIN
        SELECT NVL(PCPRODFILIAL.ESTOQUEMIN,0)
          INTO vnEstoqueMin
          FROM PCPRODFILIAL
         WHERE (CODFILIAL = pi_vCodFilial)
           AND (CODPROD   = pi_vCodProd);  
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnEstoqueMin := 0;
      END;
      IF (NVL(vnEstoqueMin,0) > 0) THEN
        vnSaldoRetorno := NVL(vnSaldoRetorno,0) - NVL(vnEstoqueMin,0);
        IF (NVL(vnSaldoRetorno,0) < 0) THEN
          vnSaldoRetorno := 0;
        END IF;
      END IF;
    END IF;
    
    -- Retorno
    RETURN vnSaldoRetorno;
  
  END F_OBTER_ESTOQUE_DISP;

  /*******************************************************************************
   Nome         : FCT_MED_OBTER_ESTOQUE_DISPPEND
   Descricão    : Função para obter o Saldo de Estoque Disponivel sem abater o
                  Pendente
   Parâmetros   : ENTRADA:
                  pi_vCodProd                 = Código do Produto
                  pi_vCodFilial               = Código da Filial
                  pi_nOpcaoLimitarVendaEstMin = Opção de abater o Estoque Mínimo
                                                0 - Não Abater
                                                1 - Abater
   Alteracão    : Anderson Silva - 30/11/2018 - Criação da Função - MED-1981
   Alteracão    : Anderson Silva - 26/04/2019 - Alteração do Parâmetro da Filial
   Alteração    : Anderson Silva - 22/08/2021 - DDMEDICA-7391 - Limitar Venda do Estoque Mínimo 
  ********************************************************************************/
  FUNCTION F_OBTER_ESTOQUE_DISPPEND(pi_vCodProd                 IN NUMBER,
                                    pi_vCodFilial               IN VARCHAR2,
                                    pi_nOpcaoLimitarVendaEstMin IN NUMBER DEFAULT 0)
  RETURN NUMBER
  IS
  
    -- Versão
    vvVersao       VARCHAR2(250);  
    
    -- Saldo Retorno
    vnSaldoRetorno NUMBER;
    
    -- Estoque Mínimo
    vnEstoqueMin   PCPRODFILIAL.ESTOQUEMIN%TYPE;
  
  BEGIN
  
    -- Inicializa Retorno
    vnSaldoRetorno := 0;
    
    -- Força a Recompilação da Package (Evita Erro de Objeto Descartado)
    BEGIN
      vvVersao := PKG_ESTOQUE.VERSAO;
    EXCEPTION
     WHEN OTHERS THEN
        BEGIN
          vvVersao := PKG_ESTOQUE.VERSAO;
        EXCEPTION
          WHEN OTHERS THEN
            vvVersao := PKG_ESTOQUE.VERSAO;
         END;
    END;  
    
    -- Obtém Estoque Disponível
    vnSaldoRetorno := PKG_ESTOQUE.ESTOQUE_DISPONIVEL (pi_vCodProd
                                                     ,pi_vCodFilial
                                                     ,'P'); -->> Venda sem Abater o Pendente
  
    -- Opção de Abater o Estoque Mínimo - DDMEDICA-7391
    IF (pi_nOpcaoLimitarVendaEstMin = 1) THEN
      BEGIN
        SELECT NVL(PCPRODFILIAL.ESTOQUEMIN,0)
          INTO vnEstoqueMin
          FROM PCPRODFILIAL
         WHERE (CODFILIAL = pi_vCodFilial)
           AND (CODPROD   = pi_vCodProd);  
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnEstoqueMin := 0;
      END;
      IF (NVL(vnEstoqueMin,0) > 0) THEN
        vnSaldoRetorno := NVL(vnSaldoRetorno,0) - NVL(vnEstoqueMin,0);
        IF (NVL(vnSaldoRetorno,0) < 0) THEN
          vnSaldoRetorno := 0;
        END IF;
      END IF;
    END IF;
    
    -- Retorno
    RETURN vnSaldoRetorno;
  
  END F_OBTER_ESTOQUE_DISPPEND;
  
  /*******************************************************************************
   Nome         : F_OBTER_ESTOQUE_AVARIA
   Descricão    : Função para obter o Saldo de Avaria Disponível
   Parâmetros   : ENTRADA:
                  pi_vCodProd   = Código do Produto
                  pi_vCodFilial = Código da Filial
   Alteracão    : Anderson Silva - 24/06/2019 - Criação da Função - DDMEDICA-641
  ********************************************************************************/
  FUNCTION F_OBTER_ESTOQUE_AVARIA(pi_vCodProd   IN NUMBER,
                                  pi_vCodFilial IN VARCHAR2)
  RETURN NUMBER
  IS
  
    -- Versão
    vvVersao       VARCHAR2(250);  
    
    -- Saldo Retorno
    vnSaldoRetorno NUMBER;
  
  BEGIN
  
    -- Inicializa Retorno
    vnSaldoRetorno := 0;
    
    -- Força a Recompilação da Package (Evita Erro de Objeto Descartado)
    BEGIN
      vvVersao := PKG_ESTOQUE.VERSAO;
    EXCEPTION
     WHEN OTHERS THEN
        BEGIN
          vvVersao := PKG_ESTOQUE.VERSAO;
        EXCEPTION
          WHEN OTHERS THEN
            vvVersao := PKG_ESTOQUE.VERSAO;
         END;
    END;  
    
    -- Obtém Estoque Disponível
    vnSaldoRetorno := PKG_ESTOQUE.ESTOQUE_DISPONIVEL (pi_vCodProd
                                                     ,pi_vCodFilial
                                                     ,'PA'); -->> Pedido de Avaria
  
    -- Retorno
    RETURN vnSaldoRetorno;
  
  END F_OBTER_ESTOQUE_AVARIA;
  
  /*******************************************************************************
   Nome         : F_OBTER_ESTOQUE_BLOQ
   Descricão    : Função para obter o Saldo de Estoque Bloqueado
   Parâmetros   : ENTRADA:
                  pi_vCodProd   = Código do Produto
                  pi_vCodFilial = Código da Filial
   Alteracão    : Anderson Silva - 22/08/2019 - Criação da Função - DDMEDICA-641
  ********************************************************************************/
  FUNCTION F_OBTER_ESTOQUE_BLOQ(pi_vCodProd   IN NUMBER,
                                pi_vCodFilial IN VARCHAR2)
  RETURN NUMBER
  IS
  
    -- Versão
    vvVersao       VARCHAR2(250);  
    
    -- Saldo Retorno
    vnSaldoRetorno NUMBER;
  
  BEGIN
  
    -- Inicializa Retorno
    vnSaldoRetorno := 0;
    
    -- Força a Recompilação da Package (Evita Erro de Objeto Descartado)
    BEGIN
      vvVersao := PKG_ESTOQUE.VERSAO;
    EXCEPTION
     WHEN OTHERS THEN
        BEGIN
          vvVersao := PKG_ESTOQUE.VERSAO;
        EXCEPTION
          WHEN OTHERS THEN
            vvVersao := PKG_ESTOQUE.VERSAO;
         END;
    END;  
    
    -- Obtém Estoque Disponível
    vnSaldoRetorno := PKG_ESTOQUE.ESTOQUE_DISPONIVEL (pi_vCodProd
                                                     ,pi_vCodFilial
                                                     ,'PC'); -->> Pedido de CrossDocking
  
    -- Retorno
    RETURN vnSaldoRetorno;
  
  END F_OBTER_ESTOQUE_BLOQ;
  
  /*******************************************************************************
   Nome         : F_OBTER_EST_CONTAB_DISP
   Descricão    : Função para obter o Saldo de Estoque Contábil Disponivel
   Parâmetros   : ENTRADA:
                  pi_nCodProd   = Código do Produto
                  pi_vCodFilial = Código da Filial
   Alteracão    : Anderson Silva - 04/10/2017 - Criação da Função
   Alteracão    : Anderson Silva - 26/04/2019 - Alteração do Parâmetro da Filial
  ********************************************************************************/
  FUNCTION F_OBTER_EST_CONTAB_DISP(pi_nCodProd          IN NUMBER,
                                   pi_vCodFilial        IN VARCHAR2,
                                   pi_IgnorarQtPendente IN VARCHAR2 DEFAULT 'N')
  RETURN NUMBER
  IS
  
    -- Versão
    vvVersao                  VARCHAR2(250);  
    
    -- Saldo Retorno
    vnSaldoRetorno            NUMBER;
  
    -- Parâmetro
    vsBloqueiaEstoquePendente VARCHAR2(1);
  
  BEGIN
  
    -- Inicializa Retorno
    vnSaldoRetorno := 0;
    
    -- Força a Recompilação da Package (Evita Erro de Objeto Descartado)
    BEGIN
      vvVersao := PKG_ESTOQUE.VERSAO;
    EXCEPTION
     WHEN OTHERS THEN
        BEGIN
          vvVersao := PKG_ESTOQUE.VERSAO;
        EXCEPTION
          WHEN OTHERS THEN
            vvVersao := PKG_ESTOQUE.VERSAO;
         END;
    END;  
    
    vsBloqueiaEstoquePendente := coalesce(paramfilial.ObterComoVarchar2('BLOQUEIAVENDAESTPENDENTE', pi_vCodFilial),
    PARAMFILIAL.OBTERCOMOVARCHAR2('CON_BLOQUEIAVENDAESTPENDENTE'));
    -- Se chamado da 2336 não pode abater a Qtde. Pendente
    IF (pi_IgnorarQtPendente = 'S') THEN
      vsBloqueiaEstoquePendente := 'N';  
    END IF;
    
    -- Obtém Estoque Disponível
    --vnSaldoRetorno := PKG_ESTOQUE.ESTOQUE_DISPONIVEL (pi_nCodProd
    --                                                 ,pi_vCodFilial
    --                                                 ,'V'); -->> Venda
    BEGIN
      SELECT (NVL(PCEST.QTEST, 0) -
              NVL(PCEST.QTBLOQUEADA, 0) -
              NVL(PCEST.QTINDUSTRIA, 0) -
              NVL(PCEST.QTRESERV, 0) -
             --(CASE PARAMFILIAL.OBTERCOMOBOOLEAN('RESERVAESTFRENTELOJA',psCODFILIAL,'S','N')
             --   WHEN 'S' THEN
             --     NVL(PCEST.QTFRENTELOJA, 0)
             -- ELSE 0 END) -
             (case vsBloqueiaEstoquePendente
                WHEN 'S' THEN
                  NVL(PCEST.QTPENDENTE, 0)
              ELSE 0 END)) AS DISPONIVEL
        INTO vnSaldoRetorno
        FROM PCEST
       WHERE PCEST.CODPROD = pi_nCodProd
         AND PCEST.CODFILIAL = pi_vCodFilial;       
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnSaldoRetorno := 0; 
    END;
  
    -- Retorno
    RETURN vnSaldoRetorno;
  
  END F_OBTER_EST_CONTAB_DISP;
  
  /*******************************************************************************
   Nome         : F_PODECOMPRARPROMOCAO
   Descricão    : Função para retornar se pode Comprar da Promoção
   Parâmetros   : ENTRADA:
                  pi_nCodProd          = Código da Promoção
                  pi_vCodFilial        = Código da Filial
                  pi_nCodCli           = Código do Cliente
                  pi_nNumRegiao        = Número da Região
                  pi_nCodUsur          = Código do RCA
                  pi_nCodPlPag         = Código do Plano de Pagamento
                  pi_nCodCondicaoVenda = Código da Condição de Venda
                  pi_dDataPedido       = Data do Pedido
   Alteracão    : Anderson Silva - 28/03/2014 - HIS.02068.2016- Criação da Função
   Alteracão    : Anderson Silva - 30/09/2016 - TRUNCAR Data do Pedido
   Alteração    : Anderson Silva = 21/12/2017 - Regra Específica a Dias a Mais na Vigência - FV
   Alteracão    : Anderson Silva - 25/05/2019 - Condição RCA ou Supervisor
   Alteração    : Anderson Silva - 22/08/2019 - DDMEDICA-619 - Pedido Avaria e CrossDocking
   Alteração    : Anderson Silva - 02/10/2019 - DDMEDICA-957 - Pedido Consignado
   Alteração    : Anderson Silva - 06/05/2020 - DDMEDICA-2609 - Grupo Comercial
   Alteração    : Anderson Silva - 11/05/2020 - DDMEDICA-2858 - Ajuste pesquisa promoção com cliente principal 
  ********************************************************************************/
  FUNCTION F_PODECOMPRARPROMOCAO(pi_nCodPromocaoMed   IN NUMBER,
                                 pi_vCodFilial        IN VARCHAR2,
                                 pi_nCodCli           IN NUMBER,
                                 pi_nNumRegiao        IN NUMBER,
                                 pi_nCodUsur          IN NUMBER,
                                 pi_nCodPlPag         IN NUMBER,
                                 pi_nCodCondicaoVenda IN NUMBER,
                                 pi_vOrigemPed        IN VARCHAR2,
                                 pi_vTipoFv           IN VARCHAR2,
                                 pi_dDataPedido       IN DATE DEFAULT SYSDATE)
  RETURN VARCHAR2
  IS
  
    -- Retorno
    vvRetPodeComprar            VARCHAR2(200);  
    
    -- Dados da Promoção
    vvTipoPlanoPag              PCPROMOCAOMED.TIPOPLANOPAG%TYPE;
    vdDataInicial               PCPROMOCAOMED.DATAINICIAL%TYPE;
    vdDataFinal                 PCPROMOCAOMED.DATAFINAL%TYPE;
    vvUsaNormalizacaoDesc       PCPROMOCAOMED.USANORMALIZACAODESC%TYPE;
    vvUtilizaDescRede           PCPROMOCAOMED.UTILIZADESCREDE%TYPE;
    
    -- Dados do Cliente
    vnCodPraca                  PCCLIENT.CODPRACA%TYPE;
    vvClasseVenda               PCCLIENT.CLASSEVENDA%TYPE;
    vnCodAtv1                   PCCLIENT.CODATV1%TYPE;
    vnCodRede                   PCCLIENT.CODREDE%TYPE; 
    vnCodGrupoComercialMed      PCCLIENT.CODGRUPOCOMERCIALMED%TYPE;
    
    -- Região do Cliente
    vnNumRegiao                 PCPRACA.NUMREGIAO%TYPE;
    
    -- Dados do RCA
    vnCodSupervisor             PCUSUARI.CODSUPERVISOR%TYPE;
    vvAreaAtuacao               PCUSUARI.AREAATUACAO%TYPE;
    
    -- Dados do Plano de Pagamento
    vnNumDias                   PCPLPAG.NUMDIAS%TYPE;  
    
    -- Origem do Pedido
    vvOrigemPed                 VARCHAR2(1);
      
    -- Verifição de Restrições
    vvExisteRestricaoPeloCodigo VARCHAR2(1);
    vvExistemRestricoes         VARCHAR2(1);
    --
    vvExisteRestricaoCodCli     VARCHAR2(1);
    vvExistemRestricoesCli      VARCHAR2(1);
    --
    vvExisteRestricaoCodRede    VARCHAR2(1);
    vvExistemRestricoesRede     VARCHAR2(1);
    --
    vvExisteRestricaoCodUsur    VARCHAR2(1);
    vvExistemRestricoesUsur     VARCHAR2(1);
    --
    vvExisteRestricaoCodSuperv  VARCHAR2(1);
    vvExistemRestricoesSuperv   VARCHAR2(1);
      
    -- Regra Específica - Dias a Mais na Vigência
    nDIASMAISPROMOCAOVENCIDAFV  NUMBER;
    vDIASMAISPROMOCAOVENCIDAFV  VARCHAR2(250);
    
    -- Cliente Principal
    vnCodCliPrinc               PCCLIENT.CODCLIPRINC%TYPE;
    
    ------------------------------------------------------------------------------
    -- Função para Verificar se Usa Regra Específica de Medicamentos --
    -------------------------------------------------------------------
    FUNCTION F_REGRA_MEDICAMENTOS(pi_vCodFilial IN VARCHAR2,
                                  pi_vNome      IN VARCHAR2)
    RETURN VARCHAR2 IS
      vvRetRegraMedicamentos VARCHAR2(240);
  BEGIN
      -- Verifica se usa regra
      BEGIN
        EXECUTE IMMEDIATE ' SELECT VALOR FROM PCREGRASEXCECAOMED WHERE NOME = ' || '''' || pi_vNome || '''' || ' AND CODFILIAL = ' || '''' || pi_vCodFilial || ''''
                     INTO vvRetRegraMedicamentos;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvRetRegraMedicamentos := NULL;
        WHEN OTHERS THEN
          vvRetRegraMedicamentos := NULL;
      END;
      -- Retorno
      RETURN vvRetRegraMedicamentos;
    END F_REGRA_MEDICAMENTOS;
  
  BEGIN
  
    -- Inicializa Retorno
    vvRetPodeComprar := 'S';
       
    -- Regra Específica - Dias a Mais na Vigência - FV
    nDIASMAISPROMOCAOVENCIDAFV := 0;
    IF (pi_vOrigemPed = 'F') AND
       (pi_vTipoFv IS NULL)  THEN
      vDIASMAISPROMOCAOVENCIDAFV := F_REGRA_MEDICAMENTOS('99','DIASMAISPROMOCAOVENCIDAFV');
      IF ((vDIASMAISPROMOCAOVENCIDAFV >= '1') AND (vDIASMAISPROMOCAOVENCIDAFV <= '9')) THEN
        BEGIN
          nDIASMAISPROMOCAOVENCIDAFV := TO_NUMBER(vDIASMAISPROMOCAOVENCIDAFV);
        EXCEPTION
          WHEN OTHERS THEN 
            nDIASMAISPROMOCAOVENCIDAFV := 0;
        END;
      END IF;
    END IF;
    
    -- Pesquisa Dados da Promoção
    BEGIN
      SELECT PCPROMOCAOMED.TIPOPLANOPAG
           , PCPROMOCAOMED.DATAINICIAL
           , PCPROMOCAOMED.DATAFINAL
           , PCPROMOCAOMED.USANORMALIZACAODESC
           , PCPROMOCAOMED.UTILIZADESCREDE
        INTO vvTipoPlanoPag
           , vdDataInicial
           , vdDataFinal
           , vvUsaNormalizacaoDesc
           , vvUtilizaDescRede
        FROM PCPROMOCAOMED
       WHERE (PCPROMOCAOMED.CODPROMOCAOMED = pi_nCodPromocaoMed);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvTipoPlanoPag        := NULL;
        vdDataInicial         := NULL;
        vdDataFinal           := NULL;
        vvUsaNormalizacaoDesc := NULL;
        vvUtilizaDescRede     := NULL;
    END;
    
   /***************************************** 
    Se utilizar as novas Tabelas Normalizadas
    *****************************************/
    IF (NVL(vvUsaNormalizacaoDesc,'N') = 'S') THEN
    
      --------------------------------
      -- Verifica Vigência da Promoção
      --------------------------------
      IF NOT ((TRUNC(pi_dDataPedido) >= vdDataInicial) AND 
              (TRUNC(pi_dDataPedido) <= (vdDataFinal + NVL(nDIASMAISPROMOCAOVENCIDAFV,0))))  THEN
    
        vvRetPodeComprar := 'N - Vigência da Promoção';
              
      ELSE
      
        -- Pesquisa Dados do Cliente
        BEGIN
          SELECT PCCLIENT.CODPRACA
               , PCCLIENT.CLASSEVENDA
               , PCCLIENT.CODATV1
               , PCCLIENT.CODREDE
               , PCCLIENT.CODGRUPOCOMERCIALMED
               , CASE WHEN (NVL(vvUtilizaDescRede,'N') = 'S') THEN
                   NVL(PCCLIENT.CODCLIPRINC,PCCLIENT.CODCLI)
                 ELSE
                   PCCLIENT.CODCLI
                 END COD_CLIENTE_PRINCIPAL -- DDMEDICA-2858
            INTO vnCodPraca
               , vvClasseVenda
               , vnCodAtv1
               , vnCodRede
               , vnCodGrupoComercialMed
               , vnCodCliPrinc -- DDMEDICA-2858             
            FROM PCCLIENT
           WHERE (PCCLIENT.CODCLI = pi_nCodCli);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnCodPraca             := NULL;
            vvClasseVenda          := NULL;
            vnCodAtv1              := NULL;
            vnCodRede              := NULL;
            vnCodGrupoComercialMed := NULL;
            vnCodCliPrinc := NULL; -- DDMEDICA-2858          
        END;
        
        -- Se passou a Região no Parâmetro
        IF (NVL(pi_nNumRegiao,0) > 0) THEN
            
          vnNumRegiao := pi_nNumRegiao;
              
        -- Se NÃO passou a Região no Parâmetro
        ELSE
          
          -- Pesquisa Região do Cliente por Filial
          BEGIN
            SELECT NUMREGIAO
              INTO vnNumRegiao
              FROM PCTABPRCLI
             WHERE (CODCLI      = pi_nCodCli)
               AND (CODFILIALNF = pi_vCodFilial);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vnNumRegiao := NULL;
          END;
            
          -- Se não achou Regiao do Cliente por Filial
          IF (vnNumRegiao IS NULL) THEN
            -- Pesquisa Região da Praça
            BEGIN
              SELECT NUMREGIAO
                INTO vnNumRegiao
                FROM PCPRACA
               WHERE (CODPRACA = vnCodPraca);
            EXCEPTION
             WHEN NO_DATA_FOUND THEN
                vnNumRegiao := NULL;
            END;
          END IF;
          
        END IF; -- Fim Condição Se passou a Região no Parâmetro        
        
        -- Pesquisa Dados do RCA
        BEGIN
          SELECT PCUSUARI.CODSUPERVISOR
               , PCUSUARI.AREAATUACAO
            INTO vnCodSupervisor
               , vvAreaAtuacao
            FROM PCUSUARI
           WHERE (PCUSUARI.CODUSUR = pi_nCodUsur);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnCodSupervisor := NULL;
            vvAreaAtuacao   := NULL;
        END;
        
        -- Pesquisa Dados do Plano de Pagamento
        BEGIN
          SELECT PCPLPAG.NUMDIAS
            INTO vnNumDias
            FROM PCPLPAG
           WHERE (PCPLPAG.CODPLPAG = pi_nCodPlPag);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnNumDias := NULL;
        END;
          
        -- Define Origem do Pedido
        IF    (NVL(pi_vTipoFv,' ') = 'OL') THEN
          vvOrigemPed := 'L';
        ELSIF (NVL(pi_vTipoFv,' ') = 'PE') THEN
          vvOrigemPed := 'E';      
        ELSIF (NVL(pi_vTipoFv,' ') = 'PA') THEN -- DDMEDICA-619 - Pedido Avaria
          vvOrigemPed := 'V';
        ELSIF (NVL(pi_vTipoFv,' ') = 'PC') THEN -- DDMEDICA-619 - Pedido CrossDocking  
          vvOrigemPed := 'D';
        ELSIF (NVL(pi_vTipoFv,' ') = 'PG') THEN -- DDMEDICA-957 - Pedido Consignado
          vvOrigemPed := 'G';
        ELSE
          vvOrigemPed := pi_vOrigemPed;
        END IF;
  
        -------------------------------------------
        -- Verifica Restrições por Origem do Pedido
        ------------------------------------------
        vvExisteRestricaoPeloCodigo := 'N';
        vvExistemRestricoes         := 'N';
        BEGIN
          SELECT 'S'
            INTO vvExisteRestricaoPeloCodigo
            FROM PCPROMOCAOORIGEMMED
           WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
             AND (ORIGEMPED      = vvOrigemPed); -->> Pesquisa pelo Código
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            BEGIN
              SELECT 'S'
                INTO vvExistemRestricoes
                FROM PCPROMOCAOORIGEMMED
               WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                 AND (ROWNUM         = 1);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                NULL;
            END;
        END;
          
        -- Se não pode comprar por Restrição de Origem do Pedido
        IF (vvExisteRestricaoPeloCodigo = 'N') AND
           (vvExistemRestricoes         = 'S') THEN
          
          vvRetPodeComprar := 'N - Restrição de Origem do Pedido';
            
        ELSE
  
          ---------------------------------  
          -- Verifica Restrições por Filial
          ---------------------------------
          vvExisteRestricaoPeloCodigo := 'N';
          vvExistemRestricoes         := 'N';
          BEGIN
            SELECT 'S'
              INTO vvExisteRestricaoPeloCodigo
              FROM PCPROMOCAOFILMED
             WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
               AND (CODFILIAL      = pi_vCodFilial); -->> Pesquisa pelo Código
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              BEGIN
                SELECT 'S'
                  INTO vvExistemRestricoes
                  FROM PCPROMOCAOFILMED
                 WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                   AND (ROWNUM         = 1);
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  NULL;
              END;
          END;
          
          -- Se não pode comprar por Restrição de Filial
          IF (vvExisteRestricaoPeloCodigo = 'N') AND
             (vvExistemRestricoes         = 'S') THEN
          
            vvRetPodeComprar := 'N - Restrição de Filial';
            
          ELSE
          
            ---------------------------------
            -- Verifica Restrições por Região
            ---------------------------------
            vvExisteRestricaoPeloCodigo := 'N';
            vvExistemRestricoes         := 'N';
            BEGIN
              SELECT 'S'
                INTO vvExisteRestricaoPeloCodigo
                FROM PCPROMOCAOREGIAOMED
               WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                 AND (NUMREGIAO      = vnNumRegiao); -->> Pesquisa pelo Código
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                BEGIN
                  SELECT 'S'
                    INTO vvExistemRestricoes
                    FROM PCPROMOCAOREGIAOMED
                   WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                     AND (ROWNUM         = 1);
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    NULL;
                END;
            END;
            
            -- Se não pode comprar por Restrição de Região
            IF (vvExisteRestricaoPeloCodigo = 'N') AND
               (vvExistemRestricoes         = 'S') THEN
            
              vvRetPodeComprar := 'N - Restrição de Região';
              
            ELSE
  
              ---------------------------------------
              -- Verifica Restrições por Cliente/Rede
              ---------------------------------------
              vvExisteRestricaoPeloCodigo := 'N';
              vvExistemRestricoes         := 'N';
        
              ----------------------------------
              -- Verifica Restrições por Cliente
              ----------------------------------
              vvExisteRestricaoCodCli := 'N';
              vvExistemRestricoesCli  := 'N';
              BEGIN
                SELECT 'S'
                  INTO vvExisteRestricaoCodCli
                  FROM PCPROMOCAOCLIMED
                 WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                   AND (CODCLI         IN (pi_nCodCli,vnCodCliPrinc)) -->> Pesquisa pelo Código do Cliente/Código do Cliente Principal
                   AND (ROWNUM         = 1);
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  NULL;
              END;
              BEGIN
                SELECT 'S'
                  INTO vvExistemRestricoesCli
                  FROM PCPROMOCAOCLIMED
                 WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                   AND (ROWNUM         = 1);
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  NULL;
              END;
              
              -------------------------------
              -- Verifica Restrições por Rede
              -------------------------------
              vvExisteRestricaoCodRede := 'N';
              vvExistemRestricoesRede  := 'N';
              BEGIN
                SELECT 'S'
                  INTO vvExisteRestricaoCodRede
                  FROM PCPROMOCAOREDEMED
                 WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                   AND (CODREDE        = vnCodRede); -->> Pesquisa pelo Código
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                   NULL;
              END;
              BEGIN
                SELECT 'S'
                  INTO vvExistemRestricoesRede
                  FROM PCPROMOCAOREDEMED
                 WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                   AND (ROWNUM         = 1);
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  NULL;
              END;
              
              -- Se existirem Restrições por Cliente e Rede
              IF    ((vvExistemRestricoesCli = 'S') AND (vvExistemRestricoesRede = 'S')) THEN
                -- Se não estiver na duas restrições (Cliente/Rede)
                IF (vvExisteRestricaoCodCli  <> 'S') AND
                   (vvExisteRestricaoCodRede <> 'S') THEN
                  vvExisteRestricaoPeloCodigo := 'N';
                  vvExistemRestricoes         := 'S';
                  vvRetPodeComprar            := 'N - Restrição de Cliente/Rede';
                END IF;
              -- Se existirem SOMENTE Restrições por Cliente
              ELSIF (vvExistemRestricoesCli = 'S') THEN
                -- Se não estiver na restrição (Cliente)
                IF (vvExisteRestricaoCodCli  <> 'S') THEN
                  vvExisteRestricaoPeloCodigo := 'N';
                  vvExistemRestricoes         := 'S';
                  vvRetPodeComprar            := 'N - Restrição de Cliente';
                END IF;
              -- Se existirem SOMENTE Restrições por Rede
              ELSIF (vvExistemRestricoesRede = 'S') THEN
                -- Se não estiver na restrição (Rede)
                IF (vvExisteRestricaoCodRede  <> 'S') THEN
                  vvExisteRestricaoPeloCodigo := 'N';
                  vvExistemRestricoes         := 'S';
                  vvRetPodeComprar            := 'N - Restrição de Rede';
                END IF;
              END IF;
              
              -- Se não pode comprar por Restrição de Cliente/Rede
              IF (vvExisteRestricaoPeloCodigo = 'N') AND
                 (vvExistemRestricoes         = 'S') THEN
              
                vvRetPodeComprar := vvRetPodeComprar;
                
              ELSE
        
                -------------------------------
                -- Verifica Restrições por Rede
                -------------------------------
                vvExisteRestricaoPeloCodigo := 'N';
                vvExistemRestricoes         := 'N';
               /* 
                BEGIN
                  SELECT 'S'
                    INTO vvExisteRestricaoPeloCodigo
                    FROM PCPROMOCAOREDEMED
                   WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                     AND (CODREDE        = vnCodRede); -->> Pesquisa pelo Código
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    BEGIN
                      SELECT 'S'
                        INTO vvExistemRestricoes
                        FROM PCPROMOCAOREDEMED
                       WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                         AND (ROWNUM         = 1);
                    EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                        NULL;
                    END;
                END;
                */
                
                -- Se não pode comprar por Restrição de Rede
                IF (vvExisteRestricaoPeloCodigo = 'N') AND
                   (vvExistemRestricoes         = 'S') THEN
                
                  vvRetPodeComprar := 'N - Restrição de Rede de Clientes';
                  
                ELSE
          
                  ------------------------------------------------------------------------------------------------------
                  -- Verifica Restrições por Plano de Pagamento com Prazo Médio Menor ou Igual ao Informado na Promoção
                  -----------------------------------------------------------------------------------------------------
                  IF    (vvTipoPlanoPag = '1') THEN
                  
                    vvExisteRestricaoPeloCodigo := 'N';
                    vvExistemRestricoes         := 'N';
                    BEGIN
                      SELECT 'S'
                        INTO vvExisteRestricaoPeloCodigo
                        FROM PCPROMOCAOPLPAGMED
                           , PCPLPAG
                       WHERE (PCPROMOCAOPLPAGMED.CODPROMOCAOMED = pi_nCodPromocaoMed)
                         AND (PCPROMOCAOPLPAGMED.CODPLPAG       = PCPLPAG.CODPLPAG)
                         AND (PCPLPAG.NUMDIAS                  >= NVL(vnNumDias,0)) -->> Pesquisando se existe algum Plano Pagto com Prazo Médio Maior ou Superior ao do Plano Pagto informado
                         AND (ROWNUM                            = 1);
                    EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                        BEGIN
                          SELECT 'S'
                            INTO vvExistemRestricoes
                            FROM PCPROMOCAOPLPAGMED
                           WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                             AND (ROWNUM         = 1);
                        EXCEPTION
                          WHEN NO_DATA_FOUND THEN
                            NULL;
                        END;
                    END;
        
                  --------------------------------------------------------------------
                  -- Verifica Restrições por Plano de Pagamento cadastrado na Promoção
                  --------------------------------------------------------------------
                  ELSIF (vvTipoPlanoPag = '2') THEN 
                  
                    vvExisteRestricaoPeloCodigo := 'N';
                    vvExistemRestricoes         := 'N';
                    BEGIN
                      SELECT 'S'
                        INTO vvExisteRestricaoPeloCodigo
                        FROM PCPROMOCAOPLPAGMED
                       WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                         AND (CODPLPAG       = pi_nCodPlPag); -->> Pesquisa pelo Código
                    EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                        BEGIN
                          SELECT 'S'
                            INTO vvExistemRestricoes
                            FROM PCPROMOCAOPLPAGMED
                           WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                             AND (ROWNUM         = 1);
                        EXCEPTION
                          WHEN NO_DATA_FOUND THEN
                            NULL;
                        END;
                    END;
                    
                  END IF; -- Fim Condição (vvTipoPlanoPag)
                  
                  -- Se não pode comprar por Plano de Pagamento
                  IF (vvExisteRestricaoPeloCodigo = 'N') AND
                     (vvExistemRestricoes         = 'S') THEN
                  
                    vvRetPodeComprar := 'N - Restrição de Plano de Pagamento';
                    
                  ELSE
  
                    -----------------------------------------
                    -- Verifica Restrições por RCA/Supervisor
                    -----------------------------------------
                    vvExisteRestricaoPeloCodigo := 'N';
                    vvExistemRestricoes         := 'N';
                  
                    ------------------------------
                    -- Verifica Restrições por RCA
                    ------------------------------
                    vvExisteRestricaoCodUsur := 'N';
                    vvExistemRestricoesUsur  := 'N';
                    BEGIN
                      SELECT 'S'
                        INTO vvExisteRestricaoCodUsur
                        FROM PCPROMOCAOUSURMED
                       WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                         AND (CODUSUR        = pi_nCodUsur); -->> Pesquisa pelo Código
                    EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                         NULL;
                    END;
                    BEGIN
                      SELECT 'S'
                        INTO vvExistemRestricoesUsur
                        FROM PCPROMOCAOUSURMED
                       WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                         AND (ROWNUM         = 1);
                    EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                        NULL;
                    END;
  
                    -------------------------------------
                    -- Verifica Restrições por Supervisor
                    ------------------------------------
                    vvExisteRestricaoCodSuperv := 'N';
                    vvExistemRestricoesSuperv  := 'N';
                    BEGIN
                      SELECT 'S'
                        INTO vvExisteRestricaoCodSuperv
                        FROM PCPROMOCAOSUPERVMED
                       WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                         AND (CODSUPERV      = vnCodSupervisor); -->> Pesquisa pelo Código
                    EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                        NULL;
                    END;
                    BEGIN
                      SELECT 'S'
                        INTO vvExistemRestricoesSuperv
                        FROM PCPROMOCAOSUPERVMED
                       WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                         AND (ROWNUM         = 1);
                    EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                        NULL;
                    END;
                    
                    -- Se existirem Restrições por RCA e Supervisor
                    IF    ((vvExistemRestricoesUsur = 'S') AND (vvExistemRestricoesSuperv = 'S')) THEN
                      -- Se não estiver na duas restrições (RCA/Supervisor)
                      IF (vvExisteRestricaoCodUsur   <> 'S') AND
                         (vvExisteRestricaoCodSuperv <> 'S') THEN
                        vvExisteRestricaoPeloCodigo := 'N';
                        vvExistemRestricoes         := 'S';
                        vvRetPodeComprar            := 'N - Restrição de RCA/Supervisor';
                      END IF;
                    -- Se existirem SOMENTE Restrições por RCA
                    ELSIF (vvExistemRestricoesUsur = 'S') THEN
                      -- Se não estiver na restrição (RCA)
                      IF (vvExisteRestricaoCodUsur  <> 'S') THEN
                        vvExisteRestricaoPeloCodigo := 'N';
                        vvExistemRestricoes         := 'S';
                        vvRetPodeComprar            := 'N - Restrição de RCA';
                      END IF;
                    -- Se existirem SOMENTE Restrições por Supervisor
                    ELSIF (vvExistemRestricoesSuperv = 'S') THEN
                      -- Se não estiver na restrição (Supervisor)
                      IF (vvExisteRestricaoCodSuperv  <> 'S') THEN
                        vvExisteRestricaoPeloCodigo := 'N';
                        vvExistemRestricoes         := 'S';
                        vvRetPodeComprar            := 'N - Restrição de Supervisor';
                      END IF;
                    END IF;
                    
                    -- Se não pode comprar por Restrição de RCA/Supervisor
                    IF (vvExisteRestricaoPeloCodigo = 'N') AND
                       (vvExistemRestricoes         = 'S') THEN
                    
                      vvRetPodeComprar := vvRetPodeComprar;
                      
                    ELSE
        
                      -------------------------------------
                      -- Verifica Restrições por Supervisor
                      ------------------------------------
                      vvExisteRestricaoPeloCodigo := 'N';
                      vvExistemRestricoes         := 'N';
                     /* 
                      BEGIN
                        SELECT 'S'
                          INTO vvExisteRestricaoPeloCodigo
                          FROM PCPROMOCAOSUPERVMED
                         WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                           AND (CODSUPERV      = vnCodSupervisor); -->> Pesquisa pelo Código
                      EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                          BEGIN
                            SELECT 'S'
                              INTO vvExistemRestricoes
                              FROM PCPROMOCAOSUPERVMED
                             WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                               AND (ROWNUM         = 1);
                          EXCEPTION
                            WHEN NO_DATA_FOUND THEN
                              NULL;
                          END;
                      END;
                      */
                      
                      -- Se não pode comprar por Restrição de Supervisor
                      IF (vvExisteRestricaoPeloCodigo = 'N') AND
                         (vvExistemRestricoes         = 'S') THEN
                      
                        vvRetPodeComprar := 'N - Restrição de Supervisor';
                        
                      ELSE
                  
                        --------------------------------------------
                        -- Verifica Restrições por Condição de Venda
                        --------------------------------------------
                        vvExisteRestricaoPeloCodigo := 'N';
                        vvExistemRestricoes         := 'N';
                        BEGIN
                          SELECT 'S'
                            INTO vvExisteRestricaoPeloCodigo
                            FROM PCPROMOCAOCONDVENDAMED
                           WHERE (CODPROMOCAOMED   = pi_nCodPromocaoMed)
                             AND (CODCONDICAOVENDA = pi_nCodCondicaoVenda); -->> Pesquisa pelo Código
                        EXCEPTION
                          WHEN NO_DATA_FOUND THEN
                            BEGIN
                              SELECT 'S'
                                INTO vvExistemRestricoes
                                FROM PCPROMOCAOCONDVENDAMED
                               WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                                 AND (ROWNUM         = 1);
                            EXCEPTION
                              WHEN NO_DATA_FOUND THEN
                                NULL;
                            END;
                        END;
            
                        -- Se não pode comprar por Condição de Venda
                        IF (vvExisteRestricaoPeloCodigo = 'N') AND
                           (vvExistemRestricoes         = 'S') THEN
                        
                          vvRetPodeComprar := 'N - Restrição de Condição de Venda';
                          
                        ELSE
                        
                          --------------------------------
                          -- Verifica Restrições por Praça
                          --------------------------------
                          vvExisteRestricaoPeloCodigo := 'N';
                          vvExistemRestricoes         := 'N';
                          BEGIN
                            SELECT 'S'
                              INTO vvExisteRestricaoPeloCodigo
                              FROM PCPROMOCAOPRACAMED
                             WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                               AND (CODPRACA       = vnCodPraca); -->> Pesquisa pelo Código
                          EXCEPTION
                            WHEN NO_DATA_FOUND THEN
                              BEGIN
                                SELECT 'S'
                                  INTO vvExistemRestricoes
                                  FROM PCPROMOCAOPRACAMED
                                 WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                                   AND (ROWNUM         = 1);
                              EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                  NULL;
                              END;
                          END;
                        
                          -- Se não pode comprar por Praça
                          IF (vvExisteRestricaoPeloCodigo = 'N') AND
                             (vvExistemRestricoes         = 'S') THEN
                          
                            vvRetPodeComprar := 'N - Restrição de Praça';
                            
                          ELSE
            
                            --------------------------------------------
                            -- Verifica Restrições por Ramo de Atividade
                            --------------------------------------------
                            vvExisteRestricaoPeloCodigo := 'N';
                            vvExistemRestricoes         := 'N';
                            BEGIN
                              SELECT 'S'
                                INTO vvExisteRestricaoPeloCodigo
                                FROM PCPROMOCAORAMOATIVMED
                               WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                                 AND (CODATIV        = vnCodAtv1); -->> Pesquisa pelo Código
                            EXCEPTION
                              WHEN NO_DATA_FOUND THEN
                                BEGIN
                                  SELECT 'S'
                                    INTO vvExistemRestricoes
                                    FROM PCPROMOCAORAMOATIVMED
                                   WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                                     AND (ROWNUM         = 1);
                                EXCEPTION
                                  WHEN NO_DATA_FOUND THEN
                                    NULL;
                                END;
                            END;
                            
                            -- Se não pode comprar por Ramo Atividade
                            IF (vvExisteRestricaoPeloCodigo = 'N') AND
                               (vvExistemRestricoes         = 'S') THEN
                            
                              vvRetPodeComprar := 'N - Restrição de Ramo Atividade';
                              
                            ELSE
            
                              ------------------------------------------
                              -- Verifica Restrições por Classe de Venda
                              ------------------------------------------
                              vvExisteRestricaoPeloCodigo := 'N';
                              vvExistemRestricoes         := 'N';
                              BEGIN
                                SELECT 'S'
                                  INTO vvExisteRestricaoPeloCodigo
                                  FROM PCPROMOCAOCLASSEVENDAMED
                                 WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                                   AND (CLASSEVENDA    = vvClasseVenda); -->> Pesquisa pelo Código
                              EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                  BEGIN
                                    SELECT 'S'
                                      INTO vvExistemRestricoes
                                      FROM PCPROMOCAOCLASSEVENDAMED
                                     WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                                       AND (ROWNUM         = 1);
                                  EXCEPTION
                                    WHEN NO_DATA_FOUND THEN
                                      NULL;
                                  END;
                              END;
  
                              -- Se não pode comprar por Classe Venda
                              IF (vvExisteRestricaoPeloCodigo = 'N') AND
                                 (vvExistemRestricoes         = 'S') THEN
                              
                                vvRetPodeComprar := 'N - Restrição de Classe de Venda';
                                
                              ELSE
                              
                                ------------------------------------------
                                -- Verifica Restrições por Grupo Comercial
                                ------------------------------------------
                                vvExisteRestricaoPeloCodigo := 'N';
                                vvExistemRestricoes         := 'N';
                                BEGIN
                                  SELECT 'S'
                                    INTO vvExisteRestricaoPeloCodigo
                                    FROM PCPROMOCAOGRUPOCOMERCMED
                                   WHERE (CODPROMOCAOMED       = pi_nCodPromocaoMed)
                                     AND (CODGRUPOCOMERCIALMED = vnCodGrupoComercialMed); -->> Pesquisa pelo Código
                                EXCEPTION
                                  WHEN NO_DATA_FOUND THEN
                                    BEGIN
                                      SELECT 'S'
                                        INTO vvExistemRestricoes
                                        FROM PCPROMOCAOGRUPOCOMERCMED
                                       WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                                         AND (ROWNUM         = 1);
                                    EXCEPTION
                                      WHEN NO_DATA_FOUND THEN
                                        NULL;
                                    END;
                                END;
                              
                                -- Se não pode comprar por Grupo Comercial
                                IF (vvExisteRestricaoPeloCodigo = 'N') AND
                                   (vvExistemRestricoes         = 'S') THEN
                                
                                  vvRetPodeComprar := 'N - Restrição de Grupo Comercial';
                                  
                                END IF;
                              
                              END IF; -- Fim Condição: Se não pode comprar por Classe Venda
  
                            
                              -- Se não pode comprar por Classe Venda ou Grupo Comercial
                              IF (vvExisteRestricaoPeloCodigo = 'N') AND
                                 (vvExistemRestricoes         = 'S') THEN
                              
                                vvRetPodeComprar := vvRetPodeComprar; -->> Mensagem de Classe Venda ou Grupo Comercial
                                
                              ELSE
            
                                ------------------------------------------
                                -- Verifica Restrições por Área de Atuação
                                ------------------------------------------
                                vvExisteRestricaoPeloCodigo := 'N';
                                vvExistemRestricoes         := 'N';
                                BEGIN
                                  SELECT 'S'
                                    INTO vvExisteRestricaoPeloCodigo
                                    FROM PCPROMOCAOAREAATUACAOMED
                                   WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                                     AND (AREAATUACAO    = vvAreaAtuacao); -->> Pesquisa pelo Código
                                EXCEPTION
                                  WHEN NO_DATA_FOUND THEN
                                    BEGIN
                                      SELECT 'S'
                                        INTO vvExistemRestricoes
                                        FROM PCPROMOCAOAREAATUACAOMED
                                       WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                                         AND (ROWNUM         = 1);
                                    EXCEPTION
                                      WHEN NO_DATA_FOUND THEN
                                        NULL;
                                    END;
                                END;
                              
                                -- Se não pode comprar por Classe Venda
                                IF (vvExisteRestricaoPeloCodigo = 'N') AND
                                   (vvExistemRestricoes         = 'S') THEN
                                
                                  vvRetPodeComprar := 'N - Restrição de Classe de Venda';
                                  
                                END IF; -- Fim Condição Se não pode comprar por Area da Atuação
                              
                              END IF; -- Fim Condição Se não pode comprar por Classe de Venda
                                            
                            END IF; -- Fim Condição Se não pode comprar por Ramo Atividade
                                          
                          END IF; -- Fim Condição Se não pode comprar por Praça
                        
                        END IF; -- Fim Condição Se não pode comprar por Condição de Venda
                        
                      END IF; -- Fim Condição Se não pode comprar por Supervisor
                      
                    END IF; -- Fim Condição Se não pode comprar por RCA
        
                  END IF; -- Fim Condição Se não pode comprar por Plano de Pagamento
        
                END IF; -- Fim Condição Se não pode comprar por Restrição de Rede
        
              END IF; -- Fim Condição Se não pode comprar por Restrição de Cliente
            
            END IF; -- Fim Condição Se não pode comprar por Restrição de Região
          
          END IF; -- Fim Condição Se não pode comprar por Restrição de Filial
  
        END IF; -- Fim Condição Se não pode comprar por Origem do Pedido
    
      END IF; -- Fim Condição Se não pode comprar por Vigência da Promoção
  
    END IF; -- Fim Condição Se usar as novas tabelas normalizadas
      
    -- Retorno
    RETURN vvRetPodeComprar;
  
  END F_PODECOMPRARPROMOCAO;
   
 /*******************************************************************************
  Nome         : F_MED_PODEGERARPROMOCAO
  Descricão    : Função para retornar se pode Gerar Carga da Promoção
  Parâmetros   : ENTRADA:
                 pi_nCodPromocaoMed   = Código da Promoção
                 pi_vCodFilial        = Código da Filial
                 pi_nNumRegiao        = Número da Região
                 pi_vOrigemPed        = Origem do Pedido
                 pi_nCodCondicaoVenda = Código da Condição de Venda
                 pi_nCodCli           = Código do Cliente
  Alteracão    : Anderson Silva - 28/03/2014 - HIS.02068.2016 - Criação da Função
  Alteração    : Anderson Silva - 11/05/2020 - DDMEDICA-2858 - Ajuste pesquisa promoção com cliente principal
  ********************************************************************************/
  FUNCTION F_MED_PODEGERARPROMOCAO(pi_nCodPromocaoMed   IN NUMBER,
                                   pi_vCodFilial        IN VARCHAR2,
                                   pi_nNumRegiao        IN NUMBER,                                                     
                                   pi_vOrigemPed        IN VARCHAR2,
                                   pi_nCodCondicaoVenda IN NUMBER,
                                   pi_nCodCli           IN NUMBER)
  RETURN VARCHAR2
  IS
  
    -- Retorno
    vvRetPodeGerar              VARCHAR2(200);  
    
    -- Dados da Promoção
    vvTipoPlanoPag              PCPROMOCAOMED.TIPOPLANOPAG%TYPE;
    vdDataInicial               PCPROMOCAOMED.DATAINICIAL%TYPE;
    vdDataFinal                 PCPROMOCAOMED.DATAFINAL%TYPE;
    vvUsaNormalizacaoDesc       PCPROMOCAOMED.USANORMALIZACAODESC%TYPE;
  
    -- Dados do Cliente
    vnCodPraca                  PCCLIENT.CODPRACA%TYPE;
    vvClasseVenda               PCCLIENT.CLASSEVENDA%TYPE;
    vnCodAtv1                   PCCLIENT.CODATV1%TYPE;
    vnCodRede                   PCCLIENT.CODREDE%TYPE; 
    vvUtilizaDescRede           PCPROMOCAOMED.UTILIZADESCREDE%TYPE;
        
    -- Verifição de Restrições
    vvExisteRestricaoPeloCodigo VARCHAR2(1);
    vvExistemRestricoes         VARCHAR2(1);
      
    -- Cliente Principal
    vnCodCliPrinc               PCCLIENT.CODCLIPRINC%TYPE;
      
  BEGIN
  
    -- Inicializa Retorno
    vvRetPodeGerar := 'S';
    
    -- Pesquisa Dados da Promoção
    BEGIN
      SELECT PCPROMOCAOMED.TIPOPLANOPAG
           , PCPROMOCAOMED.DATAINICIAL
           , PCPROMOCAOMED.DATAFINAL
           , PCPROMOCAOMED.USANORMALIZACAODESC
           , PCPROMOCAOMED.UTILIZADESCREDE
        INTO vvTipoPlanoPag
           , vdDataInicial
           , vdDataFinal
           , vvUsaNormalizacaoDesc
           , vvUtilizaDescRede
        FROM PCPROMOCAOMED
       WHERE (PCPROMOCAOMED.CODPROMOCAOMED = pi_nCodPromocaoMed);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvTipoPlanoPag        := NULL;
        vdDataInicial         := NULL;
        vdDataFinal           := NULL;
        vvUsaNormalizacaoDesc := NULL;
        vvUtilizaDescRede     := NULL;
    END;
    
   /***************************************** 
    Se utilizar as novas Tabelas Normalizadas
    *****************************************/
    IF (NVL(vvUsaNormalizacaoDesc,'N') = 'S') THEN
    
      --------------------------------
      -- Verifica Vigência da Promoção
      --------------------------------
      IF NOT ((TRUNC(SYSDATE) >= vdDataInicial) AND 
              (TRUNC(SYSDATE) <= vdDataFinal))  THEN
    
        vvRetPodeGerar := 'N - Vigência da Promoção';
              
      ELSE
          
        -------------------------------------------
        -- Verifica Restrições por Origem do Pedido
        ------------------------------------------
        vvExisteRestricaoPeloCodigo := 'N';
        vvExistemRestricoes         := 'N';
        BEGIN
          SELECT 'S'
            INTO vvExisteRestricaoPeloCodigo
            FROM PCPROMOCAOORIGEMMED
           WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
             AND (ORIGEMPED      = pi_vOrigemPed); -->> Pesquisa pelo Código
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            BEGIN
              SELECT 'S'
                INTO vvExistemRestricoes
                FROM PCPROMOCAOORIGEMMED
               WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                 AND (ROWNUM         = 1);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                NULL;
            END;
        END;
          
        -- Se não pode comprar por Restrição de Origem do Pedido
        IF (vvExisteRestricaoPeloCodigo = 'N') AND
           (vvExistemRestricoes         = 'S') THEN
          
          vvRetPodeGerar := 'N - Restrição de Origem do Pedido';
            
        ELSE
                
          ---------------------------------  
          -- Verifica Restrições por Filial
          ---------------------------------
          vvExisteRestricaoPeloCodigo := 'N';
          vvExistemRestricoes         := 'N';
          BEGIN
            SELECT 'S'
              INTO vvExisteRestricaoPeloCodigo
              FROM PCPROMOCAOFILMED
             WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
               AND (CODFILIAL      = pi_vCodFilial); -->> Pesquisa pelo Código
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              BEGIN
                SELECT 'S'
                  INTO vvExistemRestricoes
                  FROM PCPROMOCAOFILMED
                 WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                   AND (ROWNUM         = 1);
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  NULL;
              END;
          END;
          
          -- Se não pode gerar por Restrição de Filial
          IF (vvExisteRestricaoPeloCodigo = 'N') AND
             (vvExistemRestricoes         = 'S') THEN
          
            vvRetPodeGerar := 'N - Restrição de Filial';
            
          ELSE
          
            ---------------------------------
            -- Verifica Restrições por Região
            ---------------------------------
            vvExisteRestricaoPeloCodigo := 'N';
            vvExistemRestricoes         := 'N';
            BEGIN
              SELECT 'S'
                INTO vvExisteRestricaoPeloCodigo
                FROM PCPROMOCAOREGIAOMED
               WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                 AND (NUMREGIAO      = pi_nNumRegiao); -->> Pesquisa pelo Código
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                BEGIN
                  SELECT 'S'
                    INTO vvExistemRestricoes
                    FROM PCPROMOCAOREGIAOMED
                   WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                     AND (ROWNUM         = 1);
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    NULL;
                END;
            END;
            
            -- Se não pode gerar por Restrição de Região
            IF (vvExisteRestricaoPeloCodigo = 'N') AND
               (vvExistemRestricoes         = 'S') THEN
            
              vvRetPodeGerar := 'N - Restrição de Região';
              
            ELSE
            
              /***************************************
               SE VALIDAR RESTRIÇÃO A NÍVEL DE CLIENTE
               ***************************************/
               IF (NVL(pi_nCodCli,0) > 0) THEN
               
                  -- Pesquisa Dados do Cliente
                  BEGIN
                    SELECT PCCLIENT.CODPRACA
                         , PCCLIENT.CLASSEVENDA
                         , PCCLIENT.CODATV1
                         , PCCLIENT.CODREDE
                         , CASE WHEN (NVL(vvUtilizaDescRede,'N') = 'S') THEN
                             NVL(PCCLIENT.CODCLIPRINC,PCCLIENT.CODCLI)
                           ELSE
                             PCCLIENT.CODCLI
                           END COD_CLIENTE_PRINCIPAL -- DDMEDICA-2858
                      INTO vnCodPraca
                         , vvClasseVenda
                         , vnCodAtv1
                         , vnCodRede
                         , vnCodCliPrinc -- DDMEDICA-2858
                      FROM PCCLIENT
                     WHERE (PCCLIENT.CODCLI = pi_nCodCli);
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      vnCodPraca    := NULL;
                      vvClasseVenda := NULL;
                      vnCodAtv1     := NULL;
                      vnCodRede     := NULL;
                      vnCodCliPrinc := NULL; -- DDMEDICA-2858
                  END;
               
                  ----------------------------------
                  -- Verifica Restrições por Cliente
                  ----------------------------------
                  vvExisteRestricaoPeloCodigo := 'N';
                  vvExistemRestricoes         := 'N';
                  BEGIN
                    SELECT 'S'
                      INTO vvExisteRestricaoPeloCodigo
                      FROM PCPROMOCAOCLIMED
                     WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                       AND (CODCLI         IN (pi_nCodCli,vnCodCliPrinc)) -->> Pesquisa pelo Código do Cliente/Código do Cliente Principal
                       AND (ROWNUM         = 1);
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      BEGIN
                        SELECT 'S'
                          INTO vvExistemRestricoes
                          FROM PCPROMOCAOCLIMED
                         WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                           AND (ROWNUM         = 1);
                      EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                          NULL;
                      END;
                  END;
                  
                  -- Se não pode comprar por Restrição de Cliente
                  IF (vvExisteRestricaoPeloCodigo = 'N') AND
                     (vvExistemRestricoes         = 'S') THEN
                  
                    vvRetPodeGerar := 'N - Restrição de Cliente';
                    
                  ELSE
            
                    -------------------------------
                    -- Verifica Restrições por Rede
                    -------------------------------
                    vvExisteRestricaoPeloCodigo := 'N';
                    vvExistemRestricoes         := 'N';
                    BEGIN
                      SELECT 'S'
                        INTO vvExisteRestricaoPeloCodigo
                        FROM PCPROMOCAOREDEMED
                       WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                         AND (CODREDE        = vnCodRede); -->> Pesquisa pelo Código
                    EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                        BEGIN
                          SELECT 'S'
                            INTO vvExistemRestricoes
                            FROM PCPROMOCAOREDEMED
                           WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                             AND (ROWNUM         = 1);
                        EXCEPTION
                          WHEN NO_DATA_FOUND THEN
                            NULL;
                        END;
                    END;
                    
                    -- Se não pode comprar por Restrição de Rede
                    IF (vvExisteRestricaoPeloCodigo = 'N') AND
                       (vvExistemRestricoes         = 'S') THEN
                    
                      vvRetPodeGerar := 'N - Restrição de Rede de Clientes';
                      
                    ELSE
                    
                      --------------------------------------------
                      -- Verifica Restrições por Ramo de Atividade
                      --------------------------------------------
                      vvExisteRestricaoPeloCodigo := 'N';
                      vvExistemRestricoes         := 'N';
                      BEGIN
                        SELECT 'S'
                          INTO vvExisteRestricaoPeloCodigo
                          FROM PCPROMOCAORAMOATIVMED
                         WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                           AND (CODATIV        = vnCodAtv1); -->> Pesquisa pelo Código
                      EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                          BEGIN
                            SELECT 'S'
                              INTO vvExistemRestricoes
                              FROM PCPROMOCAORAMOATIVMED
                             WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                               AND (ROWNUM         = 1);
                          EXCEPTION
                            WHEN NO_DATA_FOUND THEN
                              NULL;
                          END;
                      END;
                      
                      -- Se não pode comprar por Ramo Atividade
                      IF (vvExisteRestricaoPeloCodigo = 'N') AND
                         (vvExistemRestricoes         = 'S') THEN
                      
                        vvRetPodeGerar := 'N - Restrição de Ramo Atividade';
                        
                      ELSE
            
                        ------------------------------------------
                        -- Verifica Restrições por Classe de Venda
                        ------------------------------------------
                        vvExisteRestricaoPeloCodigo := 'N';
                        vvExistemRestricoes         := 'N';
                        BEGIN
                          SELECT 'S'
                            INTO vvExisteRestricaoPeloCodigo
                            FROM PCPROMOCAOCLASSEVENDAMED
                           WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                             AND (CLASSEVENDA    = vvClasseVenda); -->> Pesquisa pelo Código
                        EXCEPTION
                          WHEN NO_DATA_FOUND THEN
                            BEGIN
                              SELECT 'S'
                                INTO vvExistemRestricoes
                                FROM PCPROMOCAOCLASSEVENDAMED
                               WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed)
                                 AND (ROWNUM         = 1);
                            EXCEPTION
                              WHEN NO_DATA_FOUND THEN
                                NULL;
                            END;
                        END;
                      
                        -- Se não pode comprar por Classe Venda
                        IF (vvExisteRestricaoPeloCodigo = 'N') AND
                           (vvExistemRestricoes         = 'S') THEN
                        
                          vvRetPodeGerar := 'N - Restrição de Classe de Venda';
                          
                        END IF; -- Fim Condição Se não pode gerar por Classe de Venda
                    
                      END IF; -- Fim Condição Se não pode gerar por Ramo de Atividade
                      
                    END IF; -- Fim Condição Se não pode gerar por Restrição de Rede
          
                 END IF; -- Fim Condição Se não pode gerar por Restrição de Cliente
               
               END IF; -- FIM CONDIÇÃO: SE VALIDAR RESTRIÇÃO A NÍVEL DE CLIENTE
                      
            END IF; -- Fim Condição Se não pode gerar por Restrição de Região
          
          END IF; -- Fim Condição Se não pode gerar por Restrição de Filial
  
        END IF; -- Fim Condição Se não pode gerar por Restrição de Origem do Pedido
    
      END IF; -- Fim Condição Se não pode gerar por Vigência da Promoção
  
    END IF; -- Fim Condição Se usar as novas tabelas normalizadas
      
    -- Retorno
    RETURN vvRetPodeGerar;
  
  END F_MED_PODEGERARPROMOCAO;
   
  /*******************************************************************************
   Nome         : F_PROMOCAORESULTADOCAB
   Descricão    : Função para retornar o Resultado da Promoção - Cabeçalho
   Alteracão    : Anderson Silva - 24/06/2017 - Criação da Função
   Alteracão    : Anderson Silva - 24/06/2018 - Promoção por Faixa de Qtde. com Valor Mínimo - MED_VLMIN_FXQ 
   Alteracão    : Anderson Silva - 02/11/2019 - DDMEDICA-1212 - Permitir Qtde. Mín. sem Obrigatório   
   Alteração    : Anderson Silva - 09/062020 - DDMEDICA-3103   Múltiplos Brindes na Campanha com Brindes Fixos 
  ********************************************************************************/
  FUNCTION F_PROMOCAORESULTADOCAB(pi_nSaldoAtualContaCorrente IN NUMBER DEFAULT NULL)
  RETURN TABELA_MED_PROMOCAORESULTCAB
  PARALLEL_ENABLE
  PIPELINED IS
  
    -- Tipo Objeto
    OUTROW TIPO_MED_PROMOCAORESULTADOCAB := TIPO_MED_PROMOCAORESULTADOCAB(NULL, -- CODPROMOCAOMED
                                                                          NULL, -- DESCRICAOPROMOCAO
                                                                          NULL, -- TIPOPROMOCAO
                                                                          NULL, -- TIPOVALIDAVALORMIN
                                                                          NULL, -- TIPOCONCESSAOBRINDE
                                                                          NULL, -- MINIMOPEDIDO
                                                                          NULL, -- TEXTO_MINIMOPEDIDO
                                                                          NULL, -- ATINGIDOPEDIDO
                                                                          NULL, -- TEXTO_ATINGIDOPEDIDO
                                                                          NULL, -- BRINDESCONCESSAO
                                                                          NULL, -- TEXTO_BRINDESCONCESSAO
                                                                          NULL, -- BRINDESCONCEDIDOS
                                                                          NULL, -- TEXTO_BRINDESCONCEDIDOS
                                                                          NULL, -- MULTIPLOSBRINDES
                                                                          NULL, -- REGRA
                                                                          NULL, -- BRINDESCONCEDIDOS_ALERTA
                                                                          NULL, -- QTDEVENDIDA_ALERTA
                                                                          NULL, -- ITENSNAOVENDIDOS_OBRIGATORIO
                                                                          NULL, -- MULTIPLICADOR
                                                                          NULL  -- PROMOCAOCAMPANHAVALIDA
                                                                           );
  
    -- Variáveis Auxiliares
    nATINGIDOPEDIDO               NUMBER;
    nBRINDESCONCESSAO             NUMBER;
    nSKUSCONCESSAO                NUMBER;
    nBRINDESCONCEDIDOS            NUMBER;
    nBRINDESCONCEDIDOS_ALERTA     NUMBER;
    nQTDEVENDIDA_ALERTA           NUMBER;
    nITENSNAOVENDIDOS_OBRIGATORIO NUMBER;
    --
    vTEXTO_MINIMOPEDIDO           VARCHAR2(30);
    vTEXTO_ATINGIDOPEDIDO         VARCHAR2(30);
    --
    vTEXTO_BRINDESCONCESSAO       VARCHAR2(30);
    vTEXTO_BRINDESCONCEDIDOS      VARCHAR2(30);
    --
    nMULTIPLICADOR                NUMBER;
    --
    vPROMOCAOCAMPANHAVALIDA       VARCHAR2(1);
    --
    nITENS_OBRIGATORIOS           NUMBER;
    -- 
    vACEITADESCPROMCAMPANHA       VARCHAR2(1);
    --
    vREGRA                        VARCHAR2(500);
    -- Controle de Conta-Corrente do RCA
    vnValorAbaterSaldoRca         NUMBER;
  
  BEGIN
  
    ----------------------------------------------------------------------------
    -- CARREGA TABLE -----------------------------------------------------------
    ----------------------------------------------------------------------------
  
    FOR vc_Promocao IN (SELECT SEL
                             , CODPROMOCAOMED
                             , DESCRICAOPROMOCAO
                             , TIPOPROMOCAO
                             , TIPOVALIDAVALORMIN
                             , TIPOCONCESSAOBRINDE
                             , MINIMOPEDIDO
                             , BRINDESCONCESSAO
                             , MULTIPLOSBRINDES
                             , ACEITADESCPROMCAMPANHA
                          FROM PCMED_PROMOCAO_CAMPANHA) LOOP
  
     /************************************************************************************************
                                     PRIMEIRA PARTE - TOTALIZA VALORES
      ************************************************************************************************/
  
  
      -----------------------------------------------------------------------------------------------
      -- Valor Atingindo no Pedido
      ----------------------------
  
      nATINGIDOPEDIDO := 0;
  
      -- Validação Valor Mínimo
      IF ((vc_Promocao.TIPOPROMOCAO = 'N') AND (vc_Promocao.TIPOVALIDAVALORMIN = 'V')) OR
          ((vc_Promocao.TIPOPROMOCAO IN ('V','F'))) THEN -- MED_VLMIN_FXQ - Adicionado 'F'
  
        -- Totaliza o Valor Total Líquido Vendido do Mix
        SELECT SUM(NVL(PCMED_PROMOCAO_CAMPANHA_MIX.VALORLIQUIDO,0))
          INTO nATINGIDOPEDIDO
          FROM PCMED_PROMOCAO_CAMPANHA_MIX
         WHERE (PCMED_PROMOCAO_CAMPANHA_MIX.CODPROMOCAOMEDREF = vc_Promocao.CODPROMOCAOMED);
  
      -- Validação Mix
      ELSIF ((vc_Promocao.TIPOPROMOCAO = 'N') AND (vc_Promocao.TIPOVALIDAVALORMIN = 'M')) OR
            ((vc_Promocao.TIPOPROMOCAO = 'M')) THEN
  
        -- Totaliza a Quantidade de SKus Vendidos
        SELECT COUNT(DISTINCT PCMED_PROMOCAO_CAMPANHA_MIX.CODPROD)
          INTO nATINGIDOPEDIDO
          FROM PCMED_PROMOCAO_CAMPANHA_MIX
         WHERE (PCMED_PROMOCAO_CAMPANHA_MIX.CODPROMOCAOMEDREF = vc_Promocao.CODPROMOCAOMED)
           AND (PCMED_PROMOCAO_CAMPANHA_MIX.QTDEVENDIDA > 0);
  
      -- Validação Quantidade Total
      ELSIF ((vc_Promocao.TIPOPROMOCAO = 'N') AND (vc_Promocao.TIPOVALIDAVALORMIN = 'Q')) THEN
  
        -- Totaliza a Quantidade Vendida do Mix
        SELECT SUM(NVL(PCMED_PROMOCAO_CAMPANHA_MIX.QTDEVENDIDA,0))
          INTO nATINGIDOPEDIDO
          FROM PCMED_PROMOCAO_CAMPANHA_MIX
         WHERE (PCMED_PROMOCAO_CAMPANHA_MIX.CODPROMOCAOMEDREF = vc_Promocao.CODPROMOCAOMED);
  
      -- Sem Validação, mas precisa mostrar o Valor Atingido (Brinde em % sobre a Venda)
      ELSIF ((vc_Promocao.TIPOPROMOCAO = 'N') AND (vc_Promocao.TIPOVALIDAVALORMIN = 'S') AND (vc_Promocao.TIPOCONCESSAOBRINDE = '3')) THEN
  
        -- Totaliza o Valor Total Líquido Vendido do Mix
        SELECT SUM(NVL(PCMED_PROMOCAO_CAMPANHA_MIX.VALORLIQUIDO,0))
          INTO nATINGIDOPEDIDO
          FROM PCMED_PROMOCAO_CAMPANHA_MIX
         WHERE (PCMED_PROMOCAO_CAMPANHA_MIX.CODPROMOCAOMEDREF = vc_Promocao.CODPROMOCAOMED);
  
      -- Sem Validação, mas precisa mostrar a quantidade de unidades atingidas (Brinde em Unidades )
      ELSIF ((vc_Promocao.TIPOPROMOCAO = 'N') AND (vc_Promocao.TIPOVALIDAVALORMIN = 'S') AND (vc_Promocao.TIPOCONCESSAOBRINDE IN ('1','2'))) THEN
  
        -- Totaliza a Quantidade Vendida do Mix
        SELECT SUM(NVL(PCMED_PROMOCAO_CAMPANHA_MIX.QTDEVENDIDA,0))
          INTO nATINGIDOPEDIDO
          FROM PCMED_PROMOCAO_CAMPANHA_MIX
         WHERE (PCMED_PROMOCAO_CAMPANHA_MIX.CODPROMOCAOMEDREF = vc_Promocao.CODPROMOCAOMED);
  
      END IF;
  
      -----------------------------------------------------------------------------------------------
      -- Qtde. de Brindes para Concessão
      ----------------------------------
  
      nBRINDESCONCESSAO := 0;
      nSKUSCONCESSAO    := NULL;
  
      -- Concede Brindes em Quantidade - Quantidade Fixa informada no Cabeçalho da Promoção
      IF    ((vc_Promocao.TIPOPROMOCAO = 'N') AND (vc_Promocao.TIPOCONCESSAOBRINDE IN (1))) THEN
  
        -- Quantidade informada no Cabeçalho da Promoção
        nBRINDESCONCESSAO := vc_Promocao.BRINDESCONCESSAO;
  
      -- Concede Brindes em Quantidade - Quantidade Fixa informada nos Brindes da Promoção
      ELSIF ((vc_Promocao.TIPOPROMOCAO = 'N') AND (vc_Promocao.TIPOCONCESSAOBRINDE IN (2))) THEN
  
        -- Quantidade informada por Brinde (Qtde. Fixa)
        --DDMEDICA-3103--nBRINDESCONCESSAO := vc_Promocao.BRINDESCONCESSAO;
        SELECT SUM(QTDEBRINDES)
          INTO nBRINDESCONCESSAO
          FROM PCMED_PROMOCAO_CAMPANHA_BRI
         WHERE (PCMED_PROMOCAO_CAMPANHA_BRI.CODPROMOCAOMEDREF = vc_Promocao.CODPROMOCAOMED);
  
        -- Qtde de Produtos Brinde (SKUs)
        SELECT COUNT(*)
          INTO nSKUSCONCESSAO
          FROM PCMED_PROMOCAO_CAMPANHA_BRI
         WHERE (PCMED_PROMOCAO_CAMPANHA_BRI.CODPROMOCAOMEDREF = vc_Promocao.CODPROMOCAOMED);
  
      -- Concede Brindes em Valor multiplicado pelo % Informado no Cabeçalho da Promoção
      ELSIF ((vc_Promocao.TIPOPROMOCAO = 'N') AND (vc_Promocao.TIPOCONCESSAOBRINDE IN (3))) THEN
  
        -- Totaliza o Valor Total Vendido do MIX  multiplicando o resultado pelo % Informado no Cabeçalho da Promoção
        SELECT ROUND(SUM(NVL(PCMED_PROMOCAO_CAMPANHA_MIX.VALORLIQUIDO,0)) * (NVL(vc_Promocao.BRINDESCONCESSAO,0) / 100),2)
          INTO nBRINDESCONCESSAO
          FROM PCMED_PROMOCAO_CAMPANHA_MIX
         WHERE (PCMED_PROMOCAO_CAMPANHA_MIX.CODPROMOCAOMEDREF = vc_Promocao.CODPROMOCAOMED);
  
      END IF;
  
      -----------------------------------------------------------------------------------------------
      -- Qtde. de Itens Obrigatórios
      ------------------------------
  
      SELECT COUNT(*)
        INTO nITENS_OBRIGATORIOS
        FROM PCMED_PROMOCAO_CAMPANHA_MIX
       WHERE (PCMED_PROMOCAO_CAMPANHA_MIX.CODPROMOCAOMEDREF = vc_Promocao.CODPROMOCAOMED)
         AND (PCMED_PROMOCAO_CAMPANHA_MIX.OBRIGATORIO = 'S');
  
      -----------------------------------------------------------------------------------------------
      -- Qtde. de Brindes Concedidos
      ------------------------------
  
      nBRINDESCONCEDIDOS := 0;
  
      -- Concede Brindes em Quantidade
      IF    ((vc_Promocao.TIPOPROMOCAO = 'N') AND (vc_Promocao.TIPOCONCESSAOBRINDE IN (1,2))) THEN
  
        -- Totaliza a Quantidade de Brindes Concedidos
        SELECT SUM(PCMED_PROMOCAO_CAMPANHA_BRI.QTDEBRINDES)
          INTO nBRINDESCONCEDIDOS
          FROM PCMED_PROMOCAO_CAMPANHA_BRI
         WHERE (PCMED_PROMOCAO_CAMPANHA_BRI.CODPROMOCAOMEDREF = vc_Promocao.CODPROMOCAOMED);
  
      -- Concede Brindes em Valor
      ELSIF ((vc_Promocao.TIPOPROMOCAO = 'N') AND (vc_Promocao.TIPOCONCESSAOBRINDE IN (3))) THEN
  
        -- Totaliza o Valor de Brindes Concedidos
        SELECT SUM(NVL(PCMED_PROMOCAO_CAMPANHA_BRI.QTDEBRINDES,0) * NVL(PCMED_PROMOCAO_CAMPANHA_BRI.PRECOTABELA,0))
          INTO nBRINDESCONCEDIDOS
          FROM PCMED_PROMOCAO_CAMPANHA_BRI
          WHERE (PCMED_PROMOCAO_CAMPANHA_BRI.CODPROMOCAOMEDREF = vc_Promocao.CODPROMOCAOMED);
  
      END IF;
  
      -----------------------------------------------------------------------------------------------
      -- Qtde. de Brindes Concedidos com Alerta
      -----------------------------------------
  
      nBRINDESCONCEDIDOS_ALERTA := 0;
  
      -- Totaliza a Quantidade de Brindes Selecionados com Alerta
      IF (vc_Promocao.TIPOPROMOCAO = 'N') THEN
  
        SELECT SUM(PCMED_PROMOCAO_CAMPANHA_BRI.QTDEBRINDES)
         INTO nBRINDESCONCEDIDOS_ALERTA
         FROM PCMED_PROMOCAO_CAMPANHA_BRI
        WHERE (PCMED_PROMOCAO_CAMPANHA_BRI.CODPROMOCAOMEDREF = vc_Promocao.CODPROMOCAOMED)
          AND (PCMED_PROMOCAO_CAMPANHA_BRI.ALERTA IN ('S','R')) -- DDVENDAS-38166
          AND (PCMED_PROMOCAO_CAMPANHA_BRI.QTDEBRINDES > 0);
  
       END IF;
  
      -----------------------------------------------------------------------------------------------
      -- Qtde. Vendida com Alerta
      ---------------------------
  
      -- Totaliza a Quantidade Vendida com Alerta
      SELECT SUM(PCMED_PROMOCAO_CAMPANHA_MIX.QTDEVENDIDA)
        INTO nQTDEVENDIDA_ALERTA
        FROM PCMED_PROMOCAO_CAMPANHA_MIX
       WHERE (PCMED_PROMOCAO_CAMPANHA_MIX.CODPROMOCAOMEDREF = vc_Promocao.CODPROMOCAOMED)
         AND (PCMED_PROMOCAO_CAMPANHA_MIX.ALERTA = 'S')
         AND (PCMED_PROMOCAO_CAMPANHA_MIX.QTDEVENDIDA > 0);
  
      -----------------------------------------------------------------------------------------------
      -- Qtde. de Itens que não atingiu a Qtde. Mínima dos Obrigatórios
      -----------------------------------------------------------------
  
      -- Totaliza a Qtde de Itens que não atingiu a Qtde Mínima dos Obrigatórios
      SELECT COUNT(*)
        INTO nITENSNAOVENDIDOS_OBRIGATORIO
        FROM PCMED_PROMOCAO_CAMPANHA_MIX
       WHERE (PCMED_PROMOCAO_CAMPANHA_MIX.CODPROMOCAOMEDREF = vc_Promocao.CODPROMOCAOMED)
         AND ( ((NVL(PCMED_PROMOCAO_CAMPANHA_MIX.OBRIGATORIO,'N') = 'S') AND (NVL(PCMED_PROMOCAO_CAMPANHA_MIX.QTDEVENDIDA,0) < NVL(PCMED_PROMOCAO_CAMPANHA_MIX.QTDEMINIMA,0))) OR
                ((NVL(PCMED_PROMOCAO_CAMPANHA_MIX.OBRIGATORIO,'N') <> 'S') AND (NVL(PCMED_PROMOCAO_CAMPANHA_MIX.QTDEVENDIDA,0) > 0) AND (NVL(PCMED_PROMOCAO_CAMPANHA_MIX.QTDEVENDIDA,0) < NVL(PCMED_PROMOCAO_CAMPANHA_MIX.QTDEMINIMA,0)))  );
  
      -----------------------------------------------------------------------------------------------
      -- Brindes para Concessão - MULTIPLOS BRINDES
      ---------------------------------------------
  
      -- Calcula o Multiplicador nas Campanhas com MÃºltiplos Brindes
      IF  (vc_Promocao.TIPOPROMOCAO = 'N')  AND
          (NVL(vc_Promocao.MULTIPLOSBRINDES,'N') = 'S') AND
          (vc_Promocao.TIPOCONCESSAOBRINDE IN (1)) AND
          (NVL(vc_Promocao.MINIMOPEDIDO,0) > 0)         THEN
        nMULTIPLICADOR := FLOOR(NVL(nATINGIDOPEDIDO,0) / NVL(vc_Promocao.MINIMOPEDIDO,0));
      ELSE
        nMULTIPLICADOR := 1;
      END IF;
  
      -- Brindes para Concessão - Multiplica a Qtde de Brindes pela qtde. de vezes que bateu a meta
      nBRINDESCONCESSAO :=  (NVL(nBRINDESCONCESSAO,0) * nMULTIPLICADOR);
  
  
     /************************************************************************************************
                                      SEGUNDA PARTE - VALIDAÇÃO DA PROMOÇÃO
      ************************************************************************************************/
  
  
  
      vPROMOCAOCAMPANHAVALIDA := NULL;
  
      -- Se teve venda do Mix e ainda não atingiu a Qtde Mínima dos Itens Obrigatórios
      IF (NVL(nATINGIDOPEDIDO,0) > 0) AND
         (NVL(nITENSNAOVENDIDOS_OBRIGATORIO,0) > 0) THEN
  
        -- Ocorrência de Obrigatórios não atendidos
        vPROMOCAOCAMPANHAVALIDA := 'O';
  
      ELSE
  
        -- Se Promoção de Mix/Valor OU Promoção de Campanha com Validação de Mix/Valor/Quantidade e não Atingiu Mínimo
        IF    ((NVL(vc_Promocao.TIPOPROMOCAO,'C') IN ('M','V','F')) OR -- MED_VLMIN_FXQ - Adicionado 'F'
               ((NVL(vc_Promocao.TIPOPROMOCAO,'C') IN ('N')) AND (NVL(vc_Promocao.TIPOVALIDAVALORMIN,'N') IN ('M','V','Q')))) AND
              (NVL(nATINGIDOPEDIDO,0) > 0) AND
              (NVL(nATINGIDOPEDIDO,0) < NVL(vc_Promocao.MINIMOPEDIDO,0)) THEN
  
          -- Ocorrência Itens Vendidos mas sem Atingir o Mínimo
          vPROMOCAOCAMPANHAVALIDA := 'M';
  
        ELSIF (NVL(vc_Promocao.TIPOPROMOCAO,'C') IN ('M','V','F')) OR -- MED_VLMIN_FXQ - Adicionado 'F'
              ((NVL(vc_Promocao.TIPOPROMOCAO,'C') IN ('N')) AND (NVL(vc_Promocao.TIPOVALIDAVALORMIN,'N') IN ('M','V','Q'))) AND
              (NVL(nATINGIDOPEDIDO,0) > 0) AND
              (NVL(nATINGIDOPEDIDO,0) >= NVL(vc_Promocao.MINIMOPEDIDO,0)) THEN
  
          -- PROMOÇÃO VÃLIDA
          vPROMOCAOCAMPANHAVALIDA := 'S';
  
        ELSIF ((NVL(vc_Promocao.TIPOPROMOCAO,'C') IN ('N')) AND (NVL(vc_Promocao.TIPOVALIDAVALORMIN,'N') = 'S')) AND
              (NVL(nATINGIDOPEDIDO,0) > 0) THEN
  
          -- PROMOÇÃO VÃLIDA QUANDO NÃƒO USA VALIDAÇÃO DE VALOR MÃNIMO NA CAMPANHA DE BONIFICAÇÃO (SE VENDEU AO MENOS UMA UNIDADE DO MIX)
          vPROMOCAOCAMPANHAVALIDA := 'S';
  
        END IF; -- Fim Condição Se Promoção de Mix/Valor OU Promoção de Campanha com Validação de Mix/Valor e não Atingiu Mínimo
  
      END IF; -- Fim Condição Se possui não atingiu a Qtde Mínima dos Itens Obrigatórios
  
      -- Se tem Problemas de Alerta
      IF (NVL(nBRINDESCONCEDIDOS_ALERTA,0) > 0) OR
         (NVL(nQTDEVENDIDA_ALERTA,0) > 0)       THEN
  
        -- Se Selecionou a Promoção
        IF (NVL(vc_Promocao.SEL,'N') = 'S') THEN
          -- Ocorrência de Alerta
          vPROMOCAOCAMPANHAVALIDA := 'A';
        END IF;
  
      ELSE
  
        -- Se os Brindes informados ultrapasserem os Brindes
        -->> IMPORTANTE: Somente mudar o Retorno se chegou a liberar os brindes, porque o usuário pode escolher os brindes antes de alcançar a meta
        IF (NVL(nBRINDESCONCESSAO,0) > 0) AND -->> Só se Liberou os Brindes
           (NVL(nBRINDESCONCEDIDOS,0) > NVL(nBRINDESCONCESSAO,0)) THEN
  
          -- Se Selecionou a Promoção
          IF (NVL(vc_Promocao.SEL,'N') = 'S') THEN
            -- Ocorrência de Alerta
            vPROMOCAOCAMPANHAVALIDA := 'U';
          END IF;
  
        END IF; -- Fim Condição Se tem Problemas de Alerta
  
      END IF; -- Fim Condição Se tem Problemas de Alerta
  
  
     /************************************************************************************************
                                     TERCEIRA PARTE - VALIDAÇÃO DO CONTA-CORRENTE
      ************************************************************************************************/
  
      -- Totaliza o Valor de Brindes Concedidos para validação da Base do RCA em todas as Promoções
      -- que estão com Qtde de Brindes Concedidos
      SELECT SUM(NVL(PCMED_PROMOCAO_CAMPANHA_BRI.QTDEBRINDES,0) * NVL(PCMED_PROMOCAO_CAMPANHA_BRI.PRECOTABELA,0))
        INTO vnValorAbaterSaldoRca
        FROM PCMED_PROMOCAO_CAMPANHA_BRI
           , PCMED_PROMOCAO_CAMPANHA
           , PCPROMOCAOMED
           , PCTIPOBONIFIC
       WHERE (PCMED_PROMOCAO_CAMPANHA.CODPROMOCAOMED = PCMED_PROMOCAO_CAMPANHA_BRI.CODPROMOCAOMEDREF)
         AND (PCPROMOCAOMED.CODPROMOCAOMED           = PCMED_PROMOCAO_CAMPANHA.CODPROMOCAOMED)
         AND (PCTIPOBONIFIC.CODBNF                   = PCPROMOCAOMED.CODBNF)
         AND (PCMED_PROMOCAO_CAMPANHA.SEL            = 'S') -->> SOMENTE PROMOÇÕES SELECIONADAS
         AND (PCTIPOBONIFIC.MOVIMENTACCRCA           = 'S');
  
      -- Se vai Movimentar o Conta-Corrente do RCA
      IF (NVL(vnValorAbaterSaldoRca,0) > 0) THEN
        -- Se não tiver Saldo Disponível (testar o valor absoluto porque o débito é negativo)
        IF (NVL(vnValorAbaterSaldoRca,0) > NVL(pi_nSaldoAtualContaCorrente,0)) THEN
          -- Ocorrência de Saldo Indisponível no Conta-Corrente do RCA
          vPROMOCAOCAMPANHAVALIDA := 'C';
        END IF;
      END IF;
  
  
     /************************************************************************************************
                                        QUARTA PARTE - FORMATA VALORES
      ************************************************************************************************/
  
  
      -----------------------------------------------------------------------------------------------
      -- Texto informativo do Mínimo do Pedido
      ----------------------------------------
  
      vTEXTO_MINIMOPEDIDO := NULL;
  
      -- Validação Valor Mínimo
      IF     ((vc_Promocao.TIPOPROMOCAO = 'N') AND (vc_Promocao.TIPOVALIDAVALORMIN = 'V')) OR
             ((vc_Promocao.TIPOPROMOCAO IN ('V','F'))) THEN -- MED_VLMIN_FXQ - Adicionado 'F'
        vTEXTO_MINIMOPEDIDO := 'R$ ' || TRIM(TO_CHAR(NVL(vc_Promocao.MINIMOPEDIDO,0), '999G999G999G990D00', 'NLS_NUMERIC_CHARACTERS = '',.'''));
      -- Validação Mix ou Quantidade Mínima
      ELSIF ((vc_Promocao.TIPOPROMOCAO = 'N') AND (vc_Promocao.TIPOVALIDAVALORMIN IN ('M','Q'))) OR
            ((vc_Promocao.TIPOPROMOCAO = 'M')) THEN
        vTEXTO_MINIMOPEDIDO := TRIM(TO_CHAR(NVL(vc_Promocao.MINIMOPEDIDO,0), '999G999G999G990', 'NLS_NUMERIC_CHARACTERS = '',.'''));
      END IF;
  
      -----------------------------------------------------------------------------------------------
      -- Texto informativo do Atingido do Pedido
      ------------------------------------------
  
      vTEXTO_ATINGIDOPEDIDO := NULL;
  
      -- Validação Valor Mínimo
      IF     ((vc_Promocao.TIPOPROMOCAO = 'N') AND (vc_Promocao.TIPOVALIDAVALORMIN = 'V')) OR
             ((vc_Promocao.TIPOPROMOCAO = 'N') AND (vc_Promocao.TIPOVALIDAVALORMIN = 'S') AND (vc_Promocao.TIPOCONCESSAOBRINDE = '3')) OR -- Mostra o Atingido em Valor se não houver Validação de Mínimo mas o Brinde ser % sobre a Venda
             ((vc_Promocao.TIPOPROMOCAO IN ('V','F'))) THEN -- MED_VLMIN_FXQ - Adicionado 'F'
        vTEXTO_ATINGIDOPEDIDO := 'R$ ' || TRIM(TO_CHAR(NVL(nATINGIDOPEDIDO,0), '999G999G999G990D00', 'NLS_NUMERIC_CHARACTERS = '',.'''));
      -- Validação Mix ou Quantidade Mínima
      ELSIF ((vc_Promocao.TIPOPROMOCAO = 'N') AND (vc_Promocao.TIPOVALIDAVALORMIN IN ('M','Q'))) OR
             ((vc_Promocao.TIPOPROMOCAO = 'N') AND (vc_Promocao.TIPOVALIDAVALORMIN = 'S') AND (vc_Promocao.TIPOCONCESSAOBRINDE IN ('1','2'))) OR -- Mostra o Atingido em Unidades se não houver Validação de Mínimo mas o Brinde ser em Unidades
            ((vc_Promocao.TIPOPROMOCAO = 'M')) THEN
        vTEXTO_ATINGIDOPEDIDO := TRIM(TO_CHAR(NVL(nATINGIDOPEDIDO,0), '999G999G999G990', 'NLS_NUMERIC_CHARACTERS = '',.'''));
      END IF;
  
      -----------------------------------------------------------------------------------------------
      -- Texto informativo dos Brindes para Concessão
      -----------------------------------------------
  
      vTEXTO_BRINDESCONCESSAO := NULL;
  
      -- *** SE CAMPANHA VALIDA ***
      IF (NVL(vPROMOCAOCAMPANHAVALIDA,'N') = 'S') THEN
  
        -- Concede Brindes em Quantidade - Quantidade Fixa informada no Cabeçalho da Promoção
        IF    ((vc_Promocao.TIPOPROMOCAO = 'N') AND (vc_Promocao.TIPOCONCESSAOBRINDE IN (1))) THEN
  
          vTEXTO_BRINDESCONCESSAO := TRIM(TO_CHAR(nBRINDESCONCESSAO, '999G999G999G990', 'NLS_NUMERIC_CHARACTERS = '',.'''));
  
        -- Concede Brindes em Quantidade - Quantidade Fixa informada nos Brindes da Promoção
        ELSIF ((vc_Promocao.TIPOPROMOCAO = 'N') AND (vc_Promocao.TIPOCONCESSAOBRINDE IN (2))) THEN
  
          vTEXTO_BRINDESCONCESSAO :=    TRIM(TO_CHAR(NVL(nBRINDESCONCESSAO,0), '999G999G999G990', 'NLS_NUMERIC_CHARACTERS = '',.'''));
  
        -- Concede Brindes em Valor
        ELSIF ((vc_Promocao.TIPOPROMOCAO = 'N') AND (vc_Promocao.TIPOCONCESSAOBRINDE IN (3))) THEN
  
          vTEXTO_BRINDESCONCESSAO := 'R$ ' || TRIM(TO_CHAR(NVL(nBRINDESCONCESSAO,0), '999G999G999G990D00', 'NLS_NUMERIC_CHARACTERS = '',.'''));
  
        END IF;
  
      END IF;
  
      -----------------------------------------------------------------------------------------------
      -- Texto informativo dos Brindes Concedidos
      -------------------------------------------
  
      vTEXTO_BRINDESCONCEDIDOS := NULL;
  
      -- Concede Brindes em Quantidade
      IF     ((vc_Promocao.TIPOPROMOCAO = 'N') AND (vc_Promocao.TIPOCONCESSAOBRINDE IN (1,2))) THEN
  
        vTEXTO_BRINDESCONCEDIDOS := TRIM(TO_CHAR(NVL(nBRINDESCONCEDIDOS,0), '999G999G999G990', 'NLS_NUMERIC_CHARACTERS = '',.'''));
  
      -- Concede Brindes em Valor
      ELSIF ((vc_Promocao.TIPOPROMOCAO = 'N') AND (vc_Promocao.TIPOCONCESSAOBRINDE IN (3))) THEN
  
        vTEXTO_BRINDESCONCEDIDOS := 'R$ ' || TRIM(TO_CHAR(NVL(nBRINDESCONCEDIDOS,0), '999G999G999G990D00', 'NLS_NUMERIC_CHARACTERS = '',.'''));
  
      END IF;
  
      -----------------------------------------------------------------------------------------------
      -- Texto informativo da Regra da Campanha
      -----------------------------------------
  
      vREGRA := NULL;
  
      -- Tipo de Promoção/Campanha
      IF    (vc_Promocao.TIPOPROMOCAO = 'M') THEN
        vREGRA := 'Promoção por Mix (SKUs)';
      ELSIF (vc_Promocao.TIPOPROMOCAO = 'V') THEN
        vREGRA := 'Promoção de Valor Mínimo';
      -- MED_VLMIN_FXQ - Validação Valor Mínimo para Promoções por Faixa de Quantidade 
      ELSIF (vc_Promocao.TIPOPROMOCAO = 'F') THEN
        vREGRA := 'Promoção por Intervalo Qtde. com Valor Mínimo';
      ELSIF (vc_Promocao.TIPOPROMOCAO = 'N') THEN
        IF    (vc_Promocao.TIPOVALIDAVALORMIN = 'M') THEN
          vREGRA := 'Campanha por Mix (SKUs)';
        ELSIF (vc_Promocao.TIPOVALIDAVALORMIN = 'V') THEN
          vREGRA := 'Campanha por Valor Mínimo';
        ELSIF (vc_Promocao.TIPOVALIDAVALORMIN = 'Q') THEN
          vREGRA := 'Campanha por Qtde. Mínima';
        END IF;
      END IF;
  
      -- Concessão de Brindes
      IF (vc_Promocao.TIPOPROMOCAO = 'N') THEN
        IF    (vc_Promocao.TIPOCONCESSAOBRINDE = 1) THEN
          IF (NVL(vc_Promocao.MULTIPLOSBRINDES,'N') = 'S') THEN
            IF (NVL(vc_Promocao.BRINDESCONCESSAO,0) = 1) THEN
              vREGRA := vREGRA || ' com escolha de 1 unidade de brinde a cada mínimo alcançado';
            ELSE
              vREGRA := vREGRA || ' com escolha de ' || TRIM(TO_CHAR(NVL(vc_Promocao.BRINDESCONCESSAO,0), '999G999G999G990', 'NLS_NUMERIC_CHARACTERS = '',.''')) || '  unidades de brinde a cada mínimo alcançado';
            END IF;
          ELSE
            vREGRA := vREGRA || ' com escolha de brindes até o limite de ' || TRIM(TO_CHAR(NVL(vc_Promocao.BRINDESCONCESSAO,0), '999G999G999G990', 'NLS_NUMERIC_CHARACTERS = '',.''')) || ' unidades';
          END IF;
        ELSIF (vc_Promocao.TIPOCONCESSAOBRINDE = 2) THEN -- DDMEDICA-3103 - usar nBRINDESCONCESSAO
          IF    (NVL(nSKUSCONCESSAO,0) = 1) THEN
            vREGRA := vREGRA || ' com concessão de 1 Produto Brinde com ' || TRIM(TO_CHAR(NVL(nBRINDESCONCESSAO,0), '999G999G999G990', 'NLS_NUMERIC_CHARACTERS = '',.''')) || ' unidades';
          ELSIF (NVL(nSKUSCONCESSAO,0) > 1) THEN
            vREGRA := vREGRA || ' com concessão de ' || TRIM(TO_CHAR(NVL(nSKUSCONCESSAO,0), '999G999G999G990', 'NLS_NUMERIC_CHARACTERS = '',.''')) || ' Produtos de Brinde totalizando '
                                                     || TRIM(TO_CHAR(NVL(nBRINDESCONCESSAO,0), '999G999G999G990', 'NLS_NUMERIC_CHARACTERS = '',.''')) || ' unidades ';
          END IF;
        ELSIF (vc_Promocao.TIPOCONCESSAOBRINDE = 3) THEN
          vREGRA := vREGRA || ' com escolha de brindes em valor sobre ' || TRIM(TO_CHAR(NVL(vc_Promocao.BRINDESCONCESSAO,0),'999G999G999G990D00', 'NLS_NUMERIC_CHARACTERS = '',.'''))  || '% do valor de venda do Mix';
        END IF;
      END IF;
  
      -- Itens Obrigatórios
      IF (nITENS_OBRIGATORIOS > 0) THEN
        vREGRA := vREGRA || ' e com Itens Obrigatórios';
      END IF;
  
      -- Ponto no Final
      vREGRA := vREGRA || '.';
  
  
     /************************************************************************************************
                                       QUINTA PARTE - GRAVAÇÃO DA TABLE
      ************************************************************************************************/
  
  
      -----------------------------------------------------------------------------------------------
      -- Atualiza Campos da Table
      ---------------------------
  
      OUTROW.CODPROMOCAOMED               := vc_Promocao.CODPROMOCAOMED;
      OUTROW.DESCRICAOPROMOCAO            := vc_Promocao.DESCRICAOPROMOCAO;
      OUTROW.TIPOPROMOCAO                 := vc_Promocao.TIPOPROMOCAO;
      OUTROW.TIPOVALIDAVALORMIN           := vc_Promocao.TIPOVALIDAVALORMIN;
      OUTROW.TIPOCONCESSAOBRINDE          := vc_Promocao.TIPOCONCESSAOBRINDE;
      OUTROW.MINIMOPEDIDO                 := vc_Promocao.MINIMOPEDIDO;
      OUTROW.TEXTO_MINIMOPEDIDO           := vTEXTO_MINIMOPEDIDO;
      OUTROW.ATINGIDOPEDIDO               := nATINGIDOPEDIDO;
      OUTROW.TEXTO_ATINGIDOPEDIDO         := vTEXTO_ATINGIDOPEDIDO;
      OUTROW.BRINDESCONCESSAO             := nBRINDESCONCESSAO;
      OUTROW.TEXTO_BRINDESCONCESSAO       := vTEXTO_BRINDESCONCESSAO;
      OUTROW.BRINDESCONCEDIDOS            := nBRINDESCONCEDIDOS;
      OUTROW.TEXTO_BRINDESCONCEDIDOS      := vTEXTO_BRINDESCONCEDIDOS;
      OUTROW.BRINDESCONCEDIDOS            := nBRINDESCONCEDIDOS;
      OUTROW.MULTIPLOSBRINDES             := vc_Promocao.MULTIPLOSBRINDES;
      OUTROW.REGRA                        := vREGRA;
      OUTROW.BRINDESCONCEDIDOS_ALERTA     := nBRINDESCONCEDIDOS_ALERTA;
      OUTROW.QTDEVENDIDA_ALERTA           := nQTDEVENDIDA_ALERTA;
      OUTROW.ITENSNAOVENDIDOS_OBRIGATORIO := nITENSNAOVENDIDOS_OBRIGATORIO;
      OUTROW.MULTIPLICADOR                := nMULTIPLICADOR;
      OUTROW.PROMOCAOCAMPANHAVALIDA       := vPROMOCAOCAMPANHAVALIDA;
  
      -- Insere dados na Table
      PIPE ROW(OUTROW);
  
    END LOOP; -- Fim Laço Promoções
  
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20000, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM);
  END F_PROMOCAORESULTADOCAB;
  
 /*******************************************************************************
  Nome         : F_OBTEM_PRECO_ABCFARMA - DDVENDAS-35697
  Descricão    : Procedimento Obter o Preço ABCFARMA/CMED - Preço Fábrica ou PMC ou Licitação
  Parâmetros   : ENTRADA:
                 pi_vTipoPreco       = 'PF'     - Preço Fábrica
                                       'PMC'    - PMC
                                       'PFLIC'  - Preço Fábrica da Licitação
                                       'PMCLIC' - PMC da Licitação
                 pi_nCodProd         = Código do Produto                
                 pi_vUf              = UF de Destino
                 pi_vCodFilial       = Código da Filial
                 pi_vCodFilialNf     = Código da Filial de Faturamento
                 pi_nCodProd         = Código do Produto
                 pi_nNumRegiao       = Região
                 pi_vTipoCliMed      = Tipo de Cliente Medicamento
                 pi_vConvenioIsencao = S/N
                 SAIDA:
                 po_nPmc             = Valor do PMC
                 po_nPrecoFabrica    = Preço Fábrica
                 po_vMensagem        = Mensagem de Erro
  ********************************************************************************/                                       
  FUNCTION F_OBTEM_PRECO_ABCFARMA(pi_vTipoPreco       IN VARCHAR2,
                                  pi_nCodProd         IN NUMBER,
                                  pi_vUf              IN VARCHAR2,
                                  pi_vCodFilial       IN VARCHAR2,
                                  pi_vCodFilialNf     IN VARCHAR2,
                                  pi_nNumRegiao       IN NUMBER,
                                  pi_vTipoCliMed      IN VARCHAR2,
                                  pi_vConvenioIsencao IN VARCHAR2) RETURN NUMBER
  IS
  
    -- Retorno
    vnRetPreco    PCTABMEDABCFARMA.PRECOFABRICA%TYPE;
    
    -- UF
    vvUf          VARCHAR2(255);
    
    -- Código da Filial
    vvCodFilial   PCFILIAL.CODIGO%TYPE;

    -- UF Exceção
    vvUfExcecao   VARCHAR2(255);
    
    -- Achou Exceção
    vAchouExcecao BOOLEAN;
        
  /*********************************
   INICIO DO PROCESSAMENTO PRINCIPAL  
   *********************************/
  BEGIN

   /******************
    Inicializa Retorno
    ******************/

    vnRetPreco := NULL;

   /********************************************
    Inicializa Variáveis a partir dos Parâmetros
    ********************************************/
    
    vvUf := pi_vUf;
    
    vvCodFilial := NVL(pi_vCodFilialNf,pi_vCodFilial);
  
   /******
    UF ZFM
    ******/
    
    IF (UPPER(pi_vUf) = 'ZF') THEN
      
      BEGIN
        SELECT NVL(PCREGIAO.ALIQZFABCFARMA,'ZF')
          INTO vvUf
          FROM PCREGIAO
         WHERE (PCREGIAO.NUMREGIAO = pi_nNumRegiao);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
            
    END IF;
       
   /******************
    Exceção do Cliente
    ******************/
    
    vAchouExcecao := FALSE;
        
    -- DDVENDAS-38075 - PMC não entra nas Exceções
    IF (UPPER(pi_vTipoPreco) NOT IN ('PMC','PMCLICIT')) THEN

      -- Regra da Prioridade: Exceções do Convênio Isenção ICMS (existir um relacionamento na PCUFMEDABCFARMA para o código da exceção e o convênio '1' = Convênio Isenção ICMS)
      FOR vc_Excecao IN (SELECT E.CODEXCECAO
                              , NVL((SELECT 1 FROM PCUFMEDABCFARMA TB WHERE TB.UF = E.CODEXCECAO AND TB.TIPOMEDICAMENTO = '1' AND pi_vConvenioIsencao = 'S'),2) PRIORIDADE
                           FROM PCEXCECAOUFMEDABCFARMA E
                          WHERE ( (NOT EXISTS (SELECT 'S' FROM PCRESTRICAOUFMEDABCFARMA RF WHERE RF.CODEXCECAO = E.CODEXCECAO AND RF.TIPO = 'F')) OR
                                  (EXISTS (SELECT 'S' FROM PCRESTRICAOUFMEDABCFARMA RF WHERE RF.CODEXCECAO = E.CODEXCECAO AND RF.TIPO = 'F' AND RF.VALOR = vvCodFilial)) )
                            AND ( (NOT EXISTS (SELECT 'S' FROM PCRESTRICAOUFMEDABCFARMA RF WHERE RF.CODEXCECAO = E.CODEXCECAO AND RF.TIPO = 'U')) OR
                                  (EXISTS (SELECT 'S' FROM PCRESTRICAOUFMEDABCFARMA RF WHERE RF.CODEXCECAO = E.CODEXCECAO AND RF.TIPO = 'U' AND RF.VALOR = vvUf)) )     
                            AND (EXISTS (SELECT 'S' FROM PCRESTRICAOUFMEDABCFARMA RF WHERE RF.CODEXCECAO = E.CODEXCECAO AND RF.TIPO = 'C' AND RF.VALOR = pi_vTipoCliMed))
                          ORDER BY PRIORIDADE) LOOP
                            
        BEGIN
  
          SELECT CASE 
                   WHEN (UPPER(pi_vTipoPreco) = 'PF') THEN 
                     PRECOFABRICA
                   WHEN (UPPER(pi_vTipoPreco) = 'PFLICIT') THEN 
                     PRECOFABRICALICITTAB
                   ELSE
                     NULL
                 END                 
            INTO vnRetPreco
            FROM PCTABMEDABCFARMA
           WHERE (CODPROD = pi_nCodProd)
             AND (UF      = vc_Excecao.CODEXCECAO);
             
          --** ACHOU EXCEÇÃO **--
          vAchouExcecao := TRUE;
          
          -- Convênio CONFAZ 87 tem Prioridade, portanto não procura o próximo
          IF (NVL(pi_vConvenioIsencao,'N') = 'S') AND
             (NVL(vnRetPreco,0) > 0) THEN
            EXIT;
          END IF;                            
          
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- Se não encontrar mantém o último
            NULL;
        END;
                            
      END LOOP;
      
    END IF;
    
   /********************
    Se não achou Exceção
    ********************/
    
    IF (NOT vAchouExcecao) THEN

      BEGIN
        SELECT CASE 
                 WHEN (UPPER(pi_vTipoPreco) = 'PF') THEN 
                   PRECOFABRICA
                 WHEN (UPPER(pi_vTipoPreco) = 'PMC') THEN 
                   PRECOMAXCONSUM
                 WHEN (UPPER(pi_vTipoPreco) = 'PFLICIT') THEN 
                   PRECOFABRICALICITTAB
                 WHEN (UPPER(pi_vTipoPreco) = 'PMCLICIT') THEN 
                   PRECOMAXCONSUMLICITTAB
                 ELSE
                   NULL
               END                 
          INTO vnRetPreco
          FROM PCTABMEDABCFARMA
         WHERE (CODPROD = pi_nCodProd)
           AND (UF      = vvUf);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnRetPreco := 0;
      END;
      
      -- Se tabela Zona Franca e não achou a Alíquota, busca na ZF
      IF (UPPER(pi_vUf) = 'ZF')  AND 
         (NVL(vnRetPreco,0) = 0) THEN
         
        BEGIN
          SELECT CASE 
                   WHEN (UPPER(pi_vTipoPreco) = 'PF') THEN 
                     PRECOFABRICA
                   WHEN (UPPER(pi_vTipoPreco) = 'PMC') THEN 
                     PRECOMAXCONSUM
                   WHEN (UPPER(pi_vTipoPreco) = 'PFLICIT') THEN 
                     PRECOFABRICALICITTAB
                   WHEN (UPPER(pi_vTipoPreco) = 'PMCLICIT') THEN 
                     PRECOMAXCONSUMLICITTAB
                   ELSE
                     NULL
                 END                 
            INTO vnRetPreco
            FROM PCTABMEDABCFARMA
           WHERE (CODPROD = pi_nCodProd)
             AND (UF      = 'ZF');
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnRetPreco := 0;
        END;
         
      END IF;      
        
    END IF; -- Não Achou Exceção
    
   /*******
    Retorno
    *******/
    
    RETURN NVL(vnRetPreco,0);
            
  END F_OBTEM_PRECO_ABCFARMA;  
 
 /********************************************************************************  
  ********************************************************************************  
  ********************************************************************************  
                      C Á L C U L O   D O   S T   F O N T E 
                                  << INICIO >>
  ********************************************************************************  
  ********************************************************************************  
  ********************************************************************************/  

  ---------------------------------------------------------------------------------------------------
  -- Função para Calcular o Descontos dos Benefícios Fiscais conforme Regra do Pacote - DDMEDICA-7584
  ---------------------------------------------------------------------------------------------------
  PROCEDURE P_CALC_DESC_PIS_COFINS_ICMS(pi_vCODFILIAL              IN VARCHAR2,
                                        pi_vCODFILIANF             IN VARCHAR2,
                                        pi_vCODFILIALRETIRA        IN VARCHAR2,
                                        pi_nCODCLI                 IN NUMBER,
                                        pi_nCODPROD                IN NUMBER,
                                        pi_nPRECOSEMIMPOSTOS       IN NUMBER,
                                        po_nVALOR_DESCONTO_PIS    OUT NUMBER,
                                        po_nPERC_DESCONTO_PIS     OUT NUMBER,
                                        po_nVALOR_DESCONTO_COFINS OUT NUMBER,
                                        po_PERC_DESCONTO_COFINS   OUT NUMBER,
                                        po_VALOR_DESCONTO_ICMS    OUT NUMBER,
                                        po_PERC_DESCONTO_ICMS     OUT NUMBER,
                                        po_VALOR_DESCONTO_SUFRAMA OUT NUMBER,
                                        po_PERC_DESCONTO_SUFRAMA  OUT NUMBER,
                                        po_vErros                 OUT VARCHAR2,
                                        po_vMsgErros              OUT VARCHAR2) IS
    
    -- Declaração de Variáveis da Função
    vvSql VARCHAR2(2000);

  BEGIN

    -- Inicializa Variáveis
    po_nVALOR_DESCONTO_PIS    := 0;
    po_nPERC_DESCONTO_PIS     := 0;
    po_nVALOR_DESCONTO_COFINS := 0;
    po_PERC_DESCONTO_COFINS   := 0;
    po_VALOR_DESCONTO_ICMS    := 0;
    po_PERC_DESCONTO_ICMS     := 0;
    po_VALOR_DESCONTO_SUFRAMA := 0;
    po_PERC_DESCONTO_SUFRAMA  := 0;
    po_vErros                 := 'N';
    po_vMsgErros              := NULL;

    -- BASE E VALOR DO ST
    BEGIN
      SELECT VALOR_DESCONTO_PIS
           , PERC_DESCONTO_PIS
           , VALOR_DESCONTO_COFINS
           , PERC_DESCONTO_COFINS
           , VALOR_DESCONTO_ICMS
           , PERC_DESCONTO_ICMS
           , VALOR_DESCONTO_SUFRAMA
           , PERC_DESCONTO_SUFRAMA
        INTO po_nVALOR_DESCONTO_PIS
           , po_nPERC_DESCONTO_PIS
           , po_nVALOR_DESCONTO_COFINS
           , po_PERC_DESCONTO_COFINS
           , po_VALOR_DESCONTO_ICMS
           , po_PERC_DESCONTO_ICMS
           , po_VALOR_DESCONTO_SUFRAMA
           , po_PERC_DESCONTO_SUFRAMA
        FROM TABLE(PKG_TRIBUTACAO.CALCULAR_DESC_PIS_COFINS_ICMS(pi_vCODFILIAL, 
                                                                pi_vCODFILIANF,
                                                                NULL,
                                                                NVL(pi_nCODCLI,0),
                                                                NVL(pi_nCODPROD,0),
                                                                NVL(pi_nPRECOSEMIMPOSTOS,0),
                                                                0,     -- pNumEmpenho
                                                                0,     -- pPrazoMedioPedido
                                                                'N')); -- pVendaTriangular      
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        po_nVALOR_DESCONTO_PIS    := 0;
        po_nPERC_DESCONTO_PIS     := 0;
        po_nVALOR_DESCONTO_COFINS := 0;
        po_PERC_DESCONTO_COFINS   := 0;
        po_VALOR_DESCONTO_ICMS    := 0;
        po_PERC_DESCONTO_ICMS     := 0;
        po_VALOR_DESCONTO_SUFRAMA := 0;
        po_PERC_DESCONTO_SUFRAMA  := 0;
    END;
    
  EXCEPTION
    WHEN OTHERS THEN
      po_vErros    := 'S';
      po_vMsgErros := 'Erro no cálculo dos benefícios fiscais (PKG_TRIBUTACAO): ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >>' || SQLERRM; 
  END P_CALC_DESC_PIS_COFINS_ICMS;  

  ------------------------------------------------------------------------------
  -- Procedimento para arredondar o calculo do Suframa - DDMEDICA-7594
  ------------------------------------------------------------------------------
  FUNCTION F_ARREDONDAMENTO_SUFRAMA(pi_nValor            IN NUMBER,
                                    pi_vNumCasasDecimais IN NUMBER,
                                    pi_vTipoCalcSuframa  IN VARCHAR2)
  RETURN NUMBER IS
    vValorSuframa NUMBER;
  BEGIN

    IF NVL(pi_vTipoCalcSuframa,' ') = 'T2' THEN
      SELECT TRUNC(pi_nValor,2) INTO vValorSuframa FROM DUAL;
    ELSE
      IF NVL(pi_vTipoCalcSuframa,' ') = 'A2' THEN
        SELECT ROUND(pi_nValor,2) INTO vValorSuframa FROM DUAL;
      ELSE
        SELECT ROUND(pi_nValor,pi_vNumCasasDecimais) INTO vValorSuframa FROM DUAL;
      END IF;
    END IF;

    -- Retorno
    RETURN NVL(vValorSuframa,0);

  END F_ARREDONDAMENTO_SUFRAMA;

  ------------------------------------------------------------------------------
  -- Procedimento para arredondar o calculo da desoneração - DDMEDICA-7594
  ------------------------------------------------------------------------------
  FUNCTION F_ARREDONDAMENTO_DESONERACAO(pi_nValor            IN NUMBER,
                                        pi_vNumCasasDecimais IN NUMBER,
                                        pi_vRegraMinimo      IN VARCHAR2,
                                        pi_nCodSt            IN NUMBER)
  RETURN NUMBER IS
    nValorDesoneracao NUMBER;
    vDESTACDESCICMISENCAOCOMERCIAL PCTRIBUT.DESTACDESCICMISENCAOCOMERCIAL%TYPE;
  BEGIN

    SELECT ROUND(pi_nValor,pi_vNumCasasDecimais) INTO nValorDesoneracao FROM DUAL;
    
    IF (nValorDesoneracao = 0) AND
       (pi_vRegraMinimo = 'S') THEN
      BEGIN
        SELECT PCTRIBUT.DESTACDESCICMISENCAOCOMERCIAL
          INTO vDESTACDESCICMISENCAOCOMERCIAL
          FROM PCTRIBUT
         WHERE (PCTRIBUT.CODST = pi_nCodSt);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vDESTACDESCICMISENCAOCOMERCIAL := 'N';
      END;
      IF (NVL(vDESTACDESCICMISENCAOCOMERCIAL,'N') <> 'S') THEN -- Isenção ST não participa da Regra
        -- Condicionar às casas decimais do preço de venda para não gerar preço negativo
        IF    (NVL(pi_vNumCasasDecimais,2) = 3) THEN
          nValorDesoneracao := 0.001;
        ELSIF (NVL(pi_vNumCasasDecimais,2) = 4) THEN
          nValorDesoneracao := 0.0001;
        ELSIF (NVL(pi_vNumCasasDecimais,2) = 5) THEN
          nValorDesoneracao := 0.00001;
        ELSIF (NVL(pi_vNumCasasDecimais,2) = 6) THEN
          nValorDesoneracao := 0.000001;
        ELSE
          nValorDesoneracao := 0.01;
        END IF;
      END IF;
    END IF;

    -- Retorno
    RETURN NVL(nValorDesoneracao,0);

  END F_ARREDONDAMENTO_DESONERACAO;

 /*******************************************************************************
  Nome         : P_OBTER_VALORES_BENEF_FISCAIS
  Descricão    : Procedimento Obter os valores dos Descontos dos Benefícios 
                 Fiscais: 
                 - SUFRAMA
                 - DESONERAÇÃO ICMS
                 - Redução PIS e COFINS
  Solicitação  : DDMEDICA-7594                
  *******************************************************************************/
  PROCEDURE P_OBTER_VALORES_BENEF_FISCAIS(pi_vCodFilial               IN VARCHAR2,
                                          pi_vCodFilialNf             IN VARCHAR2,
                                          pi_nCodCli                  IN NUMBER,
                                          pi_nCodProd                 IN NUMBER,
                                          pi_nCodSt                   IN NUMBER,
                                          pi_nNumCasasDecVenda        IN NUMBER,
                                          pi_vTipoCalcSuframa         IN VARCHAR2,
                                          pi_nPerDescIsencaoIcmsTrib  IN NUMBER,
                                          pi_vAplicaDescIsencaoMed    IN VARCHAR2,
                                          pi_nPVendaSemImposto        IN NUMBER,
                                          pi_nPTabelaSemImposto       IN NUMBER,
                                          pi_nPBaseRcaSemImposto      IN NUMBER,
                                          pi_nQt                      IN NUMBER,                                          
                                          po_nVlDescReducaoPis       OUT NUMBER,
                                          po_nPercDescReducaoPis     OUT NUMBER,
                                          po_nVlDescReducaoCofins    OUT NUMBER,
                                          po_nPercDescReducaoCofins  OUT NUMBER,
                                          po_nVlDescIcmIsencao       OUT NUMBER,
                                          po_nPercDescIcmIsencao     OUT NUMBER,
                                          po_nVlDescSuframa          OUT NUMBER,
                                          po_nPercDescSuframa        OUT NUMBER,
                                          po_nNovoPVenda             OUT NUMBER,
                                          po_nNovoPTabela            OUT NUMBER,
                                          po_nNovoPBaseRca           OUT NUMBER,
                                          po_vErros                  OUT VARCHAR2,
                                          po_vMsgErros               OUT VARCHAR2) IS                                          
    vnQtde NUMBER;                                          
  BEGIN
   
    ------------------------------------------------------------------------------
    -- Inicializa Retornos ------------------------------------------------------
    ------------------------------------------------------------------------------
    po_nVlDescReducaoPis      := 0;
    po_nPercDescReducaoPis    := 0;
    po_nPercDescReducaoCofins := 0;
    po_nVlDescSuframa         := 0;
    po_nPercDescSuframa       := 0;
    po_nVlDescIcmIsencao      := 0;
    po_nPercDescIcmIsencao    := 0;
    po_nNovoPVenda            := pi_nPVendaSemImposto;
    po_nNovoPTabela           := pi_nPTabelaSemImposto;
    po_nNovoPBaseRca          := pi_nPBaseRcaSemImposto;
    po_vErros                 := 'N';
    po_vMsgErros              := NULL;
    ------------------------------------------------------------------------------
    
    -- Quantidade para Arredondamento da Desoneração ICMS e SUFRAMA
    vnQtde := pi_nQt;
    IF (NVL(pi_nQt,0) = 0) THEN
      vnQtde := 1;
    END IF;
    
    ------------------------------------------------------------------------------
    -- CALCULA DESCONTOS DE BENEFICIOS FISCAIS CONFORME REGRA PACOTE -------------
    ------------------------------------------------------------------------------
    
    P_CALC_DESC_PIS_COFINS_ICMS(pi_vCodFilial,
                                pi_vCodFilialNf,
                                NULL,                 -->> Não tem Implementação de Filial Retira
                                pi_nCodCli,
                                pi_nCodProd,
                                pi_nPVendaSemImposto, -->> Utiliza o Preço Venda Líquido sem Impostos
                                po_nVlDescReducaoPis,
                                po_nPercDescReducaoPis,
                                po_nVlDescReducaoCofins,
                                po_nPercDescReducaoCofins,
                                po_nVlDescIcmIsencao,
                                po_nPercDescIcmIsencao,
                                po_nVlDescSuframa,
                                po_nPercDescSuframa,
                                po_vErros,
                                po_vMsgErros);
    
    
    ------------------------------------------------------------------------------
    -- ESPECIFICO MEDICAMENTOS - SUFRAMA -----------------------------------------
    ------------------------------------------------------------------------------

    -- Arredondamento do Desconto de SUFRAMA
    IF (F_ARREDONDAMENTO_SUFRAMA(po_nVlDescSuframa,pi_nNumCasasDecVenda,pi_vTipoCalcSuframa) <> 0) THEN
      po_nVlDescSuframa := F_ARREDONDAMENTO_SUFRAMA(po_nVlDescSuframa,pi_nNumCasasDecVenda,pi_vTipoCalcSuframa);
    END IF;
      
    ------------------------------------------------------------------------------
    -- ESPECIFICO MEDICAMENTOS - DESONERACAO -------------------------------------
    ------------------------------------------------------------------------------
    
    -- Calcula Desconto Isenção conforme parâmetros de cliente e tributação
    IF (NVL(pi_vAplicaDescIsencaoMed,'N') = 'S') THEN
      po_nVlDescIcmIsencao   := NVL(pi_nPVendaSemImposto,0) * (NVL(pi_nPerDescIsencaoIcmsTrib,0) / 100);
      po_nPercDescIcmIsencao := pi_nPerDescIsencaoIcmsTrib;
    END IF;

    -- Se o Valor Total do Desconto de Isenção de ICMS tender a zero, aredonda o Valor Unitário do Suframa para as casas decimais do preço de venda
    IF (NVL(po_nVlDescIcmIsencao,0) > 0) THEN
      IF (F_ARREDONDAMENTO_DESONERACAO((po_nVlDescIcmIsencao * NVL(vnQtde,0)),2,'N',pi_nCodSt) = 0) THEN
        po_nVlDescIcmIsencao := F_ARREDONDAMENTO_DESONERACAO(po_nVlDescIcmIsencao,pi_nNumCasasDecVenda,'S',pi_nCodSt);
      END IF;
    END IF;
    
    ------------------------------------------------------------------------------
    -- Aplicação dos Descontos dos Benefícios Fiscais nos Preços -----------------
    ------------------------------------------------------------------------------    
    po_nNovoPVenda          := ROUND(NVL(po_nNovoPVenda,0)
                                   - NVL(po_nVlDescReducaoPis,0)
                                   - NVL(po_nVlDescReducaoCofins,0)
                                   - NVL(po_nVlDescIcmIsencao,0)
                                   - NVL(po_nVlDescSuframa,0)
                                   , pi_nNumCasasDecVenda);
    po_nNovoPTabela         := ROUND(NVL(po_nNovoPTabela,0)
                                   - NVL(po_nVlDescReducaoPis,0)
                                   - NVL(po_nVlDescReducaoCofins,0)
                                   - NVL(po_nVlDescIcmIsencao,0)
                                   - NVL(po_nVlDescSuframa,0)
                                   , pi_nNumCasasDecVenda);
    po_nNovoPBaseRca        := ROUND(NVL(po_nNovoPBaseRca,0)
                                   - NVL(po_nVlDescReducaoPis,0)
                                   - NVL(po_nVlDescReducaoCofins,0)
                                   - NVL(po_nVlDescIcmIsencao,0)
                                   - NVL(po_nVlDescSuframa,0)
                                   , pi_nNumCasasDecVenda);
    
  EXCEPTION
    WHEN OTHERS THEN
      po_vErros    := 'S';
      po_vMsgErros := 'Erro no cálculo dos benefícios fiscais (PKG_MEDICAMENTOS): ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >>' || SQLERRM; 
  END P_OBTER_VALORES_BENEF_FISCAIS;                                          

  /*******************************************************************************
   Nome         : P_OBTEM_PMPF
   Descricão    : Procedimento Obter o PMPF dos Medicamentos
   Parâmetros   : ENTRADA:
                  pi_nCodSt   = Código da Tributação
                  pi_nCodProd = Código do Produto
                  pi_nCodCli  = Código do Cliente
                  SAIDA:
                  po_nPmPf    = PMPF
  **********************************************************************************/                                       
  PROCEDURE P_OBTEM_PMPF(pi_nCodSt   IN  VARCHAR2,
                         pi_nCodProd IN  NUMBER,
                         pi_nCodCli  IN  VARCHAR2,                               
                         po_nPmPf    OUT NUMBER) IS
    vvUsaPmPfBaseSt PCTRIBUT.USAPMPFBASEST%TYPE;
    vvEstEnt        PCCLIENT.ESTENT%TYPE;
  BEGIN
   
    -- Inicializa Retorno
    po_nPmPf := NULL;
  
    -- Pesquisa Tributação do Produto
    BEGIN
      SELECT PCTRIBUT.USAPMPFBASEST
        INTO vvUsaPmPfBaseSt
        FROM PCTRIBUT
       WHERE (PCTRIBUT.CODST = pi_nCodSt);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvUsaPmPfBaseSt := 'N';
    END;
    
    -- Se a Tributação Usa PMPF na Base do ST
    IF (vvUsaPmPfBaseSt = 'S') THEN
    
      -- Pesquisa UF do Cliente
      BEGIN
        SELECT ESTENT
          INTO vvEstEnt
          FROM PCCLIENT
         WHERE (CODCLI = pi_nCodCli);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvEstEnt := NULL;
      END;
    
      -- Pesquisa PMPF
      BEGIN
        SELECT PMPF
          INTO po_nPmPf
          FROM PCTABMEDABCFARMA
         WHERE (CODPROD = pi_nCodProd)
           AND (UF      = vvEstEnt);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          po_nPmPf := 0;
      END;
      
    END IF; -- Fim Condição: Se a Tributação Usa PMPF na Base do ST
    
  END P_OBTEM_PMPF;

  /*******************************************************************************
   Nome         : P_OBTEM_PMC_PRODUTO
   Descricão    : Procedimento Obter o PMC do Produto
   Parâmetros   : ENTRADA:
                  pi_vCodFilial = Código da Filial
                  pi_nCodProd   = Código do Produto
                  pi_vUfCliente = UF do Cliente
                  pi_nRegiao    = Região
                  SAIDA:
                  po_nPmc          = Valor do PMC
                  po_nPrecoFabrica = Preço Fábrica
                  po_vMensagem     = Mensagem de Erro
   Alteracão    : Anderson Silva - 10/04/2014 - Criação da Procedure
   Alteracão    : Anderson Silva - 30/04/2014 - Alteração Tipo Variável de pi_vCodFilial
   Alteracão    : Anderson Silva - 28/12/2015 - HIS.04408.2015 - Alteração Preço Fábrica por UF
  ********************************************************************************/                                       
  PROCEDURE P_OBTEM_PMC_PRODUTO(pi_vCodFilial    IN  VARCHAR2,
                                pi_nCodProd      IN  NUMBER,
                                pi_vUfCliente    IN  VARCHAR2,
                                pi_nRegiao       IN  NUMBER,
                                po_nPmc          OUT NUMBER,
                                po_nPrecoFabrica OUT NUMBER,
                                po_vMensagem     OUT VARCHAR2,
                                pi_nCodCli       IN  NUMBER DEFAULT NULL)
  IS
  
    -- Parâmetros
    vvUsaPmcUf                   PCPARAMFILIAL.VALOR%TYPE;
    vvUtilizaPrecoFabricaPorUf   PCPARAMFILIAL.VALOR%TYPE;
    -- Identificador de Região Zona Franca de Manaus
    vvRegiaoZfm                  PCREGIAO.REGIAOZFM%TYPE;
    -- Preços Nacionais por Produto
    TYPE TRecNacionalPorProduto   IS RECORD(
         vnPmc                    PCPRODUT.PRECOMAXCONSUM%TYPE,
         vnPrecoFabrica           PCPRODUT.CUSTOREP%TYPE);
    vrNacionalPorProduto          TRecNacionalPorProduto;   
    -- Preços Zona Franca por Produto
    TYPE TRecZonaFrancaPorProduto IS RECORD(
         vnPmc                    PCPRODUT.PRECOMAXCONSUM%TYPE,
         vnPrecoFabrica           PCPRODUT.CUSTOREP%TYPE);
    vrZonaFrancaPorProduto        TRecZonaFrancaPorProduto;  
    -- Preços Nacionais por UF
    TYPE TRecNacionalPorUf        IS RECORD(
         vnPmc                    PCTABMEDABCFARMA.PRECOMAXCONSUM%TYPE,
         vnPrecoFabrica           PCTABMEDABCFARMA.PRECOFABRICA%TYPE);
    vrNacionalPorUf               TRecNacionalPorUf;
    -- Preços Zona Franca por UF
    TYPE TRecZonaFrancaPorUf      IS RECORD(
         vnPmc                    PCTABMEDABCFARMA.PRECOMAXCONSUM%TYPE,
         vnPrecoFabrica           PCTABMEDABCFARMA.PRECOFABRICA%TYPE);
    vrZonaFrancaPorUf             TRecZonaFrancaPorUf;
    
    -- Tipo Cliente - DDVENDAS-35697
    vvTipoCliMed                  PCCLIENT.TIPOCLIMED%TYPE;
    -- Convênio - DDVENDAS-35697
    vvConvenioIsencaoIcmsMed      PCPRODUT.CONVENIOISENCAOICMSMED%TYPE;
    
  /*********************************
   INICIO DO PROCESSAMENTO PRINCIPAL  
   *********************************/
  BEGIN
  
    -- Inicializa Retornos
    po_nPmc      := 0;
    po_vMensagem := NULL;
    
   /***************************************
    Utilizando as Exceções - DDVENDAS-35697
    ***************************************/
    
    IF (NVL(pi_nCodCli,0) > 0) THEN
    
      -- Tipo Cliente
      BEGIN
        SELECT TIPOCLIMED
          INTO vvTipoCliMed 
          FROM PCCLIENT
         WHERE (CODCLI = pi_nCodCli);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvTipoCliMed := NULL;
      END;
      
      -- Convênio
      BEGIN
        SELECT NVL(CONVENIOISENCAOICMSMED,'N')
          INTO vvConvenioIsencaoIcmsMed
          FROM PCPRODUT
         WHERE (CODPROD = pi_nCodProd);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvConvenioIsencaoIcmsMed := 'N';
      END;
      
      -- Verifica seRegião ZFM
      BEGIN
        SELECT NVL(PCREGIAO.REGIAOZFM,'N') REGIAOZFM
          INTO vvRegiaoZfm
          FROM PCREGIAO
         WHERE (PCREGIAO.NUMREGIAO = pi_nRegiao);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvRegiaoZfm := 'N';
      END;
      
      -- Se Tabela Região Zona Franca
      IF (NVL(vvRegiaoZfm,'N') = 'S') THEN

        po_nPmc          := F_OBTEM_PRECO_ABCFARMA('PMC',
                                                   pi_nCodProd,
                                                   'ZF',
                                                   pi_vCodFilial,
                                                   pi_vCodFilial,
                                                   pi_nRegiao,
                                                   vvTipoCliMed,
                                                   vvConvenioIsencaoIcmsMed);
      
        po_nPrecoFabrica := F_OBTEM_PRECO_ABCFARMA('PF',
                                                   pi_nCodProd,
                                                   'ZF',
                                                   pi_vCodFilial,
                                                   pi_vCodFilial,
                                                   pi_nRegiao,
                                                   vvTipoCliMed,
                                                   vvConvenioIsencaoIcmsMed);
      
      -- Se Tabela Nacional
      ELSE
      
        po_nPmc          := F_OBTEM_PRECO_ABCFARMA('PMC',
                                                   pi_nCodProd,
                                                   pi_vUfCliente,
                                                   pi_vCodFilial,
                                                   pi_vCodFilial,
                                                   pi_nRegiao,
                                                   vvTipoCliMed,
                                                   vvConvenioIsencaoIcmsMed);
      
        po_nPrecoFabrica := F_OBTEM_PRECO_ABCFARMA('PF',
                                                   pi_nCodProd,
                                                   pi_vUfCliente,
                                                   pi_vCodFilial,
                                                   pi_vCodFilial,
                                                   pi_nRegiao,
                                                   vvTipoCliMed,
                                                   vvConvenioIsencaoIcmsMed);
      
      END IF;
            
    ELSE
  
     /**********
      Parâmetros
      **********/
      
      -- PMC por UF
      BEGIN
        SELECT NVL(VALOR,'N') VALOR
          INTO vvUsaPmcUf
          FROM PCPARAMFILIAL
         WHERE (CODFILIAL = '99')
           AND (NOME      = 'UTILIZAPMCUF');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvUsaPmcUf := 'N';
      END;         
      
      -- Preço Fábrica por UF
      BEGIN
        SELECT NVL(VALOR,'N') VALOR
          INTO vvUtilizaPrecoFabricaPorUf
          FROM PCPARAMFILIAL
         WHERE (CODFILIAL = '99')
           AND (NOME      = 'UTILIZAPRECOFABRICAPORUF');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvUtilizaPrecoFabricaPorUf := 'N';
      END;         
    
     /**********
      Região ZFM
      **********/
        
      -- Pesquisa Região - HIS.04408.2015
      BEGIN
        SELECT NVL(PCREGIAO.REGIAOZFM,'N') REGIAOZFM
          INTO vvRegiaoZfm
          FROM PCREGIAO
         WHERE (PCREGIAO.NUMREGIAO = pi_nRegiao);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvRegiaoZfm := 'N';
      END;
        
      -----------------------
      -- Se Usa PMC por UF
      -- OU 
      -- Preço Fábrica por UF
      -----------------------
      IF (NVL(vvUsaPmcUf,'N')        = 'S') OR
         (vvUtilizaPrecoFabricaPorUf = 'S') THEN
         
        -- Se ZFM - Zona Franca Manaus
        IF (vvRegiaoZfm = 'S') THEN
          -- Pesquisa PMC e Preço por UF - Zona Franca Manaus
          BEGIN
            SELECT NVL(PRECOMAXCONSUM,0) PRECOMAXCONSUM
                 , NVL(PRECOFABRICA,0)   PRECOFABRICA
              INTO vrZonaFrancaPorUf.vnPmc
                 , vrZonaFrancaPorUf.vnPrecoFabrica
              FROM PCTABMEDABCFARMA
             WHERE (CODPROD = pi_nCodProd)
               AND (UF      = 'ZF');
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vrZonaFrancaPorUf.vnPmc          := 0;
              vrZonaFrancaPorUf.vnPrecoFabrica := 0;
          END;
        END IF;  
         
        -- Pesquisa PMC por UF do Cliente
        BEGIN
          SELECT NVL(PRECOMAXCONSUM,0) PRECOMAXCONSUM
               , NVL(PRECOFABRICA,0)   PRECOFABRICA
            INTO vrNacionalPorUf.vnPmc
               , vrNacionalPorUf.vnPrecoFabrica
            FROM PCTABMEDABCFARMA
           WHERE (CODPROD = pi_nCodProd)
             AND (UF      = pi_vUfCliente);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vrNacionalPorUf.vnPmc          := 0;
            vrNacionalPorUf.vnPrecoFabrica := 0;
        END;
        
      END IF;    
      
      ----------------------------------
      -- PMC e Preço Fábrica da PCPRODUT
      ----------------------------------
        
      -- Pesquisa PMC e Preço Fábrica do Produto NACIONAL e ZFM
      BEGIN
        SELECT NVL(PRECOMAXCONSUM,0)
             , NVL(CUSTOREP,0)
             , NVL(PRECOMAXCONSUMZFM,0)
             , NVL(CUSTOREPZFM,0)         
          INTO vrNacionalPorProduto.vnPmc
             , vrNacionalPorProduto.vnPrecoFabrica
             , vrZonaFrancaPorProduto.vnPmc
             , vrZonaFrancaPorProduto.vnPrecoFabrica
          FROM PCPRODUT
         WHERE (CODPROD = pi_nCodProd);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vrNacionalPorProduto.vnPmc             := 0;
          vrNacionalPorProduto.vnPrecoFabrica    := 0;
          vrZonaFrancaPorProduto.vnPmc          := 0;
          vrZonaFrancaPorProduto.vnPrecoFabrica := 0;
      END;
            
     /****************
      Definição do PMC
      ****************/
      
      ----------------------------------------------------
      -- PMC POR UF - Tabela PCTABMEDABCFARMA ------------
      ----------------------------------------------------
      IF (NVL(vvUsaPmcUf,'N')                 = 'S') OR
         (NVL(vvUtilizaPrecoFabricaPorUf,'N') = 'S') THEN
    
        -- Inicializa PMC com Valor da UF do Cliente
        po_nPmc := vrNacionalPorUf.vnPmc;
        
        -- Substitui PMC com Valor da Zona Franca se a Região for ZFM
        IF (vvRegiaoZfm = 'S') AND
           (NVL(vrZonaFrancaPorUf.vnPmc,0) > 0) THEN
          po_nPmc := vrZonaFrancaPorUf.vnPmc;       
        END IF;    
         
      ----------------------------------------------------
      -- PMC POR PRODUTO ---------------------------------
      ----------------------------------------------------
      ELSE
    
        -- Inicializa PMC com Valor Nacional da PCPRODUT
        po_nPmc := vrNacionalPorProduto.vnPmc;
     
        -- Substitui PMC com Valor da Zona Franca se a Região for ZFM
        IF (vvRegiaoZfm = 'S')   AND
           (NVL(vrZonaFrancaPorProduto.vnPmc,0) > 0) THEN
          po_nPmc := vrZonaFrancaPorProduto.vnPmc;       
        END IF;
      
      END IF;     
    
     /**************************
      Definição do Preço Fábrica
      **************************/
      
      ----------------------------------------------------
      -- PREÇO FÁBRICA POR UF - Tabela PCTABMEDABCFARMA --
      ----------------------------------------------------
      IF (NVL(vvUtilizaPrecoFabricaPorUf,'N') = 'S') THEN
    
        -- Inicializa Preço Fábrica com Valor da UF do Cliente
        po_nPrecoFabrica := vrNacionalPorUf.vnPrecoFabrica;
     
        -- Substitui Preço Fábrica com Valor da Zona Franca se a Região for ZFM
        IF (vvRegiaoZfm = 'S')   AND
           (NVL(vrZonaFrancaPorUf.vnPrecoFabrica,0) > 0) THEN
          po_nPrecoFabrica := vrZonaFrancaPorUf.vnPrecoFabrica;       
        END IF;
      
      ----------------------------------------------------
      -- PREÇO FÁBRICA POR PRODUTO ----------------------
      ----------------------------------------------------
      ELSE
    
        -- Inicializa Preço Fábrica com Valor Nacional da PCPRODUT
        po_nPrecoFabrica := vrNacionalPorProduto.vnPrecoFabrica;
     
        -- Substitui Preço Fábrica com Valor da Zona Franca se a Região for ZFM
        IF (vvRegiaoZfm = 'S')   AND
           (NVL(vrZonaFrancaPorProduto.vnPrecoFabrica,0) > 0) THEN
          po_nPrecoFabrica := vrZonaFrancaPorProduto.vnPrecoFabrica;
        END IF;
      
      END IF;
      
    END IF; -- Fim Condição: Usando as Exceções
            
  EXCEPTION
    WHEN OTHERS THEN
      po_vMensagem := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM;
  END P_OBTEM_PMC_PRODUTO;  

/*******************************************************************************
   Nome         : P_OBTEM_STFONTE_42
   Descricão    : Procedimento Obter a Base e Valor do ST Fonte por Preço de 
                  Tabela ou Preço de Venda
                  com a Regra do ST Recolhido Anteriormente
   Parâmetros   : ENTRADA:
                  pi_vCodFilial            = Código da Filial
                  pi_nCodProd              = Código do Produto
                  pi_nCodCli               = Código do Cliente
                  pi_nNumRegiao            = Número da Região
                  pi_nCondVenda            = Tipo de Venda
                  pi_nPercVenda            = Percentual de Venda do Pedido
                  pi_vPVenda               = Preço de Venda
                  pi_nValorIpi             = Valor do Ipi                
                  pi_nPrecoMaxConsum       = Preço Max. Consumidor
                  pi_nValorUltEnt          = Valor Últ. Entrada
                  pi_nCustoNfSemSt         = Custo NF sem ST
                  pi_nPTabela              = Preço de Tabela
                  pi_vSomenteIVATribut     = 'N' em todas as chamadas exceto no 
                                                 Simples Nacional
                  pi_vPesquisarCustos      = S - Pesquisa Custos na PCEST
                                             N - Não pesquisa Custos na PCEST, 
                                                 usa os passados nos parâmetros
                  pi_vItemBonific          = S/N
                  pi_nVlFreteOutrasDesp    = Quando chamado da Package Faturamento,
                                             para ratear o Frete e Outras Despesas na
                                             Base de ST  
                  pi_vTipoChamada          = Determina o tipo de chamada da função 
                                             'F' - Chamado do Faturamento
                                             'L' - Chamado do Cálculo do ST Especial
                                                   de Operador Logísitco - HIS.01858.2015                                          
                  pi_nCodFilialNf          = Código Filial NF                           
                  ENTRADA E SAIDA:
                  pio_nCodSt               = Código da Tributação
                  SAIDA:
                  po_nBaseStFonte          = Base do ST Fonte
                  pi_nValorIpi             = Valor do ST Fonte
                  po_vMensagem             = Mensagem de Erro se ouver
                  po_vRegimeEspIsenStFonte = Se Isento de ST Fonte S/N
                  po_nPautaFonte           = Valor de Pauta ST Fonte (Farmacia Popular)
                  po_vObservacaoStFonte    = Log de Cálculo
                  po_vIndEscalaRelevante   = Escala Relevante ou Não Relevante (S/N)
                  po_vCnpjFabricante       = CNPJ Fabricante
                  po_vFabricante           = Fabricante
                  po_nVLBASEFCPICMS        =  -- HIS.04200.2017
                  po_nVLBASEFCPST          =  -- HIS.04200.2017
                  po_nVLBCFCPSTRET         =  -- HIS.04200.2017
                  po_nPERFCPSTRET          =  -- HIS.04200.2017
                  po_nVLFCPSTRET           =  -- HIS.04200.2017
                  po_nPERFCPSN             =  -- HIS.04200.2017
                  po_nVLFECP               =  -- HIS.04200.2017
                  po_nVLACRESCIMOFUNCEP    =  -- HIS.04200.2017
                  po_nPERACRESCIMOFUNCEP   =  -- HIS.04200.2017
                  po_nALIQICMSFECP         =  -- HIS.04200.2017
                  po_nVLCREDFCPICMSSN      =  -- HIS.04200.2017      
                  po_nCODCONFIGFUNCEPMED          
                  pi_vOrdemCalculo         = P - Padrão
                                           = I - Inverso
                  pi_vMemoriaCalculo       = S - Sim (Grava a Memória de Cálculo
                                             N - Não (Não grava a Memória de Cálculo)
                  pi_nValorNotaFiscal      = Valor da Nota Fiscal           
                  po_nBCSTRETANTERIOR          = Base do ST Recolhido Anteriormente
                  po_nVLICMSSUBSTITUTOANTERIOR = Base do ICMS Substituto Recolhido Anteriormente
                  po_nVLICMSSTRETANTERIOR      = Valor do ST Recolhido Anteriormente
   Alteração    : Anderson Silva - 30/09/2021 - Criação da Procedure - DDMEDICA-7697
  **********************************************************************************/                                       
  PROCEDURE P_OBTEM_STFONTE_42(pi_vCodFilial                IN VARCHAR2,
                               pi_nCodProd                  IN NUMBER,
                               pi_nCodCli                   IN NUMBER,
                               pi_nNumRegiao                IN NUMBER,
                               pi_nCondVenda                IN NUMBER,
                               pi_nPercVenda                IN NUMBER,
                               pio_nCodSt                   IN OUT NUMBER,
                               pi_vPVenda                   IN NUMBER,
                               pi_nValorIpi                 IN NUMBER,                                
                               pi_nPrecoMaxConsum           IN NUMBER,
                               pi_nValorUltEnt              IN NUMBER,
                               pi_nCustoNfSemSt             IN NUMBER,
                               pi_nPTabela                  IN NUMBER,
                               pi_vSomenteIVATribut         IN VARCHAR2,
                               pi_vPesquisarCustos          IN VARCHAR2,
                               pi_vItemBonific              IN VARCHAR2,
                               pi_nVlFreteOutrasDesp        IN NUMBER,
                               po_nBaseStFonte             OUT NUMBER,
                               po_nValorStFonte            OUT NUMBER,
                               po_vMensagem                OUT VARCHAR2,
                               po_vRegimeEspIsenStFonte    OUT VARCHAR2,
                               po_nAliqIcms1               OUT NUMBER,
                               po_nAliqIcms2               OUT NUMBER,
                               po_nIva                     OUT NUMBER,
                               po_nPercBaseRedStFonte      OUT NUMBER,
                               pi_vTipoChamada              IN VARCHAR2 DEFAULT 'O',
                               pi_nQT                       IN NUMBER DEFAULT 0,
                               pi_nNumPedido                IN NUMBER DEFAULT NULL,
                               pi_nCodFilialNf              IN VARCHAR2,
                               po_nPautaFonte              OUT NUMBER,
                               po_vObservacaoStFonte       OUT VARCHAR2,
                               po_vIndEscalaRelevante      OUT VARCHAR2,
                               po_vCnpjFabricante          OUT VARCHAR2,
                               po_vFabricante              OUT VARCHAR2,
                               po_nVLBASEFCPICMS           OUT NUMBER,
                               po_nVLBASEFCPST             OUT NUMBER,
                               po_nVLBCFCPSTRET            OUT NUMBER,
                               po_nPERFCPSTRET             OUT NUMBER,
                               po_nVLFCPSTRET              OUT NUMBER,
                               po_nPERFCPSN                OUT NUMBER,
                               po_nVLFECP                  OUT NUMBER,
                               po_nVLACRESCIMOFUNCEP       OUT NUMBER,
                               po_nPERACRESCIMOFUNCEP      OUT NUMBER,
                               po_nALIQICMSFECP            OUT NUMBER,
                               po_nVLCREDFCPICMSSN         OUT NUMBER,
                               po_nCODCONFIGFUNCEPMED      OUT NUMBER,
                               pi_vOrdemCalculo             IN VARCHAR2 DEFAULT 'F',
                               pi_vMemoriaCalculo           IN VARCHAR2 DEFAULT 'N',
                               pi_nValorNotaFiscal          IN NUMBER   DEFAULT 0,
                               pi_vPedidoAvaria             IN VARCHAR  DEFAULT 'N',
                               po_nBCSTRETANTERIOR          OUT NUMBER,
                               po_nVLICMSSUBSTITUTOANTERIOR OUT NUMBER,                               
                               po_nVLICMSSTRETANTERIOR      OUT NUMBER,
                               po_nSTCLIENTEGNRE            OUT NUMBER,
                               po_nPMPF                     OUT NUMBER,
                               po_vClienteFonteSt           OUT VARCHAR2)
  IS
  
    -- Código da Filial de Faturamento - HIS.03371.2017
    vvCodFilialFaturamento       PCFILIAL.CODIGO%TYPE;
    
    -- Variáveis Auxiliares do Procedimento Principal
    v_iva                        PCTRIBUT.IVA%TYPE;
    v_ivafonte                   PCTRIBUT.IVAFONTE%TYPE;
    v_aliqicms1fonte             PCTRIBUT.ALIQICMS1FONTE%TYPE;
    v_aliqicms2fonte             PCTRIBUT.ALIQICMS2FONTE%TYPE;
    v_percbaseredstfonte         PCTRIBUT.PERCBASEREDSTFONTE%TYPE;
    v_percbaserednrpa            PCTRIBUT.PERBASEREDNRPA%TYPE;
    v_percbaseredconsumidor      PCTRIBUT.PERCBASEREDCONSUMIDOR%TYPE;
    v_utilizapercbaseredpf_trib  PCTRIBUT.UTILIZAPERCBASEREDPF%TYPE;
    v_tipocalcst                 PCCONSUM.TIPOCALCST%TYPE;
    v_calcstfontepf              PCCONSUM.CALCSTFONTEPF%TYPE;
    v_calcstpf                   PCCONSUM.CALCSTPF%TYPE;
    v_utilizapercbaseredpf_param PCCONSUM.UTILIZAPERCBASEREDPF%TYPE;
    v_clientefontest             PCCLIENT.CLIENTEFONTEST%TYPE;
    v_calculast                  PCCLIENT.CALCULAST%TYPE;
    v_ieent                      PCCLIENT.IEENT%TYPE;
    v_tipofj                     PCCLIENT.TIPOFJ%TYPE;
    v_isentoicms                 PCCLIENT.ISENTOICMS%TYPE;
    v_consumidorfinal            PCCLIENT.CONSUMIDORFINAL%TYPE;
    v_utilizaiesimplificada      PCCLIENT.UTILIZAIESIMPLIFICADA%TYPE;
    v_tipoempresa                PCCLIENT.TIPOEMPRESA%TYPE;
    v_consideraisentoscomopf     PCCONSUM.CONSIDERAISENTOSCOMOPF%TYPE;
    v_uffilial                   PCFILIAL.UF%TYPE;
    v_estent                     PCCLIENT.ESTENT%TYPE;
    v_usavalorultentbasest       PCTRIBUT.USAVALORULTENTBASEST%TYPE;
    v_valorultent                PCEST.VALORULTENT%TYPE;
    v_usaivafontediferenciado    PCCLIENT.USAIVAFONTEDIFERENCIADO%TYPE;
    v_ivafonte_cli               PCCLIENT.IVAFONTE%TYPE;
    v_AceitaPFContribuinte       PCCONSUM.ACEITAPFCONTRIBUINTE%TYPE;
    v_ALIQICMS1                  PCTRIBUT.ALIQICMS1%TYPE;
    v_ALIQICMS2                  PCTRIBUT.ALIQICMS2%TYPE;
    v_contribuinte               PCCLIENT.CONTRIBUINTE%TYPE;
    v_numcasasdecvenda           PCCONSUM.NUMCASASDECVENDA%TYPE;
    v_custonfsemst               PCEST.CUSTONFSEMST%TYPE;
    v_usavalorultentbasest2      PCTRIBUT.USAVALORULTENTBASEST2%TYPE;
    v_usapmcbasest               PCTRIBUT.USAPMCBASEST%TYPE;
    v_precomaxconsum             PCPRODUT.PRECOMAXCONSUM%TYPE;
    v_tipoclimed                 PCCLIENT.TIPOCLIMED%TYPE;
    v_isencaostorgaopub          PCTRIBUT.ISENCAOSTORGAOPUB%TYPE;
    v_usatributacaoporuf         PCCONSUM.USATRIBUTACAOPORUF%TYPE;
    v_codpraca                   PCCLIENT.CODPRACA%TYPE;
    v_numregiao                  PCREGIAO.NUMREGIAO%TYPE;
    v_usapmcuf                   PCPARAMFILIAL.VALOR%TYPE;
    v_usabaseicmsreduzida        PCTRIBUT.USABASEICMSREDUZIDA%TYPE;
    v_usabcrultent               PCTRIBUT.USABCRULTENT%TYPE;
    n_basebcrultent              PCEST.BASEBCR%TYPE;
    n_stbcrultent                PCEST.STBCR%TYPE;
    v_calcstpautafarmaciapopular PCPARAMFILIAL.VALOR%TYPE;
    n_pautafonte                 PCTRIBUT.PAUTAFONTE%TYPE;
    v_farmaciapopular            PCPRODUT.FARMACIAPOPULAR%TYPE;
    v_participafarmaciapopular   PCCLIENT.PARTICIPAFARMACIAPOPULAR%TYPE;
    v_usaptabelabasest           PCTRIBUT.USAPTABELABASEST%TYPE;
    v_simplesnacional            PCCLIENT.SIMPLESNACIONAL%TYPE; -- [HIS.05161.2014]
    n_percredpvendasimplesnac    PCTRIBUT.PERCREDPVENDASIMPLESNAC%TYPE; -- [HIS.05161.2014]
    v_tipomerc                   PCPRODUT.TIPOMERC%TYPE; -- [HIS.05161.2014]
    v_usadescsimplesnac          PCPARAMFILIAL.VALOR%TYPE; -- [HIS.05161.2014]
    v_usarajusteprecocmed        PCTRIBUT.USARAJUSTEPRECOCMED%TYPE;
    n_percajusteprecocmed        PCTRIBUT.PERCAJUSTEPRECOCMED%TYPE;
    v_usaregimeespisenstfonte    PCCLIENT.USAREGIMEESPISENSTFONTE%TYPE;
    v_regimeespisenstfonte       PCTRIBUT.REGIMEESPISENSTFONTE%TYPE;
    v_bnfnaocalculaicms          PCTRIBUT.BNFNAOCALCULAICMS%TYPE;
    v_medretirarstbnfestadual    PCPARAMFILIAL.VALOR%TYPE;
    v_medcalcularstpelopeps      PCPARAMFILIAL.VALOR%TYPE;
    v_medutilizarstfontesimplesnac  PCPARAMFILIAL.VALOR%TYPE;
    v_nqt_saldo                  PCPEDI.QT%TYPE;
    v_nqt_baixa                  PCPEDI.QT%TYPE;
    v_dtultprocessamentopeps     PCFILIAL.DTULTPROCESSAMENTOPEPS%TYPE;
    v_baseicstpeps               PCMOV.BASEICST%TYPE;
    v_stpeps                     PCMOV.ST%TYPE;
    v_percbaseredst              PCTRIBUT.PERCBASEREDST%TYPE;
    -- INICIO: HIS.03187.2015
    vUSAREGSIMPLCARGATRIBSTFONTE  PCCLIENT.USAREGSIMPLCARGATRIBSTFONTE%TYPE;
    vREGSIMPLCARGATRIBSTFONTE     PCTRIBUT.REGSIMPLCARGATRIBSTFONTE%TYPE;
    nPERCREGSIMPLCARGATRIBSTFONTE PCTRIBUT.PERCREGSIMPLCARGATRIBSTFONTE%TYPE;
    -- FIM: HIS.03187.2015
    v_precofabrica                PCPRODUT.CUSTOREP%TYPE; --// HIS.04408.2015
    vvMensagemPmc                 VARCHAR2(2000);         --// HIS.04408.2015
    -- ST Fonte Transferência
    vUSAREGRADIFSTFONTETV10       PCTRIBUT.USAREGRADIFSTFONTETV10%TYPE;
    -- 5661.146071.2016 
    vUSAREDUTORCAT49BASESTFONTE   PCTRIBUT.USAREDUTORCAT49BASESTFONTE%TYPE;
    nPERCREDUTORCAT49BASESTFONTE  PCTRIBUT.PERCREDUTORCAT49BASESTFONTE%TYPE;
    -- HIS.01277.2017
    vUSACARGAMINIMADEFERIMSTFONTE PCTRIBUT.USACARGAMINIMADEFERIMSTFONTE%TYPE; 
    nPERCARGAMINIMADEFERIMSTFONTE PCTRIBUT.PERCARGAMINIMADEFERIMSTFONTE%TYPE;
    vUSAVLSTMAIORPERCMINPMC       PCTRIBUT.USAVLSTMAIORPERCMINPMC%TYPE; 
    nPERVLSTMAIORPERCMINPMC       PCTRIBUT.PERVLSTMAIORPERCMINPMC%TYPE;	
    p_pautafonteaplicado          PCTRIBUT.PAUTAFONTE%TYPE;          -- HIS.01838.2017             
    v_participafuncep             PCCLIENT.PARTICIPAFUNCEP%TYPE;     -- HIS.04200.2017
    v_utilizamotorcalculo         PCTRIBUT.UTILIZAMOTORCALCULO%TYPE; -- HIS.04200.2017
    v_formulapvenda               PCTRIBUT.FORMULAPVENDA%TYPE;       -- HIS.04200.2017               
    v_peracrescimofuncep          PCTRIBUT.PERACRESCIMOFUNCEP%TYPE;  -- HIS.04200.2017               
    v_aliqicmsfecp                PCTRIBUT.ALIQICMSFECP%TYPE;        -- HIS.04200.2017 
    v_codconfigfuncepmed          PCTRIBUT.CODCONFIGFUNCEPMED%TYPE;
    --
    vUSAREDICMNORMVENDASTFONTE    PCTRIBUT.USAREDICMNORMVENDASTFONTE%TYPE; -- MED-1080
    vPERCBASERED                  PCTRIBUT.PERCBASERED%TYPE; -- MED-1080
    -- Contador da Memória de Cálculo
    iSeqMemoriaCalculo            INTEGER;
    -- Percentual de IPI na Venda
    v_percipivenda                PCPRODUT.PERCIPIVENDA%TYPE;
    -- Novos cálculos st fonte
    v_usavlultentmediobasest      PCTRIBUT.USAVLULTENTMEDIOBASEST%TYPE;
    n_percbasestrj                PCTRIBUT.PERCBASESTRJ%TYPE;
    n_vlultentmes                 PCTABPR.VLULTENTMES%TYPE;
    -- Alíquota que receberá a Aliq 1 do ST Fonte e a Alíquota FECP para ST Inverso - MED-1930
    vnAliq1StFonteFecp            NUMBER;
    vnFecpInverso                 NUMBER;
    -- Erro Tratado
    e_tratado                     EXCEPTION;
    -- Erro Benefícios Fiscais - DDMEDICA-7584
    e_benef_fiscais               EXCEPTION;
    -- Lesgilação teto para aplicar redução de PMC
    v_usaReducaoBasePmc PCTRIBUT.USAREDUCAOBASEPMC%TYPE;
    v_pertetoredbasepmc PCTRIBUT.PERTETOREDBASEPMC%TYPE;
    -- MED-2521 - Isenção ST Bonificação
    v_isencaostfontebonificacao   PCTRIBUT.ISENCAOSTFONTEBONIFICACAO%TYPE;
    --
    v_percbaseredst_mc            PCTRIBUT.PERCBASEREDST_MC%TYPE;
    v_iva_mc                      PCTRIBUT.IVA_MC%TYPE;
    v_pauta_mc                    PCTRIBUT.PAUTA_MC%TYPE;
    v_aliqicms1_mc                PCTRIBUT.ALIQICMS1_MC%TYPE;
    v_aliqicms2_mc                PCTRIBUT.ALIQICMS2_MC%TYPE;
    vUSARABAPERDASTFONTEPEDAVARIA PCTRIBUT.USARABAPERDASTFONTEPEDAVARIA%TYPE;
    -- PMPF de Medicamentos - DDMEDICA-1691
    v_usapmpfbasest               PCTRIBUT.USAPMPFBASEST%TYPE;
    vnPmPf                        PCTABMEDABCFARMA.PMPF%TYPE;
       
    -- DDMEDICA-7594 - Valores para Customização da Base ST com SUFRAMA/Redução PISCOFINS e DESONERACAO
    v_tipocalcsulframa            PCCONSUM.TIPOCALCSULFRAMA%TYPE;
    v_agregapiscofinsst1          PCTRIBUT.AGREGAPISCOFINSST1%TYPE;
    v_agregasuframast1            PCTRIBUT.AGREGASUFRAMAST1%TYPE;
    v_agregaicmsisencaost1        PCTRIBUT.AGREGAICMSISENCAOST1%TYPE;
    v_vagregapiscofinsst2         PCTRIBUT.AGREGAPISCOFINSST2%TYPE;
    v_agregasuframast2            PCTRIBUT.AGREGASUFRAMAST2%TYPE;
    v_agregaicmsisencaost2        PCTRIBUT.AGREGAICMSISENCAOST2%TYPE;
    v_sulframa                    PCCLIENT.SULFRAMA%TYPE;
    v_orgaopub                    PCCLIENT.ORGAOPUB%TYPE;
    v_orgaopubfederal             PCCLIENT.ORGAOPUBFEDERAL%TYPE;
    v_orgaopubmunicipal           PCCLIENT.ORGAOPUBMUNICIPAL%TYPE;    
    v_perdescsuframa              PCTRIBUT.PERDESCSUFRAMA%TYPE;
    v_perdescpissuframa           PCTRIBUT.PERDESCPISSUFRAMA%TYPE;
    v_percdescpis                 PCTRIBUT.PERCDESCPIS%TYPE;
    v_percdesccofins              PCTRIBUT.PERCDESCCOFINS%TYPE;
    v_tipodescisencao             PCCLIENT.TIPODESCISENCAO%TYPE;
    v_perdescisentoicms           PCCLIENT.PERDESCISENTOICMS%TYPE;
    v_perdescicmisencao           PCTRIBUT.PERDESCICMISENCAO%TYPE;
    v_aplicadescisencaomed        PCTRIBUT.APLICADESCISENCAOMED%TYPE;
    v_destacdescicmisencaocomerc  PCTRIBUT.DESTACDESCICMISENCAOCOMERCIAL%TYPE;
    vnVlDescReducaoPis            NUMBER;
    vnPercDescReducaoPisAuxBF     NUMBER;
    vnVlDescReducaoCofins         NUMBER;
    vnPercDescReducaoCofinsAuxBF  NUMBER;
    vnVlDescIcmIsencao            NUMBER;
    vnPercDescIcmIsencaoAuxBF     NUMBER;
    vnVlDescSuframa               NUMBER;
    vnPercDescSuframaAuxBF        NUMBER;
    vnPrecoLiqResultAuxBF         NUMBER;
    vnPrecoTabResultAuxBF         NUMBER;
    vnPrecoRcaResultAuxBF         NUMBER;
    vvErrosBenefFiscais           VARCHAR2(255);
    vvMsgErrosBenefFiscais        VARCHAR2(4000);
    v_destacicmsstanterior        PCTRIBUT.DESTACICMSSTANTERIOR%TYPE;
    v_tipocalculognre             PCTRIBUT.TIPOCALCULOGNRE%TYPE;
           
   /*************************************
    PROCEDURE: P_INSERIR_MEMORIA_CALCULO
    DESCRICAO: Inserir Memória de Cálculo
    *************************************/
    PROCEDURE P_INSERIR_MEMORIA_CALCULO(pi_vOperacao        IN VARCHAR2,
                                        pi_vDescricao       IN VARCHAR2,                                      
                                        pi_nValorAcumulado  IN NUMBER,
                                        pi_nPercentual      IN NUMBER DEFAULT NULL,
                                        pi_nValor           IN NUMBER DEFAULT NULL,
                                        pi_vGravarValorZero IN BOOLEAN DEFAULT FALSE)
    IS
    BEGIN
    
      IF (pi_vMemoriaCalculo = 'S') THEN
    
        iSeqMemoriaCalculo := NVL(iSeqMemoriaCalculo,0) + 1;
        
        -- Se Soma ou Subtração tem que ter Valor
        IF (NVL(pi_vOperacao,' ') NOT IN ('+','-')) OR
           ( (NVL(pi_vOperacao,' ') IN ('+','-')) AND (NVL(pi_nValor,0) > 0) ) OR
           ( (NVL(pi_vOperacao,' ') IN ('+','-')) AND (NVL(pi_nValor,0) = 0) AND (pi_vGravarValorZero) ) THEN    
           
          INSERT INTO PCMED_MEMORIA_CALCULO_ST     
                    ( CODPROD
                    , ORIGEM
                    , SEQ
                    , OPERACAO
                    , DESCRICAO
                    , PERCENTUAL
                    , VALOR
                    , VALORACUMULADO
                    , FLAGRESUMO )
             VALUES ( pi_nCodProd
                    , ('S'||pi_vOrdemCalculo)
                    , iSeqMemoriaCalculo
                    , pi_vOperacao
                    , pi_vDescricao
                    , pi_nPercentual
                    , pi_nValor
                    , pi_nValorAcumulado
                    , 'S' );
                    
        END IF;
  
      END IF;
      
    END P_INSERIR_MEMORIA_CALCULO;
  
   /**********************************************
    PROCEDURE: P_INSERE_OPCAO_MEMORIA_CALCULO
    DESCRICAO: Inserir Opção na Memória de Cálculo
    **********************************************/
    PROCEDURE P_INSERE_OPCAO_MEMORIA_CALCULO(pi_vDescricao     IN VARCHAR2,
                                             pi_vOpcaoCondicao IN VARCHAR2,
                                             pi_vOpcaoValor    IN VARCHAR2 DEFAULT NULL)
    IS
    BEGIN
  
      IF (pi_vMemoriaCalculo = 'S') THEN
         
        iSeqMemoriaCalculo := NVL(iSeqMemoriaCalculo,0) + 1;
        
        INSERT INTO PCMED_MEMORIA_CALCULO_ST     
                  ( CODPROD
                  , ORIGEM
                  , SEQ
                  , OPERACAO
                  , OPCAOCONDICAO
                  , OPCAOVALOR
                  , DESCRICAO
                  , FLAGRESUMO )
           VALUES ( pi_nCodProd
                  , ('S'||pi_vOrdemCalculo)
                  , iSeqMemoriaCalculo
                  , '?'
                  , pi_vOpcaoCondicao
                  , pi_vOpcaoValor
                  , pi_vDescricao
                  , 'N' );
                  
      END IF;
      
    END P_INSERE_OPCAO_MEMORIA_CALCULO;
  
   /************************************************
    PROCEDURE: P_ATU_OPCAO_MEMORIA_CALCULO
    DESCRICAO: Atualizar Opção na Memória de Cálculo
    ************************************************/
    PROCEDURE P_ATU_OPCAO_MEMORIA_CALCULO(pi_vOpcaoCondicao IN VARCHAR2,
                                          pi_vOpcaoValor    IN VARCHAR2 DEFAULT NULL)
    IS                                         
    BEGIN
    
      IF (pi_vMemoriaCalculo = 'S') THEN
  
        iSeqMemoriaCalculo := NVL(iSeqMemoriaCalculo,0) + 1;
        
        -- Limpa Opções Marcadas
        UPDATE PCMED_MEMORIA_CALCULO_ST     
           SET OPCAOSEL   = NULL
             , FLAGRESUMO = 'N'
         WHERE (CODPROD       = pi_nCodProd)
           AND (ORIGEM        = ('S'||pi_vOrdemCalculo))
           AND (OPCAOCONDICAO = pi_vOpcaoCondicao);
  
        -- Atualiza somente Opção passada no Parâmetro
        UPDATE PCMED_MEMORIA_CALCULO_ST     
           SET OPCAOSEL   = '*'
         WHERE (CODPROD       = pi_nCodProd)
           AND (ORIGEM        = ('S'||pi_vOrdemCalculo))
           AND (OPCAOCONDICAO = pi_vOpcaoCondicao) 
           AND (OPCAOVALOR    = pi_vOpcaoValor);
           
        -- Se opção marcada diferente de NAO, indica que vai mostrar Pergunta no Resumo
        IF (pi_vOpcaoValor <> 'NAO') THEN
          UPDATE PCMED_MEMORIA_CALCULO_ST     
             SET FLAGRESUMO = 'S'
           WHERE (CODPROD       = pi_nCodProd)
             AND (ORIGEM = ('S'||pi_vOrdemCalculo))
             AND (OPCAOCONDICAO = pi_vOpcaoCondicao) 
             AND (OPCAOVALOR    IS NULL); -->> Atualiza o Registro que guarda a Pergunta
          UPDATE PCMED_MEMORIA_CALCULO_ST     
             SET FLAGRESUMO = 'S'
           WHERE (CODPROD       = pi_nCodProd)
             AND (ORIGEM        = ('S'||pi_vOrdemCalculo))
             AND (OPCAOCONDICAO = pi_vOpcaoCondicao) 
             AND (OPCAOVALOR    = pi_vOpcaoValor);
        END IF;
                  
      END IF;
      
    END P_ATU_OPCAO_MEMORIA_CALCULO;
  
   /***************************
    PROCEDURE: P_OBTER_STFONTE 
    DESCRICAO: Obter o ST FONTE
    ***************************/
    PROCEDURE P_OBTER_STFONTE
      (p_codprod                    IN NUMBER,
       p_condvenda                  IN NUMBER,
       p_percvenda                  IN NUMBER,
       p_iva                        IN NUMBER,
       p_ivafonte                   IN NUMBER,
       p_aliqicms1fonte             IN NUMBER,
       p_aliqicms2fonte             IN NUMBER,
       p_percbaseredstfonte         IN NUMBER,
       p_percbaserednrpa            IN NUMBER,
       p_percbaseredconsumidor      IN NUMBER,
       p_utilizapercbaseredpf_trib  IN VARCHAR2,
       p_tipocalcst                 IN VARCHAR2,
       p_calcstpf                   IN VARCHAR2,
       p_utilizapercbaseredpf       IN VARCHAR2,
       p_clientefontest             IN VARCHAR2,
       p_calculast                  IN VARCHAR2,
       p_ieent                      IN VARCHAR2,
       p_tipofj                     IN VARCHAR2,
       p_isentoicms                 IN VARCHAR2,
       p_consumidorfinal            IN VARCHAR2,
       p_utilizaiesimplificada      IN VARCHAR2,
       p_tipoempresa                IN VARCHAR2,
       p_consideraisentoscomopf     IN VARCHAR2,
       p_pvenda                     IN NUMBER,
       p_vlipi                      IN NUMBER,
       p_uffilial                   IN VARCHAR2,
       p_estent                     IN VARCHAR2,
       p_usavalorultentbasest       IN VARCHAR2,
       p_valorultent                IN NUMBER,
       p_usaivafontediferenciado    IN VARCHAR2,
       p_ivafonte_cli               IN NUMBER,
       p_AceitaPFContribuinte       IN VARCHAR,
       p_ALIQICMS1                  IN NUMBER,
       p_ALIQICMS2                  IN NUMBER,
       p_contribuinte               IN VARCHAR2,
       p_numcasasdecvenda           IN NUMBER,
       p_custonfsemst               IN NUMBER,
       p_usavalorultentbasest2      IN VARCHAR2,
       p_usapmcbasest               IN VARCHAR2,
       p_precomaxconsum             IN NUMBER,
       p_tipoclimed                 IN VARCHAR2,
       p_isencaostorgaopub          IN VARCHAR2,
       p_usabaseicmsreduzida        IN VARCHAR2,
       p_usabcrultent               IN VARCHAR2,
       p_basebcrultent              IN NUMBER,
       p_stbcrultent                IN NUMBER,
       p_CALCSTPAUTAFARMACIAPOPULAR IN VARCHAR2,
       p_PAUTAFONTE                 IN NUMBER,
       p_FARMACIAPOPULAR            IN VARCHAR2,
       p_PARTICIPAFARMACIAPOPULAR   IN VARCHAR2, 
       p_usaptabelabasest           IN VARCHAR2,
       p_ptabela                    IN NUMBER,
       p_SomenteIVATribut           IN VARCHAR2 DEFAULT 'N',
       p_usadescsimplesnac          IN VARCHAR2 DEFAULT 'N',
       p_simplesnacional            IN VARCHAR2 DEFAULT 'N', 
       p_percredpvendasimplesnac    IN NUMBER   DEFAULT 0  ,
       p_tipomerc                   IN VARCHAR2 DEFAULT ' ',
       p_usarajusteprecocmed        IN VARCHAR2 DEFAULT 'N',
       p_percajusteprecocmed        IN NUMBER   DEFAULT 0  ,
       p_usaregimeespisenstfonte    IN VARCHAR2 DEFAULT 'N',
       p_regimeespisenstfonte       IN VARCHAR2 DEFAULT 'N',
       p_medretirarstbnfestadual    IN VARCHAR2 DEFAULT 'N',
       p_itembonific                IN VARCHAR2 DEFAULT 'N',
       p_vlfreteoutrasdesp          IN NUMBER   DEFAULT 0,
       p_bnfnaocalculaicms          IN VARCHAR2 DEFAULT 'N',
       p_USAREGSIMPLCARGATRIBSTFONTE  IN VARCHAR2 DEFAULT 'N', -- HIS.03187.2015
       p_REGSIMPLCARGATRIBSTFONTE     IN VARCHAR2 DEFAULT 'N', -- HIS.03187.2015
       p_PERCREGSIMPLCARGATRIBSTFONTE IN NUMBER   DEFAULT 0,   -- HIS.03187.2015     
       p_USAREDUTORCAT49BASESTFONTE   IN VARCHAR2 DEFAULT 'N', -- 5661.146071.2016
       p_PERCREDUTORCAT49BASESTFONTE  IN NUMBER   DEFAULT 0,   -- 5661.146071.2016                  
       p_USACARGAMINIMADEFERIMSTFONTE IN VARCHAR2 DEFAULT 'N', -- HIS.01277.2017
       p_PERCARGAMINIMADEFERIMSTFONTE IN NUMBER   DEFAULT 0,   -- HIS.01277.2017          
       p_USAVLSTMAIORPERCMINPMC       IN VARCHAR2 DEFAULT 'N', -- DDVENDAS-40134
       p_PERVLSTMAIORPERCMINPMC       IN NUMBER   DEFAULT 0,   -- DDVENDAS-40134
       po_nBaseStFonte               OUT NUMBER,
       po_nValorStFonte              OUT NUMBER,
       po_vMensagem                  OUT VARCHAR2,
       po_vRegimeEspIsenStFonte      OUT VARCHAR2,
       po_nAliqIcms1                 OUT NUMBER,
       po_nAliqIcms2                 OUT NUMBER,
       po_nIva                       OUT NUMBER,
       po_nPercBaseRedStFonte        OUT NUMBER,
       po_nPautaFonte                OUT NUMBER,   -- HIS.01838.2017             
       po_vObservacaoStFonte         OUT VARCHAR2, -- HIS.01838.2017             
       p_codfilialfaturamento        IN VARCHAR2,  -- HIS.03371.2017
       p_indescalarelevante          IN VARCHAR2,  -- HIS.03371.2017
       p_participafuncep             IN VARCHAR2,  -- HIS.04200.2017
       p_utilizamotorcalculo         IN VARCHAR2,  -- HIS.04200.2017
       p_formulapvenda               IN VARCHAR2,  -- HIS.04200.2017             
       p_peracrescimofuncep          IN NUMBER,    -- HIS.04200.2017               
       p_aliqicmsfecp                IN NUMBER,    -- HIS.04200.2017
       p_codconfigfuncepmed          IN NUMBER,     
       p_vlbasefcpicms               OUT NUMBER,   -- HIS.04200.2017
       p_vlbasefcpst                 OUT NUMBER,   -- HIS.04200.2017
       p_vlbcfcpstret                OUT NUMBER,   -- HIS.04200.2017
       p_perfcpstret                 OUT NUMBER,   -- HIS.04200.2017
       p_vlfcpstret                  OUT NUMBER,   -- HIS.04200.2017
       p_perfcpsn                    OUT NUMBER,   -- HIS.04200.2017
       p_vlfecp                      OUT NUMBER,   -- HIS.04200.2017
       p_vlacrescimofuncep           OUT NUMBER,   -- HIS.04200.2017
       p_vlcredfcpicmssn             OUT NUMBER,   -- HIS.04200.2017                                            
       po_nPerAcrescimoFuncep        OUT NUMBER,   -- HIS.04200.2017                                            
       po_nAliqIcmsFecp              OUT NUMBER,   -- HIS.04200.2017                                            
       po_nCodConfigFuncepMed        OUT NUMBER,
       p_USAREDICMNORMVENDASTFONTE   IN VARCHAR2,  -- MED-1080
       p_PERCBASERED                 IN NUMBER,    -- MED-1080
       p_percipivenda                IN NUMBER,
       p_usavlultentmediobasest      IN VARCHAR2, 
       p_percbasestrj                IN NUMBER,
       p_vlultentmes                 IN NUMBER,
       p_valornotafiscal             IN NUMBER,
       p_usaReducaoBasePmc           IN VARCHAR2 DEFAULT 'N', -- MED-2428
       p_pertetoredbasepmc           IN NUMBER   DEFAULT 0,   -- MED-2428
       p_isencaostfontebonificacao   IN VARCHAR2, -- MED-2521
       p_usapmpfbasest               IN VARCHAR2,
       p_pmpf                        IN NUMBER,
       -- DDMEDICA-7594
       p_agregapiscofinsst1          IN VARCHAR2,
       p_agregasuframast1            IN VARCHAR2,
       p_agregaicmsisencaost1        IN VARCHAR2,
       p_agregapiscofinsst2          IN VARCHAR2,
       p_agregasuframast2            IN VARCHAR2,
       p_agregaicmsisencaost2        IN VARCHAR2,
       p_vldescreducaopis            IN NUMBER,
       p_vldescreducaocofins         IN NUMBER,
       p_vldescicmisencao            IN NUMBER,
       p_vldescsuframa               IN NUMBER,
       v_destacicmsstanterior        IN VARCHAR2,
       po_nBcStRetAnterior          OUT NUMBER,
       po_nVlIcmsSubstitutoAnterior OUT NUMBER,
       po_nVlIcmsStRetAnterior      OUT NUMBER,
       p_tipocalculognre             IN VARCHAR2,
       po_nStClienteGnre            OUT NUMBER,
       po_nPmPf                     OUT NUMBER)
    IS
    
      -- Preço de Venda sem Impostos
      vnPrecoVendaSemImpostos        NUMBER;
  
      -- Variaveis Auxiliares
      n_ivafonte                     NUMBER;
      n_aliqicms1fonte               NUMBER;
      n_aliqicms2fonte               NUMBER;
      n_percbaseredstfonte           NUMBER;
      --
      vvusabaseicmsreduzida          pctribut.usabaseicmsreduzida%type;
      -- 5661.146071.2016
      vnPercBaseRedStFonteAlterado   NUMBER;
      
      vnRetVlFreteOutrasDespBaseSt   NUMBER; -- MED-2346
      vnRetPercBaseRedIcmsFecp       NUMBER; -- MED-2346
      
      -- Valores para gravação do ST recolhido anteriormente
      vvRetEnquadraIcmsSubstAnterior VARCHAR2(1);
      vnRetVlIcmsSubstitutoAnterior  NUMBER;
      
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      -- FUNCTION FCALCULARSTFONTE
      --42 parametros ( mas pode ser usada pode packages que utilizam a de 38 parÂmetros)
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      FUNCTION FCALCULARSTFONTE(p_codprod                    IN NUMBER,
                                p_condvenda                  IN NUMBER,
                                p_percvenda                  IN NUMBER,
                                p_iva                        IN NUMBER,
                                p_ivafonte                   IN OUT NUMBER,
                                p_aliqicms1fonte             IN OUT NUMBER,
                                p_aliqicms2fonte             IN OUT NUMBER,
                                p_percbaseredstfonte         IN OUT NUMBER,
                                p_percbaserednrpa            IN NUMBER,
                                p_percbaseredconsumidor      IN NUMBER,
                                p_utilizapercbaseredpf_trib  IN VARCHAR2,
                                p_tipocalcst                 IN VARCHAR2,
                                p_calcstpf                   IN VARCHAR2,
                                p_utilizapercbaseredpf       IN VARCHAR2,
                                p_clientefontest             IN VARCHAR2,
                                p_calculast                  IN VARCHAR2,
                                p_ieent                      IN VARCHAR2,
                                p_tipofj                     IN VARCHAR2,
                                p_isentoicms                 IN VARCHAR2,
                                p_consumidorfinal            IN VARCHAR2,
                                p_utilizaiesimplificada      IN VARCHAR2,
                                p_tipoempresa                IN VARCHAR2,
                                p_consideraisentoscomopf     IN VARCHAR2,
                                p_pvenda                     IN NUMBER,
                                p_vlipi                      IN NUMBER,
                                p_uffilial                   IN VARCHAR2,
                                p_estent                     IN VARCHAR2,
                                p_usavalorultentbasest       IN VARCHAR2,
                                p_valorultent                IN NUMBER,
                                p_usaivafontediferenciado    IN VARCHAR2,
                                p_ivafonte_cli               IN NUMBER,
                                p_AceitaPFContribuinte       IN VARCHAR,
                                p_ALIQICMS1                  IN NUMBER,
                                p_ALIQICMS2                  IN NUMBER,
                                p_contribuinte               IN VARCHAR2,
                                p_numcasasdecvenda           in NUMBER,
                                p_baseicst                   IN OUT NUMBER,
                                p_PercBaseRedStFonteAlterado OUT NUMBER, -->> SE A LEGISLAÇÃO MUDAR O % DE REDUÇÃO DO CADASTRO - 5661.146071.2016
                                p_mensagem                   OUT VARCHAR2,
                                P_CUSTONFSEMST               in pcest.custonfsemst%type default 0,
                                p_usavalorultentbasest2      in pctribut.usavalorultentbasest2%type default 'N',
                                p_usapmcbasest               in pctribut.usapmcbasest%type default 'N' ,
                                p_precomaxconsum             in pcprodut.precomaxconsum%type default 0 ,
                                p_usabaseicmsreduzida        in pctribut.usabaseicmsreduzida%type default 'N',
                                p_usabcrultent               IN VARCHAR2,
                                p_basebcrultent              IN NUMBER,
                                p_stbcrultent                IN NUMBER,
                                p_CALCSTPAUTAFARMACIAPOPULAR IN VARCHAR2,
                                p_PAUTAFONTE                 IN NUMBER,
                                p_FARMACIAPOPULAR            IN VARCHAR2,
                                p_PARTICIPAFARMACIAPOPULAR   IN VARCHAR2,   
                                p_usaptabelabasest           IN VARCHAR2,
                                p_ptabela                    IN NUMBER,
                                p_somenteIVATribut           IN VARCHAR2,
                                p_usadescsimplesnac          IN VARCHAR2,
                                p_simplesnacional            IN VARCHAR2,
                                p_percredpvendasimplesnac    IN NUMBER,
                                p_tipomerc                   IN VARCHAR2,
                                p_usarajusteprecocmed        IN VARCHAR2,
                                p_percajusteprecocmed        IN NUMBER,
                                p_medretirarstbnfestadual    IN VARCHAR2,
                                p_itembonific                IN VARCHAR2,
                                p_vlfreteoutrasdesp          IN NUMBER,
                                p_bnfnaocalculaicms          IN VARCHAR2,
                                p_USAREGSIMPLCARGATRIBSTFONTE  IN VARCHAR2 DEFAULT 'N',
                                p_REGSIMPLCARGATRIBSTFONTE     IN VARCHAR2 DEFAULT 'N',
                                p_PERCREGSIMPLCARGATRIBSTFONTE IN NUMBER   DEFAULT 0,
                                p_USAREDUTORCAT49BASESTFONTE   IN VARCHAR2 DEFAULT 'N',
                                p_PERCREDUTORCAT49BASESTFONTE  IN NUMBER   DEFAULT 0,
                                p_USACARGAMINIMADEFERIMSTFONTE IN VARCHAR2 DEFAULT 'N',
                                p_PERCARGAMINIMADEFERIMSTFONTE IN NUMBER   DEFAULT 0,
                                p_USAVLSTMAIORPERCMINPMC       IN VARCHAR2 DEFAULT 'N',
                                p_PERVLSTMAIORPERCMINPMC       IN NUMBER   DEFAULT 0,								
                                p_pautafonteaplicado           OUT NUMBER,
                                p_observacaostfonte            OUT VARCHAR2,
                                p_codfilialfaturamento         IN VARCHAR2,
                                p_USAREDICMNORMVENDASTFONTE    IN VARCHAR2,
                                p_PERCBASERED                  IN NUMBER,
                                p_percipivenda                 IN NUMBER,
                                p_usavlultentmediobasest       IN VARCHAR2, 
                                p_percbasestrj                 IN NUMBER,
                                p_vlultentmes                  IN NUMBER,
                                po_nVlFreteOutrasDespBaseIcms  OUT NUMBER,
                                po_nPercBaseRedIcmsFecp        OUT NUMBER,
                                p_usaReducaoBasePmc            IN VARCHAR2 DEFAULT 'N',
                                p_pertetoredbasepmc            IN NUMBER   DEFAULT 0,
                                p_usapmpfbasest                in pctribut.usapmpfbasest%type,
                                p_pmpf                         IN NUMBER,
                                p_agregapiscofinsst1           IN VARCHAR2,
                                p_agregasuframast1             IN VARCHAR2,
                                p_agregaicmsisencaost1         IN VARCHAR2,
                                p_vagregapiscofinsst2          IN VARCHAR2,
                                p_agregasuframast2             IN VARCHAR2,
                                p_agregaicmsisencaost2         IN VARCHAR2,
                                p_vldescreducaopis             IN NUMBER,
                                p_vldescreducaocofins          IN NUMBER,
                                p_vldescicmisencao             IN NUMBER,
                                p_vldescsuframa                IN NUMBER,
                                po_vEnquadraIcmsSubstAnterior OUT VARCHAR2,
                                po_nVlIcmsSubstitutoAnterior  OUT NUMBER,
                                po_nPmPf                      OUT NUMBER)
      RETURN NUMBER IS
      
        -- Variáveis Locais da Função
        vnpercbasered                  NUMBER;
        vnpercbaseredBaseCred          NUMBER;
        vnpercbaseredIcmsFecp          NUMBER;
        vnbcst                         NUMBER;
        vnstf1                         NUMBER;
        vnstf2                         NUMBER;
        vnstfonte                      NUMBER;
        vnpbase                        NUMBER;
        vbPessoaFisica                 BOOLEAN;
        vscontribuinte                 PCCLIENT.CONTRIBUINTE%TYPE;
        vnIvaFonte                     NUMBER;
        vbCalculaSTFonte               BOOLEAN;
        vnpvenda                       NUMBER;
        vncustonfsemst                 PCEST.CUSTONFSEMST%TYPE;
        -- Regra Farmácia Popular
        vbRegraFciaPopular             BOOLEAN;
        -- Regra Usar PMC na Base do ST
        vbUsaPmcBaseSt                 BOOLEAN;
        -- PMC de Referência para Ajuste Preço CMED
        vnPmcAjustePrecoCMED           NUMBER;
        -- Valor do Frete e Despesas Acessórias a Somar nas Base de ST
        vnVlFreteOutrasDespBaseSt      NUMBER;
        -- Valor do Frete e Despesas Acessórias a Somar nas Base de ICMS
        vnVlFreteOutrasDespBaseIcms    NUMBER;
        -- Se usa Regra Regime Simplificado pela Carga Tributária Média                   
        vbUsaRegraRegSimplCargaTrib    BOOLEAN;
        vnBcIcmsOperPropriaCargaTribut NUMBER;
        vnVlIcmsOperPropriaCargaTribut NUMBER;
        vnBcEstimatSimplifCargaTribut  NUMBER;
        vnVlEstimatSimplifCargaTribut  NUMBER;
        -- Se usa ST da Última Entrada
        vbUsaRegraStUltimaEntrada      BOOLEAN;
        -- Se Ignorar ST Fonte no TV 10 quando valores zerados na tributação
        vvIgnorarSTFonteTV10Zerado     VARCHAR2(1);  
        -- Regra Exceção ST Fonte Paraná
        vvUsaRegraSTParanaOutrasDesp   VARCHAR2(1);
        -- Base ST Original sem Redução - 5661.146071.2016
        vnBaseStOriginalSemReducao     NUMBER;
        -- HIS.01277.2017
        vnStFonteCargaMinima           NUMBER;
        vnStPercMinPMC                 NUMBER;		
        -- Variáveis Auxiliares da Memória de Calculo
        vnPercMemoriaCalculo           NUMBER;
        vnValorCalculadoMemoriaCalculo NUMBER;
        vvDescOpcaoSelMemoriaCalculo   VARCHAR2(200);
        -- Variáveis para cálculo do ST RJ
        vnBaseStRj                     NUMBER;
        vnValorStRj                    NUMBER;
        vnPercBaseRedRj                NUMBER;
        -- Regra Usar PMPF na Base do ST
        vbUsaPmPfBaseSt                BOOLEAN;
        -- DDMEDICA-7594 - Valores para Customização da Base ST com SUFRAMA/Redução PISCOFINS e DESONERACAO
        -- B1 = Base da Alíquota 1,  B2 = Base da Alíquota 2
        vnVlDescReducaoPisCofins_B1    NUMBER;
        vnVlDescSuframaPisSuframa_B1   NUMBER;
        vnVlDescIcmIsencao_B1          NUMBER;
        vbUsouIVAFonte_B1              BOOLEAN;
        vnVlDescReducaoPisCofins_B2    NUMBER;
        vnVlDescSuframaPisSuframa_B2   NUMBER;
        vnVlDescIcmIsencao_B2          NUMBER;
         
      BEGIN
         
       /********************
        Inicializa Variáveis
        ********************/
      
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte         := 'St.Fonte';
      
        -- Regra Farmácia Popular
        vbRegraFciaPopular          := ( (NVL(p_CALCSTPAUTAFARMACIAPOPULAR,'N') = 'S') and
                                         (NVL(p_FARMACIAPOPULAR,'N') = 'S') and
                                         (NVL(p_PARTICIPAFARMACIAPOPULAR,'N') = 'S') and
                                         (NVL(p_PAUTAFONTE,0) > 0) );
       
        -- Regra Usar PMC na Base do ST
        vbUsaPmcBaseSt              := ( (NVL(p_PRECOMAXCONSUM,0) > 0) and
                                         (NVL(p_USAPMCBASEST,'N') = 'S') );
  
        -- Rgra Usa ST da Última Entrada (Se não for Consumidor Final)
        vbUsaRegraStUltimaEntrada   := ( (NVL(p_usabcrultent,'N')     = 'S') AND
                                         (NVL(p_consumidorfinal,'N') <> 'S') ); 
  
        -- Regra Regime Simplificado pela Carga Tributária Média -- HIS.03187.2015                                    
        vbUsaRegraRegSimplCargaTrib := ( (NVL(p_USAREGSIMPLCARGATRIBSTFONTE,'N') = 'S') and
                                         (NVL(p_REGSIMPLCARGATRIBSTFONTE,'N')    = 'S') and
                                         (NVL(p_PERCREGSIMPLCARGATRIBSTFONTE,0)  > 0) );
                              
        -- Regra Usar PMPF na Base do ST
        vbUsaPmPfBaseSt             := ( (NVL(p_PMPF,0) > 0) and
                                         (NVL(p_USAPMPFBASEST,'N') = 'S') );
                              
        -- Regra Exceção ST Fonte Paraná para Somar Outras Despesas na Base ICMS com PMC na Base do ST                                      
        BEGIN
          SELECT VALOR
            INTO vvUsaRegraSTParanaOutrasDesp
            FROM PCREGRASEXCECAOMED
           WHERE (CODFILIAL = '99')
             AND (NOME      = 'USAREGRASTPARANAOUTRASDESP');
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvUsaRegraSTParanaOutrasDesp := 'N';
        END;                     
  
       /***************************
        Inicializa Outras Variáveis
        ***************************/
  
        -- Retorno - SE A LEGISLAÇÃO MUDAR O % DE REDUÇÃO DO CADASTRO - 5661.146071.2016      
        p_PercBaseRedStFonteAlterado := NULL; 
  
        -- MED-2346 - Valores para FECP
        po_nVlFreteOutrasDespBaseIcms := NULL; 
        po_nPercBaseRedIcmsFecp       := NULL; 
        
        -- Outras Variáveis
        vnbcst                        := 0;
        vnstf1                        := 0;
        vnstf2                        := 0;
        vnstfonte                     := 0;
        vbPessoaFisica                := False;
        vnIvaFonte                    := p_IVAFONTE;
        vbCalculaSTFonte              := True;
        --
        vscontribuinte                := p_contribuinte;
        --
        vnpvenda                      := p_pvenda;
        --
        vnVlFreteOutrasDespBaseSt     := 0;
        vnVlFreteOutrasDespBaseIcms   := 0;           
        -- DDMEDICA-7594 - Valores para Customização da Base ST com SUFRAMA/Redução PISCOFINS e DESONERACAO
        vnVlDescReducaoPisCofins_B1   := 0;
        vnVlDescSuframaPisSuframa_B1  := 0;
        vnVlDescIcmIsencao_B1         := 0;
        vbUsouIVAFonte_B1             := FALSE;                 
        vnVlDescReducaoPisCofins_B2   := 0;
        vnVlDescSuframaPisSuframa_B2  := 0;
        vnVlDescIcmIsencao_B2         := 0;
        -- Valores para gravação do ST recolhido anteriormente
        po_vEnquadraIcmsSubstAnterior := 'N';
        po_nVlIcmsSubstitutoAnterior  := 0;

        -- Custo NF sem ST
        vncustonfsemst   := p_custonfsemst;   
        if nvl(P_CUSTONFSEMST,0) = 0 then
           vnCUSTONFSEMST := p_valorultent;    
        end if;
      
        -- Definindo se é Pessoa Física
        if (p_AceitaPFContribuinte = 'N') then
          vscontribuinte := p_AceitaPFContribuinte;
        end if;
      
        if (((p_TIPOFJ = 'F') and (p_UTILIZAIESIMPLIFICADA = 'N')) or
           (p_CONSUMIDORFINAL = 'S') or
           ((p_CONSIDERAISENTOSCOMOPF = 'S') and
           ((Trim(p_IEENT) = '') or (p_IEENT = 'ISENTO') or
           (p_IEENT = 'ISENTA')))) and (vscontribuinte = 'N') then
          vbpessoafisica := true;
        end if;
      
       /**********************
        Define se Usa ST Fonte
        **********************/
      
        -- Identificar a incidência de ST Fonte [RDB05]
        vbCalculaSTFonte := (p_CLIENTEFONTEST = 'S')  and
                            ((p_ALIQICMS1FONTE > 0) or (p_ALIQICMS2FONTE > 0));-- and  ((p_ALIQICMS1 = 0) or (p_ALIQICMS2 = 0));
      
        vbCalculaSTFonte := vbCalculaSTFonte and
                            (not ((p_CALCSTPF = 'N') and (vbpessoafisica)));
        
        -- Item Bonificado com Regime Especial pra Retirar ST da Bonificação da NF Estadual
        IF ((NVL(p_itembonific,'N') = 'S') AND
            (NVL(p_medretirarstbnfestadual,'N') = 'S') AND
            (p_uffilial = p_estent)) THEN
          vbCalculaSTFonte            := FALSE;
          vbUsaRegraRegSimplCargaTrib := FALSE; -- HIS.03187.2015
        END IF;
        
        -- Se for Pedido TV10
        IF (pi_nCondVenda = 10) THEN
      
          -- Verifica exceção para ignorar ST Fonte TV 10 quando valores zerados na tibutação
          BEGIN
            SELECT NVL(VALOR,'N')
              INTO vvIgnorarSTFonteTV10Zerado
              FROM PCREGRASEXCECAOMED
             WHERE NOME      = 'IGNORARSTFONTETV10ZERADO'
               AND CODFILIAL = '99';  
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vvIgnorarSTFonteTV10Zerado := 'N';
          END;     
        
          -- Se possuir a regra
          IF vvIgnorarSTFonteTV10Zerado = 'S' THEN
            -- Reinicializa a variável
            vvIgnorarSTFonteTV10Zerado := 'N';
            -- Verifica se os campos estão zerados 
            BEGIN
              SELECT 'S'
                INTO vvIgnorarSTFonteTV10Zerado
                FROM PCTRIBUT 
               WHERE CODST = pio_nCodSt
                 AND NVL(IVATRANSF,0)              <= 0
                 AND NVL(ALIQICMS1TRANSF,0)        <= 0
                 AND NVL(ALIQICMS2TRANSF,0)        <= 0
            	   AND NVL(PAUTATRANSF,0)            <= 0
                 AND NVL(PERCBASEREDSTTRANSF,0)    <= 0
                 AND NVL(IVAFONTETV10,0)           <= 0
                 AND NVL(ALIQICMS1FONTETV10,0)     <= 0
            	   AND NVL(ALIQICMS2FONTETV10,0)     <= 0
                 AND NVL(PERCBASEREDSTFONTETV10,0) <= 0
                 AND NVL(PAUTAFONTETV10,0)         <= 0;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vvIgnorarSTFonteTV10Zerado := 'N';
            END; 
            
            -- Se os valores para os campos estão zerados, não calcula ST Fonte
            IF (vvIgnorarSTFonteTV10Zerado = 'S') THEN
              vbCalculaSTFonte := FALSE;
            END IF; 
                     
          END IF; -- Fim-Se possui regra para ignorar ST com valores zerados
        END IF; -- Fim-Se Pedido TV10     
        
       /*********************************************************************************************
        *********************************************************************************************
        **                     CALCULAR VALOR DO ST PELA ULTIMA ENTRADA                            **
        *********************************************************************************************
        *********************************************************************************************/
        IF   (vbUsaRegraStUltimaEntrada) AND
             (vbCalculaSTFonte)          THEN -->> HIS.03788.2015 - Somente se for STFONTE
  
          -------------------------------------------
          -- Se usa o PEPS e é Chamado do Faturamento
          -------------------------------------------
          IF (pi_vTipoChamada = 'F') AND
             (v_medcalcularstpelopeps = 'S') THEN
          
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',PEPS';
          
             -- Total de itens (Saldo). 
             v_nqt_saldo := NVL(pi_nQT,0);
             -- Apagando a movimentação da temporária
             DELETE FROM PCPEPSSALDOTEMP;
             
             -- Cursor para identificar as transações.
             FOR CR_PEPS IN (SELECT M.NUMTRANSPEPS
                                  , E.DTENT
                                  , SUM(SALDO) SALDO
                                FROM   (   -- Saldo PEPS até último fechamento
                                        SELECT   S.NUMTRANSENT NUMTRANSPEPS, SUM (S.QTSALDO) SALDO
                                          FROM   PCPEPSSALDO S
                                         WHERE   S.CODFILIAL = p_codfilialfaturamento -- HIS.03371.2017
                                           AND   S.CODPROD = pi_nCodProd
                                        GROUP BY S.NUMTRANSENT
                                    UNION  -- Entradas após último fechamento
                                        SELECT   N.NUMTRANSENT NUMTRANSPEPS, SUM (M.QTCONT) SALDO
                                          FROM   PCNFENT N, PCMOV M
                                         WHERE   NVL (N.CODFILIALNF, N.CODFILIAL) = p_codfilialfaturamento -- HIS.03371.2017
                                               AND N.DTENT >= V_dtultprocessamentopeps+1
                                               AND N.ESPECIE = 'NF'
                                               AND M.NUMTRANSENT = N.NUMTRANSENT
                                               AND M.CODPROD = pi_nCodProd
                                               AND M.QTCONT > 0
                                               AND M.STATUS IN ('A', 'AB')
                                               AND N.TIPODESCARGA <> 'F'
                                               AND NVL (N.NFENTREGAFUTURA, 'N') = 'N'
                                               AND M.CODOPER IN ('E', 'EB', 'ET', 'ED', 'ER', 'EI')
                                               AND M.DTCANCEL IS NULL
                                               AND NOT EXISTS
                                                     (SELECT   CODPROD
                                                        FROM   PCMOVENT
                                                       WHERE       NUMTRANSENT = N.NUMTRANSENT
                                                               AND CODFILIAL = p_codfilialfaturamento -- HIS.03371.2017
                                                               AND CODPROD = M.CODPROD)
                                          GROUP BY N.NUMTRANSENT
                                    UNION  -- Saídas após último fechamento
                                        SELECT   C.NUMTRANSPEPS, SUM (M.QTCONT) * (-1) SALDO
                                          FROM   PCNFSAID N, PCMOV M, PCMOVCOMPLE C
                                         WHERE   NVL (M.CODFILIALNF, M.CODFILIAL) = p_codfilialfaturamento -- HIS.03371.2017
                                               AND M.DTMOV >= V_dtultprocessamentopeps+1
                                               AND M.NUMTRANSVENDA = N.NUMTRANSVENDA
                                               AND M.CODPROD = pi_nCodProd
                                               AND N.ESPECIE = 'NF'
                                               AND M.QTCONT > 0
                                               AND M.STATUS IN ('A', 'AB')
                                               AND M.CODOPER IN ('S', 'SB', 'ST', 'SD', 'SP', 'SR', 'SI')
                                               AND NVL (M.CODFISCAL, 0) NOT IN (5929, 6929)
                                               AND NVL (N.CONDVENDA, 0) NOT IN (3, 6, 7, 12, 13)
                                               AND NVL (N.FINALIDADENFE, 'O') <> 'C'
                                               AND M.DTCANCEL IS NULL
                                               AND N.DTCANCEL IS NULL
                                               AND C.NUMTRANSITEM = M.NUMTRANSITEM
                                          GROUP BY C.NUMTRANSPEPS
                                    UNION  -- Saldo já reservado no Pedido (outros lotes)
                                        SELECT   I.NUMTRANSPEPS, SUM (I.QT) * (-1) SALDO
                                          FROM   PCPEDC P, PCPEDI I
                                         WHERE   NVL (P.CODFILIALNF, P.CODFILIAL) = p_codfilialfaturamento -- HIS.03371.2017
                                               AND P.NUMPED = pi_nNumPedido
                                               AND I.CODPROD = pi_nCodProd
                                               AND NVL (P.CONDVENDA, 0) NOT IN (3, 6, 7, 12, 13)
                                               AND NVL (I.NUMTRANSPEPS,0) > 0
                                               AND P.NUMPED = I.NUMPED
                                         GROUP BY I.NUMTRANSPEPS
                                          ) M, PCNFENT E
                         WHERE M.NUMTRANSPEPS = E.NUMTRANSENT(+)
                         GROUP BY M.NUMTRANSPEPS, E.DTENT
                        HAVING SUM(SALDO) > 0 -->> SOMENTE COM SALDO
                         ORDER BY E.DTENT, M.NUMTRANSPEPS)
             LOOP
             
              -- CALCULANDO A QUANTIDADE DE BAIXA POR TRANSAÇÃO.
               v_nqt_baixa := 0; 
               IF (NVL(CR_PEPS.SALDO,0) >= NVL(v_nqt_saldo,0)) then
                 -- Se tem Saldo no PEPS para atender totalmente a quantidade
                 v_nqt_baixa := NVL(v_nqt_saldo,0);
                 v_nqt_saldo := 0;
               else
                 -- Se NÃO tem Saldo no PEPS para atender toda a quantidade
                 v_nqt_baixa := NVL(CR_PEPS.SALDO,0);
                 v_nqt_saldo := NVL(v_nqt_saldo,0) - NVL(v_nqt_baixa,0);  
               end if;
               
               -- BUSCANDO INFORMAÇÃO DE BASE ST E ST DA TRANSAÇÃO DE ENTRADA.
               BEGIN
                   SELECT BASEBCR
                        , STBCR
                     INTO v_baseicstpeps
                        , v_stpeps                   
                     FROM PCMOV
                    WHERE NUMTRANSENT = CR_PEPS.NUMTRANSPEPS
                      AND CODPROD = pi_nCodProd
                      AND ROWNUM = 1; 
                         
                   -- Por enquanto respeitam a tributação as variáveis abaixo
                   V_iva                := p_iva;
                   V_ivafonte           := p_ivafonte;
                   V_aliqicms1fonte     := p_aliqicms1fonte;
                   V_aliqicms2fonte     := p_aliqicms2fonte;
                   V_percbaseredstfonte := p_percbaseredstfonte;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    po_vMensagem := 'Não foi encontrado movimento para a transação ' + CR_PEPS.NUMTRANSPEPS + ' no processo do PEPS';
                    RAISE e_tratado;
                END;                  
               
               -- INSERINDO NA TEMPORÁRIA
               INSERT INTO PCPEPSSALDOTEMP (NUMTRANSPEPS
                                           ,CODPROD
                                           ,QTSALDO
                                           ,BASEICST
                                           ,ST
                                           ,IVA
                                           ,IVAFONTE
                                           ,ALIQICMS1FONTE 
                                           ,ALIQICMS2FONTE
                                           ,PERCBASEREDSTFONTE)
                                     VALUES
                                           (CR_PEPS.NUMTRANSPEPS
                                           ,pi_nCodProd
                                           ,v_nqt_baixa
                                           ,v_baseicstpeps
                                           ,v_stpeps
                                           ,V_iva
                                           ,V_ivafonte
                                           ,V_aliqicms1fonte 
                                           ,V_aliqicms2fonte
                                           ,V_percbaseredstfonte);
  
               -- Reservou toda a Quantidade do Item do Pedido no PEPS
               IF (NVL(v_nqt_saldo,0) <= 0) THEN
                  EXIT;
               END IF;
               
             END LOOP;                              
             
             -- Se ainda ficar saldo grava com os dados da PCEST
             IF (NVL(v_nqt_saldo,0) > 0) THEN
               -- INSERINDO NA TEMPORÁRIA
               INSERT INTO PCPEPSSALDOTEMP (NUMTRANSPEPS
                                           ,CODPROD
                                           ,QTSALDO
                                           ,BASEICST
                                           ,ST
                                           ,IVA
                                           ,IVAFONTE
                                           ,ALIQICMS1FONTE 
                                           ,ALIQICMS2FONTE
                                           ,PERCBASEREDSTFONTE)
                                     VALUES
                                           (NULL        -->> Não terá NUMTRANSPEPS
                                           ,pi_nCodProd
                                           ,v_nqt_saldo -->> Saldo Restante do Item do Pedido
                                           ,NVL(p_basebcrultent,0)
                                           ,NVL(p_stbcrultent,0)
                                           ,p_iva
                                           ,p_ivafonte
                                           ,p_aliqicms1fonte 
                                           ,p_aliqicms2fonte
                                           ,p_percbaseredstfonte);
               v_nqt_saldo := 0;                                          
             END IF;
             
          ----------------------------------------------------------------------
          -- Se não usa o PEPS ou se usa o PEPS mas não é chamado do Faturamento
          ----------------------------------------------------------------------
          ELSE 
            -- Usa Valores da PCEST
            vnbcst    := NVL(p_basebcrultent,0);
            vnstfonte := NVL(p_stbcrultent,0);
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',PEPS PcEst';
          END IF;
           
       /*********************************************************************************************
        *********************************************************************************************
        **            CALCULAR VALOR DO ST PELA CARGA TRIBUTÁRIA MÉDIA - HIS.03187.2015            **
        *********************************************************************************************
        *********************************************************************************************/
        ELSIF (vbUsaRegraRegSimplCargaTrib) AND
              (vbCalculaSTFonte)            THEN -->> HIS.03371.2017 - Somente se for STFONTE
            
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Carga Trib.Média';
            
        /*   
         Base ST = [Valor Operação Própria] + [Valor Estimativa Simplificada Carga Tributária Média]
                   ---------------------------------------------------------------------------------
                     		                        Percentual ICMS Interno
  
         Base ST = [Valor Produtos x (Aliq2/100)] + [(Valor Produtos + IPI + Outras Depesas) x (CargaTribut/100)]
                   ----------------------------------------------------------------------------------------------
        		                                         (Aliq1/100)
                                                     
         Valor ST = [Valor Estimativa Simplificada Carga Tributária Média]
         
         OBS: Excluem-se deste: Cliente Regime Isenção; Item Bonificado Retira ST Estadual; Orgão Público e a Tributação tem Isenção de ST para Órgãos Públicos
         */
  
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DO VALOR DA OPERAÇÃO PRÓPRIA
          -------------------------------------*/
  
          -- Base Cálculo
          vnBcIcmsOperPropriaCargaTribut := NVL(vnPVENDA,0); 
          -- Valor
          vnVlIcmsOperPropriaCargaTribut := NVL(vnBcIcmsOperPropriaCargaTribut,0) * (NVL(p_ALIQICMS2FONTE,0) / 100);
          
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DO ST VALOR DA OPERAÇÃO PRÓPRIA
          -------------------------------------*/
  
          -- Base Cálculo
          vnBcEstimatSimplifCargaTribut := NVL(vnPVENDA,0);
          vnBcEstimatSimplifCargaTribut := NVL(vnBcEstimatSimplifCargaTribut,0) + NVL(p_vlipi,0);
          vnBcEstimatSimplifCargaTribut := NVL(vnBcEstimatSimplifCargaTribut,0) + NVL(p_vlfreteoutrasdesp,0);
          -- Valor
          vnVlEstimatSimplifCargaTribut := NVL(vnBcEstimatSimplifCargaTribut,0) * (NVL(p_PERCREGSIMPLCARGATRIBSTFONTE,0) / 100);
  
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DA BASE DO ST
          ----------------------*/
          
          vnBCST := (NVL(vnVlIcmsOperPropriaCargaTribut,0) + NVL(vnVlEstimatSimplifCargaTribut,0)) / (NVL(p_ALIQICMS1FONTE,0) / 100);
  
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DO VALOR DO ST
          -----------------------*/
          
          vnSTFONTE := NVL(vnVlEstimatSimplifCargaTribut,0);
          
          --Calcular ST - Truncar com 2 casas decimais
          IF p_tipocalcst = 'T2' THEN
            vnstfonte := trunc((vnstfonte) * 100) / 100;
          ELSIF p_tipocalcst = 'A2' THEN
            vnstfonte := round((vnstfonte) * 100) / 100;
          ELSIF p_tipocalcst = 'PV' THEN
            vnSTFONTE := round(vnSTFONTE, p_numcasasdecvenda);       
          END IF;
          
       /*********************************************************************************************
        *********************************************************************************************
        **                          CALCULAR VALOR DO ST FONTE [RBD04]                             **
        *********************************************************************************************
        *********************************************************************************************/
        ELSIF (vbCalculaSTFonte) THEN
          
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Padrão';
                
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DA REDUÇÃO DA BASE DE CÁLCULO
          --------------------------------------*/
        
          vnpercbasered := p_percbaseredstfonte;
        
          -- MED-1080 - Redução da Base Crédito do ST Fonte
          vnpercbaseredBaseCred := p_percbaseredstfonte;
          IF (NVL(p_USAREDICMNORMVENDASTFONTE,'N') = 'S') THEN
            vnpercbaseredBaseCred := p_PERCBASERED; -- MED-1080
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',RedICMSNorm'||p_PERCBASERED;
          END IF;
        
          --  MED-2346 - Redução para o ICMS Crédito
          vnpercbaseredIcmsFecp := p_PERCBASERED; 
        
          ---- Se tipo de empresa do cliente for Normal RPA
          ---- Aplicar %reducao na base de ICMS especifico
          IF (p_tipoempresa = 'NRPA') THEN
            vnpercbasered         := p_percbaserednrpa;
            vnpercbaseredBaseCred := p_percbaserednrpa; -- MED-1080
            vnpercbaseredIcmsFecp := p_percbaserednrpa; -- MED-2346
            
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',NRPA';
          END IF;
          ---- Cliente consumidor final utiliza %base red. p/ consumidor final
          IF (p_consumidorfinal = 'S') AND (p_percbaseredconsumidor <> 0) THEN
            vnpercbasered         := p_percbaseredconsumidor;
            vnpercbaseredBaseCred := p_percbaseredconsumidor; -- MED-1080
            vnpercbaseredIcmsFecp := p_percbaseredconsumidor; -- MED-2346
            
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Red.CF';
          END IF;
          ---- Cliente PF que utiliza IE simplificada nao aplica %base red
          IF (p_utilizaiesimplificada = 'S') AND (p_tipofj = 'F') AND
             (p_contribuinte = 'N') THEN
            vnpercbasered         := 0;
            vnpercbaseredBaseCred := 0; -- MED-1080
            vnpercbaseredIcmsFecp := 0; -- MED-2346
            
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',PF.Simplif.';
          END IF;
        
          if vbpessoafisica = true then
            if (p_UTILIZAPERCBASEREDPF = 'N') or
               (p_UTILIZAPERCBASEREDPF_TRIB = 'N') then
              vnPERCBASERED         := 0;
              vnpercbaseredBaseCred := 0; -- MED-1080
              vnpercbaseredIcmsFecp := 0; -- MED-2346
              
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Red.PF.';
            end if;
          end if;
        
          IF (p_isentoicms = 'S') OR (p_condvenda = 7) THEN
            vnpercbasered         := 0;
            vnpercbaseredBaseCred := 0; -- MED-1080
            vnpercbaseredIcmsFecp := 0; -- MED-2346
            
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Red.Isento';
          END IF;
          
          --// MERGE CR -> GU = Farmácia Popular não tem Redução da Base de Cálculo
          if (vbRegraFciaPopular) then
            vnpercbasered         := 0;
            vnpercbaseredBaseCred := 0; -- MED-1080
            vnpercbaseredIcmsFecp := 0; -- MED-2346
            
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Red.FciaPop.';
          end if;
  
          --// MED-2428
          IF (vbUsaPmcBaseSt) THEN
            IF (p_usaReducaoBasePmc = 'S') AND (p_pertetoredbasepmc > 0) THEN
              IF (NVL(p_pvenda,0) > 0) THEN
                IF ((p_pvenda / P_PRECOMAXCONSUM * 100) >= p_pertetoredbasepmc)  THEN
                  vnpercbasered         := 0;
                  vnpercbaseredBaseCred := 0; -- MED-1080
                  vnpercbaseredIcmsFecp := 0; -- MED-2346
                  -- Observação ST Fonte
                  p_observacaostfonte := p_observacaostfonte || ',Sem Red.Teto PMC.';
                END IF;
              END IF;
            END IF;
          END IF;
  
  
          p_percbaseredstfonte := vnpercbasered;
        
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DO PERCENTUAL DE IVA FONTE
          -----------------------------------*/
        
          -- Definir IVA do ST Fonte [RBD07]
          if p_UsaIVAFonteDiferenciado = 'N' then
            vnIvaFonte := p_IVAFONTE;
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',N:Iva Dif.';
          
            --Comentado na 316 por:  //Fernandes 13/09/2011
            --if vnIVAFONTE = 0  and 
            --   not ((nvl(p_PRECOMAXCONSUM,0) > 0) and (NVL(p_USAPMCBASEST,'N') = 'S')) then
            --  p_ALIQICMS1FONTE := 0;
            --  p_ALIQICMS2FONTE := 0;
            --end if;
            --Fim Comentado na 316 por:  //Fernandes 13/09/2011
          elsif p_usaivafontediferenciado = 'S' then
            vnIvaFonte := p_IVAFonte_Cli;
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',S:Iva Dif.';
            
          elsif p_usaivafontediferenciado = 'M' then
          
            if p_IVAFONTE > p_IVAFonte_Cli then
              vnIVAFONTE := p_IVAFONTE;
            else
              vnIvaFonte := p_IVAFonte_Cli;
            end if;
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',M:Iva Dif.';
            
          end if;
        
          -- [HIS.05161.2014] - Redução Simples Nacional no IVA
          IF (p_somenteIVATribut = 'N') THEN
            IF ((NVL(p_usadescsimplesnac,'N')     = 'N')     AND  -- Somente se na Rotina 132 Não usa desconto do Simples Nacional
                (NVL(p_percredpvendasimplesnac,0) > 0)       AND  -- Somente se tiver % Redução cadastrado na Tributação
                (NVL(p_simplesnacional,'N')       = 'S')     AND  -- Somente se o Cliente participa do Simples Nacional 
                (NVL(p_tipomerc,' ') NOT IN (' ','M','MA'))) THEN -- Somente se não for Medicamento e tiver o Tipo Merc. Preenchido
              vnIvaFonte := vnIvaFonte * (p_percredpvendasimplesnac / 100);
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Red.Iva SN';
            END IF;          
          END IF;
        
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DA BASE DE CÁLCULO DA ALIQ 01
          --------------------------------------*/
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Tipo de Base de Cálculo do ST (Débito)', 'COLUNA_BCST');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Base ST pela Pauta Fonte (Farmácia Popular)', 'COLUNA_BCST', 'PAUTAFONTE');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Base ST pelo Preço Máximo Consumidor', 'COLUNA_BCST', 'PMC');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('3) Base ST pelo Preço Tabela', 'COLUNA_BCST', 'PTABELA'); 
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('4) Base ST pela Média dos Valores das Entradas (MG)', 'COLUNA_BCST', 'VLMEDIAENTMG');                                                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('5) Base ST pelo Custo da Nota de Entrada sem ST', 'COLUNA_BCST', 'CUSTONF');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('6) Base ST pelo Valor da Ultima Entrada', 'COLUNA_BCST', 'VALORULTENT');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('7) Base ST pelo Valor da Ultima Entrada (ST RJ)', 'COLUNA_BCST', 'VLULTENTSTRJ');
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('8) Base ST pelo Valor dos Produtos', 'COLUNA_BCST', 'PVENDA');   
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('9) Base ST pelo PMPF', 'COLUNA_BCST', 'PMPF');          
            
          -- FARMACIA POPULAR
          if    (vbRegraFciaPopular) then 
             
             vnPBASE := NVL(p_PAUTAFONTE,0);         
  
             vnVlFreteOutrasDespBaseSt   := NVL(p_vlfreteoutrasdesp,0);
             vnVlFreteOutrasDespBaseIcms := NVL(p_vlfreteoutrasdesp,0);
  
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',FciaPop';
             
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCST', 'PAUTAFONTE');                     
    
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor Inicial da Base ST (Débito)', vnPBASE);
    
          -- PMC NA BASE DO ST
          elsif (vbUsaPmcBaseSt) then
    
             vnPBASE := P_PRECOMAXCONSUM; 
  
             vnVlFreteOutrasDespBaseSt := 0; --> Nesta Regra não aplicará Frete e Outras Despesas
             
             -- HIS.03428.2017 - CONFORME NOVA LEGISLAÇÃO, SEMPRE SOMARÁ NO ICMS PRÓPRIO           
             vnVlFreteOutrasDespBaseIcms := NVL(p_vlfreteoutrasdesp,0);
  
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',PMC';
             
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCST', 'PMC');                     
             
             -- Memória de Cálculo
             P_INSERIR_MEMORIA_CALCULO('=', 'Valor Inicial da Base ST (Débito)', vnPBASE);
             

          -- PMPF NA BASE DO ST
          elsif (vbUsaPmPfBaseSt) then
    
             vnPBASE  := P_PMPF; 
             
             po_nPmPf := P_PMPF; -- DDMEDICA-7697
  
             vnVlFreteOutrasDespBaseSt := 0; --> Nesta Regra não aplicará Frete e Outras Despesas
             
             vnVlFreteOutrasDespBaseIcms := NVL(p_vlfreteoutrasdesp,0);
  
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',PMPF';
             
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCST', 'PMPF');                     
             
             -- Memória de Cálculo
             P_INSERIR_MEMORIA_CALCULO('=', 'Valor Inicial da Base ST (Débito)', vnPBASE);
             
          -- USAR PTABELA BASE DO ST
          elsif (NVL(p_usaptabelabasest,'N') = 'S') then
          
             vnPBASE := p_ptabela;
  
             vnVlFreteOutrasDespBaseSt   := NVL(p_vlfreteoutrasdesp,0);
             vnVlFreteOutrasDespBaseIcms := NVL(p_vlfreteoutrasdesp,0);
             
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',P.Tab';
             
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCST', 'PTABELA');                     
             
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor Inicial da Base ST (Débito)', vnPBASE);
                                       
          -- USAR VALOR MÉDIO DAS ULTIMAS ENTRADAS (MG)
          elsif (NVL(p_usavlultentmediobasest,'N') = 'S') then
  
             vnPBASE := p_vlultentmes;
  
             vnVlFreteOutrasDespBaseSt   := NVL(p_vlfreteoutrasdesp,0);
             vnVlFreteOutrasDespBaseIcms := NVL(p_vlfreteoutrasdesp,0);
             
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Media Ent.MG';
             
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCST', 'VLMEDIAENTMG');                     
             
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor Inicial da Base ST (Débito)', vnPBASE);
             
          -- DEMAIS CASOS (PVENDA, CUSTO, ETC)              
          else
        
            -- DDMEDICA-7594 - Passou para o inicio por ser prioritário sobre todos os ValorUltEnt
            if (p_UfFilial = p_EstEnt) and (NVL(p_UsaValorUltEntBaseST2,'N') = 'S') then
            
              vnPVENDA := vnCustoNFSemST; 
              
              vnVlFreteOutrasDespBaseSt   := 0; --> Nesta Regra não aplicará Frete e Outras Despesas
              vnVlFreteOutrasDespBaseIcms := 0;
               
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Ult.Ent.ST2';
              
            -- VALOR DA ULTIMA ENTRADA NA BASE DO ST      
            ELSIF (p_uffilial = p_estent) AND
                  (nvl(p_usavalorultentbasest, 'N') = 'S') AND
                  (NVL(p_percbasestrj,0) = 0) THEN
               
              vnpbase  := vncustonfsemst; 
    
              vnVlFreteOutrasDespBaseSt   := 0; --> Nesta Regra não aplicará Frete e Outras Despesas
              vnVlFreteOutrasDespBaseIcms := 0;
              
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Ult.Ent.';
              
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             if nvl(P_CUSTONFSEMST,0) = 0 then
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCST', 'VALORULTENT');                     
                                                                                                                                             ELSE            
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCST', 'CUSTONF');                     
                                                                                                                                             END IF;
  
            -- VALOR DA ULTIMA ENTRADA NA BASE DO ST - RJ (RIO DE JANEIRO)
            ELSIF (p_uffilial = p_estent) AND
                  (nvl(p_usavalorultentbasest, 'N') = 'S') AND
                  (NVL(p_percbasestrj,0) > 0) THEN
  
              vnpbase  := NVL(p_valorultent,0); 
    
              vnVlFreteOutrasDespBaseSt   := 0; --> VERIFICAR DEPOIS Nesta Regra não aplicará Frete e Outras Despesas
              vnVlFreteOutrasDespBaseIcms := 0;
              
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Ult.Ent.RJ';
              
                                                                                                                         -- Memória de Cálculo
                                                                                                                         P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCST', 'VLULTENTSTRJ');                     
                          
            ELSE          
            
              vnpbase := p_pvenda;
    
              vnVlFreteOutrasDespBaseSt   := NVL(p_vlfreteoutrasdesp,0);
              vnVlFreteOutrasDespBaseIcms := NVL(p_vlfreteoutrasdesp,0);
              
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',P.Venda';            
              
                                                                                                                         -- Memória de Cálculo
                                                                                                                         P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCST', 'PVENDA');                     
                                                               

              ---------------------------------------------------------------------------------------------------
              -- DDMEDICA-7594 - Valores para Customização da Base ST com SUFRAMA/Redução PISCOFINS e DESONERACAO
              -- Base ST da Alíquota 1
              ---------------------------------------------------------------------------------------------------
              -- Usou IVA na Base 1
              vbUsouIVAFonte_B1 := TRUE;

              -- Define os Valores conforme parametrização
              IF (p_agregapiscofinsst1 = 'S') THEN
                vnVlDescReducaoPisCofins_B1 := (NVL(p_vldescreducaopis,0) + NVL(p_vldescreducaocofins,0));
              END IF; 
              IF (p_agregasuframast1 = 'S') THEN 
                vnVlDescSuframaPisSuframa_B1 := NVL(p_vldescsuframa,0);
              END IF;
              IF (p_agregaicmsisencaost1 = 'S') THEN
                vnVlDescIcmIsencao_B1        := NVL(p_vldescicmisencao,0);
              END IF;
              
              -- APLICA REDUÇÃO PIS/COFINS
              IF (NVL(vnVlDescReducaoPisCofins_B1,0) > 0) THEN
                vnPBASE := NVL(vnPBASE,0) - NVL(vnVlDescReducaoPisCofins_B1,0);        
              
                                                                                                                                                 -- Memória de Cálculo          
                                                                                                                                                 P_INSERIR_MEMORIA_CALCULO('-', 'Redução PIS/COFINS', vnPBASE, NULL, vnVlDescReducaoPisCofins_B1);
                                                                                                                                                 
              END IF; 
              
              -- APLICA REDUÇÃO SUFRAMA
              IF (NVL(vnVlDescSuframaPisSuframa_B1,0) > 0) THEN
                vnPBASE := NVL(vnPBASE,0) - NVL(vnVlDescSuframaPisSuframa_B1,0);        
              
                                                                                                                                                 -- Memória de Cálculo          
                                                                                                                                                 P_INSERIR_MEMORIA_CALCULO('-', 'Redução SUFRAMA', vnPBASE, NULL, vnVlDescSuframaPisSuframa_B1);
                                                                                                                                                 
              END IF; 
    
              -- APLICA REDUÇÃO DESONERAÇÃO
              IF (NVL(vnVlDescIcmIsencao_B1,0) > 0) THEN
                vnPBASE := NVL(vnPBASE,0) - NVL(vnVlDescIcmIsencao_B1,0);        
              
                                                                                                                                                 -- Memória de Cálculo          
                                                                                                                                                 P_INSERIR_MEMORIA_CALCULO('-', 'Redução Desoneração ICMS', vnPBASE, NULL, vnVlDescIcmIsencao_B1);
                                                                                                                                                 
              END IF; 
              ---------------------------------------------------------------------------------------------------

            END IF;


                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor Inicial da Base ST (Débito)', vnPBASE);
        
            -- Soma o Valor do IPI na Base do ST
            vnpbase := vnpbase + nvl(p_vlipi, 0);
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('+', 'IPI', vnPBASE, p_percipivenda, p_vlipi);
            
         
          end if;
          
          -- APLICA VALOR DO FRETE E OUTRAS DESPESAS na Base de Cáculo Aliq. 01
          vnPBASE := NVL(vnPBASE,0) + NVL(vnVlFreteOutrasDespBaseSt,0);        
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('+', 'Frete e Outras Despesas', vnPBASE, NULL, vnVlFreteOutrasDespBaseSt);
          
          
          -- Guarda a Base ST Original sem Redução para cálculos mais abaixo - 5661.146071.2016
          vnBaseStOriginalSemReducao := vnPBASE;         
             
          --------------------------------------------
          -- APLICA REDUÇÃO na Base de Cáculo Aliq. 01
          --------------------------------------------
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Aplicar Redução na Base de ST (Débito) ?', 'RED_BCST');                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Sim, aplicar redução', 'RED_BCST', 'SIM');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Não aplicar redução', 'RED_BCST', 'NAO');          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('RED_BCST', 'NAO'); -->> Default               
          
          -- Se tem Redução na Base do ST
          IF vnpercbasered > 0 THEN
          
                                                                                                                                             -- Variáveis Auxiliares da Memória de Calculo
                                                                                                                                             vnPercMemoriaCalculo           := (100 - vnpercbasered);
                                                                                                                                             vnValorCalculadoMemoriaCalculo := (vnpbase * (vnPercMemoriaCalculo / 100));
          
            -- Aplica Redução na Base
            vnpbase := vnpbase * (vnpercbasered / 100);
            
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('RED_BCST', 'SIM');                     
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('-', 'Redução de ' || vnpercbasered || '% na Base ST (Crédito)', vnPBASE, vnPercMemoriaCalculo, vnValorCalculadoMemoriaCalculo);
            
          END IF; -- Fim Condição: APLICA REDUÇÃO na Base de Cáculo Aliq. 01
          
          ---------------------------------------------        
          -- APLICA O REDUTOR Cat/49 - 5661.146071.2016
          ---------------------------------------------        
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Aplicar Redução Cat-49/2016 na Base de ST (Débito) ?', 'CAT49_BCST');                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Sim, aplicar Cat-49/2016', 'CAT49_BCST', 'SIM');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Não aplicar Cat-49/2016','CAT49_BCST', 'NAO');          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('CAT49_BCST', 'NAO'); -->> Default               
                  
          -- Se usa Redutor Cat/49
          IF (p_USAREDUTORCAT49BASESTFONTE = 'S') THEN
            IF (NVL(p_PERCREDUTORCAT49BASESTFONTE,0) > 0) THEN
  
                                                                                                                                             -- Variáveis Auxiliares da Memória de Calculo
                                                                                                                                             vnPercMemoriaCalculo           := (100 - p_PERCREDUTORCAT49BASESTFONTE);
                                                                                                                                             vnValorCalculadoMemoriaCalculo := (vnpbase * (vnPercMemoriaCalculo / 100));
            
              -- Aplica Redução CAT/49 na Base
              vnpbase := vnpbase * (NVL(p_PERCREDUTORCAT49BASESTFONTE,0) / 100);
              
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Red.Cat49';
              
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('CAT49_BCST', 'SIM');                     
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('-', 'Redução Cat/49 de ' || vnpercbasered || '% da Base ST', vnPBASE, vnPercMemoriaCalculo, vnValorCalculadoMemoriaCalculo);                                                  
              
            END IF;
          END IF;
                            
          ---------------------------------------------------------------------------------------------      
          -- Regra Ajuste de Preço CMED para o PMC
          -- (Tributação Marcada para Ajuste de Preço CMED, se tiver PMC e se Não for Farmácia Popular)
          ---------------------------------------------------------------------------------------------      
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Aplicar Legislação Cat-35/2014 na Base de ST (Débito) ? (Obs: Somente Produtos com PMC e sem Pauta)', 'CAT35_BCST');                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Aplicar Cat-35/2014 ajustando a Base de ST pelo MVA (Fator Ajuste CMED >= Percentual de Referência)', 'CAT35_BCST', 'SIM_MVA_REF');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Aplicar Cat-35/2014 ajustando a Base de ST pelo PMC (Fator Ajuste CMED >= Percentual de Referência)', 'CAT35_BCST', 'SIM_PMC_REF');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('3) Aplicar Cat-35/2014 ajustando a Base de ST pelo PMC (Fator Ajuste CMED < Percentual de Referência)', 'CAT35_BCST', 'SIM_PMC');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('4) Não Aplicar Legislação Cat-35/2014', 'CAT35_BCST', 'NAO');          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('CAT35_BCST', 'NAO'); -->> Default               
          
          -- Se Utilizar Legislação Cat/35 (Ajuste Preço CMED
          IF (NVL(p_usarajusteprecocmed,'N') = 'S') AND
             (NVL(p_PRECOMAXCONSUM,0) > 0) AND
             (NOT vbRegraFciaPopular) THEN
                       
            -- PMC de Referência para Ajuste Preço CMED
            IF (NVL(vnpercbasered,0) > 0) THEN
            
              vnPmcAjustePrecoCMED := NVL(p_PRECOMAXCONSUM,0) * (vnpercbasered / 100);
              
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Red.AjusteCMED';
                          
            ELSE
            
              vnPmcAjustePrecoCMED := NVL(p_PRECOMAXCONSUM,0);
                          
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',AjusteCMED';
                          
            END IF;
                                  
            -- Se o Preço de Venda passado no Parâmetro sobre o PMC com Redução exceder o Percentual informado na Tributação,
            -- calcula a Base de ST pelo MVA mesmo sendo um Produto Tributado pelo PMC
            IF (((NVL(p_pvenda,0) / NVL(vnPmcAjustePrecoCMED,0)) * 100) >= NVL(p_percajusteprecocmed,0)) THEN
                                                 
              --- Calcula a base pelo MVA , sem o Percentual de Redução          
              vnBCST := NVL(p_pvenda,0) + nvl(p_vlipi,0);
              vnBCST := (vnBCST * (p_PERCVENDA / 100)) *
                        (1 + (vnIVAFONTE / 100));          
            
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',IVA AjusteCMED';
                                    
              -- A Base do ST não pode Exceder o PMC
              IF (NVL(vnBCST,0) > NVL(p_PRECOMAXCONSUM,0)) THEN
              
                vnBCST := NVL(p_PRECOMAXCONSUM,0);
                
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Exc.AjusteCMED';
               
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('CAT35_BCST', 'SIM_PMC_REF');                     
               
              ELSE
              
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('CAT35_BCST', 'SIM_MVA_REF');                     
                           
              END IF;
                                    
            -- Sem Regra Ajuste Preço CMED
            ELSE
                      
              -- Calcula a Base do ST pelo PMC
              vnBCST := NVL(p_PRECOMAXCONSUM,0);
              -- Base de Cáculo Aliq. 01
              IF vnpercbasered > 0 THEN
                vnBCST := vnBCST * (vnpercbasered / 100);
              END IF;
              
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',S/AjusteCMED';
              
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('CAT35_BCST', 'SIM_PMC');                                 
              
            END IF;
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Percentual de Referência CAT/35', NULL, p_percajusteprecocmed, NULL);                                                  
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Fator Ajuste CMED ((Valor Produto ' || NVL(p_pvenda,0) || CHR(247) || ' PMC ' || NVL(vnPmcAjustePrecoCMED,0) || ') x 100)', NULL, NULL, ((NVL(p_pvenda,0) / NVL(vnPmcAjustePrecoCMED,0)) * 100)); 
                                      
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Substituição da Base ST conforme Legislação CAT-35/2014', vnBCST, NULL, NULL);                                                  
                                                                                                  
          -----------------------------------------------
          -- Demais Casos (FARMACIA POPULAR, PMC, MVA ...
          -----------------------------------------------
          ELSE
        
            -- FARMACIA POPULAR
            if (vbRegraFciaPopular) then
            
              -- Sem IVA
              vnBCST               := vnpbase;
              p_pautafonteaplicado := NVL(p_PAUTAFONTE,0); -- HIS.01838.2017
      
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte  := p_observacaostfonte || ',BaseFciaPop.';
      
            -- PMC NA BASE ST
            elsif (vbUsaPmcBaseSt) then
      
              -- Sem IVA
              vnBCST := vnpbase;
  
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte  := p_observacaostfonte || ',BasePMC';
              

            -- PMPF NA BASE ST
            elsif (vbUsaPmPfBaseSt) then
      
              -- Sem IVA
              vnBCST := vnpbase;
  
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte  := p_observacaostfonte || ',BasePMPF';              

            -- Demais casos: COM IVA
            else
      
              -- Variáveis Auxiliares da Memória de Calculo
              vnValorCalculadoMemoriaCalculo := (vnPBASE * (vnIVAFONTE / 100));
      
              -- Agrega o MVA na Base do ST
              vnBCST := (vnPBASE * (p_PERCVENDA / 100)) *
                        (1 + (vnIVAFONTE / 100));
                        
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte  := p_observacaostfonte || ',BaseIVA';
              
                                                                                                                                                         -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Aplicar MVA na Base de ST (Débito)', 'MVA_BCST');                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Sim, aplicar MVA', 'MVA_BCST', 'SIM');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Não aplicar MVA', 'MVA_BCST', 'NAO');   
                                                                                                                                             IF (vnIVAFONTE > 0) THEN       
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('MVA_BCST', 'SIM'); -->> Default               
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('+', 'MVA', vnBCST, vnIVAFONTE, vnValorCalculadoMemoriaCalculo);                                          
                                                                                                                                             END IF;
                                                                
            end if;
            
          END IF;
                            
          -- Valor Aliq. 01 --
          --------------------
          vnSTF1 := vnBCST * (p_ALIQICMS1FONTE / 100);
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor ICMS Compra (Débito)', NULL, p_ALIQICMS1FONTE, vnSTF1);
          
          -- Valores para gravação do ST recolhido anteriormente -
          --------------------------------------------------------
          po_vEnquadraIcmsSubstAnterior := 'S';
          po_nVlIcmsSubstitutoAnterior  := vnSTF1;
          
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DA BASE DE CALCULO DA ALIQ 02
          --------------------------------------*/
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Tipo de Base de Cálculo do ICMS (Crédito)', 'COLUNA_BCICM');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Base ICMS pelo Preço Tabela', 'COLUNA_BCICM', 'PTABELA');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Base ICMS pela Média dos Valores das Entradas (MG)', 'COLUNA_BCICM', 'VLULTENTMES');                          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('3) Base ICMS pelo Valor dos Produtos', 'COLUNA_BCICM', 'PVENDA');          
                  
          -------------------------------------------------------------------------------------
          -- Base de Cáculo Aliq. 02
          -- Se Usa o Preço Tabela na Base do ST, aplica o PTabela também na Base da Alíquota 2
          -------------------------------------------------------------------------------------
          
          -- Se Utiliza Preço Tabela na Base do ST        
          IF (NVL(p_usaptabelabasest,'N') = 'S') THEN
          
            vnPVENDA := p_ptabela;
  
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte  := p_observacaostfonte || ',BaseIcmPTab.';          
            
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCICM', 'PVENDA');                                           
          
          -- Se Utiliza a Média dos Valores das Entradas (MG)
          ELSIF (NVL(p_usavlultentmediobasest,'N') = 'S') THEN
  
            vnPVENDA := p_vlultentmes;
  
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte  := p_observacaostfonte || ',BaseIcm Media MG';          
            
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCICM', 'VLULTENTMES');                                           
          
          -- Se Utiliza o Preço de Venda 
          ELSE
  
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte  := p_observacaostfonte || ',BaseIcmPVenda.';          
          
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('COLUNA_BCICM', 'PVENDA');                                 
          
          END IF;      
            
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor Inicial da Base ICMS (Crédito)', vnPVENDA);


          ---------------------------------------------------------------------------------------------------
          -- DDMEDICA-7594 - Valores para Customização da Base ST com SUFRAMA/Redução PISCOFINS e DESONERACAO
          -- Base ST da Alíquota 2
          ---------------------------------------------------------------------------------------------------
          -- Somente se usou IVA na Base 1
          IF (vbUsouIVAFonte_B1) THEN
          
            -- Define os Valores conforme parametrização
            IF (p_agregapiscofinsst2 = 'S') THEN
              vnVlDescReducaoPisCofins_B2 := (NVL(p_vldescreducaopis,0) + NVL(p_vldescreducaocofins,0));
            END IF; 
            IF (p_agregasuframast2 = 'S') THEN 
              vnVlDescSuframaPisSuframa_B2 := NVL(p_vldescsuframa,0);
            END IF;
            IF (p_agregaicmsisencaost2 = 'S') THEN
              vnVlDescIcmIsencao_B2        := NVL(p_vldescicmisencao,0);
            END IF;
  
            -- APLICA REDUÇÃO PIS/COFINS
            IF (NVL(vnVlDescReducaoPisCofins_B2,0) > 0) THEN
              vnPVENDA := NVL(vnPVENDA,0) - NVL(vnVlDescReducaoPisCofins_B2,0);        
            
                                                                                                                                               -- Memória de Cálculo          
                                                                                                                                               P_INSERIR_MEMORIA_CALCULO('-', 'Redução PIS/COFINS', vnPVENDA, NULL, vnVlDescReducaoPisCofins_B2);
                                                                                                                                               
            END IF; 
            
            -- APLICA REDUÇÃO SUFRAMA
            IF (NVL(vnVlDescSuframaPisSuframa_B2,0) > 0) THEN
              vnPVENDA := NVL(vnPVENDA,0) - NVL(vnVlDescSuframaPisSuframa_B2,0);        
            
                                                                                                                                               -- Memória de Cálculo          
                                                                                                                                               P_INSERIR_MEMORIA_CALCULO('-', 'Redução SUFRAMA', vnPVENDA, NULL, vnVlDescSuframaPisSuframa_B2);
                                                                                                                                               
            END IF; 
  
            -- APLICA REDUÇÃO DESONERAÇÃO
            IF (NVL(vnVlDescIcmIsencao_B2,0) > 0) THEN
              vnPVENDA := NVL(vnPVENDA,0) - NVL(vnVlDescIcmIsencao_B2,0);        
            
                                                                                                                                               -- Memória de Cálculo          
                                                                                                                                               P_INSERIR_MEMORIA_CALCULO('-', 'Redução Desoneração ICMS', vnPVENDA, NULL, vnVlDescIcmIsencao_B2);
                                                                                                                                               
            END IF; 
          END IF;
          ---------------------------------------------------------------------------------------------------
            
          ---------------------------------------------------------------------
          -- APLICA VALOR DO FRETE E OUTRAS DESPESAS na Base de Cáculo Aliq. 02
          ---------------------------------------------------------------------
  
          -- APLICA VALOR DO FRETE E OUTRAS DESPESAS na Base de Cáculo Aliq. 02
          vnPVENDA := NVL(vnPVENDA,0) + NVL(vnVlFreteOutrasDespBaseIcms,0);        
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('+', 'Frete e Outras Despesas', vnPVENDA, NULL, vnVlFreteOutrasDespBaseIcms);
            
          ---------------------------------------------
          -- Se usa Base ICMS Reduzida no Cálculo do ST
          ---------------------------------------------
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Aplicar Redução na Base de ICMS (Crédito) ?', 'RED_BCICM');                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Sim, reduzir a base usando o Percentual Redução do ST Fonte', 'RED_BCICM', 'SIM_REDFONTE');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Sim, reduzir a base usando o Percentual Redução do ICMS da Venda', 'RED_BCICM', 'SIM_REDVENDA');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('3) Não reduzir a base', 'RED_BCICM', 'NAO');          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('RED_BCICM', 'NAO'); -->> Default               
          
          -- Se usa Base ICMS Reduzida
          IF (p_usabaseicmsreduzida = 'S') THEN
            
            -- MED-1080 - Redução da Base Crédito do ST Fonte
            IF (NVL(p_USAREDICMNORMVENDASTFONTE,'N') = 'S') THEN
              
              IF vnpercbaseredBaseCred > 0 THEN
               
                                                                                                                                             -- Variáveis Auxiliares da Memória de Calculo
                                                                                                                                             vnPercMemoriaCalculo           := (100 - vnpercbaseredBaseCred);
                                                                                                                                             vnValorCalculadoMemoriaCalculo := (vnpbase * (vnPercMemoriaCalculo / 100));
               
                -- Aplica Redução da Alíquota informada na Aba de ICMS na Venda
                vnPVENDA := vnPVENDA * (vnpercbaseredBaseCred / 100);
  
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte  := p_observacaostfonte || ',Red.PVenda'||vnpercbaseredBaseCred;          
  
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('RED_BCICM', 'SIM_REDVENDA');                                               
                                            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('-', 'Redução de ' || vnpercbaseredBaseCred || '% na Base de ICMS (Débito)', vnPVENDA, vnPercMemoriaCalculo, vnValorCalculadoMemoriaCalculo);
                                            
              END IF;
              
            ELSE
                        
              IF vnpercbasered > 0 THEN
              
                                                                                                                                             -- Variáveis Auxiliares da Memória de Calculo
                                                                                                                                             vnPercMemoriaCalculo           := (100 - vnpercbasered);
                                                                                                                                             vnValorCalculadoMemoriaCalculo := (vnpbase * (vnPercMemoriaCalculo / 100));
              
                -- Aplica Redução da Alíquota informada na Aba de ST Fonte
                vnPVENDA := vnPVENDA * (vnpercbasered / 100);
              
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte  := p_observacaostfonte || ',Red.PVenda';          
              
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('RED_BCICM', 'SIM_REDFONTE');                                 
                                            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('-', 'Redução de ' || vnpercbasered || '% na Base de ICMS (Débito)', vnPVENDA, vnPercMemoriaCalculo, vnValorCalculadoMemoriaCalculo);
                                            
              END IF;
              
            END IF;
          END IF;
  
          -- Se Item Bonificado e a Bonificação não calcular ICMS
          IF ((p_itembonific IN ('S','F')) and -- DDMEDICA-198 - Incluir F
              (p_bnfnaocalculaicms = 'S')) THEN
            p_ALIQICMS2FONTE := 0;
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte  := p_observacaostfonte || ',BNF';          
          END IF;
            
          -- Valor Aliq. 02 --
          --------------------
          vnSTF2 := (vnPVENDA * (p_PERCVENDA / 100)) *
                    (p_ALIQICMS2FONTE / 100);
                                 
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor ICMS Venda (Crédito)', NULL, p_ALIQICMS2FONTE, vnSTF2);
                                      
         /*--------------------------------------------------------------------------------------------
          CALCULO DO ST FONTE
          ------------------*/
                       
          -- ST FONTE
          vnSTFONTE := vnSTF1 - vnSTF2;
        
          --Calcular ST - Truncar com 2 casas decimais
          IF p_tipocalcst = 'T2' THEN
            vnstfonte := trunc((vnstfonte) * 100) / 100;
          ELSIF p_tipocalcst = 'A2' THEN
            vnstfonte := round((vnstfonte) * 100) / 100;
          ELSIF p_tipocalcst = 'PV' THEN
            vnSTFONTE := round(vnSTFONTE, p_numcasasdecvenda);       
          END IF;
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Valor ICMS ST (Valor ICMS Débito - Valor ICMS Crédito)', NULL, NULL, vnSTFONTE);
  
          --------------------------------------------------------
          -- CARGA MÍNIMA DEFERIMENTO ST FONTE - HIS.01277.2017 --
          --------------------------------------------------------
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Usar Carga Mínima de Deferimento do ST Fonte ?', 'DEFERIM_ST');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Sim, usar a carga mínima', 'DEFERIM_ST', 'SIM');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Não usar a carga mínima', 'DEFERIM_ST', 'NAO');          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('DEFERIM_ST', 'NAO'); -->> Default               
          
          -- Se usa Carga Mínima de ST Fonte
          IF (p_USACARGAMINIMADEFERIMSTFONTE = 'S') THEN
                         
            --Calculo o ST pela Carga Mínima
            vnStFonteCargaMinima := vnBCST * (NVL(p_PERCARGAMINIMADEFERIMSTFONTE,0) / 100) ;
                      
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Percentual de Carga Mínima de Deferimento ST Fonte', NULL, p_PERCARGAMINIMADEFERIMSTFONTE, NULL);                                                  
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor do ST Mínimo conforme Percentual de Defermimento', NULL, NULL, vnstfonte); 
            
            --Calcular ST pela Carga Mínima - Truncar com 2 casas decimais
            IF p_tipocalcst = 'T2' THEN
              vnStFonteCargaMinima := trunc((vnStFonteCargaMinima) * 100) / 100;
            ELSIF p_tipocalcst = 'A2' THEN
              vnStFonteCargaMinima := round((vnStFonteCargaMinima) * 100) / 100;
            ELSIF p_tipocalcst = 'PV' THEN
              vnStFonteCargaMinima := round(vnStFonteCargaMinima, p_numcasasdecvenda);       
            END IF;
                    
            -- Verifico se o ST do Item é inferior ao ST Calculado pela Carga Mínima
            IF (NVL(vnstfonte,0) < NVL(vnStFonteCargaMinima,0)) THEN
  
              -- Substitui ST
              vnstfonte := vnStFonteCargaMinima;
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Substituição do Valor do ST conforme Deferimento ST Fonte', NULL, NULL, vnstfonte);                                                  
              
            END IF;
            
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Carga Mín.';          
                                                        
          END IF; -- FIM: CARGA MÍNIMA DEFERIMENTO ST FONTE - HIS.01277.2017
        
          --Se ST for menor que 0, torná-lo 0
          IF vnstfonte < 0 THEN
            vnstfonte := 0;
          -- Não zerar a Base de Cálculo do ST se o resultado do ST for zero - HIS.03187.2015
          --ELSIF vnstfonte = 0 THEN
          --  vnbcst := 0;
          END IF;
          
          -- Se Usa o Preço Tabela na Base do ST, a Base de ST deverá ser o Preço de Tabela (ACRE)
          IF (NVL(p_usaptabelabasest,'N') = 'S') THEN
            vnbcst := p_ptabela;
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',PTab.BaseSt';                    
          END IF;      
        
          -- tarefa 53294
          IF nvl(p_aliqicms1fonte, 0) = 0 AND
             nvl(p_aliqicms2fonte, 0) = 0 THEN
            vnbcst := 0;
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Zerada';
          END IF;            
  
          -------------------------------------------------------------------------
          -- PERCENTUAL BASE RJ - Priorização do Maior entre o Mínimo e o Calculado
          -------------------------------------------------------------------------
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Opção de ST Mínimo RJ', 'VL_STRJ');                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Valor do ST calculado maior que o Valor do ST Mínimo RJ, manter ST calculado.', 'VL_STRJ', 'CALC_STRJ');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Valor do ST calculado menor que o Valor do ST Mínimo RJ, substituir pelo ST Mínimo.', 'VL_STRJ', 'MIN_STRJ');   
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('3) Não aplicar ST Mínimo RJ', 'VL_STRJ', 'NAO_STRJ');   
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('VL_STRJ', 'NAO_STRJ'); -->> Default               
          
          IF (NVL(p_usavalorultentbasest,'N') = 'S') AND
             (NVL(p_percbasestrj,0) > 0)             THEN
  
            -- Base ST Rj pelo Valor da Última Entrada
            vnBaseStRj := NVL(p_valorultent,0);
  
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor Inicial da Base ST RJ', vnBaseStRj);
                                      
            -- Soma o Valor do IPI na Base do ST Rj
            vnBaseStRj := vnBaseStRj + nvl(p_vlipi, 0);
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('+', 'IPI', vnBaseStRj, p_percipivenda, p_vlipi);
                                      
            -- Agrega o MVA na Base do ST Rj
            vnBaseStRj := (vnBaseStRj * (1 + (vnIVAFONTE / 100)));
                                      
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('+', 'MVA', vnBaseStRj, vnIVAFONTE, vnValorCalculadoMemoriaCalculo);                                      
          
            -- Redução ST Rj
            vnPercBaseRedRj := NVL(vnpercbasered,0); 
            IF (NVL(vnPercBaseRedRj,0) = 0) THEN
              vnPercBaseRedRj := 100;
            END IF;
            
                                                                                                                                             -- Variáveis Auxiliares da Memória de Calculo
                                                                                                                                             vnPercMemoriaCalculo           := (100 - vnPercBaseRedRj);
                                                                                                                                             vnValorCalculadoMemoriaCalculo := (vnBaseStRj * (vnPercMemoriaCalculo / 100));
            
            -- Aplica Redução na Base do ST Rj
            vnBaseStRj := vnBaseStRj * (vnPercBaseRedRj / 100);
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('-', 'Redução de ' || vnPercBaseRedRj || '% na Base ST (Crédito)', vnBaseStRj, vnPercMemoriaCalculo, vnValorCalculadoMemoriaCalculo);
          
            -- Calcula o Valor do ST RJ  
            vnValorStRj := vnBaseStRj * (NVL(p_percbasestrj,0) / 100);
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor Mínimo ST RJ', NULL, p_percbasestrj, vnValorStRj);
                                                                               
            -- Validação do ST Mínimo
            IF (NVL(vnstfonte,0) < NVL(vnValorStRj,0)) THEN
  
              -- Substitui a Base do ST 
              vnbcst    := NVL(vnBaseStRj,0); 
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Substituição da Base do ST conforme ST Mínimo RJ', NULL, NULL, vnbcst);                                                  
            
              -- Substitui o Valor do ST
              vnstfonte := NVL(vnValorStRj,0);
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Substituição do Valor do ST conforme ST Mínimo RJ', NULL, NULL, vnstfonte);                                                  
                                                  
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('VL_STRJ', 'MIN_STRJ');                                 
  
            ELSE
               
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('VL_STRJ', 'CALC_STRJ');                                 
                                          
            END IF;
             
    
          END IF; -- Fim Condição: PERCENTUAL BASE RJ - Priorização do Maior entre o Mínimo e o Calculado
          
        END IF; -- FIM CONDIÇÃO CALCULA VALOR DO ST
              
       /*--------------------------------------------------------------------------------------------
        Atualização de Retornos adicionais
        ---------------------------------*/
  
        -- APLICA O REDUTOR Cat/49 - 5661.146071.2016
        IF (p_USAREDUTORCAT49BASESTFONTE = 'S') THEN
          -- Recalcula o % Redução, para considerar o agregado do % Red. Base Cálculo com o % Redutor Cat/49    
          IF (NVL(nPERCREDUTORCAT49BASESTFONTE,0) <> 0) AND
             (NVL(vnBaseStOriginalSemReducao,0) > 0)    THEN
            p_PercBaseRedStFonteAlterado := ROUND((NVL(vnbcst,0) / NVL(vnBaseStOriginalSemReducao,0)) * 100,4);
                                                                                                                         -- Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',Redutor49';
          END IF;
        END IF;
              
        -- MED-2346 - Retorno das Outras Despesas que compõem a base de icms
        po_nVlFreteOutrasDespBaseIcms := vnVlFreteOutrasDespBaseSt;
        -- MED-2346 - Retorno do Percentual de Redução da Base de Icms
        po_nPercBaseRedIcmsFecp       := vnpercbaseredIcmsFecp;
		
        IF (NVL(p_USAVLSTMAIORPERCMINPMC, 'N') = 'S') AND
           (NVL(p_PERVLSTMAIORPERCMINPMC,0) > 0) AND
           (NVL(p_PRECOMAXCONSUM,0) > 0) THEN
		   
          vnStPercMinPMC := p_PRECOMAXCONSUM * p_PERVLSTMAIORPERCMINPMC / 100; 
          
          IF p_tipocalcst = 'T2' THEN
            vnStPercMinPMC := trunc((vnStPercMinPMC) * 100) / 100;
          ELSIF p_tipocalcst = 'A2' THEN
            vnStPercMinPMC := round((vnStPercMinPMC) * 100) / 100;
          ELSIF p_tipocalcst = 'PV' THEN
            vnStPercMinPMC := round(vnStPercMinPMC, p_numcasasdecvenda);       
          END IF;		   
		   
          IF vnStPercMinPMC > vnstfonte THEN
            vnstfonte := vnStPercMinPMC;
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Substituição do Valor do ST conforme Percentual Minimo PMC', NULL, NULL, vnstfonte);                                                  			
          END IF;
        END IF;		
              
       /*--------------------------------------------------------------------------------------------
        Retornos Base e Valor do ST
        --------------------------*/
        p_baseicst := vnbcst;  
        RETURN vnstfonte;
        
      EXCEPTION
        WHEN OTHERS THEN
          p_mensagem := 'Erro ao calcular STfonte: ' || SQLCODE || '-' ||
                        SQLERRM;
          RETURN 0;
      END FCALCULARSTFONTE;  
  
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      -- FUNCTION FCALCULARSTFONTE_INVERSO
      --42 parametros ( mas pode ser usada pode packages que utilizam a de 38 parÂmetros)
      -- *** Lembrar sincronia entre PRC_MED_CALCULARSTFONTE e PRC_MED_OBTEM_STFONTE ***
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      FUNCTION FCALCULARSTFONTE_INVERSO(p_valornotafiscal            IN NUMBER,
                                        p_codprod                    IN NUMBER,
                                        p_condvenda                  IN NUMBER,
                                        p_percvenda                  IN NUMBER,
                                        p_iva                        IN NUMBER,
                                        p_ivafonte                   IN OUT NUMBER,
                                        p_aliqicms1fonte             IN OUT NUMBER,
                                        p_aliqicms2fonte             IN OUT NUMBER,
                                        p_percbaseredstfonte         IN OUT NUMBER,
                                        p_percbaserednrpa            IN NUMBER,
                                        p_percbaseredconsumidor      IN NUMBER,
                                        p_utilizapercbaseredpf_trib  IN VARCHAR2,
                                        p_tipocalcst                 IN VARCHAR2,
                                        p_calcstpf                   IN VARCHAR2,
                                        p_utilizapercbaseredpf       IN VARCHAR2,
                                        p_clientefontest             IN VARCHAR2,
                                        p_calculast                  IN VARCHAR2,
                                        p_ieent                      IN VARCHAR2,
                                        p_tipofj                     IN VARCHAR2,
                                        p_isentoicms                 IN VARCHAR2,
                                        p_consumidorfinal            IN VARCHAR2,
                                        p_utilizaiesimplificada      IN VARCHAR2,
                                        p_tipoempresa                IN VARCHAR2,
                                        p_consideraisentoscomopf     IN VARCHAR2,
                                        p_vlipi                      IN NUMBER,
                                        p_uffilial                   IN VARCHAR2,
                                        p_estent                     IN VARCHAR2,
                                        p_usavalorultentbasest       IN VARCHAR2,
                                        p_valorultent                IN NUMBER,
                                        p_usaivafontediferenciado    IN VARCHAR2,
                                        p_ivafonte_cli               IN NUMBER,
                                        p_AceitaPFContribuinte       IN VARCHAR,
                                        p_ALIQICMS1                  IN NUMBER,
                                        p_ALIQICMS2                  IN NUMBER,
                                        p_contribuinte               IN VARCHAR2,
                                        p_numcasasdecvenda           in NUMBER,
                                        p_baseicst                   OUT NUMBER,
                                        p_mensagem                   OUT VARCHAR2,
                                        P_CUSTONFSEMST               in pcest.custonfsemst%type default 0,
                                        p_usavalorultentbasest2      in pctribut.usavalorultentbasest2%type default 'N',
                                        p_usapmcbasest               in pctribut.usapmcbasest%type default 'N' ,
                                        p_precomaxconsum             in pcprodut.precomaxconsum%type default 0 ,
                                        p_usabaseicmsreduzida        in pctribut.usabaseicmsreduzida%type default 'N',
                                        p_usabcrultent               IN VARCHAR2,
                                        p_basebcrultent              IN NUMBER,
                                        p_stbcrultent                IN NUMBER,
                                        p_CALCSTPAUTAFARMACIAPOPULAR IN VARCHAR2,
                                        p_PAUTAFONTE                 IN NUMBER,
                                        p_FARMACIAPOPULAR            IN VARCHAR2,
                                        p_PARTICIPAFARMACIAPOPULAR   IN VARCHAR2,   
                                        p_usaptabelabasest           IN VARCHAR2,
                                        p_somenteIVATribut           IN VARCHAR2, -- [HIS.05161.2014]
                                        p_usadescsimplesnac          IN VARCHAR2, -- [HIS.05161.2014]
                                        p_simplesnacional            IN VARCHAR2, -- [HIS.05161.2014]
                                        p_percredpvendasimplesnac    IN NUMBER,   -- [HIS.05161.2014]
                                        p_tipomerc                   IN VARCHAR2,
                                        p_usarajusteprecocmed        IN VARCHAR2,
                                        p_percajusteprecocmed        IN NUMBER,
                                        p_medretirarstbnfestadual    IN VARCHAR2,
                                        p_itembonific                IN VARCHAR2,
                                        p_vlfreteoutrasdesp          IN NUMBER,
                                        p_bnfnaocalculaicms          IN VARCHAR2,
                                        p_USAREGSIMPLCARGATRIBSTFONTE  IN VARCHAR2 DEFAULT 'N', -- HIS.03187.2015
                                        p_REGSIMPLCARGATRIBSTFONTE     IN VARCHAR2 DEFAULT 'N', -- HIS.03187.2015
                                        p_PERCREGSIMPLCARGATRIBSTFONTE IN NUMBER   DEFAULT 0,   -- HIS.03187.2015     
                                        p_USAREDUTORCAT49BASESTFONTE   IN VARCHAR2 DEFAULT 'N', -- 5661.146071.2016
                                        p_PERCREDUTORCAT49BASESTFONTE  IN NUMBER   DEFAULT 0,   -- 5661.146071.2016                  
                                        p_USACARGAMINIMADEFERIMSTFONTE IN VARCHAR2 DEFAULT 'N', -- HIS.01277.2017
                                        p_PERCARGAMINIMADEFERIMSTFONTE IN NUMBER   DEFAULT 0,   -- HIS.01277.2017     
                                        p_USAVLSTMAIORPERCMINPMC       IN VARCHAR2 DEFAULT 'N', -- DDVENDAS-40134
                                        p_PERVLSTMAIORPERCMINPMC       IN NUMBER   DEFAULT 0,   -- DDVENDAS-40134
                                        p_codfilialfaturamento         IN VARCHAR2,             -- HIS.03371.2017
                                        p_USAREDICMNORMVENDASTFONTE    IN VARCHAR2,             -- MED-1080
                                        p_PERCBASERED                  IN NUMBER,               -- MED-1080
                                        p_percipivenda                 IN NUMBER,
                                        p_usavlultentmediobasest       IN VARCHAR2, 
                                        p_percbasestrj                 IN NUMBER,
                                        p_vlultentmes                  IN NUMBER,
                                        p_valorprodutos                OUT NUMBER,
                                        p_participafuncep              IN  VARCHAR2,
                                        p_codconfigfuncepmed           IN  NUMBER,   
                                        p_aliqicmsfecp                 IN  NUMBER,                                                   
                                        p_vlfecp                       OUT NUMBER,
                                        p_usapmpfbasest                in pctribut.usapmpfbasest%type,
                                        p_pmpf                         IN NUMBER,
                                        po_pmpf                        OUT NUMBER
                                        ) 
      RETURN NUMBER IS
      
        -- Variáveis Locais da Função
        vnpercbasered                  NUMBER;
        vnpercbaseredBaseCred          NUMBER; -- MED-1080
        vnbcst                         NUMBER;
        vnstf1                         NUMBER;
        vnstf2                         NUMBER;
        vnstfonte                      NUMBER;
        vnpbase                        NUMBER;
        vbPessoaFisica                 BOOLEAN;
        vscontribuinte                 PCCLIENT.CONTRIBUINTE%TYPE;
        vnIvaFonte                     NUMBER;
        vbCalculaSTFonte               BOOLEAN;
        vnpvenda                       NUMBER;
        vncustonfsemst                 PCEST.CUSTONFSEMST%TYPE;
        -- Regra Farmácia Popular
        vbRegraFciaPopular             BOOLEAN;
        -- Regra Usar PMC na Base do ST
        vbUsaPmcBaseSt                 BOOLEAN;
        -- PMC de Referência para Ajuste Preço CMED
        vnPmcAjustePrecoCMED           NUMBER;
        -- Valor do Frete e Despesas Acessórias a Somar nas Base de ST
        vnVlFreteOutrasDespBaseSt      NUMBER;
        -- Valor do Frete e Despesas Acessórias a Somar nas Base de ICMS
        vnVlFreteOutrasDespBaseIcms    NUMBER;
        -- Se usa Regra Regime Simplificado pela Carga Tributária Média                   
        vbUsaRegraRegSimplCargaTrib    BOOLEAN;
        vnBcIcmsOperPropriaCargaTribut NUMBER;
        vnVlIcmsOperPropriaCargaTribut NUMBER;
        vnBcEstimatSimplifCargaTribut  NUMBER;
        vnVlEstimatSimplifCargaTribut  NUMBER;
        -- Se usa ST da Última Entrada
        vbUsaRegraStUltimaEntrada      BOOLEAN;
        -- Se Ignorar ST Fonte no TV 10 quando valores zerados na tributação
        vvIgnorarSTFonteTV10Zerado     VARCHAR2(1);  
        -- Regra Exceção ST Fonte Paraná
        vvUsaRegraSTParanaOutrasDesp   VARCHAR2(1);
        -- Base ST Original sem Redução - 5661.146071.2016
        vnBaseStOriginalSemReducao     NUMBER;
        -- HIS.01277.2017
        vnStFonteCargaMinima           NUMBER;
        vnStPercMinPMC                 NUMBER;		
        -- Variáveis Auxiliares da Memória de Calculo
        vnPercMemoriaCalculo           NUMBER;
        vnValorCalculadoMemoriaCalculo NUMBER;
        vvDescOpcaoSelMemoriaCalculo   VARCHAR2(200);
        -- Variáveis para cálculo do ST RJ
        vnBaseStRj                     NUMBER;
        vnValorStRj                    NUMBER;
        vnPercBaseRedRj                NUMBER;
        -- Variáveis para Cálculo do ST Inverso
        vnPercentualValorProdutos      NUMBER;
        vnPercentualBaseSt             NUMBER;
        vnPercentualValorIcmsCompra    NUMBER;
        vnPercentualValorSt            NUMBER;
        vnPercentualValorNotaFiscal    NUMBER;
        vnValordosProdutosPeloStMin    NUMBER;
        -- Regra Usar PMPF na Base do ST
        vbUsaPmPfBaseSt                BOOLEAN;
         
      BEGIN
         
       /********************
        Inicializa Variáveis
        ********************/
        
        -- Valor dos Produtos 
        p_valorprodutos             := 0;
      
        -- Regra Farmácia Popular
        vbRegraFciaPopular          := ( (NVL(p_CALCSTPAUTAFARMACIAPOPULAR,'N') = 'S') and
                                         (NVL(p_FARMACIAPOPULAR,'N') = 'S') and
                                         (NVL(p_PARTICIPAFARMACIAPOPULAR,'N') = 'S') and
                                         (NVL(p_PAUTAFONTE,0) > 0) );

        -- Regra Usar PMC na Base do ST
        vbUsaPmcBaseSt              := ( (NVL(p_PRECOMAXCONSUM,0) > 0) and
                                         (NVL(p_USAPMCBASEST,'N') = 'S') );
  
        -- Rgra Usa ST da Última Entrada (Se não for Consumidor Final)
        vbUsaRegraStUltimaEntrada   := ( (NVL(p_usabcrultent,'N')     = 'S') AND
                                         (NVL(p_consumidorfinal,'N') <> 'S') ); 
  
        -- Regra Regime Simplificado pela Carga Tributária Média -- HIS.03187.2015                                    
        vbUsaRegraRegSimplCargaTrib := ( (NVL(p_USAREGSIMPLCARGATRIBSTFONTE,'N') = 'S') and
                                         (NVL(p_REGSIMPLCARGATRIBSTFONTE,'N')    = 'S') and
                                         (NVL(p_PERCREGSIMPLCARGATRIBSTFONTE,0)  > 0) );

        -- Regra Usar PMPF na Base do ST
        vbUsaPmPfBaseSt              := ( (NVL(p_PMPF,0) > 0) and
                                          (NVL(p_USAPMPFBASEST,'N') = 'S') );
                              
        -- Regra Exceção ST Fonte Paraná para Somar Outras Despesas na Base ICMS com PMC na Base do ST                                      
        BEGIN
          SELECT VALOR
            INTO vvUsaRegraSTParanaOutrasDesp
            FROM PCREGRASEXCECAOMED
           WHERE (CODFILIAL = '99')
             AND (NOME      = 'USAREGRASTPARANAOUTRASDESP');
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvUsaRegraSTParanaOutrasDesp := 'N';
        END;                     
  
       /***************************
        Inicializa Outras Variáveis
        ***************************/
  
        -- Retorno - SE A LEGISLAÇÃO MUDAR O % DE REDUÇÃO DO CADASTRO - 5661.146071.2016      
  
        -- Outras Variáveis
        vnbcst                      := 0;
        vnstf1                      := 0;
        vnstf2                      := 0;
        vnstfonte                   := 0;
        vbPessoaFisica              := False;
        vnIvaFonte                  := p_IVAFONTE;
        vbCalculaSTFonte            := True;
        --
        vscontribuinte              := p_contribuinte;
        --
        --vnpvenda                    := p_pvenda;
        --
        vnVlFreteOutrasDespBaseSt   := 0;
        vnVlFreteOutrasDespBaseIcms := 0;           
  
        -- Custo NF sem ST
        vncustonfsemst   := p_custonfsemst;   
        if nvl(P_CUSTONFSEMST,0) = 0 then
           vnCUSTONFSEMST := p_valorultent;    
        end if;
      
        -- Definindo se é Pessoa Física
        if (p_AceitaPFContribuinte = 'N') then
          vscontribuinte := p_AceitaPFContribuinte;
        end if;
      
        if (((p_TIPOFJ = 'F') and (p_UTILIZAIESIMPLIFICADA = 'N')) or
           (p_CONSUMIDORFINAL = 'S') or
           ((p_CONSIDERAISENTOSCOMOPF = 'S') and
           ((Trim(p_IEENT) = '') or (p_IEENT = 'ISENTO') or
           (p_IEENT = 'ISENTA')))) and (vscontribuinte = 'N') then
          vbpessoafisica := true;
        end if;
      
       /**********************
        Define se Usa ST Fonte
        **********************/
      
        -- Identificar a incidência de ST Fonte [RDB05]
        vbCalculaSTFonte := (p_CLIENTEFONTEST = 'S')  and
                            ((p_ALIQICMS1FONTE > 0) or (p_ALIQICMS2FONTE > 0));-- and  ((p_ALIQICMS1 = 0) or (p_ALIQICMS2 = 0));
      
        vbCalculaSTFonte := vbCalculaSTFonte and
                            (not ((p_CALCSTPF = 'N') and (vbpessoafisica)));
        
        -- Item Bonificado com Regime Especial pra Retirar ST da Bonificação da NF Estadual
        IF ((NVL(p_itembonific,'N') = 'S') AND
            (NVL(p_medretirarstbnfestadual,'N') = 'S') AND
            (p_uffilial = p_estent)) THEN
          vbCalculaSTFonte            := FALSE;
          vbUsaRegraRegSimplCargaTrib := FALSE; -- HIS.03187.2015
        END IF;
        
        -- Se for Pedido TV10
        IF (pi_nCondVenda = 10) THEN
      
          -- Verifica exceção para ignorar ST Fonte TV 10 quando valores zerados na tibutação
          BEGIN
            SELECT NVL(VALOR,'N')
              INTO vvIgnorarSTFonteTV10Zerado
              FROM PCREGRASEXCECAOMED
             WHERE NOME      = 'IGNORARSTFONTETV10ZERADO'
               AND CODFILIAL = '99';  
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vvIgnorarSTFonteTV10Zerado := 'N';
          END;     
        
          -- Se possuir a regra
          IF vvIgnorarSTFonteTV10Zerado = 'S' THEN
            -- Reinicializa a variável
            vvIgnorarSTFonteTV10Zerado := 'N';
            -- Verifica se os campos estão zerados 
            BEGIN
              SELECT 'S'
                INTO vvIgnorarSTFonteTV10Zerado
                FROM PCTRIBUT 
               WHERE CODST = pio_nCodSt
                 AND NVL(IVATRANSF,0)              <= 0
                 AND NVL(ALIQICMS1TRANSF,0)        <= 0
                 AND NVL(ALIQICMS2TRANSF,0)        <= 0
            	   AND NVL(PAUTATRANSF,0)            <= 0
                 AND NVL(PERCBASEREDSTTRANSF,0)    <= 0
                 AND NVL(IVAFONTETV10,0)           <= 0
                 AND NVL(ALIQICMS1FONTETV10,0)     <= 0
            	   AND NVL(ALIQICMS2FONTETV10,0)     <= 0
                 AND NVL(PERCBASEREDSTFONTETV10,0) <= 0
                 AND NVL(PAUTAFONTETV10,0)         <= 0;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vvIgnorarSTFonteTV10Zerado := 'N';
            END; 
            
            -- Se os valores para os campos estão zerados, não calcula ST Fonte
            IF (vvIgnorarSTFonteTV10Zerado = 'S') THEN
              vbCalculaSTFonte := FALSE;
            END IF; 
                     
          END IF; -- Fim-Se possui regra para ignorar ST com valores zerados
        END IF; -- Fim-Se Pedido TV10     
        
       /*********************************************************************************************
        *********************************************************************************************
        **                     CALCULAR VALOR DO ST PELA ULTIMA ENTRADA                            **
        *********************************************************************************************
        *********************************************************************************************/
        IF   (vbUsaRegraStUltimaEntrada) AND
             (vbCalculaSTFonte)          THEN -->> HIS.03788.2015 - Somente se for STFONTE
  
          p_mensagem := 'Funcionalidade não habilitada para o ST pela última entrada';
           
       /*********************************************************************************************
        *********************************************************************************************
        **            CALCULAR VALOR DO ST PELA CARGA TRIBUTÁRIA MÉDIA - HIS.03187.2015            **
        *********************************************************************************************
        *********************************************************************************************/
        ELSIF (vbUsaRegraRegSimplCargaTrib) AND
              (vbCalculaSTFonte)            THEN -->> HIS.03371.2017 - Somente se for STFONTE
            
          p_mensagem := 'Funcionalidade não habilitada para o ST pela Carga Tributária Média';
          
       /*********************************************************************************************
        *********************************************************************************************
        **                          CALCULAR VALOR DO ST FONTE [RBD04]                             **
        *********************************************************************************************
        *********************************************************************************************/
        ELSIF (vbCalculaSTFonte) THEN
                        
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DA REDUÇÃO DA BASE DE CÁLCULO
          --------------------------------------*/
        
          vnpercbasered := p_percbaseredstfonte;
        
          -- MED-1080 - Redução da Base Crédito do ST Fonte
          vnpercbaseredBaseCred := p_percbaseredstfonte;
          IF (NVL(p_USAREDICMNORMVENDASTFONTE,'N') = 'S') THEN
            vnpercbaseredBaseCred := p_PERCBASERED; -- MED-1080
          END IF;
        
          ---- Se tipo de empresa do cliente for Normal RPA
          ---- Aplicar %reducao na base de ICMS especifico
          IF (p_tipoempresa = 'NRPA') THEN
            vnpercbasered         := p_percbaserednrpa;
            vnpercbaseredBaseCred := p_percbaserednrpa; -- MED-1080
          END IF;
          ---- Cliente consumidor final utiliza %base red. p/ consumidor final
          IF (p_consumidorfinal = 'S') AND (p_percbaseredconsumidor <> 0) THEN
            vnpercbasered         := p_percbaseredconsumidor;
            vnpercbaseredBaseCred := p_percbaseredconsumidor; -- MED-1080
          END IF;
          ---- Cliente PF que utiliza IE simplificada nao aplica %base red
          IF (p_utilizaiesimplificada = 'S') AND (p_tipofj = 'F') AND
             (p_contribuinte = 'N') THEN
            vnpercbasered         := 0;
            vnpercbaseredBaseCred := 0; -- MED-1080
          END IF;
        
          if vbpessoafisica = true then
            if (p_UTILIZAPERCBASEREDPF = 'N') or
               (p_UTILIZAPERCBASEREDPF_TRIB = 'N') then
              vnPERCBASERED         := 0;
              vnpercbaseredBaseCred := 0; -- MED-1080
            end if;
          end if;
        
          IF (p_isentoicms = 'S') OR (p_condvenda = 7) THEN
            vnpercbasered         := 0;
            vnpercbaseredBaseCred := 0; -- MED-1080
          END IF;
          
          --// MERGE CR -> GU = Farmácia Popular não tem Redução da Base de Cálculo
          if (vbRegraFciaPopular) then
            vnpercbasered         := 0;
            vnpercbaseredBaseCred := 0; -- MED-1080
          end if;    
          
          p_percbaseredstfonte := vnpercbasered;
        
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DO PERCENTUAL DE IVA FONTE
          -----------------------------------*/
        
          -- Definir IVA do ST Fonte [RBD07]
          if p_UsaIVAFonteDiferenciado = 'N' then
            vnIvaFonte := p_IVAFONTE;
          
            --Comentado na 316 por:  //Fernandes 13/09/2011
            --if vnIVAFONTE = 0  and 
            --   not ((nvl(p_PRECOMAXCONSUM,0) > 0) and (NVL(p_USAPMCBASEST,'N') = 'S')) then
            --  p_ALIQICMS1FONTE := 0;
            --  p_ALIQICMS2FONTE := 0;
            --end if;
            --Fim Comentado na 316 por:  //Fernandes 13/09/2011
          elsif p_usaivafontediferenciado = 'S' then
            vnIvaFonte := p_IVAFonte_Cli;
            
          elsif p_usaivafontediferenciado = 'M' then
          
            if p_IVAFONTE > p_IVAFonte_Cli then
              vnIVAFONTE := p_IVAFONTE;
            else
              vnIvaFonte := p_IVAFonte_Cli;
            end if;
            
          end if;
        
          -- [HIS.05161.2014] - Redução Simples Nacional no IVA
          IF (p_somenteIVATribut = 'N') THEN
            IF ((NVL(p_usadescsimplesnac,'N')     = 'N')     AND  -- Somente se na Rotina 132 Não usa desconto do Simples Nacional
                (NVL(p_percredpvendasimplesnac,0) > 0)       AND  -- Somente se tiver % Redução cadastrado na Tributação
                (NVL(p_simplesnacional,'N')       = 'S')     AND  -- Somente se o Cliente participa do Simples Nacional 
                (NVL(p_tipomerc,' ') NOT IN (' ','M','MA'))) THEN -- Somente se não for Medicamento e tiver o Tipo Merc. Preenchido
              vnIvaFonte := vnIvaFonte * (p_percredpvendasimplesnac / 100);
            END IF;          
          END IF;
        
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DA BASE DE CÁLCULO DA ALIQ 01
          --------------------------------------*/
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Alíquota de ICMS Compra (Débito)', NULL, p_ALIQICMS1FONTE, NULL);
                                                 
          --------------------------------------------
          -- APLICA REDUÇÃO na Base de Cáculo Aliq. 01
          --------------------------------------------
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Aplicar Redução na Alíquota de Compra (Débito) ?', 'RED_BCSTINV');                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Sim, aplicar redução', 'RED_BCSTINV', 'SIM');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Não aplicar redução', 'RED_BCSTINV', 'NAO');          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('RED_BCSTINV', 'NAO'); -->> Default               
          
          -- Se tem Redução na Base do ST
          IF vnpercbasered > 0 THEN
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Percentual de Redução', NULL, vnpercbasered, NULL);
                                      
            -- Reduz a Alíquota de ICMS de Compra (Arredonda para 2 casas decimais)
            p_ALIQICMS1FONTE := ROUND((NVL(p_ALIQICMS1FONTE,0) * (NVL(vnpercbasered,0) / 100)),2);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Alíquota ICMS Compra com Redução [Aliq. Compra x (Redução ' || CHR(247) || ' 100)]', NULL, p_ALIQICMS1FONTE, NULL);
           
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('RED_BCSTINV', 'SIM');                     
            
            
          END IF; -- Fim Condição: APLICA REDUÇÃO na Base de Cáculo Aliq. 01
                  
          ---------------------------------------------        
          -- APLICA O REDUTOR Cat/49 - 5661.146071.2016
          ---------------------------------------------        
          
          -- Se usa Redutor Cat/49
          IF (p_USAREDUTORCAT49BASESTFONTE = 'S') THEN
            IF (NVL(p_PERCREDUTORCAT49BASESTFONTE,0) > 0) THEN
  
              p_mensagem := 'Funcionalidade não habilitada para o ST com Redutor Cat/49';
              
            END IF;
          END IF;
                            
          ---------------------------------------------------------------------------------------------      
          -- Regra Ajuste de Preço CMED para o PMC
          -- (Tributação Marcada para Ajuste de Preço CMED, se tiver PMC e se Não for Farmácia Popular)
          ---------------------------------------------------------------------------------------------      
                  
          -- Se Utilizar Legislação Cat/35 (Ajuste Preço CMED)
          IF (NVL(p_usarajusteprecocmed,'N') = 'S') AND
             (NVL(p_PRECOMAXCONSUM,0) > 0) AND
             (NOT vbRegraFciaPopular) THEN
                       
            p_mensagem := 'Funcionalidade não habilitada para o ST com Legislação Cat/35 (Ajuste Preço CMED)';
                                         
          -----------------------------------------------
          -- Preço Tabela na Base do ST
          -----------------------------------------------
          ELSIF (NVL(p_usaptabelabasest,'N') = 'S') THEN
  
            p_mensagem := 'Funcionalidade não habilitada para o ST com Preço de Tabela na Base do ST';
                                                                                                          
          -----------------------------------------------
          -- Demais Casos (FARMACIA POPULAR, PMC, MVA ...
          -----------------------------------------------
          ELSE
                  
           /*--------------------------------------------------------------------------------------------
            DEFINIÇÃO DO VALOR DO ICMS INTERNO
            ---------------------------------*/
        
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Opção de Cálculo Inverso do ST', 'INVERSO_ST');                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Cálculo inverso de ST com Pauta', 'INVERSO_ST', 'PAUTA_INVERSOST');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Cálculo inverso de ST com Valor da Ultima Entrada RJ', 'INVERSO_ST', 'VLENTRJ_INVERSOST');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('3) Cálculo inverso de ST com PMC', 'INVERSO_ST', 'PMC_INVERSOST');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('4) Cálculo inverso de ST pela Média dos Valores das Entradas (MG)', 'INVERSO_ST', 'MEDIAMG_INVERSOST');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('4) Cálculo inverso de ST pelo MVA', 'INVERSO_ST', 'MVA_INVERSOST');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('5) Não Aplicar ST inverso (funcionalidade não habilitada)', 'INVERSO_ST', 'NAO_INVERSOST');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('6) Cálculo inverso de ST com PMPF', 'INVERSO_ST', 'PMPF_INVERSOST');          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('INVERSO_ST', 'NAO_INVERSOST'); -->> Default               
        
            -- *** CALCULO INVERSO COM PAUTA SEM MVA ***
            -- FARMACIA POPULAR
            -- PMC
            -- PMPF
            if (vbRegraFciaPopular) or
               (vbUsaPmcBaseSt)     or
               (vbUsaPmPfBaseSt)    then
            
              IF    (vbRegraFciaPopular) THEN
              
                -- Pauta = Pauta Fonte Tributação
                p_pautafonteaplicado := NVL(p_PAUTAFONTE,0);
                
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Pauta (Pauta Fonte ST)', NULL, NULL, p_pautafonteaplicado);
                
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('INVERSO_ST', 'PAUTA_INVERSOST');
                
              ELSIF (vbUsaPmcBaseSt)     THEN 
  
                -- Pauta = PMC
                p_pautafonteaplicado := NVL(P_PRECOMAXCONSUM,0);
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Pauta (PMC)', NULL, NULL, p_pautafonteaplicado);
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Aliq. Compra', NULL, p_ALIQICMS1FONTE, NULL);
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('INVERSO_ST', 'PMC_INVERSOST');
 
 
               ELSIF (vbUsaPmPfBaseSt)     THEN 
               
                po_pmpf := NVL(P_PMPF,0);                
  
                -- Pauta = PMPF
                p_pautafonteaplicado := NVL(P_PMPF,0);
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Pauta (PMPF)', NULL, NULL, p_pautafonteaplicado);
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Aliq. Compra', NULL, p_ALIQICMS1FONTE, NULL);
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('INVERSO_ST', 'PMPF_INVERSOST');
              
             
              END IF;
                                                                    
              -- Valor Icms Compra - Débito
              vnSTF1 := NVL(p_pautafonteaplicado,0) * (NVL(p_ALIQICMS1FONTE,0)/100);
              p_baseicst := NVL(p_pautafonteaplicado,0); -- MED-1930
              IF (NVL(vnpercbasered,0) > 0) THEN
                -- Compensar a Alíquota que foi reduzida
                p_baseicst := (NVL(p_baseicst,0) * (NVL(vnpercbasered,0) / 100)); 
              END IF;
              
              
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor Icms Compra (Débito) = [Pauta x (Aliq. Compra ' || CHR(247) || ' 100)]',  NULL, NULL, vnSTF1);
                             
            -- *** CALCULO INVERSO COM PAUTA MAS COM MVA ***
            -- ST RJ
            elsif ((NVL(p_usavalorultentbasest,'N') = 'S') AND (NVL(p_percbasestrj,0) > 0)) then
  
              -- Pauta = Valor da Ultima Entrada
              p_pautafonteaplicado := NVL(p_valorultent,0);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Pauta (Valor Ultima Entrada)', NULL, NULL, p_pautafonteaplicado);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Percentual de MVA', NULL, vnIVAFONTE, NULL);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Aliq. Compra', NULL, p_ALIQICMS1FONTE, NULL);
  
              -- Valor Icms Compra - Débito
              vnSTF1 := (NVL(p_pautafonteaplicado,0) * (1 + (NVL(vnIVAFONTE,0) / 100))) * (NVL(p_ALIQICMS1FONTE,0)/100);
              p_baseicst := (NVL(p_pautafonteaplicado,0) * (1 + (NVL(vnIVAFONTE,0) / 100))); -- MED-1930
              IF (NVL(vnpercbasered,0) > 0) THEN
                -- Compensar a Alíquota que foi reduzida
                p_baseicst := (NVL(p_baseicst,0) * (NVL(vnpercbasered,0) / 100)); 
              END IF;
              
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor Icms Compra (Débito) = [(Pauta x (1 + (MVA ' || CHR(247) || ' 100))) x (Aliq. Compra ' || CHR(247) || ' 100)]', NULL, NULL, vnSTF1);
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('INVERSO_ST', 'VLENTRJ_INVERSOST');    
  
            -- ST MG (Pelo Valor Médio das Ultimas Entradas)
            elsif (NVL(p_usavlultentmediobasest,'N') = 'S') then
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Vl.Médio Entradas', NULL, NULL, p_vlultentmes);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Percentual de MVA', NULL, vnIVAFONTE, NULL);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Aliq. Compra', NULL, p_ALIQICMS1FONTE, NULL);
  
              -- Valor Icms Compra - Débito
              vnSTF1 := (NVL(p_vlultentmes,0) * (1 + (NVL(vnIVAFONTE,0) / 100))) * (NVL(p_ALIQICMS1FONTE,0)/100);
              p_baseicst := (NVL(p_vlultentmes,0) * (1 + (NVL(vnIVAFONTE,0) / 100))); -- MED-1930
              IF (NVL(vnpercbasered,0) > 0) THEN
                -- Compensar a Alíquota que foi reduzida
                p_baseicst := (NVL(p_baseicst,0) * (NVL(vnpercbasered,0) / 100)); 
              END IF;
              
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor Icms Compra (Débito) = [(Vl.Médio Entradas x (1 + (MVA ' || CHR(247) || ' 100))) x (Aliq. Compra ' || CHR(247) || ' 100)]', NULL, NULL, vnSTF1);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('INVERSO_ST', 'MEDIAMG_INVERSOST');    
               
            -- Demais casos: COM IVA
            else
            
              -- *************************************************************************************************
              -- *** O CÁLCULO SEM PAUTA E COM MVA SERÁ FEITO AO FINAL DESTA FUNÇÃO COM UMA FÓRMULA ESPECÍFICA ***
              -- *************************************************************************************************
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('INVERSO_ST', 'MVA_INVERSOST');    
      
            end if;
            
          END IF;
                            
          -- Valor Aliq. 01 --
          --------------------
          
         /*--------------------------------------------------------------------------------------------
          DEFINIÇÃO DA BASE DE CALCULO DA ALIQ 02
          --------------------------------------*/
                    
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Alíquota de ICMS Venda (Crédito)', NULL, p_ALIQICMS2FONTE, NULL);
                    
          ---------------------------------------------
          -- Se usa Base ICMS Reduzida no Cálculo do ST
          ---------------------------------------------
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Aplicar Redução na Base de ICMS (Crédito) ?', 'RED_BCICMINV');                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Sim, reduzir a base usando o Percentual Redução do ST Fonte', 'RED_BCICMINV', 'SIM_REDFONTE');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Sim, reduzir a base usando o Percentual Redução do ICMS da Venda', 'RED_BCICMINV', 'SIM_REDVENDA');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('3) Não reduzir a base', 'RED_BCICMINV', 'NAO');          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('RED_BCICMINV', 'NAO'); -->> Default               
          
                                                                                                                                             -- Inicio: Memória de Cálculo
                                                                                                                                             -- Se usa Base ICMS Reduzida
                                                                                                                                             IF (p_usabaseicmsreduzida = 'S') THEN
            
                                                                                                                                             -- MED-1080 - Redução da Base Crédito do ST Fonte
                                                                                                                                             IF (NVL(p_USAREDICMNORMVENDASTFONTE,'N') = 'S') THEN
              
                                                                                                                                             IF vnpercbaseredBaseCred > 0 THEN
               
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('RED_BCICMINV', 'SIM_REDVENDA');                                               
                                                                                      
                                                                                                                                             END IF;
              
                                                                                                                                             ELSE
                        
                                                                                                                                             IF vnpercbasered > 0 THEN
              
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('RED_BCICMINV', 'SIM_REDFONTE');                                 
                                                                                      
                                                                                                                                             END IF;
              
                                                                                                                                             END IF;
                                                                                                                                             END IF;
                                                                                                                                             -- Fim: Memória de Cálculo
            
          -- Se Item Bonificado e a Bonificação não calcular ICMS
          IF ((p_itembonific IN ('S','F')) and -- DDMEDICA-198 - Incluir F
              (p_bnfnaocalculaicms = 'S')) THEN
  
            p_mensagem := 'Funcionalidade não habilitada para o ST com Item Bonificado';
            --p_ALIQICMS2FONTE := 0;
  
          END IF;
                                    
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Percentual de Redução', NULL, vnpercbaseredBaseCred, NULL);
                                    
          -- Se usa Base ICMS Reduzida
          IF (p_usabaseicmsreduzida = 'S') THEN
          
            -- Reduz a Alíquota de ICMS de Compra (Arredonda para 2 casas decimais)
            IF vnpercbaseredBaseCred > 0 THEN
    	
              p_ALIQICMS2FONTE := ROUND((NVL(p_ALIQICMS2FONTE,0) * (NVL(vnpercbaseredBaseCred,0) / 100)),2);
      
                                                                                                                                               -- Memória de Cálculo          
                                                                                                                                               P_INSERIR_MEMORIA_CALCULO('=', 'Alíquota ICMS Venda com Redução [Aliq. Venda x (Redução ' || CHR(247) || ' 100)]', NULL, p_ALIQICMS2FONTE, NULL);
            END IF;																																		   
  
          END IF;
            
          -- Valor Aliq. 02 --
          --------------------
                                      
         /*--------------------------------------------------------------------------------------------
          CALCULO DO ST FONTE
          ------------------*/
                       
          --------------------------------------------------------
          -- CARGA MÍNIMA DEFERIMENTO ST FONTE - HIS.01277.2017 --
          --------------------------------------------------------
          
          -- Se usa Carga Mínima de ST Fonte
          IF (p_USACARGAMINIMADEFERIMSTFONTE = 'S') THEN
                         
            p_mensagem := 'Funcionalidade não habilitada para o ST com Carga Mínima de Deferimento do ST Fonte';
                                                        
          END IF; -- FIM: CARGA MÍNIMA DEFERIMENTO ST FONTE - HIS.01277.2017
		  
          IF (p_USAVLSTMAIORPERCMINPMC = 'S') THEN
                         
            p_mensagem := 'Funcionalidade não habilitada para o Valor de ST Maior que Percentual Mínimo sobre PMC';
                                                        
          END IF;		  
  
  
  
         /**********************************************************************************************
           CÁLCULO DO VALOR DOS PRODUTOS USANDO PAUTA (FARMACIA POPULAR, PMC, VALOR ULTIMA ENTRADA ...)
          **********************************************************************************************/
          -- *** CALCULO INVERSO COM PAUTA SEM MVA *****************************************************
          -- FARMACIA POPULAR
          -- PMC
          -- PMPF
          IF (vbRegraFciaPopular) OR
             (vbUsaPmcBaseSt)     OR
             (vbUsaPmPfBaseSt)    OR
          -- *** CALCULO INVERSO COM PAUTA MAS COM MVA ***
          -- ST RJ
             ((NVL(p_usavalorultentbasest,'N') = 'S') AND (NVL(p_percbasestrj,0) > 0)) THEN
             
            -- Requer Alíquota de Venda para não dar erro de divisão por zero
            IF (NVL(p_ALIQICMS2FONTE,0) > 0) THEN
             
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor Nota Fiscal', NULL, NULL, p_valornotafiscal);
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor ICMS Compra', NULL, NULL, vnSTF1);
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Aliq. ICMS Venda', NULL, NULL, p_ALIQICMS2FONTE);
  
              -- Cálculo do Valor dos Produtos sem Impostos
              p_valorprodutos := (NVL(p_valornotafiscal,0) - NVL(vnSTF1,0)) / ( 1 - (NVL(p_ALIQICMS2FONTE,0) / 100));
              p_valorprodutos := round(p_valorprodutos, p_numcasasdecvenda);   
               
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Valor dos Produtos = [(Valor Nota Fiscal - Valor Icms Compra) ' || CHR(247) || ' ( 1 - (Aliq. ICMS Venda ' || CHR(247) || ' 100))]', p_valorprodutos, NULL, NULL);
                            
            ELSE
             
              p_mensagem := 'Funcionalidade não habilitada para o ST sem Alíquota de Venda (Crédito)';
             
            END IF;
          
           /*************
            ST DE RETORNO
            *************/
            vnstfonte :=  (NVL(p_valornotafiscal,0) - NVL(p_valorprodutos,0)) ;
    
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Valor do ST = (Valor NF - Valor Produtos)', NULL, NULL, vnstfonte);
            
            --Calcular ST - Truncar com 2 casas decimais
            IF p_tipocalcst = 'T2' THEN
              vnstfonte := trunc((vnstfonte) * 100) / 100;
            ELSIF p_tipocalcst = 'A2' THEN
              vnstfonte := round((vnstfonte) * 100) / 100;
            ELSIF p_tipocalcst = 'PV' THEN
              vnSTFONTE := round(vnSTFONTE, p_numcasasdecvenda);       
            END IF;
          
          -- *** CALCULO ST MG *************************************************************************
          ELSIF (NVL(p_usavlultentmediobasest,'N') = 'S') THEN
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Vl.Médio Entradas', NULL, NULL, p_vlultentmes);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Aliq. Venda', NULL, p_ALIQICMS2FONTE, NULL);
  
            -- Valor Icms Venda - Crédito
            vnSTF2 := (NVL(p_vlultentmes,0) * (NVL(p_ALIQICMS2FONTE,0)/100));
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor Icms Venda (Crédito) = (Vl.Médio Entradas x * (Aliq. Venda ' || CHR(247) || ' 100)', NULL, NULL, vnSTF2);
  
           /*************
            ST DE RETORNO
            *************/
            vnstfonte :=  (NVL(vnSTF1,0)- NVL(vnSTF2,0)) ;
                      
            --Calcular ST - Truncar com 2 casas decimais
            IF p_tipocalcst = 'T2' THEN
              vnstfonte := trunc((vnstfonte) * 100) / 100;
            ELSIF p_tipocalcst = 'A2' THEN
              vnstfonte := round((vnstfonte) * 100) / 100;
            ELSIF p_tipocalcst = 'PV' THEN
              vnstfonte := round(vnstfonte, p_numcasasdecvenda);       
            END IF;          
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor do ST MG = (Valor Icms Compra - Valor Icms Venda)', NULL, NULL, vnstfonte);
                                                                                                                               
            -- Calcula o Valor dos Produtos pelo ST MG
            p_valorprodutos := NVL(p_valornotafiscal,0) - NVL(vnstfonte,0);
            p_valorprodutos := round(p_valorprodutos, p_numcasasdecvenda);   
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor Nota Fiscal', NULL, NULL, p_valornotafiscal);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Valor dos Produtos pelo ST MG = (Valor NF - Valor ST MG)', NULL, NULL, p_valorprodutos);
  
             
          -- *** CALCULO INVERSO COM MVA SEM PAUTA *****************************************************
          ELSE
          
            -- Valor dos Produtos em Percentual
            vnPercentualValorProdutos := 100;
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor dos Produtos em Percentual', vnPercentualValorProdutos, NULL, NULL);
  
            -- Inicializa a Base do ST em Percentual
            vnPercentualBaseSt := vnPercentualValorProdutos;
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Base do ST em Percentual = Valor dos Produtos em Percentual', vnPercentualValorProdutos, NULL, NULL);
  
            -- Soma o IVA na Base do ST em Percentual
            vnPercentualBaseSt := vnPercentualBaseSt + NVL(vnIVAFONTE,0);
  
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('+', 'Acresce o MVA em Percentual', vnPercentualBaseSt , NVL(vnIVAFONTE,0) , NULL, TRUE);
          
            -- Cálculo do Icms de Compra em Percentual
            vnPercentualValorIcmsCompra := NVL(vnPercentualBaseSt,0) * (p_ALIQICMS1FONTE / 100);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor do Icms Compra em Percentual = [Base do ST em Percentual x (Aliq. ICMS Compra ' || CHR(247) || ' 100)]', NULL, NULL, vnPercentualValorIcmsCompra);
          
            -- Cálculo do Valor do ST em Percentual
            vnPercentualValorSt := (NVL(vnPercentualValorIcmsCompra,0) - NVL(p_ALIQICMS2FONTE,0));
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor do ST em Percentual = (Valor do Icms Compra em Percentual - Aliq. ICMS Venda)', NULL, NULL, vnPercentualValorSt);
                                      
            -- Cálculo do Valor da Nota Fiscal em Percentual
            vnPercentualValorNotaFiscal := NVL(vnPercentualValorProdutos,0) + NVL(vnPercentualValorSt,0);                                      
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor Nota Fiscal em Percentual = (Valor dos Produtos em Percentual + Valor do ST em Percentual)', NULL, NULL, vnPercentualValorNotaFiscal);
          
            -- Cálculo do Valor dos Produtos sem Impostos
            p_valorprodutos := (NVL(p_valornotafiscal,0) / (NVL(vnPercentualValorNotaFiscal,0) / 100));
            p_valorprodutos := round(p_valorprodutos, p_numcasasdecvenda);   
             
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor Nota Fiscal em R$', NULL, NULL, p_valornotafiscal);
             
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Valor dos Produtos = [Valor NF em R$ ' || CHR(247) || ' (Valor NF em Percentual ' || CHR(247) || ' 100)]', NULL, NULL, p_valorprodutos);
          
           /*************
            ST DE RETORNO
            *************/
            vnstfonte :=  (NVL(p_valornotafiscal,0) - NVL(p_valorprodutos,0)) ;
  
            -- Retorno da Base do ST -- MED-1930    
            p_baseicst := (NVL(p_valorprodutos,0) * (1 + (NVL(vnIVAFONTE,0) / 100)));
            IF (NVL(vnpercbasered,0) > 0) THEN
              -- Compensar a Alíquota que foi reduzida
              p_baseicst := (NVL(p_baseicst,0) * (NVL(vnpercbasered,0) / 100)); 
            END IF;
    
    
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Valor do ST = (Valor NF - Valor Produtos)', NULL, NULL, vnstfonte);
            
            --Calcular ST - Truncar com 2 casas decimais
            IF p_tipocalcst = 'T2' THEN
              vnstfonte := trunc((vnstfonte) * 100) / 100;
            ELSIF p_tipocalcst = 'A2' THEN
              vnstfonte := round((vnstfonte) * 100) / 100;
            ELSIF p_tipocalcst = 'PV' THEN
              vnSTFONTE := round(vnSTFONTE, p_numcasasdecvenda);       
            END IF;
          
          END IF;              
                  
  
          -------------------------------------------------------------------------
          -- ST FECP - MED-1930
          -------------------------------------------------------------------------               
  
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Abater FECP do Valor ST Total ?', 'VL_FECP');                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Sim', 'VL_STRJINV', 'SIM_FECP');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Não', 'VL_STRJINV', 'NAO_FECP');   
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('VL_FECP', 'NAO_FECP'); -->> Default               
          
          IF (NVL(p_participafuncep,'S')  = 'S') AND
             (NVL(p_codconfigfuncepmed,0) >  0 ) AND
             (NVL(p_aliqicmsfecp,0)       >  0 ) THEN
            -- Calcula o ST FECP
            p_vlfecp := NVL(p_baseicst,0) * (NVL(p_aliqicmsfecp,0) / 100);
            IF (NVL(p_vlfecp,0) < 0) THEN
              p_vlfecp := 0;
            END IF;
            -- Arredondamento ST
            IF p_tipocalcst = 'T2' THEN
              p_vlfecp := trunc((p_vlfecp) * 100) / 100;
            ELSIF p_tipocalcst = 'A2' THEN
              p_vlfecp := round((p_vlfecp) * 100) / 100;
            ELSIF p_tipocalcst = 'PV' THEN
              p_vlfecp := round(p_vlfecp, p_numcasasdecvenda);       
            END IF;          
            -- Abate o FECP do ST
            vnSTFONTE := NVL(vnSTFONTE,0) - NVL(p_vlfecp,0); 
            IF (NVL(vnSTFONTE,0) < 0) THEN
              vnSTFONTE := 0;
            END IF;          
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('VL_FECP', 'SIM_FECP');
                                                                                                                                             
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Abater o Valor do FECP do ST Total', NULL, NULL, p_vlfecp);
                                                                                                                                                       
          ELSE        
            p_vlfecp := 0;
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('VL_FECP', 'NAO_FECP');
            
          END IF;
  
                  
          -------------------------------------------------------------------------
          -- PERCENTUAL BASE RJ - Priorização do Maior entre o Mínimo e o Calculado
          -------------------------------------------------------------------------
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('Calcular ST pelo Percentual Mínimo RJ ?', 'VL_STRJINV');                
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Sim', 'VL_STRJINV', 'SIM_STRJ');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Não', 'VL_STRJINV', 'NAO_STRJ');   
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('VL_STRJINV', 'NAO_STRJ'); -->> Default               
          
          -- Se Calcula ST MÍNIMO RJ
          IF (NVL(p_usavalorultentbasest,'N') = 'S') AND
             (NVL(p_percbasestrj,0) > 0)             THEN
  
            -- Base ST Mínimo Rj pelo Valor da Última Entrada
            vnBaseStRj := NVL(p_valorultent,0);
  
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('=', 'Valor Inicial da Base ST Mínimo RJ', vnBaseStRj);
                                                                          
            -- Agrega o MVA na Base do ST Mínimo Rj
            vnBaseStRj := (vnBaseStRj * (1 + (vnIVAFONTE / 100)));
                                      
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('+', 'MVA', vnBaseStRj, vnIVAFONTE, vnValorCalculadoMemoriaCalculo);                                      
          
            -- Redução ST Mínimo Rj
            vnPercBaseRedRj := NVL(vnpercbasered,0); 
            IF (NVL(vnPercBaseRedRj,0) = 0) THEN
              vnPercBaseRedRj := 100;
            END IF;
            
                                                                                                                                             -- Variáveis Auxiliares da Memória de Calculo
                                                                                                                                             vnPercMemoriaCalculo           := (100 - vnPercBaseRedRj);
                                                                                                                                             vnValorCalculadoMemoriaCalculo := (vnBaseStRj * (vnPercMemoriaCalculo / 100));
            
            -- Aplica Redução na Base do ST Rj
            vnBaseStRj := vnBaseStRj * (vnPercBaseRedRj / 100);
          
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('-', 'Redução de ' || vnPercBaseRedRj || '% na Base ST Mínimo', vnBaseStRj, vnPercMemoriaCalculo, vnValorCalculadoMemoriaCalculo);
          
            -- Calcula o Valor do ST RJ  
            vnValorStRj := vnBaseStRj * (NVL(p_percbasestrj,0) / 100);
            
            --Calcular ST - Truncar com 2 casas decimais
            IF p_tipocalcst = 'T2' THEN
              vnValorStRj := trunc((vnValorStRj) * 100) / 100;
            ELSIF p_tipocalcst = 'A2' THEN
              vnValorStRj := round((vnValorStRj) * 100) / 100;
            ELSIF p_tipocalcst = 'PV' THEN
              vnValorStRj := round(vnValorStRj, p_numcasasdecvenda);       
            END IF;          
            
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('>', 'Valor Mínimo ST RJ', NULL, p_percbasestrj, vnValorStRj);
                                                                               
                                                  
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('VL_STRJ', 'MIN_STRJ'); 
                                        
            -- Calcula o Valor dos Produtos pelo Mínimo
            vnValordosProdutosPeloStMin := NVL(p_valornotafiscal,0) - NVL(vnValorStRj,0);
            vnValordosProdutosPeloStMin := round(vnValordosProdutosPeloStMin, p_numcasasdecvenda);   
  
                                      
            -- Verifica o Maior ST para definir qual aplicar a Inversão
            IF (NVL(vnValorStRj,0) > NVL(vnstfonte,0)) THEN
  
             /*****************************************
              ALTERA ST DE RETORNO E VALOR DOS PRODUTOS
              *****************************************/
              vnstfonte := NVL(vnValorStRj,0);            
              p_valorprodutos := NVL(vnValordosProdutosPeloStMin,0);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Valor dos Produtos pelo ST Mínimo = (Valor NF - Valor ST Mínimo)', NULL, NULL, vnValordosProdutosPeloStMin);
  
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_INSERIR_MEMORIA_CALCULO('#', 'Substituição do Valor dos Produtos pelo calculado pelo ST Mínimo', NULL, NULL, p_valorprodutos);
              
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('VL_STRJINV', 'SIM_STRJ');
              
            END IF;
  
          END IF; -- Fim Condição: ST MÍNIMO RJ
          
        END IF; -- FIM CONDIÇÃO CALCULA VALOR DO ST
              
       /*--------------------------------------------------------------------------------------------
        Atualização de Retornos adicionais
        ---------------------------------*/
              
       /*--------------------------------------------------------------------------------------------
        Retornos Base e Valor do ST
        --------------------------*/
        RETURN vnstfonte;
        
      EXCEPTION
        WHEN OTHERS THEN
          p_mensagem := 'Erro ao calcular STfonte: ' || SQLCODE || '-' ||
                        SQLERRM;
          RETURN 0;
      END FCALCULARSTFONTE_INVERSO;  
  
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      -- FUNCTION PCALCULARFUNCEP
      -- Calcular ST do Funcep
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------------------------------
      PROCEDURE PCALCULARFUNCEP(p_codconfigfuncepmed           IN  NUMBER,
                                p_bcst                         IN  NUMBER,
                                p_pvenda                       IN  NUMBER,
                                p_observacaostfonte            IN OUT VARCHAR2, 
                                p_aliqicmsfecp                 IN  NUMBER, -- HIS.04200.2017
                                p_VLBASEFCPICMS                OUT NUMBER, -- HIS.04200.2017
                                p_VLBASEFCPST                  OUT NUMBER, -- HIS.04200.2017
                                p_VLBCFCPSTRET                 OUT NUMBER, -- HIS.04200.2017
                                p_PERFCPSTRET                  OUT NUMBER, -- HIS.04200.2017
                                p_PERFCPSN                     OUT NUMBER, -- HIS.04200.2017
                                p_VLFECP                       OUT NUMBER, -- HIS.04200.2017
                                p_VLACRESCIMOFUNCEP            OUT NUMBER, -- HIS.04200.2017
                                p_VLCREDFCPICMSSN              OUT NUMBER,
                                p_mensagem                     OUT VARCHAR2,
                                p_vlfreteoutrasdespbaseicms    IN  NUMBER, -- MED-2346
                                p_percbaseredicmsfecp          IN  NUMBER) -- MED-2346
      IS
             
        vnPercBaseRedIcmsNormal PCPEDI.PERCBASERED%TYPE; -- MED-2346
        vnBaseIcmsNormalFecp    NUMBER; -- MED-2346
        vnValorIcmsNormalFecp   NUMBER; -- MED-2346
             
      BEGIN
      
       /********************
        Inicializa Variáveis
        ********************/
      
                                                                                                                         -- Continuação da Observação ST Fonte
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',St.Funcep';
                        
       /*--------------------------------------------------------------------------------------------
        CÁLCULO DO ST FUNCEP
        -- * QUANDO NÃO TEM ST, ONDE CADASTRA o Percentual do Fundo de Combate à Pobreza (pFCP ) 
        -------------------*/
        IF (NVL(p_codconfigfuncepmed,0) > 0) THEN
          -- Fundo de Combate à Pobreza
          p_vlbasefcpicms      := 0; -- MED-656 - Será Calculado no Faturamento -- Valor da Base de Cálculo do FCP [vBCFCP]
          -->> p_peracrescimofuncep --> SERÁ USADO PARA GRAVAR O CAMPO Percentual do FCP retido por Substituição Tributária [pFCPST]
          p_vlacrescimofuncep  := 0; -- MED-656 - Será Calculado no Faturamento -- SERÁ USADO PARA GRAVAR O CAMPO Valor do Fundo de Combate à Pobreza (FCP) [vFCP]
    
          -- Simples Nacional
          p_perfcpsn           := 0;                                                              -- ??? Alíquota aplicável de cálculo do crédito (SIMPLES NACIONAL). [pCredSN]
          p_vlcredfcpicmssn    := 0;                                                              -- ??? Valor crédito do ICMS que pode ser aproveitado nos termos do art. 23 da LC 123 (SIMPLES NACIONAL) [vCredICMSSN]
    
         -- Retido anteriormente por ST 
          p_vlbcfcpstret       := 0;                                                              -- Valor da Base de Cálculo do FCP retido anteriormente [vBCFCPSTRet]
          p_perfcpstret        := 0;                                                              -- Percentual do FCP retido anteriormente por Substituição Tributária [pFCPSTRet]
          p_vlfcpstret         := 0;                                                              -- Valor do Fundo de Combate à Pobreza (FCP) [vFCP]             -- Valor Total do FCP retido anteriormente por Substituição Tributária [vFCPSTRet]
    
          -->> p_aliqicmsfecp -->> Percentual do FCP retido por Substituição Tributária [pFCPST]
    
          -- Retido por Substituição Tributária (CUIDADO QUE O NOME DAS COLUNAS NÃO CORRESPONDE AO NOME DAS TAGS POR REAPROVEITAMENTO DO OERACRESCIMOFUNCEP)
          -- Valor da Base de Cálculo do FCP retido por Substituição Tributária [vBCFCPST]        
          IF    (p_codconfigfuncepmed = 1) THEN
  
            p_vlbasefcpst       := p_bcst;                                                              
                                                                                                                         -- Observação ST Fonte
            -- Valor do FCP retido por Substituição Tributária [vFCPST]     
            p_vlfecp            := (NVL(p_vlbasefcpst,0) * (NVL(p_aliqicmsfecp,0) / 100));       
                                                                                                                         p_observacaostfonte := p_observacaostfonte || ',1-BaseSt';
          ELSIF (p_codconfigfuncepmed = 2) THEN
      
            p_vlbasefcpst       := p_pvenda;                                                              
      
            -- Valor do FCP retido por Substituição Tributária [vFCPST]     
            p_vlfecp            := (NVL(p_vlbasefcpst,0) * (NVL(p_aliqicmsfecp,0) / 100));       
                 
          -- MED-2346                                                                                                               -- Observação ST Fonte
          ELSIF (p_codconfigfuncepmed = 3) THEN
      
            p_vlbasefcpst         := p_bcst;                                                              
            
            -- Redução do ICMS Normal - MED-2346
            vnPercBaseRedIcmsNormal := NVL(p_percbaseredicmsfecp,0);
            IF (NVL(vnPercBaseRedIcmsNormal,0) = 0) THEN
              vnPercBaseRedIcmsNormal := 100;
          END IF;
            
            -- Base Icms Normal FECP - MED-2346
            vnBaseIcmsNormalFecp  := (NVL(p_pvenda,0) + NVL(p_vlfreteoutrasdespbaseicms,0));
            vnBaseIcmsNormalFecp  := (NVL(vnBaseIcmsNormalFecp,0) * (NVL(vnPercBaseRedIcmsNormal,0) / 100));
            
            -- Valor ICMS Normal FECP - MED-2346
            vnValorIcmsNormalFecp := (NVL(vnBaseIcmsNormalFecp,0) * (NVL(p_peracrescimofuncep,0) / 100));
            
            -- Valor do FCP retido por Substituição Tributária [vFCPST]     
            p_vlfecp              := (NVL(p_vlbasefcpst,0) * (NVL(p_aliqicmsfecp,0) / 100));       
          
            -- Retira o Valor do ICMS Normal do Valor do FCP retido por Substituição Tributária
            p_vlfecp              := NVL(p_vlfecp,0) - NVL(vnValorIcmsNormalFecp,0);
            IF (p_vlfecp < 0) THEN
              p_vlfecp := 0;
            END IF;
            
          END IF;
        
        END IF;
        
      EXCEPTION
        WHEN OTHERS THEN
          p_mensagem := 'Erro ao calcular ST Funcep: ' || SQLCODE || '-' ||
                        SQLERRM;
      END PCALCULARFUNCEP;  
      
    BEGIN
    
                                                                                                                                             -- Memória de Cálculo          
                                                                                                                                             IF (NVL(pi_vOrdemCalculo,'F') = 'F') THEN
                                                                                                                                               P_INSERE_OPCAO_MEMORIA_CALCULO('Calcular ST Fonte ?', 'CALCULARST');          
                                                                                                                                             ELSE
                                                                                                                                               P_INSERE_OPCAO_MEMORIA_CALCULO('Calcular ST Fonte INVERSO ?', 'CALCULARST'); -- (Não mexer no texto "Calcular ST Fonte INVERSO ?", é usado para pintar o grid)
                                                                                                                                             END IF;
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('1) Sim, calcular ST Fonte com tributação ' || NVL(pio_nCodSt,0), 'CALCULARST', 'SIM');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('2) Sem ST Fonte por Isenção Órgão Público (Cliente x Tributação)', 'CALCULARST', 'NAO_ORGAOPUB');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('3) Sem ST Fonte por Regime Especial de Isenção ST (Cliente x Tributação)', 'CALCULARST', 'NAO_ISENCAO');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('4) Sem ST Fonte por Fabricante não Relevenda (Produto)', 'CALCULARST', 'NAO_RELEVANTE');          
                                                                                                                                             P_INSERE_OPCAO_MEMORIA_CALCULO('5) Sem ST Fonte por Isenção para Bonificação (Tributação)', 'CALCULARST', 'NAO_ISEBNF'); -- MED-2521
    
      -- Iniciaiza Retornos com Regras da Tributação pra Gravação na PCPEDI                                          
      po_nAliqIcms1            := 0;
      po_nAliqIcms2            := 0;
      po_nIva                  := 0;
      po_nPercBaseRedStFonte   := 0;
    
      -- Atualiza variáveis locais que serão parâmetros de Entrada e Saída na FUNCOESVENDAS, 
      -- com valores passados nos Parâmetros de Entrada da Procedure
      n_ivafonte               := p_ivafonte;
      n_aliqicms1fonte         := p_aliqicms1fonte;
      n_aliqicms2fonte         := p_aliqicms2fonte;
      n_percbaseredstfonte     := p_percbaseredstfonte;
    
      -- Inicializa Retorno indicando como Padrão que não tem Isenção ST Fonte
      po_vRegimeEspIsenStFonte := 'N';
      
      -- Inicializa Variáveis de Cálculo do FUNCEP - HIS.04200.2017
      p_vlbasefcpicms          := 0;
      p_vlbasefcpst            := 0;
      p_vlbcfcpstret           := 0;
      p_perfcpstret            := 0;
      p_vlfcpstret             := 0;
      p_perfcpsn               := 0;
      p_vlfecp                 := 0;
      p_vlacrescimofuncep      := 0;
      p_vlcredfcpicmssn        := 0;    
      --
      po_nPerAcrescimoFuncep   := 0;    
      po_nAliqIcmsFecp         := 0;    
      po_nCodConfigFuncepMed   := NULL;
      
      -- Se Orgão Público e a Tributação tem Isenção de ST para Órgãos Públicos
      IF    ((NVL(p_tipoclimed, ' ') IN ('D','E','M')) AND  
             (NVL(p_isencaostorgaopub, ' ') = 'S')) THEN
    
        po_nBaseStFonte        := 0;
        po_nValorStFonte       := 0;
        po_nAliqIcms1          := 0;
        po_nAliqIcms2          := 0;
        po_nIva                := 0;
        po_nPercBaseRedStFonte := 0;
        po_vObservacaoStFonte  := 'Isenção Orgão Público';
               
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('CALCULARST', 'NAO_ORGAOPUB');                     
               
      -- Se Cliente Usa Regime Especial Isenção ST Fonte e
      -- Tributação com Regime Especial Isenção ST Fonte
      ELSIF ((NVL(p_usaregimeespisenstfonte,'N') = 'S') AND
             (NVL(p_regimeespisenstfonte,'N')    = 'S')) THEN
      
        po_nBaseStFonte          := 0;
        po_nValorStFonte         := 0;
        po_nAliqIcms1            := 0;
        po_nAliqIcms2            := 0;
        po_nIva                  := 0;
        po_nPercBaseRedStFonte   := 0;
        -- Atualiza Retorno indicando que vai aplicar Isenção ST Fonte
        po_vRegimeEspIsenStFonte := 'S';
        po_vObservacaoStFonte    := 'Regime Especial ST Fonte';
        
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('CALCULARST', 'NAO_ISENCAO');                     
        
      -- Fabricante NÃO RELEVANTE - HIS.03371.2017  
      ELSIF (NVL(p_indescalarelevante,'S') = 'N') THEN
  
        po_nBaseStFonte          := 0;
        po_nValorStFonte         := 0;
        po_nAliqIcms1            := 0;
        po_nAliqIcms2            := 0;
        po_nIva                  := 0;
        po_nPercBaseRedStFonte   := 0;
        po_vObservacaoStFonte    := 'Fabricante não Relevante';    
        
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('CALCULARST', 'NAO_RELEVANTE');                     
      
  
  
      -- MED-2521 - Isenção ST Bonificação
      ELSIF (NVL(p_isencaostfontebonificacao,'N') = 'S') AND
            ((NVL(p_itembonific,'N') IN ('S','F')) OR (NVL(pi_nCondVenda,0) = 5)) THEN -- DDMEDICA-198 - Incluído F
  
        po_nBaseStFonte          := 0;
        po_nValorStFonte         := 0;
        po_nAliqIcms1            := 0;
        po_nAliqIcms2            := 0;
        po_nIva                  := 0;
        po_nPercBaseRedStFonte   := 0;
        po_vObservacaoStFonte    := 'Isenção BNF';
  
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('CALCULARST', 'NAO_ISEBNF');
  
      ELSE     
  
                                                                                                                                             -- Memória de Cálculo
                                                                                                                                             P_ATU_OPCAO_MEMORIA_CALCULO('CALCULARST', 'SIM');                     
  
        ----------------------------------------------------
        -- Recebe o Preço de Venda sem Impostos do Parâmetro
        ----------------------------------------------------
        vnPrecoVendaSemImpostos := NVL(p_pvenda,0);
      
        --------------------------------------------------
        -- C Á L C U L O    I N V E R S O    D O    S T -- 
        --------------------------------------------------
        IF (pi_vOrdemCalculo = 'I') THEN
        
          -- Alíquota FECP para somar na Alíq 1 do ST Fonte - MED-1930
          IF (NVL(p_participafuncep,'S')  = 'S') AND
             (NVL(p_codconfigfuncepmed,0) >  0 ) AND
             (NVL(p_aliqicmsfecp,0)       >  0 ) THEN
            vnAliq1StFonteFecp := (NVL(n_aliqicms1fonte,0) + NVL(p_aliqicmsfecp,0));
          ELSE
            vnAliq1StFonteFecp := NVL(n_aliqicms1fonte,0); -- Regra anterior.
          END IF;
  
          -- Chama Função para Calcular a Base e Valor do ST Fonte
          po_nValorStFonte := FCALCULARSTFONTE_INVERSO(pi_nValorNotaFiscal         ,
                                                       p_codprod                   ,
                                                       p_condvenda                 ,
                                                       p_percvenda                 ,
                                                       p_iva                       ,
                                                       n_ivafonte                  , --> Variável local no parâmetro de Entrada e Saída
                                                       vnAliq1StFonteFecp          , -- MED-1930 --> Variável local no parâmetro de Entrada e Saída
                                                       n_aliqicms2fonte            , --> Variável local no parâmetro de Entrada e Saída
                                                       n_percbaseredstfonte        , --> Variável local no parâmetro de Entrada e Saída
                                                       p_percbaserednrpa           ,
                                                       p_percbaseredconsumidor     ,
                                                       p_utilizapercbaseredpf_trib ,
                                                       p_tipocalcst                ,
                                                       p_calcstpf                  ,
                                                       p_utilizapercbaseredpf      ,
                                                       p_clientefontest            ,
                                                       p_calculast                 ,
                                                       p_ieent                     ,
                                                       p_tipofj                    ,
                                                       p_isentoicms                ,
                                                       p_consumidorfinal           ,
                                                       p_utilizaiesimplificada     ,
                                                       p_tipoempresa               ,
                                                       p_consideraisentoscomopf    ,
                                                       p_vlipi                     ,
                                                       p_uffilial                  ,
                                                       p_estent                    ,
                                                       p_usavalorultentbasest      ,
                                                       p_valorultent               ,
                                                       p_usaivafontediferenciado   ,
                                                       p_ivafonte_cli              ,
                                                       p_AceitaPFContribuinte      ,
                                                       p_ALIQICMS1                 ,
                                                       p_ALIQICMS2                 ,
                                                       p_contribuinte              ,
                                                       p_numcasasdecvenda          ,
                                                       po_nBaseStFonte             , -- MED-1930
                                                       po_vMensagem                , --> Variável local no parâmetro de Saída
                                                       p_custonfsemst              ,
                                                       p_usavalorultentbasest2     ,
                                                       p_usapmcbasest              ,
                                                       p_precomaxconsum            ,
                                                       p_usabaseicmsreduzida       ,
                                                       p_usabcrultent              ,
                                                       p_basebcrultent             ,
                                                       p_stbcrultent               ,                                        
                                                       p_CALCSTPAUTAFARMACIAPOPULAR,
                                                       p_PAUTAFONTE                ,
                                                       p_FARMACIAPOPULAR           ,
                                                       p_PARTICIPAFARMACIAPOPULAR  , 
                                                       p_usaptabelabasest          ,
                                                       p_SomenteIVATribut          , -- [HIS.05161.2014] 
                                                       p_usadescsimplesnac         , -- [HIS.05161.2014] 
                                                       p_simplesnacional           , -- [HIS.05161.2014] 
                                                       p_percredpvendasimplesnac   , -- [HIS.05161.2014] 
                                                       p_tipomerc                  ,
                                                       p_usarajusteprecocmed       ,
                                                       p_percajusteprecocmed       ,
                                                       p_medretirarstbnfestadual   ,
                                                       p_itembonific               ,
                                                       p_vlfreteoutrasdesp         ,
                                                       p_bnfnaocalculaicms         ,
                                                       p_USAREGSIMPLCARGATRIBSTFONTE , -- HIS.03187.2015
                                                       p_REGSIMPLCARGATRIBSTFONTE    , -- HIS.03187.2015
                                                       p_PERCREGSIMPLCARGATRIBSTFONTE, -- HIS.03187.2015     
                                                       p_USAREDUTORCAT49BASESTFONTE  , -- 5661.146071.2016
                                                       p_PERCREDUTORCAT49BASESTFONTE , -- 5661.146071.2016                                                             
                                                       p_USACARGAMINIMADEFERIMSTFONTE, -- HIS.01277.2017
                                                       p_PERCARGAMINIMADEFERIMSTFONTE, -- HIS.01277.2017     
                                                       p_USAVLSTMAIORPERCMINPMC, -- DDVENDAS-40134
                                                       p_PERVLSTMAIORPERCMINPMC, -- DDVENDAS-40134
                                                       p_codfilialfaturamento,         -- HIS.03371.2017
                                                       p_USAREDICMNORMVENDASTFONTE,    -- MED-1080
                                                       p_PERCBASERED,                  -- MED-1080
                                                       p_percipivenda,
                                                       p_usavlultentmediobasest, 
                                                       p_percbasestrj,
                                                       p_vlultentmes,
                                                       vnPrecoVendaSemImpostos,
                                                       p_participafuncep,
                                                       p_codconfigfuncepmed,
                                                       p_aliqicmsfecp,
                                                       p_vlfecp,
                                                       p_usapmpfbasest,
                                                       p_pmpf,
                                                       po_nPmPf
                                                       );                          
              
        ------------------------------------------------
        -- C Á L C U L O    P A D R Ã O    D O    S T -- 
        ------------------------------------------------   
        ELSE
            
          -- Chama Função para Calcular a Base e Valor do ST Fonte
          po_nValorStFonte := FCALCULARSTFONTE(p_codprod                   ,
                                               p_condvenda                 ,
                                               p_percvenda                 ,
                                               p_iva                       ,
                                               n_ivafonte                  , --> Variável local no parâmetro de Entrada e Saída
                                               n_aliqicms1fonte            , --> Variável local no parâmetro de Entrada e Saída
                                               n_aliqicms2fonte            , --> Variável local no parâmetro de Entrada e Saída
                                               n_percbaseredstfonte        , --> Variável local no parâmetro de Entrada e Saída
                                               p_percbaserednrpa           ,
                                               p_percbaseredconsumidor     ,
                                               p_utilizapercbaseredpf_trib ,
                                               p_tipocalcst                ,
                                               p_calcstpf                  ,
                                               p_utilizapercbaseredpf      ,
                                               p_clientefontest            ,
                                               p_calculast                 ,
                                               p_ieent                     ,
                                               p_tipofj                    ,
                                               p_isentoicms                ,
                                               p_consumidorfinal           ,
                                               p_utilizaiesimplificada     ,
                                               p_tipoempresa               ,
                                               p_consideraisentoscomopf    ,
                                               vnPrecoVendaSemImpostos     , -->> PASSA O PREÇO DE VENDA SEM IMPOSTOS
                                               p_vlipi                     ,
                                               p_uffilial                  ,
                                               p_estent                    ,
                                               p_usavalorultentbasest      ,
                                               p_valorultent               ,
                                               p_usaivafontediferenciado   ,
                                               p_ivafonte_cli              ,
                                               p_AceitaPFContribuinte      ,
                                               p_ALIQICMS1                 ,
                                               p_ALIQICMS2                 ,
                                               p_contribuinte              ,
                                               p_numcasasdecvenda          ,
                                               po_nBaseStFonte             , -->> BASE ST FONTE QUE SERA RETORNADA PELA PROCEDURE
                                               vnPercBaseRedStFonteAlterado, -->> SE A LEGISLAÇÃO MUDAR O % DE REDUÇÃO DO CADASTRO - 5661.146071.2016
                                               po_vMensagem                , --> Variável local no parâmetro de Saída
                                               p_custonfsemst              ,
                                               p_usavalorultentbasest2     ,
                                               p_usapmcbasest              ,
                                               p_precomaxconsum            ,
                                               p_usabaseicmsreduzida       ,
                                               p_usabcrultent              ,
                                               p_basebcrultent             ,
                                               p_stbcrultent               ,                                        
                                               p_CALCSTPAUTAFARMACIAPOPULAR,
                                               p_PAUTAFONTE                ,
                                               p_FARMACIAPOPULAR           ,
                                               p_PARTICIPAFARMACIAPOPULAR  , 
                                               p_usaptabelabasest          ,
                                               p_ptabela                   ,
                                               p_SomenteIVATribut          ,
                                               p_usadescsimplesnac         ,
                                               p_simplesnacional           ,
                                               p_percredpvendasimplesnac   ,
                                               p_tipomerc                  ,
                                               p_usarajusteprecocmed       ,
                                               p_percajusteprecocmed       ,
                                               p_medretirarstbnfestadual   ,
                                               p_itembonific               ,
                                               p_vlfreteoutrasdesp         ,
                                               p_bnfnaocalculaicms         ,
                                               p_USAREGSIMPLCARGATRIBSTFONTE ,
                                               p_REGSIMPLCARGATRIBSTFONTE    ,
                                               p_PERCREGSIMPLCARGATRIBSTFONTE,
                                               p_USAREDUTORCAT49BASESTFONTE  ,
                                               p_PERCREDUTORCAT49BASESTFONTE ,
                                               p_USACARGAMINIMADEFERIMSTFONTE,
                                               p_PERCARGAMINIMADEFERIMSTFONTE,
                                               p_USAVLSTMAIORPERCMINPMC,
                                               p_PERVLSTMAIORPERCMINPMC,											   
                                               p_pautafonteaplicado,
                                               po_vObservacaoStFonte,
                                               p_codfilialfaturamento,
                                               p_USAREDICMNORMVENDASTFONTE,
                                               p_PERCBASERED,
                                               p_percipivenda,
                                               p_usavlultentmediobasest, 
                                               p_percbasestrj,
                                               p_vlultentmes,
                                               vnRetVlFreteOutrasDespBaseSt,
                                               vnRetPercBaseRedIcmsFecp,
                                               v_usaReducaoBasePmc,
                                               v_pertetoredbasepmc,
                                               p_usapmpfbasest,
                                               p_pmpf,
                                               p_agregapiscofinsst1,
                                               p_agregasuframast1,
                                               p_agregaicmsisencaost1,
                                               p_agregapiscofinsst2,
                                               p_agregasuframast2,
                                               p_agregaicmsisencaost2,
                                               p_vldescreducaopis,
                                               p_vldescreducaocofins,
                                               p_vldescicmisencao,
                                               p_vldescsuframa,
                                               vvRetEnquadraIcmsSubstAnterior,
                                               vnRetVlIcmsSubstitutoAnterior,
                                               po_nPmPf);
  
          -- Regras da Tributação pra Gravação na PCPEDI
          po_nAliqIcms1          := n_aliqicms1fonte;
          po_nAliqIcms2          := n_aliqicms2fonte;
          po_nIva                := n_ivafonte;
          po_nPercBaseRedStFonte := n_percbaseredstfonte;
          po_nPautaFonte         := p_pautafonteaplicado;
                            
          -->> SE A LEGISLAÇÃO MUDAR O % DE REDUÇÃO DO CADASTRO
          IF (vnPercBaseRedStFonteAlterado IS NOT NULL) THEN
            IF (p_USAREDUTORCAT49BASESTFONTE = 'S') THEN
              po_nPercBaseRedStFonte := vnPercBaseRedStFonteAlterado;
              po_vObservacaoStFonte  := po_vObservacaoStFonte || ',Red.Cat49';
            END IF;
          END IF;
          
          -- Se não houve erro no Cálculo do ST
          IF (po_vMensagem IS NULL) THEN
          
            -- FUNCEP com Fórmula com Motor de Cálculo
            IF (NVL(p_participafuncep,'S')  = 'S') AND
               (NVL(p_clientefontest,'N')   = 'S') AND
               (NVL(p_codconfigfuncepmed,0) >  0 ) AND
               (NVL(p_aliqicmsfecp,0)       >  0 ) THEN
            
              -- Chama Procedimento para Calcular os Valores do FUNCEP
              PCALCULARFUNCEP(p_codconfigfuncepmed,
                              po_nBaseStFonte,
                              vnPrecoVendaSemImpostos, -->> PASSA O PREÇO DE VENDA SEM IMPOSTOS
                              po_vObservacaoStFonte, 
                              p_aliqicmsfecp,
                              p_vlbasefcpicms,
                              p_vlbasefcpst,
                              p_vlbcfcpstret,
                              p_perfcpstret,
                              p_perfcpsn,
                              p_vlfecp,
                              p_vlacrescimofuncep,
                              p_vlcredfcpicmssn,
                              po_vMensagem,
                              vnRetVlFreteOutrasDespBaseSt,
                              vnRetPercBaseRedIcmsFecp); 
    
              -- Atualiza Variáveis de Cálculo do FUNCEP - HIS.04200.2017
              po_nPerAcrescimoFuncep := 0; -- MED-656 ->> Percentual de ICMS do FUNCEP - Ficou sendo gravado no Faturamento, junto com a Base e Valor do ICMS o FUNCEP
              IF (NVL(p_vlbasefcpst,0) = 0) THEN
                po_nAliqIcmsFecp     := 0; -->> Se não tiver base não vai ter alíquota do ST do Funcep MED-1471
              ELSE
                po_nAliqIcmsFecp     := p_aliqicmsfecp;
              END IF;            
              po_nCodConfigFuncepMed := p_codconfigfuncepmed;                                             
                                                          
            END IF; -- Fim Condição: FUNCEP com Fórmula com Motor de Cálculo
            
          END IF; -- Fim Condição: Se não houve erro no Cálculo do ST
          
          ----------------------------------
          -- CÁLCULO ST GNRE - DDMEDICA-7697
          ----------------------------------
          IF (NVL(v_tipocalculognre,'P') = 'C') THEN
          
            -- ST CLIENTE GNRE
            po_nStClienteGnre            := po_nValorStFonte;
            -- Sem ST Próprio
            po_nBaseStFonte              := 0;
            po_nValorStFonte             := 0;
            po_nAliqIcms1                := 0;
            po_nAliqIcms2                := 0;
            po_nIva                      := 0;
            po_nPercBaseRedStFonte       := 0;
            -- Sem ST Antecipado
            po_nBcStRetAnterior          := 0;
            po_nVlIcmsSubstitutoAnterior := 0;
            po_nVlIcmsStRetAnterior      := 0;
          
            po_vObservacaoStFonte := po_vObservacaoStFonte || ',STGnre';
          
          ---------------------------------------------------
          -- ST Recolhido Anteriormente (Ajuste SINIEF 01/94)
          ---------------------------------------------------
          ELSIF (NVL(v_destacicmsstanterior,'N') = 'S') THEN
          
            -- Enquadrado no Cálculo do ST Padrão
            IF (NVL(vvRetEnquadraIcmsSubstAnterior,'N') = 'S') THEN
  
              -- Os valores calculados de ST serão gravados em campos separados          
              po_nBcStRetAnterior          := po_nBaseStFonte;
              po_nVlIcmsSubstitutoAnterior := vnRetVlIcmsSubstitutoAnterior;
              po_nVlIcmsStRetAnterior      := po_nValorStFonte;
              
              -- Serão zerados os valores calculados de ST
              po_nBaseStFonte              := 0;
              po_nValorStFonte             := 0;
              po_nAliqIcms1                := 0;
              po_nAliqIcms2                := 0;
              po_nIva                      := 0;
              po_nPercBaseRedStFonte       := 0;
              po_vObservacaoStFonte        := po_vObservacaoStFonte || ',StRecolhidoAnt';
              
            -- Não está enquadrado no ST Padrão (Possui uma Exceção à Regra)
            ELSE
            
              po_vObservacaoStFonte        := po_vObservacaoStFonte || ',ExcStRecAnt';
              
            END IF;
            
          END IF;
  
        END IF; -- Fim Condição - Cálculo Inverso do ST
                                                                                 
      END IF;
    
    EXCEPTION
      WHEN OTHERS THEN  
        -- Sem ST
        po_nBaseStFonte  := 0;
        po_nValorStFonte := 0;
        po_vMensagem     := 'Erro cálculo ST Fonte: ' || SUBSTR('Erro: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM,1,240);
    END P_OBTER_STFONTE;
  
   /***************************************************************************
    ***************************************************************************
    **                  INICIO DO PROCESSAMENTO PRINCIPAL                    **
    ***************************************************************************                  
    ***************************************************************************/
  BEGIN
  
    -- Inicializa Retornos
    po_nBaseStFonte    := 0;
    po_nValorStFonte   := 0;
    po_vMensagem       := NULL;
    po_vClienteFonteSt := 'N';
  
   /****************************
    Inicializa Tabela Temporária
    ****************************/
  
    -- Limpa Tabela Temporaria de Memoria de Cálculo
    IF (pi_vMemoriaCalculo = 'S') THEN
      DELETE FROM PCMED_MEMORIA_CALCULO_ST
       WHERE (CODPROD <> pi_nCodProd)
         AND (SUBSTR(ORIGEM,1,1) = 'S');
      DELETE FROM PCMED_MEMORIA_CALCULO_ST
       WHERE (ORIGEM = ('S'||pi_vOrdemCalculo));
    END IF;
  
   /************************************************
    Código da Filial de Faturamento - HIS.03371.2017
    ************************************************/
    vvCodFilialFaturamento := NVL(pi_nCodFilialNf,pi_vCodFilial);
  
   /*******************
    Pesquisa Parâmetros
    *******************/
    BEGIN
      SELECT TIPOCALCST
           , CALCSTFONTEPF
           , CALCSTPF
           , NVL(UTILIZAPERCBASEREDPF,'N') UTILIZAPERCBASEREDPF
           , CONSIDERAISENTOSCOMOPF
           , ACEITAPFCONTRIBUINTE
           , NVL(NUMCASASDECVENDA,2) NUMCASASDECVENDA
           , NVL(USATRIBUTACAOPORUF,'N') USATRIBUTACAOPORUF
           , TIPOCALCSULFRAMA -- DDMEDICA-7594
        INTO v_tipocalcst
           , v_calcstfontepf
           , v_calcstpf
           , v_utilizapercbaseredpf_param
           , v_consideraisentoscomopf
           , v_AceitaPFContribuinte
           , v_numcasasdecvenda
           , v_usatributacaoporuf
           , v_tipocalcsulframa -- DDMEDICA-7594
        FROM PCCONSUM;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        po_vMensagem := 'Não foram encontrados dados na PCCONSUM';
        RAISE e_tratado;
    END;
    --
    BEGIN
      SELECT NVL(VALOR,'N') VALOR
        INTO v_calcstpautafarmaciapopular
        FROM PCPARAMFILIAL
       WHERE (CODFILIAL = '99')
         AND (NOME      = 'CALCSTPAUTAFARMACIAPOPULAR');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_calcstpautafarmaciapopular := 'N';
    END;         
    --
    BEGIN
      SELECT NVL(VALOR,'S') VALOR
        INTO v_usadescsimplesnac
        FROM PCPARAMFILIAL
       WHERE (CODFILIAL = vvCodFilialFaturamento) -- HIS.03371.2017
         AND (NOME      = 'USADESCSIMPLESNAC');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_usadescsimplesnac := 'N';
    END;
    --
    BEGIN
      SELECT NVL(VALOR,'N') VALOR
        INTO v_medretirarstbnfestadual
        FROM PCPARAMFILIAL
       WHERE (CODFILIAL = vvCodFilialFaturamento) -- HIS.03371.2017
         AND (NOME      = 'MEDRETIRARSTBNFESTADUAL');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_medretirarstbnfestadual := 'N';
    END;
    
    BEGIN
      SELECT NVL(VALOR,'N') VALOR
        INTO v_medcalcularstpelopeps
        FROM PCPARAMFILIAL
       WHERE (CODFILIAL = vvCodFilialFaturamento) -- HIS.03371.2017
         AND (NOME      = 'MEDCALCULARSTPELOPEPS');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_medcalcularstpelopeps := 'N';
    END;
    
   /*************************
    Pesquisa Dados do Cliente
    *************************/
    BEGIN
      SELECT ESTENT
           , CODPRACA      
           , NVL(CLIENTEFONTEST,'N') CLIENTEFONTEST   
           , NVL(CALCULAST,'S') CALCULAST
           , UPPER(IEENT) IEENT
           , TIPOFJ
           , NVL(ISENTOICMS,'N') ISENTOICMS
           , CONSUMIDORFINAL
           , NVL(UTILIZAIESIMPLIFICADA,'N') UTILIZAIESIMPLIFICADA
           , TIPOEMPRESA
           , NVL(USAIVAFONTEDIFERENCIADO,'N') USAIVAFONTEDIFERENCIADO
           , NVL(IVAFONTE,0) IVAFONTE_CLI
           , NVL(CONTRIBUINTE,'S') CONTRIBUINTE
           , TIPOCLIMED
           , PARTICIPAFARMACIAPOPULAR
           , SIMPLESNACIONAL -- [HIS.05161.2014]
           , NVL(USAREGIMEESPISENSTFONTE,'N')  
           , NVL(USAREGSIMPLCARGATRIBSTFONTE,'N') -- HIS.03187.2015 
           , NVL(PCCLIENT.PARTICIPAFUNCEP,'N') -- HIS.04200.2017
           -- DDMEDICA-7594
           , PCCLIENT.SULFRAMA
           , PCCLIENT.ORGAOPUB
           , PCCLIENT.ORGAOPUBFEDERAL
           , PCCLIENT.ORGAOPUBMUNICIPAL
           , PCCLIENT.TIPODESCISENCAO
           , PCCLIENT.PERDESCISENTOICMS
        INTO v_estent
           , v_codpraca
           , v_clientefontest
           , v_calculast
           , v_ieent
           , v_tipofj
           , v_isentoicms
           , v_consumidorfinal
           , v_utilizaiesimplificada
           , v_tipoempresa
           , v_usaivafontediferenciado
           , v_ivafonte_cli
           , v_contribuinte
           , v_tipoclimed
           , v_participafarmaciapopular
           , v_simplesnacional -- [HIS.05161.2014]
           , v_usaregimeespisenstfonte
           , vUSAREGSIMPLCARGATRIBSTFONTE -- HIS.03187.2015 
           , v_participafuncep -- HIS.04200.2017
           -- DDMEDICA-7594
           , v_sulframa
           , v_orgaopub
           , v_orgaopubfederal
           , v_orgaopubmunicipal           
           , v_tipodescisencao           
           , v_perdescisentoicms
        FROM PCCLIENT
       WHERE (CODCLI = pi_nCodCli);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        po_vMensagem := 'Não foram encontrados dados do Cliente ' || NVL(pi_nCodCli,0);
        RAISE e_tratado;
    END;
  
   /************************************
    Pesquisa Dados do Cliente por Filial
    ************************************/
    BEGIN
      SELECT NVL(PCCLIENTFILIALMED.CLIENTEFONTEST,'N')
        INTO v_clientefontest
        FROM PCCLIENTFILIALMED
       WHERE (PCCLIENTFILIALMED.CODCLI    = pi_nCodCli)
         AND (PCCLIENTFILIALMED.CODFILIAL = vvCodFilialFaturamento); -- HIS.03371.2017
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -->> Se não encontrar exceção por Filial, Mantém os valores da PCCLIENT
        NULL;
    END;
    
   /*************************************************
    Retornará se o Cliente é ST Fonte - DDMEDICA-7697
    *************************************************/
    po_vClienteFonteSt := v_clientefontest; 
  
   /************************
    Pesquisa Dados da Filial
    ************************/
    BEGIN
      SELECT UF
           , DTULTPROCESSAMENTOPEPS 
        INTO v_uffilial
           , v_dtultprocessamentopeps
        FROM PCFILIAL
       WHERE (CODIGO = vvCodFilialFaturamento); -- HIS.03371.2017
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        po_vMensagem := 'Não foram encontrados dados para a Filial: ' || NVL(vvCodFilialFaturamento,' '); -- HIS.03371.2017
        RAISE e_tratado;
    END;
  
   /*************************
    Pesquisa Dados do Produto
    *************************/
    BEGIN
      SELECT FARMACIAPOPULAR
           , TIPOMERC
           , PERCIPIVENDA
        INTO v_farmaciapopular
           , v_tipomerc
           , v_percipivenda
        FROM PCPRODUT
       WHERE (CODPROD = pi_nCodProd);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_farmaciapopular := 'N';
        v_tipomerc        := ' ';
        v_percipivenda    := NULL;
    END;
  
   /*****************************************************
    Pesquisa Dados do Produto por Filial - HIS.03371.2017
    *****************************************************/
    BEGIN
      SELECT NVL(PCPRODFILIAL.INDESCALARELEVANTE,'S') -->> PADRÃO SIM PARA CALCULAR ST (INDUSTRIA FARMACEUTICA RELEVANTE)
           , PCPRODFILIAL.CNPJFABRICANTE 
           , PCPRODFILIAL.FABRICANTE 
        INTO po_vIndEscalaRelevante
           , po_vCnpjFabricante
           , po_vFabricante
        FROM PCPRODFILIAL
       WHERE (CODPROD   = pi_nCodProd)
         AND (CODFILIAL = vvCodFilialFaturamento); -- HIS.03371.2017
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        po_vIndEscalaRelevante := 'S'; -->> PADRÃO SIM PARA CALCULAR ST (INDUSTRIA FARMACEUTICA RELEVANTE)
        po_vCnpjFabricante     := NULL;
        po_vFabricante         := NULL;
    END;
    
   /*******************
    Pesquisa Tributação
    *******************/
    
    -- Pega a Região do Parâmetro
    v_numregiao := pi_nNumRegiao;
    
    -- Se NÃO passou a Tributação do Parâmetro
    IF (NVL(pio_nCodSt,0) = 0) THEN
      
      ---------------------------
      -- Se usa Tributação por UF
      ---------------------------
      IF (NVL(v_usatributacaoporuf,'N') = 'S') THEN
      
        -- Pesquisa Tributação por UF
        BEGIN
          SELECT CODST
            INTO pio_nCodSt
            FROM PCTABTRIB
           WHERE (CODPROD     = pi_nCodProd)
             AND (UFDESTINO   = v_estent)
             AND (CODFILIALNF = vvCodFilialFaturamento); -- HIS.03371.2017
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            po_vMensagem := 'Não foi encontrada Tributação para o Produto ' || NVL(pi_nCodProd,0) || ', UF Destino [' || NVL(v_estent,' ') || '] e UF Filial [' || NVL(v_uffilial,' ' ||']');
            RAISE e_tratado;
        END;
            
      -------------------------------
      -- Se NÃO usa Tributação por UF
      -------------------------------
      ELSE
      
        -- Se passou a Região no Parâmetro
        IF (NVL(pi_nNumRegiao,0) > 0) THEN
        
          v_numregiao := pi_nNumRegiao;
          
        -- Se NÃO passou a Região no Parâmetro
        ELSE
      
          -- Pesquisa Região do Cliente por Filial
          BEGIN
            SELECT NUMREGIAO
              INTO v_numregiao
              FROM PCTABPRCLI
             WHERE (CODCLI      = pi_nCodCli)
               AND (CODFILIALNF = vvCodFilialFaturamento); -- HIS.03371.2017
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_numregiao := NULL;
          END;
        
          -- Se não achou Regiao do Cliente por Filial
          IF (v_numregiao IS NULL) THEN
            -- Pesquisa Região da Praça
            BEGIN
              SELECT NUMREGIAO
                INTO v_numregiao
                FROM PCPRACA
               WHERE (CODPRACA = v_codpraca);
            EXCEPTION
             WHEN NO_DATA_FOUND THEN
                v_numregiao := NULL;
            END;
          END IF;
          
        END IF; -- Fim Condição Se passou a Região no Parâmetro        
      
        -- Pesquisa Tributação por Região
        BEGIN
          SELECT CODST
            INTO pio_nCodSt
            FROM PCTABPR
           WHERE (CODPROD   = pi_nCodProd)
             AND (NUMREGIAO = v_numregiao);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            po_vMensagem := 'Não foi encontrada Tributação para o Produto ' || NVL(pi_nCodProd,0) || ' e Região ' || NVL(v_numregiao,0);
            RAISE e_tratado;
        END;
          
      END IF; -- Fim Condição v_usatributacaoporuf
      
    END IF; -- Fim Condição Se passou a Tributação do Parâmetro
  
   /***********************************
    Pesquisa Preço Máximo do Consumidor
    ***********************************/
    
    -- Se passou o Preço Máximo do Consumidor no Parâmetro
    IF (NVL(pi_nPrecoMaxConsum,0) > 0) THEN
  
      -- Pega valor do parâmetro  
      v_precomaxconsum := NVL(pi_nPrecoMaxConsum,0);
      
    -- NÃO passou o Preço Máximo do Consumidor no Parâmetro
    ELSE
  
      -------------------
      -- Obtem PMC por UF
      -------------------
      P_OBTEM_PMC_PRODUTO(vvCodFilialFaturamento, -- HIS.03371.2017
                          pi_nCodProd,
                          v_estent,
                          pi_nNumRegiao,
                          v_precomaxconsum,
                          v_precofabrica,
                          vvMensagemPmc,
                          pi_nCodCli);
      IF (vvMensagemPmc IS NOT NULL) THEN
        po_vMensagem := vvMensagemPmc; 
        RAISE e_tratado;
      END IF;                              
  
    END IF; -- Fim Condição Se passou o Preço Máximo do Consumidor no Parâmetro
      
   /*************************
    Pesquisa Valores da PCEST
    *************************/
    
    -- Se passou dados da PCEST no parâmetro
    --IF (pi_nValorUltEnt  IS NOT NULL) AND
    --   (pi_nCustoNfSemSt IS NOT NULL) THEN
    --   
    --  -- Pega Valores do Parâmetro  
    --  v_valorultent  := NVL(pi_nValorUltEnt,0);   
    --  v_custonfsemst := NVL(pi_nCustoNfSemSt,0);   
    --   
    -- Se NÃO passou dados da PCEST no parâmetro
    --ELSE 
    
      -- Pesquisa Dados da PCEST
      BEGIN
        SELECT VALORULTENT
             , CUSTONFSEMST
             , BASEBCR
             , STBCR
          INTO v_valorultent
             , v_custonfsemst
             , n_basebcrultent
             , n_stbcrultent
          FROM PCEST
         WHERE (CODFILIAL = vvCodFilialFaturamento) -- HIS.03371.2017
           AND (CODPROD   = pi_nCodProd);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_valorultent   := 0; 
          v_custonfsemst  := 0;
          n_basebcrultent := 0;
          n_stbcrultent   := 0;
      END;
      
    --END IF; -- Fim Condição Se passou dados da PCEST no parâmetro     
    
   /****************************
    Pesquisa dados da Tributação
    ****************************/
    BEGIN
      SELECT IVA
           , NVL(IVAFONTE,0) IVAFONTE
           , NVL(ALIQICMS1FONTE,0) ALIQICMS1FONTE
           , NVL(ALIQICMS2FONTE,0) ALIQICMS2FONTE
           , NVL(PERCBASEREDSTFONTE,0) PERCBASEREDSTFONTE
           , NVL(PERBASEREDNRPA,0) PERBASEREDNRPA
           , NVL(PERCBASEREDCONSUMIDOR,0) PERCBASEREDCONSUMIDOR
           , NVL(UTILIZAPERCBASEREDPF,'N') UTILIZAPERCBASEREDPF
           , NVL(USAVALORULTENTBASEST,'N') USAVALORULTENTBASEST
           , NVL(ALIQICMS1,0) ALIQICMS1
           , NVL(ALIQICMS2,0) ALIQICMS2
           , NVL(USAVALORULTENTBASEST2, 'N') USAVALORULTENTBASEST2
           , NVL(USAPMCBASEST,'N') USAPMCBASEST
           , ISENCAOSTORGAOPUB
           , USABASEICMSREDUZIDA
           , USABCRULTENT
           , NVL(PAUTAFONTE,0) PAUTAFONTE         
           , USAPTABELABASEST  
           , NVL(PERCREDPVENDASIMPLESNAC,0) PERCREDPVENDASIMPLESNAC
           , NVL(PCTRIBUT.USARAJUSTEPRECOCMED,'N') USARAJUSTEPRECOCMED
           , NVL(PCTRIBUT.PERCAJUSTEPRECOCMED,0) PERCAJUSTEPRECOCMED
           , NVL(PCTRIBUT.REGIMEESPISENSTFONTE,'N') REGIMEESPISENSTFONTE         
           , NVL(PCTRIBUT.BNFNAOCALCULAICMS,'N') BNFNAOCALCULAICMS
           , NVL(PCTRIBUT.PERCBASEREDST,0) PERCBASEREDST
           , NVL(PCTRIBUT.REGSIMPLCARGATRIBSTFONTE,'N') REGSIMPLCARGATRIBSTFONTE
           , NVL(PCTRIBUT.PERCREGSIMPLCARGATRIBSTFONTE,0) PERCREGSIMPLCARGATRIBSTFONTE
           , NVL(PCTRIBUT.USAREGRADIFSTFONTETV10,'N') USAREGRADIFSTFONTETV10
           , PCTRIBUT.USAREDUTORCAT49BASESTFONTE
           , PCTRIBUT.PERCREDUTORCAT49BASESTFONTE
           , PCTRIBUT.USACARGAMINIMADEFERIMSTFONTE
           , PCTRIBUT.PERCARGAMINIMADEFERIMSTFONTE
           , PCTRIBUT.USAVLSTMAIORPERCMINPMC
           , PCTRIBUT.PERVLSTMAIORPERCMINPMC
           , PCTRIBUT.UTILIZAMOTORCALCULO
           , PCTRIBUT.FORMULAPVENDA
           , PCTRIBUT.PERACRESCIMOFUNCEP
           , PCTRIBUT.ALIQICMSFECP
           , PCTRIBUT.CODCONFIGFUNCEPMED           
           , NVL(PCTRIBUT.USAREDICMNORMVENDASTFONTE,'N') USAREDICMNORMVENDASTFONTE
           , NVL(PCTRIBUT.PERCBASERED,0)                 PERCBASERED
           , NVL(PCTRIBUT.USAVLULTENTMEDIOBASEST,'N')
           , PCTRIBUT.PERCBASESTRJ,
             PCTRIBUT.USAREDUCAOBASEPMC,
             PCTRIBUT.PERTETOREDBASEPMC
           , NVL(PCTRIBUT.ISENCAOSTFONTEBONIFICACAO,'N')
           , PCTRIBUT.PERCBASEREDST_MC
           , PCTRIBUT.IVA_MC
           , PCTRIBUT.PAUTA_MC    
           , PCTRIBUT.ALIQICMS1_MC      
           , PCTRIBUT.ALIQICMS2_MC 
           , PCTRIBUT.USARABAPERDASTFONTEPEDAVARIA
           , NVL(USAPMPFBASEST,'N') USAPMPFBASEST
           , PCTRIBUT.AGREGAPISCOFINSST1
           , PCTRIBUT.AGREGASUFRAMAST1
           , PCTRIBUT.AGREGAICMSISENCAOST1
           , PCTRIBUT.AGREGAPISCOFINSST2   
           , PCTRIBUT.AGREGASUFRAMAST2
           , PCTRIBUT.AGREGAICMSISENCAOST2
           , PCTRIBUT.PERDESCSUFRAMA
           , PCTRIBUT.PERDESCPISSUFRAMA
           , PCTRIBUT.PERCDESCPIS
           , PCTRIBUT.PERCDESCCOFINS
           , PCTRIBUT.PERDESCICMISENCAO
           , PCTRIBUT.APLICADESCISENCAOMED           
           , PCTRIBUT.DESTACDESCICMISENCAOCOMERCIAL
           , NVL(PCTRIBUT.DESTACICMSSTANTERIOR,'N')
           , NVL(PCTRIBUT.TIPOCALCULOGNRE,'P')
        INTO v_iva
           , v_ivafonte
           , v_aliqicms1fonte
           , v_aliqicms2fonte
           , v_percbaseredstfonte
           , v_percbaserednrpa
           , v_percbaseredconsumidor
           , v_utilizapercbaseredpf_trib
           , v_usavalorultentbasest
           , v_ALIQICMS1
           , v_ALIQICMS2
           , v_usavalorultentbasest2
           , v_usapmcbasest
           , v_isencaostorgaopub
           , v_usabaseicmsreduzida
           , v_usabcrultent
           , n_pautafonte
           , v_usaptabelabasest  
           , n_percredpvendasimplesnac
           , v_usarajusteprecocmed
           , n_percajusteprecocmed         
           , v_regimeespisenstfonte
           , v_bnfnaocalculaicms
           , v_percbaseredst
           , vREGSIMPLCARGATRIBSTFONTE
           , nPERCREGSIMPLCARGATRIBSTFONTE
           , vUSAREGRADIFSTFONTETV10
           , vUSAREDUTORCAT49BASESTFONTE
           , nPERCREDUTORCAT49BASESTFONTE
           , vUSACARGAMINIMADEFERIMSTFONTE
           , nPERCARGAMINIMADEFERIMSTFONTE
           , vUSAVLSTMAIORPERCMINPMC
           , nPERVLSTMAIORPERCMINPMC		   
           , v_utilizamotorcalculo
           , v_formulapvenda
           , v_peracrescimofuncep
           , v_aliqicmsfecp
           , v_codconfigfuncepmed
           , vUSAREDICMNORMVENDASTFONTE
           , vPERCBASERED
           , v_usavlultentmediobasest
           , n_percbasestrj
           , v_usaReducaoBasePmc
           , v_pertetoredbasepmc
           , v_isencaostfontebonificacao
           , v_percbaseredst_mc
           , v_iva_mc
           , v_pauta_mc    
           , v_aliqicms1_mc      
           , v_aliqicms2_mc 
           , vUSARABAPERDASTFONTEPEDAVARIA           
           , v_usapmpfbasest
           , v_agregapiscofinsst1
           , v_agregasuframast1
           , v_agregaicmsisencaost1
           , v_vagregapiscofinsst2
           , v_agregasuframast2
           , v_agregaicmsisencaost2
           , v_perdescsuframa
           , v_perdescpissuframa
           , v_percdescpis
           , v_percdesccofins
           , v_perdescicmisencao
           , v_aplicadescisencaomed           
           , v_destacdescicmisencaocomerc
           , v_destacicmsstanterior
           , v_tipocalculognre
        FROM PCTRIBUT
       WHERE (CODST = pio_nCodSt);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        po_vMensagem := 'Não foram encontrados dados para a Tributação: ' || NVL(pio_nCodSt,0);
        RAISE e_tratado;
    END;     
     
   /***************************************
    Pesquisa PMC quando a Tributação a usar
    ***************************************/
    vnPmPf := NULL;
    IF (v_usapmpfbasest = 'S') THEN
      P_OBTEM_PMPF(pio_nCodSt,
                   pi_nCodProd,
                   pi_nCodCli,                             
                   vnPmPf);
    END IF;
                 
   /***************************
    Pesquisa Valores da PCTABPR
    ***************************/
    n_vlultentmes := 0;
    IF (NVL(v_usavlultentmediobasest,'N') = 'S') THEN
    
      -- Se chegou aqui sem a Região
      IF (NVL(v_numregiao,0) = 0) THEN
    
        -- Pesquisa Região do Cliente por Filial
        BEGIN
          SELECT NUMREGIAO
            INTO v_numregiao
            FROM PCTABPRCLI
           WHERE (CODCLI      = pi_nCodCli)
             AND (CODFILIALNF = vvCodFilialFaturamento); -- HIS.03371.2017
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_numregiao := NULL;
        END;
      
        -- Se não achou Regiao do Cliente por Filial
        IF (v_numregiao IS NULL) THEN
          -- Pesquisa Região da Praça
          BEGIN
            SELECT NUMREGIAO
              INTO v_numregiao
              FROM PCPRACA
             WHERE (CODPRACA = v_codpraca);
          EXCEPTION
           WHEN NO_DATA_FOUND THEN
              v_numregiao := NULL;
          END;
        END IF;
        
      END IF; -- Fim Condição Se passou a Região no Parâmetro        
    
      -- Pesquisa dados da Região
      BEGIN
        SELECT VLULTENTMES
          INTO n_vlultentmes
          FROM PCTABPR
         WHERE (CODPROD   = pi_nCodProd)
           AND (NUMREGIAO = v_numregiao);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          n_vlultentmes := 0;
      END;
    END IF;
      
   /***************************************************************************
                  Calcula como se Fosse ST Fonte - HIS.01858.2015
    (Operador Logistico por Preço Fábrica, mas Trabalha com ST na Precificação)
    ***************************************************************************/
    IF (pi_vTipoChamada = 'L') THEN
    
      -- Trata o Cálculo como se fosse um Cliente ST Fonte
      v_clientefontest := 'S';
    
    END IF;
    
    /***************************************************************************
                 Utilizar ST Fonte SIMPLES Nacional [HIS.04322.2015]
    ***************************************************************************/
  
    -- Se Cliente for SIMPLES Nacional 
    IF v_simplesnacional = 'S' THEN    
      BEGIN   
        -- Busca Parâmetro
        SELECT NVL(VALOR,'N')         
          INTO v_medutilizarstfontesimplesnac
          FROM PCPARAMFILIAL
         WHERE NOME = 'MEDUTILIZARSTFONTESIMPLESNAC'
           AND CODFILIAL = '99';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_medutilizarstfontesimplesnac := 'N';
      END;
      
      -- Se Utilizar, substitui as variáveis para fazer o cálculo
      IF v_medutilizarstfontesimplesnac = 'S' THEN    
        BEGIN
          SELECT NVL(IVAFONTESIMPLESNAC,0)
               , NVL(ALIQICMS1FONTESIMPLESNAC,0)
               , NVL(ALIQICMS2FONTESIMPLESNAC,0)
               , NVL(PERCBASEREDSTFONTESIMPLESNAC,0)
               , NVL(PAUTAFONTESIMPLESNAC,0)
            INTO v_ivafonte
               , v_aliqicms1fonte
               , v_aliqicms2fonte
               , v_percbaseredstfonte
               , n_pautafonte
            FROM PCTRIBUT 
         WHERE (CODST = pio_nCodSt);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            po_vMensagem := 'Não foram encontrados dados para a Tributação SIMPLES NACIONAL: ' || NVL(pio_nCodSt,0);
          RAISE e_tratado;
        END;
      END IF; -- Fim-Se Utilizar ST Fonte SIMPLES Nacional
    END IF; -- Fim-se Cliente SIMPLES Nacional    
    
    -- 4415.073219.2016 - Se Utiliza Regra Diferenciada de ST Fonte na Transferência
    IF (pi_nCondVenda = 10) AND 
       (vUSAREGRADIFSTFONTETV10 = 'S') THEN    
      -- Se Utilizar, substitui as variáveis para fazer o cálculo
      BEGIN
        SELECT NVL(IVAFONTETV10,0)
             , NVL(ALIQICMS1FONTETV10,0)
             , NVL(ALIQICMS2FONTETV10,0)
             , NVL(PERCBASEREDSTFONTETV10,0)
             , NVL(PAUTAFONTETV10,0)
          INTO v_ivafonte
             , v_aliqicms1fonte
             , v_aliqicms2fonte
             , v_percbaseredstfonte
             , n_pautafonte
          FROM PCTRIBUT 
       WHERE (CODST = pio_nCodSt);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          po_vMensagem := 'Não foram encontrados dados para a Tributação TV10: ' || NVL(pio_nCodSt,0);
        RAISE e_tratado;
      END;
    END IF;
    
    -- Tributação diferenciada para Pedido de Avaria
    IF (pi_vPedidoAvaria = 'S')              AND 
       (vUSARABAPERDASTFONTEPEDAVARIA = 'S') AND
       (NVL(pi_nCondVenda,0) <> 10)          THEN -- DDMEDICA-5115
      vUSAREDICMNORMVENDASTFONTE := 'N'; -->> Não usa a Redução da Aba Venda
      v_ivafonte                 := NVL(v_iva_mc,0);
      v_aliqicms1fonte           := NVL(v_aliqicms1_mc,0);
      v_aliqicms2fonte           := NVL(v_aliqicms2_mc,0);
      v_percbaseredstfonte       := NVL(v_percbaseredst_mc,0);
      n_pautafonte               := NVL(v_pauta_mc,0);
    END IF;
   
 /**********************************************************************
  Chama Procedimento para Obter os valores para Customização 
  da Base ST com SUFRAMA/Redução PISCOFINS e DESONERACAO - DDMEDICA-7594
  **********************************************************************/
  P_OBTER_VALORES_BENEF_FISCAIS(pi_vCodFilial,
                                pi_vCodFilial, -->> Não tenho a Filial NF na Procedure
                                pi_nCodCli,
                                pi_nCodProd,
                                pio_nCodSt,
                                v_numcasasdecvenda,
                                v_tipocalcsulframa,
                                v_perdescicmisencao,
                                v_aplicadescisencaomed,
                                ROUND(pi_vPVenda,v_numcasasdecvenda), -->> Deve ser usado o Preço com Arredondamento
                                0, -->> Aqui não irei atualizar o preço de tabela
                                0, -->> Aqui não irei atualizar o preço base rca
                                pi_nQT,
                                vnVlDescReducaoPis,
                                vnPercDescReducaoPisAuxBF,
                                vnVlDescReducaoCofins,
                                vnPercDescReducaoCofinsAuxBF,
                                vnVlDescIcmIsencao,
                                vnPercDescIcmIsencaoAuxBF,
                                vnVlDescSuframa,
                                vnPercDescSuframaAuxBF,
                                vnPrecoLiqResultAuxBF,
                                vnPrecoTabResultAuxBF,
                                vnPrecoRcaResultAuxBF,
                                vvErrosBenefFiscais,
                                vvMsgErrosBenefFiscais);
    IF (vvErrosBenefFiscais = 'S') THEN
      RAISE e_benef_fiscais;
    END IF;                            
   
   /***********************************************************
    Chama Procedimento para Calcular a Base e Valor do ST Fonte
    ***********************************************************/
    P_OBTER_STFONTE(pi_nCodProd                  , -->> Código do Produto passado no Parâmetro
                    pi_nCondVenda                , -->> Tipo de Venda Passado no Parâmetro
                    pi_nPercVenda                , -->> Percentual de Venda passado no Parâmetro
                    v_iva                        ,
                    v_ivafonte                   , --> Variável local no parâmetro de Entrada e Saída
                    v_aliqicms1fonte             , --> Variável local no parâmetro de Entrada e Saída
                    v_aliqicms2fonte             , --> Variável local no parâmetro de Entrada e Saída
                    v_percbaseredstfonte         , --> Variável local no parâmetro de Entrada e Saída
                    v_percbaserednrpa            ,
                    v_percbaseredconsumidor      ,
                    v_utilizapercbaseredpf_trib  ,
                    v_tipocalcst                 ,
                    v_calcstpf                   ,
                    v_utilizapercbaseredpf_param ,
                    v_clientefontest             ,
                    v_calculast                  ,
                    v_ieent                      ,
                    v_tipofj                     ,
                    v_isentoicms                 ,
                    v_consumidorfinal            ,
                    v_utilizaiesimplificada      ,
                    v_tipoempresa                ,
                    v_consideraisentoscomopf     ,
                    pi_vPVenda                   , --> Preço de Venda passado no Parâmetro
                    pi_nValorIpi                 , --> Valor do IPI passado no Parâmetro
                    v_uffilial                   ,
                    v_estent                     ,
                    v_usavalorultentbasest       ,
                    v_valorultent                ,
                    v_usaivafontediferenciado    ,
                    v_ivafonte_cli               ,
                    v_AceitaPFContribuinte       ,
                    v_ALIQICMS1                  ,
                    v_ALIQICMS2                  ,
                    v_contribuinte               ,
                    v_numcasasdecvenda           ,
                    v_custonfsemst               ,
                    v_usavalorultentbasest2      ,
                    v_usapmcbasest               ,
                    v_precomaxconsum             ,
                    v_tipoclimed                 ,
                    v_isencaostorgaopub          ,
                    v_usabaseicmsreduzida        ,
                    v_usabcrultent               ,
                    n_basebcrultent              ,
                    n_stbcrultent                ,
                    v_calcstpautafarmaciapopular ,
                    n_pautafonte                 ,
                    v_farmaciapopular            ,
                    v_participafarmaciapopular   ,                                        
                    v_usaptabelabasest           ,
                    NVL(pi_nPTabela,pi_vPVenda)  , -->> Se a chamada ainda não tiver o PTabela, usar o PVenda
                    pi_vSomenteIVATribut         ,
                    v_usadescsimplesnac          ,
                    v_simplesnacional            ,
                    n_percredpvendasimplesnac    ,
                    v_tipomerc                   ,
                    v_usarajusteprecocmed        ,
                    n_percajusteprecocmed        ,
                    v_usaregimeespisenstfonte    ,
                    v_regimeespisenstfonte       ,
                    v_medretirarstbnfestadual    ,
                    pi_vItemBonific              ,
                    pi_nVlFreteOutrasDesp        ,
                    v_bnfnaocalculaicms          ,
                    vUSAREGSIMPLCARGATRIBSTFONTE ,
                    vREGSIMPLCARGATRIBSTFONTE    ,
                    nPERCREGSIMPLCARGATRIBSTFONTE,
                    vUSAREDUTORCAT49BASESTFONTE  ,
                    nPERCREDUTORCAT49BASESTFONTE ,
                    vUSACARGAMINIMADEFERIMSTFONTE,
                    nPERCARGAMINIMADEFERIMSTFONTE,
                    vUSAVLSTMAIORPERCMINPMC      ,
                    nPERVLSTMAIORPERCMINPMC      ,
                    po_nBaseStFonte              , -->> BASE ST FONTE QUE SERA RETORNADA PELA PROCEDURE
                    po_nValorStFonte             , -->> VALOR ST FONTE QUE SERA RETORNADA PELA PROCEDURE
                    po_vMensagem                 , -->> Mensagem de Erro de Retorno 
                    po_vRegimeEspIsenStFonte     , -->> Retorno indicando se tem Isenção ST Fonte
                    po_nAliqIcms1                ,
                    po_nAliqIcms2                ,
                    po_nIva                      , 
                    po_nPercBaseRedStFonte       ,
                    po_nPautaFonte               ,
                    po_vObservacaoStFonte        ,
                    vvCodFilialFaturamento       ,
                    po_vIndEscalaRelevante       ,
                    v_participafuncep            ,
                    v_utilizamotorcalculo        ,
                    v_formulapvenda              ,
                    v_peracrescimofuncep         ,
                    v_aliqicmsfecp               ,
                    v_codconfigfuncepmed         ,
                    po_nVLBASEFCPICMS            ,
                    po_nVLBASEFCPST              ,
                    po_nVLBCFCPSTRET             ,
                    po_nPERFCPSTRET              ,
                    po_nVLFCPSTRET               ,
                    po_nPERFCPSN                 ,
                    po_nVLFECP                   ,
                    po_nVLACRESCIMOFUNCEP        ,
                    po_nVLCREDFCPICMSSN          ,
                    po_nPERACRESCIMOFUNCEP       ,
                    po_nALIQICMSFECP             ,
                    po_nCODCONFIGFUNCEPMED       ,
                    vUSAREDICMNORMVENDASTFONTE   ,
                    vPERCBASERED                 ,
                    v_percipivenda               ,
                    v_usavlultentmediobasest     ,
                    n_percbasestrj               ,
                    n_vlultentmes                ,
                    pi_nValorNotaFiscal          ,
                    v_usaReducaoBasePmc          ,
                    v_pertetoredbasepmc          ,
                    v_isencaostfontebonificacao  ,
                    v_usapmpfbasest              ,
                    vnPmPf                       ,
                    v_agregapiscofinsst1         ,
                    v_agregasuframast1           ,
                    v_agregaicmsisencaost1       , 
                    v_vagregapiscofinsst2        ,
                    v_agregasuframast2           ,
                    v_agregaicmsisencaost2       ,
                    vnVlDescReducaoPis           ,
                    vnVlDescReducaoCofins        ,
                    vnVlDescIcmIsencao           ,
                    vnVlDescSuframa              ,
                    v_destacicmsstanterior       ,
                    po_nBCSTRETANTERIOR          ,
                    po_nVLICMSSUBSTITUTOANTERIOR ,
                    po_nVLICMSSTRETANTERIOR      ,
                    v_tipocalculognre            ,
                    po_nSTCLIENTEGNRE            ,
                    po_nPMPF
                    );
  
    -- Se ocorreram erros na Função
    IF (TRIM(po_vMensagem) IS NOT NULL) THEN
      RAISE e_tratado;
    END IF;                                         
                                                             
  EXCEPTION
    WHEN e_tratado THEN
      -- Sem ST
      po_nBaseStFonte  := 0;
      po_nValorStFonte := 0;
    WHEN e_benef_fiscais THEN
      -- Sem ST
      po_nBaseStFonte  := 0;
      po_nValorStFonte := 0;
      po_vMensagem     := 'Erro Cálculo ST Fonte: ' || SUBSTR(vvMsgErrosBenefFiscais,1,240);
    WHEN OTHERS THEN  
      -- Sem ST
      po_nBaseStFonte  := 0;
      po_nValorStFonte := 0;
      po_vMensagem     := 'Erro Cálculo ST Fonte: ' || SUBSTR('Erro: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM,1,240);
  END P_OBTEM_STFONTE_42;

 /*******************************************************************************
  *******************************************************************************
  *******************************************************************************
  *******************************************************************************
  Nome         : P_OBTEM_STFONTE_40
  Descricão    : Procedimento Obter a Base e Valor do ST Fonte por Preço de 
                 Tabela ou Preço de Venda
  *******************************************************************************
  *******************************************************************************
  *******************************************************************************
  *******************************************************************************
  **********************************************************************************/                                       
  PROCEDURE P_OBTEM_STFONTE_40(pi_vCodFilial             IN VARCHAR2,
                               pi_nCodProd               IN NUMBER,
                               pi_nCodCli                IN NUMBER,
                               pi_nNumRegiao             IN NUMBER,
                               pi_nCondVenda             IN NUMBER,
                               pi_nPercVenda             IN NUMBER,
                               pio_nCodSt                IN OUT NUMBER,
                               pi_vPVenda                IN NUMBER,
                               pi_nValorIpi              IN NUMBER,                                
                               pi_nPrecoMaxConsum        IN NUMBER,
                               pi_nValorUltEnt           IN NUMBER,
                               pi_nCustoNfSemSt          IN NUMBER,
                               pi_nPTabela               IN NUMBER,
                               pi_vSomenteIVATribut      IN VARCHAR2,
                               pi_vPesquisarCustos       IN VARCHAR2,
                               pi_vItemBonific           IN VARCHAR2,
                               pi_nVlFreteOutrasDesp     IN NUMBER,
                               po_nBaseStFonte          OUT NUMBER,
                               po_nValorStFonte         OUT NUMBER,
                               po_vMensagem             OUT VARCHAR2,
                               po_vRegimeEspIsenStFonte OUT VARCHAR2,
                               po_nAliqIcms1            OUT NUMBER,
                               po_nAliqIcms2            OUT NUMBER,
                               po_nIva                  OUT NUMBER,
                               po_nPercBaseRedStFonte   OUT NUMBER,
                               pi_vTipoChamada           IN VARCHAR2 DEFAULT 'O',
                               pi_nQT                    IN NUMBER DEFAULT 0,
                               pi_nNumPedido             IN NUMBER DEFAULT NULL,
                               pi_nCodFilialNf           IN VARCHAR2,
                               po_nPautaFonte           OUT NUMBER,
                               po_vObservacaoStFonte    OUT VARCHAR2,
                               po_vIndEscalaRelevante   OUT VARCHAR2,
                               po_vCnpjFabricante       OUT VARCHAR2,
                               po_vFabricante           OUT VARCHAR2,
                               po_nVLBASEFCPICMS        OUT NUMBER, -- HIS.04200.2017
                               po_nVLBASEFCPST          OUT NUMBER, -- HIS.04200.2017
                               po_nVLBCFCPSTRET         OUT NUMBER, -- HIS.04200.2017
                               po_nPERFCPSTRET          OUT NUMBER, -- HIS.04200.2017
                               po_nVLFCPSTRET           OUT NUMBER, -- HIS.04200.2017
                               po_nPERFCPSN             OUT NUMBER, -- HIS.04200.2017
                               po_nVLFECP               OUT NUMBER, -- HIS.04200.2017
                               po_nVLACRESCIMOFUNCEP    OUT NUMBER, -- HIS.04200.2017
                               po_nPERACRESCIMOFUNCEP   OUT NUMBER, -- HIS.04200.2017
                               po_nALIQICMSFECP         OUT NUMBER, -- HIS.04200.2017
                               po_nVLCREDFCPICMSSN      OUT NUMBER, -- HIS.04200.2017
                               po_nCODCONFIGFUNCEPMED   OUT NUMBER,
                               pi_vOrdemCalculo          IN VARCHAR2 DEFAULT 'F',
                               pi_vMemoriaCalculo        IN VARCHAR2 DEFAULT 'N',
                               pi_nValorNotaFiscal       IN NUMBER   DEFAULT 0,
                               pi_vPedidoAvaria          IN VARCHAR  DEFAULT 'N'
                               )
  IS
    po_nBCSTRETANTERIOR          NUMBER;
    po_nVLICMSSUBSTITUTOANTERIOR NUMBER;                               
    po_nVLICMSSTRETANTERIOR      NUMBER;
    po_nSTCLIENTEGNRE            NUMBER;
    po_nPMPF                     NUMBER;
    po_vClienteFonteSt           VARCHAR2(255);
  BEGIN
  
    P_OBTEM_STFONTE_42(pi_vCodFilial,
                       pi_nCodProd,
                       pi_nCodCli,
                       pi_nNumRegiao,
                       pi_nCondVenda,
                       pi_nPercVenda,
                       pio_nCodSt,
                       pi_vPVenda,
                       pi_nValorIpi,
                       pi_nPrecoMaxConsum,
                       pi_nValorUltEnt,
                       pi_nCustoNfSemSt,
                       pi_nPTabela,
                       pi_vSomenteIVATribut,
                       pi_vPesquisarCustos,
                       pi_vItemBonific,
                       pi_nVlFreteOutrasDesp,
                       po_nBaseStFonte,
                       po_nValorStFonte,
                       po_vMensagem,
                       po_vRegimeEspIsenStFonte,
                       po_nAliqIcms1,
                       po_nAliqIcms2,
                       po_nIva,
                       po_nPercBaseRedStFonte,
                       pi_vTipoChamada,
                       pi_nQT,
                       pi_nNumPedido,
                       pi_nCodFilialNf,
                       po_nPautaFonte,
                       po_vObservacaoStFonte,
                       po_vIndEscalaRelevante,
                       po_vCnpjFabricante,
                       po_vFabricante,
                       po_nVLBASEFCPICMS,
                       po_nVLBASEFCPST,
                       po_nVLBCFCPSTRET,
                       po_nPERFCPSTRET,
                       po_nVLFCPSTRET,
                       po_nPERFCPSN,
                       po_nVLFECP,
                       po_nVLACRESCIMOFUNCEP,
                       po_nPERACRESCIMOFUNCEP,
                       po_nALIQICMSFECP,
                       po_nVLCREDFCPICMSSN,
                       po_nCODCONFIGFUNCEPMED,
                       pi_vOrdemCalculo,
                       pi_vMemoriaCalculo,
                       pi_nValorNotaFiscal,
                       pi_vPedidoAvaria,
                       po_nBCSTRETANTERIOR,
                       po_nVLICMSSUBSTITUTOANTERIOR,
                       po_nVLICMSSTRETANTERIOR,
                       po_nSTCLIENTEGNRE,
                       po_nPMPF,
                       po_vClienteFonteSt);

  END P_OBTEM_STFONTE_40;

 /********************************************************************************  
  ********************************************************************************  
  ********************************************************************************  
                                  << FIM >>
                      C Á L C U L O   D O   S T   F O N T E 
  ********************************************************************************  
  ********************************************************************************  
  ********************************************************************************  

 /*******************************************************************************
  Nome         : F_OBTER_ST_FONTE
  Descricão    : Função para retornar o ST Fonte de um Produto
  ********************************************************************************/                                       
  FUNCTION F_OBTER_ST_FONTE(pi_vCodFilial IN VARCHAR2,
                            pi_nCodProd   IN NUMBER,
                            pi_nPTabela   IN NUMBER,
                            pi_nPVenda    IN NUMBER,
                            pi_nCodCli    IN NUMBER DEFAULT NULL,
                            pi_nCondVenda IN NUMBER DEFAULT 1,
                            pi_vTipoVenda IN VARCHAR2 DEFAULT NULL,
                            pi_vSomarFecp IN VARCHAR2 DEFAULT NULL)
  RETURN NUMBER IS
    --
    vnRetStFonte                       NUMBER;
    -- 
    vnCodCli                           NUMBER;
    vvPedidoAvaria                     VARCHAR2(1);
    vnCodSt                            NUMBER;
    --
    vnBaseicst                         PCPEDI.BASEICST%TYPE;
    vvMsgRetObterStFonte               VARCHAR2(2000);
    vvRegimeEspIsenStFonte             PCPEDI.REGIMEESPISENSTFONTE%TYPE;
    vnAliqIcms1                        PCTRIBUT.ALIQICMS1%TYPE;
    vnAliqIcms2                        PCTRIBUT.ALIQICMS2%TYPE;
    vnIva                              PCTRIBUT.IVA%TYPE;
    vnPercBaseRedStFonte               PCPEDI.PERCBASEREDSTFONTE%TYPE;
    vnPautaFonte                       PCPEDI.PAUTA%TYPE;
    vvObservacaoStFonte                PCPEDI.OBSERVACAOSTFONTE%TYPE;
    vvIndEscalaRelevante               PCPEDI.INDESCALARELEVANTE%TYPE;
    vvCnpjFabricante                   PCPEDI.CNPJFABRICANTE%TYPE;
    vvFabricante                       PCPEDI.FABRICANTE%TYPE;   
    --
    TYPE TRecDadosFuncep               IS RECORD(
         nVLBASEFCPICMS                PCPEDI.VLBASEFCPICMS%TYPE,
         nVLBASEFCPST                  PCPEDI.VLBASEFCPST%TYPE,
         nVLBCFCPSTRET                 PCPEDI.VLBCFCPSTRET%TYPE,
         nPERFCPSTRET                  PCPEDI.PERFCPSTRET%TYPE,
         nVLFCPSTRET                   PCPEDI.VLFCPSTRET%TYPE,
         nPERFCPSN                     PCPEDI.PERFCPSN%TYPE,
         nVLFECP                       PCPEDI.VLFECP%TYPE,
         nVLACRESCIMOFUNCEP            PCPEDI.VLACRESCIMOFUNCEP%TYPE,
         nPERACRESCIMOFUNCEP           PCPEDI.PERACRESCIMOFUNCEP%TYPE,
         nALIQICMSFECP                 PCPEDI.ALIQICMSFECP%TYPE,
         nVLCREDFCPICMSSN              PCPEDI.VLCREDFCPICMSSN%TYPE,
         nCODCONFIGFUNCEPMED           PCPEDI.CODCONFIGFUNCEPMED%TYPE);
    vrDadosFuncep                      TRecDadosFuncep;
    -- DDMEDICA-7697
    vnBCSTRETANTERIOR                  PCPEDI.BCSTRETANTERIOR%TYPE;
    vnVLICMSSUBSTITUTOANTERIOR         PCPEDI.VLICMSSUBSTITUTOANTERIOR%TYPE;
    vnVLICMSSTRETANTERIOR              PCPEDI.VLICMSSTRETANTERIOR%TYPE;
    vnSTCLIENTEGNRE                    PCPEDI.STCLIENTEGNRE%TYPE;
    vnPMPF                             PCPEDI.PMPFMEDICAMENTO%TYPE;
    vvClienteFonteSt                   PCCLIENT.CLIENTEFONTEST%TYPE;    
  BEGIN
  
    -- Inicializa Retorno
    vnRetStFonte := 0;
    
    -- Define o Código do Cliente
    IF (NVL(pi_nCodCli,0) > 0) THEN
      vnCodCli := pi_nCodCli;
    ELSE
      BEGIN
        SELECT CODCLI
          INTO vnCodCli
          FROM PCFILIAL
         WHERE (CODIGO = pi_vCodFilial);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnCodCli := NULL;   
      END;
    END IF;
    
    -- Define se Pedido Avaria
    vvPedidoAvaria := 'N';
    IF (pi_vTipoVenda = 'PA') THEN
      vvPedidoAvaria := 'S';
    END IF;
    
    -- Inicializa o Código da Tributação
    vnCodSt := NULL;
    
    -- Obtém ST Fonte
    -- DDMEDICA-7697 - Cálculo com o ST Recolhido Anteriormente
    P_OBTEM_STFONTE_42(pi_vCodFilial,
                       pi_nCodProd,
                       vnCodCli,
                       NULL, -- pi_nNumRegiao
                       pi_nCondVenda,
                       100,  -- pi_nPercVenda
                       vnCodSt,
                       pi_nPVenda,
                       0,    -- pi_nValorIpi
                       NULL, -- pi_nPrecoMaxConsum,
                       NULL, -- pi_nValorUltEnt
                       NULL, -- pi_nCustoNfSemSt
                       pi_nPTabela,
                       'N',  -- pi_vSomenteIVATribut
                       'S',  -- pi_vPesquisarCustos
                       'N',  -- pi_vItemBonific
                       0,    -- Sem Despesas acessórias
                       vnBaseicst,
                       vnRetStFonte, -->> RETORNA O VALOR DO ST
                       vvMsgRetObterStFonte, 
                       vvRegimeEspIsenStFonte,
                       vnAliqIcms1,
                       vnAliqIcms2,
                       vnIva,
                       vnPercBaseRedStFonte,
                       'O',  -- pi_vTipoChamada 
                       1,    -- pi_nQT
                       NULL, -- pi_nNumPed
                       pi_vCodFilial,
                       vnPautaFonte,
                       vvObservacaoStFonte,
                       vvIndEscalaRelevante,
                       vvCnpjFabricante,
                       vvFabricante,
                       vrDadosFuncep.nVLBASEFCPICMS, 
                       vrDadosFuncep.nVLBASEFCPST,
                       vrDadosFuncep.nVLBCFCPSTRET,
                       vrDadosFuncep.nPERFCPSTRET,
                       vrDadosFuncep.nVLFCPSTRET,
                       vrDadosFuncep.nPERFCPSN,
                       vrDadosFuncep.nVLFECP,
                       vrDadosFuncep.nVLACRESCIMOFUNCEP,
                       vrDadosFuncep.nPERACRESCIMOFUNCEP, 
                       vrDadosFuncep.nALIQICMSFECP,
                       vrDadosFuncep.nVLCREDFCPICMSSN,                            
                       vrDadosFuncep.nCODCONFIGFUNCEPMED,
                       'F', -- pi_vOrdemCalculo
                       'N', -- pi_vMemoriaCalculo
                       0,   -- pi_nValorNotaFiscal
                       vvPedidoAvaria,
                       vnBCSTRETANTERIOR,          -- DDMEDICA-7697
                       vnVLICMSSUBSTITUTOANTERIOR, -- DDMEDICA-7697
                       vnVLICMSSTRETANTERIOR,      -- DDMEDICA-7697
                       vnSTCLIENTEGNRE,            -- DDMEDICA-7697
                       vnPMPF,                     -- DDMEDICA-7697
                       vvClienteFonteSt            -- DDMEDICA-7697
                       );

    -- Se soma o ST do FECP
    IF (NVL(pi_vSomarFecp,'N') = 'S') THEN
      vnRetStFonte := NVL(vnRetStFonte,0) + NVL(vrDadosFuncep.nVLFECP,0);
      -- DDMEDICA-7697 - Somar também o ST Retido anteriormente
      vnRetStFonte := NVL(vnRetStFonte,0) + NVL(vnVLICMSSTRETANTERIOR,0);      
    END IF;
    
    -- Retorno
    RETURN vnRetStFonte;
    
  END F_OBTER_ST_FONTE;
                                           
END PKG_FUNCOESVENDAS_MED;