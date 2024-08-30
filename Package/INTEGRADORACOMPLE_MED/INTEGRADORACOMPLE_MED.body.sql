CREATE OR REPLACE PACKAGE BODY INTEGRADORACOMPLE_MED
/***********************************************************************************************
  Complemento da Package de Integracao do Winthor com Sistemas de Forca de Vendas - MEDICAMENTOS  
+++++++++++++++++++++++++++++++++++++++++++++++++++++
  04/02/2021  Anderson Silva DDMEDICA-5511 - Restrição da Condição
  16/03/2020  Anderson Silva DDMEDICA-5980 - Promoção de Makup na Integração SERVCON
  ----------------     Historico     ----------------
  Data        Responsável    Tarefa     Comentario
  27/02/2018  Anderson Silva MED-869    Primeira Versao - (alteracoes iniciais)
  28/08/2018  Anderson Silva MED-1554   Faixa de Quantidade na 561
  05/09/2018  Anderson Silva MED-1645   Desconto Financeiro da 561
  02/09/2018  Anderson Silva            Taxa Frete
  14/09/2018  Anderson Silva  Tratamento Lock Estoque
  13/11/2018  Anderson Silva  MED-1499  Melhora Mensagens
  21/11/2018  Anderson Silva            Merge - Rejeitar Itens Fora de Linha sem Estoque Gerencial
  05/01/2019  Anderson Silva MED-2079   Validação Margem Mínima
  24/01/2019  Anderson Silva MED-2161   Alteração forma gravar os motivos
  22/03/2019  Anderson Silva MED-2270  Cálculo Custo pela própria integradora
  14/05/2019  Anderson Silva MED-2574   Ignorar Parâmetro Desconto Máximo da 132
  19/05/2019  Anderson Silva 4493.055952.2019 - Promoção de Markup
  29/08/2019  Anderson Silva DDMEDICA-675 Função para validação restrição de filial no plano
  12/09/20019 Anderson Silva DDMEDICA-706 Otimização Obter Desconto Integradora
  16/09/2019  Anderson Silva DDMEDICA-800 Validação Desc. Médio Pedido
  05/11/2019  Jorge Humberto DDMEDICA-1245 Incluído a validação da data de vencimento do limite de crédito do cliente
  23/12/2019  Anderson Silva DDMEDICA-1654 Procedimento para retornar a transportadora da frequência de entrega
  14/01/2019  Jorge Humberto DDMEDICA-1733 Nas promoções que tiverem utilizando o campo UTILIZADESCREDE = 'S' , considerar também a promoção para o cliente principal do cliente,
  que tiver selecionado
  20/01/2019  Anderson Silva DDMEDICA-1835 Grupo de Comissão na Integradora
  20/02/2020  Anderson Silva DDMEDICA-2225 Chamar a Integradora
  02/03/2020  Anderson Silva DDMEDICA-2296 Balcão Reserva pelo Força de Vendas
  11/05/2020  Anderson Silva DDMEDICA-2858 - Ajuste pesquisa promoção com cliente principal
  15/05/2020  Anderson Silva DDMEDICA-2832 - Regra Específica para Cálculo ST Pacote
  28/05/2020  Anderson Silva DDMEDICA-3017 - Parâmetro para não validar prazo médio do pedido no OL e PE
  05/06/2020  Anderson Silva DDMEDICA-3001 - Opção para Desconsiderar Repasse na Base do Desconto Isenção ICMS
  29/07/2020  Anderson Silva DDMEDICA-3464 - Restrição por Valor Mínimo 391
  05/08/2020  Anderson Silva DDMEDICA-3551 - Log do Limite de Crédito
  15/09/2020  Anderson Silva DDMEDICA-4013 - Filtro de Tipo de Venda e Multi-seleção na Rebaixa de CMV
  08/12/2020  Anderson Silva DDMEDICA-5009 - Ler Verba Rebaixa CMV da Promoção
  19/03/2021  Anderson Silva DDMEDICA-6036 - Limite Sazonal da Rotina 3321 e garantir Código da Distribuição do Pedido conforme Produto - 30.1.10

  06/04/2021  Anderson Silva DDMEDICA-6249 - Plano de Pagamento do Item na Validação da Promoção com Grupo Faturamento
  15/06/2021  Anderson Silva DDMEDICA-6841 - Cálculo Promoção Markup por Faixa de Quantidade e Preço Fixo no Força de Vendas
  21/06/2021  Anderson Silva DDMEDICA-6837 - Promoção de Markup por Faixa de Quantidade e Preço Fixo no OL e PE
  21/06/2021  Anderson Silva DDMEDICA-6837 - Descontinuar a FCT_MED_OBTEM_DESC_OLPE usando a P_REL_OBTEM_DESC_OLPE
  01/09/2021  Anderson Silva - DDMEDICA-7478 - Filtro pelo coddesconto selecionado do FV
  01/07/2021  Lucas Rangel DDMEDICA-6883 - Alterado regra de semaforo para importação de pedidos na integradora (FUNCTION PERMITE_IMPORTAR_PEDIDO_FV)
  09/09/2021  Anderson Silva DDMEDICA-7545 - Trava de Importação Duplicada de Pedidos de OL e PE
  29/10/2021  Anderson Silva DDVENDAS-31504 - Parametrizações do SERVCON
  14/12/2021  Anderson Silva DDVENDAS-32516 - Autorização Crédito com Cliente Principal
  09/02/2022  Anderson Silva DDVENDAS-33476 - Pesquisa da 561 por Grupo de Produto
  25/04/2022  Anderson Silva DDVENDAS-35125  Melhoria Referências Externas
  05/05/2022  Anderson Silva DDVENDAS-35272 - Priorização da Promoção da Oferta
  02/06/2022  Cassio Pardim  DDVENDAS-35581 - Utilização do campo PERDESCBOLETO sem a necessidade de gerar um CODPROMOCAOMED para o item do pedido
  20/06/2022  Cassio Pardim  DDVENDAS-36173 - Ajuste para validar o campo PERDESCBOLETO
  30/09/2022  Cleber Vicente DDVENDAS-37499 - Bloquear Pedidos Duplicados durante um determinado tempo(dia/hora/mint) 
  03/11/2022  Anderson Silva DDVENDAS-38538 - Serviço de Limite de Crédito
  01/12/2022  Anderson Silva DDVENDAS-38983 - Inclusão de CallCenter na pesquisa de promoção
  04/01/2023  Anderson Silva DDVENDAS-39681 - Ajuste na pesquisa de políticas por grupo de produtos da 561 no OL
  03/03/2024  Anderson Silva DDVENDAS-46442 - RCA do Cliente por Linha e Filial
 ************************************************************************************************/
IS PRAGMA SERIALLY_REUSABLE;

 /*****************************************
  Controle de Versionamento
  -----------------------------------------
  Issue                 Versão
  DDVENDAS-35581        v@31.1.2
  DDVENDAS-38983        v@33.0.1
  DDVENDAS-39681        v@33.0.2
  DDVENDAS-46442        v@35.0.1
  *****************************************/
  FUNCTION F_OBTER_VERSIONAMENTO RETURN VARCHAR2 IS
    vvVersao VARCHAR2(10);
  BEGIN
  
    -->> *** A CADA ALTERAÇÃO INCREMENTAR AQUI A VERSÃO ***
    vvVersao := 'v@35.0.1';
  
    RETURN 'MED_' || vvVersao;
    
  END F_OBTER_VERSIONAMENTO;

 /***********************************************************************************************
  PROCEDURE: proc_recompilar
  DESCRIÇÃO: Garantir a Recompilação
  ***********************************************************************************************/
  PROCEDURE proc_recompilar IS
    vdDataAtual DATE;
  BEGIN
    BEGIN
      SELECT SYSDATE
        INTO vdDataAtual
        FROM DUAL;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vdDataAtual := NULL;
    END;
  END proc_recompilar;

 /***********************************************************************************************
  FUNÇÃO...: FFORMATAR_NUMERO_PARA_TEXTO
  DESCRIÇÃO: Função para Formatar um Número para Texto
  ***********************************************************************************************/
  FUNCTION FFORMATAR_NUMERO_PARA_TEXTO(pi_nNumero            IN NUMBER,
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

    -- Finaliza a Máscara da Parte Inteira
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

  END FFORMATAR_NUMERO_PARA_TEXTO;

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

 /***********************************************************************************************
  PROCEDURE: func_gerarlogjson
  DESCRIÇÃO: Gerar Log no Formato JSON MED-1499
  ***********************************************************************************************/
  FUNCTION func_gerarlogjson(pi_vDescricaoRejeicao IN VARCHAR2,
                             pi_vObservacao        IN VARCHAR2,
                             pi_vCodRotina         IN VARCHAR2,
                             pi_nNumeroParametro   IN VARCHAR2,
                             pi_vPermissao         IN VARCHAR2,
                             pi_vSolucao           IN VARCHAR2)
  RETURN VARCHAR2 IS
    -- Retorno
    vvRetJson VARCHAR2(32000);
  BEGIN

    -- Monta Json
    vvRetJson := '{ ' || '"DESCRICAOREJEICAO": "' || pi_vDescricaoRejeicao || '", ' ||
                         '"OBSERVACAO": "'        || pi_vObservacao        || '", ' ||
                         '"CODROTINA": "'         || pi_vCodRotina         || '", ' ||
                         '"NUMEROPARAMETRO": "'   || pi_nNumeroParametro   || '", ' ||
                         '"PERMISSAO": "'         || pi_vPermissao         || '", ' ||
                         '"SOLUCAO": "'           || pi_vSolucao           || '" }';

    -- Retorno
    RETURN vvRetJson;

  END func_gerarlogjson;

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

  ------------------------------------------------------------------------------
  -- Funcao para Obter Regra Especifica de Medicamentos --
  --------------------------------------------------------
  FUNCTION FOBTER_REGRA_MEDICAMENTOS(pi_vCodFilial IN VARCHAR2,
                                     pi_vNome      IN VARCHAR2)
  RETURN VARCHAR2 IS
    vvRetRegraMedicamentos PCREGRASEXCECAOMED.VALOR%TYPE;
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
  END FOBTER_REGRA_MEDICAMENTOS;

  ------------------------------------------------------------------------------
  -- Função para retornar o Parâmetro da Integradora
  -- MED-861
  -------------------------------------------------------------------
  FUNCTION FOBTEM_PARAM_INTEGRADORA(pi_nIntegradora  IN NUMBER,
                                    pi_vNome         IN VARCHAR2,
                                    pi_vValorDefault IN VARCHAR2)
  RETURN VARCHAR2 IS
    vvRetParamIntegradora PCPARAMINTEGRADORAMED.VALOR%TYPE;
  BEGIN

    -- Pesquisa Parâmetro
    BEGIN
      SELECT NVL(PCPARAMINTEGRADORAMED.VALOR,pi_vValorDefault)
        INTO vvRetParamIntegradora
        FROM PCPARAMINTEGRADORAMED
       WHERE (PCPARAMINTEGRADORAMED.NOME        = pi_vNome)
         AND (PCPARAMINTEGRADORAMED.INTEGRADORA = pi_nIntegradora);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvRetParamIntegradora := pi_vValorDefault;
    END;

    -- Retorno
    RETURN vvRetParamIntegradora;

  END FOBTEM_PARAM_INTEGRADORA;

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- PROCEDURE: proc_validarestricao_servcon
  -- DESCRIÇÃO: DDMEDICA-5511 - Validar a Restrição do SERVCON
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  PROCEDURE proc_validarestricao_servcon(pi_nCodCondicaoVenda  IN NUMBER,
                                         pi_nCodProd           IN NUMBER,
                                         pi_nQt                IN NUMBER,
                                         po_vRejeitado        OUT VARCHAR2,
                                         po_vMotivoRejeitado  OUT VARCHAR2,
                                         po_vObservacao       OUT VARCHAR2,
                                         po_vJsonRejeitado    OUT VARCHAR2) IS
                                         
    vnQtRestricao              NUMBER;                                         
    vvCodSistema               PCCONFIGSISTOPERLOG.CODSISTEMA%TYPE;
    vvDescricaoSistema         VARCHAR2(255);
    vvOrientacaoCondicaoNaoCad VARCHAR2(32000);
    vvDescricaoCondVenda       VARCHAR2(255);
  BEGIN
  
    -- Inicializa Retornos
    po_vRejeitado       := 'N';
    po_vMotivoRejeitado := NULL;
    po_vObservacao      := NULL;
    po_vJsonRejeitado   := NULL;

    -- Sistema SERVCON
    BEGIN
      SELECT CODSISTEMA
           , CODSISTEMA || ' - ' || DESCRICAO
        INTO vvCodSistema
           , vvDescricaoSistema
        FROM PCCONFIGSISTOPERLOG
       WHERE (PEDIDOELETRONICO = 'E')
         AND (ROWNUM           = 1);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvCodSistema       := NULL;
        vvDescricaoSistema := NULL;
    END;
    
    -- Se tem Integração SERVCON
    IF (vvCodSistema IS NOT NULL) THEN
    
      -- Pesquisa Se existe alguma restrição
      BEGIN
        EXECUTE IMMEDIATE 'SELECT 1 FROM PCMED_VIEWOLCONDVENDA_RESTPRO WHERE CODCONDICAOVENDA = ' || NVL(pi_nCodCondicaoVenda,0) || ' AND CODPROD = ' || NVL(pi_nCodProd,0) || ' AND CODSISTEMA = ' || '''' || vvCodSistema || '''' || ' AND ROWNUM = 1'
                     INTO vnQtRestricao;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnQtRestricao := 0;
        WHEN OTHERS THEN
          vnQtRestricao := 0;
      END;
      
      -- Se achou alguma Restrição
      IF (NVL(vnQtRestricao,0) > 0) THEN
      
        -- Verifica se a Quantidade está na Faixa da Restrição
        BEGIN
          EXECUTE IMMEDIATE 'SELECT 1 FROM PCMED_VIEWOLCONDVENDA_RESTPRO WHERE CODCONDICAOVENDA = ' || NVL(pi_nCodCondicaoVenda,0) || ' AND CODPROD = ' || NVL(pi_nCodProd,0) || ' AND ' || NVL(pi_nQt,0) || ' BETWEEN QTINICIAL AND QTFINAL AND CODSISTEMA = ' || '''' || vvCodSistema || '''' || ' AND ROWNUM = 1'
                       INTO vnQtRestricao;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnQtRestricao := 0;
          WHEN OTHERS THEN
            vnQtRestricao := 0;
        END;
        
        -- Se a Quantidade não está na Faixa
        IF (NVL(vnQtRestricao,0) = 0) THEN
        
          BEGIN
            SELECT CODCONDICAOVENDA || ' - ' || DESCRICAO
              INTO vvDescricaoCondVenda       
              FROM PCCONDICAOVENDA
             WHERE (CODCONDICAOVENDA = pi_nCodCondicaoVenda);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vvDescricaoCondVenda := NULL;
          END;
      
          po_vRejeitado       := 'S';
          po_vMotivoRejeitado := 'Quantidade fora da faixa de quantidade escalonada no pedido eletrônico.';
          po_vObservacao      := 'A quantidade vendida = ' || FFORMATAR_NUMERO_PARA_TEXTO(NVL(pi_nQt,0),0) || ' está fora da faixa de quantidade escalonada no Sistema de Pedido Eletrônico = "' || vvDescricaoSistema || '" e para a Condição de Venda = "' || vvDescricaoCondVenda || '"';
        
          vvOrientacaoCondicaoNaoCad := 'Acessar a Rotina 2323 e incluir o produto numa Promoção sem a faixa de quantidade liberada para a Condição de Venda "' || vvDescricaoCondVenda || '" ou deixar de utilizar a regra específica da rotina 2345 para rejeitar itens fora da faixa de quantidade no SERVCON: "REJEITARITEMFORAFAIXAPROMOQTPE"';
  
          po_vJsonRejeitado := func_gerarlogjson(po_vMotivoRejeitado,
                                                 po_vObservacao,
                                                 '2323, 2345, 2325',
                                                 NULL,
                                                 NULL,
                                                 vvOrientacaoCondicaoNaoCad);

        END IF;
      
      END IF; -- Fim: -- Se achou alguma Restrição
                 
    END IF; -- Fim: Se tem Integração SERVCON
        
  END proc_validarestricao_servcon;

 /******************************************************************
  PROCEDIMENTO PARA CONSULTAR O ACORDO DE PREÇO DO PEDIDO ELETRÔNICO
  ******************************************************************/
  PROCEDURE OBTER_ACORDO_SISTOPERLOG(pi_nIntegradora       IN NUMBER,
                                     pi_vCodFilial         IN VARCHAR2,
                                     pi_nNumRegiao         IN NUMBER,
                                     pi_nCodProd           IN NUMBER,
                                     po_vAchouAcordo       OUT VARCHAR2,
                                     po_nCodAcordo         OUT NUMBER,
                                     po_nCodPromocaoMed    OUT NUMBER,
                                     po_vTipoPromocao      OUT VARCHAR2,
                                     po_nPreco             OUT NUMBER,
                                     po_nPercDesc          OUT NUMBER,
                                     po_nVlDescCmv         OUT NUMBER,   -- DDMEDICA-5009
                                     po_nPerDescCmv        OUT NUMBER,   -- DDMEDICA-5009
                                     po_nNumVerba          OUT NUMBER,   -- DDMEDICA-5009
                                     po_nValorCotaNumVerba OUT NUMBER,   -- DDMEDICA-5009
                                     po_vSemVerbaVlDescCmv OUT VARCHAR2, -- DDMEDICA-5009
                                     po_vOcorreramErros    OUT VARCHAR2,
                                     po_vMsgErros          OUT VARCHAR2) IS

    -- SQL
    vvSql                           VARCHAR2(32000);  

    -- Tabelas para uso no BulkCollect
    TYPE TT_CODACORDO               IS TABLE OF NUMBER      INDEX BY BINARY_INTEGER; 
    TYPE TT_PRECO                   IS TABLE OF NUMBER      INDEX BY BINARY_INTEGER; 
    TYPE TT_PERCDESC                IS TABLE OF NUMBER      INDEX BY BINARY_INTEGER; 
    TYPE TT_CODPROMOCAOMED          IS TABLE OF NUMBER      INDEX BY BINARY_INTEGER; 
    TYPE TT_TIPOPROMOCAO            IS TABLE OF VARCHAR2(2) INDEX BY BINARY_INTEGER; 
    ------ 
    vtCODACORDO                     TT_CODACORDO;
    vtPRECO                         TT_PRECO;
    vtPERCDESC                      TT_PERCDESC;
    vtCODPROMOCAOMED                TT_CODPROMOCAOMED;
    vtTIPOPROMOCAO                  TT_TIPOPROMOCAO;

    -- Dados Registro
    TYPE TRecDadosRegistro          IS RECORD(
         CODACORDO                  NUMBER,
         PRECO                      NUMBER,
         PERCDESC                   NUMBER,
         CODPROMOCAOMED             NUMBER,
         TIPOPROMOCAO               VARCHAR2(2));
    vrDadosRegistro                 TRecDadosRegistro;
    
    -- Dados Retorno
    TYPE TRecDadosRetorno           IS RECORD(
         vvAchouAcordo              VARCHAR2(1),
         vnCodAcordo                NUMBER,
         vnCodPromocaoMed           NUMBER,
         vvTipoPromocao             VARCHAR2(2),
         vnPreco                    NUMBER,
         vnPercDesc                 NUMBER);         
    vrDadosRetorno                  TRecDadosRetorno;
    
    -- Controle de Verba - DDMEDICA-5009
    vvExisteVerba                   VARCHAR2(1);
    vnCodFornec                     PCPRODUT.CODFORNEC%TYPE;
         
  BEGIN

    -- INICIALIZA RETORNO
    vrDadosRetorno.vvAchouAcordo := 'N'; -->> Não Achou Acordo
    po_vAchouAcordo              := 'N';    
    po_vOcorreramErros           := 'N'; 
    po_vMsgErros                 := NULL; 
  
    -- Prepara Sql
    vvSql := ' SELECT PCACORDOPRODSISTOPERLOG.CODACORDO
                    , PCACORDOPRODSISTOPERLOG.PRECO
                    , PCACORDOPRODSISTOPERLOG.PERCDESC
                    , PCACORDOPRODSISTOPERLOG.CODPROMOCAOMED
                    , PCACORDOPRODSISTOPERLOG.TIPOPROMOCAO
                 FROM PCACORDOSISTOPERLOG
                    , PCACORDOPRODSISTOPERLOG
                WHERE (PCACORDOSISTOPERLOG.CODACORDO   = PCACORDOPRODSISTOPERLOG.CODACORDO)
                  AND (PCACORDOSISTOPERLOG.INTEGRADORA = ' || pi_nIntegradora               || ')
                  AND (PCACORDOSISTOPERLOG.CODFILIAL   = ' || '''' || pi_vCodFilial || '''' || ')
                  AND (PCACORDOSISTOPERLOG.NUMREGIAO   = ' || pi_nNumRegiao                 || ')
                  AND (TRUNC(SYSDATE) BETWEEN PCACORDOSISTOPERLOG.DATAINICIAL AND PCACORDOSISTOPERLOG.DATAFINAL)
                  AND (PCACORDOPRODSISTOPERLOG.CODPROD = ' || pi_nCodProd                   || ')
                  ORDER BY PCACORDOSISTOPERLOG.DTINCLUSAO DESC';
                    
    -- Insere Dados em Arrays
    EXECUTE IMMEDIATE vvSql
      BULK COLLECT INTO vtCODACORDO,
                        vtPRECO,
                        vtPERCDESC,
                        vtCODPROMOCAOMED,
                        vtTIPOPROMOCAO;
  
    -- Se achou Dados
    IF (vtCODACORDO.COUNT > 0) THEN
      -- Laço de Registros encontrados
      FOR viLaco IN vtCODACORDO.FIRST..vtCODACORDO.LAST LOOP
      
        -------------------------
        -- OBTEM DADOS DAS TABLES
        -------------------------

        vrDadosRegistro.CODACORDO      := vtCODACORDO(viLaco);
        vrDadosRegistro.PRECO          := vtPRECO(viLaco);
        vrDadosRegistro.PERCDESC       := vtPERCDESC(viLaco);
        vrDadosRegistro.CODPROMOCAOMED := vtCODPROMOCAOMED(viLaco);
        vrDadosRegistro.TIPOPROMOCAO   := vtTIPOPROMOCAO(viLaco);
              
        ---------------------------------------
        -- ATUALIZA DADOS RETORNO e SAI DO LAÇO
        ---------------------------------------
        
        vrDadosRetorno.vvAchouAcordo    := 'S'; -->> Achou Acordo
        vrDadosRetorno.vnCodAcordo      := vrDadosRegistro.CODACORDO;
        vrDadosRetorno.vnCodPromocaoMed := vrDadosRegistro.CODPROMOCAOMED;           
        vrDadosRetorno.vvTipoPromocao   := vrDadosRegistro.TIPOPROMOCAO;           
        vrDadosRetorno.vnPreco          := vrDadosRegistro.PRECO;           
        vrDadosRetorno.vnPercDesc       := vrDadosRegistro.PERCDESC;           
        EXIT; -->> Sai do Laço
      
      END LOOP; -- Fim: Laço de Registros encontrados
    END IF; -- Fim: Se achou Dados
        
    -- RETORNO DO PROCEDIMENTO
    po_vAchouAcordo    := vrDadosRetorno.vvAchouAcordo;
    po_nCodAcordo      := vrDadosRetorno.vnCodAcordo;
    po_nCodPromocaoMed := vrDadosRetorno.vnCodPromocaoMed;    
    po_vTipoPromocao   := vrDadosRetorno.vvTipoPromocao;  
    po_nPreco          := vrDadosRetorno.vnPreco;  
    po_nPercDesc       := vrDadosRetorno.vnPercDesc;  

    -----------------------------------------------
    -- RETORNO DE VERBA DA PROMOÇÃO - DDMEDICA-5009
    -----------------------------------------------

    -- Verifica se tem Verba na Promoção
    BEGIN
      SELECT 'S'
        INTO vvExisteVerba
        FROM PCPROMOCAOVERBAMED
       WHERE (CODPROMOCAOMED = vrDadosRetorno.vnCodPromocaoMed)
         AND (ROWNUM         = 1);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvExisteVerba := 'N';
    END;
    -- Se existe Verba
    IF (vvExisteVerba = 'S') THEN
      -- Pesquisa o Código do Fornecedor do Produto
      BEGIN
        SELECT CODFORNEC
          INTO vnCodFornec
          FROM PCPRODUT
         WHERE (CODPROD = pi_nCodProd);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnCodFornec := NULL;
      END;
      -- Procura a Verba na Promoção
      BEGIN
        SELECT PCDESCONTO.VLDESCCMVPROMOCAOMED
          INTO po_nVlDescCmv
          FROM PCDESCONTO
         WHERE (PCDESCONTO.CODPROMOCAOMED = vrDadosRetorno.vnCodPromocaoMed)
           AND (PCDESCONTO.CODPROD        = pi_nCodProd)
           AND (ROWNUM                    = 1);   
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          BEGIN
            SELECT PCDESCONTO.VLDESCCMVPROMOCAOMED
              INTO po_nVlDescCmv
              FROM PCDESCONTO
             WHERE (PCDESCONTO.CODPROMOCAOMED = vrDadosRetorno.vnCodPromocaoMed)
               AND (PCDESCONTO.TIPOGRUPOREST  = 'PR')
               AND (PCDESCONTO.CODGRUPOREST   = (SELECT PCGRUPOSCAMPANHAI.CODGRUPO
                                                   FROM PCGRUPOSCAMPANHAI
                                                  WHERE PCGRUPOSCAMPANHAI.DTEXCLUSAO IS NULL
                                                    AND PCGRUPOSCAMPANHAI.CODGRUPO = PCDESCONTO.CODGRUPOREST
                                                    AND PCGRUPOSCAMPANHAI.CODITEM  = pi_nCodProd))
               AND (ROWNUM = 1);             
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              po_nVlDescCmv := 0;
          END;
      END;
      -- Obter Verba Relacionada com o Valor da Verba para Rebaixa de CMV da Promoção da PCDESCONTO - DDMEDICA-5009
      PKG_PROMOCAO_MED.P_OBTER_VERBA_PROMOCAO(vrDadosRetorno.vnCodPromocaoMed,
                                              vnCodFornec,
                                              po_nVlDescCmv,
                                              po_nNumVerba,
                                              po_nValorCotaNumVerba,
                                              po_vSemVerbaVlDescCmv);
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      po_vOcorreramErros := 'S';
      po_vMsgErros       := 'Erros Acordo Preço PE: ' || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM,1,240);
  END OBTER_ACORDO_SISTOPERLOG;                                       

 /***********************************************************************************************
  PROCEDURE: proc_validaminplanosmed
  DESCRIÇÃO: Validar Valor Mínimo do Plano Ético e Genérico do Cliente - MED-869
  ***********************************************************************************************/
  PROCEDURE proc_validaminplanosmed (pi_nCodPlPagEtico     IN  NUMBER,
                                     pi_nCodPlPagGenerico  IN  NUMBER,
                                     pi_nNumPed            IN  NUMBER,
                                     po_vValido            OUT VARCHAR2,
                                     po_nCodMotivoNaoAtend OUT NUMBER,
                                     po_vMensagem          OUT VARCHAR2,
                                     po_vMsgErros          OUT VARCHAR2) IS

   vschar                  VARCHAR2(1) DEFAULT '#';

   vncontitenseticos       NUMBER;
   vnvltotitenseticos      NUMBER;
   vncontitensgenericos    NUMBER;
   vnvltotitensgenericos   NUMBER;
   vncontitensoutros       NUMBER;
   vnvltotitensoutros      NUMBER;

   vrDadosPlPagEticoPed    PCPLPAG%ROWTYPE;
   vrDadosPlPagGenericoPed PCPLPAG%ROWTYPE;

  BEGIN

    -- Inicializa Retorno
    po_vValido            := 'S';
    po_nCodMotivoNaoAtend := NULL;
    po_vMensagem          := NULL;
    po_vMsgErros          := NULL;

    -- Informações do Plano de Pagamento Ético e Genérico
    BEGIN
      SELECT PCPLPAG.*
        INTO vrDadosPlPagEticoPed
        FROM PCPLPAG
       WHERE (PCPLPAG.CODPLPAG = pi_nCodPlPagEtico);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
    BEGIN
      SELECT PCPLPAG.*
        INTO vrDadosPlPagGenericoPed
        FROM PCPLPAG
       WHERE (PCPLPAG.CODPLPAG = pi_nCodPlPagGenerico);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;

    -- Venda Produtos Éticos
    select count(*),sum(pcpedi.qt * pcpedi.pvenda)
    into vncontitenseticos,vnvltotitenseticos
    from pcpedi,pcprodut
    where numped = pi_nNumPed
    and   pcpedi.codprod = pcprodut.codprod
    and   pcprodut.grupofaturamento = 'E';

    -- Venda Produtos Genéricos
    select count(*),sum(pcpedi.qt * pcpedi.pvenda)
    into vncontitensgenericos,vnvltotitensgenericos
    from pcpedi,pcprodut
    where numped = pi_nNumPed
    and   pcpedi.codprod = pcprodut.codprod
    and   pcprodut.grupofaturamento in ('G','S');

    -- Venda outros Produtos
    select count(*),sum(pcpedi.qt * pcpedi.pvenda)
    into vncontitensoutros,vnvltotitensoutros
    from pcpedi,pcprodut
    where numped = pi_nNumPed
    and   pcpedi.codprod = pcprodut.codprod
    and   pcprodut.grupofaturamento not in('E','G','S');

    -- Soma outros Produto nos Totais de Éticos ou Genéricos baseado no Prazo Médio
    if vrDadosPlPagEticoPed.numdias <= vrDadosPlPagGenericoPed.numdias then

        vncontitenseticos  := nvl(vncontitenseticos,0) + nvl(vncontitensoutros,0);
        vnvltotitenseticos := nvl(vnvltotitenseticos,0) + nvl(vnvltotitensoutros,0);
    else
        vncontitensgenericos  := nvl(vncontitensgenericos,0) + nvl(vncontitensoutros,0);
        vnvltotitensgenericos := nvl(vnvltotitensgenericos,0) + nvl(vnvltotitensoutros,0);
    end if;


    -- VALIDAÇÃO - ETICOS ---------------------------------------------------------------------
    if vncontitenseticos <> 0 and vncontitenseticos < vrDadosPlPagEticoPed.numitensminimo then

         if po_vMensagem is not null then
           vschar := '#';
         else
           vschar := null;
         end if;

         po_vMensagem         := po_vMensagem || vschar || 'Numero de itens de medicamentos Eticos (' ||
                               vncontitenseticos || ') menor que o#';
         po_vMensagem         := po_vMensagem ||
                               'mínimo de itens (' || vrDadosPlPagEticoPed.numitensminimo || ') informado no plano de pagamento Etico: ' ||
                               vrDadosPlPagEticoPed.codplpag || ';';
         po_vValido := 'N';

         if po_nCodMotivoNaoAtend is null then
            po_nCodMotivoNaoAtend := 35;
         end if;


    end if;

    if vnvltotitenseticos <> 0 and vnvltotitenseticos < vrDadosPlPagEticoPed.vlminpedido then


         po_vValido := 'N';

         if po_nCodMotivoNaoAtend is null then
            po_nCodMotivoNaoAtend := 34;
         end if;


         if po_vMensagem is not null then
           vschar := '#';
         else
           vschar := null;
         end if;

         po_vMensagem         := po_vMensagem || vschar || 'Valor no pedido de itens de medicamentos Eticos (' ||
                               vnvltotitenseticos || ') menor que o#';
         po_vMensagem         := po_vMensagem ||
                               'valor mínimo (' || vrDadosPlPagEticoPed.vlminpedido || ') informado no plano de pagamento Etico: ' ||
                               vrDadosPlPagEticoPed.codplpag || ';';


    end if;

    -- VALIDAÇÃO - GENERICOS --------------------------------------------------------------------
    if vncontitensgenericos <> 0 and vncontitensgenericos < vrDadosPlPagGenericoPed.numitensminimo then

         if po_vMensagem is not null then
           vschar := '#';
         else
           vschar := null;
         end if;

         po_vMensagem         := po_vMensagem || vschar || 'Numero de itens de medicamentos Genericos (' ||
                               vncontitensgenericos || ') menor que o#';
         po_vMensagem         := po_vMensagem ||
                               'mínimo de itens (' || vrDadosPlPagGenericoPed.numitensminimo || ') informado no plano de pagamento Generico: ' ||
                               vrDadosPlPagGenericoPed.codplpag || ';';

         po_vValido := 'N';

         if po_nCodMotivoNaoAtend is null then
            po_nCodMotivoNaoAtend := 35;
         end if;


       end if;

       if vnvltotitensgenericos <> 0 and vnvltotitensgenericos < vrDadosPlPagGenericoPed.vlminpedido then


         po_vValido := 'N';

         if po_nCodMotivoNaoAtend is null then
            po_nCodMotivoNaoAtend := 34;
         end if;


         if po_vMensagem is not null then
           vschar := '#';
         else
           vschar := null;
         end if;

         po_vMensagem         := po_vMensagem || vschar || 'Valor no pedido de itens de medicamentos Genericos (' ||
                               vnvltotitensgenericos || ') menor que o#';
         po_vMensagem         := po_vMensagem ||
                               'valor mínimo (' || vrDadosPlPagGenericoPed.vlminpedido || ') informado no plano de pagamento Generico: ' ||
                               vrDadosPlPagGenericoPed.codplpag || ';';


    end if;

  EXCEPTION
    WHEN OTHERS THEN
      po_vValido   := 'N';
      po_vMensagem := 'Erro ao validar valor mínimo planos de pagto Medicamentos : '||sqlcode || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || '->' || SQLERRM;
      po_vMsgErros := 'Erro ao validar valor mínimo planos de pagto Medicamentos : '||sqlcode || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || '->' || SQLERRM;
  END proc_validaminplanosmed;

 /************************************************************************
  FUNÇÕES DE OBTER POLÍTICAS DE DESCONTO MED (retiradas das FUNCOESVENDAS)
  * Contemplando a faixa de quantidade da 561 - MED-1554
  * Filtro pelo coddesconto selecionado do FV - DDMEDICA-7478
  ************************************************************************/
  FUNCTION validarpoliticasdesconto_med -- 28 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_param                    IN NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 IN OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_perdescfin               OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_creditasobrepolitica     OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER,
   p_alteraptabela            OUT VARCHAR2,
   p_pbaserca                 OUT NUMBER,
   p_prioritaria              out varchar2,
   p_questionausoprioritaria  out varchar2,
   p_naousarautdebcredpoldesc IN varchar2 default 'N',
   p_usadescfinseparadodesccom IN varchar2,
   p_param2                    IN number,
   p_qt                        IN NUMBER,
   p_coddescontofv             IN NUMBER) RETURN BOOLEAN IS

    vbresult           BOOLEAN;
    vncodpolbaserca    NUMBER;

  BEGIN

    vbresult := validarpoliticasdesconto_med(p_codprod,
                                             p_data,
                                             p_codfilial,
                                             p_numregiao,
                                             p_codcli,
                                             p_codusur,
                                             p_origempedido,
                                             p_codprodprinc,
                                             p_numcasasdecvenda,
                                             p_codplpag,
                                             p_tratarrestricaoacrescimo,
                                             p_classevenda,
                                             p_aplicadesconto,
                                             0, --p_numdias,
                                             p_dtfim,
                                             p_mensagem,
                                             p_perdesc,
                                             p_perdescfin,
                                             p_basecreddebrca,
                                             p_creditasobrepolitica,
                                             p_perdescrestricao,
                                             p_alteraptabela,
                                             p_pbaserca,
                                             p_prioritaria,
                                             p_questionausoprioritaria,
                                             p_naousarautdebcredpoldesc,
                                             p_usadescfinseparadodesccom,
                                             p_param2,
                                             vncodpolbaserca,
                                             p_qt,
                                             p_coddescontofv
                                            );

    RETURN vbresult;

  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Politica de Descontos: ' || SQLERRM;
      RETURN FALSE;

  END validarpoliticasdesconto_med;

  FUNCTION validarpoliticasdesconto_med -- 29 parametros
  (p_codprod                  IN NUMBER,
   p_data                     IN DATE,
   p_codfilial                IN VARCHAR2,
   p_numregiao                IN NUMBER,
   p_codcli                   IN NUMBER,
   p_codusur                  IN NUMBER,
   p_origempedido             IN VARCHAR2,
   p_codprodprinc             IN NUMBER,
   p_numcasasdecvenda         IN NUMBER,
   p_codplpag                 IN NUMBER,
   p_tratarrestricaoacrescimo IN pcconsum.tratarrestricaoacrescimo%TYPE,
   p_classevenda              IN pcclient.classevenda%TYPE,
   p_aplicadesconto           IN NUMBER,
   p_numdias                  IN NUMBER,
   p_dtfim                    OUT DATE,
   p_mensagem                 IN OUT VARCHAR2,
   p_perdesc                  OUT NUMBER,
   p_perdescfin               OUT NUMBER,
   p_basecreddebrca           OUT VARCHAR2,
   p_creditasobrepolitica     OUT VARCHAR2,
   p_perdescrestricao         OUT NUMBER,
   p_alteraptabela            OUT VARCHAR2,
   p_pbaserca                 OUT NUMBER,
   p_prioritaria              out varchar2,
   p_questionausoprioritaria  out varchar2,
   p_naousarautdebcredpoldesc IN varchar2 default 'N',
   p_usadescfinseparadodesccom IN varchar2,
   p_param2                   IN number,
   p_codpolbaserca            out number,
   p_qt                        IN NUMBER,
   p_coddescontofv             IN NUMBER) RETURN BOOLEAN IS

    CURSOR c_principal(vncodepto IN NUMBER, vncodsec IN NUMBER, vncodcategoria IN NUMBER, vncodfornec IN NUMBER, vncodsupervisor IN NUMBER, vncodatv1 IN NUMBER, vncodpraca IN NUMBER, vsaplicadesconto IN VARCHAR2, vsareaatuacao IN VARCHAR2, vssimplesnacional IN varchar2,
                     vncodrede IN number , vncodmarca IN number, vncodcliprinc IN number) IS
      SELECT decode(p_usadescfinseparadodesccom,'S',nvl(percdesc,0),(nvl(percdesc,0) + nvl(percdescfin,0))) percdesc,
             nvl(basecreddebrca, 'N') basecreddebrca,
             dtfim,
             nvl(creditasobrepolitica, 'S') creditasobrepolitica,
             pcdesconto.dtinicio,
             pcdesconto.coddesconto,
             pcdesconto.alteraptabela,
             pcdesconto.prioritaria,
             pcdesconto.questionausoprioritaria,
             decode(p_usadescfinseparadodesccom,'S',nvl(pcdesconto.percdescfin,0),0) percdescfin,
             NVL(PCDESCONTO.PRIORITARIAGERAL,'N') PRIORITARIAGERAL,
             (nvl(percdesc,0) + nvl(percdescfin,0)) percdesctotal -- MED-1645
        FROM pcdesconto,pcplpag
       WHERE p_data BETWEEN pcdesconto.dtinicio AND pcdesconto.dtfim
         --AND nvl(pcdesconto.utilizadescrede, 'N') = 'N'
         --AND ((pcdesconto.codcli = p_codcli) OR (pcdesconto.codcli IS NULL))
         --DDMEDICA-1733
         AND ( ((nvl(pcdesconto.utilizadescrede, 'N') = 'S') AND (codcli IN (p_codcli,vncodcliprinc))) OR
               ((nvl(pcdesconto.utilizadescrede, 'N') = 'N') AND (codcli  = p_codcli))       OR
               (codcli IS NULL) )
         AND ((pcdesconto.codepto = vncodepto) OR (pcdesconto.codepto IS NULL))
         AND ((pcdesconto.codsec = vncodsec) OR (pcdesconto.codsec IS NULL))
         AND ((pcdesconto.codcategoria = vncodcategoria) OR (pcdesconto.codcategoria IS NULL))
         AND ((pcdesconto.codprod = p_codprod) OR (pcdesconto.codprod IS NULL))
         AND ((pcdesconto.codfornec = vncodfornec) OR (pcdesconto.codfornec IS NULL))
         AND ((pcdesconto.codusur = p_codusur) OR (pcdesconto.codusur IS NULL))
         AND ((pcdesconto.codsupervisor = vncodsupervisor) OR (pcdesconto.codsupervisor IS NULL))
         AND ((pcdesconto.numregiao = p_numregiao) OR (pcdesconto.numregiao IS NULL))
         AND ((pcdesconto.codativ = vncodatv1) OR (pcdesconto.codativ IS NULL))
         AND ((pcdesconto.origemped = p_origempedido) OR (nvl(pcdesconto.origemped, 'O') = 'O'))
         AND ((pcdesconto.codpraca = vncodpraca) OR (pcdesconto.codpraca IS NULL))
         AND ((pcdesconto.codprodprinc = p_codprodprinc) OR (pcdesconto.codprodprinc IS NULL))
         AND (pcdesconto.codplpag = pcplpag.codplpag(+))
         AND (pcdesconto.codplpag is null or (
              (((nvl(pcdesconto.apenasplpagmax, 'N') = 'N') AND
             (pcplpag.numdias >= p_numdias) ) OR
             ((nvl(pcdesconto.apenasplpagmax, 'N') = 'S') AND
             ((pcdesconto.codplpag = p_codplpag)))) ) )
         AND ((pcdesconto.classevenda = p_classevenda) OR (pcdesconto.classevenda IS NULL))
         AND (pcdesconto.aplicadesconto) =
             decode(vsaplicadesconto,
                    'S',
                    vsaplicadesconto,
                    pcdesconto.aplicadesconto)
         AND ((pcdesconto.areaatuacao = vsareaatuacao) OR
             (pcdesconto.areaatuacao is null))
         AND ((pcdesconto.codfilial  = p_codfilial ) or (pcdesconto.codfilial is null ))
         AND ((pcdesconto.codrede  = vncodrede) or (pcdesconto.codrede is null))
         AND ((pcdesconto.codmarca  = vncodmarca) or (pcdesconto.codmarca is null))
         AND ((nvl(pcdesconto.percdesc, 0) > 0) OR (nvl(pcdesconto.percdescfin,0) > 0)) -- MED-1645 - Desconto Financeiro
         AND case when
             pcdesconto.aplicadescsimplesnacional in ('S', 'N') then pcdesconto.aplicadescsimplesnacional else nvl(vssimplesnacional, 'T') end = nvl(vssimplesnacional, 'T')
         AND ((nvl(pcdesconto.QTINI,0) = 0) OR --->> POLITICA SEM INTERVALO DE QUANTIDADE - MED-1554
              ((nvl(pcdesconto.QTINI,0) > 0) AND (nvl(p_qt,0) between nvl(pcdesconto.QTINI,0) and nvl(pcdesconto.QTFIM,0)))) --->> MED-1554 - POLITICA COM INTERVALO DE QUANTIDADE E DENTRO DA FAIXA
         AND (pcdesconto.tipofv IS NULL) -- MED-1554 - OL e PE não podem entrar aqui
         AND ((NVL(p_coddescontofv,0) = 0) OR (pcdesconto.coddesconto = NVL(p_coddescontofv,0))) -- DDMEDICA-7478
         AND (NVL(PCDESCONTO.CODPROMOCAOMED, 0) = 0) -- DDVENDAS-45654
         -- DDVENDAS-33476
         AND ((EXISTS (SELECT PCDESCONTOITEM.CODDESCONTO
                     FROM PCDESCONTOITEM
                    WHERE PCDESCONTOITEM.TIPO = 'GP'
                      AND PCDESCONTOITEM.CODDESCONTO = PCDESCONTO.CODDESCONTO
                      AND PCDESCONTOITEM.VALOR_NUM IN
                          (SELECT PCGRUPOSCAMPANHAI.CODGRUPO
                             FROM PCGRUPOSCAMPANHAI
                            WHERE PCGRUPOSCAMPANHAI.CODITEM = p_codprod))) OR
              (NOT EXISTS (SELECT PCDESCONTOITEM.CODDESCONTO
                             FROM PCDESCONTOITEM
                           WHERE PCDESCONTOITEM.TIPO = 'GP'
                                 AND PCDESCONTOITEM.CODDESCONTO = PCDESCONTO.CODDESCONTO)))          
         AND (((pcdesconto.CODGRUPOREST IS NULL) OR (pcdesconto.TIPOGRUPOREST IS NULL)) OR
                ((pcdesconto.CODGRUPOREST = CASE WHEN(pcdesconto.TIPOGRUPOREST = 'GR') OR
                 (pcdesconto.TIPOGRUPOREST = 'CL') OR (pcdesconto.TIPOGRUPOREST = 'GP') THEN
                (SELECT PCGRUPOSCAMPANHAI.CODGRUPO
                    FROM PCGRUPOSCAMPANHAI
                   WHERE PCGRUPOSCAMPANHAI.DTEXCLUSAO IS NULL
                      AND PCGRUPOSCAMPANHAI.CODGRUPO = PCDESCONTO.CODGRUPOREST
                     AND PCGRUPOSCAMPANHAI.CODITEM =
                         DECODE(PCDESCONTO.TIPOGRUPOREST,
                                'CL',
                                p_CodCli,
                                'GR',
                                p_CodUsur,
                                'GP',
                                p_CodProd)
                     AND ROWNUM = 1) ELSE 0 END)))         
       ORDER BY NVL(PCDESCONTO.PRIORITARIAGERAL,'N') DESC,
                --pcdesconto.percdesc DESC;
                percdesctotal DESC; -- MED-1645

    CURSOR c_principal_cr(vncodepto IN NUMBER, vncodsec IN NUMBER, vncodcategoria IN NUMBER, vncodfornec IN NUMBER, vncodsupervisor IN NUMBER, vncodatv1 IN NUMBER, vncodpraca IN NUMBER, vsaplicadesconto IN VARCHAR2, vsareaatuacao IN VARCHAR2, vssimplesnacional IN varchar2,
                        vncodrede IN number , vncodmarca IN number, vncodcliprinc IN number) IS
      SELECT decode(p_usadescfinseparadodesccom,'S',nvl(percdesc,0),(nvl(percdesc,0) + nvl(percdescfin,0))) percdesc,
             nvl(basecreddebrca, 'N') basecreddebrca,
             dtfim,
             nvl(creditasobrepolitica, 'S') creditasobrepolitica,
             pcdesconto.dtinicio,
             pcdesconto.coddesconto,
             pcdesconto.alteraptabela,
             pcdesconto.prioritaria,
             pcdesconto.questionausoprioritaria,
             decode(p_usadescfinseparadodesccom,'S',nvl(percdescfin,0),0) percdescfin,
             NVL(PCDESCONTO.PRIORITARIAGERAL,'N') PRIORITARIAGERAL
        FROM pcdesconto,pcplpag
       WHERE p_data BETWEEN pcdesconto.dtinicio AND pcdesconto.dtfim
         --AND nvl(pcdesconto.utilizadescrede, 'N') = 'N'
         --AND ((pcdesconto.codcli = p_codcli) OR (pcdesconto.codcli IS NULL))
         --DDMEDICA-1733
         AND ( ((nvl(pcdesconto.utilizadescrede, 'N') = 'S') AND (codcli IN (p_codcli,vncodcliprinc))) OR
               ((nvl(pcdesconto.utilizadescrede, 'N') = 'N') AND (codcli  = p_codcli))       OR
               (codcli IS NULL) )
         AND ((pcdesconto.codepto = vncodepto) OR (pcdesconto.codepto IS NULL))
         AND ((pcdesconto.codsec = vncodsec) OR (pcdesconto.codsec IS NULL))
         AND ((pcdesconto.codcategoria = vncodcategoria) OR (pcdesconto.codcategoria IS NULL))
         AND ((pcdesconto.codprod = p_codprod) OR (pcdesconto.codprod IS NULL))
         AND ((pcdesconto.codfornec = vncodfornec) OR (pcdesconto.codfornec IS NULL))
         AND ((pcdesconto.codusur = p_codusur) OR (pcdesconto.codusur IS NULL))
         AND ((pcdesconto.codsupervisor = vncodsupervisor) OR (pcdesconto.codsupervisor IS NULL))
         AND ((pcdesconto.numregiao = p_numregiao) OR (pcdesconto.numregiao IS NULL))
         AND ((pcdesconto.codativ = vncodatv1) OR (pcdesconto.codativ IS NULL))
         AND ((pcdesconto.origemped = p_origempedido) OR (nvl(pcdesconto.origemped, 'O') = 'O'))
         AND ((pcdesconto.codpraca = vncodpraca) OR (pcdesconto.codpraca IS NULL))
         AND ((pcdesconto.codprodprinc = p_codprodprinc) OR (pcdesconto.codprodprinc IS NULL))
         AND (pcdesconto.codplpag = pcplpag.codplpag(+))
         AND (pcdesconto.codplpag is null or (
              (((nvl(pcdesconto.apenasplpagmax, 'N') = 'N') AND
             (pcplpag.numdias >= p_numdias) ) OR
             ((nvl(pcdesconto.apenasplpagmax, 'N') = 'S') AND
             ((pcdesconto.codplpag = p_codplpag)))) ) )
         AND ((pcdesconto.classevenda = p_classevenda) OR (pcdesconto.classevenda IS NULL))
         AND (pcdesconto.aplicadesconto) =
             decode(vsaplicadesconto,
                    'S',
                    vsaplicadesconto,
                    pcdesconto.aplicadesconto)
         AND ((pcdesconto.areaatuacao = vsareaatuacao) OR
             (pcdesconto.areaatuacao is null))
         AND ((pcdesconto.codfilial  = p_codfilial ) or (pcdesconto.codfilial is null ))
         AND ((pcdesconto.codrede  = vncodrede) or (pcdesconto.codrede is null))
         AND ((pcdesconto.codmarca  = vncodmarca) or (pcdesconto.codmarca is null))
         AND (nvl(pcdesconto.percdesc, 0) < 0)
         AND case when
             pcdesconto.aplicadescsimplesnacional in ('S', 'N') then pcdesconto.aplicadescsimplesnacional else nvl(vssimplesnacional, 'T') end = nvl(vssimplesnacional, 'T')
         AND ((nvl(pcdesconto.QTINI,0) = 0) OR --->> POLITICA SEM INTERVALO DE QUANTIDADE - MED-1554
              ((nvl(pcdesconto.QTINI,0) > 0) AND (nvl(p_qt,0) between nvl(pcdesconto.QTINI,0) and nvl(pcdesconto.QTFIM,0)))) --->> MED-1554 - POLITICA COM INTERVALO DE QUANTIDADE E DENTRO DA FAIXA
         AND (pcdesconto.tipofv IS NULL) -- MED-1554 - OL e PE não podem entrar aqui
         AND ((NVL(p_coddescontofv,0) = 0) OR (pcdesconto.coddesconto = NVL(p_coddescontofv,0))) -- DDMEDICA-7478
         AND (NVL(PCDESCONTO.CODPROMOCAOMED, 0) = 0) -- DDVENDAS-45654
         -- DDVENDAS-33476
         AND ((EXISTS (SELECT PCDESCONTOITEM.CODDESCONTO
                     FROM PCDESCONTOITEM
                    WHERE PCDESCONTOITEM.TIPO = 'GP'
                      AND PCDESCONTOITEM.CODDESCONTO = PCDESCONTO.CODDESCONTO
                      AND PCDESCONTOITEM.VALOR_NUM IN
                          (SELECT PCGRUPOSCAMPANHAI.CODGRUPO
                             FROM PCGRUPOSCAMPANHAI
                            WHERE PCGRUPOSCAMPANHAI.CODITEM = p_codprod))) OR
              (NOT EXISTS (SELECT PCDESCONTOITEM.CODDESCONTO
                             FROM PCDESCONTOITEM
                           WHERE PCDESCONTOITEM.TIPO = 'GP'
                                 AND PCDESCONTOITEM.CODDESCONTO = PCDESCONTO.CODDESCONTO)))          
         AND (((pcdesconto.CODGRUPOREST IS NULL) OR (pcdesconto.TIPOGRUPOREST IS NULL)) OR
                ((pcdesconto.CODGRUPOREST = CASE WHEN(pcdesconto.TIPOGRUPOREST = 'GR') OR
                (pcdesconto.TIPOGRUPOREST = 'CL') OR (pcdesconto.TIPOGRUPOREST = 'GP') THEN
                (SELECT PCGRUPOSCAMPANHAI.CODGRUPO
                    FROM PCGRUPOSCAMPANHAI
                   WHERE PCGRUPOSCAMPANHAI.DTEXCLUSAO IS NULL
                      AND PCGRUPOSCAMPANHAI.CODGRUPO = PCDESCONTO.CODGRUPOREST
                     AND PCGRUPOSCAMPANHAI.CODITEM =
                         DECODE(PCDESCONTO.TIPOGRUPOREST,
                                'CL',
                                p_CodCli,
                                'GR',
                                p_CodUsur,
                                'GP',
                                p_CodProd)
                     AND ROWNUM = 1) ELSE 0 END)))         
       ORDER BY NVL(PCDESCONTO.PRIORITARIAGERAL,'N') DESC, pcdesconto.percdesc DESC;

    vbresult             BOOLEAN;
    vntempperdesc        NUMBER;
    vstempbasecreddebrca VARCHAR2(2);
    vnpercdesc           NUMBER;
    vsbasecreddebrca     VARCHAR2(2);
    vbresult_cr          BOOLEAN;
    vntempperdesc_cr     NUMBER;
    vnpercdesc_cr        NUMBER;
    --Dados do Cliente
    vncodcliprinc NUMBER;
    vncodatv1     NUMBER;
    vncodpraca    NUMBER;
    --Dados do RCA
    vncodsupervisor NUMBER;
    --Dados do Produto}
    vncodfornec                NUMBER;
    vncodepto                  NUMBER;
    vncodsec                   NUMBER;
    vncodcategoria             NUMBER;
    vncodsubcategoria          NUMBER;
    vicont                     NUMBER;
    vicont2                    NUMBER;
    vicont3                    NUMBER;
    vicontador                 NUMBER;
    vicontador2                NUMBER;
    vsaplicadesconto           VARCHAR2(1);
    vscreditasobrepolitica     VARCHAR2(1);
    vstempcreditasobrepolitica VARCHAR2(1);
    vsareaatuacao              pcusuari.areaatuacao%type;
    vnpercbaserca              number;
    vntemppbaserca             number;
    vssimplesnacional          pcclient.simplesnacional%type;
    vsalteraptabela            varchar2(1);
    vstempalteraptabela        varchar2(1);

    vncodrede                  pcclient.codrede%type;
    vncodmarca                 pcprodut.codmarca%type;

    vstempprioritaria          varchar2(1);
    vsprioritaria              varchar2(1);
    vsquestionaprioritaria     varchar2(1);
    vstempquestionaprioritaria varchar2(1);
    vsusaprioritaria           varchar2(1);

    vntempperdescfin           NUMBER;
    vnpercdescfin               number;

    vncodpoldescbaserca         pcdesconto.coddesconto%type;

    vUSAREGRAPRIORITARIAGERALFV PCREGRASEXCECAOMED.VALOR%type;

    vntempperdesctotal          NUMBER; -- MED-1645
    vnpercdesctotal             NUMBER; -- MED-1645

  BEGIN
    vbresult      := FALSE;
    vnpercdesc    := 0;
    vnpercdescfin := 0;
    vnpercbaserca := 0;
    --    vnpercdesc_cr          := 0;
    vsbasecreddebrca       := 'N';
    vscreditasobrepolitica := 'S';
    vsalteraptabela        := 'N';
    vsprioritaria          := 'N';
    vsusaprioritaria       := p_mensagem;

    vncodpoldescbaserca    := null;

    IF p_aplicadesconto = 0 THEN
      vsaplicadesconto := 'N';
    ELSE
      vsaplicadesconto := 'S';
    END IF;

    -- MED-1645
    vnpercdesctotal := 0;

    --Regra Especifica
    vUSAREGRAPRIORITARIAGERALFV := FUSA_REGRA_MEDICAMENTOS('99','USAREGRAPRIORITARIAGERALFV');

    --Buscar dados do cliente
    SELECT COUNT(*) INTO vicont FROM pcclient WHERE codcli = p_codcli;
    IF vicont <> 0 THEN
      SELECT nvl(codcliprinc, codcli) codcliprinc,
             codatv1,
             codpraca,
             pcclient.simplesnacional,
             pcclient.codrede
        INTO vncodcliprinc, vncodatv1, vncodpraca, vssimplesnacional,vncodrede
        FROM pcclient
       WHERE codcli = p_codcli;

      --Buscar dados do RCA
      SELECT COUNT(*) INTO vicont2 FROM pcusuari WHERE codusur = p_codusur;
      IF vicont2 <> 0 THEN
        SELECT codsupervisor, pcusuari.areaatuacao
          INTO vncodsupervisor, vsareaatuacao
          FROM pcusuari
         WHERE codusur = p_codusur;
        --Buscar dados do produto
        SELECT COUNT(*)
          INTO vicont3
          FROM pcprodut
         WHERE codprod = p_codprod;
        IF vicont3 <> 0 THEN
          SELECT codfornec, codepto, codsec, codcategoria, codsubcategoria,codmarca
            INTO vncodfornec,
                 vncodepto,
                 vncodsec,
                 vncodcategoria,
                 vncodsubcategoria,
                 vncodmarca
            FROM pcprodut
           WHERE codprod = p_codprod;

          --Verificação de Políticas de Descontos}
          FOR reg_pdescontos IN c_principal(vncodepto,
                                       vncodsec,
                                       vncodcategoria,
                                       vncodfornec,
                                       vncodsupervisor,
                                       vncodatv1,
                                       vncodpraca,
                                       vsaplicadesconto,
                                       vsareaatuacao,
                                       vssimplesnacional,
                                       vncodrede,
                                       vncodmarca,
                                       vncodcliprinc) LOOP

            IF (p_tratarrestricaoacrescimo = 'S' AND
               reg_pdescontos.percdesc >= 0) OR
               p_tratarrestricaoacrescimo = 'N' THEN
              vbresult                   := TRUE;
              vntempperdesc              := reg_pdescontos.percdesc;
              vntemppbaserca             := reg_pdescontos.percdesc;
              vstempbasecreddebrca       := reg_pdescontos.basecreddebrca;
              vstempcreditasobrepolitica := reg_pdescontos.creditasobrepolitica;
              vstempalteraptabela        := reg_pdescontos.alteraptabela;
              vstempprioritaria          := reg_pdescontos.prioritaria;
              vstempquestionaprioritaria := reg_pdescontos.questionausoprioritaria;
              vntempperdescfin           := reg_pdescontos.percdescfin;
              vntempperdesctotal         := reg_pdescontos.percdesctotal; -- MED-1645


              if vsprioritaria = 'N' then

                if vstempprioritaria = 'S' then
                  --registro atual é de politica prioritaria

                  if vsusaprioritaria = 'S' then


                    vnpercdesc             := vntempperdesc;
                    vsprioritaria          := vstempprioritaria;
                    vsquestionaprioritaria := vstempquestionaprioritaria;
                    vsalteraptabela        := vstempalteraptabela;
                    vnpercdescfin          := vntempperdescfin;
                    vnpercdesctotal        := vntempperdesctotal; -- MED-1645


                    p_mensagem := to_char(reg_pdescontos.dtinicio,
                                          'dd/mm/yyyy') || ',' ||
                                  reg_pdescontos.coddesconto;


                            if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                                vsbasecreddebrca       := vstempbasecreddebrca;
                                vnpercbaserca          := vntemppbaserca;
                                vscreditasobrepolitica := vstempcreditasobrepolitica;
                          vncodpoldescbaserca    := reg_pdescontos.coddesconto;

                     end if;


                  end if;



                else
                  --registro atual não é de politica prioritaria

                  --IF vntempperdesc > vnpercdesc THEN
                  IF vntempperdesctotal > vnpercdesctotal THEN -- MED-1645

                        vnpercdesc             := vntempperdesc;
                        vnpercdescfin          := vntempperdescfin;
                        vnpercdesctotal        := vntempperdesctotal; -- MED-1645
                        vsprioritaria          := 'N';
                        vsquestionaprioritaria := vstempquestionaprioritaria;
                        vsalteraptabela        := vstempalteraptabela;

                        p_mensagem := to_char(reg_pdescontos.dtinicio,
                                              'dd/mm/yyyy') || ',' ||
                                      reg_pdescontos.coddesconto;


                            if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                                vsbasecreddebrca       := vstempbasecreddebrca;
                                vnpercbaserca          := vntemppbaserca;
                                vscreditasobrepolitica := vstempcreditasobrepolitica;
                          vncodpoldescbaserca    := reg_pdescontos.coddesconto;

                        end if;



                  END IF;

                        if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' and
                           vntemppbaserca > vnpercbaserca then

                            vsbasecreddebrca       := vstempbasecreddebrca;
                            vnpercbaserca          := vntemppbaserca;
                            vscreditasobrepolitica := vstempcreditasobrepolitica;
                      vncodpoldescbaserca    := reg_pdescontos.coddesconto;

                  end if;



                end if;

              else
                -- já tem uma politica prioritaria

                      --IF vntempperdesc > vnpercdesc THEN
                      IF vntempperdesctotal > vnpercdesctotal THEN -- MED-1645

                        vnpercdesc             := vntempperdesc;
                        vnpercdescfin          := vntempperdescfin;
                        vnpercdesctotal        := vntempperdesctotal; -- MED-1645
                        vsprioritaria          := vstempprioritaria;
                        vsquestionaprioritaria := vstempquestionaprioritaria;
                        vsalteraptabela        := vstempalteraptabela;

                        p_mensagem := to_char(reg_pdescontos.dtinicio, 'dd/mm/yyyy') || ',' ||
                                      reg_pdescontos.coddesconto;

                              if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                                vsbasecreddebrca       := vstempbasecreddebrca;
                                vnpercbaserca          := vntemppbaserca;
                                vscreditasobrepolitica := vstempcreditasobrepolitica;
                          vncodpoldescbaserca    := reg_pdescontos.coddesconto;

                                end if;



                      END IF;

              end if;
            END IF;

            -- Ao encontrar a primeira Politica Prioritaria Geral sai do Laco
            IF (vUSAREGRAPRIORITARIAGERALFV  = 'S') AND
               (reg_pdescontos.PRIORITARIAGERAL = 'S') THEN
              EXIT;
            END IF;

          END LOOP;

          /*
          FOR reg_comrede IN c_principal(vncodepto,
                                       vncodsec,
                                       vncodcategoria,
                                       vncodfornec,
                                       vncodsupervisor,
                                       vncodatv1,
                                       vncodpraca,
                                       vncodcliprinc,
                                       vsaplicadesconto,
                                       vsareaatuacao,
                                       vssimplesnacional,
                                       vncodrede,
                                       vncodmarca) LOOP

            IF (p_tratarrestricaoacrescimo = 'S' AND
               --reg_comrede.percdesc > 0) OR
               reg_comrede.percdesctotal > 0) OR -- MED-1645
               p_tratarrestricaoacrescimo = 'N' THEN
              vbresult                   := TRUE;
              vntempperdesc              := reg_comrede.percdesc;
              vntemppbaserca             := reg_comrede.percdesc;
              vstempbasecreddebrca       := reg_comrede.basecreddebrca;
              vstempcreditasobrepolitica := reg_comrede.creditasobrepolitica;
              vstempalteraptabela        := reg_comrede.alteraptabela;

              vstempprioritaria          := reg_comrede.prioritaria;
              vstempquestionaprioritaria := reg_comrede.questionausoprioritaria;
              vntempperdescfin           := reg_comrede.percdescfin;
              vntempperdesctotal         := reg_comrede.percdesctotal; -- MED-1645

              if vsprioritaria = 'N' then

                if vstempprioritaria = 'S' then
                  --registro atual é de politica prioritaria

                  if vsusaprioritaria = 'S' then


                    vnpercdesc             := vntempperdesc;
                    vnpercdescfin          := vntempperdescfin;
                    vnpercdesctotal        := vntempperdesctotal; -- MED-1645
                    vsprioritaria          := vstempprioritaria;
                    vsquestionaprioritaria := vstempquestionaprioritaria;
                    vsalteraptabela        := vstempalteraptabela;


                    p_mensagem := to_char(reg_comrede.dtinicio,
                                          'dd/mm/yyyy') || ',' ||
                                  reg_comrede.coddesconto;


                            if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                                vsbasecreddebrca       := vstempbasecreddebrca;
                                vnpercbaserca          := vntemppbaserca;
                                vscreditasobrepolitica := vstempcreditasobrepolitica;
                          vncodpoldescbaserca    := reg_comrede.coddesconto;

                                end if;


                  end if;



                else
                  --registro atual não é de politica prioritaria

                  --IF vntempperdesc > vnpercdesc THEN
                  IF vntempperdesctotal > vnpercdesctotal THEN -- MED-1645

                        vnpercdesc := vntempperdesc;
                        vnpercdescfin := vntempperdescfin;
                        vnpercdesctotal := vntempperdesctotal; -- MED-1645
                        vsprioritaria          := 'N';
                        vsquestionaprioritaria := vstempquestionaprioritaria;
                        vsalteraptabela        := vstempalteraptabela;

                        p_mensagem := to_char(reg_comrede.dtinicio,
                                              'dd/mm/yyyy') || ',' ||
                                      reg_comrede.coddesconto;


                            if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                                vsbasecreddebrca       := vstempbasecreddebrca;
                                vnpercbaserca          := vntemppbaserca;
                                vscreditasobrepolitica := vstempcreditasobrepolitica;
                          vncodpoldescbaserca    := reg_comrede.coddesconto;

                        end if;



                  END IF;

                        if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' and
                           vntemppbaserca > vnpercbaserca then

                            vsbasecreddebrca       := vstempbasecreddebrca;
                            vnpercbaserca          := vntemppbaserca;
                            vscreditasobrepolitica := vstempcreditasobrepolitica;
                      vncodpoldescbaserca    := reg_comrede.coddesconto;

                            end if;

                end if;

              else
                -- já tem uma politica prioritaria

                      --IF vntempperdesc > vnpercdesc THEN
                      IF vntempperdesctotal > vnpercdesctotal THEN -- MED-1645

                        vnpercdesc             := vntempperdesc;
                        vnpercdescfin          := vntempperdescfin;
                        vnpercdesctotal        := vntempperdesctotal; -- MED-1645
                        vsprioritaria          := vstempprioritaria;
                        vsquestionaprioritaria := vstempquestionaprioritaria;
                        vsalteraptabela        := vstempalteraptabela;

                        p_mensagem := to_char(reg_comrede.dtinicio, 'dd/mm/yyyy') || ',' ||
                                      reg_comrede.coddesconto;

                              if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                                vsbasecreddebrca       := vstempbasecreddebrca;
                                vnpercbaserca          := vntemppbaserca;
                                vscreditasobrepolitica := vstempcreditasobrepolitica;
                          vncodpoldescbaserca    := reg_comrede.coddesconto;

                                end if;



                      END IF;

              end if;

            END IF;

            -- Ao encontrar a primeira Politica Prioritaria Geral sai do Laco
            IF (vUSAREGRAPRIORITARIAGERALFV  = 'S') AND
               (reg_comrede.PRIORITARIAGERAL = 'S') THEN
              EXIT;
            END IF;

          END LOOP;
          */

          FOR reg_pdescontos_cr IN c_principal_cr(vncodepto,
                                                  vncodsec,
                                                  vncodcategoria,
                                                  vncodfornec,
                                                  vncodsupervisor,
                                                  vncodatv1,
                                                  vncodpraca,
                                                  vsaplicadesconto,
                                                  vsareaatuacao,
                                                  vssimplesnacional,
                                                  vncodrede,
                                                  vncodmarca,
                                                  vncodcliprinc) LOOP

            IF p_tratarrestricaoacrescimo = 'S' then

              vbresult_cr                := TRUE;
              vntempperdesc_cr           := reg_pdescontos_cr.percdesc;
              vntemppbaserca             := reg_pdescontos_cr.percdesc;
              vstempbasecreddebrca       := reg_pdescontos_cr.basecreddebrca;
              vstempcreditasobrepolitica := reg_pdescontos_cr.creditasobrepolitica;
              vstempalteraptabela        := reg_pdescontos_cr.alteraptabela;

              IF vntempperdesc_cr < nvl(vnpercdesc_cr, 0) THEN
                vnpercdesc_cr := vntempperdesc_cr;
                vsalteraptabela        := vstempalteraptabela;

                if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                    vsbasecreddebrca       := vstempbasecreddebrca;
                    vnpercbaserca          := vntemppbaserca;
                    vscreditasobrepolitica := vstempcreditasobrepolitica;
                    vncodpoldescbaserca    := reg_pdescontos_cr.coddesconto;


                end if;


              END IF;

               if vstempbasecreddebrca = 'S' and  nvl(p_naousarautdebcredpoldesc,'N') = 'N' and
                 vntemppbaserca < vnpercbaserca then
                vsbasecreddebrca       := vstempbasecreddebrca;
                vnpercbaserca          := vntemppbaserca;
                vscreditasobrepolitica := vstempcreditasobrepolitica;
                vncodpoldescbaserca    := reg_pdescontos_cr.coddesconto;

              end if;

            END IF;

            -- Ao encontrar a primeira Politica Prioritaria Geral sai do Laco
            IF (vUSAREGRAPRIORITARIAGERALFV     = 'S') AND
               (reg_pdescontos_cr.PRIORITARIAGERAL = 'S') THEN
              EXIT;
            END IF;

          END LOOP;
/*
          FOR reg_comrede_cr IN c_comrede_cr(vncodepto,
                                             vncodsec,
                                             vncodcategoria,
                                             vncodfornec,
                                             vncodsupervisor,
                                             vncodatv1,
                                             vncodpraca,
                                             vncodcliprinc,
                                             vsaplicadesconto,
                                             vsareaatuacao,
                                             vssimplesnacional,
                                             vncodrede,
                                             vncodmarca) LOOP

            IF p_tratarrestricaoacrescimo = 'S' then

              vbresult                   := TRUE;
              vntempperdesc_cr           := reg_comrede_cr.percdesc;
              vntemppbaserca             := reg_comrede_cr.percdesc;
              vstempbasecreddebrca       := reg_comrede_cr.basecreddebrca;
              vstempcreditasobrepolitica := reg_comrede_cr.creditasobrepolitica;
              vstempalteraptabela        := reg_comrede_cr.alteraptabela;

              IF vntempperdesc_cr < nvl(vnpercdesc_cr, 0) THEN
                vnpercdesc_cr := vntempperdesc_cr;
                vsalteraptabela        := vstempalteraptabela;

                if nvl(p_naousarautdebcredpoldesc,'N') = 'N' and vstempbasecreddebrca = 'S' then

                    vsbasecreddebrca       := vstempbasecreddebrca;
                    vnpercbaserca          := vntemppbaserca;
                    vscreditasobrepolitica := vstempcreditasobrepolitica;


                end if;


              END IF;

               if vstempbasecreddebrca = 'S' and  nvl(p_naousarautdebcredpoldesc,'N') = 'N' and
                 vntemppbaserca < vnpercbaserca then
                vsbasecreddebrca       := vstempbasecreddebrca;
                vnpercbaserca          := vntemppbaserca;
                vscreditasobrepolitica := vstempcreditasobrepolitica;
                vncodpoldescbaserca    := reg_comrede_cr.coddesconto;

              end if;
            END IF;

            -- Ao encontrar a primeira Politica Prioritaria Geral sai do Laco
            IF (vUSAREGRAPRIORITARIAGERALFV     = 'S') AND
               (reg_comrede_cr.PRIORITARIAGERAL = 'S') THEN
              EXIT;
            END IF;

          END LOOP;
*/
        ELSE
          p_mensagem := 'Não foi possível buscar dados do PCPRODUT!';
        END IF;
      ELSE
        p_mensagem := 'Não foi possível buscar dados do PCUSUARI!';
      END IF; --dados do PCCLIENT
    ELSE
      p_mensagem := 'Não foi possível buscar dados do PCCLIENT!';
    END IF;

    p_perdescrestricao := (round(vnpercdesc_cr, p_numcasasdecvenda)) * -1;

    p_perdesc              := round(vnpercdesc, p_numcasasdecvenda);
    p_perdescfin           := round(vnpercdescfin, p_numcasasdecvenda);
    p_basecreddebrca       := vsbasecreddebrca;
    p_creditasobrepolitica := vscreditasobrepolitica;
    p_pbaserca             := round(vnpercbaserca, p_numcasasdecvenda);
    p_alteraptabela        := vsalteraptabela;

    p_prioritaria             := nvl(vsprioritaria, 'N');
    p_questionausoprioritaria := nvl(vsquestionaprioritaria, 'N');

    p_codpolbaserca   := vncodpoldescbaserca;


    RETURN vbresult;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Politica de Descontos: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END validarpoliticasdesconto_med;

 /************************************************************************
  FUNÇÃO DE SEMAFORO DE IMPORTAÇÃO DE PEDIDOS DO FORÇA DE VENDAS - MED-1600
  ************************************************************************/
 FUNCTION PERMITE_IMPORTAR_PEDIDO_FV(pi_nNumPedRca         IN NUMBER,
                                      pi_nCodUsur           IN NUMBER,
                                      pi_vCgcCli            IN VARCHAR2,
                                      pi_dDtAberturaPedPalm IN DATE)
  RETURN VARCHAR2 IS PRAGMA AUTONOMOUS_TRANSACTION;
    vvRetPermiteImportar   VARCHAR2(1);
    vdDataHoraImportacao   DATE;
    vvHoraImportacao       VARCHAR2(2);
    vvMinutoImportacao     VARCHAR2(2);
    vvHoraMinutoImportacao VARCHAR2(4);
    vdDataImportacao       DATE;
    vDataUltImpPcpedc      DATE; -- DATA DA ULTIMA IMPORTAÇAO
	vMinutosDelay  		   NUMBER; 
  BEGIN

    -- Inicializa Retorno como Nao
    vvRetPermiteImportar := 'N';
    
	-- DATA DA IMPORTAÇAO
    vdDataImportacao := SYSDATE;

	-- TEMPO DE DELAY EM MINUTOS
	vMinutosDelay  := 3;
	

	--OBTEM A DATA E HORA DA ULTIMA IMPORTAÇAO NA PCMEDSEMAFOROFV, EM CASO DE ERRO OU NULL A DATA DA ULTIMA IMPORTAÇÃO É 4 MINUTOS NO PASSADO
    BEGIN
	SELECT NVL(MAX(DATAIMPORTACAO),(SYSDATE - (1/1440*vMinutosDelay+1))) INTO vDataUltImpPcpedc
    FROM PCMEDSEMAFOROFV
	WHERE (NUMPEDRCA      = pi_nNumPedRca)
      AND (CODUSUR        = pi_nCodUsur)
      AND (CGCCLI         = pi_vCgcCli);
	EXCEPTION
      WHEN OTHERS THEN
      vDataUltImpPcpedc := (SYSDATE - (1/1440*(vMinutosDelay+1)));
    END;

	--SE O ULTIPO PEDIDO NA PCMEDSEMAFOROFV FOI INSERIDO A MAIS DE 3 MINUTOS PERMITE IMPORTAR
    IF  ((vDataUltImpPcpedc +  (1/1440*vMinutosDelay)) < vdDataImportacao)  THEN
      vvRetPermiteImportar := 'S';
  	  BEGIN
  		  INSERT INTO PCMEDSEMAFOROFV
  					( NUMPEDRCA
  					, CODUSUR
  					, CGCCLI
  					, DATAIMPORTACAO
  					, HORAMINUTO
  					, DTABERTURAPEDPALM
  					, TENTATIVAS )
  			 VALUES ( pi_nNumPedRca
  					, pi_nCodUsur
  					, pi_vCgcCli
  					, vdDataImportacao
  					, '00'
  					, pi_dDtAberturaPedPalm
  					, 0 );
  		 
  		 COMMIT;
       EXCEPTION
        WHEN OTHERS THEN
            vvRetPermiteImportar := 'S';
  	    END;  
	ELSE 
      vvRetPermiteImportar := 'N';
	 BEGIN
		UPDATE PCMEDSEMAFOROFV
		   SET TENTATIVAS = NVL(TENTATIVAS,0) + 1
		 WHERE (NUMPEDRCA      = pi_nNumPedRca)
		   AND (CODUSUR        = pi_nCodUsur)
		   AND (CGCCLI         = pi_vCgcCli)
		   AND (DATAIMPORTACAO = vDataUltImpPcpedc);
		 COMMIT;
     EXCEPTION
        WHEN OTHERS THEN
            vvRetPermiteImportar := 'N';
	  END;
    END IF;
    -- Retorno
    RETURN vvRetPermiteImportar;

  END PERMITE_IMPORTAR_PEDIDO_FV;

 /************************************************************************
  PROCEDIMENTO PARA RETORNAR A TAXA DE FRETE
  ************************************************************************/
  PROCEDURE OBTER_TAXA_FRETE(pi_vCodFilial   IN  VARCHAR2,
                             pi_vOrigemPed   IN  VARCHAR2,
                             pi_vTipoFv      IN  VARCHAR2,
                             po_vAchouTaxa   OUT VARCHAR2,
                             po_nValorTaxa   OUT NUMBER,
                             po_nValorMinimo OUT NUMBER)
  IS
    vvOrigem VARCHAR2(200);
  BEGIN
    -- Inicializa Retornos
    po_vAchouTaxa := 'N';
    po_nValorTaxa := 0;

    -- Define Origem
    IF    (pi_vOrigemPed = 'F') AND (NVL(pi_vTipoFv,'FV') = 'OL') THEN
      vvOrigem := 'L';
    ELSIF (pi_vOrigemPed = 'F') AND (NVL(pi_vTipoFv,'FV') = 'PE') THEN
      vvOrigem := 'E';
    ELSE
      vvOrigem := pi_vOrigemPed;
    END IF;

    -- Pesquisa Valores por Filial (verifica se existe algum valor cadastradp para a Filial passada no parâmetro)
    BEGIN
      SELECT 'S'
        INTO po_vAchouTaxa
        FROM PCLIMITESFILIALORIGEMMED
       WHERE (TIPOLIMITE = 'TF')
         AND (CODFILIAL  = pi_vCodFilial)
         AND (ROWNUM     = 1);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        po_vAchouTaxa := 'N';
    END;

    -- Se achou Valores por Filial
    IF (po_vAchouTaxa = 'S') THEN

      -- Pesquisa Valores da Filial passada no Parâmetro
      BEGIN
        SELECT 'S'
             , VALORDESPESA
             , VALORLIMITE
          INTO po_vAchouTaxa
             , po_nValorTaxa
             , po_nValorMinimo
          FROM PCLIMITESFILIALORIGEMMED
         WHERE (TIPOLIMITE = 'TF')
           AND (CODFILIAL  = pi_vCodFilial)
           AND (ORIGEM     = vvOrigem);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          po_vAchouTaxa := 'N';
      END;

    -- Se NÃO achou Valores por Filial
    ELSE

      -- Pesquisa Valor para Todas as Filiais
      BEGIN
        SELECT 'S'
             , VALORDESPESA
             , VALORLIMITE
          INTO po_vAchouTaxa
             , po_nValorTaxa
             , po_nValorMinimo
          FROM PCLIMITESFILIALORIGEMMED
         WHERE (TIPOLIMITE = 'TF')
           AND (CODFILIAL  = '99') -->> Todas as Filiais "99"
           AND (ORIGEM     = vvOrigem);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          po_vAchouTaxa := 'N';
      END;

    END IF;

  END OBTER_TAXA_FRETE;

 /************************************************************************
  PROCEDIMENTO DE SEMAFORO DE IMPORTAÇÃO DE PEDIDOS DE OPERADOR LOGISTICO
  ************************************************************************/
  PROCEDURE PERMITE_IMPORTAR_PED_OPERLOG(pi_vArquivoPed   IN VARCHAR2,
                                         pi_vNumPedVan    IN VARCHAR2,
                                         pi_vNumPedCli    IN VARCHAR2,
                                         pi_vToken        IN VARCHAR2,
                                         pi_nIntegradora  IN NUMBER,
                                         pi_nNumQuebra    IN NUMBER,
                                         pi_vReproc       IN VARCHAR2,
                                         pi_dDtImportacao IN DATE,
                                         po_vResultado    OUT VARCHAR2,
                                         po_vMsgResultado OUT VARCHAR2)
  IS PRAGMA AUTONOMOUS_TRANSACTION;
    vvRetPermiteImportar   VARCHAR2(1);
    vdDataHoraImportacao   DATE;
    vvHoraImportacao       VARCHAR2(2);
    vvMinutoImportacao     VARCHAR2(2);
    vvHoraMinutoImportacao VARCHAR2(4);
    vdDataImportacao       DATE;
    viIncTentativas        INTEGER;
    viIncReprocessamentos  INTEGER;
  BEGIN

    -- Inicializa Retorno
    po_vResultado    := 'N';
    po_vMsgResultado := NULL;

    -- Inicializa Incrementos
    IF (NVL(pi_vReproc,'N') = 'S') THEN
      viIncTentativas       := 0;
      viIncReprocessamentos := 1;
    ELSE
      viIncTentativas       := 1;
      viIncReprocessamentos := 0;
    END IF;

    -- Insere Semáforo
    BEGIN
      INSERT INTO PCMEDSEMAFOROOPERLOG
                ( ARQUIVOPED
                , NUMPEDVAN
                , NUMPEDCLI
                , TOKEN
                , INTEGRADORA
                , NUMQUEBRA
                , DTIMPORTACAO
                , TENTATIVAS
                , REPROCESSAMENTOS )
         VALUES ( pi_vArquivoPed
                , NVL(pi_vNumPedVan,'0')
                , NVL(pi_vNumPedCli,'0')
                , NVL(pi_vToken,'0')
                , pi_nIntegradora
                , NVL(pi_nNumQuebra,0)
                , pi_dDtImportacao -- DDMEDICA-7545
                , 0
                , 0 );
      COMMIT; -- Atualiza Transações
      -- PERMITE IMPORTAR --
      po_vResultado := 'S';
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        -- Incrementa Semáforo
        UPDATE PCMEDSEMAFOROOPERLOG
           SET TENTATIVAS       = NVL(TENTATIVAS,0)       + NVL(viIncTentativas,0)
             , REPROCESSAMENTOS = NVL(REPROCESSAMENTOS,0) + NVL(viIncReprocessamentos,0)
         WHERE (ARQUIVOPED  = pi_vArquivoPed)
           AND (NUMPEDVAN   = NVL(pi_vNumPedVan,'0'))
           AND (NUMPEDCLI   = NVL(pi_vNumPedCli,'0'))
           AND (TOKEN       = NVL(pi_vToken,'0'))
           AND (INTEGRADORA = pi_nIntegradora)
           AND (NUMQUEBRA   = NVL(pi_nNumQuebra,0));
        COMMIT; -- Atualiza Transações
        -- Pesquisa Dados
        BEGIN
          SELECT 'Pedido foi importado anteriormente no arquivo ' || ARQUIVOPED || ' em ' || TO_CHAR(DTIMPORTACAO,'DD/MM/YYYY HH24:MI:SS')
            INTO po_vMsgResultado
            FROM PCMEDSEMAFOROOPERLOG
           WHERE (ARQUIVOPED  = pi_vArquivoPed)
             AND (NUMPEDVAN   = NVL(pi_vNumPedVan,'0'))
             AND (NUMPEDCLI   = NVL(pi_vNumPedCli,'0'))
             AND (TOKEN       = NVL(pi_vToken,'0'))
             AND (INTEGRADORA = pi_nIntegradora)
             AND (NUMQUEBRA   = NVL(pi_nNumQuebra,0));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            po_vMsgResultado := NULL;
        END;
    END;

    -- Se reprocessamento, permite importar sem restrições
    IF (NVL(pi_vReproc,'N') = 'S') THEN
      po_vResultado := 'S';
    END IF;

  END PERMITE_IMPORTAR_PED_OPERLOG;

  ------------------------------------------------------------------------------
  -- Função para Verificar se Usa Regra Específica de Medicamentos --
  -- 4348.097738.2015
  -------------------------------------------------------------------
  FUNCTION FPEDIDO_EXISTE_PCPEDC(pi_vCgcCli            IN VARCHAR2,
                                 pi_nNumPedRca         IN NUMBER,
                                 pi_dDtAberturaPedPalm IN DATE,
                                 pi_nCodUsur           IN NUMBER)
  RETURN VARCHAR2 IS
    vnCodCliAux          PCCLIENT.CODCLI%TYPE;
    vnNumPedAux          PCPEDC.NUMPED%TYPE;
    vvMsgRetPedidoExiste VARCHAR2(200);
  BEGIN

    -- Inicializa Retorno
    vvMsgRetPedidoExiste := 'N';

    -- Pesquisa Cliente
    BEGIN
      select codcli
        into vnCodCliAux
        from pcclient
       where trim(replace(replace(replace(replace(replace(replace(cgcent,' ',''), '.', ''),
                                                    ',',
                                                    ''),
                                            '-',
                                            ''),
                                    '/',
                                    ''),
                            '\',
                            '')) =  trim(replace(replace(replace(replace(replace(replace(pi_vCgcCli,' ',''), '.', ''),
                                                    ',',
                                                    ''),
                                            '-',
                                            ''),
                                    '/',
                                    ''),
                            '\',
                            ''))
          and dtexclusao is null
          and rownum = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnCodCliAux := NULL;
    END;

    -- Pesquisa Pedido
    BEGIN
      select numped
        into vnNumPedAux
        from pcpedc
       where numpedrca         = pi_nNumPedRca
         and codusur           = pi_nCodUsur
         and codcli            = vnCodCliAux
         and dtaberturapedpalm = pi_dDtAberturaPedPalm
         and (nvl(posicao,'C') <> 'C')
         and rownum            = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
       vnNumPedAux := NULL;
    END;

    -- Se Pedido existir
    IF (NVL(vnNumPedAux,0) > 0) THEN
      vvMsgRetPedidoExiste := 'S-Pedido OL já processado no numped ' || vnNumPedAux;
    END IF;

    -- Retorno
    RETURN vvMsgRetPedidoExiste;

  END FPEDIDO_EXISTE_PCPEDC;

 /***********************************************************************************************
  PROCEDURE: proc_validacadastrolinhaprazo
  DESCRIÇÃO: Validar Cadastro de Linha de Prazo - MED-1499
  ***********************************************************************************************/
  PROCEDURE proc_validacadastrolinhaprazo (pi_nIntegradora      IN NUMBER,
                                           pi_vTipoFv           IN VARCHAR2,
                                           pi_nCodLinhaPrazo    IN NUMBER,
                                           pi_nCodCondicaoVenda IN NUMBER,
                                           pi_nPrazo            IN NUMBER,
                                           pi_vTipoPrazo        IN VARCHAR2,
                                           pi_vCodigoPrazo      IN VARCHAR2,
                                           po_vRejeitado        OUT VARCHAR2,
                                           po_vMotivoRejeitado  OUT VARCHAR2,
                                           po_vObservacao       OUT VARCHAR2,
                                           po_vJsonRejeitado    OUT VARCHAR2) IS

    vvExiste                   VARCHAR2(1);
    vvExisteDuplic             VARCHAR2(1);
    vvDescricaoPedidoTipoFv    VARCHAR2(100);
    vvTipoSelecaoCondicao      PCINTEGRADORA.TIPOSELECAOCONDICAO%TYPE;
    vvDescricaoTipoSelCondicao VARCHAR2(100);
    vvDescricaoTipoPrazo       VARCHAR2(2000);
    vvOrientacaoCondicaoNaoCad VARCHAR2(32000);
    vvDescricaoLinhaPrazo      PCLINHAPRAZO.DESCRICAO%TYPE;
    vvDescricaoCondVenda       PCCONDICAOVENDA.DESCRICAO%TYPE;

  BEGIN

    -- Inicializa Retornos
    po_vRejeitado       := 'N';
    po_vMotivoRejeitado := NULL;
    po_vObservacao      := NULL;
    po_vJsonRejeitado   := NULL;

    -- Descrição do Tipo FV
    IF (NVL(pi_vTipoFv,'FV') = 'OL') THEN
      vvDescricaoPedidoTipoFv := 'Pedido de Operador Logístico';
    ELSE
      vvDescricaoPedidoTipoFv := 'Pedido Eletrônico';
    END IF;

    -- Descrição do Tipo de Condição da Integradora
    BEGIN
      SELECT TIPOSELECAOCONDICAO
           , DECODE(TIPOSELECAOCONDICAO,'A','Apontador da Condição',
                                        'P','Prazo',
                                        'C','Condição do Cliente',
                                        'T','Tabela de Prazos',
                                        'O','Tipo de Pagamento do OL')
        INTO vvTipoSelecaoCondicao
           , vvDescricaoTipoSelCondicao
        FROM PCINTEGRADORA
       WHERE (INTEGRADORA = pi_nIntegradora)
         AND (ROWNUM      = 1);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvTipoSelecaoCondicao      := NULL;
        vvDescricaoTipoSelCondicao := NULL;
    END;

    -- Descrição Tipo Prazo
    IF    (NVL(pi_vTipoPrazo,' ') = 'V') THEN
      vvDescricaoTipoPrazo := 'V - À Vista';
    ELSIF (NVL(pi_vTipoPrazo,' ') = 'P') THEN
      vvDescricaoTipoPrazo := 'P - A Prazo';
    ELSIF (NVL(pi_vTipoPrazo,' ') = 'D') THEN
      vvDescricaoTipoPrazo := 'D - Prazo Determinado';
    ELSIF (NVL(pi_vTipoPrazo,' ') = 'T') THEN
      vvDescricaoTipoPrazo := 'T - Tabela de Prazos';
    END IF;

    -- Se NÃO tiver Condição de Venda
    IF (NVL(pi_nCodCondicaoVenda,0) = 0) THEN

      vvOrientacaoCondicaoNaoCad := 'No Cadastro da Integradora (botão "Integradora" na Rotina 2302)' ||
                                    ' a opção "Condição de Venda" está selecionado com o valor "' || vvDescricaoTipoSelCondicao || '".' || CHR(13) ||
                                    'Nesta configuração';
      IF    (vvTipoSelecaoCondicao = 'A') THEN
        vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad ||
                                      ' o Código da Condição de Venda cadastrada na Rotina 2311 deve ser transmitido no ' || vvDescricaoPedidoTipoFv || '.' ||
                                      ' No Layout selecionado na Integradora deve existir um campo de Condição de Venda (verificar na documentação da integração se existe um campo específico para esta informação). ' || CHR(13) ||
                                      'Altere no Cadastro da Integradora a opção "Condição de Venda" para outro valor ou verifique com a Empresa responsável pela transmissão do Pedido a possibilidade de implementação desta informação.';
      ELSIF (vvTipoSelecaoCondicao = 'P') THEN
        vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad ||
                                      ' o Sistema pesquisa uma Condição de Venda cadastrada na Rotina 2311 onde o item escolhido no campo "Tipo de Prazo da Integradora" seja igual ao indicador recebido no ' || vvDescricaoPedidoTipoFv || '.' ||
                                      ' Nesta configuração somente serão criticados os seguintes indicadores: "À Vista", "A Prazo" ou "Prazo Determinado".' ||
                                      ' Se na Condição de Venda o item selecionado for "Prazo Determinado", o Sistema ainda critica se o valor informado no Campo "Prazo da Integradora" é igual ao valor recebido no Pedido. (O campo "Prazo da Integradora" é habilitado ao selecionar "Prazo Determinado").' ||
                                      ' Neste Pedido o indicador de Tipo de Prazo está com valor igual a "' || vvDescricaoTipoPrazo || '".' || CHR(13) ||
                                      'Verifique se a sua Condição de Venda o item escolhido no campo "Tipo de Prazo da Integradora" é igual a "' || vvDescricaoTipoPrazo || '".';
        IF (pi_vTipoPrazo = 'D') THEN
          vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad ||
                                        ' Neste Pedido a quantidade de dias de prazo está com valor igual a "' || pi_nPrazo || '".' ||
                                        ' Verifique também na sua Condição de Venda se o campo "Prazo da Integradora" está com valor igual a "' || pi_nPrazo || '".';
        END IF;
      ELSIF (vvTipoSelecaoCondicao = 'C') THEN
        vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad ||
                                      ' o Sistema pesquisa uma Condição de Venda cadastrada na Rotina 2311 onde o item escolhido no campo "Tipo de Prazo da Integradora" seja diferente de "Código de Prazo".' || CHR(13) ||
                                      'Verifique se na sua Condição de Venda o item escolhido no campo "Tipo de Prazo da Integradora" está diferente de "Código de Prazo".';
      ELSIF (vvTipoSelecaoCondicao = 'T') THEN
        vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad ||
                                      ' o Sistema pesquisa uma Condição de Venda cadastrada na Rotina 2311 onde o item escolhido no campo "Tipo de Prazo da Integradora" seja igual a "Código de Prazo" e o valor do campo "Código de Prazo" seja igual ao valor recebido no ' || vvDescricaoPedidoTipoFv ||
                                      ', , com uma única exceção: se o Tipo de Prazo do Pedido for igual a "P - Prazo", o Sistema pesquisa por uma Condição de Venda onde item escolhido no campo "Tipo de Prazo da Integradora" seja igual a "A Prazo".' || CHR(13);
        IF (NVL(pi_vTipoPrazo,'X') = 'P') THEN
          vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad ||
                                        'Como neste Pedido o Tipo de Prazo recebido foi igual a "P", verifique na sua Condição de Venda se o item escolhido no campo "Tipo de Prazo da Integradora" é igual a "A Prazo" ';
        ELSE
          vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad ||
                                        'Neste Pedido o Código de Prazo é igual a "' || pi_vCodigoPrazo || '".' || CHR(13) ||
                                        'Verifique se na sua Condição de Venda o item escolhido no campo "Tipo de Prazo da Integradora" é igual a "Código de Prazo" e o campo "Código de Prazo" está com valor igual a "' || pi_vCodigoPrazo || '".';
        END IF;
      ELSIF (vvTipoSelecaoCondicao = 'O') THEN
        vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad ||
                                      ' o Sistema pesquisa uma Condição de Venda cadastrada na Rotina 2311 onde o item escolhido no campo "Tipo de Prazo da Integradora" seja igual ao indicador recebido no ' || vvDescricaoPedidoTipoFv || '.' ||
                                      ' Nesta configuração somente serão criticados os seguintes indicadores: "À Vista", "A Prazo" ou "Prazo Determinado".' ||
                                      ' Se no Pedido estiver indicando "Prazo Determinado", o Sistema ainda critica se o valor informado no campo "Código de Prazo" é igual ao valor recebido no Pedido.' ||
                                      ' Neste Pedido valor do Tipo de Prazo é igual a "' || vvDescricaoTipoPrazo || '".' || CHR(13) ||
                                      'Verifique se a sua Condição de Venda o item escolhido no campo "Tipo de Prazo da Integradora" é igual a "' || vvDescricaoTipoPrazo || '".';
        IF (pi_vTipoPrazo = 'D') THEN
          vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad ||
                                        ' Neste Pedido o Código de Prazo está com valor igual a "' || pi_vCodigoPrazo || '".' ||
                                        ' Requerido também na Condição de Venda o campo "Código de Prazo" com valor igual a "' || pi_vCodigoPrazo || '".';
        END IF;
      END IF;

      IF (vvTipoSelecaoCondicao NOT IN ('A')) THEN
        vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad || CHR(13) ||
                                      'Ainda na sua Condição de Venda, verifique o período de Vigência, se a Filial do Pedido está na lista de Filiais permitidas, se a Integradora está na lista de Integradoras permitidas ou se existe algum Bloqueio e Restrição de Venda cadastrado na própria Condição de Venda.';
      END IF;

      vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad || CHR(13) ||
                                    'Após revisão dos cadastros, o Pedido poderá ser reprocessado na Consulta de Pedidos da Rotina 2302, na aba "Pedidos", podendo ser feita a multi-seleção de Pedidos para reprocessamento.';

      po_vRejeitado       := 'S';
      po_vMotivoRejeitado := 'Condição de Venda indisponível';
      po_vObservacao      := 'Não está disponível uma Condição de Venda para este ' || vvDescricaoPedidoTipoFv || ' (Rotina 2311 - Cadastro de Condições de Venda)';
      po_vJsonRejeitado   := func_gerarlogjson(po_vMotivoRejeitado,
                                               po_vObservacao,
                                               '2302, 2311',
                                               NULL,
                                               NULL,
                                               vvOrientacaoCondicaoNaoCad);

    -- Se tiver Condição de Venda
    ELSE

      -- Verifica se a Condição de Venda existe no Sistema
      vvExiste := 'N';
      BEGIN
        SELECT 'S' EXISTE
             , DESCRICAO
          INTO vvExiste
             , vvDescricaoCondVenda
          FROM PCCONDICAOVENDA
         WHERE (CODCONDICAOVENDA = pi_nCodCondicaoVenda);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvExiste             := 'N';
          vvDescricaoCondVenda := NULL;
      END;

      -- Se a Condição de Venda NÃO existe no Sistema
      IF  (vvExiste = 'N') THEN

        po_vRejeitado       := 'S';
        po_vMotivoRejeitado := 'Condição de Venda indisponível';
        po_vObservacao      := 'Condição de Venda "' || pi_nCodCondicaoVenda || '" gravada no Pedido não existe na Rotina 2311 - Cadastro de Condições de Venda';
        po_vJsonRejeitado   := func_gerarlogjson(po_vMotivoRejeitado,
                                                 po_vObservacao,
                                                 '2311',
                                                 NULL,
                                                 NULL,
                                                 vvOrientacaoCondicaoNaoCad);

      -- Se a Condição de Venda existe no Sistema
      ELSE

        -- Se NÃO tiver Linha de Prazo no Produto
        IF (NVL(pi_nCodLinhaPrazo,0) = 0) THEN

          po_vRejeitado       := 'S';
          po_vMotivoRejeitado := 'Problemas no cadastro da Linha de Prazo';
          po_vObservacao      := 'Na Importação de Pedidos pela Rotina 2302 ou por Integrações que utilizem o Cadastro de Condições de Venda (Rotina 2311) é exigido o preenchimento do campo "Código de Linha de Prazo" na Rotina 203 - Cadastrar Produto';
          po_vJsonRejeitado   := func_gerarlogjson(po_vMotivoRejeitado,
                                                   po_vObservacao,
                                                   '203',
                                                   NULL,
                                                   NULL,
                                                   'Acessar a Rotina 203 e preencher o Código Linha Prazo (campo "codlinhaprazo")');

        ELSE

          -- Verifica se a Linha de Prazo existe no Sistema
          vvExiste := 'N';
          BEGIN
            SELECT 'S' EXISTE
                 , DESCRICAO
              INTO vvExiste
                 , vvDescricaoLinhaPrazo
              FROM PCLINHAPRAZO
             WHERE (CODLINHAPRAZO = pi_nCodLinhaPrazo);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vvExiste              := 'N';
              vvDescricaoLinhaPrazo := NULL;
          END;

          -- Se a Linha de Prazo NÃO existir no Sistema
          IF  (vvExiste = 'N') THEN

            po_vRejeitado       := 'S';
            po_vMotivoRejeitado := 'Problemas no cadastro da Linha de Prazo';
            po_vObservacao      := 'Linha de Prazo "' || pi_nCodLinhaPrazo || '" que está cadastrada no Produto não existe na Rotina 2310 - Cadastrar Linha de Prazo';
            po_vJsonRejeitado   := func_gerarlogjson(po_vMotivoRejeitado,
                                                     po_vObservacao,
                                                     '2310, 203',
                                                     NULL,
                                                     NULL,
                                                     'Acessar a Rotina 203 e preencher o Código Linha Prazo (campo "codlinhaprazo") com um código que existe na Rotina Rotina 2310 - Cadastrar Linha de Prazo');

          ELSE

            -- Verifica se a Linha existe na Condição de Venda
            vvExiste       := 'N';
            vvExisteDuplic := 'N';
            BEGIN
              SELECT 'S' EXISTE
                INTO vvExiste
                FROM PCCONDVENDALINHA
               WHERE (CODCONDICAOVENDA = pi_nCodCondicaoVenda)
                 AND (CODLINHAPRAZO    = pi_nCodLinhaPrazo);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                vvExiste      := 'N';
              WHEN TOO_MANY_ROWS THEN
                vvExisteDuplic := 'S';
            END;

            -- Se a Linha de Prazo não existir na Condição de Venda
            IF    (vvExiste = 'N') THEN

              po_vRejeitado       := 'S';
              po_vMotivoRejeitado := 'Problemas no cadastro da Linha de Prazo';
              po_vObservacao      := 'Linha de Prazo "' || pi_nCodLinhaPrazo || ' - ' || vvDescricaoLinhaPrazo || '" não cadastrada na Condição de Venda "' || pi_nCodCondicaoVenda || '" (Rotina 2311 - Cadastro de Condições de Venda)';
              po_vJsonRejeitado   := func_gerarlogjson(po_vMotivoRejeitado,
                                                       po_vObservacao,
                                                       '2311',
                                                       NULL,
                                                       NULL,
                                                       'Acessar a Rotina 2311, pesquisar pela Condição de Venda "' || pi_nCodCondicaoVenda || ' - ' || vvDescricaoCondVenda || '", clicar na aba "Linhas" e incluir a Linha de Prazo "' || pi_nCodLinhaPrazo || ' - ' || vvDescricaoLinhaPrazo ||  '"');

            -- Se a Linha de Prazo estiver Duplicada na Condição de Venda
            ELSIF (vvExisteDuplic = 'S') THEN

              po_vRejeitado       := 'S';
              po_vMotivoRejeitado := 'Problemas no cadastro da Linha de Prazo';
              po_vObservacao      := 'Linha de Prazo "' || pi_nCodLinhaPrazo || ' - ' || vvDescricaoLinhaPrazo || '" duplicada na Condição de Venda "' || pi_nCodCondicaoVenda || '"  (Rotina 2311 - Cadastro de Condições de Venda)';
              po_vJsonRejeitado   := func_gerarlogjson(po_vMotivoRejeitado,
                                                       po_vObservacao,
                                                       '2311',
                                                       NULL,
                                                       NULL,
                                                       'Acessar a Rotina 2311, pesquisar pela Condição de Venda "' || pi_nCodCondicaoVenda || ' - ' || vvDescricaoCondVenda || '", clicar na aba "Linhas" e excluir a Linha de Prazo duplicada.');

            END IF;

          END IF; -- Fim: Se a Linha de Prazo NÃO existir no Sistema

        END IF; -- Fim: Se NÃO tiver Linha de Prazo no Produto

      END IF; -- Fim: Se a Condição de Venda NÃO existe no Sistema

    END IF; -- Fim: Se NÃO tiver Condição de Venda

  END proc_validacadastrolinhaprazo;

 /***********************************************************************************************
  PROCEDURE: proc_validadescmediopedido
  DESCRIÇÃO: Validar Desconto Médio do Pedido - MED-1499
  ***********************************************************************************************/
  PROCEDURE proc_validadescmediopedido (pi_vCodFilial             IN VARCHAR2,
                                        pi_nCondVenda             IN NUMBER,
                                        pi_nPerMaxDescVendaFilial IN NUMBER,
                                        pi_nPerMaxDescVendaGeral  IN NUMBER,
                                        pi_nValorTabela           IN NUMBER,
                                        pi_nValorVenda            IN NUMBER,
                                        pi_nNumCasasDecVenda      IN NUMBER,
                                        pi_vIgnorarPerMaxDescVenda IN VARCHAR2,
                                        po_vRejeitado             OUT VARCHAR2,
                                        po_vMotivoRejeitado       OUT VARCHAR2,
                                        po_vObservacao            OUT VARCHAR2,
                                        po_vJsonRejeitado         OUT VARCHAR2) IS
    -- Variáveis
    vnperdesctot               NUMBER;
    vnPerMaxDescVenda          NUMBER;
    vnNumeroParametro          VARCHAR2(100);
    vvDescricaoParametro       VARCHAR2(100);
    vvOrientacaoCondicaoNaoCad VARCHAR2(32000);

  BEGIN

    -- Inicializa Retornos
    po_vRejeitado       := 'N';
    po_vMotivoRejeitado := NULL;
    po_vObservacao      := NULL;
    po_vJsonRejeitado   := NULL;

    -- Se não ignora Parâmetro - MED-2574
    IF (NVL(pi_vIgnorarPerMaxDescVenda,'N') <> 'S') THEN

      if (pi_nCondVenda not in (4,5,8)) then

        -- Por Filial
        if nvl(pi_nPerMaxDescVendaFilial,0) > 0 then
          vnPerMaxDescVenda    := nvl(pi_nPerMaxDescVendaFilial,0);
          vnNumeroParametro    := '2569';
          vvDescricaoParametro := 'Parâmetro da Presidência da Filial ' || pi_vCodFilial;
        -- Geral
       else
          vnPerMaxDescVenda    := nvl(pi_nPerMaxDescVendaGeral,0);
          vnNumeroParametro    := '1463';
          vvDescricaoParametro := 'Parâmetro da Presidência para a Empresa';
        end if;

        -- DDMEDICA-800 - Somente se informou o parâmetro na Filial ou Geral
        IF (NVL(vnPerMaxDescVenda,0) > 0) THEN

          if (nvl(pi_nValorTabela,0) <> 0) then
            vnperdesctot := ROUND((((pi_nValorTabela - pi_nValorVenda) / pi_nValorTabela) * 100), pi_nNumCasasDecVenda);
          else
            vnperdesctot := 0;
          end if;

          -- Se o Desconto Médio do Pedido superior ao Percentual do Parâmetro
          if (nvl(vnperdesctot,0) > nvl(vnPerMaxDescVenda,0)) then

            po_vRejeitado       := 'S';
            po_vMotivoRejeitado := 'Percentual de Desconto Médio do Pedido superior ao permitido';
            po_vObservacao      := 'O Percentual Médio de Desconto do Pedido calculado (percentual igual a ' || FFORMATAR_NUMERO_PARA_TEXTO(nvl(vnperdesctot,0),2) || '%)' ||
                                   ' é superior ao Percentual Máximo cadastrado no ' || vvDescricaoParametro || ' (percentual igual a ' || FFORMATAR_NUMERO_PARA_TEXTO(nvl(vnPerMaxDescVenda,0),2) || '%).' || CHR(13) ||
                                  'Totais do Pedido: Valor Tabela = ' || FFORMATAR_NUMERO_PARA_TEXTO(nvl(pi_nValorTabela,0),2) || ' ; Valor Venda = ' || FFORMATAR_NUMERO_PARA_TEXTO(nvl(pi_nValorVenda,0),2);

          end if;

        END IF; -- (NVL(vnPerMaxDescVenda,0) > 0)

      end if;

      -- Se houve Rejeição
      IF (po_vRejeitado = 'S') THEN

        vvOrientacaoCondicaoNaoCad := 'Acessar a Rotina 132 e aumentar o percentual de desconto cadastrado no parâmetro "' || vnNumeroParametro || '" ou reveja a condição comercial responsável pelos descontos aplicados nos itens do Pedido.' || CHR(13) ||
                                      'O desconto aplicado no pedido pode ter as seguintes origens: Desconto do EDI (recebido no Pedido), Desconto da Promoção (Rotina 2323 ou Rotina 561) ou Desconto Comercial da Condição de Venda (Rotina 2311, na aba de Linhas).';
        vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad || CHR(13) ||
                                      'Após revisão dos cadastros, o Pedido poderá ser reprocessado na Consulta de Pedidos da Rotina 2302, na aba "Pedidos", podendo ser feita a multi-seleção de Pedidos para reprocessamento.';

        po_vJsonRejeitado := func_gerarlogjson(po_vMotivoRejeitado,
                                               po_vObservacao,
                                               '132, 2302, 2323, 561',
                                               vnNumeroParametro,
                                               NULL,
                                               vvOrientacaoCondicaoNaoCad);
      END IF;

    END IF; -- Fim Condição: Se não Ignora Parâmetro

  END proc_validadescmediopedido;

 /***********************************************************************************************
  PROCEDURE: proc_validaprazomediopedido
  DESCRIÇÃO: Validar Prazo Médio do Pedido - MED-1499
  ***********************************************************************************************/
  PROCEDURE proc_validaprazomediopedido(pi_nCodPlPagPedido      IN NUMBER,
                                        pi_nCodPlPagCliente     IN NUMBER,
                                        pi_bExistePlPagCli      IN BOOLEAN,
                                        pi_vBloqPrazomdvenda    IN VARCHAR2,
                                        pi_vAceitaVendaBloq     IN VARCHAR2,
                                        pi_nCodPromocaoMed      IN NUMBER,
                                        pi_vOrigemPed                IN VARCHAR2,
                                        pi_vTipoFv                   IN VARCHAR2,
                                        pi_vIgnorarPrazoMedioCliente IN VARCHAR2,
                                        pi_nIntegradora              IN NUMBER,
                                        po_vRejeitado           OUT VARCHAR2,
                                        po_vMotivoRejeitado     OUT VARCHAR2,
                                        po_vObservacao          OUT VARCHAR2,
                                        po_vJsonRejeitado       OUT VARCHAR2,
                                        po_vGravarComoBloqueado OUT VARCHAR2) IS
    -- Variáveis
    vnPrazoMedioPedido         PCPLPAG.NUMDIAS%TYPE;
    vvFormaParcelamentoPedido  PCPLPAG.FORMAPARCELAMENTO%TYPE;
    vnPrazoMedioCliente        PCPLPAG.NUMDIAS%TYPE;
    vvOrientacaoCondicaoNaoCad VARCHAR2(32000);
    vvDescricaoPlPagPedido     PCPLPAG.DESCRICAO%TYPE;
    vvDescricaoPlPagCliente    PCPLPAG.DESCRICAO%TYPE;
    vUSAREGRANORMALIZADESC     VARCHAR2(200);
    vvPrazoPlPagMandatorio     PCPROMOCAOMED.PRAZOPLPAGMANDATORIO%TYPE; -- HIS.02239.2018
    vbUsouPrazoPromocao        BOOLEAN; -- HIS.02239.2018
    vvOrientacaoPrazoMedio     VARCHAR2(200);
    vvRotinaPrazoMedio         VARCHAR2(200);
  BEGIN

    -- Inicializa Retornos
    po_vRejeitado           := 'N';
    po_vMotivoRejeitado     := NULL;
    po_vObservacao          := NULL;
    po_vJsonRejeitado       := NULL;
    po_vGravarComoBloqueado := 'N';

    -- Ignorar Validação do Prazo Médio do Cliente - DDMEDICA-3017
    IF (NVL(pi_vOrigemPed,'X') = 'F') AND
       (NVL(pi_vTipoFv,'XX')  IN ('OL','PE')) AND
       (NVL(pi_vIgnorarPrazoMedioCliente,'N') = 'S') THEN
       
      -- Nunca rejeitará por Prazo Médio do Pedido Superior ao do Cliente
      po_vRejeitado := 'N';
       
    ELSE

      -- Regra Especifica -- HIS.02239.2018
      vUSAREGRANORMALIZADESC := FUSA_REGRA_MEDICAMENTOS('99','USAREGRANORMALIZADESC');
  
      -- Pesquisa Prazo Médio do Pedido
      BEGIN
        SELECT NUMDIAS
             , FORMAPARCELAMENTO
             , DESCRICAO
          INTO vnPrazoMedioPedido
             , vvFormaParcelamentoPedido
             , vvDescricaoPlPagPedido
          FROM PCPLPAG
         WHERE (CODPLPAG = pi_nCodPlPagPedido);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnPrazoMedioPedido        := 0;
          vvFormaParcelamentoPedido := NULL;
          vvDescricaoPlPagPedido    := NULL;
      END;
  
      -- Pesquisa Dados da Promoção - HIS.02239.2018
      BEGIN
        SELECT NVL(PRAZOPLPAGMANDATORIO,'N')
          INTO vvPrazoPlPagMandatorio
          FROM PCPROMOCAOMED
         WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvPrazoPlPagMandatorio := NULL;
      END;
  
      -- Plano de Pagamento com tratamento para o Prazo Mandatório da Promoção - HIS.02239.2018
      IF (vvPrazoPlPagMandatorio = 'S') THEN
  
        vbUsouPrazoPromocao := TRUE;
  
        -- Plano de Pagamento com tratamento para o Prazo Mandatório da Promoção - HIS.02239.2018
        IF (NVL(vUSAREGRANORMALIZADESC,'N') = 'S') THEN
  
          -- Pega maior Prazo Médio da Tabela Normalizada
          FOR vc_Prazo IN (SELECT PCPLPAG.NUMDIAS
                                , PCPLPAG.DESCRICAO
                             FROM PCPLPAG
                                , PCPROMOCAOPLPAGMED
                            WHERE (PCPROMOCAOPLPAGMED.CODPLPAG       = PCPLPAG.CODPLPAG)
                              AND (PCPROMOCAOPLPAGMED.CODPROMOCAOMED = pi_nCodPromocaoMed)
                            ORDER BY PCPLPAG.NUMDIAS DESC) LOOP
            -- Pega primeiro e sai
            vnPrazoMedioCliente     := vc_Prazo.NUMDIAS;
            vvDescricaoPlPagCliente := vc_Prazo.DESCRICAO;
             EXIT;
          END LOOP;
  
        ELSE
  
          -- Pega maior Prazo Médio da Tabela Normalizada
          FOR vc_Prazo IN (SELECT DISTINCT
                                  PCPLPAG.NUMDIAS
                                , PCPLPAG.DESCRICAO
                             FROM PCPLPAG
                                , PCDESCONTO
                            WHERE (PCDESCONTO.CODPLPAG       = PCPLPAG.CODPLPAG)
                              AND (PCDESCONTO.CODPROMOCAOMED = pi_nCodPromocaoMed)
                            ORDER BY PCPLPAG.NUMDIAS DESC) LOOP
            -- Pega primeiro e sai
            vnPrazoMedioCliente     := vc_Prazo.NUMDIAS;
            vvDescricaoPlPagCliente := vc_Prazo.DESCRICAO;
             EXIT;
          END LOOP;
  
        END IF;
  
      ELSE
  
        vbUsouPrazoPromocao := FALSE;
  
        -- Pesquisa Prazo Médio do Cliente
        BEGIN
          SELECT NUMDIAS
               , DESCRICAO
            INTO vnPrazoMedioCliente
               , vvDescricaoPlPagCliente
            FROM PCPLPAG
           WHERE (CODPLPAG = pi_nCodPlPagCliente);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnPrazoMedioCliente     := 0;
            vvDescricaoPlPagCliente := NULL;
        END;
  
      END IF;
  
      -- Se validar o Prazo Médio do Pedido x Prazo Médio do Cliente
      IF (NVL(vnPrazoMedioPedido,0) > NVL(vnPrazoMedioCliente,0)) AND
         (pi_bExistePlPagCli = False) AND
         (NVL(vvFormaParcelamentoPedido,'X') <> 'V') THEN
  
        -- Se não Aceita Planos com Prazo Médio Superior
        IF (NVL(pi_vBloqPrazomdvenda, 'N') = 'S') then
        
          vvOrientacaoPrazoMedio := NULL;
          vvRotinaPrazoMedio     := NULL;
          IF (NVL(pi_vOrigemPed,'X') = 'F') AND
             (NVL(pi_vTipoFv,'XX')  IN ('OL','PE')) AND
             (NVL(pi_vIgnorarPrazoMedioCliente,'N') = 'S') THEN
            vvOrientacaoPrazoMedio := vvOrientacaoPrazoMedio || CHR(13) ||
                                      '- Alterar o Parâmetro da Integradora "Ignorar Validação do Prazo Médio do Pedido x Prazo Médio do Cliente" (Rotina 2302) para S-Sim.';
            vvRotinaPrazoMedio     := ', 2302';                          
          END IF;        
  
          IF (vbUsouPrazoPromocao) THEN
  
            po_vRejeitado       := 'S';
            po_vMotivoRejeitado := 'Prazo Médio do Pedido superior ao Prazo Médio da Promoção';
            po_vObservacao      := 'O Prazo Médio do Pedido (Plano de Pagamento do Pedido igual a "' || pi_nCodPlPagPedido || ' - ' || vvDescricaoPlPagPedido || '" com Prazo Médio igual a "' || vnPrazoMedioPedido || '" dias)' ||
                                   ' é superior ao Prazo Médio da Promoção (Plano de Pagamento da Promoção igual a "' || pi_nCodPlPagCliente || ' - ' || vvDescricaoPlPagCliente || '" com Prazo Médio igual a "' || vnPrazoMedioCliente || '" dias)';
  
            -- Se está deixando gravar como Bloqueado
            IF (NVL(pi_vAceitaVendaBloq,'N') = 'S') THEN
              po_vGravarComoBloqueado    := 'S'; -->> Gravar o Pedido como Bloqueado
              vvOrientacaoCondicaoNaoCad := 'Alternativas para gravar o Pedido na posição Liberado (não bloquear o Pedido): ' || CHR(13) ||
                                            '- Alterar o Parâmetro da Presidência "1456" para aceitar Pedidos com Prazo Médio superior ao da Promoção.' || CHR(13) ||
                                            '- Alterar o Plano de Pagamento da Promoção para um Plano com Prazo Médio igual ou superior a "' || vnPrazoMedioPedido || '" dias (Rotina 2323).' ||
                                            vvOrientacaoPrazoMedio;
            -- Se está rejeitando
            ELSE
              vvOrientacaoCondicaoNaoCad := 'Alternativas para não rejeitar o Pedido: ' || CHR(13) ||
                                            '- Alterar o Parâmetro da Presidência "1456" para aceitar Pedidos com Prazo Médio superior ao da Promoção ou alterar o Parâmetro "1429" para aceitar o Pedido, gravando-o como Bloqueado.' || CHR(13) ||
                                            '- Alterar o Plano de Pagamento da Promoção para um Plano com Prazo Médio igual ou superior a "' || vnPrazoMedioPedido || '" dias (Rotina 2323).' || CHR(13) ||
                                            '- Alterar o Parâmetro da Presidência "1429" para gravar o Pedido como Bloqueado.' ||
                                            vvOrientacaoPrazoMedio;
              vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad || CHR(13) ||
                                            'Após revisão dos cadastros, o Pedido poderá ser reprocessado na Consulta de Pedidos da Rotina 2302, na aba "Pedidos", podendo ser feita a multi-seleção de Pedidos para reprocessamento.';
            END IF;
  
          ELSE
  
            po_vRejeitado       := 'S';
            po_vMotivoRejeitado := 'Prazo Médio do Pedido superior ao Prazo Médio do Cliente';
            po_vObservacao      := 'O Prazo Médio do Pedido (Plano de Pagamento do Pedido igual a "' || pi_nCodPlPagPedido || ' - ' || vvDescricaoPlPagPedido || '" com Prazo Médio igual a "' || vnPrazoMedioPedido || '" dias)' ||
                                   ' é superior ao Prazo Médio do Cliente (Plano de Pagamento do Cliente igual a "' || pi_nCodPlPagCliente || ' - ' || vvDescricaoPlPagCliente || '" com Prazo Médio igual a "' || vnPrazoMedioCliente || '" dias)';
  
            -- Se está deixando gravar como Bloqueado
            IF (NVL(pi_vAceitaVendaBloq,'N') = 'S') THEN
              po_vGravarComoBloqueado    := 'S'; -->> Gravar o Pedido como Bloqueado
              vvOrientacaoCondicaoNaoCad := 'Alternativas para gravar o Pedido na posição Liberado (não bloquear o Pedido): ' || CHR(13) ||
                                            '- Alterar o Parâmetro da Presidência "1456" para aceitar Pedidos com Prazo Médio superior ao do Cliente.' || CHR(13) ||
                                            '- Alterar o Plano de Pagamento do Cliente para um Plano com Prazo Médio igual ou superior a "' || vnPrazoMedioPedido || '" dias (Rotina 1203).' ||
                                            vvOrientacaoPrazoMedio;
            -- Se está rejeitando
            ELSE
              vvOrientacaoCondicaoNaoCad := 'Alternativas para não rejeitar o Pedido: ' || CHR(13) ||
                                            '- Alterar o Parâmetro da Presidência "1456" para aceitar Pedidos com Prazo Médio superior ao do Cliente ou alterar o Parâmetro "1429" para aceitar o Pedido, gravando-o como Bloqueado.' || CHR(13) ||
                                            '- Alterar o Plano de Pagamento do Cliente para um Plano com Prazo Médio igual ou superior a "' || vnPrazoMedioPedido || '" dias (Rotina 1203).' || CHR(13) ||
                                            '- Alterar o Parâmetro da Presidência "1429" para gravar o Pedido como Bloqueado.' ||
                                            vvOrientacaoPrazoMedio;
              vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad || CHR(13) ||
                                            'Após revisão dos cadastros, o Pedido poderá ser reprocessado na Consulta de Pedidos da Rotina 2302, na aba "Pedidos", podendo ser feita a multi-seleção de Pedidos para reprocessamento.';
            END IF;
  
          END IF;
  
          po_vJsonRejeitado := func_gerarlogjson(po_vMotivoRejeitado,
                                                 po_vObservacao,
                                                 '132, 1203, 2323' || vvRotinaPrazoMedio,
                                                 '1456,1429',
                                                 NULL,
                                                 vvOrientacaoCondicaoNaoCad);
  
        END IF; -- Fim Condição: Se não aceita planos com Prazo Médio Superior
  
      END IF; -- Fim Condição: Se Valida Prazo Médio

    END IF; -- Fim Condição: Se Ignora Validação do Prazo Médio

  END proc_validaprazomediopedido;

 /***********************************************************************************************
  PROCEDURE: proc_validaprazomaxcobranca
  DESCRIÇÃO: Validar Prazo Máximo da Cobrança - MED-1499
  ***********************************************************************************************/
  PROCEDURE proc_validaprazomaxcobranca(pi_vCodCobPedido        IN VARCHAR2,
                                        pi_nCodPlPagPedido      IN NUMBER,
                                        pi_bValidaNivelCob      IN BOOLEAN,
                                        po_vRejeitado           OUT VARCHAR2,
                                        po_vMotivoRejeitado     OUT VARCHAR2,
                                        po_vObservacao          OUT VARCHAR2,
                                        po_vJsonRejeitado       OUT VARCHAR2) IS
    -- Variáveis
    vnPrazoMaximoVenda         PCCOB.PRAZOMAXIMOVENDA%TYPE;
    vnPrazoMedioPedido         PCPLPAG.NUMDIAS%TYPE;
    vvOrientacaoCondicaoNaoCad VARCHAR2(32000);
    vvDescricaoPlPagPedido     PCPLPAG.DESCRICAO%TYPE;
  BEGIN

    -- Inicializa Retornos
    po_vRejeitado           := 'N';
    po_vMotivoRejeitado     := NULL;
    po_vObservacao          := NULL;
    po_vJsonRejeitado       := NULL;

    -- Busca Prazo Máximo da Cobrança
    BEGIN
      SELECT NVL(PRAZOMAXIMOVENDA,0)
        INTO vnPrazoMaximoVenda
        FROM PCCOB
       WHERE (UPPER(TRIM(CODCOB)) = UPPER(TRIM(pi_vCodCobPedido)));
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnPrazoMaximoVenda := 0;
    END;

    -- Pesquisa Prazo Médio do Pedido
    BEGIN
      SELECT NUMDIAS
           , DESCRICAO
        INTO vnPrazoMedioPedido
           , vvDescricaoPlPagPedido
        FROM PCPLPAG
       WHERE (CODPLPAG = pi_nCodPlPagPedido);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnPrazoMedioPedido     := 0;
        vvDescricaoPlPagPedido := NULL;
    END;

    -- Se o Prazo Médio do Pedido superior ao Prazo Máximo da Cobrança do Pedido
    IF (NVL(vnPrazoMedioPedido,0) > NVL(vnPrazoMaximoVenda,0)) AND
       (pi_bValidaNivelCob = True) THEN

      po_vRejeitado       := 'S';
      po_vMotivoRejeitado := 'Prazo Médio do Pedido superior ao Prazo Máximo da Cobrança do Pedido';
      po_vObservacao      := 'O Prazo Médio do Pedido (Plano de Pagamento do Pedido igual a "' || pi_nCodPlPagPedido || ' - ' || vvDescricaoPlPagPedido || '" com Prazo Médio igual a "' || vnPrazoMedioPedido || '" dias)' ||
                             ' é superior ao Prazo Máximo da Cobrança do Pedido (Código da Cobrança do Pedido igual a "' || pi_vCodCobPedido || '" com Prazo Máximo igual a "' || vnPrazoMaximoVenda || '" dias).';

      vvOrientacaoCondicaoNaoCad := 'Alternativas para não rejeitar o Pedido: ' || CHR(13) ||
                                    '- Aumentar o Prazo Máximo da Cobrança "' || pi_vCodCobPedido || '" - Cobrança do Pedido (Rotina 522 - Cadastrar Tipo de Cobrança) para um valor igual ou superior a "' || vnPrazoMedioPedido || '" dias.' || CHR(13) ||
                                    '- Alterar a Cobrança do Cliente para uma Cobrança com Prazo Máximo igual ou superior a "' || vnPrazoMedioPedido || '" dias (Rotina 1203).' || CHR(13) ||
                                    '- Alterar o Plano de Pagamento do Pedido (conforme opção "Tipo de Plano de Pagamento" definida na Rotina 2311 - Cadastro de Condições de Venda) para um Plano com Prazo Médio igual ou inferior a "' || vnPrazoMaximoVenda || '" dias (Rotina 2311 se Plano da Linha ou Rotina 1203 se Plano do Cliente).';
      vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad || CHR(13) ||
                                    'Após revisão dos cadastros, o Pedido poderá ser reprocessado na Consulta de Pedidos da Rotina 2302, na aba "Pedidos", podendo ser feita a multi-seleção de Pedidos para reprocessamento.';

      po_vJsonRejeitado := func_gerarlogjson(po_vMotivoRejeitado,
                                             po_vObservacao,
                                             '522, 1203, 2311',
                                             NULL,
                                             NULL,
                                             vvOrientacaoCondicaoNaoCad);

    END IF;

  END proc_validaprazomaxcobranca;

 /***********************************************************************************************
  PROCEDURE: proc_validanivelcobranca
  DESCRIÇÃO: Validar Nivel da Cobrança - MED-1499
  ***********************************************************************************************/
  PROCEDURE proc_validanivelcobranca(pi_vCodCobCliente       IN VARCHAR2,
                                     pi_vCodCobPedido        IN VARCHAR2,
                                     pi_bValidaNivelCob      IN BOOLEAN,
                                     po_vRejeitado           OUT VARCHAR2,
                                     po_vMotivoRejeitado     OUT VARCHAR2,
                                     po_vObservacao          OUT VARCHAR2,
                                     po_vJsonRejeitado       OUT VARCHAR2) IS
    -- Variáveis
    vnNivelVendaCliente        PCCOB.NIVELVENDA%TYPE;
    vnNivelVendaPedido         PCCOB.NIVELVENDA%TYPE;
    vvOrientacaoCondicaoNaoCad VARCHAR2(32000);
  BEGIN

    -- Inicializa Retornos
    po_vRejeitado           := 'N';
    po_vMotivoRejeitado     := NULL;
    po_vObservacao          := NULL;
    po_vJsonRejeitado       := NULL;

    -- Busca Nível de Venda da Cobrança do Cliente
    BEGIN
      SELECT NVL(NIVELVENDA,0)
        INTO vnNivelVendaCliente
        FROM PCCOB
       WHERE (UPPER(TRIM(CODCOB)) = UPPER(TRIM(pi_vCodCobCliente)));
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnNivelVendaCliente := 0;
    END;

    -- Busca Nível de Venda da Cobrança do Pedido
    BEGIN
      SELECT NVL(NIVELVENDA,0)
        INTO vnNivelVendaPedido
        FROM PCCOB
       WHERE (UPPER(TRIM(CODCOB)) = UPPER(TRIM(pi_vCodCobPedido)));
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnNivelVendaPedido := 0;
    END;

    -- Se o Nível de Venda da Cobrança do Pedido inferior ao Nível de Venda da Cobrança do Cliente
    IF (NVL(vnNivelVendaPedido,0) < NVL(vnNivelVendaCliente,0)) AND
       (pi_bValidaNivelCob = True) THEN

      po_vRejeitado       := 'S';
      po_vMotivoRejeitado := 'Nível de Venda da Cobrança do Pedido inferior ao Nível de Venda da Cobrança do Cliente';
      po_vObservacao      := 'O Nível de Venda da Cobrança do Pedido (Código da Cobrança do Pedido igual a "' || pi_vCodCobPedido || '" com Nível de Venda de valor igual a "' || vnNivelVendaPedido || '")' ||
                             ' é inferior ao Nível de Venda da Cobrança do Cliente (Código da Cobrança do Cliente igual a "' || pi_vCodCobCliente || '" com Nível de Venda de valor igual a "' || vnNivelVendaCliente || '".';

      vvOrientacaoCondicaoNaoCad := 'Alternativas para não rejeitar o Pedido: ' || CHR(13) ||
                                    '- Aumentar o Nível de Venda da Cobrança "' || vnNivelVendaPedido || '" - Cobrança do Pedido) (Rotina 522 - Cadastrar Tipo de Cobrança) para um valor igual ou superior a "' || vnNivelVendaCliente || '".' || CHR(13) ||
                                    '- Diminuir o Nível de Venda da Cobrança "' || vnNivelVendaCliente || '" - Cobrança do Cliente) (Rotina 522 - Cadastrar Tipo de Cobrança) para um valor igual ou inferior a "' || vnNivelVendaPedido || '".' || CHR(13) ||
                                    '- Alterar a Cobrança do Cliente para uma Cobrança com Nível de Venda igual ou inferior a "' || vnNivelVendaPedido || '" (Rotina 1203).';
      vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad || CHR(13) ||
                                    'Após revisão dos cadastros, o Pedido poderá ser reprocessado na Consulta de Pedidos da Rotina 2302, na aba "Pedidos", podendo ser feita a multi-seleção de Pedidos para reprocessamento.';

      po_vJsonRejeitado := func_gerarlogjson(po_vMotivoRejeitado,
                                             po_vObservacao,
                                             '522, 1203',
                                             NULL,
                                             NULL,
                                             vvOrientacaoCondicaoNaoCad);

    END IF;

  END proc_validanivelcobranca;

 /***********************************************************************************************
  PROCEDURE: proc_validavalorcgccli
  DESCRIÇÃO: Validar valor gravado no CGC do Cliente - MED-1499
  ***********************************************************************************************/
  PROCEDURE proc_validavalorcgccli(pi_vCgcCli          IN  VARCHAR2,
                                   pi_nCodCli          IN  NUMBER,
                                   pi_nIntegradora     IN  NUMBER,
                                   po_vRejeitado       OUT VARCHAR2,
                                   po_vMotivoRejeitado OUT VARCHAR2,
                                   po_vObservacao      OUT VARCHAR2,
                                   po_vJsonRejeitado   OUT VARCHAR2) IS
    -- Variáveis
    vvOrientacaoCondicaoNaoCad VARCHAR2(32000);
  BEGIN

    -- Inicializa Retornos
    po_vRejeitado           := 'N';
    po_vMotivoRejeitado     := NULL;
    po_vObservacao          := NULL;
    po_vJsonRejeitado       := NULL;

    -- Se não foi encontrado o CGC do Cliente no Arquivo
    IF (pi_vCgcCli = '0') AND
       (NVL(pi_nCodCli,0) = 0) THEN

      po_vRejeitado       := 'S';
      po_vMotivoRejeitado := 'CNPJ do Cliente não foi encontrado no arquivo';
      po_vObservacao      := 'O CNPJ do Cliente não foi encontrado no arquivo.';

      vvOrientacaoCondicaoNaoCad := 'Normalmente este problema ocorre quando a versão do arquivo é diferente da versão do Layout cadastrado na Integradora.' || CHR(13) ||
                                    'Eventualmente o problema ocorre por Layout do arquivo incompatível com o Layout configurado na Integradora.' || CHR(13) ||
                                    'Verifique no Cadastro da Integradora com código igual = "' || pi_nIntegradora || '" a versão do Layout.';
      vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad || CHR(13) ||
                                    'Após a revisão dos cadastros e do Layout da Integração, o arquivo precisa ser importado novamente.' || CHR(13) ||
                                    'Importante: Reprocessar o Pedido pela Rotina 2302 não resolverá o problema, porque os dados do Pedido precisam ser corrigidos. Somente uma nova leitura do arquivo fará a correção do Pedido.';
      vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad || CHR(13) ||
                                    'Se o problema persistir verifique se o arquivo recebido está de acordo com o Layout selecionado na Integradora.';

      po_vJsonRejeitado := func_gerarlogjson(po_vMotivoRejeitado,
                                             po_vObservacao,
                                             '2302',
                                             NULL,
                                             NULL,
                                             vvOrientacaoCondicaoNaoCad);

    END IF;

  END proc_validavalorcgccli;

 /***********************************************************************************************
  PROCEDURE: proc_validacreditocliente
  DESCRIÇÃO: Validar Limite de Crédito do Cliente - MED-1499
  ***********************************************************************************************/
  PROCEDURE proc_validacreditocliente(pi_nNumPed                  IN  NUMBER,
                                      pi_nCodCli                  IN  NUMBER,
                                      pi_nCodCliPrincipal         IN  NUMBER,
                                      pi_nCodUsur                 IN  NUMBER,
                                      pi_nLimiteCredito           IN  NUMBER,
                                      pi_nVlTotPed                IN  NUMBER,
                                      pi_vSomaCreditoCliPrincipal IN  VARCHAR2,
                                      pi_vUsaBnfLimiteCredito     IN  VARCHAR2,
                                      pi_nPerExcedeLimCred        IN  NUMBER,
                                      pi_nNumCasasDecVenda        IN  NUMBER,
                                      pi_vAtualizarAutorizacao    IN  VARCHAR2,
                                      pi_vBloqPedLimCred          IN  VARCHAR2,
                                      po_vRejeitado               OUT VARCHAR2,
                                      po_vMotivoRejeitado         OUT VARCHAR2,
                                      po_vObservacao              OUT VARCHAR2,
                                      po_vJsonRejeitado           OUT VARCHAR2,
                                      po_vGravarComoBloqueado     OUT VARCHAR2,
                                      po_nValorRetorno            OUT VARCHAR2,
                                      po_vLogDetalheLimiteRetorno OUT VARCHAR2) IS
    -- Variáveis
    vvOrientacaoCondicaoNaoCad VARCHAR2(32000);
    vvOrientacaoDetalheLimCred VARCHAR2(32000);
    vncontasareceberemaberto   number;
    vnvalorpedidospendentes    number;
    vnsaldodisponivel          number;
    vbpodecomprar              boolean;
    vnsaldoinicial             number;
    vnvalorautorizacao         number;
    vnNumAutorizacao           number; -- DDVENDAS-32516
    --DDMEDICA-1245
    vdatavalidadecredito       date;

    -- Parâmetro Específico - DDMEDICA-6036
    vUSALIMCREDSANZONALPEDIDO  PCREGRASEXCECAOMED.VALOR%TYPE;
    -- Valor Total em Cheques - DDVENDAS-38538
    vnvalortotalcheques        number;
    -- Limite Crédito Extra - DDVENDAS-38538
    vnLimiteCreditoExtra       number;
    -- Limite Crédito Sazonal - DDVENDAS-38538
    vnLimiteCreditoSanzonal    number;
    -- Saldo Disponivel Total
    vnsaldodisponiveltotal     number;

    -- Função Auxiliar
    function func_validaautorizacaopcautorc(pi_nCodCliAux                  IN NUMBER,
                                            pi_nCodCliPrincipalAux         IN NUMBER,
                                            pi_nCodUsur                    IN NUMBER,
                                            pi_vSomaCreditoCliPrincipalAux IN VARCHAR2,
                                            pi_nVlDispAux                  IN NUMBER,
                                            pi_nVlAtendAux                 IN NUMBER,
                                            po_nNumAutorizacao             OUT NUMBER) -- DDVENDAS-32516
    return number is

      vnvlliberado number;

    begin

      begin

        select pcautorc.vlliberado
             , pcautorc.numpedido -- DDVENDAS-32516
          into vnvlliberado
             , po_nNumAutorizacao -- DDVENDAS-32516
          from pcautorc, pcempr
          where ((pcautorc.codcli = pi_nCodCli) OR
                (pi_vSomaCreditoCliPrincipalAux = 'S' and ( pcautorc.codcli in (select pcclient.codcli from pcclient where codcliprinc = pi_nCodCliPrincipalAux))))
           and pcautorc.codusur = pi_nCodUsur
           and pcautorc.codfunc = pcempr.matricula
           and pcautorc.liberalimcred = 'S'
           and pcautorc.dtutilizacao is null
           and pcautorc.codfuncutilizacao is null
           and (nvl(pi_nVlDispAux,0) + nvl(pcautorc.vlliberado,0)) >= pi_nVlAtendAux
           and rownum = 1
          order by data;
     exception when others then
       vnvlliberado := 0;
       po_nNumAutorizacao := NULL; -- DDVENDAS-32516
     end;

     return vnvlliberado;

    end func_validaautorizacaopcautorc;

    -- Procedimento Auxiliar
    procedure proc_atualizarpcautorc(pi_nNumPedAux      IN NUMBER,
                                     pi_nCodUsurAux     IN NUMBER,
                                     pi_nCodCliAux      IN NUMBER,
                                     pi_nVlPendenteAux  IN NUMBER,
                                     pi_nLimCredAux     IN NUMBER,
                                     pi_nNumAutorizacao IN NUMBER) is -- DDVENDAS-32516
    begin

      -- DDVENDAS-32516 - Condicionar ao Código da Autorização encontrada
      IF (NVL(pi_nNumAutorizacao,0) > 0) THEN
        for reg in (select *
                    from pcautorc
                    where numpedido = pi_nNumAutorizacao
                      and codfuncutilizacao is null
                      and dtutilizacao is null
                      for update) loop

          exit;
        end loop;

        update pcautorc
        set  limcred = pi_nLimCredAux
             ,vlpendente = pi_nVlPendenteAux
             ,dtutilizacao = trunc(sysdate)
             ,codfuncutilizacao = 8888
             ,numpedutilizacao = pi_nNumPedAux
        where numpedido = pi_nNumAutorizacao
        and codfuncutilizacao is null
        and dtutilizacao is null;
      END IF;

    end proc_atualizarpcautorc;

    -- DDMEDICA-6036
    procedure proc_adicionar_limite_sanzonal(pi_nCodCli                 IN NUMBER,
                                             pi_nCodUsur                IN NUMBER,
                                             pi_nLimiteCredito          IN NUMBER,
                                             pio_nSaldoDisponivel       IN OUT NUMBER,
                                             po_vMensagemLimiteSanzonal OUT VARCHAR2) is
      vnPercLimiteSanzonal  NUMBER;                                         
      vnValorLimiteSanzonal NUMBER;                                         
    begin
    
      po_vMensagemLimiteSanzonal := NULL;
    
      vnPercLimiteSanzonal := 0;
      FOR vc_Limite IN (SELECT percaumento
                          FROM pclimcred
                         WHERE pclimcred.coddcli = pi_nCodCli
                           AND TRUNC( SYSDATE ) BETWEEN pclimcred.dtinicio AND pclimcred.dtfim
                           AND (    ( pclimcred.codusur IS NULL )
                                OR ( pclimcred.codusur = pi_nCodUsur ) )) LOOP
        vnPercLimiteSanzonal := vc_Limite.percaumento;
        EXIT;
      END LOOP;                          
      IF (NVL(vnPercLimiteSanzonal,0) <> 0) THEN
        vnValorLimiteSanzonal      := ROUND(NVL(pi_nLimiteCredito,0) * (NVL(vnPercLimiteSanzonal,0) / 100),2);
        po_vMensagemLimiteSanzonal := '% Limite de crédito sanzonal = ' || vnPercLimiteSanzonal;
        po_vMensagemLimiteSanzonal := po_vMensagemLimiteSanzonal || CHR(13) ||
                                      '(+) Valor do acréscimo de limite de crédito sanzonal = ' || vnValorLimiteSanzonal;
        pio_nSaldoDisponivel       := NVL(pio_nSaldoDisponivel,0) + NVL(vnValorLimiteSanzonal,0);
      END IF;

    end proc_adicionar_limite_sanzonal;

  -- INICIO PROCEDIMENTO
  BEGIN

    -- Inicializa Retornos
    po_vRejeitado           := 'N';
    po_vMotivoRejeitado     := NULL;
    po_vObservacao          := NULL;
    po_vJsonRejeitado       := NULL;
    po_vGravarComoBloqueado := NULL;
    po_nValorRetorno        := 0;

    vnsaldodisponivel       := 0;
    vnsaldodisponiveltotal  := 0;
    vbpodecomprar           := FALSE;

    -- Parâmetro Específico
    vUSALIMCREDSANZONALPEDIDO := FUSA_REGRA_MEDICAMENTOS('99','USALIMCREDSANZONALPEDIDO');  

    -- Pendencias no contas a receber do cliente
    vncontasareceberemaberto := PKG_LIMITECREDITO.RETORNA_CONTAS_RECEBER_ABERTO(pi_nCodCli);
    vnvalorpedidospendentes  := PKG_LIMITECREDITO.RETORNA_PEDIDOS_FATURAR(pi_nCodCli, pi_nNumPed);
    
    -- Total em Cheques
    vnvalortotalcheques      := PKG_LIMITECREDITO.RETORNA_TOTAL_CHEQUE(pi_nCodCli);
    
    -- Guarda Limite de Crédito para mensagem
    vnsaldoinicial           := PKG_LIMITECREDITO.RETORNA_LIMITE_CREDITO_CLIENTE(pi_nCodCli);
    
    -- Limite de Crédito Sazonal 
    vnLimiteCreditoSanzonal  := PKG_LIMITECREDITO.RETORNA_LIMITE_CREDITO_SAZONAL(pi_nCodCli,
                                                                                 pi_nCodUsur);
    
    -- Saldo Disponivel
    vnsaldodisponivel        := PKG_LIMITECREDITO.RETORNA_LIMITE_CRED_DISPONIVEL(pi_nCodCli,
                                                                                 TRUE,  -- UTILIZALIMITEEXTRA
                                                                                 FALSE, -- UTILIZALIMITEPARCEIROS
                                                                                 0);
    
    -- Limite de crédito extra
    vnLimiteCreditoExtra     := PKG_LIMITECREDITO.RETORNA_LIMITE_CREDITO_EXTRA(pi_nCodCli);
    
    -- Saldo Disponível Total (com Sanzonal)
    vnsaldodisponiveltotal   := NVL(vnsaldodisponivel,0) + NVL(vnLimiteCreditoSanzonal,0);

    -- Se NÃO Considera o Limite Disponível do Cliente Principal
    IF (NVL(pi_vSomaCreditoCliPrincipal,'N') = 'N') THEN

      --DDMEDICA-1245
      begin
        select NVL(trunc(pcclient.dtvenclimcred),trunc(sysdate))
          into vdatavalidadecredito
          from pcclient
         where (pcclient.codcli =  pi_nCodCli);
      exception
        when others then
          vdatavalidadecredito := trunc(sysdate);
      end;
      
    ELSE

      --DDMEDICA-1245
      begin
		Select max(dtvenclimcred)
				into vdatavalidadecredito
			from (select NVL(trunc(pcclient.dtvenclimcred), trunc(sysdate)) dtvenclimcred
				from pcclient
			where (pcclient.codcliprinc = pi_nCodCliPrincipal OR pcclient.codcli = pi_nCodCli));
      exception
        when others then
          vdatavalidadecredito := trunc(sysdate);
      end;
    
    END IF;

    IF vdatavalidadecredito >= trunc(sysdate) THEN

      --Calcula o valor disponivel de credito para o cliente
      if nvl(pi_nVlTotPed,0) > nvl(vnsaldodisponiveltotal,0) then

        vnvalorautorizacao := func_validaautorizacaopcautorc(pi_nCodCli,
                                                             pi_nCodCliPrincipal,
                                                             pi_nCodUsur,
                                                             pi_vSomaCreditoCliPrincipal,
                                                             nvl(vnsaldodisponiveltotal,0),
                                                             nvl(pi_nVlTotPed,0),
                                                             vnNumAutorizacao); -- DDVENDAS-32516

        if  (nvl(vnsaldodisponiveltotal,0) + nvl(vnvalorautorizacao,0)) >= nvl(pi_nVlTotPed,0) then

          -- Se chamado para atualizar a autorização
          IF (pi_vAtualizarAutorizacao = 'S') THEN
            proc_atualizarpcautorc(pi_nNumPed,
                                   pi_nCodUsur,
                                   pi_nCodCli,
                                   (NVL(vncontasareceberemaberto, 0) +  NVL(vnvalorpedidospendentes, 0)),
                                   nvl(pi_nLimiteCredito,0),
                                   vnNumAutorizacao); -- DDVENDAS-32516
          END IF;

          vbpodecomprar := true;

        else

          vbpodecomprar := false;

        end if;

      else

        vbpodecomprar := true;

      end if;
    
    ELSE
    
        vbpodecomprar := false;
        
    END IF;
    
    --INICIO: LOG DETALHAMENTO DO LIMITE DE CRÉDITO - DDMEDICA-3551
    vvOrientacaoDetalheLimCred := '*** Observações do Limite de Crédito do Cliente ***' || CHR(13);
    IF (NVL(pi_vSomaCreditoCliPrincipal,'N') = 'S') THEN
      vvOrientacaoDetalheLimCred := vvOrientacaoDetalheLimCred || CHR(13) ||
                                    '* Empresa considera o limite de crédito disponível do cliente principal (Parâmetro 2553).' || CHR(13) ||
                                    'Código do Cliente Principal = "' || pi_nCodCliPrincipal || '"';
      vvOrientacaoDetalheLimCred := vvOrientacaoDetalheLimCred || CHR(13) ||
                                    '>> Valor do limite de crédito do cliente principal = ' || FFORMATAR_NUMERO_PARA_TEXTO(nvl(vnsaldoinicial,0),2);
    ELSE
      vvOrientacaoDetalheLimCred := vvOrientacaoDetalheLimCred || CHR(13) ||
                                    '* Empresa não considera o limite de crédito disponível do cliente principal (Parâmetro 2553).';
      vvOrientacaoDetalheLimCred := vvOrientacaoDetalheLimCred || CHR(13) ||
                                    '>> Valor do limite de crédito do cliente = ' || FFORMATAR_NUMERO_PARA_TEXTO(nvl(vnsaldoinicial,0),2);
    END IF;

    vvOrientacaoDetalheLimCred := vvOrientacaoDetalheLimCred || CHR(13) ||
                                  '% máximo para exceder limite de crédito (Rotina 132) = ' || FFORMATAR_NUMERO_PARA_TEXTO(nvl(pi_nPerExcedeLimCred,0),2) || ' (Parâmetro 1094)';
    IF (nvl(pi_nPerExcedeLimCred,0) <> 0) THEN
      vvOrientacaoDetalheLimCred := vvOrientacaoDetalheLimCred || CHR(13) ||
                                    '(+) Valor do limite de crédito excedente (Rotina 132) = ' || FFORMATAR_NUMERO_PARA_TEXTO(nvl(vnLimiteCreditoExtra,0),2);
    END IF;

    IF (NVL(pi_vUsaBnfLimiteCredito,'N') = 'S') THEN
      vvOrientacaoDetalheLimCred := vvOrientacaoDetalheLimCred || CHR(13) ||
                                    '* Empresa usa bonificações em aberto para diminuir o limite de crédito do cliente (Parâmetro 2583).';
      vvOrientacaoDetalheLimCred := vvOrientacaoDetalheLimCred || CHR(13) ||
                                    '(-) Valor do contas a receber em aberto com bonificações = ' || FFORMATAR_NUMERO_PARA_TEXTO(nvl(vncontasareceberemaberto,0),2);
      vvOrientacaoDetalheLimCred := vvOrientacaoDetalheLimCred || CHR(13) ||
                                    '(-) Valor do saldo de pedidos não faturados com bonificações = ' || FFORMATAR_NUMERO_PARA_TEXTO(nvl(vnvalorpedidospendentes,0),2);
    ELSE
      vvOrientacaoDetalheLimCred := vvOrientacaoDetalheLimCred || CHR(13) ||
                                    '* Empresa não usa bonificações em aberto para diminuir o limite de crédito do cliente (Parâmetro 2583)).';
      vvOrientacaoDetalheLimCred := vvOrientacaoDetalheLimCred || CHR(13) ||
                                    '(-) Valor do contas a receber em aberto sem bonificações = ' || FFORMATAR_NUMERO_PARA_TEXTO(nvl(vncontasareceberemaberto,0),2);
      vvOrientacaoDetalheLimCred := vvOrientacaoDetalheLimCred || CHR(13) ||
                                    '(-) Valor do saldo de pedidos não faturados sem bonificações = ' || FFORMATAR_NUMERO_PARA_TEXTO(nvl(vnvalorpedidospendentes,0),2);
    END IF;
        
    IF (NVL(vnvalorautorizacao,0) <> 0) THEN
      vvOrientacaoDetalheLimCred := vvOrientacaoDetalheLimCred || CHR(13) ||
                                    '(+) Valor adicional de limite autorizado = ' || FFORMATAR_NUMERO_PARA_TEXTO(nvl(vnvalorautorizacao,0),2);
    END IF;
    vvOrientacaoDetalheLimCred := vvOrientacaoDetalheLimCred || CHR(13) ||
                                  '(=) SALDO DISPONIVEL = ' || FFORMATAR_NUMERO_PARA_TEXTO(nvl(vnsaldodisponivel,0) + nvl(vnvalorautorizacao,0),2);
    
    -- DDMEDICA-6036
    IF (NVL(vnLimiteCreditoSanzonal,0) > 0) THEN
      vvOrientacaoDetalheLimCred := vvOrientacaoDetalheLimCred || CHR(13) ||
                                    '(+) Sazonalidade de Limite de Crédito (Rotina 3321) = ' || ROUND(nvl(vnLimiteCreditoSanzonal,0),2);
      vvOrientacaoDetalheLimCred := vvOrientacaoDetalheLimCred || CHR(13) ||
                                    '(=) SALDO DISPONIVEL + Limite Sazonal  = ' || FFORMATAR_NUMERO_PARA_TEXTO(nvl(vnsaldodisponiveltotal,0),2);
    END IF;                                
    
    
    vvOrientacaoDetalheLimCred := vvOrientacaoDetalheLimCred || CHR(13) || CHR(13) ||
                                  '>> VALOR TOTAL DO PEDIDO = ' || FFORMATAR_NUMERO_PARA_TEXTO(nvl(pi_nVlTotPed,0),2);
    --FIM: LOG DETALHAMENTO DO LIMITE DE CRÉDITO - DDMEDICA-3551

    -- SE NÃO PODE COMPRAR
    IF (NOT vbpodecomprar) THEN

      po_vRejeitado       := 'S';

      --DDMEDICA-1245
      IF vdatavalidadecredito >= trunc(sysdate) THEN
        po_vMotivoRejeitado := 'Cliente sem Limite de Crédito Disponível';
        po_vObservacao      := 'O Valor Total do Pedido: ' ||  FFORMATAR_NUMERO_PARA_TEXTO(nvl(pi_nVlTotPed,0),2) || CHR(13) ||
                               'superior ao Limite de Crédito Disponível: ' ||  FFORMATAR_NUMERO_PARA_TEXTO(nvl(vnsaldodisponivel,0),2);

        -- Se está deixando gravar como Bloqueado
        IF (NVL(pi_vBloqPedLimCred,'N') = 'S') THEN
          po_vGravarComoBloqueado    := 'S'; -->> Gravar o Pedido como Bloqueado
          vvOrientacaoCondicaoNaoCad := 'Para gravar o Pedido na posição Liberado (não bloquear o Pedido), verifique com o departamento financeiro a possibilidade de aumentar o Limite de Crédito do Cliente.';
        -- Se está rejeitando
        ELSE
          vvOrientacaoCondicaoNaoCad := 'Alternativas para não rejeitar o Pedido: ' || CHR(13) ||
                                        '- Alterar o Parâmetro da Presidência "2697" para gravar o Pedido como Bloqueado.' || CHR(13) ||
                                        '- Verificar com o departamento financeiro a possibilidade de aumento do Limite de Crédito do Cliente.';
          vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad || CHR(13) ||
                                        'Após revisão do Limite de Crédito do Cliente, o Pedido poderá ser reprocessado na Consulta de Pedidos da Rotina 2302, na aba "Pedidos", podendo ser feita a multi-seleção de Pedidos para reprocessamento.';
        END IF;

      ELSE
        po_vMotivoRejeitado := 'Cliente com a data de vencimento do Limite de Crédito utrapassado';
        po_vObservacao      := 'A data de vencimento do limite de crédito do cliente : ' ||  vdatavalidadecredito  || CHR(13) ||
                               'superior a data atual: ' ||  trunc(sysdate);

        -- Se está deixando gravar como Bloqueado
        IF (NVL(pi_vBloqPedLimCred,'N') = 'S') THEN
          po_vGravarComoBloqueado    := 'S'; -->> Gravar o Pedido como Bloqueado
          vvOrientacaoCondicaoNaoCad := 'Para gravar o Pedido na posição Liberado (não bloquear o Pedido), verifique com o departamento financeiro a possibilidade de alterar a data de vencimento do Limite de Crédito do Cliente.';
        -- Se está rejeitando
        ELSE
          vvOrientacaoCondicaoNaoCad := 'Alternativas para não rejeitar o Pedido: ' || CHR(13) ||
                                        '- Alterar o Parâmetro da Presidência "2697" para gravar o Pedido como Bloqueado.' || CHR(13) ||
                                        '- Verificar com o departamento financeiro a possibilidade de alterar a data de vencimento do Limite de Crédito Cliente.';
          vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad || CHR(13) ||
                                        'Após revisão da data de vencimento do Limite de Crédito do Cliente, o Pedido poderá ser reprocessado na Consulta de Pedidos da Rotina 2302, na aba "Pedidos", podendo ser feita a multi-seleção de Pedidos para reprocessamento.';
        END IF;
      END IF;

      vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad || CHR(13) || CHR(13) ||
                                    vvOrientacaoDetalheLimCred; -- DDMEDICA-3551

      po_vJsonRejeitado := func_gerarlogjson(po_vMotivoRejeitado,
                                             po_vObservacao,
                                             '1203',
                                             '2697, 2553, 2583, 1094',
                                             NULL,
                                             vvOrientacaoCondicaoNaoCad);

    END IF;

    -- Retornará o Saldo Disponível calculado
    po_nValorRetorno := nvl(vnsaldodisponivel,0);

    -- Retornará também o Log de Detalhamento do Limite de Crédito - DDMEDICA-3551
    po_vLogDetalheLimiteRetorno := vvOrientacaoDetalheLimCred;

  END proc_validacreditocliente;

 /***********************************************************************************************
  PROCEDURE: proc_validarestricaovenda
  DESCRIÇÃO: Validar Cadastro de Restrições de Venda - MED-1499
  ***********************************************************************************************/
  PROCEDURE proc_validarestricaovenda(pi_vTipoCriticaRestricaoVenda IN VARCHAR2,
                                      pi_nRotinaParamTipoCriticaRes IN NUMBER,
                                      pi_vTipoFv                    IN VARCHAR2,
                                      pi_nCodProd                   IN NUMBER,
                                      pi_nNumRegiao                 IN NUMBER,
                                      pi_nCodCli                    IN NUMBER,
                                      pi_nCodUsur                   IN NUMBER,
                                      pi_nCodFornec                 IN NUMBER,
                                      pi_nCodPraca                  IN NUMBER,
                                      pi_vClasseProduto             IN VARCHAR2,
                                      pi_nCodAtiv                   IN NUMBER,
                                      pi_nCodSupervisor             IN NUMBER,
                                      pi_vCodFilial                 IN VARCHAR2,
                                      pi_nCondVenda                 IN NUMBER,
                                      pi_vFreteDespacho             IN VARCHAR2,
                                      pi_vOrigemPed                 IN VARCHAR2,
                                      pi_nCodAuxiliar               IN NUMBER,
                                      pi_nCodPlPag                  IN NUMBER,
                                      pi_vCodCob                    IN VARCHAR2,
                                      pi_nCodMarca                  IN NUMBER,
                                      pi_nVlAtend                   IN NUMBER,
                                      po_vRejeitado                 OUT VARCHAR2,
                                      po_vMotivoRejeitado           OUT VARCHAR2,
                                      po_vObservacao                OUT VARCHAR2,
                                      po_vJsonRejeitado             OUT VARCHAR2) IS
    -- Variáveis
    vnCodRestricao             PCRESTRICAOVENDA.CODRESTRICAO%TYPE;
    vvMotivoRestricao          VARCHAR2(32000);
    vsTipoFJ                   PCCLIENT.TIPOFJ%TYPE;
    vnCodepto                  PCPRODUT.CODEPTO%TYPE;
    vnCodSec                   PCPRODUT.CODSEC%TYPE;
    vbValido                   BOOLEAN;
    vvOrientacaoCondicaoNaoCad VARCHAR2(32000);
    vvDescricaoOpcao           VARCHAR2(250);

  BEGIN

    -- Inicializa Código e Motivo da Restrição
    vnCodRestricao    := NULL;
    vvMotivoRestricao := 'Motivo da Restrição:';

    -- Define descrição da Opção
    IF    (pi_nRotinaParamTipoCriticaRes = 2302) THEN
      vvDescricaoOpcao := ', conforme opção definida nos parâmetro da integradora "Tipo de Critica de Restrição de Venda" (Rotina 2302)';
    ELSIF (pi_nRotinaParamTipoCriticaRes = -132) THEN
      vvDescricaoOpcao := ', conforme opção definida na parâmetro da presidência "9858 - Tipo de Critica de Restrição de Venda na Importação de Pedidos" (Rotina 132)';
    ELSE
      vvDescricaoOpcao := ', conforme opção definida no parâmetro da presidência "2354 - Tipo para importação de vendas" (Rotina 132)';
    END IF;

    -- Pesquisa Dados do Cliente
    BEGIN
      select tipofj
        into vsTipoFJ
        from pcclient
       where codcli = pi_nCodCli;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vsTipoFJ := NULL;
    END;

    -- Pesquisa Dados do Produto
    BEGIN
      select codsec
           , codepto
        into vnCodSec
           , vnCodepto
        from pcprodut
       where codprod = pi_nCodProd;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnCodSec  := NULL;
        vnCodepto := NULL;
    END;

    -- Laço de Restrições
    FOR vc_Restricao IN (SELECT codrestricao
                              , codcli
                              , codprod
                              , numregiao
                              , codfornec
                              , codpraca
                              , codusur
                              , codativ
                              , classeproduto
                              , codepto
                              , codsec
                              , codsupervisor
                              , tipofj
                              , codfilial
                              , condvenda
                              , fretedespacho
                              , origemped
                              , codauxiliar
                              , codcob
                              , codplpag
                              , codmarca
                              , valorminimovenda
                           FROM pcrestricaovenda
                          WHERE ((codcli = pi_nCodCli) OR (codcli IS NULL))
                            AND ((codprod = pi_nCodProd) OR (codprod IS NULL))
                            AND ((numregiao = pi_nNumRegiao) OR (numregiao IS NULL))
                            AND ((codfornec = pi_nCodFornec) OR (codfornec IS NULL))
                            AND ((codpraca = pi_nCodPraca) OR (codpraca IS NULL))
                            AND ((codusur = pi_nCodUsur) OR (codusur IS NULL))
                            AND ((codativ = pi_nCodAtiv) OR (codativ IS NULL))
                            AND ((classeproduto = pi_vClasseProduto) OR (classeproduto IS NULL))
                            AND ((codepto = vnCodepto) OR (codepto IS NULL))
                            AND ((codsec = vnCodSec) OR (codsec IS NULL))
                            AND ((codsupervisor = pi_nCodSupervisor) OR (codsupervisor IS NULL))
                            AND ((tipofj = vsTipoFJ) OR (tipofj IS NULL))
                            AND ((codfilial = pi_vCodFilial) OR (codfilial IS NULL))
                            and ((condvenda = pi_nCondVenda) OR (condvenda is null))
                            and ((fretedespacho = pi_vFreteDespacho) OR (fretedespacho is null) OR (fretedespacho = 'T'))
                            and ((origemped = pi_vOrigemPed) OR (origemped is null) OR (origemped = 'O'))
                            and ((codauxiliar = pi_nCodAuxiliar) OR (codauxiliar is null))
                            and ((codcob = pi_vCodCob) OR (codcob is null))
                            and ((codplpag = pi_nCodPlPag) OR (codplpag is null))
                            AND ((codmarca = pi_nCodMarca) OR (codmarca IS NULL))) LOOP

      -- Exceções
      vbValido := TRUE;
      IF (NVL(pi_vTipoFv,'FV') IN ('OL','PE')) AND
         (NVL(vc_Restricao.valorminimovenda,0) > 0) THEN
        -- OL e PE não validam Valor Mínimo venda aqui, somente na 2311
        vbValido := FALSE;
      END IF;

      -->> Se achar a primeira restrição VÁLIDA
      IF (vbValido) THEN

        -- Motivos da Restrição
        IF (vc_Restricao.codcli = pi_nCodCli) THEN
          vvMotivoRestricao := vvMotivoRestricao || CHR(13) || 'Código do Cliente: ' || pi_nCodCli;
        END IF;
        IF (vc_Restricao.codprod = pi_nCodProd) THEN
          vvMotivoRestricao := vvMotivoRestricao || CHR(13) || 'Código do Produto: ' || pi_nCodProd;
        END IF;
        IF (vc_Restricao.numregiao = pi_nNumRegiao) THEN
          vvMotivoRestricao := vvMotivoRestricao || CHR(13) || 'Número da Região: ' || pi_nNumRegiao;
        END IF;
        IF (vc_Restricao.codfornec = pi_nCodFornec) THEN
          vvMotivoRestricao := vvMotivoRestricao || CHR(13) || 'Código do Fornecedor: ' || pi_nCodFornec;
        END IF;
        IF (vc_Restricao.codpraca = pi_nCodPraca) THEN
          vvMotivoRestricao := vvMotivoRestricao || CHR(13) || 'Código da Praça: ' || pi_nCodPraca;
        END IF;
        IF (vc_Restricao.codusur = pi_nCodUsur) THEN
          vvMotivoRestricao := vvMotivoRestricao || CHR(13) || 'Código do RCA: ' || pi_nCodUsur;
        END IF;
        IF (vc_Restricao.codativ = pi_nCodAtiv) THEN
          vvMotivoRestricao := vvMotivoRestricao || CHR(13) || 'Código do Ramo de Atividade: ' || pi_nCodAtiv;
        END IF;
        IF (vc_Restricao.classeproduto = pi_vClasseProduto) THEN
          vvMotivoRestricao := vvMotivoRestricao || CHR(13) || 'Classe Produto: ' || pi_vClasseProduto;
        END IF;
        IF (vc_Restricao.codepto = vnCodepto) THEN
          vvMotivoRestricao := vvMotivoRestricao || CHR(13) || 'Código do Departamento: ' || vnCodepto;
        END IF;
        IF (vc_Restricao.codsec = vnCodSec) THEN
          vvMotivoRestricao := vvMotivoRestricao || CHR(13) || 'Código da Seção: ' || vnCodSec;
        END IF;
        IF (vc_Restricao.codsupervisor = pi_nCodSupervisor) THEN
          vvMotivoRestricao := vvMotivoRestricao || CHR(13) || 'Código do Supervisor: ' || pi_nCodSupervisor;
        END IF;
        IF (vc_Restricao.tipofj = vsTipoFJ) THEN
          vvMotivoRestricao := vvMotivoRestricao || CHR(13) || 'Tipo de Pessoa Fisica/Jurídica do Cliente: ' || vsTipoFJ;
        END IF;
        IF (vc_Restricao.codfilial = pi_vCodFilial) THEN
          vvMotivoRestricao := vvMotivoRestricao || CHR(13) || 'Código da Filial: ' || pi_vCodFilial;
        END IF;
        IF (vc_Restricao.condvenda = pi_nCondVenda) THEN
          vvMotivoRestricao := vvMotivoRestricao || CHR(13) || 'Tipo de Venda: ' || pi_nCondVenda;
        END IF;
        IF (vc_Restricao.fretedespacho = pi_vFreteDespacho) THEN
          vvMotivoRestricao := vvMotivoRestricao || CHR(13) || 'Tipo de Frete do Pedido: ' || pi_vFreteDespacho;
        END IF;
        IF (vc_Restricao.origemped = pi_vOrigemPed) THEN
          vvMotivoRestricao := vvMotivoRestricao || CHR(13) || 'Origem do Pedido: ' || pi_vOrigemPed;
        END IF;
        IF (vc_Restricao.codauxiliar = pi_nCodAuxiliar) THEN
          vvMotivoRestricao := vvMotivoRestricao || CHR(13) || 'Código EAN: ' || pi_nCodAuxiliar;
        END IF;
        IF (vc_Restricao.codcob = pi_vCodCob) THEN
          vvMotivoRestricao := vvMotivoRestricao || CHR(13) || 'Código da Cobrança: ' || pi_vCodCob;
        END IF;
        IF (vc_Restricao.codplpag = pi_nCodPlPag) THEN
          vvMotivoRestricao := vvMotivoRestricao || CHR(13) || 'Código do Plano de Pagamento: ' || pi_nCodPlPag;
        END IF;
        IF (vc_Restricao.codmarca = pi_nCodMarca) THEN
          vvMotivoRestricao := vvMotivoRestricao || CHR(13) || 'Código da Marca: ' || pi_nCodPlPag;
        END IF;
        IF (NVL(pi_vTipoFv,'FV') NOT IN ('OL','PE')) AND   -->> Se não for OL e PE
           (NVL(pi_nVlAtend,0) > 0)                  THEN  -->> Se estiver validando o valor do Pedido
          IF (NVL(pi_nVlAtend,0) <= NVL(vc_Restricao.valorminimovenda,0)) THEN
            vvMotivoRestricao := vvMotivoRestricao || CHR(13) || 'Valor Atendido inferior ao Valor Mínimo de Venda.' || CHR(13) ||
                                                                 'Valor Atendido = ' || FFORMATAR_NUMERO_PARA_TEXTO(nvl(pi_nVlAtend,0),2) || CHR(13) ||
                                                                 'Valor Mínimo de Venda = ' || FFORMATAR_NUMERO_PARA_TEXTO(nvl(vc_Restricao.valorminimovenda,0),2);
          END IF;
        END IF;

        -- Código da Restrição
        vnCodRestricao := vc_Restricao.codrestricao;

        -- Finaliza Motivo da Descrição
        vvMotivoRestricao := 'Código da Restrição: ' || vnCodRestricao || CHR(13) || vvMotivoRestricao;

        -->> Sai ao achar a primeira restrição VÁLIDA
        EXIT;

      END IF;

    END LOOP;

    -- Se Rejeitou
    IF (NVL(vnCodRestricao,0) > 0) THEN

      po_vRejeitado       := 'S';
      po_vMotivoRejeitado := 'Restrição de Venda';
      po_vObservacao      := 'Existe restrição para esta venda.' || CHR(13) || vvMotivoRestricao;

      IF    (pi_vTipoCriticaRestricaoVenda = 'RI') THEN
        vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad || CHR(13) ||
                                      'O Sistema está configurado para rejeitar o item do pedido com Restrição de Venda' || vvDescricaoOpcao || '.' || CHR(13) ||
                                      'Verifique com o departamento responsável pelo Cadastro da Restrição de Venda (Rotina 391) se a Restrição de Venda encontrada ainda é válida.';
      ELSIF (pi_vTipoCriticaRestricaoVenda = 'RP') THEN
        vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad || CHR(13) ||
                                      'O Sistema está configurado para rejeitar completamente o pedido se ocorrer alguma Restrição de Venda no pedido ou em algum item do pedido' || vvDescricaoOpcao || '.' || CHR(13) ||
                                      'Verifique com o departamento responsável pelo Cadastro da Restrição de Venda (Rotina 391) se a Restrição de Venda encontrada ainda é válida.';
      ELSIF (pi_vTipoCriticaRestricaoVenda = 'BP') THEN
        vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad || CHR(13) ||
                                      'O Sistema está configurado para bloquear o pedido se ocorrer alguma Restrição de Venda no no pedido ou em algum item do pedido,' || vvDescricaoOpcao || '.' || CHR(13) ||
                                      'Verifique com o departamento responsável pelo Cadastro da Restrição de Venda (Rotina 391) se a Restrição de Venda encontrada ainda é válida.';
      END IF;

      IF (pi_vTipoCriticaRestricaoVenda IN ('RP','BP')) THEN
        vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad || CHR(13) ||
                                      'Outra alternativa para não perder a venda é alterar a parametrização para gravar o Pedido como Bloqueado (Parâmetro 2697).';
      END IF;

      po_vJsonRejeitado := func_gerarlogjson(po_vMotivoRejeitado,
                                             po_vObservacao,
                                             '391, 2302',
                                             '2697, 2354, 9858',
                                             NULL,
                                             vvOrientacaoCondicaoNaoCad);
    END IF;

  END proc_validarestricaovenda;

 /***********************************************************************************************
  PROCEDURE: proc_validarestricaovendafil
  DESCRIÇÃO: Validar Cadastro de Restrições de Venda por Filial - DDMEDICA-3464
  ***********************************************************************************************/
  PROCEDURE proc_validarestricaovendafil(pi_vCodFilial        IN VARCHAR2,
                                         pi_vOrigemPed        IN VARCHAR2,
                                         pi_vTipoFv           IN VARCHAR2,
                                         pi_nCodCondicaoVenda IN NUMBER,
                                         po_vRejeitado        OUT VARCHAR2,
                                         po_vMotivoRejeitado  OUT VARCHAR2,
                                         po_vObservacao       OUT VARCHAR2,
                                         po_vJsonRejeitado    OUT VARCHAR2) IS

    -- Variáveis
    vnCodRestricao             PCRESTRICAOVENDA.CODRESTRICAO%TYPE;
    vvMotivoRestricao          VARCHAR2(32000);
    vstipovalorminimo          PCCONDICAOVENDA.TIPOVALORMINIMO%TYPE;    
    vbValido                   BOOLEAN;
    vvOrientacaoCondicaoNaoCad VARCHAR2(32000);

  BEGIN

    -- Inicializa Código e Motivo da Restrição
    vnCodRestricao    := NULL;
    vvMotivoRestricao := 'Motivo da Restrição:';
    
    -- Pesquisa o Tipo de Valor Mínimo da Condição de Venda
    vstipovalorminimo := 'P';
    IF (NVL(pi_nCodCondicaoVenda,0) > 0) AND 
       (NVL(pi_vTipoFv,'FV') IN ('OL','PE')) THEN
      BEGIN
        SELECT NVL(PCCONDICAOVENDA.TIPOVALORMINIMO,'P')
          INTO vstipovalorminimo
          FROM PCCONDICAOVENDA
         WHERE (PCCONDICAOVENDA.CODCONDICAOVENDA = pi_nCodCondicaoVenda);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vstipovalorminimo := 'P';
      END;
    END IF;

    -------------------------------------------------
    -- Laço de Restrições por Filial SEM Valor Mínimo
    -------------------------------------------------
    FOR vc_Restricao IN (SELECT p.codrestricao 
                              , p.motivo
                           from pcrestricaovenda p
                          where p.codfilial = pi_vCodFilial
                          and   p.codcli is null
                          and   p.codprod is null
                          and   p.numregiao is null
                          and   p.codfornec is null
                          and   p.codpraca is null
                          and   p.codusur is null
                          and   p.codativ is null
                          and   p.classeproduto is null
                          and   p.codepto is null
                          and   p.codsec is null
                          and   p.codsupervisor is null
                          and   p.tipofj is null
                          and   ((NVL(p.origemped,'O') = 'O') or (NVL(p.origemped,'O') = pi_vOrigemPed))
                          and   p.condvenda is null
                          and   (p.fretedespacho is null or p.fretedespacho = 'T')
                          and   p.codplpag is null
                          and   p.codcob is null
                          and   p.codmarca is null
                          and   (NVL(p.valorminimovenda,0) = 0)) LOOP -->> Sem Valor Mínimo
                                
      -- Código da Restrição
      vnCodRestricao := vc_Restricao.codrestricao;

      -- Motivo da Restrição
      IF (vc_Restricao.motivo IS NULL) THEN
        vvMotivoRestricao := SUBSTR('Restrição: ' || vnCodRestricao || ' para a Filial: ' || pi_vCodFilial,1,255);
      ELSE
        vvMotivoRestricao := SUBSTR('Restrição: ' || vnCodRestricao || ' para a Filial: ' || pi_vCodFilial || ' (' || vc_Restricao.motivo || ')',1,255);
      END IF;

      -->> Sai ao achar a primeira restrição VÁLIDA
      EXIT;

    END LOOP;

    -- Se Rejeitou
    IF (NVL(vnCodRestricao,0) > 0) THEN

      po_vRejeitado       := 'S';
      po_vMotivoRejeitado := 'Restrição de Venda';
      po_vObservacao      := 'Existe restrição para esta venda.' || CHR(13) || vvMotivoRestricao;

      vvOrientacaoCondicaoNaoCad := 'Verifique com o departamento responsável pelo Cadastro da Restrição de Venda (Rotina 391) se a Restrição de Venda encontrada ainda é válida.';

      po_vJsonRejeitado := func_gerarlogjson(po_vMotivoRejeitado,
                                             po_vObservacao,
                                             '391',
                                             '',
                                             NULL,
                                             vvOrientacaoCondicaoNaoCad);
                                             
    END IF;

  END proc_validarestricaovendafil;

 /***********************************************************************************************
  PROCEDURE: proc_CARREGARDADOSVALIDACAO
  DESCRIÇÃO: Carregar Tabela Temporária com os Dados de Validação - MED-1499
  ***********************************************************************************************/
  PROCEDURE proc_CARREGARDADOSVALIDACAO(pi_nOrigem            IN NUMBER,
                                        pi_nNumPedRca         IN NUMBER,
                                        pi_nCodUsur           IN NUMBER,
                                        pi_vCgcCli            IN VARCHAR2,
                                        pi_dDtAberturaPedPalm IN DATE,
                                        pi_nCodProd           IN NUMBER,
                                        pi_nNumSeq            IN NUMBER,
                                        pi_vTipo              IN VARCHAR2) IS

    -- Variáveis
    vvObservacaoCab   VARCHAR2(32000);
    vvObservacaoItem  VARCHAR2(32000);
    vvParte1          VARCHAR2(4000);
    vvParte2          VARCHAR2(4000);
    vvParte3          VARCHAR2(4000);
    vvParte4          VARCHAR2(4000);
    vvParte5          VARCHAR2(4000);
    vvParte6          VARCHAR2(4000);
    vvParte7          VARCHAR2(4000);
    vvParte8          VARCHAR2(4000);
    vvParte9          VARCHAR2(4000);
    vvParte10         VARCHAR2(4000);
    vvParte11         VARCHAR2(4000);
    vvParte12         VARCHAR2(4000);
    vvParte13         VARCHAR2(4000);
    vvParte14         VARCHAR2(4000);
    vvParte15         VARCHAR2(4000);
    vvParte16         VARCHAR2(4000);
    vvParte17         VARCHAR2(4000);
    vvParte18         VARCHAR2(4000);
    vvParte19         VARCHAR2(4000);
    vvParte20         VARCHAR2(4000);
    vvParte21         VARCHAR2(4000);

    --------------------------------------------
    -- Função para Retornar o Json da Observação
    --------------------------------------------
    FUNCTION F_RETORNA_JSON(pi_vObservacao IN VARCHAR2)
    RETURN VARCHAR2 IS
      -- Retorno
      vvRetJson VARCHAR2(32000);
    BEGIN
      -- Inicializa Retorno
      vvRetJson := NULL;

      -- Se tem Observação
      IF (pi_vObservacao IS NOT NULL) THEN

        -- Pega o Json
        vvRetJson := SUBSTR(pi_vObservacao, 1, 32000);

      END IF;

      -- Retorno
      RETURN vvRetJson;

    END F_RETORNA_JSON;

    ------------------------------------------------
    -- Função para Extrair o Valor da Coluna do JSON
    ------------------------------------------------
    FUNCTION F_EXTRAIR_VALOR_COLUNA(pi_vValor         IN VARCHAR2,
                                    pi_vColuna        IN VARCHAR2,
                                    pi_vProximaColuna IN VARCHAR2)
    RETURN VARCHAR2 IS
      -- Retorno
      vvRetValor VARCHAR2(32000);
      -- Variáveis
      viPosIni   INTEGER;
      viPosFin   INTEGER;
      viLargura  INTEGER;
    BEGIN

      -- Se útima coluna
      IF (pi_vProximaColuna IS NULL) THEN

        --         1         2         3         4         5         6                                                                                         15
        --123456789012345678901234567890123456789012345678901234567890                                                                                         0
        --{ "DESCRICAOREJEICAO": "Descrição da Rejeição", "OBSERVACAO": "Observação da Rejeição", "CODROTINA": "2311", "NUMEROPARAMETRO": "", "PERMISSAO": "", "SOLUCAO": "Solução da Rejeição" }
        viPosIni   := INSTR(pi_vValor, pi_vColuna);                  -- 150
        vvRetValor := SUBSTR(pi_vValor, viPosIni, 32000);            -- '"SOLUCAO": "Solução da Rejeição" }'

        vvRetValor := REPLACE(vvRetValor, pi_vColuna, '');           -- ': "Solução da Rejeição" }'
        vvRetValor := SUBSTR(vvRetValor, 4, LENGTH(vvRetValor));     -- 'Solução da Rejeição" }'
        vvRetValor := SUBSTR(vvRetValor, 1, (LENGTH(vvRetValor)-3)); -- 'Solução da Rejeição'

      -- Se não for última coluna
      ELSE

        --         1         2         3         4         5         6                                                                                         15
        --123456789012345678901234567890123456789012345678901234567890                                                                                         0
        --{ "DESCRICAOREJEICAO": "Descrição da Rejeição", "OBSERVACAO": "Observação da Rejeição", "CODROTINA": "2311", "NUMEROPARAMETRO": "", "PERMISSAO": "", "SOLUCAO": "Solução da Rejeição" }
        viPosIni   := INSTR(pi_vValor, pi_vColuna);                  -- 03
        viPosFin   := INSTR(pi_vValor, pi_vProximaColuna);           -- 49
        viLargura  := (viPosFin - viPosIni);                         -- 46

        vvRetValor := SUBSTR(pi_vValor, viPosIni, viLargura);        -- '"DESCRICAOREJEICAO": "Descrição da Rejeição", '

        vvRetValor := REPLACE(vvRetValor, pi_vColuna, '');           -- ': "Descrição da Rejeição", '
        vvRetValor := SUBSTR(vvRetValor, 4, LENGTH(vvRetValor));     -- 'Descrição da Rejeição", '
        vvRetValor := SUBSTR(vvRetValor, 1, (LENGTH(vvRetValor)-3)); -- 'Descrição da Rejeição'

      END IF;

      -- Retorno
      RETURN vvRetValor;

    END F_EXTRAIR_VALOR_COLUNA;

    -----------------------------------
    -- Procedimento para Inserir o JSON
    -----------------------------------
    PROCEDURE P_INSERE_JSON(pi_vTipoReg    IN VARCHAR2,
                            pi_vObservacao IN VARCHAR2) IS
      -- Variáveis
      vvChar                 VARCHAR2(1);
      vvRegistro             VARCHAR2(32000);
      -- Dados da Tabela
      TYPE TRecDados         IS RECORD(
          vDESCRICAOREJEICAO VARCHAR2(32000),
          vOBSERVACAO        VARCHAR2(32000),
          vCODROTINA         VARCHAR2(32000),
          vNUMEROPARAMETRO   VARCHAR2(32000),
          vPERMISSAO         VARCHAR2(32000),
          vSOLUCAO           VARCHAR2(32000));
      vrDados                TRecDados;

    BEGIN

      -- Se tem Observação
      IF (pi_vObservacao IS NOT NULL) THEN

        -- Varre os caracteres da observação passada no parâmetro
        FOR viLaco IN 1..LENGTH(pi_vObservacao) LOOP

          -- Pega Char do texto da observação passada no parâmetro
          vvChar := SUBSTR(pi_vObservacao,viLaco,1);

          -- Se Inicio de Registro
          IF    (vvChar = '{') THEN

            -- Inicializa Registro
            vvRegistro := vvChar;

          -- Se Fim de Registro
          ELSIF (vvChar = '}') THEN

            -- Finaliza Registro
            vvRegistro := vvRegistro || vvChar;

            -- Finaliza Registro
            vrDados.vDESCRICAOREJEICAO := F_EXTRAIR_VALOR_COLUNA(vvRegistro,'"DESCRICAOREJEICAO"','"OBSERVACAO"');
            vrDados.vOBSERVACAO        := F_EXTRAIR_VALOR_COLUNA(vvRegistro,'"OBSERVACAO"','"CODROTINA"');
            vrDados.vCODROTINA         := F_EXTRAIR_VALOR_COLUNA(vvRegistro,'"CODROTINA"','"NUMEROPARAMETRO"');
            vrDados.vNUMEROPARAMETRO   := F_EXTRAIR_VALOR_COLUNA(vvRegistro,'"NUMEROPARAMETRO"','"PERMISSAO"');
            vrDados.vPERMISSAO         := F_EXTRAIR_VALOR_COLUNA(vvRegistro,'"PERMISSAO"','"SOLUCAO"');
            vrDados.vSOLUCAO           := F_EXTRAIR_VALOR_COLUNA(vvRegistro,'"SOLUCAO"',NULL);

            -- Grava Tabela Temporária
            INSERT INTO PCMED_DADOSVALIDACAO
                      ( TIPOREG
                      , DESCRICAOREJEICAO
                      , OBSERVACAO
                      , CODROTINA
                      , NUMEROPARAMETRO
                      , PERMISSAO
                      , SOLUCAOP1
                      , SOLUCAOP2
                      , SOLUCAOP3
                      , SOLUCAOP4 )
               VALUES ( pi_vTipoReg
                      , SUBSTR(vrDados.vDESCRICAOREJEICAO,1,255)
                      , SUBSTR(vrDados.vOBSERVACAO,1,2000)
                      , SUBSTR(vrDados.vCODROTINA,1,20)
                      , SUBSTR(vrDados.vNUMEROPARAMETRO,1,40)
                      , SUBSTR(vrDados.vPERMISSAO,1,10)
                      , SUBSTR(vrDados.vSOLUCAO,   1,2000)
                      , SUBSTR(vrDados.vSOLUCAO,2001,2000)
                      , SUBSTR(vrDados.vSOLUCAO,4001,2000)
                      , SUBSTR(vrDados.vSOLUCAO,6001,2000) );

          -- Se conteúdo do Registro
          ELSE

            -- Concatena caracter no Registro
            IF (vvRegistro IS NULL) THEN
              vvRegistro := vvChar;
            ELSE
              vvRegistro := vvRegistro || vvChar;
            END IF;

          END IF;

        END LOOP;

      END IF;

    END P_INSERE_JSON;

   /*********************************
    INICIO DO PROCESSAMENTO PRINCIPAL
    *********************************/
  BEGIN

    -- Inicializa Tabela temporaria
    -- DELETE FROM PCMED_DADOSVALIDACAO;
    -- DDMEDICA-5201 Alterado por ser mais eficiente que um delete na tabela inteira
    EXECUTE IMMEDIATE ' TRUNCATE TABLE PCMED_DADOSVALIDACAO ';

   /*************************************************************************************************
    CHAMADO DA ROTINA 2302
    **********************/
    IF (pi_nOrigem = 1) THEN

      --- Inicializa Observações
      vvObservacaoCab  := NULL;
      vvObservacaoItem := NULL;

      -- Pesquisa Observação do Pedido
      IF (pi_vTipo IN ('C','A')) THEN
        -- Pesquisa Log
        BEGIN
          SELECT DBMS_LOB.SUBSTR(MSGPROCMED, 4000,1)
               , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,4001)
               , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,8001)
               , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,12001)
               , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,16001)
               , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,20001)
               , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,24001)
               , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,28001)
               , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,32001)
               , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,36001)
               , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,40001)
               , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,44001)
               , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,48001)
               , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,52001)
               , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,56001)
               , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,60001)
               , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,64001)
               , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,68001)
               , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,72001)
               , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,76001)
               , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,80001)
            INTO vvParte1
               , vvParte2
               , vvParte3
               , vvParte4
               , vvParte5
               , vvParte6
               , vvParte7
               , vvParte8
               , vvParte9
               , vvParte10
               , vvParte11
               , vvParte12
               , vvParte13
               , vvParte14
               , vvParte15
               , vvParte16
               , vvParte17
               , vvParte18
               , vvParte19
               , vvParte20
               , vvParte21
            FROM PCPEDCFV
           WHERE (NUMPEDRCA         = pi_nNumPedRca)
             AND (CODUSUR           = pi_nCodUsur)
             AND (CGCCLI            = pi_vCgcCli)
             AND (DTABERTURAPEDPALM = pi_dDtAberturaPedPalm);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvObservacaoCab := NULL;
        END;
        -- Concatena Json
        vvObservacaoCab := vvParte1  ||
                           vvParte2  ||
                           vvParte3  ||
                           vvParte4  ||
                           vvParte5  ||
                           vvParte6  ||
                           vvParte7  ||
                           vvParte8  ||
                           vvParte9  ||
                           vvParte10 ||
                           vvParte11 ||
                           vvParte12 ||
                           vvParte13 ||
                           vvParte14 ||
                           vvParte15 ||
                           vvParte16 ||
                           vvParte17 ||
                           vvParte18 ||
                           vvParte19 ||
                           vvParte20 ||
                           vvParte21;
        -- Extrai Json
        vvObservacaoCab := F_RETORNA_JSON(vvObservacaoCab);
        -- Insere Json
        P_INSERE_JSON('C',
                      vvObservacaoCab);
      END IF;

      -- Pesquisa Observação do Item
      IF (pi_vTipo IN ('I','A')) THEN

        -- Se passou o NUMSEQ
        IF (NVL(pi_nNumSeq,0) > 0) THEN

          BEGIN
            SELECT DBMS_LOB.SUBSTR(MSGPROCMED, 4000,1)
                 , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,4001)
                 , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,8001)
                 , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,12001)
                 , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,16001)
                 , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,20001)
                 , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,24001)
                 , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,28001)
                 , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,32001)
                 , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,36001)
                 , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,40001)
                 , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,44001)
                 , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,48001)
                 , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,52001)
                 , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,56001)
                 , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,60001)
                 , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,64001)
                 , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,68001)
                 , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,72001)
                 , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,76001)
                 , DBMS_LOB.SUBSTR(MSGPROCMED, 4000,80001)
              INTO vvParte1
                 , vvParte2
                 , vvParte3
                 , vvParte4
                 , vvParte5
                 , vvParte6
                 , vvParte7
                 , vvParte8
                 , vvParte9
                 , vvParte10
                 , vvParte11
                 , vvParte12
                 , vvParte13
                 , vvParte14
                 , vvParte15
                 , vvParte16
                 , vvParte17
                 , vvParte18
                 , vvParte19
                 , vvParte20
                 , vvParte21
              FROM PCPEDIFV
             WHERE (NUMPEDRCA         = pi_nNumPedRca)
               AND (CODUSUR           = pi_nCodUsur)
               AND (CGCCLI            = pi_vCgcCli)
               AND (DTABERTURAPEDPALM = pi_dDtAberturaPedPalm)
               AND (CODPROD           = pi_nCodProd)
               AND (NUMSEQ            = pi_nNumSeq);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vvObservacaoItem := NULL;
          END;
          -- Concatena Json
          vvObservacaoItem := vvParte1  ||
                              vvParte2  ||
                              vvParte3  ||
                              vvParte4  ||
                              vvParte5  ||
                              vvParte6  ||
                              vvParte7  ||
                              vvParte8  ||
                              vvParte9  ||
                              vvParte10 ||
                              vvParte11 ||
                              vvParte12 ||
                              vvParte13 ||
                              vvParte14 ||
                              vvParte15 ||
                              vvParte16 ||
                              vvParte17 ||
                              vvParte18 ||
                              vvParte19 ||
                              vvParte20 ||
                              vvParte21;
          -- Extrai Json
          vvObservacaoItem := F_RETORNA_JSON(vvObservacaoItem);
          -- Insere Json
          P_INSERE_JSON('I',
                        vvObservacaoItem);

        -- Se NÃO passou o NUMSEQ
        ELSE

          FOR vc_Item IN (SELECT DBMS_LOB.SUBSTR(MSGPROCMED, 32000,1) MSGPROCMED
                            FROM PCPEDIFV
                           WHERE (NUMPEDRCA         = pi_nNumPedRca)
                             AND (CODUSUR           = pi_nCodUsur)
                             AND (CGCCLI            = pi_vCgcCli)
                             AND (DTABERTURAPEDPALM = pi_dDtAberturaPedPalm)
                             AND (CODPROD           = pi_nCodProd)) LOOP
            -- Pega Observação
            vvObservacaoItem := vc_Item.MSGPROCMED;
            -- Extrai Json
            vvObservacaoItem := F_RETORNA_JSON(vvObservacaoItem);
            -- Insere Json
            P_INSERE_JSON('I',
                          vvObservacaoItem);
          END LOOP;

        END IF;

      END IF;

    END IF; -- FIM CONDIÇÃO: ORIGEM CHAMADA

  END proc_CARREGARDADOSVALIDACAO;

 /***********************************************************************************************
  FUNCTION : func_foralinhasemest
  DESCRIÇÃO: Validar Fora de Linha sem Estoque
  ***********************************************************************************************/
  FUNCTION func_foralinhasemest(pREJEITARITENSFORALINHASEMEST IN VARCHAR2,
                                pCodFilial                    IN VARCHAR2,
                                pCodFilialRetira              IN VARCHAR2,
                                pCodProd                      IN NUMBER)
  RETURN VARCHAR2 IS
    vvRetForaLinhaSemEst VARCHAR2(1);
    vvForaLinha          PCPRODFILIAL.FORALINHA%TYPE;
    vnQtEstGer           PCEST.QTESTGER%TYPE;
  BEGIN

    vvRetForaLinhaSemEst := 'N';

    IF (pREJEITARITENSFORALINHASEMEST = 'S') THEN

      -- Verifica se Fora de Linha
      BEGIN
        SELECT FORALINHA
          INTO vvForaLinha
          FROM PCPRODFILIAL
         WHERE (CODFILIAL = pCodFilial)
           AND (CODPROD   = pCodProd) ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvForaLinha := 'N';
      END;

      -- Se Fora de Linha
      IF (vvForaLinha = 'S') THEN

        -- Busca Estoque Gerencial
        BEGIN
          SELECT QTESTGER
            INTO vnQtEstGer
            FROM PCEST
           WHERE (CODPROD = pCodProd)
             AND (CODFILIAL = NVL(pCodFilialRetira,pCodFilial));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnQtEstGer := 0;
        END;

        -- Se não tiver Estoque Gerencial
        IF (NVL(vnQtEstGer,0) <= 0) THEN

          vvRetForaLinhaSemEst := 'S'; -->> FORA DE LINHA E SEM ESTOQUE

        END IF;

      END IF;

    END IF;

    RETURN vvRetForaLinhaSemEst;

  END func_foralinhasemest;

 /***********************************************************************************************
  PROCEDURE: proc_validamargemminima
  DESCRIÇÃO: Validar Margem Minima - MED-2079
  ***********************************************************************************************/
  PROCEDURE proc_validamargemminima(pi_vOrigemPed                  IN VARCHAR2,
                                    pi_vTipoFv                     IN VARCHAR2,
                                    pi_vCodFilial                  IN VARCHAR2,
                                    pi_vValidarMargemMinOlPe       IN VARCHAR2,
                                    pi_vPercMargemMinVendaMed      IN VARCHAR2,
                                    pi_vTipoValidMargemMinVendaMed IN VARCHAR2,
                                    pi_nCodPlPag                   IN NUMBER,
                                    pi_nMargemMinPlPag             IN NUMBER,
                                    pi_nPercMargemPedido           IN NUMBER,
                                    pi_vBloqPedAbaixoMargemFv      IN VARCHAR2,
                                    po_vRejeitado                  OUT VARCHAR2,
                                    po_vMotivoRejeitado            OUT VARCHAR2,
                                    po_vObservacao                 OUT VARCHAR2,
                                    po_vJsonRejeitado              OUT VARCHAR2,
                                    po_vGravarComoBloqueado        OUT VARCHAR2,
                                    po_nMargemMinimaAplicada       OUT NUMBER) IS
    -- Variáveis
    vbValidarMargemMinima         BOOLEAN;
    vvBloquearPedido              VARCHAR2(200);
    vbPodeComprar                 BOOLEAN;
    vnPercMargemMinVendaMed       NUMBER;
    vvRegraMargemMinAplicada      VARCHAR2(2);
    vnPercMargemMinAplicada       NUMBER;
    vvDescOrigemMargemMinAplicada VARCHAR2(2000);
    vvOrientacaoCondicaoNaoCad    VARCHAR2(32000);
    vvDescricaoPlanoPagamento     PCPLPAG.DESCRICAO%TYPE;
  BEGIN

    -- Inicializa Retornos
    po_vRejeitado            := 'N';
    po_vMotivoRejeitado      := NULL;
    po_vObservacao           := NULL;
    po_vJsonRejeitado        := NULL;
    po_vGravarComoBloqueado  := 'N';
    po_nMargemMinimaAplicada := NULL;

    -- Converte a Margem Mínima do Parâmetro da Empresa
    BEGIN
      vnPercMargemMinVendaMed := TO_NUMBER(NVL(pi_vPercMargemMinVendaMed,'0'));
    EXCEPTION
      WHEN OTHERS THEN
        vnPercMargemMinVendaMed := 0;
    END;

    -- Dados do Plano de Pagamento
    BEGIN
      SELECT DESCRICAO
        INTO vvDescricaoPlanoPagamento
        FROM PCPLPAG
       WHERE (CODPLPAG = pi_nCodPlPag);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvDescricaoPlanoPagamento := NULL;
    END;

    -- VERIFICA SE VALIDA MARGEM MÍNIMA CONFORME ORIGEM DO PEDIDO --
    ----------------------------------------------------------------

    -- Inicializa Indicando que não valida margem mínima
    vbValidarMargemMinima := FALSE;

    -- Se Pedidos de Operador Logístico e Pedido Eletrônico
    IF (NVL(pi_vTipoFv,'FV') IN ('OL','PE')) THEN

      -- Se na Integradora Valida Margem Mínima
      IF (NVL(pi_vValidarMargemMinOlPe,'N') = 'S') THEN

        vbValidarMargemMinima := TRUE;

      END IF;

    -- Demais Pedidos que não são OL ou PE
    ELSE

      vbValidarMargemMinima := TRUE;

    END IF;


    -- SE VALIDAR MARGEM MINIMA --
    ------------------------------
    IF (vbValidarMargemMinima) THEN

      -- Inicializa variável indicando que pode comprar
      vbPodeComprar            := TRUE;

      -- Se Valida Margem Minima do Plano de Pagamento
      IF (NVL(pi_nMargemMinPlPag,0) > 0) THEN

        -- Valores para composição da Mensagem
        vvRegraMargemMinAplicada := 'PL';
        vnPercMargemMinAplicada  := NVL(pi_nMargemMinPlPag,0);

        -- Se ficou abaixo da Margem Mínima do Plano de Pagamento
        IF (NVL(pi_nPercMargemPedido,0) < NVL(pi_nMargemMinPlPag,0)) THEN

          -- Não pode comprar
          vbPodeComprar                 := FALSE;
          vvDescOrigemMargemMinAplicada := 'do Plano de Pagamento ' || pi_nCodPlPag || ' - ' || vvDescricaoPlanoPagamento || '.';

          -- VERIFICA SE VAI GRAVAR COMO BLOQUEADO
          vvBloquearPedido              := NVL(pi_vBloqPedAbaixoMargemFv,'N');

        END IF;

      END IF; -- Fim: Valida primeiramente a Margem do Plano de Pagamento

      -- Depois valida a Margem dos Parâmetros da Presidência
      IF (vbPodeComprar) THEN

        -- Se Validar Margem Mínima nos Parâmetros da Empresa
        IF (NVL(pi_vTipoValidMargemMinVendaMed,'0') IN ('2','3')) THEN

          -- Valores para composição da Mensagem
          vvRegraMargemMinAplicada := 'PP';
          vnPercMargemMinAplicada  := NVL(vnPercMargemMinVendaMed,0);

          -- Se ficou abaixo da Margem Mínima do Parâmetro da Empresa
          IF (NVL(pi_nPercMargemPedido,0) < NVL(vnPercMargemMinVendaMed,0)) THEN

            -- Não pode comprar
            vbPodeComprar                 := FALSE;
            vvDescOrigemMargemMinAplicada := 'do Parâmetro da Empresa "% Margem Mínima na Venda".';

            -- VERIFICA SE VAI GRAVAR COMO BLOQUEADO
            -- Não permitir gravar o Pedido
            IF (NVL(pi_vTipoValidMargemMinVendaMed,'0') = '3') THEN
              vvBloquearPedido := 'N';
            -- Bloquear o Pedido
            ELSE
              vvBloquearPedido := 'S';
            END IF;

          END IF; -- Valida primeiramente a Margem do Plano de Pagamento

        END IF;

      END IF; -- Fim: Depois valida a Margem dos Parâmetros da Presidência


      -- SE NÃO PODE COMPRAR
      IF (NOT vbPodeComprar) THEN

        po_vRejeitado       := 'S';
        po_vMotivoRejeitado := 'Margem de lucratividade do pedido menor que minima';
        po_vObservacao      := 'O Percentual de Margem do Pedido: ' || FFORMATAR_NUMERO_PARA_TEXTO(nvl(pi_nPercMargemPedido,0),2) || CHR(13) ||
                               'inferior ao Percentual Mínimo: ' || FFORMATAR_NUMERO_PARA_TEXTO(nvl(vnPercMargemMinAplicada,0),2) || ' '     || vvDescOrigemMargemMinAplicada;

        -- Se está deixando gravar como Bloqueado
        IF (NVL(vvBloquearPedido,'N') = 'S') THEN
          po_vGravarComoBloqueado    := 'S'; -->> Gravar o Pedido como Bloqueado
          IF (NVL(pi_vTipoFv,'FV') IN ('OL','PE')) THEN
            vvOrientacaoCondicaoNaoCad := 'Alternativas para gravar o Pedido na posição Liberado (não bloquear o Pedido): ' || CHR(13) ||
                                          '- Alterar o parâmetro "Validar Margem Minima" do cadastro da integradora na rotina 2302 para "Não".'|| CHR(13) ||
                                          '- Verifique a possibilidade de diminuir a margem minima ' || vvDescOrigemMargemMinAplicada;
          ELSE
            vvOrientacaoCondicaoNaoCad := 'Para gravar o Pedido na posição Liberado (não bloquear o Pedido), verifique a possibilidade de diminuir a margem minima ' || vvDescOrigemMargemMinAplicada;
          END IF;
        -- Se está rejeitando
        ELSE
          vvOrientacaoCondicaoNaoCad := 'Alternativas para não rejeitar o Pedido: ';
          IF (NVL(vvRegraMargemMinAplicada,'X') = 'PP') THEN
            vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad || CHR(13) ||
                                          '- Alterar o Parâmetro da Presidência "9894" para gravar o Pedido como Bloqueado.';
          ELSE
            vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad || CHR(13) ||
                                          '- Alterar o Parâmetro da Presidência "2899" para gravar o Pedido como Bloqueado.';
          END IF;
            vvOrientacaoCondicaoNaoCad := vvOrientacaoCondicaoNaoCad || CHR(13) ||
                                          '- Verificar a possibilidade de de diminuir a margem minima ' || vvDescOrigemMargemMinAplicada;
        END IF;

        po_vJsonRejeitado := func_gerarlogjson(po_vMotivoRejeitado,
                                               po_vObservacao,
                                               '1203',
                                               '2899,9894,9897',
                                               NULL,
                                               vvOrientacaoCondicaoNaoCad);

      END IF;

    END IF; -- Fim Condição: Se Valida Margem Mínima

    -- Margem Mínima Aplicada
    po_nMargemMinimaAplicada := vnPercMargemMinAplicada;

  END proc_validamargemminima;

 /***********************************************************************************************
  PROCEDURE: proc_insere_bloqueiospedido
  DESCRIÇÃO: Inserir na Tabela de Bloqueios do Pedido - MED-2161
  ***********************************************************************************************/
  PROCEDURE proc_insere_bloqueiospedido(pi_vAtualizarPCPEDC IN VARCHAR2,
                                        pi_nNumPed          IN NUMBER,
                                        pi_nCodMotivo       IN NUMBER,
                                        pi_nCodMotBloqueio  IN NUMBER,
                                        pi_vMotivoPosicao   IN VARCHAR2) IS
   VVACHOU    VARCHAR2(1);
   VNCODIGO   INTEGER;
   VVTIPO     PCBLOQUEIOSPEDIDO.TIPO%TYPE;
  BEGIN

   IF (NVL(pi_nCodMotivo,0) > 0) THEN

     -- Verifica se já inseriu o motivo do bloqueio do pedido
     BEGIN
       SELECT 'S'
         INTO VVACHOU
         FROM PCBLOQUEIOSPEDIDO
        WHERE (NUMPED    = pi_nNumPed)
          AND (CODMOTIVO = pi_nCodMotivo)
          AND (ROWNUM    = 1);
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
         VVACHOU := 'N';
     END;

     -- Se não inseriu o motivo do bloqueio do pedido
     IF (VVACHOU = 'N') THEN

       -- INICIO: Atualização da PCPEDC
       IF (pi_vAtualizarPCPEDC = 'S') THEN

         BEGIN
           SELECT 'S'
             INTO VVACHOU
             FROM PCLOGBLOQUEIOPEDVENDA
            WHERE (NUMPED = pi_nNumPed)
              AND (DATA   = SYSDATE)
              AND (ROWNUM = 1);
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
             VVACHOU := 'N';
         END;

         IF (VVACHOU = 'N') THEN

           UPDATE PCPEDC
              SET MOTIVOPOSICAO = SUBSTR(pi_vMotivoPosicao,1,60)
                , CODMOTIVO     = pi_nCodMotivo
            WHERE (NUMPED = pi_nNumPed);

         END IF;

       END IF;
       -- FIM: Atualização da PCPEDC

       -- Busca Tipo de Bloqueio
       BEGIN
         SELECT CASE WHEN NVL(TIPO,0) = 1 THEN
                  'F'
                ELSE
                  'C'
                END
           INTO VVTIPO
           FROM PCMOTBLOQUEIO
          WHERE (CODMOTIVO = pi_nCodMotivo);
       EXCEPTION
         WHEN NO_DATA_FOUND THEN
           VVTIPO := 'C';
       END;

       SELECT dfseq_pcbloqueiospedido.NEXTVAL INTO VNCODIGO FROM DUAL;

       -- Insere Motivo de Bloqueio do Pedido
       INSERT INTO PCBLOQUEIOSPEDIDO
                 ( CODIGO
                 , NUMPED
                 , CODMOTIVO
                 , CODMOTBLOQUEIO
                 , MOTIVO
                 , STATUS
                 , TIPO )
          VALUES ( VNCODIGO                       -- CODIGO
                 , pi_nNumPed                     -- NUMPED
                 , pi_nCodMotivo                  -- CODMOTIVO
                 , pi_nCodMotBloqueio             -- CODMOTBLOQUEIO
                 , SUBSTR(pi_vMotivoPosicao,1,60) -- MOTIVO
                 , 'B'                            -- STATUS
                 , VVTIPO );                      -- TIPO

     END IF; -- (NVL(VICONTADOR,0) = 0)

   END IF; -- (NVL(pi_nCodMotivo,0) > 0)

  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END proc_insere_bloqueiospedido;

 /**********************************************************************************************
  PROCEDIMENTO PARA RETORNAR VALORES DO PEPS - ICMS - HIS.03510.2016 - Origem Nacional/Importado - MED-2270
  **********************************************************************************************/
  PROCEDURE OBTER_DADOS_PEPS_ICMS(pi_nCodProd           IN  NUMBER,
                                  pi_vCodFilial         IN  VARCHAR2,
                                  pi_nQtde              IN  NUMBER,
                                  pi_dData              IN  DATE,
                                  po_vProdImportadoPeds OUT VARCHAR2,
                                  po_nNumTransEntPeps   OUT NUMBER,
                                  po_vMsgErros          OUT VARCHAR2) IS

     vnCodMensagem          NUMBER;
     vt_ENTRADASORIGMERC    TIPO_ENTRADASPEPSTAB;

     TYPE TRecDadosPeps     IS RECORD(
          vnMaiorQtde       NUMBER,
          vvImportado       VARCHAR2(1),
          vnNumTransEnt     NUMBER);
     vrDadosPeps            TRecDadosPeps;

   BEGIN

     -- Inicializa Retornos
     po_vProdImportadoPeds := 'N';
     po_nNumTransEntPeps   := NULL;
     po_vMsgErros          := NULL;

     BEGIN
       PKG_FWPC_FISCAL.PEPS_OBTERORIGEMMERC_1_0(pi_nCodProd
                                               ,pi_vCodFilial
                                               ,pi_nQtde
                                               ,pi_dData
                                               ,vt_ENTRADASORIGMERC
                                               ,vnCodMensagem
                                               ,po_vMsgErros);

       IF (vt_ENTRADASORIGMERC.COUNT > 0) THEN
         FOR viIdx IN  vt_ENTRADASORIGMERC.FIRST..vt_ENTRADASORIGMERC.LAST LOOP
           IF (NVL(vt_ENTRADASORIGMERC(viIdx).SALDO,0) > 0) THEN

             -- PEPS com maior Saldo em Qtde.
             IF (NVL(vt_ENTRADASORIGMERC(viIdx).SALDO,0) > NVL(vrDadosPeps.vnMaiorQtde,0)) THEN
               vrDadosPeps.vnMaiorQtde   := NVL(vt_ENTRADASORIGMERC(viIdx).SALDO,0);
               vrDadosPeps.vvImportado   := NVL(vt_ENTRADASORIGMERC(viIdx).IMPORTADO,0);
               vrDadosPeps.vnNumTransEnt := NVL(vt_ENTRADASORIGMERC(viIdx).NUMTRANSENT,0);
             END IF;

           END IF;
         END LOOP;
       END IF;

       -- Atualiza Retorno
       po_vProdImportadoPeds := vrDadosPeps.vvImportado;
       po_nNumTransEntPeps   := vrDadosPeps.vnNumTransEnt;

     EXCEPTION
       WHEN OTHERS THEN
         po_vMsgErros := 'Erros no PEPS ICMS: ' || SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE || ' >> ' || SQLERRM,1,240);
     END;

   END OBTER_DADOS_PEPS_ICMS;

 /************************************************************************
  PROCEDIMENTO PARA CALCULAR CMV - HIS.03510.2016 - Origem Nacional/Importado no CMV - MED-2270
  ************************************************************************/
 PROCEDURE calcularcmv -- 37 parametros
  (p_tributsaidaorigemnacimp     IN VARCHAR2, -- HIS.03510.2016
   p_abaterimpostoscomissaorca   IN VARCHAR2,
   p_aplicarindicecmv            IN VARCHAR2,
   p_incluircomissaosugpvendacmv IN VARCHAR2,
   p_txvenda                     IN NUMBER,
   p_tipofj                      IN VARCHAR2,
   p_utilizaiesimplificada       IN VARCHAR2,
   p_ieent                       IN VARCHAR2,
   p_freteespecial               IN VARCHAR2,
   p_perfreteterceiros           IN NUMBER,
   p_perfreteespecial            IN NUMBER,--10
   p_custofin                    IN NUMBER,
   p_custoreal                   IN NUMBER,
   p_perdesccusto                IN NUMBER,
   p_codicmtab                   IN NUMBER,
   p_codicmtabpf_enulo           IN BOOLEAN,
   p_codicmtabpf                 IN NUMBER,
   p_percvenda                   IN NUMBER,
   p_pvenda                      IN NUMBER,
   p_percom                      IN NUMBER,
   p_st                          IN NUMBER,--20
   p_vlipi                       IN NUMBER,
   p_vliss                       IN NUMBER,
   p_contribuinte                IN VARCHAR2,
   p_vldifaliquotas              in number,
   p_perredcmvsimplesnac         in number,
   p_consumidorfinal             IN varchar2 default 'N',
   p_consideraisentoscomopf      IN varchar2 default 'N',
   p_perfretecmv                 OUT NUMBER,
   p_custofinest                 OUT NUMBER,
   p_txvenda_item                OUT NUMBER,--30
   p_perdesccusto_item           OUT NUMBER,
   p_codicmtab_item              OUT NUMBER,
   p_vlcustoreal                 OUT NUMBER,
   p_vlcustofin                  OUT NUMBER,
   p_vldesccustocmv              OUT NUMBER,
   P_CODCLI                      IN NUMBER DEFAULT 0,
   p_custoprecific               IN NUMBER DEFAULT 0,
   p_codprod                     IN NUMBER,    -- HIS.03510.2016
   p_codfilial                   IN VARCHAR2,  -- HIS.03510.2016
   p_qtde                        IN NUMBER,    -- HIS.03510.2016
   p_codicmtabinternac           IN NUMBER,    -- HIS.03510.2016
   p_prodimportadopeds           OUT VARCHAR2, -- HIS.03510.2016
   p_numtransentpeps             OUT NUMBER,   -- HIS.03510.2016
   p_mensagemerro                OUT VARCHAR2  -- HIS.03510.2016
   ) IS
   vnbasecalccomissao NUMBER := 0;
  BEGIN
    -- HIS.03510.2016
    p_prodimportadopeds := NULL;
    p_numtransentpeps   := NULL;

    --Dados para cálculo do CMV
    p_perfretecmv := p_perfreteterceiros;
    IF p_freteespecial = 'S' THEN
      p_perfretecmv := p_perfreteespecial;
    END IF;

    p_custofinest       := p_custofin;

    /*4346.127564.2014 - Rafael Braga*/
    if p_custoprecific > 0 and FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('PRECIFICREGIAOFORAUFSEMST', 99, 'N') = 'S' then
      p_custofinest := p_custoprecific;
    end if;

    p_txvenda_item      := nvl(p_txvenda, 0);
    p_perdesccusto_item := nvl(p_perdesccusto, 0);
    p_codicmtab_item    := nvl(p_codicmtab, 0);

    /* Alterado abaixo por Rodrigo Santos
    IF  -- 1º caso
    (((p_TIPOFJ = 'F') and (p_UTILIZAIESIMPLIFICADA = 'N')) or
      -- 2º caso
      (p_CONSUMIDORFINAL = 'S') or
      -- 3º caso
      ((p_CONSIDERAISENTOSCOMOPF = 'S') and
      ((Trim(p_IEENT) = '') or (p_IEENT = 'ISENTO') or
      (p_IEENT = 'ISENTA'))))
      -- somente quando
    and (p_contribuinte = 'N') and (p_codicmtabpf IS NOT NULL) then

      p_codicmtab_item := nvl(p_codicmtabpf, 0);
    END IF;*/
    IF FERRAMENTAS.VERIFICAR_FJ(P_CODCLI) = 'PESSOA FISICA' THEN
      p_codicmtab_item := nvl(p_codicmtabpf, 0);
    END IF;

    -- Se Utiliza PEPS para Nacional e Importado - ICMS
    IF (p_tributsaidaorigemnacimp = 'S') THEN
      OBTER_DADOS_PEPS_ICMS(p_codprod,
                            p_codfilial,
                            p_qtde,
                            TRUNC(SYSDATE), -->> Para a Integradora a Data pode ser a Atual
                            p_prodimportadopeds,
                            p_numtransentpeps,
                            p_mensagemerro);
      IF (p_prodimportadopeds = 'S') THEN
        p_codicmtab_item := nvl(p_codicmtabinternac, 0);
      END IF;
    END IF;

    --Tarefa 25188
    vnbasecalccomissao := p_pvenda;
    IF p_abaterimpostoscomissaorca = 'S' THEN
      vnbasecalccomissao := p_pvenda - nvl(p_st, 0) - nvl(p_vlipi, 0) -
                            nvl(p_vliss, 0) - nvl(p_vldifaliquotas, 0);
    END IF;
    --tarefas 43617 e 44750
    IF p_aplicarindicecmv = 'S' THEN
      p_vlcustoreal := ((p_custoreal - ((nvl(p_perredcmvsimplesnac, 0) * p_custoreal) / 100)) -
                       ((p_custoreal /*- nvl(p_perredcmvsimplesnac, 0)*/) *
                       nvl(p_perdesccusto_item, 0) / 100) +
                       (p_pvenda * p_txvenda_item / 100) +
                       (vnbasecalccomissao * nvl(p_percom, 0) / 100) +
                       (p_pvenda * nvl(p_perfretecmv, 0) / 100) +
                       ((p_pvenda - nvl(p_st, 0) - nvl(p_vlipi, 0) -
                       nvl(p_vliss, 0) - nvl(p_vldifaliquotas, 0)) *
                       (nvl(p_percvenda, 100) / 100) --Tarefa 43617
                       * (p_codicmtab_item / 100)) + nvl(p_st, 0) +
                       nvl(p_vlipi, 0) + nvl(p_vliss, 0) +
                       nvl(p_vldifaliquotas, 0));
      p_vlcustofin  := ((p_custofinest - ((nvl(p_perredcmvsimplesnac, 0) * p_custofinest) / 100)) -
                       ((p_custofinest /*- nvl(p_perredcmvsimplesnac, 0)*/) *
                       nvl(p_perdesccusto_item, 0) / 100) +
                       (p_pvenda * p_txvenda_item / 100) +
                       (vnbasecalccomissao * nvl(p_percom, 0) / 100) +
                       (p_pvenda * nvl(p_perfretecmv, 0) / 100) +
                       ((p_pvenda - nvl(p_st, 0) - nvl(p_vlipi, 0) -
                       nvl(p_vliss, 0) - nvl(p_vldifaliquotas, 0)) *
                       (nvl(p_percvenda, 100) / 100) --Tarefa 43617
                       * (p_codicmtab_item / 100)) + nvl(p_st, 0) +
                       nvl(p_vlipi, 0) + nvl(p_vliss, 0) +
                       nvl(p_vldifaliquotas, 0));
    ELSE
      p_vlcustoreal := ((p_custoreal - ((nvl(p_perredcmvsimplesnac, 0) * p_custoreal) / 100)) -
                       ((p_custoreal /*- nvl(p_perredcmvsimplesnac, 0)*/) *
                       nvl(p_perdesccusto_item, 0) / 100) +
                       (p_pvenda * p_txvenda_item / 100) +
                       (vnbasecalccomissao * nvl(p_percom, 0) / 100) +
                       (p_pvenda * nvl(p_perfretecmv, 0) / 100) +
                       ((p_pvenda - nvl(p_st, 0) - nvl(p_vlipi, 0) -
                       nvl(p_vliss, 0) - nvl(p_vldifaliquotas, 0)) *
                       (p_codicmtab_item / 100)) + p_st + nvl(p_vlipi, 0) +
                       nvl(p_vliss, 0) + nvl(p_vldifaliquotas, 0));

      p_vlcustofin  := ((p_custofinest - ((nvl(p_perredcmvsimplesnac, 0) * p_custofinest) / 100)) -
                       ((p_custofinest /*- nvl(p_perredcmvsimplesnac, 0)*/) *
                       nvl(p_perdesccusto_item, 0) / 100) +
                       (p_pvenda * p_txvenda_item / 100) +
                       (vnbasecalccomissao * nvl(p_percom, 0) / 100) +
                       (p_pvenda * nvl(p_perfretecmv, 0) / 100) +
                       ((p_pvenda - nvl(p_st, 0) - nvl(p_vlipi, 0) -
                       nvl(p_vliss, 0) - nvl(p_vldifaliquotas, 0)) *
                       (p_codicmtab_item / 100)) + p_st + nvl(p_vlipi, 0) +
                       nvl(p_vliss, 0) + nvl(p_vldifaliquotas, 0));

/*((pdCUSTOFINEST) - ((pdCUSTOFINEST) * pdPERDESCCUSTO_ITEM / 100) +
       (pdPVENDA * pdTXVENDA_ITEM / 100) + (vnBASECALCCOMISSAO * pdPERCOM / 100) +
       (pdPVENDA * pdPERFRETECMV / 100) +
       ((pdPVENDA - pdST - pdVLIPI - pdVLISS - pdVLDifAliquotas) * (pdCODICMTAB_ITEM / 100))
       + pdST + pdVLIPI + pdVLISS + pdVLDifAliquotas);    */


    END IF;
    -- tarefa 56190
    IF nvl(p_incluircomissaosugpvendacmv, 'S') = 'N' THEN
      p_vlcustoreal := p_vlcustoreal -
                       (vnbasecalccomissao * nvl(p_percom, 0) / 100);
      p_vlcustofin  := p_vlcustofin -
                       (vnbasecalccomissao * nvl(p_percom, 0) / 100);
    END IF;
    -- Valor do Desconto no Custo Financeiro
    p_vldesccustocmv := (round(((nvl(p_custofinest, 0) *
                               nvl(p_perdesccusto_item, 0) / 100) * 100))) / 100;
  END calcularcmv;

 /**********************************************************************************************
  PROCEDIMENTO PARA RETORNAR O DESCONTO DA PROMOÇÃO - 4493.055952.2019
  **********************************************************************************************/
  PROCEDURE P_OBTEM_DESC_PROMOCAO(pi_nTipoChamada      IN  NUMBER,
                                  pi_vGravaTabTemp        IN  VARCHAR2,
                                  pi_vExecutaCommit       IN  VARCHAR2,
                                  pi_dData                IN  DATE,
                                  pi_vCodFilial           IN  VARCHAR2,
                                  pi_vTipoPrazoMedicam    IN  VARCHAR2,
                                  pi_nNumRegiao           IN  NUMBER,
                                  pi_nCodUsur             IN  NUMBER,
                                  pi_vOrigemPed           IN  VARCHAR2,
                                  pi_vTipoFv              IN  VARCHAR2,
                                  pi_nCodPlPag            IN  NUMBER,
                                  pi_nCodCondicaoVenda    IN  NUMBER,
                                  pi_nCodPromocaoMed      IN  NUMBER,
                                  pi_nCodCli              IN  NUMBER,
                                  pi_nCodProd             IN  NUMBER,
                                  pi_nQtde                IN  NUMBER,
                                  po_vTipoPromoPrecoDesc  OUT VARCHAR2,
                                  po_nCodDesconto         OUT NUMBER,
                                  po_nCodPromocaoMed      OUT NUMBER,
                                  po_nPrecoFixo           OUT NUMBER,
                                  po_nPercDesc            OUT NUMBER,
                                  po_nPercDescFin         OUT NUMBER,
                                  po_nInicioIntervaloQt   OUT NUMBER,
                                  po_nVlDescCmv           OUT NUMBER,   -- DDMEDICA-5009
                                  po_nPerDescCmv          OUT NUMBER,   -- DDMEDICA-5009
                                  po_nNumVerba            OUT NUMBER,   -- DDMEDICA-5009
                                  po_nValorCotaNumVerba   OUT NUMBER,   -- DDMEDICA-5009
                                  po_vSemVerbaVlDescCmv   OUT VARCHAR2, -- DDMEDICA-5009
                                  po_vOcorreramErros      OUT VARCHAR2,
                                  po_vMsgErros            OUT VARCHAR2,
                                  pi_nNumPedRca            IN NUMBER,
                                  pi_vRestringirPromocaoFv IN VARCHAR2,
                                  pi_TipoPromocaoPrecoDesc IN VARCHAR2,
                                  pi_nPTabela              IN NUMBER,
                                  pi_nCustoFin             IN NUMBER,
                                  po_nPercMarkupMed       OUT NUMBER,
                                  pi_nIntegradora          IN NUMBER DEFAULT NULL,
                                  pi_vConcedenteOferta     IN VARCHAR2 DEFAULT NULL)
  /*******************************************************************************
   Nome         : P_OBTEM_DESC_PROMOCAO
   Descricão    : Procedimento para Obter o Desconto da Promoção
   Parâmetros   : ENTRADA:
                  pi_nTipoChamada        = 1 - INTEGRADORA_MED
                  pi_vGravaTabTemp       = Se Grava na Tabela Temporária (S/N)
                  pi_vExecutaCommit      = Se executa Commit (S/N)
                  pi_dData               = Data Base a ser considerada nas Consultas
                  pi_vCodFilial          = Código da Filial
                  pi_vTipoPrazoMedicam   = Parâmetro da 132
                  pi_nNumRegiao          = Região do Cliente
                  pi_nCodUsur            = Código Vendedor
                  pi_vOrigemPed          = Origem do Pedido
                  pi_vTipoFv             = Tipo de Pedido Força de Vendas [FV;OL;PE]
                  pi_nCodPlPag           = Código do Plano de Pagamento
                  pi_nCodPromocaoMed     = Código da Promoção do Cabeçalho do Pedido
                  pi_nCodCondicaoVenda   = Código da Condição de Venda
                  pi_nCodCli             = Código do Cliente
                  pi_nCodProd            = Código do Produto
                  pi_nQtde               = Quantidade Base
                  pi_nNumPedRca          = Número do Pedido do RCA para testes
                  SAIDA:
                  po_vTipoPromoPrecoDesc = Tipo de Promoção P-Preço ou D-Desconto
                  po_nCodDesconto        = Código do Desconto
                  po_nCodPromocaoMed     = Código da Promoção
                  po_nPrecoFixo          = Preço Fixo
                  po_nPercDesc           = Percentual de Desconto
                  po_nPercDescFin        = Percentual de Desconto Financeiro
                  po_nInicioIntervaloQt  = Inicio do Intervalo do Desconto por Quantidade
                  po_nVlDescCmv          = Valor de Verba para Rebaixa do CMV da Promoção
                  po_nPerDescCmv         = % Desconto Financiado por Verba para Rebaixa do CMV da Promoção (Não implementado)                  
                  po_nNumVerba           = Número da Verba
                  po_vOcorreramErros     = Se Ocorreram Erros [S-Sim;N-Não]
                  po_vMsgErros           = Mensagem de Erro
   Alteração    : Anderson Silva - 17/09/2014 - Criação do Procedimento
   Alteração    : Anderson Silva - 19/01/2015 - Pesquisar Preço do Menor para o Maior
   Alteração    : Anderson Silva - 01/09/2015 - Pesquisa RCA
   Alteração    : Anderson Silva - 15/09/2015 - Tratamento para TIPOFV = NULL
                                                e ORIGEMPED = 'F'
   Alteração    : Anderson Silva - 29/09/2015 - Priorizar o maior desconto entre a
                                                Promoção de Desconto e a Promoção de Desconto por Quantidade
   Alteração    : Anderson Silva - 30/09/2015 - Priorizar o menor preço entre a
                                                Promoção de Preço e a Promoção de Preço por Quantidade
                                              - Prioridade do Produto dentro da própria promoção
   Alteração    : Anderson Silva - 13/11/2015 - Validar Campo Bloqueado da Promoção
   Alteração    : Anderson Silva - 15/12/2015 - 4493.138094.2015 - Iniciar com desconto -99.99 na pesquisa do maior,
                                                por causa da promoções zeradas precisar da comissão delas (FV)
   Alteração    : Anderson Silva - 03/02/2016 - Priorização da Promoção do Item do Pedido
   Alteração    : Anderson Silva - 04/08/2016 - Restringir Promoção do Item
   Alteração    : Anderson Silva - 30/08/2016 - Normalização PCDESCONTO
   Alteração    : Anderson Silva = 12/09/2017 - HIS.01889.2017 - Grupos na PCDESCONTO
   Alteração    : Anderson Silva = 21/12/2017 - Regra Específica a Dias a Mais na Vigência - FV
   Alteração    : Anderson Silva - 04/04/2018 - MED-994 - Filtro Pedidos ECommerce
   Alteração    : Anderson Silva - 19/05/2019 - 4493.055952.2019 - Markup
  ********************************************************************************/
  IS

    -- Parametro da Empresa Tipo de Prazo de Medicamentos
    vvTipoPrazoMedicam          PCPARAMFILIAL.VALOR%TYPE;
    vvAcrescimoPlPagPrecoFixoMed PCPARAMFILIAL.VALOR%TYPE;
    -- Dados da Filial
    vvCodFilial                 PCFILIAL.CODIGO%TYPE;
    -- Informações da Condição de Venda
    vvTipoIncidencia            PCCONDVENDALINHA.TIPOINCIDENCIADESCOM%TYPE;
    -- Região
    vnNumRegiao                 PCPRACA.NUMREGIAO%TYPE;
    -- Dados do Cliente
    vnCodCli                    PCCLIENT.CODCLI%TYPE;
    vnCodPraca                  PCCLIENT.CODPRACA%TYPE;
    vvClasseVenda               PCCLIENT.CLASSEVENDA%TYPE;
    vnCodAtv1                   PCCLIENT.CODATV1%TYPE;
    vnCodRede                   PCCLIENT.CODREDE%TYPE;
    vvSimplesNacional           PCCLIENT.SIMPLESNACIONAL%TYPE;
    vvUsaDescFinSeparadoDescCom PCCLIENT.USADESCFINSEPARADODESCCOM%TYPE;
    -- Dados do RCA
    vnCodSupervisor             PCUSUARI.CODSUPERVISOR%TYPE;
    vvAreaAtuacao               PCUSUARI.AREAATUACAO%TYPE;
    -- Dados do Produto
    vnCodepto                   PCPRODUT.CODEPTO%TYPE;
    vnCodSec                    PCPRODUT.CODSEC%TYPE;
    vnCodCategoria              PCPRODUT.CODCATEGORIA%TYPE;
    vnCodFornec                 PCPRODUT.CODFORNEC%TYPE;
    vnCodMarca                  PCPRODUT.CODMARCA%TYPE;
    vnCodLinhaProd              PCPRODUT.CODLINHAPROD%TYPE;
    vnCodProdPrinc              PCPRODUT.CODPRODPRINC%TYPE;
    vnCodLinhaPrazo             PCPRODUT.CODLINHAPRAZO%TYPE;
    vvGrupoFaturamento          PCPRODUT.GRUPOFATURAMENTO%TYPE;
    -- Dados do Plano de Pagamento
    vnCodPlPag                  PCPLPAG.CODPLPAG%TYPE;
    vnNumDias                   PCPLPAG.NUMDIAS%TYPE;
    vnPerTxFim                  PCPLPAG.PERTXFIM%TYPE;
    -- Dados do Pedido para Teste
    vvOrigemPed                 PCPEDCFV.ORIGEMPED%TYPE;
    vvTipoFv                    PCPEDCFV.TIPOFV%TYPE;
    vnCodCondicaoVenda          PCPEDRETORNO.CODCONDICAOVENDA%TYPE;
    -- Variáveis Auxiliares
    vvTipoPromoPrecoOuDesconto  VARCHAR2(1);
    vnCodDesconto               PCDESCONTO.CODDESCONTO%TYPE;
    vnCodPromocaoMed            PCDESCONTO.CODPROMOCAOMED%TYPE;
    vnPrecoFixo                 PCDESCONTO.PRECOFIXOPROMOCAOMED%TYPE;
    vnPercDesc                  PCDESCONTO.PERCDESC%TYPE;
    vnPercDescFin               PCDESCONTO.PERCDESCFIN%TYPE;
    vnInicioIntervaloQt         PCDESCONTO.INICIOINTERVALOPROMOCAOMED%TYPE;
    vbEncontrouPromocaoPreco    BOOLEAN;
    vvAplicaDesconto            VARCHAR2(1);
    vnMenorPrecoEncontrado      PCDESCONTO.PRECOFIXOPROMOCAOMED%TYPE;
    vnPercMarkupMed             PCDESCONTO.PERCMARKUPMED%TYPE; -- DDMEDICA-6837

    -- Array para Guardar a Prioridade das Promoções Gravadas
    TYPE TTPrioridadePromocao   IS TABLE OF NUMBER(2) INDEX BY BINARY_INTEGER;
    vtPrioridadePromocao        TTPrioridadePromocao;

    vbAchouPromocaoItemPedido   BOOLEAN;

    -- 5685.084449.2016 - Restringir Promoção do Item
    vbPodePesquisarPrecoFixo    BOOLEAN;
    vbPodePesquisarDesconto     BOOLEAN;

    -- Regra Específica - Dias a Mais na Vigência
    nDIASMAISPROMOCAOVENCIDAFV  NUMBER;
    vDIASMAISPROMOCAOVENCIDAFV  VARCHAR2(250);

    -- 4493.055952.2019 - Markup
    vbPodePesquisarMarkup       BOOLEAN;
    vnPrecoVendaMarkup          NUMBER;

    -- Verba para Rebaixa de CMV da Promoção - DDMEDICA-5009
    vnVlDescCmvPromocaoMed      NUMBER; 
    vnPerDescCmvPromocaoMed     NUMBER; 
    vnNumVerba                  NUMBER;
    vnValorCotaNumVerba         NUMBER;
    vvSemVerbaVlDescCmv         VARCHAR2(1);
    
    -- Tipo de Promoção - DDMEDICA-6841
    vvTipoPromocao              PCPROMOCAOMED.TIPOPROMOCAO%TYPE;
    -- Controle de Faixa de Quantidade da Promoção de Markup - DDMEDICA-6841
    vbAceitaFaixaMarkup         BOOLEAN;
    -- Percentual de Desconto e Preço Fixo do Markup - DDMEDICA-6841
    vnPercDescMarkup            NUMBER;
    vnPrecoFixoMarkup           NUMBER;

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

   /**********************************************************
    PROCEDURE: FACEITA_PROMOCAO_PRIORIDADE
    DESCRICAO: Definir a Prioridade dentro da própria promoção
    **********************************************************/
    FUNCTION FACEITA_PROMOCAO_PRIORIDADE(pi_nCodPromocao IN NUMBER,
                                         pi_nPrioridade  IN NUMBER,
                                         --
                                         pi_vCodFilial           IN VARCHAR2,
                                         pi_nCodCli              IN NUMBER,
                                         pi_nNumRegiao           IN NUMBER,
                                         pi_nCodUsur             IN NUMBER,
                                         pi_nCodPlPag            IN NUMBER,
                                         pi_nCodCondicaoVenda    IN NUMBER,
                                         pi_vOrigemPed           IN VARCHAR2,
                                         pi_vTipoFv              IN VARCHAR2,
                                         pi_dDataPedido          IN DATE )
    RETURN BOOLEAN IS
      vbRetAceita BOOLEAN;
    BEGIN

      -- Inicializa como Aceitar ou se Usar Normalização da PCDESCONTO o resultado da validação
      vbRetAceita := (PKG_FUNCOESVENDAS_MED.F_PODECOMPRARPROMOCAO(pi_nCodPromocao,
                                                                  pi_vCodFilial,
                                                                  pi_nCodCli,
                                                                  pi_nNumRegiao,
                                                                  pi_nCodUsur,
                                                                  pi_nCodPlPag,
                                                                  pi_nCodCondicaoVenda,
                                                                  pi_vOrigemPed,
                                                                  pi_vTipoFv,
                                                                  pi_dDataPedido) = 'S');

      -- Se Aceita a Promoção
      IF (vbRetAceita) THEN

        -- Se a Promoção ainda não existir para o Produto aceita sem restrições
        IF (NOT vtPrioridadePromocao.EXISTS(pi_nCodPromocao)) THEN
          vtPrioridadePromocao(pi_nCodPromocao) := pi_nPrioridade;
          vbRetAceita := TRUE;
        -- Se a Promoção já existe
        ELSE
          -- Somente aceita Promoção com maior prioridade
          -- (Se a prioridade atual é 3, somente aceitará promoção com prioridades 1 e 2)
          IF (pi_nPrioridade <= vtPrioridadePromocao(pi_nCodPromocao)) THEN
            vtPrioridadePromocao(pi_nCodPromocao) := pi_nPrioridade;
            vbRetAceita := TRUE;
          ELSE
            vbRetAceita := FALSE;
          END IF;
        END IF;

      END IF;

      -- Retorno
      RETURN vbRetAceita;

    END FACEITA_PROMOCAO_PRIORIDADE;

   /**********************************************************
    PROCEDURE: P_INSERE_TABTEMP
    DESCRICAO: Gravar na Tabela Temporária Promoção encontrada
    **********************************************************/
    PROCEDURE P_INSERE_TABTEMP(pi_nCodPromocaoMedDesconto IN NUMBER,
                               pi_nCodDesconto            IN NUMBER,
                               pi_vTipoPolitica           IN VARCHAR2,
                               pi_nInicioIntervalo        IN NUMBER,
                               pi_nFimIntervalo           IN NUMBER,
                               pi_nPrecoFixo              IN NUMBER,
                               pi_nPercDesc               IN NUMBER,
                               pi_nPercDescFin            IN NUMBER,
                               pi_vAplicaDesconto         IN VARCHAR2,
                               pi_vPrioritaria            IN VARCHAR2,
                               pi_nVlDescCmv              IN NUMBER,
                               pi_nCodFornec              IN NUMBER
                               ) IS
      -- Verba para Rebaixa de CMV da Promoção - DDMEDICA-5009
      vnnVlDescCmvAux        NUMBER;
      vnNumVerbaAux          NUMBER;
      vnValorCotaNumVerbaAux NUMBER;
      vvSemVerbaVlDescCmvAux VARCHAR2(1);
    BEGIN

      -- Se for para inserir na Tabela Temporária
      IF (pi_vGravaTabTemp = 'S') THEN

        -- Verba para Rebaixa de CMV da Promoção - DDMEDICA-5009
        vnnVlDescCmvAux := NVL(pi_nVlDescCmv,0);
        -- Obter Verba Relacionada com o Valor da Verba para Rebaixa de CMV da Promoção da PCDESCONTO - DDMEDICA-5009
        PKG_PROMOCAO_MED.P_OBTER_VERBA_PROMOCAO(pi_nCodPromocaoMedDesconto,
                                                pi_nCodFornec,
                                                vnnVlDescCmvAux,
                                                vnNumVerbaAux,
                                                vnValorCotaNumVerbaAux,
                                                vvSemVerbaVlDescCmvAux);
                               
        -- Insere
        BEGIN
          INSERT INTO PCMED_SELPROMOCAO
                    ( CODPROMOCAOMED
                    , CODDESCONTO
                    , TIPOPOLITICA
                    , INICIOINTERVALO
                    , FIMINTERVALO
                    , PRECOFIXO
                    , PERCDESC
                    , PERCDESCFIN
                    , APLICADESCONTO
                    , PRIORITARIA
                    , VLDESCCMVPROMOCAOMED -- DDMEDICA-5009
                    , NUMVERBA             -- DDMEDICA-5009
                    , VALORCOTANUMVERBA    -- DDMEDICA-5009
                    , SEMVERBAVLDESCCMV    -- DDMEDICA-5009
                    )
             VALUES ( pi_nCodPromocaoMedDesconto
                    , pi_nCodDesconto
                    , pi_vTipoPolitica
                    , pi_nInicioIntervalo
                    , pi_nFimIntervalo
                    , pi_nPrecoFixo
                    , pi_nPercDesc
                    , pi_nPercDescFin
                    , pi_vAplicaDesconto
                    , pi_vPrioritaria
                    , vnnVlDescCmvAux        -- DDMEDICA-5009
                    , vnNumVerbaAux          -- DDMEDICA-5009
                    , vnValorCotaNumVerbaAux -- DDMEDICA-5009
                    , vvSemVerbaVlDescCmvAux -- DDMEDICA-5009
                    );
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
            NULL;
        END;

      END IF; -- Fim Condição Se for para inserir na Tabela Temporária

    END P_INSERE_TABTEMP;

  /*******************************************************************************
                     INICIO DO PROCESSAMENTO PRINCIPAL
   *******************************************************************************/
  BEGIN

    -- Se for para Inserir na Tabela Temporária
    IF (pi_vGravaTabTemp = 'S') THEN
      -- Limpa Tabela Temporária
      -- DDMEDICA-5201 Alterado por ser mais eficiente que um delete na tabela inteira
      -- DELETE FROM PCMED_SELPROMOCAO;
      EXECUTE IMMEDIATE ' TRUNCATE TABLE PCMED_SELPROMOCAO ';
    
      -- Efetiva Transações
      IF (pi_vExecutaCommit = 'S') THEN
        COMMIT;
      END IF;
    END IF;

    -- Se Chamado para teste
    IF (NVL(pi_nNumPedRca,0) > 0) THEN
      -- Pega valores nos Pedidos passados nos últimos 30 dias
      BEGIN
        SELECT CODCLI
             , CODPLPAG
             , CODFILIAL
             , TIPOFV
             , ORIGEMPED
          INTO vnCodCli
             , vnCodPlPag
             , vvCodFilial
             , vvTipoFv
             , vvOrigemPed
          FROM PCPEDCFV
         WHERE (NUMPEDRCA = pi_nNumPedRca)
           AND (DTABERTURAPEDPALM >= (TRUNC(SYSDATE)-30));
        -- PCPEDRETORNO
        BEGIN
          SELECT CODCONDICAOVENDA
            INTO vnCodCondicaoVenda
            FROM PCPEDRETORNO
           WHERE (NUMPEDRCA = pi_nNumPedRca)
             AND (DTABERTURAPEDPALM >= (TRUNC(SYSDATE)-30));
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- Utiliza Valores passados nos Parâmetros
            vnCodCondicaoVenda := pi_nCodCondicaoVenda;
        END;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- Utiliza Valores passados nos Parâmetros
          vnCodCli           := pi_nCodCli;
          vnCodPlPag         := pi_nCodPlPag;
          vvCodFilial        := pi_vCodFilial;
          vvTipoFv           := pi_vTipoFv;
          vvOrigemPed        := pi_vOrigemPed;
          vnCodCondicaoVenda := pi_nCodCondicaoVenda;
      END;
    ELSE
      -- Utiliza Valores passados nos Parâmetros
      vnCodCli           := pi_nCodCli;
      vnCodPlPag         := pi_nCodPlPag;
      vvCodFilial        := pi_vCodFilial;
      vvTipoFv           := pi_vTipoFv;
      vvOrigemPed        := pi_vOrigemPed;
      vnCodCondicaoVenda := pi_nCodCondicaoVenda;
    END IF;

    -- Obtem Dados do Cliente
    BEGIN
      SELECT PCCLIENT.CODPRACA
           , PCCLIENT.CLASSEVENDA
           , PCCLIENT.CODATV1
           , PCCLIENT.CODREDE
           , PCCLIENT.SIMPLESNACIONAL
           , PCCLIENT.USADESCFINSEPARADODESCCOM
        INTO vnCodPraca
           , vvClasseVenda
           , vnCodAtv1
           , vnCodRede
           , vvSimplesNacional
           , vvUsaDescFinSeparadoDescCom
        FROM PCCLIENT
       WHERE (PCCLIENT.CODCLI = vnCodCli);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnCodPraca                  := NULL;
        vvClasseVenda               := NULL;
        vnCodAtv1                   := NULL;
        vnCodRede                   := NULL;
        vvSimplesNacional           := NULL;
        vvUsaDescFinSeparadoDescCom := NULL;
    END;

    -- Se passou a Regiao no Parâmetro
    IF (NVL(pi_nNumRegiao,0) > 0) THEN
      -- Utiliza a Região passada no Parâmetro
      vnNumRegiao := pi_nNumRegiao;
    -- Se não passou a Regiao do Cliente no Parâmetro
    ELSE
      -- Pesquisa a Região para a UF
      BEGIN
        SELECT PCTABPRCLI.NUMREGIAO
          INTO vnNumRegiao
          FROM PCTABPRCLI
         WHERE (PCTABPRCLI.CODCLI      = vnCodCli)
           AND (PCTABPRCLI.CODFILIALNF = vvCodFilial);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnNumRegiao := NULL;
      END;
      -- Se não achou Região na PCTABPRCLI
      IF (vnNumRegiao IS NULL) THEN
        -- Obtem a Regiao do Cliente na Praça
        BEGIN
          SELECT PCPRACA.NUMREGIAO
            INTO vnNumRegiao
            FROM PCPRACA
           WHERE (PCPRACA.CODPRACA = vnCodPraca);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnNumRegiao := NULL;
        END;
      END IF;
    END IF;

    -- Obtém Dados do RCA
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

    -- Pesquisa Dados do Produto
    BEGIN
      SELECT PCPRODUT.CODEPTO
           , PCPRODUT.CODSEC
           , PCPRODUT.CODCATEGORIA
           , PCPRODUT.CODFORNEC
           , PCPRODUT.CODMARCA
           , PCPRODUT.CODLINHAPROD
           , PCPRODUT.CODPRODPRINC
           , PCPRODUT.CODLINHAPRAZO
           , PCPRODUT.GRUPOFATURAMENTO
        INTO vnCodepto
           , vnCodSec
           , vnCodCategoria
           , vnCodFornec
           , vnCodMarca
           , vnCodLinhaProd
           , vnCodProdPrinc
           , vnCodLinhaPrazo
           , vvGrupoFaturamento
        FROM PCPRODUT
       WHERE (PCPRODUT.CODPROD = pi_nCodProd);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnCodepto          := NULL;
        vnCodSec           := NULL;
        vnCodCategoria     := NULL;
        vnCodFornec        := NULL;
        vnCodMarca         := NULL;
        vnCodLinhaProd     := NULL;
        vnCodProdPrinc     := NULL;
        vnCodLinhaPrazo    := NULL;
        vvGrupoFaturamento := NULL;
    END;

    -- Verifica Parâmetros da Condição de Venda se OL ou Pedido Eletrônico
    IF (NVL(vvTipoFv,' ') IN ('OL','PE')) AND
       (NVL(vnCodCondicaoVenda,0) > 0) THEN

      -- Se passou o Tipo de Prazo de Medicamentos
      IF (pi_vTipoPrazoMedicam IS NOT NULL) THEN
        -- Pega Valor do Parâmetro
        vvTipoPrazoMedicam := pi_vTipoPrazoMedicam;
      -- Se NÃO passou o Tipo de Prazo de Medicamentos
      ELSE
        -- Pesquisa Parâmetro Tipo de Prazo de Medicamentos
        BEGIN
          SELECT PCPARAMFILIAL.VALOR
            INTO vvTipoPrazoMedicam
            FROM PCPARAMFILIAL
           WHERE (PCPARAMFILIAL.NOME      = 'TIPOPRAZOMEDICAMEN')
             AND (PCPARAMFILIAL.CODFILIAL = 99);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvTipoPrazoMedicam := NULL;
        END;
      END IF;

      -- Redefine a Linha de Prazo do Produto para atender
      -- os Clientes que trabalham com Grupo de Faturamento
      IF (NVL(vvTipoPrazoMedicam,' ') = '1') THEN
        -- Define a Linha de Prazo conforme o Grupo de Produto
        IF    (NVL(vvGrupoFaturamento,' ') = 'E') THEN
          -- Grupo de Faturamento Etico = Linha 1
          vnCodLinhaPrazo := 1;
        ELSIF (NVL(vvGrupoFaturamento,' ') = 'G') THEN
          -- Grupo de Faturamento Generico = Linha 2
          vnCodLinhaPrazo := 2;
        ELSE
          vnCodLinhaPrazo := NULL;
        END IF;
      END IF;

      -- Verifica se considera o Desconto da Promoção na Condição de Venda
      BEGIN
        SELECT PCCONDVENDALINHA.TIPOINCIDENCIADESCOM
          INTO vvTipoIncidencia
          FROM PCCONDVENDALINHA
         WHERE (PCCONDVENDALINHA.codcondicaovenda = vnCodCondicaoVenda)
           AND (PCCONDVENDALINHA.codlinhaprazo    = vnCodLinhaPrazo);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvTipoIncidencia := NULL;
      END;

    ELSE

      -- Se não usa Condição de Venda Agrega sempre o Desconto que encontrar
      vvTipoIncidencia := 'A';

    END IF;

    -- Ofertas da Indústria - Prioriza o que vem no Pedido mesmo que na 2311 não esteja Agrega
    IF (pi_vConcedenteOferta IN ('D','I')) AND
       (pi_vRestringirPromocaoFv = 'S') AND
       (pi_nCodPromocaoMed > 0) THEN
      vvTipoIncidencia := 'A';
    END IF;

    -- Obtém a Qtde. de Dias do Plano de Pagamento
    BEGIN
      SELECT PCPLPAG.NUMDIAS
           , PCPLPAG.PERTXFIM
        INTO vnNumDias
           , vnPerTxFim
        FROM PCPLPAG
       WHERE (PCPLPAG.CODPLPAG = vnCodPlPag);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnNumDias := 0;
        vnPerTxFim := 0;
    END;
    
    BEGIN
      SELECT VALOR
        INTO vvAcrescimoPlPagPrecoFixoMed
        FROM PCPARAMFILIAL
       WHERE (PCPARAMFILIAL.NOME = 'ACRESCIMOPLPAGPRECOFIXOMED')
         AND (PCPARAMFILIAL.CODFILIAL = pi_vCodFilial);
    EXCEPTION
      WHEN OTHERS THEN
        vvAcrescimoPlPagPrecoFixoMed := 'N';
    END;

    -- Regra Específica - Dias a Mais na Vigência - FV
    nDIASMAISPROMOCAOVENCIDAFV := 0;
    IF (vvOrigemPed = 'F') AND
       (vvTipoFv IS NULL) THEN
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
    
    -- DDMEDICA-6841 - Pesquisa o Tipo de Promoção do Item
    BEGIN
      SELECT TIPOPROMOCAO
        INTO vvTipoPromocao
        FROM PCPROMOCAOMED
       WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvTipoPromocao := NULL;
    END;

   /******************
    Inicializa Valores
    ******************/

    vvTipoPromoPrecoOuDesconto := NULL;
    vnCodDesconto              := NULL;
    vnCodPromocaoMed           := NULL;
    vnPrecoFixo                := 0;
    vnPercDesc                 := -99.99; -- 4493.138094.2015
    vnPercDescFin              := 0;
    vnInicioIntervaloQt        := NULL;
    vbEncontrouPromocaoPreco   := FALSE;
    vvAplicaDesconto           := NULL;
    vnMenorPrecoEncontrado     := 999999;

    vbAchouPromocaoItemPedido  := FALSE;
    
    -- Verba para Rebaixa de CMV da Promoção - DDMEDICA-5009
    vnVlDescCmvPromocaoMed     := NULL;
    vnPerDescCmvPromocaoMed    := NULL;
    vnNumVerba                 := NULL;
    vnValorCotaNumVerba        := NULL;
    vvSemVerbaVlDescCmv        := NULL;

    -- % Markup - DDMEDICA-6837
    vnPercMarkupMed            := NULL;

    -- 5685.084449.2016 - Restringir Promoção do Item
    vbPodePesquisarPrecoFixo := TRUE;
    IF (NVL(pi_vRestringirPromocaoFv,'N') = 'S') AND
       (NVL(pi_TipoPromocaoPrecoDesc,'D') = 'D') AND -->> Se Promoção do Item for de Desconto não pode Pesquisar as Promoções de Preço Fixo
       (NVL(pi_nCodPromocaoMed,0) > 0)           THEN
      vbPodePesquisarPrecoFixo := FALSE;
    END IF;
    vbPodePesquisarDesconto := TRUE;
    IF (NVL(pi_vRestringirPromocaoFv,'N') = 'S') AND
       (NVL(pi_TipoPromocaoPrecoDesc,'D') = 'P') AND -->> Se Promoção do Item for de Preço Fixo não pode Pesquisar as Promoções de Desconto
       (NVL(pi_nCodPromocaoMed,0) > 0)           THEN
      vbPodePesquisarDesconto := FALSE;
    END IF;
    -----------------------------------------------------------------------
    -- Pesquisa somente pela da Promoção de Markup,
    -- considerando Desconto/Preço Fixo/Faixa de Quantidade - DDMEDICA-6841
    -----------------------------------------------------------------------
    vbPodePesquisarMarkup := FALSE; -- Markup como é exceção começa como FALSE
    IF (NVL(vvTipoPromocao,' ') = 'R') THEN 
      vbPodePesquisarMarkup    := TRUE;
      -- Se a Promoção do Item for de Markup, 
      -- não pode pesquisar demais Promoções de Preço ou Desconto 
      vbPodePesquisarPrecoFixo := FALSE;
      vbPodePesquisarDesconto  := FALSE;
    END IF;

   /*********************
    Pesquisa as Promoções
    *********************/
    FOR vc_Promocoes IN (SELECT PCPROMOCAOMED.CODPROMOCAOMED
                              , PCPROMOCAOMED.TIPOPOLITICA
                              , PCDESCONTO.INICIOINTERVALOPROMOCAOMED
                              , PCDESCONTO.FIMINTERVALOPROMOCAOMED
                              , NVL(PCDESCONTO.PRECOFIXOPROMOCAOMED,0) PRECOFIXOPROMOCAOMED
                              , NVL(PCDESCONTO.PERCDESC,0) PERCDESC
                              , NVL(PCDESCONTO.PERCDESCFIN,0) PERCDESCFIN
                              , NVL(PCDESCONTO.BASECREDDEBRCA, 'N') BASECREDDEBRCA
                              , PCDESCONTO.DTFIM
                              , NVL(PCDESCONTO.CREDITASOBREPOLITICA, 'S') CREDITASOBREPOLITICA
                              , PCDESCONTO.DTINICIO
                              , PCDESCONTO.CODDESCONTO
                              , PCDESCONTO.ALTERAPTABELA
                              , PCDESCONTO.PRIORITARIA
                              , PCDESCONTO.QUESTIONAUSOPRIORITARIA
                              , PCDESCONTO.CONSIDERACALCGIROMEDIC
                              , PCDESCONTO.CONCEDERMAIORCOMISSREG
                              , PCDESCONTO.APLICADESCONTO
                              , CASE WHEN (PCPROMOCAOMED.TIPOPOLITICA = 'F') THEN 1
                                     WHEN (PCPROMOCAOMED.TIPOPOLITICA = 'P') THEN 2
                                     WHEN (PCPROMOCAOMED.TIPOPOLITICA = 'Q') THEN 3
                                     WHEN (PCPROMOCAOMED.TIPOPOLITICA = 'D') THEN 4
                                     ELSE 5
                                END PRIORIDADE_TIPOPOLITICA
                              , CASE WHEN (PCDESCONTO.CODPROD      IS NOT NULL) THEN 1
                                     WHEN (PCDESCONTO.CODFORNEC    IS NOT NULL) THEN 2
                                     WHEN (PCDESCONTO.CODMARCA     IS NOT NULL) THEN 3
                                     WHEN (PCDESCONTO.CODCATEGORIA IS NOT NULL) THEN 4
                                     WHEN (PCDESCONTO.CODSEC       IS NOT NULL) THEN 5
                                     WHEN (PCDESCONTO.CODLINHAPROD IS NOT NULL) THEN 6
                                     WHEN (PCDESCONTO.CODEPTO      IS NOT NULL) THEN 7
                                     ELSE 8
                                END PRIORIDADE_PRODUTO
                              , PCDESCONTO.PERCMARKUPMED -- 4493.055952.2019
                              , PCDESCONTO.VLDESCCMVPROMOCAOMED -- DDMEDICA-5009
                              , PCPROMOCAOMED.TIPOPROMOCAO -- DDMEDICA-6841
                           FROM PCDESCONTO
                              , PCPROMOCAOMED
                          WHERE (PCPROMOCAOMED.CODPROMOCAOMED = PCDESCONTO.CODPROMOCAOMED) -->> CRITÉRIO PRINCIPAL -> SOMENTE POLÍTICAS DE PROMOÇÕES
                            AND (TRUNC(pi_dData) BETWEEN PCDESCONTO.DTINICIO AND (PCDESCONTO.DTFIM + NVL(nDIASMAISPROMOCAOVENCIDAFV,0)))
                            --AND (NVL(PCDESCONTO.UTILIZADESCREDE, 'N') = 'N') -->> Na Promoção não utilizamos Cliente Principal
                            --AND ((PCDESCONTO.CODCLI = vnCodCli) OR (PCDESCONTO.CODCLI IS NULL))
                            --AND ((PCDESCONTO.CODPRODPRINC = vnCodProdPrinc) OR (CODPRODPRINC IS NULL))
                            --DDMEDICA-1733
                            AND ( ((nvl(PCDESCONTO.UTILIZADESCREDE, 'N') = 'S') AND (codcli IN (vnCodCli,vnCodProdPrinc))) OR
                                ((nvl(PCDESCONTO.UTILIZADESCREDE, 'N') = 'N') AND (codcli  = vnCodCli))       OR
                                (codcli IS NULL) )
                            -- Filtros relacionados ao Produto
                            AND ((PCDESCONTO.CODPROD = pi_nCodProd) OR (PCDESCONTO.CODPROD IS NULL))
                            AND ((PCDESCONTO.CODEPTO = vnCodepto) OR (PCDESCONTO.CODEPTO IS NULL))
                            AND ((PCDESCONTO.CODSEC = vnCodSec) OR (PCDESCONTO.CODSEC IS NULL))
                            AND ((PCDESCONTO.CODCATEGORIA = vnCodCategoria) OR (PCDESCONTO.CODCATEGORIA IS NULL))
                            AND ((PCDESCONTO.CODFORNEC = vnCodFornec) OR (PCDESCONTO.CODFORNEC IS NULL))
                            AND ((PCDESCONTO.CODMARCA  = vnCodMarca) or (PCDESCONTO.CODMARCA IS NULL))
                            AND ((PCDESCONTO.CODLINHAPROD  = vnCodLinhaProd) or (PCDESCONTO.CODLINHAPROD IS NULL))

                            -- Filtros relacionados ao Cliente

                            AND ((PCDESCONTO.CODPRACA = vnCodPraca) OR (PCDESCONTO.CODPRACA IS NULL))
                            AND ((PCDESCONTO.CLASSEVENDA = vvClasseVenda) OR (PCDESCONTO.CLASSEVENDA IS NULL))
                            AND ((PCDESCONTO.CODATIV = vnCodAtv1) OR (PCDESCONTO.CODATIV IS NULL))
                            AND ((PCDESCONTO.CODREDE  = vnCodRede) or (PCDESCONTO.CODREDE IS NULL))
                            AND ((PCDESCONTO.NUMREGIAO = vnNumRegiao) OR (PCDESCONTO.NUMREGIAO IS NULL))
                            AND (CASE WHEN PCDESCONTO.APLICADESCSIMPLESNACIONAL in ('S', 'N') THEN PCDESCONTO.APLICADESCSIMPLESNACIONAL ELSE NVL(vvSimplesNacional, 'T') END = NVL(vvSimplesNacional, 'T'))
                            -- Filtros relacionados ao RCA
                            AND ((PCDESCONTO.CODUSUR = pi_nCodUsur) OR (PCDESCONTO.CODUSUR IS NULL))
                            AND ((PCDESCONTO.CODSUPERVISOR = vnCodSupervisor) OR (PCDESCONTO.CODSUPERVISOR IS NULL))
                            AND ((PCDESCONTO.AREAATUACAO = vvAreaAtuacao) OR (PCDESCONTO.AREAATUACAO IS NULL))
                            -- Filtros relacionados ao Plano de Pagamento
                            AND ( ( ( NVL( PCDESCONTO.APENASPLPAGMAX, 'S' ) = 'N' ) AND ( ( SELECT PCPLPAG.NUMDIAS FROM PCPLPAG WHERE CODPLPAG = NVL(PCDESCONTO.CODPLPAG, vnCodPlPag) ) >= vnNumDias ) )
                                OR ( ( NVL( PCDESCONTO.APENASPLPAGMAX, 'S' ) = 'S' ) AND ( ( NVL(PCDESCONTO.CODPLPAG, vnCodPlPag) = vnCodPlPag ) ) ) )
                            -- Filtros relacionados ao Pedido
                            AND ((PCDESCONTO.ORIGEMPED = vvOrigemPed) OR (NVL(PCDESCONTO.ORIGEMPED, 'O') = 'O'))
                            AND ((PCDESCONTO.CODFILIAL  = vvCodFilial) OR (PCDESCONTO.CODFILIAL IS NULL ))
                            AND ( ((vvOrigemPed = 'F')  AND ((NVL(PCDESCONTO.TIPOFV,'FV') = NVL(vvTipoFv,'FV') ))) OR -- Permitir que o FV visualize a Promoção
                                  ((vvOrigemPed = 'W')) OR -- MED-994 - Permitir que o E-Commerce Visualize a Promoção
                                  ((vvOrigemPed = 'R')) OR -- DDMEDICA-2296 - Balcão Reserva Idem
                                  ((vvOrigemPed = 'C')) OR -- DDVENDAS-38983 - Call Center Idem
                                  ((vvOrigemPed <> 'F') AND ((NVL(PCDESCONTO.TIPOFV,'TL') = vvTipoFv ))) )
                            AND ((PCDESCONTO.CODCONDICAOVENDA = vnCodCondicaoVenda) OR (PCDESCONTO.CODCONDICAOVENDA IS NULL))
                            -- Filtros relacionados à Promoção
                            AND (NVL(PCPROMOCAOMED.BLOQUEIO,'N') = 'N')
                            -- DDVENDAS-39681
                            AND ((EXISTS (SELECT PCDESCONTOITEM.CODDESCONTO
                                        FROM PCDESCONTOITEM
                                       WHERE PCDESCONTOITEM.TIPO = 'GP'
                                         AND PCDESCONTOITEM.CODDESCONTO = PCDESCONTO.CODDESCONTO
                                         AND PCDESCONTOITEM.VALOR_NUM IN
                                             (SELECT PCGRUPOSCAMPANHAI.CODGRUPO
                                                FROM PCGRUPOSCAMPANHAI
                                               WHERE PCGRUPOSCAMPANHAI.CODITEM = pi_nCodProd))) OR
                                 (NOT EXISTS (SELECT PCDESCONTOITEM.CODDESCONTO
                                                FROM PCDESCONTOITEM
                                              WHERE PCDESCONTOITEM.TIPO = 'GP'
                                                    AND PCDESCONTOITEM.CODDESCONTO = PCDESCONTO.CODDESCONTO)))          
                            AND (((pcdesconto.CODGRUPOREST IS NULL) OR (pcdesconto.TIPOGRUPOREST IS NULL)) OR
                                   ((pcdesconto.CODGRUPOREST = CASE WHEN(pcdesconto.TIPOGRUPOREST = 'GR') OR
                                   (pcdesconto.TIPOGRUPOREST = 'CL') OR (pcdesconto.TIPOGRUPOREST = 'GP') THEN
                                   (SELECT PCGRUPOSCAMPANHAI.CODGRUPO
                                       FROM PCGRUPOSCAMPANHAI
                                      WHERE PCGRUPOSCAMPANHAI.DTEXCLUSAO IS NULL
                                         AND PCGRUPOSCAMPANHAI.CODGRUPO = PCDESCONTO.CODGRUPOREST
                                        AND PCGRUPOSCAMPANHAI.CODITEM =
                                            DECODE(PCDESCONTO.TIPOGRUPOREST,
                                                   'CL',
                                                   vnCodCli,
                                                   'GR',
                                                   pi_nCodUsur,
                                                   'GP',
                                                   pi_nCodProd)
                                        AND ROWNUM = 1) ELSE 0 END)))         
                          ORDER BY PRIORIDADE_TIPOPOLITICA
                                 , PRIORIDADE_PRODUTO
                                 , NVL(PCDESCONTO.PRECOFIXOPROMOCAOMED,0) ASC -->> Do Menor Preço para o Maior Preço
                                 , (NVL(PCDESCONTO.PERCDESC,0) + NVL(PCDESCONTO.PERCDESCFIN,0)) DESC -->> Do Maior Desconto para o Menor Desconto
                                 ) LOOP

     /*******************************************************************
      Se Aceita a Promoção conforme Prioridade dentro da própria Promoção
      *******************************************************************/
      IF (FACEITA_PROMOCAO_PRIORIDADE(vc_Promocoes.CODPROMOCAOMED,
                                      vc_Promocoes.PRIORIDADE_PRODUTO,
                                      --
                                      vvCodFilial,
                                      vnCodCli,
                                      vnNumRegiao,
                                      pi_nCodUsur,
                                      vnCodPlPag,
                                      vnCodCondicaoVenda,
                                      vvOrigemPed,
                                      vvTipoFv,
                                      pi_dData)) THEN

        -------------------------------------------------
        -- Promoção de Preço Fixo por Faixa de Quantidade
        -------------------------------------------------
        IF    (vc_Promocoes.TIPOPOLITICA = 'F') AND
              (vbPodePesquisarPrecoFixo)        THEN -- 5685.084449.2016

          -- Se a Quantidade Pedida estiver dentro da Faixa
          IF ((NVL(pi_nQtde,0) >= NVL(vc_Promocoes.INICIOINTERVALOPROMOCAOMED,0)) AND
              (NVL(pi_nQtde,0) <= NVL(vc_Promocoes.FIMINTERVALOPROMOCAOMED,0)))   THEN

            -- Se não achou a Promoção do Item do Pedido
            IF (NOT vbAchouPromocaoItemPedido) THEN
              -- Se o Preço da Promoção menor que o encontrado anteriormente ou Promoção do Item do Pedido
              IF ((NVL(vc_Promocoes.PRECOFIXOPROMOCAOMED,0) * (1 - (NVL(vc_Promocoes.PERCDESCFIN,0)/100))) < NVL(vnMenorPrecoEncontrado,0)) OR
                 ((NVL(pi_nCodPromocaoMed,0) > 0) AND (NVL(pi_nCodPromocaoMed,0) = NVL(vc_Promocoes.CODPROMOCAOMED,0))) THEN
                vbEncontrouPromocaoPreco := TRUE;             -->> Encontrou a Promoção de Preço - Não pesquisará as Promoções de Desconto (Prioridade)
                vvAplicaDesconto         := vvTipoIncidencia; -->> Modo de Aplicação
                -- Se não ignora desconto encontrado
                IF (NVL(vvTipoIncidencia,' ') <> 'I') THEN
                  vvTipoPromoPrecoOuDesconto := 'P';
                  vnCodDesconto              := vc_Promocoes.CODDESCONTO;
                  vnCodPromocaoMed           := vc_Promocoes.CODPROMOCAOMED;
                  
                  IF (vc_Promocoes.TIPOPOLITICA = 'P' OR vc_Promocoes.TIPOPOLITICA = 'F') AND (vvAcrescimoPlPagPrecoFixoMed = 'S') THEN
                    vnPrecoFixo                := NVL(vc_Promocoes.PRECOFIXOPROMOCAOMED,0) * (1 + vnPerTxFim / 100);
                  ELSE
                    vnPrecoFixo                := NVL(vc_Promocoes.PRECOFIXOPROMOCAOMED,0);
                  END IF;
                  
                  vnPercDescFin              := NVL(vc_Promocoes.PERCDESCFIN,0);
                  vnInicioIntervaloQt        := vc_Promocoes.INICIOINTERVALOPROMOCAOMED;
                  vnMenorPrecoEncontrado     := NVL(vc_Promocoes.PRECOFIXOPROMOCAOMED,0) * (1 - (NVL(vc_Promocoes.PERCDESCFIN,0)/100));
                  -- Variável com o Valor da Verba para Rebaixa de CMV da Promoção da PCDESCONTO - DDMEDICA-5009
                  vnVlDescCmvPromocaoMed     := vc_Promocoes.VLDESCCMVPROMOCAOMED;                
                  -- Se Achou Promoção do Item do Pedido
                  IF ((NVL(pi_nCodPromocaoMed,0) > 0) AND (NVL(pi_nCodPromocaoMed,0) = NVL(vc_Promocoes.CODPROMOCAOMED,0))) THEN
                    vbAchouPromocaoItemPedido := TRUE;
                  END IF;
                END IF;
              ELSE
                vvAplicaDesconto := NULL;
              END IF;
            END IF; -- Fim Condição: Se não achou a Promoção do Item do Pedido

            -- Procedimento para Inserir na Tabela Temporária
            P_INSERE_TABTEMP(vc_Promocoes.CODPROMOCAOMED,
                             vc_Promocoes.CODDESCONTO,
                             vc_Promocoes.TIPOPOLITICA,
                             vc_Promocoes.INICIOINTERVALOPROMOCAOMED,
                             vc_Promocoes.FIMINTERVALOPROMOCAOMED,
                             NVL(vc_Promocoes.PRECOFIXOPROMOCAOMED,0),
                             NULL,
                             vc_Promocoes.PERCDESCFIN,
                             vvAplicaDesconto,
                             vc_Promocoes.PRIORIDADE_TIPOPOLITICA,
                             vc_Promocoes.VLDESCCMVPROMOCAOMED,
                             vnCodFornec);

          END IF; -- Fim Condição Se a Quantidade Pedida estiver dentro da Faixa

        --------------------
        -- Promoção de Preço
        --------------------
        ELSIF (vc_Promocoes.TIPOPOLITICA = 'P') AND
              (vbPodePesquisarPrecoFixo)        THEN -- 5685.084449.2016
			  
          -- Se a Quantidade Pedida estiver dentro da Faixa
          IF ((NVL(pi_nQtde,0) >= NVL(vc_Promocoes.INICIOINTERVALOPROMOCAOMED,0)) AND
              (NVL(pi_nQtde,0) <= NVL(vc_Promocoes.FIMINTERVALOPROMOCAOMED,999999))) THEN

            -- Se não achou a Promoção do Item do Pedido
            IF (NOT vbAchouPromocaoItemPedido) THEN
              -- Se o Preço da Promoção menor que o encontrado anteriormente ou Promoção do Item do Pedido
              IF ((NVL(vc_Promocoes.PRECOFIXOPROMOCAOMED,0) * (1 - (NVL(vc_Promocoes.PERCDESCFIN,0)/100))) < NVL(vnMenorPrecoEncontrado,0)) OR
                 ((NVL(pi_nCodPromocaoMed,0) > 0) AND (NVL(pi_nCodPromocaoMed,0) = NVL(vc_Promocoes.CODPROMOCAOMED,0))) THEN
                vbEncontrouPromocaoPreco := TRUE;             -->> Encontrou a Promoção de Preço - Não pesquisará as Promoções de Desconto (Prioridade)
                vvAplicaDesconto         := vvTipoIncidencia; -->> Modo de Aplicação
                -- Se não ignora desconto encontrado
                IF (NVL(vvTipoIncidencia,' ') <> 'I') THEN
                  vvTipoPromoPrecoOuDesconto := 'P';
                  vnCodDesconto              := vc_Promocoes.CODDESCONTO;
                  vnCodPromocaoMed           := vc_Promocoes.CODPROMOCAOMED;
                  
                  IF (vc_Promocoes.TIPOPOLITICA = 'P' OR vc_Promocoes.TIPOPOLITICA = 'F') AND (vvAcrescimoPlPagPrecoFixoMed = 'S') THEN
                    vnPrecoFixo                := NVL(vc_Promocoes.PRECOFIXOPROMOCAOMED,0) * (1 + vnPerTxFim / 100);
                  ELSE
                    vnPrecoFixo                := NVL(vc_Promocoes.PRECOFIXOPROMOCAOMED,0);
                  END IF;
                  
                  vnPercDescFin              := NVL(vc_Promocoes.PERCDESCFIN,0);
                  vnInicioIntervaloQt        := vc_Promocoes.INICIOINTERVALOPROMOCAOMED;
                  vnMenorPrecoEncontrado     := NVL(vc_Promocoes.PRECOFIXOPROMOCAOMED,0) * (1 - (NVL(vc_Promocoes.PERCDESCFIN,0)/100));
                  -- Variável com o Valor da Verba para Rebaixa de CMV da Promoção da PCDESCONTO - DDMEDICA-5009
                  vnVlDescCmvPromocaoMed     := vc_Promocoes.VLDESCCMVPROMOCAOMED;                
                  -- Se Achou Promoção do Item do Pedido
                  IF ((NVL(pi_nCodPromocaoMed,0) > 0) AND (NVL(pi_nCodPromocaoMed,0) = NVL(vc_Promocoes.CODPROMOCAOMED,0))) THEN
                    vbAchouPromocaoItemPedido := TRUE;
                  END IF;
                END IF;
              ELSE
                vvAplicaDesconto := NULL;
              END IF;
            END IF; -- Fim Condição: Se não achou a Promoção do Item do Pedido

            -- Procedimento para Inserir na Tabela Temporária
            P_INSERE_TABTEMP(vc_Promocoes.CODPROMOCAOMED,
                             vc_Promocoes.CODDESCONTO,
                             vc_Promocoes.TIPOPOLITICA,
                             vc_Promocoes.INICIOINTERVALOPROMOCAOMED,
                             vc_Promocoes.FIMINTERVALOPROMOCAOMED,
                             NVL(vc_Promocoes.PRECOFIXOPROMOCAOMED,0),
                             NULL,
                             vc_Promocoes.PERCDESCFIN,
                             vvAplicaDesconto,
                             vc_Promocoes.PRIORIDADE_TIPOPOLITICA,
                             vc_Promocoes.VLDESCCMVPROMOCAOMED,
                             vnCodFornec);
          END IF;
        -----------------------------------------------
        -- Promoção de Desconto por Faixa de Quantidade
        -----------------------------------------------
        ELSIF (vc_Promocoes.TIPOPOLITICA = 'Q') AND
              (vbPodePesquisarDesconto)         THEN -- 5685.084449.2016

          -- Se a Quantidade Pedida estiver dentro da Faixa
          IF ((NVL(pi_nQtde,0) >= NVL(vc_Promocoes.INICIOINTERVALOPROMOCAOMED,0)) AND
              (NVL(pi_nQtde,0) <= NVL(vc_Promocoes.FIMINTERVALOPROMOCAOMED,0)))   THEN

            -- Se não achou a Promoção do Item do Pedido
            IF (NOT vbAchouPromocaoItemPedido) THEN
              -- Se não encontrou Promoção de Preço (PRIORITÁRIA SOBRE O DESCONTO)
              IF (NOT vbEncontrouPromocaoPreco) THEN
                -- Se o Desconto da Promoção maior que o encontrado anteriormente OU Promoção do Item do Pedido
                IF ((NVL(vc_Promocoes.PERCDESC,0) + NVL(vc_Promocoes.PERCDESCFIN,0)) > (NVL(vnPercDesc,0) + NVL(vnPercDescFin,0))) OR
                   ((NVL(pi_nCodPromocaoMed,0) > 0) AND (NVL(pi_nCodPromocaoMed,0) = NVL(vc_Promocoes.CODPROMOCAOMED,0))) THEN
                  vvAplicaDesconto    := vvTipoIncidencia; -->> Modo de Aplicação
                  -- Se não ignora desconto encontrado
                  IF (NVL(vvTipoIncidencia,' ') <> 'I') THEN
                    vvTipoPromoPrecoOuDesconto := 'D';
                    vnCodDesconto              := vc_Promocoes.CODDESCONTO;
                    vnCodPromocaoMed           := vc_Promocoes.CODPROMOCAOMED;
                    vnPercDesc                 := NVL(vc_Promocoes.PERCDESC,0);
                    vnPercDescFin              := NVL(vc_Promocoes.PERCDESCFIN,0);
                    vnInicioIntervaloQt        := vc_Promocoes.INICIOINTERVALOPROMOCAOMED;
                    -- Variável com o Valor da Verba para Rebaixa de CMV da Promoção da PCDESCONTO - DDMEDICA-5009
                    vnVlDescCmvPromocaoMed     := vc_Promocoes.VLDESCCMVPROMOCAOMED;
                    -- Se Achou Promoção do Item do Pedido
                    IF ((NVL(pi_nCodPromocaoMed,0) > 0) AND (NVL(pi_nCodPromocaoMed,0) = NVL(vc_Promocoes.CODPROMOCAOMED,0))) THEN
                      vbAchouPromocaoItemPedido := TRUE;
                    END IF;
                  END IF;
                ELSE
                  vvAplicaDesconto := NULL;
                END IF;
              ELSE
                vvAplicaDesconto := NULL;
              END IF;
            END IF; -- Fim Condição: Se não achou a Promoção do Item do Pedido

            -- Procedimento para Inserir na Tabela Temporária
            P_INSERE_TABTEMP(vc_Promocoes.CODPROMOCAOMED,
                             vc_Promocoes.CODDESCONTO,
                             vc_Promocoes.TIPOPOLITICA,
                             vc_Promocoes.INICIOINTERVALOPROMOCAOMED,
                             vc_Promocoes.FIMINTERVALOPROMOCAOMED,
                             NULL,
                             NVL(vc_Promocoes.PERCDESC,0),
                             NVL(vc_Promocoes.PERCDESCFIN,0),
                             vvAplicaDesconto,
                             vc_Promocoes.PRIORIDADE_TIPOPOLITICA,
                             vc_Promocoes.VLDESCCMVPROMOCAOMED,
                             vnCodFornec);

          END IF; -- Fim Condição Se a Quantidade Pedida estiver dentro da Faixa

        -----------------------
        -- Promoção de Desconto
        -----------------------
        ELSIF (vc_Promocoes.TIPOPOLITICA = 'D') AND
              (vbPodePesquisarDesconto)         THEN -- 5685.084449.2016

          -- Se não achou a Promoção do Item do Pedido
          IF (NOT vbAchouPromocaoItemPedido) THEN
            -- Se não encontrou Promoção de Preço (PRIORITÁRIA SOBRE O DESCONTO)
            IF (NOT vbEncontrouPromocaoPreco) THEN
              -- Se o Desconto da Promoção maior que o encontrado anteriormente OU Promoção do Item do Pedido
              IF ((NVL(vc_Promocoes.PERCDESC,0) + NVL(vc_Promocoes.PERCDESCFIN,0)) > (NVL(vnPercDesc,0) + NVL(vnPercDescFin,0))) OR
                 ((NVL(pi_nCodPromocaoMed,0) > 0) AND (NVL(pi_nCodPromocaoMed,0) = NVL(vc_Promocoes.CODPROMOCAOMED,0))) THEN
                vvAplicaDesconto    := vvTipoIncidencia; -->> Modo de Aplicação
                -- Se não ignora desconto encontrado
                IF (NVL(vvTipoIncidencia,' ') <> 'I') THEN
                  vvTipoPromoPrecoOuDesconto := 'D';
                  vnCodDesconto              := vc_Promocoes.CODDESCONTO;
                  vnCodPromocaoMed           := vc_Promocoes.CODPROMOCAOMED;
                  vnPercDesc                 := NVL(vc_Promocoes.PERCDESC,0);
                  vnPercDescFin              := NVL(vc_Promocoes.PERCDESCFIN,0);
                  vnInicioIntervaloQt        := vc_Promocoes.INICIOINTERVALOPROMOCAOMED;
                  -- Variável com o Valor da Verba para Rebaixa de CMV da Promoção da PCDESCONTO - DDMEDICA-5009
                  vnVlDescCmvPromocaoMed     := vc_Promocoes.VLDESCCMVPROMOCAOMED;
                  -- Se Achou Promoção do Item do Pedido
                  IF ((NVL(pi_nCodPromocaoMed,0) > 0) AND (NVL(pi_nCodPromocaoMed,0) = NVL(vc_Promocoes.CODPROMOCAOMED,0))) THEN
                    vbAchouPromocaoItemPedido := TRUE;
                  END IF;
                END IF;
              ELSE
                vvAplicaDesconto := NULL;
              END IF;
            ELSE
              vvAplicaDesconto := NULL;
            END IF;
          END IF; -- Fim Condição: Se não achou a Promoção do Item do Pedido

          -- Procedimento para Inserir na Tabela Temporária
          P_INSERE_TABTEMP(vc_Promocoes.CODPROMOCAOMED,
                           vc_Promocoes.CODDESCONTO,
                           vc_Promocoes.TIPOPOLITICA,
                           vc_Promocoes.INICIOINTERVALOPROMOCAOMED,
                           vc_Promocoes.FIMINTERVALOPROMOCAOMED,
                           NULL,
                           NVL(vc_Promocoes.PERCDESC,0),
                           NVL(vc_Promocoes.PERCDESCFIN,0),
                           vvAplicaDesconto,
                           vc_Promocoes.PRIORIDADE_TIPOPOLITICA,
                           vc_Promocoes.VLDESCCMVPROMOCAOMED,
                           vnCodFornec);

        ---------------------------------------------------------------
        -- Promoção de Markup (DDMEDICA-6841 - Observar o TIPOPROMOCAO)
        ---------------------------------------------------------------
        ELSIF (vc_Promocoes.TIPOPROMOCAO = 'R') AND
              (vbPodePesquisarMarkup)           THEN
              
          -- Inicializa o Percentual de Desconto e Preço Fixo do Markup
          vnPercDescMarkup  := NULL;
          vnPrecoFixoMarkup := NULL;
         
          -- Verifica de Faixa Válida
          vbAceitaFaixaMarkup := FALSE;
          IF (vc_Promocoes.TIPOPOLITICA IN ('D','P','M')) THEN
            -- Quando não é por faixa de quantidade, aceita sem restrição (Políticas M são consideradas Desconto)
            vbAceitaFaixaMarkup := TRUE;
          ELSE
            -- Se a Quantidade Pedida estiver dentro da Faixa
            IF ((NVL(pi_nQtde,0) >= NVL(vc_Promocoes.INICIOINTERVALOPROMOCAOMED,0)) AND
                (NVL(pi_nQtde,0) <= NVL(vc_Promocoes.FIMINTERVALOPROMOCAOMED,0)))   THEN
              vbAceitaFaixaMarkup := TRUE;
            END IF;
          END IF;

          -- Se aceita a Faixa de Quantidade -- DDMEDICA-6841
          -- Se não achou a Promoção do Item do Pedido
          IF (vbAceitaFaixaMarkup) AND
             (NOT vbAchouPromocaoItemPedido) THEN
            -- Se Promoção igual à do Parâmetro
            IF (NVL(pi_nCodPromocaoMed,0) = NVL(vc_Promocoes.CODPROMOCAOMED,0)) THEN
              vvAplicaDesconto := vvTipoIncidencia; -->> Modo de Aplicação
              -- Se não ignora desconto encontrado
              IF (NVL(vvTipoIncidencia,' ') <> 'I') THEN
                -- Calcula Desconto
                IF ((NVL(pi_nCustoFin,0) = 0) OR
                    (NVL(pi_nPTabela,0)  = 0)) THEN
                  -- 0.018397.2016 - Não carregar desconto da promoção markup com custo zero
                  vnPercDesc               := 0;
                ELSE
                  vnPrecoVendaMarkup       := NVL(pi_nCustoFin,0) * (1+(NVL(vc_Promocoes.PERCMARKUPMED,0) * 0.01));
                  vnPercDesc               := (1-(vnPrecoVendaMarkup/NVL(pi_nPTabela,0)))*100;
                END IF;
                vnPercDescFin              := vc_Promocoes.PERCDESCFIN;
                vvTipoPromoPrecoOuDesconto := 'D'; -- DDMEDICA-6841
                vnPrecoFixo                := 0;
                vnCodDesconto              := vc_Promocoes.CODDESCONTO;
                vnCodPromocaoMed           := vc_Promocoes.CODPROMOCAOMED;
                -- Variável com o Valor da Verba para Rebaixa de CMV da Promoção da PCDESCONTO - DDMEDICA-5009
                vnVlDescCmvPromocaoMed     := vc_Promocoes.VLDESCCMVPROMOCAOMED;
                -- Promoção de Markup com Preço Fixo com ou sem faixa de quantidade - DDMEDICA-6841
                IF (vc_Promocoes.TIPOPOLITICA IN ('P','F')) THEN
                  IF (NVL(vnPercDesc,0) = 0) THEN
                    vnPrecoFixo := NVL(pi_nPTabela,0);
                  ELSE                         
                    vnPrecoFixo := NVL(vnPrecoVendaMarkup,0);
                  END IF;
                  -- Altera Preço Tabela
                  vvTipoPromoPrecoOuDesconto := 'P';
                  -- Não tem desconto (já vai aplicado no Preço Fixo)
                  vnPercDesc := 0;
                END IF;                
                -- Faixa de Quantidade - DDMEDICA-6841
                IF (vc_Promocoes.TIPOPOLITICA IN ('Q','F')) THEN
                  vnInicioIntervaloQt := vc_Promocoes.INICIOINTERVALOPROMOCAOMED;
                END IF;
                -- Percentual Desconto e Preço Fixo Markup para Gravação na Tabela Temp - DDMEDICA-6841
                vnPercDescMarkup          := vnPercDesc;
                vnPrecoFixoMarkup         := vnPrecoFixo;
                -- Achou Promoção do Item do Pedido
                vbAchouPromocaoItemPedido := TRUE;
                -- % Markup que Retornará da Procedure
                vnPercMarkupMed           := vc_Promocoes.PERCMARKUPMED; 
                
              END IF;
            END IF;
          END IF; -- Fim Condição: Se não achou a Promoção do Item do Pedido

          -- Procedimento para Inserir na Tabela Temporária
          P_INSERE_TABTEMP(vc_Promocoes.CODPROMOCAOMED,
                           vc_Promocoes.CODDESCONTO,
                           vc_Promocoes.TIPOPOLITICA,
                           vc_Promocoes.INICIOINTERVALOPROMOCAOMED,
                           vc_Promocoes.FIMINTERVALOPROMOCAOMED,
                           NVL(vnPrecoFixoMarkup,0),
                           NVL(vnPercDescMarkup,0),
                           NVL(vc_Promocoes.PERCDESCFIN,0),
                           vvAplicaDesconto,
                           vc_Promocoes.PRIORIDADE_TIPOPOLITICA,
                           vc_Promocoes.VLDESCCMVPROMOCAOMED,
                           vnCodFornec);

        END IF;

     /***********************************************************************
      Se NÃO Aceita a Promoção conforme Prioridade dentro da própria Promoção
      ***********************************************************************/
      ELSE

        -- Procedimento para Inserir na Tabela Temporária
        P_INSERE_TABTEMP(vc_Promocoes.CODPROMOCAOMED,
                         vc_Promocoes.CODDESCONTO,
                         vc_Promocoes.TIPOPOLITICA,
                         vc_Promocoes.INICIOINTERVALOPROMOCAOMED,
                         vc_Promocoes.FIMINTERVALOPROMOCAOMED,
                         NULL,
                         NVL(vc_Promocoes.PERCDESC,0),
                         NVL(vc_Promocoes.PERCDESCFIN,0),
                         NULL,
                         vc_Promocoes.PRIORIDADE_TIPOPOLITICA,
                         vc_Promocoes.VLDESCCMVPROMOCAOMED,
                         vnCodFornec);

      END IF; -- Fim Condição Se Aceita a Promoção conforme Prioridade dentro da própria Promoção

    END LOOP; -- Fim Laço de Promoções

   /*****************************************************
    Verba para Rebaixa de CMV da Promoção - DDMEDICA-5009
    *****************************************************/
    PKG_PROMOCAO_MED.P_OBTER_VERBA_PROMOCAO(vnCodPromocaoMed,
                                            vnCodFornec,
                                            vnVlDescCmvPromocaoMed,                                            
                                            vnNumVerba,
                                            vnValorCotaNumVerba,
                                            vvSemVerbaVlDescCmv);

    -- Se for para Inserir na Tabela Temporária
    IF (pi_vGravaTabTemp = 'S') THEN

      -- Se  a Promoção concedida foi de Desconto, registra o maior desconto selecionado
      IF (vvTipoPromoPrecoOuDesconto = 'D') THEN
        -- Inicializa
        UPDATE PCMED_SELPROMOCAO
           SET APLICADESCONTO = NULL;
        -- Marca a política selecionada
        UPDATE PCMED_SELPROMOCAO
           SET APLICADESCONTO = 'S'
         WHERE (CODDESCONTO = vnCodDesconto);
      END IF;

      -- Efetiva Transações
      IF (pi_vExecutaCommit = 'S') THEN
        COMMIT;
      END IF;
    END IF;

   /***********************
    Retorno do Procedimento
    ***********************/
    po_vTipoPromoPrecoDesc   := vvTipoPromoPrecoOuDesconto;
    po_nCodDesconto          := vnCodDesconto;
    po_nCodPromocaoMed       := vnCodPromocaoMed;
    IF    (vvTipoPromoPrecoOuDesconto = 'D') THEN
      IF (NVL(vvUsaDescFinSeparadoDescCom,'N') = 'S') THEN
        po_nPercDesc         := vnPercDesc;
        po_nPercDescFin      := vnPercDescFin;
      ELSE
        po_nPercDesc         := (NVL(vnPercDesc,0) + NVL(vnPercDescFin,0));
        po_nPercDescFin      := 0;
      END IF;
    ELSIF (vvTipoPromoPrecoOuDesconto = 'P') THEN
      po_nPrecoFixo          := vnPrecoFixo;
      po_nPercDescFin        := vnPercDescFin;
    END IF;
    po_nInicioIntervaloQt    := vnInicioIntervaloQt;
    -- Verba para Rebaixa de CMV da Promoção - DDMEDICA-5009
    po_nVlDescCmv            := vnVlDescCmvPromocaoMed;
    po_nPerDescCmv           := vnPerDescCmvPromocaoMed;
    po_nNumVerba             := vnNumVerba;
    po_nValorCotaNumVerba    := vnValorCotaNumVerba;
    po_vSemVerbaVlDescCmv    := vvSemVerbaVlDescCmv;
    -- % Markup
    po_nPercMarkupMed        := vnPercMarkupMed; -- DDMEDICA-6837

    -------------------------------------------
    -- Se for para Inserir na Tabela Temporária
    -------------------------------------------
    IF (pi_vGravaTabTemp = 'S') THEN
      -- GRAVA RETORNOS NA TABELA TEMPORÁRIA
      P_INSERE_TABTEMP(-1, -- Identificador de Registro de Promoção Selecionada
                       po_nCodDesconto,
                       po_vTipoPromoPrecoDesc,
                       NULL,
                       NULL,
                       po_nPrecoFixo,
                       po_nPercDesc,
                       po_nPercDescFin,
                       NULL,
                       NULL,
                       po_nVlDescCmv,
                       vnCodFornec);
      -- Efetiva Transações
      IF (pi_vExecutaCommit = 'S') THEN
        COMMIT;
      END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      po_vOcorreramErros := 'S';
      po_vMsgErros       := SQLERRM;
  END P_OBTEM_DESC_PROMOCAO;

 /*********************************************************
  Função para Retornar o Percentual de Comissão da Promoção
  *********************************************************/
  FUNCTION F_OBTER_COMISSAO_PROMOCAO(pi_nCodDesconto    IN NUMBER,
                                     pi_nCodPromocaoMed IN NUMBER,
                                     pi_vTipoVend       IN VARCHAR2,
                                     pi_nCodProd        IN NUMBER) RETURN NUMBER IS
    -- Retorno
    vnRetPerCom        PCDESCONTO.PERCOMREP%TYPE;
    -- Variáveis auxiliares
    vnCodGrupoComissao PCPROMOCAOMED.CODGRUPOCOMISSAO%TYPE;
    vnCodMarca         PCPRODUT.CODMARCA%TYPE;

  BEGIN

    -- Pesquisa Grupo de Comissão
    BEGIN
      SELECT CASE WHEN (NVL(PRIORIZACOMISSAO,'N') = 'S') THEN
               CODGRUPOCOMISSAO
             ELSE
               NULL
             END
        INTO vnCodGrupoComissao
        FROM PCPROMOCAOMED
       WHERE (CODPROMOCAOMED = pi_nCodPromocaoMed);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnCodGrupoComissao := NULL;
    END;

    -- Se tem Grupo de Comissão
    IF (vnCodGrupoComissao > 0) THEN

      -- Pesquisa a Marca do Produto
      BEGIN
        SELECT CODMARCA
          INTO vnCodMarca
          FROM PCPRODUT
         WHERE (CODPROD = pi_nCodProd);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnCodMarca := NULL;
      END;

      -- Pesquisa a Comissão
      BEGIN
        SELECT T.PERCENTUAL
          INTO vnRetPerCom
          FROM PCTABELACOMISSAOGRUPOMED T
         WHERE T.CODGRUPO = vnCodGrupoComissao
           AND (T.CAMPO  = 'MA')
           AND (T.CODIGO = vnCodMarca);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnRetPerCom := 0;
      END;

    -- Se não tem Grupo de Comissão
    ELSE

      -- Pesquisa o Percentual de Comissão da Promoção
      BEGIN
        SELECT DECODE(pi_vTipoVend
                     ,'I', PERCOMMINT
                     ,'E', PERCOMEXT
                     ,'R', PERCOMREP
                     ,0) PERCOM
          INTO vnRetPerCom
          FROM PCDESCONTO
         WHERE (PCDESCONTO.CODDESCONTO    = pi_nCodDesconto)
           AND (PCDESCONTO.CODPROMOCAOMED = pi_nCodPromocaoMed)
           AND (ROWNUM                    = 1);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnRetPerCom := 0;
      END;

    END IF;

    -- Retorno
    RETURN NVL(vnRetPerCom,0);

  END F_OBTER_COMISSAO_PROMOCAO;

 /************************************************************
  Função para Retornar o Percentual de Comissão da Integradora
  DDMEDICA-1835
  ***********************************************************/
  FUNCTION F_OBTER_COMISSAO_INTEGRADORA(pi_nCodDesconto          IN NUMBER,
                                        pi_nCodPromocaoMed       IN NUMBER,
                                        pi_vTipoVend             IN VARCHAR2,
                                        pi_nCodProd              IN NUMBER,
                                        pi_nIntegradora          IN NUMBER DEFAULT NULL,
                                        po_nComissaoIntegradora OUT NUMBER) RETURN VARCHAR2 IS
    -- Retorno
    vvExistePerCom             VARCHAR2(1);
    -- Variáveis auxiliares
    vnCodGrupoComissao         PCPROMOCAOMED.CODGRUPOCOMISSAO%TYPE;
    vvPriorizaComissao         PCPROMOCAOMED.PRIORIZACOMISSAO%TYPE;
    vnCodMarca                 PCPRODUT.CODMARCA%TYPE;
    -- Parâmetro da Integradora - DDMEDICA-1835
    vvGrupoComissaoIntegradora PCPARAMINTEGRADORAMED.VALOR%TYPE;
    vnGrupoComissaoIntegradora NUMBER;

  BEGIN
   
    -- Inicializa Retornos
    vvExistePerCom          := 'N';
    po_nComissaoIntegradora := 0;
  
    -- Verifica se Pedido Integradora
    IF (NVL(pi_nIntegradora,0) > 0) THEN

      -- Obtém o Grupo de Comissão da Integradora
      vvGrupoComissaoIntegradora := FOBTEM_PARAM_INTEGRADORA(pi_nIntegradora,
                                                             'GRUPOCOMISSAOINTEGRADORA',
                                                             '0');
      -- Converte para Número o Grupo Encontrado
      BEGIN                                                            
        vnGrupoComissaoIntegradora := TO_NUMBER(vvGrupoComissaoIntegradora);
      EXCEPTION
        WHEN OTHERS THEN
          vnGrupoComissaoIntegradora := NULL;
      END;  
      
      -- Se a Integradora utiliza Grupo de Comissão
      IF (NVL(vnGrupoComissaoIntegradora,0) > 0) THEN
        -- Aplicará o Grupo de Comissão cadastrado na Integradora
        vnCodGrupoComissao := vnGrupoComissaoIntegradora;
      END IF;   
      
      -- Se tem Grupo de Comissão, ela JÁ É PRIORIZADA
      IF (NVL(vnCodGrupoComissao,0) > 0) THEN
  
        -- Existe Comissão da Integradora
        vvExistePerCom := 'S';
  
        -- Pesquisa a Marca do Produto
        BEGIN
          SELECT CODMARCA
            INTO vnCodMarca
            FROM PCPRODUT
           WHERE (CODPROD = pi_nCodProd);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnCodMarca := NULL;
        END;
  
        -- Pesquisa a Comissão
        BEGIN
          SELECT T.PERCENTUAL
            INTO po_nComissaoIntegradora
            FROM PCTABELACOMISSAOGRUPOMED T
           WHERE T.CODGRUPO = vnCodGrupoComissao
             AND (T.CAMPO  = 'MA')
             AND (T.CODIGO = vnCodMarca);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            po_nComissaoIntegradora := 0;
        END;
        
      END IF; -- Fim Condição: Se tem Grupo de Comissão
                                                             
    END IF; -- Fim: Verifica se Pedido Integradora, se trabalha com Grupo de Comissão

    -- Retorno indicando se existe Comissão da Integradora
    RETURN vvExistePerCom;

  END F_OBTER_COMISSAO_INTEGRADORA;                                        
  
 /************************************************************
  Função para Retornar se Bloqueia a Comissão do RCA
  ***********************************************************/
  FUNCTION F_BLOQUEIA_COMISSAO(pi_nCodUsur IN NUMBER) RETURN VARCHAR2 IS
    vvBloqComis                  PCUSUARI.BLOQCOMIS%TYPE;
    vUSABLOQUEIOCOMISSAOVENDEDOR VARCHAR2(100);
  BEGIN
  
    BEGIN
      SELECT PCUSUARI.BLOQCOMIS
        INTO vvBloqComis
        FROM PCUSUARI
       WHERE (PCUSUARI.CODUSUR = pi_nCodUsur);       
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvBloqComis := 'N';
    END;
    
    IF (vvBloqComis = 'S') THEN
      vUSABLOQUEIOCOMISSAOVENDEDOR := FUSA_REGRA_MEDICAMENTOS('99',
                                                              'USABLOQUEIOCOMISSAOVENDEDOR');
      IF (NVL(vUSABLOQUEIOCOMISSAOVENDEDOR,'N') <> 'S') THEN
        vvBloqComis := 'N';
      END IF;
    END IF;
    
    RETURN vvBloqComis;
    
  END F_BLOQUEIA_COMISSAO;                                       
  
 /***********************************************************************************************
  PROCEDURE: proc_validamarfilialplano
  DESCRIÇÃO: Validar Filial do Plano de Pagamento - DDMEDICA-675
  ***********************************************************************************************/
  PROCEDURE proc_validamarfilialplano(pi_vOrigemPed                  IN VARCHAR2,
                                      pi_vTipoFv                     IN VARCHAR2,
                                      pi_vCodFilial                  IN VARCHAR2,
                                      pi_nCodPlPag                   IN NUMBER,
                                      pi_vTipoEticoGenerico          IN VARCHAR2,
                                      pi_vTipoImportacaoVenda        IN VARCHAR2,
                                      po_vRejeitado                  OUT VARCHAR2,
                                      po_vMotivoRejeitado            OUT VARCHAR2,
                                      po_vObservacao                 OUT VARCHAR2,
                                      po_vJsonRejeitado              OUT VARCHAR2,
                                      po_vGravarComoBloqueado        OUT VARCHAR2,
                                      po_nCodMotivoNaoAtend          OUT NUMBER) IS
    -- Variáveis
    vvCodFilialPlano           PCPLPAG.CODFILIAL%TYPE;
    vvUsaMultFilialPlano       PCPLPAG.USAMULTIFILIAL%TYPE;
    vvDescricaoPlano           PCPLPAG.DESCRICAO%TYPE;
    vvAceitaPlano              VARCHAR2(1);
    vvOrientacaoPlanoPagamento VARCHAR2(32000);
    vvDescTipoEticoGenerico    VARCHAR2(50);
    vvDescMultiFilial          VARCHAR2(50);
  BEGIN

    -- Inicializa Retornos
    po_vRejeitado           := 'N';
    po_vMotivoRejeitado     := NULL;
    po_vObservacao          := NULL;
    po_vJsonRejeitado       := NULL;
    po_vGravarComoBloqueado := 'N';
    po_nCodMotivoNaoAtend   := NULL;

    -- Tipo Ético/Genérico
    vvDescTipoEticoGenerico := NULL;
    IF    (pi_vTipoEticoGenerico = 'E') THEN
      vvDescTipoEticoGenerico := 'Ético ';
    ELSIF (pi_vTipoEticoGenerico = 'G') THEN
      vvDescTipoEticoGenerico := 'Genérico ';
    END IF;

    -- Pesquisa Prazo Médio do Pedido
    BEGIN
      SELECT CODFILIAL
           , USAMULTIFILIAL
           , DESCRICAO
        INTO vvCodFilialPlano
           , vvUsaMultFilialPlano
           , vvDescricaoPlano
        FROM PCPLPAG
       WHERE (CODPLPAG = pi_nCodPlPag);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvCodFilialPlano     := 0;
        vvUsaMultFilialPlano := NULL;
        vvDescricaoPlano     := NULL;
    END;

    -- Se usa Plano Multi-Filial
    IF (NVL(vvUsaMultFilialPlano,'N') = 'S') THEN

      vvDescMultiFilial := ' (Plano MultiFilial)';

      BEGIN
        SELECT 'S'
          INTO vvAceitaPlano
          FROM PCPLPAGFILIAL
         WHERE (PCPLPAGFILIAL.CODFILIAL = pi_vCodFilial)
           AND (PCPLPAGFILIAL.CODPLPAG  = pi_nCodPlPag)
           AND (ROWNUM                  = 1);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvAceitaPlano := 'N';
      END;

    -- Se não usa Plano Multi-Filial
    ELSE

      vvDescMultiFilial := NULL;

      vvAceitaPlano := 'S';

      IF ((vvCodFilialPlano IS NOT NULL) AND
          (vvCodFilialPlano <> '99')     AND
          (vvCodFilialPlano <> pi_vCodFilial)) THEN

        vvAceitaPlano := 'N';

      END IF;

    END IF;


    -- Se NÃO ACEITA PLANO
    IF (vvAceitaPlano = 'N') THEN

      po_vRejeitado         := 'S';
      po_vMotivoRejeitado   := 'Plano de Pagamento ' || vvDescTipoEticoGenerico || 'não liberado para a Filial';
      po_nCodMotivoNaoAtend := 6;  -- Plano de Pagamento não cadastrado
      po_vObservacao        := 'O Plano de Pagamento ' || vvDescTipoEticoGenerico || 'igual a "' || pi_nCodPlPag || ' - ' || vvDescricaoPlano || '" não está liberado para a Filial "' || pi_vCodFilial || '".' || vvDescMultiFilial;

      -- Se está deixando gravar como Bloqueado
      IF (NVL(pi_vTipoImportacaoVenda,'X') = 'BP') THEN
        po_vGravarComoBloqueado    := 'S'; -->> Gravar o Pedido como Bloqueado
        vvOrientacaoPlanoPagamento := 'Alternativas para gravar o Pedido na posição Liberado (não bloquear o Pedido): ' || CHR(13) ||
                                      '- Solicitar a liberação da Filial "' || pi_vCodFilial || '" para este Plano de Pagamento na Rotina 523.';
      -- Se está rejeitando
      ELSE
        vvOrientacaoPlanoPagamento := 'Alternativas para não rejeitar o Pedido: ' || CHR(13) ||
                                      '- Alterar o Parâmetro da Presidência "2354" para gravar o Pedido como Bloqueado.';
        IF (NVL(pi_vTipoFv,'FV') IN ('OL','PE')) THEN
          vvOrientacaoPlanoPagamento := vvOrientacaoPlanoPagamento || CHR(13) ||
                                        'Após revisão dos cadastros, o Pedido poderá ser reprocessado na Consulta de Pedidos da Rotina 2302, na aba "Pedidos", podendo ser feita a multi-seleção de Pedidos para reprocessamento.';
        END IF;
      END IF;

      po_vJsonRejeitado := func_gerarlogjson(po_vMotivoRejeitado,
                                             po_vObservacao,
                                             '523',
                                             '2354',
                                             NULL,
                                             vvOrientacaoPlanoPagamento);

    END IF; -- Fim Condição: Se NÃO ACEITA PLANO

  END proc_validamarfilialplano;

 /***********************************************************************************************
  PROCEDURE: P_OBTEM_DESC_INTEGRADORA
  DESCRIÇÃO: DDMEDICA-706 - Otimização Consulta por Condição de Venda
  ***********************************************************************************************/
  PROCEDURE P_OBTEM_DESC_INTEGRADORA(pi_nCodProd                  IN  pcprodut.codprod%type,
                                     pi_nqtde                     IN  pcpedi.qt%type,
                                     pi_nCodCondicaoVenda         IN  pccondicaovenda.codcondicaovenda%type,
                                     pi_nCodCli                   IN  pcclient.codcli%type,
                                     pi_dData                     IN  DATE,
                                     pi_sCodFilial                IN  pcfilial.codigo%type,
                                     pi_nNumregiao                IN  pcregiao.numregiao%type,
                                     pi_nCodusur                  IN  pcusuari.codusur%type,
                                     pi_sOrigempedido             IN  pcpedc.origemped%type,
                                     pi_nCodProdPrinc             IN  pcprodut.codprodprinc%type,
                                     pi_nNumcasasdecvenda         IN  pcconsum.numcasasdecvenda%type,
                                     pi_nCodPlPag                 IN  pcplpag.codplpag%type,
                                     pi_nnumdias                  IN  pcplpag.numdias%type,
                                     pi_sclassevenda              IN  pcclient.classevenda%type,
                                     pi_ncodpraca                 IN  pcclient.codpraca%type,
                                     pi_snaousarautdebcredpoldesc IN varchar2,
                                     pi_sUsaprioritaria           IN varchar2,
                                     pi_sTipofv                   IN pcpedretorno.tipofv%type,
                                     po_sBasecreddebrca           OUT pcdesconto.basecreddebrca%type,
                                     po_sCreditasobrepolitica     OUT pcdesconto.creditasobrepolitica%type,
                                     po_sAlteraptabela            OUT pcdesconto.alteraptabela%type,
                                     po_nDescpbaserca             OUT pcdesconto.percdesc%type,
                                     po_creditasobreptabela_quant  OUT pcdescquant.creditasobreptabela%type,
                                     po_basedebcredrca_quant      OUT pcdescquant.basecreddebrca%type,
                                     po_percbaserca_quant         OUT pcdescquant.percdesc%type,
                                     po_nPerDesc                  OUT NUMBER,
                                     po_nPerBonific               OUT NUMBER,
                                     po_nPerComerc                OUT NUMBER,
                                     po_nPerBoleto                OUT NUMBER,
                                     po_nPercDescFin              OUT NUMBER,
                                     po_vOcorreramErros           OUT VARCHAR2,
                                     po_vMsgErros                 OUT VARCHAR2,
                                     pio_CodLinhaPrazo            IN  OUT VARCHAR2, -- 155824)
                                     pi_stratarrestricaoacrescimo IN  VARCHAR2, --4663.087543.2014
                                     pi_saplicaracrescimopolitica IN  VARCHAR2,
                                     po_nCodDescontoPolitica      OUT NUMBER,   -- HIS.03080.2016
                                     po_nCodPromocaoMedPolitica   OUT NUMBER,   -- HIS.03080.2016
                                     po_nPrecoFixoPolitica        OUT NUMBER,   -- HIS.03080.2016
                                     po_vTipoPrecoDescPolitica    OUT VARCHAR2, -- HIS.03080.2016
                                     po_nVlDescCmv                OUT NUMBER,   -- DDMEDICA-5009
                                     po_nPerDescCmv               OUT NUMBER,   -- DDMEDICA-5009
                                     po_nNumVerba                 OUT NUMBER,   -- DDMEDICA-5009
                                     po_nValorCotaNumVerba        OUT NUMBER,   -- DDMEDICA-5009
                                     po_vSemVerbaVlDescCmv        OUT VARCHAR2, -- DDMEDICA-5009
                                     po_vMsgProc                  OUT VARCHAR2, -- HIS.03080.2016
                                     pi_vGravaTabTemp             IN  VARCHAR2,
                                     pi_vExecutaCommit            IN  VARCHAR2,
                                     pi_nIntegradora              IN  NUMBER,
                                     pi_nPTabela                  IN  NUMBER,
                                     pi_nCustoFin                 IN  NUMBER,
                                     po_nInicioIntervaloQt        OUT NUMBER,
                                     po_nPercMarkupMed            OUT NUMBER
                                     ) IS
  /*******************************************************************************

    Procedimento: PRC_MED_OBTEM_DESC_INTEGRADORA
    OBSERVAÇÃO  : Separada da INTEGRADORA_MED porque excedermos o limite de linhas da package
                  (Proc. Original PRC_VEN_OBTEM_DESC_CONDVENDA)

    Proposito: Procedimento para obter os Descontos da Condição de Venda de
               Medicamentos
    Versao    :
    Allteração: 28/10/2015 - Anderson Silva - Considerar Coluna de Linha de Produto na PCDESCONTO
    Allteração: 01/03/2016 - Anderson Silva - Utilizar Faixas da Promoção
    Alteração : 30/08/2016 - Anderson Silva - Normalização PCDESCONTO
    Alteração : 24/10/2016 - HIS.03080.2016 - Anderson Silva - Importar Promoção Preço
    Alteração : 12/09/2016 - HIS.01889.2017 - Anderson Silva - Grupos na PCDESCONTO
    Alteração : 28/08/2018 - Anderson Silva MED-1554   Faixa de Quantidade na 561
    Alteração : 28/09/2018 - Anderson Silva MED-1729 - Priorização Desconto Total

    Parâmetros de Entrada:
    ---------------------
    pi_nCodProd          = Código do Produto no Winthor
    pi_nCodCondicaoVenda = Código da Condição de Venda no Winthor
    pi_nCodCli           = Código do Cliente no Winthor

    Parâmetros de Saída:
    -------------------
    po_nPerDesc          = Percentual de Desconto do Produto a ser concedido na
                           Nota Fiscal
    po_nPerBonific       = Percentual de Desconto de Bonificação a ser concedido
                           na Nota Fiscal. Este percentual está contido em po_nPerDesc
    po_nPerComerc        = Percentual de Desconto Comercial a ser concedido
                           na Nota Fiscal. Este percentual está contido em po_nPerDesc
    po_nPerBoleto        = Percentual de Desconto do Produto a ser concedido no Boleto
    po_nPercDescFin      = Percentual de Desconto Financeiro da Linha de Prazo
    po_vOcorreramErros   = Indicação se ocorreram erros: S-Sim; N-Não
    po_vMsgErros         = Mensagem com o erro

   *******************************************************************************/

    -- DDMEDICA-706
    vPESQDESCINTEGRADORA              VARCHAR2(250);

    -- Parametro da Empresa Tipo de Prazo de Medicamentos
    vvTipoPrazoMedicam       PCPARAMFILIAL.valor%TYPE;
    vvAcrescimoPlPagPrecoFixoMed PCPARAMFILIAL.valor%TYPE;

    vcPermiteDescBoleto      pcclient.usadescfinseparadodesccom%type;

    -- Descontos cadastrados na Politica de Descontos
    vnPercDescComercPolitica PCDESCONTO.percdesc%TYPE;
    vnPercDescBoletoPolitica PCDESCONTO.percdescfin%TYPE;
    vbpoliticadescvalida     boolean;
    vsmensagempoldesc        varchar2(300);

    -- Desconto cadastrado por Quantidade
    vnPercDescComercQuantid  PCDESCQUANT.percdesc%TYPE;
    vbvalidodescquant        boolean;
    vsmensagemdescquant      varchar2(300);

    -- Descontos Promocionais (Recebera o maior entre a Politica de Descontos e os Descontos por Quantidade)
    vnPercDescComercPromocao PCDESCONTO.percdesc%TYPE;
    vnPercDescBoletoPromocao PCDESCONTO.percdescfin%TYPE;
    --vnPercDescTotalPromocao  PCDESCONTO.percdesc%TYPE;

    -- Percentual de Desconto de Bonificação, Grupo Faturamento e Linha de Prazo do Cadastro do Produto
    vnPercDescBonifProduto   PCPRODUT.percbonificvenda%TYPE;
    vvGrupoFaturamento       PCPRODUT.grupofaturamento%TYPE;
    vnCodLinhaPrazo          PCPRODUT.codlinhaprazo%TYPE;

    -- Plano Pagamento, Descontos e Parametro de Tipo de Incidencia da Linha da Condicao de Venda
    vnCodPlPag               PCCONDVENDALINHA.codplpag%TYPE;
    vnPercDescBonifLinha     PCCONDVENDALINHA.percdescbonifnota%TYPE;
    vnPercDescComercLinha    PCCONDVENDALINHA.percdescomnota%TYPE;
    vnPercDescBoletoLinha    PCCONDVENDALINHA.percdescboleto%TYPE;
    vnPercDescFinLinha       PCCONDVENDALINHA.percdescfin%TYPE;
    vvTipoIncidencia         PCCONDVENDALINHA.tipoincidenciadescom%TYPE;

    -- Parâmetro da condicao de venda que define a Origem do Desconto de Bonificação
    vvTipoDescBonif          PCCONDICAOVENDA.tipodescbonif%TYPE;

    -- Percentual de Desconto Total da Linha
    vnPercDescTotalLinha     PCCONDVENDALINHA.percdescbonifnota%TYPE;

    -- Percentual de Desconto do Produto que será Concedido em Nota Fiscal
    vnPerDesc                PCPEDI.perdesc%TYPE;
    -- Percentual de Desconto de Bonificação
    vnPerBonific             PCPEDI.perbonific%TYPE;
    -- Percentual de Desconto Comercial
    vnPerComerc              PCPEDI.perdesccom%TYPE;
    -- Percentual de Desconto do Produto que será Concedido no Boleto
    vnPerBoleto              PCPEDI.perdescboleto%TYPE;
    
    -- Dados do Plano de Pagamento 
    vnPerTxFim                 PCPLPAG.PERTXFIM%TYPE;

    -- HIS.03080.2016  - Variáveis para Implementação de Promoção com Preço Fixo
    vnCodDescontoPolitica        NUMBER;      -- HIS.03080.2016
    vnCodPromocaoMedPolitica     NUMBER;      -- HIS.03080.2016
    vnPrecoFixoPolitica          NUMBER;      -- HIS.03080.2016
    vvTipoPrecoDescPolitica      VARCHAR2(1); -- HIS.03080.2016
    vnInicioIntervaloQtPolitica  NUMBER;      -- DDMEDICA-6837
    vnPercMarkupPoliticaPolitica NUMBER;      -- DDMEDICA-6837

    -- Variáveis para geração de Log - DDMEDICA-2858
    vnCodDescontoSelTabTemp  NUMBER;
    vnCodPromocaoSelTabTemp  NUMBER;

    -- Verba para Rebaixa de CMV da Promoção - DDMEDICA-5009
    vnVlDescCmvPromocaoMed   NUMBER; 
    vnPerDescCmvPromocaoMed  NUMBER; 
    vnNumVerba               NUMBER;
    vnValorCotaNumVerba      NUMBER;
    vvSemVerbaVlDescCmv      VARCHAR2(1);
    
    -- Parâmetro da Integradora - DDMEDICA-6837
    vREGRAAPLICACAOPROMOCAOMARKUP  PCPARAMINTEGRADORAMED.VALOR%TYPE;

    -- Excecao de Erro Generico
    e_Generico               EXCEPTION;

    -- Função para calcular Desconto sobre Desconto
    FUNCTION F_CalcDescontoSobreDesconto(pi_nDesconto1 IN NUMBER,
                                         pi_nDesconto2 IN NUMBER)
    RETURN NUMBER IS
      vnPercDesconto    PCCONDVENDALINHA.percdescbonifnota%TYPE;
      vnPercDescRetorno PCCONDVENDALINHA.percdescbonifnota%TYPE;
    BEGIN
      -- Cálculo do Desconto sobre Desconto
      vnPercDesconto    := 100;
      vnPercDesconto    := (vnPercDesconto * (1 - (NVL(pi_nDesconto1,0) / 100)));
      vnPercDesconto    := (vnPercDesconto * (1 - (NVL(pi_nDesconto2,0) / 100)));
      vnPercDescRetorno := 100 - NVL(vnPercDesconto,0);
      -- Retorno
      RETURN vnPercDescRetorno;
    END F_CalcDescontoSobreDesconto;

 /**********************************************************
  PROCEDURE: P_INSERE_TABTEMP
  DESCRICAO: Gravar na Tabela Temporária Promoção encontrada
  **********************************************************/
  PROCEDURE P_INSERE_TABTEMP(pi_nCodPromocaoMedDesconto IN NUMBER,
                             pi_nCodDesconto            IN NUMBER,
                             pi_vTipoPolitica           IN VARCHAR2,
                             pi_nInicioIntervalo        IN NUMBER,
                             pi_nFimIntervalo           IN NUMBER,
                             pi_nPrecoFixo              IN NUMBER,
                             pi_nPercDesc               IN NUMBER,
                             pi_nPercDescFin            IN NUMBER,
                             pi_vPrioritaria            IN VARCHAR2,
                             pi_vSelecionar             IN VARCHAR2) IS
  BEGIN

    -- Se for para inserir na Tabela Temporária
    IF (pi_vGravaTabTemp = 'S') THEN

      -- Atualiza
      IF (NVL(pi_vSelecionar,'N') = 'S') THEN
      
        UPDATE PCMED_SELPROMOCAO
           SET APLICADESCONTO = 'S'
         WHERE (CODPROMOCAOMED = pi_nCodPromocaoMedDesconto)
           AND (CODDESCONTO    = pi_nCodDesconto);
      
      -- Insere
      ELSE
       
        BEGIN
          INSERT INTO PCMED_SELPROMOCAO
                    ( CODPROMOCAOMED
                    , CODDESCONTO
                    , TIPOPOLITICA
                    , INICIOINTERVALO
                    , FIMINTERVALO
                    , PRECOFIXO
                    , PERCDESC
                    , PERCDESCFIN
                    , PRIORITARIA
                    )
             VALUES ( pi_nCodPromocaoMedDesconto
                    , pi_nCodDesconto
                    , pi_vTipoPolitica
                    , pi_nInicioIntervalo
                    , pi_nFimIntervalo
                    , pi_nPrecoFixo
                    , pi_nPercDesc
                    , pi_nPercDescFin
                    , pi_vPrioritaria
                    );
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
            NULL;
        END;
        
      END IF;

    END IF; -- Fim Condição Se for para inserir na Tabela Temporária

  END P_INSERE_TABTEMP;

  FUNCTION FUNCAO_OBTEM_DESC_POLITICA
    (p_codprod                  IN NUMBER,
     p_data                     IN DATE,
     p_codfilial                IN VARCHAR2,
     p_numregiao                IN NUMBER,
     p_codcli                   IN NUMBER,
     p_codusur                  IN NUMBER,
     p_origempedido             IN VARCHAR2,
     p_codprodprinc             IN NUMBER,
     p_numcasasdecvenda         IN NUMBER,
     p_codplpag                 IN NUMBER,
     p_classevenda              IN pcclient.classevenda%TYPE,
     p_naousarautdebcredpoldesc IN varchar2 default 'N',
     p_usaprioritaria           IN varchar2 default 'S',
     p_tipofv                   IN pcintegradora.tipofv%type,
     p_codcondicaovenda         IN pccondicaovenda.codcondicaovenda%type,
     p_mensagem                 OUT VARCHAR2,
     p_perdesc                  OUT NUMBER,
     p_perdescfin               OUT NUMBER,
     p_basecreddebrca           OUT VARCHAR2,
     p_creditasobrepolitica     OUT VARCHAR2,
     p_alteraptabela            OUT VARCHAR2,
     p_pbaserca                 OUT NUMBER,
     p_tratarrestricaoacrescimo IN  VARCHAR2, -- 4663.087543.2014
     p_aplicaracrescimopolitica IN  VARCHAR2,
     p_qt                       IN  NUMBER,
     p_coddesconto              OUT NUMBER,   -- HIS.03080.2016
     p_codpromocaomed           OUT NUMBER,   -- HIS.03080.2016
     p_precofixo                OUT NUMBER,   -- HIS.03080.2016
     p_tipoprecodesc            OUT VARCHAR2, -- HIS.03080.2016
     p_vldesccmvpromocaomed     OUT NUMBER,   -- DDMEDICA-5009
     p_perdesccmvpromocaomed    OUT NUMBER,   -- DDMEDICA-5009
     p_numverba                 OUT NUMBER,   -- DDMEDICA-5009
     p_valorcotanumverba        OUT NUMBER,   -- DDMEDICA-5009
     p_semverbavldesccmv        OUT VARCHAR2, -- DDMEDICA-5009
     p_regraaplicacaopromocaomarkup IN  VARCHAR2, -- DDMEDICA-6837
     p_ptabela                      IN  NUMBER,   -- DDMEDICA-6837
     p_custofin                     IN  NUMBER,   -- DDMEDICA-6837
     p_iniciointervaloqt            OUT NUMBER,   -- DDMEDICA-6837
     p_percmarkup                   OUT NUMBER    -- DDMEDICA-6837
  ) RETURN BOOLEAN IS

    CURSOR c_principal(vncodepto IN NUMBER, vncodsec IN NUMBER, vncodcategoria IN NUMBER, vncodfornec IN NUMBER, vncodsupervisor IN NUMBER, vncodatv1 IN NUMBER, vncodpraca IN NUMBER, vsaplicadesconto IN VARCHAR2, vsareaatuacao IN VARCHAR2, vssimplesnacional IN varchar2,
                     vncodrede IN number , vncodmarca IN number, vncodlinhaprod IN NUMBER, vnqt IN NUMBER, vncodcliprinc IN number) IS
      SELECT case
               when (nvl(pcpromocaomed.tipopromocao,'C') = 'R') then -- DDMEDICA-6837
                 '0'
               when (nvl(pcdesconto.precofixopromocaomed,0) > 0) then
                 '1'
               else
                 '2'
             end order_tipoprecodesconto, -- HIS.03080.2016
             nvl(percdesc,0) percdesc,
             nvl(percdescfin,0) percdescfin,
             nvl(pcdesconto.basecreddebrca, 'N') basecreddebrca,
             pcdesconto.dtfim,
             nvl(pcdesconto.creditasobrepolitica, 'S') creditasobrepolitica,
             pcdesconto.dtinicio,
             pcdesconto.coddesconto,
             pcdesconto.alteraptabela,
             pcdesconto.prioritaria,
             pcdesconto.questionausoprioritaria,
             pcdesconto.prioritariageral,
             pcdesconto.codpromocaomed,      -- HIS.03080.2016
             pcdesconto.precofixopromocaomed, -- HIS.03080.2016
             pcdesconto.tipopoliticapromocaomed,
             pcdesconto.iniciointervalopromocaomed,
             pcdesconto.fimintervalopromocaomed,
             pcdesconto.vldesccmvpromocaomed, -- DDMEDICA-5009
             pcdesconto.percmarkupmed, -- DDMEDICA-6837
             CASE
               WHEN p_regraaplicacaopromocaomarkup = '1' THEN
                 nvl(pcdesconto.percmarkupmed,0) * -1
               ELSE
                 nvl(pcdesconto.percmarkupmed,0)
             END ordenacao_markup, -- DDMEDICA-6837
             pcpromocaomed.tipopromocao, -- DDMEDICA-6837
             pcpromocaomed.tipopolitica -- DDMEDICA-6837
        FROM pcdesconto
           , pcpromocaomed -- DDMEDICA-6837
       WHERE pcdesconto.codpromocaomed = pcpromocaomed.codpromocaomed(+) -- DDMEDICA-6837
         AND p_data BETWEEN pcdesconto.dtinicio AND pcdesconto.dtfim
         --AND nvl(utilizadescrede, 'N') = 'N'
         --AND ((codcli = p_codcli) OR (codcli IS NULL))
         --DDMEDICA-1733
         AND ( ((nvl(pcdesconto.utilizadescrede, 'N') = 'S') AND (codcli IN (p_codcli,vncodcliprinc))) OR
               ((nvl(pcdesconto.utilizadescrede, 'N') = 'N') AND (codcli  = p_codcli))       OR
               (codcli IS NULL) )
         AND ((codepto = vncodepto) OR (codepto IS NULL))
         AND ((codsec = vncodsec) OR (codsec IS NULL))
         AND ((codcategoria = vncodcategoria) OR (codcategoria IS NULL))
         AND ((codprod = p_codprod) OR (codprod IS NULL))
         AND ((codfornec = vncodfornec) OR (codfornec IS NULL))
         AND ((codusur = p_codusur) OR (codusur IS NULL))
         AND ((codsupervisor = vncodsupervisor) OR (codsupervisor IS NULL))
         AND ((numregiao = p_numregiao) OR (numregiao IS NULL))
         AND ((codativ = vncodatv1) OR (codativ IS NULL))
         AND ((origemped = p_origempedido) OR (nvl(origemped, 'O') = 'O'))
         AND ((codpraca = vncodpraca) OR (codpraca IS NULL))
         AND ((codprodprinc = p_codprodprinc) OR (codprodprinc IS NULL))
         AND ((codplpag = p_codplpag) OR (codplpag IS NULL))
         AND ((classevenda = p_classevenda) OR (classevenda IS NULL))
         AND (pcdesconto.aplicadesconto = 'S') --somente descontos automaticos
         AND ((pcdesconto.areaatuacao = vsareaatuacao) OR
             (pcdesconto.areaatuacao is null))
         AND ((pcdesconto.codfilial  = p_codfilial ) or (pcdesconto.codfilial is null ))
         AND ((pcdesconto.codrede  = vncodrede) or (pcdesconto.codrede is null))
         AND ((pcdesconto.codmarca  = vncodmarca) or (pcdesconto.codmarca is null))
         AND ((pcdesconto.codlinhaprod  = vncodlinhaprod) or (pcdesconto.codlinhaprod is null))
         -- DDVENDAS-39681
         AND ((EXISTS (SELECT PCDESCONTOITEM.CODDESCONTO
                     FROM PCDESCONTOITEM
                    WHERE PCDESCONTOITEM.TIPO = 'GP'
                      AND PCDESCONTOITEM.CODDESCONTO = PCDESCONTO.CODDESCONTO
                      AND PCDESCONTOITEM.VALOR_NUM IN
                          (SELECT PCGRUPOSCAMPANHAI.CODGRUPO
                             FROM PCGRUPOSCAMPANHAI
                            WHERE PCGRUPOSCAMPANHAI.CODITEM = p_codprod))) OR
              (NOT EXISTS (SELECT PCDESCONTOITEM.CODDESCONTO
                             FROM PCDESCONTOITEM
                           WHERE PCDESCONTOITEM.TIPO = 'GP'
                                 AND PCDESCONTOITEM.CODDESCONTO = PCDESCONTO.CODDESCONTO)))          
         AND (((pcdesconto.CODGRUPOREST IS NULL) OR (pcdesconto.TIPOGRUPOREST IS NULL)) OR
                ((pcdesconto.CODGRUPOREST = CASE WHEN(pcdesconto.TIPOGRUPOREST = 'GR') OR
                (pcdesconto.TIPOGRUPOREST = 'CL') OR (pcdesconto.TIPOGRUPOREST = 'GP') THEN
                (SELECT PCGRUPOSCAMPANHAI.CODGRUPO
                    FROM PCGRUPOSCAMPANHAI
                   WHERE PCGRUPOSCAMPANHAI.DTEXCLUSAO IS NULL
                      AND PCGRUPOSCAMPANHAI.CODGRUPO = PCDESCONTO.CODGRUPOREST
                     AND PCGRUPOSCAMPANHAI.CODITEM =
                         DECODE(PCDESCONTO.TIPOGRUPOREST,
                                'CL',
                                p_CodCli,
                                'GR',
                                p_CodUsur,
                                'GP',
                                p_CodProd)
                     AND ROWNUM = 1) ELSE 0 END)))         
         --//>> FICOU DENTRO DO CURSOR --// AND ((nvl(percdesc, 0)+nvl(percdescfin,0)) > 0) --somente desconto
         AND ((pcdesconto.tipofv = p_tipofv ))
         AND ((pcdesconto.codcondicaovenda = p_codcondicaovenda)or (pcdesconto.codcondicaovenda is null))
         AND case when pcdesconto.aplicadescsimplesnacional in ('S', 'N') then pcdesconto.aplicadescsimplesnacional else nvl(vssimplesnacional, 'T') end = nvl(vssimplesnacional, 'T')
         AND ((nvl(pcdesconto.iniciointervalopromocaomed,0) = 0) OR --->> PROMOÇÃO SEM INTERVALO DE QUANTIDADE
              ((nvl(pcdesconto.iniciointervalopromocaomed,0) > 0) AND (nvl(vnqt,0) between nvl(pcdesconto.iniciointervalopromocaomed,0) and nvl(pcdesconto.fimintervalopromocaomed,0)))) --->> PROMOÇÃO COM INTERVALO DE QUANTIDADE E DENTRO DA FAIXA
         AND ((nvl(pcdesconto.QTINI,0) = 0) OR --->> POLITICA SEM INTERVALO DE QUANTIDADE - MED-1554
              ((nvl(pcdesconto.QTINI,0) > 0) AND (nvl(vnqt,0) between nvl(pcdesconto.QTINI,0) and nvl(pcdesconto.QTFIM,0)))) --->> MED-1554 - POLITICA COM INTERVALO DE QUANTIDADE E DENTRO DA FAIXA
         -- Filtros relacionados à Promoção
         AND (NVL(PCPROMOCAOMED.BLOQUEIO,'N') = 'N')
       ORDER BY 1,                                          -- Primeiro Promoções de Markup, depois de Preço, depois de Desconto -- HIS.03080.2016
                ordenacao_markup,                           -- Depois da ordenação do markup                   -- DDMEDICA-6837  
                nvl(pcdesconto.precofixopromocaomed,0) ASC, -- Depois do menor Preço para o Maior Preço        -- HIS.03080.2016
                --nvl(pcdesconto.percdesc,0) DESC;
                (NVL(PCDESCONTO.PERCDESC,0) + NVL(PCDESCONTO.PERCDESCFIN,0)) DESC; -->> Do Maior Desconto para o Menor Desconto - MED-1729

    vbresult             BOOLEAN;
    vntempperdesc        NUMBER;
    vstempbasecreddebrca VARCHAR2(2);
    vnpercdesc           NUMBER;
    vsbasecreddebrca     VARCHAR2(2);

    -- HIS.03080.2016  - Variáveis para Implementação de Promoção com Preço Fixo
    vncoddesconto        NUMBER;      -- HIS.03080.2016
    vncodpromocaomed     NUMBER;      -- HIS.03080.2016
    vnprecofixo          NUMBER;      -- HIS.03080.2016
    vvtipoprecodesc      VARCHAR2(1); -- HIS.03080.2016
    vniniciointervaloqt  NUMBER;      -- DDMEDICA-6837    
    vnpercmarkup         NUMBER;      -- DDMEDICA-6837    
    
    vnvldesccmvpromocaomed  NUMBER;      -- DDMEDICA-5009
    vnperdesccmvpromocaomed NUMBER;      -- DDMEDICA-5009
    vnnumverba              NUMBER;      -- DDMEDICA-5009
    vnvalorcotanumverba     NUMBER;      -- DDMEDICA-5009
    vvsemverbavldesccmv     VARCHAR2(1); -- DDMEDICA-5009

    --Dados do Cliente
    vncodcliprinc NUMBER;
    vncodatv1     NUMBER;
    vncodpraca    NUMBER;
    --Dados do RCA
    vncodsupervisor NUMBER;
    --Dados do Produto}
    vncodfornec                NUMBER;
    vncodepto                  NUMBER;
    vncodsec                   NUMBER;
    vncodcategoria             NUMBER;
    vncodsubcategoria          NUMBER;
    vicont                     NUMBER;
    vicont2                    NUMBER;
    vicont3                    NUMBER;
    vsaplicadesconto           VARCHAR2(1);
    vscreditasobrepolitica     VARCHAR2(1);
    vstempcreditasobrepolitica VARCHAR2(1);
    vsareaatuacao              pcusuari.areaatuacao%type;
    vnpercbaserca              number;
    vntemppbaserca             number;
    vssimplesnacional          pcclient.simplesnacional%type;
    vsalteraptabela            varchar2(1);
    vstempalteraptabela        varchar2(1);
    vncodrede                  pcclient.codrede%type;
    vncodmarca                 pcprodut.codmarca%type;
    vncodlinhaprod             pcprodut.codlinhaprod%type;
    vstempprioritaria          varchar2(1);
    vsprioritaria              varchar2(1);
    vsusaprioritaria           varchar2(1);
    vnPerDescfin               number;
    vntempperdescfin           number;

    vnPercDescCompararAcresc   NUMBER;
    vntempperdescrestr         NUMBER;
    vnpercdescrestr            NUMBER;
    vstempprioritariageral     varchar2(1);

    -- DDMEDICA-6837 - Markup
    vnPrecoVendaMarkup         NUMBER;
    vbAplicouPromocaoMarkup    BOOLEAN;

  BEGIN
    vbresult                 := FALSE;
    vnpercdesc               := 0;
    vnperdescfin             := 0;
    vnpercbaserca            := 0;
    --    vnpercdesc_cr          := 0;
    vsbasecreddebrca         := 'N';
    vscreditasobrepolitica   := 'S';
    vsalteraptabela          := 'N';
    vsprioritaria            := 'N';
    vsusaprioritaria         := p_usaprioritaria;
    --
    vnpercdescrestr          := 0;
    vnPercDescCompararAcresc := 0;

    -- HIS.03080.2016 - Inicializa Variáveis da Implementação de Promoção com Preço Fixo
    vncoddesconto            := NULL; -- HIS.03080.2016
    vncodpromocaomed         := NULL; -- HIS.03080.2016
    vnprecofixo              := NULL; -- HIS.03080.2016
    vvtipoprecodesc          := NULL; -- HIS.03080.2016
    vniniciointervaloqt      := NULL; -- DDMEDICA-6837    

    -- DDMEDICA-5009 - Inicializa Valores de Verba para Rebaixa de CMV da Promoção
    vnvldesccmvpromocaomed   := NULL; -- DDMEDICA-5009
    vnperdesccmvpromocaomed  := NULL; -- DDMEDICA-5009
    vnnumverba               := NULL; -- DDMEDICA-5009
    vnvalorcotanumverba      := NULL; -- DDMEDICA-5009
    vvsemverbavldesccmv      := NULL; -- DDMEDICA-5009
    
    -- DDMEDICA-6837 - Markup
    vbAplicouPromocaoMarkup  := FALSE;
    vnpercmarkup             := NULL; -- DDMEDICA-6837    

    --Buscar dados do cliente
    SELECT COUNT(*) INTO vicont FROM pcclient WHERE codcli = p_codcli;
    
    BEGIN
      SELECT VALOR
        INTO vvAcrescimoPlPagPrecoFixoMed
        FROM PCPARAMFILIAL
       WHERE (PCPARAMFILIAL.NOME = 'ACRESCIMOPLPAGPRECOFIXOMED')
         AND (PCPARAMFILIAL.CODFILIAL = pi_sCodFilial);
    EXCEPTION
      WHEN OTHERS THEN
        vvAcrescimoPlPagPrecoFixoMed := 'N';
    END;
    
    BEGIN
      SELECT PERTXFIM
        INTO vnPerTxFim
        FROM PCPLPAG
       WHERE (CODPLPAG = p_codplpag);
    EXCEPTION
      WHEN OTHERS THEN
        vnPerTxFim := 0;
    END;
    
    IF vicont <> 0 THEN
      SELECT nvl(codcliprinc, codcli) codcliprinc,
             codatv1,
             codpraca,
             pcclient.simplesnacional,
             pcclient.codrede
        INTO vncodcliprinc, vncodatv1, vncodpraca, vssimplesnacional,vncodrede
        FROM pcclient
       WHERE codcli = p_codcli;

      --Buscar dados do RCA
      SELECT COUNT(*) INTO vicont2 FROM pcusuari WHERE codusur = p_codusur;
      IF vicont2 <> 0 THEN
        SELECT codsupervisor, pcusuari.areaatuacao
          INTO vncodsupervisor, vsareaatuacao
          FROM pcusuari
         WHERE codusur = p_codusur;

        --Buscar dados do produto
        SELECT COUNT(*)
          INTO vicont3
          FROM pcprodut
         WHERE codprod = p_codprod;

        IF vicont3 <> 0 THEN
          SELECT codfornec, codepto, codsec, codcategoria, codsubcategoria,codmarca,codlinhaprod
            INTO vncodfornec,
                 vncodepto,
                 vncodsec,
                 vncodcategoria,
                 vncodsubcategoria,
                 vncodmarca,
                 vncodlinhaprod
            FROM pcprodut
           WHERE codprod = p_codprod;

         /***************
          ** DESCONTOS **
          ***************/

          --------------------------------------------------
          --Verificação de Políticas de Descontos - SEM REDE
          --------------------------------------------------
          FOR reg_pdescontos IN c_principal(vncodepto,
                                       vncodsec,
                                       vncodcategoria,
                                       vncodfornec,
                                       vncodsupervisor,
                                       vncodatv1,
                                       vncodpraca,
                                       vsaplicadesconto,
                                       vsareaatuacao,
                                       vssimplesnacional,
                                       vncodrede,
                                       vncodmarca,
                                       vncodlinhaprod,
                                       p_qt,
                                       vncodcliprinc) LOOP

           -- Se Promoção, verificar se Pode Comprar Promoção
           IF (NVL(reg_pdescontos.codpromocaomed,0) = 0) OR
              ((NVL(reg_pdescontos.codpromocaomed,0) > 0) AND (PKG_FUNCOESVENDAS_MED.F_PODECOMPRARPROMOCAO(reg_pdescontos.codpromocaomed,
                                                                                                           p_codfilial,
                                                                                                           p_codcli, -- Aqui não pode passar o Principal - DDMEDICA-2858
                                                                                                           p_numregiao,
                                                                                                           p_codusur,
                                                                                                           p_codplpag,
                                                                                                           p_codcondicaovenda,
                                                                                                           p_origempedido,
                                                                                                           p_tipofv,
                                                                                                           p_data) = 'S')) THEN
                
             -- Procedimento para Inserir na Tabela Temporária
             P_INSERE_TABTEMP(reg_pdescontos.CODPROMOCAOMED,
                              reg_pdescontos.CODDESCONTO,
                              reg_pdescontos.TIPOPOLITICAPROMOCAOMED,
                              reg_pdescontos.INICIOINTERVALOPROMOCAOMED,
                              reg_pdescontos.FIMINTERVALOPROMOCAOMED,
                              NVL(reg_pdescontos.PRECOFIXOPROMOCAOMED,0),
                              reg_pdescontos.PERCDESC,
                              reg_pdescontos.PERCDESCFIN,
                              '1',
                              NULL);

             -- Se for Promoção - HIS.03080.2016
             IF (nvl(reg_pdescontos.codpromocaomed,0) > 0) THEN

               vbresult               := TRUE;

               vnpercdesc             := reg_pdescontos.percdesc;
               vnperdescfin           := reg_pdescontos.percdescfin;
               vsprioritaria          := reg_pdescontos.prioritaria;
               vsalteraptabela        := reg_pdescontos.alteraptabela;

               p_mensagem             := to_char(reg_pdescontos.dtinicio,
                                                 'dd/mm/yyyy') || ',' ||
                                                 reg_pdescontos.coddesconto;

               vsbasecreddebrca       := reg_pdescontos.basecreddebrca;
               vnpercbaserca          := reg_pdescontos.percdesc;
               vscreditasobrepolitica := reg_pdescontos.creditasobrepolitica;

               -- HIS.03080.2016  - Variáveis da Implementação de Promoção com Preço Fixo
               vncoddesconto          := reg_pdescontos.coddesconto;          -- HIS.03080.2016
               vncodpromocaomed       := reg_pdescontos.codpromocaomed;       -- HIS.03080.2016
               
               IF (reg_pdescontos.tipopolitica = 'P' OR reg_pdescontos.tipopolitica = 'F') AND (vvAcrescimoPlPagPrecoFixoMed = 'S') THEN
                 vnprecofixo            := reg_pdescontos.precofixopromocaomed * (1 + vnPerTxFim / 100);
               ELSE
                 vnprecofixo            := reg_pdescontos.precofixopromocaomed; -- HIS.03080.2016
               END IF;
               
               IF (NVL(reg_pdescontos.precofixopromocaomed,0) > 0) THEN
                 vvtipoprecodesc      := 'P'; -- HIS.03080.2016
               ELSE
                 vvtipoprecodesc      := 'D'; -- HIS.03080.2016
               END IF;
               vniniciointervaloqt    := reg_pdescontos.iniciointervalopromocaomed; -- DDMEDICA-6837    
               
               -------------------------------------
               -- Promoção de Markup - DDMEDICA-6837
               -------------------------------------
               IF (reg_pdescontos.tipopromocao = 'R') THEN
                 -- Calcula Desconto
                 IF ((NVL(p_custofin,0) = 0) OR
                     (NVL(p_ptabela,0)  = 0)) THEN
                   -- Não carregar desconto da promoção markup com custo zero
                   vnpercdesc               := 0;
                 ELSE
                   vnPrecoVendaMarkup       := NVL(p_custofin,0) * (1+(NVL(reg_pdescontos.PERCMARKUPMED,0) * 0.01));
                   vnpercdesc               := (1-(vnPrecoVendaMarkup/NVL(p_ptabela,0)))*100;
                 END IF;
                 vnperdescfin               := reg_pdescontos.percdescfin;
                 vvtipoprecodesc            := 'D';
                 vnprecofixo                := 0;
                 -- Promoção de Markup com Preço Fixo com ou sem faixa de quantidade
                 IF (reg_pdescontos.TIPOPOLITICA IN ('P','F')) THEN
                   IF (NVL(vnPercDesc,0) = 0) THEN
                     vnprecofixo := NVL(p_ptabela,0);
                   ELSE                         
                     vnprecofixo := NVL(vnPrecoVendaMarkup,0);
                   END IF;
                   -- Altera Preço Tabela
                   vvtipoprecodesc := 'P';
                   vsalteraptabela := 'S'; 
                   -- Não tem desconto (já vai aplicado no Preço Fixo)
                   vnPercDesc := 0;
                 END IF;      
                 -- DDMEDICA-6837 - Markup
                 vbAplicouPromocaoMarkup := TRUE;                         
                 -- DDMEDICA-6837 - Markup de Retorno da Procedure
                 vnpercmarkup            := reg_pdescontos.PERCMARKUPMED; 
               END IF; -- Fim Condição: Promoção de Markup
               
               -- Inicializando Variável com o Valor da Verba para Rebaixa de CMV da Promoção da PCDESCONTO - DDMEDICA-5009
               vnvldesccmvpromocaomed := reg_pdescontos.VLDESCCMVPROMOCAOMED;               
               -- Obter Verba Relacionada com o Valor da Verba para Rebaixa de CMV da Promoção da PCDESCONTO - DDMEDICA-5009
               PKG_PROMOCAO_MED.P_OBTER_VERBA_PROMOCAO(reg_pdescontos.codpromocaomed,
                                                       vncodfornec,
                                                       vnvldesccmvpromocaomed,
                                                       vnnumverba,
                                                       vnvalorcotanumverba,
                                                       vvsemverbavldesccmv);
               
               -- Se for para gerar Log - DDMEDICA-2858
               IF (NVL(pi_vGravaTabTemp,'N') = 'S') THEN               
                 IF (vnCodPromocaoSelTabTemp IS NULL) THEN
                   vnCodDescontoSelTabTemp := vncoddesconto;
                   vnCodPromocaoSelTabTemp := vncodpromocaomed;
                 END IF;
               -- Se não for para gerar Log - DDMEDICA-2858
               ELSE
                 EXIT; -->> Se usar Promoção, sai no registro que encontrar
               END IF;

             -- Se não for Promoção
             ELSE

               -- Se Desconto
               IF ((nvl(reg_pdescontos.percdesc, 0)+nvl(reg_pdescontos.percdescfin,0)) > 0) THEN

                  vbresult                   := TRUE;
                  vntempperdesc              := reg_pdescontos.percdesc;
                  vntempperdescfin           := reg_pdescontos.percdescfin;
                  vntemppbaserca             := reg_pdescontos.percdesc;
                  vstempbasecreddebrca       := reg_pdescontos.basecreddebrca;
                  vstempcreditasobrepolitica := reg_pdescontos.creditasobrepolitica;
                  vstempalteraptabela        := reg_pdescontos.alteraptabela;
                  vstempprioritaria          := reg_pdescontos.prioritaria;

                  if vsprioritaria = 'N' then

                    if vstempprioritaria = 'S' then
                      --registro atual é de politica prioritaria

                      if vsusaprioritaria = 'S' then

                        vnpercdesc             := vntempperdesc;
                        vnperdescfin           := vntempperdescfin;
                        vsprioritaria          := vstempprioritaria;
                        vsalteraptabela        := vstempalteraptabela;

                        p_mensagem := to_char(reg_pdescontos.dtinicio,
                                              'dd/mm/yyyy') || ',' ||
                                      reg_pdescontos.coddesconto;
                        vncoddesconto  := reg_pdescontos.coddesconto; -- MED-1554

                    			if p_naousarautdebcredpoldesc = 'S' and vstempbasecreddebrca = 'S' then

                    			    vsbasecreddebrca       := vstempbasecreddebrca;
                    			    vnpercbaserca          := vntemppbaserca;
                    			    vscreditasobrepolitica := vstempcreditasobrepolitica;

                      		end if;

                      end if;

                    else
                      --registro atual não é de politica prioritaria

                      IF (vntempperdesc + vntempperdescfin) > (vnpercdesc + vnPerDescfin) THEN

                            vnpercdesc := vntempperdesc;
                            vnPerDescfin := vntempperdescfin;
                            vsprioritaria          := 'N';

                            vsalteraptabela        := vstempalteraptabela;

                            p_mensagem := to_char(reg_pdescontos.dtinicio,
                                                  'dd/mm/yyyy') || ',' ||
                                          reg_pdescontos.coddesconto;
                            vncoddesconto  := reg_pdescontos.coddesconto; -- MED-1554


                    			if p_naousarautdebcredpoldesc = 'S' and vstempbasecreddebrca = 'S' then

                    			    vsbasecreddebrca       := vstempbasecreddebrca;
                    			    vnpercbaserca          := vntemppbaserca;
                    			    vscreditasobrepolitica := vstempcreditasobrepolitica;

                       		end if;



                      END IF;

                			if p_naousarautdebcredpoldesc = 'S' and vstempbasecreddebrca = 'S' and
                			   vntemppbaserca > vnpercbaserca then

                			    vsbasecreddebrca       := vstempbasecreddebrca;
                			    vnpercbaserca          := vntemppbaserca;
                			    vscreditasobrepolitica := vstempcreditasobrepolitica;

                         		end if;

                    end if;

                  else
                    -- já tem uma politica prioritaria

                          IF (vntempperdesc + vntempperdescfin) > (vnpercdesc + vnPerDescfin) THEN

                            vnpercdesc             := vntempperdesc;
                            vnperdescfin           := vntempperdescfin;
                            vsprioritaria          := vstempprioritaria;
                            vsalteraptabela        := vstempalteraptabela;

                            p_mensagem := to_char(reg_pdescontos.dtinicio, 'dd/mm/yyyy') || ',' ||
                                          reg_pdescontos.coddesconto;
                            vncoddesconto  := reg_pdescontos.coddesconto; -- MED-1554

                    		      if p_naousarautdebcredpoldesc = 'S' and vstempbasecreddebrca = 'S' then

                    			    vsbasecreddebrca       := vstempbasecreddebrca;
                    			    vnpercbaserca          := vntemppbaserca;
                    			    vscreditasobrepolitica := vstempcreditasobrepolitica;

                             		end if;


                          END IF;

                  end if;

               END IF; -- Fim Condição Se Desconto

             END IF; -- Fim Condição Se Promoção

           END IF; -- Fim Condição: Se Promoção, verificar se Pode Comprar Promoção
          END LOOP; -- reg_pdescontos

         /***********************************
          ** ACRESCIMOS - 4663.087543.2014 **
          ***********************************/
          -- Se não aplicou a Promoção de Markup - DDMEDICA-6837
          IF (NOT vbAplicouPromocaoMarkup) THEN
            IF (p_tratarrestricaoacrescimo = 'S') AND
               (p_aplicaracrescimopolitica = 'S') THEN
  
              -- Percentual de Desconto encontrado no processamento anterior para comparar com o Acréscimo
              vnPercDescCompararAcresc := NVL(vnpercdesc,0);
  
              ---------------------------------------------------
              --Verificação de Políticas de Acréscimos - SEM REDE
              ---------------------------------------------------
              FOR reg_pdescontos IN c_principal(vncodepto,
                                           vncodsec,
                                           vncodcategoria,
                                           vncodfornec,
                                           vncodsupervisor,
                                           vncodatv1,
                                           vncodpraca,
                                           vsaplicadesconto,
                                           vsareaatuacao,
                                           vssimplesnacional,
                                           vncodrede,
                                           vncodmarca,
                                           vncodlinhaprod,
                                           p_qt,
                                           vncodcliprinc) LOOP
                                           
               -- Se Promoção, verificar se Pode Comprar Promoção
               IF (NVL(reg_pdescontos.codpromocaomed,0) = 0) OR
                  ((NVL(reg_pdescontos.codpromocaomed,0) > 0) AND (PKG_FUNCOESVENDAS_MED.F_PODECOMPRARPROMOCAO(reg_pdescontos.codpromocaomed,
                                                                                                               p_codfilial,
                                                                                                               p_codcli, -- Aqui não pode passar o Principal - DDMEDICA-2858
                                                                                                               p_numregiao,
                                                                                                               p_codusur,
                                                                                                               p_codplpag,
                                                                                                               p_codcondicaovenda,
                                                                                                               p_origempedido,
                                                                                                               p_tipofv,
                                                                                                               p_data) = 'S')) THEN
               -- Se Acréscimo
               IF (nvl(reg_pdescontos.percdesc, 0) < 0) THEN
  
                  vntempperdescrestr         := reg_pdescontos.percdesc;
                  vntemppbaserca             := reg_pdescontos.percdesc;
                  vstempbasecreddebrca       := reg_pdescontos.basecreddebrca;
                  vstempcreditasobrepolitica := reg_pdescontos.creditasobrepolitica;
                  vstempalteraptabela        := reg_pdescontos.alteraptabela;
                  vstempprioritaria          := reg_pdescontos.prioritaria;
                  vstempprioritariageral     := reg_pdescontos.prioritariageral;
  
                  if vsprioritaria = 'N' then
  
                    if vstempprioritaria = 'S' then
                      --registro atual é de politica prioritaria
  
                      if (vsusaprioritaria = 'S') and
                         ((nvl(vnPercDescCompararAcresc,0) = 0) or                                         --//>> Condição da 2316 - Tarefa 97059 - somente conceder Acréscimo se achar desconto
                          ((nvl(vnPercDescCompararAcresc,0) > 0) and (vstempprioritariageral = 'S'))) THEN --//>> Condição da 2316 - Prioritária Geral - neste caso concede sempre
  
  
                        vbresult               := TRUE;
                        vnpercdescrestr        := vntempperdescrestr;
                        vsprioritaria          := vstempprioritaria;
                        vsalteraptabela        := vstempalteraptabela;
  
                        p_mensagem := to_char(reg_pdescontos.dtinicio,
                                              'dd/mm/yyyy') || ',' ||
                                      reg_pdescontos.coddesconto;
                        vncoddesconto  := reg_pdescontos.coddesconto; -- MED-1554
  
                    			if p_naousarautdebcredpoldesc = 'S' and vstempbasecreddebrca = 'S' then
  
                    			    vsbasecreddebrca       := vstempbasecreddebrca;
                    			    vnpercbaserca          := vntemppbaserca;
                    			    vscreditasobrepolitica := vstempcreditasobrepolitica;
  
                      		end if;
  
                      end if;
  
                    else
                      --registro atual não é de politica prioritaria
  
                      IF (vntempperdescrestr < vnpercdescrestr) AND
                         ((nvl(vnPercDescCompararAcresc,0) = 0) OR                                         --//>> Condição da 2316 - Tarefa 97059 - somente conceder Acréscimo se achar desconto
                          ((nvl(vnPercDescCompararAcresc,0) > 0) AND (vstempprioritariageral = 'S'))) THEN --//>> Condição da 2316 - Prioritária Geral - neste caso concede sempre
  
                            vbresult               := TRUE;
                            vnpercdescrestr        := vntempperdescrestr;
                            vsprioritaria          := 'N';
  
                            vsalteraptabela        := vstempalteraptabela;
  
                            p_mensagem := to_char(reg_pdescontos.dtinicio,
                                                  'dd/mm/yyyy') || ',' ||
                                          reg_pdescontos.coddesconto;
                            vncoddesconto  := reg_pdescontos.coddesconto; -- MED-1554
  
  
                    			if p_naousarautdebcredpoldesc = 'S' and vstempbasecreddebrca = 'S' then
  
                    			    vsbasecreddebrca       := vstempbasecreddebrca;
                    			    vnpercbaserca          := vntemppbaserca;
                    			    vscreditasobrepolitica := vstempcreditasobrepolitica;
  
                       		end if;
  
  
  
                      END IF;
  
                			if p_naousarautdebcredpoldesc = 'S' and vstempbasecreddebrca = 'S' and
                			   vntemppbaserca > vnpercbaserca then
  
                			    vsbasecreddebrca       := vstempbasecreddebrca;
                			    vnpercbaserca          := vntemppbaserca;
                			    vscreditasobrepolitica := vstempcreditasobrepolitica;
  
                      end if;
  
                    end if;
  
                  else
                    -- já tem uma politica prioritaria
  
                          IF (vntempperdescrestr < vnpercdescrestr) AND
                             ((nvl(vnPercDescCompararAcresc,0) = 0) OR                                         --//>> Condição da 2316 - Tarefa 97059 - somente conceder Acréscimo se achar desconto
                              ((nvl(vnPercDescCompararAcresc,0) > 0) AND (vstempprioritariageral = 'S'))) THEN --//>> Condição da 2316 - Prioritária Geral - neste caso concede sempre
  
                            vbresult               := TRUE;
                            vnpercdescrestr        := vntempperdescrestr;
                            vsprioritaria          := vstempprioritaria;
                            vsalteraptabela        := vstempalteraptabela;
  
                            p_mensagem := to_char(reg_pdescontos.dtinicio, 'dd/mm/yyyy') || ',' ||
                                          reg_pdescontos.coddesconto;
                            vncoddesconto  := reg_pdescontos.coddesconto; -- MED-1554
  
                    		      if p_naousarautdebcredpoldesc = 'S' and vstempbasecreddebrca = 'S' then
  
                    			    vsbasecreddebrca       := vstempbasecreddebrca;
                    			    vnpercbaserca          := vntemppbaserca;
                    			    vscreditasobrepolitica := vstempcreditasobrepolitica;
  
                             		end if;
  
  
                          END IF;
  
                  end if;
  
               END IF; -- Fim Condição Se Acréscimo
               END IF; -- Fim Condição: Se Promoção, verificar se Pode Comprar Promoção
              END LOOP; -- reg_pdescontos
  
              --------------------------------------------------
              --Verificação de Políticas de Acréscimo - COM REDE
              --------------------------------------------------
  
            END IF; -- Fim Condição ACRESCIMOS - 4663.087543.2014
          END IF; -- Fim Condição não usar ACRESCIMOS se Aplicou Promoção de Markup - DDMEDICA-6837

        ELSE
          p_mensagem := 'Não foi possível buscar dados do PCPRODUT!';
        END IF;
      ELSE
        p_mensagem := 'Não foi possível buscar dados do PCUSUARI!';
      END IF; --dados do PCCLIENT
    ELSE
      p_mensagem := 'Não foi possível buscar dados do PCCLIENT!';
    END IF;

    -- SE TEM ACRÉSCIMO VÁLIDO - 4663.087543.2014
    IF (NVL(vnpercdescrestr,0) <> 0) THEN
      vnpercdesc := NVL(vnpercdescrestr,0);

      -- HIS.03080.2016 - Desconsidera o Preço Fixo -- HIS.03080.2016
      vncoddesconto           := NULL; -- HIS.03080.2016
      vncodpromocaomed        := NULL; -- HIS.03080.2016
      vnprecofixo             := NULL; -- HIS.03080.2016
      vvtipoprecodesc         := NULL; -- HIS.03080.2016
      vniniciointervaloqt     := NULL; -- DDMEDICA-6837    
      -- DDMEDICA-5009 - Desconsidera Verba para Rebaixa de CMV da Promoção da PCDESCONTO - 
      vnvldesccmvpromocaomed  := NULL; -- DDMEDICA-5009
      vnperdesccmvpromocaomed := NULL; -- DDMEDICA-5009
      vnnumverba              := NULL; -- DDMEDICA-5009
      vnvalorcotanumverba     := NULL; -- DDMEDICA-5009
      vvsemverbavldesccmv     := NULL; -- DDMEDICA-5009

    END IF;

    p_perdesc               := round(vnpercdesc, p_numcasasdecvenda);
    p_perdescfin            := round(vnPerDescfin,p_numcasasdecvenda);
    p_basecreddebrca        := vsbasecreddebrca;
    p_creditasobrepolitica  := vscreditasobrepolitica;
    p_pbaserca              := round(vnpercbaserca, p_numcasasdecvenda);
    p_alteraptabela         := vsalteraptabela;

    -- HIS.03080.2016  - Variáveis de Retorno de Promoção de Preço Fixo -- HIS.03080.2016
    p_coddesconto           := vncoddesconto;       -- HIS.03080.2016
    p_codpromocaomed        := vncodpromocaomed;    -- HIS.03080.2016
    p_precofixo             := vnprecofixo;         -- HIS.03080.2016
    p_tipoprecodesc         := vvtipoprecodesc;     -- HIS.03080.2016
    p_iniciointervaloqt     := vniniciointervaloqt; -- DDMEDICA-6837
    p_percmarkup            := vnpercmarkup;        -- DDMEDICA-6837

    -- DDMEDICA-5009 - Valores da Verba para Rebaixa de CMV da Promoção da PCDESCONTO - 
    p_vldesccmvpromocaomed  := vnvldesccmvpromocaomed;  -- DDMEDICA-5009
    p_perdesccmvpromocaomed := vnperdesccmvpromocaomed; -- DDMEDICA-5009
    p_numverba              := vnnumverba;             -- DDMEDICA-5009
    p_valorcotanumverba     := vnvalorcotanumverba;    -- DDMEDICA-5009     
    p_semverbavldesccmv     := vvsemverbavldesccmv;    -- DDMEDICA-5009     

    RETURN vbresult;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Politica de Descontos: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END FUNCAO_OBTEM_DESC_POLITICA;

  -- DDMEDICA-706 - Pesquisa Otimizada pela Condição de Venda
  FUNCTION FUNCAO_OBTEM_DESC_POLITICA_CV
    (p_codprod                  IN NUMBER,
     p_data                     IN DATE,
     p_codfilial                IN VARCHAR2,
     p_numregiao                IN NUMBER,
     p_codcli                   IN NUMBER,
     p_codusur                  IN NUMBER,
     p_origempedido             IN VARCHAR2,
     p_codprodprinc             IN NUMBER,
     p_numcasasdecvenda         IN NUMBER,
     p_codplpag                 IN NUMBER,
     p_classevenda              IN pcclient.classevenda%TYPE,
     p_naousarautdebcredpoldesc IN varchar2 default 'N',
     p_usaprioritaria           IN varchar2 default 'S',
     p_tipofv                   IN pcintegradora.tipofv%type,
     p_codcondicaovenda         IN pccondicaovenda.codcondicaovenda%type,
     p_mensagem                 OUT VARCHAR2,
     p_perdesc                  OUT NUMBER,
     p_perdescfin               OUT NUMBER,
     p_basecreddebrca           OUT VARCHAR2,
     p_creditasobrepolitica     OUT VARCHAR2,
     p_alteraptabela            OUT VARCHAR2,
     p_pbaserca                 OUT NUMBER,
     p_tratarrestricaoacrescimo IN  VARCHAR2, -- 4663.087543.2014
     p_aplicaracrescimopolitica IN  VARCHAR2,
     p_qt                       IN  NUMBER,
     p_coddesconto              OUT NUMBER,   -- HIS.03080.2016
     p_codpromocaomed           OUT NUMBER,   -- HIS.03080.2016
     p_precofixo                OUT NUMBER,   -- HIS.03080.2016
     p_tipoprecodesc            OUT VARCHAR2, -- HIS.03080.2016
     p_vldesccmvpromocaomed     OUT NUMBER,   -- DDMEDICA-5009
     p_perdesccmvpromocaomed    OUT NUMBER,   -- DDMEDICA-5009
     p_numverba                 OUT NUMBER,   -- DDMEDICA-5009
     p_valorcotanumverba        OUT NUMBER,   -- DDMEDICA-5009     
     p_semverbavldesccmv        OUT VARCHAR2, -- DDMEDICA-5009          
     p_regraaplicacaopromocaomarkup IN  VARCHAR2, -- DDMEDICA-6837
     p_ptabela                      IN  NUMBER,   -- DDMEDICA-6837
     p_custofin                     IN  NUMBER,   -- DDMEDICA-6837
     p_iniciointervaloqt            OUT NUMBER,   -- DDMEDICA-6837
     p_percmarkup                   OUT NUMBER    -- DDMEDICA-6837
  ) RETURN BOOLEAN IS

    CURSOR c_principal(vncodepto IN NUMBER, vncodsec IN NUMBER, vncodcategoria IN NUMBER, vncodfornec IN NUMBER, vncodsupervisor IN NUMBER, vncodatv1 IN NUMBER, vncodpraca IN NUMBER, vsaplicadesconto IN VARCHAR2, vsareaatuacao IN VARCHAR2, vssimplesnacional IN varchar2,
                     vncodrede IN number , vncodmarca IN number, vncodlinhaprod IN NUMBER, vnqt IN NUMBER, vncodcliprinc IN number) IS
      SELECT case
               when (nvl(pcpromocaomed.tipopromocao,'C') = 'R') then -- DDMEDICA-6837
                 '0'
               when (nvl(pcdesconto.precofixopromocaomed,0) > 0) then
                 '1'
               else
                 '2'
             end order_tipoprecodesconto, -- HIS.03080.2016
             nvl(pcdesconto.precofixopromocaomed,0) as coluna_order2,
             (NVL(PCDESCONTO.PERCDESC,0) + NVL(PCDESCONTO.PERCDESCFIN,0)) as coluna_order3,
             nvl(percdesc,0) percdesc,
             nvl(percdescfin,0) percdescfin,
             nvl(pcdesconto.basecreddebrca, 'N') basecreddebrca,
             pcdesconto.dtfim,
             nvl(pcdesconto.creditasobrepolitica, 'S') creditasobrepolitica,
             pcdesconto.dtinicio,
             pcdesconto.coddesconto,
             pcdesconto.alteraptabela,
             pcdesconto.prioritaria,
             pcdesconto.questionausoprioritaria,
             pcdesconto.prioritariageral,
             pcdesconto.codpromocaomed,      -- HIS.03080.2016
             pcdesconto.precofixopromocaomed, -- HIS.03080.2016
             pcdesconto.tipopoliticapromocaomed,
             pcdesconto.iniciointervalopromocaomed,
             pcdesconto.fimintervalopromocaomed,
             pcdesconto.vldesccmvpromocaomed, -- DDMEDICA-5009
             pcdesconto.percmarkupmed, -- DDMEDICA-6837
             CASE
               WHEN p_regraaplicacaopromocaomarkup = '1' THEN
                 nvl(pcdesconto.percmarkupmed,0) * -1
               ELSE
                 nvl(pcdesconto.percmarkupmed,0)
             END ordenacao_markup, -- DDMEDICA-6837
             pcpromocaomed.tipopromocao, -- DDMEDICA-6837
             pcpromocaomed.tipopolitica -- DDMEDICA-6837
         FROM pcdesconto
           , pcpromocaomed -- DDMEDICA-6837
       WHERE pcdesconto.codpromocaomed = pcpromocaomed.codpromocaomed(+) -- DDMEDICA-6837
         AND p_data BETWEEN pcdesconto.dtinicio AND pcdesconto.dtfim
         --AND nvl(utilizadescrede, 'N') = 'N'
         --AND ((codcli = p_codcli) OR (codcli IS NULL))
         --DDMEDICA-1733
         AND ( ((nvl(pcdesconto.utilizadescrede, 'N') = 'S') AND (codcli IN (p_codcli,vncodcliprinc))) OR
               ((nvl(pcdesconto.utilizadescrede, 'N') = 'N') AND (codcli  = p_codcli))       OR
               (codcli IS NULL) )
         AND ((codepto = vncodepto) OR (codepto IS NULL))
         AND ((codsec = vncodsec) OR (codsec IS NULL))
         AND ((codcategoria = vncodcategoria) OR (codcategoria IS NULL))
         AND ((codprod = p_codprod) OR (codprod IS NULL))
         AND ((codfornec = vncodfornec) OR (codfornec IS NULL))
         AND ((codusur = p_codusur) OR (codusur IS NULL))
         AND ((codsupervisor = vncodsupervisor) OR (codsupervisor IS NULL))
         AND ((numregiao = p_numregiao) OR (numregiao IS NULL))
         AND ((codativ = vncodatv1) OR (codativ IS NULL))
         AND ((origemped = p_origempedido) OR (nvl(origemped, 'O') = 'O'))
         AND ((codpraca = vncodpraca) OR (codpraca IS NULL))
         AND ((codprodprinc = p_codprodprinc) OR (codprodprinc IS NULL))
         AND ((codplpag = p_codplpag) OR (codplpag IS NULL))
         AND ((classevenda = p_classevenda) OR (classevenda IS NULL))
         AND (pcdesconto.aplicadesconto = 'S') --somente descontos automaticos
         AND ((pcdesconto.areaatuacao = vsareaatuacao) OR
             (pcdesconto.areaatuacao is null))
         AND ((pcdesconto.codfilial  = p_codfilial ) or (pcdesconto.codfilial is null ))
         AND ((pcdesconto.codrede  = vncodrede) or (pcdesconto.codrede is null))
         AND ((pcdesconto.codmarca  = vncodmarca) or (pcdesconto.codmarca is null))
         AND ((pcdesconto.codlinhaprod  = vncodlinhaprod) or (pcdesconto.codlinhaprod is null))
         -- DDVENDAS-39681
         AND ((EXISTS (SELECT PCDESCONTOITEM.CODDESCONTO
                     FROM PCDESCONTOITEM
                    WHERE PCDESCONTOITEM.TIPO = 'GP'
                      AND PCDESCONTOITEM.CODDESCONTO = PCDESCONTO.CODDESCONTO
                      AND PCDESCONTOITEM.VALOR_NUM IN
                          (SELECT PCGRUPOSCAMPANHAI.CODGRUPO
                             FROM PCGRUPOSCAMPANHAI
                            WHERE PCGRUPOSCAMPANHAI.CODITEM = p_codprod))) OR
              (NOT EXISTS (SELECT PCDESCONTOITEM.CODDESCONTO
                             FROM PCDESCONTOITEM
                           WHERE PCDESCONTOITEM.TIPO = 'GP'
                                 AND PCDESCONTOITEM.CODDESCONTO = PCDESCONTO.CODDESCONTO)))          
         AND (((pcdesconto.CODGRUPOREST IS NULL) OR (pcdesconto.TIPOGRUPOREST IS NULL)) OR
                ((pcdesconto.CODGRUPOREST = CASE WHEN(pcdesconto.TIPOGRUPOREST = 'GR') OR
                (pcdesconto.TIPOGRUPOREST = 'CL') OR (pcdesconto.TIPOGRUPOREST = 'GP') THEN
                (SELECT PCGRUPOSCAMPANHAI.CODGRUPO
                    FROM PCGRUPOSCAMPANHAI
                   WHERE PCGRUPOSCAMPANHAI.DTEXCLUSAO IS NULL
                      AND PCGRUPOSCAMPANHAI.CODGRUPO = PCDESCONTO.CODGRUPOREST
                     AND PCGRUPOSCAMPANHAI.CODITEM =
                         DECODE(PCDESCONTO.TIPOGRUPOREST,
                                'CL',
                                p_CodCli,
                                'GR',
                                p_CodUsur,
                                'GP',
                                p_CodProd)
                     AND ROWNUM = 1) ELSE 0 END)))         
         --//>> FICOU DENTRO DO CURSOR --// AND ((nvl(percdesc, 0)+nvl(percdescfin,0)) > 0) --somente desconto
         AND ((pcdesconto.tipofv = p_tipofv ))
         AND ((pcdesconto.codcondicaovenda = p_codcondicaovenda)) -->> PESQUISA DIRETA PELA CONDIÇÃO DE VENDA
         AND case when pcdesconto.aplicadescsimplesnacional in ('S', 'N') then pcdesconto.aplicadescsimplesnacional else nvl(vssimplesnacional, 'T') end = nvl(vssimplesnacional, 'T')
         AND ((nvl(pcdesconto.iniciointervalopromocaomed,0) = 0) OR --->> PROMOÇÃO SEM INTERVALO DE QUANTIDADE
              ((nvl(pcdesconto.iniciointervalopromocaomed,0) > 0) AND (nvl(vnqt,0) between nvl(pcdesconto.iniciointervalopromocaomed,0) and nvl(pcdesconto.fimintervalopromocaomed,0)))) --->> PROMOÇÃO COM INTERVALO DE QUANTIDADE E DENTRO DA FAIXA
         AND ((nvl(pcdesconto.QTINI,0) = 0) OR --->> POLITICA SEM INTERVALO DE QUANTIDADE - MED-1554
              ((nvl(pcdesconto.QTINI,0) > 0) AND (nvl(vnqt,0) between nvl(pcdesconto.QTINI,0) and nvl(pcdesconto.QTFIM,0)))) --->> MED-1554 - POLITICA COM INTERVALO DE QUANTIDADE E DENTRO DA FAIXA
         -- Filtros relacionados à Promoção
         AND (NVL(PCPROMOCAOMED.BLOQUEIO,'N') = 'N')
      UNION
      SELECT case
               when (nvl(pcpromocaomed.tipopromocao,'C') = 'R') then -- DDMEDICA-6837
                 '0'
               when (nvl(pcdesconto.precofixopromocaomed,0) > 0) then
                 '1'
               else
                 '2'
             end order_tipoprecodesconto, -- HIS.03080.2016
             nvl(pcdesconto.precofixopromocaomed,0) as coluna_order2,
             (NVL(PCDESCONTO.PERCDESC,0) + NVL(PCDESCONTO.PERCDESCFIN,0)) as coluna_order3,
             nvl(percdesc,0) percdesc,
             nvl(percdescfin,0) percdescfin,
             nvl(pcdesconto.basecreddebrca, 'N') basecreddebrca,
             pcdesconto.dtfim,
             nvl(pcdesconto.creditasobrepolitica, 'S') creditasobrepolitica,
             pcdesconto.dtinicio,
             pcdesconto.coddesconto,
             pcdesconto.alteraptabela,
             pcdesconto.prioritaria,
             pcdesconto.questionausoprioritaria,
             pcdesconto.prioritariageral,
             pcdesconto.codpromocaomed,      -- HIS.03080.2016
             pcdesconto.precofixopromocaomed, -- HIS.03080.2016
             pcdesconto.tipopoliticapromocaomed,
             pcdesconto.iniciointervalopromocaomed,
             pcdesconto.fimintervalopromocaomed,
             pcdesconto.vldesccmvpromocaomed, -- DDMEDICA-5009
             pcdesconto.percmarkupmed, -- DDMEDICA-6837
             CASE
               WHEN p_regraaplicacaopromocaomarkup = '1' THEN
                 nvl(pcdesconto.percmarkupmed,0) * -1
               ELSE
                 nvl(pcdesconto.percmarkupmed,0)
             END ordenacao_markup, -- DDMEDICA-6837
             pcpromocaomed.tipopromocao, -- DDMEDICA-6837
             pcpromocaomed.tipopolitica -- DDMEDICA-6837
        FROM pcdesconto, pcpromocaocondvendamed
           , pcpromocaomed -- DDMEDICA-6837
       WHERE pcdesconto.codpromocaomed = pcpromocaomed.codpromocaomed(+) -- DDMEDICA-6837
         AND pcdesconto.codpromocaomed = pcpromocaocondvendamed.codpromocaomed
         AND p_data BETWEEN pcdesconto.dtinicio AND pcdesconto.dtfim
         --AND nvl(utilizadescrede, 'N') = 'N'
         --DDMEDICA-1733
         AND ( ((nvl(pcdesconto.utilizadescrede, 'N') = 'S') AND (codcli IN (p_codcli,vncodcliprinc))) OR
               ((nvl(pcdesconto.utilizadescrede, 'N') = 'N') AND (codcli  = p_codcli))       OR
               (codcli IS NULL) )
         AND ((codepto = vncodepto) OR (codepto IS NULL))
         AND ((codsec = vncodsec) OR (codsec IS NULL))
         AND ((codcategoria = vncodcategoria) OR (codcategoria IS NULL))
         AND ((codprod = p_codprod) OR (codprod IS NULL))
         AND ((codfornec = vncodfornec) OR (codfornec IS NULL))
         AND ((codusur = p_codusur) OR (codusur IS NULL))
         AND ((codsupervisor = vncodsupervisor) OR (codsupervisor IS NULL))
         AND ((numregiao = p_numregiao) OR (numregiao IS NULL))
         AND ((codativ = vncodatv1) OR (codativ IS NULL))
         AND ((origemped = p_origempedido) OR (nvl(origemped, 'O') = 'O'))
         AND ((codpraca = vncodpraca) OR (codpraca IS NULL))
         AND ((codprodprinc = p_codprodprinc) OR (codprodprinc IS NULL))
         AND ((codplpag = p_codplpag) OR (codplpag IS NULL))
         AND ((classevenda = p_classevenda) OR (classevenda IS NULL))
         AND (pcdesconto.aplicadesconto = 'S') --somente descontos automaticos
         AND ((pcdesconto.areaatuacao = vsareaatuacao) OR
             (pcdesconto.areaatuacao is null))
         AND ((pcdesconto.codfilial  = p_codfilial ) or (pcdesconto.codfilial is null ))
         AND ((pcdesconto.codrede  = vncodrede) or (pcdesconto.codrede is null))
         AND ((pcdesconto.codmarca  = vncodmarca) or (pcdesconto.codmarca is null))
         AND ((pcdesconto.codlinhaprod  = vncodlinhaprod) or (pcdesconto.codlinhaprod is null))
         -- DDVENDAS-39681
         AND ((EXISTS (SELECT PCDESCONTOITEM.CODDESCONTO
                     FROM PCDESCONTOITEM
                    WHERE PCDESCONTOITEM.TIPO = 'GP'
                      AND PCDESCONTOITEM.CODDESCONTO = PCDESCONTO.CODDESCONTO
                      AND PCDESCONTOITEM.VALOR_NUM IN
                          (SELECT PCGRUPOSCAMPANHAI.CODGRUPO
                             FROM PCGRUPOSCAMPANHAI
                            WHERE PCGRUPOSCAMPANHAI.CODITEM = p_codprod))) OR
              (NOT EXISTS (SELECT PCDESCONTOITEM.CODDESCONTO
                             FROM PCDESCONTOITEM
                           WHERE PCDESCONTOITEM.TIPO = 'GP'
                                 AND PCDESCONTOITEM.CODDESCONTO = PCDESCONTO.CODDESCONTO)))          
         AND (((pcdesconto.CODGRUPOREST IS NULL) OR (pcdesconto.TIPOGRUPOREST IS NULL)) OR
                ((pcdesconto.CODGRUPOREST = CASE WHEN(pcdesconto.TIPOGRUPOREST = 'GR') OR
                (pcdesconto.TIPOGRUPOREST = 'CL') OR (pcdesconto.TIPOGRUPOREST = 'GP') THEN
                (SELECT PCGRUPOSCAMPANHAI.CODGRUPO
                    FROM PCGRUPOSCAMPANHAI
                   WHERE PCGRUPOSCAMPANHAI.DTEXCLUSAO IS NULL
                      AND PCGRUPOSCAMPANHAI.CODGRUPO = PCDESCONTO.CODGRUPOREST
                     AND PCGRUPOSCAMPANHAI.CODITEM =
                         DECODE(PCDESCONTO.TIPOGRUPOREST,
                                'CL',
                                p_CodCli,
                                'GR',
                                p_CodUsur,
                                'GP',
                                p_CodProd)
                     AND ROWNUM = 1) ELSE 0 END)))         
         --//>> FICOU DENTRO DO CURSOR --// AND ((nvl(percdesc, 0)+nvl(percdescfin,0)) > 0) --somente desconto
         AND ((pcdesconto.tipofv = p_tipofv ))
         AND ((pcpromocaocondvendamed.codcondicaovenda = p_codcondicaovenda)) -->> PESQUISA DIRETA PELA CONDIÇÃO DE VENDA DA PROMOÇÃO
         AND case when pcdesconto.aplicadescsimplesnacional in ('S', 'N') then pcdesconto.aplicadescsimplesnacional else nvl(vssimplesnacional, 'T') end = nvl(vssimplesnacional, 'T')
         AND ((nvl(pcdesconto.iniciointervalopromocaomed,0) = 0) OR --->> PROMOÇÃO SEM INTERVALO DE QUANTIDADE
              ((nvl(pcdesconto.iniciointervalopromocaomed,0) > 0) AND (nvl(vnqt,0) between nvl(pcdesconto.iniciointervalopromocaomed,0) and nvl(pcdesconto.fimintervalopromocaomed,0)))) --->> PROMOÇÃO COM INTERVALO DE QUANTIDADE E DENTRO DA FAIXA
         AND ((nvl(pcdesconto.QTINI,0) = 0) OR --->> POLITICA SEM INTERVALO DE QUANTIDADE - MED-1554
              ((nvl(pcdesconto.QTINI,0) > 0) AND (nvl(vnqt,0) between nvl(pcdesconto.QTINI,0) and nvl(pcdesconto.QTFIM,0)))) --->> MED-1554 - POLITICA COM INTERVALO DE QUANTIDADE E DENTRO DA FAIXA
         -- Filtros relacionados à Promoção
         AND (NVL(PCPROMOCAOMED.BLOQUEIO,'N') = 'N')
       ORDER BY 1,                  -- Primeiro Promoções de Markup, depois de Preço, depois de Desconto -- HIS.03080.2016
                ordenacao_markup,   -- Depois da ordenação do markup                   -- DDMEDICA-6837  
                coluna_order2 ASC,  -- Depois do menor Preço para o Maior Preço        -- HIS.03080.2016
                coluna_order3 DESC; -->> Do Maior Desconto para o Menor Desconto - MED-1729
    
    vbresult             BOOLEAN;
    vntempperdesc        NUMBER;
    vstempbasecreddebrca VARCHAR2(2);
    vnpercdesc           NUMBER;
    vsbasecreddebrca     VARCHAR2(2);

    -- HIS.03080.2016  - Variáveis para Implementação de Promoção com Preço Fixo
    vncoddesconto        NUMBER;      -- HIS.03080.2016
    vncodpromocaomed     NUMBER;      -- HIS.03080.2016
    vnprecofixo          NUMBER;      -- HIS.03080.2016
    vvtipoprecodesc      VARCHAR2(1); -- HIS.03080.2016
    vniniciointervaloqt  NUMBER;      -- DDMEDICA-6837    
    vnpercmarkup         NUMBER;      -- DDMEDICA-6837    

    vnvldesccmvpromocaomed  NUMBER;      -- DDMEDICA-5009
    vnperdesccmvpromocaomed NUMBER;      -- DDMEDICA-5009 
    vnnumverba              NUMBER;      -- DDMEDICA-5009
    vnvalorcotanumverba     NUMBER;      -- DDMEDICA-5009
    vvsemverbavldesccmv     VARCHAR2(1); -- DDMEDICA-5009

    --Dados do Cliente
    vncodcliprinc NUMBER;
    vncodatv1     NUMBER;
    vncodpraca    NUMBER;
    --Dados do RCA
    vncodsupervisor NUMBER;
    --Dados do Produto}
    vncodfornec                NUMBER;
    vncodepto                  NUMBER;
    vncodsec                   NUMBER;
    vncodcategoria             NUMBER;
    vncodsubcategoria          NUMBER;
    vicont                     NUMBER;
    vicont2                    NUMBER;
    vicont3                    NUMBER;
    vsaplicadesconto           VARCHAR2(1);
    vscreditasobrepolitica     VARCHAR2(1);
    vstempcreditasobrepolitica VARCHAR2(1);
    vsareaatuacao              pcusuari.areaatuacao%type;
    vnpercbaserca              number;
    vntemppbaserca             number;
    vssimplesnacional          pcclient.simplesnacional%type;
    vsalteraptabela            varchar2(1);
    vstempalteraptabela        varchar2(1);
    vncodrede                  pcclient.codrede%type;
    vncodmarca                 pcprodut.codmarca%type;
    vncodlinhaprod             pcprodut.codlinhaprod%type;
    vstempprioritaria          varchar2(1);
    vsprioritaria              varchar2(1);
    vsusaprioritaria           varchar2(1);
    vnPerDescfin               number;
    vntempperdescfin           number;

    vnPercDescCompararAcresc   NUMBER;
    vntempperdescrestr         NUMBER;
    vnpercdescrestr            NUMBER;
    vstempprioritariageral     varchar2(1);

    -- DDMEDICA-6837 - Markup
    vnPrecoVendaMarkup         NUMBER;
    vbAplicouPromocaoMarkup    BOOLEAN;

  BEGIN
    vbresult                 := FALSE;
    vnpercdesc               := 0;
    vnperdescfin             := 0;
    vnpercbaserca            := 0;
    --    vnpercdesc_cr          := 0;
    vsbasecreddebrca         := 'N';
    vscreditasobrepolitica   := 'S';
    vsalteraptabela          := 'N';
    vsprioritaria            := 'N';
    vsusaprioritaria         := p_usaprioritaria;
    --
    vnpercdescrestr          := 0;
    vnPercDescCompararAcresc := 0;

    -- HIS.03080.2016  - Inicializa Variáveis da Implementação de Promoção com Preço Fixo
    vncoddesconto            := NULL; -- HIS.03080.2016
    vncodpromocaomed         := NULL; -- HIS.03080.2016
    vnprecofixo              := NULL; -- HIS.03080.2016
    vvtipoprecodesc          := NULL; -- HIS.03080.2016
    vniniciointervaloqt      := NULL; -- DDMEDICA-6837    

    -- DDMEDICA-5009 - Inicializa Valores de Verba para Rebaixa de CMV da Promoção
    vnvldesccmvpromocaomed   := NULL; -- DDMEDICA-5009
    vnperdesccmvpromocaomed  := NULL; -- DDMEDICA-5009
    vnnumverba               := NULL; -- DDMEDICA-5009
    vnvalorcotanumverba      := NULL; -- DDMEDICA-5009
    vvsemverbavldesccmv      := NULL; -- DDMEDICA-5009

    -- DDMEDICA-6837 - Markup
    vbAplicouPromocaoMarkup  := FALSE;
    vnpercmarkup             := NULL; -- DDMEDICA-6837    

    --Buscar dados do cliente
    SELECT COUNT(*) INTO vicont FROM pcclient WHERE codcli = p_codcli;
    IF vicont <> 0 THEN
      SELECT nvl(codcliprinc, codcli) codcliprinc,
             codatv1,
             codpraca,
             pcclient.simplesnacional,
             pcclient.codrede
        INTO vncodcliprinc, vncodatv1, vncodpraca, vssimplesnacional,vncodrede
        FROM pcclient
       WHERE codcli = p_codcli;

      --Buscar dados do RCA
      SELECT COUNT(*) INTO vicont2 FROM pcusuari WHERE codusur = p_codusur;
      IF vicont2 <> 0 THEN
        SELECT codsupervisor, pcusuari.areaatuacao
          INTO vncodsupervisor, vsareaatuacao
          FROM pcusuari
         WHERE codusur = p_codusur;

        --Buscar dados do produto
        SELECT COUNT(*)
          INTO vicont3
          FROM pcprodut
         WHERE codprod = p_codprod;

        IF vicont3 <> 0 THEN
          SELECT codfornec, codepto, codsec, codcategoria, codsubcategoria,codmarca,codlinhaprod
            INTO vncodfornec,
                 vncodepto,
                 vncodsec,
                 vncodcategoria,
                 vncodsubcategoria,
                 vncodmarca,
                 vncodlinhaprod
            FROM pcprodut
           WHERE codprod = p_codprod;

         /***************
          ** DESCONTOS **
          ***************/

          --------------------------------------------------
          --Verificação de Políticas de Descontos - SEM REDE
          --------------------------------------------------
          FOR reg_pdescontos IN c_principal(vncodepto,
                                       vncodsec,
                                       vncodcategoria,
                                       vncodfornec,
                                       vncodsupervisor,
                                       vncodatv1,
                                       vncodpraca,
                                       vsaplicadesconto,
                                       vsareaatuacao,
                                       vssimplesnacional,
                                       vncodrede,
                                       vncodmarca,
                                       vncodlinhaprod,
                                       p_qt,
                                       vncodcliprinc) LOOP

           -- Se Promoção, verificar se Pode Comprar Promoção
           IF (NVL(reg_pdescontos.codpromocaomed,0) = 0) OR
              ((NVL(reg_pdescontos.codpromocaomed,0) > 0) AND (PKG_FUNCOESVENDAS_MED.F_PODECOMPRARPROMOCAO(reg_pdescontos.codpromocaomed,
                                                                                                           p_codfilial,
                                                                                                           p_codcli, -- Aqui não pode passar o Principal - DDMEDICA-2858
                                                                                                           p_numregiao,
                                                                                                           p_codusur,
                                                                                                           p_codplpag,
                                                                                                           p_codcondicaovenda,
                                                                                                           p_origempedido,
                                                                                                           p_tipofv,
                                                                                                           p_data) = 'S')) THEN
                
             -- Procedimento para Inserir na Tabela Temporária
             P_INSERE_TABTEMP(reg_pdescontos.CODPROMOCAOMED,
                              reg_pdescontos.CODDESCONTO,
                              reg_pdescontos.TIPOPOLITICAPROMOCAOMED,
                              reg_pdescontos.INICIOINTERVALOPROMOCAOMED,
                              reg_pdescontos.FIMINTERVALOPROMOCAOMED,
                              NVL(reg_pdescontos.PRECOFIXOPROMOCAOMED,0),
                              reg_pdescontos.PERCDESC,
                              reg_pdescontos.PERCDESCFIN,
                              '2',
                              NULL);

             -- Se for Promoção - HIS.03080.2016
             IF (nvl(reg_pdescontos.codpromocaomed,0) > 0) THEN

               vbresult               := TRUE;

               vnpercdesc             := reg_pdescontos.percdesc;
               vnperdescfin           := reg_pdescontos.percdescfin;
               vsprioritaria          := reg_pdescontos.prioritaria;
               vsalteraptabela        := reg_pdescontos.alteraptabela;

               p_mensagem             := to_char(reg_pdescontos.dtinicio,
                                                 'dd/mm/yyyy') || ',' ||
                                                 reg_pdescontos.coddesconto;

               vsbasecreddebrca       := reg_pdescontos.basecreddebrca;
               vnpercbaserca          := reg_pdescontos.percdesc;
               vscreditasobrepolitica := reg_pdescontos.creditasobrepolitica;

               -- HIS.03080.2016  - Variáveis da Implementação de Promoção com Preço Fixo
               vncoddesconto          := reg_pdescontos.coddesconto;          -- HIS.03080.2016
               vncodpromocaomed       := reg_pdescontos.codpromocaomed;       -- HIS.03080.2016
               vnprecofixo            := reg_pdescontos.precofixopromocaomed; -- HIS.03080.2016
               IF (NVL(reg_pdescontos.precofixopromocaomed,0) > 0) THEN
                 vvtipoprecodesc      := 'P'; -- HIS.03080.2016
               ELSE
                 vvtipoprecodesc      := 'D'; -- HIS.03080.2016
               END IF;
               vniniciointervaloqt    := reg_pdescontos.iniciointervalopromocaomed; -- DDMEDICA-6837    

               -------------------------------------
               -- Promoção de Markup - DDMEDICA-6837
               -------------------------------------
               IF (reg_pdescontos.tipopromocao = 'R') THEN
                 -- Calcula Desconto
                 IF ((NVL(p_custofin,0) = 0) OR
                     (NVL(p_ptabela,0)  = 0)) THEN
                   -- Não carregar desconto da promoção markup com custo zero
                   vnpercdesc               := 0;
                 ELSE
                   vnPrecoVendaMarkup       := NVL(p_custofin,0) * (1+(NVL(reg_pdescontos.PERCMARKUPMED,0) * 0.01));
                   vnpercdesc               := (1-(vnPrecoVendaMarkup/NVL(p_ptabela,0)))*100;
                 END IF;
                 vnperdescfin               := reg_pdescontos.percdescfin;
                 vvtipoprecodesc            := 'D';
                 vnprecofixo                := 0;
                 -- Promoção de Markup com Preço Fixo com ou sem faixa de quantidade
                 IF (reg_pdescontos.TIPOPOLITICA IN ('P','F')) THEN
                   IF (NVL(vnPercDesc,0) = 0) THEN
                     vnprecofixo := NVL(p_ptabela,0);
                   ELSE                         
                     vnprecofixo := NVL(vnPrecoVendaMarkup,0);
                   END IF;
                   -- Altera Preço Tabela
                   vvtipoprecodesc := 'P';
                   vsalteraptabela := 'S'; 
                   -- Não tem desconto (já vai aplicado no Preço Fixo)
                   vnPercDesc := 0;
                 END IF;                
                 -- DDMEDICA-6837 - Markup
                 vbAplicouPromocaoMarkup := TRUE;                         
                 -- DDMEDICA-6837 - Markup de Retorno da Procedure
                 vnpercmarkup            := reg_pdescontos.PERCMARKUPMED; 
               END IF; -- Fim Condição: Promoção de Markup

               -- Inicializando Variável com o Valor da Verba para Rebaixa de CMV da Promoção da PCDESCONTO - DDMEDICA-5009
               vnvldesccmvpromocaomed := reg_pdescontos.VLDESCCMVPROMOCAOMED;
               -- Obter Verba Relacionada com o Valor da Verba para Rebaixa de CMV da Promoção da PCDESCONTO - DDMEDICA-5009
               PKG_PROMOCAO_MED.P_OBTER_VERBA_PROMOCAO(reg_pdescontos.codpromocaomed,
                                                       vncodfornec,
                                                       vnvldesccmvpromocaomed,
                                                       vnnumverba,
                                                       vnvalorcotanumverba,
                                                       vvsemverbavldesccmv);

               -- Se for para gerar Log - DDMEDICA-2858
               IF (NVL(pi_vGravaTabTemp,'N') = 'S') THEN               
                 IF (vnCodPromocaoSelTabTemp IS NULL) THEN
                   vnCodDescontoSelTabTemp := vncoddesconto;
                   vnCodPromocaoSelTabTemp := vncodpromocaomed;
                 END IF;
               -- Se não for para gerar Log - DDMEDICA-2858
               ELSE
                 EXIT; -->> Se usar Promoção, sai no registro que encontrar
               END IF;

             -- Se não for Promoção
             ELSE

               -- Se Desconto
               IF ((nvl(reg_pdescontos.percdesc, 0)+nvl(reg_pdescontos.percdescfin,0)) > 0) THEN

                  vbresult                   := TRUE;
                  vntempperdesc              := reg_pdescontos.percdesc;
                  vntempperdescfin           := reg_pdescontos.percdescfin;
                  vntemppbaserca             := reg_pdescontos.percdesc;
                  vstempbasecreddebrca       := reg_pdescontos.basecreddebrca;
                  vstempcreditasobrepolitica := reg_pdescontos.creditasobrepolitica;
                  vstempalteraptabela        := reg_pdescontos.alteraptabela;
                  vstempprioritaria          := reg_pdescontos.prioritaria;

                  if vsprioritaria = 'N' then

                    if vstempprioritaria = 'S' then
                      --registro atual é de politica prioritaria

                      if vsusaprioritaria = 'S' then

                        vnpercdesc             := vntempperdesc;
                        vnperdescfin           := vntempperdescfin;
                        vsprioritaria          := vstempprioritaria;
                        vsalteraptabela        := vstempalteraptabela;

                        p_mensagem := to_char(reg_pdescontos.dtinicio,
                                              'dd/mm/yyyy') || ',' ||
                                      reg_pdescontos.coddesconto;
                        vncoddesconto  := reg_pdescontos.coddesconto; -- MED-1554

                    			if p_naousarautdebcredpoldesc = 'S' and vstempbasecreddebrca = 'S' then

                    			    vsbasecreddebrca       := vstempbasecreddebrca;
                    			    vnpercbaserca          := vntemppbaserca;
                    			    vscreditasobrepolitica := vstempcreditasobrepolitica;

                      		end if;

                      end if;

                    else
                      --registro atual não é de politica prioritaria

                      IF (vntempperdesc + vntempperdescfin) > (vnpercdesc + vnPerDescfin) THEN

                            vnpercdesc := vntempperdesc;
                            vnPerDescfin := vntempperdescfin;
                            vsprioritaria          := 'N';

                            vsalteraptabela        := vstempalteraptabela;

                            p_mensagem := to_char(reg_pdescontos.dtinicio,
                                                  'dd/mm/yyyy') || ',' ||
                                          reg_pdescontos.coddesconto;
                            vncoddesconto  := reg_pdescontos.coddesconto; -- MED-1554


                    			if p_naousarautdebcredpoldesc = 'S' and vstempbasecreddebrca = 'S' then

                    			    vsbasecreddebrca       := vstempbasecreddebrca;
                    			    vnpercbaserca          := vntemppbaserca;
                    			    vscreditasobrepolitica := vstempcreditasobrepolitica;

                       		end if;



                      END IF;

                			if p_naousarautdebcredpoldesc = 'S' and vstempbasecreddebrca = 'S' and
                			   vntemppbaserca > vnpercbaserca then

                			    vsbasecreddebrca       := vstempbasecreddebrca;
                			    vnpercbaserca          := vntemppbaserca;
                			    vscreditasobrepolitica := vstempcreditasobrepolitica;

                         		end if;

                    end if;

                  else
                    -- já tem uma politica prioritaria

                          IF (vntempperdesc + vntempperdescfin) > (vnpercdesc + vnPerDescfin) THEN

                            vnpercdesc             := vntempperdesc;
                            vnperdescfin           := vntempperdescfin;
                            vsprioritaria          := vstempprioritaria;
                            vsalteraptabela        := vstempalteraptabela;

                            p_mensagem := to_char(reg_pdescontos.dtinicio, 'dd/mm/yyyy') || ',' ||
                                          reg_pdescontos.coddesconto;
                            vncoddesconto  := reg_pdescontos.coddesconto; -- MED-1554

                    		      if p_naousarautdebcredpoldesc = 'S' and vstempbasecreddebrca = 'S' then

                    			    vsbasecreddebrca       := vstempbasecreddebrca;
                    			    vnpercbaserca          := vntemppbaserca;
                    			    vscreditasobrepolitica := vstempcreditasobrepolitica;

                             		end if;


                          END IF;

                  end if;

               END IF; -- Fim Condição Se Desconto

             END IF; -- Fim Condição Se Promoção

           END IF; -- Fim Condição: Se Promoção, verificar se Pode Comprar Promoção
          END LOOP; -- reg_pdescontos

         /***********************************
          ** ACRESCIMOS - 4663.087543.2014 **
          ***********************************/
          -- Se não aplicou a Promoção de Markup - DDMEDICA-6837
          IF (NOT vbAplicouPromocaoMarkup) THEN
            IF (p_tratarrestricaoacrescimo = 'S') AND
               (p_aplicaracrescimopolitica = 'S') THEN
  
              -- Percentual de Desconto encontrado no processamento anterior para comparar com o Acréscimo
              vnPercDescCompararAcresc := NVL(vnpercdesc,0);
  
              ---------------------------------------------------
              --Verificação de Políticas de Acréscimos - SEM REDE
              ---------------------------------------------------
              FOR reg_pdescontos IN c_principal(vncodepto,
                                           vncodsec,
                                           vncodcategoria,
                                           vncodfornec,
                                           vncodsupervisor,
                                           vncodatv1,
                                           vncodpraca,
                                           vsaplicadesconto,
                                           vsareaatuacao,
                                           vssimplesnacional,
                                           vncodrede,
                                           vncodmarca,
                                           vncodlinhaprod,
                                           p_qt,
                                           vncodcliprinc) LOOP
                                           
               -- Se Promoção, verificar se Pode Comprar Promoção
               IF (NVL(reg_pdescontos.codpromocaomed,0) = 0) OR
                  ((NVL(reg_pdescontos.codpromocaomed,0) > 0) AND (PKG_FUNCOESVENDAS_MED.F_PODECOMPRARPROMOCAO(reg_pdescontos.codpromocaomed,
                                                                                                               p_codfilial,
                                                                                                               p_codcli, -- Aqui não pode passar o Principal - DDMEDICA-2858
                                                                                                               p_numregiao,
                                                                                                               p_codusur,
                                                                                                               p_codplpag,
                                                                                                               p_codcondicaovenda,
                                                                                                               p_origempedido,
                                                                                                               p_tipofv,
                                                                                                               p_data) = 'S')) THEN
               -- Se Acréscimo
               IF (nvl(reg_pdescontos.percdesc, 0) < 0) THEN
  
                  vntempperdescrestr         := reg_pdescontos.percdesc;
                  vntemppbaserca             := reg_pdescontos.percdesc;
                  vstempbasecreddebrca       := reg_pdescontos.basecreddebrca;
                  vstempcreditasobrepolitica := reg_pdescontos.creditasobrepolitica;
                  vstempalteraptabela        := reg_pdescontos.alteraptabela;
                  vstempprioritaria          := reg_pdescontos.prioritaria;
                  vstempprioritariageral     := reg_pdescontos.prioritariageral;
  
                  if vsprioritaria = 'N' then
  
                    if vstempprioritaria = 'S' then
                      --registro atual é de politica prioritaria
  
                      if (vsusaprioritaria = 'S') and
                         ((nvl(vnPercDescCompararAcresc,0) = 0) or                                         --//>> Condição da 2316 - Tarefa 97059 - somente conceder Acréscimo se achar desconto
                          ((nvl(vnPercDescCompararAcresc,0) > 0) and (vstempprioritariageral = 'S'))) THEN --//>> Condição da 2316 - Prioritária Geral - neste caso concede sempre
  
  
                        vbresult               := TRUE;
                        vnpercdescrestr        := vntempperdescrestr;
                        vsprioritaria          := vstempprioritaria;
                        vsalteraptabela        := vstempalteraptabela;
  
                        p_mensagem := to_char(reg_pdescontos.dtinicio,
                                              'dd/mm/yyyy') || ',' ||
                                      reg_pdescontos.coddesconto;
                        vncoddesconto  := reg_pdescontos.coddesconto; -- MED-1554
  
                    			if p_naousarautdebcredpoldesc = 'S' and vstempbasecreddebrca = 'S' then
  
                    			    vsbasecreddebrca       := vstempbasecreddebrca;
                    			    vnpercbaserca          := vntemppbaserca;
                    			    vscreditasobrepolitica := vstempcreditasobrepolitica;
  
                      		end if;
  
                      end if;
  
                    else
                      --registro atual não é de politica prioritaria
  
                      IF (vntempperdescrestr < vnpercdescrestr) AND
                         ((nvl(vnPercDescCompararAcresc,0) = 0) OR                                         --//>> Condição da 2316 - Tarefa 97059 - somente conceder Acréscimo se achar desconto
                          ((nvl(vnPercDescCompararAcresc,0) > 0) AND (vstempprioritariageral = 'S'))) THEN --//>> Condição da 2316 - Prioritária Geral - neste caso concede sempre
  
                            vbresult               := TRUE;
                            vnpercdescrestr        := vntempperdescrestr;
                            vsprioritaria          := 'N';
  
                            vsalteraptabela        := vstempalteraptabela;
  
                            p_mensagem := to_char(reg_pdescontos.dtinicio,
                                                  'dd/mm/yyyy') || ',' ||
                                          reg_pdescontos.coddesconto;
                            vncoddesconto  := reg_pdescontos.coddesconto; -- MED-1554
  
  
                    			if p_naousarautdebcredpoldesc = 'S' and vstempbasecreddebrca = 'S' then
  
                    			    vsbasecreddebrca       := vstempbasecreddebrca;
                    			    vnpercbaserca          := vntemppbaserca;
                    			    vscreditasobrepolitica := vstempcreditasobrepolitica;
  
                       		end if;
  
  
  
                      END IF;
  
                			if p_naousarautdebcredpoldesc = 'S' and vstempbasecreddebrca = 'S' and
                			   vntemppbaserca > vnpercbaserca then
  
                			    vsbasecreddebrca       := vstempbasecreddebrca;
                			    vnpercbaserca          := vntemppbaserca;
                			    vscreditasobrepolitica := vstempcreditasobrepolitica;
  
                      end if;
  
                    end if;
  
                  else
                    -- já tem uma politica prioritaria
  
                          IF (vntempperdescrestr < vnpercdescrestr) AND
                             ((nvl(vnPercDescCompararAcresc,0) = 0) OR                                         --//>> Condição da 2316 - Tarefa 97059 - somente conceder Acréscimo se achar desconto
                              ((nvl(vnPercDescCompararAcresc,0) > 0) AND (vstempprioritariageral = 'S'))) THEN --//>> Condição da 2316 - Prioritária Geral - neste caso concede sempre
  
                            vbresult               := TRUE;
                            vnpercdescrestr        := vntempperdescrestr;
                            vsprioritaria          := vstempprioritaria;
                            vsalteraptabela        := vstempalteraptabela;
  
                            p_mensagem := to_char(reg_pdescontos.dtinicio, 'dd/mm/yyyy') || ',' ||
                                          reg_pdescontos.coddesconto;
                            vncoddesconto  := reg_pdescontos.coddesconto; -- MED-1554
  
                    		      if p_naousarautdebcredpoldesc = 'S' and vstempbasecreddebrca = 'S' then
  
                    			    vsbasecreddebrca       := vstempbasecreddebrca;
                    			    vnpercbaserca          := vntemppbaserca;
                    			    vscreditasobrepolitica := vstempcreditasobrepolitica;
  
                             		end if;
  
  
                          END IF;
  
                  end if;
  
               END IF; -- Fim Condição Se Acréscimo
               END IF; -- Fim Condição: Se Promoção, verificar se Pode Comprar Promoção
              END LOOP; -- reg_pdescontos
              
            END IF; -- Fim Condição ACRESCIMOS - 4663.087543.2014
          END IF; -- Fim Condição não usar ACRESCIMOS se Aplicou Promoção de Markup - DDMEDICA-6837

        ELSE
          p_mensagem := 'Não foi possível buscar dados do PCPRODUT!';
        END IF;
      ELSE
        p_mensagem := 'Não foi possível buscar dados do PCUSUARI!';
      END IF; --dados do PCCLIENT
    ELSE
      p_mensagem := 'Não foi possível buscar dados do PCCLIENT!';
    END IF;

    -- SE TEM ACRÉSCIMO VÁLIDO - 4663.087543.2014
    IF (NVL(vnpercdescrestr,0) <> 0) THEN
      vnpercdesc := NVL(vnpercdescrestr,0);

      -- HIS.03080.2016  - Desconsidera o Preço Fixo -- HIS.03080.2016
      vncoddesconto           := NULL; -- HIS.03080.2016
      vncodpromocaomed        := NULL; -- HIS.03080.2016
      vnprecofixo             := NULL; -- HIS.03080.2016
      vvtipoprecodesc         := NULL; -- HIS.03080.2016
      vniniciointervaloqt     := NULL; -- DDMEDICA-6837    
      -- DDMEDICA-5009 - Desconsidera Verba para Rebaixa de CMV da Promoção da PCDESCONTO - 
      vnvldesccmvpromocaomed  := NULL; -- DDMEDICA-5009
      vnperdesccmvpromocaomed := NULL; -- DDMEDICA-5009
      vnnumverba              := NULL; -- DDMEDICA-5009
      vnvalorcotanumverba     := NULL; -- DDMEDICA-5009
      vvsemverbavldesccmv     := NULL; -- DDMEDICA-5009

    END IF;

    p_perdesc               := round(vnpercdesc, p_numcasasdecvenda);
    p_perdescfin            := round(vnPerDescfin,p_numcasasdecvenda);
    p_basecreddebrca        := vsbasecreddebrca;
    p_creditasobrepolitica  := vscreditasobrepolitica;
    p_pbaserca              := round(vnpercbaserca, p_numcasasdecvenda);
    p_alteraptabela         := vsalteraptabela;

    -- HIS.03080.2016  - Variáveis de Retorno de Promoção de Preço Fixo -- HIS.03080.2016
    p_coddesconto           := vncoddesconto;       -- HIS.03080.2016
    p_codpromocaomed        := vncodpromocaomed;    -- HIS.03080.2016
    p_precofixo             := vnprecofixo;         -- HIS.03080.2016
    p_tipoprecodesc         := vvtipoprecodesc;     -- HIS.03080.2016
    p_iniciointervaloqt     := vniniciointervaloqt; -- DDMEDICA-6837
    p_percmarkup            := vnpercmarkup;        -- DDMEDICA-6837

    -- DDMEDICA-5009 - Valores da Verba para Rebaixa de CMV da Promoção da PCDESCONTO - 
    p_vldesccmvpromocaomed  := vnvldesccmvpromocaomed;  -- DDMEDICA-5009
    p_perdesccmvpromocaomed := vnperdesccmvpromocaomed; -- DDMEDICA-5009
    p_numverba              := vnnumverba;              -- DDMEDICA-5009
    p_valorcotanumverba     := vnvalorcotanumverba;     -- DDMEDICA-5009     
    p_semverbavldesccmv     := vvsemverbavldesccmv;     -- DDMEDICA-5009     

    RETURN vbresult;
  EXCEPTION
    WHEN OTHERS THEN
      p_mensagem := 'Erro ao Validar Politica de Descontos: ' || SQLCODE || '-' ||
                    SQLERRM;
      RETURN FALSE;
  END FUNCAO_OBTEM_DESC_POLITICA_CV;


  FUNCTION FUNCAO_OBTEM_DESC_QUANTIDADE
    (p_codprod             IN NUMBER,
     p_qtde                IN NUMBER,
     p_numregiao           IN NUMBER,
   --  p_ptabela             IN NUMBER,
  --   p_pvenda1             IN NUMBER,
     p_codpraca            IN NUMBER,
  --   p_numcasasdecvenda    IN NUMBER,
     p_numdias             IN NUMBER,
     p_codprodprinc        IN NUMBER,
     p_usaprioritaria      IN VARCHAR2,
     p_tipofv              IN pcintegradora.tipofv%type,
     p_mensagem            OUT VARCHAR2,
     p_perdesc             OUT NUMBER,
     p_creditasobreptabela OUT VARCHAR2,
     p_basedebcredrca      OUT VARCHAR2,
     p_percbaserca         OUT NUMBER) RETURN BOOLEAN IS

      vbresult         BOOLEAN;
      vnpercdesc       NUMBER;
      vnperdesctemp    number;
      vnperdescmax     NUMBER;
  --    vnperdescmaxtemp number;
  --    vnptabela        NUMBER;

  --    vnptabela_quantmax        NUMBER;
  --    vnptabela_quant           NUMBER;
      vscreditasobreptabela     VARCHAR2(1);
      vscreditasobreptabelatemp VARCHAR2(1);
      vddtinicio                DATE;
      vniniciointervalo         NUMBER;
      vnfimintervalo            NUMBER;
      vsbasecreddebrca          pcdescquant.basecreddebrca%type;
      vsbasecreddebrcatemp      pcdescquant.basecreddebrca%type;
      vnpercbaserca             number;
      vnpercbasercatemp         number;
      vsprioritaria             pcdescquant.prioritaria%type;
      vstempprioritaria         pcdescquant.prioritaria%type;



    BEGIN


      vbresult      := FALSE;
  --    vnptabela     := p_ptabela;
      vnpercdesc    := null;
      vnpercbaserca := null;
      vsprioritaria := 'N';




        for reg in (SELECT pcdescquant.percdesc,
                           pcdescquant.dtfim,
                           pcdescquant.perdescmax,
                           pcdescquant.creditasobreptabela,
                           pcdescquant.dtinicio,
                           pcdescquant.iniciointervalo,
                           pcdescquant.fimintervalo,
                           nvl(pcdescquant.basecreddebrca, 'N') basecreddebrca,
                           pcdescquant.prioritaria,
                           pcdescquant.questionausoprioritaria
                      FROM pcdescquant, pcplpag
                     WHERE pcdescquant.codprod =
                           decode(pcdescquant.APLICAFAMILIAPRODUTOS,
                                  'S',
                                  p_codprodprinc,
                                  p_codprod)
                       AND pcdescquant.codplpagmax = pcplpag.codplpag(+)
                       AND decode(pcdescquant.codplpagmax,
                                  NULL,
                                  p_numdias,
                                  pcplpag.numdias) >= p_numdias
                       AND pcdescquant.iniciointervalo <= p_qtde
                       AND pcdescquant.fimintervalo >= p_qtde
                       AND ((pcdescquant.numregiao = p_numregiao) OR
                           (pcdescquant.numregiao IS NULL))
                       AND ((pcdescquant.codpraca = p_codpraca) OR
                           (pcdescquant.codpraca IS NULL))
                       AND ((trunc(SYSDATE) BETWEEN pcdescquant.dtinicio AND
                           pcdescquant.dtfim) OR ((pcdescquant.dtinicio IS NULL) AND
                           (pcdescquant.dtfim IS NULL)))
                       AND nvl(pcdescquant.tipodesconto, 'A') = 'A'
                       --AND pcdescquant.tipofv = p_tipofv
                       AND (case when p_tipofv = 'OL' then pcdescquant.aplicaoperlog else pcdescquant.aplicapedelet end) = 'S'
                     ORDER BY pcdescquant.percdesc) loop

          vbresult                   := TRUE;
          vnperdesctemp              := reg.percdesc;
          vsbasecreddebrcatemp       := reg.basecreddebrca;
          vscreditasobreptabelatemp  := reg.creditasobreptabela;
          vnpercbasercatemp          := reg.percdesc;
          vstempprioritaria          := reg.prioritaria;


          if vnperdesctemp < 0 then
            --desconto


           if vsprioritaria = 'N' then

            if vstempprioritaria = 'S' then --registro atual é de politica prioritaria


               if p_usaprioritaria = 'S' then


                  vnpercdesc        := vnperdesctemp;
                  vddtinicio        := reg.dtinicio;
                  vniniciointervalo := reg.iniciointervalo;
                  vnfimintervalo    := reg.fimintervalo;
                  vnperdescmax      := reg.perdescmax;
                  vsprioritaria          := reg.prioritaria;



                  if vsbasecreddebrcatemp = 'S'  then
                    vsbasecreddebrca      := vsbasecreddebrcatemp;
                    vnpercbaserca         := vnpercbasercatemp;
                    vscreditasobreptabela := vscreditasobreptabelatemp;
                  end if;

               end if;


           else --registro atual não é prioritaria

                IF (vnperdesctemp < vnpercdesc) or vnpercdesc is null THEN


                  vnpercdesc        := vnperdesctemp;
                  vddtinicio        := reg.dtinicio;
                  vniniciointervalo := reg.iniciointervalo;
                  vnfimintervalo    := reg.fimintervalo;
                  vnperdescmax      := reg.perdescmax;
                  vsprioritaria          := 'N';


                END IF;

                if vsbasecreddebrcatemp = 'S' and
                   ((vnpercbasercatemp < vnpercbaserca) or vnpercbaserca is null) then
                  vsbasecreddebrca      := vsbasecreddebrcatemp;
                  vnpercbaserca         := vnpercbasercatemp;
                  vscreditasobreptabela := vscreditasobreptabelatemp;
                end if;
             end if;

            else -- já tem politica prioritaria

                IF (vnperdesctemp < vnpercdesc) or vnpercdesc is null THEN


                  vnpercdesc        := vnperdesctemp;
                  vddtinicio        := reg.dtinicio;
                  vniniciointervalo := reg.iniciointervalo;
                  vnfimintervalo    := reg.fimintervalo;
                  vnperdescmax      := reg.perdescmax;
                  vsprioritaria          := reg.prioritaria;



                END IF;

                if vsbasecreddebrcatemp = 'S' and
                   ((vnpercbasercatemp < vnpercbaserca) or vnpercbaserca is null) then
                  vsbasecreddebrca      := vsbasecreddebrcatemp;
                  vnpercbaserca         := vnpercbasercatemp;
                  vscreditasobreptabela := vscreditasobreptabelatemp;
                end if;


            end if;



          end if;

        END loop;


          --utilizado só para retornar o percentual
          p_perdesc := abs(vnpercdesc);


      --4. Desconto ou Acrescimo


      p_creditasobreptabela := vscreditasobreptabela;

      p_basedebcredrca := vsbasecreddebrca;

      p_percbaserca := abs(vnpercbaserca);




      if vddtinicio is not null then
        p_mensagem := to_char(vddtinicio, 'dd/mm/yyyy') || ',' ||
                      vniniciointervalo || ',' || vnfimintervalo;
      end if;

      RETURN vbresult;
    EXCEPTION
      WHEN OTHERS THEN
        p_mensagem := 'Erro validar desconto por quantidade ' || SQLCODE || '-' ||
                      SQLERRM;
        RETURN FALSE;
    END FUNCAO_OBTEM_DESC_QUANTIDADE;

  BEGIN

   /**************************
    Inicializacao de Variaveis
    **************************/

    -- Inicializa Retornos de indicacao de erros
    po_vOcorreramErros := 'N';
    po_vMsgErros       := NULL;
    po_vMsgProc        := CHR(13) || 'INICIO: PRC_MED_OBTEM_DESC_INTEGRADORA';

    -- Se for para Inserir na Tabela Temporária - DDMEDICA-2858
    IF (pi_vGravaTabTemp = 'S') THEN
      -- Limpa Tabela Temporária
      -- DDMEDICA-5201 Alterado por ser mais eficiente que um delete na tabela inteira
      -- DELETE FROM PCMED_SELPROMOCAO;
      EXECUTE IMMEDIATE ' TRUNCATE TABLE PCMED_SELPROMOCAO ';

      -- Efetiva Transações
      IF (pi_vExecutaCommit = 'S') THEN
        COMMIT;
      END IF;
    END IF;

    -- Inicializa variáveis auxiliares
    vnPerDesc          := NVL(vnPerDesc,0);
    vnPerBonific       := NVL(vnPerBonific,0);
    vnPerComerc        := NVL(vnPerComerc,0);
    vnPerBoleto        := NVL(vnPerBoleto,0);
    vnPercDescFinLinha := NVL(vnPercDescFinLinha,0);

    -- DDMEDICA-706 - Otimização da pesquisa dos descontos
    vPESQDESCINTEGRADORA := FUSA_REGRA_MEDICAMENTOS('99',
                                                    'PESQDESCINTEGRADORAPORCONDICAO');
    -- DDVENDAS-31504 - Se Integradora Restrita às Condições de Venda da Rotina 2311
    IF (FOBTEM_PARAM_INTEGRADORA(pi_nIntegradora,
                                 'SOMENTEPROMORESTRITASCONDICAOVENDA',
                                 'N') = 'S') THEN 
      vPESQDESCINTEGRADORA := 'S';
    END IF;

    -- Pesquisa Parâmetro Tipo de Prazo de Medicamentos
    BEGIN
      SELECT PCPARAMFILIAL.valor
        INTO vvTipoPrazoMedicam
        FROM PCPARAMFILIAL
       WHERE (PCPARAMFILIAL.nome      = 'TIPOPRAZOMEDICAMEN')
         AND (PCPARAMFILIAL.codfilial = 99);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- Atualiza Mensagem de Erro e Aborta
        po_vMsgErros := 'Parâmetro [TIPOPRAZOMEDICAMEN] não encontrado.';
        RAISE e_Generico;

    END;

    -- Pesquisa parâmetro da condicao de venda que define a Origem do Desconto de Bonificacao
    BEGIN
      SELECT PCCONDICAOVENDA.tipodescbonif
        INTO vvTipoDescBonif
        FROM PCCONDICAOVENDA
       WHERE (PCCONDICAOVENDA.codcondicaovenda = pi_nCodCondicaoVenda);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- Atualiza Mensagem de Erro e Aborta
        po_vMsgErros := 'Condicao Venda [' || pi_nCodCondicaoVenda || '] não cadastrada.';
        RAISE e_Generico;
    END;

    -- Pesquisa Parâmetro que define se o Cliente pode ter Desconto Comercial no Boleto
    BEGIN
      SELECT nvl(pcclient.usadescfinseparadodesccom,'S')
        INTO vcPermiteDescBoleto
        FROM PCCLIENT
       WHERE (PCCLIENT.codcli = pi_nCodCli);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- Atualiza Mensagem de Erro e Aborta
        po_vMsgErros := 'Cliente [' || pi_nCodCli || '] não cadastrado.';
        RAISE e_Generico;
    END;
    
    -- Pesquisa parâmetro da integradora que define se pega o maior markup ou o menor markup, default menor markup - DDMEDICA-6837
    vREGRAAPLICACAOPROMOCAOMARKUP := FOBTEM_PARAM_INTEGRADORA(pi_nIntegradora,
                                                              'REGRAAPLICACAOPROMOCAOMARKUP',
                                                              '2');    

   /**********************************************************
    Obtem o maior Desconto cadastrado na Politica de Descontos
    **********************************************************/
    -- FUNCAO PARA OBTER O MAIOR DESCONTO CADASTRADOS NA POLITICA DE DESCONTOS

    BEGIN

      -- DDMEDICA-706 - Se pesquisa pela Condição de Venda
      IF (NVL(vPESQDESCINTEGRADORA,'N') = 'S') AND
         (NVL(pi_ncodcondicaovenda,0) > 0)     THEN

        vbpoliticadescvalida := FUNCAO_OBTEM_DESC_POLITICA_CV(pi_ncodprod ,
                                                              pi_ddata,
                                                              pi_scodfilial,
                                                              pi_nnumregiao,
                                                              pi_ncodcli,
                                                              pi_ncodusur,
                                                              pi_sorigempedido,
                                                              pi_ncodprodprinc,
                                                              pi_nnumcasasdecvenda,
                                                              pi_ncodplpag,
                                                              pi_sclassevenda,
                                                              pi_snaousarautdebcredpoldesc,
                                                              pi_susaprioritaria,
                                                              pi_stipofv,
                                                              pi_ncodcondicaovenda,
                                                              vsmensagempoldesc,
                                                              vnPercDescComercPolitica,
                                                              vnPercDescBoletoPolitica,
                                                              po_sbasecreddebrca,
                                                              po_screditasobrepolitica,
                                                              po_salteraptabela,
                                                              po_ndescpbaserca,
                                                              pi_stratarrestricaoacrescimo, -- 4663.087543.2014
                                                              pi_saplicaracrescimopolitica,
                                                              pi_nqtde,
                                                              vnCodDescontoPolitica,    -- HIS.03080.2016
                                                              vnCodPromocaoMedPolitica, -- HIS.03080.2016
                                                              vnPrecoFixoPolitica,      -- HIS.03080.2016
                                                              vvTipoPrecoDescPolitica,  -- HIS.03080.2016
                                                              vnVlDescCmvPromocaoMed,   -- DDMEDICA-5009
                                                              vnPerDescCmvPromocaoMed,  -- DDMEDICA-5009
                                                              vnNumVerba,               -- DDMEDICA-5009
                                                              vnValorCotaNumVerba,      -- DDMEDICA-5009
                                                              vvSemVerbaVlDescCmv,      -- DDMEDICA-5009
                                                              vREGRAAPLICACAOPROMOCAOMARKUP, -- DDMEDICA-6837
                                                              pi_nPTabela,                   -- DDMEDICA-6837
                                                              pi_nCustoFin,                  -- DDMEDICA-6837
                                                              vnInicioIntervaloQtPolitica,   -- DDMEDICA-6837
                                                              vnPercMarkupPoliticaPolitica   -- DDMEDICA-6837
                                                              );

      ELSE

        vbpoliticadescvalida := FUNCAO_OBTEM_DESC_POLITICA(pi_ncodprod ,
                                                           pi_ddata,
                                                           pi_scodfilial,
                                                           pi_nnumregiao,
                                                           pi_ncodcli,
                                                           pi_ncodusur,
                                                           pi_sorigempedido,
                                                           pi_ncodprodprinc,
                                                           pi_nnumcasasdecvenda,
                                                           pi_ncodplpag,
                                                           pi_sclassevenda,
                                                           pi_snaousarautdebcredpoldesc,
                                                           pi_susaprioritaria,
                                                           pi_stipofv,
                                                           pi_ncodcondicaovenda,
                                                           vsmensagempoldesc,
                                                           vnPercDescComercPolitica,
                                                           vnPercDescBoletoPolitica,
                                                           po_sbasecreddebrca,
                                                           po_screditasobrepolitica,
                                                           po_salteraptabela,
                                                           po_ndescpbaserca,
                                                           pi_stratarrestricaoacrescimo, -- 4663.087543.2014
                                                           pi_saplicaracrescimopolitica,
                                                           pi_nqtde,
                                                           vnCodDescontoPolitica,    -- HIS.03080.2016
                                                           vnCodPromocaoMedPolitica, -- HIS.03080.2016
                                                           vnPrecoFixoPolitica,      -- HIS.03080.2016
                                                           vvTipoPrecoDescPolitica,  -- HIS.03080.2016
                                                           vnVlDescCmvPromocaoMed,   -- DDMEDICA-5009
                                                           vnPerDescCmvPromocaoMed,  -- DDMEDICA-5009
                                                           vnNumVerba,               -- DDMEDICA-5009
                                                           vnValorCotaNumVerba,      -- DDMEDICA-5009
                                                           vvSemVerbaVlDescCmv,      -- DDMEDICA-5009
                                                           vREGRAAPLICACAOPROMOCAOMARKUP, -- DDMEDICA-6837
                                                           pi_nPTabela,                   -- DDMEDICA-6837
                                                           pi_nCustoFin,                  -- DDMEDICA-6837
                                                           vnInicioIntervaloQtPolitica,   -- DDMEDICA-6837
                                                           vnPercMarkupPoliticaPolitica   -- DDMEDICA-6837
                                                           );

      END IF;

      po_vMsgProc := po_vMsgProc || CHR(13) || 'vnPercDescComercPolitica: ' || vnPercDescComercPolitica;

      if vbpoliticadescvalida = false then
         vnPercDescComercPolitica := 0;
         vnPercDescBoletoPolitica := 0;

         po_vMsgErros := vsmensagempoldesc;


      end if;

    EXCEPTION WHEN OTHERS THEN
        vnPercDescComercPolitica := 0;
        vnPercDescBoletoPolitica := 0;
        po_vMsgErros := 'Erro ao verificar politica de descontos. '||SQLCODE|| ' - ' ||SQLERRM;
        RAISE e_Generico;
    END;

   /**************************************************************
    Obtem o maior Desconto cadastrado nos Descontos por Quantidade
    **************************************************************/
    -- FUNCAO PARA OBTER O MAIOR DESCONTO CADASTRADO NOS DESCONTOS POR QUANTIDADE

    begin

      vbvalidodescquant :=  FUNCAO_OBTEM_DESC_QUANTIDADE
                            (pi_nCodProd,
                             pi_nqtde,
                             pi_nnumregiao,
                           --  p_ptabela,
                           --  p_pvenda1,
                             pi_ncodpraca,
                           --  pi_nnumcasasdecvenda,
                             pi_nnumdias,
                             pi_ncodprodprinc,
                             pi_susaprioritaria ,
                             pi_stipofv,
                             vsmensagemdescquant,
                             vnPercDescComercQuantid,
                             po_creditasobreptabela_quant,
                             po_basedebcredrca_quant,
                             po_percbaserca_quant);

        if vbvalidodescquant = false then

           vnPercDescComercQuantid := 0;

           po_vMsgErros := vsmensagemdescquant;


        end if;


   EXCEPTION WHEN OTHERS THEN
        vnPercDescComercQuantid := 0;

        po_vMsgErros := 'Erro ao verificar politica de descontos por quantidade: '||vsmensagemdescquant;
        RAISE e_Generico;
    END;




   /**********************************************************
    Definição do Desconto Promocional:
    Maior Desconto entre o cadastrado na Politica de Descontos
    e o cadastrado nos Descontos por Quantidade
    **********************************************************/

    -- SE POSSUI ACRÉSCIMO - 4663.087543.2014
    IF (NVL(vnPercDescComercPolitica,0) < 0) THEN

      -- Desconto a conceder em NF (PRIORIZA O ACRÉSCIMO SOBRE DA POLITICA SOBRE O DESCONTO POR QUANTIDADE)
      vnPercDescComercPromocao := NVL(vnPercDescComercPolitica,0);
      -- Desconto a conceder em Boleto = ZERO (não aplica desconto no boleto quando acréscimo)
      vnPercDescBoletoPromocao := 0;

      po_vMsgProc := po_vMsgProc || CHR(13) || 'Com Acréscimo > vnPercDescComercPromocao: ' || vnPercDescComercPromocao;

    ELSE

      -- Escolhe o maior Desconto entre os cadastrados na Politica de Descontos e o Desconto por Quantidade
      IF ((NVL(vnPercDescComercPolitica,0) + NVL(vnPercDescBoletoPolitica,0)) >= NVL(vnPercDescComercQuantid,0)) THEN

        -- Se pode ser concedido Desconto no Boleto para o Cliente
        IF    (NVL(vcPermiteDescBoleto,' ') = 'S') THEN

          -- Desconto a conceder em NF
          vnPercDescComercPromocao := NVL(vnPercDescComercPolitica,0);
          -- Desconto a conceder em Boleto
          vnPercDescBoletoPromocao := NVL(vnPercDescBoletoPolitica,0);

          po_vMsgProc := po_vMsgProc || CHR(13) || 'Permite Boleto > vnPercDescComercPromocao: ' || vnPercDescComercPromocao;

        -- Se NÃO pode ser concedido Desconto no Boleto para o Cliente
        ELSE

          -- Desconto a conceder em NF (adiciona o desconto que seria dado no boleto ao desconto da nota fiscal)
          vnPercDescComercPromocao := (NVL(vnPercDescComercPolitica,0) + NVL(vnPercDescBoletoPolitica,0));
          -- Desconto a conceder em Boleto = ZERO (não pode conceder desconto no boleto)
          vnPercDescBoletoPromocao := 0;

          po_vMsgProc := po_vMsgProc || CHR(13) || 'Não Permite Boleto > vnPercDescComercPromocao: ' || vnPercDescComercPromocao;

        END IF;

        ELSE

        -- Desconto a conceder em NF
        vnPercDescComercPromocao := NVL(vnPercDescComercQuantid,0);
        -- Desconto a conceder em Boleto = ZERO (Desconto por Quantidade não possui cadastro de desconto financeiro)
        vnPercDescBoletoPromocao := 0;

        po_vMsgProc := po_vMsgProc || CHR(13) || 'Desconto por Qtde. > vnPercDescComercPromocao: ' || vnPercDescComercPromocao;

      END IF;

    END IF; -- FIM CONDIÇÃO SE POSSUI ACRÉSCIMO - 4663.087543.2014

    -- Desconto Total da Promoção
    --vnPercDescTotalPromocao  := NVL(vnPercDescComercPromocao,0) + NVL(vnPercDescBoletoPromocao,0);

   /***************************************
    Obtem o Desconto, Grupo de Faturamento
    e Linha de Prazo do Cadastro do Produto
    ****************************************/
    BEGIN
      SELECT PCPRODUT.percbonificvenda,
             PCPRODUT.grupofaturamento,
             PCPRODUT.codlinhaprazo
        INTO vnPercDescBonifProduto,
             vvGrupoFaturamento,
             vnCodLinhaPrazo
        FROM PCPRODUT
       WHERE (PCPRODUT.codprod = pi_nCodProd);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- Atualiza Mensagem de Erro e Aborta
        po_vMsgErros := 'Produto [' || pi_nCodProd || '] não cadastrado.';
        RAISE e_Generico;
    END;

   /**************************************************
    Redefine a Linha de Prazo do Produto para atender
    os Clientes que trabalham com Grupo de Faturamento
    **************************************************/
    IF (NVL(vvTipoPrazoMedicam,' ') = '1') THEN

      -- Define a Linha de Prazo conforme o Grupo de Produto
      IF    (NVL(vvGrupoFaturamento,' ') = 'E') THEN
        -- Grupo de Faturamento Etico = Linha 1
        vnCodLinhaPrazo := 1;
      ELSIF (NVL(vvGrupoFaturamento,' ') = 'G') THEN
        -- Grupo de Faturamento Generico = Linha 2
        vnCodLinhaPrazo := 2;
      ELSE
        vnCodLinhaPrazo := NULL;
      END IF;

    END IF;

   /**************************************************
    Obtem o Plano, Descontos e Parametro de Incidencia
    da Linha da Condição de Venda
    **************************************************/
    BEGIN
      SELECT PCCONDVENDALINHA.codplpag,
             PCCONDVENDALINHA.percdescbonifnota,
             PCCONDVENDALINHA.percdescomnota,
             PCCONDVENDALINHA.percdescboleto,
             PCCONDVENDALINHA.percdescfin,
             PCCONDVENDALINHA.tipoincidenciadescom
        INTO vnCodPlPag,
             vnPercDescBonifLinha,
             vnPercDescComercLinha,
             vnPercDescBoletoLinha,
             vnPercDescFinLinha,
             vvTipoIncidencia
        FROM PCCONDVENDALINHA
       WHERE (PCCONDVENDALINHA.codcondicaovenda = pi_nCodCondicaoVenda)
         AND (PCCONDVENDALINHA.codlinhaprazo    = vnCodLinhaPrazo);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- Atualiza Mensagem de Erro e Aborta
        po_vMsgErros := 'Linha [' || vnCodLinhaPrazo || '] não cadastrada na Cond. Venda [' || pi_nCodCondicaoVenda || '].';
        RAISE e_Generico;
    END;

   /****************************************************
    Redefine Descontos da Linha conforme parametrizações
    da Condição de Venda e do Cliente
    ****************************************************/

    -- Se a Origem do Desconto de Bonificacao for o Cadastro do Produto, substitui
    -- o Desconto de Bonificação da Linha da Condição de Venda pela Bonificação do cadastro do Produto
    IF (NVL(vvTipoDescBonif,' ') = 'P') THEN
      vnPercDescBonifLinha := NVL(vnPercDescBonifProduto,0);
    END IF;

    -- Se NÃO pode ser concedido Desconto no Boleto para o Cliente
    IF    (NVL(vcPermiteDescBoleto,' ') <> 'S') THEN

      -- Desconto a conceder em NF (adiciona o desconto que seria dado no boleto ao desconto da nota fiscal)
      vnPercDescComercLinha := NVL(vnPercDescComercLinha,0) + NVL(vnPercDescBoletoLinha,0);
      -- Desconto a conceder em Boleto = ZERO (não pode conceder desconto no boleto)
      vnPercDescBoletoLinha := 0;

    END IF;

   /**********************************************************
    Definição dos Descontos da Condição de Venda:
    Descontos a serem concedidos conforme o Tipo de Incidencia
    dos Descontos Promocionais sobre os Descontos por Linha
    na Condição de Venda
    *********************************************************/

    -- Cálculo do Total de Descontos da Linha (descontos bonificação + comercial + boleto)
    -- para utilização na validação do maior desconto entre os descontos da Condição de Venda e os Descontos Promocionais
    vnPercDescTotalLinha := F_CalcDescontoSobreDesconto((NVL(vnPercDescBonifLinha,0)),
                                                        (NVL(vnPercDescComercLinha,0) + NVL(vnPercDescBoletoLinha,0)));

    ------------------------------------------------------------------------------
    -- Se Agrega Desconto:
    -- Substitui o Desconto Comercial da Linha da Condição de Venda pelo Desconto
    -- Comercial Promocional e a agrega o resultado ao Desconto de Bonificação
    ------------------------------------------------------------------------------
    IF    (NVL(vvTipoIncidencia,' ') = 'A') THEN

      -- HIS.03080.2016  - Variáveis para Implementação de Promoção com Preço Fixo
      IF (NVL(vvTipoPrecoDescPolitica,' ') = 'P') THEN
        -->> Não tem Desconto Comercial, tem SOMENTE Preço Fixo
        vnPercDescComercPromocao := 0;
      END IF;

      -- Desconto Total a ser concedido em Nota Fiscal
      vnPerDesc    := F_CalcDescontoSobreDesconto(NVL(vnPercDescBonifLinha,0),
                                                  NVL(vnPercDescComercPromocao,0));
      -- Desconto de Bonificação a ser concedido em Nota Fiscal
      vnPerBonific := NVL(vnPercDescBonifLinha,0);
      -- Desconto Comercial a ser concedido em Nota Fiscal
      vnPerComerc  := NVL(vnPercDescComercPromocao,0);
      -- Desconto do Produto a ser concedido no Boleto
      vnPerBoleto  := NVL(vnPercDescBoletoPromocao,0);

      po_vMsgProc := po_vMsgProc || CHR(13) || 'Agrega > vnPercDescBonifLinha: '     || vnPercDescBonifLinha;
      po_vMsgProc := po_vMsgProc || CHR(13) || 'Agrega > vnPercDescComercPromocao: ' || vnPercDescComercPromocao;
      po_vMsgProc := po_vMsgProc || CHR(13) || 'Agrega > vnPerDesc: '                || vnPerDesc;

    ------------------------------------------------------------------------------
    -- Se Prioriza Desconto:
    -- Concede somente o Desconto Promocional caso exista, se não existir concede
    -- somente o Desconto da Linha da Condição de Venda
    ------------------------------------------------------------------------------
    ELSIF (NVL(vvTipoIncidencia,' ') = 'P') THEN

      -- Se encontrou Desconto Promocional, somente concederá no Produto os Descontos Promocionais
      -- HIS.03080.2016 - Promoção de Preço Fixo será tratado como existe Promocional
      IF (NVL(vvTipoPrecoDescPolitica,' ') = 'P') OR -->> HIS.03080.2016  - Se Encontrou Promoção de Preço Fixo
         ((NVL(vnPercDescComercPromocao,0) + NVL(vnPercDescBoletoPromocao,0)) > 0) THEN

        -- HIS.03080.2016  - Variáveis para Implementação de Promoção com Preço Fixo
        IF (NVL(vvTipoPrecoDescPolitica,' ') = 'P') THEN
          -->> Não tem Desconto Comercial, tem SOMENTE Preço Fixo
          vnPercDescComercPromocao := 0;
          po_vMsgProc := po_vMsgProc || CHR(13) || 'Prioriza > Preço Fixo';
        END IF;

        -- Desconto Total a ser concedido em Nota Fiscal
        vnPerDesc    := NVL(vnPercDescComercPromocao,0);
        -- Não concede Desconto de Bonificação em Nota Fiscal
        vnPerBonific := 0;
        -- Desconto Comercial a ser concedido em Nota Fiscal
        vnPerComerc  := NVL(vnPercDescComercPromocao,0);
        -- Desconto do produto a ser concedido no Boleto
        vnPerBoleto  := NVL(vnPercDescBoletoPromocao,0);

        po_vMsgProc := po_vMsgProc || CHR(13) || 'Prioriza > vnPercDescComercPromocao: ' || vnPercDescComercPromocao;
        po_vMsgProc := po_vMsgProc || CHR(13) || 'Prioriza > vnPerDesc: '                || vnPerDesc;

      -- Se não encontrou Desconto Promocional, somente concederá no Produto os Descontos da Linha da Condição de Venda
      ELSE

        -- HIS.03080.2016  - Variáveis para Implementação de Promoção com Preço Fixo
        -->> Não terá Promoção de Preço Fixo
        vnCodDescontoPolitica    := NULL; -- HIS.03080.2016
        vnCodPromocaoMedPolitica := NULL; -- HIS.03080.2016
        vnPrecoFixoPolitica      := NULL; -- HIS.03080.2016
        vvTipoPrecoDescPolitica  := NULL; -- HIS.03080.2016
        vnVlDescCmvPromocaoMed   := NULL; -- DDMEDICA-5009
        vnPerDescCmvPromocaoMed  := NULL; -- DDMEDICA-5009
        vnNumVerba               := NULL; -- DDMEDICA-5009
        vnValorCotaNumVerba      := NULL; -- DDMEDICA-5009
        vvSemVerbaVlDescCmv      := NULL; -- DDMEDICA-5009

        -- Desconto Total a ser concedido em Nota Fiscal
        vnPerDesc    := F_CalcDescontoSobreDesconto(NVL(vnPercDescBonifLinha,0),
                                                    NVL(vnPercDescComercLinha,0));
        -- Desconto de Bonificação a ser concedido em Nota Fiscal
        vnPerBonific := NVL(vnPercDescBonifLinha,0);
        -- Desconto Comercial a ser concedido em Nota Fiscal
        vnPerComerc  := NVL(vnPercDescComercLinha,0);
        -- Desconto do produto a ser concedido no Boleto
        vnPerBoleto  := NVL(vnPercDescBoletoLinha,0);

        po_vMsgProc := po_vMsgProc || CHR(13) || 'Prioriza > vnPercDescBonifLinha: '  || vnPercDescBonifLinha;
        po_vMsgProc := po_vMsgProc || CHR(13) || 'Prioriza > vnPercDescComercLinha: ' || vnPercDescComercLinha;
        po_vMsgProc := po_vMsgProc || CHR(13) || 'Prioriza > vnPerDesc: '             || vnPerDesc;

      END IF;

    ------------------------------------------------------------------------------
    -- Se Ignora:
    -- Ignora o Desconto Promocional e concede somente o Desconto da Linha da
    -- Condição de Venda
    ------------------------------------------------------------------------------
    ELSIF (NVL(vvTipoIncidencia,' ') = 'I') THEN

      -- HIS.03080.2016  - Variáveis para Implementação de Promoção com Preço Fixo
      -->> Não terá Promoção de Preço Fixo
      vnCodDescontoPolitica    := NULL; -- HIS.03080.2016
      vnCodPromocaoMedPolitica := NULL; -- HIS.03080.2016
      vnPrecoFixoPolitica      := NULL; -- HIS.03080.2016
      vvTipoPrecoDescPolitica  := NULL; -- HIS.03080.2016
      vnVlDescCmvPromocaoMed   := NULL; -- DDMEDICA-5009
      vnPerDescCmvPromocaoMed  := NULL; -- DDMEDICA-5009
      vnNumVerba               := NULL; -- DDMEDICA-5009
      vnValorCotaNumVerba      := NULL; -- DDMEDICA-5009
      vvSemVerbaVlDescCmv      := NULL; -- DDMEDICA-5009

      -- Desconto Total a ser concedido em Nota Fiscal
      vnPerDesc    := F_CalcDescontoSobreDesconto(NVL(vnPercDescBonifLinha,0),
                                                  NVL(vnPercDescComercLinha,0));
      -- Desconto de Bonificação a ser concedido em Nota Fiscal
      vnPerBonific := NVL(vnPercDescBonifLinha,0);
      -- Desconto Comercial a ser concedido em Nota Fiscal
      vnPerComerc  := NVL(vnPercDescComercLinha,0);
      -- Desconto do produto a ser concedido no Boleto
      vnPerBoleto  := NVL(vnPercDescBoletoLinha,0);

      po_vMsgProc := po_vMsgProc || CHR(13) || 'Ignora > vnPercDescBonifLinha: '  || vnPercDescBonifLinha;
      po_vMsgProc := po_vMsgProc || CHR(13) || 'Ignora > vnPercDescComercLinha: ' || vnPercDescComercLinha;
      po_vMsgProc := po_vMsgProc || CHR(13) || 'Ignora > vnPerDesc: '             || vnPerDesc;

    ------------------------------------------------------------------------------
    -- Se Maior Desconto:
    -- Concede o maior desconto entre o Desconto Promocional e o Desconto da Linha
    -- da Condição de Venda
    ------------------------------------------------------------------------------
    ELSIF (NVL(vvTipoIncidencia,' ') = 'M') THEN

      -- Se o maior Desconto for o Promocional, concede o Desconto Promocional
      -- HIS.03080.2016 - Promoção de Preço Fixo será tratado como maior, "Prioritário"
      IF (NVL(vvTipoPrecoDescPolitica,' ') = 'P') OR -->> HIS.03080.2016  - Se Encontrou Promoção de Preço Fixo
         ((NVL(vnPercDescComercPromocao,0) + NVL(vnPercDescBoletoPromocao,0)) > NVL(vnPercDescTotalLinha,0)) THEN

        -- HIS.03080.2016 - Variáveis para Implementação de Promoção com Preço Fixo
        IF (NVL(vvTipoPrecoDescPolitica,' ') = 'P') THEN
          -->> Não tem Desconto Comercial, tem SOMENTE Preço Fixo
          vnPercDescComercPromocao := 0;
          po_vMsgProc := po_vMsgProc || CHR(13) || 'Maior > Preço Fixo';
        END IF;

        -- Desconto Total a ser concedido em Nota Fiscal
        vnPerDesc    := NVL(vnPercDescComercPromocao,0);
        -- Não concede Desconto de Bonificação em Nota Fiscal
        vnPerBonific := 0;
        -- Desconto Comercial a ser concedido em Nota Fiscal
        vnPerComerc  := NVL(vnPercDescComercPromocao,0);
        -- Desconto do produto a ser concedido no Boleto
        vnPerBoleto  := NVL(vnPercDescBoletoPromocao,0);

        po_vMsgProc := po_vMsgProc || CHR(13) || 'Maior > vnPercDescComercPromocao: ' || vnPercDescComercPromocao;
        po_vMsgProc := po_vMsgProc || CHR(13) || 'Ignora > vnPerDesc: '               || vnPerDesc;

      -- Se o maior Desconto não for o Promocional, concede os Desconto da Linha da Condição de Venda
      ELSE

        -- HIS.03080.2016  - Variáveis para Implementação de Promoção com Preço Fixo
        -->> Não terá Promoção de Preço Fixo
        vnCodDescontoPolitica    := NULL; -- HIS.03080.2016
        vnCodPromocaoMedPolitica := NULL; -- HIS.03080.2016
        vnPrecoFixoPolitica      := NULL; -- HIS.03080.2016
        vvTipoPrecoDescPolitica  := NULL; -- HIS.03080.2016
        vnVlDescCmvPromocaoMed   := NULL; -- DDMEDICA-5009
        vnPerDescCmvPromocaoMed  := NULL; -- DDMEDICA-5009
        vnNumVerba               := NULL; -- DDMEDICA-5009
        vnValorCotaNumVerba      := NULL; -- DDMEDICA-5009
        vvSemVerbaVlDescCmv      := NULL; -- DDMEDICA-5009

        -- Desconto Total a ser concedido em Nota Fiscal
        vnPerDesc    := F_CalcDescontoSobreDesconto(NVL(vnPercDescBonifLinha,0),
                                                    NVL(vnPercDescComercLinha,0));
        -- Desconto de Bonificação a ser concedido em Nota Fiscal
        vnPerBonific := NVL(vnPercDescBonifLinha,0);
        -- Desconto Comercial a ser concedido em Nota Fiscal
        vnPerComerc  := NVL(vnPercDescComercLinha,0);
        -- Desconto do produto a ser concedido no Boleto
        vnPerBoleto  := NVL(vnPercDescBoletoLinha,0);

        po_vMsgProc := po_vMsgProc || CHR(13) || 'Maior > vnPercDescBonifLinha: '  || vnPercDescBonifLinha;
        po_vMsgProc := po_vMsgProc || CHR(13) || 'Maior > vnPercDescComercLinha: ' || vnPercDescComercLinha;
        po_vMsgProc := po_vMsgProc || CHR(13) || 'Ignora > vnPerDesc: '            || vnPerDesc;

      END IF;

    END IF;

   /*********************************
    Atualiza Retornos do Procedimento
    *********************************/
    po_nPerDesc     := NVL(vnPerDesc,0);
    po_nPerBonific  := NVL(vnPerBonific,0);
    po_nPerComerc   := NVL(vnPerComerc,0);
    po_nPerBoleto   := NVL(vnPerBoleto,0);
    po_nPercDescFin := NVL(vnPercDescFinLinha,0);
    pio_CodLinhaPrazo := vnCodLinhaPrazo; -- 155824

    -- HIS.03080.2016  - Variáveis para Implementação de Promoção com Preço Fixo
    po_nCodDescontoPolitica    := vnCodDescontoPolitica;        -- HIS.03080.2016
    po_nCodPromocaoMedPolitica := vnCodPromocaoMedPolitica;     -- HIS.03080.2016
    po_nPrecoFixoPolitica      := vnPrecoFixoPolitica;          -- HIS.03080.2016
    po_vTipoPrecoDescPolitica  := vvTipoPrecoDescPolitica;      -- HIS.03080.2016
    po_nInicioIntervaloQt      := vnInicioIntervaloQtPolitica;  -- DDMEDICA-6837 
    po_nPercMarkupMed          := vnPercMarkupPoliticaPolitica; -- DDMEDICA-6837 
    -- Verba para Rebaixa de CMV da Promoção - DDMEDICA-5009
    po_nVlDescCmv              := vnVlDescCmvPromocaoMed;
    po_nPerDescCmv             := vnPerDescCmvPromocaoMed;
    po_nNumVerba               := vnNumVerba;
    po_nValorCotaNumVerba      := vnValorCotaNumVerba;
    po_vSemVerbaVlDescCmv      := vvSemVerbaVlDescCmv;

    po_vMsgProc := po_vMsgProc || CHR(13) || 'po_vTipoPrecoDescPolitica: ' || po_vTipoPrecoDescPolitica;
    po_vMsgProc := po_vMsgProc || CHR(13) || 'po_nPerDesc: '               || po_nPerDesc;
    po_vMsgProc := po_vMsgProc || CHR(13) || 'po_nPrecoFixoPolitica: '     || po_nPrecoFixoPolitica;
    po_vMsgProc := po_vMsgProc || CHR(13) || 'FIM: PRC_MED_OBTEM_DESC_INTEGRADORA';
    po_vMsgProc := po_vMsgProc || CHR(13);

    -------------------------------------------
    -- Se for para Inserir na Tabela Temporária
    -------------------------------------------
    IF (pi_vGravaTabTemp = 'S') THEN
      -- GRAVA RETORNOS NA TABELA TEMPORÁRIA
      P_INSERE_TABTEMP(vnCodPromocaoSelTabTemp,
                       vnCodDescontoSelTabTemp,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       'S'); -->> Aplica Desconto
      -- Efetiva Transações
      IF (pi_vExecutaCommit = 'S') THEN
        COMMIT;
      END IF;
    END IF;

  EXCEPTION
    WHEN e_Generico THEN
      -- Atualiza Retorno indicando que ocorreram erros
      po_vOcorreramErros := 'S';
    WHEN OTHERS THEN
      -- Atualiza Retorno indicando que ocorreram erros
      po_vOcorreramErros := 'S';
      po_vMsgErros       := 'Erro ao obter os descontos da Cond. Venda [' || pi_nCodCondicaoVenda || '] - ' || SQLCODE || '-' || SQLERRM || ' -> ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
  END P_OBTEM_DESC_INTEGRADORA;

 /***********************************************************************************************
  PROCEDURE: P_VALIDAR_DESC_INTEGRADORA
  DESCRIÇÃO: DDMEDICA-706 - Otimização Consulta por Condição de Venda
  ***********************************************************************************************/
  PROCEDURE P_VALIDAR_DESC_INTEGRADORA(pi_nNumPedRca  IN  NUMBER,
                                       pi_nCodUsur    IN  NUMBER,
                                       pi_nCodProd    IN  NUMBER,
                                       po_vMensagem   OUT VARCHAR2)
  IS
    vsbasecreddebrca           pcdesconto.basecreddebrca%type;
    vscreditasobrepolitica     varchar2(1);
    vsalteraptabela            pcdesconto.alteraptabela%type;
    vnpercpbaserca             pcdesconto.percdesc%type;
    vscreditasobreptabela      varchar2(1);
    vsbasecreddebrca_quant     pcdescquant.basecreddebrca%type;
    vnpercpbaserca_desc        pcdescquant.percdesc%type;
                               vnperdesc number;
                               nperbonific number;
                               nperdesccom number;
                               nperdescboleto number;
                               nperdescfin number;
                               ncodlinhaprazo number;
    vsocorreramerros           varchar2(1);
    vsmensagemdescontos        varchar2(500);
    TYPE TRecRetornoPromocao   IS RECORD(
         vvTipoPromoPrecoDesc  VARCHAR2(1),
         vnCodDesconto         PCDESCONTO.CODDESCONTO%TYPE,
         vnCodPromocaoMed      PCDESCONTO.CODPROMOCAOMED%TYPE,
         vnPrecoFixo           PCDESCONTO.PRECOFIXOPROMOCAOMED%TYPE,
         vnPercDesc            PCDESCONTO.PERCDESC%TYPE,
         vnPercDescFin         PCDESCONTO.PERCDESCFIN%TYPE,
         vnInicioIntervaloQt   PCDESCONTO.INICIOINTERVALOPROMOCAOMED%TYPE,
         vnVlDescCmv           PCDESCONTO.VLDESCCMVPROMOCAOMED%TYPE, -- DDMEDICA-5009
         vnPerDescCmv          NUMBER,      -- DDMEDICA-5009
         vnNumVerba            NUMBER,      -- DDMEDICA-5009
         vnValorCotaNumVerba   NUMBER,      -- DDMEDICA-5009
         vvSemVerbaVlDescCmv   VARCHAR2(1), -- DDMEDICA-5009
         vnPercMarkupMed       NUMBER,      -- DDMEDICA-6837
         vvOcorreramErros      VARCHAR2(1),
         vvMsgErros            VARCHAR2(2000),
         vvMsgProc             VARCHAR2(4000));
    vrRetornoPromocao          TRecRetornoPromocao;
    vnNumRegiao                NUMBER;
  BEGIN

   FOR vc_produtos IN (SELECT PCPEDIFV.CODPROD
                            , PCPEDIFV.QT
                            , PCPEDRETORNO.CODCONDICAOVENDA
                            , PCPEDRETORNO.CODCLI
                            , TRUNC(PCPEDRETORNO.DTABERTURAPEDPALM) DATA
                            , PCPEDRETORNO.CODFILIAL
                            , PCPEDRETORNO.NUMPED
                            , PCPEDRETORNO.CODUSUR
                            , PCPEDCFV.ORIGEMPED
                            , PCPEDCFV.TIPOFV
                            , PCPEDIFV.CODPROD CODPRODPRINC
                            , PCPEDCFV.CODPLPAG
                            , PCPLPAG.NUMDIAS
                            , PCCLIENT.CLASSEVENDA
                            , PCCLIENT.CODPRACA
                            , 'N' NAOUSARAUTDEBCREDPOLDESC
                            , PCPEDIFV.POLITICAPRIORITARIA PRIORITARIA
                            , (SELECT TRATARRESTRICAOACRESCIMO FROM PCCONSUM) TRATARRESTRICAOACRESCIMO
                            , PCPEDRETORNO.INTEGRADORA
                         FROM PCPEDIFV, PCPEDCFV, PCPEDRETORNO, PCCLIENT, PCPLPAG
                        WHERE PCPEDIFV.NUMPEDRCA = pi_nNumPedRca
                          AND PCPEDIFV.CODUSUR = pi_nCodUsur
                          AND PCPEDIFV.CODPROD = pi_nCodProd
                          AND PCPEDIFV.NUMPEDRCA = PCPEDCFV.NUMPEDRCA
                          AND PCPEDIFV.CGCCLI = PCPEDCFV.CGCCLI
                          AND PCPEDIFV.CODUSUR = PCPEDCFV.CODUSUR
                          AND PCPEDIFV.DTABERTURAPEDPALM = PCPEDCFV.DTABERTURAPEDPALM
                          AND PCPEDIFV.NUMPEDRCA = PCPEDRETORNO.NUMPEDRCA
                          AND PCPEDIFV.CGCCLI = PCPEDRETORNO.CGCCLI
                          AND PCPEDIFV.CODUSUR = PCPEDRETORNO.CODUSUR
                          AND PCPEDIFV.DTABERTURAPEDPALM = PCPEDRETORNO.DTABERTURAPEDPALM
                          AND PCPLPAG.CODPLPAG = PCPEDCFV.CODPLPAG
                          AND PCCLIENT.CODCLI = PCPEDRETORNO.CODCLI
                          ) LOOP
       IF (vc_produtos.NUMPED > 0) THEN
         BEGIN
           SELECT NUMREGIAO
             INTO vnNumRegiao
             FROM PCPEDC
            WHERE (NUMPED = vc_produtos.NUMPED);
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
             vnNumRegiao := NULL;
         END;
       END IF;
       IF (NVL(vnNumRegiao,0) = 0) THEN
          BEGIN
            SELECT NUMREGIAO
              INTO vnNumRegiao
              FROM PCTABPRCLI
             WHERE CODCLI = VC_PRODUTOS.CODCLI
               AND CODFILIALNF = VC_PRODUTOS.CODFILIAL;
          EXCEPTION
            WHEN OTHERS THEN
              vnNumRegiao := NULL;
          END;
       END IF;
       IF (NVL(vnNumRegiao,0) = 0) THEN
          BEGIN
            SELECT NUMREGIAO
              INTO vnNumRegiao
              FROM PCPRACA
             WHERE CODPRACA = VC_PRODUTOS.CODPRACA;
          EXCEPTION
            WHEN OTHERS THEN
              vnNumRegiao := NULL;
          end;
       END IF;

       P_OBTEM_DESC_INTEGRADORA(vc_produtos.codprod,
                                vc_produtos.qt,
                                vc_produtos.codcondicaovenda,
                                vc_produtos.codcli,
                                vc_produtos.DATA,
                                vc_produtos.codfilial,
                                vnNumRegiao,
                                vc_produtos.codusur,
                                vc_produtos.origemped,
                                vc_produtos.codprodprinc,
                                2,--gregpcconsum.numcasasdecvenda,
                                vc_produtos.codplpag,
                                vc_produtos.numdias,
                                vc_produtos.classevenda,
                                vc_produtos.codpraca,
                                vc_produtos.naousarautdebcredpoldesc,
                                vc_produtos.prioritaria,
                                vc_produtos.tipofv,
                                vsbasecreddebrca,
                                vscreditasobrepolitica,
                                vsalteraptabela,
                                vnpercpbaserca,
                                vscreditasobreptabela,
                                vsbasecreddebrca_quant,
                                vnpercpbaserca_desc,
                                vnperdesc,
                                nperbonific,
                                nperdesccom,
                                nperdescboleto,
                                nperdescfin,
                                vsocorreramerros,
                                vsmensagemdescontos,
                                ncodlinhaprazo, -- 155824);
                                'N',--nvl(gregpcconsum.tratarrestricaoacrescimo,'N'), -- 4663.087543.2014
                                'N',--NVL(p_regpedido.aplicaracrescimopolitica,'N'),
                                vrRetornoPromocao.vnCodDesconto,         -- HIS.03080.2016
                                vrRetornoPromocao.vnCodPromocaoMed,      -- HIS.03080.2016
                                vrRetornoPromocao.vnPrecoFixo,           -- HIS.03080.2016
                                vrRetornoPromocao.vvTipoPromoPrecoDesc,  -- HIS.03080.2016
                                vrRetornoPromocao.vnVlDescCmv,           -- DDMEDICA-5009
                                vrRetornoPromocao.vnPerDescCmv,          -- DDMEDICA-5009
                                vrRetornoPromocao.vnNumVerba,            -- DDMEDICA-5009
                                vrRetornoPromocao.vnValorCotaNumVerba,   -- DDMEDICA-5009
                                vrRetornoPromocao.vvSemVerbaVlDescCmv,   -- DDMEDICA-5009                                
                                vrRetornoPromocao.vvMsgProc,             -- HIS.03080.2016
                                'S',  -- DDMEDICA-2858
                                'S',  -- DDMEDICA-2858
                                vc_produtos.integradora,
                                0,    -- PTABELA
                                0,    -- CUSTOFIN
                                vrRetornoPromocao.vnInicioIntervaloQt,
                                vrRetornoPromocao.vnPercMarkupMed);

      po_vMensagem := 'CodDesconto = '        || vrRetornoPromocao.vnCodDesconto        || ' , ' ||
                      'CodPromocaoMed = '     || vrRetornoPromocao.vnCodPromocaoMed     || ' , ' ||
                      'vnperdesc = '          || vnperdesc                              || ' , ' ||
                      'perbonific = '         || nperbonific                            || ' , ' ||
                      'perdesccom = '         || nperdesccom                            || ' , ' ||
                      'perdescboleto = '      || nperdescboleto                         || ' , ' ||
                      'perdescfin = '         || nperdescfin                            || ' , ' ||
                      'PrecoFixo = '          || vrRetornoPromocao.vnPrecoFixo          || ' , ' ||
                      'PercMarkup = '         || vrRetornoPromocao.vnPercMarkupMed      || ' , ' ||
                      'TipoPromoPrecoDesc = ' || vrRetornoPromocao.vvTipoPromoPrecoDesc || ' , ';

    END LOOP;

  END P_VALIDAR_DESC_INTEGRADORA;

 /***********************************************************************************************
  PROCEDURE: P_OBTER_TRANSPORTADORA_FREQENT
  DESCRIÇÃO: DDMEDICA-1654 - Obter Transportadora da Frequência de Entrega
  ***********************************************************************************************/
  PROCEDURE P_OBTER_TRANSPORTADORA_FREQENT(pi_nCodPraca           IN  NUMBER,
                                           pi_vCodFilial          IN VARCHAR2,
                                           po_nCodTransportadora OUT NUMBER,
                                           po_nCodFreqEntrega    OUT NUMBER) IS
    vbAchouTransp BOOLEAN;
    vvDiaSemana   VARCHAR2(1);
    vnCodFilial   NUMBER;
  BEGIN

    po_nCodTransportadora := NULL;
    po_nCodFreqEntrega    := NULL;

    IF (FUSA_REGRA_MEDICAMENTOS('99','APLICARTRANSPFREQENTPED') = 'S') THEN

      vbAchouTransp         := FALSE;

      vvDiaSemana           := TO_CHAR(SYSDATE,'D');

      BEGIN
        vnCodFilial := TO_NUMBER(pi_vCodFilial);
      EXCEPTION
        WHEN OTHERS THEN
          vnCodFilial := 0;
      END;

      FOR vc_TranspPraca IN (SELECT PCFREQENTREGAMED.CODFORNEC
                                  , NVL(PCFREQENTREGAMED.DOMINGO,'N') DOMINGO
                                  , NVL(PCFREQENTREGAMED.SEGUNDA,'N') SEGUNDA
                                  , NVL(PCFREQENTREGAMED.TERCA,'N')   TERCA
                                  , NVL(PCFREQENTREGAMED.QUARTA,'N')  QUARTA
                                  , NVL(PCFREQENTREGAMED.QUINTA,'N')  QUINTA
                                  , NVL(PCFREQENTREGAMED.SEXTA,'N')   SEXTA
                                  , NVL(PCFREQENTREGAMED.SABADO,'N')  SABADO
                                  , PCFREQENTREGAMED.CODFREQENTREGA
                               FROM PCFREQENTREGAMED
                              WHERE (PCFREQENTREGAMED.TIPOFREQ = 'TP')
                                AND (PCFREQENTREGAMED.CODPRACA = pi_nCodPraca)
                              ORDER BY PCFREQENTREGAMED.CODFREQENTREGA) LOOP

        IF ((vvDiaSemana = '1') AND (vc_TranspPraca.DOMINGO = 'S')) OR
           ((vvDiaSemana = '2') AND (vc_TranspPraca.SEGUNDA = 'S')) OR
           ((vvDiaSemana = '3') AND (vc_TranspPraca.TERCA   = 'S')) OR
           ((vvDiaSemana = '4') AND (vc_TranspPraca.QUARTA  = 'S')) OR
           ((vvDiaSemana = '5') AND (vc_TranspPraca.QUINTA  = 'S')) OR
           ((vvDiaSemana = '6') AND (vc_TranspPraca.SEXTA   = 'S')) OR
           ((vvDiaSemana = '7') AND (vc_TranspPraca.SABADO  = 'S')) THEN
          po_nCodTransportadora := vc_TranspPraca.CODFORNEC;
          po_nCodFreqEntrega    := vc_TranspPraca.CODFREQENTREGA;
          vbAchouTransp         := TRUE;
        END IF;

      END LOOP;

      IF (NOT vbAchouTransp) THEN

        FOR vc_TranspPraca IN (SELECT PCFREQENTREGAMED.CODFORNEC
                                    , NVL(PCFREQENTREGAMED.DOMINGO,'N') DOMINGO
                                    , NVL(PCFREQENTREGAMED.SEGUNDA,'N') SEGUNDA
                                    , NVL(PCFREQENTREGAMED.TERCA,'N')   TERCA
                                    , NVL(PCFREQENTREGAMED.QUARTA,'N')  QUARTA
                                    , NVL(PCFREQENTREGAMED.QUINTA,'N')  QUINTA
                                    , NVL(PCFREQENTREGAMED.SEXTA,'N')   SEXTA
                                    , NVL(PCFREQENTREGAMED.SABADO,'N')  SABADO
                                    , PCFREQENTREGAMED.CODFREQENTREGA
                                 FROM PCFREQENTREGAMED
                                WHERE (PCFREQENTREGAMED.TIPOFREQ = 'TF')
                                  AND (PCFREQENTREGAMED.CODFILIAL = vnCodFilial)
                                ORDER BY PCFREQENTREGAMED.CODFREQENTREGA) LOOP

          IF ((vvDiaSemana = '1') AND (vc_TranspPraca.DOMINGO = 'S')) OR
             ((vvDiaSemana = '2') AND (vc_TranspPraca.SEGUNDA = 'S')) OR
             ((vvDiaSemana = '3') AND (vc_TranspPraca.TERCA   = 'S')) OR
             ((vvDiaSemana = '4') AND (vc_TranspPraca.QUARTA  = 'S')) OR
             ((vvDiaSemana = '5') AND (vc_TranspPraca.QUINTA  = 'S')) OR
             ((vvDiaSemana = '6') AND (vc_TranspPraca.SEXTA   = 'S')) OR
             ((vvDiaSemana = '7') AND (vc_TranspPraca.SABADO  = 'S')) THEN
            po_nCodTransportadora := vc_TranspPraca.CODFORNEC;
            po_nCodFreqEntrega    := vc_TranspPraca.CODFREQENTREGA;
            vbAchouTransp         := TRUE;
          END IF;

        END LOOP;

        IF (NOT vbAchouTransp) THEN

          FOR vc_TranspPraca IN (SELECT PCFREQENTREGAMED.CODFORNEC
                                      , NVL(PCFREQENTREGAMED.DOMINGO,'N') DOMINGO
                                      , NVL(PCFREQENTREGAMED.SEGUNDA,'N') SEGUNDA
                                      , NVL(PCFREQENTREGAMED.TERCA,'N')   TERCA
                                      , NVL(PCFREQENTREGAMED.QUARTA,'N')  QUARTA
                                      , NVL(PCFREQENTREGAMED.QUINTA,'N')  QUINTA
                                      , NVL(PCFREQENTREGAMED.SEXTA,'N')   SEXTA
                                      , NVL(PCFREQENTREGAMED.SABADO,'N')  SABADO
                                      , PCFREQENTREGAMED.CODFREQENTREGA
                                   FROM PCFREQENTREGAMED
                                  WHERE (PCFREQENTREGAMED.TIPOFREQ = 'T')
                                  ORDER BY PCFREQENTREGAMED.CODFREQENTREGA) LOOP

            IF ((vvDiaSemana = '1') AND (vc_TranspPraca.DOMINGO = 'S')) OR
               ((vvDiaSemana = '2') AND (vc_TranspPraca.SEGUNDA = 'S')) OR
               ((vvDiaSemana = '3') AND (vc_TranspPraca.TERCA   = 'S')) OR
               ((vvDiaSemana = '4') AND (vc_TranspPraca.QUARTA  = 'S')) OR
               ((vvDiaSemana = '5') AND (vc_TranspPraca.QUINTA  = 'S')) OR
               ((vvDiaSemana = '6') AND (vc_TranspPraca.SEXTA   = 'S')) OR
               ((vvDiaSemana = '7') AND (vc_TranspPraca.SABADO  = 'S')) THEN
              po_nCodTransportadora := vc_TranspPraca.CODFORNEC;
              po_nCodFreqEntrega    := vc_TranspPraca.CODFREQENTREGA;
              vbAchouTransp         := TRUE;
            END IF;

          END LOOP;

        END IF;

      END IF;

    END IF; -- Fim Condição: Se Usa Regra Específica

  END P_OBTER_TRANSPORTADORA_FREQENT;

 /*************************************************************************
   PROCEDURE   : P_OBTER_DESC_SPREAD_OL
   DESCRIÇÃO   : DDMEDICA-1835 - Validação de Pré-Cadastro de Descontos da Indústria
   Programador : Anderson Silva
   Parametros  : ENTRADA
                 pi_vOpcao               = Identifica o que Retornar
                                           S - Spread
                                           D - Desconto da Indústria
                 pi_vCodFilial           = Código da Filial
                 pi_nCodProd             = Código do Produto
                 pi_nCodCli              = Código do Cliente
                 pi_nIntegradora         = Código da Integradora
                 pi_nCodCondicaoVenda    = Código da Condição de Venda
                 SAIDA
                 po_nPrioridade          = Prioridade do Spread/Desconto
                 po_vTipo                = Tipo do Spread/Desconto
                 po_nPercentual          = Percentual do Spread/Desconto
                 po_nPercRefDebCred      = % Desconto Referência de Débito/Crédito do OL
                 po_nPrioridadeAcrescimo = Prioridade do Spread/Desconto
  Data Criação : Anderson Silva - 25/04/2017 - HIS.02754.2016 - Procedimento para Retornar Desc./Spread OL
  Alteração    : Anderson Silva - 12/06/2017 - 0.069154.2017 - Ver Parâmetro Política Pruduto/Filial no Desc. do Spread
  Alteração    : Anderson Silva - 13/11/2017 - Retirada da FUNCOES_MED
  Alteração    : Anderson Silva - 09/12/2018 - HIS.00262.2018 - Acréscimo OL
  ************************************************************************/
  PROCEDURE P_OBTER_DESC_SPREAD_OL(pi_vOpcao               IN  VARCHAR2,
                                   pi_vCodFilial           IN  NUMBER,
                                   pi_nCodProd             IN  NUMBER,
                                   pi_nCodCli              IN  NUMBER,
                                   pi_nIntegradora         IN  NUMBER,
                                   pi_nCodCondicaoVenda    IN  NUMBER,
                                   po_nPrioridade          OUT NUMBER,
                                   po_vTipo                OUT VARCHAR2,
                                   po_nPercentual          OUT NUMBER,
                                   po_nPercRefDebCred      OUT NUMBER,
                                   po_nPercAcrescimo       OUT NUMBER,
                                   po_nPrioridadeAcrescimo OUT NUMBER)
  IS
  
    -- SQL
    vvSql                           VARCHAR2(32000);
  
    -- Parâmetro
    vUSAPOLITICACOMERCIALPRODFIL    PCPARAMFILIAL.VALOR%TYPE;
  
    -- Fornecedor, Desconto, Marca do Produto
    vnCodFornec                     PCPRODUT.CODFORNEC%TYPE;
    vnPercDesc                      PCPRODUT.PERCDESC%TYPE;
    vnCodMarca                      PCPRODUT.CODMARCA%TYPE;
    -- Rede do Cliente
    vnCodRede                       PCCLIENT.CODREDE%TYPE;
  
    -- Tabelas para uso no BulkCollect
    TYPE TT_CODFILIAL               IS TABLE OF PCFILIAL.CODIGO%TYPE                  INDEX BY BINARY_INTEGER;
    TYPE TT_CODPROD                 IS TABLE OF PCPRODUT.CODPROD%TYPE                 INDEX BY BINARY_INTEGER;
    TYPE TT_CODFORNEC               IS TABLE OF PCPRODUT.CODFORNEC%TYPE               INDEX BY BINARY_INTEGER;
    TYPE TT_CODCLI                  IS TABLE OF PCCLIENT.CODCLI%TYPE                  INDEX BY BINARY_INTEGER;
    TYPE TT_CODREDE                 IS TABLE OF PCCLIENT.CODREDE%TYPE                 INDEX BY BINARY_INTEGER;
    TYPE TT_TIPO                    IS TABLE OF VARCHAR2(20)                          INDEX BY BINARY_INTEGER;
    TYPE TT_PERCENTUAL              IS TABLE OF NUMBER                                INDEX BY BINARY_INTEGER;
    TYPE TT_PERCACRESC              IS TABLE OF NUMBER                                INDEX BY BINARY_INTEGER;  -- HIS.00262.2018
    TYPE TT_INTEGRADORA             IS TABLE OF PCINTEGRADORA.INTEGRADORA%TYPE        INDEX BY BINARY_INTEGER;  -- HIS.00262.2018
    TYPE TT_CODCONDICAOVENDA        IS TABLE OF PCCONDICAOVENDA.CODCONDICAOVENDA%TYPE INDEX BY BINARY_INTEGER;  -- HIS.00262.2018
    TYPE TT_CODMARCA                IS TABLE OF PCMARCA.CODMARCA%TYPE                 INDEX BY BINARY_INTEGER;
    ------
    vtCODFILIAL                     TT_CODFILIAL;
    vtCODPROD                       TT_CODPROD;
    vtCODFORNEC                     TT_CODFORNEC;
    vtCODCLI                        TT_CODCLI;
    vtCODREDE                       TT_CODREDE;
    vtTIPO                          TT_TIPO;
    vtPERCENTUAL                    TT_PERCENTUAL;
    vtPERCACRESC                    TT_PERCACRESC;       -- HIS.00262.2018
    vtINTEGRADORA                   TT_INTEGRADORA;      -- HIS.00262.2018
    vtCODCONDICAOVENDA              TT_CODCONDICAOVENDA; -- HIS.00262.2018
    vtCODMARCA                      TT_CODMARCA;
  
    -- Dados Registro
    TYPE TRecDadosRegistro          IS RECORD(
         CODFILIAL                  PCFILIAL.CODIGO%TYPE,
         CODPROD                    PCPRODUT.CODPROD%TYPE,
         CODFORNEC                  PCPRODUT.CODFORNEC%TYPE,
         CODCLI                     PCCLIENT.CODCLI%TYPE,
         CODREDE                    PCCLIENT.CODREDE%TYPE,
         TIPO                       VARCHAR2(20),
         PERCENTUAL                 NUMBER,
         PERCACRESC                 NUMBER,                                 -- HIS.00262.2018
         INTEGRADORA                PCINTEGRADORA.INTEGRADORA%TYPE,         -- HIS.00262.2018
         CODCONDICAOVENDA           PCCONDICAOVENDA.CODCONDICAOVENDA%TYPE,  -- HIS.00262.2018
         CODMARCA                   PCMARCA.CODMARCA%TYPE);
    vrDadosRegistro                 TRecDadosRegistro;
  
    -- Prioridade
    vnPrioridade                    NUMBER;
  
    -- Dados Retorno
    TYPE TRecDadosRetorno           IS RECORD(
         vnPrioridade               NUMBER,
         vnPrioridadeAcrescimo      NUMBER,       -- HIS.00262.2018
         vvTipo                     VARCHAR2(20),
         vnPercentual               NUMBER,
         vnPercAcrescimo            NUMBER);      -- HIS.00262.2018
    vrDadosRetorno                  TRecDadosRetorno;
  
    -- Regra Específica - DDMEDICA-2225
    vCOLDESCONTOCOMPRARESSARC_OL    PCREGRASEXCECAOMED.VALOR%TYPE;
    
  BEGIN
  
    -- Inicializa Retorno para que se não achou dados retorna -1, para identificar que a procedure foi executada
    vrDadosRetorno.vnPrioridade := -1;
  
    -- Pesquisa Parâmetro
    BEGIN
      SELECT NVL(VALOR,'P')
        INTO vUSAPOLITICACOMERCIALPRODFIL
        FROM PCPARAMFILIAL
       WHERE (CODFILIAL = '99')
         AND (NOME      = 'USAPOLITICACOMERCIALPRODFILIAL');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vUSAPOLITICACOMERCIALPRODFIL := 'P';
    END;
  
    -- Regra Específica
    vCOLDESCONTOCOMPRARESSARC_OL := FOBTER_REGRA_MEDICAMENTOS('99',
                                                              'COLDESCONTOCOMPRARESSARCOPERLOG');
  
    -- Pesquisa Fornecedor e Desconto do Produto
    BEGIN
      SELECT CODFORNEC
           , DECODE(NVL(vCOLDESCONTOCOMPRARESSARC_OL,'0'),
                    '0', PERCDESC,
                    '1', PERCDESC1, 
                    '2', PERCDESC2, 
                    '3', PERCDESC3, 
                    '4', PERCDESC4, 
                    '5', PERCDESC5, 
                    '6', PERCDESC6, 
                    '7', PERCDESC7, 
                    '8', PERCDESC8, 
                    '9', PERCDESC9, 
                    '10', PERCDESC10,
                    PERCDESC) 
           , CODMARCA
        INTO vnCodFornec
           , vnPercDesc
           , vnCodMarca
        FROM PCPRODUT
       WHERE (CODPROD = pi_nCodProd);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnCodFornec := 0;
        vnPercDesc  := 0;
    END;
  
    -- Se opção Spread e Usa Política Produto/Filial, busca o desconto do Produto por Filial
    IF (pi_vOpcao = 'S') AND
       (vUSAPOLITICACOMERCIALPRODFIL = 'F') THEN
      BEGIN
        SELECT DECODE(NVL(vCOLDESCONTOCOMPRARESSARC_OL,'0'),
                    '0', PERCDESC,
                    '1', PERCDESC1, 
                    '2', PERCDESC2, 
                    '3', PERCDESC3, 
                    '4', PERCDESC4, 
                    '5', PERCDESC5, 
                    '6', PERCDESC6, 
                    '7', PERCDESC7, 
                    '8', PERCDESC8, 
                    '9', PERCDESC9, 
                    '10', PERCDESC10,
                    PERCDESC)
          INTO vnPercDesc
          FROM PCPRODFILIAL
         WHERE (CODPROD   = pi_nCodProd)
           AND (CODFILIAL = pi_vCodFilial);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -->> Se não achar a PCPRODFILIAL, mantém percentual informado na PCPRODUT
          NULL;
      END;
    END IF;
  
    -- Pesquisa Rede do Cliente
    BEGIN
      SELECT CODREDE
        INTO vnCodRede
        FROM PCCLIENT
       WHERE (CODCLI = pi_nCodCli);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnCodRede := 0;
    END;
  
    -- Prepara Sql
    vvSql := ' SELECT CODFILIAL
                    , CODPROD
                    , CODFORNEC
                    , CODCLI
                    , CODREDE ';
    IF    (pi_vOpcao = 'D') THEN -->> Desconto da Indústria
      vvSql := vvSql || ' , TIPO
                          , PERCDESC   PERCENTUAL
                          , PERCACRESC PERCACRESC
                          , CODMARCA
                       FROM PCDESCONTOOPERLOG
                      WHERE (1=1) ';
    ELSIF (pi_vOpcao = 'S') THEN-->> Spread do Operador Logístico
      vvSql := vvSql || ' , NULL TIPO
                          , PERCSPREAD PERCENTUAL
                          , 0          PERCACRESC
                          , 0          CODMARCA
                       FROM PCSPREADOPERLOG
                      WHERE (1=1) ';
    END IF;
  
    -- Where de Filial
    vvSql := vvSql || ' AND ((CODFILIAL IS NULL) OR (CODFILIAL = ' || '''' || pi_vCodFilial || '''' || '))';
  
    -- Where de Produto
    vvSql := vvSql || ' AND ((CODPROD IS NULL) OR (CODPROD = ' || NVL(pi_nCodProd,0) || '))';
  
    -- Where de Fornecedor
    vvSql := vvSql || ' AND ((CODFORNEC IS NULL) OR (CODFORNEC = ' || NVL(vnCodFornec,0) || '))';
  
    -- Where de Cliente
    vvSql := vvSql || ' AND ((CODCLI IS NULL) OR (CODCLI = ' || NVL(pi_nCodCli,0) || '))';
  
    -- Where de Rede
    vvSql := vvSql || ' AND ((CODREDE IS NULL) OR (CODREDE = ' || NVL(vnCodRede,0) || '))';
  
    -- Fitros exclusivos do Desconto da Indústria -- HIS.00262.2018
    IF (pi_vOpcao = 'D') THEN
  
      -- Where de Integradora
      vvSql := vvSql || ' AND ((INTEGRADORA IS NULL) OR (INTEGRADORA = ' || NVL(pi_nIntegradora,0) || '))';
  
      -- Where de Condição de Venda
      vvSql := vvSql || ' AND ((CODCONDICAOVENDA IS NULL) OR (CODCONDICAOVENDA = ' || NVL(pi_nCodCondicaoVenda,0) || '))';
  
      -- Where de Marca
      vvSql := vvSql || ' AND ((CODMARCA IS NULL) OR (CODMARCA = ' || NVL(vnCodMarca,0) || '))';
  
    END IF;
  
    -- Insere Dados em Arrays
    EXECUTE IMMEDIATE vvSql
      BULK COLLECT INTO vtCODFILIAL,
                        vtCODPROD,
                        vtCODFORNEC,
                        vtCODCLI,
                        vtCODREDE,
                        vtTIPO,
                        vtPERCENTUAL,
                        vtPERCACRESC,
                        vtCODMARCA;
  
    -- Se achou Dados
    IF (vtCODFILIAL.COUNT > 0) THEN
  
      -- Laço de Registros encontrados
      FOR viLaco IN vtCODFILIAL.FIRST..vtCODFILIAL.LAST LOOP
  
        -------------------------
        -- OBTEM DADOS DAS TABLES
        -------------------------
  
        vrDadosRegistro.CODFILIAL  := vtCODFILIAL(viLaco);
        vrDadosRegistro.CODPROD    := vtCODPROD(viLaco);
        vrDadosRegistro.CODFORNEC  := vtCODFORNEC(viLaco);
        vrDadosRegistro.CODCLI     := vtCODCLI(viLaco);
        vrDadosRegistro.CODREDE    := vtCODREDE(viLaco);
        vrDadosRegistro.TIPO       := vtTIPO(viLaco);
        vrDadosRegistro.PERCENTUAL := vtPERCENTUAL(viLaco);
        vrDadosRegistro.PERCACRESC := vtPERCACRESC(viLaco); -- HIS.00262.2018
        vrDadosRegistro.CODMARCA   := vtCODMARCA(viLaco);
  
        ----------------------
        -- DEFINE A PRIORIDADE
        ----------------------
  
        -- Prioridade CLIENTE
        IF    (NVL(vrDadosRegistro.CODCLI,0)  > 0)    THEN
          -- Cliente + Filial
          IF (vrDadosRegistro.CODFILIAL IS NOT NULL) THEN
            IF    (NVL(vrDadosRegistro.CODPROD,0) > 0)   THEN
              vnPrioridade := 1;
            ELSIF (NVL(vrDadosRegistro.CODFORNEC,0) > 0) OR (NVL(vrDadosRegistro.CODMARCA,0) > 0) THEN
              vnPrioridade := 2;
            ELSE
              vnPrioridade := 3;
            END IF;
          -- Cliente SEM FILIAL
          ELSE
            IF    (NVL(vrDadosRegistro.CODPROD,0) > 0)   THEN
              vnPrioridade := 4;
            ELSIF (NVL(vrDadosRegistro.CODFORNEC,0) > 0) OR (NVL(vrDadosRegistro.CODMARCA,0) > 0) THEN
              vnPrioridade := 5;
            ELSE
              vnPrioridade := 6;
            END IF;
          END IF;
        -- Prioridade REDE
        ELSIF (NVL(vrDadosRegistro.CODREDE,0) > 0)    THEN
          -- Rede + Filial
          IF (vrDadosRegistro.CODFILIAL IS NOT NULL) THEN
            IF    (NVL(vrDadosRegistro.CODPROD,0) > 0)   THEN
              vnPrioridade := 7;
            ELSIF (NVL(vrDadosRegistro.CODFORNEC,0) > 0) OR (NVL(vrDadosRegistro.CODMARCA,0) > 0) THEN
              vnPrioridade := 8;
            ELSE
              vnPrioridade := 9;
            END IF;
          -- Rede SEM FILIAL
          ELSE
            IF    (NVL(vrDadosRegistro.CODPROD,0) > 0)   THEN
              vnPrioridade := 10;
            ELSIF (NVL(vrDadosRegistro.CODFORNEC,0) > 0) OR (NVL(vrDadosRegistro.CODMARCA,0) > 0) THEN
              vnPrioridade := 11;
            ELSE
              vnPrioridade := 12;
            END IF;
          END IF;
  
        -- INICIO: Prioridade INTEGRADORA -- HIS.00262.2018 --
        ELSIF (NVL(vrDadosRegistro.INTEGRADORA,0) > 0)    THEN
          -- Integradora + Filial
          IF (vrDadosRegistro.CODFILIAL IS NOT NULL) THEN
            IF  (NVL(vrDadosRegistro.CODPROD,0) > 0) THEN
              vnPrioridade := 13;
            ELSIF    (NVL(vrDadosRegistro.CODFORNEC,0) > 0)        AND
                  (NVL(vrDadosRegistro.CODCONDICAOVENDA,0) > 0) THEN
              vnPrioridade := 14;
            ELSIF (NVL(vrDadosRegistro.CODFORNEC,0) > 0) OR (NVL(vrDadosRegistro.CODMARCA,0) > 0)  THEN
              vnPrioridade := 15;
            ELSIF (NVL(vrDadosRegistro.CODCONDICAOVENDA,0) > 0) THEN
              vnPrioridade := 16;
            ELSE
              vnPrioridade := 17;
            END IF;
          -- Integradora SEM FILIAl
          ELSE
            IF  (NVL(vrDadosRegistro.CODPROD,0) > 0) THEN
              vnPrioridade := 18;
            ELSIF (NVL(vrDadosRegistro.CODFORNEC,0) > 0)        AND
                  (NVL(vrDadosRegistro.CODCONDICAOVENDA,0) > 0) THEN
              vnPrioridade := 19;
            ELSIF (NVL(vrDadosRegistro.CODFORNEC,0) > 0) OR (NVL(vrDadosRegistro.CODMARCA,0) > 0) THEN
              vnPrioridade := 20;
            ELSIF (NVL(vrDadosRegistro.CODCONDICAOVENDA,0) > 0) THEN
              vnPrioridade := 21;
            ELSE
              vnPrioridade := 22;
            END IF;
          END IF;
        -- FIM: Prioridade INTEGRADORA -----------------------
  
        -- Prioridade FILIAL
        ELSIF (vrDadosRegistro.CODFILIAL IS NOT NULL) THEN
          IF    (NVL(vrDadosRegistro.CODPROD,0) > 0)   THEN
            vnPrioridade := 23;
          ELSIF (NVL(vrDadosRegistro.CODFORNEC,0) > 0) OR (NVL(vrDadosRegistro.CODMARCA,0) > 0) THEN
            vnPrioridade := 24;
          ELSE
            vnPrioridade := 25;
          END IF;
        -- Prioridade GERAL
        ELSE
          IF    (NVL(vrDadosRegistro.CODPROD,0) > 0)   THEN
            vnPrioridade := 26;
          ELSIF (NVL(vrDadosRegistro.CODFORNEC,0) > 0) OR (NVL(vrDadosRegistro.CODMARCA,0) > 0) THEN
            vnPrioridade := 27;
          ELSE
            vnPrioridade := 28;
          END IF;
        END IF;
  
        -------------------------
        -- ATUALIZA DADOS RETORNO
        -------------------------
  
        -- SPREAD/DESCONTO ----------------------------
        IF (NVL(vrDadosRegistro.PERCENTUAL,0) > 0) THEN
          -- Se os dados do registro atual possuem maior prioridade, retornará eles
          IF (NVL(vrDadosRetorno.vnPrioridade,0) <= 0)                  OR   -- Se primeiro Laço OU
             (NVL(vnPrioridade,0) < NVL(vrDadosRetorno.vnPrioridade,0)) THEN -- Se o prioridade maior (valor 1 mais prioritário que valor 2)
  
            vrDadosRetorno.vnPrioridade := NVL(vnPrioridade,0);
            vrDadosRetorno.vvTipo       := vrDadosRegistro.TIPO;
            vrDadosRetorno.vnPercentual := vrDadosRegistro.PERCENTUAL;
  
          END IF;
        END IF; -- FIM: DESCONTO
  
        -- ACRÉSCIMO - HIS.00262.2018 -----------------
        IF (NVL(vrDadosRegistro.PERCACRESC,0) > 0) THEN
          -- Se os dados do registro atual possuem maior prioridade, retornará eles
          IF (NVL(vrDadosRetorno.vnPrioridadeAcrescimo,0) <= 0)                  OR   -- Se primeiro Laço OU
             (NVL(vnPrioridade,0) < NVL(vrDadosRetorno.vnPrioridadeAcrescimo,0)) THEN -- Se o prioridade maior (valor 1 mais prioritário que valor 2)
  
            vrDadosRetorno.vnPrioridadeAcrescimo := NVL(vnPrioridade,0);
            vrDadosRetorno.vnPercAcrescimo       := vrDadosRegistro.PERCACRESC;
  
          END IF;
        END IF; -- FIM: ACRÉSCIMO
  
      END LOOP; -- Fim: Laço de Registros encontrados
  
   ELSE
  
      -- Se não achou dados retorna -1, para identificar que a procedure foi executada
      vrDadosRetorno.vnPrioridade := -1;
  
    END IF; -- Fim: Se achou Dados
  
    -- RETORNO DO PROCEDIMENTO - SPREAD/DESCONTO
    po_nPrioridade          := vrDadosRetorno.vnPrioridade;
    po_vTipo                := vrDadosRetorno.vvTipo;
    po_nPercentual          := vrDadosRetorno.vnPercentual;
    -- RETORNO DO PROCEDIMENTO - SOMENTE ACRÉSCIMOS -- HIS.00262.2018
    po_nPrioridadeAcrescimo := vrDadosRetorno.vnPrioridadeAcrescimo;
    po_nPercAcrescimo       := vrDadosRetorno.vnPercAcrescimo;
  
  
    -- RETORNO SE SPREAD
    IF (pi_vOpcao = 'S') THEN
      po_nPercRefDebCred := (NVL(vnPercDesc,0) - NVL(po_nPercentual,0));
      IF (NVL(po_nPercRefDebCred,0) < 0) THEN
        po_nPercRefDebCred := 0;
      END IF;
    END IF;
  
  END P_OBTER_DESC_SPREAD_OL;

 /***********************************************************************************************
  PROCEDURE: F_OBTER_RCA_LINHAPROD
  DESCRIÇÃO: DDMEDICA-1835 - Obter o RCA da Linha de Produto
  ***********************************************************************************************/
  FUNCTION F_OBTER_RCA_LINHAPROD(pi_nCodCli                    IN NUMBER,
                                 pi_nCodProd                   IN NUMBER,
                                 pi_vCodFilial                 IN VARCHAR2 DEFAULT NULL,
                                 pi_vUsarClienteLinhaFilialMed IN VARCHAR2 DEFAULT 'N') RETURN NUMBER IS
    nCODLINHAPROD PCPRODUT.CODLINHAPROD%TYPE;
    nCODUSUR      PCCLIUSURLINHAPROD.CODUSUR%TYPE;    
  BEGIN
   
    BEGIN
      SELECT CODLINHAPROD
        INTO nCODLINHAPROD
        FROM PCPRODUT
       WHERE (CODPROD = pi_nCodProd);
    EXCEPTION 
      WHEN NO_DATA_FOUND THEN
        nCODLINHAPROD := NULL;
    END;
    
    IF (NVL(pi_vUsarClienteLinhaFilialMed,'N') = 'S') THEN
      BEGIN
        SELECT CODUSUR
          INTO nCODUSUR
          FROM PCCLIUSURFILIALLINHAPROD
         WHERE (CODCLI       = pi_nCodCli) 
           AND (CODLINHAPROD = nCODLINHAPROD)
           AND (CODFILIAL    = pi_vCodFilial);
      EXCEPTION 
        WHEN NO_DATA_FOUND THEN
          nCODUSUR := NULL;
      END;
    ELSE
      BEGIN
        SELECT CODUSUR
          INTO nCODUSUR
          FROM PCCLIUSURLINHAPROD
         WHERE (CODCLI       = pi_nCodCli) 
           AND (CODLINHAPROD = nCODLINHAPROD);
      EXCEPTION 
        WHEN NO_DATA_FOUND THEN
          nCODUSUR := NULL;
      END;
    END IF;
    
    RETURN nCODUSUR;
    
  END F_OBTER_RCA_LINHAPROD;                                    
                                            
 /***********************************************************************************************
  PROCEDURE: F_RCA_PREPOSTO
  DESCRIÇÃO: DDMEDICA-1835 - Verifica se o RCA é Proposto (Vem no arquivo de pedido)
  ***********************************************************************************************/
  FUNCTION F_RCA_PREPOSTO(pi_nCodUsur       IN NUMBER,
                          pi_vCodVendedorOL IN VARCHAR2) RETURN VARCHAR2 IS
    vvRcaPreposto VARCHAR2(1);                          
  BEGIN
    BEGIN
      SELECT 'S' 
        INTO vvRcaPreposto
        FROM PCUSUARI 
       WHERE (CODUSUR = pi_nCodUsur)
         AND (TRIM(MASKPREPOSTO) = TRIM(pi_vCodVendedorOL));       
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvRcaPreposto := 'N';
    END;
    RETURN vvRcaPreposto;
  END F_RCA_PREPOSTO;                                 
                                            
  ------------------------------------------------------------------------------
  -- Função para Calcular o ST conforme Regra do Pacote - DDMEDICA-2832
  ------------------------------------------------------------------------------
  FUNCTION FCALCULAR_ST(pi_nNUMCASASDECVENDA       IN NUMBER,
                        pi_vCODFILIAL              IN VARCHAR2,
                        pi_vCODFILIANF             IN VARCHAR2,
                        pi_vCODFILIALRETIRA        IN VARCHAR2,
                        pi_nCODCLI                 IN NUMBER,
                        pi_nCODPLPAG               IN NUMBER,
                        pi_nCODPROD                IN NUMBER,
                        pi_nCODAUXILIAR            IN NUMBER,
                        pi_nCONDVENDA              IN NUMBER,
                        pi_nNUMREGIAO              IN NUMBER,
                        pi_nPRECO                  IN NUMBER,
                        pi_vITEMBNF                IN VARCHAR2,
                        pi_nVALORDESCPIS_COFINS    IN NUMBER,
                        pi_nVALORDESCICMS          IN NUMBER,
                        pi_nVALORSUFRAMA           IN NUMBER,
                        pio_vMensagem              IN OUT VARCHAR2,
                        pio_nST                    IN OUT NUMBER,
                        pio_nBASEST                IN OUT NUMBER,
                        pio_nVALORIPI              IN OUT NUMBER,
                        pio_nBASEFECP              IN OUT NUMBER,
                        pio_nALIQFECP              IN OUT NUMBER,
                        pio_nVLFECP                IN OUT NUMBER,
                        po_nPrecoSemImposto        OUT NUMBER)
  RETURN BOOLEAN IS

    -- Declaração de Variáveis da Função
    vbResult             BOOLEAN;
    vnBaseST             NUMBER;
    vnValorST            NUMBER;
    vvMensagem           VARCHAR2(2000);
    -- 
    vvSql                VARCHAR2(400);
    --
    vnPrecoSemImpostos   NUMBER;
    vnBaseFecp           NUMBER;
    vnAliqFecp           NUMBER;
    vnVlFecp             NUMBER;
    --
    vnVlStPrecificacao   NUMBER;

  BEGIN

    -- Inicializa Variáveis
    vbResult            := FALSE;
    vnBaseST            := 0;
    vnValorST           := 0;
    vvMensagem          := NULL;
    po_nPrecoSemImposto := 0;

    -- Pesquisa ST da Tributação
    BEGIN
      SELECT PCTABPR.VLST
        INTO vnVlStPrecificacao
        FROM PCTABPR
       WHERE (PCTABPR.CODPROD   = pi_nCODPROD)
         AND (PCTABPR.NUMREGIAO = pi_nNUMREGIAO);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvMensagem := 'ST da Precificação não encontrado na Região ' || pi_nNUMREGIAO;
    END;

    -- Inicio das chamadas da Tributação
    IF (vvMensagem IS NULL) THEN
    
      BEGIN
  
        -- PREÇO SEM IMPOSTO
        BEGIN
          vvSql := ' SELECT VALORSEMIMPOSTO ' ||
                   '   FROM TABLE(PKG_TRIBUTACAO.CALCULAR_PVENDA_SEM_IMPOSTO(' || '''' || pi_vCODFILIAL               || '''' || ', ' ||
                                                                                  '''' || pi_vCODFILIANF              || '''' || ', ' ||
                                                                                  '''' || pi_vCODFILIALRETIRA         || '''' || ', ' ||
                                                                                          NVL(pi_nCODCLI,0)           || ', ' ||
                                                                                          NVL(pi_nCODPLPAG,0)         || ', ' ||
                                                                                          NVL(pi_nCODPROD,0)          || ', ' ||
                                                                                          NVL(pi_nCODAUXILIAR,0)      || ', ' ||
                                                                                          NVL(pi_nCONDVENDA,0)        || ', ' ||
                                                                                  '''' || 'N'                         || '''' || ', ' || -- psVendaExportacao
                                                                                          FFORMATAR_NUMERO_TEXTO_SQL(NVL(vnVlStPrecificacao,0))   || ', ' ||
                                                                                          0                           || ', ' ||         -- pVendaSemImposto
                                                                                          FFORMATAR_NUMERO_TEXTO_SQL(ROUND(pi_nPRECO, 
                                                                                                                           pi_nNUMCASASDECVENDA)) || ', ' ||
                                                                                  '''' || 'S'                         || '''' || ', ' || -- pRetiraImposto201
                                                                                  '''' || 'S'                         || '''' || ', ' || -- pFoiPrecificadoIPI
                                                                                  '''' || NVL(pi_vITEMBNF,'N')        || '''' || '))';
          EXECUTE IMMEDIATE vvSql
                       INTO vnPrecoSemImpostos;                       
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vvMensagem := 'Não foram retornados dados para cálculo do valor sem imposto';
        END;
        
        -- Continua ...
        IF (vvMensagem IS NULL) THEN
  
          -- VALOR IPI
          BEGIN
            vvSql :=  ' SELECT VALORIPI ' ||
                        ' FROM TABLE(PKG_TRIBUTACAO.CALCULAR_IPI(' || '''' || pi_vCODFILIAL               || '''' || ', ' ||
                                                                      '''' || pi_vCODFILIANF              || '''' || ', ' ||
                                                                      '''' || pi_vCODFILIALRETIRA         || '''' || ', ' ||
                                                                              NVL(pi_nCODCLI,0)           || ', ' ||
                                                                              NVL(pi_nCODPROD,0)          || ', ' ||
                                                                              NVL(pi_nCODAUXILIAR,0)      || ', ' ||
                                                                              NVL(pi_nCONDVENDA,0)        || ', ' ||
                                                                      '''' || 'N'                         || '''' || ', ' || -- psVendaExportacao
                                                                              FFORMATAR_NUMERO_TEXTO_SQL(NVL(vnPrecoSemImpostos,0)) || ', ' ||
                                                                      '''' || 'N'                         || '''' || '))';   -- pVendaTriangular
            EXECUTE IMMEDIATE vvSql
                         INTO pio_nVALORIPI;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              pio_nVALORIPI := 0;
          END;
    
          -- BASE E VALOR DO ST
          BEGIN
            vvSql := ' SELECT BASEST
                            , ST
                            , BASEFECP
                            , ALIQFECP
                            , VLRFECP
                         FROM TABLE(PKG_TRIBUTACAO.CALCULAR_ST(' || '''' || pi_vCODFILIAL                  || '''' || ', ' || 
                                                                    '''' || pi_vCODFILIANF                 || '''' || ', ' ||
                                                                    '''' || pi_vCODFILIALRETIRA            || '''' || ', ' ||
                                                                            NVL(pi_nCODCLI,0)              || ', ' ||
                                                                            NVL(pi_nCODPLPAG,0)            || ', ' ||
                                                                            NVL(pi_nCODPROD,0)             || ', ' ||
                                                                            NVL(pi_nCODAUXILIAR,0)         || ', ' ||
                                                                            NVL(pi_nCONDVENDA,0)           || ', ' ||
                                                                    '''' || 'N'                            || '''' || ', ' || -- psVendaExportacao
                                                                             FFORMATAR_NUMERO_TEXTO_SQL(NVL(vnPrecoSemImpostos,0))     || ', ' ||
                                                                             0                             || ', ' ||         -- pPerDesconto
                                                                    '''' || NVL(pi_vITEMBNF,'N')           || '''' || ', ' || 
                                                                            FFORMATAR_NUMERO_TEXTO_SQL(NVL(pi_nVALORDESCPIS_COFINS,0)) || ', ' ||
                                                                            FFORMATAR_NUMERO_TEXTO_SQL(NVL(pi_nVALORDESCICMS,0))       || ', ' ||
                                                                            FFORMATAR_NUMERO_TEXTO_SQL(NVL(pi_nVALORSUFRAMA,0))        || ', ' ||
                                                                            'NULL'                         || ', ' ||         -- pROWID
                                                                     '''' || 'S'                           || '''' || ', ' || -- pCalculaIPI
                                                                     '''' || 'N'                           || '''' || '))';   -- pTransferencia      
            EXECUTE IMMEDIATE vvSql
                         INTO vnBaseST
                            , vnValorST
                            , vnBaseFecp
                            , vnAliqFecp
                            , vnVlFecp;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vnBaseST   := 0;
              vnValorST  := 0;
              vnBaseFecp := 0;
              vnAliqFecp := 0;
              vnVlFecp   := 0;
          END;
    
          -- Sucesso no Cálculo do ST
          vbResult := TRUE;
          
        END IF;
  
      EXCEPTION
        WHEN OTHERS THEN
          vvMensagem := 'Erro ao calcular ST da Precificação: ' || SUBSTR(SQLERRM,1,240);
      END;
      
    END IF;

    -- Verificado no Cliente que rejeita se tiver Base mas não tiver Valor
    IF (NVL(vnValorST,0) = 0) THEN
      vnBaseST := 0;
    END IF;

    -- Atualiza Retornos da Função
    pio_nST       := vnValorST;
    pio_nBASEST   := vnBaseST;
    --
    pio_nBASEFECP := vnBaseFecp;
    pio_nALIQFECP := vnAliqFecp;
    pio_nVLFECP   := vnVlFecp;
    --
    pio_vMensagem := vvMensagem;
    --
    po_nPrecoSemImposto := vnPrecoSemImpostos; -- MED-1573
    -- Retorno de Sucesso
    RETURN vbResult;

  END FCALCULAR_ST;

 /**********************************************
  Procedimento para Rebaixar CMV - DDMEDICA-4013
  **********************************************/
  procedure proc_RebaixarCMV(p_numped in number, 
                             p_data in date,
                             p_codfilial in varchar2, 
                             p_codcontarebaixacmvaapurar in number, 
                             p_codcontarebaixacmv in number, 
                             p_condvenda in number,
                             p_codcli in number) is
  
    vbutilizouverba boolean;
  
  begin
  
    for reg_itens in (select pcpedi.codprod, PCPEDI.QT, PCPEDI.NUMSEQ
                        from pcpedi
                       where (numped = p_numped)
                         and (nvl(pcpedi.vldesccmvpromocaomed,0) = 0) -- DDMEDICA-5009 - Somente Produtos sem Rabaixa e CMV da Promoção
                     ) loop

      vbutilizouverba := false;
 
      for reg in (SELECT PCVERBA.NUMVERBA,
            PCVERBA.DTEMISSAO,
            PCVERBA.DTVENC,
            pcverba.codconta,
            (SELECT SUM((NVL(PCPEDI.VLVERBACMV, 0) * NVL(PCPEDI.QT, 0)))
               FROM PCPEDI, PCPEDC
              WHERE PCPEDC.DATA BETWEEN PCAPLICVERBAI.DTINICIOVIGENCIA AND
                    PCAPLICVERBAI.DTFIMVIGENCIA
                AND PCPEDC.DTCANCEL IS NULL
                AND PCPEDC.CONDVENDA <> 4
                AND PCPEDC.POSICAO <> 'C'
                AND PCPEDC.POSICAO NOT IN ('P', 'B', 'C')
                AND PCPEDI.NUMPED = PCPEDC.NUMPED
                AND PCPEDI.NUMVERBAREBCMV = PCVERBA.NUMVERBA
                AND PCPEDI.CODPROD = PCAPLICVERBAI.CODPROD) VLVERBAUTILIZ,
            PCAPLICVERBAI.VLAPLIC,
            decode(pcaplicverbai.vlaplicunitario,null,(nvl(PCAPLICVERBAI.VLAPLIC,0) / nvl(PCAPLICVERBAI.QTVENDA,0)), pcaplicverbai.vlaplicunitario) VLVERBA_ITEM,
            pcaplicverbai.Vlaplicunitario
       FROM PCVERBA, PCAPLICVERBAI
      WHERE p_DATA BETWEEN PCAPLICVERBAI.DTINICIOVIGENCIA AND
            PCAPLICVERBAI.DTFIMVIGENCIA
        AND PCVERBA.NUMVERBA = PCAPLICVERBAI.NUMVERBA
        AND PCAPLICVERBAI.CODPROD = reg_itens.CODPROD
        and pcaplicverbai.codfilial = p_codfilial
        and pcverba.dtapuracao is null
        AND ( (p_codcli IN (SELECT VC.CODCLI FROM PCAPLICVERBAICLIENTE VC WHERE VC.NUMAPLIC = PCAPLICVERBAI.NUMAPLIC)) OR -- Lista de Clientes por Multi-Selecao
              (NVL(pcaplicverbai.codcli,0) = p_codcli) OR -- Cliente Fixo informado no Item
              ((NVL((SELECT COUNT(*) FROM PCAPLICVERBAICLIENTE VC WHERE VC.NUMAPLIC = PCAPLICVERBAI.NUMAPLIC),0) = 0) AND (NVL(pcaplicverbai.codcli,0) = 0)) ) -- Sem Lista de Clientes e Sem Cliente no Item    
        AND  NVL(PCAPLICVERBAI.CONDVENDA,0) IN (0,p_condvenda)        
        )  loop
 
 
        if nvl(reg.numverba,0) <> 0 and vbutilizouverba = false then
        
          --Verba a apurar
          if reg.codconta = p_codcontarebaixacmvaapurar then
        
        
            UPDATE PCPEDI
               SET VLCUSTOFIN  = nvl(vlcustofin,0) - nvl(reg.VLAPLICUNITARIO,0),
                   VLCUSTOREAL = nvl(VLCUSTOREAL,0) - nvl(reg.VLAPLICUNITARIO,0),
                   VLVERBACMV = nvl(reg.VLAPLICUNITARIO,0),
                   numverbarebcmv = reg.numverba
             WHERE NUMPED = P_NUMPED
               AND CODPROD = REG_ITENS.CODPROD
               AND NUMSEQ = REG_ITENS.NUMSEQ;
        
            vbutilizouverba := true;
        
          -- Verba valor definido
          elsif reg.codconta = p_codcontarebaixacmv then
        
            if Round(nvl(reg.VLVERBAUTILIZ,0), 2) < Round(nvl(reg.VLAPLIC,0), 2)
            then
        
              for reg_verba in ( SELECT NUMVERBA
                                   FROM PCAPLICVERBAI
                                  WHERE NUMVERBA = reg.NUMVERBA
                                    FOR UPDATE) loop
        
                  exit;
        
              end loop;
        
              if Round((reg_itens.qt * nvl(reg.VLVERBA_ITEM,0)), 2) <
                 Round((nvl(reg.VLAPLIC,0) - nvl(reg.VLVERBAUTILIZ,0)), 2)
              then
      
                UPDATE PCPEDI
                   SET VLCUSTOREAL = nvl(VLCUSTOREAL,0) - nvl(reg.vlverba_item,0),
                       VLCUSTOFIN  = nvl(VLCUSTOFIN,0) - nvl(reg.vlverba_item,0),
                       VLVERBACMV = nvl(reg.vlverba_item,0),
                       numverbarebcmv = reg.numverba
                 WHERE NUMPED = P_NUMPED
                   AND CODPROD = REG_ITENS.CODPROD
                   AND NUMSEQ = REG_ITENS.NUMSEQ;
      
                vbutilizouverba := true;
      
              else
                
                reg.vlverba_item := round((Round((nvl(reg.VLAPLIC,0) - nvl(reg.VLVERBAUTILIZ,0)), 2)/reg_itens.qt)  ,2);
      
                UPDATE PCPEDI
                   SET VLCUSTOREAL = nvl(VLCUSTOREAL,0) - nvl(reg.vlverba_item,0),
                       VLCUSTOFIN  = nvl(VLCUSTOFIN,0) - nvl(reg.vlverba_item,0),
                       VLVERBACMV = nvl(reg.vlverba_item,0),
                       numverbarebcmv = reg.numverba
                 WHERE NUMPED = P_NUMPED
                   AND CODPROD = REG_ITENS.CODPROD
                   AND NUMSEQ = REG_ITENS.NUMSEQ;
      
      
                vbutilizouverba := true;
      
        
              end if;
                
            end if; -- Round(nvl(reg.VLVERBAUTILIZ,0), 2) < Round(nvl(reg.VLAPLIC,0), 2)
          
          end if; -- if conta
              
        end if; -- nvl(reg.numverba,0) <> 0 and vbutilizouverba = false
 
      end loop; -- loop verba

    end loop; -- loop pcpedi
          
  end proc_RebaixarCMV;

 /*************************************************************************
  Nome        : P_ATU_DISTRIB_PEDIDO_INICIAL
  Objetivo    : Garantir no Pedido Inicial a Distribuição dos Produtos 
                que ficaram nele - DDMEDICA-6036
  Parametros  : pi_nNumPed : Filtro Número do Pedido Inicial
                pi_vMEDPERMITEDISTRIBDIFRCA : Parâmetro que permite Múltiplas Distribuições no Pedido
  ************************************************************************/
  PROCEDURE P_ATU_DISTRIB_PEDIDO_INICIAL(pi_nNumPedInicial           IN NUMBER,
                                         pi_vMEDPERMITEDISTRIBDIFRCA IN VARCHAR2) IS
    vvCodDistrib PCPRODUT.CODDISTRIB%TYPE;
  BEGIN
  
    -- Se Permitir incluir no pedido itens de distribuição diferente do RCA
    IF (NVL(pi_vMEDPERMITEDISTRIBDIFRCA,'N') = 'S') THEN
  
      -- Pesquisa o Código da Distribuição de um dos Produtos do Pedido Inicial
      BEGIN
        SELECT PCPRODUT.CODDISTRIB
          INTO vvCodDistrib
          FROM PCPEDI
             , PCPRODUT
         WHERE (PCPEDI.CODPROD = PCPRODUT.CODPROD)
           AND (PCPEDI.NUMPED  = pi_nNumPedInicial)
           AND (PCPRODUT.CODDISTRIB IS NOT NULL)
           AND (ROWNUM         = 1);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vvCodDistrib := NULL;
      END;
  
      -- Atualizar a Distribuição do Pedido
      IF (vvCodDistrib IS NOT NULL) THEN
        UPDATE PCPEDC
           SET CODDISTRIB = vvCodDistrib
         WHERE (NUMPED = pi_nNumPedInicial);
      END IF;

    END IF;
   
  END P_ATU_DISTRIB_PEDIDO_INICIAL;    

 /*****************'****************************************************
  FUNÇÃO   : F_RETORNAR_PLPAG_ITEM
  DESCRIÇÃO: Retorna o Plano de Pagamento do Item
  *********************************************************************/
  FUNCTION F_RETORNAR_PLPAG_ITEM(pi_vTipoPrazoMedicamen IN VARCHAR2,
                                 pi_nCodProd            IN NUMBER,
                                 pi_nCodPlPag_PCPEDI    IN NUMBER,
                                 pi_nCodPlPag_PCPEDC    IN NUMBER,
                                 pi_nCodPlPag_ETICO     IN NUMBER,
                                 pi_nCodPlPag_GENERICO  IN NUMBER,
                                 pi_vGrupoFaturamento   IN VARCHAR2) 
  RETURN NUMBER IS
  
    -- Retorno da Função
    vnRetCodPlPag      PCPLPAG.CODPLPAG%TYPE;
    -- Grupo Faturamento
    vvGrupoFaturamento PCPRODUT.GRUPOFATURAMENTO%TYPE;
    
  BEGIN

    -- Inicializa Plano de Pagamento Por Linha de Prazo
    IF (NVL(pi_vTipoPrazoMedicamen,'2') = '4') THEN
    
       -- Pega Plano de Pagamento do Item
       vnRetCodPlPag := pi_nCodPlPag_PCPEDI;
       -- Se não gravou no item Pega no Pedido
       IF (NVL(vnRetCodPlPag,0) = 0) THEN
         vnRetCodPlPag := pi_nCodPlPag_PCPEDC;
       END IF;
       
    ELSE
    
      -- Inicializa Plano de Pagamento Por Grupo de Faturamento
      IF (NVL(pi_nCodPlPag_ETICO,0)    > 0) AND
         (NVL(pi_nCodPlPag_GENERICO,0) > 0) THEN
         
        -- Pega Grupo de Faturamento do Parâmetro
        vvGrupoFaturamento := pi_vGrupoFaturamento;

        -- Se o Grupo Faturamento passado no parâmetro estava nulo no item do pedido, busca do produto
        IF (vvGrupoFaturamento IS NULL) THEN
          BEGIN
            SELECT GRUPOFATURAMENTO
              INTO vvGrupoFaturamento
              FROM PCPRODUT
             WHERE (CODPROD = pi_nCodProd);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vvGrupoFaturamento := NULL;
          END;
        END IF; 
        
        -- Pega Plano de Pagamento Ético
        IF (NVL(vvGrupoFaturamento,' ') = 'E') THEN
          vnRetCodPlPag := pi_nCodPlPag_ETICO;
        -- Pega Plano de Pagamento Genérico/Similar
        ELSE
          vnRetCodPlPag := pi_nCodPlPag_GENERICO;
        END IF;
        
      -- Inicializa Plano de Pagamento Por Pedido
      ELSE
      
        -- Pega Plano de Pagamento do Pedido
        vnRetCodPlPag := pi_nCodPlPag_PCPEDC;
        
      END IF;
      
    END IF;  
    
    -- Retorno da Função
    RETURN vnRetCodPlPag;
     
  END F_RETORNAR_PLPAG_ITEM;

  /*******************************************************************************
   Nome         : P_REL_OBTEM_DESC_OLPE
   Descricão    : Procedimento para Retornar o Desconto do OL e PE
   Alteração    : Anderson Silva - 22/06/2021 - Criação do Procedimento 
                  DDMEDICA-6837 - Usada para descontinar a FCT_MED_OBTEM_DESC_OLPE
  ********************************************************************************/
  PROCEDURE P_REL_OBTEM_DESC_OLPE(pi_nIntegradora      IN NUMBER,
                                  pi_vCodFilial        IN VARCHAR2,
                                  pi_nCodCli           IN NUMBER,
                                  pi_nCodCondicaoVenda IN NUMBER,
                                  pi_nCodProdAdicional IN NUMBER,
                                  pi_nQtde             IN NUMBER)
  IS
  
    -- String Retorno
    vvRetString VARCHAR2(250);
  
    -- Variáveis para uso na função de obter Promoção
    TYPE TRecRetornoPromocao   IS RECORD(
         vvTipoPromoPrecoDesc  VARCHAR2(1),
         vnCodDesconto         PCDESCONTO.CODDESCONTO%TYPE,
         vnCodPromocaoMed      PCDESCONTO.CODPROMOCAOMED%TYPE,
         vnPrecoFixo           PCDESCONTO.PRECOFIXOPROMOCAOMED%TYPE,
         vnPercDesc            PCDESCONTO.PERCDESC%TYPE,
         vnPercDescFin         PCDESCONTO.PERCDESCFIN%TYPE,
         vnInicioIntervaloQt   PCDESCONTO.INICIOINTERVALOPROMOCAOMED%TYPE,
         vnVlDescCmv           NUMBER,        -- DDMEDICA-5009
         vnPerDescCmv          NUMBER,        -- DDMEDICA-5009
         vnNumVerba            NUMBER,        -- DDMEDICA-5009
         vnValorCotaNumVerba   NUMBER,        -- DDMEDICA-5009
         vvSemVerbaVlDescCmv   VARCHAR2(255), -- DDMEDICA-5009
         vnPercMarkupMed       NUMBER,        -- DDMEDICA-6837
         vvOcorreramErros      VARCHAR2(1),
         vvMsgErros            VARCHAR2(2000));
    vrRetornoPromocao          TRecRetornoPromocao;
  
    -- Dados Cliente
    vnCodUsurCli               PCINTEGRADORA.CODUSUR%TYPE;
    vnCodPlPagCli              PCPLPAG.CODPLPAG%TYPE;
    vnCodPraca                 PCCLIENT.CODPRACA%TYPE;
    vvClasseVenda              PCCLIENT.CLASSEVENDA%TYPE;
  
    -- Dados Integradora
    vnCodUsur                  PCINTEGRADORA.CODUSUR%TYPE;
    vvOpcaoRcaPedido           PCINTEGRADORA.OPCAORCAPEDIDO%TYPE;
    vvTipoFv                   PCINTEGRADORA.TIPOFV%TYPE;
    vvaplicaracrescimopolitica PCINTEGRADORA.APLICARACRESCIMOPOLITICA%TYPE;
    vnLayout                   PCINTEGRADORA.LAYOUT%TYPE;
  
    -- Dados Condição Venda
    vnTipoPlPag                PCCONDICAOVENDA.TIPOPLPAG%TYPE;
    vnCodPlPag                 PCPLPAG.CODPLPAG%TYPE;
  
    -- Dados Produto
    vnCodLinhaPrazo            PCPRODUT.CODLINHAPRAZO%TYPE;
  
    -- Dados Plano Pagamento
    vnNumDias                  PCPLPAG.NUMDIAS%TYPE;
  
    -- Retornos Adicionais da Procedure PRC_MED_OBTEM_DESC_INTEGRADORA
    pBasecreddebrca            pcdesconto.basecreddebrca%type;
    pCreditasobrepolitica      pcdesconto.creditasobrepolitica%type;
    pAlteraptabela             pcdesconto.alteraptabela%type;
    pDescpbaserca              pcdesconto.percdesc%type;
    pcreditasobreptabela_quant pcdescquant.creditasobreptabela%type;
    pbasedebcredrca_quant      pcdescquant.basecreddebrca%type;
    ppercbaserca_quant         pcdescquant.percdesc%type;
    pnPerBonific               NUMBER;
    pnPerComerc                NUMBER;
    pnPercDescFin              NUMBER;
    vsocorreramerros           VARCHAR2(1);
    vsmensagemdescontos        VARCHAR2(2000);
  
    -- Outras Variáveis Auxiliares
    vnCodPromocaoMed           NUMBER;
    vvTipoPrecoDesconto        VARCHAR2(1);
    vnPerDesc                  PCDESCONTO.PERCDESC%TYPE;
    vnPercDescFin              PCDESCONTO.PERCDESCFIN%TYPE;
    vnPrecoFixo                PCDESCONTO.PRECOFIXO%TYPE;
  
    -- Região
    vnNumRegiao                PCPRACA.NUMREGIAO%TYPE;
    
    -- Código do Produto
    vnCodProd                  PCTABPR.CODPROD%TYPE;
    
    -- Preço Venda
    vnPrecoVenda1              PCTABPR.PVENDA1%TYPE;
    
    -- Custo Financeiro
    vnCustoFin                 PCEST.CUSTOFIN%TYPE;
  
    -- PROCEDIMENTO PARA OBTEM VALOR DOS PARÂMETROS
    procedure proc_pcparamfilial (p_codfilial in pcfilial.codigo%type,
                                  p_nome       in pcparamfilial.nome%type,
                                  p_padrao     in pcparamfilial.valor%type,
                                  p_valor      out pcparamfilial.valor%type) is
     vsnome      pcparamfilial.nome%type;
    begin
      vsnome := upper(trim(p_nome));
  
      begin
        select nvl(p.valor,p_padrao)
          into p_valor
          from pcparamfilial p
         where upper(trim(p.nome)) = vsnome
           and  p.codfilial = p_codfilial;
      exception
        when no_Data_found then
          BEGIN
            select nvl(p.valor,p_padrao)
              into p_valor
              from pcparamfilial p
             where upper(trim(p.nome)) = vsnome
               and  p.codfilial = '99';
          exception
            when no_data_found then
               p_valor := p_padrao;
          end;
        when others then
           p_valor  := p_padrao;
      end;
    end proc_pcparamfilial ;
  
  /*******************************************************************************
                     INICIO DO PROCESSAMENTO PRINCIPAL
   *******************************************************************************/
  BEGIN

    -- Limpa Tabela Temporária  
    EXECUTE IMMEDIATE ' TRUNCATE TABLE PCMED_SELPROMOCAO ';
  
    -- String Retorno
    vvRetString := NULL;
  
    -- Indentificador de Promoção
    vnCodPromocaoMed    := NULL;
    -- Indentificador de Tipo Preço/Desconto
    vvTipoPrecoDesconto := NULL;
  
    -- DADOS CLIENTE
    BEGIN
      SELECT PCCLIENT.CODUSUR1
           , PCCLIENT.CODPLPAG
           , PCCLIENT.CODPRACA
           , PCCLIENT.CLASSEVENDA
        INTO vnCodUsurCli
           , vnCodPlPagCli
           , vnCodPraca
           , vvClasseVenda
        FROM PCCLIENT
       WHERE (PCCLIENT.CODCLI = pi_nCodCli);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnCodUsurCli  := NULL;
        vnCodPlPagCli := NULL;
        vnCodPraca    := NULL;
        vvClasseVenda := NULL;
    END;
  
    -- DADOS INTEGRADORA
    BEGIN
      SELECT PCINTEGRADORA.CODUSUR
           , PCINTEGRADORA.OPCAORCAPEDIDO
           , PCINTEGRADORA.TIPOFV
           , PCINTEGRADORA.APLICARACRESCIMOPOLITICA
           , PCINTEGRADORA.LAYOUT
        INTO vnCodUsur
           , vvOpcaoRcaPedido
           , vvTipoFv
           , vvaplicaracrescimopolitica
           , vnLayout
        FROM PCINTEGRADORA
       WHERE (PCINTEGRADORA.INTEGRADORA = pi_nIntegradora);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnCodUsur                  := NULL;
        vvOpcaoRcaPedido           := NULL;
        vvTipoFv                   := NULL;
        vvaplicaracrescimopolitica := NULL;
        vnLayout                   := NULL;
    END;
    IF (vvOpcaoRcaPedido = 'C') THEN
      vnCodUsur := vnCodUsurCli;
    END IF;
    
    -- Pesquisa a Região para a UF
    BEGIN
      SELECT PCTABPRCLI.NUMREGIAO
        INTO vnNumRegiao
        FROM PCTABPRCLI
       WHERE (PCTABPRCLI.CODCLI      = pi_nCodCli)
         AND (PCTABPRCLI.CODFILIALNF = pi_vCodFilial);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vnNumRegiao := NULL;
    END;
    -- Se não achou Região na PCTABPRCLI
    IF (vnNumRegiao IS NULL) THEN
      -- Obtem a Regiao do Cliente na Praça
      BEGIN
        SELECT PCPRACA.NUMREGIAO
          INTO vnNumRegiao
          FROM PCPRACA
         WHERE (PCPRACA.CODPRACA = vnCodPraca);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnNumRegiao := NULL;
      END;
    END IF;

    ------------------------
    ------------------------
    -- CURSOR DE PRODUTOS --
    ------------------------
    ------------------------
    FOR vc_produtos IN (SELECT PCPRODUT.CODPROD
                             , PCPRODUT.DESCRICAO
                             , PCMARCA.MARCA
                          FROM PCPRODUT
                             , PCMARCA
                         WHERE PCPRODUT.CODMARCA = PCMARCA.CODMARCA(+)
                           AND ( (PCPRODUT.CODPROD IN (SELECT PCPEDI.CODPROD
                                                         FROM PCPEDI
                                                        WHERE (PCPEDI.CODCLI = pi_nCodCli))) OR
                                 (PCPRODUT.CODPROD = pi_nCodProdAdicional) )  
                         ORDER BY PCPRODUT.CODPROD) LOOP
                         
      -- Código do Produto
      vnCodProd := vc_produtos.CODPROD; 
      
      -- Preço Venda
      BEGIN
        SELECT PVENDA1  
          INTO vnPrecoVenda1
          FROM PCTABPR
         WHERE (NUMREGIAO = vnNumRegiao)
           AND (CODPROD   = vnCodProd);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnPrecoVenda1 := 0;
      END;         
  
      -- Custo Financeiro
      BEGIN
        SELECT CUSTOFIN
          INTO vnCustoFin
          FROM PCEST
         WHERE (CODFILIAL = pi_vCodFilial)
           AND (CODPROD   = vnCodProd);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnCustoFin := 0;
      END;     
      
      -- DADOS PRODUTO
      BEGIN
        SELECT PCPRODUT.CODLINHAPRAZO
          INTO vnCodLinhaPrazo
          FROM PCPRODUT
         WHERE (PCPRODUT.CODPROD = vnCodProd);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnCodLinhaPrazo := NULL;
      END;
    
      -- DADOS CONDIÇÃO DE VENDA
      BEGIN
        SELECT PCCONDICAOVENDA.TIPOPLPAG
          INTO vnTipoPlPag
          FROM PCCONDICAOVENDA
         WHERE (PCCONDICAOVENDA.CODCONDICAOVENDA = pi_nCodCondicaoVenda);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnTipoPlPag := NULL;
      END;
      IF (NVL(vnTipoPlPag,0) = 2) THEN
        vnCodPlPag := vnCodPlPagCli;
      ELSE
        BEGIN
          SELECT PCCONDVENDALINHA.CODPLPAG
            INTO vnCodPlPag
            FROM PCCONDVENDALINHA
           WHERE (PCCONDVENDALINHA.CODCONDICAOVENDA = pi_nCodCondicaoVenda)
             AND (PCCONDVENDALINHA.CODLINHAPRAZO    = vnCodLinhaPrazo);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnCodPlPag := NULL;
        END;
      END IF;
    
      -- DADOS PLANO PAGAMENTO
      BEGIN
        SELECT PCPLPAG.NUMDIAS
          INTO vnNumDias
          FROM PCPLPAG
         WHERE (PCPLPAG.CODPLPAG = vnCodPlPag);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnNumDias := 0;
      END;
      
      -- Inicializa Valores da Promoção
      vnCodPromocaoMed    := NULL;
      vvTipoPrecoDesconto := NULL;
      vnPerDesc           := NULL;
      vnPercDescFin       := NULL;
      vnPrecoFixo         := NULL;
      pnPerBonific        := NULL;
      pnPerComerc         := NULL;

      ------------------------------------------------------------------------------
      -- Pega valores da Promoção - INTEGRADORA WINTHOR (quando usa IMP_EXP_OPERLOG)
      ------------------------------------------------------------------------------
      IF (vnLayout = 16) THEN
        P_OBTEM_DESC_PROMOCAO(1,
                              'N',  -- Não grava Tabela Temporária,
                              'N',  -- Não executa Commit
                              TRUNC(SYSDATE),
                              pi_vCodFilial,
                              NULL, -- pi_vTipoPrazoMedicam
                              NULL, -- pi_nNumRegiao
                              vnCodUsur,
                              'F',  -- pi_vOrigemPed
                              vvTipoFv,
                              vnCodPlPag,
                              pi_nCodCondicaoVenda,
                              NULL, -- Não passa o Código da Promoção do Produto
                              pi_nCodCli,
                              vnCodProd,
                              pi_nQtde,
                              vrRetornoPromocao.vvTipoPromoPrecoDesc,
                              vrRetornoPromocao.vnCodDesconto,
                              vrRetornoPromocao.vnCodPromocaoMed,
                              vrRetornoPromocao.vnPrecoFixo,
                              vrRetornoPromocao.vnPercDesc,
                              vrRetornoPromocao.vnPercDescFin,
                              vrRetornoPromocao.vnInicioIntervaloQt,
                              vrRetornoPromocao.vnVlDescCmv,         -- DDMEDICA-5009
                              vrRetornoPromocao.vnPerDescCmv,        -- DDMEDICA-5009
                              vrRetornoPromocao.vnNumVerba,          -- DDMEDICA-5009
                              vrRetornoPromocao.vnValorCotaNumVerba, -- DDMEDICA-5009
                              vrRetornoPromocao.vvSemVerbaVlDescCmv, -- DDMEDICA-5009
                              vrRetornoPromocao.vvOcorreramErros,
                              vrRetornoPromocao.vvMsgErros,
                              NULL,
                              'N',                                    -- 5685.084449.2016
                              NULL,                                   -- 5685.084449.2016
                              vnPrecoVenda1,                          -- DDMEDICA-6841 - Usar o Preço Tabela sem Taxa no Cálculo do Desconto do Markup
                              vnCustoFin,                             -- DDMEDICA-6841
                              vrRetornoPromocao.vnPercMarkupMed);     -- DDMEDICA-6837
    
        -- Se a Promoção Vigente for de Desconto
        IF    (vrRetornoPromocao.vvTipoPromoPrecoDesc = 'D') THEN
          vnCodPromocaoMed    := vrRetornoPromocao.vnCodPromocaoMed;
          vvTipoPrecoDesconto := vrRetornoPromocao.vvTipoPromoPrecoDesc;
          vnPerDesc           := vrRetornoPromocao.vnPercDesc;
          vnPercDescFin       := vrRetornoPromocao.vnPercDescFin;
          vnPrecoFixo         := 0;
        -- Se a Promoção Vigente for de Preço
        ELSIF (vrRetornoPromocao.vvTipoPromoPrecoDesc = 'P') THEN
          vnCodPromocaoMed    := vrRetornoPromocao.vnCodPromocaoMed;
          vvTipoPrecoDesconto := vrRetornoPromocao.vvTipoPromoPrecoDesc;
          vnPerDesc           := 0;
          vnPercDescFin       := vrRetornoPromocao.vnPercDescFin;
          vnPrecoFixo         := vrRetornoPromocao.vnPrecoFixo;
        END IF;
      END IF;
    
      -- SE NÃO ACHOU PROMOÇÃO
      IF (vnCodPromocaoMed IS NULL) THEN
    
        ---------------------------------------
        -- Pega valores da Política de Desconto
        ---------------------------------------
        P_OBTEM_DESC_INTEGRADORA(vnCodProd,
                                 pi_nQtde,
                                 pi_nCodCondicaoVenda,
                                 pi_nCodCli,
                                 TRUNC(SYSDATE),
                                 pi_vCodFilial,
                                 vnNumRegiao,
                                 vnCodUsur,
                                 'F',         -- pi_vOrigemPed
                                 vnCodProd,   -- pi_nCodProdPrinc,
                                 4,           -- pi_nNumcasasdecvenda
                                 vnCodPlPag,
                                 vnNumDias,
                                 vvClasseVenda,
                                 vnCodPraca,
                                 'N',         -- pi_snaousarautdebcredpoldesc
                                 'N',         -- pi_sUsaprioritaria
                                 vvTipoFv,
                                 pBasecreddebrca,
                                 pCreditasobrepolitica,
                                 pAlteraptabela,
                                 pDescpbaserca,
                                 pcreditasobreptabela_quant,
                                 pbasedebcredrca_quant,
                                 ppercbaserca_quant,
                                 vrRetornoPromocao.vnPercDesc,
                                 pnPerBonific,
                                 pnPerComerc,
                                 vrRetornoPromocao.vnPercDescFin,
                                 pnPercDescFin,
                                 vsocorreramerros,
                                 vsmensagemdescontos,
                                 vnCodLinhaPrazo,
                                 'N', -- pi_stratarrestricaoacrescimo
                                 vvaplicaracrescimopolitica,
                                 vrRetornoPromocao.vnCodDesconto,
                                 vrRetornoPromocao.vnCodPromocaoMed,
                                 vrRetornoPromocao.vnPrecoFixo,
                                 vrRetornoPromocao.vvTipoPromoPrecoDesc,
                                 vrRetornoPromocao.vnVlDescCmv,         -- DDMEDICA-5009
                                 vrRetornoPromocao.vnPerDescCmv,        -- DDMEDICA-5009
                                 vrRetornoPromocao.vnNumVerba,          -- DDMEDICA-5009
                                 vrRetornoPromocao.vnValorCotaNumVerba, -- DDMEDICA-5009
                                 vrRetornoPromocao.vvSemVerbaVlDescCmv, -- DDMEDICA-5009
                                 vrRetornoPromocao.vvMsgErros,
                                 'N', -- pi_vGravaTabTemp,
                                 'N', -- pi_vExecutaCommit
                                 pi_nIntegradora,                         -- DDMEDICA-6837
                                 vnPrecoVenda1,                           -- DDMEDICA-6837
                                 vnCustoFin,                              -- DDMEDICA-6837
                                 vrRetornoPromocao.vnInicioIntervaloQt,   -- DDMEDICA-6837
                                 vrRetornoPromocao.vnPercMarkupMed);      -- DDMEDICA-6837
  
        -- Se a Promoção Vigente for de Desconto
        IF    (vrRetornoPromocao.vvTipoPromoPrecoDesc = 'D') THEN
          vnCodPromocaoMed    := vrRetornoPromocao.vnCodPromocaoMed;
          vvTipoPrecoDesconto := 'C'; -- Condição de Venda
          vnPerDesc           := vrRetornoPromocao.vnPercDesc;
          vnPercDescFin       := vrRetornoPromocao.vnPercDescFin;
          vnPrecoFixo         := 0;
        -- Se a Promoção Vigente for de Preço
        ELSIF (vrRetornoPromocao.vvTipoPromoPrecoDesc = 'P') THEN
          vnCodPromocaoMed    := vrRetornoPromocao.vnCodPromocaoMed;
          vvTipoPrecoDesconto := 'C'; -- Condição de Venda
          vnPerDesc           := 0;
          vnPercDescFin       := vrRetornoPromocao.vnPercDescFin;
          vnPrecoFixo         := vrRetornoPromocao.vnPrecoFixo;
        END IF;
    
      END IF;
      
      -- Insere na Tabela Temporária
      INSERT INTO PCMED_SELPROMOCAO
                ( CODPROMOCAOMED
                , CODDESCONTO
                , TIPOPROMOCAO
                , PERCDESC
                , PERCDESCFIN
                , PRECOFIXO
                , PERCBONIFICMERC
                , PERCDESCBASERCA ) 
         VALUES ( vnCodPromocaoMed
                , vnCodProd
                , vvTipoPrecoDesconto
                , vnPerDesc
                , vnPercDescFin
                , vnPrecoFixo
                , pnPerBonific
                , pnPerComerc );
      
    END LOOP; -- FIM: CURSOR DE PRODUTOS --
    
    COMMIT;
         
  END P_REL_OBTEM_DESC_OLPE;  
  
 /***********************************************************************************************
  FUNÇÃO...: F_POSSUIVENDADUPLIC
  DESCRIÇÃO: Função para verificar se possui venda duplicada durante um determinado tempo(dia/hora/mint) 
  ***********************************************************************************************/
  FUNCTION F_POSSUIVENDADUPLIC(pi_vCgcCli            IN VARCHAR2,
                               pi_nIntegradora       IN NUMBER,
                               pi_dDtaberturapedpalm IN DATE,
                               pi_nCodUsur           IN NUMBER,
                               pi_nNumpedRca         IN NUMBER) RETURN boolean IS
                                   
    vbreturn   boolean;
    
    vnnumpedrca          pcpedretorno.numpedrca%TYPE;
    vvcodusur            pcpedretorno.codusur%TYPE;
    vvcgccli             pcpedretorno.cgccli%TYPE;
    vddtaberturapedpalm  pcpedretorno.dtaberturapedpalm%TYPE;
    vnintegradora        pcpedretorno.integradora%TYPE; 
    vnnumped             pcpedc.numped%TYPE;  
    vddata               pcpedc.data%TYPE;
    vnhora               pcpedc.hora%TYPE;
    vnminuto             pcpedc.minuto%TYPE;
    vntipofv             pcpedc.tipofv%TYPE;
    
    vvRetParamHrIntegradora PCPARAMINTEGRADORAMED.VALOR%TYPE;
    vvHoraDB             VARCHAR2(2);
    vvMinutDB            VARCHAR2(2);
    vvHoraPed            VARCHAR2(2);
    vvMinutPed           VARCHAR2(2);
    vnTotPed             NUMBER;
    vnTotQtPed           NUMBER;
    vnTotPedAtual        NUMBER;
    vnTotQtPedAtual      NUMBER; 
    vvCodProdol          pcpedifv.codprodol%TYPE;
    vbChecaItem          BOOLEAN;
    vnQtProd             NUMBER; 
  BEGIN
    vbreturn := false;
    -- Verifica se tem o parametro de horas gravado no banco de dados
    -- caso tenha e pq ele quer chegar a duplicidade do pedido no intervalo de horas
    BEGIN
      SELECT NVL(PCPARAMINTEGRADORAMED.VALOR,'0')
        INTO vvRetParamHrIntegradora
        FROM PCPARAMINTEGRADORAMED
       WHERE (PCPARAMINTEGRADORAMED.NOME        = 'HORASNAOPERMITEDUPLICPED')
         AND (PCPARAMINTEGRADORAMED.INTEGRADORA = pi_nIntegradora); 
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vvRetParamHrIntegradora := NULL;
        Return false;
    END; 
    
    if vvRetParamHrIntegradora is not null then           
      -- Preeche Arrray a partir das vendas do cliente e do rca
      FOR aArray_Vendas IN (SELECT r.numpedrca
                                   , r.codusur
                                   , r.cgccli
                                   , r.dtaberturapedpalm
                                   , r.integradora
                                   , p.numped
                                   , P.codcli
                                   , p.data
                                   , p.hora
                                   , p.minuto
                                   , p.tipofv
                              from pcpedretorno r
                                   , pcpedc p
                             where (r.numped = p.numped)
                               and (nvl(p.posicao, 'C') <> 'C')
                               and (r.dtaberturapedpalm >= (SYSDATE - 7))
                               and (r.cgccli = pi_vCgcCli) 
                               and (r.integradora = pi_nIntegradora)) LOOP                               
        BEGIN
          -- hora e mint atual do banco
          SELECT To_Char(sysdate, 'HH24') as HORA,
                 To_Char(sysdate, 'MI') as MINUT 
            INTO vvHoraDB,
                 vvMinutDB
            FROM dual;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vvHoraDB  := '0';
              vvMinutDB := '0';
        END;
        
        vbChecaItem := false; 
        
        -- testando hora e minuto do banco com a hora e minuto do pedido   
        if  ((aArray_Vendas.Hora + TO_NUMBER(vvRetParamHrIntegradora)) >  vvHoraDB ) or
             (((aArray_Vendas.Hora + TO_NUMBER(vvRetParamHrIntegradora)) = vvHoraDB ) and (aArray_Vendas.Minuto > vvMinutDB) )  then        
          vbChecaItem := true;
        end if;            
        
        if (vbChecaItem) then
        -- itens do pedido já existe na pcpedc
          select COUNT(*), SUM(QT)
            into vnTotPed, vnTotQtPed
            from pcpedifv
           where (pcpedifv.numpedrca = aArray_Vendas.Numpedrca)
             and (pcpedifv.codusur = aArray_Vendas.Codusur)
             and (pcpedifv.cgccli = aArray_Vendas.Cgccli) 
             and (pcpedifv.dtaberturapedpalm = aArray_Vendas.Dtaberturapedpalm);
                                 
         -- mesmo select como pedido atual
          select COUNT(*), SUM(QT)
            into vnTotPedAtual, vnTotQtPedAtual
            from pcpedifv
           where (pcpedifv.numpedrca = pi_nNumpedRca)
             and (pcpedifv.codusur = pi_nCodUsur)
             and (pcpedifv.cgccli = pi_vCgcCli) 
             and (pcpedifv.dtaberturapedpalm = pi_dDtaberturapedpalm);
                         
          -- checando se a Count e o Sum(Qt) sao iguais do atual qto do banco
          -- se forem iguais, chegar se os produtos tb são iguais                    
          if (vnTotPed = vnTotPedAtual) and (vnTotQtPed =  vnTotQtPedAtual) then 
            vnQtProd := 0;          
           -- itens do pedido já existe na pcpedc
            FOR aArray_Prod IN (select CODAUXILIAR
                                  from pcpedifv
                                 where (pcpedifv.numpedrca = aArray_Vendas.Numpedrca)
                                   and (pcpedifv.codusur = aArray_Vendas.Codusur)
                                   and (pcpedifv.cgccli = aArray_Vendas.Cgccli) 
                                   and (pcpedifv.dtaberturapedpalm = aArray_Vendas.Dtaberturapedpalm)) LOOP
           -- mesmo select como pedido atual
              BEGIN
                select Count(*)
                  into vvCodProdol
                  from pcpedifv
                 where (pcpedifv.numpedrca = pi_nNumpedRca)
                   and (pcpedifv.codusur = pi_nCodUsur)
                   and (pcpedifv.cgccli = pi_vCgcCli) 
                   and (pcpedifv.dtaberturapedpalm = pi_dDtaberturapedpalm)
                   and (pcpedifv.CODAUXILIAR = aArray_Prod.CODAUXILIAR);
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  vvCodProdol := 0;
                  Return false;
              END;
              
              -- se q qtda de produtos e e qtda dos produtos forem iguamsi
              -- então chega se um produto for difeente da lista
              -- e armazena na vnQtProd
              if vvCodProdol > 0 then                                       
                vnQtProd := vnQtProd + 1;
              end if;                    
              
              if vnTotPedAtual <> vnQtProd then
                vbreturn := false;    
              else
                vbreturn := true;
              end if;                
                  
            END LOOP;   
   
          end if; 
            
        end if;  
            
      END LOOP;      
      
    end if;  
      
    -- Retorno
    RETURN vbreturn;
    
  EXCEPTION
    WHEN OTHERS THEN
      RETURN FALSE;    

  END F_POSSUIVENDADUPLIC;  

END INTEGRADORACOMPLE_MED;