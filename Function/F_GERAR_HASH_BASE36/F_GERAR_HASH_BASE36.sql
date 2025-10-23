CREATE OR REPLACE FUNCTION F_GERAR_HASH_BASE36(P_NUMERO IN NUMBER, P_TAMANHO IN NUMBER DEFAULT 6) RETURN VARCHAR2 IS
    l_chars          VARCHAR2(36) := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    l_result         VARCHAR2(25);
    l_input          VARCHAR2(38);
    l_input_reversed VARCHAR2(38);
    l_num            NUMBER;
    l_tamanho        NUMBER;
BEGIN  

    IF P_TAMANHO > 25 THEN
        RAISE_APPLICATION_ERROR(-20001, 'O tamanho máximo da hash gerada é de 25 caracteres.');
    END IF;

    IF LENGTH(P_NUMERO) > 38 THEN
        RAISE_APPLICATION_ERROR(-20001, 'O número a converter deve ter no máximo 38 caracteres.');
    END IF;

    -- Verifica quantidade de casas numéricas que cabem no tamanho da string de saída
    l_tamanho := LENGTH(POWER(36,P_TAMANHO) - 1) - 1;

    IF l_tamanho < LENGTH(P_NUMERO) THEN
        RAISE_APPLICATION_ERROR(-20001, 'O número a converter (' || P_NUMERO || ') é muito grande para o tamanho informado (' || P_TAMANHO || '). O maior número possível para este tamanho deve ter ' || l_tamanho || ' caracteres.');
    END IF;

    -- Formata com os dígitos necessários para chegar no tamanho máximo
    l_input := LPAD(TO_CHAR(TRUNC(P_NUMERO)), l_tamanho, '0');

    -- Inverte os dígitos
    FOR i IN REVERSE 1 .. LENGTH(l_input) LOOP
        l_input_reversed := l_input_reversed || SUBSTR(l_input, i, 1);
    END LOOP;

    -- Converte para número
    l_num := TO_NUMBER(l_input_reversed);

    -- Converte para base 36
    WHILE l_num > 0 LOOP
        l_result := SUBSTR(l_chars, MOD(l_num, 36) + 1, 1) || l_result;
        l_num := FLOOR(l_num / 36);
    END LOOP;

    RETURN LPAD(NVL(l_result, '0'), P_TAMANHO, '0');
END;