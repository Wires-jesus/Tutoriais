CREATE OR REPLACE PACKAGE PC_PKG_CONTROLASALDORCAFORNEC IS

/******************************************************************************************************
  29/01/2013 Marcos Garcia e Thiago Melo - Criação
******************************************************************************************************/

/*Procedure utilizada realizar a movimentação, a mesma não faz chamada da função que retorna o saldo
  disponivél, o saldo disponivél e feito dinamicamente.
*/
PROCEDURE PRC_MOVIMENTASALDORCAFORNEC(P_CODUSUR IN NUMBER,
                                      P_NUMPED IN NUMBER,
                                      P_CODROTINA IN
                                      PCROTINA.CODIGO%TYPE,
                                      P_CODFUNC IN
                                      PCEMPR.MATRICULA%TYPE,
                                      P_CODFILIAL IN
                                      VARCHAR2,
                                      P_MENSAGEM OUT VARCHAR2);


PROCEDURE PRC_VALIDAITEMSALDORCAFORNEC(P_CODUSUR   IN NUMBER,
                                 P_NUMPED    IN NUMBER,
                                 P_CODFORNEC IN NUMBER,
                                 P_CODPROD   IN NUMBER,
                                 P_NUMSEQ    IN NUMBER,
                                 P_NUMSEQANT IN NUMBER,
                                 P_PVENDA    IN NUMBER,
                                 P_PBASERCA  IN NUMBER,
                                 P_QT        IN NUMBER,
                                 P_CODROTINA IN PCROTINA.CODIGO%TYPE,
                                 P_CODFUNC   IN PCEMPR.MATRICULA%TYPE,
                                 P_CODFILIAL IN VARCHAR2,
                                 P_MENSAGEM  OUT VARCHAR2);

PROCEDURE PRC_ATUALIZA_MOVSALDORCAFORNEC(P_DATA_INICIO IN DATE);

PROCEDURE PRC_CANCELARITEM(P_CODUSUR   IN NUMBER,
                           P_NUMPED    IN NUMBER,
                           P_CODFORNEC IN NUMBER,
                           P_CODPROD   IN NUMBER,
                           P_NUMSEQ    IN NUMBER,
                           P_CODROTINA IN PCROTINA.CODIGO%TYPE,
                           P_CODFUNC   IN PCEMPR.MATRICULA%TYPE,
                           P_MENSAGEM  OUT VARCHAR2);

END;
