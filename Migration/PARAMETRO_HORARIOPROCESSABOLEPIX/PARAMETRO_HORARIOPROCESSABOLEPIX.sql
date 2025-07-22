BEGIN
  UPDATE PCMETAPARAMFILIAL
    SET PCMETAPARAMFILIAL.TITULO = 'Horario de processamento de status para bolepix gerado '
      , PCMETAPARAMFILIAL.TEXTOAJUDA = 'Horário que o Winthor processará as baixas dos bolepix caso o parâmetro CON_PROCESSABOLEPIX1XDIA(4858) esteja como "SIM".'
  WHERE NOME = 'HORARIOPROCESSABOLEPIX'
   AND ID = 4747;   
 COMMIT;
END;