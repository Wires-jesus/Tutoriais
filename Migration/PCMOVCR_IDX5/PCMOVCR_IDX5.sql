declare 
  vContIdx NUMBER;
  vContPk NUMBER;
  vEXEC    VARCHAR2(4000);  
begin
  vContIdx := 0;
  vContPk  := 0;
  vEXEC    := '';  
  SELECT COUNT(1)
    INTO vContIdx
    FROM USER_INDEXES I
  WHERE I.TABLE_NAME = 'PCMOVCR' AND I.INDEX_NAME = 'PCMOVCR_IDX5';

  select count(1) 
    INTO vContPk
    from user_constraints where constraint_name = 'PCMOVCR_IDX5';

  IF (vContIdx > 0) AND (vContPk = 0) THEN
    vEXEC := 'CREATE INDEX PCMOVCR_IDX_5 ON PCMOVCR (TRUNC(DTCONCIL))';
  ELSE
    vEXEC := 'CREATE INDEX PCMOVCR_IDX5 ON PCMOVCR (TRUNC(DTCONCIL))';
  END IF;
  
  EXECUTE IMMEDIATE vEXEC;
  
EXCEPTION
    WHEN OTHERS THEN
      NULL;
end;