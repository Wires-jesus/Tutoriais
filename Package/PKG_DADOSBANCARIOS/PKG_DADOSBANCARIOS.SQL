CREATE OR REPLACE PACKAGE PKG_DADOSBANCARIOS IS

  TYPE CONSULTA_BANCO IS RECORD(NUMBANCO                       PCBANCO.NUMBANCO%TYPE,
                                PROXNOSSONUMBCO                PCBANCO.PROXNOSSONUMBCO%TYPE,
                                NUMCONVENIO                    PCBANCO.NUMCONVENIO%TYPE,
                                NUMCARTEIRA                    PCBANCO.NUMCARTEIRA%TYPE,
                                TIPOCOB                        PCBANCO.TIPOCOB%TYPE,
                                FAIXAINI                       PCBANCO.FAIXAINI%TYPE,
                                FAIXAFIM                       PCBANCO.FAIXAFIM%TYPE,
                                AGENCIA                        PCBANCO.AGENCIA%TYPE,
                                CONTA                          PCBANCO.CONTA%TYPE,
                                CODCLIENTENOBANCO              PCBANCO.CODCLIENTENOBANCO%TYPE,
                                CODCEDENTE                     PCBANCO.CODCEDENTE%TYPE,
                                NUMCARTEIRA3                   PCBANCO.NUMCARTEIRA3%TYPE,
                                NOSSONUMBCO17DIGCOBCEFSIGCBREG PCBANCO.NOSSONUMBCO17DIGCOBCEFSIGCBREG%TYPE);                                
  BANCO CONSULTA_BANCO;

  TYPE CONSULTA IS RECORD (CODFILIAL     PCPREST.CODFILIAL%TYPE,
                           CODCLI        PCCLIENT.CODCLI%TYPE,
                           NUMTRANSVENDA PCPREST.NUMTRANSVENDA%TYPE,
                           DUPLIC        PCPREST.DUPLIC%TYPE,
                           PREST         PCPREST.PREST%TYPE,
                           DTDESCONTO    PCPREST.DTVENC%TYPE,
                           VALOR         PCPREST.VALOR%TYPE,
                           VALORDESC     PCPREST.VALORDESC%TYPE,
                           VALOR_TEMP    NUMBER(22,2),
                           VLTXVENDOR    NUMBER(22,2),
                           VLTXIOF       PCPREST.VLTXIOF%TYPE,
                           DTVENC        PCPREST.DTVENC%TYPE,
                           VLDEVOL       PCPREST.VLDEVOL%TYPE,
                           VALORBRUTO    PCPREST.VALOR%TYPE,
                           VLTXBOLETO    PCPREST.VLTXBOLETO%TYPE,
                           NOSSONUMERO   PCPREST.NOSSONUMBCO%TYPE,
                           CLIENTE       PCCLIENT.CLIENTE%TYPE);
  TITULOS CONSULTA;

  FUNCTION F_LERPROXIMONOSSONUMERO(PN_CODBANCO IN NUMBER,
                                   PS_MSGERRO OUT VARCHAR2) RETURN NUMBER;

  PROCEDURE P_GERADADOSBANCARIOS(PS_CODFILIAL         IN VARCHAR2,
                                 PS_CODCOBRANCA       IN VARCHAR2,
                                 PN_CODBANCO          IN NUMBER,
                                 PN_NUMTRANSVENDA     IN NUMBER,
                                 PN_NUMDIASPROTESTO   IN NUMBER,
                                 PS_PREST             IN VARCHAR2,
                                 PS_FILIALVIRTUAL     IN VARCHAR2 DEFAULT 'N',
                                 PS_UTILIZAVALORBRUTO IN VARCHAR2 DEFAULT 'N',
                                 PS_PRIMEIRAIMPRESSAO IN VARCHAR2 DEFAULT 'S',
                                 PS_SOMACUSTOCARTORIO IN NUMBER DEFAULT 0);
END PKG_DADOSBANCARIOS;