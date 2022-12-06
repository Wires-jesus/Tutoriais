CREATE OR REPLACE PACKAGE FERRAMENTAS IS

  --Versão 21 Pacote

  TYPE TR_DADOS_ICMS IS RECORD(
     NUMPED              PCPEDC.NUMPED%TYPE
    ,CODPROD             PCPEDI.CODPROD%TYPE
    ,NUMSEQ              PCPEDI.NUMSEQ%TYPE
    ,PERC_ICMS           PCMOV.PERCICM%TYPE
    ,VALOR_BASE          PCMOV.BASEICMS%TYPE
    ,VALOR_ICMS          PCMOVCOMPLE.VLICMS%TYPE
    ,PERC_BASE_RED       PCPEDI.PERCBASERED%TYPE
    ,PERC_ICMS_DIFERIDO  PCMOVCOMPLE.PERDIFEREIMENTOICMS%TYPE
    ,VALOR_ICMS_DIFERIDO PCMOVCOMPLE.VLICMSDIFERIDO%TYPE
    ,VALOR_FECP_ICMS     PCMOVCOMPLE.VLACRESCIMOFUNCEP%TYPE
    ,PERC_FECP_ICMS      PCMOVCOMPLE.PERACRESCIMOFUNCEP%TYPE
    ,BASE_FECP_ICMS      PCMOVCOMPLE.VLBASEFCPICMS%TYPE
    ,VLFCPDIF                  PCMOVCOMPLE.VLFCPDIF%TYPE
    );

  TYPE TB_DADOS_ICMS IS TABLE OF TR_DADOS_ICMS;

  ROWPCMOV      PCMOV%ROWTYPE;

  TYPE TR_LISTA IS RECORD
  (ITEM VARCHAR2(100));

  TYPE TD_LISTA IS TABLE OF TR_LISTA;

  PARAMETROS T_PC_PARAMETROS := T_PC_PARAMETROS('FERRAMENTAS');

  FUNCTION VERIFICAR_FJ(PCODCLI  NUMBER)
    RETURN VARCHAR2;

  FUNCTION VERIFICAR_ISENTOST (PCODCLI        NUMBER,
                               PCODPROD       NUMBER,
                               PCODST         NUMBER,
                               PTRANSFERENCIA VARCHAR2 DEFAULT 'N')
    RETURN VARCHAR2;

  FUNCTION VERIFICAR_TIPOST (PCODCLI  NUMBER,
                             PCODST   NUMBER)
    RETURN VARCHAR2;

  FUNCTION F_PROX_NUMCAR
    RETURN NUMBER;

  FUNCTION F_PROX_NUMTRANS
    RETURN NUMBER;

  FUNCTION F_PROX_NUMTRANSVENDA(P_INCREMENTO IN NUMBER DEFAULT 1)
    RETURN NUMBER;

  FUNCTION F_PROX_NUMTRANSENT(P_INCREMENTO IN NUMBER DEFAULT 1)
    RETURN NUMBER;

  FUNCTION F_PROX_RECNUM
    RETURN NUMBER;

  FUNCTION F_PROX_NUMPED(PCODUSUR NUMBER)
    RETURN NUMBER;

  FUNCTION F_PROX_CODCLI
    RETURN NUMBER;

  FUNCTION F_COMPARARCNPJ (PCODCLI1 NUMBER,
                           PCODCLI2 NUMBER)
    RETURN BOOLEAN;

  PROCEDURE Recontar_NUMSEQ(PNUMPED PCPEDC.NUMPED%TYPE);

  FUNCTION F_RETORNARLISTA(PLISTA     VARCHAR2,
                           PSEPARADOR VARCHAR2)
    RETURN TD_LISTA
    PARALLEL_ENABLE PIPELINED;

  FUNCTION F_BUSCARPARAMETRO_ALFA(PNOMEPARAM   IN VARCHAR2,
                                  PCODFILIAL   IN VARCHAR2,
                                  PVALORSENULO IN VARCHAR2)
    RETURN VARCHAR2;

  FUNCTION F_BUSCARPARAMETRO_NUM(PNOMEPARAM   IN VARCHAR2,
                                 PCODFILIAL   IN VARCHAR2,
                                 PVALORSENULO IN NUMBER)
   RETURN NUMBER;

  FUNCTION F_BUSCARPARAMETRO_DATA(PNOMEPARAM   IN VARCHAR2,
                                  PCODFILIAL   IN VARCHAR2,
                                  PVALORSENULO IN DATE)
   RETURN DATE;

   TYPE T_RAMO_ATIVIDADE IS RECORD(
    PercRedAliqIpi  PCATIVI.PERCREDALIQIPI%TYPE,
    CalculaSt       PCATIVI.CALCULAST%TYPE
   );

  type T_CLIENTE IS RECORD(
       CodCli                    PCCLIENT.CODCLI%TYPE,
       CodcliPrinc               PCCLIENT.CODCLIPRINC%TYPE,
       ClasseVenda               PCCLIENT.CLASSEVENDA%TYPE,
       TipoPessoa                PCCLIENT.TIPOFJ%TYPE,
       CodRede                   PCCLIENT.CODREDE%TYPE,
       CodAtiv1                  PCCLIENT.CODATV1%TYPE,
       SimplesNacional           PCCLIENT.SIMPLESNACIONAL%TYPE,
       NumRegiao                 PCCLIENT.NUMREGIAOCLI%TYPE,
       EstEnt                    PCCLIENT.estent%TYPE,
       CalculaSt                 PCCLIENT.calculast%TYPE,
       UsaivaFonteDiferenciado   PCCLIENT.Usaivafontediferenciado%TYPE,
       IvaFonte                  PCCLIENT.Ivafonte%TYPE,
       IEEnt                     PCCLIENT.ieent%TYPE,
       Utilizaiesimplificada     PCCLIENT.utilizaiesimplificada%TYPE,
       Isentoipi                 PCCLIENT.isentoipi%TYPE,
       Isentoicms                PCCLIENT.Isentoicms%TYPE,
       Sulframa                  PCCLIENT.sulframa%TYPE,
       IsencaoSuframa            PCCLIENT.ISENCAOSUFRAMA%TYPE,
       Contribuinte              PCCLIENT.contribuinte%TYPE,
       ConsumidorFinal           PCCLIENT.consumidorfinal%TYPE,
       UtilizaCalculoSTMT        PCCLIENT.UTILIZACALCULOSTMT%TYPE,
       TipoEmpresa               PCCLIENT.TIPOEMPRESA%TYPE,
       TipoDescIsencao           PCCLIENT.TIPODESCISENCAO%TYPE,
       PerDescIsentoICMS         PCCLIENT.PERDESCISENTOICMS%TYPE,
       OrgaoPub                  PCCLIENT.ORGAOPUB%TYPE,
       OrgaoPubFederal           PCCLIENT.ORGAOPUBFEDERAL%TYPE,
       UsaDescontoICMS           PCCLIENT.USADESCONTOICMS%TYPE,
       PessoaFisicaJuridica      VARCHAR2(60),
       CodCnae                   PCCLIENT.CODCNAE%TYPE,
       CodPraca                  PCCLIENT.CodPraca%TYPE,
       ClienteFonteST            PCCLIENT.ClienteFonteST%TYPE,
       RamoAtividade             T_RAMO_ATIVIDADE,
       CodFilialNf               PCCLIENT.codfilialnf%TYPE,
       RioLog                    PCCLIENT.RIOLOG%TYPE,
       CozinhaIndustrial         PCCLIENT.COZINHAINDUSTRIAL%TYPE,
       TipoDocumento             PCCLIENT.TIPODOCUMENTO%TYPE
       );

  

  FUNCTION BUSCAR_CLIENTE(pCodCli IN NUMBER, pCODFILIALNF IN VARCHAR2, pconsultardblink IN varchar2 DEFAULT 'N')
    RETURN T_CLIENTE;

  PROCEDURE DEFINIRCODFISCAL(T_PCPEDC    PCPEDC%ROWTYPE,
                             T_PCPEDI    PCPEDI%ROWTYPE,
                             P_CODFISCAL OUT NUMBER,
                             P_SITTRIBUT OUT VARCHAR2,
                             P_MSG       OUT VARCHAR2,
                             P_GERALOG   IN  VARCHAR2 DEFAULT 'N');

  PROCEDURE DEFINIR_TRIBUTOS(P_CODPROD       IN  NUMBER
                            ,P_CODFILIAL     IN  VARCHAR2
                            ,P_CODCLI        IN  NUMBER
                            ,P_CODST         IN  NUMBER
                            ,P_TRIBMUNICIPAL OUT NUMBER
                            ,P_TRIBESTADUAL  OUT NUMBER
                            ,P_TRIBFEDERAL   OUT NUMBER) ;

  FUNCTION RETORNAR_ICMS(P_NUMPED  IN NUMBER
                        ,P_GERALOG IN VARCHAR2 DEFAULT 'N'
                        ,P_CODPROD IN NUMBER DEFAULT 0
                        ,P_NUMSEQ  IN NUMBER DEFAULT 0) RETURN TB_DADOS_ICMS
  PIPELINED;

  FUNCTION RETORNAR_ROWTIPEPCMOV(P_ROWID  IN VARCHAR2) RETURN PCMOV%ROWTYPE;

  FUNCTION RETORNAR_DADOS_FABRICANTE(pCodprod          IN  number,
                                     pCodFilial        IN  VARCHAR2,
                                     rFabricante       OUT VARCHAR2,
                                     rCgcFabricante    OUT VARCHAR2,
                                     rRelevante        OUT varchar2,
                                     rMsg              OUT VARCHAR2) RETURN BOOLEAN;

  PROCEDURE GRAVARLOG(PPARAMS    IN OUT PCLOGIMPOSTOS%ROWTYPE
                     ,PSLINHAMSG IN VARCHAR2 DEFAULT '');
                     
  FUNCTION SONUMEROS(P_STRING in varchar) return varchar;
  
  PROCEDURE SET_GRAVARLOG(P_Valor in varchar2);
  
  FUNCTION GET_GRAVARLOG  return varchar2;
  
  FUNCTION CLIENTE_CALCULA_FUNCEP(P_CODIGOCLIENTE          IN NUMBER
                                 ,P_CODIGOFIGURATRIBUTARIA IN NUMBER
                                 ,P_MENSAGEM_RETORNO          OUT VARCHAR2)
  RETURN VARCHAR2;


  CURSOR ITENS_PEDIDO(P_NUMPED  NUMBER,
                      P_CODPROD NUMBER,
                      P_NUMSEQ  NUMBER) IS
  SELECT F.CODCLI CODCLI_FILIAL
                         ,F.CODFORNEC CODFORNEC_FILIAL
                         ,NVL(T.PERCBASEREDTRANFSAID, 100) PERCBASEREDTRANFSAID
                         ,NVL(CLI.ISENTOICMS, 'N') ISENTOICMS
                         ,PARAMETROS.GETVALORALFANVL('CON_USARTRIBUTACAOTRANSFTV10',
                                                         '99',
                                                         'N') CON_USARTRIBUTACAOTRANSFTV10
                         ,PARAMETROS.GETVALORALFANVL('CON_USARREDUCAOICMSABATRANSF',
                                                         '99',
                                                         'N') CON_USARREDUCAOICMSABATRANSF
                         ,PARAMETROS.GETVALORALFANVL('CON_UTILIZAPERCBASEREDPF',
                                                         '99',
                                                         'N') CON_UTILIZAPERCBASEREDPF
                         ,C.CONDVENDA
                         ,NVL(C.CONTAORDEM, 'N') CONTAORDEM
                         ,NVL(C.VENDATRIANGULAR, 'N') VENDATRIANGULAR
                         ,C.TIPOVENDA
                         ,C.CODCLI
                         ,NVL(C.CODCLINF, C.CODCLI) CODCLINF
                         ,NVL(C.VLATEND, 0) VLATEND
                         ,C.CODFILIAL
                         ,NVL(C.VENDAEXPORTACAO, 'N') VENDAEXPORTACAO
                         ,NVL(C.NUMREGIAO,
                              NVL((CASE
                               WHEN  C.CODFILIALNF IS NOT NULL THEN
                                (SELECT NUMREGIAO
                                   FROM PCTABPRCLI
                                  WHERE CODCLI = C.CODCLI
                                    AND CODFILIALNF = C.CODFILIALNF)
                               ELSE
                                PRA.NUMREGIAO
                             END), PRA.NUMREGIAO)) NUMREGIAO
                         ,I.CODPROD
                         ,NVL(I.PVENDA, 0) PVENDA
                         ,NVL(I.ST, 0) ST
                         ,NVL(I.VLIPI, 0) VLIPI
                         ,NVL(I.VLDIFALIQUOTAS, 0) VLDIFALIQUOTAS
                         ,NVL(I.VLDESCICMISENCAO, 0) VLDESCICMISENCAO
                         ,NVL(I.VLDESCREDUCAOPIS, 0) VLDESCREDUCAOPIS
                         ,NVL(I.VLDESCREDUCAOCOFINS, 0) VLDESCREDUCAOCOFINS
                         ,NVL(I.ALIQICMS1,0) ALIQICMS1
                         ,NVL(I.ALIQICMS2, 0) ALIQICMS2
                         ,NVL(I.STCLIENTEGNRE, 0) STCLIENTEGNRE
                         ,NVL(I.VLDESCSUFRAMA, 0) VLDESCSUFRAMA
                         ,I.CODST
                         ,DECODE(NVL(I.BONIFIC, 'N'), 'F', 'S', 'N') BONIFIC
                         ,NVL(I.BASEICST, 0) BASEICST
                         ,NVL(CLI.ORGAOPUB, 'N') ORGAOPUB_CLIENT
                         ,NVL(CLI.ORGAOPUBFEDERAL, 'N') ORGAOPUBFEDERAL_CLIENT
                         ,CLI.SULFRAMA SUFRAMA_CLIENT
                         ,NVL(CLI.UTILIZAIESIMPLIFICADA, 'N') UTILIZAIESIMPLIFICADA_CLIENT
                         ,NVL(CLI.CONSUMIDORFINAL, 'N') CONSUMIDORFINAL_CLIENT
                         ,NVL(CLI.USADESCONTOICMS, 'N') USADESCONTOICMS
                         ,NVL(CLI.CONTRIBUINTE, 'N') CONTRIBUINTE_CLIENT
                         ,NVL(CLI.CLIENTEFONTEST, 'N') CLIENTEFONTEST
                         ,NVL(CLI.CALCULAST, 'S') CALCULAST
                         ,UPPER(LTRIM(RTRIM(CLI.ESTENT))) ESTENT_CLIENT
                         ,NVL(CLI.TIPOEMPRESA, 'O') TIPOEMPRESA_CLIENT
                         ,NVL(T.ZERARBASEICMSORGPUBSUFRAMA, 'N') ZERARBASEICMSORGPUBSUFRAMA
                         ,NVL(T.USAISENCAOICMSVP, 'S') USAISENCAOICMSVP
                         ,T.UTILIZAPERCBASEREDPF UTILIZAPERCBASEREDPF_TRIB
                         ,T.PERCBASEREDCONSUMIDOR
                         ,NVL(T.PERBASEREDSIMPLESNAC, 0) PERBASEREDSIMPLESNAC
                         ,NVL(T.REDUZBASEICMDECRETOMARANHAO, 'N') REDUZBASEICMDECRETOMARANHAO
                         ,NVL(T.DESCICMSREDUZBASEICMS, 'S') DESCICMSREDUZBASEICMS
                         ,NVL(T.VLPAUTAICMSINTEREST, 0) VLPAUTAICMSINTEREST
                         ,NVL(T.APLICAREDICMSSEMIPIBA, 'N') APLICAREDICMSSEMIPIBA
                         ,UPPER(LTRIM(RTRIM(F.UF))) UF_FILIAL
                         ,NVL(T.PERPAUTAICMS, 0) PERPAUTAICMS
                         ,NVL(T.PERCBASEREDADICIONALINTER, 0) PERCBASEREDADICIONALINTER
                         ,NVL(T.PERPAUTAICMSINTER, 0) PERPAUTAICMSINTER
                         ,NVL(T.PAUTA, 0) PAUTA
                         ,NVL(T.USAVLULTENTMEDIOBASEST, 'N') USAVLULTENTMEDIOBASEST
                         ,NVL(T.PERCBASEREDST, 0) PERCBASEREDST
                         ,NVL(T.ISENTAICMSBONIFIC, 'N') ISENTAICMSBONIFIC
                         ,NVL(T.ISENTAICMSBONIFICINT, 'N') ISENTAICMSBONIFICINT
                         ,NVL(T.SITTRIBUT, '000') SITTRIBUT
                         ,NVL(T.CALCULARICMSSITTRIBUT060, 'S') CALCULARICMSSITTRIBUT060
                         ,NVL(P.IMPORTADO, 'N') IMPORTADO
                         ,NVL(T.PERCBASERED, 100) PERCBASERED
                         ,NVL(T.IVA, 0) IVA
                         ,NVL(T.IVAFONTE, 0) IVAFONTE
                         ,NVL(T.ALIQICMS1FONTE, 0) ALIQICMS1FONTE
                         ,NVL(T.ALIQICMS2FONTE, 0) ALIQICMS2FONTE
                         ,NVL(T.PERCBASEREDSTFONTE, 0) PERCBASEREDSTFONTE
                         ,NVL(PC.CALCSTPF, 'N') CALCSTPF
                         ,NVL(PC.MOSTRARPVENDASEMST, 'N') MOSTRARPVENDASEMST
                         ,NVL(F.VALIDAVLMAXISENCAOSTPF, 'N') VALIDAVLMAXISENCAOSTPF
                         ,NVL(F.VLMAXISENCAOSTPF, 0) VLMAXISENCAOSTPF
                         ,NVL(T.TIPOCALCULOGNRE, 'P') TIPOCALCULOGNRE
                         ,C.NUMPED
                         ,I.NUMSEQ
                         ,NVL(T.CODICM, 0) CODICM
                         ,NVL(T.CODICMPF, 0) CODICMPF
                         ,T.CODICMPRODRURAL CODICMPRODRURAL
                         ,NVL(T.ALIQICMSTV9, 0) ALIQICMSTV9
                         ,T.CODICMSIMPLESNAC CODICMSIMPLESNAC
                         ,T.APLICAACRESPFJURIDICA
                         ,CLI.TIPOFJ
                         ,NVL(T.CALCBASEICMSMEDIAENT, 'N') CALCBASEICMSMEDIAENT
                         ,NVL(T.USAVALORULTENTBASEICMS, 'N') USAVALORULTENTBASEICMS
                         ,NVL(T.USAVALORULTENTBASEICMSFONTE, 'N') USAVALORULTENTBASEICMSFONTE
                         ,NVL(I.CODFILIALRETIRA, C.CODFILIAL) CODFILIALRETIRA
                         ,NVL(T.BNFNAOCALCULAICMS, 'N') BNFNAOCALCULAICMS
                         ,NVL(T.APLICAMVABASEICMS, 'N') APLICAMVABASEICMS
                         ,CLI.IEENT
                         ,NVL(CLI.PARTICIPAFUNCEP, 'N') PARTICIPAFUNCEP
                         ,NVL(T.CALCULARFUNCEPISENTOIE, 'N') CALCULARFUNCEPISENTOIE
                         ,NVL(T.PERACRESCIMOFUNCEP, 0) PERACRESCIMOFUNCEP
                         ,NVL(I.IVA, 0) IVA_ITEM
                         ,I.SITTRIBUT SITTRIBUT_ITEM
                         ,T.MEINAOCALCDIF
                         ,NVL(T.PERDIFEREIMENTOICMS,0) PERDIFEREIMENTOICMS
                         ,NVL(T.PERDIFERIMENTOCMSTRANSF,0) PERDIFERIMENTOCMSTRANSF
                         ,NVL(T.PERBASEREDNRPA, 0) PERBASEREDNRPA
                         ,T.CODICMTRANSF
                         ,T.PERCBASEREDSTTRANSF
                         ,NVL(T.BNFNAOCALCULAICMSTV14, 'N') BNFNAOCALCULAICMSTV14
                         ,NVL(T.PERDIFEREIMENTOICMSTV9, 0) PERDIFEREIMENTOICMSTV9
                         ,NVL(I.VLFECP, 0) VLFECP
                         ,NVL(T.UTILIZAMOTORCALCULO, 'N') UTILIZAMOTORCALCULO
                         ,T.FORMULAFUNCEPICMS
                         ,NVL(T.VLPAUTAICMSEST,0) VLPAUTAICMSEST
                         ,I.QT
                         ,COALESCE(CLI.PERCREDICMS,0) PERCREDICMS
                         ,COALESCE(I.VLFRETE,0) VLFRETE
                         ,COALESCE(I.VLOUTRASDESP,0) VLOUTRASDESP
                         ,COALESCE(I.Vlicmspartrem,0)Vlicmspartrem
                         ,NVL(T.SNNAOCALCDIF, 'N') SNNAOCALCDIF
                         ,NVL(T.PRODRURALCALCDIFER, 'N') PRODRURALCALCDIFER
                         ,CLI.ISENCAOSUFRAMA
                         ,NVL(T.ISENTAICMSSITTRIBUT041, 'S') ISENTAICMSSITTRIBUT041
                         ,NVL(CLI.AGREGARIPIBASEICMS, 'N') AGREGARIPIBASEICMS
                         ,NVL(T.SOMARVALORDIFBCICMS, 'N') SOMARVALORDIFBCICMS
                         ,NVL(T.COMPARARBASEICMSMEDULTENTMES, 'N') COMPARARBASEICMSMEDULTENTMES
                     FROM PCPEDC C
                         ,PCPEDI I
                         ,PCFILIAL F
                         ,PCTRIBUT T
                         ,PCCLIENT CLI
                         ,PCPRODUT P
                         ,PCCONSUM PC
                         ,PCPRACA PRA
                    WHERE C.NUMPED = I.NUMPED
                      AND C.CODFILIAL = F.CODIGO
                      AND T.CODST = I.CODST
                      AND CLI.CODCLI = C.CODCLI
                      AND I.CODPROD = P.CODPROD
                      AND C.NUMPED = P_NUMPED
                      AND PRA.CODPRACA = CLI.CODPRACA
                      AND DECODE(NVL(P_CODPROD, 0), 0, 1, I.CODPROD) =
                          DECODE(NVL(P_CODPROD, 0), 0, 1, NVL(P_CODPROD, 0))
                      AND DECODE(NVL(P_NUMSEQ, 0), 0, 1, I.NUMSEQ) =
                          DECODE(NVL(P_NUMSEQ, 0), 0, 1, NVL(P_NUMSEQ, 0))

                        UNION ALL

                      SELECT F.CODCLI CODCLI_FILIAL
                         ,F.CODFORNEC CODFORNEC_FILIAL
                         ,NVL(T.PERCBASEREDTRANFSAID, 100) PERCBASEREDTRANFSAID
                         ,NVL(CLI.ISENTOICMS, 'N') ISENTOICMS
                         ,PARAMETROS.GETVALORALFANVL('CON_USARTRIBUTACAOTRANSFTV10',
                                                         '99',
                                                         'N') CON_USARTRIBUTACAOTRANSFTV10
                         ,PARAMETROS.GETVALORALFANVL('CON_USARREDUCAOICMSABATRANSF',
                                                         '99',
                                                         'N') CON_USARREDUCAOICMSABATRANSF
                         ,PARAMETROS.GETVALORALFANVL('CON_UTILIZAPERCBASEREDPF',
                                                         '99',
                                                         'N') CON_UTILIZAPERCBASEREDPF
                         ,C.CONDVENDA
                         ,NVL(C.CONTAORDEM, 'N') CONTAORDEM
                         ,NVL(C.VENDATRIANGULAR, 'N') VENDATRIANGULAR
                         ,C.TIPOVENDA
                         ,C.CODCLI
                         ,NVL(C.CODCLINF, C.CODCLI) CODCLINF
                         ,NVL(C.VLATEND, 0) VLATEND
                         ,C.CODFILIAL
                         ,NVL(C.VENDAEXPORTACAO, 'N') VENDAEXPORTACAO
                         ,NVL(C.NUMREGIAO,
                              NVL((CASE
                               WHEN  C.CODFILIALNF IS NOT NULL THEN
                                (SELECT NUMREGIAO
                                   FROM PCTABPRCLI
                                  WHERE CODCLI = C.CODCLI
                                    AND CODFILIALNF = C.CODFILIALNF)
                               ELSE
                                PRA.NUMREGIAO
                             END), PRA.NUMREGIAO)) NUMREGIAO
                         ,I.CODPRODMP CODPROD
                         ,NVL(I.PVENDA, 0) PVENDA
                         ,NVL(I.ST, 0) ST
                         ,NVL(I.VLIPI, 0) VLIPI
                         ,NVL(I.VLDIFALIQUOTAS, 0) VLDIFALIQUOTAS
                         ,NVL(CESTA.VLDESCICMISENCAO, 0) VLDESCICMISENCAO
                         ,NVL(CESTA.VLDESCREDUCAOPIS, 0) VLDESCREDUCAOPIS
                         ,NVL(CESTA.VLDESCREDUCAOCOFINS, 0) VLDESCREDUCAOCOFINS
                         ,NVL(I.ALIQICMS1,0) ALIQICMS1
                         ,NVL(I.ALIQICMS2, 0) ALIQICMS2
                         ,NVL(I.STCLIENTEGNRE, 0) STCLIENTEGNRE
                         ,NVL(I.VLDESCSUFRAMA, 0) VLDESCSUFRAMA
                         ,I.CODST
                         ,DECODE(NVL(CESTA.BONIFIC, 'N'), 'F', 'S', 'N') BONIFIC
                         ,NVL(I.BASEICST, 0) BASEICST
                         ,NVL(CLI.ORGAOPUB, 'N') ORGAOPUB_CLIENT
                         ,NVL(CLI.ORGAOPUBFEDERAL, 'N') ORGAOPUBFEDERAL_CLIENT
                         ,CLI.SULFRAMA SUFRAMA_CLIENT
                         ,NVL(CLI.UTILIZAIESIMPLIFICADA, 'N') UTILIZAIESIMPLIFICADA_CLIENT
                         ,NVL(CLI.CONSUMIDORFINAL, 'N') CONSUMIDORFINAL_CLIENT
                         ,NVL(CLI.USADESCONTOICMS, 'N') USADESCONTOICMS
                         ,NVL(CLI.CONTRIBUINTE, 'N') CONTRIBUINTE_CLIENT
                         ,NVL(CLI.CLIENTEFONTEST, 'N') CLIENTEFONTEST
                         ,NVL(CLI.CALCULAST, 'S') CALCULAST
                         ,UPPER(LTRIM(RTRIM(CLI.ESTENT))) ESTENT_CLIENT
                         ,NVL(CLI.TIPOEMPRESA, 'O') TIPOEMPRESA_CLIENT
                         ,NVL(T.ZERARBASEICMSORGPUBSUFRAMA, 'N') ZERARBASEICMSORGPUBSUFRAMA
                         ,NVL(T.USAISENCAOICMSVP, 'S') USAISENCAOICMSVP
                         ,T.UTILIZAPERCBASEREDPF UTILIZAPERCBASEREDPF_TRIB
                         ,NVL(T.PERCBASEREDCONSUMIDOR, 0) PERCBASEREDCONSUMIDOR
                         ,NVL(T.PERBASEREDSIMPLESNAC, 0) PERBASEREDSIMPLESNAC
                         ,NVL(T.REDUZBASEICMDECRETOMARANHAO, 'N') REDUZBASEICMDECRETOMARANHAO
                         ,NVL(T.DESCICMSREDUZBASEICMS, 'S') DESCICMSREDUZBASEICMS
                         ,NVL(T.VLPAUTAICMSINTEREST, 0) VLPAUTAICMSINTEREST
                         ,NVL(T.APLICAREDICMSSEMIPIBA, 'N') APLICAREDICMSSEMIPIBA
                         ,UPPER(LTRIM(RTRIM(F.UF))) UF_FILIAL
                         ,NVL(T.PERPAUTAICMS, 0) PERPAUTAICMS
                         ,NVL(T.PERCBASEREDADICIONALINTER, 0) PERCBASEREDADICIONALINTER
                         ,NVL(T.PERPAUTAICMSINTER, 0) PERPAUTAICMSINTER
                         ,NVL(T.PAUTA, 0) PAUTA
                         ,NVL(T.USAVLULTENTMEDIOBASEST, 'N') USAVLULTENTMEDIOBASEST
                         ,NVL(T.PERCBASEREDST, 0) PERCBASEREDST
                         ,NVL(T.ISENTAICMSBONIFIC, 'N') ISENTAICMSBONIFIC
						             ,NVL(T.ISENTAICMSBONIFICINT, 'N') ISENTAICMSBONIFICINT
                         ,NVL(T.SITTRIBUT, '000') SITTRIBUT
                         ,NVL(T.CALCULARICMSSITTRIBUT060, 'S') CALCULARICMSSITTRIBUT060
                         ,NVL(P.IMPORTADO, 'N') IMPORTADO
                         ,NVL(T.PERCBASERED, 100) PERCBASERED
                         ,NVL(T.IVA, 0) IVA
                         ,NVL(T.IVAFONTE, 0) IVAFONTE
                         ,NVL(T.ALIQICMS1FONTE, 0) ALIQICMS1FONTE
                         ,NVL(T.ALIQICMS2FONTE, 0) ALIQICMS2FONTE
                         ,NVL(T.PERCBASEREDSTFONTE, 0) PERCBASEREDSTFONTE
                         ,NVL(PC.CALCSTPF, 'N') CALCSTPF
                         ,NVL(PC.MOSTRARPVENDASEMST, 'N') MOSTRARPVENDASEMST
                         ,NVL(F.VALIDAVLMAXISENCAOSTPF, 'N') VALIDAVLMAXISENCAOSTPF
                         ,NVL(F.VLMAXISENCAOSTPF, 0) VLMAXISENCAOSTPF
                         ,NVL(T.TIPOCALCULOGNRE, 'P') TIPOCALCULOGNRE
                         ,C.NUMPED
                         ,I.NUMSEQ
                         ,NVL(T.CODICM, 0) CODICM
                         ,NVL(T.CODICMPF, 0) CODICMPF
                         ,T.CODICMPRODRURAL CODICMPRODRURAL
                         ,NVL(T.ALIQICMSTV9, 0) ALIQICMSTV9
                         ,T.CODICMSIMPLESNAC CODICMSIMPLESNAC
                         ,T.APLICAACRESPFJURIDICA
                         ,CLI.TIPOFJ
                         ,NVL(T.CALCBASEICMSMEDIAENT, 'N') CALCBASEICMSMEDIAENT
                         ,NVL(T.USAVALORULTENTBASEICMS, 'N') USAVALORULTENTBASEICMS
                         ,NVL(T.USAVALORULTENTBASEICMSFONTE, 'N') USAVALORULTENTBASEICMSFONTE
                         ,NVL(CESTA.CODFILIALRETIRA, C.CODFILIAL) CODFILIALRETIRA
                         ,NVL(T.BNFNAOCALCULAICMS, 'N') BNFNAOCALCULAICMS
                         ,NVL(T.APLICAMVABASEICMS, 'N') APLICAMVABASEICMS
                         ,CLI.IEENT
                         ,NVL(CLI.PARTICIPAFUNCEP, 'N') PARTICIPAFUNCEP
                         ,NVL(T.CALCULARFUNCEPISENTOIE, 'N') CALCULARFUNCEPISENTOIE
                         ,NVL(T.PERACRESCIMOFUNCEP, 0) PERACRESCIMOFUNCEP
                         ,NVL(I.IVA, 0) IVA_ITEM
                         ,I.SITTRIBUT SITTRIBUT_ITEM
                         ,T.MEINAOCALCDIF
                         ,NVL(T.PERDIFEREIMENTOICMS,0) PERDIFEREIMENTOICMS
                         ,NVL(T.PERDIFERIMENTOCMSTRANSF,0) PERDIFERIMENTOCMSTRANSF
                         ,NVL(T.PERBASEREDNRPA, 0) PERBASEREDNRPA
                         ,T.CODICMTRANSF
                         ,T.PERCBASEREDSTTRANSF
                         ,NVL(T.BNFNAOCALCULAICMSTV14, 'N') BNFNAOCALCULAICMSTV14
                         ,NVL(T.PERDIFEREIMENTOICMSTV9, 0) PERDIFEREIMENTOICMSTV9
                         ,NVL(I.VLFECP, 0) VLFECP
                         ,NVL(T.UTILIZAMOTORCALCULO, 'N') UTILIZAMOTORCALCULO
                         ,T.FORMULAFUNCEPICMS
                         ,NVL(T.VLPAUTAICMSEST,0) VLPAUTAICMSEST
                         ,CESTA.QT
                         ,COALESCE(CLI.PERCREDICMS,0) PERCREDICMS
                         ,COALESCE(I.vlfrete_rateio,0) VLFRETE
                         ,COALESCE(I.vloutras_rateio,0) VLOUTRASDESP
                         ,COALESCE(I.Vlicmspartrem,0)Vlicmspartrem
                         ,NVL(T.SNNAOCALCDIF, 'N') SNNAOCALCDIF
                         ,NVL(T.PRODRURALCALCDIFER, 'N') PRODRURALCALCDIFER
                         ,CLI.ISENCAOSUFRAMA
                         ,NVL(T.ISENTAICMSSITTRIBUT041, 'S') ISENTAICMSSITTRIBUT041
                         ,NVL(CLI.AGREGARIPIBASEICMS, 'S') AGREGARIPIBASEICMS
                         ,NVL(T.SOMARVALORDIFBCICMS, 'N') SOMARVALORDIFBCICMS
                         ,NVL(T.COMPARARBASEICMSMEDULTENTMES, 'N') COMPARARBASEICMSMEDULTENTMES
                     FROM PCPEDC C
                         ,PCPEDICESTA I
                         ,PCFILIAL F
                         ,PCTRIBUT T
                         ,PCCLIENT CLI
                         ,PCPRODUT P
                         ,PCCONSUM PC
                         ,PCPEDI CESTA
                         ,PCPRACA PRA
                    WHERE C.NUMPED = I.NUMPED
                      AND C.NUMPED = CESTA.NUMPED
                      AND CESTA.CODPROD = I.CODPROD
                      AND I.codprodmp = P.CODPROD
                      AND C.CODFILIAL = F.CODIGO
                      AND T.CODST = I.CODST
                      AND CLI.CODCLI = C.CODCLI
                      AND PRA.CODPRACA = CLI.CODPRACA
                      AND C.NUMPED = P_NUMPED
                      AND DECODE(NVL(P_CODPROD, 0), 0, 1, I.CODPRODMP) =
                          DECODE(NVL(P_CODPROD, 0), 0, 1, NVL(P_CODPROD, 0))
                      AND DECODE(NVL(P_NUMSEQ, 0), 0, 1, I.NUMSEQ) =
                          DECODE(NVL(P_NUMSEQ, 0), 0, 1, NVL(P_NUMSEQ, 0))
  ;

  FUNCTION RETORNAR_ICMS_PROD(PEDIDO IN OUT ITENS_PEDIDO%ROWTYPE) RETURN TR_DADOS_ICMS;


  FUNCTION RETORNAR_ROWTYPE(TABELA      IN VARCHAR2
                           ,CAMPO_CHAVE IN VARCHAR
                           ,VALOR_CHAVE IN VARCHAR) RETURN SYS_REFCURSOR;

  PROCEDURE F_SLEEP( IN_TIME NUMBER );

END;
