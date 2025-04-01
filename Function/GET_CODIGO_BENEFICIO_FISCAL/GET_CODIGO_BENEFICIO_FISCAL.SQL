CREATE OR REPLACE FUNCTION GET_CODIGO_BENEFICIO_FISCAL(P_NATUREZAVINCULO IN VARCHAR2,
                                                       P_TIPOCLIENTEFORNEC IN  VARCHAR2,
                                                       P_CODFILIAL IN VARCHAR2,
                                                       P_CODPROD IN NUMBER,
                                                       P_UFORIGEM IN VARCHAR2,
                                                       P_UFDESTINO IN VARCHAR2,
                                                       P_NCM IN VARCHAR2,
                                                       P_FIGURATRIBUTARIA IN VARCHAR2,
                                                       P_MENSAGEM_RETORNO IN OUT VARCHAR2,
                                                       P_CSTICMS IN VARCHAR2 DEFAULT '',
                                                       P_CODFISCAL IN NUMBER DEFAULT 0,
                                                       P_CODCLI IN NUMBER DEFAULT 0,
                                                       P_NOVOPROCESSO IN VARCHAR2 DEFAULT 'N',
                                                       P_CODBENEFFISCALCOMPLEMENTAR OUT VARCHAR2) RETURN VARCHAR2 IS
   --VARIÁVEIS PROCESSO ANTIGO
   V_TIPOTRIBUTACAOENTRADA VARCHAR2(1);
   --VARIÁVEIS PROCESSO NOVO
   VSQL VARCHAR2(6000);
   VCODIGOBENEFICIOFISCALNOVO VARCHAR2(10);
   VCODIGOBENEFICIOFISCALEXCECAO VARCHAR2(10);
   VCONTADORTABELA INTEGER;
   VCONTADORCAMPO INTEGER;
   --VARIÁVEIS DE AMBOS PROCESSOS
   VCODIGOBENEFICIOFISCAL VARCHAR2(10);

   FUNCTION OBTER_CODCADASTROEXCECAO RETURN VARCHAR2
            IS VCODCADASTROEXCECAO VARCHAR2(10);
   BEGIN
      VCODCADASTROEXCECAO := NULL;
      VSQL := '';

      BEGIN
      -- VERIFICAR EXCEÇÃO COM CÓDIGO DE PRODUTO, CÓDIGO DE CLIENTE, CÓDIGO DE FIGURA TRIBUTÁRIA E CÓDIGO DE NCM
            VSQL := 'SELECT E.CODCADASTROEXCECAO,                                                                                    ' ||
                    '       E.CODBENEFICIOFISCALCOMPLE                                                                               ' ||
                    'FROM PCCODIGOBENEFICIOFISCAL B,                                                                                 ' ||
                    '     (SELECT CODEXCECAO,                                                                                        ' ||
                    '             CODCADASTROPRINC,                                                                                  ' ||
                    '             CODCADASTROEXCECAO,                                                                                ' ||
                    '             TIPO1,                                                                                             ' ||
                    '             VALOR1,                                                                                            ' ||
                    '             TIPO2,                                                                                             ' ||
                    '             VALOR2,                                                                                            ' ||
                    '             CODBENEFICIOFISCALCOMPLE                                                                           ' ||
                    '      FROM PCEXCECAOCADASTROSFISCAIS                                                                            ' ||
                    '      WHERE CODCADASTROPRINC = :VCODIGOBENEFICIOFISCALNOVO                                                      ' ||
                    '        AND ROTINA = ''PCSIS4008'') E                                                                           ' ||
                    'WHERE B.CODIGOBENEFICIO = E.CODCADASTROPRINC                                                                    ' ||
                    '  AND B.UF = :P_UFORIGEM                                                                                        ' ||
                    '  AND NVL(B.TIPOCREDPRES,''AB'') IN (''AB'',''CB'')                                                             ' ||
                    '  AND (NVL(E.VALOR1, ''0'') =  (DECODE(NVL(E.TIPO1,''XX''), ''PR'', :P_CODPROD, ''CC'', :P_CODCLI, ''FT'', :P_FIGURATRIBUTARIA, ''CM'', :P_NCM)))          ' ||
                    '  AND ((TRIM(E.VALOR2) IS NULL ) OR                                                                             ' ||
                    '       (TRIM(NVL(E.VALOR2, ''0'')) =  (DECODE(NVL(E.TIPO2, ''XX''), ''PR'', :P_CODPROD, ''CC'', :P_CODCLI, ''FT'', :P_FIGURATRIBUTARIA, ''CM'', :P_NCM)))) ' ||
                    '  AND ROWNUM = 1                                                                                                ' ||
                    '  ORDER BY DECODE(NVL(E.TIPO1,''XX''), ''PR'', 1, ''CM'', 2,''FT'', 3, ''CC'', 4),                              ' ||
                    '           DECODE(NVL(E.TIPO2,''XX''), ''PR'', 1, ''CM'', 2,''FT'', 3, ''CC'', 4)                               ';

            EXECUTE IMMEDIATE VSQL
               INTO VCODCADASTROEXCECAO, P_CODBENEFFISCALCOMPLEMENTAR
              USING VCODIGOBENEFICIOFISCALNOVO, P_UFORIGEM, P_CODPROD, P_CODCLI, P_FIGURATRIBUTARIA, P_NCM, P_CODPROD, P_CODCLI, P_FIGURATRIBUTARIA, P_NCM;

            EXCEPTION
            WHEN OTHERS THEN
              VCODCADASTROEXCECAO := NULL;
            END;

      IF VCODCADASTROEXCECAO IS NOT NULL THEN
         RETURN VCODCADASTROEXCECAO;
      ELSE
         RETURN VCODIGOBENEFICIOFISCALNOVO;
      END IF;

   END OBTER_CODCADASTROEXCECAO;

BEGIN
   -----------------------------------------------------------------------------------------
   -----INICIO COMENTÁRIOS SOBRE VARIÁVEIS PROCESSO NOVO------------------------------------
   -- Nesse novo processo será chamado pelo Servidor (NFe, NFCe, etc...)
   -- P_CODPROD IN NUMBER - CÓDIGO DO PRODUTO
   -- P_UFDESTINO IN VARCHAR2 - UF DO CLIENTE
   -- P_CSTICMS      - Será o Código Situação Tributário do ICMS passado para a função.
   -- P_CODFISCAL    - Será o CFOP passado para a função.
   -- P_NOVOPROCESSO - Será passado "S" quando for o servidor que chamar essa função
   -- As novas regras estarão vinculadas apenas ao CST e CFOP. Mas irá verificar também as Exceções de cada Código do Benefício Fiscal.
   -----FINAL COMENTÁRIOS SOBRE VARIÁVEIS PROCESSO NOVO-------------------------------------
   -----------------------------------------------------------------------------------------
   VCODIGOBENEFICIOFISCAL        := NULL;
   VCODIGOBENEFICIOFISCALNOVO    := NULL;
   VCODIGOBENEFICIOFISCALEXCECAO := NULL;
   ---------------------------------------------------------------------------------
   -- VERIFICAR SE A TABELA JÁ FOI CRIADA NO BANCO DE DADOS PARA QUE NÃO OCORRA ERROS NO PROCESSO ANTIGO.
   SELECT COUNT(TABLE_NAME) CONT
     INTO VCONTADORTABELA
     FROM ALL_TABLES
    WHERE TABLE_NAME = 'PCEXCECAOCADASTROSFISCAIS';
   ---------------------------------------------------------------------------------
   -- VERIFICAR SE OS CAMPOS DA TABELA PCCODIGOBENEFICIOFISCALVINCULO JÁ FORAM CRIADOS NO BANCO DE DADOS PARA QUE NÃO OCORRA ERROS NO PROCESSO ANTIGO.
   SELECT COUNT(COLUNAS.COLUMN_NAME) CONT
     INTO VCONTADORCAMPO
     FROM USER_TABLES TABELA,
          USER_TAB_COLUMNS COLUNAS
    WHERE TABELA.TABLE_NAME = COLUNAS.TABLE_NAME
      AND TABELA.TABLE_NAME = 'PCCODIGOBENEFICIOFISCALVINCULO'
      AND COLUNAS.COLUMN_NAME IN ('SITTRIBUT', 'CODFISCAL');
   ---------------------------------------------------------------------------------
   ---------------------------------------------------------------------------------
   IF (P_NOVOPROCESSO = 'S') AND (VCONTADORTABELA > 0) AND (VCONTADORCAMPO > 0) THEN
      BEGIN
         IF P_CSTICMS IS NULL THEN
            P_MENSAGEM_RETORNO := 'N: O PARAMETRO P_CSTICMS NÃO FOI INFORMADO.';
            RAISE_APPLICATION_ERROR(-20999,P_MENSAGEM_RETORNO);
         END IF;

         IF P_CODFISCAL = 0 OR P_CODFISCAL IS NULL THEN
            P_MENSAGEM_RETORNO := 'N: O PARAMETRO P_CODFISCAL NÃO FOI INFORMADO.';
            RAISE_APPLICATION_ERROR(-20999,P_MENSAGEM_RETORNO);
         END IF;

         IF P_UFORIGEM IS NOT NULL AND P_CSTICMS IS NOT NULL AND P_CODFISCAL > 0 THEN
            BEGIN
              SELECT COD.CODIGOBENEFICIO,
                     COD.CODBENEFICIOFISCALCOMPLE
                INTO VCODIGOBENEFICIOFISCALNOVO,
                     P_CODBENEFFISCALCOMPLEMENTAR
                FROM PCCODIGOBENEFICIOFISCALVINCULO COD,
                     PCCODIGOBENEFICIOFISCAL B
               WHERE COD.CODIGOBENEFICIO = B.CODIGOBENEFICIO
                 AND NVL(B.TIPOCREDPRES,'AB') IN ('AB','CB')
                 AND COD.SITTRIBUT = P_CSTICMS
                 AND COD.CODFISCAL = P_CODFISCAL
                 AND COD.UFDESTINO = P_UFORIGEM
                 AND NVL(COD.FIGURATRIBUTARIA,0) = TO_CHAR(P_FIGURATRIBUTARIA)
                 AND ROWNUM = 1;

                 P_MENSAGEM_RETORNO := 'S: CÓDIGO BENEFÍCIO LOCALIZADO POR FIGURA TRIBUTÁRIA.';
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                 BEGIN
                    SELECT COD.CODIGOBENEFICIO,
                           COD.CODBENEFICIOFISCALCOMPLE
                      INTO VCODIGOBENEFICIOFISCALNOVO,
                           P_CODBENEFFISCALCOMPLEMENTAR
                      FROM PCCODIGOBENEFICIOFISCALVINCULO COD,
                           PCCODIGOBENEFICIOFISCAL B
                     WHERE COD.CODIGOBENEFICIO = B.CODIGOBENEFICIO
                       AND NVL(B.TIPOCREDPRES,'AB') IN ('AB','CB')
                       AND COD.SITTRIBUT = P_CSTICMS
                       AND COD.CODFISCAL = P_CODFISCAL
                       AND COD.UFDESTINO = P_UFORIGEM
                       AND COD.FIGURATRIBUTARIA IS NULL
                       AND ROWNUM = 1;

                       P_MENSAGEM_RETORNO := 'S: CÓDIGO BENEFÍCIO LOCALIZADO SEM FIGURA TRIBUTÁRIA.';
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        VCODIGOBENEFICIOFISCALNOVO := '';
                        P_MENSAGEM_RETORNO := 'S: NÃO ENCONTRADO CÓDIGO BENEFÍCIO';
                  END;
            END;
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            IF VCODIGOBENEFICIOFISCALNOVO IS NULL THEN
               P_MENSAGEM_RETORNO := 'N: ERRO NA BUSCA DO CÓDIGO BENEFÍCIO FISCAL.';
            END IF;
      END;

      BEGIN
          IF (VCODIGOBENEFICIOFISCALNOVO IS NOT NULL) THEN
             VCODIGOBENEFICIOFISCALEXCECAO := OBTER_CODCADASTROEXCECAO;
          END IF;
      EXCEPTION
         WHEN OTHERS THEN
            IF VCODIGOBENEFICIOFISCALNOVO IS NULL THEN
               P_MENSAGEM_RETORNO := 'N: ERRO NA BUSCA DO CÓDIGO BENEFÍCIO FISCAL.';
            END IF;
      END;

      IF (VCODIGOBENEFICIOFISCALNOVO IS NOT NULL) THEN
         BEGIN
            VCODIGOBENEFICIOFISCALEXCECAO := OBTER_CODCADASTROEXCECAO;
            IF VCODIGOBENEFICIOFISCALEXCECAO IS NOT NULL THEN
              VCODIGOBENEFICIOFISCALNOVO := VCODIGOBENEFICIOFISCALEXCECAO;
            END IF;
         EXCEPTION
            WHEN OTHERS THEN
               IF VCODIGOBENEFICIOFISCALEXCECAO IS NULL THEN
                  P_MENSAGEM_RETORNO := 'S: CÓDIGO BENEFÍCIO LOCALIZADO, MAS CÓDIGO DE BENEFÍCIO DE EXCEÇÃO NÃO FOI ENCONTRADO.';
               END IF;
         END;
      END IF;
   END IF;

   IF VCODIGOBENEFICIOFISCALNOVO IS NOT NULL THEN
      VCODIGOBENEFICIOFISCAL := VCODIGOBENEFICIOFISCALNOVO;
   END IF;
   -----------------------------------------------------------------------------------------
   -----INICIO COMENTÁRIOS SOBRE VARIÁVEIS PROCESSO ANTIGO----------------------------------
   -- P_NATUREZAVINCULO       = E (ENTRADA) OU S (SAÍDA)
   -- V_TIPOTRIBUTACAOENTRADA = TIPO DA TRIBUTAÇÃO IDENTIFICADO NA ROTINA 132 PARAMETRO 1533
   -- P_TIPOCLIENTEFORNEC     = PARA SAÍDA É COMPOSTO DAS OPÇÕES:
   --                           'NORM','Normal',
   --                           'CONSF','Consumidor Final',
   --                           'NRPA','NRPA',
   --                           'SIMPN','Simples Nacional',
   --                           'ORGP','Órgão Público',
   --                           'REGE','Regime Especial',
   --                           'SUFRA','Suframa'
   --
   --    PARA ENTRADA É CONSIDERADO OS VALORE RETORNADOS DA CONSULTA:
   --
   --      SELECT PCROTULOITEM.DESCRICAO || '(' || PCROTULOITEM.VALOR || ')' AS DESCRICAOCOMPLETA,
   --             PCROTULOITEM.VALOR
   --        FROM PCROTULOITEM
   --       WHERE ID = 'TIPOFORNEC';
   -----------------------------------------------------------------------------------------------
   -- P_CODFILIAL             = É O CODIGO DA FILIAL DE DESTINO, MAIS UTILIZADO NAS OPÇÇÕES QUE VISUALIZA A FIGURA TRIBUTÁRIA PARA ENTRADA
   -- P_CODPROD               = IDENTIFICA O CÓDIGO DO PRODUTO
   -- P_UFORIGEM              = UTILIZADO PARA A O TIPO DE TRIBUTAÇÃO DE ENTRADA (PRODUTO / ESTADO (UF))
   -- P_UFORIGEM              = UTILIZADO PARA A O TIPO DE TRIBUTAÇÃO DE ENTRADA (PRODUTO / ESTADO (UF) e  NCM / FIGURA TRIBUTÁRIA e PRODUTO / FIGURA TRIBUTÁRIA)
   -- P_NCM                   = UTILIZADO PARA IDENTIRFICAR O CODIGO DO BENEFÍCIO FISCAL QUANDO FOR ENTRADA (NCM / FIGURA TRIBUTÁRIA)
   -- P_FIGURATRIBUTARIA      = UTILIADO PARA SAÍDA E PARA ENTRADA. NO CASO DA ENTRADA VAI SER PARA AS CONFIGURAÇÕES  (NCM / FIGURA TRIBUTÁRIA e PRODUTO / FIGURA TRIBUTÁRIA)
   -----FINAL COMENTÁRIOS SOBRE VARIÁVEIS PROCESSO ANTIGO-----------------------------------
   -----------------------------------------------------------------------------------------
   V_TIPOTRIBUTACAOENTRADA := '';

   IF (NVL(P_NOVOPROCESSO,'N') = 'N') OR (VCODIGOBENEFICIOFISCAL IS NULL) THEN
   BEGIN
      -- Pegar qual tipo de tributação na entrada
      --------------------------------------------------------------------
      SELECT NVL(USATRIBENTPORUF, 'N') INTO V_TIPOTRIBUTACAOENTRADA FROM PCCONSUM;
      --------------------------------------------------------------------
      --SE O PARAMETRO  P_NATUREZAVINCULO NÃO FOR INFORMADO, NÃO DEVERÁ CONTINUAR COM O PROCEDIMENTO
      IF P_NATUREZAVINCULO IS NULL THEN
         P_MENSAGEM_RETORNO := 'N: O PARAMETRO P_NATUREZAVINCULO NÃO FOI INFORMADO.';
         RAISE_APPLICATION_ERROR(-20999,P_MENSAGEM_RETORNO);
      END IF;
      --SAÍDA
      IF P_NATUREZAVINCULO = 'S' THEN
         BEGIN
            SELECT COD.CODIGOBENEFICIO
              INTO VCODIGOBENEFICIOFISCAL
              FROM PCCODIGOBENEFICIOFISCALVINCULO COD,
                   PCCODIGOBENEFICIOFISCAL B
             WHERE COD.CODIGOBENEFICIO = B.CODIGOBENEFICIO
               AND NVL(B.TIPOCREDPRES,'AB') IN ('AB','CB')
               AND COD.NATUREZAVINCULO   = P_NATUREZAVINCULO
               AND COD.FIGURATRIBUTARIA  = P_FIGURATRIBUTARIA
               AND COD.TIPOCLIENTEFORNEC = P_TIPOCLIENTEFORNEC
               AND ROWNUM = 1;

               P_MENSAGEM_RETORNO := 'S: CÓDIGO BENEFÍCIO LOCALIZADO (SAÍDA).';
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               VCODIGOBENEFICIOFISCAL := '';

               P_MENSAGEM_RETORNO := 'S: NÃO ENCONTRADO CÓDIGO BENEFÍCIO DE SAÍDA';

               IF P_FIGURATRIBUTARIA IS NULL THEN
                  P_MENSAGEM_RETORNO := 'N: O PARAMETRO P_FIGURATRIBUTARIA NÃO FOI INFORMADO. INFORME A FIGURA TRIBUTÁRIA PARA PESQUISA SER REALIZADA.';
               END IF;

               IF P_TIPOCLIENTEFORNEC IS NULL THEN
                  P_MENSAGEM_RETORNO := 'N: O PARAMETRO P_TIPOCLIENTEFORNEC NÃO FOI INFORMADO. INFORMA O TIPO DO CLIENTE PARA REALIZAR A CONSULTA.';
               END IF;
         END;
      END IF;
      /* PARA ENTRADA, É CONSIDERADO O PARAMETRO 1533 DA ROTINA 132. ESSE PARAMETRO DETERMINA O TIPO DE TRIBUTAÇÃO DA ENTRADA (Produto,   Produto/Estado,        */
      /* NCM/Figura Tributária, Produto/Figura Tributária). DE ACORDO COM ESSE PARAMETRO A CONSULTA É REALIZADA NA TABELA PCCODIGOBENEFICIOFISCALVINCULO      */
      IF P_NATUREZAVINCULO = 'E' THEN -- ENTRADA
         CASE
            --PRODUTO
            WHEN V_TIPOTRIBUTACAOENTRADA = 'N' THEN
               BEGIN
                  BEGIN
                     SELECT COD.CODIGOBENEFICIO
                       INTO VCODIGOBENEFICIOFISCAL
                       FROM PCCODIGOBENEFICIOFISCALVINCULO COD,
                            PCCODIGOBENEFICIOFISCAL B
                      WHERE COD.CODIGOBENEFICIO = B.CODIGOBENEFICIO
                        AND NVL(B.TIPOCREDPRES,'AB') IN ('AB','CB')
                        AND COD.NATUREZAVINCULO       = P_NATUREZAVINCULO
                        AND COD.TIPOTRIBUTACAOENTRADA = V_TIPOTRIBUTACAOENTRADA
                        AND COD.CODPROD               = P_CODPROD
                        AND ROWNUM = 1;

                     P_MENSAGEM_RETORNO := 'S: CÓDIGO BENEFÍCIO LOCALIZADO (ENTRADA - PRODUTO)';
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        VCODIGOBENEFICIOFISCAL := '';

                        P_MENSAGEM_RETORNO := 'S: NÃO ENCONTRADO CÓDIGO BENEFÍCIO (ENTRADA - PRODUTO).';

                     IF P_CODPROD IS NULL THEN
                        P_MENSAGEM_RETORNO := 'N: O PARAMETRO P_CODPROD NÃO FOI INFORMADO. INFORME O CODIGO DO PRODUTO PARA CONSULTA SER REALIZADA.';
                     END IF;
                  END;
               END;
            --PRODUTO / ESTADO (UF)
            WHEN V_TIPOTRIBUTACAOENTRADA = 'S' THEN
               BEGIN
                  BEGIN
                     SELECT COD.CODIGOBENEFICIO
                       INTO VCODIGOBENEFICIOFISCAL
                       FROM PCCODIGOBENEFICIOFISCALVINCULO COD,
                            PCCODIGOBENEFICIOFISCAL B
                      WHERE COD.CODIGOBENEFICIO = B.CODIGOBENEFICIO
                        AND NVL(B.TIPOCREDPRES,'AB') IN ('AB','CB')
                        AND COD.NATUREZAVINCULO       = P_NATUREZAVINCULO
                        AND COD.TIPOTRIBUTACAOENTRADA = V_TIPOTRIBUTACAOENTRADA
                        AND COD.CODPROD               = P_CODPROD
                        AND COD.UFORIGEM              = P_UFORIGEM
                        AND COD.UFDESTINO             = P_UFDESTINO
                        AND ROWNUM = 1;

                    P_MENSAGEM_RETORNO := 'S: CÓDIGO BENEFÍCIO LOCALIZADO (ENTRADA - PRODUTO/ESTADO (UF) )';
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        VCODIGOBENEFICIOFISCAL := '';
                        P_MENSAGEM_RETORNO := 'S: NÃO ENCONTRADO CÓDIGO BENEFÍCIO (ENTRADA - PRODUTO/ESTADO (UF)).';

                     IF P_CODPROD IS NULL THEN
                        P_MENSAGEM_RETORNO := 'N: O PARAMETRO P_CODPROD NÃO FOI INFORMADO. INFORME O CODIGO DO PRODUTO PARA CONSULTA SER REALIZADA.';
                     END IF;

                     IF P_UFORIGEM IS NULL THEN
                        P_MENSAGEM_RETORNO := 'N: O PARAMETRO P_UFORIGEM NÃO FOI INFORMADO. INFORME A UF DE ORIGEM PARA CONSULTA SER REALIZADA.';
                     END IF;

                     IF P_UFDESTINO IS NULL THEN
                        P_MENSAGEM_RETORNO := 'N: O PARAMETRO P_UFDESTINO NÃO FOI INFORMADO. INFORME A UF DE DESTINO PARA CONSULTA SER REALIZADA.';
                     END IF;
                  END;
               END;
            --NCM / FIGURA TRIBUTÁRIA
            WHEN V_TIPOTRIBUTACAOENTRADA = 'F' THEN
               BEGIN
                  BEGIN
                     SELECT COD.CODIGOBENEFICIO
                       INTO VCODIGOBENEFICIOFISCAL
                       FROM PCCODIGOBENEFICIOFISCALVINCULO COD,
                            PCCODIGOBENEFICIOFISCAL B
                      WHERE COD.CODIGOBENEFICIO = B.CODIGOBENEFICIO
                        AND NVL(B.TIPOCREDPRES,'AB') IN ('AB','CB')
                        AND COD.NATUREZAVINCULO       = P_NATUREZAVINCULO
                        AND COD.TIPOTRIBUTACAOENTRADA = V_TIPOTRIBUTACAOENTRADA
                        AND COD.TIPOCLIENTEFORNEC     = P_TIPOCLIENTEFORNEC
                        AND COD.FIGURATRIBUTARIA      = P_FIGURATRIBUTARIA
                        AND COD.CODFILIAL             = P_CODFILIAL --CODFILIAL de destino
                        AND COD.NCM                   = P_NCM
                        AND COD.UFDESTINO             = P_UFDESTINO
                        AND ROWNUM = 1;

                    P_MENSAGEM_RETORNO := 'S: CÓDIGO BENEFÍCIO LOCALIZADO (ENTRADA - NCM / FIGURA TRIBUTÁRIA).';
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        VCODIGOBENEFICIOFISCAL := '';
                        P_MENSAGEM_RETORNO := 'S: NÃO ENCONTRADO CÓDIGO BENEFÍCIO (ENTRADA -  NCM / FIGURA TRIBUTÁRIA).';

                     IF P_TIPOCLIENTEFORNEC IS NULL THEN
                        P_MENSAGEM_RETORNO := 'N: O PARAMETRO P_TIPOCLIENTEFORNEC NÃO FOI INFORMADO. INFORMA O TIPO DO CLIENTE PARA REALIZAR A CONSULTA.';
                     END IF;

                     IF P_FIGURATRIBUTARIA IS NULL THEN
                        P_MENSAGEM_RETORNO := 'N: O PARAMETRO P_FIGURATRIBUTARIA NÃO FOI INFORMADO. INFORME A FIGURA TRIBUTÁRIO PARA CONSULTA SER REALIZADA.';
                     END IF;

                     IF P_CODFILIAL IS NULL THEN
                        P_MENSAGEM_RETORNO := 'N: O PARAMETRO P_CODFILIAL NÃO FOI INFORMADO. INFORME O CÓDIGO DA FILIAL DE DESTINO PARA CONSULTA SER REALIZADA.';
                     END IF;

                     IF P_NCM IS NULL THEN
                        P_MENSAGEM_RETORNO := 'N: O PARAMETRO P_NCM NÃO FOI INFORMADO. INFORME O NCM PARA CONSULTA SER REALIZADA.';
                     END IF;

                     IF P_UFDESTINO IS NULL THEN
                        P_MENSAGEM_RETORNO := 'N: O PARAMETRO P_UFDESTINO NÃO FOI INFORMADO. INFORME A UF DE DESTINO PARA CONSULTA SER REALIZADA.';
                     END IF;
                  END;
               END;

            --PRODUTO / FIGURA TRIBUTÁRIA
            WHEN V_TIPOTRIBUTACAOENTRADA = 'P' THEN
               BEGIN
                  BEGIN
                     SELECT COD.CODIGOBENEFICIO
                       INTO VCODIGOBENEFICIOFISCAL
                       FROM PCCODIGOBENEFICIOFISCALVINCULO COD,
                            PCCODIGOBENEFICIOFISCAL B
                      WHERE COD.CODIGOBENEFICIO = B.CODIGOBENEFICIO
                        AND NVL(B.TIPOCREDPRES,'AB') IN ('AB','CB')
                        AND COD.NATUREZAVINCULO       = P_NATUREZAVINCULO
                        AND COD.TIPOTRIBUTACAOENTRADA = V_TIPOTRIBUTACAOENTRADA
                        AND COD.TIPOCLIENTEFORNEC     = P_TIPOCLIENTEFORNEC
                        AND COD.FIGURATRIBUTARIA      = P_FIGURATRIBUTARIA
                        AND COD.CODFILIAL             = P_CODFILIAL          --CODFILIAL de destino
                        AND COD.CODPROD               = P_CODPROD
                        AND COD.UFDESTINO             = P_UFDESTINO
                        AND ROWNUM = 1;

                    P_MENSAGEM_RETORNO := 'S: CÓDIGO BENEFÍCIO LOCALIZADO (ENTRADA - PRODUTO/FIGURA TRIBUTÁRIA).';
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        VCODIGOBENEFICIOFISCAL := '';
                        P_MENSAGEM_RETORNO := 'S: NÃO ENCONTRADO CÓDIGO BENEFÍCIO (ENTRADA - PRODUTO/FIGURA TRIBUTÁRIA).';

                     IF P_TIPOCLIENTEFORNEC IS NULL THEN
                        P_MENSAGEM_RETORNO := 'N: O PARAMETRO P_TIPOCLIENTEFORNEC NÃO FOI INFORMADO. INFORMA O TIPO DO CLIENTE PARA REALIZAR A CONSULTA.';
                     END IF;

                     IF P_FIGURATRIBUTARIA IS NULL THEN
                        P_MENSAGEM_RETORNO := 'N: O PARAMETRO P_FIGURATRIBUTARIA NÃO FOI INFORMADO. INFORME A FIGURA TRIBUTÁRIA PARA CONSULTA SER REALIZADA.';
                     END IF;

                     IF P_CODFILIAL IS NULL THEN
                        P_MENSAGEM_RETORNO := 'N: O PARAMETRO P_CODFILIAL NÃO FOI INFORMADO. INFORME O CÓDIGO DA FILIAL DE DESTINO PARA CONSULTA SER REALIZADA.';
                     END IF;

                     IF P_CODPROD IS NULL THEN
                        P_MENSAGEM_RETORNO := 'N: O PARAMETRO P_CODPROD NÃO FOI INFORMADO. INFORME O CODIGO DO PRODUTO PARA CONSULTA SER REALIZADA.';
                     END IF;

                     IF P_UFDESTINO IS NULL THEN
                        P_MENSAGEM_RETORNO := 'N: O PARAMETRO P_UFDESTINO NÃO FOI INFORMADO. INFORME A UF DE DESTINO PARA CONSULTA SER REALIZADA.';
                     END IF;
                  END;
               END;
            END CASE;
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            IF V_TIPOTRIBUTACAOENTRADA IS NULL THEN
               P_MENSAGEM_RETORNO := 'N: O PARAMETRO V_TIPOTRIBUTACAOENTRADA NÃO FOI INFORMADO.';
            END IF;
      END;
   END IF;
   ---------------------------------------------------------------------------------
   -- Esse retorno é das duas fucnionalidades.
   RETURN VCODIGOBENEFICIOFISCAL;
END;