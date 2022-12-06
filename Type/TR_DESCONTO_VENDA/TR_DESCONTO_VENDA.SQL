CREATE OR REPLACE TYPE FORCE tr_desconto_venda IS OBJECT( 
           msg                 VARCHAR2(1000),              
           codesconto          NUMBER,                      
           codescontobase      NUMBER,                      
           codescontoptabela   NUMBER,                      
           politicabasecredita VARCHAR2(1),                 
           politicabasedebita  VARCHAR2(1),                 
           percdescbase        NUMBER,                      
           datafinal           DATE,                        
           percdesc            NUMBER,                      
           percdescaut         NUMBER,                      
           ptabeladesc         NUMBER,                      
           pvendadesc          NUMBER,                      
           pbaserca            NUMBER,                      
           questionauso        VARCHAR2(1),                 
           alteraptabela       VARCHAR2(1),                 
           forcarutilizacao    VARCHAR2(1),                 
           percdescmax         NUMBER,                      
           datainicio          DATE,                        
           qtini               NUMBER,                      
           qtfim               NUMBER,                      
           vlrminimo           NUMBER,                      
           vlrmaximo           NUMBER);
/
CREATE OR REPLACE TYPE FORCE TD_DESCONTO_VENDA IS TABLE OF TR_DESCONTO_VENDA;
/
CREATE OR REPLACE TYPE FORCE TR_DESC_SIMUL IS OBJECT
(
  PERCATING    NUMBER(18, 6),
  PERCDESC     NUMBER(18, 6),
  CODDESCONTO  NUMBER(18, 6),
  DTINICIO     DATE,
  DTFIM        DATE,
  VLRMINIMO    NUMBER(18, 6),
  VLRMAXIMO    NUMBER(18, 6),
  CODEPTO      NUMBER(18, 6),
  CODCATEGORIA NUMBER(18, 6),
  SUBCATEGORIA NUMBER(18, 6),
  CODSEC       NUMBER(18, 6),
  CODFORNEC    NUMBER(18, 6),
  CODMARCA     NUMBER(18, 6),
  CODAUXILIAR  NUMBER(18, 6),
  CODPRODPRINC NUMBER(18, 6),
  PERDESCAPLIC NUMBER(18, 6),
  CLASSEPROD   VARCHAR2(2),
  PRODATEND    VARCHAR2(4000)
);
/
CREATE OR REPLACE TYPE FORCE TD_DESCONTO_SIMUL IS TABLE OF TR_DESC_SIMUL;
/
