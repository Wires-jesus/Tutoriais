DECLARE
    PROCEDURE INSERIR_9999_TODOS(
        PTABELA     IN VARCHAR2,
        PCODIGO     IN VARCHAR2,
        PDESCRICAO  IN VARCHAR2,                                 
        PNOMETABELA IN VARCHAR2
    ) IS
        VTEMREGISTRO INTEGER := 0;
        VSQL         VARCHAR2(4000);
        VDATATYPE    VARCHAR2(30);
        VCODIGO      VARCHAR2(50);

        -- Para tratar campos obrigatórios extras
        CURSOR CAMPOS_OBRIGATORIOS IS
            SELECT DISTINCT 
                   COLUMN_NAME, 
                   DATA_TYPE,
                   DATA_LENGTH
              FROM ALL_TAB_COLUMNS
             WHERE TABLE_NAME  = UPPER(PTABELA)
               AND NULLABLE    = 'N'
               AND COLUMN_NAME NOT IN (UPPER(PCODIGO), UPPER(PDESCRICAO));

        VCOLUNAS      VARCHAR2(1000) := '';
        VVALORES      VARCHAR2(1000) := '';
        VSEP          VARCHAR2(2) := '';
        VPADRAO       VARCHAR2(4000);
    BEGIN
        -- Descobre o tipo da coluna
        SELECT DISTINCT DATA_TYPE
          INTO VDATATYPE
          FROM ALL_TAB_COLUMNS
         WHERE TABLE_NAME  = UPPER(PTABELA)
           AND COLUMN_NAME = UPPER(PCODIGO);

        -- Monta valor da chave de acordo com o tipo
        IF VDATATYPE = 'VARCHAR2' THEN
            VCODIGO := '''9999''';
        ELSE
            VCODIGO := '9999';
        END IF;

        -- Verifica se já existe
        VSQL := 'SELECT COUNT(1) FROM ' || PTABELA || ' WHERE ' || PCODIGO || ' = ' || VCODIGO;
        EXECUTE IMMEDIATE VSQL INTO VTEMREGISTRO;

        IF VTEMREGISTRO = 0 THEN
            -- Monta campos obrigatórios extras
            VCOLUNAS := PCODIGO || ', ' || PDESCRICAO;
            VVALORES := VCODIGO || ', ''TODOS OS ' || PNOMETABELA || '''';
            VSEP := ', ';

            FOR DADOS IN CAMPOS_OBRIGATORIOS LOOP
                VCOLUNAS := VCOLUNAS || VSEP || DADOS.COLUMN_NAME;

                -- Define valor padrão baseado no tipo
                IF DADOS.DATA_TYPE LIKE '%CHAR%' OR DADOS.DATA_TYPE = 'VARCHAR2' THEN
                    VPADRAO := 'PADRAO';
                    -- Ajusta para não ultrapassar o tamanho da coluna
                    IF LENGTH(VPADRAO) > DADOS.DATA_LENGTH THEN
                        VPADRAO := SUBSTR(VPADRAO, 1, DADOS.DATA_LENGTH);
                    END IF;
                    VVALORES := VVALORES || VSEP || '''' || VPADRAO || '''';
                ELSIF DADOS.DATA_TYPE LIKE '%NUMBER%' THEN
                    VVALORES := VVALORES || VSEP || '0';
                ELSIF DADOS.DATA_TYPE LIKE '%DATE%' THEN
                    VVALORES := VVALORES || VSEP || 'SYSDATE';
                ELSE
                    VVALORES := VVALORES || VSEP || 'NULL';
                END IF;
            END LOOP;

            -- Monta o insert final
            VSQL := 'INSERT INTO ' || PTABELA || ' (' || VCOLUNAS || ') VALUES (' || VVALORES || ')';
            EXECUTE IMMEDIATE VSQL;
            COMMIT;
        END IF;
    END INSERIR_9999_TODOS;
BEGIN
    INSERIR_9999_TODOS('PCDEPTO','CODEPTO','DESCRICAO','DEPARTAMENTOS');
    INSERIR_9999_TODOS('PCFORNEC','CODFORNEC','FORNECEDOR','FORNECEDORES');
    INSERIR_9999_TODOS('PCBANCO','CODBANCO','NOME','BANCOS');
    INSERIR_9999_TODOS('PCGRUPO','CODGRUPO','GRUPO','GRUPOS');
    INSERIR_9999_TODOS('PCMOEDA','CODMOEDA','MOEDA','MOEDAS');
    INSERIR_9999_TODOS('PCSUPERV','CODSUPERVISOR','NOME','SUPERVISORES');
    INSERIR_9999_TODOS('PCCOB','CODCOB','COBRANCA','COBRANCAS');
    INSERIR_9999_TODOS('PCDIRETORIO','CODDIRETORIO','NOME','DIRETORIOS');
    COMMIT;
END;