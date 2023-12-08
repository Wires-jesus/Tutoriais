CREATE OR REPLACE FUNCTION PODE_CANCELAR(P_CODIGO NUMBER) RETURN VARCHAR2 IS RESULTADO VARCHAR2(1);
BEGIN
  SELECT DECODE(P_CODIGO,
                101,
                'S',
                218,
                'S',
                420,
                'S',
                110,
                'S',
                151, 
                'S',
                155,
                'S',
                205,
                'S',
                256,
                'S',
                301,
                'S',
                302,
                'S',
                303,
                'S',
                580,
                'S', 
                563,
                'S',  
                573,
                'S',
                682,
                'S',
                'N')
  INTO   RESULTADO
  FROM   DUAL;

  RETURN RESULTADO;
END; 