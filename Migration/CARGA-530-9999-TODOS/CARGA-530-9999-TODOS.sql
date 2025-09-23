DECLARE
    PROCEDURE INSERIR_9999_TODOS(PTABELA     IN VARCHAR2,
                                 PCODIGO     IN VARCHAR2,
                                 PDESCRICAO  IN VARCHAR2,                                 
                                 PNOMETABELA IN VARCHAR2) IS
        VTEMREGISTRO INTEGER := 0;
        VSQL         VARCHAR2(10000);
        VDATATYPE    VARCHAR2(30);
        VCODIGO      VARCHAR2(50);
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
        
        -- Se não existe, insere
        IF VTEMREGISTRO = 0 THEN
            VSQL := 'INSERT INTO ' || PTABELA || ' (' || PCODIGO || ', ' || PDESCRICAO || ')' || ' VALUES ('|| VCODIGO ||', ''TODOS OS ' || PNOMETABELA || ''')';
            
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