BEGIN
  
  FOR C IN (SELECT CONSTRAINT_NAME NOME
                 , TABLE_NAME TABELA
                 , ('C') TIPO
              FROM USER_CONSTRAINTS
             WHERE TABLE_NAME = 'PCVIGENCIANTSEFAZ'
               AND INDEX_OWNER IS NOT NULL
               AND CONSTRAINT_TYPE <> 'P'
            UNION
            SELECT UI.INDEX_NAME NOME
                 , UI.TABLE_NAME TABELA
                 , ('I') TIPO
              FROM USER_INDEXES UI
             WHERE UI.UNIQUENESS = 'UNIQUE'
               AND UI.TABLE_NAME = 'PCVIGENCIANTSEFAZ'
               AND NOT EXISTS(
                      SELECT 1
                        FROM USER_CONSTRAINTS UC
                       WHERE UC.INDEX_NAME = UI.INDEX_NAME
                         AND UC.TABLE_NAME = 'PCVIGENCIANTSEFAZ'
                         AND UC.CONSTRAINT_TYPE IN('P', 'U'))) LOOP
			   
	  DELETE FROM PCVIGENCIANTSEFAZ;
	  COMMIT;
    
    IF (C.TIPO = 'C') THEN
      BEGIN
        EXECUTE IMMEDIATE 'ALTER TABLE ' || C.TABELA || ' DROP CONSTRAINT ' || C.NOME;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20001, 'Erro ao remover chave única da tabela PCVIGENCIANTSEFAZ: ' || sqlerrm);
      END;
    ELSIF (C.TIPO = 'I') THEN
      BEGIN
        EXECUTE IMMEDIATE 'DROP INDEX ' || C.NOME;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20001, 'Erro ao remover chave única da tabela PCVIGENCIANTSEFAZ: ' || sqlerrm);
      END;      
    END IF;
  END LOOP;
  
  BEGIN
    EXECUTE IMMEDIATE 'ALTER TABLE PCVIGENCIANTSEFAZ ADD CONSTRAINT PCVIGENCIANTSEFAZ_UK1 UNIQUE (IDENTIFICADOR_NT, UF, AMBIENTE)';
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20001, 'Erro ao criar chave composta na tabela PCVIGENCIANTSEFAZ: ' || sqlerrm);
  END;
END;
