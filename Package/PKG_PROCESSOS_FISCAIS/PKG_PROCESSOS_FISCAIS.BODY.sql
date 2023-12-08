CREATE OR REPLACE PACKAGE BODY PKG_PROCESSOS_FISCAIS IS
  /**********************************************************************************************/
  /* Este objeto tem por objetivo unificar e facilitar a manutenibiliadade das várias funções   */
  /* fiscais, que NÃO influenciam diretamente no preço da mercadoria, além de validar pontos    */
  /* específicos do sistema, como cadastro de produto e tributação                              */
  /**********************************************************************************************/  

  /****************************************  PRIVATE  ********************************************/ 
  
  /**********************************************************************************************/
  /* Método privado que mensagens na em uma lista de mensagens                                  */
  /**********************************************************************************************/
  PROCEDURE ADD_ERRO(P_LISTA_ERRO IN OUT VARCHAR2, P_MSG_ERRO IN VARCHAR2) IS
  BEGIN
    IF ((P_MSG_ERRO IS NOT NULL) AND (P_MSG_ERRO <> 'OK')) THEN
       IF (P_LISTA_ERRO IS NULL) THEN
          P_LISTA_ERRO := P_MSG_ERRO;
       ELSE  
          P_LISTA_ERRO := P_LISTA_ERRO || C_SEPARADOR || P_MSG_ERRO; 
       END IF;   
    END IF;             
  END;
  
  /**********************************************************************************************/
  /* Método privado que busca as informações da nota e popula um objeto para ser usado em todo o*/
  /* processamento da package                                                                   */
  /**********************************************************************************************/
  PROCEDURE GET_DADOS_NOTAS(P_NUMTRANSACAO IN NUMBER, P_PREFAT IN VARCHAR2, P_TIPOMOV IN VARCHAR2, P_CODCONT IN NUMBER) IS
  BEGIN
    BEGIN
      V_DADOS_NOTAS.NUMTRANSACAO := P_NUMTRANSACAO;
      V_DADOS_NOTAS.PREFAT       := P_PREFAT;
      V_DADOS_NOTAS.TIPOMOV      := P_TIPOMOV;
      V_DADOS_NOTAS.CODCONTA      := P_CODCONT;
      
      IF (P_TIPOMOV = 'S') THEN
        IF (P_PREFAT = 'S') THEN
           --PCNFSAIDPREFAT
           SELECT NVL(CODFILIALNF, CODFILIAL),
                  NUMNOTA,
                  ESPECIE,
                  CODCLI,
                  DTSAIDA
             INTO V_DADOS_NOTAS.CODFILIAL,
                  V_DADOS_NOTAS.NUMNOTA,
                  V_DADOS_NOTAS.ESPECIE,    
                  V_DADOS_NOTAS.CODCLI_FORNEC,
                  V_DADOS_NOTAS.DATA_DOCUMENTO
             FROM PCNFSAIDPREFAT
            WHERE NUMTRANSVENDA = P_NUMTRANSACAO;       
        ELSE
          --PCNFSAID
          SELECT NVL(CODFILIALNF, CODFILIAL),
                  NUMNOTA,
                  ESPECIE,
                  CODCLI,
                  DTSAIDA
             INTO V_DADOS_NOTAS.CODFILIAL,
                  V_DADOS_NOTAS.NUMNOTA,
                  V_DADOS_NOTAS.ESPECIE,    
                  V_DADOS_NOTAS.CODCLI_FORNEC,
                  V_DADOS_NOTAS.DATA_DOCUMENTO
             FROM PCNFSAID
            WHERE NUMTRANSVENDA = P_NUMTRANSACAO; 
        END IF;   
      ELSE
        --PCNFENT
        SELECT NVL(CODFILIALNF, CODFILIAL),
                 NUMNOTA,
                 ESPECIE,
                 CODFORNEC,
                 DTENT
            INTO V_DADOS_NOTAS.CODFILIAL,
                 V_DADOS_NOTAS.NUMNOTA,
                 V_DADOS_NOTAS.ESPECIE,    
                 V_DADOS_NOTAS.CODCLI_FORNEC,
                 V_DADOS_NOTAS.DATA_DOCUMENTO
            FROM PCNFENT
           WHERE NUMTRANSENT = P_NUMTRANSACAO
             AND CODCONT = P_CODCONT; 
      END IF;  
      
      V_DADOS_NOTAS.MSG := 'OK';
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
            V_DADOS_NOTAS.MSG := 'ERRO: NOTA FISCAL NÃO ENCONTRADA PARA A TRANSAÇÃO INFORMADA.';
       WHEN OTHERS THEN
            V_DADOS_NOTAS.MSG := 'ERRO: NÃO FOI POSSÍVEL OBTER DADOS DA NOTA FISCAL.';     
    END;
         
  END;
  
  /**********************************************************************************************/
  /* Método privado que valida as informações referente ao ICMS, de acordo com cada CST e campos*/
  /* obrigatórios no manual da NFE                                                              */
  /**********************************************************************************************/
  FUNCTION VALIDAR_ICMS(V_ICMS IN T_ICMS) RETURN VARCHAR2 IS
    V_LISTA_ERROS VARCHAR2(4000);
    V_MSG_IGUAL VARCHAR2(100);
  BEGIN
    V_LISTA_ERROS := ''; 
    V_MSG_IGUAL := 'PARA CST "' || V_ICMS.SITTRIBUT || '", ';  
    
    IF ((V_ICMS.SITTRIBUT = '00') OR (V_ICMS.SITTRIBUT = '51')) THEN
      --ICMS00/ ICMS51
      IF (V_ICMS.BASEICMS = 0) THEN
          ADD_ERRO(V_LISTA_ERROS, V_MSG_IGUAL || 'A BASE DE ICMS NÃO PODE SER ZERO!');
      END IF;
      
      IF (V_ICMS.PERCICM = 0) THEN
         ADD_ERRO(V_LISTA_ERROS, V_MSG_IGUAL || 'O PERCENTUAL DE ICMS NÃO PODE SER ZERO!');
      END IF;
    ELSIF (V_ICMS.SITTRIBUT = '10') THEN
      --ICMS10
      IF (V_ICMS.BASEICMS = 0) THEN
          ADD_ERRO(V_LISTA_ERROS, V_MSG_IGUAL || 'A BASE DE ICMS NÃO PODE SER ZERO!');
      END IF;
      
      IF (V_ICMS.PERCICM = 0) THEN
          ADD_ERRO(V_LISTA_ERROS, V_MSG_IGUAL || 'O PERCENTUAL DE ICMS NÃO PODE SER ZERO!');
      END IF;
      
      IF (V_ICMS.BASEICST = 0) THEN
          ADD_ERRO(V_LISTA_ERROS, V_MSG_IGUAL || 'A BASE DE ICMS ST NÃO PODE SER ZERO!');
      END IF;
      
      IF (V_ICMS.ALIQICMS1 = 0) THEN
          ADD_ERRO(V_LISTA_ERROS, V_MSG_IGUAL || 'O PERCENTUAL DE ICMS ST(ALIQICMS1) NÃO PODE SER ZERO!');
      END IF;
      
      IF (V_ICMS.ALIQICMS2 = 0) THEN
          ADD_ERRO(V_LISTA_ERROS, V_MSG_IGUAL || 'O PERCENTUAL DE ICMS ST(ALIQICMS2) NÃO PODE SER ZERO!');
      END IF;
      
      IF (V_ICMS.VLST = 0) THEN
          ADD_ERRO(V_LISTA_ERROS, V_MSG_IGUAL || 'O VALOR DE ICMS ST NÃO PODE SER ZERO!');
      END IF;
    ELSIF (V_ICMS.SITTRIBUT = '20') THEN 
      --ICMS20 
      IF (V_ICMS.BASEICMS = 0) THEN
          ADD_ERRO(V_LISTA_ERROS, V_MSG_IGUAL || 'A BASE DE ICMS NÃO PODE SER ZERO!');
      END IF;
      
      IF (V_ICMS.PERCICM = 0) THEN
         ADD_ERRO(V_LISTA_ERROS, V_MSG_IGUAL || 'O PERCENTUAL DE ICMS NÃO PODE SER ZERO!');
      END IF;
      
      IF (V_ICMS.PERCBASERED = 0) THEN
         ADD_ERRO(V_LISTA_ERROS, V_MSG_IGUAL || 'O PERCENTUAL DE REDUÇÃO NA BASE DE CÁLCULO DE ICMS NÃO PODE SER ZERO!');
      END IF;
    ELSIF (V_ICMS.SITTRIBUT = '30') THEN
      --ICMS30
      IF (V_ICMS.BASEICST = 0) THEN
          ADD_ERRO(V_LISTA_ERROS, V_MSG_IGUAL || 'A BASE DE ICMS ST NÃO PODE SER ZERO!');
      END IF;
      
      IF (V_ICMS.ALIQICMS1 = 0) THEN
          ADD_ERRO(V_LISTA_ERROS, V_MSG_IGUAL || 'O PERCENTUAL DE ICMS ST(ALIQICMS1) NÃO PODE SER ZERO!');
      END IF;
      
      IF (V_ICMS.VLST = 0) THEN
          ADD_ERRO(V_LISTA_ERROS, V_MSG_IGUAL || 'O VALOR DE ICMS ST NÃO PODE SER ZERO!');
      END IF;    
    ELSIF (V_ICMS.SITTRIBUT = '70') THEN
      --ICMS70
      IF (V_ICMS.BASEICMS = 0) THEN
          ADD_ERRO(V_LISTA_ERROS, V_MSG_IGUAL || 'A BASE DE ICMS NÃO PODE SER ZERO!');
      END IF;
      
      IF (V_ICMS.PERCICM = 0) THEN
          ADD_ERRO(V_LISTA_ERROS, V_MSG_IGUAL || 'O PERCENTUAL DE ICMS NÃO PODE SER ZERO!');
      END IF;
      
      IF (V_ICMS.BASEICST = 0) THEN
          ADD_ERRO(V_LISTA_ERROS, V_MSG_IGUAL || 'A BASE DE ICMS ST NÃO PODE SER ZERO!');
      END IF;
      
      IF (V_ICMS.ALIQICMS1 = 0) THEN
          ADD_ERRO(V_LISTA_ERROS, V_MSG_IGUAL || 'O PERCENTUAL DE ICMS ST(ALIQICMS1) NÃO PODE SER ZERO!');
      END IF;
      
      IF (V_ICMS.ALIQICMS2 = 0) THEN
          ADD_ERRO(V_LISTA_ERROS, V_MSG_IGUAL || 'O PERCENTUAL DE ICMS ST(ALIQICMS2) NÃO PODE SER ZERO!');
      END IF;
      
      IF (V_ICMS.VLST = 0) THEN
          ADD_ERRO(V_LISTA_ERROS, V_MSG_IGUAL || 'O VALOR DE ICMS ST NÃO PODE SER ZERO!');
      END IF;
      
      IF (V_ICMS.PERCBASEREDST = 0) THEN
         ADD_ERRO(V_LISTA_ERROS, V_MSG_IGUAL || 'O PERCENTUAL DE REDUÇÃO NA BASE DE CÁLCULO DE ICMS ST NÃO PODE SER ZERO!');
      END IF;
    END IF;  
    
    IF (V_LISTA_ERROS IS NOT NULL) THEN
      RETURN V_LISTA_ERROS;
    ELSE
      RETURN 'OK';
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
        V_DADOS_NOTAS.MSG := 'ERRO NA VALIDAÇÃO DO ICMS.';     
  END;

  /**********************************************************************************************/
  /****************************************  PUBLIC  ********************************************/  

  /**********************************************************************************************/
  /* Método que realiza todas as chamadas de objetos fiscais, calculos e afins, em um único     */
  /* local para NOTAS de SAIDA                                                                  */
  /**********************************************************************************************/
  FUNCTION PROCESSAR_NF_SAIDA(P_NUMTRANSACAO IN PCNFSAID.NUMTRANSVENDA%TYPE, P_PREFAT IN VARCHAR2) RETURN VARCHAR2 IS
    
    V_LISTA_ERROS VARCHAR2(4000);
    V_RETORNO_TEMP VARCHAR2(1);
 
  BEGIN    
    V_LISTA_ERROS := '';
    V_RETORNO_TEMP := '';
    GET_DADOS_NOTAS(P_NUMTRANSACAO, P_PREFAT, 'S', 0);   
       
    IF (V_DADOS_NOTAS.MSG <> 'OK') THEN
      RETURN V_DADOS_NOTAS.MSG;
    END IF;  
    ---------------------------------------------  
    V_DADOS_NOTAS.MSG := '';              
    GERA_HISTORICO.GERA_HISTORICO(V_DADOS_NOTAS.CODFILIAL,
                                  V_DADOS_NOTAS.DATA_DOCUMENTO,
                                  V_DADOS_NOTAS.DATA_DOCUMENTO,
                                  V_DADOS_NOTAS.NUMTRANSACAO,
                                  V_DADOS_NOTAS.TIPOMOV,
                                  V_DADOS_NOTAS.CODCLI_FORNEC,
                                  'S',
                                  V_DADOS_NOTAS.MSG);
    ADD_ERRO(V_LISTA_ERROS, V_DADOS_NOTAS.MSG);
    ---------------------------------------------
    V_DADOS_NOTAS.MSG := '';    
    V_RETORNO_TEMP := FISCAL.CALCULARPISCOFINS_VENDA(V_DADOS_NOTAS.NUMTRANSACAO,
                                                     V_DADOS_NOTAS.MSG);
    ADD_ERRO(V_LISTA_ERROS, V_DADOS_NOTAS.MSG);          
    ---------------------------------------------    
    V_DADOS_NOTAS.MSG := '';    
    V_RETORNO_TEMP := FISCAL.CALCULARDESONERACAOICMS_SAIDA(V_DADOS_NOTAS.NUMTRANSACAO,
                                                           V_DADOS_NOTAS.MSG);
    ADD_ERRO(V_LISTA_ERROS, V_DADOS_NOTAS.MSG); 
    ---------------------------------------------
    --FISCAL.OBTERCODIGOCEST_1_3
    --FISCAL.CALCULAR_PARTILHA_ICMS_1_5
    
    IF (V_LISTA_ERROS IS NOT NULL) THEN
      RETURN V_LISTA_ERROS;
    ELSE
      RETURN 'OK';
    END IF;
  END;
  /**********************************************************************************************/
  /* Método que realiza todas as chamadas de objetos fiscais, calculos e afins, em um único     */
  /* local para NOTAS de ENTRADA                                                                */
  /**********************************************************************************************/
  FUNCTION PROCESSAR_NF_ENTRADA(P_NUMTRANSACAO IN PCNFENT.NUMTRANSENT%TYPE, P_CODCONT IN PCNFENT.CODCONT%TYPE) RETURN VARCHAR2 IS
  BEGIN    
    --GERA_HISTORICO
    --OBTERCDCEST
    --CALCULAR_PARTILHA
    
    RETURN 'OK'; 
  END;
  /**********************************************************************************************/
  /* Método que realiza todas as chamadas de objetos fiscais, calculos e afins, em um único     */
  /* local para CONHECIMENTO DE TRANSPORTE de SAIDA                                             */
  /**********************************************************************************************/
  FUNCTION PROCESSAR_CT_SAIDA(P_NUMTRANSACAO IN PCNFSAID.NUMTRANSVENDA%TYPE) RETURN VARCHAR2 IS
  BEGIN    
    --GERA_HISTORICO
    --CALCULAR_PARTILHA_CTE
    --CALCULARPISCOFINS_TRANSPORTE
    
    RETURN 'OK'; 
  END;
  /**********************************************************************************************/
  /* Método que faz a validação completa do cadastro de produtos, deve ser chamado antes de     */
  /* gravar alterações/inclusções de produto na rotina 203                                      */
  /**********************************************************************************************/
  FUNCTION VALIDAR_CADASTRO_PRODUTO(P_CODPROD IN PCPRODUT.CODPROD%TYPE) RETURN VARCHAR2 IS
    V_LISTA_ERROS VARCHAR2(4000);
    V_PROD        PCPRODUT%ROWTYPE;
  BEGIN    
    IF (P_CODPROD = 0) THEN
       RETURN 'PRODUTO NÃO ENCONTRADO.';  
    END IF;
    
    SELECT *
      INTO V_PROD
      FROM PCPRODUT
     WHERE CODPROD = P_CODPROD;
     
     --INICIAR VALIDAÇÕES  
  
    RETURN 'OK'; 
  END;
  /**********************************************************************************************/
  /* Método que faz a validação completa da tributação de venda, deve ser chamado antes de      */
  /* gravar alterações/inclusoções na rotina 514                                                */
  /**********************************************************************************************/
  FUNCTION VALIDAR_CADASTRO_TRIBUT_VENDA(P_CODST IN PCTRIBUT.CODST%TYPE) RETURN VARCHAR2 IS
  BEGIN    
    RETURN 'OK'; 
  END;  
  /**********************************************************************************************/
  /* Método que faz a validação completa de notas de saida                                      */
  /**********************************************************************************************/
  FUNCTION VALIDAR_NOTA_SAIDA(P_NUMTRANSACAO IN PCNFSAID.NUMTRANSVENDA%TYPE, P_PREFAT IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN    
    RETURN 'OK'; 
  END;
  /**********************************************************************************************/
  /* Método que faz a validação completa de notas de entrada                                    */
  /**********************************************************************************************/
  FUNCTION VALIDAR_NOTA_ENTRADA(P_NUMTRANSACAO IN PCNFENT.NUMTRANSENT%TYPE, P_CODCONT IN PCNFENT.CODCONT%TYPE) RETURN VARCHAR2 IS
  BEGIN
    RETURN 'OK';                  
  END;
      
END; 