------------------------------------------------------------
-- PACKAGE BODY
------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY pkg_cnpj_validator AS

   -------------------------------------------------------------------
   -- FUNÇÕES PRIVADAS (Helpers internos)
   -------------------------------------------------------------------
   FUNCTION clean_cnpj(p_cnpj IN VARCHAR2) RETURN VARCHAR2 IS
   BEGIN
      RETURN REGEXP_REPLACE(p_cnpj, '[^[:alnum:]]', '');
   END clean_cnpj;

   FUNCTION obter_valor_char(p_char IN CHAR) RETURN NUMBER IS
   BEGIN
      IF p_char BETWEEN '0' AND '9' THEN
         RETURN TO_NUMBER(p_char);
      ELSIF (p_char BETWEEN 'A' AND 'Z') OR (p_char BETWEEN 'a' AND 'z') THEN
         RETURN ASCII(UPPER(p_char)) - ASCII('A') + 17;
      ELSE
         RAISE_APPLICATION_ERROR(-20001, 'Caractere inválido no CNPJ: ' || p_char);
      END IF;
   END obter_valor_char;

   -------------------------------------------------------------------
   -- FUNÇÕES PÚBLICAS
   -------------------------------------------------------------------

   FUNCTION calcular_dv_cnpj(p_base_cnpj IN VARCHAR2) RETURN VARCHAR2 IS
      v_sum     NUMBER := 0;
      v_resto   NUMBER;
      v_d1      NUMBER;
      v_d2      NUMBER;
      v_temp    VARCHAR2(14); 
      i         INTEGER;
      
      TYPE t_num_table IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
      v_mult1 t_num_table;
      v_mult2 t_num_table;
   BEGIN
      IF LENGTH(p_base_cnpj) != 12 THEN
         RAISE_APPLICATION_ERROR(-20002, 'A base do CNPJ deve ter exatamente 12 caracteres.');
      END IF;

      -- Pesos 1
      v_mult1(1):=5; v_mult1(2):=4; v_mult1(3):=3; v_mult1(4):=2;
      v_mult1(5):=9; v_mult1(6):=8; v_mult1(7):=7; v_mult1(8):=6;
      v_mult1(9):=5; v_mult1(10):=4; v_mult1(11):=3; v_mult1(12):=2;

      -- Pesos 2
      v_mult2(1):=6; v_mult2(2):=5; v_mult2(3):=4; v_mult2(4):=3;
      v_mult2(5):=2; v_mult2(6):=9; v_mult2(7):=8; v_mult2(8):=7;
      v_mult2(9):=6; v_mult2(10):=5; v_mult2(11):=4; v_mult2(12):=3; v_mult2(13):=2;

      -- 1º Dígito
      v_sum := 0;
      FOR i IN 1 .. 12 LOOP
         v_sum := v_sum + obter_valor_char(SUBSTR(p_base_cnpj, i, 1)) * v_mult1(i);
      END LOOP;
      v_resto := MOD(v_sum, 11);
      v_d1 := CASE WHEN v_resto < 2 THEN 0 ELSE 11 - v_resto END;

      -- 2º Dígito
      v_temp := p_base_cnpj || TO_CHAR(v_d1);
      v_sum := 0;
      FOR i IN 1 .. 13 LOOP
         v_sum := v_sum + obter_valor_char(SUBSTR(v_temp, i, 1)) * v_mult2(i);
      END LOOP;
      v_resto := MOD(v_sum, 11);
      v_d2 := CASE WHEN v_resto < 2 THEN 0 ELSE 11 - v_resto END;

      RETURN TO_CHAR(v_d1) || TO_CHAR(v_d2);
   END calcular_dv_cnpj;

   -- Função Lógica (Retorna BOOLEAN)
   FUNCTION is_valid_cnpj(p_cnpj IN VARCHAR2) RETURN BOOLEAN IS
      v_clean_cnpj   VARCHAR2(50);
      v_base         VARCHAR2(12);
      v_dv_informado VARCHAR2(2);
      v_dv_calculado VARCHAR2(2);
   BEGIN
      IF p_cnpj IS NULL THEN RETURN FALSE; END IF;
      v_clean_cnpj := clean_cnpj(p_cnpj);
      IF LENGTH(v_clean_cnpj) != 14 THEN RETURN FALSE; END IF;

      v_base := SUBSTR(v_clean_cnpj, 1, 12);
      v_dv_informado := SUBSTR(v_clean_cnpj, 13, 2);

      BEGIN
         v_dv_calculado := calcular_dv_cnpj(v_base);
      EXCEPTION
         WHEN OTHERS THEN RETURN FALSE;
      END;

      RETURN (v_dv_informado = v_dv_calculado);
   END is_valid_cnpj;

   -- Função Wrapper (Retorna 'S' ou 'N')
   FUNCTION validar_cnpj(p_cnpj IN VARCHAR2) RETURN VARCHAR2 IS
   BEGIN
      IF is_valid_cnpj(p_cnpj) THEN
         RETURN 'S';
      ELSE
         RETURN 'N';
      END IF;
   END validar_cnpj;

END pkg_cnpj_validator;