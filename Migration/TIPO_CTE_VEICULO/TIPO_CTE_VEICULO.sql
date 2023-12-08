DECLARE
   V_EXISTE ALL_TYPES.TYPE_NAME%TYPE;
BEGIN
   SELECT T.TYPE_NAME
     INTO V_EXISTE
     FROM ALL_TYPES T
    WHERE T.TYPE_NAME = 'TABELA_CTE_VEICULO'
      AND OWNER = SYS_CONTEXT('USERENV', 'SESSION_USER');
   IF NOT V_EXISTE IS NULL THEN
      EXECUTE IMMEDIATE 'DROP TYPE TABELA_CTE_VEICULO';
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      V_EXISTE := NULL;
END;
\
CREATE OR REPLACE TYPE TIPO_CTE_VEICULO AS OBJECT
  (
     CODVEICULO                            NUMBER,
     RENAVAM                               VARCHAR2(11),
     PLACA                                 VARCHAR2(10),
     TARA                                  NUMBER(10,2),
     CAPAC_VEICULO_KG                      NUMBER(10,2),
     CAPAC_VEICULO_M3                      NUMBER(10,4),
     TIPO_PROD_VEICULO                     NUMBER(1),
     TIPO_VEICULO                          VARCHAR2(2),
     TIPORODADO                            VARCHAR2(2),
     TIPOCARROCERIA                        VARCHAR2(2),
     UFPLACAVEICULO                        VARCHAR2(2),
     CGCCPFPROPRIETARIO                    VARCHAR2(15),
     NOMEPROPRIETARIO                      VARCHAR2(150),
     CODIGORNTRC                           VARCHAR2(30),
     IEPROPRIETARIO                        VARCHAR2(14),
     UFPROPRIETARIO                        VARCHAR2(2),
     TIPOPROPRIETARIO                      NUMBER(1),
     CPF_MOTORISTA                         VARCHAR2(20),
     NOME_MOTORISTA                        VARCHAR2(40)
  );
\
CREATE OR REPLACE TYPE TABELA_CTE_VEICULO IS TABLE OF TIPO_CTE_VEICULO;