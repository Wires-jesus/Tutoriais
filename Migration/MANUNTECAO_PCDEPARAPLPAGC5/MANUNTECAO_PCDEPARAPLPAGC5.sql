DECLARE
  vExisteSeqCategoriaWinthor char(1) := 'N'; 
  vExisteSeqCategoriaC5 char(1):= 'N';
BEGIN
  SELECT case  when count(*) > 0 then 'S' else 'N' end
  INTO vExisteSeqCategoriaWinthor
  FROM USER_TAB_COLS
  WHERE 
    TABLE_NAME = 'PCDEPARAPLPAGC5'
    AND COLUMN_NAME = 'SEQCATEGORIAWINTHOR';
  
  
  IF vExisteSeqCategoriaWinthor = 'S' THEN
     execute immediate 'ALTER TABLE PCDEPARAPLPAGC5 DROP (SEQCATEGORIAWINTHOR)';
  END IF;
  
  SELECT case  when count(*) > 0 then 'S' else 'N' end
  INTO vExisteSeqCategoriaC5
  FROM USER_TAB_COLS
  WHERE 
    TABLE_NAME = 'PCDEPARAPLPAGC5'
    AND COLUMN_NAME = 'SEQCATEGORIAC5';
    
  IF vExisteSeqCategoriaC5 = 'S' THEN
     execute immediate 'ALTER TABLE PCDEPARAPLPAGC5 DROP (SEQCATEGORIAC5)';
  END IF;

END;
