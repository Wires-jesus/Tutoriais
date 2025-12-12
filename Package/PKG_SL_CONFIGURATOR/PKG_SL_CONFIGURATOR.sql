-- 07_PKG_SL_CONFIGURATOR_V2.sql
-- Correção: Implementação da geração real do Schema JSON e ajuste de mapeamento.

CREATE OR REPLACE PACKAGE PKG_SL_CONFIGURATOR AS
    e_key_not_found EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_key_not_found, -20001);

    PROCEDURE CONFIGURE_ENTITY(
        p_owner             IN VARCHAR2,
        p_source_table_name IN VARCHAR2,
        p_entity_type       IN VARCHAR2,
        p_custom_filter     IN CLOB DEFAULT NULL,
        p_force_reconfig    IN NUMBER DEFAULT 0 -- Alterado de BOOLEAN para NUMBER
    );

    PROCEDURE RESET_ENTITY_FOR_RELOAD(p_entity_name IN VARCHAR2);
    FUNCTION GET_ENTITY_SCHEMA(p_entity_name IN VARCHAR2) RETURN CLOB;
    FUNCTION GET_PK_JOIN_CLAUSE(p_entity_name IN VARCHAR2) RETURN VARCHAR2;
END PKG_SL_CONFIGURATOR;
