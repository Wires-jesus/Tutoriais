CREATE OR REPLACE PROCEDURE PRC_MED_OBTEM_SEL_PROMO_CLI(pi_dData                IN  DATE,
                                      pi_nCodCli              IN  NUMBER,
                                      pi_vCodFilial           IN  VARCHAR2,
                                      pi_nCodCondicaoVenda    IN  NUMBER,
                                      pi_nCodPraca            IN  NUMBER,                                       
                                      pi_nNumRegiao           IN  NUMBER,                                       
                                      pi_nCodUsur             IN  NUMBER,
                                      pi_vOrigemPed           IN  VARCHAR2,
                                      pi_vTipoFv              IN  VARCHAR2,                                       
                                      pi_nCodPlPag            IN  NUMBER,
                                      pi_vExecutaCommit       IN  VARCHAR2,
                                      pi_vVisualizarPromoBloq IN  VARCHAR2,
                                      pi_vVisualizarPromoEsp  IN  VARCHAR2,
                                      po_vOcorreramErros      OUT VARCHAR2,
                                      po_vMsgErros            OUT VARCHAR2,
                                      pi_vSomentePromoPadrao  IN  VARCHAR2 DEFAULT 'N')
/*******************************************************************************
 Nome         : PRC_MED_OBTEM_SEL_PROMO_CLI
 Descricão    : Procedimento para Obter as Promoções Válidas para o Cliente,
                carregando-as em Tabela Temporária
 Parâmetros   : ENTRADA:
                pi_dData                = Data do Pedido
                pi_nCodCli              = Código do Cliente
                pi_vCodFilial           = Código da Filial
                pi_nCodCondicaoVenda    = Código da Condição de Venda
                pi_nCodPraca            = Código da Praça do Cliente
                pi_nNumRegiao           = Região do Cliente
                pi_nCodUsur             = Código Vendedor
                pi_vOrigemPed           = Origem do Pedido
                pi_vTipoFv              = Tipo de Pedido Força de Vendas [FV;OL;PE]                                                        
                pi_nCodPlPag            = Código do Plano de Pagamento
                pi_vExecutaCommit       = Se executa COMMIT (S- Sim;Não)
                pi_vVisualizarPromoBloq = Se tem permissão para visualizar Promoção Bloqueada
                pi_vVisualizarPromoEsp  = Se tem permissão para visualizar Promoção Especial
                pi_vSomentePromoPadrao  = Se Somente carregar a Promoção [S-Sim;N-Não]
                SAIDA:
                po_vOcorreramErros   = Se Ocorreram Erros [S-Sim;N-Não]
                po_vMsgErros         = Mensagem de Erro                
 Alteracão    : Anderson Silva - 13/08/2013 - Criação da Procedure
 Alteracão    : Anderson Silva - 14/02/2014 - Somente considerar Politicas
                                              de Desconto e Preço Fixo
 Alteração:   : Anderson Silva - 11/04/2014 - Novos Tipos de Encarte - Novas Promoções
                                              por Valor, Mix e Kit
 Alteração    : Anderson Silva - 22/04/2014 - uso do campo APENASPLPAGMAX                                              
 Alteração    : Rubens Pinheiro- 13/02/2015 - Verificar se tem permissão de listar promoçao bloqueada
 Alteração    : Anderson Silva - 03/09/2015 - HIS.01152.2015 - Desconsiderar Casadinha
 Alteração    : Anderson Silva - 07/10/2015 - Nova permissão promoção especial
 Alteração    : Anderson Silva - 30/08/2016 - Normalização PCDESCONTO
 Alteração    : Anderson Silva - 03/10/2016 - Tabela TEMP de Promoções do Cliente para auxiliar o cálculo do Preço com Maior Desc.
 Alteração    : Anderson Silva - 04/11/2016 - Parâmetro pi_vSomentePromoPadrao
 Alteração    : Anderson Silva - 12/09/2017 - HIS.01889.2017 - Grupos na PCDESCONTO
 Alteração    : Anderson Silva - 19/05/2019 - HIS.02239.2018 - Prazo Mandatório
 Alteração    : Anderson Silva - 22/08/2019 - DDMEDICA-641 - Pedido Avaria e CrossDocking
 Alteração    : Anderson Silva - 26/01/2020 - DDMEDICA-1969 - Apresentar das Promoções de Cliente por Faixa de Quantidade como Promoção Principal mediante Regra Específica
 Alteração    : Anderson Silva - 03/09/2020 - DDMEDICA-3914 - Incluir a Promoção de Markup também como Principal
 
 CREATE GLOBAL TEMPORARY TABLE PCMED_SEL_PROMO_CLI(
   CODPROMOCAOMED    NUMBER(9), 
   DESCRICAORESUMIDA VARCHAR2(40),
   TIPOPROMOCAO      VARCHAR2(1)) ON COMMIT PRESERVE ROWS; 

 CREATE GLOBAL TEMPORARY TABLE PCMED_PROMO_CLI(
   CODPROMOCAOMED    NUMBER(9)) ON COMMIT PRESERVE ROWS;    
********************************************************************************/                                       
IS

  -- Dados do RCA
  vnCodSupervisor             NUMBER;
  vvAreaAtuacao               PCUSUARI.AREAATUACAO%TYPE;
  -- Dados do Cliente
  vnCodCliPrinc               NUMBER;
  vnCodAtv1                   NUMBER;
  vnCodPraca                  NUMBER;
  vvSimplesNacional           PCCLIENT.SIMPLESNACIONAL%TYPE;
  vnCodRede                   PCCLIENT.CODREDE%TYPE;
  vvClasseVenda               PCCLIENT.CLASSEVENDA%TYPE;
  vnCodPromocaoMed            PCCLIENT.CODPROMOCAOMED%TYPE;
  -- Dados da Promoção
  vvDescricaoResumida         PCPROMOCAOMED.DESCRICAORESUMIDA%TYPE;
  vvTipoPromocao              PCPROMOCAOMED.TIPOPROMOCAO%TYPE;
  vvTipoPolitica              PCPROMOCAOMED.TIPOPOLITICA%TYPE;
  vvBloqueio                  PCPROMOCAOMED.BLOQUEIO%TYPE;
  vvVisualizaPromoEsp         PCPROMOCAOMED.VISUALIZARPROMOESP%TYPE;
  vvPrazoPlPagMandatorio      PCPROMOCAOMED.PRAZOPLPAGMANDATORIO%TYPE; -- HIS.02239.2018
  -- Dados do Plano de Pagamento
  vnNumDias                   PCPLPAG.NUMDIAS%TYPE;
  -- Exibe Maior % Desconto
  vEXIBIRMAIORPERCDESCPSQPRODUTO PCPERFILTELEVMED.EXIBIRMAIORPERCDESCPSQPRODUTO%TYPE;     
  -- Regra Exceção
  vvUsaNormalizacaoDesc          PCREGRASEXCECAOMED.VALOR%TYPE;
  -- HIS.02239.2018 - Plano de Pagamento por causa da Regra do Prazo Mandatório
  vnCodPlPag                     PCPEDC.CODPLPAG%TYPE;
  -- Parâmetro Informar Promoção nos Itens
  vSELPROMOMEDSOMENTEITENS       PCPARAMFILIAL.VALOR%TYPE;
  -- DDMEDICA-1969
  vvUsaPromoFaixaQtdePrincipal   PCREGRASEXCECAOMED.VALOR%TYPE;

/*******************************************************************************
                   INICIO DO PROCESSAMENTO PRINCIPAL
 *******************************************************************************/  
BEGIN

  -- Inicializa Indicação de Erros
  po_vMsgErros := NULL;
  
  -- Limpa Tabela Temporária
  DELETE FROM PCMED_SEL_PROMO_CLI;
  DELETE FROM PCMED_PROMO_CLI;
  -- Efetiva Transações
  IF (pi_vExecutaCommit = 'S') THEN
    COMMIT;
  END IF;     
  
  -- Busca Regra do Perfil
  BEGIN
    SELECT PCPERFILTELEVMED.EXIBIRMAIORPERCDESCPSQPRODUTO      
      INTO vEXIBIRMAIORPERCDESCPSQPRODUTO
      FROM PCPERFILTELEVMED
     WHERE (PCPERFILTELEVMED.EXIBIRMAIORPERCDESCPSQPRODUTO = 'S')
       AND (ROWNUM                                         = 1);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      vEXIBIRMAIORPERCDESCPSQPRODUTO := 'N';
  END;

  -- Parâmetro Informar Promoção nos Itens
  BEGIN
    SELECT VALOR 
      INTO vSELPROMOMEDSOMENTEITENS
      FROM PCPARAMFILIAL
     WHERE (NOME = 'SELPROMOMEDSOMENTEITENS')
       AND (CODFILIAL = '99');
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      vSELPROMOMEDSOMENTEITENS := 'N';
  END;

  -- Buscar dados do Cliente
  BEGIN
    SELECT NVL(CODCLIPRINC, CODCLI) CODCLIPRINC,
           CODATV1,
           CODPRACA,
           PCCLIENT.SIMPLESNACIONAL,
           PCCLIENT.CODREDE,
           PCCLIENT.CLASSEVENDA,
           PCCLIENT.CODPROMOCAOMED
      INTO vnCodCliPrinc, 
           vnCodAtv1, 
           vnCodPraca, 
           vvSimplesNacional,
           vnCodRede,
           vvClasseVenda,
           vnCodPromocaoMed
      FROM PCCLIENT
     WHERE (CODCLI = pi_nCodCli);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      vnCodCliPrinc     := NULL;
      vnCodAtv1         := NULL;
      vnCodPraca        := NULL;
      vvSimplesNacional := NULL;
      vnCodRede         := NULL;
      vvClasseVenda     := NULL;
      vnCodPromocaoMed  := NULL;
  END;     

  -- Buscar dados do RCA
  BEGIN
    SELECT CODSUPERVISOR, 
           AREAATUACAO
      INTO vnCodSupervisor, 
           vvAreaAtuacao
      FROM PCUSUARI
     WHERE (CODUSUR = pi_nCodUsur);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      vnCodSupervisor := NULL;
      vvAreaAtuacao   := NULL;
  END;     
  
  -- Busca dados do Plano de Pagamento
  BEGIN
    SELECT NVL(NUMDIAS,0)
      INTO vnNumDias
      FROM PCPLPAG
     WHERE (CODPLPAG = pi_nCodPlPag);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      vnNumDias := 0;    
  END;
  
  -- Verifica se usa Normalização da PCDESCONTO
  BEGIN
    SELECT NVL(PCREGRASEXCECAOMED.VALOR,'N')
      INTO vvUsaNormalizacaoDesc
      FROM PCREGRASEXCECAOMED
     WHERE (PCREGRASEXCECAOMED.NOME      = 'USAREGRANORMALIZADESC')
       AND (PCREGRASEXCECAOMED.CODFILIAL = '99'); 
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      vvUsaNormalizacaoDesc := 'N';
  END;
   
  -- Regra Específica de Promoção Principal - DDMEDICA-1969
  BEGIN
    SELECT NVL(PCREGRASEXCECAOMED.VALOR,'N')
      INTO vvUsaPromoFaixaQtdePrincipal
      FROM PCREGRASEXCECAOMED
     WHERE (PCREGRASEXCECAOMED.NOME      = 'USAPROMOFAIXAQTDEPRINCIPAL')
       AND (PCREGRASEXCECAOMED.CODFILIAL = '99'); 
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      vvUsaPromoFaixaQtdePrincipal := 'N';
  END;
   
 /***********************************************************
  ***********************************************************
  ** SE CHAMADO PARA CARREGAR A PROMOÇÃO PADRÃO DO CLIENTE **
  **         (Otimização da 2316 ao abrir Pedido)          **
  **     (Precisa usar a Normalização da PCDESCONTO)       **
  ***********************************************************
  ***********************************************************/
  IF (NVL(pi_vSomentePromoPadrao,'N') = 'S') AND
     (NVL(vvUsaNormalizacaoDesc,'N')  = 'S') THEN
  
    -- Pesquisa Dados da Promoção
    BEGIN
      SELECT DESCRICAORESUMIDA
           , TIPOPROMOCAO
           , TIPOPOLITICA
           , NVL(BLOQUEIO,'N')
           , NVL(VISUALIZARPROMOESP,'N')
           , NVL(PRAZOPLPAGMANDATORIO,'N') -- HIS.02239.2018
        INTO vvDescricaoResumida
           , vvTipoPromocao
           , vvTipoPolitica
           , vvBloqueio
           , vvVisualizaPromoEsp
           , vvPrazoPlPagMandatorio -- HIS.02239.2018
        FROM PCPROMOCAOMED
       WHERE (CODPROMOCAOMED = vnCodPromocaoMed); -->> Promoção Padrão do Cliente
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvDescricaoResumida    := NULL;    
        vvTipoPromocao         := NULL;    
        vvTipoPolitica         := NULL;
        vvVisualizaPromoEsp    := NULL;
        vvPrazoPlPagMandatorio := NULL; -- HIS.02239.2018
    END;
    
    -- Plano de Pagamento com tratamento para o Prazo Mandatório da Promoção - HIS.02239.2018
    vnCodPlpag := pi_nCodPlPag;
    IF (vvPrazoPlPagMandatorio = 'S') THEN
      BEGIN
        SELECT CODPLPAG
         INTO vnCodPlpag
         FROM PCPROMOCAOPLPAGMED
        WHERE (CODPROMOCAOMED = vnCodPromocaoMed) -->> Promoção Padrão do Cliente
          AND (ROWNUM = 1);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
         vnCodPlpag := pi_nCodPlPag;
      END;
    END IF;    

    -- Se Usar Normalização da PCDESCONTO a Função FCT_MED_PODECOMPRARPROMOCAO retornará se Promoção Válida
    IF (FCT_MED_PODECOMPRARPROMOCAO(vnCodPromocaoMed, -->> Promoção Padrão do Cliente
                                    pi_vCodFilial,
                                    pi_nCodCli,       -- DDMEDICA-4778 no caso de normalizada a function já faz a diferenciação e aplicação de regras de cliente principal
                                    pi_nNumRegiao,
                                    pi_nCodUsur,
                                    vnCodPlpag, -- HIS.02239.2018
                                    pi_nCodCondicaoVenda,
                                    pi_vOrigemPed,
                                    pi_vTipoFv,
                                    pi_dData) = 'S') THEN

      IF (vvBloqueio = 'N') OR 
         ((vvBloqueio = 'S') AND (pi_vVisualizarPromoBloq = 'S')) THEN
         
        IF (vvVisualizaPromoEsp = 'N') OR 
           ((vvVisualizaPromoEsp = 'S') AND (pi_vVisualizarPromoEsp = 'S')) THEN

          INSERT INTO PCMED_SEL_PROMO_CLI
                    ( CODPROMOCAOMED
                    , DESCRICAORESUMIDA
                    , TIPOPROMOCAO )
             VALUES ( vnCodPromocaoMed -->> Promoção Padrão do Cliente
                    , vvDescricaoResumida
                    , vvTipoPromocao );                                  
        END IF;  
        
      END IF;  
            
    END IF; -- FIM CONDIÇÃO: (FCT_MED_PODECOMPRARPROMOCAO = 'S')  
  
 /***********************************************************
  ***********************************************************
  **      SE CHAMADO PARA CARREGAR TODAS AS PROMOÇÕES      **
  ***********************************************************
  ***********************************************************/
  ELSE

    ---------------------------------------------------------------------------
    -- PROMOÇÕES NORMALIZADAS
    ---------------------------------------------------------------------------
    IF (NVL(vvUsaNormalizacaoDesc,'N') = 'S') THEN

      FOR vc_Promocoes IN (SELECT CODPROMOCAOMED
                             FROM PCPROMOCAOMED
                            WHERE (TRUNC(pi_dData) BETWEEN DATAINICIAL AND DATAFINAL)
                              ) LOOP
                              
        -- Pesquisa Dados da Promoção
        BEGIN
          SELECT DESCRICAORESUMIDA
               , TIPOPROMOCAO
               , TIPOPOLITICA
               , NVL(BLOQUEIO,'N')
               , NVL(VISUALIZARPROMOESP,'N')
               , NVL(PRAZOPLPAGMANDATORIO,'N') -- HIS.02239.2018
            INTO vvDescricaoResumida
               , vvTipoPromocao
               , vvTipoPolitica
               , vvBloqueio
               , vvVisualizaPromoEsp
               , vvPrazoPlPagMandatorio -- HIS.02239.2018
            FROM PCPROMOCAOMED
           WHERE (CODPROMOCAOMED = vc_Promocoes.CODPROMOCAOMED);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvDescricaoResumida    := NULL;    
            vvTipoPromocao         := NULL;    
            vvTipoPolitica         := NULL;
            vvVisualizaPromoEsp    := NULL;
            vvPrazoPlPagMandatorio := NULL; -- HIS.02239.2018
        END;
    
        -- Plano de Pagamento com tratamento para o Prazo Mandatório da Promoção - HIS.02239.2018
        vnCodPlpag := pi_nCodPlPag;
        IF (vvPrazoPlPagMandatorio = 'S') THEN
          BEGIN
            SELECT CODPLPAG
             INTO vnCodPlpag
             FROM PCPROMOCAOPLPAGMED
            WHERE (CODPROMOCAOMED = vc_Promocoes.CODPROMOCAOMED) -->> Promoção do Laço
              AND (ROWNUM = 1);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
             vnCodPlpag := pi_nCodPlPag;
          END;
        END IF;    
    
        -- Se Usar Normalização da PCDESCONTO a Função FCT_MED_PODECOMPRARPROMOCAO retornará se Promoção Válida
        IF (FCT_MED_PODECOMPRARPROMOCAO(vc_Promocoes.CODPROMOCAOMED,
                                        pi_vCodFilial,
                                        pi_nCodCli , -- DDMEDICA-4778 no caso de normalizada a function já faz a diferenciação e aplicação de regras de cliente principal,
                                        pi_nNumRegiao,
                                        pi_nCodUsur,
                                        vnCodPlpag, -- HIS.02239.2018
                                        pi_nCodCondicaoVenda,
                                        pi_vOrigemPed,
                                        pi_vTipoFv,
                                        pi_dData) = 'S') THEN
    
          -- Se Politica de Desconto ou Preço Fixo
          -- E não for Promoção de Produtos de mesma Família
          -- (Com relação TipoPromocao = 'K' não estar nesta condição, 
          -- quando chamado para carregar as Promoções de Cabeçalho, 
          -- no Delphi o Select do Combobox tem a condição: TipoPromocao <> 'K',
          -- quando chamado para carregar as Promoções de Kit (Inserir Kit), no Delphi
          -- o Select do ComboBox tem a condição: TipoPromocao = 'K'
          -- HIS.01152.2015 - Adicionado para não carregar para seleção na promoção principal e no combo o tipo S - Casadinha
          IF ((NVL(vvUsaPromoFaixaQtdePrincipal,'N')  = 'S') AND (NVL(vvTipoPolitica,' ') IN ('D','P','Q','F','M'))) OR
             ((NVL(vvUsaPromoFaixaQtdePrincipal,'N') <> 'S') AND (NVL(vvTipoPolitica,' ') IN ('D','P','M'))) or 
             ((NVL(vvTipoPromocao,' ') in ('K')) AND (NVL(vvTipoPolitica,' ') IN ('Q')))  THEN
            IF (NVL(vvTipoPromocao,' ') NOT IN ('F','S')) THEN
      
              IF (vvBloqueio = 'N') OR 
                 ((vvBloqueio = 'S') AND (pi_vVisualizarPromoBloq = 'S')) THEN
               
                IF (vvVisualizaPromoEsp = 'N') OR 
                   ((vvVisualizaPromoEsp = 'S') AND (pi_vVisualizarPromoEsp = 'S')) THEN
               
                  INSERT INTO PCMED_SEL_PROMO_CLI
                            ( CODPROMOCAOMED
                            , DESCRICAORESUMIDA
                            , TIPOPROMOCAO )
                     VALUES ( vc_Promocoes.CODPROMOCAOMED
                            , vvDescricaoResumida
                            , vvTipoPromocao );
                          
                END IF;  
        
              END IF;  
            
            END IF;                
          END IF; -- vvUsaPromoFaixaQtdePrincipal
          
        END IF; -- FIM CONDIÇÃO: (FCT_MED_PODECOMPRARPROMOCAO = 'S')
                  
      END LOOP;                              

    ---------------------------------------------------------------------------
    -- PROMOÇÕES ANTIGAS
    ---------------------------------------------------------------------------
    ELSE
  
      -- PESQUISA PROMOÇÕES A PARTIR DA PCDESCONTO
      FOR vc_Promocoes IN (SELECT DISTINCT 
                                  PCDESCONTO.CODPROMOCAOMED
                             FROM PCDESCONTO 
                                , PCPROMOCAOMED
                            WHERE (PCPROMOCAOMED.CODPROMOCAOMED = PCDESCONTO.CODPROMOCAOMED)
                              AND (TRUNC(pi_dData) BETWEEN dtinicio AND dtfim)
                              /*--AND (NVL(PCDESCONTO.UTILIZADESCREDE, 'N') = 'N')
                              --AND ((CODCLI = pi_nCodCli) OR (CODCLI IS NULL))*/
                              AND ( ((nvl(PCDESCONTO.utilizadescrede, 'N') = 'S') AND (codcli IN (pi_nCodCli,vnCodCliPrinc))) OR
                                    ((nvl(PCDESCONTO.utilizadescrede, 'N') = 'N') AND (codcli  = pi_nCodCli))       OR
                                     (codcli IS NULL) )
                              AND ((CODUSUR = pi_nCodUsur) OR (CODUSUR IS NULL))
                              AND ((CODSUPERVISOR = vnCodSupervisor) OR (CODSUPERVISOR IS NULL))
                              AND ((NUMREGIAO = pi_nNumRegiao) OR (NUMREGIAO IS NULL))
                              AND ((CODATIV = vnCodAtv1) OR (CODATIV IS NULL))
                              AND ((ORIGEMPED = pi_vOrigemPed) OR (NVL(ORIGEMPED, 'O') = 'O'))
                              AND ((CODPRACA = vnCodPraca) OR (CODPRACA IS NULL))
                              AND ((CLASSEVENDA = vvClasseVenda) OR (CLASSEVENDA IS NULL))
                              AND ((AREAATUACAO = vvAreaAtuacao) OR (AREAATUACAO IS NULL))
                              AND ((CODFILIAL  = pi_vCodFilial) OR (CODFILIAL IS NULL))    
                              AND ((CODREDE = vnCodRede) OR (CODREDE IS NULL))
                              -- HIS.01889.2017
                              AND ((PCDESCONTO.TIPOGRUPOREST IS NULL) OR 
                                   (PCDESCONTO.TIPOGRUPOREST = 'GP' ) OR -->> Colocado para não deixar de trazer os registros com Filtro de Grupo de Produtos
                                   (PCDESCONTO.CODGRUPOREST  = (SELECT PCGRUPOSCAMPANHAI.CODGRUPO
                                                                 FROM PCGRUPOSCAMPANHAI
                                                                WHERE PCGRUPOSCAMPANHAI.DTEXCLUSAO IS NULL
                                                                  AND PCGRUPOSCAMPANHAI.CODGRUPO = PCDESCONTO.CODGRUPOREST
                                                                  AND PCGRUPOSCAMPANHAI.CODITEM  = DECODE(PCDESCONTO.TIPOGRUPOREST,'CL',pi_nCodCli,
                                                                                                                                   'GR',pi_nCodUsur))))                            
                              --AND ((NVL(TIPOFV,'TL') = pi_vTipoFv ))
                              AND ((nvl(nvl(pcdesconto.tipovenda,pcdesconto.tipofv),'TL') = pi_vTipoFv)) -- DDMEDICA-641 - CrossDocking ou Avaria (p_tipofv = PC ou PA)
                              AND (CASE WHEN APLICADESCSIMPLESNACIONAL IN ('S', 'N') THEN APLICADESCSIMPLESNACIONAL ELSE NVL(vvSimplesNacional, 'T') END = NVL(vvSimplesNacional, 'T'))
                              -- HIS.02239.2018 - Condição para Mandatório
                              AND (
                                     (NVL(PCPROMOCAOMED.PRAZOPLPAGMANDATORIO,'N') = 'S') OR
                                     (    (NVL(PCPROMOCAOMED.PRAZOPLPAGMANDATORIO,'N') <> 'S')                              
                                           AND ( ( ( NVL( APENASPLPAGMAX, 'S' ) = 'N' ) AND ( ( SELECT PCPLPAG.NUMDIAS FROM PCPLPAG WHERE CODPLPAG = NVL(PCDESCONTO.CODPLPAG, pi_nCodPlPag) ) >= vnNumDias ) )
                                            OR ( ( NVL( APENASPLPAGMAX, 'S' ) = 'S' ) AND ( ( NVL(CODPLPAG, pi_nCodPlPag) = pi_nCodPlPag ) ) ) )    )
                                  )
                            /*
                            UNION
                           SELECT DISTINCT 
                                  PCDESCONTO.CODPROMOCAOMED
                             FROM PCDESCONTO
                                , PCPROMOCAOMED
                            WHERE (PCPROMOCAOMED.CODPROMOCAOMED = PCDESCONTO.CODPROMOCAOMED)
                              AND (CODCLI = vnCodCliPrinc)
                              AND (TRUNC(pi_dData) BETWEEN dtinicio AND dtfim)
                              AND (NVL(PCDESCONTO.UTILIZADESCREDE, 'N') = 'S')
                              AND ((CODUSUR = pi_nCodUsur) OR (CODUSUR IS NULL))
                              AND ((CODSUPERVISOR = vnCodSupervisor) OR (CODSUPERVISOR IS NULL))
                              AND ((NUMREGIAO = pi_nNumRegiao) OR (NUMREGIAO IS NULL))
                              AND ((CODATIV = vnCodAtv1) OR (CODATIV IS NULL))
                              AND ((ORIGEMPED = pi_vOrigemPed) OR (NVL(ORIGEMPED, 'O') = 'O'))
                              AND ((CODPRACA = vnCodPraca) OR (CODPRACA IS NULL))
                              AND ((CLASSEVENDA = vvClasseVenda) OR (CLASSEVENDA IS NULL))
                              AND ((AREAATUACAO = vvAreaAtuacao) OR (AREAATUACAO IS NULL))
                              AND ((CODFILIAL  = pi_vCodFilial) OR (CODFILIAL IS NULL))    
                              AND ((CODREDE = vnCodRede) OR (CODREDE IS NULL))
                              -- HIS.01889.2017
                              AND ((PCDESCONTO.TIPOGRUPOREST IS NULL) OR 
                                   (PCDESCONTO.TIPOGRUPOREST = 'GP' ) OR -->> Colocado para não deixar de trazer os registros com Filtro de Grupo de Produtos
                                   (PCDESCONTO.CODGRUPOREST  = (SELECT PCGRUPOSCAMPANHAI.CODGRUPO
                                                                 FROM PCGRUPOSCAMPANHAI
                                                                WHERE PCGRUPOSCAMPANHAI.DTEXCLUSAO IS NULL
                                                                  AND PCGRUPOSCAMPANHAI.CODGRUPO = PCDESCONTO.CODGRUPOREST
                                                                  AND PCGRUPOSCAMPANHAI.CODITEM  = DECODE(PCDESCONTO.TIPOGRUPOREST,'CL',pi_nCodCli,
                                                                                                                                   'GR',pi_nCodUsur))))                            
                              --AND ((NVL(TIPOFV,'TL') = pi_vTipoFv ))
                              AND ((nvl(nvl(pcdesconto.tipovenda,pcdesconto.tipofv),'TL') = pi_vTipoFv)) -- DDMEDICA-641 - CrossDocking ou Avaria (p_tipofv = PC ou PA)
                              AND (CASE WHEN APLICADESCSIMPLESNACIONAL IN ('S', 'N') THEN APLICADESCSIMPLESNACIONAL ELSE NVL(vvSimplesNacional, 'T') END = NVL(vvSimplesNacional, 'T'))
                              -- HIS.02239.2018 - Condição para Mandatório
                              AND (
                                     (NVL(PCPROMOCAOMED.PRAZOPLPAGMANDATORIO,'N') = 'S') OR
                                     (    (NVL(PCPROMOCAOMED.PRAZOPLPAGMANDATORIO,'N') <> 'S')                              
                                           AND ( ( ( NVL( APENASPLPAGMAX, 'S' ) = 'N' ) AND ( ( SELECT PCPLPAG.NUMDIAS FROM PCPLPAG WHERE CODPLPAG = NVL(PCDESCONTO.CODPLPAG, pi_nCodPlPag) ) >= vnNumDias ) )
                                            OR ( ( NVL( APENASPLPAGMAX, 'S' ) = 'S' ) AND ( ( NVL(CODPLPAG, pi_nCodPlPag) = pi_nCodPlPag ) ) ) )    )
                                  )
                              */
                              ) LOOP
                                  
        -- Pesquisa Dados da Promoção
        BEGIN
          SELECT DESCRICAORESUMIDA
               , TIPOPROMOCAO
               , TIPOPOLITICA
               , NVL(BLOQUEIO,'N')
               , NVL(VISUALIZARPROMOESP,'N')
               , NVL(PRAZOPLPAGMANDATORIO,'N') -- HIS.02239.2018
            INTO vvDescricaoResumida
               , vvTipoPromocao
               , vvTipoPolitica
               , vvBloqueio
               , vvVisualizaPromoEsp
               , vvPrazoPlPagMandatorio -- HIS.02239.2018
            FROM PCPROMOCAOMED
           WHERE (CODPROMOCAOMED = vc_Promocoes.CODPROMOCAOMED);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvDescricaoResumida    := NULL;    
            vvTipoPromocao         := NULL;    
            vvTipoPolitica         := NULL;
            vvVisualizaPromoEsp    := NULL;
            vvPrazoPlPagMandatorio := NULL; -- HIS.02239.2018
        END;
        
        -- Plano de Pagamento com tratamento para o Prazo Mandatório da Promoção - HIS.02239.2018
        vnCodPlpag := pi_nCodPlPag;
        IF (vvPrazoPlPagMandatorio = 'S') THEN
          BEGIN
            SELECT CODPLPAG
             INTO vnCodPlpag
             FROM PCDESCONTO
            WHERE (CODPROMOCAOMED = vc_Promocoes.CODPROMOCAOMED) -->> Promoção do Laço
              AND (ROWNUM = 1);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
             vnCodPlpag := pi_nCodPlPag;
          END;
        END IF;    
        
        -- Se Usar Normalização da PCDESCONTO a Função FCT_MED_PODECOMPRARPROMOCAO retornará se Promoção Válida
        IF (FCT_MED_PODECOMPRARPROMOCAO(vc_Promocoes.CODPROMOCAOMED,
                                        pi_vCodFilial,
                                        vnCodCliPrinc,
                                        pi_nNumRegiao,
                                        pi_nCodUsur,
                                        vnCodPlpag, -- HIS.02239.2018
                                        pi_nCodCondicaoVenda,
                                        pi_vOrigemPed,
                                        pi_vTipoFv,
                                        pi_dData) = 'S') THEN
    
          -- Se Politica de Desconto ou Preço Fixo
          -- E não for Promoção de Produtos de mesma Família
          -- (Com relação TipoPromocao = 'K' não estar nesta condição, 
          -- quando chamado para carregar as Promoções de Cabeçalho, 
          -- no Delphi o Select do Combobox tem a condição: TipoPromocao <> 'K',
          -- quando chamado para carregar as Promoções de Kit (Inserir Kit), no Delphi
          -- o Select do ComboBox tem a condição: TipoPromocao = 'K'
          -- HIS.01152.2015 - Adicionado para não carregar para seleção na promoção principal e no combo o tipo S - Casadinha
          IF ((NVL(vvUsaPromoFaixaQtdePrincipal,'N')  = 'S') AND (NVL(vvTipoPolitica,' ') IN ('D','P','Q','F','M'))) OR
             ((NVL(vvUsaPromoFaixaQtdePrincipal,'N') <> 'S') AND (NVL(vvTipoPolitica,' ') IN ('D','P','M'))) or 
             ((NVL(vvTipoPromocao,' ') in ('K')) AND (NVL(vvTipoPolitica,' ') IN ('Q'))) THEN
            IF (NVL(vvTipoPromocao,' ') NOT IN ('F','S')) THEN
      
              IF (vvBloqueio = 'N') OR 
                 ((vvBloqueio = 'S') AND (pi_vVisualizarPromoBloq = 'S')) THEN
               
                IF (vvVisualizaPromoEsp = 'N') OR 
                   ((vvVisualizaPromoEsp = 'S') AND (pi_vVisualizarPromoEsp = 'S')) THEN
               
                  INSERT INTO PCMED_SEL_PROMO_CLI
                            ( CODPROMOCAOMED
                            , DESCRICAORESUMIDA
                            , TIPOPROMOCAO )
                     VALUES ( vc_Promocoes.CODPROMOCAOMED
                            , vvDescricaoResumida
                            , vvTipoPromocao );
                          
                END IF;  
        
              END IF;  
            END IF;  -- vvUsaPromoFaixaQtdePrincipal
            
          END IF;                
          
        END IF; -- FIM CONDIÇÃO: (FCT_MED_PODECOMPRARPROMOCAO = 'S')
                  
      END LOOP;    
    
    END IF; -- FIM CONDIÇÃO: SE PROMOÇÃO NORMALIZADA
    
    -- PESQUISA PROMOÇÕES PARA CALCULO DO MAIOR DESCONTO
    --IF (vEXIBIRMAIORPERCDESCPSQPRODUTO = 'S') THEN
    -- HIS.02239.2018 - Por causa do novo filtro de promoção na 2316, deve alimentar sempre a Tabela Temporária
    IF (vvUsaNormalizacaoDesc = 'S') THEN
      FOR vc_Promocoes IN (SELECT CODPROMOCAOMED
                             FROM PCPROMOCAOMED
                            WHERE (TRUNC(pi_dData) BETWEEN DATAINICIAL AND DATAFINAL)
                              ) LOOP
    
        -- Pesquisa Dados da Promoção
        BEGIN
          SELECT DESCRICAORESUMIDA
               , TIPOPROMOCAO
               , TIPOPOLITICA
               , NVL(BLOQUEIO,'N')
               , NVL(VISUALIZARPROMOESP,'N')
               , NVL(PRAZOPLPAGMANDATORIO,'N') -- HIS.02239.2018
            INTO vvDescricaoResumida
               , vvTipoPromocao
               , vvTipoPolitica
               , vvBloqueio
               , vvVisualizaPromoEsp
               , vvPrazoPlPagMandatorio -- HIS.02239.2018
            FROM PCPROMOCAOMED
           WHERE (CODPROMOCAOMED = vc_Promocoes.CODPROMOCAOMED);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvDescricaoResumida    := NULL;    
            vvTipoPromocao         := NULL;    
            vvTipoPolitica         := NULL;
            vvVisualizaPromoEsp    := NULL;
            vvPrazoPlPagMandatorio := NULL; -- HIS.02239.2018
        END;

        -- Plano de Pagamento com tratamento para o Prazo Mandatório da Promoção - HIS.02239.2018
        vnCodPlpag := pi_nCodPlPag;
        IF (vvPrazoPlPagMandatorio = 'S') AND
           (vvUsaNormalizacaoDesc  = 'S') THEN
          BEGIN
            SELECT CODPLPAG
             INTO vnCodPlpag
             FROM PCPROMOCAOPLPAGMED
            WHERE (PCPROMOCAOPLPAGMED.CODPROMOCAOMED = vnCodPromocaoMed)
              AND (ROWNUM = 1);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
             vnCodPlpag := pi_nCodPlPag;
          END;
        END IF;    
    
        -- Se Usar Normalização da PCDESCONTO a Função FCT_MED_PODECOMPRARPROMOCAO retornará se Promoção Válida
        IF (FCT_MED_PODECOMPRARPROMOCAO(vc_Promocoes.CODPROMOCAOMED,
                                        pi_vCodFilial,
                                        vnCodCliPrinc,
                                        pi_nNumRegiao,
                                        pi_nCodUsur,
                                        vnCodPlpag, -- HIS.02239.2018
                                        pi_nCodCondicaoVenda,
                                        pi_vOrigemPed,
                                        pi_vTipoFv,
                                        pi_dData) = 'S') THEN
    
          IF (vvBloqueio = 'N') OR 
             ((vvBloqueio = 'S') AND (pi_vVisualizarPromoBloq = 'S')) THEN
               
            IF (vvVisualizaPromoEsp = 'N') OR 
               ((vvVisualizaPromoEsp = 'S') AND (pi_vVisualizarPromoEsp = 'S')) THEN
               
              INSERT INTO PCMED_PROMO_CLI
                        ( CODPROMOCAOMED )
                 VALUES ( vc_Promocoes.CODPROMOCAOMED );
                          
            END IF;  
        
          END IF;  
            
        END IF; -- FIM CONDIÇÃO: (FCT_MED_PODECOMPRARPROMOCAO = 'S')
                  
      END LOOP;      
    END IF; -- (vEXIBIRMAIORPERCDESCPSQPRODUTO = 'S')

  END IF; -- (NVL(pi_vSomentePromoPadrao,'N') = 'S')
  
  -- Parâmetro Informar Promoção nos Itens não estiver ativada, não apresenta a promoção 999999999
  IF (vSELPROMOMEDSOMENTEITENS <> 'S') THEN
    DELETE FROM PCMED_PROMO_CLI WHERE CODPROMOCAOMED = 999999999;
    DELETE FROM PCMED_SEL_PROMO_CLI WHERE CODPROMOCAOMED = 999999999;
  END IF;
  
  -- Efetiva Transações
  IF (pi_vExecutaCommit = 'S') THEN
    COMMIT;
  END IF;     

EXCEPTION
  WHEN OTHERS THEN  
    po_vMsgErros := 'S';
    po_vMsgErros := SQLERRM;
END PRC_MED_OBTEM_SEL_PROMO_CLI;