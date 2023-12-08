DECLARE
   V_EXISTE ALL_TYPES.TYPE_NAME%TYPE;
BEGIN
   SELECT T.TYPE_NAME
     INTO V_EXISTE
     FROM ALL_TYPES T
    WHERE T.TYPE_NAME = 'TABELA_CTE_INFO_NOTA'
      AND OWNER = SYS_CONTEXT('USERENV', 'SESSION_USER');
   IF NOT V_EXISTE IS NULL THEN
      EXECUTE IMMEDIATE 'DROP TYPE TABELA_CTE_INFO_NOTA';
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      V_EXISTE := NULL;
END;
\
CREATE OR REPLACE TYPE TIPO_CTE_INFO_NOTA AS OBJECT
  (
     DOCUMENTO_ORIGINARIO                     NUMBER,
     CNPJ                                     VARCHAR2(18),
     PIN_SUFRAMA                              VARCHAR2(9),
     CHAVENFE                                 VARCHAR2(44),
     DESCRICAO_OUTROS                         VARCHAR2(20),
     NUMERO_DOCUMENTO                         NUMBER,
     DATA_EMISSAO                             DATE,    
     VALOR_DOCUMENTO                          NUMBER,
     SERIE                                    VARCHAR2(3),
     CLIENTE                                  VARCHAR2(60),
     ENDERECO                                 VARCHAR2(255)
  );
\
CREATE OR REPLACE TYPE TABELA_CTE_INFO_NOTA IS TABLE OF TIPO_CTE_INFO_NOTA;