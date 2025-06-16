BEGIN
  UPDATE PCMETAPARAMFILIAL
    SET PCMETAPARAMFILIAL.TITULO = 'OBSOLETO - Horario de processamento de status para bolepix gerado '
      , PCMETAPARAMFILIAL.TEXTOAJUDA = 'Parâmetro obsoleto. Favor ajustar no parâmetro CON_TEMPOEXECUCAOBAIXABOLEPIX o tempo de execução do processamento automatizado.'
  WHERE NOME = 'HORARIOPROCESSABOLEPIX'
   AND ID = 4747;   
 COMMIT;
END;