CREATE OR REPLACE PACKAGE INTEGRACAOSERVINTERMEDIARIO
IS
   -- Cadastros
   PROCEDURE executar_importacao (
      pscodfilial   IN       VARCHAR2,
      psmensagem    OUT      VARCHAR2
   );

   -- Vendas/Cancelamentos/Sangria-Suprimento/Reducoes
   PROCEDURE executar_exportacao (
      pscodfilial   IN       VARCHAR2,
      psmensagem    OUT      VARCHAR2
   );

   -- Importar arquivos de retorno
   PROCEDURE executar_retorno (
      pscodfilial   IN       VARCHAR2,
      psmensagem    OUT      VARCHAR2
   );

   PROCEDURE exportar_vendas (pscodfilial IN VARCHAR2, psmensagem OUT VARCHAR2);

   PROCEDURE exportar_cancelamentos (
      pscodfilial   IN       VARCHAR2,
      psmensagem    OUT      VARCHAR2
   );

   PROCEDURE exportar_sangrias (
      pscodfilial   IN       VARCHAR2,
      psmensagem    OUT      VARCHAR2
   );

   PROCEDURE exportar_reducoes (pscodfilial VARCHAR2, psmensagem OUT VARCHAR2);

   -- Parametro de Dias
   vgnumdias   NUMBER (4)         DEFAULT 3;
   -- Arquivo de Log
   vgarqlog    UTL_FILE.file_type;
END;                                                           -- Package spec

