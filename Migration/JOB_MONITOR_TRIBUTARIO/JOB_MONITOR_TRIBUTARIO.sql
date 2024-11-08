BEGIN
  DBMS_SCHEDULER.CREATE_JOB(
    job_name   => 'JOB_MONITOR_TRIBUTARIO',
    job_type   => 'PLSQL_BLOCK',
    job_action => 'BEGIN PKG_MONITOR_TRIBUTARIO.CRIAR_MONITOR_TRIBUTARIO; END;',
    start_date => SYSDATE,
    repeat_interval => 'FREQ=DAILY;BYHOUR=23;BYMINUTE=59',
    enabled    => TRUE
  );
END;