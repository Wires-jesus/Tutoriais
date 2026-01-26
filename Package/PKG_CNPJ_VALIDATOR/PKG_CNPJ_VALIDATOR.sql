------------------------------------------------------------
-- PACKAGE SPECIFICATION
------------------------------------------------------------
CREATE OR REPLACE PACKAGE pkg_cnpj_validator AS
   -- Calcula o DV para uma base de 12 caracteres (Numérico ou Alfanumérico)
   FUNCTION calcular_dv_cnpj(p_base_cnpj IN VARCHAR2) RETURN VARCHAR2;
   
   -- Retorna BOOLEAN (Ideal para PL/SQL: IF, Triggers, Procedures)
   FUNCTION is_valid_cnpj(p_cnpj IN VARCHAR2) RETURN BOOLEAN;

   -- Retorna 'S' ou 'N' (Ideal para SQL: Views, Relatórios Winthor)
   FUNCTION validar_cnpj(p_cnpj IN VARCHAR2) RETURN VARCHAR2;
END pkg_cnpj_validator;
