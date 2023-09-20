DECLARE
  vnContSeq NUMBER;
  vScript VARCHAR2(4000);
BEGIN

  BEGIN
    SELECT COUNT(1)
    INTO vnContSeq
    FROM ALL_SEQUENCES A
    WHERE A.SEQUENCE_NAME = 'DEFSEQ_NUMPEDECF';
  END;
     
  IF vnContSeq = 0  THEN
     vScript := ' CREATE SEQUENCE DEFSEQ_NUMPEDECF minvalue 1 maxvalue 999999999999999999999999999 start with 1 increment by 1 cache 20 ';
     execute immediate vscript;  
  END IF;
    
  BEGIN
    SELECT COUNT(1)
    INTO vnContSeq
    FROM ALL_SEQUENCES A
    WHERE A.SEQUENCE_NAME = 'DFSEQ_PCFILAMENSAGEM';
  END;
     
  IF vnContSeq = 0  THEN
     vScript := ' CREATE SEQUENCE DFSEQ_PCFILAMENSAGEM minvalue 1 maxvalue 999999999999999999999999999 start with 1 increment by 1 cache 20 ';
     execute immediate vscript;  
  END IF;
  
END;