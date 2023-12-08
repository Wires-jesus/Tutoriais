DECLARE
   V_EXISTE ALL_TYPES.TYPE_NAME%TYPE;
BEGIN
   SELECT T.TYPE_NAME
     INTO V_EXISTE
     FROM ALL_TYPES T
    WHERE T.TYPE_NAME = 'TABELA_CTE_PARCELA'
      AND OWNER = SYS_CONTEXT('USERENV', 'SESSION_USER');
   IF NOT V_EXISTE IS NULL THEN
      EXECUTE IMMEDIATE 'DROP TYPE TABELA_CTE_PARCELA';
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      V_EXISTE := NULL;
END;
\
CREATE OR REPLACE TYPE TIPO_CTE_PARCELA AS OBJECT
  (
     NOME                               VARCHAR(60),
     PRESTACAO                          VARCHAR(60),
     VALOR                              NUMBER(13,2),
     VALORDESCONTO                      NUMBER(13,2),
     DATAVENCIMENTO                     DATE,
     CODCOB                             VARCHAR2(4),
     GRIS                               VARCHAR(60),
     VLGRIS                             NUMBER(13,2),
     PEDAGIO                            VARCHAR(60),
     VLDESPPEDAGIO                      NUMBER(13,2),
     TAS                                VARCHAR(60),
     VLTAS                              NUMBER(13,2),
     VLOUTRAS                           NUMBER(13,2),
     OUTRAS                             VARCHAR2(60),
     SEGURO                             VARCHAR2(60),
     VALOR_SEGURO                       NUMBER(13,2)
  );
\
CREATE OR REPLACE TYPE TABELA_CTE_PARCELA IS TABLE OF TIPO_CTE_PARCELA;