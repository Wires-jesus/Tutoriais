CREATE OR REPLACE PACKAGE PKG_INDICES_CONTEXT AS
    PROCEDURE LISTAR_INDICES_DISPONIVEIS (
        p_table_name IN VARCHAR2,
        p_result     OUT SYS_REFCURSOR
    );

    PROCEDURE VALIDAR_CONFIGURACOES (
        p_configuracoes_validas OUT CHAR,
        p_log                   OUT CLOB
    );

    PROCEDURE CONFIGURAR_AMBIENTE (
        p_ambiente_configurado  OUT CHAR,
        p_log                   OUT CLOB
    );

    PROCEDURE CRIAR_INDICE (
        p_tabela            IN VARCHAR2,
        p_colunas           IN VARCHAR2,
        p_matricula_usuario IN NUMBER,
        p_indice_criado     OUT CHAR,
        p_log               OUT CLOB
    );

    PROCEDURE EXCLUIR_INDICE (
        p_tabela            IN VARCHAR2,
        p_hash              IN VARCHAR2,
        p_indice_excluido   OUT CHAR,
        p_log               OUT CLOB
    );

END PKG_INDICES_CONTEXT;