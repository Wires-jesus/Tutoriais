CREATE OR REPLACE PACKAGE PKG_CONTABILIZALANCAMENTOS IS

  PROCEDURE GRAVARLANCAMENTOS(PCODFILIAL        IN VARCHAR2,
                              PCODREGRA         IN NUMBER,
                              PDTINICIO         IN DATE,
                              PDTFINAL          IN DATE,
                              PCODPLANOCONTA    IN NUMBER,
                              PCODFUNCLOGADO    IN NUMBER,
                              PGERAADVERTENCIAS IN VARCHAR2,
                              PCONSOLIDAR       IN VARCHAR2,
                              RESULTADO         OUT VARCHAR2);

END PKG_CONTABILIZALANCAMENTOS;
