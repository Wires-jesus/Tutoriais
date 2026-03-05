------------------------------------------------------------
-- PACKAGE SPECIFICATION
------------------------------------------------------------
CREATE OR REPLACE PACKAGE pkg_cnpj_validator AS

   C_REGEX_CNPJ_ALFA VARCHAR2(12) := '[^[:alnum:]]';

   -- Calcula o DV para uma base de 12 caracteres (Numérico ou Alfanumérico)
   FUNCTION calcular_dv_cnpj(p_base_cnpj IN VARCHAR2) RETURN VARCHAR2;
   
   -- Retorna BOOLEAN (Ideal para PL/SQL: IF, Triggers, Procedures)
   FUNCTION is_valid_cnpj(p_cnpj IN VARCHAR2) RETURN BOOLEAN;

   -- Retorna 'S' ou 'N' (Ideal para SQL: Views, Relatórios Winthor)
   FUNCTION validar_cnpj(p_cnpj IN VARCHAR2) RETURN VARCHAR2;
   
   -- Retorna o CNPJ limpo, sem máscaras
   FUNCTION limpar_cnpj(p_cnpj IN VARCHAR2) RETURN VARCHAR2;
   
   -- Retorna S caso os CNPJs sejam iguais, e N caso sejam diferentes
   FUNCTION comparar_cnpjs(p_cnpj1 IN VARCHAR2, p_cnpj2 IN VARCHAR2) RETURN VARCHAR2;
   
   -- Retorna apenas o radical do CNPJ limpo, sem máscaras (8 caracteres)
   FUNCTION get_radical(p_cnpj IN VARCHAR2) RETURN VARCHAR2;
   
END pkg_cnpj_validator;