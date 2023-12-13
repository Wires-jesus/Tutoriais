DECLARE
  v_sql VARCHAR2(200);
BEGIN
  -- Renomeando a coluna abastecepalete para abastepalete
  v_sql := 'ALTER TABLE pclogdadoslogisticos RENAME COLUMN abastecepalete TO abastepalete';
  EXECUTE IMMEDIATE v_sql;

  -- Renomeando a coluna abastecepalete_ant para abastepalete_ant
  v_sql := 'ALTER TABLE pclogdadoslogisticos RENAME COLUMN abastecepalete_ant TO abastepalete_ant';
  EXECUTE IMMEDIATE v_sql;

  -- Renomeando a coluna abastecepaletecx para abastepaletecx
  v_sql := 'ALTER TABLE pclogdadoslogisticos RENAME COLUMN abastecepaletecx TO abastepaletecx';
  EXECUTE IMMEDIATE v_sql;

  -- Renomeando a coluna abastecepaletecx_ant para abastepaletecx_ant
  v_sql := 'ALTER TABLE pclogdadoslogisticos RENAME COLUMN abastecepaletecx_ant TO abastepaletecx_ant';
  EXECUTE IMMEDIATE v_sql;
  
  -- Renomeando a coluna ESTOQUEPORDATAVALIDADE para ESTOQUEPORDTVALIDADE 
  v_sql := 'ALTER TABLE pclogdadoslogisticos RENAME COLUMN ESTOQUEPORDATAVALIDADE TO ESTOQUEPORDTVALIDADE';
  EXECUTE IMMEDIATE v_sql;
  
  DBMS_OUTPUT.PUT_LINE('Alterações concluídas com sucesso.');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Erro: ' || SQLERRM);
END;