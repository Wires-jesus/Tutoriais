BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name      => 'JOB_AJUSTE_DATA_PCMOV_PCNFSAID',
    job_type      => 'STORED_PROCEDURE',
    job_action    => 'PRC_AJUSTAR_DATA',
    start_date    => SYSTIMESTAMP,         -- Inicia imediatamente
	end_date      => SYSTIMESTAMP + INTERVAL '10' DAY,
    enabled       => TRUE,                 -- Habilita imediatamente
    auto_drop     => TRUE,                 -- Apaga o job automaticamente após execução
    comments      => 'Executa ajuste de data da nota fiscal de junho'
  );
END;