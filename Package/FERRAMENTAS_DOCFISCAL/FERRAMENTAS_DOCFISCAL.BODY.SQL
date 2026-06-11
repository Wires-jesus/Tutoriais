CREATE OR REPLACE PACKAGE BODY FERRAMENTAS_DOCFISCAL IS

  FUNCTION SINC_INFOXML_SAIDA_ENTRADA(pNumtransvenda IN pcnfsaid.numtransvenda%type, pMensagemRetorno OUT VARCHAR2) 
    RETURN VARCHAR2 IS
    PINFOXML T_INFOXML;
    VOBSNFE CLOB;
    vRetono VARCHAR2(1) := 'S';
    FUNCTION OBTER_NUMTRANSITEM(PTRANS IN NUMBER, PPROD IN NUMBER, PSEQ IN NUMBER, PQTDE IN NUMBER, PPRECO IN NUMBER)
       RETURN PCMOV.NUMTRANSITEM%TYPE IS
       V_RETORNO PCMOV.NUMTRANSITEM%TYPE;
       V_QTDEREG NUMBER;
    BEGIN
      SELECT MIN(NUMTRANSITEM) RETORNO
           , COUNT(NUMTRANSITEM) QTDEREG
        INTO V_RETORNO
           , V_QTDEREG
        FROM PCMOV
       WHERE NUMTRANSENT = PTRANS
         AND CODPROD = PPROD
         AND NUMSEQ = PSEQ;
         
      IF V_QTDEREG > 1 THEN
        FOR REG IN (SELECT P.NUMTRANSITEM RETORNO
                         , PCDADOSXML.NUMTRANSITEM EXISTE
                      FROM PCMOV P
                         , PCDADOSXML
                     WHERE P.NUMTRANSITEM = PCDADOSXML.NUMTRANSITEM(+)
                       AND P.NUMTRANSENT = PTRANS
                       AND P.CODPROD = PPROD
                       AND P.NUMSEQ = PSEQ
                       AND P.QTCONT = PQTDE
                       AND NVL(P.PUNITCONT, 0) = PPRECO
                  ORDER BY P.CODPROD, P.NUMSEQ, P.QTCONT, NVL(P.PUNITCONT, 0))
        LOOP
          V_RETORNO := REG.RETORNO;
          EXIT WHEN (REG.EXISTE IS NULL);
        END LOOP;
      END IF;  
      RETURN V_RETORNO;
    END;
  BEGIN
     pMensagemRetorno := 'OK';
     BEGIN
     FOR REG IN (SELECT NF.*
                   FROM (SELECT PCNFENT.NUMTRANSENT
                              , PCNFSAID.CHAVENFE
                              , PCNFSAID.NUMNOTA
                              , PCNFSAID.ESPECIE
                              , PCNFSAID.SERIE
                              , PCNFSAID.NUMTRANSVENDA
                              , ('N') PREFAT
                           FROM PCNFENT
                              , PCNFSAID
                          WHERE TRIM(PCNFSAID.CHAVENFE) IS NOT NULL
                            AND PCNFSAID.NUMTRANSENTORIGEM > 0
                            AND PCNFENT.NUMTRANSENT = PCNFSAID.NUMTRANSENTORIGEM
                            AND PCNFSAID.NUMTRANSVENDA = pNumtransvenda
                         UNION
                         SELECT PCNFENT.NUMTRANSENT
                              , PCNFSAID.CHAVENFE
                              , PCNFSAID.NUMNOTA
                              , PCNFSAID.ESPECIE
                              , PCNFSAID.SERIE
                              , PCNFSAID.NUMTRANSVENDA
                              , ('S') PREFAT
                           FROM PCNFENT
                              , PCNFSAIDPREFAT PCNFSAID
                          WHERE TRIM(PCNFSAID.CHAVENFE) IS NOT NULL
                            AND PCNFSAID.NUMTRANSENTORIGEM > 0
                            AND PCNFENT.NUMTRANSENT = PCNFSAID.NUMTRANSENTORIGEM
                            AND PCNFSAID.NUMTRANSVENDA = pNumtransvenda) NF
                  WHERE ROWNUM = 1)
     LOOP
        IF (REG.PREFAT = 'S') THEN
           SELECT P.OBSNFE
             INTO VOBSNFE
             FROM PCNFSAIDPREFAT P
            WHERE P.NUMTRANSVENDA = REG.NUMTRANSVENDA;
        ELSE
           SELECT P.OBSNFE
             INTO VOBSNFE
             FROM PCNFSAID P
            WHERE P.NUMTRANSVENDA = REG.NUMTRANSVENDA;        
        END IF;
               
        UPDATE PCNFENT
           SET CHAVENFE = REG.CHAVENFE
             , ESPECIE = REG.ESPECIE
             , SERIE = REG.SERIE
             , MODELO = DECODE(NVL(REG.CHAVENFE, '0'), '0', '01', '55')
             , NUMNOTA = REG.NUMNOTA
             , OBSNFE = VOBSNFE
         WHERE NUMTRANSENT = REG.NUMTRANSENT
           AND ESPECIE = 'TP';

        FOR ORIGEM IN (SELECT NFI.*
                         FROM (SELECT PCMOV.CODPROD
                                    , PCMOV.NUMSEQ
                                    , PCMOV.QTCONT
                                    , NVL(PCMOV.PUNITCONT, 0) PUNITCONT
                                    , PCMOV.NUMTRANSITEM
                                    , PCMOVCOMPLE.DESCRICAONFE
                                    , PCMOVCOMPLE.NITEMXML
                                    , PCMOVCOMPLE.UNIDADECOMERCIAL
                                    , PCMOVCOMPLE.XML_QCOM
                                    , PCMOVCOMPLE.XML_QTRIB
                                 FROM PCMOVCOMPLE
                                    , PCMOV
                                WHERE PCMOVCOMPLE.NUMTRANSITEM = PCMOV.NUMTRANSITEM
                                  AND PCMOV.NUMTRANSVENDA = REG.NUMTRANSVENDA
                               UNION
                               SELECT PCMOV.CODPROD
                                    , PCMOV.NUMSEQ
                                    , PCMOV.QTCONT
                                    , NVL(PCMOV.PUNITCONT, 0) PUNITCONT
                                    , PCMOV.NUMTRANSITEM
                                    , PCMOVCOMPLE.DESCRICAONFE
                                    , PCMOVCOMPLE.NITEMXML
                                    , PCMOVCOMPLE.UNIDADECOMERCIAL
                                    , PCMOVCOMPLE.XML_QCOM
                                    , PCMOVCOMPLE.XML_QTRIB
                                 FROM PCMOVCOMPLEPREFAT PCMOVCOMPLE
                                    , PCMOVPREFAT PCMOV
                                WHERE PCMOVCOMPLE.NUMTRANSITEM = PCMOV.NUMTRANSITEM
                                  AND PCMOV.NUMTRANSVENDA = REG.NUMTRANSVENDA) NFI
                     ORDER BY CODPROD, NUMSEQ, QTCONT, PUNITCONT)
        LOOP
           PINFOXML.DESCRICAONFE := ORIGEM.DESCRICAONFE;
           PINFOXML.NITEMXML := ORIGEM.NITEMXML;
           PINFOXML.NUMSEQENT := ORIGEM.NITEMXML;
           PINFOXML.UNIDADECOMERCIAL := ORIGEM.UNIDADECOMERCIAL;
           PINFOXML.XML_QCOM := ORIGEM.XML_QCOM;
           PINFOXML.XML_QTRIB := ORIGEM.XML_QTRIB;
           
           BEGIN
             PINFOXML.NUMTRANSITEM := OBTER_NUMTRANSITEM(REG.NUMTRANSENT
                                                       , ORIGEM.CODPROD
                                                       , ORIGEM.NUMSEQ
                                                       , ORIGEM.QTCONT
                                                       , ORIGEM.PUNITCONT);
                
             IF (GRAVAR_INFOXML(PINFOXML, pMensagemRetorno) = 'N') THEN
               pMensagemRetorno := pMensagemRetorno ||' Transação de entrada: '|| REG.NUMTRANSENT 
                 ||' Produto: '|| ORIGEM.CODPROD ||' Sequencia: '||ORIGEM.NUMSEQ;
               vRetono := 'N';
             END IF;            
             
             FOR DADOSXML IN (SELECT PCDADOSXML.*
                                FROM PCDADOSXML
                               WHERE PCDADOSXML.NUMTRANSITEM = ORIGEM.NUMTRANSITEM)
             LOOP
                DADOSXML.NUMTRANSITEM := PINFOXML.NUMTRANSITEM;
                IF (GRAVAR_DADOSXML(DADOSXML, pMensagemRetorno) = 'N') THEN
                   pMensagemRetorno := pMensagemRetorno ||' Transação de entrada: '|| REG.NUMTRANSENT 
                     ||' Produto: '|| ORIGEM.CODPROD ||' Sequencia: '|| ORIGEM.NUMSEQ ||' TransItem: '|| PINFOXML.NUMTRANSITEM;
                   vRetono := 'N';
                END IF;               
             END LOOP;
           EXCEPTION
              WHEN NO_DATA_FOUND THEN
                pMensagemRetorno := 'Não encontramos vinculo no destino para transação de entrada: '
                  || REG.NUMTRANSENT ||' Produto: '|| ORIGEM.CODPROD ||' Sequencia: '||ORIGEM.NUMSEQ;
                vRetono := 'N';
           END;
        END LOOP;
     END LOOP;    
     EXCEPTION
        WHEN OTHERS THEN
          pMensagemRetorno := 'Erro buscar dados da movimentação da nota com transação ' ||
                              pNumtransvenda || '. Erro orignal: ' || SQLERRM;
         vRetono := 'N';
     END;
    
     RETURN vRetono;
  END;
  
  FUNCTION GRAVAR_INFOXML(PINFOXML IN T_INFOXML, PMENSAGEMRETORNO OUT VARCHAR2)
    RETURN VARCHAR2 IS
  BEGIN
    pMensagemRetorno := 'OK';
    BEGIN
       UPDATE PCMOVCOMPLE
          SET DESCRICAONFE = PINFOXML.DESCRICAONFE
            , NITEMXML = PINFOXML.NITEMXML
            , NUMSEQENT = PINFOXML.NITEMXML
            , UNIDADECOMERCIAL = PINFOXML.UNIDADECOMERCIAL
            , XML_QCOM = PINFOXML.XML_QCOM
            , XML_QTRIB = PINFOXML.XML_QTRIB
        WHERE NUMTRANSITEM = PINFOXML.NUMTRANSITEM;
       
       IF (SQL%ROWCOUNT = 0) THEN
         UPDATE PCMOVCOMPLEPREFAT
            SET DESCRICAONFE = PINFOXML.DESCRICAONFE
              , NITEMXML = PINFOXML.NITEMXML
              , NUMSEQENT = PINFOXML.NITEMXML
              , UNIDADECOMERCIAL = PINFOXML.UNIDADECOMERCIAL
              , XML_QCOM = PINFOXML.XML_QCOM
              , XML_QTRIB = PINFOXML.XML_QTRIB
          WHERE NUMTRANSITEM = PINFOXML.NUMTRANSITEM;         
       END IF;   
    EXCEPTION
       WHEN OTHERS THEN
         pMensagemRetorno := 'Erro ao gravar dados do xml na movimentação. ' ||
                             PINFOXML.NUMTRANSITEM || '. Erro orignal: ' || SQLERRM;
        RETURN 'N';
    END;
    
    RETURN 'S';    
  END;
  
  FUNCTION GRAVAR_DADOSXML(PDADOSXML IN PCDADOSXML%ROWTYPE, pMensagemRetorno OUT VARCHAR2)
    RETURN VARCHAR2 IS
  BEGIN
    pMensagemRetorno := 'OK';
    BEGIN
      UPDATE PCDADOSXML
         SET ROW = PDADOSXML
       WHERE NUMTRANSITEM = PDADOSXML.NUMTRANSITEM;

      IF (SQL%ROWCOUNT = 0) THEN
         INSERT INTO PCDADOSXML
              VALUES PDADOSXML;
      END IF;  
    EXCEPTION
       WHEN OTHERS THEN
         pMensagemRetorno := 'Erro ao gravar dados do xml na PCDADOSXML. ' ||
                             PDADOSXML.NUMTRANSITEM || '. Erro orignal: ' || SQLERRM;
        RETURN 'N';
    END;
    
    RETURN 'S';
  END;
  
  FUNCTION GET_HORACERTA_TIMEZONE(P_UF VARCHAR2) RETURN DATE IS
    /*
    * Método que faz o cálculo da data e hora correta de acordo com o fusorário da uf
    * Author: Eddy Pereira
    *OBS: só funciona se a tabela PCESTADOTIMEZONE estiver populada. Quem popula é a rotina 820 do WTA.
    */
    V_DATA_CORRETA DATE;
    V_TIMEZONE     VARCHAR2(100);

  BEGIN
    BEGIN
      --INICIALIZA A VARIÁVEL DE RETORNO
      V_DATA_CORRETA := SYSDATE;

      --CASO A UF ESTEJA NULA, DEVOLVE A DATA DO BANCO
      IF (P_UF IS NULL) THEN
        RETURN V_DATA_CORRETA;
      END IF;

      BEGIN
        --PEGA O INTERVALO DA ZONA DA UF
        SELECT REGEXP_SUBSTR(TIMEZONE, '(-?\d{2})') TIMEZONE
          INTO V_TIMEZONE
          FROM PCESTADOTIMEZONE
         WHERE UPPER(SIGLAESTADO) = UPPER(P_UF);
      EXCEPTION
        WHEN OTHERS THEN
          --CASO NÃO TENHA REGISTRO NA TABELA, RETORNA A DATA DO BANCO
          RETURN V_DATA_CORRETA;
      END;

      --FAZ O CÁLCULO DE ACORDO COM O TIMEZONE DA UF
      SELECT CAST(((CURRENT_TIMESTAMP AT TIME ZONE 'UTC') + NUMTODSINTERVAL(V_TIMEZONE, 'HOUR')) AS DATE) AS HORA_AJUSTADA
        INTO V_DATA_CORRETA
        FROM DUAL;

      IF (V_DATA_CORRETA IS NOT NULL) THEN
        RETURN V_DATA_CORRETA;
      ELSE
        RETURN SYSDATE;
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
        RETURN V_DATA_CORRETA;
    END;
  END;
  
  FUNCTION NFE_DENEGADA(P_SITUACAONFE IN VARCHAR2,
                        P_DATAEMISSAO IN DATE := SYSDATE,
                        P_AMBIENTE IN VARCHAR2 := 'P',
                        P_UF IN VARCHAR2 := 'BR') RETURN VARCHAR2 IS
    vRetorno VARCHAR2(1);
    vDATAINICIALVIGENCIA DATE;
    vDATAFINALVIGENCIA   DATE;
  BEGIN
    BEGIN
      IF (P_SITUACAONFE IS NOT NULL) THEN
        vRetorno := 'N';  
  
        IF (NFE_EM_VIGENCIA_DE_NT('NFE-NT2024.001-CRT-MEIv1.10', P_AMBIENTE, P_UF, P_DATAEMISSAO) = 'S') THEN
          IF (P_SITUACAONFE IN ('110','205')) THEN
            vRetorno := 'S';
          END IF;
        ELSE
          IF (P_SITUACAONFE IN ('110','205','301','302','303','307')) THEN
            vRetorno := 'S';
          END IF;
        END IF;
      ELSE
        vRetorno := 'N';
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        vRetorno := 'N';
    END;

    RETURN vRetorno;    
  END;  
  
  FUNCTION CTE_DENEGADO(P_SITUACAOCTE IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    BEGIN
      IF (P_SITUACAOCTE IS NOT NULL) THEN
        IF (P_SITUACAOCTE IN ('110','205','301')) THEN
          RETURN 'S';
        ELSE
          RETURN 'N';
        END IF;
      ELSE
        RETURN 'N';
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN 'N';
    END;
  END;
  
  FUNCTION ROTINA504DESCONTINUADA RETURN VARCHAR2 IS
    V_ROTINA_DESCONTINUADA NUMBER(1);
  BEGIN
    SELECT COUNT(1) INTO V_ROTINA_DESCONTINUADA FROM PCROTDESCONTINUADAS WHERE CODIGO = '504';
      
    IF (V_ROTINA_DESCONTINUADA > 0) THEN
      RETURN 'S';
    ELSE
      RETURN 'N';
    END IF;  
  END;
    
  FUNCTION ESTA_NO_HORARIO_DE_FECHAMENTO(P_COD_FILIAL IN VARCHAR2) RETURN VARCHAR2 IS
    V_UF_FILIAL VARCHAR2(2);
    V_DATA_HORA DATE;
    V_HORA_MIN  NUMBER;
  BEGIN
    SELECT UF INTO V_UF_FILIAL FROM PCFILIAL WHERE CODIGO = P_COD_FILIAL;

    -- Data e hora correta da filial
    V_DATA_HORA := GET_HORACERTA_TIMEZONE(V_UF_FILIAL);

    -- Hora no formato HHMM (ex: 2357, 0003)
    V_HORA_MIN := TO_NUMBER(TO_CHAR(V_DATA_HORA, 'HH24MI'));

    IF (V_HORA_MIN >= 2355 OR V_HORA_MIN <= 5) THEN
      RETURN 'S';
    ELSE
      RETURN 'N';
    END IF;
  END;
  
  FUNCTION FILIAL_EM_FECHAMENTO_DIARIO(P_COD_FILIAL IN VARCHAR2) RETURN VARCHAR2 IS
    V_RESULTADO VARCHAR2(1);
  BEGIN
    BEGIN  
      IF (ROTINA504DESCONTINUADA() = 'S') AND (ESTA_NO_HORARIO_DE_FECHAMENTO(P_COD_FILIAL) = 'S') THEN
        RETURN 'S';
      ELSE
        RETURN 'N';
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, ('Erro original: ' || SQLERRM));
    END;  
  END;
  
  FUNCTION OBTER_VIGENCIA_NT_SEFAZ(P_TIPO_DOCUMENTO IN VARCHAR2, P_IDENTIFICADORNT IN VARCHAR2, 
    P_AMBIENTE IN VARCHAR2, P_UF_DOCUMENTO IN VARCHAR2, P_DATA_INICIO_VIGENCIA OUT DATE, P_DATA_FIM_VIGENCIA OUT DATE) RETURN VARCHAR2 IS
    vDATAINICIALVIGENCIA VARCHAR2(50);
    vDATAFINALVIGENCIA   VARCHAR2(50);
    vRESULTADO           VARCHAR2(1);
  BEGIN
    BEGIN
      SELECT to_char(datainicialvigencia, 'dd/MM/yyyy') as datainicialvigencia,
             to_char(datafinalvigencia, 'dd/MM/yyyy') as datafinalvigencia
        INTO vDATAINICIALVIGENCIA,
             vDATAFINALVIGENCIA
        FROM pcvigenciantsefaz
       WHERE codvigencia IN (
      SELECT REG.CODVIGENCIA
        FROM (SELECT 1 COD
                   , CODVIGENCIA
                FROM PCVIGENCIANTSEFAZ
               WHERE IDENTIFICADOR_NT = P_IDENTIFICADORNT
                 AND TIPODOCUMENTO = P_TIPO_DOCUMENTO
                 AND NVL(UF, 'BR') = P_UF_DOCUMENTO
                 AND (NVL(AMBIENTE, 'A') = P_AMBIENTE OR NVL(AMBIENTE, 'A') = 'A')
              UNION
              SELECT 2 COD
                   , CODVIGENCIA
                FROM PCVIGENCIANTSEFAZ
               WHERE IDENTIFICADOR_NT = P_IDENTIFICADORNT
                 AND TIPODOCUMENTO = P_TIPO_DOCUMENTO
                 AND NVL(UF, 'BR') = 'BR'
                 AND (NVL(AMBIENTE, 'A') = P_AMBIENTE OR NVL(AMBIENTE, 'A') = 'A')
            ORDER BY COD) REG
       WHERE ROWNUM = 1);

       P_DATA_INICIO_VIGENCIA := TO_DATE(vDATAINICIALVIGENCIA, 'DD/MM/YYYY');
       P_DATA_FIM_VIGENCIA := TO_DATE(vDATAFINALVIGENCIA, 'DD/MM/YYYY');
       vRESULTADO := 'S';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vRESULTADO := 'N';
    END;
    RETURN vRESULTADO;
  END;
  
  FUNCTION NOTA_TECNICA_EM_VIGENCIA(P_TIPO_DOCUMENTO IN VARCHAR2, P_IDENTIFICADORNT IN VARCHAR2, 
    P_AMBIENTE IN VARCHAR2, P_UF_DOCUMENTO IN VARCHAR2, P_DATA_INICIO_VIGENCIA OUT DATE, 
    P_DATA_FIM_VIGENCIA OUT DATE) RETURN VARCHAR2 IS
    vDATAINICIALVIGENCIA DATE;
    vDATAFINALVIGENCIA   DATE;
    vRESULTADO           VARCHAR2(1);
  BEGIN
    BEGIN
       IF (OBTER_VIGENCIA_NT_SEFAZ(P_TIPO_DOCUMENTO, P_IDENTIFICADORNT, 
           P_AMBIENTE, P_UF_DOCUMENTO, vDATAINICIALVIGENCIA, vDATAFINALVIGENCIA) = 'S') THEN
         IF ((vDATAINICIALVIGENCIA <= TRUNC(SYSDATE)) AND (vDATAFINALVIGENCIA IS NULL OR vDATAFINALVIGENCIA >= TRUNC(SYSDATE))) THEN
           P_DATA_INICIO_VIGENCIA := vDATAINICIALVIGENCIA;
           P_DATA_FIM_VIGENCIA := vDATAFINALVIGENCIA;
           vRESULTADO := 'S';
         ELSE
           vRESULTADO := 'N';
         END IF;
       ELSE
         vRESULTADO := 'N';
       END IF;  
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vRESULTADO := 'N';
    END;
    RETURN vRESULTADO;
  END;
  
  FUNCTION DOCUMENTO_EM_VIGENCIA_DE_NT(P_TIPO_DOCUMENTO IN VARCHAR2, P_IDENTIFICADORNT IN VARCHAR2, 
    P_AMBIENTE IN VARCHAR2, P_UF_DOCUMENTO IN VARCHAR2, P_DATADOCUMENTO IN DATE) RETURN VARCHAR2 IS
    vDATAINICIALVIGENCIA DATE;
    vDATAFINALVIGENCIA   DATE;
    vRESULTADO           VARCHAR2(1);
  BEGIN
    BEGIN
      IF (OBTER_VIGENCIA_NT_SEFAZ(P_TIPO_DOCUMENTO, P_IDENTIFICADORNT, 
           P_AMBIENTE, P_UF_DOCUMENTO, vDATAINICIALVIGENCIA, vDATAFINALVIGENCIA) = 'S') THEN
        IF ((vDATAINICIALVIGENCIA <= P_DATADOCUMENTO) AND (vDATAFINALVIGENCIA IS NULL OR vDATAFINALVIGENCIA >= P_DATADOCUMENTO)) THEN
          vRESULTADO := 'S';
        ELSE
          vRESULTADO := 'N';
        END IF;
      ELSE
        vRESULTADO := 'N';
      END IF;     
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vRESULTADO := 'N';
    END;
    RETURN vRESULTADO;
  END;
  
  FUNCTION NFE_EM_VIGENCIA_DE_NT(P_IDENTIFICADORNT IN VARCHAR2,
                                 P_AMBIENTE        IN VARCHAR2,
                                 P_UF_DOCUMENTO    IN VARCHAR2,
                                 P_DATADOCUMENTO   IN DATE) RETURN VARCHAR2 IS
  BEGIN
    RETURN DOCUMENTO_EM_VIGENCIA_DE_NT('NFE', P_IDENTIFICADORNT,P_AMBIENTE,P_UF_DOCUMENTO, P_DATADOCUMENTO);
  END;
  
  FUNCTION CTE_EM_VIGENCIA_DE_NT(P_IDENTIFICADORNT IN VARCHAR2,
                                 P_AMBIENTE        IN VARCHAR2,
                                 P_UF_DOCUMENTO    IN VARCHAR2,
                                 P_DATADOCUMENTO   IN DATE) RETURN VARCHAR2 IS
  BEGIN
    RETURN DOCUMENTO_EM_VIGENCIA_DE_NT('CTE', P_IDENTIFICADORNT,P_AMBIENTE,P_UF_DOCUMENTO, P_DATADOCUMENTO);
  END;
  
  FUNCTION MDFE_EM_VIGENCIA_DE_NT(P_IDENTIFICADORNT IN VARCHAR2,
                                 P_AMBIENTE        IN VARCHAR2,
                                 P_UF_DOCUMENTO    IN VARCHAR2,
                                 P_DATADOCUMENTO   IN DATE) RETURN VARCHAR2 IS
  BEGIN
    RETURN DOCUMENTO_EM_VIGENCIA_DE_NT('MDFE', P_IDENTIFICADORNT,P_AMBIENTE,P_UF_DOCUMENTO, P_DATADOCUMENTO);
  END;
  
  FUNCTION CCE_EM_VIGENCIA_DE_NT(P_IDENTIFICADORNT IN VARCHAR2,
                                 P_AMBIENTE        IN VARCHAR2,
                                 P_UF_DOCUMENTO    IN VARCHAR2,
                                 P_DATADOCUMENTO   IN DATE) RETURN VARCHAR2 IS
  BEGIN
    RETURN DOCUMENTO_EM_VIGENCIA_DE_NT('CCE', P_IDENTIFICADORNT,P_AMBIENTE,P_UF_DOCUMENTO, P_DATADOCUMENTO);
  END;  

END FERRAMENTAS_DOCFISCAL;
