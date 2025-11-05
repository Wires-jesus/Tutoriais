BEGIN
  DELETE FROM  pcparamnps;

  INSERT INTO pcparamnps
    (nome,
    urlbase,
    chave_autenticacao,
    ativo,
    data_erro,
    log_erro,
    tempo_inatividade,
    tempoproximarequisicao)
  VALUES
    ('NPS_CORPORATIVO_PRODUCAO',
    'https://nps.totvs.io',
    'AcdS+R93n5Vf8Pkt+DBMY5y25ttZjNxT7MJtxUXbd8q98jyk98+Z+GJ59QQNFTXhDM9WNFzEhfNk2CsJCoUTykvRKWGhF1rScW5ey7UY+FY2OFZgKTHaFK60Jh7bj5LR',
    'S',
    NULL,
    NULL,
    24,
    168);

  INSERT INTO pcparamnps
    (nome,
    urlbase,
    chave_autenticacao,
    ativo,
    data_erro,
    log_erro,
    tempo_inatividade,
    tempoproximarequisicao)
  VALUES
    ('NPS_WINTHOR_PRODUCAO',
    'http://autenticador.licenciamento-winthor.totvs.com.br',
    NULL,
    'S',
    NULL,
    NULL,
    24,
    168);

  INSERT INTO pcparamnps
    (nome,
    urlbase,
    chave_autenticacao,
    ativo,
    data_erro,
    log_erro,
    tempo_inatividade,
    tempoproximarequisicao)
  VALUES
    ('NPS_WINTHOR_HOMOLOGACAO',
    'http://autenticadorhomolog.licenciamento-winthor.totvs.com.br',
    NULL,
    'S',
    NULL,
    NULL,
    24,
    168);

  COMMIT;
END;