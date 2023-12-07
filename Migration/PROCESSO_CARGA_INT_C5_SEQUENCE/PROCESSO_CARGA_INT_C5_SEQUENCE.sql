DECLARE
  vnContSeq NUMBER;
  vScript VARCHAR2(4000);
BEGIN

  BEGIN
    SELECT COUNT(1)
    INTO vnContSeq
    FROM ALL_SEQUENCES A
    WHERE A.SEQUENCE_NAME = 'DFSEQ_INT_C5_PRODPRECOAPARTIR';
  END;
     
  IF vnContSeq = 0  THEN
     vScript := ' CREATE SEQUENCE DFSEQ_INT_C5_PRODPRECOAPARTIR minvalue 1 maxvalue 999999999999999999999999999 start with 1 increment by 1 nocache';
     execute immediate vscript;  
  END IF;
    
  BEGIN
    SELECT COUNT(1)
    INTO vnContSeq
    FROM ALL_SEQUENCES A
    WHERE A.SEQUENCE_NAME = 'DFSEQ_INT_C5_REGRAINCENTIVO';
  END;
     
  IF vnContSeq = 0  THEN
     vScript := ' CREATE SEQUENCE DFSEQ_INT_C5_REGRAINCENTIVO minvalue 1 maxvalue 999999999999999999999999999 start with 1 increment by 1 nocache';
     execute immediate vscript;  
  END IF;
  
END;                