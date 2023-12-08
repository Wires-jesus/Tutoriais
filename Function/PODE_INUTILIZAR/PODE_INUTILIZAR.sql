CREATE OR REPLACE FUNCTION PODE_INUTILIZAR(P_CODIGO NUMBER) RETURN VARCHAR2 IS
  RESULTADO VARCHAR2(1);
BEGIN

  SELECT DECODE(P_CODIGO,
                102,
                'S',
                206,
                'S',
                563,
                'S',
                241,
                'N',
                110,
                'S',
                205,
                'S',
                301,
                'S',
                302,
                'S',
                303,
                'S',
                256,
                'S',
                563,
                'S',
                682,
                'S',
                'N')
  INTO   RESULTADO
  FROM   DUAL;

  RETURN RESULTADO;

END; 