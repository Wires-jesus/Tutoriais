CREATE OR REPLACE PACKAGE PKG_DRECONTABIL IS

  FUNCTION FNC_RETORNADADOS(PCODFILIAL              IN VARCHAR2 DEFAULT NULL,
                            PCODPLANOCONTA          IN NUMBER,
                            PCODDRE                 IN NUMBER,
                            PMESINI                 IN NUMBER,
                            PMESFIM                 IN NUMBER,
                            PANO                    IN NUMBER,
                            PCONSOLIDAR             IN VARCHAR2 DEFAULT NULL,
                            PAGRUPAFILIAL           IN VARCHAR2 DEFAULT NULL,
                            PCONSIDERARSALDOINI     IN VARCHAR2,
                            PANTESDOENCERRAMENTO    IN VARCHAR2,
                            PANALISEHORIZONTAL      IN VARCHAR2,
                            PANALISEVERTICAL        IN VARCHAR2,
                            PEXIBIRCONTASANALITICAS IN VARCHAR2,
                            PEXIBIRCONTASSALDOZERO  IN VARCHAR2,
                            PEXIBIRCODREDUZIDO      IN VARCHAR2,
                            PEXIBIRRATEIO_RECEITA_CUSTO IN VARCHAR2,
							PSALDOANOANTERIOR         IN VARCHAR2 DEFAULT 'N',
						    PDATAINI_ESP              IN DATE DEFAULT NULL, 
							PDATAFIM_ESP              IN DATE DEFAULT NULL
                            )
    RETURN DRECONTABIL_DATATABLE;

END PKG_DRECONTABIL;