CREATE OR REPLACE package GERA_HISTORICO is

  VTIPOALIQOUTRASDESP varchar2(1);
  VAGREGARSTPRODSINTEGRA varchar2(1);
  VCODCONTFOR number(10);
  VCODCONTFRE number(10);
  VCODCONTCLI number(10);
  VPERCICMFRETEENT number(4, 2);
  VPERCICMINTERFRETEENT number(4, 2);
  VCODFISCALFRETEENT number(4);
  VCODFISCALINTERFRETEENT number(4);
  VPERCICMFRETE number(4, 2);
  VPERCICMINTERFRETE number(4, 2);
  VALIQICMOUTRASDESP number(4, 2);
  VALIQICMINTEROUTRASDESP number(4, 2);
  VCODFISCALFRETE number(4);
  VCODFISCALINTERFRETE number(4);
  VCODFISCALOUTRASDESP number(4);
  VCODFISCALINTEROUTRASDESP number(4);
  VCODFISCALDEVOUTRASDESP number(4);
  VCODFISCALINTERDEVOUTRASDESP number(4);
  VUFFILIAL varchar2(2);
  VCFOPFRETE number(4);
  VCFOPDESPESA number(4);
  VALIQICMSFRETE number(4, 2);
  VALIQICMSDESPESA number(4, 2);
  VERRO varchar2(1000);
  VUSATRIBENTPORUF varchar2(1);
  VUSAPISCOFINSPORFILIAL varchar2(1);
  VCALCCREDIPI varchar2(1);
  VAPROVEITAIPI_PISCOFINS varchar2(1);
  VAPROVEITAFRETE_PISCOFINS varchar2(1);
  VAPROVEITADESP_PISCOFINS varchar2(1);
  VVLBASEPISCOFINS PCMOV.VLBASEPISCOFINS%type;
  VPISCOFINSRETIDO varchar2(1);
  VCODSITTRIBPISCOFINS PCMOV.CODSITTRIBPISCOFINS%type;
  VCODFISCALNF PCMOV.CODFISCAL%type;
  VCODECF PCMOV.CODECF%type;
  VCONT_ATUALIZACAO number(10);
  VCONT_PRODUTOS number(6);
  VULTIMA_TRANSACAO number(10);
  VREPROCESSAR varchar2(1);
  VNUMNOTA PCNFSAID.NUMNOTA%type;
  VMSGERRO_PISCOFINS varchar2(1000);
  V_CSTIPI_ENTRADA PCFIGURATRIBIPI.CODSITTRIBIPIENT%type;
  V_CSTIPI_SAIDA   PCFIGURATRIBIPI.CODSITTRIBIPISAID%type;
  V_GERABASEIPIALIQZERO   VARCHAR2(1);  
  V_MSG_IPI        varchar2(4000);
  V_RETORNO_IPI    varchar2(1);
  v_GERARBCRNFE    varchar2(1);
  VPERCMVAORIG_ENT NUMBER(12,4);
  v_FALTAREGIAOPADRAO exception;
  /****************************************************************************/
  procedure VERIFICAR_SE_NECESSARIO_COMMIT;

  function SOMENTE_NUMERO(P_STRING in varchar) return number;

  /****************************************************************************/

  function GET_VALORCLIENTE(PCODCLI        in NUMBER,
                            PCONSUMIDOR    in VARCHAR2,
                            PVENDACONSUM   in VARCHAR2,
                            PVALOR_CONSUM  in VARCHAR2,
                            PVALOR_CLIENTE in VARCHAR2,
                            PVALOR_FILIAL  in VARCHAR2) RETURN VARCHAR2;

  procedure ATUALIZAR_TRIBUTACOES_ENTRADA(PCODFILIAL    in varchar2,
                                          PUF           in varchar2,
                                          PTIPODESCARGA in varchar2);

  procedure ATUALIZAR_TRIBUTACOES_SAIDA(PCODFILIAL  in varchar2,
                                        PUF         in varchar2,
                                        PTIPOVENDA  in varchar2,
                                        PCONSUMIDOR in varchar2,
                                        PTIPOFJ     in varchar2);

  /****************************************************************************/
  procedure GERAR_CAB_ENTRADAS(PCODFILIAL   in varchar2,
                               PDATA1       in date,
                               PDATA2       in date,
                               PTRANSACAO   in number,
                               PCODFORNEC   in number,
                               PTIPOENTRADA in varchar2);

  procedure GERAR_CAB_SAIDAS(PCODFILIAL in varchar2,
                             PDATA1     in date,
                             PDATA2     in date,
                             PTRANSACAO in number,
                             PCODCLI    in number);
  
  function GRAVAR_DADOS_PCMOVCOMPLE(P_IDREGISTRO_PCMOV in varchar2,
                                    P_NUMTRANSITEM     in number,
                                    P_CODSITTRIBUIPI   in number,
                                    P_EXTIPI           in varchar2,
                                    P_SUBSTANCIA       in varchar2,
                                    P_QTLITRAGEM       in number,
                                    P_REGIMEESPECIAL IN VARCHAR2,
                                    P_ORIGMERCTRIB   IN VARCHAR2,
                                    P_CODCEST        IN VARCHAR2, 
                                    P_PREFATURAMENTO IN VARCHAR2,
                                    P_CODMOTISENCAOANVISA IN VARCHAR2,
                                    P_PERMITECREDITOPRESUMIDO IN VARCHAR2,
                                    P_PERCMVAORIG_ENT IN NUMBER)
    return number;                             
                      
                      
    function GRAVAR_DADOS_PCMOVHISTORICO(P_IDREGISTRO_PCMOV in varchar2,
                                    P_NUMTRANSHISTORICO    in number,
                                    P_CESTABASICALEGIS   in VARCHAR2, 
                                    P_PREFATURAMENTO IN VARCHAR2)
    return number;                             
                     

  procedure GERAR_MOVIMENTACAO(PCODFILIAL in varchar2,
                               PDATA1     in date,
                               PDATA2     in date,
                               PTRANSACAO in number,
                               PTIPOMOV   in varchar2,
                               PCODPROD   in number);

  procedure GERAR_INVENTARIO(PCODFILIAL in varchar2,
                             PDATA1     in date,
                             PDATA2     in date,
                             PCODPROD   in number);

  procedure GERAR_LOG(PCODFILIAL   in varchar2,
                      PDATA1       in date,
                      PDATA2       in date,
                      PCODPROD     in number,
                      PREPROCESSAR in varchar2);

  /****************************************************************************/
  procedure GERA_HISTORICO(PCODFILIAL     in varchar2,
                           PDTINICIAL     in date,
                           PDTFINAL       in date,
                           PTRANSACAO     in number,
                           PTIPOMOV       in varchar2,
                           PCODCLI_FORNEC in number,
                           PREPROCESSAR   in varchar2,
                           MSG            out varchar2);

/****************************************************************************/
  procedure GERA_DESCRICAO_PROD_NFE(PCODFILIAL     in varchar2,
                                    PDTINICIAL     in date,
                                    PDTFINAL       in date,
                                    PTRANSACAO     in number,
                                    PTIPOMOV       in varchar2);

/****************************************************************************/
end GERA_HISTORICO; 
-- 24/11/2022 - Gleibe - Alteração de melhorias de performance
