DECLARE
 VSCRIPT VARCHAR2(4000);
BEGIN

  FOR SEQUENCES IN (SELECT CACHE_SIZE,
                           LAST_NUMBER,
                           SEQUENCE_NAME,
                           MIN_VALUE,
                           MAX_VALUE
                      FROM USER_SEQUENCES S
                     WHERE S.sequence_name IN
                           ('DFSEQ_PCDEPARACATEGORIAC5',
                            'DFSEQ_PCDEPARAEMBALAGENSC5',
                            'DFSEQ_PCDEPARAPLPAGC5',
                            'DFSEQ_PCDEPARAREGIAOC5')) LOOP
                            
  IF SEQUENCES.CACHE_SIZE > 0 THEN
    vscript := 'DROP SEQUENCE '|| SEQUENCES.SEQUENCE_NAME ||' ';
    execute immediate vscript;
    VSCRIPT :=  'CREATE SEQUENCE '|| SEQUENCES.SEQUENCE_NAME || ' minvalue 1 maxvalue 999999999999999999999999999 start with ' || TO_CHAR(SEQUENCES.LAST_NUMBER +1) || ' increment by 1 nocache';
    execute immediate vscript;
  END IF;                          
                            
  END LOOP;

END;

