CREATE OR REPLACE FUNCTION FNC_DADOS_CAMPANHAS(PNUMVERBACAMPANHA IN NUMBER,
                                               PNUMPED           IN NUMBER,
                                               PCODPROD          IN NUMBER,
                                               PNUMSEQ           IN NUMBER,
                                               DTINICIOVIGENCIA  OUT DATE,
                                               DTFIMVIGENCIA     OUT DATE,
                                               MSG_RETORNO       OUT VARCHAR2)

 RETURN VARCHAR2 IS

  CODDESCONTO  PCPEDI.CODDESCONTO%TYPE;
  CODCOMBO     PCPEDI.CODCOMBO%TYPE;
  CODPRECOFIXO PCPEDI.CODPRECOFIXO%TYPE;
  CODIGOBRINDE PCPEDI.CODIGOBRINDE%TYPE;

BEGIN

  SELECT nvl(CODDESCONTO, 0) CODDESCONTO,
         NVL(CODCOMBO, 0) CODCOMBO,
         NVL(CODPRECOFIXO, 0) CODPRECOFIXO,
         NVL(CODIGOBRINDE, 0) CODIGOBRINDE
    into CODDESCONTO, CODCOMBO, CODPRECOFIXO, CODIGOBRINDE
    FROM PCPEDI
   WHERE NUMPED = PNUMPED
     AND CODPROD = PCODPROD
     AND NUMSEQ = PNUMSEQ;

  IF CODDESCONTO <> 0 THEN
  
    BEGIN
    
      SELECT DTINICIO, DTFIM
        INTO DTINICIOVIGENCIA, DTFIMVIGENCIA
        FROM PCDESCONTO
       WHERE CODDESCONTO = CODDESCONTO
         AND NUMVERBA = PNUMVERBACAMPANHA;
    
      MSG_RETORNO := 'Desconto da 561 encontrado na PCDESCONTO';
      RETURN 'S';
    EXCEPTION
      WHEN OTHERS THEN
        BEGIN
          SELECT DTINICIO, DTFIM
            INTO DTINICIOVIGENCIA, DTFIMVIGENCIA
            FROM PCDESCONTOLOG
           WHERE CODDESCONTO = CODDESCONTO
             AND NUMVERBA = PNUMVERBACAMPANHA;
        
          MSG_RETORNO := 'Desconto da 561 encontrado em PCDESCONTOLOG';
          RETURN 'S';
        EXCEPTION
          WHEN OTHERS THEN
            MSG_RETORNO := 'A política de nÃºmero ' || coddesconto ||
                           ' não foi encontrada na PCDESCONTO ou PCDESCONTOLOG para essa verba.';
            RETURN 'N';
        END;
    END;
  
  END IF;

  IF CODCOMBO <> 0 THEN
  
    BEGIN
      SELECT DTINICIO, DTFIM
        INTO DTINICIOVIGENCIA, DTFIMVIGENCIA
        FROM PCDESCONTOC
       WHERE CODIGO = CODCOMBO
         AND NUMVERBA = PNUMVERBACAMPANHA;
    
      MSG_RETORNO := 'Desconto da 3306 encontrado';
      RETURN 'S';
    
    EXCEPTION
      WHEN OTHERS THEN
        MSG_RETORNO := 'A campanha de número ' || CODCOMBO ||
                       ' não foi encontrada na PCDESCONTOC para essa verba.';
        RETURN 'N';
      
    END;
  
  END IF;

  IF CODPRECOFIXO <> 0 THEN
  
    BEGIN
    
      SELECT DTINICIOVIGENCIA, DTFIMVIGENCIA
        INTO DTINICIOVIGENCIA, DTFIMVIGENCIA
        FROM PCPRECOPROM
       WHERE CODPRECOPROM = CODPRECOFIXO
         AND NUMVERBA = PNUMVERBACAMPANHA;
    
      MSG_RETORNO := 'Desconto da 357 encontrado na PCPRECOPROM';
      RETURN 'S';
    
    EXCEPTION
      WHEN OTHERS THEN
        BEGIN
        
          SELECT DTINICIOVIGENCIA, DTFIMVIGENCIA
            INTO DTINICIOVIGENCIA, DTFIMVIGENCIA
            FROM PCPRECOPROMLOG
           WHERE CODPRECOPROM = CODPRECOFIXO
             AND NUMVERBA = PNUMVERBACAMPANHA;
        
          MSG_RETORNO := 'Desconto da 357 encontrado na PCPRECOPROMLOG';
          RETURN 'S';
        
        EXCEPTION
          WHEN OTHERS THEN
            MSG_RETORNO := 'A política de número ' || CODPRECOFIXO ||
                           ' não foi encontrada na PCPRECOPROM ou PCPRECOPROMLOG para essa verba.';
            RETURN 'N';
          
        END;
      
    END;
  
  END IF;

  IF CODIGOBRINDE <> 0 THEN
  
    BEGIN
      SELECT DTINICIO, DTFIM
        INTO DTINICIOVIGENCIA, DTFIMVIGENCIA
        FROM PCBRINDEEX
       WHERE codbrex = CODIGOBRINDE
         AND NUMVERBA = PNUMVERBACAMPANHA;
    
      MSG_RETORNO := 'Política de brinde da 3320 encontrada';
      RETURN 'S';
    EXCEPTION
      WHEN OTHERS THEN
        MSG_RETORNO := 'A política de brinde de número ' || CODIGOBRINDE ||
                       ' não foi encontrada na PCBRINDEEX para essa verba.';
        RETURN 'N';
      
    END;
  
  END IF;

  MSG_RETORNO := 'Não foi encontrada nenhuma política de desconto';
  RETURN 'N';

EXCEPTION
  WHEN OTHERS THEN
  
    MSG_RETORNO := 'Dados não localizados na PCPEDI com os parâmetros informados.';
    RETURN 'N';
  
END FNC_DADOS_CAMPANHAS;