CREATE OR REPLACE PACKAGE BODY PKG_FUNCOES_OPERADOR_LOGISTICO
/***********************************************************************************************
  Package de Processos Específicos de Geração de Dados do Módulo de Medicamentos
  ------------------------------------     Historico     ---------------------------------------
  Data        Responsável        Tarefa          Comentario
  10/01/2023  Anderson Silva     DDVENDAS-38983  Criação da Package
 ************************************************************************************************/
IS

  ------------------------------------------------------------------------------
  -- Funcao para Verificar se Usa Regra Especifica de Medicamentos --
  -------------------------------------------------------------------
  FUNCTION FUSA_REGRA_MEDICAMENTOS(pi_vCodFilial IN VARCHAR2,
                                   pi_vNome      IN VARCHAR2)
  RETURN VARCHAR2 IS
    vvRetUsaRegraMedicamentos VARCHAR2(200);
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
        IF (vvMascara IS NULL) THEN
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

  /*******************************************************************************
   Nome      : F_VALIDACONDICAOVENDA
   Descricão : Procedimento para Carregar a(s) Condições Válidas do Cliente
  ********************************************************************************/                                       
  FUNCTION F_VALIDACONDICAOVENDA (P_CODCLI                 IN PCCLIENT.CODCLI%TYPE,
                                  P_INTEGRADORA            IN PCINTEGRADORA.INTEGRADORA%TYPE,
                                  P_TIPOSELECAOCONDICAO    IN PCINTEGRADORA.TIPOSELECAOCONDICAO%TYPE,
                                  P_TIPOPRAZO              IN PCPEDRETORNO.TIPOPRAZO%TYPE,
                                  P_CODFILIAL              IN PCFILIAL.CODIGO%TYPE,
                                  P_PRAZO                  IN PCPEDRETORNO.PRAZO%TYPE,
                                  P_CODPRAZO               IN PCPEDRETORNO.CODPRAZO%TYPE,
                                  P_CODIGOPROJETO          IN PCPEDRETORNO.codigoprojeto%TYPE,
                                  P_CODCONDICAOVENDA       IN PCPEDRETORNO.CODCONDICAOVENDA%TYPE) RETURN NUMBER
  IS
    VNCODCONDICAOVENDA         PCCONDICAOVENDA.CODCONDICAOVENDA%TYPE;
    VSDESCRICAOCONDVENDA       PCCONDICAOVENDA.DESCRICAO%TYPE;
    VSCODUNIVERSO_CODCLI       VARCHAR2(20);
    VSCODUNIVERSO_CODREDE      VARCHAR2(20);
    VSCODUNIVERSO_ESTENT       VARCHAR2(20);
    VSCODUNIVERSO_NUMREGIAO    VARCHAR2(20);
    VSCODUNIVERSO_CLASSEVENDA  VARCHAR2(20);
    vbAchouPrazoDeterminado    BOOLEAN; -- MED-1956
    
    vrPrioridade               PCCONDVALIDACLI%ROWTYPE;
  
    /* Consultar Prioridade da Condição de Venda*/
    FUNCTION VALIDAR_BLOQ_RESTR (P_CODCONDICAOVENDA IN PCCONDVENDABLOQRESTR.CODCONDICAOVENDA%TYPE,
                                 P_CODUNIVERSO IN PCCONDVENDABLOQRESTR.CODUNIVERSO%TYPE,
                                 P_TIPOEVENTO IN PCCONDVENDABLOQRESTR.TIPOEVENTO%TYPE,
                                 P_TIPOUNIVERSO IN PCCONDVENDABLOQRESTR.TIPOUNIVERSO%TYPE,
                                 P_PRIORIDADE IN NUMERIC)
    RETURN NUMBER IS
      VNRETORNO                NUMERIC(2);
      VNQTDERESTRICOESTIPOUNIV NUMERIC(8);
    BEGIN
      VNRETORNO := 0;
      /*Se Bloqueio*/
      IF (P_TIPOEVENTO = 'B') THEN  
        BEGIN
          SELECT P_PRIORIDADE AS PRIORIDADE
            INTO VNRETORNO
            FROM PCCONDVENDABLOQRESTR
           WHERE (PCCONDVENDABLOQRESTR.CODCONDICAOVENDA = P_CODCONDICAOVENDA)
             AND (PCCONDVENDABLOQRESTR.TIPOEVENTO       = P_TIPOEVENTO)
             AND (PCCONDVENDABLOQRESTR.TIPOUNIVERSO     = P_TIPOUNIVERSO)
             AND (PCCONDVENDABLOQRESTR.CODUNIVERSO      = P_CODUNIVERSO);
        EXCEPTION WHEN OTHERS THEN
          VNRETORNO := 0;
        END;
      /*Se Restrição*/
      ELSIF (P_TIPOEVENTO = 'R') THEN  
        /*Verificando se existe restrições para o tipo universo*/
        SELECT COUNT(*)
          INTO VNQTDERESTRICOESTIPOUNIV
          FROM PCCONDVENDABLOQRESTR
         WHERE (PCCONDVENDABLOQRESTR.CODCONDICAOVENDA = P_CODCONDICAOVENDA)
           AND (PCCONDVENDABLOQRESTR.TIPOEVENTO       = P_TIPOEVENTO)
           AND (PCCONDVENDABLOQRESTR.TIPOUNIVERSO     = P_TIPOUNIVERSO);
        /*Se existem Restrições para o Tipo Universo*/
        IF (NVL(VNQTDERESTRICOESTIPOUNIV,0) > 0) THEN         
          /*Pesquisa a Restrição para o Código do Universo*/
          BEGIN
            SELECT P_PRIORIDADE AS PRIORIDADE
              INTO VNRETORNO
              FROM PCCONDVENDABLOQRESTR
             WHERE (PCCONDVENDABLOQRESTR.CODCONDICAOVENDA = P_CODCONDICAOVENDA)
               AND (PCCONDVENDABLOQRESTR.TIPOEVENTO       = P_TIPOEVENTO)
               AND (PCCONDVENDABLOQRESTR.TIPOUNIVERSO     = P_TIPOUNIVERSO)
               AND (PCCONDVENDABLOQRESTR.CODUNIVERSO      = P_CODUNIVERSO);
          EXCEPTION WHEN OTHERS THEN
            VNRETORNO := 0;
          END;
          /*Se existem Restrições para o Tipo de Universo, mas menhuma delas para o Código Universo,*/
          /*marca Condição como Inválida*/
          IF (NVL(VNRETORNO,0) = 0) THEN
            VNRETORNO := -1;        
          END IF;        
        END IF;        
      END IF;      
      RETURN VNRETORNO;
    END VALIDAR_BLOQ_RESTR;
  
    /* Procedure de validação dos Bloqueios de Restrições por projeto e cliente*/
    PROCEDURE GRAVARPRIORIDADE(P_CODCONDICAOVENDA IN PCCONDICAOVENDA.CODCONDICAOVENDA%TYPE,
                               P_DESCRICAO IN PCCONDICAOVENDA.DESCRICAO%TYPE)
    IS
       VNPRIORIDADE             NUMBER(2)  DEFAULT 0;
       VNPRIORIDADEPROJETO      NUMBER(2)  DEFAULT 0;
       VNBLOQUEIO               NUMBER(2)  DEFAULT 0;
       VNBLOQUEIOPROJETO        NUMBER(2)  DEFAULT 0;
       VNQTDERESTRICOES         NUMBER(10) DEFAULT 0;
       VNQTDERESTRICOESPROJETO  NUMBER(10) DEFAULT 0;
    BEGIN
  
      /* Validando Bloqueios por projeto */
      VNBLOQUEIOPROJETO := VALIDAR_BLOQ_RESTR(P_CODCONDICAOVENDA, P_CODIGOPROJETO, 'B', 5, 1);
  
      /*Se não encontrou bloqueios por projeto, então verifica restrição por projeto*/
      IF VNBLOQUEIOPROJETO = 0 THEN
        /*Verificando se existe restrições de projeto*/
        SELECT COUNT(*)
          INTO VNQTDERESTRICOESPROJETO
          FROM PCCONDVENDABLOQRESTR
         WHERE (PCCONDVENDABLOQRESTR.CODCONDICAOVENDA = P_CODCONDICAOVENDA)
           AND (PCCONDVENDABLOQRESTR.TIPOEVENTO       = 'R')
           AND (PCCONDVENDABLOQRESTR.TIPOUNIVERSO     = 5);
        /*Se existem restrições de projeto*/
        IF VNQTDERESTRICOESPROJETO > 0 THEN
          VNPRIORIDADEPROJETO := VALIDAR_BLOQ_RESTR(P_CODCONDICAOVENDA, P_CODIGOPROJETO, 'R', 5, 1);
        ELSE
          VNPRIORIDADEPROJETO := 99;
        END IF;
      END IF;
  
      /* Se a condição está liberada para o projeto, então verifica bloqueio e restrição do cliente.*/
      IF VNPRIORIDADEPROJETO > 0 THEN
        /* Validando Bloqueios */
        VNBLOQUEIO := VALIDAR_BLOQ_RESTR(P_CODCONDICAOVENDA, VSCODUNIVERSO_CODCLI, 'B', 1, 1); --> Cliente
        IF VNBLOQUEIO = 0 THEN
          VNBLOQUEIO := VALIDAR_BLOQ_RESTR(P_CODCONDICAOVENDA, VSCODUNIVERSO_CODREDE, 'B', 2, 2); -->> Rede de Lojas
          IF VNBLOQUEIO = 0 THEN
            VNBLOQUEIO := VALIDAR_BLOQ_RESTR(P_CODCONDICAOVENDA, VSCODUNIVERSO_CLASSEVENDA, 'B', 6, 3); -->> Classe de Venda
            IF VNBLOQUEIO = 0 THEN
              VNBLOQUEIO := VALIDAR_BLOQ_RESTR(P_CODCONDICAOVENDA, VSCODUNIVERSO_ESTENT, 'B', 3, 4); -->> UF
              IF VNBLOQUEIO = 0 THEN
                VNBLOQUEIO := VALIDAR_BLOQ_RESTR(P_CODCONDICAOVENDA, VSCODUNIVERSO_NUMREGIAO, 'B', 4, 5); -->> Região
              END IF;
            END IF;
          END IF;
        END IF;
  
        /*Se não encontrou bloqueios, então verifica prioridade conforme restrições.*/
        IF VNBLOQUEIO = 0 THEN
          /*Verificando se existe restrições de cliente*/
          SELECT COUNT(*)
            INTO VNQTDERESTRICOES
            FROM PCCONDVENDABLOQRESTR
           WHERE (PCCONDVENDABLOQRESTR.CODCONDICAOVENDA = P_CODCONDICAOVENDA)
             AND (PCCONDVENDABLOQRESTR.TIPOEVENTO       = 'R')
             AND (PCCONDVENDABLOQRESTR.TIPOUNIVERSO     in (1,2,3,4,6));
          /*Se existem restrições de clientes*/
          IF VNQTDERESTRICOES > 0 THEN
            /* Validando TODAS as Restrições enquanto não encontrar uma restrição que invalide a Condição */
            VNPRIORIDADE := VALIDAR_BLOQ_RESTR(P_CODCONDICAOVENDA, VSCODUNIVERSO_CODCLI, 'R', 1, 1); -->> Cliente
            IF VNPRIORIDADE <> -1 THEN
              VNPRIORIDADE := VALIDAR_BLOQ_RESTR(P_CODCONDICAOVENDA, VSCODUNIVERSO_CODREDE, 'R', 2, 2); -->> Rede de Lojas
              IF VNPRIORIDADE <> -1 THEN
                VNPRIORIDADE := VALIDAR_BLOQ_RESTR(P_CODCONDICAOVENDA, VSCODUNIVERSO_CLASSEVENDA, 'R', 6, 3); -->> Classe de Venda
                IF VNPRIORIDADE <> -1 THEN
                  VNPRIORIDADE := VALIDAR_BLOQ_RESTR(P_CODCONDICAOVENDA, VSCODUNIVERSO_ESTENT, 'R', 3, 4); -->> UF
                  IF VNPRIORIDADE <> -1 THEN
                    VNPRIORIDADE := VALIDAR_BLOQ_RESTR(P_CODCONDICAOVENDA, VSCODUNIVERSO_NUMREGIAO, 'R', 4, 5); -->> Região
                  END IF;
                END IF;
              END IF;
            END IF;
            /* Se a Condição não foi invalidada, Define Restrição Prioritária */
            IF (VNPRIORIDADE <> -1) THEN
              VNPRIORIDADE := VALIDAR_BLOQ_RESTR(P_CODCONDICAOVENDA, VSCODUNIVERSO_CODCLI, 'R', 1, 1); -->> Cliente
              IF VNPRIORIDADE = 0 THEN
                VNPRIORIDADE := VALIDAR_BLOQ_RESTR(P_CODCONDICAOVENDA, VSCODUNIVERSO_CODREDE, 'R', 2, 2); -->> Rede de Lojas
                IF VNPRIORIDADE = 0 THEN
                  VNPRIORIDADE := VALIDAR_BLOQ_RESTR(P_CODCONDICAOVENDA, VSCODUNIVERSO_CLASSEVENDA, 'R', 6, 3); -->> Classe de Venda
                  IF VNPRIORIDADE = 0 THEN
                    VNPRIORIDADE := VALIDAR_BLOQ_RESTR(P_CODCONDICAOVENDA, VSCODUNIVERSO_ESTENT, 'R', 3, 4); -->> UF
                    IF VNPRIORIDADE = 0 THEN
                      VNPRIORIDADE := VALIDAR_BLOQ_RESTR(P_CODCONDICAOVENDA, VSCODUNIVERSO_NUMREGIAO, 'R', 4, 5); -->> Região
                    END IF;
                  END IF;
                END IF;
              END IF;
            END IF;
          ELSE
            VNPRIORIDADE := 99;
          END IF;
  
          /* Se a Condição é Válida */
          IF VNPRIORIDADE > 0 THEN
            -- Registra a Condição mais prioritária
            IF (NVL(VNPRIORIDADE,0) < NVL(vrPrioridade.PRIORIDADE,0)) THEN
              vrPrioridade.CODCONDICAOVENDA := P_CODCONDICAOVENDA;
              vrPrioridade.DESCRICAO        := P_DESCRICAO;
              vrPrioridade.PRIORIDADE       := VNPRIORIDADE;
            END IF;          
          END IF;
  
        END IF;
      END IF;
    END;
  
  BEGIN
  
    -- Inicializa a Prioridade com o maior número válido
    vrPrioridade.PRIORIDADE  := 99999;  
  
    /* 1 */
    BEGIN
      VSCODUNIVERSO_CODCLI := P_CODCLI;
    EXCEPTION WHEN OTHERS THEN
      VSCODUNIVERSO_CODCLI := NULL;
    END;
  
    /* 2 e 6 */
    BEGIN
      SELECT PCCLIENT.CODREDE,
             PCCLIENT.CLASSEVENDA
        INTO VSCODUNIVERSO_CODREDE,
             VSCODUNIVERSO_CLASSEVENDA      
        FROM PCCLIENT
       WHERE PCCLIENT.CODCLI = P_CODCLI;
    EXCEPTION WHEN OTHERS THEN
      VSCODUNIVERSO_CODREDE     := NULL;
      VSCODUNIVERSO_CLASSEVENDA := NULL;   
    END;
  
    /* 3 */
    BEGIN
      SELECT PCCLIENT.ESTENT
        INTO VSCODUNIVERSO_ESTENT
        FROM PCCLIENT
       WHERE PCCLIENT.CODCLI = P_CODCLI;
    EXCEPTION WHEN OTHERS THEN
      VSCODUNIVERSO_ESTENT := NULL;
    END;
  
    /* 4 */
    BEGIN -- Pesquisa primeiro a Região por Cliente - 4663.037138.2014
      SELECT NUMREGIAO
        INTO VSCODUNIVERSO_NUMREGIAO
        FROM PCTABPRCLI
       WHERE CODCLI      = P_CODCLI
         AND CODFILIALNF = P_CODFILIAL;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        VSCODUNIVERSO_NUMREGIAO := NULL;
    END;
    IF (VSCODUNIVERSO_NUMREGIAO IS NULL) THEN
      BEGIN
        SELECT PCPRACA.NUMREGIAO
          INTO VSCODUNIVERSO_NUMREGIAO
          FROM PCPRACA
         WHERE PCPRACA.CODPRACA = (SELECT PCCLIENT.CODPRACA
                                     FROM PCCLIENT
                                    WHERE PCCLIENT.CODCLI = P_CODCLI);
      EXCEPTION WHEN OTHERS THEN
        VSCODUNIVERSO_NUMREGIAO := NULL;
      END;
    END IF;    
    
    /*VALIDANDO PRIORIDADES*/
    IF P_TIPOSELECAOCONDICAO IN ('A','I') THEN -->> APONTADOR DA CONDICAO OU CONDIÇÃO DA INTEGRAÇÃO
      BEGIN
        SELECT PCCONDICAOVENDA.CODCONDICAOVENDA,
               PCCONDICAOVENDA.DESCRICAO
          INTO VNCODCONDICAOVENDA,
               VSDESCRICAOCONDVENDA
          FROM PCCONDICAOVENDA,
               PCCONDVENDAFILIAL,
               PCCONDVENDAINTEGRADORA
          WHERE (PCCONDICAOVENDA.CODCONDICAOVENDA       = PCCONDVENDAFILIAL.CODCONDICAOVENDA)
            AND (PCCONDICAOVENDA.CODCONDICAOVENDA       = PCCONDVENDAINTEGRADORA.CODCONDICAOVENDA)
            AND (PCCONDVENDAFILIAL.CODFILIAL            = P_CODFILIAL)
            AND (PCCONDVENDAINTEGRADORA.INTEGRADORA     = P_INTEGRADORA)
            AND (PCCONDICAOVENDA.DTVALIDINICIAL        <= TRUNC(SYSDATE))
            AND (PCCONDICAOVENDA.DTVALIDFINAL          >= TRUNC(SYSDATE))
            AND (PCCONDICAOVENDA.CONDICAOINTEGRAD       = 'S')
            AND (PCCONDICAOVENDA.CODCONDICAOVENDA       = P_CODCONDICAOVENDA);
  
        GRAVARPRIORIDADE(VNCODCONDICAOVENDA, VSDESCRICAOCONDVENDA);
  
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
             vrPrioridade.CODCONDICAOVENDA := -1;
        WHEN OTHERS THEN
             vrPrioridade.CODCONDICAOVENDA := -2;
      END;
    ELSIF P_TIPOSELECAOCONDICAO = 'P' THEN -->> PRAZO
      
      -- MED-1956
      vbAchouPrazoDeterminado := FALSE;
      
      -- MED-1956 - Pesquisa primeiramente pelo Prazo Determinado
      -- DDMEDICA-1969 - Fidelize envia Prazo Zero
      IF (NVL(P_PRAZO,0) >= 0) THEN
        FOR REG IN ( SELECT PCCONDICAOVENDA.CODCONDICAOVENDA,
                            PCCONDICAOVENDA.DESCRICAO
                        FROM PCCONDICAOVENDA,
                             PCCONDVENDAFILIAL,
                             PCCONDVENDAINTEGRADORA
                        WHERE (PCCONDICAOVENDA.CODCONDICAOVENDA         = PCCONDVENDAFILIAL.CODCONDICAOVENDA)
                        AND (PCCONDICAOVENDA.CODCONDICAOVENDA         = PCCONDVENDAINTEGRADORA.CODCONDICAOVENDA)
                        AND (PCCONDVENDAFILIAL.CODFILIAL              = P_CODFILIAL)
                        AND (PCCONDVENDAINTEGRADORA.INTEGRADORA       = P_INTEGRADORA)
                        AND (PCCONDICAOVENDA.DTVALIDINICIAL          <= TRUNC(SYSDATE))
                        AND (PCCONDICAOVENDA.DTVALIDFINAL            >= TRUNC(SYSDATE))
                        AND (PCCONDICAOVENDA.CONDICAOINTEGRAD         = 'S')
                        AND (PCCONDICAOVENDA.TIPOPRAZOINTEGRAD        = 'D') -->> Condições Setadas com a opção Prazo Determinado
                        AND (PCCONDICAOVENDA.PRAZOINTEGRAD            = P_PRAZO)) LOOP
          GRAVARPRIORIDADE(REG.CODCONDICAOVENDA, REG.DESCRICAO);
          vbAchouPrazoDeterminado := TRUE; -- MED-1956
        END LOOP;
      END IF;
      
      -- Se não achou o Prazo Determinado - MED-1956
      IF (NOT vbAchouPrazoDeterminado) THEN
      
        -- Se não tem Prazo Determinado, somente À VISTA ou A PRAZO - MED-1956
        IF P_TIPOPRAZO IN ('P','V') THEN
          FOR REG IN ( SELECT PCCONDICAOVENDA.CODCONDICAOVENDA,
                              PCCONDICAOVENDA.DESCRICAO
                         FROM PCCONDICAOVENDA,
                              PCCONDVENDAFILIAL,
                              PCCONDVENDAINTEGRADORA
                    WHERE (PCCONDICAOVENDA.CODCONDICAOVENDA         = PCCONDVENDAFILIAL.CODCONDICAOVENDA)
                      AND (PCCONDICAOVENDA.CODCONDICAOVENDA         = PCCONDVENDAINTEGRADORA.CODCONDICAOVENDA)
                      AND (PCCONDVENDAFILIAL.CODFILIAL              = P_CODFILIAL)
                      AND (PCCONDVENDAINTEGRADORA.INTEGRADORA       = P_INTEGRADORA)
                      AND (PCCONDICAOVENDA.DTVALIDINICIAL          <= TRUNC(SYSDATE))
                      AND (PCCONDICAOVENDA.DTVALIDFINAL            >= TRUNC(SYSDATE))
                      AND (PCCONDICAOVENDA.CONDICAOINTEGRAD         = 'S')
                      AND (PCCONDICAOVENDA.TIPOPRAZOINTEGRAD        = P_TIPOPRAZO)) LOOP
  
            GRAVARPRIORIDADE(REG.CODCONDICAOVENDA, REG.DESCRICAO);
          END LOOP;
        END IF;
      
      END IF; -- Fim: Se não achou o Prazo Determinado - MED-1956
      
     /*
      IF P_TIPOPRAZO IN ('P','V') THEN    --PRAZO A VISTA OU PRAZO
        BEGIN
          FOR REG IN ( SELECT PCCONDICAOVENDA.CODCONDICAOVENDA,
                              PCCONDICAOVENDA.DESCRICAO
                         FROM PCCONDICAOVENDA,
                              PCCONDVENDAFILIAL,
                              PCCONDVENDAINTEGRADORA
                    WHERE (PCCONDICAOVENDA.CODCONDICAOVENDA         = PCCONDVENDAFILIAL.CODCONDICAOVENDA)
                      AND (PCCONDICAOVENDA.CODCONDICAOVENDA         = PCCONDVENDAINTEGRADORA.CODCONDICAOVENDA)
                      AND (PCCONDVENDAFILIAL.CODFILIAL              = P_CODFILIAL)
                      AND (PCCONDVENDAINTEGRADORA.INTEGRADORA       = P_INTEGRADORA)
                      AND (PCCONDICAOVENDA.DTVALIDINICIAL          <= TRUNC(SYSDATE))
                      AND (PCCONDICAOVENDA.DTVALIDFINAL            >= TRUNC(SYSDATE))
                      AND (PCCONDICAOVENDA.CONDICAOINTEGRAD         = 'S')
                      AND (PCCONDICAOVENDA.TIPOPRAZOINTEGRAD = P_TIPOPRAZO)) LOOP
  
            GRAVARPRIORIDADE(REG.CODCONDICAOVENDA, REG.DESCRICAO);
          END LOOP;
        EXCEPTION
          WHEN OTHERS THEN
             P_MENSAGEM := 'ERRO AO SELECIONAR CONDICAO DE VENDA :'||SQLCODE||' - '||SQLERRM;
        END;
      ELSIF P_TIPOPRAZO = 'D' THEN --PRAZO DETERMINADO
        BEGIN
          FOR REG IN ( SELECT PCCONDICAOVENDA.CODCONDICAOVENDA,
                              PCCONDICAOVENDA.DESCRICAO
                          FROM PCCONDICAOVENDA,
                               PCCONDVENDAFILIAL,
                               PCCONDVENDAINTEGRADORA
                          WHERE (PCCONDICAOVENDA.CODCONDICAOVENDA         = PCCONDVENDAFILIAL.CODCONDICAOVENDA)
                          AND (PCCONDICAOVENDA.CODCONDICAOVENDA         = PCCONDVENDAINTEGRADORA.CODCONDICAOVENDA)
                          AND (PCCONDVENDAFILIAL.CODFILIAL              = P_CODFILIAL)
                          AND (PCCONDVENDAINTEGRADORA.INTEGRADORA       = P_INTEGRADORA)
                          AND (PCCONDICAOVENDA.DTVALIDINICIAL          <= TRUNC(SYSDATE))
                          AND (PCCONDICAOVENDA.DTVALIDFINAL            >= TRUNC(SYSDATE))
                          AND (PCCONDICAOVENDA.CONDICAOINTEGRAD         = 'S')
                          AND (PCCONDICAOVENDA.TIPOPRAZOINTEGRAD        = P_TIPOPRAZO)
                          AND (PCCONDICAOVENDA.PRAZOINTEGRAD            = P_PRAZO)) LOOP
            GRAVARPRIORIDADE(REG.CODCONDICAOVENDA, REG.DESCRICAO);
          END LOOP;
  
        EXCEPTION WHEN OTHERS THEN
          P_MENSAGEM := 'ERRO AO SELECIONAR CONDICAO DE VENDA :'||SQLCODE||' - '||SQLERRM;
        END;
      END IF;      
      */
      
    ELSIF P_TIPOSELECAOCONDICAO = 'T' THEN -->> TABELA DE PRAZOS
      FOR REG IN ( SELECT PCCONDICAOVENDA.CODCONDICAOVENDA,
                          PCCONDICAOVENDA.DESCRICAO
                      FROM PCCONDICAOVENDA,
                           PCCONDVENDAFILIAL,
                           PCCONDVENDAINTEGRADORA
                    WHERE (PCCONDICAOVENDA.CODCONDICAOVENDA         = PCCONDVENDAFILIAL.CODCONDICAOVENDA)
                      AND (PCCONDICAOVENDA.CODCONDICAOVENDA         = PCCONDVENDAINTEGRADORA.CODCONDICAOVENDA)
                      AND (PCCONDVENDAFILIAL.CODFILIAL              = P_CODFILIAL)
                      AND (PCCONDVENDAINTEGRADORA.INTEGRADORA       = P_INTEGRADORA)
                      AND (PCCONDICAOVENDA.DTVALIDINICIAL          <= TRUNC(SYSDATE))
                      AND (PCCONDICAOVENDA.DTVALIDFINAL            >= TRUNC(SYSDATE))
                      AND (PCCONDICAOVENDA.CONDICAOINTEGRAD         = 'S')
                      AND (PCCONDICAOVENDA.TIPOPRAZOINTEGRAD        = 'C') -->> TIPO DE PRAZO = 'C' - CODIGO DE PRAZO
                      AND (TRIM(PCCONDICAOVENDA.CODPRAZOINTEGRAD)   = TRIM(P_CODPRAZO))) LOOP
        GRAVARPRIORIDADE(REG.CODCONDICAOVENDA, REG.DESCRICAO);
      END LOOP;
    ELSIF P_TIPOSELECAOCONDICAO = 'C' OR P_TIPOSELECAOCONDICAO IS NULL THEN -->> CONDIÇÃO DO CLIENTE
      FOR REG IN ( SELECT PCCONDICAOVENDA.CODCONDICAOVENDA,
                          PCCONDICAOVENDA.DESCRICAO
                    FROM PCCONDICAOVENDA,
                         PCCONDVENDAFILIAL,
                         PCCONDVENDAINTEGRADORA
                   WHERE (PCCONDICAOVENDA.CODCONDICAOVENDA   = PCCONDVENDAFILIAL.CODCONDICAOVENDA)
                     AND (PCCONDICAOVENDA.CODCONDICAOVENDA   = PCCONDVENDAINTEGRADORA.CODCONDICAOVENDA)
                     AND (PCCONDVENDAFILIAL.CODFILIAL        = P_CODFILIAL)
                     AND (PCCONDVENDAINTEGRADORA.INTEGRADORA = P_INTEGRADORA)
                     AND (PCCONDICAOVENDA.CONDICAOINTEGRAD   = 'S')
                     AND (PCCONDICAOVENDA.DTVALIDINICIAL    <= TRUNC(SYSDATE))
                     AND (PCCONDICAOVENDA.DTVALIDFINAL      >= TRUNC(SYSDATE))
                     AND (NVL(PCCONDICAOVENDA.TIPOPRAZOINTEGRAD,' ') NOT IN ('C','D'))) LOOP -- [Tarefa: 170847] - MED-1956 - Não carregar Prazos Determinados
        GRAVARPRIORIDADE(REG.CODCONDICAOVENDA, REG.DESCRICAO);
      END LOOP;
    END IF;
  
    -- Retorna a Condição mais prioritária
    RETURN NVL(vrPrioridade.CODCONDICAOVENDA,0);
    --/* Buscando condição de venda na tabela temporária, se não existir irá retornar o valor 0 (zero).*/
    --/* Se INTEGRAÇÃO não pode executar instrução DML*/
    --IF (NVL(P_TIPOSELECAOCONDICAO,'A') NOT IN ('I')) THEN
    --  BEGIN
    --    SELECT CODCONDICAOVENDA
    --      INTO P_CODCONDICAOVENDAVALIDA
    --    FROM (SELECT CODCONDICAOVENDA
    --               , PRIORIDADE
    --            FROM PCCONDVALIDACLI
    --            ORDER BY  PRIORIDADE, CODCONDICAOVENDA) X
    --    WHERE ROWNUM = 1;
    --  EXCEPTION WHEN OTHERS THEN
    --    P_CODCONDICAOVENDAVALIDA := 0;
    --  END;
    --END IF;
    
  END F_VALIDACONDICAOVENDA;

 /***********************************************************************************************
  PROCEDURE: P_VALIDACREDITOCLIENTE
  DESCRIÇÃO: Validar Limite de Crédito do Cliente
  ***********************************************************************************************/
  PROCEDURE P_VALIDACREDITOCLIENTE(pi_nCodCli                  IN  NUMBER,
                                   pi_nCodCliPrincipal         IN  NUMBER,
                                   pi_nCodUsur                 IN  NUMBER,
                                   pi_nLimiteCredito           IN  NUMBER,
                                   pi_vSomaCreditoCliPrincipal IN  VARCHAR2,
                                   pi_vUsaBnfLimiteCredito     IN  VARCHAR2,
                                   pi_nPerExcedeLimCred        IN  NUMBER,
                                   pi_nNumCasasDecVenda        IN  NUMBER,
                                   po_nValorRetorno            OUT VARCHAR2) IS
                                   
    -- Variáveis
    vncontasareceberemaberto   number;
    vnvalorpedidospendentes    number;
    vnvllimcredtot             number;
    vnsaldodisponivel          number;
    --DDMEDICA-1245
    vdatavalidadecredito       date;
    -- Mensagem Limite de Crédito Sazonal
    vvMensagemLimiteSanzonal   varchar2(255);

    -- Parâmetro Específico - DDMEDICA-6036
    vUSALIMCREDSANZONALPEDIDO  PCREGRASEXCECAOMED.VALOR%TYPE;

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
    po_nValorRetorno        := 0;

    vnsaldodisponivel       := 0;

    -- Parâmetro Específico
    vUSALIMCREDSANZONALPEDIDO := FUSA_REGRA_MEDICAMENTOS('99','USALIMCREDSANZONALPEDIDO');  

    -- Se NÃO Considera o Limite Disponível do Cliente Principal
    IF (NVL(pi_vSomaCreditoCliPrincipal,'N') = 'N') THEN

      IF (NVL(pi_vUsaBnfLimiteCredito,'N') = 'S') THEN

        -- Pendencias no contas a receber do cliente
        select sum(NVL(pcprest.valor, 0))
          into vncontasareceberemaberto
          from pcprest
         where pcprest.codcli = pi_nCodCli
           and pcprest.dtpag is null ;

        select sum(NVL(vlatend, 0))
          into vnvalorpedidospendentes
          from pcpedc
         where codcli   = pi_nCodCli
           and dtcancel is null
           and posicao  in ('L', 'M');

      ELSE

        -- Pendencias no contas a receber do cliente
        select sum(NVL(pcprest.valor, 0))
          into vncontasareceberemaberto
          from pcprest
         where pcprest.codcli = pi_nCodCli
           and pcprest.dtpag is null
           and PCPREST.CODCOB not in ('BNF','BNFT','BNTR','BNFR','BNRP');


        select sum(NVL(vlatend, 0))
          into vnvalorpedidospendentes
          from pcpedc
         where codcli   = pi_nCodCli
           and dtcancel is null
           and posicao  in ('L', 'M')
           and CODCOB not in ('BNF','BNFT','BNTR','BNFR','BNRP');


      END IF;

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


      IF vdatavalidadecredito >= trunc(sysdate) THEN

        -- Saldo Inicial
        vnsaldodisponivel := ((nvl(pi_nLimiteCredito,0) * (1 + (NVL (pi_nPerExcedeLimCred, 0) / 100)) )-
                             (NVL(vncontasareceberemaberto, 0) +
                             NVL(vnvalorpedidospendentes, 0)));

        vnsaldodisponivel := ROUND(nvl(vnsaldodisponivel,0),
                                   pi_nNumCasasDecVenda);

        -- Adiciona Limite Sanzonal - DDMEDICA-6036
        IF (NVL(vUSALIMCREDSANZONALPEDIDO,'N') = 'S') THEN
          proc_adicionar_limite_sanzonal(pi_nCodCli,
                                         pi_nCodUsur,
                                         pi_nLimiteCredito,
                                         vnsaldodisponivel,
                                         vvMensagemLimiteSanzonal);          
        END IF;                               

      END IF;

    -- Se Considera o Limite Disponível do Cliente Principal
    ELSE

      IF (NVL(pi_vUsaBnfLimiteCredito,'N') = 'S') THEN

        -- Pendencias no contas a receber do cliente
        select sum(NVL(pcprest.valor, 0))
          into vncontasareceberemaberto
          from pcprest
         where (pcprest.codcli in (select pcclient.codcli from pcclient where pcclient.codcliprinc =  pi_nCodCliPrincipal) OR
                pcprest.codcli = pi_nCodCli)
           and pcprest.dtpag is null;

        -- Pedidos pendentes do cliente
        select sum(NVL(vlatend, 0))
          into vnvalorpedidospendentes
          from pcpedc
         where (codcli   in (select pcclient.codcli from pcclient where pcclient.codcliprinc =  pi_nCodCliPrincipal) OR
                codcli = pi_nCodCli)
           and dtcancel is null
           and posicao  in ('L', 'M');

      ELSE

        -- Pendencias no contas a receber do cliente
        select sum(NVL(pcprest.valor, 0))
          into vncontasareceberemaberto
          from pcprest
         where (pcprest.codcli in (select pcclient.codcli from pcclient where pcclient.codcliprinc =  pi_nCodCliPrincipal) OR
                pcprest.codcli = pi_nCodCli)
           and pcprest.dtpag is null
           and PCPREST.CODCOB not in ('BNF','BNFT','BNTR','BNFR','BNRP');

        -- Pedidos pendentes do cliente
        select sum(NVL(vlatend, 0))
          into vnvalorpedidospendentes
          from pcpedc
         where (codcli   in (select pcclient.codcli from pcclient where pcclient.codcliprinc =  pi_nCodCliPrincipal) OR
                codcli = pi_nCodCli)
           and dtcancel is null
           and posicao  in ('L', 'M')
           and CODCOB not in ('BNF','BNFT','BNTR','BNFR','BNRP');

      END IF;

      select sum(pcclient.limcred)
      into vnvllimcredtot
      from pcclient
      where (pcclient.codcliprinc =  pi_nCodCliPrincipal OR pcclient.codcli = pi_nCodCli);

      --DDMEDICA-1245
      begin
        select NVL(trunc(pcclient.dtvenclimcred),trunc(sysdate))
          into vdatavalidadecredito
          from pcclient
         where (pcclient.codcliprinc =  pi_nCodCliPrincipal OR pcclient.codcli = pi_nCodCli);
      exception
        when others then
          vdatavalidadecredito := trunc(sysdate);
      end;

      IF vdatavalidadecredito >= trunc(sysdate) THEN

        vnsaldodisponivel := ((nvl(vnvllimcredtot,0)* (1 + (NVL (pi_nPerExcedeLimCred, 0) / 100))) -
                             (NVL(vncontasareceberemaberto, 0) +
                             NVL(vnvalorpedidospendentes, 0)));

        vnsaldodisponivel := ROUND(nvl(vnsaldodisponivel,0),
                                   pi_nNumCasasDecVenda);

        -- Adiciona Limite Sanzonal - DDMEDICA-6036
        IF (NVL(vUSALIMCREDSANZONALPEDIDO,'N') = 'S') THEN
          proc_adicionar_limite_sanzonal(pi_nCodCli,
                                         pi_nCodUsur,
                                         vnvllimcredtot,
                                         vnsaldodisponivel,
                                         vvMensagemLimiteSanzonal);          
        END IF;                               

      END IF;

    END IF; -- Fim Condição: Se não Considera ou Considera o Limite Disponível do Cliente Principal
	
    IF (nvl(vnsaldodisponivel,0) < 0) THEN
      vnsaldodisponivel := 0;
    END IF;	
    
    -- Retornará o Saldo Disponível calculado
    po_nValorRetorno := nvl(vnsaldodisponivel,0);

  END P_VALIDACREDITOCLIENTE;
  
 /***********************************************************************************************
  FUNÇÃO   : F_OBTEM_CREDITODISPONIVEL
  DESCRIÇÃO: Validar Limite de Crédito do Cliente
  ***********************************************************************************************/
  FUNCTION F_OBTEM_LIMITECREDITO(pi_nCodCliPrinc   IN NUMBER,
                                 pi_nLimiteCredito IN NUMBER)
  RETURN NUMBER IS  
      
    vSOMACREDITOCLIPRINCIPAL PCPARAMFILIAL.VALOR%TYPE;      
   
    vnLimiteCredito          NUMBER;                                
    
  BEGIN
    
    BEGIN
      SELECT NVL(VALOR,'N')
        INTO vSOMACREDITOCLIPRINCIPAL
        FROM PCPARAMFILIAL 
       WHERE NOME = 'SOMACREDITOCLIPRINCIPAL' 
         AND CODFILIAL = '99';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vSOMACREDITOCLIPRINCIPAL := 'N';
    END;  
    
    vnLimiteCredito := NVL(pi_nLimiteCredito,0);
    IF (vSOMACREDITOCLIPRINCIPAL = 'S') THEN
      SELECT SUM(NVL(cp.LIMCRED,0)) 
        INTO vnLimiteCredito
        FROM PCCLIENT cp 
       WHERE cp.CODCLIPRINC = pi_nCodCliPrinc;
    END IF;    
    
    RETURN vnLimiteCredito;
  
  END F_OBTEM_LIMITECREDITO;  
  
 /***********************************************************************************************
  FUNÇÃO   : F_OBTEM_CREDITODISPONIVEL
  DESCRIÇÃO: Validar Limite de Crédito do Cliente
  ***********************************************************************************************/
  FUNCTION F_OBTEM_CREDITODISPONIVEL(pi_nCodCli        IN NUMBER,
                                     pi_nCodCliPrinc   IN NUMBER,
                                     pi_nCodUsur       IN NUMBER,
                                     pi_nLimiteCredito IN NUMBER)
  RETURN NUMBER IS  
      
    vSOMACREDITOCLIPRINCIPAL PCPARAMFILIAL.VALOR%TYPE;      
    vUSABNFLIMITECREDITO     PCPARAMFILIAL.VALOR%TYPE;
    nPEREXCEDELIMCRED        PCCONSUM.PEREXCEDELIMCRED%TYPE;
    nNUMCASASDECVENDA        PCCONSUM.NUMCASASDECVENDA%TYPE;
    
    vnLimiteCredito          NUMBER;                                
    
    vnSaldoDisponivel        NUMBER;
    
  BEGIN
    
    BEGIN
      SELECT NVL(VALOR,'N')
        INTO vSOMACREDITOCLIPRINCIPAL
        FROM PCPARAMFILIAL 
       WHERE NOME = 'SOMACREDITOCLIPRINCIPAL' 
         AND CODFILIAL = '99';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vSOMACREDITOCLIPRINCIPAL := 'N';
    END;  

    BEGIN
      SELECT NVL(VALOR,'N')
        INTO vUSABNFLIMITECREDITO
        FROM PCPARAMFILIAL 
       WHERE NOME = 'USABNFLIMITECREDITO' 
         AND CODFILIAL = '99';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vUSABNFLIMITECREDITO := 'N';
    END;  

    BEGIN
      SELECT PEREXCEDELIMCRED
           , NUMCASASDECVENDA
        INTO nPEREXCEDELIMCRED
           , nNUMCASASDECVENDA     
        FROM PCCONSUM;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        nPEREXCEDELIMCRED := 0;
        nNUMCASASDECVENDA := 0;        
    END;
    
    vnLimiteCredito := F_OBTEM_LIMITECREDITO(pi_nCodCliPrinc,
                                             pi_nLimiteCredito);
  
    P_VALIDACREDITOCLIENTE(pi_nCodCli,
                           pi_nCodCliPrinc,
                           pi_nCodUsur,
                           vnLimiteCredito,
                           vSOMACREDITOCLIPRINCIPAL,
                           vUSABNFLIMITECREDITO,
                           nPEREXCEDELIMCRED,
                           nNUMCASASDECVENDA,
                           vnSaldoDisponivel);
                           
    RETURN vnSaldoDisponivel;
  
  END F_OBTEM_CREDITODISPONIVEL;

 /***********************************************************************************************
  FUNÇÃO...: F_OBTER_PEDIDOS_HUB_INTEGRACAO
  DESCRIÇÃO: Função para retornar os pedidos recebidos no HUB de Integração
  ***********************************************************************************************/  
  FUNCTION F_OBTER_PEDIDOS_HUB_INTEGRACAO(pi_vDataInicial IN VARCHAR2 DEFAULT NULL,
                                          pi_vDataFinal   IN VARCHAR2 DEFAULT NULL)
  RETURN TABELA_MED_PEDIDOS_HUB_INTEGRA PARALLEL_ENABLE PIPELINED IS
  
    -- Variáveis
    vdDataInicial           DATE;
    vdDataFinal             DATE;
    vrPedidoRetorno         PCPEDRETORNO%ROWTYPE;
    vrLimpaPedidoRetorno    PCPEDRETORNO%ROWTYPE;
    vnImportado             PCPEDCFV.IMPORTADO%TYPE;
    vvObservacaoPc          PCPEDCFV.OBSERVACAO_PC%TYPE;
    vnNumPed                PCPEDC.NUMPED%TYPE;
    vvPosicao               PCPEDC.POSICAO%TYPE;
    vvIdExternoRetorno      VARCHAR2(255);
    vvIdExternoCancelamento VARCHAR2(255);
    vvIdExternoNotaFiscal   VARCHAR2(255);
    vvIdExternoDevolucao    VARCHAR2(255);
    vvIdExternoPrePed       VARCHAR2(255);
    vnStatsRetorno          PCINTEGRACAOCORE.STATUS%TYPE;
    vnStatsCancelamento     PCINTEGRACAOCORE.STATUS%TYPE;
    vnStatusNotaFiscal      PCINTEGRACAOCORE.STATUS%TYPE;
    vnStatusDevolucao       PCINTEGRACAOCORE.STATUS%TYPE;
    vnStatusPrePed          PCINTEGRACAOCORE.STATUS%TYPE;
    vnNumNotaSai            PCNFSAID.NUMNOTA%TYPE;
    vvSituacaoNfeSai        PCNFSAID.SITUACAONFE%TYPE;
    vnNumTransEnt           PCNFENT.NUMTRANSENT%TYPE;
    vnNumNotaEnt            PCNFENT.NUMNOTA%TYPE;
    vvSituacaoNfeEnt        PCNFENT.SITUACAONFE%TYPE;
        
    -- Tipo Objeto
    OUTROW TIPO_MED_PEDIDOS_HUB_INTEGRA := TIPO_MED_PEDIDOS_HUB_INTEGRA(NULL,   -- ARQUIVOPED
                                                                        NULL,   -- DATACRIACAO
                                                                        NULL,   -- STATUSPED
                                                                        NULL,   -- NUMPEDVAN
                                                                        NULL,   -- CODFILIAL 
                                                                        NULL,   -- NUMPEDRCA
                                                                        NULL,   -- IMPORTADO
                                                                        NULL,   -- GEROURET
                                                                        NULL,   -- STATUSRET
                                                                        NULL,   -- NUMPED
                                                                        NULL,   -- POSICAO
                                                                        NULL,   -- GEROUCAN
                                                                        NULL,   -- STATUSCAN
                                                                        NULL,   -- NUMTRANSVENDA
                                                                        NULL,   -- NUMNOTASAI
                                                                        NULL,   -- SITUACAONFESAI
                                                                        NULL,   -- GEROUNOT
                                                                        NULL,   -- STATUSNOT
                                                                        NULL,   -- NUMTRANSENT
                                                                        NULL,   -- NUMNOTAENT
                                                                        NULL,   -- SITUACAONFEENT
                                                                        NULL,   -- GEROUDEV
                                                                        NULL,   -- STATUSDEV
                                                                        NULL,   -- POSSUIPREPED
                                                                        NULL,   -- STATUSPREPED
                                                                        NULL);  -- OBSERVACAO_PC
        
  BEGIN
    
    -- Período    
    IF (pi_vDataInicial IS NULL) THEN
      vdDataInicial := TRUNC(SYSDATE)-7;
    ELSE
      vdDataInicial := TO_DATE(pi_vDataInicial,'DD/MM/YYYY');
    END IF;

    IF (pi_vDataFinal IS NULL) THEN
      vdDataFinal := TRUNC(SYSDATE);
    ELSE
      vdDataFinal := TO_DATE(pi_vDataFinal,'DD/MM/YYYY');
    END IF;
    
    -- Laço de Pedidos
    FOR vc_Pedido IN (SELECT PCINTEGRACAOCORE.IDEXTERNO
                           , PCINTEGRACAOCORE.DATACRIACAO
                           , PCINTEGRACAOCORE.STATUS          
                        FROM PCINTEGRACAOCORE
                       WHERE (PCINTEGRACAOCORE.IDEXTERNO LIKE 'PED_%')
                         AND ((PCINTEGRACAOCORE.DATACRIACAO >= vdDataInicial) AND (PCINTEGRACAOCORE.DATACRIACAO < vdDataFinal+1))) LOOP
                         
      -- Pesquisa PCPEDCRETORNO 
      BEGIN
        SELECT PCPEDRETORNO.*
          INTO vrPedidoRetorno                  
          FROM PCPEDRETORNO
         WHERE (PCPEDRETORNO.ARQUIVOPED = vc_Pedido.IDEXTERNO);
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vrPedidoRetorno := vrLimpaPedidoRetorno;
      END;
    
      -- Pesquisa PCPEDCFV
      BEGIN
        SELECT PCPEDCFV.IMPORTADO
             , PCPEDCFV.OBSERVACAO_PC
          INTO vnImportado
             , vvObservacaoPc
          FROM PCPEDCFV
         WHERE (PCPEDCFV.NUMPEDRCA         = vrPedidoRetorno.NUMPEDRCA)
           AND (PCPEDCFV.CODUSUR           = vrPedidoRetorno.CODUSUR)
           AND (PCPEDCFV.CGCCLI            = vrPedidoRetorno.CGCCLI)
           AND (PCPEDCFV.DTABERTURAPEDPALM = vrPedidoRetorno.DTABERTURAPEDPALM);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnImportado    := NULL;
          vvObservacaoPc := NULL;
      END;

      -- Pesquisa PCPEDC
      BEGIN
        SELECT PCPEDC.NUMPED
             , PCPEDC.POSICAO
          INTO vnNumPed
             , vvPosicao
          FROM PCPEDC
         WHERE (PCPEDC.NUMPED = vrPedidoRetorno.NUMPED);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vnNumPed  := NULL;
          -- Se chegou a gerar a PCPEDRETORNO
          IF (NVL(vrPedidoRetorno.NUMPEDRCA,0) > 0) THEN
            IF (NVL(vrPedidoRetorno.NUMPED,0) > 0) THEN
              vvPosicao := 'C';
            ELSE
              vvPosicao := 'R';
            END IF;
          ELSE
            vvPosicao := NULL;
          END IF;
      END;
      
      -- Pesquisa PCNFSAID
      IF (NVL(vrPedidoRetorno.NUMTRANSVENDA,0) > 0) THEN
        BEGIN
          SELECT PCNFSAID.NUMNOTA
               , PCNFSAID.SITUACAONFE
            INTO vnNumNotaSai
               , vvSituacaoNfeSai
            FROM PCNFSAID
           WHERE (PCNFSAID.NUMTRANSVENDA = vrPedidoRetorno.NUMTRANSVENDA);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnNumNotaSai     := NULL;
            vvSituacaoNfeSai := NULL;
        END;
      ELSE
        vnNumNotaSai     := NULL;
        vvSituacaoNfeSai := NULL;
      END IF;
      
      -- Pesqisa PCESTCOM
      IF (NVL(vrPedidoRetorno.NUMTRANSVENDA,0) > 0) THEN
        BEGIN
          SELECT PCESTCOM.NUMTRANSENT
            INTO vnNumTransEnt
            FROM PCESTCOM
           WHERE (PCESTCOM.NUMTRANSVENDA = vrPedidoRetorno.NUMTRANSVENDA)
             AND (ROWNUM                 = 1);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnNumTransEnt := NULL;
        END;
      ELSE
        vnNumTransEnt := NULL;
      END IF;
      
      -- Pesquisa PCNFENT
      IF (NVL(vnNumTransEnt,0) > 0) THEN
        BEGIN
          SELECT PCNFENT.NUMNOTA
               , PCNFENT.SITUACAONFE
            INTO vnNumNotaEnt
               , vvSituacaoNfeEnt
            FROM PCNFENT
           WHERE (PCNFENT.NUMTRANSENT = vnNumTransEnt)
             AND (ROWNUM              = 1);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vnNumNotaEnt     := NULL;
            vvSituacaoNfeEnt := NULL;
        END;
      ELSE
        vnNumNotaEnt     := NULL;
        vvSituacaoNfeEnt := NULL;
      END IF;
      
      
      -- Prepara dados externos
      vvIdExternoRetorno      := 'RET_' || vc_Pedido.IDEXTERNO;
      vvIdExternoCancelamento := 'CAN_' || vc_Pedido.IDEXTERNO;
      vvIdExternoNotaFiscal   := 'NOT_' || vc_Pedido.IDEXTERNO;
      vvIdExternoDevolucao    := 'DEV_' || vc_Pedido.IDEXTERNO;
      vvIdExternoPrePed       := vrPedidoRetorno.ARQUIVOORD;
      vnStatsRetorno          := NULL;
      vnStatsCancelamento     := NULL;
      vnStatusNotaFiscal      := NULL;
      vnStatusDevolucao       := NULL;
      vnStatusPrePed          := NULL;
      
      -- Pequisa PCINTEGRACAOCORE
      FOR vc_Integracao IN (SELECT PCINTEGRACAOCORE.IDEXTERNO
                                 , PCINTEGRACAOCORE.DATACRIACAO
                                 , PCINTEGRACAOCORE.STATUS          
                              FROM PCINTEGRACAOCORE
                             WHERE (PCINTEGRACAOCORE.IDEXTERNO IN (vvIdExternoRetorno, vvIdExternoCancelamento, vvIdExternoNotaFiscal, vvIdExternoDevolucao, vvIdExternoPrePed))) LOOP
        IF    (SUBSTR(vc_Integracao.IDEXTERNO,1,4) = 'RET_')     THEN
          vnStatsRetorno      := vc_Integracao.STATUS;
        ELSIF (SUBSTR(vc_Integracao.IDEXTERNO,1,4) = 'CAN_')     THEN
          vnStatsCancelamento := vc_Integracao.STATUS;
        ELSIF (SUBSTR(vc_Integracao.IDEXTERNO,1,4) = 'NOT_')     THEN
          vnStatusNotaFiscal  := vc_Integracao.STATUS;
        ELSIF (SUBSTR(vc_Integracao.IDEXTERNO,1,4) = 'DEV_')     THEN
          vnStatusDevolucao   := vc_Integracao.STATUS;
        ELSIF (SUBSTR(vc_Integracao.IDEXTERNO,1,8) = 'PRE-PED_') THEN
          vnStatusPrePed      := vc_Integracao.STATUS;
        END IF;                             
      END LOOP;     
            
      -- Insere Dados na Table   
      OUTROW.ARQUIVOPED           := vc_Pedido.IDEXTERNO;
      OUTROW.DATACRIACAO          := vc_Pedido.DATACRIACAO;
      OUTROW.STATUSPED            := vc_Pedido.STATUS;
      OUTROW.NUMPEDVAN            := vrPedidoRetorno.NUMPEDVAN;      
      OUTROW.CODFILIAL            := vrPedidoRetorno.CODFILIAL;
      OUTROW.NUMPEDRCA            := vrPedidoRetorno.NUMPEDRCA;
      OUTROW.IMPORTADO            := vnImportado;
      OUTROW.GEROURET             := vrPedidoRetorno.GEROURET;
      OUTROW.STATUSRET            := vnStatsRetorno;
      OUTROW.NUMPED               := vnNumPed;
      OUTROW.POSICAO              := vvPosicao;
      OUTROW.GEROUCAN             := vrPedidoRetorno.GEROUCAN;
      OUTROW.STATUSCAN            := vnStatsCancelamento;
      OUTROW.NUMTRANSVENDA        := vrPedidoRetorno.NUMTRANSVENDA;
      OUTROW.NUMNOTASAI           := vnNumNotaSai;      
      OUTROW.SITUACAONFESAI       := vvSituacaoNfeSai;            
      OUTROW.GEROUNOT             := vrPedidoRetorno.GEROUNOT;
      OUTROW.STATUSNOT            := vnStatusNotaFiscal;
      OUTROW.NUMTRANSENT          := vnNumTransEnt;
      OUTROW.NUMNOTAENT           := vnNumNotaEnt;
      OUTROW.SITUACAONFEENT       := vvSituacaoNfeEnt;
      OUTROW.GEROUDEV             := vrPedidoRetorno.GEROUDEV;
      OUTROW.STATUSDEV            := vnStatusDevolucao;
      -- Se chegou a gerar a PCPEDRETORNO
      IF (NVL(vrPedidoRetorno.NUMPEDRCA,0) > 0) THEN
        IF (vvIdExternoPrePed IS NULL) THEN
          OUTROW.POSSUIPREPED     := 'N';
        ELSE
          OUTROW.POSSUIPREPED     := 'S';
        END IF;
      ELSE
        OUTROW.POSSUIPREPED       := NULL;
      END IF;
      OUTROW.STATUSPREPED         := vnStatusPrePed;
      OUTROW.OBSERVACAO_PC        := vvObservacaoPc;
      PIPE ROW(OUTROW);

    END LOOP; -- Fim: Laço de Pedidos
  
  END F_OBTER_PEDIDOS_HUB_INTEGRACAO;
        
END PKG_FUNCOES_OPERADOR_LOGISTICO;