DECLARE
vSQL VARCHAR2(200);
col_count   integer;
col_count1  integer;
BEGIN
   SELECT count(*)
    into col_count
  FROM user_tab_columns
  WHERE table_name = 'PCDESPESAIMPCE'
  AND column_name = 'VALOR_BKP';
  
  IF col_count = 0 THEN
     
     -- Incluindo as colunas de bkp
    vSQL := 'ALTER TABLE PCDESPESAIMPCE ADD VALOR_BKP NUMBER(12,6)';
    EXECUTE IMMEDIATE vSQL; 
  END IF;
  
  SELECT count(*)
    into col_count1
  FROM user_tab_columns
  WHERE table_name = 'PCDESPESAIMPCE'
  AND column_name = 'VLREALIZADO_BKP';
  
  IF col_count = 0 THEN
     
     -- Incluindo as colunas de bkp
    vSQL := 'ALTER TABLE PCDESPESAIMPCE ADD VALOR_BKP NUMBER(12,6)';
    EXECUTE IMMEDIATE vSQL;
  END IF;
      
  -- Clonando os dados das colunas VALOR e VLREALIZADO para as colunas de bkp
  vSQL := 'UPDATE PCDESPESAIMPCE SET VALOR_BKP = VALOR, VLREALIZADO_BKP = VLREALIZADO';
  EXECUTE IMMEDIATE vSQL;
  
  -- Limpado os dados das colunas VALOR e VLREALIZADO
  vSQL := 'UPDATE PCDESPESAIMPCE SET VALOR = NULL, VLREALIZADO = NULL';
  EXECUTE IMMEDIATE vSQL;
  
  -- Alterando a precisão dos campos VALOR e VLREALIZADO
  vSQL := 'ALTER TABLE PCDESPESAIMPCE MODIFY VALOR NUMBER(22,6)';
  EXECUTE IMMEDIATE vSQL;
  
  -- Alterando a precisão dos campos VALOR e VLREALIZADO
  vSQL := 'ALTER TABLE PCDESPESAIMPCE MODIFY VLREALIZADO NUMBER(22,6)';
  EXECUTE IMMEDIATE vSQL;
  
  -- Clonando os dados das colunas BKP para colunas VALOR e VLREALIZADO
  vSQL := 'UPDATE PCDESPESAIMPCE SET VALOR = VALOR_BKP, VLREALIZADO = VLREALIZADO_BKP';
  EXECUTE IMMEDIATE vSQL;
  
  commit;
END;