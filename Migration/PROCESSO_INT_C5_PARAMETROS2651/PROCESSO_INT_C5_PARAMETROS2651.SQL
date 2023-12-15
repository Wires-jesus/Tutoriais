MERGE INTO PCPARAMETROS2651 T
USING (
  SELECT 
    'SINCRONIZACAO_CARGA_DESCIDA'            NOME,
    '00:15:00'                               VALOR,
    'Intervalo de carga da descida de dados' DESCRICAO,
    '99'                                     CODFILIAL
  FROM DUAL

  UNION ALL

  SELECT
    'SINCRONIZACAO_CARGA_SUBIDA'            NOME,
    '30000'                                 VALOR,
    'Intervalo de carga da subida de dados' DESCRICAO,
    '99'                                    CODFILIAL
  FROM DUAL

  UNION ALL

  SELECT
    'SINCRONIZAR_COM_TELA_ABERTA'               NOME,
    'N'                                         VALOR,
    'Se o timer continua rodando em background' DESCRICAO,
    '99'                                        CODFILIAL
  FROM
    DUAL

  UNION ALL

  SELECT
    'SINCRONIZACAO_CARGA_SUBIDA'            NOME,
    '30000'                                 VALOR,
    'Intervalo de carga da subida de dados' DESCRICAO,
    '99'                                    CODFILIAL
  FROM
    DUAL
)S
ON (T.NOME = S.NOME)
WHEN NOT MATCHED THEN
  INSERT( 
    T.NOME,
    T.DESCRICAO,
    T.VALOR,
    T.CODFILIAL
  )
  VALUES(
    S.NOME,
    S.DESCRICAO,
    S.VALOR,
    S.CODFILIAL
  )
