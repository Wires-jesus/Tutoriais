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