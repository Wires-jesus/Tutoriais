DECLARE
  vnExisteColuna NUMBER;
  vsExec         VARCHAR2(1000);
  vsSchemaName   VARCHAR2(1000);
BEGIN
  SELECT SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')
    INTO vsSchemaName
    FROM DUAL;

  vnExisteColuna := 0;
  SELECT COUNT(1)
    INTO vnExisteColuna
    FROM ALL_TAB_COLUMNS C
   WHERE C.TABLE_NAME = 'PCDEPARAPRODC5'
     AND C.COLUMN_NAME = 'CODFILIAL'
     AND C.OWNER = vsSchemaName;

  if vnExisteColuna > 0 then
    vsExec := 'ALTER TABLE ' || vsSchemaName ||
              '.PCDEPARAPRODC5 DROP COLUMN CODFILIAL';
    EXECUTE IMMEDIATE vsExec;
  end if;
END;