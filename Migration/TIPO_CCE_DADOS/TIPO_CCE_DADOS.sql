DECLARE
   V_EXISTE ALL_TYPES.TYPE_NAME%TYPE;
BEGIN
   SELECT T.TYPE_NAME
     INTO V_EXISTE
     FROM ALL_TYPES T
    WHERE T.TYPE_NAME = 'TABELA_CCE_DADOS'
      AND OWNER = SYS_CONTEXT('USERENV', 'SESSION_USER');
   IF NOT V_EXISTE IS NULL THEN
      EXECUTE IMMEDIATE 'DROP TYPE TABELA_CCE_DADOS';
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      V_EXISTE := NULL;
END;
\
CREATE OR REPLACE TYPE TIPO_CCE_DADOS AS OBJECT
  (
     TIPO_AMBIENTE                            NUMBER,
     CNPJCPF                                  VARCHAR2(20),
     CODIGO_EMITENTE                          VARCHAR2(2),
     CHAVENFE                                 VARCHAR2(44),
     DATAHORAEVENTO                           DATE,
     SIGLA_UF_EMITENTE                        VARCHAR2(2),
     NUMTRANSACAO                             NUMBER(10),
     MOVIMENTO                                VARCHAR2(1),
     SERIALCERTIFICADO                        VARCHAR2(50),
     PINCERTIFICADO                           VARCHAR2(20),
     PROVIDERCERTIFICADOA3                    VARCHAR2(256),
     TIPOPROVIDERA3                           NUMBER,
     CONDICAOUSO                              VARCHAR(1000),
     CORRECAO                                 VARCHAR(1500),
     TIPO_CCE                                 NUMBER
  )