CREATE OR REPLACE PACKAGE BODY LOGISTICA IS
  /*--------------------------------------------------------------------------------------------------------------------
  AUTOR                SOLICITAÇÃO        DATA         DESCRIÇÃO
  Rodrigo Santos       2419.031297.2016   13/04/2016   Criação da nova package para operações logísticas(Mód-011).
  Rodrigo Santos       HIS.00934.2016     25/04/2016   Implementação da nova leitura do parâmetro 2888 da rotina 132.
  Hugo Aquino          3659.014966.2017   14/02/2017   Ajustada a totalização da nota de entrada, onde não estava fazendo
                                                       o arredondamento de duas casas decimais na totalização do valor
                                                       dos itens da nota.
  --------------------------------------------------------------------------------------------------------------------*/
  FUNCTION VALIDACAOPROCESSOPCNFENT(PNUMTRANS IN NUMBER) RETURN BOOLEAN IS
    vnValor number;
  BEGIN
    vnValor := 0;
    SELECT count(*)
      into vnValor
      FROM pcnfent
     WHERE (NUMTRANSENT = PNUMTRANS);
    RETURN(vnValor > 0);
  END;

  FUNCTION VALIDACAOPROCESSOPCNFSAID(PNUMTRANS IN NUMBER) RETURN BOOLEAN IS
    vnValor number;
  BEGIN
    vnValor := 0;
    SELECT count(*)
      into vnValor
      FROM PCNFSAID
     WHERE (NUMTRANSVENDA = PNUMTRANS);
    RETURN(vnValor > 0);
  END;

  PROCEDURE TOTALIZAR_NF(PTIPO      IN VARCHAR2,
                         PDATA      IN DATE,
                         PNUMTRANS  IN NUMBER,
                         PMATRICULA IN NUMBER) IS
    VT_PCNFSAID  PCNFSAID%ROWTYPE;
    VT_PCNFENT   PCNFENT%ROWTYPE;
    vnCONTAJUSTE NUMBER;
  
    FUNCTION F_SERIENF(PCODFILIAL IN VARCHAR2) RETURN VARCHAR2 IS
      vsSERIE PCDOCC.SERIE%TYPE;
    BEGIN
      SELECT SERIE
        INTO vsSERIE
        FROM PCDOCC
       WHERE TIPODOC = 'SR'
         AND CODDOC =
             (SELECT CODDOCSR FROM PCFILIAL WHERE CODIGO = PCODFILIAL)
         AND ROWNUM = 1;
      RETURN vsSERIE;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END;
  BEGIN
  
    vnCONTAJUSTE := FERRAMENTAS.F_BUSCARPARAMETRO_NUM('CON_CODCONTAJUSTEEST',
                                                      '99',
                                                      0);
  
    IF PTIPO = 'S' THEN
      --CONSOLIDANDO PCMOVs CONTÁBEIS DE SAÍDA NA PCNFSAID
      SELECT SUM(NVL(PCMOV.VLIPI, 0) * PCMOV.QTCONT) VLIPI,
             SUM(ROUND((NVL(PCMOV.PUNITCONT, 0) * NVL(PCMOV.QTCONT, 0)), 2)) VLTOTAL,
             SUM(ROUND((NVL(PCMOV.PUNIT, 0) * NVL(PCMOV.QT, 0)), 2)) VLTOTGER,
             SUM(DECODE(NVL(PCMOV.PERCIPI, 0),
                        0,
                        0,
                        NVL(PCMOV.VLBASEIPI, 0))) VLBASEIPI,
             SUM(NVL(PCMOV.ST, 0) * NVL(PCMOV.QTCONT, 0)) ICMSRETIDO,
             SUM(NVL((SELECT PCPRODUT.PESOBRUTO
                       FROM PCPRODUT
                      WHERE CODPROD = PCMOV.CODPROD),
                     0) * NVL(PCMOV.QTCONT, 0)) TOTPESO,
             PCMOV.CODFILIAL,
             PCMOV.NUMNOTA
        INTO VT_PCNFSAID.VLIPI,
             VT_PCNFSAID.VLTOTAL,
             VT_PCNFSAID.VLTOTGER,
             VT_PCNFSAID.VLBASEIPI,
             VT_PCNFSAID.ICMSRETIDO,
             VT_PCNFSAID.TOTPESO,
             VT_PCNFSAID.CODFILIAL,
             VT_PCNFSAID.NUMNOTA
        FROM PCMOV
       WHERE CODOPER = 'SI'
         AND STATUS = 'A'
         AND NUMTRANSVENDA = PNUMTRANS
       GROUP BY PCMOV.CODFILIAL, PCMOV.NUMNOTA;
    
      VT_PCNFSAID.ESPECIE       := 'TP';
      VT_PCNFSAID.NUMTRANSVENDA := PNUMTRANS;
      VT_PCNFSAID.DTSAIDA       := PDATA;
      VT_PCNFSAID.DTENTREGA     := PDATA;
      VT_PCNFSAID.SERIE         := F_SERIENF(VT_PCNFSAID.CODFILIAL);
    
      SELECT CODCLI
        INTO VT_PCNFSAID.CODCLI
        FROM PCFILIAL
       WHERE CODIGO = VT_PCNFSAID.CODFILIAL;
    
      SELECT CODPRACA
        INTO VT_PCNFSAID.CODPRACA
        FROM PCCLIENT
       WHERE CODCLI = VT_PCNFSAID.CODCLI;
    
      VT_PCNFSAID.CODCONT     := vnCONTAJUSTE;
      VT_PCNFSAID.CONDVENDA   := 1;
      VT_PCNFSAID.TIPOVENDA   := 'SR';
      VT_PCNFSAID.CAIXA       := 0;
      VT_PCNFSAID.CODUSUR     := 0;
      VT_PCNFSAID.NUMCAR      := 1;
      VT_PCNFSAID.CODPLPAG    := 1;
      VT_PCNFSAID.CODFISCAL   := 599;
      VT_PCNFSAID.TIPOEMISSAO := 1;
      VT_PCNFSAID.CODEMITENTE := PMATRICULA;
    
      IF FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CALCULARIPINFSAIDAINVENT',
                                            VT_PCNFSAID.CODFILIAL,
                                            'N') = 'N' THEN
        VT_PCNFSAID.VLIPI := 0;
      END IF;
    
      IF NOT VALIDACAOPROCESSOPCNFSAID(PNUMTRANS) THEN
        INSERT INTO PCNFSAID VALUES VT_PCNFSAID;
      END IF;
    
      FOR LIVRO IN (SELECT NVL(PCMOV.PERCICM, 0) PERCICM,
                           SUM(NVL(PCMOV.BASEICMS, 0) * NVL(PCMOV.QTCONT, 0)) VLBASE
                      FROM PCMOV
                     WHERE NUMTRANSVENDA = VT_PCNFSAID.NUMTRANSVENDA
                       AND CODOPER = 'SI'
                       AND STATUS = 'A'
                     GROUP BY NVL(PCMOV.PERCICM, 0)) LOOP
      
        INSERT INTO PCNFBASE
          (ALIQUOTA, VLBASE, VLICMS, CODCONT, NUMTRANSVENDA)
        VALUES
          (LIVRO.PERCICM,
           LIVRO.VLBASE,
           ROUND((LIVRO.VLBASE / 100) * LIVRO.PERCICM, 2),
           vnCONTAJUSTE,
           VT_PCNFSAID.NUMTRANSVENDA);
      
      END LOOP;
    
    ELSE
      --CONSOLIDANDO PCMOVs CONTÁBEIS DE ENTRADA NA PCNFENT
      SELECT PCMOV.NUMNOTA,
             PCMOV.CODFILIAL,
             SUM(ROUND((NVL(PCMOV.PUNITCONT, 0) * NVL(PCMOV.QTCONT, 0)), 2)) VLTOTAL
        INTO VT_PCNFENT.NUMNOTA, VT_PCNFENT.CODFILIAL, VT_PCNFENT.VLTOTAL
        FROM PCMOV
       WHERE CODOPER = 'EI'
         AND STATUS = 'A'
         AND NUMTRANSENT = PNUMTRANS
       GROUP BY PCMOV.NUMNOTA, PCMOV.CODFILIAL;
    
      VT_PCNFENT.NUMTRANSENT := PNUMTRANS;
      VT_PCNFENT.SERIE       := F_SERIENF(VT_PCNFENT.CODFILIAL);
    
      SELECT CODFORNEC
        INTO VT_PCNFENT.CODFORNEC
        FROM PCFILIAL
       WHERE CODIGO = VT_PCNFENT.CODFILIAL;
    
      VT_PCNFENT.ESPECIE         := 'TP';
      VT_PCNFENT.TIPOFRETECIFFOB := 'S';
      VT_PCNFENT.MODELO          := '55';
    
      VT_PCNFENT.CODCONT      := vnCONTAJUSTE;
      VT_PCNFENT.TIPODESCARGA := 4;
      VT_PCNFENT.DTEMISSAO    := PDATA;
      VT_PCNFENT.DTENT        := PDATA;
      VT_PCNFENT.VLIPI        := 0;
      VT_PCNFENT.VLFRETE      := 0;
      VT_PCNFENT.VLST         := 0;
      VT_PCNFENT.VLDESCONTO   := 0;
      VT_PCNFENT.VLOUTRAS     := 0;
      VT_PCNFENT.CODFISCAL    := 199;
      VT_PCNFENT.GERANFVENDA  := 'S';
      VT_PCNFENT.TIPOEMISSAO  := 1;
      VT_PCNFENT.CODFUNCLANC  := PMATRICULA;
    
      IF NOT VALIDACAOPROCESSOPCNFENT(PNUMTRANS) THEN
        BEGIN
          INSERT INTO PCNFENT VALUES VT_PCNFENT;
        
          INSERT INTO PCNFBASE
            (ALIQUOTA, VLBASE, VLICMS, CODCONT, NUMTRANSVENDA)
          VALUES
            (0, 0, 0, vnCONTAJUSTE, VT_PCNFENT.NUMTRANSENT);
        END;
      END IF;
    END IF;
  
  END TOTALIZAR_NF;

  PROCEDURE GERAR_NF_INVENTARIO(PNUMINVENT           IN NUMBER,
                                PCODFILIAL           IN VARCHAR2,
                                PCFOP_ENTR           IN NUMBER,
                                PCFOP_SAID           IN NUMBER,
                                PORLOTE              IN VARCHAR2 DEFAULT 'N',
                                PMATRICULA           IN NUMBER,
                                PRETORNO             OUT VARCHAR2,
                                PNUMTRANSVENDA       OUT NUMBER,
                                PNUMTRANSVENDA_LISTA OUT VARCHAR2,
                                PNUMTRANSENT         OUT NUMBER,
                                PNUMTRANSENT_LISTA   OUT VARCHAR2) IS
    vsRETORNO          VARCHAR2(5000);
    vnRETESTOQUE       NUMBER;
    VT_PCMOV           PCMOV%ROWTYPE;
    INVENT_GERENCIAL   SYS_REFCURSOR;
    vSQL_PCMOVGER      VARCHAR2(2000);
    vdDTPROCESSAMENTO  DATE;
    vdDTATUALIZACAO    DATE;
    vdDTATUALIZACAOMIN DATE;
    vnNUMTRANSVENDA    NUMBER;
    vnNUMTRANSENT      NUMBER;
    vnQTREG            NUMBER;
    vsRELCONT          VARCHAR2(1);
    vsTIPOCUSTOAJUST   VARCHAR2(1);
    vnQTDEITENSNF      NUMBER;
    vnQTDEMAXITENSNF   NUMBER;
    vnCustoErro        Boolean;
    vsValidarCusto     Varchar(5000);
    vsCALCULARIPINFSAIDAINVENT VARCHAR2(1);
    E_ENCONTRADO_CUSTO EXCEPTION;
  
    TYPE TR_NUMTRANS IS RECORD(
      NUMTRANSVENDA NUMBER,
      NUMTRANSENT   NUMBER);
    TYPE TB_NUMTRANS IS TABLE OF TR_NUMTRANS;
  
    vtNUMTRANS TB_NUMTRANS := TB_NUMTRANS();
  
    FUNCTION F_EXISTETRANSACAO(PNUMTRANS IN NUMBER, PTIPOTRANS IN VARCHAR2)
      RETURN BOOLEAN IS
      vnCOUNT NUMBER;
    BEGIN
      vnCOUNT := 0;
    
      SELECT COUNT(*)
        INTO vnCOUNT
        FROM PCMOV
       WHERE (NUMTRANSVENDA = PNUMTRANS AND PTIPOTRANS = 'S')
          OR (NUMTRANSENT = PNUMTRANS AND PTIPOTRANS = 'E');
    
      RETURN(vnCOUNT > 0);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
    END;
  
  BEGIN
    vnQTREG := 0;
    BEGIN
      SELECT MAX(TRUNC(PCMOV.DTMOV)), MIN(TRUNC(PCMOV.DTMOV))
        INTO vdDTATUALIZACAO, vdDTATUALIZACAOMIN
        FROM PCMOV, PCPRODUT
       WHERE PCMOV.NUMNOTA = PNUMINVENT
         AND PCMOV.CODFILIAL = PCODFILIAL
         AND PCMOV.CODPROD = PCPRODUT.CODPROD
         AND PCPRODUT.DTEXCLUSAO IS NULL
         AND PCMOV.STATUS = 'B'
         AND PCMOV.CODOPER IN ('EI', 'SI');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        vdDTATUALIZACAO    := NULL;
        vdDTATUALIZACAOMIN := NULL;
    END;
  
    IF vdDTATUALIZACAO IS NOT NULL THEN
    
      vsRETORNO := 'OK';
    
      vnQTDEITENSNF    := 0;
      vnQTDEMAXITENSNF := PARAMFILIAL.ObterComoNumber('FIL_NUMMAXITENSNFE',
                                                      PCODFILIAL);
      IF NVL(vnQTDEMAXITENSNF, 0) = 0 THEN
        vnQTDEMAXITENSNF := 150;
      END IF;
    
      vnNUMTRANSVENDA := 0;
      vnNUMTRANSENT   := 0;
    
      vdDTPROCESSAMENTO := TRUNC(SYSDATE);
    
      --HIS.00934.2016
      vsRELCONT := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('GERARRELATCONT',
                                                      PCODFILIAL,
                                                      'N');
    
      --HIS.01437.2016
      vsTIPOCUSTOAJUST := PARAMFILIAL.ObterComoVarchar2('TIPOCUSTOAJUSTECONTABIL');

      --DDESTOQUE-21766 
      vsCALCULARIPINFSAIDAINVENT := FERRAMENTAS.F_BUSCARPARAMETRO_ALFA('CALCULARIPINFSAIDAINVENT',
                                                                       PCODFILIAL,
                                                                       'N');
    
      --ABRINDO MOVIMENTAÇÕES GERENCIAIS REFERNTE AO INVENTÁRIO JÁ ATUALIZADO
      vSQL_PCMOVGER := 'SELECT M.*
         FROM PCMOV M
            , PCPRODUT P
            , PCEST E
        WHERE M.CODPROD = P.CODPROD
          AND M.CODPROD = E.CODPROD
          AND M.CODFILIAL = E.CODFILIAL
          AND M.DTCANCEL IS NULL
          AND M.CODFILIAL = ' || CHR(39) ||
                       PCODFILIAL || CHR(39) || '
          AND M.NUMNOTA = ' || PNUMINVENT || '
          AND M.CODOPER IN (''EI'',''SI'')
          AND M.STATUS = ''B''
          AND NVL(M.QT, 0) > 0
          AND P.DTEXCLUSAO IS NULL
          AND M.CODPROD NOT IN
              (SELECT PCMOV.CODPROD
                 FROM PCMOV, PCMOVCOMPLE
                WHERE PCMOV.NUMTRANSITEM = PCMOVCOMPLE.NUMTRANSITEM
                  AND UPPER(PCMOV.ROTINACAD) LIKE ''%1188%''
                  AND PCMOV.CODPROD = M.CODPROD
                  AND PCMOV.CODFILIAL = M.CODFILIAL
                  AND PCMOVCOMPLE.NUMINVENT = M.NUMNOTA
                  AND PCMOV.STATUS = ''A''
                  AND PCMOV.CODOPER IN (''EI'', ''SI'', ''EA'', ''SA'')
                  AND PCMOV.DTCANCEL IS NULL)
          AND TRUNC(M.DTMOV) <= TRUNC(TO_DATE(' ||
                       CHR(39) || TO_CHAR(vdDTATUALIZACAO) || CHR(39) ||
                       ',''DD/MM/RRRR HH24:MI:SS''))
          AND TRUNC(M.DTMOV) >= TRUNC(TO_DATE(' ||
                       CHR(39) || TO_CHAR(vdDTATUALIZACAOMIN) || CHR(39) ||
                       ',''DD/MM/RRRR HH24:MI:SS''))';
    
      CASE vsTIPOCUSTOAJUST /*Buscando apenas as movimentações em que o custo parametrizada seja maior que zero*/
        WHEN 'C' THEN
          vSQL_PCMOVGER := vSQL_PCMOVGER || chr(13) ||
                           'AND NVL(E.CUSTOCONT, 0) > 0';
        WHEN 'F' THEN
          vSQL_PCMOVGER := vSQL_PCMOVGER || chr(13) ||
                           'AND NVL(E.CUSTOFIN, 0) > 0';
        WHEN 'P' THEN
          vSQL_PCMOVGER := vSQL_PCMOVGER || chr(13) ||
                           'AND NVL(E.CUSTOREP, 0) > 0';
        WHEN 'R' THEN
          vSQL_PCMOVGER := vSQL_PCMOVGER || chr(13) ||
                           'AND NVL(E.CUSTOREAL, 0) > 0';
        WHEN 'U' THEN
          vSQL_PCMOVGER := vSQL_PCMOVGER || chr(13) ||
                           'AND NVL(E.CUSTOULTENT, 0) > 0';
        ELSE
          vSQL_PCMOVGER := vSQL_PCMOVGER || chr(13) ||
                           'AND NVL(E.CUSTOCONT, 0) > 0';
      END CASE;
    
      vSQL_PCMOVGER := vSQL_PCMOVGER || chr(13) ||
                       'ORDER BY M.CODOPER, M.CODPROD';
    
      OPEN INVENT_GERENCIAL FOR vSQL_PCMOVGER;
      LOOP
      
        FETCH INVENT_GERENCIAL
          INTO VT_PCMOV;
        EXIT WHEN INVENT_GERENCIAL%NOTFOUND;
      
        IF vnQTDEITENSNF >= vnQTDEMAXITENSNF THEN
          vnQTDEITENSNF := 0;
          IF SUBSTR(VT_PCMOV.CODOPER, 1, 1) = 'E' THEN
            vnNUMTRANSENT      := FERRAMENTAS.F_PROX_NUMTRANSENT;
            PNUMTRANSENT_LISTA := PNUMTRANSENT_LISTA || ',' ||
                                  vnNUMTRANSENT;
          END IF;
          IF SUBSTR(VT_PCMOV.CODOPER, 1, 1) = 'S' THEN
            vnNUMTRANSVENDA      := FERRAMENTAS.F_PROX_NUMTRANSVENDA;
            PNUMTRANSVENDA_LISTA := PNUMTRANSVENDA_LISTA || ',' ||
                                    vnNUMTRANSVENDA;
          END IF;
          vtNUMTRANS.EXTEND;
          vtNUMTRANS(vtNUMTRANS.LAST).NUMTRANSVENDA := vnNUMTRANSVENDA;
          vtNUMTRANS(vtNUMTRANS.LAST).NUMTRANSENT := vnNUMTRANSENT;
        
        ELSIF (vnNUMTRANSVENDA = 0 AND vnNUMTRANSENT = 0) THEN
          vnNUMTRANSVENDA      := FERRAMENTAS.F_PROX_NUMTRANSVENDA;
          vnNUMTRANSENT        := FERRAMENTAS.F_PROX_NUMTRANSENT;
          PNUMTRANSENT_LISTA   := vnNUMTRANSENT;
          PNUMTRANSVENDA_LISTA := vnNUMTRANSVENDA;
          vtNUMTRANS.EXTEND;
          vtNUMTRANS(vtNUMTRANS.LAST).NUMTRANSVENDA := vnNUMTRANSVENDA;
          vtNUMTRANS(vtNUMTRANS.LAST).NUMTRANSENT := vnNUMTRANSENT;
        END IF;
      
        vnQTDEITENSNF := nvl(vnQTDEITENSNF, 0) + 1;
      
        VT_PCMOV.DTMOV               := vdDTPROCESSAMENTO;
        VT_PCMOV.STATUS              := 'A';
        VT_PCMOV.MOVESTOQUEGERENCIAL := 'N';
        VT_PCMOV.MOVESTOQUECONTABIL  := 'S';
        VT_PCMOV.QTCONT              := VT_PCMOV.QT;
        VT_PCMOV.QT                  := 0;
        VT_PCMOV.ROTINACAD           := NULL;
        VT_PCMOV.DATAESTOQUE         := NULL;
      
        SELECT DFSEQ_PCMOVCOMPLE.NEXTVAL
          INTO VT_PCMOV.NUMTRANSITEM
          FROM DUAL;
      
        IF SUBSTR(VT_PCMOV.CODOPER, 1, 1) = 'S' THEN
          VT_PCMOV.NUMTRANSVENDA := vnNUMTRANSVENDA;
          VT_PCMOV.CODFISCAL     := PCFOP_SAID;
        ELSE
          VT_PCMOV.NUMTRANSENT := vnNUMTRANSENT;
          VT_PCMOV.CODFISCAL   := PCFOP_ENTR;
        END IF;
      
        SELECT CUSTOFIN, CUSTOREAL, CUSTOCONT, CUSTOREP, CUSTOULTENT
          INTO VT_PCMOV.CUSTOFIN,
               VT_PCMOV.CUSTOREAL,
               VT_PCMOV.CUSTOCONT,
               VT_PCMOV.CUSTOREP,
               VT_PCMOV.CUSTOULTENT
          FROM PCEST
         WHERE CODPROD = VT_PCMOV.CODPROD
           AND CODFILIAL = PCODFILIAL;
      
        VT_PCMOV.CUSTOFINANT  := VT_PCMOV.CUSTOFIN;
        VT_PCMOV.CUSTOREALANT := VT_PCMOV.CUSTOREAL;
        VT_PCMOV.CUSTOCONTANT := VT_PCMOV.CUSTOCONT;
      
        CASE vsTIPOCUSTOAJUST
          WHEN 'C' THEN
            VT_PCMOV.PUNITCONT := VT_PCMOV.CUSTOCONT;
          WHEN 'F' THEN
            VT_PCMOV.PUNITCONT := VT_PCMOV.CUSTOFIN;
          WHEN 'P' THEN
            VT_PCMOV.PUNITCONT := VT_PCMOV.CUSTOREP;
          WHEN 'R' THEN
            VT_PCMOV.PUNITCONT := VT_PCMOV.CUSTOREAL;
          WHEN 'U' THEN
            VT_PCMOV.PUNITCONT := VT_PCMOV.CUSTOULTENT;
          ELSE
            VT_PCMOV.PUNITCONT := VT_PCMOV.CUSTOCONT;
        END CASE;
      
        IF VT_PCMOV.PUNITCONT = 0 THEN
          vnCustoErro := true;
        
          if vsValidarCusto is NULL then
            vsValidarCusto := VT_PCMOV.CODPROD;
          else
            vsValidarCusto := vsValidarCusto || ',' || VT_PCMOV.CODPROD;
          
          End if;
        
        END IF;
      
        VT_PCMOV.PUNIT := 0;
      
        CASE vsRELCONT
          WHEN 'A' THEN
            IF SUBSTR(VT_PCMOV.CODOPER, 1, 1) = 'E' THEN
              VT_PCMOV.CODOPER := 'EA';
            ELSE
              VT_PCMOV.CODOPER := 'SA';
            END IF;
          WHEN 'E' THEN
            IF SUBSTR(VT_PCMOV.CODOPER, 1, 1) = 'E' THEN
              VT_PCMOV.CODOPER := 'EA';
            END IF;
          WHEN 'S' THEN
            IF SUBSTR(VT_PCMOV.CODOPER, 1, 1) = 'S' THEN
              VT_PCMOV.CODOPER := 'SA';
            END IF;
          ELSE
            NULL;
        END CASE;
      
        CASE VT_PCMOV.CODOPER
          WHEN 'SI' THEN
            IF NVL(VT_PCMOV.CODCLI, 0) = 0 THEN
              SELECT CODCLI
                INTO VT_PCMOV.CODCLI
                FROM PCFILIAL
               WHERE PCFILIAL.CODIGO = VT_PCMOV.CODFILIAL;
            
            END IF;
          WHEN 'EI' THEN
            IF NVL(VT_PCMOV.CODFORNEC, 0) = 0 THEN
              SELECT CODFORNEC
                INTO VT_PCMOV.CODFORNEC
                FROM PCFILIAL
               WHERE PCFILIAL.CODIGO = VT_PCMOV.CODFILIAL;
            END IF;
          ELSE
            NULL;
        END CASE;
      
        VT_PCMOV.CODFUNCLANC := PMATRICULA;
      
        IF vsCALCULARIPINFSAIDAINVENT = 'N' THEN
        
          VT_PCMOV.VLIPI     := 0;
          VT_PCMOV.PERCIPI   := 0;
          VT_PCMOV.VLBASEIPI := 0;
        END IF;
      
        IF SUBSTR(VT_PCMOV.CODOPER, 1, 1) = 'E' THEN
          IF VT_PCMOV.NUMTRANSENT = 0 THEN
            RAISE_APPLICATION_ERROR(-20000,
                                    'Erro ao gerar movimentação! Foi gerado movimentação com transação 0');
          END IF;
        ELSE
          IF VT_PCMOV.NUMTRANSVENDA = 0 THEN
            RAISE_APPLICATION_ERROR(-20000,
                                    'Erro ao gerar movimentação! Foi gerado movimentação com transação 0');
          END IF;
        END IF;
      
        INSERT INTO PCMOV VALUES VT_PCMOV;
      
        INSERT INTO PCMOVCOMPLE
          (NUMTRANSITEM, DTREGISTRO, NUMINVENT)
        VALUES
          (VT_PCMOV.NUMTRANSITEM, TRUNC(SYSDATE), PNUMINVENT);
      
        vnQTREG := vnQTREG + 1;
      
      END LOOP;
    
      FOR X IN 1 .. vtNUMTRANS.LAST LOOP
      
        IF F_EXISTETRANSACAO(vtNUMTRANS(X).NUMTRANSENT, 'E') AND
           (vsRETORNO = 'OK') THEN
          IF vsRELCONT IN ('N', 'S') THEN
            --HIS.00934.2016
            TOTALIZAR_NF('E',
                         vdDTPROCESSAMENTO,
                         vtNUMTRANS(X).NUMTRANSENT,
                         PMATRICULA);
          END IF;
          --vnRETESTOQUE := PKG_ESTOQUE.COMPRAS_ENTRADA(vnNUMTRANSENT,'N',vsRETORNO);
          PNUMTRANSENT := vtNUMTRANS(X).NUMTRANSENT;
        ELSE
          PNUMTRANSENT := vtNUMTRANS(X).NUMTRANSENT;
        END IF;
      
        IF F_EXISTETRANSACAO(vtNUMTRANS(X).NUMTRANSVENDA, 'S') AND
           (vsRETORNO = 'OK') THEN
          IF vsRELCONT IN ('N', 'E') THEN
            --HIS.00934.2016
            TOTALIZAR_NF('S',
                         vdDTPROCESSAMENTO,
                         vtNUMTRANS(X).NUMTRANSVENDA,
                         PMATRICULA);
          END IF;
          --vnRETESTOQUE := PKG_ESTOQUE.VENDAS_SAIDA(vnNUMTRANSVENDA,'N',vsRETORNO);
          PNUMTRANSVENDA := vtNUMTRANS(X).NUMTRANSVENDA;
        ELSE
          PNUMTRANSVENDA := vtNUMTRANS(X).NUMTRANSVENDA;
        END IF;
      
        IF vnRETESTOQUE = 0 THEN
          PRETORNO := vsRETORNO;
        END IF;
      
      END LOOP;
    
    ELSE
    
      vsRETORNO := 'O inventário informado não existe ou ainda não foi atualizado.';
    
    END IF;
  
    IF (vnCustoErro) and (vsValidarCusto IS NOT NULL) THEN
      RAISE E_ENCONTRADO_CUSTO;
    END IF;
  
    IF UPPER(vsRETORNO) <> 'OK' THEN
      ROLLBACK;
      PRETORNO := vsRETORNO;
    ELSE
      --COMMIT; --É necessário para que sejam aplicadas as tributações pela classe do compras
      PRETORNO := 'OK';
    END IF;
  
  EXCEPTION
    WHEN E_ENCONTRADO_CUSTO THEN
      ROLLBACK;
      PRETORNO := 'Os produtos' || ' ' || vsValidarCusto || ' ' ||
                  'estão com custos zerados! Verifique a rotina 1103.';
    
    WHEN OTHERS THEN
      ROLLBACK;
      PRETORNO := SQLERRM;
    
  END GERAR_NF_INVENTARIO;

  /*--------------------------------------------------------------------------------------------------------------------
  AUTOR                SOLICITAÇÃO        DATA         DESCRIÇÃO
  Rodrigo Santos       2925.069894.2016   23/07/2016   Criação do método para implementação dos custos para rotinas logisticas.
  Rodrigo Santos       2397.076328.2016   03/08/2016   Função ajustada para prever o status da PCMOV, decindo qual QT usar no cálculo.
  --------------------------------------------------------------------------------------------------------------------*/
  FUNCTION GERAR_CUSTOS_PCMOV(PROWID_PCMOV     VARCHAR2,
                              PATUALIZAR_PCEST VARCHAR2 DEFAULT 'S')
    RETURN VARCHAR2 IS
    TYPE TR_PARAMS IS RECORD(
      CON_PERCACRESCIMOCUSTOFIN    NUMBER,
      CON_PERCACRESCIMOCUSTOREAL   NUMBER,
      USADEPTERCEIRO               VARCHAR2(1),
      FIL_ATUALIZACUSTOULTENTRANSF VARCHAR2(1),
      FIL_INDICECUSTOTRANSF        NUMBER);
  
    TYPE TR_CUSTOS_PCEST IS RECORD(
      QTESTGER           NUMBER,
      QTEST              NUMBER,
      VALORULTIMAENTRADA NUMBER,
      CUSTOULTIMAENTRADA NUMBER,
      CUSTOFINANCEIRO    NUMBER,
      CUSTOREAL          NUMBER,
      CUSTOREALSEMST     NUMBER,
      CUSTOCONTABIL      NUMBER,
      CUSTOREPOSICAO     NUMBER);
  
    vtPARAMS        TR_PARAMS;
    vtPCMOV         PCMOV%ROWTYPE;
    vtPCEST_ORIGEM  TR_CUSTOS_PCEST;
    vtPCEST_DESTINO TR_CUSTOS_PCEST;
    vnQTDEMOV       NUMBER;
    vnCUSTO         NUMBER;
    vMSG_RETURN     VARCHAR2(1000);
    E_NO_DATA_FOUND               EXCEPTION;
    E_NAO_EH_ENTRADA              EXCEPTION;
    E_FILIALORIGEM_NAO_ENCONTRADA EXCEPTION;
  
    FUNCTION MEDIA_PONDERADA(QTANTERIOR NUMBER,
                             QTENTRADA  NUMBER,
                             VLANTERIOR NUMBER,
                             VLENTRADA  NUMBER) RETURN NUMBER IS
      vnRETORNO NUMBER;
    BEGIN
    
      vnRETORNO := ((GREATEST(QTANTERIOR, 0) * VLANTERIOR) +
                   (QTENTRADA * VLENTRADA)) /
                   (GREATEST(QTANTERIOR, 0) + QTENTRADA);
    
      IF vnRETORNO > 0 THEN
        RETURN ROUND(vnRETORNO, 6);
      ELSE
        RETURN ROUND(VLENTRADA, 6);
      END IF;
    
    END MEDIA_PONDERADA;
  
  BEGIN
  
    --Buscar registro na PCMOV pelo ROWID
    BEGIN
      SELECT * INTO vtPCMOV FROM PCMOV WHERE ROWID = PROWID_PCMOV;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE E_NO_DATA_FOUND;
    END;
  
    IF vtPCMOV.CODOPER <> 'ET' THEN
      RAISE E_NAO_EH_ENTRADA;
    ELSE
      vMSG_RETURN := 'OK';
    END IF;
  
    --Buscando parâmetros
    vtPARAMS.CON_PERCACRESCIMOCUSTOFIN    := PARAMFILIAL.OBTERCOMONUMBER('CON_PERCACRESCIMOCUSTOFIN');
    vtPARAMS.CON_PERCACRESCIMOCUSTOREAL   := PARAMFILIAL.OBTERCOMONUMBER('CON_PERCACRESCIMOCUSTOREAL');
    vtPARAMS.USADEPTERCEIRO               := NVL(PARAMFILIAL.OBTERCOMOVARCHAR2('USADEPTERCEIRO',
                                                                               vtPCMOV.CODFILIAL),
                                                 'N');
    vtPARAMS.FIL_ATUALIZACUSTOULTENTRANSF := PARAMFILIAL.OBTERCOMOVARCHAR2('FIL_ATUALIZACUSTOULTENTRANSF',
                                                                           vtPCMOV.CODFILIAL);
    vtPARAMS.FIL_INDICECUSTOTRANSF        := NVL(PARAMFILIAL.OBTERCOMONUMBER('FIL_INDICECUSTOTRANSF',
                                                                             vtPCMOV.CODFILIAL),
                                                 0);
    IF vtPARAMS.FIL_INDICECUSTOTRANSF = 0 THEN
      vtPARAMS.FIL_INDICECUSTOTRANSF := 1;
    END IF;
  
    SELECT NVL(QTESTGER, 0),
           NVL(QTEST, 0),
           NVL(VALORULTENT, 0),
           NVL(CUSTOULTENT, 0),
           NVL(CUSTOFIN, 0),
           NVL(CUSTOREAL, 0),
           NVL(CUSTOREALSEMST, 0),
           NVL(CUSTOCONT, 0),
           NVL(CUSTOREP, 0)
      INTO vtPCEST_DESTINO.QTESTGER,
           vtPCEST_DESTINO.QTEST,
           vtPCEST_DESTINO.VALORULTIMAENTRADA,
           vtPCEST_DESTINO.CUSTOULTIMAENTRADA,
           vtPCEST_DESTINO.CUSTOFINANCEIRO,
           vtPCEST_DESTINO.CUSTOREAL,
           vtPCEST_DESTINO.CUSTOREALSEMST,
           vtPCEST_DESTINO.CUSTOCONTABIL,
           vtPCEST_DESTINO.CUSTOREPOSICAO
      FROM PCEST
     WHERE CODFILIAL = vtPCMOV.CODFILIAL
       AND CODPROD = vtPCMOV.CODPROD;
  
    --Armazenando dados anteriores
    vtPCMOV.VALORULTENTANT    := vtPCEST_DESTINO.VALORULTIMAENTRADA;
    vtPCMOV.CUSTOULTENTANT    := vtPCEST_DESTINO.CUSTOULTIMAENTRADA;
    vtPCMOV.CUSTOFINANT       := vtPCEST_DESTINO.CUSTOFINANCEIRO;
    vtPCMOV.CUSTOREALANT      := vtPCEST_DESTINO.CUSTOREAL;
    vtPCMOV.CUSTOREALSEMSTANT := vtPCEST_DESTINO.CUSTOREALSEMST;
    vtPCMOV.CUSTOCONTANT      := vtPCEST_DESTINO.CUSTOCONTABIL;
    vtPCMOV.CUSTOREPANT       := vtPCEST_DESTINO.CUSTOREPOSICAO;
  
    vtPCMOV.QTSALDOESTGER := nvl(vtPCEST_DESTINO.QTESTGER, 0) +
                             NVL(vtPCMOV.QT, 0);
    vtPCMOV.QTSALDOEST    := nvl(vtPCEST_DESTINO.QTEST, 0) +
                             NVL(vtPCMOV.QTCONT, 0);
  
    --Limpando novos custos
    vtPCMOV.VALORULTENT    := 0;
    vtPCMOV.CUSTOULTENT    := 0;
    vtPCMOV.CUSTOFIN       := 0;
    vtPCMOV.CUSTOREAL      := 0;
    vtPCMOV.CUSTOREALSEMST := 0;
    vtPCMOV.CUSTOCONT      := 0;
    vtPCMOV.CUSTOREP       := 0;
  
    --Calculando novos custos
    IF vtPARAMS.USADEPTERCEIRO = 'S' THEN
    
      BEGIN
        SELECT NVL(QTESTGER, 0),
               NVL(QTEST, 0),
               NVL(VALORULTENT, 0),
               NVL(CUSTOULTENT, 0),
               NVL(CUSTOFIN, 0),
               NVL(CUSTOREAL, 0),
               NVL(CUSTOREALSEMST, 0),
               NVL(CUSTOCONT, 0),
               NVL(CUSTOREP, 0)
          INTO vtPCEST_ORIGEM.QTESTGER,
               vtPCEST_ORIGEM.QTEST,
               vtPCEST_ORIGEM.VALORULTIMAENTRADA,
               vtPCEST_ORIGEM.CUSTOULTIMAENTRADA,
               vtPCEST_ORIGEM.CUSTOFINANCEIRO,
               vtPCEST_ORIGEM.CUSTOREAL,
               vtPCEST_ORIGEM.CUSTOREALSEMST,
               vtPCEST_ORIGEM.CUSTOCONTABIL,
               vtPCEST_ORIGEM.CUSTOREPOSICAO
          FROM PCEST
         WHERE CODFILIAL =
               (SELECT CODFILIAL
                  FROM PCNFSAID
                 WHERE NUMTRANSENTORIGEM = vtPCMOV.NUMTRANSENT)
           AND CODPROD = vtPCMOV.CODPROD;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE E_FILIALORIGEM_NAO_ENCONTRADA;
        WHEN OTHERS THEN
          vMSG_RETURN := SQLERRM;
      END;
    
      --Custos contábeis
      IF vtPCMOV.STATUS IN ('A', 'AB') THEN
        vtPCMOV.VALORULTENT := vtPCEST_ORIGEM.VALORULTIMAENTRADA;
        vtPCMOV.CUSTOCONT   := vtPCEST_ORIGEM.CUSTOCONTABIL;
        vtPCMOV.CUSTOREP    := vtPCEST_ORIGEM.CUSTOREPOSICAO;
      END IF;
      --Custos gerenciais
      IF vtPCMOV.STATUS IN ('B', 'AB') THEN
        vtPCMOV.CUSTOULTENT    := vtPCEST_ORIGEM.CUSTOULTIMAENTRADA;
        vtPCMOV.CUSTOFIN       := vtPCEST_ORIGEM.CUSTOFINANCEIRO;
        vtPCMOV.CUSTOREAL      := vtPCEST_ORIGEM.CUSTOREAL;
        vtPCMOV.CUSTOREALSEMST := vtPCEST_ORIGEM.CUSTOREALSEMST;
      END IF;
    
    ELSE
      CASE SUBSTR(vtPCMOV.STATUS, 1, 1)
        WHEN 'A' THEN
          vnCUSTO   := NVL(vtPCMOV.PUNITCONT, 0);
          vnQTDEMOV := NVL(vtPCMOV.QTCONT, 0);
        ELSE
          vnCUSTO   := NVL(vtPCMOV.PUNIT, 0);
          vnQTDEMOV := NVL(vtPCMOV.QT, 0);
      END CASE;
      --Custo contábil
      IF vtPCMOV.STATUS IN ('A', 'AB') THEN
        IF vtPARAMS.FIL_ATUALIZACUSTOULTENTRANSF = 'S' THEN
          vtPCMOV.VALORULTENT := MEDIA_PONDERADA(vtPCMOV.QTESTGERANT,
                                                 vnQTDEMOV,
                                                 vtPCEST_DESTINO.VALORULTIMAENTRADA,
                                                 vnCUSTO);
        END IF;
        vtPCMOV.CUSTOCONT := MEDIA_PONDERADA(vtPCMOV.QTESTGERANT,
                                             vnQTDEMOV,
                                             vtPCEST_DESTINO.CUSTOCONTABIL,
                                             vnCUSTO);
        vtPCMOV.CUSTOREP  := MEDIA_PONDERADA(vtPCMOV.QTESTGERANT,
                                             vnQTDEMOV,
                                             vtPCEST_DESTINO.CUSTOREPOSICAO,
                                             vnCUSTO);
      END IF;
    
      --Custo Gerencial
      IF vtPCMOV.STATUS IN ('B', 'AB') THEN
        IF vtPARAMS.FIL_ATUALIZACUSTOULTENTRANSF = 'S' THEN
          vtPCMOV.CUSTOULTENT := MEDIA_PONDERADA(vtPCMOV.QTESTGERANT,
                                                 vnQTDEMOV,
                                                 vtPCEST_DESTINO.CUSTOULTIMAENTRADA,
                                                 vnCUSTO);
        END IF;
        vtPCMOV.CUSTOFIN       := MEDIA_PONDERADA(vtPCMOV.QTESTGERANT,
                                                  vnQTDEMOV,
                                                  vtPCEST_DESTINO.CUSTOFINANCEIRO,
                                                  vnCUSTO) * (1 +
                                                              (vtPARAMS.CON_PERCACRESCIMOCUSTOFIN / 100));
        vtPCMOV.CUSTOREAL      := MEDIA_PONDERADA(vtPCMOV.QTESTGERANT,
                                                  vnQTDEMOV,
                                                  vtPCEST_DESTINO.CUSTOREAL,
                                                  vnCUSTO) * (1 +
                                                              (vtPARAMS.CON_PERCACRESCIMOCUSTOREAL / 100));
        vtPCMOV.CUSTOREALSEMST := MEDIA_PONDERADA(vtPCMOV.QTESTGERANT,
                                                  vnQTDEMOV,
                                                  vtPCEST_DESTINO.CUSTOREALSEMST,
                                                  (vnCUSTO -
                                                  NVL(vtPCMOV.ST, 0))) * (1 +
                                                                          (vtPARAMS.CON_PERCACRESCIMOCUSTOREAL / 100));
      END IF;
    
    END IF;
  
    --Aplicar Índice custo
    vtPCMOV.VALORULTENT    := vtPCMOV.VALORULTENT *
                              vtPARAMS.FIL_INDICECUSTOTRANSF;
    vtPCMOV.CUSTOULTENT    := vtPCMOV.CUSTOULTENT *
                              vtPARAMS.FIL_INDICECUSTOTRANSF;
    vtPCMOV.CUSTOFIN       := vtPCMOV.CUSTOFIN *
                              vtPARAMS.FIL_INDICECUSTOTRANSF;
    vtPCMOV.CUSTOREAL      := vtPCMOV.CUSTOREAL *
                              vtPARAMS.FIL_INDICECUSTOTRANSF;
    vtPCMOV.CUSTOREALSEMST := vtPCMOV.CUSTOREALSEMST *
                              vtPARAMS.FIL_INDICECUSTOTRANSF;
    vtPCMOV.CUSTOCONT      := vtPCMOV.CUSTOCONT *
                              vtPARAMS.FIL_INDICECUSTOTRANSF;
    vtPCMOV.CUSTOREP       := vtPCMOV.CUSTOREP *
                              vtPARAMS.FIL_INDICECUSTOTRANSF;
  
    UPDATE PCMOV
       SET ----------------------------------------
             VALORULTENT = vtPCMOV.VALORULTENT,
           CUSTOULTENT    = vtPCMOV.CUSTOULTENT,
           CUSTOFIN       = vtPCMOV.CUSTOFIN,
           CUSTOREAL      = vtPCMOV.CUSTOREAL,
           CUSTOREALSEMST = vtPCMOV.CUSTOREALSEMST,
           CUSTOCONT      = vtPCMOV.CUSTOCONT,
           CUSTOREP       = vtPCMOV.CUSTOREP,
           ----------------------------------------
           VALORULTENTANT    = vtPCMOV.VALORULTENTANT,
           CUSTOULTENTANT    = vtPCMOV.CUSTOULTENTANT,
           CUSTOFINANT       = vtPCMOV.CUSTOFINANT,
           CUSTOREALANT      = vtPCMOV.CUSTOREALANT,
           CUSTOREALSEMSTANT = vtPCMOV.CUSTOREALSEMSTANT,
           CUSTOCONTANT      = vtPCMOV.CUSTOCONTANT,
           CUSTOREPANT       = vtPCMOV.CUSTOREPANT,
           ----------------------------------------
           QTSALDOESTGER = vtPCMOV.QTSALDOESTGER,
           QTSALDOEST    = vtPCMOV.QTSALDOEST
     WHERE ROWID = PROWID_PCMOV;
  
    IF PATUALIZAR_PCEST = 'S' THEN
    
      UPDATE PCEST
         SET ----------------------------------------
               VALORULTENT = DECODE(NVL(vtPCMOV.VALORULTENT, VALORULTENT),
                                    0,
                                    VALORULTENT,
                                    NVL(vtPCMOV.VALORULTENT, VALORULTENT)),
             CUSTOULTENT    = DECODE(NVL(vtPCMOV.CUSTOULTENT, CUSTOULTENT),
                                     0,
                                     CUSTOULTENT,
                                     NVL(vtPCMOV.CUSTOULTENT, CUSTOULTENT)),
             CUSTOFIN       = DECODE(NVL(vtPCMOV.CUSTOFIN, CUSTOFIN),
                                     0,
                                     CUSTOFIN,
                                     NVL(vtPCMOV.CUSTOFIN, CUSTOFIN)),
             CUSTOREAL      = DECODE(NVL(vtPCMOV.CUSTOREAL, CUSTOREAL),
                                     0,
                                     CUSTOREAL,
                                     NVL(vtPCMOV.CUSTOREAL, CUSTOREAL)),
             CUSTOREALSEMST = DECODE(NVL(vtPCMOV.CUSTOREALSEMST,
                                         CUSTOREALSEMST),
                                     0,
                                     CUSTOREALSEMST,
                                     NVL(vtPCMOV.CUSTOREALSEMST,
                                         CUSTOREALSEMST)),
             CUSTOCONT      = DECODE(NVL(vtPCMOV.CUSTOCONT, CUSTOCONT),
                                     0,
                                     CUSTOCONT,
                                     NVL(vtPCMOV.CUSTOCONT, CUSTOCONT)),
             CUSTOREP       = DECODE(NVL(vtPCMOV.CUSTOREP, CUSTOREP),
                                     0,
                                     CUSTOREP,
                                     NVL(vtPCMOV.CUSTOREP, CUSTOREP))
      ----------------------------------------
       WHERE CODFILIAL = vtPCMOV.CODFILIAL
         AND CODPROD = vtPCMOV.CODPROD;
    
    END IF;
  
    RETURN vMSG_RETURN;
  
  EXCEPTION
    WHEN E_NO_DATA_FOUND THEN
      RETURN 'Não foi possível encontrar o registro da PCMOV indicado.';
    WHEN E_NAO_EH_ENTRADA THEN
      RETURN 'O registro não se trata de uma entrada de transferência.';
    WHEN E_FILIALORIGEM_NAO_ENCONTRADA THEN
      RETURN 'Não foram localizados os dados de custo na filial de origem.';
    WHEN OTHERS THEN
      RETURN 'Erro LOGISTICA.GERAR_CUSTOS_PCMOV: ' || SQLERRM;
    
  END GERAR_CUSTOS_PCMOV;

  PROCEDURE INSERIR_COMPLEMENTODESCPROD(pnROTINA       IN PCPEDI.ROTINALANC%TYPE,
                                        pnNUMPED       IN PCPEDI.NUMPED%TYPE,
                                        pnCODPROD      IN PCPEDI.CODPROD%TYPE,
                                        pnNUMSEQANTIGO IN PCPEDI.NUMSEQ%TYPE,
                                        pnNUMSEQNOVO   IN PCPEDI.NUMSEQ%TYPE) IS
    -- Variáveis internas
  
    VT_COMPLEMENTODESCPRODORIGINAL PCCOMPLEMENTODESCPROD%ROWTYPE;
    VN_NUMSEQPRODNOVO              NUMBER;
  
  BEGIN
  
    VN_NUMSEQPRODNOVO := 1;
  
    FOR REGISTRO IN (SELECT NUMPED, CODPROD, NUMSEQPROD, NUMSEQ, ROWID
                       FROM PCCOMPLEMENTODESCPROD
                      WHERE NUMPED = pnNUMPED
                        AND NUMSEQ = pnNUMSEQANTIGO
                        AND CODPROD = pnCODPROD
                      ORDER BY NUMSEQ, NUMSEQPROD)
    
     LOOP
    
      SELECT *
        INTO VT_COMPLEMENTODESCPRODORIGINAL
        FROM PCCOMPLEMENTODESCPROD
       WHERE ROWID = REGISTRO.ROWID;
    
      VT_COMPLEMENTODESCPRODORIGINAL.NUMSEQ     := pnNUMSEQNOVO;
      VT_COMPLEMENTODESCPRODORIGINAL.NUMSEQPROD := VN_NUMSEQPRODNOVO;
    
      INSERT INTO PCCOMPLEMENTODESCPROD
      VALUES VT_COMPLEMENTODESCPRODORIGINAL;
    
      VN_NUMSEQPRODNOVO := VN_NUMSEQPRODNOVO + 1;
    
    END LOOP;
  
  END;

  PROCEDURE DELETAR_COMPLEMENTODESCPROD(pnROTINA       IN PCPEDI.ROTINALANC%TYPE,
                                        pnNUMPED       IN PCPEDI.NUMPED%TYPE,
                                        pnCODPROD      IN PCPEDI.CODPROD%TYPE,
                                        pnNUMSEQANTIGO IN PCPEDI.NUMSEQ%TYPE) IS -- Variáveis internas
  BEGIN
    -- Deletar registro antigo
    DELETE FROM PCCOMPLEMENTODESCPROD
     WHERE NUMPED = pnNUMPED
       AND CODPROD = pnCODPROD
       AND NUMSEQ = pnNUMSEQANTIGO;
    -- Procedure
  END DELETAR_COMPLEMENTODESCPROD;

END LOGISTICA;
