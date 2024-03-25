CREATE OR REPLACE FUNCTION FNC_DADOS_CAMPANHAS(P_NUMVERBACAMPANHA IN NUMBER,
                                               P_NUMPED           IN NUMBER,
                                               P_CODPROD          IN NUMBER,
                                               P_NUMSEQ           IN NUMBER,
                                               P_DTINICIOVIGENCIA  OUT DATE,
                                               P_DTFIMVIGENCIA     OUT DATE,
                                               P_MSG_RETORNO       OUT VARCHAR2,
                                               P_VLAPLICUNITARIO   OUT NUMBER)
RETURN VARCHAR2 IS
  V_CODDESCONTO  PCPEDI.CODDESCONTO%TYPE;
  V_CODCOMBO     PCPEDI.CODCOMBO%TYPE;
  V_CODPRECOFIXO PCPEDI.CODPRECOFIXO%TYPE;
  V_CODIGOBRINDE PCPEDI.CODIGOBRINDE%TYPE;
  V_CONTREGVERBACUMULATIVA NUMBER(10);
  V_VLVERBAAPLICUNITARIO PCAUXVERBACUMULATIVAPROD.VLVERBACMV%TYPE;

BEGIN 
  V_CONTREGVERBACUMULATIVA := 0;
  V_VLVERBAAPLICUNITARIO   := 0;

  SELECT NVL(CODDESCONTO, 0) CODDESCONTO,
         NVL(CODCOMBO, 0) CODCOMBO,
         NVL(CODPRECOFIXO, 0) CODPRECOFIXO,
         NVL(CODIGOBRINDE, 0) CODIGOBRINDE,
         NVL(VLVERBACMV, 0) VLVERBACMV
    INTO V_CODDESCONTO,
         V_CODCOMBO,
         V_CODPRECOFIXO,
         V_CODIGOBRINDE,
         V_VLVERBAAPLICUNITARIO
    FROM PCPEDI
   WHERE NUMPED = P_NUMPED
     AND CODPROD = P_CODPROD
     AND NUMSEQ = P_NUMSEQ;
  
  IF NVL(P_NUMVERBACAMPANHA,0) <> 0
    THEN
      BEGIN
        SELECT COUNT(*)
          INTO V_CONTREGVERBACUMULATIVA
          FROM PCAUXVERBACUMULATIVAPROD
         WHERE NUMPED = P_NUMPED
          AND CODPROD = P_CODPROD
          AND NUMSEQ = P_NUMSEQ
          AND NUMVERBACMV = P_NUMVERBACAMPANHA;         
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_CONTREGVERBACUMULATIVA := 0;    
      END;
  
    IF V_CONTREGVERBACUMULATIVA > 0
      THEN
        BEGIN
          SELECT NVL(VLVERBACMV,0) VLVERBACMV
            INTO V_VLVERBAAPLICUNITARIO
            FROM PCAUXVERBACUMULATIVAPROD
           WHERE NUMPED = P_NUMPED
             AND CODPROD = P_CODPROD
             AND NUMSEQ = P_NUMSEQ
             AND NUMVERBACMV = P_NUMVERBACAMPANHA;        
        EXCEPTION
          WHEN OTHERS THEN
            V_VLVERBAAPLICUNITARIO := 0;   
        END;    
    END IF;
    
    P_VLAPLICUNITARIO := V_VLVERBAAPLICUNITARIO;
    
  END IF;

  IF V_CODDESCONTO <> 0 THEN  
    BEGIN    
      SELECT DTINICIO,
             DTFIM
        INTO P_DTINICIOVIGENCIA,
             P_DTFIMVIGENCIA
        FROM PCDESCONTO
       WHERE CODDESCONTO = V_CODDESCONTO
         AND NUMVERBA = P_NUMVERBACAMPANHA;
    
      P_MSG_RETORNO := 'Desconto da 561 encontrado na PCDESCONTO.';
      RETURN 'S';
    EXCEPTION
      WHEN OTHERS THEN
        BEGIN
          SELECT DTINICIO,
                 DTFIM
            INTO P_DTINICIOVIGENCIA,
                 P_DTFIMVIGENCIA
            FROM PCDESCONTOLOG
           WHERE CODDESCONTO = V_CODDESCONTO
             AND NUMVERBA = P_NUMVERBACAMPANHA;
          
          P_MSG_RETORNO := 'Desconto da 561 encontrado em PCDESCONTOLOG.';
          RETURN 'S';
        EXCEPTION
          WHEN OTHERS THEN
            P_MSG_RETORNO := 'A política de número ' || V_CODDESCONTO || ' não foi encontrada na PCDESCONTO ou PCDESCONTOLOG para essa verba.';
            RETURN 'N';
        END;
    END;  
  END IF;

  IF V_CODCOMBO <> 0 THEN  
    BEGIN
      SELECT DTINICIO,
             DTFIM
        INTO P_DTINICIOVIGENCIA,
             P_DTFIMVIGENCIA
        FROM PCDESCONTOC
       WHERE CODIGO = V_CODCOMBO
         AND NUMVERBA = P_NUMVERBACAMPANHA;
    
      P_MSG_RETORNO := 'Desconto da 3306 encontrado.';
      RETURN 'S';    
    EXCEPTION
      WHEN OTHERS THEN
        P_MSG_RETORNO := 'A campanha de número ' || V_CODCOMBO || ' não foi encontrada na PCDESCONTOC para essa verba.';
        RETURN 'N';
    END;  
  END IF;

  IF V_CODPRECOFIXO <> 0 THEN
    BEGIN    
      SELECT DTINICIOVIGENCIA,
             DTFIMVIGENCIA
        INTO P_DTINICIOVIGENCIA,
             P_DTFIMVIGENCIA
        FROM PCPRECOPROM
       WHERE CODPRECOPROM = V_CODPRECOFIXO
         AND NUMVERBA = P_NUMVERBACAMPANHA;
    
      P_MSG_RETORNO := 'Desconto da 357 encontrado na PCPRECOPROM.';
      RETURN 'S';    
    EXCEPTION
      WHEN OTHERS THEN
        BEGIN        
          SELECT DTINICIOVIGENCIA,
                 DTFIMVIGENCIA
            INTO P_DTINICIOVIGENCIA,
                 P_DTFIMVIGENCIA
            FROM PCPRECOPROMLOG
           WHERE CODPRECOPROM = V_CODPRECOFIXO
             AND NUMVERBA = P_NUMVERBACAMPANHA;
        
          P_MSG_RETORNO := 'Desconto da 357 encontrado na PCPRECOPROMLOG.';
          RETURN 'S';
        
        EXCEPTION
          WHEN OTHERS THEN
            P_MSG_RETORNO := 'A política de número ' || V_CODPRECOFIXO || ' não foi encontrada na PCPRECOPROM ou PCPRECOPROMLOG para essa verba.';
            RETURN 'N';          
        END;     
    END;  
  END IF;

  IF V_CODIGOBRINDE <> 0 THEN  
    BEGIN
      SELECT DTINICIO,
             DTFIM
        INTO P_DTINICIOVIGENCIA,
             P_DTFIMVIGENCIA
        FROM PCBRINDEEX
       WHERE CODBREX = V_CODIGOBRINDE
         AND NUMVERBA = P_NUMVERBACAMPANHA;
    
      P_MSG_RETORNO := 'Política de brinde da 3320 encontrada.';
      RETURN 'S';
    EXCEPTION
      WHEN OTHERS THEN
        P_MSG_RETORNO := 'A política de brinde de número ' || V_CODIGOBRINDE || ' não foi encontrada na PCBRINDEEX para essa verba.';
        RETURN 'N';      
    END;  
  END IF;

  P_MSG_RETORNO := 'Não foi encontrada nenhuma política de desconto.';
  RETURN 'N';
EXCEPTION
  WHEN OTHERS THEN  
    P_MSG_RETORNO := 'Dados não localizados na PCPEDI com os parâmetros informados. ' 
                     || SQLCODE || '-' || SQLERRM || '-' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    RETURN 'N';  
END FNC_DADOS_CAMPANHAS;