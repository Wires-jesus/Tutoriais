CREATE OR REPLACE FUNCTION RETORNA_COD_BENEF_FISCAL(P_TIPOOPER       IN     VARCHAR2
                                                   ,P_CODCLI_FORNEC  IN     NUMBER
                                                   ,P_CODENDENT      IN     NUMBER
                                                   ,P_CODPROD        IN     NUMBER
                                                   ,P_CODFILIAL      IN     VARCHAR2
                                                   ,P_CODST          IN     NUMBER
                                                   ,P_MSG            IN OUT VARCHAR2
                                                   ,P_SUCESSO           OUT BOOLEAN
												   ,P_CSTICMS        IN VARCHAR2 DEFAULT ''
                                                   ,P_CODFISCAL      IN NUMBER DEFAULT 0)
  RETURN VARCHAR2 IS
  /**********************************************************************************
   *P_CODCLI_FORNEC = PODE SER CLIENTE OU FORNECEDOR. DEPENDENDO DO TIPO DE ENTRADA,*
   *                 ELE Ã‰ TRATADO COMO FORNECEDOR, CASO SEJA ENTRADA, OU CLIENTE,  *
   *                 EM CASOS DE SAÃDA.                                             *
   *********************************************************************************/

  VSTIPOCLIFORNEC    VARCHAR2(6);
  VNCODPROD    PCPRODUT.CODPROD%TYPE;
  VSNCM        PCPRODUT.NBM%TYPE;
  CODBENEFICIO PCCODIGOBENEFICIOFISCALVINCULO.CODIGOBENEFICIO%TYPE;
  VSUFDEST     PCCLIENT.ESTENT%TYPE;
  VSUFORIG     PCFILIAL.UF%TYPE;  
BEGIN
  P_SUCESSO := TRUE;
  P_MSG     := '';

  FOR CLIENTE IN (SELECT C.CODCLI
                        ,C.TIPOEMPRESA
                        ,C.SULFRAMA
                        ,C.DTVENCSUFRAMA
                        ,NVL(C.CONSUMIDORFINAL, 'N') CONSUMIDORFINAL
                        ,NVL(C.ORGAOPUB, 'N') ORGAOPUB
                        ,NVL(C.ORGAOPUBFEDERAL, 'N') ORGAOPUBFEDERAL
                        ,C.ESTENT
                    FROM PCCLIENT C
                   WHERE C.CODCLI = P_CODCLI_FORNEC
                     AND P_TIPOOPER IN ('S', 'D') )
  LOOP
    VSTIPOCLIFORNEC := 'NORM';
  
    --SIMPLES NACIONAL
    IF CLIENTE.TIPOEMPRESA = 'SN'
    THEN
      VSTIPOCLIFORNEC := 'SIMPN';
    END IF;
  
    --CONSUMIDOR FINAL
    IF CLIENTE.CONSUMIDORFINAL = 'S'
    THEN
      VSTIPOCLIFORNEC := 'CONSF';
    END IF;
  
    -- NRPA
    IF CLIENTE.TIPOEMPRESA = 'NRPA'
    THEN
      VSTIPOCLIFORNEC := 'NRPA';
    END IF;
  
    --ORGÃƒO PUBLICO
    IF (CLIENTE.ORGAOPUB = 'S') OR (CLIENTE.ORGAOPUBFEDERAL = 'S')
    THEN
      VSTIPOCLIFORNEC := 'ORGP';
    END IF;
  
    -- REGIME ESPECIAL
    IF CLIENTE.TIPOEMPRESA = 'R'
    THEN
      VSTIPOCLIFORNEC := 'REGE';
    END IF;
  
    -- SULFRAMA
    IF (CLIENTE.DTVENCSUFRAMA >= TRUNC(SYSDATE)) AND
       (CLIENTE.SULFRAMA IS NOT NULL)
    THEN
      VSTIPOCLIFORNEC := 'SUFRA';
    END IF;
  
    BEGIN
      SELECT C.ESTENT
        INTO VSUFDEST
        FROM PCCLIENTENDENT C
       WHERE C.CODCLI = CLIENTE.CODCLI
         AND C.CODENDENTCLI = P_CODENDENT;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        VSUFDEST := CLIENTE.ESTENT;
    END;
  END LOOP;

  BEGIN
    SELECT P.CODPROD, P.NBM
      INTO VNCODPROD, VSNCM
      FROM PCPRODUT P
     WHERE P.CODPROD = P_CODPROD;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      P_MSG     := 'Produto nÃ£o localizado';
      P_SUCESSO := FALSE;
      RETURN '';
    WHEN OTHERS THEN
      P_MSG     := 'Erro ao buscar Produto' || CHR(13) || SQLCODE || ' - ' ||
                   SQLERRM;
      P_SUCESSO := FALSE;
      RETURN '';
  END;

  BEGIN
    SELECT F.UF
      INTO VSUFORIG
      FROM PCFILIAL F
     WHERE F.CODIGO = P_CODFILIAL;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      P_MSG     := 'UF da filial nÃ£o localizado';
      P_SUCESSO := FALSE;
      RETURN '';
    WHEN OTHERS THEN
      P_MSG     := 'Erro ao buscar Filial' || CHR(13) || SQLCODE || ' - ' ||
                   SQLERRM;
      P_SUCESSO := FALSE;
      RETURN '';
  END;

  IF P_TIPOOPER = 'E' THEN
    VSUFDEST := VSUFORIG;--INVERTER POR O DESTINO PASSA A SER A FILIAL.

    BEGIN
      SELECT NVL(F.TIPOFORNEC, 'I'), ESTADO
        INTO VSTIPOCLIFORNEC, VSUFORIG
        FROM PCFORNEC F
       WHERE F.CODFORNEC = P_CODCLI_FORNEC;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        P_MSG     := 'Fornecedor nÃ£o localizado';
        P_SUCESSO := FALSE;
        RETURN '';
      WHEN OTHERS THEN
        P_MSG     := 'Erro ao buscar Fornecedor' || CHR(13) || SQLCODE || ' - ' ||
                     SQLERRM;
        P_SUCESSO := FALSE;
        RETURN '';
    END;
  END IF;

  CODBENEFICIO := GET_CODIGO_BENEFICIO_FISCAL(CASE WHEN  P_TIPOOPER = 'D' THEN 'E' ELSE P_TIPOOPER END,  -- P_NATUREZAVINCULO   IN     VARCHAR2,
                                              VSTIPOCLIFORNEC, -- P_TIPOCLIENTEFORNEC IN     VARCHAR2,
                                              P_CODFILIAL,     -- P_CODFILIAL         IN     VARCHAR2,
                                              VNCODPROD,       -- P_CODPROD           IN     NUMBER,
                                              VSUFORIG,        -- P_UFORIGEM          IN     VARCHAR2,
                                              VSUFDEST,        -- P_UFDESTINO         IN     VARCHAR2,
                                              VSNCM,           -- P_NCM               IN     VARCHAR2,
                                              P_CODST,         -- P_FIGURATRIBUTARIA  IN     VARCHAR2,
                                              P_MSG,           -- P_MENSAGEM_RETORNO  IN OUT VARCHAR2,
                                              P_CSTICMS,       -- P_CSTICMS IN VARCHAR2 DEFAULT '',
                                              P_CODFISCAL,     -- P_CODFISCAL IN NUMBER DEFAULT 0,
                                              P_CODCLI_FORNEC, -- P_CODCLI IN NUMBER DEFAULT 0,
                                              'S'              -- P_NOVOPROCESSO IN VARCHAR2 DEFAULT 'N'
                                              );
  IF (UPPER(SUBSTR(P_MSG, 1, 1)) = 'N')
  THEN
    P_SUCESSO := FALSE;
    RETURN NULL;
  ELSE
    RETURN CODBENEFICIO;
  END IF;

END;