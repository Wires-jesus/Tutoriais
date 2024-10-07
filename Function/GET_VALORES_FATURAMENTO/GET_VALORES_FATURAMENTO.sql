CREATE OR REPLACE FUNCTION GET_VALORES_FATURAMENTO RETURN VARCHAR2 IS
    v_sql VARCHAR2(4000);
BEGIN
    v_sql := 'SELECT
                N.NUMTRANSVENDA,
                N.SERIE,
                N.VLTOTGER,
                N.VLCUSTOFIN,
                N.VLTOTGER -
                N.VLCUSTOFIN AS VLLUCRO,
                N.CODFILIAL,
                N.CODFILIALNF
            FROM PCNFSAID N
            WHERE N.DTSAIDA >= TRUNC(SYSDATE-90)
            AND N.DTSAIDA < TRUNC(SYSDATE)
            AND N.CODFISCAL NOT IN (522, 622, 722, 532, 632, 732)
            AND N.CONDVENDA IN (1, 5, 7, 9, 11, 14)';

    RETURN v_sql;
END;
