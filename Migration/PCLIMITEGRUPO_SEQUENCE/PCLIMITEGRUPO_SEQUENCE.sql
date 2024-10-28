DECLARE
  v_sequence_name VARCHAR2(30); 
  V_START number(6);
  v_sequence_exist number(1);
BEGIN
  V_START := 1;
  v_sequence_name := 'DFSEQ_PCLIMITEGRUPO';
    v_sequence_exist := 0;
  BEGIN
    SELECT count(1)
    INTO v_sequence_exist
    FROM user_sequences
    WHERE sequence_name = v_sequence_name;
  EXCEPTION
      when others then
      v_sequence_exist := 0;
  END;
    IF v_sequence_exist = 0 THEN
    BEGIN
      SELECT NVL((MAX(TO_NUMBER(CODENDENTCLI)) + 1), 1) VALOR
      INTO V_START
      FROM PCCLIENTENDENT;
    EXCEPTION
        when others THEN
          V_START := 1;
    END;
    BEGIN
        EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || v_sequence_name ||
                           ' INCREMENT BY 1 ' ||
                           ' START WITH 1 ';
    END;
        DBMS_OUTPUT.PUT_LINE('Sequence '|| v_sequence_name ||' foi criada');
    ELSE
      DBMS_OUTPUT.PUT_LINE('Sequence '|| v_sequence_name ||' ja existe');
  END IF; 
END;

