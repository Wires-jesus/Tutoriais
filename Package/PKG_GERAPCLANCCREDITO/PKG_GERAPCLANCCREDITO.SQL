CREATE OR REPLACE PACKAGE PKG_GERAPCLANCCREDITO IS

  T_TIPO_INSERCAO CONSTANT VARCHAR2(1) := 'I';
  T_TIPO_ESTORNO CONSTANT VARCHAR2(1) := 'E'; 

  PROCEDURE P_GERARLANCAMENTO(PS_CODFILIAL         IN VARCHAR2,
                              PN_CODCLI            IN NUMBER,                              
                              PN_VALOR             IN NUMBER,
                              PS_CODROTINA         IN VARCHAR2,
                              PN_MATRICULA         IN NUMBER,
                              PN_CODIGO            IN NUMBER,
                              PS_TIPO              IN VARCHAR2);
END PKG_GERAPCLANCCREDITO;