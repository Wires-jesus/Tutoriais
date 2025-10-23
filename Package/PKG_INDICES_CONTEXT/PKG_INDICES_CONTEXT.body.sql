CREATE OR REPLACE PACKAGE BODY PKG_INDICES_CONTEXT AS

    TYPE VARCHAR2_TABLE IS
        TABLE OF VARCHAR2(4000) INDEX BY BINARY_INTEGER;

    PROCEDURE EXECUTAR_EXCLUIR_INDICE (
        p_tabela   IN VARCHAR2,
        p_hash     IN VARCHAR2,
        p_coluna   IN VARCHAR2,
        p_log      IN OUT VARCHAR2_TABLE
    );

    PROCEDURE INCREMENTAR_LOG (
        p_mensagem IN VARCHAR2,
        p_log      IN OUT VARCHAR2_TABLE
    );

    FUNCTION CONVERTER_LOG (
        p_log      IN VARCHAR2_TABLE
    ) RETURN CLOB;

    /************************************************************************
    Retorna os índices de contexto criados pela package e válidos
    ************************************************************************/
    PROCEDURE LISTAR_INDICES_DISPONIVEIS (
        p_table_name IN VARCHAR2,
        p_result     OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_result FOR
            SELECT
                ctx.hash,
                ctx.tipo,
                icm.column_name,
                ctx.colunas,
                ctx.data_criacao,
                ctx.matricula_criacao,
                idx.status
            FROM
                 PCDC_INDICES_TEXT ctx
            JOIN user_indexes idx ON
                idx.table_name = ctx.tabela
            JOIN user_ind_columns icm ON
                icm.table_name = idx.table_name
            AND icm.index_name = idx.index_name
            WHERE
              ctx.tabela = upper(p_table_name)
          AND idx.index_name = 'IDX_CTX_' || ctx.hash
          AND idx.index_type = 'DOMAIN'
          AND idx.status = 'VALID'
          AND idx.domidx_status = 'VALID'
          AND idx.domidx_opstatus = 'VALID';
    END LISTAR_INDICES_DISPONIVEIS;

    /************************************************************************
    Valida se as configurações básicas (padrão para os índices automáticos) do Oracle Text estão configuradas
    ************************************************************************/
    PROCEDURE VALIDAR_CONFIGURACOES (
        p_configuracoes_validas OUT CHAR,
        p_log                   OUT CLOB
    ) IS
        l_log               VARCHAR2_TABLE;
        l_stopword_count    NUMBER;
        l_lexer_count       NUMBER;
        l_wordlist_count    NUMBER;
    BEGIN
        p_configuracoes_validas := 'N';
        INCREMENTAR_LOG('Consultando objetos', l_log);
        SELECT COUNT(*) INTO l_stopword_count   FROM ctx_stopwords  WHERE spw_stoplist  = 'WINTHOR_CTX_STPL';
        SELECT COUNT(*) INTO l_lexer_count      FROM ctx_preferences WHERE pre_name     = 'WINTHOR_CTX_LEX';
        SELECT COUNT(*) INTO l_wordlist_count   FROM ctx_preferences WHERE pre_name     = 'WINTHOR_CTX_BWL';

        IF l_stopword_count > 0 AND l_lexer_count > 0 AND l_wordlist_count > 0 THEN
            p_configuracoes_validas := 'S';
        END IF;

        IF l_stopword_count = 0 THEN
            INCREMENTAR_LOG('Stoplist não configurado', l_log);
        END IF;
        IF l_lexer_count = 0 THEN
            INCREMENTAR_LOG('Lexer não configurado', l_log);
        END IF;
        IF l_wordlist_count = 0 THEN
            INCREMENTAR_LOG('Wordlist não configurado', l_log);
        END IF;

        INCREMENTAR_LOG('Validações concluídas', l_log);

        p_log := CONVERTER_LOG(l_log);
    END VALIDAR_CONFIGURACOES;

    /************************************************************************
    Define as configurações básicas (padrão para os índices automáticos) do Oracle Text
    ************************************************************************/
    PROCEDURE CONFIGURAR_AMBIENTE (
        p_ambiente_configurado OUT CHAR,
        p_log                  OUT CLOB
    ) IS
        l_log            VARCHAR2_TABLE;
        l_stopword_count NUMBER;
        l_lexer_count    NUMBER;
        l_wordlist_count NUMBER; 
    BEGIN
        p_ambiente_configurado := 'N';
        INCREMENTAR_LOG('Consultando objetos', l_log);
        SELECT COUNT(*) INTO l_stopword_count   FROM ctx_stopwords  WHERE spw_stoplist  = 'WINTHOR_CTX_STPL';
        SELECT COUNT(*) INTO l_lexer_count      FROM ctx_preferences WHERE pre_name     = 'WINTHOR_CTX_LEX';
        SELECT COUNT(*) INTO l_wordlist_count   FROM ctx_preferences WHERE pre_name     = 'WINTHOR_CTX_BWL';
		BEGIN
			INCREMENTAR_LOG('Excluindo configurações pré existentes', l_log);
	        IF l_stopword_count > 0 THEN
	            INCREMENTAR_LOG('Excluindo WINTHOR_CTX_STPL', l_log);
	            ctx_ddl.drop_stoplist('WINTHOR_CTX_STPL');
	        ELSIF l_lexer_count > 0 THEN
	            INCREMENTAR_LOG('Excluindo WINTHOR_CTX_LEX', l_log);
	            ctx_ddl.drop_preference('WINTHOR_CTX_LEX');
	        ELSIF l_wordlist_count > 0 THEN
	            INCREMENTAR_LOG('Excluindo WINTHOR_CTX_BWL', l_log);
	            ctx_ddl.drop_preference('WINTHOR_CTX_BWL');
	        END IF;
	
	        INCREMENTAR_LOG('Criando stoplist', l_log);
	        ctx_ddl.create_stoplist('WINTHOR_CTX_STPL');
	        ctx_ddl.add_stopword('WINTHOR_CTX_STPL', 'DA');
	        ctx_ddl.add_stopword('WINTHOR_CTX_STPL', 'DE');
	        ctx_ddl.add_stopword('WINTHOR_CTX_STPL', 'DO');
	        ctx_ddl.add_stopword('WINTHOR_CTX_STPL', 'A');
	        ctx_ddl.add_stopword('WINTHOR_CTX_STPL', 'E');
	        ctx_ddl.add_stopword('WINTHOR_CTX_STPL', 'O');	
		EXCEPTION 
			WHEN no_data_found THEN
        	RETURN;	
		END;        

        INCREMENTAR_LOG('Criando lexer', l_log);
        ctx_ddl.create_preference('WINTHOR_CTX_LEX', 'BASIC_LEXER');
        ctx_ddl.set_attribute('WINTHOR_CTX_LEX', 'BASE_LETTER', 'YES');
        ctx_ddl.set_attribute('WINTHOR_CTX_LEX', 'MIXED_CASE', 'NO');
        ctx_ddl.set_attribute('WINTHOR_CTX_LEX', 'INDEX_TEXT', 'YES');
        ctx_ddl.set_attribute('WINTHOR_CTX_LEX', 'INDEX_THEMES', 'NO');
        ctx_ddl.set_attribute('WINTHOR_CTX_LEX', 'INDEX_STEMS', 'NONE');
        ctx_ddl.set_attribute('WINTHOR_CTX_LEX', 'SKIPJOINS', '.,+-*_/\%*');

        INCREMENTAR_LOG('Criando wordlist', l_log);
        ctx_ddl.create_preference('WINTHOR_CTX_BWL', 'BASIC_WORDLIST');
        ctx_ddl.set_attribute('WINTHOR_CTX_BWL', 'WILDCARD_MAXTERMS', 0);
        ctx_ddl.set_attribute('WINTHOR_CTX_BWL', 'STEMMER', 'NULL');
        ctx_ddl.set_attribute('WINTHOR_CTX_BWL', 'FUZZY_NUMRESULTS', 0);
        ctx_ddl.set_attribute('WINTHOR_CTX_BWL', 'SUBSTRING_INDEX', 'YES');
        p_ambiente_configurado := 'S';

        p_log := CONVERTER_LOG(l_log);
    END CONFIGURAR_AMBIENTE;

    /************************************************************************
    Cria um novo índice no Oracle Text que pode ser do tipo:
    - DIRECT_DATASTORE quando o índice for em uma única coluna de texto
    - MULTI_COLUMN_DATASTORE quando o índice for em mais de uma coluna de texto
    - USER_DATASTORE quando o índice for em uma ou mais colunas e alguma das colunas não for texto

    Quando for MULTI_COLUMN_DATASTORE ou USER_DATASTORE:
    - Cria na tabela uma coluna de controle para controle da reindexação e uma trigger que força a atualização desta coluna caso uma das colunas do índice seja alterada
    - Necessário pois apenas a coluna principal do índice sensibiliza a atualização do mesmo

    Quando for USER_DATASTORE:
    - Cria uma função de formatação do índice que concatena todas as colunas envolvidas
    - Necessário para lidar com campos que não são texto
    ************************************************************************/
    PROCEDURE CRIAR_INDICE (
        p_tabela            IN VARCHAR2,
        p_colunas           IN VARCHAR2,
        p_matricula_usuario IN NUMBER,
        p_indice_criado     OUT CHAR,
        p_log               OUT CLOB
    ) IS
        l_log              VARCHAR2_TABLE;
        l_array            dbms_utility.uncl_array;
        l_column_count     BINARY_INTEGER;
        l_data_type        VARCHAR2(200);
        l_coluna           VARCHAR2(100);
        l_colunas          VARCHAR2(4000);
        l_tipo_indice      VARCHAR2(50);
        l_hash             VARCHAR2(6);
        l_datastore_name   VARCHAR2(30);
        l_preference_count INT;
        l_index_count      INT;
        l_object_count     INT;
        l_sql              CLOB;
    BEGIN
        p_indice_criado := 'N';
        INCREMENTAR_LOG('Definindo tipo de índice e validando colunas', l_log);

        dbms_utility.comma_to_table(replace(p_colunas, ' ', ''), l_column_count, l_array);

        --Independente de ter uma ou várias colunas, ainda faremos a verificação se todas são do tipo texto
        IF l_column_count = 1 THEN
            --Caso tenha apenas uma coluna
            l_tipo_indice := 'DIRECT_DATASTORE';
        ELSE
            --Caso tenha mais de uma coluna
            l_tipo_indice := 'MULTI_COLUMN_DATASTORE';
        END IF;

        --Valida se as colunas existem e se o tipo do índice deve ser USER_DATASTORE
        FOR i IN 1..l_column_count LOOP
            BEGIN
                --Busca tipo da coluna no dicionário
                SELECT data_type INTO l_data_type FROM user_tab_columns WHERE table_name = upper(p_tabela) AND column_name = upper(l_array(i));

                IF l_data_type <> 'VARCHAR2' AND l_data_type <> 'CLOB' THEN
                    --Coluna não é texto
                    l_tipo_indice := 'USER_DATASTORE';
                END IF;

                --Concatena as colunas validadas para utilizar na criação do índice
                l_colunas := l_colunas || CASE i WHEN 1 THEN '' ELSE ',' END || upper(l_array(i));

            EXCEPTION
                WHEN no_data_found THEN
                    --Se não encontrar uma coluna já encerra a validação
                    INCREMENTAR_LOG('Coluna ' || l_array(i) || ' não encontrada na tabela ' || upper(p_tabela), l_log);
                    p_log := CONVERTER_LOG(l_log);
                    RETURN;
            END;
        END LOOP;

        IF l_tipo_indice = 'DIRECT_DATASTORE' THEN
            --Se for um DIRECT_DATASTORE verifica se já ão existe um índice context na coluna, pois só pode haver um
            INCREMENTAR_LOG('Validando criação de índice tipo DIRECT_DATASTORE', l_log);
            SELECT
                COUNT(*) INTO l_index_count
            FROM user_indexes idx
            JOIN user_ind_columns icm ON
                icm.table_name = idx.table_name
            AND icm.index_name = idx.index_name
            WHERE
                idx.table_name = upper(p_tabela)
            AND icm.column_name = upper(l_array(1))
            AND idx.index_type = 'DOMAIN';

            IF l_index_count > 0 THEN
                INCREMENTAR_LOG('Já existe um índice context na coluna ' || upper(l_array(1)), l_log);
                RETURN;
            END IF;
        END IF;

        INCREMENTAR_LOG('Criando indice tipo ' || l_tipo_indice, l_log);
        BEGIN
            l_hash := f_gerar_hash_base36(DFSEQ_PCDC_INDICES_TEXT.NEXTVAL);
            l_datastore_name := 'WINTHOR_CTX_' || l_hash || '_DS';
            IF l_tipo_indice = 'DIRECT_DATASTORE' THEN
                l_coluna := upper(l_colunas);
            ELSE
                l_coluna := 'CTL_CTX_' || l_hash;
            END IF;

            INCREMENTAR_LOG('Gravando na tabela de controle', l_log);
            INSERT INTO PCDC_INDICES_TEXT (id, hash, tabela, tipo, coluna, colunas, data_criacao, matricula_criacao)
            VALUES (DFSEQ_PCDC_INDICES_TEXT.CURRVAL, l_hash, upper(p_tabela), l_tipo_indice, l_coluna, l_colunas, current_timestamp, p_matricula_usuario);

            INCREMENTAR_LOG('Configurando data store', l_log);
            ctx_ddl.create_preference(l_datastore_name, l_tipo_indice);

            IF l_tipo_indice = 'MULTI_COLUMN_DATASTORE' OR l_tipo_indice = 'USER_DATASTORE' THEN
                --Para MULTI_COLUMN_DATASTORE ou USER_DATASTORE cria a coluna de controle
                INCREMENTAR_LOG('Criando coluna de controle ' || l_coluna, l_log);
                l_sql := 'ALTER TABLE ' || p_tabela || ' ADD (' || l_coluna || ' CHAR(1))';
                INCREMENTAR_LOG('Executando: ' || l_sql, l_log);
                EXECUTE IMMEDIATE l_sql;

                --Cria trigger que vai forçar um update na coluna de conrole sempre que uma das colunas do índice for alterada
                INCREMENTAR_LOG('Trigger de controle para a coluna ' || l_coluna, l_log);
                l_sql := 'CREATE TRIGGER ' || 'TRG_' || l_coluna || ' BEFORE UPDATE ON ' || p_tabela
                    || CHR(10) || 'FOR EACH ROW '
                    || CHR(10) || 'BEGIN '
                    || CHR(10) || '  IF ';
                FOR i IN 1..l_column_count LOOP
                    --Monta condição para verificar se alguma coluna do índice foi alterada
                    BEGIN
                        IF i > 1 THEN
                            l_sql := l_sql || ' OR ';
                        END IF;
                        l_sql := l_sql || ':OLD.' || upper(l_array(i)) || ' != :NEW.' || upper(l_array(i));
                    END;
                END LOOP;
                l_sql := l_sql || ' THEN'
                    || CHR(10) || ':NEW.' || l_coluna || ' := ''A'';'
                    || CHR(10) || 'END IF;'
                    || CHR(10) || 'END;';
                INCREMENTAR_LOG('Executando: ' || l_sql, l_log);
                EXECUTE IMMEDIATE l_sql;

                IF l_tipo_indice = 'USER_DATASTORE' THEN
                    INCREMENTAR_LOG('Criando procedure de indexação para USER_DATASTORE' , l_log);
                    l_sql := 'CREATE OR REPLACE PROCEDURE P_CTX_DATASTORE_' || l_hash || '(RID IN ROWID, TLOB IN OUT NOCOPY CLOB) IS'
                        || CHR(10) || 'BEGIN'
                        || CHR(10) || 'FOR C1 IN (SELECT ';
                    FOR i IN 1..l_column_count LOOP
                        --Monta concatenação dos valores
                        BEGIN
                            IF i > 1 THEN
                                l_sql := l_sql || ' || CHR(10) || ';
                            END IF;
                            l_sql := l_sql || 'NVL(' || upper(l_array(i)) ||', '''')';
                        END;
                    END LOOP;
                    l_sql := l_sql || ' AS VALOR_CONCATENADO'
                        || CHR(10) || 'FROM ' || upper(p_tabela) || ' WHERE  ROWID = RID) LOOP'
                        || CHR(10) || 'DBMS_LOB.WRITEAPPEND(TLOB, LENGTH(C1.VALOR_CONCATENADO), C1.VALOR_CONCATENADO);'
                        || CHR(10) || 'END LOOP;'
                        || CHR(10) || 'END;';
                    INCREMENTAR_LOG('Executando: ' || l_sql, l_log);
                    EXECUTE IMMEDIATE l_sql;
                END IF;

                INCREMENTAR_LOG('Finalizando configuração do data store ' || l_datastore_name, l_log);
                IF l_tipo_indice = 'MULTI_COLUMN_DATASTORE' THEN
                    --Para MULTI_COLUMN_DATASTORE configura as colunas
                    ctx_ddl.set_attribute(l_datastore_name, 'COLUMNS', l_colunas);
                ELSIF l_tipo_indice = 'USER_DATASTORE' THEN
                    --Para USER_DATASTORE configura a procedure que vai gerar o dado indexado
                    --TODO: Criar procedure
                    ctx_ddl.set_attribute(l_datastore_name, 'PROCEDURE', 'P_CTX_DATASTORE_' || l_hash);
                    ctx_ddl.set_attribute(l_datastore_name, 'OUTPUT_TYPE', 'CLOB');
                END IF;
            END IF;

            INCREMENTAR_LOG('Criando índice' , l_log);
            l_sql := 'CREATE INDEX IDX_CTX_' || l_hash || ' ON ' || p_tabela || '(' || l_coluna || ')'
                     || CHR(10) || ' INDEXTYPE IS CTXSYS.CONTEXT'
                     || CHR(10) || ' PARAMETERS (''DATASTORE ' || l_datastore_name || ' SYNC ( ON COMMIT ) STOPLIST WINTHOR_CTX_STPL WORDLIST WINTHOR_CTX_BWL LEXER WINTHOR_CTX_LEX'')';
            INCREMENTAR_LOG('Executando: ' || l_sql, l_log);
            EXECUTE IMMEDIATE l_sql;

            p_indice_criado := 'N';
            INCREMENTAR_LOG('Índice criado', l_log);

        EXCEPTION
            WHEN OTHERS THEN
                INCREMENTAR_LOG('Erro de execução na criação tipo ' || l_datastore_name || ' - ' || l_tipo_indice || ': ' || sqlcode || ' - ' || sqlerrm, l_log);
                 EXECUTAR_EXCLUIR_INDICE(p_tabela, l_hash, l_coluna, l_log);
        END;
        p_log := CONVERTER_LOG(l_log);
    END CRIAR_INDICE;

    /************************************************************************
    Remove o índice da tabela, removendo também triggers e funções associadas
    ************************************************************************/
    PROCEDURE EXCLUIR_INDICE (
        p_tabela            IN VARCHAR2,
        p_hash              IN VARCHAR2,
        p_indice_excluido   OUT CHAR,
        p_log               OUT CLOB
    ) IS
        l_log       VARCHAR2_TABLE;
        l_coluna    VARCHAR2 (128);
    BEGIN
        p_indice_excluido := 'N';
        INCREMENTAR_LOG('Excluindo índice: ' || p_hash, l_log);

        BEGIN
            SELECT COLUNA INTO l_coluna FROM PCDC_INDICES_TEXT WHERE hash = p_hash;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            INCREMENTAR_LOG('Hash não encontrada na tabela PCDC_INDICES_TEXT', l_log);
            l_coluna := 'CTL_CTX_' || p_hash;
        END;

        EXECUTAR_EXCLUIR_INDICE(p_tabela, p_hash, l_coluna, l_log);

        p_indice_excluido := 'S';
        INCREMENTAR_LOG('Índice excluído ', l_log);
        p_log := CONVERTER_LOG(l_log);
    END EXCLUIR_INDICE;

    /************************************************************************
    Método privado para apagar o índice (reutilizado no rollback da criação)
    ************************************************************************/
    PROCEDURE EXECUTAR_EXCLUIR_INDICE (
        p_tabela   IN VARCHAR2,
        p_hash     IN VARCHAR2,
        p_coluna   IN VARCHAR2,
        p_log      IN OUT VARCHAR2_TABLE
    ) IS
        l_index_count      INT;
        l_object_count     INT;
        l_preference_count INT;
        l_sql              CLOB;
    BEGIN
        --Apaga tabela de controle
        INCREMENTAR_LOG('Excluindo registro da tabela de controle', p_log);
        DELETE FROM PCDC_INDICES_TEXT WHERE hash = p_hash;

        INCREMENTAR_LOG('Verificando existência do índice', p_log);
        SELECT COUNT(*) INTO l_index_count
        FROM
            user_indexes idx
        JOIN
            user_ind_columns icm ON
        icm.table_name = idx.table_name
        AND icm.index_name = idx.index_name
        WHERE
            idx.table_name = upper(p_tabela)
        AND icm.column_name = p_coluna
        AND idx.index_type = 'DOMAIN';

        IF l_index_count > 0 THEN
            INCREMENTAR_LOG('Excluindo índice', p_log);
            l_sql := 'DROP INDEX IDX_CTX_' || p_hash;
            INCREMENTAR_LOG('Executando: ' || l_sql, p_log);
            EXECUTE IMMEDIATE l_sql;
        END IF;

        INCREMENTAR_LOG('Verificando existência de trigger de controle', p_log);
        SELECT COUNT(*) INTO l_object_count FROM USER_TRIGGERS WHERE TRIGGER_NAME = 'TRG_CTL_CTX_' || p_hash ;
        IF l_object_count > 0 THEN
            INCREMENTAR_LOG('Excluindo trigger de controle', p_log);
            l_sql := 'DROP TRIGGER TRG_CTL_CTX_' || p_hash;
            INCREMENTAR_LOG('Executando: ' || l_sql, p_log);
            EXECUTE IMMEDIATE l_sql;
        END IF;

        INCREMENTAR_LOG('Verificando existência de procedure de indexação', p_log);
        SELECT COUNT(*) INTO l_object_count FROM USER_OBJECTS WHERE OBJECT_NAME = 'P_CTX_DATASTORE_' || p_hash || 'AND OBJECT_TYPE = ''PROCEDURE''';
        IF l_object_count > 0 THEN
            INCREMENTAR_LOG('Excluindo procedure de indexação', p_log);
            l_sql := 'DROP PROCEDURE P_CTX_DATASTORE_' || p_hash;
            INCREMENTAR_LOG('Executando: ' || l_sql, p_log);
            EXECUTE IMMEDIATE l_sql;
        END IF;

        INCREMENTAR_LOG('Verificando existência de coluna de controle', p_log);
        IF p_coluna = 'CTL_CTX_' || p_hash THEN
            SELECT COUNT(*) INTO l_object_count
            FROM
                user_tab_columns
            WHERE
                    table_name = p_tabela
                AND column_name = p_coluna;

            IF l_object_count > 0 THEN
                INCREMENTAR_LOG('Excluindo coluna de controle', p_log);
                l_sql := 'ALTER TABLE '
                         || p_tabela
                         || ' DROP COLUMN '
                         || p_coluna;
                INCREMENTAR_LOG('Executando: ' || l_sql, p_log);
                EXECUTE IMMEDIATE l_sql;
            END IF;
        END IF;

        INCREMENTAR_LOG('Verificando existência de preferência do índice', p_log);
        SELECT COUNT(*) INTO l_preference_count FROM ctx_preferences WHERE pre_name = 'WINTHOR_CTX_' || p_hash || '_DS';

        IF l_preference_count > 0 THEN
            INCREMENTAR_LOG('Excluindo preferência do índice', p_log);
            ctx_ddl.drop_preference('WINTHOR_CTX_' || p_hash || '_DS');
        END IF;

    END EXECUTAR_EXCLUIR_INDICE;

    /************************************
    Método privado para incremento dos logs
    ************************************/
    PROCEDURE INCREMENTAR_LOG (
        p_mensagem IN VARCHAR2,
        p_log      IN OUT VARCHAR2_TABLE
    ) IS
    BEGIN
        p_log(NVL(p_log.LAST, 0) + 1) :=  TO_CHAR(CURRENT_TIMESTAMP, 'DD-MM-YY HH24:MI:SS TZH:TZM') || ' - ' || p_mensagem;
    END INCREMENTAR_LOG;

    /************************************
    Método privado para gerar output dos logs em clob
    ************************************/
    FUNCTION CONVERTER_LOG (
        p_log      IN VARCHAR2_TABLE
    ) RETURN CLOB IS
        v_result CLOB;
    BEGIN
        DBMS_LOB.CREATETEMPORARY(v_result, TRUE);  -- cria um CLOB temporário

      FOR i IN p_log.FIRST .. p_log.LAST LOOP
        DBMS_LOB.WRITEAPPEND(v_result, LENGTH(p_log(i)) + 1, CHR(10) || p_log(i));
      END LOOP;

      RETURN v_result;
    END CONVERTER_LOG;

END PKG_INDICES_CONTEXT;