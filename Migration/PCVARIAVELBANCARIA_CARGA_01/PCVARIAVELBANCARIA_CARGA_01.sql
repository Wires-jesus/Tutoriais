DECLARE
  contador INT;
  
BEGIN
    SELECT COUNT(*)
    INTO contador
    FROM pcvariavelbancaria
    where nome = 'NOSSONUMERO_NUMERICO';
    IF contador = 0 THEN
        BEGIN
          insert into PCVARIAVELBANCARIA
            (CODIGO,
             NOME,
             DESCRICAO,
             TIPOVARIAVEL,
             TIPODADOS,
             TIPOCONTEUDO,
             STATUS,
             CONTEUDO,
             FINALIDADE,
             PROCESSO)
          values
            ((select max(codigo) + 1 from PCVARIAVELBANCARIA),
             'NOSSONUMERO_NUMERICO',
             'Identificação do título no banco - Tipo Númerico',
             'PADRAO',
             'INTEIRO',
             'TABELA',
             'VALIDO',
             null,
             'RETORNO',
             'CONTAS_RECEBER');
       END;
   END IF;
END;