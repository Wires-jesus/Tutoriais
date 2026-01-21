DECLARE
 vSQL VARCHAR2(2000);
BEGIN
-- 1. Adicionar a nova coluna temporária do tipo CLOB
vSQL := 'ALTER TABLE PCJSONBOLEPIX ADD (INFORETORNO_NEW CLOB)';
EXECUTE IMMEDIATE vSQL;

-- 2. Copiar os dados da coluna antiga (VARCHAR2) para a nova (CLOB)
vSQL := 'UPDATE PCJSONBOLEPIX SET INFORETORNO_NEW = TO_CLOB(INFORETORNO)';
EXECUTE IMMEDIATE vSQL;

-- Confirma a transação
COMMIT;

-- 3. Remover a coluna antiga (Cuidado: isso remove índices e constraints dessa coluna)
vSQL := 'ALTER TABLE PCJSONBOLEPIX DROP COLUMN INFORETORNO';
EXECUTE IMMEDIATE vSQL;

-- 4. Renomear a nova coluna para o nome original
vSQL := 'ALTER TABLE PCJSONBOLEPIX RENAME COLUMN INFORETORNO_NEW TO INFORETORNO';
EXECUTE IMMEDIATE vSQL;
  
END;