DECLARE
  VSCRIPT VARCHAR2(4000);
BEGIN

  FOR TRGS IN (SELECT *
                 FROM USER_TRIGGERS T
                WHERE T.trigger_name IN
                      ('TRG_SRVPRC_PCPRECOPROM',
                       'TRG_SRVPRC_PCTABPR',
                       'TRG_SRVPRC_PCPRODUT',
                       'TRG_SRVPRC_PCEST',
                       'TRG_SRVPRC_PCEMBALAGEM',
                       'TRG_SRVPRC_PCEMBALAGEM',
                       'TRG_SRVPRC_PCFORNEC')) LOOP
    VSCRIPT := 'DROP TRIGGER ' || TRGS.TABLE_OWNER || '.' ||
               TRGS.TRIGGER_NAME || ' ';
    EXECUTE IMMEDIATE VSCRIPT;
  END LOOP;

END;