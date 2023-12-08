DECLARE
   V_EXISTE ALL_TYPES.TYPE_NAME%TYPE;
BEGIN
   SELECT T.TYPE_NAME
     INTO V_EXISTE
     FROM ALL_TYPES T
    WHERE T.TYPE_NAME = 'TABELA_CTE_EXPEDIDOR'
      AND OWNER = SYS_CONTEXT('USERENV', 'SESSION_USER');
   IF NOT V_EXISTE IS NULL THEN
      EXECUTE IMMEDIATE 'DROP TYPE TABELA_CTE_EXPEDIDOR';
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      V_EXISTE := NULL;
END;
\
CREATE OR REPLACE TYPE TIPO_CTE_EXPEDIDOR AS OBJECT
  (
     CNPJ                                     VARCHAR2(18),
     INSCRICAO_ESTADUAL                       VARCHAR2(20),
     RAZAO_SOCIAL                             VARCHAR2(60),
     NOME_FANTASIA                            VARCHAR2(60),
     LOGRADOURO                               VARCHAR2(60),
     NUMERO                                   VARCHAR2(60),
     COMPLEMENTO                              VARCHAR2(60),
     BAIRRO                                   VARCHAR2(60),
     CODIGO_MUNICIPIO                         NUMBER,
     NOME_MUNICIPIO                           VARCHAR2(80),
     CEP                                      VARCHAR2(10),
     SIGLA_UF                                 VARCHAR2(2),
     CODIGO_PAIS                              NUMBER,
     NOME_PAIS                                VARCHAR2(60),
     TELEFONE                                 VARCHAR2(20),
     SERIALCERTIFICADO                        VARCHAR2(50),
     PINCERTIFICADO                           VARCHAR2(50),
     PROVIDERCERTIFICADOA3                    VARCHAR2(50),
     TIPOPROVIDERA3                           NUMBER, 
     CONTRIBUINTE VARCHAR2(1)
  );
\
CREATE OR REPLACE TYPE TABELA_CTE_EXPEDIDOR IS TABLE OF TIPO_CTE_EXPEDIDOR;