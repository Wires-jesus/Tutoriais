-- 07_PKG_SL_CONFIGURATOR.sql
-- Alteração: Suporte dinâmico para N colunas na PK (Foco em até 10) para Carga Inicial.
 
CREATE OR REPLACE PACKAGE PKG_SL_CONFIGURATOR AS
    PROCEDURE CONFIGURE_ENTITY(
        p_owner             IN VARCHAR2,
        p_source_table_name IN VARCHAR2,
        p_entity_type       IN VARCHAR2 DEFAULT 'MASTER',
        p_custom_filter     IN CLOB DEFAULT NULL,
        p_force_reconfig    IN NUMBER DEFAULT 0
    );

    PROCEDURE RESET_ENTITY_FOR_RELOAD(p_entity_name IN VARCHAR2);
    
    FUNCTION GET_PK_JOIN_CLAUSE(p_entity_name IN VARCHAR2) RETURN CLOB;
    
    PROCEDURE PURGE_ALL_CONFIG;
    
END PKG_SL_CONFIGURATOR;