CREATE OR REPLACE FUNCTION PODE_IMPORTARXML(P_CODIGO NUMBER) RETURN VARCHAR2 IS
  RESULTADO VARCHAR2(1000);
BEGIN

  SELECT DECODE(P_CODIGO,
                100,
                'S',
                101,
                'N - Nota Fiscal consta como cancelada na base de dados da Sefaz.',
                102,
                'N - Nota Fiscal consta como inutilizada na base de dados da Sefaz.',
                110,
                'N - Uso Denegado.',
                205,
                'N - NF-e está denegada na base de dados da SEFAZ.',
                217,
                'N - Nota Fiscal não consta na base de dados da Sefaz.',
                218,
                'N - Nota Fiscal consta como cancelada na base de dados da Sefaz.',
                301,
                'N - Nota fiscal consta como USO DENEGADO - Irregularidade fiscal do emitente.',
                302,
                'N - Uso Denegado: Irregularidade fiscal do destinatário.', 
                303,
                'N - Uso Denegado: Destinatário não habilitado a operar na UF .'
)
  INTO   RESULTADO
  FROM   DUAL;

  RETURN RESULTADO;

END; 