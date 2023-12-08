CREATE OR REPLACE PACKAGE PKG_PROCESSOS_FISCAIS IS
  /**********************************************************************************************/
  /* Este objeto tem por objetivo unificar e facilitar a manutenibiliadade das várias funções   */
  /* fiscais, que NÃO influenciam diretamente no preço da mercadoria, além de validar pontos    */
  /* específicos do sistema, como cadastro de produto e tributação                              */
  /**********************************************************************************************/  
 
  ------------------------------- types ---------------------------------- 
  TYPE T_DADOS_NOTAS IS RECORD(
    NUMTRANSACAO    NUMBER(10),
    TIPOMOV         VARCHAR2(1),--E=ENTRADA/S=SAIDA
    PREFAT          VARCHAR2(1),--CASO DE SAIDA
    CODCONTA        NUMBER(10),--PARA ENTRADAS
    CODFILIAL       PCFILIAL.CODIGO%TYPE,
    NUMNOTA         NUMBER(10),
    ESPECIE         VARCHAR2(2),    
    CODCLI_FORNEC   NUMBER(10),
    DATA_DOCUMENTO  DATE,
    MSG             VARCHAR2(1000)
    );
    
  TYPE T_ICMS IS RECORD(
	  SITTRIBUT     PCMOV.SITTRIBUT%TYPE,
	  BASEICMS      PCMOV.BASEICMS%TYPE,
    PERCICM       PCMOV.PERCICM%TYPE,
    VLICMS        PCMOVCOMPLE.VLICMS%TYPE,
    BASEICST      PCMOV.BASEICST%TYPE,
    ALIQICMS1     PCMOV.ALIQICMS1%TYPE,
    ALIQICMS2     PCMOV.ALIQICMS2%TYPE,
    VLST          PCMOV.ST%TYPE,
    PERCBASERED   PCMOV.PERCBASERED%TYPE,
    PERCBASEREDST PCMOV.PERCBASEREDST%TYPE
    );    
  ------------------------------------------------------------------------ 
   --------------------------- variaveis ----------------------------------
   V_DADOS_NOTAS   T_DADOS_NOTAS;
   
   ------------------------------------------------------------------------ 
   --------------------------- Constantes ---------------------------------
   C_SEPARADOR    VARCHAR2(4) := '#13';
   
   ------------------------------------------------------------------------ 
   

  /**********************************************************************************************/
  /* Método que realiza todas as chamadas de objetos fiscais, calculos e afins, em um único     */
  /* local para NOTAS de SAIDA                                                                  */
  /**********************************************************************************************/
  FUNCTION PROCESSAR_NF_SAIDA(P_NUMTRANSACAO IN PCNFSAID.NUMTRANSVENDA%TYPE, P_PREFAT IN VARCHAR2) RETURN VARCHAR2;
  /**********************************************************************************************/
  /* Método que realiza todas as chamadas de objetos fiscais, calculos e afins, em um único     */
  /* local para NOTAS de ENTRADA                                                                */
  /**********************************************************************************************/
  FUNCTION PROCESSAR_NF_ENTRADA(P_NUMTRANSACAO IN PCNFENT.NUMTRANSENT%TYPE, P_CODCONT IN PCNFENT.CODCONT%TYPE) RETURN VARCHAR2; 
  /**********************************************************************************************/
  /* Método que realiza todas as chamadas de objetos fiscais, calculos e afins, em um único     */
  /* local para CONHECIMENTO DE TRANSPORTE de SAIDA                                             */
  /**********************************************************************************************/
  FUNCTION PROCESSAR_CT_SAIDA(P_NUMTRANSACAO IN PCNFSAID.NUMTRANSVENDA%TYPE) RETURN VARCHAR2;
  /**********************************************************************************************/
  /* Método que faz a validação completa do cadastro de produtos, deve ser chamado antes de     */
  /* gravar alterações/inclusções de produto na rotina 203                                      */
  /**********************************************************************************************/
  FUNCTION VALIDAR_CADASTRO_PRODUTO(P_CODPROD IN PCPRODUT.CODPROD%TYPE) RETURN VARCHAR2;  
  /**********************************************************************************************/
  /* Método que faz a validação completa da tributação de venda, deve ser chamado antes de      */
  /* gravar alterações/inclusoções na rotina 514                                                */
  /**********************************************************************************************/
  FUNCTION VALIDAR_CADASTRO_TRIBUT_VENDA(P_CODST IN PCTRIBUT.CODST%TYPE) RETURN VARCHAR2;
  /**********************************************************************************************/
  /* Validação completa de notas de saida */
  /**********************************************************************************************/
  FUNCTION VALIDAR_NOTA_SAIDA(P_NUMTRANSACAO IN PCNFSAID.NUMTRANSVENDA%TYPE, P_PREFAT IN VARCHAR2) RETURN VARCHAR2;
  /**********************************************************************************************/
  /* Validação completa de notas de entrada */
  /**********************************************************************************************/
  FUNCTION VALIDAR_NOTA_ENTRADA(P_NUMTRANSACAO IN PCNFENT.NUMTRANSENT%TYPE, P_CODCONT IN PCNFENT.CODCONT%TYPE) RETURN VARCHAR2;
  /**********************************************************************************************/
  /* Método privado que valida as informações referente ao ICMS, de acordo com cada CST e campos*/
  /* obrigatórios no manual da NFE                                                              */
  /**********************************************************************************************/
  FUNCTION VALIDAR_ICMS(V_ICMS IN T_ICMS) RETURN VARCHAR2;
  
  
END; 