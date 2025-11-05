DECLARE
    v_count NUMBER;
BEGIN
    -- Verificar se a coluna DTCANCEL existe na tabela PCROTACOMPRAMOV
    SELECT COUNT(*) INTO v_count
      FROM user_tab_columns
     WHERE table_name = 'PCROTACOMPRAMOV'
       AND column_name = 'DTCANCEL';

    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE PCROTACOMPRAMOV DROP COLUMN DTCANCEL';
        COMMIT;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;