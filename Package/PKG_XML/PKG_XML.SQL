CREATE OR REPLACE PACKAGE PKG_XML AS
  --Executar no terminal antes de chamar no terminal.
  --ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
  --ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';

  --Modo de Usar. Deve existir o xml na tabela PCNFENTXML.
  --SELECT V.* FROM TABLE(PKG_XML.LER_CABECALHO(:CHAVENFE)) V
  --SELECT V.* FROM TABLE(PKG_XML.LER_ITENS(:CHAVENFE)) V
  --SELECT V.* FROM TABLE(PKG_XML.LER_PARCELAS(:CHAVENFE)) V

  TYPE ROW_CABECALHO IS RECORD(
    CODFILIAL     PCNFENTPREENT.CODFILIAL%TYPE,
    CODFORNEC     PCNFENTPREENT.CODFORNEC%TYPE,
    NNF           NUMBER(10, 0),
    MOD_          NUMBER(2, 0),
    SERIE         NUMBER(3, 0),
    DHEMI         DATE,
    DHSAIENT      DATE,
    CNPJ_EMIT     VARCHAR2(14),
    XNOME_EMIT    VARCHAR2(60),
    CNPJ_DEST     VARCHAR2(14),
    XNOME_DEST    VARCHAR2(60),
    MODFRETE      VARCHAR2(1),
    PLACA         VARCHAR2(10),
    VPROD         NUMBER(18, 6),
    VDESC         NUMBER(18, 6),
    VFRETE        NUMBER(18, 6),
    VSEG          NUMBER(18, 6),
    VOUTRO        NUMBER(18, 6),
    VBC           NUMBER(18, 6),
    VICMSDESON    NUMBER(18, 6),
    VICMS         NUMBER(18, 6),
    VIPI          NUMBER(18, 6),
    VPIS          NUMBER(18, 6),
    VCOFINS       NUMBER(18, 6),
    VST           NUMBER(18, 6),
    VFCP          NUMBER(18, 6),
    VFCPST        NUMBER(18, 6),
    VFCPSTRET     NUMBER(18, 6),
    VBCST         NUMBER(18, 6),
    VNF           NUMBER(18, 6),
    NATOP         VARCHAR2(60),
    INDPRES       VARCHAR2(1),
    CNPJ_INTERMED VARCHAR2(20),
    IDCADINTTRAN  VARCHAR2(60),
    INFCPL        VARCHAR2(255),
    CHNFE         VARCHAR2(45));

  TYPE ROW_ITENS IS RECORD(
    CODPROD                PCMOVPREENT.CODPROD%TYPE,
    NITEM                  NUMBER(5),
    XPED                   NUMBER(15),
    NITEMPED               NUMBER(6),
    CPROD                  VARCHAR2(18),
    CEAN                   VARCHAR2(18),
    NFCI                   VARCHAR2(36),
    NCM                    VARCHAR2(15),
    CEST                   VARCHAR2(10),
    CFOP                   NUMBER(4),
    EXTIPI                 NUMBER(2),
    CBENEF                 VARCHAR2(10),
    UCOM                   VARCHAR2(10),
    XPROD                  VARCHAR2(60),
    VUNCOM                 NUMBER(18, 6),
    QCOM                   NUMBER(18, 6),
    QTRIB                  NUMBER(18, 6),
    VUNTRIB                NUMBER(18, 6),
    VDESC                  NUMBER(18, 6),
    VFRETE                 NUMBER(18, 6),
    VOUTRO                 NUMBER(18, 6),
    VSEG                   NUMBER(18, 6),
    VPROD                  NUMBER(18, 6),
    INDESCALA              VARCHAR2(2),
    CNPJFAB                VARCHAR2(14),
    NLOTE                  VARCHAR2(20),
    QTLOTE                 NUMBER(18, 6),
    DFAB                   DATE,
    DVAL                   DATE,
    CAGREG                 VARCHAR2(20),
    CPRODANVISA            VARCHAR2(13),
    VPMC                   NUMBER(18, 6),
    CST_IPI                NUMBER(3),
    VBC_IPI                NUMBER(18, 6),
    PIPI                   NUMBER(12, 4),
    VIPI                   NUMBER(18, 6),
    CST_PIS                NUMBER(3),
    VBC_PIS                NUMBER(18, 6),
    PPIS                   NUMBER(12, 4),
    VPIS                   NUMBER(18, 6),
    CST_COFINS             NUMBER(3),
    VBC_COFINS             NUMBER(18, 6),
    PCOFINS                NUMBER(12, 4),
    VCOFINS                NUMBER(18, 6),
    ORIG                   NUMBER(1),
    CST                    NUMBER(2),
    MODBC                  NUMBER(1),
    PREDBC                 NUMBER(12, 4),
    VBC                    NUMBER(18, 6),
    PST                    NUMBER(12, 4),
    PICMS                  NUMBER(12, 4),
    VICMSOP                NUMBER(18, 6),
    PDIF                   NUMBER(12, 4),
    VICMSDIF               NUMBER(18, 6),
    VICMS                  NUMBER(18, 6),
    VICMSSUBSTITUTO        NUMBER(18, 6),
    MODBCST                NUMBER(1),
    PMVAST                 NUMBER(12, 4),
    PREDBCST               NUMBER(12, 4),
    VBCST                  NUMBER(18, 6),
    PICMSST                NUMBER(12, 4),
    VICMSST                NUMBER(18, 6),
    VBCSTRET               NUMBER(18, 6),
    VICMSSTRET             NUMBER(18, 6),
    VBCFCP                 NUMBER(18, 6),
    PFCP                   NUMBER(12, 4),
    VFCP                   NUMBER(18, 6),
    VBCFCPST               NUMBER(18, 6),
    PFCPST                 NUMBER(12, 4),
    VFCPST                 NUMBER(18, 6),
    VBCFCPSTRET            NUMBER(18, 6),
    PFCPSTRET              NUMBER(12, 4),
    VFCPSTRET              NUMBER(18, 6),
    PREDBCEFET             NUMBER(12, 4),
    VBCEFET                NUMBER(18, 6),
    PICMSEFET              NUMBER(12, 4),
    VICMSEFET              NUMBER(18, 6),
    VICMSDESON             NUMBER(18, 6),
    MOTDESICMS             NUMBER(2),
    TAGICMS60              VARCHAR2(1),
    IBSCBS_CST             VARCHAR2(3),
    IBSCBS_CCLASSTRIB      VARCHAR2(6),
    gIBSCBS_vBC            NUMBER(15, 2),
    gIBSUF_pIBSUF          NUMBER(7, 4),
    gIBSUF_vIBSUF          NUMBER(15, 2),
    gIBSMun_pIBSMun        NUMBER(7, 4),
    gIBSMun_vIBSMun        NUMBER(15, 2),
    gIBSMun_gRed_pRedAliq  NUMBER(7, 4),
    gIBSMun_gRed_pAliqEfet NUMBER(7, 4),
    gCBS_pCBS              NUMBER(10, 4),
    gCBS_vCBS              NUMBER(18, 6));

  TYPE ROW_PARCELAS IS RECORD(
    NDUP  VARCHAR2(15),
    DVENC DATE,
    VDUP  NUMBER(18, 6));

  TYPE TBL_CABECALHO IS TABLE OF ROW_CABECALHO;
  TYPE TBL_ITENS IS TABLE OF ROW_ITENS;
  TYPE TBL_PARCELAS IS TABLE OF ROW_PARCELAS;

  FUNCTION LER_CABECALHO(SCHAVENFE IN PCNFENTXML.CHAVENFE%TYPE)
    RETURN TBL_CABECALHO
    PIPELINED;

  FUNCTION LER_ITENS(SCHAVENFE IN PCNFENTXML.CHAVENFE%TYPE) RETURN TBL_ITENS
    PIPELINED;

  FUNCTION LER_PARCELAS(SCHAVENFE IN PCNFENTXML.CHAVENFE%TYPE)
    RETURN TBL_PARCELAS
    PIPELINED;
END PKG_XML;
