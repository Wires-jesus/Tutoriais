DECLARE

  TYPE t_trigger_list IS TABLE OF VARCHAR2(30);
  v_triggers t_trigger_list := t_trigger_list('TRG_WMSSAAS_PCBONUSC');
  v_exists   NUMBER;

BEGIN
  FOR i IN 1 .. v_triggers.COUNT LOOP
  
    SELECT COUNT(*)
      INTO v_exists
      FROM ALL_TRIGGERS
     WHERE TRIGGER_NAME = v_triggers(i);
  
    IF v_exists > 0 THEN
      EXECUTE IMMEDIATE 'DROP TRIGGER ' || v_triggers(i);
    END IF;
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;