CREATE OR REPLACE PACKAGE PKG_RECEBIMENTOANTECIPADO IS

    --------------------- DADOS PCPRESTANTECIPADA ------------------------------
    TYPE T_PCPRESTANTECIPADA IS RECORD(
        NUMTRANSPAGADIANTADO    PCPRESTANTECIPADA.NUMTRANSPAGADIANTADO%TYPE,
        CODCLI                  PCPRESTANTECIPADA.CODCLI%TYPE,
        CODFILIAL               PCPRESTANTECIPADA.CODFILIAL%TYPE,
        NUMPED                  PCPRESTANTECIPADA.NUMPED%TYPE,
        NUMORCA                 PCPRESTANTECIPADA.NUMORCA%TYPE,
        COBANTECIPADA           PCPRESTANTECIPADA.COBANTECIPADA%TYPE,
        QUITAPCPREST            PCPRESTANTECIPADA.QUITAPCPREST%TYPE,
        VALOR                   PCPRESTANTECIPADA.VALOR%TYPE,
        VLRCREDITOABATIDO       PCPRESTANTECIPADA.VLRCREDITOABATIDO%TYPE,
        VALORPEDIDO             PCPRESTANTECIPADA.VALORPEDIDO%TYPE,
        CODCOBPGTO              PCPRESTANTECIPADA.CODCOBPGTO%TYPE,
        STATUSPGTO              PCPRESTANTECIPADA.STATUSPGTO%TYPE,
        DTEMISSAOPED            PCPRESTANTECIPADA.DTEMISSAOPED%TYPE,
        DTGERACAOPGTO           PCPRESTANTECIPADA.DTGERACAOPGTO%TYPE,
        DTCONFIRMACAOPGTO       PCPRESTANTECIPADA.DTCONFIRMACAOPGTO%TYPE,
        DTPGTO                  PCPRESTANTECIPADA.DTPGTO%TYPE,
        DTESTORNO               PCPRESTANTECIPADA.DTESTORNO%TYPE,
        NUMTRANSESTORNO         PCPRESTANTECIPADA.NUMTRANSESTORNO%TYPE,
        MATRICULAGERACAO        PCPRESTANTECIPADA.MATRICULAGERACAO%TYPE,
        MATRICULACONFIRMACAO    PCPRESTANTECIPADA.MATRICULACONFIRMACAO%TYPE,
        MATRICULAESTORNO        PCPRESTANTECIPADA.MATRICULAESTORNO%TYPE
    );

    TYPE TB_PCPRESTANTECIPADA IS TABLE OF T_PCPRESTANTECIPADA;
    ----------------------------------------------------------------------------

    FUNCTION CONSULTA_PAGANTECIPADO(PMENSAGEM   OUT VARCHAR2,
									PCODFILIAL  PCPRESTANTECIPADA.CODFILIAL%TYPE,
                                    PCODCLI     PCPRESTANTECIPADA.CODCLI%TYPE,
                                    PNUMPED     PCPRESTANTECIPADA.NUMPED%TYPE
                                    )
    RETURN TB_PCPRESTANTECIPADA
    PIPELINED;
    ----------------------------------------------------------------------------

    FUNCTION CONSULTA_STATUS(PMENSAGEM   OUT VARCHAR2,
							 PCODFILIAL  PCPRESTANTECIPADA.CODFILIAL%TYPE,
                             PCODCLI     PCPRESTANTECIPADA.CODCLI%TYPE,
                             PNUMPED     PCPRESTANTECIPADA.NUMPED%TYPE
                             )
    RETURN TB_PCPRESTANTECIPADA
    PIPELINED;
    ----------------------------------------------------------------------------

    PROCEDURE SOLICITA_CANCELAMENTO(PMENSAGEM              OUT VARCHAR2,
                                    PNUMTRANSPAGADIANTADO  PCPRESTANTECIPADA.NUMTRANSPAGADIANTADO%TYPE,
                                    PMATRICULA             PCPRESTANTECIPADA.MATRICULAESTORNO%TYPE);

    ----------------------------------------------------------------------------

    PROCEDURE ATUALIZAR_STATUS(PMENSAGEM              OUT VARCHAR2,
                               PNUMTRANSPAGADIANTADO  PCPRESTANTECIPADA.NUMTRANSPAGADIANTADO%TYPE,
                               PMATRICULA             PCPRESTANTECIPADA.MATRICULACONFIRMACAO%TYPE);
    ----------------------------------------------------------------------------

    PROCEDURE CRIAR_RECEB_ANTECIPADO(PSTATUS                OUT VARCHAR2,
                                     PMENSAGEM              OUT VARCHAR2,
                                     PNUMTRANSPAGOADIANTADO OUT PCPRESTANTECIPADA.NUMTRANSPAGADIANTADO%TYPE,
                                     PCODIGO                OUT PCCRECLI.CODIGO%TYPE,
                                     PNUMTRANS              OUT PCMOVCR.NUMTRANS%TYPE,

                                     PCODCLI                 IN PCPRESTANTECIPADA.CODCLI%TYPE,
                                     PNUMPED                 IN PCPRESTANTECIPADA.NUMPED%TYPE,
                                     PVALOR                  IN PCPRESTANTECIPADA.VALOR%TYPE,
                                     PCODFILIAL              IN PCPRESTANTECIPADA.CODFILIAL%TYPE,
                                     PVALORPEDIDO            IN PCPRESTANTECIPADA.VALORPEDIDO%TYPE,
                                     PCODCOBPGTO             IN PCPRESTANTECIPADA.CODCOBPGTO%TYPE,
                                     PDTEMISSAOPED           IN PCPRESTANTECIPADA.DTEMISSAOPED%TYPE,
                                     PDTGERACAOPGTO          IN PCPRESTANTECIPADA.DTGERACAOPGTO%TYPE,
                                     PDTCONFIRMACAOPGTO      IN PCPRESTANTECIPADA.DTCONFIRMACAOPGTO%TYPE,
                                     PDTPGTO                 IN PCPRESTANTECIPADA.DTPGTO%TYPE,
                                     PMATRICULAGERACAO       IN PCPRESTANTECIPADA.MATRICULAGERACAO%TYPE,
                                     PMATRICULACONFIRMACAO   IN PCPRESTANTECIPADA.MATRICULACONFIRMACAO%TYPE,

                                     PNSUTEF                 IN PCPRESTANTECIPADA.NSUTEF%TYPE DEFAULT NULL,
                                     PNSUHOST                IN PCPRESTANTECIPADA.NSUHOST%TYPE DEFAULT NULL,
                                     PCODREDE                IN PCPRESTANTECIPADA.CODREDE%TYPE DEFAULT NULL,
                                     PQTDPARCELATEF          IN PCPRESTANTECIPADA.QTDPARCELATEF%TYPE DEFAULT NULL,
                                     PNOME_CARTEIRA_DIGITAL  IN PCPRESTANTECIPADA.NOME_CARTEIRA_DIGITAL%TYPE DEFAULT NULL,
                                     PCODADMINISTRADORA      IN PCPRESTANTECIPADA.CODADMINISTRADORA%TYPE DEFAULT NULL,
                                     PCODBANDEIRA            IN PCPRESTANTECIPADA.CODBANDEIRA%TYPE DEFAULT NULL,
                                     PNUMTRANSPAGDIGITAL     IN PCPRESTANTECIPADA.NUMTRANSPAGDIGITAL%TYPE DEFAULT NULL,
                                     PNUMCAIXAFISCAL         IN PCPRESTANTECIPADA.NUMCAIXAFISCAL%TYPE DEFAULT NULL,
                                     PCODFUNCCHECKOUT        IN PCPRESTANTECIPADA.CODFUNCCHECKOUT%TYPE DEFAULT NULL,
                                     PNUMCAIXA               IN PCPRESTANTECIPADA.NUMCAIXA%TYPE DEFAULT NULL,
                                     PQUITAPCPREST           IN PCPRESTANTECIPADA.QUITAPCPREST%TYPE DEFAULT 'S',
                                     PEXECUTACOMMITROLLBACK  IN VARCHAR2 DEFAULT 'S'
                                    );
    ----------------------------------------------------------------------------

    PROCEDURE ESTORNO_RECEBIMENTO(PMENSAGEM              OUT VARCHAR2,
                                  PNUMTRANSPAGADIANTADO  PCPRESTANTECIPADA.NUMTRANSPAGADIANTADO%TYPE,
                                  PMATRICULA             PCPRESTANTECIPADA.MATRICULACONFIRMACAO%TYPE);
    ----------------------------------------------------------------------------

    PROCEDURE ESTORNAR_RECEB_ANTECIPADO(PSTATUS                OUT VARCHAR2,
                                        PMENSAGEM              OUT VARCHAR2,

                                        PCODCLI                 IN PCPRESTANTECIPADA.CODCLI%TYPE,
                                        PNUMPED                 IN PCPRESTANTECIPADA.NUMPED%TYPE,
                                        PVALOR                  IN PCPRESTANTECIPADA.VALOR%TYPE,
                                        PNUMTRANSPAGOADIANTADO  IN PCPRESTANTECIPADA.NUMTRANSPAGADIANTADO%TYPE,
                                        PMATRICULAESTORNO       IN PCPRESTANTECIPADA.MATRICULAESTORNO%TYPE,
                                        PEXECUTACOMMITROLLBACK  IN VARCHAR2 DEFAULT 'S'
                                        );
    ----------------------------------------------------------------------------

END PKG_RECEBIMENTOANTECIPADO;