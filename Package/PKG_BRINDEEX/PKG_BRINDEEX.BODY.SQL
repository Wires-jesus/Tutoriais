CREATE OR REPLACE PACKAGE BODY PKG_BRINDEEX IS

  /**************************************************************************************************************
  Proposito: Validar novo método de campanhas de brinde (Brinde Express)

                        Historico de Alteracoes

  Versão: 22 Pacote
  Utilizada por: PCSIS316, PCSIS382
  ---------------------------------------------------------------------------------------------------------------
  Data        Tarefa             Responsavel         Descricao
  ----------  -------            --------------      --------------------------------------------------------------------------
  13/05/2011  .......            Rodrigo Santos      Criação do escopo da procedure.
  27/05/2011  .......            Rodrigo Santos      Implementação do tratamento de "estoque de brinde"(descontinuado).
  30/05/2011  .......            Rodrigo Santos      Implementação de código para contemplar campanhas por
                                                     Valor Total(VL), Quantidade Total(QT) e Peso Total(PE).
  01/06/2011  .......            Rodrigo Santos      Implementado esquema para substituição do brinde por
                                                     similar caso não haja estoque disponível.
  15/07/2011  .......            Rodrigo Santos      Alterada a procedure para verificar o campo
                                                     PCBRINDEEX.QTMINREGRASATENDER.
  04/08/2011  .......            Rodrigo Santos      Adequado sistema de multiplos brindes.("PCBRINDEEXPREMIO.ACEITAMULTIPLO")
  27/10/2011  .......            Rodrigo Santos      Pkg alterada para retornar dados em forma de tabela dinâmica.
  19/10/2012   178323            Rodrigo Santos      Ajuste para não considerar campanhas canceladas, ou seja, com PCBRINDEEX.DTCANCEL preenchido.
  18/01/2013   187210            Fabrício Borges     Correção quando tiver para um tipo de exclusividade dois registros diferentes.
  14/02/2013   187386            Rodrigo Santos      Ajuste na verificação de restrições de EXCLUSIVIDADE.
  27/02/2013   191073            Rodrigo Santos      Ajuste na verificação de restrições para não pular todas as campanhas ao sair do loop de "Campanhas_Ativas".
  23/05/2013   199384            Rodrigo Santos      Ajuste no "ALTER SESSION" para prevenir retorno de exceções.
  25/06/2013   199981            Rodrigo Santos      Ajuste na apuração dos brindes(P_GERARPREMIO) para retornar corretamente os resultados.
  04/10/2013   212812            Rafael Braga        Ajuste na procedure PROCEDURE P_GERARPREMIO, parâmetro filialestoque, de number para varchar2(2).
  08/10/2013   213115            Rodrigo Santos      Ajuste referente a busca da "Data Base" para campanha Acumulativa.
  10/10/2013   213115            Rodrigo Santos      Ajuste referente a busca do vetor de apuração X vetor de premios.
  18/10/2013   213115            Rodrigo Santos      Ajustes diversos relacionados a campanhas acumulativas (P&G).
  06/11/2013   2033.003152.2013  Rodrigo Santos      Ajuste na busca da qtde máxima de multiplos, quando existe mais de um brinde para um mesmo grupo de regras.
  28/08/2015   2550.056230.2015  Rafael Braga        Ajuste no select para buscar produto similar, pois estava buscando o próprio produto original, ao invés de verificar o similar.
  01/09/2015   HIS.02580.2015    Guilherme Freitas   Ajustado para não considerar os itens de bonificaçao manual na apuração.
  17/02/2016   0.018700.2016     Guilherme Freitas   Quando estava não trabalhava com brinde por embalagem, estava ocorrendo erro ao apurar as campanhas de brinde.
  **************************************************************************************************************/

  /**************************************************************************************************************
  ----------------------ÍNDICE-----------------------
  1.0     - Início
   1.1     - Carregar Dados Básicos
   1.2     - Início da validação da campanha
    1.2.1   - Validar origem do pedido.
    1.2.2   - Validar o campo "Validar Campanha Brinde" no cadastro do cliente aba "Cond. Comerciais/Parâmetros".
    1.2.3   - Verificar RESTRIÇÕES.
     1.2.3.1 - Verificar restrições de PROIBIÇÃO.
     1.2.3.2 - Verificar restrições de EXCLUSIVIDADE.
    1.2.4   - Validar Regras.
     1.2.4.1 - Compondo tabela de apuração dos resultados das validações.
    1.2.5   - Validar regra corrente (PCBRINDEEXVALIDACOES).
     1.2.5.1 - Configuração de validação incorreta(tipo nulo).
     1.2.5.2 - Validar tipo "PE" - Peso Total.
     1.2.5.3 - Validar tipo "QT" - Qtde Tota.
     1.2.5.4 - Validar tipo "VL" - Valor Total.
     1.2.5.5 - Validar tipo "P" - Produto.
     1.2.5.6 - Validar tipo "D" - Departamento.
     1.2.5.7 - Validar tipo "S" - Seção.
     1.2.5.8 - Validar tipo "F" - Fornecedor.
     1.2.5.9 - Validar tipo "GP" - Grupo de Produtos.
     1.2.5.10 - Validar tipo "PP" - Produto Principal.
     1.2.5.11 - Validar tipo "MX" - Mix Total.
    1.2.6   - Passando tabela de apuração a limpo.
   1.3     - Finalizando bloco de apuração das campanhas ativas.


  ------------------FUNCIONALIDADES------------------
   - O que a pkg FAZ:
     a) Existem duas procedures para geração de dados e uma função para retorno dos dados, sendo:
        1. P_VALIDARPEDIDO: Faz a apuração dos grupos de regras das campanhas vigentes em relação aos itens do pedido
                            retornando os dados da apuração.
        2. P_GERARPREMIO: Gera os prêmios relacionados aos grupos de regras retornados pela apuração feita por "P_VALIDARPEDIDO".
        3. REL_BRINDES: Retorna a relação de brindes contemplados pelas campanhas vigentes através do pedido.
                        Ex.: "SELECT * FROM TABLE(pkg_brindeex.rel_brindes(:numped))"

   - O que precisa ser feito externamente:
     a) A pkg não está preparada para fazer a inserção do(s) brinde(s) nos pedidos ou criar novos pedidos TV5;
     b) A pkg não realiza atualização dos campos "PCBRINDEEX.QTBRINDESDISP" e "PCBRINDEEXPREMIO.QTBRINDESDISP", consequentemente
        não valida os campos "PCBRINDEEX.QTMAXBRINDES" e "PCBRINDEEXPREMIO.QTMAXBRINDES", estes devem ser manipulados pelas
        rotinas de vendas;
     c)
  **************************************************************************************************************/

  /*************************************************************************************************************
                                          MÉTODOS AUXILIARES
  **************************************************************************************************************/
  PROCEDURE P_ATUALIZAR_DTBASE (PCODCAMP  NUMBER)
  IS
  VD_DTINI  DATE;
  VD_DTFIM  DATE;
  BEGIN

    SELECT dtinicio, dtfim
      INTO VD_DTINI, VD_DTFIM
      FROM pcbrindeex
     WHERE codbrex = PCODCAMP;

    SELECT NVL(MAX(c.numped),0), NVL(MAX(c.hora),0), NVL(MAX(c.minuto),0), nvl(MAX(c.data),VD_DTINI)
      INTO G_NUMPED_GZERO, G_HORAULTPEDACUMU, G_MINULTPEDACUMU, G_DTBASEACUMUL
      FROM pcpedi i, pcpedc c
     WHERE c.numped = i.numped
       AND c.data BETWEEN VD_DTINI AND VD_DTFIM
       AND i.codigobrinde = PCODCAMP
       AND c.posicao <> 'C' --Tarefa: 213115
       AND c.dtcancel IS NULL --Tarefa: 213115
       AND i.grpregrabrinde = 0
       AND c.codcli = G_CODCLI;

    VB_GRPZERO_CONTEMPLADO := TRUE;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN

      G_DTBASEACUMUL    := VD_DTINI;
      G_HORAULTPEDACUMU := 0;
      G_MINULTPEDACUMU  := 0;
      VB_GRPZERO_CONTEMPLADO := FALSE;

  END P_ATUALIZAR_DTBASE;

  -------------------------------------------------------------------------------------------------------------

  PROCEDURE P_VALIDARPEDIDO(pn_codcli IN NUMBER,
                            ps_origemped IN VARCHAR2,
                            ps_codfilial IN VARCHAR2,
                            pn_codemitente IN NUMBER,
                            pn_codusur IN NUMBER,
                            pn_codplpag IN NUMBER,
                            pd_data IN DATE,
                            pn_numregiao IN NUMBER,
                            pn_codprod IN NUMBER,
                            pn_numped IN NUMBER DEFAULT 0,
                            pn_numpedtv5 IN NUMBER DEFAULT 0,
                            apuracao  OUT T_ApuraGrupoRegras,
                            msg       OUT VARCHAR2,
                            criticas  OUT TTvCriticasRestr) IS
    CURSOR C_Campanhas_Ativas is
      select *
        from pcbrindeex
       where
       TRUNC(SYSDATE) between trunc(dtinicio) and trunc(dtfim)
       and dtcancel is null;  --Tarefa: 178323

    CURSOR C_Validacoes(pn_codbrex NUMBER, pn_regra NUMBER) IS
      SELECT *
        FROM pcbrindeexvalidacoes
       WHERE gruporegra in (pn_regra)
         AND codbrex = pn_codbrex;

    CURSOR C_Restricoes(pn_codbrex NUMBER, pn_gruporegra NUMBER) IS
      SELECT COUNT(1) QTDE, VALIDACAO, TIPO, GRUPOREGRA
        FROM pcbrindeexrestricoes
       WHERE codbrex = pn_codbrex
         and NVL(gruporegra,0) = pn_gruporegra
      GROUP BY VALIDACAO, TIPO, GRUPOREGRA;

    CURSOR C_Regras(pn_codbrex NUMBER, ps_ListaGrupoRegraNaoAtender VARCHAR2 DEFAULT '-1') IS
      SELECT gruporegra, qtminregrasatender, (COUNT(*)) qt
        FROM pcbrindeexvalidacoes
       WHERE codbrex = pn_codbrex
         AND gruporegra NOT IN (SELECT item
                  FROM TABLE(FERRAMENTAS.F_RETORNARLISTA(ps_ListaGrupoRegraNaoAtender, ','))
                 WHERE ITEM IS NOT NULL)
       GROUP BY gruporegra, qtminregrasatender;

    --"Constantes"
    --vs_parametro1552          PCCONSUM.GERARBRINDEPEDBONIFIC%TYPE;
    vn_codcli          PCCLIENT.codcli%TYPE;
    vn_codfunclanc     pcpedc.codemitente%TYPE;
    vn_codrca          pcpedc.codusur%TYPE;
    vs_origemped       pcpedc.origemped%TYPE;
    vs_clivalidabrinde pcclient.validarcampanhabrinde%TYPE;
    vd_dataped         pcpedc.data%type;
    vn_numregiao       pcpedc.numregiao%type;
    --Variáveis para os cursores
    campanhas  C_Campanhas_Ativas%ROWTYPE;
    validacoes C_Validacoes%ROWTYPE;
    restricoes C_Restricoes%ROWTYPE;
    regras     C_Regras%ROWTYPE;
    --Variáveis utilitárias
    vt_tabelaapuracao        T_ApuraGrupoRegras := T_ApuraGrupoRegras();
    vt_tabelaapuracaofinal   T_ApuraGrupoRegras := T_ApuraGrupoRegras();
    vr_tabelaapuracao        T_ApuraRegra := T_ApuraRegra(NULL,NULL,NULL,NULL,NULL);
    vn_qtloops               NUMBER;
    vn_nr                    NUMBER;
    vn_count                 NUMBER;
    vn_grupook               NUMBER;
    vn_basemultiplo          NUMBER;
    vn_qtregrasatender       NUMBER;
    vn_qtbrindescontemplados NUMBER;
    vn_maxmultiplo           NUMBER;
    vn_brindescamp           NUMBER;
    v_vscodfilialretira       varchar2(3);
    v_vscodauxiliar           number;

    vn_qtacumuladavenda      pcbrindeex.qtacumuladavenda%TYPE;

    v_AplicBrindCampanhaComDesc varchar2(1);

    vs_classevenda              varchar2(10);
    vn_codpraca                 number;
    vn_codrede                  number;
    vn_codcliprinc              number;
    vn_codatv1                  number;
    vn_codsupervisor            number;
    vsListaGrupoRegraNaoAtender VARCHAR2(4000) DEFAULT NULL;
    
    TYPE TRecGrupoRegraNaoAtender IS RECORD(
         vnCodGrupo               NUMBER,
         vvCritica                VARCHAR2(2000)); 
    TYPE TTvGrupoRegraNaoAtender  IS TABLE OF TRecGrupoRegraNaoAtender INDEX BY BINARY_INTEGER;
    vtIndGrupoRegraNaoAtender     TTvGrupoRegraNaoAtender;
    vtRelGrupoRegraNaoAtender     TTvGrupoRegraNaoAtender;

    --Variaveis para testes
    --V_teste  NUMBER;
    --V_Teste2 NUMBER;

    PROCEDURE buscar_qtregrasatender(pcodcamp           IN NUMBER,
                                     pgrpregra          IN NUMBER,
                                     pqtregras          OUT NUMBER,
                                     pqtregrasatendidas OUT NUMBER) AS
    BEGIN

      SELECT nvl(v.qtminregrasatender, 0)
        INTO pqtregras
        FROM pcbrindeexvalidacoes v
       WHERE v.codbrex = pcodcamp
         AND v.gruporegra = pgrpregra
         AND ROWNUM = 1;

      IF pqtregras = 0 THEN
        SELECT COUNT(*)
          INTO pqtregras
          FROM pcbrindeexvalidacoes v
         WHERE v.codbrex = pcodcamp
           AND v.gruporegra = pgrpregra
         GROUP BY v.codbrex, v.gruporegra;
      END IF;

      pqtregrasatendidas := 0;
      FOR F IN 1 .. vt_tabelaapuracao.LAST LOOP
        IF vt_tabelaapuracao(F).codcamp = pcodcamp
          AND vt_tabelaapuracao(F).gruporegra = pgrpregra
        THEN
          pqtregrasatendidas := pqtregrasatendidas + 1;
        END IF;
      END LOOP;

    END buscar_qtregrasatender;
    
    PROCEDURE add_Critica(pi_nCodBrinde IN NUMBER, pi_vCritica IN VARCHAR2) IS    
      viIdx INTEGER;
    BEGIN
      viIdx := NVL(criticas.COUNT,0) + 1;
      criticas(viIdx).vnCodCampanha := pi_nCodBrinde; 
      criticas(viIdx).vvCritica     := pi_vCritica; 
    END;
    
    PROCEDURE add_GrupoRegraNaoAtender(pi_nCodBrinde IN NUMBER, pi_nGrupoRegra IN NUMBER, pi_vCritica IN VARCHAR2) IS    
      vrGrupoRegraNaoAtender TRecGrupoRegraNaoAtender;
      viIdx                  INTEGER;
    BEGIN
      vrGrupoRegraNaoAtender.vnCodGrupo := pi_nGrupoRegra; 
      vrGrupoRegraNaoAtender.vvCritica  := pi_vCritica || ' (Grupo Regra ' || NVL(pi_nGrupoRegra,0) || ')';
    
      IF (NOT vtIndGrupoRegraNaoAtender.EXISTS(pi_nGrupoRegra)) THEN             
        vtIndGrupoRegraNaoAtender(pi_nGrupoRegra) := vrGrupoRegraNaoAtender;
        
        viIdx := NVL(vtRelGrupoRegraNaoAtender.COUNT,0) + 1;
        vtRelGrupoRegraNaoAtender(viIdx) := vrGrupoRegraNaoAtender;
      END IF;
      
      viIdx := NVL(criticas.COUNT,0) + 1;
      criticas(viIdx).vnCodCampanha := pi_nCodBrinde; 
      criticas(viIdx).vnCodGrupo    := pi_nGrupoRegra; 
      criticas(viIdx).vvCritica     := pi_vCritica; 
    END;

  BEGIN
    --1.0 - Início

    --1.1 - Carregar Dados Básicos
    /*SELECT pcclient.codcli,
           pcpedc.origemped,
           nvl(pcclient.validarcampanhabrinde, 'S'),
           pcpedc.codemitente,
           pcpedc.codusur,
           pcpedc.data,
           pcpedc.numregiao
      INTO vn_codcli,
           vs_origemped,
           vs_clivalidabrinde,
           vn_codfunclanc,
           vn_codrca,
           vd_dataped,
           vn_numregiao
      FROM pcpedc, pcclient
     WHERE pcpedc.codcli = pcclient.codcli
       AND pcpedc.numped = pn_numped;*/
    vn_codcli := pn_codcli;
    vs_origemped := ps_origemped;
    vn_codfunclanc := pn_codemitente;
    vn_codrca := pn_codusur;
    vd_dataped := pd_data;
    vn_numregiao := pn_numregiao;
    v_AplicBrindCampanhaComDesc :=  FERRAMENTAS.PARAMETROS.getVALORALFA('CONCEDE_BRINDE_COM_PERDESC', ps_codfilial);

    SELECT pcclient.codcli,
           nvl(pcclient.validarcampanhabrinde, 'S')
      INTO vn_codcli,
           vs_clivalidabrinde
      FROM pcclient
     WHERE pcclient.codcli = pn_codcli;

    G_CODCLI := vn_codcli;

    vn_nr := 0;

    OPEN C_Campanhas_Ativas;
    FETCH C_Campanhas_Ativas
      INTO campanhas;

    vt_tabelaapuracao.DELETE;
    vn_qtloops := 0;

    <<loop_principal>> --> Executado uma vez para cada campanha ativa existente
    WHILE C_Campanhas_Ativas%FOUND LOOP
      --1.2 - Início da validação da campanha
      vn_nr := vn_nr + 1;
      campanhas.acumulativa := nvl(campanhas.acumulativa,'N');
      campanhas.usaalienacao := nvl(campanhas.usaalienacao,'N');

      IF campanhas.acumulativa = 'S'
      THEN
        P_ATUALIZAR_DTBASE(campanhas.codbrex);
      END IF;

      IF (nvl(campanhas.qtmaxbrindes,999999999) > 0) THEN

        SELECT NVL(SUM(I.QT), 0)
          INTO VN_BRINDESCAMP
          FROM PCPEDI I, PCPEDC C
         WHERE I.CODIGOBRINDE = CAMPANHAS.CODBREX
           AND I.NUMPED       = C.NUMPED
           AND ((NVL(I.BRINDE, 'N') = 'S') OR
               (NVL(C.BRINDE, 'N') = 'S' AND NVL(I.BRINDE, 'N') = 'N'))
           AND  I.NUMPED = C.NUMPED
           AND I.DATA BETWEEN campanhas.dtinicio AND campanhas.dtfim;

        IF (vn_brindescamp >= nvl(campanhas.qtmaxbrindes,999999999))
        THEN
          msg := 'Quantidade máxima de brindes para a campanha atingida!';
          add_Critica(campanhas.codbrex, msg);
          GOTO FIM_LOOP_CAMPANHAS;
        END IF;
      END IF;
      --1.2.1 - Validar origem do pedido.
      CASE vs_origemped
        WHEN 'A' THEN
          IF NVL(campanhas.usaas, 'N') = 'N' THEN
            msg := 'Campanha ' || campanhas.codbrex ||
                   ' não disponível para Auto-Serviço.';
            add_Critica(campanhas.codbrex, msg);
            GOTO FIM_LOOP_CAMPANHAS;
            --EXIT loop_principal; 3285.086248.2015
          END IF;
        WHEN 'F' THEN
          IF NVL(campanhas.vendafv, 'N') = 'N' THEN
            msg := 'Campanha ' || campanhas.codbrex ||
                   ' não disponível para o Força de Vendas.';
            add_Critica(campanhas.codbrex, msg);
            GOTO FIM_LOOP_CAMPANHAS;
            --EXIT loop_principal; 3285.086248.2015
          END IF;
        WHEN 'T' THEN
          IF NVL(campanhas.vendatelemark, 'N') = 'N' THEN
            msg := 'Campanha ' || campanhas.codbrex ||
                   ' não disponível para o Telemarketing.';
            add_Critica(campanhas.codbrex, msg);
            GOTO FIM_LOOP_CAMPANHAS;
            --EXIT loop_principal; 3285.086248.2015
          END IF;
        WHEN 'B' THEN
          IF NVL(campanhas.vendabalcao, 'N') = 'N' THEN
            msg := 'Campanha ' || campanhas.codbrex ||
                   ' não disponível para venda Balcão.';
            add_Critica(campanhas.codbrex, msg);
            GOTO FIM_LOOP_CAMPANHAS;
            --EXIT loop_principal; 3285.086248.2015
          END IF;
        WHEN 'R' THEN
          IF NVL(campanhas.vendabalcaoreserva, 'N') = 'N' THEN
            msg := 'Campanha ' || campanhas.codbrex ||
                   ' não disponível para venda Balcão Reserva.';
            add_Critica(campanhas.codbrex, msg);
            GOTO FIM_LOOP_CAMPANHAS;
            --EXIT loop_principal; 3285.086248.2015
          END IF;
        WHEN 'C' THEN
          IF NVL(campanhas.vendacallcenter, 'N') = 'N' THEN
            msg := 'Campanha ' || campanhas.codbrex ||
                   ' não disponível para o Call Center.';
            add_Critica(campanhas.codbrex, msg);
            GOTO FIM_LOOP_CAMPANHAS;
            --EXIT loop_principal; 3285.086248.2015
          END IF;
        WHEN 'W' THEN
          IF NVL(campanhas.vendaecommerce, 'N') = 'N' THEN
            msg := 'Campanha ' || campanhas.codbrex ||
                   ' não disponível para o e-Commerce.';
            add_Critica(campanhas.codbrex, msg);
            GOTO FIM_LOOP_CAMPANHAS;
          END IF;            

        ELSE
          IF vs_origemped <> 'E' THEN
            msg := 'Origem do pedido desconhecida.';
            add_Critica(campanhas.codbrex, msg);
            GOTO FIM_LOOP_CAMPANHAS;
            --EXIT loop_principal; 3285.086248.2015
          END IF;
      END CASE;
    --Fim 1.2.1

      --1.2.2 - Validar o campo "Validar Campanha Brinde" no cadastro do cliente aba "Cond. Comerciais/Parâmetros".
      IF vs_clivalidabrinde = 'N' THEN
        msg := 'Cliente parametrizado para não validar campanhas de brinde!(Rotina 302, aba "Condições Comerciais/Parâmetros".)';
        EXIT loop_principal;
      END IF;
      --Fim 1.2.2

      /* BUSCAR DADOS DO CLIENTE PARA CONSULTA DAS RESTRIÇÕES */
      SELECT CLASSEVENDA, CODPRACA, CODREDE, CODCLIPRINC, CODATV1
        INTO VS_CLASSEVENDA, VN_CODPRACA, VN_CODREDE, VN_CODCLIPRINC, VN_CODATV1
        FROM PCCLIENT
       WHERE PCCLIENT.CODCLI = pn_codcli;
  
      vtIndGrupoRegraNaoAtender.DELETE;                               
      vtRelGrupoRegraNaoAtender.DELETE;                               
     
      -- INICIO: Loop de Todas as Regras do Brinde
      FOR vc_Regras_Brinde IN (SELECT DISTINCT NVL(gruporegra,0) gruporegra
                                 FROM pcbrindeexvalidacoes
                                WHERE (codbrex = campanhas.codbrex)) LOOP
                                
        --1.2.3 - Verificar RESTRIÇÕES para cada Regra do Loop
        OPEN C_Restricoes(campanhas.codbrex, vc_Regras_Brinde.gruporegra);
        FETCH C_Restricoes
          INTO restricoes;
  
        WHILE C_Restricoes%FOUND LOOP
          vn_count := 0;
          IF restricoes.validacao = 'P' THEN
            --1.2.3.1 - Verificar restrições de PROIBIÇÃO
            CASE restricoes.tipo
            --Proibição para Região -> "R"
              WHEN 'R' THEN
                SELECT COUNT(*)
                  INTO VN_COUNT
                  FROM PCBRINDEEXRESTRICOES
                  WHERE TIPO              = RESTRICOES.TIPO
                    AND VALIDACAO         = RESTRICOES.VALIDACAO
                    AND NVL(GRUPOREGRA,0) = RESTRICOES.GRUPOREGRA 
                    AND CODBREX           = CAMPANHAS.CODBREX
                    AND ((CODIGO  = NVL(VN_NUMREGIAO, -1)) OR
                         ((NVL(VN_NUMREGIAO, 0) = 0) AND VN_CODPRACA IN (SELECT CODPRACA
                                                                           FROM PCPRACA
                                                                          WHERE NUMREGIAO = VN_NUMREGIAO)
                         )
                        );
                IF vn_count > 0 THEN
                  msg := 'Campanha com proibição para a região ' || TO_CHAR(VN_NUMREGIAO);
                  add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
                END IF;
  
            --Proibição para classes de clientes -> "CL"
              WHEN 'CL' THEN
                SELECT COUNT(*)
                  INTO VN_COUNT
                  FROM PCBRINDEEXRESTRICOES
                 WHERE TIPO              = RESTRICOES.TIPO
                   AND VALIDACAO         = RESTRICOES.VALIDACAO
                   AND NVL(GRUPOREGRA,0) = RESTRICOES.GRUPOREGRA 
                   AND CODBREX           = CAMPANHAS.CODBREX
                   AND CODIGOA           = VS_CLASSEVENDA;
                IF vn_count > 0 THEN
                  msg := 'Campanha com proibição para a classe ' || TO_CHAR(VS_CLASSEVENDA);
                  add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
                END IF;
  
            --Proibição para praças -> "P"
              WHEN 'P' THEN
                SELECT COUNT(*)
                  INTO VN_COUNT
                  FROM PCBRINDEEXRESTRICOES
                 WHERE TIPO              = RESTRICOES.TIPO
                   AND VALIDACAO         = RESTRICOES.VALIDACAO
                   AND NVL(GRUPOREGRA,0) = RESTRICOES.GRUPOREGRA 
                   AND CODBREX           = CAMPANHAS.CODBREX
                   AND CODIGO            = VN_CODPRACA;
  
                IF vn_count > 0 THEN
                  msg := 'Campanha com proibição para a praça ' || TO_CHAR(VN_CODPRACA);
                  add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
                END IF;
  
            --Proibição para redes de clientes -> "RC"
              WHEN 'RC' THEN
                SELECT COUNT(*)
                  INTO VN_COUNT
                  FROM PCBRINDEEXRESTRICOES
                 WHERE TIPO              = RESTRICOES.TIPO
                   AND VALIDACAO         = RESTRICOES.VALIDACAO
                   AND NVL(GRUPOREGRA,0) = RESTRICOES.GRUPOREGRA 
                   AND CODBREX           = CAMPANHAS.CODBREX
                   AND CODIGO            = VN_CODREDE;
  
                IF vn_count > 0 THEN
                  msg := 'Campanha com proibição para a rede de clientes ' || TO_CHAR(VN_CODREDE);
                  add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
                END IF;
  
            --Proibição para cliente -> "C"
              WHEN 'C' THEN
                SELECT COUNT(*)
                  INTO VN_COUNT
                  FROM PCBRINDEEXRESTRICOES
                 WHERE TIPO              = RESTRICOES.TIPO
                   AND VALIDACAO         = RESTRICOES.VALIDACAO
                   AND NVL(GRUPOREGRA,0) = RESTRICOES.GRUPOREGRA 
                   AND CODBREX           = CAMPANHAS.CODBREX
                   AND CODIGO            = vn_codcli;

                IF vn_count > 0 THEN
                  msg := 'Campanha com proibição para o cliente ' || TO_CHAR(vn_codcli);
                  add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
                END IF;
               
  
            --Proibição para cliente principal -> "CP"
              WHEN 'CP' THEN
                SELECT COUNT(*)
                  INTO VN_COUNT
                  FROM PCBRINDEEXRESTRICOES
                 WHERE TIPO              = RESTRICOES.TIPO
                   AND VALIDACAO         = RESTRICOES.VALIDACAO
                   AND NVL(GRUPOREGRA,0) = RESTRICOES.GRUPOREGRA 
                   AND CODBREX           = CAMPANHAS.CODBREX
                   AND CODIGO            = VN_CODCLIPRINC;
  
                IF vn_count > 0 THEN
                  msg := 'Campanha com proibição para o cliente principal ' || TO_CHAR(VN_CODCLIPRINC);
                  add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
                END IF;
  
            --Proibição para Filial -> "F"
              WHEN 'F' THEN
                SELECT COUNT(*)
                  INTO VN_COUNT
                  FROM PCBRINDEEXRESTRICOES
                 WHERE TIPO              = RESTRICOES.TIPO
                   AND VALIDACAO         = RESTRICOES.VALIDACAO
                   AND NVL(GRUPOREGRA,0) = RESTRICOES.GRUPOREGRA 
                   AND CODBREX           = CAMPANHAS.CODBREX
                   AND CODIGOA IN (ps_codfilial);
  
                IF vn_count > 0 THEN
                  msg := 'Campanha com proibição para a filial ' || TO_CHAR(ps_codfilial);
                  add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
                END IF;
  
            --Proibição para Ramo de Atividade -> "RA"
              WHEN 'RA' THEN
                SELECT COUNT(*)
                  INTO VN_COUNT
                  FROM PCBRINDEEXRESTRICOES
                 WHERE TIPO              = RESTRICOES.TIPO
                   AND VALIDACAO         = RESTRICOES.VALIDACAO
                   AND NVL(GRUPOREGRA,0) = RESTRICOES.GRUPOREGRA 
                   AND CODBREX           = CAMPANHAS.CODBREX
                   AND CODIGO            = VN_CODATV1;
  
                IF vn_count > 0 THEN
                  msg := 'Campanha com proibição para o ramo de atividade ' || TO_CHAR(VN_CODATV1);
                  add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
                END IF;
  
            --Proibição para Plano de Pgto -> "PL"
              WHEN 'PL' THEN
                SELECT COUNT(*)
                  INTO VN_COUNT
                  FROM PCBRINDEEXRESTRICOES
                 WHERE TIPO              = RESTRICOES.TIPO
                   AND VALIDACAO         = RESTRICOES.VALIDACAO
                   AND NVL(GRUPOREGRA,0) = RESTRICOES.GRUPOREGRA 
                   AND CODBREX           = CAMPANHAS.CODBREX
                   AND CODIGO IN (pn_codplpag);
  
                IF vn_count > 0 THEN
                  msg := 'Campanha com proibição para o plano de pagamento ' || TO_CHAR(pn_codplpag);
                  add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
                END IF;
  
            --Proibição para Supervisor -> "SP"
              WHEN 'SP' THEN
                SELECT COUNT(*)
                  INTO vn_count
                  FROM pcusuari u,
                       PCBRINDEEXRESTRICOES B
                 WHERE B.TIPO              = RESTRICOES.TIPO
                   AND B.VALIDACAO         = RESTRICOES.VALIDACAO
                   AND NVL(B.GRUPOREGRA,0) = RESTRICOES.GRUPOREGRA 
                   AND B.CODBREX           = CAMPANHAS.CODBREX
                   AND u.codusur           = VN_CODRCA
                   AND u.codsupervisor     = B.codigo;
  
                IF vn_count > 0 THEN
                  SELECT CODSUPERVISOR
                    INTO vn_codsupervisor
                    FROM PCUSUARI
                   WHERE CODUSUR = VN_CODRCA;
  
                  msg := 'Campanha com proibição para o supervisor ' || TO_CHAR(vn_codsupervisor);
                  add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
                END IF;
  
             --Proibição para RCA -> "RX"
              WHEN 'RX' THEN
                SELECT COUNT(*)
                  INTO VN_COUNT
                  FROM PCBRINDEEXRESTRICOES
                 WHERE TIPO              = RESTRICOES.TIPO
                   AND VALIDACAO         = RESTRICOES.VALIDACAO
                   AND NVL(GRUPOREGRA,0) = RESTRICOES.GRUPOREGRA 
                   AND CODBREX           = CAMPANHAS.CODBREX
                   AND CODIGO            = vn_codrca;
  
                IF vn_count > 0 THEN
  --              IF vn_codrca = restricoes.codigo THEN
                  msg := 'Campanha com proibição para o RCA ' || TO_CHAR(vn_codrca);
                  add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
                END IF;
  
            --Proibição inválida
              WHEN NULL THEN
                msg := 'Campanha código ' || TO_CHAR(campanhas.codbrex) ||
                       ', com proibição inválida!';
                add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
              ELSE
                msg := 'Campanha código ' || TO_CHAR(campanhas.codbrex) ||
                       ', com proibição inválida!';
            END CASE;
          --Fim 1.2.3.1
  
          ELSIF restricoes.validacao = 'E' THEN
            --1.2.3.2 - Verificar restrições de EXCLUSIVIDADE
            CASE restricoes.tipo
            --Exclusividade para Região -> "R"
              WHEN 'R' THEN
                select COUNT(*)
                  INTO VN_COUNT
                  from pcbrindeexrestricoes
                  where codigo            = pn_numregiao
                    AND tipo              = restricoes.tipo
                    AND validacao         = restricoes.validacao
                    AND NVL(gruporegra,0) = restricoes.gruporegra 
                    AND codbrex           = campanhas.codbrex;
  
                IF vn_count = 0 THEN
                  msg := 'Campanha não permitida para a região ' || TO_CHAR(pn_numregiao);
                  --EXIT loop_principal;
                  add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
                END IF;
  
            --Exclusividade para classes de clientes -> "CL"
              WHEN 'CL' THEN
                SELECT COUNT(*)
                  INTO vn_count
                  FROM pcbrindeexrestricoes
                 where codigoa            = vs_classevenda
                    AND tipo              = restricoes.tipo
                    AND validacao         = restricoes.validacao
                    AND NVL(gruporegra,0) = restricoes.gruporegra 
                    AND codbrex           = campanhas.codbrex;
  
                IF vn_count = 0 THEN
                  msg := 'Campanha não permitida para a classe ' || TO_CHAR(vs_classevenda);
                  add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
                END IF;
  
            --Exclusividade para praças -> "P"
              WHEN 'P' THEN
                SELECT COUNT(*)
                  INTO vn_count
                  FROM pcbrindeexrestricoes
                 where codigo             = vn_codpraca
                    AND tipo              = restricoes.tipo
                    AND validacao         = restricoes.validacao
                    AND NVL(gruporegra,0) = restricoes.gruporegra 
                    AND codbrex           = campanhas.codbrex;
  
                IF vn_count = 0 THEN
                  msg := 'Campanha não permitida para a praça ' || TO_CHAR(vn_codpraca);
                  add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
                END IF;
  
            --Exclusividade para redes de clientes -> "RC"
              WHEN 'RC' THEN
                SELECT COUNT(*)
                  INTO vn_count
                  FROM pcbrindeexrestricoes
                 where codigo             = vn_codrede
                    AND tipo              = restricoes.tipo
                    AND validacao         = restricoes.validacao
                    AND NVL(gruporegra,0) = restricoes.gruporegra 
                    AND codbrex           = campanhas.codbrex;
  
                IF vn_count = 0 THEN
                  msg := 'Campanha não permitida para a rede de clientes ' || TO_CHAR(vn_codrede);
                  add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
                END IF;
  
            --Exclusividade para cliente -> "C"
              WHEN 'C' THEN
                SELECT COUNT(*)
                  INTO vn_count
                  FROM pcbrindeexrestricoes
                 where codigo             = vn_codcli
                    AND tipo              = restricoes.tipo
                    AND validacao         = restricoes.validacao
                    AND NVL(gruporegra,0) = restricoes.gruporegra 
                    AND codbrex           = campanhas.codbrex;
  
                IF vn_count = 0 THEN
                  msg := 'Campanha não permitida para o cliente ' || TO_CHAR(vn_codcli);
                  add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
                END IF;
  
            --Exclusividade para cliente principal -> "CP"
              WHEN 'CP' THEN
                SELECT COUNT(*)
                  INTO vn_count
                  FROM pcbrindeexrestricoes
                 where codigo            = vn_codcliprinc
                   AND tipo              = restricoes.tipo
                   AND validacao         = restricoes.validacao
                   AND NVL(gruporegra,0) = restricoes.gruporegra 
                   AND codbrex           = campanhas.codbrex;
  
                IF vn_count = 0 THEN
                  msg := 'Campanha não permitida para o cliente principal ' || TO_CHAR(vn_codcliprinc);
                  add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
                END IF;
  
            --Exclusividade para Filial -> "F"
              WHEN 'F' THEN
                SELECT COUNT(*)
                  INTO vn_count
                  FROM pcbrindeexrestricoes
                 where codigoa          IN (ps_codfilial)
                   AND tipo              = restricoes.tipo
                   AND validacao         = restricoes.validacao
                   AND NVL(gruporegra,0) = restricoes.gruporegra 
                   AND codbrex           = campanhas.codbrex;
  
                IF vn_count = 0 THEN
                  msg := 'Campanha não permitida para a filial ' || TO_CHAR(ps_codfilial);
                  add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
                END IF;
  
            --Exclusividade para Ramo de Atividade -> "RA"
              WHEN 'RA' THEN
                SELECT COUNT(*)
                  INTO vn_count
                  FROM pcbrindeexrestricoes
                 where codigo            = vn_codatv1
                   AND tipo              = restricoes.tipo
                   AND validacao         = restricoes.validacao
                   AND NVL(gruporegra,0) = restricoes.gruporegra 
                   AND codbrex           = campanhas.codbrex;
  
                IF vn_count = 0 THEN
                  msg := 'Campanha não permitida para o ramo de atividade ' || TO_CHAR(vn_codatv1);
                  add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
                END IF;
  
            --Exclusividade para Plano de Pgto -> "PL"
              WHEN 'PL' THEN
                SELECT COUNT(*)
                  INTO vn_count
                  FROM pcbrindeexrestricoes
                 where codigo IN (pn_codplpag)
                   AND tipo              = restricoes.tipo
                   AND validacao         = restricoes.validacao
                   AND NVL(gruporegra,0) = restricoes.gruporegra 
                   AND codbrex           = campanhas.codbrex;
  
                IF vn_count = 0 THEN
                  msg := 'Campanha não permitida para o plano de pagamento ' || TO_CHAR(pn_codplpag);
                  add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
                END IF;
  
            --Exclusividade para Supervisor -> "SP"
              WHEN 'SP' THEN
                SELECT COUNT(*)
                  INTO vn_count
                  FROM pcbrindeexrestricoes
                 where codigo IN (select u.codsupervisor
                                    from pcusuari u
                                     where u.codusur = pn_codusur)
                   AND tipo              = restricoes.tipo
                   AND validacao         = restricoes.validacao
                   AND NVL(gruporegra,0) = restricoes.gruporegra 
                   AND codbrex           = campanhas.codbrex;
  
                IF vn_count = 0 THEN
                  SELECT CODSUPERVISOR
                    INTO vn_codsupervisor
                    FROM PCUSUARI
                   WHERE CODUSUR = VN_CODRCA;
  
                  msg := 'Campanha não permitida para o plano de pagamento ' || TO_CHAR(vn_codsupervisor);
                  add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
                END IF;
  
            --Exclusividade para RCA -> "RX"
              WHEN 'RX' THEN
                SELECT COUNT(*)
                  INTO vn_count
                  FROM pcbrindeexrestricoes
                 where codigo IN (pn_codusur)
                   AND tipo              = restricoes.tipo
                   AND validacao         = restricoes.validacao
                   AND NVL(gruporegra,0) = restricoes.gruporegra 
                   AND codbrex           = campanhas.codbrex;
  
                IF vn_count = 0 THEN
                  msg := 'Campanha não permitida para o RCA ' || TO_CHAR(pn_codusur);
                  add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
                END IF;
  
            --Exclusividade inválida
              WHEN NULL THEN
                msg := 'Campanha código ' || TO_CHAR(campanhas.codbrex) ||
                       ', com exclusividade inválida!';
                add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
              ELSE
                msg := 'Campanha código ' || TO_CHAR(campanhas.codbrex) ||
                       ', com exclusividade inválida!';
                add_GrupoRegraNaoAtender(CAMPANHAS.CODBREX, RESTRICOES.GRUPOREGRA, msg);
  
            END CASE;
          --Fim 1.2.3.2
  
          END IF;
  
          FETCH C_Restricoes INTO restricoes;
  
        END LOOP;
  
        IF C_Restricoes%ISOPEN THEN
          CLOSE C_Restricoes;
        END IF;
        --Fim 1.2.3
        
      END LOOP; -- FIM: Loop de Todas as Regras do Brinde

      -- Grupos de Regra com Restrição
      vsListaGrupoRegraNaoAtender := NULL;
      IF (vtRelGrupoRegraNaoAtender.COUNT > 0) THEN
        FOR viIdx IN vtRelGrupoRegraNaoAtender.FIRST..vtRelGrupoRegraNaoAtender.LAST LOOP
          IF vsListaGrupoRegraNaoAtender IS NULL THEN
            vsListaGrupoRegraNaoAtender := TO_CHAR(vtRelGrupoRegraNaoAtender(viIdx).vnCodGrupo);
          ELSE
            vsListaGrupoRegraNaoAtender := vsListaGrupoRegraNaoAtender || ',' || TO_CHAR(vtRelGrupoRegraNaoAtender(viIdx).vnCodGrupo);
          END IF;
          msg := vtRelGrupoRegraNaoAtender(viIdx).vvCritica;       
        END LOOP; 
      END IF; 
      
      IF vsListaGrupoRegraNaoAtender IS NULL
       THEN
         vsListaGrupoRegraNaoAtender := '-1';
      END IF;

      --1.2.4 - Validar Regras
      OPEN C_Regras(campanhas.codbrex, vsListaGrupoRegraNaoAtender);
      FETCH C_Regras
        INTO regras;
      /*
      O cursor "C_Regras" serve para buscar as qtdes de regras que cada
      grupo de regras da campanha tem.
      Para cada "C_Regras"(grupo de regras) serão verificadas todas as
      validações(PCBRINDEEXVALIDACOES) existentes para este mais as regras
      do grupo zero "0".
      */
      --IF campanhas.acumulativa = 'S' THEN

      vn_qtacumuladavenda := NVL(campanhas.qtacumuladavenda, 1);

      IF vn_qtacumuladavenda = 0 THEN
        vn_qtacumuladavenda := 1;
      END IF;

      --END IF;

      <<loop_Validacao>>
      WHILE C_Regras%FOUND LOOP
        --1.2.4.1 - Compondo tabela de apuração dos resultados das validações.

        OPEN C_Validacoes(campanhas.codbrex, regras.gruporegra);
        FETCH C_Validacoes
          INTO validacoes;
        IF nvl(validacoes.vlmax, 0) = 0 THEN
          validacoes.vlmax := 999999999999;
        END IF;
        --Fim 1.2.4.1
        <<loop_regra>>
        WHILE C_Validacoes%FOUND LOOP
          vn_count := 0;
          --vn_qtloops := nvl(vt_tabelaapuracao.LAST,0) + 1;
          --1.2.5 - Validar regra corrente (PCBRINDEEXVALIDACOES)
          CASE validacoes.tipo
            --1.2.5.1 - Configuração de validação incorreta(tipo nulo)
            WHEN NULL THEN
              msg := 'Campanha código ' || TO_CHAR(campanhas.codbrex) ||
                     ' possui uma ou mais regras de validação inválidas!';
              --Fim 1.2.5.1

            --1.2.5.2 - Validar tipo "PE" - Peso Total
            WHEN 'PE' THEN

              IF campanhas.acumulativa <> 'S'
              THEN

                SELECT COUNT(*)
                  INTO vn_count
                  FROM (SELECT SUM(p.qt * pr.pesoliq) valor
                          FROM pcpedi p, pcprodut pr
                         WHERE pr.codprod = p.codprod
                           AND p.numped = pn_numped
                           AND NVL(P.BONIFIC, 'N') = 'N'
                           AND nvl(p.brinde, 'N') <> 'S'
                           AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                           ) itensped

                 WHERE valor BETWEEN NVL(validacoes.vlmin*vn_qtacumuladavenda, 0) AND NVL(validacoes.vlmax, 999999999999);


              ELSE
                -- 1166.015770.2018 - Ajustado para melhorar a performance do select
                DECLARE
                  vnPEDTV5qtbrindescontemplados number;
                  vnDEVTV5qtbrindesdevolvidos   number;
                BEGIN
                  SELECT --COUNT(*) qtbrindescontemplados
                        NVL(SUM(I.QT),0) qtbrindescontemplados
                   INTO vnPEDTV5qtbrindescontemplados
                     FROM pcpedi i, pcpedc c
                    WHERE i.numped = c.numped
                      AND NVL(i.brinde,'N') = 'S'
                      AND i.codigobrinde = campanhas.codbrex
                      AND c.numped > G_NUMPED_GZERO
                      AND c.posicao <> 'C'
                      AND c.dtcancel IS NULL
                      AND c.codcli = G_CODCLI
                      --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                      --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                      AND i.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim
                      AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                           ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(i.perdesc, 0) = 0)));

                  SELECT --COUNT(*) qtbrindesdevolvidos
                        NVL(SUM(m.QT),0) qtbrindesdevolvidos
                   INTO vnDEVTV5qtbrindesdevolvidos
                     FROM pcmov m
                    WHERE (m.numped, m.codprod) IN (SELECT c.numped, i.codprod
                                                      FROM pcpedc c, pcpedi i
                                                     WHERE i.numped = c.numped
                                                       AND NVL(i.brinde,'N') = 'S'
                                                       AND i.codigobrinde = campanhas.codbrex
                                                       AND i.codprod = m.codprod
                                                       AND c.codcli = G_CODCLI
                                                       AND c.posicao <> 'C'
                                                       AND c.dtcancel IS NULL
                                                       AND c.numped > G_NUMPED_GZERO
                                                       AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                      --AND m.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND m.codcli = G_CODCLI
                      AND m.dtcancel IS NULL
                      AND m.codoper = 'ED';

                    vn_qtbrindescontemplados := vnPEDTV5qtbrindescontemplados - vnDEVTV5qtbrindesdevolvidos;
                END;

                /*SELECT (PEDTV5.qtbrindescontemplados - DEVTV5.qtbrindesdevolvidos)
                  INTO vn_qtbrindescontemplados
                  FROM
                  (SELECT --COUNT(*) qtbrindescontemplados
                          NVL(SUM(I.QT),0) qtbrindescontemplados
                     FROM pcpedi i, pcpedc c
                    WHERE i.numped = c.numped
                      AND NVL(i.brinde,'N') = 'S'
                      AND i.codigobrinde = campanhas.codbrex
                      AND c.numped > G_NUMPED_GZERO
                      AND c.posicao <> 'C'
                      AND c.dtcancel IS NULL
                      AND c.codcli = G_CODCLI
                      --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                      --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                      --AND i.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND i.codprod IN (SELECT NUMEROS FROM TABLE(CODPRODPREMIO(campanhas.codbrex, validacoes.gruporegra, pn_numpedtv5)))
                      AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim) PEDTV5,
                  (SELECT --COUNT(*) qtbrindesdevolvidos
                          NVL(SUM(m.QT),0) qtbrindesdevolvidos
                     FROM pcmov m
                    WHERE (m.numped, m.codprod) IN (SELECT c.numped, i.codprod
                                                      FROM pcpedc c, pcpedi i
                                                     WHERE i.numped = c.numped
                                                       AND NVL(i.brinde,'N') = 'S'
                                                       AND i.codigobrinde = campanhas.codbrex
                                                       AND i.codprod = m.codprod
                                                       AND c.codcli = G_CODCLI
                                                       AND c.posicao <> 'C'
                                                       AND c.dtcancel IS NULL
                                                       AND c.numped > G_NUMPED_GZERO
                                                       AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                      --AND m.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND m.codcli = G_CODCLI
                      AND m.dtcancel IS NULL
                      AND m.codoper = 'ED') DEVTV5;*/

                vn_count := 0; --REAPROVEITANDO VARIÁVEL
                SELECT SUM(QT)
                  INTO vn_count --REAPROVEITANDO VARIÁVEL
                  FROM PCBRINDEEXPREMIO
                 WHERE CODBREX = CAMPANHAS.CODBREX
                   AND GRUPOREGRA = VALIDACOES.GRUPOREGRA;

                IF NVL(vn_count,0) > 0 THEN
                  vn_qtbrindescontemplados := TRUNC(vn_qtbrindescontemplados / vn_count);
                END IF;

                BEGIN
                  SELECT decode(qtmaxmultiplo, 0, 999999999999, MAX(qtmaxmultiplo))
                    INTO vn_maxmultiplo
                    FROM pcbrindeexpremio
                   WHERE codbrex = campanhas.codbrex
                     AND gruporegra = validacoes.gruporegra
                GROUP BY qtmaxmultiplo;
                EXCEPTION
                  WHEN OTHERS THEN
                    vn_maxmultiplo := 999999999999;
                END;

                IF (vn_qtbrindescontemplados < vn_maxmultiplo)
                AND (vn_maxmultiplo > 0)
                THEN
                  SELECT COUNT(*)
                    INTO vn_count
                    FROM (SELECT (venda.valor - decode(NVL(campanhas.abaterdev,'N'),
                                                       'N',
                                                       0,
                                                       NVL(dev.valor,0))) valor
                            FROM (SELECT SUM(p.qt * pr.pesoliq) valor
                                    FROM pcpedi p, pcprodut pr
                                   WHERE pr.codprod = p.codprod
                                     AND p.numped IN (SELECT numped
                                                        FROM pcpedc
                                                       WHERE codcli = G_CODCLI
                                                         AND posicao <> 'C'
                                                         AND dtcancel IS NULL
                                                         AND numped > G_NUMPED_GZERO
                                                         --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                         --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                         AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                                     AND NVL(P.BONIFIC, 'N') = 'N'
                                     AND nvl(p.brinde, 'N') <> 'S'
                                     AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                          ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))) venda,
                                 (SELECT SUM(m.qtcont * m.pesoliq) valor
                                    FROM pcmov m
                                   WHERE m.numped IN (SELECT c.numped
                                                        FROM pcpedc c, pcpedi i
                                                       WHERE i.numped = c.numped
                                                         AND nvl(i.brinde,'N') <> 'S'
                                                         AND NVL(I.BONIFIC, 'N') = 'N'
                                                         AND c.codcli = G_CODCLI
                                                         AND c.posicao <> 'C'
                                                         AND c.dtcancel IS NULL
                                                         AND c.numped > G_NUMPED_GZERO
                                                         --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                         --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                         AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                                     AND m.dtcancel IS NULL
                                     AND m.codoper = 'ED') dev) itensped,
                         (SELECT SUM(b.vlmin) valor
                            FROM pcbrindeexvalidacoes b
                           WHERE b.codbrex = campanhas.codbrex
                             AND b.tipo = validacoes.tipo
                             AND b.gruporegra = validacoes.gruporegra) itensregras
                   WHERE decode(vn_qtbrindescontemplados,
                                0,
                                itensped.valor,
                                (itensped.valor - (itensregras.valor * vn_qtbrindescontemplados)))
                         --BETWEEN NVL(validacoes.vlmin, 0) AND NVL(validacoes.vlmax, 999999999999); Tarefa: 213115
                         -->= NVL(validacoes.vlmin, 0);
                         >= CASE
                              WHEN vn_qtbrindescontemplados > 0 THEN
                                NVL(validacoes.vlmin, 0)
                              ELSE
                                (NVL(validacoes.vlmin, 0) * vn_qtacumuladavenda)
                            END;
                ELSE
                  vn_count := 0;
                END IF;

              END IF;

              IF vn_count > 0 THEN

                IF campanhas.acumulativa <> 'S'
                THEN

                  SELECT SUM(p.qt * pr.pesoliq) valor
                    INTO vn_basemultiplo
                    FROM pcpedi p, pcprodut pr
                   WHERE pr.codprod = p.codprod
                     AND nvl(p.brinde, 'N') <> 'S'
                     AND nvl(p.bonific, 'N') = 'N'
                     AND p.numped = pn_numped
                     AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                          ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)));

                ELSE
                  IF (vn_qtbrindescontemplados < vn_maxmultiplo)
                  AND (vn_maxmultiplo > 0)
                  THEN
                    /*
                    SELECT SUM(p.qt * pr.pesoliq) valor
                      INTO vn_basemultiplo
                      FROM pcpedi p, pcprodut pr
                     WHERE pr.codprod = p.codprod
                       AND nvl(p.brinde, 'N') <> 'S'
                       AND p.numped IN (SELECT numped
                                          FROM pcpedc
                                         WHERE codcli = G_CODCLI
                                           AND posicao <> 'C'
                                           AND dtcancel IS NULL
                                           AND numped > G_NUMPED_GZERO
                                           --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                           --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                           AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim);*/

                    SELECT (venda.valor - decode(NVL(campanhas.abaterdev,'N'),
                                                 'N',
                                                 0,
                                                 NVL(dev.valor,0))) valor
                      INTO vn_basemultiplo
                      FROM (SELECT SUM(p.qt * pr.pesoliq) valor
                              FROM pcpedi p, pcprodut pr
                             WHERE pr.codprod = p.codprod
                               AND p.numped IN (SELECT numped
                                                  FROM pcpedc
                                                 WHERE codcli = G_CODCLI
                                                   AND posicao <> 'C'
                                                   AND dtcancel IS NULL
                                                   AND numped > G_NUMPED_GZERO
                                                   --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                   --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                   AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                               AND nvl(p.bonific, 'N') = 'N'
                               AND nvl(p.brinde, 'N') <> 'S'
                               AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                    ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                               ) venda,
                           (SELECT SUM(m.qtcont * m.pesoliq) valor
                              FROM pcmov m
                             WHERE m.numped IN (SELECT c.numped
                                                  FROM pcpedc c, pcpedi i
                                                 WHERE i.numped = c.numped
                                                   AND nvl(i.brinde,'N') <> 'S'
                                                   AND NVL(I.BONIFIC, 'N') = 'N'
                                                   AND c.codcli = G_CODCLI
                                                   AND c.posicao <> 'C'
                                                   AND c.dtcancel IS NULL
                                                   AND c.numped > G_NUMPED_GZERO
                                                   --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                   --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                   AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                               AND m.dtcancel IS NULL
                               AND m.codoper = 'ED') dev;

                  END IF;

                END IF;

                IF vn_qtloops >= 1 THEN
                  IF NOT vt_tabelaapuracao.EXISTS(vn_qtloops + 1) AND
                     (vt_tabelaapuracao(vt_tabelaapuracao.LAST).codcamp IS NOT NULL) THEN
                    vn_qtloops := vt_tabelaapuracao.LAST + 1;
                    vt_tabelaapuracao.EXTEND;
                  END IF;
                ELSE
                  vn_qtloops := vn_qtloops + 1;
                  vt_tabelaapuracao.EXTEND;
                END IF;

                vr_tabelaapuracao.codcamp := campanhas.codbrex;
                vr_tabelaapuracao.gruporegra := validacoes.gruporegra;
                vr_tabelaapuracao.ok := 'S';
                vr_tabelaapuracao.numregra := C_Validacoes%ROWCOUNT;
/*                vr_tabelaapuracao.multiplo := trunc(vn_basemultiplo /
                                                                GREATEST(nvl(validacoes.vlmin,
                                                                    1)),1);*/

                vr_tabelaapuracao.multiplo := trunc(vn_basemultiplo /
                                                                    (CASE WHEN nvl(validacoes.vlmin,1) = 0 THEN
                                                                      1
                                                                    ELSE
                                                                      nvl(validacoes.vlmin,1)
                                                                    END));



                vt_tabelaapuracao(vn_qtloops) := vr_tabelaapuracao;

              ELSIF (validacoes.gruporegra = 0) AND (pn_numped > 0)  THEN
                EXIT loop_Validacao;

              END IF;
              --Fim 1.2.5.2

            --1.2.5.3 - Validar tipo "QT" - Qtde Total
            WHEN 'QT' THEN

              IF campanhas.acumulativa <> 'S'
              THEN

                SELECT COUNT(*)
                  INTO vn_count
                  FROM (SELECT SUM(p.qt) valor
                          FROM pcpedi p
                         WHERE p.numped = pn_numped
                           AND nvl(p.bonific, 'N') = 'N'
                           AND nvl(p.brinde, 'N') <> 'S'
                           AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                           ) itensped
                 WHERE valor BETWEEN NVL(validacoes.vlmin*vn_qtacumuladavenda, 0) AND NVL(validacoes.vlmax, 999999999999);
              ELSE

                -- 1166.015770.2018 - Ajustado para melhorar a performance do select
                DECLARE
                  vnPEDTV5qtbrindescontemplados number;
                  vnDEVTV5qtbrindesdevolvidos   number;
                BEGIN
                  SELECT --COUNT(*) qtbrindescontemplados
                        NVL(SUM(I.QT),0) qtbrindescontemplados
                   INTO vnPEDTV5qtbrindescontemplados
                     FROM pcpedi i, pcpedc c
                    WHERE i.numped = c.numped
                      AND NVL(i.brinde,'N') = 'S'
                      AND i.codigobrinde = campanhas.codbrex
                      AND c.numped > G_NUMPED_GZERO
                      AND c.posicao <> 'C'
                      AND c.dtcancel IS NULL
                      AND c.codcli = G_CODCLI
                      --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                      --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                      AND i.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim
                      AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                           ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(i.perdesc, 0) = 0)));

                  SELECT --COUNT(*) qtbrindesdevolvidos
                        NVL(SUM(m.QT),0) qtbrindesdevolvidos
                   INTO vnDEVTV5qtbrindesdevolvidos
                     FROM pcmov m
                    WHERE (m.numped, m.codprod) IN (SELECT c.numped, i.codprod
                                                      FROM pcpedc c, pcpedi i
                                                     WHERE i.numped = c.numped
                                                       AND NVL(i.brinde,'N') = 'S'
                                                       AND i.codigobrinde = campanhas.codbrex
                                                       AND i.codprod = m.codprod
                                                       AND c.codcli = G_CODCLI
                                                       AND c.posicao <> 'C'
                                                       AND c.dtcancel IS NULL
                                                       AND c.numped > G_NUMPED_GZERO
                                                       AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                      --AND m.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND m.codcli = G_CODCLI
                      AND m.dtcancel IS NULL
                      AND m.codoper = 'ED';

                    vn_qtbrindescontemplados := vnPEDTV5qtbrindescontemplados - vnDEVTV5qtbrindesdevolvidos;
                END;

                /*SELECT (PEDTV5.qtbrindescontemplados - DEVTV5.qtbrindesdevolvidos)
                  INTO vn_qtbrindescontemplados
                  FROM
                  (SELECT --COUNT(*) qtbrindescontemplados
                          NVL(SUM(I.QT),0) qtbrindescontemplados
                     FROM pcpedi i, pcpedc c
                    WHERE i.numped = c.numped
                      AND NVL(i.brinde,'N') = 'S'
                      AND i.codigobrinde = campanhas.codbrex
                      AND c.numped > G_NUMPED_GZERO
                      AND c.posicao <> 'C'
                      AND c.dtcancel IS NULL
                      AND c.codcli = G_CODCLI
                      --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                      --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                      --AND i.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND i.codprod IN (SELECT NUMEROS FROM TABLE(CODPRODPREMIO(campanhas.codbrex, validacoes.gruporegra, pn_numpedtv5)))
                      AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim) PEDTV5,
                  (SELECT --COUNT(*) qtbrindesdevolvidos
                          NVL(SUM(m.QT),0) qtbrindesdevolvidos
                     FROM pcmov m
                    WHERE (m.numped, m.codprod) IN (SELECT c.numped, i.codprod
                                                      FROM pcpedc c, pcpedi i
                                                     WHERE i.numped = c.numped
                                                       AND NVL(i.brinde,'N') = 'S'
                                                       AND i.codigobrinde = campanhas.codbrex
                                                       AND i.codprod = m.codprod
                                                       AND c.codcli = G_CODCLI
                                                       AND c.posicao <> 'C'
                                                       AND c.dtcancel IS NULL
                                                       AND c.numped > G_NUMPED_GZERO
                                                       AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                      --AND m.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND m.codcli = G_CODCLI
                      AND m.dtcancel IS NULL
                      AND m.codoper = 'ED') DEVTV5;  */
                BEGIN

                  SELECT decode(qtmaxmultiplo, 0, 999999999999, MAX(qtmaxmultiplo))
                    INTO vn_maxmultiplo
                    FROM pcbrindeexpremio
                   WHERE codbrex = campanhas.codbrex
                     AND gruporegra = validacoes.gruporegra
                GROUP BY qtmaxmultiplo;

                EXCEPTION
                  WHEN OTHERS THEN
                    vn_maxmultiplo := 999999999999;
                END;

                IF (vn_qtbrindescontemplados < vn_maxmultiplo)
                AND (vn_maxmultiplo > 0)
                THEN
                  SELECT COUNT(*)
                    INTO vn_count
                    FROM (SELECT (venda.valor - decode(NVL(campanhas.abaterdev,'N'),
                                                       'N',
                                                       0,
                                                       NVL(dev.valor,0))) valor
                            FROM (SELECT SUM(p.qt * decode(campanhas.usaalienacao, 'S',
                                                                                   pr.fator,
                                                                                   1)) valor
                                    FROM pcpedi p, VW_ALIENACAO_FORNEC pr
                                   WHERE pr.codprod = p.codprod
                                     AND p.numped IN (SELECT numped
                                                        FROM pcpedc
                                                       WHERE codcli = G_CODCLI
                                                         AND posicao <> 'C'
                                                         AND dtcancel IS NULL
                                                         AND numped > G_NUMPED_GZERO
                                                         --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                         --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                         AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                                     AND NVL(p.bonific, 'N') = 'N'
                                     AND nvl(p.brinde, 'N') <> 'S'
                                     AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                          ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                                     ) venda,
                                 (SELECT SUM(m.qtcont * decode(campanhas.usaalienacao, 'S',
                                                                                       pr.fator,
                                                                                       1)) valor
                                    FROM pcmov m, VW_ALIENACAO_FORNEC pr
                                   WHERE m.codprod = pr.codprod
                                     AND m.numped IN (SELECT c.numped
                                                        FROM pcpedc c, pcpedi i
                                                       WHERE i.numped = c.numped
                                                         AND nvl(i.brinde,'N') <> 'S'
                                                         AND nvl(i.bonific, 'N') = 'N'
                                                         AND c.codcli = G_CODCLI
                                                         AND c.posicao <> 'C'
                                                         AND c.dtcancel IS NULL
                                                         AND c.numped > G_NUMPED_GZERO
                                                         --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                         --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                         AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                                     AND m.dtcancel IS NULL
                                     AND m.codoper = 'ED') dev) itensped,
                         (SELECT SUM(b.vlmin) valor
                            FROM pcbrindeexvalidacoes b
                           WHERE b.codbrex = campanhas.codbrex
                             AND b.tipo = validacoes.tipo
                             AND b.gruporegra = validacoes.gruporegra) itensregras
                   WHERE decode(vn_qtbrindescontemplados,
                                0,
                                itensped.valor,
                                (itensped.valor - (itensregras.valor * vn_qtbrindescontemplados)))
                         --BETWEEN NVL(validacoes.vlmin, 0) AND NVL(validacoes.vlmax, 999999999999); Tarefa: 213115
                         -->= NVL(validacoes.vlmin, 0);
                         >= CASE
                              WHEN vn_qtbrindescontemplados > 0 THEN
                                NVL(validacoes.vlmin, 0)
                              ELSE
                                (NVL(validacoes.vlmin, 0) * vn_qtacumuladavenda)
                            END;
                ELSE
                  vn_count := 0;
                END IF;

              END IF;

              IF vn_count > 0 THEN

                IF campanhas.acumulativa <> 'S'
                THEN

                  SELECT SUM(p.qt) valor
                    INTO vn_basemultiplo
                    FROM pcpedi p, pcprodut pr
                   WHERE pr.codprod = p.codprod
                     AND nvl(p.brinde, 'N') <> 'S'
                     and nvl(p.bonific, 'N') = 'N'
                     AND p.numped = pn_numped
                     AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                          ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)));
                ELSE
                  IF (vn_qtbrindescontemplados < vn_maxmultiplo)
                  AND (vn_maxmultiplo > 0)
                  THEN
                    /*
                    SELECT SUM(p.qt * decode(campanhas.usaalienacao, 'S',
                                                                     pr.fator,
                                                                     1)) valor
                      INTO vn_basemultiplo
                      FROM pcpedi p, VW_ALIENACAO_FORNEC pr
                     WHERE pr.codprod = p.codprod
                       AND nvl(p.brinde, 'N') <> 'S'
                       AND p.numped IN (SELECT numped
                                          FROM pcpedc
                                         WHERE codcli = G_CODCLI
                                           AND posicao <> 'C'
                                           AND dtcancel IS NULL
                                           AND numped > G_NUMPED_GZERO
                                           --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                           --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                           AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim);*/

                    SELECT (venda.valor - decode(NVL(campanhas.abaterdev,'N'),
                                                 'N',
                                                 0,
                                                 NVL(dev.valor,0))) valor
                      INTO vn_basemultiplo
                      FROM (SELECT SUM(p.qt * decode(campanhas.usaalienacao, 'S',
                                                                             pr.fator,
                                                                             1)) valor
                              FROM pcpedi p, VW_ALIENACAO_FORNEC pr
                             WHERE pr.codprod = p.codprod
                               AND p.numped IN (SELECT numped
                                                  FROM pcpedc
                                                 WHERE codcli = G_CODCLI
                                                   AND posicao <> 'C'
                                                   AND dtcancel IS NULL
                                                   AND numped > G_NUMPED_GZERO
                                                   --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                   --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                   AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                               AND nvl(p.bonific, 'N') = 'N'
                               AND nvl(p.brinde, 'N') <> 'S'
                               AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                    ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                               ) venda,
                           (SELECT SUM(m.qtcont * decode(campanhas.usaalienacao, 'S',
                                                                                 pr.fator,
                                                                                 1)) valor
                              FROM pcmov m, VW_ALIENACAO_FORNEC pr
                             WHERE m.codprod = pr.codprod
                               AND m.numped IN (SELECT c.numped
                                                  FROM pcpedc c, pcpedi i
                                                 WHERE i.numped = c.numped
                                                   AND nvl(i.brinde,'N') <> 'S'
                                                   AND nvl(i.bonific, 'N') = 'N'
                                                   AND c.codcli = G_CODCLI
                                                   AND c.posicao <> 'C'
                                                   AND c.dtcancel IS NULL
                                                   AND c.numped > G_NUMPED_GZERO
                                                   --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                   --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                   AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                               AND m.dtcancel IS NULL
                               AND m.codoper = 'ED') dev;
                  END IF;

                END IF;

                IF vn_qtloops >= 1 THEN
                  IF NOT vt_tabelaapuracao.EXISTS(vn_qtloops + 1) AND
                     (vt_tabelaapuracao(vt_tabelaapuracao.LAST).codcamp IS NOT NULL) THEN
                    vn_qtloops := vt_tabelaapuracao.LAST + 1;
                    vt_tabelaapuracao.EXTEND;
                  END IF;
                ELSE
                  vn_qtloops := vn_qtloops + 1;
                  vt_tabelaapuracao.EXTEND;
                END IF;

                vr_tabelaapuracao.codcamp := campanhas.codbrex;
                vr_tabelaapuracao.gruporegra := validacoes.gruporegra;
                vr_tabelaapuracao.ok := 'S';
                vr_tabelaapuracao.numregra := C_Validacoes%ROWCOUNT;
/*                vr_tabelaapuracao.multiplo := trunc(vn_basemultiplo /
                                                                GREATEST(nvl(validacoes.vlmin,
                                                                    1)),1);*/

                vr_tabelaapuracao.multiplo := trunc(vn_basemultiplo /
                                                                    (CASE WHEN nvl(validacoes.vlmin,1) = 0 THEN
                                                                      1
                                                                    ELSE
                                                                      nvl(validacoes.vlmin,1)
                                                                    END));


                vt_tabelaapuracao(vn_qtloops) := vr_tabelaapuracao;

              ELSIF (validacoes.gruporegra = 0) AND (pn_numped > 0)  THEN
                EXIT loop_Validacao;

              END IF;
              --Fim 1.2.5.3

            --1.2.5.4 - Validar tipo "VL" - Valor Total
            WHEN 'VL' THEN

              IF campanhas.acumulativa <> 'S'
              THEN

                SELECT COUNT(*)
                  INTO vn_count
                  FROM (SELECT SUM(p.qt * p.pvenda) valor
                          FROM pcpedi p
                         WHERE p.numped = pn_numped
                           AND nvl(p.BONIFIC, 'N') = 'N'
                           AND nvl(p.brinde, 'N') <> 'S'
                           AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                           ) itensped
                 WHERE valor BETWEEN NVL(validacoes.vlmin*vn_qtacumuladavenda, 0) AND NVL(validacoes.vlmax, 999999999999);
              ELSE

                -- 1166.015770.2018 - Ajustado para melhorar a performance do select
                DECLARE
                  vnPEDTV5qtbrindescontemplados number;
                  vnDEVTV5qtbrindesdevolvidos   number;
                BEGIN
                  SELECT --COUNT(*) qtbrindescontemplados
                        NVL(SUM(I.QT),0) qtbrindescontemplados
                   INTO vnPEDTV5qtbrindescontemplados
                     FROM pcpedi i, pcpedc c
                    WHERE i.numped = c.numped
                      AND NVL(i.brinde,'N') = 'S'
                      AND i.codigobrinde = campanhas.codbrex
                      AND c.numped > G_NUMPED_GZERO
                      AND c.posicao <> 'C'
                      AND c.dtcancel IS NULL
                      AND c.codcli = G_CODCLI
                      --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                      --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                      AND i.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim
                      AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                           ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(i.perdesc, 0) = 0)));

                  SELECT --COUNT(*) qtbrindesdevolvidos
                        NVL(SUM(m.QT),0) qtbrindesdevolvidos
                   INTO vnDEVTV5qtbrindesdevolvidos
                     FROM pcmov m
                    WHERE (m.numped, m.codprod) IN (SELECT c.numped, i.codprod
                                                      FROM pcpedc c, pcpedi i
                                                     WHERE i.numped = c.numped
                                                       AND NVL(i.brinde,'N') = 'S'
                                                       AND i.codigobrinde = campanhas.codbrex
                                                       AND i.codprod = m.codprod
                                                       AND c.codcli = G_CODCLI
                                                       AND c.posicao <> 'C'
                                                       AND c.dtcancel IS NULL
                                                       AND c.numped > G_NUMPED_GZERO
                                                       AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                      --AND m.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND m.dtcancel IS NULL
                      AND m.codoper = 'ED';

                    vn_qtbrindescontemplados := vnPEDTV5qtbrindescontemplados - vnDEVTV5qtbrindesdevolvidos;
                END;

                /*SELECT (PEDTV5.qtbrindescontemplados - DEVTV5.qtbrindesdevolvidos)
                  INTO vn_qtbrindescontemplados
                  FROM
                  (SELECT --COUNT(*) qtbrindescontemplados
                          NVL(SUM(I.QT),0) qtbrindescontemplados
                     FROM pcpedi i, pcpedc c
                    WHERE i.numped = c.numped
                      AND NVL(i.brinde,'N') = 'S'
                      AND i.codigobrinde = campanhas.codbrex
                      AND c.numped > G_NUMPED_GZERO
                      AND c.posicao <> 'C'
                      AND c.dtcancel IS NULL
                      AND c.codcli = G_CODCLI
                      --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                      --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                      --AND i.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND i.codprod IN (SELECT NUMEROS FROM TABLE(CODPRODPREMIO(campanhas.codbrex, validacoes.gruporegra, pn_numpedtv5)))
                      AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim) PEDTV5,
                  (SELECT --COUNT(*) qtbrindesdevolvidos
                          NVL(SUM(m.QT),0) qtbrindesdevolvidos
                     FROM pcmov m
                    WHERE (m.numped, m.codprod) IN (SELECT c.numped, i.codprod
                                                      FROM pcpedc c, pcpedi i
                                                     WHERE i.numped = c.numped
                                                       AND NVL(i.brinde,'N') = 'S'
                                                       AND i.codigobrinde = campanhas.codbrex
                                                       AND i.codprod = m.codprod
                                                       AND c.codcli = G_CODCLI
                                                       AND c.posicao <> 'C'
                                                       AND c.dtcancel IS NULL
                                                       AND c.numped > G_NUMPED_GZERO
                                                       AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                      --AND m.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND m.dtcancel IS NULL
                      AND m.codoper = 'ED') DEVTV5;*/

                vn_count := 0; --REAPROVEITANDO VARIÁVEL
                SELECT SUM(QT)
                  INTO vn_count --REAPROVEITANDO VARIÁVEL
                  FROM PCBRINDEEXPREMIO
                 WHERE CODBREX = CAMPANHAS.CODBREX
                   AND GRUPOREGRA = VALIDACOES.GRUPOREGRA;

                IF NVL(vn_count,0) > 0 THEN
                  vn_qtbrindescontemplados := TRUNC(vn_qtbrindescontemplados / vn_count);
                END IF;

                BEGIN
                  SELECT decode(qtmaxmultiplo, 0, 999999999999, MAX(qtmaxmultiplo))
                    INTO vn_maxmultiplo
                    FROM pcbrindeexpremio
                   WHERE codbrex = campanhas.codbrex
                     AND gruporegra = validacoes.gruporegra
                GROUP BY qtmaxmultiplo;
                EXCEPTION
                  WHEN OTHERS THEN
                    vn_maxmultiplo := 999999999999;
                END;

                IF (vn_qtbrindescontemplados < vn_maxmultiplo)
                AND (vn_maxmultiplo > 0)
                THEN
                  SELECT COUNT(*)
                    INTO vn_count
                    FROM (SELECT (venda.valor - decode(NVL(campanhas.abaterdev,'N'),
                                                       'N',
                                                       0,
                                                       NVL(dev.valor,0))) valor
                            FROM (SELECT SUM(p.qt * p.pvenda) valor
                                    FROM pcpedi p
                                   WHERE p.numped IN (SELECT numped
                                                        FROM pcpedc
                                                       WHERE codcli = G_CODCLI
                                                         AND posicao <> 'C'
                                                         AND dtcancel IS NULL
                                                         AND numped > G_NUMPED_GZERO
                                                         --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                         --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                         AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                                     AND nvl(p.bonific, 'N') = 'N'
                                     AND nvl(p.brinde, 'N') <> 'S'
                                     AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                          ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                                     ) venda,
                                 (SELECT SUM(m.qtcont * m.punitcont) valor
                                    FROM pcmov m
                                   WHERE m.numped IN (SELECT c.numped
                                                        FROM pcpedc c, pcpedi i
                                                       WHERE i.numped = c.numped
                                                         AND nvl(i.bonific, 'N') = 'N'
                                                         AND nvl(i.brinde,'N') <> 'S'
                                                         AND c.codcli = G_CODCLI
                                                         AND c.posicao <> 'C'
                                                         AND c.dtcancel IS NULL
                                                         AND c.numped > G_NUMPED_GZERO
                                                         --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                         --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                         AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                                     AND m.dtcancel IS NULL
                                     AND m.codoper = 'ED') dev) itensped,
                         (SELECT SUM(b.vlmin) valor
                            FROM pcbrindeexvalidacoes b
                           WHERE b.codbrex = campanhas.codbrex
                             AND b.tipo = validacoes.tipo
                             AND b.gruporegra = validacoes.gruporegra) itensregras
                   WHERE decode(vn_qtbrindescontemplados,
                                0,
                                itensped.valor,
                                (itensped.valor - (itensregras.valor * vn_qtbrindescontemplados)))
                         --BETWEEN NVL(validacoes.vlmin, 0) AND NVL(validacoes.vlmax, 999999999999); Tarefa: 213115
                         -->= NVL(validacoes.vlmin, 0);
                         >= CASE
                              WHEN vn_qtbrindescontemplados > 0 THEN
                                NVL(validacoes.vlmin, 0)
                              ELSE
                                (NVL(validacoes.vlmin, 0) * vn_qtacumuladavenda)
                            END;
                ELSE
                  vn_count := 0;
                END IF;

              END IF;

              IF vn_count > 0 THEN

                IF campanhas.acumulativa <> 'S'
                THEN

                  SELECT SUM(p.qt * p.pvenda) valor
                    INTO vn_basemultiplo
                    FROM pcpedi p, pcprodut pr
                   WHERE pr.codprod = p.codprod
                     AND nvl(p.bonific, 'N') = 'N'
                     AND nvl(p.brinde, 'N') <> 'S'
                     AND p.numped = pn_numped
                     AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                          ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)));
                ELSE
                  IF (vn_qtbrindescontemplados < vn_maxmultiplo)
                  AND (vn_maxmultiplo > 0)
                  THEN
                    /*
                    SELECT SUM(p.qt * p.pvenda) valor
                      INTO vn_basemultiplo
                      FROM pcpedi p, pcprodut pr
                     WHERE pr.codprod = p.codprod
                       AND nvl(p.brinde, 'N') <> 'S'
                       AND p.numped IN (SELECT numped
                                          FROM pcpedc
                                         WHERE codcli = G_CODCLI
                                           AND posicao <> 'C'
                                           AND dtcancel IS NULL
                                           AND numped > G_NUMPED_GZERO
                                           --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                           --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                           AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim);*/

                    SELECT (venda.valor - decode(NVL(campanhas.abaterdev,'N'),
                                                 'N',
                                                 0,
                                                 NVL(dev.valor,0))) valor
                      INTO vn_basemultiplo
                      FROM (SELECT SUM(p.qt * p.pvenda) valor
                              FROM pcpedi p
                             WHERE p.numped IN (SELECT numped
                                                  FROM pcpedc
                                                 WHERE codcli = G_CODCLI
                                                   AND posicao <> 'C'
                                                   AND dtcancel IS NULL
                                                   AND numped > G_NUMPED_GZERO
                                                   --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                   --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                   AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                               AND nvl(p.bonific, 'N') = 'N'
                               AND nvl(p.brinde, 'N') <> 'S'
                               AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                    ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                               ) venda,
                           (SELECT SUM(m.qtcont * m.punitcont) valor
                              FROM pcmov m
                             WHERE m.numped IN (SELECT c.numped
                                                  FROM pcpedc c, pcpedi i
                                                 WHERE i.numped = c.numped
                                                   AND nvl(i.bonific, 'N') = 'N'
                                                   AND nvl(i.brinde,'N') <> 'S'
                                                   AND c.codcli = G_CODCLI
                                                   AND c.posicao <> 'C'
                                                   AND c.dtcancel IS NULL
                                                   AND c.numped > G_NUMPED_GZERO
                                                   --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                   --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                   AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                               AND m.dtcancel IS NULL
                               AND m.codoper = 'ED') dev;
                  END IF;

                END IF;

                IF vn_qtloops >= 1 THEN
                  IF NOT vt_tabelaapuracao.EXISTS(vn_qtloops + 1) AND
                     (vt_tabelaapuracao(vt_tabelaapuracao.LAST).codcamp IS NOT NULL) THEN
                    vn_qtloops := vt_tabelaapuracao.LAST + 1;
                    vt_tabelaapuracao.EXTEND;
                  END IF;
                ELSE
                  vn_qtloops := vn_qtloops + 1;
                  vt_tabelaapuracao.EXTEND;
                END IF;

                vr_tabelaapuracao.codcamp := campanhas.codbrex;
                vr_tabelaapuracao.gruporegra := validacoes.gruporegra;
                vr_tabelaapuracao.ok := 'S';
                vr_tabelaapuracao.numregra := C_Validacoes%ROWCOUNT;
/*                vr_tabelaapuracao.multiplo := trunc(vn_basemultiplo /
                                                                GREATEST(nvl(validacoes.vlmin,
                                                                    1)),1);*/

                vr_tabelaapuracao.multiplo := trunc(vn_basemultiplo /
                                                                    (CASE WHEN nvl(validacoes.vlmin,1) = 0 THEN
                                                                      1
                                                                    ELSE
                                                                      nvl(validacoes.vlmin,1)
                                                                    END));


                vt_tabelaapuracao(vn_qtloops) := vr_tabelaapuracao;

              ELSIF (validacoes.gruporegra = 0) AND (pn_numped > 0)  THEN
                EXIT loop_Validacao;

              END IF;
              --Fim 1.2.5.4

          --1.2.5.5 - Validar tipo "P" - Produto
            WHEN 'P' THEN

              IF campanhas.acumulativa <> 'S'
              THEN
                 IF (ferramentas.F_BUSCARPARAMETRO_ALFA('FIL_UTILIZAVENDAPOREMBALAGEM',VALIDACOES.CODFILIALEMB,'N') = 'S') then
                      if (pn_codprod > 0) and (pn_numped = 0) then
                        SELECT COUNT(*)
                        INTO vn_count
                        FROM (SELECT pr.codprod
                                FROM pcprodut pr
                               WHERE pr.codprod = pn_codprod
                               GROUP BY pr.codprod) itensped
                        WHERE codprod = validacoes.codigo;
                      else
                        SELECT COUNT(1)
                        INTO vn_count
                        FROM (SELECT p.codprod,
                                     decode(validacoes.tipovalor,
                                            'VL',
                                              DECODE (validacoes.precosemimposto,
                                              'S',
                                              SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                              SUM(p.qt * p.pvenda)
                                              ),
                                            'QT',
                                            CASE ferramentas.F_BUSCARPARAMETRO_ALFA('FIL_UTILIZAVENDAPOREMBALAGEM',VALIDACOES.CODFILIALEMB,'N')
                                              WHEN 'N' THEN SUM(p.qt)
                                              ELSE SUM(p.qt/DECODE (NVl(validacoes.codauxiliar,0),0,1, nvl((select qtunit
                                                                                                              from pcembalagem
                                                                                                             where codauxiliar = validacoes.codauxiliar and
                                                                                                                       codprod = e.codprod and
                                                                                                                     codfilial = e.codfilial and
                                                                                                                        rownum = 1), 1)))
                                            END,
                                            'PE',
                                            SUM(p.qt * pr.pesoliq),
                                            'MX',
                                            COUNT(DISTINCT p.codprod)) valor,
                                     p.Codfilialretira,
                                     NVL(p.CODAUXILIAR, 0) CODAUXILIAR
                                FROM pcpedi p, PCEMBALAGEM E, PCPRODUT PR /*INNER JOIN pcprodut pr
                                                      ON pr.codprod = p.codprod
                                               LEFT JOIN pcembalagem e
                                                      ON e.codprod     = p.codprod
                                                     AND e.codfilial   = p.codfilialretira
                                                     AND e.codauxiliar   = VALIDACOES.CODAUXILIAR    */
                               WHERE nvl(p.bonific, 'N') = 'N'
                                 AND nvl(p.brinde, 'N') <> 'S'
                                 AND p.numped = pn_numped
                                 AND P.CODPROD = PR.CODPROD
                                 AND P.CODPROD(+) = E.CODPROD
                                 AND P.CODFILIALRETIRA(+) = E.CODFILIAL
                                 AND E.CODAUXILIAR = p.CODAUXILIAR
                               GROUP BY p.codprod,
                                        p.Codfilialretira,
                                        p.CODAUXILIAR) itensped
                       WHERE codprod = validacoes.codigo
                         AND valor BETWEEN
                             NVL(validacoes.vlmin * vn_qtacumuladavenda, 0) AND
                             NVL(validacoes.vlmax, 999999999999);
                    END IF;
                  else
                      if pn_codprod > 0 then
                        SELECT COUNT(*)
                        INTO vn_count
                        FROM (SELECT pr.codprod
                                FROM pcprodut pr
                               WHERE pr.codprod = pn_codprod
                               GROUP BY pr.codprod) itensped
                        WHERE codprod = validacoes.codigo;
                      else
                        SELECT COUNT(*)
                        INTO vn_count
                        FROM (SELECT p.codprod,
                                     decode(validacoes.tipovalor,
                                            'VL',
                                              DECODE (validacoes.precosemimposto,
                                              'S',
                                              SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                              SUM(p.qt * p.pvenda)
                                              ),
                                            'QT',
                                            SUM(p.qt),
                                            'PE',
                                            SUM(p.qt * pr.pesoliq),
                                            'MX',
                                            COUNT(DISTINCT p.codprod)) valor
                                FROM pcpedi p, pcprodut pr
                               WHERE pr.codprod = p.codprod
                                 AND nvl(p.brinde, 'N') <> 'S'
                                 AND p.numped = pn_numped
                                 AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                      ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                               GROUP BY p.codprod) itensped
                        WHERE codprod = validacoes.codigo
                          AND valor BETWEEN NVL(validacoes.vlmin*vn_qtacumuladavenda, 0) AND NVL(validacoes.vlmax, 999999999999);
                      end if;
                   end if;

              ELSE

                DECLARE
                  vnPEDTV5qtbrindescontemplados number;
                  vnDEVTV5qtbrindesdevolvidos   number;
                BEGIN
                  SELECT --COUNT(*) qtbrindescontemplados
                        NVL(SUM(I.QT),0) qtbrindescontemplados
                   INTO vnPEDTV5qtbrindescontemplados
                     FROM pcpedi i, pcpedc c
                    WHERE i.numped = c.numped
                      AND NVL(i.brinde,'N') = 'S'
                      AND i.codigobrinde = campanhas.codbrex
                      AND c.numped > G_NUMPED_GZERO
                      AND c.posicao <> 'C'
                      AND c.dtcancel IS NULL
                      AND c.codcli = G_CODCLI
                      --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                      --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                      AND i.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim
                      AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                           ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(i.perdesc, 0) = 0)));

                  SELECT --COUNT(*) qtbrindesdevolvidos
                        NVL(SUM(m.QT),0) qtbrindesdevolvidos
                   INTO vnDEVTV5qtbrindesdevolvidos
                     FROM pcmov m
                    WHERE (m.numped, m.codprod) IN (SELECT c.numped, i.codprod
                                                      FROM pcpedc c, pcpedi i
                                                     WHERE i.numped = c.numped
                                                       AND NVL(i.brinde,'N') = 'S'
                                                       AND i.codigobrinde = campanhas.codbrex
                                                       AND i.codprod = m.codprod
                                                       AND c.codcli = G_CODCLI
                                                       AND c.posicao <> 'C'
                                                       AND c.dtcancel IS NULL
                                                       AND c.numped > G_NUMPED_GZERO
                                                       AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                      --AND m.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND m.dtcancel IS NULL
                      AND m.codoper = 'ED';

                    vn_qtbrindescontemplados := vnPEDTV5qtbrindescontemplados - vnDEVTV5qtbrindesdevolvidos;
                END;

               /* SELECT (PEDTV5.qtbrindescontemplados - DEVTV5.qtbrindesdevolvidos)
                  INTO vn_qtbrindescontemplados
                  FROM
                  (SELECT --COUNT(*) qtbrindescontemplados
                          NVL(SUM(I.QT),0) qtbrindescontemplados
                     FROM pcpedi i, pcpedc c
                    WHERE i.numped = c.numped
                      AND NVL(i.brinde,'N') = 'S'
                      AND i.codigobrinde = campanhas.codbrex
                      AND c.numped > G_NUMPED_GZERO
                      AND c.posicao <> 'C'
                      AND c.dtcancel IS NULL
                      AND c.codcli = G_CODCLI
                      --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                      --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                      --AND i.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND i.codprod IN (SELECT NUMEROS FROM TABLE(CODPRODPREMIO(campanhas.codbrex, validacoes.gruporegra, pn_numpedtv5)))
                      AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim) PEDTV5,
                  (SELECT --COUNT(*) qtbrindesdevolvidos
                          NVL(SUM(m.QT),0) qtbrindesdevolvidos
                     FROM pcmov m
                    WHERE (m.numped, m.codprod) IN (SELECT c.numped, i.codprod
                                                      FROM pcpedc c, pcpedi i
                                                     WHERE i.numped = c.numped
                                                       AND NVL(i.brinde,'N') = 'S'
                                                       AND i.codigobrinde = campanhas.codbrex
                                                       AND i.codprod = m.codprod
                                                       AND c.codcli = G_CODCLI
                                                       AND c.posicao <> 'C'
                                                       AND c.dtcancel IS NULL
                                                       AND c.numped > G_NUMPED_GZERO
                                                       AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                      --AND m.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND m.dtcancel IS NULL
                      AND m.codoper = 'ED') DEVTV5;*/

                vn_count := 0; --REAPROVEITANDO VARIÁVEL
                SELECT SUM(QT)
                  INTO vn_count --REAPROVEITANDO VARIÁVEL
                  FROM PCBRINDEEXPREMIO
                 WHERE CODBREX = CAMPANHAS.CODBREX
                   AND GRUPOREGRA = VALIDACOES.GRUPOREGRA;

                IF NVL(vn_count,0) > 0 THEN
                  vn_qtbrindescontemplados := TRUNC(vn_qtbrindescontemplados / vn_count);
                END IF;

                BEGIN
                  SELECT decode(qtmaxmultiplo, 0, 999999999999, MAX(qtmaxmultiplo))
                    INTO vn_maxmultiplo
                    FROM pcbrindeexpremio
                   WHERE codbrex = campanhas.codbrex
                     AND gruporegra = validacoes.gruporegra
                GROUP BY qtmaxmultiplo;
                EXCEPTION
                  WHEN OTHERS THEN
                    vn_maxmultiplo := 999999999999;
                END;

                IF (vn_qtbrindescontemplados < vn_maxmultiplo)
                AND (vn_maxmultiplo > 0)
                THEN
                  vn_count := 0;

                  SELECT COUNT(*)
                    INTO vn_count
                    FROM (SELECT venda.codprod,venda.CODFILIALRETIRA,
                                 venda.codauxiliar,
                                 (venda.valor - decode(NVL(campanhas.abaterdev,'N'),
                                                       'N',
                                                       0,
                                                       NVL(dev.valor,0))) valor
                            FROM (SELECT p.codprod,
                                         decode(validacoes.tipovalor,
                                                'VL',
                                                  DECODE (validacoes.precosemimposto,
                                                  'S',
                                                  SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                                  SUM(p.qt * p.pvenda)
                                                  ),
                                                'QT',
                                                SUM(p.qt * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                                'PE',
                                                SUM(p.qt * pr.pesoliq),
                                                'MX',
                                                COUNT(DISTINCT p.codprod)) valor,
                                         NVL(p.CODAUXILIAR, 0) CODAUXILIAR,
                                         p.CODFILIALRETIRA
                                    FROM pcpedi p, VW_ALIENACAO_FORNEC pr
                                   WHERE pr.codprod = p.codprod
                                     AND nvl(p.brinde, 'N') <> 'S'
                                     AND nvl(p.bonific, 'N') = 'N'
                                     AND p.numped IN (SELECT numped
                                                        FROM pcpedc
                                                       WHERE codcli = G_CODCLI
                                                         AND posicao <> 'C'
                                                         AND dtcancel IS NULL
                                                         AND numped > G_NUMPED_GZERO
                                                         --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                         --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                         AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                                     AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                          ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                                   GROUP BY p.codprod,NVL(p.CODAUXILIAR, 0) ,p.CODFILIALRETIRA ) venda,
                                 (SELECT m.codprod,
                                         decode(validacoes.tipovalor,
                                                'VL',
                                                  DECODE (validacoes.precosemimposto,
                                                  'S',
                                                  SUM(m.qtcont * (m.punitcont - nvl(m.st,0) - nvl(m.vlipi,0))),
                                                  SUM(m.qtcont * m.punitcont)
                                                  ),
                                                'QT',
                                                CASE campanhas.usaalienacao
                                                  WHEN 'S' then SUM(m.qtcont*pr.fator)
                                                  ELSE CASE ferramentas.F_BUSCARPARAMETRO_ALFA('FIL_UTILIZAVENDAPOREMBALAGEM',VALIDACOES.CODFILIALEMB,'N')
                                                         WHEN 'N' THEN SUM(m.qt)
                                                         ELSE SUM(m.qt/nvl(e.qtunit, 1))
                                                       END
                                                END,
                                                'PE',
                                                SUM(m.qt * m.pesoliq),
                                                'MX',
                                                COUNT(DISTINCT m.codprod)) valor,
                                                NVL(M.CODAUXILIAR, 0) CODAUXILIAR,
                                                m.CODFILIALRETIRA
                                    FROM pcmov m INNER JOIN VW_ALIENACAO_FORNEC pr
                                                         ON pr.codprod = m.codprod
                                                  LEFT JOIN pcembalagem e
                                                         ON e.codprod     = m.codprod
                                                        AND e.codfilial   = m.codfilialretira
                                                        AND e.codauxiliar = VALIDACOES.CODAUXILIAR
                                   WHERE m.numped IN (SELECT c.numped
                                                        FROM pcpedc c, pcpedi i
                                                       WHERE i.numped = c.numped
                                                         AND nvl(i.bonific, 'N') = 'N'
                                                         AND nvl(i.brinde,'N') <> 'S'
                                                         AND c.codcli = G_CODCLI
                                                         AND c.posicao <> 'C'
                                                         AND c.dtcancel IS NULL
                                                         AND c.numped > G_NUMPED_GZERO
                                                         --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                         --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                         AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                                     AND m.dtcancel IS NULL
                                     AND m.codoper = 'ED'
                                  GROUP BY m.codprod,NVL(m.CODAUXILIAR, 0) , m.CODFILIALRETIRA ) dev
                          WHERE venda.codprod = dev.codprod(+)) itensped,
                          (SELECT b.codigo,
                                  SUM(b.vlmin) valor
                             FROM pcbrindeexvalidacoes b
                            WHERE b.codbrex = campanhas.codbrex
                              AND b.tipo = validacoes.tipo
                              AND b.gruporegra = validacoes.gruporegra
                           GROUP BY b.codigo) itensregras
                   WHERE itensped.codprod = validacoes.codigo
                     AND itensped.codprod = itensregras.codigo
                     AND itensped.CODFILIALRETIRA = case
                           when NVL(VALIDACOES.CODFILIALEMB,'0') <> '0' then
                            VALIDACOES.CODFILIALEMB
                           else
                            itensped.CODFILIALRETIRA
                         end
                     AND itensped.CODAUXILIAR = case
                           when NVL(VALIDACOES.CODAUXILIAR,0) <> 0 then
                            VALIDACOES.CODAUXILIAR
                           else
                            itensped.CODAUXILIAR
                         end
                     AND decode(vn_qtbrindescontemplados,
                                0,
                                itensped.valor,
                                (itensped.valor - (itensregras.valor * vn_qtbrindescontemplados)))
                         --BETWEEN NVL(validacoes.vlmin, 0) AND NVL(validacoes.vlmax, 999999999999); Tarefa: 213115
                         -->= NVL(validacoes.vlmin, 0);
                         >= CASE
                              WHEN vn_qtbrindescontemplados > 0 THEN
                                NVL(validacoes.vlmin, 0)
                              ELSE
                                (NVL(validacoes.vlmin, 0) * vn_qtacumuladavenda)
                            END;
                ELSE
                  vn_count := 0;
                END IF;

              END IF;

              IF vn_count > 0 THEN

                IF campanhas.acumulativa <> 'S'
                THEN
                  IF (ferramentas.F_BUSCARPARAMETRO_ALFA('FIL_UTILIZAVENDAPOREMBALAGEM',VALIDACOES.CODFILIALEMB,'N') = 'S') then
                    SELECT decode(validacoes.tipovalor,
                                  'VL',
                                    DECODE (validacoes.precosemimposto,
                                    'S',
                                    SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                    SUM(p.qt * p.pvenda)
                                    ),
                                  'QT',
                                  CASE ferramentas.F_BUSCARPARAMETRO_ALFA('FIL_UTILIZAVENDAPOREMBALAGEM',VALIDACOES.CODFILIALEMB,'N')
                                    WHEN 'N' THEN SUM(p.qt)
                                    ELSE NVL(SUM(p.qt / nvl((select QTUNIT from PCEMBALAGEM where CODFILIAL=p.codfilialretira and CODAUXILIAR=VALIDACOES.CODAUXILIAR), p.codauxiliar)),1)
                                  END,
                                  'PE',
                                  SUM(p.qt * pr.pesoliq),
                                  'MX',
                                  COUNT(DISTINCT p.codprod)) valor
                      INTO vn_basemultiplo
                      FROM pcpedi p ,PCEMBALAGEM E, PCPRODUT PR /*INNER JOIN pcprodut pr
                                            ON pr.codprod = p.codprod
                                     LEFT JOIN pcembalagem e
                                            ON e.codprod     = p.codprod
                                           AND e.codfilial   = p.codfilialretira
                                           AND e.codauxiliar   = VALIDACOES.CODAUXILIAR*/
                     WHERE nvl(p.brinde, 'N') <> 'S'
                       AND nvl(p.bonific, 'N') = 'N'
                       AND p.numped = pn_numped
                       AND p.codprod = validacoes.codigo
                       AND P.CODPROD = PR.CODPROD
                       AND P.CODPROD(+) = E.CODPROD
                       AND P.CODFILIALRETIRA(+) = E.CODFILIAL
                       AND E.CODAUXILIAR = DECODE(p.CODAUXILIAR,0 , e.codauxiliar, p.CODAUXILIAR)
                       AND p.CODFILIALRETIRA = case
                             when NVL(VALIDACOES.CODFILIALEMB,'0') <> '0' then
                              VALIDACOES.CODFILIALEMB
                             else
                              p.CODFILIALRETIRA
                           end
                       AND p.CODAUXILIAR = case
                             when NVL(p.CODAUXILIAR,0) <> 0 then
                              p.CODAUXILIAR
                             else
                              VALIDACOES.CODAUXILIAR
                           end
                       AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                            ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)));
                   ELSE
                       SELECT decode(validacoes.tipovalor,
                                    'VL',
                                      DECODE (validacoes.precosemimposto,
                                      'S',
                                      SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                      SUM(p.qt * p.pvenda)
                                      ),
                                    'QT',
                                    SUM(p.qt),
                                    'PE',
                                    SUM(p.qt * pr.pesoliq),
                                    'MX',
                                    COUNT(DISTINCT p.codprod)) valor
                        INTO vn_basemultiplo
                        FROM pcpedi p, pcprodut pr
                       WHERE pr.codprod = p.codprod
                         AND nvl(p.brinde, 'N') <> 'S'
                         AND p.numped = pn_numped
                         AND p.codprod = validacoes.codigo
                         AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                              ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)));
                   end if;
                ELSE

                  IF (vn_qtbrindescontemplados < vn_maxmultiplo)
                  AND (vn_maxmultiplo > 0)
                  THEN
                    /*
                    SELECT decode(vn_qtbrindescontemplados,
                                  0,
                                  itensped.valor,
                                  (itensped.valor - (itensregras.valor * vn_qtbrindescontemplados)))
                      INTO vn_basemultiplo
                      FROM (SELECT validacoes.codigo,
                                   decode(validacoes.tipovalor,
                                          'VL',
                                          SUM(p.qt * p.pvenda),
                                          'QT',
                                          SUM(p.qt * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                          'PE',
                                          SUM(p.qt * pr.pesoliq)) valor
                              FROM pcpedi p, VW_ALIENACAO_FORNEC pr
                             WHERE pr.codprod = p.codprod
                               AND nvl(p.brinde, 'N') <> 'S'
                               AND p.numped IN (SELECT numped
                                                  FROM pcpedc
                                                 WHERE codcli = G_CODCLI
                                                   AND posicao <> 'C'
                                                   AND dtcancel IS NULL
                                                   AND numped > G_NUMPED_GZERO
                                                   --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                   --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                   AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                               AND p.codprod = validacoes.codigo) itensped,
                           (SELECT b.codigo,
                                   SUM(b.vlmin) valor
                              FROM pcbrindeexvalidacoes b
                             WHERE codbrex = campanhas.codbrex
                               AND gruporegra = validacoes.gruporegra
                            GROUP BY b.codigo) itensregras
                     WHERE
                     itensped.codigo = itensregras.codigo;*/

                    SELECT SUM(venda.valor - decode(NVL(campanhas.abaterdev,'N'),
                                                 'N',
                                                 0,
                                                 NVL(dev.valor,0))) valor
                      INTO vn_basemultiplo
                      FROM (SELECT p.codprod,
                                   decode(validacoes.tipovalor,
                                          'VL',
                                            DECODE (validacoes.precosemimposto,
                                            'S',
                                            SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                            SUM(p.qt * p.pvenda)
                                            ),
                                          'QT',
                                          CASE campanhas.usaalienacao
                                            WHEN 'S' then SUM(p.qt*pr.fator)
                                            ELSE CASE ferramentas.F_BUSCARPARAMETRO_ALFA('FIL_UTILIZAVENDAPOREMBALAGEM',VALIDACOES.CODFILIALEMB,'N')
                                                   WHEN 'N' THEN SUM(p.qt)
                                                   ELSE SUM(p.qt/nvl(e.qtunit, 1))
                                                 END
                                          END,
                                          'PE',
                                          SUM(p.qt * pr.pesoliq),
                                          'MX',
                                          COUNT(DISTINCT p.codprod)) valor,
                                   NVL(p.CODAUXILIAR, 0) CODAUXILIAR,
                                   p.codfilialretira
                              FROM pcpedi p INNER JOIN VW_ALIENACAO_FORNEC pr
                                                    ON pr.codprod = p.codprod
                                             LEFT JOIN pcembalagem e
                                                    ON e.codprod     = p.codprod
                                                   AND e.codfilial   = p.codfilialretira
                                                   AND e.codauxiliar = VALIDACOES.CODAUXILIAR
                             WHERE nvl(p.brinde, 'N') <> 'S'
                               AND nvl(p.bonific, 'N') = 'N'
                               AND p.numped IN (SELECT numped
                                                  FROM pcpedc
                                                 WHERE codcli = G_CODCLI
                                                   AND posicao <> 'C'
                                                   AND dtcancel IS NULL
                                                   AND numped > G_NUMPED_GZERO
                                                   --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                   --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                   AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                               AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                    ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                             GROUP BY p.codprod,NVL(p.CODAUXILIAR, 0) ,p.codfilialretira) venda,
                           (SELECT m.codprod,
                                   decode(validacoes.tipovalor,
                                          'VL',
                                            DECODE (validacoes.precosemimposto,
                                            'S',
                                            SUM(m.qtcont * (m.punitcont - nvl(m.st,0) - nvl(m.vlipi,0))),
                                            SUM(m.qtcont * m.punitcont)
                                            ),
                                          'QT',
                                          SUM(m.qtcont * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                          'PE',
                                          SUM(m.qt * m.pesoliq),
                                          'MX',
                                          COUNT(DISTINCT m.codprod)) valor,
                                   NVL(m.CODAUXILIAR, 0) CODAUXILIAR,
                                   m.CODFILIALRETIRA
                              FROM pcmov m, VW_ALIENACAO_FORNEC pr
                             WHERE pr.codprod = m.codprod
                               AND m.numped IN (SELECT c.numped
                                                  FROM pcpedc c, pcpedi i
                                                 WHERE i.numped = c.numped
                                                   AND nvl(i.brinde,'N') <> 'S'
                                                   AND nvl(i.bonific, 'N') = 'N'
                                                   AND c.codcli = G_CODCLI
                                                   AND c.posicao <> 'C'
                                                   AND c.dtcancel IS NULL
                                                   AND c.numped > G_NUMPED_GZERO
                                                   --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                   --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                   AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                               AND m.dtcancel IS NULL
                               AND m.codoper = 'ED'
                            GROUP BY m.codprod,NVL(m.CODAUXILIAR, 0) ,m.CODFILIALRETIRA) dev
                    WHERE venda.codprod = dev.codprod(+)
                      AND venda.codprod = validacoes.codigo
                      AND venda.CODFILIALRETIRA = case
                            when NVL(VALIDACOES.CODFILIALEMB,'0') <> '0' then
                             VALIDACOES.CODFILIALEMB
                            else
                             venda.CODFILIALRETIRA
                          end
                      AND venda.CODAUXILIAR = case
                            when NVL(VALIDACOES.CODAUXILIAR,0) <> 0 then
                             VALIDACOES.CODAUXILIAR
                            else
                             venda.CODAUXILIAR
                          end
                      AND venda.CODAUXILIAR = dev.CODAUXILIAR
                      AND venda.CODFILIALRETIRA = dev.CODFILIALRETIRA;

                  END IF;

                END IF;

                IF vn_qtloops >= 1 THEN
                  IF NOT vt_tabelaapuracao.EXISTS(vn_qtloops + 1) AND
                     (vt_tabelaapuracao(vt_tabelaapuracao.LAST).codcamp IS NOT NULL) THEN
                    vn_qtloops := vt_tabelaapuracao.LAST + 1;
                    vt_tabelaapuracao.EXTEND;
                  END IF;
                ELSE
                  vn_qtloops := vn_qtloops + 1;
                  vt_tabelaapuracao.EXTEND;
                END IF;

                vr_tabelaapuracao.codcamp := campanhas.codbrex;
                vr_tabelaapuracao.gruporegra := validacoes.gruporegra;
                vr_tabelaapuracao.ok := 'S';
                vr_tabelaapuracao.numregra := C_Validacoes%ROWCOUNT;
           /*     vr_tabelaapuracao.multiplo := trunc(vn_basemultiplo /
                                                               GREATEST(nvl(validacoes.vlmin,
                                                                    1)),1);*/

                vr_tabelaapuracao.multiplo := trunc(vn_basemultiplo /
                                                                    (CASE WHEN nvl(validacoes.vlmin,1) = 0 THEN
                                                                      1
                                                                    ELSE
                                                                      nvl(validacoes.vlmin,1)
                                                                    END));


                vt_tabelaapuracao(vn_qtloops) := vr_tabelaapuracao;

              ELSIF (validacoes.gruporegra = 0) AND (pn_numped > 0)  THEN
                EXIT loop_Validacao;

              END IF;
              --Fim 1.2.5.5

            --1.2.5.6 - Validar tipo "D" - Departamento
            WHEN 'D' THEN

              IF campanhas.acumulativa <> 'S'
              THEN
                if pn_codprod > 0 then
                  SELECT COUNT(*)
                    INTO vn_count
                    FROM (SELECT pr.codepto
                            FROM pcprodut pr
                           WHERE pr.codprod = pn_codprod
                           GROUP BY pr.codepto) itensped
                   WHERE codepto = validacoes.codigo;
                else
                  SELECT COUNT(*)
                    INTO vn_count
                    FROM (SELECT pr.codepto,
                                 decode(validacoes.tipovalor,
                                        'VL',
                                         DECODE (validacoes.precosemimposto,
                                         'S',
                                         SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                         SUM(p.qt * p.pvenda)
                                         ),
                                        'QT',
                                        SUM(p.qt),
                                        'PE',
                                        SUM(p.qt * pr.pesoliq),
                                        'MX',
                                        COUNT(DISTINCT p.codprod)) valor
                            FROM pcpedi p, pcprodut pr
                           WHERE pr.codprod = p.codprod
                             AND nvl(p.brinde, 'N') <> 'S'
                             AND nvl(p.bonific, 'N') = 'N'
                             AND p.numped = pn_numped
                             AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                  ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                           GROUP BY pr.codepto) itensped
                    WHERE codepto = validacoes.codigo
                      AND valor BETWEEN NVL(validacoes.vlmin*vn_qtacumuladavenda, 0) AND NVL(validacoes.vlmax, 999999999999);
                 end if;
              ELSE

                DECLARE
                  vnPEDTV5qtbrindescontemplados number;
                  vnDEVTV5qtbrindesdevolvidos   number;
                BEGIN
                  SELECT --COUNT(*) qtbrindescontemplados
                        NVL(SUM(I.QT),0) qtbrindescontemplados
                   INTO vnPEDTV5qtbrindescontemplados
                     FROM pcpedi i, pcpedc c
                    WHERE i.numped = c.numped
                      AND NVL(i.brinde,'N') = 'S'
                      AND i.codigobrinde = campanhas.codbrex
                      AND c.numped > G_NUMPED_GZERO
                      AND c.posicao <> 'C'
                      AND c.dtcancel IS NULL
                      AND c.codcli = G_CODCLI
                      --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                      --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                      AND i.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim
                      AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                           ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(i.perdesc, 0) = 0)));

                   SELECT --COUNT(*) qtbrindesdevolvidos
                        NVL(SUM(m.QT),0) qtbrindesdevolvidos
                     INTO vnDEVTV5qtbrindesdevolvidos
                     FROM pcmov m
                    WHERE (m.numped, m.codprod) IN (SELECT c.numped, i.codprod
                                                      FROM pcpedc c, pcpedi i
                                                     WHERE i.numped = c.numped
                                                       AND NVL(i.brinde,'N') = 'S'
                                                       AND i.codigobrinde = campanhas.codbrex
                                                       AND i.codprod = m.codprod
                                                       AND c.codcli = G_CODCLI
                                                       AND c.posicao <> 'C'
                                                       AND c.dtcancel IS NULL
                                                       AND c.numped > G_NUMPED_GZERO
                                                       AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                      --AND m.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND m.dtcancel IS NULL
                      AND m.codoper = 'ED';

                    vn_qtbrindescontemplados := vnPEDTV5qtbrindescontemplados - vnDEVTV5qtbrindesdevolvidos;
                END;

                /*SELECT (PEDTV5.qtbrindescontemplados - DEVTV5.qtbrindesdevolvidos)
                  INTO vn_qtbrindescontemplados
                  FROM
                  (SELECT --COUNT(*) qtbrindescontemplados
                          NVL(SUM(I.QT),0) qtbrindescontemplados
                     FROM pcpedi i, pcpedc c
                    WHERE i.numped = c.numped
                      AND NVL(i.brinde,'N') = 'S'
                      AND i.codigobrinde = campanhas.codbrex
                      AND c.numped > G_NUMPED_GZERO
                      AND c.posicao <> 'C'
                      AND c.dtcancel IS NULL
                      AND c.codcli = G_CODCLI
                      --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                      --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                      --AND i.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND i.codprod IN (SELECT NUMEROS FROM TABLE(CODPRODPREMIO(campanhas.codbrex, validacoes.gruporegra, pn_numpedtv5)))
                      AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim) PEDTV5,
                  (SELECT --COUNT(*) qtbrindesdevolvidos
                          NVL(SUM(m.QT),0) qtbrindesdevolvidos
                     FROM pcmov m
                    WHERE (m.numped, m.codprod) IN (SELECT c.numped, i.codprod
                                                      FROM pcpedc c, pcpedi i
                                                     WHERE i.numped = c.numped
                                                       AND NVL(i.brinde,'N') = 'S'
                                                       AND i.codigobrinde = campanhas.codbrex
                                                       AND i.codprod = m.codprod
                                                       AND c.codcli = G_CODCLI
                                                       AND c.posicao <> 'C'
                                                       AND c.dtcancel IS NULL
                                                       AND c.numped > G_NUMPED_GZERO
                                                       AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                      --AND m.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND m.dtcancel IS NULL
                      AND m.codoper = 'ED') DEVTV5;  */

                vn_count := 0; --REAPROVEITANDO VARIÁVEL
                SELECT SUM(QT)
                  INTO vn_count --REAPROVEITANDO VARIÁVEL
                  FROM PCBRINDEEXPREMIO
                 WHERE CODBREX = CAMPANHAS.CODBREX
                   AND GRUPOREGRA = VALIDACOES.GRUPOREGRA;

                IF NVL(vn_count,0) > 0 THEN
                  vn_qtbrindescontemplados := TRUNC(vn_qtbrindescontemplados / vn_count);
                END IF;

                BEGIN
                  SELECT decode(qtmaxmultiplo, 0, 999999999999, MAX(qtmaxmultiplo))
                    INTO vn_maxmultiplo
                    FROM pcbrindeexpremio
                   WHERE codbrex = campanhas.codbrex
                     AND gruporegra = validacoes.gruporegra
                GROUP BY qtmaxmultiplo;
                EXCEPTION
                  WHEN OTHERS THEN
                    vn_maxmultiplo := 999999999999;
                END;

                IF (vn_qtbrindescontemplados < vn_maxmultiplo)
                AND (vn_maxmultiplo > 0)
                THEN
                  SELECT COUNT(*)
                    INTO vn_count
                    FROM (SELECT venda.codepto,
                                 (venda.valor - decode(NVL(campanhas.abaterdev,'N'),
                                                       'N',
                                                       0,
                                                       NVL(dev.valor,0))) valor
                            FROM (SELECT pr.codepto,
                                         decode(validacoes.tipovalor,
                                                'VL',
                                                 DECODE (validacoes.precosemimposto,
                                                 'S',
                                                 SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                                 SUM(p.qt * p.pvenda)
                                                 ),
                                                'QT',
                                                SUM(p.qt * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                                'PE',
                                                SUM(p.qt * pr.pesoliq),
                                                'MX',
                                                COUNT(DISTINCT p.codprod)) valor
                                    FROM pcpedi p, VW_ALIENACAO_FORNEC pr
                                   WHERE pr.codprod = p.codprod
                                     AND nvl(p.brinde, 'N') <> 'S'
                                     AND nvl(p.bonific, 'N') = 'N'
                                     AND p.numped IN (SELECT numped
                                                        FROM pcpedc
                                                       WHERE codcli = G_CODCLI
                                                         AND posicao <> 'C'
                                                         AND dtcancel IS NULL
                                                         AND numped > G_NUMPED_GZERO
                                                         --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                         --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                         AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                                     AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                          ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                                   GROUP BY pr.codepto) venda,
                                 (SELECT m.codepto,
                                         decode(validacoes.tipovalor,
                                                'VL',
                                                 DECODE (validacoes.precosemimposto,
                                                 'S',
                                                 SUM(m.qtcont * (m.punitcont - nvl(m.st,0) - nvl(m.vlipi,0))),
                                                 SUM(m.qtcont * m.punitcont)
                                                 ),
                                                'QT',
                                                SUM(m.qtcont * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                                'PE',
                                                SUM(m.qt * m.pesoliq),
                                                'MX',
                                                COUNT(DISTINCT m.codprod)) valor
                                    FROM pcmov m, VW_ALIENACAO_FORNEC pr
                                   WHERE pr.codprod = m.codprod
                                     AND m.numped IN (SELECT c.numped
                                                        FROM pcpedc c, pcpedi i
                                                       WHERE i.numped = c.numped
                                                         AND nvl(i.brinde,'N') <> 'S'
                                                         AND nvl(i.bonific, 'N') = 'N'
                                                         AND c.codcli = G_CODCLI
                                                         AND c.posicao <> 'C'
                                                         AND c.dtcancel IS NULL
                                                         AND c.numped > G_NUMPED_GZERO
                                                         --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                         --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                         AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                                     AND m.dtcancel IS NULL
                                     AND m.codoper = 'ED'
                                  GROUP BY m.codepto) dev
                          WHERE venda.codepto = dev.codepto(+)) itensped,
                         (SELECT b.codigo,
                                  SUM(b.vlmin) valor
                             FROM pcbrindeexvalidacoes b
                            WHERE b.codbrex = campanhas.codbrex
                              AND b.tipo = validacoes.tipo
                              AND b.gruporegra = validacoes.gruporegra
                          GROUP BY b.codigo) itensregras
                   WHERE itensped.codepto = validacoes.codigo
                     AND itensped.codepto = itensregras.codigo
                     AND decode(vn_qtbrindescontemplados,
                                0,
                                itensped.valor,
                                (itensped.valor - (itensregras.valor * vn_qtbrindescontemplados)))
                         --BETWEEN NVL(validacoes.vlmin, 0) AND NVL(validacoes.vlmax, 999999999999); Tarefa: 213115
                         -->= NVL(validacoes.vlmin, 0);
                         >= CASE
                              WHEN vn_qtbrindescontemplados > 0 THEN
                                NVL(validacoes.vlmin, 0)
                              ELSE
                                (NVL(validacoes.vlmin, 0) * vn_qtacumuladavenda)
                            END;
                ELSE
                  vn_count := 0;
                END IF;

              END IF;

              IF vn_count > 0 THEN

                IF campanhas.acumulativa <> 'S'
                THEN
                  SELECT decode(validacoes.tipovalor,
                                'VL',
                                 DECODE (validacoes.precosemimposto,
                                 'S',
                                 SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                 SUM(p.qt * p.pvenda)
                                 ),
                                'QT',
                                SUM(p.qt),
                                'PE',
                                SUM(p.qt * pr.pesoliq),
                                'MX',
                                COUNT(DISTINCT p.codprod)) valor
                    INTO vn_basemultiplo
                    FROM pcpedi p, pcprodut pr
                   WHERE pr.codprod = p.codprod
                     AND nvl(p.brinde, 'N') <> 'S'
                     AND nvl(p.bonific, 'N') = 'N'
                     AND p.numped = pn_numped
                     AND pr.codepto = validacoes.codigo
                     AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                          ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)));
                ELSE
                  IF (vn_qtbrindescontemplados < vn_maxmultiplo)
                  AND (vn_maxmultiplo > 0)
                  THEN
                    /*
                    SELECT decode(vn_qtbrindescontemplados,
                                  0,
                                  itensped.valor,
                                  (itensped.valor - (itensregras.valor * vn_qtbrindescontemplados)))
                      INTO vn_basemultiplo
                      FROM (SELECT validacoes.codigo,
                                   decode(validacoes.tipovalor,
                                          'VL',
                                          SUM(p.qt * p.pvenda),
                                          'QT',
                                          SUM(p.qt * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                          'PE',
                                          SUM(p.qt * pr.pesoliq)) valor
                              FROM pcpedi p, VW_ALIENACAO_FORNEC pr
                             WHERE pr.codprod = p.codprod
                               AND nvl(p.brinde, 'N') <> 'S'
                               AND p.numped IN (SELECT numped
                                                  FROM pcpedc
                                                 WHERE codcli = G_CODCLI
                                                   AND posicao <> 'C'
                                                   AND dtcancel IS NULL
                                                   AND numped > G_NUMPED_GZERO
                                                   --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                   --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                   AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                               AND pr.codepto = validacoes.codigo) itensped,
                           (SELECT b.codigo,
                                   SUM(b.vlmin) valor
                              FROM pcbrindeexvalidacoes b
                             WHERE codbrex = campanhas.codbrex
                               AND gruporegra = validacoes.gruporegra
                            GROUP BY b.codigo) itensregras
                     WHERE
                     itensped.codigo = itensregras.codigo;*/

                     SELECT SUM((venda.valor - decode(NVL(campanhas.abaterdev,'N'),
                                                  'N',
                                                  0,
                                                  NVL(dev.valor,0)))) valor
                      INTO vn_basemultiplo
                      FROM (SELECT pr.codepto,
                                   decode(validacoes.tipovalor,
                                          'VL',
                                            DECODE (validacoes.precosemimposto,
                                            'S',
                                            SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                            SUM(p.qt * p.pvenda)
                                            ),
                                          'QT',
                                          SUM(p.qt * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                          'PE',
                                          SUM(p.qt * pr.pesoliq),
                                          'MX',
                                          COUNT(DISTINCT p.codprod)) valor
                              FROM pcpedi p, VW_ALIENACAO_FORNEC pr
                             WHERE pr.codprod = p.codprod
                               AND nvl(p.brinde, 'N') <> 'S'
                               AND nvl(p.bonific, 'N') = 'N'
                               AND p.numped IN (SELECT numped
                                                  FROM pcpedc
                                                 WHERE codcli = G_CODCLI
                                                   AND posicao <> 'C'
                                                   AND dtcancel IS NULL
                                                   AND numped > G_NUMPED_GZERO
                                                   --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                   --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                   AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                               AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                    ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                             GROUP BY pr.codepto) venda,
                           (SELECT m.codepto,
                                   decode(validacoes.tipovalor,
                                          'VL',
                                            DECODE (validacoes.precosemimposto,
                                            'S',
                                            SUM(m.qtcont * (m.punitcont - nvl(m.st,0) - nvl(m.vlipi,0))),
                                            SUM(m.qtcont * m.punitcont)
                                            ),
                                          'QT',
                                          SUM(m.qtcont * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                          'PE',
                                          SUM(m.qt * m.pesoliq),
                                          'MX',
                                          COUNT(DISTINCT m.codprod)) valor
                              FROM pcmov m, VW_ALIENACAO_FORNEC pr
                             WHERE pr.codprod = m.codprod
                               AND m.numped IN (SELECT c.numped
                                                  FROM pcpedc c, pcpedi i
                                                 WHERE i.numped = c.numped
                                                   AND nvl(i.brinde,'N') <> 'S'
                                                   AND nvl(i.bonific, 'N') = 'N'
                                                   AND c.codcli = G_CODCLI
                                                   AND c.posicao <> 'C'
                                                   AND c.dtcancel IS NULL
                                                   AND c.numped > G_NUMPED_GZERO
                                                   --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                   --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                   AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                               AND m.dtcancel IS NULL
                               AND m.codoper = 'ED'
                            GROUP BY m.codepto) dev
                    WHERE venda.codepto = dev.codepto(+);

                  END IF;

                END IF;

                IF vn_qtloops >= 1 THEN
                  IF NOT vt_tabelaapuracao.EXISTS(vn_qtloops + 1) AND
                     (vt_tabelaapuracao(vt_tabelaapuracao.LAST).codcamp IS NOT NULL) THEN
                    vn_qtloops := vt_tabelaapuracao.LAST + 1;
                    vt_tabelaapuracao.EXTEND;
                  END IF;
                ELSE
                  vn_qtloops := vn_qtloops + 1;
                  vt_tabelaapuracao.EXTEND;
                END IF;

                vr_tabelaapuracao.codcamp := campanhas.codbrex;
                vr_tabelaapuracao.gruporegra := validacoes.gruporegra;
                vr_tabelaapuracao.ok := 'S';
                vr_tabelaapuracao.numregra := C_Validacoes%ROWCOUNT;
/*                vr_tabelaapuracao.multiplo := trunc(vn_basemultiplo /
                                                                GREATEST(nvl(validacoes.vlmin,
                                                                    1)),1);*/

                vr_tabelaapuracao.multiplo := trunc(vn_basemultiplo /
                                                                    (CASE WHEN nvl(validacoes.vlmin,1) = 0 THEN
                                                                      1
                                                                    ELSE
                                                                      nvl(validacoes.vlmin,1)
                                                                    END));


                vt_tabelaapuracao(vn_qtloops) := vr_tabelaapuracao;

              ELSIF (validacoes.gruporegra = 0) AND (pn_numped > 0)  THEN
                EXIT loop_Validacao;

              END IF;
              --Fim 1.2.5.6

            --1.2.5.7 - Validar tipo "S" - Seção
            WHEN 'S' THEN

              IF campanhas.acumulativa <> 'S'
              THEN
                if pn_codprod > 0 then
                  SELECT COUNT(*)
                  INTO vn_count
                  FROM (SELECT pr.codsec
                          FROM pcprodut pr
                         WHERE pr.codprod = pn_codprod
                         GROUP BY pr.codsec) itensped
                  WHERE codsec = validacoes.codigo;
                else
                  SELECT COUNT(*)
                    INTO vn_count
                    FROM (SELECT pr.codsec,
                                 decode(validacoes.tipovalor,
                                        'VL',
                                          DECODE (validacoes.precosemimposto,
                                          'S',
                                          SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                          SUM(p.qt * p.pvenda)
                                          ),
                                        'QT',
                                        SUM(p.qt),
                                        'PE',
                                        SUM(p.qt * pr.pesoliq),
                                        'MX',
                                        COUNT(DISTINCT p.codprod)) valor
                            FROM pcpedi p, pcprodut pr
                           WHERE pr.codprod = p.codprod
                             AND nvl(p.brinde, 'N') <> 'S'
                             AND nvl(p.bonific, 'N') = 'N'
                             AND p.numped = pn_numped
                             AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                  ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                           GROUP BY pr.codsec) itensped
                    WHERE codsec = validacoes.codigo
                      AND valor BETWEEN NVL(validacoes.vlmin*vn_qtacumuladavenda, 0) AND NVL(validacoes.vlmax, 999999999999);
                 end if;
              ELSE

                DECLARE
                  vnPEDTV5qtbrindescontemplados number;
                  vnDEVTV5qtbrindesdevolvidos   number;
                BEGIN
                  SELECT --COUNT(*) qtbrindescontemplados
                        NVL(SUM(I.QT),0) qtbrindescontemplados
                   INTO vnPEDTV5qtbrindescontemplados
                     FROM pcpedi i, pcpedc c
                    WHERE i.numped = c.numped
                      AND NVL(i.brinde,'N') = 'S'
                      AND i.codigobrinde = campanhas.codbrex
                      AND c.numped > G_NUMPED_GZERO
                      AND c.posicao <> 'C'
                      AND c.dtcancel IS NULL
                      AND c.codcli = G_CODCLI
                      --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                      --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                      AND i.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim
                      AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                           ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(i.perdesc, 0) = 0)));

                   SELECT --COUNT(*) qtbrindesdevolvidos
                        NVL(SUM(m.QT),0) qtbrindesdevolvidos
                     INTO vnDEVTV5qtbrindesdevolvidos
                     FROM pcmov m
                    WHERE (m.numped, m.codprod) IN (SELECT c.numped, i.codprod
                                                      FROM pcpedc c, pcpedi i
                                                     WHERE i.numped = c.numped
                                                       AND NVL(i.brinde,'N') = 'S'
                                                       AND i.codigobrinde = campanhas.codbrex
                                                       AND i.codprod = m.codprod
                                                       AND c.codcli = G_CODCLI
                                                       AND c.posicao <> 'C'
                                                       AND c.dtcancel IS NULL
                                                       AND c.numped > G_NUMPED_GZERO
                                                       AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim
                                                       AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                                            ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(i.perdesc, 0) = 0))))
                      --AND m.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND m.dtcancel IS NULL
                      AND m.codoper = 'ED';

                    vn_qtbrindescontemplados := vnPEDTV5qtbrindescontemplados - vnDEVTV5qtbrindesdevolvidos;
                END;

                /*SELECT (PEDTV5.qtbrindescontemplados - DEVTV5.qtbrindesdevolvidos)
                  INTO vn_qtbrindescontemplados
                  FROM
                  (SELECT --COUNT(*) qtbrindescontemplados
                          NVL(SUM(I.QT),0) qtbrindescontemplados
                     FROM pcpedi i, pcpedc c
                    WHERE i.numped = c.numped
                      AND NVL(i.brinde,'N') = 'S'
                      AND i.codigobrinde = campanhas.codbrex
                      AND c.numped > G_NUMPED_GZERO
                      AND c.posicao <> 'C'
                      AND c.dtcancel IS NULL
                      AND c.codcli = G_CODCLI
                      --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                      --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                      --AND i.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND i.codprod IN (SELECT NUMEROS FROM TABLE(CODPRODPREMIO(campanhas.codbrex, validacoes.gruporegra, pn_numpedtv5)))
                      AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim) PEDTV5,
                  (SELECT --COUNT(*) qtbrindesdevolvidos
                          NVL(SUM(m.QT),0) qtbrindesdevolvidos
                     FROM pcmov m
                    WHERE (m.numped, m.codprod) IN (SELECT c.numped, i.codprod
                                                      FROM pcpedc c, pcpedi i
                                                     WHERE i.numped = c.numped
                                                       AND NVL(i.brinde,'N') = 'S'
                                                       AND i.codigobrinde = campanhas.codbrex
                                                       AND i.codprod = m.codprod
                                                       AND c.codcli = G_CODCLI
                                                       AND c.posicao <> 'C'
                                                       AND c.dtcancel IS NULL
                                                       AND c.numped > G_NUMPED_GZERO
                                                       AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                      --AND m.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND m.dtcancel IS NULL
                      AND m.codoper = 'ED') DEVTV5;  */

                vn_count := 0; --REAPROVEITANDO VARIÁVEL
                SELECT SUM(QT)
                  INTO vn_count --REAPROVEITANDO VARIÁVEL
                  FROM PCBRINDEEXPREMIO
                 WHERE CODBREX = CAMPANHAS.CODBREX
                   AND GRUPOREGRA = VALIDACOES.GRUPOREGRA;

                IF NVL(vn_count,0) > 0 THEN
                  vn_qtbrindescontemplados := TRUNC(vn_qtbrindescontemplados / vn_count);
                END IF;

                BEGIN
                  SELECT decode(qtmaxmultiplo, 0, 999999999999, MAX(qtmaxmultiplo))
                    INTO vn_maxmultiplo
                    FROM pcbrindeexpremio
                   WHERE codbrex = campanhas.codbrex
                     AND gruporegra = validacoes.gruporegra
                GROUP BY qtmaxmultiplo;
                EXCEPTION
                  WHEN OTHERS THEN
                    vn_maxmultiplo := 999999999999;
                END;

                IF (vn_qtbrindescontemplados < vn_maxmultiplo)
                AND (vn_maxmultiplo > 0)
                THEN
                  SELECT COUNT(*)
                    INTO vn_count
                    FROM (SELECT venda.codsec,
                                 (venda.valor - decode(NVL(campanhas.abaterdev,'N'),
                                                       'N',
                                                       0,
                                                       NVL(dev.valor,0))) valor
                            FROM (SELECT pr.codsec,
                                         decode(validacoes.tipovalor,
                                                'VL',
                                                  DECODE (validacoes.precosemimposto,
                                                  'S',
                                                  SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                                  SUM(p.qt * p.pvenda)
                                                  ),
                                                'QT',
                                                SUM(p.qt * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                                'PE',
                                                SUM(p.qt * pr.pesoliq),
                                                'MX',
                                                COUNT(DISTINCT p.codprod)) valor
                                    FROM pcpedi p, VW_ALIENACAO_FORNEC pr
                                   WHERE pr.codprod = p.codprod
                                     AND nvl(p.brinde, 'N') <> 'S'
                                     AND nvl(p.bonific, 'N') = 'N'
                                     AND p.numped IN (SELECT numped
                                                        FROM pcpedc
                                                       WHERE codcli = G_CODCLI
                                                         AND posicao <> 'C'
                                                         AND dtcancel IS NULL
                                                         AND numped > G_NUMPED_GZERO
                                                         --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                         --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                         AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                                     AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                          ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                                   GROUP BY pr.codsec) venda,
                                 (SELECT m.codsec,
                                         decode(validacoes.tipovalor,
                                                'VL',
                                                  DECODE (validacoes.precosemimposto,
                                                  'S',
                                                  SUM(m.qtcont * (m.punitcont - nvl(m.st,0) - nvl(m.vlipi,0))),
                                                  SUM(m.qtcont * m.punitcont)
                                                  ),
                                                'QT',
                                                SUM(m.qtcont * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                                'PE',
                                                SUM(m.qt * m.pesoliq),
                                                'MX',
                                                COUNT(DISTINCT m.codprod)) valor
                                    FROM pcmov m, VW_ALIENACAO_FORNEC pr
                                   WHERE m.codprod = pr.codprod
                                     AND m.numped IN (SELECT c.numped
                                                        FROM pcpedc c, pcpedi i
                                                       WHERE i.numped = c.numped
                                                         AND nvl(i.brinde,'N') <> 'S'
                                                         AND nvl(i.bonific, 'N') = 'N'
                                                         AND c.codcli = G_CODCLI
                                                         AND c.posicao <> 'C'
                                                         AND c.dtcancel IS NULL
                                                         AND c.numped > G_NUMPED_GZERO
                                                         --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                         --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                         AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                                     AND m.dtcancel IS NULL
                                     AND m.codoper = 'ED'
                                  GROUP BY m.codsec) dev
                          WHERE venda.codsec = dev.codsec(+)) itensped,
                         (SELECT b.codigo,
                                 SUM(b.vlmin) valor
                            FROM pcbrindeexvalidacoes b
                           WHERE b.codbrex = campanhas.codbrex
                             AND b.tipo = validacoes.tipo
                             AND b.gruporegra = validacoes.gruporegra
                          GROUP BY b.codigo) itensregras
                   WHERE itensped.codsec = validacoes.codigo
                     AND itensped.codsec = itensregras.codigo
                     AND decode(vn_qtbrindescontemplados,
                                0,
                                itensped.valor,
                                (itensped.valor - (itensregras.valor * vn_qtbrindescontemplados)))
                         --BETWEEN NVL(validacoes.vlmin, 0) AND NVL(validacoes.vlmax, 999999999999); Tarefa: 213115
                         -->= NVL(validacoes.vlmin, 0);
                         >= CASE
                              WHEN vn_qtbrindescontemplados > 0 THEN
                                NVL(validacoes.vlmin, 0)
                              ELSE
                                (NVL(validacoes.vlmin, 0) * vn_qtacumuladavenda)
                            END;
                ELSE
                  vn_count := 0;
                END IF;

              END IF;

              IF vn_count > 0 THEN

                IF campanhas.acumulativa <> 'S'
                THEN

                  SELECT decode(validacoes.tipovalor,
                                'VL',
                                  DECODE (validacoes.precosemimposto,
                                  'S',
                                  SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                  SUM(p.qt * p.pvenda)
                                  ),
                                'QT',
                                SUM(p.qt),
                                'PE',
                                SUM(p.qt * pr.pesoliq),
                                'MX',
                                COUNT(DISTINCT p.codprod)) valor
                    INTO vn_basemultiplo
                    FROM pcpedi p, pcprodut pr
                   WHERE pr.codprod = p.codprod
                     AND nvl(p.brinde, 'N') <> 'S'
                     AND nvl(p.bonific, 'N') = 'N'
                     AND p.numped = pn_numped
                     AND pr.codsec = validacoes.codigo
                     AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                          ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)));
                ELSE
                  /*
                  SELECT decode(vn_qtbrindescontemplados,
                                0,
                                itensped.valor,
                                (itensped.valor - (itensregras.valor * vn_qtbrindescontemplados)))
                    INTO vn_basemultiplo
                    FROM (SELECT validacoes.codigo,
                                 decode(validacoes.tipovalor,
                                        'VL',
                                        SUM(p.qt * p.pvenda),
                                        'QT',
                                        SUM(p.qt * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                        'PE',
                                        SUM(p.qt * pr.pesoliq)) valor
                            FROM pcpedi p, VW_ALIENACAO_FORNEC pr
                           WHERE pr.codprod = p.codprod
                             AND nvl(p.brinde, 'N') <> 'S'
                             AND p.numped IN (SELECT numped
                                                FROM pcpedc
                                               WHERE codcli = G_CODCLI
                                                 AND posicao <> 'C'
                                                 AND dtcancel IS NULL
                                                 AND numped > G_NUMPED_GZERO
                                                 --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                 --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                 AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                             AND pr.codsec = validacoes.codigo) itensped,
                         (SELECT b.codigo,
                                 SUM(b.vlmin) valor
                            FROM pcbrindeexvalidacoes b
                           WHERE codbrex = campanhas.codbrex
                             AND gruporegra = validacoes.gruporegra
                          GROUP BY b.codigo) itensregras
                   WHERE
                   itensped.codigo = itensregras.codigo;*/

                   SELECT SUM((venda.valor - decode(NVL(campanhas.abaterdev,'N'),
                                                'N',
                                                 0,
                                                 NVL(dev.valor,0)))) valor
                      INTO vn_basemultiplo
                      FROM (SELECT pr.codsec,
                                   decode(validacoes.tipovalor,
                                          'VL',
                                            DECODE (validacoes.precosemimposto,
                                            'S',
                                            SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                            SUM(p.qt * p.pvenda)
                                            ),
                                          'QT',
                                          SUM(p.qt * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                          'PE',
                                          SUM(p.qt * pr.pesoliq),
                                          'MX',
                                          COUNT(DISTINCT p.codprod)) valor
                              FROM pcpedi p, VW_ALIENACAO_FORNEC pr
                             WHERE pr.codprod = p.codprod
                               AND pr.codsec = validacoes.codigo -- 4528.062930.2016
                               AND nvl(p.brinde, 'N') <> 'S'
                               AND p.numped IN (SELECT numped
                                                  FROM pcpedc
                                                 WHERE codcli = G_CODCLI
                                                   AND posicao <> 'C'
                                                   AND dtcancel IS NULL
                                                   AND numped > G_NUMPED_GZERO
                                                   --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                   --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                   AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                               AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                    ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                             GROUP BY pr.codsec) venda,
                           (SELECT m.codsec,
                                   decode(validacoes.tipovalor,
                                          'VL',
                                            DECODE (validacoes.precosemimposto,
                                            'S',
                                            SUM(m.qtcont * (m.punitcont - nvl(m.st,0) - nvl(m.vlipi,0))),
                                            SUM(m.qtcont * m.punitcont)
                                            ),
                                          'QT',
                                          SUM(m.qtcont * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                          'PE',
                                          SUM(m.qt * m.pesoliq),
                                          'MX',
                                          COUNT(DISTINCT m.codprod)) valor
                              FROM pcmov m, VW_ALIENACAO_FORNEC pr
                             WHERE m.codprod = pr.codprod
                               AND m.numped IN (SELECT c.numped
                                                  FROM pcpedc c, pcpedi i
                                                 WHERE i.numped = c.numped
                                                   AND nvl(i.brinde,'N') <> 'S'
                                                   AND nvl(i.bonific, 'N') = 'N'
                                                   AND c.codcli = G_CODCLI
                                                   AND c.posicao <> 'C'
                                                   AND c.dtcancel IS NULL
                                                   AND c.numped > G_NUMPED_GZERO
                                                   --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                   --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                   AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim
                                                   AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                                        ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(i.perdesc, 0) = 0))))
                               AND m.dtcancel IS NULL
                               AND m.codoper = 'ED'
                            GROUP BY m.codsec) dev
                    WHERE venda.codsec = dev.codsec(+);

                END IF;

                IF vn_qtloops >= 1 THEN
                  IF NOT vt_tabelaapuracao.EXISTS(vn_qtloops + 1) AND
                     (vt_tabelaapuracao(vt_tabelaapuracao.LAST).codcamp IS NOT NULL) THEN
                    vn_qtloops := vt_tabelaapuracao.LAST + 1;
                    vt_tabelaapuracao.EXTEND;
                  END IF;
                ELSE
                  vn_qtloops := vn_qtloops + 1;
                  vt_tabelaapuracao.EXTEND;
                END IF;

                vr_tabelaapuracao.codcamp := campanhas.codbrex;
                vr_tabelaapuracao.gruporegra := validacoes.gruporegra;
                vr_tabelaapuracao.ok := 'S';
                vr_tabelaapuracao.numregra := C_Validacoes%ROWCOUNT;
/*                vr_tabelaapuracao.multiplo := trunc(vn_basemultiplo /
                                                                GREATEST(nvl(validacoes.vlmin,
                                                                    1)),1);*/

                vr_tabelaapuracao.multiplo := trunc(vn_basemultiplo /
                                                                    (CASE WHEN nvl(validacoes.vlmin,1) = 0 THEN
                                                                      1
                                                                    ELSE
                                                                      nvl(validacoes.vlmin,1)
                                                                    END));


                vt_tabelaapuracao(vn_qtloops) := vr_tabelaapuracao;

              ELSIF (validacoes.gruporegra = 0) AND (pn_numped > 0)  THEN
                EXIT loop_Validacao;

              END IF;
              --Fim 1.2.5.7

            --1.2.5.8 - Validar tipo "F" - Fornecedor
            WHEN 'F' THEN

              IF campanhas.acumulativa <> 'S'
              THEN
                if pn_codprod <> 0 then
                  SELECT COUNT(*)
                    INTO vn_count
                    FROM (SELECT pr.codfornec
                            FROM pcprodut pr
                           WHERE pr.codprod = pn_codprod
                           GROUP BY pr.codfornec) itensped
                   WHERE codfornec = validacoes.codigo;
                else
                  SELECT COUNT(*)
                    INTO vn_count
                    FROM (SELECT pr.codfornec,
                                 decode(validacoes.tipovalor,
                                        'VL',
                                         DECODE (validacoes.precosemimposto,
                                         'S',
                                         SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                         SUM(p.qt * p.pvenda)
                                         ),
                                        'QT',
                                        SUM(p.qt),
                                        'PE',
                                        SUM(p.qt * pr.pesoliq),
                                        'MX',
                                        COUNT(DISTINCT p.codprod)) valor
                            FROM pcpedi p, pcprodut pr
                           WHERE pr.codprod = p.codprod
                             AND nvl(p.brinde, 'N') <> 'S'
                             AND nvl(p.bonific, 'N') = 'N'
                             AND p.numped = pn_numped
                             AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                  ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                           GROUP BY pr.codfornec) itensped
                   WHERE codfornec = validacoes.codigo
                     AND valor BETWEEN NVL(validacoes.vlmin*vn_qtacumuladavenda, 0) AND NVL(validacoes.vlmax, 999999999999);
                end if;
              ELSE

                DECLARE
                  vnPEDTV5qtbrindescontemplados number;
                  vnDEVTV5qtbrindesdevolvidos   number;
                BEGIN
                  SELECT --COUNT(*) qtbrindescontemplados
                        NVL(SUM(I.QT),0) qtbrindescontemplados
                   INTO vnPEDTV5qtbrindescontemplados
                     FROM pcpedi i, pcpedc c
                    WHERE i.numped = c.numped
                      AND NVL(i.brinde,'N') = 'S'
                      AND i.codigobrinde = campanhas.codbrex
                      AND c.numped > G_NUMPED_GZERO
                      AND c.posicao <> 'C'
                      AND c.dtcancel IS NULL
                      AND c.codcli = G_CODCLI
                      --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                      --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                      AND i.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim
                      AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                           ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(i.perdesc, 0) = 0)));

                   SELECT --COUNT(*) qtbrindesdevolvidos
                        NVL(SUM(m.QT),0) qtbrindesdevolvidos
                     INTO vnDEVTV5qtbrindesdevolvidos
                     FROM pcmov m
                    WHERE (m.numped, m.codprod) IN (SELECT c.numped, i.codprod
                                                      FROM pcpedc c, pcpedi i
                                                     WHERE i.numped = c.numped
                                                       AND NVL(i.brinde,'N') = 'S'
                                                       AND i.codigobrinde = campanhas.codbrex
                                                       AND i.codprod = m.codprod
                                                       AND c.codcli = G_CODCLI
                                                       AND c.posicao <> 'C'
                                                       AND c.dtcancel IS NULL
                                                       AND c.numped > G_NUMPED_GZERO
                                                       AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                      --AND m.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND m.dtcancel IS NULL
                      AND m.codoper = 'ED';

                    vn_qtbrindescontemplados := vnPEDTV5qtbrindescontemplados - vnDEVTV5qtbrindesdevolvidos;
                END;

                /*SELECT (PEDTV5.qtbrindescontemplados - DEVTV5.qtbrindesdevolvidos)
                  INTO vn_qtbrindescontemplados
                  FROM
                  (SELECT --COUNT(*) qtbrindescontemplados
                          NVL(SUM(I.QT),0) qtbrindescontemplados
                     FROM pcpedi i, pcpedc c
                    WHERE i.numped = c.numped
                      AND NVL(i.brinde,'N') = 'S'
                      AND i.codigobrinde = campanhas.codbrex
                      AND c.numped > G_NUMPED_GZERO
                      AND c.posicao <> 'C'
                      AND c.dtcancel IS NULL
                      AND c.codcli = G_CODCLI
                      --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                      --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                      --AND i.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND i.codprod IN (SELECT NUMEROS FROM TABLE(CODPRODPREMIO(campanhas.codbrex, validacoes.gruporegra, pn_numpedtv5)))
                      AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim) PEDTV5,
                  (SELECT --COUNT(*) qtbrindesdevolvidos
                          NVL(SUM(m.QT),0) qtbrindesdevolvidos
                     FROM pcmov m
                    WHERE (m.numped, m.codprod) IN (SELECT c.numped, i.codprod
                                                      FROM pcpedc c, pcpedi i
                                                     WHERE i.numped = c.numped
                                                       AND NVL(i.brinde,'N') = 'S'
                                                       AND i.codigobrinde = campanhas.codbrex
                                                       AND i.codprod = m.codprod
                                                       AND c.codcli = G_CODCLI
                                                       AND c.posicao <> 'C'
                                                       AND c.dtcancel IS NULL
                                                       AND c.numped > G_NUMPED_GZERO
                                                       AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                      --AND m.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND m.dtcancel IS NULL
                      AND m.codoper = 'ED') DEVTV5; */

                vn_count := 0; --REAPROVEITANDO VARIÁVEL
                SELECT SUM(QT)
                  INTO vn_count --REAPROVEITANDO VARIÁVEL
                  FROM PCBRINDEEXPREMIO
                 WHERE CODBREX = CAMPANHAS.CODBREX
                   AND GRUPOREGRA = VALIDACOES.GRUPOREGRA;

                IF NVL(vn_count,0) > 0 THEN
                  vn_qtbrindescontemplados := TRUNC(vn_qtbrindescontemplados / vn_count);
                END IF;

                BEGIN
                  SELECT decode(qtmaxmultiplo, 0, 999999999999, MAX(qtmaxmultiplo))
                    INTO vn_maxmultiplo
                    FROM pcbrindeexpremio
                   WHERE codbrex = campanhas.codbrex
                     AND gruporegra = validacoes.gruporegra
                GROUP BY qtmaxmultiplo;
                EXCEPTION
                  WHEN OTHERS THEN
                    vn_maxmultiplo := 999999999999;
                END;

                IF (vn_qtbrindescontemplados < vn_maxmultiplo)
                AND (vn_maxmultiplo > 0)
                THEN
                  SELECT COUNT(*)
                    INTO vn_count
                    FROM (SELECT venda.codfornec,
                                 (venda.valor - decode(NVL(campanhas.abaterdev,'N'),
                                                       'N',
                                                       0,
                                                       NVL(dev.valor,0))) valor
                            FROM (SELECT pr.codfornec,
                                         decode(validacoes.tipovalor,
                                                'VL',
                                                  DECODE (validacoes.precosemimposto,
                                                  'S',
                                                  SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                                  SUM(p.qt * p.pvenda)
                                                  ),
                                                'QT',
                                                SUM(p.qt * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                                'PE',
                                                SUM(p.qt * pr.pesoliq),
                                                'MX',
                                                COUNT(DISTINCT p.codprod)) valor
                                    FROM pcpedi p, VW_ALIENACAO_FORNEC pr
                                   WHERE pr.codprod = p.codprod
                                     AND nvl(p.brinde, 'N') <> 'S'
                                     AND nvl(p.bonific, 'N') = 'N'
                                     AND p.numped IN (SELECT numped
                                                        FROM pcpedc
                                                       WHERE codcli = G_CODCLI
                                                         AND posicao <> 'C'
                                                         AND dtcancel IS NULL
                                                         AND numped > G_NUMPED_GZERO
                                                         --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                         --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                         AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                                     AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                          ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                                   GROUP BY pr.codfornec) venda,
                                 (SELECT m.codfornec,
                                         decode(validacoes.tipovalor,
                                                'VL',
                                                  DECODE (validacoes.precosemimposto,
                                                  'S',
                                                  SUM(m.qtcont * (m.punitcont - nvl(m.st,0) - nvl(m.vlipi,0))),
                                                  SUM(m.qtcont * m.punitcont)
                                                  ),
                                                'QT',
                                                SUM(m.qtcont * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                                'PE',
                                                SUM(m.qt * m.pesoliq),
                                                'MX',
                                                COUNT(DISTINCT m.codprod)) valor
                                    FROM pcmov m, VW_ALIENACAO_FORNEC pr
                                   WHERE pr.codprod = m.codprod
                                     AND m.numped IN (SELECT c.numped
                                                        FROM pcpedc c, pcpedi i
                                                       WHERE i.numped = c.numped
                                                         AND nvl(i.brinde,'N') <> 'S'
                                                         AND nvl(i.bonific, 'N') = 'N'
                                                         AND c.codcli = G_CODCLI
                                                         AND c.posicao <> 'C'
                                                         AND c.dtcancel IS NULL
                                                         AND c.numped > G_NUMPED_GZERO
                                                         --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                         --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                         AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                                     AND m.dtcancel IS NULL
                                     AND m.codoper = 'ED'
                                  GROUP BY m.codfornec) dev
                          WHERE venda.codfornec = dev.codfornec(+)) itensped,
                         (SELECT b.codigo,
                                 SUM(b.vlmin) valor
                            FROM pcbrindeexvalidacoes b
                           WHERE b.codbrex = campanhas.codbrex
                             AND b.tipo = validacoes.tipo
                             AND b.gruporegra = validacoes.gruporegra
                          GROUP BY b.codigo) itensregras
                   WHERE itensped.codfornec = validacoes.codigo
                     AND itensped.codfornec = itensregras.codigo
                     AND decode(vn_qtbrindescontemplados,
                                0,
                                itensped.valor,
                                (itensped.valor - (itensregras.valor * vn_qtbrindescontemplados)))
                         --BETWEEN NVL(validacoes.vlmin, 0) AND NVL(validacoes.vlmax, 999999999999); Tarefa: 213115
                         -->= NVL(validacoes.vlmin, 0);
                         >= CASE
                              WHEN vn_qtbrindescontemplados > 0 THEN
                                NVL(validacoes.vlmin, 0)
                              ELSE
                                (NVL(validacoes.vlmin, 0) * vn_qtacumuladavenda)
                            END;
                ELSE
                  vn_count := 0;
                END IF;

              END IF;

              IF vn_count > 0 THEN

                IF campanhas.acumulativa <> 'S'
                THEN

                  SELECT decode(validacoes.tipovalor,
                                'VL',
                                  DECODE (validacoes.precosemimposto,
                                  'S',
                                  SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                  SUM(p.qt * p.pvenda)
                                  ),
                                'QT',
                                SUM(p.qt),
                                'PE',
                                SUM(p.qt * pr.pesoliq),
                                'MX',
                                COUNT(DISTINCT p.codprod)) valor
                    INTO vn_basemultiplo
                    FROM pcpedi p, pcprodut pr
                   WHERE pr.codprod = p.codprod
                     AND nvl(p.brinde, 'N') <> 'S'
                     AND nvl(p.bonific, 'N') = 'N'
                     AND p.numped = pn_numped
                     AND pr.codfornec = validacoes.codigo
                     AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                          ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)));
                ELSE
                  IF (vn_qtbrindescontemplados < vn_maxmultiplo)
                  AND (vn_maxmultiplo > 0)
                  THEN
                    /*
                    SELECT decode(vn_qtbrindescontemplados,
                                  0,
                                  itensped.valor,
                                  (itensped.valor - (itensregras.valor * vn_qtbrindescontemplados)))
                      INTO vn_basemultiplo
                      FROM (SELECT validacoes.codigo,
                                   decode(validacoes.tipovalor,
                                          'VL',
                                          SUM(p.qt * p.pvenda),
                                          'QT',
                                          SUM(p.qt * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                          'PE',
                                          SUM(p.qt * pr.pesoliq)) valor
                              FROM pcpedi p, VW_ALIENACAO_FORNEC pr
                             WHERE pr.codprod = p.codprod
                               AND nvl(p.brinde, 'N') <> 'S'
                               AND p.numped IN (SELECT numped
                                                  FROM pcpedc
                                                 WHERE codcli = G_CODCLI
                                                   AND posicao <> 'C'
                                                   AND dtcancel IS NULL
                                                   AND numped > G_NUMPED_GZERO
                                                   --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                   ---    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                   AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                               AND pr.codfornec = validacoes.codigo) itensped,
                           (SELECT b.codigo,
                                   SUM(b.vlmin) valor
                              FROM pcbrindeexvalidacoes b
                             WHERE codbrex = campanhas.codbrex
                               AND gruporegra = validacoes.gruporegra
                            GROUP BY b.codigo) itensregras
                     WHERE
                     itensped.codigo = itensregras.codigo;*/

                     SELECT sum((venda.valor - decode(NVL(campanhas.abaterdev,'N'),
                                                  'N',
                                                  0,
                                                  NVL(dev.valor,0)))) valor
                      INTO vn_basemultiplo
                      FROM (SELECT pr.codfornec,
                                   decode(validacoes.tipovalor,
                                          'VL',
                                            DECODE (validacoes.precosemimposto,
                                            'S',
                                            SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                            SUM(p.qt * p.pvenda)
                                            ),
                                          'QT',
                                          SUM(p.qt * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                          'PE',
                                          SUM(p.qt * pr.pesoliq),
                                          'MX',
                                          COUNT(DISTINCT p.codprod)) valor
                              FROM pcpedi p, VW_ALIENACAO_FORNEC pr
                             WHERE pr.codprod = p.codprod
                               AND nvl(p.brinde, 'N') <> 'S'
                               AND nvl(p.bonific, 'N') = 'N'
                               AND p.numped IN (SELECT numped
                                                  FROM pcpedc
                                                 WHERE codcli = G_CODCLI
                                                   AND posicao <> 'C'
                                                   AND dtcancel IS NULL
                                                   AND numped > G_NUMPED_GZERO
                                                   --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                   --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                   AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                               AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                    ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                             GROUP BY pr.codfornec) venda,
                           (SELECT m.codfornec,
                                   decode(validacoes.tipovalor,
                                          'VL',
                                            DECODE (validacoes.precosemimposto,
                                            'S',
                                            SUM(m.qtcont * (m.punitcont - nvl(m.st,0) - nvl(m.vlipi,0))),
                                            SUM(m.qtcont * m.punitcont)
                                            ),
                                          'QT',
                                          SUM(m.qtcont * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                          'PE',
                                          SUM(m.qt * m.pesoliq),
                                          'MX',
                                          COUNT(DISTINCT m.codprod)) valor
                              FROM pcmov m, VW_ALIENACAO_FORNEC pr
                             WHERE pr.codprod = m.codprod
                               AND m.numped IN (SELECT c.numped
                                                  FROM pcpedc c, pcpedi i
                                                 WHERE i.numped = c.numped
                                                   AND nvl(i.brinde,'N') <> 'S'
                                                   AND nvl(i.bonific, 'N') = 'N'
                                                   AND c.codcli = G_CODCLI
                                                   AND c.posicao <> 'C'
                                                   AND c.dtcancel IS NULL
                                                   AND c.numped > G_NUMPED_GZERO
                                                   --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                   --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                   AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                               AND m.dtcancel IS NULL
                               AND m.codoper = 'ED'
                            GROUP BY m.codfornec) dev
                    WHERE venda.codfornec = dev.codfornec(+);

                  END IF;

                END IF;

                IF vn_qtloops >= 1 THEN
                  IF NOT vt_tabelaapuracao.EXISTS(vn_qtloops + 1) AND
                     (vt_tabelaapuracao(vt_tabelaapuracao.LAST).codcamp IS NOT NULL) THEN
                    vn_qtloops := vt_tabelaapuracao.LAST + 1;
                    vt_tabelaapuracao.EXTEND;
                  END IF;
                ELSE
                  vn_qtloops := vn_qtloops + 1;
                  vt_tabelaapuracao.EXTEND;
                END IF;

                vr_tabelaapuracao.codcamp := campanhas.codbrex;
                vr_tabelaapuracao.gruporegra := validacoes.gruporegra;
                vr_tabelaapuracao.ok := 'S';
                vr_tabelaapuracao.numregra := C_Validacoes%ROWCOUNT;
/*                vr_tabelaapuracao.multiplo := trunc(vn_basemultiplo /
                                                                GREATEST(nvl(validacoes.vlmin,
                                                                    1)),1);*/

                vr_tabelaapuracao.multiplo := trunc(vn_basemultiplo /
                                                                    (CASE WHEN nvl(validacoes.vlmin,1) = 0 THEN
                                                                      1
                                                                    ELSE
                                                                      nvl(validacoes.vlmin,1)
                                                                    END));


                vt_tabelaapuracao(vn_qtloops) := vr_tabelaapuracao;

              ELSIF (validacoes.gruporegra = 0) AND (pn_numped > 0)  THEN
                EXIT loop_Validacao;

              END IF;
              --Fim 1.2.5.8

            --1.2.5.9 - Validar tipo "GP" - Grupo de Produtos
            WHEN 'GP' THEN

              IF campanhas.acumulativa <> 'S'
              THEN
                if pn_codprod > 0 then
                  SELECT COUNT(*)
                    INTO vn_count
                    FROM (SELECT gp.codgrupo
                            FROM pcprodut pr, pcgruposcampanhai gp
                           WHERE pr.codprod = pn_codprod
                             AND pr.codprod = gp.coditem
                             AND gp.codgrupo = validacoes.codigo
                           GROUP BY gp.codgrupo) itensped;
                else
                  SELECT COUNT(*)
                    INTO vn_count
                    FROM (SELECT gp.codgrupo,
                                 decode(validacoes.tipovalor,
                                        'VL',
                                          DECODE (validacoes.precosemimposto,
                                          'S',
                                          SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                          SUM(p.qt * p.pvenda)
                                          ),
                                        'QT',
                                        SUM(p.qt),
                                        'PE',
                                        SUM(p.qt * pr.pesoliq),
                                        'MX',
                                        COUNT(DISTINCT p.codprod)) valor
                            FROM pcpedi p, pcprodut pr, pcgruposcampanhai gp
                           WHERE pr.codprod = p.codprod
                             AND nvl(p.brinde, 'N') <> 'S'
                             AND nvl(p.bonific, 'N') = 'N'
                             AND pr.codprod = gp.coditem
                             AND gp.codgrupo = validacoes.codigo
                             AND p.numped = pn_numped
                             AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                  ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                           GROUP BY gp.codgrupo) itensped
                   WHERE valor BETWEEN NVL(validacoes.vlmin*vn_qtacumuladavenda, 0) AND NVL(validacoes.vlmax, 999999999999);
                end if;
              ELSE
                DECLARE
                  vnPEDTV5qtbrindescontemplados number;
                  vnDEVTV5qtbrindesdevolvidos   number;
                BEGIN
                  SELECT --COUNT(*) qtbrindescontemplados
                        NVL(SUM(I.QT),0) qtbrindescontemplados
                   INTO vnPEDTV5qtbrindescontemplados
                     FROM pcpedi i, pcpedc c
                    WHERE i.numped = c.numped
                      AND NVL(i.brinde,'N') = 'S'
                      AND i.codigobrinde = campanhas.codbrex
                      AND c.numped > G_NUMPED_GZERO
                      AND c.posicao <> 'C'
                      AND c.dtcancel IS NULL
                      AND c.codcli = G_CODCLI
                      --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                      --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                      AND i.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim
                      AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                           ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(i.perdesc, 0) = 0)));


                   SELECT --COUNT(*) qtbrindesdevolvidos
                        NVL(SUM(m.QT),0) qtbrindesdevolvidos
                     INTO vnDEVTV5qtbrindesdevolvidos
                     FROM pcmov m
                    WHERE (m.numped, m.codprod) IN (SELECT c.numped, i.codprod
                                                      FROM pcpedc c, pcpedi i
                                                     WHERE i.numped = c.numped
                                                       AND NVL(i.brinde,'N') = 'S'
                                                       AND i.codigobrinde = campanhas.codbrex
                                                       AND i.codprod = m.codprod
                                                       AND c.codcli = G_CODCLI
                                                       AND c.posicao <> 'C'
                                                       AND c.dtcancel IS NULL
                                                       AND c.numped > G_NUMPED_GZERO
                                                       AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                      --AND m.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND m.dtcancel IS NULL
                      AND m.codoper = 'ED';

                    vn_qtbrindescontemplados := vnPEDTV5qtbrindescontemplados - vnDEVTV5qtbrindesdevolvidos;
                END;

                /*SELECT (PEDTV5.qtbrindescontemplados - DEVTV5.qtbrindesdevolvidos)
                  INTO vn_qtbrindescontemplados
                  FROM
                  (SELECT --COUNT(*) qtbrindescontemplados
                          NVL(SUM(I.QT),0) qtbrindescontemplados
                     FROM pcpedi i, pcpedc c
                    WHERE i.numped = c.numped
                      AND NVL(i.brinde,'N') = 'S'
                      AND i.codigobrinde = campanhas.codbrex
                      AND c.numped > G_NUMPED_GZERO
                      AND c.posicao <> 'C'
                      AND c.dtcancel IS NULL
                      AND c.codcli = G_CODCLI
                      --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                      --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                      --AND i.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND i.codprod IN (SELECT NUMEROS FROM TABLE(CODPRODPREMIO(campanhas.codbrex, validacoes.gruporegra, pn_numpedtv5)))
                      AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim) PEDTV5,
                  (SELECT COUNT(*) qtbrindesdevolvidos
                    FROM pcmov m
                    WHERE (m.numped, m.codprod) IN (SELECT c.numped, i.codprod
                                                      FROM pcpedc c, pcpedi i
                                                     WHERE i.numped = c.numped
                                                       AND NVL(i.brinde,'N') = 'S'
                                                       AND i.codigobrinde = campanhas.codbrex
                                                       AND i.codprod = m.codprod
                                                       AND c.codcli = G_CODCLI
                                                       AND c.posicao <> 'C'
                                                       AND c.dtcancel IS NULL
                                                       AND c.numped > G_NUMPED_GZERO
                                                       AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                      --AND m.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND m.dtcancel IS NULL
                      AND m.codoper = 'ED') DEVTV5; */

                vn_count := 0; --REAPROVEITANDO VARIÁVEL
                SELECT SUM(QT)
                  INTO vn_count --REAPROVEITANDO VARIÁVEL
                  FROM PCBRINDEEXPREMIO
                 WHERE CODBREX = CAMPANHAS.CODBREX
                   AND GRUPOREGRA = VALIDACOES.GRUPOREGRA;

                IF NVL(vn_count,0) > 0 THEN
                  vn_qtbrindescontemplados := TRUNC(vn_qtbrindescontemplados / vn_count);
                END IF;

                BEGIN
                  SELECT decode(qtmaxmultiplo, 0, 999999999999, MAX(qtmaxmultiplo))
                    INTO vn_maxmultiplo
                    FROM pcbrindeexpremio
                   WHERE codbrex = campanhas.codbrex
                     AND gruporegra = validacoes.gruporegra
                GROUP BY qtmaxmultiplo;
                EXCEPTION
                  WHEN OTHERS THEN
                    vn_maxmultiplo := 999999999999;
                END;

                IF (vn_qtbrindescontemplados < vn_maxmultiplo)
                AND (vn_maxmultiplo > 0)
                THEN
                  SELECT COUNT(*)
                    INTO vn_count
                    FROM (SELECT venda.codgrupo,
                                 (venda.valor - decode(NVL(campanhas.abaterdev,'N'),
                                                       'N',
                                                       0,
                                                       NVL(dev.valor,0))) valor
                            FROM (SELECT gp.codgrupo,
                                         decode(validacoes.tipovalor,
                                                'VL',
                                                  DECODE (validacoes.precosemimposto,
                                                  'S',
                                                  SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                                  SUM(p.qt * p.pvenda)
                                                  ),
                                                'QT',
                                                SUM(p.qt * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                                'PE',
                                                SUM(p.qt * pr.pesoliq),
                                                'MX',
                                                COUNT(DISTINCT p.codprod)) valor
                                    FROM pcpedi p, VW_ALIENACAO_FORNEC pr, pcgruposcampanhai gp
                                   WHERE pr.codprod = p.codprod
                                     AND gp.codgrupo = validacoes.codigo
                                     AND gp.coditem = pr.codprod
                                     AND nvl(p.brinde, 'N') <> 'S'
                                     AND nvl(p.bonific, 'N') = 'N'
                                     AND p.numped IN (SELECT numped
                                                        FROM pcpedc
                                                       WHERE codcli = G_CODCLI
                                                         AND posicao <> 'C'
                                                         AND dtcancel IS NULL
                                                         AND numped > G_NUMPED_GZERO
                                                         --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                         --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                         AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                                     AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                          ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                                   GROUP BY gp.codgrupo) venda,
                                 (SELECT gp.codgrupo,
                                         decode(validacoes.tipovalor,
                                                'VL',
                                                  DECODE (validacoes.precosemimposto,
                                                  'S',
                                                  SUM(m.qtcont * (m.punitcont - nvl(m.st,0) - nvl(m.vlipi,0))),
                                                  SUM(m.qtcont * m.punitcont)
                                                  ),
                                                'QT',
                                                SUM(m.qtcont * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                                'PE',
                                                SUM(m.qt * m.pesoliq),
                                                'MX',
                                                COUNT(DISTINCT m.codprod)) valor
                                    FROM pcmov m, pcgruposcampanhai gp, VW_ALIENACAO_FORNEC pr
                                   WHERE m.codprod = gp.coditem
                                     AND gp.codgrupo = validacoes.codigo
                                     AND pr.codprod = gp.coditem
                                     AND m.numped IN (SELECT c.numped
                                                        FROM pcpedc c, pcpedi i
                                                       WHERE i.numped = c.numped
                                                         AND nvl(i.brinde,'N') <> 'S'
                                                         AND nvl(i.bonific, 'N') = 'N'
                                                         AND c.codcli = G_CODCLI
                                                         AND c.posicao <> 'C'
                                                         AND c.dtcancel IS NULL
                                                         AND c.numped > G_NUMPED_GZERO
                                                         --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                         --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                         AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                                     AND m.dtcancel IS NULL
                                     AND m.codoper = 'ED'
                                  GROUP BY gp.codgrupo) dev
                          WHERE venda.codgrupo = dev.codgrupo(+)) itensped,
                         (SELECT b.codigo,
                                 SUM(b.vlmin) valor
                            FROM pcbrindeexvalidacoes b
                           WHERE b.codbrex = campanhas.codbrex
                             AND b.tipo = validacoes.tipo
                             AND b.gruporegra = validacoes.gruporegra
                          GROUP BY b.codigo) itensregras
                   WHERE itensped.codgrupo = validacoes.codigo
                     AND itensped.codgrupo = itensregras.codigo
                     AND decode(vn_qtbrindescontemplados,
                                0,
                                itensped.valor,
                                (itensped.valor - (itensregras.valor * vn_qtbrindescontemplados)))
                         --BETWEEN NVL(validacoes.vlmin, 0) AND NVL(validacoes.vlmax, 999999999999); Tarefa: 213115
                         -->= NVL(validacoes.vlmin, 0);
                         >= CASE
                              WHEN vn_qtbrindescontemplados > 0 THEN
                                NVL(validacoes.vlmin, 0)
                              ELSE
                                (NVL(validacoes.vlmin, 0) * vn_qtacumuladavenda)
                            END;

                ELSE
                  vn_count := 0;
                END IF;

              END IF;

              IF vn_count > 0 THEN

                IF campanhas.acumulativa <> 'S'
                THEN

                  SELECT decode(validacoes.tipovalor,
                                'VL',
                                  DECODE (validacoes.precosemimposto,
                                  'S',
                                  SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                  SUM(p.qt * p.pvenda)
                                  ),
                                'QT',
                                SUM(p.qt),
                                'PE',
                                SUM(p.qt * pr.pesoliq),
                                'MX',
                                COUNT(DISTINCT p.codprod)) valor
                    INTO vn_basemultiplo
                    FROM pcpedi p, pcprodut pr, pcgruposcampanhai gp
                   WHERE pr.codprod = p.codprod
                     AND nvl(p.brinde, 'N') <> 'S'
                     AND nvl(p.bonific, 'N') = 'N'
                     AND pr.codprod = gp.coditem
                     AND p.numped = pn_numped
                     AND gp.codgrupo = validacoes.codigo
                     AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                          ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)));
                ELSE
                  IF (vn_qtbrindescontemplados < vn_maxmultiplo)
                  AND (vn_maxmultiplo > 0)
                  THEN
                    /*
                    SELECT decode(vn_qtbrindescontemplados,
                                  0,
                                  itensped.valor,
                                  (itensped.valor - (itensregras.valor * vn_qtbrindescontemplados)))
                    INTO vn_basemultiplo
                    FROM (SELECT validacoes.codigo,
                                 decode(validacoes.tipovalor,
                                        'VL',
                                        SUM(p.qt * p.pvenda),
                                        'QT',
                                        SUM(p.qt * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                        'PE',
                                        SUM(p.qt * pr.pesoliq)) valor
                            FROM pcpedi p, VW_ALIENACAO_FORNEC pr, pcgruposcampanhai gp
                           WHERE pr.codprod = p.codprod
                             AND nvl(p.brinde, 'N') <> 'S'
                             AND pr.codprod = gp.coditem
                             AND p.numped IN (SELECT numped
                                                FROM pcpedc
                                               WHERE codcli = G_CODCLI
                                                 AND posicao <> 'C'
                                                 AND dtcancel IS NULL
                                                 AND numped > G_NUMPED_GZERO
                                                 --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                 --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                 AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                             AND gp.codgrupo = validacoes.codigo) itensped,
                         (SELECT b.codigo,
                                 SUM(b.vlmin) valor
                            FROM pcbrindeexvalidacoes b
                           WHERE codbrex = campanhas.codbrex
                             AND gruporegra = validacoes.gruporegra
                          GROUP BY b.codigo) itensregras
                   WHERE
                   itensped.codigo = itensregras.codigo;*/

                   SELECT SUM((venda.valor - decode(NVL(campanhas.abaterdev,'N'),
                                                'N',
                                                0,
                                                NVL(dev.valor,0)))) valor
                      INTO vn_basemultiplo
                      FROM (SELECT gp.codgrupo,
                                   decode(validacoes.tipovalor,
                                          'VL',
                                            DECODE (validacoes.precosemimposto,
                                            'S',
                                            SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                            SUM(p.qt * p.pvenda)
                                            ),
                                          'QT',
                                          SUM(p.qt * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                          'PE',
                                          SUM(p.qt * pr.pesoliq),
                                          'MX',
                                          COUNT(DISTINCT p.codprod)) valor
                              FROM pcpedi p, VW_ALIENACAO_FORNEC pr, pcgruposcampanhai gp
                             WHERE pr.codprod = p.codprod
                               AND gp.codgrupo = validacoes.codigo
                               AND gp.coditem = pr.codprod
                               AND nvl(p.brinde, 'N') <> 'S'
                               AND nvl(p.bonific, 'N') = 'N'
                               AND p.numped IN (SELECT numped
                                                  FROM pcpedc
                                                 WHERE codcli = G_CODCLI
                                                   AND posicao <> 'C'
                                                   AND dtcancel IS NULL
                                                   AND numped > G_NUMPED_GZERO
                                                   --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                   --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                   AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                               AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                    ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                             GROUP BY gp.codgrupo) venda,
                           (SELECT gp.codgrupo,
                                   decode(validacoes.tipovalor,
                                          'VL',
                                            DECODE (validacoes.precosemimposto,
                                            'S',
                                            SUM(m.qtcont * (m.punitcont - nvl(m.st,0) - nvl(m.vlipi,0))),
                                            SUM(m.qtcont * m.punitcont)
                                            ),
                                          'QT',
                                          SUM(m.qtcont * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                          'PE',
                                          SUM(m.qt * m.pesoliq),
                                          'MX',
                                          COUNT(DISTINCT m.codprod)) valor
                              FROM pcmov m, pcgruposcampanhai gp, VW_ALIENACAO_FORNEC pr
                             WHERE m.codprod = gp.coditem
                               AND gp.codgrupo = validacoes.codigo
                               AND pr.codprod = gp.coditem
                               AND m.numped IN (SELECT c.numped
                                                  FROM pcpedc c, pcpedi i
                                                 WHERE i.numped = c.numped
                                                   AND nvl(i.brinde,'N') <> 'S'
                                                   AND nvl(i.bonific, 'N') = 'N'
                                                   AND c.codcli = G_CODCLI
                                                   AND c.posicao <> 'C'
                                                   AND c.dtcancel IS NULL
                                                   AND c.numped > G_NUMPED_GZERO
                                                   --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                   --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                   AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                               AND m.dtcancel IS NULL
                               AND m.codoper = 'ED'
                            GROUP BY gp.codgrupo) dev
                    WHERE venda.codgrupo = dev.codgrupo(+);

                  END IF;

                END IF;

                IF vn_qtloops >= 1 THEN
                  IF NOT vt_tabelaapuracao.EXISTS(vn_qtloops + 1) AND
                     (vt_tabelaapuracao(vt_tabelaapuracao.LAST).codcamp IS NOT NULL) THEN
                    vn_qtloops := vt_tabelaapuracao.LAST + 1;
                    vt_tabelaapuracao.EXTEND;
                  END IF;
                ELSE
                  vn_qtloops := vn_qtloops + 1;
                  vt_tabelaapuracao.EXTEND;
                END IF;

                vr_tabelaapuracao.codcamp := campanhas.codbrex;
                vr_tabelaapuracao.gruporegra := validacoes.gruporegra;
                vr_tabelaapuracao.ok := 'S';
                vr_tabelaapuracao.numregra := C_Validacoes%ROWCOUNT;
/*                vr_tabelaapuracao.multiplo := trunc(vn_basemultiplo /
                                                                GREATEST(nvl(validacoes.vlmin,
                                                                    1)),1);*/

                vr_tabelaapuracao.multiplo := trunc(vn_basemultiplo /
                                                                    (CASE WHEN nvl(validacoes.vlmin,1) = 0 THEN
                                                                      1
                                                                    ELSE
                                                                      nvl(validacoes.vlmin,1)
                                                                    END));



                vt_tabelaapuracao(vn_qtloops) := vr_tabelaapuracao;

              ELSIF (validacoes.gruporegra = 0) AND (pn_numped > 0)  THEN
                EXIT loop_Validacao;

              END IF;
              --Fim 1.2.5.9

            --1.2.5.10 - Validar tipo "PP" - Produto Principal
            WHEN 'PP' THEN

              IF campanhas.acumulativa <> 'S'
              THEN
                if pn_codprod > 0 then
                  SELECT COUNT(*)
                    INTO vn_count
                    FROM (SELECT pr.codprodprinc
                            FROM  pcprodut pr
                           WHERE pr.codprod = pn_codprod
                           GROUP BY pr.codprodprinc) itensped
                   WHERE codprodprinc = validacoes.codigo;
                else
                  SELECT COUNT(*)
                    INTO vn_count
                    FROM (SELECT pr.codprodprinc,
                                 decode(validacoes.tipovalor,
                                        'VL',
                                         DECODE (validacoes.precosemimposto,
                                         'S',
                                         SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                         SUM(p.qt * p.pvenda)
                                         ),
                                        'QT',
                                        SUM(p.qt),
                                        'PE',
                                        SUM(p.qt * pr.pesoliq),
                                        'MX',
                                        COUNT(DISTINCT p.codprod)) valor
                            FROM pcpedi p, pcprodut pr
                           WHERE pr.codprod = p.codprod
                             AND p.codprod not in (select codigo
                                                     from pcbrindeexvalidacoes
                                                    where tipo = 'P'
                                                      and codbrex = campanhas.codbrex
                                                      and gruporegra = validacoes.gruporegra)
                             AND p.numped = pn_numped
                             AND nvl(p.brinde, 'N') <> 'S'
                             AND nvl(p.bonific, 'N') = 'N'
                             AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                  ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                           GROUP BY pr.codprodprinc) itensped
                   WHERE codprodprinc = validacoes.codigo
                     AND valor BETWEEN NVL(validacoes.vlmin*vn_qtacumuladavenda, 0) AND NVL(validacoes.vlmax, 999999999999);
                end if;
              ELSE

                DECLARE
                  vnPEDTV5qtbrindescontemplados number;
                  vnDEVTV5qtbrindesdevolvidos   number;
                BEGIN
                  SELECT --COUNT(*) qtbrindescontemplados
                        NVL(SUM(I.QT),0) qtbrindescontemplados
                   INTO vnPEDTV5qtbrindescontemplados
                     FROM pcpedi i, pcpedc c
                    WHERE i.numped = c.numped
                      AND NVL(i.brinde,'N') = 'S'
                      AND nvl(i.bonific, 'N') = 'N'
                      AND i.codigobrinde = campanhas.codbrex
                      AND c.numped > G_NUMPED_GZERO
                      AND c.posicao <> 'C'
                      AND c.dtcancel IS NULL
                      AND c.codcli = G_CODCLI
                      --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                      --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                      AND i.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim
                      AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                           ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(i.perdesc, 0) = 0)));

                   SELECT --COUNT(*) qtbrindesdevolvidos
                        NVL(SUM(m.QT),0) qtbrindesdevolvidos
                     INTO vnDEVTV5qtbrindesdevolvidos
                     FROM pcmov m
                    WHERE (m.numped, m.codprod) IN (SELECT c.numped, i.codprod
                                                      FROM pcpedc c, pcpedi i
                                                     WHERE i.numped = c.numped
                                                       AND NVL(i.brinde,'N') = 'S'
                                                       AND nvl(i.bonific, 'N') = 'N'
                                                       AND i.codigobrinde = campanhas.codbrex
                                                       AND i.codprod = m.codprod
                                                       AND c.codcli = G_CODCLI
                                                       AND c.posicao <> 'C'
                                                       AND c.dtcancel IS NULL
                                                       AND c.numped > G_NUMPED_GZERO
                                                       AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                      --AND m.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND m.dtcancel IS NULL
                      AND m.codoper = 'ED';

                    vn_qtbrindescontemplados := vnPEDTV5qtbrindescontemplados - vnDEVTV5qtbrindesdevolvidos;
                END;

                /*SELECT (PEDTV5.qtbrindescontemplados - DEVTV5.qtbrindesdevolvidos)
                  INTO vn_qtbrindescontemplados
                  FROM
                  (SELECT --COUNT(*) qtbrindescontemplados
                          NVL(SUM(I.QT),0) qtbrindescontemplados
                     FROM pcpedi i, pcpedc c
                    WHERE i.numped = c.numped
                      AND NVL(i.brinde,'N') = 'S'
                      AND nvl(i.bonific, 'N') = 'N'
                      AND i.codigobrinde = campanhas.codbrex
                      AND c.numped > G_NUMPED_GZERO
                      AND c.posicao <> 'C'
                      AND c.dtcancel IS NULL
                      AND c.codcli = G_CODCLI
                      --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                      --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                      --AND i.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND i.codprod IN (SELECT NUMEROS FROM TABLE(CODPRODPREMIO(campanhas.codbrex, validacoes.gruporegra, pn_numpedtv5)))
                      AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim) PEDTV5,
                  (SELECT --COUNT(*) qtbrindesdevolvidos
                          NVL(SUM(m.QT),0) qtbrindesdevolvidos
                     FROM pcmov m
                    WHERE (m.numped, m.codprod) IN (SELECT c.numped, i.codprod
                                                      FROM pcpedc c, pcpedi i
                                                     WHERE i.numped = c.numped
                                                       AND NVL(i.brinde,'N') = 'S'
                                                       AND nvl(i.bonific, 'N') = 'N'
                                                       AND i.codigobrinde = campanhas.codbrex
                                                       AND i.codprod = m.codprod
                                                       AND c.codcli = G_CODCLI
                                                       AND c.posicao <> 'C'
                                                       AND c.dtcancel IS NULL
                                                       AND c.numped > G_NUMPED_GZERO
                                                       AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                      --AND m.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND m.dtcancel IS NULL
                      AND m.codoper = 'ED') DEVTV5; */

                vn_count := 0; --REAPROVEITANDO VARIÁVEL
                SELECT SUM(QT)
                  INTO vn_count --REAPROVEITANDO VARIÁVEL
                  FROM PCBRINDEEXPREMIO
                 WHERE CODBREX = CAMPANHAS.CODBREX
                   AND GRUPOREGRA = VALIDACOES.GRUPOREGRA;

                IF NVL(vn_count,0) > 0 THEN
                  vn_qtbrindescontemplados := TRUNC(vn_qtbrindescontemplados / vn_count);
                END IF;

                BEGIN
                  SELECT decode(qtmaxmultiplo, 0, 999999999999, MAX(qtmaxmultiplo))
                    INTO vn_maxmultiplo
                    FROM pcbrindeexpremio
                   WHERE codbrex = campanhas.codbrex
                     AND gruporegra = validacoes.gruporegra
                GROUP BY qtmaxmultiplo;
                EXCEPTION
                  WHEN OTHERS THEN
                    vn_maxmultiplo := 999999999999;
                END;

                IF (vn_qtbrindescontemplados < vn_maxmultiplo)
                AND (vn_maxmultiplo > 0)
                THEN
                  SELECT COUNT(*)
                    INTO vn_count
                    FROM (SELECT venda.codprodprinc,
                                 (venda.valor - decode(NVL(campanhas.abaterdev,'N'),
                                                       'N',
                                                       0,
                                                       NVL(dev.valor,0))) valor
                            FROM (SELECT pr.codprodprinc,
                                         decode(validacoes.tipovalor,
                                                'VL',
                                                 DECODE (validacoes.precosemimposto,
                                                 'S',
                                                 SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                                 SUM(p.qt * p.pvenda)
                                                 ),
                                                'QT',
                                                SUM(p.qt * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                                'PE',
                                                SUM(p.qt * pr.pesoliq),
                                                'MX',
                                                COUNT(DISTINCT p.codprod)) valor
                                    FROM pcpedi p, VW_ALIENACAO_FORNEC pr
                                   WHERE pr.codprod = p.codprod
                                     AND nvl(p.brinde, 'N') <> 'S'
                                     AND nvl(p.bonific, 'N') = 'N'
                                     AND p.numped IN (SELECT numped
                                                        FROM pcpedc
                                                       WHERE codcli = G_CODCLI
                                                         AND posicao <> 'C'
                                                         AND dtcancel IS NULL
                                                         AND numped > G_NUMPED_GZERO
                                                         --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                         --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                         AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                                     AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                          ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                                   GROUP BY pr.codprodprinc) venda,
                                 (SELECT m.codprodprinc,
                                         decode(validacoes.tipovalor,
                                                'VL',
                                                  DECODE (validacoes.precosemimposto,
                                                  'S',
                                                  SUM(m.qtcont * (m.punitcont - nvl(m.st,0) - nvl(m.vlipi,0))),
                                                  SUM(m.qtcont * m.punitcont)
                                                  ),
                                                'QT',
                                                SUM(m.qtcont * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                                'PE',
                                                SUM(m.qt * m.pesoliq),
                                                'MX',
                                                COUNT(DISTINCT m.codprod)) valor
                                    FROM pcmov m, VW_ALIENACAO_FORNEC pr
                                   WHERE pr.codprod = m.codprod
                                     AND m.numped IN (SELECT c.numped
                                                        FROM pcpedc c, pcpedi i
                                                       WHERE i.numped = c.numped
                                                         AND nvl(i.brinde,'N') <> 'S'
                                                         AND nvl(i.bonific, 'N') = 'N'
                                                         AND c.codcli = G_CODCLI
                                                         AND c.posicao <> 'C'
                                                         AND c.dtcancel IS NULL
                                                         AND c.numped > G_NUMPED_GZERO
                                                         --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                         --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                         AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                                     AND m.dtcancel IS NULL
                                     AND m.codoper = 'ED'
                                  GROUP BY m.codprodprinc) dev
                          WHERE venda.codprodprinc = dev.codprodprinc(+)) itensped,
                         (SELECT b.codigo,
                                 SUM(b.vlmin) valor
                            FROM pcbrindeexvalidacoes b
                           WHERE b.codbrex = campanhas.codbrex
                             AND b.tipo = validacoes.tipo
                             AND b.gruporegra = validacoes.gruporegra
                          GROUP BY b.codigo) itensregras
                   WHERE itensped.codprodprinc = validacoes.codigo
                     AND itensped.codprodprinc = itensregras.codigo
                     AND decode(vn_qtbrindescontemplados,
                                0,
                                itensped.valor,
                                (itensped.valor - (itensregras.valor * vn_qtbrindescontemplados)))
                         --BETWEEN NVL(validacoes.vlmin, 0) AND NVL(validacoes.vlmax, 999999999999); Tarefa: 213115
                         -->= NVL(validacoes.vlmin, 0);
                         >= CASE
                              WHEN vn_qtbrindescontemplados > 0 THEN
                                NVL(validacoes.vlmin, 0)
                              ELSE
                                (NVL(validacoes.vlmin, 0) * vn_qtacumuladavenda)
                            END;
                ELSE
                  vn_count := 0;
                END IF;

              END IF;

              IF vn_count > 0 THEN

                IF campanhas.acumulativa <> 'S'
                THEN

                  SELECT decode(validacoes.tipovalor,
                                'VL',
                                  DECODE (validacoes.precosemimposto,
                                  'S',
                                  SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                  SUM(p.qt * p.pvenda)
                                  ),
                                'QT',
                                SUM(p.qt),
                                'PE',
                                SUM(p.qt * pr.pesoliq),
                                'MX',
                                COUNT(DISTINCT p.codprod)) valor
                    INTO vn_basemultiplo
                    FROM pcpedi p, pcprodut pr
                   WHERE pr.codprod = p.codprod
                     AND p.codprod not in (select codigo
                                             from pcbrindeexvalidacoes
                                            where tipo = 'P'
                                              and codbrex = campanhas.codbrex
                                              and gruporegra = validacoes.gruporegra)
                     AND nvl(p.brinde, 'N') <> 'S'
                     AND nvl(p.bonific, 'N') = 'N'
                     AND p.numped = pn_numped
                     AND pr.codprodprinc = validacoes.codigo
                     AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                          ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)));
                ELSE
                  IF (vn_qtbrindescontemplados < vn_maxmultiplo)
                  AND (vn_maxmultiplo > 0)
                  THEN
                    /*
                    SELECT decode(vn_qtbrindescontemplados,
                                  0,
                                  itensped.valor,
                                  (itensped.valor - (itensregras.valor * vn_qtbrindescontemplados)))
                    INTO vn_basemultiplo
                    FROM (SELECT validacoes.codigo,
                                 decode(validacoes.tipovalor,
                                        'VL',
                                        SUM(p.qt * p.pvenda),
                                        'QT',
                                        SUM(p.qt * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                        'PE',
                                        SUM(p.qt * pr.pesoliq)) valor
                            FROM pcpedi p, VW_ALIENACAO_FORNEC pr
                           WHERE pr.codprod = p.codprod
                             AND nvl(p.brinde, 'N') <> 'S'
                             AND p.numped IN (SELECT c.numped
                                                FROM pcpedc c, pcpedi i
                                               WHERE i.numped = c.numped
                                                 AND nvl(i.brinde,'N') <> 'S'
                                                 AND c.codcli = G_CODCLI
                                                 AND c.posicao <> 'C'
                                                 AND c.dtcancel IS NULL
                                                 AND c.numped > G_NUMPED_GZERO
                                                 --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                 --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                 AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                             AND pr.codprodprinc = validacoes.codigo) itensped,
                         (SELECT b.codigo,
                                 SUM(b.vlmin) valor
                            FROM pcbrindeexvalidacoes b
                           WHERE codbrex = campanhas.codbrex
                             AND gruporegra = validacoes.gruporegra
                          GROUP BY b.codigo) itensregras
                   WHERE
                   itensped.codigo = itensregras.codigo;*/

                    SELECT SUM((venda.valor - decode(NVL(campanhas.abaterdev,'N'),
                                                 'N',
                                                 0,
                                                 NVL(dev.valor,0)))) valor
                      INTO vn_basemultiplo
                      FROM (SELECT pr.codprodprinc,
                                   decode(validacoes.tipovalor,
                                          'VL',
                                            DECODE (validacoes.precosemimposto,
                                            'S',
                                            SUM(p.qt * (p.pvenda - nvl(p.st,0) - nvl(p.vlipi,0))),
                                            SUM(p.qt * p.pvenda)
                                            ),
                                          'QT',
                                          SUM(p.qt * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                          'PE',
                                          SUM(p.qt * pr.pesoliq),
                                          'MX',
                                          COUNT(DISTINCT p.codprod)) valor
                              FROM pcpedi p, VW_ALIENACAO_FORNEC pr
                             WHERE pr.codprod = p.codprod
                               AND nvl(p.brinde, 'N') <> 'S'
                               AND nvl(p.bonific, 'N') = 'N'
                               AND p.numped IN (SELECT numped
                                                  FROM pcpedc
                                                 WHERE codcli = G_CODCLI
                                                   AND posicao <> 'C'
                                                   AND dtcancel IS NULL
                                                   AND numped > G_NUMPED_GZERO
                                                   --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                   --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                   AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                               AND ((v_AplicBrindCampanhaComDesc = 'S') OR
                                    ((v_AplicBrindCampanhaComDesc = 'N') AND (NVL(p.perdesc, 0) = 0)))
                             GROUP BY pr.codprodprinc) venda,
                           (SELECT m.codprodprinc,
                                   decode(validacoes.tipovalor,
                                          'VL',
                                            DECODE (validacoes.precosemimposto,
                                            'S',
                                            SUM(m.qtcont * (m.punitcont - nvl(m.st,0) - nvl(m.vlipi,0))),
                                            SUM(m.qtcont * m.punitcont)
                                            ),
                                          'QT',
                                          SUM(m.qtcont * (decode(campanhas.usaalienacao, 'S', pr.fator, 1))),
                                          'PE',
                                          SUM(m.qt * m.pesoliq),
                                          'MX',
                                          COUNT(DISTINCT m.codprod)) valor
                              FROM pcmov m, VW_ALIENACAO_FORNEC pr
                             WHERE pr.codprod = m.codprod
                               AND m.numped IN (SELECT c.numped
                                                  FROM pcpedc c, pcpedi i
                                                 WHERE i.numped = c.numped
                                                   AND nvl(i.brinde,'N') <> 'S'
                                                   AND nvl(i.bonific, 'N') = 'N'
                                                   AND c.codcli = G_CODCLI
                                                   AND c.posicao <> 'C'
                                                   AND c.dtcancel IS NULL
                                                   AND c.numped > G_NUMPED_GZERO
                                                   --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                   --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                   AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                               AND m.dtcancel IS NULL
                               AND m.codoper = 'ED'
                            GROUP BY m.codprodprinc) dev
                    WHERE venda.codprodprinc = dev.codprodprinc(+);

                  END IF;

                END IF;

                IF vn_qtloops >= 1 THEN
                  IF NOT vt_tabelaapuracao.EXISTS(vn_qtloops + 1) AND
                     (vt_tabelaapuracao(vt_tabelaapuracao.LAST).codcamp IS NOT NULL) THEN
                    vn_qtloops := vt_tabelaapuracao.LAST + 1;
                    vt_tabelaapuracao.EXTEND;
                  END IF;
                ELSE
                  vn_qtloops := vn_qtloops + 1;
                  vt_tabelaapuracao.EXTEND;
                END IF;

                vr_tabelaapuracao.codcamp := campanhas.codbrex;
                vr_tabelaapuracao.gruporegra := validacoes.gruporegra;
                vr_tabelaapuracao.ok := 'S';
                vr_tabelaapuracao.numregra := C_Validacoes%ROWCOUNT;
/*                vr_tabelaapuracao.multiplo := trunc(vn_basemultiplo /
                                                                GREATEST(nvl(validacoes.vlmin,
                                                                    1)),1);*/

                vr_tabelaapuracao.multiplo := trunc(vn_basemultiplo /
                                                                    (CASE WHEN nvl(validacoes.vlmin,1) = 0 THEN
                                                                      1
                                                                    ELSE
                                                                      nvl(validacoes.vlmin,1)
                                                                    END));


                vt_tabelaapuracao(vn_qtloops) := vr_tabelaapuracao;

              ELSIF (validacoes.gruporegra = 0) AND (pn_numped > 0)  THEN
                EXIT loop_Validacao;

              END IF;
              --Fim 1.2.5.10
            
            --1.2.5.11 - Validar tipo "MX" - Mix Total
            WHEN 'MX' THEN

              IF campanhas.acumulativa <> 'S'
              THEN

                SELECT COUNT(*)
                  INTO vn_count
                  FROM (SELECT COUNT(DISTINCT p.codprod) valor
                          FROM pcpedi p
                         WHERE p.numped = pn_numped
                           AND nvl(p.BONIFIC, 'N') = 'N'
                           AND nvl(p.brinde, 'N') <> 'S') itensped
                 WHERE valor BETWEEN NVL(validacoes.vlmin*vn_qtacumuladavenda, 0) AND NVL(validacoes.vlmax, 999999999999);
              ELSE

                -- 1166.015770.2018 - Ajustado para melhorar a performance do select
                DECLARE
                  vnPEDTV5qtbrindescontemplados number;
                  vnDEVTV5qtbrindesdevolvidos   number;
                BEGIN
                  SELECT --COUNT(*) qtbrindescontemplados
                        NVL(SUM(I.QT),0) qtbrindescontemplados
                   INTO vnPEDTV5qtbrindescontemplados
                     FROM pcpedi i, pcpedc c
                    WHERE i.numped = c.numped
                      AND NVL(i.brinde,'N') = 'S'
                      AND i.codigobrinde = campanhas.codbrex
                      AND c.numped > G_NUMPED_GZERO
                      AND c.posicao <> 'C'
                      AND c.dtcancel IS NULL
                      AND c.codcli = G_CODCLI
                      --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                      --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                      AND i.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim;

                  SELECT --COUNT(*) qtbrindesdevolvidos
                        NVL(SUM(m.QT),0) qtbrindesdevolvidos
                   INTO vnDEVTV5qtbrindesdevolvidos
                     FROM pcmov m
                    WHERE (m.numped, m.codprod) IN (SELECT c.numped, i.codprod
                                                      FROM pcpedc c, pcpedi i
                                                     WHERE i.numped = c.numped
                                                       AND NVL(i.brinde,'N') = 'S'
                                                       AND i.codigobrinde = campanhas.codbrex
                                                       AND i.codprod = m.codprod
                                                       AND c.codcli = G_CODCLI
                                                       AND c.posicao <> 'C'
                                                       AND c.dtcancel IS NULL
                                                       AND c.numped > G_NUMPED_GZERO
                                                       AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                      --AND m.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = campanhas.codbrex AND gruporegra = validacoes.gruporegra)
                      AND m.dtcancel IS NULL
                      AND m.codoper = 'ED';

                    vn_qtbrindescontemplados := vnPEDTV5qtbrindescontemplados - vnDEVTV5qtbrindesdevolvidos;
                END;

                vn_count := 0; --REAPROVEITANDO VARIÁVEL
                SELECT SUM(QT)
                  INTO vn_count --REAPROVEITANDO VARIÁVEL
                  FROM PCBRINDEEXPREMIO
                 WHERE CODBREX = CAMPANHAS.CODBREX
                   AND GRUPOREGRA = VALIDACOES.GRUPOREGRA;

                IF NVL(vn_count,0) > 0 THEN
                  vn_qtbrindescontemplados := TRUNC(vn_qtbrindescontemplados / vn_count);
                END IF;

                BEGIN
                  SELECT decode(qtmaxmultiplo, 0, 999999999999, MAX(qtmaxmultiplo))
                    INTO vn_maxmultiplo
                    FROM pcbrindeexpremio
                   WHERE codbrex = campanhas.codbrex
                     AND gruporegra = validacoes.gruporegra
                GROUP BY qtmaxmultiplo;
                EXCEPTION
                  WHEN OTHERS THEN
                    vn_maxmultiplo := 999999999999;
                END;

                IF (vn_qtbrindescontemplados < vn_maxmultiplo)
                AND (vn_maxmultiplo > 0)
                THEN
                  SELECT COUNT(*)
                    INTO vn_count
                    FROM (SELECT (venda.valor - decode(NVL(campanhas.abaterdev,'N'),
                                                       'N',
                                                       0,
                                                       NVL(dev.valor,0))) valor
                            FROM (SELECT COUNT(DISTINCT p.codprod) valor
                                    FROM pcpedi p
                                   WHERE p.numped IN (SELECT numped
                                                        FROM pcpedc
                                                       WHERE codcli = G_CODCLI
                                                         AND posicao <> 'C'
                                                         AND dtcancel IS NULL
                                                         AND numped > G_NUMPED_GZERO
                                                         --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                         --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                         AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                                     AND nvl(p.bonific, 'N') = 'N'
                                     AND nvl(p.brinde, 'N') <> 'S') venda,
                                 (SELECT COUNT(DISTINCT m.codprod) valor
                                    FROM pcmov m
                                   WHERE m.numped IN (SELECT c.numped
                                                        FROM pcpedc c, pcpedi i
                                                       WHERE i.numped = c.numped
                                                         AND nvl(i.bonific, 'N') = 'N'
                                                         AND nvl(i.brinde,'N') <> 'S'
                                                         AND c.codcli = G_CODCLI
                                                         AND c.posicao <> 'C'
                                                         AND c.dtcancel IS NULL
                                                         AND c.numped > G_NUMPED_GZERO
                                                         --AND TO_DATE(TO_CHAR(data || ' ' || hora || ':' || minuto),'DD-MON-RRRR HH24:MI') >
                                                         --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                                                         AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                                     AND m.dtcancel IS NULL
                                     AND m.codoper = 'ED') dev) itensped,
                         (SELECT SUM(b.vlmin) valor
                            FROM pcbrindeexvalidacoes b
                           WHERE b.codbrex = campanhas.codbrex
                             AND b.tipo = validacoes.tipo
                             AND b.gruporegra = validacoes.gruporegra) itensregras
                   WHERE decode(vn_qtbrindescontemplados,
                                0,
                                itensped.valor,
                                (itensped.valor - (itensregras.valor * vn_qtbrindescontemplados)))
                         --BETWEEN NVL(validacoes.vlmin, 0) AND NVL(validacoes.vlmax, 999999999999); Tarefa: 213115
                         -->= NVL(validacoes.vlmin, 0);
                         >= CASE
                              WHEN vn_qtbrindescontemplados > 0 THEN
                                NVL(validacoes.vlmin, 0)
                              ELSE
                                (NVL(validacoes.vlmin, 0) * vn_qtacumuladavenda)
                            END;
                ELSE
                  vn_count := 0;
                END IF;

              END IF;

              IF vn_count > 0 THEN

                IF campanhas.acumulativa <> 'S'
                THEN

                  SELECT COUNT(DISTINCT p.codprod) valor
                    INTO vn_basemultiplo
                    FROM pcpedi p, pcprodut pr
                   WHERE pr.codprod = p.codprod
                     AND nvl(p.bonific, 'N') = 'N'
                     AND nvl(p.brinde, 'N') <> 'S'
                     AND p.numped = pn_numped;
                ELSE
                  IF (vn_qtbrindescontemplados < vn_maxmultiplo)
                  AND (vn_maxmultiplo > 0)
                  THEN

                    SELECT (venda.valor - decode(NVL(campanhas.abaterdev,'N'),
                                                 'N',
                                                 0,
                                                 NVL(dev.valor,0))) valor
                      INTO vn_basemultiplo
                      FROM (SELECT COUNT(DISTINCT p.codprod) valor
                              FROM pcpedi p
                             WHERE p.numped IN (SELECT numped
                                                  FROM pcpedc
                                                 WHERE codcli = G_CODCLI
                                                   AND posicao <> 'C'
                                                   AND dtcancel IS NULL
                                                   AND numped > G_NUMPED_GZERO
                                                   AND data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                               AND nvl(p.bonific, 'N') = 'N'
                               AND nvl(p.brinde, 'N') <> 'S') venda,
                           (SELECT COUNT(DISTINCT m.codprod) valor
                              FROM pcmov m
                             WHERE m.numped IN (SELECT c.numped
                                                  FROM pcpedc c, pcpedi i
                                                 WHERE i.numped = c.numped
                                                   AND nvl(i.bonific, 'N') = 'N'
                                                   AND nvl(i.brinde,'N') <> 'S'
                                                   AND c.codcli = G_CODCLI
                                                   AND c.posicao <> 'C'
                                                   AND c.dtcancel IS NULL
                                                   AND c.numped > G_NUMPED_GZERO
                                                   AND c.data BETWEEN G_DTBASEACUMUL AND campanhas.dtfim)
                               AND m.dtcancel IS NULL
                               AND m.codoper = 'ED') dev;
                  END IF;

                END IF;

                IF vn_qtloops >= 1 THEN
                  IF NOT vt_tabelaapuracao.EXISTS(vn_qtloops + 1) AND
                     (vt_tabelaapuracao(vt_tabelaapuracao.LAST).codcamp IS NOT NULL) THEN
                    vn_qtloops := vt_tabelaapuracao.LAST + 1;
                    vt_tabelaapuracao.EXTEND;
                  END IF;
                ELSE
                  vn_qtloops := vn_qtloops + 1;
                  vt_tabelaapuracao.EXTEND;
                END IF;

                vr_tabelaapuracao.codcamp := campanhas.codbrex;
                vr_tabelaapuracao.gruporegra := validacoes.gruporegra;
                vr_tabelaapuracao.ok := 'S';
                vr_tabelaapuracao.numregra := C_Validacoes%ROWCOUNT;

                vr_tabelaapuracao.multiplo := trunc(vn_basemultiplo /
                                                                    (CASE WHEN nvl(validacoes.vlmin,1) = 0 THEN
                                                                      1
                                                                    ELSE
                                                                      nvl(validacoes.vlmin,1)
                                                                    END));


                vt_tabelaapuracao(vn_qtloops) := vr_tabelaapuracao;

              ELSIF (validacoes.gruporegra = 0) AND (pn_numped > 0)  THEN
                EXIT loop_Validacao;

              END IF;
              --Fim 1.2.5.11  
              
            ELSE
              EXIT;

          END CASE;

          FETCH C_Validacoes
            INTO validacoes;
          IF nvl(validacoes.vlmax, 0) = 0 THEN
            validacoes.vlmax := 999999999999;
          END IF;
        END LOOP;
        --Fim 1.2.5

        vn_grupook := 0;
        /*Tarefa: 189550
        --1.2.6 - Passando tabela de apuração a limpo.
        IF vt_tabelaapuracao.COUNT > 0 THEN

          FOR i IN 1 .. vt_tabelaapuracao.LAST LOOP

            buscar_qtregrasatender(campanhas.codbrex,
                                   validacoes.gruporegra,
                                   vn_qtregrasatender,
                                   vn_grupook);

            IF vn_grupook < vn_qtregrasatender
            THEN

              FOR N IN 1 .. vt_tabelaapuracao.LAST LOOP
                IF vt_tabelaapuracao(N).codcamp = campanhas.codbrex
                  AND vt_tabelaapuracao(N).gruporegra = validacoes.gruporegra
                THEN
                  vt_tabelaapuracao(N).codcamp := NULL;
                  vt_tabelaapuracao(N).gruporegra := NULL;
                  vt_tabelaapuracao(N).ok := NULL;
                  vt_tabelaapuracao(N).numregra := NULL;
                  vt_tabelaapuracao(N).multiplo := NULL;
                END IF;

              END LOOP;

            END IF;

          END LOOP;

        END IF;
        --Fim 1.2.6
        */

        --1.3 - Finalizando bloco de apuração das campanhas ativas.
        IF (regras.qt = vn_grupook OR
           (nvl(regras.qtminregrasatender, 0) > 0 AND
           nvl(regras.qtminregrasatender, 9999) <= vn_grupook)) AND
           regras.gruporegra <> 0 THEN
          msg := 'Apuração de brindes realizada com sucesso!';
          CLOSE C_Validacoes;
          EXIT loop_Validacao;

        END IF;
        --Fim 1.3
        CLOSE C_Validacoes;
        FETCH C_Regras
          INTO regras;

      END LOOP;

      --Tarefa: 191073
      <<FIM_LOOP_CAMPANHAS>>
      IF C_Restricoes%ISOPEN THEN
        CLOSE C_Restricoes;
      END IF;

      IF C_Regras%ISOPEN THEN
        CLOSE C_Regras;
      END IF;
      --Fim Tarefa: 191073

      IF C_Validacoes%ISOPEN THEN
        CLOSE C_Validacoes;
      END IF;

      FETCH C_Campanhas_Ativas
        INTO campanhas;
    END LOOP;
    <<fim_loop_Principal>>
    CLOSE C_Campanhas_Ativas;

    --1.2.6 - Passando tabela de apuração a limpo.
    FOR VALID IN (SELECT V.CODBREX, V.GRUPOREGRA
                  FROM PCBRINDEEXVALIDACOES V, PCBRINDEEX B
                  WHERE
                  V.CODBREX = B.CODBREX
                  AND B.DTCANCEL IS NULL
                  AND vd_dataped BETWEEN b.dtinicio AND b.dtfim)
    LOOP

      IF vt_tabelaapuracao.COUNT > 0 THEN

        FOR i IN 1 .. vt_tabelaapuracao.LAST LOOP

          vn_grupook := 0;

          buscar_qtregrasatender(VALID.codbrex,
                                 VALID.gruporegra,
                                 vn_qtregrasatender,
                                 vn_grupook);

        IF pn_numped = 0 THEN
         vn_qtregrasatender := 1;
        END IF;

          IF vn_grupook < vn_qtregrasatender
          THEN

            FOR N IN 1 .. vt_tabelaapuracao.LAST LOOP
              IF vt_tabelaapuracao(N).codcamp = VALID.codbrex
                AND vt_tabelaapuracao(N).gruporegra = VALID.gruporegra
              THEN

                vr_tabelaapuracao.codcamp := NULL;
                vr_tabelaapuracao.gruporegra := NULL;
                vr_tabelaapuracao.ok := NULL;
                vr_tabelaapuracao.numregra := NULL;
                vr_tabelaapuracao.multiplo := NULL;

                vt_tabelaapuracao(N) := vr_tabelaapuracao;
              END IF;

            END LOOP;

          END IF;

        END LOOP;

      END IF;

    END LOOP;

    IF vt_tabelaapuracao.COUNT > 0 THEN

      FOR i IN 1 .. vt_tabelaapuracao.last LOOP

        IF vt_tabelaapuracao(i).codcamp IS NOT NULL THEN
          vt_tabelaapuracaofinal.extend;
          vt_tabelaapuracaofinal(vt_tabelaapuracaofinal.last) := vt_tabelaapuracao(i);
        END IF;

      END LOOP;

    END IF;
    --Fim 1.2.6

    apuracao := vt_tabelaapuracaofinal;

  END P_VALIDARPEDIDO;



  FUNCTION REL_BRINDES(pn_codcli IN NUMBER,
                       ps_origemped IN VARCHAR2,
                       ps_codfilial IN VARCHAR2,
                       pn_codemitente IN NUMBER,
                       pn_codusur IN NUMBER,
                       pn_codplpag IN NUMBER,
                       pd_data IN DATE,
                       pn_numregiao IN NUMBER,
                       pn_codprod IN NUMBER,
                       pn_numped IN NUMBER default 0,
                       pn_numpedtv5 IN NUMBER default 0) RETURN T_RELBRINDES_DT
    PARALLEL_ENABLE PIPELINED
    IS

    VT_APURACAO  T_ApuraGrupoRegras := T_ApuraGrupoRegras();
    VT_PREMIOS   T_RELBRINDES_DT    := T_RELBRINDES_DT();
    DADOS_SAIDA  T_RELBRINDES_DR    := T_RELBRINDES_DR(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
    VS_CODFILIAL VARCHAR2(2);
    V_MSG        VARCHAR2(4000);
    VICONTADOR   NUMBER;
    VT_CRITICAS  TTvCriticasRestr;

  BEGIN

    --Tarefa: 199384
    BEGIN
      EXECUTE IMMEDIATE 'alter session set NLS_DATE_FORMAT="DD-MON-RRRR"';
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;

    --G_NUMPED := pn_numped;
    --P_VALIDARPEDIDO(pn_numped, VT_APURACAO, v_msg);
    P_VALIDARPEDIDO(pn_codcli,ps_origemped,ps_codfilial,pn_codemitente,pn_codusur,pn_codplpag,pd_data,pn_numregiao,pn_codprod,pn_numped,pn_numpedtv5, VT_APURACAO, v_msg, VT_CRITICAS);
    VS_CODFILIAL := ps_codfilial;

    /*SELECT CODFILIAL
      INTO VS_CODFILIAL
      FROM PCPEDC
     WHERE NUMPED = pn_numped;*/

    BEGIN
      IF NVL(VT_APURACAO(1).codcamp, 0) <> 0 THEN
        VICONTADOR := 1;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        VICONTADOR := 0;
    END;

    IF VICONTADOR > 0 THEN
      P_GERARPREMIO(VT_APURACAO, vs_codfilial, pn_numpedtv5, VT_PREMIOS);
    END IF;

    IF VT_PREMIOS.EXISTS(1) THEN
      FOR X IN 1 .. VT_PREMIOS.LAST LOOP

        DADOS_SAIDA.CODCAMP        := VT_PREMIOS(X).CODCAMP;
        DADOS_SAIDA.GRPREGRABRINDE := VT_PREMIOS(X).GRPREGRABRINDE;
        DADOS_SAIDA.GRPREGRACAMP   := VT_PREMIOS(X).GRPREGRACAMP;
        DADOS_SAIDA.CODBRINDE      := VT_PREMIOS(X).CODBRINDE;
        DADOS_SAIDA.DESCRICAO      := VT_PREMIOS(X).DESCRICAO;
        DADOS_SAIDA.EMBALAGEM      := VT_PREMIOS(X).EMBALAGEM;
        DADOS_SAIDA.QTDECAMP       := VT_PREMIOS(X).QTDECAMP;
        DADOS_SAIDA.QTDE           := VT_PREMIOS(X).QTDE;
        DADOS_SAIDA.ESTDISP        := VT_PREMIOS(X).ESTDISP;
        DADOS_SAIDA.SIMILAR        := VT_PREMIOS(X).SIMILAR;
        DADOS_SAIDA.usadebcredrca  := VT_PREMIOS(X).USADEBCREDRCA;
        DADOS_SAIDA.QTBRINDEDISP   := VT_PREMIOS(X).QTBRINDEDISP;
        PIPE ROW(DADOS_SAIDA);

      END LOOP;
    END IF;

   RETURN;

  END REL_BRINDES;

  FUNCTION REL_BRINDES(pn_numped NUMBER, pn_numpedtv5 NUMBER DEFAULT 0) RETURN T_RELBRINDES_DT
    PARALLEL_ENABLE PIPELINED
    IS
    vn_codcli          PCCLIENT.codcli%TYPE;
    vn_codfunclanc     pcpedc.codemitente%TYPE;
    vs_codfilial       pcpedc.codfilial%TYPE;
    vn_codrca          pcpedc.codusur%TYPE;
    vn_codplpag        pcpedc.codplpag%type;
    vs_origemped       pcpedc.origemped%TYPE;
    vs_clivalidabrinde pcclient.validarcampanhabrinde%TYPE;
    vd_dataped         pcpedc.data%type;
    vn_numregiao       pcpedc.numregiao%type;
    VT_APURACAO  T_ApuraGrupoRegras := T_ApuraGrupoRegras();
    VT_PREMIOS   T_RELBRINDES_DT := T_RELBRINDES_DT();
    DADOS_SAIDA  T_RELBRINDES_DR := T_RELBRINDES_DR(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
    V_MSG        VARCHAR2(4000);
    VICONTADOR   NUMBER;
    VT_CRITICAS  TTvCriticasRestr;
  BEGIN

    --Tarefa: 199384
    BEGIN
      EXECUTE IMMEDIATE 'alter session set NLS_DATE_FORMAT="DD-MON-RRRR"';
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;

    SELECT pcclient.codcli,
           pcpedc.origemped,
           pcpedc.codfilial,
           pcpedc.codemitente,
           pcpedc.codusur,
           pcpedc.codplpag,
           pcpedc.data,
           pcpedc.numregiao
      INTO vn_codcli,
           vs_origemped,
           vs_codfilial,
           vn_codfunclanc,
           vn_codrca,
           vn_codplpag,
           vd_dataped,
           vn_numregiao
      FROM pcpedc, pcclient
     WHERE pcpedc.codcli = pcclient.codcli
       AND pcpedc.numped = pn_numped;
--     REL_BRINDES(vn_codcli,vs_origemped,vs_codfilial,vn_codfunclanc,vn_codrca,vn_codplpag,vd_dataped,vn_numregiao,pn_numped,pn_numped);

    G_NUMPED := pn_numped;
    --P_VALIDARPEDIDO(pn_numped, VT_APURACAO, v_msg);
    P_VALIDARPEDIDO(vn_codcli,Vs_origemped,Vs_codfilial,vn_codfunclanc,vn_codrca,vn_codplpag,vd_dataped,vn_numregiao,0,pn_numped,pn_numpedtv5, VT_APURACAO, v_msg, VT_CRITICAS);

    /*SELECT CODFILIAL
      INTO VS_CODFILIAL
      FROM PCPEDC
     WHERE NUMPED = pn_numped;*/

    BEGIN
      IF NVL(VT_APURACAO(1).codcamp, 0) <> 0 THEN
        VICONTADOR := 1;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        VICONTADOR := 0;
    END;

    IF VICONTADOR > 0 THEN
      P_GERARPREMIO(VT_APURACAO, vs_codfilial, PN_NUMPEDTV5, VT_PREMIOS);
    END IF;

    IF VT_PREMIOS.EXISTS(1) THEN
      FOR X IN 1 .. VT_PREMIOS.LAST LOOP

        DADOS_SAIDA.CODCAMP        := VT_PREMIOS(X).CODCAMP;
        DADOS_SAIDA.GRPREGRABRINDE := VT_PREMIOS(X).GRPREGRABRINDE;
        DADOS_SAIDA.GRPREGRACAMP   := VT_PREMIOS(X).GRPREGRACAMP;
        DADOS_SAIDA.CODBRINDE      := VT_PREMIOS(X).CODBRINDE;
        DADOS_SAIDA.DESCRICAO      := VT_PREMIOS(X).DESCRICAO;
        DADOS_SAIDA.EMBALAGEM      := VT_PREMIOS(X).EMBALAGEM;
        DADOS_SAIDA.QTDECAMP       := VT_PREMIOS(X).QTDECAMP;
        DADOS_SAIDA.QTDE           := VT_PREMIOS(X).QTDE;
        DADOS_SAIDA.ESTDISP        := VT_PREMIOS(X).ESTDISP;
        DADOS_SAIDA.SIMILAR        := VT_PREMIOS(X).SIMILAR;
        DADOS_SAIDA.usadebcredrca  := VT_PREMIOS(X).USADEBCREDRCA;
        DADOS_SAIDA.QTBRINDEDISP   := VT_PREMIOS(X).QTBRINDEDISP;
        PIPE ROW(DADOS_SAIDA);

      END LOOP;
    END IF;

   RETURN;

  END REL_BRINDES;
  
  FUNCTION RESTRICOES_BRINDES(pn_numped NUMBER, pn_numpedtv5 NUMBER DEFAULT 0) RETURN T_RELBRINDES_DT
    PARALLEL_ENABLE PIPELINED
    IS
    vn_codcli          PCCLIENT.codcli%TYPE;
    vn_codfunclanc     pcpedc.codemitente%TYPE;
    vs_codfilial       pcpedc.codfilial%TYPE;
    vn_codrca          pcpedc.codusur%TYPE;
    vn_codplpag        pcpedc.codplpag%type;
    vs_origemped       pcpedc.origemped%TYPE;
    vs_clivalidabrinde pcclient.validarcampanhabrinde%TYPE;
    vd_dataped         pcpedc.data%type;
    vn_numregiao       pcpedc.numregiao%type;
    VT_APURACAO        T_ApuraGrupoRegras := T_ApuraGrupoRegras();
    VT_PREMIOS         T_RELBRINDES_DT := T_RELBRINDES_DT();
    DADOS_SAIDA        T_RELBRINDES_DR := T_RELBRINDES_DR(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
    V_MSG              VARCHAR2(4000);
    VICONTADOR         NUMBER;
    VT_CRITICAS        TTvCriticasRestr;
  BEGIN

    BEGIN
      EXECUTE IMMEDIATE 'alter session set NLS_DATE_FORMAT="DD-MON-RRRR"';
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;

    SELECT pcclient.codcli,
           pcpedc.origemped,
           pcpedc.codfilial,
           pcpedc.codemitente,
           pcpedc.codusur,
           pcpedc.codplpag,
           pcpedc.data,
           pcpedc.numregiao
      INTO vn_codcli,
           vs_origemped,
           vs_codfilial,
           vn_codfunclanc,
           vn_codrca,
           vn_codplpag,
           vd_dataped,
           vn_numregiao
      FROM pcpedc, pcclient
     WHERE pcpedc.codcli = pcclient.codcli
       AND pcpedc.numped = pn_numped;

    G_NUMPED := pn_numped;
    P_VALIDARPEDIDO(vn_codcli,Vs_origemped,Vs_codfilial,vn_codfunclanc,vn_codrca,vn_codplpag,vd_dataped,vn_numregiao,0,pn_numped,pn_numpedtv5, VT_APURACAO, v_msg, VT_CRITICAS);

    IF VT_CRITICAS.COUNT > 0 THEN
      FOR X IN VT_CRITICAS.FIRST .. VT_CRITICAS.LAST LOOP

        DADOS_SAIDA.CODCAMP        := VT_CRITICAS(X).vnCodCampanha;
        DADOS_SAIDA.GRPREGRACAMP   := VT_CRITICAS(X).vnCodGrupo;
        DADOS_SAIDA.DESCRICAO      := SUBSTR(VT_CRITICAS(X).vvCritica, 1, 50);
        PIPE ROW(DADOS_SAIDA);

      END LOOP;
    END IF;

   RETURN;

  END RESTRICOES_BRINDES;  

  PROCEDURE P_GERARPREMIO(PDADOS         IN T_ApuraGrupoRegras,
                          PFILIALESTOQUE IN VARCHAR2,
                          PN_NUMPEDTV5   IN NUMBER,
                          PRESULT        OUT T_RELBRINDES_DT) IS

    CURSOR C_PREMIOS(P_CODBREX    NUMBER,
                     P_GR         NUMBER,
                     PN_NUMPEDTV5 NUMBER,
                     P_LISTA      VARCHAR2) IS
      SELECT   PCBRINDEEXPREMIO.CODBREX
              ,PCBRINDEEXPREMIO.CODPROD
              ,PCBRINDEEXPREMIO.QT
              ,PCBRINDEEXPREMIO.GRUPOREGRA
              ,PCBRINDEEXPREMIO.QTMAXBRINDES
              ,PCBRINDEEXPREMIO.QTBRINDESDISP
              ,PCBRINDEEXPREMIO.ACEITAMULTIPLO
              ,PCBRINDEEXPREMIO.QTMAXMULTIPLO
              ,PCBRINDEEXPREMIO.SUBSTBRINDEPORSIMILAR
              ,PCBRINDEEXPREMIO.Qtmaxbrindescli
              ,PCBRINDEEXPREMIO.Qtmaxbrindessuperv
              ,PCBRINDEEXPREMIO.QTMAXBRINDESRCA
              ,PCBRINDEEXPREMIO.CODFILIALEMB
              ,PCBRINDEEXPREMIO.CODAUXILIAR
        FROM PCBRINDEEXPREMIO
       WHERE CODBREX = P_CODBREX
         AND (((SELECT NVL(PCBRINDEEX.ACUMULATIVA,'N') FROM PCBRINDEEX WHERE CODBREX = PCBRINDEEXPREMIO.CODBREX AND ROWNUM = 1) = 'S'
          AND GRUPOREGRA NOT IN (SELECT ITEM FROM TABLE(FERRAMENTAS.F_RETORNARLISTA(P_LISTA,',')) WHERE ITEM IS NOT NULL)
          AND P_LISTA IS NOT NULL
          AND GRUPOREGRA IN (P_GR))
         OR (GRUPOREGRA IN (0,P_GR)
          AND P_LISTA IS NULL))
      UNION
      SELECT P_CODBREX
            ,I.CODPROD
            ,CASE
              WHEN B.ACEITAMULTIPLO = 'S' THEN TRUNC(B.VALOR/I.PTABELA)
              ELSE 1
             END AS QT
            ,B.GRUPOREGRA
            ,0 AS QTMAXBRINDES
            ,0 AS QTBRINDESDISP
            ,B.ACEITAMULTIPLO
            ,0 AS QTMAXMULTIPLO
            ,'N' SUBSTBRINDEPORSIMILAR
            ,0 AS QTMAXBRINDEDESCLI
            ,0 AS QTMAXBRINDEDESSUPERV
            ,0 AS QTMAXBRINDESRCA
            ,'' AS CODFILIALEMB
            ,0 AS CODAUXILIAR
        FROM PCPEDI I INNER JOIN PCPRODUT P
                              ON P.CODPROD = I.CODPROD
                      INNER JOIN PCBRINDEXPREMIOGENERICO B
                              ON B.CODBREX = P_CODBREX
                             AND B.GRUPOREGRA = P_GR
                             AND ((B.TIPO = 'F' AND P.CODFORNEC       = B.CODIGO) OR -- FORNECEDOR
                                  (B.TIPO = 'S' AND P.CODSEC          = B.CODIGO) OR -- SEÇAO
                                  (B.TIPO = 'B' AND P.CODSUBCATEGORIA = B.CODIGO) OR -- SUBCATEGORIA
                                  (B.TIPO = 'D' AND P.CODEPTO         = B.CODIGO) OR -- DEPARTAMENTO
                                  (B.TIPO = 'C' AND P.CODCATEGORIA    = B.CODIGO))   -- CATEGORIA
       WHERE I.NUMPED = PN_NUMPEDTV5;

    TYPE T_CAMPANHAS IS RECORD
    (CODCAMP         PCBRINDEEX.CODBREX%TYPE,
     QTGRUPOS_ATEND  NUMBER,
     ACUMULATIVA     PCBRINDEEX.ACUMULATIVA%TYPE,
     PULAR           BOOLEAN);

    TYPE TB_CAMPANHAS IS TABLE OF T_CAMPANHAS;

    VC_PREMIOS          C_PREMIOS%ROWTYPE;
    VN_CAMP             NUMBER;
    VN_GRPREGRA         NUMBER;
    VN_REG              NUMBER;
    VN_QTGRUPOS         NUMBER;
    VN_QTGRUPOS_TEMP    NUMBER;
    VN_QTGRPZERO        NUMBER;
    VN_MAXQTMULT        NUMBER;
    VN_QTDISP           NUMBER;
    VN_MULT             NUMBER;
    VN_COUNTSIMIL       NUMBER;
    VN_QTCAMPDISP       NUMBER;
    VN_QTMAX            NUMBER;
    VN_QTCAMPDISPIT     NUMBER;
    VN_QTCAMPDISPCLI    NUMBER;
    VN_QTCAMPDISPITCLI  NUMBER;
    VN_QTMAXCLI         NUMBER;
    VN_QTMAXIT          NUMBER;
    VN_QTMAXITCLI       NUMBER;
    VN_QTPREMIOS        NUMBER;
    VN_QTCAMPGERAL      NUMBER;
    VN_QTCAMPGERALCLI   NUMBER;
    VN_QTBRINDEGERAL    NUMBER;
    VN_QTBRINDEGERALCLI NUMBER;
    VN_BRINDESCONTEMPLADOS NUMBER;
    VS_ACUMULATIVA      PCBRINDEEX.ACUMULATIVA%TYPE;
    VB_PULOUBRINDE      BOOLEAN := FALSE;
    VN_BRINDEGRPZERO    NUMBER;
    VD_DTINI            DATE;
    VD_DTFIM            DATE;
    vlLISTA             VARCHAR2(4000);
    VN_QTACUMULADAVENDA NUMBER;
    --HIS.02193.2015
    VN_QTMAXITSUPERV       NUMBER;
    VN_QTMAXITRCA          NUMBER;
    VN_QTCAMPDISPITSUPERV  NUMBER;
    VN_QTCAMPDISPITRCA     NUMBER;
    VN_QTBRINDEGERALSUPERV NUMBER;
    VN_QTBRINDEGERALRCA    NUMBER;
    VN_QTBRINDEPRODUT      NUMBER;
    VS_CODFILIALRETIRA     PCFILIAL.CODIGO%TYPE;
    vnFator                number;

    VR_RESULT T_RELBRINDES_DR := T_RELBRINDES_DR(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
    VT_RESULT T_RELBRINDES_DT := T_RELBRINDES_DT();

    VR_CAMPANHAS T_CAMPANHAS;
    VT_CAMPANHAS TB_CAMPANHAS := TB_CAMPANHAS();

    PROCEDURE buscarmenormultiplo(pcodcamp    IN NUMBER,
                                  pgruporegra IN NUMBER,
                                  pmenormult  OUT NUMBER) AS
    BEGIN
      pmenormult := 999999;

      FOR X IN 1 .. PDADOS.LAST LOOP
        IF PDADOS(X).CODCAMP    = pcodcamp AND
           PDADOS(X).GRUPOREGRA = pgruporegra THEN
          IF pmenormult > NVL(PDADOS(X).MULTIPLO,0) THEN
            pmenormult := NVL(PDADOS(X).MULTIPLO,0);
          END IF;
        END IF;
      END LOOP;

    END buscarmenormultiplo;

    PROCEDURE verbrindegrpzero(pcodcamp   IN NUMBER)
    AS
    TYPE listagrp IS VARRAY(1000) OF NUMBER(6);

    vn_qtgruposcamp         NUMBER;
    vn_qtgruposcontemplados NUMBER;
    vd_dtfim                DATE;
    vs_proddesc             PCPRODUT.DESCRICAO%TYPE;
    vs_prodemb              PCPRODUT.EMBALAGEM%TYPE;
    vlistagrp               listagrp := listagrp(NULL);
    vn_x                    NUMBER;

    BEGIN

      SELECT dtfim
        INTO vd_dtfim
        FROM pcbrindeex
       WHERE codbrex = pcodcamp;

      SELECT COUNT(DISTINCT gruporegra)
        INTO vn_qtgruposcamp
        FROM pcbrindeexpremio
       WHERE codbrex = pcodcamp
         AND gruporegra <> 0;

      vn_x := 1;
      FOR grpcontemp IN (SELECT DISTINCT i.grpregrabrinde
                           FROM pcpedi i, pcpedc c
                          WHERE i.numped = c.numped
                            AND c.data BETWEEN G_DTBASEACUMUL AND vd_dtfim
                            AND c.codcli = G_CODCLI
                            AND c.dtcancel IS NULL
                            AND c.posicao <> 'C'
                            AND c.numped > G_NUMPED_GZERO
                            --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                            --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                            AND i.grpregrabrinde <> 0)
      LOOP
        vlistagrp(vn_x) := grpcontemp.grpregrabrinde;
        vn_x := vn_x + 1;
        vlistagrp.EXTEND;
      END LOOP;

      FOR N IN 1..VT_RESULT.LAST
      LOOP
        vn_x := 0;
        FOR I IN 1..vlistagrp.LAST
        LOOP
          IF vlistagrp(I) = VT_RESULT(N).grpregracamp
          THEN
            vn_x := 1;
          END IF;

        END LOOP;

        IF vn_x = 0
        THEN
          vlistagrp.EXTEND;
          vlistagrp(vlistagrp.LAST) := VT_RESULT(N).grpregracamp;
        END IF;

      END LOOP;

      FOR L IN 1..vlistagrp.LAST
      LOOP
        IF vlistagrp(L) IS NOT NULL
        THEN
          vn_qtgruposcontemplados := vn_qtgruposcontemplados + 1;
        END IF;
      END LOOP;

      IF vn_qtgruposcontemplados = vn_qtgruposcamp
      THEN
        FOR brindes IN (SELECT codbrex,
                               gruporegra,
                               codprod,
                               qt,
                               qtmaxmultiplo,
                               codauxiliar,
                               codfilialemb
                          FROM pcbrindeexpremio
                         WHERE codbrex = pcodcamp
                           AND gruporegra = 0)
        LOOP

          SELECT pcprodut.descricao, NVL(pcembalagem.Embalagem,pcprodut.embalagem)
            INTO vs_proddesc, vs_prodemb
            FROM pcprodut,pcembalagem
           WHERE pcprodut.codprod = brindes.codprod
           and pcprodut.codprod = pcembalagem.codprod
           and pcembalagem.codauxiliar = brindes.codauxiliar(+)
           and pcembalagem.codfilial = brindes.codfilialemb(+);

          VT_RESULT.EXTEND;

          VR_RESULT.codcamp        := brindes.codbrex;
          VR_RESULT.grpregrabrinde := brindes.gruporegra;
          VR_RESULT.grpregracamp   := brindes.gruporegra;
          VR_RESULT.codbrinde      := brindes.codprod;
          VR_RESULT.descricao      := vs_proddesc;
          VR_RESULT.embalagem      := vs_prodemb;
          VR_RESULT.qtdecamp       := brindes.qt;
          VR_RESULT.qtde           := brindes.qt;
          VR_RESULT.estdisp        := 'S';
          VR_RESULT.similar        := 'N';
          VR_RESULT.usadebcredrca  := 'N';
          VR_RESULT.qtbrindedisp   := NULL;

          VT_RESULT(VT_RESULT.LAST) := VR_RESULT;

        END LOOP;

      END IF;

    END verbrindegrpzero;

  BEGIN

    VN_REG      := 1;
    VN_CAMP     := 0;
    VN_GRPREGRA := 9999;

    IF PDADOS.COUNT > 0 THEN
      --POPULANDO "VT_CAMPANHAS" COM DADOS DO PEDIDO ATUAL
      vlLISTA := NULL;
      FOR X IN 1..PDADOS.LAST
        LOOP
          IF PDADOS.EXISTS(X) THEN

            IF (VN_CAMP <> PDADOS(X).CODCAMP)
              AND (VN_GRPREGRA <> PDADOS(X).GRUPOREGRA)
            THEN

              VT_CAMPANHAS.EXTEND;
              VN_REG := VT_CAMPANHAS.COUNT;

              IF (VN_CAMP <> PDADOS(X).CODCAMP) THEN
                VN_CAMP := PDADOS(X).CODCAMP;
              END IF;

              IF (VN_GRPREGRA <> PDADOS(X).GRUPOREGRA) THEN

                VN_GRPREGRA := PDADOS(X).GRUPOREGRA;

                VR_CAMPANHAS.CODCAMP := VN_CAMP;
                VR_CAMPANHAS.QTGRUPOS_ATEND := NVL(VR_CAMPANHAS.QTGRUPOS_ATEND,0) + 1;
                vlLISTA := vlLISTA || TO_CHAR(PDADOS(X).GRUPOREGRA) || ',';

                SELECT NVL(ACUMULATIVA,'N')
                  INTO VR_CAMPANHAS.ACUMULATIVA
                  FROM PCBRINDEEX
                 WHERE CODBREX = PDADOS(X).CODCAMP;

                VT_CAMPANHAS(VN_REG) := VR_CAMPANHAS;

              ELSIF (VR_CAMPANHAS.CODCAMP = VN_CAMP)
                AND (VN_GRPREGRA <> PDADOS(X).GRUPOREGRA)
              THEN

                VN_GRPREGRA := PDADOS(X).GRUPOREGRA;

                VR_CAMPANHAS.CODCAMP        := VN_CAMP;
                VR_CAMPANHAS.QTGRUPOS_ATEND := NVL(VR_CAMPANHAS.QTGRUPOS_ATEND,0) + 1;
                vlLISTA := vlLISTA || TO_CHAR(PDADOS(X).GRUPOREGRA) || ',';

                SELECT NVL(ACUMULATIVA,'N')
                  INTO VR_CAMPANHAS.ACUMULATIVA
                  FROM PCBRINDEEX
                 WHERE CODBREX = PDADOS(X).CODCAMP;

                VT_CAMPANHAS(VN_REG) := VR_CAMPANHAS;

              ELSE

                VN_GRPREGRA := PDADOS(X).GRUPOREGRA;

                VT_CAMPANHAS.EXTEND;

                VN_REG := VT_CAMPANHAS.COUNT;

                VR_CAMPANHAS.CODCAMP        := VN_CAMP;
                VR_CAMPANHAS.QTGRUPOS_ATEND := NVL(VR_CAMPANHAS.QTGRUPOS_ATEND,0) + 1;
                vlLISTA := vlLISTA || TO_CHAR(PDADOS(X).GRUPOREGRA) || ',';

                SELECT NVL(ACUMULATIVA,'N')
                  INTO VR_CAMPANHAS.ACUMULATIVA
                  FROM PCBRINDEEX
                 WHERE CODBREX = PDADOS(X).CODCAMP;

                VT_CAMPANHAS(VN_REG) := VR_CAMPANHAS;

              END IF;

            ELSIF (VN_GRPREGRA <> PDADOS(X).GRUPOREGRA) THEN

              VT_CAMPANHAS(VN_REG).QTGRUPOS_ATEND := NVL(VT_CAMPANHAS(VN_REG).QTGRUPOS_ATEND,0) + 1;
              vlLISTA := vlLISTA || TO_CHAR(PDADOS(X).GRUPOREGRA) || ',';
              VN_GRPREGRA := PDADOS(X).GRUPOREGRA;

            END IF;

          END IF;
        END LOOP;
    END IF;


    IF VT_CAMPANHAS.COUNT > 0 THEN
      --CASO SEJA CAMPANHA ACUMULATIVA DEVE COMPLEMENTAR "VT_CAMPANHAS" COM OS BRINDES JÁ CONTEMPLADOS
      FOR W IN 1..VT_CAMPANHAS.LAST
        LOOP

          IF VT_CAMPANHAS(W).ACUMULATIVA = 'S' THEN

            P_ATUALIZAR_DTBASE(VT_CAMPANHAS(W).CODCAMP);

            SELECT COUNT(DISTINCT I.GRPREGRABRINDE)
              INTO VN_QTGRUPOS_TEMP
              FROM PCPEDI I, PCPEDC C
             WHERE C.NUMPED = I.NUMPED
               AND NVL(I.GRPREGRABRINDE,0) <> 0
               AND NVL(I.GRPREGRABRINDE,0) NOT IN (SELECT ITEM FROM TABLE(FERRAMENTAS.F_RETORNARLISTA(vlLISTA,',')) WHERE ITEM IS NOT NULL)
               AND C.DTCANCEL IS NULL
               AND C.CODCLI = G_CODCLI
               AND C.POSICAO <> 'C'
               AND I.CODIGOBRINDE = VT_CAMPANHAS(W).CODCAMP
               AND c.numped > G_NUMPED_GZERO;
               --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
               --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI');

            VT_CAMPANHAS(W).QTGRUPOS_ATEND := VT_CAMPANHAS(W).QTGRUPOS_ATEND + NVL(VN_QTGRUPOS_TEMP,0);

            SELECT COUNT(I.GRPREGRABRINDE)
              INTO VN_QTGRPZERO
              FROM PCPEDI I, PCPEDC C
             WHERE C.NUMPED = I.NUMPED
               AND NVL(I.GRPREGRABRINDE,0) = 0
               AND C.DTCANCEL IS NULL
               AND C.POSICAO <> 'C'
               AND C.CODCLI = G_CODCLI
               AND I.CODIGOBRINDE = VT_CAMPANHAS(W).CODCAMP
               AND C.DATA >= (SELECT DTINICIO FROM PCBRINDEEX WHERE CODBREX = VT_CAMPANHAS(W).CODCAMP)
               AND C.DATA <= (SELECT DTFIM FROM PCBRINDEEX WHERE CODBREX = VT_CAMPANHAS(W).CODCAMP);

            BEGIN
              SELECT MAX(QTMAXMULTIPLO)
                INTO VN_MAXQTMULT
                FROM PCBRINDEEXPREMIO
               WHERE CODBREX = VT_CAMPANHAS(W).CODCAMP
                 AND GRUPOREGRA = 0;
            EXCEPTION
              WHEN OTHERS THEN
                VN_MAXQTMULT := 999999999999;
            END;

            IF VN_QTGRPZERO >= VN_MAXQTMULT THEN
              VT_CAMPANHAS(W).QTGRUPOS_ATEND := 0;
              VT_CAMPANHAS(W).PULAR := TRUE;
            ELSE
              VT_CAMPANHAS(W).PULAR := FALSE;
            END IF;

          END IF;

        END LOOP;
      END IF;

      IF VT_CAMPANHAS.COUNT > 0 THEN
        FOR P IN 1..VT_CAMPANHAS.LAST
        LOOP
          IF VT_CAMPANHAS(P).ACUMULATIVA = 'S' THEN

            SELECT COUNT(DISTINCT GRUPOREGRA)
              INTO VN_QTGRUPOS
              FROM PCBRINDEEXVALIDACOES
             WHERE CODBREX = VT_CAMPANHAS(P).CODCAMP;

            IF (VT_CAMPANHAS(P).QTGRUPOS_ATEND >= VN_QTGRUPOS) THEN

              FOR GRUPO_ZERO IN
              (SELECT CODPROD, QT,CODFILIALEMB,CODAUXILIAR
                 FROM PCBRINDEEXPREMIO
                WHERE CODBREX = VT_CAMPANHAS(P).CODCAMP
                  AND GRUPOREGRA = 0)
              LOOP
                SELECT pcprodut.descricao, NVL(pcembalagem.Embalagem,pcprodut.embalagem)
                    INTO VR_RESULT.descricao, VR_RESULT.embalagem
                    FROM pcprodut,pcembalagem
                   WHERE pcprodut.codprod = GRUPO_ZERO.codprod
                   and pcprodut.codprod = pcembalagem.codprod
                   and pcembalagem.codauxiliar = GRUPO_ZERO.codauxiliar(+)
                   and pcembalagem.codfilial = GRUPO_ZERO.codfilialemb(+);

                VT_RESULT.EXTEND;

                VR_RESULT.codcamp        := VT_CAMPANHAS(P).CODCAMP;
                VR_RESULT.grpregrabrinde := 0;
                VR_RESULT.grpregracamp   := 0;
                VR_RESULT.codbrinde      := GRUPO_ZERO.codprod;
                VR_RESULT.qtdecamp       := GRUPO_ZERO.qt;
                VR_RESULT.qtde           := GRUPO_ZERO.qt;
                VR_RESULT.estdisp        := 'S';
                VR_RESULT.similar        := 'N';
                VR_RESULT.usadebcredrca  := 'N';
                VR_RESULT.qtbrindedisp   := NULL;

                VT_RESULT(VT_RESULT.LAST) := VR_RESULT;

              END LOOP;
            END IF;
          END IF;
        END LOOP;
      END IF;

    VN_REG      := 1;
    VN_CAMP     := 0;
    VN_GRPREGRA := 9999;

    IF PDADOS.COUNT > 0 THEN
      FOR Y IN 1..PDADOS.LAST LOOP

        IF VT_CAMPANHAS.COUNT > 0 THEN
          FOR U IN 1..VT_CAMPANHAS.LAST
          LOOP
            IF (VT_CAMPANHAS(U).PULAR)
             AND (VT_CAMPANHAS(U).CODCAMP = PDADOS(Y).CODCAMP)
            THEN
              GOTO FIM_LOOP;
            END IF;
          END LOOP;
        END IF;

        BEGIN
          SELECT dtinicio, dtfim, nvl(acumulativa,'N'), NVL(QTACUMULADAVENDA,1)
            INTO VD_DTINI, VD_DTFIM, VS_ACUMULATIVA, VN_QTACUMULADAVENDA
            FROM pcbrindeex
           WHERE codbrex = PDADOS(Y).CODCAMP;

          IF VN_QTACUMULADAVENDA = 0 THEN
            VN_QTACUMULADAVENDA := 1;
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            GOTO FIM_LOOP;
        END;

        IF VS_ACUMULATIVA = 'S'
        THEN
          P_ATUALIZAR_DTBASE(PDADOS(Y).CODCAMP);
        END IF;

        IF VN_CAMP <> PDADOS(Y).CODCAMP
          OR VN_GRPREGRA <> PDADOS(Y).GRUPOREGRA
        THEN
          VN_CAMP     := PDADOS(Y).CODCAMP;
          VN_GRPREGRA := PDADOS(Y).GRUPOREGRA;
          vlLISTA     := NULL;

          IF (VS_ACUMULATIVA = 'S') AND
             (VN_QTACUMULADAVENDA = 1) --valor padrão do campo PCBRINDEEX.QTACUMULADAVENDA
          THEN
            P_ATUALIZAR_DTBASE(PDADOS(Y).CODCAMP);

            FOR GRPCONTEMPLADOS IN
            (SELECT DISTINCT I.GRPREGRABRINDE
                FROM PCPEDI I, PCPEDC C
               WHERE C.NUMPED = I.NUMPED
                 AND NVL(I.GRPREGRABRINDE,0) <> 0
                 AND C.DTCANCEL IS NULL
                 AND C.POSICAO <> 'C'
                 AND C.CODCLI = G_CODCLI
                 AND I.CODIGOBRINDE = PDADOS(Y).CODCAMP
                 AND c.numped > G_NUMPED_GZERO)
                 --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                 --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI'))
            LOOP

              vlLISTA := vlLISTA || TO_CHAR(GRPCONTEMPLADOS.GRPREGRABRINDE) || ',';

            END LOOP;
          END IF;

          OPEN C_PREMIOS(PDADOS(Y).CODCAMP, PDADOS(Y).GRUPOREGRA, PN_NUMPEDTV5, vlLISTA);

          FETCH C_PREMIOS INTO VC_PREMIOS;

          WHILE C_PREMIOS%FOUND LOOP

            IF VS_ACUMULATIVA = 'S'
            THEN

              SELECT COUNT(*)
                INTO VN_BRINDEGRPZERO
                FROM pcpedi i, pcpedc c
               WHERE i.numped = c.numped
                 AND i.codigobrinde = PDADOS(Y).CODCAMP
                 AND i.grpregrabrinde = 0
                 AND C.DTCANCEL IS NULL
                 AND C.POSICAO <> 'C'
                 AND c.codcli = G_CODCLI
                 AND c.numped > G_NUMPED_GZERO
                 --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                 --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                 AND c.data BETWEEN G_DTBASEACUMUL AND VD_DTFIM;

              SELECT COUNT(*)
                INTO vn_qtpremios
                FROM pcbrindeexpremio
               WHERE codbrex = PDADOS(Y).CODCAMP
                 AND gruporegra = PDADOS(Y).GRUPOREGRA;

              SELECT COUNT(*)
                INTO vn_brindescontemplados
                FROM pcpedi i, pcpedc c
               WHERE i.numped = c.numped
                 AND i.codigobrinde = PDADOS(Y).CODCAMP
                 AND i.grpregrabrinde = PDADOS(Y).GRUPOREGRA
                 AND c.codcli = G_CODCLI
                 AND C.DTCANCEL IS NULL
                 AND C.POSICAO <> 'C'
                 AND c.data BETWEEN G_DTBASEACUMUL AND VD_DTFIM
                 AND c.numped > G_NUMPED_GZERO
                 --AND TO_DATE(TO_CHAR(c.data || ' ' || c.hora || ':' || c.minuto),'DD-MON-RRRR HH24:MI') >
                 --    TO_DATE(TO_CHAR(G_DTBASEACUMUL || ' ' || G_HORAULTPEDACUMU || ':' || G_MINULTPEDACUMU),'DD-MON-RRRR HH24:MI')
                 --AND i.codprod IN (SELECT codprod FROM pcbrindeexpremio WHERE codbrex = PDADOS(Y).CODCAMP);
                 AND i.codprod IN (SELECT NUMEROS FROM TABLE(CODPRODPREMIO(PDADOS(Y).CODCAMP, null, pn_numpedtv5)));

              IF (vn_brindescontemplados < vn_qtpremios)
              AND (vn_brindescontemplados > 0)
              AND (VN_BRINDEGRPZERO = 0)
              THEN
                VB_PULOUBRINDE := TRUE;
                GOTO FIM_LOOP_PDADOS;
              ELSE
                VB_PULOUBRINDE := FALSE;
              END IF;

            END IF;

            VR_RESULT.codcamp := PDADOS(Y).CODCAMP;

            select pcbrindeex.movccrca
              into VR_RESULT.usadebcredrca
              from pcbrindeex
             where codbrex = PDADOS(Y).CODCAMP;

            VR_RESULT.grpregrabrinde := VC_PREMIOS.GRUPOREGRA;
            VR_RESULT.grpregracamp   := PDADOS(Y).GRUPOREGRA;
            VR_RESULT.codbrinde      := VC_PREMIOS.CODPROD;
            VR_RESULT.estdisp        := 'N';
            VR_RESULT.similar        := 'N';



     --Retornar qtde disponível da campanha
            SELECT NVL(QTMAXBRINDES,0), NVL(QTMAXBRINDESCLI,0), NVL(QTACUMULADAVENDA,1)
             INTO  VN_QTMAX, VN_QTMAXCLI, VN_QTACUMULADAVENDA
             FROM PCBRINDEEX
             WHERE
             CODBREX = PDADOS(Y).CODCAMP;

            BEGIN
              SELECT NVL(QTMAXBRINDES,0), NVL(QTMAXBRINDESCLI,0),
                     NVL(QTMAXBRINDESSUPERV,0), NVL(QTMAXBRINDESRCA,0) --HIS.02193.2015
               INTO VN_QTMAXIT, VN_QTMAXITCLI,
                    VN_QTMAXITSUPERV, VN_QTMAXITRCA
               FROM PCBRINDEEXPREMIO
               WHERE
               CODBREX = PDADOS(Y).CODCAMP
               AND GRUPOREGRA = VC_PREMIOS.GRUPOREGRA
               AND CODPROD = VC_PREMIOS.CODPROD;
            EXCEPTION
              WHEN OTHERS THEN
                VN_QTMAXIT := 0;
                VN_QTMAXITCLI := 0;
                VN_QTMAXITSUPERV := 0;
                VN_QTMAXITRCA := 0;
            END;


           if (VN_QTMAX = 0) THEN
             VN_QTMAX := 999999;
           END IF;

           if (VN_QTMAXCLI = 0) THEN
             VN_QTMAXCLI := 999999;
           END IF;

           if (VN_QTMAXIT = 0) THEN
             VN_QTMAXIT := 999999;
           END IF;

           if (VN_QTMAXITCLI = 0) THEN
             VN_QTMAXITCLI := 999999;
           END IF;

           if (VN_QTMAXITSUPERV = 0) THEN
             VN_QTMAXITSUPERV := 999999;
           END IF;

           if (VN_QTMAXITRCA = 0) THEN
             VN_QTMAXITRCA := 999999;
           END IF;

           VN_QTCAMPGERAL := 0;
           VN_QTCAMPGERALCLI := 0;
           VN_QTBRINDEGERAL := 0;
           VN_QTBRINDEGERALCLI := 0;
           VN_QTBRINDEGERALSUPERV := 0;
           VN_QTBRINDEGERALRCA := 0;
           VN_QTBRINDEPRODUT := 0;


            -- 1 - POR CAMPANHA
            -- 1.1 - CAMPANHA GERAL
            IF (VN_QTMAX <>  999999) THEN
              SELECT nvl(SUM(QT),0)
               INTO VN_QTCAMPGERAL
               FROM PCPEDI
               WHERE
               DATA BETWEEN VD_DTINI AND VD_DTFIM
               AND BRINDE = 'S'
               AND CODIGOBRINDE = PDADOS(Y).CODCAMP;--CODBREX;
            END IF;
            -- 1.2 - CAMPANHA POR CLIENTE
            IF (VN_QTMAXCLI <>  999999) THEN
              SELECT nvl(SUM(QT),0)
                INTO VN_QTCAMPGERALCLI
                FROM PCPEDI
                WHERE
                DATA BETWEEN VD_DTINI AND VD_DTFIM
                AND BRINDE = 'S'
                AND CODCLI = G_CODCLI
                AND CODIGOBRINDE = PDADOS(Y).CODCAMP;--CODBREX;
            END IF;
            -- 2 - POR BRINDE(ITEM)
            -- 2.1 - POR BRINDE GERAL
            IF (VN_QTMAXITCLI <>  999999 and
                VN_QTMAXITSUPERV <> 999999 and
                VN_QTMAXITRCA <> 999999) THEN
              SELECT nvl(SUM(QT),0)
                INTO VN_QTBRINDEGERAL
                FROM PCPEDI
                WHERE
                DATA BETWEEN VD_DTINI AND VD_DTFIM
                AND BRINDE = 'S'
                AND GRPREGRABRINDE = VC_PREMIOS.GRUPOREGRA
                AND CODIGOBRINDE = PDADOS(Y).CODCAMP;--VCODBREX;
             END IF;
            -- 2.2 - POR BRINDE POR CLIENTE
            IF (VN_QTMAXITCLI <>  999999 ) THEN
              SELECT nvl(SUM(QT),0)
                INTO VN_QTBRINDEGERALCLI
                FROM PCPEDI
                WHERE
                DATA BETWEEN VD_DTINI AND VD_DTFIM
                AND BRINDE = 'S'
                AND GRPREGRABRINDE = VC_PREMIOS.GRUPOREGRA
                AND CODCLI = G_CODCLI
                AND CODIGOBRINDE = PDADOS(Y).CODCAMP
                AND CODPROD = VC_PREMIOS.CODPROD; --VCODBREX;
             END IF;
            -- 2.3 - POR BRINDE POR SUPERVISOR  --HIS.02193.2015
            IF (VN_QTMAXITSUPERV <>  999999) THEN
              SELECT nvl(SUM(QT),0)
                INTO VN_QTBRINDEGERALSUPERV
                FROM PCPEDI, PCPEDC
                WHERE
                PCPEDI.DATA BETWEEN VD_DTINI AND VD_DTFIM
                AND PCPEDI.NUMPED = PCPEDC.NUMPED
                AND PCPEDI.BRINDE = 'S'
                AND PCPEDI.GRPREGRABRINDE = VC_PREMIOS.GRUPOREGRA
                AND PCPEDC.CODSUPERVISOR = (SELECT PCPEDC.CODSUPERVISOR FROM PCPEDC WHERE PCPEDC.NUMPED = G_NUMPED)
                AND PCPEDI.CODIGOBRINDE = PDADOS(Y).CODCAMP;
             END IF;
            -- 2.4 - POR BRINDE POR RCA  --HIS.02193.2015
            IF (VN_QTMAXITRCA <>  999999) THEN
              SELECT nvl(SUM(QT),0)
                INTO VN_QTBRINDEGERALRCA
                FROM PCPEDI, PCPEDC
                WHERE
                PCPEDI.DATA BETWEEN VD_DTINI AND VD_DTFIM
                AND PCPEDI.NUMPED = PCPEDC.NUMPED
                AND PCPEDI.BRINDE = 'S'
                AND PCPEDI.GRPREGRABRINDE = VC_PREMIOS.GRUPOREGRA
                AND PCPEDC.CODUSUR = (SELECT PCPEDC.CODUSUR FROM PCPEDC WHERE PCPEDC.NUMPED = G_NUMPED)
                AND PCPEDI.CODIGOBRINDE = PDADOS(Y).CODCAMP;
             END IF;
            -- 2.5 - POR BRINDE PRODUTO
            IF (VN_QTMAXIT <>  999999) THEN
              SELECT nvl(SUM(QT),0)
                INTO VN_QTBRINDEPRODUT
                FROM PCPEDI
                WHERE
                DATA BETWEEN VD_DTINI AND VD_DTFIM
                AND BRINDE = 'S'
                AND NVL(GRPREGRABRINDE, 0) = VC_PREMIOS.GRUPOREGRA
                AND CODIGOBRINDE = PDADOS(Y).CODCAMP
                AND CODPROD = VC_PREMIOS.CODPROD;--VCODBREX;
             END IF;

            -- Se usar venda por embalagem, converte as quantidades dos pedidos
            IF (ferramentas.F_BUSCARPARAMETRO_ALFA('FIL_UTILIZAVENDAPOREMBALAGEM',VC_PREMIOS.CODFILIALEMB,'N') = 'S') then

              begin
              select qtunit
                into vnFator
                from pcembalagem
               where codauxiliar = VC_PREMIOS.CODAUXILIAR
               and codfilial = VC_PREMIOS.CODFILIALEMB
               and CODPROD = VC_PREMIOS.CODPROD;
              exception
                when others then
                  vnFator := 0;
              end;

              if vnFator <= 0 then
                vnFator := 1;
              end if;

              VN_QTCAMPGERAL := VN_QTCAMPGERAL/vnFator;
              VN_QTCAMPGERALCLI := VN_QTCAMPGERALCLI/vnFator;
              VN_QTBRINDEGERAL := VN_QTBRINDEGERAL/vnFator;
              VN_QTBRINDEGERALCLI := VN_QTBRINDEGERALCLI/vnFator;
              VN_QTBRINDEGERALSUPERV := VN_QTBRINDEGERALSUPERV/vnFator;
              VN_QTBRINDEGERALRCA := VN_QTBRINDEGERALRCA/vnFator;
              VN_QTBRINDEPRODUT := VN_QTBRINDEPRODUT/vnFator;
            end if;

            if (VN_QTMAX      - VN_QTCAMPGERAL) <= 0 then
                VN_QTCAMPDISP  :=  0;
            else
                 VN_QTCAMPDISP  :=  VN_QTMAX   - VN_QTCAMPGERAL;
            end if;

            if (VN_QTMAXCLI   - VN_QTCAMPGERALCLI) <= 0 then
                VN_QTCAMPDISPCLI  :=  0;
            else
                 VN_QTCAMPDISPCLI  :=  VN_QTMAXCLI   - VN_QTCAMPGERALCLI;
            end if;

            if (VN_QTMAXIT    - VN_QTBRINDEPRODUT) <= 0 then
                VN_QTCAMPDISPIT  :=  0;
            else
                 VN_QTCAMPDISPIT  :=  VN_QTMAXIT    - VN_QTBRINDEPRODUT;
            end if;

            if (VN_QTMAXITCLI - VN_QTBRINDEGERALCLI) <= 0 then
                VN_QTCAMPDISPITCLI  :=  0;
            else
                 VN_QTCAMPDISPITCLI  :=  VN_QTMAXITCLI - VN_QTBRINDEGERALCLI;
            end if;

            --HIS.02193.2015
            if (VN_QTMAXITSUPERV - VN_QTBRINDEGERALSUPERV) <= 0 then
                VN_QTCAMPDISPITSUPERV  :=  0;
            else
                 VN_QTCAMPDISPITSUPERV  :=  VN_QTMAXITSUPERV - VN_QTBRINDEGERALSUPERV;
            end if;

            if (VN_QTMAXITRCA - VN_QTBRINDEGERALRCA) <= 0 then
                VN_QTCAMPDISPITRCA  :=  0;
            else
                 VN_QTCAMPDISPITRCA  :=  VN_QTMAXITRCA - VN_QTBRINDEGERALRCA;
            end if;

            VR_RESULT.QTBRINDEDISP := NULL;

            --VN_QTCAMPDISP
            --VN_QTCAMPDISPClI
            --VN_QTCAMPDISPIT
            --VN_QTCAMPDISPITCLI

            IF VN_QTMAX > 0 THEN
                VR_RESULT.QTBRINDEDISP := VN_QTCAMPDISP;
            END IF;

            IF VN_QTMAXCLI > 0 THEN
                IF VR_RESULT.QTBRINDEDISP > VN_QTCAMPDISPCLI  THEN
                    VR_RESULT.QTBRINDEDISP := VN_QTCAMPDISPCLI;
                END IF;
            END IF;

            IF VN_QTMAXIT > 0 THEN
                IF VR_RESULT.QTBRINDEDISP > VN_QTCAMPDISPIT THEN
                    VR_RESULT.QTBRINDEDISP := VN_QTCAMPDISPIT;
                END IF;
            END IF;

            IF VN_QTMAXITCLI > 0 THEN
                IF VR_RESULT.QTBRINDEDISP > VN_QTCAMPDISPITCLI  THEN
                    VR_RESULT.QTBRINDEDISP := VN_QTCAMPDISPITCLI;
                END IF;
            END IF;

            --HIS.02193.2015
            IF VN_QTMAXITSUPERV > 0 THEN
                IF VR_RESULT.QTBRINDEDISP > VN_QTCAMPDISPITSUPERV  THEN
                    VR_RESULT.QTBRINDEDISP := VN_QTCAMPDISPITSUPERV;
                END IF;
            END IF;

            IF VN_QTMAXITRCA > 0 THEN
                IF VR_RESULT.QTBRINDEDISP > VN_QTCAMPDISPITRCA  THEN
                    VR_RESULT.QTBRINDEDISP := VN_QTCAMPDISPITRCA;
                END IF;
            END IF;


            --Definir qtde do brinde a ser concedida
            VR_RESULT.qtdecamp := VC_PREMIOS.qt;

            IF NVL(VC_PREMIOS.ACEITAMULTIPLO, 'N') = 'S'
            THEN

              buscarmenormultiplo(PDADOS(Y).CODCAMP,PDADOS(Y).GRUPOREGRA, VN_MULT);

              IF VN_MULT > NVL(VC_PREMIOS.QTMAXMULTIPLO,0)
                 and NVL(VC_PREMIOS.QTMAXMULTIPLO,0) > 0
               THEN
                VN_MULT := VC_PREMIOS.QTMAXMULTIPLO;
              END IF;

              IF VS_ACUMULATIVA = 'S' THEN
                IF VN_QTACUMULADAVENDA > 1 THEN

                  VN_BRINDESCONTEMPLADOS := 0;
                  SELECT nvl(SUM(QT),0)
                    INTO VN_BRINDESCONTEMPLADOS --REAPROVEITANDO VARIÁVEL
                    FROM PCPEDI
                    WHERE
                    DATA BETWEEN VD_DTINI AND VD_DTFIM
                    AND BRINDE = 'S'
                    AND POSICAO <> 'C'
                    AND CODCLI = G_CODCLI
                    AND GRPREGRABRINDE = VC_PREMIOS.GRUPOREGRA
                    AND CODIGOBRINDE = PDADOS(Y).CODCAMP;

                  VN_BRINDESCONTEMPLADOS := NVL(VN_BRINDESCONTEMPLADOS,0);

                  VR_RESULT.qtde := CASE
                                      WHEN VN_MULT >= VN_QTACUMULADAVENDA THEN
                                        (VC_PREMIOS.qt * (VN_MULT - (VN_BRINDESCONTEMPLADOS / VC_PREMIOS.qt)))
                                      ELSE
                                        VC_PREMIOS.qt
                                    END;

                ELSE
                  VR_RESULT.qtde := VC_PREMIOS.qt;
                END IF;
              ELSE
                VN_MULT := CASE
                           WHEN VN_MULT = 0 THEN
                              1
                           ELSE
                              VN_MULT
                           END;

                VR_RESULT.qtde := VC_PREMIOS.qt * VN_MULT;
              END IF;

            ELSE
              VR_RESULT.qtde := VC_PREMIOS.qt;
            END IF;

           -- Comparando a quantidade da campanha com max brindes da campanha e qtde do item com max do item
            IF (VR_RESULT.qtde > VN_QTCAMPDISP)
              AND (VN_QTCAMPDISP > 0) then
               VR_RESULT.qtde := VN_QTCAMPDISP;

            ELSIF (VN_QTCAMPDISP = 0) THEN
                VB_PULOUBRINDE := TRUE;
                GOTO FIM_LOOP_PDADOS;
            END IF;
            -- 1
            IF (VR_RESULT.qtde > VN_QTCAMPDISPClI)
              AND (VN_QTCAMPDISPClI > 0) then
               VR_RESULT.qtde := VN_QTCAMPDISPClI;

            ELSIF (VN_QTCAMPDISPClI = 0) THEN
                VB_PULOUBRINDE := TRUE;
                GOTO FIM_LOOP_PDADOS;
            END IF;

            -- 2
            IF (VR_RESULT.qtde > VN_QTCAMPDISPIT)
              AND (VN_QTCAMPDISPIT > 0) then
               VR_RESULT.qtde := VN_QTCAMPDISPIT;

            ELSIF (VN_QTCAMPDISPIT = 0) THEN
                VB_PULOUBRINDE := TRUE;
                GOTO FIM_LOOP_PDADOS;
            END IF;

            -- 3
            IF (VR_RESULT.qtde > VN_QTCAMPDISPITCLI)
              AND (VN_QTCAMPDISPITCLI > 0) then
               VR_RESULT.qtde := VN_QTCAMPDISPITCLI;

            ELSIF (VN_QTCAMPDISPITCLI = 0) THEN
                VB_PULOUBRINDE := TRUE;
                GOTO FIM_LOOP_PDADOS;
            END IF;

            -- 4 Por supervisor HIS.02193.2015
            IF (VR_RESULT.qtde > VN_QTCAMPDISPITSUPERV)
              AND (VN_QTCAMPDISPITSUPERV > 0) then
               VR_RESULT.qtde := VN_QTCAMPDISPITSUPERV;

            ELSIF (VN_QTCAMPDISPITSUPERV = 0) THEN
                VB_PULOUBRINDE := TRUE;
                GOTO FIM_LOOP_PDADOS;
            END IF;

            -- 5 Por RCA HIS.02193.2015
            IF (VR_RESULT.qtde > VN_QTCAMPDISPITRCA)
              AND (VN_QTCAMPDISPITRCA > 0) then
               VR_RESULT.qtde := VN_QTCAMPDISPITRCA;

            ELSIF (VN_QTCAMPDISPITRCA = 0) THEN
                VB_PULOUBRINDE := TRUE;
                GOTO FIM_LOOP_PDADOS;
            END IF;

            --VERIFICANDO FILIAL DE BRINDE
            --1º filial retira na PCPRODFILIAL
            begin
              select  pcprodfilial.codfilialretirabrinde
              into VS_CODFILIALRETIRA
              from  pcprodfilial
              where pcprodfilial.codfilial = PFILIALESTOQUE
                    and pcprodfilial.codprod =  VC_PREMIOS.CODPROD;

             exception
               when others then
                  VS_CODFILIALRETIRA := NULL;
             end;
            if VS_CODFILIALRETIRA is null then

               -- 2º filial retira da pcprodut
               select pcprodut.codfilialretira
               into VS_CODFILIALRETIRA
               from pcprodut
               where codprod =  VC_PREMIOS.CODPROD;

               if VS_CODFILIALRETIRA is null then
                 --3º filial retira igual a filial de venda
                  VS_CODFILIALRETIRA := PFILIALESTOQUE  ;
               end if;
            end if;

            --Verificar estoque disponível do brinde
            SELECT (PKG_ESTOQUE.ESTOQUE_DISPONIVEL(PCEST.CODPROD,PCEST.CODFILIAL,'VA'))
              INTO VN_QTDISP
              FROM pcest
             WHERE pcest.codprod = VC_PREMIOS.CODPROD
               AND pcest.codfilial = VS_CODFILIALRETIRA;

            --Se não houver estoque do brinde, procurar por similar
            IF VN_QTDISP >= VR_RESULT.qtde THEN
              VR_RESULT.estdisp := 'S';

            ELSIF NVL(VC_PREMIOS.SUBSTBRINDEPORSIMILAR, 'N') = 'S'
            THEN

              SELECT COUNT(*)
                INTO VN_COUNTSIMIL
                FROM pcprodsimil s, pcest e
               WHERE s.codsimil = e.codprod --2550.056230.2015 (de codprod para codsmil)
                 AND e.codfilial = PFILIALESTOQUE
                 AND s.codprod = VC_PREMIOS.CODPROD
                 AND (PKG_ESTOQUE.ESTOQUE_DISPONIVEL(e.CODPROD,e.CODFILIAL,'VA')) >= VR_RESULT.qtde;

              IF VN_COUNTSIMIL > 0 THEN

                VR_RESULT.similar := 'S';
                SELECT CODSIMIL
                  INTO VR_RESULT.codbrinde
                  FROM (
                SELECT S.CODSIMIL
                  FROM PCPRODSIMIL S, PCEST E
                 WHERE S.CODSIMIL = E.CODPROD
                   AND S.CODPROD = VC_PREMIOS.CODPROD
                   AND E.CODFILIAL = PFILIALESTOQUE
                   AND (PKG_ESTOQUE.ESTOQUE_DISPONIVEL(e.CODPROD,e.CODFILIAL,'VA')) >= VR_RESULT.qtde
                 ORDER BY S.PRIORIDADE
                       ) WHERE ROWNUM = 1;

              END IF;

            END IF;

            SELECT pcprodut.descricao, NVL(pcembalagem.Embalagem, pcprodut.embalagem)
             INTO VR_RESULT.descricao, VR_RESULT.embalagem
             FROM pcprodut, pcembalagem
            WHERE pcprodut.codprod = VC_PREMIOS.codprod
              and pcprodut.codprod = pcembalagem.codprod(+)
              and pcembalagem.codauxiliar(+) = VC_PREMIOS.codauxiliar
              and pcembalagem.codfilial(+) = VC_PREMIOS.codfilialemb;

            <<FIM_LOOP_PDADOS>>
            FETCH C_PREMIOS INTO VC_PREMIOS;

            IF NOT VB_PULOUBRINDE
            THEN
              VT_RESULT.EXTEND;
              VT_RESULT(VT_RESULT.LAST) := VR_RESULT;
              VN_REG := VT_RESULT.LAST + 1;
            END IF;
            VB_PULOUBRINDE := FALSE;
          END LOOP;

          CLOSE C_PREMIOS;
        END IF;
        <<FIM_LOOP>>
        VD_DTINI := NULL;
        VD_DTFIM := NULL;
        VS_ACUMULATIVA := NULL;
      END LOOP;
    END IF;
    VN_CAMP := 0;

    /*Tarefa: 213115
    IF VT_RESULT.COUNT > 0 THEN
      FOR W IN 1..VT_RESULT.LAST
      LOOP
        IF VN_CAMP <> VT_RESULT(W).CODCAMP
        THEN
          verbrindegrpzero(VT_RESULT(W).CODCAMP);
        END IF;
        VN_CAMP := VT_RESULT(W).CODCAMP;
      END LOOP;
    END IF;*/

    PRESULT := VT_RESULT;

  END P_GERARPREMIO;

  PROCEDURE P_ATUALIZARQTBRINDE(PCODCAMP   IN NUMBER,
                                PGRPREGRA  IN NUMBER,
                                PCODBRINDE IN NUMBER,
                                PQTDE      IN NUMBER,
                                PRESULT    OUT VARCHAR2) IS

    VN_QTMAXCAB    NUMBER;
    VN_QTMAXITEM   NUMBER;
    VN_QTDISPCAB   NUMBER;
    VN_QTDISPITEM  NUMBER;

  BEGIN

    SELECT NVL(QTBRINDESDISP,0), NVL(QTMAXBRINDES,0)
     INTO VN_QTDISPCAB, VN_QTMAXCAB
     FROM PCBRINDEEX
     WHERE
     CODBREX = PCODCAMP;

    SELECT NVL(QTBRINDESDISP,0), NVL(QTMAXBRINDES,0)
     INTO VN_QTDISPITEM, VN_QTMAXITEM
     FROM PCBRINDEEXPREMIO
     WHERE
     CODBREX = PCODCAMP
     AND GRUPOREGRA = PGRPREGRA
     AND CODPROD = PCODBRINDE;

    PRESULT := 'OK';

    IF VN_QTMAXCAB > 0 AND VN_QTDISPCAB >= PQTDE
    THEN

       UPDATE PCBRINDEEX
        SET QTBRINDESDISP = QTBRINDESDISP - PQTDE
        WHERE
        CODBREX = PCODCAMP;

       IF VN_QTMAXITEM > 0 AND VN_QTDISPITEM >= PQTDE
       THEN

         UPDATE PCBRINDEEXPREMIO
          SET QTBRINDESDISP = QTBRINDESDISP - PQTDE
          WHERE
          CODBREX = PCODCAMP
          AND GRUPOREGRA = PGRPREGRA
          AND CODPROD = PCODBRINDE;

       ELSE
         PRESULT := 'Quantidade disponível para o brinde da campanha insuficiente!';
       END IF;

      ELSE
     PRESULT := 'Quantidade disponível para a campanha insuficiente!';
    END IF;


  END P_ATUALIZARQTBRINDE;

  FUNCTION VALIDARTV5(PN_NUMPED IN PCPEDC.NUMPED%TYPE, PN_NUMPEDTV5 IN PCPEDC.NUMPED%TYPE, PCODBREX IN NUMBER DEFAULT 0)
    RETURN VARCHAR2 IS

    TYPE TB_PREMIOS IS TABLE OF PCBRINDEXPREMIOGENERICO%ROWTYPE INDEX BY BINARY_INTEGER;
    PREMIO  PCBRINDEXPREMIOGENERICO%ROWTYPE;
    PREMIOS TB_PREMIOS;
    i         number;
    vbValido  Boolean;
    MSG       VARCHAR2(4000);
    vnCODBREX Number;

  BEGIN

  vbvalido := false;

  BEGIN
    SELECT NVL(CODBREX, PCODBREX) INTO vnCODBREX
      FROM PCPEDC C
     WHERE C.NUMPED = PN_NUMPEDTV5;
  EXCEPTION
    WHEN OTHERS THEN
      vnCODBREX := PCODBREX;
  END;

  BEGIN
   SELECT COUNT(*) INTO i
     FROM PCPEDC C
    WHERE C.NUMPEDTV1 = PN_NUMPED
      AND C.CODBREX   = vnCODBREX
      AND C.NUMPED   <> PN_NUMPEDTV5;
  EXCEPTION
    WHEN OTHERS THEN
      i := 0;
  END;

  IF i > 0 THEN
    Return 'Já existe TV5 para o mesmo pedido TV1 e mesma campanha informada';
  END IF;

  --Verifica se os prêmios configurados atendem os valores dos brindes
  i := 0;
  FOR cPREMIOS IN (select p.*
                     from pcbrindexpremiogenerico p
                    where p.codbrex = vnCODBREX
                 order by p.valor) LOOP
    i := i + 1;
    PREMIO := cPremios;
    PREMIOS(i) := PREMIO;
  END LOOP;

  vbvalido := true;
  FOR ITENS IN (SELECT I.CODPROD,
                       I.PTABELA,
                       I.QT,
                       P.CODEPTO,
                       P.CODFORNEC,
                       P.CODSEC,
                       P.CODCATEGORIA,
                       P.CODSUBCATEGORIA
                  FROM PCPEDI I
                 INNER JOIN PCPRODUT P
                    ON P.CODPROD = I.CODPROD
                 WHERE I.NUMPED = PN_NUMPEDTV5
              order by (i.ptabela*i.qt)) LOOP

    IF NOT(vbvalido) THEN
      EXIT; -- Se é false, não foi atendido, pedido inválido para a campanha
    ELSE
      vbvalido := false; -- Volta para true caso seja atendido
    END IF;

    FOR i IN 1 .. PREMIOS.COUNT LOOP

      IF PREMIOS(i).ACEITAMULTIPLO <> 'X' THEN

        IF PREMIOS(i)
         .TIPO = 'B' AND ITENS.CODSUBCATEGORIA = PREMIOS(i).CODIGO THEN
          -- Subcategoria
          IF (ITENS.PTABELA * ITENS.QT) <= PREMIOS(i).VALOR THEN
            PREMIOS(i).VALOR := PREMIOS(i)
                                .VALOR - (ITENS.PTABELA * ITENS.QT);
            vbValido := true;
          END IF;
        END IF;

        IF PREMIOS(i).TIPO = 'C' AND ITENS.CODCATEGORIA = PREMIOS(i).CODIGO THEN
          -- Categoria
          IF (ITENS.PTABELA * ITENS.QT) <= PREMIOS(i).VALOR THEN
            PREMIOS(i).VALOR := PREMIOS(i)
                                .VALOR - (ITENS.PTABELA * ITENS.QT);
            vbValido := true;
          END IF;
        END IF;

        IF PREMIOS(i).TIPO = 'S' AND ITENS.CODSEC = PREMIOS(i).CODIGO THEN
          -- Sessão
          IF (ITENS.PTABELA * ITENS.QT) <= PREMIOS(i).VALOR THEN
            PREMIOS(i).VALOR := PREMIOS(i)
                                .VALOR - (ITENS.PTABELA * ITENS.QT);
            vbValido := true;
          END IF;
        END IF;

        IF PREMIOS(i).TIPO = 'D' AND ITENS.CODEPTO = PREMIOS(i).CODIGO THEN
          -- Departamento
          IF (ITENS.PTABELA * ITENS.QT) <= PREMIOS(i).VALOR THEN
            PREMIOS(i).VALOR := PREMIOS(i)
                                .VALOR - (ITENS.PTABELA * ITENS.QT);
            vbValido := true;
          END IF;
        END IF;

        IF PREMIOS(i).TIPO = 'F' AND ITENS.CODFORNEC = PREMIOS(i).CODIGO THEN
          -- Fornecedor
          IF (ITENS.PTABELA * ITENS.QT) <= PREMIOS(i).VALOR THEN
            PREMIOS(i).VALOR := PREMIOS(i)
                                .VALOR - (ITENS.PTABELA * ITENS.QT);
            vbValido := true;
          END IF;
        END IF;

      END IF;

      IF VBVALIDO THEN
        IF PREMIOS(i).ACEITAMULTIPLO = 'N' THEN
          PREMIOS(i).ACEITAMULTIPLO := 'X';
        END IF;
        EXIT;
      END IF;

    END LOOP;

  END LOOP;

  i := 0;
  SELECT COUNT(*) INTO i
    FROM TABLE(REL_BRINDES(PN_NUMPED, PN_NUMPEDTV5));

  IF i = 0 THEN
    Return 'Pedido TV1 não atende às regras da campanha!';
  END IF;

  --Verifica se todos os itens foram atendidos para as regras da campanha
  FOR VALIDACAO IN (SELECT I.CODPROD
                          ,SUM(I.QT) AS QTBRINDE
                          ,NVL(B.QTDECAMP,0) AS QTPERMITIDA
                      FROM PCPEDI I LEFT JOIN (SELECT CODBRINDE
                                                     ,SUM(QTDECAMP) QTDECAMP
                                                FROM TABLE(REL_BRINDES(PN_NUMPED, PN_NUMPEDTV5))
                                            GROUP BY CODBRINDE) B
                                           ON I.CODPROD = B.CODBRINDE
                     WHERE I.NUMPED = PN_NUMPEDTV5
                  GROUP BY I.CODPROD, B.QTDECAMP) LOOP

     IF NVL(VALIDACAO.QTPERMITIDA, 0) < VALIDACAO.QTBRINDE THEN
       vbvalido := false;
       IF VALIDACAO.QTPERMITIDA <= 0 THEN
         Return 'Pedido não atende as regras da campanha. ';
       END IF;
       EXIT;
     END IF;

  END LOOP;

  MSG := 'OK';

  IF NOT(VBVALIDO) THEN
    MSG := 'Pedido não atende as regras da campanha cód: ' || vnCODBREX || '! Valores permitidos:' || CHR(13);
    FOR DADOS IN (SELECT CASE P.TIPO
                           WHEN 'F' THEN 'FORNECEDOR'
                           WHEN 'S' THEN 'SESSÃO'
                           WHEN 'B' THEN 'SUBCATEGORIA'
                           WHEN 'D' THEN 'DEPARTAMENTO'
                           WHEN 'C' THEN 'CATEGORIA'
                         END TIPO
                         ,CODIGO
                         ,VALOR
                         ,ACEITAMULTIPLO
                    FROM PCBRINDEXPREMIOGENERICO P
                   WHERE CODBREX = vnCODBREX) LOOP

        MSG := MSG || DADOS.TIPO || ': ' || DADOS.CODIGO ||
                    ' - Valor: '         || to_char(DADOS.VALOR, 'FM999G999G999D90')  ||
                     CASE DADOS.ACEITAMULTIPLO
                       WHEN 'N' THEN ' - Não aceita múltiplo'
                       ELSE ''
                     END || CHR(13);

    END LOOP;
  END IF;

  RETURN MSG;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN SQLERRM;
  END;

  FUNCTION CODPRODPREMIO(P_CODBREX IN NUMBER, P_GR IN NUMBER, PN_NUMPEDTV5 IN PCPEDC.NUMPED%TYPE)
    RETURN TABELA_INTEIRO IS
    TABELA_NUMEROS TABELA_INTEIRO;
  BEGIN
    TABELA_NUMEROS := TABELA_INTEIRO();

    FOR L_CURSOR IN (SELECT CODPROD
                       FROM PCBRINDEEXPREMIO
                      WHERE CODBREX = P_CODBREX
                        AND GRUPOREGRA = P_GR
                     UNION
                     SELECT I.CODPROD
                       FROM PCPEDI I INNER JOIN PCPRODUT P
                                             ON P.CODPROD = I.CODPROD
                                     INNER JOIN PCBRINDEXPREMIOGENERICO B
                                             ON B.CODBREX = P_CODBREX
                                            AND B.GRUPOREGRA = P_GR
                                            AND ((B.TIPO = 'F' AND P.CODFORNEC       = B.CODIGO) OR -- FORNECEDOR
                                                 (B.TIPO = 'S' AND P.CODSEC          = B.CODIGO) OR -- SEÇAO
                                                 (B.TIPO = 'B' AND P.CODSUBCATEGORIA = B.CODIGO) OR -- SUBCATEGORIA
                                                 (B.TIPO = 'D' AND P.CODEPTO         = B.CODIGO) OR -- DEPARTAMENTO
                                                 (B.TIPO = 'C' AND P.CODCATEGORIA    = B.CODIGO))   -- CATEGORIA
                      WHERE I.NUMPED = PN_NUMPEDTV5) LOOP

      TABELA_NUMEROS.EXTEND;
      TABELA_NUMEROS(TABELA_NUMEROS.COUNT) := ARRAY_INTEIRO(NUMEROS => L_CURSOR.CODPROD);

    END LOOP;

    RETURN TABELA_NUMEROS;
  END;

  PROCEDURE REL_BRINDES_DEBUG(pn_numped NUMBER, pn_numpedtv5 NUMBER DEFAULT 0) IS
    vnCodCampanha NUMBER;
    vnCodBrinde   NUMBER;
    vnCodGrupo    NUMBER;
    vnQtde        NUMBER;
    vnCodCamp     NUMBER;
    vvCritica     VARCHAR2(50);  
  BEGIN
  
    FOR vc_Brindes IN (SELECT CODBRINDE, QTDE, CODCAMP, GRPREGRABRINDE FROM TABLE(REL_BRINDES(pn_numped, pn_numpedtv5))) LOOP
      
      vnCodCamp   := vc_Brindes.CODCAMP;      
      vnCodBrinde := vc_Brindes.CODBRINDE;
      vnCodGrupo  := vc_Brindes.GRPREGRABRINDE;
      vnQtde      := vc_Brindes.QTDE;
      
    END LOOP;

    FOR vc_Criticas IN (SELECT CODCAMP, GRPREGRACAMP, DESCRICAO FROM TABLE(RESTRICOES_BRINDES(pn_numped, pn_numpedtv5))) LOOP
      
      vnCodCampanha := vc_Criticas.CODCAMP;
      vnCodGrupo    := vc_Criticas.GRPREGRACAMP;
      vvCritica     := SUBSTR(vc_Criticas.DESCRICAO,1,50);      
      
    END LOOP;
    
  END;

END PKG_BRINDEEX;
