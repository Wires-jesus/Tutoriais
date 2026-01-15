DECLARE
  dVLDIFF NUMBER;
  dQTDPARCELAS INTEGER;

  dtVENC        PCPREST.DTVENC%TYPE;
  dVLPREST      PCPREST.VALOR%TYPE;
  dNUMPREST     PCPREST.PREST%TYPE;
  dVLTOTALPREST PCPREST.VALOR%TYPE;

  dVLTOTALPCNFSAID PCNFSAID.VLTOTAL%TYPE;

  tPCPLPAG PCPLPAG%ROWTYPE;
  tPCPREST PCPREST%ROWTYPE;
  tPCPARCELANFE PCPARCELANFE%ROWTYPE;
  tPCLOGFATURAMENTO PCLOGFATURAMENTO%ROWTYPE;
  
  PROCEDURE GRAVARLOG(P_LOGFATURAMENTO PCLOGFATURAMENTO%ROWTYPE)
    IS
  BEGIN
    INSERT INTO PCLOGFATURAMENTO (LOG
                                 ,TIPOLOG
                                 ,PROCESSO
                                 ,CODLOG
                                 ,CODFUNC
                                 ,CODFILIAL
                                 ,DATAHORA
                                 ,DTINICIAL
                                 ,DTFINAL
                                 ,OSUSER
                                 ,MAQUINA
                                 ,TERMINAL
                                 ,CODIGOIDENTIFICADOR)
                          VALUES (P_LOGFATURAMENTO.LOG
                                 ,P_LOGFATURAMENTO.TIPOLOG
                                 ,P_LOGFATURAMENTO.PROCESSO
                                 ,P_LOGFATURAMENTO.CODLOG
                                 ,P_LOGFATURAMENTO.CODFUNC
                                 ,P_LOGFATURAMENTO.CODFILIAL
                                 ,P_LOGFATURAMENTO.DATAHORA
                                 ,P_LOGFATURAMENTO.DTINICIAL
                                 ,P_LOGFATURAMENTO.DTFINAL
                                 ,P_LOGFATURAMENTO.OSUSER
                                 ,P_LOGFATURAMENTO.MAQUINA
                                 ,P_LOGFATURAMENTO.TERMINAL
                                 ,P_LOGFATURAMENTO.CODIGOIDENTIFICADOR);
    COMMIT WORK;
  END;
    
  FUNCTION FN_QTD_PARCELAS(P_CODPLPAG IN NUMBER)
        RETURN PLS_INTEGER
    IS
      V_QTD PLS_INTEGER;
  BEGIN
    SELECT
        (CASE WHEN NVL(PRAZO1,0)  > 0 THEN 1 ELSE 0 END +
         CASE WHEN NVL(PRAZO2,0)  > 0 THEN 1 ELSE 0 END +
         CASE WHEN NVL(PRAZO3,0)  > 0 THEN 1 ELSE 0 END +
         CASE WHEN NVL(PRAZO4,0)  > 0 THEN 1 ELSE 0 END +
         CASE WHEN NVL(PRAZO5,0)  > 0 THEN 1 ELSE 0 END +
         CASE WHEN NVL(PRAZO6,0)  > 0 THEN 1 ELSE 0 END +
         CASE WHEN NVL(PRAZO7,0)  > 0 THEN 1 ELSE 0 END +
         CASE WHEN NVL(PRAZO8,0)  > 0 THEN 1 ELSE 0 END +
         CASE WHEN NVL(PRAZO9,0)  > 0 THEN 1 ELSE 0 END +
         CASE WHEN NVL(PRAZO10,0) > 0 THEN 1 ELSE 0 END +
         CASE WHEN NVL(PRAZO11,0) > 0 THEN 1 ELSE 0 END +
         CASE WHEN NVL(PRAZO12,0) > 0 THEN 1 ELSE 0 END
        )
        +
        CASE WHEN NVL(NUMDIAS,0) > 0 AND
               (CASE WHEN NVL(PRAZO1,0)  > 0 THEN 1 ELSE 0 END +
                CASE WHEN NVL(PRAZO2,0)  > 0 THEN 1 ELSE 0 END +
                CASE WHEN NVL(PRAZO3,0)  > 0 THEN 1 ELSE 0 END +
                CASE WHEN NVL(PRAZO4,0)  > 0 THEN 1 ELSE 0 END +
                CASE WHEN NVL(PRAZO5,0)  > 0 THEN 1 ELSE 0 END +
                CASE WHEN NVL(PRAZO6,0)  > 0 THEN 1 ELSE 0 END +
                CASE WHEN NVL(PRAZO7,0)  > 0 THEN 1 ELSE 0 END +
                CASE WHEN NVL(PRAZO8,0)  > 0 THEN 1 ELSE 0 END +
                CASE WHEN NVL(PRAZO9,0)  > 0 THEN 1 ELSE 0 END +
                CASE WHEN NVL(PRAZO10,0) > 0 THEN 1 ELSE 0 END +
                CASE WHEN NVL(PRAZO11,0) > 0 THEN 1 ELSE 0 END +
                CASE WHEN NVL(PRAZO12,0) > 0 THEN 1 ELSE 0 END
               ) = 0
          THEN 1
          ELSE 0
        END
    INTO V_QTD
    FROM PCPLPAG
    WHERE CODPLPAG = P_CODPLPAG;
      
    IF V_QTD = 0 THEN
      V_QTD := 1;
    END IF;  

    RETURN V_QTD;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN 1;
  END;
BEGIN
  FOR DADOS IN (
    SELECT
       NFSAID.CODCLI
      ,NFSAID.NUMNOTA AS DUPLIC
      ,NFSAID.VLTOTAL AS VALOR
      ,NFSAID.VLTOTAL AS VPAGO
      ,NFSAID.DTSAIDA AS DTPAG
      ,NFSAID.DTSAIDA AS DTEMISSAO
      ,NFSAID.DTSAIDA AS DTVENC
      ,NFSAID.CODCOB
      ,NFSAID.CODFILIAL
      ,NFSAID.CODPLPAG
      ,NFSAID.CODUSUR
      ,NFSAID.NUMPED
      ,'A' AS STATUS
      ,NFSAID.DTSAIDA AS DTVENCORIG
      ,NFSAID.NUMTRANSVENDA
      ,NFSAID.NUMCAR
    FROM PCNFSAID NFSAID
    WHERE 1=1
      AND  NOT EXISTS (SELECT 1 FROM PCPREST PREST WHERE PREST.NUMTRANSVENDA = NFSAID.NUMTRANSVENDA)
      AND NFSAID.ESPECIE = 'NF'
      AND NFSAID.DTSAIDA >= '01-10-2025'
      AND NFSAID.SITUACAONFE = '100'
      AND NFSAID.CODCOB IS NOT NULL
      AND NFSAID.CODPLPAG IS NOT NULL
      AND NFSAID.CONDVENDA = 1) LOOP
    
    dVLTOTALPCNFSAID := DADOS.VALOR;
    
    tPCPREST.CODCLI        := DADOS.CODCLI;
    tPCPREST.CODCOB        := DADOS.CODCOB;
    tPCPREST.DUPLIC        := DADOS.DUPLIC;
    tPCPREST.STATUS        := DADOS.STATUS; 
    tPCPREST.NUMCAR        := DADOS.NUMCAR;
    tPCPREST.NUMPED        := DADOS.NUMPED;
    tPCPREST.CODUSUR       := DADOS.CODUSUR;
    tPCPREST.CODFILIAL     := DADOS.CODFILIAL;
    tPCPREST.DTEMISSAO     := DADOS.DTEMISSAO;
    tPCPREST.NUMTRANSVENDA := DADOS.NUMTRANSVENDA;
    
    tPCPARCELANFE.DUPLIC       := DADOS.DUPLIC;
    tPCPARCELANFE.TIPOMOV      := 'S';
    tPCPARCELANFE.NUMTRANSACAO := DADOS.NUMTRANSVENDA;

    tPCLOGFATURAMENTO.LOG                 := 'Inserção de registros na tabela PCPREST via rotina 814 - MIGRATION_PCPREST - DUPLIC: '||tPCPREST.DUPLIC;
    tPCLOGFATURAMENTO.TIPOLOG             := 'MIGRATION';
    tPCLOGFATURAMENTO.PROCESSO            := 'MIGRATION_PREST';
    tPCLOGFATURAMENTO.CODLOG              := DADOS.DUPLIC;
    tPCLOGFATURAMENTO.CODFUNC             := DADOS.CODUSUR;
    tPCLOGFATURAMENTO.CODFILIAL           := DADOS.CODFILIAL;
    tPCLOGFATURAMENTO.DATAHORA            := DADOS.DTEMISSAO;
    tPCLOGFATURAMENTO.DTINICIAL           := SYSDATE;
    tPCLOGFATURAMENTO.DTFINAL             := SYSDATE;
    tPCLOGFATURAMENTO.OSUSER              := SYS_CONTEXT('USERENV', 'OS_USER');
    tPCLOGFATURAMENTO.MAQUINA             := SYS_CONTEXT('USERENV', 'HOST'); 
    tPCLOGFATURAMENTO.TERMINAL            := SYS_CONTEXT('USERENV', 'TERMINAL');
    tPCLOGFATURAMENTO.CODIGOIDENTIFICADOR := DADOS.NUMTRANSVENDA;
    
    BEGIN
      SELECT PRAZO1
            ,PRAZO2
            ,PRAZO3
            ,PRAZO4
            ,PRAZO5
            ,PRAZO6
            ,PRAZO7
            ,PRAZO8
            ,PRAZO9
            ,PRAZO10
            ,PRAZO11
            ,PRAZO12
        INTO tPCPLPAG.PRAZO1
            ,tPCPLPAG.PRAZO2
            ,tPCPLPAG.PRAZO3
            ,tPCPLPAG.PRAZO4
            ,tPCPLPAG.PRAZO5
            ,tPCPLPAG.PRAZO6
            ,tPCPLPAG.PRAZO7
            ,tPCPLPAG.PRAZO8
            ,tPCPLPAG.PRAZO9
            ,tPCPLPAG.PRAZO10
            ,tPCPLPAG.PRAZO11
            ,tPCPLPAG.PRAZO12
      FROM PCPLPAG P 
      WHERE P.CODPLPAG = DADOS.CODPLPAG;
    EXCEPTION
    WHEN OTHERS THEN
      tPCLOGFATURAMENTO.LOG := 'Erro na consulta da tabela PCPLPAG para o CODPLPAG: '||DADOS.CODPLPAG||' '|| SQLCODE || '-' || SQLERRM || ' - ' ||
                                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
      DBMS_OUTPUT.PUT_LINE(tPCLOGFATURAMENTO.LOG);
      GRAVARLOG(tPCLOGFATURAMENTO);
      RAISE;
    END;
    
    dNUMPREST           := 1;
    dQTDPARCELAS        := FN_QTD_PARCELAS(DADOS.CODPLPAG);
    dVLPREST            := DADOS.VALOR / dQTDPARCELAS;
    tPCPREST.VALOR      := dVLPREST;
    tPCPARCELANFE.VALOR := dVLPREST;  
    
    FOR PARC IN 1..dQTDPARCELAS LOOP
       
      CASE dNUMPREST 
           WHEN  1 THEN dtVENC := DADOS.DTEMISSAO + tPCPLPAG.PRAZO1;
           WHEN  2 THEN dtVENC := DADOS.DTEMISSAO + tPCPLPAG.PRAZO2;
           WHEN  3 THEN dtVENC := DADOS.DTEMISSAO + tPCPLPAG.PRAZO3;
           WHEN  4 THEN dtVENC := DADOS.DTEMISSAO + tPCPLPAG.PRAZO4;
           WHEN  5 THEN dtVENC := DADOS.DTEMISSAO + tPCPLPAG.PRAZO5;
           WHEN  6 THEN dtVENC := DADOS.DTEMISSAO + tPCPLPAG.PRAZO6;
           WHEN  7 THEN dtVENC := DADOS.DTEMISSAO + tPCPLPAG.PRAZO7;
           WHEN  8 THEN dtVENC := DADOS.DTEMISSAO + tPCPLPAG.PRAZO8;
           WHEN  9 THEN dtVENC := DADOS.DTEMISSAO + tPCPLPAG.PRAZO9;
           WHEN 10 THEN dtVENC := DADOS.DTEMISSAO + tPCPLPAG.PRAZO10;
           WHEN 11 THEN dtVENC := DADOS.DTEMISSAO + tPCPLPAG.PRAZO11;
           WHEN 12 THEN dtVENC := DADOS.DTEMISSAO + tPCPLPAG.PRAZO12;
      END CASE;
          
      tPCPREST.PREST       := dNUMPREST;
      tPCPREST.DTVENC      := dtVENC;
      tPCPREST.DTVENCORIG  := dtVENC;
      tPCPARCELANFE.PREST  := dNUMPREST;
      tPCPARCELANFE.DTVENC := dtVENC;
      
      BEGIN
        INSERT INTO PCPREST (CODCLI
                            ,PREST
                            ,DUPLIC
                            ,VALOR
                            ,CODCOB
                            ,DTVENC
                            ,DTEMISSAO
                            ,CODFILIAL
                            ,STATUS
                            ,CODUSUR
                            ,DTVENCORIG
                            ,NUMTRANSVENDA
                            ,NUMCAR
                            ,NUMPED)
                     VALUES (tPCPREST.CODCLI
                            ,tPCPREST.PREST
                            ,tPCPREST.DUPLIC
                            ,tPCPREST.VALOR
                            ,tPCPREST.CODCOB
                            ,tPCPREST.DTVENC
                            ,tPCPREST.DTEMISSAO
                            ,tPCPREST.CODFILIAL
                            ,tPCPREST.STATUS
                            ,tPCPREST.CODUSUR
                            ,tPCPREST.DTVENCORIG
                            ,tPCPREST.NUMTRANSVENDA
                            ,tPCPREST.NUMCAR
                            ,tPCPREST.NUMPED);

        INSERT INTO PCPARCELANFE (DUPLIC
                                 ,PREST
                                 ,DTVENC
                                 ,VALOR
                                 ,NUMTRANSACAO
                                 ,TIPOMOV)
                         VALUES (tPCPARCELANFE.DUPLIC
                                ,tPCPARCELANFE.PREST
                                ,tPCPARCELANFE.DTVENC
                                ,tPCPARCELANFE.VALOR
                                ,tPCPARCELANFE.NUMTRANSACAO
                                ,tPCPARCELANFE.TIPOMOV);
      EXCEPTION
        WHEN OTHERS THEN
          tPCLOGFATURAMENTO.LOG := 'Erro na inserção do registro na PCPREST via rotina 814 - MIGRATION_PCPREST - DUPLIC: '||tPCPREST.DUPLIC||' '|| SQLCODE || '-' || SQLERRM || ' - ' ||
                                   DBMS_UTILITY.FORMAT_ERROR_BACKTRACE; 
          DBMS_OUTPUT.PUT_LINE(tPCLOGFATURAMENTO.LOG);
          GRAVARLOG(tPCLOGFATURAMENTO);
        RAISE;
      END;
         
      dNUMPREST := dNUMPREST + 1;
    END LOOP;
    BEGIN
      SELECT SUM(VALOR) 
        INTO dVLTOTALPREST
      FROM PCPREST 
      WHERE NUMTRANSVENDA = tPCPREST.NUMTRANSVENDA;
    EXCEPTION
    WHEN OTHERS THEN
      tPCLOGFATURAMENTO.LOG :='Erro na consulta do somatório da PCPREST para o NUMTRANSVENDA = '||tPCPREST.NUMTRANSVENDA||' '|| SQLCODE || '-' || SQLERRM || ' - ' ||
                               DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
      DBMS_OUTPUT.PUT_LINE(tPCLOGFATURAMENTO.LOG);
      GRAVARLOG(tPCLOGFATURAMENTO);        
      RAISE;
    END;
  
    IF dVLTOTALPREST <> dVLTOTALPCNFSAID THEN
      dVLDIFF := dVLTOTALPCNFSAID - dVLTOTALPREST;
      
     UPDATE PCPREST SET
       VALOR = VALOR + dVLDIFF
      WHERE NUMTRANSVENDA = tPCPREST.NUMTRANSVENDA
      AND PREST = tPCPREST.PREST;
    END IF; 
    GRAVARLOG(tPCLOGFATURAMENTO);
  END LOOP;
END;