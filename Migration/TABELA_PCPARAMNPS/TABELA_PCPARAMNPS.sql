DECLARE
  vQuantidade Integer;
BEGIN
  SELECT COUNT(1) INTO vQuantidade FROM pcparamnps;
  
  IF (vQuantidade = 0) THEN
     INSERT INTO pcparamnps
      (urlbase,
      chave_autenticacao,
      ativo,
      data_erro,
      tempo_inatividade)
    VALUES
      ('https://nps.totvs.io',
      'AcdS+R93n5Vf8Pkt+DBMY5y25ttZjNxT7MJtxUXbd8q98jyk98+Z+GJ59QQNFTXhDM9WNFzEhfNk2CsJCoUTykvRKWGhF1rScW5ey7UY+FY2OFZgKTHaFK60Jh7bj5LR',
      'S',
      null,
      24);
  ELSE
    UPDATE pcparamnps 
    SET 
      tempo_inatividade = 24;
  END IF;

  COMMIT;
END;