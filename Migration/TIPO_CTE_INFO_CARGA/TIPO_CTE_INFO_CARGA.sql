DECLARE
   V_EXISTE ALL_TYPES.TYPE_NAME%TYPE;
BEGIN
   SELECT T.TYPE_NAME
     INTO V_EXISTE
     FROM ALL_TYPES T
    WHERE T.TYPE_NAME = 'TABELA_CTE_INFO_CARGA'
      AND OWNER = SYS_CONTEXT('USERENV', 'SESSION_USER');
   IF NOT V_EXISTE IS NULL THEN
      EXECUTE IMMEDIATE 'DROP TYPE TABELA_CTE_INFO_CARGA';
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      V_EXISTE := NULL;
END;
\
CREATE OR REPLACE TYPE TIPO_CTE_INFO_CARGA AS OBJECT
  (
     VALOR_TOTAL_MERCADORIA                NUMBER,
     PRODUTO_PREDOMINANTE                  VARCHAR2(60),
     OUTRAS_CARACTERISTICAS_CARGA          VARCHAR2(30),
     CODIGO_UNIDADE                        VARCHAR2(2),
     TIPO_MEDIDA                           VARCHAR2(20),
     QUANTIDADE_CARGA                      NUMBER(11,4),
     CUBAGEM                               NUMBER(12,6),
     VALOR_PESO_BRUTO                      NUMBER(13,6),
     RNTRC                                 VARCHAR(30),
     DATA_PREVISTA_ENTREGA                 DATE,
     LOTACAO                               NUMBER,
     NUMONUCARGA                           VARCHAR2(4),
     NOMEAPROPRIADOCARGA                   VARCHAR2(150),
     DIVISAOCARGA                          VARCHAR2(40),
     GRUPOEMBCARGA                         VARCHAR2(6),
     QTDTOTALPRODCARGA                     VARCHAR2(60),
     PONTOFUGORCARGA                       VARCHAR2(6),
     CNPJFORNEC                            VARCHAR2(18),
     NUMCOMPROVANTE                        NUMBER(10),
     CNPJRESPONSAVEL                       VARCHAR2(18),
     RESPSEGURO                            NUMBER(1),
     NOMESEGURADORA                        VARCHAR2(30),
     NUMEROAPOLICE                         VARCHAR2(20),
     NUMEROAVERBACAO                       VARCHAR2(40),
     VLVALEPEDAGIO                         NUMBER(13,2)
  );
\
CREATE OR REPLACE TYPE TABELA_CTE_INFO_CARGA IS TABLE OF TIPO_CTE_INFO_CARGA;