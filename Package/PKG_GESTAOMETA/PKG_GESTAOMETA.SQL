create or replace package PKG_GESTAOMETA is

   -- Author  : DEYVID.COSTA
   -- Created : 10/01/2019 15:19:30
   -- Purpose :

   TYPE TR_PARAMETRO IS RECORD(
      NOMECOMBENTIDADE      VARCHAR2(1000),
      PERCOMMOV             VARCHAR2(500),
      VLFATPORPERCOM        VARCHAR2(500),
      VLCOMISSAO            NUMBER(18, 6),
      CODTIPOMETA           NUMBER,
      CODINDICADOR          NUMBER,
      VLFATURADO            NUMBER(18, 6),
      PERCATINGIDO          NUMBER(15, 2),
      PERCOMPORIND          NUMBER(15, 2),
      PERCPESOINDNIVELATING NUMBER(15, 2),
      FAIXAINI              NUMBER(8, 2),
      FAIXAFIM              NUMBER(8, 2),
      CODMETA               NUMBER,
      REALIZADO             NUMBER,
      SUBTOTAL              NUMBER,
      DATA                  DATE,
      CODCOMBINACAO         NUMBER,
      ITEMNOVOADD           VARCHAR2(1),
      TIPOCHAMADA           VARCHAR2(15),
      DTFECHAMENTO          DATE,
      PERIODICIDADE         VARCHAR2(1),
      DATAFIM               DATE,
      TIPOENTIDADE          VARCHAR2(10));

   TYPE TB_PARAMETRO IS TABLE OF TR_PARAMETRO;

   TYPE TR_RETORNO IS RECORD(
      PSBLOCOSQLCALCREALIZADO VARCHAR2(10000),
      NOMECOMBENTIDADE        VARCHAR2(1000));

   TYPE TB_RETORNO IS TABLE OF TR_RETORNO;

   TYPE TR_PCGMMETATEMP IS RECORD(
      NUMTRANSVENDA          NUMBER,
      CODCOMBINACAO          NUMBER,
      CODENTIDADE            VARCHAR2(200),
      CODMETA                NUMBER,
      CODTIPOMETA            NUMBER,
      CODINDICADOR           NUMBER,
      TABELAENTIDADE         VARCHAR2(100),
      DATA                   DATE,
      VLLIQUIDO              NUMBER(18, 6),
      VLBONIFIC              NUMBER(18, 6),
      CODFILIAL              VARCHAR2(3),
      VOLUMELIQUIDO          NUMBER(18, 6),
      LITRAGEMLIQUIDO        NUMBER(18, 6),
      CODUSUR                NUMBER,
      CODSUPERVISOR          NUMBER,
      CODGERENTE             NUMBER,
      NUMCAR                 NUMBER,
      CODPROD                NUMBER,
      CODCLI                 NUMBER,
      CODFORNEC              NUMBER,
      CODSEC                 NUMBER,
      CODEPTO                NUMBER,
      PERCOM                 NUMBER(18, 6),
      TIPOMOV                VARCHAR2(2),
      NUMSEQ                 NUMBER(20),
      VLLUCRO                NUMBER(15, 6),
      PRAZOMEDIO             NUMBER,
      NUMTRANSENTNFESTORNADA NUMBER,
      VLVENDA                NUMBER(18, 6),
      NUMTRANSENT            NUMBER,
      VLST                   NUMBER(16, 6),
      VLIPI                  NUMBER(16, 6),
      VLFECP                 NUMBER(16, 6),
      VLIPIBONIFIC           NUMBER(16, 6),
      VLSTBONIFIC            NUMBER(16, 6),
      CODGERENTEREGIONAL     NUMBER(8),
      CODGERENTENACIONAL     NUMBER(8),
      PESOLIQUIDO            NUMBER(18,6),
      QTPRODUTO              NUMBER(20,6),
      VLDESCONTO             NUMBER(18,6),
      VLTABELA               NUMBER(18,6),
      VLDEVOLUCAO            NUMBER(18,6),
      CODPRACA               NUMBER(6));

   TYPE TB_PCGMMETATEMP IS TABLE OF TR_PCGMMETATEMP;

   TYPE TR_PCGMINDICADOR IS RECORD(
      CODIGO         NUMBER,
      DESCRICAO      VARCHAR2(200),
      VALOR          NUMBER(18, 6),
      PERCOMMOV      VARCHAR2(500),
      VLFATPORPERCOM VARCHAR2(500),
      VLCOMISSAO     NUMBER(18, 6),
      NUMCAR         NUMBER,
      NUMTRANSVENDA  NUMBER,
      CODTIPOMETA    NUMBER,
      CODINDICADOR   NUMBER,
      VLFATURADO     NUMBER(18, 6));

   TYPE TB_PCGMINDICADOR IS TABLE OF TR_PCGMINDICADOR;

   TYPE TR_PCGMMETACOMB IS RECORD(
      CODCOMBINACAO         NUMBER,
      CODENTIDADE           VARCHAR2(200),
      NOMEENTIDADE          VARCHAR2(2000),
      TIPOENTIDADE          VARCHAR2(100),
      CODMETA               NUMBER,
      CODTIPOMETA           NUMBER,
      CODINDICADOR          NUMBER,
      DATA                  DATE,
      PREVISTO              NUMBER(18, 6),
      REALIZADO             NUMBER(18, 6),
      DTFECHAMENTO          DATE,
      CODFILIAL             VARCHAR(3),
      PESOINDICADOR         NUMBER(18, 6),
      NIVELATINGIDO         NUMBER(18, 6),
      PERCATINGIDO          NUMBER(18, 6),
      PERCPESOINDNIVELATING NUMBER(18, 6),
      PERCOMCADASTRADO      NUMBER(18, 6),
      VLFATURADO            NUMBER(18, 6),
      PERCOMCALCPESO        NUMBER(18, 6),
      VLCOMISSAO            NUMBER(18, 6),
      ITEMNOVOADD           VARCHAR2(1),
      FAIXAINI              NUMBER(8, 2),
      FAIXAFIM              NUMBER(8, 2),
      FILTROTIPOMETA        VARCHAR2(10));

   TYPE TB_PCGMMETACOMB IS TABLE OF TR_PCGMMETACOMB; -- index by pls_integer;

   TYPE TR_DADOSMETATEMP IS RECORD(
      CODCOMBINACAO  NUMBER,
      CODMETA        NUMBER,
      CODTIPOMETA    NUMBER,
      CODINDICADOR   NUMBER,
      CODENTIDADE    VARCHAR2(200),
      TABELAENTIDADE VARCHAR2(30),
      CAMPOCONDICAO  VARCHAR2(20));

   TYPE TB_DADOSMETATEMP IS TABLE OF TR_DADOSMETATEMP; -- index by pls_integer;

   TYPE TR_PCGMPARAMETRO IS TABLE OF PCGMPARAMETRO%ROWTYPE;
   TB_PCGMPARAMETRO TR_PCGMPARAMETRO := TR_PCGMPARAMETRO(NULL);

   FUNCTION METAPREVISTAPORINDICADOR(PNCODMETA      IN NUMBER,
                                     PNCODTIPOMETA  IN NUMBER DEFAULT 0,
                                     PNCODINDICADOR IN NUMBER DEFAULT 0,
                                     PDDATAINI      IN DATE,
                                     PDDATAFIM      IN DATE)
      RETURN TB_PCGMINDICADOR
      PIPELINED;

   FUNCTION APURACAOMETA(PNCODMETA      IN NUMBER,
                         PNCODTIPOMETA  IN NUMBER DEFAULT 0,
                         PNCODINDICADOR IN NUMBER DEFAULT 0,
                         PDDATAINI      IN DATE,
                         PDDATAFIM      IN DATE) RETURN TB_PCGMMETACOMB
      PIPELINED;

   FUNCTION APURACAOPREMIO(PNCODMETA       IN NUMBER,
                           PSCODENTIDADE   IN VARCHAR2 DEFAULT '',
                           PSTIPOBONUS     IN VARCHAR2,
                           PNSOMAPESONIVEL IN NUMBER,
                           PDDATAINI       IN DATE,
                           PDDATAFIM       IN DATE) RETURN TB_PCGMMETACOMB
      PIPELINED;

  FUNCTION F_RetornarSQLEntidadeIN(PNPARAMMETA       IN NUMBER,
                                   PNCODTIPOMETA     IN NUMBER,
                                   PNCODENTIDADEMETA IN NUMBER DEFAULT 0,
                                   PSCODFILIAL       IN VARCHAR2 DEFAULT NULL)
  RETURN VARCHAR2;

/*FUNCTION F_DADOSMETATEMP(PNCODMETA      IN NUMBER,
                           PNCODTIPOMETA  IN NUMBER,
                           PNCODINDICADOR IN NUMBER,
                           PDDATAINI      IN DATE,
                           PDDATAFIM      IN DATE) RETURN TB_DADOSMETATEMP
    PIPELINED;
*/
end PKG_GESTAOMETA;
